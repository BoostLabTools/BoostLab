# AXIS Edge WebView Step Blueprint

Date: 2026-07-06
Scope: owner-approved Windows Part B customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `edge-webview` Windows-stage step.

This phase is documentation-only. It does not implement UI behavior, remove Edge WebView, repair or install Edge/WebView components, change Services, download installers, clean files, modify registry, modify files, modify Windows settings, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `edge-webview` |
| Customer-facing step title | `Edge WebView` |
| Stage | `Windows` |
| Visible stage label | `Windows` |
| Production action mapping | customer-facing `Ø¥Ø²Ø§Ù„Ø© Edge WebView` maps later to internal `Apply` for `edge-webview` |
| Default action | Do not expose Default/restore in normal customer UI now |
| Prototype behavior | Simulation only. Do not remove Edge WebView. Do not repair or install Edge/WebView components. Do not change Services. Do not download installers. Do not clean files. Do not modify registry, files, Windows settings, or host configuration. |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Edge WebView` |
| Subtitle | `Ø¥Ø²Ø§Ù„Ø© Edge WebView ÙˆØªÙ‚Ù„ÙŠÙ„ Ø§Ù„Ù…ÙƒÙˆÙ†Ø§Øª ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠØ© Ù„ØªØ­Ø³ÙŠÙ† Ø§Ù„Ø£Ø¯Ø§Ø¡.` |
| Primary action button | `Ø¥Ø²Ø§Ù„Ø© Edge WebView` |
| Information card title | `ØªÙ†Ø¸ÙŠÙ Ù…ÙƒÙˆÙ†Ø§Øª Edge WebView` |
| Information card bullet 1 | `Ø¥Ø²Ø§Ù„Ø© Edge WebView Ø­Ø³Ø¨ Ù…Ø³Ø§Ø± BoostLab Ø§Ù„Ù…Ø¹ØªÙ…Ø¯.` |
| Information card bullet 2 | `ØªÙ‚Ù„ÙŠÙ„ Ø§Ù„Ù…ÙƒÙˆÙ†Ø§Øª ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠØ© ÙŠØ³Ø§Ø¹Ø¯ Ø¹Ù„Ù‰ Ø¬Ø¹Ù„ Ø§Ù„Ù†Ø¸Ø§Ù… Ø£Ø®Ù Ø£Ø«Ù†Ø§Ø¡ Ø§Ù„Ø§Ø³ØªØ®Ø¯Ø§Ù….` |
| Information card bullet 3 | `ÙŠØªÙ… ØªÙ†ÙÙŠØ° Ø§Ù„Ø¥Ø¹Ø¯Ø§Ø¯ Ø§Ù„Ù…Ù†Ø§Ø³Ø¨ ØªÙ„Ù‚Ø§Ø¦ÙŠÙ‹Ø§ Ø£Ø«Ù†Ø§Ø¡ Ù‡Ø°Ù‡ Ø§Ù„Ø®Ø·ÙˆØ©.` |
| Requirements card | Not shown |
| Confirmation checkbox | `Ù„Ù‚Ø¯ Ù‚Ø±Ø£Øª Ø§Ù„ØªØ¹Ù„ÙŠÙ…Ø§Øª` |
| Confirmation primary button | `Ø¥Ø²Ø§Ù„Ø© Edge WebView` |
| Confirmation return button | `Ø±Ø¬ÙˆØ¹` |
| Running state | `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°` |
| Completed state | `Ù…ÙƒØªÙ…Ù„` |
| Support panel title | `Ù…Ø³Ø§Ø¹Ø¯Ø©` |
| Support panel body | `ØªØ­ØªØ§Ø¬ Ù…Ø³Ø§Ø¹Ø¯Ø©ØŸ ÙŠÙ…ÙƒÙ†Ùƒ Ø§Ù„ØªÙˆØ§ØµÙ„ Ù…Ø¹ Ø£Ø®ØµØ§Ø¦ÙŠ Ø§Ù„Ø¯Ø¹Ù… Ø¹Ø¨Ø± Ø®Ø§Ø¯Ù… Discord Ø§Ù„Ø®Ø§Øµ Ø¨Ø§Ù„Ù…ØªØ¬Ø±.` |

## Confirmation Overlay

Use a confirmation overlay with the checkbox text `Ù„Ù‚Ø¯ Ù‚Ø±Ø£Øª Ø§Ù„ØªØ¹Ù„ÙŠÙ…Ø§Øª`.

The primary overlay button is `Ø¥Ø²Ø§Ù„Ø© Edge WebView` and stays disabled until the checkbox is checked.

The checkbox checked fill is blue with no checkmark, matching the approved existing pattern.

`Ø±Ø¬ÙˆØ¹` closes the overlay only.

No Cancel button should appear.

## Runtime Status And Completion

During simulated action, show `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°`.

After simulated completion, show `Ù…ÙƒØªÙ…Ù„`.

After completion, show no additional customer-facing text. Only enable the Next button.

## Requirements Card

No requirements card should be shown.

## Customer-Facing Restrictions

Do not show services details, installers, file cleanup details, URLs, package details, logs, commands, diagnostics, validation results, command output, internal modules, Registry names, Services names, Tasks names, AppX package names, TrustedInstaller details, file paths, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not remove Edge WebView, repair or install Edge/WebView components, change Services, download installers, clean files, modify registry, files, Windows settings, host configuration, or run Apply, Open, Default, Restore, or Analyze.

## Windows UI Layout Contract

Preserve the global Windows-stage AXIS layout: `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, no PNG/SVG/WPF vector placeholders, RTL with physical right-edge anchoring, Windows active, prior Check/Refresh/Setup/Installers/Graphics stages completed green, active Windows full white line, no partial progress line, support card separate from runtime status, runtime status near the primary action button, Next disabled until completion then blue, no auto-advance, Previous returns to the previous step, enabled buttons use hand cursor, disabled buttons do not hover, press, or use hand cursor, hover is crisp and readable with no grow/scale/blur, and pressed state is a subtle pressed-in effect.

## BiDi And Layout Notes

Title is English-only and should render LTR while remaining physically right-anchored.

`Edge WebView` and `BoostLab` inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, Windows Settings launch, Edge/WebView mutation, Services mutation, file cleanup, Registry mutation, host mutation, staging, committing, or pushing.

