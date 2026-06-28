# Phase 176J - AXIS First-Use Wizard BIOS Information Prototype

Date: 2026-06-28
Scope: isolated first-use wizard prototype only

## Purpose

This phase adds a new isolated AXIS first-use wizard prototype focused on the BIOS Information step.

The prototype is a static visual direction slice. It does not replace the current BoostLab UI, wire into `MainWindow`, run tools, query firmware, or change runtime behavior.

## Direction Change

The previous isolated Guided Stage Workspace prototype remains in the repository, but the product-owner direction changed.

The desired first-use AXIS experience is now:

- small wizard-style guided flow
- one step visible at a time
- no sidebar
- no dashboard or workspace layout
- stage-only progress
- BIOS Information as the first visible step

The wizard keeps the dark, premium, technical AXIS design direction while reducing visual density.

## Completion-Only Customer State Model

The product-owner decision for the normal AXIS first-use customer UI is completion-only state language.

The visible customer outcome label is:

- Completed

The prototype intentionally avoids customer-visible problem, warning, failure, unavailable, skipped, waiting, stopped, or restart-needed state labels in the normal first-use wizard surface.

This does not change backend/runtime truth, diagnostics, developer-only reports, logs, or future internal result contracts. Technical detail can still preserve exact status later, but it should not appear as normal customer-facing state language.

## Changed Files

- `ui/AxisFirstUseWizardPrototype.ps1`
- `tools/dev/Start-AxisFirstUseWizardPreview.ps1`
- `tests/Test-AxisFirstUseWizardPrototype.ps1`
- `tests/Test-AxisFirstUseWizardPreviewHarness.ps1`
- `docs/design/Phase176J-AXISFirstUseWizardBIOSInformationPrototype.md`

## Window And Layout

Target window size:

- width: `900`
- height: `650`

The prototype uses a compact wizard shell:

- top product header
- stage-only progress strip
- centered single-step content
- bottom visual navigation

There is no left sidebar and no multi-card workspace.

## Stage Progress Strip

The progress strip shows stage names only:

- Check
- Refresh
- Setup
- Apps
- Graphics
- Windows
- Finish

The active sample stage is `Check`.

The strip is intentionally not a script list. It does not show tool names or step names such as BIOS Information.

## BIOS Information Step

The first visible step is:

- BIOS Information

The step explains that AXIS is reviewing basic firmware and motherboard information before deeper setup work.

Static sample content includes:

- BIOS/UEFI version
- motherboard and vendor details
- Windows boot mode when available later
- basic firmware readiness signals

The prototype does not query BIOS, firmware, motherboard, Windows boot mode, or device state.

The BIOS Information sample starts in a neutral `Ready` state and supports a visual `Checking` placeholder. The only customer-facing end state in the model is `Completed`.

## BIOS Icon

`ui/AxisFirstUseWizardPrototype.ps1` creates a simple WPF vector-style BIOS Information icon using shapes.

The icon direction is:

- motherboard/chip outline
- subtle firmware dot
- restrained blue/cyan accent
- no external image asset

## Documentation Button Rule

Every future AXIS step should include a documentation or learn-more action.

The BIOS Information prototype includes:

- `View documentation`
- static AXIS Documentation / BIOS Information guide concept

The button is visual-only in this phase. It does not open a browser, launch a URL, or call any external process.

## Documentation Acknowledgement Pattern

The wizard model includes a future dangerous-step acknowledgement pattern:

- `RequiresDocumentationAcknowledgement`
- acknowledgement text: `I have read the instructions for this step.`
- primary action disabled until acknowledged

BIOS Information sets `RequiresDocumentationAcknowledgement = false` because it is informational.

This phase does not implement full dangerous-step logic globally. It only proves the component and model shape.

## Preview

Manual preview command from the repository root:

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\tools\dev\Start-AxisFirstUseWizardPreview.ps1
```

Test-safe modes:

```powershell
.\tools\dev\Start-AxisFirstUseWizardPreview.ps1 -BuildOnly
.\tools\dev\Start-AxisFirstUseWizardPreview.ps1 -NoShow
.\tools\dev\Start-AxisFirstUseWizardPreview.ps1 -ValidateOnly
```

`-ValidateOnly` is an alias for `-NoShow`.

These modes build the preview window in memory and do not show it.

## MainWindow

`ui/MainWindow.ps1` was not modified.

`ui/MainWindow.xaml` was not modified.

The default BoostLab UI remains unchanged. The first-use wizard is only available through the explicit developer preview launcher.

## Visual-Only Boundaries

This phase does not:

- run tools
- run Apply, Default, Restore, Open, or Analyze behavior
- change tool order
- change action labels
- change action plans
- change verification
- change async execution
- change restart behavior
- change diagnostics behavior
- change result contracts
- query BIOS or device state
- mutate registry, services, tasks, packages, AppX, drivers, BitLocker, activation, cleanup targets, installers, Defender, Timer, NVIDIA, or Start Menu layout
- modify `source-ultimate`
- modify `source-extra`
- modify `intake`
- replace the current UI
- wire into production UI
- perform a technical BoostLab-to-AXIS rename
- implement localization
- add TypeUI, Figma, or third-party UI frameworks

## Validation

Validation for this phase includes:

- `tests/Test-AxisFirstUseWizardPrototype.ps1`
- `tests/Test-AxisFirstUseWizardPreviewHarness.ps1`
- `tests/Test-AxisWpfResources.ps1`
- previous AXIS prototype and preview harness tests
- module scaffolding tests
- reverse GUI/runtime contract validator
- reached/action label parity validator
- result severity policy tests
- runtime payload/source intent/operation descriptor tests
- source policy/hash tests
- full safe/static suite
- `git diff --check`
- final `git status --short`

No real Apply/runtime actions should be run during validation.
