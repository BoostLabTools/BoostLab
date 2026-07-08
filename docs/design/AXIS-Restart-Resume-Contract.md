# AXIS Persistence And Resume Blueprint

Date: 2026-07-08
Scope: AXIS first-use wizard persistence and resume design with prototype-only temp-file preview state

Related roadmap lock:

- `docs/design/AXIS-Product-Direction-Lock.md`

## Purpose

AXIS must persist and resume the customer's first-use wizard position.

Goals:

- If the customer closes AXIS and reopens it, AXIS returns to the last saved step or page.
- If a restart happens during an expected AXIS-controlled step flow, future production AXIS can auto-start later and resume properly.
- If the customer manually restarts the PC outside an expected AXIS restart flow, AXIS does not auto-start. In that case, AXIS resumes only when the customer opens AXIS manually.

This blueprint describes the production persistence/resume direction and the isolated prototype preview boundary. The current prototype may use prototype-only temp-file state so close/reopen resume can be visually tested. It does not implement production runtime behavior, production persistence, restart behavior, auto-start behavior, scheduled tasks, RunOnce entries, registry writes, services, production config, or module behavior.

## Owner-Approved Decisions

1. Resume after close/reopen:
   - AXIS should automatically return to the last saved step or page when the customer closes and reopens AXIS.

2. Auto-start after restart:
   - In production, AXIS should auto-start after restart only when the restart was expected or initiated by an AXIS step/script.
   - If the customer manually restarts the PC outside an expected AXIS restart flow, AXIS should not auto-start.
   - In that manual restart case, AXIS resumes only when the customer opens AXIS manually.

3. Completed setup behavior:
   - If the customer reached `final-completion` and opens AXIS again, AXIS should ask whether to start over.

4. Start over:
   - A future action/button is needed:
     - `ابدأ من جديد`

5. Saved progress:
   - Save both completed steps/pages and the current or last step/page.

6. `restart-after-installers`:
   - After `restart-after-installers`, resume to `restart-after-installers` marked complete.
   - The customer then presses Next manually to move to Graphics.
   - Do not auto-advance.

7. `driver-clean` and `defender-optimize-assistant`:
   - After an expected restart, they should resume back to the same step and continue the flow.

8. `intro-welcome`:
   - `intro-welcome` appears only the first time.
   - If saved progress exists, AXIS should not show `intro-welcome` by default.

9. `final-completion`:
   - `final-completion` saves that setup is complete.

## Future State Model

Future production state should track at minimum:

- `schemaVersion`
- `productName`: `AXIS`
- `currentPageId`
- `currentToolStepId`, if the current page is a tool step
- `currentStage`
- `completedPageIds`
- `completedToolStepIds`
- `isIntroCompleted`
- `isSetupCompleted`
- `reachedFinalCompletion`
- `lastUpdatedUtc`
- `restartExpected`
- `restartReason`
- `restartSourceStepId`
- `resumeTargetPageId`
- `resumeMode`
- `pendingContinuation`
- optional selector metadata needed later, such as a selected option for selector-driven steps

Important boundaries:

- Do not store secrets in wizard progress state.
- Do not store license keys in wizard progress state.
- Licensing and customer key design belong to the future Cloudflare website/platform phase.
- This blueprint does not implement licensing.

Suggested future production storage path:

- `%ProgramData%\AXIS\state.json`

This path is a future production storage idea only. The isolated prototype must not create `%ProgramData%\AXIS`, must not write production `state.json`, and must not use that path for preview resume testing.

## Resume Behavior

First launch with no state:

- Show `intro-welcome`.

Intro completed but no tool progress:

- Continue to `bios-information`.

Existing progress:

- Resume to `currentPageId` or the last saved page.

Current page complete:

- It is acceptable to show the completed page with Next enabled so the customer can continue.

Current page incomplete:

- Show the page incomplete with Next disabled until the step simulation or future runtime completes.

Final completion reached:

- Show a start-over prompt or choice.
- Do not automatically restart the wizard from the beginning.
- Do not auto-open a dashboard.
- Dashboard is permanently cancelled.

Manual app close/reopen:

- Resume to the last saved page.

Manual customer PC restart:

- Do not auto-start AXIS.
- Resume only when the customer opens AXIS manually.

Expected AXIS restart:

- In production, AXIS may auto-start after reboot only for expected AXIS restart flows.
- Resume according to `resumeTargetPageId` and `pendingContinuation`.

## Expected Restart Flows

`restart-after-installers`:

- Restart is expected.
- After restart, resume to `restart-after-installers` marked complete.
- The customer presses Next manually to enter Graphics.
- No auto-advance.

`driver-clean`:

- Restart may be expected as part of the real future tool flow.
- After restart, resume back to `driver-clean` and continue the flow according to future runtime integration.
- Prototype remains simulation-only.

`defender-optimize-assistant`:

- Restart may be expected as part of the real future tool flow.
- After restart, resume back to `defender-optimize-assistant` and continue the flow according to future runtime integration.
- Prototype remains simulation-only.

BIOS-related steps:

- `bios-settings` and `to-bios` may involve restart or firmware handoff in future production integration.
- Persistence should support resume targets for these flows.
- Exact runtime behavior is decided during production wiring.

No real restart flow is implemented or approved by this documentation-only phase.

## Future Auto-Start Strategy

Possible future production mechanisms:

- Scheduled Task
- RunOnce
- AXIS bootstrapper-specific resume mechanism

Rules:

- Auto-start should only be enabled for expected AXIS restart flows.
- Auto-start should not be enabled for arbitrary or manual customer restarts.
- The future implementation must clean up any one-time auto-start registration after successful resume.
- This phase does not implement Scheduled Tasks, RunOnce, startup entries, bootstrapper resume, registry writes, or any host mutation.

## Future Start-Over Behavior

When setup is complete and AXIS is launched again:

- Show a prompt asking whether to start over.
- Include the future customer-facing action:
  - `ابدأ من جديد`

Start-over should:

- Reset wizard progress.
- Clear completed steps/pages.
- Return to `intro-welcome` or the start of the flow according to future approved behavior.
- Not affect license status.
- Not affect website/account/key data.
- Not run any tool automatically.

Do not implement start-over UI unless a later phase explicitly requests it.

## Prototype Boundary

For the isolated prototype implementation:

- Use prototype-only temp-file state for visible preview testing.
- Default prototype state path:
  - `%TEMP%\AXIS\FirstUseWizardPrototypeState.json`
- Create the `%TEMP%\AXIS` folder only when saving prototype progress.
- Store only prototype wizard progress fields.
- Ignore invalid or corrupt prototype state and start at `intro-welcome`.
- Clear the prototype temp-file state when the approved start-over prompt primary action is used.
- Do not show the temp path, JSON, state details, diagnostics, or implementation details in normal customer UI.

This is not production persistence. It does not create or use `%ProgramData%\AXIS\state.json`.

The prototype boundary does not implement Scheduled Tasks, RunOnce, startup entries, bootstrapper resume, registry writes, or any host mutation. It does not restart, auto-start, run tools, or execute Apply, Default, Restore, Open, Analyze, or Restart behavior.

## Customer-Facing Restrictions

Normal AXIS customer UI must remain Arabic-only.

Do not show these in normal customer UI:

- BoostLab
- state file paths
- JSON
- diagnostics
- logs
- Registry details
- Scheduled Task details
- RunOnce details
- PowerShell details
- implementation details
- dashboard wording

## Relationship To Roadmap

This blueprint records roadmap phase 3 from `docs/design/AXIS-Product-Direction-Lock.md`.

- Persistence/resume comes after intro/final pages.
- Persistence/resume comes before converting prototype simulation to real runtime.
- Persistence/resume must be completed before production runtime wiring.

This document does not edit the product direction lock and does not change the roadmap order.

## Non-Implementation Boundary

This document does not approve or implement:

- production runtime state files
- `%ProgramData%\AXIS\state.json`
- registry keys
- scheduled tasks
- startup entries
- RunOnce entries
- service changes
- rebooting
- BIOS/UEFI opening
- live firmware queries
- `ui/MainWindow.ps1` integration
- runtime module behavior
- production config changes
- Apply, Default, Restore, Open, diagnostics, or result contract changes
