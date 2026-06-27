# Phase 176A - AXIS UX and Brand Direction Brief

Date: 2026-06-28
Scope: UX and brand direction only

## Purpose

This brief defines the initial customer-facing UX and brand direction for AXIS, the future product name for the guided Windows setup and optimization tool currently developed in the BoostLab repository.

This phase is documentation-only. It does not implement UI changes, does not rename technical assets, and does not continue the external packaging or source-free cleanup track.

## Product Positioning

AXIS is a guided Windows setup and optimization workspace for performance users, gamers, and regular users who want a clean, controlled setup experience.

AXIS should feel technical and powerful without becoming hard to understand. It is not just a raw script launcher. The product should guide users through checks, preparation, system configuration, installs, graphics and performance work, cleanup, and final review with clear context before each action.

The core promise is confidence: users should understand what AXIS is about to do, why it matters, what risk level is involved, and what will happen next.

## Naming Note

AXIS is the intended customer-facing product, tool, store, and brand name.

The Arabic brand rendering is: اكسيس

BoostLab may remain the internal repository and project codename until a later technical rename phase. This phase does not rename files, folders, modules, namespaces, tool ids, repository metadata, code references, tests, or runtime identifiers.

Full technical rename from BoostLab to AXIS is out of scope for this phase.

## Target Users

Primary users: gamers and performance users.
Design implication: AXIS should feel fast, controlled, technically credible, and performance-oriented without relying on loud RGB or gimmick visuals.

Secondary users: regular users who want Windows configured cleanly.
Design implication: AXIS should explain decisions plainly, avoid overwhelming settings dumps, and provide safe guided choices.

Future possible users: technicians and power users.
Design implication: AXIS should keep diagnostics, logs, source/provenance details, and advanced context available without making them the main customer layer.

## Brand Personality

Clarity: AXIS should make complex Windows setup work legible. The user should always know what a step does and why it exists.

Power: AXIS should feel capable enough for serious system work. Actions can be deep, but the interface should make them controlled.

Technical: AXIS should respect technical users with accurate language, honest status, and accessible diagnostics.

AXIS is not:

- hacker-style
- childish gaming RGB
- enterprise-boring
- a raw PowerShell console
- a clone of AtlasOS, Win11Debloat, WinUtil, or any other project
- a decorative shell over unsafe automation

## Visual Direction

The first design system should be dark-only.

The visual style should balance Windows-native utility clarity with subtle gaming and performance energy. It should feel premium and paid, but not exaggerated.

Direction:

- dark technical foundation
- premium utility feel
- Windows-native cleanliness
- subtle performance/gaming energy
- strong hierarchy for stages, steps, risks, and actions
- clear cards for guided work
- controlled accent color usage
- calm and confidence-building status language
- restrained motion and effects
- no excessive RGB, neon overload, glow gimmicks, or noisy backgrounds

The current app UI should be treated as a test and stability UI, not the final customer-facing design.

## UX Principles

Guided over dumped options: users should see a clear next step, not a wall of raw toggles.

Explain before action: every meaningful action needs a short, clear reason and expected result.

Risk clarity without fear: risk should be visible, specific, and calm.

Technical power behind a clean customer layer: the customer sees outcomes and decisions; diagnostics remain available for support and troubleshooting.

Outcome first, details second: primary UI should emphasize what happened, what needs attention, and what comes next.

Every dangerous action needs context: system, driver, security, cleanup, restart, and download actions need clear framing.

Restart and manual steps must be predictable: users should know when a restart is needed and whether AXIS will pause, continue, or wait.

No surprise behavior: AXIS should not execute impactful actions without clear confirmation.

Current step and next step must always be visible.

## Information Architecture

AXIS should eventually support two high-level modes:

- First-run or setup mode: a guided flow for users configuring a system.
- Later dashboard or free-control mode: a more direct control surface after the guided setup is complete.

The current stages remain conceptually useful as product structure, but customer-facing screens should not rely only on raw script or tool names. Tools should be presented as understandable steps with context, expected outcome, and risk information.

Each tool screen or card may have custom content later. The product owner will decide exactly what each stage and tool shows to customers in future phases.

## Guided Flow Concept

Future guided setup can be organized around a strategic flow such as:

1. Welcome and system check
2. Setup preparation
3. Core Windows configuration
4. Installers
5. Graphics and performance
6. Cleanup and final polish
7. Completion, restart guidance, and final summary

