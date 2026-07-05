# AXIS BitLocker Step Blueprint

Date: 2026-07-06
Scope: owner-approved Setup-stage customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `bitlocker` Setup-stage step.

This phase is documentation-only. It does not implement UI behavior, query BitLocker, change disk encryption, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `bitlocker` |
| Customer-facing step title | `BitLocker` |
| Stage | `Setup` |
| Visible stage label | `Setup` |
| Production action mapping | customer-facing `Ø¥ÙŠÙ‚Ø§Ù BitLocker` maps later to internal `Apply` for `bitlocker` |
| Prototype behavior | Simulation only. No real BitLocker query, no real BitLocker change, no disk encryption/decryption action. |

Internal runtime actions may include Analyze, Apply, Default, Restore, or Open according to config/runtime state, but the customer-facing AXIS first-use wizard exposes only the owner-approved action recorded here.

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `BitLocker` |
| Subtitle | `ØªØ¹Ø·ÙŠÙ„ ØªØ´ÙÙŠØ± BitLocker Ø¹Ù„Ù‰ Ø§Ù„Ù‚Ø±Øµ.` |
| Primary action button | `Ø¥ÙŠÙ‚Ø§Ù BitLocker` |
| Information card title | `ØªØ¹Ø·ÙŠÙ„ ØªØ´ÙÙŠØ± Ø§Ù„Ù‚Ø±Øµ` |
| Information card bullet 1 | `ØªØ¹Ø·ÙŠÙ„ ØªÙ‚Ù†ÙŠØ© BitLocker Ø¹Ù„Ù‰ Ø§Ù„Ù‚Ø±Øµ.` |
| Information card bullet 2 | `ÙŠØ³Ø§Ø¹Ø¯ Ø°Ù„Ùƒ Ø¹Ù„Ù‰ Ø¥Ø²Ø§Ù„Ø© Ø§Ù„ØªØ´ÙÙŠØ± Ù…Ù† Ø§Ù„Ù‚Ø±Øµ Ù‚Ø¨Ù„ Ù…ØªØ§Ø¨Ø¹Ø© Ø¥Ø¹Ø¯Ø§Ø¯ Ø§Ù„Ù†Ø¸Ø§Ù….` |
| Information card bullet 3 | `Ø¨Ø¹Ø¯ Ø§ÙƒØªÙ…Ø§Ù„ Ø§Ù„Ø®Ø·ÙˆØ©ØŒ ÙŠØµØ¨Ø­ Ø§Ù„Ù‚Ø±Øµ Ø¬Ø§Ù‡Ø²Ù‹Ø§ Ù„Ù„Ù…ØªØ§Ø¨Ø¹Ø© Ø¨Ø¯ÙˆÙ† ØªØ´ÙÙŠØ± BitLocker.` |
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

Do not mention Recovery Key in the normal customer UI.

Do not show disk identifiers, volume names, protection status, encryption method, PowerShell commands, or BitLocker diagnostics.

Do not show internal action names, Registry names, Services names, Tasks names, file paths, modules, logs, hashes, command output, validation results, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not query BitLocker, disable BitLocker, enable BitLocker, open BitLocker Control Panel, change disk encryption state, touch disk protection, mutate host state, or run Analyze, Apply, Default, Restore, or Open.

## Setup UI Layout Contract

The future Setup prototype should preserve `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, no PNG/SVG/WPF vector placeholders, Arabic-first copy except owner-approved English titles/buttons, RTL layout with physical right-edge anchoring, and the stage strip logical order Check, Refresh, Setup, Installers, Graphics, Windows, Advanced.

For Arabic, the visual order is mirrored while logical stage order remains correct. Setup is active, previous Check and Refresh stages are completed green, active Setup uses a full white line, and there is no partial progress line.

The support card appears in every Setup step and remains separate from runtime status:

| Surface | Owner-approved value |
| --- | --- |
| Support card title | `Ù…Ø³Ø§Ø¹Ø¯Ø©` |
| Support card body | `ØªØ­ØªØ§Ø¬ Ù…Ø³Ø§Ø¹Ø¯Ø©ØŸ ÙŠÙ…ÙƒÙ†Ùƒ Ø§Ù„ØªÙˆØ§ØµÙ„ Ù…Ø¹ Ø£Ø®ØµØ§Ø¦ÙŠ Ø§Ù„Ø¯Ø¹Ù… Ø¹Ø¨Ø± Ø®Ø§Ø¯Ù… Discord Ø§Ù„Ø®Ø§Øµ Ø¨Ø§Ù„Ù…ØªØ¬Ø±.` |

Runtime status stays near the primary action button. Next is disabled until action simulation completes, then enabled and blue. There is no auto-advance. Previous returns to the previous step.

Enabled buttons use hand cursor. Disabled buttons do not hover, do not press, and do not use hand cursor. Hover must be crisp and readable, with no grow, scale, or blur. Pressed state should be a subtle pressed-in effect.

## BiDi And Layout Notes

Title is English-only and should render LTR while remaining physically right-anchored.

Mixed Arabic/English lines containing `BitLocker` must use safe rendering.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, BitLocker mutation, host mutation, staging, committing, or pushing.
