# AXIS Bloatware Step Blueprint

Date: 2026-07-06
Scope: owner-approved Windows Part A customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `bloatware` Windows-stage step.

This phase is documentation-only. It does not implement UI behavior, remove AppX packages, install Microsoft Store, install Snipping Tool, repair AppX/features, modify packages, features, services, registry, files, Windows components, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `bloatware` |
| Customer-facing step title | `Bloatware` |
| Stage | `Windows` |
| Visible stage label | `Windows` |
| Production action mapping | customer-facing `ØªÙ†ÙÙŠØ° Ø§Ù„Ø®ÙŠØ§Ø±` maps later to internal `Apply` for `bloatware` |
| Production behavior note | The AXIS UI must preserve the existing BoostLab one-option-then-Apply behavior. Only the owner-approved customer-visible options listed below should appear. Other BoostLab options must not appear in the normal AXIS customer UI for this step. |
| Prototype behavior | Simulation only. Do not remove AppX packages. Do not install Microsoft Store. Do not install Snipping Tool. Do not repair AppX/features. Do not modify packages, features, services, registry, files, or Windows components. |

## Selector Behavior

Show an action selector.

Selector label:

`Ø§Ø®ØªØ± Ø§Ù„Ø¥Ø¬Ø±Ø§Ø¡`

Selector placeholder:

`Ø§Ø®ØªØ± Ø¥Ø¬Ø±Ø§Ø¡Ù‹ Ù…Ù† Ø§Ù„Ù‚Ø§Ø¦Ù…Ø©`

Customer-visible selector options:

- `Remove All Bloatware`
- `Install Store`
- `Install Snipping Tool`

The customer selects one action only.

The primary action button stays disabled until an action is selected.

Any other BoostLab bloatware options do not appear in this customer-facing AXIS step.

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `Bloatware` |
| Subtitle | `Ø¥Ø²Ø§Ù„Ø© Ø§Ù„ØªØ·Ø¨ÙŠÙ‚Ø§Øª ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠØ© Ø£Ùˆ ØªØ«Ø¨ÙŠØª Ù…ÙƒÙˆÙ†Ø§Øª Ù…Ø­Ø¯Ø¯Ø©.` |
| Primary action button | `ØªÙ†ÙÙŠØ° Ø§Ù„Ø®ÙŠØ§Ø±` |
| Information card title | `ØªÙ†Ø¸ÙŠÙ ØªØ·Ø¨ÙŠÙ‚Ø§Øª Ø§Ù„Ù†Ø¸Ø§Ù…` |
| Information card bullet 1 | `ØªØ³Ø§Ø¹Ø¯ Ù‡Ø°Ù‡ Ø§Ù„Ø®Ø·ÙˆØ© Ø¹Ù„Ù‰ Ø¥Ø²Ø§Ù„Ø© Ø§Ù„ØªØ·Ø¨ÙŠÙ‚Ø§Øª ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠØ© Ø£Ùˆ ØªØ«Ø¨ÙŠØª Ù…ÙƒÙˆÙ†Ø§Øª Ù…Ø­Ø¯Ø¯Ø© Ø­Ø³Ø¨ Ø§Ù„Ø®ÙŠØ§Ø± Ø§Ù„Ù…Ø®ØªØ§Ø±.` |
| Information card bullet 2 | `Ø§Ø®ØªÙŠØ§Ø± Remove All Bloatware ÙŠØ±ÙƒØ² Ø¹Ù„Ù‰ ØªÙ†Ø¸ÙŠÙ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚Ø§Øª ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠØ©.` |
| Information card bullet 3 | `Ø§Ø®ØªÙŠØ§Ø± Install Store Ø£Ùˆ Install Snipping Tool ÙŠØ³ØªØ®Ø¯Ù… Ù„ØªØ«Ø¨ÙŠØª Ø§Ù„Ù…ÙƒÙˆÙ† Ø§Ù„Ù…Ø·Ù„ÙˆØ¨ ÙÙ‚Ø·.` |
| Requirements card title | `Ø§Ù„Ù…ØªØ·Ù„Ø¨Ø§Øª` |
| Requirements bullet 1 | `Ø§Ù‚Ø±Ø£ Ø§Ù„ØªØ¹Ù„ÙŠÙ…Ø§Øª Ù‚Ø¨Ù„ ØªÙ†ÙÙŠØ° Ø§Ù„Ø®ÙŠØ§Ø± Ø§Ù„Ù…Ø­Ø¯Ø¯.` |
| Requirements bullet 2 | `ØªØ£ÙƒØ¯ Ù…Ù† Ø§Ø®ØªÙŠØ§Ø± Ø§Ù„Ø¥Ø¬Ø±Ø§Ø¡ Ø§Ù„ØµØ­ÙŠØ­ Ù…Ù† Ø§Ù„Ù‚Ø§Ø¦Ù…Ø© Ù‚Ø¨Ù„ Ø§Ù„Ù…ØªØ§Ø¨Ø¹Ø©.` |
| Confirmation checkbox | `Ù„Ù‚Ø¯ Ù‚Ø±Ø£Øª Ø§Ù„ØªØ¹Ù„ÙŠÙ…Ø§Øª` |
| Confirmation primary button | `ØªÙ†ÙÙŠØ° Ø§Ù„Ø®ÙŠØ§Ø±` |
| Confirmation return button | `Ø±Ø¬ÙˆØ¹` |
| Running state | `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°` |
| Completed state | `Ù…ÙƒØªÙ…Ù„` |

## Requirements Card

Show the requirements card using only the owner-approved title and bullets recorded above.

## Confirmation Overlay

Use a confirmation overlay with checkbox.

The primary overlay button stays disabled until the checkbox is checked.

The checkbox checked fill is blue with no checkmark, matching the approved existing pattern.

`Ø±Ø¬ÙˆØ¹` closes the overlay only.

No Cancel button appears.

## Runtime Status And Completion

During simulated action, show `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªÙ†ÙÙŠØ°`.

After simulated completion, show `Ù…ÙƒØªÙ…Ù„`.

After completion, show no additional customer-facing text. Only enable the Next button.

## Customer-Facing Restrictions

Do not show AppX package names.

Do not show feature names.

Do not show TrustedInstaller details.

Do not show logs.

Do not show PowerShell commands.

Do not show technical removal details.

Do not show technical failure/error output.

Do not expose hidden BoostLab options in the normal AXIS customer UI.

Do not show Registry names, Services names, Tasks names, file paths, diagnostics, validation results, command output, internal modules, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not remove AppX packages, install Microsoft Store, install Snipping Tool, repair AppX/features, modify packages, features, services, registry, files, Windows components, Windows settings, host configuration, or run Apply, Open, Default, Restore, or Analyze.

## Windows UI Layout Contract

Preserve the global Windows-stage AXIS layout: `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, RTL with physical right-edge anchoring, Windows active, prior stages completed green, active Windows full white line, support card separate, runtime status near the primary action button, Next disabled until completion then blue, no auto-advance.

## BiDi And Layout Notes

Title and selector option names are English.

Render English labels LTR while keeping the block physically right-anchored.

Mixed Arabic/English option names inside Arabic lines must be rendered safely.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, AppX mutation, Microsoft Store installation, Snipping Tool installation, feature repair, service mutation, Registry mutation, host mutation, staging, committing, or pushing.
