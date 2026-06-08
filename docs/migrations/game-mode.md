# GameMode Migration Record

* **Tool name:** GameMode
* **Stage:** Windows
* **Source script path:** `source-ultimate/6 Windows/9 Gamemode.ps1`
* **Source checksum:** `F83275C0B3CE135679C2F1D98A1F0BD6B101936E0B2BC17B542DE288EF6A0B82`
* **Risk level:** Low
* **Required privileges:** BoostLab application context; catalog currently requires Administrator
* **Yazan approval status:** Approved by Yazan

## Original Ultimate Behavior

Open the Windows Game Mode Settings page.

## Approved BoostLab Behavior

The Open action launches the exact built-in Settings URI from Ultimate.

## Preserved Commands

`Start-Process "ms-settings:gaming-gamemode"`

## Intentional Deviations

Catalog metadata was corrected from placeholder Apply/Default behavior to an Open-only assistant because the approved source contains no setting mutation. The module adds structured result handling.

## Side Effects

Launches Windows Settings only.

## Capabilities

`RequiresAdmin = true`; all mutation, Default, Restore, confirmation, and restart capabilities are false.

## Default, Restore, and Restart

No Default, Restore, or restart behavior exists.

## Test Requirements

Validate the exact source checksum and launcher, corrected Open-only metadata, safe capability set, structured module contract, and absence of system-changing commands. Automated tests must not execute Open.
