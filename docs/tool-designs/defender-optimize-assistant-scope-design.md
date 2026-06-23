# Defender Optimize Assistant Scope Design

## Purpose

This Phase 54 document defines the future implementation scope for the
`Defender Optimize Assistant` tool. It is design-only.

No Defender Optimize Assistant behavior is implemented by this document. No
runtime behavior, module behavior, production Defender scope, service scope,
registry scope, file scope, cleanup scope, reboot scope, Safe Mode scope, BCD
scope, RunOnce scope, scheduled task scope, TrustedInstaller scope, download
artifact, installer execution, Default behavior, or Restore behavior is
approved here.

Defender Optimize Assistant remains a refused placeholder until a later
approved phase adds exact bounded production scopes, security warnings,
workflow records, rollback rules, verification, and implementation.

## Source Reference

* Source path: `source-ultimate/8 Advanced/7 Defender Optimize Assistant.ps1`
* Source SHA-256: `512F12D805715E9232304ABE5BA400BE6B3965D63F77D3B39E4C304507BFB9B6`
* Current BoostLab module path:
  `modules/Advanced/defender-optimize-assistant.psm1`
* Current status: refused placeholder
* Current implemented actions: none

Relevant foundations:

* Phase 35: download provenance and installer execution policy
* Phase 36: file and registry state capture and rollback
* Phase 37: service state capture and rollback
* Phase 40: reboot and recovery workflow
* Phase 42: TrustedInstaller privileged-operation policy
* Phase 43: Safe Mode recovery and resume workflow

## Source Behavior Summary

The Ultimate source exposes two menu actions:

1. `Defender: Optimize (Recommended)`
2. `Defender: Default`

Both branches generate a PowerShell script under `%SystemRoot%\Temp`, write a
RunOnce entry, perform a few normal-boot registry and scheduled-task changes,
set Safe Mode through `bcdedit`, and restart the machine. The generated Safe
Mode script defines `Run-Trusted`, temporarily rewrites the `TrustedInstaller`
service `binPath` to run encoded PowerShell, applies the Defender/security
registry command list once through TrustedInstaller and once as Administrator,
removes Safe Mode, and restarts again.

The source contains no external download URL and no installer launch.

## Current Decision

Do not implement Analyze, Apply, Default, or Restore yet.

The source combines Defender/security registry changes, scheduled task
changes, generated scripts, TrustedInstaller service hijacking, Safe Mode
entry, RunOnce resume, BCD edits, and repeated reboot behavior. Optimize is
security-reducing for several settings. These behaviors require exact
production scopes and a security-specific recovery design before BoostLab can
preserve the Ultimate behavior safely.

Optimize is security-reducing.

## Behavior Groups

### 1. Defender Service Configuration

* Source targets:
  * No direct `WinDefend`, `WdNisSvc`, `Sense`, or `SecurityHealthService`
    service startup mutation was detected.
  * `TrustedInstaller` service is reconfigured as part of the privileged
    execution helper.
  * `HKLM\System\ControlSet001\Services\SharedAccess\Epoch`
  * `HKLM\System\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile`
  * `HKLM\System\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\PublicProfile`
  * `HKLM\System\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile`
* Intended mutation type:
  * Firewall notification registry values are changed under the `SharedAccess`
    service registry tree.
  * `TrustedInstaller` is stopped, started, and temporarily reconfigured by
    the source helper.
* Required foundation:
  * Phase 37 service state capture and rollback
  * Phase 36 registry state capture and rollback
  * Phase 42 TrustedInstaller policy
* Required future production allowlist:
  * Exact `TrustedInstaller` service scope.
  * Exact `SharedAccess` registry value scopes.
  * No wildcard Defender service scope.
* Required inventory/capture before mutation:
  * `TrustedInstaller` binary path, service state, account, dependencies, and
    running status.
  * Prior `SharedAccess` registry values, types, and data.
* Required confirmation level:
  * High-risk explicit security confirmation.
* Required verification:
  * `TrustedInstaller` binary path restored exactly.
  * `SharedAccess` values match source expectations after the branch.
* Rollback/restore feasibility:
  * Possible only with exact service and registry records captured before this
    specific BoostLab operation.
