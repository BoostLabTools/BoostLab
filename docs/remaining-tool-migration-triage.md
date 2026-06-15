# Remaining Tool Migration Triage

## Scope and Method

This began as a read-only migration audit of the 34 modules that were still placeholders after Phase 17. No Ultimate script was executed. Sources were matched by approved stage and order, then checked by full-text and PowerShell AST inspection. Lower-complexity and borderline sources were also reviewed manually. Phase 25 removes Loudness EQ from the product and from every future migration queue.

The categories below describe behavior present in the audited Ultimate sources, not behavior authorized for BoostLab. Self-elevation and console-only commands were ignored when deciding whether a source is open-only. A source is marked open-only only when its operational behavior does nothing except launch an approved interface. Loudness EQ is no longer an audited candidate because its catalog entry, placeholder module, and explicitly approved legacy source file were deleted in Phase 25.

Classification meanings:

* **Safe:** a focused future phase can preserve the source without requiring new high-impact infrastructure.
* **Medium:** potentially migratable, but needs a stronger tool-specific plan, confirmation, verification, state capture, or narrowly scoped process/service handling.
* **Deferred:** contains behavior that should not be migrated until the relevant heavy runtime, rollback, distribution, or safety decisions are approved.

## Product Scope Notes

Windows 11 is BoostLab's optimized target platform, with NVIDIA-only support for GPU-specific tooling.

Windows 10 optimization, performance, service, and settings-improvement branches, AMD GPU branches, and Intel GPU branches are currently outside scope unless Yazan explicitly expands scope later.

A Windows 10 host may run an approved preparation, refresh, migration, or transition tool when the tool's output and goal target Windows 11. This exception covers host compatibility for Windows 11 preparation; it does not make Windows 10 optimization branches supported.

If a source contains both supported and unsupported branches, future migration phases may keep the unsupported branches disabled, visual-only, or placeholder-only while implementing only the supported Windows 11 / NVIDIA path. That is a scope decision, not an accidental weakening.

If a tool is entirely outside the supported scope, it should remain a placeholder or disabled candidate with a clear reason until scope changes.

The intent is that unsupported branches remain disabled, visual-only, or not implemented unless Yazan later expands scope.

## A. Summary

* Active approved tools: **48**
* Implemented modules: **29**
* Placeholder modules: **19**
* Permanently deleted in Phase 25: **Loudness EQ**
* Missing module files: **0**
* Missing source mappings: **0**

The first migration pass is complete. The execution-focused follow-up plan for every remaining placeholder or refused tool now lives in `docs/deferred-tools-execution-plan.md`.

No existing implementation changed during Phase 25. The only catalog and source changes are the permanent Loudness EQ removal approved by Yazan.

### Important Catalog Mismatches

The current catalog describes several placeholders more softly than their Ultimate sources:

* `Start Menu Taskbar` exposes only `Open`, but the source has Clean and Default system-changing branches.
* `Edge Settings` exposes only `Open`, but the source changes policy, RunOnce, Active Setup, services, and performs a repair download.
* `Control Panel Settings` exposes only `Open`, but the source is a large Apply/Default optimization using services, security-sensitive policy, deletion, and TrustedInstaller.
* `Network Adapter Power Savings & Wake` was originally cataloged as `Open`, but its source performs broad HKLM adapter-registry changes. It has since been implemented under an approved migration record.

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

3. **Network Adapter Power Savings & Wake**
   * Applies or removes multiple power and wake values across every detected network adapter class key.
   * Explicit Default exists; adapter-specific unsupported values must be warnings rather than false failures.

4. **Timer Resolution Assistant**
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
* **Resizable BAR Assistant:** downloads and executes NVIDIA Inspector profiles, changes driver profile behavior, and includes firmware restart.
* **Services Optimizer:** broad service/security changes with TrustedInstaller, Safe Mode, RunOnce, restore-point, driver-related, deletion, and reboot behavior.
* **Defender Optimize Assistant:** Defender/security changes using TrustedInstaller, Safe Mode, RunOnce, service handling, and repeated reboots.

## C. Per-Tool Audit Table

