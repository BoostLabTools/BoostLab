# Deferred Tools Execution Plan

## Purpose

This plan covers every active BoostLab tool that remains a placeholder after the first full migration pass.

These tools are not abandoned. They are blocked until the required foundation exists to preserve approved Ultimate behavior without weakening it, silently narrowing it, or bypassing current governance.

Current inventory at the time of this plan:

* Active approved tools: **48**
* Implemented tools: **29**
* Remaining placeholders: **19**
* Deleted tools that must never return: **Loudness EQ**, **NVME Faster Driver**

## Product Scope Context

Windows 11 is BoostLab's optimized target platform. NVIDIA is the only supported vendor scope for GPU-specific tooling.

Windows 10 optimization branches remain unsupported. A Windows 10 host may still be valid for approved Windows 11 preparation or migration workflows, but that exception does not convert Windows 10 optimization branches into supported migration targets.

AMD and Intel GPU-specific branches remain disabled, visual-only, or not implemented unless Yazan expands product scope later.

## Status Meanings

* `Placeholder`: module still uses the shared placeholder contract.
* `Refused`: direct implementation was explicitly rejected because it would violate current governance or weaken Ultimate behavior.
* `Deferred`: blocked until a required foundation is approved and implemented.

In practice, every tool in this document is both still a placeholder and currently blocked. Where a tool was explicitly reviewed in a dedicated phase and rejected, its status is recorded as `Refused`.

## Deferred / Refused Tools

