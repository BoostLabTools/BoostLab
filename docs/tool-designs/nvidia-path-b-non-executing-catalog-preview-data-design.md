# NVIDIA Path B Non-Executing Catalog Preview Data Design

## Purpose And Status

Phase 85 defines non-executing catalog preview data design for NVIDIA App Path B.

This is non-executing catalog preview data design only. Preview data is informational only. No live catalog or runtime registry is enabled. No UI implementation is added. No runtime behavior changes. No tool card or placeholder is enabled. No executable workflow is created. No production approval is granted.

This document does not create active UI config, active runtime config,
production config, allowlist config, runtime module, executable helper, tool
module, or WPF runtime behavior.

NVIDIA App Path B exact required order:

`Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

Path relationship:

* Path A: `Driver Install Debloat & Settings`
* Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`
* Path A is the debloat/configuration workflow.
* Path B is the NVIDIA App compatible workflow for users who want to keep or
  use NVIDIA App features such as recording or related NVIDIA App features.
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

## Preview Data Concepts

Future preview data concepts:

* preview workflow: a read-only representation of the whole Path B workflow.
* preview path: the Path A or Path B identity shown to the technician.
* preview step: one ordered Path B step shown without execution.
* preview badge set: readiness badges displayed for workflow or step state.
* preview blocker summary: readable list of blockers preventing execution.
* preview status text: user-facing wording for current preview state.
* preview source binding: source mirror path and expected checksum.
* preview checksum: SHA-256 expected for the source mirror reference.
* preview design references: design documents that explain this preview.
* preview approval references: future approval documents required before
  execution.
* preview missing requirement list: approvals, scopes, captures, provenance, or
  gates still absent.
* preview action availability: explicit disabled/enabled display state, always
  non-executing in current design.
* preview restore/default status: future Restore and Default availability state
  without enabling either action.
* preview user copy: beginner-friendly text shown to technicians.
* preview admin details: expanded technical status and gate details.
* preview localization placeholder: future localization-ready text slot without
  localization runtime files.
* preview non-execution guarantee: explicit fields proving no execution is
  enabled.

## Required Workflow Preview Fields

Required future workflow preview fields:

* `previewId`
* `workflowId`
* `workflowName`
* `workflowPathLabel`
* `workflowSummary`
* `workflowStatus`
* `implementationStatus`
* `executionStatus`
* `stage`
* `category`
* `selectedPath`
* `pathAReference`
* `pathBReference`
* `mixingPolicy`
* `targetVendor`
* `unsupportedTargets`
* `orderedStepIds`
* `canShowAsPreview`
* `canExecute`
* `isExecutionEnabling`
* `workflowBadges`
* `workflowBlockingReasons`
* `workflowStatusText`
* `beginnerSummary`
* `advancedSummary`
* `documentationReferences`
* `lastReviewedPhase`
* `sourcePromotedCandidateCount`
* `officialCountImpact`
* `notes`

## Required Step Preview Fields

Required future step preview fields:

* `stepId`
* `stepNumber`
* `stepName`
* `displayName`
* `shortPurpose`
* `sourceMirrorPath`
* `sourceRelativePath`
* `sourceChecksum`
* `checksumAlgorithm`
* `stepStatus`
* `implementationStatus`
* `gateState`
* `canAnalyze`
* `canApply`
* `canDefault`
* `canRestore`
* `canExecute`
* `isExecutionEnabling`
* `badgeSet`
* `blockingReasons`
* `missingApprovals`
* `missingProvenance`
* `missingRollbackCaptures`
* `missingProfileCapture`
* `missingProcessPolicy`
* `missingRebootPolicy`
* `nvidiaTargetingStatus`
* `pathConflictStatus`
* `restoreStatus`
* `defaultStatus`
* `disabledActionTextReferences`
* `actionPlanPreconditionReferences`
* `latestResultTemplateReference`
* `activityLogTemplateReference`
* `designReferences`
* `futureApprovalReferences`
* `userFacingStatusText`
* `adminStatusText`

## Non-Executing Preview Data Example

This pseudo-PSD1 example is documentation-only. It is not a config file, is not
loaded by runtime, and is not execution permission.

