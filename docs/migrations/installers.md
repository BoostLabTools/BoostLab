# Installers Migration Record

- Tool name: Installers
- Tool id: `installers`
- Stage: Installers
- Module: `modules/Installers/installers.psm1`
- Source script path: `source-ultimate/4 Installers/1 Installers.ps1`
- Source SHA-256: `1065D64183457D4E7B28EA78DDE41525EC8F7C4A4BCA12D29B70D991141C0C67`
- Migration status: Controlled selected-app sequential queue with Yazan final app-list exception
- Yazan approval status: Approved for Phase 119 retained-app multi-select queue; Yazan excluded source menu entries 11, 12, 15, 16, 18, and 19

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

BoostLab implements:

- `Analyze`: read-only source/checksum/status analysis, full source menu mapping, Yazan-excluded app mapping, retained visible app catalog, retained app count, retained artifact count, and queue model reporting.
- `Open`: retained catalog and selection guidance prepared inside BoostLab only.
- `Apply`: selected retained app IDs are processed one app at a time in retained source order after explicit confirmation. Each selected retained app downloads only its source-defined artifact(s), runs only its source-defined installer/helper command and arguments, and performs only its source-defined post-install side effects.
- `Default`: blocked with `DefaultUnavailable`.
- `Restore`: blocked with `RestoreUnavailable`.

Removed Yazan-excluded source menu entries are not visible, selectable, downloadable, installable, or plannable:

- 11 Frame View
- 12 GOG launcher
- 15 Notepad ++
- 16 Nvidia App
- 18 Onboard Memory Manager
- 19 Pot Player

Google Chrome, OBS Studio, and Rockstar Games remain retained and selectable.

## Preserved Commands

For retained apps, BoostLab preserves the source-defined URLs, destination
paths, installer/helper commands, arguments, and post-install operation
families in a data-driven catalog. The queue is sequential and stops on the
first failed selected app by default, reporting completed, failed, and remaining
not-started apps.

## Intentional Deviations

Yazan intentionally removed six source menu entries from BoostLab's visible
Installers catalog. This is recorded as `YazanFinalException` rather than full
parity. Default and Restore remain unavailable because the source does not
define one safe global Default branch and BoostLab does not have a captured-state
restore contract for installed apps and side effects.

## Side Effects

Apply can perform source-defined selected-app side effects for retained apps
after explicit confirmation, including downloads, installer/helper execution,
app configuration writes, browser policy writes, shortcut changes, service/task
cleanup, startup-value cleanup, component uninstall calls, and file cleanup where
the retained source app defines those operations.

## Required Privileges

The original Ultimate source requires Administrator rights. BoostLab preserves
that requirement for the selected-app Apply path. Analyze and Open remain
read-only/no-mutation paths, but the tool metadata declares the full Apply
capability surface because the card exposes one implemented selected-app queue.

## Capabilities

- RequiresAdmin: true
- RequiresInternet: true
- CanReboot: false
- CanModifyRegistry: true
- CanModifyServices: true
- CanInstallSoftware: true
- CanDownload: true
- CanModifyDrivers: false
- CanModifySecurity: false
- CanDeleteFiles: true
- UsesTrustedInstaller: false
- UsesSafeMode: false
- SupportsDefault: false
- SupportsRestore: false
- NeedsExplicitConfirmation: true

## Risk Level

High. The source is a multi-application installer workflow with many external
artifacts and per-app side effects.

## Confirmation Requirements

Apply requires explicit Action Plan confirmation for the selected queue before
downloads, installer/helper execution, or source-defined side effects begin.

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
- Verify Open opens no browser or external tool and downloads, runs, mutates,
  installs, uninstalls, repairs, or cleans up nothing.
- Verify Apply accepts multiple retained selected app IDs.
- Verify selected retained apps are executed sequentially in source order.
- Verify failure stops the queue and reports completed, failed, and remaining apps.
- Verify removed Yazan-excluded apps are not visible or selectable.
- Verify retained apps include Google Chrome, OBS Studio, and Rockstar Games.
- Verify Default and Restore are unavailable and separate.
- Verify no artifact provenance or production allowlist entries are added.
- Verify source-ultimate, source mirror, and intake files are untouched.
- Verify deleted tools remain deleted.
