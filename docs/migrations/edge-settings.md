# Edge Settings Migration Record

## Tool

- Tool name: Edge Settings
- Tool id: `edge-settings`
- Stage: Setup
- Module: `modules/Setup/edge-settings.psm1`

## Source

- Source script path: `source-ultimate/3 Setup/6 Edge Settings.ps1`
- Source SHA-256:
  `342869157930ECF0869A07B4254CB8F174C63648CD329DB3914BAD291CD5FF28`

## Original Ultimate Behavior Summary

The Ultimate source requires Administrator rights and internet connectivity,
then offers two menu branches:

- `Edge Settings: Optimize (Recommended)`
- `Edge Settings: Default`

The Optimize branch writes the uBlock Origin force-install Edge policy, writes
three Edge policy values, removes Active Setup entries matching Edge, removes
RunOnce values matching `msedge`, stops and deletes services whose names match
`Edge`, unregisters scheduled tasks whose task names match `*Edge*`, and deletes
the two source-defined IE-to-Edge Browser Helper Object registry keys.

The Default branch deletes the complete Edge policy key, stops Edge, launches
`msedge.exe --restore-last-session --disable-extensions`, stops Edge again,
downloads the source-defined `edge.exe` to Windows Temp, and starts that
downloaded executable.

## Approved BoostLab Behavior

Phase 118 implements the source-equivalent Edge Settings workflow as a
near-parity controlled tool:

- `Analyze`: read-only source/checksum/status analysis.
- `Apply`: source-equivalent Optimize branch after source verification,
  Administrator/internet preflight, explicit confirmation, and pre-change
  capture where practical.
- `Default`: source-equivalent Default branch after source verification,
  Administrator/internet preflight, explicit confirmation, and Edge policy key
  capture before deletion.
- `Restore`: blocked as `RestoreUnavailable` because no approved selected
  captured-state Restore contract exists.

## Preserved Commands And Targets

BoostLab represents the source-defined targets and command families:

- `HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist`
- uBlock force-install value:
  `odfafepnkmbhccpbejgmiehpchacaeak;https://edge.microsoft.com/extensionwebstorebase/v1/crx`
- `HardwareAccelerationModeEnabled=REG_DWORD 0`
- `BackgroundModeEnabled=REG_DWORD 0`
- `StartupBoostEnabled=REG_DWORD 0`
- Active Setup child keys whose default value matches `*Edge*`
- RunOnce values whose names match `*msedge*`
- services whose names match `Edge`
- scheduled tasks whose task names match `*Edge*`
- the two source-defined IE-to-Edge BHO keys
- `Stop-Process -Name "msedge"`
- `Start-Process "msedge.exe" -ArgumentList "--restore-last-session --disable-extensions"`
- `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe`
- `$env:SystemRoot\Temp\edge.exe`

## Intentional Deviations

BoostLab adds GUI confirmation, structured results, Action Plan visibility, and
mockable execution seams. These mechanics do not remove the practical Ultimate
behavior. They allow validators to prove the source-equivalent command routing
without executing real registry, service, scheduled task, process, download, or
installer side effects.

BoostLab does not expose Restore as a real mutation path. Default remains the
source-defined Default branch and is not treated as captured-state Restore.

## Side Effects

When confirmed by the user in production, `Apply` can mutate Edge policy,
Active Setup, RunOnce, services, scheduled tasks, and BHO registry state.
`Default` can delete the Edge policy key, stop/start Edge, download
source-defined `edge.exe`, and start the downloaded executable.

Automated tests use injected mocks only and do not execute those side effects.

## Required Privileges

Administrator rights and internet connectivity are required for confirmed
Apply/Default, matching the Ultimate source preflight expectations.

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
- SupportsDefault: true
- SupportsRestore: false
- NeedsExplicitConfirmation: true

## Risk Level

High. The source changes policy, Active Setup, RunOnce, services, scheduled
tasks, BHO registry state, process state, download behavior, and installer
launch behavior.

## Confirmation Requirements

Confirmed Apply and Default require explicit Action Plan confirmation. The plan
lists the source-defined operation families, Administrator/internet
requirements, download/install capability, and the lack of reboot behavior.

## Default And Restore

Default is implemented as the source-defined Default branch. Restore is
unavailable because BoostLab has no approved selected captured-state Restore
contract covering Edge policy, Active Setup, RunOnce, service, scheduled-task,
BHO, process, download, installer, file, or support state.

Restore is unavailable for Edge Settings until a future approved captured-state
Restore contract exists.

## Restart Behavior

No restart is requested or performed.

## Test Requirements

- Verify source path and SHA-256.
- Verify Analyze is read-only.
- Verify Apply represents every source-defined Optimize operation family using
  mocks only.
- Verify Default represents the source-defined policy deletion, Edge
  stop/start/stop, download, and `edge.exe` start sequence using mocks only.
- Verify Restore remains unavailable and does not imply mutation.
- Verify no artifact provenance or production allowlist entries are added.
- Verify source-ultimate, source mirror, and intake files are untouched.
- Verify deleted tools remain deleted.

## Yazan Approval Status

Approved in Phase 118 as source-equivalent, confirmation-gated near parity.
Yazan accepted the safer BoostLab mechanics because they preserve the practical
Ultimate result while adding GUI confirmation and test-safe validation seams.
