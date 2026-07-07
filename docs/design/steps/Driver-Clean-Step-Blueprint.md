# AXIS Driver Clean Step Blueprint

Date: 2026-07-06
Scope: owner-approved Graphics-stage customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `driver-clean` Graphics-stage step.

This phase is documentation-only. It does not implement UI behavior, launch DDU, clean real drivers, enter Safe Mode, restart the computer, modify drivers, devices, services, registry, boot configuration, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `driver-clean` |
| Customer-facing step title | `Driver Clean` |
| Stage | `Graphics` |
| Visible stage label | `Graphics` |
| Production action mapping | customer-facing `ØªÙ†Ø¸ÙŠÙ Ø§Ù„ØªØ¹Ø±ÙŠÙØ§Øª` maps later to internal `Apply` for `driver-clean` |
| Production behavior note | The future AXIS primary action should map to the real BoostLab Auto path for this tool, not manual behavior. Do not change the real script behavior. The AXIS UI must reflect the existing automatic BoostLab behavior. |
| Prototype behavior | Simulation only. Do not launch DDU. Do not clean real drivers. Do not enter Safe Mode. Do not restart the computer. Do not modify drivers, devices, services, registry, or boot configuration. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Driver Clean` |
| Subtitle | `ØªÙ†Ø¸ÙŠÙ ØªØ¹Ø±ÙŠÙØ§Øª ÙƒØ±Øª Ø§Ù„Ø´Ø§Ø´Ø© Ù‚Ø¨Ù„ ØªØ«Ø¨ÙŠØª Ø§Ù„ØªØ¹Ø±ÙŠÙ Ø§Ù„Ø¬Ø¯ÙŠØ¯.` |
| Primary action button | `ØªÙ†Ø¸ÙŠÙ Ø§Ù„ØªØ¹Ø±ÙŠÙØ§Øª` |
| Information card title | `ØªÙ†Ø¸ÙŠÙ ØªØ¹Ø±ÙŠÙØ§Øª ÙƒØ±Øª Ø§Ù„Ø´Ø§Ø´Ø©` |
| Information card bullet 1 | `تنظيف تعريفات كرت الشاشة القديمة قبل تثبيت التعريف الجديد.` |
| Information card bullet 2 | `يتم تنفيذ خطوة التنظيف تلقائيًا حسب المسار المعتمد.` |
| Information card bullet 3 | `بعد اكتمال التنظيف، يمكنك متابعة إعداد التعريف الجديد.` |
| Requirements card title | `Ø§Ù„Ù…ØªØ·Ù„Ø¨Ø§Øª` |
| Requirements bullet 1 | `Ø§Ù‚Ø±Ø£ Ø§Ù„ØªØ¹Ù„ÙŠÙ…Ø§Øª Ù‚Ø¨Ù„ Ø¨Ø¯Ø¡ ØªÙ†Ø¸ÙŠÙ Ø§Ù„ØªØ¹Ø±ÙŠÙØ§Øª.` |
| Requirements bullet 2 | `Ø§Ø­ÙØ¸ Ø£ÙŠ Ø¹Ù…Ù„ Ù…ÙØªÙˆØ­ Ù‚Ø¨Ù„ Ø§Ù„Ù…ØªØ§Ø¨Ø¹Ø©.` |
| Requirements bullet 3 | `Ø§Ù†ØªØ¸Ø± Ø­ØªÙ‰ ØªÙƒØªÙ…Ù„ Ø§Ù„Ø¹Ù…Ù„ÙŠØ© Ø¨Ø§Ù„ÙƒØ§Ù…Ù„.` |
| Confirmation checkbox | `Ù„Ù‚Ø¯ Ù‚Ø±Ø£Øª Ø§Ù„ØªØ¹Ù„ÙŠÙ…Ø§Øª` |
| Confirmation primary button | `ØªÙ†Ø¸ÙŠÙ Ø§Ù„ØªØ¹Ø±ÙŠÙØ§Øª` |
| Confirmation return button | `Ø±Ø¬ÙˆØ¹` |
| Running state | `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°` |
| Completed state | `Ù…ÙƒØªÙ…Ù„` |

## Information Card Scope

The normal in-app information card intentionally uses short, readable copy. Detailed instructional content belongs behind the Instructions flow and the future AXIS website, not in the normal customer-facing card. Do not add a URL in this blueprint.

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

Do not show DDU logs.

Do not show Safe Mode internals.

Do not show driver package details.

Do not show PowerShell commands.

Do not show technical failure/error output.

Do not show implementation details beyond the approved copy above.

Do not show download URLs, hashes, installer filenames, driver package filenames, file paths, logs, diagnostics, validation results, command output, internal modules, Registry names, Services names, Tasks names, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not launch DDU, clean real drivers, enter Safe Mode, restart the computer, modify drivers, devices, services, registry, boot configuration, Defender, USB, firmware settings, system files, Windows settings, host configuration, or run Apply, Open, Default, Restore, or Analyze.

## Graphics UI Layout Contract

The future Graphics prototype should preserve `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, no PNG/SVG/WPF vector placeholders, Arabic-first copy except owner-approved English titles/buttons/tokens, RTL layout with physical right-edge anchoring, and the stage strip logical order Check, Refresh, Setup, Installers, Graphics, Windows, Advanced.

For Arabic, the visual order is mirrored while logical stage order remains correct. Graphics is active for this step. Previous Check, Refresh, Setup, and Installers stages are completed green. Active Graphics uses a full white line. There is no partial or incomplete progress line.

The support card appears in every step and remains separate from runtime status:

| Surface | Owner-approved value |
| --- | --- |
| Support card title | `Ù…Ø³Ø§Ø¹Ø¯Ø©` |
| Support card body | `ØªØ­ØªØ§Ø¬ Ù…Ø³Ø§Ø¹Ø¯Ø©ØŸ ÙŠÙ…ÙƒÙ†Ùƒ Ø§Ù„ØªÙˆØ§ØµÙ„ Ù…Ø¹ Ø£Ø®ØµØ§Ø¦ÙŠ Ø§Ù„Ø¯Ø¹Ù… Ø¹Ø¨Ø± Ø®Ø§Ø¯Ù… Discord Ø§Ù„Ø®Ø§Øµ Ø¨Ø§Ù„Ù…ØªØ¬Ø±.` |

Runtime status stays near the primary action button. Next is disabled until action simulation completes, then enabled and blue. There is no auto-advance after normal completion. Previous returns to the previous step.

Enabled buttons use hand cursor. Disabled buttons do not hover, do not press, and do not use hand cursor. Hover must be crisp and readable, with no grow, scale, or blur. Pressed state should be a subtle pressed-in effect.

## BiDi And Layout Notes

Title is English-only and should render LTR while remaining physically right-anchored.

If future detailed instructional content mentions `DDU` or `Safe Mode`, those English tokens must be rendered safely. They are not part of the normal in-card copy.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, DDU launch, NVIDIA installer launch, downloads, Safe Mode, restart, driver mutation, Registry mutation, service mutation, host mutation, staging, committing, or pushing.
