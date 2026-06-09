# Remaining Tool Migration Triage

## Scope and Method

This began as a read-only migration audit of the 34 modules that were still placeholders after Phase 17. No Ultimate script was executed. Sources were matched by approved stage and order, then checked by full-text and PowerShell AST inspection. Lower-complexity and borderline sources were also reviewed manually. Phase 25 removes Loudness EQ from the product and from every future migration queue.

The categories below describe behavior present in the audited Ultimate sources, not behavior authorized for BoostLab. Self-elevation and console-only commands were ignored when deciding whether a source is open-only. A source is marked open-only only when its operational behavior does nothing except launch an approved interface. Loudness EQ is no longer an audited candidate because its catalog entry, placeholder module, and explicitly approved legacy source file were deleted in Phase 25.

Classification meanings:

* **Safe:** a focused future phase can preserve the source without requiring new high-impact infrastructure.
* **Medium:** potentially migratable, but needs a stronger tool-specific plan, confirmation, verification, state capture, or narrowly scoped process/service handling.
* **Deferred:** contains behavior that should not be migrated until the relevant heavy runtime, rollback, distribution, or safety decisions are approved.

## A. Summary

* Active approved tools: **48**
* Implemented modules: **21**
* Placeholder modules: **27**
* Permanently deleted in Phase 25: **Loudness EQ**
* Missing module files: **0**
* Missing source mappings: **0**

No existing implementation changed during Phase 25. The only catalog and source changes are the permanent Loudness EQ removal approved by Yazan.

### Important Catalog Mismatches

The current catalog describes several placeholders more softly than their Ultimate sources:

* `Start Menu Taskbar` exposes only `Open`, but the source has Clean and Default system-changing branches.
* `Edge Settings` exposes only `Open`, but the source changes policy, RunOnce, Active Setup, services, and performs a repair download.
* `Notepad Settings` exposes only `Open`, but the source stops Notepad, edits its settings hive, and deletes `settings.dat` for Default.
* `Control Panel Settings` exposes only `Open`, but the source is a large Apply/Default optimization using services, security-sensitive policy, deletion, and TrustedInstaller.
* `Device Manager Power Savings & Wake` and `Network Adapter Power Savings & Wake` expose only `Open`, but their sources perform broad HKLM device-registry changes.

These mismatches are documented here rather than changed during this planning-only phase. Their actions and capabilities should be corrected as part of an approved implementation phase, after the intended BoostLab behavior is decided.

## B. Recommended Migration Queue

### Group 1: Safe / Next Candidates

1. **Theme Black**
   * Explicit Apply and Default behavior.
   * Reversible HKCU/HKLM theme values.
   * No downloads, services, AppX, TrustedInstaller, Safe Mode, or reboot.
   * Verification can read every imported value.

2. **Start Menu Layout**
   * Limited to four HKLM feature override values and one HKCU Start value.
   * No services, downloads, AppX, TrustedInstaller, Safe Mode, or reboot.
   * Before implementation, Yazan must approve whether the source's `24H2` branch is the intended BoostLab `Default`; the source does not call it Default.

### Group 2: Medium / Needs Stronger Phase Prompt

1. **Context Menu**
   * Reversible registry-focused behavior, but it modifies many HKCR/HKLM shell handlers.
   * Source Default deletes the complete shared `Shell Extensions\Blocked` key, which may remove unrelated entries. Preserve-or-correct behavior requires an explicit decision.

2. **Signout LockScreen Wallpaper Black**
   * Creates `C:\Windows\Black.jpg`, changes lock-screen and wallpaper values, refreshes desktop parameters, and deletes the generated file on Default.
   * Default deletes the full `PersonalizationCSP` key, so state capture or narrower approved behavior should be decided.

3. **User Account Pictures Black**
   * Backs up and overwrites system account-picture files.
   * Restore depends on the backup folder created by Apply; the runtime should verify backup completeness before changing images.

4. **Notepad Settings**
   * Stops Notepad, mounts its `settings.dat` registry hive, imports values, and unloads the hive.
   * Default deletes `settings.dat`, so this needs explicit file-change confirmation and verification.

5. **Device Manager Power Savings & Wake**
   * Applies or removes values across all connected ACPI, HID, PCI, and USB device registry trees.
   * Explicit Default exists, but dynamic device enumeration and value-level verification are required.

