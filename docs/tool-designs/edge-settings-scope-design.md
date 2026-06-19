# Edge Settings Scope Design

## Purpose

This Phase 63 document defines the future implementation scope for the
`Edge Settings` tool. It is design-only.

No Edge Settings behavior is implemented by this document. No runtime behavior,
module behavior, production Edge policy scope, registry scope, service scope,
scheduled task scope, file scope, cleanup scope, download artifact approval,
installer execution approval, process scope, Active Setup scope, RunOnce scope,
BHO scope, Default behavior, or Restore behavior is approved here.

Edge Settings remains a refused placeholder until a later approved phase adds
exact bounded production scopes and implementation.

## Source Reference

* Source path: `source-ultimate/3 Setup/6 Edge Settings.ps1`
* Source SHA-256: `342869157930ECF0869A07B4254CB8F174C63648CD329DB3914BAD291CD5FF28`
* Current BoostLab module path: `modules/Setup/edge-settings.psm1`
* Current status: refused placeholder
* Current implemented actions: none

Relevant foundations:

* Phase 35: download provenance and installer execution policy
* Phase 36: file and registry state capture and rollback
* Phase 37: service state capture and rollback
* Phase 38: destructive cleanup policy
* Phase 40: reboot/recovery workflow

## Product Scope Decision

Phase 48 defines BoostLab product scope as branch-level scope. Shared Windows
behavior may be preserved if it otherwise passes governance. Explicit Windows
10-only branches or options must remain unsupported, disabled, visual-only, or
`NotApplicable`.

No Windows 10-only branch was found in `source-ultimate/3 Setup/6 Edge Settings.ps1`.
The source behavior is shared Windows behavior, but it remains blocked because
it requires HKLM Edge policy writes/deletes, Active Setup deletion, RunOnce
deletion, Edge service deletion, scheduled task deletion, BHO deletion, Edge
process handling, and mutable repair-installer download/execution.

## Source Behavior Summary

The Ultimate source exposes two console menu actions:

1. `Edge Settings: Optimize (Recommended)`
2. `Edge Settings: Default`

The source requires Administrator and internet connectivity up front.
No scheduled task mutation is approved in this phase; no scheduled task mutation is approved in this phase.

The Optimize branch:

* Writes an Edge extension force-install policy for uBlock Origin.
* Writes Edge policy values for hardware acceleration, background mode, and
  startup boost.
* Removes Active Setup components whose default value matches `*Edge*`.
* Removes RunOnce values whose names match `*msedge*`.
* Stops and deletes every service where `Name -match 'Edge'`.
* Unregisters every scheduled task where `TaskName -like '*Edge*'`.
* Deletes both IE-to-Edge Browser Helper Object registry keys.

The Default branch:

* Deletes the entire `HKLM\SOFTWARE\Policies\Microsoft\Edge` policy key.
* Stops `msedge`.
* Launches `msedge.exe --restore-last-session --disable-extensions`.
* Stops `msedge` again.
* Downloads `edge.exe` from a mutable GitHub raw URL into
  `$env:SystemRoot\Temp\edge.exe`.
* Starts `$env:SystemRoot\Temp\edge.exe`.

Per Phase 36, every registry and file mutation needs exact bounded targets and
capture before mutation. Broad policy-key deletion remains refused unless exact
rollback is approved.

Per Phase 37, service changes or deletions require exact future allowlist,
capture, confirmation, verification, and rollback design.

Per Phase 35, no external download or executable can be approved without exact
provenance, filename, version, size, hash, signer when applicable, and allowed
consumer. Mutable or unverified URLs remain refused.

Do not implement a policy-only subset: applying only the Edge policy values
would weaken and misrepresent the approved Ultimate behavior because the source
also removes Active Setup state, RunOnce state, services, scheduled tasks, BHO
keys, stops Edge, and runs a repair installer.
Any policy-only implementation would weaken Ultimate behavior.

## Current Decision

Phase 117 ordered parity review keeps Edge Settings blocked as
`DeferredNeedsYazanDecision`. Do not implement Analyze, Open, Apply, Default,
or Restore yet.

The current catalog suggests an `Open`-style assistant, but the approved source
is not open-only. Direct implementation is refused until Edge Settings is
decomposed into exact policy, service, task, process, repair, and rollback
scopes. Policy-only implementation would weaken Ultimate behavior.

