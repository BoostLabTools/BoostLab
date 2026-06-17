# NVIDIA Path B Runtime Gating Design

## Purpose And Status

Phase 81 defines a future runtime gating design for NVIDIA App Path B.

This is runtime gating design only. No runtime gate implementation is added.
No tool execution is enabled. No production approval is granted. No production config or allowlist config is created or changed. No placeholder/tool card is enabled. No UI implementation is added.

NVIDIA App Path B exact required order:

`Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

Path relationship:

* Path A: `Driver Install Debloat & Settings`
* Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

Path B is for users who want to keep or use NVIDIA App features such as
recording or related NVIDIA App features. Future runtime gates must preserve
guided separation between Path A and Path B and prevent accidental mixing unless
a later explicit design approves that behavior.

Source references for the five Path B steps:

| Step | Script name | Source mirror path | SHA-256 |
|---:|---|---|---|
| 1 | Driver Install Latest | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1` | `41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F` |
| 2 | Nvidia Settings | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1` | `903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5` |
| 3 | Hdcp | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1` | `5C350D28F795D678051E6088F34968DF8D90B3D9024F558C5FAFB2899D1A906A` |
| 4 | P0 State | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1` | `382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC` |
| 5 | Msi Mode | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1` | `94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7` |

## Runtime Gating Concepts

Future runtime design should treat each gate as a structured decision, not as a
hidden conditional inside a tool module.

Required concepts:

* Workflow gate: validates that the selected NVIDIA workflow is known and
  permitted.
* Path gate: validates the selected Path A or Path B and prevents accidental
  cross-path execution.
* Step gate: validates the requested Path B step number and step identity.
* Prerequisite gate: validates that earlier required steps are completed,
  skipped by approved design, or NotApplicable by approved validator.
* Source checksum gate: validates source mirror path and expected SHA-256.
* Approval gate: validates future production approval records.
* Artifact provenance gate: validates future artifact records before any
  download, executable, installer, archive, or external helper is used.
* Installer descriptor gate: validates future command descriptors, arguments,
  timeout, exit-code, signer, and execution policy.
* Driver rollback gate: validates driver inventory/capture references before a
  driver mutation or installer handoff.
* Profile capture gate: validates NVIDIA profile capture before profile import,
  profile write, `.nip` import, or profile Restore.
* Registry rollback gate: validates exact registry capture before registry
  mutation.
* Process policy gate: validates future process launch, close, wait, or handoff
  scope.
* Reboot/recovery gate: validates future reboot, device restart, or session
  transition workflow records.
* NVIDIA-only targeting gate: validates that GPU, driver, device, display, and
  profile operations are constrained to NVIDIA targets.
* Path A/Path B mutual exclusion gate: blocks or warns on mixed path state
  according to a future approved policy.
* Restore availability gate: validates captured-state Restore eligibility.
* Default availability gate: validates source-defined Default availability
  without confusing it with Restore.
* Verification gate: validates expected post-action checks.
* User confirmation gate: validates explicit user confirmation after all other
  blocking gates are satisfied.
* Failure gate: converts failed gate checks into structured refusal results.
* Skip gate: validates that a step skip was approved by design and recorded.
* Not applicable gate: validates source-supported NotApplicable results.
* Not implemented gate: keeps all Path B steps non-executing until a future
  implementation phase exists.

## Gate States

Future gates may return these states:

* `NotImplemented`
* `Blocked`
* `MissingApproval`
* `MissingProvenance`
* `MissingRollbackCapture`
* `MissingProfileCapture`
* `MissingProcessPolicy`
* `MissingRebootPolicy`
* `MissingNvidiaTargeting`
* `SourceChecksumMismatch`
* `PathConflict`
* `ReadyForReview`
* `ReadyForExecutionInFuturePhase`
* `SkippedByApprovedDesign`
* `NotApplicable`
* `Failed`
* `Refused`
* `Completed`
* `RestoreAvailable`
* `RestoreDenied`

`ReadyForExecutionInFuturePhase` is descriptive only. It must not enable
execution, visible tool actions, runtime workflow config, production config, or
approval in this phase.

## Workflow-Level Gating Rules

Future workflow-level rules:

* Exact order must be preserved:
  `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`.
* Step 2 is ready only after Step 1 completed, skipped by approved design, or
  NotApplicable by approved validator.
