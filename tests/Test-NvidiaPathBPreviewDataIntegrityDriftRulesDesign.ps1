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
        throw 'Unable to determine the NVIDIA Path B preview data integrity/drift rules design validator path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

function Get-BoostLabManifestHash {
    param(
        [Parameter(Mandatory)]
        [string[]]$Lines
    )

    [BitConverter]::ToString(
        [Security.Cryptography.SHA256]::Create().ComputeHash(
            [Text.Encoding]::UTF8.GetBytes(($Lines -join "`n"))
        )
    ).Replace('-', '')
}

$driftDesignPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-preview-data-integrity-drift-rules-design.md'
$previewDesignPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-non-executing-catalog-preview-data-design.md'
$copyDesignPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-path-conflict-copy-status-text-design.md'
$badgeDesignPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-readiness-badge-design.md'
$runtimeGatingPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-runtime-gating-design.md'
$schemaDesignPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-non-executing-workflow-registry-schema-design.md'
$uiDesignPath = Join-Path $ProjectRoot 'docs\nvidia-path-b-ui-workflow-design.md'
$catalogPath = Join-Path $ProjectRoot 'docs\nvidia-path-b-catalog-design.md'
$matrixPath = Join-Path $ProjectRoot 'docs\final-deferred-tools-readiness-matrix.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$reviewPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$intakeRoot = Join-Path $ProjectRoot 'intake\missing-ultimate-scripts\Ultimate'

foreach ($path in @($driftDesignPath, $previewDesignPath, $copyDesignPath, $badgeDesignPath, $runtimeGatingPath, $schemaDesignPath, $uiDesignPath, $catalogPath, $matrixPath, $planPath, $reviewPath, $stagesPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file was not found: $path"
    }
}
foreach ($path in @($modulesRoot, $sourceRoot, $intakeRoot)) {
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        throw "Required folder was not found: $path"
    }
}

$pathB = @(
    @{
        Title = 'Driver Install Latest'
        ModuleName = 'DriverInstallLatest'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
        Hash = '41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F'
    }
    @{
        Title = 'Nvidia Settings'
        ModuleName = 'NvidiaSettings'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
        Hash = '903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5'
    }
    @{
        Title = 'Hdcp'
        ModuleName = 'Hdcp'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/5 Hdcp.ps1'
        Hash = '5C350D28F795D678051E6088F34968DF8D90B3D9024F558C5FAFB2899D1A906A'
    }
    @{
        Title = 'P0 State'
        ModuleName = 'P0State'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/6 P0 State.ps1'
        Hash = '382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC'
    }
    @{
        Title = 'Msi Mode'
        ModuleName = 'MsiMode'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/7 Msi Mode.ps1'
        Hash = '94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7'
    }
)

$driftText = Get-Content -LiteralPath $driftDesignPath -Raw

foreach ($section in @(
    '# NVIDIA Path B Preview Data Integrity And Drift Rules Design',
    '## Purpose And Status',
    '## Integrity Concepts',
    '## Drift Concepts',
    '## Required Future Integrity Rules',
    '## Drift Detection Rules',
    '## Drift Severity Model',
    '## Future Drift Response Behavior',
    '## Preview Data Integrity Report Schema',
    '## Relationship To Existing Documents',
    '## Explicit Non-Actions',
    '## Recommended Next Phase'
)) {
    if (-not $driftText.Contains($section)) {
        throw "Preview data integrity/drift rules design is missing section: $section"
    }
}

foreach ($phrase in @(
    'This is preview data integrity and drift rules design only',
    'No live drift checker is implemented',
    'No active preview data config is created',
    'No live catalog or runtime registry is enabled',
    'No UI implementation is added',
    'No runtime behavior changes',
    'No tool card or placeholder is enabled',
    'No executable workflow is created',
    'No production approval is granted',
    'This phase does not touch Windows Registry',
    'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
)) {
    if (-not $driftText.Contains($phrase)) {
        throw "Required drift design status/order phrase is missing: $phrase"
    }
}