The exact Yazan decision required before ordered parity can continue is whether
BoostLab may implement the full source workflow with production approvals for
dynamic Active Setup deletion, wildcard RunOnce deletion, dynamic Edge service
stop/delete, broad Edge scheduled-task deletion, BHO key deletion, broad Edge
policy key deletion, `msedge` launch/stop behavior, and the mutable GitHub
`edge.exe` repair download/installer. If that full workflow is not approved,
Yazan must explicitly define a final Edge Settings scope exception; otherwise
the ordered parity cursor remains on `edge-settings`.

## Behavior Groups

### 1. Edge Policy Registry Behavior

* Exact source targets:
  * `HKLM\SOFTWARE\Policies\Microsoft\Edge`
  * `HardwareAccelerationModeEnabled=REG_DWORD 0`
  * `BackgroundModeEnabled=REG_DWORD 0`
  * `StartupBoostEnabled=REG_DWORD 0`
  * Default deletes `HKLM\SOFTWARE\Policies\Microsoft\Edge`
* Exact source commands:
  * `cmd /c "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Edge`" /v `"HardwareAccelerationModeEnabled`" /t REG_DWORD /d `"0`" /f >nul 2>&1"`
  * `cmd /c "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Edge`" /v `"BackgroundModeEnabled`" /t REG_DWORD /d `"0`" /f >nul 2>&1"`
  * `cmd /c "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Edge`" /v `"StartupBoostEnabled`" /t REG_DWORD /d `"0`" /f >nul 2>&1"`
  * `cmd /c "reg delete `"HKLM\SOFTWARE\Policies\Microsoft\Edge`" /f >nul 2>&1"`
* Source menu options:
  * `Edge Settings: Optimize (Recommended)`
  * `Edge Settings: Default`
* Intended mutation or launch type:
  * HKLM policy value writes and broad HKLM policy key deletion.
* Required foundation:
  * Phase 36 file and registry state capture and rollback.
* Required future production allowlist:
  * Exact value scopes for the three Edge policy values.
  * Exact key scope only if full policy-key deletion is explicitly approved.
* Required inventory/capture before mutation:
  * Previous value existence, type, and data for every policy value.
  * Full key manifest before any approved key deletion.
* Required confirmation level:
  * Explicit Action Plan confirmation because HKLM policy mutation is
    system-changing and because policy-only implementation would weaken source
    behavior.
* Required verification:
  * Verify Optimize writes each source-defined value as `REG_DWORD 0`.
  * Verify Default deletes only approved Edge policy values/keys.
  * Verify broad policy-key deletion did not remove unrelated values unless an
    exact captured-state rollback path exists.
* Rollback/restore feasibility:
  * Value-level restore is feasible only from captured Phase 36 state.
  * Broad key deletion is not safely restorable without exact key capture and
    current-state identity checks.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only as part of the full approved Edge Settings behavior, not as a weakened
    standalone policy subset.
* Whether it must remain refused:
  * Broad `HKLM\SOFTWARE\Policies\Microsoft\Edge` deletion remains refused.

### 2. Edge Extension Force-Install Behavior

* Exact source targets:
  * `HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist`
  * Value name `1`
  * Value type `REG_SZ`
  * Value data
    `odfafepnkmbhccpbejgmiehpchacaeak;https://edge.microsoft.com/extensionwebstorebase/v1/crx`
* Exact source command:
  * `cmd /c "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist`" /v `"1`" /t REG_SZ /d `"odfafepnkmbhccpbejgmiehpchacaeak;https://edge.microsoft.com/extensionwebstorebase/v1/crx`" /f >nul 2>&1"`
* Source menu options:
  * `Edge Settings: Optimize (Recommended)`
* Intended mutation or launch type:
  * HKLM Edge extension force-install policy write.
* Required foundation:
  * Phase 36 registry state capture and rollback.
* Required future production allowlist:
  * Exact extension force-install value scope and exact extension id.
* Required inventory/capture before mutation:
  * Previous existence, type, and data for value `1`.
  * Any existing `ExtensionInstallForcelist` key manifest if key creation or
    deletion is approved.
* Required confirmation level:
  * Explicit Action Plan confirmation.
