# Resizable BAR Assistant Scope Design

## Purpose

This Phase 56 document defines the future implementation scope for the
`Resizable BAR Assistant` tool. It is design-only.

No Resizable BAR Assistant behavior is implemented by this document. No runtime
behavior, module behavior, production download artifact, tool execution entry,
driver profile scope, registry scope, file scope, reboot scope, firmware
restart scope, Default behavior, or Restore behavior is approved here.

Resizable BAR Assistant remains a refused placeholder until a later approved
phase adds exact NVIDIA-only artifact provenance, driver profile inventory,
rollback rules, firmware/reboot workflow, verification, and implementation.

## Source Reference

* Source path: `source-ultimate/8 Advanced/3 Resizable BAR Assistant.ps1`
* Source SHA-256: `E2E1D919B350FA5190DFD4FAF23F3AB51ED2A324155CAFF49CDE774B092FB443`
* Current BoostLab module path:
  `modules/Advanced/resizable-bar-assistant.psm1`
* Current status: refused placeholder
* Current implemented actions: none

Relevant foundations:

* Phase 35: download provenance and installer execution policy
* Phase 36: file and registry state capture and rollback
* Phase 40: reboot and recovery workflow
* Phase 41: driver state capture and rollback
* Phase 48: branch-level product scope, with GPU-specific tooling limited to
  NVIDIA

## Product Scope Decision

The Ultimate source is NVIDIA-specific. It does not include AMD or Intel
branches. A future BoostLab implementation may consider only the NVIDIA-specific
behavior if all other governance requirements are met.

No AMD GPU-specific behavior is approved. No Intel GPU-specific behavior is approved. GPU-neutral detection may be preserved later only if it is read-only, safe, and needed to report that the tool is not applicable. NVIDIA driver profile mutation and firmware restart remain high-risk even though NVIDIA is the supported GPU vendor scope.

## Source Behavior Summary

The Ultimate source:

1. self-elevates as Administrator
2. requires internet by pinging `8.8.8.8`
3. downloads `inspector.exe` from
   `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/inspector.exe`
   to `%SystemRoot%\Temp\inspector.exe`
4. shows a menu with four choices:
   * `DEFAULT DRIVER WHITELIST PER GAME (DEFAULT)`
   * `FORCE ON`
   * `FORCE OFF`
   * `TO BIOS`
5. for the first three choices, recursively unblocks files under
   `C:\ProgramData\NVIDIA Corporation\Drs`
6. writes one of three generated NVIDIA Profile Inspector `.nip` files:
   * `%SystemRoot%\Temp\default.nip`
   * `%SystemRoot%\Temp\forceon.nip`
   * `%SystemRoot%\Temp\forceoff.nip`
7. imports the selected `.nip` through:
   `%SystemRoot%\Temp\inspector.exe -silentImport -silent <nip path>`
8. opens `%SystemRoot%\Temp\inspector.exe`
9. for `TO BIOS`, runs:
   `cmd /c C:\Windows\System32\shutdown.exe /r /fw /t 0`

The source contains no AMD or Intel GPU branch. The source contains no Default
branch in the BoostLab captured-state sense. The source's "DEFAULT DRIVER
WHITELIST PER GAME" option is an NVIDIA profile preset import, not a BoostLab
Restore operation.

## Current Decision

Do not implement Analyze, Apply, Open, Default, or Restore yet.

The source depends on a mutable external executable, NVIDIA driver profile
mutation, recursive unblocking of NVIDIA DRS files, generated `.nip` profile
files, and an immediate firmware restart command. These behaviors are outside
the currently approved production scopes because no artifact, driver profile,
file, registry, reboot, or firmware restart scope has been approved.

## Behavior Groups

### 1. GPU/Vendor Detection Behavior

* Exact source logic:
  * The source does not perform explicit GPU vendor detection.
  * The visible menu text is NVIDIA-specific:
    `NVIDIA RESIZABLE BAR FORCE:`
* Target type:
  * Future read-only hardware/driver detection only, if added later.
* Intended mutation type:
  * None in the source before menu selection.
* Required foundation:
  * Phase 41 driver inventory for NVIDIA device/driver state if future
    Apply-style behavior is attempted.
