# Bloatware Scope Design

## Purpose

This Phase 51 document defines the future implementation scope for the
`Bloatware` tool. It is design-only.

No Bloatware behavior is implemented by this document. No runtime behavior,
module behavior, production AppX package allowlist, cleanup scope, file scope,
registry scope, service scope, scheduled-task scope, artifact approval, or
restore scope is approved here.

Bloatware remains a refused placeholder until a later approved phase adds exact
bounded production scopes and implementation.

## Source Reference

* Source path: `source-ultimate/6 Windows/11 Bloatware.ps1`
* Source SHA-256: `36677A334B37025A7234F4320EE54EF50E9528D1814E2B3A463EEB564C5814F5`
* Current BoostLab module path: `modules/Windows/bloatware.psm1`
* Current status: refused placeholder
* Current implemented actions: none

Relevant foundations:

* Phase 39: AppX package inventory and restore
* Phase 38: destructive cleanup policy
* Phase 36: file and registry state capture and rollback
* Phase 37: service state capture and rollback
* Phase 40: reboot/recovery workflow

## Source Behavior Summary

The Ultimate source is a menu with these options:

1. Exit
2. Remove all bloatware
3. Install Store
4. Install all UWP apps
5. Install UWP features
6. Install legacy features
7. Install OneDrive
8. Install Remote Desktop Connection
9. Install Snipping Tool

The script requires Administrator and internet connectivity up front, then
writes a passwordless sign-in registry value before the menu is shown:

* `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device`
* `DevicePasswordLessBuildVersion=0`

The main removal path uses broad inverse filters rather than exact target
allowlists. Future BoostLab implementation must not convert these wildcard
queries into broad production allowlists.

Per Phase 39, unknown packages remain denied, wildcard/broad packages remain
denied, and system-critical/framework/dependency packages remain denied unless
Yazan separately approves an exact exception with a recovery plan.

Future migration must not convert wildcard queries into broad production allowlists.

Phase 39 mutation names relevant to this design are `RemoveCurrentUser`,
`RemoveAllUsers`, `RemoveProvisioned`, `ReRegister`, and
`RepairRegistration`. Bloatware currently has no approved production scope for
any of them.

## Current Decision

Do not implement Analyze, Apply, Default, or Restore yet.

The source removes AppX packages, removes Windows capabilities, disables
optional features, stops and deletes services, takes ownership of a Windows
directory, deletes files, launches uninstallers, stops processes, unregisters
scheduled tasks, edits registry, loads and imports an app settings hive,
downloads installers, launches installers, and re-registers AppX packages.

That is too broad for a direct implementation. A future migration must split
the tool into exact approved scopes or refuse any branch that cannot preserve
Ultimate behavior safely.

## Behavior Groups

### 1. AppX Current-User Package Removals

* Exact source command:
  * The source does not use a current-user-only removal path.
* Intended mutation type:
  * Not present as a separate source branch.
* Required foundation:
  * Phase 39 AppX package inventory and restore
* Required production allowlist:
  * None approved.
  * A future current-user-only implementation would require exact package
    family names and exact `RemoveCurrentUser` scopes.
* Required inventory/capture before mutation:
  * Exact package family, full name, publisher, version, architecture, install
    location, dependencies, framework/dependency classification, and current
    user registration state.
* Required verification:
  * Verify only exact approved current-user packages were removed.
* Rollback/restore feasibility:
  * Only feasible with a valid Phase 39 inventory record and captured manifest
    path. Missing package content cannot be re-downloaded by this foundation.
* Risk level: high
* Later implementation decision:
  * Can be considered only as a deliberate redesign. It would not preserve the
    source's all-users behavior unless Yazan explicitly approves the deviation.

### 2. AppX All-Users Package Removals

* Exact source command:
  * `Get-AppXPackage -AllUsers | Where-Object { ... } | Remove-AppxPackage`
* Source exclusion patterns:
  * `*CBS*`
  * `*Microsoft.AV1VideoExtension*`
  * `*Microsoft.AVCEncoderVideoExtension*`
  * `*Microsoft.HEIFImageExtension*`
  * `*Microsoft.HEVCVideoExtension*`
  * `*Microsoft.MPEG2VideoExtension*`
  * `*Microsoft.Paint*`
  * `*Microsoft.RawImageExtension*`
  * `*Microsoft.SecHealthUI*`
  * `*Microsoft.VP9VideoExtensions*`
  * `*Microsoft.WebMediaExtensions*`
  * `*Microsoft.WebpImageExtension*`
  * `*Microsoft.Windows.Photos*`
  * `*Microsoft.Windows.ShellExperienceHost*`
  * `*Microsoft.Windows.StartMenuExperienceHost*`
  * `*Microsoft.WindowsNotepad*`
  * `*NVIDIACorp.NVIDIAControlPanel*`
  * `*windows.immersivecontrolpanel*`
