# Copilot Scope Design

## Purpose

This Phase 62 document defines the future implementation scope for the
`Copilot` tool. It is design-only.

No Copilot behavior is implemented by this document. No runtime behavior,
module behavior, production AppX/package scope, registry scope, file scope,
cleanup scope, download artifact approval, installer execution approval,
process scope, policy scope, Default behavior, or Restore behavior is approved
here.

Copilot remains a refused placeholder until a later approved phase adds exact
bounded production scopes and implementation.

## Source Reference

* Source path: `source-ultimate/6 Windows/8 Copilot.ps1`
* Source SHA-256: `45F87252A018398E87B281DE094E4943A63026567EB0782B631BBEF989CF6A9E`
* Current BoostLab module path: `modules/Windows/copilot.psm1`
* Current status: refused placeholder
* Current implemented actions: none

Relevant foundations:

* Phase 35: download provenance and installer execution policy
* Phase 36: file and registry state capture and rollback
* Phase 38: destructive cleanup policy
* Phase 39: AppX package inventory and restore
* Phase 40: reboot/recovery workflow

## Product Scope Decision

Phase 48 defines BoostLab product scope as branch-level scope. Shared Windows
behavior may be preserved if it otherwise passes governance. Explicit Windows
10-only branches or options must remain unsupported, disabled, visual-only, or
`NotApplicable`.

No Windows 10-only branch was found in `source-ultimate/6 Windows/8 Copilot.ps1`.
The source behavior is shared Windows behavior, but it remains blocked because
it requires broad process stops, wildcard Copilot AppX removal, wildcard AppX
re-registration, and HKCU/HKLM policy key mutation without exact package,
process, registry, or restore scopes.

## Source Behavior Summary

The Ultimate source exposes two console menu actions:

1. `Copilot: Off (Recommended)`
2. `Copilot: Default`

The source requires Administrator up front. It does not contain download,
installer, reboot, Safe Mode, or TrustedInstaller behavior.

The Off branch:

* Stops a broad process list.
* Stops any process where `ProcessName -like "*edge*"`.
* Removes AppX packages returned by
  `Get-AppXPackage -AllUsers | Where-Object { $_.Name -like '*Copilot*' }`.
* Sets `TurnOffWindowsCopilot=REG_DWORD 1` under both HKCU and HKLM policy
  paths.

The Default branch:

* Re-registers AppX packages returned by
  `Get-AppXPackage -AllUsers | Where-Object { $_.Name -like '*Copilot*' }`.
* Deletes both HKCU and HKLM `WindowsCopilot` policy keys.

Per Phase 39, unknown packages remain denied, wildcard/broad packages remain denied,
framework/dependency/system-critical packages remain denied, no
AppX/package removal is allowed without inventory capture, and no
restore/re-registration is allowed without a verified inventory/restore record.

Per Phase 36, policy registry mutation needs exact bounded targets and capture
before mutation. Broad policy-key deletion remains refused unless exact
rollback is approved.

Do not implement a policy-only subset: applying only the registry policy would
weaken and misrepresent the approved Ultimate behavior because the source also
stops processes and removes/re-registers Copilot AppX packages.
Any policy-only implementation would weaken Ultimate behavior.

## Current Decision

Do not implement Analyze, Apply, Default, or Restore yet.

The source combines broad process handling, wildcard AppX removal and
re-registration, and HKCU/HKLM policy mutation. A partial policy-only
implementation would weaken Ultimate behavior, while full preservation requires
production process governance and exact AppX/package and registry scopes that
do not exist.

## Behavior Groups

### 1. Copilot AppX/Package Behavior

* Exact source targets:
  * `Get-AppXPackage -AllUsers | Where-Object`
  * Package name pattern `*Copilot*`
  * `Remove-AppxPackage`
* Source menu options:
  * `Copilot: Off (Recommended)`
* Intended mutation or launch type:
  * Wildcard AppX package removal.
