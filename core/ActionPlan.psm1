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
        [ValidateSet('Apply', 'Default', 'Open', 'Analyze', 'Restore', 'Off')]
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
        [ValidateSet('Apply', 'Default', 'Open', 'Analyze', 'Restore', 'Off')]
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
    $isNvidiaSettingsReadOnlyAnalyze = ($toolId -eq 'nvidia-settings' -and $ActionName -eq 'Analyze')
    $isDirectXReadOnlyAnalyze = ($toolId -eq 'directx' -and $ActionName -eq 'Analyze')
    $isVisualCppReadOnlyAnalyze = ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Analyze')
    $isReadOnlyAnalyzePrivilegeOverride = ($isNvidiaSettingsReadOnlyAnalyze -or $isDirectXReadOnlyAnalyze -or $isVisualCppReadOnlyAnalyze)
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
        'Read the Driver Clean source mirror and report the source-equivalent Auto and Manual DDU workflows without executing them.'
    }
    elseif ($toolId -eq 'driver-clean' -and $ActionName -eq 'Open') {
        'Run the source-equivalent Driver Clean Manual branch after confirmation: prepare 7-Zip/DDU, create the manual DDU RunOnce flow, enable Safe Mode, and restart.'
    }
    elseif ($toolId -eq 'driver-clean' -and $ActionName -eq 'Apply') {
        'Run the source-equivalent Driver Clean Auto branch after confirmation: prepare 7-Zip/DDU, create the automatic DDU RunOnce flow, enable Safe Mode, and restart.'
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Analyze') {
        'Read the Driver Install Latest source mirror and report the source-equivalent NVIDIA, AMD, and INTEL latest-driver branch plans without executing them.'
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Open') {
        'Open the INTEL source-defined Driver Install Latest page only after selecting the INTEL branch; NVIDIA and AMD Open are unavailable and run no operation.'
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Apply') {
        'Run the selected source-equivalent Driver Install Latest NVIDIA, AMD, or INTEL branch after explicit confirmation.'
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Default') {
        'Default is unavailable because the Driver Install Latest source defines no Default branch.'
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Restore') {
        'Restore is unavailable because no selected captured driver/download/installer/session state restore contract exists.'
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Analyze') {
        'Analyze the Installers source, Yazan-excluded menu entries, retained app catalog, and checkbox multi-select queue model without running any installer workflow.'
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Open') {
        'Show retained Installers catalog and selection guidance inside BoostLab only; no browser, external tool, download, installer, package action, file mutation, registry change, service change, task change, cleanup, reboot, or system mutation is opened or executed.'
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Apply') {
        'Run the selected retained Installers app queue one app at a time in source order after explicit confirmation.'
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Default') {
        'Default is unavailable because the source does not define a safe global Installers default branch.'
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Restore') {
        'Restore is unavailable because no captured package, installer, file, registry, service, task, shortcut, app configuration, cleanup, or support state restore contract exists.'
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Apply') {
        'Run the source-equivalent Edge & WebView Uninstall (Recommended) branch after explicit confirmation.'
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Default') {
        'Run the source-defined Edge & WebView Default repair branch after explicit confirmation.'
    }
    elseif ($toolId -eq 'edge-settings' -and $ActionName -eq 'Analyze') {
        'Analyze the Edge Settings source identity and source-equivalent Apply/Default operation families without changing Edge.'
    }
    elseif ($toolId -eq 'edge-settings' -and $ActionName -eq 'Apply') {
        'Run the source-equivalent Edge Settings Optimize branch: write Edge/uBlock policies and remove source-matched Active Setup, RunOnce, Edge services, Edge scheduled tasks, and IE-to-Edge BHO entries.'
    }
    elseif ($toolId -eq 'edge-settings' -and $ActionName -eq 'Default') {
        'Run the source-equivalent Edge Settings Default branch: delete the Edge policy key, stop/start/stop Edge, download the source-defined edge.exe, and start it.'
    }
    elseif ($toolId -eq 'edge-settings' -and $ActionName -eq 'Restore') {
        'Restore is unavailable because no approved captured Edge Settings restore contract exists for policy, Active Setup, RunOnce, service, scheduled-task, BHO, process, download, or installer state.'
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Analyze') {
        'Analyze the Driver Install Debloat & Settings source and build source-equivalent NVIDIA, AMD, and INTEL branch operation plans without running any operation.'
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Open') {
        'Open only the source-defined vendor driver page flow for the selected NVIDIA, AMD, or INTEL branch after confirmation; no install/debloat workflow runs.'
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Apply') {
        'Run one selected source-equivalent NVIDIA, AMD, or INTEL Driver Install Debloat & Settings branch after confirmation.'
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Default') {
        'Default is unavailable because the source does not define a safe overall default mutation for the driver install/debloat workflow.'
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Restore') {
        'Restore is unavailable because no captured driver/profile/package/registry/file/reboot state restore contract exists.'
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Analyze') {
        'Analyze the DirectX source, artifact source classifications, and source-equivalent install plan without running any DirectX or 7-Zip workflow.'
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Open') {
        'Open is not exposed for DirectX; the source defines an install workflow, not a standalone browser or manual handoff action.'
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Apply') {
        'Install DirectX using the source-equivalent controlled workflow: install/configure 7-Zip, download/extract the DirectX package, and launch DXSETUP after confirmation.'
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Default') {
        'Default is unavailable because the source does not define a safe DirectX default branch.'
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Restore') {
        'Restore is unavailable because no captured artifact, registry, shortcut, file, installer, or cleanup state restore contract exists.'
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Analyze') {
        'Analyze the Visual C++ source, artifact source classifications, and source-equivalent twelve-installer plan without running any Visual C++ workflow.'
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Open') {
        'Open is not exposed for Visual C++; the source defines an install workflow, not a standalone browser or manual handoff action.'
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Apply') {
        'Install Visual C++ using the source-equivalent controlled workflow: download all twelve redistributable installers and run them sequentially with source-defined switches after confirmation.'
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Default') {
        'Default is unavailable because the source does not define a safe Visual C++ default branch.'
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Restore') {
        'Restore is unavailable because no captured artifact, package, registry, temp-file, installer, or cleanup state restore contract exists.'
    }
    elseif ($toolId -eq 'bloatware' -and $ActionName -eq 'Analyze') {
        'Analyze the Bloatware Ultimate source identity and all approved non-Exit branch operation plans without executing package, registry, service, task, process, file, download, installer, or feature operations.'
    }
    elseif ($toolId -eq 'bloatware' -and $ActionName -eq 'Apply') {
        'Run exactly one selected source-equivalent Bloatware branch after explicit confirmation.'
    }
    elseif ($toolId -eq 'game-bar' -and $ActionName -eq 'Apply') {
        'Run the source-equivalent Gamebar Xbox Off (Recommended) branch after explicit confirmation.'
    }
    elseif ($toolId -eq 'game-bar' -and $ActionName -eq 'Default') {
        'Run the source-defined Gamebar Xbox Default repair branch after explicit confirmation. Default is not captured-state Restore.'
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
        'Read the Nvidia Settings source mirror and report the source-equivalent On (Recommended) and Default operation plans without changing settings.'
    }
    elseif ($toolId -eq 'nvidia-settings' -and $ActionName -eq 'Apply') {
        'Run the source-defined Nvidia Settings On (Recommended) branch after explicit confirmation: common 7-Zip prelude, NVIDIA registry/profile operations, Profile Inspector .nip import, and NVIDIA Control Panel launch.'
    }
    elseif ($toolId -eq 'nvidia-settings' -and $ActionName -eq 'Default') {
        'Run the source-defined Nvidia Settings Default branch after explicit confirmation: common 7-Zip prelude, NVIDIA registry/profile default operations, Profile Inspector default .nip import, and NVIDIA Control Panel launch. Default is not Restore.'
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Analyze') {
        'Read the HDCP source mirror and report source-defined display-class registry scope, non-Configuration target discovery, and readback state without changing the system.'
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Apply') {
        'Run the source-defined HDCP Off (Recommended) branch after confirmation: set RMHdcpKeyglobZero DWORD 1 on every non-Configuration display-class subkey and read the values back.'
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Default') {
        'Run the source-defined HDCP Default branch after confirmation: set RMHdcpKeyglobZero DWORD 0 on every non-Configuration display-class subkey and read the values back. Default is not Restore.'
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Analyze') {
        'Read the P0 State source mirror and report source-defined display-class registry scope, non-Configuration target discovery, Apply availability, and Default availability without changing the system.'
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Apply') {
        'Run the source-defined P0 State On (Recommended) branch after confirmation: set DisableDynamicPstate DWORD 1 on every non-Configuration display-class subkey and read the values back.'
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Default') {
        'Run the source-defined P0 State Default branch after confirmation: set DisableDynamicPstate DWORD 0 on every non-Configuration display-class subkey and read the values back. Default is not Restore.'
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Analyze') {
        'Read the Msi Mode source mirror and report the source-defined Get-PnpDevice -Class Display target scope, On availability, Off availability, and current MSISupported readbacks without changing the system.'
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Apply') {
        'Run the source-defined Msi Mode On (Recommended) branch after confirmation: set MSISupported DWORD 1 for every display device returned by Get-PnpDevice -Class Display after source checksum validation and pre-change registry state capture.'
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Off') {
        'Run the source-defined Msi Mode Off branch after confirmation: set MSISupported DWORD 0 for every display device returned by Get-PnpDevice -Class Display after source checksum validation and pre-change registry state capture. Off is not Default or Restore.'
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
    elseif ($toolId -eq 'copilot' -and $ActionName -eq 'Apply') {
        'Run the approved source-equivalent Copilot Off branch: stop the source process list, stop *edge* process matches, remove AppX packages matching *Copilot*, and set HKCU/HKLM TurnOffWindowsCopilot to REG_DWORD 1.'
    }
    elseif ($toolId -eq 'copilot' -and $ActionName -eq 'Default') {
        'Run the approved source-equivalent Copilot Default branch: re-register AppX packages matching *Copilot* and delete the HKCU/HKLM WindowsCopilot policy keys. Default is not Restore.'
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
        'Generate and apply the exact source-defined black sign-out, lock screen, and desktop wallpaper.'
    }
    elseif ($toolId -eq 'signout-lockscreen-wallpaper-black' -and $ActionName -eq 'Default') {
        'Run the exact source-defined Default wallpaper action.'
    }
    elseif ($toolId -eq 'notepad-settings' -and $ActionName -eq 'Apply') {
        'Stop Notepad, write the source registry file, load settings.dat, import the Ultimate values when load succeeds, and unload the hive.'
    }
    elseif ($toolId -eq 'notepad-settings' -and $ActionName -eq 'Default') {
        'Stop Notepad and run the source-defined settings.dat delete action.'
    }
    elseif ($toolId -eq 'control-panel-settings' -and $ActionName -eq 'Apply') {
        'Run the exact source-defined Control Panel Settings Optimize branch after checksum verification.'
    }
    elseif ($toolId -eq 'control-panel-settings' -and $ActionName -eq 'Default') {
        'Run the exact source-defined Control Panel Settings Default branch after checksum verification.'
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
    elseif ($toolId -eq 'write-cache-buffer-flushing' -and $ActionName -eq 'Default') {
        'Delete each source-discovered SCSI and NVME Disk registry key exactly as the Ultimate Default branch does.'
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
    elseif ($toolId -eq 'cleanup' -and $ActionName -eq 'Apply') {
        'Run the exact Ultimate cleanup branch: remove the source-defined temp, Windows.old, inetpub, PerfLogs, and DumpStack targets, then open Disk Cleanup.'
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
        'Apply the approved Ultimate MMAgent Default profile exactly as defined by the source, including the features that remain disabled.'
    }
    elseif ($toolId -eq 'services-optimizer' -and $ActionName -eq 'Analyze') {
        'Analyze the approved Ultimate Services Off and Services Default Safe Mode workflows without staging them.'
    }
    elseif ($toolId -eq 'services-optimizer' -and $ActionName -eq 'Apply') {
        'Stage the approved Ultimate Services: Off workflow, including generated Safe Mode script, RunOnce, BCD safeboot, TrustedInstaller REG import, and restart request.'
    }
    elseif ($toolId -eq 'services-optimizer' -and $ActionName -eq 'Default') {
        'Stage the approved Ultimate Services: Default workflow, including generated Safe Mode script, RunOnce, BCD safeboot, TrustedInstaller REG import, and restart request.'
    }
    elseif ($toolId -eq 'timer-resolution-assistant' -and $ActionName -eq 'Analyze') {
        'Analyze the approved Ultimate Timer Resolution On and Default workflows without changing service, file, registry, or process state.'
    }
    elseif ($toolId -eq 'timer-resolution-assistant' -and $ActionName -eq 'Apply') {
        'Run the approved Ultimate Timer Resolution: On workflow: generate and compile the source-defined service, install and start it, set the timer registry value, and open Task Manager.'
    }
    elseif ($toolId -eq 'timer-resolution-assistant' -and $ActionName -eq 'Default') {
        'Run the approved Ultimate Timer Resolution: Default workflow: disable, stop, and delete the service, remove the generated executable, delete the timer registry value, and open Task Manager.'
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
        $plannedChanges.Add('Read the Driver Clean source mirror checksum and source-defined Auto/Manual workflow descriptors.')
        $plannedChanges.Add('Report the source-defined 7-Zip download/install/config, DDU download/extraction/config, driver-search policy value, temp scripts, RunOnce, bcdedit Safe Mode, restart, and DDU launch commands.')
        $plannedChanges.Add('Perform no download, external process start, registry mutation, Safe Mode change, RunOnce creation, bcdedit call, reboot, or driver cleanup.')
    }
    elseif ($toolId -eq 'driver-clean' -and $ActionName -eq 'Open') {
        $plannedChanges.Add('Verify the Driver Clean source checksum and require explicit confirmation.')
        $plannedChanges.Add('Download the source-defined 7-Zip and DDU artifacts to Windows Temp, then install/configure 7-Zip.')
        $plannedChanges.Add('Extract DDU, write the source-defined Settings.xml, and mark it read-only.')
        $plannedChanges.Add('Capture and set HKLM:\Software\Microsoft\Windows\CurrentVersion\DriverSearching SearchOrderConfig = REG_DWORD 0.')
        $plannedChanges.Add('Create the source-defined ddumanual.ps1 script and RunOnce entry, enable bcdedit Safe Mode minimal, wait five seconds, and restart.')
        $plannedChanges.Add('After restart, the RunOnce script deletes Safe Mode and launches DDU manually.')
    }
    elseif ($toolId -eq 'driver-clean' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Verify the Driver Clean source checksum and require explicit confirmation.')
        $plannedChanges.Add('Download the source-defined 7-Zip and DDU artifacts to Windows Temp, then install/configure 7-Zip.')
        $plannedChanges.Add('Extract DDU, write the source-defined Settings.xml, and mark it read-only.')
        $plannedChanges.Add('Capture and set HKLM:\Software\Microsoft\Windows\CurrentVersion\DriverSearching SearchOrderConfig = REG_DWORD 0.')
        $plannedChanges.Add('Create the source-defined ddu.ps1 script and RunOnce entry, enable bcdedit Safe Mode minimal, wait five seconds, and restart.')
        $plannedChanges.Add('After restart, the RunOnce script deletes Safe Mode and launches DDU with -CleanSoundBlaster -CleanRealtek -CleanAllGpus -Restart.')
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Read the Driver Install Latest source mirror checksum and implementation status.')
        $plannedChanges.Add('Report the source Administrator and internet checks.')
        $plannedChanges.Add('Report the NVIDIA branch: guidance, NVIDIA lookup API, dynamic latest driver URL construction, download to %SystemRoot%\Temp\nvidiadriver.exe, and installer launch.')
        $plannedChanges.Add('Report the AMD branch: AMD support page scrape, minimal setup web-installer link discovery, spoofed browser headers, download to %SystemRoot%\Temp\amddriver.exe, and installer launch.')
        $plannedChanges.Add('Report the INTEL branch: Intel Windows 11 graphics driver search page launch.')
        $plannedChanges.Add('Report Path B step 1 of 5 while keeping Driver Install Latest separate from Nvidia Settings, Hdcp, P0 State, and Msi Mode.')
        $plannedChanges.Add('Perform no vendor query, download, installer launch, browser/page launch, external process, file mutation, driver mutation, reboot, or session change.')
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Open') {
        $plannedChanges.Add('Require selecting exactly one source branch.')
        $plannedChanges.Add('For INTEL, open only the source-defined Intel Windows 11 graphics driver search page.')
        $plannedChanges.Add('For NVIDIA and AMD, report Open unavailable because those source branches perform their workflow through Apply, not a standalone browser/page action.')
        $plannedChanges.Add('Do not download a driver installer from Open.')
        $plannedChanges.Add('Do not execute a driver installer from Open.')
        $plannedChanges.Add('Do not modify registry, drivers, services, files, sessions, or reboot state from Open.')
        $plannedChanges.Add('Keep Path B steps separate: Driver Install Latest, Nvidia Settings, Hdcp, P0 State, and Msi Mode.')
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Require explicit confirmation and exactly one selected source branch: NVIDIA, AMD, or INTEL.')
        $plannedChanges.Add('Run the source Administrator and internet checks.')
        $plannedChanges.Add('For NVIDIA, query the source NVIDIA latest-driver API, build the dynamic source NVIDIA installer URL, download to %SystemRoot%\Temp\nvidiadriver.exe, and launch that installer.')
        $plannedChanges.Add('For AMD, scrape the source AMD support page for the minimal setup web installer, download it with the source browser-spoof headers to %SystemRoot%\Temp\amddriver.exe, and launch that installer.')
        $plannedChanges.Add('For INTEL, open the source-defined Intel Windows 11 graphics driver search page.')
        $plannedChanges.Add('Log every operation, source command mapping, target URL, and target path returned by the selected branch workflow.')
        $plannedChanges.Add('Do not run Nvidia Settings, HDCP, P0 State, Msi Mode, Driver Clean, or Driver Install Debloat & Settings from this tool.')
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Block Default because the source has no Default branch.')
        $plannedChanges.Add('Do not treat Default as Restore.')
        $plannedChanges.Add('No driver, file, registry, installer, process, reboot, or session mutation is planned.')
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Restore') {
        $plannedChanges.Add('Block Restore because no selected captured driver/download/installer/session state exists for this tool.')
        $plannedChanges.Add('Do not invent rollback for vendor driver installers.')
        $plannedChanges.Add('No driver, file, registry, installer, process, reboot, or session mutation is planned.')
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Read the Installers source checksum and implementation status.')
        $plannedChanges.Add('Report full source menu mapping, Yazan-excluded entries, retained visible catalog, retained app count, and retained artifact count.')
        $plannedChanges.Add('Report checkbox multi-select and sequential queue behavior.')
        $plannedChanges.Add('Perform no download, browser/Explorer/Settings/Store/external process launch, installer execution, package action, file mutation, registry/service/task/shortcut mutation, cleanup, reboot, or system mutation.')
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Open') {
        $plannedChanges.Add('Show retained catalog and checkbox selection guidance inside BoostLab only.')
        $plannedChanges.Add('Do not open a browser, Explorer, Settings, Store, app installer, package manager, script, or external tool.')
        $plannedChanges.Add('Do not download app installers, archives, scripts, packages, or artifacts.')
        $plannedChanges.Add('Do not run installers, setup executables, package managers, Store actions, AppX actions, MSI packages, scripts, or helpers.')
        $plannedChanges.Add('Do not install, uninstall, repair, update, remove, or configure packages or apps.')
        $plannedChanges.Add('Do not create, delete, or mutate files, temp folders, shortcuts, registry, services, scheduled tasks, firewall, devices, drivers, reboot/session state, or app configuration.')
        $plannedChanges.Add('Perform no system-changing operation.')
    }
    elseif ($toolId -eq 'installers' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Require checkbox selection of one or more retained Yazan-approved source apps.')
        $plannedChanges.Add('Confirm the full selected queue once before starting.')
        $plannedChanges.Add('Process selected apps sequentially in retained source order; do not download or run selected installers in parallel.')
        $plannedChanges.Add('For each selected app, download only its source-defined artifact(s), run only its source-defined installer/helper command and arguments, and perform only its source-defined post-install side effects.')
        $plannedChanges.Add('Stop the queue on the first failed selected app and report completed, failed, and remaining not-started apps.')
        $plannedChanges.Add('Removed app choices are hidden and cannot be selected, planned, downloaded, or installed.')
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
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Verify the Edge & WebView source checksum before execution.')
        $plannedChanges.Add('Temporarily set DeviceRegion to REG_DWORD 244 through the source reg1.exe copy, then restore the captured DeviceRegion when available.')
        $plannedChanges.Add('Stop the exact source-defined named process list and every running process whose ProcessName matches *edge*.')
        $plannedChanges.Add('Remove the exact source EdgeUpdate registry keys, run discovered MicrosoftEdgeUpdate.exe paths with /unregsvc and /uninstall, and wait for source Edge setup/update processes.')
        $plannedChanges.Add('Create and later remove the source Microsoft.MicrosoftEdge_8wekyb3d8bbwe SystemApps marker directory and MicrosoftEdge.exe marker file.')
        $plannedChanges.Add('Run the 32-bit Microsoft Edge uninstall string through cmd.exe with --force-uninstall when present.')
        $plannedChanges.Add('Delete the source Microsoft EdgeWebView uninstall key, Edge Quick Launch shortcut, Program Files (x86)\Microsoft folder, and every service whose Name matches Edge.')
        $plannedChanges.Add('If the Windows 10 legacy Edge CBS package exists, run the source Visibility/Owners registry edits and DISM /Remove-Package /quiet /norestart branch.')
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Verify the Edge & WebView source checksum before execution.')
        $plannedChanges.Add('Stop the exact source-defined named process list and every running process whose ProcessName matches *edge*.')
        $plannedChanges.Add('Download the source edge.exe and edgewebview.exe Ultimate-author-hosted artifacts to %SystemRoot%\Temp and launch each one with wait in the source order.')
        $plannedChanges.Add('Write the source Edge policies: ExtensionInstallForcelist, HardwareAccelerationModeEnabled DWORD 0, BackgroundModeEnabled DWORD 0, and StartupBoostEnabled DWORD 0.')
        $plannedChanges.Add('Remove source-matched Edge Active Setup components, RunOnce entries, Edge services, Edge scheduled tasks, and the native/WOW6432Node IE-to-Edge Browser Helper Object registry keys.')
        $plannedChanges.Add('Default is the source repair branch, not captured-state Restore.')
    }
    elseif ($toolId -eq 'edge-settings' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Verify the Edge Settings source checksum and report the source-equivalent Optimize and Default operation families.')
        $plannedChanges.Add('Report Edge policy, uBlock force-install, Active Setup, RunOnce, Edge service, scheduled task, BHO, process, download, and installer behavior without executing it.')
        $plannedChanges.Add('Perform no registry, service, scheduled-task, process, file, download, installer, Edge, or system mutation.')
    }
    elseif ($toolId -eq 'edge-settings' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Verify the Edge Settings source checksum before any mutation.')
        $plannedChanges.Add('Capture source-targeted registry/service/task metadata where practical before mutation.')
        $plannedChanges.Add('Write the source-defined uBlock force-install policy and three Edge policy values.')
        $plannedChanges.Add('Delete Active Setup child keys whose default value matches *Edge*.')
        $plannedChanges.Add('Delete RunOnce values whose names match *msedge*.')
        $plannedChanges.Add('Stop and delete services whose names match Edge using the source-derived dynamic match.')
        $plannedChanges.Add('Unregister scheduled tasks whose names match *Edge* using the source-derived wildcard.')
        $plannedChanges.Add('Delete both source-defined IE-to-Edge BHO registry keys.')
    }
    elseif ($toolId -eq 'edge-settings' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Verify the Edge Settings source checksum before any mutation.')
        $plannedChanges.Add('Capture the Edge policy key state before source-defined deletion.')
        $plannedChanges.Add('Delete HKLM:\SOFTWARE\Policies\Microsoft\Edge recursively, matching the source Default branch.')
        $plannedChanges.Add('Stop msedge, launch msedge.exe with --restore-last-session --disable-extensions, then stop msedge again.')
        $plannedChanges.Add('Download the source-defined edge.exe from the Ultimate source URL to Windows Temp.')
        $plannedChanges.Add('Start the downloaded edge.exe repair installer path.')
    }
    elseif ($toolId -eq 'edge-settings' -and $ActionName -eq 'Restore') {
        $plannedChanges.Add('Block Restore before any operational step.')
        $plannedChanges.Add('Require an approved selected captured-state restore contract before any Edge Settings Restore can be planned.')
        $plannedChanges.Add('Do not treat source Default as Restore.')
        $plannedChanges.Add('No Edge Settings registry, service, scheduled-task, process, download, installer, Edge, or system mutation is planned.')
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Read the Driver Install Debloat & Settings source checksum and implementation status.')
        $plannedChanges.Add('Report source behavior summary, Phase 122 NVIDIA/AMD/INTEL branch-scope decision, and exact branch operation plans.')
        $plannedChanges.Add('Keep Driver Install Debloat & Settings separate from Driver Clean and NVIDIA Path B.')
        $plannedChanges.Add('Perform no download, browser/external process launch, installer execution, file cleanup, profile import, package action, registry/service/driver mutation, reboot, or session change.')
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Open') {
        $plannedChanges.Add('Require selecting exactly one source branch: NVIDIA, AMD, or INTEL.')
        $plannedChanges.Add('Open the selected branch vendor driver page flow only.')
        $plannedChanges.Add('Do not download 7-Zip, download or run driver installers, extract driver packages, debloat files, mutate registry/profile/package/service/task/process/driver state, open shared display/sound panels, or reboot.')
        $plannedChanges.Add('Record the selected branch and skipped mutation families in Latest Result.')
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Require selecting exactly one source branch: NVIDIA, AMD, or INTEL.')
        $plannedChanges.Add('Run the source-defined admin and internet checks.')
        $plannedChanges.Add('Run the source-defined 7-Zip download/install/config flow.')
        $plannedChanges.Add('Open the selected vendor driver page, require selected installer input, extract the selected driver package, and execute only the selected source branch.')
        $plannedChanges.Add('For NVIDIA: remove source-defined driver components, run setup.exe with -s -noreboot -noeula -clean, install NVIDIA Control Panel through winget, remove Microsoft.Winget.Source, write NVIDIA registry/profile settings, download Profile Inspector, write/import the source .nip, then run shared UI/MSI/color/tray/restart steps.')
        $plannedChanges.Add('For AMD: edit source-defined XML/JSON files, run ATISetup.exe -INSTALL -VIEW:2, remove source-defined startup/task/service/driver/file targets, uninstall AMD Install Manager when present, open/stop Radeon Software, write AMD registry settings, then run shared UI/MSI/color/tray/restart steps.')
        $plannedChanges.Add('For INTEL: run Installer.exe -f --noExtras --terminateProcesses -s, install Intel Graphics Software extra package when present, remove source-defined startup/service/driver/process/file targets, write Intel registry settings, then run shared UI/MSI/color/tray/restart steps.')
        $plannedChanges.Add('Log every operation and target path; do not run branches in parallel.')
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
        $plannedChanges.Add('Report the exact source-equivalent operation plan and author-hosted artifact source policy for 7zip.exe and directx.exe.')
        $plannedChanges.Add('Perform no download, browser/external process launch, extraction, installer execution, registry change, shortcut cleanup, file cleanup, or system mutation.')
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Open') {
        $plannedChanges.Add('Block Open because DirectX does not expose a source-defined standalone Open action.')
        $plannedChanges.Add('Perform no system-changing operation.')
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Verify the DirectX source checksum before any mutation.')
        $plannedChanges.Add('Require Administrator execution and internet connectivity before downloads or installer launches.')
        $plannedChanges.Add('Download source-defined 7zip.exe from the Ultimate author-hosted URL to %SystemRoot%\Temp\7zip.exe.')
        $plannedChanges.Add('Run the 7-Zip installer with /S and wait for completion.')
        $plannedChanges.Add('Write the source-defined 7-Zip HKCU options: ContextMenu=259 and CascadedMenu=0.')
        $plannedChanges.Add('Move the 7-Zip File Manager Start Menu shortcut and silently remove the 7-Zip Start Menu folder, matching source tolerance.')
        $plannedChanges.Add('Download source-defined directx.exe from the Ultimate author-hosted URL to %SystemRoot%\Temp\directx.exe.')
        $plannedChanges.Add('Extract directx.exe with %SystemDrive%\Program Files\7-Zip\7z.exe into %SystemRoot%\Temp\directx.')
        $plannedChanges.Add('Launch %SystemRoot%\Temp\directx\DXSETUP.exe without waiting, matching the source.')
        $plannedChanges.Add('Record that both author-hosted artifacts are classified as NeedsBoostLabMirror; runtime URLs are not substituted and no provenance approval is created.')
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
        $plannedChanges.Add('Report the source behavior summary, all twelve author-hosted artifact classifications, and the exact source-equivalent install plan.')
        $plannedChanges.Add('Perform no download, external process launch, installer execution, package change, registry change, temp-file change, file cleanup, or system mutation.')
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Open') {
        $plannedChanges.Add('Block Open before any operational step.')
        $plannedChanges.Add('Do not expose a fake browser, external tool, source page, or manual handoff action for Visual C++.')
        $plannedChanges.Add('Perform no system-changing operation.')
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Verify the exact Visual C++ Ultimate source checksum before execution.')
        $plannedChanges.Add('Require BoostLab to be running elevated as Administrator.')
        $plannedChanges.Add('Verify internet connectivity using the source-equivalent 8.8.8.8 check.')
        $plannedChanges.Add('Download all twelve source-defined Visual C++ redistributable installers to `%SystemRoot%\Temp` from their unchanged Ultimate author-hosted URLs.')
        $plannedChanges.Add('Run all twelve installers sequentially with `Start-Process -Wait` in the exact source order.')
        $plannedChanges.Add('Use the exact source arguments: `/q` for 2005, `/qb` for 2008, and `/passive /norestart` for 2010, 2012, 2013, and 2015/2017/2019/2022 packages.')
        $plannedChanges.Add('Capture installer exit codes and fail closed if a required download, file check, process launch, or installer execution fails.')
        $plannedChanges.Add('Report that every Visual C++ artifact source remains `UltimateAuthorHostedArtifact` with `NeedsBoostLabMirror`; no artifact approval or mirror substitution is created.')
        $plannedChanges.Add('Do not add reboot, Default, Restore, 7-Zip, extraction, Safe Mode, RunOnce, DDU, driver, service, or package-selection behavior.')
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
    elseif ($toolId -eq 'bloatware' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Verify the exact Bloatware Ultimate source checksum and report all approved non-Exit source branches.')
        $plannedChanges.Add('Report the source admin, internet, and password sign-in registry preflight used before each source branch.')
        $plannedChanges.Add('Report branch plans for AppX removal/re-registration, Windows capability removal, optional feature disable/list/open behavior, service stop/delete, scheduled-task unregister, process stop, registry/hive import/delete, protected file ownership/delete, MSI/uninstaller execution, OneDrive setup, Remote Desktop Connection download/install, and Snipping Tool download/install.')
        $plannedChanges.Add('Perform no package, capability, feature, registry, hive, service, task, process, file, ownership, ACL, download, installer, uninstaller, external process, reboot, or system mutation during Analyze.')
    }
    elseif ($toolId -eq 'bloatware' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Require explicit confirmation and exactly one selected Bloatware source branch.')
        $plannedChanges.Add('Verify the exact Bloatware Ultimate source checksum before execution.')
        $plannedChanges.Add('Run the source Administrator and internet checks, then set the source password sign-in registry value before the selected branch.')
        $plannedChanges.Add('Execute only the selected source-equivalent branch: Remove all bloatware, Install Store, Install all UWP apps, Open/list UWP optional features, Open/list legacy optional features, Install OneDrive, Install Remote Desktop Connection, or Install Snipping Tool.')
        $plannedChanges.Add('Preserve source-defined AppX, Windows capability, optional feature, service, task, process, registry/hive, protected file, MSI/uninstaller, OneDrive setup, download, and installer intents in source order for that branch.')
        $plannedChanges.Add('Do not expose Exit, Default, Restore, or unrelated repair behavior for Bloatware.')
    }
    elseif ($toolId -eq 'game-bar' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Verify the exact Gamebar Ultimate source checksum before execution.')
        $plannedChanges.Add('Run the source Administrator and internet preflight checks.')
        $plannedChanges.Add('Stop GameBar, remove all-users AppX packages where Name matches *Gaming* or *Xbox*, stop GameInputSvc, stop gamingservices, gamingservicesnet, and GameInputRedistService, wait two seconds, uninstall Microsoft GameInput with msiexec when present, then stop the source GameInput targets again.')
        $plannedChanges.Add('Write %SystemRoot%\Temp\gamebaroff.reg with the exact source registry payload, import it with regedit.exe /S, and run the source TrustedInstaller reg add command that sets PresenceWriter ActivationType to DWORD 0.')
        $plannedChanges.Add('Do not expose source Exit, Open, or captured-state Restore for GameBar.')
    }
    elseif ($toolId -eq 'game-bar' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Verify the exact Gamebar Ultimate source checksum before execution.')
        $plannedChanges.Add('Run the source Administrator and internet preflight checks.')
        $plannedChanges.Add('Write %SystemRoot%\Temp\gamebaron.reg with the exact source Default registry payload, import it with regedit.exe /S, and run the source TrustedInstaller reg add command that sets PresenceWriter ActivationType to DWORD 1.')
        $plannedChanges.Add('Re-register all-users AppX packages where Name matches *Gaming*, *Xbox*, or *Store* from each package AppXManifest.xml.')
        $plannedChanges.Add('Download the source edgewebview.exe and gamingrepairtool.exe Ultimate-author-hosted artifacts to %SystemRoot%\Temp, launch edgewebview.exe with wait, then launch gamingrepairtool.exe.')
        $plannedChanges.Add('Default is the source repair/default branch, not captured-state Restore.')
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
        $plannedChanges.Add('Report the source-defined common 7-Zip prelude, On (Recommended) branch, Default branch, exact .nip payload source, Profile Inspector import request, and NVIDIA Control Panel launch request.')
        $plannedChanges.Add('Report Path B step 2 of 5 while keeping Nvidia Settings separate from Driver Install Latest, Hdcp, P0 State, and Msi Mode.')
        $plannedChanges.Add('Perform no 7-Zip download/install, Profile Inspector download/execution, .nip write/import, NVIDIA Control Panel launch, external process start, registry/profile mutation, or system mutation.')
    }
    elseif ($toolId -eq 'nvidia-settings' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Verify the Nvidia Settings source mirror checksum before any operation.')
        $plannedChanges.Add('Require explicit Action Plan confirmation, Administrator elevation, and internet connectivity.')
        $plannedChanges.Add('Run the source-defined common prelude: download 7zip.exe to %SystemRoot%\Temp, install it silently, write HKCU 7-Zip options, move the 7-Zip File Manager shortcut, and remove the 7-Zip Start Menu folder.')
        $plannedChanges.Add('Run the source-defined On (Recommended) branch: unblock NVIDIA Drs files; set NvCplPhysxAuto, NvDevToolsVisible, RmProfilingAdminOnly, NvTray StartOnLogin, and EnableGR535 values; download Profile Inspector; write the exact source On inspector.nip payload; import it silently; then open NVIDIA Control Panel.')
        $plannedChanges.Add('Do not run Hdcp, P0 State, Msi Mode, Driver Install Latest, or Driver Install Debloat & Settings behavior.')
        $plannedChanges.Add('Do not reboot, use Safe Mode, use TrustedInstaller, create RunOnce, modify services, or modify drivers.')
    }
    elseif ($toolId -eq 'nvidia-settings' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Verify the Nvidia Settings source mirror checksum before any operation.')
        $plannedChanges.Add('Require explicit Action Plan confirmation, Administrator elevation, and internet connectivity.')
        $plannedChanges.Add('Run the source-defined common prelude: download 7zip.exe to %SystemRoot%\Temp, install it silently, write HKCU 7-Zip options, move the 7-Zip File Manager shortcut, and remove the 7-Zip Start Menu folder.')
        $plannedChanges.Add('Run the source-defined Default branch: unblock NVIDIA Drs files; delete NvCplPhysxAuto, NvDevToolsVisible, dynamic-display RmProfilingAdminOnly, NVTweak RmProfilingAdminOnly, and NvTray; set EnableGR535 to DWORD 1 on all three source paths; download Profile Inspector; write the exact source Default inspector.nip payload; import it silently; then open NVIDIA Control Panel.')
        $plannedChanges.Add('Default is source-defined behavior, not captured-state Restore.')
        $plannedChanges.Add('Do not reboot, use Safe Mode, use TrustedInstaller, create RunOnce, modify services, or modify drivers.')
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Verify the HDCP source mirror checksum.')
        $plannedChanges.Add('Report Path B step 3 of 5 while keeping Driver Install Latest, Nvidia Settings, Hdcp, P0 State, and Msi Mode separate.')
        $plannedChanges.Add('Discover the source display-class registry target shape read-only using immediate subkey .Name values.')
        $plannedChanges.Add('Report non-Configuration source targets and Configuration-skipped targets without applying GPU vendor filtering.')
        $plannedChanges.Add('Report the exact source value RMHdcpKeyglobZero as REG_DWORD 1 for Apply and REG_DWORD 0 for Default.')
        $plannedChanges.Add('Perform no registry capture, registry write, external process, download, reboot, driver change, or profile mutation.')
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Verify the approved HDCP source mirror checksum before any target discovery or mutation.')
        $plannedChanges.Add('Discover only immediate source display-class registry subkeys under HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}, excluding Configuration.')
        $plannedChanges.Add('Do not apply GPU vendor filtering; the Ultimate source writes every non-Configuration display-class subkey returned by the source query.')
        $plannedChanges.Add('Block before capture or write if no source-included target exists or if target discovery includes an out-of-scope registry path.')
        $plannedChanges.Add('Capture prior state for RMHdcpKeyglobZero on every source-included target before writing.')
        $plannedChanges.Add('Set RMHdcpKeyglobZero as REG_DWORD 1 on every captured source-included target.')
        $plannedChanges.Add('Read back RMHdcpKeyglobZero after Apply and record post-mutation state for rollback evidence.')
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Verify the approved HDCP source mirror checksum before any target discovery or mutation.')
        $plannedChanges.Add('Discover only immediate source display-class registry subkeys under HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}, excluding Configuration.')
        $plannedChanges.Add('Do not apply GPU vendor filtering; the Ultimate source writes every non-Configuration display-class subkey returned by the source query.')
        $plannedChanges.Add('Block before capture or write if no source-included target exists or if target discovery includes an out-of-scope registry path.')
        $plannedChanges.Add('Capture prior state for RMHdcpKeyglobZero on every source-included target before writing.')
        $plannedChanges.Add('Set RMHdcpKeyglobZero as REG_DWORD 0 on every captured source-included target, matching the Ultimate Default branch.')
        $plannedChanges.Add('Read back RMHdcpKeyglobZero after Default and record post-mutation state for rollback evidence.')
        $plannedChanges.Add('Default is source-defined behavior, not captured-state Restore.')
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Verify the P0 State source mirror checksum.')
        $plannedChanges.Add('Report Path B step 4 of 5 while keeping Driver Install Latest, Nvidia Settings, HDCP, P0 State, and Msi Mode separate.')
        $plannedChanges.Add('Discover immediate source display-class registry subkeys read-only and report source-included targets separately from paths skipped by the *Configuration* rule.')
        $plannedChanges.Add('Report the exact source value DisableDynamicPstate as REG_DWORD 1 for Apply and REG_DWORD 0 for Default.')
        $plannedChanges.Add('Report that no Restore action is source-defined or exposed; Default is the source-defined DWORD 0 branch.')
        $plannedChanges.Add('Perform no registry capture, registry write, external process, download, reboot, driver change, or profile mutation.')
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Verify the approved P0 State source mirror checksum before any target discovery or mutation.')
        $plannedChanges.Add('Discover only immediate source display-class registry subkeys under HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}, excluding Configuration.')
        $plannedChanges.Add('Do not apply GPU vendor filtering; the Ultimate source writes every non-Configuration display-class subkey returned by the source query.')
        $plannedChanges.Add('Block before capture or write if no source-included target exists or if target discovery includes an out-of-scope registry path.')
        $plannedChanges.Add('Capture prior state for DisableDynamicPstate on every source-included target before writing.')
        $plannedChanges.Add('Set DisableDynamicPstate as REG_DWORD 1 on every captured source-included target.')
        $plannedChanges.Add('Read back DisableDynamicPstate after Apply and record post-mutation state for rollback evidence.')
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Verify the approved P0 State source mirror checksum before any target discovery or mutation.')
        $plannedChanges.Add('Discover only immediate source display-class registry subkeys under HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}, excluding Configuration.')
        $plannedChanges.Add('Do not apply GPU vendor filtering; the Ultimate source writes every non-Configuration display-class subkey returned by the source query.')
        $plannedChanges.Add('Block before capture or write if no source-included target exists or if target discovery includes an out-of-scope registry path.')
        $plannedChanges.Add('Capture prior state for DisableDynamicPstate on every source-included target before writing.')
        $plannedChanges.Add('Set DisableDynamicPstate as REG_DWORD 0 on every captured source-included target, matching the Ultimate Default branch.')
        $plannedChanges.Add('Read back DisableDynamicPstate after Default and record post-mutation state for rollback evidence.')
        $plannedChanges.Add('Default is source-defined behavior, not captured-state Restore.')
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Verify the Msi Mode source mirror checksum.')
        $plannedChanges.Add('Report Path B step 5 of 5 while keeping Driver Install Latest, Nvidia Settings, HDCP, P0 State, and Msi Mode separate.')
        $plannedChanges.Add('Discover the exact source PnP query shape read-only: Get-PnpDevice -Class Display, then build the HKLM:\SYSTEM\ControlSet001\Enum\<InstanceId>\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties target path for every display device with a usable InstanceId.')
        $plannedChanges.Add('Report the exact source value MSISupported as REG_DWORD 1 for On (Recommended) and REG_DWORD 0 for Off.')
        $plannedChanges.Add('Report that the source defines Off as a visible branch and does not define Default or Restore.')
        $plannedChanges.Add('Perform no registry capture, registry write, external process, download, reboot, driver change, device restart, or profile mutation.')
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Verify the approved Msi Mode source mirror checksum before any target discovery or mutation.')
        $plannedChanges.Add('Discover source display devices using Get-PnpDevice -Class Display and derive the exact HKLM:\SYSTEM\ControlSet001\Enum\<InstanceId>\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties target path.')
        $plannedChanges.Add('Do not apply source-undefined NVIDIA/RDP/status/vendor filtering; every source display-device target with a usable InstanceId remains in scope.')
        $plannedChanges.Add('Block before capture or write if no usable display-device target exists or if target discovery includes an out-of-scope registry path.')
        $plannedChanges.Add('Capture prior state for MSISupported on every source-derived display-device target before writing.')
        $plannedChanges.Add('Set only MSISupported as REG_DWORD 1 on every captured source-derived display-device target.')
        $plannedChanges.Add('Read back MSISupported after On (Recommended) and record post-mutation state for rollback evidence.')
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Off') {
        $plannedChanges.Add('Verify the approved Msi Mode source mirror checksum before any target discovery or mutation.')
        $plannedChanges.Add('Discover source display devices using Get-PnpDevice -Class Display and derive the exact HKLM:\SYSTEM\ControlSet001\Enum\<InstanceId>\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties target path.')
        $plannedChanges.Add('Do not apply source-undefined NVIDIA/RDP/status/vendor filtering; every source display-device target with a usable InstanceId remains in scope.')
        $plannedChanges.Add('Block before capture or write if no usable display-device target exists or if target discovery includes an out-of-scope registry path.')
        $plannedChanges.Add('Capture prior state for MSISupported on every source-derived display-device target before writing.')
        $plannedChanges.Add('Set only MSISupported as REG_DWORD 0 on every captured source-derived display-device target, matching the Ultimate Off branch.')
        $plannedChanges.Add('Read back MSISupported after Off and record post-mutation state for rollback evidence.')
        $plannedChanges.Add('Off is a source-defined branch, not Default or Restore.')
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
    elseif ($toolId -eq 'copilot' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Stop every source-defined named process: backgroundTaskHost, Copilot, CrossDeviceResume, GameBar, MicrosoftEdgeUpdate, msedge, msedgewebview2, OneDrive, OneDrive.Sync.Service, OneDriveStandaloneUpdater, Resume, RuntimeBroker, Search, SearchHost, Setup, StoreDesktopExtension, WidgetService, and Widgets.')
        $plannedChanges.Add('Stop every running process whose ProcessName matches *edge*.')
        $plannedChanges.Add('Remove AppX packages returned by Get-AppXPackage -AllUsers where Name matches *Copilot*.')
        $plannedChanges.Add('Set HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot TurnOffWindowsCopilot to REG_DWORD 1.')
        $plannedChanges.Add('Set HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot TurnOffWindowsCopilot to REG_DWORD 1.')
    }
    elseif ($toolId -eq 'copilot' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Re-register AppX packages returned by Get-AppXPackage -AllUsers where Name matches *Copilot* using each package AppXManifest.xml.')
        $plannedChanges.Add('Delete HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot exactly as the Ultimate Default branch defines.')
        $plannedChanges.Add('Delete HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot exactly as the Ultimate Default branch defines.')
        $plannedChanges.Add('Default is source-defined and is not captured-state Restore.')
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
        $plannedChanges.Add('Delete the complete source-defined Shell Extensions Blocked key exactly as Ultimate does.')
        $plannedChanges.Add('Verify all 21 approved default Context Menu registry states.')
    }
    elseif ($toolId -eq 'signout-lockscreen-wallpaper-black' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Generate C:\Windows\Black.jpg as a black bitmap at the primary monitor resolution.')
        $plannedChanges.Add('Set HKLM PersonalizationCSP LockScreenImagePath to C:\Windows\Black.jpg.')
        $plannedChanges.Add('Set HKLM PersonalizationCSP LockScreenImageStatus to REG_DWORD 1.')
        $plannedChanges.Add('Set the current user desktop Wallpaper value to C:\Windows\Black.jpg and request the source wallpaper refresh.')
    }
    elseif ($toolId -eq 'signout-lockscreen-wallpaper-black' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Delete the complete HKLM PersonalizationCSP key exactly as the Ultimate source defines.')
        $plannedChanges.Add('Set the current user desktop Wallpaper value to C:\Windows\Web\Wallpaper\Windows\img0.jpg and request the source wallpaper refresh.')
        $plannedChanges.Add('Delete C:\Windows\Black.jpg exactly as the Ultimate source defines.')
    }
    elseif ($toolId -eq 'notepad-settings' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Stop only the Notepad process and wait for the source-defined two-second delay.')
        $plannedChanges.Add('Write the source-compatible notepadsettings.reg file under Windows Temp.')
        $plannedChanges.Add('Load settings.dat at HKLM\Settings, import the three source-defined LocalState values only when load succeeds, and unload the hive.')
        $plannedChanges.Add('Do not create a backup or state record because Ultimate does not define backup or Restore behavior.')
    }
    elseif ($toolId -eq 'notepad-settings' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Stop only the Notepad process and wait for the source-defined two-second delay.')
        $plannedChanges.Add('Run the source-defined Remove-Item action only against Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings\settings.dat.')
        $plannedChanges.Add('Do not create a backup or state record because Ultimate does not define backup or Restore behavior.')
    }
    elseif ($toolId -eq 'control-panel-settings' -and ($ActionName -eq 'Apply' -or $ActionName -eq 'Default')) {
        $branchName = if ($ActionName -eq 'Apply') { 'Optimize (Recommended)' } else { 'Default' }
        $plannedChanges.Add("Verify the Control Panel Settings Ultimate source checksum before running the $branchName branch.")
        $plannedChanges.Add('Execute the exact source-backed branch through BoostLab runtime confirmation and script-runner plumbing.')
        $plannedChanges.Add('The source branch may stop services/processes, change TrustedInstaller service binPath temporarily, import broad registry payloads, change scheduled tasks and powercfg values, and write/delete source-defined settings files.')
        $plannedChanges.Add('Do not expose Restore or Open because the Ultimate source defines only Optimize and Default branches.')
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
        $plannedChanges.Add('Make no registry changes.')
    }
    elseif ($toolId -eq 'write-cache-buffer-flushing' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Enumerate the same source-targeted SCSI and NVME Device Parameters paths and validate the exact Disk child path.')
        $plannedChanges.Add('Capture the prior CacheIsPowerProtected existence, type, and data for every target before any write.')
        $plannedChanges.Add('Set only CacheIsPowerProtected to REG_DWORD 1 on each captured target.')
        $plannedChanges.Add('Verify each changed value and record post-mutation evidence for future review.')
    }
    elseif ($toolId -eq 'write-cache-buffer-flushing' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Enumerate source-discovered Disk keys under HKLM:\SYSTEM\ControlSet001\Enum\SCSI and NVME.')
        $plannedChanges.Add('Capture each target Disk key state before deletion.')
        $plannedChanges.Add('Delete each discovered Disk key exactly as the Ultimate Default branch does.')
        $plannedChanges.Add('Verify each target Disk key is absent and record post-mutation evidence for future review.')
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
    elseif ($toolId -eq 'cleanup' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Delete the contents of %USERPROFILE%\AppData\Local\Temp\* recursively exactly as the source does.')
        $plannedChanges.Add('Delete the contents of %SystemDrive%\Windows\Temp\* recursively exactly as the source does.')
        $plannedChanges.Add('Delete %SystemDrive%\inetpub, %SystemDrive%\PerfLogs, %SystemDrive%\Windows.old, and %SystemDrive%\DumpStack.log exactly as the source does.')
        $plannedChanges.Add('Launch cleanmgr.exe after the source-defined Remove-Item operations.')
        $plannedChanges.Add('Expose no Default, Restore, download, registry, service, task, process-stop, or reboot behavior.')
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
    elseif ($toolId -eq 'services-optimizer' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Verify the Services Optimizer Ultimate source SHA-256 and parse the source-defined Services: Off and Services: Default workflows.')
        $plannedChanges.Add('Report generated script names, RunOnce value names, Safe Mode workflow, TrustedInstaller REG import behavior, and service target counts without staging changes.')
        $plannedChanges.Add('Confirm the rejected smart analyzer/profile redesign is not used.')
    }
    elseif ($toolId -eq 'services-optimizer' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Attempt the source-defined restore point prelude.')
        $plannedChanges.Add('Write and patch %SystemRoot%\\Temp\\servicesoff.ps1 from the verified Ultimate Services: Off generated script.')
        $plannedChanges.Add('Create RunOnce value *servicesoff to run the generated script in Safe Mode.')
        $plannedChanges.Add('Run bcdedit /set {current} safeboot minimal.')
        $plannedChanges.Add('Request the source-defined restart with shutdown -r -t 00.')
        $plannedChanges.Add('The generated script imports servicesoff.reg as TrustedInstaller and Administrator, removes safeboot, and restarts again.')
    }
    elseif ($toolId -eq 'services-optimizer' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Attempt the source-defined restore point prelude.')
        $plannedChanges.Add('Write and patch %SystemRoot%\\Temp\\serviceson.ps1 from the verified Ultimate Services: Default generated script.')
        $plannedChanges.Add('Create RunOnce value *serviceson to run the generated script in Safe Mode.')
        $plannedChanges.Add('Run bcdedit /set {current} safeboot minimal.')
        $plannedChanges.Add('Request the source-defined restart with shutdown -r -t 00.')
        $plannedChanges.Add('The generated script imports serviceson.reg as TrustedInstaller and Administrator, removes safeboot, and restarts again.')
    }
    elseif ($toolId -eq 'timer-resolution-assistant' -and $ActionName -eq 'Analyze') {
        $plannedChanges.Add('Verify the Timer Resolution Assistant Ultimate source SHA-256 and extract the embedded source-defined C# service payload.')
        $plannedChanges.Add('Report the service names, compiler path and arguments, generated file paths, timer registry value, and Task Manager verification launcher.')
        $plannedChanges.Add('No service, file, registry, process, download, installer, reboot, Safe Mode, or TrustedInstaller operation is executed during Analyze.')
    }
    elseif ($toolId -eq 'timer-resolution-assistant' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Write the source-defined C# payload to C:\Windows\SetTimerResolutionService.cs.')
        $plannedChanges.Add('Run C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe with the exact source arguments to compile C:\Windows\SetTimerResolutionService.exe.')
        $plannedChanges.Add('Delete C:\Windows\SetTimerResolutionService.cs after compilation.')
        $plannedChanges.Add('Delete an existing Set Timer Resolution Service when present, then create it from the generated executable.')
        $plannedChanges.Add('Set the service startup type to Auto and start the service.')
        $plannedChanges.Add('Set HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel\GlobalTimerResolutionRequests to REG_DWORD 1.')
        $plannedChanges.Add('Open taskmgr.exe for source-defined verification. No download, installer, reboot, Safe Mode, TrustedInstaller, or driver operation is used.')
    }
    elseif ($toolId -eq 'timer-resolution-assistant' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Set the Set Timer Resolution Service startup type to Disabled and stop the service.')
        $plannedChanges.Add('Delete the Set Timer Resolution Service using the source-defined sc.exe command.')
        $plannedChanges.Add('Delete C:\Windows\SetTimerResolutionService.exe.')
        $plannedChanges.Add('Delete HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel\GlobalTimerResolutionRequests.')
        $plannedChanges.Add('Open taskmgr.exe for source-defined verification. Default is the source-defined reset branch, not captured-state Restore.')
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
    $isBlockedInstallersNoMutationAction = $toolId -eq 'installers' -and $ActionName -in @('Default', 'Restore')
    $isBlockedEdgeWebViewNoMutationAction = $false
    $isBlockedDriverInstallLatestNoMutationAction = $toolId -eq 'driver-install-latest' -and $ActionName -in @('Default', 'Restore')
    $isBlockedDriverInstallDebloatSettingsNoMutationAction = $toolId -eq 'driver-install-debloat-settings' -and $ActionName -in @('Default', 'Restore')
    $isBlockedDirectXNoMutationAction = $toolId -eq 'directx' -and $ActionName -in @('Default', 'Restore')
    $isBlockedVisualCppNoMutationAction = $toolId -eq 'visual-cpp' -and $ActionName -in @('Default', 'Restore')
    $isBlockedReinstallNoMutationAction = $toolId -eq 'reinstall' -and $ActionName -in @('Default', 'Restore')
    $isBlockedUpdatesDriversBlockRestoreNoMutationAction = $toolId -eq 'updates-drivers-block' -and $ActionName -eq 'Restore'
    $isBlockedEdgeSettingsRestoreNoMutationAction = $toolId -eq 'edge-settings' -and $ActionName -eq 'Restore'
    if ($isPotentialChangeAction -and -not $isBlockedBitLockerNoMutationAction -and -not $isBlockedInstallersNoMutationAction -and -not $isBlockedEdgeWebViewNoMutationAction -and -not $isBlockedDriverInstallLatestNoMutationAction -and -not $isBlockedDriverInstallDebloatSettingsNoMutationAction -and -not $isBlockedDirectXNoMutationAction -and -not $isBlockedVisualCppNoMutationAction -and -not $isBlockedReinstallNoMutationAction -and -not $isBlockedUpdatesDriversBlockRestoreNoMutationAction -and -not $isBlockedEdgeSettingsRestoreNoMutationAction) {
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
    if ($capabilities.RequiresAdmin -and -not $isReadOnlyAnalyzePrivilegeOverride -and $toolId -notin @('installers') -and -not $isBlockedEdgeSettingsRestoreNoMutationAction -and -not $isBlockedDriverInstallLatestNoMutationAction) {
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
        $sideEffects.Add('7-Zip and DDU are downloaded from the exact source URLs, and 7-Zip is installed/configured.')
        $sideEffects.Add('Windows driver-search policy, RunOnce, bcdedit Safe Mode, generated scripts, DDU files, and reboot state are changed.')
        $sideEffects.Add('The Manual branch opens DDU after reboot through the source-defined RunOnce script.')
    }
    elseif ($toolId -eq 'driver-clean' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('7-Zip and DDU are downloaded from the exact source URLs, and 7-Zip is installed/configured.')
        $sideEffects.Add('Windows driver-search policy, RunOnce, bcdedit Safe Mode, generated scripts, DDU files, and reboot state are changed.')
        $sideEffects.Add('The Auto branch runs DDU after reboot with -CleanSoundBlaster -CleanRealtek -CleanAllGpus -Restart.')
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; Driver Install Latest analysis is read-only.')
        $sideEffects.Add('No warnings are duplicated between result-level warnings and structured details.')
        $sideEffects.Add('NVIDIA, AMD, and INTEL source branch plans are reported without vendor queries, downloads, installer launches, browser/page launches, driver mutation, reboot, or session changes.')
        $sideEffects.Add('Path B step 1 is reported without enabling the remaining Path B steps.')
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Open') {
        $sideEffects.Add('Open requires a selected branch and runs only the source-defined INTEL standalone browser/page behavior when INTEL is selected.')
        $sideEffects.Add('The INTEL branch may open the source-defined Intel Windows 11 graphics driver search page.')
        $sideEffects.Add('The NVIDIA and AMD branches have no standalone source Open behavior; BoostLab reports that without opening external processes.')
        $sideEffects.Add('No driver installer is downloaded or launched by Open.')
        $sideEffects.Add('No registry, driver, file, reboot, or session change occurs from Open.')
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Apply may query vendor APIs/pages, download source-defined driver installers, and launch the selected branch installer or driver page.')
        $sideEffects.Add('Driver installer handoff may affect display output, driver state, session state, and reboot prompts controlled by the vendor installer.')
        $sideEffects.Add('No registry/service/task/profile/debloat steps from other Graphics tools are run by Driver Install Latest.')
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -in @('Default', 'Restore')) {
        $sideEffects.Add("$ActionName is blocked before execution.")
        $sideEffects.Add('No driver, file, registry, installer, process, reboot, or session mutation is planned.')
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
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Apply can stop source-targeted processes, remove EdgeUpdate registry keys, run Edge update/uninstall executables, run Edge uninstall through cmd.exe, delete source-targeted files/folders/shortcut, delete Edge services, and optionally run the source legacy Edge DISM removal branch.')
        $sideEffects.Add('Apply temporarily sets DeviceRegion to the source US value and restores the captured value when one was present.')
        $sideEffects.Add('No reboot, Safe Mode, TrustedInstaller operation, source file change, source mirror change, artifact provenance approval, or production allowlist entry is added.')
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Default can stop source-targeted processes, download and launch source Edge/WebView repair executables, write Edge policy values, remove Active Setup and RunOnce Edge entries, delete Edge services/tasks, and delete source BHO registry keys.')
        $sideEffects.Add('The source repair EXEs remain classified as UltimateAuthorHostedArtifact / NeedsBoostLabMirror; no artifact provenance approval, production allowlist entry, binary vendoring, or mirror substitution is created.')
        $sideEffects.Add('Default is not Restore. No reboot, Safe Mode, TrustedInstaller operation, source file change, source mirror change, artifact provenance approval, or production allowlist behavior is changed.')
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; Driver Install Debloat & Settings analysis is read-only.')
        $sideEffects.Add('No warnings are duplicated between result-level warnings and structured details.')
        $sideEffects.Add('Driver Install Debloat & Settings remains separate from Driver Clean and NVIDIA Path B.')
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Open') {
        $sideEffects.Add('The selected branch vendor driver page may open after confirmation.')
        $sideEffects.Add('No 7-Zip download/install, driver download, installer execution, driver extraction/debloat, Profile Inspector execution, .nip import, winget/AppX action, registry/service/driver mutation, display/sound launch, reboot, or session change occurs from Open.')
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Apply can download 7-Zip and Profile Inspector, open vendor pages, run driver installers, extract files, remove source-defined driver components, edit AMD XML/JSON files, change package/AppX/winget state, write registry/profile settings, stop processes, delete services/drivers/tasks, open UI panels, and restart.')
        $sideEffects.Add('Only one selected branch runs; NVIDIA, AMD, and INTEL branches are not run in parallel.')
        $sideEffects.Add('This approval is tool-specific and does not expand project-wide AMD/Intel GPU scope.')
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
        $sideEffects.Add('No downloads, installers, extraction, registry writes, shortcut cleanup, DXSETUP launch, or reboot occur during Analyze.')
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Open') {
        $sideEffects.Add('Open is not exposed for DirectX.')
        $sideEffects.Add('No system-changing operation occurs.')
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Downloads and executes source-defined installer/setup files from author-hosted URLs after confirmation.')
        $sideEffects.Add('Installs/configures 7-Zip, writes HKCU 7-Zip option values, adjusts source-defined Start Menu shortcut state, extracts DirectX, and launches DXSETUP.')
        $sideEffects.Add('The source does not request a reboot; any reboot prompt would come from the launched DirectX setup UI, not BoostLab.')
        $sideEffects.Add('No services, drivers, Safe Mode, TrustedInstaller, RunOnce, DDU, source file, mirror file, artifact provenance, or production allowlist behavior is changed.')
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
        $sideEffects.Add('Open is blocked before execution because the source defines no standalone Open branch.')
        $sideEffects.Add('No browser, external tool, Visual C++ download, installer launch, package change, registry change, temp-file change, file cleanup, or system mutation occurs.')
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Downloads twelve source-defined Visual C++ redistributable installers from unchanged Ultimate author-hosted URLs to %SystemRoot%\Temp.')
        $sideEffects.Add('Runs all twelve installers sequentially with Start-Process -Wait and source-defined switches; installer side effects may change Visual C++ redistributable package, file, registry, and application state.')
        $sideEffects.Add('Artifacts remain classified as UltimateAuthorHostedArtifact / NeedsBoostLabMirror; no BoostLab mirror substitution or artifact approval is created.')
        $sideEffects.Add('No source-defined reboot, Default, Restore, 7-Zip, extraction, Safe Mode, RunOnce, DDU, driver, service, or package-selection behavior is added.')
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Default is blocked before execution.')
        $sideEffects.Add('No artifact, package, installer, registry, temp-file, cleanup, or system state changes occur.')
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Restore') {
        $sideEffects.Add('Restore is blocked without selected captured artifact, package, registry, temp-file, installer, and cleanup state plus an approved restore contract.')
        $sideEffects.Add('No system-changing operation occurs.')
    }
    elseif ($toolId -eq 'bloatware' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; Bloatware analysis is read-only.')
        $sideEffects.Add('No package, capability, feature, registry, hive, service, task, process, file, ACL, ownership, download, installer, uninstaller, or reboot operation occurs during Analyze.')
    }
    elseif ($toolId -eq 'bloatware' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('The selected source branch can remove or re-register AppX packages, remove Windows capabilities, disable optional features, stop/delete services, unregister tasks, stop processes, write/delete/import registry state and hives, change ownership/ACLs, delete protected files, download source-defined EXEs, and run installers or uninstallers.')
        $sideEffects.Add('Downloaded EXEs remain classified as UltimateAuthorHostedArtifact / NeedsBoostLabMirror; no artifact provenance approval, production allowlist entry, binary vendoring, or mirror substitution is created.')
        $sideEffects.Add('Bloatware has no source-defined Default or captured-state Restore action; BoostLab does not expose either one.')
    }
    elseif ($toolId -eq 'game-bar' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Apply can remove Gaming/Xbox AppX packages, stop GameBar/GameInput processes, stop GameInputSvc, uninstall Microsoft GameInput with msiexec, write/import source registry payloads, and run the source TrustedInstaller registry command.')
        $sideEffects.Add('No download or installer launch is part of the source Off branch. No reboot, Safe Mode, driver mutation, source file change, mirror file change, artifact provenance, or production allowlist behavior is changed.')
    }
    elseif ($toolId -eq 'game-bar' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Default can write/import source registry payloads, run the source TrustedInstaller registry command, re-register Gaming/Xbox/Store AppX packages, download source edgewebview.exe and gamingrepairtool.exe, and launch both downloaded tools.')
        $sideEffects.Add('The downloaded EXEs remain classified as UltimateAuthorHostedArtifact / NeedsBoostLabMirror; no artifact provenance approval, production allowlist entry, binary vendoring, or mirror substitution is created.')
        $sideEffects.Add('Default is not Restore. No reboot, Safe Mode, driver mutation, source file change, mirror file change, artifact provenance, or production allowlist behavior is changed.')
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
        $sideEffects.Add('Source-equivalent On and Default plans are reported without enabling the remaining Path B steps.')
    }
    elseif ($toolId -eq 'nvidia-settings' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Downloads and installs the source-defined 7-Zip artifact from the Ultimate source URL, then downloads and runs source-defined NVIDIA Profile Inspector.')
        $sideEffects.Add('Writes NVIDIA registry/profile settings, writes/imports the exact source On inspector.nip payload, cleans source-defined 7-Zip Start Menu entries, and opens NVIDIA Control Panel.')
        $sideEffects.Add('No reboot, Safe Mode, TrustedInstaller, service change, driver mutation, or unrelated Path B step runs.')
    }
    elseif ($toolId -eq 'nvidia-settings' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Downloads and installs the source-defined 7-Zip artifact from the Ultimate source URL, then downloads and runs source-defined NVIDIA Profile Inspector.')
        $sideEffects.Add('Deletes or resets only the source-defined NVIDIA Settings registry/profile targets, writes/imports the exact source Default inspector.nip payload, cleans source-defined 7-Zip Start Menu entries, and opens NVIDIA Control Panel.')
        $sideEffects.Add('Default is not Restore; no reboot, Safe Mode, TrustedInstaller, service change, driver mutation, or unrelated Path B step runs.')
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
        $sideEffects.Add('Writes RMHdcpKeyglobZero as REG_DWORD 1 on every source-included non-Configuration display-class subkey after source checksum validation and capture.')
        $sideEffects.Add('No external process, download, Control Panel launch, profile import, driver install, reboot, service change, or source-undefined registry path write occurs.')
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Writes RMHdcpKeyglobZero as REG_DWORD 0 on every source-included non-Configuration display-class subkey after source checksum validation and capture.')
        $sideEffects.Add('Default is source-defined behavior and is not captured-state Restore.')
        $sideEffects.Add('No external process, download, Control Panel launch, profile import, driver install, reboot, service change, or source-undefined registry path write occurs.')
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; P0 State analysis is read-only.')
        $sideEffects.Add('Path B step 4 is reported without merging Driver Install Latest, Nvidia Settings, HDCP, or Msi Mode.')
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Writes only DisableDynamicPstate as REG_DWORD 1 after source-included non-Configuration display-class target discovery and capture succeed.')
        $sideEffects.Add('No external process, download, Control Panel launch, profile import, driver install, reboot, service change, or source-undefined registry path write occurs.')
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Writes only DisableDynamicPstate as REG_DWORD 0 after source-included non-Configuration display-class target discovery and capture succeed.')
        $sideEffects.Add('Default is source-defined behavior and is not a captured-state Restore.')
        $sideEffects.Add('No external process, download, Control Panel launch, profile import, driver install, reboot, service change, or source-undefined registry path write occurs.')
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; Msi Mode analysis is read-only.')
        $sideEffects.Add('Path B step 5 is reported without merging Driver Install Latest, Nvidia Settings, HDCP, or P0 State.')
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Writes only MSISupported as REG_DWORD 1 after source Get-PnpDevice display-device target discovery and capture succeed.')
        $sideEffects.Add('No external process, download, Control Panel launch, profile import, driver install, device restart, reboot, service change, or source-undefined registry write occurs.')
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Off') {
        $sideEffects.Add('Writes only MSISupported as REG_DWORD 0 after source Get-PnpDevice display-device target discovery and capture succeed.')
        $sideEffects.Add('Off is source-defined behavior and is not Default or captured-state Restore.')
        $sideEffects.Add('No external process, download, Control Panel launch, profile import, driver install, device restart, reboot, service change, or source-undefined registry write occurs.')
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
    elseif ($toolId -eq 'copilot' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('The source process list and any process matching *edge* may be force-closed, including Edge, Search, Widgets, GameBar, OneDrive, and related hosts.')
        $sideEffects.Add('All-users AppX packages with names matching *Copilot* are removed according to the approved Ultimate source.')
        $sideEffects.Add('HKCU and HKLM WindowsCopilot policy keys are set to disable Copilot; no download, installer, service, task, driver, TrustedInstaller, Safe Mode, file cleanup, or reboot operation is performed.')
    }
    elseif ($toolId -eq 'copilot' -and $ActionName -eq 'Default') {
        $sideEffects.Add('All-users AppX packages with names matching *Copilot* are re-registered from their AppXManifest.xml when present.')
        $sideEffects.Add('The HKCU and HKLM WindowsCopilot policy keys are deleted exactly as Ultimate defines; Default is not Restore and does not use captured state.')
        $sideEffects.Add('No download, installer, service, task, driver, TrustedInstaller, Safe Mode, file cleanup, or reboot operation is performed.')
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
        $sideEffects.Add('The complete Shell Extensions Blocked key is removed exactly as Ultimate defines; unrelated blocked shell-extension values in that key can also be removed.')
        $sideEffects.Add('No Explorer process is stopped; reopening the context menu, Explorer refresh, or sign-out may be required before every visual change appears.')
    }
    elseif ($toolId -eq 'signout-lockscreen-wallpaper-black' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('The desktop, sign-out, and lock screen wallpaper may become black.')
        $sideEffects.Add('Any existing C:\Windows\Black.jpg is overwritten by the source-defined generated image.')
        $sideEffects.Add('No process is stopped and no restart occurs; Windows may require lock, sign-out, Settings, or Explorer refresh before every visual change appears.')
    }
    elseif ($toolId -eq 'signout-lockscreen-wallpaper-black' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Wallpaper registry values return to the approved source default.')
        $sideEffects.Add('The complete PersonalizationCSP key is deleted exactly as the Ultimate source defines.')
        $sideEffects.Add('C:\Windows\Black.jpg is deleted exactly as the Ultimate source defines.')
    }
    elseif ($toolId -eq 'notepad-settings' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Running Notepad is closed and unsaved Notepad work can be lost.')
        $sideEffects.Add('The current user Notepad settings.dat is modified through a temporary mounted registry hive.')
        $sideEffects.Add('No backup or Restore state is created because the Ultimate source does not define one.')
    }
    elseif ($toolId -eq 'notepad-settings' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Running Notepad is closed and unsaved Notepad work can be lost.')
        $sideEffects.Add('The exact current user Notepad settings.dat is deleted, so Notepad recreates default settings later.')
        $sideEffects.Add('No backup or Restore state is created because the Ultimate source does not define one.')
    }
    elseif ($toolId -eq 'control-panel-settings' -and ($ActionName -eq 'Apply' -or $ActionName -eq 'Default')) {
        $sideEffects.Add('Control Panel, Settings, privacy, security, accessibility, Explorer, sound, notification, app-action, scheduled task, service, process, and power settings may change exactly as the Ultimate source defines.')
        $sideEffects.Add('TrustedInstaller is used by the source helper for protected CapabilityAccessManager database cleanup.')
        $sideEffects.Add('No Restore action is exposed; Default is the separate source-defined Default branch, not captured-state restore.')
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
        $sideEffects.Add('Captured value state is retained for future review; Restore is not exposed.')
    }
    elseif ($toolId -eq 'write-cache-buffer-flushing' -and $ActionName -eq 'Default') {
        $sideEffects.Add('The complete source-discovered SCSI/NVME Disk registry keys are deleted exactly as defined by Ultimate.')
        $sideEffects.Add('This may remove storage write-cache configuration values inside those Disk keys.')
        $sideEffects.Add('No driver, service, device, file, process, download, installer, or reboot action is performed.')
        $sideEffects.Add('Captured key state is retained for future review; Restore is not exposed.')
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
    elseif ($toolId -eq 'cleanup' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Files and directories under the six exact Ultimate cleanup targets are permanently removed with Remove-Item -Force and no quarantine or Restore path.')
        $sideEffects.Add('Disk Cleanup opens through cleanmgr.exe after the removal attempts.')
        $sideEffects.Add('No registry, service, task, package, driver, download, installer, TrustedInstaller, Safe Mode, or reboot operation is performed.')
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
    elseif ($toolId -eq 'services-optimizer' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; source identity and workflow shape are reported only.')
        $sideEffects.Add('The source workflow is high risk because Apply and Default stage Safe Mode, RunOnce, BCD, TrustedInstaller, service registry imports, and restarts.')
    }
    elseif ($toolId -eq 'services-optimizer' -and $ActionName -in @('Apply', 'Default')) {
        $sideEffects.Add('Windows will be configured to boot into Safe Mode and restart immediately after staging.')
        $sideEffects.Add('The generated Safe Mode script temporarily reconfigures TrustedInstaller to import the source-defined service registry payload, also imports it as Administrator, removes safeboot, and restarts again.')
        $sideEffects.Add('Hundreds of service Start values are changed by the source-defined REG payload; this is not a smart analyzer, recommendation engine, or redesigned profile.')
        $sideEffects.Add('Default is the source-defined Services: Default preset, not captured-state Restore.')
    }
    elseif ($toolId -eq 'timer-resolution-assistant' -and $ActionName -eq 'Analyze') {
        $sideEffects.Add('No system changes are made; source identity, generated service payload shape, and source-defined operation targets are reported only.')
        $sideEffects.Add('The source workflow is high risk because Apply and Default write protected Windows files, create/delete a service, change a kernel timer registry value, compile generated C# code, and open Task Manager.')
    }
    elseif ($toolId -eq 'timer-resolution-assistant' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('A generated LocalSystem timer resolution service is compiled, installed, configured for automatic startup, and started.')
        $sideEffects.Add('The kernel GlobalTimerResolutionRequests value is set to REG_DWORD 1, and Task Manager is opened for source-defined verification.')
        $sideEffects.Add('No downloads, external artifacts, installers, reboots, Safe Mode, TrustedInstaller, driver changes, or Restore behavior are used.')
    }
    elseif ($toolId -eq 'timer-resolution-assistant' -and $ActionName -eq 'Default') {
        $sideEffects.Add('The source-defined service is disabled, stopped, deleted, and its generated executable is removed.')
        $sideEffects.Add('The kernel GlobalTimerResolutionRequests value is deleted, and Task Manager is opened for source-defined verification.')
        $sideEffects.Add('Default is not captured-state Restore; Restore remains unavailable for this tool.')
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
    if ($capabilities.RequiresInternet -and $toolId -notin @('installers')) {
        $sideEffects.Add('The requested action may fail when internet access is unavailable.')
    }
    if ($capabilities.CanReboot -and $ActionName -ne 'Analyze' -and -not $isBlockedDriverInstallLatestNoMutationAction -and -not ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Open') -and -not ($toolId -eq 'reinstall' -and $ActionName -eq 'Open')) {
        $sideEffects.Add('The computer may restart; unsaved work could be lost.')
    }
    if ($isPotentialChangeAction -and -not $isBlockedInstallersNoMutationAction -and -not $isBlockedDriverInstallLatestNoMutationAction -and -not $isBlockedDriverInstallDebloatSettingsNoMutationAction -and -not $isBlockedDirectXNoMutationAction -and -not $isBlockedVisualCppNoMutationAction -and -not $isBlockedReinstallNoMutationAction -and $capabilities.CanModifyServices) {
        $sideEffects.Add('Service changes may affect dependent Windows or application features.')
    }
    if ($isPotentialChangeAction -and -not $isBlockedInstallersNoMutationAction -and -not $isBlockedDriverInstallLatestNoMutationAction -and -not $isBlockedDirectXNoMutationAction -and -not $isBlockedVisualCppNoMutationAction -and -not $isBlockedReinstallNoMutationAction -and $capabilities.CanModifyDrivers) {
        $sideEffects.Add('Driver changes may affect display, devices, stability, or hardware availability.')
    }
    if ($isPotentialChangeAction -and -not $isBlockedBitLockerNoMutationAction -and -not $isBlockedInstallersNoMutationAction -and -not $isBlockedDriverInstallLatestNoMutationAction -and -not $isBlockedDirectXNoMutationAction -and -not $isBlockedVisualCppNoMutationAction -and -not $isBlockedReinstallNoMutationAction -and $capabilities.CanModifySecurity) {
        $sideEffects.Add('Security changes may alter system protection or compatibility.')
    }
    if ($isPotentialChangeAction -and -not $isBlockedInstallersNoMutationAction -and -not $isBlockedDriverInstallLatestNoMutationAction -and -not $isBlockedDirectXNoMutationAction -and -not $isBlockedVisualCppNoMutationAction -and -not $isBlockedReinstallNoMutationAction -and $capabilities.CanDeleteFiles) {
        $sideEffects.Add('Deleted files may not be recoverable unless an approved checkpoint exists.')
    }
    if ($isPotentialChangeAction -and -not $isBlockedInstallersNoMutationAction -and -not $isBlockedDriverInstallLatestNoMutationAction -and -not $isBlockedDirectXNoMutationAction -and -not $isBlockedVisualCppNoMutationAction -and -not $isBlockedReinstallNoMutationAction -and $capabilities.CanInstallSoftware) {
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
        'Driver Clean Manual will run the source-equivalent workflow: download 7-Zip and DDU, install/configure 7-Zip, extract/configure DDU, set driver-search policy, create ddumanual.ps1 and RunOnce, enable Safe Mode with bcdedit, and restart. Continue?'
    }
    elseif ($toolId -eq 'driver-clean' -and $ActionName -eq 'Apply') {
        'Driver Clean Auto will run the source-equivalent workflow: download 7-Zip and DDU, install/configure 7-Zip, extract/configure DDU, set driver-search policy, create ddu.ps1 and RunOnce, enable Safe Mode with bcdedit, restart, and then run DDU with -CleanSoundBlaster -CleanRealtek -CleanAllGpus -Restart. Continue?'
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Open') {
        'Driver Install Latest Open is INTEL-only: it may open the source-defined Intel Windows 11 graphics driver search page when INTEL is selected. NVIDIA and AMD Open report unavailable because their source behavior runs through Apply Source Workflow. Continue?'
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Apply') {
        'Driver Install Latest will run the selected NVIDIA, AMD, or INTEL source-equivalent latest-driver branch after confirmation. It may query vendor sources, download driver installers, launch installers or driver pages, and hand off to vendor driver behavior that can affect display/session/reboot state. Continue only if this exact selected branch should run.'
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Default') {
        'Driver Install Latest Default is unavailable because the source defines no Default branch. BoostLab will not mutate driver, installer, file, registry, process, reboot, or session state. Continue only to record the blocked result?'
    }
    elseif ($toolId -eq 'driver-install-latest' -and $ActionName -eq 'Restore') {
        'Driver Install Latest Restore is unavailable without approved selected captured driver/download/installer/session state. BoostLab will not mutate driver, installer, file, registry, process, reboot, or session state. Continue only to record the blocked result?'
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Open') {
        'BoostLab will open only the source-defined vendor driver page flow for the selected Driver Install Debloat & Settings branch. It will not download or install 7-Zip, run driver installers, extract or debloat files, import profiles, mutate registry/services/packages/drivers, open shared UI panels, or reboot from Open. Continue?'
    }
    elseif ($toolId -eq 'driver-install-debloat-settings' -and $ActionName -eq 'Apply') {
        'Driver Install Debloat & Settings will run the selected NVIDIA, AMD, or INTEL source-equivalent branch after confirmation. It may download tools, open vendor pages, run installers, delete source-defined driver components/files, modify packages/AppX/winget, write registry/profile settings, stop processes, remove services/drivers/tasks, open display/NVIDIA/sound interfaces, and restart. Continue only if this exact selected branch should run.'
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
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Apply') {
        'Edge & WebView will run the source-equivalent Uninstall (Recommended) branch: stop source-targeted processes, mutate DeviceRegion, remove EdgeUpdate registry keys, run Edge update/uninstall executables, run Edge uninstall, delete source-targeted files/folders/shortcut/services, and optionally run the source legacy Edge DISM branch if present. Continue?'
    }
    elseif ($toolId -eq 'edge-webview' -and $ActionName -eq 'Default') {
        'Edge & WebView will run the source-defined Default branch: stop source-targeted processes, download and launch source Edge/WebView repair executables, write Edge policy values, remove Active Setup and RunOnce Edge entries, delete Edge services/tasks, and delete source BHO keys. Default is not captured-state Restore. Continue?'
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Open') {
        'DirectX Open is unavailable because the source defines an install workflow, not a standalone Open action. Continue only to record the blocked Open result?'
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Apply') {
        'BoostLab will install/configure 7-Zip, download/extract the DirectX package, and launch DXSETUP using the source-defined order and URLs. Both downloads are Ultimate-author-hosted artifacts marked NeedsBoostLabMirror; no artifact approval or mirror substitution is created. No reboot is requested by BoostLab. Continue?'
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Default') {
        'DirectX Default is unavailable. The source does not define a safe Default branch, and Default is not Restore. Continue only to record the blocked Default result?'
    }
    elseif ($toolId -eq 'directx' -and $ActionName -eq 'Restore') {
        'DirectX Restore requires selected captured artifact, registry, shortcut, file, installer, and cleanup state plus an approved restore contract. BoostLab will fail closed because neither exists. Continue only to record the blocked Restore result?'
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Open') {
        'Visual C++ Open is unavailable because the source defines an install workflow, not a standalone Open action. Continue only to record the blocked Open result?'
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Apply') {
        'BoostLab will run the source-equivalent Visual C++ workflow: verify Administrator and internet access, download all twelve source-defined redistributable installers to %SystemRoot%\Temp from unchanged Ultimate author-hosted URLs, and run them sequentially with Start-Process -Wait and exact source switches. Artifacts remain NeedsBoostLabMirror; no artifact approval or mirror substitution is created, and no reboot is requested by BoostLab. Continue?'
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Default') {
        'Visual C++ Default is unavailable. The source does not define a safe Default branch, and Default is not Restore. Continue only to record the blocked Default result?'
    }
    elseif ($toolId -eq 'visual-cpp' -and $ActionName -eq 'Restore') {
        'Visual C++ Restore requires selected captured artifact, package, registry, temp-file, installer, and cleanup state plus an approved restore contract. BoostLab will fail closed because neither exists. Continue only to record the blocked Restore result?'
    }
    elseif ($toolId -eq 'bloatware' -and $ActionName -eq 'Apply') {
        'Bloatware will run exactly one selected source-equivalent Ultimate branch after confirmation. Depending on the selected branch it may remove or re-register AppX packages, remove Windows capabilities, disable optional features, stop/delete services, unregister tasks, stop processes, write/delete/import registry state and hives, change ownership/ACLs, delete protected files, download the source-defined Remote Desktop Connection or Snipping Tool EXEs, and run installers/uninstallers. No Default or Restore branch exists. Continue only if this selected branch should run.'
    }
    elseif ($toolId -eq 'game-bar' -and $ActionName -eq 'Apply') {
        'GameBar will run the source-defined Off (Recommended) branch: stop GameBar, remove all-users Gaming/Xbox AppX packages, stop GameInput service/processes, uninstall Microsoft GameInput when present, write/import gamebaroff.reg, and run the source TrustedInstaller PresenceWriter registry command. No download, repair installer, reboot, Safe Mode, or Restore runs. Continue?'
    }
    elseif ($toolId -eq 'game-bar' -and $ActionName -eq 'Default') {
        'GameBar will run the source-defined Default branch: write/import gamebaron.reg, run the source TrustedInstaller PresenceWriter registry command, re-register Gaming/Xbox/Store AppX packages, download edgewebview.exe and gamingrepairtool.exe from the Ultimate author-hosted URLs, and launch them. Default is not captured-state Restore. Continue?'
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
    elseif ($toolId -eq 'nvidia-settings' -and $ActionName -eq 'Apply') {
        'BoostLab will run the source-defined Nvidia Settings On (Recommended) branch: download/install 7-Zip, write 7-Zip options, clean 7-Zip Start Menu entries, unblock NVIDIA Drs files, write NVIDIA registry/profile settings, download and run NVIDIA Profile Inspector with the exact source .nip, and open NVIDIA Control Panel. No reboot, services, drivers, Safe Mode, TrustedInstaller, or unrelated Path B steps will run. Continue?'
    }
    elseif ($toolId -eq 'nvidia-settings' -and $ActionName -eq 'Default') {
        'BoostLab will run the source-defined Nvidia Settings Default branch: run the same 7-Zip prelude, delete/reset only the source-defined NVIDIA Settings registry/profile targets, download and run NVIDIA Profile Inspector with the exact source Default .nip, and open NVIDIA Control Panel. Default is not Restore. No reboot, services, drivers, Safe Mode, TrustedInstaller, or unrelated Path B steps will run. Continue?'
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
        'BoostLab will run the source-defined HDCP Off (Recommended) branch: set RMHdcpKeyglobZero to DWORD 1 on every non-Configuration display-class subkey returned by the source query, after source checksum validation and pre-change registry capture, then read the values back. No external process, download, driver change, or reboot will occur. Continue?'
    }
    elseif ($toolId -eq 'hdcp' -and $ActionName -eq 'Default') {
        'BoostLab will run the source-defined HDCP Default branch: set RMHdcpKeyglobZero to DWORD 0 on every non-Configuration display-class subkey returned by the source query, after source checksum validation and pre-change registry capture, then read the values back. Default is not Restore. No external process, download, driver change, or reboot will occur. Continue?'
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Apply') {
        'BoostLab will run the source-defined P0 State On (Recommended) branch: set DisableDynamicPstate to DWORD 1 on every non-Configuration display-class subkey returned by the source query, after source checksum validation and pre-change registry capture, then read the values back. No external process, download, driver change, or reboot will occur. Continue?'
    }
    elseif ($toolId -eq 'p0-state' -and $ActionName -eq 'Default') {
        'BoostLab will run the source-defined P0 State Default branch: set DisableDynamicPstate to DWORD 0 on every non-Configuration display-class subkey returned by the source query, after source checksum validation and pre-change registry capture, then read the values back. Default is not Restore. No external process, download, driver change, or reboot will occur. Continue?'
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Apply') {
        'BoostLab will run the source-defined Msi Mode On (Recommended) branch: set only MSISupported to DWORD 1 for every display device returned by Get-PnpDevice -Class Display with a usable InstanceId, after source checksum validation and pre-change registry capture. No external process, download, profile import, driver change, device restart, or reboot will occur. Continue?'
    }
    elseif ($toolId -eq 'msi-mode' -and $ActionName -eq 'Off') {
        'BoostLab will run the source-defined Msi Mode Off branch: set only MSISupported to DWORD 0 for every display device returned by Get-PnpDevice -Class Display with a usable InstanceId, after source checksum validation and pre-change registry capture. Off is not Default or Restore. No external process, download, profile import, driver change, device restart, or reboot will occur. Continue?'
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
    elseif ($toolId -eq 'copilot' -and $ActionName -eq 'Apply') {
        'BoostLab will run the approved source-equivalent Copilot Off branch: force-stop the source process list and *edge* process matches, remove AppX packages matching *Copilot*, and set HKCU/HKLM TurnOffWindowsCopilot to REG_DWORD 1. This can close apps and alter package/policy state. No download, installer, service, task, driver, file cleanup, or reboot is performed. Do you want to continue?'
    }
    elseif ($toolId -eq 'copilot' -and $ActionName -eq 'Default') {
        'BoostLab will run the approved source-equivalent Copilot Default branch: re-register AppX packages matching *Copilot* and delete the HKCU/HKLM WindowsCopilot policy keys. Default is not Restore. No download, installer, service, task, driver, file cleanup, or reboot is performed. Do you want to continue?'
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
        'BoostLab will restore the source Context Menu handlers and delete the complete Shell Extensions\Blocked key exactly as Ultimate defines, which can remove unrelated blocked shell-extension entries. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'signout-lockscreen-wallpaper-black' -and $ActionName -eq 'Apply') {
        'BoostLab will generate C:\Windows\Black.jpg, set the source-defined PersonalizationCSP and desktop wallpaper values, and request the source wallpaper refresh. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'signout-lockscreen-wallpaper-black' -and $ActionName -eq 'Default') {
        'BoostLab will delete the complete PersonalizationCSP key, set the approved default desktop wallpaper, request the source wallpaper refresh, and delete C:\Windows\Black.jpg exactly as Ultimate defines. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'notepad-settings' -and $ActionName -eq 'Apply') {
        'BoostLab will close Notepad, write notepadsettings.reg to Windows Temp, load settings.dat, import the three Ultimate values when load succeeds, unload the hive, and verify the result. No backup or Restore state is created. Unsaved Notepad work can be lost. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'notepad-settings' -and $ActionName -eq 'Default') {
        'BoostLab will close Notepad and run the source-defined delete action only against the exact Notepad settings.dat. No backup or Restore state is created. Unsaved Notepad work can be lost. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'control-panel-settings' -and $ActionName -eq 'Apply') {
        'BoostLab will run the exact Control Panel Settings Optimize branch after source checksum verification. This broad source branch can change registry, services, TrustedInstaller state, scheduled tasks, power settings, app-action state, processes, and source-defined files. No Restore is available. Do you want to continue?'
    }
    elseif ($toolId -eq 'control-panel-settings' -and $ActionName -eq 'Default') {
        'BoostLab will run the exact Control Panel Settings Default branch after source checksum verification. This broad source branch can change registry, services, TrustedInstaller state, scheduled tasks, power settings, app-action state, processes, and source-defined files. Default is not Restore. Do you want to continue?'
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
    elseif ($toolId -eq 'write-cache-buffer-flushing' -and $ActionName -eq 'Default') {
        'BoostLab will capture each source-discovered SCSI/NVME Disk registry key, delete the complete Disk key exactly as the Ultimate Default branch does, and verify each key is absent. No driver, service, device, file, process, download, installer, or reboot action is performed. Do you want to continue?'
    }
    elseif ($toolId -eq 'power-plan' -and $ActionName -eq 'Apply') {
        'BoostLab will activate the approved Ultimate scheme, permanently delete other enumerated power schemes, disable hibernation, apply 36 AC/DC setting pairs and 10 registry values, and set battery warnings/actions/levels to zero. Custom schemes are not captured and Default cannot restore them. No restart is performed. Do you want to continue?'
    }
    elseif ($toolId -eq 'power-plan' -and $ActionName -eq 'Default') {
        'BoostLab will run restoredefaultschemes, enable hibernation, restore the explicit Ultimate defaults, and delete the complete FlyoutMenuSettings and PowerThrottling keys. Previously deleted custom schemes will not be recovered. No restart is performed. Do you want to continue?'
    }
    elseif ($toolId -eq 'cleanup' -and $ActionName -eq 'Apply') {
        'BoostLab will permanently remove the exact Ultimate cleanup targets: user Temp contents, Windows Temp contents, inetpub, PerfLogs, Windows.old, and DumpStack.log, then launch cleanmgr.exe. There is no Default or Restore path and no quarantine. No registry, service, task, download, installer, or reboot operation is performed. Do you want to continue?'
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
        'BoostLab will apply the approved Ultimate MMAgent Default profile exactly as defined by the source: set EnablePrefetcher to 3, enable ApplicationLaunchPrefetching, ApplicationPreLaunch, and OperationAPI, set MaxOperationAPIFiles to 512, keep MemoryCompression and PageCombining disabled, and verify the result. No restart is performed. Do you want to continue?'
    }
    elseif ($toolId -eq 'services-optimizer' -and $ActionName -eq 'Apply') {
        'BoostLab will stage the exact Ultimate Services: Off workflow: write the generated Safe Mode script, set RunOnce, enable safeboot minimal, and request an immediate restart. The generated script changes service Start values through TrustedInstaller and Administrator REG imports, removes safeboot, and restarts again. Continue only with unsaved work closed and recovery plan understood.'
    }
    elseif ($toolId -eq 'services-optimizer' -and $ActionName -eq 'Default') {
        'BoostLab will stage the exact Ultimate Services: Default workflow: write the generated Safe Mode script, set RunOnce, enable safeboot minimal, and request an immediate restart. The generated script changes service Start values through TrustedInstaller and Administrator REG imports, removes safeboot, and restarts again. Continue only with unsaved work closed and recovery plan understood.'
    }
    elseif ($toolId -eq 'timer-resolution-assistant' -and $ActionName -eq 'Apply') {
        'BoostLab will run the exact Ultimate Timer Resolution: On workflow: write and compile the generated C# service under C:\Windows, create/start the Set Timer Resolution Service, set GlobalTimerResolutionRequests to REG_DWORD 1, and open Task Manager. No download, installer, reboot, Safe Mode, TrustedInstaller, or driver operation is used. Continue only if you approve these service, protected-file, registry, and process-launch changes.'
    }
    elseif ($toolId -eq 'timer-resolution-assistant' -and $ActionName -eq 'Default') {
        'BoostLab will run the exact Ultimate Timer Resolution: Default workflow: disable/stop/delete the Set Timer Resolution Service, delete C:\Windows\SetTimerResolutionService.exe, delete GlobalTimerResolutionRequests, and open Task Manager. This is Default, not captured-state Restore. Continue only if you approve these service, protected-file, registry, and process-launch changes.'
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
    elseif ($capabilities.RequiresAdmin -and -not $isReadOnlyAnalyzePrivilegeOverride) {
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
        RequiresAdmin             = if ($isProductScopeNotApplicable -or $isReadOnlyAnalyzePrivilegeOverride) { $false } else { [bool]$capabilities.RequiresAdmin }
        UsesTrustedInstaller      = [bool]$capabilities.UsesTrustedInstaller
        UsesSafeMode              = [bool]$capabilities.UsesSafeMode
        PrivilegeRequirements     = $privilegeRequirements.ToArray()
        RequiresInternet          = if ($isReadOnlyAnalyzePrivilegeOverride) { $false } else { [bool]$capabilities.RequiresInternet }
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
