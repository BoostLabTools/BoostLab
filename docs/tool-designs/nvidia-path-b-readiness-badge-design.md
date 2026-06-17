# NVIDIA Path B Readiness Badge Design

## Purpose And Status

Phase 83 defines readiness badge design for NVIDIA App Path B.

This is readiness badge design only. No live UI badge implementation is added.
No runtime behavior changes. No tool card or placeholder is enabled. No executable workflow is created. No production approval is granted.

This document does not create active UI config, runtime config, production
config, allowlist config, runtime module, executable helper, tool module, or WPF
runtime behavior.

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

## Badge Taxonomy

Future readiness badges should be short user-visible labels backed by structured
status reasons. None of these badges enables execution in this phase.

| Badge | Meaning |
|---|---|
| `DesignOnly` | Documentation-only state; no active implementation exists. |
| `NotImplemented` | No executable module, handler, or action exists. |
| `SourcePromoted` | Source mirror exists under `_intake-promoted` with expected checksum. |
| `CatalogOnly` | Future catalog/design visibility only; no action button enablement. |
| `ScopeDesigned` | A design document exists, but production scope is not approved. |
| `NeedsProvenance` | Download, executable, installer, archive, Profile Inspector, or `.nip` provenance is missing. |
| `NeedsAllowlist` | Required production allowlist entry or exact target scope is missing. |
| `NeedsApprovalGate` | Production approval gate has not approved the workflow or step. |
| `NeedsRuntimeGate` | Runtime gate evaluator does not exist or has not approved execution. |
| `NeedsProfileCapture` | NVIDIA profile capture is required before profile mutation/import/Restore. |
| `NeedsRegistryRollback` | Exact registry capture/rollback scope is missing. |
| `NeedsDriverRollback` | Driver inventory/capture/rollback scope is missing. |
| `NeedsProcessPolicy` | Process start/close/wait/handoff policy is missing. |
| `NeedsRebootPolicy` | Reboot, device restart, or session-transition policy is missing. |
| `NeedsNvidiaTargeting` | NVIDIA-only target detection and disambiguation is missing. |
| `NeedsSecurityReview` | Security/content-protection or stability-sensitive review is missing. |
| `Blocked` | Execution must be blocked by current governance. |
| `PathConflict` | Path A and Path B state or selection conflicts. |
| `NotApplicable` | Step does not apply to detected future state or target. |
| `ReadyForReview` | Human review can continue, but execution is not approved. |
| `ReadyInFuturePhase` | Future phase may continue after approvals; not executable now. |
| `RestoreUnavailable` | Captured-state Restore is not available. |
| `RestoreDenied` | Restore was requested but policy/capture eligibility denies it. |
| `DefaultUnavailable` | Source-defined Default is unavailable or not approved. |
| `CompletedInFuture` | Future result state for a completed step. |
| `FailedInFuture` | Future result state for a failed step. |
| `RefusedInFuture` | Future result state for a policy refusal. |

## Badge State Rules

Rules for badge interpretation:

* A badge is informational unless future runtime explicitly consumes it.
* `ReadyInFuturePhase` must not mean executable now.
* `CompletedInFuture`, `FailedInFuture`, and `RefusedInFuture` are future result states only.
* `RestoreUnavailable` and `RestoreDenied` must not be hidden silently.
* `DefaultUnavailable` must not be confused with Restore.
* Path B badges must respect exact step order.
* Path A/Path B conflict badges must be visible when applicable.
* Missing production approval must show a blocking badge.
* Missing source checksum validation must show a blocking badge.
* Missing NVIDIA-only targeting must show a blocking badge.
* AMD/Intel GPU-specific behavior must be shown as unsupported for Path B.
* `CatalogOnly` and `DesignOnly` must not enable action buttons.
* `SourcePromoted` means the mirror exists; it does not approve execution.
* Blocking badges should remain visible in Latest Result and Activity Log
  rather than collapsing into a generic disabled state.
* Future badge consumers must preserve official counts unless a separate phase
  explicitly promotes Path B into active tools.

## Badge-To-Gate Mapping