* Required verification:
  * Verify the value exists as `REG_SZ` with the exact source-defined extension
    id and update URL.
  * Verify no unrelated extension force-install values were overwritten unless
    captured and explicitly approved.
* Rollback/restore feasibility:
  * Feasible only from Phase 36 captured value state.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after exact Edge extension policy scope and extension decision are
    approved.
* Whether it must remain refused:
  * Current production force-install scope remains refused.

### 3. Edge Services Behavior

* Exact source targets:
  * `$services = Get-Service | Where-Object { $_.Name -match 'Edge' }`
  * Dynamic service names matching `Edge`
* Exact source commands:
  * `cmd /c "sc stop `"$($service.Name)`" >nul 2>&1"`
  * `cmd /c "sc delete `"$($service.Name)`" >nul 2>&1"`
* Source menu options:
  * `Edge Settings: Optimize (Recommended)`
* Intended mutation or launch type:
  * Dynamic service stop and service deletion.
* Required foundation:
  * Phase 37 service state capture and rollback.
* Required future production allowlist:
  * Exact service names only. Regex service discovery `Name -match 'Edge'`
    must not become a production scope.
  * Separate approval for service deletion/recreation, because Phase 37 does
    not currently authorize service deletion rollback.
* Required inventory/capture before mutation:
  * Complete service state, start type, binary path, display name, dependencies,
    running status, and protected-service classification for each exact service.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify only approved service names were stopped or deleted.
  * Verify service deletion result and any remaining service state.
* Rollback/restore feasibility:
  * Not feasible under current service foundation because deletion/recreation is
    not approved.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after exact service scopes and deletion/recreation design are approved.
* Whether it must remain refused:
  * Dynamic Edge service deletion remains refused.

### 4. Edge Scheduled Tasks Behavior

* Exact source targets:
  * `Get-ScheduledTask | Where-Object { $_.TaskName -like '*Edge*' }`
* Exact source command:
  * `Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue`
* Source menu options:
  * `Edge Settings: Optimize (Recommended)`
* Intended mutation or launch type:
  * Broad scheduled task deletion.
* Required foundation:
  * A future scheduled task inventory and rollback policy is still needed.
* Required future production allowlist:
  * Exact task path and task name, not `*Edge*` discovery.
* Required inventory/capture before mutation:
  * Task XML, task path, task name, principal, triggers, actions, settings,
    enabled state, and running state.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify only approved scheduled tasks were unregistered.
  * Verify no unrelated task containing `Edge` was removed.
* Rollback/restore feasibility:
  * Not feasible without captured task XML and task recreation governance.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after scheduled task governance exists.
* Whether it must remain refused:
  * Scheduled task mutation is not approved in this phase and remains refused.

### 5. Active Setup Behavior

* Exact source targets:
  * `HKLM:\Software\Microsoft\Active Setup\Installed Components`
  * Child keys whose default value matches `*Edge*`
* Exact source commands:
  * `Get-ChildItem $basePath`
  * `(Get-ItemProperty $_.PsPath)."(default)"`
  * `Remove-Item $_.PsPath -Force -ErrorAction SilentlyContinue`
* Source menu options:
  * `Edge Settings: Optimize (Recommended)`
* Intended mutation or launch type:
  * Dynamic Active Setup registry key deletion.
* Required foundation:
  * Phase 36 registry state capture and rollback.
  * A future Active Setup governance decision may be needed because Active
    Setup entries can affect per-user initialization.
* Required future production allowlist:
  * Exact Active Setup component ids and exact default-value identity checks.
* Required inventory/capture before mutation:
  * Full key manifest for every exact Active Setup component before deletion.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify only exact approved component ids were deleted.
  * Verify broad default-value matching `*Edge*` did not remove unrelated
    components.
* Rollback/restore feasibility:
  * Possible only from exact Phase 36 key capture and current-state identity
    checks.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after exact Active Setup scopes are approved.
* Whether it must remain refused:
  * Dynamic Active Setup deletion remains refused.

### 6. RunOnce Behavior

* Exact source targets:
  * `HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce`
  * Any value name matching `*msedge*`
* Exact source command:
  * `Get-Item $runOncePath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Property | Where-Object { $_ -like "*msedge*" } | ForEach-Object { Remove-ItemProperty -Path $runOncePath -Name $_ -Force -ErrorAction SilentlyContinue }`