6. **Network Adapter Power Savings & Wake**
   * Applies or removes multiple power and wake values across every detected network adapter class key.
   * Explicit Default exists; adapter-specific unsupported values must be warnings rather than false failures.

7. **MMAgent Assistant**
   * Uses focused MMAgent commands plus one prefetch registry value.
   * Explicit Default and Check branches exist.
   * Must remain an assistant with analysis, command planning, verification, and warnings about delayed state initialization.

8. **SMT / HT Assistant**
   * Changes process affinity for a selected process or launches a selected executable with an affinity mask.
   * One branch stops a list of game launchers. There is no Default or restore branch.
   * Requires user-driven process selection and captured prior affinity if Restore is ever offered.

9. **Timer Resolution Assistant**
    * Compiles and installs a narrowly scoped custom Windows service, then starts/stops and removes it.
    * Explicit Default exists, but service creation, binary provenance, compilation, cleanup, and verification need a dedicated phase.

### Group 3: Deferred Heavy Tools

* **Reinstall:** downloads and launches Windows media creation tools.
* **Unattended:** builds installation media configuration, includes hardware requirement bypasses, and writes installation artifacts.
* **Updates Drivers Block:** includes multiple policy modes, bootable-media scripts, forced update endpoints, and reboot commands.
* **To BIOS:** immediately requests restart to firmware.
* **Edge Settings:** modifies policies, Active Setup, RunOnce, browser helper objects, and Edge services; Default downloads and launches an installer.
* **Installers:** large download/install workflow with application-specific service and policy changes.
* **Driver Install Debloat & Settings:** downloads tools, installs and modifies graphics drivers, removes components/services, changes driver registry state, and reboots.
* **DirectX:** downloads, extracts, and launches installers.
* **Visual C++:** downloads and runs multiple redistributable installers.
* **Start Menu Taskbar:** broad registry changes, Start layout file replacement/deletion, Quick Launch deletion, `start2.bin` replacement, and Explorer termination.
* **Copilot:** removes/re-registers Copilot AppX and stops a broad unrelated process set.
* **Bloatware:** broad AppX removal/re-registration, services, file deletion, downloads, and Windows feature repair behavior.
* **GameBar:** AppX removal/re-registration, GameInput uninstall, service/process handling, TrustedInstaller, downloads, and repair installers.
* **Edge & WebView:** broad file deletion, service deletion, RunOnce changes, downloads, and reinstall behavior.
* **Control Panel Settings:** very large policy set with services, security-sensitive changes, deletion, and TrustedInstaller.
* **Write Cache Buffer Flushing:** modifies storage-device registry state; source Default deletes complete `Disk` subkeys rather than only the value written by Apply.
* **Power Plan:** deletes all enumerated power schemes, disables hibernation, changes battery safety behavior, and cannot restore custom previous schemes.
* **Cleanup:** recursively deletes temporary data, `Windows.old`, `inetpub`, `PerfLogs`, and dump files without a restore path.
* **Spectre / Meltdown Assistant:** directly disables or enables CPU vulnerability mitigations.
* **Resizable BAR Assistant:** downloads and executes NVIDIA Inspector profiles, changes driver profile behavior, and includes firmware restart.
* **Services Optimizer:** broad service/security changes with TrustedInstaller, Safe Mode, RunOnce, restore-point, driver-related, deletion, and reboot behavior.
* **Defender Optimize Assistant:** Defender/security changes using TrustedInstaller, Safe Mode, RunOnce, service handling, and repeated reboots.

## C. Per-Tool Audit Table