* Required foundation:
  * Phase 39 AppX package inventory and restore.
* Required future production allowlist:
  * Exact Copilot package names and package family names. Wildcard `*Copilot*`
    package discovery must not become a production scope.
* Required inventory/capture before mutation:
  * Current-user, all-user, and provisioned package inventory for every exact
    approved Copilot package.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify only approved package identities were selected.
  * Verify removal outcome per package and report packages not present as
    non-errors.
* Rollback/restore feasibility:
  * Not feasible without Phase 39 inventory restore records and exact package
    restore or repair paths.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after exact Copilot package scopes are approved.
* Whether it must remain refused:
  * Wildcard AppX package removal remains refused.

### 2. Copilot-Related Package Removal Behavior

* Exact source targets:
  * Any package returned by `Name -like '*Copilot*'`.
* Source menu options:
  * `Copilot: Off (Recommended)`
* Intended mutation or launch type:
  * Broad Copilot-related package selection and removal.
* Required foundation:
  * Phase 39 AppX package inventory and restore.
* Required future production allowlist:
  * Exact approved package family names, user scopes, and mutation types.
* Required inventory/capture before mutation:
  * Package identity, install location, registration state, user scope,
    provisioned state, dependencies, and framework/system classification.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify every selected package matches an exact approved scope.
  * Verify protected package classifications are denied unless separately
    approved.
* Rollback/restore feasibility:
  * Not feasible as a generic Default. Restore must be record-based and
    package-specific.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after the wildcard selector is decomposed into exact package scopes.
* Whether it must remain refused:
  * Broad package matching remains refused.

### 3. AppX Re-Registration or Restore Behavior If Present

* Exact source targets:
  * `Get-AppXPackage -AllUsers | Where-Object`
  * Package name pattern `*Copilot*`
  * `Add-AppxPackage -DisableDevelopmentMode -Register`
  * `"$($_.InstallLocation)\AppXManifest.xml"`
* Source menu options:
  * `Copilot: Default`
* Intended mutation or launch type:
  * Wildcard AppX re-registration.
* Required foundation:
  * Phase 39 AppX package inventory and restore.
* Required future production allowlist:
  * Exact package family names and exact manifest paths.
  * Exact approval for `RepairRegistration` or a source-default
    re-registration operation.
* Required inventory/capture before mutation:
  * Existing package identity, captured manifest path, install location,
    dependency state, and registration state.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify each package registration result.
  * Verify no package outside the approved Copilot scope was re-registered.
* Rollback/restore feasibility:
  * Source Default is not Restore. Re-registration requires a verified package
    inventory record and does not reconstruct arbitrary previous user state.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after exact Copilot package and repair-registration scopes are
    approved.
* Whether it must remain refused:
  * Wildcard re-registration remains refused.

### 4. Copilot Policy Registry Behavior

* Exact source targets:
  * `HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot`
  * `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot`
  * Value name `TurnOffWindowsCopilot`
  * Value type `REG_DWORD`
  * Off data `1`
* Exact source commands:
  * `cmd /c "reg add `"HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot`" /v `"TurnOffWindowsCopilot`" /t REG_DWORD /d `"1`" /f >nul 2>&1"`
  * `cmd /c "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot`" /v `"TurnOffWindowsCopilot`" /t REG_DWORD /d `"1`" /f >nul 2>&1"`
  * `cmd /c "reg delete `"HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot`" /f >nul 2>&1"`
  * `cmd /c "reg delete `"HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot`" /f >nul 2>&1"`
* Source menu options:
  * `Copilot: Off (Recommended)`
  * `Copilot: Default`
* Intended mutation or launch type:
  * HKCU/HKLM policy value write and broad policy key delete.
* Required foundation:
  * Phase 36 file and registry state capture and rollback.
* Required future production allowlist:
  * Exact value scopes for `TurnOffWindowsCopilot`.
  * Exact key scopes if source Default key deletion is ever approved.
