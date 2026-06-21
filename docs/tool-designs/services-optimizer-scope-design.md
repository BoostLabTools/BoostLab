# Services Optimizer Scope Design

## Purpose

This Phase 53 document originally defined the future implementation scope for
the `Services Optimizer` tool. It is retained as historical scope evidence.

No Services Optimizer behavior was implemented by this document. No runtime
behavior, module behavior, production service scope, registry scope, file
scope, cleanup scope, reboot scope, Safe Mode scope, BCD scope, RunOnce scope,
TrustedInstaller scope, Default behavior, or Restore behavior was approved by
Phase 53.

Phase 159 supersedes the placeholder/refusal status by implementing the exact
Ultimate Services Off and Services Default workflows for this tool only, after
explicit Yazan approval. This historical design document still does not approve
any reusable production allowlists, scopes, or Restore contract.

## Source Reference

* Source path: `source-ultimate/8 Advanced/5 Services Optimizer.ps1`
* Source SHA-256: `386EEF403F48907E82C2E8E4BE5DFE509B0ED93CADBB5639B42D6326163EDB8F`
* Current BoostLab module path: `modules/Advanced/services-optimizer.psm1`
* Current status after Phase 159: exact Ultimate parity implemented
* Current implemented actions after Phase 159: Analyze, Apply, Default

Relevant foundations:

* Phase 37: service state capture and rollback
* Phase 36: file and registry state capture and rollback
* Phase 40: reboot and recovery workflow
* Phase 42: TrustedInstaller privileged-operation policy
* Phase 43: Safe Mode recovery and resume workflow

## Source Behavior Summary

The Ultimate source exposes two menu actions:

1. `Services: Off`
2. `Services: Default`

The source requires Administrator. It creates a restore point attempt before
the menu, then each selected branch generates a PowerShell script and REG file
under `%SystemRoot%\Temp`, writes a RunOnce resume command, sets Safe Mode
through `bcdedit`, and restarts the machine.

Inside the generated Safe Mode script, the source defines a `Run-Trusted`
helper that temporarily rewrites the `TrustedInstaller` service `binPath` to
run an encoded PowerShell command, starts `TrustedInstaller`, restores the
service binary path, stops `TrustedInstaller`, and kills
`trustedinstaller.exe` when needed.

The generated script imports the services REG payload twice:

* once through `Run-Trusted "Regedit.exe /S ..."`
* once as the Administrator process with `Regedit.exe /S ...`

The source then deletes the Safe Mode boot value and restarts again.

## Current Decision

Phase 159 implements Analyze, Apply, and Default as exact Ultimate parity for
this tool only. Restore remains unavailable because the Ultimate source does not
define captured-state Restore.

The source combines mass service registry mutation, generated scripts,
generated REG files, TrustedInstaller service hijacking, Safe Mode entry,
RunOnce resume, BCD edits, restore-point setup, and two immediate reboots per
selected branch. Phase 159 preserves that source behavior through explicit
confirmation and test-safe executor injection. It does not introduce the
previously rejected productized service analyzer/profile redesign.

## Behavior Groups

### 1. Service Configuration Changes

* Source targets:
  * `HKLM\SYSTEM\ControlSet001\Services\<ServiceName>`
  * `Start` value under each targeted service key
  * Active source target count: `273` services in the Off preset and `273`
    services in the Default preset
  * Commented source entries: `MDCoreSvc`, `SecurityHealthService`, `Sense`,
    `WdNisSvc`, `webthreatdefsvc`, `webthreatdefusersvc`, `WinDefend`,
    `wscsvc`
* Target type:
  * Registry value representing Windows service startup configuration
* Intended mutation type:
  * Off preset writes source-defined `Start` DWORD values, commonly disabling
    many services with `4` while leaving selected critical services at `2` or
    `3`.
  * Default preset writes source-defined `Start` DWORD values, commonly
    restoring many services to `2`, `3`, or `4`.
