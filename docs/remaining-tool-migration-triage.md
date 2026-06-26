# Remaining Tool Migration Triage

## Scope and Method

This began as a read-only migration audit of the 34 modules that were still placeholders after Phase 17. No Ultimate script was executed. Sources were matched by approved stage and order, then checked by full-text and PowerShell AST inspection. Lower-complexity and borderline sources were also reviewed manually. Phase 25 removes Loudness EQ from the product and from every future migration queue.

The categories below describe behavior present in the audited Ultimate sources, not behavior authorized for BoostLab. Self-elevation and console-only commands were ignored when deciding whether a source is open-only. A source is marked open-only only when its operational behavior does nothing except launch an approved interface. Loudness EQ is no longer an audited candidate because its catalog entry, placeholder module, and explicitly approved legacy source file were deleted in Phase 25.

Classification meanings:

* **Safe:** a focused future phase can preserve the source without requiring new high-impact infrastructure.
* **Medium:** potentially migratable, but needs a stronger tool-specific plan, confirmation, verification, state capture, or narrowly scoped process/service handling.
* **Deferred:** contains behavior that should not be migrated until the relevant heavy runtime, rollback, distribution, or safety decisions are approved.

## Product Scope Notes

Windows 11 is BoostLab's preferred supported product target, with NVIDIA-only support for GPU-specific tooling.

Product scope is branch-level scope, not a blanket host-OS or hardware-vendor block.

If an approved Ultimate source applies the same behavior to Windows 10 and Windows 11 without an explicit Windows 10-only branch or option, that shared Windows behavior may be preserved. A Windows 10 host must not be blocked merely because the preferred supported product target is Windows 11.

Explicit Windows 10-only optimization, performance, service, and settings-improvement branches, AMD GPU branches, and Intel GPU branches are currently outside scope unless Yazan explicitly expands scope later.

A Windows 10 host may also run an approved preparation, refresh, migration, or transition tool when the tool's output and goal target Windows 11. This exception covers host compatibility for Windows 11 preparation; it does not make Windows 10-only optimization branches supported.

If a source contains both supported and unsupported branches, future migration phases may keep the unsupported branches disabled, visual-only, or placeholder-only while implementing only the supported shared Windows / Windows 11 / NVIDIA path. That is a scope decision, not an accidental weakening.

GPU-neutral behavior and NVIDIA-specific behavior may be preserved when otherwise approved. Explicit AMD/Intel GPU branches remain unsupported.

If a tool is entirely outside the supported scope, it should remain a placeholder or disabled candidate with a clear reason until scope changes.

The intent is that unsupported branches remain disabled, visual-only, or not implemented unless Yazan later expands scope.

## A. Summary

* Active approved tools: **48**
* Implemented modules: **30**
* Placeholder modules: **18**
* Permanently deleted in Phase 25: **Loudness EQ**
* Missing module files: **0**
* Missing source mappings: **0**

The first migration pass is complete. The execution-focused follow-up plan for every remaining placeholder or refused tool now lives in `docs/deferred-tools-execution-plan.md`.

No existing implementation changed during Phase 25. The only catalog and source changes are the permanent Loudness EQ removal approved by Yazan.

### Important Catalog Mismatches

The current catalog describes several placeholders more softly than their Ultimate sources:

* `Start Menu Taskbar` exposes only `Open`, but the source has Clean and Default system-changing branches.
* `Edge Settings` previously exposed only `Open`, but Phase 118 implements the source-equivalent controlled workflow after Yazan approved full-source near parity.
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
* **Updates Drivers Block:** Phase 112 supersedes Phase 102 final scope. The tool now implements only the Yazan-selected Driver Updates Block Bootable USB branch; Unblock, broad Windows Updates, custom update-server URL, live host registry block/unblock, external-process, and host reboot behavior remain blocked.
* **To BIOS:** immediately requests restart to firmware.
* **Edge Settings:** Phase 118 implements the full source-equivalent controlled workflow with confirmation and test-safe mechanics; Restore remains unavailable without a future selected captured-state restore contract.
* **Installers:** large download/install workflow with application-specific service and policy changes.
* **Driver Install Debloat & Settings:** downloads tools, installs and modifies graphics drivers, removes components/services, changes driver registry state, and reboots.
* **DirectX:** Phase 129 implements the source-equivalent controlled runtime
  with explicit confirmation while keeping the source-defined author-hosted
  artifact URLs classified as `NeedsBoostLabMirror`.
