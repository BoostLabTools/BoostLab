# AXIS Control Panel Settings Step Blueprint

Date: 2026-07-06
Scope: owner-approved Windows Part B customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `control-panel-settings` Windows-stage step.

This phase is documentation-only. It does not implement UI behavior, change Control Panel settings, change Services, change security settings, use TrustedInstaller, delete files, modify registry, modify files, modify Windows settings, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `control-panel-settings` |
| Customer-facing step title | `Control Panel Settings` |
| Stage | `Windows` |
| Visible stage label | `Windows` |
| Production action mapping | customer-facing `Ø¶Ø¨Ø· Control Panel` maps later to internal `Apply` for `control-panel-settings` |
| Default action | Do not expose Default/restore in normal customer UI now |
| Prototype behavior | Simulation only. Do not change Control Panel settings. Do not change Services. Do not change security settings. Do not use TrustedInstaller. Do not delete files. Do not modify registry, files, Windows settings, or system configuration. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Control Panel Settings` |
| Subtitle | `Ø¶Ø¨Ø· Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Control Panel Ù„ØªØ­Ø³ÙŠÙ† ØªØ¬Ø±Ø¨Ø© Windows.` |
| Primary action button | `Ø¶Ø¨Ø· Control Panel` |
| Information card title | `ØªØ­Ø³ÙŠÙ† Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ù†Ø¸Ø§Ù…` |
| Information card bullet 1 | `ØªØ·Ø¨ÙŠÙ‚ Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ù…Ù‡Ù…Ø© Ø¯Ø§Ø®Ù„ Control Panel Ù„ØªØ­Ø³ÙŠÙ† ØªØ¬Ø±Ø¨Ø© Windows.` |
| Information card bullet 2 | `ØªÙ‚Ù„ÙŠÙ„ Ø§Ù„Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠØ© ÙˆØ¬Ø¹Ù„ Ø§Ù„Ù†Ø¸Ø§Ù… Ø£ÙƒØ«Ø± Ø¬Ø§Ù‡Ø²ÙŠØ© Ù„Ù„Ø§Ø³ØªØ®Ø¯Ø§Ù….` |
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

Do not show Services details, security internals, TrustedInstaller details, delete details, Registry names, logs, commands, diagnostics, validation results, command output, internal modules, Tasks names, AppX package names, file paths, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not change Control Panel settings, change Services, change security settings, use TrustedInstaller, delete files, modify registry, files, Windows settings, system configuration, host configuration, or run Apply, Open, Default, Restore, or Analyze.

## Windows UI Layout Contract

Preserve the global Windows-stage AXIS layout: `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, no PNG/SVG/WPF vector placeholders, RTL with physical right-edge anchoring, Windows active, prior Check/Refresh/Setup/Installers/Graphics stages completed green, active Windows full white line, no partial progress line, support card separate from runtime status, runtime status near the primary action button, Next disabled until completion then blue, no auto-advance, Previous returns to the previous step, enabled buttons use hand cursor, disabled buttons do not hover, press, or use hand cursor, hover is crisp and readable with no grow/scale/blur, and pressed state is a subtle pressed-in effect.

## BiDi And Layout Notes

Title is English-only and should render LTR while remaining physically right-anchored.

`Control Panel` and `Windows` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, Control Panel mutation, Services mutation, security mutation, file deletion, Registry mutation, host mutation, staging, committing, or pushing.

