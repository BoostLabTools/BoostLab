# Phase 176C - AXIS Design System Foundation Tokens

Date: 2026-06-28
Scope: Design-token direction only

## Purpose

This document defines foundational design-token direction for AXIS before visual implementation.

It provides a shared language for future UI work: colors, typography, spacing, radius, borders, surfaces, elevation, status states, risk indicators, layout density, component states, and accessibility principles.

This is not UI implementation. This is not final logo or brand identity. This is not localization implementation. It is a foundation for consistent future UI design and later WPF resource planning.

All values in this document are provisional foundation values until a visual prototype is approved.

## Token Philosophy

AXIS design tokens should follow these principles:

- semantic tokens over one-off values
- dark-first system
- clarity over decoration
- premium technical restraint
- status clarity without fear
- risk visibility without alarmism
- accessible contrast
- scalable for English and Arabic later
- WPF-friendly implementation later
- stable enough for guided setup and denser dashboard modes

Tokens should make the UI easier to reason about. A future component should ask for `Color.Status.Completed.Background`, not a hardcoded green value scattered across screens.

## Color System

The first AXIS color system is dark-only. It should use a dark graphite/near-black base, controlled blue/cyan technical accents, and restrained status colors.

Avoid heavy purple, neon overload, rainbow RGB, hacker-green dominance, and noisy color effects. Contrast and hierarchy matter more than spectacle.

### Base And Background Colors

| Token | Proposed value | Role |
| --- | --- | --- |
| `Color.Background.App` | `#090D12` | Main app background |
| `Color.Background.Panel` | `#0D131A` | Sidebar, bottom rail, large panels |
| `Color.Background.Deep` | `#05080C` | Deepest background zones |
| `Color.Background.Inset` | `#111923` | Inset areas such as diagnostics containers |

### Surface And Card Colors

| Token | Proposed value | Role |
| --- | --- | --- |
| `Color.Surface.Base` | `#121A24` | Default card and tool surface |
| `Color.Surface.Raised` | `#172231` | Raised card, selected grouped surface |
| `Color.Surface.Elevated` | `#1B2838` | Dialogs, popovers, modal content |
| `Color.Surface.Interactive` | `#1A2634` | Hoverable card/control surface |
| `Color.Surface.InteractiveHover` | `#223246` | Hover state |
| `Color.Surface.InteractivePressed` | `#101822` | Pressed state |

### Border And Divider Colors

| Token | Proposed value | Role |
| --- | --- | --- |
| `Color.Border.Subtle` | `#243244` | Default card and panel border |
| `Color.Border.Default` | `#314154` | Control border |
| `Color.Border.Strong` | `#4A5F78` | Active/selected border |
| `Color.Border.Divider` | `#1F2A38` | Quiet separators |
| `Color.Border.Focus` | `#55B7FF` | Focus and keyboard highlight |

### Text Colors

| Token | Proposed value | Role |
| --- | --- | --- |
| `Color.Text.Primary` | `#F2F7FC` | Primary text |
| `Color.Text.Secondary` | `#B8C6D6` | Body and secondary labels |
| `Color.Text.Muted` | `#7F8EA3` | Captions, metadata, helper text |
| `Color.Text.Disabled` | `#546172` | Disabled text |
| `Color.Text.Inverse` | `#061019` | Text on bright accent fills |
| `Color.Text.Diagnostics` | `#C7D3E2` | Technical/log text |

### Accent Colors

| Token | Proposed value | Role |
| --- | --- | --- |
| `Color.Accent.Primary` | `#2FA8FF` | Primary action, active navigation, important highlights |
| `Color.Accent.Hover` | `#55B7FF` | Primary hover |
| `Color.Accent.Pressed` | `#1688D8` | Primary pressed |
| `Color.Accent.Subtle` | `#14304A` | Accent-tinted quiet background |
| `Color.Accent.Text` | `#8FD2FF` | Accent text on dark surfaces |

### Focus, Selection, And Overlay

| Token | Proposed value | Role |
| --- | --- | --- |
| `Color.Focus.Ring` | `#67C3FF` | Keyboard focus ring |
| `Color.Focus.Inner` | `#0A1420` | Inner contrast around focus ring if needed |
| `Color.Selection.Background` | `#123A58` | Selected rows/cards |
| `Color.Selection.Border` | `#2FA8FF` | Selected border |
| `Color.Overlay.Modal` | `#020509CC` | Modal scrim |
| `Color.Overlay.Subtle` | `#02050988` | Drawer/sheet scrim |

