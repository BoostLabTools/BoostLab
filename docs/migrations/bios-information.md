# BIOS Information Migration Record

* **Tool name:** BIOS Information
* **Stage:** Check
* **Source script path:** `source-ultimate/1 Check/1 BIOS Information.ps1`
* **Source checksum:** `A5BB6A0DABC156A26D9767500BDA528BFDE9C61955FE814014F6663B8224EDBC`
* **Risk level:** Low
* **Required privileges:** BoostLab application context; catalog currently requires Administrator
* **Yazan approval status:** Approved by Yazan

## Original Ultimate Behavior

Read the motherboard product with `Get-CimInstance Win32_BaseBoard`, escape it for a URL, and open a Google search.

## Approved BoostLab Behavior

`Analyze` performs read-only collection of motherboard, BIOS, system, Secure Boot, TPM, CPU, and Windows information. `Open` launches an escaped Google search using only the detected motherboard/baseboard product model. It does not download or run an updater.

## Preserved Commands

* `Get-CimInstance` motherboard detection
* `[System.Uri]::EscapeDataString(...)`
* `Start-Process` with a Google search URL

## Intentional Deviations

The assistant collects additional read-only information and adds an explicit `Analyze` action. The `Open` search query preserves the original product-only source behavior. Internet availability and individual detection failures are handled gracefully. If the motherboard/baseboard product model is unavailable, `Open` fails closed with `MotherboardModelUnavailable` instead of broadening the query with vendor, BIOS version, or generic update text.

## Side Effects

`Analyze` has no intended system side effects. `Open` launches the default browser.

## Capabilities

`RequiresAdmin = true`, `RequiresInternet = true`; all modification, download, installation, deletion, reboot, Safe Mode, TrustedInstaller, Default, and Restore capabilities are false. Explicit confirmation is not required.

## Default, Restore, and Restart

No Default or Restore action exists. The tool cannot restart the system.

## Test Requirements

Validate the structured analysis fields, escaped search construction, lack of download behavior, approved Open command, module action list, and source checksum. Tests must not execute Open.