* Step 3 is ready only after Step 2 gates are satisfied.
* Step 4 is ready only after Step 3 gates are satisfied.
* Step 5 is ready only after Step 4 gates are satisfied.
* If Path A is selected or applied, Path B is blocked unless a future mixing
  design explicitly approves the combination.
* If Path B is selected or applied, Path A is blocked or warned depending on a
  future approved policy.
* AMD/Intel GPU targets are blocked for NVIDIA Path B.
* NVIDIA-only targeting is required before any GPU, device, driver, display,
  profile, or device-registry operation.
* Missing source checksum blocks the workflow.
* Missing production approval blocks execution.
* Missing artifact provenance blocks download, installer, external executable,
  archive, Profile Inspector, and `.nip` import execution.
* Missing rollback capture blocks registry, file, driver, profile, and restore
  operations where the related foundation requires capture.
* Missing process policy blocks installer handoff, Profile Inspector launch,
  NVIDIA Control Panel launch, and any future process close/start/wait behavior.
* Missing reboot policy blocks any reboot, device restart, or session-transition
  behavior.
* Default and Restore must remain distinct. Default follows source-defined
  default behavior. Restore returns to captured prior state.

## Per-Step Gating Requirements

### Step 1 - Driver Install Latest

Required future gates:

* Source checksum gate for `Driver Install Latest`.
* Artifact provenance gate for the NVIDIA driver lookup and resulting driver
  artifact.
* Driver installer descriptor gate for the installer handoff.
* Driver rollback gate for current driver/device/package state capture.
* Process handoff gate for installer launch/observation.
* Reboot/recovery gate for possible reboot or session interruption.
* NVIDIA driver verification gate.
* User confirmation gate.

This step must remain blocked until all applicable gates are future-approved.

### Step 2 - Nvidia Settings

Required future gates:

* Source checksum gate for `Nvidia Settings`.
* NVIDIA Inspector provenance gate.
* Profile Inspector execution descriptor gate.
* Generated/imported `.nip` gate.
* Profile pre-capture gate.
* Profile restore eligibility gate.
* Registry/file rollback gate if source registry or file behavior is preserved.
* Process policy gate for 7-Zip, Profile Inspector, and NVIDIA Control Panel
  launch behavior.
* Verification gate.
* User confirmation gate.

This step must not import `.nip` files or write profile state without validated
profile capture.

### Step 3 - Hdcp

Required future gates:

* Source checksum gate for `Hdcp`.
* Exact `RMHdcpKeyglobZero` registry scope gate.
* NVIDIA-only targeting gate.
* Registry rollback capture gate.
* Content-protection/security review gate.
* Verification gate.
* Restore/Default decision gate.
* User confirmation gate.

This step must not write display-class registry state without exact NVIDIA
targeting and capture.

### Step 4 - P0 State

Required future gates:

* Source checksum gate for `P0 State`.
* Exact `DisableDynamicPstate` registry scope gate.
* NVIDIA-only targeting gate.
* Registry rollback capture gate.
* Power/thermal/stability warning gate.
* Verification gate.
* Restore/Default decision gate.
* User confirmation gate.

This step must warn about power, thermal, stability, fan, and battery impact
before any future execution.

### Step 5 - Msi Mode

Required future gates:

* Source checksum gate for `Msi Mode`.
* Exact `MSISupported` registry scope gate.
* Display device instance validation gate.
* NVIDIA-only targeting gate.
* Registry rollback capture gate.
* Reboot/device restart disclosure gate.
* Verification gate.
* Restore/Default decision gate.
* User confirmation gate.

This step must not target AMD, Intel, unknown, or ambiguous display devices.

## Gating Decision Table

Current status values in this table are non-executable only: `DesignOnly`,
`NotImplemented`, `Blocked`, `NeedsFutureRuntime`, and `NotApproved`.