| Tool | Stage | Module | Ultimate source and SHA-256 | Detected behavior | Class | Reason / warnings | Source Default | Approved inverse needed | Suggested phase |
|---|---|---|---|---|---|---|---|---|---|
| Reinstall | Refresh | `modules/Refresh/reinstall.psm1` | `source-ultimate/2 Refresh/1 Reinstall.ps1`<br>`137F519926293F37052817ACBBE20851652E5EA1B9F3B5B9F933AA1E22C2D9FB` | Downloads; installer/UI launch | Deferred | Downloads and launches Windows 10/11 media creation executables. | No | No; workflow has no meaningful inverse | Phase: Refresh Reinstall Workflow |
| Unattended | Refresh | `modules/Refresh/unattended.psm1` | `source-ultimate/2 Refresh/2 Unattended.ps1`<br>`0974CFCC4FFC4B21BF4EB62172C0C1C31FF32AB147878A4610FC19C95DF74338` | Windows Setup commands; file creation/deletion; installation-media UI | Implemented | Phase 33 preserves the Windows 11 artifact workflow with confirmation, removable-media validation, verified backups, ownership state, and structured verification. | No | No Default or Restore action is claimed | Phase 33 complete |
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
| Copilot | Windows | `modules/Windows/copilot.psm1` | `source-ultimate/6 Windows/8 Copilot.ps1`<br>`21B58212B241A6C0B74582063E3E74F746014E9137194B58B088CC6692F22A90` | HKCU/HKLM policy; broad process stop; AppX removal/re-registration | Deferred | Phase 18 refusal: registry-only behavior would weaken Ultimate; full behavior violates AppX and broad-process restrictions. | Yes | No | Phase: Copilot Package and Policy Workflow |
| Bloatware | Windows | `modules/Windows/bloatware.psm1` | `source-ultimate/6 Windows/11 Bloatware.ps1`<br>`36677A334B37025A7234F4320EE54EF50E9528D1814E2B3A463EEB564C5814F5` | AppX removal/re-registration; services; downloads; installers; security-related features; broad deletion | Deferred | Multi-mode removal and repair workflow with no single reversible state. | No single Default | Yes; Restore requires a captured package/feature inventory | Phase: Bloatware Analysis and Package Plan |
| GameBar | Windows | `modules/Windows/game-bar.psm1` | `source-ultimate/6 Windows/12 Gamebar.ps1`<br>`8C6703E68C251D63ADD81A87B7CB6C1F572A4CE55A1E092C33B9B444A9884E59` | HKCU/HKLM/HKCR; processes; services; AppX; installer/uninstaller; downloads; TrustedInstaller | Deferred | Phase 18 refusal: full behavior includes Gaming/Xbox removal, GameInput uninstall, repair downloads, and TrustedInstaller. | Yes | No | Phase: GameBar and Gaming Services Repair |
| Edge & WebView | Windows | `modules/Windows/edge-webview.psm1` | `source-ultimate/6 Windows/13 Edge & WebView.ps1`<br>`161ED9C99D437E45650369CB7E15D5737DED363712E647138F134B049AC7E691` | HKCU/HKLM; processes; service deletion; RunOnce; downloads; installers; broad file deletion | Deferred | Removes Edge/WebView files and services, then Default downloads repair installers. | Yes | No | Phase: Edge and WebView Removal/Repair |
| Notepad Settings | Windows | `modules/Windows/notepad-settings.psm1` | `source-ultimate/6 Windows/14 Notepad Settings.ps1`<br>`2086D75FAA560C9746B1FA2EDB29AE9A8364633FD6268DEEDBE7FB4720EA39FB` | Notepad process stop; mounted app settings hive; file write/delete | Implemented | Phase 32 preserves Apply and Default with explicit confirmation, a verified pre-change backup, scoped state capture, and structured verification. | Yes | No; no Restore action is claimed | Phase 32 complete |
| Control Panel Settings | Windows | `modules/Windows/control-panel-settings.psm1` | `source-ultimate/6 Windows/15 Control Panel Settings.ps1`<br>`B78F643D21069F14E7E766769FB1EE15AEF974ABDF3CA010FE808D9EC162FB0B` | HKCU/HKLM/HKCR; services; security policy; deletion; TrustedInstaller | Deferred | Nearly 3,000 lines of broad policy and settings behavior. Current `Open` metadata is inaccurate. | Yes | No | Phase: Control Panel Settings Decomposition |
| Network Adapter Power Savings & Wake | Windows | `modules/Windows/network-adapter-power-savings-wake.psm1` | `source-ultimate/6 Windows/19 Network Adapter Power Savings & Wake.ps1`<br>`1DAAC872ECB1C601FD165FD471BFA9B9137D895333FBFBC5ADE5427561D4BCEB` | Broad dynamic HKLM adapter registry | Medium | Writes/removes 14 adapter power/wake values per detected adapter. Current `Open` metadata is inaccurate. | Yes | No | Phase: Network Adapter Power and Wake |
| Write Cache Buffer Flushing | Windows | `modules/Windows/write-cache-buffer-flushing.psm1` | `source-ultimate/6 Windows/20 Write Cache Buffer Flushing.ps1`<br>`67D8CA0FECBFD9FCE7D2C81CE1713F1B08E83B729DC8FEC7B8C2E33806F9AD5D` | HKLM storage-device registry; destructive key deletion | Deferred | Apply writes one value, but Default deletes entire device `Disk` subkeys. Source also references the intentionally deleted NVME Faster Driver tool. | Yes, but unsafe | Yes; approve a value-only Default or captured-state Restore | Phase: Storage Write Cache Safety Review |
| Power Plan | Windows | `modules/Windows/power-plan.psm1` | `source-ultimate/6 Windows/21 Power Plan.ps1`<br>`97CD584B1713809466E372B70434F06FFABC10DE0C4C4F67AF4212B5892DAC56` | HKLM power policy; extensive `powercfg`; power-scheme deletion; UI launch | Deferred | Deletes all enumerated schemes, disables hibernation, and sets battery warnings/actions/levels to zero. Default cannot restore custom prior schemes. | Yes | Yes for true Restore; source Default only restores Windows schemes | Phase: Power Plan Capture, Apply, and Rollback |
| Cleanup | Windows | `modules/Windows/cleanup.psm1` | `source-ultimate/6 Windows/22 Cleanup.ps1`<br>`3419A995AD4483A145999B659268302F02BE982733DE831554ADA1C40F07CCAA` | Broad recursive file deletion | Deferred | Deletes user/system temp contents, `inetpub`, `PerfLogs`, `Windows.old`, and `DumpStack.log`; no rollback. | No | No practical inverse | Phase: Cleanup Inventory and Confirmation |
| MMAgent Assistant | Advanced | `modules/Advanced/mmagent-assistant.psm1` | `source-ultimate/8 Advanced/2 MMAgent Assistant.ps1`<br>`C7E6E7879B7B32E548607A5D30124CC327622E09E7BEF817D36E8BC095B64A79` | HKLM registry; MMAgent commands; read-only check | Medium | Focused but multi-setting system behavior. Source Default intentionally leaves MemoryCompression and PageCombining disabled, so “Default” must preserve that approved meaning. | Yes | No | Phase: MMAgent Analysis and Toggle |
| Resizable BAR Assistant | Advanced | `modules/Advanced/resizable-bar-assistant.psm1` | `source-ultimate/8 Advanced/3 Resizable BAR Assistant.ps1`<br>`E2E1D919B350FA5190DFD4FAF23F3AB51ED2A324155CAFF49CDE774B092FB443` | Download; driver profiles; external executable; firmware reboot | Deferred | Downloads NVIDIA Inspector, imports large profiles, and includes reboot-to-BIOS behavior. | Yes, driver whitelist | No | Phase: Resizable BAR Driver and Firmware Assistant |
| Services Optimizer | Advanced | `modules/Advanced/services-optimizer.psm1` | `source-ultimate/8 Advanced/5 Services Optimizer.ps1`<br>`386EEF403F48907E82C2E8E4BE5DFE509B0ED93CADBB5639B42D6326163EDB8F` | Broad services; HKLM; security; drivers; deletion; RunOnce; Safe Mode; TrustedInstaller; reboot | Deferred | Heavy multi-stage privileged workflow. Requires service-state capture, Safe Mode recovery, TrustedInstaller runtime, and rollback design. | Yes | No, but Restore should use captured pre-action service state | Phase: Services Optimizer Recovery Architecture |
| Timer Resolution Assistant | Advanced | `modules/Advanced/timer-resolution-assistant.psm1` | `source-ultimate/8 Advanced/6 Timer Resolution Assistant.ps1`<br>`883F7CF4E6179383DE02E44B94FFC8DAFD380246751F1B1D81CAB8800B1E8621` | Compiles executable; creates/starts/stops service; scoped file deletion; Task Manager launch | Medium | Narrowly scoped service, but production needs reviewed source provenance, deterministic compilation, service verification, and cleanup. | Yes | No | Phase: Timer Resolution Service Assistant |
| Defender Optimize Assistant | Advanced | `modules/Advanced/defender-optimize-assistant.psm1` | `source-ultimate/8 Advanced/7 Defender Optimize Assistant.ps1`<br>`512F12D805715E9232304ABE5BA400BE6B3965D63F77D3B39E4C304507BFB9B6` | Defender/security; services; drivers; deletion; RunOnce; Safe Mode; TrustedInstaller; reboot | Deferred | High-impact security workflow with repeated Safe Mode transitions and restarts. | Yes | No, but recovery must be independently verified | Phase: Defender Safe Mode Recovery Assistant |

