# Widgets Migration Record

* **Tool name:** Widgets
* **Stage:** Windows
* **Source script path:** `source-ultimate/6 Windows/7 Widgets.ps1`
* **Source checksum:** `7A530557AA503EE038BDF910007D6A496DABFE61FA0D8818C189774E33892A73`
* **Risk level:** Low
* **Required privileges:** Administrator
* **Yazan approval status:** Approved by Yazan

## Original Ultimate Behavior

The source presents `Widgets: Off (Recommended)` and `Widgets: Default`.

Off sets the PolicyManager `AllowNewsAndInterests` value to `0`, sets the Dsh `AllowNewsAndInterests` policy value to `0`, then force-stops `Widgets` and `WidgetService` if present.

Default sets the PolicyManager `AllowNewsAndInterests` value to `1`, then deletes the `HKLM\SOFTWARE\Policies\Microsoft\Dsh` policy key.

The repository source is numbered `7 Widgets.ps1`; the Phase 13 request referred to number 8, but the approved tool and behavior match the numbered source above.

## Approved BoostLab Behavior

Apply maps to Ultimate's Widgets Off option. Default maps to Ultimate's Widgets Default option. The registry operations and execution order are preserved. Apply targets only `Widgets` and `WidgetService`; an absent process is not an error.

## Preserved Commands and Registry Paths

```powershell
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" /v "value" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d "0" /f
Stop-Process -Force -Name Widgets
Stop-Process -Force -Name WidgetService

reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" /v "value" /t REG_DWORD /d "1" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /f
```

## Intentional Deviations

The original script suppresses command output and ignores process-stop errors. BoostLab checks each registry command result and returns structured errors. It ignores a missing Widgets process as the original intended, but reports a failure when a process remains running after a failed stop attempt.

The original script self-elevates and uses a console menu. BoostLab preserves Administrator enforcement at application/runtime level and maps the two menu choices to confirmed GUI actions.

## Side Effects

Apply changes machine policy values and closes running Widgets components. Default changes the PolicyManager value and removes the original Dsh blocking policy key. The taskbar may update immediately or when Windows refreshes policy state.

## Capabilities

`RequiresAdmin = true`; `CanModifyRegistry = true`; `SupportsDefault = true`; `NeedsExplicitConfirmation = true`.

No internet, reboot, service, installer, download, driver, security, deletion, TrustedInstaller, or Safe Mode capability is declared.

## Confirmation and Restart

Apply and Default require an Action Plan confirmation. Neither action restarts the computer.

## Default Behavior

Default preserves Ultimate's approved behavior: set the PolicyManager `value` to `1` and delete `HKLM\SOFTWARE\Policies\Microsoft\Dsh`.

## Test Requirements

Validate the source checksum, exact registry paths, names, data values, command order, process target allowlist, Apply/Default metadata, capabilities, confirmation plans, runtime mapping, structured result fields, and absence of unrelated commands. Automated tests must not invoke Apply or Default.
