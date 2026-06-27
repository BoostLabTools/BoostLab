# Phase 176B - AXIS Customer Experience Model and Screen-Flow Map

Date: 2026-06-28
Scope: Customer-facing experience model and screen-flow direction only

## Purpose

This document defines the customer-facing experience model and screen-flow map for AXIS before visual design, component implementation, localization, or technical rename work begins.

It translates the Phase 176A AXIS UX and brand direction into a practical product experience: what the customer sees, how the customer moves through the app, what each major screen is responsible for, how guided setup works, how results are presented without raw technical labels as the primary experience, and how diagnostics remain available without overwhelming the customer.

This phase is document-only. It does not implement UI changes.

## Experience Model Summary

AXIS should support two experience layers.

### Guided Setup Mode

Guided Setup Mode is the primary first-run and setup journey.

It should:

- lead the customer step by step
- provide a recommended path
- explain before action
- reduce decision overload
- show the current step and the next step
- keep risk visible without making the experience feel scary
- keep diagnostics available without making them the main view

This mode should feel like a controlled Windows setup workspace, not a list of raw scripts.

### Control Dashboard Mode

Control Dashboard Mode is a later/free-control experience after setup completion.

It should:

- let the user revisit tools intentionally
- expose advanced control without forcing the guided flow again
- separate recommended actions from advanced controls
- show recent results or history when useful
- preserve the same safety, confirmation, and diagnostics model

Dashboard Mode is planned as a future experience. It is not implemented in this phase.

## Primary Customer Journey

The main AXIS customer journey should be strategic and guided:

1. Welcome
2. System readiness check
3. Setup preparation
4. Core Windows configuration
5. Essential installers
6. Graphics and performance setup
7. Windows cleanup and polish
8. Final review
9. Restart or final confirmation if needed
10. Completion summary

This is UX flow direction only. It does not force the final runtime order and does not rename or reorder the current implementation.

## Screen-Flow Map

### Welcome Screen

Purpose: introduce AXIS and establish the guided setup journey.

What the customer sees:

- AXIS name and short product promise
- a calm explanation of guided setup
- system setup goals at a high level
- start action
- optional access to settings later

Available actions:

- start guided setup
- choose language later when localization exists
- exit

What should not be shown:

- raw tool list
- raw script names as the primary content
- technical warnings before context exists
- internal project names

Technical data handling: none by default. Diagnostics can remain unavailable here unless startup diagnostics are needed later.

UX notes: this screen should feel premium, concise, and confidence-building. It should not be a marketing landing page inside the app.

### Language Selection Later

Purpose: allow English or Arabic selection when localization is implemented.

What the customer sees:

- language choices
- brief note that tool names may remain English
- continue action

Available actions:

- select English
- select Arabic
- continue

What should not be shown:

- translation debug labels
- raw localization keys
- technical language fallback details

Technical data handling: language preference can be stored later when localization is implemented.

UX notes: AXIS remains AXIS. Arabic rendering is اكسيس. Arabic text should be natural, not literal.

### System Check Screen

Purpose: verify the device is ready for guided setup and identify important constraints.

What the customer sees:

- readiness summary
- admin status
- internet availability if needed
- device/Windows compatibility notes
- major blockers or notes
- next recommended step

Available actions:

- run or refresh check
- continue if ready
- review details
- stop if a blocker exists

What should not be shown:

- raw command output as the main view
- hashes
- source/provenance labels
- raw `Success`, `Warning`, or `Error` labels as primary states

Technical data handling: raw checks, verification detail, command status, and logs live in diagnostics.

UX notes: the screen should be direct and reassuring. It should explain what matters for setup without flooding the customer.

### Guided Flow Overview Screen

Purpose: show the customer the journey before the first setup step.

What the customer sees:

- the major setup sections
- current progress
- which steps are recommended
- which steps may require confirmation, downloads, or restart

Available actions:

- begin recommended flow
- skip a non-required section if allowed later
- open details for a section

What should not be shown:

- every low-level tool at once
- developer diagnostics
- internal phase names

Technical data handling: step readiness and availability can be summarized; raw details stay in diagnostics.

UX notes: this screen should reduce decision overload. It should make setup feel finite and understandable.

### Stage Screen

Purpose: group related customer-facing steps.

What the customer sees:

- stage title and purpose
- recommended step order
- step cards
- status summaries
- risk indicators where relevant

Available actions:

- open a tool/step
- continue to recommended next step
- review completed items
- view diagnostics for the stage if needed

What should not be shown:

- raw script list as the main structure
- internal tool ids
- excessive technical settings

Technical data handling: diagnostics should remain accessible per stage but hidden by default.

UX notes: stages should feel like meaningful customer sections, not folders of scripts.

### Tool Detail / Step Screen

Purpose: explain one tool or setup step before action.

What the customer sees:

- customer-friendly title
- original English tool/script name where needed
- short purpose
- what this step changes
- requirements
- risk badges
- estimated time if known
- restart/download/admin indicators
- primary action
- diagnostics/details drawer

Available actions:

- run the primary action
- choose an alternate action if approved
- open confirmation when required
- view technical details
- go back to the stage

What should not be shown:

- raw PowerShell implementation details
- source/provenance as the default customer view
- internal warnings without customer translation

Technical data handling: the details drawer can show raw status, hashes, provenance, command status, and logs.

UX notes: simple tools can have short screens. Technical tools can have richer explanation, but the main path should still be clear.

### Confirmation Screen

Purpose: ensure the user understands impact before an important action.

What the customer sees:

- what AXIS will do
- what could change
- risk badges
- restart/download/security/file impact
- whether the user can stop now
- what happens after confirmation

Available actions:

- confirm and continue
- cancel or go back
- open details

What should not be shown:

- fear-based language
- vague "are you sure" prompts
- raw command lines as the main message

Technical data handling: technical execution plan can be available behind details.

UX notes: confirmations should be calm, specific, and short enough to understand quickly.

### Running / Progress Screen

Purpose: show that AXIS is working and prevent frozen-feeling UI.

What the customer sees:

- current step
- progress summary
- safe waiting state
- active operation label in customer language
- ability to view diagnostics if needed

Available actions:

- view details
- copy diagnostics when available
- cancel only if the action safely supports cancellation later

What should not be shown:

- overwhelming raw logs in the main view
- ambiguous spinner-only state for long operations
- frozen or silent UI

Technical data handling: raw logs and command output go to diagnostics.

UX notes: the user should always know whether AXIS is checking, downloading, applying, waiting, or asking for action.

### Result Summary Screen

Purpose: explain the outcome of a step in customer-friendly language.

What the customer sees:

- result state
- short explanation
- notes if any
- next recommended action
- restart requirement if present
- details option

Available actions:

- continue
- retry if appropriate
- view diagnostics
- stop or return to overview

What should not be shown:

- raw `Success`, `Warning`, or `Error` as the primary label
- raw verification status as the headline
- internal error stacks in the main view

Technical data handling: technical status remains in diagnostics and logs.

UX notes: "Completed with notes" should feel informational, not alarming. "Needs attention" should clearly tell the customer what to review.

### Diagnostics Drawer / Technical Details

Purpose: keep technical evidence available without making it the emotional center of the app.

What the customer sees:

- raw status
- verification details
- command status
- logs
- hashes if needed
- source/provenance if appropriate for internal or support mode
- copy technical report action

Available actions:

- copy report
- expand sections
- collapse drawer

What should not be shown:

- diagnostics forced open by default for normal successful flows
- internal development text in normal customer summaries

Technical data handling: diagnostics should be complete, structured, and copyable.

UX notes: this area is for support, technicians, and power users. It should be trustworthy and easy to copy.