* Intended mutation type:
  * Remove every all-users AppX package that does not match the exclusion list.
* Required foundation:
  * Phase 39 AppX package inventory and restore
* Required production allowlist:
  * Exact package family names.
  * Exact `RemoveAllUsers` permission per family.
  * Separate approval for any protected, framework, dependency, Store, Shell,
    Start Menu, WebView, Edge, VCLibs, UI Xaml, .NET Native, Windows App
    Runtime, or other system-critical package.
* Required inventory/capture before mutation:
  * Full all-users package inventory for every exact package to remove.
  * Dependency and protected-package classification.
  * Per-user registration state and provisioned state where applicable.
* Required verification:
  * Verify each approved package was removed from the requested user scope.
  * Verify no unapproved package was removed.
  * Verify protected and dependency packages were not touched unless separately
    approved.
* Rollback/restore feasibility:
  * Restore is record-based only and depends on captured manifests/package
    content. Broad re-registration is not a safe restore.
* Risk level: high
* Later implementation decision:
  * Must remain refused until exact package families are approved. The source's
    inverse wildcard query is not an acceptable BoostLab allowlist.

### 3. Provisioned Package Removals

* Exact source command:
  * None present.
* Intended mutation type:
  * Not present in the source.
* Required foundation:
  * Phase 39 AppX package inventory and restore if added later.
* Required production allowlist:
  * No provisioned-package scope may be inferred from this source.
* Required inventory/capture before mutation:
  * Not applicable while unsupported.
* Required verification:
  * A future validator must reject provisioned package removal for Bloatware
    unless explicitly approved.
* Rollback/restore feasibility:
  * Not applicable.
* Risk level: high if added later
* Later implementation decision:
  * Must remain refused unless Yazan explicitly approves a new source-backed
    provisioned package branch.

### 4. Windows Capabilities

* Exact source command:
  * `Get-WindowsCapability -Online | Where-Object { ... } | Remove-WindowsCapability -Online -Name $_.Name`
* Source exclusion patterns:
  * `*Microsoft.Windows.Ethernet*`
  * `*Microsoft.Windows.MSPaint*`
  * `*Microsoft.Windows.Notepad*`
  * `*Microsoft.Windows.Notepad.System*`
  * `*Microsoft.Windows.Wifi*`
  * `*NetFX3*`
  * `*VBSCRIPT*`
  * `*WMIC*`
  * `*Windows.Client.ShellComponents*`
* Intended mutation type:
  * Remove every online Windows capability that does not match the exclusion
    list.
* Required foundation:
  * A future Windows capability inventory and rollback policy is still needed.
  * Phase 40 may be needed for capabilities that require restart.
* Required production allowlist:
  * Exact capability names and versions.
  * Exact removal approval per capability.
  * Explicit decision on Windows 10-only capability branches.
* Required inventory/capture before mutation:
  * Online capability state, install state, source package identity if
    available, restart requirement, and dependency information.
* Required verification:
  * Verify each exact approved capability state after removal.
  * Verify excluded and unapproved capabilities were not touched.
* Rollback/restore feasibility:
  * Not currently feasible through an approved BoostLab foundation. Installing
    capabilities may require source media, Windows Update, reboot, or DISM
    behavior not approved here.
* Risk level: high
* Later implementation decision:
  * Must remain refused until a capability-specific scope and restore strategy
    exist.

### 5. Optional Features

* Exact source command:
  * `Get-WindowsOptionalFeature -Online | Where-Object { ... } | Disable-WindowsOptionalFeature -Online -FeatureName $_.FeatureName -NoRestart`
* Source exclusion patterns:
  * `*DirectPlay*`
  * `*LegacyComponents*`
  * `*NetFx3*`
  * `*NetFx4*`
  * `*NetFx4-AdvSrvs*`
  * `*NetFx4ServerFeatures*`
  * `*SearchEngine-Client-Package*`
  * `*Server-Shell*`
  * `*Windows-Defender*`
  * `*Server-Drivers-General*`
  * `*ServerCore-Drivers-General*`
  * `*ServerCore-Drivers-General-WOW64*`
  * `*Server-Gui-Mgmt*`
  * `*WirelessNetworking*`
