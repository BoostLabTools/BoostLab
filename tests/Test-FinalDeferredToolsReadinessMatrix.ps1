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
        throw 'Unable to determine the final deferred matrix validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

$matrixPath = Join-Path $ProjectRoot 'docs\final-deferred-tools-readiness-matrix.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$reviewPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$policyPaths = @{
    Artifact          = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
    Appx              = Join-Path $ProjectRoot 'config\AppxPackagePolicy.psd1'
    Cleanup           = Join-Path $ProjectRoot 'config\CleanupPolicy.psd1'
    DriverState       = Join-Path $ProjectRoot 'config\DriverStatePolicy.psd1'
    RebootRecovery    = Join-Path $ProjectRoot 'config\RebootRecoveryPolicy.psd1'
    Rollback          = Join-Path $ProjectRoot 'config\RollbackPolicy.psd1'
    SafeModeRecovery  = Join-Path $ProjectRoot 'config\SafeModeRecoveryPolicy.psd1'
    ServiceRollback   = Join-Path $ProjectRoot 'config\ServiceRollbackPolicy.psd1'
    TrustedInstaller  = Join-Path $ProjectRoot 'config\TrustedInstallerPolicy.psd1'
}

foreach ($path in @($matrixPath, $planPath, $reviewPath, $configPath) + $policyPaths.Values) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file was not found: $path"
    }
}

$matrixText = Get-Content -LiteralPath $matrixPath -Raw
$planText = Get-Content -LiteralPath $planPath -Raw
$reviewText = Get-Content -LiteralPath $reviewPath -Raw
$config = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })

$placeholderModules = @(
    Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' |
        Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw).Contains(
                'ToolModule.Placeholder.ps1'
            )
        }
)

$placeholderTools = foreach ($module in $placeholderModules) {
    $stageName = Split-Path -Path (Split-Path -Path $module.FullName -Parent) -Leaf
    $toolId = [IO.Path]::GetFileNameWithoutExtension($module.Name)
    $tool = $allTools |
        Where-Object { $_.Stage -eq $stageName -and $_.Id -eq $toolId } |
        Select-Object -First 1
    if (-not $tool) {
        throw "Unable to map placeholder module to config metadata: $($module.FullName)"
    }
    $tool
}

if ($allTools.Count -ne $inventoryBaseline.ActiveTools) {
    throw "Expected $($inventoryBaseline.ActiveTools) active tools, found $($allTools.Count)."
}
if ($placeholderTools.Count -ne $inventoryBaseline.DeferredPlaceholders) {
    throw "Expected $($inventoryBaseline.DeferredPlaceholders) deferred/placeholders, found $($placeholderTools.Count)."
}
if (($allTools.Count - $placeholderTools.Count) -ne $inventoryBaseline.ImplementedTools) {
    throw "Expected $($inventoryBaseline.ImplementedTools) implemented tools, found $($allTools.Count - $placeholderTools.Count)."
}

$expectedDeferred = @(
    @{ Id = 'timer-resolution-assistant'; Title = 'Timer Resolution Assistant'; Link = 'docs/tool-designs/timer-resolution-assistant-scope-design.md'; Source = 'source-ultimate/8 Advanced/6 Timer Resolution Assistant.ps1'; Hash = '883F7CF4E6179383DE02E44B94FFC8DAFD380246751F1B1D81CAB8800B1E8621' }
    @{ Id = 'defender-optimize-assistant'; Title = 'Defender Optimize Assistant'; Link = 'docs/tool-designs/defender-optimize-assistant-scope-design.md'; Source = 'source-ultimate/8 Advanced/7 Defender Optimize Assistant.ps1'; Hash = '512F12D805715E9232304ABE5BA400BE6B3965D63F77D3B39E4C304507BFB9B6' }
)

foreach ($expected in $expectedDeferred) {
    if (-not ($placeholderTools | Where-Object { $_.Id -eq $expected.Id })) {
        throw "Expected deferred tool '$($expected.Id)' is no longer a placeholder."
    }
    foreach ($requiredText in @($expected.Id, $expected.Title, $expected.Link, $expected.Source, $expected.Hash)) {
        if (-not $matrixText.Contains($requiredText)) {
            throw "Final deferred matrix is missing '$requiredText'."
        }
    }
}

if ($placeholderTools | Where-Object { $_.Id -eq 'services-optimizer' }) {
    throw "Services Optimizer remains in the deferred placeholder set after Phase 159."
}
if ($matrixText -match '\| Services Optimizer \| `services-optimizer` \|') {
    throw 'Final deferred matrix still lists Services Optimizer as deferred.'
}

foreach ($requiredSection in @(
    '# Final Deferred Tools Readiness Matrix',
    '## Purpose',
    '## Current Inventory',
    '## Coverage Summary',
    '## Matrix',
    '## Blocker Frequency Summary',
    '## Near-Term Candidate Shortlist',
    '## Shared Foundation Roadmap',
    '## High-Risk Deferred Set',
    '## Product Scope Notes',
    '## Recommended Next Phases',
    '## Final Phase 65 Decision'
)) {
    if (-not $matrixText.Contains($requiredSection)) {
        throw "Final deferred matrix is missing section: $requiredSection"
    }
}

foreach ($requiredPhrase in @(
    'Standalone provenance review covered tools: **0**',
    'Manual-handoff implemented with Auto provenance review still blocking automation: **5**',
    'No deferred tool is marked ready for implementation by this matrix.',
    'The presence of a scope design or provenance review is evidence for planning, not permission to execute.',
    'Production Allowlist Governance',
    'Restore Selection UI / Runtime Foundation',
    'Process Handling Policy Foundation',
    'Scheduled Task State Capture / Rollback Foundation',
    'Generated Script / Temp Artifact Ownership Policy',
    'Artifact Approval Intake Process'
)) {
    if (-not $matrixText.Contains($requiredPhrase)) {
        throw "Final deferred matrix is missing phrase: $requiredPhrase"
    }
}

