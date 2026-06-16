# GameBar Scope Design

## Purpose

This Phase 61 document defines the future implementation scope for the
`GameBar` tool. It is design-only.

No GameBar behavior is implemented by this document. No runtime behavior,
module behavior, production AppX/package scope, service scope, registry scope,
file scope, cleanup scope, download artifact approval, installer execution
approval, TrustedInstaller scope, reboot scope, Default behavior, or Restore
behavior is approved here.

GameBar remains a refused placeholder until a later approved phase adds exact
bounded production scopes and implementation.

## Source Reference

* Source path: `source-ultimate/6 Windows/12 Gamebar.ps1`
* Source SHA-256: `8C6703E68C251D63ADD81A87B7CB6C1F572A4CE55A1E092C33B9B444A9884E59`
* Current BoostLab module path: `modules/Windows/game-bar.psm1`
* Current status: refused placeholder
* Current implemented actions: none

Relevant foundations:

* Phase 35: download provenance and installer execution policy
* Phase 36: file and registry state capture and rollback
* Phase 37: service state capture and rollback
* Phase 38: destructive cleanup policy
* Phase 39: AppX package inventory and restore
* Phase 40: reboot/recovery workflow
* Phase 42: TrustedInstaller privileged-operation policy

## Product Scope Decision

Phase 48 defines BoostLab product scope as branch-level scope. Shared Windows
behavior may be preserved if it otherwise passes governance. Explicit Windows
10-only branches or options must remain unsupported, disabled, visual-only, or
`NotApplicable`.

No Windows 10-only branch was found in `source-ultimate/6 Windows/12 Gamebar.ps1`.
The source behavior is shared Windows behavior, but it is still blocked because
it requires AppX wildcard package removal, AppX re-registration, service and
process handling, MSI uninstall, registry protocol overrides, TrustedInstaller
registry mutation, and mutable download/repair installers.

## Source Behavior Summary

The Ultimate source exposes two console menu actions:

1. `Gamebar Xbox: Off (Recommended)`
2. `Gamebar Xbox: Default`

The source requires Administrator and internet connectivity up front.

The Off branch stops Game Bar, removes AppX packages whose names match
`*Gaming*` or `*Xbox*`, stops GameInput-related services/processes, uninstalls
Microsoft GameInput through `msiexec.exe`, imports a generated
`$env:SystemRoot\Temp\gamebaroff.reg` file, and uses `Run-Trusted -command` to
set `ActivationType=0` for the Game Bar PresenceWriter runtime class.

The Default branch imports a generated `$env:SystemRoot\Temp\gamebaron.reg`
file, uses `Run-Trusted -command` to set `ActivationType=1`, re-registers AppX
packages whose names match `*Gaming*`, `*Xbox*`, or `*Store*`, downloads
`edgewebview.exe` and `gamingrepairtool.exe` from mutable GitHub raw URLs, and
launches both repair tools.

The source includes:

* TrustedInstaller helper references: 14
* Non-elevation `Start-Process` calls: 5
* AppX package operations: 4
* Registry-file target lines: 22
* Mutable GitHub raw URLs: 2

Per Phase 39, unknown packages remain denied, wildcard AppX package matching remains refused,
and system-critical/framework/dependency package changes
remain denied unless Yazan separately approves exact exceptions with recovery
plans.

The current catalog metadata understates source risk because the catalog still
describes GameBar as a low-risk reversible preference while the approved source
performs high-risk package, service, installer, registry, and TrustedInstaller
operations. This phase documents the mismatch but does not change metadata or
tool behavior.

## Current Decision

Do not implement Analyze, Apply, Default, or Restore yet.

The source combines wildcard AppX removal and re-registration, Microsoft
GameInput uninstall, process stops, service stops, HKCU/HKCR/HKLM registry
mutation, generated `.reg` imports, TrustedInstaller service hijack behavior,
mutable download artifacts, and repair installer launches. A partial
registry-only implementation would weaken Ultimate behavior, while a full
implementation requires production scopes and artifact approvals that do not
exist.

