# Reboot and Recovery Workflow Foundation

## Purpose

A reboot can interrupt the process that requested it. Without persisted
checkpoints, recovery instructions, bounded resume steps, and post-reboot
verification, BoostLab cannot safely decide whether work completed, should
resume, should stop, or should roll back.

Phase 40 establishes a deny-by-default workflow contract for future normal,
firmware, Safe Mode, manual, and post-reboot continuation scenarios. It does
not approve a production scope, restart Windows, write RunOnce, create a
Scheduled Task, edit BCD, enter Safe Mode, alter Windows Recovery Environment,
or enable a deferred tool.

Phase 43 adds a separate Safe Mode-specific policy boundary. A future Safe Mode
tool must satisfy both foundations: Phase 40 owns the reboot record, while
Phase 43 requires Safe Mode type approval, bounded in-mode resume handlers, a
mandatory exit plan, machine-state validation, and Safe Mode recovery guidance.

## Production Files

* `config/RebootRecoveryPolicy.psd1` contains future exact workflow scopes.
* `core/RebootWorkflow.psm1` validates scopes, plans workflows, stores
  integrity-protected records, validates resume state, handles cancellation,
  and persists post-reboot verification.
* `core/RebootExecution.psm1` validates future execution requests but returns
  `NotImplemented` for reboot and resume scheduling in Phase 40.

Production `WorkflowScopes` are empty. Every production request is blocked
until a future approved tool phase adds an exact tool/action scope.

## Workflow Model

Each plan and record identifies:

* Operation id
* Tool id and action id
* Timestamp
* Schema version and BoostLab version
* Exact policy scope id
* Requested reboot type
* Reboot reason
* Risk classification
* Required confirmation level
* Pre-reboot checkpoints and evidence
* Required state-capture references
* Ordered pending resume steps
* Post-reboot verification requirements
* Expiration
* Cancellation eligibility
* Human-readable recovery instructions
* User-visible warning text
* Workflow, cancellation, reboot, resume, and verification status

Records are stored under:

```text
$env:ProgramData\BoostLab\State\RebootRecovery\Records
```

Every record is wrapped with a SHA-256 integrity value. Missing, corrupt,
expired, stale, mismatched, out-of-scope, or cancelled records are refused.

## Exact Scope Rules

A future scope must declare:

* Exact tool ids and action ids
* Allowed reboot types
* Required checkpoint names
* Trusted state-reference roots
* Exact resume handler ids
* Exact trusted resume artifact paths
* Whether state capture is mandatory
* Whether immediate reboot or resume scheduling is permitted
* Separate firmware and Safe Mode permissions
* Maximum resume-step count and workflow duration
* Cancellation policy
* Confirmation level and explicit-confirmation requirement

Unknown tools, actions, scopes, reboot types, handlers, artifacts, and state
roots are blocked. Wildcards and broad identities are not allowed.

Adding a scope does not implement a reboot. A future migration must still
preserve approved Ultimate behavior, use the foundation explicitly, document
recovery, and pass tool-specific tests.

## Reboot Planning

Planning requires:

1. Exact tool/action/scope approval.
2. A matching BoostLab Action Plan.
3. Explicit user confirmation.
4. Every required checkpoint in `Passed` state with readable evidence.
5. Every required state record marked verified, integrity identified, and
   located under an approved state root.
6. A bounded, predeclared resume-step list.
7. Post-reboot verification requirements.
8. An approved expiration.
9. Readable recovery instructions and warning text.

The model distinguishes:

* **Immediate reboot:** Windows would be asked to restart after every gate
  passes. Phase 40 does not perform it.
* **Manual reboot required:** the technician is told to reboot, but BoostLab
  does not issue a request.
* **Post-reboot resume:** continuation is considered only from a valid
  persisted record and bounded handler list.

Firmware and Safe Mode reboot require separate policy flags. Generic reboot
permission does not imply either one.

## Resume Steps

Resume steps are data, not command strings. Each step contains:

* Exact step id
* Positive unique order
* Exact policy-approved handler id
* Human-readable description
* Optional exact trusted artifact path
* Expected machine conditions
* Verification requirements

Resume steps may not contain executable names, command lines, arguments,
scripts, script paths, URLs, or dynamic command fields. Future runtime code
must dispatch a known handler implemented in reviewed production code.

Resume is refused when:

* The record is missing, corrupt, expired, stale, mismatched, or cancelled.
* The workflow is not in `PendingResume`.
* Required checkpoints or state records are absent.
* The step list is empty, too large, duplicated, or unapproved.
* A handler or artifact path is not allowlisted.
* Current machine state no longer matches expected conditions.

Refusal preserves the recorded recovery instructions. Failed resume must not
silently continue with later steps.

## Cancellation and Recovery

Cancellation is available only when both policy and record permit it.
Cancellation:

* Persists the timestamp and reason.
* Sets workflow status to `Cancelled`.
* Blocks every later resume attempt.
* Preserves readable recovery instructions.

Cancellation does not reverse changes already made. Rollback remains governed
by the foundation that owns the affected file, registry value, service,
package, driver, or cleanup target.

Post-reboot verification accepts structured `Passed`, `Warning`, or `Failed`
results. Failure stores `Failed`, returns a Latest Result-style object, keeps
recovery instructions visible, and does not continue silently.

## Non-Executing Boundaries

`Invoke-BoostLabRebootRequest` and
`Register-BoostLabPostRebootResume` revalidate policy and confirmation, but
return `NotImplemented` in Phase 40.

The foundation contains no built-in call to:

* `shutdown.exe` or `Restart-Computer`
* RunOnce registry writes
* Scheduled Task creation
* `bcdedit`
* Safe Mode configuration
* Firmware restart commands
* Windows Recovery Environment configuration

Existing separately approved BIOS Settings and To BIOS behavior is not rewired
or changed by Phase 40.

## Relationship to Other Foundations

### Action Plan

Every reboot-capable operation requires an Action Plan and explicit
confirmation. The reboot workflow adds persistent recovery and continuation
state; it does not replace the user-facing plan.

### File and Registry Rollback

File and registry records may be required checkpoints before reboot. Their
integrity and restore rules remain owned by the Phase 36 foundation.

### Service Rollback

Multi-stage service workflows must capture exact service state before reboot
and verify it again before resume. Phase 40 does not broaden service scopes.

### AppX Restore

Package workflows must retain exact AppX inventory records and verify package
state before any post-reboot step. Reboot state does not authorize package
mutation or broad re-registration.

### Cleanup

Cleanup or quarantine performed before reboot must use its exact Phase 38
scope and record. Resume must not infer that incomplete cleanup may be retried
broadly.

### Downloads and Installers

Artifacts remain subject to provenance, signer, hash, command-line, and
installer policy. A reboot record cannot authorize an unknown executable or
untrusted path.

## Why Deferred Tools Remain Blocked

This foundation is relevant to:

* Reinstall
* Updates Drivers Block
* Driver Install Debloat & Settings
* Resizable BAR Assistant
* Services Optimizer
* Defender Optimize Assistant
* Other future reboot-capable workflows

They remain deferred because Phase 40 approves no production scopes and they
still require exact download/installer approvals, driver rollback,
TrustedInstaller, Safe Mode recovery, service recovery, security governance,
or tool-specific state and verification plans.

Phase 40 is a prerequisite, not permission to implement a partial workflow that
would weaken approved Ultimate behavior.