| Badge | Related gate category | Triggering condition | User-facing message summary | Blocking or informational | Required future foundation | Current Path B status |
|---|---|---|---|---|---|---|
| `DesignOnly` | Not implemented gate | Documentation exists without implementation | Design-only, not executable | Informational and blocking for execution | Future implementation phase | Current |
| `NotImplemented` | Not implemented gate | No module, handler, or active workflow exists | Not implemented yet | Blocking | Tool/module implementation | Current |
| `SourcePromoted` | Source checksum gate | Source mirror exists with expected checksum | Source reference is available | Informational | Source checksum validation | Current |
| `CatalogOnly` | UI visibility gate | Future catalog display may exist without actions | Catalog/design reference only | Informational and blocking for execution | Future UI policy | Current |
| `ScopeDesigned` | Scope design gate | Scope design exists but scope is not approved | Scope has design, approval missing | Informational | Production allowlist approval | Partial |
| `NeedsProvenance` | Artifact provenance gate | Artifact URL/hash/signer/approval is missing | Artifact provenance missing | Blocking | Download Provenance and Installer Execution Policy | Current |
| `NeedsAllowlist` | Production allowlist gate | Exact tool/action/target scope is missing | Production allowlist missing | Blocking | Production Allowlist Governance | Current |
| `NeedsApprovalGate` | Approval gate | Production approval record is missing | Production approval missing | Blocking | Production Approval Gate Design | Current |
| `NeedsRuntimeGate` | Runtime gate | Future gate evaluator is absent or incomplete | Runtime gate missing | Blocking | Runtime Gating Design | Current |
| `NeedsProfileCapture` | Profile capture gate | NVIDIA profile mutation/import may occur | Profile capture required first | Blocking | NVIDIA Profile State Capture Model | Current |
| `NeedsRegistryRollback` | Registry rollback gate | Registry write/delete needs capture | Registry rollback capture required | Blocking | File/Registry State Capture and Rollback | Current |
| `NeedsDriverRollback` | Driver rollback gate | Driver install/change may occur | Driver rollback capture required | Blocking | Driver State Capture and Rollback | Current |
| `NeedsProcessPolicy` | Process policy gate | External process start/stop/wait/handoff is needed | Process policy missing | Blocking | Process Handling Policy | Current |
| `NeedsRebootPolicy` | Reboot/recovery gate | Reboot, device restart, or session transition is possible | Reboot policy missing | Blocking | Reboot/Recovery Workflow | Current |
| `NeedsNvidiaTargeting` | NVIDIA-only targeting gate | GPU/device/profile/registry target is ambiguous or not verified NVIDIA | NVIDIA target verification required | Blocking | Driver State Capture and Rollback | Current |
| `NeedsSecurityReview` | Security review gate | Content protection, HDCP, P-state, or interrupt behavior may affect security/stability | Security/stability review needed | Blocking | Production Approval Gate Design | Current |
| `Blocked` | Failure gate | Any required blocking gate fails | Blocked by governance | Blocking | Runtime Foundation | Current |
| `PathConflict` | Path A/Path B mutual exclusion gate | Path A and Path B selections or state conflict | Choose one NVIDIA workflow path | Blocking | Runtime Gating Design | Future |
| `NotApplicable` | Not applicable gate | Future target does not match step requirements | Not applicable to this target | Informational or blocking by context | Runtime Gating Design | Future |
| `ReadyForReview` | Approval review gate | Design evidence is complete enough for human review | Ready for review, not execution | Informational | Production Approval Gate Design | Future |
| `ReadyInFuturePhase` | Future promotion gate | A future phase may proceed after approvals | Ready in a future phase only | Informational and blocking for execution | Future approved phase | Future |
| `RestoreUnavailable` | Restore Selection gate | No valid capture exists | Restore is unavailable | Informational and blocking for Restore | Restore Selection UI / Runtime | Current |
| `RestoreDenied` | Restore Selection gate | Restore request lacks eligible capture or approval | Restore denied | Blocking | Restore Selection UI / Runtime | Current |
| `DefaultUnavailable` | Default availability gate | Source-defined Default is unavailable or not approved | Default unavailable | Blocking for Default | Runtime Gating Design | Current |
| `CompletedInFuture` | Verification/result gate | Future approved step completes | Step completed | Informational | Verification Contract | Future |
| `FailedInFuture` | Verification/result gate | Future approved step fails | Step failed | Informational/error result | Verification Contract | Future |
| `RefusedInFuture` | Refusal gate | Future request is refused by policy | Refused by policy | Blocking | Runtime Foundation | Future |

## Per-Step Readiness Badge Plan

### Driver Install Latest

Current design-only badges:

* `NotImplemented`
* `SourcePromoted`
* `NeedsProvenance`
* `NeedsAllowlist`
* `NeedsDriverRollback`
* `NeedsProcessPolicy`
* `NeedsRebootPolicy`
* `NeedsApprovalGate`

Future badge possibilities:

* `ReadyForReview` after artifact, driver, process, reboot, and approval
  evidence is complete.
* `PathConflict` if Path A state conflicts with Path B.
* `CompletedInFuture`, `FailedInFuture`, or `RefusedInFuture` only after a
  future executable implementation exists.

### Nvidia Settings

Current design-only badges:

