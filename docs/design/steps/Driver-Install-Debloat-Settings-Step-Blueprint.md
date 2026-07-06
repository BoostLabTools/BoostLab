# AXIS GPU Driver Setup Step Blueprint

Date: 2026-07-06
Scope: owner-approved Graphics-stage customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `driver-install-debloat-settings` Graphics-stage step.

This phase is documentation-only. It does not implement UI behavior, open NVIDIA pages, download drivers, open real file dialogs, install drivers, debloat driver packages, change GPU settings, restart the computer, modify drivers, devices, services, registry, system settings, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `driver-install-debloat-settings` |
| Customer-facing step title | `GPU Driver Setup` |
| Stage | `Graphics` |
| Visible stage label | `Graphics` |
| Production action mapping | customer-facing `ØªØ«Ø¨ÙŠØª ÙˆØ¶Ø¨Ø· Ø§Ù„ØªØ¹Ø±ÙŠÙ` maps later to internal `Apply` for `driver-install-debloat-settings` |
| Production behavior note | The AXIS UI must preserve the existing BoostLab behavior: choose one GPU branch, then run Apply. Do not change the real script behavior. Do not add support for AMD or Intel if they are not owner-enabled for AXIS customer flow now. |
| Prototype behavior | Simulation only. Do not open NVIDIA pages. Do not download drivers. Do not open file dialogs for real. Do not install drivers. Do not debloat real driver packages. Do not change GPU settings. Do not restart the computer. Do not modify drivers, devices, services, registry, or system settings. |

## Selector Behavior

Show a GPU type selector.

Selector label:

`Ø§Ø®ØªØ± Ù†ÙˆØ¹ ÙƒØ±Øª Ø§Ù„Ø´Ø§Ø´Ø©`

Selector options:

- `NVIDIA`
- `AMD â€” Ù„Ø§Ø­Ù‚Ù‹Ø§`
- `Intel â€” Ù„Ø§Ø­Ù‚Ù‹Ø§`

NVIDIA is the only selectable option in the AXIS customer UI for now.

AMD and Intel appear as disabled text-only options marked `Ù„Ø§Ø­Ù‚Ù‹Ø§`.

Do not use lock icons or any icons.

The customer can select one GPU type only.

