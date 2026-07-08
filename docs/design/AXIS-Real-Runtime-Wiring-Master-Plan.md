# AXIS Real Runtime Wiring Master Plan

Date: 2026-07-08
Scope: documentation-only master plan for converting the completed AXIS first-use wizard prototype from simulation-only behavior to real runtime wiring

## Boundary

This phase is documentation-only. It does not implement runtime wiring, edit UI, edit tests, edit config, edit modules, import modules, execute scripts, run tools, run Apply/Open/Analyze/Default/Restore/Restart, mutate the host, stage, commit, or push.

Protected paths remain out of scope:

- `source-ultimate/`
- `source-extra/`
- `intake/`
- `ui/MainWindow.ps1`
- `ui/AxisFirstUseWizardPrototype.ps1`
- `modules/`
- `config/`
- `tests/`

The plan is about wiring the completed AXIS wizard UI to existing approved BoostLab behavior. It is not script redesign. Yazan has already validated the original BoostLab scripts repeatedly on a clean machine; future work must preserve existing script behavior unless Yazan explicitly approves a change.

## Discovery Basis

This document was prepared from read-only inspection of:

- `docs/design/AXIS-First-Use-Wizard-Prototype-Completion-Record.md`
- `docs/design/AXIS-Product-Direction-Lock.md`
- `docs/design/AXIS-Restart-Resume-Contract.md`
- `docs/design/steps/*.md`
- `config/Stages.psd1`
- `config/UltimateParityExecutionOrder.psd1`
- `modules/`
- `ui/AxisFirstUseWizardPrototype.ps1`

No project script or tool was executed to create this plan.

## Current Status Summary

- AXIS isolated first-use wizard prototype is complete.
- The flow has 52 navigable pages.
- The flow has 50 tool steps.
- `intro-welcome` and `final-completion` exist.
- Prototype persistence/resume exists, including completed-setup start-over behavior.
- Current stage: preparing strict stage-by-stage real runtime wiring.
- The latest starting commit for this plan is `5d705b7 Apply AXIS persistence and resume prototype`.

## Product Direction Constraints

These constraints remain locked:

- AXIS is Arabic-only.
- No English version.
- No dashboard.
- No free-control mode.
- Guided wizard remains the customer flow.
- AXIS is customer-facing.
- BoostLab remains internal repo/code branding.
- Normal customer UI must not show BoostLab.
- Instruction buttons are not linked yet because the Cloudflare AXIS website does not exist.
- Website, purchase flow, license key system, and `irm <AXIS-site-url> | iex` launch model are future Cloudflare platform work.
- Discord bots are future work.
- Normal customer UI must stay clean and must not expose logs, diagnostics, PowerShell, Registry names, Services names, Tasks, AppX/package names, file paths, hashes, URLs, internal module names, implementation details, or raw runtime method details.

## Runtime Wiring Principles

1. Preserve existing BoostLab tool behavior.
2. Do not weaken scripts.
3. Do not change script behavior unless Yazan explicitly requests it.
4. AXIS UI wiring should call existing approved modules/actions where available.
5. AXIS custom actions must be explicitly documented before implementation.
6. Customer UI remains Arabic-only and clean.
7. Internal technical details stay out of normal customer UI.
8. BoostLab remains internal branding; AXIS remains customer-facing branding.
9. Completion remains completion-only in customer UI. Runtime diagnostics may preserve technical truth outside normal customer UI.
10. Future production wiring must respect the existing confirmation, state capture, verification, and result contracts already present in BoostLab modules.
11. Do not expose module-supported `Analyze`, `Default`, or `Restore` actions in the normal first-use wizard unless the relevant AXIS step blueprint or Yazan explicitly approves that customer-facing action.

## Complete Page And Step Mapping

The mapping below covers all 52 pages and all 50 tool steps. "Primary future mapping" means the customer-facing first-use wizard action planned for that page, not every module-supported action.

