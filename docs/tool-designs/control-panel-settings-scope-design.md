# Control Panel Settings Scope Design

## Purpose

This Phase 64 document defines the future implementation scope for the
`Control Panel Settings` tool. It is design-only.

No Control Panel Settings behavior is implemented by this document. No runtime
behavior, module behavior, production Control Panel scope, privacy scope,
security scope, application scope, registry scope, file scope, cleanup scope,
service scope, process scope, scheduled task scope, TrustedInstaller scope,
Default behavior, or Restore behavior is approved here.

Control Panel Settings remains a refused placeholder until a later approved
phase splits the source into exact bounded scopes and implementation.

## Source Reference

* Source path: `source-ultimate/6 Windows/15 Control Panel Settings.ps1`
* Source SHA-256: `F81FB649A4645A5145B43A051DDF8306145E64F1FCA5249F90B66BFDFA97BE83`
* Current BoostLab module path: `modules/Windows/control-panel-settings.psm1`
* Current status: refused placeholder
* Current implemented actions: none

Relevant foundations:

* Phase 35: download provenance and installer execution policy
* Phase 36: file and registry state capture and rollback
* Phase 37: service state capture and rollback
* Phase 38: destructive cleanup policy
* Phase 40: reboot/recovery workflow
* Phase 42: TrustedInstaller privileged-operation policy

## Product Scope Decision

Phase 48 defines BoostLab product scope as branch-level scope. Shared Windows
behavior may be preserved if it otherwise passes governance. Explicit Windows
10-only branches or options must remain unsupported, disabled, visual-only, or
`NotApplicable`.

No Windows 10-only branch was found in
`source-ultimate/6 Windows/15 Control Panel Settings.ps1`. The source behavior
is shared Windows behavior, but it remains blocked because it is a broad
privacy, security, Control Panel, Settings, service, task, process, registry,
file, and TrustedInstaller workflow.

## Source Behavior Summary

The Ultimate source exposes two console menu actions:

1. `Control Panel Settings: Optimize (Recommended)`
2. `Control Panel Settings: Default`

The source requires Administrator and defines a `Run-Trusted` helper that
temporarily changes the `TrustedInstaller` service `binPath`, starts the
service, restores the original path, and force-stops it again.

The source writes and imports two large registry files:

* `$env:SystemRoot\Temp\registryoptimize.reg`
* `$env:SystemRoot\Temp\registrydefaults.reg`

It also generates/imports:

* `$env:SystemRoot\Temp\disablesetprioritynotifications.reg`
* `$env:SystemRoot\Temp\appactions.reg`

The source touches at least 234 distinct registry keys and 356 distinct
registry value names across HKCU, HKLM, HKCR, and HKEY_USERS. It also stops
services, disables/enables a scheduled task, uses `powercfg`, stops a broad app
process set, loads an application `settings.dat` hive, imports registry state
into that hive, unloads it, and deletes the same `settings.dat` on Default.

Privacy and security mutation is high risk. Any future implementation must show
user-facing warnings about privacy impact, security posture changes, app
permission side effects, Windows Settings and Control Panel side effects, and
restore limitations. It must require explicit high-risk confirmation and
before/after verification.

Do not implement a registry-only or policy-only subset: applying only the
convenient registry portion would weaken and misrepresent the approved Ultimate
behavior because the source also changes services, scheduled tasks, power
settings, app-action state, privacy database files, processes, and protected
settings files.
Broad registry import remains refused; broad registry import remains refused.
Service changes require exact future allowlist; service changes require exact future allowlist.
No scheduled task mutation is approved in this phase; no scheduled task mutation is approved in this phase.
No TrustedInstaller operation is approved in this phase; no TrustedInstaller operation is approved in this phase.

## Current Decision

Do not implement Analyze, Open, Apply, Default, or Restore yet.

The current catalog suggests an `Open`-style assistant, but the approved source
is not open-only. Direct implementation is refused until this source is split
into smaller approved target groups with exact allowlists, state capture,
confirmation, verification, and rollback decisions.

## Behavior Groups

### 1. Control Panel Registry Settings

