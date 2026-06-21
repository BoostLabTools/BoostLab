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
        throw 'Unable to determine the Control Panel Settings scope design validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

$designPath = Join-Path $ProjectRoot 'docs\tool-designs\control-panel-settings-scope-design.md'
$readinessPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\15 Control Panel Settings.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\control-panel-settings.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$artifactPolicyPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$cleanupPolicyPath = Join-Path $ProjectRoot 'config\CleanupPolicy.psd1'
$rollbackPolicyPath = Join-Path $ProjectRoot 'config\RollbackPolicy.psd1'
$servicePolicyPath = Join-Path $ProjectRoot 'config\ServiceRollbackPolicy.psd1'
$rebootPolicyPath = Join-Path $ProjectRoot 'config\RebootRecoveryPolicy.psd1'
$trustedPolicyPath = Join-Path $ProjectRoot 'config\TrustedInstallerPolicy.psd1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

foreach ($path in @(
    $designPath,
    $readinessPath,
    $planPath,
    $sourcePath,
    $modulePath,
    $configPath,
    $artifactPolicyPath,
    $cleanupPolicyPath,
    $rollbackPolicyPath,
    $servicePolicyPath,
    $rebootPolicyPath,
    $trustedPolicyPath
)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file was not found: $path"
    }
}

$designText = Get-Content -LiteralPath $designPath -Raw
$readinessText = Get-Content -LiteralPath $readinessPath -Raw
$planText = Get-Content -LiteralPath $planPath -Raw
$sourceText = Get-Content -LiteralPath $sourcePath -Raw
$moduleText = Get-Content -LiteralPath $modulePath -Raw
$config = Import-PowerShellDataFile -LiteralPath $configPath
$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPolicyPath
$cleanupPolicy = Import-PowerShellDataFile -LiteralPath $cleanupPolicyPath
$rollbackPolicy = Import-PowerShellDataFile -LiteralPath $rollbackPolicyPath
$servicePolicy = Import-PowerShellDataFile -LiteralPath $servicePolicyPath
$rebootPolicy = Import-PowerShellDataFile -LiteralPath $rebootPolicyPath
$trustedPolicy = Import-PowerShellDataFile -LiteralPath $trustedPolicyPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })

$expectedSourceHash = 'B78F643D21069F14E7E766769FB1EE15AEF974ABDF3CA010FE808D9EC162FB0B'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
if ($actualSourceHash -ne $expectedSourceHash) {
    throw "Control Panel Settings source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."
}

foreach ($requiredSection in @(
    '# Control Panel Settings Scope Design',
    '## Purpose',
    '## Source Reference',
    '## Product Scope Decision',
    '## Source Behavior Summary',
    '## Current Decision',
    '## Behavior Groups',
    '### 1. Control Panel Registry Settings',
    '### 2. Privacy Settings',
    '### 3. Security Settings',
    '### 4. Application Settings',
    '### 5. Capability Access Manager Behavior',
    '### 6. Capability Access Manager Database/File Behavior If Present',
    '### 7. Service Configuration Behavior',
    '### 8. Service Stop/Start/Delete Behavior If Present',
    '### 9. Process Stop Behavior If Present',
    '### 10. Scheduled Task Behavior If Present',
    '### 11. TrustedInstaller-Required Operations',
    '### 12. Registry Import Behavior',
    '### 13. Registry Deletion Behavior',
    '### 14. Protected File Deletion or Cleanup Behavior',
    '### 15. Default/Restore Behavior',
    '### 16. Unsupported Broad Registry/File/Service/Privacy/Security Targets',
    '### 17. Unsupported Windows 10-Only Branches/Options If Present',
    '## Exact Source Target Inventory',
    '## Future Safe Apply Requirements',
    '## Default and Restore Boundary',
    '## Production Approval State'
)) {
    if (-not $designText.Contains($requiredSection)) {
        throw "Control Panel Settings scope design is missing section: $requiredSection"
    }
}

foreach ($requiredPhrase in @(
    'Source SHA-256: `B78F643D21069F14E7E766769FB1EE15AEF974ABDF3CA010FE808D9EC162FB0B`',
    'No production Control Panel',
    'No Windows 10-only branch was found',
    'Privacy and security mutation is high risk',
    'Do not implement a registry-only or policy-only subset',
    'broad registry import remains refused',
    'service changes require exact future allowlist',
    'No scheduled task mutation is approved in this phase',
    'No TrustedInstaller operation is approved in this phase',
    'Current Default/Restore must remain unavailable',
    '234 distinct registry keys and 356 distinct'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "Control Panel Settings scope design is missing phrase: $requiredPhrase"
    }
}

