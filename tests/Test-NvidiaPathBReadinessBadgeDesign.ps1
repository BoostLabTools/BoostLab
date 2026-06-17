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
        throw 'Unable to determine the NVIDIA Path B readiness badge design validator path.'
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

foreach ($path in @($badgeDesignPath, $runtimeGatingPath, $schemaDesignPath, $uiDesignPath, $catalogPath, $matrixPath, $planPath, $reviewPath, $stagesPath)) {
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

$badgeText = Get-Content -LiteralPath $badgeDesignPath -Raw

foreach ($section in @(
    '# NVIDIA Path B Readiness Badge Design',
    '## Purpose And Status',
    '## Badge Taxonomy',
    '## Badge State Rules',
    '## Badge-To-Gate Mapping',
    '## Per-Step Readiness Badge Plan',
    '## Workflow-Level Badge Plan',
    '## Future UI Display Rules',
    '## Future Structured Badge Model',
    '## Relationship To Existing Documents',
    '## Explicit Non-Actions',
    '## Recommended Next Phase'
)) {
    if (-not $badgeText.Contains($section)) {
        throw "Readiness badge design document is missing section: $section"
    }
}

foreach ($phrase in @(
    'This is readiness badge design only',
    'No live UI badge implementation is added',
    'No runtime behavior changes',
    'No tool card or placeholder is enabled',
    'No executable workflow is created',
    'No production approval is granted',
    'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode',
    'Path A: `Driver Install Debloat & Settings`',
    'Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`'
)) {
    if (-not $badgeText.Contains($phrase)) {
        throw "Required badge design status or path phrase is missing: $phrase"
    }
}

foreach ($badge in @(
    'DesignOnly',
    'NotImplemented',
    'SourcePromoted',
    'CatalogOnly',
    'ScopeDesigned',
    'NeedsProvenance',
    'NeedsAllowlist',
    'NeedsApprovalGate',
    'NeedsRuntimeGate',
    'NeedsProfileCapture',
    'NeedsRegistryRollback',
    'NeedsDriverRollback',
    'NeedsProcessPolicy',
    'NeedsRebootPolicy',
    'NeedsNvidiaTargeting',
    'NeedsSecurityReview',
    'Blocked',
    'PathConflict',
    'NotApplicable',
    'ReadyForReview',
    'ReadyInFuturePhase',
    'RestoreUnavailable',
    'RestoreDenied',
    'DefaultUnavailable',
    'CompletedInFuture',
    'FailedInFuture',
    'RefusedInFuture'
)) {
    if (-not $badgeText.Contains(('`' + $badge + '`'))) {
        throw "Badge taxonomy is missing badge: $badge"
    }
}

foreach ($rule in @(
    'A badge is informational unless future runtime explicitly consumes it',
    '`ReadyInFuturePhase` must not mean executable now',
    '`CompletedInFuture`, `FailedInFuture`, and `RefusedInFuture` are future result states only',
    '`RestoreUnavailable` and `RestoreDenied` must not be hidden silently',
    '`DefaultUnavailable` must not be confused with Restore',
    'Path B badges must respect exact step order',
    'Path A/Path B conflict badges must be visible when applicable',
    'Missing production approval must show a blocking badge',
    'Missing source checksum validation must show a blocking badge',
    'Missing NVIDIA-only targeting must show a blocking badge',
    'AMD/Intel GPU-specific behavior must be shown as unsupported for Path B'
)) {
    if (-not $badgeText.Contains($rule)) {
        throw "Badge state rule is missing: $rule"
    }
}

if (-not $badgeText.Contains('| Badge | Related gate category | Triggering condition | User-facing message summary | Blocking or informational | Required future foundation | Current Path B status |')) {
    throw 'Badge-to-gate mapping table header is missing.'
}

foreach ($mapping in @(
    '`NeedsProvenance` | Artifact provenance gate',
    '`NeedsProfileCapture` | Profile capture gate',
    '`NeedsRegistryRollback` | Registry rollback gate',
    '`NeedsNvidiaTargeting` | NVIDIA-only targeting gate',
    '`PathConflict` | Path A/Path B mutual exclusion gate',
    '`RestoreDenied` | Restore Selection gate'
)) {
    if (-not $badgeText.Contains($mapping)) {
        throw "Badge-to-gate mapping row is missing: $mapping"
    }
}

$stepRequirements = @(
    @{
        Heading = '### Driver Install Latest'
        Badges = @('NotImplemented', 'SourcePromoted', 'NeedsProvenance', 'NeedsAllowlist', 'NeedsDriverRollback', 'NeedsProcessPolicy', 'NeedsRebootPolicy', 'NeedsApprovalGate')
    }
    @{
        Heading = '### Nvidia Settings'
        Badges = @('NotImplemented', 'SourcePromoted', 'NeedsProvenance', 'NeedsAllowlist', 'NeedsProfileCapture', 'NeedsRegistryRollback', 'NeedsProcessPolicy', 'NeedsApprovalGate')
    }
    @{
        Heading = '### Hdcp'
        Badges = @('NotImplemented', 'SourcePromoted', 'NeedsAllowlist', 'NeedsRegistryRollback', 'NeedsNvidiaTargeting', 'NeedsSecurityReview', 'NeedsApprovalGate')
    }
    @{
        Heading = '### P0 State'
        Badges = @('NotImplemented', 'SourcePromoted', 'NeedsAllowlist', 'NeedsRegistryRollback', 'NeedsNvidiaTargeting', 'NeedsSecurityReview', 'NeedsApprovalGate')
    }
    @{
        Heading = '### Msi Mode'
        Badges = @('NotImplemented', 'SourcePromoted', 'NeedsAllowlist', 'NeedsRegistryRollback', 'NeedsNvidiaTargeting', 'NeedsRebootPolicy', 'NeedsApprovalGate')
    }
)

foreach ($requirement in $stepRequirements) {
    if (-not $badgeText.Contains($requirement.Heading)) {
        throw "Per-step badge section is missing: $($requirement.Heading)"
    }
    $start = $badgeText.IndexOf($requirement.Heading)
    $nextHeading = $badgeText.IndexOf('### ', $start + $requirement.Heading.Length)
    $sectionText = if ($nextHeading -ge 0) {
        $badgeText.Substring($start, $nextHeading - $start)
    }
    else {
        $badgeText.Substring($start)
    }
    foreach ($badge in $requirement.Badges) {
        if (-not $sectionText.Contains(('`' + $badge + '`'))) {
            throw "$($requirement.Heading) is missing current badge: $badge"
        }
    }
}

foreach ($workflowBadge in @(
    'DesignOnly',
    'CatalogOnly',
    'SourcePromoted',
    'NotImplemented',
    'Blocked',
    'PathConflict',
    'NeedsRuntimeGate',
    'NeedsApprovalGate',
    'NeedsAllowlist',
    'RestoreUnavailable'
)) {
    if (-not $badgeText.Contains(('`' + $workflowBadge + '`'))) {
        throw "Workflow-level badge plan is missing badge: $workflowBadge"
    }
}
if (-not $badgeText.Contains('Path B workflow-level `canExecute` remains false')) {
    throw 'Workflow-level canExecute=false rule is missing.'
}

foreach ($uiRule in @(
    'Badges should be short and readable',
    'Advanced details should be available through expanded details',
    'Badge color/icon choices must be finalized in a later visual UI design phase',
    'Badge text must not imply readiness to execute unless execution is truly approved later',
    'Blockers should be shown before action buttons',
    'Disabled action buttons should explain which badges block them',
    'Path B ordered stepper should show badge clusters per step',
    'Beginner users should see plain-language summaries',
    'Advanced users should see source/gate/approval details'
)) {
    if (-not $badgeText.Contains($uiRule)) {
        throw "Future UI display rule is missing: $uiRule"
    }
}

foreach ($field in @(
    'badgeId',
    'badgeLabel',
    'badgeCategory',
    'severity',
    'isBlocking',
    'relatedGate',
    'relatedApproval',
    'relatedFoundation',
    'userMessage',
    'adminMessage',
    'stepId',
    'workflowId',
    'sourceChecksum',
    'statusReason',
    'nextResolutionAction',
    'documentationReference',
    'canClearAutomatically',
    'requiresFutureApproval',
    'isExecutionEnabling'
)) {
    if (-not $badgeText.Contains(('`' + $field + '`'))) {
        throw "Structured badge model field is missing: $field"
    }
}
if (-not $badgeText.Contains('`isExecutionEnabling` must be false for all current Path B badges')) {
    throw 'Structured badge model does not state isExecutionEnabling must remain false.'
}
if (-not $badgeText.Contains('isExecutionEnabling = $false')) {
    throw 'Structured badge model example does not keep isExecutionEnabling false.'
}

foreach ($documentPath in @(
    'docs/nvidia-path-b-catalog-design.md',
    'docs/tool-designs/nvidia-path-b-scope-design.md',
    'docs/tool-designs/nvidia-path-b-production-allowlist-planning.md',
    'docs/tool-designs/nvidia-path-b-artifact-provenance-review.md',
    'docs/nvidia-profile-state-capture-model.md',
    'docs/nvidia-path-b-ui-workflow-design.md',
    'docs/tool-designs/nvidia-path-b-draft-allowlist-proposal.md',
    'docs/tool-designs/nvidia-path-b-production-approval-gate-design.md',
    'docs/tool-designs/nvidia-path-b-runtime-gating-design.md',
    'docs/tool-designs/nvidia-path-b-non-executing-workflow-registry-schema-design.md',
    'docs/production-allowlist-governance.md',
    'docs/download-provenance-installer-policy.md',
    'docs/driver-state-capture-rollback.md',
    'docs/file-registry-state-capture-rollback.md',
    'docs/process-handling-policy.md',
    'docs/reboot-recovery-workflow.md',
    'docs/restore-selection-ui-runtime.md',
    'docs/final-deferred-tools-readiness-matrix.md',
    'docs/deferred-tools-execution-plan.md',
    'docs/deferred-tool-readiness-review.md'
)) {
    if (-not $badgeText.Contains($documentPath)) {
        throw "Readiness badge design relationship is missing: $documentPath"
    }
}

foreach ($nonAction in @(
    'No live UI badges implemented',
    'No UI runtime files modified',
    'No active UI config created',
    'No active runtime config created',
    'No production config or allowlist config created or changed',
    'No production approval granted',
    'No executable handler/module/action created',
    'No tool module created',
    'No runtime module or executable helper created',
    'No tool or placeholder enabled',
    'No runtime behavior changed',
    'No source mirror files changed',
    'No intake files changed',
    'No legacy source-ultimate files changed',
    'No artifact, download, installer, Profile Inspector, `.nip`, driver',
    'No AppX, service, task, cleanup, TrustedInstaller, or Safe Mode approval',
    'No production scope, allowlist, artifact, workflow, or process target added',
    'No DDU execution/download/artifact approval added',
    'Standalone DDU not introduced',
    'Loudness EQ and NVME Faster Driver remain deleted',
    'Counts unchanged'
)) {
    if (-not $badgeText.Contains($nonAction)) {
        throw "Explicit non-action boundary is missing: $nonAction"
    }
}

foreach ($linkedPath in @($runtimeGatingPath, $schemaDesignPath, $uiDesignPath, $catalogPath, $matrixPath, $planPath, $reviewPath)) {
    $linkedText = Get-Content -LiteralPath $linkedPath -Raw
    if (-not $linkedText.Contains('docs/tool-designs/nvidia-path-b-readiness-badge-design.md')) {
        throw "Expected document does not link to the NVIDIA Path B readiness badge design: $linkedPath"
    }
}

foreach ($forbiddenPath in @(
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
        throw "Active UI, runtime, production, or Path B allowlist config was unexpectedly created: $forbiddenPath"
    }
}

if (@(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'core') -Filter '*NvidiaPathB*.psm1' -ErrorAction SilentlyContinue).Count -ne 0) {
    throw 'Runtime module or executable helper was unexpectedly created for NVIDIA Path B.'
}

