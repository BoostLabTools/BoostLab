# NVIDIA Path B Preview Data Integrity And Drift Rules Design

## Purpose And Status

Phase 86 defines preview data integrity and drift rules design for NVIDIA App
Path B.

This is preview data integrity and drift rules design only. No live drift checker is implemented. No active preview data config is created. No live catalog or runtime registry is enabled. No UI implementation is added. No runtime behavior changes. No tool card or placeholder is enabled. No executable workflow is created. No production approval is granted.

Terminology:

* Integrity means the preview data matches expected source, checksum, order,
  status, and non-execution guarantees.
* Drift means a preview field, document reference, status, badge, gate, source
  checksum, source path, or count becomes outdated or inconsistent with the
  approved design.
* This phase does not touch Windows Registry.

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

* Driver Clean remains outside the five-step NVIDIA Path B preview and needs a
  separate Driver Clean scope/provenance/safety design later.
* BitLocker remains outside the five-step NVIDIA Path B preview and needs
  future security-sensitive design.

## Integrity Concepts

Future integrity concepts:

* source mirror integrity: every referenced source mirror file exists.
* source checksum integrity: every source mirror SHA-256 matches the approved
  expected checksum.
* Path B order integrity: the preview always lists the five Path B steps in the
  approved order.
* source path binding integrity: each step remains bound to the approved source
  mirror path.
* workflow id integrity: preview workflow id remains `nvidia.pathB`.
* step id integrity: step ids remain stable and map to the correct ordered
  step.
* badge mapping integrity: badge sets match the readiness badge design.
* gate mapping integrity: gate references match the runtime gating design.
* copy/status text integrity: status text references match the copy/status text
  design.
* preview action availability integrity: preview action availability remains
  disabled and non-executing.
* non-execution integrity: no preview field enables execution or maps to a
  handler, command, action id, module path, script, download, installer, or
  Profile Inspector call.
* count separation integrity: source-promoted candidates remain separate from
  official active/implemented/deferred counts.
* documentation reference integrity: preview references point to existing
  governance and design documents.
* approval dependency integrity: missing approvals stay visible and do not
  become implied approvals.
* Restore/Default semantic integrity: Restore and Default remain separate and
  unavailable unless a future phase explicitly approves them.

## Drift Concepts

Future drift categories:

* `SourceChecksumDrift`
* `SourcePathDrift`
* `PathOrderDrift`
* `StepMetadataDrift`
* `BadgeMappingDrift`
* `GateMappingDrift`
* `StatusTextDrift`
* `PreviewActionDrift`
* `DocumentationReferenceDrift`
* `ApprovalStateDrift`
* `ProductionApprovalDrift`
* `CountDrift`
* `RestoreDefaultSemanticDrift`
* `ExecutionEnablementDrift`
* `PathConflictPolicyDrift`
* `UnsupportedTargetPolicyDrift`

Any `ExecutionEnablementDrift` must be treated as critical and must fail closed.

## Required Future Integrity Rules

Required future integrity rules:

* Path B preview must always list exactly five steps in the approved order.
* Every preview step source mirror path must match the approved source mirror
  path.
* Every preview step SHA-256 must match the approved checksum.
* Every step must keep `canExecute = $false` until a future implementation
  approval explicitly changes it.
* Every current Path B badge must keep `isExecutionEnabling = $false`.
* Preview action availability must keep Analyze/Apply/Default/Restore/Continue/Skip/Download/Install/Import Profile unavailable until later approval.
* Preview data must not be counted as active, implemented, or deferred placeholders.
* Preview data must remain separate from official 48/30/18 counts.
* Path A/Path B conflict policy must remain visible.
* Restore must not be confused with Default.
* Missing provenance/rollback/profile capture/NVIDIA targeting must remain visible blockers.
* Any mismatch must block future runtime consumption.
* Driver Clean and BitLocker must remain outside the five-step Path B preview.
* Standalone DDU must remain absent.
* Loudness EQ and NVME Faster Driver must remain deleted.

## Drift Detection Rules

Future drift detection rules:

* Recompute source mirror checksums and compare with expected values.
* Verify exact step order.
* Verify required step ids and names.
* Verify source mirror files still exist.
* Verify badge sets match readiness badge design.
* Verify gate references match runtime gating design.
* Verify path conflict status text references exist.
* Verify non-executing preview flags remain false.
* Verify no preview field implies production approval.
* Verify official counts did not absorb source-promoted intake candidates.
* Verify Driver Clean and BitLocker remain outside the five-step Path B preview.
* Verify standalone DDU remains absent.
* Verify Loudness EQ and NVME Faster Driver remain deleted.
* Verify no active preview config, UI config, runtime config, production config,
  allowlist config, runtime module, helper, or tool module appeared without a
  future explicit phase.

## Drift Severity Model

Future severity levels:

