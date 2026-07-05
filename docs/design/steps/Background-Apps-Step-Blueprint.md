# AXIS Background Apps Step Blueprint

Date: 2026-07-06
Scope: owner-approved Setup-stage customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `background-apps` Setup-stage step.

This phase is documentation-only. It does not implement UI behavior, write policies, write Registry values, change background app settings, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `background-apps` |
| Customer-facing step title | `ØªØ·Ø¨ÙŠÙ‚Ø§Øª Ø§Ù„Ø®Ù„ÙÙŠØ©` |
| Stage | `Setup` |
| Visible stage label | `Setup` |
| Production action mapping | customer-facing `ØªØ¹Ø·ÙŠÙ„ ØªØ·Ø¨ÙŠÙ‚Ø§Øª Ø§Ù„Ø®Ù„ÙÙŠØ©` maps later to internal `Apply` for `background-apps` |
| Prototype behavior | Simulation only. Do not write policies or Registry values. Do not change background app settings. |

Internal runtime actions may include Apply and Default according to config/runtime state, but the normal customer-facing AXIS first-use wizard exposes only the owner-approved Apply action recorded here.

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `ØªØ·Ø¨ÙŠÙ‚Ø§Øª Ø§Ù„Ø®Ù„ÙÙŠØ©` |
| Subtitle | `ØªØ¹Ø·ÙŠÙ„ Ø¹Ù…Ù„ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚Ø§Øª ÙÙŠ Ø§Ù„Ø®Ù„ÙÙŠØ©.` |
| Primary action button | `ØªØ¹Ø·ÙŠÙ„ ØªØ·Ø¨ÙŠÙ‚Ø§Øª Ø§Ù„Ø®Ù„ÙÙŠØ©` |
| Information card title | `ØªÙ‚Ù„ÙŠÙ„ Ù†Ø´Ø§Ø· Ø§Ù„ØªØ·Ø¨ÙŠÙ‚Ø§Øª` |
| Information card bullet 1 | `ØªØ¹Ø·ÙŠÙ„ Ø¹Ù…Ù„ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚Ø§Øª ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠØ© ÙÙŠ Ø§Ù„Ø®Ù„ÙÙŠØ©.` |
| Information card bullet 2 | `ÙŠØ³Ø§Ø¹Ø¯ Ø°Ù„Ùƒ Ø¹Ù„Ù‰ ØªÙ‚Ù„ÙŠÙ„ Ø§Ø³ØªÙ‡Ù„Ø§Ùƒ Ø§Ù„Ù…ÙˆØ§Ø±Ø¯ Ø£Ø«Ù†Ø§Ø¡ Ø§Ø³ØªØ®Ø¯Ø§Ù… Ø§Ù„Ø¬Ù‡Ø§Ø².` |
| Information card bullet 3 | `ÙŠØªÙ… ØªØ·Ø¨ÙŠÙ‚ Ø§Ù„Ø¥Ø¹Ø¯Ø§Ø¯ ØªÙ„Ù‚Ø§Ø¦ÙŠÙ‹Ø§ Ø¨Ø¯ÙˆÙ† Ø§Ù„Ø­Ø§Ø¬Ø© Ø¥Ù„Ù‰ Ø®Ø·ÙˆØ§Øª Ø¥Ø¶Ø§ÙÙŠØ©.` |
| Requirements card | Not shown |
| Confirmation overlay | Not shown |
| Running state | `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°` |
| Completed state | `Ù…ÙƒØªÙ…Ù„` |

## Requirements Card

No requirements card should be shown.

## Confirmation Overlay

No confirmation overlay should be shown.

## Default Action Boundary

Do not expose Default or Restore in the normal customer UI now.

## Runtime Status And Completion

During simulated action, show `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°`.

After simulated completion, show `Ù…ÙƒØªÙ…Ù„`.

After completion, show no additional customer-facing text. Only enable the Next button.

## Customer-Facing Restrictions

Do not show policy names, Registry paths, package names, commands, diagnostics, internal action names, Services names, Tasks names, file paths, modules, logs, hashes, command output, validation results, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not write policies, write Registry values, change background app settings, open Settings, mutate host state, or run Apply, Default, Restore, Open, or Analyze.

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

Arabic text blocks must be physically right-aligned.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, Registry or policy mutation, host mutation, staging, committing, or pushing.
