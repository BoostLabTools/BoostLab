# Theme Black Migration Record

* **Tool name:** Theme Black
* **Stage:** Windows
* **Source script path:** `source-ultimate/6 Windows/4 Theme Black.ps1`
* **Source checksum:** `3E5C58E1128B20041828BD3BDDA07033D84B2C540CAE18DDC82C989BDEECE31A`
* **Risk level:** Low
* **Required privileges:** Administrator
* **Yazan approval status:** Approved by Yazan for Phase 19

## Original Ultimate Behavior

The source exposes two console choices.

Apply writes `blacktheme.reg` under `%SystemRoot%\Temp` and silently imports it with:

```powershell
Start-Process -Wait "regedit.exe" -ArgumentList "/S `"$env:SystemRoot\Temp\blacktheme.reg`"" -WindowStyle Hidden
```

The payload sets dark app and system theme values, disables transparency, enables colorization, applies the source black accent palette and DWM colors, and sets the desktop background color value to `0 0 0`.

Default writes `defaulttheme.reg` under `%SystemRoot%\Temp` and imports it through the same command. It restores the source light-theme, transparency, accent, DWM, and background values. It also deletes:

```text
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize
```

The source does not launch Settings, restart Explorer, stop processes, change services, remove AppX packages, download or install content, use TrustedInstaller or Safe Mode, modify drivers or security settings, perform cleanup, sign out, or reboot.

## Approved BoostLab Behavior

Apply and Default preserve the source `.reg` payloads, file names, `%SystemRoot%\Temp` paths, `Set-Content` then `regedit.exe /S` execution order, registry paths, value names, value types, value data, and explicit Default branch.

BoostLab uses the application-level Administrator model, Action Plan confirmation, structured results, Activity Log integration, and read-only verification. It does not run the Ultimate script directly.

## Preserved Registry Paths

```text
HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize
HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent
HKCU\Software\Microsoft\Windows\DWM
HKCU\Control Panel\Colors
```

Apply preserves:

* `AppsUseLightTheme = 0` for HKCU and HKLM
* `ColorPrevalence = 1`
* `EnableTransparency = 0`
* `SystemUsesLightTheme = 0`
* The source 32-byte black `AccentPalette`
* `StartColorMenu = 0`
* `AccentColorMenu = 0`
* `EnableWindowColorization = 1`
* `AccentColor = 0xff191919`
* `ColorizationColor = 0xc4191919`
* `ColorizationAfterglow = 0xc4191919`
* `Background = "0 0 0"`

Default preserves:

* `AppsUseLightTheme = 1`
* `ColorPrevalence = 0`
* `EnableTransparency = 1`
* `SystemUsesLightTheme = 1`
* Removal of the complete HKLM Themes `Personalize` key
* The source 32-byte default `AccentPalette`
* `StartColorMenu = 0xffc06700`
* `AccentColorMenu = 0xffd47800`
* `EnableWindowColorization = 0`
* `AccentColor = 0xffd47800`
* `ColorizationColor = 0xc40078d4`
* `ColorizationAfterglow = 0xc40078d4`
* `Background = "0 0 0"`

## Intentional Deviations

The console menu, self-elevation block, `Clear-Host`, `Write-Host`, loop, and `exit` are replaced by BoostLab GUI actions, application/runtime elevation, confirmation, logging, and structured results.

BoostLab checks the `regedit.exe` exit code and reports file-write or import failures instead of silently exiting. It also verifies all 13 source-defined registry states after either action.

No operational theme behavior is removed, softened, or expanded. The source leaves the temporary `.reg` file in place; BoostLab preserves that behavior and does not add file cleanup.

## Capabilities

`RequiresAdmin = true`; `CanModifyRegistry = true`; `SupportsDefault = true`; `NeedsExplicitConfirmation = true`.

Internet, reboot, service, installer, download, driver, security, file deletion, TrustedInstaller, Safe Mode, and Restore capabilities are false.

## Confirmation and Restart

Apply and Default require a visible Action Plan confirmation. Neither action restarts Windows, signs out, or restarts Explorer.

## Default Behavior

Default is the explicit Ultimate Default branch. It is not an inferred inverse. It imports `defaulttheme.reg`, including the source deletion of the HKLM Themes `Personalize` key.

## Verification Strategy

BoostLab reads the five source registry paths and produces 13 checks in source order.

* `Passed`: every expected value matches, including the binary palette and DWORD values; for Default, the HKLM Themes `Personalize` key is absent.
* `Warning`: one or more registry states cannot be read.
* `Failed`: a detected value or key state contradicts the expected source state.

Command completion and verification status remain separate. Windows may require Settings, Explorer, sign-out, or a later session to visually refresh all theme elements, but BoostLab does not force that refresh.

## Test Requirements

Validate the source checksum and safety gate, exact `.reg` payloads, file names, import command, execution order, all registry paths and values, Apply and Default results, confirmation plans, verification Passed/Warning/Failed outcomes, runtime mapping, Latest Result rendering, source-ultimate integrity, deleted-tool exclusion, and the unchanged placeholder state of GameBar and Copilot. Automated tests must use mocks and must not write the real registry, launch regedit, stop processes, sign out, or reboot.
