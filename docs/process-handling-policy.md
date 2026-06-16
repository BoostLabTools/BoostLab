# Process Handling Policy Foundation

## Purpose

Phase 68 defines how BoostLab will later govern process handling operations
before any tool can detect, wait for, close, stop, restart, or hand off to a
process.

This foundation is policy-only and runtime-inert. It does not stop, start,
kill, restart, launch, or manipulate any real process. It approves no process
target, no production process scope, no deferred tool behavior, and no visible
process action.

Process handling is high-friction on purpose because a process can represent
unsaved user work, shell state, security software, services, installers, or a
multi-stage workflow. Future implementations must prove exact source mapping,
exact target identity, confirmation, verification, and recovery expectations
before execution.

## Relationship To Existing Foundations

This foundation connects to earlier BoostLab safety layers:

* **Phase 35 download and installer execution:** `LaunchHandoff` involving an
  external executable must use approved artifact provenance and execution
  descriptors before it can run.
* **Phase 36 file and registry rollback:** process handling that exists to
  apply file or registry changes must reference the associated capture records.
* **Phase 37 service rollback:** service-related processes must not be treated
  as ordinary user processes when service state is also changing.
* **Phase 40 reboot/recovery:** process handling that is part of a resume,
  handoff, or shell-disruptive workflow must reference approved workflow rules.
* **Phase 42 TrustedInstaller:** process handling that requires
  TrustedInstaller must be target-specific, confirmed, logged, and approved by
  the TrustedInstaller foundation.
* **Phase 43 Safe Mode:** process handling inside Safe Mode or a resume flow
  must use approved Safe Mode workflow records.
* **Phase 66 production allowlist governance:** future process scopes require
  exact source-linked production allowlist approval before runtime can use them.
* **Phase 67 Restore selection:** process state itself is generally not
  Restore. If a process operation supports a later Restore path, Restore must
  be tied to captured file, registry, package, service, driver, or workflow
  records rather than the stopped process alone.

## Process Operation Types

Future process proposals must use one of these operation categories:

* `DetectOnly`
* `WaitForExit`
* `GracefulClose`
* `StopProcess`
* `RestartProcess`
* `LaunchHandoff`
* `ExplorerRestart`
* `ToolOwnedProcessCleanup`

Phase 68 does not approve production mutation for any of these categories.

`DetectOnly` is non-mutating and may be reviewed by the inert helper when all
metadata is complete and the proposal is not tied to deferred production use.
Every mutating production operation remains `NotApproved` or `Denied`.

## Required Process Metadata

Every future process handling proposal must include:

* `ToolId`
* `ToolName`
* `SourcePath`
* `SourceChecksum`
* `DesignReviewDocument`
* `SourceBehaviorGroup`
* `ProcessOperationType`
* `ExactProcessName`
* `ExactExecutablePathRequirement`
* `PublisherSignatureRequirement`
* `UserSessionScope`
* `OwnershipModel`
* `IsToolOwnedProcess`
* `UnsavedUserDataRisk`
* `ConfirmationLevel`
* `PreflightVerification`
* `PostOperationVerification`
* `TimeoutBehavior`
* `RetryBehavior`
* `RollbackRecoveryFeasibility`
* `ActionPlanTextRequirement`
* `ActivityLogTextRequirement`
* `RiskLevel`
* `ApprovalStatus`
* `DenialReason`

Missing metadata blocks eligibility. Vague metadata blocks eligibility. A
proposal that cannot be traced to a current tool design or review remains
denied.

## Hard Denial Rules

Process handling must be denied when it uses or requires:

* Wildcard process names.
* Broad process-stop patterns.
* Stopping all processes from a vendor without exact names.
* Stopping system-critical processes.
* Stopping security processes without explicit security-sensitive approval.
* Stopping shell or Explorer without exact `ExplorerRestart` policy.
* Stopping browser processes broadly without exact tool-specific design and
  confirmation.
* Killing processes by PID only without identity validation.
* Killing processes without user/session validation.
* Force-kill before a graceful path when graceful close is required.
* Restarting processes without exact executable path and approval.
* Launch handoff without provenance or execution descriptor if an external
  executable is involved.
* Process handling that requires TrustedInstaller, Safe Mode, reboot,
  installer, download, service mutation, or driver mutation without those
  foundations approving the adjacent behavior.