```powershell
@{
    previewId = 'nvidia.pathB.preview'
    workflowId = 'nvidia.pathB'
    workflowName = 'NVIDIA App Compatible Workflow'
    workflowPathLabel = 'Path B'
    workflowSummary = 'Preview-only data for the future NVIDIA App compatible workflow.'
    workflowStatus = 'PreviewOnly'
    implementationStatus = 'NotImplemented'
    executionStatus = 'NotApproved'
    stage = 'Graphics'
    category = 'NVIDIA'
    selectedPath = 'Path B'
    pathAReference = 'Driver Install Debloat & Settings'
    pathBReference = 'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
    mixingPolicy = 'BlockedUntilFutureExplicitApproval'
    targetVendor = 'NVIDIA'
    unsupportedTargets = @('AMD GPU-specific branches', 'Intel GPU-specific branches', 'Standalone DDU')
    orderedStepIds = @(
        'nvidia.pathB.driverInstallLatest'
        'nvidia.pathB.nvidiaSettings'
        'nvidia.pathB.hdcp'
        'nvidia.pathB.p0State'
        'nvidia.pathB.msiMode'
    )
    canShowAsPreview = $true
    canExecute = $false
    isExecutionEnabling = $false
    workflowBadges = @('DesignOnly', 'CatalogOnly', 'SourcePromoted', 'NotImplemented', 'Blocked')
    workflowBlockingReasons = @('Missing production approval', 'Missing runtime gate', 'Missing allowlists')
    workflowStatusText = 'Path B is available as preview data only and cannot execute.'
    beginnerSummary = 'Path B is planned for NVIDIA App compatibility but is not active yet.'
    advancedSummary = 'Preview data references source-promoted scripts, missing gates, and non-executing blockers.'
    documentationReferences = @(
        'docs/nvidia-path-b-catalog-design.md'
        'docs/tool-designs/nvidia-path-b-readiness-badge-design.md'
        'docs/tool-designs/nvidia-path-b-path-conflict-copy-status-text-design.md'
    )
    lastReviewedPhase = 85
    sourcePromotedCandidateCount = 7
    officialCountImpact = 'None; source-promoted candidates remain separate from official active tool counts.'
    notes = 'No executable handler exists. No action id maps to execution. No module path exists. No command line exists. No download URL is marked approved. No installer action is marked approved. Official counts remain unchanged.'
    steps = @(
        @{
            stepId = 'nvidia.pathB.driverInstallLatest'
            stepNumber = 1
            stepName = 'Driver Install Latest'
            displayName = 'Driver Install Latest'
            shortPurpose = 'Future NVIDIA driver install path that keeps NVIDIA App compatibility.'
            sourceMirrorPath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
            sourceRelativePath = '5 Graphics/2 Driver Install Latest.ps1'
            sourceChecksum = '41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F'
            checksumAlgorithm = 'SHA-256'
            stepStatus = 'PreviewOnly'
            implementationStatus = 'NotImplemented'
            gateState = 'Blocked'
            canAnalyze = $false
            canApply = $false
            canDefault = $false
            canRestore = $false
            canExecute = $false
            isExecutionEnabling = $false
            badgeSet = @('NotImplemented', 'SourcePromoted', 'NeedsProvenance', 'NeedsAllowlist', 'NeedsDriverRollback', 'NeedsProcessPolicy', 'NeedsRebootPolicy', 'NeedsApprovalGate')
            blockingReasons = @('Missing driver artifact provenance', 'Missing driver rollback scope', 'Missing process policy', 'Missing reboot policy')
            missingApprovals = @('ProductionApprovalGate')
            missingProvenance = @('NvidiaDriverArtifact')
            missingRollbackCaptures = @('DriverStateCapture')
            missingProfileCapture = @()
            missingProcessPolicy = @('InstallerProcessHandoff')
            missingRebootPolicy = @('DriverInstallerRebootDisclosure')
            nvidiaTargetingStatus = 'NotVerified'
            pathConflictStatus = 'UnknownUntilFutureRuntime'
            restoreStatus = 'RestoreUnavailable'
            defaultStatus = 'DefaultUnavailable'
            disabledActionTextReferences = @('docs/tool-designs/nvidia-path-b-path-conflict-copy-status-text-design.md')
            actionPlanPreconditionReferences = @('docs/tool-designs/nvidia-path-b-path-conflict-copy-status-text-design.md')
            latestResultTemplateReference = 'docs/tool-designs/nvidia-path-b-path-conflict-copy-status-text-design.md'
            activityLogTemplateReference = 'docs/tool-designs/nvidia-path-b-path-conflict-copy-status-text-design.md'
            designReferences = @('docs/tool-designs/nvidia-path-b-scope-design.md')
            futureApprovalReferences = @('docs/tool-designs/nvidia-path-b-production-approval-gate-design.md')
            userFacingStatusText = 'Driver Install Latest is preview-only and cannot run.'
            adminStatusText = 'Missing provenance, rollback, process, reboot, and approval gates.'
        }
        @{
            stepId = 'nvidia.pathB.nvidiaSettings'
            stepNumber = 2
            stepName = 'Nvidia Settings'
            displayName = 'Nvidia Settings'
            shortPurpose = 'Future NVIDIA Profile Inspector and profile/settings step.'
            sourceMirrorPath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
            sourceRelativePath = '5 Graphics/4 Nvidia Settings.ps1'
            sourceChecksum = '903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5'
            checksumAlgorithm = 'SHA-256'
            stepStatus = 'PreviewOnly'
            implementationStatus = 'NotImplemented'
            gateState = 'Blocked'
            canAnalyze = $false
            canApply = $false
            canDefault = $false
            canRestore = $false
            canExecute = $false
            isExecutionEnabling = $false
            badgeSet = @('NotImplemented', 'SourcePromoted', 'NeedsProvenance', 'NeedsAllowlist', 'NeedsProfileCapture', 'NeedsRegistryRollback', 'NeedsProcessPolicy', 'NeedsApprovalGate')
            blockingReasons = @('Missing Profile Inspector provenance', 'Missing profile capture', 'Missing registry rollback', 'Missing process policy')
            missingApprovals = @('ProductionApprovalGate')
            missingProvenance = @('ProfileInspectorArtifact', 'NipArtifacts')
            missingRollbackCaptures = @('RegistryCapture', 'FileCapture')
            missingProfileCapture = @('NvidiaProfilePreCapture')
            missingProcessPolicy = @('ProfileInspectorProcessPolicy')
            missingRebootPolicy = @()
            nvidiaTargetingStatus = 'NotVerified'
            pathConflictStatus = 'UnknownUntilFutureRuntime'
            restoreStatus = 'RestoreUnavailable'
            defaultStatus = 'DefaultUnavailable'
            canExecute = $false
            isExecutionEnabling = $false
        }
        @{
            stepId = 'nvidia.pathB.hdcp'
            stepNumber = 3
            stepName = 'Hdcp'
            displayName = 'Hdcp'
            shortPurpose = 'Future HDCP/content-protection registry step.'
            sourceMirrorPath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1'
            sourceRelativePath = '5 Graphics/5 Hdcp.ps1'
            sourceChecksum = '5C350D28F795D678051E6088F34968DF8D90B3D9024F558C5FAFB2899D1A906A'
            checksumAlgorithm = 'SHA-256'
            stepStatus = 'PreviewOnly'
            implementationStatus = 'NotImplemented'
            gateState = 'Blocked'
            canAnalyze = $false
            canApply = $false
            canDefault = $false
            canRestore = $false
            canExecute = $false
            isExecutionEnabling = $false
            badgeSet = @('NotImplemented', 'SourcePromoted', 'NeedsAllowlist', 'NeedsRegistryRollback', 'NeedsNvidiaTargeting', 'NeedsSecurityReview', 'NeedsApprovalGate')
            blockingReasons = @('Missing exact registry scope', 'Missing NVIDIA targeting', 'Missing security review')
            missingApprovals = @('SecurityReview', 'ProductionApprovalGate')
            missingRollbackCaptures = @('RegistryCapture')
            nvidiaTargetingStatus = 'NotVerified'
        }
        @{
            stepId = 'nvidia.pathB.p0State'
            stepNumber = 4
            stepName = 'P0 State'
            displayName = 'P0 State'
            shortPurpose = 'Future P0 performance-state registry step.'
            sourceMirrorPath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1'
            sourceRelativePath = '5 Graphics/6 P0 State.ps1'
            sourceChecksum = '382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC'
            checksumAlgorithm = 'SHA-256'
            stepStatus = 'PreviewOnly'
            implementationStatus = 'NotImplemented'
            gateState = 'Blocked'
            canAnalyze = $false
            canApply = $false
            canDefault = $false
            canRestore = $false
            canExecute = $false
            isExecutionEnabling = $false
            badgeSet = @('NotImplemented', 'SourcePromoted', 'NeedsAllowlist', 'NeedsRegistryRollback', 'NeedsNvidiaTargeting', 'NeedsSecurityReview', 'NeedsApprovalGate')
            blockingReasons = @('Missing exact registry scope', 'Missing NVIDIA targeting', 'Missing stability/security review')
            missingApprovals = @('PowerThermalStabilityReview', 'ProductionApprovalGate')
            missingRollbackCaptures = @('RegistryCapture')
            nvidiaTargetingStatus = 'NotVerified'
        }
        @{
            stepId = 'nvidia.pathB.msiMode'
            stepNumber = 5
            stepName = 'Msi Mode'
            displayName = 'Msi Mode'
            shortPurpose = 'Future MSI interrupt-mode registry step.'
            sourceMirrorPath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1'
            sourceRelativePath = '5 Graphics/7 Msi Mode.ps1'
            sourceChecksum = '94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7'
            checksumAlgorithm = 'SHA-256'
            stepStatus = 'PreviewOnly'
            implementationStatus = 'NotImplemented'
            gateState = 'Blocked'
            canAnalyze = $false
            canApply = $false
            canDefault = $false
            canRestore = $false
            canExecute = $false
            isExecutionEnabling = $false
            badgeSet = @('NotImplemented', 'SourcePromoted', 'NeedsAllowlist', 'NeedsRegistryRollback', 'NeedsNvidiaTargeting', 'NeedsRebootPolicy', 'NeedsApprovalGate')
            blockingReasons = @('Missing exact registry scope', 'Missing NVIDIA targeting', 'Missing reboot/device restart disclosure')
            missingApprovals = @('ProductionApprovalGate')
            missingRollbackCaptures = @('RegistryCapture')
            missingRebootPolicy = @('DeviceRestartDisclosure')
            nvidiaTargetingStatus = 'NotVerified'
        }
    )
}
```