* `NotImplemented`
* `SourcePromoted`
* `NeedsProvenance`
* `NeedsAllowlist`
* `NeedsProfileCapture`
* `NeedsRegistryRollback`
* `NeedsProcessPolicy`
* `NeedsApprovalGate`

Future badge possibilities:

* `RestoreUnavailable` until NVIDIA profile capture and Restore Selection
  records prove eligibility.
* `ReadyForReview` only after Profile Inspector, `.nip`, process, registry, and
  profile capture gates are fully documented and approved.

### Hdcp

Current design-only badges:

* `NotImplemented`
* `SourcePromoted`
* `NeedsAllowlist`
* `NeedsRegistryRollback`
* `NeedsNvidiaTargeting`
* `NeedsSecurityReview`
* `NeedsApprovalGate`

Future badge possibilities:

* `NotApplicable` if no eligible NVIDIA display-class target is found.
* `DefaultUnavailable` or `RestoreUnavailable` if source Default and captured
  Restore remain unavailable.

### P0 State

Current design-only badges:

* `NotImplemented`
* `SourcePromoted`
* `NeedsAllowlist`
* `NeedsRegistryRollback`
* `NeedsNvidiaTargeting`
* `NeedsSecurityReview`
* `NeedsApprovalGate`

Future badge possibilities:

* `NotApplicable` if no eligible NVIDIA target is found.
* `ReadyForReview` only after power, thermal, fan, battery, and stability
  warnings are approved.

### Msi Mode

Current design-only badges:

* `NotImplemented`
* `SourcePromoted`
* `NeedsAllowlist`
* `NeedsRegistryRollback`
* `NeedsNvidiaTargeting`
* `NeedsRebootPolicy`
* `NeedsApprovalGate`

Future badge possibilities:

* `NotApplicable` if no eligible NVIDIA display device instance is found.
* `RestoreDenied` if a future Restore request lacks an exact captured
  pre-change value.

## Workflow-Level Badge Plan

Current workflow-level badges:

* `DesignOnly`
* `CatalogOnly`
* `SourcePromoted`
* `NotImplemented`
* `Blocked`
* `PathConflict`
* `NeedsRuntimeGate`
* `NeedsApprovalGate`
* `NeedsAllowlist`
* `RestoreUnavailable`

Path B workflow-level `canExecute` remains false. No workflow-level badge in
this phase grants execution, Default, Restore, production approval, artifact
approval, or UI action enablement.

Workflow-level badge rules:

* `DesignOnly` and `CatalogOnly` explain visibility without execution.
* `PathConflict` must appear when future Path A/Path B state conflicts.
* `NeedsRuntimeGate`, `NeedsApprovalGate`, and `NeedsAllowlist` are blocking.
* `RestoreUnavailable` must appear for the workflow until future captured state
  and Restore Selection rules approve a specific restore request.

## Future UI Display Rules

Future UI display should follow these rules:

* Badges should be short and readable.
* Advanced details should be available through expanded details.
* Badge color/icon choices must be finalized in a later visual UI design phase.
* Badge text must not imply readiness to execute unless execution is truly approved later.
* Blockers should be shown before action buttons.
* Disabled action buttons should explain which badges block them.
* Path B ordered stepper should show badge clusters per step.
* Beginner users should see plain-language summaries.
* Advanced users should see source/gate/approval details.
* Badge details should reference source checksum and governance documents where
  useful.
* `RestoreUnavailable`, `RestoreDenied`, and `DefaultUnavailable` should be
  displayed as explicit state, not hidden inside a generic disabled button.
* Future Activity Log and Latest Result should preserve badge ids and
  user-facing messages for copyable diagnostics.

## Future Structured Badge Model

Future badge objects should use these fields:

* `badgeId`
* `badgeLabel`
* `badgeCategory`
* `severity`
* `isBlocking`
* `relatedGate`
* `relatedApproval`
* `relatedFoundation`
* `userMessage`
* `adminMessage`
* `stepId`
* `workflowId`
* `sourceChecksum`
* `statusReason`
* `nextResolutionAction`
* `documentationReference`
* `canClearAutomatically`
* `requiresFutureApproval`
* `isExecutionEnabling`

Current Path B rule: `isExecutionEnabling` must be false for all current Path B badges.

Example design-only object:

```powershell
@{
    badgeId = 'pathB.needsProvenance.driverInstallLatest'
    badgeLabel = 'Needs Provenance'
    badgeCategory = 'ArtifactProvenance'
    severity = 'Blocking'
    isBlocking = $true
    relatedGate = 'Artifact provenance gate'
    relatedApproval = 'ProductionApprovalGate'
    relatedFoundation = 'Download Provenance and Installer Execution Policy'
    userMessage = 'NVIDIA driver artifact provenance is not approved.'
    adminMessage = 'Missing approved artifact id, SHA-256, signer, size, and installer descriptor.'
    stepId = 'nvidia.pathB.driverInstallLatest'
    workflowId = 'nvidia.pathB'
    sourceChecksum = '41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F'
    statusReason = 'Artifact provenance and installer execution are denied by default.'
    nextResolutionAction = 'Future phase must approve exact artifact provenance and installer descriptor.'
    documentationReference = 'docs/tool-designs/nvidia-path-b-artifact-provenance-review.md'
    canClearAutomatically = $false
    requiresFutureApproval = $true
    isExecutionEnabling = $false
}
```

## Relationship To Existing Documents

This readiness badge design relates to:

* NVIDIA Path B Catalog Design:
  `docs/nvidia-path-b-catalog-design.md`
* NVIDIA Path B Scope Design:
  `docs/tool-designs/nvidia-path-b-scope-design.md`
* NVIDIA Path B Production Allowlist Planning:
  `docs/tool-designs/nvidia-path-b-production-allowlist-planning.md`
* NVIDIA Path B Artifact Provenance Review:
  `docs/tool-designs/nvidia-path-b-artifact-provenance-review.md`
* NVIDIA Profile State Capture Model:
  `docs/nvidia-profile-state-capture-model.md`
* NVIDIA Path B UI Workflow Design:
  `docs/nvidia-path-b-ui-workflow-design.md`
* NVIDIA Path B Draft Allowlist Proposal:
  `docs/tool-designs/nvidia-path-b-draft-allowlist-proposal.md`
* NVIDIA Path B Production Approval Gate Design:
  `docs/tool-designs/nvidia-path-b-production-approval-gate-design.md`
* NVIDIA Path B Runtime Gating Design:
  `docs/tool-designs/nvidia-path-b-runtime-gating-design.md`
* NVIDIA Path B Non-Executing Workflow Registry Schema Design:
  `docs/tool-designs/nvidia-path-b-non-executing-workflow-registry-schema-design.md`
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
* Final Deferred Tools Readiness Matrix:
  `docs/final-deferred-tools-readiness-matrix.md`
* Deferred Tools Execution Plan:
  `docs/deferred-tools-execution-plan.md`
* Deferred Tool Readiness Review:
  `docs/deferred-tool-readiness-review.md`

This relationship is documentation-only. It does not create a badge renderer,
badge config, workflow registry, runtime gate, production approval, or UI
implementation.

## Explicit Non-Actions

Phase 83 is readiness badge design only.

* No live UI badges implemented.
* No UI runtime files modified.
* No active UI config created.
* No active runtime config created.
* No production config or allowlist config created or changed.
* No production approval granted.
* No executable handler/module/action created.
* No tool module created.
* No runtime module or executable helper created.
* No tool or placeholder enabled.
* No runtime behavior changed.
* No source mirror files changed.
* No intake files changed.
* No legacy source-ultimate files changed.
* No artifact, download, installer, Profile Inspector, `.nip`, driver,
  profile write, profile import, profile export, Windows Registry, file,
  process, reboot, Default, or Restore approval added.
* No AppX, service, task, cleanup, TrustedInstaller, or Safe Mode approval
  added.
* No production scope, allowlist, artifact, workflow, or process target added.
* No DDU execution/download/artifact approval added.
* Standalone DDU not introduced.
* Loudness EQ and NVME Faster Driver remain deleted.
* Counts unchanged: 48 active tools, 30 implemented tools, 18
  deferred/placeholders, and 7 source-promoted intake candidates separate from
  official counts.

## Recommended Next Phase

Recommended next phase: **NVIDIA Path B Path Conflict Copy And Status Text
Design**.

That phase should remain design-only unless Yazan explicitly approves a narrow
runtime or UI foundation. It should define exact future copy for Path A/Path B
selection, conflict, warning, and blocked states without implementing UI,
runtime config, modules, action buttons, artifacts, production scopes, or
execution behavior.

Phase 84 records that copy/status text design in
`docs/tool-designs/nvidia-path-b-path-conflict-copy-status-text-design.md`. It
adds no live UI copy implementation, localization runtime file, active UI
config, runtime config, production approval, or Path B execution behavior.

Phase 85 records non-executing catalog preview data design in
`docs/tool-designs/nvidia-path-b-non-executing-catalog-preview-data-design.md`.
It defines future read-only preview metadata for badges, blockers, status text,
source checksums, and missing approvals without creating active UI/runtime
config or execution behavior.

Phase 86 records preview data integrity/drift rules design in
`docs/tool-designs/nvidia-path-b-preview-data-integrity-drift-rules-design.md`.
It defines future drift categories and fail-closed rules without implementing a
drift checker, creating active preview config, or enabling Path B.
