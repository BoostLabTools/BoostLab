[CmdletBinding()]
param(
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $scriptPath = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $PSCommandPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $MyInvocation.MyCommand.Path
    }
    else {
        throw 'Unable to determine the validator script path.'
    }

    $scriptDirectory = Split-Path -Parent $scriptPath
    $ProjectRoot = Split-Path -Parent $scriptDirectory
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$placeholderPath = Join-Path $modulesRoot 'ToolModule.Placeholder.ps1'
$implementedModules = @{
    'bios-information' = @{
        RelativePath          = 'Check\BIOSInformation.psm1'
        LaunchText            = 'Start-Process $searchUrl'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Open'')'
    }
    'bios-settings' = @{
        RelativePath          = 'Check\BIOSSettings.psm1'
        LaunchText            = '& $commandProcessorPath @firmwareRestartArguments'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Open'')'
    }
    'to-bios' = @{
        RelativePath          = 'Refresh\to-bios.psm1'
        LaunchText            = '& $commandProcessorPath @firmwareRestartArguments'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Open'')'
    }
    'unattended' = @{
        RelativePath          = 'Refresh\unattended.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'')'
    }
    'reinstall' = @{
        RelativePath          = 'Refresh\reinstall.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Open'', ''Apply'', ''Default'', ''Restore'')'
    }
    'updates-drivers-block' = @{
        RelativePath          = 'Refresh\updates-drivers-block.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'', ''Restore'')'
    }
    'edge-settings' = @{
        RelativePath          = 'Setup\edge-settings.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'', ''Restore'')'
    }
    'startup-apps-settings' = @{
        RelativePath          = 'Setup\StartupAppsSettings.psm1'
        LaunchText            = 'Start-Process "ms-settings:startupapps"'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Open'')'
    }
    'startup-apps-task-manager' = @{
        RelativePath          = 'Setup\StartupAppsTaskManager.psm1'
        LaunchText            = 'Start-Process "taskmgr" -ArgumentList " /0 /startup"'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Open'')'
    }
    'memory-compression' = @{
        RelativePath          = 'Setup\MemoryCompression.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    'bitlocker' = @{
        RelativePath          = 'Setup\bitlocker.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'', ''Restore'', ''Open'')'
    }
    'spectre-meltdown-assistant' = @{
        RelativePath          = 'Advanced\spectre-meltdown-assistant.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
    }
    'mmagent-assistant' = @{
        RelativePath          = 'Advanced\mmagent-assistant.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
    }
    'services-optimizer' = @{
        RelativePath          = 'Advanced\services-optimizer.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
    }
    'timer-resolution-assistant' = @{
        RelativePath          = 'Advanced\timer-resolution-assistant.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
    }
    'defender-optimize-assistant' = @{
        RelativePath          = 'Advanced\defender-optimize-assistant.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
    }
    'background-apps' = @{
        RelativePath          = 'Setup\BackgroundApps.psm1'
        LaunchText            = 'Start-Process ms-settings:privacy-backgroundapps -ErrorAction Stop'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    'store-settings' = @{
        RelativePath          = 'Setup\StoreSettings.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    'updates-pause' = @{
        RelativePath          = 'Setup\UpdatesPause.psm1'
        LaunchText            = 'Start-Process ms-settings:windowsupdate -ErrorAction Stop'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    'installers' = @{
        RelativePath          = 'Installers\installers.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Open'', ''Apply'', ''Default'', ''Restore'')'
    }
    'edge-webview' = @{
        RelativePath          = 'Windows\edge-webview.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    'game-bar' = @{
        RelativePath          = 'Windows\game-bar.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    'bloatware' = @{
        RelativePath          = 'Windows\bloatware.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'')'
    }
    'driver-clean' = @{
        RelativePath          = 'Graphics\driver-clean.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Open'', ''Apply'')'
    }
    'driver-install-latest' = @{
        RelativePath          = 'Graphics\driver-install-latest.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Open'', ''Apply'', ''Default'', ''Restore'')'
    }
    'driver-install-debloat-settings' = @{
        RelativePath          = 'Graphics\driver-install-debloat-settings.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Open'', ''Apply'', ''Default'', ''Restore'')'
    }
    'directx' = @{
        RelativePath          = 'Graphics\directx.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'')'
    }
    'visual-cpp' = @{
        RelativePath          = 'Graphics\visual-cpp.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'')'
    }
    'nvidia-settings' = @{
        RelativePath          = 'Graphics\nvidia-settings.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
    }
    'hdcp' = @{
        RelativePath          = 'Graphics\hdcp.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
    }
    'p0-state' = @{
        RelativePath          = 'Graphics\p0-state.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
    }
    'msi-mode' = @{
        RelativePath          = 'Graphics\msi-mode.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Off'')'
    }
    'graphics-configuration-center' = @{
        RelativePath          = 'Graphics\GraphicsConfigurationCenter.psm1'
        LaunchText            = 'Start-Process "ms-settings:display-advancedgraphics"'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Open'')'
    }
    'date-language-region-time' = @{
        RelativePath          = 'Setup\date-language-region-time.psm1'
        LaunchText            = 'Start-Process "ms-settings:dateandtime"'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Open'')'
    }
    'game-mode' = @{
        RelativePath          = 'Windows\game-mode.psm1'
        LaunchText            = 'Start-Process "ms-settings:gaming-gamemode"'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Open'')'
    }
    'pointer-precision' = @{
        RelativePath          = 'Windows\pointer-precision.psm1'
        LaunchText            = 'Start-Process "control.exe" -ArgumentList "main.cpl ,2"'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Open'')'
    }
    'sound' = @{
        RelativePath          = 'Windows\sound.psm1'
        LaunchText            = 'Start-Process "mmsys.cpl"'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Open'')'
    }
    'widgets' = @{
        RelativePath          = 'Windows\Widgets.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    'copilot' = @{
        RelativePath          = 'Windows\copilot.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    'restore-point' = @{
        RelativePath          = 'Windows\RestorePoint.psm1'
        LaunchText            = 'Start-Process "$env:SystemRoot\system32\control.exe" -ArgumentList "sysdm.cpl,,4"'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Apply'', ''Open'')'
    }
    'theme-black' = @{
        RelativePath          = 'Windows\ThemeBlack.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    'start-menu-layout' = @{
        RelativePath          = 'Windows\StartMenuLayout.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    'context-menu' = @{
        RelativePath          = 'Windows\ContextMenu.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    'signout-lockscreen-wallpaper-black' = @{
        RelativePath          = 'Windows\SignoutLockScreenWallpaperBlack.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    'user-account-pictures-black' = @{
        RelativePath          = 'Windows\user-account-pictures-black.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    'device-manager-power-savings-wake' = @{
        RelativePath          = 'Windows\device-manager-power-savings-wake.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    'network-adapter-power-savings-wake' = @{
        RelativePath          = 'Windows\NetworkAdapterPowerSavingsWake.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    'write-cache-buffer-flushing' = @{
        RelativePath          = 'Windows\write-cache-buffer-flushing.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
    }
    'power-plan' = @{
        RelativePath          = 'Windows\PowerPlan.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    'cleanup' = @{
        RelativePath          = 'Windows\cleanup.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Apply'')'
    }
    'game-configs' = @{
        RelativePath          = 'GameConfigs\game-configs.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Apply'')'
    }
    'notepad-settings' = @{
        RelativePath          = 'Windows\notepad-settings.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    'control-panel-settings' = @{
        RelativePath          = 'Windows\control-panel-settings.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    'start-menu-taskbar' = @{
        RelativePath          = 'Windows\start-menu-taskbar.psm1'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
}
$requiredFunctions = @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
$deletedToolNames = @(
    'Windows Activation Helper'
    'Firewall'
    'DEP'
    'File Download Security Warning'
    'MPO'
    'FSO'
    'FSE'
    'Hardware Flip'
    'AMD ULPS'
    'WHQL Secure Boot Bypass'
    'Keyboard Shortcuts'
    'Search Shell Mobsync'
    'NVME Faster Driver'
    'Core 1 Thread 1'
    'DDU'
    'UAC'
    'Scaling'
    'Start Menu Shortcuts'
    'Loudness EQ'
)
$prohibitedCommands = @(
    'Set-ItemProperty'
    'New-ItemProperty'
    'Remove-ItemProperty'
    'Remove-Item'
    'Set-Content'
    'Add-Content'
    'Out-File'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'Restart-Computer'
    'Stop-Computer'
    'Checkpoint-Computer'
    'Enable-ComputerRestore'
    'Disable-ComputerRestore'
    'Invoke-Expression'
)
$errors = [System.Collections.Generic.List[string]]::new()

