# Edge and WebView Scope Design

## Purpose

This Phase 52 document defined the future Auto implementation scope for the
`Edge & WebView` tool. Phase 147 supersedes the manual-handoff status by
implementing the two non-exit Ultimate source branches as source-equivalent
controlled Apply and Default workflows.

The Phase 147 implementation is module-scoped exact parity. It does not add
global artifact provenance approvals, production allowlist entries, reusable
Edge/WebView cleanup scopes, reusable installer approval, Open behavior, or
captured-state Restore behavior.

## Source Reference

* Source path: `source-ultimate/6 Windows/13 Edge & WebView.ps1`
* Source SHA-256: `3AB92D76307B1CB4C6988DB2201631C14D3B91B32CFFA4F1177B3E1F4F0D7966`
* Current BoostLab module path: `modules/Windows/edge-webview.psm1`
* Current status: exact source-equivalent controlled runtime
* Current implemented actions: `Apply`, `Default`
* Migration record: `docs/migrations/edge-webview.md`

Relevant foundations:

* Phase 35: download provenance and installer execution policy
* Phase 39: AppX package inventory and restore
* Phase 38: destructive cleanup policy
* Phase 36: file and registry state capture and rollback
* Phase 37: service state capture and rollback
* Phase 40: reboot/recovery workflow

## Source Behavior Summary

The Ultimate source exposes two menu actions:

1. `Edge & WebView: Uninstall`
2. `Edge & WebView: Default`

The source requires Administrator and internet connectivity up front.

The Default repair downloads are mutable `refs/heads/main` artifacts with no
approved SHA-256, size, signer, publisher, or installer execution record.

Per Phase 39, unknown packages remain denied, wildcard/broad packages remain
denied, and system-critical/framework/dependency packages remain denied unless
Yazan separately approves an exact exception with a recovery plan.

wildcard/broad packages remain denied.

The uninstall branch changes `DeviceRegion`, copies `reg.exe` into the working
directory as `reg1.exe`, stops many processes, removes EdgeUpdate registry
state, runs EdgeUpdate uninstallers, creates a fake legacy Edge SystemApps file,
uses the Edge uninstall string with `--force-uninstall`, deletes Edge/WebView
registry and file state, deletes Edge services, optionally removes a Windows
10 CBS package through DISM, restores the original region, and deletes
`reg1.exe`.

The Default branch stops the same broad process set, downloads `edge.exe` and
`edgewebview.exe` from mutable GitHub branch URLs, launches both installers,
writes Microsoft Edge policy registry values, removes Active Setup and RunOnce
Edge entries, deletes Edge services and scheduled tasks, and deletes IE-to-Edge
Browser Helper Object registry keys.

## Current Decision

Edge & WebView is implemented as exact source-equivalent controlled runtime in
Phase 147. Apply runs the source `Edge & WebView: Uninstall (Recommended)`
branch after confirmation. Default runs the source `Edge & WebView: Default`
repair branch after confirmation. Open and Restore remain unavailable because
the source does not define those branches.

The source combines package repair/removal, download and installer execution,
process termination, service deletion, scheduled task removal, broad file and
directory deletion, registry mutation, RunOnce and Active Setup deletion, and a
Windows 10 CBS/DISM package removal branch. Phase 147 represents that exact
module-scoped behavior in operation descriptors with test-safe mocks; it does
not create reusable global production allowlists or artifact approvals.

## Behavior Groups

### 1. Microsoft Edge Package/AppX Behavior

* Exact source targets:
  * `%SystemRoot%\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe`
  * `%SystemRoot%\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\MicrosoftEdge.exe`
  * `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge`
* Exact source behavior:
  * Creates the `Microsoft.MicrosoftEdge_8wekyb3d8bbwe` SystemApps directory.
  * Creates a placeholder `MicrosoftEdge.exe` file.
  * Reads the Edge uninstall string from 32-bit HKLM uninstall registry view.
  * Runs the uninstall string with `--force-uninstall`.
  * Deletes the SystemApps directory afterward.