* Intended mutation type:
  * Disable every online optional feature that does not match the exclusion
    list, with `-NoRestart`.
* Required foundation:
  * A future optional-feature inventory and rollback policy is still needed.
  * Phase 40 reboot/recovery workflow for features that require reboot even
    when `-NoRestart` is used.
* Required production allowlist:
  * Exact feature names.
  * Exact disable permission per feature.
  * Exact verification and restart handling.
* Required inventory/capture before mutation:
  * Current feature state, restart required state, parent/dependency
    information, and source availability for re-enable.
* Required verification:
  * Verify exact approved features were disabled.
  * Verify excluded/unapproved features remain unchanged.
* Rollback/restore feasibility:
  * Not currently feasible through an approved BoostLab foundation. Re-enabling
    features may require source media, Windows Update, or reboot.
* Risk level: high
* Later implementation decision:
  * Must remain refused until exact feature scopes and restore/reboot handling
    are approved.

### 6. Services If Present

* Exact source service targets:
  * `brlapi`
  * `uhssvc`
* Exact source commands:
  * `sc stop "brlapi"`
  * `sc delete "brlapi"`
  * `reg delete "HKLM\SYSTEM\ControlSet001\Services\uhssvc" /f`
* Intended mutation type:
  * Stop and delete `brlapi`.
  * Delete `uhssvc` service registry key directly.
* Required foundation:
  * Phase 37 service state capture and rollback
  * Phase 36 registry state capture for service registry key deletion
  * Phase 38 cleanup policy for adjacent file deletion
* Required production allowlist:
  * Exact service scopes for `brlapi` and `uhssvc`.
  * Explicit approval for service deletion or direct service-registry deletion.
* Required inventory/capture before mutation:
  * Complete service state, binary path, account, dependencies, startup type,
    running state, description, and failure actions.
  * Registry key capture for `HKLM\SYSTEM\ControlSet001\Services\uhssvc` if any
    direct key deletion is approved.
* Required verification:
  * Verify only approved service names were stopped/deleted.
  * Verify service identity matches captured state before mutation.
* Rollback/restore feasibility:
  * Phase 37 does not enable service creation, deletion, or recreation
    rollback. Deletion remains refused without a stronger service recreation
    design.
* Risk level: high
* Later implementation decision:
  * Must remain refused until service deletion/recreation governance exists.

### 7. Scheduled Tasks If Present

* Exact source task targets:
  * Any scheduled task whose `TaskName` matches `OneDrive`
  * `PLUGScheduler`
* Exact source commands:
  * `Get-ScheduledTask | Where-Object {$_.Taskname -match 'OneDrive'} | Unregister-ScheduledTask -Confirm:$false`
  * `Unregister-ScheduledTask -TaskName PLUGScheduler -Confirm:$false`
* Intended mutation type:
  * Unregister matching scheduled tasks.
* Required foundation:
  * A future scheduled-task inventory and rollback policy is still needed.
* Required production allowlist:
  * Exact task path and task name, not regex/broad name match.
  * Exact unregister permission per task.
* Required inventory/capture before mutation:
  * Task XML, principal, triggers, actions, settings, path, name, and current
    enabled/running state.
* Required verification:
  * Verify exact approved tasks were removed.
  * Verify no unrelated task matching a broad pattern was removed.
* Rollback/restore feasibility:
  * Not currently feasible without captured task XML and task recreation
    governance.
* Risk level: high
* Later implementation decision:
  * Must remain refused until scheduled-task governance exists.

### 8. Files/Directories If Present

* Exact source paths:
  * `%SystemRoot%\brltty`
  * `C:\Program Files*\Microsoft OneDrive`
  * `%LOCALAPPDATA%\Microsoft\OneDrive`
  * `%SystemRoot%\Temp\windowsstore.reg`
  * `%SystemRoot%\Temp\remotedesktopconnection.exe`
  * `%SystemRoot%\Temp\snippingtool.exe`
  * `%LOCALAPPDATA%\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\Settings\settings.dat`