### Restart Checkpoint Screen

Purpose: make restart timing predictable.

What the customer sees:

- why restart is needed
- whether AXIS can continue after restart later
- what to expect next
- any manual steps

Available actions:

- restart now if implemented and approved later
- restart later
- return to summary
- copy notes

What should not be shown:

- sudden restart prompts without context
- hidden restart consequences

Technical data handling: restart reasons and related action logs stay available in diagnostics.

UX notes: restart is a checkpoint, not a surprise.

### Completion Screen

Purpose: close the guided setup journey.

What the customer sees:

- final setup summary
- completed sections
- notes needing attention
- restart status
- suggested next steps
- option to enter dashboard mode later

Available actions:

- finish
- open dashboard later
- export or copy summary later
- review diagnostics

What should not be shown:

- raw logs as the primary content
- internal phase names
- source/provenance details unless opened

Technical data handling: final technical report can remain copyable.

UX notes: completion should make the user feel oriented, not abandoned.

### Dashboard Mode Later

Purpose: provide direct access after guided setup is complete.

What the customer sees:

- system state overview
- maintenance actions
- recommended actions
- recent results/history
- advanced controls separated from normal recommendations

Available actions:

- rerun tools intentionally
- open advanced controls
- review history
- open diagnostics

What should not be shown:

- a forced repeat of the guided setup
- ungrouped script dumps
- dangerous actions without confirmation

Technical data handling: dashboard can surface summaries while keeping detailed logs behind diagnostics.

UX notes: this mode is future-facing and should not be part of first implementation unless explicitly approved.

## Stage Model

The future customer-facing stage structure can be simpler and more outcome-oriented than the current runtime stages.

Do not rename current runtime stages in code. This is UX structure only.

### Prepare

Customer purpose: get the device and user ready for setup.

Expected tools: readiness checks, setup prerequisites, admin/internet checks, restart or manual preparation.

Risk level style: usually low to medium; focus on readiness and blockers.

User guidance style: explain what AXIS needs before continuing.

Result summary style: ready, needs attention, or stopped with a clear reason.

### Setup

Customer purpose: configure foundational Windows setup choices.

Expected tools: account/setup preparation, system settings, security-sensitive setup helpers.

Risk level style: medium, with specific notes for security-sensitive changes.

User guidance style: explain impact and give clear confirmation points.

Result summary style: completed, completed with notes, or waiting for confirmation.

### Windows

Customer purpose: tune core Windows behavior.

Expected tools: Windows settings, shell/taskbar behavior, system policies, quality-of-life options.

Risk level style: low to high depending on tool; use badges rather than long warnings.

User guidance style: explain visible user impact and reversibility if known.

Result summary style: outcome and visible changes first, technical details second.

### Apps

Customer purpose: install or prepare essential applications.

Expected tools: curated installers, app setup, download-dependent steps.

Risk level style: download and install indicators should be clear.

User guidance style: show selected apps, download need, and estimated time where known.

Result summary style: installed, skipped, needs attention, or stopped.

### Graphics

Customer purpose: prepare graphics-related setup and performance tools.

Expected tools: NVIDIA-focused setup, graphics runtime installers, driver-related workflows.

Risk level style: driver change and restart indicators should be prominent when applicable.

User guidance style: be precise and controlled; avoid flashy gaming language.

Result summary style: driver/performance outcome, restart need, and notes.

### Performance

Customer purpose: apply approved performance-related configuration.

Expected tools: performance assistants, system behavior toggles, advanced options.

Risk level style: advanced and system change badges should guide the user.

User guidance style: explain expected benefit and impact without overpromising.

Result summary style: what changed, what was skipped, and what to review.

### Cleanup

Customer purpose: remove temporary or unwanted data safely.

Expected tools: cleanup steps, final polish, temporary file handling.

Risk level style: file cleanup badge with specific scope.

User guidance style: be clear about what may be deleted and what is not touched.

