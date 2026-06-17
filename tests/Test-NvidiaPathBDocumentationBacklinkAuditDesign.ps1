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
        throw 'Unable to determine the NVIDIA Path B documentation backlink audit design validator path.'
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

function Test-BoostLabTextContains {
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [string]$Needle,

        [Parameter(Mandatory)]
        [string]$Description
    )

    if (-not $Text.Contains($Needle)) {
        throw "$Description is missing: $Needle"
    }
}

function Get-BoostLabItemCount {
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return 0
    }

    return @($Value).Count
}

$auditDesignPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-documentation-backlink-audit-design.md'
$indexDesignPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-documentation-index-navigation-design.md'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$intakeRoot = Join-Path $ProjectRoot 'intake\missing-ultimate-scripts\Ultimate'

$pathBDocuments = @(
    'docs\tool-designs\nvidia-path-b-documentation-index-navigation-design.md'
    'docs\tool-designs\nvidia-path-b-preview-data-integrity-drift-rules-design.md'
    'docs\tool-designs\nvidia-path-b-non-executing-catalog-preview-data-design.md'
    'docs\tool-designs\nvidia-path-b-path-conflict-copy-status-text-design.md'
    'docs\tool-designs\nvidia-path-b-readiness-badge-design.md'
    'docs\tool-designs\nvidia-path-b-runtime-gating-design.md'
    'docs\tool-designs\nvidia-path-b-non-executing-workflow-registry-schema-design.md'
    'docs\tool-designs\nvidia-path-b-production-approval-gate-design.md'
    'docs\tool-designs\nvidia-path-b-draft-allowlist-proposal.md'
    'docs\nvidia-path-b-ui-workflow-design.md'
    'docs\nvidia-profile-state-capture-model.md'
    'docs\tool-designs\nvidia-path-b-artifact-provenance-review.md'
    'docs\tool-designs\nvidia-path-b-production-allowlist-planning.md'
    'docs\tool-designs\nvidia-path-b-scope-design.md'
    'docs\nvidia-path-b-catalog-design.md'
)

$deferredDocuments = @(
    'docs\final-deferred-tools-readiness-matrix.md'
    'docs\deferred-tools-execution-plan.md'
    'docs\deferred-tool-readiness-review.md'
)

foreach ($path in @($auditDesignPath, $indexDesignPath, $stagesPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file was not found: $path"
    }
}
foreach ($path in @($modulesRoot, $sourceRoot, $intakeRoot)) {
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        throw "Required folder was not found: $path"
    }
}
foreach ($relativeDoc in @($pathBDocuments + $deferredDocuments)) {
    if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $relativeDoc) -PathType Leaf)) {
        throw "Required NVIDIA Path B or deferred document was not found: $relativeDoc"
    }
}

$auditText = Get-Content -LiteralPath $auditDesignPath -Raw

foreach ($section in @(
    '# NVIDIA Path B Documentation Backlink Audit Design',
    '## Purpose And Status',
    '## Backlink Audit Concepts',
    '## Required Backlink Classes',
    '## Backlink Matrix',
    '## Backlink Risk Categories',
    '## Backlink Audit Rules',
    '## Future Backlink Audit Report Schema',
    '## Future Validator Design',
    '## Relationship To Existing Documents',
    '## Explicit Non-Actions',
    '## Recommended Next Phase'
)) {
    Test-BoostLabTextContains -Text $auditText -Needle $section -Description 'Backlink audit design section'
}

foreach ($phrase in @(
    'This is documentation backlink audit design only',
    'This is not live UI navigation',
    'This is not runtime navigation',
    'No live backlink auditor is implemented',
    'No active docs runtime, app catalog, preview config, or workflow registry is enabled',
    'No UI implementation is added',
    'No runtime behavior changes',
    'No tool card or placeholder is enabled',
    'No executable workflow is created',
    'No production approval is granted',
    'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
)) {
    Test-BoostLabTextContains -Text $auditText -Needle $phrase -Description 'Backlink audit status/order phrase'
}

foreach ($phase in 73..88) {
    if ($auditText -notmatch "Phase\s+$phase\b") {
        throw "Backlink matrix or relationship text is missing Phase $phase."
    }
}

foreach ($concept in @(
    'index backlink',
    'upstream dependency backlink',
    'downstream consumer backlink',
    'sibling document backlink',
    'governance backlink',
    'validator backlink',
    'source mirror backlink',
    'out-of-scope boundary backlink',
    'non-execution guarantee backlink',
    'approval status backlink',
    'runtime gate backlink',
    'badge/status text backlink',
    'preview/integrity backlink',
    'stale backlink',
    'missing backlink',
    'incorrect backlink',
    'unsafe backlink implication'
)) {
    Test-BoostLabTextContains -Text $auditText -Needle $concept -Description 'Backlink audit concept'
}