| Order | Page/step id | Stage | Page type | Prototype behavior | Primary future mapping | Real module/tool file | Real action name | Selector/input | Overlay | Restart/resume relevance | Notes / blockers |
| ---: | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0 | `intro-welcome` | Before Check | intro page | UI-only intro and Start navigation | UI-only page | None | UI-only Start | No | No | Saves intro completion only | No runtime action. |
| 1 | `bios-information` | Check | tool step | Simulated Open flow with documentation/confirmation pattern | `Open`, with `Analyze` available for displayed data | `modules/Check/BIOSInformation.psm1` | `Open`; `Analyze` for read-only data | No | Yes | Low; no restart expected | Normal UI must not expose raw BIOS diagnostics. |
| 2 | `bios-settings` | Check | tool step | Simulated firmware guidance/restart flow | `Open`, with `Analyze` available for guidance | `modules/Check/BIOSSettings.psm1` | `Open`; `Analyze` for guidance | No | Yes | Yes; firmware handoff may need resume support | Hardware/vendor uncertainty stays diagnostics-only. |
| 3 | `reinstall` | Refresh | tool step | Simulated Windows 11 media creation action | `Apply` | `modules/Refresh/reinstall.psm1` | `Apply` | No current input; USB/media context applies | No | Possible external handoff; follow module result | Do not expose Open/Default/Restore in normal AXIS unless approved. |
| 4 | `unattended` | Refresh | tool step | Simulated input window for account name and USB | `Apply` | `modules/Refresh/unattended.psm1` | `Apply` | Input window: account name and USB | No | No restart; USB output relevance | Input validation and USB selection must be wired to module parameters. |
| 5 | `updates-drivers-block` | Refresh | tool step | Simulated USB selector/input window | `Apply` | `modules/Refresh/updates-drivers-block.psm1` | `Apply` | Input window: USB selector | No | No restart; Windows setup USB relevance | Restore exists in module but is not normal customer UI. |
| 6 | `to-bios` | Refresh | tool step | Simulated confirmation restart-to-BIOS flow | `Open` | `modules/Refresh/to-bios.psm1` | `Open` | No | Yes | Yes; firmware handoff | Real Open must coordinate with persistence before restart/handoff. |
| 7 | `bitlocker` | Setup | tool step | Simulated BitLocker action | `Apply` | `modules/Setup/bitlocker.psm1` | `Apply` | No | No current overlay | No restart expected | Module supports Analyze/Open/Default/Restore, but normal AXIS uses approved primary action only. |
| 8 | `convert-home-to-pro` | Setup | tool step | Simulated Windows Pro upgrade handoff | `Apply` | `modules/Setup/convert-home-to-pro.psm1` | `Apply` | No | No | Possible Windows restart outside AXIS if customer proceeds later | License/activation details must stay out of normal AXIS UI beyond approved copy. |
| 9 | `memory-compression` | Setup | tool step | Simulated Memory Compression change | `Apply` | `modules/Setup/MemoryCompression.psm1` | `Apply` | No | No | No | Default exists but is not normal AXIS UI. |
| 10 | `date-language-region-time` | Setup | tool step | Simulated settings Open | `Open` | `modules/Setup/date-language-region-time.psm1` | `Open` | No | No | No | Do not show settings URI or command details. |
| 11 | `startup-apps-settings` | Setup | tool step | Simulated settings Open | `Open` | `modules/Setup/StartupAppsSettings.psm1` | `Open` | No | No | No | This Setup step remains even though Installers has a later duplicate. |
| 12 | `startup-apps-task-manager` | Setup | tool step | Simulated Task Manager Open | `Open` | `modules/Setup/StartupAppsTaskManager.psm1` | `Open` | No | No | No | Do not expose process arguments or internal Open details. |
| 13 | `background-apps` | Setup | tool step | Simulated background apps optimization | `Apply` | `modules/Setup/BackgroundApps.psm1` | `Apply` | No | No | No | Default exists but is not normal AXIS UI. |
| 14 | `edge-settings` | Setup | tool step | Simulated Microsoft Edge optimization | `Apply` | `modules/Setup/edge-settings.psm1` | `Apply` | No | No | No | Analyze/Default/Restore stay out of normal AXIS UI unless approved. |
| 15 | `store-settings` | Setup | tool step | Simulated Microsoft Store optimization | `Apply` | `modules/Setup/StoreSettings.psm1` | `Apply` | No | No | No | Default exists but is not normal AXIS UI. |
| 16 | `updates-pause` | Setup | tool step | Simulated pause updates with confirmation overlay | `Apply` | `modules/Setup/UpdatesPause.psm1` | `Apply` | No | Yes | No | Confirmation copy is owner-approved for this step. |
| 17 | `installers` | Installers | tool step | Simulated single app selection and install | `Apply` | `modules/Installers/installers.psm1` | `Apply` with selected app | Selector: one app | Conditional Epic instruction overlay | No restart during this step | Catalog internals stay hidden; removed apps remain unavailable. |
| 18 | `installers-startup-apps-settings` | Installers | tool step | Simulated settings Open after app install | `Open` | `modules/Setup/StartupAppsSettings.psm1` | `Open` | No | No | No | Installers-stage duplicate; original Setup step remains. |
| 19 | `installers-startup-apps-task-manager` | Installers | tool step | Simulated Task Manager Open after app install | `Open` | `modules/Setup/StartupAppsTaskManager.psm1` | `Open` | No | No | No | Installers-stage duplicate; original Setup step remains. |
| 20 | `restart-after-installers` | Installers | tool step | Simulated restart action | AXIS custom `Restart` | None | AXIS custom `Restart` | No | No current overlay | Yes; resume to this step complete, then customer presses Next | Must be implemented as an explicit AXIS custom action later. |
| 21 | `driver-clean` | Graphics | tool step | Simulated Driver Clean Auto path | `Apply` | `modules/Graphics/driver-clean.psm1` | `Apply` | No | Yes | Yes; Safe Mode/restart may be involved | Preserve existing approved Driver Clean behavior. No standalone DDU. |
| 22 | `driver-install-debloat-settings` | Graphics | tool step | Simulated GPU branch selector; NVIDIA selectable | `Apply` | `modules/Graphics/driver-install-debloat-settings.psm1` | `Apply` with selected GPU branch | Selector: NVIDIA only enabled | Yes | Possible; follow module result | Do not enable AMD/Intel customer options unless owner expands AXIS scope. |
| 23 | `nvidia-app-install` | Graphics | tool step | Simulated NVIDIA App install plus optional continuation | `Apply` | `modules/Graphics/nvidia-app-install.psm1` | `Apply` | No | Yes | No expected restart | Optional continuation must not execute Apply or use skip language. |
| 24 | `directx` | Graphics | tool step | Simulated DirectX install | `Apply` | `modules/Graphics/directx.psm1` | `Apply` | No | No | No expected restart | Downloads/installers handled by existing module behavior. |
| 25 | `visual-cpp` | Graphics | tool step | Simulated Visual C++ install | `Apply` | `modules/Graphics/visual-cpp.psm1` | `Apply` | No | No | No expected restart | Downloads/installers handled by existing module behavior. |
| 26 | `graphics-configuration-center` | Graphics | tool step | Simulated graphics settings Open | `Open` | `modules/Graphics/GraphicsConfigurationCenter.psm1` | `Open` | No | No | No | Open only; do not expose internal settings target. |
| 27 | `start-menu-taskbar` | Windows | tool step | Simulated Start Menu/Taskbar tweaks | `Apply` | `modules/Windows/start-menu-taskbar.psm1` | `Apply` | No | No | No | Default exists but is not normal AXIS UI. |
| 28 | `start-menu-layout` | Windows | tool step | Simulated Start layout tweaks | `Apply` | `modules/Windows/StartMenuLayout.psm1` | `Apply` | No | No | No | Default exists but is not normal AXIS UI. |
| 29 | `context-menu` | Windows | tool step | Simulated context menu tweaks | `Apply` | `modules/Windows/ContextMenu.psm1` | `Apply` | No | No | No | Default exists but is not normal AXIS UI. |
| 30 | `theme-black` | Windows | tool step | Simulated dark theme application | `Apply` | `modules/Windows/ThemeBlack.psm1` | `Apply` | No | No | No | Default exists but is not normal AXIS UI. |
| 31 | `signout-lockscreen-wallpaper-black` | Windows | tool step | Simulated black wallpaper/signout/lockscreen application | `Apply` | `modules/Windows/SignoutLockScreenWallpaperBlack.psm1` | `Apply` | No | No | No | Default exists but is not normal AXIS UI. |
| 32 | `user-account-pictures-black` | Windows | tool step | Simulated black account picture application | `Apply` | `modules/Windows/user-account-pictures-black.psm1` | `Apply` | No | No | No | Default exists but is not normal AXIS UI. |
| 33 | `widgets` | Windows | tool step | Simulated Widgets disable | `Apply` | `modules/Windows/widgets.psm1` | `Apply` | No | No | No | Default exists but is not normal AXIS UI. |
| 34 | `copilot` | Windows | tool step | Simulated Copilot disable | `Apply` | `modules/Windows/copilot.psm1` | `Apply` | No | No | No | Default exists but is not normal AXIS UI. |
| 35 | `game-mode` | Windows | tool step | Simulated Game Mode settings Open | `Open` | `modules/Windows/game-mode.psm1` | `Open` | No | No | No | Open only. |
| 36 | `pointer-precision` | Windows | tool step | Simulated Mouse Properties Open | `Open` | `modules/Windows/pointer-precision.psm1` | `Open` | No | No | No | Open only. |
| 37 | `bloatware` | Windows | tool step | Simulated action selector and execution | `Apply` | `modules/Windows/bloatware.psm1` | `Apply` with selected branch | Selector: approved branch | Yes | No | Only approved customer-visible choices should appear. |
| 38 | `game-bar` | Windows | tool step | Simulated Game Bar disable | `Apply` | `modules/Windows/game-bar.psm1` | `Apply` | No | No | No | Default exists but is not normal AXIS UI. |
| 39 | `edge-webview` | Windows | tool step | Simulated Edge WebView removal | `Apply` | `modules/Windows/edge-webview.psm1` | `Apply` | No | Yes | No | Normal AXIS UI must not mention BoostLab. |
| 40 | `notepad-settings` | Windows | tool step | Simulated Notepad settings | `Apply` | `modules/Windows/notepad-settings.psm1` | `Apply` | No | No | No | Default exists but is not normal AXIS UI. |
| 41 | `control-panel-settings` | Windows | tool step | Simulated Control Panel settings | `Apply` | `modules/Windows/control-panel-settings.psm1` | `Apply` | No | No | No | Default exists but is not normal AXIS UI. |
| 42 | `input-language-hotkey` | Windows | tool step | Simulated input-language hotkey change | `Apply` | `modules/Windows/input-language-hotkey.psm1` | `Apply` | No | No | No | BoostLab-specific approved tool; normal UI should not expose registry details. |
| 43 | `sound` | Windows | tool step | Simulated Sound settings Open | `Open` | `modules/Windows/sound.psm1` | `Open` | No | No | No | Open only. |
| 44 | `device-manager-power-savings-wake` | Windows | tool step | Simulated device power/wake optimization | `Apply` | `modules/Windows/device-manager-power-savings-wake.psm1` | `Apply` | No | No | No | Default exists but is not normal AXIS UI. |
| 45 | `network-adapter-power-savings-wake` | Windows | tool step | Simulated network adapter power/wake optimization | `Apply` | `modules/Windows/NetworkAdapterPowerSavingsWake.psm1` | `Apply` | No | No | No | Default exists but is not normal AXIS UI. |
| 46 | `write-cache-buffer-flushing` | Windows | tool step | Simulated storage optimization | `Apply` | `modules/Windows/write-cache-buffer-flushing.psm1` | `Apply` | No | No | No | Analyze/Default exist but are not normal AXIS UI. |
| 47 | `power-plan` | Windows | tool step | Simulated power plan application | `Apply` | `modules/Windows/PowerPlan.psm1` | `Apply` | No | No | No | Default exists but is not normal AXIS UI. |
| 48 | `cleanup` | Windows | tool step | Simulated cleanup | `Apply` | `modules/Windows/cleanup.psm1` | `Apply` | No | No | No | Cleanup scope must remain bounded by existing module behavior. |
| 49 | `timer-resolution-assistant` | Advanced | tool step | Simulated Timer Resolution activation | `Apply` | `modules/Advanced/timer-resolution-assistant.psm1` | `Apply` | No | No | No expected restart | Analyze/Default exist but are not normal AXIS UI. |
| 50 | `defender-optimize-assistant` | Advanced | tool step | Simulated Defender Optimize flow | `Apply` | `modules/Advanced/defender-optimize-assistant.psm1` | `Apply` | No | Yes | Yes; Safe Mode/restart may be involved | Preserve existing Defender workflow; details stay diagnostics-only. |
| 51 | `final-completion` | After Advanced | final page | UI-only completion and prototype-window close | UI-only page | None | UI-only Finish/close | No | No | Saves setup complete; reopening shows start-over prompt | No dashboard and no runtime action. |