* Required foundation:
  * Phase 37 service state capture and rollback
  * Phase 36 registry state capture and rollback
  * Phase 42 TrustedInstaller policy for the source's privileged import path
  * Phase 43 Safe Mode workflow
  * Phase 40 reboot workflow
* Required future production allowlist:
  * Exact tool id `services-optimizer`.
  * Exact action ids for Off and Default if ever approved.
  * Exact service names.
  * Exact permitted `Start` values per service and per branch.
  * Exact registry path rooted at
    `HKLM\SYSTEM\ControlSet001\Services\<ServiceName>`.
* Required inventory/capture before mutation:
  * Service existence, display name, binary path, account, dependencies,
    running status, startup type, delayed auto-start, and failure actions where
    available.
  * Registry value existence, type, and data for each exact `Start` value.
  * Capture must complete before any REG import or value write.
* Required confirmation level:
  * High-risk explicit Action Plan confirmation.
  * Separate acknowledgement that Safe Mode, TrustedInstaller, BCD, RunOnce,
    and reboot sequencing are involved.
* Required verification:
  * Every approved service target exists or is reported as unavailable.
  * Every writable `Start` value matches the expected source DWORD after the
    branch completes.
  * Every unavailable service is reported as Warning, not silently ignored.
  * Commented source entries are not mutated unless Yazan separately approves
    them.
* Rollback/restore feasibility:
  * Not feasible through generic Default.
  * Restore would require exact service and registry rollback records captured
    before this specific BoostLab operation.
* Risk level: high
* Later implementation decision:
  * Can be reconsidered only after exact service and registry scopes are
    approved. Dynamic broad service mutation remains refused.

### 2. Service Stop/Start Behavior

* Source targets:
  * `TrustedInstaller`
  * `trustedinstaller.exe`
* Target type:
  * Windows service and process
* Intended mutation type:
  * `Stop-Service -Name TrustedInstaller -Force`
  * `taskkill /im trustedinstaller.exe /f`
  * `sc.exe start TrustedInstaller`
* Required foundation:
  * Phase 37 service rollback
  * Phase 42 TrustedInstaller policy
* Required future production allowlist:
  * Exact `TrustedInstaller` service scope.
  * Exact process target `trustedinstaller.exe`.
  * Exact sequencing and timeout rules.
* Required inventory/capture before mutation:
  * Original `TrustedInstaller` service state, binary path, and running status.
  * Current `trustedinstaller.exe` process identity before any force kill.
* Required confirmation level:
  * High-risk explicit confirmation.
* Required verification:
  * `TrustedInstaller` binary path restored exactly.
  * Any started/stopped state change is recorded.
  * Force-kill result is logged if attempted.
* Rollback/restore feasibility:
  * Only feasible with exact captured service state and a verified post-mutation
    state.
* Risk level: high
* Later implementation decision:
  * Must remain refused until the privileged-operation flow is target-specific,
    bounded, and approved.

### 3. Service Deletion Behavior If Present

* Source targets:
  * No general `sc.exe delete` or service-removal loop was detected in this
    source.
* Target type:
  * Not applicable in current source.
* Intended mutation type:
  * None detected.
* Required foundation:
  * Phase 37 still applies if future review finds service deletion.
* Required future production allowlist:
  * Service deletion requires a separate exact allowlist and rollback design.
* Required inventory/capture before mutation:
  * Full service identity, binary path, account, dependencies, description, and
    failure actions.
* Required confirmation level:
  * High-risk explicit confirmation.
* Required verification:
  * Exact service deletion or non-deletion result by service name.
* Rollback/restore feasibility:
  * Phase 37 does not enable service creation, deletion, or recreation.
* Risk level: high
* Later implementation decision:
  * Service deletion must remain refused unless a later phase explicitly adds a
    reviewed deletion/recreation model.

### 4. Registry Service Key Mutations

* Source targets:
  * `HKLM\SYSTEM\ControlSet001\Services\<ServiceName>\Start`
  * Commented source entries under `HKLM\SYSTEM\CurrentControlSet\Services`
    for Defender/security services listed above
