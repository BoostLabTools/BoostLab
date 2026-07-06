# AXIS Start Menu Layout Step Blueprint

Date: 2026-07-06
Scope: owner-approved Windows Part A customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `start-menu-layout` Windows-stage step.

This phase is documentation-only. It does not implement UI behavior, modify Start layout, files, registry, shell state, Windows layout settings, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `start-menu-layout` |
| Customer-facing step title | `Start Menu Layout` |
| Stage | `Windows` |
| Visible stage label | `Windows` |
| Production action mapping | customer-facing `Tweaks Start Menu Layout` maps later to internal `Apply` for `start-menu-layout` |
| Internal branch/option mapping | `25H2 (Recommended)` |
| Default action | Do not expose Default/restore in normal customer UI now. |
| Prototype behavior | Simulation only. Do not modify Start layout, files, registry, shell state, or Windows layout settings. |

Important: do not show `25H2` or `24H2` in the normal customer UI.

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Start Menu Layout` |
| Subtitle | `Ø¶Ø¨Ø· ØªØ®Ø·ÙŠØ· Ù‚Ø§Ø¦Ù…Ø© Ø§Ø¨Ø¯Ø£.` |
| Primary action button | `Tweaks Start Menu Layout` |
| Information card title | `ØªØ±ØªÙŠØ¨ Ù‚Ø§Ø¦Ù…Ø© Ø§Ø¨Ø¯Ø£` |
| Information card bullet 1 | `ØªØ·Ø¨ÙŠÙ‚ ØªØ®Ø·ÙŠØ· Ù…Ø®ØµØµ Ù„Ù‚Ø§Ø¦Ù…Ø© Ø§Ø¨Ø¯Ø£.` |
| Information card bullet 2 | `ÙŠØ³Ø§Ø¹Ø¯ Ø°Ù„Ùƒ Ø¹Ù„Ù‰ Ø¬Ø¹Ù„ Ø§Ù„Ù‚Ø§Ø¦Ù…Ø© Ø£Ù†Ø¸Ù ÙˆØ£Ø³Ù‡Ù„ ÙÙŠ Ø§Ù„Ø§Ø³ØªØ®Ø¯Ø§Ù….` |
| Information card bullet 3 | `ÙŠØªÙ… ØªØ·Ø¨ÙŠÙ‚ Ø§Ù„ØªØ®Ø·ÙŠØ· Ø§Ù„Ù…Ù†Ø§Ø³Ø¨ ØªÙ„Ù‚Ø§Ø¦ÙŠÙ‹Ø§ Ø£Ø«Ù†Ø§Ø¡ Ù‡Ø°Ù‡ Ø§Ù„Ø®Ø·ÙˆØ©.` |
| Requirements card | Not shown |
| Confirmation overlay | Not shown |
| Running state | `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°` |
| Completed state | `Ù…ÙƒØªÙ…Ù„` |

## Runtime Status And Completion

During simulated action, show `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°`.

After simulated completion, show `Ù…ÙƒØªÙ…Ù„`.

After completion, show no additional customer-facing text. Only enable the Next button.

## Customer-Facing Restrictions

Do not show `25H2` or `24H2` in the normal customer UI.

Do not show layout file names.

Do not show Registry details.

Do not show file paths, commands, diagnostics, logs, validation results, command output, internal modules, shell handler names, Services names, Tasks names, AppX package names, TrustedInstaller details, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not modify Start layout, files, registry, shell state, Windows layout settings, Windows shell, system files, host configuration, or run Apply, Open, Default, Restore, or Analyze.

## Windows UI Layout Contract

The future Windows prototype should preserve `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, no PNG/SVG/WPF vector placeholders, Arabic-first copy except owner-approved English titles/buttons/tokens, RTL layout with physical right-edge anchoring, and the stage strip logical order Check, Refresh, Setup, Installers, Graphics, Windows, Advanced.

Windows is active for this step. Previous Check, Refresh, Setup, Installers, and Graphics stages are completed green. Active Windows uses a full white line. There is no partial or incomplete progress line.

Support card remains separate from runtime status and uses the unchanged global support copy.

Runtime status stays near the primary action button. Next is disabled until action simulation completes, then enabled and blue. There is no auto-advance after completion. Previous returns to the previous step.

Enabled buttons use hand cursor. Disabled buttons do not hover, do not press, and do not use hand cursor. Hover must be crisp and readable, with no grow, scale, or blur. Pressed state should be a subtle pressed-in effect.

## BiDi And Layout Notes

Title and primary action are English-only and should render LTR while remaining physically right-anchored.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, layout mutation, Registry mutation, host mutation, staging, committing, or pushing.