foreach ($requiredField in @(
    'Intended mutation type:',
    'Required foundation:',
    'Required future production allowlist:',
    'Required inventory/capture before mutation:',
    'Required confirmation level:',
    'Required verification:',
    'Rollback/restore feasibility:',
    'Risk level:',
    'Whether it can be implemented later:',
    'Whether it must remain refused:'
)) {
    if (-not $designText.Contains($requiredField)) {
        throw "Control Panel Settings scope design is missing per-group field: $requiredField"
    }
}

foreach ($requiredSourceTarget in @(
    '$env:SystemRoot\Temp\registryoptimize.reg',
    '$env:SystemRoot\Temp\registrydefaults.reg',
    '$env:SystemRoot\Temp\disablesetprioritynotifications.reg',
    '$env:SystemRoot\Temp\appactions.reg',
    '$env:ProgramData\Microsoft\Windows\CapabilityAccessManager\CapabilityConsentStorage.db*',
    '$env:LOCALAPPDATA\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\Settings\settings.dat',
    'Run-Trusted -command $capabilityconsentstoragedb',
    'sc.exe config TrustedInstaller binPath=',
    'sc.exe start TrustedInstaller',
    'Regedit.exe /S "$env:SystemRoot\Temp\registryoptimize.reg"',
    'Regedit.exe /S "$env:SystemRoot\Temp\registrydefaults.reg"',
    'Start-Process -Wait "regedit.exe"',
    'reg import $regfileappactions',
    'reg load "HKLM\Settings" $settingsdat',
    'reg unload "HKLM\Settings"',
    'powercfg /setdcvalueindex scheme_current sub_none consolelock',
    'powercfg /setacvalueindex scheme_current sub_none consolelock',
    'TrustedInstaller',
    'camsvc',
    'CDPUserSvc',
    'ScheduledDefrag',
    'AppActions',
    'CrossDeviceResume',
    'DesktopStickerEditorWin32Exe',
    'DiscoveryHubApp',
    'FESearchHost',
    'SearchHost',
    'SoftLandingTask',
    'TextInputHost',
    'VisualAssistExe',
    'WebExperienceHostApp',
    'WindowsBackupClient',
    'WindowsMigration',
    'HKEY_CURRENT_USER\Control Panel',
    'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore',
    'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy',
    'HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\WindowsCopilot',
    'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot',
    'HKEY_CLASSES_ROOT\ms-gamebar',
    'HKEY_LOCAL_MACHINE\Settings\LocalState\DisabledApps'
)) {
    if (-not $designText.Contains($requiredSourceTarget)) {
        throw "Control Panel Settings scope design is missing source target: $requiredSourceTarget"
    }
}

$registryKeys = [regex]::Matches($sourceText, '^\[(?:-|)([^\]]+)\]', 'Multiline') |
    ForEach-Object { $_.Groups[1].Value } |
    Sort-Object -Unique
$registryValues = [regex]::Matches($sourceText, '^"([^"]+)"=', 'Multiline') |
    ForEach-Object { $_.Groups[1].Value } |
    Sort-Object -Unique
if (@($registryKeys).Count -ne 234) {
    throw "Expected 234 distinct registry keys, found $(@($registryKeys).Count)."
}
if (@($registryValues).Count -ne 356) {
    throw "Expected 356 distinct registry value names, found $(@($registryValues).Count)."
}

if ($sourceText -match 'IWR|Invoke-WebRequest|DownloadFile|https?://') {
    throw 'Control Panel Settings source unexpectedly contains download behavior.'
}
if ($sourceText -match 'Restart-Computer|shutdown\s|bcdedit') {
    throw 'Control Panel Settings source unexpectedly contains direct reboot or BCD behavior.'
}

if (-not $readinessText.Contains('docs/tool-designs/control-panel-settings-scope-design.md')) {
    throw 'Deferred readiness review does not link to the Control Panel Settings scope design.'
}
if (-not $planText.Contains('docs/tool-designs/control-panel-settings-scope-design.md')) {
    throw 'Deferred tools execution plan does not link to the Control Panel Settings scope design.'
}

foreach ($requiredModuleText in @(
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')',
    '$script:BoostLabExpectedSourceHash',
    'Get-BoostLabControlPanelSettingsSourceStatus',
    'Get-BoostLabControlPanelSettingsBranchScript',
    'Invoke-BoostLabControlPanelSettingsScript',
    'ScriptRunner'
)) {
    if (-not $moduleText.Contains($requiredModuleText)) {
        throw "Control Panel Settings implemented module is missing source-backed behavior: $requiredModuleText"
    }
}
if ($moduleText.Contains('ToolModule.Placeholder.ps1')) {
    throw 'Control Panel Settings must no longer use the placeholder module after Phase 149.'
}

