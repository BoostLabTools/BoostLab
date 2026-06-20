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
        throw 'Unable to determine the NVIDIA Path B runtime gating design validator path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

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

$runtimeDesignPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-runtime-gating-design.md'
$approvalGatePath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-production-approval-gate-design.md'
$draftPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-draft-allowlist-proposal.md'
$planningPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-production-allowlist-planning.md'
$scopeDesignPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-scope-design.md'
$profileModelPath = Join-Path $ProjectRoot 'docs\nvidia-profile-state-capture-model.md'
$uiDesignPath = Join-Path $ProjectRoot 'docs\nvidia-path-b-ui-workflow-design.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$reviewPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$matrixPath = Join-Path $ProjectRoot 'docs\final-deferred-tools-readiness-matrix.md'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$intakeRoot = Join-Path $ProjectRoot 'intake\missing-ultimate-scripts\Ultimate'

foreach ($path in @($runtimeDesignPath, $approvalGatePath, $draftPath, $planningPath, $scopeDesignPath, $profileModelPath, $uiDesignPath, $planPath, $reviewPath, $matrixPath, $stagesPath)) {
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

$runtimeText = Get-Content -LiteralPath $runtimeDesignPath -Raw

foreach ($section in @(
    '# NVIDIA Path B Runtime Gating Design',
    '## Purpose And Status',
    '## Runtime Gating Concepts',
    '## Gate States',
    '## Workflow-Level Gating Rules',
    '## Per-Step Gating Requirements',
    '## Gating Decision Table',
    '## Future Runtime Result Schema',
    '## Future UI Integration Requirements',
    '## Rejection And Refusal Behavior',
    '## Relationship To Existing Documents',
    '## Explicit Non-Actions',
    '## Recommended Next Phase'
)) {
    if (-not $runtimeText.Contains($section)) {
        throw "Runtime gating design is missing section: $section"
    }
}

foreach ($requiredPhrase in @(
    'This is runtime gating design only',
    'No runtime gate implementation is added',
    'No tool execution is enabled',
    'No production approval is granted',
    'No production config or allowlist config is created or changed',
    'No placeholder/tool card is enabled',
    'No UI implementation is added',
    'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode',
    'Path A: `Driver Install Debloat & Settings`',
    'Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`'
)) {
    if (-not $runtimeText.Contains($requiredPhrase)) {
        throw "Runtime-gating status or Path A/B phrase is missing: $requiredPhrase"
    }
}

foreach ($concept in @(
    'Workflow gate',
    'Path gate',
    'Step gate',
    'Prerequisite gate',
    'Source checksum gate',
    'Approval gate',
    'Artifact provenance gate',
    'Installer descriptor gate',
    'Driver rollback gate',
    'Profile capture gate',
    'Registry rollback gate',
    'Process policy gate',
    'Reboot/recovery gate',
    'NVIDIA-only targeting gate',
    'Path A/Path B mutual exclusion gate',
    'Restore availability gate',
    'Default availability gate',
    'Verification gate',
    'User confirmation gate',
    'Failure gate',
    'Skip gate',
    'Not applicable gate',
    'Not implemented gate'
)) {
    if (-not $runtimeText.Contains($concept)) {
        throw "Runtime gating concept is missing: $concept"
    }
}

foreach ($state in @(
    'NotImplemented',
    'Blocked',
    'MissingApproval',
    'MissingProvenance',
    'MissingRollbackCapture',
    'MissingProfileCapture',
    'MissingProcessPolicy',
    'MissingRebootPolicy',
    'MissingNvidiaTargeting',
    'SourceChecksumMismatch',
    'PathConflict',
    'ReadyForReview',
    'ReadyForExecutionInFuturePhase',
    'SkippedByApprovedDesign',
    'NotApplicable',
    'Failed',
    'Refused',
    'Completed',
    'RestoreAvailable',
    'RestoreDenied'
)) {
    if (-not $runtimeText.Contains($state)) {
        throw "Gate state is missing: $state"
    }
}
if (-not $runtimeText.Contains('`ReadyForExecutionInFuturePhase` is descriptive only')) {
    throw 'ReadyForExecutionInFuturePhase descriptive-only rule is missing.'
}

foreach ($workflowRule in @(
    'Exact order must be preserved',
    'Step 2 is ready only after Step 1 completed, skipped by approved design, or',
    'Step 3 is ready only after Step 2 gates are satisfied',
    'Step 4 is ready only after Step 3 gates are satisfied',
    'Step 5 is ready only after Step 4 gates are satisfied',
    'If Path A is selected or applied, Path B is blocked unless a future mixing',
    'If Path B is selected or applied, Path A is blocked or warned depending on a',
    'AMD/Intel GPU targets are blocked for NVIDIA Path B',
    'NVIDIA-only targeting is required before any GPU, device, driver, display',
    'Missing source checksum blocks the workflow',
    'Missing production approval blocks execution'
)) {
    if (-not $runtimeText.Contains($workflowRule)) {
        throw "Workflow-level gating rule is missing: $workflowRule"
    }
}

foreach ($stepGate in @(
    '### Step 1 - Driver Install Latest',
    'Artifact provenance gate for the NVIDIA driver lookup and resulting driver',
    'Driver installer descriptor gate',
    'Driver rollback gate',
    'Process handoff gate',
    'NVIDIA driver verification gate',
    '### Step 2 - Nvidia Settings',
    'NVIDIA Inspector provenance gate',
    'Profile Inspector execution descriptor gate',
    'Generated/imported `.nip` gate',
    'Profile pre-capture gate',
    'Profile restore eligibility gate',
    '### Step 3 - Hdcp',
    'Exact `RMHdcpKeyglobZero` registry scope gate',
    'Content-protection/security review gate',
    '### Step 4 - P0 State',
    'Exact `DisableDynamicPstate` registry scope gate',
    'Power/thermal/stability warning gate',
    '### Step 5 - Msi Mode',
    'Exact `MSISupported` registry scope gate',
    'Display device instance validation gate',
    'Reboot/device restart disclosure gate'
)) {
    if (-not $runtimeText.Contains($stepGate)) {
        throw "Per-step runtime gate is missing: $stepGate"
    }
}

foreach ($tablePhrase in @(
    '| Gate id | Step number | Script name | Gate category | Required evidence | Blocking condition | Non-blocking condition | Future runtime result field | User-facing message requirement | Related foundation/document | Current status |',
    'NPB-RUNTIME-GATE-001',
    'NPB-RUNTIME-GATE-035',
    'DesignOnly',
    'NeedsFutureRuntime',
    'NotApproved',
    'NotImplemented'
)) {
    if (-not $runtimeText.Contains($tablePhrase)) {
        throw "Gating decision table content is missing: $tablePhrase"
    }
}
if ($runtimeText -match '\|\s*(Approved|Enabled)\s*\|') {
    throw 'Gating decision table contains an active Approved or Enabled status.'
}

foreach ($field in @(
    'workflowId',
    'selectedPath',
    'stepId',
    'stepNumber',
    'stepName',
    'sourcePath',
    'sourceChecksum',
    'gateState',
    'blockingReasons',
    'missingApprovals',
    'missingProvenance',
    'missingRollbackCaptures',
    'missingProfileCapture',
    'missingProcessPolicy',
    'missingRebootPolicy',
    'nvidiaTargetingStatus',
    'pathConflictStatus',
    'restoreAvailability',
    'defaultAvailability',
    'confirmationRequired',
    'actionPlanRequired',
    'verificationRequired',
    'canExecute',
    'canRestore',
    'canDefault',
    'nextAllowedStep',
    'userMessage',
    'activityLogEvent'
)) {
    if (-not $runtimeText.Contains(('`' + $field + '`'))) {
        throw "Future runtime result schema field is missing: $field"
    }
}
if (-not $runtimeText.Contains('`canExecute` must remain false for all Path B steps')) {
    throw 'canExecute=false boundary is missing.'
}

foreach ($uiRule in @(
    'UI should read gate results before enabling any action button',
    '`NotImplemented` and `Blocked` states should remain visible and readable',
    'Missing approvals should be shown as explicit blocker categories',
    'Path order should be visible',
    'Path A/B conflict should be visible',
    'Restore availability should come only from validated capture state',
    'Default is not Restore',
    'Action Plan should be generated only after all approval gates are satisfied',
    'No UI implementation is added by this document'
)) {
    if (-not $runtimeText.Contains($uiRule)) {
        throw "Future UI integration rule is missing: $uiRule"
    }
}

foreach ($refusal in @(
    'Checksum mismatch refuses execution',
    'Missing production allowlist refuses execution',
    'Missing provenance refuses download',
    'Missing profile capture refuses `.nip` import and profile write',
    'Missing registry rollback capture refuses registry mutation',
    'Missing NVIDIA targeting refuses device',
    'Missing reboot policy refuses reboot',
    'Path conflict refuses mixed Path A/B unless approved by a future design',
    'Ambiguous target refuses execution'
)) {
    if (-not $runtimeText.Contains($refusal)) {
        throw "Rejection/refusal behavior is missing: $refusal"
    }
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
    if (-not $runtimeText.Contains($documentPath)) {
        throw "Runtime gating design relationship is missing: $documentPath"
    }
}

foreach ($nonAction in @(
    'No runtime gating implementation was added',
    'No runtime config was created to enable Path B',
    'No production config or allowlist config was created or changed',
    'No production approval was granted',
    'No source mirror files changed',
    'No intake files changed',
    'No legacy source-ultimate files changed',
    'No executable module was created',
    'No helper module was created',
    'No tool or placeholder was enabled',
    'No tool card was enabled',
    'No UI behavior changed',
    'No runtime behavior changed',
    'No artifact, download, installer, Profile Inspector, `.nip`, driver',
    'No DDU execution, DDU download, or DDU artifact approval was added',
    'Standalone DDU was not introduced',
    'Loudness EQ and NVME Faster Driver remain deleted',
    'Counts remain unchanged'
)) {
    if (-not $runtimeText.Contains($nonAction)) {
        throw "Explicit non-action boundary is missing: $nonAction"
    }
}

foreach ($linkedPath in @($approvalGatePath, $draftPath, $planningPath, $scopeDesignPath, $profileModelPath, $uiDesignPath, $planPath, $reviewPath, $matrixPath)) {
    $linkedText = Get-Content -LiteralPath $linkedPath -Raw
    if (-not $linkedText.Contains('docs/tool-designs/nvidia-path-b-runtime-gating-design.md')) {
        throw "Expected document does not link to the NVIDIA Path B runtime gating design: $linkedPath"
    }
}

foreach ($forbiddenPath in @(
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
        throw "Production/Path B runtime or allowlist config was unexpectedly created: $forbiddenPath"
    }
}
if (@(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'core') -Filter '*NvidiaPathB*.psm1' -ErrorAction SilentlyContinue).Count -ne 0) {
    throw 'Runtime module was unexpectedly created for NVIDIA Path B.'
}

