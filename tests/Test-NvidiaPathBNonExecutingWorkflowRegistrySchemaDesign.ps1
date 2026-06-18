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
        throw 'Unable to determine the NVIDIA Path B non-executing workflow registry schema design validator path.'
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

$schemaDesignPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-non-executing-workflow-registry-schema-design.md'
$optionalSchemaConfigPath = Join-Path $ProjectRoot 'config\NvidiaPathBWorkflowRegistry.Schema.psd1'
$runtimeGatingPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-runtime-gating-design.md'
$approvalGatePath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-production-approval-gate-design.md'
$uiDesignPath = Join-Path $ProjectRoot 'docs\nvidia-path-b-ui-workflow-design.md'
$catalogPath = Join-Path $ProjectRoot 'docs\nvidia-path-b-catalog-design.md'
$matrixPath = Join-Path $ProjectRoot 'docs\final-deferred-tools-readiness-matrix.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$reviewPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$intakeRoot = Join-Path $ProjectRoot 'intake\missing-ultimate-scripts\Ultimate'

foreach ($path in @($schemaDesignPath, $runtimeGatingPath, $approvalGatePath, $uiDesignPath, $catalogPath, $matrixPath, $planPath, $reviewPath, $stagesPath)) {
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

$schemaText = Get-Content -LiteralPath $schemaDesignPath -Raw

foreach ($section in @(
    '# NVIDIA Path B Non-Executing Workflow Registry Schema Design',
    '## Purpose And Status',
    '## Workflow Registry Schema Concepts',
    '## Required Workflow-Level Fields',
    '## Required Step-Level Fields',
    '## Proposed Non-Executing Schema Example',
    '## Optional Inert Schema Config Decision',
    '## Path A / Path B Relationship Schema',
    '## Gate And Approval Dependency Schema',
    '## Non-Execution Guarantees',
    '## Future Promotion Path',
    '## Explicit Non-Actions',
    '## Recommended Next Phase'
)) {
    if (-not $schemaText.Contains($section)) {
        throw "Schema design document is missing section: $section"
    }
}

foreach ($phrase in @(
    'Workflow Registry means an internal BoostLab metadata',
    'It does not mean Windows Registry',
    'This phase must not touch Windows Registry',
    'This is non-executing workflow registry schema design only',
    'No runtime workflow registry is enabled',
    'No executable workflow is created',
    'No UI/runtime behavior changes',
    'No tool card or placeholder is enabled',
    'No production approval is granted',
    'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode',
    'Path A: `Driver Install Debloat & Settings`',
    'Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`'
)) {
    if (-not $schemaText.Contains($phrase)) {
        throw "Required schema/status phrase is missing: $phrase"
    }
}

foreach ($concept in @(
    'workflow id',
    'workflow display name',
    'workflow path label',
    'workflow category/stage',
    'workflow status',
    'implementation status',
    'execution status',
    'source promotion status',
    'path relationship',
    'mutually exclusive workflow id',
    'workflow step list',
    'ordered step',
    'prerequisite step',
    'next step',
    'gate dependency',
    'approval dependency',
    'source checksum binding',
    'artifact provenance dependency',
    'driver/profile state dependency',
    'registry rollback dependency',
    'process policy dependency',
    'reboot policy dependency',
    'restore selection dependency',
    'UI visibility state',
    'user intent note',
    'risk level',
    'canExecute flag',
    'canShowInUI flag',
    'canShowAsCatalog flag'
)) {
    if (-not $schemaText.Contains($concept)) {
        throw "Workflow registry schema concept is missing: $concept"
    }
}

foreach ($field in @(
    'workflowId',
    'workflowName',
    'workflowPathLabel',
    'stage',
    'category',
    'status',
    'implementationStatus',
    'executionStatus',
    'canExecute',
    'canShowInUI',
    'canShowAsCatalog',
    'sourceSet',
    'sourceMirrorRoot',
    'pathAReference',
    'pathBReference',
    'mutuallyExclusiveWorkflowIds',
    'mixingPolicy',
    'requiredOrder',
    'userIntent',
    'targetVendor',
    'unsupportedTargets',
    'requiredApprovals',
    'requiredFoundations',
    'designDocuments',
    'validatorDocuments',
    'defaultAvailability',
    'restoreAvailability',
    'actionPlanRequirements',
    'latestResultSchemaReference',
    'activityLogSchemaReference',
    'warningTextReferences',
    'lastReviewedPhase',
    'notes'
)) {
    if (-not $schemaText.Contains(('`' + $field + '`'))) {
        throw "Workflow-level field is missing: $field"
    }
}

foreach ($field in @(
    'stepId',
    'stepNumber',
    'stepName',
    'displayName',
    'sourceMirrorPath',
    'sourceRelativePath',
    'sourceChecksum',
    'sourceChecksumAlgorithm',
    'stage',
    'prerequisiteStepIds',
    'nextStepIds',
    'skipPolicy',
    'failurePolicy',
    'notApplicablePolicy',
    'implementationStatus',
    'gateState',
    'canExecute',
    'canDefault',
    'canRestore',
    'requiredApprovals',
    'requiredArtifactApprovals',
    'requiredAllowlistEntries',
    'requiredRollbackCaptures',
    'requiredProfileCaptures',
    'requiredProcessPolicies',
    'requiredRebootPolicies',
    'targetVendor',
    'userWarningText',
    'actionPlanRequirements',
    'latestResultFields',
    'activityLogFields',
    'verificationRequirements',
    'designDocument',
    'statusReason'
)) {
    if (-not $schemaText.Contains(('`' + $field + '`'))) {
        throw "Step-level field is missing: $field"
    }
}

foreach ($examplePhrase in @(
    "workflowId = 'nvidia.pathB'",
    "status = 'DesignOnly'",
    "implementationStatus = 'NotImplemented'",
    "executionStatus = 'NotApproved'",
    'canExecute = $false',
    'canShowAsCatalog = $true',
    'canShowInUI = $false',
    "stepName = 'Driver Install Latest'",
    "stepName = 'Nvidia Settings'",
    "stepName = 'Hdcp'",
    "stepName = 'P0 State'",
    "stepName = 'Msi Mode'",
    'No runtime action command is present',
    'No executable handler is present',
    'No module path is present',
    'No action id maps to execution'
)) {
    if (-not $schemaText.Contains($examplePhrase)) {
        throw "Non-executing schema example content is missing: $examplePhrase"
    }
}

foreach ($relationshipPhrase in @(
    'Path A reference: `Driver Install Debloat & Settings`',
    'Path B reference:',
    'Mutual exclusion through `mutuallyExclusiveWorkflowIds`',
    'Guided selection through explicit `workflowPathLabel` and `userIntent`',
    'Accidental mixing prevention through `mixingPolicy`',
    'Future explicit mixing approval if ever allowed',
    'Blocking messages when conflicting path is selected or applied',
    'Path B must never silently call Path A behavior',
    'Path A must never silently call Path B behavior'
)) {
    if (-not $schemaText.Contains($relationshipPhrase)) {
        throw "Path A/Path B relationship schema content is missing: $relationshipPhrase"
    }
}

foreach ($dependencyPhrase in @(
    'Production Approval Gate Design',
    'Runtime Gating Design',
    'Draft Allowlist Proposal',
    'Artifact Provenance Review',
    'Profile State Capture Model',
    'Production Allowlist Governance',
    'Download Provenance and Installer Execution Policy',
    'Driver State Capture and Rollback',
    'File/Registry State Capture and Rollback',
    'Process Handling Policy',
    'Reboot/Recovery Workflow',
    'Restore Selection UI / Runtime',
    'Missing production approval keeps workflow and steps `NotApproved`',
    'Missing artifact provenance keeps download',
    'Missing driver/profile capture keeps driver/profile/profile-import behavior',
    'Missing registry rollback capture keeps Windows Registry mutation blocked'
)) {
    if (-not $schemaText.Contains($dependencyPhrase)) {
        throw "Gate/approval dependency schema content is missing: $dependencyPhrase"
    }
}

foreach ($guarantee in @(
    'Schema must not contain direct script execution commands',
    'Schema must not contain PowerShell command lines to run Path B',
    'Schema must not contain download URLs as approved sources',
    'Schema must not contain installer commands',
    'Schema must not contain Profile Inspector execution commands',
    'Schema must not contain registry write commands',
    'Schema must not contain DDU references as executable entries',
    'Schema must not expose action buttons as enabled',
    'Schema must not change official counts'
)) {
    if (-not $schemaText.Contains($guarantee)) {
        throw "Non-execution guarantee is missing: $guarantee"
    }
}

foreach ($promotion in @(
    'Separate approval to create a real workflow registry',
    'Production allowlist approvals',
    'Artifact approvals',
    'Per-step implementation modules',
    'Runtime gate evaluator',
    'UI implementation',
    'Validators proving `canExecute` remains false until approvals exist',
    'Final integration validation'
)) {
    if (-not $schemaText.Contains($promotion)) {
        throw "Future promotion path item is missing: $promotion"
    }
}

foreach ($nonAction in @(
    'No runtime workflow registry enabled',
    'No active config created',
    'No production config or allowlist config created or changed',
    'No production approval granted',
    'No executable handler/module/action created',
    'No tool or placeholder enabled',
    'No UI implementation added',
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
    if (-not $schemaText.Contains($nonAction)) {
        throw "Explicit non-action boundary is missing: $nonAction"
    }
}

foreach ($linkedPath in @($runtimeGatingPath, $approvalGatePath, $uiDesignPath, $catalogPath, $matrixPath, $planPath, $reviewPath)) {
    $linkedText = Get-Content -LiteralPath $linkedPath -Raw
    if (-not $linkedText.Contains('docs/tool-designs/nvidia-path-b-non-executing-workflow-registry-schema-design.md')) {
        throw "Expected document does not link to the NVIDIA Path B non-executing workflow registry schema design: $linkedPath"
    }
}

if (Test-Path -LiteralPath $optionalSchemaConfigPath) {
    $configText = Get-Content -LiteralPath $optionalSchemaConfigPath -Raw
    $schemaConfig = Import-PowerShellDataFile -LiteralPath $optionalSchemaConfigPath

    foreach ($required in @('DesignOnly', 'NotImplemented', 'NotApproved', 'canExecute')) {
        if (-not $configText.Contains($required)) {
            throw "Optional schema config is missing required inert marker: $required"
        }
    }
    if ($configText -match '(Start-Process|Invoke-WebRequest|IWR\s|reg\.exe|reg add|reg delete|Stop-Process|Restart-Computer|shutdown\.exe|pnputil|DDU)') {
        throw 'Optional schema config contains executable or mutation-oriented content.'
    }
    if ($configText -match '(ExecutableHandler|CommandLine|ModulePath|ScriptExecution|ActionId)') {
        throw 'Optional schema config contains handler, command, module, script, or executable action fields.'
    }
    if ($schemaConfig.ContainsKey('Workflows')) {
        foreach ($workflow in @($schemaConfig.Workflows)) {
            if ($workflow.canExecute -ne $false) {
                throw 'Optional schema config contains a workflow with canExecute not false.'
            }
            foreach ($step in @($workflow.steps)) {
                if ($step.canExecute -ne $false) {
                    throw 'Optional schema config contains a step with canExecute not false.'
                }
                if ($step.implementationStatus -ne 'NotImplemented') {
                    throw 'Optional schema config contains a step whose implementationStatus is not NotImplemented.'
                }
            }
        }
    }
}

foreach ($forbiddenPath in @(
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
        throw "Active runtime, production, or Path B allowlist config was unexpectedly created: $forbiddenPath"
    }
}

if (@(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'core') -Filter '*NvidiaPathB*.psm1' -ErrorAction SilentlyContinue).Count -ne 0) {
    throw 'Runtime module or executable helper was unexpectedly created for NVIDIA Path B.'
}

$uiFilesWithPathB = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'ui') -Recurse -File |
        Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw) -match 'Driver Install Latest|Nvidia Settings|Hdcp|P0 State|Msi Mode|nvidia-path-b-non-executing-workflow-registry'
        }
)
if ($uiFilesWithPathB.Count -ne 0) {
    throw 'WPF/UI runtime files were unexpectedly modified for NVIDIA Path B.'
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
    Success                      = $true
    SchemaDesignPath             = $schemaDesignPath
    OptionalSchemaConfigCreated  = (Test-Path -LiteralPath $optionalSchemaConfigPath)
    PathBOrder                   = 'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
    ActiveToolCount              = $allTools.Count
    ImplementedToolCount         = $allTools.Count - $placeholderModules.Count
    DeferredPlaceholderCount     = $placeholderModules.Count
    SourcePromotedCandidateCount = $sourcePromotedFiles.Count
    ProductionApprovalsAdded     = $false
    RuntimeBehaviorChanged       = $false
    Message                      = 'NVIDIA Path B workflow registry schema design is documented and remains non-executing.'
}