if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    throw "Stage configuration was not found: $configPath"
}
if (-not (Test-Path -LiteralPath $placeholderPath -PathType Leaf)) {
    throw "Shared placeholder implementation was not found: $placeholderPath"
}

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$stages = @($configuration['Stages'] | Sort-Object { [int]$_['Order'] })
$expectedModules = [ordered]@{}

foreach ($stage in $stages) {
    foreach ($tool in @($stage['Tools'] | Sort-Object { [int]$_['Order'] })) {
        $toolId = [string]$tool['Id']
        $relativePath = if ($implementedModules.ContainsKey($toolId)) {
            [string]$implementedModules[$toolId].RelativePath
        }
        else {
            Join-Path ([string]$stage['Name']) ("{0}.psm1" -f $toolId)
        }
        $fullPath = Join-Path $modulesRoot $relativePath
        $expectedModules[$fullPath.ToLowerInvariant()] = @{
            Path = $fullPath
            Tool = $tool
        }
    }
}

$actualModules = @(
    Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1' |
        Where-Object { $_.Directory.Parent.FullName -eq $modulesRoot }
)
$actualModuleLookup = @{}
foreach ($module in $actualModules) {
    $actualModuleLookup[$module.FullName.ToLowerInvariant()] = $module
}

foreach ($expectedKey in $expectedModules.Keys) {
    if (-not $actualModuleLookup.ContainsKey($expectedKey)) {
        $errors.Add("Missing module: $($expectedModules[$expectedKey].Path)")
    }
}

foreach ($actualKey in $actualModuleLookup.Keys) {
    if (-not $expectedModules.Contains($actualKey)) {
        $errors.Add("Unexpected module: $($actualModuleLookup[$actualKey].FullName)")
    }
}

$placeholderTokens = $null
$placeholderParseErrors = $null
$placeholderAst = [System.Management.Automation.Language.Parser]::ParseFile(
    $placeholderPath,
    [ref]$placeholderTokens,
    [ref]$placeholderParseErrors
)
foreach ($parseError in @($placeholderParseErrors)) {
    $errors.Add("Placeholder syntax error: $($parseError.Message)")
}

$placeholderFunctions = @(
    $placeholderAst.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] },
        $true
    ) | ForEach-Object { $_.Name }
)
foreach ($functionName in $requiredFunctions) {
    if ($functionName -notin $placeholderFunctions) {
        $errors.Add("Shared placeholder is missing function: $functionName")
    }
}