## Behavior Groups

### 1. Xbox Game Bar AppX/Package Behavior

* Exact source targets:
  * `Get-AppXPackage -AllUsers | Where-Object`
  * Package name pattern `*Gaming*`
  * Package name pattern `*Xbox*`
  * `Remove-AppxPackage`
* Source options:
  * Off removes all matching packages for all users.
* Intended mutation type:
  * Wildcard AppX package removal.
* Required foundation:
  * Phase 39 AppX package inventory and restore.
* Required future production allowlist:
  * Exact package names and package family names. Wildcard `*Gaming*` and
    `*Xbox*` discovery must not be approved as production scopes.
* Required inventory/capture before mutation:
  * Current-user, all-user, and provisioned package inventory for every exact
    approved package.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify only approved packages were selected.
  * Verify removal outcome per package and report packages not present.
* Rollback/restore feasibility:
  * Not feasible without Phase 39 inventory restore records and a reviewed
    package restore path.
* Risk level: high
* Whether it can be implemented later:
  * Only after exact package scopes are approved.
* Whether it must remain refused:
  * The wildcard package selection must remain refused.

### 2. Xbox-Related AppX/Package Behavior

* Exact source targets:
  * `Get-AppXPackage -AllUsers | Where-Object`
  * Package name pattern `*Gaming*`
  * Package name pattern `*Xbox*`
  * Package name pattern `*Store*`
  * `Add-AppxPackage -DisableDevelopmentMode -Register`
  * `"$($_.InstallLocation)\AppXManifest.xml"`
* Source options:
  * Default re-registers all matching Gaming, Xbox, and Store packages.
* Intended mutation type:
  * Wildcard AppX package re-registration and repair behavior.
* Required foundation:
  * Phase 39 AppX package inventory and restore.
* Required future production allowlist:
  * Exact package family names and exact manifest paths.
  * Store package handling needs extra approval because Microsoft Store is a
    protected package class in current package policy.
* Required inventory/capture before mutation:
  * Package inventory, install location, manifest hash, package status, and
    dependency relationship per package.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify each exact package registration result.
  * Verify protected packages are not touched without explicit scope.
* Rollback/restore feasibility:
  * Re-registration is not Restore. Restore requires captured package state and
    a reviewed restore record.
* Risk level: high
* Whether it can be implemented later:
  * Only after exact package and protected-package exceptions are approved.
* Whether it must remain refused:
  * Wildcard re-registration and Store package inclusion must remain refused.

### 3. GameInput Behavior

* Exact source targets:
  * Service name `GameInputSvc`
  * Process name `GameInputRedistService`
  * Uninstall registry discovery:
    `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*`
  * Display name match `*Microsoft GameInput*`
  * `msiexec.exe`
* Exact source commands:
  * `cmd /c "sc stop `"GameInputSvc`" >nul 2>&1"`
  * `Start-Process "msiexec.exe" -ArgumentList "/x $guid /qn /norestart" -Wait -NoNewWindow`
* Source options:
  * Off stops GameInput and uninstalls Microsoft GameInput when found.
  * Default sets `GameInputSvc` startup value to `3` through a registry file.
* Intended mutation type:
  * Service stop, process stop, MSI uninstall, and service-start registry write.
* Required foundation:
  * Phase 37 service state capture and rollback.
  * Phase 35 installer execution policy for `msiexec.exe`.
  * Phase 36 registry state capture for service startup values.
* Required future production allowlist:
  * Exact service name `GameInputSvc`.
  * Exact process name `GameInputRedistService`.
  * Exact Microsoft GameInput product identity and uninstall command descriptor.
* Required inventory/capture before mutation:
  * Service status/start type.
  * Process id/path before stop.
  * Uninstall key identity, product code, display name, publisher, and version.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify service state capture exists before stop or registry mutation.
  * Verify the MSI product code belongs to Microsoft GameInput before uninstall.
  * Verify no unrelated uninstall key was selected by display-name wildcard.