| Tool | Stage | Module | Ultimate source and SHA-256 | Detected behavior | Class | Reason / warnings | Source Default | Approved inverse needed | Suggested phase |
|---|---|---|---|---|---|---|---|---|---|
| Reinstall | Refresh | `modules/Refresh/reinstall.psm1` | `source-ultimate/2 Refresh/1 Reinstall.ps1`<br>`137F519926293F37052817ACBBE20851652E5EA1B9F3B5B9F933AA1E22C2D9FB` | Downloads; installer/UI launch | Deferred | Downloads and launches Windows 10/11 media creation executables. | No | No; workflow has no meaningful inverse | Phase: Refresh Reinstall Workflow |
| Unattended | Refresh | `modules/Refresh/unattended.psm1` | `source-ultimate/2 Refresh/2 Unattended.ps1`<br>`0974CFCC4FFC4B21BF4EB62172C0C1C31FF32AB147878A4610FC19C95DF74338` | HKLM setup commands; file creation/deletion; installation-media UI | Deferred | Creates `autounattend.xml`, includes TPM/RAM/Secure Boot/CPU/storage bypasses, and writes selected installation media. | No | No; artifact generation needs Cancel/Delete semantics instead | Phase: Unattended Media Builder |
| Updates Drivers Block | Refresh | `modules/Refresh/updates-drivers-block.psm1` | `source-ultimate/2 Refresh/3 Updates Drivers Block.ps1`<br>`4D4EC652C5A7F78824F53B7DC7FD46DDA948F3716A7CD6FD102D6C678EE11991` | HKLM policy; file generation/move; UI launch; reboot | Deferred | Six distinct modes include live policy and bootable USB scripts. Some branches embed reboot commands and nonstandard update-server URLs. | Yes, Unblock branches | No for live policies; bootable-media rollback must be separately designed | Phase: Update and Driver Policy Assistant |
| To BIOS | Refresh | `modules/Refresh/to-bios.psm1` | `source-ultimate/2 Refresh/4 To Bios.ps1`<br>`A8371B42B235A6AC1F9661D96B430BEC0E4CAB6D9DE3CBD1461A02572220CA0C` | Reboot to firmware | Deferred | Executes `shutdown.exe /r /fw /t 0`; requires the established explicit reboot confirmation flow. | No | No | Phase: Firmware Restart Workflow |
| Edge Settings | Setup | `modules/Setup/edge-settings.psm1` | `source-ultimate/3 Setup/6 Edge Settings.ps1`<br>`342869157930ECF0869A07B4254CB8F174C63648CD329DB3914BAD291CD5FF28` | HKLM policy; process; service deletion; RunOnce; downloads; installer; registry deletion | Deferred | Not an open-only tool. Default downloads and launches an Edge installer. Current catalog actions/capabilities understate source behavior. | Yes | No | Phase: Edge Policy and Repair Workflow |
| Installers | Installers | `modules/Installers/installers.psm1` | `source-ultimate/4 Installers/1 Installers.ps1`<br>`1065D64183457D4E7B28EA78DDE41525EC8F7C4A4BCA12D29B70D991141C0C67` | Downloads; installers; HKLM policies; processes; services; file changes | Deferred | Large multi-application installer with application-specific post-install changes and uninstalls. | No global Default | No; each package needs independent state and uninstall policy | Phase: Approved Installer Framework |
| Driver Install Debloat & Settings | Graphics | `modules/Graphics/driver-install-debloat-settings.psm1` | `source-ultimate/5 Graphics/1 Driver Install Debloat & Settings.ps1`<br>`E69EFF538E7CE6108233C525A2BB88BA2D549CE6954AE751BE7BED778271C26F` | Downloads; installers; drivers; AppX; HKCU/HKLM; services; processes; RunOnce; file deletion; reboot | Deferred | Vendor-specific driver extraction/install/debloat, service removal, profile import, component deletion, and restart. | No overall Default | Yes; `Restore` requires captured pre-migration driver state | Phase: Graphics Driver Orchestrator |
| DirectX | Graphics | `modules/Graphics/directx.psm1` | `source-ultimate/5 Graphics/2 DirectX.ps1`<br>`17051A2F0F7A0CF16BE525121720406E8F1630C94E5977A7CD4C18652A87EE05` | Downloads; extraction; installers | Deferred | Downloads 7-Zip and DirectX packages, then launches `DXSETUP.exe`. | No | No | Phase: DirectX Installer |
| Visual C++ | Graphics | `modules/Graphics/visual-cpp.psm1` | `source-ultimate/5 Graphics/3 C++.ps1`<br>`7ACB1F25ECFEEAD83FA389E2D0C1FEEF12232C4E9A740CB5DE64A326FFD38C09` | Downloads; installers | Deferred | Downloads and installs twelve x86/x64 redistributables using version-specific switches. | No | No | Phase: Visual C++ Runtime Installer |
| Start Menu Taskbar | Windows | `modules/Windows/start-menu-taskbar.psm1` | `source-ultimate/6 Windows/1 Start Menu Taskbar.ps1`<br>`88BEB0E8C41F7A32AAE6A0A6E184E87E678FB25BEDEB092C63F4BA98B8712E91` | HKCU/HKLM; process stop; file write/copy/delete | Deferred | Deletes Quick Launch and Start layout state, replaces `start2.bin`, writes policy XML, and terminates Explorer. Current `Open` metadata is inaccurate. | Yes | No, but previous user layout is not captured | Phase: Start and Taskbar State Migration |
| Start Menu Layout | Windows | `modules/Windows/start-menu-layout.psm1` | `source-ultimate/6 Windows/2 Start Menu Layout.ps1`<br>`81C1298D7C9E112DB910C4398CD94E4B70ECD97ED3B185CF2FD2B8A380E069E8` | HKCU/HKLM registry | Safe | Four feature overrides plus `AllAppsViewMode`; no process/service/download/reboot behavior. Source choices are 25H2 and 24H2, not Apply and Default. | No explicit Default | Yes; approve mapping of `Default` to the 24H2 branch or rename the action | Phase: Start Menu Layout Toggle |
| Context Menu | Windows | `modules/Windows/context-menu.psm1` | `source-ultimate/6 Windows/3 Context Menu.ps1`<br>`33DA36782CF6416A2FAE98829ADF0913B0E54DC53DE454AB0C5210A79754B6F2` | HKCU/HKLM/HKCR registry; temporary `.reg` file | Medium | Reversible in intent, but touches many shell handlers. Default deletes the complete shared `Shell Extensions\Blocked` key and could remove unrelated entries. | Yes | No, but collateral-key behavior needs approval or state capture | Phase: Context Menu Policy Toggle |
| Theme Black | Windows | `modules/Windows/theme-black.psm1` | `source-ultimate/6 Windows/4 Theme Black.ps1`<br>`C7FAEA241747065A9B752D989C5D0EA740E1525F442ABDDFFF3320766A005B2F` | HKCU/HKLM registry; temporary `.reg` file | Safe | Focused theme, transparency, accent, DWM, and background values with an explicit Default branch. | Yes | No | Phase: Theme Black Toggle |
| Signout LockScreen Wallpaper Black | Windows | `modules/Windows/signout-lockscreen-wallpaper-black.psm1` | `source-ultimate/6 Windows/5 Signout Lockscreen Wallpaper Black.ps1`<br>`C5A3E791BB85EE166397748D95B0BD4725063B55DC50CAEA805DC212E485C64C` | HKCU/HKLM; generated image; scoped file deletion; UI refresh | Medium | Creates/deletes `C:\Windows\Black.jpg`. Default removes the complete `PersonalizationCSP` key rather than only owned values. | Yes | No, but previous wallpaper/CSP state should be captured if behavior is narrowed | Phase: Black Wallpaper and Lock Screen |
| User Account Pictures Black | Windows | `modules/Windows/user-account-pictures-black.psm1` | `source-ultimate/6 Windows/6 User Account Pictures Black.ps1`<br>`8B978374BC9D5AE51858FC71BE02D0DFFAE29AADFEFAF8662D8654D735443710` | System-file backup, overwrite, and restore | Medium | Overwrites all PNG/BMP account-picture assets. Restore relies on a source-created backup and does not verify its integrity. | Yes, backup restore | No; Restore must require a valid captured backup | Phase: User Picture Backup and Blackout |
| Copilot | Windows | `modules/Windows/copilot.psm1` | `source-ultimate/6 Windows/8 Copilot.ps1`<br>`21B58212B241A6C0B74582063E3E74F746014E9137194B58B088CC6692F22A90` | HKCU/HKLM policy; broad process stop; AppX removal/re-registration | Deferred | Phase 18 refusal: registry-only behavior would weaken Ultimate; full behavior violates AppX and broad-process restrictions. | Yes | No | Phase: Copilot Package and Policy Workflow |
| Bloatware | Windows | `modules/Windows/bloatware.psm1` | `source-ultimate/6 Windows/11 Bloatware.ps1`<br>`36677A334B37025A7234F4320EE54EF50E9528D1814E2B3A463EEB564C5814F5` | AppX removal/re-registration; services; downloads; installers; security-related features; broad deletion | Deferred | Multi-mode removal and repair workflow with no single reversible state. | No single Default | Yes; Restore requires a captured package/feature inventory | Phase: Bloatware Analysis and Package Plan |
| GameBar | Windows | `modules/Windows/game-bar.psm1` | `source-ultimate/6 Windows/12 Gamebar.ps1`<br>`8C6703E68C251D63ADD81A87B7CB6C1F572A4CE55A1E092C33B9B444A9884E59` | HKCU/HKLM/HKCR; processes; services; AppX; installer/uninstaller; downloads; TrustedInstaller | Deferred | Phase 18 refusal: full behavior includes Gaming/Xbox removal, GameInput uninstall, repair downloads, and TrustedInstaller. | Yes | No | Phase: GameBar and Gaming Services Repair |
| Edge & WebView | Windows | `modules/Windows/edge-webview.psm1` | `source-ultimate/6 Windows/13 Edge & WebView.ps1`<br>`161ED9C99D437E45650369CB7E15D5737DED363712E647138F134B049AC7E691` | HKCU/HKLM; processes; service deletion; RunOnce; downloads; installers; broad file deletion | Deferred | Removes Edge/WebView files and services, then Default downloads repair installers. | Yes | No | Phase: Edge and WebView Removal/Repair |
| Notepad Settings | Windows | `modules/Windows/notepad-settings.psm1` | `source-ultimate/6 Windows/14 Notepad Settings.ps1`<br>`2086D75FAA560C9746B1FA2EDB29AE9A8364633FD6268DEEDBE7FB4720EA39FB` | Notepad process stop; mounted app settings hive; file write/delete | Medium | Default deletes Notepad `settings.dat`. Current `Open` metadata is inaccurate. | Yes | No | Phase: Notepad Settings State |
| Control Panel Settings | Windows | `modules/Windows/control-panel-settings.psm1` | `source-ultimate/6 Windows/15 Control Panel Settings.ps1`<br>`B78F643D21069F14E7E766769FB1EE15AEF974ABDF3CA010FE808D9EC162FB0B` | HKCU/HKLM/HKCR; services; security policy; deletion; TrustedInstaller | Deferred | Nearly 3,000 lines of broad policy and settings behavior. Current `Open` metadata is inaccurate. | Yes | No | Phase: Control Panel Settings Decomposition |
| Device Manager Power Savings & Wake | Windows | `modules/Windows/device-manager-power-savings-wake.psm1` | `source-ultimate/6 Windows/18 Device Manager Power Savings & Wake.ps1`<br>`FB543A5C6BD8F2FBEA5CD3069FD72DCDCCAB847D9E4753FD33BB0909843D209F` | Broad dynamic HKLM device registry | Medium | Writes/removes values for every ACPI, HID, PCI, and USB device. Current `Open` metadata is inaccurate. | Yes | No | Phase: Device Power and Wake Policy |
| Network Adapter Power Savings & Wake | Windows | `modules/Windows/network-adapter-power-savings-wake.psm1` | `source-ultimate/6 Windows/19 Network Adapter Power Savings & Wake.ps1`<br>`1DAAC872ECB1C601FD165FD471BFA9B9137D895333FBFBC5ADE5427561D4BCEB` | Broad dynamic HKLM adapter registry | Medium | Writes/removes 14 adapter power/wake values per detected adapter. Current `Open` metadata is inaccurate. | Yes | No | Phase: Network Adapter Power and Wake |
| Write Cache Buffer Flushing | Windows | `modules/Windows/write-cache-buffer-flushing.psm1` | `source-ultimate/6 Windows/20 Write Cache Buffer Flushing.ps1`<br>`67D8CA0FECBFD9FCE7D2C81CE1713F1B08E83B729DC8FEC7B8C2E33806F9AD5D` | HKLM storage-device registry; destructive key deletion | Deferred | Apply writes one value, but Default deletes entire device `Disk` subkeys. Source also references the intentionally deleted NVME Faster Driver tool. | Yes, but unsafe | Yes; approve a value-only Default or captured-state Restore | Phase: Storage Write Cache Safety Review |
| Power Plan | Windows | `modules/Windows/power-plan.psm1` | `source-ultimate/6 Windows/21 Power Plan.ps1`<br>`97CD584B1713809466E372B70434F06FFABC10DE0C4C4F67AF4212B5892DAC56` | HKLM power policy; extensive `powercfg`; power-scheme deletion; UI launch | Deferred | Deletes all enumerated schemes, disables hibernation, and sets battery warnings/actions/levels to zero. Default cannot restore custom prior schemes. | Yes | Yes for true Restore; source Default only restores Windows schemes | Phase: Power Plan Capture, Apply, and Rollback |
| Cleanup | Windows | `modules/Windows/cleanup.psm1` | `source-ultimate/6 Windows/22 Cleanup.ps1`<br>`3419A995AD4483A145999B659268302F02BE982733DE831554ADA1C40F07CCAA` | Broad recursive file deletion | Deferred | Deletes user/system temp contents, `inetpub`, `PerfLogs`, `Windows.old`, and `DumpStack.log`; no rollback. | No | No practical inverse | Phase: Cleanup Inventory and Confirmation |
| Spectre / Meltdown Assistant | Advanced | `modules/Advanced/spectre-meltdown-assistant.psm1` | `source-ultimate/8 Advanced/1 Spectre  Meltdown Assistant.ps1`<br>`3989B93BC4B3367B1ED0CF831C93DA6C2E87C556D945854FEE4ECA5D4C66AB50` | HKLM security mitigation registry | Deferred | Directly disables CPU vulnerability mitigations. Must remain a high-risk assistant with explicit security impact analysis. | Yes | No | Phase: Spectre/Meltdown Security Assistant |
| MMAgent Assistant | Advanced | `modules/Advanced/mmagent-assistant.psm1` | `source-ultimate/8 Advanced/2 MMAgent Assistant.ps1`<br>`C7E6E7879B7B32E548607A5D30124CC327622E09E7BEF817D36E8BC095B64A79` | HKLM registry; MMAgent commands; read-only check | Medium | Focused but multi-setting system behavior. Source Default intentionally leaves MemoryCompression and PageCombining disabled, so “Default” must preserve that approved meaning. | Yes | No | Phase: MMAgent Analysis and Toggle |
| Resizable BAR Assistant | Advanced | `modules/Advanced/resizable-bar-assistant.psm1` | `source-ultimate/8 Advanced/3 Resizable BAR Assistant.ps1`<br>`E2E1D919B350FA5190DFD4FAF23F3AB51ED2A324155CAFF49CDE774B092FB443` | Download; driver profiles; external executable; firmware reboot | Deferred | Downloads NVIDIA Inspector, imports large profiles, and includes reboot-to-BIOS behavior. | Yes, driver whitelist | No | Phase: Resizable BAR Driver and Firmware Assistant |
| SMT / HT Assistant | Advanced | `modules/Advanced/smt-ht-assistant.psm1` | `source-ultimate/8 Advanced/4 SMT  HT Assistant.ps1`<br>`5D53BF2A9A589ECB14D9F8F9048FF4830D2E6F4DEE7E4B54BA6B6B6F77F004FE` | Process analysis; process affinity; selected executable launch; launcher process stops | Medium | Interactive process/file selection and affinity calculation. No Default or restore behavior. | No | Yes if Restore is introduced; capture prior affinity | Phase: SMT/HT Process Affinity Assistant |
| Services Optimizer | Advanced | `modules/Advanced/services-optimizer.psm1` | `source-ultimate/8 Advanced/5 Services Optimizer.ps1`<br>`386EEF403F48907E82C2E8E4BE5DFE509B0ED93CADBB5639B42D6326163EDB8F` | Broad services; HKLM; security; drivers; deletion; RunOnce; Safe Mode; TrustedInstaller; reboot | Deferred | Heavy multi-stage privileged workflow. Requires service-state capture, Safe Mode recovery, TrustedInstaller runtime, and rollback design. | Yes | No, but Restore should use captured pre-action service state | Phase: Services Optimizer Recovery Architecture |
| Timer Resolution Assistant | Advanced | `modules/Advanced/timer-resolution-assistant.psm1` | `source-ultimate/8 Advanced/6 Timer Resolution Assistant.ps1`<br>`883F7CF4E6179383DE02E44B94FFC8DAFD380246751F1B1D81CAB8800B1E8621` | Compiles executable; creates/starts/stops service; scoped file deletion; Task Manager launch | Medium | Narrowly scoped service, but production needs reviewed source provenance, deterministic compilation, service verification, and cleanup. | Yes | No | Phase: Timer Resolution Service Assistant |
| Defender Optimize Assistant | Advanced | `modules/Advanced/defender-optimize-assistant.psm1` | `source-ultimate/8 Advanced/7 Defender Optimize Assistant.ps1`<br>`512F12D805715E9232304ABE5BA400BE6B3965D63F77D3B39E4C304507BFB9B6` | Defender/security; services; drivers; deletion; RunOnce; Safe Mode; TrustedInstaller; reboot | Deferred | High-impact security workflow with repeated Safe Mode transitions and restarts. | Yes | No, but recovery must be independently verified | Phase: Defender Safe Mode Recovery Assistant |