* Exact source targets:
  * `HKEY_CURRENT_USER\Software\Microsoft\Narrator\NoRoam`
  * `HKEY_CURRENT_USER\Software\Microsoft\Narrator`
  * `HKEY_CURRENT_USER\Software\Microsoft\Ease of Access`
  * `HKEY_CURRENT_USER\Control Panel\Accessibility`
  * `HKEY_CURRENT_USER\Control Panel\Accessibility\HighContrast`
  * `HKEY_CURRENT_USER\Control Panel\Accessibility\Keyboard Response`
  * `HKEY_CURRENT_USER\Control Panel\Accessibility\MouseKeys`
  * `HKEY_CURRENT_USER\Control Panel\Accessibility\StickyKeys`
  * `HKEY_CURRENT_USER\Control Panel\Accessibility\ToggleKeys`
  * `HKEY_CURRENT_USER\Control Panel\Accessibility\SoundSentry`
  * `HKEY_CURRENT_USER\Control Panel\Accessibility\SlateLaunch`
  * `HKEY_CURRENT_USER\Control Panel\TimeDate`
  * `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced`
  * `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer`
  * `HKEY_CURRENT_USER\AppEvents\Schemes`
  * `HKEY_CURRENT_USER\AppEvents\Schemes\Apps\.Default\WindowsUAC\.Current`
* Source menu options:
  * `Control Panel Settings: Optimize (Recommended)`
  * `Control Panel Settings: Default`
* Intended mutation type:
  * Large HKCU registry value writes and value deletes for accessibility,
    Explorer, sound, mouse, keyboard, autoplay, and legacy Control Panel
    preferences.
* Required foundation:
  * Phase 36 file and registry state capture and rollback.
* Required future production allowlist:
  * Exact key/value scopes for each individual setting.
* Required inventory/capture before mutation:
  * Previous existence, type, and data for every value.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation because the tool is broad and
    user-visible.
* Required verification:
  * Verify every intended value is written, deleted, or restored exactly.
  * Report unavailable keys as warnings only when source behavior is optional.
* Rollback/restore feasibility:
  * Feasible only value-by-value from Phase 36 captured state. Source Default is
    not record-based Restore.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after this group is split into exact smaller setting scopes.
* Whether it must remain refused:
  * The current broad `.reg` import remains refused.

### 2. Privacy Settings

* Exact source targets:
  * `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Privacy`
  * `HKEY_CURRENT_USER\Software\Microsoft\InputPersonalization`
  * `HKEY_CURRENT_USER\Software\Microsoft\InputPersonalization\TrainedDataStore`
  * `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\SearchSettings`
  * `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\CPSS\Store\UserLocationOverridePrivacySetting`
  * `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\PushNotifications`
  * `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings`
  * `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location`
* Source menu options:
  * `Control Panel Settings: Optimize (Recommended)`
  * `Control Panel Settings: Default`
* Intended mutation type:
  * Privacy policy and user preference registry writes/deletes.
* Required foundation:
  * Phase 36 registry state capture and rollback.
* Required future production allowlist:
  * Exact privacy keys and values. Broad privacy category imports are not
    enough.
* Required inventory/capture before mutation:
  * Previous value state for every privacy value and key manifests before any
    key deletion.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation with privacy-impact warning.
* Required verification:
  * Verify before/after privacy state and clearly report app permission side
    effects.
* Rollback/restore feasibility:
  * Only from exact captured registry state.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after exact privacy scopes and user-facing warnings are approved.
* Whether it must remain refused:
  * Broad privacy imports/deletions remain refused.

### 3. Security Settings

* Exact source targets:
  * `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device`
  * `HKEY_CURRENT_USER\AppEvents\Schemes\Apps\.Default\WindowsUAC\.Current`
  * `HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot`
  * `HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\WindowsCopilot`
  * `HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy`
  * `HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System`
* Source menu options:
  * `Control Panel Settings: Optimize (Recommended)`
  * `Control Panel Settings: Default`
* Intended mutation type:
  * Security and policy registry value writes/deletes affecting sign-in,
    Copilot, AppPrivacy, UAC sounds, and system behavior.
* Required foundation:
  * Phase 36 registry state capture and rollback.
* Required future production allowlist:
  * Exact security-sensitive registry values and key scopes.
