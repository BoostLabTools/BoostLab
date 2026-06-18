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
        throw 'Unable to determine the missing Ultimate scripts intake validator path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$docPath = Join-Path $ProjectRoot 'docs\missing-ultimate-scripts-intake-review.md'
$agentsPath = Join-Path $ProjectRoot 'AGENTS.md'
$instructionsPath = Join-Path $ProjectRoot 'CODEX_INSTRUCTIONS.md'
$blueprintPath = Join-Path $ProjectRoot 'BOOSTLAB_BLUEPRINT.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$reviewPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$matrixPath = Join-Path $ProjectRoot 'docs\final-deferred-tools-readiness-matrix.md'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

foreach ($path in @($docPath, $agentsPath, $instructionsPath, $blueprintPath, $planPath, $reviewPath, $matrixPath, $stagesPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file was not found: $path"
    }
}

$expectedIntakeFiles = @(
    'intake\missing-ultimate-scripts\Ultimate\5 Graphics\1 Driver Clean.ps1',
    'intake\missing-ultimate-scripts\Ultimate\5 Graphics\2 Driver Install Latest.ps1',
    'intake\missing-ultimate-scripts\Ultimate\5 Graphics\4 Nvidia Settings.ps1',
    'intake\missing-ultimate-scripts\Ultimate\5 Graphics\5 Hdcp.ps1',
    'intake\missing-ultimate-scripts\Ultimate\5 Graphics\6 P0 State.ps1',
    'intake\missing-ultimate-scripts\Ultimate\5 Graphics\7 Msi Mode.ps1',
    'intake\missing-ultimate-scripts\Ultimate\3 Setup\1 BitLocker.ps1'
)

$expectedWorkflow = @(
    '5 Graphics/2 Driver Install Latest.ps1',
    '5 Graphics/4 Nvidia Settings.ps1',
    '5 Graphics/5 Hdcp.ps1',
    '5 Graphics/6 P0 State.ps1',
    '5 Graphics/7 Msi Mode.ps1'
)

$docText = Get-Content -LiteralPath $docPath -Raw
$agentsText = Get-Content -LiteralPath $agentsPath -Raw
$instructionsText = Get-Content -LiteralPath $instructionsPath -Raw
$blueprintText = Get-Content -LiteralPath $blueprintPath -Raw
$planText = Get-Content -LiteralPath $planPath -Raw
$reviewText = Get-Content -LiteralPath $reviewPath -Raw
$matrixText = Get-Content -LiteralPath $matrixPath -Raw
$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })

foreach ($section in @(
    '# Missing Ultimate Scripts Intake Review',
    '## Current Counts',
    '## Intake File List',
    '## Deleted And Disallowed Tool Conflict Check',
    '## Duplicate / Current Source Conflict Check',
    '## Product Scope Review',
    '## NVIDIA App Alternate Workflow',
    '## Per-Script Intake Classification',
    '## Source-Order Reconciliation Plan',
    '## Phase 69 Non-Actions',
    '## Recommended Next Phase'
)) {
    if (-not $docText.Contains($section)) {
        throw "Intake review document is missing section: $section"
    }
}

