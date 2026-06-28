# Phase 176D - AXIS Component Inventory and Specs

Date: 2026-06-28
Scope: Component inventory and component specifications only

## Purpose

This document defines the future AXIS UI component inventory and component specifications before visual implementation begins.

It translates the Phase 176A UX and brand direction, the Phase 176B screen-flow model, and the Phase 176C foundation tokens into a practical component model for future WPF work.

This phase is document-only. It is not implementation, final styling, a code rewrite, a WPF resource change, or a technical rename from BoostLab to AXIS. It is a blueprint for later component design and migration work.

## Component Hierarchy

AXIS should be built around a guided-first component hierarchy:

```text
App Shell
  Product Header / Top Bar
  Stage Navigation
  Guided Flow Container
    Stage Screen
      Tool / Step Card
      Tool Detail Panel
      Action Area
      Progress Area
      Result Summary
      Diagnostics Drawer
  Confirmation Dialog
  Restart Checkpoint
  Completion Summary
  Dashboard Mode later
  Settings / Language later
```

The App Shell provides the stable frame. The Product Header identifies AXIS and exposes future global controls. Stage Navigation shows where the user is in the guided setup journey. The Guided Flow Container owns the main customer journey, with Stage Screens grouping Tool / Step Cards and Tool Detail Panels.

Action, progress, result, confirmation, restart, and diagnostics components appear as needed inside that journey. Dashboard Mode and Settings / Language are later extensions, not first implementation requirements.

## App Shell

Purpose: provide the stable customer-facing frame for AXIS.

Customer-facing role:

- make the app feel like one guided setup workspace
- keep navigation, current context, and primary content predictable
- show AXIS as the product brand
- preserve access to diagnostics without making diagnostics the main layer

Expected layout regions:

- top Product Header / Top Bar
- left or side Stage Navigation
- central Guided Flow Container
- optional right-side Tool Detail Panel or Diagnostics Drawer
- modal overlay region for confirmations
- optional lower activity/status region if needed later

Dark background and surface behavior:

- use `Color.Background.App` for the overall app frame
- use `Color.Background.Panel` for navigation and persistent side regions
- use `Color.Surface.Base`, `Color.Surface.Raised`, and `Color.Surface.Elevated` for cards, selected states, and overlays
- keep elevation restrained; use border, contrast, and hierarchy before heavy shadows

Brand placement:

- AXIS should appear in the Product Header as the main product name
- the Arabic rendering, Ø§ÙƒØ³ÙŠØ³, belongs in language or brand contexts later
- BoostLab should not appear in normal customer UI after the customer-facing rename is implemented

What should not be shown in the shell:

- internal repository names
- internal phase names
- raw script dumps
- raw hash/provenance details
- raw `Success`, `Warning`, or `Error` as the primary customer layer
- dense logs unless diagnostics are opened

## Product Header / Top Bar

Purpose: identify AXIS and provide global context.

The header should include:

- AXIS product name
- optional subtitle or current journey label
- optional current global status area
- future app mode indicator such as Guided Setup or Dashboard
- future language switcher
- future settings entry

Usage rules:

- use `Type.PageTitle` or `Type.SectionTitle` depending on header density
- use `Color.Text.Primary` for the AXIS name and `Color.Text.Secondary` for supporting context
- avoid internal repository/project terminology in customer UI
- keep the header calm and functional rather than decorative

The header should not expose technical debug state by default. Technical status can live in diagnostics or a compact support mode later.

## Guided Flow Container

Purpose: make setup feel step-by-step instead of like a raw tool list.

The container should show:

- current step or stage
- next recommended step
- stage progress
- recommended path
- concise context for why the current step matters
- available details without overwhelming the user

Behavior:

- one primary next action should be visually obvious
- optional or advanced actions should be secondary
- diagnostics should be reachable but hidden by default
- guided setup should feel finite and structured

Difference from Dashboard Mode:

- Guided Flow Container leads the customer through a recommended sequence
- Dashboard Mode later allows intentional free-control after setup is complete
- guided mode should reduce decision overload
- dashboard mode may be denser and more direct

Relevant tokens:

- `Layout.Content.MaxWidth`
- `Layout.Stage.Gap`
- `Space.24`, `Space.32`, and `Space.40`
- `Color.Background.App`
- `Color.Surface.Base`
- `Type.PageTitle`, `Type.Body`, and `Type.BodySmall`

## Stage Navigation

Purpose: show where the user is in the setup journey.

Behavior:

- list the major setup stages
- show current, complete, available, and locked states
- keep stage names customer-friendly
- show calm risk or attention indicators when a stage needs review
- never rely on color alone for status

Possible future customer-facing stage names:

- Prepare
- Setup
- Windows
- Apps
- Graphics
- Performance
- Cleanup
- Finish

This phase does not rename runtime stages, configuration keys, modules, tests, or tool ids.

Stage states:

- Current: the stage currently open in the guided journey
- Complete: stage finished without unresolved required action
- Complete with notes: stage finished but contains useful notes
- Needs attention: stage contains a blocker or review item
- Available: stage can be opened
- Locked: stage is intentionally unavailable until an earlier requirement is complete
- Skipped because not needed: stage was checked and avoided where appropriate

Risk and attention behavior:

- use small text-labeled indicators
- avoid making every risk red
- show the reason in hover/details or in the stage summary
- keep the main navigation scannable

Relevant tokens:

- `Color.Background.Panel`
- `Color.Selection.Background`
- `Color.Selection.Border`
- `Color.Border.Focus`
- `Type.BodySmall`
- `State.Default`, `State.Hover`, `State.Selected`, `State.Disabled`, and `State.NeedsAttention`

## Stage Screen

Purpose: group related customer-facing work into a readable setup section.

The Stage Screen should show:

- customer-friendly stage title
- short stage description
- recommended tools or steps
- stage progress
- stage notes
- stage-level requirements
- current recommended next action
- link or button to diagnostics

Customer-facing information:

- what the stage is for
- what kind of changes may happen
- what the user should do next
- whether anything is blocked, complete, or waiting

Hidden by default:

- raw command output
- raw verification payloads
- hashes and provenance
- internal tool ids
- source names

Relevant tokens:

- `Type.PageTitle`
- `Type.SectionTitle`
- `Color.Text.Primary`
- `Color.Text.Secondary`
- `Space.24`, `Space.32`
- `Layout.ToolList.Gap`

## Tool / Step Card

Purpose: present one actionable setup step in a compact, customer-friendly form.

Future card structure:

- customer-friendly title
- original English tool/script name where needed
- short purpose
- requirements indicators
- risk indicators
- estimated time if known
- restart indicator
- download indicator
- admin indicator
- security-sensitive indicator
- driver-change indicator
- file-cleanup indicator
- current state
- primary action
- secondary details action
- notes count if applicable

Card states:

- Default
- Hover
- Selected
- Running
- Completed
- Completed with notes
- Needs attention
- Stopped
- Restart needed
- Not available
- Skipped because not needed
- Disabled

State behavior:

- Default: normal available card with concise purpose
- Hover: subtle surface lift or border change
- Selected: clear border and background treatment
- Running: stable active indicator and disabled conflicting actions
- Completed: quiet completed state with next-step support
- Completed with notes: informational notes indicator, not alarming
- Needs attention: amber attention treatment with a specific reason
- Stopped: workflow did not continue; show a next safe option
- Restart needed: show restart checkpoint status and next action
- Not available: explain why the step is not applicable
- Skipped because not needed: reassure that AXIS checked and avoided unnecessary work
- Disabled: readable disabled state with reason available

Relevant tokens:

- `Color.Surface.Base`
- `Color.Surface.Interactive`
- `Color.Surface.InteractiveHover`
- `Color.Border.Subtle`
- `Color.Border.Strong`
- `Color.Status.*`
- `Color.Risk.*`
- `Type.CardTitle`
- `Type.BodySmall`
- `Radius.Large`
- `Layout.Card.Padding`