* Required inventory/capture before mutation:
  * Existing value state and key manifests before deletion.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation with security posture warning.
* Required verification:
  * Verify each security/policy value before and after mutation.
  * Surface tradeoffs and restore limitations in Latest Result.
* Rollback/restore feasibility:
  * Possible only from exact captured state.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only as small security-specific subtools or explicitly scoped groups.
* Whether it must remain refused:
  * Broad security policy import remains refused.

### 4. Application Settings

* Exact source targets:
  * `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\GameDVR`
  * `HKEY_CURRENT_USER\System\GameConfigStore`
  * `HKEY_CURRENT_USER\Software\Microsoft\GameBar`
  * `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate`
  * `HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsStore`
  * `HKEY_LOCAL_MACHINE\Settings\LocalState\DisabledApps`
  * App identities `Microsoft.Paint_8wekyb3d8bbwe`,
    `Microsoft.Windows.Photos_8wekyb3d8bbwe`, and
    `MicrosoftWindows.Client.CBS_cw5n1h2txyewy`
* Source menu options:
  * `Control Panel Settings: Optimize (Recommended)`
  * `Control Panel Settings: Default`
* Intended mutation type:
  * App, Game Bar, Store, Start, Settings, and app-action registry writes,
    deletes, and hive import.
* Required foundation:
  * Phase 36 registry/file state capture and rollback.
  * Phase 39 AppX inventory if future app identity mutation is coupled to
    package state.
* Required future production allowlist:
  * Exact application setting values and exact app identities.
* Required inventory/capture before mutation:
  * Registry value state, loaded-hive target state, and app settings file state.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify affected app settings and report Settings app side effects.
* Rollback/restore feasibility:
  * Only from exact registry and file/hive capture.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after the app settings are decomposed into exact scopes.
* Whether it must remain refused:
  * Broad app-action hive import remains refused.

### 5. Capability Access Manager Behavior

* Exact source targets:
  * `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location`
  * `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location`
  * `HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam`
  * `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone`
  * `HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener`
  * `HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userAccountInformation`
  * `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\contacts`
  * `HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appointments`
  * `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\phoneCall`
  * `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\phoneCallHistory`
  * `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\email`
  * `HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userDataTasks`
  * `HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\chat`
  * `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\radios`
  * `HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetoothSync`
  * `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appDiagnostics`
  * `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\documentsLibrary`
  * `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\downloadsFolder`
  * `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\musicLibrary`
  * `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\picturesLibrary`
  * `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\videosLibrary`
  * `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\broadFileSystemAccess`
  * `HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels`
  * `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\passkeys`
  * `HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\passkeysEnumeration`
* Source menu options:
  * `Control Panel Settings: Optimize (Recommended)`
  * `Control Panel Settings: Default`
* Intended mutation type:
  * Capability permission registry writes and selected key deletions.
* Required foundation:
  * Phase 36 registry state capture and rollback.
* Required future production allowlist:
  * Exact capability names and exact value mutations.
* Required inventory/capture before mutation:
  * Previous permission value state and key manifests before key deletion.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation with app-permission warning.
* Required verification:
  * Verify all permission states and report unavailable capabilities as
    warnings.
* Rollback/restore feasibility:
  * Only from exact captured registry state.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after capability scopes are approved one by one.
* Whether it must remain refused:
  * Broad Capability Access Manager mutation remains refused.

### 6. Capability Access Manager Database/File Behavior If Present

* Exact source targets:
  * Service `camsvc`
  * `$env:ProgramData\Microsoft\Windows\CapabilityAccessManager\CapabilityConsentStorage.db*`
  * Command string:
    `Remove-item "$env:ProgramData\Microsoft\Windows\CapabilityAccessManager\CapabilityConsentStorage.db*" -Force`
* Exact source commands:
  * `Stop-Service -Name 'camsvc' -Force -ErrorAction SilentlyContinue`
  * `Run-Trusted -command $capabilityconsentstoragedb`
* Source menu options:
  * `Control Panel Settings: Optimize (Recommended)`
  * `Control Panel Settings: Default`
* Intended mutation type:
  * Service stop and wildcard protected database file deletion under
    TrustedInstaller.