* Intended mutation type:
  * File creation/deletion and installer/uninstaller launch for Microsoft Edge.
* Required foundation:
  * Phase 36 file and registry state capture and rollback
  * Phase 38 cleanup policy
  * Phase 35 installer execution policy
  * Phase 39 AppX package policy if any future branch treats Edge as AppX
* Required future production allowlist:
  * Exact SystemApps directory and generated placeholder file scope.
  * Exact uninstall registry key/value read scope.
  * Exact Edge uninstaller command approval, including `--force-uninstall`.
* Required inventory/capture before mutation:
  * Existing SystemApps directory/file state.
  * Edge uninstall registry value and product identity.
  * Edge installed version/path if discoverable.
* Required verification:
  * Verify only the exact placeholder file/directory created by BoostLab is
    deleted.
  * Verify Edge uninstall command identity and exit result.
  * Verify no protected AppX/framework package mutation occurs without Phase 39
    scope.
* Rollback/restore feasibility:
  * Not feasible as a generic Restore without approved repair installer
    provenance and captured state. Edge is a protected package family under
    Phase 39.
* Risk level: high
* Later implementation decision:
  * Must remain refused until exact Edge uninstaller and SystemApps scopes are
    approved.

### 2. Microsoft Edge WebView2 Behavior

* Exact source targets:
  * `HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView`
  * `%SystemRoot%\Temp\edgewebview.exe`
  * Process name `msedgewebview2`
* Exact source behavior:
  * Uninstall branch deletes the Edge WebView uninstall registry key.
  * Default branch downloads and runs `edgewebview.exe`.
* Intended mutation type:
  * Registry key deletion and installer repair/reinstall.
* Required foundation:
  * Phase 36 registry state capture and rollback
  * Phase 35 download provenance and installer execution policy
  * Phase 38 cleanup policy for generated temp installer
* Required future production allowlist:
  * Exact WebView uninstall key scope.
  * Exact artifact provenance for `edgewebview.exe`.
  * Exact installer execution request and allowed switches.
* Required inventory/capture before mutation:
  * WebView uninstall registry key state and values.
  * Local downloaded artifact hash, size, signer, publisher, and filename.
* Required verification:
  * Verify registry key mutation only touches the exact WebView key.
  * Verify downloaded installer matches approved provenance before execution.
  * Verify WebView installed/registered state after Default if approved.
* Rollback/restore feasibility:
  * Registry restore is possible only from Phase 36 captured state.
  * WebView repair requires exact approved installer provenance.
* Risk level: high
* Later implementation decision:
  * Must remain refused until the WebView artifact and registry scopes are
    approved.

### 3. Edge Update Services

* Exact source service discovery:
  * `Get-Service | Where-Object { $_.Name -match 'Edge' }`
* Exact source commands:
  * `sc stop "<service name>"`
  * `sc delete "<service name>"`
* Related process/source executable:
  * `MicrosoftEdgeUpdate.exe`
  * EdgeUpdate paths under LocalApplicationData, ProgramFilesX86, and
    ProgramFiles `Microsoft\EdgeUpdate\*.*.*.*\MicrosoftEdgeUpdate.exe`
* Intended mutation type:
  * Dynamic service stop/delete and EdgeUpdate unregistration/uninstall.
* Required foundation:
  * Phase 37 service state capture and rollback
  * Phase 35 installer/executable execution policy for `MicrosoftEdgeUpdate.exe`
  * Phase 36 file/registry capture for EdgeUpdate registry state
* Required future production allowlist:
  * Exact service names, not regex `Edge` discovery.
  * Exact EdgeUpdate executable paths and command arguments `/unregsvc` and
    `/uninstall`.
  * Explicit approval for service deletion/recreation if deletion is preserved.
* Required inventory/capture before mutation:
  * Complete service state for each exact service.
  * EdgeUpdate executable signer/version/path.
  * EdgeUpdate registry state before deletion.
* Required verification:
  * Verify only approved service names were stopped/deleted.
  * Verify EdgeUpdate executable path is approved before launch.
