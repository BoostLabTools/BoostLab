# AppX Package Inventory and Restore Foundation

## Purpose

AppX removal is not equivalent to deleting one file. A package may be registered
for one user, registered for all users, provisioned into the Windows image,
shared as a framework or dependency, or required by a core Windows experience.
Removal without an exact inventory can leave BoostLab unable to verify what was
changed or determine whether a meaningful restore path still exists.

Phase 39 establishes a centralized deny-by-default contract for future AppX
inventory, mutation planning, verification, and record-based restore. It does
not approve a production package, execute an AppX command, enable a deferred
tool, download package content, or launch an installer.

## Production Files

* `config/AppxPackagePolicy.psd1` contains future exact package scopes and the
  protected-package defaults.
* `core/AppxPackageInventory.psm1` validates policy and package identity,
  captures callback-supplied inventory, stores integrity-protected records, and
  builds mutation and restore plans.
* `core/AppxPackageExecution.psm1` exposes callback-only mutation and restore
  boundaries after inventory, Action Plan, confirmation, and verification
  checks pass.

Production `PackageScopes` are empty. Every production request is blocked until
a future approved tool phase adds an exact tool/action/package scope.

Neither core module contains built-in `Get-AppxPackage`, `Remove-AppxPackage`,
`Add-AppxPackage`, provisioned-package mutation, DISM, download, installer, or
process-launch behavior.

## Inventory Record

Every pre-mutation inventory record contains:

* Operation id
* Tool id and action id
* Timestamp
* Schema version and BoostLab version
* Exact allowlist scope id
* Package family name
* Package full name
* Display name
* Publisher
* Version
* Architecture
* Install location
* Package status
* Provisioned package identity
* User scope: current user, all users, provisioned image, or system package
* Original existence, installed state, and provisioned state
* Captured registration manifest path
* Dependencies
* Framework, dependency, and system-critical classification
* Intended mutation
* Rollback eligibility
* Verification requirement
* Risk classification
* Recorded post-mutation and post-restore state

Records are stored under:

```text
$env:ProgramData\BoostLab\State\AppxPackages\Records
```

Each JSON record is wrapped with a SHA-256 integrity value. Missing, corrupt,
stale, out-of-scope, wrong-tool, wrong-action, wrong-package, or wrong-mutation
records are blocked.

Inventory is mandatory before removal. A future tool may not infer original
package state after it has already removed the package.

## Exact Allowlist Rules

A future package scope must declare:

* Exact scope id
* Exact tool ids
* Exact action ids
* Exact package family names
* Exact user scopes
* Exact permitted mutation types
* Whether protected, system, framework, or dependency packages are approved
* Whether all-user removal is approved
* Whether provisioned-image removal is approved
* Whether record-based restore is approved
* Mandatory explicit confirmation

The following are denied:

* Empty, wildcard, partial, or broad package-family targets
* Unknown packages
* Unknown tools or actions
* Package families absent from the manifest
* System-critical packages without separate approval
* Framework and dependency packages without separate approval
* All-user removal without separate approval
* Provisioned-image removal without separate approval
* Restore or repair without an approved restore mutation
* Mutation without a verified inventory record

Package family, tool, action, scope, and mutation identities must match exactly.
Config metadata must never become an arbitrary package query or command line.

## Protected Windows Packages

The production policy protects package families associated with:

* Microsoft Edge
* WebView
* Microsoft Store and Store purchase infrastructure
* Shell Experience Host
* Start Menu Experience Host
* Desktop App Installer
* VCLibs
* Microsoft UI Xaml
* .NET Native
* Windows App Runtime

Frameworks and dependencies are protected even when their family names do not
match one of these tokens. Future exceptions require an exact family, exact
tool/action scope, a migration record, explicit Yazan approval, and a recovery
plan. A generic package-removal tool cannot approve these families.

## Mutation Types

The policy model recognizes only:

* `RemoveCurrentUser`
* `RemoveAllUsers`
* `RemoveProvisioned`
* `ReRegister`
* `RestoreProvisioned`
* `RepairRegistration`

All-user and provisioned-image removal are stricter than current-user removal.
They require separate scope flags in addition to exact package and mutation
allowlisting.

Every mutation plan is dry-run only until:

1. Inventory record integrity and scope are valid.
2. Tool, action, package, user scope, and mutation match.
3. The normal BoostLab Action Plan requires explicit confirmation.
4. The user confirms.
5. A future approved narrow executor is supplied.
6. A read-only verifier returns `Passed`.
7. Post-mutation state is persisted into the inventory record.

Phase 39 supplies no production executor.

## Restore Rules

AppX restore is record-based. It is not a broad re-registration command.

A restore plan requires:

* A valid, non-stale inventory record
* Matching tool and source-action identity
* A recorded completed mutation
* `RollbackEligible = true`
* Exact policy permission for the restore mutation
* A captured install location where registration repair requires one
* A captured provisioned package identity where provisioned restore requires one
* A captured registration manifest path
* A manifest inspection result that confirms the exact captured path exists
* Explicit Action Plan confirmation
* Structured post-restore verification

Restore is blocked when the package install location or manifest is gone. This
foundation does not download, install, reacquire, or repair missing package
content. A future package download or installer workflow would also have to
pass the download provenance and installer execution foundations.

Restoration never enumerates and re-registers every package. It uses only the
specific record and exact package scope approved for the requesting tool.

## Relationship to Other Foundations

### Action Plan

Every mutation and restore requires a matching Action Plan and explicit
confirmation. The AppX plan identifies the package family, user scope, intended
mutation, risk, inventory record, and verification requirement.

### Verification

Command completion is not sufficient. Future callbacks must return a structured
verification result with `Status = Passed` before the foundation records the
operation as completed.

### File and Registry Rollback

The AppX record captures package identity and registration state. It does not
replace exact file or registry capture when a source also changes package
files, policies, registry values, RunOnce state, or other settings.

### Service Rollback

Package workflows that change Gaming Services, update services, or related
service state must also use exact service scopes and service rollback policy.

### Download and Installer Policy

Missing package files, manifests, frameworks, dependencies, or repair installers
cannot be reacquired by this foundation. Any future download or installer path
must use a separately approved provenance artifact and installer request.

### Cleanup and TrustedInstaller

AppX inventory does not authorize file deletion, package-directory cleanup, or
TrustedInstaller execution. Those behaviors remain subject to their own exact
governance boundaries.

## Deferred Tools

This foundation is required by:

* Copilot
* Bloatware
* GameBar

Those tools remain deferred. Each also has additional blockers:

* Copilot needs exact package/process/policy behavior and a proven restore path.
* Bloatware needs exact package lists, feature/service handling, cleanup,
  download/installer decisions, and per-package recovery rules.
* GameBar needs package inventory plus services, downloads/installers,
  TrustedInstaller, and repair governance.

Phase 39 does not authorize partial implementations that weaken Ultimate by
performing only a convenient subset of these workflows.
