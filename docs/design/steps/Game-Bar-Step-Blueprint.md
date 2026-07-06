# AXIS Game Bar Step Blueprint

Date: 2026-07-06
Scope: owner-approved Windows Part B customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `game-bar` Windows-stage step.

This phase is documentation-only. It does not implement UI behavior, disable Game Bar, repair or remove Xbox/GameInput components, remove AppX packages, modify Services, use TrustedInstaller-owned components, download files, modify registry, modify files, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `game-bar` |
| Customer-facing step title | `Game Bar` |
| Stage | `Windows` |
| Visible stage label | `Windows` |
| Production action mapping | customer-facing `ØªØ¹Ø·ÙŠÙ„ Game Bar` maps later to internal `Apply` for `game-bar` |
| Default action | Do not expose Default/restore in normal customer UI now |
| Prototype behavior | Simulation only. Do not disable Game Bar. Do not repair or remove Xbox/GameInput components. Do not remove AppX packages. Do not modify Services, TrustedInstaller-owned components, downloads, registry, files, or Windows settings. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Game Bar` |
| Subtitle | `ØªØ¹Ø·ÙŠÙ„ Game Bar ÙˆØªÙ‚Ù„ÙŠÙ„ Ù…ÙƒÙˆÙ†Ø§Øª Ø§Ù„Ø£Ù„Ø¹Ø§Ø¨ ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠØ©.` |
| Primary action button | `ØªØ¹Ø·ÙŠÙ„ Game Bar` |
| Information card title | `ØªØ­Ø³ÙŠÙ† ØªØ¬Ø±Ø¨Ø© Ø§Ù„Ø£Ù„Ø¹Ø§Ø¨` |
| Information card bullet 1 | `ØªØ¹Ø·ÙŠÙ„ Game Bar Ù„ØªÙ‚Ù„ÙŠÙ„ Ø§Ù„Ù†Ø´Ø§Ø· ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠ Ø£Ø«Ù†Ø§Ø¡ Ø§Ù„Ø§Ø³ØªØ®Ø¯Ø§Ù….` |
| Information card bullet 2 | `ÙŠØ³Ø§Ø¹Ø¯ Ø°Ù„Ùƒ Ø¹Ù„Ù‰ ØªØ®ÙÙŠÙ Ø§Ø³ØªÙ‡Ù„Ø§Ùƒ Ø§Ù„Ù…ÙˆØ§Ø±Ø¯ ÙÙŠ Ø§Ù„Ø®Ù„ÙÙŠØ©.` |
| Information card bullet 3 | `ØªØ³Ø§Ù‡Ù… Ù‡Ø°Ù‡ Ø§Ù„Ø®Ø·ÙˆØ© ÙÙŠ ØªØ­Ø³ÙŠÙ† ØªØ¬Ø±Ø¨Ø© Ø§Ù„Ø¬Ù‡Ø§Ø² Ø£Ø«Ù†Ø§Ø¡ Ø§Ù„Ù„Ø¹Ø¨ ÙˆØ§Ù„Ø§Ø³ØªØ®Ø¯Ø§Ù… Ø§Ù„ÙŠÙˆÙ…ÙŠ.` |
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

Do not mention Xbox.

Do not mention GameInput.

Do not show AppX package names, Services names, TrustedInstaller details, downloads, logs, commands, diagnostics, validation results, command output, internal modules, Registry names, file paths, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not disable Game Bar, repair or remove Xbox/GameInput components, remove AppX packages, modify Services, use TrustedInstaller-owned components, download files, modify registry, files, Windows settings, host configuration, or run Apply, Open, Default, Restore, or Analyze.

## Windows UI Layout Contract

Preserve the global Windows-stage AXIS layout: `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, no PNG/SVG/WPF vector placeholders, RTL with physical right-edge anchoring, Windows active, prior Check/Refresh/Setup/Installers/Graphics stages completed green, active Windows full white line, no partial progress line, support card separate from runtime status, runtime status near the primary action button, Next disabled until completion then blue, no auto-advance, Previous returns to the previous step, enabled buttons use hand cursor, disabled buttons do not hover, press, or use hand cursor, hover is crisp and readable with no grow/scale/blur, and pressed state is a subtle pressed-in effect.

## BiDi And Layout Notes

Title is English-only and should render LTR while remaining physically right-anchored.

`Game Bar` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, Windows Settings launch, settings mutation, Registry mutation, Services mutation, AppX mutation, host mutation, staging, committing, or pushing.