* Rollback/restore feasibility:
  * Phase 37 does not enable service deletion/recreation rollback. Restore
    remains unavailable without stronger service recreation design or approved
    repair installer.
* Risk level: high
* Later implementation decision:
  * Must remain refused until exact service names and deletion/repair strategy
    are approved.

### 4. Edge Scheduled Tasks

* Exact source task discovery:
  * `Get-ScheduledTask | Where-Object { $_.TaskName -like '*Edge*' }`
* Exact source mutation:
  * `Unregister-ScheduledTask -Confirm:$false`
* Intended mutation type:
  * Broad scheduled task deletion by wildcard-like task name filter.
* Required foundation:
  * A future scheduled-task inventory and rollback policy is still needed.
* Required future production allowlist:
  * Exact task path and task name, not `*Edge*` discovery.
  * Exact unregister permission per task.
* Required inventory/capture before mutation:
  * Task XML, principal, triggers, actions, settings, task path/name, enabled
    state, and running state.
* Required verification:
  * Verify only approved tasks were unregistered.
  * Verify no unrelated task containing `Edge` was removed.
* Rollback/restore feasibility:
  * Not feasible without captured task XML and task recreation governance.
* Risk level: high
* Later implementation decision:
  * Must remain refused until scheduled-task governance exists.

### 5. Program Files / Program Files (x86) Microsoft Edge Directories

* Exact source paths:
  * `%SystemDrive%\Program Files (x86)\Microsoft`
  * EdgeUpdate discovery under `%LOCALAPPDATA%\Microsoft\EdgeUpdate`
  * EdgeUpdate discovery under `%ProgramFiles(x86)%\Microsoft\EdgeUpdate`
  * EdgeUpdate discovery under `%ProgramFiles%\Microsoft\EdgeUpdate`
* Exact source mutation:
  * Recursively deletes `%SystemDrive%\Program Files (x86)\Microsoft`.
* Intended mutation type:
  * Broad directory deletion and executable discovery.
* Required foundation:
  * Phase 38 destructive cleanup policy
  * Phase 36 file/directory state capture and rollback
* Required future production allowlist:
  * Exact Edge/WebView subdirectories only. The broad Microsoft vendor folder
    must remain refused.
  * Recursive file-count/size/depth limits and reparse-point denial.
* Required inventory/capture before mutation:
  * Directory manifest for every approved subdirectory.
  * Hashes/metadata for generated or removed files where feasible.
* Required verification:
  * Verify path normalization does not target the whole Microsoft folder unless
    separately approved, which is not approved here.
  * Verify no unrelated Microsoft product directory is touched.
* Rollback/restore feasibility:
  * Quarantine or captured-state restore only for exact bounded directories.
    Broad permanent deletion is not safely restorable.
* Risk level: high
* Later implementation decision:
  * Broad `%SystemDrive%\Program Files (x86)\Microsoft` deletion must remain
    refused.

### 6. Edge/WebView Registry Paths

* Exact source registry paths:
  * `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Control Panel\DeviceRegion`
  * `HKCU\SOFTWARE\Microsoft\EdgeUpdate`
  * `HKLM\SOFTWARE\Microsoft\EdgeUpdate`
  * `HKCU\SOFTWARE\Policies\Microsoft\EdgeUpdate`
  * `HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate`
  * `HKCU\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate`
  * `HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate`
  * `HKCU\SOFTWARE\WOW6432Node\Policies\Microsoft\EdgeUpdate`
  * `HKLM\SOFTWARE\WOW6432Node\Policies\Microsoft\EdgeUpdate`
  * `HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView`
  * `HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist`
  * `HKLM\SOFTWARE\Policies\Microsoft\Edge`
  * `HKLM\Software\Microsoft\Active Setup\Installed Components`
  * `HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce`
  * `HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}`
  * `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}`
* Exact source values:
  * `DeviceRegion=244`, then restore previous value if captured
  * Edge extension forcelist value `1=odfafepnkmbhccpbejgmiehpchacaeak;https://edge.microsoft.com/extensionwebstorebase/v1/crx`
  * `HardwareAccelerationModeEnabled=0`
  * `BackgroundModeEnabled=0`
  * `StartupBoostEnabled=0`