* Required future production allowlist:
  * Exact NVIDIA GPU/driver detection fields and accepted NVIDIA vendor ids.
  * No AMD or Intel GPU-specific branch.
* Required inventory/capture before mutation:
  * NVIDIA adapter identity, driver provider, driver version, driver package
    identity, and profile-store state before any profile import.
* Required confirmation level:
  * Read-only Analyze may be informational.
  * Any mutation requires high-risk confirmation.
* Required verification:
  * Confirm NVIDIA GPU and supported NVIDIA driver/profile tooling before any
    future mutation.
* Rollback/restore feasibility:
  * Detection alone does not need rollback.
* Risk level:
  * Low for read-only detection, high once used to gate driver profile mutation.
* Later implementation decision:
  * Can be implemented later as read-only Analyze if it does not execute
    Inspector, modify DRS, download artifacts, or reboot.

### 2. NVIDIA-Specific Resizable BAR Checks

* Exact source logic:
  * The source does not query current Resizable BAR state.
  * It provides three NVIDIA Profile Inspector import presets and one firmware
    restart option.
  * The NVIDIA rBAR profile setting is:
    `rBAR - Enable`, SettingID `983226`, ValueType `Dword`.
* Target type:
  * NVIDIA driver profile setting.
* Intended mutation type:
  * Import a Base Profile `.nip` that either omits the rBAR setting, sets it to
    `1`, or sets it to `0`.
* Required foundation:
  * Phase 41 driver state capture and rollback.
* Required future production allowlist:
  * Exact NVIDIA profile setting id `983226`.
  * Exact accepted values:
    * Default driver whitelist: no `rBAR - Enable` entry in `default.nip`
    * Force On: `rBAR - Enable` = `1`
    * Force Off: `rBAR - Enable` = `0`
* Required inventory/capture before mutation:
  * Current NVIDIA Base Profile state for all imported settings, not only rBAR.
  * Driver profile backup or equivalent exported state before import.
* Required confirmation level:
  * High-risk explicit confirmation.
* Required verification:
  * Verify the imported profile state after Inspector runs.
  * Report unsupported or unreadable NVIDIA profile state as Warning or Failed
    according to the future verification contract.
* Rollback/restore feasibility:
  * Restore is unavailable until exact pre-import NVIDIA profile state can be
    captured and restored.
* Risk level:
  * High
* Later implementation decision:
  * Must remain refused until exact NVIDIA driver profile scope and rollback
    behavior are approved.

### 3. NVIDIA Profile Inspector Download or Executable Behavior

* Exact source targets:
  * URL:
    `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/inspector.exe`
  * Output file:
    `%SystemRoot%\Temp\inspector.exe`
  * Import command:
    `%SystemRoot%\Temp\inspector.exe -silentImport -silent <nip path>`
  * Open command:
    `%SystemRoot%\Temp\inspector.exe`
* Target type:
  * Downloaded executable and external tool execution.
* Intended mutation type:
  * Download and run NVIDIA Profile Inspector.
* Required foundation:
  * Phase 35 download provenance and installer/tool execution policy.
* Required future production allowlist:
  * Exact immutable artifact source, file name, expected SHA-256, expected size
    or size bounds, signer/publisher if applicable, license/redistribution
    note, consumer tool id, allowed actions, and execution permission.
  * Exact allowed command arguments for silent import and visible launch.
* Required inventory/capture before mutation:
  * Existing `%SystemRoot%\Temp\inspector.exe` existence, hash, and ownership
    if future implementation writes to the same path.
* Required confirmation level:
  * High-risk explicit confirmation before download and execution.
* Required verification:
  * Artifact is known and approved.
  * Downloaded file matches expected file name and SHA-256.
  * Signer/publisher requirement passes if executable execution is approved.
  * Execution request matches the approved command descriptor.
* Rollback/restore feasibility:
  * File cleanup requires exact generated/temp file ownership tracking.
* Risk level:
  * High
* Later implementation decision:
  * Must remain refused while the source URL is mutable and no artifact
    provenance entry is approved.

### 4. NVIDIA Driver Profile Mutation Behavior

