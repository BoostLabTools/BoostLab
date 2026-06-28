# Phase 176E - AXIS First Redesigned Screen Prototype Plan

Date: 2026-06-28
Scope: First redesigned screen prototype plan only

## Purpose

This document defines the first redesigned AXIS screen prototype plan before implementation.

It identifies a controlled first visual slice that can prove the AXIS design direction without risking BoostLab runtime stability. The plan aligns with the Phase 176A UX and brand direction, the Phase 176B customer experience model, the Phase 176C design token foundation, and the Phase 176D component inventory.

This is not implementation. It is not the final full-app redesign. It is not a WPF resource change, a code rewrite, a runtime behavior change, or a technical rename from BoostLab to AXIS. It is the plan for a safe first visual prototype.

## Recommended First Prototype Slice

The recommended first prototype slice is the AXIS Guided Stage Workspace.

The slice should include:

- App Shell
- Product Header
- Stage Navigation
- Stage Screen
- Tool / Step Cards
- Tool Detail Panel
- Action Area
- Result Summary placeholder
- Diagnostics Drawer placeholder

This is a better first prototype than starting with only a Welcome screen because it tests the real product structure. A Welcome screen can prove brand tone, but it does not exercise the core BoostLab/AXIS product experience: stages, tool cards, risk badges, action buttons, result states, diagnostics access, and current runtime-data mapping.

The Guided Stage Workspace can become the foundation for the rest of the UI because it touches the components most users will spend time with and can be prototyped without changing runtime behavior.

## Prototype Target Screen

The first prototype target should be a future AXIS Guided Stage screen mapped to the current `Windows` runtime stage as a visual sample.

Reasoning after current UI inspection:

- `ui/MainWindow.xaml` already has a product/header area, `StageNavigationPanel`, `ToolCardsPanel`, `LatestResultPanel`, `ActivityLogRichTextBox`, and status text surfaces.
- `ui/MainWindow.ps1` already renders stages from `config/Stages.psd1`, creates tool cards, routes action buttons, renders latest result details, shows action-plan confirmations, and keeps logs copyable.
- The current `Windows` stage is broad enough to test a dense real-world stage: low, medium, and high risk tools; Apply/Default/Open actions; visible Windows behavior changes; cleanup; power configuration; and result/verification summaries.
- The current `Graphics` stage is important, but it is more driver/download/restart-heavy. It should follow once the base Guided Stage Workspace pattern is proven.

The prototype should use the current `Windows` stage as the structural sample while presenting future customer-facing AXIS language. Runtime stage ids, tool ids, action names, modules, and tests must not be renamed in this phase or in the first visual prototype unless a later phase explicitly approves that technical change.

### Data Strategy

The safest first implementation should be static/sample visual state first, optionally mapped to read-only current stage metadata after the layout proves stable.

Recommended order for a later implementation phase:

1. Build an isolated visual prototype surface or feature-flagged screen that cannot run tools.
2. Use sample card states to validate layout, tokens, and component hierarchy.
3. If practical and safe, read existing stage/tool metadata for names and descriptions only.
4. Keep action execution, Apply/Default/Restore behavior, action plans, verification, async dispatch, Latest Result behavior, and diagnostics copying unchanged.

The prototype must not run tools. It must not change Apply flow. It must not change runtime behavior. Any real data-binding should be read-only and limited to already-safe metadata.

## Screen Layout Plan

### Top Product Header

Purpose: identify AXIS and show the current experience context.

Customer-facing content:

- AXIS product name
- current mode label such as Guided Setup
- short current stage context
- optional quiet status indicators later

Technical content handling:

- no raw command status
- no raw verification status
- no internal repository label in the main customer layer
- technical status remains in diagnostics or internal/dev surfaces

Component dependencies:

- Product Header
- App Shell
- Settings / Language later

Phase 176C token categories:

- `Color.Background.Panel`
- `Color.Text.Primary`
- `Color.Text.Secondary`
- `Type.PageTitle`
- `Type.BodySmall`
- `Space.16`, `Space.24`

Migration notes:

- current XAML uses `Title="BoostLab"` and visible BoostLab branding; the prototype can visually show AXIS inside an isolated prototype surface while leaving technical window/app identifiers untouched until a later rename phase.

### Stage Navigation

Purpose: show where the customer is in the guided setup journey.

