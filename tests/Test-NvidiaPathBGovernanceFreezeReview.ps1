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
        throw 'Unable to determine the NVIDIA Path B governance freeze review validator path.'
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

$freezeReviewPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-governance-freeze-review.md'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$intakeRoot = Join-Path $ProjectRoot 'intake\missing-ultimate-scripts\Ultimate'

$pathBDocuments = @(
    'docs\tool-designs\nvidia-path-b-documentation-backlink-audit-design.md'
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

foreach ($path in @($freezeReviewPath, $stagesPath)) {
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

$freezeText = Get-Content -LiteralPath $freezeReviewPath -Raw

foreach ($section in @(
    '# NVIDIA Path B Governance Freeze Review',
    '## Purpose And Status',
    '## Freeze Scope',
    '## Governance Freeze Table',
    '## Frozen Document Set',
    '## Open Blockers After Freeze',
    '## Required Future Unfreeze Conditions',
    '## Change Control Rules',
    '## Frozen Non-Execution Guarantees',
    '## Future Review Checklist',
    '## Relationship To Existing Documents',
    '## Explicit Non-Actions',
    '## Recommended Next Phase'
)) {
    Test-BoostLabTextContains -Text $freezeText -Needle $section -Description 'Governance freeze review section'
}

foreach ($phrase in @(
    'Phase 89 is governance freeze review only',
    'frozen as design-only',
    'This is not production approval',
    'This is not runtime approval',
    'This is not UI approval',
    'This is not artifact, download, or installer approval',
    'This is not driver, profile, Windows Registry, file, process, reboot, Default, or Restore approval',
    'No executable workflow is created',
    'No runtime behavior changes',
    'No tool card or placeholder is enabled',
    'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
)) {
    Test-BoostLabTextContains -Text $freezeText -Needle $phrase -Description 'Governance freeze status/order phrase'
}

foreach ($freezeItem in @(
    'Exact five-step Path B order',
    'Source mirror path bindings and expected SHA-256 values',
    'Path A vs Path B separation',
    'NVIDIA App compatibility purpose',
    'Non-executing documentation family status',
    'Non-approval status',
    '`canExecute = false` expectation',
    '`isExecutionEnabling = false` expectation',
    'Preview/catalog non-execution semantics',
    'Readiness badge meanings',
    'Path conflict copy/status wording principles',
    'Drift and fail-closed expectations',
    'Documentation index/navigation structure',
    'Backlink audit expectations',
    'Driver Clean and BitLocker outside Path B',
    'Standalone DDU absence',
    'Loudness EQ and NVME Faster Driver remain deleted'
)) {
    Test-BoostLabTextContains -Text $freezeText -Needle $freezeItem -Description 'Freeze scope item'
}

Test-BoostLabTextContains -Text $freezeText -Needle '| Governance item | Frozen value or rule | Source document | Validation expectation | Execution implication | Change requirement |' -Description 'Governance freeze table header'
$freezeTable = [regex]::Match($freezeText, '(?s)## Governance Freeze Table(.*?)## Frozen Document Set').Groups[1].Value
if ($freezeTable -match '\|\s*(Approved|Enabled)\s*\|') {
    throw 'Governance freeze table contains standalone Approved or Enabled status.'
}
foreach ($status in @('NoExecution', 'NoApproval', 'DesignOnly', 'NotImplemented', 'NotApproved')) {
    Test-BoostLabTextContains -Text $freezeTable -Needle $status -Description 'Governance freeze non-executing status'
}

foreach ($phase in 73..89) {
    if ($freezeText -notmatch "\|\s*$phase\s*\|") {
        throw "Frozen document set is missing Phase $phase."
    }
}
foreach ($validatorName in @(
    'Test-NvidiaPathBCatalogDesign.ps1',
    'Test-NvidiaPathBScopeDesign.ps1',
    'Test-NvidiaPathBProductionAllowlistPlanning.ps1',
    'Test-NvidiaPathBArtifactProvenanceReview.ps1',
    'Test-NvidiaProfileStateCaptureModel.ps1',
    'Test-NvidiaPathBUIWorkflowDesign.ps1',
    'Test-NvidiaPathBDraftAllowlistProposal.ps1',
    'Test-NvidiaPathBProductionApprovalGateDesign.ps1',
    'Test-NvidiaPathBRuntimeGatingDesign.ps1',
    'Test-NvidiaPathBNonExecutingWorkflowRegistrySchemaDesign.ps1',
    'Test-NvidiaPathBReadinessBadgeDesign.ps1',
    'Test-NvidiaPathBPathConflictCopyStatusTextDesign.ps1',
    'Test-NvidiaPathBNonExecutingCatalogPreviewDataDesign.ps1',
    'Test-NvidiaPathBPreviewDataIntegrityDriftRulesDesign.ps1',
    'Test-NvidiaPathBDocumentationIndexNavigationDesign.ps1',
    'Test-NvidiaPathBDocumentationBacklinkAuditDesign.ps1',
    'Test-NvidiaPathBGovernanceFreezeReview.ps1'
)) {
    Test-BoostLabTextContains -Text $freezeText -Needle $validatorName -Description 'Frozen document set validator'
}

foreach ($blocker in @(
    'No production approval',
    'No production allowlist entries',
    'No approved artifacts',
    'No approved downloads',
    'No approved NVIDIA driver installer',
    'No approved NVIDIA Profile Inspector execution',
    'No approved `.nip` import/export',
    'No approved profile capture runtime',
    'No approved registry rollback runtime for Path B',
    'No approved driver rollback runtime for Path B',
    'No approved process handoff runtime for Path B',
    'No approved reboot/device restart runtime for Path B',
    'No active runtime gate evaluator for Path B',
    'No active workflow registry',
    'No active UI stepper',
    'No active catalog preview',
    'No active drift checker',
    'No active backlink auditor',
    'No Default/Restore availability for Path B steps',
    'No NVIDIA-only runtime targeting implementation for Path B',
    'No Path A/Path B runtime conflict resolver'
)) {
    Test-BoostLabTextContains -Text $freezeText -Needle $blocker -Description 'Open blocker after freeze'
}

foreach ($condition in @(
    'Explicit Yazan approval for unfreezing a specific sub-area',
    'Separate phase name and scope',
    'Production allowlist update proposal',
    'Artifact provenance approval where needed',
    'Installer descriptor approval where needed',
    'Profile capture/restore implementation plan where needed',
    'Registry/file capture implementation plan where needed',
    'Driver rollback implementation plan where needed',
    'Process policy integration where needed',
    'Reboot/recovery integration where needed',
    'NVIDIA-only targeting validation where needed',
    'Path A/Path B conflict handling implementation where needed',
    'UI implementation phase if UI is involved',
    'Validators proving `canExecute` remains false until approvals exist',
    'Validators proving no deleted tools are reintroduced',
    'Validators proving standalone DDU remains absent'
)) {
    Test-BoostLabTextContains -Text $freezeText -Needle $condition -Description 'Required future unfreeze condition'
}

foreach ($rule in @(
    'Source mirror files must not be modified',
    'Checksums must not be changed silently',
    'Step order must not be changed silently',
    'Badges must not become execution-enabling silently',
    'Preview data must not become runtime-consumed silently',
    'Documentation backlinks must not imply approval',
    'Path B docs must not be used as production allowlist approval',
    'Any new Path B implementation work must start from a new explicit phase',
    'Any future tool implementation must be isolated',
    'Any future approval must be specific, not blanket'
)) {
    Test-BoostLabTextContains -Text $freezeText -Needle $rule -Description 'Change control rule'
}

foreach ($guarantee in @(
    '`canExecute` must remain false',
    '`isExecutionEnabling` must remain false',
    'No action button may be enabled',
    'No script execution path is approved',
    'No download, installer, Profile Inspector, or `.nip` path is approved',
    'No Windows Registry write path is approved',
    'No driver/profile mutation path is approved',
    'No file/process/reboot path is approved',
    'No Default/Restore path is approved',
    'No production allowlist is created'
)) {
    Test-BoostLabTextContains -Text $freezeText -Needle $guarantee -Description 'Frozen non-execution guarantee'
}

foreach ($checklistItem in @(
    'All Path B docs exist',
    'All validators pass',
    'All five source mirror checksums match',
    'Exact step order remains intact',
    'Path A/Path B separation is documented',
    'Driver Clean and BitLocker remain outside Path B',
    'Standalone DDU remains absent',
    'Loudness EQ and NVME Faster Driver remain deleted',
    'No Approved or Enabled status appears for Path B execution',
    'No production allowlist entry exists for Path B',
    'No artifact, download, installer, Profile Inspector, or `.nip` approval',
    'No runtime, UI, config, tool, or module implementation exists for Path B',
    'Counts remain unchanged',
    'Future unfreeze request has explicit phase scope'
)) {
    Test-BoostLabTextContains -Text $freezeText -Needle $checklistItem -Description 'Future review checklist item'
}

foreach ($relationshipTarget in @(
    'docs/tool-designs/nvidia-path-b-documentation-backlink-audit-design.md',
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
    'docs/nvidia-path-b-catalog-design.md',
    'docs/production-allowlist-governance.md',
    'docs/download-provenance-installer-policy.md',
    'docs/driver-state-capture-rollback.md',
    'docs/file-registry-state-capture-rollback.md',
    'docs/process-handling-policy.md',
    'docs/reboot-recovery-workflow.md',
    'docs/restore-selection-ui-runtime.md'
)) {
    Test-BoostLabTextContains -Text $freezeText -Needle $relationshipTarget -Description 'Relationship to existing document'
}

foreach ($nonAction in @(
    'No governance unfreeze performed',
    'No production approval granted',
    'No runtime approval granted',
    'No UI approval granted',
    'No artifact, download, or installer approval granted',
    'No Profile Inspector or `.nip` approval granted',
    'No driver, profile, Windows Registry, file, process, reboot, Default, or',
    'No live governance enforcement runtime implemented',
    'No active docs runtime added',
    'No active preview config created',
    'No active UI config created',
    'No active runtime config created',
    'No production config or allowlist config created or changed',
    'No executable handler/module/action created',
    'No tool or placeholder enabled',
    'No runtime behavior changed',
    'No source mirror files changed',
    'No intake files changed',
    'No legacy source-ultimate files changed',
    'No DDU execution/download/artifact approval added',
    'Standalone DDU not introduced',
    'Loudness EQ and NVME Faster Driver remain deleted',
    'Counts unchanged: 48 active tools, 30 implemented tools, 18'
)) {
    Test-BoostLabTextContains -Text $freezeText -Needle $nonAction -Description 'Explicit non-action boundary'
}

foreach ($relativeDoc in @($pathBDocuments + $deferredDocuments)) {
    $docText = Get-Content -LiteralPath (Join-Path $ProjectRoot $relativeDoc) -Raw
    if (-not $docText.Contains('docs/tool-designs/nvidia-path-b-governance-freeze-review.md')) {
        throw "Expected document does not link to the governance freeze review: $relativeDoc"
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
    'config\NvidiaPathBGovernanceFreeze.psd1',
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
        throw "Active governance, docs, preview, UI, runtime, production, or Path B allowlist config was unexpectedly created: $forbiddenPath"
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
    throw 'WPF/UI runtime files were unexpectedly modified for NVIDIA Path B governance freeze review.'
}

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })
foreach ($title in @($pathB | Where-Object { $_.Title -ne 'Driver Install Latest' } | ForEach-Object { $_.Title })) {
    if (Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Title -eq $title }) -ne 0) {
        throw "Path B source-promoted script was unexpectedly added as an active tool: $title"
    }
}
$driverInstallLatestTool = @($allTools | Where-Object { $_.Title -eq 'Driver Install Latest' })
if ($driverInstallLatestTool.Count -ne 1) {
    throw 'Driver Install Latest must be active exactly once as the Phase 93 controlled manual-handoff tool.'
}

