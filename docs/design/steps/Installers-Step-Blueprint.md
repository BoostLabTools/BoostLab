# AXIS Installers Step Blueprint

Date: 2026-07-06
Scope: owner-approved Installers-stage customer copy contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `installers` Installers-stage step.

This phase is documentation-only. It does not implement UI behavior, run Apply, run Analyze, run Open, run Default, run Restore, download anything, run installers, launch apps, delete services, modify Services, modify Registry, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `installers` |
| Customer-facing step title | `ØªØ«Ø¨ÙŠØª Ø§Ù„Ø¨Ø±Ø§Ù…Ø¬` |
| Stage | `Installers` |
| Visible stage label | `Installers` |
| Production action mapping | customer-facing `Install` maps later to internal `Apply` for `installers` |
| Production behavior | Install one selected retained app from the existing BoostLab approved catalog. |
| Prototype behavior | Simulation only. Do not download anything. Do not install anything. Do not open installers. Do not launch apps. Do not delete services. Do not modify Services. Do not modify Registry. Do not execute the real installers Apply action. |

Do not change the real script behavior.

Do not add multi-install behavior.

Do not add new app catalog behavior.

The AXIS UI must reflect the existing one-app-at-a-time behavior.

Internal runtime actions may include Analyze, Open, Apply, Default, or Restore according to config/runtime state, but the normal customer-facing AXIS first-use wizard exposes only the owner-approved selector and `Install` action recorded here.

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `ØªØ«Ø¨ÙŠØª Ø§Ù„Ø¨Ø±Ø§Ù…Ø¬` |
| Subtitle | `Ø§Ø®ØªÙŠØ§Ø± ÙˆØªØ«Ø¨ÙŠØª Ø§Ù„Ø¨Ø±Ø§Ù…Ø¬ Ø§Ù„Ø£Ø³Ø§Ø³ÙŠØ© Ø¹Ù„Ù‰ Ø§Ù„Ø¬Ù‡Ø§Ø².` |
| Primary action button | `Install` |
| Selector label | `Ø§Ø®ØªØ± Ø§Ù„Ø¨Ø±Ù†Ø§Ù…Ø¬` |
| Selector placeholder | `Ø§Ø®ØªØ± Ø¨Ø±Ù†Ø§Ù…Ø¬Ù‹Ø§ Ù…Ù† Ø§Ù„Ù‚Ø§Ø¦Ù…Ø©` |
| Information card title | `Ø§Ø®ØªÙŠØ§Ø± Ø§Ù„Ø¨Ø±Ù†Ø§Ù…Ø¬` |
| Information card bullet 1 | `Ø§Ø®ØªØ± Ø§Ù„Ø¨Ø±Ù†Ø§Ù…Ø¬ Ø§Ù„Ù…Ø·Ù„ÙˆØ¨ Ù…Ù† Ø§Ù„Ù‚Ø§Ø¦Ù…Ø©.` |
| Information card bullet 2 | `Ø³ÙŠØªÙ… ØªØ¬Ù‡ÙŠØ² ØªØ«Ø¨ÙŠØª Ø§Ù„Ø¨Ø±Ù†Ø§Ù…Ø¬ Ø§Ù„Ù…Ø­Ø¯Ø¯ Ø¹Ù„Ù‰ Ø§Ù„Ø¬Ù‡Ø§Ø².` |
| Information card bullet 3 | `ÙŠØ¸Ù‡Ø± Ø§Ø³Ù… Ø§Ù„Ø¨Ø±Ù†Ø§Ù…Ø¬ Ø§Ù„Ù…Ø­Ø¯Ø¯ Ø£Ø«Ù†Ø§Ø¡ Ø¹Ù…Ù„ÙŠØ© Ø§Ù„ØªØ«Ø¨ÙŠØª.` |
| Requirements card title | `Ø§Ù„Ù…ØªØ·Ù„Ø¨Ø§Øª` |
| Requirements bullet 1 | `Ù‚Ù… Ø¨Ø¥ØºÙ„Ø§Ù‚ Ø§Ù„Ø¨Ø±Ø§Ù…Ø¬ Ø§Ù„Ù…ÙØªÙˆØ­Ø© Ù‚Ø¨Ù„ Ø¨Ø¯Ø¡ Ø§Ù„ØªØ«Ø¨ÙŠØª.` |
| Requirements bullet 2 | `Ø§Ù†ØªØ¸Ø± Ø­ØªÙ‰ ØªÙƒØªÙ…Ù„ Ø¹Ù…Ù„ÙŠØ© ØªØ«Ø¨ÙŠØª Ø§Ù„Ø¨Ø±Ù†Ø§Ù…Ø¬ Ø§Ù„Ù…Ø­Ø¯Ø¯.` |
| Confirmation overlay | Not shown |
| Running state | `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªØ«Ø¨ÙŠØª` |
| Selected app display | `Ø§Ù„Ø¨Ø±Ù†Ø§Ù…Ø¬ Ø§Ù„Ù…Ø­Ø¯Ø¯: {Ø§Ø³Ù… Ø§Ù„Ø¨Ø±Ù†Ø§Ù…Ø¬}` |
| Completed state | `ØªÙ… Ø§Ù„ØªØ«Ø¨ÙŠØª` |

## Selector Behavior

Show a dropdown or list selector.

Selector source: use the same current BoostLab installers catalog.

Selection mode: one program only.

The customer can select one program only.

The Install button stays disabled until a program is selected.

The selected program name may be displayed near runtime status during simulation.

Do not add multi-install behavior.

Do not add a new app catalog.