* Exact source targets:
  * `C:\ProgramData\NVIDIA Corporation\Drs`
  * `%SystemRoot%\Temp\default.nip`
  * `%SystemRoot%\Temp\forceon.nip`
  * `%SystemRoot%\Temp\forceoff.nip`
  * `%SystemRoot%\Temp\inspector.exe -silentImport -silent ...`
* Target type:
  * NVIDIA DRS profile store, generated `.nip` files, and external tool import.
* Intended mutation type:
  * Recursive `Unblock-File` on NVIDIA DRS files.
  * Import the selected Base Profile XML through Inspector.
* Required foundation:
  * Phase 41 driver state capture and rollback.
  * Phase 36 file state capture for generated `.nip` files.
* Required future production allowlist:
  * Exact DRS path handling policy.
  * Exact `.nip` files and hashes.
  * Exact imported settings list and values.
  * Exact Inspector command descriptors.
* Required inventory/capture before mutation:
  * NVIDIA DRS profile backup or exported Base Profile.
  * Prior existence/hash of generated `.nip` temp files.
* Required confirmation level:
  * High-risk explicit driver-profile mutation confirmation.
* Required verification:
  * Every targeted NVIDIA profile setting reports expected value or a clear
    unsupported/unreadable warning.
  * Confirm no AMD or Intel profile behavior was attempted.
* Rollback/restore feasibility:
  * Restore is unavailable until a verified profile export/backup and restore
    path exists.
* Risk level:
  * High
* Later implementation decision:
  * Must remain refused until profile capture, import, verification, and
    rollback are designed.

### 5. Registry or File Targets If Present

* Exact source targets:
  * No direct registry write appears in the source.
  * File targets:
    * `%SystemRoot%\Temp\inspector.exe`
    * `%SystemRoot%\Temp\default.nip`
    * `%SystemRoot%\Temp\forceon.nip`
    * `%SystemRoot%\Temp\forceoff.nip`
    * `C:\ProgramData\NVIDIA Corporation\Drs`
* Target type:
  * Downloaded executable, generated XML files, and existing NVIDIA profile
    store files.
* Intended mutation type:
  * Download executable, write XML profile files, recursively unblock DRS files.
* Required foundation:
  * Phase 36 file state capture and rollback.
  * Phase 35 artifact provenance for executable content.
* Required future production allowlist:
  * Exact temp file paths.
  * Exact generated XML file content hashes.
  * Exact DRS unblocking scope if preserved.
* Required inventory/capture before mutation:
  * Existing temp file state and DRS profile-state evidence.
* Required confirmation level:
  * High-risk confirmation when tied to driver profile mutation.
* Required verification:
  * Generated `.nip` files match approved content before Inspector import.
  * DRS path exists and belongs to NVIDIA profile storage before unblocking.
* Rollback/restore feasibility:
  * File Restore unavailable until exact file capture and cleanup/restore
    ownership are approved.
* Risk level:
  * High
* Later implementation decision:
  * File writes and DRS mutation remain refused until exact scopes are added.

### 6. Firmware Restart / Reboot Behavior

* Exact source target:
  * `cmd /c C:\Windows\System32\shutdown.exe /r /fw /t 0`
* Target type:
  * Immediate firmware restart command.
* Intended mutation type:
  * Restart the machine and request UEFI firmware settings.
* Required foundation:
  * Phase 40 reboot and recovery workflow.
* Required future production allowlist:
  * Exact firmware restart workflow scope for `resizable-bar-assistant`.
  * Exact shutdown path and arguments if preserved.
* Required inventory/capture before mutation:
  * No system mutation record is needed for restart itself, but the workflow
    requires explicit checkpoint, cancellation/recovery instructions, and clear
    user acknowledgement.
* Required confirmation level:
  * High-risk explicit confirmation saying the PC will restart and attempt to
    enter BIOS/UEFI firmware settings.
* Required verification:
  * Pre-restart plan and confirmation captured.
  * Post-return verification is limited unless a future resume workflow is
    explicitly approved.
* Rollback/restore feasibility:
  * Not a Restore action. Firmware restart cannot be undone once accepted.
