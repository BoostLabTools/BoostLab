# Reinstall Scope and Provenance Design

## Purpose

This document defines the exact future scope required before the BoostLab
`Reinstall` tool can be safely implemented.

This is a design and provenance document only. It does not approve any
download, executable launch, installer execution, reboot workflow, file scope,
registry scope, or reinstall workflow.

## Source Reference

* Tool id: `reinstall`
* Tool title: `Reinstall`
* Stage: `Refresh`
* Current module: `modules/Refresh/reinstall.psm1`
* Source path: `source-ultimate/2 Refresh/1 Reinstall.ps1`
* Source SHA-256: `137F519926293F37052817ACBBE20851652E5EA1B9F3B5B9F933AA1E22C2D9FB`

## Product Scope Decision

BoostLab's preferred product target is Windows 11. Product scope is branch
level, not a blanket host-OS block.

For this tool:

* The Windows 10 Media Creation Tool branch is unsupported.
* A future Windows 10 host may be allowed only when preparing or launching an
  approved Windows 11 reinstall/refresh workflow.
* The Windows 11 Media Creation Tool branch may be considered later only after
  download provenance, executable verification, installer execution approval,
  and reboot/recovery handoff requirements are satisfied.
* Windows 10 optimization behavior is not part of this tool and must not be
  added.

## Source Behavior Summary

The Ultimate source is an administrator-only console menu with an internet
precheck. It presents two choices:

* `Write-Host "1. Reinstall: W10"`
* `Write-Host "2. Reinstall: W11`n"`

The source validates `Read-Host` input against `^[1-2]$`.

Before the menu it checks internet by using:

* `Test-Connection -ComputerName "8.8.8.8"`

When option 1 is selected, the source downloads a Windows 10 Media Creation
Tool executable and launches it:

* `IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw10.exe"`
* `OutFile "$env:SystemRoot\Temp\mediacreationtoolw10.exe"`
* `Start-Process "$env:SystemRoot\Temp\mediacreationtoolw10.exe"`

When option 2 is selected, the source downloads a Windows 11 Media Creation
Tool executable and launches it:

* `IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw11.exe"`
* `OutFile "$env:SystemRoot\Temp\mediacreationtoolw11.exe"`
* `Start-Process "$env:SystemRoot\Temp\mediacreationtoolw11.exe"`

The source does not directly run `setup.exe`, mount an ISO, write registry
values, delete files, call `shutdown`, or pass explicit installer switches.
However, it hands control to a downloaded executable that can perform Windows
setup/media/reinstall work outside BoostLab's current approved execution
scope.

## Current Decision

Reinstall remains a refused placeholder.

No production download/executable/installer/reinstall/reboot/file/registry scopes
are approved for Reinstall in this phase.

Partial implementation would weaken or distort Ultimate behavior. A browser
link, generic Windows Settings page, or locally invented reinstall assistant
would not preserve the source-defined behavior, which downloads and launches a
specific Media Creation Tool executable.

## Behavior Groups

### 1. Windows 10-Only Branch Behavior

Exact source targets:

* Menu choice: `1`
* Console label: `Write-Host "1. Reinstall: W10"`
* Download URL:
  `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw10.exe`
* Output path: `$env:SystemRoot\Temp\mediacreationtoolw10.exe`
* Launch command: `Start-Process "$env:SystemRoot\Temp\mediacreationtoolw10.exe"`

Intended mutation or launch type:

* Downloads and launches a Windows 10 Media Creation Tool executable.

Required foundation:

* Download provenance and checksum/signature policy.
* Installer execution policy.
* Reboot/recovery workflow if execution can hand off to setup or restart.

Required future production allowlist:

* None should be added under current product scope.

Required provenance before download/launch:

* Not applicable because this branch is unsupported.

Required user confirmation level:

* Branch must remain disabled or NotApplicable.

Required verification:

* Verify the branch remains unavailable and does not download or launch.

Rollback/restore feasibility:

* Not applicable because unsupported.

Risk level:

* High.

Later implementation decision:

* Must remain refused unless Yazan explicitly expands scope to Windows 10
  reinstall workflows.