The primary action button stays disabled until NVIDIA is selected.

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `GPU Driver Setup` |
| Subtitle | `ØªØ«Ø¨ÙŠØª ÙˆØ¶Ø¨Ø· ØªØ¹Ø±ÙŠÙ ÙƒØ±Øª Ø§Ù„Ø´Ø§Ø´Ø©.` |
| Primary action button | `ØªØ«Ø¨ÙŠØª ÙˆØ¶Ø¨Ø· Ø§Ù„ØªØ¹Ø±ÙŠÙ` |
| Information card title | `ØªØ«Ø¨ÙŠØª ÙˆØ¶Ø¨Ø· ØªØ¹Ø±ÙŠÙ ÙƒØ±Øª Ø§Ù„Ø´Ø§Ø´Ø©` |
| Information card bullet 1 | `ÙŠØªÙ… ÙØªØ­ ØµÙØ­Ø© NVIDIA Ø§Ù„Ø±Ø³Ù…ÙŠØ© Ù„ØªØ­Ù…ÙŠÙ„ Ø§Ù„ØªØ¹Ø±ÙŠÙ Ø§Ù„Ù…Ù†Ø§Ø³Ø¨ Ø­Ø³Ø¨ Ù†ÙˆØ¹ ÙƒØ±Øª Ø§Ù„Ø´Ø§Ø´Ø©.` |
| Information card bullet 2 | `Ø¨Ø¹Ø¯ ØªØ­Ù…ÙŠÙ„ Ø§Ù„ØªØ¹Ø±ÙŠÙØŒ Ø§Ø®ØªØ± Ù…Ù„Ù Ø§Ù„ØªØ¹Ø±ÙŠÙ Ù…Ù† Ù†Ø§ÙØ°Ø© Ø§Ø®ØªÙŠØ§Ø± Ø§Ù„ØªØ¹Ø±ÙŠÙ.` |
| Information card bullet 3 | `Ø¨Ø¹Ø¯ Ø§Ø®ØªÙŠØ§Ø± Ø§Ù„Ù…Ù„ÙØŒ ÙŠØªÙ… ØªØ«Ø¨ÙŠØª Ø§Ù„ØªØ¹Ø±ÙŠÙ ÙˆØ¶Ø¨Ø· Ø§Ù„Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ù…Ù†Ø§Ø³Ø¨Ø© ØªÙ„Ù‚Ø§Ø¦ÙŠÙ‹Ø§.` |
| Requirements card title | `Ø§Ù„Ù…ØªØ·Ù„Ø¨Ø§Øª` |
| Requirements bullet 1 | `Ø§Ù‚Ø±Ø£ Ø§Ù„ØªØ¹Ù„ÙŠÙ…Ø§Øª Ù‚Ø¨Ù„ Ø¨Ø¯Ø¡ ØªØ«Ø¨ÙŠØª ÙˆØ¶Ø¨Ø· Ø§Ù„ØªØ¹Ø±ÙŠÙ.` |
| Requirements bullet 2 | `Ø§Ø®ØªØ± Ù†ÙˆØ¹ ÙƒØ±Øª Ø§Ù„Ø´Ø§Ø´Ø© Ø§Ù„ØµØ­ÙŠØ­ Ù‚Ø¨Ù„ Ø§Ù„Ù…ØªØ§Ø¨Ø¹Ø©.` |
| Requirements bullet 3 | `Ø§ØªØ¨Ø¹ Ù†Ø§ÙØ°Ø© Ø§Ø®ØªÙŠØ§Ø± Ø§Ù„ØªØ¹Ø±ÙŠÙ Ø¹Ù†Ø¯ Ø¸Ù‡ÙˆØ±Ù‡Ø§.` |
| Confirmation checkbox | `Ù„Ù‚Ø¯ Ù‚Ø±Ø£Øª Ø§Ù„ØªØ¹Ù„ÙŠÙ…Ø§Øª` |
| Confirmation primary button | `ØªØ«Ø¨ÙŠØª ÙˆØ¶Ø¨Ø· Ø§Ù„ØªØ¹Ø±ÙŠÙ` |
| Confirmation return button | `Ø±Ø¬ÙˆØ¹` |
| Running state | `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°` |
| Completed state | `Ù…ÙƒØªÙ…Ù„` |

## Requirements Card

Show the requirements card using only the owner-approved title and bullets recorded above.

## Confirmation Overlay

Use a confirmation overlay with checkbox.

The primary overlay button stays disabled until the checkbox is checked.

The checkbox checked fill is blue with no checkmark, matching the approved existing pattern.

`Ø±Ø¬ÙˆØ¹` closes the overlay only.

No Cancel button appears.

## Runtime Status And Completion

During simulated action, show `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°`.

After simulated completion, show `Ù…ÙƒØªÙ…Ù„`.

After completion, show no additional customer-facing text. Only enable the Next button.

## Customer-Facing Restrictions

Do not show download URLs, driver filenames, debloat internals, hashes, logs, PowerShell commands, technical failure/error output, internal action names, Registry names, Services names, Tasks names, file paths, modules, command output, validation results, or implementation details.

Do not expose AMD or Intel as usable customer options now.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not open NVIDIA pages, download drivers, open file dialogs for real, install drivers, debloat real driver packages, change GPU settings, restart the computer, modify drivers, devices, services, registry, system settings, Defender, USB, firmware settings, system files, Windows settings, host configuration, or run Apply, Open, Default, Restore, or Analyze.

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

`NVIDIA`, `AMD`, `Intel`, and English status tokens inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, downloads, driver installation, driver debloat, file dialog launch, restart, driver mutation, Registry mutation, service mutation, host mutation, staging, committing, or pushing.
