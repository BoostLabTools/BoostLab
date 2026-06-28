# Phase 176F - AXIS WPF Design Token Resource Implementation Plan

Date: 2026-06-28
Scope: WPF design token and resource implementation planning only

## Purpose

This document defines the future WPF implementation plan for AXIS design tokens and resource styles inside the current PowerShell/WPF application.

It explains how the Phase 176C design-token direction should later become centralized WPF resources and reusable style helpers without changing BoostLab runtime behavior. It also aligns with the Phase 176D component specs and the Phase 176E first Guided Stage Workspace prototype plan.

This phase is document-only. It is not implementation, the visual prototype, a component rewrite, a WPF resource-file addition, a technical BoostLab-to-AXIS rename, or a runtime behavior change. It is the plan for safe future WPF token/resource work.

## Current UI Implementation Review

The current UI is a stability/test interface. It already provides useful structure for stage navigation, tool cards, action routing, latest result rendering, activity logs, and confirmation dialogs. Future AXIS styling should migrate this gradually rather than replacing it in one broad pass.

Current implementation observations:

- `ui/MainWindow.xaml` defines the main window shell, layout columns, header, stage navigation host, tool-card host, latest-result panel, activity log, and several base styles.
- `Window.Resources` currently contains core brushes such as `PageBackground`, `HeaderBackground`, `PanelBackground`, `SurfaceBackground`, `BorderBrush`, `PrimaryText`, `SecondaryText`, `MutedText`, and `AccentBrush`.
- `Window.Resources` also defines styles such as `HeaderStatusBorderStyle`, `HeaderStatusTextStyle`, `SidebarButtonStyle`, `ActionButtonStyle`, and `PanelButtonStyle`.
- Several colors, sizes, margins, font sizes, and corner radii are still hardcoded directly in XAML outside reusable resources.
- `ui/MainWindow.ps1` dynamically builds badges, tool cards, result rows, bullets, action buttons, confirmation dialogs, and stage-selection state with PowerShell-created WPF controls.
- PowerShell-created controls use direct `BrushConverter` values, numeric dimensions, `Thickness`, `CornerRadius`, `FontSize`, `FontWeight`, and per-control layout choices.
- Current cards vary height for selection-heavy tools, and dialogs are created programmatically, so token application must support both XAML and PowerShell-created controls.
- Current latest-result and activity-log surfaces intentionally expose technical detail. AXIS customer-facing work should wrap that detail in a cleaner customer layer without removing it.

Implementation constraints:

- The app is PowerShell/WPF-based, not a compiled XAML/C# application.
- Some controls are declared in XAML and others are generated in PowerShell.
- Runtime event handlers, async execution, action-plan confirmation, latest-result rendering, and copyable diagnostics must remain stable.
- Tokens must be usable from both XAML resources and PowerShell helper functions.

Parts to migrate gradually:

- shared brush resources
- button styles
- sidebar/stage navigation styles
- tool-card and badge helpers
- result and diagnostics rendering helpers
- confirmation dialog styles
- layout sizing and spacing constants

## Token Implementation Strategy

The recommended future architecture is a centralized AXIS token/resource layer that can be loaded by the existing UI without changing runtime behavior.

Recommended future paths:

- `ui/AxisResources.ps1`: PowerShell helper for registering AXIS brushes, fonts, spacing values, radii, and reusable styles into a WPF resource dictionary.
- `ui/Styles/AxisTokens.ps1`: optional split-out token definitions if `AxisResources.ps1` becomes too large.
- `ui/Styles/AxisComponentStyles.ps1`: optional later style factories for cards, badges, navigation, dialogs, result summaries, and diagnostics.

These paths are recommendations only. This phase does not create them.

Architecture principles:

- centralize token values before broad visual changes
- use semantic token names rather than one-off color names
- expose WPF Brush resources for colors
- expose font family, font size, font weight, and line-height guidance through style helpers or resource values
- expose spacing constants for PowerShell-created `Thickness` values
- expose radius/corner constants for borders and cards
- define border and elevation conventions even when WPF shadows remain minimal
- define component state resources for hover, pressed, selected, focused, disabled, running, completed, needs-attention, and restart-needed states
- define status/result and risk resources separately from technical raw status colors
- define diagnostics-specific resources that preserve dense, copyable technical detail

## Token Categories To Implement Later

