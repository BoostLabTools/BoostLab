# AXIS First-Use Wizard Prototype Completion Record

## Status

The AXIS first-use wizard isolated prototype is complete as of the final acceptance audit.

- Final acceptance audit: passed.
- Implemented prototype steps: 50/50.
- Full safe/static test suite: 120/120 passed.
- Working tree at audit: clean.
- Last audited commit: `5e42651 Apply AXIS Advanced prototype`.

This record documents the isolated prototype completion only. It does not approve production runtime wiring, customer website linking, or real tool execution from the first-use wizard.

## Final Stage Summary

| Stage | Step Count |
| --- | ---: |
| Check | 2 |
| Refresh | 4 |
| Setup | 10 |
| Installers | 4 |
| Graphics | 6 |
| Windows | 22 |
| Advanced | 2 |

## Final Ordered Step List

### Check

1. `bios-information`
2. `bios-settings`

### Refresh

3. `reinstall`
4. `unattended`
5. `updates-drivers-block`
6. `to-bios`

### Setup

7. `bitlocker`
8. `convert-home-to-pro`
9. `memory-compression`
10. `date-language-region-time`
11. `startup-apps-settings`
12. `startup-apps-task-manager`
13. `background-apps`
14. `edge-settings`
15. `store-settings`
16. `updates-pause`

### Installers

17. `installers`
18. `installers-startup-apps-settings`
19. `installers-startup-apps-task-manager`
20. `restart-after-installers`

### Graphics

21. `driver-clean`
22. `driver-install-debloat-settings`
23. `nvidia-app-install`
24. `directx`
25. `visual-cpp`
26. `graphics-configuration-center`

### Windows

27. `start-menu-taskbar`
28. `start-menu-layout`
29. `context-menu`
30. `theme-black`
31. `signout-lockscreen-wallpaper-black`
32. `user-account-pictures-black`
33. `widgets`
34. `copilot`
35. `game-mode`
36. `pointer-precision`
37. `bloatware`
38. `game-bar`
39. `edge-webview`
40. `notepad-settings`
41. `control-panel-settings`
42. `input-language-hotkey`
43. `sound`
44. `device-manager-power-savings-wake`
45. `network-adapter-power-savings-wake`
46. `write-cache-buffer-flushing`
47. `power-plan`
48. `cleanup`

### Advanced

49. `timer-resolution-assistant`
50. `defender-optimize-assistant`

## Prototype Boundary

- Isolated prototype only.
- No production runtime wiring.
- No real `Apply`, `Open`, `Analyze`, `Default`, `Restore`, or `Restart` behavior.
- No host mutation.
- No protected path modification.
- No `source-ultimate`, `source-extra`, or `intake` edits.
- No `ui/MainWindow.ps1` edits.

## Customer-Facing Restrictions

- AXIS is the customer-facing product.
- BoostLab remains internal repository/code branding.
- Normal customer UI must not show BoostLab.
- Normal customer UI must not expose diagnostics, logs, PowerShell, Registry, Services, Tasks, AppX/package names, file paths, hashes, URLs, internal modules, implementation details, TrustedInstaller, service names, package internals, driver names, Defender internals, or security internals.
- Normal customer UI must not show `Error`, `Failed`, `Warning`, `Needs attention`, `Stopped`, `Restart needed`, `Waiting for confirmation`, `Not available`, `Skipped`, `Completed with notes`, or Arabic equivalents.
- First-use wizard overlays must not show a `Cancel` button.
- The first-use wizard prototype has no icons.

## Layout Safeguards

- Fixed target window: `900x650`.
- Normal Windows chrome/titlebar.
- Dark premium UI.
- No sidebar.
- Stage strip uses completed and active state behavior.
- Active stage line is full white.
- Previous completed stage lines are green.
- No partial progress line.
- Support card remains fully visible and unchanged.
- Runtime status remains separate from the support card.
- Information card is physically right and requirements card is physically left whenever both exist.
- Arabic wrapped lines are physically right-aligned.
- English-only titles render LTR while physically right-anchored.
- Mixed Arabic/English text uses BiDi-safe rendering.
- Selector/dropdown styling uses the shared dark AXIS selector style.
- Primary buttons include no-clipping safeguards.
- Runtime/status areas include no-clipping safeguards.
- Card content includes no-clipping safeguards.
- Confirmation overlay buttons include no-clipping safeguards.
- Customer-facing copy must not contain replacement glyphs.

## Special Decisions

- Game Configs / GitHub-Game-Configs integration is cancelled and is not part of AXIS.
- `restart-after-installers` is an AXIS custom future restart action, not an existing BoostLab tool.
- The Installers stage intentionally includes duplicate startup-app review steps after app installation; the Setup originals remain in Setup.
- GPU Driver Setup currently exposes NVIDIA as selectable only; AMD and Intel are disabled future text-only options.
- NVIDIA App Install includes optional continuation without prohibited skip wording.
- Installers Epic Games behavior is an instructional overlay shown only after pressing Install while Epic is selected.
- Instruction/help website linking is deferred because the AXIS customer/store/instruction website does not exist yet.

## Deferred Future Phases

- Build the AXIS customer/store/instruction website from scratch on the Cloudflare platform.
- After the website exists, define per-step instruction URLs.
- After instruction pages exist, implement Instructions button linking.
- Implement persistence/resume after Restart.
- Plan the production UI/runtime transition from the isolated prototype.
- Implement the future AXIS custom restart action for `restart-after-installers`.
- Review final customer copy before production wiring.

## Instruction Website Boundary

Do not implement or link the Instructions button yet.

The AXIS customer instruction/store website does not exist yet. It will be created later as a separate Cloudflare-based AXIS website/platform phase. Instruction button URL linking must remain deferred until the AXIS website and instruction pages exist.