foreach ($concept in @(
    'source mirror integrity',
    'source checksum integrity',
    'Path B order integrity',
    'source path binding integrity',
    'workflow id integrity',
    'step id integrity',
    'badge mapping integrity',
    'gate mapping integrity',
    'copy/status text integrity',
    'preview action availability integrity',
    'non-execution integrity',
    'count separation integrity',
    'documentation reference integrity',
    'approval dependency integrity',
    'Restore/Default semantic integrity'
)) {
    if (-not $driftText.Contains($concept)) {
        throw "Integrity concept is missing: $concept"
    }
}

foreach ($category in @(
    'SourceChecksumDrift',
    'SourcePathDrift',
    'PathOrderDrift',
    'StepMetadataDrift',
    'BadgeMappingDrift',
    'GateMappingDrift',
    'StatusTextDrift',
    'PreviewActionDrift',
    'DocumentationReferenceDrift',
    'ApprovalStateDrift',
    'ProductionApprovalDrift',
    'CountDrift',
    'RestoreDefaultSemanticDrift',
    'ExecutionEnablementDrift',
    'PathConflictPolicyDrift',
    'UnsupportedTargetPolicyDrift'
)) {
    if (-not $driftText.Contains(('`' + $category + '`'))) {
        throw "Drift category is missing: $category"
    }
}
if (-not $driftText.Contains('Any `ExecutionEnablementDrift` must be treated as critical and must fail closed')) {
    throw 'ExecutionEnablementDrift critical fail-closed rule is missing.'
}

foreach ($rule in @(
    'Path B preview must always list exactly five steps in the approved order',
    'Every preview step source mirror path must match the approved source mirror',
    'Every preview step SHA-256 must match the approved checksum',
    'Every step must keep `canExecute = $false`',
    'Every current Path B badge must keep `isExecutionEnabling = $false`',
    'Preview action availability must keep Analyze/Apply/Default/Restore/Continue/Skip/Download/Install/Import Profile unavailable until later approval',
    'Preview data must not be counted as active, implemented, or deferred placeholders',
    'Preview data must remain separate from official 48/30/18 counts',
    'Path A/Path B conflict policy must remain visible',
    'Restore must not be confused with Default',
    'Missing provenance/rollback/profile capture/NVIDIA targeting must remain',
    'Any mismatch must block future runtime consumption'
)) {
    if (-not $driftText.Contains($rule)) {
        throw "Required future integrity rule is missing: $rule"
    }
}

foreach ($rule in @(
    'Recompute source mirror checksums and compare with expected values',
    'Verify exact step order',
    'Verify required step ids and names',
    'Verify source mirror files still exist',
    'Verify badge sets match readiness badge design',
    'Verify gate references match runtime gating design',
    'Verify path conflict status text references exist',
    'Verify non-executing preview flags remain false',
    'Verify no preview field implies production approval',
    'Verify official counts did not absorb source-promoted intake candidates',
    'Verify Driver Clean and BitLocker remain outside the five-step Path B preview',
    'Verify standalone DDU remains absent',
    'Verify Loudness EQ and NVME Faster Driver remain deleted'
)) {
    if (-not $driftText.Contains($rule)) {
        throw "Drift detection rule is missing: $rule"
    }
}

foreach ($severity in @('Info', 'Warning', 'Blocking', 'Critical')) {
    if (-not $driftText.Contains(('`' + $severity + '`'))) {
        throw "Drift severity level is missing: $severity"
    }
}
foreach ($mapping in @(
    '`Critical` | `ExecutionEnablementDrift`, `SourceChecksumDrift`, `SourcePathDrift`, `PathOrderDrift`, `ProductionApprovalDrift`, `StandaloneDduDrift`, `DeletedToolDrift`',
    '`Blocking` | `BadgeMappingDrift`, `GateMappingDrift`, `PreviewActionDrift`, `CountDrift`, `RestoreDefaultSemanticDrift`',
    '`Warning` | `DocumentationReferenceDrift`, `StatusTextDrift`, `StepMetadataDrift`, `ApprovalStateDrift`, `PathConflictPolicyDrift`, `UnsupportedTargetPolicyDrift`',
    '`Info` | wording-only review notes that do not affect gates'
)) {
    if (-not $driftText.Contains($mapping)) {
        throw "Drift severity mapping is missing: $mapping"
    }
}