* **Visual C++:** Phase 130 implements the source-equivalent controlled
  runtime with explicit confirmation and test-safe executor injection. The
  twelve source-defined redistributable URLs remain unchanged and classified as
  author-hosted `NeedsBoostLabMirror` entries; no artifact provenance or mirror
  approval is added.
* **Visual C++:** downloads and runs multiple redistributable installers.
* **Start Menu Taskbar:** broad registry changes, Start layout file replacement/deletion, Quick Launch deletion, `start2.bin` replacement, and Explorer termination.
* **Copilot:** removes/re-registers Copilot AppX and stops a broad unrelated process set.
* **Bloatware:** broad AppX removal/re-registration, services, file deletion, downloads, and Windows feature repair behavior.
* **GameBar:** AppX removal/re-registration, GameInput uninstall, service/process handling, TrustedInstaller, downloads, and repair installers.
* **Edge & WebView:** broad file deletion, service deletion, RunOnce changes, downloads, and reinstall behavior.
* **Control Panel Settings:** very large policy set with services, security-sensitive changes, deletion, and TrustedInstaller.
* **Power Plan:** deletes all enumerated power schemes, disables hibernation, changes battery safety behavior, and cannot restore custom previous schemes.
* **Cleanup:** recursively deletes temporary data, `Windows.old`, `inetpub`, `PerfLogs`, and dump files without a restore path.
* **Defender Optimize Assistant:** Defender/security changes using TrustedInstaller, Safe Mode, RunOnce, service handling, and repeated reboots.

## C. Per-Tool Audit Table