* Required inventory/capture before mutation:
  * Previous existence, type, and data for `TurnOffWindowsCopilot`.
  * Full key manifest before any approved key deletion.
* Required confirmation level:
  * Explicit Action Plan confirmation because HKLM policy mutation is
    system-changing and because a policy-only subset would weaken source
    behavior.
* Required verification:
  * Verify Off writes both HKCU and HKLM policy values as `REG_DWORD 1`.
  * Verify Default removes only exact approved policy values/keys.
  * Verify broad policy-key deletion did not remove unrelated values unless an
    exact key manifest restore path is approved.
* Rollback/restore feasibility:
  * Value-level restore is feasible only from captured Phase 36 state.
  * Broad key deletion is not safely restorable without exact key capture and
    current-state identity checks.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Policy values can be considered only as part of the full approved Copilot
    behavior, not as a weakened standalone subset.
* Whether it must remain refused:
  * Broad policy-key deletion remains refused until exact rollback is approved.

### 5. Copilot User/Settings Registry Behavior If Present

* Exact source targets:
  * None beyond HKCU/HKLM policy paths listed above.
* Source menu options:
  * Not applicable.
* Intended mutation or launch type:
  * No separate Copilot user/settings registry behavior found.
* Required foundation:
  * Phase 36 if future source-approved settings are discovered.
* Required future production allowlist:
  * None in this phase.
* Required inventory/capture before mutation:
  * Not applicable.
* Required confirmation level:
  * Not applicable.
* Required verification:
  * Future implementation must verify it did not invent extra Copilot user
    settings not present in the source.
* Rollback/restore feasibility:
  * Not applicable.
* Risk level:
  * Not applicable.
* Whether it can be implemented later:
  * Only if a later approved source mapping identifies exact settings.
* Whether it must remain refused:
  * Any invented Copilot setting tweak must remain refused.

### 6. Process Stop Behavior If Present

* Exact source targets:
  * `backgroundTaskHost`
  * `Copilot`
  * `CrossDeviceResume`
  * `GameBar`
  * `MicrosoftEdgeUpdate`
  * `msedge`
  * `msedgewebview2`
  * `OneDrive`
  * `OneDrive.Sync.Service`
  * `OneDriveStandaloneUpdater`
  * `Resume`
  * `RuntimeBroker`
  * `Search`
  * `SearchHost`
  * `Setup`
  * `StoreDesktopExtension`
  * `WidgetService`
  * `Widgets`
  * Any process where `ProcessName -like "*edge*"`
* Exact source commands:
  * `$stop | ForEach-Object { Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue }`
  * `Get-Process | Where-Object { $_.ProcessName -like "*edge*" } | Stop-Process -Force -ErrorAction SilentlyContinue`
* Source menu options:
  * `Copilot: Off (Recommended)`
* Intended mutation or launch type:
  * Broad forced process stop.
* Required foundation:
  * A future process-handling policy is still needed.
* Required future production allowlist:
  * Exact process names, executable identity rules, session/owner rules, and
    stop justification.
  * Wildcard `*edge*` process matching must not become a production scope.
* Required inventory/capture before mutation:
  * Process id, executable path, command line if safely available, owner/session,
    and reason for stopping.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify only approved processes were targeted.
  * Report already-stopped processes as non-errors.
* Rollback/restore feasibility:
  * Process state is not restorable. The tool must not claim Restore for
    stopped processes.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after process-handling governance exists.
* Whether it must remain refused:
  * The current broad process stop and `*edge*` wildcard remain refused.

### 7. File/Directory Cleanup Behavior If Present

* Exact source targets:
  * None found.
* Source menu options:
  * Not applicable.
* Intended mutation or launch type:
  * No file or directory cleanup behavior is present in the Copilot source.
* Required foundation:
  * Phase 38 destructive cleanup policy if future file cleanup is introduced by
    an approved source mapping.