* Rollback/restore feasibility:
  * Startup value restore may be possible from Phase 36/37 capture.
  * MSI uninstall is not reversible without approved installer/repair
    provenance.
* Risk level: high
* Whether it can be implemented later:
  * Only after exact service and installer scopes are approved.
* Whether it must remain refused:
  * Dynamic display-name based MSI uninstall remains refused.

### 4. Service Behavior If Present

* Exact source targets:
  * Service name `GameInputSvc`
  * Service registry path `HKLM\SYSTEM\ControlSet001\Services\GameInputSvc`
  * Service registry path `HKLM\SYSTEM\ControlSet001\Services\BcastDVRUserService`
  * Service registry path `HKLM\SYSTEM\ControlSet001\Services\XboxGipSvc`
  * Service registry path `HKLM\SYSTEM\ControlSet001\Services\XblAuthManager`
  * Service registry path `HKLM\SYSTEM\ControlSet001\Services\XblGameSave`
  * Service registry path `HKLM\SYSTEM\ControlSet001\Services\XboxNetApiSvc`
* Exact source values:
  * `Start` set to `REG_DWORD 3` in Default.
* Intended mutation type:
  * Service stop and service-start registry value mutation.
* Required foundation:
  * Phase 37 service state capture and rollback.
  * Phase 36 registry state capture and rollback.
* Required future production allowlist:
  * Exact service names and exact `Start` value scopes.
* Required inventory/capture before mutation:
  * Service state, start type, delayed auto-start if applicable, and registry
    value existence/type/data.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify only approved service names were touched.
  * Verify `Start` values equal source-defined `3` after Default if Default is
    ever approved.
* Rollback/restore feasibility:
  * Startup value rollback is possible only from captured prior state.
  * Stopped process/service runtime state is not a reliable Restore claim.
* Risk level: high
* Whether it can be implemented later:
  * Only after exact service scopes are approved.
* Whether it must remain refused:
  * Default service mutation remains refused until scoped.

### 5. Process Stop Behavior If Present

* Exact source targets:
  * `Stop-Process -Force -Name GameBar`
  * Process name `GameBar`
  * Process name `gamingservices`
  * Process name `gamingservicesnet`
  * Process name `GameInputRedistService`
* Intended mutation type:
  * Force-stop running user and service-related processes.
* Required foundation:
  * A future process-handling policy is still needed.
* Required future production allowlist:
  * Exact process names, executable identity rules, and reason for stopping.
* Required inventory/capture before mutation:
  * Process id, executable path, owner/session, and command line where safely
    available.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify only approved process names were targeted.
  * Report already-stopped processes as non-errors.
* Rollback/restore feasibility:
  * Process state is not restorable. The tool must not claim Restore for
    stopped processes.
* Risk level: high
* Whether it can be implemented later:
  * Only after process-handling governance exists.
* Whether it must remain refused:
  * Force-stop behavior must remain refused for now.

### 6. Registry Policy/Settings Behavior

* Exact source targets:
  * `HKCU\System\GameConfigStore`
  * `GameDVR_Enabled=REG_DWORD 0`
  * `HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR`
  * `AppCaptureEnabled=REG_DWORD 0` in Off
  * `AppCaptureEnabled=-` in Default
  * `HKCU\Software\Microsoft\GameBar`
  * `UseNexusForGameBarEnabled=REG_DWORD 0` in Off
  * `UseNexusForGameBarEnabled=-` in Default
  * `GamepadNexusChordEnabled=REG_DWORD 0` in Off
  * `GamepadNexusChordEnabled=-` in Default
  * `HKEY_CLASSES_ROOT\ms-gamebar`
  * `HKEY_CLASSES_ROOT\ms-gamebarservices`
  * `HKEY_CLASSES_ROOT\ms-gamingoverlay`
  * `HKLM\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter`
  * `ActivationType=REG_DWORD 0` in Off
  * `ActivationType=REG_DWORD 1` in Default