This is UX direction only. It does not force the final runtime order, and it does not change the current stage order or tool behavior.

## Customer-Facing Result Model

The main customer layer should not primarily expose raw technical labels such as `Success`, `Warning`, `Error`, `Verification Status`, or `Command Status`.

Customer-facing result language should be more outcome-based:

- Completed
- Completed with notes
- Needs attention
- Stopped
- Restart needed
- Waiting for your confirmation

Technical fields should remain available in diagnostics, developer, or log views:

- raw status
- verification status
- command status
- hashes
- source/provenance
- detailed logs
- structured errors

This is a UX presentation layer only. It must not hide real failures, suppress meaningful warnings, or weaken diagnostics. Diagnostic details should remain copyable for troubleshooting.

## Risk And Confirmation Language

Risk language should feel calm, clear, specific, and not scary. It should avoid excessive technical density while still explaining real impact.

Risk categories should include:

- system change
- driver change
- restart required
- network/download required
- security-sensitive
- file cleanup

Future confirmation copy should answer:

- What will AXIS do?
- What could change?
- Does this need a restart?
- Can the user stop now?
- What happens after confirmation?

This phase does not rewrite actual product copy.

## Language And Localization Direction

AXIS should support English and Arabic later.

Brand naming:

- English brand name: AXIS
- Arabic brand rendering: اكسيس

Tool and script names should remain in English even when the UI language is Arabic. Technical terms may also remain in English where that is clearer and less awkward.

Arabic UI should not be a literal or awkward translation. It should read naturally while preserving technical accuracy. English UI should be concise, polished, and product-quality.

The product owner approves final customer-facing copy. This phase does not implement localization.

## Component Philosophy

Future AXIS UI work should define components before broad redesign implementation.

Key future components:

- stage navigation: shows where the user is in the setup journey
- guided step card: frames one focused step with purpose, risk, and next action
- tool card: presents a specific tool as a customer-friendly capability
- risk badges: identify system, driver, restart, security, cleanup, or download impact
- action buttons: make available actions clear and limited to the current context
- confirmation dialog: summarizes impact before a meaningful action runs
- progress state: shows active work without exposing raw command noise by default
- result summary: explains outcome and next step in customer language
- diagnostics drawer or panel: keeps logs, raw status, hashes, and provenance available
- language switcher later: supports English and Arabic selection
- completion summary: gives final state, notes, restarts, and unresolved items
- restart checkpoint: makes restart timing and continuation clear
- technical details drawer: exposes deeper details without crowding normal UI

These are intended roles, not final visual specifications.

## Design Constraints

The current app is PowerShell/WPF-based.

Future design work should avoid adding large UI libraries unless a later phase clearly justifies them. No third-party dependency should be added in this phase.

AXIS needs a design system before broad UI changes. Visual redesign must preserve runtime safety and test stability, and it must not change tool behavior unless a phase explicitly plans that behavior change.

The first design system should focus on structure, tokens, components, and state language before visual polish expands.

## TypeUI, Figma, And Fluent Direction

TypeUI may be useful later as a design-context or tooling layer after AXIS direction is defined. Do not adopt TypeUI yet.

Figma may be useful later for visual exploration, but it is optional. Do not assume the product owner has Figma, TypeUI, or any other design-tool account or subscription.

Fluent and Windows design can be used as inspiration for native clarity, spacing, typography discipline, and familiar interaction patterns. AXIS should still have its own identity.

No third-party design tool or service integration belongs in this phase.

## Non-Goals

This phase does not include:

- UI implementation
- color token implementation
- component rewrite
- external packaging work
- source decoupling work
- technical BoostLab-to-AXIS rename
- microcopy rewrite
- localization implementation
- logo design
- runtime behavior changes
- module behavior changes
- test behavior changes

## Next Phases

Recommended roadmap:

- Phase 176B: Customer-facing experience model and screen-flow map
- Phase 176C: Design system foundation tokens
- Phase 176D: Component inventory and component specs
- Phase 176E: First redesigned screen prototype
- Phase 176F: Customer-facing copy and microcopy pass
- Later separate phase: technical rename from BoostLab to AXIS after UX and design direction is stable

## Validation

Validation for this phase should remain docs-focused:

- `git diff --check`
- `git status --short`

Full runtime/static suite is not required for a single documentation-only design brief, unless later project policy requires it.