* Risk level: high
* Later implementation decision:
  * Must remain refused until exact service and registry scopes are approved.

### 2. Defender Process Handling

* Source targets:
  * `trustedinstaller.exe`
* Intended mutation type:
  * `taskkill /im trustedinstaller.exe /f` is used if stopping the service
    fails.
* Required foundation:
  * Phase 42 TrustedInstaller policy
  * Future process-handling governance if force-kill remains source-preserved
* Required future production allowlist:
  * Exact process name `trustedinstaller.exe`.
  * Exact condition where force-kill is allowed.
* Required inventory/capture before mutation:
  * Process id, image path, service association, and command line where
    available.
* Required confirmation level:
  * High-risk explicit confirmation.
* Required verification:
  * Process termination result is logged and the `TrustedInstaller` service
    state is verified afterward.
* Rollback/restore feasibility:
  * Process termination is not directly restorable.
* Risk level: high
* Later implementation decision:
  * Must remain refused until process handling is bounded and verified.

### 3. Defender Registry Policy/Settings

* Source targets:
  * `HKLM\SOFTWARE\Microsoft\Windows Defender`
    * `VerifiedAndReputableTrustModeEnabled`
    * `SmartLockerMode`
    * `PUAProtection`
  * `HKLM\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection`
    * `DisableRealtimeMonitoring`
    * `DisableAsyncScanOnOpen`
  * `HKLM\SOFTWARE\Microsoft\Windows Defender\Spynet`
    * `SpyNetReporting`
    * `SubmitSamplesConsent`
  * `HKLM\SOFTWARE\Microsoft\Windows Defender\Features`
    * `TamperProtection`
  * `HKLM\SOFTWARE\Microsoft\Windows Defender\Windows Defender Exploit Guard\Controlled Folder Access`
    * `EnableControlledFolderAccess`
  * `HKLM\System\ControlSet001\Control\CI\Config`
    * `VulnerableDriverBlocklistEnable`
  * `HKLM\SOFTWARE\Microsoft\Windows Defender Security Center\Notifications`
    * `DisableEnhancedNotifications`
  * `HKLM\SOFTWARE\Microsoft\Windows Defender Security Center\Virus and threat protection`
    * `NoActionNotificationDisabled`
    * `SummaryNotificationDisabled`
    * `FilesBlockedNotificationDisabled`
  * `HKCU\SOFTWARE\Microsoft\Windows Defender Security Center\Account protection`
    * `DisableNotifications`
    * `DisableDynamiclockNotifications`
    * `DisableWindowsHelloNotifications`
* Intended mutation type:
  * Optimize writes security-reducing values including cloud protection off,
    sample submission off, controlled folder access off, notifications off,
    Smart App Control / PUA-related settings reduced, and Tamper Protection
    value changed.
  * Default writes source-defined default values.
* Required foundation:
  * Phase 36 registry state capture and rollback
  * Phase 42 TrustedInstaller policy where source marks settings as needing
    Safe Mode as TrustedInstaller
  * Phase 43 Safe Mode workflow
* Required future production allowlist:
  * Exact registry path, value name, type, Optimize data, and Default data.
  * Separate security-sensitive approval for each value.
* Required inventory/capture before mutation:
  * Prior value existence, type, and data for each target.
  * Current Defender/Tamper Protection availability where detectable.
* Required confirmation level:
  * High-risk security confirmation describing reduced protection.
* Required verification:
  * Read back every approved value.
  * Contradictory security values are Failed, not Warning.
  * Values unavailable because Windows rejects protected changes are reported
    clearly.
* Rollback/restore feasibility:
  * Possible only with exact Phase 36 records.
* Risk level: high
* Later implementation decision:
  * Can be reconsidered only after a security-specific allowlist and warning
    plan exists.

### 4. Tamper Protection or Protected Setting Boundaries

* Source targets:
  * `HKLM\SOFTWARE\Microsoft\Windows Defender\Features\TamperProtection`
  * `HKLM\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection`
  * `HKLM\SOFTWARE\Microsoft\Windows Defender\Spynet`
  * `HKLM\SOFTWARE\Microsoft\Windows Defender\Windows Defender Exploit Guard\Controlled Folder Access`
