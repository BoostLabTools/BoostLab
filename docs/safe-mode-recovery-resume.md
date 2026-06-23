# Safe Mode Recovery and Resume Foundation

## Purpose

Safe Mode is not just another restart. A tool can leave Windows in a restricted
boot state where normal services, networking, UI components, or BoostLab itself
may be unavailable. Entry without a known continuation and exit path can strand
the technician or leave a partially completed high-risk operation.

Phase 43 creates a centralized, deny-by-default contract for future controlled
Safe Mode workflows. It does not approve a production scope, edit BCD, enter
Safe Mode, reboot, create RunOnce entries or Scheduled Tasks, create or change
services, invoke TrustedInstaller, or modify protected registry/file targets.

## Production Files

* `config/SafeModeRecoveryPolicy.psd1` contains future exact tool/action scopes.
* `core/SafeModeWorkflow.psm1` validates plans, stores integrity-protected
  records, validates resume and exit state, handles cancellation, and persists
  structured post-resume verification.
* `core/SafeModeExecution.psm1` revalidates future-shaped requests but returns
  only `Blocked` or `NotImplemented`.

Production `SafeModeScopes` are empty. Therefore no current or deferred tool can
request Safe Mode through this foundation.

## Required Workflow Record

Every future record must contain:

* Operation, tool, and action identity
* Timestamp, schema version, and BoostLab version
* Exact policy scope id
* Requested type: Minimal, Networking, or separately approved Command Shell
* Reason and High risk classification
* Explicit confirmation requirement
* Passed pre-Safe-Mode checkpoints with evidence
* Verified state-capture references for every required adjacent foundation
* A verified Phase 40 `SafeModeReboot` workflow reference
* Ordered bounded resume steps
* Ordered bounded exit strategy
* Post-resume verification requirements
* Expiration and cancellation eligibility
* Human-readable recovery instructions and warning text
* Workflow, entry, resume, exit, cancellation, and verification status

Records are stored under:

```text
$env:ProgramData\BoostLab\State\SafeModeRecovery\Records
```

Each record is wrapped in a SHA-256 integrity envelope. Missing, corrupt,
expired, stale, mismatched, incomplete, or cancelled records are refused.

## Policy Scopes

A future scope must declare:

* Exact tool and action ids
* Allowed Safe Mode types
* Required checkpoint names and foundation references
* Trusted state-record and Phase 40 reboot-record roots
* Exact resume and exit handler ids
* Exact trusted local resume and exit artifact paths
* Mandatory state capture, reboot reference, exit plan, and verification
* Maximum resume steps, exit steps, and duration
* Cancellation and Command Shell permissions
* Explicit confirmation requirement

Wildcards, broad identities, unknown handlers, network paths, URI paths, and
path traversal are denied.

## Planning

A plan is allowed only when all of the following are true:

1. Tool, action, scope, and Safe Mode type match an exact allowlist.
2. A matching Action Plan declares `UsesSafeMode` and requires confirmation.
3. Explicit confirmation was recorded.
4. Every required checkpoint passed and contains evidence.
5. Every required adjacent-foundation state record is verified and trusted.
6. A matching verified Phase 40 `SafeModeReboot` workflow record exists.
7. Resume steps are known, ordered, bounded, and policy-approved.
8. An exit strategy is known, ordered, bounded, and policy-approved.
9. Post-resume verification, expiration, warning, and recovery text exist.

No plan may describe an entry that lacks a documented exit path.

## Resume and Exit

Resume and exit steps are data records, not shell commands. They may contain an
exact handler id, order, description, exact trusted local artifact path,
expected conditions, and verification requirements. Exit steps also carry
recovery instructions.

They may not contain:

* Command or command-line text
* Executable names or paths
* Arguments
* Scripts or script blocks
* URLs or network paths
* Dynamically supplied shell content

Before a resume or exit plan is accepted, a caller-supplied read-only validator
must confirm that current machine state matches the recorded expectations. A
mismatch blocks continuation and preserves the recovery instructions.

## Cancellation and Failure

Cancellation persists the reason and timestamp, marks the record `Cancelled`,
and permanently blocks later resume.

A failed resume does not silently continue. A failed post-resume verification
marks the workflow `Failed`, returns a structured result, and keeps recovery
instructions visible.

The exit plan exists before entry. Future execution must never rely on
best-effort cleanup or an improvised command after Windows is already in Safe
Mode.

## Normal Reboot Versus Safe Mode

Phase 40 owns generic reboot and post-reboot workflow state. It distinguishes
normal, firmware, Safe Mode, manual, and resume scenarios, but it does not
define Safe Mode-specific continuation or exit behavior.

Phase 43 requires a verified Phase 40 Safe Mode reboot reference and adds:

* Exact Safe Mode type
* In-mode resume handlers
* Mandatory exit strategy
* Safe Mode machine-state validation
* Safe Mode-specific recovery and verification

Both scopes are required for a future Safe Mode tool.

## Relationship to Other Foundations

Safe Mode does not broaden any adjacent foundation:

* File/registry rollback owns exact captured file and registry state.
* Service rollback owns exact service state and permitted restoration.
* AppX restore owns exact package inventory and captured restore sources.
* Cleanup policy owns bounded delete/quarantine targets.
* Driver rollback owns exact device/package identity and rollback evidence.
* Download provenance and installer policy own artifacts and execution approval.
* TrustedInstaller policy owns narrowly scoped privileged sub-operations.
* Phase 40 owns reboot workflow records and future reboot execution.

A future tool must supply every foundation record required by its approved
Ultimate behavior. Safe Mode workflow state cannot substitute for them.

## Inert Execution Boundary

The Phase 43 execution helpers always report:

* `SafeModeConfigured = false`
* `BcdModified = false`
* `RebootInitiated = false`
* `ScheduleCreated = false`
* `ServiceChanged = false`
* `TrustedInstallerUsed = false`
* `ProtectedTargetModified = false`

Structurally invalid requests return `Blocked`. Structurally valid future-shaped
requests return `NotImplemented`. Neither result performs a system operation.

## Why Heavy Tools Remain Blocked

Defender Optimize Assistant, Updates Drivers Block, Driver Install Debloat &
Settings, and similar multi-stage tools remain blocked.
Phase 43 provides only the common safety contract. Each tool still needs:

* Exact production Safe Mode and Phase 40 scopes
* Exact service, security, driver, file/registry, AppX, cleanup, provenance, and
  TrustedInstaller scopes required by its source
* A separately approved entry/resume/exit implementation
* Tool-specific recovery and interrupted-run tests
* A migration record approved by Yazan

The foundation prevents guessing; it does not authorize partial migration.
