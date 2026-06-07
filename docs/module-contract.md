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

The module metadata must not redefine the approved stage name, tool name, order, type, risk meaning, description, or action list.

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
