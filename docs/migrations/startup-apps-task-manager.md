# Startup Apps Task Manager Migration Record

* **Tool name:** Startup Apps (Task Manager)
* **Stage:** Setup
* **Source script path:** `source-ultimate/3 Setup/4 Startup Apps (Task Manager).ps1`
* **Source checksum:** `EB648780E90F95A7A65CD25EDF21CCDFC1BFEA92705AEF0AC88C97B41989ABF6`
* **Risk level:** Low
* **Required privileges:** BoostLab application context; catalog currently requires Administrator
* **Yazan approval status:** Approved by Yazan

## Original Ultimate Behavior

Open Task Manager on its Startup page.

## Approved BoostLab Behavior

The Open action launches Task Manager with the original argument string.

## Preserved Commands

`Start-Process "taskmgr" -ArgumentList " /0 /startup"`

## Intentional Deviations

The legacy console wrapper and self-elevation flow are handled by the BoostLab application. The launcher behavior and argument string are unchanged.

## Side Effects

Launches Task Manager only.

## Capabilities

`RequiresAdmin = true`; all other capabilities, including explicit confirmation, are false.

## Default, Restore, and Restart

No Default, Restore, or restart behavior exists.

## Test Requirements

Validate the exact executable and argument text, Open-only action list, lack of other system-changing commands, and source checksum without executing Open.
