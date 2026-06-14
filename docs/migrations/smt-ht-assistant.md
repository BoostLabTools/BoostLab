# SMT / HT Assistant Migration Record

* **Tool name:** SMT / HT Assistant
* **Stage:** Advanced
* **Source script path:** `source-ultimate/8 Advanced/4 SMT  HT Assistant.ps1`
* **Source checksum:** `5D53BF2A9A589ECB14D9F8F9048FF4830D2E6F4DEE7E4B54BA6B6B6F77F004FE`
* **Risk level:** High
* **Required privileges:** Administrator
* **Yazan approval status:** Approved by Yazan for Phase 29

## Original Ultimate Behavior

The source presents two console choices:

* `Off: Already Running`
* `Off: Startup`

The source first reads `Win32_ComputerSystem.NumberOfLogicalProcessors`, then builds an alternating SMT / HT-off mask where even-indexed logical processors are `0` and odd-indexed logical processors are `1`. It pads the binary mask to a multiple of four bits and converts it to hexadecimal.

### Off: Already Running

The source:

* lists running processes with `WorkingSet64 -gt 500MB`
* prompts for a process ID
* applies `ProcessorAffinity` directly to that running process using the computed integer mask
* reloads the process and prints the resulting binary affinity value

### Off: Startup

The source:

* stops this exact launcher list:
  * `Battle.net`
  * `BsgLauncher`
  * `EADesktop`
  * `EpicGamesLauncher`
  * `GalaxyClient`
  * `RobloxPlayerBeta`
  * `RiotClientServices`
  * `Launcher`
  * `steam`
  * `upc`
* opens a file picker for a launcher, game, shortcut, or executable
* runs:

```powershell
cmd /c "start `"`" /affinity $hexadecimal `"$gamelauncher`""
```

* waits ten seconds
* checks the launched process by base file name
* prints the resulting binary affinity value

The source does not modify BIOS settings, CPU firmware settings, drivers, devices, registry, services, or boot configuration.

## Approved BoostLab Behavior

BoostLab preserves the source as an advanced assistant with these actions:

* `Analyze`
* `Apply`
* `Open`

`Analyze` is the added assistant layer required by BoostLab governance. It is read-only and reports:

* logical processor count
* generated binary mask
* generated hex mask
* candidate running processes larger than 500 MB
* the exact launcher stop list
* warnings that the workflow is temporary and per-process only

`Apply` maps to Ultimate `Off: Already Running`.

`Open` maps to Ultimate `Off: Startup`.

## Preserved Commands and Behaviors

```powershell
(Get-WmiObject Win32_ComputerSystem).NumberOfLogicalProcessors
(Get-Process | Where-Object {$_.WorkingSet64 -gt 500MB} | Select-Object Name, Id)
$smthtoff.ProcessorAffinity = $hexadecimal
Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue
cmd /c "start `"`" /affinity $hexadecimal `"$gamelauncher`""
Start-Sleep -Seconds 10
Get-Process -Name "$gamelauncher"
```

The GUI replaces `Read-Host` and the file chooser is kept as a Windows file dialog. BoostLab preserves the same launcher stop list, the same affinity-mask generation concept, the same temporary per-process scope, and the same ten-second verification delay window for the startup path.

## Intentional Deviations

BoostLab replaces console prompts and tables with:

* structured Analyze output
* a running-process selection dialog for the `Already Running` path
* a file picker dialog for the `Startup` path
* Action Plan confirmation
* structured verification and result reporting

These changes only replace the interface layer. They do not weaken the operational effect.

## Side Effects

* `Apply` changes the affinity of one selected running process only.
* `Open` stops only the approved launcher names and launches one selected file with the source affinity mask.
* The effect is temporary and process-scoped.
* BIOS SMT/HT settings are not changed.
* CPU firmware, drivers, devices, services, registry, boot settings, and reboot behavior are not changed.

## Capabilities

* `RequiresAdmin = true`
* `RequiresInternet = false`
* `CanReboot = false`
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

## Confirmation Requirements

`Analyze` is read-only and does not require confirmation.

`Apply` and `Open` require Action Plan confirmation because they change running-process behavior and can stop approved launcher processes before launch.

## Rollback / Default Behavior

The approved source does not provide a default or restore branch.

BoostLab therefore does not implement `Default` or `Restore` for this tool. The process-affinity behavior is temporary and ends when the affected process exits.

## Restart Behavior

No restart is implemented. The source does not reboot and BoostLab does not add reboot behavior.

## Verification Strategy

`Apply` verification:

* reload the selected process by ID
* compare `ProcessorAffinity` to the expected computed mask
* report binary, hex, and integer forms

`Open` verification:

* wait for the source ten-second delay window
* resolve the selected file base name
* attempt to detect a process with that base name
* compare `ProcessorAffinity` when a process is found

Statuses:

* `Passed` when the detected process affinity matches the expected mask
* `Warning` when launch completed but the target process could not be detected conclusively
* `Failed` when the detected affinity contradicts the expected mask

## Test Requirements

Validate:

* source checksum
* exact launcher stop list
* exact logical-processor mask generation behavior
* metadata and runtime mapping
* Analyze structured output
* mocked Apply verification
* mocked Open verification
* absence of BIOS, driver, device, registry, reboot, installer, and download behavior
* source-ultimate integrity
* permanent Loudness EQ deletion

Automated tests must be static or mocked only and must not modify the affinity of real user processes.
