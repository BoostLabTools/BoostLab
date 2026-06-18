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
        throw 'Unable to determine the privilege policy test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$trustedInstallerPath = Join-Path $ProjectRoot 'core\TrustedInstaller.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$bootstrapPath = Join-Path $ProjectRoot 'bootstrap.ps1'
$startPath = Join-Path $ProjectRoot 'Start-BoostLab.ps1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$modulesRoot = Join-Path $ProjectRoot 'modules'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration['Stages'] | ForEach-Object { $_['Tools'] })
$errors = [System.Collections.Generic.List[string]]::new()

foreach ($tool in $tools) {
    $capabilities = $tool['Capabilities']
    if (
        $capabilities -isnot [System.Collections.IDictionary] -or
        -not $capabilities.Contains('RequiresAdmin') -or
        $capabilities['RequiresAdmin'] -isnot [bool]
    ) {
        $errors.Add("$($tool['Title']) does not have Boolean RequiresAdmin metadata.")
        continue
    }

    foreach ($field in @('UsesTrustedInstaller', 'UsesSafeMode', 'CanReboot')) {
        if ([bool]$capabilities[$field] -and -not [bool]$capabilities['NeedsExplicitConfirmation']) {
            $errors.Add("$($tool['Title']) declares $field without explicit confirmation.")
        }
    }
}

$safeLauncherIds = @(
    'date-language-region-time'
    'startup-apps-settings'
    'startup-apps-task-manager'
    'graphics-configuration-center'
    'game-mode'
    'pointer-precision'
    'sound'
)
foreach ($toolId in $safeLauncherIds) {
    $tool = $tools | Where-Object { $_['Id'] -eq $toolId } | Select-Object -First 1
    if ($null -eq $tool -or [bool]$tool['Capabilities']['RequiresAdmin']) {
        $errors.Add("$toolId should not require Administrator for its approved launcher.")
    }
}

$trustedInstallerIds = @(
    'game-bar'
    'control-panel-settings'
    'services-optimizer'
    'defender-optimize-assistant'
)
$safeModeIds = @(
    'services-optimizer'
    'defender-optimize-assistant'
)
$serviceIds = @(
    'edge-settings'
    'installers'
    'driver-install-debloat-settings'
    'bloatware'
    'game-bar'
    'edge-webview'
    'control-panel-settings'
    'services-optimizer'
    'timer-resolution-assistant'
    'defender-optimize-assistant'
)

foreach ($toolId in $trustedInstallerIds) {
    $tool = $tools | Where-Object { $_['Id'] -eq $toolId } | Select-Object -First 1
    if (
        $null -eq $tool -or
        -not [bool]$tool['Capabilities']['UsesTrustedInstaller'] -or
        -not [bool]$tool['Capabilities']['RequiresAdmin'] -or
        -not [bool]$tool['Capabilities']['NeedsExplicitConfirmation']
    ) {
        $errors.Add("$toolId does not preserve its TrustedInstaller privilege metadata.")
    }
}
foreach ($toolId in $safeModeIds) {
    $tool = $tools | Where-Object { $_['Id'] -eq $toolId } | Select-Object -First 1
    if (
        $null -eq $tool -or
        -not [bool]$tool['Capabilities']['UsesSafeMode'] -or
        -not [bool]$tool['Capabilities']['NeedsExplicitConfirmation']
    ) {
        $errors.Add("$toolId does not preserve its Safe Mode metadata.")
    }
}
foreach ($toolId in $serviceIds) {
    $tool = $tools | Where-Object { $_['Id'] -eq $toolId } | Select-Object -First 1
    if ($null -eq $tool -or -not [bool]$tool['Capabilities']['CanModifyServices']) {
        $errors.Add("$toolId does not declare source-proven service capability.")
    }
}

