# Store Settings Migration Record

* **Tool name:** Store Settings
* **Stage:** Setup
* **Source script path:** `source-ultimate/3 Setup/7 Store Settings.ps1`
* **Source checksum:** `C16EDA260DA2FA48A4830894BC44BF11FC8541A6087B4013A8C67BA7979ED0BD`
* **Risk level:** Low
* **Required privileges:** Administrator
* **Yazan approval status:** Approved by Yazan

## Original Ultimate Behavior

The source presents `Store Settings: Optimize (Recommended)` and `Store Settings: Default`.

Optimize:

1. Opens `ms-windows-store:settings`.
2. Waits five seconds.
3. Stops `WinStore.App`, `backgroundTaskHost`, and `StoreDesktopExtension`.
4. Waits two seconds.
5. Sets `AutoDownload = 2` under the WindowsStore WindowsUpdate registry path.
6. Writes an approved temporary `.reg` file containing Store video autoplay, installation notification, and personalization values.
7. Loads the current user's Microsoft Store `settings.dat` hive at `HKLM\Settings`.
8. Imports the `.reg` file.
9. Waits two seconds and unloads the hive.
10. Waits two seconds and opens Microsoft Store Settings again.

Default:

1. Deletes `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore`.
2. Stops the same three Store process targets.
3. Waits two seconds.
4. Launches hidden `wsreset.exe`.
5. Stops the same three Store process targets again.
6. Waits two seconds and opens Microsoft Store Settings.

The source contains no service, download, installer, driver, Defender, TrustedInstaller, Safe Mode, or reboot behavior.

## Approved BoostLab Behavior

Apply maps to Ultimate's Optimize option. Default maps to Ultimate's Default option. Registry paths, values, process targets, Store launchers, waits, hive operations, and execution order are preserved.

BoostLab reports failures instead of suppressing them and returns structured command, process, UI, and verification details.

## Preserved Commands and Registry Paths

```powershell
Start-Process "ms-windows-store:settings"

Stop-Process -Name WinStore.App -Force
Stop-Process -Name backgroundTaskHost -Force
Stop-Process -Name StoreDesktopExtension -Force

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" /v "AutoDownload" /t REG_DWORD /d "2" /f
reg load "HKLM\Settings" "<LocalAppData>\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\Settings\settings.dat"
reg import "<SystemRoot>\Temp\windowsstore.reg"
reg unload "HKLM\Settings"

reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore" /f
Start-Process "wsreset.exe" -WindowStyle Hidden
```

The imported Store values are:

```text
HKLM\Settings\LocalState\VideoAutoplay
hex(5f5e10b):00,96,9d,69,8d,cd,93,dc,01

HKLM\Settings\LocalState\EnableAppInstallNotifications
hex(5f5e10b):00,36,d0,88,8e,cd,93,dc,01

HKLM\Settings\LocalState\PersistentSettings\PersonalizationEnabled
hex(5f5e10b):00,0d,56,a1,8a,cd,93,dc,01
```

## Intentional Deviations

The original script suppresses registry and process errors. BoostLab checks registry command results, confirms whether approved process targets stopped, and reports failures clearly.

The original initial Store Settings launch is wrapped in an empty catch. BoostLab preserves it as best-effort behavior but records a warning when it fails.

Default is registry-idempotent: if the complete WindowsStore registry path is already absent, BoostLab skips only the unnecessary delete command. It still preserves the original process-stop, `wsreset.exe`, second process-stop, delay, and Store Settings launch sequence.

The original script self-elevates and uses a console menu. BoostLab uses application/runtime Administrator enforcement and confirmed GUI Apply/Default actions.

## Side Effects

Apply disables automatic Store app downloads, disables Store video autoplay and app installation notifications, disables Store personalized experiences, closes approved Store processes, and opens Store Settings.

Default removes the approved WindowsStore registry key, closes approved Store processes, launches the built-in Store reset, and opens Store Settings. `wsreset.exe` may clear Microsoft Store cache and refresh Store state.

The temporary file is:

```text
<SystemRoot>\Temp\windowsstore.reg
```

BoostLab does not add file deletion or unrelated cleanup behavior because the source does not remove this file.

## Capabilities

`RequiresAdmin = true`; `CanModifyRegistry = true`; `SupportsDefault = true`; `NeedsExplicitConfirmation = true`.

Internet, reboot, service, installer, download, driver, security, file deletion, TrustedInstaller, Safe Mode, and Restore capabilities are false.

## Confirmation and Restart

Apply and Default require Action Plan confirmation. Neither action restarts the computer.

## Default Behavior

Default preserves the source behavior: remove the complete approved WindowsStore key, stop the approved Store processes, launch `wsreset.exe`, stop the same processes again, and open Store Settings.

It does not modify other Store, Windows Update, application privacy, service, or package settings.

## Verification Strategy

Apply verifies:

* `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate\AutoDownload = 2`
* `HKLM:\Settings\LocalState\VideoAutoplay` while the Store hive is mounted
* `HKLM:\Settings\LocalState\EnableAppInstallNotifications` while the Store hive is mounted
* `HKLM:\Settings\LocalState\PersistentSettings\PersonalizationEnabled` while the Store hive is mounted

Default verifies that:

* `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore` is absent

Verification results are:

* `Passed` when every expected state is detected.
* `Warning` when a command completed but a value or path could not be read.
* `Failed` when a detected value or path contradicts the expected state.

Command completion, process actions, Store UI actions, and verification status remain separate.

## Test Requirements

Validate the source checksum, exact registry paths, value names, binary data, process allowlist, waits, execution order, Store Settings URI, `wsreset.exe`, metadata, capabilities, confirmation plans, verification outcomes, structured result fields, runtime mapping, UI rendering, and absence of unrelated behavior. Automated tests must not modify the real registry, stop real processes, write the temporary `.reg` file, launch Store UI, or run `wsreset.exe`.
