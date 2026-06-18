# Driver Clean Controlled Intake Implementation Readiness

## Scope

Phase 90 is Driver Clean implementation-readiness only.

Driver Clean is separate from NVIDIA Path B. It is one of the seven
source-promoted intake scripts. Driver Clean is one of the seven source-promoted intake scripts.
It is not part of the five-step NVIDIA Path B workflow.

No execution is approved by this document. No runtime behavior changes. No tool
card or placeholder is enabled. No production allowlist entry is added. No DDU
download, DDU artifact, standalone DDU workflow, or DDU execution path is
approved.

Current official counts remain unchanged:

* Active tools: 48
* Implemented tools: 30
* Deferred/placeholders: 17
* Source-promoted intake candidates: 7 separate from official counts

## Source Review

Source mirror path:

`source-ultimate/_intake-promoted/Ultimate/5 Graphics/1 Driver Clean.ps1`

Expected SHA-256:

`CF9E1C55ACAFD8A52D2200AC3E6C3AFDF9823837C7B68101C2D4B83E074D325A`

Observed source behavior summary:

* Requires Administrator through the original per-script elevation pattern.
* Requires internet through a ping-style connectivity check.
* Presents two console choices:
  * `DDU: Auto`
  * `DDU: Manual`
* Downloads `7zip.exe` from the Ultimate-Files GitHub path.
* Installs 7-Zip silently with `/S`.
* Writes 7-Zip HKCU configuration values.
* Moves the 7-Zip Start Menu shortcut and removes the 7-Zip Start Menu folder.
* Downloads `ddu.exe` from the Ultimate-Files GitHub path.
* Extracts `ddu.exe` into `$env:SystemRoot\Temp\ddu` using 7-Zip.
* Writes a DDU `Settings.xml` file under the extracted DDU settings folder.
* Marks the DDU settings file read-only.
* Writes `HKLM\Software\Microsoft\Windows\CurrentVersion\DriverSearching`
  `SearchOrderConfig = 0`.
* Creates a temporary PowerShell script for the selected DDU flow.
* Writes a RunOnce entry that runs the temporary DDU script.
* Uses `bcdedit /set {current} safeboot minimal`.
* Restarts the system with `shutdown -r -t 00`.
* The Auto flow removes Safe Mode boot in the generated script, then launches
  DDU with `-CleanSoundBlaster -CleanRealtek -CleanAllGpus -Restart`.
* The Manual flow removes Safe Mode boot in the generated script, then opens
  DDU interactively.
* The Manual flow opens DDU interactively.

DDU-related behavior identified:

* DDU download from the Ultimate-Files GitHub path.
* DDU extraction to a Windows temp folder.
* DDU configuration file generation.
* DDU read-only configuration enforcement.
* DDU RunOnce handoff through a generated PowerShell script.
* DDU execution in Safe Mode after reboot.
* Auto DDU clean for SoundBlaster, Realtek, and all GPUs, followed by restart.
* Manual DDU launch after Safe Mode reboot.

External artifact, download, process, reboot, cleanup, and driver-risk behavior:

* External artifact download: `7zip.exe`.
* External artifact download: `ddu.exe`.
* Installer execution: 7-Zip silent installer.
* Extraction process: 7-Zip command-line extraction.
* Generated scripts: `$env:SystemRoot\Temp\ddu.ps1` and
  `$env:SystemRoot\Temp\ddumanual.ps1`.
* Registry writes: HKCU 7-Zip options, HKLM DriverSearching, HKLM RunOnce.
* File operations: temp file creation, DDU settings write, Start Menu shortcut
  move, Start Menu folder removal.
* Boot configuration: Safe Mode BCD entry.
* Reboot: immediate shutdown restart.
* Driver risk: DDU removes display/audio driver components and can affect GPU,
  Realtek, SoundBlaster, and related driver state.

## Controlled Exception Boundary

Yazan approved Driver Clean intake despite DDU usage.

That exception is narrow:

* It does not approve standalone DDU.
* It does not approve DDU downloads.
* It does not approve DDU artifacts.
* It does not approve uncontrolled DDU execution.
* It does not approve reusing DDU elsewhere.
* It does not approve DDU as a general-purpose BoostLab capability.
* It does not approve Driver Clean implementation by itself.

Any future implementation must be Driver Clean-specific and bounded. The DDU
exception cannot be treated as production artifact approval, production
execution approval, or approval to create a standalone DDU tool.

## Implementation Readiness Decision

Status: **NeedsArtifactDecision**

Reason:

Driver Clean cannot move directly to implementation because its approved source
behavior depends on external `7zip.exe` and `ddu.exe` artifacts, installer
execution, extraction, generated scripts, RunOnce, Safe Mode, reboot, and DDU
execution. The current Yazan-approved intake exception allows this source to be
reviewed despite DDU usage, but it does not approve DDU artifacts, downloads,
or execution.

The first blocking decision is artifact provenance. Without explicit artifact
approval for the exact 7-Zip and DDU artifacts, any implementation would either
download unapproved binaries or weaken the Ultimate behavior by omitting the
source-defined DDU path. After the artifact decision, a separate process,
reboot/Safe Mode/recovery, generated-script, and driver-state decision is still
required.

