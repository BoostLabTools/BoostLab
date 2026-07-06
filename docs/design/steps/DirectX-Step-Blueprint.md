# AXIS DirectX Step Blueprint

Date: 2026-07-06
Scope: owner-approved Graphics-stage customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `directx` Graphics-stage step.

This phase is documentation-only. It does not implement UI behavior, download anything, extract packages, install DirectX, run DXSETUP, install or configure 7-Zip, modify files, registry, system settings, Windows components, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `directx` |
| Customer-facing step title | `DirectX` |
| Stage | `Graphics` |
| Visible stage label | `Graphics` |
| Production action mapping | customer-facing `ØªØ«Ø¨ÙŠØª DirectX` maps later to internal `Apply` for `directx` |
| Prototype behavior | Simulation only. Do not download anything. Do not extract packages. Do not install DirectX. Do not run DXSETUP. Do not install or configure 7-Zip. Do not modify files, registry, system settings, or Windows components. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `DirectX` |
| Subtitle | `ØªØ«Ø¨ÙŠØª Ù…ÙƒÙˆÙ†Ø§Øª DirectX Ø§Ù„Ù…Ø·Ù„ÙˆØ¨Ø© Ù„Ù„Ø£Ù„Ø¹Ø§Ø¨ ÙˆØ§Ù„Ø¨Ø±Ø§Ù…Ø¬.` |
| Primary action button | `ØªØ«Ø¨ÙŠØª DirectX` |
| Information card title | `Ù…ÙƒÙˆÙ†Ø§Øª ØªØ´ØºÙŠÙ„ Ø§Ù„Ø£Ù„Ø¹Ø§Ø¨ ÙˆØ§Ù„Ø¨Ø±Ø§Ù…Ø¬` |
| Information card bullet 1 | `ØªØ«Ø¨ÙŠØª Ù…ÙƒÙˆÙ†Ø§Øª DirectX Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠØ© Ù„ØªØ´ØºÙŠÙ„ Ø§Ù„Ø¹Ø¯ÙŠØ¯ Ù…Ù† Ø§Ù„Ø£Ù„Ø¹Ø§Ø¨ ÙˆØ§Ù„Ø¨Ø±Ø§Ù…Ø¬.` |
| Information card bullet 2 | `ØªØ³Ø§Ø¹Ø¯ Ù‡Ø°Ù‡ Ø§Ù„Ù…ÙƒÙˆÙ†Ø§Øª Ø¹Ù„Ù‰ ØªØ­Ø³ÙŠÙ† ØªÙˆØ§ÙÙ‚ Ø§Ù„Ø£Ù„Ø¹Ø§Ø¨ ÙˆØ§Ù„Ø¨Ø±Ø§Ù…Ø¬ Ù…Ø¹ Windows.` |
| Information card bullet 3 | `ÙŠØªÙ… ØªØ¬Ù‡ÙŠØ² Ø§Ù„Ù…ÙƒÙˆÙ†Ø§Øª ÙˆØªØ«Ø¨ÙŠØªÙ‡Ø§ ØªÙ„Ù‚Ø§Ø¦ÙŠÙ‹Ø§ Ø£Ø«Ù†Ø§Ø¡ Ù‡Ø°Ù‡ Ø§Ù„Ø®Ø·ÙˆØ©.` |
| Requirements card | Not shown |
| Confirmation overlay | Not shown |
| Running state | `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªØ­Ù…ÙŠÙ„` |
| Completed state | `Ù…ÙƒØªÙ…Ù„` |

## Requirements Card

No requirements card should be shown.

## Confirmation Overlay

No confirmation overlay should be shown.

## Runtime Status And Completion

During simulated action, show `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªØ­Ù…ÙŠÙ„`.

After simulated completion, show `Ù…ÙƒØªÙ…Ù„`.

After completion, show no additional customer-facing text. Only enable the Next button.

## Customer-Facing Restrictions

Do not show download URLs.

Do not show package names.

Do not show DXSETUP.

Do not show extraction details.

Do not show hashes, logs, PowerShell commands, internal installation details, installer filenames, driver package filenames, file paths, diagnostics, validation results, command output, internal modules, Registry names, Services names, Tasks names, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not download anything, extract packages, install DirectX, run DXSETUP, install or configure 7-Zip, modify files, registry, system settings, Windows components, Defender, USB, boot settings, firmware settings, host configuration, or run Apply, Open, Default, Restore, or Analyze.

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

`DirectX` and `Windows` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, downloads, extraction, DirectX installation, DXSETUP execution, 7-Zip installation/configuration, Registry mutation, host mutation, staging, committing, or pushing.