## Custom AXIS Actions

The following pages/actions are not direct existing BoostLab tool actions:

- `intro-welcome`: UI-only intro page.
- `final-completion`: UI-only completion page; Finish closes AXIS/prototype window without clearing saved progress.
- `restart-after-installers`: future AXIS custom `Restart` action.
- Persistence/resume: coordinates wizard state, restart handoff, and resume targets; it does not replace module actions.

`restart-after-installers` must be implemented only in a later approved Installers-stage wiring phase. It must integrate with the resume contract so the customer returns to `restart-after-installers` marked complete and manually presses Next to enter Graphics.

## Restart/Resume Integration Plan

Future runtime wiring must coordinate with `docs/design/AXIS-Restart-Resume-Contract.md`.

Relevant flows:

- `bios-settings`: firmware/BIOS handoff may require saving current state before the handoff.
- `to-bios`: restart-to-BIOS Open behavior requires saving expected restart/handoff state before action.
- `restart-after-installers`: AXIS custom restart; after restart, resume to this step complete and do not auto-advance.
- `driver-clean`: real Driver Clean may involve Safe Mode/restart. Resume behavior must return to the correct Graphics step according to the module result.
- `defender-optimize-assistant`: real Defender flow may involve Safe Mode/restart. Resume behavior must return to the correct Advanced step according to the module result.

