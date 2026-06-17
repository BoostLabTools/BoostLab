# NVIDIA Path B UI Workflow Design

## Purpose And Status

Phase 78 defines a future UI workflow design for NVIDIA Path A and NVIDIA App
Path B.

This is UI workflow design only. No UI implementation was added. No live WPF or
runtime behavior changed. No Path B tool cards or placeholders were enabled.
Path B remains `NotImplemented` / `DesignPending`. No production approval was
added.

Phase 78 status statements:

* No UI implementation was added.
* No live WPF or runtime behavior changed.
* No Path B tool cards or placeholders were enabled.
* Path B remains `NotImplemented` / `DesignPending`.
* No production approval was added.

NVIDIA App Path B exact required order:

`Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

Path relationship:

* Path A: `Driver Install Debloat & Settings`
* Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

Path A is the existing debloat/configuration workflow. Path B is the alternate
NVIDIA App compatible workflow for users who want to keep or use NVIDIA App
features such as recording or related NVIDIA App features.

Future UI must preserve guided separation between Path A and Path B and prevent
accidental mixing unless a later explicit design approves otherwise. The five
Path B scripts must not be shown as random unordered Graphics tools.

## User-Facing Workflow Model

Future Graphics UI should introduce a NVIDIA workflow choice area before any
NVIDIA-specific execution surface is exposed.

Future UI concepts:

* NVIDIA Workflow Choice screen/section.
* Path A card: `Driver Install Debloat & Settings`.
* Path B card: NVIDIA App compatible path.
* Path B ordered stepper.
* Step status states.
* Prerequisites.
* Blocked / not implemented state.
* Warning state.
* Ready state.
* Completed state.
* Failed / refused state.
* Restore available / restore denied state.
* Artifact provenance missing state.
* Profile capture missing state.
* Reboot required / pending state.
* Path A / Path B mutual guidance.

Path B is a workflow, not a loose collection of tools. Future UI should show
what is missing before a step can run and why a step is blocked.

## Path A Vs Path B Decision UX

Future UI copy should describe Path A as:

> NVIDIA driver debloat and configuration workflow. Intended for users who do
> not need NVIDIA App features and accept the approved debloat/configuration
> path.

Future UI copy should describe Path B as:

> NVIDIA App compatible workflow. Intended for users who want to keep or use
> NVIDIA App features such as recording, while applying a separate approved
> ordered NVIDIA setup path.

User flow rules:

* User must intentionally choose Path A or Path B.
* UI must prevent accidental mixing.
* Until mixing is approved, Path A and Path B should be mutually guided.
* If a later phase allows mixing, UI must show an explicit warning and require
  explicit confirmation.
* A chosen path should show its current readiness, blockers, and next safe step.
* Path B must not silently call Path A behavior.
* Path A must not silently call Path B behavior.

## Path B Ordered Stepper Design

Future Path B stepper:

1. Driver Install Latest
2. Nvidia Settings
3. Hdcp
4. P0 State
5. Msi Mode

### Step 1 - Driver Install Latest

* Display name: Driver Install Latest
* Source mirror path:
  `source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1`
* SHA-256:
  `41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F`
* Short user-facing purpose: Locate and install the source-defined latest
  NVIDIA driver path when future artifact provenance and installer execution
  policy allow it.
* Design status: `DesignPending` / `NotImplemented`.
* Required future approvals before enabling: NVIDIA driver artifact provenance,
  download policy, installer execution descriptor, driver state capture,
  rollback/recovery plan, reboot/session handling, NVIDIA-only targeting, and
  production allowlist approval.
* Required Action Plan information: source checksum, selected path, NVIDIA-only
  target, artifact provenance status, download destination, installer command,
  expected exit behavior, driver capture status, reboot risk, and refusal
  conditions.
* Required confirmation level: high-risk explicit confirmation.
* Expected Latest Result fields: WorkflowId, SelectedPath, StepId, StepNumber,
  SourceChecksum, ArtifactProvenanceStatus, DriverCaptureStatus,
  InstallerPolicyStatus, OperationResult, VerificationResult,
  RestoreEligibility, RefusalReason, NextRecommendedStep.
* Expected Activity Log fields: timestamp, level, workflow path, step number,
  step title, action, provenance decision, confirmation decision, result, and
  refusal reason when blocked.
* Failure behavior: failed or refused driver install should block later required
  Path B steps unless a future design approves manual continuation.
* Skip behavior recommendation: skip should remain unavailable unless a future
  design defines a validated existing-driver prerequisite.
* Restore/default visibility recommendation: Default unavailable unless the
  source-approved behavior exists; Restore denied unless captured driver state
  is available and selected through Restore Selection UI / Runtime.

### Step 2 - Nvidia Settings

* Display name: Nvidia Settings
* Source mirror path:
  `source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1`
* SHA-256:
  `903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5`
* Short user-facing purpose: Apply source-defined NVIDIA settings and Profile
  Inspector `.nip` behavior only after future provenance, profile capture, and
  production allowlists are approved.
* Design status: `DesignPending` / `NotImplemented`.
* Required future approvals before enabling: 7-Zip provenance if preserved,
  NVIDIA Profile Inspector provenance, generated `.nip` model, profile state
  capture model, registry/file capture, process handling, profile import
  verification, NVIDIA Control Panel launch handling, and production allowlist
  approval.
* Required Action Plan information: source checksum, selected path, artifact
  provenance status, profile capture status, `.nip` generation/import status,
  registry/file capture status, Profile Inspector execution descriptor,
  expected profile settings, confirmation status, and refusal conditions.
* Required confirmation level: high-risk explicit confirmation.
* Expected Latest Result fields: WorkflowId, SelectedPath, StepId, StepNumber,
  SourceChecksum, ArtifactProvenanceStatus, ProfileCaptureStatus,
  NipValidationStatus, ProfileImportStatus, RegistryCaptureStatus,
  OperationResult, VerificationResult, RestoreEligibility, RefusalReason,
  NextRecommendedStep.
* Expected Activity Log fields: timestamp, level, workflow path, step number,
  step title, action, provenance decision, profile capture decision, `.nip`
  decision, confirmation decision, result, and refusal reason when blocked.
* Failure behavior: failed or refused profile/settings import should block
  later Path B steps unless a future design allows continuation.
* Skip behavior recommendation: skip should remain unavailable unless future UI
  can prove the required settings are already present or not applicable.
* Restore/default visibility recommendation: Default is source-defined behavior,
  not Restore. Restore denied unless a validated profile and registry/file
  capture exists.

### Step 3 - Hdcp

* Display name: Hdcp
* Source mirror path:
  `source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1`
* SHA-256:
  `5C350D28F795D678051E6088F34968DF8D90B3D9024F558C5FAFB2899D1A906A`
* Short user-facing purpose: Apply source-defined HDCP/content-protection
  registry behavior only after exact NVIDIA registry/driver targeting and
  rollback rules are approved.
* Design status: `DesignPending` / `NotImplemented`.
* Required future approvals before enabling: exact registry allowlist,
  NVIDIA-only display target discovery, registry capture, driver state
  review, security/content-protection warning, verification model, and
  production allowlist approval.
* Required Action Plan information: source checksum, selected path, registry
  target identity, NVIDIA target validation, capture status, content-protection
  warning, confirmation status, and refusal conditions.
* Required confirmation level: high-risk explicit confirmation.
* Expected Latest Result fields: WorkflowId, SelectedPath, StepId, StepNumber,
  SourceChecksum, RegistryTargetStatus, CaptureStatus, OperationResult,
  VerificationResult, RestoreEligibility, RefusalReason, NextRecommendedStep.
* Expected Activity Log fields: timestamp, level, workflow path, step number,
  step title, registry target decision, capture decision, result, and refusal
  reason when blocked.
* Failure behavior: failed or refused HDCP step should stop or clearly gate
  later steps unless future UI allows manual continuation.
* Skip behavior recommendation: skip may be considered only with explicit
  future design and visible reason.
* Restore/default visibility recommendation: Restore denied unless exact
  captured registry state is available; Default unavailable unless the
  source-approved default behavior is designed.

### Step 4 - P0 State

* Display name: P0 State
* Source mirror path:
  `source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1`
* SHA-256:
  `382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC`
* Short user-facing purpose: Apply source-defined NVIDIA P0/performance-state
  registry behavior only after exact targeting, capture, and thermal/stability
  warnings are approved.
* Design status: `DesignPending` / `NotImplemented`.
* Required future approvals before enabling: exact registry allowlist,
  NVIDIA-only display target discovery, registry capture, driver/power review,
  thermal/stability warning, verification model, and production allowlist
  approval.
* Required Action Plan information: source checksum, selected path, registry
  target identity, NVIDIA target validation, capture status, power/thermal risk
  warning, confirmation status, and refusal conditions.
* Required confirmation level: high-risk explicit confirmation.
* Expected Latest Result fields: WorkflowId, SelectedPath, StepId, StepNumber,
  SourceChecksum, RegistryTargetStatus, CaptureStatus, PowerThermalWarning,
  OperationResult, VerificationResult, RestoreEligibility, RefusalReason,
  NextRecommendedStep.
* Expected Activity Log fields: timestamp, level, workflow path, step number,
  step title, registry target decision, capture decision, warning, result, and
  refusal reason when blocked.
* Failure behavior: failed or refused P0 State should stop or clearly gate later
  steps unless future UI allows manual continuation.
* Skip behavior recommendation: skip may be considered only with explicit
  future design and visible reason.
* Restore/default visibility recommendation: Restore denied unless exact
  captured registry state is available; Default unavailable unless the
  source-approved default behavior is designed.

### Step 5 - Msi Mode

* Display name: Msi Mode
* Source mirror path:
  `source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1`
* SHA-256:
  `94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7`
* Short user-facing purpose: Apply source-defined MSI interrupt registry
  behavior only after NVIDIA-only device targeting, capture, and reboot/device
  restart disclosure are approved.
* Design status: `DesignPending` / `NotImplemented`.
* Required future approvals before enabling: exact device registry allowlist,
  NVIDIA-only device identity validation, registry capture, driver/device
  review, reboot/device-restart policy, verification model, and production
  allowlist approval.
* Required Action Plan information: source checksum, selected path, device
  target identity, NVIDIA target validation, capture status, reboot/device
  restart disclosure, confirmation status, and refusal conditions.
* Required confirmation level: high-risk explicit confirmation.
* Expected Latest Result fields: WorkflowId, SelectedPath, StepId, StepNumber,
  SourceChecksum, DeviceTargetStatus, CaptureStatus, RebootOrRestartStatus,
  OperationResult, VerificationResult, RestoreEligibility, RefusalReason,
  NextRecommendedStep.
* Expected Activity Log fields: timestamp, level, workflow path, step number,
  step title, device target decision, capture decision, reboot/device-restart
  disclosure, result, and refusal reason when blocked.
* Failure behavior: failed or refused Msi Mode should end the Path B attempt
  with a clear refusal or failure result.
* Skip behavior recommendation: skip may be considered only with explicit
  future design and visible reason.
* Restore/default visibility recommendation: Restore denied unless exact
  captured device registry state is available; Default unavailable unless the
  source-approved default behavior is designed.

## Gating And Sequencing Rules

Future gating rules:

* Step order must be preserved.
* Later steps should be gated until earlier required steps are completed,
  skipped by an approved design, or marked not applicable by a future validator.
* If Driver Install Latest fails or is refused, later Path B steps should remain
  blocked unless a future design allows manual continuation.
* Nvidia Settings must not be enabled until artifact provenance, profile capture
  model, profile import model, and production allowlists are approved.
* Hdcp, P0 State, and Msi Mode must not be enabled until exact registry,
  device, driver targeting, and rollback rules are approved.
* Msi Mode must require NVIDIA-only device targeting and reboot/device-restart
  disclosure.
* Path B must not silently call Path A behavior.
* Path B must not be exposed as five random unordered Graphics tools.
* A skipped step must record who/what approved the skip, why it was safe, and
  what later steps may rely on.

## UI Safety Messaging

Future UI warning copy must cover:

* Downloads/installers: "This step may download or run NVIDIA-related
  installers only after artifact provenance and installer execution policy are
  approved."
* NVIDIA driver mutation: "Driver installation or driver state changes can
  affect display stability and may require recovery planning."
* NVIDIA Profile Inspector: "Profile Inspector is an external tool and cannot
  run until its artifact provenance, execution descriptor, and verification
  model are approved."
* `.nip` profile import: "Profile imports can overwrite NVIDIA driver profile
  settings. A pre-change profile capture is required before import."
* HDCP/content protection implications: "Changing HDCP/content-protection
  settings may affect protected media playback or display behavior."
* P0 power/thermal/stability implications: "Forcing performance-state behavior
  may increase power, heat, or stability risk."
* MSI interrupt/device registry implications: "Interrupt-mode registry changes
  affect device behavior and may require reboot or device restart."
* Reboot/device restart implications: "Some driver/device changes may not take
  effect until a reboot or device restart. This must be disclosed before Apply."
* Default vs Restore distinction: "Default follows approved default behavior;
  Restore returns to captured prior state."
* Missing restore capture: "Restore is unavailable because no validated capture
  exists."
* Unsupported AMD/Intel GPU-specific behavior: "AMD and Intel GPU-specific
  branches are outside BoostLab NVIDIA-only GPU scope."

## Action Plan / Latest Result / Activity Log Design

Future Action Plan, Latest Result, and Activity Log data should include:

* WorkflowId
* SelectedPath
* StepId
* StepNumber
* SourceChecksum
* ApprovalsPresent
* ApprovalsMissing
* ArtifactProvenanceStatus
* DriverProfileCaptureStatus
* RegistryFileCaptureStatus
* ProcessRebootGatingStatus
* UserConfirmationStatus
* OperationResult
* VerificationResult
* RestoreEligibility
* RefusalReason
* SkipReason
* NextRecommendedStep

Activity Log entries should show the selected path and step number so Path B
events cannot be mistaken for Path A events. Latest Result should show all
missing approval categories when a step is blocked.

## Restore And Default UI Model

Future UI must show that Default is not Restore.

Default means the approved source-defined default behavior for a tool or step.
Restore means returning to a captured previous state selected through Restore
Selection UI / Runtime.

Rules:

* Restore requires captured prior state.
* Restore must integrate with Restore Selection UI / Runtime.
* If no capture exists, Restore must be shown as unavailable/denied, not hidden
  silently.
* For profile operations, Restore depends on NVIDIA Profile State Capture Model.
* For registry/device settings, Restore depends on File/Registry State Capture
  and Driver State foundations.
* No Restore behavior is approved in this phase.
* Default must not be displayed as a substitute for captured-state Restore.

## Future Visual And Layout Recommendations

Future visual/layout ideas:

* Graphics stage could have a NVIDIA workflow selector area.
* Path A and Path B could be shown as two workflow cards.
* Path B steps could be shown as an ordered vertical or horizontal stepper.
* Each step could have status badges such as `NotImplemented`,
  `NeedsProvenance`, `NeedsProfileCapture`, `NeedsRegistryRollback`,
  `NeedsRebootPolicy`, `Ready`, and `Blocked`.
* Advanced users may later see source/risk details.
* Beginner users should see clear workflow guidance.
* The UI should keep Path B blocked details readable rather than hiding them in
  generic disabled buttons.
* Path B status should make it obvious that a blocked step is a governance
  decision, not a broken app.

## Relationship To Existing Foundations

This design connects to:

* NVIDIA Path B Catalog Design
* NVIDIA Path B Scope Design
* NVIDIA Path B Production Allowlist Planning
* NVIDIA Path B Artifact Provenance Review
* NVIDIA Profile State Capture Model
* Production Allowlist Governance
* Download Provenance and Installer Execution Policy
* Driver State Capture and Rollback
* File/Registry State Capture and Rollback
* Restore Selection UI / Runtime
* Process Handling Policy
* Reboot/Recovery Workflow

The UI design does not approve any foundation scope. It only defines how future
approved state should be presented, blocked, confirmed, logged, and sequenced.

## Related Source-Promoted Scripts Outside This Workflow

`Driver Clean` remains outside the five-step NVIDIA Path B UI workflow. It is a
Yazan-approved intake exception despite DDU usage, but this does not approve
standalone DDU, DDU execution, DDU downloads, artifact approvals, production
scopes, modules, placeholders, or tool behavior.

`BitLocker` is outside NVIDIA Path B and remains pending future
security-sensitive design.

## Explicit Non-Actions

Phase 78 is UI workflow design only.

* No UI implementation was added.
* No WPF/runtime files were changed for execution.
* No source mirror files changed.
* No intake files changed.
* No legacy source-ultimate files changed.
* No executable module created.
* No tool or placeholder enabled.
* No runtime behavior changed.
* No production scope, allowlist, artifact, download, installer, driver,
  profile write, profile import, profile export, AppX, service, task, process,
  cleanup, reboot, TrustedInstaller, Safe Mode, Default, or Restore approval was
  added.
* No DDU execution, DDU download, or DDU artifact approval was added.
* Standalone DDU was not introduced.
* Loudness EQ and NVME Faster Driver remain deleted.
* Counts remain unchanged: 48 active tools, 30 implemented tools, 18
  deferred/placeholders, and 7 source-promoted intake candidates separate from
  official counts.

## Recommended Next Phase

Recommended next phase: **NVIDIA Path B Draft Allowlist Proposal**.

That phase should remain non-executing unless Yazan explicitly approves a
narrower scope. A cautious version should draft non-approved candidate entries
for exact Path B registry, device, profile, artifact, process, and workflow
scopes while keeping every candidate `Draft` / `NotApproved`.

Phase 79 records those non-approved draft proposals in
`docs/tool-designs/nvidia-path-b-draft-allowlist-proposal.md`. It creates no
production allowlist config and approves no scope.
