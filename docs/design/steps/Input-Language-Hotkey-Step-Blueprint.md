# AXIS Input Language Hotkey Step Blueprint

Date: 2026-07-06
Scope: owner-approved Windows Part B customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `input-language-hotkey` Windows-stage step.

This phase is documentation-only. It does not implement UI behavior, change input language hotkeys, modify HKCU, modify keyboard layout settings, modify registry, modify files, modify Windows settings, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `input-language-hotkey` |
| Customer-facing step title | `Input Language Hotkey` |
| Stage | `Windows` |
| Visible stage label | `Windows` |
| Production action mapping | customer-facing `Ø¶Ø¨Ø· Ø§Ø®ØªØµØ§Ø± Ø§Ù„Ù„ØºØ©` maps later to internal `Apply` for `input-language-hotkey` |
| Prototype behavior | Simulation only. Do not change input language hotkeys. Do not modify HKCU, keyboard layout settings, registry, files, or Windows settings. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Input Language Hotkey` |
| Subtitle | `Ø¶Ø¨Ø· Ø§Ø®ØªØµØ§Ø± ØªØ¨Ø¯ÙŠÙ„ Ù„ØºØ© Ø§Ù„Ø¥Ø¯Ø®Ø§Ù„ ØªÙ„Ù‚Ø§Ø¦ÙŠÙ‹Ø§.` |
| Primary action button | `Ø¶Ø¨Ø· Ø§Ø®ØªØµØ§Ø± Ø§Ù„Ù„ØºØ©` |
| Information card title | `Ø§Ø®ØªØµØ§Ø± ØªØ¨Ø¯ÙŠÙ„ Ø§Ù„Ù„ØºØ©` |
| Information card bullet 1 | `Ø¶Ø¨Ø· Ø§Ø®ØªØµØ§Ø± ØªØ¨Ø¯ÙŠÙ„ Ù„ØºØ© Ø§Ù„Ø¥Ø¯Ø®Ø§Ù„ Ø¯Ø§Ø®Ù„ Windows.` |
| Information card bullet 2 | `ÙŠØªÙ… ØªØ¹ÙŠÙŠÙ† Ø§Ù„Ø§Ø®ØªØµØ§Ø± Ø¥Ù„Ù‰ Left Alt + Shift.` |
| Information card bullet 3 | `ÙŠØ³Ø§Ø¹Ø¯ Ø°Ù„Ùƒ Ø¹Ù„Ù‰ ØªØ¨Ø¯ÙŠÙ„ Ø§Ù„Ù„ØºØ© Ø¨Ø³Ø±Ø¹Ø© Ø£Ø«Ù†Ø§Ø¡ Ø§Ù„ÙƒØªØ§Ø¨Ø©.` |
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

Do not show HKCU, keyboard layout registry names, technical names beyond the approved customer text, logs, commands, diagnostics, validation results, command output, internal modules, Registry names, Services names, Tasks names, AppX package names, TrustedInstaller details, file paths, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not change input language hotkeys, modify HKCU, keyboard layout settings, registry, files, Windows settings, host configuration, or run Apply, Open, Default, Restore, or Analyze.

## Windows UI Layout Contract

Preserve the global Windows-stage AXIS layout: `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, no PNG/SVG/WPF vector placeholders, RTL with physical right-edge anchoring, Windows active, prior Check/Refresh/Setup/Installers/Graphics stages completed green, active Windows full white line, no partial progress line, support card separate from runtime status, runtime status near the primary action button, Next disabled until completion then blue, no auto-advance, Previous returns to the previous step, enabled buttons use hand cursor, disabled buttons do not hover, press, or use hand cursor, hover is crisp and readable with no grow/scale/blur, and pressed state is a subtle pressed-in effect.

## BiDi And Layout Notes

Title is English-only and should render LTR while remaining physically right-anchored.

`Windows` and `Left Alt + Shift` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, input-language mutation, Registry mutation, Windows settings mutation, host mutation, staging, committing, or pushing.