## D. Permanently Deleted Tools

### Loudness EQ

Yazan permanently removed Loudness EQ from the BoostLab product in Phase 25 on June 10, 2026. It is not a hidden tool, deferred heavy tool, or future migration candidate.

The approved deletion removed:

* Catalog id `loudness-eq`
* Placeholder module `modules/Windows/loudness-eq.psm1`
* Legacy source `source-ultimate/6 Windows/17 Loudness EQ.ps1`

The deleted legacy source had SHA-256 `2F11A145B3E035372AB023614662524159BDDFA122A3778D6FEE9824782416AE`. The source stopped and restarted audio services and wrote per-device HKLM enhancement data without a Default path. Loudness EQ must never be recreated directly, indirectly, under another name, or inside another tool.

## E. Refused Tools

### GameBar

GameBar was refused after inspecting `source-ultimate/6 Windows/12 Gamebar.ps1`.

The complete source:

* Stops GameBar, Gaming Services, and GameInput-related processes.
* Removes Gaming and Xbox AppX packages.
* Uninstalls Microsoft GameInput.
* Changes registry and protocol-handler state.
* Uses TrustedInstaller for GameBar Presence Writer activation.
* Re-registers Gaming, Xbox, and Store AppX packages during Default.
* Downloads and executes Edge WebView and GameBar repair tools.

