# Service State Capture and Rollback

## Purpose

Future BoostLab tools may stop or start services, change startup configuration, or in heavier cases create, delete, or reconfigure a service. A service command completing does not prove that the intended service was changed or that the prior state can be restored.

Phase 37 establishes a deny-by-default service state and rollback contract. It does not enable any deferred tool, approve any production service name, or contain a live Windows service mutation command.

## Production Files

* `config/ServiceRollbackPolicy.psd1` contains future exact service scopes.
* `core/ServiceState.psm1` validates scopes, captures structured service state, verifies state, and stores integrity-protected records.
* `core/ServiceRollback.psm1` validates record identity, age, scope, post-mutation state, and rollback eligibility before invoking a narrow mutation callback.

Production `ServiceScopes` are empty in Phase 37. No real Windows service is approved for capture or rollback.

The modules require caller-supplied service reader and mutator callbacks. Phase 37 tests use local in-memory callbacks only. The foundation does not call `Get-Service`, `Set-Service`, `Start-Service`, `Stop-Service`, `Restart-Service`, `New-Service`, `Remove-Service`, or `sc.exe`.

## Service Rollback Record Contract

Every service record contains:

* Operation id
* Tool id and action id
* Timestamp
* Schema version and BoostLab version
* Exact scope id
* Exact service name and display name
* Original existence
* Original running status
* Original startup type
* Original delayed auto-start state
* Original binary path
* Original service account
* Original dependencies
* Original description
* Original failure actions where available
* Intended mutation type
* Rollback eligibility
* Verification requirement
* Risk classification
* Recorded post-mutation state
* Rollback completion state

Records are saved below:

```text
$env:ProgramData\BoostLab\State\ServiceRollback
```

Each JSON record is wrapped with a SHA-256 integrity hash. Records outside the BoostLab service records directory are rejected.

## Exact Scope Rules

A future service-changing migration must add a tool-specific scope containing:

* Exact tool ids
* Exact service names
* Exact permitted mutation types
* Explicit startup/status restoration flags
* Explicit create, delete, and recreation flags

Wildcards, broad service selectors, unknown names, unapproved mutation types, and wrong tool identities are denied.

Core Windows services listed in `ProtectedServiceNames` are denied by default. A future phase must not remove that protection casually. Any exception requires an exact service scope, source evidence, migration-record approval, strong confirmation, verification, and recovery design.

## Capture Before Mutation

Service state must be captured before the approved mutation. Capture records read-only state for the exact approved service name.

Rollback eligibility is conservative:

* The original service must exist.
* The mutation must be limited to start, stop, enable, disable, or startup-type change.
* The scope must explicitly allow restoration of startup type, delayed auto-start, or running status.
* Service creation, deletion, recreation, and arbitrary configuration rollback are not enabled by Phase 37.

After the approved tool changes the service, it must record the complete post-mutation service snapshot. Rollback is blocked until that snapshot exists.

## Verification

Read-only verification supports:

* Service existence
* Exact service name
* Display name
* Running status
* Startup type
* Delayed auto-start state where available
* Binary path
* Service account
* Dependencies
* Description
* Failure actions where available

Unavailable optional properties may produce `Warning`. A contradictory detected value produces `Failed`.

Rollback requires the current service state to match the recorded post-mutation state exactly. This prevents BoostLab from overwriting a later administrator or Windows change.

## Rollback Gates

Rollback is blocked when:

* The record is missing, corrupt, outside the state root, hash-mismatched, or stale.
* Tool id, action id, scope id, service name, or intended mutation does not match.
* The exact service is no longer approved by policy.
* The record is not rollback eligible.
* Post-mutation state was not recorded.
* Current state differs from recorded post-mutation state.
* Service identity differs, including binary path, service account, or dependencies.
* The original service did not exist.
* The operation would require service creation, deletion, or recreation.
* Unsupported configuration fields changed.

When all gates pass, the mutation plan may restore only the explicitly approved startup type, delayed auto-start setting, and running status. Restoration is verified against the complete captured original state. Failures return structured `Blocked` or `Failed` results and are never silently ignored.

## Default Versus Rollback

`Default` remains the source-approved default behavior of a tool.

Service rollback returns one exact service to state captured before one BoostLab operation. It must not infer a default, enumerate all services, or apply an optimizer preset.

## Deferred Tools Helped Later

This foundation is relevant to:

* Edge Settings
* Installers
* Driver Install Debloat & Settings
* Bloatware
* GameBar
* Edge & WebView
* Control Panel Settings
* Timer Resolution Assistant
* Defender Optimize Assistant

Those tools remain deferred. Depending on the source behavior, they still require one or more of:

* Download provenance and installer execution approval
* AppX/package inventory and restore
* TrustedInstaller execution
* Safe Mode resume/recovery
* Driver rollback
* File/registry rollback scopes
* Destructive cleanup governance
* Reboot and interrupted-workflow recovery
* Explicit approval for service creation, deletion, protected services, or broad multi-service plans

Phase 37 does not satisfy those additional requirements and does not wire service rollback into any tool.
