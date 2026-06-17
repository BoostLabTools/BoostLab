# Missing Ultimate Scripts Intake Review

## Purpose

Phase 69 reviews seven Ultimate scripts that were manually copied into the intake area:

`intake/missing-ultimate-scripts/Ultimate/`

This is an intake review only. It does not promote the scripts into `source-ultimate/`, create tool cards, create modules, enable placeholders, approve production scopes, or change runtime behavior.

## Current Counts

Official BoostLab counts do not change in this phase. Phase 69 was intake
review only.

Current BoostLab counts after Phase 96:

* Active tools: **53**
* Implemented tools: **35**
* Deferred/placeholders: **18**
* Intake candidate scripts reviewed here: **7**
* Remaining unimplemented source-promoted intake candidates: **2**

The intake scripts were later source-promoted into the protected mirror. Driver
Clean was then promoted in Phase 92 as a controlled manual-handoff active tool.
Driver Install Latest was promoted in Phase 93 as controlled manual handoff
only. Nvidia Settings was promoted in Phase 94 as controlled manual handoff
only. HDCP was promoted in Phase 95 as controlled NVIDIA-only registry behavior
with source-defined Apply/Default and capture before mutation. P0 State was
promoted in Phase 96 as controlled NVIDIA-only registry behavior with
source-defined Apply/Default and capture before mutation. The remaining
two intake scripts should not be counted as active or deferred
BoostLab tools unless a future source-promotion phase explicitly accepts them
into the official catalog.

## Intake File List

| Intake path | Exists | Size bytes | Lines | SHA-256 |
|---|---:|---:|---:|---|
| `intake/missing-ultimate-scripts/Ultimate/5 Graphics/1 Driver Clean.ps1` | Yes | 10728 | 255 | `CF9E1C55ACAFD8A52D2200AC3E6C3AFDF9823837C7B68101C2D4B83E074D325A` |
| `intake/missing-ultimate-scripts/Ultimate/5 Graphics/2 Driver Install Latest.ps1` | Yes | 4012 | 93 | `41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F` |
| `intake/missing-ultimate-scripts/Ultimate/5 Graphics/4 Nvidia Settings.ps1` | Yes | 14121 | 340 | `903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5` |
| `intake/missing-ultimate-scripts/Ultimate/5 Graphics/5 Hdcp.ps1` | Yes | 2394 | 68 | `5C350D28F795D678051E6088F34968DF8D90B3D9024F558C5FAFB2899D1A906A` |
| `intake/missing-ultimate-scripts/Ultimate/5 Graphics/6 P0 State.ps1` | Yes | 2568 | 79 | `382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC` |
| `intake/missing-ultimate-scripts/Ultimate/5 Graphics/7 Msi Mode.ps1` | Yes | 2819 | 85 | `94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7` |
| `intake/missing-ultimate-scripts/Ultimate/3 Setup/1 BitLocker.ps1` | Yes | 1589 | 60 | `1678E97FB5AFF851F1491A2D96C82A5716B1FA07CB4E3A4A5E0F3FB1B086FBA1` |

## Deleted And Disallowed Tool Conflict Check

Deleted and disallowed BoostLab tools remain excluded:

* Loudness EQ
* NVME Faster Driver
* Windows Activation Helper
* Firewall
* DEP
* File Download Security Warning
* MPO
* FSO
* FSE
* Hardware Flip
* AMD ULPS
* WHQL Secure Boot Bypass
* Keyboard Shortcuts
* Search Shell Mobsync
* Core 1 Thread 1
* DDU
* UAC
* Scaling
* Start Menu Shortcuts

Conflict result:

* `Driver Clean.ps1` is a Yazan-approved intake exception despite DDU usage; this does not approve standalone DDU or DDU execution.
* `Driver Clean.ps1` downloads and runs Display Driver Uninstaller / DDU behavior in the intake source. Phase 92 implements controlled manual handoff only; future implementation requires dedicated Driver Clean scope/provenance/safety design before any DDU execution can be considered.
* `Driver Install Latest.ps1` downloads and launches the latest NVIDIA driver installer in the intake source. Phase 93 implements controlled manual handoff only; Auto remains blocked until NVIDIA artifact/download, installer descriptor, driver-state, process handoff, reboot/session, and recovery approvals exist.
* The remaining two intake scripts do not directly match the deleted tool names above, but they still require separate governance review before any promotion or implementation.
* Loudness EQ remains deleted and is not present in the intake set.
* NVME Faster Driver remains deleted and is not present in the intake set.

## Duplicate / Current Source Conflict Check

No intake script currently exists in `source-ultimate/` under the same relative path or same script title.

There are source-order conflicts if these files are later promoted with their current numbering:

* `source-ultimate/5 Graphics/1 Driver Install Debloat & Settings.ps1` already occupies Graphics slot 1.
* `source-ultimate/5 Graphics/2 DirectX.ps1` already occupies Graphics slot 2.
* `source-ultimate/5 Graphics/4 Graphics Configuration Center.ps1` already occupies Graphics slot 4.
* `source-ultimate/3 Setup/1 Memory Compression.ps1` already occupies Setup slot 1.

These are numbering/order reconciliation conflicts, not duplicate file-content conflicts.

## Product Scope Review

Phase 48 product scope applies:

* NVIDIA-specific behavior may be considered future-eligible when otherwise approved.
* AMD and Intel GPU-specific branches remain unsupported.
* Shared Windows behavior may be preserved when otherwise safe.
* Explicit Windows 10-only branches or options remain unsupported.

The intake graphics scripts are mostly NVIDIA-specific or driver-focused. Future promotion must preserve NVIDIA-only scope and must not port AMD/Intel branches from `Driver Install Latest.ps1`.

## NVIDIA App Alternate Workflow

The following five scripts form a specific alternate NVIDIA workflow from the original Ultimate author. Their order must be preserved if they are ever accepted into BoostLab:

1. `5 Graphics/2 Driver Install Latest.ps1`
2. `5 Graphics/4 Nvidia Settings.ps1`
3. `5 Graphics/5 Hdcp.ps1`
4. `5 Graphics/6 P0 State.ps1`
5. `5 Graphics/7 Msi Mode.ps1`

Workflow relationship:

* Path A: `Driver Install Debloat & Settings`
* Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

Path B is an alternate NVIDIA App workflow for users who want to keep or use NVIDIA App features such as recording or related app features. Future UI must not let Path A and Path B be mixed accidentally. If both paths become visible later, the UI should make the choice explicit and explain that they are separate workflows.

These five scripts must not be merged into one tool during intake. Any future implementation must preserve their sequence and their tool boundaries unless Yazan explicitly approves a different product design.

## Per-Script Intake Classification