* Exact source commands:
  * `takeown /f "$env:SystemRoot\brltty" /r /d y`
  * `icacls "$env:SystemRoot\brltty" /grant *S-1-5-32-544:F /t`
  * `Remove-Item "$env:SystemRoot\brltty" -Recurse -Force`
  * `Get-ChildItem -Path "C:\Program Files*\Microsoft OneDrive", "$env:LOCALAPPDATA\Microsoft\OneDrive" -Filter "OneDriveSetup.exe" -Recurse`
  * `Set-Content -Path "$env:SystemRoot\Temp\windowsstore.reg"`
  * `IWR ... -OutFile "$env:SystemRoot\Temp\remotedesktopconnection.exe"`
  * `IWR ... -OutFile "$env:SystemRoot\Temp\snippingtool.exe"`
* Intended mutation type:
  * Ownership/ACL change and recursive deletion of `brltty`.
  * Recursive discovery and execution of OneDrive uninstallers.
  * Generated temp registry file.
  * Downloaded installer artifacts.
  * Store settings hive access.
* Required foundation:
  * Phase 38 destructive cleanup policy
  * Phase 36 file state capture and rollback
  * Phase 35 download provenance and installer execution policy for downloaded
    installers
* Required production allowlist:
  * Exact file and directory scopes.
  * Exact generated temp-file ownership rules.
  * Exact download artifact provenance records for remote desktop and snipping
    tool installers.
  * No wildcard `C:\Program Files*` scope without a tool-specific bounded
    discovery design.
* Required inventory/capture before mutation:
  * Directory manifest before `brltty` deletion.
  * File hashes for generated temp artifacts.
  * Exact OneDriveSetup.exe paths discovered before execution.
  * Store `settings.dat` existence and backup before hive load/import.
* Required verification:
  * Verify only exact approved files/directories were deleted, generated, or
    executed.
  * Verify downloaded files match approved hashes and signer policy before any
    launch.
* Rollback/restore feasibility:
  * File/directory restore is feasible only from captured/quarantined state.
  * Installer downloads and launches require separate provenance and installer
    execution approval.
* Risk level: high
* Later implementation decision:
  * Must remain refused until exact file, cleanup, download, and installer
    scopes are approved.

### 9. Registry Paths If Present

* Exact source registry paths and values:
  * `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device\DevicePasswordLessBuildVersion=0`
  * `HKLM\SYSTEM\ControlSet001\Services\uhssvc` deletion
  * `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate\AutoDownload=2`
  * Loaded hive target `HKLM\Settings` from Store `settings.dat`
  * `HKLM\Settings\LocalState\VideoAutoplay`
  * `HKLM\Settings\LocalState\EnableAppInstallNotifications`
  * `HKLM\Settings\LocalState\PersistentSettings\PersonalizationEnabled`
* Intended mutation type:
  * Write passwordless sign-in setting before menu.
  * Delete service registry key.
  * Disable Store app updates.
  * Load Store settings hive and import generated registry values.
* Required foundation:
  * Phase 36 registry state capture and rollback
  * Phase 37 service rollback for service registry identity
  * A hive-load/import governance rule for app `settings.dat` is still needed.
* Required production allowlist:
  * Exact registry value scopes.
  * Explicit key deletion scope for `uhssvc`, if ever approved.
  * Exact temporary hive name and hive source file scope.
* Required inventory/capture before mutation:
  * Previous value existence, type, and data.
  * Service key capture before key deletion.
  * Store `settings.dat` backup and hash before hive load/import.
* Required verification:
  * Verify exact values equal expected data after mutation.
  * Verify temporary hive unloaded successfully.
  * Verify no unrelated hive paths were changed.
* Rollback/restore feasibility:
  * Value-level restore is feasible with Phase 36 records.
  * Service key restore and app hive restore require stronger design and
    exact captured-state flow.
* Risk level: high
* Later implementation decision:
  * Must remain refused until exact registry and hive-load scopes are approved.

### 10. MSI/Uninstaller Calls If Present

* Exact source uninstall/install targets:
  * `msiexec.exe /x $guid /qn /norestart` for display name `*Microsoft GameInput*`
  * `C:\Windows\System32\OneDriveSetup.exe -uninstall`
  * `OneDriveSetup.exe /uninstall /allusers` discovered under
    `C:\Program Files*\Microsoft OneDrive` and `%LOCALAPPDATA%\Microsoft\OneDrive`
  * `C:\Windows\SysWOW64\OneDriveSetup.exe -uninstall`
  * `Start-Process "mstsc" -ArgumentList "/Uninstall"`
  * `Start-Process "C:\Windows\System32\SnippingTool.exe" -ArgumentList "/Uninstall"`
  * `msiexec.exe /x $guid /qn /norestart` for display name `*Update for x64-based Windows Systems*`
  * `msiexec.exe /x $guid /qn /norestart` for display name `*Microsoft Update Health Tools*`
  * `C:\Windows\SysWOW64\OneDriveSetup.exe`
  * `C:\Windows\System32\OneDriveSetup.exe`
  * `%SystemRoot%\Temp\remotedesktopconnection.exe`
  * `%SystemRoot%\Temp\snippingtool.exe`
