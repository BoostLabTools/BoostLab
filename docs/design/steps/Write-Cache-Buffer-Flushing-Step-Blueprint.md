# AXIS Write Cache Buffer Flushing Step Blueprint

Date: 2026-07-06
Scope: owner-approved Windows Part B customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `write-cache-buffer-flushing` Windows-stage step.

This phase is documentation-only. It does not implement UI behavior, change write-cache buffer flushing, modify Disk registry keys, modify storage settings, modify registry, modify files, modify Windows settings, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `write-cache-buffer-flushing` |
| Customer-facing step title | `Write Cache Buffer Flushing` |
| Stage | `Windows` |
| Visible stage label | `Windows` |
| Production action mapping | customer-facing `ØªØ­Ø³ÙŠÙ† Ø§Ù„ØªØ®Ø²ÙŠÙ†` maps later to internal `Apply` for `write-cache-buffer-flushing` |
| Analyze/Default actions | Do not expose Analyze or Default in normal customer UI now |
| Prototype behavior | Simulation only. Do not change write-cache buffer flushing. Do not modify Disk registry keys. Do not modify storage settings, registry, files, or Windows settings. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Write Cache Buffer Flushing` |
| Subtitle | `ØªØ­Ø³ÙŠÙ† Ø·Ø±ÙŠÙ‚Ø© ØªØ¹Ø§Ù…Ù„ ÙˆØ­Ø¯Ø§Øª Ø§Ù„ØªØ®Ø²ÙŠÙ† Ù…Ø¹ Ø§Ù„Ù‚Ø±Ø§Ø¡Ø© ÙˆØ§Ù„ÙƒØªØ§Ø¨Ø©.` |
| Primary action button | `ØªØ­Ø³ÙŠÙ† Ø§Ù„ØªØ®Ø²ÙŠÙ†` |
| Information card title | `ØªØ­Ø³ÙŠÙ† Ø£Ø¯Ø§Ø¡ Ø§Ù„ØªØ®Ø²ÙŠÙ†` |
| Information card bullet 1 | `Ø¶Ø¨Ø· Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª ØªØ³Ø§Ø¹Ø¯ Ø¹Ù„Ù‰ ØªØ­Ø³ÙŠÙ† Ø£Ø¯Ø§Ø¡ ÙˆØ­Ø¯Ø§Øª Ø§Ù„ØªØ®Ø²ÙŠÙ†.` |
| Information card bullet 2 | `ÙŠØ³Ø§Ø¹Ø¯ Ø°Ù„Ùƒ Ø¹Ù„Ù‰ ØªØ­Ø³ÙŠÙ† ØªØ¬Ø±Ø¨Ø© Ø§Ù„Ù‚Ø±Ø§Ø¡Ø© ÙˆØ§Ù„ÙƒØªØ§Ø¨Ø© Ø£Ø«Ù†Ø§Ø¡ Ø§Ù„Ø§Ø³ØªØ®Ø¯Ø§Ù….` |
| Information card bullet 3 | `ÙŠØªÙ… ØªØ·Ø¨ÙŠÙ‚ Ø§Ù„Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ù…Ù†Ø§Ø³Ø¨Ø© ØªÙ„Ù‚Ø§Ø¦ÙŠÙ‹Ø§ Ø£Ø«Ù†Ø§Ø¡ Ù‡Ø°Ù‡ Ø§Ù„Ø®Ø·ÙˆØ©.` |
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

Do not show Disk registry keys, storage internals, technical risk text, Analyze or Default details, logs, commands, diagnostics, validation results, command output, internal modules, Registry names, Services names, Tasks names, AppX package names, TrustedInstaller details, file paths, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not change write-cache buffer flushing, modify Disk registry keys, modify storage settings, registry, files, Windows settings, host configuration, or run Apply, Open, Default, Restore, or Analyze.

## Windows UI Layout Contract

Preserve the global Windows-stage AXIS layout: `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, no PNG/SVG/WPF vector placeholders, RTL with physical right-edge anchoring, Windows active, prior Check/Refresh/Setup/Installers/Graphics stages completed green, active Windows full white line, no partial progress line, support card separate from runtime status, runtime status near the primary action button, Next disabled until completion then blue, no auto-advance, Previous returns to the previous step, enabled buttons use hand cursor, disabled buttons do not hover, press, or use hand cursor, hover is crisp and readable with no grow/scale/blur, and pressed state is a subtle pressed-in effect.

## BiDi And Layout Notes

Title is English-only and should render LTR while remaining physically right-anchored.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, storage setting mutation, Disk registry mutation, Registry mutation, host mutation, staging, committing, or pushing.