* Target type:
  * HKLM registry value
* Intended mutation type:
  * Import generated REG files with source-defined `Start` values.
* Required foundation:
  * Phase 36 registry state capture and rollback
  * Phase 37 service state capture and rollback
* Required future production allowlist:
  * Exact service key and exact `Start` value for each branch.
  * No wildcard service names.
  * No broad `HKLM\SYSTEM` root scope.
* Required inventory/capture before mutation:
  * Registry value existence, type, and data.
  * Service identity matching the registry key.
* Required confirmation level:
  * High-risk explicit confirmation.
* Required verification:
  * Every `Start` value is read back after mutation.
  * Mismatches are Failed, not Warning.
* Rollback/restore feasibility:
  * Possible only through exact Phase 36 records for the exact values changed.
* Risk level: high
* Later implementation decision:
  * Can be implemented later only through value-level mutation, not raw broad
    REG import.

### 5. TrustedInstaller-Required Operations

* Source targets:
  * `TrustedInstaller` service
  * `cmd.exe /c powershell.exe -encodedcommand <base64>`
  * `Regedit.exe /S "%SystemRoot%\Temp\servicesoff.reg"`
  * `Regedit.exe /S "%SystemRoot%\Temp\serviceson.reg"`
* Target type:
  * Privileged service execution path and registry import command
* Intended mutation type:
  * Temporarily reconfigure `TrustedInstaller` `binPath`, start it, then
    restore the original path.
* Required foundation:
  * Phase 42 TrustedInstaller policy
  * Phase 37 service rollback for `TrustedInstaller`
  * Phase 36 registry/file records for the REG files and targets
* Required future production allowlist:
  * Exact command descriptor ids.
  * No raw encoded command strings.
  * Exact file paths under `%SystemRoot%\Temp` if generated artifacts are ever
    approved.
  * Exact registry targets that command may mutate.
* Required inventory/capture before mutation:
  * Original `TrustedInstaller` service binary path and state.
  * Hash and content identity of generated REG file.
  * Verified Action Plan and state references.
* Required confirmation level:
  * Explicit high-risk TrustedInstaller warning.
* Required verification:
  * `TrustedInstaller` path restored.
  * Requested privileged command id and target list match policy.
  * No unbounded shell string or encoded command is accepted.
* Rollback/restore feasibility:
  * Requires exact service rollback and registry rollback records.
* Risk level: high
* Later implementation decision:
  * Must remain refused until a target-specific TrustedInstaller scope exists.

### 6. Safe Mode Entry/Resume Behavior

* Source targets:
  * `bcdedit /set {current} safeboot minimal`
  * `bcdedit /deletevalue {current} safeboot`
  * Safe Mode resume through RunOnce script
* Target type:
  * Boot configuration and recovery workflow
* Intended mutation type:
  * Enter minimal Safe Mode, run generated script, remove Safe Mode, restart.
* Required foundation:
  * Phase 43 Safe Mode recovery and resume
  * Phase 40 reboot and recovery workflow
* Required future production allowlist:
  * Exact Safe Mode type `minimal`.
  * Exact tool/action workflow scope.
  * Exact resume handler ids, not raw script paths.
  * Exact exit strategy that removes Safe Mode.
* Required inventory/capture before mutation:
  * Verified pre-Safe-Mode checkpoints.
  * Verified reboot workflow record.
  * Verified service, registry, file, and TrustedInstaller state references.
* Required confirmation level:
  * Separate Safe Mode confirmation before any BCD change or restart.
* Required verification:
  * Safe Mode was configured only when intended.
  * Safe Mode was removed after the in-mode work.
  * Resume and exit records are complete and not expired.
* Rollback/restore feasibility:
  * Requires a valid Safe Mode exit plan before entry.
* Risk level: high
* Later implementation decision:
  * Must remain refused until exact Phase 43 and Phase 40 scopes are approved.

### 7. RunOnce Behavior

