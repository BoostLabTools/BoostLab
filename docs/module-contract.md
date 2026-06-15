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

Modules must not copy Ultimate per-script self-elevation blocks or silently elevate themselves. BoostLab owns Administrator elevation at the bootstrap/runtime level. A module that declares `RequiresAdmin = true` may rely on the runtime gate, but it must still report privilege-related failures clearly.

Modules must not implement TrustedInstaller execution directly. A future approved module with `UsesTrustedInstaller = true` must use the centralized runtime helper, require explicit confirmation, and stay within its approved migration record. The Phase 14.5 helper is a non-executing placeholder.

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

The shared runtime may attach an `ActionPlan` property to the module result before returning it to the UI. Modules must not treat the presence of a plan or user confirmation as permission to exceed their approved migration record or capability metadata.

### VerificationResult

Real `Apply`, `Default`, and `Restore` actions should return a `VerificationResult` when the resulting state can be checked safely. Verification is read-only and occurs after the approved command path completes.

Required `VerificationResult` fields:

* `ToolId`
* `ToolTitle`
* `Action`
* `Status`: `Passed`, `Warning`, `Failed`, `NotApplicable`, or `NotImplemented`
* `ExpectedState`
* `DetectedState`
* `Checks`
* `Message`
* `Timestamp`

Each entry in `Checks` must contain:

* `Name`
* `Expected`
* `Actual`
* `Status`
* `Message`

Command success and verification success are separate. `Success = true` means the approved command path completed without a reported execution failure. `VerificationResult.Status = Passed` means the expected state was detected afterward. `Warning` means execution completed but verification was incomplete or Windows may require a refresh, sign-out, policy refresh, or restart. `Failed` means the detected state contradicts the expected result.

Tools that cannot yet verify safely may omit `VerificationResult` or return `NotApplicable`/`NotImplemented`. Existing modules without verification remain valid.

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

Implemented modules that perform future destructive cleanup must use an approved exact scope from `config/CleanupPolicy.psd1`, require an Action Plan and explicit confirmation, provide Phase 36 state-capture evidence when rollback eligible, and return structured verification. Modules must not bypass the centralized cleanup boundary with broad or metadata-driven deletion commands.

Implemented modules that perform future AppX package work must use an approved
exact scope from `config/AppxPackagePolicy.psd1`. They must capture inventory
before removal, identify the exact package family, user scope, and mutation,
require Action Plan confirmation, return structured verification, and persist
post-mutation state. Restore may use only a valid BoostLab package record and
the exact captured manifest, install location, or provisioned identity. Modules
must not enumerate broad package families, re-register every package, or bypass
the centralized AppX boundary.

Implemented modules that perform future reboot-capable work must use an exact
scope from `config/RebootRecoveryPolicy.psd1`. They must supply passed
pre-reboot checkpoints, verified state references, bounded policy-approved
resume handler ids, post-reboot verification, expiration, warning text, and
recovery instructions. Modules must not write RunOnce, create Scheduled Tasks,
edit BCD, embed command strings in resume records, or call reboot commands
outside the future centralized reboot boundary.

Implemented modules that perform future driver work must use an exact scope
from `config/DriverStatePolicy.psd1`. They must capture exact device and package
inventory before mutation, use the centralized driver plan and execution
boundaries, require Action Plan confirmation, verify the resulting state, and
persist post-mutation state before any rollback claim. Install/update must
reference verified artifact provenance, reboot-capable work must reference a
verified reboot workflow, and related service/file/registry/AppX/cleanup work
must use those separate foundations. Modules must not enumerate broad device
classes, accept arbitrary INF paths, run AMD/Intel GPU branches, or bypass the
driver boundary with direct PnP/DISM/device commands.

Implemented modules that require future TrustedInstaller execution must use an
exact scope from `config/TrustedInstallerPolicy.psd1` and the centralized
request/execution boundary. They must provide a structured command descriptor,
exact targets, matching Action Plan confirmation, verified Administrator host,
required state references, verification plan, timeout, logging, and recovery
behavior. Modules must not self-elevate, embed raw command lines, invoke
external elevation tools, start or modify the TrustedInstaller service, create
temporary services or Scheduled Tasks, alter ACLs/ownership, or bypass the
centralized boundary.

## Migration Boundary

Future implementation must follow the Script Migration Policy in `CODEX_INSTRUCTIONS.md`.

* `source-ultimate` remains untouched.
* Approved production logic will live in the matching tool module.
* Deleted tools must never receive modules or be recreated under another name.
* Every migration must have an approved record under `docs/migrations/` before stronger production behavior is enabled.
