# Restore Point Migration Record

* **Tool name:** Restore Point
* **Stage:** Windows
* **Source script path:** `source-ultimate/6 Windows/23 Restore Point.ps1`
* **Source checksum:** `0FCC75B291F40F234632BA44A2705B31BA7EBC29FE817D42630A953D0D10A451`
* **Risk level:** Medium
* **Required privileges:** Administrator
* **Yazan approval status:** Approved by Yazan

## Original Ultimate Behavior

Temporarily set `SystemRestorePointCreationFrequency` to `0`, enable System Restore on `C:\`, create a restore point named `backup` with type `MODIFY_SETTINGS`, remove the temporary frequency override, then open System Protection and Windows System Restore.

The repository source is numbered `23 Restore Point.ps1`; the Phase 12 request referred to number 36, but the approved tool and behavior match the numbered source above.

## Approved BoostLab Behavior

Apply preserves the original restore-point creation sequence. Open preserves both original Windows UI launchers. BoostLab does not run the Ultimate script directly.

## Preserved Commands

```powershell
cmd /c reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "SystemRestorePointCreationFrequency" /t REG_DWORD /d "0" /f
Enable-ComputerRestore -Drive "C:\"
Checkpoint-Computer -Description "backup" -RestorePointType "MODIFY_SETTINGS"
cmd /c reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "SystemRestorePointCreationFrequency" /f
Start-Process "$env:SystemRoot\system32\control.exe" -ArgumentList "sysdm.cpl,,4"
Start-Process "rstrui"
```

## Intentional Deviations

The original script silently catches restore-point failures. BoostLab returns structured failures, records the outcome, and attempts removal of the temporary frequency override in `finally`. Console-only output, pause, clear, and exit behavior are replaced by the GUI action plan, confirmation, Activity Log, and Latest Result.

The original script self-elevates. BoostLab preserves the Administrator requirement at application and runtime levels rather than launching a second copy from the module.

## Side Effects

Apply may enable System Restore on `C:\`, creates a restore point that consumes System Protection storage, and temporarily changes one System Restore registry value. Open launches built-in Windows interfaces only.

## Capabilities

`RequiresAdmin = true`; `CanModifyRegistry = true`; `NeedsExplicitConfirmation = true`.

No internet, reboot, service, installer, download, driver, security, deletion, TrustedInstaller, or Safe Mode capability is declared. Default and Restore actions are not supported.

## Confirmation and Restart

Apply requires an Action Plan confirmation that states System Restore may be enabled and a restore point named `backup` will be created. Open does not require confirmation. Neither action restarts the computer.

## Default and Rollback

No Default action is defined. The module removes the temporary creation-frequency override after the operation. It does not delete restore points or disable System Restore.

## Test Requirements

Validate the source checksum, exact command intent and execution order, Apply/Open metadata, capabilities, confirmation plan, structured result contract, runtime allowlist, exact UI launchers, and absence of unrelated system-changing commands. Automated tests must not invoke Apply or Open.
