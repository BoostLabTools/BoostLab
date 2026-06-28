# Phase 176M - AXIS First-Use Wizard Neutral Palette Experiment

Date: 2026-06-28
Scope: isolated AXIS first-use wizard prototype only

## Purpose

Phase 176M applies a premium neutral color direction to the isolated AXIS first-use wizard prototype.

This is a visual experiment only. It does not change runtime behavior, production UI integration, modules, tool order, execution flow, diagnostics, or result contracts.

The light neutral palette remains a historical visual experiment and is not the restored Phase 176N dark premium natural wizard direction.

## Approved Palette

Off-white set:

- `#F5F5F5`
- `#FAF9F6`
- `#F0F2F5`
- `#EDEDED`

Dark-gray set:

- `#121212`
- `#2C2C2C`
- `#222222`
- `#0C0C0C`

The wizard-specific tokens in `ui/AxisResources.ps1` are constrained to this approved set.

## Visual Direction

The prototype keeps the current wizard layout and restyles it toward:

- off-white background and surfaces
- very dark gray headings and strong text
- dark gray secondary text
- subtle off-white borders
- restrained shadows
- a deep neutral primary button
- neutral status boxes for `Ready`, `Checking`, and `Completed`

The intended feel is premium, minimal, clean, soft, modern, readable, and calm. It should not feel like dark mode, and it should not use loud saturated accent colors.

## Preserved Behavior Model

The experiment preserves:

- target window size: `900 x 650`
- BIOS Information as the first visible step
- stage-only progress strip
- canonical stage order: Check, Refresh, Setup, Installers, Graphics, Windows, Advanced
- documentation button
- action buttons
- status box
- customer-facing state model: Ready, Checking, Completed
- Completed as the only customer-facing end state
- no customer-facing problem labels

## Boundaries

This phase does not:

- modify `ui/MainWindow.ps1`
- wire the prototype into production UI
- run Apply, Default, Restore, Open, Analyze, or any runtime action
- mutate host state
- modify `source-ultimate`
- modify `source-extra`
- modify `intake`
- add external TypeUI files, assets, packages, or runtime dependencies
- commit or push

## Validation

Validation for this experiment includes:

- `tests\Test-AxisFirstUseWizardPrototype.ps1`
- `tests\Test-AxisFirstUseWizardPreviewHarness.ps1`
- `tests\Test-AxisWpfResources.ps1`
- full safe/static suite
- `git diff --check`
- final `git status --short`