Result summary style: cleaned, skipped because not needed, or needs attention.

### Finish

Customer purpose: summarize work and close the guided journey.

Expected tools: final review, restart checkpoint, completion summary.

Risk level style: restart and unresolved notes only.

User guidance style: show the final state and next steps.

Result summary style: concise completion with details available.

## Tool Detail Model

Each future tool screen or card should eventually include:

- customer-friendly title
- original English tool/script name retained where useful
- short purpose
- what this step changes
- requirements
- risk indicators
- estimated time if known
- restart/download/admin indicators
- primary action
- confirmation language when needed
- progress state
- customer result summary
- diagnostics/details drawer

Some tools may be short and simple. Some may need a detailed technical explanation. The product owner decides exact content per tool later.

The template should support both regular users and power users: clean primary explanation first, deeper details second.

## Result Presentation Model

Raw technical labels should not be the main UX:

- `Success`
- `Warning`
- `Error`
- `Verification Status`
- `Command Status`

Customer-facing states should be outcome-based:

- Completed
- Completed with notes
- Needs attention
- Stopped
- Restart needed
- Waiting for your confirmation
- Not available on this device
- Skipped because not needed

Completed with notes means the action finished and there is something useful to know. It should not feel scary.

Needs attention means the customer should review something before continuing.

Stopped means the workflow did not continue, either by user choice, unmet requirement, or a real blocker.

Restart needed means the current result is not fully complete until restart happens.

Waiting for your confirmation means AXIS is paused and will not proceed until the user decides.

Not available on this device should be calm and specific, not treated as a failure when the tool is legitimately not applicable.

Skipped because not needed should reassure the user that AXIS checked the condition and avoided unnecessary work.

Diagnostics remain available for technical support. Raw internal status stays in logs and developer diagnostics.

## Risk And Confidence Model

AXIS should explain risk calmly and specifically.

### System Change

Meaning: AXIS may change Windows settings, policies, services, or system behavior.

Presentation: use a clear badge and one sentence about expected impact.

Tone: controlled and factual.

Do not: imply danger without explaining the actual scope.

### Driver Change

Meaning: AXIS may affect driver setup, graphics behavior, or driver-related tools.

Presentation: make device relevance, restart possibility, and vendor scope clear.

Tone: precise and performance-aware.

Do not: use hype language or hide restart implications.

### Security-Sensitive

Meaning: AXIS may touch security-related settings, protection state, encryption, or Defender-related flows.

Presentation: show the badge prominently and require clear confirmation when action is impactful.

Tone: calm, careful, and specific.

Do not: make security changes feel casual or use scary wording.

### Restart Required

Meaning: the step needs a restart to finish or continue safely.

Presentation: show before action and again in result summary.

Tone: predictable and practical.

Do not: surprise the user with restart behavior.

### Download Required

Meaning: AXIS needs internet access or external artifacts.

Presentation: show download need, approximate scope if known, and what happens if offline.

Tone: practical.

Do not: hide network dependency until failure.

### File Cleanup

Meaning: AXIS may delete temporary or cleanup-target files.

Presentation: explain cleanup scope in customer language.

Tone: careful and concrete.

Do not: imply broad deletion without scope.

### Advanced

Meaning: the step is technical or affects deeper system behavior.

Presentation: keep the main explanation clear and provide a details drawer.

Tone: confident and measured.

Do not: overload the main screen with implementation detail.

### Device-Specific

Meaning: the step depends on hardware, Windows edition, device state, or installed components.

Presentation: explain why the step is available, unavailable, skipped, or limited.

Tone: normal and non-punitive.

Do not: make a non-applicable step look like a failure.

## Confirmation Model

Confirmations should be clear, calm, specific, not overly technical, not scary, and honest about impact.

### Normal Confirmation

Use when a step changes settings but has limited risk.

Concept: "AXIS is ready to apply this setup step. Here is what will change and what happens next."

