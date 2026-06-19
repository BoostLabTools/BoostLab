# Reinstall Migration Record

## Identity

- Tool name: Reinstall
- Tool id: `reinstall`
- Stage: Refresh
- Module: `modules/Refresh/reinstall.psm1`
- Source script path: `source-ultimate/2 Refresh/1 Reinstall.ps1`
- Source SHA-256: `137F519926293F37052817ACBBE20851652E5EA1B9F3B5B9F933AA1E22C2D9FB`

## Original Ultimate Behavior

The Ultimate script requires Administrator rights and internet access, presents
Windows 10 and Windows 11 reinstall choices, downloads the selected Media
Creation Tool executable from the Ultimate-Files mirror into `%SystemRoot%\Temp`,
and launches the downloaded executable.

The Windows 10 branch downloads and launches `mediacreationtoolw10.exe`. The
Windows 11 branch downloads and launches `mediacreationtoolw11.exe`.

## Approved BoostLab Behavior

Phase 104 implements controlled manual handoff only:

- `Analyze`: verifies source identity and reports the source behavior, supported
  Windows 11 target scope, unsupported Windows 10 branch, and missing approvals.
- `Open`: prepares manual handoff instructions inside BoostLab only.
- `Apply`: fails closed with `AutoBlockedUntilArtifactApproval`.
- `Default`: returns `DefaultUnavailable`; the source defines no safe Default
  branch.
- `Restore`: returns `RestoreUnavailable`; unavailable without captured
  reinstall/setup/generated-file/reboot/recovery state and an approved Restore
  contract.

## Preserved Commands

No source command is executed in Phase 104. The source-defined Media Creation
Tool downloads, output paths, executable launches, and Windows 10/Windows 11
branch distinction are preserved as reviewed intent and blocked Auto approval
requirements.

## Intentional Deviations

BoostLab does not download Windows media, download Media Creation Tool
executables, launch setup or installer tools, create or delete setup files,
start repair/refresh/reinstall workflows, modify registry/services/packages,
open external tools, or reboot. This is an approved manual-handoff safety
boundary, not a weakened Auto implementation.

## Side Effects

None. Implemented behavior is read-only analysis, in-app manual handoff text, or
fail-closed blocked results.

## Capabilities

- RequiresAdmin: false for implemented manual handoff; blocked source Auto
  requires Administrator.
- RequiresInternet: false for implemented manual handoff; blocked source Auto
  requires internet.
- CanReboot: false for implemented manual handoff; blocked source Auto may hand
  off to setup/reinstall behavior that can eventually restart.
- CanModifyRegistry: false
- CanModifyServices: false
- CanInstallSoftware: false for implemented manual handoff; blocked source Auto
  launches Media Creation Tool executables.
- CanDownload: false for implemented manual handoff; blocked source Auto
  downloads Media Creation Tool executables.
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
Windows reinstall/media/setup handoff that depends on unapproved mutable
artifacts and executable launch behavior.

## Confirmation Requirements

`Open` requires confirmation before preparing manual handoff text. `Apply`,
`Default`, and `Restore` return blocked or unavailable results and perform no
operation.

## Default And Restore

Default is unavailable because the source defines no safe Default branch.
Restore is unavailable until BoostLab has captured eligible reinstall/setup
state and an approved Restore contract. Default is not Restore.

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

Approved for controlled manual handoff only in Phase 104. Automated Reinstall,
Media Creation Tool download, executable launch, setup/recovery workflow, and
reboot behavior remain blocked until a future explicit approval phase.
