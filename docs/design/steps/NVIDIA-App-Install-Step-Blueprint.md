# AXIS NVIDIA App Install Step Blueprint

Date: 2026-07-06
Scope: owner-approved Graphics-stage customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `nvidia-app-install` Graphics-stage step.

This phase is documentation-only. It does not implement UI behavior, download NVIDIA App, run the NVIDIA App installer, clean real shortcut folders, launch apps, modify files, services, registry, Windows settings, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `nvidia-app-install` |
| Customer-facing step title | `NVIDIA App Install` |
| Stage | `Graphics` |
| Visible stage label | `Graphics` |
| Production action mapping | customer-facing `Install NVIDIA App` maps later to internal `Apply` for `nvidia-app-install` |
| Production behavior note | Future production behavior maps to the existing BoostLab `nvidia-app-install` Apply behavior. Do not change the real script behavior. |
| Prototype behavior | Simulation only. Do not download NVIDIA App. Do not run the NVIDIA App installer. Do not clean real shortcut folders. Do not launch apps. Do not modify files, services, registry, or Windows settings. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `NVIDIA App Install` |
| Subtitle | `ØªØ«Ø¨ÙŠØª ØªØ·Ø¨ÙŠÙ‚ NVIDIA Ù„Ù„Ø­ØµÙˆÙ„ Ø¹Ù„Ù‰ Ù…ÙŠØ²Ø§Øª Ø§Ù„ØªØ·Ø¨ÙŠÙ‚.` |
| Primary action button | `Install NVIDIA App` |
| Secondary optional continuation button | `Ù…ØªØ§Ø¨Ø¹Ø© Ø¨Ø¯ÙˆÙ† NVIDIA App` |
| Information card title | `ØªØ«Ø¨ÙŠØª ØªØ·Ø¨ÙŠÙ‚ NVIDIA` |
| Information card bullet 1 | `ØªØ«Ø¨ÙŠØª NVIDIA App Ù„Ù…Ù† ÙŠØ±ÙŠØ¯ Ù…ÙŠØ²Ø§Øª Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ Ù…Ø«Ù„ Ø§Ù„ØªØ³Ø¬ÙŠÙ„ ÙˆØ§Ù„ØªØµÙˆÙŠØ±.` |
| Information card bullet 2 | `ÙŠÙ…ÙƒÙ† Ù…ØªØ§Ø¨Ø¹Ø© Ø§Ù„Ø¥Ø¹Ø¯Ø§Ø¯ Ø¨Ø¯ÙˆÙ† ØªØ«Ø¨ÙŠØª Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ Ø¥Ø°Ø§ Ù„Ù… ØªÙƒÙ† ØªØ­ØªØ§Ø¬ Ù‡Ø°Ù‡ Ø§Ù„Ù…ÙŠØ²Ø§Øª.` |
| Information card bullet 3 | `ØªØ¹Ø±ÙŠÙ ÙƒØ±Øª Ø§Ù„Ø´Ø§Ø´Ø© ÙŠÙƒÙˆÙ† Ù…Ø«Ø¨ØªÙ‹Ø§ ÙˆÙ…Ø¶Ø¨ÙˆØ·Ù‹Ø§ Ù…Ù† Ø§Ù„Ø®Ø·ÙˆØ© Ø§Ù„Ø³Ø§Ø¨Ù‚Ø©.` |
| Requirements card | Not shown |
| Confirmation checkbox | `Ù„Ù‚Ø¯ Ù‚Ø±Ø£Øª Ø§Ù„ØªØ¹Ù„ÙŠÙ…Ø§Øª` |
| Confirmation primary button | `Install NVIDIA App` |
| Confirmation return button | `Ø±Ø¬ÙˆØ¹` |
| Running state | `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªØ«Ø¨ÙŠØª` |
| Completed state | `ØªÙ… Ø§Ù„ØªØ«Ø¨ÙŠØª` |

## Requirements Card

No requirements card should be shown.

## Confirmation Overlay

Use a confirmation overlay with checkbox.

The primary overlay button stays disabled until the checkbox is checked.

The checkbox checked fill is blue with no checkmark, matching the approved existing pattern.

`Ø±Ø¬ÙˆØ¹` closes the overlay only.

No Cancel button appears.

## Secondary Optional Continuation Behavior

The secondary optional continuation button appears beside the normal navigation buttons for this step.

It allows the customer to continue to the next step without installing NVIDIA App.

It must not use the words Skip, Skipped, ØªØ®Ø·ÙŠ, ØªÙ… Ø§Ù„ØªØ®Ø·ÙŠ, or Ø³ÙƒØ¨ in the normal customer UI.

It must not show a runtime status for bypassing this step.

It simply advances to the next step by owner-approved design.

It does not execute any Apply action.

## Runtime Status And Completion

During simulated action, show `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªØ«Ø¨ÙŠØª`.

After simulated completion, show `ØªÙ… Ø§Ù„ØªØ«Ø¨ÙŠØª`.

After completion, show no additional customer-facing text. Only enable the Next button.

## Customer-Facing Restrictions

Do not say this step is only for NVIDIA devices in the normal UI.

Do not show NVIDIA App download links.

Do not show installer filenames.

Do not show cleanup internals.

Do not show hashes, logs, PowerShell commands, technical failure/error output, internal action names, Registry names, Services names, Tasks names, file paths, modules, command output, validation results, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not download NVIDIA App, run the NVIDIA App installer, clean real shortcut folders, launch apps, modify files, services, registry, Windows settings, Defender, USB, boot settings, firmware settings, system files, host configuration, or run Apply, Open, Default, Restore, or Analyze.

## Graphics UI Layout Contract

The future Graphics prototype should preserve `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, no PNG/SVG/WPF vector placeholders, Arabic-first copy except owner-approved English titles/buttons/tokens, RTL layout with physical right-edge anchoring, and the stage strip logical order Check, Refresh, Setup, Installers, Graphics, Windows, Advanced.

Graphics is active for this step. Previous Check, Refresh, Setup, and Installers stages are completed green. Active Graphics uses a full white line. There is no partial or incomplete progress line.

Support card remains separate from runtime status and uses the unchanged global support copy:

| Surface | Owner-approved value |
| --- | --- |
| Support card title | `Ù…Ø³Ø§Ø¹Ø¯Ø©` |
| Support card body | `ØªØ­ØªØ§Ø¬ Ù…Ø³Ø§Ø¹Ø¯Ø©ØŸ ÙŠÙ…ÙƒÙ†Ùƒ Ø§Ù„ØªÙˆØ§ØµÙ„ Ù…Ø¹ Ø£Ø®ØµØ§Ø¦ÙŠ Ø§Ù„Ø¯Ø¹Ù… Ø¹Ø¨Ø± Ø®Ø§Ø¯Ù… Discord Ø§Ù„Ø®Ø§Øµ Ø¨Ø§Ù„Ù…ØªØ¬Ø±.` |

Runtime status stays near the primary action button. Next is disabled until action simulation completes, then enabled and blue, except the approved NVIDIA App optional continuation button documented above. There is no auto-advance after normal completion. Previous returns to the previous step.

Enabled buttons use hand cursor. Disabled buttons do not hover, do not press, and do not use hand cursor. Hover must be crisp and readable, with no grow, scale, or blur. Pressed state should be a subtle pressed-in effect.

## BiDi And Layout Notes

Title and primary action are English-only and should render LTR while remaining physically right-anchored.

`NVIDIA App` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, downloads, NVIDIA installer launch, app launch, shortcut cleanup, Registry mutation, service mutation, host mutation, staging, committing, or pushing.
