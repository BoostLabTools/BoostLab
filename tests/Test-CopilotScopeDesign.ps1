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
        throw 'Unable to determine the Copilot scope design validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

$designPath = Join-Path $ProjectRoot 'docs\tool-designs\copilot-scope-design.md'
$readinessPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\8 Copilot.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\copilot.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$artifactPolicyPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$appxPolicyPath = Join-Path $ProjectRoot 'config\AppxPackagePolicy.psd1'
$cleanupPolicyPath = Join-Path $ProjectRoot 'config\CleanupPolicy.psd1'
$rollbackPolicyPath = Join-Path $ProjectRoot 'config\RollbackPolicy.psd1'
$rebootPolicyPath = Join-Path $ProjectRoot 'config\RebootRecoveryPolicy.psd1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

foreach ($path in @(
    $designPath,
    $readinessPath,
    $planPath,
    $sourcePath,
    $modulePath,
    $configPath,
    $artifactPolicyPath,
    $appxPolicyPath,
    $cleanupPolicyPath,
    $rollbackPolicyPath,
    $rebootPolicyPath
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
$appxPolicy = Import-PowerShellDataFile -LiteralPath $appxPolicyPath
$cleanupPolicy = Import-PowerShellDataFile -LiteralPath $cleanupPolicyPath
$rollbackPolicy = Import-PowerShellDataFile -LiteralPath $rollbackPolicyPath
$rebootPolicy = Import-PowerShellDataFile -LiteralPath $rebootPolicyPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })

$expectedSourceHash = '21B58212B241A6C0B74582063E3E74F746014E9137194B58B088CC6692F22A90'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
if ($actualSourceHash -ne $expectedSourceHash) {
    throw "Copilot source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."
}

foreach ($requiredSection in @(
    '# Copilot Scope Design',
    '## Purpose',
    '## Source Reference',
    '## Product Scope Decision',
    '## Source Behavior Summary',
    '## Current Decision',
    '## Behavior Groups',
    '### 1. Copilot AppX/Package Behavior',
    '### 2. Copilot-Related Package Removal Behavior',
    '### 3. AppX Re-Registration or Restore Behavior If Present',
    '### 4. Copilot Policy Registry Behavior',
    '### 5. Copilot User/Settings Registry Behavior If Present',
    '### 6. Process Stop Behavior If Present',
    '### 7. File/Directory Cleanup Behavior If Present',
    '### 8. Downloads/Installers or Repair Behavior If Present',
    '### 9. Default/Restore Behavior',
    '### 10. Unsupported Broad Package/File/Registry/Policy Targets',
    '### 11. Unsupported Windows 10-Only Branches/Options If Present',
    '## Exact Source Target Inventory',
    '## Future Safe Apply Requirements',
    '## Default and Restore Boundary',
    '## Production Approval State'
)) {
    if (-not $designText.Contains($requiredSection)) {
        throw "Copilot scope design is missing section: $requiredSection"
    }
}

foreach ($requiredPhrase in @(
    'Source SHA-256: `21B58212B241A6C0B74582063E3E74F746014E9137194B58B088CC6692F22A90`',
    'Copilot remains a refused placeholder',
    'No production AppX/package',
    'unknown packages remain denied',
    'wildcard/broad packages remain denied',
    'framework/dependency/system-critical packages remain denied',
    'No Windows 10-only branch was found',
    'Do not implement a policy-only subset',
    'policy-only implementation would weaken Ultimate behavior',
    'Current Default/Restore must remain unavailable',
    'No download, installer, or repair tool behavior is present',
    'No file or directory cleanup behavior is present',
    'process-handling policy is still needed'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "Copilot scope design is missing phrase: $requiredPhrase"
    }
}

foreach ($requiredField in @(
    'Intended mutation or launch type:',
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
        throw "Copilot scope design is missing per-group field: $requiredField"
    }
}