* Intended mutation type:
  * Protected Defender settings are written in Safe Mode through
    TrustedInstaller and again as Administrator.
* Required foundation:
  * Phase 42 TrustedInstaller policy
  * Phase 43 Safe Mode policy
  * Phase 36 registry rollback
* Required future production allowlist:
  * Exact target-specific protected-setting scope.
  * No broad `Windows Defender` subtree permission.
* Required inventory/capture before mutation:
  * Prior registry values and detected Defender protection state.
* Required confirmation level:
  * Highest practical security warning and explicit confirmation.
* Required verification:
  * Protected-setting writes are verified without hiding Windows refusal.
  * User-facing result states whether protections were reduced or restored.
* Rollback/restore feasibility:
  * Not safe without exact captured values and a recovery path for failed
    Safe Mode/TrustedInstaller execution.
* Risk level: high
* Later implementation decision:
  * Must remain refused until Yazan approves exact protected-setting scope.

### 5. Scheduled Task Behavior

* Source targets:
  * `Microsoft\Windows\ExploitGuard\ExploitGuard MDM policy Refresh`
  * `Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance`
  * `Microsoft\Windows\Windows Defender\Windows Defender Cleanup`
  * `Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan`
  * `Microsoft\Windows\Windows Defender\Windows Defender Verification`
* Intended mutation type:
  * Optimize disables the five tasks with `schtasks /Change /Disable`.
  * Default enables the same five tasks with `schtasks /Change /Enable`.
* Required foundation:
  * Phase 40 reboot/recovery if tasks participate in a multi-stage workflow
  * A future scheduled-task state capture and rollback policy
* Required future production allowlist:
  * Exact scheduled task paths and exact enabled/disabled expectations.
* Required inventory/capture before mutation:
  * Task existence, enabled state, task path, action list, principal, and
    trigger summary where available.
* Required confirmation level:
  * High-risk security confirmation.
* Required verification:
  * Each task enabled/disabled state matches the source-defined branch.
* Rollback/restore feasibility:
  * Not available until a scheduled-task rollback model exists.
* Risk level: high
* Later implementation decision:
  * Must remain refused until exact scheduled-task policy exists.

### 6. TrustedInstaller-Required Operations

* Source targets:
  * `TrustedInstaller` service
  * `cmd.exe /c powershell.exe -encodedcommand <base64>`
  * The generated `$windowssecuritysettings` command list
* Intended mutation type:
  * Temporarily reconfigure `TrustedInstaller` `binPath`, start the service,
    restore the original path, then stop or kill it.
* Required foundation:
  * Phase 42 TrustedInstaller policy
  * Phase 37 service rollback
  * Phase 36 registry/file records
* Required future production allowlist:
  * Exact command descriptor ids.
  * Structured commands, not raw shell strings or encoded command blobs.
  * Exact registry targets each command is allowed to mutate.
* Required inventory/capture before mutation:
  * `TrustedInstaller` service state and original binary path.
  * Verified state references for every protected registry target.
* Required confirmation level:
  * Explicit TrustedInstaller warning.
* Required verification:
  * `TrustedInstaller` path restored.
  * No unapproved command or target was requested.
* Rollback/restore feasibility:
  * Requires exact service and registry rollback records.
* Risk level: high
* Later implementation decision:
  * Must remain refused until a target-specific TrustedInstaller scope exists.

### 7. Safe Mode Entry/Resume Behavior

* Source targets:
  * `bcdedit /set {current} safeboot minimal`
  * `bcdedit /deletevalue {current} safeboot`
  * Safe Mode resume through RunOnce script
* Intended mutation type:
  * Enter minimal Safe Mode, run generated script, remove Safe Mode, restart.
* Required foundation:
  * Phase 43 Safe Mode recovery and resume
  * Phase 40 reboot and recovery workflow
* Required future production allowlist:
  * Exact Safe Mode type `minimal`.
  * Exact tool/action workflow scope.
  * Exact resume and exit handlers.
* Required inventory/capture before mutation:
  * Verified pre-Safe-Mode checkpoints.
  * Verified reboot workflow record.
  * Verified registry, file, service, scheduled task, and TrustedInstaller
    state references.
* Required confirmation level:
  * Explicit Safe Mode and reboot confirmation.