| Tool id | Title | Stage | Ultimate source | Source SHA-256 | Current status | Main blocker category | Why direct implementation was refused or unsafe | Required foundation before implementation | Product-scope effect | Suggested future phase | Visual-only / disabled until ready |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `reinstall` | Reinstall | Refresh | `source-ultimate/2 Refresh/1 Reinstall.ps1` | `137F519926293F37052817ACBBE20851652E5EA1B9F3B5B9F933AA1E22C2D9FB` | Refused | Download provenance and installer execution policy | Downloads and launches Windows setup/media tools. No approved provenance policy or safe execution contract exists yet. | Download provenance and checksum/signature policy; installer execution policy; reboot/recovery workflow | Windows 10 host exception may apply only for Windows 11-targeted preparation, not Windows 10 optimization | `Refresh Reinstall Workflow` | Yes |
| `updates-drivers-block` | Updates Drivers Block | Refresh | `source-ultimate/2 Refresh/3 Updates Drivers Block.ps1` | `4D4EC652C5A7F78824F53B7DC7FD46DDA948F3716A7CD6FD102D6C678EE11991` | Refused | Reboot/recovery workflow | Mixes live policy changes with bootable-media scripts, nonstandard update endpoints, and reboot-capable flows. | Reboot/recovery workflow; download provenance policy; file/registry state capture and rollback | No GPU scope issue; Windows 10 optimization branches remain unsupported | `Update and Driver Policy Assistant` | Yes |
| `edge-settings` | Edge Settings | Setup | `source-ultimate/3 Setup/6 Edge Settings.ps1` | `342869157930ECF0869A07B4254CB8F174C63648CD329DB3914BAD291CD5FF28` | Refused | Download provenance and checksum/signature policy | Current catalog suggests an `Open`-style tool, but source changes policy, RunOnce, services, and downloads a repair installer. | Download provenance and checksum/signature policy; installer execution policy; service state capture and rollback; file/registry state capture and rollback | No scope exception | `Edge Policy and Repair Workflow` | Yes |
| `installers` | Installers | Installers | `source-ultimate/4 Installers/1 Installers.ps1` | `1065D64183457D4E7B28EA78DDE41525EC8F7C4A4BCA12D29B70D991141C0C67` | Refused | Installer execution policy | Downloads and launches 23 application installers with per-app post-install changes, shortcut cleanup, service removal, and policy/config edits. | Download provenance and checksum/signature policy; installer execution policy; service state capture and rollback; file/registry state capture and rollback | NVIDIA-only scope does not help because the blocker is multi-installer governance | `Approved Installer Framework` | Yes |
| `driver-install-debloat-settings` | Driver Install Debloat & Settings | Graphics | `source-ultimate/5 Graphics/1 Driver Install Debloat & Settings.ps1` | `E69EFF538E7CE6108233C525A2BB88BA2D549CE6954AE751BE7BED778271C26F` | Refused | Driver state capture and rollback | NVIDIA path alone downloads unpinned tools, debloats extracted driver contents, installs drivers, imports profiles, writes registry, deletes files, removes packages, and restarts. | Download provenance and checksum/signature policy; installer execution policy; driver state capture and rollback; reboot/recovery workflow; file/registry state capture and rollback | AMD and Intel branches must stay disabled; only NVIDIA could ever be considered later | `Graphics Driver Orchestrator` | Yes |
| `directx` | DirectX | Graphics | `source-ultimate/5 Graphics/2 DirectX.ps1` | `17051A2F0F7A0CF16BE525121720406E8F1630C94E5977A7CD4C18652A87EE05` | Refused | Download provenance and checksum/signature policy | Downloads unverified `7zip.exe` and `directx.exe`, installs/configures 7-Zip, extracts DirectX, and launches `DXSETUP.exe`. | Download provenance and checksum/signature policy; installer execution policy | No scope exception | `DirectX Installer` | Yes |
| `visual-cpp` | Visual C++ | Graphics | `source-ultimate/5 Graphics/3 C++.ps1` | `7ACB1F25ECFEEAD83FA389E2D0C1FEEF12232C4E9A740CB5DE64A326FFD38C09` | Refused | Download provenance and checksum/signature policy | Downloads and runs twelve redistributable executables from mutable third-party URLs with no signature, checksum, or installed-state validation. | Download provenance and checksum/signature policy; installer execution policy | No scope exception | `Visual C++ Runtime Installer` | Yes |
| `start-menu-taskbar` | Start Menu Taskbar | Windows | `source-ultimate/6 Windows/1 Start Menu Taskbar.ps1` | `88BEB0E8C41F7A32AAE6A0A6E184E87E678FB25BEDEB092C63F4BA98B8712E91` | Refused | File/registry state capture and rollback | Replaces `start2.bin`, deletes Quick Launch state, writes policy XML, and terminates Explorer without captured prior user state. | File/registry state capture and rollback; destructive cleanup policy | No scope exception | `Start and Taskbar State Migration` | Yes |
| `copilot` | Copilot | Windows | `source-ultimate/6 Windows/8 Copilot.ps1` | `21B58212B241A6C0B74582063E3E74F746014E9137194B58B088CC6692F22A90` | Refused | AppX/package inventory and restore framework | Registry-only behavior would weaken Ultimate; full source removes/re-registers AppX and stops a broad process set. | AppX/package inventory and restore framework; process-handling policy | No scope exception | `Copilot Package and Policy Workflow` | Yes |
| `bloatware` | Bloatware | Windows | `source-ultimate/6 Windows/11 Bloatware.ps1` | `36677A334B37025A7234F4320EE54EF50E9528D1814E2B3A463EEB564C5814F5` | Refused | AppX/package inventory and restore framework | Broad AppX removal/re-registration, services, downloads, installers, security-related features, and deletion with no single reversible baseline. | AppX/package inventory and restore framework; service state capture and rollback; destructive cleanup policy; download provenance and installer execution policies | No scope exception | `Bloatware Analysis and Package Plan` | Yes |
| `game-bar` | GameBar | Windows | `source-ultimate/6 Windows/12 Gamebar.ps1` | `8C6703E68C251D63ADD81A87B7CB6C1F572A4CE55A1E092C33B9B444A9884E59` | Refused | TrustedInstaller execution framework | Full source removes AppX, uninstalls GameInput, changes services/protocols, downloads repair tools, and uses TrustedInstaller. | AppX/package inventory and restore framework; TrustedInstaller execution framework; download provenance and installer execution policies; service state capture and rollback | No scope exception | `GameBar and Gaming Services Repair` | Yes |
| `edge-webview` | Edge & WebView | Windows | `source-ultimate/6 Windows/13 Edge & WebView.ps1` | `161ED9C99D437E45650369CB7E15D5737DED363712E647138F134B049AC7E691` | Refused | Destructive cleanup policy | Removes Edge/WebView files and services, changes RunOnce, and downloads repair installers. | Download provenance and checksum/signature policy; installer execution policy; service state capture and rollback; destructive cleanup policy; file/registry state capture and rollback | No scope exception | `Edge and WebView Removal/Repair` | Yes |
| `control-panel-settings` | Control Panel Settings | Windows | `source-ultimate/6 Windows/15 Control Panel Settings.ps1` | `B78F643D21069F14E7E766769FB1EE15AEF974ABDF3CA010FE808D9EC162FB0B` | Refused | TrustedInstaller execution framework | Very large optimization source with services, deletion, security-sensitive policy, and TrustedInstaller. Current `Open` metadata understates risk. | TrustedInstaller execution framework; service state capture and rollback; file/registry state capture and rollback; destructive cleanup policy | No scope exception | `Control Panel Settings Decomposition` | Yes |
| `write-cache-buffer-flushing` | Write Cache Buffer Flushing | Windows | `source-ultimate/6 Windows/20 Write Cache Buffer Flushing.ps1` | `67D8CA0FECBFD9FCE7D2C81CE1713F1B08E83B729DC8FEC7B8C2E33806F9AD5D` | Refused | File/registry state capture and rollback | Source `Default` deletes complete device `Disk` subkeys rather than only the value written by Apply, and references deleted NVME Faster Driver context. | File/registry state capture and rollback; destructive cleanup policy | No scope exception; NVME Faster Driver must remain deleted | `Storage Write Cache Safety Review` | Yes |
| `cleanup` | Cleanup | Windows | `source-ultimate/6 Windows/22 Cleanup.ps1` | `3419A995AD4483A145999B659268302F02BE982733DE831554ADA1C40F07CCAA` | Refused | Destructive cleanup policy | Recursively deletes temp data, `Windows.old`, `inetpub`, `PerfLogs`, and dumps with no approved rollback path. | Destructive cleanup policy; file/registry state capture and rollback | No scope exception | `Cleanup Inventory and Confirmation` | Yes |
| `resizable-bar-assistant` | Resizable BAR Assistant | Advanced | `source-ultimate/8 Advanced/3 Resizable BAR Assistant.ps1` | `E2E1D919B350FA5190DFD4FAF23F3AB51ED2A324155CAFF49CDE774B092FB443` | Refused | Driver state capture and rollback | NVIDIA-only in scope, but still downloads NVIDIA Inspector, imports driver profiles, and includes firmware restart. | Download provenance and checksum/signature policy; driver state capture and rollback; reboot/recovery workflow | AMD and Intel remain disabled; NVIDIA-only path could be revisited later | `Resizable BAR Driver and Firmware Assistant` | Yes |
| `services-optimizer` | Services Optimizer | Advanced | `source-ultimate/8 Advanced/5 Services Optimizer.ps1` | `386EEF403F48907E82C2E8E4BE5DFE509B0ED93CADBB5639B42D6326163EDB8F` | Refused | Safe Mode recovery/resume framework | Heavy multi-stage privileged workflow with Safe Mode, TrustedInstaller, RunOnce, service/security changes, deletion, and reboot behavior. | Safe Mode recovery/resume framework; TrustedInstaller execution framework; service state capture and rollback; reboot/recovery workflow | No scope exception | `Services Optimizer Recovery Architecture` | Yes |
| `timer-resolution-assistant` | Timer Resolution Assistant | Advanced | `source-ultimate/8 Advanced/6 Timer Resolution Assistant.ps1` | `883F7CF4E6179383DE02E44B94FFC8DAFD380246751F1B1D81CAB8800B1E8621` | Refused | Service state capture and rollback | Narrower than Services Optimizer, but still compiles a binary, creates/removes a service, and deletes scoped files without approved provenance or service rollback guarantees. | Service state capture and rollback; download provenance and checksum/signature policy for built artifacts; destructive cleanup policy | No scope exception | `Timer Resolution Service Assistant` | Yes |
| `defender-optimize-assistant` | Defender Optimize Assistant | Advanced | `source-ultimate/8 Advanced/7 Defender Optimize Assistant.ps1` | `512F12D805715E9232304ABE5BA400BE6B3965D63F77D3B39E4C304507BFB9B6` | Refused | Safe Mode recovery/resume framework | Security-sensitive workflow using TrustedInstaller, Safe Mode, RunOnce, service handling, deletion, and repeated reboots. | Safe Mode recovery/resume framework; TrustedInstaller execution framework; service state capture and rollback; reboot/recovery workflow | No scope exception | `Defender Safe Mode Recovery Assistant` | Yes |