foreach ($requiredSourceTarget in @(
    'Get-AppXPackage -AllUsers | Where-Object',
    '*Copilot*',
    'Remove-AppxPackage',
    'Add-AppxPackage -DisableDevelopmentMode -Register',
    '"$($_.InstallLocation)\AppXManifest.xml"',
    'backgroundTaskHost',
    'Copilot',
    'CrossDeviceResume',
    'GameBar',
    'MicrosoftEdgeUpdate',
    'msedge',
    'msedgewebview2',
    'OneDrive',
    'OneDrive.Sync.Service',
    'OneDriveStandaloneUpdater',
    'Resume',
    'RuntimeBroker',
    'Search',
    'SearchHost',
    'Setup',
    'StoreDesktopExtension',
    'WidgetService',
    'Widgets',
    'ProcessName -like "*edge*"',
    'HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot',
    'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot',
    'TurnOffWindowsCopilot',
    'REG_DWORD',
    'cmd /c "reg add',
    'cmd /c "reg delete'
)) {
    if (-not $designText.Contains($requiredSourceTarget)) {
        throw "Copilot scope design is missing source target: $requiredSourceTarget"
    }
}

$urls = [regex]::Matches($sourceText, 'https?://\S+') | ForEach-Object { $_.Value }
if (@($urls).Count -ne 0) {
    throw "Expected no Copilot source URLs, found $(@($urls).Count)."
}

$nonElevationStartProcess = @(
    [regex]::Matches($sourceText, 'Start-Process') |
        ForEach-Object { $_.Value }
).Count - 1
if ($nonElevationStartProcess -ne 0) {
    throw "Expected no non-elevation Start-Process calls, found $nonElevationStartProcess."
}

if ($sourceText -match 'Restart-Computer|shutdown\s|bcdedit') {
    throw 'Copilot source unexpectedly contains direct reboot or BCD behavior.'
}
if ($sourceText -match 'IWR|Invoke-WebRequest|DownloadFile|TrustedInstaller|Run-Trusted') {
    throw 'Copilot source unexpectedly contains download or TrustedInstaller behavior.'
}

if (-not $readinessText.Contains('docs/tool-designs/copilot-scope-design.md')) {
    throw 'Deferred readiness review does not link to the Copilot scope design.'
}
if (-not $planText.Contains('docs/tool-designs/copilot-scope-design.md')) {
    throw 'Deferred tools execution plan does not link to the Copilot scope design.'
}

if (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) {
    throw 'Copilot module is no longer a placeholder.'
}
if ($moduleText -match 'Get-AppXPackage|Remove-AppxPackage|Add-AppxPackage|Start-Process|IWR|Invoke-WebRequest|reg add|reg delete|Stop-Process') {
    throw 'Copilot placeholder module appears to contain real mutation behavior.'
}

if ($artifactPolicy.Artifacts.Count -ne 0) {
    throw "Artifact approvals were added unexpectedly: $($artifactPolicy.Artifacts.Count)"
}
if ($appxPolicy.PackageScopes.Count -ne 0) {
    throw "AppX package production scopes were approved unexpectedly: $($appxPolicy.PackageScopes.Count)"
}
if ($cleanupPolicy.CleanupScopes.Count -ne 0) {
    throw "Cleanup production scopes were approved unexpectedly: $($cleanupPolicy.CleanupScopes.Count)"
}
if ($rollbackPolicy.FileScopes.Count -ne 0 -or $rollbackPolicy.RegistryScopes.Count -ne 0) {
    throw 'File or registry production scopes were approved unexpectedly.'
}
if ($rebootPolicy.WorkflowScopes.Count -ne 0) {
    throw "Reboot workflow production scopes were approved unexpectedly: $($rebootPolicy.WorkflowScopes.Count)"
}

$copilotTool = $allTools |
    Where-Object { $_.Id -eq 'copilot' -and $_.Stage -eq 'Windows' } |
    Select-Object -First 1
if (-not $copilotTool) {
    throw 'Copilot catalog entry was not found.'
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
    ToolId                        = 'copilot'
    SourceHash                    = $actualSourceHash
    ActiveToolCount               = $activeTools.Count
    ImplementedToolCount          = $activeTools.Count - $placeholderModules.Count
    PlaceholderToolCount          = $placeholderModules.Count
    ProductionArtifactApprovals   = $artifactPolicy.Artifacts.Count
    ProductionPackageScopes       = $appxPolicy.PackageScopes.Count
    ProductionCleanupScopes       = $cleanupPolicy.CleanupScopes.Count
    ProductionFileScopes          = $rollbackPolicy.FileScopes.Count
    ProductionRegistryScopes      = $rollbackPolicy.RegistryScopes.Count
    ProductionRebootScopes        = $rebootPolicy.WorkflowScopes.Count
    SourceUltimateUnchanged       = $true
    DeletedToolsRemainDeleted     = $true
    Message                       = 'Copilot scope design is present, linked, and non-executing.'
    Timestamp                     = Get-Date
}



