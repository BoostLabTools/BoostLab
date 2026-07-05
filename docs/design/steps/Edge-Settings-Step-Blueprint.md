# AXIS Microsoft Edge Settings Step Blueprint

Date: 2026-07-06
Scope: owner-approved Setup-stage customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `edge-settings` Setup-stage step.

This phase is documentation-only. It does not implement UI behavior, change Edge settings, write Registry values, change services, download, install, clean, remove, launch anything, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `edge-settings` |
| Customer-facing step title | `Microsoft Edge Settings` |
| Stage | `Setup` |
| Visible stage label | `Setup` |
| Production action mapping | customer-facing `Optimize Microsoft Edge` maps later to internal `Apply` for `edge-settings` |
| Prototype behavior | Simulation only. Do not change Edge settings. Do not write Registry values. Do not change services. Do not download, install, clean, remove, or launch anything. |

Internal runtime actions may include Analyze, Apply, Default, or Restore according to config/runtime state, but the normal customer-facing AXIS first-use wizard exposes only the owner-approved Apply action recorded here.

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Microsoft Edge Settings` |
| Subtitle | `Ø¶Ø¨Ø· Microsoft Edge ÙˆØªÙ‚Ù„ÙŠÙ„ Ø§Ù„Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠØ©.` |
| Primary action button | `Optimize Microsoft Edge` |
| Information card title | `ØªØ­Ø³ÙŠÙ† Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ù…ØªØµÙØ­` |
| Information card bullet 1 | `Ø¶Ø¨Ø· Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Microsoft Edge Ù„ØªØ¬Ø±Ø¨Ø© Ø§Ø³ØªØ®Ø¯Ø§Ù… Ø£Ù†Ø¸Ù.` |
| Information card bullet 2 | `ØªÙ‚Ù„ÙŠÙ„ Ø§Ù„Ø¹Ù†Ø§ØµØ± ÙˆØ§Ù„Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠØ© Ø¯Ø§Ø®Ù„ Ø§Ù„Ù…ØªØµÙØ­.` |
| Information card bullet 3 | `ÙŠØªÙ… ØªØ·Ø¨ÙŠÙ‚ Ø§Ù„Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ù…Ù†Ø§Ø³Ø¨Ø© ØªÙ„Ù‚Ø§Ø¦ÙŠÙ‹Ø§ Ø£Ø«Ù†Ø§Ø¡ Ù‡Ø°Ù‡ Ø§Ù„Ø®Ø·ÙˆØ©.` |
| Requirements card | Not shown |
| Confirmation overlay | Not shown |
| Running state | `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°` |
| Completed state | `Ù…ÙƒØªÙ…Ù„` |

## Requirements Card

No requirements card should be shown.

## Confirmation Overlay

No confirmation overlay should be shown.

## Analyze, Default, And Restore Boundary

Do not expose Analyze, Default, or Restore in the normal customer UI now.

## Runtime Status And Completion

During simulated action, show `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°`.

After simulated completion, show `Ù…ÙƒØªÙ…Ù„`.

After completion, show no additional customer-facing text. Only enable the Next button.

## Customer-Facing Restrictions

Do not show Registry details.

Do not show services details.

Do not show download, install, or cleanup internals.

Do not show file paths, commands, diagnostics, logs, internal action names, Tasks names, modules, hashes, command output, validation results, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not change Edge settings, write Registry values, change services, download, install, clean, remove, launch external processes, mutate host state, or run Apply, Default, Restore, Open, or Analyze.

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

Title and primary action are English-only and should render LTR while remaining physically right-anchored.

`Microsoft Edge` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, Edge mutation, downloads, installers, cleanup, service mutation, Registry mutation, host mutation, staging, committing, or pushing.