* Required future production allowlist:
  * None in this phase.
* Required inventory/capture before mutation:
  * Not applicable.
* Required confirmation level:
  * Not applicable.
* Required verification:
  * Future implementation must verify it did not invent file cleanup outside the
    source.
* Rollback/restore feasibility:
  * Not applicable.
* Risk level:
  * Not applicable.
* Whether it can be implemented later:
  * Only if a future approved source mapping names exact file targets.
* Whether it must remain refused:
  * Invented file/directory cleanup remains refused.

### 8. Downloads/Installers or Repair Behavior If Present

* Exact source targets:
  * None found.
* Source menu options:
  * Not applicable.
* Intended mutation or launch type:
  * No download, installer, or repair tool behavior is present in the Copilot
    source.
* Required foundation:
  * Phase 35 download provenance and installer execution policy if future source
    changes add artifacts.
* Required future production allowlist:
  * None in this phase.
* Required inventory/capture before mutation:
  * Not applicable.
* Required confirmation level:
  * Not applicable.
* Required verification:
  * Future implementation must verify no external download or executable launch
    was invented for Copilot.
* Rollback/restore feasibility:
  * Not applicable.
* Risk level:
  * Not applicable.
* Whether it can be implemented later:
  * Not applicable for the current source.
* Whether it must remain refused:
  * Any unapproved download, installer, or repair behavior remains refused.

### 9. Default/Restore Behavior

* Exact source Default behavior:
  * Re-register packages where `Name -like '*Copilot*'`.
  * Delete `HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot`.
  * Delete `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot`.
* Source menu options:
  * `Copilot: Default`
* Intended mutation or launch type:
  * Source-default repair/re-registration plus policy-key deletion.
* Required foundation:
  * Phase 39 AppX package inventory and restore.
  * Phase 36 registry state capture and rollback.
* Required future production allowlist:
  * Exact package repair/re-registration scopes and exact registry key/value
    scopes.
* Required inventory/capture before mutation:
  * Package inventory, manifest path, prior registry key/value state, and key
    manifest if key deletion is approved.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify every re-registered package matches an exact approved scope.
  * Verify policy deletion is scoped to the approved Copilot policy targets.
* Rollback/restore feasibility:
  * Current Default/Restore must remain unavailable. Source Default is not a
    captured Restore and does not reconstruct arbitrary previous package or
    policy state.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Default can be considered only after package and registry scopes are
    approved.
* Whether it must remain refused:
  * Restore must remain refused until record-based package and registry restore
    is approved.

### 10. Unsupported Broad Package/File/Registry/Policy Targets

* Exact source targets:
  * Package wildcard `*Copilot*`
  * Process wildcard `ProcessName -like "*edge*"`
  * Broad policy key delete:
    `HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot`
  * Broad policy key delete:
    `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot`
* Source menu options:
  * `Copilot: Off (Recommended)`
  * `Copilot: Default`
* Intended mutation or launch type:
  * Broad package discovery, broad process discovery, and broad policy-key
    deletion.
* Required foundation:
  * Phase 36 and Phase 39.
  * A future process-handling policy.
* Required future production allowlist:
  * Exact targets only. Wildcards and broad policy deletes are not approved.
* Required inventory/capture before mutation:
  * Exact package, process, and registry inventories.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify broad selectors are replaced by exact scopes or block execution.
* Rollback/restore feasibility:
  * Not feasible without exact inventory and captured state.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after the source behavior is decomposed into exact scopes.
* Whether it must remain refused:
  * All broad selectors in this group must remain refused.

### 11. Unsupported Windows 10-Only Branches/Options If Present

* Exact source targets:
  * None found.
* Source menu options:
  * No explicit Windows 10-only menu branch or source option was found.
* Intended mutation or launch type:
  * Not applicable.
* Required foundation:
  * Phase 48 branch-level product scope.