* Required foundation:
  * Phase 37 service state capture and rollback.
  * Phase 38 destructive cleanup policy.
  * Phase 42 TrustedInstaller privileged-operation policy.
  * Phase 36 file state capture if restore/quarantine is claimed.
* Required future production allowlist:
  * Exact service scope for `camsvc`.
  * Exact file patterns decomposed into bounded file names.
  * Exact TrustedInstaller command descriptor.
* Required inventory/capture before mutation:
  * Service state, file inventory, hashes, size limits, ownership, and
    quarantine/restore decision.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify only approved database files are removed or quarantined.
  * Verify `camsvc` state and app-permission effects after mutation.
* Rollback/restore feasibility:
  * Not feasible without exact backup/quarantine records and service state
    handling.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after exact file, service, cleanup, and TrustedInstaller scopes are
    approved.
* Whether it must remain refused:
  * Wildcard protected database deletion remains refused.

### 7. Service Configuration Behavior

* Exact source targets:
  * `HKLM\SYSTEM\ControlSet001\Services\CDPUserSvc`
  * Value `Start=REG_DWORD 4` in Optimize
  * Value `Start=REG_DWORD 2` in Default
* Exact source commands:
  * `cmd /c "reg add `"HKLM\SYSTEM\ControlSet001\Services\CDPUserSvc`" /v `"Start`" /t REG_DWORD /d `"4`" /f >nul 2>&1"`
  * `cmd /c "reg add `"HKLM\SYSTEM\ControlSet001\Services\CDPUserSvc`" /v `"Start`" /t REG_DWORD /d `"2`" /f >nul 2>&1"`
* Source menu options:
  * `Control Panel Settings: Optimize (Recommended)`
  * `Control Panel Settings: Default`
* Intended mutation type:
  * Service startup registry value write.
* Required foundation:
  * Phase 37 service state capture and rollback.
  * Phase 36 registry state capture and rollback.
* Required future production allowlist:
  * Exact service and `Start` value scope.
* Required inventory/capture before mutation:
  * Service state and previous registry value existence/type/data.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify the `Start` value equals the source-defined expected state.
* Rollback/restore feasibility:
  * Possible only from exact service/registry capture.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after exact service scope is approved.
* Whether it must remain refused:
  * Current service mutation remains refused.

### 8. Service Stop/Start/Delete Behavior If Present

* Exact source targets:
  * `TrustedInstaller`
  * `camsvc`
* Exact source commands:
  * `Stop-Service -Name TrustedInstaller -Force`
  * `taskkill /im trustedinstaller.exe /f`
  * `sc.exe config TrustedInstaller binPath=`
  * `sc.exe start TrustedInstaller`
  * `Stop-Service -Name 'camsvc' -Force -ErrorAction SilentlyContinue`
* Source menu options:
  * `Control Panel Settings: Optimize (Recommended)`
  * `Control Panel Settings: Default`
* Intended mutation type:
  * TrustedInstaller helper flow and Camera Frame Server Monitor service stop.
* Required foundation:
  * Phase 37 service state capture and rollback.
  * Phase 42 TrustedInstaller privileged-operation policy.
* Required future production allowlist:
  * Exact service scopes and exact TrustedInstaller request scope.
* Required inventory/capture before mutation:
  * Service state, service binary path, running status, and recovery metadata.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify TrustedInstaller service path is restored.
  * Verify no service outside approved scope is stopped.
* Rollback/restore feasibility:
  * Runtime service state is not a complete Restore. Captured service
    configuration may be restorable only within Phase 37 limits.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after exact service and TrustedInstaller scopes are approved.
* Whether it must remain refused:
  * TrustedInstaller service manipulation remains refused.

### 9. Process Stop Behavior If Present

* Exact source targets:
  * `AppActions`
  * `CrossDeviceResume`
  * `DesktopStickerEditorWin32Exe`
  * `DiscoveryHubApp`
  * `FESearchHost`
  * `SearchHost`
  * `SoftLandingTask`
  * `TextInputHost`
  * `VisualAssistExe`
  * `WebExperienceHostApp`
  * `WindowsBackupClient`
  * `WindowsMigration`
