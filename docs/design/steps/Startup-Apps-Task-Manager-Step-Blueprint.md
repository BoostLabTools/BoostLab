# AXIS Startup Apps Task Manager Step Blueprint

Date: 2026-07-06
Scope: owner-approved Setup-stage customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `startup-apps-task-manager` Setup-stage step.

This phase is documentation-only. It does not implement UI behavior, open Task Manager, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `startup-apps-task-manager` |
| Customer-facing step title | `Startup Apps Task Manager` |
| Stage | `Setup` |
| Visible stage label | `Setup` |
| Production action mapping | customer-facing `Ø§ÙØªØ­` maps later to internal `Open` for `startup-apps-task-manager` |
| Prototype behavior | Simulation only. Do not open Task Manager. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Startup Apps Task Manager` |
| Subtitle | `Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø¨Ø¯Ø¡ Ø§Ù„ØªØ´ØºÙŠÙ„ Ù…Ù† Task Manager.` |
| Primary action button | `Ø§ÙØªØ­` |
| Information card title | `Ù…Ø±Ø§Ø¬Ø¹Ø© Ø¨Ø¯Ø¡ Ø§Ù„ØªØ´ØºÙŠÙ„` |
| Information card bullet 1 | `Ø§ÙØªØ­ Task Manager Ø¹Ù„Ù‰ Ù‚Ø³Ù… ØªØ·Ø¨ÙŠÙ‚Ø§Øª Ø¨Ø¯Ø¡ Ø§Ù„ØªØ´ØºÙŠÙ„.` |
| Information card bullet 2 | `Ø±Ø§Ø¬Ø¹ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚Ø§Øª Ø§Ù„ØªÙŠ ØªØ¹Ù…Ù„ ØªÙ„Ù‚Ø§Ø¦ÙŠÙ‹Ø§ Ø¹Ù†Ø¯ Ø¥Ù‚Ù„Ø§Ø¹ Windows.` |
| Information card bullet 3 | `Ù‡Ø°Ù‡ Ø§Ù„Ù…Ø±Ø§Ø¬Ø¹Ø© ØªØ³Ø§Ø¹Ø¯Ùƒ Ø¹Ù„Ù‰ ØªØ¹Ø·ÙŠÙ„ Ø§Ù„Ø¹Ù†Ø§ØµØ± ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠØ©.` |
| Requirements card title | `Ø§Ù„Ù…ØªØ·Ù„Ø¨Ø§Øª` |
| Requirements bullet 1 | `Ù‚Ù… Ø¨Ø¥ØºÙ„Ø§Ù‚ Ø¬Ù…ÙŠØ¹ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚Ø§Øª Ù‚Ø¨Ù„ Ø§Ù„Ù…ØªØ§Ø¨Ø¹Ø©.` |
| Requirements bullet 2 | `Ù‡Ø°Ù‡ Ø§Ù„Ø®Ø·ÙˆØ© Ù…ÙˆØµÙ‰ Ø¨Ù‡Ø§ Ù‚Ø¨Ù„ Ù…Ø±Ø§Ø¬Ø¹Ø© ØªØ·Ø¨ÙŠÙ‚Ø§Øª Ø¨Ø¯Ø¡ Ø§Ù„ØªØ´ØºÙŠÙ„.` |
| Confirmation overlay | Not shown |
| Running state | `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°` |
| Completed state | `Ù…ÙƒØªÙ…Ù„` |

## Requirements Card

Show the requirements card using only the owner-approved title and bullets recorded above.

## Confirmation Overlay

No confirmation overlay should be shown.

## Runtime Status And Completion

During simulated action, show `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°`.

After simulated completion, show `Ù…ÙƒØªÙ…Ù„`.

After completion, show no additional customer-facing text. Only enable the Next button.

## Customer-Facing Restrictions

Do not show process names, taskmgr arguments, commands, internal Open implementation details, Registry names, Services names, Tasks names, file paths, modules, logs, hashes, command output, validation results, or diagnostics.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not open Task Manager, mutate host state, or run Apply, Default, Restore, Open, or Analyze.

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

`Task Manager` and `Windows` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, Task Manager launch, host mutation, staging, committing, or pushing.