* Source menu options:
  * `Edge Settings: Optimize (Recommended)`
* Intended mutation or launch type:
  * Dynamic RunOnce registry value deletion.
* Required foundation:
  * Phase 36 registry state capture and rollback.
  * A future RunOnce-specific governance decision may be needed because RunOnce
    entries can be workflow/resume handlers.
* Required future production allowlist:
  * Exact value names and expected data, not wildcard `*msedge*` selection.
* Required inventory/capture before mutation:
  * Previous existence, type, and data for each exact value.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify only approved RunOnce values were removed.
  * Verify no unrelated installer/resume value was deleted.
* Rollback/restore feasibility:
  * Value restore is feasible only from Phase 36 captured state.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after exact RunOnce scopes are approved.
* Whether it must remain refused:
  * Wildcard RunOnce deletion remains refused.

### 7. BHO / Browser Helper Object Behavior

* Exact source targets:
  * `HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}`
  * `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}`
* Exact source commands:
  * `cmd /c "reg delete `"HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}`" /f >nul 2>&1"`
  * `cmd /c "reg delete `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}`" /f >nul 2>&1"`
* Source menu options:
  * `Edge Settings: Optimize (Recommended)`
* Intended mutation or launch type:
  * BHO registry key deletion.
* Required foundation:
  * Phase 36 registry state capture and rollback.
* Required future production allowlist:
  * Exact BHO key scopes for the CLSID
    `{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}`.
* Required inventory/capture before mutation:
  * Full key manifests before deletion.
* Required confirmation level:
  * Explicit Action Plan confirmation.
* Required verification:
  * Verify only the approved BHO CLSID keys were removed.
  * Verify captured state exists if Restore is ever claimed.
* Rollback/restore feasibility:
  * Possible only from exact Phase 36 key capture.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after exact BHO scopes are approved.
* Whether it must remain refused:
  * BHO deletion remains refused until scoped.

### 8. Edge Process Stop Behavior

* Exact source targets:
  * Process name `msedge`
* Exact source commands:
  * `Stop-Process -Name "msedge" -Force -ErrorAction SilentlyContinue`
  * `Start-Sleep -Seconds 2`
* Source menu options:
  * `Edge Settings: Default`
* Intended mutation or launch type:
  * Force-stop Edge before and after launching Edge restore.
* Required foundation:
  * A future process-handling policy is still needed.
* Required future production allowlist:
  * Exact process name, executable identity, owner/session rules, and reason
    for stopping.
* Required inventory/capture before mutation:
  * Process id, executable path, command line if safely available, owner/session,
    and reason for stopping.
* Required confirmation level:
  * Explicit Action Plan confirmation.
* Required verification:
  * Verify only approved `msedge` processes were targeted.
  * Report already-stopped processes as non-errors.
* Rollback/restore feasibility:
  * Process state is not restorable. The tool must not claim Restore for
    stopped processes.
* Risk level:
  * Medium to high.
* Whether it can be implemented later:
  * Only after process-handling governance exists.
* Whether it must remain refused:
  * Force-stop process behavior remains refused for now.

### 9. External Edge Executable Download Behavior

* Exact source targets:
  * URL `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe`
  * Path `$env:SystemRoot\Temp\edge.exe`
* Exact source commands:
  * `IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe" -OutFile "$env:SystemRoot\Temp\edge.exe"`
  * `Start-Process "$env:SystemRoot\Temp\edge.exe"`
* Source menu options:
  * `Edge Settings: Default`
* Intended mutation or launch type:
  * Download and execute Edge repair installer.
* Required foundation:
  * Phase 35 download provenance and installer execution policy.
  * Phase 36 file state capture for generated/overwritten temp path.
  * Phase 38 cleanup policy if cleanup is later added.
* Required future production allowlist:
  * Exact artifact id, source URL, expected filename, expected version, expected
    size, expected SHA-256, signer/publisher, allowed consumer tool id,
    execution permission, admin requirement, reboot possibility, and
    verification requirements.
  * Exact installer command descriptor, timeout, and exit-code policy.