| Tool | Stage | Module | Ultimate source and SHA-256 | Detected behavior | Class | Reason / warnings | Source Default | Approved inverse needed | Suggested phase |
|---|---|---|---|---|---|---|---|---|---|
| Reinstall | Refresh | `modules/Refresh/reinstall.psm1` | `source-ultimate/2 Refresh/1 Reinstall.ps1`<br>`64F76A856E4CC57BEE34C6DEA86F2B7ADC432B01A3FA4AEB5C2A650B9AE9A477` | Downloads; installer/UI launch | Deferred | Downloads and launches Windows 10/11 media creation executables. | No | No; workflow has no meaningful inverse | Phase: Refresh Reinstall Workflow |
| Unattended | Refresh | `modules/Refresh/unattended.psm1` | `source-ultimate/2 Refresh/2 Unattended.ps1`<br>`8A010A0B88860C88C4109A37BE21B03BA5C5686333D5B4A1C30F40C2FEE1D3DD` | Windows Setup commands; file creation/deletion; installation-media UI | Implemented | Phase 33 preserves the Windows 11 artifact workflow with confirmation, removable-media validation, verified backups, ownership state, and structured verification. | No | No Default or Restore action is claimed | Phase 33 complete |
| Updates Drivers Block | Refresh | `modules/Refresh/updates-drivers-block.psm1` | `source-ultimate/2 Refresh/3 Updates Drivers Block.ps1`<br>`D18878A8856096913643F7619917CAE688A19368A34792D94F3CC53BE45B0367` | HKLM policy; file generation/move; UI launch; reboot | Implemented USB-only final scope; broader/live branches blocked | Phase 112 implements only the Yazan-selected Driver Updates Block Bootable USB branch by writing the selected USB `setupcomplete.cmd` after file state capture. Live host registry block/unblock, Unblock/Default, broad Windows Updates, custom update-server URL, external-process, and host reboot behavior remain blocked. | No; Yazan final scope excludes Unblock/Default | Restore requires selected captured USB file state and is not Unblock | Phase 112 complete as Yazan final exception for USB-only Driver Updates scope |
| To BIOS | Refresh | `modules/Refresh/to-bios.psm1` | `source-ultimate/2 Refresh/4 To Bios.ps1`<br>`555C124CC29006D9E6E42A1B2B3761AB760431E3D028758400A69065890E403D` | Reboot to firmware | Deferred | Executes `shutdown.exe /r /fw /t 0`; requires the established explicit reboot confirmation flow. | No | No | Phase: Firmware Restart Workflow |
| Edge Settings | Setup | `modules/Setup/edge-settings.psm1` | `source-ultimate/3 Setup/6 Edge Settings.ps1`<br>`3EE9E6F586D71E74F7400379E8D5DA079D52208D5B2DFA0E4AB035FCB08096A8` | HKLM policy; process; service deletion; RunOnce; downloads; installer; registry deletion | Implemented near parity | Phase 118 preserves the full source Optimize and Default behavior with confirmation, capture where practical, structured verification, and test-safe seams. | Yes | Restore requires future selected captured-state contract | Phase 118 complete |
| Installers | Installers | `modules/Installers/installers.psm1` | `source-ultimate/4 Installers/1 Installers.ps1`<br>`268C1EFE627FADDA17892223D4C35E4845833506C22AADD3240C894ED046A6F8` | Downloads; installers; HKLM policies; processes; services; file changes | Deferred | Large multi-application installer with application-specific post-install changes and uninstalls. | No global Default | No; each package needs independent state and uninstall policy | Phase: Approved Installer Framework |
| Driver Install Debloat & Settings | Graphics | `modules/Graphics/driver-install-debloat-settings.psm1` | `source-ultimate/5 Graphics/1 Driver Install Debloat & Settings.ps1`<br>`00D7EA2C941DF776F729CD35A9386FE18D59D02717DCB3CF43282714E345A6D3` | Downloads; installers; drivers; AppX; HKCU/HKLM; services; processes; RunOnce; file deletion; reboot | Deferred | Vendor-specific driver extraction/install/debloat, service removal, profile import, component deletion, and restart. | No overall Default | Yes; `Restore` requires captured pre-migration driver state | Phase: Graphics Driver Orchestrator |
| DirectX | Graphics | `modules/Graphics/directx.psm1` | `source-ultimate/5 Graphics/2 DirectX.ps1`<br>`B944AE03DE0AFDD7329B84BBF53FF5624739465CBB7130A021E097A6723B1B27` | Downloads; 7-Zip install/config; extraction; DXSETUP launch | Implemented near parity | Phase 129 preserves the source-equivalent workflow behind BoostLab confirmation and test-safe executor injection. The source-defined `7zip.exe` and `directx.exe` URLs remain unchanged and are classified as author-hosted `NeedsBoostLabMirror` entries; no artifact provenance or mirror approval is added. | No | No; future Restore would need captured installer/artifact/registry/shortcut/temp state | Phase 129 complete as Yazan-accepted near parity |
| Visual C++ | Graphics | `modules/Graphics/visual-cpp.psm1` | `source-ultimate/5 Graphics/3 C++.ps1`<br>`01D6A5FAFD5E7C1FB9DA1913BD17C543EE0F8A4A7E2A7DF5583A50AEF1D82374` | Downloads; twelve waited installer launches | Implemented near parity | Phase 130 preserves the source-equivalent workflow behind BoostLab confirmation and test-safe executor injection. The twelve source-defined redistributable URLs remain unchanged and classified as author-hosted `NeedsBoostLabMirror` entries; no artifact provenance or mirror approval is added. | No | No; future Restore would need captured package/file/registry/temp state | Phase 130 complete as Yazan-accepted near parity |
| Start Menu Taskbar | Windows | `modules/Windows/start-menu-taskbar.psm1` | `source-ultimate/6 Windows/1 Start Menu Taskbar.ps1`<br>`D53678CE91FE8ADE6D28F221A2E4153188597D850149F87227B26E0B821EFFF4` | HKCU/HKLM; process stop; file write/copy/delete | Deferred | Deletes Quick Launch and Start layout state, replaces `start2.bin`, writes policy XML, and terminates Explorer. Current `Open` metadata is inaccurate. | Yes | No, but previous user layout is not captured | Phase: Start and Taskbar State Migration |
| Start Menu Layout | Windows | `modules/Windows/start-menu-layout.psm1` | `source-ultimate/6 Windows/2 Start Menu Layout.ps1`<br>`B769C351189A3DC2BB8E4A595F9E745A9F25E5A69923DF10619B6D9C34D37724` | HKCU/HKLM registry | Safe | Four feature overrides plus `AllAppsViewMode`; no process/service/download/reboot behavior. Source choices are 25H2 and 24H2, not Apply and Default. | No explicit Default | Yes; approve mapping of `Default` to the 24H2 branch or rename the action | Phase: Start Menu Layout Toggle |
| Context Menu | Windows | `modules/Windows/context-menu.psm1` | `source-ultimate/6 Windows/3 Context Menu.ps1`<br>`0E0B63E158A22D01CB0654A92BBF4B1EFD01A9DD610CCF0631F4ACB851AF5117` | HKCU/HKLM/HKCR registry; temporary `.reg` file | Medium | Reversible in intent, but touches many shell handlers. Default deletes the complete shared `Shell Extensions\Blocked` key and could remove unrelated entries. | Yes | No, but collateral-key behavior needs approval or state capture | Phase: Context Menu Policy Toggle |
| Theme Black | Windows | `modules/Windows/theme-black.psm1` | `source-ultimate/6 Windows/4 Theme Black.ps1`<br>`3E5C58E1128B20041828BD3BDDA07033D84B2C540CAE18DDC82C989BDEECE31A` | HKCU/HKLM registry; temporary `.reg` file | Safe | Focused theme, transparency, accent, DWM, and background values with an explicit Default branch. | Yes | No | Phase: Theme Black Toggle |
| Signout LockScreen Wallpaper Black | Windows | `modules/Windows/signout-lockscreen-wallpaper-black.psm1` | `source-ultimate/6 Windows/5 Signout Lockscreen Wallpaper Black.ps1`<br>`132C79401BE9CC2067FA97558AC28C03946B4D50BC2E895CF516A658332ECEB1` | HKCU/HKLM; generated image; scoped file deletion; UI refresh | Medium | Creates/deletes `C:\Windows\Black.jpg`. Default removes the complete `PersonalizationCSP` key rather than only owned values. | Yes | No, but previous wallpaper/CSP state should be captured if behavior is narrowed | Phase: Black Wallpaper and Lock Screen |
| Copilot | Windows | `modules/Windows/copilot.psm1` | `source-ultimate/6 Windows/8 Copilot.ps1`<br>`45F87252A018398E87B281DE094E4943A63026567EB0782B631BBEF989CF6A9E` | HKCU/HKLM policy; broad process stop; AppX removal/re-registration | Deferred | Phase 18 refusal: registry-only behavior would weaken Ultimate; full behavior violates AppX and broad-process restrictions. | Yes | No | Phase: Copilot Package and Policy Workflow |
| Bloatware | Windows | `modules/Windows/bloatware.psm1` | `source-ultimate/6 Windows/11 Bloatware.ps1`<br>`EBCE09158AB61ADE2C181DD5DB64C94B962BAF133DB4DB6122CEE642B9A48C9F` | AppX removal/re-registration; services; downloads; installers; security-related features; broad deletion | Deferred | Multi-mode removal and repair workflow with no single reversible state. | No single Default | Yes; Restore requires a captured package/feature inventory | Phase: Bloatware Analysis and Package Plan |
| GameBar | Windows | `modules/Windows/game-bar.psm1` | `source-ultimate/6 Windows/12 Gamebar.ps1`<br>`C35831AFE527DFA090E5DA6EBF0F6132256A4ABF3BEBDA90FC8605C47F55C0D2` | HKCU/HKLM/HKCR; processes; services; AppX; installer/uninstaller; downloads; TrustedInstaller | Deferred | Phase 18 refusal: full behavior includes Gaming/Xbox removal, GameInput uninstall, repair downloads, and TrustedInstaller. | Yes | No | Phase: GameBar and Gaming Services Repair |
| Edge & WebView | Windows | `modules/Windows/edge-webview.psm1` | `source-ultimate/6 Windows/13 Edge & WebView.ps1`<br>`3AB92D76307B1CB4C6988DB2201631C14D3B91B32CFFA4F1177B3E1F4F0D7966` | HKCU/HKLM; processes; service deletion; RunOnce; downloads; installers; broad file deletion | Deferred | Removes Edge/WebView files and services, then Default downloads repair installers. | Yes | No | Phase: Edge and WebView Removal/Repair |
| Notepad Settings | Windows | `modules/Windows/notepad-settings.psm1` | `source-ultimate/6 Windows/14 Notepad Settings.ps1`<br>`CF139B4C5C96F57A2031F0CB9EDAC04E0F3CF86691BDC47F78DF5B45B76C1BA1` | Notepad process stop; mounted app settings hive; file write/delete | Implemented | Phase 32 preserves Apply and Default with explicit confirmation, a verified pre-change backup, scoped state capture, and structured verification. | Yes | No; no Restore action is claimed | Phase 32 complete |
| Control Panel Settings | Windows | `modules/Windows/control-panel-settings.psm1` | `source-ultimate/6 Windows/15 Control Panel Settings.ps1`<br>`F81FB649A4645A5145B43A051DDF8306145E64F1FCA5249F90B66BFDFA97BE83` | HKCU/HKLM/HKCR; services; security policy; deletion; TrustedInstaller | Deferred | Nearly 3,000 lines of broad policy and settings behavior. Current `Open` metadata is inaccurate. | Yes | No | Phase: Control Panel Settings Decomposition |
| Network Adapter Power Savings & Wake | Windows | `modules/Windows/network-adapter-power-savings-wake.psm1` | `source-ultimate/6 Windows/19 Network Adapter Power Savings & Wake.ps1`<br>`D0CD4D79295D78366478C45958E5790ABAA63FE42065FBC29B88D6326DF6A4B6` | Broad dynamic HKLM adapter registry | Medium | Writes/removes 14 adapter power/wake values per detected adapter. Current `Open` metadata is inaccurate. | Yes | No | Phase: Network Adapter Power and Wake |
| Write Cache Buffer Flushing | Windows | `modules/Windows/write-cache-buffer-flushing.psm1` | `source-ultimate/6 Windows/20 Write Cache Buffer Flushing.ps1`<br>`28891440103D710F66F73620D944A9F29174B0DCCC211DCDE1008D694BBC90E2` | HKLM storage-device registry; destructive key deletion | Implemented | Phase 47 preserves Apply with exact pre-change value capture and refuses the unsafe source Default broad `Disk` key deletion. Source also references the intentionally deleted NVME Faster Driver tool, which remains deleted. | Yes, but unsafe | No Default is exposed; future Restore would require reviewed captured-state selection | Phase 47 complete |
| Power Plan | Windows | `modules/Windows/power-plan.psm1` | `source-ultimate/6 Windows/21 Power Plan.ps1`<br>`BC0CA2C442CE74CA07ECDA0FE6F52DDD50C86D9E5F1A9DD420943AA08D9D1285` | HKLM power policy; extensive `powercfg`; power-scheme deletion; UI launch | Deferred | Deletes all enumerated schemes, disables hibernation, and sets battery warnings/actions/levels to zero. Default cannot restore custom prior schemes. | Yes | Yes for true Restore; source Default only restores Windows schemes | Phase: Power Plan Capture, Apply, and Rollback |
| Cleanup | Windows | `modules/Windows/cleanup.psm1` | `source-ultimate/6 Windows/22 Cleanup.ps1`<br>`13C3933AC95A9817E48C0FFA4971FB2CC2234F9783831C34675F9F529F2D507E` | Broad recursive file deletion | Deferred | Deletes user/system temp contents, `inetpub`, `PerfLogs`, `Windows.old`, and `DumpStack.log`; no rollback. | No | No practical inverse | Phase: Cleanup Inventory and Confirmation |
| Timer Resolution Assistant | Advanced | `modules/Advanced/timer-resolution-assistant.psm1` | `source-ultimate/8 Advanced/6 Timer Resolution Assistant.ps1`<br>`46098A6B38BA04DA4A5A962EDC9B7EEBF2742A158845FA82C183D865133D2E73` | Compiles executable; creates/starts/stops service; scoped file deletion; Task Manager launch | Medium | Narrowly scoped service, but production needs reviewed source provenance, deterministic compilation, service verification, and cleanup. | Yes | No | Phase: Timer Resolution Service Assistant |
| Defender Optimize Assistant | Advanced | `modules/Advanced/defender-optimize-assistant.psm1` | `source-ultimate/8 Advanced/7 Defender Optimize Assistant.ps1`<br>`FA09439A4056CA16937B47AEA6D70092312513D92EC9DFA09CF62B1D625E0B92` | Defender/security; services; drivers; deletion; RunOnce; Safe Mode; TrustedInstaller; reboot | Deferred | High-impact security workflow with repeated Safe Mode transitions and restarts. | Yes | No, but recovery must be independently verified | Phase: Defender Safe Mode Recovery Assistant |