This status does not mean Driver Clean is refused forever. It means Driver
Clean is not implementation-ready until the artifact decision is resolved.

## Minimum Safe Future Implementation Contract

Any future Driver Clean implementation must satisfy all of the following:

* No silent DDU execution.
* No automatic DDU download unless separately approved.
* No bundled DDU artifact unless separately approved.
* No 7-Zip download or installer execution unless separately approved.
* Explicit Action Plan before any download, installer, extraction, registry
  write, generated script, RunOnce entry, Safe Mode change, DDU launch, or
  reboot.
* Explicit user confirmation before any driver-cleaning, Safe Mode, RunOnce,
  reboot, generated-script, or DDU execution flow.
* Source checksum verification against
  `CF9E1C55ACAFD8A52D2200AC3E6C3AFDF9823837C7B68101C2D4B83E074D325A`.
* Download provenance and installer execution policy integration for every
  artifact.
* Process handling policy integration for 7-Zip extraction, DDU launch, and any
  generated script process.
* Driver state and recovery warning before DDU can run.
* Reboot, Safe Mode, RunOnce, and recovery handling if the original automatic
  or manual handoff is preserved.
* File and registry state capture for touched paths where policy requires it.
* Activity Log and Latest Result reporting for every planned and completed
  step.
* No Default or Restore promise unless real captured state exists and a Restore
  selection flow is approved.
* Fail closed on missing artifact, missing signature/hash, missing confirmation,
  missing process scope, missing reboot/Safe Mode workflow, missing generated
  script scope, or missing recovery plan.
* No standalone DDU module, card, helper, artifact approval, or reusable DDU
  runtime.

## Recommended Next Phase

Recommended next phase: **Phase 91: Driver Clean Controlled Implementation
Plan**.

That phase should stay small and concrete. It should decide the exact Driver
Clean-specific implementation path and list required approvals for artifacts,
installer execution, generated scripts, RunOnce, Safe Mode, reboot/recovery,
process handling, file/registry state capture, driver-state warnings, and DDU
handoff.

It should not implement all seven intake scripts. It should not create broad
NVIDIA documentation. It should not add indexes, backlinks, freeze reviews, or
blanket governance. It should not approve standalone DDU.

If the artifact decision cannot be made in that phase, the phase should produce
**Phase 91: Driver Clean Refusal/Deferral Record** instead.

Phase 91 records the controlled implementation plan in
`docs/tool-designs/driver-clean-controlled-implementation-plan.md`. It chooses
`ManualHandoffFirst` as the future strategy and keeps Auto blocked until
artifact, process, Safe Mode, RunOnce, reboot/recovery, generated-script, and
driver-state approvals exist. It does not implement Driver Clean or approve
DDU/7-Zip artifacts.

## Roadmap Compression Note

The compressed seven-script roadmap is:

1. Driver Clean first, separate from NVIDIA Path B.
2. Driver Install Latest second.
3. Nvidia Settings third.
4. Hdcp, P0 State, and Msi Mode can be grouped later only after a shared NVIDIA
   registry/device targeting and capture pattern is ready.
5. BitLocker last or separate because it is security-sensitive and outside
   NVIDIA Path B.
6. After these seven source-promoted intake scripts are resolved, return to the
   18 existing deferred/placeholders.

Do not keep expanding broad NVIDIA Path B documentation phases. Future phases
should be small, source-specific, approval-specific, and implementation-facing.

## Relationship To Existing Documents

This readiness document is constrained by:

* `docs/tool-designs/nvidia-path-b-governance-freeze-review.md`
* `docs/final-deferred-tools-readiness-matrix.md`
* `docs/deferred-tools-execution-plan.md`
* `docs/deferred-tool-readiness-review.md`
* `docs/process-handling-policy.md`
* `docs/download-provenance-installer-policy.md`
* `docs/driver-state-capture-rollback.md`
* `docs/file-registry-state-capture-rollback.md`
* `docs/reboot-recovery-workflow.md`
* `docs/restore-selection-ui-runtime.md`

These references do not approve execution. They identify the existing
foundations and blockers that any future Driver Clean-specific implementation
plan must satisfy.

## Explicit Non-Actions

Phase 90 is implementation-readiness only.

* No Driver Clean execution.
* No DDU execution.
* No DDU download.
* No DDU artifact approval.
* No standalone DDU approval.
* No uncontrolled DDU execution approval.
* No 7-Zip artifact approval.
* No installer execution approval.
* No generated-script approval.
* No RunOnce approval.
* No Safe Mode approval.
* No reboot approval.
* No driver-cleaning operation approval.
* No runtime/tool behavior changed.
* No tool card or placeholder enabled.
* No production allowlist config created or changed.
* No runtime module/helper/tool module created.
* No WPF/UI runtime file modified.
* No source mirror files changed.
* No intake files changed.
* No legacy source-ultimate files changed.
* Standalone DDU not introduced.
* Loudness EQ and NVME Faster Driver remain deleted.
* Counts unchanged: 48 active tools, 30 implemented tools, 18
  deferred/placeholders, and 7 source-promoted intake candidates separate from
  official counts.