* `Info`
* `Warning`
* `Blocking`
* `Critical`

Severity mapping:

| Severity | Drift categories |
|---|---|
| `Critical` | `ExecutionEnablementDrift`, `SourceChecksumDrift`, `SourcePathDrift`, `PathOrderDrift`, `ProductionApprovalDrift`, `StandaloneDduDrift`, `DeletedToolDrift` |
| `Blocking` | `BadgeMappingDrift`, `GateMappingDrift`, `PreviewActionDrift`, `CountDrift`, `RestoreDefaultSemanticDrift` |
| `Warning` | `DocumentationReferenceDrift`, `StatusTextDrift`, `StepMetadataDrift`, `ApprovalStateDrift`, `PathConflictPolicyDrift`, `UnsupportedTargetPolicyDrift` |
| `Info` | wording-only review notes that do not affect gates |

## Future Drift Response Behavior

Future drift response behavior:

* Critical drift must fail closed.
* Blocking drift must prevent preview from being consumed by runtime.
* Warning drift must require review before activation.
* Info drift may be documented for future cleanup.
* Drift reports must include source, expected value, actual value, severity,
  related document, and recommended resolution.
* No auto-fix should move or rewrite source mirror files without explicit phase approval.
* No drift response should enable execution.
* Drift response must not approve production scopes, artifacts, downloads,
  installers, Profile Inspector, `.nip` import/export, driver/profile changes,
  registry/file/process/reboot behavior, Default, or Restore.

## Preview Data Integrity Report Schema

Future report object fields:

* `reportId`
* `workflowId`
* `reviewedAt`
* `reviewedBy`
* `expectedStepOrder`
* `actualStepOrder`
* `sourceChecksums`
* `checksumResults`
* `pathResults`
* `badgeResults`
* `gateResults`
* `actionAvailabilityResults`
* `documentationReferenceResults`
* `countResults`
* `driftFindings`
* `highestSeverity`
* `canUsePreview`
* `canExecute`
* `recommendedAction`
* `activityLogEvent`

Current design requires `canExecute = $false`.

Example future report shape:

```powershell
@{
    reportId = 'nvidia.pathB.preview.integrity.phase86.example'
    workflowId = 'nvidia.pathB'
    reviewedAt = '<future timestamp>'
    reviewedBy = 'BoostLab future drift checker'
    expectedStepOrder = @('Driver Install Latest', 'Nvidia Settings', 'Hdcp', 'P0 State', 'Msi Mode')
    actualStepOrder = @('Driver Install Latest', 'Nvidia Settings', 'Hdcp', 'P0 State', 'Msi Mode')
    sourceChecksums = @{}
    checksumResults = @()
    pathResults = @()
    badgeResults = @()
    gateResults = @()
    actionAvailabilityResults = @()
    documentationReferenceResults = @()
    countResults = @()
    driftFindings = @()
    highestSeverity = 'Info'
    canUsePreview = $false
    canExecute = $false
    recommendedAction = 'Review only; no execution is enabled.'
    activityLogEvent = 'NVIDIA Path B preview integrity reviewed in design-only mode.'
}
```

## Relationship To Existing Documents

This integrity/drift rules design relates to:

* NVIDIA Path B Non-Executing Catalog Preview Data Design:
  `docs/tool-designs/nvidia-path-b-non-executing-catalog-preview-data-design.md`
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
* NVIDIA Path B UI Workflow Design:
  `docs/nvidia-path-b-ui-workflow-design.md`
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

This relationship is documentation-only. It does not create live drift
checking, preview config, UI config, runtime config, production approval, or
Path B execution.

## Explicit Non-Actions

Phase 86 is integrity/drift rules design only.

* No live drift checker implemented.
* No active preview config created.
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

Recommended next phase: **NVIDIA Path B Documentation Index And Navigation
Design**.

That phase should remain documentation-only unless Yazan explicitly approves a
narrow foundation. It should create a navigable index of Path B design
documents and validators without creating active preview config, UI config,
runtime config, production config, modules, action buttons, artifacts,
allowlists, or execution behavior.

Phase 87 records that documentation index/navigation design in
`docs/tool-designs/nvidia-path-b-documentation-index-navigation-design.md`. It
creates no live UI navigation, active docs runtime, active config, modules,
tool cards, placeholder enablement, or Path B execution behavior.

Phase 88 records documentation backlink audit design in
`docs/tool-designs/nvidia-path-b-documentation-backlink-audit-design.md`. It
defines future backlink audit rules without creating a live backlink auditor,
active docs runtime, active config, production approval, or Path B execution
behavior.

Phase 89 records governance freeze review in
`docs/tool-designs/nvidia-path-b-governance-freeze-review.md`. It freezes the
Path B documentation set as design-only and non-executing without creating
active governance runtime, production approval, UI approval, runtime approval,
or Path B execution behavior.
