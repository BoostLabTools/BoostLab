Set-StrictMode -Version Latest

$script:BoostLabCapabilityFields = @(
    'RequiresAdmin'
    'RequiresInternet'
    'CanReboot'
    'CanModifyRegistry'
    'CanModifyServices'
    'CanInstallSoftware'
    'CanDownload'
    'CanModifyDrivers'
    'CanModifySecurity'
    'CanDeleteFiles'
    'UsesTrustedInstaller'
    'UsesSafeMode'
    'SupportsDefault'
    'SupportsRestore'
    'NeedsExplicitConfirmation'
)

function ConvertTo-BoostLabCapabilityObject {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Capabilities
    )

    $normalized = [ordered]@{}
    foreach ($field in $script:BoostLabCapabilityFields) {
        $normalized[$field] = if ($Capabilities.Contains($field)) {
            [bool]$Capabilities[$field]
        }
        else {
            $false
        }
    }

    return [pscustomobject]$normalized
}

function Test-BoostLabPlanNeedsConfirmation {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('low', 'medium', 'high')]
        [string]$RiskLevel,

        [Parameter(Mandatory)]
        [pscustomobject]$Capabilities,

        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default', 'Open', 'Analyze', 'Restore')]
        [string]$ActionName
    )

    if ($RiskLevel -eq 'high') {
        return $true
    }
    if ($ActionName -eq 'Analyze') {
        return $false
    }
    if ($ActionName -eq 'Open') {
        return (
            $Capabilities.NeedsExplicitConfirmation -or
            $Capabilities.CanReboot -or
            $Capabilities.UsesTrustedInstaller -or
            $Capabilities.UsesSafeMode
        )
    }

    return (
        $Capabilities.NeedsExplicitConfirmation -or
        $Capabilities.CanReboot -or
        $Capabilities.CanModifyServices -or
        $Capabilities.CanInstallSoftware -or
        $Capabilities.CanDownload -or
        $Capabilities.CanModifyDrivers -or
        $Capabilities.CanModifySecurity -or
        $Capabilities.CanDeleteFiles -or
        $Capabilities.UsesTrustedInstaller -or
        $Capabilities.UsesSafeMode
    )
}

function Test-BoostLabWriteCacheActionPlanProductScope {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $productName = 'Windows'
    $buildNumber = [Environment]::OSVersion.Version.Build

    try {
        $currentVersion = Get-ItemProperty `
            -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' `
            -ErrorAction Stop
        $productName = [string]$currentVersion.ProductName
        $buildNumber = [int]$currentVersion.CurrentBuildNumber

        if ($buildNumber -ge 22000 -and $productName -like 'Windows 10*') {
            $productName = $productName -replace '^Windows 10', 'Windows 11'
        }
    }
    catch {
        # The plan falls back to the process-reported build and remains conservative.
    }

    $isWindows = $productName -match 'Windows' -or $env:OS -eq 'Windows_NT'
    $isWindows10 = $productName -match 'Windows 10' -or ($buildNumber -ge 10240 -and $buildNumber -lt 22000)
    $isWindows11 = $productName -match 'Windows 11' -or ($buildNumber -ge 22000 -and $productName -notmatch 'Server')
    $supported = $isWindows
    $reason = if ($supported) {
        'Write Cache Buffer Flushing uses shared Windows storage registry behavior; the Ultimate source has no Windows 10-only branch.'
    }
    else {
        'This host is outside BoostLab product scope for Write Cache Buffer Flushing.'
    }

    return [pscustomobject]@{
        Supported   = $supported
        ProductName = $productName
        Build       = $buildNumber
        IsWindows10 = $isWindows10
        IsWindows11 = $isWindows11
        Reason      = $reason
    }
}

