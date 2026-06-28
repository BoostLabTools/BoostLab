# Phase 176I - AXIS Prototype Preview Harness

Date: 2026-06-28
Scope: developer-only prototype preview harness

## Purpose

This phase adds a safe developer-only launcher for the isolated AXIS Guided Stage Workspace prototype from Phase 176H.

The harness lets the product owner open the static AXIS prototype visually without replacing the current BoostLab UI, wiring the prototype into `MainWindow`, running tools, or changing runtime behavior.

This is not production UI.

## Changed Files

- `tools/dev/Start-AxisPrototypePreview.ps1`
- `tests/Test-AxisPrototypePreviewHarness.ps1`
- `docs/design/Phase176I-AXISPrototypePreviewHarness.md`

## Manual Preview

Run the preview from the repository root in an STA Windows PowerShell session:

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\tools\dev\Start-AxisPrototypePreview.ps1
```

The launcher opens the static AXIS Guided Stage Workspace prototype window and exits cleanly when the window closes.

The launcher prints a console message explaining that this is a static AXIS prototype preview and that no setup tools are connected or run from the window.

## STA Requirement

WPF requires an STA thread.

The launcher checks the current thread apartment state before creating the preview window. If it is not running in STA, it throws a clear message with the supported command.

The launcher does not self-relaunch and does not call `Start-Process`.

## Test-Safe Mode

The launcher supports test-safe build modes:

```powershell
.\tools\dev\Start-AxisPrototypePreview.ps1 -BuildOnly
.\tools\dev\Start-AxisPrototypePreview.ps1 -NoShow
.\tools\dev\Start-AxisPrototypePreview.ps1 -ValidateOnly
```

`-ValidateOnly` is an alias for `-NoShow`.

In these modes, the launcher:

- imports the AXIS WPF resources
- imports the isolated AXIS prototype module
- creates the preview window in memory
- verifies AXIS resources are attached
- does not show the window
- does not start a modal UI loop
- returns structured preview information

## Preview Content

The preview shows the Phase 176H isolated AXIS Guided Stage Workspace:

- AXIS product header
- Guided setup label
- Windows stage sample
- stage navigation
- tool / step cards
- selected tool detail panel
- visual-only action area
- risk badges
- customer-friendly result summary placeholder
- collapsed diagnostics drawer placeholder

The sample remains static and mocked.

## MainWindow

`ui/MainWindow.ps1` was not modified.

`ui/MainWindow.xaml` was not modified.

The default BoostLab UI remains unchanged. The AXIS prototype is available only through the explicit developer preview launcher.

## Runtime Safety

The preview harness does not:

- run Apply, Default, Restore, Open, or Analyze behavior
- call action plans
- change tool order or labels
- change verification
- change async execution
- change restart behavior
- change diagnostics behavior
- change result contracts
- import runtime modules unnecessarily
- require administrator privileges
- require `source-ultimate`, `source-extra`, or `intake`
- mutate files outside process memory
- mutate registry, services, tasks, packages, AppX, drivers, BitLocker, activation, cleanup targets, installers, Defender, Timer, NVIDIA, or Start Menu layout
- perform a technical BoostLab-to-AXIS rename
- implement localization
- add TypeUI, Figma, or third-party UI frameworks

## Not Implemented

This phase does not replace the current UI, add a production launch path, add a `MainWindow` feature flag, add live data binding, wire action buttons, read real logs, or change any tool behavior.

Future visual phases can use this launcher for design review while continuing to migrate actual UI components separately and safely.

## Validation

Validation for this phase includes:

- `tests/Test-AxisPrototypePreviewHarness.ps1`
- `tests/Test-AxisGuidedStageWorkspacePrototype.ps1`
- `tests/Test-AxisWpfResources.ps1`
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