## Tool Detail Panel

Purpose: explain one step before action and hold richer detail for technical steps.

The panel should show:

- expanded customer explanation
- what this step changes
- before-you-start notes
- requirements
- risk explanation
- available action buttons
- expected outcome
- diagnostics drawer link
- product-owner controlled content per tool

Content model:

- simple tools can use short explanations and a small number of controls
- technical tools can use more detailed sections
- final customer-facing content is decided later per stage/tool by the product owner
- original English tool/script names may remain where clarity or support needs require them

Hidden by default:

- raw command lines
- source/provenance fields
- hashes
- verbose logs
- developer-only policy names

Relevant tokens:

- `Layout.Panel.Width`
- `Color.Surface.Raised`
- `Color.Text.Primary`
- `Color.Text.Secondary`
- `Type.SectionTitle`
- `Type.Body`
- `Space.16`, `Space.20`, `Space.24`

## Action Area And Buttons

Purpose: make available actions clear, limited, and safe.

Button hierarchy:

| Button role | Purpose | Tone | Token categories | Accessibility |
| --- | --- | --- | --- | --- |
| Primary action | Continue, run, or apply the recommended current action | confident and direct | `Button.Primary.*`, `Color.Accent.*`, `Type.BodySmall`, `Radius.Medium` | one clear default action, keyboard focus visible |
| Secondary action | Alternate supported action or review path | steady and lower emphasis | `Button.Secondary.*`, `Color.Surface.Interactive`, `Color.Border.Default` | readable label and focus state |
| Tertiary/ghost action | Details, back, copy, minor navigation | quiet | `Button.Ghost.*`, `Color.Text.Secondary` | not color-only, adequate target size |
| Restart action | Start or acknowledge a restart checkpoint | specific and predictable | `Button.Restart.*`, `Color.Status.RestartNeeded`, `Color.Risk.RestartRequired` | explicit label, no surprise restart |
| High-risk/destructive action | Driver, security, cleanup, or broad system changes | calm and serious | `Button.HighRisk.*`, relevant `Color.Risk.*` tokens | confirmation required and cancel available |
| Disabled/unavailable action | Show action exists but is unavailable | clear and non-punitive | `Button.Disabled.*`, `Color.Text.Disabled` | reason available nearby or in tooltip/details |

Button states:

- Default
- Hover
- Pressed
- Focused
- Disabled
- Running
- Waiting for confirmation

Rules:

- do not implement actual buttons in this phase
- avoid red as the default high-risk treatment
- use icon plus text where helpful
- disabled actions need an explanation
- high-risk actions need confirmation before execution

## Risk Badges

Purpose: explain impact without overwhelming or frightening the customer.

| Badge | Customer meaning | Display behavior | Tone |
| --- | --- | --- | --- |
| System change | AXIS may change Windows settings, policies, services, or behavior | text label with system/settings icon | controlled and factual |
| Driver change | AXIS may affect driver setup, graphics behavior, or driver-related tools | prominent on graphics/driver steps | precise and performance-aware |
| Security-sensitive | AXIS may touch security, encryption, Defender, or protection state | visible before action and in confirmation | careful and specific |
| Restart required | Restart is needed to finish or continue safely | show before action and in result | predictable |
| Download required | Internet or approved artifact access may be needed | show before action and in requirements | practical |
| File cleanup | Cleanup may remove scoped temporary/unwanted files | show scope in details | careful and concrete |
| Advanced | Step affects deeper technical behavior | compact badge with details available | confident and measured |
| Device-specific | Availability depends on hardware, edition, or current state | show on unavailable/skipped states | normal and non-punitive |

Rules:

- include text labels, not color only
- avoid making every risk red
- do not use flashing, heavy glow, or fear language
- use the `Color.Risk.*` token family from Phase 176C
- give the user the actual reason when a badge affects availability or confirmation