* Intended mutation type:
  * Launch silent uninstallers/installers and terminate related UI processes.
* Required foundation:
  * Phase 35 download provenance and installer execution policy
  * A local Windows component installer/uninstaller allowlist is still needed.
  * Phase 40 if any installer reports reboot required.
* Required production allowlist:
  * Exact executable path, command line, switches, display-name match rules,
    expected signer/publisher, timeout, and exit-code handling.
  * Exact downloaded artifact approvals for remote desktop and snipping tool.
* Required inventory/capture before mutation:
  * Installed product identity, GUID, display name, publisher, version,
    uninstall command, and expected executable signer before invoking.
* Required verification:
  * Capture exit code.
  * Verify expected product/app state after installer/uninstaller.
  * Report reboot-required exit codes without rebooting.
* Rollback/restore feasibility:
  * Not generally feasible without original installer source and exact restore
    plan. Must not claim Restore by default.
* Risk level: high
* Later implementation decision:
  * Must remain refused until installer/uninstaller allowlists and artifact
    provenance are approved.

### 11. AppX Re-Registration or Restore Behavior If Present

* Exact source commands:
  * Store restore:
    `Get-AppXPackage -AllUsers | Where-Object { $_.Name -like '*Store*' } | Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"`
  * All UWP restore:
    `Get-AppxPackage -AllUsers | Foreach { Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" }`
  * Snipping Tool Windows 11 restore:
    `Get-AppXPackage -AllUsers *Microsoft.ScreenSketch* | Foreach { Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" }`
* Intended mutation type:
  * Broad AppX re-registration from install locations.
* Required foundation:
  * Phase 39 AppX package inventory and restore
* Required production allowlist:
  * Exact package family names.
  * Exact `ReRegister` or `RepairRegistration` mutation permission.
  * No broad `Get-AppxPackage -AllUsers | Foreach` restore path.
* Required inventory/capture before mutation:
  * Captured package install location and manifest path before any removal or
    repair.
  * Manifest existence check before re-registration.
* Required verification:
  * Verify exact approved package registration state after repair.
  * Verify no unrelated package was re-registered.
* Rollback/restore feasibility:
  * Store and ScreenSketch repair may be feasible only with exact package scope
    and captured manifest path. Broad all-UWP restore must remain refused.
* Risk level: high
* Later implementation decision:
  * Must remain refused except for exact package repair scopes approved one by
    one.

### 12. Default/Restore Behavior If Present

* Exact source behavior:
  * The source has install/repair menu options, but no single Default option and
    no record-based Restore behavior.
  * Catalog metadata currently exposes `Restore`, but the Ultimate source does
    not provide a safe single Restore equivalent.
* Intended mutation type:
  * Mixed reinstall/re-register/open settings behaviors.
* Required foundation:
  * Phase 39 inventory restore for package repair.
  * Phase 36/38 for file cleanup restore.
  * Phase 37 for service rollback.
  * Phase 35 for any downloaded repair/install artifact.
* Required production allowlist:
  * Exact restore/repair scope per package, service, file, registry value, task,
    installer, or feature.
* Required inventory/capture before mutation:
  * Restore requires a valid pre-mutation inventory or state record.
* Required verification:
  * Verify each restored target against the captured original state.
* Rollback/restore feasibility:
  * Not available as a single tool-level Restore. Only target-specific restore
    can be considered after exact records exist.
* Risk level: high
* Later implementation decision:
  * Restore must remain unavailable until exact inventory restore,
    captured-state restore, or quarantine restore selection is implemented.

### 13. Unsupported Package/Framework/System-Critical Targets