$uiFilesWithPathB = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'ui') -Recurse -File |
        Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw) -match 'Driver Install Latest|Nvidia Settings|Hdcp|P0 State|Msi Mode|nvidia-path-b|ReadinessBadge'
        }
)
if ($uiFilesWithPathB.Count -ne 0) {
    throw 'WPF/UI runtime files were unexpectedly modified for NVIDIA Path B readiness badges.'
}

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })
foreach ($title in @($pathB | Where-Object { $_.Title -notin @('Driver Install Latest', 'Nvidia Settings') } | ForEach-Object { $_.Title })) {
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
if ($allTools.Count -ne 51) {
    throw "Expected 51 active tools, found $($allTools.Count)."
}
if ($placeholderModules.Count -ne 18) {
    throw "Expected 18 deferred/placeholders, found $($placeholderModules.Count)."
}
if (($allTools.Count - $placeholderModules.Count) -ne 33) {
    throw "Expected 33 implemented tools, found $($allTools.Count - $placeholderModules.Count)."
}

foreach ($moduleName in @($pathB | ForEach-Object { $_.ModuleName })) {
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
    BadgeDesignPath              = $badgeDesignPath
    PathBOrder                   = 'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
    ActiveToolCount              = $allTools.Count
    ImplementedToolCount         = $allTools.Count - $placeholderModules.Count
    DeferredPlaceholderCount     = $placeholderModules.Count
    SourcePromotedCandidateCount = $sourcePromotedFiles.Count
    IsExecutionEnabling          = $false
    ProductionApprovalsAdded     = $false
    RuntimeBehaviorChanged       = $false
    Message                      = 'NVIDIA Path B readiness badge design is documented and remains non-executing.'
}
