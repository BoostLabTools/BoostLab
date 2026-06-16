# Timer Resolution Assistant Scope Design

## Purpose

This Phase 55 document defines the future implementation scope for the
`Timer Resolution Assistant` tool. It is design-only.

No Timer Resolution Assistant behavior is implemented by this document. No
runtime behavior, module behavior, production service scope, file scope,
registry scope, compiler scope, LocalSystem scope, scheduled task scope, reboot
scope, download artifact, installer execution, Default behavior, or Restore
behavior is approved here.

Timer Resolution Assistant remains a refused placeholder until a later
approved phase adds exact bounded production scopes, generated-artifact
governance, service rollback rules, verification, and implementation.

## Source Reference

* Source path: `source-ultimate/8 Advanced/6 Timer Resolution Assistant.ps1`
* Source SHA-256: `883F7CF4E6179383DE02E44B94FFC8DAFD380246751F1B1D81CAB8800B1E8621`
* Current BoostLab module path:
  `modules/Advanced/timer-resolution-assistant.psm1`
* Current status: refused placeholder
* Current implemented actions: none

Relevant foundations:

* Phase 35: download provenance and installer execution policy
* Phase 36: file and registry state capture and rollback
* Phase 37: service state capture and rollback
* Phase 40: reboot and recovery workflow
* Phase 42: TrustedInstaller / privileged-operation policy if a future design
  attempts privileged protected-path execution

## Source Behavior Summary

The Ultimate source exposes two menu actions:

1. `Timer Resolution: On (Recommended)`
2. `Timer Resolution: Default`

The On branch writes generated C# source to
`%SystemDrive%\Windows\SetTimerResolutionService.cs`, compiles it with
`C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe` into
`C:\Windows\SetTimerResolutionService.exe`, deletes the `.cs` file, deletes an
old service if present, creates and starts a Windows service, enables
`GlobalTimerResolutionRequests`, and opens Task Manager.

The Default branch disables/stops/deletes the same PowerShell-named service,
deletes `C:\Windows\SetTimerResolutionService.exe`, removes
`GlobalTimerResolutionRequests`, and opens Task Manager.

The generated C# code calls `NtQueryTimerResolution` and
`NtSetTimerResolution`, watches process creation through
`ManagementEventWatcher`, writes to the Application event log, and declares a
service installer account of `LocalSystem`.

The source contains no external download URL and no installer launch.

## Current Decision

Do not implement Analyze, Apply, Default, or Restore yet.

The source combines generated compiler input, a generated executable under the
Windows directory, service creation/deletion, timer-resolution API calls,
registry mutation under `HKLM\SYSTEM`, and protected-path cleanup. LocalSystem service creation and C# compilation are high risk because they can create a persistent privileged binary from generated source. These behaviors require exact production scopes, source hashing, generated artifact hashing, service identity decisions, cleanup rules, and verification before BoostLab can preserve the Ultimate behavior safely.

## Behavior Groups

### 1. Timer Service Identity and Naming

* Source targets:
  * PowerShell service name: `Set Timer Resolution Service`
  * C# `ServiceBase.ServiceName`: `STR`
  * C# installer `ServiceInstaller.ServiceName`: `STR`
  * C# installer `DisplayName`: `Set Timer Resolution Service`
* Intended mutation type:
  * Create and manage a Windows service from a generated executable.
* Required foundation:
  * Phase 37 service state capture and rollback
* Required future production allowlist:
  * Exact approved service identity and display name.
  * Explicit decision on the mismatch between PowerShell service name
    `Set Timer Resolution Service` and C# internal service name `STR`.
* Required inventory/capture before mutation:
  * Existing service identity for both `Set Timer Resolution Service` and
    `STR`, if either exists.
  * Binary path, account, startup type, running status, dependencies, and
    failure actions where available.
* Required confirmation level:
  * High-risk explicit service creation confirmation.
* Required verification:
  * Service exists under the exact approved name.
  * Service binary path points to the approved generated executable.
  * Service account and startup type match the approved source behavior.
* Rollback/restore feasibility:
  * Only feasible with exact pre-mutation service records and file records.
* Risk level: high
* Later implementation decision:
  * Must remain refused until service identity is explicitly designed.

### 2. Service Install/Configuration/Start/Stop/Delete Behavior

