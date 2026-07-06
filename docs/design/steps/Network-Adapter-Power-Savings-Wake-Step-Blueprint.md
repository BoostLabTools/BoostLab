# AXIS Network Adapter Power Savings Wake Step Blueprint

Date: 2026-07-06
Scope: owner-approved Windows Part B customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `network-adapter-power-savings-wake` Windows-stage step.

This phase is documentation-only. It does not implement UI behavior, change network adapter power settings, modify adapter registry values, modify wake settings, change network driver/device configuration, modify registry, modify files, modify Windows settings, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `network-adapter-power-savings-wake` |
| Customer-facing step title | `Network Adapter Power Savings Wake` |
| Stage | `Windows` |
| Visible stage label | `Windows` |
| Production action mapping | customer-facing `ØªØ¹Ø·ÙŠÙ„ ØªÙˆÙÙŠØ± Ø§Ù„Ø·Ø§Ù‚Ø© Ù„Ù„Ø´Ø¨ÙƒØ©` maps later to internal `Apply` for `network-adapter-power-savings-wake` |
| Default action | Do not expose Default/restore in normal customer UI now |
| Prototype behavior | Simulation only. Do not change network adapter power settings. Do not modify adapter registry values. Do not modify wake settings. Do not change network driver/device configuration, registry, files, or Windows settings. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Network Adapter Power Savings Wake` |
| Subtitle | `ØªØ¹Ø·ÙŠÙ„ ØªÙˆÙÙŠØ± Ø§Ù„Ø·Ø§Ù‚Ø© Ù„Ù…Ø­ÙˆÙ„ Ø§Ù„Ø´Ø¨ÙƒØ© Ù„ØªØ­Ø³ÙŠÙ† Ø§Ø³ØªÙ‚Ø±Ø§Ø± Ø§Ù„Ø§ØªØµØ§Ù„.` |
| Primary action button | `ØªØ¹Ø·ÙŠÙ„ ØªÙˆÙÙŠØ± Ø§Ù„Ø·Ø§Ù‚Ø© Ù„Ù„Ø´Ø¨ÙƒØ©` |
| Information card title | `ØªØ­Ø³ÙŠÙ† Ø§Ø³ØªÙ‚Ø±Ø§Ø± Ø§Ù„Ø´Ø¨ÙƒØ©` |
| Information card bullet 1 | `ØªØ¹Ø·ÙŠÙ„ Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª ØªÙˆÙÙŠØ± Ø§Ù„Ø·Ø§Ù‚Ø© ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠØ© Ù„Ù…Ø­ÙˆÙ„ Ø§Ù„Ø´Ø¨ÙƒØ©.` |
| Information card bullet 2 | `ÙŠØ³Ø§Ø¹Ø¯ Ø°Ù„Ùƒ Ø¹Ù„Ù‰ ØªØ­Ø³ÙŠÙ† Ø§Ø³ØªÙ‚Ø±Ø§Ø± Ø§Ù„Ø§ØªØµØ§Ù„ ÙˆØªÙ‚Ù„ÙŠÙ„ Ø§Ù„Ø§Ù†Ù‚Ø·Ø§Ø¹Ø§Øª.` |
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

Do not show adapter registry values, driver IDs, NIC technical details, logs, commands, diagnostics, validation results, command output, internal modules, Registry names, Services names, Tasks names, AppX package names, TrustedInstaller details, file paths, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not change network adapter power settings, modify adapter registry values, modify wake settings, change network driver/device configuration, modify registry, files, Windows settings, host configuration, or run Apply, Open, Default, Restore, or Analyze.

## Windows UI Layout Contract

Preserve the global Windows-stage AXIS layout: `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, no PNG/SVG/WPF vector placeholders, RTL with physical right-edge anchoring, Windows active, prior Check/Refresh/Setup/Installers/Graphics stages completed green, active Windows full white line, no partial progress line, support card separate from runtime status, runtime status near the primary action button, Next disabled until completion then blue, no auto-advance, Previous returns to the previous step, enabled buttons use hand cursor, disabled buttons do not hover, press, or use hand cursor, hover is crisp and readable with no grow/scale/blur, and pressed state is a subtle pressed-in effect.

## BiDi And Layout Notes

Title is English-only and should render LTR while remaining physically right-anchored.

`Network Adapter` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, network adapter mutation, network driver/device mutation, Registry mutation, host mutation, staging, committing, or pushing.