### 2. Windows 11 Reinstall/Refresh Branch Behavior

Exact source targets:

* Menu choice: `2`
* Console label: `Write-Host "2. Reinstall: W11`n"`
* Download URL:
  `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw11.exe`
* Output path: `$env:SystemRoot\Temp\mediacreationtoolw11.exe`
* Launch command: `Start-Process "$env:SystemRoot\Temp\mediacreationtoolw11.exe"`

Intended mutation or launch type:

* Downloads and launches a Windows 11 Media Creation Tool executable.

Required foundation:

* Phase 35 download provenance and installer execution policy.
* Phase 40 reboot/recovery workflow policy.
* Phase 36 file state capture policy for generated temp files if BoostLab
  manages the download path.

Required future production allowlist:

* Exact artifact id for the Windows 11 Media Creation Tool.
* Exact approved source URL.
* Exact output directory and file name scope.
* Exact execution descriptor for launching the verified executable.
* Exact workflow handoff/recovery scope if the executable can restart or hand
  off to setup.

Required provenance before download/launch:

* Expected SHA-256.
* Expected file name.
* Expected size or size bounds.
* Expected publisher/signer.
* License or redistributability note.
* Approval status.
* Verification requirements before use.

Required user confirmation level:

* Explicit Action Plan confirmation before any download or launch.
* Confirmation must state that the Media Creation Tool can modify Windows
  installation state, create media, start upgrade/reinstall flows, require
  Microsoft account/OOBE steps, and may eventually restart the PC.

Required verification:

* Artifact is known and approved.
* Download path is approved and local.
* Downloaded file name matches expected file name.
* Downloaded SHA-256 matches expected SHA-256.
* Executable signer/publisher matches expected signer.
* Execution request is approved by installer policy.
* Launch status and process start result are logged.

Rollback/restore feasibility:

* BoostLab can only clean up its own verified generated download file if a
  future cleanup scope approves that.
* BoostLab cannot restore Windows setup changes after handoff without a
  separately approved reboot/recovery and restore workflow.

Risk level:

* High.

Later implementation decision:

* Can be reconsidered only after real artifact provenance and execution scopes
  are approved.

### 3. Media Creation Tool Download Behavior

Exact source targets:

* `IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw10.exe"`
* `IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw11.exe"`
* `$env:SystemRoot\Temp\mediacreationtoolw10.exe`
* `$env:SystemRoot\Temp\mediacreationtoolw11.exe`

Intended mutation or launch type:

* Network download of executable files into the Windows temp directory.

Required foundation:

* Phase 35 download provenance policy.

Required future production allowlist:

* One approved artifact entry per executable.

Required provenance before download/launch:

* Exact stable source URL.
* SHA-256.
* Expected file size or bounds.
* Expected signer/publisher.
* Execution permission.
* Approval status.

Required user confirmation level:

* Explicit confirmation before download because the artifacts are executable
  reinstall tooling.

Required verification:

* The provenance manifest allows the artifact.
* The downloaded file matches hash, name, size, and signer expectations.

Rollback/restore feasibility:

* Download cleanup is feasible only for BoostLab-owned generated files and only
  after a bounded file scope is approved.

Risk level:

* High.

Later implementation decision:

* Refused until immutable or otherwise trusted provenance exists.

### 4. Third-Party Mirror or Mutable URL Behavior

Exact source targets:

* mutable third-party mirror URL:
  `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw10.exe`
* mutable third-party mirror URL:
  `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw11.exe`

Intended mutation or launch type:

* Downloads executable artifacts from a branch reference.

Required foundation:

* Phase 35 provenance policy with deny-by-default behavior.

Required future production allowlist:

* No approval should be given to floating or mutable branch artifacts unless a
  separate review explicitly documents why that source can be trusted and how
  hash/signature pinning is enforced.

Required provenance before download/launch:

* Stable artifact identity, expected SHA-256, signer, and version evidence.

Required user confirmation level:

* Explicit confirmation is required, but confirmation alone is not sufficient
  without provenance approval.

Required verification:

* Hash and signer verification must pass before any launch.

Rollback/restore feasibility:

* Not meaningful for trust. A bad artifact must be blocked before execution.

Risk level:

* High.

Later implementation decision:

* Current source URLs are refused because they are mutable third-party mirror
  URLs without checked provenance.

### 5. Installer/Executable Launch Behavior

Exact source targets:

* `Start-Process "$env:SystemRoot\Temp\mediacreationtoolw10.exe"`
* `Start-Process "$env:SystemRoot\Temp\mediacreationtoolw11.exe"`

Intended mutation or launch type:

* Launches a downloaded executable with no command-line switches.

Required foundation:

* Phase 35 installer execution policy.
* Phase 40 reboot/recovery workflow policy for handoff and restart risk.

Required future production allowlist:

* Exact executable descriptor.
* Exact argument list, even if empty.
* Exact working directory.
* Expected publisher/signer.
* Expected exit-code and handoff behavior.

Required provenance before download/launch:

* Artifact must pass provenance verification before execution.

Required user confirmation level:

* Explicit confirmation that this launches Windows reinstall/media tooling.

Required verification:

* No execution from URL.
* No execution from unverified temp path.
* Process start is logged.
* Exit code or handoff state is captured if available.

Rollback/restore feasibility:

* Execution handoff is not inherently reversible. Rollback would need a
  separate workflow and may not be possible after Windows setup starts.

Risk level:

* High.

Later implementation decision:

* Refused until executable launch can be approved by policy.

### 6. ISO/Setup/Upgrade Workflow Behavior If Present

Exact source targets:

* The source does not directly call `setup.exe`.
* The source does not mount or generate an ISO.
* The source delegates any setup, media, upgrade, or reinstall behavior to the
  launched Media Creation Tool executable.

Intended mutation or launch type:

* Indirect handoff to external Windows setup/media workflow.

Required foundation:

* Reboot/recovery workflow.
* Installer execution policy.

Required future production allowlist:

* Exact handoff states and recovery instructions.

Required provenance before download/launch:

* Verified executable provenance before launch.

Required user confirmation level:

* Explicit user confirmation before launch.

Required verification:

* Confirm BoostLab only launched the approved executable.
* Record that any subsequent setup flow is outside direct BoostLab control.

Rollback/restore feasibility:

* No Default/Restore should be claimed for Windows setup changes.

Risk level:

* High.

Later implementation decision:

* Future implementation must be framed as a guided, confirmed handoff, not as a
  silent reinstall.

### 7. File/Temp/Download Target Behavior If Present

Exact source targets:

* `$env:SystemRoot\Temp\mediacreationtoolw10.exe`
* `$env:SystemRoot\Temp\mediacreationtoolw11.exe`

Intended mutation or launch type:

* Writes downloaded executable files under the Windows temp directory.

Required foundation:

* Phase 36 file state capture if an existing file could be overwritten.
* Phase 38 cleanup policy if BoostLab later deletes generated files.

Required future production allowlist:

* Exact file path scope for generated executable downloads.

Required provenance before download/launch:

* The generated file must be associated with a known artifact id and verified.

Required user confirmation level:

* Confirmation before writing executable files to a system temp path.

Required verification:

* Path is local.
* Path is not network, reparse-point, or untrusted.
* Existing file handling is defined before overwrite.
* Generated file hash and signer match approved metadata.

Rollback/restore feasibility:

* If a file already exists, state capture must record prior existence and
  identity before overwrite.
* Cleanup can delete only the verified BoostLab-owned generated executable.

Risk level:

* High.

Later implementation decision:

* Requires exact file scope and ownership policy.

### 8. Reboot/Restart Behavior If Present

Exact source targets:

* The source does not directly call `shutdown` or `Restart-Computer`.
* The launched Media Creation Tool may initiate or guide restart/setup behavior
  after handoff.

Intended mutation or launch type:

* Reboot-capable external handoff.

Required foundation:

* Phase 40 reboot/recovery workflow.

Required future production allowlist:

* Exact workflow id for Reinstall launch/handoff.
* Explicit recovery instructions.
* Known resume behavior if BoostLab is expected to continue after restart.

Required provenance before download/launch:

* Verified executable provenance before any reboot-capable tool launch.

