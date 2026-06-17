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
        throw 'Unable to determine the NVIDIA Path B documentation index/navigation design validator path.'
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

$indexDesignPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-documentation-index-navigation-design.md'
$pathBDocuments = @(
    'docs\nvidia-path-b-catalog-design.md'
    'docs\tool-designs\nvidia-path-b-scope-design.md'
    'docs\tool-designs\nvidia-path-b-production-allowlist-planning.md'
    'docs\tool-designs\nvidia-path-b-artifact-provenance-review.md'
    'docs\nvidia-profile-state-capture-model.md'
    'docs\nvidia-path-b-ui-workflow-design.md'
    'docs\tool-designs\nvidia-path-b-draft-allowlist-proposal.md'
    'docs\tool-designs\nvidia-path-b-production-approval-gate-design.md'
    'docs\tool-designs\nvidia-path-b-runtime-gating-design.md'
    'docs\tool-designs\nvidia-path-b-non-executing-workflow-registry-schema-design.md'
    'docs\tool-designs\nvidia-path-b-readiness-badge-design.md'
    'docs\tool-designs\nvidia-path-b-path-conflict-copy-status-text-design.md'
    'docs\tool-designs\nvidia-path-b-non-executing-catalog-preview-data-design.md'
    'docs\tool-designs\nvidia-path-b-preview-data-integrity-drift-rules-design.md'
)
$matrixPath = Join-Path $ProjectRoot 'docs\final-deferred-tools-readiness-matrix.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$reviewPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$intakeRoot = Join-Path $ProjectRoot 'intake\missing-ultimate-scripts\Ultimate'