## Confirmation Dialog

Purpose: pause before meaningful actions and clearly explain what will happen.

Confirmation types:

| Type | Purpose | Customer-facing tone | Technical details handling | Required actions | Cancel/decline behavior |
| --- | --- | --- | --- | --- | --- |
| Normal confirmation | Confirm limited system or settings changes | short, direct, calm | details link can show action plan | confirm or cancel | no changes made if declined |
| High-risk confirmation | Confirm driver, security, cleanup, or broad system action | serious without being scary | action plan and diagnostics available | explicit confirm required | stop or return to previous safe state |
| Restart confirmation | Confirm restart timing or restart-dependent continuation | predictable checkpoint | restart reason in details/logs | user chooses restart/continue path where supported | AXIS pauses or marks restart needed |
| Manual checkpoint confirmation | Confirm the user completed an external/manual step | clear and instructional | manual step record available | user confirms completion | AXIS does not continue |
| Unavailable/not-applicable message | Explain why a step cannot or should not run | normal, non-punitive | device/requirement details in diagnostics | acknowledge or open details | no failure framing unless truly blocked |
| User-decline path | Record intentional stop/skip | respectful and clear | status can record declined/cancelled | continue to next safe option if available | no hidden execution |

Graphics restart checkpoint pattern:

- the prompt must be clear
- the UI must not freeze
- there must be no surprise restart
- action continues only after confirmation
- decline leaves the user in a known safe state
- diagnostics can record the confirmation result

Relevant tokens:

- `Color.Surface.Elevated`
- `Color.Overlay.Modal`
- `Elevation.High`
- `Radius.XLarge`
- `Type.SectionTitle`
- `Button.Primary.*`, `Button.Secondary.*`, and `Button.Restart.*`

## Running / Progress State

Purpose: show active work without making the app feel frozen or flooding the main view with logs.

The progress component should show:

- current action
- customer-friendly progress summary
- current phase
- safe waiting state where applicable
- background operation explanation
- details/diagnostics access
- cancellation only if a future implementation safely supports it

Progress states:

- Preparing
- Waiting for input
- Running
- Finalizing
- Restart pending
- Completed

Main-view rules:

- do not show raw log flood by default
- do not rely on a spinner alone for long work
- show when AXIS is checking, applying, downloading, waiting, finalizing, or complete
- diagnostics can show raw streams, command output, and structured details

Relevant tokens:

- `Color.Status.Running`
- `Color.Status.WaitingForConfirmation`
- `Color.Status.RestartNeeded`
- `Type.BodySmall`
- `Space.12`, `Space.16`
- `State.Running`

## Result Summary

Purpose: explain outcomes in customer language and direct the next action.

Customer-facing result states:

| Result | Customer meaning | Tone | Icon suggestion | Color token role | Next action | Diagnostics |
| --- | --- | --- | --- | --- | --- | --- |
| Completed | Step finished as expected | confident and quiet | check circle | `Color.Status.Completed` | continue | available |
| Completed with notes | Step finished and has useful notes | informational | check plus note | `Color.Status.CompletedWithNotes` | review notes or continue | available |
| Needs attention | Customer should review something before continuing | focused, not panic | attention diamond | `Color.Status.NeedsAttention` | review and decide | available |
| Stopped | Workflow did not continue | clear and neutral | stop circle | `Color.Status.Stopped` | retry, go back, or continue if safe | available |
| Restart needed | Restart is required to finish or continue | predictable | restart arrow | `Color.Status.RestartNeeded` | open restart checkpoint | available |
| Waiting for your confirmation | AXIS is paused until the user decides | reassuring | pause/user prompt | `Color.Status.WaitingForConfirmation` | confirm or decline | available |
| Not available on this device | Step is not applicable or cannot run here | normal | circle slash | `Color.Status.NotAvailable` | continue or read why | available |
| Skipped because not needed | AXIS checked and avoided unnecessary work | reassuring | skip/forward | `Color.Status.SkippedNotNeeded` | continue | available |