Implementing only the registry values would not preserve the effective Ultimate behavior. Implementing the full source requires capabilities explicitly excluded from the refused phase.

### Copilot

Copilot was refused after inspecting `source-ultimate/6 Windows/8 Copilot.ps1`.

The complete source:

* Stops a broad process list including Edge, OneDrive, Search, GameBar, Store, and Widgets processes.
* Removes the Copilot AppX package.
* Sets HKCU and HKLM Copilot policies.
* Re-registers the Copilot AppX package during Default.

A policy-only implementation would weaken Ultimate behavior. The full source requires AppX and broad-process capabilities that were explicitly excluded.

## Recommended Next Five

In recommended order:

1. **Theme Black**
2. **Start Menu Layout**, after approving the `24H2`-to-`Default` action mapping
3. **Context Menu**, after deciding how to avoid or preserve deletion of the shared Blocked key
4. **Signout LockScreen Wallpaper Black**, with scoped state capture for existing CSP values and wallpaper
5. **Network Adapter Power Savings & Wake**, with adapter-aware verification and unsupported-value warnings

The first two are Group 1. Items three through five are the lowest-complexity Group 2 candidates, not unconditional safe migrations.

## Decisions Needed Before Future Phases

* Decide whether source alternatives such as Start Menu Layout `24H2` may be labeled `Default`.
* Decide whether known broad key deletion in Context Menu and Signout Wallpaper should be preserved or intentionally narrowed.
* Define a state-capture contract for file replacement and hardware-wide registry tools.
* Define package inventory and rollback requirements before any AppX migration.
* Define installer provenance, checksums, and distribution policy before downloads are implemented.
* Complete TrustedInstaller execution and recovery governance before GameBar, Control Panel Settings, Services Optimizer, or Defender.
* Define Safe Mode recovery and interrupted-run behavior before Services Optimizer or Defender.
* Require captured previous state before exposing `Restore` for driver, service, bloatware, power-plan, or system-file tools.