| Gate id | Step number | Script name | Gate category | Required evidence | Blocking condition | Non-blocking condition | Future runtime result field | User-facing message requirement | Related foundation/document | Current status |
|---|---:|---|---|---|---|---|---|---|---|---|
| NPB-RUNTIME-GATE-001 | 0 | Path B Workflow | Workflow gate | Known workflow id and exact step list | Unknown workflow or missing step order | Workflow id matches Path B design | `workflowId` | Show selected NVIDIA workflow and ordered steps | NVIDIA Path B Scope Design | DesignOnly |
| NPB-RUNTIME-GATE-002 | 0 | Path B Workflow | Path gate | Selected Path B with Path A state checked | Path A state conflicts with Path B | No conflict or future-approved mix policy | `pathConflictStatus` | Explain Path A/Path B conflict | NVIDIA Path B UI Workflow Design | NeedsFutureRuntime |
| NPB-RUNTIME-GATE-003 | 0 | Path B Workflow | Source checksum gate | All five source paths and SHA-256 values | Any source checksum mismatch | Every source checksum matches | `sourceChecksum` | Refuse on source checksum mismatch | NVIDIA Path B Production Approval Gate Design | NeedsFutureRuntime |
| NPB-RUNTIME-GATE-004 | 0 | Path B Workflow | Approval gate | Future production approval records | Missing production approval | Future production approval exists | `missingApprovals` | List missing approval categories | Production Allowlist Governance | NotApproved |
| NPB-RUNTIME-GATE-005 | 0 | Path B Workflow | Not implemented gate | Implementation status record | No future implementation phase exists | Future implementation exists and is approved | `gateState` | Show NotImplemented without hiding reason | NVIDIA Path B Runtime Gating Design | NotImplemented |
| NPB-RUNTIME-GATE-006 | 1 | Driver Install Latest | Step gate | Step id, number, and source identity | Requested step is not step 1 | Step 1 identity matches design | `stepId` | Show step number and title | NVIDIA Path B Scope Design | DesignOnly |
| NPB-RUNTIME-GATE-007 | 1 | Driver Install Latest | Artifact provenance gate | Driver artifact source, URL, filename, hash, signer, size | Missing or untrusted driver provenance | Future artifact is approved and verified | `missingProvenance` | Explain missing NVIDIA driver provenance | Download Provenance and Installer Execution Policy | NotApproved |
| NPB-RUNTIME-GATE-008 | 1 | Driver Install Latest | Installer descriptor gate | Exact executable, arguments, timeout, exit policy | Missing installer descriptor | Future descriptor is approved | `missingProvenance` | Explain installer handoff is not approved | Installer Execution Policy | NotApproved |
| NPB-RUNTIME-GATE-009 | 1 | Driver Install Latest | Driver rollback gate | Current NVIDIA driver/device/package capture | Missing driver capture | Future driver capture exists and verifies | `missingRollbackCaptures` | Explain driver rollback capture requirement | Driver State Capture and Rollback | NotApproved |
| NPB-RUNTIME-GATE-010 | 1 | Driver Install Latest | Process policy gate | Installer process handoff policy | Missing process policy | Future process policy exists | `missingProcessPolicy` | Explain installer process policy requirement | Process Handling Policy | NotApproved |
| NPB-RUNTIME-GATE-011 | 1 | Driver Install Latest | Reboot/recovery gate | Reboot/session disclosure and workflow policy | Missing reboot/session policy | Future reboot/session policy exists or is NotApplicable | `missingRebootPolicy` | Explain possible reboot/session impact | Reboot/Recovery Workflow | NotApproved |
| NPB-RUNTIME-GATE-012 | 1 | Driver Install Latest | Verification gate | Driver artifact and installed driver checks | Verification plan missing | Future verification plan exists | `verificationRequired` | Explain driver verification requirement | Verification Contract | NeedsFutureRuntime |
| NPB-RUNTIME-GATE-013 | 2 | Nvidia Settings | Prerequisite gate | Step 1 completed, skipped, or NotApplicable | Step 1 unresolved or failed | Step 1 gate allows continuation | `nextAllowedStep` | Explain why Nvidia Settings is blocked | NVIDIA Path B UI Workflow Design | NeedsFutureRuntime |
| NPB-RUNTIME-GATE-014 | 2 | Nvidia Settings | Artifact provenance gate | 7-Zip and NVIDIA Profile Inspector provenance | Missing or rejected artifact provenance | Future artifact provenance exists | `missingProvenance` | Explain missing 7-Zip/Inspector provenance | NVIDIA Path B Artifact Provenance Review | NotApproved |
| NPB-RUNTIME-GATE-015 | 2 | Nvidia Settings | Profile capture gate | Pre-change NVIDIA profile capture | Missing profile capture | Future profile capture exists and verifies | `missingProfileCapture` | Explain profile capture blocks `.nip` import | NVIDIA Profile State Capture Model | NotApproved |
| NPB-RUNTIME-GATE-016 | 2 | Nvidia Settings | Installer descriptor gate | 7-Zip and Inspector command descriptors | Missing execution descriptor | Future descriptor exists and verifies | `missingProvenance` | Explain external executable execution is blocked | Installer Execution Policy | NotApproved |
| NPB-RUNTIME-GATE-017 | 2 | Nvidia Settings | Registry rollback gate | Exact NVIDIA and 7-Zip registry captures | Missing registry capture | Future registry capture exists | `missingRollbackCaptures` | Explain registry capture requirement | File/Registry State Capture and Rollback | NotApproved |
| NPB-RUNTIME-GATE-018 | 2 | Nvidia Settings | Process policy gate | Control Panel and Inspector process policy | Missing process policy | Future process policy exists | `missingProcessPolicy` | Explain process launch policy requirement | Process Handling Policy | NotApproved |
| NPB-RUNTIME-GATE-019 | 2 | Nvidia Settings | Verification gate | Registry, file, `.nip`, and profile checks | Verification plan missing | Future verification plan exists | `verificationRequired` | Explain verification is required | NVIDIA Profile State Capture Model | NeedsFutureRuntime |
| NPB-RUNTIME-GATE-020 | 3 | Hdcp | Prerequisite gate | Step 2 completed, skipped, or NotApplicable | Step 2 unresolved or failed | Step 2 gate allows continuation | `nextAllowedStep` | Explain why Hdcp is blocked | NVIDIA Path B UI Workflow Design | NeedsFutureRuntime |
| NPB-RUNTIME-GATE-021 | 3 | Hdcp | NVIDIA-only targeting gate | Verified NVIDIA display-class targets | AMD/Intel/unknown target or ambiguous target | Verified NVIDIA target only | `nvidiaTargetingStatus` | Explain NVIDIA-only targeting requirement | Driver State Capture and Rollback | NotApproved |
| NPB-RUNTIME-GATE-022 | 3 | Hdcp | Registry rollback gate | Capture for `RMHdcpKeyglobZero` | Missing capture for target value | Capture exists and verifies | `missingRollbackCaptures` | Explain HDCP registry capture requirement | File/Registry State Capture and Rollback | NotApproved |
| NPB-RUNTIME-GATE-023 | 3 | Hdcp | Approval gate | Content-protection/security review | Missing security review | Future review exists | `missingApprovals` | Warn about content-protection impact | Production Allowlist Governance | NotApproved |
| NPB-RUNTIME-GATE-024 | 3 | Hdcp | Default/Restore gate | Source Default and Restore decision | Default/Restore semantics ambiguous | Future decision exists | `defaultAvailability` | Explain Default is not Restore | Restore Selection UI / Runtime | NeedsFutureRuntime |
| NPB-RUNTIME-GATE-025 | 4 | P0 State | Prerequisite gate | Step 3 completed, skipped, or NotApplicable | Step 3 unresolved or failed | Step 3 gate allows continuation | `nextAllowedStep` | Explain why P0 State is blocked | NVIDIA Path B UI Workflow Design | NeedsFutureRuntime |
| NPB-RUNTIME-GATE-026 | 4 | P0 State | NVIDIA-only targeting gate | Verified NVIDIA display-class targets | AMD/Intel/unknown target or ambiguous target | Verified NVIDIA target only | `nvidiaTargetingStatus` | Explain NVIDIA-only targeting requirement | Driver State Capture and Rollback | NotApproved |
| NPB-RUNTIME-GATE-027 | 4 | P0 State | Registry rollback gate | Capture for `DisableDynamicPstate` | Missing capture for target value | Capture exists and verifies | `missingRollbackCaptures` | Explain P0 registry capture requirement | File/Registry State Capture and Rollback | NotApproved |
| NPB-RUNTIME-GATE-028 | 4 | P0 State | User confirmation gate | Power/thermal/stability confirmation text | Missing warning or confirmation | Future confirmation provided | `confirmationRequired` | Warn about power, heat, and stability | Action Plan Framework | NeedsFutureRuntime |
| NPB-RUNTIME-GATE-029 | 5 | Msi Mode | Prerequisite gate | Step 4 completed, skipped, or NotApplicable | Step 4 unresolved or failed | Step 4 gate allows continuation | `nextAllowedStep` | Explain why Msi Mode is blocked | NVIDIA Path B UI Workflow Design | NeedsFutureRuntime |
| NPB-RUNTIME-GATE-030 | 5 | Msi Mode | NVIDIA-only targeting gate | Verified NVIDIA device instance identity | AMD/Intel/unknown target or ambiguous target | Verified NVIDIA device only | `nvidiaTargetingStatus` | Explain NVIDIA-only device targeting | Driver State Capture and Rollback | NotApproved |
| NPB-RUNTIME-GATE-031 | 5 | Msi Mode | Registry rollback gate | Capture for `MSISupported` | Missing capture for target value | Capture exists and verifies | `missingRollbackCaptures` | Explain MSI registry capture requirement | File/Registry State Capture and Rollback | NotApproved |
| NPB-RUNTIME-GATE-032 | 5 | Msi Mode | Reboot/recovery gate | Device restart/reboot disclosure | Missing reboot/device restart policy | Future policy exists or is NotApplicable | `missingRebootPolicy` | Explain restart implications | Reboot/Recovery Workflow | NotApproved |
| NPB-RUNTIME-GATE-033 | 5 | Msi Mode | Verification gate | Readback of `MSISupported` on NVIDIA targets | Verification plan missing or failed | Future verification passes | `verificationRequired` | Explain MSI verification requirement | Verification Contract | NeedsFutureRuntime |
| NPB-RUNTIME-GATE-034 | 0 | Path B Workflow | Restore availability gate | Validated capture selection | No valid capture or wrong step/path | Valid capture selected | `restoreAvailability` | Show RestoreAvailable or RestoreDenied | Restore Selection UI / Runtime | NeedsFutureRuntime |
| NPB-RUNTIME-GATE-035 | 0 | Path B Workflow | Failure gate | Structured result mapping | Gate failure lacks structured result | Gate failure returns structured refusal | `activityLogEvent` | Show readable refusal details | Runtime Foundation | NeedsFutureRuntime |

