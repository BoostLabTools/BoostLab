# NVIDIA Path B Non-Executing Workflow Registry Schema Design

## Purpose And Status

Phase 82 defines a non-executing Workflow Registry schema design for NVIDIA App
Path B.

In this document, Workflow Registry means an internal BoostLab metadata
registry/catalog schema. It does not mean Windows Registry. This phase must not touch Windows Registry.

This is non-executing workflow registry schema design only. No runtime workflow registry is enabled. No executable workflow is created. No UI/runtime behavior changes. No tool card or placeholder is enabled. No production approval is granted.

This document does not create an active runtime registry, executable workflow
configuration, production allowlist configuration, runtime module, executable
helper, tool module, or WPF implementation.

NVIDIA App Path B exact required order:

`Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

Path relationship:

* Path A: `Driver Install Debloat & Settings`
* Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`
* Path B is for users who want to keep or use NVIDIA App features such as
  recording or related NVIDIA App features.
* Future UI/runtime must preserve guided separation between Path A and Path B
  and prevent accidental mixing unless later explicitly approved.

Source mirror references:

| Step | Script name | Source mirror path | SHA-256 |
|---:|---|---|---|
| 1 | Driver Install Latest | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1` | `41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F` |
| 2 | Nvidia Settings | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1` | `903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5` |
| 3 | Hdcp | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1` | `5C350D28F795D678051E6088F34968DF8D90B3D9024F558C5FAFB2899D1A906A` |
| 4 | P0 State | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1` | `382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC` |
| 5 | Msi Mode | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1` | `94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7` |

Related but out of scope:

* Driver Clean remains outside the five-step NVIDIA Path B workflow and needs a
  separate Driver Clean scope/provenance/safety design later.
* BitLocker remains outside NVIDIA Path B and needs future security-sensitive
  design.

## Workflow Registry Schema Concepts

Future schema concepts:

* workflow id: stable internal id for the workflow.
* workflow display name: user-facing name.
* workflow path label: Path A or Path B label.
* workflow category/stage: catalog grouping such as Graphics.
* workflow status: design and governance status.
* implementation status: whether executable behavior exists.
* execution status: whether runtime may execute the workflow.
* source promotion status: whether source exists as official source,
  source-promoted mirror, or intake-only reference.
* path relationship: relation to other workflows.
* mutually exclusive workflow id: workflow that conflicts with this one.
* workflow step list: ordered collection of steps.
* ordered step: one step with a positive order number.
* prerequisite step: step that must be completed, skipped by approved design, or
  NotApplicable before another step.
* next step: step that may become visible or eligible after this step.
* gate dependency: runtime gate that must pass before execution in a future
  phase.
* approval dependency: production approval or review that must exist first.
* source checksum binding: required source path plus SHA-256.
* artifact provenance dependency: required artifact approval dependency.
* driver/profile state dependency: driver or NVIDIA profile state capture
  dependency.
* registry rollback dependency: exact registry capture dependency.
* process policy dependency: process handling or launch-handoff dependency.
* reboot policy dependency: reboot, device restart, or session-transition
  dependency.
* restore selection dependency: captured-state Restore dependency.
* UI visibility state: whether the item may be hidden, catalog-only,
  design-preview-only, or enabled in future UI.
* user intent note: why a technician would choose this workflow.
* risk level: conservative risk classification.
* canExecute flag: explicit execution permission flag.
* canShowInUI flag: explicit future UI visibility flag.
* canShowAsCatalog flag: explicit catalog/design visibility flag.

## Required Workflow-Level Fields

Required future workflow registry fields:

* `workflowId`
* `workflowName`
* `workflowPathLabel`
* `stage`
* `category`
* `status`
* `implementationStatus`
* `executionStatus`
* `canExecute`
* `canShowInUI`
* `canShowAsCatalog`
* `sourceSet`
* `sourceMirrorRoot`
* `pathAReference`
* `pathBReference`
* `mutuallyExclusiveWorkflowIds`
* `mixingPolicy`
* `requiredOrder`
* `userIntent`
* `targetVendor`
* `unsupportedTargets`
* `requiredApprovals`
* `requiredFoundations`
* `designDocuments`
* `validatorDocuments`
* `defaultAvailability`
* `restoreAvailability`
* `actionPlanRequirements`
* `latestResultSchemaReference`
* `activityLogSchemaReference`
* `warningTextReferences`
* `lastReviewedPhase`
* `notes`

## Required Step-Level Fields

Required future step registry fields:

* `stepId`
* `stepNumber`
* `stepName`
* `displayName`
* `sourceMirrorPath`
* `sourceRelativePath`
* `sourceChecksum`
* `sourceChecksumAlgorithm`
* `stage`
* `prerequisiteStepIds`
* `nextStepIds`
* `skipPolicy`
* `failurePolicy`
* `notApplicablePolicy`
* `implementationStatus`
* `gateState`
* `canExecute`
* `canDefault`
* `canRestore`
* `requiredApprovals`
* `requiredArtifactApprovals`
* `requiredAllowlistEntries`
* `requiredRollbackCaptures`
* `requiredProfileCaptures`
* `requiredProcessPolicies`
* `requiredRebootPolicies`
* `targetVendor`
* `userWarningText`
* `actionPlanRequirements`
* `latestResultFields`
* `activityLogFields`
* `verificationRequirements`
* `designDocument`
* `statusReason`

## Proposed Non-Executing Schema Example

This example is documentation-only pseudo-PSD1. It is not a config file, is not
loaded by runtime, and is not execution permission.

```powershell
@{
    SchemaVersion = '0.1-design-only'
    Purpose = 'NVIDIA Path B non-executing workflow registry schema example'
    IsRuntimeRegistry = $false
    IsProductionConfig = $false
    WorkflowRegistryStatus = 'DesignOnly'
    Workflows = @(
        @{
            workflowId = 'nvidia.pathB'
            workflowName = 'NVIDIA App Compatible Path'
            workflowPathLabel = 'Path B'
            stage = 'Graphics'
            category = 'NVIDIA'
            status = 'DesignOnly'
            implementationStatus = 'NotImplemented'
            executionStatus = 'NotApproved'
            canExecute = $false
            canShowInUI = $false
            canShowAsCatalog = $true
            sourceSet = 'source-promoted-intake'
            sourceMirrorRoot = 'source-ultimate/_intake-promoted/Ultimate'
            pathAReference = 'Driver Install Debloat & Settings'
            pathBReference = 'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
            mutuallyExclusiveWorkflowIds = @('nvidia.pathA')
            mixingPolicy = 'BlockedUntilFutureExplicitApproval'
            requiredOrder = @(
                'Driver Install Latest'
                'Nvidia Settings'
                'Hdcp'
                'P0 State'
                'Msi Mode'
            )
            userIntent = 'Keep or use NVIDIA App features such as recording while following the future approved Path B sequence.'
            targetVendor = 'NVIDIA'
            unsupportedTargets = @('AMD GPU-specific branches', 'Intel GPU-specific branches', 'Standalone DDU')
            requiredApprovals = @('ProductionApprovalGate', 'RuntimeGating', 'ProductionAllowlistGovernance')
            requiredFoundations = @(
                'DownloadProvenance'
                'InstallerExecution'
                'DriverStateCaptureRollback'
                'NvidiaProfileStateCapture'
                'FileRegistryStateCaptureRollback'
                'ProcessHandling'
                'RebootRecovery'
                'RestoreSelection'
            )
            designDocuments = @(
                'docs/nvidia-path-b-catalog-design.md'
                'docs/tool-designs/nvidia-path-b-scope-design.md'
                'docs/tool-designs/nvidia-path-b-production-allowlist-planning.md'
                'docs/tool-designs/nvidia-path-b-artifact-provenance-review.md'
                'docs/nvidia-profile-state-capture-model.md'
                'docs/nvidia-path-b-ui-workflow-design.md'
                'docs/tool-designs/nvidia-path-b-draft-allowlist-proposal.md'
                'docs/tool-designs/nvidia-path-b-production-approval-gate-design.md'
                'docs/tool-designs/nvidia-path-b-runtime-gating-design.md'
            )
            validatorDocuments = @('tests/Test-NvidiaPathBNonExecutingWorkflowRegistrySchemaDesign.ps1')
            defaultAvailability = 'NotApproved'
            restoreAvailability = 'RestoreDenied'
            actionPlanRequirements = 'Future only after all approval gates pass'
            latestResultSchemaReference = 'docs/tool-designs/nvidia-path-b-runtime-gating-design.md'
            activityLogSchemaReference = 'docs/tool-designs/nvidia-path-b-runtime-gating-design.md'
            warningTextReferences = @('docs/nvidia-path-b-ui-workflow-design.md')
            lastReviewedPhase = 82
            notes = 'No runtime action command is present. No executable handler is present. No module path is present. No action id maps to execution.'
            steps = @(
                @{
                    stepId = 'nvidia.pathB.driverInstallLatest'
                    stepNumber = 1
                    stepName = 'Driver Install Latest'
                    displayName = 'Driver Install Latest'
                    sourceMirrorPath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
                    sourceRelativePath = '5 Graphics/2 Driver Install Latest.ps1'
                    sourceChecksum = '41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F'
                    sourceChecksumAlgorithm = 'SHA-256'
                    stage = 'Graphics'
                    prerequisiteStepIds = @()
                    nextStepIds = @('nvidia.pathB.nvidiaSettings')
                    skipPolicy = 'NotApproved'
                    failurePolicy = 'BlockLaterSteps'
                    notApplicablePolicy = 'FutureValidatorRequired'
                    implementationStatus = 'NotImplemented'
                    gateState = 'NotImplemented'
                    canExecute = $false
                    canDefault = $false
                    canRestore = $false
                    requiredApprovals = @('ProductionApprovalGate')
                    requiredArtifactApprovals = @('NvidiaDriverArtifact')
                    requiredAllowlistEntries = @('InstallerExecutionDescriptor', 'DriverScope')
                    requiredRollbackCaptures = @('DriverStateCapture')
                    requiredProfileCaptures = @()
                    requiredProcessPolicies = @('InstallerLaunchHandoff')
                    requiredRebootPolicies = @('DriverInstallerRebootDisclosure')
                    targetVendor = 'NVIDIA'
                    userWarningText = 'Driver install can affect display stability and may require restart planning.'
                    actionPlanRequirements = 'Future high-risk Action Plan'
                    latestResultFields = @('workflowId', 'stepId', 'gateState', 'missingProvenance')
                    activityLogFields = @('workflowId', 'stepNumber', 'stepName', 'gateState')
                    verificationRequirements = @('ArtifactVerification', 'DriverStateVerification')
                    designDocument = 'docs/tool-designs/nvidia-path-b-scope-design.md'
                    statusReason = 'Missing artifact provenance, installer descriptor, driver rollback, process policy, reboot policy, and production approval.'
                }
                @{
                    stepId = 'nvidia.pathB.nvidiaSettings'
                    stepNumber = 2
                    stepName = 'Nvidia Settings'
                    displayName = 'Nvidia Settings'
                    sourceMirrorPath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
                    sourceRelativePath = '5 Graphics/4 Nvidia Settings.ps1'
                    sourceChecksum = '903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5'
                    sourceChecksumAlgorithm = 'SHA-256'
                    stage = 'Graphics'
                    prerequisiteStepIds = @('nvidia.pathB.driverInstallLatest')
                    nextStepIds = @('nvidia.pathB.hdcp')
                    skipPolicy = 'NotApproved'
                    failurePolicy = 'BlockLaterSteps'
                    notApplicablePolicy = 'FutureValidatorRequired'
                    implementationStatus = 'NotImplemented'
                    gateState = 'NotImplemented'
                    canExecute = $false
                    canDefault = $false
                    canRestore = $false
                    requiredApprovals = @('ProductionApprovalGate')
                    requiredArtifactApprovals = @('7ZipArtifact', 'NvidiaProfileInspectorArtifact')
                    requiredAllowlistEntries = @('RegistryScopes', 'FileScopes', 'ProfileImportScope')
                    requiredRollbackCaptures = @('RegistryCapture', 'FileCapture')
                    requiredProfileCaptures = @('NvidiaProfilePreCapture')
                    requiredProcessPolicies = @('InstallerLaunch', 'ProfileInspectorImport', 'NvidiaControlPanelLaunch')
                    requiredRebootPolicies = @()
                    targetVendor = 'NVIDIA'
                    userWarningText = 'Profile imports can overwrite NVIDIA profile settings and require pre-capture.'
                    actionPlanRequirements = 'Future high-risk Action Plan'
                    latestResultFields = @('workflowId', 'stepId', 'gateState', 'missingProfileCapture')
                    activityLogFields = @('workflowId', 'stepNumber', 'stepName', 'gateState')
                    verificationRequirements = @('RegistryVerification', 'ProfileImportVerification', 'NipHashVerification')
                    designDocument = 'docs/nvidia-profile-state-capture-model.md'
                    statusReason = 'Missing artifact provenance, profile capture, process policy, registry/file scopes, and production approval.'
                }
                @{
                    stepId = 'nvidia.pathB.hdcp'
                    stepNumber = 3
                    stepName = 'Hdcp'
                    displayName = 'Hdcp'
                    sourceMirrorPath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1'
                    sourceRelativePath = '5 Graphics/5 Hdcp.ps1'
                    sourceChecksum = '5C350D28F795D678051E6088F34968DF8D90B3D9024F558C5FAFB2899D1A906A'
                    sourceChecksumAlgorithm = 'SHA-256'
                    stage = 'Graphics'
                    prerequisiteStepIds = @('nvidia.pathB.nvidiaSettings')
                    nextStepIds = @('nvidia.pathB.p0State')
                    skipPolicy = 'NotApproved'
                    failurePolicy = 'BlockLaterSteps'
                    notApplicablePolicy = 'FutureValidatorRequired'
                    implementationStatus = 'NotImplemented'
                    gateState = 'NotImplemented'
                    canExecute = $false
                    canDefault = $false
                    canRestore = $false
                    requiredApprovals = @('ContentProtectionReview', 'ProductionApprovalGate')
                    requiredArtifactApprovals = @()
                    requiredAllowlistEntries = @('RMHdcpKeyglobZeroRegistryScope')
                    requiredRollbackCaptures = @('RegistryCapture')
                    requiredProfileCaptures = @()
                    requiredProcessPolicies = @()
                    requiredRebootPolicies = @()
                    targetVendor = 'NVIDIA'
                    userWarningText = 'HDCP/content-protection settings may affect protected playback or display behavior.'
                    actionPlanRequirements = 'Future high-risk Action Plan'
                    latestResultFields = @('workflowId', 'stepId', 'gateState', 'nvidiaTargetingStatus')
                    activityLogFields = @('workflowId', 'stepNumber', 'stepName', 'gateState')
                    verificationRequirements = @('NvidiaTargetVerification', 'RegistryValueVerification')
                    designDocument = 'docs/tool-designs/nvidia-path-b-runtime-gating-design.md'
                    statusReason = 'Missing NVIDIA-only targeting, registry rollback capture, content-protection review, and production approval.'
                }
                @{
                    stepId = 'nvidia.pathB.p0State'
                    stepNumber = 4
                    stepName = 'P0 State'
                    displayName = 'P0 State'
                    sourceMirrorPath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1'
                    sourceRelativePath = '5 Graphics/6 P0 State.ps1'
                    sourceChecksum = '382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC'
                    sourceChecksumAlgorithm = 'SHA-256'
                    stage = 'Graphics'
                    prerequisiteStepIds = @('nvidia.pathB.hdcp')
                    nextStepIds = @('nvidia.pathB.msiMode')
                    skipPolicy = 'NotApproved'
                    failurePolicy = 'BlockLaterSteps'
                    notApplicablePolicy = 'FutureValidatorRequired'
                    implementationStatus = 'NotImplemented'
                    gateState = 'NotImplemented'
                    canExecute = $false
                    canDefault = $false
                    canRestore = $false
                    requiredApprovals = @('PowerThermalStabilityReview', 'ProductionApprovalGate')
                    requiredArtifactApprovals = @()
                    requiredAllowlistEntries = @('DisableDynamicPstateRegistryScope')
                    requiredRollbackCaptures = @('RegistryCapture')
                    requiredProfileCaptures = @()
                    requiredProcessPolicies = @()
                    requiredRebootPolicies = @()
                    targetVendor = 'NVIDIA'
                    userWarningText = 'P0/performance-state changes may increase power, heat, fan, battery, and stability risk.'
                    actionPlanRequirements = 'Future high-risk Action Plan'
                    latestResultFields = @('workflowId', 'stepId', 'gateState', 'nvidiaTargetingStatus')
                    activityLogFields = @('workflowId', 'stepNumber', 'stepName', 'gateState')
                    verificationRequirements = @('NvidiaTargetVerification', 'RegistryValueVerification')
                    designDocument = 'docs/tool-designs/nvidia-path-b-runtime-gating-design.md'
                    statusReason = 'Missing NVIDIA-only targeting, registry rollback capture, warning approval, and production approval.'
                }
                @{
                    stepId = 'nvidia.pathB.msiMode'
                    stepNumber = 5
                    stepName = 'Msi Mode'
                    displayName = 'Msi Mode'
                    sourceMirrorPath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1'
                    sourceRelativePath = '5 Graphics/7 Msi Mode.ps1'
                    sourceChecksum = '94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7'
                    sourceChecksumAlgorithm = 'SHA-256'
                    stage = 'Graphics'
                    prerequisiteStepIds = @('nvidia.pathB.p0State')
                    nextStepIds = @()
                    skipPolicy = 'NotApproved'
                    failurePolicy = 'EndWorkflowWithStructuredResult'
                    notApplicablePolicy = 'FutureValidatorRequired'
                    implementationStatus = 'NotImplemented'
                    gateState = 'NotImplemented'
                    canExecute = $false
                    canDefault = $false
                    canRestore = $false
                    requiredApprovals = @('ProductionApprovalGate')
                    requiredArtifactApprovals = @()
                    requiredAllowlistEntries = @('MSISupportedRegistryScope')
                    requiredRollbackCaptures = @('RegistryCapture')
                    requiredProfileCaptures = @()
                    requiredProcessPolicies = @()
                    requiredRebootPolicies = @('DeviceRestartDisclosure')
                    targetVendor = 'NVIDIA'
                    userWarningText = 'Interrupt-mode changes may require reboot or device restart disclosure.'
                    actionPlanRequirements = 'Future high-risk Action Plan'
                    latestResultFields = @('workflowId', 'stepId', 'gateState', 'nvidiaTargetingStatus')
                    activityLogFields = @('workflowId', 'stepNumber', 'stepName', 'gateState')
                    verificationRequirements = @('NvidiaDeviceVerification', 'RegistryValueVerification')
                    designDocument = 'docs/tool-designs/nvidia-path-b-runtime-gating-design.md'
                    statusReason = 'Missing NVIDIA-only device targeting, registry rollback capture, reboot policy decision, and production approval.'
                }
            )
        }
    )
}
```

Important schema example boundaries:

* No runtime action command is present.
* No executable handler is present.
* No module path is present.
* No action id maps to execution.
* The workflow has `canExecute = $false`.
* Every step has `canExecute = $false`.
* Every step has `implementationStatus = 'NotImplemented'`.
* Every step is listed in exact order.
* Status values remain `DesignOnly`, `NotImplemented`, and `NotApproved`.

## Optional Inert Schema Config Decision

Phase 82 does not create `config/NvidiaPathBWorkflowRegistry.Schema.psd1`.

Reason: the current phase is design-only and explicitly says not to create an
active runtime registry. Keeping the schema as documentation avoids confusing a
sample metadata file with runtime input. A future phase may create an inert
schema file only if it remains unconsumed by runtime and preserves every
non-execution boundary in this document.

If a future inert config is created, it must:

* Be schema/sample metadata only.
* Not be consumed by runtime.
* Not register a live workflow.
* Not enable UI/tool cards.
* Not include executable handlers, commands, module paths, script execution
  instructions, or action ids that execute anything.
* Set workflow and step statuses to `DesignOnly`, `NotImplemented`, or
  `NotApproved`.
* Set `canExecute = $false` for workflow and all steps.
* Include exact source mirror paths and expected SHA-256 values for the five
  Path B steps.
* Clearly state that it is non-executing schema/reference only.

## Path A / Path B Relationship Schema

Future schema should represent:

* Path A reference: `Driver Install Debloat & Settings`.
* Path B reference:
  `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`.
* Mutual exclusion through `mutuallyExclusiveWorkflowIds`.
* Guided selection through explicit `workflowPathLabel` and `userIntent`.
* Accidental mixing prevention through `mixingPolicy`.
* Future explicit mixing approval if ever allowed through a separate
  production approval and runtime gating design.
* Blocking messages when conflicting path is selected or applied.
* Clear user-facing language that Path B is for users who want to keep or use
  NVIDIA App features such as recording or related NVIDIA App features.

Path B must never silently call Path A behavior. Path A must never silently call Path B behavior.

## Gate And Approval Dependency Schema

Future schema should reference these gate and approval sources:

* Production Approval Gate Design:
  `docs/tool-designs/nvidia-path-b-production-approval-gate-design.md`
* Runtime Gating Design:
  `docs/tool-designs/nvidia-path-b-runtime-gating-design.md`
* Draft Allowlist Proposal:
  `docs/tool-designs/nvidia-path-b-draft-allowlist-proposal.md`
* Artifact Provenance Review:
  `docs/tool-designs/nvidia-path-b-artifact-provenance-review.md`
* Profile State Capture Model:
  `docs/nvidia-profile-state-capture-model.md`
* Production Allowlist Governance:
  `docs/production-allowlist-governance.md`
* Download Provenance and Installer Execution Policy:
  `docs/download-provenance-installer-policy.md`
* Driver State Capture and Rollback:
  `docs/driver-state-capture-rollback.md`
* File/Registry State Capture and Rollback:
  `docs/file-registry-state-capture-rollback.md`
* Process Handling Policy:
  `docs/process-handling-policy.md`
* Reboot/Recovery Workflow:
  `docs/reboot-recovery-workflow.md`
* Restore Selection UI / Runtime:
  `docs/restore-selection-ui-runtime.md`

Dependency schema rules:

* Missing production approval keeps workflow and steps `NotApproved`.
* Missing artifact provenance keeps download, installer, external executable,
  Profile Inspector, and `.nip` operations blocked.
* Missing driver/profile capture keeps driver/profile/profile-import behavior
  blocked.
* Missing registry rollback capture keeps Windows Registry mutation blocked.
* Missing process policy keeps installer handoff, Profile Inspector launch, and
  NVIDIA Control Panel launch blocked.
* Missing reboot policy keeps reboot/device-restart/session behavior blocked.
* Missing Restore Selection keeps Restore denied.

## Non-Execution Guarantees

Future schema and any later inert schema file must guarantee:

* Schema must not contain direct script execution commands.
* Schema must not contain PowerShell command lines to run Path B.
* Schema must not contain download URLs as approved sources.
* Schema must not contain installer commands.
* Schema must not contain Profile Inspector execution commands.
* Schema must not contain registry write commands.
* Schema must not contain DDU references as executable entries.
* Schema must not expose action buttons as enabled.
* Schema must not change official counts.
* Schema must not create a module path, handler id, script path, or action id
  that runtime can execute.
* Schema must not become discoverable as an executable workflow until a future
  explicit runtime and UI phase approves that transition.

## Future Promotion Path

This schema could later become active only through separate future phases:

1. Separate approval to create a real workflow registry.
2. Production allowlist approvals.
3. Artifact approvals.
4. Per-step implementation modules.
5. Runtime gate evaluator.
6. UI implementation.
7. Validators proving `canExecute` remains false until approvals exist.
8. Final integration validation.

Each promotion phase must remain narrow. A future workflow registry alone must
not imply artifact approval, production allowlist approval, UI enablement,
module creation, action-button enablement, or execution permission.

## Explicit Non-Actions

Phase 82 is non-executing schema design only.

* No runtime workflow registry enabled.
* No active config created.
* No production config or allowlist config created or changed.
* No production approval granted.
* No executable handler/module/action created.
* No tool or placeholder enabled.
* No UI implementation added.
* No runtime behavior changed.
* No source mirror files changed.
* No intake files changed.
* No legacy source-ultimate files changed.
* No artifact, download, installer, Profile Inspector, `.nip`, driver,
  profile, Windows Registry, file, process, reboot, Default, or Restore
  approval added.
* No AppX, service, task, cleanup, TrustedInstaller, or Safe Mode approval
  added.
* No DDU execution/download/artifact approval added.
* Standalone DDU not introduced.
* Loudness EQ and NVME Faster Driver remain deleted.
* Counts unchanged: 48 active tools, 30 implemented tools, 18
  deferred/placeholders, and 7 source-promoted intake candidates separate from
  official counts.

## Recommended Next Phase

Recommended next phase: **NVIDIA Path B Readiness Badge Design**.

That phase should remain UI/design-only unless Yazan explicitly approves a
narrower runtime foundation. It should describe how future UI could show
catalog-only Path B readiness, missing gate categories, and Path A/Path B
conflict state without enabling action buttons, creating modules, approving
artifacts, or changing runtime behavior.

Phase 83 records that badge design in
`docs/tool-designs/nvidia-path-b-readiness-badge-design.md`. It creates no live
UI badges, active badge config, runtime config, production config, modules,
tool cards, placeholder enablement, or Path B execution behavior.

Phase 84 records path conflict copy/status text design in
`docs/tool-designs/nvidia-path-b-path-conflict-copy-status-text-design.md`. It
adds no live UI strings, active UI config, localization files, runtime config,
production config, modules, tool cards, placeholder enablement, or Path B
execution behavior.