* Required verification:
  * Safe Mode configured only during the approved segment.
  * Safe Mode removed before completion.
* Rollback/restore feasibility:
  * Requires an exit plan before entry.
* Risk level: high
* Later implementation decision:
  * Must remain refused until Phase 43 and Phase 40 scopes are approved.

### 8. RunOnce Behavior

* Source targets:
  * `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce`
  * Value `*defenderoptimize`
  * Value `*defenderdefault`
  * Data:
    `powershell.exe -nop -ep bypass -WindowStyle Maximized -f %SystemRoot%\Temp\defenderoptimize.ps1`
  * Data:
    `powershell.exe -nop -ep bypass -WindowStyle Maximized -f %SystemRoot%\Temp\defenderdefault.ps1`
* Intended mutation type:
  * Schedule generated script execution on next boot.
* Required foundation:
  * Phase 40 reboot/recovery workflow
  * Phase 43 Safe Mode recovery and resume
  * Phase 36 registry rollback
* Required future production allowlist:
  * Exact RunOnce value names and exact trusted resume handler ids.
  * No arbitrary script path execution.
* Required inventory/capture before mutation:
  * Prior RunOnce value existence and data.
  * Generated script hash and content identity.
* Required confirmation level:
  * High-risk explicit confirmation.
* Required verification:
  * RunOnce value appears only in the approved workflow and is consumed or
    cleared as expected.
* Rollback/restore feasibility:
  * Possible only with exact registry capture and recovery records.
* Risk level: high
* Later implementation decision:
  * Must remain refused until a bounded resume handler model exists.

### 9. BCD Behavior

* Source targets:
  * `{current}` boot entry
  * `safeboot minimal`
  * `allowedinmemorysettings`
  * `isolatedcontext`
  * `hypervisorlaunchtype`
* Intended mutation type:
  * Set and delete Safe Mode boot option.
  * Optimize deletes VBS/hypervisor-related BCD values.
* Required foundation:
  * Phase 40 reboot/recovery workflow
  * Phase 43 Safe Mode recovery and resume
  * A future BCD state capture/verification policy for security boot values
* Required future production allowlist:
  * Exact BCD operation ids and values.
  * Separate approval for VBS/hypervisor security changes.
* Required inventory/capture before mutation:
  * Current Safe Mode state.
  * Current values for `allowedinmemorysettings`, `isolatedcontext`, and
    `hypervisorlaunchtype` if present.
* Required confirmation level:
  * High-risk security and reboot confirmation.
* Required verification:
  * `safeboot` removed before final completion.
  * VBS/hypervisor values match branch expectations.
* Rollback/restore feasibility:
  * Not available until BCD capture and recovery behavior is approved.
* Risk level: high
* Later implementation decision:
  * Must remain refused in this phase.

### 10. Temporary Script or REG File Behavior

* Source targets:
  * `%SystemRoot%\Temp\defenderoptimize.ps1`
  * `%SystemRoot%\Temp\defenderdefault.ps1`
* Intended mutation type:
  * Write generated PowerShell scripts with `Set-Content -Force`.
* Required foundation:
  * Phase 36 file state capture and rollback
  * Phase 38 cleanup policy if generated artifacts are removed later
  * Phase 40/43 workflow records if artifacts are resume inputs
* Required future production allowlist:
  * Exact generated paths.
  * Deterministic content identity and hash.
  * Exact cleanup/quarantine rules.
* Required inventory/capture before mutation:
  * Prior existence and hash of each target path.
  * Generated artifact hash after write.
* Required confirmation level:
  * High-risk explicit confirmation because these are boot-resume artifacts.
* Required verification:
  * Artifact content matches approved generated content.
  * Path is local and trusted.
* Rollback/restore feasibility:
  * Possible only with Phase 36 file records and cleanup policy.
* Risk level: high
* Later implementation decision:
  * Must remain refused until generated artifact handling is approved.

### 11. Restore Point Behavior

* Source targets:
  * No restore point creation was detected in this source.
* Intended mutation type:
  * Not applicable in current source.
* Required foundation:
  * A non-tool recovery checkpoint may be recommended separately before any
    future high-risk Defender change.
* Required future production allowlist:
  * None from this source.