## Future Runtime Result Schema

Future gating results should use a structured object with these fields:

* `workflowId`
* `selectedPath`
* `stepId`
* `stepNumber`
* `stepName`
* `sourcePath`
* `sourceChecksum`
* `gateState`
* `blockingReasons`
* `missingApprovals`
* `missingProvenance`
* `missingRollbackCaptures`
* `missingProfileCapture`
* `missingProcessPolicy`
* `missingRebootPolicy`
* `nvidiaTargetingStatus`
* `pathConflictStatus`
* `restoreAvailability`
* `defaultAvailability`
* `confirmationRequired`
* `actionPlanRequired`
* `verificationRequired`
* `canExecute`
* `canRestore`
* `canDefault`
* `nextAllowedStep`
* `userMessage`
* `activityLogEvent`

Current Phase 81 rule: `canExecute` must remain false for all Path B steps.
`canRestore` and `canDefault` must remain false unless a future approved phase
documents exact eligibility. A future result may show why a step is
`ReadyForReview`, but it must not turn that state into execution permission.

## Future UI Integration Requirements

Future UI integration should follow these rules:

* UI should read gate results before enabling any action button.
* `NotImplemented` and `Blocked` states should remain visible and readable.
* Missing approvals should be shown as explicit blocker categories.
* Path order should be visible.
* Path A/B conflict should be visible.
* Restore availability should come only from validated capture state.
* Default is not Restore and must not be displayed as a captured-state recovery
  action.