* Intended mutation type:
  * Registry value writes, broad key deletion, dynamic Active Setup key removal,
    RunOnce value deletion, and BHO key deletion.
* Required foundation:
  * Phase 36 registry state capture and rollback
* Required future production allowlist:
  * Exact value scopes for policy writes.
  * Exact key scopes for key deletion.
  * No dynamic Active Setup or RunOnce deletion until exact item discovery and
    capture rules are approved.
* Required inventory/capture before mutation:
  * Previous value existence, type, and data for every value.
  * Key manifests before key deletion.
  * DeviceRegion capture before temporary region mutation.
* Required verification:
  * Verify DeviceRegion restore succeeds when the source branch changes it.
  * Verify Edge policy values equal expected data.
  * Verify only approved Active Setup/RunOnce/BHO entries were removed.
* Rollback/restore feasibility:
  * Value-level restore is feasible from Phase 36 records.
  * Broad key restore requires exact captured key state and current-state
    identity checks.
* Risk level: high
* Later implementation decision:
  * Must remain refused until exact registry and dynamic discovery scopes are
    approved.

### 7. CBS/DISM/Package Removal Behavior If Present

* Exact source package discovery:
  * `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages`
  * Child key pattern `*Microsoft-Windows-Internet-Browser-Package*~~*`
* Exact source mutation:
  * Sets package `Visibility=1`
  * Deletes values under package `Owners`
  * Runs `dism /online /Remove-Package /PackageName:$EdgeLegacyPackage /quiet /norestart`
* Intended mutation type:
  * Windows 10 legacy Edge CBS package removal.
* Required foundation:
  * Phase 36 registry state capture
  * Phase 40 reboot/recovery workflow for component servicing state and
    possible reboot requirement
  * A future CBS/DISM package governance policy is still needed
* Required future production allowlist:
  * Exact CBS package identity.
  * Exact DISM command and arguments.
  * Explicit Windows 10 branch approval if product scope changes.
* Required inventory/capture before mutation:
  * Package identity, state, owners, visibility, and DISM applicability.
* Required verification:
  * Verify package state and reboot requirement after DISM.
* Rollback/restore feasibility:
  * Not currently feasible. CBS/DISM removal must remain refused without a
    dedicated package restore/recovery plan.
* Risk level: high
* Later implementation decision:
  * Must remain refused. This is an explicit Windows 10 legacy Edge branch and
    is outside current product scope.

### 8. RunOnce / Active Setup / Task Removal Behavior If Present

* Exact source targets:
  * `HKLM\Software\Microsoft\Active Setup\Installed Components`
  * Any child whose default value matches `*Edge*`
  * `HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce`
  * Any RunOnce value whose name matches `*msedge*`
  * Scheduled tasks whose `TaskName` matches `*Edge*`
* Intended mutation type:
  * Dynamic registry key/value deletion and scheduled task removal.
* Required foundation:
  * Phase 36 registry state capture
  * A future scheduled-task inventory/restore policy
* Required future production allowlist:
  * Exact Active Setup component ids.
  * Exact RunOnce value names.
  * Exact scheduled task paths/names.
* Required inventory/capture before mutation:
  * Registry key/value manifests and scheduled task XML.
* Required verification:
  * Verify only approved entries were removed.
  * Verify broad `*Edge*` and `*msedge*` discovery did not remove unrelated
    entries.
* Rollback/restore feasibility:
  * Registry restore is possible only from Phase 36 records.
  * Task restore requires future scheduled-task recreation governance.
* Risk level: high
* Later implementation decision:
  * Must remain refused until exact RunOnce, Active Setup, and task scopes are
    approved.

### 9. Process Stop Behavior

* Exact source process list:
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
* Intended mutation type:
  * Force-stop a broad process set before uninstall/default/repair operations.
