# AXIS Defender Optimize Assistant Step Blueprint

Date: 2026-07-06
Scope: owner-approved Advanced customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `defender-optimize-assistant` Advanced-stage step.

This phase is documentation-only. It does not implement UI behavior, modify Defender, change security settings, enter Safe Mode, restart the computer, use TrustedInstaller, modify drivers, modify registry, modify services, modify files, modify Defender settings, modify system files, modify Windows settings, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `defender-optimize-assistant` |
| Customer-facing step title | `Defender Optimize Assistant` |
| Stage | `Advanced` |
| Visible stage label | `Advanced` |
| Production action mapping | customer-facing `Apply Defender Optimize` maps later to internal `Apply` for `defender-optimize-assistant` |
| Analyze/Default actions | Do not expose Analyze or Default in normal customer UI now |
| Prototype behavior | Simulation only. Do not modify Defender. Do not change security settings. Do not enter Safe Mode. Do not restart the computer. Do not use TrustedInstaller. Do not modify drivers. Do not modify registry, services, files, Defender settings, system files, Windows settings, or host configuration. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Defender Optimize Assistant` |
| Subtitle | `Ø¶Ø¨Ø· Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Defender Ù„ØªØ­Ø³ÙŠÙ† Ø§Ù„ØªØ¬Ø±Ø¨Ø©.` |
| Primary action button | `Apply Defender Optimize` |
| Information card title | `ØªØ­Ø³ÙŠÙ† Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Defender` |
| Information card bullet 1 | `ØªØ·Ø¨ÙŠÙ‚ Ù…Ø³Ø§Ø± BoostLab Ø§Ù„Ù…Ø¹ØªÙ…Ø¯ Ù„Ø¶Ø¨Ø· Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Defender.` |
| Information card bullet 2 | `ÙŠØªÙ… ØªÙ†ÙÙŠØ° Ø§Ù„Ù…Ø³Ø§Ø± ØªÙ„Ù‚Ø§Ø¦ÙŠÙ‹Ø§ØŒ Ø¨Ù…Ø§ ÙÙŠ Ø°Ù„Ùƒ Ø¥Ø¹Ø§Ø¯Ø© Ø§Ù„ØªØ´ØºÙŠÙ„ ÙˆØ§Ù„Ø¯Ø®ÙˆÙ„ Ø¥Ù„Ù‰ Safe Mode Ø¹Ù†Ø¯ Ø§Ù„Ø­Ø§Ø¬Ø©.` |
| Information card bullet 3 | `Ø¨Ø¹Ø¯ Ø§ÙƒØªÙ…Ø§Ù„ Ø§Ù„Ù…Ø³Ø§Ø±ØŒ ÙŠØ¹ÙˆØ¯ Ø§Ù„Ø¬Ù‡Ø§Ø² Ù„Ù„ÙˆØ¶Ø¹ Ø§Ù„Ø·Ø¨ÙŠØ¹ÙŠ Ù„Ø§Ø³ØªÙƒÙ…Ø§Ù„ Ø§Ù„Ø¥Ø¹Ø¯Ø§Ø¯.` |
| Requirements card title | `Ø§Ù„Ù…ØªØ·Ù„Ø¨Ø§Øª` |
| Requirements bullet 1 | `Ø§Ù‚Ø±Ø£ Ø§Ù„ØªØ¹Ù„ÙŠÙ…Ø§Øª Ù‚Ø¨Ù„ Ø¨Ø¯Ø¡ Ø¶Ø¨Ø· Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Defender.` |
| Requirements bullet 2 | `Ø§Ø­ÙØ¸ Ø£ÙŠ Ø¹Ù…Ù„ Ù…ÙØªÙˆØ­ Ù‚Ø¨Ù„ Ø§Ù„Ù…ØªØ§Ø¨Ø¹Ø©.` |
| Requirements bullet 3 | `Ø§Ù†ØªØ¸Ø± Ø­ØªÙ‰ ØªÙƒØªÙ…Ù„ Ø§Ù„Ø¹Ù…Ù„ÙŠØ© Ø¨Ø§Ù„ÙƒØ§Ù…Ù„.` |
| Confirmation checkbox | `Ù„Ù‚Ø¯ Ù‚Ø±Ø£Øª Ø§Ù„ØªØ¹Ù„ÙŠÙ…Ø§Øª` |
| Confirmation primary button | `Apply Defender Optimize` |
| Confirmation return button | `Ø±Ø¬ÙˆØ¹` |
| Running state | `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°` |
| Completed state | `Ù…ÙƒØªÙ…Ù„` |
| Support panel title | `Ù…Ø³Ø§Ø¹Ø¯Ø©` |
| Support panel body | `ØªØ­ØªØ§Ø¬ Ù…Ø³Ø§Ø¹Ø¯Ø©ØŸ ÙŠÙ…ÙƒÙ†Ùƒ Ø§Ù„ØªÙˆØ§ØµÙ„ Ù…Ø¹ Ø£Ø®ØµØ§Ø¦ÙŠ Ø§Ù„Ø¯Ø¹Ù… Ø¹Ø¨Ø± Ø®Ø§Ø¯Ù… Discord Ø§Ù„Ø®Ø§Øµ Ø¨Ø§Ù„Ù…ØªØ¬Ø±.` |

## Requirements Card

Show a requirements card titled `Ø§Ù„Ù…ØªØ·Ù„Ø¨Ø§Øª`.

Requirements bullets:

- `Ø§Ù‚Ø±Ø£ Ø§Ù„ØªØ¹Ù„ÙŠÙ…Ø§Øª Ù‚Ø¨Ù„ Ø¨Ø¯Ø¡ Ø¶Ø¨Ø· Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Defender.`
- `Ø§Ø­ÙØ¸ Ø£ÙŠ Ø¹Ù…Ù„ Ù…ÙØªÙˆØ­ Ù‚Ø¨Ù„ Ø§Ù„Ù…ØªØ§Ø¨Ø¹Ø©.`
- `Ø§Ù†ØªØ¸Ø± Ø­ØªÙ‰ ØªÙƒØªÙ…Ù„ Ø§Ù„Ø¹Ù…Ù„ÙŠØ© Ø¨Ø§Ù„ÙƒØ§Ù…Ù„.`

## Confirmation Overlay

Use a confirmation overlay with the checkbox text `Ù„Ù‚Ø¯ Ù‚Ø±Ø£Øª Ø§Ù„ØªØ¹Ù„ÙŠÙ…Ø§Øª`.

The primary overlay button is `Apply Defender Optimize` and stays disabled until the checkbox is checked.

The checkbox checked fill is blue with no checkmark, matching the approved existing pattern.

`Ø±Ø¬ÙˆØ¹` closes the overlay only.

No Cancel button should appear.

## Runtime Status And Completion

During simulated action, show `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°`.

After simulated completion, show `Ù…ÙƒØªÙ…Ù„`.

After completion, show no additional customer-facing text. Only enable the Next button.

## Customer-Facing Restrictions

Do not show Defender internals.

Do not show security internals.

Do not show service names.

Do not show driver names.

Do not show Registry names.

Do not show TrustedInstaller details.

Do not show system file details.

Do not show logs.

Do not show diagnostics.

Do not show PowerShell commands.

Do not show technical failure/error output.

Do not show validation results, command output, internal modules, file paths, Services names, Tasks names, or implementation details beyond the approved copy above.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not modify Defender, change security settings, enter Safe Mode, restart the computer, use TrustedInstaller, modify drivers, modify registry, services, files, Defender settings, system files, Windows settings, host configuration, or run Apply, Open, Default, Restore, or Analyze.

## Advanced UI Layout Contract

Preserve the global Advanced-stage AXIS layout: `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, no PNG/SVG/WPF vector placeholders, RTL with physical right-edge anchoring, Advanced active, prior Check/Refresh/Setup/Installers/Graphics/Windows stages completed green, active Advanced full white line, no partial progress line, support card separate from runtime status, runtime status near the primary action button, Next disabled until completion then blue, no auto-advance, Previous returns to the previous step, enabled buttons use hand cursor, disabled buttons do not hover, press, or use hand cursor, hover is crisp and readable with no grow/scale/blur, and pressed state is a subtle pressed-in effect.

## BiDi And Layout Notes

Title and primary action are English-only and should render LTR while remaining physically right-anchored.

`Defender`, `BoostLab`, and `Safe Mode` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, Defender mutation, Safe Mode entry, restart, TrustedInstaller use, driver mutation, Registry mutation, Services mutation, security mutation, host mutation, staging, committing, or pushing.
