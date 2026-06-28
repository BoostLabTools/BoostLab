# Phase 176H - AXIS Isolated Guided Stage Workspace Prototype

Date: 2026-06-28
Scope: isolated visual prototype only

## Purpose

This phase adds the first isolated AXIS Guided Stage Workspace prototype.

The prototype proves the Phase 176A through Phase 176G design direction in a safe WPF surface without changing the current BoostLab runtime UI, action routing, tool behavior, verification behavior, diagnostics behavior, or result contracts.

This is not a full UI redesign.

## Changed Files

- `ui/AxisGuidedStageWorkspacePrototype.ps1`
- `tests/Test-AxisGuidedStageWorkspacePrototype.ps1`
- `docs/design/Phase176H-AXISIsolatedGuidedStageWorkspacePrototype.md`

## Prototype Scope

The prototype is built around the Windows stage as a representative customer-facing sample.

Included visual components:

- AXIS app shell slice
- product header
- guided setup mode label
- stage navigation
- Windows stage screen
- tool / step cards
- selected tool detail panel
- visual-only action area
- risk badges
- result summary placeholder
- diagnostics drawer placeholder
- static preview window factory

The prototype uses mocked/sample state only. It does not query runtime metadata, live tool state, device state, source folders, or logs.

## Preview Model

The default app UI is unchanged. `ui/MainWindow.ps1` and `ui/MainWindow.xaml` are not wired to the prototype.

For an isolated manual preview, an STA PowerShell session can dot-source the prototype module, create a preview window, and show that window explicitly:

```powershell
. .\ui\AxisGuidedStageWorkspacePrototype.ps1
$window = New-AxisGuidedStageWorkspacePrototypeWindow
$window.ShowDialog()
```

Creating the prototype or preview window does not run setup steps and does not attach action handlers.

## MainWindow

`ui/MainWindow.ps1` was not modified.

`ui/MainWindow.xaml` was not modified.

No environment-variable gate was added in this phase. Isolation is provided by the new prototype module and preview-window factory only.

## Sample States

The Windows stage sample includes these card states:

- Default
- Selected
- Running
- Completed
- Completed with notes
- Needs attention
- Restart needed
- Not available on this device
- Skipped because not needed

The result summary also includes:

- Waiting for your confirmation

The main customer-facing prototype does not use raw `Success`, `Warning`, or `Error` labels as primary state language.

## Representative Windows Cards

The mocked Windows cards include:

- Start menu and taskbar
- Context menu
- Theme and wallpaper
- Widgets
- Copilot
- Game Mode
- Power plan
- Cleanup
- Restart checkpoint

These are static visual samples. They are not connected to the existing runtime tools.

## Diagnostics Placeholder

The diagnostics drawer is collapsed by default and contains static placeholder sections:

- Summary
- Technical status
- Operations
- Logs
- Copy technical report

The drawer is intentionally secondary. It does not read or write real logs and does not change Latest Result data.

## Runtime Safety

This phase does not:

- run tools
- call Apply, Default, Restore, Open, or Analyze behavior
- change action plans
- change verification logic
- change async execution
- change restart behavior
- change diagnostics behavior
- change result contracts
- change Latest Result behavior
- query or mutate device state
- mutate registry, services, tasks, packages, AppX, drivers, BitLocker, activation, cleanup targets, installers, Defender, Timer, NVIDIA, or Start Menu layout
- modify `source-ultimate`
- modify `source-extra`
- modify `intake`
- perform a technical BoostLab-to-AXIS rename
- implement localization
- add TypeUI, Figma, or third-party UI frameworks

## Intentionally Not Implemented

This phase does not replace the current UI, migrate existing card rendering, restyle `MainWindow`, change confirmation dialogs, add live data binding, implement real diagnostics, or add runtime preview routing.

Future phases can decide whether to add an explicit development flag or migrate one component at a time after the isolated prototype is reviewed.

## Validation

Validation for this phase includes:

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