foreach ($relativePath in $expectedIntakeFiles) {
    $fullPath = Join-Path $ProjectRoot $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "Expected intake script is missing: $relativePath"
    }

    $item = Get-Item -LiteralPath $fullPath
    $hash = (Get-FileHash -LiteralPath $fullPath -Algorithm SHA256).Hash
    $lineCount = (Get-Content -LiteralPath $fullPath).Count

    foreach ($requiredText in @($relativePath.Replace('\', '/'), $hash, [string]$item.Length, [string]$lineCount)) {
        if (-not $docText.Contains($requiredText)) {
            throw "Intake review does not record '$requiredText' for $relativePath."
        }
    }
}

$previousIndex = -1
foreach ($workflowItem in $expectedWorkflow) {
    $index = $docText.IndexOf($workflowItem, [StringComparison]::Ordinal)
    if ($index -lt 0) {
        throw "NVIDIA App workflow item is missing from intake review: $workflowItem"
    }
    if ($index -le $previousIndex) {
        throw "NVIDIA App workflow order is not preserved for $workflowItem."
    }
    $previousIndex = $index
}

foreach ($requiredPhrase in @(
    'Path A: `Driver Install Debloat & Settings`',
    'Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`',
    'alternate NVIDIA App workflow',
    'Future UI must not let Path A and Path B be mixed accidentally',
    'These five scripts must not be merged into one tool during intake'
)) {
    if (-not $docText.Contains($requiredPhrase)) {
        throw "Intake review is missing workflow phrase: $requiredPhrase"
    }
}

foreach ($deletedTool in @(
    'Loudness EQ',
    'NVME Faster Driver',
    'Windows Activation Helper',
    'Firewall',
    'DEP',
    'File Download Security Warning',
    'MPO',
    'FSO',
    'FSE',
    'Hardware Flip',
    'AMD ULPS',
    'WHQL Secure Boot Bypass',
    'Keyboard Shortcuts',
    'Search Shell Mobsync',
    'Core 1 Thread 1',
    'DDU',
    'UAC',
    'Scaling',
    'Start Menu Shortcuts'
)) {
    if (-not $docText.Contains($deletedTool)) {
        throw "Intake review does not document deleted/disallowed conflict check for: $deletedTool"
    }
}

foreach ($requiredPhrase in @(
    'Driver Clean.ps1` is a Yazan-approved intake exception despite DDU usage; this does not approve standalone DDU or DDU execution',
    'future implementation requires dedicated Driver Clean scope/provenance/safety design',
    'Standalone DDU remains deleted/disallowed as an independent BoostLab tool',
    'No intake script currently exists in `source-ultimate/` under the same relative path or same script title',
    'numbering/order reconciliation conflicts',
    'No files should be renamed or moved in this phase',
    'No scripts were moved into `source-ultimate` in this phase',
    'No tool was implemented or enabled in this phase',
    'No intake scripts were edited',
    'No `source-ultimate` files were modified',
    'Intake candidate scripts reviewed here: **7**',
    'Official BoostLab counts do not change in this phase',
    'Yazan approved this script as an intake exception despite DDU usage'
)) {
    if (-not $docText.Contains($requiredPhrase)) {
        throw "Intake review is missing required phrase: $requiredPhrase"
    }
}

foreach ($classification in @(
    'Yazan-approved intake exception for future source promotion',
    'Scope + Provenance Design needed',
    'Implemented as controlled manual handoff only in Phase 93',
    'Implemented as controlled registry behavior in Phase 95',
    'Implemented as controlled NVIDIA-only registry behavior in Phase 97',
    'Implemented as controlled security assistant in Phase 98',
    'Mutation remains blocked pending security/recovery-key design'
)) {
    if (-not $docText.Contains($classification)) {
        throw "Intake review is missing classification: $classification"
    }
}

foreach ($governanceText in @($agentsText, $instructionsText, $blueprintText)) {
    foreach ($requiredPhrase in @(
        'Driver Clean is a Yazan-approved intake exception despite DDU usage',
        'does not approve standalone DDU',
        'Loudness EQ',
        'NVME Faster Driver'
    )) {
        if (-not $governanceText.Contains($requiredPhrase)) {
            throw "Top-level governance is missing Driver Clean exception phrase: $requiredPhrase"
        }
    }
}

foreach ($linkedDocText in @($planText, $reviewText, $matrixText)) {
    if (-not $linkedDocText.Contains('docs/missing-ultimate-scripts-intake-review.md')) {
        throw 'A deferred/readiness document does not link to the missing scripts intake review.'
    }
}

$placeholderModules = @(
    Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' |
        Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw).Contains(
                'ToolModule.Placeholder.ps1'
            )
        }
)
if ($allTools.Count -ne 55) {
    throw "Expected 55 active tools, found $($allTools.Count)."
}
if ($placeholderModules.Count -ne 17) {
    throw "Expected 17 deferred/placeholders, found $($placeholderModules.Count)."
}
if (($allTools.Count - $placeholderModules.Count) -ne 38) {
    throw "Expected 38 implemented tools, found $($allTools.Count - $placeholderModules.Count)."
}

$dduTools = @($allTools | Where-Object { $_.Title -eq 'DDU' -or $_.Id -eq 'ddu' })
if ($dduTools.Count -ne 0) {
    throw 'Standalone DDU was reintroduced into active config.'
}
$dduModules = @(
    Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' |
        Where-Object { $_.BaseName -eq 'ddu' -or $_.Name -like '*DDU*' }
)
if ($dduModules.Count -ne 0) {
    throw 'Standalone DDU module was reintroduced.'
}