Non-execution guarantees in the example:

* `workflowId` is `nvidia.pathB`.
* `previewId` is `nvidia.pathB.preview`.
* All five steps are in exact order.
* `canExecute` is false for workflow and every step.
* `isExecutionEnabling` is false for workflow and every step.
* No executable handler exists.
* No action id maps to execution.
* No module path exists.
* No command line exists.
* No download URL is marked approved.
* No installer action is marked approved.
* Badges and blockers reflect current design-only state.
* Official counts remain unchanged.

## Optional Inert Preview Sample File

Phase 85 does not create `config/NvidiaPathBPreview.Schema.psd1`.

Reason: this phase is design-only and explicitly says not to create active UI
config or active runtime config. Keeping the sample inside documentation avoids
confusing preview data with a runtime-consumed catalog.

If a future phase creates `config/NvidiaPathBPreview.Schema.psd1`, it must:

* Be schema/sample preview data only.
* Not be consumed by runtime.
* Not register a live workflow.
* Not enable UI/tool cards.
* Not include executable handlers, commands, module paths, script execution
  instructions, or action ids that execute anything.
* Set `canExecute = $false` for workflow and all steps.
* Set `isExecutionEnabling = $false` for workflow and all steps.
* Use non-executing statuses like `DesignOnly`, `NotImplemented`,
  `NotApproved`, and `PreviewOnly`.
