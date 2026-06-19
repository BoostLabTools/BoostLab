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
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Analyze') {
        'Read the Driver Install Latest source mirror and report blocked NVIDIA driver approvals without downloading or installing anything.'
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Open') {
        'Prepare Driver Install Latest manual handoff instructions only; no browser, external tool, NVIDIA driver download, installer execution, or system-changing operation is opened or executed.'
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Apply') {
        'Auto mode is blocked for Driver Install Latest because NVIDIA artifact, installer, driver-state, process, reboot/session, and recovery approvals do not exist.'
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Analyze') {
        'Analyze the Installers source and report blocked per-app artifact, installer, package, side-effect, cleanup, rollback, and support approvals without running any installer workflow.'
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Open') {
        'Prepare Installers manual handoff instructions only; no browser, Explorer, Settings, Store, external tool, download, installer, package action, file mutation, registry change, service change, task change, cleanup, reboot, or system mutation is opened or executed.'
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Apply') {
        'Auto mode is blocked for Installers because per-app artifact provenance, installer execution, side-effect scopes, inventory, cleanup, rollback, and support approvals do not exist.'
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Default') {
        'Default is unavailable because the source does not define a safe global Installers default branch.'
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Restore') {
        'Restore is unavailable because no captured package, installer, file, registry, service, task, shortcut, app configuration, cleanup, or support state restore contract exists.'
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Analyze') {
        'Analyze the Edge & WebView source and report blocked artifact, repair, installer, package, process, service, task, file, registry, cleanup, rollback, and support approvals without running any Edge/WebView workflow.'
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Open') {
        'Prepare Edge & WebView manual handoff instructions only; no browser, Explorer, Settings, Store, Edge, WebView, external tool, download, repair, installer, package action, process handling, file mutation, registry change, service change, task change, cleanup, reboot, or system mutation is opened or executed.'
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Apply') {
        'Auto mode is blocked for Edge & WebView because artifact provenance, repair/installer execution, package scopes, process handling, service/task/file/registry cleanup, rollback, and support approvals do not exist.'
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Default') {
        'Default is unavailable because the source Default branch downloads and runs repair installers and performs unapproved policy, service, task, Active Setup, RunOnce, and BHO mutations.'
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Restore') {
        'Restore is unavailable because no captured Edge/WebView package, installer, file, registry, service, task, process, cleanup, or support state restore contract exists.'
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Analyze') {
        'Analyze the Driver Install Debloat & Settings source and report blocked approvals without running any driver install, debloat, profile, registry, package, or reboot operation.'
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Open') {
        'Prepare Driver Install Debloat & Settings manual handoff instructions only; no browser, external tool, download, installer, driver mutation, cleanup, profile import, package action, or reboot is opened or executed.'
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Apply') {
        'Auto mode is blocked for Driver Install Debloat & Settings because artifact, installer, driver-state, process, cleanup, AppX/package, profile, registry, reboot, and recovery approvals do not exist.'
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Default') {
        'Default is unavailable because the source does not define a safe overall default mutation for the driver install/debloat workflow.'
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Restore') {
        'Restore is unavailable because no captured driver/profile/package/registry/file/reboot state restore contract exists.'
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Analyze') {
        'Analyze the DirectX source and report blocked artifact, extraction, installer, registry, shortcut, cleanup, and rollback approvals without running any DirectX or 7-Zip workflow.'
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Open') {
        'Prepare DirectX manual handoff instructions only; no browser, external tool, download, extraction, installer, registry change, shortcut cleanup, file cleanup, or system mutation is opened or executed.'
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Apply') {
        'Auto mode is blocked for DirectX because immutable artifact, extraction, installer, side-effect scope, cleanup, and rollback approvals do not exist.'
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Default') {
        'Default is unavailable because the source does not define a safe DirectX default branch.'
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Restore') {
        'Restore is unavailable because no captured artifact, registry, shortcut, file, installer, or cleanup state restore contract exists.'
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Analyze') {
        'Analyze the Visual C++ source and report blocked twelve-package artifact, installer, exit-code, temp-file, cleanup, and rollback/support approvals without running any Visual C++ workflow.'
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Open') {
        'Prepare Visual C++ manual handoff instructions only; no browser, external tool, download, installer, package change, registry change, temp-file change, file cleanup, or system mutation is opened or executed.'
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Apply') {
        'Auto mode is blocked for Visual C++ because immutable artifacts, installer descriptors, exit-code rules, temp-file ownership, cleanup, and rollback/support approvals do not exist.'
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Default') {
        'Default is unavailable because the source does not define a safe Visual C++ default branch.'
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Restore') {
        'Restore is unavailable because no captured artifact, package, registry, temp-file, installer, or cleanup state restore contract exists.'
    }
    elseif ($toolId -eq 'reinstall' -and $ActionName -eq 'Analyze') {
        'Analyze the Reinstall source and report the controlled Windows 11 Media Creation Tool operation without downloading or launching anything.'
    }
    elseif ($toolId -eq 'reinstall' -and $ActionName -eq 'Open') {
        'Prepare Reinstall guidance only; no browser, Explorer, Settings, external tool, Windows media download, Media Creation Tool launch, setup command, file mutation, reboot, recovery, or system mutation is opened or executed.'
    }
    elseif ($toolId -eq 'reinstall' -and $ActionName -eq 'Apply') {
        'Download the source-defined Windows 11 Media Creation Tool to Windows Temp and launch it after explicit confirmation.'
    }
    elseif ($toolId -eq 'reinstall' -and $ActionName -eq 'Default') {
        'Default is unavailable because the source does not define a safe Reinstall default branch.'
    }
    elseif ($toolId -eq 'reinstall' -and $ActionName -eq 'Restore') {
        'Restore is unavailable because no captured reinstall, setup, generated-file, reboot/session, recovery, or support state restore contract exists.'
    }
    elseif ($toolId -eq 'updates-drivers-block' -and $ActionName -eq 'Analyze') {
        'Analyze the Yazan-selected Driver Updates Block Bootable USB scope without changing the system.'
    }
    elseif ($toolId -eq 'updates-drivers-block' -and $ActionName -eq 'Apply') {
        'Create only the source-equivalent Driver Updates Block setupcomplete.cmd on selected USB media after source validation and pre-change file state capture.'
    }
    elseif ($toolId -eq 'updates-drivers-block' -and $ActionName -eq 'Default') {
        'Default is unavailable because Yazan final scope excludes Unblock and live local default behavior.'
    }
    elseif ($toolId -eq 'updates-drivers-block' -and $ActionName -eq 'Restore') {
        'Restore only from a valid selected captured USB setupcomplete.cmd file rollback record from this Updates Drivers Block tool.'
    }
    elseif ($toolId -eq 'nvidia-settings' -and $ActionName -eq 'Analyze') {
        'Read the Nvidia Settings source mirror and report blocked 7-Zip, Profile Inspector, .nip, NVIDIA profile, registry, process, and verification approvals without changing settings.'
    }
    elseif ($toolId -eq 'nvidia-settings' -and $ActionName -eq 'Open') {
        'Prepare Nvidia Settings manual handoff instructions only; no 7-Zip, Profile Inspector, .nip, Control Panel, browser, external process, registry/profile mutation, or system-changing operation is opened or executed.'
    }
    elseif ($toolId -eq 'nvidia-settings' -and $ActionName -eq 'Apply') {
        'Auto mode is blocked for Nvidia Settings because 7-Zip, Profile Inspector, .nip, profile capture/restore, registry/file rollback, process, and verification approvals do not exist.'
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Analyze') {
        'Read the HDCP source mirror and report source-defined NVIDIA display-class registry scope, target discovery, Apply availability, Default availability, and Restore availability without changing the system.'
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Apply') {
        'Apply the source-defined HDCP Off value only to eligible NVIDIA display-class registry targets after source checksum validation and pre-change registry state capture; excluded Microsoft/RDP/non-NVIDIA targets are skipped.'
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Default') {
        'Apply the source-defined HDCP Default value only to eligible NVIDIA display-class registry targets after source checksum validation and pre-change registry state capture; excluded Microsoft/RDP/non-NVIDIA targets are skipped.'
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Restore') {
        'Report Restore as unavailable unless a valid selected captured rollback record from this HDCP tool is provided. No registry mutation is planned without selected captured state.'
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Analyze') {
        'Read the P0 State source mirror and report source-defined NVIDIA display-class registry scope, target classification, Apply availability, Default availability, and Restore availability without changing the system.'
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Apply') {
        'Apply the source-defined P0 State On value only to eligible NVIDIA display-class registry targets after source checksum validation and pre-change registry state capture; excluded Microsoft/RDP/non-NVIDIA targets are skipped.'
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Default') {
        'Apply the source-defined P0 State Default value only to eligible NVIDIA display-class registry targets after source checksum validation and pre-change registry state capture; excluded Microsoft/RDP/non-NVIDIA targets are skipped.'
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Restore') {
        'Report Restore as unavailable unless a valid selected captured rollback record from this P0 State tool is provided. No registry mutation is planned without selected captured state.'
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Analyze') {
        'Read the Msi Mode source mirror and report source-defined NVIDIA display-device Enum registry scope, target classification, Apply availability, Default availability, and Restore availability without changing the system.'
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Apply') {
        'Apply the source-defined Msi Mode On value only to eligible NVIDIA display-device Enum registry targets after source checksum validation and pre-change registry state capture; excluded Microsoft/RDP/non-NVIDIA targets are skipped.'
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Default') {
        'Apply the source-defined Msi Mode Default value only to eligible NVIDIA display-device Enum registry targets after source checksum validation and pre-change registry state capture; excluded Microsoft/RDP/non-NVIDIA targets are skipped.'
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Restore') {
        'Report Restore as unavailable unless a valid selected captured rollback record from this Msi Mode tool is provided. No registry mutation is planned without selected captured state.'
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
    elseif ($toolId -eq 'bitlocker' -and $ActionName -eq 'Analyze') {
        'Analyze BitLocker volume state read-only and preview the source-equivalent Off and On/status behavior without changing encryption state.'
    }
    elseif ($toolId -eq 'bitlocker' -and $ActionName -eq 'Open') {
        'Run the source-equivalent BitLocker On/status branch: open BitLocker Drive Encryption Control Panel and run manage-bde -status without enabling BitLocker automatically.'
    }
    elseif ($toolId -eq 'bitlocker' -and $ActionName -eq 'Apply') {
        'Run the source-equivalent BitLocker Off branch: disable BitLocker only on source-matched volumes, then open BitLocker status UI and run manage-bde -status.'
    }
    elseif ($toolId -eq 'bitlocker' -and $ActionName -eq 'Default') {
        'Block Default because the source On branch is UI/status-only and does not define a safe default mutation.'
    }
    elseif ($toolId -eq 'bitlocker' -and $ActionName -eq 'Restore') {
        'Block Restore because no captured BitLocker state restore contract exists.'
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
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Read the Driver Install Latest source mirror checksum and implementation status.')
        $plannedChanges.Add('Report missing NVIDIA driver artifact/download, installer descriptor, driver-state, process handoff, reboot/session, and recovery approvals.')
        $plannedChanges.Add('Report Path B step 1 of 5 while keeping Driver Install Latest separate from Nvidia Settings, Hdcp, P0 State, and Msi Mode.')
        $plannedChanges.Add('Perform no NVIDIA driver download, installer execution, browser opening, external process start, registry mutation, driver mutation, reboot, or session change.')
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Open') {
        $plannedChanges.Add('Prepare manual handoff instructions only.')
        $plannedChanges.Add('Do not open a browser, external tool, NVIDIA installer, or approved external resource.')
        $plannedChanges.Add('Do not download an NVIDIA driver or 7-Zip.')
        $plannedChanges.Add('Do not execute an NVIDIA installer.')
        $plannedChanges.Add('Do not modify registry, drivers, services, files, sessions, or reboot state.')
        $plannedChanges.Add('Keep Path B steps separate: Driver Install Latest, Nvidia Settings, Hdcp, P0 State, and Msi Mode.')
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Block Auto mode before any operational step.')
        $plannedChanges.Add('Do not execute any approved Auto behavior because none is approved.')
        $plannedChanges.Add('Report missing NVIDIA driver artifact/download approval, installer execution descriptor approval, driver state capture/rollback approval, process handoff approval, reboot/session handling approval, and recovery handling approval.')
        $plannedChanges.Add('Perform no NVIDIA driver download, installer execution, external process start, registry/system/driver mutation, reboot, or session change.')
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Read the Installers source checksum and implementation status.')
        $plannedChanges.Add('Report source behavior summary and missing per-app artifact provenance, installer execution, switch validation, exit-code, side-effect, inventory, cleanup, rollback, and support approvals.')
        $plannedChanges.Add('Perform no download, browser/Explorer/Settings/Store/external process launch, installer execution, package action, file mutation, registry/service/task/shortcut mutation, cleanup, reboot, or system mutation.')
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Open') {
        $plannedChanges.Add('Prepare manual handoff instructions inside BoostLab only.')
        $plannedChanges.Add('Do not open a browser, Explorer, Settings, Store, app installer, package manager, script, or external tool.')
        $plannedChanges.Add('Do not download app installers, archives, scripts, packages, or artifacts.')
        $plannedChanges.Add('Do not run installers, setup executables, package managers, Store actions, AppX actions, MSI packages, scripts, or helpers.')
        $plannedChanges.Add('Do not install, uninstall, repair, update, remove, or configure packages or apps.')
        $plannedChanges.Add('Do not create, delete, or mutate files, temp folders, shortcuts, registry, services, scheduled tasks, firewall, devices, drivers, reboot/session state, or app configuration.')
        $plannedChanges.Add('Perform no system-changing operation.')
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Block Auto mode before any operational step.')
        $plannedChanges.Add('Do not execute any approved Auto behavior because none is approved.')
        $plannedChanges.Add('Report missing per-app artifact provenance, installer descriptors, silent-switch validation, exit-code handling, generated-file ownership, cleanup, side-effect scopes, rollback, and support approvals.')
        $plannedChanges.Add('Perform no download, installer execution, package action, file mutation, registry/service/task/shortcut mutation, cleanup, reboot, or system mutation.')
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Block Default before any operational step.')
        $plannedChanges.Add('Do not treat Default as Restore.')
        $plannedChanges.Add('Do not invent a global app default, uninstall, repair, registry, service, task, shortcut, cleanup, reboot, or system mutation.')
        $plannedChanges.Add('Perform no system-changing operation.')
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Restore') {
        $plannedChanges.Add('Block Restore before any operational step.')
        $plannedChanges.Add('Require valid selected captured package, installer, file, registry, service, scheduled-task, shortcut, app configuration, cleanup, and support state plus an approved Restore contract before any Restore can be planned.')
        $plannedChanges.Add('Do not treat source install behavior, Apply, or Default as captured-state Restore.')
        $plannedChanges.Add('Perform no system-changing operation.')
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Read the Edge & WebView source checksum and implementation status.')
        $plannedChanges.Add('Report source behavior summary and missing artifact provenance, repair/installer execution, package/AppX, process handling, service rollback, scheduled-task governance, file/registry cleanup, rollback, and support approvals.')
        $plannedChanges.Add('Perform no download, browser/Explorer/Settings/Store/Edge/WebView/external process launch, repair, installer execution, package action, process stop/start, file mutation, registry/service/task/shortcut mutation, cleanup, reboot, or system mutation.')
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Open') {
        $plannedChanges.Add('Prepare manual handoff instructions inside BoostLab only.')
        $plannedChanges.Add('Do not open a browser, Explorer, Settings, Store, Edge, WebView, repair installer, package manager, script, or external tool.')
        $plannedChanges.Add('Do not download Edge, WebView, installer, repair, script, package, archive, or artifact content.')
        $plannedChanges.Add('Do not run setup, repair, installer, winget, Store, AppX, MSI, EXE, script, package, or helper behavior.')
        $plannedChanges.Add('Do not install, uninstall, repair, update, reset, remove, or configure Edge, WebView, packages, services, tasks, policies, BHO, Active Setup, or RunOnce state.')
        $plannedChanges.Add('Do not stop or start Edge/WebView processes or services.')
        $plannedChanges.Add('Do not create, delete, or mutate files, temp folders, shortcuts, registry, services, scheduled tasks, firewall, devices, drivers, reboot/session state, or app configuration.')
        $plannedChanges.Add('Perform no system-changing operation.')
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Block Auto mode before any operational step.')
        $plannedChanges.Add('Do not execute any approved Auto behavior because none is approved.')
        $plannedChanges.Add('Report missing Edge/WebView artifact provenance, repair and installer descriptors, package scopes, process handling, service/task/file/registry cleanup scopes, rollback, and support approvals.')
        $plannedChanges.Add('Perform no download, repair, installer execution, package action, process stop/start, file mutation, registry/service/task/shortcut mutation, cleanup, reboot, or system mutation.')
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Block Default before any operational step.')
        $plannedChanges.Add('Do not treat Default as Restore.')
        $plannedChanges.Add('Do not run the source Default repair installers or invent a safe Edge/WebView default.')
        $plannedChanges.Add('Perform no download, repair, installer execution, package action, policy, service, task, Active Setup, RunOnce, BHO, cleanup, reboot, or system mutation.')
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Restore') {
        $plannedChanges.Add('Block Restore before any operational step.')
        $plannedChanges.Add('Require valid selected captured Edge/WebView package, installer, file, registry, service, scheduled-task, process, cleanup, and support state plus an approved Restore contract before any Restore can be planned.')
        $plannedChanges.Add('Do not treat source uninstall, Default repair, or Apply behavior as captured-state Restore.')
        $plannedChanges.Add('Perform no system-changing operation.')
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Read the Driver Install Debloat & Settings source checksum and implementation status.')
        $plannedChanges.Add('Report source behavior summary, unsupported AMD/Intel branches, and missing 7-Zip, NVIDIA driver, installer, extraction, cleanup/debloat, winget/AppX/package, Profile Inspector/.nip, registry/profile, driver-state, process, reboot/session, and recovery approvals.')
        $plannedChanges.Add('Keep Driver Install Debloat & Settings separate from Driver Clean and NVIDIA Path B.')
        $plannedChanges.Add('Perform no download, browser/external process launch, installer execution, file cleanup, profile import, package action, registry/service/driver mutation, reboot, or session change.')
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Open') {
        $plannedChanges.Add('Prepare manual handoff instructions inside BoostLab only.')
        $plannedChanges.Add('Do not open a browser, NVIDIA driver page, NVIDIA Control Panel, winget, 7-Zip installer, Profile Inspector, setup.exe, or any external tool.')
        $plannedChanges.Add('Do not download 7-Zip, NVIDIA driver artifacts, Profile Inspector, .nip files, or package content.')
        $plannedChanges.Add('Do not extract driver packages, delete driver components, run setup.exe, import profiles, install NVIDIA Control Panel, or remove AppX/winget packages.')
        $plannedChanges.Add('Do not modify registry, services, drivers, files, profiles, display settings, sound settings, sessions, or reboot state.')
        $plannedChanges.Add('Perform no system-changing operation.')
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Block Auto mode before any operational step.')
        $plannedChanges.Add('Do not execute any approved Auto behavior because none is approved.')
        $plannedChanges.Add('Report missing 7-Zip, NVIDIA driver, installer, extraction, cleanup/debloat, winget/AppX/package, Profile Inspector/.nip, registry/profile, driver-state, process, reboot/session, and recovery approvals.')
        $plannedChanges.Add('Perform no download, browser/external process launch, installer execution, file cleanup, profile import, package action, registry/service/driver mutation, reboot, or session change.')
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Block Default before any operational step.')
        $plannedChanges.Add('Do not treat Default as Restore.')
        $plannedChanges.Add('Do not invent a default driver, profile, package, registry, file, service, or reboot mutation.')
        $plannedChanges.Add('Perform no system-changing operation.')
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Restore') {
        $plannedChanges.Add('Block Restore before any operational step.')
        $plannedChanges.Add('Require valid selected captured driver/profile/package/registry/file/reboot state and an approved Restore contract before any Restore can be planned.')
        $plannedChanges.Add('Do not treat source install/debloat, Apply, or Default as captured-state Restore.')
        $plannedChanges.Add('Perform no system-changing operation.')
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Read the DirectX source checksum and implementation status.')
        $plannedChanges.Add('Report source behavior summary and missing 7-Zip artifact, DirectX artifact, extraction inventory, installer execution, registry/shortcut/file side-effect, cleanup, and rollback approvals.')
        $plannedChanges.Add('Perform no download, browser/external process launch, extraction, installer execution, registry change, shortcut cleanup, file cleanup, or system mutation.')
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Open') {
        $plannedChanges.Add('Prepare manual handoff instructions inside BoostLab only.')
        $plannedChanges.Add('Do not open a browser, external tool, 7-Zip installer, DirectX runtime package, extraction tool, or DirectX setup executable.')
        $plannedChanges.Add('Do not download 7-Zip or DirectX artifacts.')
        $plannedChanges.Add('Do not install 7-Zip, write 7-Zip registry options, move or remove 7-Zip Start Menu shortcuts, extract DirectX files, or launch DirectX setup.')
        $plannedChanges.Add('Perform no system-changing operation.')
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Block Auto mode before any operational step.')
        $plannedChanges.Add('Do not execute any approved Auto behavior because none is approved.')
        $plannedChanges.Add('Report missing 7-Zip artifact, DirectX artifact, extraction inventory, installer execution, registry/shortcut/file side-effect, cleanup, and rollback approvals.')
        $plannedChanges.Add('Perform no download, extraction, installer execution, registry change, shortcut cleanup, file cleanup, or system mutation.')
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Block Default before any operational step.')
        $plannedChanges.Add('Do not treat Default as Restore.')
        $plannedChanges.Add('Do not invent a DirectX default artifact, installer, registry, shortcut, file, cleanup, or system mutation.')
        $plannedChanges.Add('Perform no system-changing operation.')
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Restore') {
        $plannedChanges.Add('Block Restore before any operational step.')
        $plannedChanges.Add('Require valid selected captured artifact, registry, shortcut, file, installer, and cleanup state plus an approved Restore contract before any Restore can be planned.')
        $plannedChanges.Add('Do not treat source installation, Apply, or Default as captured-state Restore.')
        $plannedChanges.Add('Perform no system-changing operation.')
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Read the Visual C++ source checksum and implementation status.')
        $plannedChanges.Add('Report source behavior summary and missing twelve-package artifact, installer execution, exit-code, temp-file ownership, cleanup, and rollback/support approvals.')
        $plannedChanges.Add('Perform no download, browser/external process launch, installer execution, package change, registry change, temp-file change, file cleanup, or system mutation.')
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Open') {
        $plannedChanges.Add('Prepare manual handoff instructions inside BoostLab only.')
        $plannedChanges.Add('Do not open a browser, external tool, Visual C++ redistributable package, or Visual C++ installer executable.')
        $plannedChanges.Add('Do not download Visual C++ artifacts.')
        $plannedChanges.Add('Do not launch Visual C++ installers, change package state, write registry, change temp files, or perform cleanup.')
        $plannedChanges.Add('Perform no system-changing operation.')
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Block Auto mode before any operational step.')
        $plannedChanges.Add('Do not execute any approved Auto behavior because none is approved.')
        $plannedChanges.Add('Report missing twelve-package Visual C++ artifact provenance, installer execution, exit-code, temp-file ownership, cleanup, and rollback/support approvals.')
        $plannedChanges.Add('Perform no download, installer execution, package change, registry change, temp-file change, file cleanup, or system mutation.')
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Block Default before any operational step.')
        $plannedChanges.Add('Do not treat Default as Restore.')
        $plannedChanges.Add('Do not invent a Visual C++ default artifact, package, installer, registry, temp-file, cleanup, or system mutation.')
        $plannedChanges.Add('Perform no system-changing operation.')
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Restore') {
        $plannedChanges.Add('Block Restore before any operational step.')
        $plannedChanges.Add('Require valid selected captured artifact, package, registry, temp-file, installer, and cleanup state plus an approved Restore contract before any Restore can be planned.')
        $plannedChanges.Add('Do not treat source installation, Apply, or Default as captured-state Restore.')
        $plannedChanges.Add('Perform no system-changing operation.')
    }
    elseif ($toolId -eq 'reinstall' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Read the Reinstall source checksum and implementation status.')
        $plannedChanges.Add('Report source behavior summary, Windows 11 target scope, unsupported Windows 10 branch, and the controlled Apply operation.')
        $plannedChanges.Add('Perform no download, browser/Explorer/Settings/external process launch, setup execution, file mutation, registry/service/package/device/driver mutation, recovery workflow, reboot, or system mutation.')
    }
    elseif ($toolId -eq 'reinstall' -and $ActionName -eq 'Open') {
        $plannedChanges.Add('Prepare Reinstall guidance inside BoostLab only.')
        $plannedChanges.Add('Do not open a browser, Explorer, Settings, Media Creation Tool, setup executable, installer, recovery tool, or any external tool.')
        $plannedChanges.Add('Do not download Windows media, Media Creation Tool executables, installers, setup files, ISOs, scripts, or artifacts.')
        $plannedChanges.Add('Do not create, delete, or mutate setup files, media folders, temp files, boot files, recovery files, partitions, registry, services, scheduled tasks, packages, devices, or drivers.')
        $plannedChanges.Add('Do not start setup, media creation, repair, refresh, recovery, or reinstall workflows.')
        $plannedChanges.Add('Do not reboot or change session state.')
        $plannedChanges.Add('Perform no system-changing operation.')
    }
    elseif ($toolId -eq 'reinstall' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Verify the Reinstall source checksum before any operation.')
        $plannedChanges.Add('Require explicit Action Plan confirmation, Administrator elevation, and internet connectivity.')
        $plannedChanges.Add('Download the source-defined Windows 11 Media Creation Tool from the Ultimate source URL to %SystemRoot%\Temp\mediacreationtoolw11.exe.')
        $plannedChanges.Add('Launch the downloaded Windows 11 Media Creation Tool with Start-Process.')
        $plannedChanges.Add('Hand off all media creation, refresh, reinstall, session-change, and reboot decisions to the Microsoft tool after launch.')
        $plannedChanges.Add('Keep the Windows 10 Media Creation Tool branch unsupported.')
        $plannedChanges.Add('Do not run setup.exe directly, pass installer switches, partition disks, format media, modify registry/services/packages/devices/drivers, or reboot from BoostLab.')
    }
    elseif ($toolId -eq 'reinstall' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Block Default before any operational step.')
        $plannedChanges.Add('Do not treat Default as Restore.')
        $plannedChanges.Add('Do not invent a reinstall, setup, file, registry, service, package, recovery, reboot, or system mutation.')
        $plannedChanges.Add('Perform no system-changing operation.')
    }
    elseif ($toolId -eq 'reinstall' -and $ActionName -eq 'Restore') {
        $plannedChanges.Add('Block Restore before any operational step.')
        $plannedChanges.Add('Require valid selected captured reinstall, setup, generated-file, reboot/session, recovery, and support state plus an approved Restore contract before any Restore can be planned.')
        $plannedChanges.Add('Do not treat source download/launch behavior, Apply, or Default as captured-state Restore.')
        $plannedChanges.Add('Perform no system-changing operation.')
    }
    elseif ($toolId -eq 'updates-drivers-block' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Verify the Updates Drivers Block source checksum.')
        $plannedChanges.Add('Report Yazan final scope: Driver Updates Block Bootable USB only.')
        $plannedChanges.Add('Report unsupported live host registry Block/Unblock, broad Updates Block, broad Updates USB, custom update-server, Windows Update execution, external-process, and reboot branches as omitted.')
        $plannedChanges.Add('Perform no file capture, file write, registry capture, registry write, registry deletion, driver/device mutation, Windows Update execution, download, external process launch, or reboot.')
    }
    elseif ($toolId -eq 'updates-drivers-block' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Verify the Updates Drivers Block source checksum before mutation.')
        $plannedChanges.Add('Require an explicit selected removable USB/root target before any file operation.')
        $plannedChanges.Add('Capture the existing selected USB setupcomplete.cmd file state before create or overwrite.')
        $plannedChanges.Add('Create or update only sources\$OEM$\$$\Setup\Scripts\setupcomplete.cmd on the selected USB target with the source-equivalent Driver Updates Block Bootable USB content.')
        $plannedChanges.Add('Verify the generated setupcomplete.cmd content and record post-mutation file state for selected captured-state Restore.')
        $plannedChanges.Add('Do not execute setupcomplete.cmd, write host registry policy values, delete host registry values, run Windows Update, change drivers/devices, download, launch external tools, or reboot.')
    }
    elseif ($toolId -eq 'updates-drivers-block' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Block Default before any operational step.')
        $plannedChanges.Add('Do not expose Unblock because Yazan final scope is Driver Updates Block Bootable USB only.')
        $plannedChanges.Add('Do not delete live local Driver Updates policy values, broad Windows Update values, custom update-server values, or USB files.')
        $plannedChanges.Add('Do not treat Default as Restore.')
        $plannedChanges.Add('Perform no system-changing operation.')
    }
    elseif ($toolId -eq 'updates-drivers-block' -and $ActionName -eq 'Restore') {
        $plannedChanges.Add('Require a valid selected captured USB setupcomplete.cmd file rollback record from this Updates Drivers Block tool before any Restore operation can be planned.')
        $plannedChanges.Add('Validate that the selected record targets sources\$OEM$\$$\Setup\Scripts\setupcomplete.cmd captured by Apply.')
        $plannedChanges.Add('If a valid selected record is provided, restore only the exact captured prior USB file state from that selected record.')
        $plannedChanges.Add('Fail closed when no selected captured USB file state is available; no file or registry mutation is planned without selected captured state.')
        $plannedChanges.Add('Do not treat Restore as Unblock or Default.')
    }
    elseif ($toolId -eq 'nvidia-settings' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Read the Nvidia Settings source mirror checksum and implementation status.')
        $plannedChanges.Add('Report missing 7-Zip artifact/download/install approval, NVIDIA Profile Inspector artifact/download/execution approval, .nip import/export approval, NVIDIA profile state capture/restore approval, NVIDIA registry/file rollback capture approval, process handling approval, and verification approval.')
        $plannedChanges.Add('Report Path B step 2 of 5 while keeping Nvidia Settings separate from Driver Install Latest, Hdcp, P0 State, and Msi Mode.')
        $plannedChanges.Add('Perform no 7-Zip download/install, Profile Inspector download/execution, .nip import/export, NVIDIA Control Panel launch, external process start, registry/profile mutation, or system mutation.')
    }
    elseif ($toolId -eq 'nvidia-settings' -and $ActionName -eq 'Open') {
        $plannedChanges.Add('Prepare manual handoff instructions only for Path B step 2.')
        $plannedChanges.Add('Do not download or install 7-Zip.')
        $plannedChanges.Add('Do not download or run NVIDIA Profile Inspector.')
        $plannedChanges.Add('Do not import, export, or generate a .nip file for execution.')
        $plannedChanges.Add('Do not open NVIDIA Control Panel, a browser, external tool, or approved external resource.')
        $plannedChanges.Add('Do not modify NVIDIA profiles, NVIDIA registry settings, Windows Registry values, files, drivers, sessions, or reboot state.')
        $plannedChanges.Add('Keep Path B steps separate: Driver Install Latest, Nvidia Settings, Hdcp, P0 State, and Msi Mode.')
    }
    elseif ($toolId -eq 'nvidia-settings' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Block Auto mode before any operational step.')
        $plannedChanges.Add('Do not execute any approved Auto behavior because none is approved.')
        $plannedChanges.Add('Report missing 7-Zip artifact/download/install approval, NVIDIA Profile Inspector artifact/download/execution approval, .nip import/export approval, NVIDIA profile state capture/restore approval, NVIDIA registry/file rollback capture approval, process handling approval, and verification approval.')
        $plannedChanges.Add('Perform no 7-Zip download/install, Profile Inspector execution, .nip import/export, NVIDIA Control Panel launch, external process start, registry/profile mutation, or system-changing operation.')
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Verify the HDCP source mirror checksum.')
        $plannedChanges.Add('Report Path B step 3 of 5 while keeping Driver Install Latest, Nvidia Settings, Hdcp, P0 State, and Msi Mode separate.')
        $plannedChanges.Add('Discover the source display-class registry target shape read-only and report eligible NVIDIA targets separately from excluded Microsoft/RDP/non-NVIDIA targets.')
        $plannedChanges.Add('Report the exact source value RMHdcpKeyglobZero as REG_DWORD 1 for Apply and REG_DWORD 0 for Default.')
        $plannedChanges.Add('Report Restore as unavailable unless selected captured rollback state exists.')
        $plannedChanges.Add('Perform no registry capture, registry write, external process, download, reboot, driver change, or profile mutation.')
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Verify the approved HDCP source mirror checksum before any target discovery or mutation.')
        $plannedChanges.Add('Discover only immediate source display-class registry subkeys under HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}, excluding Configuration.')
        $plannedChanges.Add('Classify eligible NVIDIA targets separately from excluded Microsoft/RDP/non-NVIDIA targets; skipped targets are reported and never written.')
        $plannedChanges.Add('Block before capture or write if no eligible NVIDIA target exists or if target discovery includes an out-of-scope registry path.')
        $plannedChanges.Add('Capture prior state for RMHdcpKeyglobZero on every approved target before writing.')
        $plannedChanges.Add('Set only RMHdcpKeyglobZero as REG_DWORD 1 on captured NVIDIA targets.')
        $plannedChanges.Add('Verify RMHdcpKeyglobZero is DWORD 1 after Apply and record post-mutation state for rollback evidence.')
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Verify the approved HDCP source mirror checksum before any target discovery or mutation.')
        $plannedChanges.Add('Discover only immediate source display-class registry subkeys under HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}, excluding Configuration.')
        $plannedChanges.Add('Classify eligible NVIDIA targets separately from excluded Microsoft/RDP/non-NVIDIA targets; skipped targets are reported and never written.')
        $plannedChanges.Add('Block before capture or write if no eligible NVIDIA target exists or if target discovery includes an out-of-scope registry path.')
        $plannedChanges.Add('Capture prior state for RMHdcpKeyglobZero on every approved target before writing.')
        $plannedChanges.Add('Set only RMHdcpKeyglobZero as REG_DWORD 0 on captured NVIDIA targets, matching the Ultimate Default branch.')
        $plannedChanges.Add('Verify RMHdcpKeyglobZero is DWORD 0 after Default and record post-mutation state for rollback evidence.')
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Restore') {
        $plannedChanges.Add('Do not treat Default as Restore.')
        $plannedChanges.Add('Require a valid selected captured rollback record from this HDCP tool before any Restore operation can be planned.')
        $plannedChanges.Add('Fail closed when no selected captured state is available.')
        $plannedChanges.Add('Perform no registry mutation in the current runtime path.')
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Verify the P0 State source mirror checksum.')
        $plannedChanges.Add('Report Path B step 4 of 5 while keeping Driver Install Latest, Nvidia Settings, HDCP, P0 State, and Msi Mode separate.')
        $plannedChanges.Add('Discover the source display-class registry target shape read-only and report eligible NVIDIA targets separately from excluded Microsoft/RDP/non-NVIDIA and ambiguous targets.')
        $plannedChanges.Add('Report the exact source value DisableDynamicPstate as REG_DWORD 1 for Apply and REG_DWORD 0 for Default.')
        $plannedChanges.Add('Report Restore as unavailable unless selected captured rollback state exists.')
        $plannedChanges.Add('Perform no registry capture, registry write, external process, download, reboot, driver change, or profile mutation.')
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Verify the approved P0 State source mirror checksum before any target discovery or mutation.')
        $plannedChanges.Add('Discover only immediate source display-class registry subkeys under HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}, excluding Configuration.')
        $plannedChanges.Add('Classify eligible NVIDIA targets separately from excluded Microsoft/RDP/non-NVIDIA targets and ambiguous targets; skipped targets are reported and never written.')
        $plannedChanges.Add('Block before capture or write if no eligible NVIDIA target exists, if target identity is ambiguous, or if target discovery includes an out-of-scope registry path.')
        $plannedChanges.Add('Capture prior state for DisableDynamicPstate on every eligible target before writing.')
        $plannedChanges.Add('Set only DisableDynamicPstate as REG_DWORD 1 on captured NVIDIA targets.')
        $plannedChanges.Add('Verify DisableDynamicPstate is DWORD 1 after Apply and record post-mutation state for rollback evidence.')
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Verify the approved P0 State source mirror checksum before any target discovery or mutation.')
        $plannedChanges.Add('Discover only immediate source display-class registry subkeys under HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}, excluding Configuration.')
        $plannedChanges.Add('Classify eligible NVIDIA targets separately from excluded Microsoft/RDP/non-NVIDIA targets and ambiguous targets; skipped targets are reported and never written.')
        $plannedChanges.Add('Block before capture or write if no eligible NVIDIA target exists, if target identity is ambiguous, or if target discovery includes an out-of-scope registry path.')
        $plannedChanges.Add('Capture prior state for DisableDynamicPstate on every eligible target before writing.')
        $plannedChanges.Add('Set only DisableDynamicPstate as REG_DWORD 0 on captured NVIDIA targets, matching the Ultimate Default branch.')
        $plannedChanges.Add('Verify DisableDynamicPstate is DWORD 0 after Default and record post-mutation state for rollback evidence.')
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Restore') {
        $plannedChanges.Add('Do not treat Default as Restore.')
        $plannedChanges.Add('Require a valid selected captured rollback record from this P0 State tool before any Restore operation can be planned.')
        $plannedChanges.Add('Fail closed when no selected captured state is available.')
        $plannedChanges.Add('Perform no registry mutation in the current runtime path.')
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Verify the Msi Mode source mirror checksum.')
        $plannedChanges.Add('Report Path B step 5 of 5 while keeping Driver Install Latest, Nvidia Settings, HDCP, P0 State, and Msi Mode separate.')
        $plannedChanges.Add('Discover the source PnP display-device Enum registry target shape read-only and report eligible NVIDIA targets separately from excluded Microsoft/RDP/non-NVIDIA and ambiguous targets.')
        $plannedChanges.Add('Report the exact source value MSISupported as REG_DWORD 1 for Apply and REG_DWORD 0 for Default.')
        $plannedChanges.Add('Report Restore as unavailable unless selected captured rollback state exists.')
        $plannedChanges.Add('Perform no registry capture, registry write, external process, download, reboot, driver change, device restart, or profile mutation.')
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Verify the approved Msi Mode source mirror checksum before any target discovery or mutation.')
        $plannedChanges.Add('Discover source display devices using Get-PnpDevice -Class Display and derive the exact HKLM:\SYSTEM\ControlSet001\Enum\<InstanceId>\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties target path.')
        $plannedChanges.Add('Classify eligible NVIDIA targets separately from excluded Microsoft/RDP/non-NVIDIA targets and ambiguous targets; skipped targets are reported and never written.')
        $plannedChanges.Add('Block before capture or write if no eligible NVIDIA target exists, if target identity is ambiguous, or if target discovery includes an out-of-scope registry path.')
        $plannedChanges.Add('Capture prior state for MSISupported on every eligible target before writing.')
        $plannedChanges.Add('Set only MSISupported as REG_DWORD 1 on captured NVIDIA targets.')
        $plannedChanges.Add('Verify MSISupported is DWORD 1 after Apply and record post-mutation state for rollback evidence.')
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Verify the approved Msi Mode source mirror checksum before any target discovery or mutation.')
        $plannedChanges.Add('Discover source display devices using Get-PnpDevice -Class Display and derive the exact HKLM:\SYSTEM\ControlSet001\Enum\<InstanceId>\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties target path.')
        $plannedChanges.Add('Classify eligible NVIDIA targets separately from excluded Microsoft/RDP/non-NVIDIA targets and ambiguous targets; skipped targets are reported and never written.')
        $plannedChanges.Add('Block before capture or write if no eligible NVIDIA target exists, if target identity is ambiguous, or if target discovery includes an out-of-scope registry path.')
        $plannedChanges.Add('Capture prior state for MSISupported on every eligible target before writing.')
        $plannedChanges.Add('Set only MSISupported as REG_DWORD 0 on captured NVIDIA targets, matching the Ultimate Off/Default branch.')
        $plannedChanges.Add('Verify MSISupported is DWORD 0 after Default and record post-mutation state for rollback evidence.')
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Restore') {
        $plannedChanges.Add('Do not treat Default as Restore.')
        $plannedChanges.Add('Require a valid selected captured rollback record from this Msi Mode tool before any Restore operation can be planned.')
        $plannedChanges.Add('Fail closed when no selected captured state is available.')
        $plannedChanges.Add('Perform no registry mutation in the current runtime path.')
    }
    elseif ($toolId -eq 'bitlocker' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Verify the BitLocker source mirror checksum.')
        $plannedChanges.Add('Query BitLocker volume state read-only when Get-BitLockerVolume is available.')
        $plannedChanges.Add('Report matched volumes for the source Off branch without disabling, decrypting, suspending, resuming, enabling, or removing protectors.')
        $plannedChanges.Add('Preview that Apply maps to the source Off branch and Open maps to the source On/status branch.')
        $plannedChanges.Add('Perform no external process, Control Panel launch, manage-bde call, registry mutation, BitLocker mutation, reboot, or recovery-key operation.')
    }
    elseif ($toolId -eq 'bitlocker' -and $ActionName -eq 'Open') {
        $plannedChanges.Add('Verify the BitLocker source mirror checksum before any status action.')
        $plannedChanges.Add('Open BitLocker Drive Encryption Control Panel with control.exe /name microsoft.bitlockerdriveencryption.')
        $plannedChanges.Add('Run manage-bde -status for source-equivalent status output.')
        $plannedChanges.Add('Do not enable BitLocker automatically; the Ultimate On branch is UI/status-only.')
        $plannedChanges.Add('Do not collect, display, persist, add, remove, suspend, or resume recovery keys or protectors.')
    }
    elseif ($toolId -eq 'bitlocker' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Verify the BitLocker source mirror checksum before any mutation.')
        $plannedChanges.Add('Query Get-BitLockerVolume and filter volumes where ProtectionStatus is On or VolumeStatus is not FullyDecrypted.')
        $plannedChanges.Add('Run Disable-BitLocker -MountPoint <mount> -ErrorAction SilentlyContinue only for the filtered target MountPoints.')
        $plannedChanges.Add('Open BitLocker Drive Encryption Control Panel after the disable requests.')
        $plannedChanges.Add('Run manage-bde -status after the disable requests.')
        $plannedChanges.Add('Do not collect, display, persist, add, remove, suspend, or resume recovery keys or protectors.')
    }
    elseif ($toolId -eq 'bitlocker' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Block Default before any operational step.')
        $plannedChanges.Add('Do not treat the source On branch as BoostLab Default because it only opens BitLocker UI and status output.')
        $plannedChanges.Add('Do not enable BitLocker, add protectors, remove protectors, or change encryption state.')
        $plannedChanges.Add('Perform no system-changing operation.')
    }
    elseif ($toolId -eq 'bitlocker' -and $ActionName -eq 'Restore') {
        $plannedChanges.Add('Block Restore before any operational step.')
        $plannedChanges.Add('Require a valid selected captured BitLocker state and an approved restore contract before any Restore can be planned.')
        $plannedChanges.Add('Do not treat source On, source Off, Apply, or Default as captured-state Restore.')
        $plannedChanges.Add('Perform no system-changing operation.')
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
    $isBlockedBitLockerNoMutationAction = $toolId -eq 'bitlocker' -and $ActionName -in @('Default', 'Restore')
    $isBlockedInstallersNoMutationAction = $toolId -eq 'installers' -and $ActionName -in @('Apply', 'Default', 'Restore')
    $isBlockedEdgeWebViewNoMutationAction = $toolId -eq 'edge-webview' -and $ActionName -in @('Apply', 'Default', 'Restore')
    $isBlockedDriverInstallDebloatSettingsNoMutationAction = $toolId -eq 'driver-install-debloat-settings' -and $ActionName -in @('Apply', 'Default', 'Restore')
    $isBlockedDirectXNoMutationAction = $toolId -eq 'directx' -and $ActionName -in @('Apply', 'Default', 'Restore')
    $isBlockedVisualCppNoMutationAction = $toolId -eq 'visual-cpp' -and $ActionName -in @('Apply', 'Default', 'Restore')
    $isBlockedReinstallNoMutationAction = $toolId -eq 'reinstall' -and $ActionName -in @('Default', 'Restore')
    $isBlockedUpdatesDriversBlockRestoreNoMutationAction = $toolId -eq 'updates-drivers-block' -and $ActionName -eq 'Restore'
    if ($isPotentialChangeAction -and -not $isBlockedBitLockerNoMutationAction -and -not $isBlockedInstallersNoMutationAction -and -not $isBlockedEdgeWebViewNoMutationAction -and -not $isBlockedDriverInstallDebloatSettingsNoMutationAction -and -not $isBlockedDirectXNoMutationAction -and -not $isBlockedVisualCppNoMutationAction -and -not $isBlockedReinstallNoMutationAction -and -not $isBlockedUpdatesDriversBlockRestoreNoMutationAction) {
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
    if ($capabilities.CanReboot -and $ActionName -ne 'Analyze' -and -not ($toolId -eq 'reinstall' -and $ActionName -eq 'Open')) {
        $plannedChanges.Add('Request or perform an approved restart when required by the workflow.')
    }
    if ($capabilities.RequiresAdmin -and $toolId -notin @('installers', 'edge-webview', 'directx', 'visual-cpp')) {
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
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; Driver Install Latest analysis is read-only.')
        $sideEffects.Add('No warnings are duplicated between result-level warnings and structured details.')
        $sideEffects.Add('Path B step 1 is reported without enabling the remaining Path B steps.')
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Open') {
        $sideEffects.Add('Manual handoff instructions are prepared inside BoostLab only.')
        $sideEffects.Add('No browser, external tool, NVIDIA driver download, NVIDIA installer execution, or system-changing operation occurs.')
        $sideEffects.Add('No registry, driver, reboot, or session change occurs.')
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Auto mode is blocked before execution.')
        $sideEffects.Add('No approved Auto behavior, NVIDIA driver download, installer execution, external process, registry mutation, driver mutation, reboot, or session change occurs.')
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; Installers analysis is read-only.')
        $sideEffects.Add('No warnings are duplicated between result-level warnings and structured details.')
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Open') {
        $sideEffects.Add('Manual handoff instructions are prepared inside BoostLab only.')
        $sideEffects.Add('No browser, Explorer, Settings, Store, external tool, app download, installer execution, package change, file mutation, registry/service/task/shortcut mutation, cleanup, reboot, or system mutation occurs.')
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Auto mode is blocked before execution.')
        $sideEffects.Add('No approved Auto behavior, download, installer execution, package change, file mutation, registry/service/task/shortcut mutation, cleanup, reboot, or system mutation occurs.')
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Default is blocked before execution.')
        $sideEffects.Add('No app, package, file, registry, service, task, shortcut, cleanup, reboot, or system state changes occur.')
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Restore') {
        $sideEffects.Add('Restore is blocked without selected captured package, installer, file, registry, service, scheduled-task, shortcut, app configuration, cleanup, and support state plus an approved restore contract.')
        $sideEffects.Add('No system-changing operation occurs.')
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; Edge & WebView analysis is read-only.')
        $sideEffects.Add('No warnings are duplicated between result-level warnings and structured details.')
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Open') {
        $sideEffects.Add('Manual handoff instructions are prepared inside BoostLab only.')
        $sideEffects.Add('No browser, Explorer, Settings, Store, Edge, WebView, external tool, download, repair, installer execution, package action, process handling, file mutation, registry/service/task/shortcut mutation, cleanup, reboot, or system mutation occurs.')
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Auto mode is blocked before execution.')
        $sideEffects.Add('No approved Auto behavior, download, repair, installer execution, package action, process handling, file mutation, registry/service/task/shortcut mutation, cleanup, reboot, or system mutation occurs.')
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Default is blocked before execution.')
        $sideEffects.Add('No Edge/WebView repair, package, policy, service, task, Active Setup, RunOnce, BHO, cleanup, reboot, or system state changes occur.')
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Restore') {
        $sideEffects.Add('Restore is blocked without selected captured Edge/WebView package, installer, file, registry, service, scheduled-task, process, cleanup, and support state plus an approved restore contract.')
        $sideEffects.Add('No system-changing operation occurs.')
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; Driver Install Debloat & Settings analysis is read-only.')
        $sideEffects.Add('No warnings are duplicated between result-level warnings and structured details.')
        $sideEffects.Add('Driver Install Debloat & Settings remains separate from Driver Clean and NVIDIA Path B.')
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Open') {
        $sideEffects.Add('Manual handoff instructions are prepared inside BoostLab only.')
        $sideEffects.Add('No browser, external tool, 7-Zip download/install, driver download, installer execution, driver extraction/debloat, Profile Inspector execution, .nip import, winget/AppX action, registry/service/driver mutation, display/sound launch, reboot, or session change occurs.')
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Auto mode is blocked before execution.')
        $sideEffects.Add('No approved Auto behavior, download, installer execution, external process, file cleanup, profile import, package action, registry/service/driver mutation, reboot, or session change occurs.')
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Default is blocked before execution.')
        $sideEffects.Add('No driver, package, profile, registry, file, service, reboot, or session state changes occur.')
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Restore') {
        $sideEffects.Add('Restore is blocked without selected captured driver/profile/package/registry/file/reboot state and an approved restore contract.')
        $sideEffects.Add('No system-changing operation occurs.')
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; DirectX analysis is read-only.')
        $sideEffects.Add('No warnings are duplicated between result-level warnings and structured details.')
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Open') {
        $sideEffects.Add('Manual handoff instructions are prepared inside BoostLab only.')
        $sideEffects.Add('No browser, external tool, 7-Zip download/install, DirectX download, extraction, setup launch, registry change, shortcut cleanup, file cleanup, or system mutation occurs.')
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Auto mode is blocked before execution.')
        $sideEffects.Add('No approved Auto behavior, download, extraction, installer execution, registry change, shortcut cleanup, file cleanup, or system mutation occurs.')
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Default is blocked before execution.')
        $sideEffects.Add('No artifact, installer, registry, shortcut, file, cleanup, or system state changes occur.')
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Restore') {
        $sideEffects.Add('Restore is blocked without selected captured artifact, registry, shortcut, file, installer, and cleanup state plus an approved restore contract.')
        $sideEffects.Add('No system-changing operation occurs.')
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; Visual C++ analysis is read-only.')
        $sideEffects.Add('No warnings are duplicated between result-level warnings and structured details.')
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Open') {
        $sideEffects.Add('Manual handoff instructions are prepared inside BoostLab only.')
        $sideEffects.Add('No browser, external tool, Visual C++ download, installer launch, package change, registry change, temp-file change, file cleanup, or system mutation occurs.')
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Auto mode is blocked before execution.')
        $sideEffects.Add('No approved Auto behavior, download, installer execution, package change, registry change, temp-file change, file cleanup, or system mutation occurs.')
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Default is blocked before execution.')
        $sideEffects.Add('No artifact, package, installer, registry, temp-file, cleanup, or system state changes occur.')
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Restore') {
        $sideEffects.Add('Restore is blocked without selected captured artifact, package, registry, temp-file, installer, and cleanup state plus an approved restore contract.')
        $sideEffects.Add('No system-changing operation occurs.')
    }
    elseif ($toolId -eq 'reinstall' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; Reinstall analysis is read-only.')
        $sideEffects.Add('No warnings are duplicated between result-level warnings and structured details.')
        $sideEffects.Add('The Windows 10 Media Creation Tool branch is reported as unsupported while the target outcome remains Windows 11.')
    }
    elseif ($toolId -eq 'reinstall' -and $ActionName -eq 'Open') {
        $sideEffects.Add('Reinstall guidance is prepared inside BoostLab only.')
        $sideEffects.Add('No browser, Explorer, Settings, external tool, Windows media download, Media Creation Tool launch, setup command, file mutation, registry/service/package/device/driver mutation, recovery workflow, reboot, or system mutation occurs.')
    }
    elseif ($toolId -eq 'reinstall' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Downloads the source-defined Windows 11 Media Creation Tool to Windows Temp and launches it.')
        $sideEffects.Add('Microsoft tooling may continue into media creation, refresh, reinstall, session changes, or reboot if the user proceeds inside it.')
        $sideEffects.Add('BoostLab does not run setup.exe directly, partition disks, format media, mutate registry/services/packages/devices/drivers, or reboot by itself.')
    }
    elseif ($toolId -eq 'reinstall' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Default is blocked before execution.')
        $sideEffects.Add('No reinstall, setup, generated-file, recovery, reboot, or system state changes occur.')
    }
    elseif ($toolId -eq 'reinstall' -and $ActionName -eq 'Restore') {
        $sideEffects.Add('Restore is blocked without selected captured reinstall, setup, generated-file, reboot/session, recovery, and support state plus an approved restore contract.')
        $sideEffects.Add('No system-changing operation occurs.')
    }
    elseif ($toolId -eq 'nvidia-settings' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; Nvidia Settings analysis is read-only.')
        $sideEffects.Add('No warnings are duplicated between result-level warnings and structured details.')
        $sideEffects.Add('Path B step 2 is reported without enabling the remaining Path B steps.')
    }
    elseif ($toolId -eq 'nvidia-settings' -and $ActionName -eq 'Open') {
        $sideEffects.Add('Manual handoff instructions are prepared inside BoostLab only.')
        $sideEffects.Add('No 7-Zip download/install, NVIDIA Profile Inspector download/execution, .nip import/export, browser, Control Panel launch, external process, or system-changing operation occurs.')
        $sideEffects.Add('No NVIDIA profile, registry, driver, reboot, or session change occurs.')
    }
    elseif ($toolId -eq 'nvidia-settings' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Auto mode is blocked before execution.')
        $sideEffects.Add('No approved Auto behavior, 7-Zip download/install, Profile Inspector execution, .nip import/export, external process, Control Panel launch, registry/profile mutation, or system-changing operation occurs.')
    }
    elseif ($toolId -eq 'updates-drivers-block' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; Updates Drivers Block analysis is read-only.')
        $sideEffects.Add('Yazan final scope is reported as Driver Updates Block Bootable USB only; Unblock and broad Updates branches remain unsupported.')
    }
    elseif ($toolId -eq 'updates-drivers-block' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Creates or updates only the source-equivalent Driver Updates Block setupcomplete.cmd file on selected USB media after source validation and file capture succeed.')
        $sideEffects.Add('No host registry policy value is written or deleted.')
        $sideEffects.Add('No setupcomplete.cmd execution, Windows Update execution, download, installer, external process, service change, driver/device mutation, or BoostLab reboot occurs.')
    }
    elseif ($toolId -eq 'updates-drivers-block' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Default is unavailable because Yazan final scope excludes Unblock.')
        $sideEffects.Add('No host registry values or USB files are changed.')
        $sideEffects.Add('Default remains separate from Restore.')
    }
    elseif ($toolId -eq 'updates-drivers-block' -and $ActionName -eq 'Restore') {
        $sideEffects.Add('Restore is blocked without a selected captured USB setupcomplete.cmd file rollback record from this Updates Drivers Block tool.')
        $sideEffects.Add('No file or registry mutation occurs when no selected captured USB file state is provided.')
        $sideEffects.Add('Restore is not Unblock and Default remains separate from Restore.')
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; HDCP analysis is read-only.')
        $sideEffects.Add('Path B step 3 is reported without merging Driver Install Latest, Nvidia Settings, P0 State, or Msi Mode.')
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Writes only RMHdcpKeyglobZero as REG_DWORD 1 after eligible NVIDIA target discovery and capture succeed; excluded Microsoft/RDP/non-NVIDIA targets are skipped.')
        $sideEffects.Add('No external process, download, Control Panel launch, profile import, driver install, reboot, service change, or non-NVIDIA registry write occurs.')
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Writes only RMHdcpKeyglobZero as REG_DWORD 0 after eligible NVIDIA target discovery and capture succeed; excluded Microsoft/RDP/non-NVIDIA targets are skipped.')
        $sideEffects.Add('Default is source-defined behavior and is not a captured-state Restore.')
        $sideEffects.Add('No external process, download, Control Panel launch, profile import, driver install, reboot, service change, or non-NVIDIA registry write occurs.')
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Restore') {
        $sideEffects.Add('Restore is blocked without a selected captured rollback record from this HDCP tool.')
        $sideEffects.Add('No registry mutation occurs in the current Restore path.')
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; P0 State analysis is read-only.')
        $sideEffects.Add('Path B step 4 is reported without merging Driver Install Latest, Nvidia Settings, HDCP, or Msi Mode.')
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Writes only DisableDynamicPstate as REG_DWORD 1 after eligible NVIDIA target discovery and capture succeed; excluded Microsoft/RDP/non-NVIDIA targets are skipped.')
        $sideEffects.Add('No external process, download, Control Panel launch, profile import, driver install, reboot, service change, or non-NVIDIA registry write occurs.')
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Writes only DisableDynamicPstate as REG_DWORD 0 after eligible NVIDIA target discovery and capture succeed; excluded Microsoft/RDP/non-NVIDIA targets are skipped.')
        $sideEffects.Add('Default is source-defined behavior and is not a captured-state Restore.')
        $sideEffects.Add('No external process, download, Control Panel launch, profile import, driver install, reboot, service change, or non-NVIDIA registry write occurs.')
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Restore') {
        $sideEffects.Add('Restore is blocked without a selected captured rollback record from this P0 State tool.')
        $sideEffects.Add('No registry mutation occurs in the current Restore path.')
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; Msi Mode analysis is read-only.')
        $sideEffects.Add('Path B step 5 is reported without merging Driver Install Latest, Nvidia Settings, HDCP, or P0 State.')
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Writes only MSISupported as REG_DWORD 1 after eligible NVIDIA target discovery and capture succeed; excluded Microsoft/RDP/non-NVIDIA targets are skipped.')
        $sideEffects.Add('No external process, download, Control Panel launch, profile import, driver install, device restart, reboot, service change, or non-NVIDIA registry write occurs.')
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Writes only MSISupported as REG_DWORD 0 after eligible NVIDIA target discovery and capture succeed; excluded Microsoft/RDP/non-NVIDIA targets are skipped.')
        $sideEffects.Add('Default is source-defined behavior and is not a captured-state Restore.')
        $sideEffects.Add('No external process, download, Control Panel launch, profile import, driver install, device restart, reboot, service change, or non-NVIDIA registry write occurs.')
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Restore') {
        $sideEffects.Add('Restore is blocked without a selected captured rollback record from this Msi Mode tool.')
        $sideEffects.Add('No registry mutation occurs in the current Restore path.')
    }
    elseif ($toolId -eq 'bitlocker' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; BitLocker analysis is read-only.')
        $sideEffects.Add('Get-BitLockerVolume may be queried to report sanitized volume, protection, encryption, and key-protector type state.')
        $sideEffects.Add('Recovery-key values are not collected or logged.')
    }
    elseif ($toolId -eq 'bitlocker' -and $ActionName -eq 'Open') {
        $sideEffects.Add('BitLocker Drive Encryption Control Panel is opened.')
        $sideEffects.Add('manage-bde -status is run for status output.')
        $sideEffects.Add('No automatic BitLocker enable, disable, protector, recovery-key, registry, or reboot state change occurs.')
    }
    elseif ($toolId -eq 'bitlocker' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Disable-BitLocker is invoked only for source-matched protected or not fully decrypted MountPoints.')
        $sideEffects.Add('Matched volumes may begin decryption or protection disable behavior after confirmation.')
        $sideEffects.Add('BitLocker Drive Encryption Control Panel is opened and manage-bde -status is run after the disable requests.')
        $sideEffects.Add('Recovery keys are not collected, displayed, or stored; no automatic enable, protector add/remove, registry, or reboot operation occurs.')
    }
    elseif ($toolId -eq 'bitlocker' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Default is blocked before execution because the source On branch is UI/status-only, not a BoostLab default mutation.')
        $sideEffects.Add('No BitLocker state, protector state, recovery-key state, external process, registry, or reboot operation occurs.')
    }
    elseif ($toolId -eq 'bitlocker' -and $ActionName -eq 'Restore') {
        $sideEffects.Add('Restore is blocked without selected captured BitLocker state and an approved restore contract.')
        $sideEffects.Add('No BitLocker state, protector state, recovery-key state, external process, registry, or reboot operation occurs.')
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
    if ($ActionName -eq 'Analyze' -and $toolId -notin @('driver-clean', 'driver-install-latest', 'installers', 'edge-webview', 'driver-install-debloat-settings', 'directx', 'visual-cpp', 'reinstall', 'nvidia-settings')) {
        $sideEffects.Add('Read-only system information may be collected and displayed.')
    }
    elseif ($ActionName -eq 'Open' -and -not $capabilities.CanReboot -and $toolId -notin @('driver-clean', 'driver-install-latest', 'installers', 'edge-webview', 'driver-install-debloat-settings', 'directx', 'visual-cpp', 'reinstall', 'nvidia-settings', 'bitlocker')) {
        $sideEffects.Add('A Windows interface or approved external resource may be opened.')
    }
    if ($capabilities.RequiresInternet -and $toolId -notin @('installers', 'edge-webview', 'directx', 'visual-cpp')) {
        $sideEffects.Add('The requested action may fail when internet access is unavailable.')
    }
    if ($capabilities.CanReboot -and $ActionName -ne 'Analyze' -and -not ($toolId -eq 'reinstall' -and $ActionName -eq 'Open')) {
        $sideEffects.Add('The computer may restart; unsaved work could be lost.')
    }
    if ($isPotentialChangeAction -and -not $isBlockedInstallersNoMutationAction -and -not $isBlockedDriverInstallDebloatSettingsNoMutationAction -and -not $isBlockedDirectXNoMutationAction -and -not $isBlockedVisualCppNoMutationAction -and -not $isBlockedReinstallNoMutationAction -and $capabilities.CanModifyServices) {
        $sideEffects.Add('Service changes may affect dependent Windows or application features.')
    }
    if ($isPotentialChangeAction -and -not $isBlockedInstallersNoMutationAction -and -not $isBlockedDirectXNoMutationAction -and -not $isBlockedVisualCppNoMutationAction -and -not $isBlockedReinstallNoMutationAction -and $capabilities.CanModifyDrivers) {
        $sideEffects.Add('Driver changes may affect display, devices, stability, or hardware availability.')
    }
    if ($isPotentialChangeAction -and -not $isBlockedBitLockerNoMutationAction -and -not $isBlockedInstallersNoMutationAction -and -not $isBlockedDirectXNoMutationAction -and -not $isBlockedVisualCppNoMutationAction -and -not $isBlockedReinstallNoMutationAction -and $capabilities.CanModifySecurity) {
        $sideEffects.Add('Security changes may alter system protection or compatibility.')
    }
    if ($isPotentialChangeAction -and -not $isBlockedInstallersNoMutationAction -and -not $isBlockedDirectXNoMutationAction -and -not $isBlockedVisualCppNoMutationAction -and -not $isBlockedReinstallNoMutationAction -and $capabilities.CanDeleteFiles) {
        $sideEffects.Add('Deleted files may not be recoverable unless an approved checkpoint exists.')
    }
    if ($isPotentialChangeAction -and -not $isBlockedInstallersNoMutationAction -and -not $isBlockedDirectXNoMutationAction -and -not $isBlockedVisualCppNoMutationAction -and -not $isBlockedReinstallNoMutationAction -and $capabilities.CanInstallSoftware) {
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
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Open') {
        'BoostLab will prepare Driver Install Latest manual handoff instructions only. It will not open a browser or external tool, download an NVIDIA driver or 7-Zip, execute an NVIDIA installer, modify registry or drivers, change the session, or reboot. Continue?'
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Apply') {
        'Driver Install Latest Auto mode is blocked. BoostLab will not execute Auto behavior because NVIDIA artifact/download, installer descriptor, driver-state, process handoff, reboot/session, and recovery approvals are missing. Continue only to record the blocked result?'
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Open') {
        'BoostLab will prepare Driver Install Debloat & Settings manual handoff instructions only. It will not open a browser, external tool, 7-Zip installer, driver page, NVIDIA Control Panel, winget, Profile Inspector, or setup.exe; download artifacts; run installers; debloat files; import profiles; mutate registry, services, packages, drivers, sessions; or reboot. Continue?'
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Apply') {
        'Driver Install Debloat & Settings Auto mode is blocked. BoostLab will not execute Auto behavior because artifact, installer, driver-state, process, cleanup, AppX/package, profile, registry, reboot/session, and recovery approvals are missing. Continue only to record the blocked result?'
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Default') {
        'Driver Install Debloat & Settings Default is unavailable. The source does not define a safe overall default mutation, and Default is not Restore. Continue only to record the blocked Default result?'
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Restore') {
        'Driver Install Debloat & Settings Restore requires selected captured driver/profile/package/registry/file/reboot state and an approved restore contract. BoostLab will fail closed because neither exists. Continue only to record the blocked Restore result?'
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Open') {
        'BoostLab will prepare Installers manual handoff instructions only. It will not open a browser, Explorer, Settings, Store, app installer, package manager, script, or external tool; download artifacts; run installers; install, uninstall, repair, update, or configure apps; mutate files, registry, services, tasks, shortcuts, devices, drivers, sessions, or cleanup state; or reboot. Continue?'
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Apply') {
        'Installers Auto mode is blocked. BoostLab will not execute Auto behavior because per-app artifact provenance, installer descriptors, switch validation, exit-code handling, generated-file ownership, cleanup, side-effect scopes, rollback, and support approvals are missing. Continue only to record the blocked result?'
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Default') {
        'Installers Default is unavailable. The source does not define a safe global Default branch, and Default is not Restore. Continue only to record the blocked Default result?'
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Restore') {
        'Installers Restore requires selected captured package, installer, file, registry, service, scheduled-task, shortcut, app configuration, cleanup, and support state plus an approved restore contract. BoostLab will fail closed because neither exists. Continue only to record the blocked Restore result?'
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Open') {
        'BoostLab will prepare Edge & WebView manual handoff instructions only. It will not open a browser, Explorer, Settings, Store, Edge, WebView, repair installer, package manager, script, or external tool; download artifacts; run repair or installers; stop processes; install, uninstall, reset, remove, or configure packages; mutate files, registry, services, tasks, shortcuts, devices, drivers, sessions, or cleanup state; or reboot. Continue?'
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Apply') {
        'Edge & WebView Auto mode is blocked. BoostLab will not execute Auto behavior because artifact provenance, repair/installer descriptors, package scopes, process handling, service/task/file/registry cleanup scopes, rollback, and support approvals are missing. Continue only to record the blocked result?'
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Default') {
        'Edge & WebView Default is unavailable. The source Default branch downloads and runs repair installers and mutates Edge policy, services, tasks, Active Setup, RunOnce, and BHO state; Default is not Restore. Continue only to record the blocked Default result?'
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Restore') {
        'Edge & WebView Restore requires selected captured package, installer, file, registry, service, scheduled-task, process, cleanup, and support state plus an approved restore contract. BoostLab will fail closed because neither exists. Continue only to record the blocked Restore result?'
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Open') {
        'BoostLab will prepare DirectX manual handoff instructions only. It will not open a browser, external tool, 7-Zip installer, DirectX package, extraction tool, or setup executable; download artifacts; run installers; extract files; mutate registry, shortcuts, files, or system state. Continue?'
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Apply') {
        'DirectX Auto mode is blocked. BoostLab will not execute Auto behavior because 7-Zip artifact, DirectX artifact, extraction, installer, side-effect scope, cleanup, and rollback approvals are missing. Continue only to record the blocked result?'
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Default') {
        'DirectX Default is unavailable. The source does not define a safe Default branch, and Default is not Restore. Continue only to record the blocked Default result?'
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Restore') {
        'DirectX Restore requires selected captured artifact, registry, shortcut, file, installer, and cleanup state plus an approved restore contract. BoostLab will fail closed because neither exists. Continue only to record the blocked Restore result?'
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Open') {
        'BoostLab will prepare Visual C++ manual handoff instructions only. It will not open a browser, external tool, Visual C++ redistributable package, or installer executable; download artifacts; run installers; mutate package, registry, temp-file, cleanup, or system state. Continue?'
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Apply') {
        'Visual C++ Auto mode is blocked. BoostLab will not execute Auto behavior because twelve-package artifact, installer, exit-code, temp-file, cleanup, and rollback/support approvals are missing. Continue only to record the blocked result?'
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Default') {
        'Visual C++ Default is unavailable. The source does not define a safe Default branch, and Default is not Restore. Continue only to record the blocked Default result?'
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Restore') {
        'Visual C++ Restore requires selected captured artifact, package, registry, temp-file, installer, and cleanup state plus an approved restore contract. BoostLab will fail closed because neither exists. Continue only to record the blocked Restore result?'
    }
    elseif ($toolId -eq 'reinstall' -and $ActionName -eq 'Open') {
        'BoostLab will prepare Reinstall guidance only. It will not open a browser, Explorer, Settings, Media Creation Tool, setup executable, installer, recovery tool, or external tool; download Windows media; mutate files, registry, services, packages, devices, or drivers; start recovery; or reboot. Continue?'
    }
    elseif ($toolId -eq 'reinstall' -and $ActionName -eq 'Apply') {
        'BoostLab will download the source-defined Windows 11 Media Creation Tool to %SystemRoot%\Temp\mediacreationtoolw11.exe and launch it. The Microsoft tool can continue into media creation, refresh, reinstall, session changes, or reboot after you proceed inside it. Windows 10 branch remains unsupported. Continue?'
    }
    elseif ($toolId -eq 'reinstall' -and $ActionName -eq 'Default') {
        'Reinstall Default is unavailable. The source does not define a safe Default branch, and Default is not Restore. Continue only to record the blocked Default result?'
    }
    elseif ($toolId -eq 'reinstall' -and $ActionName -eq 'Restore') {
        'Reinstall Restore requires selected captured reinstall, setup, generated-file, reboot/session, recovery, and support state plus an approved restore contract. BoostLab will fail closed because neither exists. Continue only to record the blocked Restore result?'
    }
    elseif ($toolId -eq 'nvidia-settings' -and $ActionName -eq 'Open') {
        'BoostLab will prepare Nvidia Settings manual handoff instructions only. It will not download or install 7-Zip, download or execute NVIDIA Profile Inspector, import or export .nip files, launch NVIDIA Control Panel, open a browser or external process, modify registry or NVIDIA profiles, or change system state. Continue?'
    }
    elseif ($toolId -eq 'nvidia-settings' -and $ActionName -eq 'Apply') {
        'Nvidia Settings Auto mode is blocked. BoostLab will not execute Auto behavior because 7-Zip, NVIDIA Profile Inspector, .nip, profile capture/restore, registry/file rollback, process, and verification approvals are missing. Continue only to record the blocked result?'
    }
    elseif ($toolId -eq 'updates-drivers-block' -and $ActionName -eq 'Apply') {
        'BoostLab will write only the source-equivalent Driver Updates Block setupcomplete.cmd to selected removable USB media after file state capture. It will not execute the script, write host registry values, run Windows Update, modify driver devices, download, launch external tools, change services, or reboot. Continue?'
    }
    elseif ($toolId -eq 'updates-drivers-block' -and $ActionName -eq 'Default') {
        'Updates Drivers Block Default is unavailable because Yazan final scope excludes Unblock. BoostLab will not delete live registry values or change USB files. Continue only to record the blocked Default result?'
    }
    elseif ($toolId -eq 'updates-drivers-block' -and $ActionName -eq 'Restore') {
        'Updates Drivers Block Restore requires a selected captured USB setupcomplete.cmd file rollback record from this tool. BoostLab will fail closed if no valid captured state is selected. Continue only to record the blocked Restore result?'
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Apply') {
        'BoostLab will set only the source-defined HDCP registry value RMHdcpKeyglobZero to DWORD 1 on eligible NVIDIA display-class targets, after source checksum validation and pre-change registry capture. Microsoft/RDP/non-NVIDIA targets are skipped. No external process, download, profile import, driver change, or reboot will occur. Continue?'
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Default') {
        'BoostLab will set only the source-defined HDCP Default registry value RMHdcpKeyglobZero to DWORD 0 on eligible NVIDIA display-class targets, after source checksum validation and pre-change registry capture. Microsoft/RDP/non-NVIDIA targets are skipped. Default is not Restore. Continue?'
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Restore') {
        'HDCP Restore requires a selected captured rollback record from this HDCP tool. BoostLab will fail closed if no valid captured state is selected. Continue only to record the blocked Restore result?'
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Apply') {
        'BoostLab will set only the source-defined P0 State registry value DisableDynamicPstate to DWORD 1 on eligible NVIDIA display-class targets, after source checksum validation and pre-change registry capture. Microsoft/RDP/non-NVIDIA targets are skipped. No external process, download, profile import, driver change, or reboot will occur. Continue?'
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Default') {
        'BoostLab will set only the source-defined P0 State Default registry value DisableDynamicPstate to DWORD 0 on eligible NVIDIA display-class targets, after source checksum validation and pre-change registry capture. Microsoft/RDP/non-NVIDIA targets are skipped. Default is not Restore. Continue?'
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Restore') {
        'P0 State Restore requires a selected captured rollback record from this P0 State tool. BoostLab will fail closed if no valid captured state is selected. Continue only to record the blocked Restore result?'
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Apply') {
        'BoostLab will set only the source-defined Msi Mode registry value MSISupported to DWORD 1 on eligible NVIDIA display-device Enum targets, after source checksum validation and pre-change registry capture. Microsoft/RDP/non-NVIDIA targets are skipped. No external process, download, profile import, driver change, device restart, or reboot will occur. Continue?'
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Default') {
        'BoostLab will set only the source-defined Msi Mode Default registry value MSISupported to DWORD 0 on eligible NVIDIA display-device Enum targets, after source checksum validation and pre-change registry capture. Microsoft/RDP/non-NVIDIA targets are skipped. Default is not Restore. Continue?'
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Restore') {
        'Msi Mode Restore requires a selected captured rollback record from this Msi Mode tool. BoostLab will fail closed if no valid captured state is selected. Continue only to record the blocked Restore result?'
    }
    elseif ($toolId -eq 'bitlocker' -and $ActionName -eq 'Open') {
        'BoostLab will run the source-equivalent BitLocker On/status branch: open BitLocker Drive Encryption Control Panel and run manage-bde -status. It will not enable BitLocker automatically, collect recovery keys, change protectors, or reboot. Continue?'
    }
    elseif ($toolId -eq 'bitlocker' -and $ActionName -eq 'Apply') {
        'BoostLab will run the source-equivalent BitLocker Off branch. It will query BitLocker volumes, call Disable-BitLocker only for volumes where ProtectionStatus is On or VolumeStatus is not FullyDecrypted, then open BitLocker Control Panel and run manage-bde -status. This may decrypt or disable protection on matched volumes. Recovery keys are not collected or stored. Continue?'
    }
    elseif ($toolId -eq 'bitlocker' -and $ActionName -eq 'Default') {
        'BitLocker Default is unavailable. The source On branch opens UI/status only and does not define a safe default mutation. Default is not Restore. Continue only to record the blocked result?'
    }
    elseif ($toolId -eq 'bitlocker' -and $ActionName -eq 'Restore') {
        'BitLocker Restore requires a selected captured BitLocker state and an approved restore contract. BoostLab will fail closed because neither exists. Continue only to record the blocked Restore result?'
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
