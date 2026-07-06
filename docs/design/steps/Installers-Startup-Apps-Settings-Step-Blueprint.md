# AXIS Installers Startup Apps Settings Step Blueprint

Date: 2026-07-07
Scope: owner-approved Installers-stage duplicate step blueprint only

## Owner-Control Notice

This document records the Installers-stage copy of the approved `startup-apps-settings` Setup-stage customer-facing step.

This phase is documentation-only. It does not implement UI behavior, open Windows Settings, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, edit modules, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `installers-startup-apps-settings` |
| Customer-facing step title | `Startup Apps Settings` |
| Stage | `Installers` |
| Visible stage label | `Installers` |
| Source/copy relationship | Installers-stage copy of approved Setup step `startup-apps-settings` |
| Production action mapping | customer-facing `Ø§ÙØªØ­` maps later to internal `Open` behavior |
| Prototype behavior | Simulation only. Do not open Windows Settings. |

The original Setup-stage `startup-apps-settings` step remains exactly where it is. This Installers-stage duplicate appears after app installation so the customer can review startup apps again after installing new programs.

## Owner-Approved Customer-Facing Copy

Copy the approved `startup-apps-settings` customer-facing copy exactly from `docs/design/steps/Startup-Apps-Settings-Step-Blueprint.md`.

| Surface | Owner-approved value |
| --- | --- |
| Title | `Startup Apps Settings` |
| Subtitle | `Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª ØªØ·Ø¨ÙŠÙ‚Ø§Øª Ø¨Ø¯Ø¡ Ø§Ù„ØªØ´ØºÙŠÙ„.` |
| Primary action button | `Ø§ÙØªØ­` |
| Information card title | `ØªØ·Ø¨ÙŠÙ‚Ø§Øª Ø¨Ø¯Ø¡ Ø§Ù„ØªØ´ØºÙŠÙ„` |
| Information card bullet 1 | `Ø§ÙØªØ­ Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª ØªØ·Ø¨ÙŠÙ‚Ø§Øª Ø¨Ø¯Ø¡ Ø§Ù„ØªØ´ØºÙŠÙ„ Ø¯Ø§Ø®Ù„ Windows.` |
| Information card bullet 2 | `Ø±Ø§Ø¬Ø¹ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚Ø§Øª Ø§Ù„ØªÙŠ ØªØ¹Ù…Ù„ ØªÙ„Ù‚Ø§Ø¦ÙŠÙ‹Ø§ Ø¹Ù†Ø¯ ØªØ´ØºÙŠÙ„ Ø§Ù„Ø¬Ù‡Ø§Ø².` |
| Information card bullet 3 | `ØªØ¹Ø·ÙŠÙ„ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚Ø§Øª ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠØ© ÙŠØ³Ø§Ø¹Ø¯ Ø¹Ù„Ù‰ ØªØ­Ø³ÙŠÙ† Ø³Ø±Ø¹Ø© Ø§Ù„Ø¥Ù‚Ù„Ø§Ø¹.` |
| Requirements card title | `Ø§Ù„Ù…ØªØ·Ù„Ø¨Ø§Øª` |
| Requirements bullet 1 | `Ù‚Ù… Ø¨Ø¥ØºÙ„Ø§Ù‚ Ø¬Ù…ÙŠØ¹ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚Ø§Øª Ù‚Ø¨Ù„ Ø§Ù„Ù…ØªØ§Ø¨Ø¹Ø©.` |
| Requirements bullet 2 | `Ù‡Ø°Ù‡ Ø§Ù„Ø®Ø·ÙˆØ© Ù…ÙˆØµÙ‰ Ø¨Ù‡Ø§ Ù„Ù„Ø­ØµÙˆÙ„ Ø¹Ù„Ù‰ Ù…Ø±Ø§Ø¬Ø¹Ø© Ø£ÙˆØ¶Ø­ Ù„ØªØ·Ø¨ÙŠÙ‚Ø§Øª Ø¨Ø¯Ø¡ Ø§Ù„ØªØ´ØºÙŠÙ„.` |
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

Do not show settings URI, commands, startup entry internals, internal Open implementation details, Registry names, Services names, Tasks names, file paths, modules, logs, hashes, command output, validation results, or diagnostics.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not open Windows Settings, change startup app settings, mutate host state, modify Registry, modify startup entries, modify apps, or run Apply, Default, Restore, Open, or Analyze.

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

`Windows` inside Arabic lines must be rendered safely.

Information card must be physical right and requirements card physical left.

Wrapped Arabic lines must remain physically right-aligned and must not float left.

No accidental replacement glyphs like `ï¿½`.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, Windows Settings launch, host mutation, staging, committing, or pushing.
