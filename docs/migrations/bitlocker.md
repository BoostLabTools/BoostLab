# BitLocker Migration Record

## Tool

- Tool name: BitLocker
- Tool id: `bitlocker`
- Stage: Setup
- Source script path: `source-ultimate/_intake-promoted/Ultimate/3 Setup/1 BitLocker.ps1`
- Source SHA-256: `1678E97FB5AFF851F1491A2D96C82A5716B1FA07CB4E3A4A5E0F3FB1B086FBA1`
- Yazan approval status: Phase 115 Yazan-approved source-equivalent BitLocker Off and On/status behavior with explicit GUI confirmation and test-safe execution seams.

## Original Ultimate Behavior

The source script exposes a console menu with:

- `BitLocker: Off (Recommended)`: reads all BitLocker volumes, selects volumes where protection is on or the volume is not fully decrypted, runs `Disable-BitLocker -MountPoint <mount> -ErrorAction SilentlyContinue`, opens BitLocker Drive Encryption Control Panel, then runs `manage-bde -status`.
- `BitLocker: On`: opens BitLocker Drive Encryption Control Panel and runs `manage-bde -status`.

The source includes administrator self-elevation and console-only menu, pause, clear-screen, and exit behavior.

## Approved BoostLab Behavior

BoostLab implements BitLocker as a security-sensitive source-equivalent controlled assistant:

- `Analyze`: read-only source/hash validation and sanitized BitLocker volume-state reporting.
- `Open`: source-equivalent On/status behavior; opens BitLocker Drive Encryption Control Panel and runs `manage-bde -status` after explicit confirmation. It does not enable BitLocker automatically.
- `Apply`: source-equivalent Off behavior; reads BitLocker volumes, filters the same source-matched volumes, invokes `Disable-BitLocker -MountPoint <mount> -ErrorAction SilentlyContinue` only for those target MountPoints, opens BitLocker Drive Encryption Control Panel, then runs `manage-bde -status`.
- `Default`: unavailable because the source On branch is UI/status-only and does not define a BoostLab default mutation.
- `Restore`: unavailable without selected captured BitLocker state and an approved restore contract.

## Preserved Intent

BoostLab preserves the source intent by implementing the exact practical Off and On/status branches behind explicit GUI confirmation and structured results. Because disabling BitLocker can affect encryption, recovery keys, protectors, and support posture, the module warns clearly, reports target MountPoints and command outcomes, and never collects, displays, stores, adds, removes, suspends, or resumes recovery keys or protectors.

## Commands Preserved As Source Reference

- `Get-BitLockerVolume`
- `Disable-BitLocker -MountPoint <mount> -ErrorAction SilentlyContinue`
- `Start-Process control.exe -ArgumentList "/name microsoft.bitlockerdriveencryption"`
- `manage-bde -status`

Phase 115 implements `Disable-BitLocker`, Control Panel launch, and `manage-bde -status` in runtime only after explicit confirmation. Automated validators use mocks and never execute these commands.

## Intentional Deviations

- Console menu interaction is replaced by GUI actions.
- Console-only behavior such as `Clear-Host`, `Pause`, `Write-Host`, and `Exit` is replaced by structured result/log output.
- Source console menu choices are mapped to BoostLab canonical actions: `Apply` is Off, and `Open` is On/status.
- Explicit GUI confirmation replaces console input.
- Test-safe executor seams let validators verify command routing without disabling BitLocker, running `manage-bde`, launching Control Panel, or mutating encryption state.
- `Default` and `Restore` return blocked structured results rather than inventing behavior not present in the source.

## Side Effects

- `Analyze`: no system-changing side effects; may query BitLocker volume state read-only.
- `Open`: opens BitLocker Control Panel and runs `manage-bde -status`; no automatic BitLocker enable or protector/recovery-key mutation.
- `Apply`: may disable BitLocker or start decryption on source-matched target volumes, then opens BitLocker Control Panel and runs `manage-bde -status`.
- `Default`, `Restore`: no system-changing side effects; fail closed.

## Required Privileges

BitLocker declares `RequiresAdmin = true` because the approved source assumes administrator execution and future mutation would require elevated runtime control. Read-only analysis remains non-mutating.

## Capabilities

- RequiresAdmin: true
- RequiresInternet: false
- CanReboot: false
- CanModifyRegistry: false
- CanModifyServices: false
- CanInstallSoftware: false
- CanDownload: false
- CanModifyDrivers: false
- CanModifySecurity: true
- CanDeleteFiles: false
- UsesTrustedInstaller: false
- UsesSafeMode: false
- SupportsDefault: false
- SupportsRestore: false
- NeedsExplicitConfirmation: true

## Risk Level

High. BitLocker mutation affects encryption and recovery-key workflows.

## Confirmation Requirements

All non-analysis actions require explicit confirmation through the Action Plan framework. Confirmation for `Apply` permits the source-equivalent Off branch. Confirmation for `Open` permits the source-equivalent On/status branch.

## Rollback / Default Behavior

`Default` is not implemented because the source On branch is UI/status-only. Default is not Restore. `Restore` is not implemented because BoostLab has no captured BitLocker state, protector inventory, recovery-key policy, or approved restore flow.

## Restart Behavior

No restart behavior is implemented or approved.

## Test Requirements

- Validate source checksum.
- Validate BitLocker catalog metadata and runtime registration.
- Validate `Analyze` returns structured read-only volume state with no recovery-key values.
- Validate `Open` builds and routes the source-equivalent On/status branch through mocks only.
- Validate `Apply` builds and routes the source-equivalent Off branch through mocks only.
- Validate `Default` and `Restore` fail closed with explicit blockers.
- Validate validators never execute real BitLocker mutation commands, `manage-bde`, or Control Panel launch.
- Validate source mirror and legacy source are untouched.