Manual customer restart outside an expected AXIS restart flow must not auto-start AXIS. AXIS should resume only when the customer opens AXIS manually.

Production persistence/storage and auto-start mechanism remain future implementation work. This plan does not implement `%ProgramData%\AXIS`, Scheduled Tasks, RunOnce, registry writes, services, bootstrapper resume, or production state files.

## Required Stage-By-Stage Implementation Order

Real runtime conversion must happen strictly stage-by-stage in the exact AXIS wizard order. Step notes may mention selectors, inputs, overlays, or restart relevance, but implementation order remains stage-first and exact-flow only.

### A. Check Stage Runtime Wiring

Steps:

1. `bios-information`
2. `bios-settings`

Likely files later:

- `ui/AxisFirstUseWizardPrototype.ps1` or future production AXIS wizard file
- wiring layer/controller selected by the implementation phase
- `modules/Check/BIOSInformation.psm1`
- `modules/Check/BIOSSettings.psm1`

Notes:

- Both steps have `Analyze` support.
- Both primary customer flows map to `Open`.
- `bios-settings` needs restart/resume awareness.
- Customer UI must not expose hardware/vendor uncertainty details.

### B. Refresh Stage Runtime Wiring

Steps:

1. `reinstall`
2. `unattended`
3. `updates-drivers-block`
4. `to-bios`

