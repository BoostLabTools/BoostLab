# BoostLab Runtime Foundation

Phase 4 introduced the shared runtime services used by BoostLab tools. The runtime does not execute scripts from `source-ultimate`; approved production behavior lives in individual modules.

## Runtime Modules

### Logging

`core/Logging.psm1` provides structured logging for the GUI and runtime.

Supported levels:

* Info
* Warning
* Error
* Success
* Debug

Each log entry contains a timestamp, level, source, event ID, message, and optional structured data. Entries are retained in memory so the Activity Log can receive them through a registered log sink.

File logs are written as JSON Lines under:

```text
$env:ProgramData\BoostLab\Logs
```

The directory is created when logging is initialized. Common secret-bearing field names and message patterns are redacted. Callers must still avoid passing credentials, tokens, personal data, or other sensitive values to the logging API.

### Environment

`core/Environment.psm1` detects:

* Administrator status
* Internet connectivity
* Windows product name, edition, display version, build, and revision
* PowerShell version and edition
* Operating system and process architecture
* Common pending reboot indicators

Internet detection first uses a lightweight HTTPS request with timeout handling. A TCP connection check is used only as a fallback; ping is not required.

Pending reboot detection is read-only. It checks common Windows servicing, Windows Update, and pending file rename indicators without restarting the computer.

### Privileged Execution

BoostLab uses an application-level Administrator model. `bootstrap.ps1` requests elevation before launching the application, and `Start-BoostLab.ps1` repeats the check so direct launch cannot bypass the requirement. An elevation-attempt marker prevents an infinite relaunch loop.

Tool-level `RequiresAdmin` metadata still describes the approved behavior of the tool itself. Before dispatching an implemented action with `RequiresAdmin = true`, `core/Execution.psm1` verifies that the current process is elevated and returns a structured blocked result when it is not.

`config/TrustedInstallerPolicy.psd1` is the deny-by-default allowlist for future narrowly scoped TrustedInstaller requests. Phase 42 leaves production scopes empty.

`core/TrustedInstaller.psm1` validates exact tool/action/command identities, structured argument tokens, local executable/helper identity, working directory, exact targets, Action Plan confirmation, Administrator host status, required adjacent-foundation records, verification plans, timeout, logging, risk, and recovery behavior.

`core/TrustedInstallerExecution.psm1` is deliberately inert. Valid future-shaped requests return `NotImplemented`; invalid requests return `Blocked`. Both paths report `ProcessStarted = false` and `CommandExecuted = false`. BoostLab never runs the complete application as TrustedInstaller.

### Download Provenance and Installer Execution

`config/ArtifactProvenance.psd1` is the centralized allowlist for future downloaded artifacts. Phase 35 intentionally leaves the production artifact list empty.

`core/DownloadProvenance.psm1` validates manifest records and local files. It checks artifact identity, approval state, expected file name, SHA-256, size constraints, and Authenticode publisher requirements for executable content. Unknown artifacts and failed verification are blocked. The module has no network command and cannot download a file.

`core/InstallerExecution.psm1` validates future installer requests against a verified provenance result, matching tool/action identity, an explicit Action Plan, confirmation, exact command line, and timeout policy. Its Phase 35 execution function always returns `NotImplemented` or `Blocked` and never starts a process.

This foundation is deliberately disconnected from current tools. It defines the security contract required before any deferred downloader or installer migration can begin.

### File and Registry State Capture

`config/RollbackPolicy.psd1` is the centralized allowlist for future file and registry capture scopes. Phase 36 leaves both production scope collections empty.

`core/StateCapture.psm1` validates exact tool/scope/path identity, captures original existence and metadata, creates hash-verified file backups, and saves integrity-protected rollback records under:

```text
$env:ProgramData\BoostLab\State\Rollback
```

File scopes reject wildcards, broad system roots, reparse points, and paths outside the approved root. Directory scopes require explicit file-count and byte limits. Registry scopes require an exact approved key and, for values, an exact approved value name. Broad hives and protected `HKLM\SYSTEM` paths are denied by default.

`core/Rollback.psm1` restores only from a valid BoostLab record after the current target matches the recorded post-mutation state. File backups must match both the captured original hash and backup hash. Registry rollback uses explicit reader, writer, and remover boundaries so a future tool can keep operations narrowly scoped and testable.

These helpers are not imported by `core/Execution.psm1` and are not wired to any tool. A future approved migration must add an exact production scope and call the helpers explicitly.

### Service State Capture and Rollback

`config/ServiceRollbackPolicy.psd1` is the deny-by-default allowlist for future service-changing tools. Phase 37 leaves `ServiceScopes` empty.

`core/ServiceState.psm1` defines exact-name scope validation, integrity-protected service records, read-only state verification, and capture through an injected service reader. Records include original existence, status, startup type, delayed auto-start, binary path, account, dependencies, description, failure actions where available, mutation intent, rollback eligibility, and risk.

