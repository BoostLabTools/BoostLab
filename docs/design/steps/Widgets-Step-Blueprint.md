# AXIS Widgets Step Blueprint

Date: 2026-07-06
Scope: owner-approved Windows Part A customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `widgets` Windows-stage step.

This phase is documentation-only. It does not implement UI behavior, disable Widgets, write policies, stop processes, modify registry, modify Windows settings, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `widgets` |
| Customer-facing step title | `Widgets` |
| Stage | `Windows` |
| Visible stage label | `Windows` |
| Production action mapping | customer-facing `ØªØ¹Ø·ÙŠÙ„ Widgets` maps later to internal `Apply` for `widgets` |
| Internal branch/option mapping | `Off` |
| Default action | Do not expose Default/restore in normal customer UI now. |
| Prototype behavior | Simulation only. Do not disable Widgets. Do not write policies. Do not stop processes. Do not modify registry or Windows settings. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Widgets` |
| Subtitle | `ØªØ¹Ø·ÙŠÙ„ Widgets Ù„ØªÙ‚Ù„ÙŠÙ„ Ø§Ù„Ù†Ø´Ø§Ø· ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠ.` |
| Primary action button | `ØªØ¹Ø·ÙŠÙ„ Widgets` |
| Information card title | `ØªØ¹Ø·ÙŠÙ„ Widgets` |
| Information card bullet 1 | `ØªØ¹Ø·ÙŠÙ„ Widgets Ø¯Ø§Ø®Ù„ Windows.` |
| Information card bullet 2 | `ÙŠØ³Ø§Ø¹Ø¯ Ø°Ù„Ùƒ Ø¹Ù„Ù‰ ØªÙ‚Ù„ÙŠÙ„ Ø§Ù„Ù†Ø´Ø§Ø· ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠ ÙÙŠ Ø§Ù„Ø®Ù„ÙÙŠØ©.` |
| Information card bullet 3 | `ØªØ³Ø§Ù‡Ù… Ù‡Ø°Ù‡ Ø§Ù„Ø®Ø·ÙˆØ© ÙÙŠ ØªØ­Ø³ÙŠÙ† Ø§Ø³ØªÙ‡Ù„Ø§Ùƒ Ø§Ù„Ù…ÙˆØ§Ø±Ø¯ Ø£Ø«Ù†Ø§Ø¡ Ø§Ù„Ø§Ø³ØªØ®Ø¯Ø§Ù….` |
| Requirements card | Not shown |
| Confirmation overlay | Not shown |
| Running state | `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°` |
| Completed state | `Ù…ÙƒØªÙ…Ù„` |

## Runtime Status And Completion

During simulated action, show `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°`.

After simulated completion, show `Ù…ÙƒØªÙ…Ù„`.

After completion, show no additional customer-facing text. Only enable the Next button.

## Customer-Facing Restrictions

Do not show policy names.

Do not show process names.

Do not show Registry paths.

Do not show commands, diagnostics, logs, validation results, command output, internal modules, Services names, Tasks names, AppX package names, TrustedInstaller details, file paths, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not disable Widgets, write policies, stop processes, modify registry, Windows settings, host configuration, or run Apply, Open, Default, Restore, or Analyze.

## Windows UI Layout Contract

Preserve the global Windows-stage AXIS layout: `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, RTL with physical right-edge anchoring, Windows active, prior stages completed green, active Windows full white line, support card separate, runtime status near the primary action button, Next disabled until completion then blue, no auto-advance.

## BiDi And Layout Notes

Title is English-only and should render LTR while remaining physically right-anchored.

`Widgets` and `Windows` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, policy mutation, Registry mutation, process handling, host mutation, staging, committing, or pushing.