* Required future production allowlist:
  * None for Windows 10-only behavior because no such branch exists.
* Required inventory/capture before mutation:
  * Not applicable.
* Required confirmation level:
  * Not applicable for product-scope gating.
* Required verification:
  * Future implementation must verify that it is not adding Windows 10-only
    behavior not present in the approved source.
* Rollback/restore feasibility:
  * Not applicable.
* Risk level:
  * Not applicable.
* Whether it can be implemented later:
  * Shared Windows behavior may be reconsidered if every non-product-scope
    blocker is solved.
* Whether it must remain refused:
  * Any invented Windows 10-only branch must remain refused.

## Exact Source Target Inventory

Package selectors:

* `*Copilot*`
* `Remove-AppxPackage`
* `Add-AppxPackage -DisableDevelopmentMode -Register`
* `"$($_.InstallLocation)\AppXManifest.xml"`

Processes:

* `backgroundTaskHost`
* `Copilot`
* `CrossDeviceResume`
* `GameBar`
* `MicrosoftEdgeUpdate`
* `msedge`
* `msedgewebview2`
* `OneDrive`
* `OneDrive.Sync.Service`
* `OneDriveStandaloneUpdater`
* `Resume`
* `RuntimeBroker`
* `Search`
* `SearchHost`
* `Setup`
* `StoreDesktopExtension`
* `WidgetService`
* `Widgets`
* `ProcessName -like "*edge*"`

Registry paths and values:

* `HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot`
* `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot`
* `TurnOffWindowsCopilot`
* `REG_DWORD`
* Data `1`

Commands:

* `Get-AppXPackage -AllUsers | Where-Object`
* `Remove-AppxPackage`
* `Add-AppxPackage -DisableDevelopmentMode -Register`
* `Stop-Process -Name`
* `Stop-Process -Force`
* `cmd /c "reg add`
* `cmd /c "reg delete`

## Future Safe Apply Requirements

A future safe Apply would require all of the following:

1. A tool-specific Action Plan decomposing the source behavior into exact
   process, package, and registry operations.
2. Exact AppX package scopes replacing `*Copilot*` wildcard discovery.
3. A process-handling policy plus exact process scopes replacing the broad
   process list and `*edge*` wildcard discovery.
4. Exact registry value scopes for both HKCU and HKLM
   `TurnOffWindowsCopilot`.
5. Exact registry key capture and restore rules before any policy-key deletion.
6. Inventory/capture before every mutation.
7. Verification after every target group.
8. Explicit confirmation before process stop, package mutation, or HKLM policy
   mutation.
9. Explicit refusal of a policy-only subset because it would weaken Ultimate
   behavior.

## Default and Restore Boundary

The source Default branch is a source-default repair/re-registration workflow,
not a captured Restore action.

BoostLab must not expose Copilot Default until exact AppX package scopes,
registry scopes, process behavior decisions, and verification rules are
approved.

BoostLab must not expose Restore until exact AppX inventory restore, registry
rollback, repair provenance if ever needed, quarantine restore if ever needed,
and captured-state restore selection are implemented. Restore must be
record-based and target-specific.

Current Default/Restore must remain unavailable because the source Default
re-registers broad AppX package matches and deletes policy keys without
capturing the user's previous package or policy state.

## Production Approval State

No production AppX/package, registry, file, cleanup, download, installer,
process, policy, repair, Default, or Restore scope is approved by this
document.

Specifically, this document does not approve:

* Copilot AppX package removal
* Copilot AppX package re-registration
* Broad process stop
* `*edge*` process matching
* HKCU Copilot policy write
* HKLM Copilot policy write
* HKCU Copilot policy key deletion
* HKLM Copilot policy key deletion
* Policy-only implementation
* Default behavior
* Restore behavior

Copilot remains a refused placeholder until a future phase explicitly approves
exact bounded scopes and implements a reviewed workflow.