if ($artifactPolicy.Artifacts.Count -ne 0) {
    throw "Artifact approvals were added unexpectedly: $($artifactPolicy.Artifacts.Count)"
}
if ($cleanupPolicy.CleanupScopes.Count -ne 0) {
    throw "Cleanup production scopes were approved unexpectedly: $($cleanupPolicy.CleanupScopes.Count)"
}
if ($rollbackPolicy.FileScopes.Count -ne 0 -or $rollbackPolicy.RegistryScopes.Count -ne 0) {
    throw 'File or registry production scopes were approved unexpectedly.'
}
if ($servicePolicy.ServiceScopes.Count -ne 0) {
    throw "Service production scopes were approved unexpectedly: $($servicePolicy.ServiceScopes.Count)"
}
if ($rebootPolicy.WorkflowScopes.Count -ne 0) {
    throw "Reboot workflow production scopes were approved unexpectedly: $($rebootPolicy.WorkflowScopes.Count)"
}
if ($trustedPolicy.TrustedInstallerScopes.Count -ne 0) {
    throw "TrustedInstaller production scopes were approved unexpectedly: $($trustedPolicy.TrustedInstallerScopes.Count)"
}

$controlPanelTool = $allTools |
    Where-Object { $_.Id -eq 'control-panel-settings' -and $_.Stage -eq 'Windows' } |
    Select-Object -First 1
if (-not $controlPanelTool) {
    throw 'Control Panel Settings catalog entry was not found.'
}

$activeTools = @($allTools)
$placeholderModules = @(
    Get-ChildItem -Path (Join-Path $ProjectRoot 'modules') -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
if ($activeTools.Count -ne $inventoryBaseline.ActiveTools) {
    throw "Expected $($inventoryBaseline.ActiveTools) active tools, found $($activeTools.Count)."
}
if ($placeholderModules.Count -ne $inventoryBaseline.DeferredPlaceholders) {
    throw "Expected $($inventoryBaseline.DeferredPlaceholders) placeholder modules, found $($placeholderModules.Count)."
}
if (($activeTools.Count - $placeholderModules.Count) -ne $inventoryBaseline.ImplementedTools) {
    throw "Expected $($inventoryBaseline.ImplementedTools) implemented tools, found $($activeTools.Count - $placeholderModules.Count)."
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
    Sort-Object {
        $_.FullName.Substring($root.Length + 1).Replace('\', '/')
    } |
    ForEach-Object {
        '{0}|{1}' -f `
            $_.FullName.Substring($root.Length + 1).Replace('\', '/'), `
            (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    }
$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $manifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash(
            [Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n"))
        )
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}

if (
    @($sourceLines).Count -ne 49 -or
    $manifestHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477'
) {
    throw 'source-ultimate content or paths changed.'
}

$loudnessPath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'
if (Test-Path -LiteralPath $loudnessPath) {
    throw 'Loudness EQ source was reintroduced.'
}
$nvmeSource = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Where-Object { $_.Name -like '*NVME Faster Driver*' }
)
if ($nvmeSource.Count -ne 0) {
    throw 'NVME Faster Driver source was reintroduced.'
}

[pscustomobject]@{
    Success                       = $true
    ToolId                        = 'control-panel-settings'
    SourceHash                    = $actualSourceHash
    RegistryKeyCount              = @($registryKeys).Count
    RegistryValueCount            = @($registryValues).Count
    ActiveToolCount               = $activeTools.Count
    ImplementedToolCount          = $activeTools.Count - $placeholderModules.Count
    PlaceholderToolCount          = $placeholderModules.Count
    ProductionArtifactApprovals   = $artifactPolicy.Artifacts.Count
    ProductionCleanupScopes       = $cleanupPolicy.CleanupScopes.Count
    ProductionFileScopes          = $rollbackPolicy.FileScopes.Count
    ProductionRegistryScopes      = $rollbackPolicy.RegistryScopes.Count
    ProductionServiceScopes       = $servicePolicy.ServiceScopes.Count
    ProductionRebootScopes        = $rebootPolicy.WorkflowScopes.Count
    ProductionTrustedScopes       = $trustedPolicy.TrustedInstallerScopes.Count
    SourceUltimateUnchanged       = $true
    DeletedToolsRemainDeleted     = $true
    Message                       = 'Control Panel Settings scope design is present, linked, and non-executing.'
    Timestamp                     = Get-Date
}