* Required inventory/capture before mutation:
  * Existing temp file state before overwrite.
  * Local artifact verification record before execution.
  * Installer execution request record.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify artifact provenance before download/use.
  * Verify downloaded file name, hash, size, and Authenticode signer.
  * Verify no network execution directly from URL.
  * Capture process exit result when launch is approved.
* Rollback/restore feasibility:
  * Installer execution is not Restore. Repair can be considered only after
    artifact and execution approval.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after exact provenance and installer descriptors are approved.
* Whether it must remain refused:
  * Current mutable GitHub raw URL remains refused.

### 10. File/Directory Cleanup Behavior If Present

* Exact source targets:
  * `$env:SystemRoot\Temp\edge.exe`
* Source behavior:
  * Downloads the file to `%SystemRoot%\Temp`.
  * Does not explicitly delete the file afterward.
* Source menu options:
  * `Edge Settings: Default`
* Intended mutation or launch type:
  * Generated/downloaded file placement. No explicit cleanup is present.
* Required foundation:
  * Phase 36 file state capture where overwrite could occur.
  * Phase 38 cleanup policy if cleanup is later added.
  * Phase 35 artifact provenance for the executable.
* Required future production allowlist:
  * Exact temp artifact path tied to an approved artifact.
* Required inventory/capture before mutation:
  * Previous file existence, hash, size, owner, and timestamp.
  * Generated artifact ownership record.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation when downloading or executing.
* Required verification:
  * Verify existing files are not overwritten without capture and approval.
  * Verify any cleanup later touches only BoostLab-owned generated artifacts.
* Rollback/restore feasibility:
  * Generated file cleanup can be safe only when BoostLab owns the generated
    file record. Restore of a pre-existing file requires captured backup state.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after exact file and artifact scopes are approved.
* Whether it must remain refused:
  * Downloaded executable placement remains refused until provenance exists.

### 11. Default/Restore Behavior

* Exact source Default behavior:
  * Delete `HKLM\SOFTWARE\Policies\Microsoft\Edge`.
  * Stop `msedge`.
  * Launch `msedge.exe --restore-last-session --disable-extensions`.
  * Stop `msedge` again.
  * Download `$env:SystemRoot\Temp\edge.exe`.
  * Start `$env:SystemRoot\Temp\edge.exe`.
* Source menu options:
  * `Edge Settings: Default`
* Intended mutation or launch type:
  * Source-default repair/reset workflow, not captured-state Restore.
* Required foundation:
  * Phase 35, Phase 36, Phase 38, and a future process-handling policy.
* Required future production allowlist:
  * Exact registry, process, file, download, and installer scopes.
* Required inventory/capture before mutation:
  * Registry records, process plan, temp file record, artifact verification
    record, and installer request record.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify each registry, process, artifact, launch, and installer outcome.
* Rollback/restore feasibility:
  * Current Default/Restore must remain unavailable. Source Default is a
    repair/reset path and does not reconstruct arbitrary prior Edge policy,
    service, task, file, extension, or process state.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Default can be considered only after every constituent scope is approved.
* Whether it must remain refused:
  * Restore must remain refused until record-based registry, service/task/file,
    cleanup, and repair recovery is approved.

### 12. Unsupported Broad Edge Policy/Service/Task/File/Registry Targets

* Exact source targets:
  * Entire key `HKLM\SOFTWARE\Policies\Microsoft\Edge`
  * Active Setup children whose default value matches `*Edge*`
  * RunOnce values whose names match `*msedge*`
  * Services where `Name -match 'Edge'`
  * Scheduled tasks where `TaskName -like '*Edge*'`
  * BHO keys under HKLM for CLSID
    `{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}`
  * `$env:SystemRoot\Temp\edge.exe`
* Source menu options:
  * `Edge Settings: Optimize (Recommended)`
  * `Edge Settings: Default`
* Intended mutation or launch type:
  * Broad registry deletion, dynamic service deletion, dynamic task deletion,
    process/file/download handling, and policy reset.
* Required foundation:
  * Phase 35, Phase 36, Phase 37, Phase 38, and future task/process governance.
* Required future production allowlist:
  * Exact targets only. Wildcards, regex discovery, and broad key deletion are
    not approved.
* Required inventory/capture before mutation:
  * Exact registry, service, task, process, and file inventories.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify broad selectors are replaced by exact scopes or block execution.