## Status And Result Color Tokens

Customer-facing states should not use raw `Success`, `Warning`, or `Error` as the primary labels. Technical diagnostics can still carry raw status fields later.

| Customer state | Semantic token | Color role | Icon role suggestion | Tone guidance |
| --- | --- | --- | --- | --- |
| Completed | `Color.Status.Completed` | calm green, `#4CCB7A` | check circle | Confident and quiet |
| Completed with notes | `Color.Status.CompletedWithNotes` | blue-green, `#5BC8D6` | check plus note | Informational, not scary |
| Needs attention | `Color.Status.NeedsAttention` | amber, `#F4B84A` | attention diamond | Review needed, not panic |
| Stopped | `Color.Status.Stopped` | muted red, `#F16B6B` | stop circle | Workflow did not continue |
| Restart needed | `Color.Status.RestartNeeded` | controlled blue, `#6EA8FF` | restart arrow | Predictable checkpoint |
| Waiting for confirmation | `Color.Status.WaitingForConfirmation` | violet-blue, `#9AA7FF` | pause/user prompt | AXIS is paused safely |
| Not available | `Color.Status.NotAvailable` | neutral gray, `#8A96A8` | circle slash | Not applicable, not failure |
| Skipped because not needed | `Color.Status.SkippedNotNeeded` | slate, `#7EA0B8` | skip/forward | Checked and avoided work |
| Running | `Color.Status.Running` | accent blue, `#2FA8FF` | activity/progress | Active and stable |

Suggested supporting tokens:

- `Color.Status.*.Background`
- `Color.Status.*.Border`
- `Color.Status.*.Text`
- `Color.Status.*.Icon`

Status color should not be the only signal. Every state needs text and an icon or structural cue.

## Risk Color Tokens

Risk indicators should be visible, calm, and specific. Do not make every risk red.

| Risk | Semantic token | Suggested color family | Usage guidance | What not to do |
| --- | --- | --- | --- | --- |
| System change | `Color.Risk.SystemChange` | blue, `#5EA8FF` | Settings, policy, services, system behavior | Do not make routine settings feel dangerous |
| Driver change | `Color.Risk.DriverChange` | cyan, `#45D5E8` | Driver or graphics-related work | Do not use hype or racing visuals |
| Security-sensitive | `Color.Risk.SecuritySensitive` | amber, `#F2C14E` | Security, encryption, Defender-sensitive actions | Do not make it casual or frightening |
| Restart required | `Color.Risk.RestartRequired` | violet-blue, `#9AA7FF` | Restart before or after action | Do not surprise the user |
| Download required | `Color.Risk.DownloadRequired` | azure, `#58BDF7` | Internet or artifact need | Do not hide network dependency |
| File cleanup | `Color.Risk.FileCleanup` | orange, `#FF9F4A` | Cleanup/deletion scope | Do not imply broad deletion without scope |
| Advanced | `Color.Risk.Advanced` | indigo, `#8E9BFF` | Deeper technical behavior | Do not overload main UI with internals |
| Device-specific | `Color.Risk.DeviceSpecific` | teal, `#4EC9B0` | Hardware, edition, or state-dependent | Do not treat not-applicable as failure |

Suggested supporting tokens:

- `Color.Risk.*.Background`
- `Color.Risk.*.Border`
- `Color.Risk.*.Text`
- `Color.Risk.*.Icon`

Risk badges should be compact and text-labeled. They should not use flashing, glow-heavy, or aggressive styling.

## Typography Foundation

AXIS typography should feel like a clear technical Windows utility: readable, structured, and not decorative.

Font strategy should be WPF-friendly:

- English/UI: Segoe UI Variable if available, otherwise Segoe UI
- Arabic later: Segoe UI with Arabic-capable system fallback
- Diagnostics: Cascadia Mono if available, otherwise Consolas

Text should remain readable at common Windows desktop sizes. Avoid condensed, futuristic, or ornamental fonts.

| Type role | Token | Size | Weight | Line height | Usage |
| --- | --- | ---: | ---: | ---: | --- |
| Display / product title | `Type.Display` | 32 | 650 | 40 | AXIS title, high-level welcome |
| Page title | `Type.PageTitle` | 24 | 650 | 32 | Screen title |
| Section title | `Type.SectionTitle` | 18 | 600 | 26 | Stage or grouped section |
| Card title | `Type.CardTitle` | 15 | 600 | 22 | Tool card title |
| Body | `Type.Body` | 14 | 400 | 21 | Main copy |
| Small body | `Type.BodySmall` | 13 | 400 | 19 | Secondary copy |
| Caption | `Type.Caption` | 12 | 400 | 16 | Helper text, badges |
| Micro/metadata | `Type.Micro` | 11 | 500 | 14 | Metadata, compact rows |
| Monospace diagnostic | `Type.DiagnosticsMono` | 12 | 400 | 18 | Logs, hashes, raw status |

