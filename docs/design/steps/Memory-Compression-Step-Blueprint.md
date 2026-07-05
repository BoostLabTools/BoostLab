# AXIS Memory Compression Step Blueprint

Date: 2026-07-06
Scope: owner-approved Setup-stage customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `memory-compression` Setup-stage step.

This phase is documentation-only. It does not implement UI behavior, run MMAgent, change memory compression state, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `memory-compression` |
| Customer-facing step title | `Memory Compression` |
| Stage | `Setup` |
| Visible stage label | `Setup` |
| Production action mapping | customer-facing `ØªØ¹Ø·ÙŠÙ„ Memory Compression` maps later to internal `Apply` for `memory-compression` |
| Prototype behavior | Simulation only. Do not run MMAgent or any real memory compression command. |

Internal runtime actions may include Apply and Default according to config/runtime state, but the normal customer-facing AXIS first-use wizard exposes only the owner-approved Apply action recorded here.

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Memory Compression` |
| Subtitle | `ØªØ¹Ø·ÙŠÙ„ Ù…ÙŠØ²Ø© Memory Compression Ù…Ù† Ø§Ù„Ù†Ø¸Ø§Ù….` |
| Primary action button | `ØªØ¹Ø·ÙŠÙ„ Memory Compression` |
| Information card title | `ØªØ¹Ø·ÙŠÙ„ Ø¶ØºØ· Ø§Ù„Ø°Ø§ÙƒØ±Ø©` |
| Information card bullet 1 | `ØªØ¹Ø·ÙŠÙ„ Ù…ÙŠØ²Ø© Memory Compression ÙÙŠ Windows.` |
| Information card bullet 2 | `ØªØ³Ø§Ø¹Ø¯ Ù‡Ø°Ù‡ Ø§Ù„Ø®Ø·ÙˆØ© Ø¹Ù„Ù‰ Ø¬Ø¹Ù„ Ø¥Ø¯Ø§Ø±Ø© Ø§Ù„Ø°Ø§ÙƒØ±Ø© Ø£ÙƒØ«Ø± Ù…Ø¨Ø§Ø´Ø±Ø© Ø£Ø«Ù†Ø§Ø¡ Ø§Ù„Ø§Ø³ØªØ®Ø¯Ø§Ù….` |
| Information card bullet 3 | `ÙŠØªÙ… ØªØ·Ø¨ÙŠÙ‚ Ø§Ù„Ø¥Ø¹Ø¯Ø§Ø¯ ØªÙ„Ù‚Ø§Ø¦ÙŠÙ‹Ø§ Ø¨Ø¯ÙˆÙ† Ø£ÙŠ Ø®Ø·ÙˆØ§Øª Ø¥Ø¶Ø§ÙÙŠØ© Ù…Ù† Ø§Ù„Ø¹Ù…ÙŠÙ„.` |
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

Do not show MMAgent, PowerShell, memory counters, diagnostics, command output, or technical implementation details.

Do not show internal action names, Registry names, Services names, Tasks names, file paths, modules, logs, hashes, validation results, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not run MMAgent, query live memory compression state, mutate host state, or run Apply, Default, Restore, Open, or Analyze.

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

`Memory Compression` and `Windows` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, MMAgent execution, host mutation, staging, committing, or pushing.