foreach ($response in @(
    'Critical drift must fail closed',
    'Blocking drift must prevent preview from being consumed by runtime',
    'Warning drift must require review before activation',
    'Info drift may be documented for future cleanup',
    'Drift reports must include source, expected value, actual value, severity',
    'No auto-fix should move or rewrite source mirror files without explicit phase approval',
    'No drift response should enable execution'
)) {
    if (-not $driftText.Contains($response)) {
        throw "Future drift response behavior is missing: $response"
    }
}

foreach ($field in @(
    'reportId',
    'workflowId',
    'reviewedAt',
    'reviewedBy',
    'expectedStepOrder',
    'actualStepOrder',
    'sourceChecksums',
    'checksumResults',
    'pathResults',
    'badgeResults',
    'gateResults',
    'actionAvailabilityResults',
    'documentationReferenceResults',
    'countResults',
    'driftFindings',
    'highestSeverity',
    'canUsePreview',
    'canExecute',
    'recommendedAction',
    'activityLogEvent'
)) {
    if (-not $driftText.Contains(('`' + $field + '`'))) {
        throw "Preview data integrity report schema field is missing: $field"
    }
}
if (-not $driftText.Contains('Current design requires `canExecute = $false`')) {
    throw 'Report schema does not state canExecute must remain false in current design.'
}

foreach ($documentPath in @(
    'docs/tool-designs/nvidia-path-b-non-executing-catalog-preview-data-design.md',
    'docs/tool-designs/nvidia-path-b-readiness-badge-design.md',
    'docs/tool-designs/nvidia-path-b-path-conflict-copy-status-text-design.md',
    'docs/tool-designs/nvidia-path-b-runtime-gating-design.md',
    'docs/tool-designs/nvidia-path-b-non-executing-workflow-registry-schema-design.md',
    'docs/tool-designs/nvidia-path-b-production-approval-gate-design.md',
    'docs/tool-designs/nvidia-path-b-draft-allowlist-proposal.md',
    'docs/tool-designs/nvidia-path-b-artifact-provenance-review.md',
    'docs/nvidia-profile-state-capture-model.md',
    'docs/nvidia-path-b-ui-workflow-design.md',
    'docs/production-allowlist-governance.md',
    'docs/download-provenance-installer-policy.md',
    'docs/driver-state-capture-rollback.md',
    'docs/file-registry-state-capture-rollback.md',
    'docs/process-handling-policy.md',
    'docs/reboot-recovery-workflow.md',
    'docs/restore-selection-ui-runtime.md'
)) {
    if (-not $driftText.Contains($documentPath)) {
        throw "Relationship to existing documents/foundations is missing: $documentPath"
    }
}

foreach ($nonAction in @(
    'No live drift checker implemented',
    'No active preview config created',
    'No active UI config created',
    'No active runtime config created',
    'No production config or allowlist config created or changed',
    'No production approval granted',
    'No executable handler/module/action created',
    'No tool or placeholder enabled',
    'No runtime behavior changed',
    'No source mirror files changed',
    'No intake files changed',
    'No legacy source-ultimate files changed',
    'No artifact, download, installer, Profile Inspector, `.nip`, driver',
    'No AppX, service, task, cleanup, TrustedInstaller, or Safe Mode approval',
    'No DDU execution/download/artifact approval added',
    'Standalone DDU not introduced',
    'Loudness EQ and NVME Faster Driver remain deleted',
    'Counts unchanged'
)) {
    if (-not $driftText.Contains($nonAction)) {
        throw "Explicit non-action boundary is missing: $nonAction"
    }
}