Customer-facing content:

- future stage names such as Prepare, Setup, Windows, Apps, Graphics, Performance, Cleanup, Finish
- current stage indicator
- completed or needs-attention indicators where sample states require them

Technical content handling:

- do not show internal phase names
- do not show tool ids
- diagnostics for stage state remain behind details

Component dependencies:

- Stage Navigation
- Risk Badges for calm attention markers
- Result Summary for aggregate state language

Phase 176C token categories:

- `Color.Background.Panel`
- `Color.Selection.Background`
- `Color.Selection.Border`
- `Color.Border.Focus`
- `Type.BodySmall`
- `State.Default`, `State.Hover`, `State.Selected`, `State.Completed`, `State.NeedsAttention`

Migration notes:

- current `StageNavigationPanel` is already populated from stage metadata. A later prototype should preserve this structure or isolate from it without changing runtime navigation contracts.

### Main Stage Content

Purpose: explain the current stage and guide the next action.

Customer-facing content:

- stage title: Windows
- stage description in customer-friendly language
- current step
- next recommended step
- progress summary
- short stage-level notes

Technical content handling:

- no raw status labels in the stage headline
- no source/provenance in the main stage content
- no command output unless diagnostics is opened

Component dependencies:

- Stage Screen
- Guided Flow Container
- Progress State
- Result Summary placeholder

Phase 176C token categories:

- `Color.Background.App`
- `Color.Surface.Base`
- `Color.Text.Primary`
- `Color.Text.Secondary`
- `Type.PageTitle`
- `Type.SectionTitle`
- `Space.24`, `Space.32`

Migration notes:

- current `Show-BoostLabStage` already sets stage eyebrow, title, description, and tool count. The prototype can keep that runtime source but should present future customer-facing structure only inside the prototype layer.

### Tool List / Cards Area

Purpose: show the available steps in the selected stage.

Customer-facing content:

- tool cards with friendly summaries
- current state per card
- risk badges
- requirements indicators
- primary and secondary action affordances
- notes count or attention marker where needed

Technical content handling:

- do not show tool ids by default
- original English tool/script names may appear where useful, but not as the only explanation
- raw verification and command status stay in diagnostics

Component dependencies:

- Tool / Step Card
- Risk Badges
- Action Buttons
- Progress State
- Result Summary

Phase 176C token categories:

- `Color.Surface.Base`
- `Color.Surface.Interactive`
- `Color.Surface.InteractiveHover`
- `Color.Status.*`
- `Color.Risk.*`
- `Type.CardTitle`
- `Type.BodySmall`
- `Radius.Large`
- `Layout.Card.Padding`

Migration notes:

- current `New-BoostLabToolCard` builds cards from metadata and action lists. A later visual prototype should avoid changing action routing and can initially show static cards in a separate prototype surface.

### Selected Tool Detail Area

Purpose: explain the selected step before action.

Customer-facing content:

- selected tool title
- plain-language purpose
- what this step changes
- requirements and risks
- expected outcome
- primary action
- details/diagnostics access

Technical content handling:

- hide raw action plan fields until confirmation/details
- hide raw command lines
- keep exact technical detail available in diagnostics

Component dependencies:

- Tool Detail Panel
- Action Area
- Risk Badges
- Confirmation Dialog placeholder
- Diagnostics Drawer placeholder

Phase 176C token categories:

- `Color.Surface.Raised`
- `Color.Border.Subtle`
- `Color.Text.Primary`
- `Color.Text.Secondary`
- `Type.SectionTitle`
- `Type.Body`
- `Layout.Panel.Width`
- `Space.16`, `Space.20`

Migration notes:

- current selected-tool labels and Latest Result area can inform the detail-panel data model, but future customer-facing detail should not be a raw latest-result dump.

### Diagnostics Drawer Or Details Panel

Purpose: keep technical details available without dominating the main customer experience.

Customer-facing content:

- visible access point such as Details or Diagnostics
- collapsed by default
- copy report action

Technical content handling:

- raw status
- command status
- verification status
- source/provenance
- hashes
- detailed operation list
- logs
- technical warnings/errors

Component dependencies:

- Diagnostics Drawer
- Result Summary
- Copy Report action

Phase 176C token categories:

- `Color.Diagnostics.Background`
- `Color.Diagnostics.Border`
- `Color.Diagnostics.Text`
- `Color.Diagnostics.Muted`
- `Type.DiagnosticsMono`
- `Layout.Diagnostics.Width`
- `Color.Background.Inset`

Migration notes:

- current `LatestResultPanel`, `ActivityLogRichTextBox`, `CopyLatestResultButton`, and `CopyLogButton` already provide useful diagnostics behavior. The prototype should preserve copyability and move diagnostics behind a cleaner customer layer.

### Bottom Action / Result Area

Purpose: keep the current action, progress, and latest customer-facing outcome visible.

Customer-facing content:

- current action summary
- progress phase
- customer-facing result state
- next recommended action
- restart or attention marker if needed

Technical content handling:

- no raw log flood
- no raw `Command Status` or `Verification Status` as primary labels
- details remain available through diagnostics

Component dependencies:

- Action Area
- Progress State
- Result Summary
- Restart Checkpoint placeholder

Phase 176C token categories:

- `Color.Background.Panel`
- `Color.Surface.Base`
- `Color.Status.*`
- `Type.BodySmall`
- `Space.12`, `Space.16`
- `Layout.BottomBar.Height`

Migration notes:

- current `ApplicationStatusText` and Latest Result rendering can inform this area, but the customer layer should use outcome language first.

## Customer-Facing Content Layer

The prototype should show:

- stage title
- stage description
- current step
- next recommended step
- tool cards with friendly summaries
- risk badges
- requirements indicators
- primary action button
- secondary details action
- customer-friendly result states

Customer-friendly result states:

- Completed
- Completed with notes
- Needs attention
- Stopped
- Restart needed
- Waiting for your confirmation
- Not available on this device
- Skipped because not needed

Raw `Success`, `Warning`, `Error`, `Verification Status`, and `Command Status` should not be primary visual labels in the prototype main UI. Those values can remain in diagnostics.

Final customer-facing copy per stage/tool is product-owner controlled and belongs in a later copy/microcopy phase.

## Diagnostics Layer

The diagnostics/details layer should contain:

- raw status
- command status
- verification status
- source/provenance
- hashes
- detailed operation list
- logs
- technical warnings/errors
- copy technical report

The prototype should include a visible diagnostics access point, but diagnostics should not dominate the main customer experience. The drawer can be represented as open and closed sample states without wiring real diagnostics in the first visual slice.

Diagnostics must remain complete and copyable in later implementation. The customer layer changes presentation hierarchy only; it must not hide real failures or remove technical evidence.

## Component Coverage

| Component | Prototype states to represent | Phase 176C token categories | Out of scope for first prototype |
| --- | --- | --- | --- |
| App Shell | default dark shell | background, panel, surface, spacing | technical app rename, full shell rewrite |
| Product Header | AXIS guided setup header | text, panel, spacing | settings/language implementation |
| Stage Navigation | current, completed, needs attention, available | selection, navigation, status, focus | runtime stage rename |
| Stage Screen | default stage view with current/next step | page title, surface, spacing | changing stage order or behavior |
| Tool / Step Card | default, selected, running, completed, notes, attention, unavailable | cards, status, risk, border, radius | changing tool/action metadata |
| Tool Detail Panel | selected tool detail | raised surface, body text, spacing | final per-tool content approval |
| Risk Badges | system change, cleanup, advanced, restart, device-specific | risk color tokens, captions, borders | new risk policy behavior |
| Action Buttons | primary, secondary, disabled, restart placeholder | button tokens, focus, accent | action execution changes |
| Progress State | preparing, running, waiting, finalizing | status, body small, spacing | cancellation behavior |
| Result Summary | completed, notes, attention, stopped, restart needed | result/status tokens | changing runtime result contracts |
| Diagnostics Drawer | open and closed | diagnostics colors, monospace, panel width | hiding/removing diagnostics |
| Confirmation Dialog placeholder | normal/high-risk/restart placeholder | overlay, elevated surface, button tokens | changing confirmation logic |
| Restart Checkpoint placeholder | restart needed and user-decline sample | restart status/risk tokens | real reboot/resume behavior |

## Prototype Sample States

The first prototype plan should include these visual states:

- Default stage view: Windows stage open with a calm overview and recommended next step.
- Selected tool: one tool card selected and expanded in the detail panel.
- Running tool: sample card and bottom progress area show active work without raw log flood.
- Completed tool: completed state shown quietly with next action.
- Completed with notes: completed state includes a notes indicator and customer-friendly note.
- Needs attention: one tool needs review with a specific reason.
- Restart needed: a result or placeholder checkpoint explains restart timing without surprise behavior.
- Not available on this device: a sample tool or action explains non-applicability calmly.
- Diagnostics drawer closed: default customer view stays clean.
- Diagnostics drawer open: technical fields and copy report action are visible.

These are visual states only. They do not implement runtime state transitions.

## WPF Implementation Strategy For Later

Later implementation should follow this order:

1. Add centralized AXIS WPF resource tokens first.
2. Avoid scattered hardcoded values.
3. Keep current runtime and action execution unchanged.
4. Introduce visual components incrementally.
5. Prefer a feature flag or isolated prototype area if practical.
6. Start with static/sample visual states before real data-binding.
7. Add read-only metadata binding only after static layout is stable.
8. Preserve async execution and current action dispatch.
9. Preserve Latest Result behavior and copyable diagnostics.
10. Preserve tool/action contracts.
11. Avoid large third-party UI frameworks initially.

Implementation should be WPF-native and conservative. The prototype may visually say AXIS, but technical identifiers can remain BoostLab until a later approved rename phase.

## Safety And Runtime Boundaries

The prototype must not:

- run tools differently
- change Apply behavior
- change Default behavior
- change Restore behavior
- change Open behavior
- change action plans
- change confirmation requirements
- change verification logic
- change source validation
- change driver behavior
- change Defender behavior
- change cleanup behavior
- change installer behavior
- change restart behavior
- hide real failures
- remove diagnostics
- remove copyable reports/logs
- weaken Ultimate execution strength
- reintroduce deleted tools

The first visual prototype is a presentation experiment, not a runtime migration.

## Customer-Facing Terminology Implications

Avoid these terms in the prototype main UI:

- BoostLab as customer brand, except internal/dev areas until technical rename
- Ultimate
- source-ultimate
- source-extra
- source-defined
- source-equivalent
- raw `Success`, `Warning`, or `Error` as primary labels
- `Verification Status`
- `Command Status`
- phase names
- Codex / ChatGPT / OpenAI workflow terms
- Yazan internal references

Technical details may remain in diagnostics, developer views, internal docs, tests, and support reports until a later microcopy cleanup phase defines final language.

Tool/script names remain English even in future Arabic UI. AXIS remains AXIS. The Arabic rendering is Ø§ÙƒØ³ÙŠØ³.

## Visual Acceptance Criteria

A successful first prototype should prove:

- AXIS feels premium, dark, technical, and clear
- guided structure is understandable
- the selected stage and next step are obvious
- tool cards are easier to scan than raw script lists
- risk is visible but calm
- results feel customer-friendly
- diagnostics are available but not overwhelming
- copyable technical details remain available
- the interface does not feel like a raw PowerShell wrapper
- no runtime behavior is changed
- existing tests remain stable

## Implementation Readiness Checklist

- [x] Design tokens document exists.
- [x] Component specs document exists.
- [x] First prototype screen is selected.
- [x] Sample states are defined.
- [x] Customer/diagnostic layer separation is defined.
- [x] WPF token/resource approach is planned at a high level.
- [x] Runtime safety boundaries are clear.
- [x] Validation plan is clear.
- [ ] Product owner approves exact first prototype content.
- [ ] Later implementation phase defines the exact feature flag or isolated prototype route.

## Non-Goals

This phase does not include:

- code changes
- UI implementation
- WPF resource implementation
- runtime behavior changes
- module behavior changes
- test behavior changes
- localization implementation
- technical BoostLab-to-AXIS rename
- external packaging/source decoupling
- logo design
- full-app redesign in one step
- dashboard/free-control implementation

## Next Phases

Recommended roadmap:

- Phase 176F: WPF design token/resource implementation plan
- Phase 176G: First WPF visual prototype implementation
- Phase 176H: Customer-facing copy/microcopy model
- Phase 176I: Guided flow content model per stage/tool
- Later: technical BoostLab-to-AXIS rename
- Later: localization implementation

## Validation

Validation for this phase should remain docs-focused:

- `git diff --check`
- `git status --short`

Full runtime/static suite is not required for this single documentation-only design artifact.
