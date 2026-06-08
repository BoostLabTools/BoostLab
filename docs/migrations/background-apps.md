# Background Apps Migration Record

* **Tool name:** Background Apps
* **Stage:** Setup
* **Source script path:** `source-ultimate/3 Setup/5 Background Apps.ps1`
* **Source checksum:** `2DF15DE03306CCAF19180940F215972E943EA94E7B2C52B7D6EC2B6403E79445`
* **Risk level:** Low
* **Required privileges:** Administrator
* **Yazan approval status:** Approved by Yazan

## Original Ultimate Behavior

The source presents `Background Apps: Off (Recommended)` and `Background Apps: Default`.

Off writes the machine policy value `LetAppsRunInBackground = 2` under `HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy`, then opens `ms-settings:privacy-backgroundapps`.

Default deletes the same policy value, then opens `ms-settings:privacy-backgroundapps`.

The source contains no service, process, download, installer, cleanup, driver, security, TrustedInstaller, Safe Mode, or reboot behavior.

## Approved BoostLab Behavior

Apply maps to Ultimate's recommended Off option. Default maps to Ultimate's Default option. The registry path, value name, DWORD data, command order, and Settings URI are preserved.

BoostLab performs the policy command first, opens the Background Apps Settings page second, and performs read-only verification afterward.

## Preserved Commands and Registry Paths

```powershell
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /t REG_DWORD /d "2" /f
Start-Process ms-settings:privacy-backgroundapps

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /f
Start-Process ms-settings:privacy-backgroundapps
```

Provider path used for read-only verification:

```text
HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy
```

## Intentional Deviations

The original script suppresses registry command output and does not verify success. BoostLab checks the command exit code, reports launch failures, and returns a structured verification result.

Default is idempotent. If BoostLab can confirm that `LetAppsRunInBackground` is already absent, it skips the unnecessary delete command, opens the original Settings page, and reports that Background Apps is already default. This preserves the effective Ultimate result while avoiding a false error from deleting an absent value.

The original script self-elevates and uses a console menu. BoostLab preserves Administrator enforcement through the application/runtime model and maps the two choices to confirmed GUI actions.

## Side Effects

Apply sets a machine-wide application privacy policy to force-deny background execution for governed Windows apps. Default removes only that policy value. Both actions open the Windows Background Apps Settings page.

Windows may require a policy refresh, sign-out, or later session before every visible effect appears. BoostLab does not restart Explorer, sign out, or reboot.

## Capabilities

`RequiresAdmin = true`; `CanModifyRegistry = true`; `SupportsDefault = true`; `NeedsExplicitConfirmation = true`.

Internet, reboot, service, installer, download, driver, security, file deletion, TrustedInstaller, Safe Mode, and Restore capabilities are false.

## Confirmation and Restart

Apply and Default require Action Plan confirmation. Neither action restarts the computer.

## Default Behavior

Default removes only:

```text
HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy\LetAppsRunInBackground
```

It does not delete the parent `AppPrivacy` key or change other application privacy policies.

## Verification Strategy

After Apply or Default, BoostLab reads:

```text
HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy\LetAppsRunInBackground
```

Apply expects the value to exist as `2`. Default expects the value to be absent.

* `Passed`: detected state matches the expected state.
* `Warning`: the command completed but the value could not be read.
* `Failed`: the detected value contradicts the expected state.

Command completion and verification status remain separate. Settings-page launch status is also returned separately.

## Test Requirements

Validate the source checksum, exact registry path, value name, DWORD data, delete behavior, execution order, Settings URI, metadata, capabilities, confirmation plans, verification outcomes, structured result fields, runtime mapping, UI rendering, and absence of unrelated commands. Automated tests must not modify the real registry or open the Settings page.