Rules:

- do not use raw `Success`, `Warning`, or `Error` as the main customer component labels
- raw status remains available in diagnostics
- every result needs text, not color only
- the next recommended action should be clear

## Diagnostics Drawer / Technical Details

Purpose: keep technical evidence available and copyable without making it the main customer layer.

Behavior:

- hidden by default
- openable from stage, tool, progress, result, and confirmation contexts
- structured rather than a single unfiltered text dump
- copy technical report action available
- raw status, verification status, command status, hashes, source/provenance, and logs allowed here

Sections:

- Summary
- Technical status
- Verification
- Operations
- Warnings/notes
- Errors if any
- Logs
- Copy report

Allowed diagnostics content:

- raw result status
- verification status
- command status
- detailed logs
- hashes
- source and provenance details
- structured errors
- operation metadata

Rules:

- diagnostics must not hide real failures
- diagnostics must remain copyable for troubleshooting
- diagnostics should not dominate normal successful flows
- diagnostics are for support, technicians, power users, and development evidence

Relevant tokens:

- `Color.Diagnostics.Background`
- `Color.Diagnostics.Border`
- `Color.Diagnostics.Text`
- `Color.Diagnostics.Muted`
- `Type.DiagnosticsMono`
- `Layout.Diagnostics.Width`
- `Color.Background.Inset`

## Restart Checkpoint Component

Purpose: make restart timing explicit and safe.

When it appears:

- a step requires restart to finish
- a step can continue only after user confirmation
- a manual restart is recommended
- a future approved workflow needs post-restart continuation

Restart required vs restart ready:

- Restart required means the result is not fully complete until a restart happens.
- Restart ready means AXIS has finished the current work and the user can choose when to restart or continue according to the supported workflow.

User confirmation:

- required before any immediate restart action
- required before continuing from a manual restart checkpoint
- must explain what happens next

Decline behavior:

- no surprise restart
- AXIS records that the user declined or postponed
- result should remain Restart needed or Stopped, depending on the tool workflow
- next safe option should be shown

After restart:

- future resume behavior must depend on approved reboot/recovery policy
- if resume is unsupported, AXIS should tell the user what to do manually
- completion should not pretend a restart-dependent step is fully finished before restart

Relevant tokens:

- `Color.Status.RestartNeeded`
- `Color.Risk.RestartRequired`
- `Button.Restart.*`
- `Type.SectionTitle`
- `Radius.XLarge`

## Completion Summary

Purpose: close the guided setup journey with a clear final state.

The component should show:

- final setup result
- what was completed
- what completed with notes
- what needs attention
- restart status
- recommended next step
- future dashboard entry
- copy report option

Customer-facing behavior:

- make completion feel oriented and controlled
- avoid raw logs as the main experience
- keep unresolved notes visible but calm
- offer diagnostics/report copy for support

Relevant tokens:

- `Color.Status.Completed`
- `Color.Status.CompletedWithNotes`
- `Color.Status.NeedsAttention`
- `Color.Status.RestartNeeded`
- `Type.PageTitle`
- `Type.Body`
- `Layout.Content.MaxWidth`

## Dashboard Mode Later

Dashboard Mode is a later/free-control experience after guided setup.

Future dashboard components:

- system overview
- recent results/history
- maintenance actions
- intentional rerun controls
- recommended actions
- advanced actions
- diagnostics access
- history/detail panels

Rules:

- not part of first implementation unless later approved
- should not force a repeat of guided setup
- should separate recommended and advanced actions
- should preserve confirmations for impactful actions
- should not become an ungrouped script dump

## Settings / Language Later

Future settings components:

- language selection: English / Arabic
- AXIS brand handling
- Arabic rendering: Ø§ÙƒØ³ÙŠØ³
- diagnostics/developer options later
- possible appearance/accessibility controls later