foreach ($intakePath in $expectedIntakeFiles) {
    $relativeToSource = $intakePath -replace '^intake\\missing-ultimate-scripts\\Ultimate\\', ''
    $sourceCandidate = Join-Path $sourceRoot $relativeToSource
    if (Test-Path -LiteralPath $sourceCandidate) {
        throw "Intake script was unexpectedly promoted into source-ultimate: $relativeToSource"
    }
}

$loudnessPath = Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1'
if (Test-Path -LiteralPath $loudnessPath) {
    throw 'Loudness EQ source was reintroduced.'
}
$nvmeMatches = @(
    Get-ChildItem -Path $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }
)
if ($nvmeMatches.Count -ne 0) {
    throw 'NVME Faster Driver source was reintroduced.'
}

$policyPaths = @{
    Artifact            = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
    Appx                = Join-Path $ProjectRoot 'config\AppxPackagePolicy.psd1'
    Cleanup             = Join-Path $ProjectRoot 'config\CleanupPolicy.psd1'
    DriverState         = Join-Path $ProjectRoot 'config\DriverStatePolicy.psd1'
    ProcessHandling     = Join-Path $ProjectRoot 'config\ProcessHandlingPolicy.psd1'
    ProductionAllowlist = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
    RebootRecovery      = Join-Path $ProjectRoot 'config\RebootRecoveryPolicy.psd1'
    Rollback            = Join-Path $ProjectRoot 'config\RollbackPolicy.psd1'
    RestoreSelection    = Join-Path $ProjectRoot 'config\RestoreSelectionPolicy.psd1'
    SafeModeRecovery    = Join-Path $ProjectRoot 'config\SafeModeRecoveryPolicy.psd1'
    ServiceRollback     = Join-Path $ProjectRoot 'config\ServiceRollbackPolicy.psd1'
    TrustedInstaller    = Join-Path $ProjectRoot 'config\TrustedInstallerPolicy.psd1'
}
foreach ($path in $policyPaths.Values) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required policy file was not found: $path"
    }
}

$artifactPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.Artifact
$appxPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.Appx
$cleanupPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.Cleanup
$driverPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.DriverState
$processPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.ProcessHandling
$productionPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.ProductionAllowlist
$rebootPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.RebootRecovery
$rollbackPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.Rollback
$restorePolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.RestoreSelection
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
if ($processPolicy.ProcessHandlingScopes.Count -ne 0 -or $processPolicy.ApprovedProcessTargets.Count -ne 0) {
    throw 'Process handling scopes or targets were approved unexpectedly.'
}
if ($productionPolicy.ProductionAllowlistProposals.Count -ne 0) {
    throw "Production allowlist proposals were approved unexpectedly: $($productionPolicy.ProductionAllowlistProposals.Count)"
}
if ($rebootPolicy.WorkflowScopes.Count -ne 0) {
    throw "Reboot workflow scopes were approved unexpectedly: $($rebootPolicy.WorkflowScopes.Count)"
}
if ($rollbackPolicy.FileScopes.Count -ne 0 -or $rollbackPolicy.RegistryScopes.Count -ne 0) {
    throw 'File or registry rollback scopes were approved unexpectedly.'
}
if ($restorePolicy.RestoreSelectionScopes.Count -ne 0 -or $restorePolicy.ApprovedRestoreHandlers.Count -ne 0) {
    throw 'Restore selection scopes or handlers were approved unexpectedly.'
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

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceFiles = @(
    Get-ChildItem -Path $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
        ForEach-Object {
            $relative = $_.FullName.Substring($root.Length + 1).Replace('\', '/')
            $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
            "$relative|$hash"
        }
)
$sourceManifestHash = [BitConverter]::ToString(
    [Security.Cryptography.SHA256]::Create().ComputeHash(
        [Text.Encoding]::UTF8.GetBytes(($sourceFiles -join "`n"))
    )
).Replace('-', '')

if ($sourceFiles.Count -ne 49) {
    throw "Expected 49 source-ultimate files, found $($sourceFiles.Count)."
}
if ($sourceManifestHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') {
    throw "source-ultimate manifest hash changed unexpectedly: $sourceManifestHash"
}

[pscustomobject]@{
    Success                  = $true
    IntakeCandidateCount     = $expectedIntakeFiles.Count
    ActiveToolCount          = $allTools.Count
    ImplementedToolCount     = $allTools.Count - $placeholderModules.Count
    DeferredPlaceholderCount = $placeholderModules.Count
    SourceUltimateUnchanged  = $true
    Message                  = 'Missing Ultimate scripts intake review is documented and remains separate from official source/tool counts.'
}