| Script | Intake classification | Likely future handling | Major risk groups | Product-scope notes | Reason |
|---|---|---|---|---|---|
| `5 Graphics/1 Driver Clean.ps1` | Yazan-approved intake exception for future source promotion | Scope + Provenance Design needed | downloads/artifacts/installers; driver install/profile/settings; AMD/Intel unsupported behavior; registry mutation; file mutation/cleanup; services/tasks/processes; reboot/firmware restart; Safe Mode; RunOnce; Default/Restore concerns | Uses broad GPU cleanup and DDU behavior across NVIDIA/AMD/Intel cleanup settings. Future BoostLab design must reconcile this with NVIDIA-only product scope and must not create a standalone DDU tool. | Downloads 7-Zip and DDU, configures DDU, writes RunOnce, changes BCD SafeBoot, restarts, and runs Display Driver Uninstaller. Yazan approved Driver Clean for intake despite DDU usage, but no DDU execution, download, artifact approval, or tool implementation is approved by this intake exception. |
| `5 Graphics/2 Driver Install Latest.ps1` | Implemented as controlled manual handoff only in Phase 93 | Auto remains blocked pending provenance/installer/driver/reboot approvals | downloads/artifacts/installers; driver install/profile/settings; NVIDIA-only GPU-specific behavior; AMD/Intel unsupported behavior | BoostLab exposes only manual handoff for the NVIDIA path. AMD and Intel branches remain disabled/not implemented. | NVIDIA branch queries NVIDIA driver API, downloads the latest NVIDIA installer to `%SystemRoot%\Temp\nvidiadriver.exe`, and launches it. BoostLab does not automate those operations in Phase 93. AMD branch downloads AMD installer; Intel branch opens Intel driver page. |
| `5 Graphics/4 Nvidia Settings.ps1` | Implemented as controlled manual handoff only in Phase 94 | Auto remains blocked pending 7-Zip/Profile Inspector/.nip/profile/registry/process/verification approvals | downloads/artifacts/installers; driver install/profile/settings; NVIDIA-only GPU-specific behavior; registry mutation; file mutation/cleanup; process execution; Default/Restore concerns | BoostLab exposes only manual handoff for Path B step 2. Automatic NVIDIA settings/profile behavior remains blocked. | Downloads and installs 7-Zip, downloads NVIDIA Profile Inspector, writes NVIDIA registry values, writes/imports `.nip` profile data, opens NVIDIA Control Panel, and has a Default branch that deletes or changes NVIDIA values. |
| `5 Graphics/5 Hdcp.ps1` | Implemented as controlled registry behavior in Phase 95 | Restore remains unavailable without selected captured-state restore flow | NVIDIA-only GPU-specific behavior; HKLM registry mutation; Default/Restore separation | Active HDCP behavior preserves source-defined `RMHdcpKeyglobZero` Apply/Default only after exact target discovery, NVIDIA-only validation, registry capture, and verification. | Writes `RMHdcpKeyglobZero` under NVIDIA display class registry instances with source-defined Apply/Default values; blocks non-NVIDIA or out-of-scope targets. |
| `5 Graphics/6 P0 State.ps1` | Implemented as controlled registry behavior in Phase 96 | Restore remains unavailable without selected captured-state restore flow | NVIDIA-only GPU-specific behavior; HKLM registry mutation; Default/Restore separation | Active P0 State behavior preserves source-defined `DisableDynamicPstate` Apply/Default only after exact target discovery, NVIDIA-only validation, registry capture, and verification. | Writes `DisableDynamicPstate` under NVIDIA display class registry instances with source-defined Apply/Default values; blocks non-NVIDIA or out-of-scope targets. |
| `5 Graphics/7 Msi Mode.ps1` | Intake accepted for future source promotion | Driver/Profile Design needed | driver install/profile/settings; registry mutation; Default/Restore concerns; AMD/Intel unsupported behavior | Current source targets all display devices through `Get-PnpDevice -Class Display`; future BoostLab must constrain or clearly reject non-NVIDIA GPU-specific behavior under product scope. | Writes `MSISupported` under each display device's interrupt-management registry path. This touches device/driver registry state and needs exact device targeting, capture, verification, and rollback policy. |
| `3 Setup/1 BitLocker.ps1` | Intake accepted for future source promotion | Security-sensitive Design needed | BitLocker/security-sensitive behavior; process/UI launch; Default/Restore concerns | Shared Windows security behavior is not blocked by product scope, but it is high-risk and security-sensitive. | Off branch calls `Disable-BitLocker` for protected or not fully decrypted volumes, opens BitLocker Control Panel, and runs `manage-bde -status`; On branch opens BitLocker Control Panel and runs status only. |

## Source-Order Reconciliation Plan

No files should be renamed or moved in this phase.

If accepted in a future source-promotion phase, the natural future destination paths would be:

| Intake path | Proposed future destination | Reconciliation issue |
|---|---|---|
| `intake/missing-ultimate-scripts/Ultimate/5 Graphics/1 Driver Clean.ps1` | `source-ultimate/5 Graphics/1 Driver Clean.ps1` | Conflicts with current Graphics slot 1. Yazan approved this script as an intake exception despite DDU usage, but source promotion still needs a separate phase and dedicated Driver Clean scope/provenance/safety design. |
| `intake/missing-ultimate-scripts/Ultimate/5 Graphics/2 Driver Install Latest.ps1` | `source-ultimate/5 Graphics/2 Driver Install Latest.ps1` | Conflicts with current Graphics slot 2 (`DirectX`). Needs separate source-promotion order decision. |
| `intake/missing-ultimate-scripts/Ultimate/5 Graphics/4 Nvidia Settings.ps1` | `source-ultimate/5 Graphics/4 Nvidia Settings.ps1` | Conflicts with current Graphics slot 4 (`Graphics Configuration Center`). Needs separate source-promotion order decision. |
| `intake/missing-ultimate-scripts/Ultimate/5 Graphics/5 Hdcp.ps1` | `source-ultimate/5 Graphics/5 Hdcp.ps1` | No current Graphics slot 5 file, but official catalog has only four active Graphics tools today. |
| `intake/missing-ultimate-scripts/Ultimate/5 Graphics/6 P0 State.ps1` | `source-ultimate/5 Graphics/6 P0 State.ps1` | Resolved through active Graphics order 5 controlled P0 State implementation; source mirror path remains the protected source reference. |
| `intake/missing-ultimate-scripts/Ultimate/5 Graphics/7 Msi Mode.ps1` | `source-ultimate/5 Graphics/7 Msi Mode.ps1` | No current Graphics slot 7 file, but official catalog has only four active Graphics tools today. |
| `intake/missing-ultimate-scripts/Ultimate/3 Setup/1 BitLocker.ps1` | `source-ultimate/3 Setup/1 BitLocker.ps1` | Conflicts with current Setup slot 1 (`Memory Compression`). Needs separate source-promotion order decision. |

A future promotion phase would need to decide whether these files keep their original Ultimate numbering in `source-ultimate/`, receive a documented source-order remap, or remain in a separate intake/reference area. That phase would also need to update:

* `BOOSTLAB_BLUEPRINT.md`
* `CODEX_INSTRUCTIONS.md`
* `config/Stages.psd1`
* module scaffolding and placeholder modules, if new active tools are approved
* capability metadata tests
* deleted-tool and source manifest validators
* deferred execution and readiness docs
* migration records only when a tool is actually implemented

## Phase 69 Non-Actions

No scripts were moved into `source-ultimate` in this phase.

No intake scripts were edited.

No `source-ultimate` files were modified.

No tool was implemented or enabled in this phase.

No tool card, module, placeholder, action, Default, Restore, production allowlist, artifact approval, installer approval, download approval, driver scope, AppX scope, service scope, scheduled task scope, process scope, cleanup scope, reboot scope, TrustedInstaller scope, or Safe Mode scope was approved in this phase.

Standalone DDU remains deleted/disallowed as an independent BoostLab tool. The Phase 70 decision only accepts `Driver Clean.ps1` as a missing Ultimate script candidate for future source promotion despite DDU usage.

Loudness EQ and NVME Faster Driver remain deleted.

## Recommended Next Phase

Recommended next phase: **Missing Scripts Source Promotion Decision**.

Phase 71 records that decision in `docs/missing-scripts-source-promotion-decision.md`. It recommends preserving original intake filenames in a future source-promotion mirror under `source-ultimate/_intake-promoted/Ultimate/` rather than renumbering existing approved source files.

Phase 72 completed that mirror copy for all seven candidates under `source-ultimate/_intake-promoted/Ultimate/`. The original intake files remain preserved for intake history. This source promotion is not implementation, catalog promotion, placeholder enablement, or production approval.

Future catalog/design phases must preserve Path B workflow metadata and keep standalone DDU, DDU execution, downloads, artifacts, and driver-cleaning behavior unapproved until explicitly approved.

Phase 73 records the NVIDIA App Path B catalog design in `docs/nvidia-path-b-catalog-design.md`. It documents Path A versus Path B, preserves the required five-step Path B order, and remains catalog-only with no tool enablement or production approval.

