# AXIS Graphics Configuration Center Step Blueprint

Date: 2026-07-06
Scope: owner-approved Graphics-stage customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `graphics-configuration-center` Graphics-stage step.

This phase is documentation-only. It does not implement UI behavior, open Windows Settings, open graphics control panels, change graphics settings, modify registry, system settings, drivers, GPU configuration, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `graphics-configuration-center` |
| Customer-facing step title | `Graphics Configuration Center` |
| Stage | `Graphics` |
| Visible stage label | `Graphics` |
| Production action mapping | customer-facing `ÙØªØ­ Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ø±Ø³ÙˆÙ…Ø§Øª` maps later to internal `Open` for `graphics-configuration-center` |
| Prototype behavior | Simulation only. Do not open Windows Settings. Do not open graphics control panels. Do not change graphics settings. Do not modify registry, system settings, drivers, or GPU configuration. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Graphics Configuration Center` |
| Subtitle | `ÙØªØ­ Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ø±Ø³ÙˆÙ…Ø§Øª Ù„Ù„Ù…Ø±Ø§Ø¬Ø¹Ø©.` |
| Primary action button | `ÙØªØ­ Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ø±Ø³ÙˆÙ…Ø§Øª` |
| Information card title | `Ù…Ø±Ø§Ø¬Ø¹Ø© Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ø±Ø³ÙˆÙ…Ø§Øª` |
| Information card bullet 1 | `Ø§ÙØªØ­ Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ø±Ø³ÙˆÙ…Ø§Øª Ø¯Ø§Ø®Ù„ Windows Ù„Ù…Ø±Ø§Ø¬Ø¹Ø© Ø®ÙŠØ§Ø±Ø§Øª Ø§Ù„Ø£Ø¯Ø§Ø¡.` |
| Information card bullet 2 | `ØªØ£ÙƒØ¯ Ø£Ù† Ø®ÙŠØ§Ø± Optimizations for windowed games Ù…Ø¶Ø¨ÙˆØ· Ø¹Ù„Ù‰ ON.` |
| Information card bullet 3 | `ØªØ£ÙƒØ¯ Ø£Ù† Ø®ÙŠØ§Ø± Hardware-accelerated GPU scheduling Ù…Ø¶Ø¨ÙˆØ· Ø¹Ù„Ù‰ ON.` |
| Requirements card | Not shown |
| Confirmation overlay | Not shown |
| Running state | `ÙØªØ­ Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ø±Ø³ÙˆÙ…Ø§Øª` |
| Completed state | `Ù…ÙƒØªÙ…Ù„` |

## Requirements Card

No requirements card should be shown.

## Confirmation Overlay

No confirmation overlay should be shown.

## Runtime Status And Completion

During simulated action, show `ÙØªØ­ Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ø±Ø³ÙˆÙ…Ø§Øª`.

After simulated completion, show `Ù…ÙƒØªÙ…Ù„`.

After completion, show no additional customer-facing text. Only enable the Next button.

## Customer-Facing Restrictions

Do not show settings URI.

Do not show commands used to open settings.

Do not show system diagnostics.

Do not show internal implementation details.

Do not show PowerShell details, download URLs, hashes, installer filenames, driver package filenames, file paths, logs, validation results, command output, internal modules, Registry names, Services names, Tasks names, or diagnostics.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not open Windows Settings, open graphics control panels, change graphics settings, modify registry, system settings, drivers, GPU configuration, Defender, USB, boot settings, firmware settings, system files, host configuration, or run Apply, Open, Default, Restore, or Analyze.

## Graphics UI Layout Contract

The future Graphics prototype should preserve `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, no PNG/SVG/WPF vector placeholders, Arabic-first copy except owner-approved English titles/buttons/tokens, RTL layout with physical right-edge anchoring, and the stage strip logical order Check, Refresh, Setup, Installers, Graphics, Windows, Advanced.

Graphics is active for this step. Previous Check, Refresh, Setup, and Installers stages are completed green. Active Graphics uses a full white line. There is no partial or incomplete progress line.

Support card remains separate from runtime status and uses the unchanged global support copy:

| Surface | Owner-approved value |
| --- | --- |
| Support card title | `Ù…Ø³Ø§Ø¹Ø¯Ø©` |
| Support card body | `ØªØ­ØªØ§Ø¬ Ù…Ø³Ø§Ø¹Ø¯Ø©ØŸ ÙŠÙ…ÙƒÙ†Ùƒ Ø§Ù„ØªÙˆØ§ØµÙ„ Ù…Ø¹ Ø£Ø®ØµØ§Ø¦ÙŠ Ø§Ù„Ø¯Ø¹Ù… Ø¹Ø¨Ø± Ø®Ø§Ø¯Ù… Discord Ø§Ù„Ø®Ø§Øµ Ø¨Ø§Ù„Ù…ØªØ¬Ø±.` |

Runtime status stays near the primary action button. Next is disabled until action simulation completes, then enabled and blue. There is no auto-advance after normal completion. Previous returns to the previous step.

Enabled buttons use hand cursor. Disabled buttons do not hover, do not press, and do not use hand cursor. Hover must be crisp and readable, with no grow, scale, or blur. Pressed state should be a subtle pressed-in effect.

## BiDi And Layout Notes

Title is English-only and should render LTR while remaining physically right-anchored.

`Windows`, `Optimizations for windowed games`, `ON`, and `Hardware-accelerated GPU scheduling` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, Windows Settings launch, graphics control panel launch, graphics setting mutation, driver mutation, Registry mutation, host mutation, staging, committing, or pushing.