* Source targets:
  * `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce`
  * Value `*servicesoff`
  * Value `*serviceson`
  * Data:
    `powershell.exe -nop -ep bypass -WindowStyle Maximized -f %SystemRoot%\Temp\servicesoff.ps1`
  * Data:
    `powershell.exe -nop -ep bypass -WindowStyle Maximized -f %SystemRoot%\Temp\serviceson.ps1`
* Target type:
  * HKLM RunOnce registry value
* Intended mutation type:
  * Schedule generated script execution on next boot.
* Required foundation:
  * Phase 40 reboot/recovery workflow
  * Phase 43 Safe Mode recovery and resume
  * Phase 36 registry rollback
* Required future production allowlist:
  * Exact RunOnce value names.
  * Exact trusted resume handler ids.
  * Exact artifact identity if any local script artifact is approved.
* Required inventory/capture before mutation:
  * Existing RunOnce value existence and data.
  * Generated script hash and content identity.
* Required confirmation level:
  * High-risk explicit confirmation.
* Required verification:
  * RunOnce values are created only in the approved workflow.
  * RunOnce values are consumed or cleared according to workflow state.
* Rollback/restore feasibility:
  * Possible only with exact Phase 36 registry capture and a recovery record.
* Risk level: high
* Later implementation decision:
  * Must remain refused until BoostLab owns a bounded resume handler model for
    this tool.

### 8. BCD Behavior

* Source targets:
  * `{current}` boot entry
  * `safeboot minimal`
* Target type:
  * Boot Configuration Data
* Intended mutation type:
  * Set and delete Safe Mode boot option.
* Required foundation:
  * Phase 40 reboot/recovery workflow
  * Phase 43 Safe Mode recovery and resume
* Required future production allowlist:
  * Exact BCD operation ids.
  * Exact boot entry target.
  * Exact Safe Mode value.
* Required inventory/capture before mutation:
  * Current Safe Mode state and relevant BCD state.
  * Recovery instructions if deletevalue fails.
* Required confirmation level:
  * High-risk explicit confirmation.
* Required verification:
  * `safeboot` is present only during the approved Safe Mode segment.
  * `safeboot` is removed before final completion.
* Rollback/restore feasibility:
  * Requires recovery workflow support and explicit exit plan.
* Risk level: high
* Later implementation decision:
  * Must remain refused in this phase.

### 9. Temporary Script or REG File Behavior

* Source targets:
  * `%SystemRoot%\Temp\servicesoff.ps1`
  * `%SystemRoot%\Temp\servicesoff.reg`
  * `%SystemRoot%\Temp\serviceson.ps1`
  * `%SystemRoot%\Temp\serviceson.reg`
* Target type:
  * Generated local script and REG artifacts under Windows temp
* Intended mutation type:
  * Write generated PowerShell and REG files with `Set-Content -Force`.
  * Patch generated script text with a backtick-here-string replacement.
* Required foundation:
  * Phase 36 file state capture and rollback
  * Phase 38 cleanup policy if generated artifacts are removed later
  * Phase 40/43 workflow records if artifacts are resume inputs
* Required future production allowlist:
  * Exact generated paths.
  * Exact file content hashes or deterministic generation rules.
  * Exact cleanup/quarantine policy for generated files.
* Required inventory/capture before mutation:
  * Prior existence and hash of each target path.
  * Generated artifact hash after write.
* Required confirmation level:
  * High-risk explicit confirmation because generated scripts are boot-resume
    artifacts.
* Required verification:
  * Artifact content matches the approved generated content.
  * Artifact path is local and trusted.
  * No network path or user-controlled path is accepted.
* Rollback/restore feasibility:
  * Possible only with Phase 36 file records and cleanup policy.
* Risk level: high
* Later implementation decision:
  * Must remain refused until generated artifact handling is approved.

### 10. Restore Point Behavior

* Source targets:
  * `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore`
  * Value `SystemRestorePointCreationFrequency`
  * `Enable-ComputerRestore -Drive "C:\"`
  * `Checkpoint-Computer -Description "beforeservices" -RestorePointType "MODIFY_SETTINGS"`
