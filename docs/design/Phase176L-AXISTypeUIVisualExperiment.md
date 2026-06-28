# Phase 176L - AXIS TypeUI Visual Experiment

Date: 2026-06-28
Scope: isolated AXIS first-use wizard prototype only

## Purpose

Phase 176L is a temporary visual experiment for the isolated AXIS first-use wizard prototype.

The experiment uses the local TypeUI markdown kit as read-only design guidance only:

`C:\Users\d3f4ult\Downloads\untitled-project-markdown-files\untitled-project`

The kit was not copied into the repository, added as a dependency, wired into runtime code, or treated as an official AXIS design system dependency.

This experiment remains read-only historical visual guidance only and is not a runtime dependency.

## Visual Direction

The wizard moved toward a lighter, cleaner, calmer first-use direction:

- lighter shell and panel surfaces
- clearer wizard-specific text colors
- softer bordered cards
- compact stage strip typography
- pill-shaped visual buttons
- restrained shadows for tactile surfaces
- warm primary action accent with AXIS blue still used for stage emphasis

This is inspired by the kit's guidance around crisp borders, rounded controls, compact hierarchy, and restrained accents. It is not a direct copy of TypeUI, Win11Debloat, AtlasOS, or AME Wizard.

## Stage Order Fix

The progress strip now normalizes incoming stage data to the canonical AXIS/BoostLab order:

1. Check
2. Refresh
3. Setup
4. Installers
5. Graphics
6. Windows
7. Advanced

When `config/Stages.psd1` is readable, the prototype sorts by the explicit `Order` field and only accepts it when it matches the canonical sequence. Otherwise, the prototype falls back to the exact order above.

The strip remains stage-only and does not show script or tool names.

## Clipping And Overflow

The preview keeps the `900 x 650` target size.

The shell keeps fixed header, progress, and bottom navigation rows while the central step content remains scrollable when needed. The stage strip uses seven equal columns, smaller labels, and clipped progress geometry so the right edge and bottom action area remain visible.

## Preview

Manual preview from the repository root:

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\tools\dev\Start-AxisFirstUseWizardPreview.ps1
```

Test-safe modes:

```powershell
.\tools\dev\Start-AxisFirstUseWizardPreview.ps1 -BuildOnly
.\tools\dev\Start-AxisFirstUseWizardPreview.ps1 -NoShow
.\tools\dev\Start-AxisFirstUseWizardPreview.ps1 -ValidateOnly
```

## Boundaries

This phase does not:

- wire the wizard into `ui/MainWindow.ps1`
- run Apply, Default, Restore, Open, Analyze, or any runtime action
- change tool order, action labels, action plans, verification, async execution, restart behavior, diagnostics behavior, or result contracts
- mutate registry, services, tasks, packages, AppX, drivers, BitLocker, activation, cleanup targets, installers, Defender, Timer, NVIDIA, or Start Menu layout
- modify `source-ultimate`
- modify `source-extra`
- modify `intake`
- add TypeUI as a runtime dependency
- copy TypeUI kit files into the repository
- perform a technical BoostLab-to-AXIS rename
- implement localization
- commit or push

## Customer State Model

The customer-facing first-use wizard model remains:

- Ready
- Checking
- Completed

`Completed` remains the only customer-facing end state.

The normal prototype UI continues to avoid customer-visible problem labels such as error, failed, warning, needs-attention, restart-needed, waiting, unavailable, skipped, stopped, or completed-with-notes language.

## Validation

Validation for this experiment includes:

- `tests\Test-AxisFirstUseWizardPrototype.ps1`
- `tests\Test-AxisFirstUseWizardPreviewHarness.ps1`
- `tests\Test-AxisWpfResources.ps1`
- full safe/static suite
- `git diff --check`
- final `git status --short`

No real Apply/runtime actions should be run during validation.