* Exact source commands and files:
  * `$env:SystemRoot\Temp\gamebaroff.reg`
  * `$env:SystemRoot\Temp\gamebaron.reg`
  * `Start-Process -Wait "regedit.exe" -ArgumentList "/S `"$env:SystemRoot\Temp\gamebaroff.reg`"" -WindowStyle Hidden`
  * `Start-Process -Wait "regedit.exe" -ArgumentList "/S `"$env:SystemRoot\Temp\gamebaron.reg`"" -WindowStyle Hidden`
  * `Run-Trusted -command`
* Intended mutation type:
  * HKCU/HKCR/HKLM value writes, value deletes, protocol key deletes/recreates,
    generated `.reg` import, and TrustedInstaller-protected registry write.
* Required foundation:
  * Phase 36 registry state capture and rollback.
  * Phase 42 TrustedInstaller privileged-operation policy.
  * Phase 38 generated file/cleanup policy for `.reg` files.
* Required future production allowlist:
  * Exact registry value scopes for each HKCU/HKCR/HKLM value.
  * Exact key scopes for protocol key deletion/recreation.
  * Exact TrustedInstaller command descriptor for `ActivationType` only.
  * Exact generated `.reg` file paths and contents.
* Required inventory/capture before mutation:
  * Previous existence, type, and data for every value.
  * Key manifests before deleting protocol keys.
  * Generated file ownership and hash record before import.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify registry writes match source-defined values.
  * Verify deletes only remove source-defined values/keys.
  * Verify TrustedInstaller command is bounded to the exact PresenceWriter path
    and `ActivationType` value.
* Rollback/restore feasibility:
  * Value/key restore is possible only from Phase 36 captured state.
  * Source Default is not Restore because it writes source defaults and deletes
    values/keys without reconstructing arbitrary prior user state.
* Risk level: high
* Whether it can be implemented later:
  * Only after exact registry, generated file, and TrustedInstaller scopes are
    approved.
* Whether it must remain refused:
  * Generated regedit import and TrustedInstaller mutation remain refused.

### 7. File/Directory Cleanup Behavior If Present

* Exact source targets:
  * `$env:SystemRoot\Temp\gamebaroff.reg`
  * `$env:SystemRoot\Temp\gamebaron.reg`
  * `$env:SystemRoot\Temp\edgewebview.exe`
  * `$env:SystemRoot\Temp\gamingrepairtool.exe`
* Source behavior:
  * Creates generated `.reg` files in `%SystemRoot%\Temp`.
  * Downloads repair executables to `%SystemRoot%\Temp`.
  * Does not explicitly remove those generated files or executables.
* Intended mutation type:
  * Generated file creation and downloaded artifact placement.
* Required foundation:
  * Phase 36 file state capture where overwriting could occur.
  * Phase 38 destructive cleanup policy if cleanup is later added.
  * Phase 35 artifact provenance for downloaded executables.
* Required future production allowlist:
  * Exact generated file paths and generated-content hashes.
  * Exact temp artifact paths tied to approved artifacts.
* Required inventory/capture before mutation:
  * Previous file existence, hash, size, owner, and timestamp for each path.
  * Generated-file ownership record for BoostLab-created files.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation for generated protected temp
    files and downloaded executables.
* Required verification:
  * Verify generated content matches approved source text before import.
  * Verify existing files are not overwritten without capture and approval.
* Rollback/restore feasibility:
  * Generated file cleanup can be safe only when BoostLab owns the generated
    file record.
  * Restore of pre-existing files requires captured backup state.
* Risk level: high
* Whether it can be implemented later:
  * Only after exact file scopes and generated-file ownership rules are
    approved.
* Whether it must remain refused:
  * Downloaded executable placement remains refused until provenance exists.

### 8. AppX Re-Registration or Repair Behavior If Present

* Exact source targets:
  * `Get-AppXPackage -AllUsers | Where-Object`
  * Package name pattern `*Gaming*`
  * Package name pattern `*Xbox*`
  * Package name pattern `*Store*`
  * `Add-AppxPackage -DisableDevelopmentMode -Register`
  * `"$($_.InstallLocation)\AppXManifest.xml"`