foreach ($requiredBlocker in @(
    '| Missing artifact provenance | 1 |',
    '| Missing Safe Mode/reboot workflow approval | 1 |'
)) {
    if (-not $matrixText.Contains($requiredBlocker)) {
        throw "Final deferred matrix is missing blocker frequency row: $requiredBlocker"
    }
}

foreach ($candidate in @(
    'Timer Resolution Assistant'
)) {
    if (-not $matrixText.Contains("**$candidate**")) {
        throw "Final deferred matrix is missing near-term candidate '$candidate'."
    }
}

if (-not $planText.Contains('docs/final-deferred-tools-readiness-matrix.md')) {
    throw 'Deferred tools execution plan does not link to the final readiness matrix.'
}
if (-not $reviewText.Contains('docs/final-deferred-tools-readiness-matrix.md')) {
    throw 'Deferred readiness review does not link to the final readiness matrix.'
}

$artifactPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.Artifact
$appxPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.Appx
$cleanupPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.Cleanup
$driverPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.DriverState
$rebootPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.RebootRecovery
$rollbackPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.Rollback
$safeModePolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.SafeModeRecovery
$servicePolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.ServiceRollback
$trustedPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.TrustedInstaller

if ($artifactPolicy.Artifacts.Count -ne 0) {
    throw "Artifact approvals were added unexpectedly: $($artifactPolicy.Artifacts.Count)"
}
if ($appxPolicy.PackageScopes.Count -ne 0) {
    throw "AppX package scopes were approved unexpectedly: $($appxPolicy.PackageScopes.Count)"
}
if ($cleanupPolicy.CleanupScopes.Count -ne 0) {
    throw "Cleanup scopes were approved unexpectedly: $($cleanupPolicy.CleanupScopes.Count)"
}
if ($driverPolicy.DriverScopes.Count -ne 0) {
    throw "Driver scopes were approved unexpectedly: $($driverPolicy.DriverScopes.Count)"
}
if ($rebootPolicy.WorkflowScopes.Count -ne 0) {
    throw "Reboot workflow scopes were approved unexpectedly: $($rebootPolicy.WorkflowScopes.Count)"
}
if ($rollbackPolicy.FileScopes.Count -ne 0 -or $rollbackPolicy.RegistryScopes.Count -ne 0) {
    throw 'File or registry rollback scopes were approved unexpectedly.'
}
if ($safeModePolicy.SafeModeScopes.Count -ne 0) {
    throw "Safe Mode scopes were approved unexpectedly: $($safeModePolicy.SafeModeScopes.Count)"
}
if ($servicePolicy.ServiceScopes.Count -ne 0) {
    throw "Service scopes were approved unexpectedly: $($servicePolicy.ServiceScopes.Count)"
}
if ($trustedPolicy.TrustedInstallerScopes.Count -ne 0) {
    throw "TrustedInstaller scopes were approved unexpectedly: $($trustedPolicy.TrustedInstallerScopes.Count)"
}

foreach ($deletedTool in @('Loudness EQ', 'NVME Faster Driver')) {
    if ($matrixText.Contains("| $deletedTool |")) {
        throw "Final deferred matrix must not list deleted tool '$deletedTool' as active."
    }
    if ($allTools | Where-Object { $_.Title -eq $deletedTool -or $_.Id -like "*$($deletedTool.ToLowerInvariant().Replace(' ', '-'))*" }) {
        throw "Deleted tool '$deletedTool' was reintroduced into active config."
    }
}
foreach ($deletedToolId in @('resizable-bar-assistant', 'smt-ht-assistant')) {
    if ($matrixText.Contains("| $deletedToolId |")) {
        throw "Final deferred matrix must not list deleted tool '$deletedToolId' as active or deferred."
    }
    if ($allTools | Where-Object { $_.Id -eq $deletedToolId }) {
        throw "Deleted tool '$deletedToolId' was reintroduced into active config."
    }
}

$loudnessPath = Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1'
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

[pscustomobject]@{
    Success                   = $true
    MatrixPath                = $matrixPath
    DeferredToolCount         = $placeholderTools.Count
    ImplementedToolCount      = $allTools.Count - $placeholderTools.Count
    ActiveToolCount           = $allTools.Count
    ScopeDesignCoverage       = $placeholderTools.Count
    ProvenanceReviewCoverage  = 0
    ProductionArtifactScopes  = $artifactPolicy.Artifacts.Count
    ProductionAppxScopes      = $appxPolicy.PackageScopes.Count
    ProductionCleanupScopes   = $cleanupPolicy.CleanupScopes.Count
    ProductionDriverScopes    = $driverPolicy.DriverScopes.Count
    ProductionFileScopes      = $rollbackPolicy.FileScopes.Count
    ProductionRegistryScopes  = $rollbackPolicy.RegistryScopes.Count
    ProductionServiceScopes   = $servicePolicy.ServiceScopes.Count
    ProductionRebootScopes    = $rebootPolicy.WorkflowScopes.Count
    ProductionSafeModeScopes  = $safeModePolicy.SafeModeScopes.Count
    ProductionTrustedScopes   = $trustedPolicy.TrustedInstallerScopes.Count
    SourceUltimateUnchanged   = $true
    DeletedToolsRemainDeleted = $true
    Message                   = 'Final deferred tools readiness matrix covers all current placeholders and remains non-executing.'
    Timestamp                 = Get-Date
}