## Foundation Groups

### Download provenance and checksum/signature policy

Needed when a tool downloads any executable, installer, archive, or helper.

Affected tools:

* `reinstall`
* `edge-settings`
* `installers`
* `driver-install-debloat-settings`
* `directx`
* `visual-cpp`
* `game-bar`
* `edge-webview`
* `resizable-bar-assistant`
* `timer-resolution-assistant`

### Installer execution policy

Needed when a tool launches MSI, EXE, setup, or repair packages and BoostLab must define allowed switches, visible/non-visible execution rules, exit-code handling, and post-install verification.

Affected tools:

* `reinstall`
* `edge-settings`
* `installers`
* `driver-install-debloat-settings`
* `directx`
* `visual-cpp`
* `game-bar`
* `edge-webview`

### AppX/package inventory and restore framework

Needed before any tool removes, re-registers, or repairs Store/AppX packages and before any Restore claim can be meaningful.

Affected tools:

* `copilot`
* `bloatware`
* `game-bar`

### TrustedInstaller execution framework

Needed for tools whose approved Ultimate source explicitly depends on TrustedInstaller-level execution.

Affected tools:

* `game-bar`
* `control-panel-settings`
* `services-optimizer`
* `defender-optimize-assistant`

### Safe Mode recovery/resume framework