* Risk level:
  * High
* Later implementation decision:
  * Must remain refused until an exact firmware restart workflow is approved or
    reused from an existing approved BIOS restart pattern.

### 7. User Confirmation and Warning Requirements

* Exact source behavior:
  * Console menu with choices `1` through `4`.
  * No detailed confirmation before importing driver profiles.
  * No confirmation before immediate firmware restart beyond selecting menu
    option `4`.
* Target type:
  * User interaction and safety gating.
* Intended mutation type:
  * Convert `Read-Host` menu choices into GUI actions only after full scope
    approval.
* Required foundation:
  * Action Plan and confirmation framework.
* Required future production allowlist:
  * Exact action mapping for future approved behavior.
* Required inventory/capture before mutation:
  * Action Plan must list artifact, file, driver profile, and reboot impacts
    before any mutation.
* Required confirmation level:
  * High-risk explicit confirmation for download/execution, profile import,
    and firmware restart.
* Required verification:
  * Confirmation was shown and accepted before any high-risk action.
* Rollback/restore feasibility:
  * Not applicable by itself.
* Risk level:
  * High
* Later implementation decision:
  * Future UI must add warnings rather than silently mirroring the source's
    minimal console prompt.

### 8. Verification Behavior After Mutation

* Exact source behavior:
  * Opens Inspector after import.
  * Does not programmatically verify rBAR/profile state.
  * Does not verify firmware/BIOS changes.
* Target type:
  * Future verification contract.
* Intended mutation type:
  * None in the source beyond launching Inspector.
* Required foundation:
  * Phase 41 driver verification.
  * Phase 40 reboot workflow verification if firmware restart is approved.
* Required future production allowlist:
  * Exact NVIDIA profile read/verification method.
  * Exact rBAR/driver support check if available.
* Required inventory/capture before mutation:
  * Pre-import profile values and NVIDIA driver state.
* Required confirmation level:
  * High-risk workflow result reporting.
* Required verification:
  * Artifact verification.
  * `.nip` content verification.
  * Profile import exit code.
  * Expected profile setting values after import.
  * Unsupported setting warnings per current driver/build.
* Rollback/restore feasibility:
  * Verification is required before any future Restore claim.
* Risk level:
  * High
* Later implementation decision:
  * Must be designed before any Apply-like action is exposed.

### 9. Default/Restore Behavior If Present

* Exact source behavior:
  * Menu option `1` is labeled:
    `DEFAULT DRIVER WHITELIST PER GAME (DEFAULT)`.
  * It imports `default.nip`, which does not contain `rBAR - Enable`.
  * There is no captured-state Restore behavior.
* Target type:
  * NVIDIA profile preset import.
* Intended mutation type:
  * Import the source-defined default profile preset.
* Required foundation:
  * Phase 41 driver state capture and rollback.
* Required future production allowlist:
  * Exact mapping decision:
    * Source "Default driver whitelist per game" may become a future `Default`
      only if the full profile import is approved.
    * BoostLab `Restore` must remain separate and record-based.
* Required inventory/capture before mutation:
  * Pre-import profile state for all settings touched by `default.nip`.
* Required confirmation level:
  * High-risk explicit confirmation because source default still mutates NVIDIA
    profile state.
* Required verification:
  * Imported default profile values match source XML.
  * `rBAR - Enable` absence is verified or reported clearly.
* Rollback/restore feasibility:
  * Restore remains unavailable without captured driver profile state.
* Risk level:
  * High
* Later implementation decision:
  * Default/Restore must remain unavailable until exact driver profile rollback
    and restore selection are approved.

### 10. Unsupported AMD/Intel Behavior If Present

* Exact source behavior:
  * No AMD GPU branch is present.
  * No Intel GPU branch is present.
* Target type:
  * Product-scope denial.
* Intended mutation type:
  * None.
* Required foundation:
  * Phase 48 product scope.
* Required future production allowlist:
  * None. AMD and Intel GPU-specific behavior remains unsupported unless Yazan
    expands scope later.
* Required inventory/capture before mutation:
  * If a future Analyze detects AMD or Intel GPUs, it should report
    NotApplicable or visual-only guidance without executing GPU-specific
    behavior.
