# BoostLab Tool Module Contract

Every approved tool in `config/Stages.psd1` must have one matching PowerShell module under its stage folder. Placeholder modules normally use:

```text
modules/<Stage>/<ToolId>.psm1
```

An implemented module may use an approved canonical filename when it is explicitly mapped by the runtime and validator. Module paths must never be accepted directly from editable tool metadata.

Tool modules must remain isolated from the GUI. Future runtime discovery will load a selected module and call its exported functions through a module-qualified command or another isolated module scope.

## Required Metadata

`Get-BoostLabToolInfo` must return a structured object matching the tool entry in `config/Stages.psd1`:

* `Id`
* `Title`
* `Stage`
* `Order`
* `Type`
* `RiskLevel`
* `Description`
* `Actions`
* `Capabilities`

The module metadata must not redefine the approved stage name, tool name, order, type, risk meaning, description, or action list.

## Capability Metadata

`config/Stages.psd1` is the canonical source for capability metadata. Every tool entry must contain a `Capabilities` object with Boolean values for:

* `RequiresAdmin`
* `RequiresInternet`
* `CanReboot`
* `CanModifyRegistry`
* `CanModifyServices`
* `CanInstallSoftware`
* `CanDownload`
* `CanModifyDrivers`
* `CanModifySecurity`
* `CanDeleteFiles`
* `UsesTrustedInstaller`
* `UsesSafeMode`
* `SupportsDefault`
* `SupportsRestore`
* `NeedsExplicitConfirmation`

The runtime must validate and honor the catalog capabilities before dispatching implemented behavior. A module must not perform an operation whose capability is not declared in the catalog.

Modules created or migrated after Phase 9 should expose a matching `Capabilities` object from `Get-BoostLabToolInfo`. Existing modules that do not yet return the object remain governed by the catalog metadata supplied to the runtime. Module metadata may be more restrictive during compatibility checks, but it must never silently expand the approved capability set.

Capability flags describe possible operational scope; they do not mean that an action is implemented or authorized. Unknown behavior must be represented conservatively. `CanReboot`, high risk, security-sensitive behavior, destructive file operations, Safe Mode, and TrustedInstaller use require explicit confirmation.

`SupportsDefault` is valid only when the approved action list contains `Default`. `SupportsRestore` is valid only when the action list contains `Restore` and the implementation can use a previous state captured by BoostLab.

## Required Functions

### Get-BoostLabToolInfo

Returns the tool metadata as a structured PowerShell object.

```powershell
Get-BoostLabToolInfo
```

### Test-BoostLabToolCompatibility

Returns a structured compatibility assessment. Placeholder modules report support by default without changing the system.

Required result fields:

* `Supported`
* `ToolId`
* `ToolTitle`
* `Reason`
* `Timestamp`

### Get-BoostLabToolState

Returns the current structured tool state.

Required result fields:

* `ToolId`
* `ToolTitle`
* `Status`
* `LastAction`
* `LastResult`
* `RestartRequired`
* `Timestamp`

Placeholder modules return `Not implemented`. Implemented modules may return `Ready`.

### Invoke-BoostLabToolAction

Accepts an action name declared by the tool metadata and returns a structured result.

```powershell
Invoke-BoostLabToolAction -ActionName Apply
```

Required result fields:

* `Success`
* `ToolId`
* `ToolTitle`
* `Action`
* `Message`
* `RestartRequired`
* `Timestamp`

Assistant analysis actions may also return a structured `Data` object containing read-only findings.

Placeholder modules must not execute real logic. Valid requests return `Action not implemented yet`.

### Restore-BoostLabToolDefault

Modules export this function for a consistent contract. It represents default or restore behavior when applicable to the tool metadata.

Required result fields are the same as `Invoke-BoostLabToolAction`. Placeholder modules return `Action not implemented yet` and perform no restore operation.

## Placeholder Safety Rules

Placeholder tool modules must not:

* Modify registry values
* Change services
* Create, modify, or delete user or system files
* Download or install content
* Change drivers, firmware, security, or Windows configuration
* Create restore points
* Restart or reboot Windows
* Invoke scripts from `source-ultimate`

The modules may only return static metadata and structured placeholder objects.

## Migration Boundary

Future implementation must follow the Script Migration Policy in `CODEX_INSTRUCTIONS.md`.

* `source-ultimate` remains untouched.
* Approved production logic will live in the matching tool module.
* Deleted tools must never receive modules or be recreated under another name.
* Every migration must have an approved record under `docs/migrations/` before stronger production behavior is enabled.