$placeholderModules = @(
    Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' |
        Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw).Contains(
                'ToolModule.Placeholder.ps1'
            )
        }
)
if ($allTools.Count -ne 50) {
    throw "Expected 50 active tools, found $($allTools.Count)."
}
if ($placeholderModules.Count -ne 18) {
    throw "Expected 18 deferred/placeholders, found $($placeholderModules.Count)."
}
if (($allTools.Count - $placeholderModules.Count) -ne 32) {
    throw "Expected 32 implemented tools, found $($allTools.Count - $placeholderModules.Count)."
}

foreach ($moduleName in @($pathB | ForEach-Object { $_.ModuleName })) {
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
    GovernanceFreezeReviewPath   = $freezeReviewPath
    PathBOrder                   = 'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
    BacklinkedDocumentCount      = $pathBDocuments.Count + $deferredDocuments.Count
    ActiveToolCount              = $allTools.Count
    ImplementedToolCount         = $allTools.Count - $placeholderModules.Count
    DeferredPlaceholderCount     = $placeholderModules.Count
    SourcePromotedCandidateCount = $sourcePromotedFiles.Count
    RuntimeBehaviorChanged       = $false
    ProductionApprovalsAdded     = $false
    Message                      = 'NVIDIA Path B governance freeze review is documented and remains non-executing.'
}
