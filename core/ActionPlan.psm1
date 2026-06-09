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
    $needsConfirmation = Test-BoostLabPlanNeedsConfirmation `
        -RiskLevel $riskLevel `
        -Capabilities $capabilities `
        -ActionName $ActionName
    if ($toolId -eq 'restore-point' -and $ActionName -eq 'Open') {
        $needsConfirmation = $false
    }

    $summary = if ($toolId -eq 'restore-point' -and $ActionName -eq 'Apply') {
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
    if ($toolId -eq 'restore-point' -and $ActionName -eq 'Apply') {
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
    if ($toolId -eq 'restore-point' -and $ActionName -eq 'Apply') {
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
    if ($ActionName -eq 'Analyze') {
        $sideEffects.Add('Read-only system information may be collected and displayed.')
    }
    elseif ($ActionName -eq 'Open' -and -not $capabilities.CanReboot) {
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

    $confirmationMessage = if ($toolId -eq 'bios-settings' -and $ActionName -eq 'Open') {
        'This PC will restart immediately and attempt to enter BIOS/UEFI firmware settings. Save your work before continuing. Do you want to proceed?'
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
    if ($capabilities.RequiresAdmin) {
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
        RequiresAdmin             = [bool]$capabilities.RequiresAdmin
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
