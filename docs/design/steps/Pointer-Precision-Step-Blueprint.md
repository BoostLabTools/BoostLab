# AXIS Pointer Precision Step Blueprint

Date: 2026-07-06
Scope: owner-approved Windows Part A customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `pointer-precision` Windows-stage step.

This phase is documentation-only. It does not implement UI behavior, open Mouse Properties, change pointer settings, modify registry, modify Windows mouse settings, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `pointer-precision` |
| Customer-facing step title | `Pointer Precision` |
| Stage | `Windows` |
| Visible stage label | `Windows` |
| Production action mapping | customer-facing `ÙØªØ­ Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ù…Ø¤Ø´Ø±` maps later to internal `Open` for `pointer-precision` |
| Prototype behavior | Simulation only. Do not open Mouse Properties. Do not change pointer settings. Do not modify registry or Windows mouse settings. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Pointer Precision` |
| Subtitle | `ÙØªØ­ Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ù…Ø¤Ø´Ø± Ù„ØªØ¹Ø·ÙŠÙ„ Enhance pointer precision.` |
| Primary action button | `ÙØªØ­ Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ù…Ø¤Ø´Ø±` |
| Information card title | `Ù…Ø±Ø§Ø¬Ø¹Ø© Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ù…Ø¤Ø´Ø±` |
| Information card bullet 1 | `Ø§ÙØªØ­ Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ù…Ø¤Ø´Ø± Ø§Ù„Ù…Ø§ÙˆØ³.` |
| Information card bullet 2 | `Ø£Ø²Ù„ ØªØ­Ø¯ÙŠØ¯ Ø®ÙŠØ§Ø± Enhance pointer precision.` |
| Information card bullet 3 | `Ø¨Ø¹Ø¯ Ø°Ù„Ùƒ Ø§Ø¶ØºØ· Apply Ø«Ù… OK Ù„Ø­ÙØ¸ Ø§Ù„Ø¥Ø¹Ø¯Ø§Ø¯.` |
| Requirements card | Not shown |
| Confirmation overlay | Not shown |
| Running state | `ÙØªØ­ Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ù…Ø¤Ø´Ø±` |
| Completed state | `Ù…ÙƒØªÙ…Ù„` |

## Runtime Status And Completion

During simulated action, show `ÙØªØ­ Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ù…Ø¤Ø´Ø±`.

After simulated completion, show `Ù…ÙƒØªÙ…Ù„`.

After completion, show no additional customer-facing text. Only enable the Next button.

## Customer-Facing Restrictions

Do not show RunDLL commands.

Do not show internal mouse settings names beyond approved customer text.

Do not show Registry names, diagnostics, logs, validation results, command output, internal modules, Services names, Tasks names, AppX package names, TrustedInstaller details, file paths, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not open Mouse Properties, change pointer settings, modify registry, Windows mouse settings, host configuration, or run Apply, Open, Default, Restore, or Analyze.

## Windows UI Layout Contract

Preserve the global Windows-stage AXIS layout: `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, RTL with physical right-edge anchoring, Windows active, prior stages completed green, active Windows full white line, support card separate, runtime status near the primary action button, Next disabled until completion then blue, no auto-advance.

## BiDi And Layout Notes

Title is English-only and should render LTR while remaining physically right-anchored.

`Enhance pointer precision`, `Apply`, and `OK` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, Mouse Properties launch, settings mutation, Registry mutation, host mutation, staging, committing, or pushing.