`core/ServiceRollback.psm1` requires a valid non-stale record, matching tool/action/scope/service identity, recorded post-mutation state, and current-state verification. Its approved mutation plan can restore only startup type, delayed auto-start, and running status when the scope explicitly allows those fields.

The service helpers contain no live Service Control Manager command and are not imported by `core/Execution.psm1` or any tool module. Service creation, deletion, recreation, arbitrary configuration restoration, protected-service handling, TrustedInstaller, Safe Mode, and reboot recovery remain outside the Phase 37 boundary.

### Destructive Cleanup and Quarantine

`config/CleanupPolicy.psd1` is the deny-by-default allowlist for future destructive cleanup. Phase 38 leaves `CleanupScopes` empty.

`core/CleanupPolicy.psm1` validates exact bounded targets, rejects broad or unsafe paths, performs read-only file/directory inspection, builds cleanup plans, validates Phase 36 state-capture evidence, and stores integrity-protected quarantine records.

`core/CleanupExecution.psm1` requires a matching Action Plan, explicit confirmation, any required state-capture evidence, and structured post-operation verification. Permanent deletion, quarantine, and quarantine restore are callback-only boundaries; the module contains no built-in destructive command.

These helpers are not imported by `core/Execution.psm1` and are not wired into a tool. Future migrations must add exact production scopes and still satisfy AppX, service, driver, TrustedInstaller, Safe Mode, installer, registry, reboot, or ownership requirements that apply to the source.

### Driver State Capture and Rollback

`config/DriverStatePolicy.psd1` is the deny-by-default allowlist for future
driver operations. Phase 41 leaves `DriverScopes` empty.

`core/DriverState.psm1` validates exact tool, action, device instance,
hardware, vendor, mutation, and driver-package identities. Inventory records
preserve provider/version/date, INF and published names, device status and
problem code, associated services/files, source-store location, provenance
evidence, reboot workflow references, related state records, verification
requirements, and rollback eligibility.

`core/DriverExecution.psm1` provides callback-only mutation and rollback
boundaries for local mocked validation. It requires a policy-approved dry-run
plan, matching Action Plan, explicit confirmation, structured verification,
and persisted post-operation state. The module contains no built-in driver,
PnP, DISM, installer, device-state, or package-removal command.

Install/update planning requires verified Phase 35 provenance. Reboot-capable
mutations require a verified Phase 40 workflow reference. Associated file,
registry, service, AppX, installer, or cleanup work remains governed by its
own foundation. The driver helpers are not imported by
`core/Execution.psm1` and are not wired into a tool.

### Safety

`core/Safety.psm1` contains structured safety functions for:

* Risk confirmation
* Restore point requests
* High-risk action gating
* Action Plan confirmation callback gating
* Restart requirement descriptions

Safety functions return assessment objects only. The UI owns presentation of confirmation prompts. Safety functions do not create restore points, change Windows, or restart the computer.

### Action Planning

`core/ActionPlan.psm1` builds conservative Action Plan objects from catalog metadata and capabilities.

Plans describe the requested action, risk, possible changes, side effects, privilege and internet requirements, restart capability, confirmation requirement, Default and Restore support, and dry-run status. Planning does not execute module behavior.

Plans expose Administrator, TrustedInstaller, and Safe Mode requirements explicitly. TrustedInstaller capability always requires confirmation and an elevated privileged-execution warning.

The WPF UI may receive a plan through the runtime confirmation callback and display a reusable Confirm/Cancel dialog. Safe Open-only actions do not request confirmation. Placeholder actions receive dry-run plans but remain non-executing.

### State

`core/State.psm1` tracks:

* Current stage and status
* Per-tool status
* Last requested action
* Last result
* Restart required state

Runtime state is stored as JSON under:

```text
$env:ProgramData\BoostLab\State\runtime-state.json
```

The state directory is created during initialization. State persistence contains runtime status only and must not be used for passwords, tokens, credentials, or other sensitive data.

### Execution

`core/Execution.psm1` provides the shared entry point:

```powershell
Invoke-BoostLabToolAction -ToolMetadata $tool -ActionName $action
```

The execution pipeline:

1. Validates required tool metadata and the requested action.
2. Builds an Action Plan from risk and capability metadata.
3. Determines whether an implemented non-Analyze action requires confirmation.
4. Invokes the optional UI confirmation callback when required.
5. Blocks an implemented action when required confirmation is absent or declined.
6. Dispatches only actions present in the approved implementation allowlist.
7. Attaches the Action Plan to the structured result.
8. Logs and persists the result state.

The result includes:

* `Success`
* `ToolId`
* `ToolTitle`
* `Action`
* `Message`
* `RestartRequired`
* `ActionPlan`
* `Timestamp`

Read-only assistant analysis may also include a structured `Data` payload.

Tools without an approved implementation continue to return `Action not implemented yet`. Implemented modules are loaded only through the runtime allowlist; no legacy script is invoked.

## Target Execution Lifecycle

Stronger tools must eventually use this mandatory lifecycle:

```text
Preflight -> Plan -> Confirm -> Checkpoint -> Execute -> Verify -> Persist -> Restart or Rollback
```

* **Preflight** validates metadata, capabilities, privileges, compatibility, dependencies, and environment state.
* **Plan** produces a reviewable description of intended commands and side effects.
* **Confirm** obtains explicit approval when required by risk or capability metadata.
* **Checkpoint** captures the state required for an approved Default or Restore path.
* **Execute** runs only the approved module behavior.
* **Verify** checks the effective result rather than assuming command success.
* **Persist** records the action, result, captured state, and restart requirement.
* **Restart or Rollback** performs only an approved, confirmed continuation or recovery path.

This lifecycle is the target governance model and is not fully implemented yet. Phase 11 implements the Plan and reusable Confirm boundary. Capability metadata and migration records define the information the future pipeline must enforce. No stronger tool should be enabled merely because a module exists.

## GUI Integration

The GUI passes the selected tool metadata, action name, and a confirmation callback to `Invoke-BoostLabToolAction`. The callback is invoked only when an implemented action requires confirmation. Latest Result displays returned Action Plans and structured action details.

Header status indicators use the environment snapshot produced by `Get-BoostLabEnvironmentInfo`.

## Current Safety Boundary

The current runtime does not:

* Execute Ultimate scripts
* Implement registry, service, driver, installer, cleanup, Defender, or security changes
* Create restore points
* Download content
* Launch third-party installers through the Phase 35 policy helpers
* Capture or restore file/registry state without a future approved scope and explicit tool call
* Capture or restore service state without a future approved exact service scope and explicit tool call
* Perform destructive cleanup or quarantine without a future approved exact cleanup scope and explicit tool call
* Inspect, remove, re-register, repair, or restore AppX packages without a future approved exact package scope, inventory record, confirmation, and explicit tool call
* Request reboot, schedule post-reboot resume, alter boot state, or continue a workflow without a future approved exact reboot scope and integrity-verified workflow record
* Inventory, install, update, uninstall, disable, enable, remove, profile-import, debloat, or roll back a driver without a future exact driver scope and integrity-verified record
* Execute a TrustedInstaller command without a future exact scope and separately approved execution implementation
* Enforce licenses

BIOS Settings retains its previously approved, explicitly confirmed firmware restart action. No new reboot behavior is introduced by the planning framework.

`source-ultimate` remains an untouched legacy reference. Future production tool logic must follow the Script Migration Policy in `CODEX_INSTRUCTIONS.md`, have an approved migration record, and live under `modules/`.

## AppX Package Foundation

`core/AppxPackageInventory.psm1` and `core/AppxPackageExecution.psm1` establish
the future package lifecycle:

```text
Exact scope -> Inventory -> Plan -> Confirm -> Mutate -> Verify -> Persist
```

Restore adds record validation and exact captured manifest/install-location
checks before execution. Production package scopes are empty, the helpers are
not imported by `core/Execution.psm1`, and execution is callback-only. Phase 39
does not call package cmdlets, DISM, downloads, installers, or deferred modules.

## Reboot and Recovery Foundation

`core/RebootWorkflow.psm1` and `core/RebootExecution.psm1` establish the future
workflow:

```text
Scope -> Plan -> Confirm -> Checkpoint -> Persist -> Reboot or Manual Pause
      -> Validate Resume -> Execute Known Steps -> Verify -> Complete or Recover
```

Workflow records preserve checkpoints, state references, ordered known handler
ids, expiration, cancellation state, recovery instructions, and post-reboot
verification. Production workflow scopes are empty and both reboot and resume
scheduling entry points return `NotImplemented`. The helpers are not imported
by `core/Execution.psm1` or wired into any tool.

## Driver State and Rollback Foundation

`core/DriverState.psm1` and `core/DriverExecution.psm1` establish the future
driver lifecycle:

```text
Exact scope -> Inventory -> Plan -> Confirm -> Mutate -> Verify -> Persist
            -> Validate identity/package -> Roll back -> Verify -> Persist
```

Production driver scopes are empty. GPU-specific targets are NVIDIA-only, but
NVIDIA is not implicitly approved. Install/update requires Phase 35 provenance,
reboot-capable work requires Phase 40 workflow evidence, and associated state
changes require their own foundation records. Execution is callback-only and
the helpers are not imported by the live runtime.

## TrustedInstaller Execution Foundation

`core/TrustedInstaller.psm1` and
`core/TrustedInstallerExecution.psm1` establish the future privileged
sub-operation lifecycle:

```text
Exact scope -> Structured request -> Plan -> Confirm -> Validate admin/state
            -> Refuse or future execute -> Verify -> Log -> Recover
```

Production scopes are empty. Raw command strings, network paths, unknown
commands, broad/protected targets, external elevation utilities, missing state
records, and missing verification are denied. The execution boundary contains
no process, service, ACL, ownership, registry, file, package, Scheduled Task,
or elevation command and is not wired into any tool.