Do not expose catalog internals beyond the customer-visible app names.

## Requirements Card

Show the requirements card using only the owner-approved title and bullets recorded above.

Do not mention Internet requirement in the normal customer UI.

Do not show download links or source websites.

## Confirmation Overlay

No confirmation overlay should be shown.

## Runtime Status And Completion

During simulated action, show `Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªØ«Ø¨ÙŠØª`.

When a program is selected, the selected app display may show `Ø§Ù„Ø¨Ø±Ù†Ø§Ù…Ø¬ Ø§Ù„Ù…Ø­Ø¯Ø¯: {Ø§Ø³Ù… Ø§Ù„Ø¨Ø±Ù†Ø§Ù…Ø¬}`.

After simulated completion, show `ØªÙ… Ø§Ù„ØªØ«Ø¨ÙŠØª`.

After completion, show no additional general customer-facing text. Only enable the Next button.

## Epic Games Launcher Special UI Note

If and only if the selected catalog item is Epic Games Launcher, show an additional Epic-specific guidance block.

Epic guidance title:

`Ø®Ø·ÙˆØ© Ø¥Ø¶Ø§ÙÙŠØ© Ù„Ù€ Epic Games`

Epic guidance text:

- `Ø¨Ø¹Ø¯ Ø§ÙƒØªÙ…Ø§Ù„ Ø§Ù„ØªØ«Ø¨ÙŠØª ÙˆØ¸Ù‡ÙˆØ± Ù†Ø§ÙØ°Ø© Epic Games LauncherØŒ Ø£ØºÙ„Ù‚ Ø§Ù„Ù†Ø§ÙØ°Ø© Ø£ÙˆÙ„Ù‹Ø§.`
- `Ø¨Ø¹Ø¯ Ø¥ØºÙ„Ø§Ù‚ Ø§Ù„Ù†Ø§ÙØ°Ø©ØŒ Ø£ÙƒÙ…Ù„ Ø®Ø·ÙˆØ© Ø¥Ø²Ø§Ù„Ø© Ø®Ø¯Ù…Ø© Epic Games ØºÙŠØ± Ø§Ù„Ø¶Ø±ÙˆØ±ÙŠØ© Ù„ØªØ­Ø³ÙŠÙ† ØªØ¬Ø±Ø¨Ø© Ø§Ù„ØªØ´ØºÙŠÙ„.`

Epic checkbox text:

`ØªÙ… Ø¥ØºÙ„Ø§Ù‚ Ù†Ø§ÙØ°Ø© Epic Games Launcher`

Epic checkbox behavior:

- This checkbox appears only when Epic Games Launcher is selected.
- This checkbox does not appear for any other program.
- In the prototype, this is guidance/simulation only.
- Do not delete any real Epic Games service.
- Do not modify Services.
- Do not add new real runtime behavior beyond what the existing BoostLab script already supports.

## Customer-Facing Restrictions

Do not show download links.

Do not show source websites.

Do not show installer filenames.

Do not show hashes.

Do not show logs.

Do not show diagnostics.

Do not show PowerShell commands.

Do not show internal download/install implementation details.

Do not show failure/error details in the normal customer UI.

Do not expose catalog internals beyond the customer-visible app names.

Do not show internal action names, Registry names, Services names, Tasks names, file paths, modules, command output, validation results, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not download anything, install anything, open installers, launch apps, delete services, modify Services, modify Registry, execute the real installers Apply action, run Analyze, run Open, run Default, run Restore, mutate host state, or add new runtime behavior.

## Installers UI Layout Contract

The future Installers prototype should preserve `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, no PNG/SVG/WPF vector placeholders, Arabic-first copy except owner-approved English button/title tokens, RTL layout with physical right-edge anchoring, and the stage strip logical order Check, Refresh, Setup, Installers, Graphics, Windows, Advanced.

For Arabic, the visual order is mirrored while logical stage order remains correct. Installers is active for this step. Previous Check, Refresh, and Setup stages are completed green. Active Installers uses a full white line. There is no partial or incomplete progress line.

The support card appears in every step and remains separate from runtime status:

| Surface | Owner-approved value |
| --- | --- |
| Support card title | `Ù…Ø³Ø§Ø¹Ø¯Ø©` |
| Support card body | `ØªØ­ØªØ§Ø¬ Ù…Ø³Ø§Ø¹Ø¯Ø©ØŸ ÙŠÙ…ÙƒÙ†Ùƒ Ø§Ù„ØªÙˆØ§ØµÙ„ Ù…Ø¹ Ø£Ø®ØµØ§Ø¦ÙŠ Ø§Ù„Ø¯Ø¹Ù… Ø¹Ø¨Ø± Ø®Ø§Ø¯Ù… Discord Ø§Ù„Ø®Ø§Øµ Ø¨Ø§Ù„Ù…ØªØ¬Ø±.` |

Runtime status stays near the primary action button. Next is disabled until action simulation completes, then enabled and blue. There is no auto-advance. Previous returns to the previous step.

Enabled buttons use hand cursor. Disabled buttons do not hover, do not press, and do not use hand cursor. Hover must be crisp and readable, with no grow, scale, or blur. Pressed state should be a subtle pressed-in effect.

## BiDi And Layout Notes

Primary action button is English-only: `Install`.

Keep it visually stable and readable.

Program names may contain English.

Selected program name must use BiDi-safe rendering inside Arabic text.

The title is Arabic and must be physically right-anchored.

Any English app names inside Arabic lines must not jump to the wrong side.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze actions, downloads, installer execution, external app launches, service mutation, Registry mutation, host mutation, staging, committing, or pushing.
