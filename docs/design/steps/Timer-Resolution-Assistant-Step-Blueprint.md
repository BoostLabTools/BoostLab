# AXIS Timer Resolution Assistant Step Blueprint

Date: 2026-07-06
Scope: owner-approved Advanced customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `timer-resolution-assistant` Advanced-stage step.

This phase is documentation-only. It does not implement UI behavior, create a real service, remove a real service, build binaries, run compiler/build workflows, modify services, modify registry, modify files, modify system settings, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `timer-resolution-assistant` |
| Customer-facing step title | `Timer Resolution Assistant` |
| Stage | `Advanced` |
| Visible stage label | `Advanced` |
| Production action mapping | customer-facing `ØªÙØ¹ÙŠÙ„ Timer Resolution` maps later to internal `Apply` for `timer-resolution-assistant` |
| Analyze/Default actions | Do not expose Analyze or Default in normal customer UI now |
| Prototype behavior | Simulation only. Do not create a real service. Do not remove a real service. Do not build binaries. Do not run compiler/build workflows. Do not modify services, registry, files, system settings, or host configuration. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Timer Resolution Assistant` |
| Subtitle | `Ø¶Ø¨Ø· Timer Resolution Ù„ØªØ­Ø³ÙŠÙ† Ø§Ø³ØªØ¬Ø§Ø¨Ø© Ø§Ù„Ù†Ø¸Ø§Ù….` |
| Primary action button | `ØªÙØ¹ÙŠÙ„ Timer Resolution` |
| Information card title | `ØªØ­Ø³ÙŠÙ† Ø§Ø³ØªØ¬Ø§Ø¨Ø© Ø§Ù„Ù†Ø¸Ø§Ù…` |
| Information card bullet 1 | `ØªÙØ¹ÙŠÙ„ Ø¥Ø¹Ø¯Ø§Ø¯ Timer Resolution Ù„ØªØ­Ø³ÙŠÙ† Ø§Ø³ØªØ¬Ø§Ø¨Ø© Ø§Ù„Ù†Ø¸Ø§Ù… Ø£Ø«Ù†Ø§Ø¡ Ø§Ù„Ø§Ø³ØªØ®Ø¯Ø§Ù….` |
| Information card bullet 2 | `ÙŠØ³Ø§Ø¹Ø¯ Ø°Ù„Ùƒ Ø¹Ù„Ù‰ Ø¬Ø¹Ù„ Ø§Ù„ØªÙØ§Ø¹Ù„ Ù…Ø¹ Ø§Ù„Ù†Ø¸Ø§Ù… Ø£ÙƒØ«Ø± Ø³Ù„Ø§Ø³Ø©.` |
| Information card bullet 3 | `ÙŠØªÙ… ØªØ·Ø¨ÙŠÙ‚ Ø§Ù„Ø¥Ø¹Ø¯Ø§Ø¯ Ø§Ù„Ù…Ù†Ø§Ø³Ø¨ ØªÙ„Ù‚Ø§Ø¦ÙŠÙ‹Ø§ Ø£Ø«Ù†Ø§Ø¡ Ù‡Ø°Ù‡ Ø§Ù„Ø®Ø·ÙˆØ©.` |
| Requirements card | Not shown |
| Confirmation overlay | Not shown |
| Running state | `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°` |
| Completed state | `Ù…ÙƒØªÙ…Ù„` |
| Support panel title | `Ù…Ø³Ø§Ø¹Ø¯Ø©` |
| Support panel body | `ØªØ­ØªØ§Ø¬ Ù…Ø³Ø§Ø¹Ø¯Ø©ØŸ ÙŠÙ…ÙƒÙ†Ùƒ Ø§Ù„ØªÙˆØ§ØµÙ„ Ù…Ø¹ Ø£Ø®ØµØ§Ø¦ÙŠ Ø§Ù„Ø¯Ø¹Ù… Ø¹Ø¨Ø± Ø®Ø§Ø¯Ù… Discord Ø§Ù„Ø®Ø§Øµ Ø¨Ø§Ù„Ù…ØªØ¬Ø±.` |

## Runtime Status And Completion

During simulated action, show `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°`.

After simulated completion, show `Ù…ÙƒØªÙ…Ù„`.

After completion, show no additional customer-facing text. Only enable the Next button.

## Requirements And Overlay

No requirements card should be shown.

No confirmation overlay should be shown.

## Customer-Facing Restrictions

Do not show service names.

Do not show service creation details.

Do not show compiler details.

Do not show build logs.

Do not show file paths.

Do not show PowerShell commands.

Do not show diagnostics, validation results, command output, internal modules, Registry names, Services names, Tasks names, Defender internals, security internals, driver names, TrustedInstaller details, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not create a real service, remove a real service, build binaries, run compiler/build workflows, modify services, registry, files, system settings, host configuration, or run Apply, Open, Default, Restore, or Analyze.

## Advanced UI Layout Contract

Preserve the global Advanced-stage AXIS layout: `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, no PNG/SVG/WPF vector placeholders, RTL with physical right-edge anchoring, Advanced active, prior Check/Refresh/Setup/Installers/Graphics/Windows stages completed green, active Advanced full white line, no partial progress line, support card separate from runtime status, runtime status near the primary action button, Next disabled until completion then blue, no auto-advance, Previous returns to the previous step, enabled buttons use hand cursor, disabled buttons do not hover, press, or use hand cursor, hover is crisp and readable with no grow/scale/blur, and pressed state is a subtle pressed-in effect.

## BiDi And Layout Notes

Title is English-only and should render LTR while remaining physically right-anchored.

`Timer Resolution` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, service creation/removal, binary builds, compiler workflows, Registry mutation, Services mutation, host mutation, staging, committing, or pushing.
