# AXIS Date Language Region Time Step Blueprint

Date: 2026-07-06
Scope: owner-approved Setup-stage customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `date-language-region-time` Setup-stage step.

This phase is documentation-only. It does not implement UI behavior, open Windows Settings, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `date-language-region-time` |
| Customer-facing step title | `Ø§Ù„ØªØ§Ø±ÙŠØ® ÙˆØ§Ù„ÙˆÙ‚Øª` |
| Stage | `Setup` |
| Visible stage label | `Setup` |
| Production action mapping | customer-facing `Ø§ÙØªØ­` maps later to internal `Open` for `date-language-region-time` |
| Prototype behavior | Simulation only. Do not open Windows Settings. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Ø§Ù„ØªØ§Ø±ÙŠØ® ÙˆØ§Ù„ÙˆÙ‚Øª` |
| Subtitle | `Ø¶Ø¨Ø· Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Windows ÙŠØ¯ÙˆÙŠÙ‹Ø§.` |
| Primary action button | `Ø§ÙØªØ­` |
| Information card title | `Ù…Ø±Ø§Ø¬Ø¹Ø© Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ù…Ù†Ø·Ù‚Ø© ÙˆØ§Ù„ÙˆÙ‚Øª` |
| Information card bullet 1 | `Ø§ÙØªØ­ Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„ØªØ§Ø±ÙŠØ® ÙˆØ§Ù„ÙˆÙ‚Øª Ø¯Ø§Ø®Ù„ Windows.` |
| Information card bullet 2 | `Ø±Ø§Ø¬Ø¹ Ø§Ù„Ù„ØºØ© ÙˆØ§Ù„Ù…Ù†Ø·Ù‚Ø© Ø­Ø³Ø¨ ØªÙØ¶ÙŠÙ„Ø§ØªÙƒ.` |
| Information card bullet 3 | `ØªØ£ÙƒØ¯ Ø£Ù† Ø§Ù„ÙˆÙ‚Øª ÙˆØ§Ù„Ù…Ù†Ø·Ù‚Ø© Ù…Ø¶Ø¨ÙˆØ·ÙŠÙ† Ù‚Ø¨Ù„ Ù…ØªØ§Ø¨Ø¹Ø© Ø§Ù„Ø¥Ø¹Ø¯Ø§Ø¯.` |
| Requirements card | Not shown |
| Confirmation overlay | Not shown |
| Running state | `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°` |
| Completed state | `Ù…ÙƒØªÙ…Ù„` |

## Requirements Card

No requirements card should be shown.

## Confirmation Overlay

No confirmation overlay should be shown.

## Runtime Status And Completion

During simulated action, show `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°`.

After simulated completion, show `Ù…ÙƒØªÙ…Ù„`.

After completion, show no additional customer-facing text. Only enable the Next button.

## Customer-Facing Restrictions

Do not show settings URI, commands, internal Open implementation details, Registry names, Services names, Tasks names, file paths, modules, logs, hashes, command output, validation results, or diagnostics.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not open Windows Settings, mutate host state, or run Apply, Default, Restore, Open, or Analyze.

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

`Windows` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, Windows Settings launch, host mutation, staging, committing, or pushing.