* Exact source command:
  * `$stop | ForEach-Object { Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue }`
* Source menu options:
  * `Control Panel Settings: Optimize (Recommended)`
  * `Control Panel Settings: Default`
* Intended mutation type:
  * Broad forced process stop before app-action hive mutation and Default
    settings.dat deletion.
* Required foundation:
  * A future process-handling policy is still needed.
* Required future production allowlist:
  * Exact process names, executable identity rules, owner/session rules, and
    stop justification.
* Required inventory/capture before mutation:
  * Process id, executable path, command line if safely available, owner/session,
    and reason for stopping.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify only approved processes were targeted.
  * Report already-stopped processes as non-errors.
* Rollback/restore feasibility:
  * Process state is not restorable.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after process-handling governance exists.
* Whether it must remain refused:
  * Broad process stop remains refused.

### 10. Scheduled Task Behavior If Present

* Exact source targets:
  * Scheduled tasks where `TaskName -match 'ScheduledDefrag'`
* Exact source commands:
  * `Get-ScheduledTask | Where-Object {$_.TaskName -match 'ScheduledDefrag'} | Disable-ScheduledTask | Out-Null`
  * `Get-ScheduledTask | Where-Object {$_.TaskName -match 'ScheduledDefrag'} | Enable-ScheduledTask | Out-Null`
* Source menu options:
  * `Control Panel Settings: Optimize (Recommended)`
  * `Control Panel Settings: Default`
* Intended mutation type:
  * Dynamic scheduled task disable/enable.
* Required foundation:
  * A future scheduled task inventory and rollback policy is still needed.
* Required future production allowlist:
  * Exact task path and exact task name, not pattern matching.
* Required inventory/capture before mutation:
  * Task XML, path, name, enabled state, triggers, actions, principal, and
    settings.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify only approved scheduled tasks were enabled or disabled.
* Rollback/restore feasibility:
  * Not feasible without captured task state and task restore governance.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after scheduled task governance exists.
* Whether it must remain refused:
  * No scheduled task mutation is approved in this phase.

### 11. TrustedInstaller-Required Operations

* Exact source targets:
  * `TrustedInstaller`
  * `$env:ProgramData\Microsoft\Windows\CapabilityAccessManager\CapabilityConsentStorage.db*`
* Exact source commands:
  * `Run-Trusted -command $capabilityconsentstoragedb`
  * `sc.exe config TrustedInstaller binPath= "cmd.exe /c powershell.exe -encodedcommand $base64Command"`
  * `sc.exe start TrustedInstaller`
* Source menu options:
  * `Control Panel Settings: Optimize (Recommended)`
  * `Control Panel Settings: Default`
* Intended mutation type:
  * Privileged deletion of Capability Access Manager database files.
* Required foundation:
  * Phase 42 TrustedInstaller privileged-operation policy.
  * Phase 38 cleanup policy.
* Required future production allowlist:
  * Exact TrustedInstaller command descriptor and exact file targets.
* Required inventory/capture before mutation:
  * TrustedInstaller plan, file inventory, and cleanup/quarantine records.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation with privileged-operation
    warning.
* Required verification:
  * Verify no generic shell string, broad wildcard, or unapproved protected
    target is accepted.
* Rollback/restore feasibility:
  * Not feasible without exact quarantine/backup and current-state checks.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after exact TrustedInstaller and cleanup scopes are approved.
* Whether it must remain refused:
  * All TrustedInstaller operations remain refused in this phase.

### 12. Registry Import Behavior

* Exact source targets:
  * `$env:SystemRoot\Temp\registryoptimize.reg`
  * `$env:SystemRoot\Temp\registrydefaults.reg`
  * `$env:SystemRoot\Temp\disablesetprioritynotifications.reg`
  * `$env:SystemRoot\Temp\appactions.reg`
* Exact source commands:
  * `Set-Content -Path "$env:SystemRoot\Temp\registryoptimize.reg" -Value $RegistryOptimize -Force`
  * `Regedit.exe /S "$env:SystemRoot\Temp\registryoptimize.reg"`
  * `Set-Content -Path "$env:SystemRoot\Temp\registrydefaults.reg" -Value $RegistryDefaults -Force`
  * `Regedit.exe /S "$env:SystemRoot\Temp\registrydefaults.reg"`
  * `Start-Process -Wait "regedit.exe" -ArgumentList "/S `"$disableprioritynotificationsregfile`"" -WindowStyle Hidden`
  * `reg import $regfileappactions`