* Action Plan should be generated only after all approval gates are satisfied
  in a future phase.
* A blocked Path B step should show the next missing prerequisite instead of a
  generic disabled button.
* Activity Log should record gate refusal, skip, NotApplicable, and failure
  events with selected path and step number.
* Latest Result should display the full structured gate result and all missing
  approvals/provenance/capture/process/reboot categories.

No UI implementation is added by this document.

## Rejection And Refusal Behavior

Future runtime must refuse or block as follows:

* Checksum mismatch refuses execution.
* Missing production allowlist refuses execution.
* Missing provenance refuses download, installer, artifact, external executable,
  archive, Profile Inspector, and `.nip` execution.
* Missing profile capture refuses `.nip` import and profile write.
* Missing registry rollback capture refuses registry mutation.
* Missing NVIDIA targeting refuses device, display, driver, profile, and
  registry mutation.
* Missing reboot policy refuses reboot, device restart, and session transition.
* Path conflict refuses mixed Path A/B unless approved by a future design.
* Ambiguous target refuses execution.
* Missing process policy refuses installer handoff, Profile Inspector launch,
  NVIDIA Control Panel launch, and process handling.
* Missing verification plan refuses execution for any future step that mutates
  driver, profile, registry, file, installer, or process state.
* Unsupported AMD/Intel GPU-specific branches return blocked or NotApplicable
  according to future UI design.