* Source targets:
  * `Get-Service -Name "Set Timer Resolution Service"`
  * `sc.exe delete "Set Timer Resolution Service"`
  * `New-Service -Name "Set Timer Resolution Service" -BinaryPathName "%SystemDrive%\Windows\SetTimerResolutionService.exe"`
  * `Set-Service -Name "Set Timer Resolution Service" -StartupType Auto`
  * `Set-Service -Name "Set Timer Resolution Service" -Status Running`
  * `Set-Service -Name "Set Timer Resolution Service" -StartupType Disabled`
  * `Set-Service -Name "Set Timer Resolution Service" -Status Stopped`
* Intended mutation type:
  * Delete any existing source-named service, create a new service, set it to
    Automatic, start it, then Default disables/stops/deletes it.
* Required foundation:
  * Phase 37 service state capture and rollback
* Required future production allowlist:
  * Exact service name and allowed mutation types: create, set startup,
    start, stop, disable, delete.
  * Explicit approval for service creation and deletion, which Phase 37 does
    not currently enable.
* Required inventory/capture before mutation:
  * Full service state before deletion or modification.
  * Post-mutation service state after each step.
* Required confirmation level:
  * High-risk explicit confirmation.
* Required verification:
  * Existing service deletion result, create result, startup type, running
    state, and binary path.
  * Default confirms service stopped/deleted or reports exact failure.
* Rollback/restore feasibility:
  * Phase 37 does not currently enable service recreation rollback.
  * Restore remains unavailable without a reviewed create/delete rollback
    design.
* Risk level: high
* Later implementation decision:
  * Must remain refused until service create/delete governance exists.

### 3. LocalSystem Service Behavior

* Source targets:
  * C# `ServiceProcessInstaller.Account = ServiceAccount.LocalSystem`
* Intended mutation type:
  * The generated service installer metadata declares LocalSystem.
  * PowerShell `New-Service` does not specify credentials, so future design
    must verify actual service account behavior rather than assuming it.
* Required foundation:
  * Phase 37 service state capture
  * Phase 42 privileged-operation policy if future execution requires elevated
    protected-path operation beyond Administrator
* Required future production allowlist:
  * Exact account expectation and verification method.
* Required inventory/capture before mutation:
  * Original service account if the service already exists.
  * Created service account after installation.
* Required confirmation level:
  * High-risk LocalSystem service warning.
* Required verification:
  * Confirm whether the resulting service runs as LocalSystem or another
    account.
* Rollback/restore feasibility:
  * Requires exact service record and deletion/recreation rollback design.
* Risk level: high
* Later implementation decision:
  * Must remain refused until LocalSystem behavior is explicitly approved.

### 4. C# Source Generation / Compilation Behavior

* Source targets:
  * `%SystemDrive%\Windows\SetTimerResolutionService.cs`
  * `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe`
  * Compiler arguments:
    `-out:C:\Windows\SetTimerResolutionService.exe C:\Windows\SetTimerResolutionService.cs`
  * Generated C# imports:
    * `kernel32.dll`
    * `ntdll.dll`
  * Timer APIs:
    * `NtQueryTimerResolution`
    * `NtSetTimerResolution`
* Intended mutation type:
  * Generate source code and compile a privileged service executable.
* Required foundation:
  * Phase 36 file state capture and rollback
  * Phase 35 artifact provenance principles for generated artifact identity
* Required future production allowlist:
  * Exact compiler path and arguments.
  * Exact generated source content hash.
  * Exact generated executable hash after compilation.
  * Exact local-only compiler execution policy.
* Required inventory/capture before mutation:
  * Prior existence and hash of `.cs` and `.exe` targets.
  * Compiler binary identity and signer/publisher where available.
* Required confirmation level:
  * High-risk generated binary and compiler execution confirmation.
* Required verification:
  * Source hash matches approved generated source.
  * Generated executable exists at the exact approved path and has the expected
    hash for the current source/compiler decision.
  * Compiler exit code and stderr/stdout are captured.
* Rollback/restore feasibility:
  * Requires exact file records and generated-artifact cleanup policy.
* Risk level: high
* Later implementation decision:
  * Must remain refused until compiler and generated artifact scopes are
    approved.

### 5. Files Created Under Windows or Protected Paths

* Source targets:
  * `C:\Windows\SetTimerResolutionService.cs`
  * `C:\Windows\SetTimerResolutionService.exe`
* Intended mutation type:
  * Write generated C# source, compile executable, delete source, keep
    executable for service use, and Default deletes the executable.
* Required foundation:
  * Phase 36 file state capture and rollback
  * Phase 38 cleanup policy if deletion/quarantine rules are needed later
* Required future production allowlist:
  * Exact protected Windows file paths.
  * Exact overwrite/delete ownership rules.
  * Explicit denial of broad Windows directory cleanup.
