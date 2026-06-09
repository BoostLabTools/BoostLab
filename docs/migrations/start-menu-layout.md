# Start Menu Layout Migration Record

* **Tool name:** Start Menu Layout
* **Stage:** Windows
* **Source script path:** `source-ultimate/6 Windows/2 Start Menu Layout.ps1`
* **Source checksum:** `81C1298D7C9E112DB910C4398CD94E4B70ECD97ED3B185CF2FD2B8A380E069E8`
* **Risk level:** Low
* **Required privileges:** Administrator
* **Yazan approval status:** Approved by Yazan for Phase 20

## Original Ultimate Behavior

The source exposes two console choices:

1. `Start Menu: 25H2 (Recommended)`
2. `Start Menu: 24H2`

The recommended branch writes `%SystemRoot%\Temp\newstartmenu.reg`, sets four `EnabledState` feature override values to `2`, sets `AllAppsViewMode` to `2`, and silently imports the file with `regedit.exe /S`.

The 24H2 branch writes `%SystemRoot%\Temp\oldstartmenu.reg`, deletes only the same four `EnabledState` values, sets `AllAppsViewMode` to `0`, and imports the file through the same command.

The source does not launch Settings, restart Explorer, stop processes, delete Start Menu files or shortcuts, change services, remove AppX packages, download or install content, use TrustedInstaller or Safe Mode, modify drivers or security settings, perform cleanup, sign out, or reboot.

## Approved BoostLab Behavior

Apply preserves the source 25H2 recommended branch.

Default preserves the source 24H2 branch exactly and maps it to the BoostLab `Default` action. This Phase 20 approval resolves the Phase 18 triage question about action naming. The operational behavior is not inferred or expanded.

Both actions preserve the source `.reg` payload, file name, `%SystemRoot%\Temp` path, `Set-Content` then `regedit.exe /S` execution order, registry paths, value names, value types, and values.

## Preserved Registry Paths and Values

The four feature override paths are:

```text
HKLM\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14\2792562829
HKLM\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14\3036241548
HKLM\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14\734731404
HKLM\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14\762256525
```

Apply sets `EnabledState = 2` in that order. Default removes only `EnabledState` from those four paths.

Both branches also use:

```text
HKCU\Software\Microsoft\Windows\CurrentVersion\Start
```

Apply sets `AllAppsViewMode = 2` for list view. Default sets `AllAppsViewMode = 0` for category view.

## Preserved Commands and File Paths

```powershell
Set-Content -Path "$env:SystemRoot\Temp\newstartmenu.reg" -Value $NewStartMenu -Force
Start-Process -Wait "regedit.exe" -ArgumentList "/S `"$env:SystemRoot\Temp\newstartmenu.reg`"" -WindowStyle Hidden

Set-Content -Path "$env:SystemRoot\Temp\oldstartmenu.reg" -Value $OldStartMenu -Force
Start-Process -Wait "regedit.exe" -ArgumentList "/S `"$env:SystemRoot\Temp\oldstartmenu.reg`"" -WindowStyle Hidden
```

## Intentional Deviations

The console menu, self-elevation block, `Clear-Host`, `Write-Host`, loop, and `exit` are replaced by BoostLab GUI actions, application/runtime elevation, Action Plan confirmation, logging, and structured results.

The source calls its second branch `24H2`, not `Default`. Phase 20 explicitly approves that narrow source branch as the BoostLab Default. No unrelated inverse behavior was invented.

BoostLab checks the `regedit.exe` exit code and reports file-write or import failures. It verifies the five source registry states and the expected temporary `.reg` file content after each action.

The source leaves the temporary `.reg` files in place. BoostLab preserves that behavior and adds no cleanup.

## Capabilities

`RequiresAdmin = true`; `CanModifyRegistry = true`; `SupportsDefault = true`; `NeedsExplicitConfirmation = true`.

Internet, reboot, service, installer, download, driver, security, file deletion, TrustedInstaller, Safe Mode, and Restore capabilities are false.

## Confirmation and Restart

Apply and Default require visible Action Plan confirmation. Neither action restarts Windows, signs out, restarts Explorer, or stops Start Menu processes.

## Default Behavior

Default imports the complete Ultimate 24H2 branch:

* Remove only the four source-defined `EnabledState` values.
* Set `AllAppsViewMode = 0`.
* Preserve the source write/import order.

It does not delete the feature override keys, shortcuts, Start Menu database files, pinned items, or user files.

## Verification Strategy

BoostLab verifies five registry states and one file state.

* Apply expects each `EnabledState` to equal `2`, `AllAppsViewMode` to equal `2`, and `newstartmenu.reg` to contain the approved payload.
* Default expects each `EnabledState` to be absent, `AllAppsViewMode` to equal `0`, and `oldstartmenu.reg` to contain the approved payload.
* `Passed`: every detected state matches.
* `Warning`: one or more registry or file states cannot be read.
* `Failed`: a detected value, absence state, or file content contradicts the expected result.

Command completion and verification status remain separate. Explorer, Start Menu, sign-out, or a later session may be required before the visual layout refreshes, but BoostLab does not force that refresh.

## Test Requirements

Validate the source checksum and safety gate, exact `.reg` payloads, file names, import command, execution order, four feature override paths, `AllAppsViewMode`, Apply and Default results, confirmation plans, verification Passed/Warning/Failed outcomes, runtime mapping, Latest Result rendering, source-ultimate integrity, deleted-tool exclusion, and unchanged Theme Black, GameBar, Copilot, and GameMode modules. Automated tests must use mocks and must not write the real registry, modify Start Menu files, launch regedit, stop processes, sign out, or reboot.
