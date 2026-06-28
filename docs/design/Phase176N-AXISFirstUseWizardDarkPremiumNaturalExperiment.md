# Phase 176N - AXIS First-Use Wizard Dark Premium Natural Experiment

Date: 2026-06-28
Scope: isolated AXIS first-use wizard prototype only

## Purpose

This phase applies a dark premium natural visual pass to the isolated AXIS first-use wizard prototype.

The change is visual-only. It does not change runtime behavior, production UI integration, modules, tool order, execution flow, diagnostics, or result contracts.

## Visual Direction

The wizard-specific resources use a calm neutral family:

- near-black and charcoal surfaces: `#0C0C0C`, `#121212`, `#222222`, `#2C2C2C`
- soft off-white text and accents: `#F5F5F5`, `#FAF9F6`, `#F0F2F5`, `#EDEDED`

The intended feel is premium, mature, restrained, and modern. The theme avoids neon, gamer-style saturation, and flashy accent color.

## BIOS Information Icon

The BIOS Information icon was clarified for the dark theme:

- added a dark neutral backplate
- increased board and chip stroke weight
- improved board/chip fill contrast
- enlarged the pin details
- kept the icon as local WPF vector shapes with no external assets

## Preserved Prototype Model

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
- add external assets, packages, or runtime dependencies
- commit or push

## Validation

Validation for this experiment includes:

- `tests\Test-AxisFirstUseWizardPrototype.ps1`
- `tests\Test-AxisFirstUseWizardPreviewHarness.ps1`
- `tests\Test-AxisWpfResources.ps1`
- full safe/static suite
- `git diff --check`
- final `git status --short`