* Exact source protected/excluded package patterns:
  * `*CBS*`
  * media extensions such as AV1, AVC, HEIF, HEVC, MPEG2, Raw, VP9, WebMedia,
    and Webp
  * `*Microsoft.Paint*`
  * `*Microsoft.SecHealthUI*`
  * `*Microsoft.Windows.Photos*`
  * `*Microsoft.Windows.ShellExperienceHost*`
  * `*Microsoft.Windows.StartMenuExperienceHost*`
  * `*Microsoft.WindowsNotepad*`
  * `*NVIDIACorp.NVIDIAControlPanel*`
  * `*windows.immersivecontrolpanel*`
* Exact source protected capability/feature patterns:
  * Networking, Notepad, Paint, NetFX, VBSCRIPT, WMIC, ShellComponents,
    DirectPlay, LegacyComponents, SearchEngine, Server shell/driver/GUI
    components, Defender, and WirelessNetworking patterns listed in the source.
* Intended mutation type:
  * These are excluded by Ultimate and must not become targets accidentally.
* Required foundation:
  * Phase 39 protected package policy and future capability/feature protection.
* Required production allowlist:
  * No protected package, framework, dependency, or system-critical target may
    be approved without separate explicit Yazan approval and recovery design.
* Required inventory/capture before mutation:
  * Protected classification before any package/capability/feature mutation.
* Required verification:
  * Verify protected/excluded targets remain unchanged.
* Rollback/restore feasibility:
  * Protected/system-critical mutation should remain refused unless a dedicated
    restore plan exists.
* Risk level: high
* Later implementation decision:
  * Must remain refused by default.

## Product Scope Notes

The source includes explicit Windows 10 comments and behavior:

* Windows 10 capability exclusions for MSPaint, Notepad, and ShellComponents.
* Windows 10 OneDrive uninstall path under `C:\Windows\SysWOW64`.
* Windows 10 update and Update Health Tools uninstall branches.
* Windows 10 Snipping Tool installer branch.
* Windows 10 optional feature guidance.

Under Phase 48 branch-level product scope, explicit Windows 10-only
optimization/removal/install branches must remain unsupported, disabled,
visual-only, or `NotApplicable` unless Yazan expands scope.

Shared Windows behavior may be designed later only when exact scopes and
restore strategy exist. NVIDIA Control Panel appears only in an exclusion
pattern and must not be removed.

## Future Safe Apply Requirements

A future safe Apply would require all of the following:

1. A tool-specific Action Plan that decomposes the selected branch into exact
   package, capability, feature, service, task, file, registry, installer, and
   cleanup operations.
2. Exact production package scopes in `config/AppxPackagePolicy.psd1`.
3. Exact cleanup scopes in `config/CleanupPolicy.psd1`.
4. Exact file/registry scopes in the Phase 36 rollback policy.
5. Exact service scopes in the Phase 37 service policy.
6. Exact download provenance and installer execution approvals for downloaded
   or launched EXE/MSI artifacts.
7. A future scheduled-task state capture and rollback policy for task removal.
8. A future Windows capability and optional feature inventory/restore policy.
9. Explicit confirmation after a dry-run plan and inventory are visible.
10. Verification after every target group.
11. Clear refusal of Windows 10-only branches unless product scope changes.
12. No broad wildcard package, feature, capability, task, or file selection.

## Default and Restore Boundary

The Ultimate source does not provide a single safe Default or Restore behavior.
It provides separate install/repair menu options that are themselves broad and
high-risk.

BoostLab must not expose Bloatware Restore until exact inventory restore,
captured-state restore, or quarantine restore selection is implemented.

Restore must be target-specific:

* AppX restore requires a valid Phase 39 inventory record and exact package
  scope.
* File restore requires Phase 36 capture or Phase 38 quarantine records.
* Service restore requires Phase 37 records and cannot recreate deleted
  services under the current foundation.
* Installer-based repair requires Phase 35 provenance and installer execution
  approval.
* Capability/feature restore requires a future dedicated foundation.

## Production Approval State

No production AppX/package/cleanup/file/registry/service/task/capability/
feature/installer scopes are approved by this document.

Specifically, this document does not approve:

* AppX package removal
* All-users package removal
* Provisioned package removal
* Broad package re-registration
* Windows capability removal
* Optional feature disabling
* Service stop/delete
* Scheduled task unregister
* File or directory deletion
* Ownership or ACL changes
* Registry writes or key deletion
* Store settings hive load/import
* MSI or EXE uninstallers/installers
* Downloads
* Windows 10-only branches
* Default behavior
* Restore behavior

Bloatware remains refused and disabled as a placeholder until a future phase
explicitly approves exact bounded scopes and implements a narrower reviewed
workflow.