## D. Implemented After Triage

### Device Manager Power Savings & Wake

Phase 26 implemented the source-defined Apply and Default registry behavior with strict ACPI/HID/PCI/USB target validation, explicit confirmation, idempotent value deletion, and read-only verification. See `docs/migrations/device-manager-power-savings-wake.md`.

### User Account Pictures Black

Phase 27 implemented the source-defined black-image and default-restore behavior with verified per-file backups, ownership tracking, explicit confirmation, unknown-file preservation, and hash-based verification. See `docs/migrations/user-account-pictures-black.md`.

### Notepad Settings

Phase 32 implemented the source-defined Apply and Default behavior with exact Notepad process and `settings.dat` scope, mounted-hive import, explicit confirmation, verified pre-change backup, state capture, and structured verification. See `docs/migrations/notepad-settings.md`.

### Unattended

Phase 33 implemented the source-defined Windows 11 `autounattend.xml` generation workflow with Analyze and confirmed Apply actions. It preserves the complete Ultimate XML payload, account substitution, temporary-file sequence, removable-media destination, and folder launch while adding verified backup and ownership state before any overwrite. Windows 10 and Windows 11 may host this Windows 11 preparation workflow; Windows 10 optimization branches remain unsupported. No Default or Restore action is claimed. See `docs/migrations/unattended.md`.