Future Arabic text may require line-height adjustments. Typography tokens should allow language-specific overrides later.

## Spacing System

Spacing should support dense technical content without making the main customer flow feel cramped.

| Token | Value | Usage |
| --- | ---: | --- |
| `Space.2` | 2 | Tight alignment, hairline offsets |
| `Space.4` | 4 | Icon/text gaps, compact rows |
| `Space.6` | 6 | Dense control gaps |
| `Space.8` | 8 | Default small gap |
| `Space.12` | 12 | Card internal clusters |
| `Space.16` | 16 | Standard padding and control groups |
| `Space.20` | 20 | Guided card padding |
| `Space.24` | 24 | Section spacing |
| `Space.32` | 32 | Major screen spacing |
| `Space.40` | 40 | Guided flow group separation |
| `Space.48` | 48 | Large hero/welcome spacing |

Usage guidance:

- guided flow screens can use larger spacing
- dashboard mode later can be denser
- cards should use consistent padding
- controls should avoid cramped click targets
- diagnostics can be dense but should remain organized

## Radius System

AXIS should feel modern but not overly rounded. The shape language should be clean, technical, and controlled.

| Token | Value | Usage |
| --- | ---: | --- |
| `Radius.None` | 0 | Dividers, flat edges |
| `Radius.Small` | 4 | Badges, compact inputs |
| `Radius.Medium` | 6 | Buttons, smaller cards |
| `Radius.Large` | 8 | Primary cards, panels |
| `Radius.XLarge` | 12 | Dialogs, large guided surfaces |
| `Radius.Pill` | 999 | Pills, status badges only |

Avoid overly soft card stacks. Cards and dialogs should feel premium and precise.

## Border And Divider System

Borders should define structure without making the app feel boxed-in.

| Token | Value | Usage |
| --- | ---: | --- |
| `Border.Width.Hairline` | 1 | Dividers, subtle card boundaries |
| `Border.Width.Default` | 1 | Controls and cards |
| `Border.Width.Emphasis` | 2 | Focus, selected, important status |

Additional token patterns:

- `Color.Border.Status.*`
- `Color.Border.Risk.*`
- `Color.Border.Active`
- `Color.Border.Disabled`

Usage guidance:

- use subtle borders for cards
- use stronger borders for active or selected states
- risk/status left rails can help scannability
- avoid heavy outlines everywhere

## Elevation And Shadow System

Dark-theme elevation should be careful. Surfaces should separate mostly by color, border, and layout rather than heavy shadows.

| Token | Suggested value | Usage |
| --- | --- | --- |
| `Elevation.None` | none | Flat panels |
| `Elevation.Low` | `0 1 2 #00000040` | Hover card, small popover |
| `Elevation.Medium` | `0 8 20 #0000004D` | Drawer, raised surface |
| `Elevation.High` | `0 18 44 #00000066` | Modal/dialog |
| `Overlay.Scrim` | `#020509CC` | Modal overlay |

WPF implementation may translate these into available shadow/effect resources later.

## Motion And Transition Principles

Future motion should be:

- subtle
- fast
- purposeful
- reduced-motion friendly
- tied to state change or progress

Do not use flashy animations, gaming-style excessive motion, constant pulsing, or decorative movement.

Progress should feel active but stable. Long-running operations should not feel frozen, but the main surface should remain calm.

This phase does not implement motion.

## Iconography Direction

Iconography should prioritize Windows-native clarity.

Direction:

- simple line icons are preferred
- filled accents can be used for strong status moments
- status icons must be distinguishable without relying only on color
- risk icons should be calm and specific
- avoid complex illustrated icon sets for now
- avoid aggressive gaming iconography

Suggested roles:

- status: check, note, attention, stop, restart, pause, skip, running
- risk: system, driver, shield, restart, download, cleanup, advanced, device
- actions: continue, back, details, copy, run, confirm, cancel

## Layout Grid And Density

AXIS is desktop-first and WPF-based. Future design should consider minimum comfortable window sizes later.

Guided mode should use clear stage and step hierarchy. Dashboard mode later can be denser.

Diagnostics can be dense but organized, with copyable technical detail.