These refusals are not runtime crashes. They must produce structured results,
Latest Result details, and Activity Log entries.

## Relationship To Existing Documents

This runtime gating design depends on and links to:

* `docs/nvidia-path-b-catalog-design.md`
* `docs/tool-designs/nvidia-path-b-scope-design.md`
* `docs/tool-designs/nvidia-path-b-production-allowlist-planning.md`
* `docs/tool-designs/nvidia-path-b-artifact-provenance-review.md`
* `docs/nvidia-profile-state-capture-model.md`
* `docs/nvidia-path-b-ui-workflow-design.md`
* `docs/tool-designs/nvidia-path-b-draft-allowlist-proposal.md`
* `docs/tool-designs/nvidia-path-b-production-approval-gate-design.md`
* `docs/production-allowlist-governance.md`
* `docs/download-provenance-installer-policy.md`
* `docs/driver-state-capture-rollback.md`
* `docs/file-registry-state-capture-rollback.md`
* `docs/process-handling-policy.md`
* `docs/reboot-recovery-workflow.md`
* `docs/restore-selection-ui-runtime.md`
* `docs/final-deferred-tools-readiness-matrix.md`
* `docs/deferred-tools-execution-plan.md`
* `docs/deferred-tool-readiness-review.md`

The relationship is design-only. This document does not create a new runtime
configuration file or approve any production gate.

## Explicit Non-Actions

Phase 81 is runtime gating design only.

* No runtime gating implementation was added.
* No runtime config was created to enable Path B.
* No production config or allowlist config was created or changed.
* No production approval was granted.
* No source mirror files changed.
* No intake files changed.
* No legacy source-ultimate files changed.
* No executable module was created.
* No helper module was created.
* No tool or placeholder was enabled.
* No tool card was enabled.
* No UI behavior changed.
* No runtime behavior changed.
* No artifact, download, installer, Profile Inspector, `.nip`, driver,
  profile write, profile import, profile export, registry, file, AppX, service,
  task, process, cleanup, reboot, TrustedInstaller, Safe Mode, Default, or
  Restore approval was added.
* No DDU execution, DDU download, or DDU artifact approval was added.
* Standalone DDU was not introduced.
* Loudness EQ and NVME Faster Driver remain deleted.
* Counts remain unchanged: 48 active tools, 30 implemented tools, 18
  deferred/placeholders, and 7 source-promoted intake candidates separate from
  official counts.

## Recommended Next Phase

Recommended next phase: **NVIDIA Path B Non-Executing Workflow Registry Schema
Design**.

That phase should remain design-only unless Yazan explicitly approves a narrow
runtime foundation. It should define how a future non-executing workflow
registry would represent Path B steps, gate states, missing approvals, and
visible blocked status without creating production config, enabling tool
buttons, approving artifacts, or changing runtime behavior.

Phase 82 records that schema design in
`docs/tool-designs/nvidia-path-b-non-executing-workflow-registry-schema-design.md`.
It creates no active workflow registry, runtime config, production config, UI
implementation, tool card, placeholder enablement, or Path B execution
behavior.

Phase 83 records readiness badge design in
`docs/tool-designs/nvidia-path-b-readiness-badge-design.md`. It defines future
badge taxonomy and badge-to-gate mapping without implementing live UI badges,
runtime badge evaluation, production config, or Path B execution behavior.

Phase 84 records path conflict copy/status text design in
`docs/tool-designs/nvidia-path-b-path-conflict-copy-status-text-design.md`. It
defines future user-facing wording for Path A/Path B conflicts, disabled
actions, gate blockers, and status messages without adding live UI text,
runtime behavior, localization files, or Path B execution behavior.

Phase 85 records non-executing catalog preview data design in
`docs/tool-designs/nvidia-path-b-non-executing-catalog-preview-data-design.md`.
It defines future preview fields and sample metadata without creating a live
catalog, runtime registry, active UI config, production config, or executable
Path B workflow.
