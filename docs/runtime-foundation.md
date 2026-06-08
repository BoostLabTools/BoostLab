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

### Safety

`core/Safety.psm1` contains structured safety placeholders for:

* Risk confirmation
* Restore point requests
* High-risk action gating
* Restart requirement descriptions

These functions return assessment objects only. They do not display prompts, create restore points, change Windows, or restart the computer.

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

The placeholder pipeline:

1. Validates required tool metadata and the requested action.
2. Evaluates the high-risk safety gate when `RiskLevel` is `high`.
3. Creates a structured result object.
4. Logs `[ToolTitle] [ActionName] not implemented yet`.
5. Updates JSON-backed runtime state.
6. Returns the result to the GUI.

The result includes:

* `Success`
* `ToolId`
* `ToolTitle`
* `Action`
* `Message`
* `RestartRequired`
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

This lifecycle is the target governance model and is not fully implemented yet. Capability metadata and migration records introduced in Phase 9 define the information the future pipeline must enforce. No stronger tool should be enabled merely because a module exists.

## GUI Integration

The GUI passes the selected tool metadata and action name to `Invoke-BoostLabToolAction`. It displays the returned placeholder message and receives structured log entries through the existing Activity Log sink.

Header status indicators use the environment snapshot produced by `Get-BoostLabEnvironmentInfo`.

## Current Safety Boundary

Phase 4 does not:

* Execute Ultimate scripts
* Implement registry, service, driver, installer, firmware, or Windows changes
* Create restore points
* Restart or reboot Windows
* Download content
* Enforce licenses

`source-ultimate` remains an untouched legacy reference. Future production tool logic must follow the Script Migration Policy in `CODEX_INSTRUCTIONS.md` and live under `modules/`.
