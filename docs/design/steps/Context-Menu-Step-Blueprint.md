# AXIS Context Menu Step Blueprint

Date: 2026-07-06
Scope: owner-approved Windows Part A customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `context-menu` Windows-stage step.

This phase is documentation-only. It does not implement UI behavior, modify context menu, shell handlers, registry, files, Windows shell settings, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `context-menu` |
| Customer-facing step title | `Context Menu` |
| Stage | `Windows` |
| Visible stage label | `Windows` |
| Production action mapping | customer-facing `Tweaks Context Menu` maps later to internal `Apply` for `context-menu` |
| Internal branch/option mapping | `Clean (Recommended)` |
| Default action | Do not expose Default/restore in normal customer UI now. |
| Prototype behavior | Simulation only. Do not modify context menu, shell handlers, registry, files, or Windows shell settings. |

Important: do not show `Clean (Recommended)` as an internal branch label in the normal customer UI.

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Context Menu` |
| Subtitle | `ØªØ¹Ø¯ÙŠÙ„Ø§Øª Ø¹Ù„Ù‰ Ù‚Ø§Ø¦Ù…Ø© Ø§Ù„Ø²Ø± Ø§Ù„Ø£ÙŠÙ…Ù†.` |
| Primary action button | `Tweaks Context Menu` |
| Information card title | `ØªÙ†Ø¸ÙŠÙ Ù‚Ø§Ø¦Ù…Ø© Ø§Ù„Ø²Ø± Ø§Ù„Ø£ÙŠÙ…Ù†` |
| Information card bullet 1 | `ØªØ·Ø¨ÙŠÙ‚ ØªØ¹Ø¯ÙŠÙ„Ø§Øª Ù…Ø®ØµØµØ© Ø¹Ù„Ù‰ Ù‚Ø§Ø¦Ù…Ø© Ø§Ù„Ø²Ø± Ø§Ù„Ø£ÙŠÙ…Ù†.` |
| Information card bullet 2 | `ØªÙ‚Ù„ÙŠÙ„ Ø§Ù„Ø¹Ù†Ø§ØµØ± ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠØ© Ø¯Ø§Ø®Ù„ Ø§Ù„Ù‚Ø§Ø¦Ù…Ø©.` |
| Information card bullet 3 | `ÙŠØ³Ø§Ø¹Ø¯ Ø°Ù„Ùƒ Ø¹Ù„Ù‰ Ø¬Ø¹Ù„ Ø§Ù„Ù‚Ø§Ø¦Ù…Ø© Ø£Ø¨Ø³Ø· ÙˆØ£Ø³Ø±Ø¹ ÙÙŠ Ø§Ù„Ø§Ø³ØªØ®Ø¯Ø§Ù….` |
| Requirements card | Not shown |
| Confirmation overlay | Not shown |
| Running state | `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°` |
| Completed state | `Ù…ÙƒØªÙ…Ù„` |

## Runtime Status And Completion

During simulated action, show `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°`.

After simulated completion, show `Ù…ÙƒØªÙ…Ù„`.

After completion, show no additional customer-facing text. Only enable the Next button.

## Customer-Facing Restrictions

Do not show Registry names.

Do not show shell handler names.

Do not show extension names.

Do not show commands, diagnostics, logs, validation results, command output, internal modules, Services names, Tasks names, AppX package names, TrustedInstaller details, file paths, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not modify context menu, shell handlers, registry, files, Windows shell settings, host configuration, or run Apply, Open, Default, Restore, or Analyze.

## Windows UI Layout Contract

The future Windows prototype should preserve `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, no PNG/SVG/WPF vector placeholders, Arabic-first copy except owner-approved English titles/buttons/tokens, RTL layout with physical right-edge anchoring, and the stage strip logical order Check, Refresh, Setup, Installers, Graphics, Windows, Advanced.

Windows is active for this step. Previous Check, Refresh, Setup, Installers, and Graphics stages are completed green. Active Windows uses a full white line. There is no partial or incomplete progress line.

Support card remains separate from runtime status and uses the unchanged global support copy. Runtime status stays near the primary action button. Next is disabled until action simulation completes, then enabled and blue.

## BiDi And Layout Notes

Title and primary action are English-only and should render LTR while remaining physically right-anchored.

`Context Menu` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, shell mutation, Registry mutation, host mutation, staging, committing, or pushing.