$sourceFiles = @(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File -Filter '*.ps1' | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') })
$adminSources = @($sourceFiles | Where-Object {
    (Get-Content -Raw -LiteralPath $_.FullName) -match '(?im)#\s*SCRIPT RUN AS ADMIN'
})
$trustedInstallerSources = @($sourceFiles | Where-Object {
    (Get-Content -Raw -LiteralPath $_.FullName) -match '(?i)TrustedInstaller'
})
$safeModeSources = @($sourceFiles | Where-Object {
    (Get-Content -Raw -LiteralPath $_.FullName) -match '(?i)Safe\s*Mode|safeboot'
})
$runOnceSources = @($sourceFiles | Where-Object {
    (Get-Content -Raw -LiteralPath $_.FullName) -match '(?i)RunOnce'
})
if (
    $sourceFiles.Count -ne 49 -or
    $adminSources.Count -ne 41 -or
    $trustedInstallerSources.Count -ne 4 -or
    $safeModeSources.Count -ne 2 -or
    $runOnceSources.Count -ne 5
) {
    $errors.Add('The read-only Ultimate privilege audit no longer matches the approved baseline.')
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
$trustedInstallerModule = Import-Module -Name $trustedInstallerPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    $adminTool = $tools | Where-Object { $_['Id'] -eq 'memory-compression' } | Select-Object -First 1
    $adminPlan = New-BoostLabActionPlan -ToolMetadata $adminTool -ActionName 'Apply' -IsDryRun $false
    if (
        -not [bool]$adminPlan.RequiresAdmin -or
        (@($adminPlan.PrivilegeRequirements) -join ' ') -notmatch 'Administrator required'
    ) {
        $errors.Add('Administrator requirements are not visible in Action Plans.')
    }

    $safeTool = $tools | Where-Object { $_['Id'] -eq 'date-language-region-time' } | Select-Object -First 1
    $safePlan = New-BoostLabActionPlan -ToolMetadata $safeTool -ActionName 'Open' -IsDryRun $false
    if ([bool]$safePlan.RequiresAdmin -or [bool]$safePlan.NeedsExplicitConfirmation) {
        $errors.Add('Safe Open-only launchers received an unnecessary privilege or confirmation requirement.')
    }

    $trustedInstallerTool = $tools | Where-Object { $_['Id'] -eq 'game-bar' } | Select-Object -First 1
    $trustedInstallerAction = [string]@($trustedInstallerTool['Actions'])[0]
    $trustedInstallerPlan = New-BoostLabActionPlan `
        -ToolMetadata $trustedInstallerTool `
        -ActionName $trustedInstallerAction
    $trustedInstallerText = @(
        @($trustedInstallerPlan.PrivilegeRequirements)
        @($trustedInstallerPlan.PlannedChanges)
        @($trustedInstallerPlan.SideEffects)
        $trustedInstallerPlan.ConfirmationMessage
    ) -join ' '
    if (
        -not [bool]$trustedInstallerPlan.UsesTrustedInstaller -or
        -not [bool]$trustedInstallerPlan.NeedsExplicitConfirmation -or
        $trustedInstallerText -notmatch 'TrustedInstaller' -or
        $trustedInstallerText -notmatch 'Administrator|elevated'
    ) {
        $errors.Add('TrustedInstaller Action Plans do not show the required privilege warning.')
    }

    foreach ($commandName in @(
        'Test-BoostLabTrustedInstallerSupported'
        'New-BoostLabTrustedInstallerPlan'
        'Invoke-BoostLabTrustedInstallerCommand'
    )) {
        if (-not (Get-Command -Name $commandName -ErrorAction SilentlyContinue)) {
            $errors.Add("TrustedInstaller helper is missing function: $commandName")
        }
    }

    $support = Test-BoostLabTrustedInstallerSupported
    $helperPlan = New-BoostLabTrustedInstallerPlan `
        -ToolMetadata $trustedInstallerTool `
        -ActionName $trustedInstallerAction
    $invokeResult = Invoke-BoostLabTrustedInstallerCommand `
        -ToolMetadata $trustedInstallerTool `
        -ActionName $trustedInstallerAction `
        -CommandDescription 'Static policy test only'
    if (
        $support.Supported -or
        $support.Status -ne 'NotImplemented' -or
        $helperPlan.Status -ne 'NotImplemented' -or
        $invokeResult.Success -or
        $invokeResult.Status -ne 'NotImplemented' -or
        $invokeResult.CommandExecuted
    ) {
        $errors.Add('TrustedInstaller helper is not an inert NotImplemented boundary.')
    }
}
finally {
    Remove-Module -ModuleInfo $trustedInstallerModule -Force -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$trustedInstallerSource = Get-Content -Raw -LiteralPath $trustedInstallerPath
$tokens = $null
$parseErrors = $null
$trustedInstallerAst = [System.Management.Automation.Language.Parser]::ParseFile(
    $trustedInstallerPath,
    [ref]$tokens,
    [ref]$parseErrors
)
if (@($parseErrors).Count -gt 0) {
    $errors.Add("TrustedInstaller helper has a syntax error: $($parseErrors[0].Message)")
}
$trustedInstallerCommands = @(
    $trustedInstallerAst.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
        $true
    ) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }
)
foreach ($forbiddenCommand in @(
    'Start-Process'
    'Start-Service'
    'Stop-Service'
    'Set-Service'
    'Restart-Service'
    'Invoke-Expression'
    'sc.exe'
    'psexec'
    'nsudo'
)) {
    if ($forbiddenCommand -in $trustedInstallerCommands) {
        $errors.Add("TrustedInstaller helper contains executable command: $forbiddenCommand")
    }
}
if ($trustedInstallerSource -notmatch 'CommandExecuted\s*=\s*\$false') {
    $errors.Add('TrustedInstaller helper does not explicitly report that no command executed.')
}

$bootstrapSource = Get-Content -Raw -LiteralPath $bootstrapPath
$startSource = Get-Content -Raw -LiteralPath $startPath
$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredText in @(
    'Test-BoostLabAdministrator'
    '-Verb RunAs'
    'BoostLab requires Administrator rights'
)) {
    if (-not $bootstrapSource.Contains($requiredText)) {
        $errors.Add("bootstrap.ps1 is missing Administrator enforcement: $requiredText")
    }
    if (-not $startSource.Contains($requiredText)) {
        $errors.Add("Start-BoostLab.ps1 is missing Administrator enforcement: $requiredText")
    }
}
if (
    -not $startSource.Contains('[switch]$ElevationAttempted') -or
    -not $startSource.Contains('if ($ElevationAttempted)')
) {
    $errors.Add('Start-BoostLab.ps1 is missing its elevation loop guard.')
}
foreach ($requiredText in @(
    '$isImplementedAction'
    '[bool]$actionPlan.RequiresAdmin'
    'Test-BoostLabAdministrator'
    'Administrator rights are required'
)) {
    if (-not $executionSource.Contains($requiredText)) {
        $errors.Add("Execution runtime is missing Administrator gating: $requiredText")
    }
}

$implementedModules = [ordered]@{
    'bios-information' = 'Check\BIOSInformation.psm1'
    'bios-settings' = 'Check\BIOSSettings.psm1'
    'to-bios' = 'Refresh\to-bios.psm1'
    'startup-apps-settings' = 'Setup\StartupAppsSettings.psm1'
    'startup-apps-task-manager' = 'Setup\StartupAppsTaskManager.psm1'
    'memory-compression' = 'Setup\MemoryCompression.psm1'
    'background-apps' = 'Setup\BackgroundApps.psm1'
    'store-settings' = 'Setup\StoreSettings.psm1'
    'updates-pause' = 'Setup\UpdatesPause.psm1'
    'graphics-configuration-center' = 'Graphics\GraphicsConfigurationCenter.psm1'
    'hdcp' = 'Graphics\hdcp.psm1'
    'p0-state' = 'Graphics\p0-state.psm1'
    'msi-mode' = 'Graphics\msi-mode.psm1'
    'date-language-region-time' = 'Setup\date-language-region-time.psm1'
    'game-mode' = 'Windows\game-mode.psm1'
    'pointer-precision' = 'Windows\pointer-precision.psm1'
    'sound' = 'Windows\sound.psm1'
    'widgets' = 'Windows\Widgets.psm1'
    'restore-point' = 'Windows\RestorePoint.psm1'
    'theme-black' = 'Windows\ThemeBlack.psm1'
    'start-menu-layout' = 'Windows\StartMenuLayout.psm1'
    'context-menu' = 'Windows\ContextMenu.psm1'
    'signout-lockscreen-wallpaper-black' = 'Windows\SignoutLockScreenWallpaperBlack.psm1'
    'device-manager-power-savings-wake' = 'Windows\device-manager-power-savings-wake.psm1'
    'user-account-pictures-black' = 'Windows\user-account-pictures-black.psm1'
    'spectre-meltdown-assistant' = 'Advanced\spectre-meltdown-assistant.psm1'
    'mmagent-assistant' = 'Advanced\mmagent-assistant.psm1'
    'smt-ht-assistant' = 'Advanced\smt-ht-assistant.psm1'
    'notepad-settings' = 'Windows\notepad-settings.psm1'
}
foreach ($toolId in $implementedModules.Keys) {
    $modulePath = Join-Path $modulesRoot $implementedModules[$toolId]
    if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
        $errors.Add("Existing implemented module path changed: $toolId")
        continue
    }
    $moduleSource = Get-Content -Raw -LiteralPath $modulePath
    if (-not $moduleSource.Contains('$script:BoostLabImplementedActions')) {
        $errors.Add("Existing implemented module is no longer marked implemented: $toolId")
    }
    if (-not $executionSource.Contains("'$toolId' = @{")) {
        $errors.Add("Existing implemented module is no longer in the runtime allowlist: $toolId")
    }
}

$allModules = @(
    Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1' |
        Where-Object { $_.Directory.Parent.FullName -eq $modulesRoot }
)
$implementedModuleFiles = @(
    $allModules | Where-Object {
        (Get-Content -Raw -LiteralPath $_.FullName).Contains('$script:BoostLabImplementedActions')
    }
)
if ($implementedModuleFiles.Count -ne 37) {
    $errors.Add("Implemented module boundary changed: found $($implementedModuleFiles.Count) implemented modules.")
}

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
function ConvertTo-NormalizedToolName {
    param([Parameter(Mandatory)][string]$Name)

    return ($Name -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()
}
$approvedNames = @(
    $tools | ForEach-Object {
        ConvertTo-NormalizedToolName -Name ([string]$_['Title'])
        ConvertTo-NormalizedToolName -Name ([string]$_['Id'])
    }
)
foreach ($deletedToolName in $deletedToolNames) {
    if ((ConvertTo-NormalizedToolName -Name $deletedToolName) -in $approvedNames) {
        $errors.Add("Deleted tool is present: $deletedToolName")
    }
}

$sourceLines = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Sort-Object { $_.FullName.Substring($ProjectRoot.Length + 1).Replace('\', '/') } |
        ForEach-Object {
            '{0}|{1}' -f `
                $_.FullName.Substring($ProjectRoot.Length + 1).Replace('\', '/'), `
                (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
        }
)
$sha256 = [System.Security.Cryptography.SHA256]::Create()
try {
    $sourceManifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n")))
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}
if (
    $sourceLines.Count -ne 49 -or
    $sourceManifestHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477'
) {
    $errors.Add('source-ultimate content or paths changed.')
}

if ($errors.Count -gt 0) {
    throw "Privilege policy validation failed:`r`n- $($errors -join "`r`n- ")"
}

[pscustomobject]@{
    Success                     = $true
    ToolCount                   = $tools.Count
    AdminMarkedSourceCount      = $adminSources.Count
    TrustedInstallerSourceCount = $trustedInstallerSources.Count
    SafeModeSourceCount         = $safeModeSources.Count
    ImplementedToolCount        = $implementedModuleFiles.Count
    TrustedInstallerExecuted    = $false
    ToolActionsExecuted         = $false
    SourceUltimateUnchanged     = $true
    Message                     = 'Administrator and TrustedInstaller privilege policy is valid without executing tool actions.'
    Timestamp                   = Get-Date
}


