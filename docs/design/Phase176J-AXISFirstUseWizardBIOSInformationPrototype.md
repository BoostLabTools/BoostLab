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

## Phase 176K Correction

Phase 176K refines this prototype without changing runtime behavior.

Corrections:

- the preview keeps the `900 x 650` target window
- the root content now auto-sizes to the available client area
- the center step region fits inside the fixed layout without a default visible scrollbar
- the bottom action area remains fully visible
- the stage progress strip uses the canonical stage names from `config/Stages.psd1`
- the visual treatment shifts toward a cleaner, softer, more modern first-use wizard surface

The developer preview remains isolated and is not wired into production UI.

## Phase 176M Neutral Palette Experiment

Phase 176M keeps the isolated first-use wizard structure and behavior, but changes the wizard-specific visual tokens to a premium neutral palette.

The experiment uses only the approved off-white and dark-gray values:

- `#F5F5F5`
- `#FAF9F6`
- `#F0F2F5`
- `#EDEDED`
- `#121212`
- `#2C2C2C`
- `#222222`
- `#0C0C0C`

The result is intended to feel minimal, soft, modern, and premium without becoming dark mode or overly bright.

The change remains prototype-only and does not affect `MainWindow`, production runtime behavior, modules, or execution flow.

## Dark Premium Natural Iteration

The next visual iteration keeps the same isolated prototype structure and shifts the wizard-specific tokens to a dark premium natural palette.

The direction uses near-black and charcoal surfaces with soft off-white text and neutral accents. Earlier icon exploration from this iteration is superseded by the Phase 176Y text-only product decision.

This remains a visual-only experiment and does not affect `MainWindow`, production runtime behavior, modules, or execution flow. It does not add external image assets, design-kit dependencies, runtime dependencies, or production UI wiring.

## Phase 176V Small Polish

Phase 176V keeps the restored first-use wizard structure and applies only a small polish pass.

The polish:

- slightly darkens wizard-specific surfaces and borders
- keeps off-white text and neutral controls readable
- increases usable content room so the Ready/status panel is fully visible at `900 x 650`
- keeps the normal Windows titlebar/chrome, no sidebar, and stage-only progress strip
- any icon work from this earlier polish pass is superseded by the Phase 176Y text-only product decision

This remains prototype-only and does not affect `MainWindow`, production runtime behavior, modules, execution flow, diagnostics, or result contracts.

## Phase 176W Footer Polish

Phase 176W keeps the approved restored wizard direction and applies a narrow prototype-only footer refinement.

The polish:

- gives the footer row more vertical room so Back / Continue / Cancel borders and shadows are not clipped
- keeps the bottom-left prototype note and bottom-right visual buttons in the same footer structure

The earlier image-icon support from this pass is superseded by the Phase 176Y text-only product decision.

## Phase 176X Exact Model A BIOS Icon Superseded

Phase 176X briefly used the supplied cropped Model A BIOS Information PNG.

That decision is superseded by Phase 176Y. The current prototype does not load that PNG, does not draw a fallback, and does not keep an icon placeholder.

## Phase 176Y Text-Only Wizard Decision

Phase 176Y applies the final product-owner decision that the AXIS first-use wizard customer UI should not use icons.

The current prototype:

- removes the BIOS Information image icon
- removes the WPF vector fallback
- removes the icon column and empty placeholder space
- removes the status indicator next to `Ready`
- keeps the BIOS Information step as a text-only customer-facing screen

The layout remains prototype-only and does not affect `MainWindow`, production runtime behavior, modules, execution flow, diagnostics, or result contracts.

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
- Installers
- Graphics
- Windows
- Advanced

The active sample stage is `Check`.

The strip is intentionally not a script list. It does not show tool names or step names such as BIOS Information.

The stage names and order are taken from the project stage model in `config/Stages.psd1`.

## BIOS Information Step

The first visible step is:

- BIOS Information

The step explains that AXIS is reviewing basic firmware and motherboard information before deeper setup work.

Static sample content includes:

- BIOS/UEFI version
- motherboard and vendor details

The prototype does not query BIOS, firmware, motherboard, Windows boot mode, or device state.

The BIOS Information sample starts in a neutral `Ready` state and supports a visual `Checking` placeholder. The only customer-facing end state in the model is `Completed`.

## No BIOS Icon

The current prototype intentionally renders no BIOS Information icon.

The BIOS Information screen is text-only. It has no image icon, SVG icon, WPF vector icon, icon placeholder, icon column, or status indicator next to `Ready`.

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