* Source menu options:
  * `Control Panel Settings: Optimize (Recommended)`
  * `Control Panel Settings: Default`
* Intended mutation type:
  * Generated `.reg` file creation and broad registry import.
* Required foundation:
  * Phase 36 file and registry state capture and rollback.
  * Phase 38 cleanup policy for generated files if cleanup is later added.
* Required future production allowlist:
  * Exact generated file paths and hashes.
  * Every key/value in every imported file must be enumerated and allowlisted.
* Required inventory/capture before mutation:
  * Previous file state before overwrite and previous registry state for every
    imported target.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify generated file contents match approved source text.
  * Verify each imported key/value individually.
* Rollback/restore feasibility:
  * Only from exact Phase 36 captured file and registry state.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after the giant imports are decomposed into exact scopes.
* Whether it must remain refused:
  * Broad registry import remains refused.

### 13. Registry Deletion Behavior

* Exact source targets:
  * Deleted registry values and keys inside `registrydefaults.reg`
  * `HKCU\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current`
  * `HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\WindowsCopilot`
  * `HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot`
  * Capability Access Manager keys such as
    `HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetoothSync`
    and
    `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\downloadsFolder`
* Exact source commands:
  * `cmd /c "reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current /f >nul 2>&1"`
  * Registry-file deletion markers like
    `[-HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot]`
* Source menu options:
  * `Control Panel Settings: Default`
* Intended mutation type:
  * Registry value deletion, whole key deletion, and CloudStore reset.
* Required foundation:
  * Phase 36 registry state capture and rollback.
* Required future production allowlist:
  * Exact key/value scopes and explicit deletion approval for each target.
* Required inventory/capture before mutation:
  * Full key manifest before any whole-key deletion.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify only approved values/keys were removed.
* Rollback/restore feasibility:
  * Only from exact captured key/value state.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after deletions are decomposed and allowlisted.
* Whether it must remain refused:
  * Entire-key deletion remains refused unless every target is enumerated,
    allowlisted, captured, and verified.

### 14. Protected File Deletion or Cleanup Behavior

* Exact source targets:
  * `$env:ProgramData\Microsoft\Windows\CapabilityAccessManager\CapabilityConsentStorage.db*`
  * `$env:LOCALAPPDATA\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\Settings\settings.dat`
* Exact source commands:
  * `Remove-item "$env:ProgramData\Microsoft\Windows\CapabilityAccessManager\CapabilityConsentStorage.db*" -Force`
  * `Remove-Item "$env:LOCALAPPDATA\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\Settings\settings.dat" -Force -ErrorAction SilentlyContinue`
  * `reg load "HKLM\Settings" $settingsdat`
  * `reg unload "HKLM\Settings"`
* Source menu options:
  * `Control Panel Settings: Optimize (Recommended)`
  * `Control Panel Settings: Default`
* Intended mutation type:
  * Protected privacy database deletion, loaded application settings hive
    mutation, and Default deletion of Settings app `settings.dat`.
* Required foundation:
  * Phase 36 file state capture and rollback.
  * Phase 38 destructive cleanup policy.
  * Phase 42 TrustedInstaller policy for protected database deletion.
* Required future production allowlist:
  * Exact file paths, bounded wildcard replacement, and exact hive path.
* Required inventory/capture before mutation:
  * Existing file state, hash, metadata, backup/quarantine record, and loaded
    hive validation.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify no unrelated package settings file or privacy database file was
    removed.
  * Verify hive load/unload completed and no mounted hive remains.
* Rollback/restore feasibility:
  * Only from exact backup/quarantine/captured state.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after exact protected file and hive mutation scopes are approved.
* Whether it must remain refused:
  * Deleting privacy/security database files requires explicit future approval
    and restore/quarantine design.

### 15. Default/Restore Behavior