foreach ($linkedPath in @($previewDesignPath, $badgeDesignPath, $runtimeGatingPath, $schemaDesignPath, $copyDesignPath, $uiDesignPath, $catalogPath, $matrixPath, $planPath, $reviewPath)) {
    $linkedText = Get-Content -LiteralPath $linkedPath -Raw
    if (-not $linkedText.Contains('docs/tool-designs/nvidia-path-b-preview-data-integrity-drift-rules-design.md')) {
        throw "Expected document does not link to the NVIDIA Path B preview data integrity/drift rules design: $linkedPath"
    }
}

foreach ($forbiddenPath in @(
    'config\NvidiaPathBPreview.Schema.psd1',
    'config\NvidiaPathBPreview.psd1',
    'config\NvidiaPathBCatalogPreview.psd1',
    'config\NvidiaPathBPreviewData.psd1',
    'config\NvidiaPathBDriftRules.psd1',
    'config\NvidiaPathBIntegrity.psd1',
    'config\NvidiaPathBCatalog.psd1',
    'config\NvidiaPathBCopyStatusText.psd1',
    'config\NvidiaPathBStatusText.psd1',
    'config\NvidiaPathBLocalization.psd1',
    'config\NvidiaPathBReadinessBadges.psd1',
    'config\NvidiaPathBBadges.psd1',
    'config\NvidiaPathBWorkflowRegistry.psd1',
    'config\NvidiaPathBWorkflow.psd1',
    'config\NvidiaPathBRuntimeGating.psd1',
    'config\NvidiaPathBGates.psd1',
    'config\NvidiaPathBProductionAllowlist.psd1',
    'config\NvidiaPathBAllowlist.psd1',
    'config\NvidiaPathBScopes.psd1',
    'config\NvidiaPathBArtifactProvenance.psd1',
    'config\NvidiaPathBArtifacts.psd1',
    'config\NvidiaPathBDraftAllowlist.psd1',
    'config\NvidiaPathBApprovalGate.psd1',
    'config\NvidiaProfileProductionAllowlist.psd1',
    'config\NvidiaProfileScopes.psd1',
    'config\NvidiaProfileImportPolicy.psd1',
    'config\NvidiaProfileExportPolicy.psd1',
    'config\NvidiaProfileInspectorArtifacts.psd1'
)) {
    if (Test-Path -LiteralPath (Join-Path $ProjectRoot $forbiddenPath)) {
        throw "Active preview, UI, runtime, production, or Path B allowlist config was unexpectedly created: $forbiddenPath"
    }
}

if (@(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'core') -Filter '*NvidiaPathB*.psm1' -ErrorAction SilentlyContinue).Count -ne 0) {
    throw 'Runtime module or executable helper was unexpectedly created for NVIDIA Path B.'
}