* Required foundation:
  * A future process-handling policy is still needed.
  * Phase 40 recovery guidance may be relevant for user-session disruption.
* Required future production allowlist:
  * Exact process names and justification per process.
  * No wildcard `*edge*` process stop without a bounded process identity plan.
* Required inventory/capture before mutation:
  * Process id, executable path, command line if available, owner/session, and
    reason for stopping.
* Required verification:
  * Verify only approved processes were stopped.
  * Report processes that restarted or could not be stopped.
* Rollback/restore feasibility:
  * Process state is not restorable. The tool must not claim Restore for
    stopped processes.
* Risk level: high
* Later implementation decision:
  * Must remain refused until process-handling governance exists.

### 10. Downloads or Repair Installer Behavior

* Exact source URLs:
  * `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe`
  * `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edgewebview.exe`
* Exact source paths:
  * `%SystemRoot%\Temp\edge.exe`
  * `%SystemRoot%\Temp\edgewebview.exe`
* Exact source execution:
  * `Start-Process -Wait "$env:SystemRoot\Temp\edge.exe"`
  * `Start-Process -Wait "$env:SystemRoot\Temp\edgewebview.exe"`
* Intended mutation type:
  * Download and execute Edge/WebView repair installers.
* Required foundation:
  * Phase 35 download provenance and installer execution policy
  * Phase 38 cleanup policy for generated temp artifacts
* Required future production allowlist:
  * Exact artifact id, source URL, file name, version, size, SHA-256, signer,
    publisher, allowed consumer tool id, execution permission, admin
    requirement, reboot possibility, and verification requirements.
  * Exact installer command line and timeout.
* Required inventory/capture before mutation:
  * Local artifact verification result and installer request record.
* Required verification:
  * Verify filename, hash, size, Authenticode signer, and allowed consumer
    before execution.
  * Capture exit code and timeout result.
  * Verify Edge/WebView installed state after execution.
* Rollback/restore feasibility:
  * Repair is not Restore unless tied to exact captured prior state. Installer
    re-run may be a Default/repair branch only after provenance is approved.
* Risk level: high
* Later implementation decision:
  * Must remain refused. The current URLs are mutable `refs/heads/main`
    artifacts and have no approved hash, size, signer, or installer policy.

### 11. Default/Restore Behavior

* Exact source Default behavior:
  * Stop broad process set.
  * Download and run Edge installer.
  * Stop broad process set again.
  * Download and run Edge WebView installer.
  * Stop broad process set again.
  * Add Edge policies and uBlock Origin extension force install policy.
  * Remove Edge Active Setup entries.
  * Remove Edge RunOnce entries.
  * Delete Edge services and scheduled tasks.
  * Delete IE-to-Edge BHO keys.
* Intended mutation type:
  * Repair/reinstall plus policy hardening and cleanup.
* Required foundation:
  * Phase 35, Phase 36, Phase 37, Phase 38, Phase 39, and future scheduled-task
    and process-handling policies.
* Required future production allowlist:
  * Exact artifact approvals, installer requests, registry scopes, service
    scopes, task scopes, and process scopes.
* Required inventory/capture before mutation:
  * Installer artifact records, registry records, service records, task records,
    and process stop plan.
* Required verification:
  * Verify every repair, policy, service, task, BHO, and process outcome.
* Rollback/restore feasibility:
  * Source Default is not Restore. It does not reconstruct arbitrary prior
    Edge/WebView state. Restore remains unavailable unless exact captured-state,
    AppX/package inventory restore, repair provenance, or quarantine restore
    selection is implemented.
* Risk level: high
* Later implementation decision:
  * Must remain refused until every constituent scope is approved.

### 12. Unsupported Broad Deletion or Package Targets

* Exact broad source targets:
  * `%SystemDrive%\Program Files (x86)\Microsoft`
  * `Get-Service | Where-Object { $_.Name -match 'Edge' }`
  * `Get-ScheduledTask | Where-Object { $_.TaskName -like '*Edge*' }`
  * `Get-Process | Where-Object { $_.ProcessName -like "*edge*" }`
  * EdgeUpdate registry roots across HKCU/HKLM, policy, and WOW6432Node hives
  * CBS package pattern `*Microsoft-Windows-Internet-Browser-Package*~~*`