## D. Implemented After Triage

### Device Manager Power Savings & Wake

Phase 26 implemented the source-defined Apply and Default registry behavior with strict ACPI/HID/PCI/USB target validation, explicit confirmation, idempotent value deletion, and read-only verification. See `docs/migrations/device-manager-power-savings-wake.md`.

### User Account Pictures Black

Phase 27 implemented the source-defined black-image and default-restore behavior with verified per-file backups, ownership tracking, explicit confirmation, unknown-file preservation, and hash-based verification. See `docs/migrations/user-account-pictures-black.md`.

### MMAgent Assistant

Phase 28 implemented the source-defined Check, Off, and Default behavior as an assistant with Action Plan confirmation, structured results, and verification. The approved BoostLab Default preserves the original source meaning where `MemoryCompression` and `PageCombining` remain disabled. See `docs/migrations/mmagent-assistant.md`.

### SMT / HT Assistant

Phase 29 implemented the source-defined `Off: Already Running` and `Off: Startup` workflows as an advanced assistant with Analyze, Action Plan confirmation, structured results, and affinity verification. The implementation preserves the source launcher stop list and temporary per-process scope without changing BIOS SMT/HT settings. See `docs/migrations/smt-ht-assistant.md`.

### Spectre / Meltdown Assistant

Phase 30 implemented the source-defined Disable and Enable (Default) registry behavior as a security-sensitive assistant with read-only Analyze, explicit Action Plan confirmation, structured results, idempotent Default handling, and independent verification for both mitigation values. See `docs/migrations/spectre-meltdown-assistant.md`.

