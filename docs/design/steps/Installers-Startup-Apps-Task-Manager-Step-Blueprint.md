# AXIS Installers Startup Apps Task Manager Step Blueprint

Date: 2026-07-07
Scope: owner-approved Installers-stage duplicate step blueprint only

## Owner-Control Notice

This document records the Installers-stage copy of the approved `startup-apps-task-manager` Setup-stage customer-facing step.

This phase is documentation-only. It does not implement UI behavior, open Task Manager, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, edit modules, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `installers-startup-apps-task-manager` |
| Customer-facing step title | `Startup Apps Task Manager` |
| Stage | `Installers` |
| Visible stage label | `Installers` |
| Source/copy relationship | Installers-stage copy of approved Setup step `startup-apps-task-manager` |
| Production action mapping | customer-facing `Ø§ÙØªØ­` maps later to internal `Open` behavior |
| Prototype behavior | Simulation only. Do not open Task Manager. |

The original Setup-stage `startup-apps-task-manager` step remains exactly where it is. This Installers-stage duplicate appears after app installation so the customer can review startup apps through Task Manager after installing new programs.

## Owner-Approved Customer-Facing Copy

Copy the approved `startup-apps-task-manager` customer-facing copy exactly from `docs/design/steps/Startup-Apps-Task-Manager-Step-Blueprint.md`.

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

Do not auto-advance.

## Customer-Facing Restrictions

Do not show process names, taskmgr arguments, commands, startup entry internals, internal Open implementation details, Registry names, Services names, Tasks names, file paths, modules, logs, hashes, command output, validation results, or diagnostics.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not open Task Manager, modify startup apps, mutate host state, modify processes, modify startup entries, modify Registry, modify apps, or run Apply, Default, Restore, Open, or Analyze.

## Installers UI Layout Contract

Future implementation should preserve `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, no PNG/SVG/WPF vector placeholders, Arabic-first copy except owner-approved English titles/buttons, RTL layout with physical right-edge anchoring, and the stage strip logical order Check, Refresh, Setup, Installers, Graphics, Windows, Advanced.

Installers is active for this step. Previous Check, Refresh, and Setup stages are completed green. Active Installers uses a full white line. There is no partial progress line.

The support card appears in every step and remains separate from runtime status:

| Surface | Owner-approved value |
| --- | --- |
| Support card title | `Ù…Ø³Ø§Ø¹Ø¯Ø©` |
| Support card body | `ØªØ­ØªØ§Ø¬ Ù…Ø³Ø§Ø¹Ø¯Ø©ØŸ ÙŠÙ…ÙƒÙ†Ùƒ Ø§Ù„ØªÙˆØ§ØµÙ„ Ù…Ø¹ Ø£Ø®ØµØ§Ø¦ÙŠ Ø§Ù„Ø¯Ø¹Ù… Ø¹Ø¨Ø± Ø®Ø§Ø¯Ù… Discord Ø§Ù„Ø®Ø§Øµ Ø¨Ø§Ù„Ù…ØªØ¬Ø±.` |

Runtime status stays near the primary action button. Next is disabled until action simulation completes, then enabled and blue. Previous returns to the previous step.

Enabled buttons use hand cursor. Disabled buttons do not hover, do not press, and do not use hand cursor. Hover must be crisp and readable, with no grow, scale, or blur. Pressed state should be a subtle pressed-in effect.

## BiDi And Layout Notes

Title is English-only and should render LTR while remaining physically right-anchored.

`Task Manager` and `Windows` inside Arabic lines must be rendered safely.

Information card must be physical right and requirements card physical left.

Wrapped Arabic lines must remain physically right-aligned and must not float left.

No accidental replacement glyphs like `ï¿½`.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, Task Manager launch, host mutation, staging, committing, or pushing.
