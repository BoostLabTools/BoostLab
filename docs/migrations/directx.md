# DirectX Migration Record

## Tool

- Tool name: DirectX
- Tool id: `directx`
- Stage: Graphics
- Module: `modules/Graphics/directx.psm1`

## Source

- Source script path: `source-ultimate/5 Graphics/2 DirectX.ps1`
- Source SHA-256:
  `17051A2F0F7A0CF16BE525121720406E8F1630C94E5977A7CD4C18652A87EE05`

## Original Ultimate Behavior Summary

The Ultimate source requires Administrator rights and internet connectivity,
downloads `7zip.exe`, silently installs and configures 7-Zip, changes the 7-Zip
Start Menu shortcut location, downloads `directx.exe`, extracts it with 7-Zip
into the Windows Temp DirectX folder, and launches the extracted DirectX setup
executable.

## Approved BoostLab Behavior

Phase 100 approves controlled manual handoff only:

- `Analyze`: read-only source/checksum/status analysis.
- `Open`: prepare manual handoff instructions inside BoostLab only.
- `Apply`: fail closed with `AutoBlockedUntilArtifactApproval`.
- `Default`: `DefaultUnavailable`.
- `Restore`: `RestoreUnavailable`.

## Preserved Commands

No source command is executed in Phase 100. The source behavior is preserved as
reviewed intent and blocked approval requirements. Automated DirectX behavior
remains unavailable until exact artifact provenance, installer execution,
extraction inventory, side-effect scope, cleanup, and rollback approvals exist.

## Intentional Deviations

BoostLab does not download 7-Zip or DirectX, install 7-Zip, change 7-Zip
registry options, move or remove Start Menu shortcuts, extract DirectX files, or
launch DirectX setup. This is an approved safety boundary, not a weakened Auto
implementation; Auto is explicitly blocked rather than partially re-created.

## Side Effects

None for Phase 100. No browser, external tool, download, extraction, installer,
registry mutation, shortcut cleanup, file cleanup, or system mutation occurs.

## Required Privileges

The Ultimate Auto source expects Administrator rights and internet access.
Phase 100 manual handoff does not execute privileged work, but the source-risk
capability metadata remains conservative.

## Capabilities

- RequiresAdmin: false for the implemented manual-handoff behavior; the
  blocked source Auto workflow requires Administrator.
- RequiresInternet: false for the implemented manual-handoff behavior; the
  blocked source Auto workflow requires internet.
- CanReboot: false
- CanModifyRegistry: false for the implemented manual-handoff behavior; the
  blocked source Auto workflow writes 7-Zip HKCU configuration.
- CanModifyServices: false
- CanInstallSoftware: false for the implemented manual-handoff behavior; the
  blocked source Auto workflow installs 7-Zip and launches DirectX setup.
- CanDownload: false for the implemented manual-handoff behavior; the blocked
  source Auto workflow downloads 7-Zip and DirectX artifacts.
- CanModifyDrivers: false
- CanModifySecurity: false
- CanDeleteFiles: false for the implemented manual-handoff behavior; the
  blocked source Auto workflow changes shortcut/temp file state.
- UsesTrustedInstaller: false
- UsesSafeMode: false
- SupportsDefault: false
- SupportsRestore: false
- NeedsExplicitConfirmation: true

## Risk Level

High. The source contains download, installer, extraction, registry, shortcut,
and file cleanup behavior.

## Confirmation Requirements

`Open` and blocked `Apply` require explicit confirmation through the Action Plan
framework. The confirmation text states that no external tool, download,
installer, extraction, registry, shortcut, file cleanup, or system mutation will
occur.

## Rollback, Default, and Restore Behavior

Default is unavailable because the source does not define a safe DirectX default
branch. Restore is unavailable because BoostLab has not captured artifact,
registry, shortcut, file, installer, or cleanup state for this tool.

## Restart Behavior

No restart is performed or requested.

## Test Requirements

Tests must verify source identity, read-only Analyze, manual-handoff-only Open,
blocked Apply, unavailable Default/Restore, no artifact provenance entries, no
production allowlist entries, unchanged protected sources, and updated
inventory counts.

## Yazan Approval Status

Approved for Phase 100 controlled manual handoff only. Auto remains blocked
until a future explicit approval phase.