$uiFilesWithPathB = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'ui') -Recurse -File |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw) -match 'Driver Install Latest|Nvidia Settings|P0 State|Msi Mode|nvidia-path-b-runtime-gating' }
)
if ($uiFilesWithPathB.Count -ne 0) {
    throw 'UI implementation was unexpectedly changed for NVIDIA Path B.'
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
    throw 'Driver Install Latest must be active exactly once as the Phase 124 source-equivalent Driver Install Latest tool.'
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
if ($allTools.Count -ne $inventoryBaseline.ActiveTools) {
    throw "Expected $($inventoryBaseline.ActiveTools) active tools, found $($allTools.Count)."
}
if ($placeholderModules.Count -ne $inventoryBaseline.DeferredPlaceholders) {
    throw "Expected $($inventoryBaseline.DeferredPlaceholders) deferred/placeholders, found $($placeholderModules.Count)."
}
if (($allTools.Count - $placeholderModules.Count) -ne $inventoryBaseline.ImplementedTools) {
    throw "Expected $($inventoryBaseline.ImplementedTools) implemented tools, found $($allTools.Count - $placeholderModules.Count)."
}

foreach ($moduleName in @($pathB | Where-Object { $_.Title -notin @('Driver Install Latest', 'Nvidia Settings', 'Hdcp', 'P0 State', 'Msi Mode') } | ForEach-Object { $_.ModuleName })) {
    if (@(Get-ChildItem -Path $modulesRoot -Recurse -Filter "$moduleName.psm1").Count -ne 0) {
        throw "Executable module was unexpectedly created for Path B script: $moduleName"
    }
}

$sourcePromotedFiles = @(
    Get-ChildItem -LiteralPath (Join-Path $sourceRoot '_intake-promoted\Ultimate') -Recurse -File
)
if ($sourcePromotedFiles.Count -ne $inventoryBaseline.SourcePromotedMirrorFiles) {
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
    throw 'A production scope, allowlist, artifact, profile operation, workflow, or process target was unexpectedly approved.'
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
    Success                       = $true
    PathBOrder                    = 'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
    ActiveToolCount               = $allTools.Count
    ImplementedToolCount          = $allTools.Count - $placeholderModules.Count
    DeferredPlaceholderCount      = $placeholderModules.Count
    SourcePromotedCandidateCount  = $sourcePromotedFiles.Count
    CanExecuteForPathBSteps       = $false
    ProductionApprovalsAdded      = $false
    RuntimeBehaviorChanged        = $false
    Message                       = 'NVIDIA Path B runtime gating design is documented and remains non-executing.'
}