### Notepad Settings

Phase 32 implemented the source-defined Apply and Default behavior with exact Notepad process and `settings.dat` scope, mounted-hive import, explicit confirmation, verified pre-change backup, state capture, and structured verification. See `docs/migrations/notepad-settings.md`.

### Unattended

Phase 33 implemented the source-defined Windows 11 `autounattend.xml` generation workflow with Analyze and confirmed Apply actions. It preserves the complete Ultimate XML payload, account substitution, temporary-file sequence, removable-media destination, and folder launch while adding verified backup and ownership state before any overwrite. Windows 10 and Windows 11 may host this Windows 11 preparation workflow; Windows 10 optimization branches remain unsupported. No Default or Restore action is claimed. See `docs/migrations/unattended.md`.

## E. Permanently Deleted Tools

### Loudness EQ

Yazan permanently removed Loudness EQ from the BoostLab product in Phase 25 on June 10, 2026. It is not a hidden tool, deferred heavy tool, or future migration candidate.

The approved deletion removed:

* Catalog id `loudness-eq`
* Placeholder module `modules/Windows/loudness-eq.psm1`
* Legacy source `source-ultimate/6 Windows/17 Loudness EQ.ps1`

The deleted legacy source had SHA-256 `2F11A145B3E035372AB023614662524159BDDFA122A3778D6FEE9824782416AE`. The source stopped and restarted audio services and wrote per-device HKLM enhancement data without a Default path. Loudness EQ must never be recreated directly, indirectly, under another name, or inside another tool.

## F. Refused Tools

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

1. **Timer Resolution Assistant**, after approving service creation, binary provenance, and cleanup expectations
2. **Write Cache Buffer Flushing**, after deciding whether Default preserves the unsafe full-key deletion or narrows to owned values only
3. **Edge Settings**, only after download provenance, service deletion, RunOnce recovery, and repair behavior are approved

Timer Resolution is the strongest remaining medium-risk candidate in this historical queue. Every listed item still requires a dedicated safety decision before implementation.

## Decisions Needed Before Future Phases

* Decide whether source alternatives such as Start Menu Layout `24H2` may be labeled `Default`.
* Decide whether known broad key deletion in Context Menu and Signout Wallpaper should be preserved or intentionally narrowed.
* Define a state-capture contract for file replacement and hardware-wide registry tools.
* Define package inventory and rollback requirements before any AppX migration.
* Define installer provenance, checksums, and distribution policy before downloads are implemented.
* Complete TrustedInstaller execution and recovery governance before GameBar, Control Panel Settings, Services Optimizer, or Defender.
* Define Safe Mode recovery and interrupted-run behavior before Services Optimizer or Defender.
* Require captured previous state before exposing `Restore` for driver, service, bloatware, power-plan, or system-file tools.
