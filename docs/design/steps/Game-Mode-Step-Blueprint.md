# AXIS Game Mode Step Blueprint

Date: 2026-07-06
Scope: owner-approved Windows Part A customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `game-mode` Windows-stage step.

This phase is documentation-only. It does not implement UI behavior, open Windows Settings, change Game Mode settings, modify registry, modify Windows settings, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `game-mode` |
| Customer-facing step title | `Game Mode` |
| Stage | `Windows` |
| Visible stage label | `Windows` |
| Production action mapping | customer-facing `ÙØªØ­ Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Game Mode` maps later to internal `Open` for `game-mode` |
| Prototype behavior | Simulation only. Do not open Windows Settings. Do not change Game Mode settings. Do not modify registry or Windows settings. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Game Mode` |
| Subtitle | `ÙØªØ­ Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ø£Ù„Ø¹Ø§Ø¨ Ù„Ù„ØªØ£ÙƒØ¯ Ù…Ù† ØªÙØ¹ÙŠÙ„ Game Mode.` |
| Primary action button | `ÙØªØ­ Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Game Mode` |
| Information card title | `Ù…Ø±Ø§Ø¬Ø¹Ø© Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ø£Ù„Ø¹Ø§Ø¨` |
| Information card bullet 1 | `Ø§ÙØªØ­ Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ø£Ù„Ø¹Ø§Ø¨ Ø¯Ø§Ø®Ù„ Windows.` |
| Information card bullet 2 | `ØªØ£ÙƒØ¯ Ø£Ù† Ø®ÙŠØ§Ø± Game Mode Ù…Ø¶Ø¨ÙˆØ· Ø¹Ù„Ù‰ ON.` |
| Information card bullet 3 | `Ø¨Ø¹Ø¯ Ø§Ù„ØªØ£ÙƒØ¯ Ù…Ù† Ø§Ù„Ø¥Ø¹Ø¯Ø§Ø¯ØŒ ÙŠÙ…ÙƒÙ†Ùƒ Ù…ØªØ§Ø¨Ø¹Ø© Ø§Ù„Ø®Ø·ÙˆØ§Øª Ø§Ù„ØªØ§Ù„ÙŠØ©.` |
| Requirements card | Not shown |
| Confirmation overlay | Not shown |
| Running state | `ÙØªØ­ Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Game Mode` |
| Completed state | `Ù…ÙƒØªÙ…Ù„` |

## Runtime Status And Completion

During simulated action, show `ÙØªØ­ Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Game Mode`.

After simulated completion, show `Ù…ÙƒØªÙ…Ù„`.

After completion, show no additional customer-facing text. Only enable the Next button.

## Customer-Facing Restrictions

Do not show settings URI.

Do not show commands used to open settings.

Do not show diagnostics, logs, validation results, command output, internal modules, Registry names, Services names, Tasks names, AppX package names, TrustedInstaller details, file paths, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not open Windows Settings, change Game Mode settings, modify registry, Windows settings, host configuration, or run Apply, Open, Default, Restore, or Analyze.

## Windows UI Layout Contract

Preserve the global Windows-stage AXIS layout: `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, RTL with physical right-edge anchoring, Windows active, prior stages completed green, active Windows full white line, support card separate, runtime status near the primary action button, Next disabled until completion then blue, no auto-advance.

## BiDi And Layout Notes

Title is English-only and should render LTR while remaining physically right-anchored.

`Windows`, `Game Mode`, and `ON` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, Windows Settings launch, settings mutation, Registry mutation, host mutation, staging, committing, or pushing.
