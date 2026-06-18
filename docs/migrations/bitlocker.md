# BitLocker Migration Record

## Tool

- Tool name: BitLocker
- Tool id: `bitlocker`
- Stage: Setup
- Source script path: `source-ultimate/_intake-promoted/Ultimate/3 Setup/1 BitLocker.ps1`
- Source SHA-256: `1678E97FB5AFF851F1491A2D96C82A5716B1FA07CB4E3A4A5E0F3FB1B086FBA1`
- Yazan approval status: Approved for controlled security assistant intake only.

## Original Ultimate Behavior

The source script exposes a console menu with:

- `BitLocker: Off (Recommended)`: reads all BitLocker volumes, selects volumes where protection is on or the volume is not fully decrypted, runs `Disable-BitLocker -MountPoint <mount> -ErrorAction SilentlyContinue`, opens BitLocker Drive Encryption Control Panel, then runs `manage-bde -status`.
- `BitLocker: On`: opens BitLocker Drive Encryption Control Panel and runs `manage-bde -status`.

The source includes administrator self-elevation and console-only menu, pause, clear-screen, and exit behavior.

## Approved BoostLab Behavior

BoostLab implements BitLocker as a security-sensitive assistant:

- `Analyze`: read-only source/hash validation and sanitized BitLocker volume-state reporting.
- `Open`: manual handoff guidance only; no external process is opened.
- `Apply`: blocked because the source Off branch disables BitLocker on matched volumes.
- `Default`: unavailable because the source On branch is UI/status-only and does not define a BoostLab default mutation.
- `Restore`: unavailable without selected captured BitLocker state and an approved restore contract.

## Preserved Intent

BoostLab preserves the source intent by documenting the exact Off and On branches and by refusing to weaken the Off branch into a partial or softer mutation. Because disabling BitLocker can affect encryption, recovery keys, protectors, and support posture, BoostLab does not execute mutation until a recovery-key, volume-selection, encryption-state, protector-state, verification, support, and restore policy is approved.

## Commands Preserved As Source Reference

- `Get-BitLockerVolume`
- `Disable-BitLocker -MountPoint <mount> -ErrorAction SilentlyContinue`
- `Start-Process control.exe -ArgumentList "/name microsoft.bitlockerdriveencryption"`
- `manage-bde -status`

Only read-only BitLocker state collection is implemented. The mutation, Control Panel launch, and `manage-bde` status execution are not executed by BoostLab in this phase.

## Intentional Deviations

- Console menu interaction is replaced by GUI actions.
- Console-only behavior such as `Clear-Host`, `Pause`, `Write-Host`, and `Exit` is replaced by structured result/log output.
- Manual handoff does not open Control Panel automatically because this phase is explicitly controlled and non-mutating.
- `Apply`, `Default`, and `Restore` return blocked structured results rather than performing BitLocker state changes.

## Side Effects

- `Analyze`: no system-changing side effects; may query BitLocker volume state read-only.
- `Open`: no system-changing side effects; prepares manual handoff guidance only.
- `Apply`, `Default`, `Restore`: no system-changing side effects; fail closed.

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

All non-analysis actions require explicit confirmation through the Action Plan framework. Confirmation records only the controlled handoff or blocked result; it does not permit mutation.

## Rollback / Default Behavior

`Default` is not implemented because the source On branch is UI/status-only. Default is not Restore. `Restore` is not implemented because BoostLab has no captured BitLocker state, protector inventory, recovery-key policy, or approved restore flow.

## Restart Behavior

No restart behavior is implemented or approved.

## Test Requirements

- Validate source checksum.
- Validate BitLocker catalog metadata and runtime registration.
- Validate `Analyze` returns structured read-only volume state with no recovery-key values.
- Validate `Open` prepares manual handoff only and opens no external process.
- Validate `Apply`, `Default`, and `Restore` fail closed with explicit blockers.
- Validate no BitLocker mutation command is executed by the module.
- Validate source mirror and legacy source are untouched.
