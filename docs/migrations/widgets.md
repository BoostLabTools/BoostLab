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

Default is idempotent: when a read confirms that the Dsh key or `AllowNewsAndInterests` value is already absent, BoostLab skips the unnecessary delete command and reports the state as already default. This preserves Ultimate's effective result while avoiding a false command error from `reg delete`.

The original script self-elevates and uses a console menu. BoostLab preserves Administrator enforcement at application/runtime level and maps the two menu choices to confirmed GUI actions.

## Side Effects

Apply changes machine policy values and closes running Widgets components. Default changes the PolicyManager value and removes the original Dsh blocking policy key. The taskbar may update immediately or when Windows refreshes policy state.

## Capabilities

`RequiresAdmin = true`; `CanModifyRegistry = true`; `SupportsDefault = true`; `NeedsExplicitConfirmation = true`.

No internet, reboot, service, installer, download, driver, security, deletion, TrustedInstaller, or Safe Mode capability is declared.

## Confirmation and Restart

Apply and Default require an Action Plan confirmation. Neither action restarts the computer.

## Default Behavior

Default preserves Ultimate's approved behavior: set the PolicyManager `value` to `1` and remove the Dsh blocking policy when present. If the Dsh key or `AllowNewsAndInterests` value is already absent, no deletion is required and the action remains successful.

## Verification Strategy

After Apply or Default completes, BoostLab performs read-only checks of:

* `HKLM:\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests` value `value`
* `HKLM:\SOFTWARE\Policies\Microsoft\Dsh` value `AllowNewsAndInterests`
* Running state of `Widgets`
* Running state of `WidgetService`

Apply expects PolicyManager `value = 0`, Dsh `AllowNewsAndInterests = 0`, and both approved process targets not running. Missing processes pass verification. Unreadable process state produces a warning; a contradictory registry value or a still-running process produces a failure.

Default expects PolicyManager `value = 1` and the Dsh blocking value absent or not equal to `0`. Process state is informational and Widgets is never force-started. An unreadable Dsh state produces a warning; PolicyManager remaining at `0`, another unexpected PolicyManager value, or Dsh still blocking Widgets produces a failure.

Command completion and verification are reported separately. A successful command path can therefore have a verification warning or failure.

Windows may delay the taskbar's visual update even after registry verification passes. A policy refresh, sign-out, taskbar refresh, or later Windows session may be required. BoostLab does not restart Explorer or reboot to force the visual change.

## Test Requirements

Validate the source checksum, exact registry paths, names, data values, command order, process target allowlist, Apply/Default metadata, capabilities, confirmation plans, verification outcomes, runtime mapping, structured result fields, and absence of unrelated commands. Automated tests must not invoke the real Apply or Default command paths.