* Target type:
  * Registry value and Windows System Restore operation
* Intended mutation type:
  * Temporarily set restore point creation frequency to `0`, enable Computer
    Restore on `C:\`, create restore point `beforeservices`, then delete the
    frequency value.
* Required foundation:
  * Existing Restore Point implementation pattern
  * Phase 36 registry capture for the frequency value if this tool owns it
* Required future production allowlist:
  * Exact restore point name and type.
  * Exact SystemRestore registry value behavior.
* Required inventory/capture before mutation:
  * Prior frequency value existence, type, and data.
  * Restore point command result.
* Required confirmation level:
  * High-risk explicit confirmation in the Services Optimizer Action Plan.
* Required verification:
  * Restore point creation result reported clearly.
  * Frequency value restored/deleted according to source behavior.
* Rollback/restore feasibility:
  * Restore point creation is not the same as BoostLab Restore. It is a safety
    checkpoint, not a reversible Services Optimizer action.
* Risk level: high
* Later implementation decision:
  * Can be designed later, but it does not make the service workflow safe by
    itself.

### 11. Reboot Sequencing

* Source targets:
  * `shutdown -r -t 00`
  * `Start-Sleep -Seconds 5`
  * First restart into Safe Mode.
  * Second restart back to normal boot after `safeboot` removal.
* Target type:
  * Operating system restart flow
* Intended mutation type:
  * Immediate reboot twice per selected branch.
* Required foundation:
  * Phase 40 reboot and recovery workflow
  * Phase 43 Safe Mode workflow
* Required future production allowlist:
  * Exact two-stage workflow.
  * Explicit user confirmation.
  * Cancellation and recovery instructions.
  * Expiration and interrupted-run handling.
* Required inventory/capture before mutation:
  * All service, registry, file, TrustedInstaller, and Safe Mode records must be
    verified before first restart.
* Required confirmation level:
  * High-risk explicit confirmation that Windows will restart.
* Required verification:
  * First stage reached Safe Mode or reported a recoverable failure.
  * Second stage returned to normal boot or showed recovery instructions.
* Rollback/restore feasibility:
  * Requires a complete recovery workflow. No ad hoc reboot is acceptable.
* Risk level: high
* Later implementation decision:
  * Must remain refused until exact reboot/resume scopes are approved.

### 12. Default/Restore Behavior

* Source targets:
  * Default branch uses `serviceson.ps1` and `serviceson.reg`.
  * Same Safe Mode, TrustedInstaller, RunOnce, BCD, REG import, and reboot
    machinery as Off.
* Target type:
  * Source-defined default preset, not captured-state restore.
* Intended mutation type:
  * Apply source-defined Default service `Start` values.
* Required foundation:
  * Same foundations as Off.
  * Phase 36/37 records if a separate Restore action is ever claimed.
* Required future production allowlist:
  * Exact source-defined Default values per service.
  * Exact workflow scopes.
* Required inventory/capture before mutation:
  * Same as Off.
* Required confirmation level:
  * High-risk explicit confirmation.
* Required verification:
  * Every approved Default value matches source expectation.
* Rollback/restore feasibility:
  * Default is not Restore.
  * Restore remains unavailable unless exact captured-state restore selection is
    approved for service and registry records.
* Risk level: high
* Later implementation decision:
  * Default must remain unavailable until the same workflow governance exists.
  * Restore must remain unavailable until captured-state restore selection is
    approved.

### 13. Unsupported Broad or Dynamic Service Targets

* Source targets:
  * Broad generated REG import over hundreds of service keys.
  * Protected and security-sensitive service names appear in commented source
    entries: `MDCoreSvc`, `SecurityHealthService`, `Sense`, `WdNisSvc`,
    `webthreatdefsvc`, `webthreatdefusersvc`, `WinDefend`, `wscsvc`.
* Target type:
  * Broad service registry set and protected-service candidates.
* Intended mutation type:
  * Mass preset import.
* Required foundation:
  * Phase 37 and Phase 36, plus specific security review for protected entries.
* Required future production allowlist:
  * Exact names only. Unknown or wildcard service targets remain denied.
  * No commented source entries may become active without explicit approval.
* Required inventory/capture before mutation:
  * Per-service state and per-registry-value capture.
* Required confirmation level:
  * High-risk explicit confirmation.
* Required verification:
  * Count and identity of mutated services must match the approved allowlist.
* Rollback/restore feasibility:
  * Only exact captured-state restore can be considered.
* Risk level: high
* Later implementation decision:
  * Dynamic broad service mutation remains refused.

## Exact Active Service Target List

The source active REG payloads target these `273` service-name entries. A future
implementation must not treat this list as an approval. It is only the source
inventory required before any exact production allowlist can be proposed.

- AarSvc, ADPSvc, AJRouter, ALG, AppIDSvc, Appinfo, AppMgmt, AppReadiness
- AppVClient, AppXSvc, ApxSvc, AssignedAccessManagerSvc, AudioEndpointBuilder, Audiosrv, autotimesvc, AxInstSV
- BcastDVRUserService, BDESVC, BFE, BITS, BluetoothUserService, BrokerInfrastructure, Browser, BTAGService
- BthAvctpSvc, bthserv, camsvc, CaptureService, cbdhsvc, CDPSvc, CDPUserSvc, CertPropSvc
- ClipSVC, CloudBackupRestoreSvc, cloudidsvc, COMSysApp, ConsentUxUserSvc, CoreMessagingRegistrar, CredentialEnrollmentManagerUserSvc, CryptSvc
- CscService, DcomLaunch, dcsvc, defragsvc, DeviceAssociationBrokerSvc, DeviceAssociationService, DeviceInstall, DevicePickerUserSvc
- DevicesFlowUserSvc, DevQueryBroker, Dhcp, diagnosticshub.standardcollector.service, diagsvc, DiagTrack, DialogBlockingService, DispBrokerDesktopSvc
- DisplayEnhancementService, DmEnrollmentSvc, dmwappushservice, Dnscache, DoSvc, dot3svc, DPS, DsmSvc
- DsSvc, DusmSvc, EapHost, EFS, embeddedmode, EntAppSvc, EventLog, EventSystem
- Fax, fdPHost, FDResPub, fhsvc, FontCache, FontCache3.0.0.0, FrameServer, FrameServerMonitor
- GameInputSvc, gpsvc, GraphicsPerfSvc, hidserv, hpatchmon, HvHost, icssvc, IKEEXT
- InstallService, InventorySvc, iphlpsvc, IpxlatCfgSvc, KeyIso, KtmRm, LanmanServer, LanmanWorkstation
- lfsvc, LicenseManager, lltdsvc, lmhosts, LocalKdc, LSM, LxpSvc, MapsBroker
- McmSvc, McpManagementService, MessagingService, midisrv, MixedRealityOpenXRSvc, mpssvc, MSDTC, MSiSCSI
- msiserver, MsKeyboardFilter, NaturalAuthentication, NcaSvc, NcbService, NcdAutoSetup, Netlogon, Netman
- netprofm, NetSetupSvc, NetTcpPortSharing, NgcCtnrSvc, NgcSvc, NlaSvc, NPSMSvc, nsi
- OneSyncSvc, p2pimsvc, p2psvc, P9RdrService, PcaSvc, PeerDistSvc, PenService, perceptionsimulation
- PerfHost, PhoneSvc, PimIndexMaintenanceSvc, pla, PlugPlay, PNRPAutoReg, PNRPsvc, PolicyAgent
- Power, PrintDeviceConfigurationService, PrintNotify, PrintScanBrokerService, PrintWorkflowUserSvc, ProfSvc, PushToInstall, QWAVE
- RasAuto, RasMan, refsdedupsvc, RemoteAccess, RemoteRegistry, RetailDemo, RmSvc, RpcEptMapper
- RpcLocator, RpcSs, SamSs, SCardSvr, ScDeviceEnum, Schedule, SCPolicySvc, SDRSVC
- seclogon, SEMgrSvc, SENS, SensorDataService, SensorService, SensrSvc, SessionEnv, SgrmBroker
- SharedAccess, SharedRealitySvc, ShellHWDetection, shpamsvc, smphost, SmsRouter, SNMPTrap, spectrum
- Spooler, sppsvc, SSDPSRV, ssh-agent, SstpSvc, StateRepository, StiSvc, StorSvc
- svsvc, swprv, SysMain, SystemEventsBroker, TabletInputService, TapiSrv, TermService, TextInputManagementService
- stisvc
- Themes, TieringEngineService, TimeBrokerSvc, TokenBroker, TrkWks, TroubleshootingSvc, TrustedInstaller, tzautoupdate
- UdkUserSvc, UevAgentService, uhssvc, UmRdpService, UnistoreSvc, upnphost, UserDataSvc, UserManager
- UsoSvc, VacSvc, VaultSvc, vds, vmicguestinterface, vmicheartbeat, vmickvpexchange, vmicrdv
- vmicshutdown, vmictimesync, vmicvmsession, vmicvss, VSS, W32Time, WaaSMedicSvc, WalletService
- WarpJITSvc, wbengine, WbioSrvc, Wcmsvc, wcncsvc, WdiServiceHost, WdiSystemHost, WebClient
- Wecsvc, WEPHOSTSVC, wercplsupport, WerSvc, WFDSConMgrSvc, whesvc, WiaRpc, WinHttpAutoProxySvc
- Winmgmt, WinRM, wisvc, WlanSvc, wlidsvc, wlpasvc, WManSvc, wmiApSrv
- WMPNetworkSvc, workfolderssvc, WpcMonSvc, WPDBusEnum, WpnService, WpnUserService, WSAIFabricSvc, WSearch
- wuauserv, wuqisvc, WwanSvc, XblAuthManager, XblGameSave, XboxGipSvc, XboxNetApiSvc, ZTHELPER

Commented source entries are source-visible but inactive:

`MDCoreSvc`, `SecurityHealthService`, `Sense`, `WdNisSvc`,
`webthreatdefsvc`, `webthreatdefusersvc`, `WinDefend`, `wscsvc`.

## Future Safe Apply Requirements

A future safe Apply would require all of the following:

1. A source-preserving Action Plan that decomposes Off or Default into exact
   service, registry, file, TrustedInstaller, Safe Mode, RunOnce, BCD, restore
   point, and reboot steps.
2. Exact Phase 37 service scopes for every active service target.
3. Exact Phase 36 registry scopes for every `Start` value and RunOnce value.
4. Exact Phase 36 file scopes for generated `.ps1` and `.reg` artifacts.
5. Exact Phase 42 TrustedInstaller command descriptors with no raw shell
   strings or generated encoded-command payloads.
6. Exact Phase 43 Safe Mode scope and exit plan.
7. Exact Phase 40 reboot workflow scope for both restarts.
8. Explicit high-risk confirmation before any state change.
9. Verified capture before every mutation.
10. Verification after every target group.
11. Recovery instructions for interrupted Safe Mode or failed BCD cleanup.
12. A migration record approved by Yazan.

## Default and Restore Boundary

The Ultimate `Services: Default` branch is a source-defined preset. It is not
the same thing as BoostLab Restore.

Current Default/Restore must remain unavailable. A future Default would need
the same service, registry, Safe Mode, TrustedInstaller, RunOnce, BCD, and
reboot governance as Off.

Restore remains unavailable unless exact service rollback, registry rollback,
workflow resume, and captured-state restore selection are approved. BoostLab
must not infer the user's prior service state from Ultimate defaults.

## Production Approval State

No production service/registry/file/reboot/Safe Mode/TrustedInstaller scopes
are approved by this document.

Services Optimizer remains a placeholder/refused tool.

The current placeholder module must remain non-executing. A future migration
phase must not enable partial "safe-looking" service changes if doing so would
weaken the source's effective multi-stage behavior.