### High-Risk Confirmation

Use for driver, security-sensitive, cleanup, restart, or broad system actions.

Concept: "This step can affect important system behavior. Review the scope before continuing."

### Restart Confirmation

Use when restart is immediate, required soon, or needed for completion.

Concept: "A restart is needed to finish this step. AXIS will pause here and show what to do next."

### Manual Checkpoint Confirmation

Use when the user must perform or confirm an external/manual action.

Concept: "Complete this manual step, then return to AXIS to continue."

### Unavailable Or Not Applicable Message

Use when the step cannot or should not run on the current device.

Concept: "This step is not available on this device because AXIS did not find the required condition."

### User Decline Path

If the user declines, AXIS should stop or skip the step intentionally and show the next safe option.

Concept: "No changes were made. You can continue to the next step or return later."

## Progress Model

Running actions should feel active and safe.

AXIS should show:

- current step
- progress summary
- active operation explanation
- safe waiting state
- expected wait or phase if known
- ability to view diagnostics
- result transition when work completes

The main view should not become a raw log stream. Logs can update in diagnostics. Long actions should not feel frozen.

The UI should make it clear when AXIS is checking, downloading, applying, waiting for confirmation, waiting for restart, or finished.

## Diagnostics Model

AXIS should separate customer and technical layers.

Customer layer:

- simple result
- short notes
- next action
- restart or manual checkpoint if needed

Technical layer:

- raw status
- verification details
- command status
- hashes
- source/provenance
- logs
- copy technical report

Diagnostics should be:

- available
- copyable
- hidden behind details/drawer by default
- structured enough for support
- not part of the main customer emotional experience

This split must not hide real failures. It only changes presentation hierarchy.

## Language And Localization Experience

Language choice can appear in first-run setup or settings later.

AXIS should support English and Arabic later.

Brand language:

- AXIS stays AXIS
- Arabic rendering: اكسيس

Tool/script names remain English. Technical terms can remain English when clearer than forced translation.

Arabic text should sound natural and product-quality, not literal or awkward. English text should be concise and polished.

Final copy requires product-owner approval. This phase does not implement localization.

## Dashboard Mode Later

Dashboard Mode should appear after guided setup is completed.

It can:

- show system state and maintenance actions
- let users rerun tools intentionally
- separate recommended actions from advanced controls
- show recent results or history
- provide diagnostics access
- avoid forcing the guided flow again

Dashboard Mode should not be part of the first implementation unless a later phase approves it.

## Customer-Facing Text Cleanup Implications

These terms should not appear in normal customer UI:

- BoostLab as the customer brand once AXIS rename is implemented
- Ultimate
- source-ultimate
- source-extra
- source-defined
- source-equivalent
- raw hashes
- provenance labels
- raw `Success`, `Warning`, or `Error` as primary labels
- internal phase names
- Codex, ChatGPT, or OpenAI workflow material
- Yazan personal/internal references

Some terms can remain in diagnostics, developer views, internal docs, tests, or support reports where appropriate.

Normal customer UI should use AXIS language and customer-friendly states. Actual microcopy rewrite is a later phase.

## Non-Goals

This phase does not include:

- UI implementation
- visual design tokens
- component styling
- code changes
- localization implementation
- technical rename
- source decoupling
- packaging implementation
- runtime behavior changes
- module behavior changes
- logo design

## Next Phases

Recommended roadmap:

- Phase 176C: Design system foundation tokens
- Phase 176D: Component inventory and component specs
- Phase 176E: First redesigned screen prototype
- Phase 176F: Customer-facing copy and microcopy model
- Later: technical BoostLab-to-AXIS rename
- Later: localization implementation
- Later: dashboard mode implementation

## Validation

Validation for this phase should remain docs-focused:

- `git diff --check`
- `git status --short`

Full runtime/static suite is not required for a single documentation-only design artifact.
