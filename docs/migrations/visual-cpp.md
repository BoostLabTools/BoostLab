# Visual C++ Migration Record

## Identity

- Tool name: Visual C++
- Tool id: `visual-cpp`
- Stage: Graphics
- Module: `modules/Graphics/visual-cpp.psm1`
- Source script path: `source-ultimate/5 Graphics/3 C++.ps1`
- Source SHA-256: `7ACB1F25ECFEEAD83FA389E2D0C1FEEF12232C4E9A740CB5DE64A326FFD38C09`

## Original Ultimate Behavior

The Ultimate script requires Administrator rights and internet access, downloads
twelve Visual C++ redistributable executables from mutable
`refs/heads/main` mirror URLs into `%SystemRoot%\Temp`, then launches each
installer in source-defined order with `/q`, `/qb`, or `/passive /norestart`
switches. The source does not remove the downloaded executables afterward.

## Approved BoostLab Behavior

Phase 101 implements controlled manual handoff only:

- `Analyze`: verifies source identity and reports the source behavior plus
  missing approvals.
- `Open`: prepares manual handoff instructions inside BoostLab only.
- `Apply`: fails closed with `AutoBlockedUntilArtifactApproval`.
- `Default`: returns `DefaultUnavailable`; the source defines no safe Default
  branch.
- `Restore`: returns `RestoreUnavailable`; unavailable without captured
  artifact/package/registry/temp-file
  state and an approved Restore contract.

## Preserved Commands

No source command is executed in Phase 101. The source-defined downloads,
installer filenames, installer switches, and operation order are documented and
reported as blocked Auto intent.

## Intentional Deviations

BoostLab does not download Visual C++ redistributables, launch installers,
change package state, mutate registry, write temp files, perform cleanup, or
change system state. This is an approved safety boundary for the manual-handoff
implementation, not approval to weaken or replace the blocked Auto workflow.

## Side Effects

None. All implemented actions are read-only, manual-handoff text, or
fail-closed blocked results.

## Capabilities

- RequiresAdmin: false for implemented manual handoff; blocked source Auto
  requires Administrator.
- RequiresInternet: false for implemented manual handoff; blocked source Auto
  requires internet.
- CanReboot: false
- CanModifyRegistry: false
- CanModifyServices: false
- CanInstallSoftware: false for implemented manual handoff; blocked source Auto
  launches installers.
- CanDownload: false for implemented manual handoff; blocked source Auto
  downloads twelve redistributables.
- CanModifyDrivers: false
- CanModifySecurity: false
- CanDeleteFiles: false
- UsesTrustedInstaller: false
- UsesSafeMode: false
- SupportsDefault: false
- SupportsRestore: false
- NeedsExplicitConfirmation: true

## Risk Level

High. The implemented behavior is inert, but the source Auto workflow is a
multi-installer runtime workflow with unapproved mutable artifacts.

## Confirmation Requirements

`Open` requires confirmation before preparing manual handoff text. `Apply`,
`Default`, and `Restore` return blocked/unavailable results and perform no
operation.

## Default And Restore

Default is unavailable because the source defines no safe Default branch.
Restore is unavailable until BoostLab has captured eligible state and an
approved Restore contract. Default is not Restore.

## Restart Behavior

No restart or reboot is implemented.

## Test Requirements

- Verify source path and SHA-256.
- Verify Analyze is read-only.
- Verify Open prepares manual handoff only and opens no external tool.
- Verify Apply fails closed with `AutoBlockedUntilArtifactApproval`.
- Verify Default and Restore are unavailable.
- Verify no artifact provenance or production allowlist entry is added.
- Verify source paths remain untouched and deleted tools remain deleted.

## Yazan Approval Status

Approved for controlled manual handoff only in Phase 101. Automated Visual C++
download/installer behavior remains blocked until the complete artifact,
installer, temp-file, cleanup, exit-code, and rollback/support approval package
exists.
