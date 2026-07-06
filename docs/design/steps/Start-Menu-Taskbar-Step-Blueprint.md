# AXIS Start Menu Taskbar Step Blueprint

Date: 2026-07-06
Scope: owner-approved Windows Part A customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `start-menu-taskbar` Windows-stage step.

This phase is documentation-only. It does not implement UI behavior, modify Start Menu, modify Taskbar, modify Quick Launch, modify Explorer, modify files, modify registry, change shell state, restart Explorer, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `start-menu-taskbar` |
| Customer-facing step title | `Start Menu Taskbar` |
| Stage | `Windows` |
| Visible stage label | `Windows` |
| Production action mapping | customer-facing `Tweaks Start Menu Taskbar` maps later to internal `Apply` for `start-menu-taskbar` |
| Default action | Do not expose Default/restore in normal customer UI now. |
| Prototype behavior | Simulation only. Do not modify Start Menu, Taskbar, Quick Launch, Explorer, files, registry, or shell state. Do not restart Explorer. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Start Menu Taskbar` |
| Subtitle | `ØªØ¹Ø¯ÙŠÙ„Ø§Øª ÙˆØªÙ†Ø¸ÙŠÙ Ø¹Ù„Ù‰ Ø´Ø±ÙŠØ· Ø§Ù„Ù…Ù‡Ø§Ù… ÙˆÙ‚Ø§Ø¦Ù…Ø© Ø§Ø¨Ø¯Ø£.` |
| Primary action button | `Tweaks Start Menu Taskbar` |
| Information card title | `ØªØ­Ø³ÙŠÙ† Ø´Ø±ÙŠØ· Ø§Ù„Ù…Ù‡Ø§Ù… ÙˆÙ‚Ø§Ø¦Ù…Ø© Ø§Ø¨Ø¯Ø£` |
| Information card bullet 1 | `ØªØ·Ø¨ÙŠÙ‚ ØªØ¹Ø¯ÙŠÙ„Ø§Øª Ù…Ø®ØµØµØ© Ø¹Ù„Ù‰ Ø´Ø±ÙŠØ· Ø§Ù„Ù…Ù‡Ø§Ù… ÙˆÙ‚Ø§Ø¦Ù…Ø© Ø§Ø¨Ø¯Ø£.` |
| Information card bullet 2 | `ØªÙ†Ø¸ÙŠÙ Ø§Ù„Ø¹Ù†Ø§ØµØ± ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠØ© Ù„ØªØ­Ø³ÙŠÙ† Ø´ÙƒÙ„ ÙˆØªØ¬Ø±Ø¨Ø© Ø§Ù„Ø§Ø³ØªØ®Ø¯Ø§Ù….` |
| Information card bullet 3 | `ÙŠØªÙ… ØªØ·Ø¨ÙŠÙ‚ Ø§Ù„Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø§Ù„Ù…Ù†Ø§Ø³Ø¨Ø© ØªÙ„Ù‚Ø§Ø¦ÙŠÙ‹Ø§ Ø£Ø«Ù†Ø§Ø¡ Ù‡Ø°Ù‡ Ø§Ù„Ø®Ø·ÙˆØ©.` |
| Requirements card | Not shown |
| Confirmation overlay | Not shown |
| Running state | `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°` |
| Completed state | `Ù…ÙƒØªÙ…Ù„` |

## Runtime Status And Completion

During simulated action, show `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°`.

After simulated completion, show `Ù…ÙƒØªÙ…Ù„`.

After completion, show no additional customer-facing text. Only enable the Next button.

## Customer-Facing Restrictions

Do not mention Explorer refresh.

Do not show Explorer details.

Do not show layout file details.

Do not show Quick Launch internals.

Do not show Registry, file paths, commands, diagnostics, logs, validation results, command output, internal modules, shell handler names, Services names, Tasks names, AppX package names, TrustedInstaller details, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not modify Start Menu, Taskbar, Quick Launch, Explorer, files, registry, shell state, Windows shell, wallpapers, account pictures, system files, Windows settings, host configuration, or run Apply, Open, Default, Restore, or Analyze.

## Windows UI Layout Contract

The future Windows prototype should preserve `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, no PNG/SVG/WPF vector placeholders, Arabic-first copy except owner-approved English titles/buttons/tokens, RTL layout with physical right-edge anchoring, and the stage strip logical order Check, Refresh, Setup, Installers, Graphics, Windows, Advanced.

Windows is active for this step. Previous Check, Refresh, Setup, Installers, and Graphics stages are completed green. Active Windows uses a full white line. There is no partial or incomplete progress line.

Support card remains separate from runtime status and uses the unchanged global support copy:

| Surface | Owner-approved value |
| --- | --- |
| Support card title | `Ù…Ø³Ø§Ø¹Ø¯Ø©` |
| Support card body | `ØªØ­ØªØ§Ø¬ Ù…Ø³Ø§Ø¹Ø¯Ø©ØŸ ÙŠÙ…ÙƒÙ†Ùƒ Ø§Ù„ØªÙˆØ§ØµÙ„ Ù…Ø¹ Ø£Ø®ØµØ§Ø¦ÙŠ Ø§Ù„Ø¯Ø¹Ù… Ø¹Ø¨Ø± Ø®Ø§Ø¯Ù… Discord Ø§Ù„Ø®Ø§Øµ Ø¨Ø§Ù„Ù…ØªØ¬Ø±.` |

Runtime status stays near the primary action button. Next is disabled until action simulation completes, then enabled and blue. There is no auto-advance after completion. Previous returns to the previous step.

Enabled buttons use hand cursor. Disabled buttons do not hover, do not press, and do not use hand cursor. Hover must be crisp and readable, with no grow, scale, or blur. Pressed state should be a subtle pressed-in effect.

## BiDi And Layout Notes

Title and primary action are English-only and should render LTR while remaining physically right-anchored.

`Start Menu` and `Taskbar` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, Explorer restart, shell mutation, Registry mutation, host mutation, staging, committing, or pushing.
