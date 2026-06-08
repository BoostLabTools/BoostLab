# BIOS Settings Migration Record

* **Tool name:** BIOS Settings
* **Stage:** Check
* **Source script path:** `source-ultimate/1 Check/2 BIOS Settings.ps1`
* **Source checksum:** `C68BDADC7EEAC77A0FE8ECE999CEB5A28C51D819D69107AFD471739BA36E2737`
* **Risk level:** High
* **Required privileges:** Administrator
* **Yazan approval status:** Approved by Yazan

## Original Ultimate Behavior

Display Intel, AMD, cooling, and motherboard utility guidance, pause for the user, then invoke `shutdown.exe /r /fw /t 0` through `cmd` to restart into firmware.

## Approved BoostLab Behavior

`Analyze` returns the original guidance concept as structured sections and warnings. `Open` preserves the restart-to-UEFI result, but only after an explicit GUI confirmation that the PC will restart immediately.

## Preserved Commands

* Original Intel, AMD, cooling, and motherboard utility guidance
* `cmd /c ...shutdown.exe /r /fw /t 0`

The module resolves `cmd.exe` and `shutdown.exe` from the Windows system directory before invocation.

## Intentional Deviations

Console output and `Pause` became structured results and an explicit Yes/No GUI confirmation defaulting to No. Clear warnings were added. No Google search behavior is permitted.

## Side Effects

`Analyze` is read-only. Confirmed `Open` schedules an immediate restart and attempts to enter BIOS/UEFI firmware settings.

## Capabilities

`RequiresAdmin = true`, `CanReboot = true`, and `NeedsExplicitConfirmation = true`. All registry, service, software, download, driver, security, deletion, Safe Mode, TrustedInstaller, Default, and Restore capabilities are false.

## Default, Restore, and Restart

No Default or Restore action exists. Restart occurs only for a confirmed Open request.

## Test Requirements

Validate guidance fidelity, high-risk metadata, confirmation text, cancellation without execution, exact firmware restart arguments, absence of search/download behavior, BIOS Information independence, and source checksum. Automated tests must never confirm Open.
