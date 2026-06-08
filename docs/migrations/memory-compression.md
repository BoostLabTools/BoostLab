# Memory Compression Migration Record

* **Tool name:** Memory Compression
* **Stage:** Setup
* **Source script path:** `source-ultimate/3 Setup/1 Memory Compression.ps1`
* **Source checksum:** `CCBABB01D249C1206F4762579665DCE6F95F12A8D221D9A65A6310A0393C2352`
* **Risk level:** Low
* **Required privileges:** Administrator
* **Yazan approval status:** Approved by Yazan

## Original Ultimate Behavior

The source presents three console choices:

* `Memory Compression: Off (Recommended)` runs `Disable-MMAgent -MemoryCompression`.
* `Memory Compression: Enable` runs `Enable-MMAgent -MemoryCompression`.
* `Check` displays `Get-MMAgent` output and warns that the setting may take time to initialize after a reboot.

The script self-elevates before presenting the menu. It does not alter other MMAgent settings and does not initiate a reboot.

## Approved BoostLab Behavior

Apply maps to Ultimate's recommended Off option and runs only `Disable-MMAgent -MemoryCompression`.

Default maps to Ultimate's Enable option and runs only `Enable-MMAgent -MemoryCompression`.

The original console Check choice is represented by automatic read-only verification after Apply or Default rather than a separate GUI action.

## Preserved Commands

```powershell
Disable-MMAgent -MemoryCompression
Enable-MMAgent -MemoryCompression
Get-MMAgent
```

## Intentional Deviations

BoostLab uses `-ErrorAction Stop` instead of the source's `-ErrorAction SilentlyContinue` so command failures are reported clearly.

The source's `Read-Host`, `Write-Host`, `Clear-Host`, `Pause`, and `Exit` interaction is replaced by Apply and Default buttons, Action Plan confirmation, structured results, Activity Log entries, and post-action verification.

No operational strengthening or weakening is introduced. No other MMAgent setting is modified.

## Side Effects

Apply disables Windows memory compression. Default enables it again. Windows memory management behavior can change immediately, but BoostLab does not restart the computer.

## Capabilities

`RequiresAdmin = true`; `RequiresInternet = false`; `CanReboot = false`; `SupportsDefault = true`; `NeedsExplicitConfirmation = true`.

No registry, service, installer, download, driver, security, file deletion, TrustedInstaller, or Safe Mode capability is declared.

## Confirmation and Default Behavior

Apply and Default require visible Action Plan confirmation. Default restores the Ultimate approved enabled state. Neither action restarts Windows.

## Verification Strategy

After either command completes, BoostLab calls `Get-MMAgent` and reads `MemoryCompression`.

* Apply expects `MemoryCompression = False`.
* Default expects `MemoryCompression = True`.
* Verification is `Passed` when the detected value matches.
* Verification is `Warning` when the command completed but the value cannot be detected.
* Verification is `Failed` when the detected value contradicts the expected state.

Command completion and verification status are reported separately.

## Test Requirements

Validate the source checksum, exact MMAgent command switches, Apply/Default metadata, capability flags, confirmation plans, verification outcomes, runtime mapping, result rendering, and absence of unrelated MMAgent or restart behavior. Automated tests must not invoke the real Apply or Default command paths.