| Token | Provisional value | Usage |
| --- | ---: | --- |
| `Layout.Sidebar.Width` | 260 | Stage/navigation rail |
| `Layout.Panel.Width` | 360 | Details drawer or secondary panel |
| `Layout.Content.MaxWidth` | 1120 | Guided content container |
| `Layout.Card.Padding` | 20 | Default guided card padding |
| `Layout.Card.PaddingDense` | 16 | Dashboard/tool list cards |
| `Layout.Stage.Gap` | 24 | Gap between stage sections |
| `Layout.ToolList.Gap` | 12 | Gap between tool cards/rows |
| `Layout.Diagnostics.Width` | 420 | Technical details drawer |
| `Layout.BottomBar.Height` | 88 | Status/log/action rail concept |

These values are provisional and should be validated in a WPF prototype.

## Component State Tokens

Future components should share consistent state tokens.

Common states:

- `State.Default`
- `State.Hover`
- `State.Pressed`
- `State.Focused`
- `State.Selected`
- `State.Disabled`
- `State.Running`
- `State.Completed`
- `State.NeedsAttention`
- `State.Blocked`
- `State.RestartNeeded`

Applies to:

- buttons
- cards
- navigation items
- badges
- dialogs
- progress rows

State changes should update surface, border, text, icon, and focus treatment consistently. Do not rely on color alone.

## Button Hierarchy

Button hierarchy should make the next safe action obvious without hiding alternatives.

| Button role | Token pattern | Direction |
| --- | --- | --- |
| Primary action | `Button.Primary.*` | Filled accent, highest emphasis, one primary per context |
| Secondary action | `Button.Secondary.*` | Outlined or raised neutral |
| Tertiary/ghost action | `Button.Ghost.*` | Low emphasis, details/back/minor actions |
| Destructive/high-risk action | `Button.HighRisk.*` | Calm risk styling, confirmation required |
| Disabled state | `Button.Disabled.*` | Clearly unavailable, readable reason nearby |
| Restart action | `Button.Restart.*` | Distinct checkpoint action, not hidden as generic primary |

High-risk buttons should not be loud red by default. They should show risk through label, badge, context, and confirmation.

This phase does not implement actual buttons.

## Diagnostics Styling Direction

The customer-facing summary should use calm, clear cards.

Technical diagnostics should use a structured panel with:

- monospace logs where appropriate
- compact metadata rows
- copy technical report action
- raw status
- verification details
- command status
- hashes
- source/provenance when appropriate

Diagnostics must not dominate the main customer screen. They must remain available, complete, and copyable for troubleshooting.

Suggested tokens:

- `Color.Diagnostics.Background` = `#0A1017`
- `Color.Diagnostics.Border` = `#263445`
- `Color.Diagnostics.Text` = `#C7D3E2`
- `Color.Diagnostics.Muted` = `#7F8EA3`
- `Type.DiagnosticsMono`
- `Layout.Diagnostics.Width`

## Accessibility Requirements

AXIS design tokens must support:

- sufficient contrast for text and controls
- visible keyboard focus
- no color-only status or risk communication
- readable text sizes
- clear disabled states
- sufficient target size for pointer use
- status and risk labels with text
- distinguishable important actions
- future Arabic and English layout support
- reduced-motion friendly behavior

Accessibility should be part of token validation, not a later patch.

## Token Implementation Notes For Later WPF

Later implementation should centralize tokens as WPF resources and styles.

Guidance:

- avoid scattered hardcoded colors and sizes
- create semantic resource names before broad UI changes
- map component styles to tokens
- keep runtime safety and tests as priority
- do not add large UI frameworks unless later approved
- design tokens must not change runtime behavior
- keep diagnostics and customer layer visually distinct
- plan for English/Arabic typography adjustments later

This phase does not add WPF resources.

## Non-Goals

This phase does not include:

- code changes
- WPF resource implementation
- UI redesign implementation
- component rewrite
- logo design
- localization implementation
- technical rename
- packaging/source decoupling
- TypeUI integration
- Figma integration

## Next Phases

Recommended roadmap:

- Phase 176D: Component inventory and component specs
- Phase 176E: First redesigned screen prototype
- Phase 176F: Customer-facing copy and microcopy model
- Phase 176G: WPF token/resource implementation plan
- Later: technical BoostLab-to-AXIS rename
- Later: localization implementation

## Validation

Validation for this phase should remain docs-focused:

- `git diff --check`
- `git status --short`

Full runtime/static suite is not required for a single documentation-only design-token artifact.