* Rollback/restore feasibility:
  * Not feasible without exact inventories and captured state.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after broad source behavior is decomposed into exact scopes.
* Whether it must remain refused:
  * All broad selectors in this group must remain refused.

### 13. Unsupported Windows 10-Only Branches/Options If Present

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

Edge policies and extension:

* `HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist`
* `odfafepnkmbhccpbejgmiehpchacaeak;https://edge.microsoft.com/extensionwebstorebase/v1/crx`
* `HKLM\SOFTWARE\Policies\Microsoft\Edge`
* `HardwareAccelerationModeEnabled`
* `BackgroundModeEnabled`
* `StartupBoostEnabled`

Active Setup, RunOnce, BHO, services, and tasks:

* `HKLM:\Software\Microsoft\Active Setup\Installed Components`
* Default value match `*Edge*`
* `HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce`
* Value name match `*msedge*`
* `Get-Service | Where-Object { $_.Name -match 'Edge' }`
* `sc stop`
* `sc delete`
* `Get-ScheduledTask | Where-Object { $_.TaskName -like '*Edge*' }`
* `Unregister-ScheduledTask -Confirm:$false`
* `HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}`
* `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}`

Process and repair behavior:

* `msedge`
* `Stop-Process -Name "msedge" -Force -ErrorAction SilentlyContinue`
* `Start-Process "msedge.exe" -ArgumentList "--restore-last-session --disable-extensions"`
* `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe`
* `$env:SystemRoot\Temp\edge.exe`
* `IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe" -OutFile "$env:SystemRoot\Temp\edge.exe"`
* `Start-Process "$env:SystemRoot\Temp\edge.exe"`

## Future Safe Apply Requirements

A future safe Apply would require all of the following:

1. A tool-specific Action Plan decomposing the selected branch into exact Edge
   policy, extension, Active Setup, RunOnce, service, task, BHO, process, file,
   download, and installer operations.
2. Exact registry value scopes for each Edge policy and BHO target.
3. Exact Active Setup component scopes and RunOnce value scopes.
4. Exact service scopes replacing `Name -match 'Edge'`.
5. Exact scheduled task scopes after scheduled-task governance exists.
6. A process-handling policy and exact `msedge` process scope.
7. Exact artifact provenance for `edge.exe`, including immutable source
   evidence, expected SHA-256, size, signer/publisher, and allowed consumer.
8. Exact installer execution descriptor, timeout, exit-code handling, and
   confirmation rules.
9. Exact file scope for `$env:SystemRoot\Temp\edge.exe`.
10. Inventory/capture before every mutation.
11. Verification after every target group.
12. Explicit refusal of a policy-only subset because it would weaken Ultimate
    behavior.

## Default and Restore Boundary

The source Default branch is a repair/reset workflow, not a captured Restore
action.

BoostLab must not expose Edge Settings Default until exact registry rollback,
service/task rollback, file rollback, download provenance, installer execution,
cleanup restore, process handling, and captured-state restore selection are
approved.

BoostLab must not expose Restore until exact registry rollback, service/task
rollback, file rollback, cleanup restore, repair provenance, and captured-state
restore selection are implemented. Restore must be record-based and
target-specific.

Current Default/Restore must remain unavailable because the source Default
deletes the entire Edge policy key, stops Edge, launches Edge with restore
arguments, downloads an unapproved executable, and launches it without
capturing the previous Edge policy, service, task, file, or extension state.

## Production Approval State

No production Edge policy, extension, registry, service, task, file, cleanup,
download, installer, process, Active Setup, RunOnce, BHO, Default, or Restore
scope is approved by this document.

Specifically, this document does not approve:

* Edge policy writes
* Extension force-install policy
* Edge policy key deletion
* Active Setup deletion
* RunOnce deletion
* Edge service stop
* Edge service deletion
* Scheduled task deletion
* BHO deletion
* Edge process stop
* Edge restore-session launch
* `edge.exe` download
* `edge.exe` installer execution
* File overwrite or cleanup under `%SystemRoot%\Temp`
* Policy-only implementation
* Default behavior
* Restore behavior

Edge Settings remains a refused placeholder until a future phase explicitly
approves exact bounded scopes and implements a reviewed workflow.
