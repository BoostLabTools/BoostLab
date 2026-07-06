# AXIS Copilot Step Blueprint

Date: 2026-07-06
Scope: owner-approved Windows Part A customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `copilot` Windows-stage step.

This phase is documentation-only. It does not implement UI behavior, disable Copilot, remove AppX packages, write policies, modify security settings, registry, files, Windows settings, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `copilot` |
| Customer-facing step title | `Copilot` |
| Stage | `Windows` |
| Visible stage label | `Windows` |
| Production action mapping | customer-facing `ØªØ¹Ø·ÙŠÙ„ Copilot` maps later to internal `Apply` for `copilot` |
| Internal branch/option mapping | `Off` |
| Default action | Do not expose Default/restore in normal customer UI now. |
| Prototype behavior | Simulation only. Do not disable Copilot. Do not remove AppX packages. Do not write policies. Do not modify security settings, registry, files, or Windows settings. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Copilot` |
| Subtitle | `ØªØ¹Ø·ÙŠÙ„ Copilot ÙˆØªÙ‚Ù„ÙŠÙ„ Ø§Ù„Ù†Ø´Ø§Ø· ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠ.` |
| Primary action button | `ØªØ¹Ø·ÙŠÙ„ Copilot` |
| Information card title | `ØªØ¹Ø·ÙŠÙ„ Copilot` |
| Information card bullet 1 | `ØªØ¹Ø·ÙŠÙ„ Copilot Ø¯Ø§Ø®Ù„ Windows.` |
| Information card bullet 2 | `ÙŠØ³Ø§Ø¹Ø¯ Ø°Ù„Ùƒ Ø¹Ù„Ù‰ ØªÙ‚Ù„ÙŠÙ„ Ø§Ù„Ø¹Ù†Ø§ØµØ± ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠØ© ÙÙŠ Ø§Ù„Ù†Ø¸Ø§Ù….` |
| Information card bullet 3 | `ØªØ³Ø§Ù‡Ù… Ù‡Ø°Ù‡ Ø§Ù„Ø®Ø·ÙˆØ© ÙÙŠ ØªØ­Ø³ÙŠÙ† ØªØ¬Ø±Ø¨Ø© Ø§Ù„Ø§Ø³ØªØ®Ø¯Ø§Ù… ÙˆØ§Ø³ØªÙ‡Ù„Ø§Ùƒ Ø§Ù„Ù…ÙˆØ§Ø±Ø¯.` |
| Requirements card | Not shown |
| Confirmation overlay | Not shown |
| Running state | `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°` |
| Completed state | `Ù…ÙƒØªÙ…Ù„` |

## Runtime Status And Completion

During simulated action, show `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°`.

After simulated completion, show `Ù…ÙƒØªÙ…Ù„`.

After completion, show no additional customer-facing text. Only enable the Next button.

## Customer-Facing Restrictions

Do not show AppX package names.

Do not show policy names.

Do not show security internals.

Do not show commands, diagnostics, logs, validation results, command output, internal modules, Registry names, Services names, Tasks names, TrustedInstaller details, file paths, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not disable Copilot, remove AppX packages, write policies, modify security settings, registry, files, Windows settings, host configuration, or run Apply, Open, Default, Restore, or Analyze.

## Windows UI Layout Contract

Preserve the global Windows-stage AXIS layout: `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, RTL with physical right-edge anchoring, Windows active, prior stages completed green, active Windows full white line, support card separate, runtime status near the primary action button, Next disabled until completion then blue, no auto-advance.

## BiDi And Layout Notes

Title is English-only and should render LTR while remaining physically right-anchored.

`Copilot` and `Windows` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, AppX mutation, policy mutation, Registry mutation, security mutation, host mutation, staging, committing, or pushing.
