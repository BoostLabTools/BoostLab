# AXIS Convert Home to Pro Step Blueprint

Date: 2026-07-06
Scope: owner-approved Setup-stage customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `convert-home-to-pro` Setup-stage step.

This phase is documentation-only. It does not implement UI behavior, copy any key to the clipboard, open Activation, open product-key UI, change Windows edition, change activation state, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `convert-home-to-pro` |
| Customer-facing step title | `Convert Home to Pro` |
| Stage | `Setup` |
| Visible stage label | `Setup` |
| Production action mapping | customer-facing `Ø§Ù„ØªØ±Ù‚ÙŠØ© Ø¥Ù„Ù‰ Windows Pro` maps later to internal `Apply` for `convert-home-to-pro` |
| Prototype behavior | Simulation only. Do not copy any key to clipboard. Do not open Activation. Do not open product-key UI. Do not change Windows edition or activation state. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Convert Home to Pro` |
| Subtitle | `Ø§Ù„ØªØ­ÙˆÙŠÙ„ Ù…Ù† Ø¥ØµØ¯Ø§Ø± Windows Home Ø¥Ù„Ù‰ Windows Pro.` |
| Primary action button | `Ø§Ù„ØªØ±Ù‚ÙŠØ© Ø¥Ù„Ù‰ Windows Pro` |
| Information card title | `ØªØ±Ù‚ÙŠØ© Ø¥ØµØ¯Ø§Ø± Windows` |
| Information card bullet 1 | `ØªØ¬Ù‡ÙŠØ² Ø§Ù„ØªØ­ÙˆÙŠÙ„ Ù…Ù† Ø¥ØµØ¯Ø§Ø± Windows Home Ø¥Ù„Ù‰ Windows Pro.` |
| Information card bullet 2 | `Ø³ÙŠØªÙ… ÙØªØ­ Ù†Ø§ÙØ°Ø© Ø¥Ø¯Ø®Ø§Ù„ Ù…ÙØªØ§Ø­ Ø§Ù„Ù…Ù†ØªØ¬ Ø¯Ø§Ø®Ù„ Windows.` |
| Information card bullet 3 | `Ø¨Ø¹Ø¯ ÙØªØ­ Ø§Ù„Ù†Ø§ÙØ°Ø©ØŒ ÙŠÙ…ÙƒÙ†Ùƒ Ù„ØµÙ‚ Ø§Ù„Ù…ÙØªØ§Ø­ Ù…Ø¨Ø§Ø´Ø±Ø© Ù„Ù„Ù…ØªØ§Ø¨Ø¹Ø©.` |
| Requirements card title | `Ø§Ù„Ù…ØªØ·Ù„Ø¨Ø§Øª` |
| Requirements bullet 1 | `Ø³ÙŠØªÙ… Ù†Ø³Ø® Ø§Ù„Ù…ÙØªØ§Ø­ ØªÙ„Ù‚Ø§Ø¦ÙŠÙ‹Ø§.` |
| Requirements bullet 2 | `Ø¹Ù†Ø¯ Ø¸Ù‡ÙˆØ± Ù†Ø§ÙØ°Ø© Ø¥Ø¯Ø®Ø§Ù„ Ø§Ù„Ù…ÙØªØ§Ø­ØŒ Ø§Ø³ØªØ®Ø¯Ù… Ctrl + V Ù„Ù„ØµÙ‚ Ø§Ù„Ù…ÙØªØ§Ø­.` |
| Confirmation overlay | Not shown |
| Running state | `ÙŠØªÙ… Ø§Ù„ØªØ¬Ù‡ÙŠØ²` |
| Completed state | `Ø¬Ø§Ù‡Ø² Ù„Ù„ØµÙ‚` |

## Requirements Card

Show the requirements card using only the owner-approved title and bullets recorded above.

## Confirmation Overlay

No confirmation overlay should be shown.

## Runtime Status And Completion

During simulated action, show `ÙŠØªÙ… Ø§Ù„ØªØ¬Ù‡ÙŠØ²`.

After simulated completion, show `Ø¬Ø§Ù‡Ø² Ù„Ù„ØµÙ‚`.

After completion, show no additional customer-facing text. Only enable the Next button.

## Customer-Facing Restrictions

Do not mention valid Windows Pro license requirement in the normal UI.

Do not mention that the copied key is generic.

Do not promise final activation.

Do not show the actual key in the normal UI.

Do not show activation internals or command details.

Do not show internal action names, Registry names, Services names, Tasks names, file paths, modules, logs, hashes, command output, validation results, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not copy clipboard content, open Activation, open product-key UI, change edition, activate Windows, run activation commands, mutate host state, or run Apply.

## Setup UI Layout Contract

The future Setup prototype should preserve `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, no PNG/SVG/WPF vector placeholders, Arabic-first copy except owner-approved English titles/buttons, RTL layout with physical right-edge anchoring, and the stage strip logical order Check, Refresh, Setup, Installers, Graphics, Windows, Advanced.

Setup is active, previous Check and Refresh stages are completed green, active Setup uses a full white line, and there is no partial progress line.

The support card appears in every Setup step and remains separate from runtime status:

| Surface | Owner-approved value |
| --- | --- |
| Support card title | `Ù…Ø³Ø§Ø¹Ø¯Ø©` |
| Support card body | `ØªØ­ØªØ§Ø¬ Ù…Ø³Ø§Ø¹Ø¯Ø©ØŸ ÙŠÙ…ÙƒÙ†Ùƒ Ø§Ù„ØªÙˆØ§ØµÙ„ Ù…Ø¹ Ø£Ø®ØµØ§Ø¦ÙŠ Ø§Ù„Ø¯Ø¹Ù… Ø¹Ø¨Ø± Ø®Ø§Ø¯Ù… Discord Ø§Ù„Ø®Ø§Øµ Ø¨Ø§Ù„Ù…ØªØ¬Ø±.` |

Runtime status stays near the primary action button. Next is disabled until action simulation completes, then enabled and blue. There is no auto-advance. Previous returns to the previous step.

Enabled buttons use hand cursor. Disabled buttons do not hover, do not press, and do not use hand cursor. Hover must be crisp and readable, with no grow, scale, or blur. Pressed state should be a subtle pressed-in effect.

## BiDi And Layout Notes

Title is English-only and should render LTR while remaining physically right-anchored.

`Windows Home`, `Windows Pro`, and `Ctrl + V` must be rendered safely inside Arabic lines.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, clipboard mutation, Activation settings, Windows edition changes, host mutation, staging, committing, or pushing.
