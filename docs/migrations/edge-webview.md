# Edge & WebView Migration Record

- Tool name: Edge & WebView
- Tool id: `edge-webview`
- Stage: Windows
- Module: `modules/Windows/edge-webview.psm1`
- Source script path: `source-ultimate/6 Windows/13 Edge & WebView.ps1`
- Source SHA-256: `3AB92D76307B1CB4C6988DB2201631C14D3B91B32CFFA4F1177B3E1F4F0D7966`
- Migration status: Exact Ultimate parity implemented
- Yazan approval status: Approved for Phase 147 exact source-equivalent Apply/Default behavior

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

BoostLab implements the two non-exit Ultimate source branches:

- `Apply`: source-equivalent `Edge & WebView: Uninstall (Recommended)`.
- `Default`: source-defined `Edge & WebView: Default` repair branch.

The runtime verifies the source checksum before mutation, requires explicit
Action Plan confirmation, and represents the source operation order as
test-safe operation descriptors so validators can mock every dangerous step.
No `Open` or `Restore` action is exposed because the Ultimate source does not
define those branches.

## Preserved Commands

The implementation preserves the source Apply/Uninstall branch operations:

- Administrator and internet checks.
- DeviceRegion capture, temporary `REG_DWORD 244` write through `reg1.exe`,
  and source-defined DeviceRegion restoration when a previous value exists.
- Exact source process stop list plus wildcard `*edge*` process handling.
- EdgeUpdate registry key removal.
- Discovered `MicrosoftEdgeUpdate.exe` `/unregsvc` and `/uninstall` runs.
- Edge SystemApps marker directory/file creation and removal.
- 32-bit Microsoft Edge uninstall string execution with `--force-uninstall`.
- EdgeWebView uninstall key deletion, Edge shortcut deletion,
  `%SystemDrive%\Program Files (x86)\Microsoft` directory deletion, Edge
  service stop/delete, and conditional legacy Edge CBS/DISM branch.

The implementation also preserves the source Default branch operations:

- Process stops before and after the source repair installers.
- Source `edge.exe` and `edgewebview.exe` downloads to `%SystemRoot%\Temp`.
- Source repair executable launches with wait.
- Edge policy writes, Active Setup cleanup, RunOnce cleanup, Edge service
  deletion, Edge scheduled task removal, and native/WOW6432Node BHO key
  deletion.

## Intentional Deviations

No `Open` action is added because the source does not define an Open branch.
No `Restore` action is added because the source does not define a captured-state
Restore contract. `Default` remains the source repair/default branch and is not
treated as Restore.

## Side Effects

High-risk source-equivalent side effects are possible only after explicit
confirmation: downloads, repair executable launches, process stops, registry
mutation, file/folder/shortcut deletion, service deletion, scheduled task
removal, conditional CBS/DISM package removal, and cleanup. Validators use
mocks/stubs and do not perform real host mutation.

## Required Privileges

The original Ultimate source requires Administrator rights. The Phase 147
runtime metadata requires Administrator for Apply and Default.

## Capabilities

- RequiresAdmin: true
- RequiresInternet: true
- CanReboot: false
- CanModifyRegistry: true
- CanModifyServices: true
- CanInstallSoftware: true
- CanDownload: true
- CanModifyDrivers: false
- CanModifySecurity: true
- CanDeleteFiles: true
- UsesTrustedInstaller: false
- UsesSafeMode: false
- SupportsDefault: true
- SupportsRestore: false
- NeedsExplicitConfirmation: true

## Risk Level

High. The source is a destructive Edge/WebView removal and repair workflow with
downloads, installers, process handling, service deletion, scheduled task
removal, file cleanup, registry mutation, and package behavior.

## Confirmation Requirements

Apply and Default require explicit confirmation through the Action Plan surface.

## Default And Restore

Default is available as the source repair/reinstall plus policy and cleanup
branch. Restore is unavailable because the Ultimate source does not define a
captured Edge/WebView package, installer, file, registry, service,
scheduled-task, process, cleanup, or support restore contract. Default is not
Restore.

## Restart Behavior

No restart is requested or performed. Future Auto behavior must model possible
installer restart/session effects before approval.

## Test Requirements

- Verify source path and SHA-256.
- Verify Apply preserves the source Uninstall (Recommended) operation order.
- Verify Default preserves the source repair/default operation order.
- Verify Open and Restore are not exposed as source actions.
- Verify no artifact provenance or production allowlist entries are added.
- Verify validators use mocks/stubs and perform no real host mutation.
- Verify source-ultimate, source mirror, and intake files are untouched.
- Verify deleted tools remain deleted.