Likely files later:

- AXIS wizard production wiring file(s)
- `modules/Refresh/reinstall.psm1`
- `modules/Refresh/unattended.psm1`
- `modules/Refresh/updates-drivers-block.psm1`
- `modules/Refresh/to-bios.psm1`

Notes:

- `reinstall`, `unattended`, and `updates-drivers-block` map to `Apply`.
- `to-bios` maps to `Open`.
- `unattended` and `updates-drivers-block` need input/USB wiring.
- `to-bios` needs restart/resume awareness.
- USB detection/selection must be real only in the implementation phase, not in this plan.

### C. Setup Stage Runtime Wiring

Steps:

1. `bitlocker`
2. `convert-home-to-pro`
3. `memory-compression`
4. `date-language-region-time`
5. `startup-apps-settings`
6. `startup-apps-task-manager`
7. `background-apps`
8. `edge-settings`
9. `store-settings`
10. `updates-pause`

Likely files later:

- AXIS wizard production wiring file(s)
- `modules/Setup/*.psm1`

Notes:

- Primary mappings are `Apply` except `date-language-region-time`, `startup-apps-settings`, and `startup-apps-task-manager`, which map to `Open`.
- `updates-pause` keeps its confirmation overlay.
- Default/Restore-capable modules must not expose those actions in normal AXIS UI unless owner-approved.
- Convert Home To Pro must not expose license-key internals in normal UI.