* Exact source Default behavior:
  * Delete Capability Access Manager database files again.
  * Set `CDPUserSvc` to `Start=2`.
  * Import `$env:SystemRoot\Temp\registrydefaults.reg`.
  * Enable `ScheduledDefrag`.
  * Set `powercfg` console lock AC/DC values to `1`.
  * Delete the CloudStore current account key.
  * Stop the app-action process list.
  * Delete
    `$env:LOCALAPPDATA\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\Settings\settings.dat`.
* Source menu options:
  * `Control Panel Settings: Default`
* Intended mutation type:
  * Source-default reset workflow, not captured-state Restore.
* Required foundation:
  * Phase 36, Phase 37, Phase 38, Phase 40, Phase 42, and future task/process
    governance.
* Required future production allowlist:
  * Exact registry, file, service, task, power, process, and TrustedInstaller
    scopes.
* Required inventory/capture before mutation:
  * Every target group must have a pre-mutation record before Default can be
    considered.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify each Default target separately and report restore limitations.
* Rollback/restore feasibility:
  * Current Default/Restore must remain unavailable. Source Default is not
    record-based Restore and does not reconstruct arbitrary prior user state.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after exact Default target scopes and captured-state boundaries are
    approved.
* Whether it must remain refused:
  * Restore must remain refused until record-based restore selection is
    implemented.

### 16. Unsupported Broad Registry/File/Service/Privacy/Security Targets

* Exact source targets:
  * Broad `.reg` payloads with at least 234 distinct registry keys and 356
    distinct value names.
  * Capability Access Manager database wildcard
    `CapabilityConsentStorage.db*`.
  * CloudStore whole-key deletion under
    `HKCU\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current`.
  * `HKLM\Settings\LocalState\DisabledApps` loaded from app `settings.dat`.
  * Process list with twelve app/process names.
  * Scheduled task pattern `TaskName -match 'ScheduledDefrag'`.
* Source menu options:
  * `Control Panel Settings: Optimize (Recommended)`
  * `Control Panel Settings: Default`
* Intended mutation type:
  * Broad registry/file/service/privacy/security mutation.
* Required foundation:
  * Phase 36, Phase 37, Phase 38, Phase 40, Phase 42, and future task/process
    governance.
* Required future production allowlist:
  * Exact targets only. Broad imports, wildcards, dynamic discovery, and
    whole-key deletion are not approved.
* Required inventory/capture before mutation:
  * Exact registry, file, service, task, process, and privacy/security
    inventories.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
* Required verification:
  * Verify broad selectors are replaced by exact scopes or block execution.
* Rollback/restore feasibility:
  * Not feasible without exact inventories and captured state.
* Risk level:
  * High.
* Whether it can be implemented later:
  * Only after the source is split into smaller approved candidates.
* Whether it must remain refused:
  * The broad all-in-one source behavior must remain refused.

### 17. Unsupported Windows 10-Only Branches/Options If Present

* Exact source targets:
  * None found.
* Source menu options:
  * No explicit Windows 10-only menu branch or source option was found.
* Intended mutation type:
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
  * Shared Windows behavior may be reconsidered only after every non-product
    blocker is solved.
* Whether it must remain refused:
  * Any invented Windows 10-only branch must remain refused.

## Exact Source Target Inventory

Generated registry and file targets:

* `$env:SystemRoot\Temp\registryoptimize.reg`
* `$env:SystemRoot\Temp\registrydefaults.reg`
* `$env:SystemRoot\Temp\disablesetprioritynotifications.reg`
* `$env:SystemRoot\Temp\appactions.reg`
* `$env:ProgramData\Microsoft\Windows\CapabilityAccessManager\CapabilityConsentStorage.db*`
* `$env:LOCALAPPDATA\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\Settings\settings.dat`

Execution commands and privileged operations:

* `Run-Trusted -command $capabilityconsentstoragedb`
* `sc.exe config TrustedInstaller binPath=`
* `sc.exe start TrustedInstaller`
* `Regedit.exe /S "$env:SystemRoot\Temp\registryoptimize.reg"`
* `Regedit.exe /S "$env:SystemRoot\Temp\registrydefaults.reg"`
* `Start-Process -Wait "regedit.exe" -ArgumentList "/S `"$disableprioritynotificationsregfile`"" -WindowStyle Hidden`
* `reg import $regfileappactions`
* `reg load "HKLM\Settings" $settingsdat`
* `reg unload "HKLM\Settings"`
* `powercfg /setdcvalueindex scheme_current sub_none consolelock`
* `powercfg /setacvalueindex scheme_current sub_none consolelock`