foreach ($requiredClass in @(
    'Every Path B document should link to the documentation index/navigation',
    'Every Path B document should link to its direct upstream dependency',
    'Every Path B document should link to downstream docs that consume it',
    'Gate documents should link to readiness badges and copy/status text docs',
    'Preview data docs should link to integrity/drift rules',
    'UI workflow docs should link to runtime gating and non-executing workflow',
    'Approval/gate docs should link to production allowlist governance',
    'Artifact/provenance docs should link to download provenance and installer',
    'Profile/state docs should link to restore selection and rollback foundations',
    'Docs touching registry concepts must link to file/registry state capture',
    'Docs mentioning process/reboot concepts must link to process handling',
    'All docs must preserve links or explicit notes that Driver Clean and BitLocker',
    'All docs must preserve non-execution/no-approval wording'
)) {
    Test-BoostLabTextContains -Text $auditText -Needle $requiredClass -Description 'Required backlink class'
}

Test-BoostLabTextContains -Text $auditText -Needle '| source document | required backlink target | backlink type | reason | required wording or section expectation | current status | future validator expectation |' -Description 'Backlink matrix header'
Test-BoostLabTextContains -Text $auditText -Needle 'The matrix covers phases 73 through 88 and remains non-executing.' -Description 'Backlink matrix coverage statement'

foreach ($risk in @(
    'MissingIndexBacklink',
    'MissingUpstreamBacklink',
    'MissingDownstreamBacklink',
    'MissingGovernanceBacklink',
    'MissingValidatorBacklink',
    'MissingBoundaryBacklink',
    'MissingNonExecutionBacklink',
    'StaleBacklink',
    'MisleadingBacklink',
    'UnsafeApprovalImplication',
    'UnsafeExecutionImplication'
)) {
    Test-BoostLabTextContains -Text $auditText -Needle $risk -Description 'Backlink risk category'
}
Test-BoostLabTextContains -Text $auditText -Needle 'must be critical' -Description 'Critical backlink risk rule'

foreach ($rule in @(
    'Backlinks must not imply approval',
    'Backlinks must not imply enablement',
    'Backlinks must not imply executable workflow exists',
    'Backlinks must not convert design docs into runtime docs',
    'Links to source mirror files are reference-only',
    'Links to DDU-related Driver Clean context must not introduce standalone DDU',
    'Links must not imply Loudness EQ or NVME Faster Driver are restored',
    'Broken or stale references require review before future activation',
    'Any document that mentions Default/Restore must preserve the Default vs',
    'Any document that mentions Path A/Path B must preserve'
)) {
    Test-BoostLabTextContains -Text $auditText -Needle $rule -Description 'Backlink audit rule'
}

foreach ($field in @(
    'reportId',
    'reviewedAt',
    'reviewedBy',
    'documentSetVersion',
    'sourceDocuments',
    'requiredBacklinkTargets',
    'backlinkResults',
    'missingBacklinks',
    'staleBacklinks',
    'misleadingBacklinks',
    'unsafeApprovalImplications',
    'unsafeExecutionImplications',
    'boundaryCoverageResults',
    'nonExecutionCoverageResults',
    'validatorCoverageResults',
    'highestSeverity',
    'canUseDocumentationIndex',
    'canExposeNavigation',
    'recommendedAction',
    'activityLogEvent'
)) {
    Test-BoostLabTextContains -Text $auditText -Needle ('`' + $field + '`') -Description 'Future backlink audit report schema field'
}
Test-BoostLabTextContains -Text $auditText -Needle 'This phase does not implement the report object.' -Description 'Report schema non-implementation statement'

foreach ($validatorExpectation in @(
    'all Path B docs exist',
    'every doc links or references the index/navigation design',
    'direct upstream dependencies are referenced',
    'direct downstream consumers are referenced where appropriate',
    'governance/foundation docs are referenced when concepts appear',
    'validator files are referenced or discoverable',
    'Driver Clean and BitLocker remain outside Path B',
    'source mirror references remain reference-only',
    'no backlink text contains Approved or Enabled for Path B execution',
    'no backlink text implies production allowlist exists',
    'no backlink text implies artifact/download/installer/Profile Inspector/.nip',
    'no backlink text implies Default/Restore availability without capture',
    'all counts remain separated'
)) {
    Test-BoostLabTextContains -Text $auditText -Needle $validatorExpectation -Description 'Future validator design expectation'
}