* Include exact source mirror paths and expected SHA-256 values for the five
  Path B steps.
* Clearly state that it is non-executing preview/schema reference only.

## Preview Badge And Blocker Mapping

Preview data should reference:

| Preview item | Reference source | Current preview meaning |
|---|---|---|
| readiness badges | `docs/tool-designs/nvidia-path-b-readiness-badge-design.md` | Badges explain current blockers and design-only state. |
| runtime gates | `docs/tool-designs/nvidia-path-b-runtime-gating-design.md` | Gate names explain why execution remains blocked. |
| path conflict text | `docs/tool-designs/nvidia-path-b-path-conflict-copy-status-text-design.md` | Text explains Path A/Path B conflict and selected path state. |
| disabled action text | `docs/tool-designs/nvidia-path-b-path-conflict-copy-status-text-design.md` | Disabled action reasons explain why no action was performed. |
| missing provenance | Download Provenance and Installer Execution Policy | Preview can list missing artifacts, but cannot approve them. |
| missing rollback capture | File/Registry and Driver rollback foundations | Preview can list capture requirements, but cannot mutate state. |
| missing profile capture | NVIDIA Profile State Capture Model | Preview can show profile capture requirement. |
| missing NVIDIA targeting | Driver State Capture and Rollback | Preview can show NVIDIA-only target verification missing. |
| missing approval gate | Production Approval Gate Design | Preview can show production approval missing. |
| Restore unavailable/denied | Restore Selection UI / Runtime | Preview can show Restore state without enabling Restore. |
| Default unavailable | Runtime Gating Design | Preview can show Default state without enabling Default. |