Services, tasks, and processes:

* `TrustedInstaller`
* `camsvc`
* `CDPUserSvc`
* `ScheduledDefrag`
* `AppActions`
* `CrossDeviceResume`
* `DesktopStickerEditorWin32Exe`
* `DiscoveryHubApp`
* `FESearchHost`
* `SearchHost`
* `SoftLandingTask`
* `TextInputHost`
* `VisualAssistExe`
* `WebExperienceHostApp`
* `WindowsBackupClient`
* `WindowsMigration`

Representative registry families:

* `HKEY_CURRENT_USER\Control Panel`
* `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer`
* `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Privacy`
* `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore`
* `HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy`
* `HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\WindowsCopilot`
* `HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot`
* `HKEY_CLASSES_ROOT\ms-gamebar`
* `HKEY_LOCAL_MACHINE\Settings\LocalState\DisabledApps`

## Future Safe Apply Requirements

A future safe Apply would require all of the following:

1. Split the source into smaller approved target groups rather than one broad
   all-in-one tool.
2. A tool-specific Action Plan decomposing every registry, file, service, task,
   process, powercfg, TrustedInstaller, and loaded-hive operation.
3. Exact registry scopes for every key/value in each generated `.reg` payload.
4. Exact generated file scopes and content hashes for every `.reg` file.
5. Exact service scopes for `camsvc`, `CDPUserSvc`, and any TrustedInstaller
   helper use.
6. Exact scheduled task scopes after scheduled-task governance exists.
7. Exact process scopes after process-handling governance exists.
8. Exact file, cleanup, quarantine, and restore scopes for Capability Access
   Manager database files and Settings app `settings.dat`.
9. Exact TrustedInstaller command descriptors and privileged-target scopes.
10. Exact `powercfg` command descriptors and verification if power settings are
    preserved.
11. Inventory/capture before every mutation.
12. Verification after every target group.
13. User-facing high-risk privacy/security/app-permission warnings.
14. Explicit refusal of a registry-only or policy-only subset because it would
    weaken Ultimate behavior.

## Default and Restore Boundary

The source Default branch is a source-default reset workflow, not a captured
Restore action.

BoostLab must not expose Control Panel Settings Default until exact registry
rollback, file rollback, service rollback, task rollback, process handling,
privacy database restore/quarantine, TrustedInstaller workflow, power setting
verification, and captured-state restore selection are approved.

BoostLab must not expose Restore until exact registry rollback, file rollback,
service rollback, task rollback, privacy database restore/quarantine,
TrustedInstaller workflow, and captured-state restore selection are
implemented. Restore must be record-based and target-specific.

Current Default/Restore must remain unavailable because the source Default
imports a broad registry file, deletes registry keys, deletes protected app
settings files, changes service/task/power state, and removes privacy database
files without reconstructing arbitrary prior user state.

## Production Approval State

No production Control Panel, privacy, security, application, registry, file,
cleanup, service, process, task, TrustedInstaller, Default, or Restore scope is
approved by this document.

Specifically, this document does not approve:

* Control Panel registry writes
* Privacy registry writes or deletes
* Security registry writes or deletes
* Application settings writes
* Capability Access Manager registry changes
* Capability Access Manager database deletion
* `camsvc` stop
* `CDPUserSvc` startup mutation
* `TrustedInstaller` service manipulation
* Scheduled task enable/disable
* Process force-stop
* `powercfg` changes
* Generated `.reg` creation
* Registry import
* Loaded application hive mutation
* Settings app `settings.dat` deletion
* Broad registry/file/service/privacy/security targets
* Registry-only implementation
* Policy-only implementation
* Default behavior
* Restore behavior

Control Panel Settings remains a refused placeholder until a future phase
explicitly approves exact bounded scopes and implements reviewed smaller
workflows.