foreach ($path in @($indexDesignPath, $matrixPath, $planPath, $reviewPath, $stagesPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file was not found: $path"
    }
}
foreach ($relativeDoc in $pathBDocuments) {
    $docPath = Join-Path $ProjectRoot $relativeDoc
    if (-not (Test-Path -LiteralPath $docPath -PathType Leaf)) {
        throw "Required NVIDIA Path B document was not found: $relativeDoc"
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

$indexText = Get-Content -LiteralPath $indexDesignPath -Raw

foreach ($section in @(
    '# NVIDIA Path B Documentation Index And Navigation Design',
    '## Purpose And Status',
    '## Documentation Set Overview',
    '## Navigation Goals',
    '## Documentation Index Table',
    '## Document Dependency Graph',
    '## Reader Paths',
    '## Cross-Reference Rules',
    '## Navigation Metadata Design',
    '## Review Checklist',
    '## Future Navigation Activation Path',
    '## Explicit Non-Actions',
    '## Recommended Next Phase'
)) {
    if (-not $indexText.Contains($section)) {
        throw "Documentation index/navigation design is missing section: $section"
    }
}

foreach ($phrase in @(
    'This is documentation index and navigation design only',
    'This is not live UI navigation',
    'This is not runtime navigation',
    'No active docs runtime, app catalog, preview config, or workflow registry is enabled',
    'No UI implementation is added',
    'No runtime behavior changes',
    'No tool card or placeholder is enabled',
    'No executable workflow is created',
    'No production approval is granted',
    'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
)) {
    if (-not $indexText.Contains($phrase)) {
        throw "Required index/navigation status or order phrase is missing: $phrase"
    }
}

foreach ($phase in 73..87) {
    if (-not $indexText.Contains("Phase $($phase):")) {
        throw "Documentation set overview is missing Phase $phase."
    }
}

foreach ($goal in @(
    'Give maintainers one entry point for Path B docs',
    'Preserve phase order',
    'Show dependency order',
    'Show which docs are design-only',
    'Show which docs are gating/governance docs',
    'Show which docs are future UI/docs/reference docs',
    'Show which docs are future runtime prerequisites',
    'Show which docs block execution',
    'Show that no current Path B doc enables execution',
    'Show counts remain unchanged',
    'Show Driver Clean and BitLocker remain out of Path B',
    'Show standalone DDU remains absent',
    'Show Loudness EQ and NVME Faster Driver remain deleted'
)) {
    if (-not $indexText.Contains($goal)) {
        throw "Navigation goal is missing: $goal"
    }
}

if (-not $indexText.Contains('| phase | document title | file path | document role | depends on | feeds into | execution status | approval status | runtime impact | UI impact | source impact | current validator |')) {
    throw 'Documentation index table header is missing.'
}

$tableBlock = [regex]::Match($indexText, '(?s)## Documentation Index Table(.*?)## Document Dependency Graph').Groups[1].Value
if ($tableBlock -match '\|\s*(Approved|Enabled)\s*\|') {
    throw 'Documentation index table contains Approved or Enabled as a status.'
}
foreach ($status in @('DesignOnly', 'NonExecuting', 'NotImplemented', 'NotApproved')) {
    if (-not $tableBlock.Contains($status)) {
        throw "Documentation index table is missing non-executing status: $status"
    }
}

foreach ($graphPhrase in @(
    'Catalog -> Scope -> Allowlist Planning -> Artifact Provenance -> Profile State Model',
    'UI Workflow -> Draft Allowlist -> Production Approval Gate',
    'Runtime Gating -> Non-Executing Workflow Registry Schema',
    'Readiness Badges -> Path Conflict Copy/Status Text',
    'Catalog Preview Data -> Preview Data Integrity/Drift Rules',
    'Documentation Index/Navigation as the navigation layer'
)) {
    if (-not $indexText.Contains($graphPhrase)) {
        throw "Document dependency graph/map is missing: $graphPhrase"
    }
}

foreach ($readerPath in @(
    'Maintainer trying to understand Path B from scratch',
    'Future implementer preparing a runtime gate evaluator',
    'Future UI designer preparing Path B stepper/preview/badges',
    'Future security reviewer reviewing downloads/installers/Profile Inspector/.nip/profile/registry changes',
    'Future tester/validator author',
    'Future reviewer checking why Path B cannot execute today',
    'Future reviewer checking Path A vs Path B conflict handling'
)) {
    if (-not $indexText.Contains($readerPath)) {
        throw "Reader path is missing: $readerPath"
    }
}

foreach ($rule in @(
    'Each Path B design doc should link to the index/navigation design once',
    'Docs that define gates should link to readiness badges and copy/status text',
    'Docs that define preview data should link to integrity/drift rules',
    'Docs that define UI concepts should link to runtime gating and workflow',
    'Docs must distinguish Path B from Driver Clean and BitLocker',
    'Docs must not imply approval, enablement, or runtime execution unless a future'
)) {
    if (-not $indexText.Contains($rule)) {
        throw "Cross-reference rule is missing: $rule"
    }
}

foreach ($field in @(
    'docId',
    'phase',
    'title',
    'path',
    'role',
    'status',
    'approvalStatus',
    'executionImpact',
    'runtimeImpact',
    'uiImpact',
    'sourceImpact',
    'dependencies',
    'downstreamReferences',
    'relatedSourceFiles',
    'relatedValidators',
    'ownerArea',
    'lastReviewedPhase',
    'nextReviewTrigger',
    'nonExecutionGuarantee'
)) {
    if (-not $indexText.Contains(('`' + $field + '`'))) {
        throw "Navigation metadata design field is missing: $field"
    }
}
if (-not $indexText.Contains('This is metadata design only, not a live metadata registry')) {
    throw 'Navigation metadata design does not state it is not live metadata.'
}

foreach ($check in @(
    'all Path B docs exist',
    'phase order is correct',
    'source checksums match',
    'all five Path B steps are referenced in exact order',
    'Path A vs Path B distinction is visible',
    'Driver Clean and BitLocker are out of Path B',
    'all current docs state non-execution/no approval where appropriate',
    'no doc claims Approved or Enabled for Path B execution',
    'no doc implies production allowlist exists',
    'no doc implies artifact/download/installer/Profile Inspector/.nip approval',
    'no doc implies Default/Restore is available without capture',
    'validators cover the current document set',
    'counts remain 48/30/18 and 7 source-promoted intake candidates'
)) {
    if (-not $indexText.Contains($check)) {
        throw "Review checklist item is missing: $check"
    }
}

foreach ($activation in @(
    'explicit UI phase',
    'read-only docs/catalog integration approval',
    'non-executing metadata source',
    'validator confirming no action button enablement',
    'runtime gate checks still deny execution',
    'localization plan if exposed to users',
    'review that source mirror files remain unchanged',
    'review that counts remain separated'
)) {
    if (-not $indexText.Contains($activation)) {
        throw "Future navigation activation path item is missing: $activation"
    }
}

foreach ($nonAction in @(
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
    'Counts unchanged'
)) {
    if (-not $indexText.Contains($nonAction)) {
        throw "Explicit non-action boundary is missing: $nonAction"
    }
}

foreach ($relativeDoc in $pathBDocuments) {
    $docPath = Join-Path $ProjectRoot $relativeDoc
    $docText = Get-Content -LiteralPath $docPath -Raw
    if (-not $docText.Contains('docs/tool-designs/nvidia-path-b-documentation-index-navigation-design.md')) {
        throw "Expected prior NVIDIA Path B document does not link to the documentation index/navigation design: $relativeDoc"
    }
}
foreach ($linkedPath in @($matrixPath, $planPath, $reviewPath)) {
    $linkedText = Get-Content -LiteralPath $linkedPath -Raw
    if (-not $linkedText.Contains('docs/tool-designs/nvidia-path-b-documentation-index-navigation-design.md')) {
        throw "Expected deferred/readiness document does not link to the documentation index/navigation design: $linkedPath"
    }
}

foreach ($forbiddenPath in @(
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
        throw "Active docs, preview, UI, runtime, production, or Path B allowlist config was unexpectedly created: $forbiddenPath"
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
    throw 'WPF/UI runtime files were unexpectedly modified for NVIDIA Path B documentation navigation.'
}

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })
foreach ($title in @($pathB | Where-Object { $_.Title -notin @('Driver Install Latest', 'Nvidia Settings', 'Hdcp', 'P0 State') } | ForEach-Object { $_.Title })) {
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

if (-not $indexText.Contains('Driver Clean remains outside the five-step NVIDIA Path B workflow')) {
    throw 'Driver Clean is not documented as outside the five-step Path B workflow.'
}
if (-not $indexText.Contains('BitLocker remains outside the five-step NVIDIA Path B workflow')) {
    throw 'BitLocker is not documented as outside the five-step Path B workflow.'
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
    IndexDesignPath              = $indexDesignPath
    PathBOrder                   = 'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
    PathBDocumentCount           = $pathBDocuments.Count + 1
    ActiveToolCount              = $allTools.Count
    ImplementedToolCount         = $allTools.Count - $placeholderModules.Count
    DeferredPlaceholderCount     = $placeholderModules.Count
    SourcePromotedCandidateCount = $sourcePromotedFiles.Count
    RuntimeBehaviorChanged       = $false
    ProductionApprovalsAdded     = $false
    Message                      = 'NVIDIA Path B documentation index/navigation design is documented and remains non-executing.'
}