### Updates Drivers Block

Phase 112 superseded the Phase 102 live-policy final scope. The tool now
implements only Driver Updates Block Bootable USB: Analyze, confirmed Apply to
selected USB `setupcomplete.cmd` after file capture, unavailable Default, and
selected captured USB file Restore. Live host registry block/unblock, broad
Windows Updates, custom update-server URL, script execution, external-process,
and host reboot branches remain blocked. See
`docs/migrations/updates-drivers-block.md`.

### Write Cache Buffer Flushing

Phase 47 implemented the source-defined Windows 11 Apply behavior with exact SCSI/NVME target discovery, pre-change `CacheIsPowerProtected` value capture, explicit confirmation, and structured verification. Because this is a storage optimization tool rather than a Windows 11 preparation workflow, Windows 10 hosts receive `NotApplicable` before registry discovery or mutation. The source Default broad `Disk` key deletion is refused, and no Restore action is claimed until a captured-state selection flow is approved. See `docs/migrations/write-cache-buffer-flushing.md`.

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
2. **Start Menu Taskbar**, only after exact file/registry scopes, Explorer process handling, and restore selection are approved
3. **Cleanup**, after approving exact cleanup ownership, quarantine/delete choices, and verification rules

Timer Resolution is the strongest remaining medium-risk candidate in this historical queue. Every listed item still requires a dedicated safety decision before implementation.

## Decisions Needed Before Future Phases

* Decide whether source alternatives such as Start Menu Layout `24H2` may be labeled `Default`.
* Decide whether known broad key deletion in Context Menu and Signout Wallpaper should be preserved or intentionally narrowed.
* Define a state-capture contract for file replacement and hardware-wide registry tools.
* Define package inventory and rollback requirements before any AppX migration.
* Define installer provenance, checksums, and distribution policy before downloads are implemented.
* Complete TrustedInstaller execution and recovery governance before GameBar, Control Panel Settings, or Defender.
* Define Safe Mode recovery and interrupted-run behavior before Defender.
* Require captured previous state before exposing `Restore` for driver, service, bloatware, power-plan, or system-file tools.