| Token category | WPF/PowerShell representation | Example resource naming style | Implementation risk | Migration priority |
| --- | --- | --- | --- | --- |
| Color tokens | raw color values stored once and converted into brushes | `Axis.Color.Background.App` | low if values are centralized first | high |
| Text tokens | brushes plus text style helpers | `Axis.Brush.Text.Primary`, `Axis.Text.Body.Style` | medium because text appears in XAML and generated controls | high |
| Surface tokens | brushes for shell, panels, cards, dialogs, and insets | `Axis.Brush.Surface.Card` | low | high |
| Border tokens | brushes and border thickness constants | `Axis.Brush.Border.Subtle`, `Axis.Border.Width.Default` | low | high |
| Accent tokens | brushes for primary action, hover, pressed, and accent text | `Axis.Brush.Accent.Primary` | low | high |
| Status/result tokens | brush families for customer result states | `Axis.Status.Completed.Brush`, `Axis.Status.NeedsAttention.BorderBrush` | medium because raw status labels must not drive customer labels directly | high |
| Risk tokens | badge brush families for risk categories | `Axis.Risk.DriverChange.Brush`, `Axis.Risk.FileCleanup.BorderBrush` | medium because risk mapping must remain presentation-only | high |
| Typography tokens | font family, size, weight, and line-height values | `Axis.Type.Body.FontSize`, `Axis.Type.CardTitle.Weight` | medium in PowerShell-created controls | high |
| Spacing tokens | integer/double constants and helper functions returning `Thickness` | `Axis.Space.16`, `New-AxisThickness -All Axis.Space.16` | medium because layout regressions are easy | medium |
| Radius tokens | corner radius constants/helpers | `Axis.Radius.Medium`, `New-AxisCornerRadius Medium` | low | medium |
| Elevation/shadow tokens | conventions and optional WPF effects | `Axis.Elevation.Low` | medium because WPF effects can hurt performance or readability | low |
| Focus tokens | focus brush, thickness, and style triggers | `Axis.Brush.Focus.Ring` | medium because keyboard behavior must be verified | high |
| Disabled state tokens | disabled brushes and text colors | `Axis.Brush.Disabled.Text` | low | high |
| Diagnostics tokens | brushes, monospace font, dense spacing | `Axis.Brush.Diagnostics.Background`, `Axis.Type.DiagnosticsMono.FontFamily` | medium because copyable diagnostics must remain readable | high |

## Resource Naming Convention

Future WPF resources should use a consistent `Axis.` prefix.

Recommended convention:

- color values: `Axis.Color.<Category>.<Role>`
- brush resources: `Axis.Brush.<Category>.<Role>`
- typography resources: `Axis.Type.<Role>.<Property>`
- spacing resources: `Axis.Space.<Value>`
- radius resources: `Axis.Radius.<Role>`
- border resources: `Axis.Border.<Role>.<Property>`
- status resources: `Axis.Status.<State>.<Property>`
- risk resources: `Axis.Risk.<RiskType>.<Property>`
- component styles: `Axis.Style.<Component>.<Variant>`

Examples:

- `Axis.Color.Background.App`
- `Axis.Color.Surface.Card`
- `Axis.Color.Text.Primary`
- `Axis.Brush.Background.App`
- `Axis.Brush.Accent.Primary`
- `Axis.Type.Body.FontSize`
- `Axis.Type.Body.FontWeight`
- `Axis.Space.16`
- `Axis.Radius.Medium`
- `Axis.Status.Completed.Brush`
- `Axis.Status.Completed.BorderBrush`
- `Axis.Risk.DriverChange.Brush`
- `Axis.Style.Button.Primary`
- `Axis.Style.ToolCard.Default`

The internal repository and many technical symbols may still be named BoostLab for now. Resource names may use Axis branding because they describe the future customer-facing design system, but this does not perform the technical BoostLab-to-AXIS rename.

## WPF Resource Application Model

Future implementation should apply resources in layers:

1. Register AXIS resources at the application/window level before component rendering.
2. Keep existing XAML control names and event handlers stable.
3. Use helper functions to create brushes, thickness values, corner radii, text blocks, badges, and component styles for PowerShell-created controls.
4. Replace scattered hardcoded colors and layout values incrementally.
5. Prefer reusable style factories for generated controls such as tool cards, badges, result rows, and dialogs.
6. Avoid one-off style values inside every control.
7. Preserve existing event handlers, runtime binding, action dispatch, and async completion paths.
8. Avoid changing control logic while styling.

Practical model:

- XAML-declared controls consume `StaticResource` or `DynamicResource` entries where safe.
- PowerShell-created controls use resource lookup helpers, for example `Get-AxisBrush 'Axis.Brush.Surface.Card'`.
- Style factories return WPF `Style` objects or configured controls without touching runtime action logic.
- Result and diagnostic styling helpers receive presentation state only and must not reinterpret runtime success/failure semantics.

## Component Style Implementation Order

Recommended safe order:

### A. Token/resource foundation only

Create the resource registration layer and verify the app still loads without applying a broad redesign.

Why first: it gives future work a stable vocabulary and can be tested independently.

### B. Basic text/surface/button/card styles

Move shared text, panel, button, and card primitives onto AXIS resources.

Why second: these are visible everywhere and reduce duplicated hardcoded values.

### C. Stage navigation style

Apply current, hover, selected, complete, and needs-attention states to stage navigation.

Why third: navigation is important but behavior is simple and already centralized through `StageNavigationPanel`.

### D. Tool card style

Apply card surfaces, titles, descriptions, badges, actions, and availability states.

Why fourth: tool cards are core to the product, but generated controls and variable card heights make this higher risk than navigation.

### E. Result summary style

Introduce customer-facing result styling while preserving technical latest-result data.

Why fifth: this is where raw status and customer outcome language must be separated carefully.

### F. Diagnostics drawer style

Style technical details with diagnostics tokens while preserving copy and log behavior.

Why sixth: diagnostics are essential for support and should be preserved after customer summaries are stable.

### G. Confirmation dialog style

Apply dialog resources to action-plan and restart confirmations.

Why seventh: confirmation dialogs are safety-critical and should be touched only after shared resources are stable.

### H. First Guided Stage Workspace visual prototype

Implement the Phase 176E visual prototype using the token/resource foundation.

Why last: the prototype should consume tested resources instead of becoming another isolated hardcoded layout.

## First Prototype Resource Needs

The Phase 176E Guided Stage Workspace prototype will need resources for:

- App Shell surface: app background, panel background, divider borders, content margins
- Product Header: AXIS title text, subtitle text, mode/status chips, header surface
- Stage Navigation: default, hover, selected, completed, needs-attention, disabled, focus states
- Stage Screen: page title, stage description, section surfaces, progress summary
- Tool Card: default, hover, selected, running, completed, completed-with-notes, needs-attention, restart-needed, not-available, disabled
- Tool Detail Panel: raised surface, section titles, body text, requirement rows, detail links
- Action Button: primary, secondary, ghost, restart, high-risk, disabled, focused, pressed
- Risk Badge: system change, driver change, security-sensitive, restart required, download required, file cleanup, advanced, device-specific
- Result Summary: completed, completed with notes, needs attention, stopped, restart needed, waiting for confirmation, not available, skipped
- Diagnostics Drawer: background, border, monospace text, muted text, copy report button, dense rows
- Focus/hover/selected/running states: consistent brushes, borders, and text/icon treatment

## Runtime Safety Boundaries

Future token implementation must not:

- change Apply behavior
- change Default behavior
- change Restore behavior
- change action plans
- change confirmation requirements
- change verification logic
- change async execution
- change restart behavior
- change driver behavior
- change Defender behavior
- change cleanup behavior
- change installer behavior
- hide real failures
- remove diagnostics
- break Latest Result
- break copyable logs or reports
- break tool/action contracts
- weaken Ultimate execution strength
- reintroduce deleted tools

Design tokens are presentation infrastructure only.

## Feature Flag / Isolated Prototype Recommendation

The safest practical approach is a feature-flagged isolated prototype layout.

Recommendation:

- create the token/resource foundation first
- add an opt-in prototype route or internal visual mode for the AXIS Guided Stage Workspace
- keep existing stable BoostLab UI as the default until the prototype passes validation
- prevent prototype actions from running tools during the first visual implementation
- allow read-only metadata binding only after static/sample layout is stable
- do not duplicate or fork runtime action logic

This approach lets AXIS prototype work proceed without risking stable runtime behavior. Direct incremental migration should come later, once the resource layer and isolated prototype have proven reliable.

## Testing And Validation Plan For Implementation Phase

Future implementation phases must validate:

- no runtime behavior change
- full safe/static suite still passes
- UI loads without exceptions
- active tools still use the non-blocking execution path where currently required
- Latest Result still renders
- diagnostics remain available and copyable
- activity log copy still works
- stage/tool lists still map correctly from configuration
- action buttons still call the same runtime contracts
- confirmation dialogs still block or continue exactly as before
- no Apply actions run during tests
- no source/protected files are modified
- visual resources do not break PowerShell/WPF startup
- feature-flagged prototype cannot accidentally execute tools during the first visual slice

Docs-only phases do not need the full suite, but implementation phases should run the full existing safe/static validators unless the phase explicitly narrows validation.

## Accessibility Implementation Considerations

Implementation checks should include:

- contrast for primary, secondary, muted, disabled, status, risk, and diagnostics text
- visible keyboard focus rings on buttons, navigation, cards, dialogs, and diagnostics controls
- keyboard navigation order through header, stage navigation, cards, details, dialogs, and copy buttons
- readable font sizes at common Windows scaling levels
- icons plus text for status and risk indicators
- disabled states that remain readable and explain why an action is unavailable
- status meaning that does not rely on color alone
- Arabic/English future expansion without layout collapse
- text clipping prevention for long tool names, result messages, and Windows version labels
- high-DPI behavior with `UseLayoutRounding` and readable line heights
- no hover-only information required for critical decisions

## Localization Readiness

Future WPF resource planning should separate style resources from text resources.

Guidance:

- style tokens and component styles can use `Axis.` resource names
- customer-facing strings should later move into a separate text/copy model
- tool/script names remain English even in Arabic UI
- AXIS stays AXIS
- Arabic rendering remains the product-owner approved Arabic brand rendering from the design direction docs
- RTL support is a later layout and localization phase
- text expansion should be expected in cards, dialogs, and navigation
- do not implement localization in the token/resource foundation phase

## Third-Party Dependency Guidance

Future implementation should not add TypeUI, Figma, or UI framework dependencies by default.

Guidance:

- do not require external accounts or subscriptions
- avoid large WPF UI libraries initially
- use the current WPF/PowerShell structure first
- treat TypeUI, Figma, or other tools as optional planning aids later
- do not introduce a dependency merely to store colors, spacing, or basic styles
- any third-party dependency needs a later explicit approval phase

## Migration Risk List

| Risk | Mitigation strategy | Test/validation idea |
| --- | --- | --- |
| Hardcoded styles scattered through `MainWindow.xaml` and `MainWindow.ps1` | centralize tokens first, then replace values by component area | diff review for style-only changes and `git diff --check` |
| PowerShell/WPF style limitations | provide helper functions for generated controls, not XAML-only resources | run UI startup test and inspect generated cards |
| Layout regressions | change one region at a time and keep current control names stable | verify stage navigation, tool list, and right panel render |
| Scroll clipping | keep scroll viewers and min sizes intact until prototype-specific layout is validated | inspect long Windows/Installers/Graphics stages |
| Modal dialog regressions | migrate dialogs after base tokens are stable | run mocked/static dialog tests only, no Apply actions |
| Async UI responsiveness regressions | do not change dispatch, async state, or completion handling while styling | run existing async/static validators |
| Diagnostics rendering regressions | keep Latest Result and copy functions unchanged until diagnostics drawer exists | verify latest result and activity log copy behavior |
| Customer labels mixing with technical labels | define a mapping layer for presentation labels without changing raw result data | test raw status remains visible in diagnostics only |
| Focus/accessibility regressions | define focus resources early and verify tab order after style changes | keyboard navigation check |
| Color-only status meaning | require text labels and icons/structure for status and risk | visual review plus accessibility checklist |
| Feature flag complexity | isolate the prototype without duplicating runtime execution logic | verify prototype cannot execute tools |

## Non-Goals

This phase does not include:

- code changes
- UI implementation
- WPF resource files added
- component rewrite
- runtime behavior changes
- module behavior changes
- test behavior changes
- localization implementation
- technical BoostLab-to-AXIS rename
- external packaging/source decoupling
- logo design
- TypeUI integration
- Figma integration
- third-party UI framework adoption

## Next Phases

Recommended roadmap:

- Phase 176G: Implement AXIS WPF token/resource foundation
- Phase 176H: First Guided Stage Workspace visual prototype
- Phase 176I: Customer-facing copy/microcopy model
- Phase 176J: Guided flow content model per stage/tool
- Later: technical BoostLab-to-AXIS rename
- Later: localization implementation

## Validation

Validation for this phase should remain docs-focused:

- `git diff --check`
- `git status --short`

Full runtime/static suite is not required for this single documentation-only design artifact.