foreach ($entry in $expectedModules.Values) {
    $modulePath = [string]$entry.Path
    if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
        continue
    }

    $tool = $entry.Tool
    $source = Get-Content -Raw -LiteralPath $modulePath
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $modulePath,
        [ref]$tokens,
        [ref]$parseErrors
    )
    foreach ($parseError in @($parseErrors)) {
        $errors.Add("$modulePath syntax error: $($parseError.Message)")
    }

    $metadataChecks = [ordered]@{
        Id          = "Id = '$($tool['Id'])'"
        Title       = "Title = '$($tool['Title'])'"
        Stage       = "Stage = '$($tool['Stage'])'"
        Order       = "Order = $([int]$tool['Order'])"
        Type        = "Type = '$($tool['Type'])'"
        RiskLevel   = "RiskLevel = '$($tool['RiskLevel'])'"
        Description = "Description = '$($tool['Description'])'"
        Actions     = "Actions = @($((@($tool['Actions']) | ForEach-Object { "'$_'" }) -join ', '))"
    }
    foreach ($field in $metadataChecks.Keys) {
        if (-not $source.Contains([string]$metadataChecks[$field])) {
            $errors.Add("$modulePath metadata mismatch: $field")
        }
    }

    foreach ($functionName in $requiredFunctions) {
        if (-not $source.Contains("'$functionName'")) {
            $errors.Add("$modulePath does not export $functionName.")
        }
    }

    $commands = @(
        $ast.FindAll(
            { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
            $true
        ) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }
    )
    $toolId = [string]$tool['Id']
    foreach ($commandName in $commands) {
        $approvedRestorePointCommand = (
            $toolId -eq 'restore-point' -and
            $commandName -in @('Checkpoint-Computer', 'Enable-ComputerRestore')
        )
        $approvedStoreSettingsCommand = (
            $toolId -eq 'store-settings' -and
            $commandName -eq 'Set-Content'
        )
        $approvedUpdatesPauseCommand = (
            $toolId -eq 'updates-pause' -and
            $commandName -in @('Set-ItemProperty', 'Remove-ItemProperty')
        )
        $approvedThemeBlackCommand = (
            $toolId -eq 'theme-black' -and
            $commandName -eq 'Set-Content'
        )
        $approvedStartMenuLayoutCommand = (
            $toolId -eq 'start-menu-layout' -and
            $commandName -eq 'Set-Content'
        )
        $approvedContextMenuCommand = (
            $toolId -eq 'context-menu' -and
            $commandName -eq 'Set-Content'
        )
        $approvedNotepadSettingsCommand = (
            $toolId -eq 'notepad-settings' -and
            $commandName -in @('Set-Content', 'Remove-Item')
        )
        $approvedUnattendedCommand = (
            $toolId -eq 'unattended' -and
            $commandName -in @('Set-Content', 'Remove-Item')
        )
        $approvedWriteCacheCommand = (
            $toolId -eq 'write-cache-buffer-flushing' -and
            $commandName -eq 'New-ItemProperty'
        )
        $approvedHdcpCommand = (
            $toolId -eq 'hdcp' -and
            $commandName -eq 'New-ItemProperty'
        )
        $approvedP0StateCommand = (
            $toolId -eq 'p0-state' -and
            $commandName -eq 'New-ItemProperty'
        )
        $approvedMsiModeCommand = (
            $toolId -eq 'msi-mode' -and
            $commandName -in @('New-Item', 'New-ItemProperty')
        )
        $approvedUpdatesDriversBlockCommand = (
            $toolId -eq 'updates-drivers-block' -and
            $commandName -in @('New-ItemProperty', 'Remove-ItemProperty')
        )
        $approvedReinstallCommand = (
            $toolId -eq 'reinstall' -and
            $commandName -eq 'Invoke-WebRequest'
        )
        $approvedEdgeSettingsCommand = (
            $toolId -eq 'edge-settings' -and
            $commandName -in @('New-ItemProperty', 'Remove-Item', 'Remove-ItemProperty', 'Invoke-WebRequest')
        )
        $approvedEdgeWebViewCommand = (
            $toolId -eq 'edge-webview' -and
            $commandName -in @('Invoke-WebRequest', 'Remove-Item', 'Remove-ItemProperty')
        )
        $approvedInstallersCommand = (
            $toolId -eq 'installers' -and
            $commandName -in @('Invoke-WebRequest', 'Set-Content', 'New-ItemProperty', 'Remove-ItemProperty', 'Remove-Item')
        )
        $approvedDriverCleanCommand = (
            $toolId -eq 'driver-clean' -and
            $commandName -in @('Invoke-WebRequest', 'Remove-Item', 'Set-Content', 'Set-ItemProperty')
        )
        $approvedDriverInstallLatestCommand = (
            $toolId -eq 'driver-install-latest' -and
            $commandName -eq 'Invoke-WebRequest'
        )
        $approvedDriverInstallDebloatSettingsCommand = (
            $toolId -eq 'driver-install-debloat-settings' -and
            $commandName -in @('Invoke-WebRequest', 'Remove-Item', 'Set-Content', 'Set-ItemProperty')
        )
        $approvedNvidiaSettingsCommand = (
            $toolId -eq 'nvidia-settings' -and
            $commandName -in @('Invoke-WebRequest', 'New-ItemProperty', 'Remove-ItemProperty', 'Remove-Item', 'Set-Content')
        )
        $approvedDirectXCommand = (
            $toolId -eq 'directx' -and
            $commandName -in @('Invoke-WebRequest', 'New-ItemProperty', 'Remove-Item')
        )
        $approvedVisualCppCommand = (
            $toolId -eq 'visual-cpp' -and
            $commandName -eq 'Invoke-WebRequest'
        )
        $approvedBloatwareCommand = (
            $toolId -eq 'bloatware' -and
            $commandName -in @('Invoke-WebRequest', 'Remove-Item', 'Set-Content')
        )
        $approvedGameBarCommand = (
            $toolId -eq 'game-bar' -and
            $commandName -in @('Invoke-WebRequest', 'Set-Content')
        )
        $approvedStartMenuTaskbarCommand = (
            $toolId -eq 'start-menu-taskbar' -and
            $commandName -in @('New-ItemProperty', 'Remove-ItemProperty', 'Remove-Item', 'Set-Content')
        )
        $approvedSignoutWallpaperCommand = (
            $toolId -eq 'signout-lockscreen-wallpaper-black' -and
            $commandName -eq 'Remove-Item'
        )
        $approvedCleanupCommand = (
            $toolId -eq 'cleanup' -and
            $commandName -eq 'Remove-Item'
        )
        $approvedServicesOptimizerCommand = (
            $toolId -eq 'services-optimizer' -and
            $commandName -in @('Set-Content', 'Enable-ComputerRestore', 'Checkpoint-Computer')
        )
        $approvedTimerResolutionCommand = (
            $toolId -eq 'timer-resolution-assistant' -and
            $commandName -in @('Set-Content', 'Remove-Item')
        )
        $approvedDefenderOptimizeCommand = (
            $toolId -eq 'defender-optimize-assistant' -and
            $commandName -eq 'Set-Content'
        )
        $approvedGameConfigsCommand = (
            $toolId -eq 'game-configs' -and
            $commandName -in @('Copy-Item', 'Expand-Archive', 'Invoke-WebRequest', 'Move-Item', 'New-Item', 'Remove-Item', 'Start-Sleep', 'Unblock-File')
        )
        if (
            $commandName -in $prohibitedCommands -and
            -not $approvedRestorePointCommand -and
            -not $approvedStoreSettingsCommand -and
            -not $approvedUpdatesPauseCommand -and
            -not $approvedThemeBlackCommand -and
            -not $approvedStartMenuLayoutCommand -and
            -not $approvedContextMenuCommand -and
            -not $approvedNotepadSettingsCommand -and
            -not $approvedUnattendedCommand -and
            -not $approvedWriteCacheCommand -and
            -not $approvedHdcpCommand -and
            -not $approvedP0StateCommand -and
            -not $approvedMsiModeCommand -and
            -not $approvedUpdatesDriversBlockCommand -and
            -not $approvedReinstallCommand -and
            -not $approvedEdgeSettingsCommand -and
            -not $approvedEdgeWebViewCommand -and
            -not $approvedInstallersCommand -and
            -not $approvedDriverCleanCommand -and
            -not $approvedDriverInstallLatestCommand -and
            -not $approvedDriverInstallDebloatSettingsCommand -and
            -not $approvedNvidiaSettingsCommand -and
            -not $approvedDirectXCommand -and
            -not $approvedVisualCppCommand -and
            -not $approvedBloatwareCommand -and
            -not $approvedGameBarCommand -and
            -not $approvedStartMenuTaskbarCommand -and
            -not $approvedSignoutWallpaperCommand -and
            -not $approvedCleanupCommand -and
            -not $approvedServicesOptimizerCommand -and
            -not $approvedTimerResolutionCommand -and
            -not $approvedDefenderOptimizeCommand -and
            -not $approvedGameConfigsCommand
        ) {
            $errors.Add("$modulePath contains prohibited command: $commandName")
        }
    }

    if ($implementedModules.ContainsKey($toolId)) {
        if ($source.Contains('ToolModule.Placeholder.ps1')) {
            $errors.Add("$modulePath must not use the shared placeholder implementation.")
        }
        if (-not $source.Contains([string]$implementedModules[$toolId].ImplementedActionsText)) {
            $errors.Add("$modulePath does not declare the approved implemented actions.")
        }
        if (
            $implementedModules[$toolId].ContainsKey('LaunchText') -and
            -not $source.Contains([string]$implementedModules[$toolId].LaunchText)
        ) {
            $errors.Add("$modulePath does not preserve the approved Start-Process behavior.")
        }

        $expectedStartProcessCount = if ($toolId -in @('bios-settings', 'to-bios')) {
            0
        }
        elseif ($toolId -eq 'restore-point') {
            2
        }
        elseif ($toolId -eq 'widgets') {
            0
        }
        elseif ($toolId -eq 'copilot') {
            0
        }
        elseif ($toolId -eq 'memory-compression') {
            0
        }
        elseif ($toolId -eq 'bitlocker') {
            1
        }
        elseif ($toolId -eq 'spectre-meltdown-assistant') {
            0
        }
        elseif ($toolId -eq 'mmagent-assistant') {
            0
        }
        elseif ($toolId -eq 'services-optimizer') {
            0
        }
        elseif ($toolId -eq 'timer-resolution-assistant') {
            1
        }
        elseif ($toolId -eq 'defender-optimize-assistant') {
            0
        }
        elseif ($toolId -eq 'store-settings') {
            2
        }
        elseif ($toolId -eq 'driver-clean') {
            1
        }
        elseif ($toolId -eq 'driver-install-latest') {
            1
        }
        elseif ($toolId -eq 'installers') {
            2
        }
        elseif ($toolId -eq 'driver-install-debloat-settings') {
            4
        }
        elseif ($toolId -eq 'directx') {
            3
        }
        elseif ($toolId -eq 'visual-cpp') {
            1
        }
        elseif ($toolId -eq 'bloatware') {
            3
        }
        elseif ($toolId -eq 'game-bar') {
            3
        }
        elseif ($toolId -eq 'edge-webview') {
            4
        }
        elseif ($toolId -eq 'reinstall') {
            1
        }
        elseif ($toolId -eq 'nvidia-settings') {
            1
        }
        elseif ($toolId -eq 'nvidia-settings') {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
                '903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5'
                '$script:BoostLabSevenZipUrl'
                '$script:BoostLabInspectorUrl'
                'Get-BoostLabNvidiaSettingsSourceNipPayloads'
                'NvCplPhysxAuto'
                'NvDevToolsVisible'
                'RmProfilingAdminOnly'
                'StartOnLogin'
                'EnableGR535'
                'OpenUnavailable'
                'RestoreUnavailable'
                'On (Recommended)'
                'source defines On and Default branches, not captured-state Restore'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing Nvidia Settings source-equivalent behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'ManualHandoffOnly'
                'Manual Handoff'
                'Apply Auto'
                'AutoBlockedUntilArtifactApproval'
                'RestoreSupported = $true'
                'UsesTrustedInstaller = $true'
                'UsesSafeMode = $true'
                'Restart-Computer'
                'Stop-Computer'
                'bcdedit'
                'Set-Service'
                'Stop-Service'
                'Restart-Service'
                'Remove-AppxPackage'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains unrelated or stale Nvidia Settings behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'hdcp') {
            0
        }
        elseif ($toolId -eq 'theme-black') {
            1
        }
        elseif ($toolId -eq 'start-menu-layout') {
            1
        }
        elseif ($toolId -eq 'context-menu') {
            1
        }
        elseif ($toolId -eq 'signout-lockscreen-wallpaper-black') {
            0
        }
        elseif ($toolId -eq 'user-account-pictures-black') {
            0
        }
        elseif ($toolId -eq 'device-manager-power-savings-wake') {
            0
        }
        elseif ($toolId -eq 'network-adapter-power-savings-wake') {
            0
        }
        elseif ($toolId -eq 'write-cache-buffer-flushing') {
            0
        }
        elseif ($toolId -eq 'p0-state') {
            0
        }
        elseif ($toolId -eq 'msi-mode') {
            0
        }
        elseif ($toolId -eq 'updates-drivers-block') {
            0
        }
        elseif ($toolId -eq 'power-plan') {
            1
        }
        elseif ($toolId -eq 'notepad-settings') {
            0
        }
        elseif ($toolId -eq 'control-panel-settings') {
            0
        }
        elseif ($toolId -eq 'start-menu-taskbar') {
            0
        }
        elseif ($toolId -eq 'game-configs') {
            2
        }
        else {
            1
        }
        $startProcessCount = @($commands | Where-Object { $_ -eq 'Start-Process' }).Count
        if ($startProcessCount -ne $expectedStartProcessCount) {
            $errors.Add("$modulePath must contain exactly $expectedStartProcessCount Start-Process command(s).")
        }

        if ($toolId -eq 'game-bar') {
            foreach ($requiredText in @(
                '$script:BoostLabExpectedSourceHash = ''8C6703E68C251D63ADD81A87B7CB6C1F572A4CE55A1E092C33B9B444A9884E59'''
                'Get-BoostLabGameBarOperationPlan'
                'Invoke-BoostLabGameBarBranchWorkflow'
                'Invoke-BoostLabGameBarTrustedInstallerCommand'
                'Get-AppXPackage -AllUsers'
                'Remove-AppxPackage'
                'Add-AppxPackage'
                'GameInputSvc'
                'Microsoft GameInput'
                'msiexec.exe'
                'gamebaroff.reg'
                'gamebaron.reg'
                'GameDVR_Enabled'
                'AppCaptureEnabled'
                'UseNexusForGameBarEnabled'
                'GamepadNexusChordEnabled'
                'ms-gamebar'
                'ms-gamebarservices'
                'ms-gamingoverlay'
                'PresenceServer.Internal.PresenceWriter'
                'edgewebview.exe'
                'gamingrepairtool.exe'
                'UltimateAuthorHostedArtifact'
                'NeedsBoostLabMirror = $true'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing GameBar source-equivalent behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'ToolModule.Placeholder.ps1'
                'ManualHandoffOnly'
                'AutoBlockedUntilArtifactApproval'
                'RestoreSupported = $true'
                'UsesSafeMode = $true'
                'Restart-Computer'
                'Stop-Computer'
                'bcdedit'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains stale or unrelated GameBar behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'bios-information') {
            foreach ($requiredText in @(
                'Get-CimInstance'
                '[System.Uri]::EscapeDataString'
                'https://www.google.com/search?q='
                'Confirm-SecureBootUEFI'
                'Get-Tpm'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing BIOS information safety behavior: $requiredText")
                }
            }
        }
        elseif ($toolId -eq 'updates-pause') {
            foreach ($requiredText in @(
                '$script:BoostLabUpdatesPauseRegistryPath = ''HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'''
                'PauseUpdatesExpiryTime'
                'PauseFeatureUpdatesEndTime'
                'PauseFeatureUpdatesStartTime'
                'PauseQualityUpdatesEndTime'
                'PauseQualityUpdatesStartTime'
                'PauseUpdatesStartTime'
                '.AddDays(365).ToUniversalTime().ToString(''yyyy-MM-ddTHH:mm:ssZ'')'
                'Set-ItemProperty'
                'Remove-ItemProperty'
                'Start-Process ms-settings:windowsupdate -ErrorAction Stop'
                'function Test-BoostLabUpdatesPauseState'
                'New-BoostLabVerificationResult'
                '-VerificationResult $verificationResult'
                '[bool]$Confirmed = $false'
                'Windows updates paused for 365 days.'
                'Windows Update pause values restored to default.'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing Updates Pause behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Restart-Service'
                'Stop-Process'
                'UsesTrustedInstaller = $true'
                'safeboot'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains unrelated Updates Pause behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'spectre-meltdown-assistant') {
            foreach ($requiredText in @(
                'HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\Memory Management'
                'FeatureSettingsOverrideMask'
                'FeatureSettingsOverride'
                '/t REG_DWORD /d "3" /f'
                'function Test-BoostLabSpectreMeltdownState'
                'function New-BoostLabSpectreVerificationResult'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing Spectre / Meltdown preserved behavior: $requiredText")
                }
            }
        }
        elseif ($toolId -eq 'notepad-settings') {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
                '$script:BoostLabNotepadProcessName = ''Notepad'''
                'Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings\settings.dat'
                'notepadsettings.reg'
                '"OpenFile"=hex(5f5e104):01,00,00,00,d1,55,24,57,d1,84,db,01'
                '"GhostFile"=hex(5f5e10b):00,42,60,f1,5a,d1,84,db,01'
                '"RewriteEnabled"=hex(5f5e10b):00,12,4a,7f,5f,d1,84,db,01'
                'Stop-Process -Name $script:BoostLabNotepadProcessName -Force -ErrorAction SilentlyContinue'
                'if ($null -ne $loadResult -and [bool]$loadResult.Success)'
                'Remove-Item -LiteralPath $Path -Force -ErrorAction Stop'
                'Invoke-BoostLabNotepadRegistryCommand'
                'New-BoostLabVerificationResult'
                '[bool]$Confirmed = $false'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing Notepad Settings behavior: $requiredText")
                }
            }
        }
        elseif ($toolId -eq 'theme-black') {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
                'blacktheme.reg'
                'defaulttheme.reg'
                'Set-Content -Path $Path -Value $Content -Force -ErrorAction Stop'
                'Start-Process'
                '"regedit.exe"'
                '-ArgumentList "/S `"$Path`""'
                'function Test-BoostLabThemeBlackState'
                'New-BoostLabVerificationResult'
                '-VerificationResult $verificationResult'
                '[bool]$Confirmed = $false'
                'Black theme applied.'
                'Theme restored to default.'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing Theme Black behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Restart-Service'
                'Stop-Process'
                'Remove-AppxPackage'
                'UsesTrustedInstaller = $true'
                'safeboot'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains unrelated Theme Black behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'start-menu-layout') {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
                'newstartmenu.reg'
                'oldstartmenu.reg'
                '"EnabledState"=dword:00000002'
                '"EnabledState"=-'
                '"AllAppsViewMode"=dword:00000002'
                '"AllAppsViewMode"=dword:00000000'
                'Set-Content -Path $Path -Value $Content -Force -ErrorAction Stop'
                '"regedit.exe"'
                '-ArgumentList "/S `"$Path`""'
                'function Test-BoostLabStartMenuLayoutState'
                'New-BoostLabVerificationResult'
                '-VerificationResult $verificationResult'
                '[bool]$Confirmed = $false'
                'Start Menu 25H2 layout applied.'
                'Start Menu 24H2 layout restored as default.'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing Start Menu Layout behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Restart-Service'
                'Stop-Process'
                'Remove-AppxPackage'
                'Remove-Item'
                'UsesTrustedInstaller = $true'
                'safeboot'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains unrelated Start Menu Layout behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'context-menu') {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
                'contextmenudefault.reg'
                '$script:BoostLabOwnedBlockedGuids'
                'ScanWithDefender'
                'ImportDefaultFile'
                'Set-Content -Path $Path -Value $Content -Force -ErrorAction Stop'
                '"regedit.exe"'
                '-ArgumentList "/S `"$Path`""'
                'function Test-BoostLabContextMenuState'
                'New-BoostLabVerificationResult'
                '-VerificationResult $verificationResult'
                '[bool]$Confirmed = $false'
                'Clean context menu applied.'
                'Context menu restored to the approved default.'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing Context Menu behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Restart-Service'
                'Stop-Process'
                'Remove-AppxPackage'
                'UsesTrustedInstaller = $true'
                'safeboot'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains unrelated Context Menu behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'signout-lockscreen-wallpaper-black') {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
                'C:\Windows\Black.jpg'
                'C:\Windows\Web\Wallpaper\Windows\img0.jpg'
                'LockScreenImagePath'
                'LockScreenImageStatus'
                'UpdatePerUserSystemParameters'
                'reg add'
                'reg delete'
                'DeleteKey'
                'Remove-Item -Recurse -Force $Path'
                'function Test-BoostLabSignoutWallpaperState'
                'New-BoostLabVerificationResult'
                'VerificationResult'
                '[bool] $Confirmed = $false'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing Signout LockScreen Wallpaper Black behavior: $requiredText")
                }
            }

            if (
                $source -notmatch
                    'reg delete\s+["'']\{0\}["'']\s+/f'
            ) {
                $errors.Add("$modulePath is missing the source-defined complete PersonalizationCSP key deletion.")
            }

            foreach ($forbiddenText in @(
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Restart-Service'
                'Stop-Process'
                'Remove-AppxPackage'
                'UsesTrustedInstaller = $true'
                'safeboot'
                'Backup-BoostLabWallpaperFile'
                'Restore-BoostLabWallpaperBackup'
                'Remove-BoostLabOwnedWallpaperFile'
                'signout-lockscreen-wallpaper-black.json'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains unrelated Signout LockScreen Wallpaper Black behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'user-account-pictures-black') {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
                'Microsoft\User Account Pictures'
                '$script:BoostLabApprovedExtensions = @(''.png'', ''.bmp'')'
                'System.Drawing.Bitmap'
                'System.Drawing.Graphics'
                'System.Drawing.Color]::Black'
                'Copy-BoostLabUltimateAccountPictureBackup'
                'Set-BoostLabAccountPictureBlack'
                'Copy-BoostLabUltimateAccountPictureDefault'
                'Get-ChildItem -Path $TargetRoot -Include *.png,*.bmp -Recurse'
                'New-BoostLabVerificationResult'
                'VerificationResult'
                '[bool]$Confirmed = $false'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing User Account Pictures Black behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Restart-Service'
                'Stop-Process'
                'Remove-AppxPackage'
                'UsesTrustedInstaller = $true'
                'safeboot'
                'source-ultimate'
                'user-account-pictures-black.json'
                'LeftIntactUnknownOwnership'
                'Restore-BoostLabAccountPictureBackup'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains unrelated User Account Pictures Black behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'device-manager-power-savings-wake') {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
                '$script:BoostLabDeviceClasses = @(''ACPI'', ''HID'', ''PCI'', ''USB'')'
                'EnhancedPowerManagementEnabled'
                'SeleactiveSuspendEnabled'
                'SelectiveSuspendEnabled'
                'SelectiveSuspendOn'
                'IdleInWorkingState'
                'WaitWakeEnabled'
                'function Test-BoostLabDeviceManagerRegistryTarget'
                'function Test-BoostLabDeviceManagerPowerWakeState'
                'New-BoostLabVerificationResult'
                '-VerificationResult $verificationResult'
                '[bool]$Confirmed = $false'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing Device Manager Power Savings & Wake behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'Disable-PnpDevice'
                'Enable-PnpDevice'
                'Uninstall-PnpDevice'
                'pnputil'
                'devcon'
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Remove-Item'
                'Remove-AppxPackage'
                'UsesTrustedInstaller = $true'
                'safeboot'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains unrelated Device Manager Power Savings & Wake behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'network-adapter-power-savings-wake') {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
                'HKLM:\System\ControlSet001\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}'
                'PnPCapabilities'
                'AdvancedEEE'
                '*ModernStandbyWoLMagicPacket'
                'function Test-BoostLabNetworkAdapterPowerWakeState'
                'New-BoostLabVerificationResult'
                '-VerificationResult $verificationResult'
                '[bool]$Confirmed = $false'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing Network Adapter Power Savings & Wake behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'Disable-NetAdapter'
                'Disable-PnpDevice'
                'Uninstall-PnpDevice'
                'pnputil'
                'devcon'
                'netsh winsock reset'
                'netsh int ip reset'
                'Set-NetFirewall'
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Restart-Service'
                'Stop-Process'
                'Remove-AppxPackage'
                'UsesTrustedInstaller = $true'
                'safeboot'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains unrelated Network Adapter Power Savings & Wake behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'hdcp') {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
                '5C350D28F795D678051E6088F34968DF8D90B3D9024F558C5FAFB2899D1A906A'
                'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
                'Registry::HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
                'RMHdcpKeyglobZero'
                'New-BoostLabRegistryStateCapture'
                'Set-BoostLabRollbackMutationState'
                'SourceSkipRule = ''*Configuration*'''
                'SourceKeyNames'
                'SkippedTargets'
                'Off (Recommended)'
                'SupportsDefault = $true'
                'SupportsRestore = $false'
                'CanModifyDrivers = $false'
                'function Test-BoostLabHdcpState'
                'No Restore action is source-defined or exposed for HDCP'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing HDCP controlled registry behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'reg delete'
                'Remove-ItemProperty'
                'Remove-Item -LiteralPath'
                'Restart-Computer'
                'Stop-Computer'
                'Set-Service'
                'Stop-Service'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Start-Process'
                'UsesTrustedInstaller = $true'
                'UsesSafeMode = $true'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains unrelated or unsafe HDCP behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'p0-state') {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
                '382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC'
                'source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1'
                'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
                'Registry::HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
                'DisableDynamicPstate'
                'New-BoostLabRegistryStateCapture'
                'Set-BoostLabRollbackMutationState'
                'SourceKeyNames'
                'SkippedTargets'
                'SourceSkipRule = ''*Configuration*'''
                'No Restore action is source-defined or exposed for P0 State'
                'SupportsDefault = $true'
                'SupportsRestore = $false'
                'CanModifyDrivers = $false'
                'function Test-BoostLabP0StateState'
                'Default is source-defined DWORD 0 and is not Restore'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing P0 State controlled registry behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'NeedsNvidiaTargeting'
                'EligibleTargets'
                'ExcludedTargets'
                'AmbiguousTargets'
                'VEN_10DE'
                'Microsoft/RDP/non-NVIDIA'
                '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'', ''Restore'')'
                'reg delete'
                'Remove-ItemProperty'
                'Remove-Item -LiteralPath'
                'Restart-Computer'
                'Stop-Computer'
                'Set-Service'
                'Stop-Service'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Start-Process'
                'UsesTrustedInstaller = $true'
                'UsesSafeMode = $true'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains unrelated or unsafe P0 State behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'msi-mode') {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Off'')'
                '94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7'
                'Get-PnpDevice -Class Display'
                'HKLM:\SYSTEM\ControlSet001\Enum'
                'Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'
                'MSISupported'
                '$script:BoostLabMsiModeSourceOnRecommendedValue = 1'
                '$script:BoostLabMsiModeSourceOffValue = 0'
                'New-BoostLabRegistryStateCapture'
                'Set-BoostLabRollbackMutationState'
                'SupportsDefault = $false'
                'SupportsRestore = $false'
                'CanModifyDrivers = $false'
                'function Test-BoostLabMsiModeState'
                'Off as a separate visible option'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing Msi Mode controlled registry behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'NeedsNvidiaTargeting'
                'EligibleTargets'
                'ExcludedTargets'
                'AmbiguousTargets'
                'VEN_10DE'
                'NvidiaTarget'
                '$script:BoostLabMsiModeDefaultValue'
                'Invoke-BoostLabMsiModeRestore'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath retained source-undefined Msi Mode filtering/default/restore behavior: $forbiddenText")
                }
            }

            foreach ($forbiddenText in @(
                'Start-Process'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Restart-Computer'
                'Stop-Computer'
                'Set-Service'
                'Stop-Service'
                'bcdedit'
                'reg add'
                'reg delete'
                'Remove-ItemProperty'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains unrelated or unsafe Msi Mode behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'write-cache-buffer-flushing') {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
                'HKLM:\SYSTEM\ControlSet001\Enum'
                'SCSI'
                'NVME'
                'CacheIsPowerProtected'
                'New-BoostLabRegistryStateCapture'
                'Set-BoostLabRollbackMutationState'
                'SupportsDefault           = $true'
                'SupportsRestore           = $false'
                'CanModifyDrivers          = $false'
                'function Test-BoostLabWriteCacheState'
                'function Remove-BoostLabWriteCacheRegistryKey'
                'reg delete "{0}" /f'
                'RegistryKeysDeleteAttempted'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing Write Cache Buffer Flushing behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'Remove-ItemProperty'
                'Remove-Item -LiteralPath'
                'Restart-Computer'
                'Stop-Computer'
                'Set-Service'
                'Stop-Service'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'UsesTrustedInstaller      = $true'
                'UsesSafeMode              = $true'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains unrelated or unsafe Write Cache behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'power-plan') {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
                '$script:BoostLabPowerSchemeGuid = ''99999999-9999-9999-9999-999999999999'''
                '$script:BoostLabPowerSettingDefinitions'
                '/duplicatescheme'
                '/setactive'
                '/delete'
                '-restoredefaultschemes'
                '/hibernate'
                'function Test-BoostLabPowerPlanState'
                'New-BoostLabVerificationResult'
                '-VerificationResult $verification'
                '[bool]$Confirmed = $false'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing Power Plan behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'Disable-PnpDevice'
                'Uninstall-PnpDevice'
                'pnputil'
                'devcon'
                'Restart-Computer'
                'Stop-Computer'
                'shutdown.exe'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Restart-Service'
                'Remove-AppxPackage'
                'UsesTrustedInstaller = $true'
                'safeboot'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains unrelated Power Plan behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'cleanup') {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Apply'')'
                '$script:BoostLabExpectedSourceHash'
                'Get-BoostLabCleanupTargets'
                'Invoke-BoostLabCleanupRemoveTarget'
                'Test-BoostLabCleanupState'
                'Invoke-BoostLabCleanupApply'
                'Remove-Item -Path ([string]$Target.Path) -Recurse -Force -ErrorAction SilentlyContinue'
                'Start-Process ''cleanmgr.exe'''
                'SupportsDefault           = $false'
                'SupportsRestore           = $false'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing Cleanup behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Restart-Computer'
                'Stop-Computer'
                'Set-Service'
                'Stop-Service'
                'reg add'
                'reg delete'
                'Clear-RecycleBin'
                'SupportsDefault           = $true'
                'SupportsRestore           = $true'
                'UsesTrustedInstaller      = $true'
                'UsesSafeMode              = $true'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains unrelated or unsafe Cleanup behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'bios-settings') {
            foreach ($requiredText in @(
                'INTEL CPU'
                'ENABLE ram profile (XMP DOCP EXPO)'
                'DISABLE c-states (K CHIPS ONLY)'
                'ENABLE resizable bar (REBAR C.A.M)'
                'DISABLE i-gpu'
                'AMD CPU'
                'ENABLE precision boost overdrive (PBO)'
                'DISABLE iommu (NEEDED FOR FACEIT)'
                'MAX pump and set fans to performance'
                'DISABLE any driver installer software'
                'Asus armory crate'
                'MSI driver utility'
                'Gigabyte update utility'
                'Asrock motherboard utility'
                'Do not change settings you do not understand'
                'Document current BIOS settings'
                '$script:BoostLabFirmwareConfirmationText'
                '[bool]$Confirmed = $false'
                '$commandProcessorPath = Join-Path $env:SystemRoot ''System32\cmd.exe'''
                '$shutdownPath = Join-Path $env:SystemRoot ''System32\shutdown.exe'''
                '$firmwareRestartCommand = "`"$shutdownPath`" /r /fw /t 0"'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing BIOS Settings guidance behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'https://www.google.com/search?q='
                '[System.Uri]::EscapeDataString'
                'Start-Process $searchUrl'
                'bcdedit'
                'Restart-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains forbidden BIOS Settings behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'to-bios') {
            foreach ($requiredText in @(
                '$script:BoostLabFirmwareConfirmationText'
                '[bool]$Confirmed = $false'
                '$commandProcessorPath = Join-Path $env:SystemRoot ''System32\cmd.exe'''
                '$shutdownPath = Join-Path $env:SystemRoot ''System32\shutdown.exe'''
                '$firmwareRestartCommand = "`"$shutdownPath`" /r /fw /t 0"'
                '& $commandProcessorPath @firmwareRestartArguments'
                'VerificationResult'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing To BIOS behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'Set-ItemProperty'
                'New-ItemProperty'
                'Remove-ItemProperty'
                'bcdedit'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'pnputil'
                'devcon'
                'source-ultimate'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains unrelated To BIOS behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'restore-point') {
            foreach ($requiredText in @(
                'Enable-ComputerRestore -Drive $script:BoostLabRestoreDrive -ErrorAction Stop'
                'Checkpoint-Computer'
                '-Description $script:BoostLabRestorePointName'
                '-RestorePointType $script:BoostLabRestorePointType'
                'SystemRestorePointCreationFrequency'
                '$script:BoostLabRestorePointName = ''backup'''
                '$script:BoostLabRestorePointType = ''MODIFY_SETTINGS'''
                'Start-Process "$env:SystemRoot\system32\control.exe" -ArgumentList "sysdm.cpl,,4"'
                'Start-Process "rstrui"'
                'finally'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing Restore Point behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'Disable-ComputerRestore'
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains forbidden Restore Point behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'widgets') {
            foreach ($requiredText in @(
                '$script:BoostLabWidgetProcessNames = @(''Widgets'', ''WidgetService'')'
                'reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" /v "value" /t REG_DWORD /d "0" /f'
                'reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d "0" /f'
                'reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" /v "value" /t REG_DWORD /d "1" /f'
                'reg delete "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /f'
                'Stop-Process -Force -Name $processName -ErrorAction Stop'
                '[bool]$Confirmed = $false'
                'Widgets disabled.'
                'Widgets restored to default.'
                'Widgets already default.'
                '$script:BoostLabPolicyManagerProviderPath = ''HKLM:\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests'''
                '$script:BoostLabDshPolicyProviderPath = ''HKLM:\SOFTWARE\Policies\Microsoft\Dsh'''
                'function Test-BoostLabWidgetsState'
                'function New-BoostLabWidgetsRegistryOperations'
                'function Test-BoostLabWidgetsAlreadyDefault'
                'New-BoostLabVerificationResult'
                '-VerificationResult $verificationResult'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing Widgets behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains forbidden Widgets behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'memory-compression') {
            foreach ($requiredText in @(
                'Disable-MMAgent -MemoryCompression -ErrorAction Stop'
                'Enable-MMAgent -MemoryCompression -ErrorAction Stop'
                'Get-MMAgent -ErrorAction Stop'
                'function Test-BoostLabMemoryCompressionState'
                'New-BoostLabVerificationResult'
                '-VerificationResult $verificationResult'
                '[bool]$Confirmed = $false'
                'Memory compression disabled.'
                'Memory compression restored to default.'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing Memory Compression behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Set-MMAgent'
                '-PageCombining'
                '-ApplicationPreLaunch'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains unrelated Memory Compression behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'mmagent-assistant') {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
                '$script:BoostLabMMAgentPrefetchRegistryCmdKey = ''HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'''
                'Disable-MMAgent -ApplicationLaunchPrefetching -ErrorAction Stop'
                'Disable-MMAgent -ApplicationPreLaunch -ErrorAction Stop'
                'Set-MMAgent -MaxOperationAPIFiles $Operation.Value -ErrorAction Stop'
                'Disable-MMAgent -MemoryCompression -ErrorAction Stop'
                'Disable-MMAgent -OperationAPI -ErrorAction Stop'
                'Disable-MMAgent -PageCombining -ErrorAction Stop'
                'Enable-MMAgent -ApplicationLaunchPrefetching -ErrorAction Stop'
                'Enable-MMAgent -ApplicationPreLaunch -ErrorAction Stop'
                'Enable-MMAgent -OperationAPI -ErrorAction Stop'
                'Get-MMAgent -ErrorAction Stop'
                'SETTINGS MAY TAKE A WHILE TO INITIALIZE AFTER REBOOT'
                'WAIT A SHORT PERIOD BEFORE CHECKING'
                'The Ultimate Default profile still disables MemoryCompression and PageCombining.'
                'Use the dedicated Memory Compression tool when you only want to change MemoryCompression.'
                'function Test-BoostLabMMAgentAssistantState'
                'New-BoostLabVerificationResult'
                '-VerificationResult $verificationResult'
                '[bool]$Confirmed = $false'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing MMAgent Assistant behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Restart-Service'
                'Start-Process'
                'UsesTrustedInstaller = $true'
                'safeboot'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains unrelated MMAgent Assistant behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'services-optimizer') {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
                '386EEF403F48907E82C2E8E4BE5DFE509B0ED93CADBB5639B42D6326163EDB8F'
                'source-ultimate\8 Advanced\5 Services Optimizer.ps1'
                'Get-BoostLabServicesOptimizerBranchDefinition'
                'Services: Off'
                'Services: Default'
                'servicesoff'
                'serviceson'
                'RunOnceValueName'
                'bcdedit /set {current} safeboot minimal'
                'shutdown -r -t 00'
                'Generated script imports the source-defined REG payload'
                'TrustedInstaller'
                'Enable-ComputerRestore'
                'Checkpoint-Computer'
                'SystemRestorePointCreationFrequency'
                'RejectedRedesignBehavior'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing Services Optimizer exact Ultimate behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'ToolModule.Placeholder.ps1'
                'Gaming profile selected'
                'Performance profile selected'
                'Extreme profile selected'
                'Invoke-BoostLabServicesRecommendationEngine'
                'New-BoostLabServiceCompatibilityScore'
                'RestoreSupported = $true'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Restart-Computer'
                'Stop-Computer'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains unrelated or rejected Services Optimizer behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'timer-resolution-assistant') {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
                '883F7CF4E6179383DE02E44B94FFC8DAFD380246751F1B1D81CAB8800B1E8621'
                'source-ultimate\8 Advanced\6 Timer Resolution Assistant.ps1'
                'Get-BoostLabTimerCSharpPayload'
                'Timer Resolution: On (Recommended)'
                'Timer Resolution: Default'
                'Set Timer Resolution Service'
                'STR'
                'SetTimerResolutionService.cs'
                'SetTimerResolutionService.exe'
                'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
                'GlobalTimerResolutionRequests'
                'NtSetTimerResolution'
                'NtQueryTimerResolution'
                'taskmgr.exe'
                'SupportsRestore = $false'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing Timer Resolution Assistant source-equivalent behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'ToolModule.Placeholder.ps1'
                'ManualHandoffOnly'
                'AutoBlockedUntilArtifactApproval'
                'SupportsRestore = $true'
                'UsesTrustedInstaller = $true'
                'UsesSafeMode = $true'
                'Restart-Computer'
                'Stop-Computer'
                'bcdedit'
                'Invoke-WebRequest'
                'Start-BitsTransfer'
                'msiexec'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains stale or unrelated Timer Resolution Assistant behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'defender-optimize-assistant') {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
                '512F12D805715E9232304ABE5BA400BE6B3965D63F77D3B39E4C304507BFB9B6'
                'source-ultimate\8 Advanced\7 Defender Optimize Assistant.ps1'
                'Get-BoostLabDefenderScriptPayload'
                'Get-BoostLabDefenderSecurityCommands'
                'Defender: Optimize (Recommended)'
                'Defender: Default'
                'defenderoptimize.ps1'
                'defenderdefault.ps1'
                '*defenderoptimize'
                '*defenderdefault'
                'RunOnce'
                'bcdedit /set {current} safeboot minimal'
                'shutdown -r -t 00'
                'TrustedInstaller'
                'GeneratedSecurityCommandCount'
                'SupportsDefault = $true'
                'SupportsRestore = $false'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing Defender Optimize Assistant exact Ultimate behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'ToolModule.Placeholder.ps1'
                'ManualHandoffOnly'
                'AutoBlockedUntilArtifactApproval'
                'SupportsRestore = $true'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'msiexec'
                'Start-Process'
                'RestoreSupported = $true'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains stale or unrelated Defender Optimize Assistant behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'background-apps') {
            foreach ($requiredText in @(
                'reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /t REG_DWORD /d "2" /f'
                'reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /f'
                'Start-Process ms-settings:privacy-backgroundapps -ErrorAction Stop'
                'function Test-BoostLabBackgroundAppsState'
                'New-BoostLabVerificationResult'
                '-VerificationResult $verificationResult'
                '[bool]$Confirmed = $false'
                'Background apps disabled.'
                'Background apps restored to default.'
                'Background Apps already default.'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing Background Apps behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Stop-Process'
                'UsesTrustedInstaller = $true'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains unrelated Background Apps behavior: $forbiddenText")
                }
            }
        }
        elseif ($toolId -eq 'store-settings') {
            foreach ($requiredText in @(
                '$script:BoostLabStoreProcessNames = @(''WinStore.App'', ''backgroundTaskHost'', ''StoreDesktopExtension'')'
                'reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" /v "AutoDownload" /t REG_DWORD /d "2" /f'
                'reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore" /f'
                'Start-Process "ms-windows-store:settings" -ErrorAction Stop'
                'Start-Process "wsreset.exe" -WindowStyle Hidden -ErrorAction Stop'
                'Stop-Process -Name $processName -Force -ErrorAction SilentlyContinue'
                'Set-Content -LiteralPath $Path -Value $Content -Force -ErrorAction Stop'
                'reg load "HKLM\Settings"'
                'reg import'
                'reg unload "HKLM\Settings"'
                'function Test-BoostLabStoreSettingsState'
                'New-BoostLabVerificationResult'
                '-VerificationResult $verificationResult'
                '[bool]$Confirmed = $false'
                'Store settings optimized.'
                'Store settings restored to default.'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing Store Settings behavior: $requiredText")
                }
            }

            foreach ($forbiddenText in @(
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'UsesTrustedInstaller = $true'
            )) {
                if ($source.Contains($forbiddenText)) {
                    $errors.Add("$modulePath contains unrelated Store Settings behavior: $forbiddenText")
                }
            }
        }
    }
    else {
        if (-not $source.Contains('ToolModule.Placeholder.ps1')) {
            $errors.Add("$modulePath does not use the shared placeholder contract.")
        }
        if ('Start-Process' -in $commands) {
            $errors.Add("$modulePath is a placeholder but contains Start-Process.")
        }
        if ($source.Contains('$script:BoostLabImplementedActions')) {
            $errors.Add("$modulePath is a placeholder but declares implemented actions.")
        }
    }
}

$normalizedDeletedNames = @(
    $deletedToolNames | ForEach-Object {
        ($_ -replace '[^a-zA-Z0-9]+', '-').Trim('-').ToLowerInvariant()
    }
)
foreach ($module in $actualModules) {
    $moduleId = [System.IO.Path]::GetFileNameWithoutExtension($module.Name).ToLowerInvariant()
    if ($moduleId -in $normalizedDeletedNames) {
        $errors.Add("Deleted tool module found: $($module.FullName)")
    }
}

if ($errors.Count -gt 0) {
    throw "Module scaffolding validation failed:`r`n- $($errors -join "`r`n- ")"
}

[pscustomobject]@{
    Success               = $true
    ApprovedToolCount     = $expectedModules.Count
    ModuleCount           = $actualModules.Count
    ImplementedModuleCount = $implementedModules.Count
    PlaceholderModuleCount = $actualModules.Count - $implementedModules.Count
    RequiredFunctionCount = $requiredFunctions.Count
    DeletedModuleCount    = 0
    Message               = 'All approved tools have matching modules and valid implementation status.'
    Timestamp             = Get-Date
}
