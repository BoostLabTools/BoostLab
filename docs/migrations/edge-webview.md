# Edge & WebView Migration Record

- Tool name: Edge & WebView
- Tool id: `edge-webview`
- Stage: Windows
- Module: `modules/Windows/edge-webview.psm1`
- Source script path: `source-ultimate/6 Windows/13 Edge & WebView.ps1`
- Source SHA-256: `161ED9C99D437E45650369CB7E15D5737DED363712E647138F134B049AC7E691`
- Migration status: Controlled manual handoff only
- Yazan approval status: Approved for Phase 106 manual handoff only

## Original Ultimate Behavior

The source is an Administrator-only menu with `Edge & WebView: Uninstall` and
`Edge & WebView: Default` branches. It requires internet connectivity.

The uninstall branch changes DeviceRegion, stops broad process targets,
removes EdgeUpdate registry state, runs Edge update/uninstall executables,
creates and removes an Edge system-app marker path, removes Edge WebView
uninstall registry state, deletes an Edge shortcut, deletes Microsoft Edge
folders, deletes Edge services, and may remove a Windows 10 legacy Edge package.

The Default branch stops broad process targets, downloads Edge and Edge WebView
repair installers from mutable mirror URLs, launches those repair installers,
then applies Edge policies and removes Edge Active Setup, RunOnce, services,
scheduled tasks, and Browser Helper Object state.

## Approved BoostLab Behavior

BoostLab implements only:

- `Analyze`: read-only source/checksum/status analysis.
- `Open`: controlled manual handoff instructions prepared inside BoostLab only.
- `Apply`: blocked with `AutoBlockedUntilArtifactApproval`.
- `Default`: blocked with `DefaultUnavailable`.
- `Restore`: blocked with `RestoreUnavailable`.

No downloads, repair, installer launches, package actions, process handling,
file changes, registry changes, service changes, scheduled-task changes,
cleanup, reboot, or system mutation are implemented.

## Preserved Commands

No operational source commands are executed in Phase 106. The source behavior is
preserved as documented operational intent and remains blocked for Auto until
all required artifact, package, process, service, task, file, registry, cleanup,
rollback, and support approvals exist.

## Intentional Deviations

Automated Edge/WebView removal, repair, download, installer launch, package
actions, process handling, service/task mutation, cleanup, Default, and Restore
behavior are not implemented. This is an intentional controlled-manual-handoff
boundary because the source requires unapproved artifacts, installer/repair
descriptors, side-effect scopes, and rollback contracts.

## Side Effects

None in Phase 106.

## Required Privileges

The original Ultimate source requires Administrator rights. The Phase 106
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

High. The source is a destructive Edge/WebView removal and repair workflow with
downloads, installers, process handling, service deletion, scheduled task
removal, file cleanup, registry mutation, and package behavior.

## Confirmation Requirements

Manual handoff and blocked Auto paths require explicit confirmation before the
result is recorded through the Action Plan surface.

## Default And Restore

Default is unavailable because the source Default branch is a repair/reinstall
plus policy and cleanup workflow that is not approved for automated execution.
Restore is unavailable because BoostLab has no captured Edge/WebView package,
installer, file, registry, service, scheduled-task, process, cleanup, or
support state for this tool. Default is not Restore.

## Restart Behavior

No restart is requested or performed. Future Auto behavior must model possible
installer restart/session effects before approval.

## Test Requirements

- Verify source path and SHA-256.
- Verify Analyze is read-only.
- Verify Open/manual handoff opens no browser or external tool and downloads,
  repairs, runs, mutates, installs, uninstalls, resets, removes, configures,
  stops processes, changes services/tasks, or cleans up nothing.
- Verify Apply is blocked as `AutoBlockedUntilArtifactApproval`.
- Verify Default and Restore are unavailable and separate.
- Verify no artifact provenance or production allowlist entries are added.
- Verify source-ultimate, source mirror, and intake files are untouched.
- Verify deleted tools remain deleted.