Required user confirmation level:

* Confirmation must clearly state restart/reinstall risk, interruption risk,
  BitLocker/recovery key risks, and that Windows setup may take over after
  launch.

Required verification:

* Record whether BoostLab only launched the tool or whether a workflow handoff
  was entered.

Rollback/restore feasibility:

* Not approved. Windows reinstall/refresh workflows may not be reversible from
  BoostLab.

Risk level:

* High.

Later implementation decision:

* No reboot or recovery scope is approved in this phase.

### 9. User Confirmation and Warning Requirements

Exact source targets:

* Console menu selection via `Read-Host`.
* No detailed reinstall warning beyond branch labels.

Intended mutation or launch type:

* User-controlled branch selection.

Required foundation:

* Action Plan and confirmation framework.
* Download/installer policy.
* Reboot/recovery policy.

Required future production allowlist:

* Action `Analyze` can describe readiness and unsupported branches.
* Action `Apply` or `Launch` can request the Windows 11 handoff only after all
  provenance and execution approvals exist.

Required provenance before download/launch:

* Provenance must be verified before the confirmation can lead to execution.

Required user confirmation level:

* High-risk explicit confirmation.
* Warning text must include possible app/data impact, Windows reinstall or
  refresh side effects, Microsoft account/OOBE effects, BitLocker/recovery key
  risks, interruption risks, admin requirement, internet requirement, and
  reboot/setup handoff risk.

Required verification:

* Confirmation result is recorded with the action plan.

Rollback/restore feasibility:

* Confirmation does not create rollback. It only authorizes a bounded action.

Risk level:

* High.

Later implementation decision:

* Required before any future launch action.

### 10. Verification Before Launch

Exact source targets:

* Internet precheck: `Test-Connection -ComputerName "8.8.8.8"`
* No hash verification.
* No signer verification.
* No file size verification.
* No version verification.

Intended mutation or launch type:

* Minimal connectivity precheck only.

Required foundation:

* Environment internet detection.
* Artifact provenance verification.
* Installer execution request validation.

Required future production allowlist:

* Exact artifact and execution descriptors.

Required provenance before download/launch:

* SHA-256, signer, file name, size, URL, redistributability/license note, admin
  and reboot flags.

Required user confirmation level:

* User confirmation after verification passes and before launch.

Required verification:

* Internet is available.
* Artifact is listed and approved.
* Downloaded file matches expected hash and signer.
* Launch request is approved.

Rollback/restore feasibility:

* Pre-launch verification prevents unsafe execution. It does not restore setup
  changes after launch.

Risk level:

* High.

Later implementation decision:

* Required for any future Windows 11 branch implementation.

### 11. Verification After Launch or Handoff

Exact source targets:

* The source does not capture process id, exit code, installer result, setup
  state, or handoff result.

Intended mutation or launch type:

* Fire-and-forget process launch.

Required foundation:

* Installer execution policy.
* Reboot/recovery workflow if a handoff is tracked.

Required future production allowlist:

* Approved result model for launched Media Creation Tool.

Required provenance before download/launch:

* Completed before launch.

Required user confirmation level:

* Explicit launch confirmation.

Required verification:

* Process start succeeded or failed.
* Exit code captured if the process ends while BoostLab is still running.
* If handoff begins, record handoff and recovery guidance.

Rollback/restore feasibility:

* No Default/Restore for Windows setup outcomes.

Risk level:

* High.

Later implementation decision:

* Future implementation must avoid pretending that process launch equals a
  completed reinstall.

### 12. Default/Restore Behavior

Exact source targets:

* The source has no Default option.
* The source has no Restore option.
* The source does not capture state before launching Media Creation Tool.

Intended mutation or launch type:

* None.

Required foundation:

* State capture and reboot/recovery foundations if any future Restore claim is
  considered.

Required future production allowlist:

* None approved.

Required provenance before download/launch:

* Not applicable.

Required user confirmation level:

* Not applicable.

Required verification:

* Confirm BoostLab does not expose Default or Restore for Reinstall.

Rollback/restore feasibility:

* Current Default/Restore must remain unavailable.
* Restore remains unavailable unless exact workflow state, generated-file
  ownership, setup handoff state, and recoverable side effects are captured and
  verified by a future approved design.

Risk level:

* High if incorrectly exposed.

Later implementation decision:

* Do not add Default or Restore in a future implementation unless a separate
  approved restore workflow exists.

### 13. Unsupported Reinstall/Refresh Targets

Exact source targets:

* Windows 10 branch.
* Any non-source reinstall mode.
* Any invented reset, ISO, setup, disk, partition, format, or recovery option.

Intended mutation or launch type:

* Unsupported under current scope.

Required foundation:

* None, because these targets are not approved.

Required future production allowlist:

* None.

Required provenance before download/launch:

* Not applicable.

Required user confirmation level:

* Unsupported branches must not become executable by confirmation alone.

Required verification:

* Confirm unsupported branches remain disabled, visual-only, or NotApplicable.

Rollback/restore feasibility:

* Not applicable.

Risk level:

* High.

Later implementation decision:

* Must remain refused unless Yazan explicitly changes product scope and
  governance approvals.

## Exact Source Target Inventory

Menu and branch logic:

* `Write-Host "1. Reinstall: W10"`
* `Write-Host "2. Reinstall: W11`n"`
* `Read-Host " "`
* Input validation: `^[1-2]$`

Connectivity:

* `Test-Connection -ComputerName "8.8.8.8"`

Windows 10 branch:

* URL:
  `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw10.exe`
* Output:
  `$env:SystemRoot\Temp\mediacreationtoolw10.exe`
* Launch:
  `Start-Process "$env:SystemRoot\Temp\mediacreationtoolw10.exe"`

Windows 11 branch:

* URL:
  `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw11.exe`
* Output:
  `$env:SystemRoot\Temp\mediacreationtoolw11.exe`
* Launch:
  `Start-Process "$env:SystemRoot\Temp\mediacreationtoolw11.exe"`

No direct source behavior found:

* No direct `setup.exe` launch.
* No direct ISO mount.
* No direct `shutdown` or `Restart-Computer`.
* No direct registry mutation.
* No direct broad file deletion.
* No explicit installer switches.

## Future Safe Open/Apply/Launch Requirements

A future implementation can be considered only for the Windows 11 branch and
only after:

1. A real artifact approval is added to `config/ArtifactProvenance.psd1`.
2. The approved artifact includes exact URL, file name, SHA-256, size or size
   bounds, signer/publisher, license or redistributability note, admin flag,
   reboot flag, and verification requirements.
3. The artifact source is stable enough for provenance verification.
4. The execution descriptor is approved by installer execution policy.
5. A file ownership/capture rule is approved for the generated executable path.
6. A reboot/recovery handoff plan is approved if BoostLab tracks the Media
   Creation Tool after launch.
7. The UI Action Plan clearly identifies download, verification, executable
   launch, reinstall/refresh risk, BitLocker/recovery key risks, Microsoft
   account/OOBE effects, interruption risks, and lack of automatic rollback.

Potential future actions:

* `Analyze`: report branch support, missing approvals, host readiness, and
  unsupported Windows 10 branch.
* `Apply` or `Launch`: only after provenance and execution approvals exist.

No direct URL execution is allowed. No execution from an unverified temp path
is allowed. No unrelated cleanup is allowed.

## Default and Restore Boundary

Current Default/Restore must remain unavailable.

The source provides no Default and no Restore behavior. BoostLab must not claim
it can restore a Windows reinstall/refresh workflow unless a future design
captures exact workflow state and proves a bounded recovery path. Even then,
Windows setup side effects may remain outside BoostLab control.

## Production Approval State

Current approved production scopes for Reinstall:

* Artifact approvals: none.
* Download approvals: none.
* Executable launch approvals: none.
* Installer execution approvals: none.
* Reinstall/refresh workflow approvals: none.
* Reboot/recovery workflow approvals: none.
* File/temp path scopes: none.
* Registry scopes: none.
* Cleanup scopes: none.
* Default/Restore scopes: none.

Reinstall must remain a refused placeholder until these approvals are supplied
in a future explicit implementation phase.