## Preview Action Availability Rules

Current preview action availability rules:

* Analyze/Apply/Default/Restore/Continue/Skip/Download/Install/Import Profile
  must be unavailable in current preview.
* Disabled actions must include reason text references.
* Preview data must not cause buttons to become enabled.
* Preview data must not be interpreted as runtime gate success.
* Preview data must show that all current Path B steps are `NotImplemented` /
  `DesignOnly`.
* Preview data must not become a source of executable action ids.
* Preview data must not substitute for artifact, allowlist, rollback, profile,
  process, reboot, Restore, or production approval.

## Relationship To Existing Documents

This catalog preview data design relates to:

* NVIDIA Path B Catalog Design:
  `docs/nvidia-path-b-catalog-design.md`
* NVIDIA Path B UI Workflow Design:
  `docs/nvidia-path-b-ui-workflow-design.md`
* NVIDIA Path B Readiness Badge Design:
  `docs/tool-designs/nvidia-path-b-readiness-badge-design.md`
* NVIDIA Path B Path Conflict Copy And Status Text Design:
  `docs/tool-designs/nvidia-path-b-path-conflict-copy-status-text-design.md`
* NVIDIA Path B Runtime Gating Design:
  `docs/tool-designs/nvidia-path-b-runtime-gating-design.md`
* NVIDIA Path B Non-Executing Workflow Registry Schema Design:
  `docs/tool-designs/nvidia-path-b-non-executing-workflow-registry-schema-design.md`
* NVIDIA Path B Production Approval Gate Design:
  `docs/tool-designs/nvidia-path-b-production-approval-gate-design.md`
* NVIDIA Path B Draft Allowlist Proposal:
  `docs/tool-designs/nvidia-path-b-draft-allowlist-proposal.md`
* NVIDIA Path B Artifact Provenance Review:
  `docs/tool-designs/nvidia-path-b-artifact-provenance-review.md`
* NVIDIA Profile State Capture Model:
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

This relationship is documentation-only. It does not create a live catalog,
runtime registry, active UI config, active runtime config, production approval,
or Path B execution.

## Explicit Non-Actions

Phase 85 is catalog preview data design only.

* No live catalog preview implemented.
* No active UI config created.
* No active runtime config created.
* No production config or allowlist config created or changed.
* No production approval granted.
* No executable handler/module/action created.
* No tool or placeholder enabled.
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

Recommended next phase: **NVIDIA Path B Preview Data Integrity And Drift Rules
Design**.

That phase should remain design-only unless Yazan explicitly approves a narrow
foundation. It should define how future preview-only data would detect stale
source checksum, stale badge/gate references, and documentation drift without
creating active UI config, runtime config, production config, modules, action
buttons, artifacts, allowlists, or execution behavior.

Phase 86 records that integrity/drift rules design in
`docs/tool-designs/nvidia-path-b-preview-data-integrity-drift-rules-design.md`.
It creates no live drift checker, active preview config, active UI config,
runtime config, production approval, or Path B execution behavior.

Phase 87 records documentation index/navigation design in
`docs/tool-designs/nvidia-path-b-documentation-index-navigation-design.md`. It
adds a documentation-only map of the Path B doc set without creating live UI
navigation, active docs runtime, active config, or execution behavior.

Phase 88 records documentation backlink audit design in
`docs/tool-designs/nvidia-path-b-documentation-backlink-audit-design.md`. It
defines future backlink audit rules without creating a live backlink auditor,
active docs runtime, active config, production approval, or Path B execution
behavior.