* Required confirmation level:
  * Not applicable for unsupported branches.
* Required verification:
  * Tests must prove AMD/Intel branches are not exposed or executed.
* Rollback/restore feasibility:
  * Not applicable.
* Risk level:
  * High if someone attempts to invent AMD/Intel equivalents.
* Later implementation decision:
  * Must remain refused.

### 11. Unsupported Download/Tool/Driver-Profile Targets

* Exact source targets:
  * Mutable GitHub raw URL under `refs/heads/main`.
  * `%SystemRoot%\Temp\inspector.exe`.
  * `%SystemRoot%\Temp\*.nip`.
  * `C:\ProgramData\NVIDIA Corporation\Drs`.
  * Firmware restart command.
* Target type:
  * External tool, generated profile files, NVIDIA profile store, reboot path.
* Intended mutation type:
  * Download, execute, profile import, unblocking, firmware restart.
* Required foundation:
  * Phase 35, Phase 36, Phase 40, and Phase 41.
* Required future production allowlist:
  * Exact artifact, command descriptor, generated file, NVIDIA driver profile,
    and firmware restart scopes.
* Required inventory/capture before mutation:
  * Artifact hash/signature, generated file hashes, NVIDIA profile state,
    reboot workflow record.
* Required confirmation level:
  * High-risk explicit confirmation.
* Required verification:
  * Every artifact, generated file, command, profile setting, and reboot
    request must report Passed, Warning, Failed, or NotAvailable.
* Rollback/restore feasibility:
  * Restore remains unavailable without exact driver profile rollback, file
    rollback, registry rollback if later discovered, and reboot workflow
    selection.
* Risk level:
  * High
* Later implementation decision:
  * Unknown, mutable, unverified, AMD/Intel, or out-of-scope targets remain denied.

## Exact Source Target Inventory

The source targets the following exact identities. This list is inventory only,
not approval:

* Download URL:
  `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/inspector.exe`
* Downloaded executable:
  `%SystemRoot%\Temp\inspector.exe`
* NVIDIA DRS path:
  `C:\ProgramData\NVIDIA Corporation\Drs`
* Generated profile files:
  * `%SystemRoot%\Temp\default.nip`
  * `%SystemRoot%\Temp\forceon.nip`
  * `%SystemRoot%\Temp\forceoff.nip`
* Inspector import command:
  `%SystemRoot%\Temp\inspector.exe -silentImport -silent <nip path>`
* Inspector open command:
  `%SystemRoot%\Temp\inspector.exe`
* Firmware restart command:
  `cmd /c C:\Windows\System32\shutdown.exe /r /fw /t 0`

## NVIDIA Profile Setting Inventory

The source imports the following Base Profile settings. This list is inventory
only and is not an approved driver-profile scope.

