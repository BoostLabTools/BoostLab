# Driver Clean Controlled Implementation Plan

## Purpose And Status

Phase 91 is a Driver Clean controlled implementation plan only.

No Driver Clean implementation is added in this phase. No execution is
approved. No execution is approved. No DDU download or DDU artifact is
approved. No 7-Zip download or 7-Zip artifact is approved. No standalone DDU is
approved. No runtime/tool behavior changes.

Explicit non-approval statements:

* No DDU download or DDU artifact is approved.
* No 7-Zip download or 7-Zip artifact is approved.
* No standalone DDU is approved.
* No runtime/tool behavior changes.

This plan exists to turn the Phase 90 readiness result into the smallest
future implementation path that can preserve the approved source intent without
quietly approving DDU, downloads, artifacts, Safe Mode, RunOnce, reboot, or
driver cleanup behavior.

Driver Clean remains outside NVIDIA Path B.

The original Ultimate routing model remains preserved:

* Users who do not want NVIDIA App use `Driver Install Debloat & Settings`
  only.
* Users who want NVIDIA App use the separate Path B scripts in this order:
  `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`.
* Driver Clean remains separate from both.

Path B steps must not be merged into one script, one tool, or one combined
action.

## Source And Checksum Binding

Source mirror path:

`source-ultimate/_intake-promoted/Ultimate/5 Graphics/1 Driver Clean.ps1`

Expected SHA-256:

`CF9E1C55ACAFD8A52D2200AC3E6C3AFDF9823837C7B68101C2D4B83E074D325A`

Source script identity:

* Source-promoted intake candidate.
* Driver Clean source reference.
* Outside official active/deferred counts until explicitly promoted.
* Outside NVIDIA Path B.
* Contains the original `DDU: Auto` and `DDU: Manual` console routing.

The source mirror is reference-only and must not be modified. Future phases
must verify this checksum before using the source as implementation evidence.

## Implementation Strategy Decision

Primary strategy: **ManualHandoffFirst**

Auto mode status: **AutoBlockedUntilArtifactApproval**

ManualHandoffFirst is the safest bounded future path because the source's Auto
flow requires unapproved external artifacts, 7-Zip installation, DDU download,
DDU extraction, generated scripts, RunOnce, Safe Mode, BCD changes, immediate
reboot, and DDU execution with driver-cleaning arguments.

Manual handoff can preserve the technician-facing intent first without silently
executing DDU or pretending artifact approval exists. It can give the user a
structured Action Plan, source-linked warnings, and clear next steps while
leaving DDU download/execution blocked until Yazan approves exact artifacts,
process scopes, Safe Mode/reboot workflow, and recovery handling.

This does not weaken Ultimate behavior as a final implementation. It selects a
safe first implementation slice while Auto remains blocked until full source
behavior can be preserved under approved foundations.

## Manual Handoff Future Plan

Future manual handoff behavior, if explicitly approved later:

* User sees an Action Plan.
* User confirms understanding.
* BoostLab verifies the Driver Clean source checksum.
* BoostLab does not download DDU unless separately approved.
* BoostLab does not download 7-Zip unless separately approved.
* BoostLab does not run DDU silently.
* BoostLab does not install 7-Zip silently.
* BoostLab does not create RunOnce entries.
* BoostLab does not switch into Safe Mode.
* BoostLab does not reboot.
* BoostLab may only guide the user or open an approved location/tool in a
  future phase if explicitly approved.
* BoostLab logs that no automated DDU execution occurred.
* User is warned about Safe Mode, reboot, driver cleanup, display loss, and
  network loss risks.
* Latest Result reports that the workflow is manual handoff only.
* No Default or Restore promise is made without captured state.

Manual handoff is still not implemented in this phase.

## Auto Mode Future Blocker List

Auto mode remains blocked until all applicable approvals exist:

* DDU artifact provenance is approved.
* 7-Zip artifact provenance is approved if used.
* Download URLs and hashes are approved.
* Installer/extractor behavior is approved.
* Process handling is approved for every launched process.
* Safe Mode handling is approved.
* RunOnce handling is approved.
* `bcdedit` handling is approved.
* Reboot/recovery handling is approved.
* Generated script handling is approved.
* Driver state and rollback limitations are documented.
* Explicit user confirmation is implemented.
* Validators prove fail-closed behavior.

Until those approvals exist, Auto must remain blocked.

## Driver Clean Future Implementation Contract

Any future Driver Clean implementation must include:

* Source checksum verification.
* Explicit Action Plan.
* Explicit user confirmation.
* No silent execution.
* No hidden download.
* No uncontrolled process start.
* No uncontrolled Safe Mode switch.
* No uncontrolled RunOnce creation.
* No uncontrolled reboot.
* No Default or Restore unless real captured state exists.
* Latest Result and Activity Log reporting.
* Fail closed on missing artifact, process, reboot, or recovery approvals.
* Driver Clean-specific DDU boundary only.
* No standalone DDU reuse.
* No DDU approval outside Driver Clean.
* No 7-Zip approval outside Driver Clean.
* No Path B merge or combined NVIDIA action.

## Risk And Recovery Handling Plan

Future Driver Clean implementation must account for:

* Safe Mode risk: Safe Mode entry must require explicit approval, recovery
  instructions, exit plan, and validation before any future use.
* Reboot risk: reboot must require approved workflow records, confirmation,
  cancellation handling, and post-reboot verification.
* Driver removal risk: driver cleanup can remove display/audio driver
  components and must be explained before confirmation.
* Black screen/display risk: user must be warned that display behavior can
  degrade until drivers are reinstalled.
* Network loss risk: network driver or display stack disruption may make online
  recovery harder.
* Failed cleanup risk: partial DDU or interrupted Safe Mode flow needs clear
  user-facing recovery instructions.
* User cancellation: cancellation before execution must leave no RunOnce, BCD,
  generated script, download, or process side effect.
* Partial completion: BoostLab must report what completed, what did not, and
  whether manual recovery is required.
* Restore point/recovery guidance: BoostLab can recommend recovery preparation,
  but it must not promise that a restore point can reverse DDU driver removal.
* Restore limits: BoostLab cannot safely restore removed drivers unless a
  future approved driver-state backup and recovery model exists.

## Future UI/Action Model

Future action states, design only:

* `Analyze`
* `Prepare Manual Handoff`
* `Apply Auto`
* `Open Instructions`
* `Cancel`
* `Restore`
* `Default`

Current/future status:

* `Analyze` may be considered first to explain source behavior and current
  blocker status.
* `Prepare Manual Handoff` is the preferred first future implementation
  candidate.
* `Apply Auto` must remain blocked.
* `Open Instructions` may be considered only if the target is explicitly
  approved.
* `Cancel` must be side-effect-free before execution.
* `Restore` must remain unavailable unless captured state exists.
* `Default` must not be confused with Restore.
* No live UI changes are added in this phase.

## Validation Plan For Future Implementation

Future implementation validators must prove:

* No DDU execution during tests.
* No downloads during tests.
* No 7-Zip execution during tests.
* Source checksum verification.
* Process policy dry-run or mocked behavior.
* Reboot/Safe Mode dry-run or mocked behavior.
* RunOnce dry-run or mocked behavior.
* Generated-script dry-run or mocked behavior.
* No production allowlist entry without approval.
* No artifact provenance entry without explicit approval.
* No standalone DDU introduced.
* Deleted tools remain deleted.
* Loudness EQ and NVME Faster Driver remain deleted.
* Driver Clean remains separate from NVIDIA Path B.
* Path B steps remain separate and are not merged into one script, tool, or
  action.
* Auto fails closed until artifact, process, reboot, Safe Mode, RunOnce,
  generated-script, and recovery approvals exist.

## Recommended Next Phase

Recommended next phase: **Phase 92: Driver Clean Controlled Manual Handoff
Implementation**.

This is the most correct next step because it is the shortest path toward
resolving Driver Clean without broad documentation expansion and without
pretending DDU/7-Zip artifacts are approved. The phase should implement only a
non-executing manual-handoff workflow if Yazan approves that scope:

* `Analyze`
* `Prepare Manual Handoff`
* possibly `Open Instructions` only if the target is explicitly approved

It must not implement Auto, DDU download, DDU execution, 7-Zip download,
7-Zip installation, RunOnce, Safe Mode, `bcdedit`, reboot, or driver cleanup.

If Yazan wants Auto preservation first, then the next phase should instead be
**Phase 92: Driver Clean Artifact Provenance Decision**. That route is slower
but necessary before Auto can be implemented.

## Roadmap Compression Note

The compressed seven-script roadmap remains:

1. Driver Clean first and separate.
2. Driver Install Latest second.
3. Nvidia Settings third.
4. Hdcp, P0 State, and Msi Mode can be handled with a shared small NVIDIA
   registry/device targeting pattern if approved later.
5. BitLocker remains separate and security-sensitive.
6. After the seven source-promoted intake scripts are resolved, return to the
   18 existing deferred/placeholders.

Do not keep expanding broad NVIDIA documentation phases. Future phases should
be implementation-facing, source-specific, and approval-specific.

## Relationship To Existing Documents

This controlled implementation plan follows:

* `docs/tool-designs/driver-clean-controlled-intake-implementation-readiness.md`
* `docs/process-handling-policy.md`
* `docs/download-provenance-installer-policy.md`
* `docs/driver-state-capture-rollback.md`
* `docs/file-registry-state-capture-rollback.md`
* `docs/reboot-recovery-workflow.md`
* `docs/restore-selection-ui-runtime.md`
* `docs/tool-designs/nvidia-path-b-governance-freeze-review.md`
* `docs/final-deferred-tools-readiness-matrix.md`
* `docs/deferred-tools-execution-plan.md`
* `docs/deferred-tool-readiness-review.md`

These references do not approve execution. They identify the constraints that
must remain in place until a future explicit implementation phase approves a
narrow Driver Clean path.

## Explicit Non-Actions

Phase 91 is plan-only.

* No Driver Clean implementation.
* No Driver Clean execution.
* No DDU execution.
* No DDU download.
* No DDU artifact approval.
* No 7-Zip download.
* No 7-Zip artifact approval.
* No standalone DDU approval.
* No uncontrolled DDU execution approval.
* No runtime/tool behavior changed.
* No tool card or placeholder enabled.
* No production allowlist config created or changed.
* No artifact provenance config entry created.
* No runtime module/helper/tool module created.
* No WPF/UI runtime file modified.
* No source mirror files changed.
* No intake files changed.
* No legacy source-ultimate files changed.
* No Windows Registry change.
* No boot or Safe Mode state change.
* No RunOnce entry created.
* No reboot.
* Standalone DDU not introduced.
* Loudness EQ and NVME Faster Driver remain deleted.
* Counts unchanged: 48 active tools, 30 implemented tools, 18
  deferred/placeholders, and 7 source-promoted intake candidates separate from
  official counts.

## Phase 92 Implementation Update

Phase 92 implements `Driver Clean` as a controlled manual-handoff tool only.

Implemented actions:

* `Analyze`
* `Prepare Manual Handoff`
* `Apply Auto`

`Analyze` verifies the source mirror checksum and reports
`ManualHandoffOnly`. `Prepare Manual Handoff` records the Action Plan,
warnings, and results while performing no automated DDU execution, DDU
download, 7-Zip download, external process start, registry mutation, RunOnce
creation, Safe Mode switch, `bcdedit` call, reboot, or driver cleanup.
`Apply Auto` remains fail-closed as `AutoBlockedUntilArtifactApproval`.

Default and Restore remain unavailable. Default is not Restore, and Restore
requires real captured state that does not exist for external DDU actions.

Driver Clean remains outside NVIDIA Path B. Path B steps remain separate and
unmerged:

`Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

Phase 92 count convention:

* Active tools: 51
* Implemented tools: 33
* Deferred/placeholders: 18
* Source-promoted mirror files: 7
* Remaining unimplemented source-promoted intake candidates: 4
