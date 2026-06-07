# BoostLab Runtime Foundation

Phase 4 introduces the shared runtime services that future BoostLab tools will use. It does not migrate or execute any Ultimate script, and it does not implement real tool actions.

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

All valid tool requests currently return `Action not implemented yet`. No production tool module or legacy script is invoked.

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
