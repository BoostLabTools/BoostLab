# AXIS Theme Black Step Blueprint

Date: 2026-07-06
Scope: owner-approved Windows Part A customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `theme-black` Windows-stage step.

This phase is documentation-only. It does not implement UI behavior, change theme settings, registry, files, Windows personalization settings, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `theme-black` |
| Customer-facing step title | `Theme Black` |
| Stage | `Windows` |
| Visible stage label | `Windows` |
| Production action mapping | customer-facing `ØªØ·Ø¨ÙŠÙ‚ Ø§Ù„Ø«ÙŠÙ… Ø§Ù„Ø¯Ø§ÙƒÙ†` maps later to internal `Apply` for `theme-black` |
| Internal branch/option mapping | `Black` |
| Default action | Do not expose Default/restore in normal customer UI now. |
| Prototype behavior | Simulation only. Do not change theme settings, registry, files, or Windows personalization settings. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Theme Black` |
| Subtitle | `ØªØ·Ø¨ÙŠÙ‚ Ø§Ù„Ø«ÙŠÙ… Ø§Ù„Ø¯Ø§ÙƒÙ†.` |
| Primary action button | `ØªØ·Ø¨ÙŠÙ‚ Ø§Ù„Ø«ÙŠÙ… Ø§Ù„Ø¯Ø§ÙƒÙ†` |
| Information card title | `Ø§Ù„Ø«ÙŠÙ… Ø§Ù„Ø¯Ø§ÙƒÙ†` |
| Information card bullet 1 | `ØªØ·Ø¨ÙŠÙ‚ Ø§Ù„Ù…Ø¸Ù‡Ø± Ø§Ù„Ø¯Ø§ÙƒÙ† Ø¹Ù„Ù‰ Windows.` |
| Information card bullet 2 | `ÙŠØªÙ… Ø¶Ø¨Ø· Ø§Ù„Ù…Ø¸Ù‡Ø± ØªÙ„Ù‚Ø§Ø¦ÙŠÙ‹Ø§ Ø£Ø«Ù†Ø§Ø¡ Ù‡Ø°Ù‡ Ø§Ù„Ø®Ø·ÙˆØ©.` |
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

Do not show theme internals.

Do not show commands, diagnostics, logs, validation results, command output, internal modules, Services names, Tasks names, AppX package names, TrustedInstaller details, file paths, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not change theme settings, registry, files, Windows personalization settings, host configuration, or run Apply, Open, Default, Restore, or Analyze.

## Windows UI Layout Contract

Preserve the global Windows-stage AXIS layout: `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, RTL with physical right-edge anchoring, Windows active, prior stages completed green, active Windows full white line, support card separate, runtime status near the primary action button, Next disabled until completion then blue, no auto-advance.

## BiDi And Layout Notes

Title is English-only and should render LTR while remaining physically right-anchored.

`Windows` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, theme mutation, Registry mutation, host mutation, staging, committing, or pushing.
