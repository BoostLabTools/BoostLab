# Graphics Configuration Center Migration Record

* **Tool name:** Graphics Configuration Center
* **Stage:** Graphics
* **Source script path:** `source-ultimate/5 Graphics/4 Graphics Configuration Center.ps1`
* **Source checksum:** `5D8438C6E6CBB7AA87111518F24689095382F72F76DD72E64CBBF3019B9B13CA`
* **Risk level:** Low
* **Required privileges:** BoostLab application context; catalog currently requires Administrator
* **Yazan approval status:** Approved by Yazan

## Original Ultimate Behavior

Open the Windows advanced graphics Settings page.

## Approved BoostLab Behavior

The Open action launches the same built-in Windows Settings URI.

## Preserved Commands

`Start-Process "ms-settings:display-advancedgraphics"`

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