foreach ($relativeDoc in @($pathBDocuments + $deferredDocuments)) {
    $docText = Get-Content -LiteralPath (Join-Path $ProjectRoot $relativeDoc) -Raw
    if (-not $docText.Contains('docs/tool-designs/nvidia-path-b-documentation-backlink-audit-design.md')) {
        throw "Expected document does not link to the backlink audit design: $relativeDoc"
    }
}

foreach ($relationshipTarget in @(
    'docs/tool-designs/nvidia-path-b-documentation-index-navigation-design.md',
    'docs/tool-designs/nvidia-path-b-preview-data-integrity-drift-rules-design.md',
    'docs/tool-designs/nvidia-path-b-non-executing-catalog-preview-data-design.md',
    'docs/tool-designs/nvidia-path-b-path-conflict-copy-status-text-design.md',
    'docs/tool-designs/nvidia-path-b-readiness-badge-design.md',
    'docs/tool-designs/nvidia-path-b-runtime-gating-design.md',
    'docs/tool-designs/nvidia-path-b-non-executing-workflow-registry-schema-design.md',
    'docs/tool-designs/nvidia-path-b-production-approval-gate-design.md',
    'docs/tool-designs/nvidia-path-b-draft-allowlist-proposal.md',
    'docs/nvidia-path-b-ui-workflow-design.md',
    'docs/nvidia-profile-state-capture-model.md',
    'docs/tool-designs/nvidia-path-b-artifact-provenance-review.md',
    'docs/tool-designs/nvidia-path-b-production-allowlist-planning.md',
    'docs/tool-designs/nvidia-path-b-scope-design.md',
    'docs/nvidia-path-b-catalog-design.md'
)) {
    Test-BoostLabTextContains -Text $auditText -Needle $relationshipTarget -Description 'Relationship to existing Path B document'
}

foreach ($nonAction in @(
    'No live backlink auditor implemented',
    'No live UI navigation implemented',
    'No active docs runtime added',
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
    'Counts unchanged: 48 active tools, 30 implemented tools, 18'
)) {
    Test-BoostLabTextContains -Text $auditText -Needle $nonAction -Description 'Backlink audit non-action boundary'
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

foreach ($forbiddenPath in @(
    'config\NvidiaPathBBacklinkAudit.psd1',
    'config\NvidiaPathBDocumentationBacklinks.psd1',
    'config\NvidiaPathBDocumentationIndex.psd1',
    'config\NvidiaPathBDocsNavigation.psd1',
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
        throw "Active docs, preview, UI, runtime, production, Path B, or backlink audit config was unexpectedly created: $forbiddenPath"
    }
}

if (Get-BoostLabItemCount -Value (Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'core') -Filter '*NvidiaPathB*.psm1' -ErrorAction SilentlyContinue) -ne 0) {
    throw 'Runtime module or executable helper was unexpectedly created for NVIDIA Path B.'
}