Rules:

- AXIS stays AXIS
- tool and script names remain English even in Arabic UI
- Arabic UI should read naturally, not literally
- English UI should be concise and polished
- product owner approves final customer-facing copy
- do not implement localization in this phase

## Component-To-Token Mapping

| Component | Color tokens | Typography tokens | Spacing tokens | Radius tokens | Border tokens | Elevation tokens | State tokens |
| --- | --- | --- | --- | --- | --- | --- | --- |
| App Shell | `Color.Background.App`, `Color.Background.Panel`, `Color.Surface.Base` | `Type.Body`, `Type.BodySmall` | `Space.16`, `Space.24`, `Space.32` | `Radius.None`, `Radius.Large` | `Color.Border.Divider` | `Elevation.None` | `State.Default` |
| Cards | `Color.Surface.Base`, `Color.Surface.Raised`, `Color.Surface.InteractiveHover`, `Color.Status.*`, `Color.Risk.*` | `Type.CardTitle`, `Type.BodySmall`, `Type.Caption` | `Space.12`, `Space.16`, `Space.20` | `Radius.Large` | `Color.Border.Subtle`, `Color.Border.Strong` | `Elevation.Low` | `State.Default`, `State.Hover`, `State.Selected`, `State.Running`, `State.Completed`, `State.NeedsAttention`, `State.Disabled` |
| Buttons | `Color.Accent.*`, `Color.Surface.Interactive`, `Color.Text.*`, `Color.Risk.*` | `Type.BodySmall`, `Type.Caption` | `Space.8`, `Space.12`, `Space.16` | `Radius.Medium`, `Radius.Pill` | `Color.Border.Default`, `Color.Border.Focus` | `Elevation.None`, `Elevation.Low` | `State.Default`, `State.Hover`, `State.Pressed`, `State.Focused`, `State.Disabled`, `State.Running` |
| Badges | `Color.Risk.*`, `Color.Status.*`, supporting background/border/text variants | `Type.Caption`, `Type.Micro` | `Space.4`, `Space.6`, `Space.8` | `Radius.Small`, `Radius.Pill` | `Color.Border.Risk.*`, `Color.Border.Status.*` | `Elevation.None` | `State.Default`, `State.Disabled` |
| Dialogs | `Color.Surface.Elevated`, `Color.Overlay.Modal`, `Color.Text.*` | `Type.SectionTitle`, `Type.Body`, `Type.BodySmall` | `Space.16`, `Space.20`, `Space.24` | `Radius.XLarge` | `Color.Border.Default`, `Color.Border.Focus` | `Elevation.High` | `State.Default`, `State.Focused`, `State.WaitingForConfirmation` |
| Progress | `Color.Status.Running`, `Color.Status.WaitingForConfirmation`, `Color.Status.RestartNeeded` | `Type.BodySmall`, `Type.Caption` | `Space.8`, `Space.12`, `Space.16` | `Radius.Medium` | `Color.Border.Subtle` | `Elevation.None` | `State.Running`, `State.Completed`, `State.RestartNeeded` |
| Results | `Color.Status.Completed`, `Color.Status.CompletedWithNotes`, `Color.Status.NeedsAttention`, `Color.Status.Stopped`, `Color.Status.RestartNeeded`, `Color.Status.NotAvailable`, `Color.Status.SkippedNotNeeded` | `Type.SectionTitle`, `Type.Body`, `Type.Caption` | `Space.12`, `Space.16`, `Space.24` | `Radius.Large` | `Color.Border.Status.*` | `Elevation.Low` | `State.Completed`, `State.NeedsAttention`, `State.RestartNeeded`, `State.Blocked` |
| Diagnostics | `Color.Diagnostics.Background`, `Color.Diagnostics.Border`, `Color.Diagnostics.Text`, `Color.Diagnostics.Muted`, `Color.Background.Inset` | `Type.DiagnosticsMono`, `Type.Caption` | `Space.8`, `Space.12`, `Space.16` | `Radius.Large` | `Color.Diagnostics.Border` | `Elevation.Medium` | `State.Default`, `State.Focused` |
| Navigation | `Color.Background.Panel`, `Color.Selection.Background`, `Color.Selection.Border`, `Color.Border.Focus` | `Type.BodySmall`, `Type.Caption` | `Space.8`, `Space.12`, `Space.16` | `Radius.Medium` | `Color.Border.Divider`, `Color.Border.Strong` | `Elevation.None` | `State.Default`, `State.Hover`, `State.Selected`, `State.Completed`, `State.Disabled`, `State.NeedsAttention` |
| Overlays | `Color.Overlay.Modal`, `Color.Overlay.Subtle`, `Color.Surface.Elevated` | `Type.Body`, `Type.BodySmall` | `Space.16`, `Space.24` | `Radius.XLarge` | `Color.Border.Default` | `Elevation.High` | `State.Default`, `State.WaitingForConfirmation` |