$uiFilesWithPathB = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'ui') -Recurse -File |
        Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw) -match 'Driver Install Latest|Nvidia Settings|Hdcp|P0 State|Msi Mode|nvidia-path-b|PathConflict|NVIDIA App Compatible'
        }
)
if ($uiFilesWithPathB.Count -ne 0) {
    throw 'WPF/UI runtime files were unexpectedly modified for NVIDIA Path B integrity/drift rules.'
}

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })
foreach ($title in @($pathB | Where-Object { $_.Title -notin @('Driver Install Latest', 'Nvidia Settings', 'Hdcp', 'P0 State', 'Msi Mode') } | ForEach-Object { $_.Title })) {
    if (@($allTools | Where-Object { $_.Title -eq $title }).Count -ne 0) {
        throw "Path B source-promoted script was unexpectedly added as an active tool: $title"
    }
}
$driverInstallLatestTool = @($allTools | Where-Object { $_.Title -eq 'Driver Install Latest' })
if ($driverInstallLatestTool.Count -ne 1) {
    throw 'Driver Install Latest must be active exactly once as the Phase 93 controlled manual-handoff tool.'
}
$nvidiaSettingsTool = @($allTools | Where-Object { $_.Title -eq 'Nvidia Settings' })
if ($nvidiaSettingsTool.Count -ne 1) {
    throw 'Nvidia Settings must be active exactly once as the Phase 94 controlled manual-handoff tool.'
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
if ($placeholderModules.Count -ne 18) {
    throw "Expected 18 deferred/placeholders, found $($placeholderModules.Count)."
}
if (($allTools.Count - $placeholderModules.Count) -ne 37) {
    throw "Expected 37 implemented tools, found $($allTools.Count - $placeholderModules.Count)."
}

foreach ($moduleName in @($pathB | Where-Object { $_.Title -notin @('Driver Install Latest', 'Nvidia Settings', 'Hdcp', 'P0 State', 'Msi Mode') } | ForEach-Object { $_.ModuleName })) {
    if (@(Get-ChildItem -Path $modulesRoot -Recurse -Filter "$moduleName.psm1").Count -ne 0) {
        throw "Executable tool module was unexpectedly created for Path B script: $moduleName"
    }
}

$sourcePromotedFiles = @(
    Get-ChildItem -LiteralPath (Join-Path $sourceRoot '_intake-promoted\Ultimate') -Recurse -File
)
if ($sourcePromotedFiles.Count -ne 7) {
    throw "Expected 7 source-promoted intake candidates, found $($sourcePromotedFiles.Count)."
}

if (-not $driftText.Contains('Driver Clean remains outside the five-step NVIDIA Path B preview')) {
    throw 'Driver Clean is not documented as outside the five-step Path B preview.'
}
if (-not $driftText.Contains('BitLocker remains outside the five-step NVIDIA Path B preview')) {
    throw 'BitLocker is not documented as outside the five-step Path B preview.'
}

if (@($allTools | Where-Object { $_.Title -eq 'DDU' -or $_.Id -eq 'ddu' }).Count -ne 0) {
    throw 'Standalone DDU was reintroduced into active config.'
}
if (@(Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' | Where-Object { $_.BaseName -eq 'ddu' -or $_.Name -like '*DDU*' }).Count -ne 0) {
    throw 'Standalone DDU module was reintroduced.'
}
if (Test-Path -LiteralPath (Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1')) {
    throw 'Loudness EQ source was reintroduced.'
}
if (@(Get-ChildItem -Path $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }).Count -ne 0) {
    throw 'NVME Faster Driver source was reintroduced.'
}

$policyPaths = @(
    'config\ArtifactProvenance.psd1',
    'config\AppxPackagePolicy.psd1',
    'config\CleanupPolicy.psd1',
    'config\DriverStatePolicy.psd1',
    'config\NvidiaProfileStatePolicy.psd1',
    'config\ProcessHandlingPolicy.psd1',
    'config\ProductionAllowlistGovernance.psd1',
    'config\RebootRecoveryPolicy.psd1',
    'config\RollbackPolicy.psd1',
    'config\RestoreSelectionPolicy.psd1',
    'config\SafeModeRecoveryPolicy.psd1',
    'config\ServiceRollbackPolicy.psd1',
    'config\TrustedInstallerPolicy.psd1'
)
foreach ($relativePolicy in $policyPaths) {
    if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $relativePolicy) -PathType Leaf)) {
        throw "Required policy file was not found: $relativePolicy"
    }
}

$artifactPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1')
$appxPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\AppxPackagePolicy.psd1')
$cleanupPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\CleanupPolicy.psd1')
$driverPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\DriverStatePolicy.psd1')
$profilePolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\NvidiaProfileStatePolicy.psd1')
$processPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\ProcessHandlingPolicy.psd1')
$productionPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1')
$rebootPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\RebootRecoveryPolicy.psd1')
$rollbackPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\RollbackPolicy.psd1')
$restorePolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\RestoreSelectionPolicy.psd1')
$safeModePolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\SafeModeRecoveryPolicy.psd1')
$servicePolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\ServiceRollbackPolicy.psd1')
$trustedPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\TrustedInstallerPolicy.psd1')

if (
    $artifactPolicy.Artifacts.Count -ne 0 -or
    $appxPolicy.PackageScopes.Count -ne 0 -or
    $cleanupPolicy.CleanupScopes.Count -ne 0 -or
    $driverPolicy.DriverScopes.Count -ne 0 -or
    $profilePolicy.ProductionProfileScopes.Count -ne 0 -or
    $profilePolicy.ApprovedProfileOperations.Count -ne 0 -or
    $profilePolicy.ApprovedProfileInspectorArtifacts.Count -ne 0 -or
    $profilePolicy.ApprovedNipImports.Count -ne 0 -or
    $profilePolicy.ApprovedNipExports.Count -ne 0 -or
    $processPolicy.ProcessHandlingScopes.Count -ne 0 -or
    $processPolicy.ApprovedProcessTargets.Count -ne 0 -or
    $productionPolicy.ProductionAllowlistProposals.Count -ne 0 -or
    $rebootPolicy.WorkflowScopes.Count -ne 0 -or
    $rollbackPolicy.FileScopes.Count -ne 0 -or
    $rollbackPolicy.RegistryScopes.Count -ne 0 -or
    $restorePolicy.RestoreSelectionScopes.Count -ne 0 -or
    $restorePolicy.ApprovedRestoreHandlers.Count -ne 0 -or
    $safeModePolicy.SafeModeScopes.Count -ne 0 -or
    $servicePolicy.ServiceScopes.Count -ne 0 -or
    $trustedPolicy.TrustedInstallerScopes.Count -ne 0
) {
    throw 'A production scope, allowlist, artifact, profile operation, workflow, restore handler, or process target was unexpectedly approved.'
}

foreach ($item in $pathB) {
    foreach ($relative in @($item.Mirror, $item.Intake)) {
        $diskPath = Join-Path $ProjectRoot ($relative -replace '/', '\')
        if (-not (Test-Path -LiteralPath $diskPath -PathType Leaf)) {
            throw "Expected Path B file is missing: $relative"
        }
        $hash = (Get-FileHash -LiteralPath $diskPath -Algorithm SHA256).Hash
        if ($hash -ne $item.Hash) {
            throw "Path B file hash mismatch for $relative. Expected $($item.Hash), found $hash."
        }
    }
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$legacySourceLines = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
        Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
        ForEach-Object {
            $relative = $_.FullName.Substring($root.Length + 1).Replace('\', '/')
            $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
            "$relative|$hash"
        }
)
$legacySourceHash = Get-BoostLabManifestHash -Lines $legacySourceLines
if ($legacySourceLines.Count -ne 49) {
    throw "Expected 49 legacy source files outside _intake-promoted, found $($legacySourceLines.Count)."
}
if ($legacySourceHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') {
    throw "Legacy source-ultimate manifest outside _intake-promoted changed unexpectedly: $legacySourceHash"
}

[pscustomobject]@{
    Success                      = $true
    DriftDesignPath              = $driftDesignPath
    PathBOrder                   = 'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
    ActiveToolCount              = $allTools.Count
    ImplementedToolCount         = $allTools.Count - $placeholderModules.Count
    DeferredPlaceholderCount     = $placeholderModules.Count
    SourcePromotedCandidateCount = $sourcePromotedFiles.Count
    CanExecuteCurrentDesign      = $false
    RuntimeBehaviorChanged       = $false
    ProductionApprovalsAdded     = $false
    Message                      = 'NVIDIA Path B preview data integrity/drift rules design is documented and remains non-executing.'
}




