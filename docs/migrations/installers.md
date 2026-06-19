# Installers Migration Record

- Tool name: Installers
- Tool id: `installers`
- Stage: Installers
- Module: `modules/Installers/installers.psm1`
- Source script path: `source-ultimate/4 Installers/1 Installers.ps1`
- Source SHA-256: `1065D64183457D4E7B28EA78DDE41525EC8F7C4A4BCA12D29B70D991141C0C67`
- Migration status: Controlled manual handoff only
- Yazan approval status: Approved for Phase 105 manual handoff only

## Original Ultimate Behavior

The source is an Administrator-only interactive menu for application installers.
It checks internet connectivity, offers Discord, Roblox, 7-Zip, Battle.net,
Brave, Electronic Arts, Epic Games, Escape From Tarkov, Firefox, Frame View,
GOG launcher, Google Chrome, League Of Legends, Notepad++, Nvidia App, OBS
Studio, Onboard Memory Manager, Pot Player, Rockstar Games, Spotify, Steam,
Ubisoft Connect, and Valorant choices.

The source downloads 24 external artifacts, launches installers or helper
executables, applies selected silent switches, writes app configuration and
browser policies, creates or reshapes shortcuts, removes selected services and
scheduled tasks, removes selected startup entries or components, and performs
selected cleanup.

## Approved BoostLab Behavior

BoostLab implements only:

- `Analyze`: read-only source/checksum/status analysis.
- `Open`: controlled manual handoff instructions prepared inside BoostLab only.
- `Apply`: blocked with `AutoBlockedUntilArtifactApproval`.
- `Default`: blocked with `DefaultUnavailable`.
- `Restore`: blocked with `RestoreUnavailable`.

No downloads, installer launches, package changes, app configuration, cleanup, or system mutation are implemented.

## Preserved Commands

No operational source commands are executed in Phase 105. The source behavior is
preserved as documented operational intent and remains blocked for Auto until
all required artifact and execution approvals exist.

## Intentional Deviations

Automated download, installer launch, post-install configuration, cleanup,
uninstall, Default, and Restore behavior are not implemented. This is an
intentional controlled-manual-handoff boundary because the source requires
unapproved artifacts, installer descriptors, side-effect scopes, and rollback
contracts.

## Side Effects

None in Phase 105.

## Required Privileges

The original Ultimate source requires Administrator rights. The Phase 105
manual-handoff implementation does not perform privileged operations, so the
implemented metadata does not require Administrator for Analyze/Open/blocked
Apply/Default/Restore.

## Capabilities

- RequiresAdmin: false
- RequiresInternet: false
- CanReboot: false
- CanModifyRegistry: false
- CanModifyServices: false
- CanInstallSoftware: false
- CanDownload: false
- CanModifyDrivers: false
- CanModifySecurity: false
- CanDeleteFiles: false
- UsesTrustedInstaller: false
- UsesSafeMode: false
- SupportsDefault: false
- SupportsRestore: false
- NeedsExplicitConfirmation: true

## Risk Level

High. The source is a multi-application installer workflow with many external
artifacts and per-app side effects.

## Confirmation Requirements

Manual handoff and blocked Auto paths require explicit confirmation before the
result is recorded through the Action Plan surface.

## Default And Restore

Default is unavailable because the source does not define a safe global default
branch. Restore is unavailable because BoostLab has no captured package,
installer, file, registry, service, scheduled-task, shortcut, app
configuration, cleanup, or support state for this tool. Default is not Restore.

## Restart Behavior

No restart is requested or performed. Future Auto behavior must model possible
installer restart/session effects before approval.

## Test Requirements

- Verify source path and SHA-256.
- Verify Analyze is read-only.
- Verify Open/manual handoff opens no browser or external tool and downloads,
  runs, mutates, installs, uninstalls, repairs, or cleans up nothing.
- Verify Apply is blocked as `AutoBlockedUntilArtifactApproval`.
- Verify Default and Restore are unavailable and separate.
- Verify no artifact provenance or production allowlist entries are added.
- Verify source-ultimate, source mirror, and intake files are untouched.
- Verify deleted tools remain deleted.