* Intended mutation type:
  * AppX package re-registration and repair.
* Required foundation:
  * Phase 39 AppX package inventory and restore.
* Required future production allowlist:
  * Exact package family and manifest scopes.
  * Explicit Store package exception if preserving the source Default behavior.
* Required inventory/capture before mutation:
  * Package identity, manifest path, package install state, dependency state,
    and current registration state.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify package registration outcome per exact package.
  * Verify Store/framework/dependency packages are not touched unless approved.
* Rollback/restore feasibility:
  * Re-registration is a repair/default operation, not a captured Restore.
* Risk level: high
* Whether it can be implemented later:
  * Only after exact AppX scopes are approved.
* Whether it must remain refused:
  * Broad wildcard re-registration remains refused.

### 9. Downloads/Installers or Repair Installer Behavior If Present

* Exact source URLs:
  * `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edgewebview.exe`
  * `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/gamingrepairtool.exe`
* Exact source paths:
  * `$env:SystemRoot\Temp\edgewebview.exe`
  * `$env:SystemRoot\Temp\gamingrepairtool.exe`
* Exact source commands:
  * `IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edgewebview.exe" -OutFile "$env:SystemRoot\Temp\edgewebview.exe"`
  * `Start-Process -Wait "$env:SystemRoot\Temp\edgewebview.exe"`
  * `IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/gamingrepairtool.exe" -OutFile "$env:SystemRoot\Temp\gamingrepairtool.exe"`
  * `Start-Process "$env:SystemRoot\Temp\gamingrepairtool.exe"`
* Intended mutation type:
  * Download and execute repair installers/tools.
* Required foundation:
  * Phase 35 download provenance and installer execution policy.
  * Phase 38 cleanup policy for generated temp artifacts.
* Required future production allowlist:
  * Exact artifact id, source URL, expected file name, expected SHA-256, size,
    signer/publisher, allowed consumer tool id, execution permission, admin
    requirement, reboot possibility, and verification requirements.
  * Exact installer command descriptor, timeout, and exit-code policy.
* Required inventory/capture before mutation:
  * Local artifact verification result.
  * Installer execution request record.
  * Existing temp file state before download/overwrite.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify artifact provenance before download/use.
  * Verify downloaded file name, hash, size, and Authenticode signer.
  * Verify no network execution directly from URL.
  * Capture process exit result when launch is approved.
* Rollback/restore feasibility:
  * Repair installer execution is not Restore. It can be part of a future
    Default/repair path only after artifact and execution approval.
* Risk level: high
* Whether it can be implemented later:
  * Only after exact provenance and installer descriptors are approved.
* Whether it must remain refused:
  * Current mutable GitHub raw URLs remain refused.

### 10. Default/Restore Behavior

* Exact source Default behavior:
  * Imports `$env:SystemRoot\Temp\gamebaron.reg`.
  * Sets PresenceWriter `ActivationType=1` using TrustedInstaller.
  * Re-registers `*Gaming*`, `*Xbox*`, and `*Store*` AppX packages.
  * Downloads and launches `edgewebview.exe`.
  * Downloads and launches `gamingrepairtool.exe`.
* Intended mutation type:
  * Source-defined repair/default workflow, not captured-state Restore.
* Required foundation:
  * Phase 35, Phase 36, Phase 37, Phase 38, Phase 39, and Phase 42.
* Required future production allowlist:
  * Exact registry, TrustedInstaller, AppX, service, process, file, download,
    and installer scopes.
* Required inventory/capture before mutation:
  * Registry records, service records, package inventory, generated file
    records, and artifact verification records.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify each source-defined Default target separately.
  * Verify repair tools were approved before launch.
* Rollback/restore feasibility:
  * Current Default/Restore must remain unavailable. Source Default is a repair
    and source-default path; it does not restore arbitrary prior user state.
    Restore requires exact captured-state, AppX inventory restore, installer
    repair provenance, and generated-file ownership selection.