### D. Installers Stage Runtime Wiring

Steps:

1. `installers`
2. `installers-startup-apps-settings`
3. `installers-startup-apps-task-manager`
4. `restart-after-installers`

Likely files later:

- AXIS wizard production wiring file(s)
- `modules/Installers/installers.psm1`
- `modules/Setup/StartupAppsSettings.psm1`
- `modules/Setup/StartupAppsTaskManager.psm1`
- future AXIS custom restart implementation location

Notes:

- `installers` maps to `Apply` with exactly one selected app.
- The two startup-app steps are Installers-stage duplicates and map to existing Setup Open modules.
- `restart-after-installers` is AXIS custom `Restart`, not an existing BoostLab module.
- After the custom restart, resume to this step marked complete and wait for customer Next.
- The owner will not do a full second-PC test after this stage; that happens only after all stages are wired.

### E. Graphics Stage Runtime Wiring

Steps:

1. `driver-clean`
2. `driver-install-debloat-settings`
3. `nvidia-app-install`
4. `directx`
5. `visual-cpp`
6. `graphics-configuration-center`

Likely files later:

- AXIS wizard production wiring file(s)
- `modules/Graphics/*.psm1`

Notes:

- Primary mappings are `Apply` except `graphics-configuration-center`, which maps to `Open`.
- `driver-install-debloat-settings` needs GPU selector wiring; AXIS currently enables NVIDIA only.
- `driver-clean` and possibly driver setup need restart/resume coordination according to real module results.
- `nvidia-app-install` has optional continuation that must not execute Apply and must not use skip wording.
- DirectX and Visual C++ must preserve existing download/installer behavior and provenance gates.

### F. Windows Stage Runtime Wiring

Steps:

1. `start-menu-taskbar`
2. `start-menu-layout`
3. `context-menu`
4. `theme-black`
5. `signout-lockscreen-wallpaper-black`
6. `user-account-pictures-black`
7. `widgets`
8. `copilot`
9. `game-mode`
10. `pointer-precision`
11. `bloatware`
12. `game-bar`
13. `edge-webview`
14. `notepad-settings`
15. `control-panel-settings`
16. `input-language-hotkey`
17. `sound`
18. `device-manager-power-savings-wake`
19. `network-adapter-power-savings-wake`
20. `write-cache-buffer-flushing`
21. `power-plan`
22. `cleanup`