function New-BoostLabActionPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$ToolMetadata,

        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default', 'Open', 'Analyze', 'Restore')]
        [string]$ActionName,

        [bool]$IsDryRun = $true
    )

    foreach ($field in @('Id', 'Title', 'RiskLevel', 'Actions', 'Capabilities')) {
        if (-not $ToolMetadata.Contains($field)) {
            throw "Cannot build an action plan because metadata field '$field' is missing."
        }
    }
    if ($ActionName -notin @($ToolMetadata['Actions'])) {
        throw "Cannot build an action plan for undeclared action '$ActionName'."
    }
    if ($ToolMetadata['Capabilities'] -isnot [System.Collections.IDictionary]) {
        throw 'Cannot build an action plan because Capabilities is not a dictionary.'
    }

    $toolId = [string]$ToolMetadata['Id']
    $toolTitle = [string]$ToolMetadata['Title']
    $riskLevel = ([string]$ToolMetadata['RiskLevel']).ToLowerInvariant()
    if ($riskLevel -notin @('low', 'medium', 'high')) {
        throw "Cannot build an action plan for unsupported risk level '$riskLevel'."
    }

    $capabilities = ConvertTo-BoostLabCapabilityObject -Capabilities $ToolMetadata['Capabilities']
    $productScope = if ($toolId -eq 'write-cache-buffer-flushing') {
        Test-BoostLabWriteCacheActionPlanProductScope
    }
    else {
        $null
    }
    $isProductScopeNotApplicable = (
        $toolId -eq 'write-cache-buffer-flushing' -and
        $null -ne $productScope -and
        -not [bool]$productScope.Supported
    )
    $needsConfirmation = Test-BoostLabPlanNeedsConfirmation `
        -RiskLevel $riskLevel `
        -Capabilities $capabilities `
        -ActionName $ActionName
    if ($isProductScopeNotApplicable) {
        $needsConfirmation = $false
    }
    if ($toolId -eq 'restore-point' -and $ActionName -eq 'Open') {
        $needsConfirmation = $false
    }

    $summary = if ($isProductScopeNotApplicable) {
        'This Windows optimization tool is not applicable on the current host; no registry discovery, capture, or write will run.'
    }
    elseif ($toolId -eq 'unattended' -and $ActionName -eq 'Analyze') {
        'Review the approved Windows 11 unattended setup payload without creating files.'
    }
    elseif ($toolId -eq 'unattended' -and $ActionName -eq 'Apply') {
        'Create the approved Windows 11 autounattend.xml on selected removable installation media.'
    }
    elseif ($toolId -eq 'driver-clean' -and $ActionName -eq 'Analyze') {
        'Read the Driver Clean source mirror and report blocked approvals without running any driver-cleaning operation.'
    }
    elseif ($toolId -eq 'driver-clean' -and $ActionName -eq 'Open') {
        'Prepare Driver Clean manual handoff instructions only; no external tool, download, or system-changing operation is opened or executed.'
    }
    elseif ($toolId -eq 'driver-clean' -and $ActionName -eq 'Apply') {
        'Auto mode is blocked for Driver Clean because DDU, 7-Zip, process, reboot, and recovery approvals do not exist.'
    }
    elseif ($toolId -eq 'restore-point' -and $ActionName -eq 'Apply') {
        'Enable System Restore if needed and create the approved backup restore point.'
    }
    elseif ($toolId -eq 'restore-point' -and $ActionName -eq 'Open') {
        'Open Windows System Protection and System Restore.'
    }
    elseif ($toolId -eq 'widgets' -and $ActionName -eq 'Apply') {
        'Disable Windows Widgets and remove Widgets from the taskbar using the approved policies.'
    }
    elseif ($toolId -eq 'widgets' -and $ActionName -eq 'Default') {
        'Restore the approved default Windows Widgets policy behavior.'
    }
    elseif ($toolId -eq 'memory-compression' -and $ActionName -eq 'Apply') {
        'Disable Windows Memory Compression using the approved Ultimate recommendation.'
    }
    elseif ($toolId -eq 'memory-compression' -and $ActionName -eq 'Default') {
        'Restore the approved default enabled Memory Compression state.'
    }
    elseif ($toolId -eq 'background-apps' -and $ActionName -eq 'Apply') {
        'Disable Windows background apps using the approved machine policy.'
    }
    elseif ($toolId -eq 'background-apps' -and $ActionName -eq 'Default') {
        'Restore the approved default Windows background apps policy behavior.'
    }
    elseif ($toolId -eq 'store-settings' -and $ActionName -eq 'Apply') {
        'Apply the approved Microsoft Store update and preference optimizations.'
    }
    elseif ($toolId -eq 'store-settings' -and $ActionName -eq 'Default') {
        'Restore the approved default Microsoft Store settings behavior.'
    }
    elseif ($toolId -eq 'updates-pause' -and $ActionName -eq 'Apply') {
        'Pause Windows Update for 365 days using the approved Ultimate timestamp values.'
    }
    elseif ($toolId -eq 'updates-pause' -and $ActionName -eq 'Default') {
        'Restore the default unpaused Windows Update registry state.'
    }
    elseif ($toolId -eq 'theme-black' -and $ActionName -eq 'Apply') {
        'Apply the approved Ultimate black theme, transparency, accent, DWM, and background registry values.'
    }
    elseif ($toolId -eq 'theme-black' -and $ActionName -eq 'Default') {
        'Restore the explicit default theme registry values from the approved Ultimate source.'
    }
    elseif ($toolId -eq 'start-menu-layout' -and $ActionName -eq 'Apply') {
        'Apply the approved Ultimate 25H2 recommended Start menu layout feature overrides and apps view.'
    }
    elseif ($toolId -eq 'start-menu-layout' -and $ActionName -eq 'Default') {
        'Restore the Ultimate 24H2 Start menu branch as the approved BoostLab Default.'
    }
    elseif ($toolId -eq 'context-menu' -and $ActionName -eq 'Apply') {
        'Apply the approved Ultimate clean Context Menu registry behavior.'
    }
    elseif ($toolId -eq 'context-menu' -and $ActionName -eq 'Default') {
        'Restore the Ultimate Context Menu handlers with the Yazan-approved scoped Blocked-value cleanup.'
    }
    elseif ($toolId -eq 'signout-lockscreen-wallpaper-black' -and $ActionName -eq 'Apply') {
        'Generate and apply the approved black sign-out, lock screen, and desktop wallpaper with ownership tracking.'
    }
    elseif ($toolId -eq 'signout-lockscreen-wallpaper-black' -and $ActionName -eq 'Default') {
        'Restore the approved default wallpaper state without deleting unrelated PersonalizationCSP values or files.'
    }
    elseif ($toolId -eq 'notepad-settings' -and $ActionName -eq 'Apply') {
        'Back up Notepad settings.dat, stop Notepad, and import the approved Ultimate settings into the mounted Notepad settings hive.'
    }
    elseif ($toolId -eq 'notepad-settings' -and $ActionName -eq 'Default') {
        'Back up Notepad settings.dat, stop Notepad, and delete only that file to restore the Ultimate default behavior.'
    }
    elseif ($toolId -eq 'network-adapter-power-savings-wake' -and $ActionName -eq 'Apply') {
        'Disable the approved network adapter power-saving and wake values across detected adapter class keys.'
    }
    elseif ($toolId -eq 'network-adapter-power-savings-wake' -and $ActionName -eq 'Default') {
        'Restore the approved default state by removing only the source-defined adapter power and wake values.'
    }
    elseif ($toolId -eq 'write-cache-buffer-flushing' -and $ActionName -eq 'Analyze') {
        'Analyze the source-targeted SCSI and NVME storage registry paths without changing write-cache buffer flushing.'
    }
    elseif ($toolId -eq 'write-cache-buffer-flushing' -and $ActionName -eq 'Apply') {
        'Set CacheIsPowerProtected to 1 on source-targeted storage Disk registry paths after capturing each prior value state.'
    }
    elseif ($toolId -eq 'power-plan' -and $ActionName -eq 'Apply') {
        'Apply the source-defined Ultimate power scheme, registry values, hibernation state, and power settings.'
    }
    elseif ($toolId -eq 'power-plan' -and $ActionName -eq 'Default') {
        'Restore Windows default power schemes and the explicit default registry behavior from Ultimate.'
    }
    elseif ($toolId -eq 'spectre-meltdown-assistant' -and $ActionName -eq 'Analyze') {
        'Analyze the two source-defined Spectre / Meltdown mitigation override values and explain the security and performance tradeoff.'
    }
    elseif ($toolId -eq 'spectre-meltdown-assistant' -and $ActionName -eq 'Apply') {
        'Disable the source-targeted Spectre / Meltdown mitigations by setting both approved Ultimate override values to 3.'
    }
    elseif ($toolId -eq 'spectre-meltdown-assistant' -and $ActionName -eq 'Default') {
        'Remove both source-defined mitigation overrides so Windows can use its default mitigation policy.'
    }
    elseif ($toolId -eq 'mmagent-assistant' -and $ActionName -eq 'Analyze') {
        'Analyze the current MMAgent and prefetcher state and compare it with the approved Ultimate Off and Default profiles.'
    }
    elseif ($toolId -eq 'mmagent-assistant' -and $ActionName -eq 'Apply') {
        'Apply the approved Ultimate MMAgent Off profile, including the source-defined prefetch and MMAgent feature changes.'
    }
    elseif ($toolId -eq 'mmagent-assistant' -and $ActionName -eq 'Default') {
        'Restore the approved Ultimate MMAgent Default profile exactly as defined by the source, including the features that remain disabled.'
    }
    elseif ($toolId -eq 'smt-ht-assistant' -and $ActionName -eq 'Analyze') {
        'Analyze processor topology, compute the source SMT / HT-off affinity mask, and explain the two approved temporary per-process workflows.'
    }
    elseif ($toolId -eq 'smt-ht-assistant' -and $ActionName -eq 'Apply') {
        'Apply the approved Already Running SMT / HT-off affinity mask to a selected running process.'
    }
    elseif ($toolId -eq 'smt-ht-assistant' -and $ActionName -eq 'Open') {
        'Run the approved Startup SMT / HT-off workflow by stopping specific launchers, selecting a file, and launching it with the source affinity mask.'
    }
    elseif ($toolId -eq 'to-bios' -and $ActionName -eq 'Analyze') {
        'Review the approved immediate restart-to-firmware behavior without restarting the computer.'
    }
    elseif ($toolId -eq 'to-bios' -and $ActionName -eq 'Open') {
        'Restart Windows immediately and request BIOS/UEFI firmware settings using the approved Ultimate command.'
    }
    else {
        switch ($ActionName) {
        'Analyze' { "Analyze $toolTitle without applying changes." }
        'Open' {
            if ($capabilities.CanReboot) {
                "Open the approved $toolTitle workflow, which can restart the computer."
            }
            else {
                "Open the approved Windows interface or resource for $toolTitle."
            }
        }
        'Apply' { "Apply the approved $toolTitle behavior." }
        'Default' { "Return $toolTitle to its approved default behavior." }
        'Restore' { "Restore $toolTitle from a previous state captured by BoostLab." }
        }
    }

    $plannedChanges = [System.Collections.Generic.List[string]]::new()
    if ($isProductScopeNotApplicable) {
        $plannedChanges.Add([string]$productScope.Reason)
        $plannedChanges.Add('No Windows storage registry path enumeration is planned on this unsupported host.')
        $plannedChanges.Add('Do not capture registry state and do not write CacheIsPowerProtected.')
    }
    elseif ($toolId -eq 'unattended' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Read Windows version and removable-media availability without creating or deleting files.')
        $plannedChanges.Add('Display the exact source-defined Windows Setup, local account, OOBE, and hardware-bypass behavior.')
        $plannedChanges.Add('Report that Windows 10 may host this Windows 11 preparation workflow while Windows 10 optimization branches remain unsupported.')
    }
    elseif ($toolId -eq 'unattended' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Require a Windows 10 or Windows 11 host and let the technician select a local account name and detected removable-media root.')
        $plannedChanges.Add('Back up and hash every pre-existing source-targeted temporary or destination unattended file before replacement.')
        $plannedChanges.Add('Create the exact Ultimate autounattendtemplate.xml and autounattend.xml sequence under Windows Temp.')
        $plannedChanges.Add('Move autounattend.xml to the selected removable-media root and preserve the source overwrite behavior only after backup.')
        $plannedChanges.Add('Verify the final file hash, XML structure, account substitution, and all five source-defined hardware bypass commands.')
        $plannedChanges.Add('Persist destination, backup, ownership, source checksum, and verification state under ProgramData\BoostLab\State.')
    }
    elseif ($toolId -eq 'driver-clean' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Read the Driver Clean source mirror checksum and implementation status.')
        $plannedChanges.Add('Report missing DDU, 7-Zip, process, Safe Mode, RunOnce, bcdedit, reboot, recovery, generated-script, and driver-state approvals.')
        $plannedChanges.Add('Perform no download, external process start, registry mutation, Safe Mode change, RunOnce creation, bcdedit call, reboot, or driver cleanup.')
    }
    elseif ($toolId -eq 'driver-clean' -and $ActionName -eq 'Open') {
        $plannedChanges.Add('Prepare manual handoff instructions only.')
        $plannedChanges.Add('Do not open any external tool or approved external resource.')
        $plannedChanges.Add('Do not download DDU or 7-Zip.')
        $plannedChanges.Add('Do not execute DDU or any driver-cleaning process.')
        $plannedChanges.Add('Do not modify registry, create RunOnce, call bcdedit, switch Safe Mode, reboot, or perform any system-changing operation.')
    }
    elseif ($toolId -eq 'driver-clean' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Block Auto mode before any operational step.')
        $plannedChanges.Add('Do not execute any approved Auto behavior because none is approved.')
        $plannedChanges.Add('Report missing DDU artifact/provenance, 7-Zip artifact/provenance, process handling, Safe Mode, RunOnce, bcdedit, reboot/recovery, generated-script, and driver-state approvals.')
        $plannedChanges.Add('Perform no download, external process start, registry mutation, Safe Mode change, RunOnce creation, bcdedit call, reboot, or driver cleanup.')
    }
    elseif ($toolId -eq 'restore-point' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Temporarily set SystemRestorePointCreationFrequency to 0.')
        $plannedChanges.Add('Enable System Restore on C:\ if it is disabled.')
        $plannedChanges.Add('Create a restore point named backup with type MODIFY_SETTINGS.')
        $plannedChanges.Add('Remove the temporary restore-point frequency override.')
    }
    elseif ($toolId -eq 'restore-point' -and $ActionName -eq 'Open') {
        $plannedChanges.Add('Open the System Protection page.')
        $plannedChanges.Add('Open the Windows System Restore interface.')
    }
    elseif ($toolId -eq 'widgets' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Set PolicyManager AllowNewsAndInterests value to 0.')
        $plannedChanges.Add('Set the Dsh AllowNewsAndInterests policy value to 0.')
        $plannedChanges.Add('Stop Widgets and WidgetService if they are running.')
    }
    elseif ($toolId -eq 'widgets' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Set PolicyManager AllowNewsAndInterests value to 1.')
        $plannedChanges.Add('Remove the Dsh policy key used to block Widgets.')
    }
    elseif ($toolId -eq 'memory-compression' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Run Disable-MMAgent -MemoryCompression.')
        $plannedChanges.Add('Read the resulting MemoryCompression state with Get-MMAgent.')
    }
    elseif ($toolId -eq 'memory-compression' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Run Enable-MMAgent -MemoryCompression.')
        $plannedChanges.Add('Read the resulting MemoryCompression state with Get-MMAgent.')
    }
    elseif ($toolId -eq 'background-apps' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Set AppPrivacy LetAppsRunInBackground to 2 (Force deny).')
        $plannedChanges.Add('Open the Windows Background Apps Settings page.')
        $plannedChanges.Add('Read the resulting AppPrivacy policy value.')
    }
    elseif ($toolId -eq 'background-apps' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Remove the AppPrivacy LetAppsRunInBackground policy value.')
        $plannedChanges.Add('Open the Windows Background Apps Settings page.')
        $plannedChanges.Add('Confirm that the AppPrivacy policy value is absent.')
    }
    elseif ($toolId -eq 'store-settings' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Open Microsoft Store Settings before changing Store preferences.')
        $plannedChanges.Add('Stop only WinStore.App, backgroundTaskHost, and StoreDesktopExtension.')
        $plannedChanges.Add('Set WindowsStore WindowsUpdate AutoDownload to 2.')
        $plannedChanges.Add('Import the approved video autoplay, installation notification, and personalization values into the Store settings hive.')
        $plannedChanges.Add('Unload the Store settings hive and reopen Microsoft Store Settings.')
    }
    elseif ($toolId -eq 'store-settings' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Remove the WindowsStore registry key used by the approved optimization.')
        $plannedChanges.Add('Stop only WinStore.App, backgroundTaskHost, and StoreDesktopExtension.')
        $plannedChanges.Add('Launch the built-in wsreset.exe Store reset.')
        $plannedChanges.Add('Stop the same Store process targets again and open Microsoft Store Settings.')
    }
    elseif ($toolId -eq 'updates-pause' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Calculate UTC start timestamps and expiry timestamps 365 days in the future.')
        $plannedChanges.Add('Write the six approved Windows Update pause timestamp values in Ultimate execution order.')
        $plannedChanges.Add('Open the built-in Windows Update Settings page.')
        $plannedChanges.Add('Read and verify all six pause timestamp values.')
    }
    elseif ($toolId -eq 'updates-pause' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Remove only the six Windows Update pause timestamp values written by Apply.')
        $plannedChanges.Add('Open the built-in Windows Update Settings page.')
        $plannedChanges.Add('Confirm that all six pause timestamp values are absent.')
    }
    elseif ($toolId -eq 'theme-black' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Write the approved blacktheme.reg payload to the Windows Temp directory.')
        $plannedChanges.Add('Import the exact HKCU and HKLM black theme values with regedit.exe in the Ultimate source order.')
        $plannedChanges.Add('Verify all 13 theme registry states defined by the source.')
    }
    elseif ($toolId -eq 'theme-black' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Write the approved defaulttheme.reg payload to the Windows Temp directory.')
        $plannedChanges.Add('Import the exact default values and remove the HKLM Themes Personalize key as defined by Ultimate.')
        $plannedChanges.Add('Verify all 13 default theme registry states defined by the source.')
    }
    elseif ($toolId -eq 'start-menu-layout' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Write the approved newstartmenu.reg payload to the Windows Temp directory.')
        $plannedChanges.Add('Set the four approved HKLM feature override EnabledState values to 2.')
        $plannedChanges.Add('Set HKCU Start AllAppsViewMode to 2 and verify the five registry values plus the import file.')
    }
    elseif ($toolId -eq 'start-menu-layout' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Write the approved oldstartmenu.reg payload to the Windows Temp directory.')
        $plannedChanges.Add('Remove only the four approved feature override EnabledState values.')
        $plannedChanges.Add('Set HKCU Start AllAppsViewMode to 0 and verify the five registry states plus the import file.')
    }
    elseif ($toolId -eq 'context-menu' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Apply the source classic context menu value and machine Explorer policy values.')
        $plannedChanges.Add('Remove the source-defined Pin, Favorites, Compatibility, Library, Sharing, Previous Versions, and Send To handlers.')
        $plannedChanges.Add('Add only the three source-defined Blocked GUID values for Terminal, Defender scan, and Give access to.')
        $plannedChanges.Add('Verify all 13 source-defined clean Context Menu registry states.')
    }
    elseif ($toolId -eq 'context-menu' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Remove the classic context menu override and NoCustomizeThisFolder value.')
        $plannedChanges.Add('Write and import the source contextmenudefault.reg payload for Pin to Quick access and Add to favorites.')
        $plannedChanges.Add('Restore the source Compatibility, Library, Sharing, Previous Versions, and Send To handler states.')
        $plannedChanges.Add('Remove only the three Context Menu-owned values from the shared Shell Extensions Blocked key; leave the key and unrelated values intact.')
        $plannedChanges.Add('Verify all 23 approved default Context Menu registry states.')
    }
    elseif ($toolId -eq 'signout-lockscreen-wallpaper-black' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Check C:\Windows\Black.jpg ownership and back up a pre-existing unrelated file before overwrite.')
        $plannedChanges.Add('Generate C:\Windows\Black.jpg as a black bitmap at the primary monitor resolution.')
        $plannedChanges.Add('Set HKLM PersonalizationCSP LockScreenImagePath and LockScreenImageStatus.')
        $plannedChanges.Add('Set the current user desktop Wallpaper value to C:\Windows\Black.jpg and request the source wallpaper refresh.')
        $plannedChanges.Add('Record backup and generated-file ownership metadata under ProgramData\BoostLab\State.')
    }
    elseif ($toolId -eq 'signout-lockscreen-wallpaper-black' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Remove only the tool-owned PersonalizationCSP values LockScreenImagePath and LockScreenImageStatus.')
        $plannedChanges.Add('Leave the shared PersonalizationCSP key and every unrelated value intact.')
        $plannedChanges.Add('Set the current user desktop Wallpaper value to C:\Windows\Web\Wallpaper\Windows\img0.jpg and request the source wallpaper refresh.')
        $plannedChanges.Add('Restore a recorded backup of a pre-existing C:\Windows\Black.jpg when available.')
        $plannedChanges.Add('Otherwise remove Black.jpg only when BoostLab state and hash prove ownership; leave uncertain or unrelated files intact.')
    }
    elseif ($toolId -eq 'notepad-settings' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Stop only the Notepad process and wait for the source-defined two-second delay.')
        $plannedChanges.Add('Create and verify a unique backup of the exact Notepad settings.dat before mutation.')
        $plannedChanges.Add('Write the source-compatible notepadsettings.reg file under Windows Temp.')
        $plannedChanges.Add('Load settings.dat at HKLM\Settings, import the three source-defined LocalState values, and unload the hive.')
        $plannedChanges.Add('Persist the target path, original hash, backup hash, and action outcome under ProgramData\BoostLab\State.')
    }
    elseif ($toolId -eq 'notepad-settings' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Stop only the Notepad process and wait for the source-defined two-second delay.')
        $plannedChanges.Add('Create and verify a unique backup of the exact Notepad settings.dat before deletion when it exists.')
        $plannedChanges.Add('Delete only Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings\settings.dat, matching Ultimate Default.')
        $plannedChanges.Add('Treat an already-absent settings.dat as the approved default state.')
        $plannedChanges.Add('Persist the target path, original hash, backup hash, and action outcome under ProgramData\BoostLab\State.')
    }
    elseif ($toolId -eq 'network-adapter-power-savings-wake' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Enumerate numeric network adapter class keys under the source ControlSet001 class GUID.')
        $plannedChanges.Add('Set the 14 source-defined PnPCapabilities, energy-saving, and wake values in Ultimate execution order.')
        $plannedChanges.Add('Verify every unique value on every detected adapter key.')
    }
    elseif ($toolId -eq 'network-adapter-power-savings-wake' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Enumerate numeric network adapter class keys under the source ControlSet001 class GUID.')
        $plannedChanges.Add('Remove only the 14 source-defined PnPCapabilities, energy-saving, and wake values in Ultimate execution order.')
        $plannedChanges.Add('Treat already-absent values as default and verify every unique value on every detected adapter key.')
    }
    elseif ($toolId -eq 'write-cache-buffer-flushing' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Enumerate source-targeted Device Parameters keys under HKLM:\SYSTEM\ControlSet001\Enum\SCSI and NVME.')
        $plannedChanges.Add('Report whether each detected Disk child key has CacheIsPowerProtected set, absent, or unreadable.')
        $plannedChanges.Add('Make no registry changes and expose no Default key deletion.')
    }
    elseif ($toolId -eq 'write-cache-buffer-flushing' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Enumerate the same source-targeted SCSI and NVME Device Parameters paths and validate the exact Disk child path.')
        $plannedChanges.Add('Capture the prior CacheIsPowerProtected existence, type, and data for every target before any write.')
        $plannedChanges.Add('Set only CacheIsPowerProtected to REG_DWORD 1 on each captured target.')
        $plannedChanges.Add('Verify each changed value and record post-mutation evidence for future review.')
        $plannedChanges.Add('Do not run the Ultimate Default broad Disk-key deletion.')
    }
    elseif ($toolId -eq 'power-plan' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Duplicate Ultimate Performance to the source GUID 99999999-9999-9999-9999-999999999999 and activate it.')
        $plannedChanges.Add('Enumerate and delete the other power schemes exactly as Ultimate does; user-created custom schemes cannot be restored by Default.')
        $plannedChanges.Add('Disable hibernation and apply the 10 source-defined registry values, including hidden power-setting attributes.')
        $plannedChanges.Add('Apply all 36 source-defined AC and DC power setting pairs in Ultimate order.')
        $plannedChanges.Add('Open Power Options and verify the active scheme, settings, and registry state.')
    }
    elseif ($toolId -eq 'power-plan' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Run powercfg -restoredefaultschemes, which removes custom schemes and restores Windows built-in schemes.')
        $plannedChanges.Add('Enable hibernation and apply the explicit Ultimate Default registry operations.')
        $plannedChanges.Add('Delete the complete FlyoutMenuSettings and PowerThrottling keys exactly as defined by the approved source.')
        $plannedChanges.Add('Restore the four hidden power-setting Attributes values to 1.')
        $plannedChanges.Add('Open Power Options and verify Balanced is active and the approved registry defaults are present.')
    }
    elseif ($toolId -eq 'spectre-meltdown-assistant' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Read FeatureSettingsOverrideMask and FeatureSettingsOverride under the exact Ultimate ControlSet001 Memory Management path.')
        $plannedChanges.Add('Classify the detected policy as source-disabled, default, custom/partial, or unknown.')
        $plannedChanges.Add('Explain that Apply reduces speculative-execution vulnerability protection and Default is the recommended security posture.')
    }
    elseif ($toolId -eq 'spectre-meltdown-assistant' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Set FeatureSettingsOverrideMask to DWORD 3 at the exact source-defined ControlSet001 path.')
        $plannedChanges.Add('Set FeatureSettingsOverride to DWORD 3 at the exact source-defined ControlSet001 path.')
        $plannedChanges.Add('Verify both values independently without changing boot configuration or restarting Windows.')
    }
    elseif ($toolId -eq 'spectre-meltdown-assistant' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Delete only FeatureSettingsOverrideMask from the exact source-defined ControlSet001 path.')
        $plannedChanges.Add('Delete only FeatureSettingsOverride from the exact source-defined ControlSet001 path.')
        $plannedChanges.Add('Treat already-absent values as default and verify both values independently.')
    }
    elseif ($toolId -eq 'mmagent-assistant' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Read the source-defined EnablePrefetcher registry value.')
        $plannedChanges.Add('Read Get-MMAgent and compare ApplicationLaunchPrefetching, ApplicationPreLaunch, MaxOperationAPIFiles, MemoryCompression, OperationAPI, and PageCombining.')
        $plannedChanges.Add('Display the approved Ultimate Off and Default profiles and the source warning about delayed initialization after reboot.')
    }
    elseif ($toolId -eq 'mmagent-assistant' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Set HKLM\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Memory Management\\PrefetchParameters\\EnablePrefetcher to 0.')
        $plannedChanges.Add('Run Disable-MMAgent -ApplicationLaunchPrefetching and Disable-MMAgent -ApplicationPreLaunch.')
        $plannedChanges.Add('Run Set-MMAgent -MaxOperationAPIFiles 1.')
        $plannedChanges.Add('Run Disable-MMAgent -MemoryCompression, Disable-MMAgent -OperationAPI, and Disable-MMAgent -PageCombining.')
        $plannedChanges.Add('Verify the resulting MMAgent and prefetcher state against the approved Ultimate Off profile.')
    }
    elseif ($toolId -eq 'mmagent-assistant' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Set HKLM\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Memory Management\\PrefetchParameters\\EnablePrefetcher to 3.')
        $plannedChanges.Add('Run Enable-MMAgent -ApplicationLaunchPrefetching and Enable-MMAgent -ApplicationPreLaunch.')
        $plannedChanges.Add('Run Set-MMAgent -MaxOperationAPIFiles 512.')
        $plannedChanges.Add('Preserve the source-defined Default behavior by keeping MemoryCompression and PageCombining disabled and enabling only OperationAPI.')
        $plannedChanges.Add('Verify the resulting MMAgent and prefetcher state against the approved Ultimate Default profile.')
    }
    elseif ($toolId -eq 'smt-ht-assistant' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Read the number of logical processors from Win32_ComputerSystem.')
        $plannedChanges.Add('Generate the exact alternating SMT / HT-off binary and hexadecimal affinity mask from the source logic.')
        $plannedChanges.Add('List running processes larger than 500 MB for the source Already Running path.')
        $plannedChanges.Add('Display the approved launcher stop list used by the source Startup path.')
    }
    elseif ($toolId -eq 'smt-ht-assistant' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('List running processes larger than 500 MB and select one process ID.')
        $plannedChanges.Add('Apply the source-derived integer affinity mask directly to the selected running process.')
        $plannedChanges.Add('Reload the process and verify that its processor affinity matches the expected SMT / HT-off mask.')
    }
    elseif ($toolId -eq 'smt-ht-assistant' -and $ActionName -eq 'Open') {
        $plannedChanges.Add('Stop only the source-defined launcher processes before launch.')
        $plannedChanges.Add('Select a launcher, game, shortcut, or executable file.')
        $plannedChanges.Add('Launch the selected file with `start "" /affinity <hex-mask> "<path>"` through cmd.exe exactly in the approved source style.')
        $plannedChanges.Add('Wait for the source delay window, then try to verify the launched process affinity by base file name.')
    }
    elseif ($toolId -eq 'to-bios' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Display the approved restart-to-firmware command and safety warnings without executing it.')
    }
    elseif ($toolId -eq 'to-bios' -and $ActionName -eq 'Open') {
        $plannedChanges.Add('Require explicit GUI confirmation before execution.')
        $plannedChanges.Add('Run cmd.exe with the source-defined shutdown.exe /r /fw /t 0 command.')
        $plannedChanges.Add('Report whether Windows accepted the firmware restart request.')
    }
    else {
        switch ($ActionName) {
        'Analyze' {
            $plannedChanges.Add('Collect and report read-only information defined by the approved tool.')
        }
        'Open' {
            $plannedChanges.Add('Open only the approved interface or workflow declared by the tool.')
        }
        'Apply' {
            $plannedChanges.Add('Apply the approved operational behavior documented for this tool.')
        }
        'Default' {
            $plannedChanges.Add('Apply the tool-specific approved default behavior.')
        }
        'Restore' {
            $plannedChanges.Add('Use a previous state captured by BoostLab; do not infer or invent restore data.')
        }
        }
    }

    $isPotentialChangeAction = $ActionName -in @('Apply', 'Default', 'Restore')
    if ($isPotentialChangeAction) {
        $capabilityChanges = [ordered]@{
            CanModifyRegistry = 'Modify approved Windows registry values.'
            CanModifyServices = 'Modify approved Windows service configuration or state.'
            CanInstallSoftware = 'Install or repair approved software.'
            CanDownload = 'Download approved external content.'
            CanModifyDrivers = 'Modify approved driver configuration or installation.'
            CanModifySecurity = 'Modify approved Windows security configuration.'
            CanDeleteFiles = 'Delete files within the approved tool scope.'
            UsesTrustedInstaller = 'Use an approved TrustedInstaller execution flow.'
            UsesSafeMode = 'Use an approved Safe Mode workflow.'
        }
        foreach ($field in $capabilityChanges.Keys) {
            if ([bool]$capabilities.$field) {
                $plannedChanges.Add([string]$capabilityChanges[$field])
            }
        }
    }
    if ($capabilities.CanReboot -and $ActionName -ne 'Analyze') {
        $plannedChanges.Add('Request or perform an approved restart when required by the workflow.')
    }
    if ($capabilities.RequiresAdmin) {
        $plannedChanges.Add('Require BoostLab to be running in an elevated Administrator process.')
    }
    if ($capabilities.UsesTrustedInstaller) {
        $plannedChanges.Add('Route any approved TrustedInstaller-level command through the centralized runtime helper.')
    }

    $sideEffects = [System.Collections.Generic.List[string]]::new()
    if ($isProductScopeNotApplicable) {
        $sideEffects.Add('No system changes are planned because this tool is outside product scope on the current host.')
        $sideEffects.Add('No Administrator execution, registry discovery, registry capture, or registry write is required.')
    }
    elseif ($toolId -eq 'unattended' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No files are created, moved, overwritten, or deleted.')
        $sideEffects.Add('The analysis distinguishes an allowed Windows 10 host from unsupported Windows 10 optimization branches.')
    }
    elseif ($toolId -eq 'unattended' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('The generated file creates a blank-password local administrator and skips multiple Windows OOBE pages when used by Windows Setup.')
        $sideEffects.Add('The generated file bypasses TPM, RAM, Secure Boot, CPU, and storage requirement checks during Windows 11 Setup.')
        $sideEffects.Add('Dynamic Update is disabled in the generated setup payload, and existing source-targeted files are retained as verified BoostLab backups.')
        $sideEffects.Add('BoostLab creates the file but does not start Windows Setup, partition disks, format media, or reboot the computer.')
    }
    elseif ($toolId -eq 'driver-clean' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; Driver Clean analysis is read-only.')
        $sideEffects.Add('No warnings are duplicated between result-level warnings and structured details.')
    }
    elseif ($toolId -eq 'driver-clean' -and $ActionName -eq 'Open') {
        $sideEffects.Add('Manual handoff instructions are prepared inside BoostLab only.')
        $sideEffects.Add('No external tool is opened, no DDU or 7-Zip artifact is downloaded, and no system-changing operation occurs.')
    }
    elseif ($toolId -eq 'driver-clean' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Auto mode is blocked before execution.')
        $sideEffects.Add('No approved Auto behavior, external process, download, registry mutation, reboot, or driver cleanup occurs.')
    }
    elseif ($toolId -eq 'restore-point' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('System Restore may be enabled on C:\ and remains enabled after the action.')
        $sideEffects.Add('The new restore point consumes space allocated to System Protection.')
        $sideEffects.Add('A temporary registry value is created and removed during the operation.')
    }
    elseif ($toolId -eq 'widgets' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Widgets and News and Interests are disabled by machine policy.')
        $sideEffects.Add('Running Widgets and WidgetService processes are closed.')
        $sideEffects.Add('The taskbar may update immediately or after Windows refreshes its policy state.')
    }
    elseif ($toolId -eq 'widgets' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Widgets availability returns to the approved Windows default policy behavior.')
        $sideEffects.Add('The taskbar may update after Windows refreshes its policy state.')
    }
    elseif ($toolId -eq 'memory-compression' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Windows will stop using memory compression until it is enabled again.')
        $sideEffects.Add('The setting is changed immediately; BoostLab does not restart the computer.')
    }
    elseif ($toolId -eq 'memory-compression' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Windows will be allowed to use memory compression again.')
        $sideEffects.Add('The setting is changed immediately; BoostLab does not restart the computer.')
    }
    elseif ($toolId -eq 'background-apps' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Windows apps governed by this machine policy will be prevented from running in the background.')
        $sideEffects.Add('The Windows Background Apps Settings page will open after the policy command.')
        $sideEffects.Add('Windows may require policy refresh, sign-out, or a later session before every visible effect appears.')
    }
    elseif ($toolId -eq 'background-apps' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Background app behavior returns to the Windows default when no other policy controls it.')
        $sideEffects.Add('The Windows Background Apps Settings page will open after the policy command.')
        $sideEffects.Add('Windows may require policy refresh, sign-out, or a later session before every visible effect appears.')
    }
    elseif ($toolId -eq 'store-settings' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Automatic Microsoft Store app updates are disabled by the approved registry value.')
        $sideEffects.Add('Store video autoplay, install notifications, and personalized experiences are disabled in the Store settings hive.')
        $sideEffects.Add('Running Microsoft Store components may be closed, and Microsoft Store Settings opens before and after the changes.')
    }
    elseif ($toolId -eq 'store-settings' -and $ActionName -eq 'Default') {
        $sideEffects.Add('The approved WindowsStore registry key is removed and the built-in Store reset is launched.')
        $sideEffects.Add('Running Microsoft Store components may be closed before and after wsreset.exe.')
        $sideEffects.Add('Microsoft Store Settings opens after the reset; the Store UI may need time to refresh.')
    }
    elseif ($toolId -eq 'updates-pause' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Windows Update is paused until the generated expiry timestamps, approximately 365 days from execution.')
        $sideEffects.Add('Windows Update Settings opens after the registry values are written.')
        $sideEffects.Add('Windows may require the Settings page to refresh before the pause state is displayed.')
    }
    elseif ($toolId -eq 'updates-pause' -and $ActionName -eq 'Default') {
        $sideEffects.Add('The six approved pause timestamps are removed so Windows Update returns to its default unpaused state.')
        $sideEffects.Add('Windows Update Settings opens after the values are removed.')
        $sideEffects.Add('Windows may require the Settings page to refresh before the default state is displayed.')
    }
    elseif ($toolId -eq 'theme-black' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Windows app and system theme values change to dark, transparency is disabled, and the approved black accent values are applied.')
        $sideEffects.Add('The source-compatible blacktheme.reg file remains in the Windows Temp directory.')
        $sideEffects.Add('Windows may require Settings, Explorer, sign-out, or a later session to visually refresh every theme element.')
    }
    elseif ($toolId -eq 'theme-black' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Theme, transparency, accent, DWM, and background values return to the explicit Ultimate default branch.')
        $sideEffects.Add('The HKLM Themes Personalize key is removed exactly as defined by the source, and defaulttheme.reg remains in Windows Temp.')
        $sideEffects.Add('Windows may require Settings, Explorer, sign-out, or a later session to visually refresh every theme element.')
    }
    elseif ($toolId -eq 'start-menu-layout' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('The four source-defined Windows feature overrides enable the recommended 25H2 Start menu behavior.')
        $sideEffects.Add('AllAppsViewMode changes to list view, and newstartmenu.reg remains in the Windows Temp directory.')
        $sideEffects.Add('Explorer, Start Menu, sign-out, or a later session may be required before the visual layout refreshes.')
    }
    elseif ($toolId -eq 'start-menu-layout' -and $ActionName -eq 'Default') {
        $sideEffects.Add('The four source-defined EnabledState values are removed and AllAppsViewMode returns to category view.')
        $sideEffects.Add('oldstartmenu.reg remains in the Windows Temp directory.')
        $sideEffects.Add('Explorer, Start Menu, sign-out, or a later session may be required before the visual layout refreshes.')
    }
    elseif ($toolId -eq 'context-menu' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Several Windows context-menu entries are hidden, including Scan with Microsoft Defender, Open in Terminal, and Give access to.')
        $sideEffects.Add('No Explorer process is stopped; reopening the context menu, Explorer refresh, or sign-out may be required before every visual change appears.')
    }
    elseif ($toolId -eq 'context-menu' -and $ActionName -eq 'Default') {
        $sideEffects.Add('The source context-menu handlers are restored and contextmenudefault.reg remains in the Windows Temp directory.')
        $sideEffects.Add('Only the three tool-owned Blocked GUID values are removed; unrelated values and the shared Blocked key are preserved.')
        $sideEffects.Add('No Explorer process is stopped; reopening the context menu, Explorer refresh, or sign-out may be required before every visual change appears.')
    }
    elseif ($toolId -eq 'signout-lockscreen-wallpaper-black' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('The desktop, sign-out, and lock screen wallpaper may become black.')
        $sideEffects.Add('A pre-existing unrelated C:\Windows\Black.jpg is copied to BoostLab state storage before replacement.')
        $sideEffects.Add('No process is stopped and no restart occurs; Windows may require lock, sign-out, Settings, or Explorer refresh before every visual change appears.')
    }
    elseif ($toolId -eq 'signout-lockscreen-wallpaper-black' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Wallpaper registry values return to the approved source default.')
        $sideEffects.Add('A recorded pre-existing Black.jpg is restored; an owned generated file is removed only when ownership is proven.')
        $sideEffects.Add('Unrelated PersonalizationCSP values and files are preserved, and uncertain file ownership is reported as a warning.')
    }
    elseif ($toolId -eq 'notepad-settings' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Running Notepad is closed and unsaved Notepad work can be lost.')
        $sideEffects.Add('The current user Notepad settings.dat is modified through a temporary mounted registry hive.')
        $sideEffects.Add('A verified pre-change backup and state record are retained under ProgramData\BoostLab\State; no Restore action is exposed.')
    }
    elseif ($toolId -eq 'notepad-settings' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Running Notepad is closed and unsaved Notepad work can be lost.')
        $sideEffects.Add('The exact current user Notepad settings.dat is deleted, so Notepad recreates default settings later.')
        $sideEffects.Add('A verified pre-delete backup and state record are retained under ProgramData\BoostLab\State; unrelated files are not deleted.')
    }
    elseif ($toolId -eq 'network-adapter-power-savings-wake' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Detected network adapters may use more power and will not wake from the source-defined wake events.')
        $sideEffects.Add('No adapter is disabled and no driver is installed, removed, replaced, or updated.')
        $sideEffects.Add('Device Manager, adapter refresh, or sign-out may be needed before every visible driver UI state updates; no restart is performed.')
    }
    elseif ($toolId -eq 'network-adapter-power-savings-wake' -and $ActionName -eq 'Default') {
        $sideEffects.Add('The source-defined adapter overrides are removed so each driver can return to its default behavior.')
        $sideEffects.Add('No unrelated adapter properties or registry values are removed.')
        $sideEffects.Add('Device Manager, adapter refresh, or sign-out may be needed before every visible driver UI state updates; no restart is performed.')
    }
    elseif ($toolId -eq 'write-cache-buffer-flushing' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Storage write-cache buffer flushing policy may change for detected SCSI and NVME disk registry paths.')
        $sideEffects.Add('Only CacheIsPowerProtected is written; no driver, service, device, or reboot action is performed.')
        $sideEffects.Add('The unsafe Ultimate Default broad Disk-key deletion is not implemented; captured value state is retained for future review.')
    }
    elseif ($toolId -eq 'power-plan' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Ultimate deletes every enumerated non-active power scheme. Existing custom power schemes are not captured and cannot be restored by Default.')
        $sideEffects.Add('Hibernation, Fast Startup, lock and sleep menu options, power throttling, sleep timers, battery protection actions, and many AC/DC settings are changed.')
        $sideEffects.Add('Critical and low battery notifications, actions, and thresholds are set to zero exactly as defined by Ultimate.')
        $sideEffects.Add('Power Options opens after execution. No reboot is performed, but the UI may need refresh.')
    }
    elseif ($toolId -eq 'power-plan' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Windows built-in power schemes are restored, but previously deleted custom schemes are not recovered.')
        $sideEffects.Add('The complete FlyoutMenuSettings and PowerThrottling keys are deleted exactly as defined by Ultimate, which may remove unrelated values in those keys.')
        $sideEffects.Add('Hibernation and Fast Startup are enabled, hidden setting attributes return to 1, and Power Options opens. No reboot is performed.')
    }
    elseif ($toolId -eq 'spectre-meltdown-assistant' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; only the two source-defined mitigation override values are read.')
        $sideEffects.Add('Registry inspection cannot prove the currently active kernel mitigation state.')
    }
    elseif ($toolId -eq 'spectre-meltdown-assistant' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('CPU vulnerability protection is reduced by disabling the source-targeted Spectre / Meltdown mitigations.')
        $sideEffects.Add('Only the two approved Ultimate registry values are written; no BCD, service, driver, process, or reboot behavior is added.')
        $sideEffects.Add('Verification confirms registry configuration only and does not claim to measure active kernel mitigation state.')
    }
    elseif ($toolId -eq 'spectre-meltdown-assistant' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Only the two source-defined override values are removed so Windows can use its default mitigation policy.')
        $sideEffects.Add('Already-absent values are treated as the approved default; unrelated Memory Management values are left intact.')
        $sideEffects.Add('Verification confirms registry configuration only and does not claim to measure active kernel mitigation state.')
    }
    elseif ($toolId -eq 'mmagent-assistant' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; the result compares the current state with the source-defined Off and Default profiles.')
        $sideEffects.Add('The source warns that MMAgent settings may take time to initialize after reboot before they can be checked accurately.')
    }
    elseif ($toolId -eq 'mmagent-assistant' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Windows prefetch and multiple MMAgent features are changed together exactly as defined by the approved Ultimate Off profile.')
        $sideEffects.Add('MemoryCompression is disabled here as part of the MMAgent profile; use the separate Memory Compression tool when only that setting should change.')
        $sideEffects.Add('No restart is performed, but the source warns that state initialization may take time after reboot before a later check.')
    }
    elseif ($toolId -eq 'mmagent-assistant' -and $ActionName -eq 'Default') {
        $sideEffects.Add('The approved Ultimate Default profile does not re-enable every MMAgent feature. MemoryCompression and PageCombining remain disabled by source design.')
        $sideEffects.Add('No restart is performed, but the source warns that state initialization may take time after reboot before a later check.')
    }
    elseif ($toolId -eq 'smt-ht-assistant' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; the result explains the temporary per-process affinity mask derived from the source logic.')
        $sideEffects.Add('The source workflow is temporary and affects a running process or a newly launched process rather than BIOS SMT/HT settings.')
    }
    elseif ($toolId -eq 'smt-ht-assistant' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Only the selected running process receives the temporary SMT / HT-off affinity mask. BIOS settings and permanent CPU configuration are not changed.')
        $sideEffects.Add('The selected process may behave differently because sibling logical threads are disabled for that process only.')
    }
    elseif ($toolId -eq 'smt-ht-assistant' -and $ActionName -eq 'Open') {
        $sideEffects.Add('Only the source-defined launcher process names are stopped before launch.')
        $sideEffects.Add('The selected launcher or executable is started with a temporary SMT / HT-off affinity mask. BIOS settings and permanent CPU configuration are not changed.')
        $sideEffects.Add('Verification may be inconclusive when a shortcut or launcher spawns a differently named child process.')
    }
    elseif ($toolId -eq 'to-bios' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made and no restart command is executed.')
    }
    elseif ($toolId -eq 'to-bios' -and $ActionName -eq 'Open') {
        $sideEffects.Add('The computer restarts immediately and unsaved work can be lost.')
        $sideEffects.Add('Windows requests the firmware settings interface, but firmware support ultimately determines whether it opens.')
        $sideEffects.Add('BoostLab does not modify BIOS or UEFI settings.')
    }
    if ($ActionName -eq 'Analyze' -and $toolId -ne 'driver-clean') {
        $sideEffects.Add('Read-only system information may be collected and displayed.')
    }
    elseif ($ActionName -eq 'Open' -and -not $capabilities.CanReboot -and $toolId -ne 'driver-clean') {
        $sideEffects.Add('A Windows interface or approved external resource may be opened.')
    }
    if ($capabilities.RequiresInternet) {
        $sideEffects.Add('The requested action may fail when internet access is unavailable.')
    }
    if ($capabilities.CanReboot -and $ActionName -ne 'Analyze') {
        $sideEffects.Add('The computer may restart; unsaved work could be lost.')
    }
    if ($isPotentialChangeAction -and $capabilities.CanModifyServices) {
        $sideEffects.Add('Service changes may affect dependent Windows or application features.')
    }
    if ($isPotentialChangeAction -and $capabilities.CanModifyDrivers) {
        $sideEffects.Add('Driver changes may affect display, devices, stability, or hardware availability.')
    }
    if ($isPotentialChangeAction -and $capabilities.CanModifySecurity) {
        $sideEffects.Add('Security changes may alter system protection or compatibility.')
    }
    if ($isPotentialChangeAction -and $capabilities.CanDeleteFiles) {
        $sideEffects.Add('Deleted files may not be recoverable unless an approved checkpoint exists.')
    }
    if ($isPotentialChangeAction -and $capabilities.CanInstallSoftware) {
        $sideEffects.Add('Installed software may add files, services, tasks, or application settings.')
    }
    if ($isPotentialChangeAction -and $capabilities.UsesTrustedInstaller) {
        $sideEffects.Add('TrustedInstaller execution has elevated system impact and requires explicit review.')
    }
    elseif ($capabilities.UsesTrustedInstaller) {
        $sideEffects.Add('TrustedInstaller capability is declared for this tool; no TrustedInstaller command is implemented in the current placeholder.')
    }
    if ($isPotentialChangeAction -and $capabilities.UsesSafeMode) {
        $sideEffects.Add('Safe Mode changes the next startup flow and requires a documented recovery path.')
    }
    if ($sideEffects.Count -eq 0) {
        $sideEffects.Add('No system-changing side effects are declared for this action.')
    }

    $confirmationMessage = if ($isProductScopeNotApplicable) {
        'No confirmation is required because this tool is not applicable on the current host and no changes will be executed.'
    }
    elseif ($toolId -eq 'unattended' -and $ActionName -eq 'Apply') {
        'BoostLab will create the approved Windows 11 autounattend.xml on selected removable media. The file creates a blank-password local administrator, skips OOBE, disables Dynamic Update, and bypasses TPM, RAM, Secure Boot, CPU, and storage checks. Existing source-targeted files will be backed up first. No installation or reboot starts now. Do you want to continue?'
    }
    elseif ($toolId -in @('bios-settings', 'to-bios') -and $ActionName -eq 'Open') {
        'This PC will restart immediately and attempt to enter BIOS/UEFI firmware settings. Save your work before continuing. Do you want to proceed?'
    }
    elseif ($toolId -eq 'driver-clean' -and $ActionName -eq 'Open') {
        'BoostLab will prepare Driver Clean manual handoff instructions only. It will not open an external tool, download DDU or 7-Zip, execute DDU, modify registry, create RunOnce, call bcdedit, switch Safe Mode, reboot, or clean drivers. Continue?'
    }
    elseif ($toolId -eq 'driver-clean' -and $ActionName -eq 'Apply') {
        'Driver Clean Auto mode is blocked. BoostLab will not execute Auto behavior because DDU/7-Zip artifact provenance, process handling, reboot/recovery, generated-script, and driver-state approvals are missing. Continue only to record the blocked result?'
    }
    elseif ($toolId -eq 'restore-point' -and $ActionName -eq 'Apply') {
        'BoostLab will enable System Restore on C:\ if needed and create a restore point named backup. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'widgets' -and $ActionName -eq 'Apply') {
        'BoostLab will disable Widgets by machine policy and close Widgets processes if they are running. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'widgets' -and $ActionName -eq 'Default') {
        'BoostLab will restore the approved default Widgets policy values. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'memory-compression' -and $ActionName -eq 'Apply') {
        'BoostLab will run Disable-MMAgent -MemoryCompression and verify the result. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'memory-compression' -and $ActionName -eq 'Default') {
        'BoostLab will run Enable-MMAgent -MemoryCompression and verify the result. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'background-apps' -and $ActionName -eq 'Apply') {
        'BoostLab will set LetAppsRunInBackground to 2 (Force deny), open Background Apps Settings, and verify the policy. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'background-apps' -and $ActionName -eq 'Default') {
        'BoostLab will remove the LetAppsRunInBackground policy value, open Background Apps Settings, and verify the default state. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'store-settings' -and $ActionName -eq 'Apply') {
        'BoostLab will apply the approved Microsoft Store registry and preference settings, close only approved Store process targets, and verify the result. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'store-settings' -and $ActionName -eq 'Default') {
        'BoostLab will remove the approved WindowsStore registry key, close only approved Store process targets, launch wsreset.exe, and verify the default policy state. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'updates-pause' -and $ActionName -eq 'Apply') {
        'BoostLab will write the six approved Windows Update pause timestamps for 365 days, open Windows Update Settings, and verify the values. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'updates-pause' -and $ActionName -eq 'Default') {
        'BoostLab will remove only the six approved Windows Update pause timestamps, open Windows Update Settings, and verify the default state. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'theme-black' -and $ActionName -eq 'Apply') {
        'BoostLab will import the approved Ultimate black theme registry payload and verify all source-defined values. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'theme-black' -and $ActionName -eq 'Default') {
        'BoostLab will import the approved Ultimate default theme payload, including removal of the HKLM Themes Personalize key, and verify the result. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'start-menu-layout' -and $ActionName -eq 'Apply') {
        'BoostLab will import the approved Ultimate 25H2 Start menu layout values and verify all five registry states plus the import file. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'start-menu-layout' -and $ActionName -eq 'Default') {
        'BoostLab will import the Ultimate 24H2 branch as the approved Default, removing only four EnabledState values and setting AllAppsViewMode to 0. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'context-menu' -and $ActionName -eq 'Apply') {
        'BoostLab will apply the approved Ultimate clean Context Menu registry behavior, including hiding the Defender scan context-menu entry, and verify all source-defined states. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'context-menu' -and $ActionName -eq 'Default') {
        'BoostLab will restore the source Context Menu handlers and remove only the three tool-owned Blocked GUID values. The shared Blocked key and unrelated values will remain. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'signout-lockscreen-wallpaper-black' -and $ActionName -eq 'Apply') {
        'BoostLab will back up any unrelated pre-existing C:\Windows\Black.jpg, generate the approved black wallpaper, set the owned PersonalizationCSP and desktop values, and verify ownership. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'signout-lockscreen-wallpaper-black' -and $ActionName -eq 'Default') {
        'BoostLab will remove only its two PersonalizationCSP values, restore the approved desktop wallpaper, and restore or remove Black.jpg only when backup or ownership state permits. Unrelated values and files will remain. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'notepad-settings' -and $ActionName -eq 'Apply') {
        'BoostLab will close Notepad, create and verify a backup of the exact Notepad settings.dat, import the three approved Ultimate settings through a mounted hive, unload it, and verify the result. Unsaved Notepad work can be lost. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'notepad-settings' -and $ActionName -eq 'Default') {
        'BoostLab will close Notepad, create and verify a backup of the exact Notepad settings.dat when it exists, then delete only that file so Notepad returns to its source-defined default state. Unsaved Notepad work can be lost. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'network-adapter-power-savings-wake' -and $ActionName -eq 'Apply') {
        'BoostLab will set the 14 approved power-saving and wake values on every detected network adapter class key and verify each value. No adapter will be disabled and no restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'network-adapter-power-savings-wake' -and $ActionName -eq 'Default') {
        'BoostLab will remove only the 14 approved network adapter power-saving and wake values and verify their default absent state. No adapter will be disabled and no restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'write-cache-buffer-flushing' -and $ActionName -eq 'Apply') {
        'BoostLab will capture the exact prior CacheIsPowerProtected value state on every detected source-targeted SCSI/NVME Disk path, then set only that value to REG_DWORD 1 and verify it. No driver change, broad key deletion, or reboot is performed. Do you want to continue?'
    }
    elseif ($toolId -eq 'power-plan' -and $ActionName -eq 'Apply') {
        'BoostLab will activate the approved Ultimate scheme, permanently delete other enumerated power schemes, disable hibernation, apply 36 AC/DC setting pairs and 10 registry values, and set battery warnings/actions/levels to zero. Custom schemes are not captured and Default cannot restore them. No restart is performed. Do you want to continue?'
    }
    elseif ($toolId -eq 'power-plan' -and $ActionName -eq 'Default') {
        'BoostLab will run restoredefaultschemes, enable hibernation, restore the explicit Ultimate defaults, and delete the complete FlyoutMenuSettings and PowerThrottling keys. Previously deleted custom schemes will not be recovered. No restart is performed. Do you want to continue?'
    }
    elseif ($toolId -eq 'spectre-meltdown-assistant' -and $ActionName -eq 'Apply') {
        'Security warning: BoostLab will set FeatureSettingsOverrideMask and FeatureSettingsOverride to 3 exactly as defined by Ultimate. This disables the source-targeted Spectre / Meltdown mitigations and reduces CPU vulnerability protection. No reboot is performed. Do you want to continue?'
    }
    elseif ($toolId -eq 'spectre-meltdown-assistant' -and $ActionName -eq 'Default') {
        'BoostLab will remove only FeatureSettingsOverrideMask and FeatureSettingsOverride from the source-defined ControlSet001 path so Windows can use its default mitigation policy. Already-absent values are accepted and no reboot is performed. Do you want to continue?'
    }
    elseif ($toolId -eq 'mmagent-assistant' -and $ActionName -eq 'Apply') {
        'BoostLab will apply the approved Ultimate MMAgent Off profile: set EnablePrefetcher to 0, disable ApplicationLaunchPrefetching, ApplicationPreLaunch, MemoryCompression, OperationAPI, and PageCombining, set MaxOperationAPIFiles to 1, and verify the result. No restart is performed. Do you want to continue?'
    }
    elseif ($toolId -eq 'mmagent-assistant' -and $ActionName -eq 'Default') {
        'BoostLab will restore the approved Ultimate MMAgent Default profile exactly as defined by the source: set EnablePrefetcher to 3, enable ApplicationLaunchPrefetching, ApplicationPreLaunch, and OperationAPI, set MaxOperationAPIFiles to 512, keep MemoryCompression and PageCombining disabled, and verify the result. No restart is performed. Do you want to continue?'
    }
    elseif ($toolId -eq 'smt-ht-assistant' -and $ActionName -eq 'Apply') {
        'BoostLab will let you choose a running process larger than 500 MB, then apply the source-derived SMT / HT-off affinity mask to that process only and verify the result. BIOS settings and permanent CPU configuration are not changed. No restart is performed. Do you want to continue?'
    }
    elseif ($toolId -eq 'smt-ht-assistant' -and $ActionName -eq 'Open') {
        'BoostLab will stop only the approved launcher process names, let you select a launcher, game, shortcut, or executable, then launch it with the source SMT / HT-off affinity mask and attempt verification after the source delay window. BIOS settings and permanent CPU configuration are not changed. No restart is performed. Do you want to continue?'
    }
    elseif ($capabilities.UsesTrustedInstaller) {
        "This action requires approved TrustedInstaller-level execution through BoostLab's centralized runtime helper. Administrator elevation and explicit confirmation are required. No TrustedInstaller execution is implemented yet."
    }
    elseif ($needsConfirmation) {
        "Review the action plan for $toolTitle. Confirm only if you understand the planned changes and side effects."
    }
    else {
        'No explicit confirmation is required for this action.'
    }

    $privilegeRequirements = [System.Collections.Generic.List[string]]::new()
    if ($isProductScopeNotApplicable) {
        $privilegeRequirements.Add('No Administrator execution required because no action will run on this unsupported host.')
    }
    elseif ($capabilities.RequiresAdmin) {
        $privilegeRequirements.Add('Administrator required')
    }
    if ($capabilities.UsesTrustedInstaller) {
        $privilegeRequirements.Add('TrustedInstaller required for approved tool-specific execution')
    }
    if ($privilegeRequirements.Count -eq 0) {
        $privilegeRequirements.Add('No tool-specific elevated privilege required')
    }

    return [pscustomobject]@{
        ToolId                    = $toolId
        ToolTitle                 = $toolTitle
        Action                    = $ActionName
        RiskLevel                 = $riskLevel
        Capabilities              = $capabilities
        Summary                   = $summary
        PlannedChanges            = $plannedChanges.ToArray()
        SideEffects               = $sideEffects.ToArray()
        RequiresAdmin             = if ($isProductScopeNotApplicable) { $false } else { [bool]$capabilities.RequiresAdmin }
        UsesTrustedInstaller      = [bool]$capabilities.UsesTrustedInstaller
        UsesSafeMode              = [bool]$capabilities.UsesSafeMode
        PrivilegeRequirements     = $privilegeRequirements.ToArray()
        RequiresInternet          = [bool]$capabilities.RequiresInternet
        CanReboot                 = [bool]$capabilities.CanReboot
        NeedsExplicitConfirmation = [bool]$needsConfirmation
        SupportsDefault           = [bool]$capabilities.SupportsDefault
        SupportsRestore           = [bool]$capabilities.SupportsRestore
        ConfirmationMessage       = $confirmationMessage
        IsDryRun                  = $IsDryRun
        Timestamp                 = Get-Date
    }
}

Export-ModuleMember -Function @(
    'ConvertTo-BoostLabCapabilityObject'
    'Test-BoostLabPlanNeedsConfirmation'
    'New-BoostLabActionPlan'
)
