# Updates Pause Migration Record

* **Tool name:** Updates Pause
* **Stage:** Setup
* **Source script path:** `source-ultimate/3 Setup/8 Updates Pause.ps1`
* **Source checksum:** `4BBEF16C51FBEBAFAECB58307F8C619A37CD10BB3DC489BD4DF9A59DDBD1A0BD`
* **Risk level:** Low
* **Required privileges:** Administrator
* **Yazan approval status:** Approved by Yazan

## Original Ultimate Behavior

The source calculates a UTC start time and an expiry time 365 days in the future. It writes six values under:

```text
HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings
```

The values are written in this order:

1. `PauseUpdatesExpiryTime` = expiry
2. `PauseFeatureUpdatesEndTime` = expiry
3. `PauseFeatureUpdatesStartTime` = start
4. `PauseQualityUpdatesEndTime` = expiry
5. `PauseQualityUpdatesStartTime` = start
6. `PauseUpdatesStartTime` = start

The source then runs:

```powershell
Start-Process ms-settings:windowsupdate
```

It contains no service, download, installer, driver, cleanup, Defender, security, TrustedInstaller, Safe Mode, or reboot behavior.

## Approved BoostLab Behavior

Apply preserves the source timestamp calculation, registry path, value names, value order, 365-day interval, UTC format, and Windows Update Settings launcher.

Default removes only the same six pause timestamp values and then opens the same Windows Update Settings page. It does not change Windows Update services, driver policy, delivery optimization, restart policy, or any other Windows Update setting.

## Preserved Commands and Registry Paths

```powershell
$pause = (Get-Date).AddDays(365)
$today = Get-Date
$today = $today.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$pause = $pause.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -Value $pause -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseFeatureUpdatesEndTime" -Value $pause -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseFeatureUpdatesStartTime" -Value $today -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseQualityUpdatesEndTime" -Value $pause -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseQualityUpdatesStartTime" -Value $today -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesStartTime" -Value $today -Force
Start-Process ms-settings:windowsupdate
```

## Intentional Deviations

The Ultimate source has no menu or Default branch. Phase 17 explicitly approves a reversible Default action. BoostLab implements that action by removing only the six values written by Apply. No additional Windows Update behavior is inferred.

Default is idempotent. If all six values are already absent, BoostLab skips the unnecessary removals, opens Windows Update Settings, verifies the absent values, and reports that the tool is already default.

The source self-elevates and uses console-only presentation. BoostLab uses application/runtime Administrator enforcement, Action Plan confirmation, structured logging, and Latest Result presentation.

The source suppresses registry output and has no verification. BoostLab reports individual write/removal or Settings launch failures and verifies every value.

## Side Effects

Apply pauses Windows feature, quality, and general update state through the six source timestamps for approximately 365 days. Default removes those timestamps. Both actions open the built-in Windows Update Settings page.

Windows may require the Settings page to refresh before its visible status changes. BoostLab does not stop services, install or download content, modify drivers or security policy, restart Explorer, sign out, or reboot.

## Capabilities

`RequiresAdmin = true`; `CanModifyRegistry = true`; `SupportsDefault = true`; `NeedsExplicitConfirmation = true`.

Internet, reboot, service, installer, download, driver, security, file deletion, TrustedInstaller, Safe Mode, and Restore capabilities are false.

## Confirmation and Restart

Apply and Default require Action Plan confirmation. Neither action restarts the computer.

## Default Behavior

Default removes only:

```text
PauseUpdatesExpiryTime
PauseFeatureUpdatesEndTime
PauseFeatureUpdatesStartTime
PauseQualityUpdatesEndTime
PauseQualityUpdatesStartTime
PauseUpdatesStartTime
```

from `HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings`.

## Verification Strategy

After Apply or Default, BoostLab reads all six values.

* Apply expects each start value to equal the generated UTC start timestamp and each end/expiry value to equal the generated UTC timestamp 365 days in the future.
* Default expects all six values to be absent.
* `Passed`: every detected value matches.
* `Warning`: a command completed but one or more values could not be read.
* `Failed`: a detected value contradicts the expected state.

Command completion, Settings launch status, and verification status remain separate.

## Test Requirements

Validate the source checksum, safety gate, exact registry path, six value names, UTC format, 365-day interval, write order, Settings URI, Default removal scope, idempotency, metadata, capabilities, confirmation plans, verification outcomes, structured result fields, runtime mapping, UI rendering, and absence of unrelated behavior. Automated tests must not modify the real registry, launch Settings, stop services, or execute tool actions through the production runtime.