## Accessibility And Localization Considerations

Accessibility requirements:

- visible keyboard focus for navigation, cards, buttons, dialogs, and drawers
- readable text sizes and line heights
- sufficient contrast for text, controls, borders, and focus states
- icon plus text for status, risk, and important actions
- no color-only status meaning
- disabled states must remain readable and explainable
- minimum clickable target size should be defined in a later implementation phase
- dialogs must support keyboard confirm/cancel behavior
- diagnostics must be copyable without pointer-only interaction
- progress states must be understandable to screen-reader and keyboard users later

Localization requirements:

- English and Arabic support later
- right-to-left layout considerations later
- Arabic text expansion and line-height adjustments later
- AXIS remains AXIS
- Arabic rendering is Ø§ÙƒØ³ÙŠØ³
- tool/script names remain English
- final customer-facing copy requires product-owner approval

## Current UI Migration Notes

Based on inspection of `ui/MainWindow.ps1`, the current UI is a stability/test interface that already provides many useful structural surfaces. Future AXIS work should migrate gradually rather than aggressively replacing everything at once.

Likely migration areas:

- Current stage/tool list: current stages are rendered from configuration into sidebar buttons and tool cards. Future work can map this structure into customer-facing stage names while preserving runtime stage ids until a later approved rename.
- Current action buttons: tool cards create action buttons from tool metadata. Future components should map these into the AXIS button hierarchy while preserving action behavior and confirmations.
- Current latest result area: the existing latest result panel displays tool, tool id, action, command status, verification, warnings, errors, timestamps, and detailed sections. Future work should split this into customer-facing Result Summary plus Diagnostics Drawer.
- Current action plan/details: action plan confirmation already presents risk, summary, admin/TrustedInstaller requirements, planned changes, side effects, and confirmation message. Future confirmation dialogs can reuse this evidence with more customer-facing hierarchy.
- Current diagnostics/log preview: visible activity log and copy actions already support technical transparency. Future diagnostics should keep this copyable, structured detail but hide it by default in normal customer flows.
- Current confirmation dialogs: the action plan confirmation and Graphics refresh restart confirmation demonstrate important safety patterns. Future AXIS confirmation components should keep clear decline paths, avoid frozen-feeling UI, and continue only after explicit confirmation.

These notes do not implement UI changes. They only identify where future component migration will likely connect to the current WPF surface.

## Non-Goals

This phase does not include:

- UI implementation
- visual token implementation
- WPF resource changes
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

## Next Phases

Recommended roadmap:

- Phase 176E: First redesigned screen prototype plan
- Phase 176F: Customer-facing copy/microcopy model
- Phase 176G: WPF token/resource implementation plan
- Phase 176H: First WPF visual prototype
- Later: technical BoostLab-to-AXIS rename
- Later: localization implementation

## Validation

Validation for this phase should remain docs-focused:

- `git diff --check`
- `git status --short`

Full runtime/static suite is not required for this single documentation-only design artifact.