* Required inventory/capture before mutation:
  * Prior existence, hash, size, timestamps, and owner/ACL metadata where
    safely available.
* Required confirmation level:
  * High-risk protected-path write/delete confirmation.
* Required verification:
  * `.cs` deleted after compile only if generated by this tool.
  * `.exe` exists after Apply and is deleted after Default only if tool-owned.
* Rollback/restore feasibility:
  * Possible only with exact file state capture and ownership tracking.
* Risk level: high
* Later implementation decision:
  * Must remain refused until protected-path file scopes are approved.

### 6. Registry Timer Policy/Settings

* Source targets:
  * `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel`
  * Value `GlobalTimerResolutionRequests`
* Intended mutation type:
  * Apply writes `GlobalTimerResolutionRequests = REG_DWORD 1`.
  * Default deletes `GlobalTimerResolutionRequests`.
* Required foundation:
  * Phase 36 registry state capture and rollback
* Required future production allowlist:
  * Exact HKLM protected registry path and value name.
  * Exact Apply value and source-defined Default deletion behavior.
* Required inventory/capture before mutation:
  * Prior value existence, type, and data.
* Required confirmation level:
  * High-risk explicit confirmation because this is a system timer policy.
* Required verification:
  * Apply reads back `REG_DWORD 1`.
  * Default confirms value absence or reports exact failure.
* Rollback/restore feasibility:
  * Source Default is not Restore. Restore requires exact captured prior value.
* Risk level: high
* Later implementation decision:
  * Can be reconsidered only with exact registry scope approval.

### 7. Task Manager / Process Verification Behavior

* Source targets:
  * `Start-Process taskmgr.exe`
* Intended mutation type:
  * Open Task Manager after Apply and Default, presumably for manual
    verification.
* Required foundation:
  * Open-only process launch policy if retained.
* Required future production allowlist:
  * Exact executable `taskmgr.exe`.
  * Decision whether this is required behavior or optional UI guidance.
* Required inventory/capture before mutation:
  * Not applicable.
* Required confirmation level:
  * Low for opening Task Manager alone, but it is attached to a high-risk
    workflow.
* Required verification:
  * If preserved, report whether Task Manager launch was requested.
* Rollback/restore feasibility:
  * Not applicable.
* Risk level: low by itself, high in workflow context
* Later implementation decision:
  * Can be implemented later only as part of the approved full source workflow
    or an approved guidance-only Analyze/Open design.

### 8. Cleanup/Default Behavior

* Source targets:
  * Service `Set Timer Resolution Service`
  * `C:\Windows\SetTimerResolutionService.exe`
  * `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel\GlobalTimerResolutionRequests`
* Intended mutation type:
  * Disable, stop, and delete service.
  * Delete generated executable.
  * Delete registry value.
  * Open Task Manager.
* Required foundation:
  * Phase 37 service state capture and rollback
  * Phase 36 file/registry rollback
  * Phase 38 cleanup policy for file deletion ownership if used
* Required future production allowlist:
  * Exact service delete scope.
  * Exact executable delete scope.
  * Exact registry value delete scope.
* Required inventory/capture before mutation:
  * Service state, executable ownership/hash, registry value state.
* Required confirmation level:
  * High-risk explicit confirmation.
* Required verification:
  * Service absent/stopped as source expects.
  * Executable deleted only if tool-owned.
  * Registry value absent.
* Rollback/restore feasibility:
  * Default is source-defined cleanup, not captured-state Restore.
* Risk level: high
* Later implementation decision:
  * Must remain refused until exact service/file/registry cleanup scopes are
    approved.

### 9. Restore Behavior

* Source targets:
  * No captured-state Restore exists in the source.
* Intended mutation type:
  * Not applicable. The source has Apply/On and Default only.
* Required foundation:
  * Phase 36 and Phase 37 if BoostLab later adds true Restore.
* Required future production allowlist:
  * Exact captured-state restore selection and operation ids.
* Required inventory/capture before mutation:
  * Service, file, and registry records captured before Apply or Default.
* Required confirmation level:
  * High-risk explicit confirmation.
* Required verification:
  * Restore must prove the current state still matches the BoostLab-created
    post-mutation state before writing anything.
* Rollback/restore feasibility:
  * Restore remains unavailable until exact service rollback, file rollback,
    registry rollback, and generated-artifact cleanup/restore selection are
    approved.
* Risk level: high
* Later implementation decision:
  * Do not claim Restore in a future implementation unless captured-state
    restore is truly implemented.