$uiFilesWithPathB = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'ui') -Recurse -File |
        Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw) -match 'Driver Install Latest|Nvidia Settings|Hdcp|P0 State|Msi Mode|nvidia-path-b|PathConflict|NVIDIA App Compatible'
        }
)
if ($uiFilesWithPathB.Count -ne 0) {
    throw 'WPF/UI runtime files were unexpectedly modified for NVIDIA Path B documentation backlink audit design.'
}

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })
foreach ($title in @($pathB | Where-Object { $_.Title -notin @('Driver Install Latest', 'Nvidia Settings', 'Hdcp', 'P0 State') } | ForEach-Object { $_.Title })) {
    if (Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Title -eq $title }) -ne 0) {
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
if ($allTools.Count -ne 53) {
    throw "Expected 53 active tools, found $($allTools.Count)."
}
if ($placeholderModules.Count -ne 18) {
    throw "Expected 18 deferred/placeholders, found $($placeholderModules.Count)."
}
if (($allTools.Count - $placeholderModules.Count) -ne 35) {
    throw "Expected 35 implemented tools, found $($allTools.Count - $placeholderModules.Count)."
}

foreach ($moduleName in @($pathB | Where-Object { $_.Title -notin @('Driver Install Latest', 'Nvidia Settings', 'Hdcp', 'P0 State') } | ForEach-Object { $_.ModuleName })) {
    if (Get-BoostLabItemCount -Value (Get-ChildItem -Path $modulesRoot -Recurse -Filter "$moduleName.psm1" -ErrorAction SilentlyContinue) -ne 0) {
        throw "Executable tool module was unexpectedly created for Path B script: $moduleName"
    }
}

$sourcePromotedFiles = @(
    Get-ChildItem -LiteralPath (Join-Path $sourceRoot '_intake-promoted\Ultimate') -Recurse -File
)
if ($sourcePromotedFiles.Count -ne 7) {
    throw "Expected 7 source-promoted intake candidates, found $($sourcePromotedFiles.Count)."
}

foreach ($boundary in @(
    'Driver Clean remains outside the five-step NVIDIA Path B workflow',
    'BitLocker remains outside the five-step NVIDIA Path B workflow',
    'Standalone DDU not introduced',
    'Loudness EQ and NVME Faster Driver remain deleted'
)) {
    Test-BoostLabTextContains -Text $auditText -Needle $boundary -Description 'Boundary statement'
}

if (Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Title -eq 'DDU' -or $_.Id -eq 'ddu' }) -ne 0) {
    throw 'Standalone DDU was reintroduced into active config.'
}
if (Get-BoostLabItemCount -Value (Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' | Where-Object { $_.BaseName -eq 'ddu' -or $_.Name -like '*DDU*' }) -ne 0) {
    throw 'Standalone DDU module was reintroduced.'
}
if (Test-Path -LiteralPath (Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1')) {
    throw 'Loudness EQ source was reintroduced.'
}
if (Get-BoostLabItemCount -Value (Get-ChildItem -Path $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }) -ne 0) {
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
    (Get-BoostLabItemCount -Value $artifactPolicy.Artifacts) -ne 0 -or
    (Get-BoostLabItemCount -Value $appxPolicy.PackageScopes) -ne 0 -or
    (Get-BoostLabItemCount -Value $cleanupPolicy.CleanupScopes) -ne 0 -or
    (Get-BoostLabItemCount -Value $driverPolicy.DriverScopes) -ne 0 -or
    (Get-BoostLabItemCount -Value $profilePolicy.ProductionProfileScopes) -ne 0 -or
    (Get-BoostLabItemCount -Value $profilePolicy.ApprovedProfileOperations) -ne 0 -or
    (Get-BoostLabItemCount -Value $profilePolicy.ApprovedProfileInspectorArtifacts) -ne 0 -or
    (Get-BoostLabItemCount -Value $profilePolicy.ApprovedNipImports) -ne 0 -or
    (Get-BoostLabItemCount -Value $profilePolicy.ApprovedNipExports) -ne 0 -or
    (Get-BoostLabItemCount -Value $processPolicy.ProcessHandlingScopes) -ne 0 -or
    (Get-BoostLabItemCount -Value $processPolicy.ApprovedProcessTargets) -ne 0 -or
    (Get-BoostLabItemCount -Value $productionPolicy.ProductionAllowlistProposals) -ne 0 -or
    (Get-BoostLabItemCount -Value $rebootPolicy.WorkflowScopes) -ne 0 -or
    (Get-BoostLabItemCount -Value $rollbackPolicy.FileScopes) -ne 0 -or
    (Get-BoostLabItemCount -Value $rollbackPolicy.RegistryScopes) -ne 0 -or
    (Get-BoostLabItemCount -Value $restorePolicy.RestoreSelectionScopes) -ne 0 -or
    (Get-BoostLabItemCount -Value $restorePolicy.ApprovedRestoreHandlers) -ne 0 -or
    (Get-BoostLabItemCount -Value $safeModePolicy.SafeModeScopes) -ne 0 -or
    (Get-BoostLabItemCount -Value $servicePolicy.ServiceScopes) -ne 0 -or
    (Get-BoostLabItemCount -Value $trustedPolicy.TrustedInstallerScopes) -ne 0
) {
    throw 'A production scope, allowlist, artifact, profile operation, workflow, restore handler, or process target was unexpectedly approved.'
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
    BacklinkAuditDesignPath      = $auditDesignPath
    PathBOrder                   = 'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
    BacklinkedDocumentCount      = $pathBDocuments.Count + $deferredDocuments.Count
    ActiveToolCount              = $allTools.Count
    ImplementedToolCount         = $allTools.Count - $placeholderModules.Count
    DeferredPlaceholderCount     = $placeholderModules.Count
    SourcePromotedCandidateCount = $sourcePromotedFiles.Count
    RuntimeBehaviorChanged       = $false
    ProductionApprovalsAdded     = $false
    Message                      = 'NVIDIA Path B documentation backlink audit design is documented and remains non-executing.'
}



