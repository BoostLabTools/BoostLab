# AXIS Cleanup Step Blueprint

Date: 2026-07-06
Scope: owner-approved Windows Part B customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `cleanup` Windows-stage step.

This phase is documentation-only. It does not implement UI behavior, delete files, clean temporary files, run cleanup actions, modify file system, modify registry, modify Windows settings, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `cleanup` |
| Customer-facing step title | `Cleanup` |
| Stage | `Windows` |
| Visible stage label | `Windows` |
| Production action mapping | customer-facing `ØªÙ†Ø¸ÙŠÙ Ø§Ù„Ø¬Ù‡Ø§Ø²` maps later to internal `Apply` for `cleanup` |
| Prototype behavior | Simulation only. Do not delete files. Do not clean temporary files. Do not run cleanup actions. Do not modify file system, registry, Windows settings, or host configuration. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Cleanup` |
| Subtitle | `ØªÙ†Ø¸ÙŠÙ Ø§Ù„Ù…Ù„ÙØ§Øª Ø§Ù„Ù…Ø¤Ù‚ØªØ© ÙˆØ§Ù„Ù…Ø®Ù„ÙØ§Øª ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠØ©.` |
| Primary action button | `ØªÙ†Ø¸ÙŠÙ Ø§Ù„Ø¬Ù‡Ø§Ø²` |
| Information card title | `ØªÙ†Ø¸ÙŠÙ Ø§Ù„Ù†Ø¸Ø§Ù…` |
| Information card bullet 1 | `ØªÙ†Ø¸ÙŠÙ Ø§Ù„Ù…Ù„ÙØ§Øª Ø§Ù„Ù…Ø¤Ù‚ØªØ© ÙˆØ§Ù„Ù…Ø®Ù„ÙØ§Øª ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠØ©.` |
| Information card bullet 2 | `ÙŠØ³Ø§Ø¹Ø¯ Ø°Ù„Ùƒ Ø¹Ù„Ù‰ ØªØ®ÙÙŠÙ Ø§Ù„Ù†Ø¸Ø§Ù… ÙˆØ¬Ø¹Ù„ Ø§Ù„ØªØ¬Ø±Ø¨Ø© Ø£ÙƒØ«Ø± Ø³Ù„Ø§Ø³Ø©.` |
| Information card bullet 3 | `ÙŠØªÙ… ØªÙ†ÙÙŠØ° Ø§Ù„ØªÙ†Ø¸ÙŠÙ ØªÙ„Ù‚Ø§Ø¦ÙŠÙ‹Ø§ Ø£Ø«Ù†Ø§Ø¡ Ù‡Ø°Ù‡ Ø§Ù„Ø®Ø·ÙˆØ©.` |
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

Do not show file paths, deletion lists, logs, cleanup internals, technical deletion details, commands, diagnostics, validation results, command output, internal modules, Registry names, Services names, Tasks names, AppX package names, TrustedInstaller details, or implementation details.

Do not claim absolute safety.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not delete files, clean temporary files, run cleanup actions, modify file system, registry, Windows settings, host configuration, or run Apply, Open, Default, Restore, or Analyze.

## Windows UI Layout Contract

Preserve the global Windows-stage AXIS layout: `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, no PNG/SVG/WPF vector placeholders, RTL with physical right-edge anchoring, Windows active, prior Check/Refresh/Setup/Installers/Graphics stages completed green, active Windows full white line, no partial progress line, support card separate from runtime status, runtime status near the primary action button, Next disabled until completion then blue, no auto-advance, Previous returns to the previous step, enabled buttons use hand cursor, disabled buttons do not hover, press, or use hand cursor, hover is crisp and readable with no grow/scale/blur, and pressed state is a subtle pressed-in effect.

## BiDi And Layout Notes

Title is English-only and should render LTR while remaining physically right-anchored.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, cleanup execution, deletion, file-system mutation, Registry mutation, host mutation, staging, committing, or pushing.

