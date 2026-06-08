# Sound Migration Record

* **Tool name:** Sound
* **Stage:** Windows
* **Source script path:** `source-ultimate/6 Windows/16 Sound.ps1`
* **Source checksum:** `08FDB346A40595C68FF01D8F0882AC82D8BE27F66D83B400FD5691388B35929B`
* **Risk level:** Low
* **Required privileges:** BoostLab application context; catalog currently requires Administrator
* **Yazan approval status:** Approved by Yazan

## Original Ultimate Behavior

Open the Windows Sound Control Panel applet.

## Approved BoostLab Behavior

The Open action launches the exact built-in Control Panel applet from Ultimate.

## Preserved Commands

`Start-Process "mmsys.cpl"`

## Intentional Deviations

None in operational behavior. The BoostLab module adds structured success and failure results around the original launcher.

## Side Effects

Launches the built-in Sound UI only.

## Capabilities

`RequiresAdmin = true`; all other capabilities, including explicit confirmation, are false.

## Default, Restore, and Restart

No Default, Restore, or restart behavior exists.

## Test Requirements

Validate the exact source checksum and launcher, Open-only metadata, safe capability set, structured module contract, and absence of system-changing commands. Automated tests must not execute Open.
