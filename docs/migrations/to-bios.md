# To BIOS Migration Record

* **Tool name:** To BIOS
* **Stage:** Refresh
* **Source script path:** `source-ultimate/2 Refresh/4 To Bios.ps1`
* **Source checksum:** `A8371B42B235A6AC1F9661D96B430BEC0E4CAB6D9DE3CBD1461A02572220CA0C`
* **Risk level:** High
* **Required privileges:** Administrator
* **Yazan approval status:** Approved by Yazan for Phase 31

## Original Ultimate Behavior

Require Administrator rights, tell the technician to press Enter to restart to BIOS, pause for user input, and run:

```text
cmd /c C:\Windows\System32\shutdown.exe /r /fw /t 0
```

## Approved BoostLab Behavior

`Analyze` displays the restart behavior, exact approved command, compatibility limitations, and save-work warning without executing anything.

`Open` preserves the original restart-to-firmware result. The runtime must first display the existing BoostLab Action Plan confirmation. Declining confirmation performs no command. Confirming runs the source-defined command through the Windows system `cmd.exe` and `shutdown.exe` paths.

## Preserved Commands

* `cmd /c C:\Windows\System32\shutdown.exe /r /fw /t 0`

The module resolves both executables beneath `$env:SystemRoot\System32` before invocation and does not accept executable paths from configuration.

## Intentional Deviations

Ultimate's console `Pause` is replaced by an explicit GUI confirmation that clearly states the computer will restart immediately. `Analyze` was added as a read-only assistant action because the approved catalog defines `Analyze` and `Open`.

No BIOS setting, registry value, BCD entry, service, driver, download, installer, or firmware file behavior was added.

## Side Effects

A confirmed `Open` request restarts Windows immediately and asks supported firmware to enter BIOS/UEFI settings. Unsaved work can be lost. Firmware or Windows may reject the request on unsupported systems.

## Capabilities

* `RequiresAdmin = true`
* `RequiresInternet = false`
* `CanReboot = true`
* `CanModifyRegistry = false`
* `CanModifyServices = false`
* `CanInstallSoftware = false`
* `CanDownload = false`
* `CanModifyDrivers = false`
* `CanModifySecurity = false`
* `CanDeleteFiles = false`
* `UsesTrustedInstaller = false`
* `UsesSafeMode = false`
* `SupportsDefault = false`
* `SupportsRestore = false`
* `NeedsExplicitConfirmation = true`

## Confirmation and Restart

The Action Plan confirmation must state that the PC will restart immediately and attempt to enter BIOS/UEFI firmware settings. Confirmation defaults to cancellation. No Default or Restore action exists.

## Verification Strategy

Before execution, the module verifies that the Windows system directory, `cmd.exe`, and `shutdown.exe` exist. After confirmed invocation, exit code `0` is reported as Windows accepting the restart request. This does not claim that firmware successfully displayed its settings page because that can only be observed after restart.

## Test Requirements

Automated tests must:

* validate the source checksum and exact command arguments
* validate high-risk reboot capability metadata
* validate the Action Plan and confirmation text
* validate Analyze output
* validate declined Open without executing a restart command
* validate runtime allowlisting and structured result fields
* never call `Open` with confirmation
