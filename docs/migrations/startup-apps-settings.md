# Startup Apps Settings Migration Record

* **Tool name:** Startup Apps (Settings)
* **Stage:** Setup
* **Source script path:** `source-ultimate/3 Setup/3 Startup Apps (Settings).ps1`
* **Source checksum:** `15895826F14392D72F54BDDEB3D21F3E482289E0A6CAC057366C0E6E34D45DF7`
* **Risk level:** Low
* **Required privileges:** BoostLab application context; catalog currently requires Administrator
* **Yazan approval status:** Approved by Yazan

## Original Ultimate Behavior

Open the Windows Startup Apps Settings page.

## Approved BoostLab Behavior

The Open action launches the same built-in Windows Settings URI.

## Preserved Commands

`Start-Process "ms-settings:startupapps"`

## Intentional Deviations

The legacy console wrapper and self-elevation flow are handled by the BoostLab application. The launcher behavior is unchanged.

## Side Effects

Launches Windows Settings only.

## Capabilities

`RequiresAdmin = true`; all other capabilities, including explicit confirmation, are false.

## Default, Restore, and Restart

No Default, Restore, or restart behavior exists.

## Test Requirements

Validate the exact launcher text, Open-only action list, lack of other system-changing commands, and source checksum without executing Open.