Needed for multi-stage tools that change boot flow and must survive interruption or failed resumes.

Affected tools:

* `services-optimizer`
* `defender-optimize-assistant`

### Service state capture and rollback

Needed before changing or deleting services so BoostLab can prove what changed and restore a captured prior state where appropriate.

Affected tools:

* `edge-settings`
* `installers`
* `driver-install-debloat-settings`
* `bloatware`
* `game-bar`
* `edge-webview`
* `control-panel-settings`
* `services-optimizer`
* `timer-resolution-assistant`
* `defender-optimize-assistant`

### Driver state capture and rollback

Needed before driver installers, profile imports, vendor-service removals, or graphics-driver registry changes.

Affected tools:

* `driver-install-debloat-settings`
* `resizable-bar-assistant`

### File/registry state capture and rollback

Needed where Ultimate replaces user/system files, writes broad registry state, or deletes keys/values that cannot be reconstructed safely without a captured baseline.

Affected tools:

* `updates-drivers-block`
* `start-menu-taskbar`
* `edge-settings`
* `edge-webview`
* `write-cache-buffer-flushing`
* `control-panel-settings`

### Destructive cleanup policy

Needed for tools that remove files, folders, extracted components, package debris, or registry trees where “delete what Ultimate deleted” is not automatically safe enough for BoostLab.

Affected tools:

* `driver-install-debloat-settings`
* `edge-webview`
* `cleanup`
* `write-cache-buffer-flushing`
* `control-panel-settings`
* `bloatware`
* `timer-resolution-assistant`

### Reboot/recovery workflow

Needed when a tool can reboot, hand control to firmware or setup, or leave the machine mid-workflow.

Affected tools:

* `reinstall`
* `updates-drivers-block`
* `driver-install-debloat-settings`
* `resizable-bar-assistant`
* `services-optimizer`
* `defender-optimize-assistant`

## Recommended Foundation Roadmap

1. **Download provenance and checksum/signature policy**
   This unblocks the broadest set of deferred tools and prevents every future download phase from reinventing trust rules.
2. **Installer execution policy**
   This should define visible vs silent installs, switch allowlists, exit-code handling, temp-file ownership, and verification expectations.
3. **File/registry state capture and rollback**
   This is the baseline for any future `Default` narrowing or true `Restore` path on system-state tools.
4. **Service state capture and rollback**
   This is needed before any real service deletion, startup-type mutation, or “optimizer” workflow.
5. **Destructive cleanup policy**
   This should define deletion scope, ownership checks, exclusions, and when a tool must refuse broad cleanup instead of narrowing it silently.
6. **AppX/package inventory and restore framework**
   This is required for Copilot, Bloatware, and GameBar-class tools.
7. **Reboot/recovery workflow**
   This should cover preflight, confirmation, interrupted-run state, and post-restart continuation.
8. **Driver state capture and rollback**
   This is required before any NVIDIA driver orchestration or profile-import workflow can preserve Ultimate without becoming one-way.
9. **TrustedInstaller execution framework**
   The placeholder helper exists, but it still needs execution policy, visibility, logging, and recovery rules.
10. **Safe Mode recovery/resume framework**
    This is the last major blocker because only the heaviest security/service tools need it, but they cannot move safely without it.

## What This Means for Future Phases

* Refused tools are blocked, not abandoned.
* A future phase should pick one foundation at a time, implement that foundation, and then migrate only the tools unlocked by it.
* Visual-only or disabled cards are the correct state for these tools until their prerequisites exist.
* No future phase should “just do the safe part” of one of these tools when that would weaken the effective Ultimate behavior.

## First-Pass Completion State

The first migration pass established the runtime, confirmation, logging, state, verification, and assistant patterns needed for low- to medium-risk tools.

The remaining placeholders are concentrated in the heavy-governance categories above. The next project milestone is therefore foundation-building, not opportunistic tool migration.
