# MMAgent Assistant Migration Record

* **Tool name:** MMAgent Assistant
* **Stage:** Advanced
* **Source script path:** `source-ultimate/8 Advanced/2 MMAgent Assistant.ps1`
* **Source checksum:** `5B53236C5CC6B2E791A7F2E2E7A0B36EC7F3662628CADE9A64013664B0A0AF97`
* **Risk level:** High
* **Required privileges:** Administrator
* **Yazan approval status:** Approved by Yazan for Phase 28

## Original Ultimate Behavior

The source presents three console choices:

* `Off`
* `Default`
* `Check`

`Off` performs these exact operations:

```powershell
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d "0" /f
Disable-MMAgent -ApplicationLaunchPrefetching
Disable-MMAgent -ApplicationPreLaunch
Set-MMAgent -MaxOperationAPIFiles 1
Disable-MMAgent -MemoryCompression
Disable-MMAgent -OperationAPI
Disable-MMAgent -PageCombining
```

`Default` performs these exact operations:

```powershell
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d "3" /f
Enable-MMAgent -ApplicationLaunchPrefetching
Enable-MMAgent -ApplicationPreLaunch
Set-MMAgent -MaxOperationAPIFiles 512
Disable-MMAgent -MemoryCompression
Enable-MMAgent -OperationAPI
Disable-MMAgent -PageCombining
```

`Check` prints:

* `SETTINGS MAY TAKE A WHILE TO INITIALIZE AFTER REBOOT`
* `WAIT A SHORT PERIOD BEFORE CHECKING`

Then it runs:

```powershell
Get-MMAgent
```

The source self-elevates before showing the console menu. It does not reboot, install software, use TrustedInstaller, or change services.

## Approved BoostLab Behavior

BoostLab preserves the source behavior as an implemented assistant:

* `Analyze` replaces the source `Check` branch.
* `Apply` maps to the source `Off` branch.
* `Default` maps to the source `Default` branch.

The assistant remains high-risk because it changes multiple Windows memory-management features together. It uses Action Plan confirmation for `Apply` and `Default`.

## Preserved Commands

```powershell
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d "3" /f
Disable-MMAgent -ApplicationLaunchPrefetching
Disable-MMAgent -ApplicationPreLaunch
Set-MMAgent -MaxOperationAPIFiles 1
Set-MMAgent -MaxOperationAPIFiles 512
Disable-MMAgent -MemoryCompression
Disable-MMAgent -OperationAPI
Enable-MMAgent -ApplicationLaunchPrefetching
Enable-MMAgent -ApplicationPreLaunch
Enable-MMAgent -OperationAPI
Disable-MMAgent -PageCombining
Get-MMAgent
```

## Important Preserved Meaning

The source `Default` branch does **not** restore every MMAgent feature to a Windows stock state.

BoostLab preserves that meaning exactly:

* `MemoryCompression` remains disabled in `Default`.
* `PageCombining` remains disabled in `Default`.

MemoryCompression remains disabled in `Default`.
PageCombining remains disabled in `Default`.

This must remain distinct from the separate `Memory Compression` tool, whose `Default` behavior re-enables only `MemoryCompression`.

## Intentional Deviations

BoostLab replaces `Read-Host`, `Write-Host`, `Clear-Host`, `Pause`, and `Exit` with:

* GUI actions
* Action Plan confirmation
* structured results
* Activity Log entries
* read-only verification

BoostLab also uses `-ErrorAction Stop` around MMAgent command execution so failures are reported clearly instead of being hidden.

These deviations change the interface and reporting layer only. They do not weaken the approved operational behavior.

## Side Effects

Apply and Default can change:

* Prefetcher behavior
* ApplicationLaunchPrefetching
* ApplicationPreLaunch
* MaxOperationAPIFiles
* MemoryCompression
* OperationAPI
* PageCombining

The source warns that settings may take time to initialize after reboot before a later check is fully representative. BoostLab does not reboot automatically.

## Capabilities

* `RequiresAdmin = true`
* `RequiresInternet = false`
* `CanReboot = false`
* `CanModifyRegistry = true`
* `CanModifyServices = false`
* `CanInstallSoftware = false`
* `CanDownload = false`
* `CanModifyDrivers = false`
* `CanModifySecurity = false`
* `CanDeleteFiles = false`
* `UsesTrustedInstaller = false`
* `UsesSafeMode = false`
* `SupportsDefault = true`
* `SupportsRestore = false`
* `NeedsExplicitConfirmation = true`

## Confirmation Behavior

`Analyze` is read-only and does not require confirmation.

`Apply` and `Default` require Action Plan confirmation. The plan must clearly show that:

* Administrator rights are required.
* Multiple MMAgent features are changed together.
* The approved source `Default` still keeps `MemoryCompression` and `PageCombining` disabled.

## Verification Strategy

After `Apply` or `Default`, BoostLab verifies:

* `EnablePrefetcher`
* `ApplicationLaunchPrefetching`
* `ApplicationPreLaunch`
* `MaxOperationAPIFiles`
* `MemoryCompression`
* `OperationAPI`
* `PageCombining`

Verification uses `Get-MMAgent` plus the source-defined `EnablePrefetcher` registry value.

* `Passed` means every detected value matches the expected source profile.
* `Warning` means one or more values could not be detected.
* `Failed` means a detected value contradicts the expected source profile.

## Test Requirements

Validate:

* source checksum
* exact Apply and Default command intent
* explicit preservation of `MemoryCompression = False` and `PageCombining = False` in `Default`
* Action Plan confirmation behavior
* runtime mapping
* structured Analyze, Apply, and Default results
* verification result structure
* no reboot/download/service/TrustedInstaller behavior
* source-ultimate integrity
* permanent Loudness EQ deletion

Automated tests must be static or mocked only and must not change the real MMAgent state.