* Required inventory/capture before mutation:
  * Not applicable.
* Required confirmation level:
  * High-risk confirmation should still recommend a restore point or other
    checkpoint, but this source does not create one.
* Required verification:
  * Not applicable for source-preserved behavior.
* Rollback/restore feasibility:
  * Restore remains independent of this source.
* Risk level: high
* Later implementation decision:
  * Do not invent restore point behavior as part of preserving this source.

### 12. Reboot Sequencing

* Source targets:
  * `shutdown -r -t 00`
  * `Start-Sleep -Seconds 5`
  * First restart into Safe Mode.
  * Second restart back to normal boot after `safeboot` removal.
* Intended mutation type:
  * Immediate reboot twice per selected branch.
* Required foundation:
  * Phase 40 reboot and recovery workflow
  * Phase 43 Safe Mode workflow
* Required future production allowlist:
  * Exact two-stage workflow.
  * Explicit confirmation, cancellation, expiration, and recovery
    instructions.
* Required inventory/capture before mutation:
  * All registry, file, service, task, TrustedInstaller, and Safe Mode records
    verified before first restart.
* Required confirmation level:
  * High-risk explicit confirmation that Windows will restart.
* Required verification:
  * Safe Mode stage completed or recoverable failure is shown.
  * Normal boot restored after final restart.
* Rollback/restore feasibility:
  * Requires a complete recovery workflow.
* Risk level: high
* Later implementation decision:
  * Must remain refused until exact reboot/resume scopes are approved.

### 13. Downloads/Installers If Present

* Source targets:
  * No URL, `Invoke-WebRequest`, `curl`, `bitsadmin`, installer, MSI, EXE
    download, or installer-launch behavior was detected.
* Intended mutation type:
  * Not applicable.
* Required foundation:
  * Phase 35 would apply if a future source revision or design adds any
    artifact.
* Required future production allowlist:
  * No artifact is approved by this document.
* Required inventory/capture before mutation:
  * Not applicable.
* Required confirmation level:
  * Not applicable for current source.
* Required verification:
  * Future validators should continue proving no download or installer scope is
    approved unless a later phase adds exact provenance.
* Rollback/restore feasibility:
  * Not applicable.
* Risk level: high if ever introduced
* Later implementation decision:
  * Do not invent downloads, installers, or helper tools.

### 14. Default/Restore Behavior

* Source targets:
  * Default branch uses `%SystemRoot%\Temp\defenderdefault.ps1`.
  * Same Safe Mode, TrustedInstaller, RunOnce, BCD, registry, scheduled task,
    and reboot machinery as Optimize.
* Intended mutation type:
  * Apply source-defined Default security values and re-enable the five
    scheduled tasks.
* Required foundation:
  * Same foundations as Optimize.
  * Phase 36 records if a separate Restore action is ever claimed.
* Required future production allowlist:
  * Exact Default values per registry target.
  * Exact scheduled task enable expectations.
* Required inventory/capture before mutation:
  * Same as Optimize.
* Required confirmation level:
  * High-risk explicit confirmation.
* Required verification:
  * Every approved Default value and scheduled task state matches source
    expectation.
* Rollback/restore feasibility:
  * Default is not Restore.
  * Restore remains unavailable unless exact service rollback, registry
    rollback, workflow resume, captured-state restore, or security settings
    restore selection are approved.
* Risk level: high
* Later implementation decision:
  * Default must remain unavailable until the same workflow governance exists.

### 15. Unsupported Broad or Security-Sensitive Targets

* Source targets:
  * Broad protected Defender registry trees.
  * SmartScreen, Smart App Control, PUA protection, phishing protection,
    exploit protection, HVCI, VBS, LSA protection, vulnerable driver blocklist,
    firewall notifications, Defender scheduled tasks, Safe Mode, and
    TrustedInstaller.
* Intended mutation type:
  * Security posture reduction for Optimize and restoration for Default.
* Required foundation:
  * Phase 36, Phase 37, Phase 40, Phase 42, Phase 43, plus a dedicated
    Defender/security policy decision.
* Required future production allowlist:
  * Exact targets only. Unknown or wildcard Defender/security targets remain
    denied.
  * Unknown or wildcard Defender/security targets remain denied.