* Risk level: high
* Whether it can be implemented later:
  * Default can be considered only after every constituent scope is approved.
* Whether it must remain refused:
  * Restore must remain refused until record-based restore is approved.

### 11. Unsupported Broad Package/Service/File/Registry Targets

* Exact source targets:
  * Package wildcard `*Gaming*`
  * Package wildcard `*Xbox*`
  * Package wildcard `*Store*`
  * Uninstall registry wildcard
    `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*`
  * Display name wildcard `*Microsoft GameInput*`
  * Protocol-key deletion and recreation under `HKEY_CLASSES_ROOT\ms-gamebar`,
    `HKEY_CLASSES_ROOT\ms-gamebarservices`, and
    `HKEY_CLASSES_ROOT\ms-gamingoverlay`
  * TrustedInstaller service mutation through
    `sc.exe config TrustedInstaller binPath=`
  * TrustedInstaller start through `sc.exe start TrustedInstaller`
* Intended mutation type:
  * Broad package selection, dynamic uninstall selection, protocol registry
    mutation, and privileged registry write.
* Required foundation:
  * Phase 35, Phase 36, Phase 37, Phase 39, and Phase 42.
* Required future production allowlist:
  * Exact targets only. Wildcards and dynamic broad selectors are not approved.
* Required inventory/capture before mutation:
  * Exact package, service, registry, and product identity inventories.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify broad selectors resolve only approved targets or block execution.
* Rollback/restore feasibility:
  * Not feasible without exact inventories and captured state.
* Risk level: high
* Whether it can be implemented later:
  * Only after broad source behavior is decomposed into exact scopes.
* Whether it must remain refused:
  * All broad selectors in this group must remain refused.

### 12. Unsupported Windows 10-Only Branches/Options If Present

* Exact source targets:
  * None found.
* Source options:
  * No explicit Windows 10-only menu branch or source option was found.
* Intended mutation type:
  * Not applicable.
* Required foundation:
  * Phase 48 branch-level product scope.
* Required future production allowlist:
  * None for Windows 10-only behavior because no such branch exists in this
    source.
* Required inventory/capture before mutation:
  * Not applicable.
* Required confirmation level:
  * Not applicable for product-scope gating.
* Required verification:
  * Future implementation must verify that it is not adding Windows 10-only
    behavior not present in the approved source.
* Rollback/restore feasibility:
  * Not applicable.
* Risk level: not applicable
* Whether it can be implemented later:
  * Shared Windows behavior may be reconsidered if every non-product-scope
    blocker is solved.
* Whether it must remain refused:
  * Any future Windows 10-only branch invented outside the source must remain
    refused.

## Exact Source Target Inventory

Package selectors:

* `*Gaming*`
* `*Xbox*`
* `*Store*`
* `Remove-AppxPackage`
* `Add-AppxPackage -DisableDevelopmentMode -Register`

Services and processes:

* `GameInputSvc`
* `GameBar`
* `gamingservices`
* `gamingservicesnet`
* `GameInputRedistService`

Registry paths and values:

* `HKCU\System\GameConfigStore`
* `HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR`
* `HKCU\Software\Microsoft\GameBar`
* `HKEY_CLASSES_ROOT\ms-gamebar`
* `HKEY_CLASSES_ROOT\ms-gamebarservices`
* `HKEY_CLASSES_ROOT\ms-gamingoverlay`
* `HKLM\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter`
* `HKLM\SYSTEM\ControlSet001\Services\GameInputSvc`
* `HKLM\SYSTEM\ControlSet001\Services\BcastDVRUserService`
* `HKLM\SYSTEM\ControlSet001\Services\XboxGipSvc`
* `HKLM\SYSTEM\ControlSet001\Services\XblAuthManager`
* `HKLM\SYSTEM\ControlSet001\Services\XblGameSave`
* `HKLM\SYSTEM\ControlSet001\Services\XboxNetApiSvc`

Generated files and artifacts:

* `$env:SystemRoot\Temp\gamebaroff.reg`
* `$env:SystemRoot\Temp\gamebaron.reg`
* `$env:SystemRoot\Temp\edgewebview.exe`
* `$env:SystemRoot\Temp\gamingrepairtool.exe`

Downloads:

* `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edgewebview.exe`
* `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/gamingrepairtool.exe`

Installer and privileged commands:

* `Start-Process "msiexec.exe" -ArgumentList "/x $guid /qn /norestart" -Wait -NoNewWindow`
* `Start-Process -Wait "regedit.exe" -ArgumentList "/S `"$env:SystemRoot\Temp\gamebaroff.reg`"" -WindowStyle Hidden`
* `Start-Process -Wait "regedit.exe" -ArgumentList "/S `"$env:SystemRoot\Temp\gamebaron.reg`"" -WindowStyle Hidden`
* `Start-Process -Wait "$env:SystemRoot\Temp\edgewebview.exe"`
* `Start-Process "$env:SystemRoot\Temp\gamingrepairtool.exe"`
* `Run-Trusted -command`
* `sc.exe config TrustedInstaller binPath=`
* `sc.exe start TrustedInstaller`

## Future Safe Apply Requirements

A future safe Apply would require all of the following:

1. A tool-specific Action Plan decomposing the branch into exact package,
   service, process, registry, file, TrustedInstaller, installer, and download
   operations.
2. Exact AppX package scopes replacing all wildcard package matching.
3. Exact service and service-registry scopes for GameInput and Xbox services.
4. A process-handling policy and exact process scopes for GameBar and
   GameInput-related process stops.
5. Exact Microsoft GameInput uninstall product identity and MSI command
   descriptor.
6. Exact registry value/key scopes for HKCU, HKCR, and HKLM protocol and
   PresenceWriter targets.
7. Exact generated `.reg` file content hashes and protected temp-path ownership
   records.
8. Exact TrustedInstaller command scope for `ActivationType` only, with
   production TrustedInstaller execution still separately approved.
9. Exact artifact provenance records for `edgewebview.exe` and
   `gamingrepairtool.exe`, including immutable source evidence, expected
   SHA-256, size, signer/publisher, execution permission, and consumer tool id.
10. Exact installer execution descriptors, timeout rules, exit-code handling,
    and confirmation requirements.
11. Inventory/capture before every mutation.
12. Verification after every target group.
13. Explicit refusal of broad selectors if they cannot be decomposed into exact
    scopes.

## Default and Restore Boundary

The source Default branch is a source-default repair workflow, not a captured
Restore action.

BoostLab must not expose GameBar Default until exact package scopes,
TrustedInstaller scopes, registry scopes, service scopes, process scopes,
download artifacts, installer descriptors, and generated-file scopes are
approved.

BoostLab must not expose Restore until exact AppX inventory restore,
captured-state restore, repair provenance, generated-file ownership, and
quarantine/captured-state restore selection are implemented. Restore must be
record-based and target-specific.

Current Default/Restore must remain unavailable because the source Default
downloads repair tools, re-registers broad AppX packages, mutates service
registry values, and writes TrustedInstaller-protected state without capturing
the user's previous state.

## Production Approval State

No production AppX/package/service/registry/file/cleanup/download/installer/reboot scopes are approved by this document.

No production TrustedInstaller scope is approved by this document.

Specifically, this document does not approve:

* AppX package removal
* AppX package re-registration
* Microsoft Store package re-registration
* GameInput service stop
* GameInput process stop
* Gaming Services process stop
* Microsoft GameInput uninstall
* `msiexec.exe` execution
* `regedit.exe` import
* HKCR protocol override writes or deletes
* HKCU Game DVR or Game Bar value writes or deletes
* HKLM PresenceWriter `ActivationType` writes
* TrustedInstaller service mutation
* Generated `.reg` file creation
* `edgewebview.exe` download
* `gamingrepairtool.exe` download
* Repair installer execution
* Default behavior
* Restore behavior

GameBar remains a refused placeholder until a future phase explicitly approves
exact bounded scopes and implements a reviewed workflow.