* Process handling for deferred tools without production allowlist approval.
* Operations that could lose unsaved user data without explicit warning and
  confirmation.
* Ambiguous process matches.
* A process target not present in the tool's design document.

## ExplorerRestart Handling

ExplorerRestart is a special future category.

It may be used only when a tool specifically requires Explorer restart or shell
refresh behavior in its approved Ultimate source and design document. It must
require explicit confirmation, describe taskbar, Start menu, shell, and open
Explorer-window side effects, and verify Explorer returns if restart is later
attempted.

No Explorer restart, force-stop, or shell process scope is enabled by Phase 68.

## ToolOwnedProcessCleanup Handling

ToolOwnedProcessCleanup is a future low-risk category for processes that
BoostLab itself created.

It may be considered only when BoostLab owns the process handle or exact
launched artifact descriptor. It must not be confused with external user
processes, installer processes, browser processes, service processes, shell
processes, or vendor processes. It still requires logging, verification, and
bounded timeout behavior.

No tool-owned process cleanup is enabled for deferred tools in Phase 68.

## UI And Runtime Requirements

Future UI and runtime behavior must:

* Show exact process names and operation type in the Action Plan.
* Show executable path, publisher/signature requirement, user/session scope,
  ownership model, timeout, retry, and verification expectations when relevant.
* Warn clearly when unsaved user work or shell side effects are possible.
* Show ineligible process operations as denied with a reason.
* Require confirmation before mutation.
* Activity Log must show what was planned, skipped, denied, attempted, or
  completed.
* Include structured process operation results in Latest Result.

Toast or short status messages must not replace detailed process results.

## Runtime Helper Behavior

`core/ProcessHandlingPolicy.psm1` is deny-by-default and non-mutating.

The helper functions may:

* Load and validate the process handling policy.
* Validate fake or future process proposal objects.
* Return structured `Eligible`, `Reviewed`, `Denied`, `NotApproved`,
  `Invalid`, or `NotApplicable` style results.
* Build an inert plan result that never executes.

The helper functions must not:

* Stop, start, kill, restart, launch, or wait on real processes.
* Call `Stop-Process`, `taskkill`, `Start-Process`, `Restart-Computer`,
  `shutdown`, `sc.exe`, service APIs, TrustedInstaller, Safe Mode, AppX,
  driver, installer, download, registry, file, cleanup, RunOnce, Active Setup,
  BHO, or generated-script operations.
* Require Administrator for mock validation.
* Mutate protected system state.
* Approve deferred tool process handling.

## Deferred Tool Impact

This foundation reduces one shared blocker for tools that mention process
handling, including Copilot, Start Menu Taskbar, GameBar, Edge Settings, Edge &
WebView, Control Panel Settings, Defender Optimize Assistant, Services
Optimizer, and Driver Install Debloat & Settings.

It does not make those tools ready. They still require exact production
allowlists, artifact provenance, scheduled task governance, TrustedInstaller
scope approval, Safe Mode workflow approval, reboot workflow approval, AppX
scopes, service scopes, cleanup scopes, driver scopes, generated-script
ownership, RunOnce/Active Setup/BHO governance, or Restore selection depending
on the tool.

No deferred placeholder is enabled by Phase 68.

## Phase 68 Production State

Phase 68 creates process handling governance and inert validation helpers only.

* Production process scopes: **0**
* Approved process targets: **0**
* Deferred tools enabled: **0**
* Visible process action buttons added: **0**
* Runtime tool behavior changes: **0**
* Real process operations: **0**
* Protected system mutations: **0**

The current deferred queue snapshot remains tracked in
`docs/final-deferred-tools-readiness-matrix.md`.

## Recommended Next Phases

1. **Scheduled Task State Capture / Rollback Foundation**
   Required by Edge Settings, Control Panel Settings, Defender Optimize
   Assistant, and installer-style workflows.
2. **Generated Script / Temp Artifact Ownership Policy**
   Required before generated `.reg`, `.ps1`, `.cmd`, `.xml`, `.nip`, C#,
   binary, or extraction artifacts can be approved.
3. **RunOnce / Active Setup Governance**
   Required before persistent startup or post-reboot repair behavior can be
   approved.
