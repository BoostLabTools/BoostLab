# AXIS Updates Pause Step Blueprint

Date: 2026-07-06
Scope: owner-approved Setup-stage customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `updates-pause` Setup-stage step.

This phase is documentation-only. It does not implement UI behavior, pause Windows Update, write Windows Update policies, write Registry values, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `updates-pause` |
| Customer-facing step title | `Updates Pause` |
| Stage | `Setup` |
| Visible stage label | `Setup` |
| Production action mapping | customer-facing `Ø¥ÙŠÙ‚Ø§Ù Ø§Ù„ØªØ­Ø¯ÙŠØ«Ø§Øª` maps later to internal `Apply` for `updates-pause` |
| Prototype behavior | Simulation only. Do not pause Windows Update. Do not write Windows Update policies or Registry values. |

Internal runtime actions may include Apply and Default according to config/runtime state, but the normal customer-facing AXIS first-use wizard exposes only the owner-approved Apply action recorded here.

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Updates Pause` |
| Subtitle | `Ø¥ÙŠÙ‚Ø§Ù Ù…Ø¤Ù‚Øª Ù„ØªØ­Ø¯ÙŠØ«Ø§Øª Windows.` |
| Primary action button | `Ø¥ÙŠÙ‚Ø§Ù Ø§Ù„ØªØ­Ø¯ÙŠØ«Ø§Øª` |
| Information card title | `Ø¥ÙŠÙ‚Ø§Ù ØªØ­Ø¯ÙŠØ«Ø§Øª Windows Ù…Ø¤Ù‚ØªÙ‹Ø§` |
| Information card bullet 1 | `Ø¥ÙŠÙ‚Ø§Ù ØªØ­Ø¯ÙŠØ«Ø§Øª Windows Ù…Ø¤Ù‚ØªÙ‹Ø§ Ù„ØªÙ‚Ù„ÙŠÙ„ Ø§Ù„Ù…Ù‚Ø§Ø·Ø¹Ø§Øª Ø£Ø«Ù†Ø§Ø¡ Ø§Ø³ØªØ®Ø¯Ø§Ù… Ø§Ù„Ø¬Ù‡Ø§Ø².` |
| Information card bullet 2 | `ÙŠØ³Ø§Ø¹Ø¯ Ø°Ù„Ùƒ Ø¹Ù„Ù‰ ØªÙˆÙÙŠØ± ØªØ¬Ø±Ø¨Ø© Ø£ÙƒØ«Ø± Ù‡Ø¯ÙˆØ¡Ù‹Ø§ Ø¨Ø¯ÙˆÙ† Ø§Ù†Ø´ØºØ§Ù„ Ù…Ø³ØªÙ…Ø± Ø¨Ø§Ù„ØªØ­Ø¯ÙŠØ«Ø§Øª.` |
| Information card bullet 3 | `ÙŠÙ…ÙƒÙ† Ù…ØªØ§Ø¨Ø¹Ø© Ø¥Ø¹Ø¯Ø§Ø¯ Ø§Ù„Ù†Ø¸Ø§Ù… Ø¨Ø¹Ø¯ Ø§ÙƒØªÙ…Ø§Ù„ Ù‡Ø°Ù‡ Ø§Ù„Ø®Ø·ÙˆØ©.` |
| Requirements card title | `Ø§Ù„Ù…ØªØ·Ù„Ø¨Ø§Øª` |
| Requirements bullet 1 | `Ø§Ù‚Ø±Ø£ Ø§Ù„ØªØ¹Ù„ÙŠÙ…Ø§Øª Ù‚Ø¨Ù„ Ø¥ÙŠÙ‚Ø§Ù Ø§Ù„ØªØ­Ø¯ÙŠØ«Ø§Øª.` |
| Confirmation checkbox | `Ù„Ù‚Ø¯ Ù‚Ø±Ø£Øª Ø§Ù„ØªØ¹Ù„ÙŠÙ…Ø§Øª` |
| Confirmation primary button | `Ø¥ÙŠÙ‚Ø§Ù Ø§Ù„ØªØ­Ø¯ÙŠØ«Ø§Øª` |
| Confirmation return button | `Ø±Ø¬ÙˆØ¹` |
| Running state | `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°` |
| Completed state | `Ù…ÙƒØªÙ…Ù„` |

## Requirements Card

Show the requirements card using only the owner-approved title and bullet recorded above.

## Confirmation Overlay

Use a confirmation overlay with checkbox.

The overlay checkbox text is `Ù„Ù‚Ø¯ Ù‚Ø±Ø£Øª Ø§Ù„ØªØ¹Ù„ÙŠÙ…Ø§Øª`.

The overlay primary button is `Ø¥ÙŠÙ‚Ø§Ù Ø§Ù„ØªØ­Ø¯ÙŠØ«Ø§Øª`.

The overlay return button is `Ø±Ø¬ÙˆØ¹`.

The primary overlay button stays disabled until the checkbox is checked.

The checkbox checked fill is blue with no checkmark, matching the approved existing pattern.

`Ø±Ø¬ÙˆØ¹` closes the overlay only.

No Cancel button appears.

## Default Action Boundary

Do not expose Default or Restore in the normal customer UI now.

## Runtime Status And Completion

During simulated action, show `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°`.

After simulated completion, show `Ù…ÙƒØªÙ…Ù„`.

After completion, show no additional customer-facing text. Only enable the Next button.

## Customer-Facing Restrictions

Do not mention 365 days in the normal customer UI.

Do not show Registry values, Windows Update policy names, commands, diagnostics, internal action names, Services names, Tasks names, file paths, modules, logs, hashes, command output, validation results, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not pause Windows Update, write Windows Update policies, write Registry values, open Windows Update settings, mutate host state, or run Apply, Default, Restore, Open, or Analyze.

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

`Windows` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, Windows Update mutation, Registry mutation, host mutation, staging, committing, or pushing.
