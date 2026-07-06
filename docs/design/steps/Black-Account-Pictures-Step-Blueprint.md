# AXIS Black Account Pictures Step Blueprint

Date: 2026-07-06
Scope: owner-approved Windows Part A customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `user-account-pictures-black` Windows-stage step.

This phase is documentation-only. It does not implement UI behavior, replace account pictures, copy image files, restore backups, modify account picture files, registry, system image locations, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `user-account-pictures-black` |
| Customer-facing step title | `Black Account Pictures` |
| Stage | `Windows` |
| Visible stage label | `Windows` |
| Production action mapping | customer-facing `ØªØ·Ø¨ÙŠÙ‚ ØµÙˆØ± Ø§Ù„Ø­Ø³Ø§Ø¨ Ø§Ù„Ø³ÙˆØ¯Ø§Ø¡` maps later to internal `Apply` for `user-account-pictures-black` |
| Internal branch/option mapping | `Black` |
| Default action | Do not expose Default/restore in normal customer UI now. |
| Prototype behavior | Simulation only. Do not replace account pictures. Do not copy image files. Do not restore backups. Do not modify account picture files, registry, or system image locations. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Black Account Pictures` |
| Subtitle | `ØªØ·Ø¨ÙŠÙ‚ ØµÙˆØ± Ø­Ø³Ø§Ø¨ Ø³ÙˆØ¯Ø§Ø¡.` |
| Primary action button | `ØªØ·Ø¨ÙŠÙ‚ ØµÙˆØ± Ø§Ù„Ø­Ø³Ø§Ø¨ Ø§Ù„Ø³ÙˆØ¯Ø§Ø¡` |
| Information card title | `ØµÙˆØ± Ø§Ù„Ø­Ø³Ø§Ø¨` |
| Information card bullet 1 | `Ø§Ø³ØªØ¨Ø¯Ø§Ù„ ØµÙˆØ± Ø­Ø³Ø§Ø¨ Ø§Ù„Ù…Ø³ØªØ®Ø¯Ù… Ø¨ØµÙˆØ± Ø³ÙˆØ¯Ø§Ø¡.` |
| Information card bullet 2 | `ÙŠØ³Ø§Ø¹Ø¯ Ø°Ù„Ùƒ Ø¹Ù„Ù‰ ØªÙˆØ­ÙŠØ¯ Ù…Ø¸Ù‡Ø± Ø­Ø³Ø§Ø¨Ø§Øª Windows.` |
| Requirements card | Not shown |
| Confirmation overlay | Not shown |
| Running state | `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°` |
| Completed state | `Ù…ÙƒØªÙ…Ù„` |

## Runtime Status And Completion

During simulated action, show `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°`.

After simulated completion, show `Ù…ÙƒØªÙ…Ù„`.

After completion, show no additional customer-facing text. Only enable the Next button.

## Customer-Facing Restrictions

Do not show account picture paths.

Do not show backup file names.

Do not show copy/replace internals.

Do not show Registry names, commands, diagnostics, logs, validation results, command output, internal modules, Services names, Tasks names, AppX package names, TrustedInstaller details, file paths, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not replace account pictures, copy image files, restore backups, modify account picture files, registry, system image locations, Windows settings, host configuration, or run Apply, Open, Default, Restore, or Analyze.

## Windows UI Layout Contract

Preserve the global Windows-stage AXIS layout: `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, RTL with physical right-edge anchoring, Windows active, prior stages completed green, active Windows full white line, support card separate, runtime status near the primary action button, Next disabled until completion then blue, no auto-advance.

## BiDi And Layout Notes

Title is English-only and should render LTR while remaining physically right-anchored.

`Windows` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, account-picture mutation, file mutation, Registry mutation, host mutation, staging, committing, or pushing.