### 10. Service Identity Mismatch From Previous Refusal Notes

* Source targets:
  * PowerShell service name: `Set Timer Resolution Service`
  * C# runtime service name: `STR`
  * C# installer service name: `STR`
  * C# display name: `Set Timer Resolution Service`
* Intended mutation type:
  * The source compiles a service executable whose internal identity does not
    match the name used by `New-Service`, `Set-Service`, and `sc.exe delete`.
* Required foundation:
  * Phase 37 service identity validation
* Required future production allowlist:
  * Explicit decision whether preserving the mismatch is required or whether a
    Yazan-approved correction is allowed.
* Required inventory/capture before mutation:
  * Existing state for both possible service identities.
* Required confirmation level:
  * High-risk explicit confirmation.
* Required verification:
  * Service creation/start success and event log behavior are verified under
    the actual service identity Windows uses.
* Rollback/restore feasibility:
  * Blocked until identity is resolved.
* Risk level: high
* Later implementation decision:
  * Must remain refused until the identity decision is documented and approved.

### 11. Unsupported Compiler/Service/Protected-Path Targets

* Source targets:
  * Compiler execution from `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe`
  * Generated executable under `C:\Windows`
  * Service create/delete around a generated binary
  * Protected HKLM timer registry value
* Intended mutation type:
  * Persistent privileged service installation with system timer changes.
* Required foundation:
  * Phase 35, Phase 36, Phase 37, and tool-specific compiler/binary policy
* Required future production allowlist:
  * Exact targets only. Unknown compiler, service, protected-path, and registry targets remain denied.
* Required inventory/capture before mutation:
  * Compiler identity, generated source hash, generated executable hash,
    service state, file state, and registry state.
* Required confirmation level:
  * Explicit high-risk warning before any future Apply.
* Required verification:
  * All generated artifacts, service state, and timer registry state report
    Passed, Warning, Failed, or NotAvailable.
* Rollback/restore feasibility:
  * Only exact captured-state restore can be considered.
* Risk level: high
* Later implementation decision:
  * Broad compiler/service/protected-path mutation remains refused.

## Exact Source Target Inventory

The source targets the following exact identities. This list is inventory only,
not approval:

* Service name used by PowerShell: `Set Timer Resolution Service`
* C# service name: `STR`
* C# display name: `Set Timer Resolution Service`
* Generated source file: `C:\Windows\SetTimerResolutionService.cs`
* Generated executable: `C:\Windows\SetTimerResolutionService.exe`
* Compiler: `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe`
* Compiler arguments:
  `-out:C:\Windows\SetTimerResolutionService.exe C:\Windows\SetTimerResolutionService.cs`
* Registry value:
  `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel\GlobalTimerResolutionRequests`
* Verification UI launcher: `taskmgr.exe`
* Native APIs in generated code: `NtQueryTimerResolution`,
  `NtSetTimerResolution`, `OpenProcess`, `WaitForSingleObject`, `CloseHandle`

## Future Safe Apply Requirements

A future safe Apply would require all of the following:

1. A source-preserving Action Plan that decomposes compiler, file, service,
   registry, and Task Manager launch steps.
2. Exact Phase 36 file scopes for `SetTimerResolutionService.cs` and
   `SetTimerResolutionService.exe`.
3. Exact Phase 36 registry scope for `GlobalTimerResolutionRequests`.
4. Exact Phase 37 service scope for the approved service identity.
5. Exact compiler path and argument allowlist.
6. Generated source hash and generated executable hash.
7. Explicit high-risk confirmation for generated binary and service creation.
8. Verified capture before every mutation.
9. Verification after every target group.
10. Migration record approved by Yazan.

## Default and Restore Boundary

The Ultimate `Timer Resolution: Default` branch is a source-defined cleanup
operation. It is not the same thing as BoostLab Restore.

Current Default/Restore must remain unavailable. A future Default would need
the same service, file, registry, and cleanup governance as Apply.

Restore remains unavailable unless exact service rollback, file rollback,
registry rollback, and generated-artifact cleanup/restore selection are
approved. BoostLab must not infer prior service/file/registry state from the
Ultimate default path.

## Production Approval State

No production service/file/registry/compiler/LocalSystem/download/installer scopes are approved by this document.

Timer Resolution Assistant remains a placeholder/refused tool.

The current placeholder module must remain non-executing. A future migration
phase must not implement a partial "safe-looking" subset if doing so would
weaken the source's effective generated-service behavior.
