# Phase 176G - AXIS WPF Token Resource Foundation

Date: 2026-06-28
Scope: WPF token/resource foundation only

## Purpose

This phase adds the first centralized AXIS WPF design token and resource foundation for the current PowerShell/WPF application.

The goal is to make future visual work safer by establishing reusable token data and WPF resource creation helpers before any UI redesign, component migration, or prototype layout work begins.

## Changed Files

- `ui/AxisResources.ps1`
- `tests/Test-AxisWpfResources.ps1`
- `docs/design/Phase176G-AXISWPFTokenResourceFoundation.md`

## Resource File

The resource foundation lives at:

`ui/AxisResources.ps1`

It is safe to dot-source/import without launching the UI, running tools, changing the host, or touching application state. It defines functions only. WPF assemblies are loaded only when a caller requests WPF resource construction.

## Resource Naming Convention

Resources use the `Axis.` prefix:

- `Axis.Color.Background.App`
- `Axis.Color.Surface.Base`
- `Axis.Color.Text.Primary`
- `Axis.Color.Accent.Primary`
- `Axis.Brush.Background.App`
- `Axis.Brush.Surface.Base`
- `Axis.Brush.Text.Primary`
- `Axis.Brush.Accent.Primary`
- `Axis.Space.16`
- `Axis.Thickness.16`
- `Axis.Radius.Medium`
- `Axis.Status.Completed.Brush`
- `Axis.Status.CompletedWithNotes.Brush`
- `Axis.Risk.DriverChange.Brush`
- `Axis.Focus.Ring.Brush`

The resource names may use AXIS because they describe the future customer-facing design system. This does not rename the repository, modules, tool ids, runtime identifiers, tests, or technical BoostLab symbols.

## Functions Added

`ui/AxisResources.ps1` defines:

- `Get-AxisDesignTokens`
- `New-AxisWpfResourceDictionary`
- `Add-AxisResourcesToElement`
- `Get-AxisResourceValue`
- `Test-AxisDesignTokens`

It also includes internal helper functions for safe WPF assembly loading, color conversion, frozen brush creation, font-weight conversion, and token lookup.

## Token Categories Implemented

Implemented token groups:

- color tokens
- brush resources
- typography tokens
- spacing tokens
- thickness resources derived from spacing
- radius/corner resources
- border width tokens
- customer-facing status/result tokens
- risk tokens
- focus tokens
- diagnostics tokens

Customer-facing result states:

- Completed
- Completed with notes
- Needs attention
- Stopped
- Restart needed
- Waiting for confirmation
- Not available on this device
- Skipped because not needed
- Running

Risk categories:

- System change
- Driver change
- Security-sensitive
- Restart required
- Download required
- File cleanup
- Advanced
- Device-specific

## MainWindow Wiring

`ui/MainWindow.ps1` and `ui/MainWindow.xaml` were intentionally not modified in this phase.

The AXIS resources are ready for future phases, but they are not yet merged into the active window resources and are not applied to existing controls. This avoids visual or runtime behavior changes before the token foundation has its own validator.

## Future Use

Future phases should:

1. Import or dot-source `ui/AxisResources.ps1`.
2. Create a resource dictionary with `New-AxisWpfResourceDictionary`.
3. Add it to an explicit WPF element with `Add-AxisResourcesToElement`.
4. Migrate styles one component at a time.
5. Keep tool/action/runtime behavior unchanged while styling.

The recommended next UI implementation path remains:

1. token/resource foundation
2. basic text/surface/button/card styles
3. stage navigation style
4. tool card style
5. result summary style
6. diagnostics drawer style
7. confirmation dialog style
8. first Guided Stage Workspace visual prototype

## Intentionally Not Implemented

This phase does not:

- redesign the UI
- wire resources into MainWindow
- migrate existing XAML styles
- migrate PowerShell-generated card/dialog styles
- change Apply, Default, Restore, Open, or Analyze behavior
- change action plans
- change verification logic
- change async execution
- change restart behavior
- change diagnostics behavior
- change Latest Result behavior
- implement localization
- perform the technical BoostLab-to-AXIS rename
- add TypeUI, Figma, or any third-party UI framework

## Runtime Safety

The resource file does not start tools, launch UI, call runtime actions, change registry, alter services, schedule tasks, touch drivers, affect BitLocker, alter activation, run cleanup, install packages, change Defender/Timer/NVIDIA behavior, or mutate host system state.

## Validation

Validation for this implementation should include:

- `tests/Test-AxisWpfResources.ps1`
- module scaffolding tests
- reverse GUI/runtime contract validator
- reached/action label parity validator
- result severity policy tests
- runtime payload/source intent/operation descriptor tests if affected
- source policy/hash tests
- full safe/static suite
- `git diff --check`
- `git status --short`

No real Apply/runtime actions should be run during validation.