| Setting name | Setting ID | Default driver whitelist value | Force On value | Force Off value | Type |
|---|---:|---|---|---|---|
| Frame Rate Limiter V3 | 277041154 | 0 | 0 | 0 | Dword |
| GSYNC - Application Mode | 294973784 | 0 | 0 | 0 | Dword |
| GSYNC - Application State | 279476687 | 4 | 4 | 4 | Dword |
| GSYNC - Global Feature | 278196567 | 0 | 0 | 0 | Dword |
| GSYNC - Global Mode | 278196727 | 0 | 0 | 0 | Dword |
| GSYNC - Indicator Overlay | 268604728 | 0 | 0 | 0 | Dword |
| Maximum Pre-Rendered Frames | 8102046 | 1 | 1 | 1 | Dword |
| Preferred Refresh Rate | 6600001 | 1 | 1 | 1 | Dword |
| Ultra Low Latency - CPL State | 390467 | 2 | 2 | 2 | Dword |
| Ultra Low Latency - Enabled | 277041152 | 1 | 1 | 1 | Dword |
| Vertical Sync | 11041231 | 138504007 | 138504007 | 138504007 | Dword |
| Vertical Sync - Smooth AFR Behavior | 270198627 | 0 | 0 | 0 | Dword |
| Vertical Sync - Tear Control | 5912412 | 2525368439 | 2525368439 | 2525368439 | Dword |
| Vulkan/OpenGL Present Method | 550932728 | 0 | 0 | 0 | Dword |
| Antialiasing - Gamma Correction | 276652957 | 0 | 0 | 0 | Dword |
| Antialiasing - Mode | 276757595 | 1 | 1 | 1 | Dword |
| Antialiasing - Setting | 282555346 | 0 | 0 | 0 | Dword |
| Anisotropic Filter - Optimization | 8703344 | 1 | 1 | 1 | Dword |
| Anisotropic Filter - Sample Optimization | 15151633 | 1 | 1 | 1 | Dword |
| Anisotropic Filtering - Mode | 282245910 | 1 | 1 | 1 | Dword |
| Anisotropic Filtering - Setting | 270426537 | 1 | 1 | 1 | Dword |
| Texture Filtering - Negative LOD Bias | 1686376 | 0 | 0 | 0 | Dword |
| Texture Filtering - Quality | 13510289 | 20 | 20 | 20 | Dword |
| Texture Filtering - Trilinear Optimization | 3066610 | 0 | 0 | 0 | Dword |
| CUDA - Force P2 State | 1343646814 | 0 | 0 | 0 | Dword |
| CUDA - Sysmem Fallback Policy | 283962569 | 1 | 1 | 1 | Dword |
| Power Management - Mode | 274197361 | 1 | 1 | 1 | Dword |
| rBAR - Enable | 983226 | Not present | 1 | 0 | Dword |
| Shader Cache - Cache Size | 11306135 | 4294967295 | 4294967295 | 4294967295 | Dword |
| Threaded Optimization | 549528094 | 1 | 1 | 1 | Dword |
| OpenGL GDI Compatibility | 544392611 | 0 | 0 | 0 | Dword |
| Preferred OpenGL GPU | 550564838 | id,2.0:268410DE,00000100,GF - (400,2,161,24564) @ (0) | id,2.0:268410DE,00000100,GF - (400,2,161,24564) @ (0) | id,2.0:268410DE,00000100,GF - (400,2,161,24564) @ (0) | String |

## Future Safe Apply Requirements

A future safe Apply would require all of the following:

1. A source-preserving Action Plan that decomposes download, file, driver
   profile, Inspector execution, and firmware restart behavior.
2. Exact Phase 35 artifact provenance for `inspector.exe`, including immutable
   source, file name, version, expected SHA-256, size or size bounds,
   signer/publisher policy, license/redistribution note, and consumer tool id.
3. Exact approved command descriptors for Inspector silent import and visible
   launch.
4. Exact Phase 36 file scopes for generated `.nip` files and any future temp
   executable handling.
5. Exact Phase 41 NVIDIA driver/profile scopes for every imported setting.
6. Exact profile backup or export method before mutation.
7. Exact verification method for imported NVIDIA profile settings.
8. Exact Phase 40 firmware restart scope if `TO BIOS` is preserved.
9. Explicit high-risk confirmation for download/execution, driver profile
   mutation, and firmware restart.
10. Migration record approved by Yazan.

## Default and Restore Boundary

The source option `DEFAULT DRIVER WHITELIST PER GAME (DEFAULT)` is a
source-defined NVIDIA profile import preset. It is not a BoostLab captured-state
Restore.

Current Default/Restore must remain unavailable. A future Default would need
the same artifact, file, driver profile, and verification governance as Force
On/Force Off.

Restore remains unavailable unless exact driver profile rollback, file
rollback, registry rollback if later discovered, and reboot/recovery workflow
selection are approved. BoostLab must not infer prior NVIDIA profile state from
the source's default `.nip` file.

## Production Approval State

No production download/tool/driver-profile/registry/file/reboot/firmware scopes are approved by this document.

No AMD GPU-specific behavior is approved. No Intel GPU-specific behavior is approved.

Resizable BAR Assistant remains a placeholder/refused tool.

The current placeholder module must remain non-executing. A future migration
phase must not implement a partial "safe-looking" subset if doing so would
weaken the source's effective NVIDIA Profile Inspector and firmware restart
behavior.