* Intended mutation type:
  * Broad cleanup, service/task deletion, process stop, registry deletion, and
    package removal.
* Required foundation:
  * Phase 36, Phase 37, Phase 38, Phase 40, and future task/process/CBS
    governance.
* Required future production allowlist:
  * None approved. Exact targets must replace broad patterns.
* Required inventory/capture before mutation:
  * Exact target inventories before any mutation.
* Required verification:
  * Verify broad patterns remain blocked unless decomposed into exact scopes.
* Rollback/restore feasibility:
  * Not feasible for broad deletion without captured/quarantined exact state.
* Risk level: high
* Later implementation decision:
  * Must remain refused as broad source behavior until exact safe scopes are
    approved.

## Product Scope Notes

The source includes an explicit Windows 10 legacy Edge CBS/DISM branch:

* `Microsoft-Windows-Internet-Browser-Package`
* `dism /online /Remove-Package`

Under Phase 48 branch-level product scope, this Windows 10-only legacy Edge
branch must remain unsupported, disabled, visual-only, or `NotApplicable`
unless Yazan expands scope.

Windows 10-only legacy Edge branch behavior is not approved by this design.

Shared Edge/WebView behavior may be designed later only after exact scopes,
artifact provenance, and restore strategy are approved.

## Future Safe Apply Requirements

A future safe Apply would require all of the following:

1. A tool-specific Action Plan decomposing the selected branch into exact
   registry, file, service, task, process, package, installer, and cleanup
   operations.
2. Exact artifact provenance records for `edge.exe` and `edgewebview.exe`, or a
   refusal of repair installer behavior if provenance cannot be completed.
3. Exact installer execution requests with command line, timeout, exit-code
   handling, and confirmation.
4. Exact file and directory scopes for every generated, deleted, or inspected
   target.
5. Exact registry scopes for policy values, BHO keys, EdgeUpdate roots,
   DeviceRegion, Active Setup, RunOnce, and uninstall keys.
6. Exact service scopes for every Edge service name.
7. Exact scheduled task scopes after a scheduled-task foundation exists.
8. Exact process scopes after a process-handling foundation exists.
9. Inventory/capture before every mutation.
10. Verification after every target group.
11. Explicit refusal of the Windows 10 CBS/DISM branch under current product
    scope.
12. No broad wildcard process, service, task, registry, file, or package
    selection.

## Default and Restore Boundary

The source Default branch is a repair/reinstall plus policy/cleanup workflow,
not a Restore action.

BoostLab exposes Edge & WebView Default only as the source repair/default
branch after explicit confirmation. Default is still not Restore and does not
claim captured-state rollback.

BoostLab must not expose Restore until exact inventory restore,
captured-state restore, repair provenance, or quarantine restore selection is
implemented. Restore must be target-specific and record-based.

## Production Approval State

No reusable production AppX/package/download/installer/cleanup/file/registry/
service/task/DISM/CBS/Restore scopes are approved by this document. Phase 147
implements only this tool's source-equivalent Apply and Default runtime.

Specifically, this document does not approve:

* Edge uninstall
* WebView uninstall
* Edge repair installer download
* WebView repair installer download
* Installer execution
* EdgeUpdate unregistration or uninstall
* Service stop or deletion
* Scheduled task unregister
* Process force-stop
* Program Files directory deletion
* SystemApps placeholder creation/deletion
* EdgeUpdate registry deletion
* Active Setup deletion
* RunOnce deletion
* Browser Helper Object deletion
* DeviceRegion mutation
* Edge policy writes
* uBlock Origin force-install policy
* CBS/DISM package removal
* Windows 10-only branches
* Restore behavior

Edge & WebView exact source-equivalent Apply and Default are implemented in
Phase 147. Restore remains blocked until a future phase explicitly approves a
captured-state restore contract; no such Restore behavior is added here.