Likely files later:

- AXIS wizard production wiring file(s)
- `modules/Windows/*.psm1`

Notes:

- Primary mappings are `Apply` except `game-mode`, `pointer-precision`, and `sound`, which map to `Open`.
- `bloatware` needs selector wiring.
- `edge-webview` keeps confirmation overlay and must not show BoostLab in normal customer UI.
- Default/Restore-capable modules must not expose those actions in normal AXIS UI unless owner-approved.
- The Windows stage is large, but it still remains one stage in the required order.

### G. Advanced Stage Runtime Wiring

Steps:

1. `timer-resolution-assistant`
2. `defender-optimize-assistant`

Likely files later:

- AXIS wizard production wiring file(s)
- `modules/Advanced/timer-resolution-assistant.psm1`
- `modules/Advanced/defender-optimize-assistant.psm1`

Notes:

- Both primary mappings are `Apply`.
- `defender-optimize-assistant` needs restart/resume and Safe Mode coordination according to existing module behavior.
- Timer Resolution service/build details stay out of normal customer UI.
- Defender technical/security details stay diagnostics-only.

### H. Final Real-Runtime Acceptance Audit

After all stages are converted, the owner will run one full comprehensive AXIS test from start to finish on a second clean computer and record bugs, notes, performance issues, UI issues, restart/resume issues, and functional issues.

Do not require owner second-PC validation at individual stage checkpoints. The second-PC owner test happens only after all stages are converted.

## Future Stage Implementation Workflow

For each stage implementation later:

1. Stage-specific runtime wiring plan/docs if needed.
2. Implement that stage only.
3. Run local automated validation.
4. Commit/push after owner review if needed.
5. Move to the next stage.

This workflow is stage-by-stage only. Do not convert by action type, technical concern, or risk category.

## Future Local Validation Plan

Future implementation phases should add or update automated checks as appropriate for the stage being wired. The checks should verify:

- Each wired button maps to the intended action only.
- `Open` steps open the intended page/tool.
- `Apply` steps call the intended module action.
- Selectors pass the intended selected option.
- Input windows pass approved values to the intended module action.
- Restart-expected flows save resume state before the handoff.
- Completion unlocks Next without auto-advance.
- Customer UI remains Arabic-only and clean.
- Normal customer UI does not show BoostLab.
- No dashboard appears.
- Instruction links remain inactive until the AXIS website exists.
- Owner second-PC full testing is not listed per stage and happens only after all stages are converted.

## Unknowns And Blockers

- The exact production AXIS wizard host/wiring file is not selected in this docs-only plan.
- `restart-after-installers` needs a future approved AXIS custom Restart implementation.
- Production persistence path, auto-start mechanism, and cleanup for expected restart flows remain future implementation details governed by `AXIS-Restart-Resume-Contract.md`.
- USB/input handoff for `unattended` and `updates-drivers-block` must be wired to module expectations during the Refresh stage.
- Selector payloads for `installers`, `driver-install-debloat-settings`, and `bloatware` must be mapped during their stage implementation.
- Instruction buttons remain blocked by the missing AXIS Cloudflare website/instruction pages.
- Website, license, purchase, bootstrapper, key validation, and Discord bots are not part of runtime wiring.
- No standalone "Runtime safety and diagnostics" roadmap phase should be created; normal validation belongs inside each stage implementation.

## Explicit Non-Goals

- No runtime wiring in this phase.
- No UI changes.
- No test changes.
- No config changes.
- No module changes.
- No source-ultimate/source-extra/intake edits.
- No website.
- No license system.
- No instruction URL mapping.
- No Discord bot work.
- No production persistence implementation.
- No real Apply/Open/Analyze/Default/Restore/Restart execution.
- No host mutation.
- No action-type implementation grouping.
- No owner second-PC full test before all stages are converted.