* Required inventory/capture before mutation:
  * Per-target state capture and current security posture summary.
* Required confirmation level:
  * Explicit user-facing security warning before any future Apply.
* Required verification:
  * Each security target reports Passed, Warning, Failed, or NotAvailable.
  * No protected setting failure is hidden.
* Rollback/restore feasibility:
  * Only exact captured-state restore can be considered.
* Risk level: high
* Later implementation decision:
  * Broad Defender/security mutation remains refused until exact scope and
    security approval exist.

## Exact Registry Path Inventory

The source writes or deletes values under these `25` registry paths. This list
is source inventory only, not approval:

* `HKCU\SOFTWARE\Microsoft\Edge\SmartScreenEnabled`
* `HKCU\SOFTWARE\Microsoft\Edge\SmartScreenPuaEnabled`
* `HKCU\SOFTWARE\Microsoft\Windows Defender Security Center\Account protection`
* `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost`
* `HKLM\SOFTWARE\Microsoft\Windows Defender`
* `HKLM\SOFTWARE\Microsoft\Windows Defender Security Center\Notifications`
* `HKLM\SOFTWARE\Microsoft\Windows Defender Security Center\Virus and threat protection`
* `HKLM\SOFTWARE\Microsoft\Windows Defender\Features`
* `HKLM\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection`
* `HKLM\SOFTWARE\Microsoft\Windows Defender\Spynet`
* `HKLM\SOFTWARE\Microsoft\Windows Defender\Windows Defender Exploit Guard\Controlled Folder Access`
* `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer`
* `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components`
* `HKLM\System\ControlSet001\Control\AppID\Configuration\SMARTLOCKER`
* `HKLM\System\ControlSet001\Control\CI\Config`
* `HKLM\System\ControlSet001\Control\CI\Policy`
* `HKLM\System\ControlSet001\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity`
* `HKLM\System\ControlSet001\Control\Session Manager\kernel`
* `HKLM\System\ControlSet001\Services\SharedAccess\Epoch`
* `HKLM\System\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile`
* `HKLM\System\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\PublicProfile`
* `HKLM\System\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile`
* `HKLM\SYSTEM\CurrentControlSet\Control\Lsa`
* `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce`
* `HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard`

The source contains `85` registry command lines and `78` unique registry
operation shapes when operation, path, value, type, and data are considered.

## Future Safe Apply Requirements

A future safe Apply would require all of the following:

1. A source-preserving Action Plan that decomposes Optimize or Default into
   exact registry, scheduled task, file, TrustedInstaller, Safe Mode, RunOnce,
   BCD, and reboot steps.
2. Exact Phase 36 registry scopes for every Defender/security value.
3. Exact Phase 36 file scopes for generated `.ps1` artifacts.
4. Exact scheduled-task state capture policy for the five source tasks.
5. Exact Phase 42 TrustedInstaller command descriptors with no raw shell
   strings or generated encoded-command payloads.
6. Exact Phase 43 Safe Mode scope and exit plan.
7. Exact Phase 40 reboot workflow scope for both restarts.
8. Explicit high-risk security confirmation before any state change.
9. Verified capture before every mutation.
10. Verification after every target group.
11. Recovery instructions for interrupted Safe Mode or failed BCD cleanup.
12. A security-specific migration record approved by Yazan.

## Default and Restore Boundary

The Ultimate `Defender: Default` branch is a source-defined default preset. It
is not the same thing as BoostLab Restore.

Current Default/Restore must remain unavailable. A future Default would need
the same registry, scheduled task, Safe Mode, TrustedInstaller, RunOnce, BCD,
and reboot governance as Optimize.

Restore remains unavailable unless exact service rollback, registry rollback,
workflow resume, captured-state restore, or security settings restore
selection are approved. BoostLab must not infer a prior security posture from
Ultimate defaults.

## Production Approval State

No production Defender/service/registry/file/reboot/Safe Mode/TrustedInstaller/download/installer scopes are approved by this document.

Defender Optimize Assistant remains a placeholder/refused tool.

The current placeholder module must remain non-executing. A future migration
phase must not implement a partial "safe-looking" subset if doing so would
weaken the source's effective multi-stage security behavior.
