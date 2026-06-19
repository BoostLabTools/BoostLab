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

Phase 110 upgrades Reinstall from controlled manual handoff to controlled
Windows 11 source-equivalent Apply:

- `Analyze`: verifies source identity and reports the source behavior, supported
  Windows 11 target scope, unsupported Windows 10 branch, and controlled Apply
  operation.
- `Open`: prepares in-app guidance only and performs no download, launch, setup,
  reboot, file, registry, service, package, device, or driver mutation.
- `Apply`: after explicit Action Plan confirmation, source checksum validation,
  Administrator validation, internet validation, and Windows Temp availability
  validation, downloads the source-defined Windows 11 Media Creation Tool to
  `%SystemRoot%\Temp\mediacreationtoolw11.exe` and launches it with
  `Start-Process`.
- `Default`: returns `DefaultUnavailable`; the source defines no safe Default
  branch.
- `Restore`: returns `RestoreUnavailable`; unavailable without captured
  reinstall/setup/generated-file/reboot/session/recovery state and an approved
  Restore contract.

## Preserved Commands

BoostLab preserves the supported Windows 11 branch commands:

```powershell
IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw11.exe" -OutFile "$env:SystemRoot\Temp\mediacreationtoolw11.exe"
Start-Process "$env:SystemRoot\Temp\mediacreationtoolw11.exe"
```

The source-defined Windows 10 branch remains documented but unsupported by
BoostLab product scope.

## Intentional Deviations

- Windows 10 Media Creation Tool branch is not exposed because Windows 10
  branches are outside BoostLab product scope unless they prepare a Windows 11
  outcome through an approved path.
- BoostLab adds explicit GUI Action Plan confirmation before the download and
  launch.
- BoostLab verifies source checksum, Administrator state, internet availability,
  and the source-defined Windows Temp output directory before executing Apply.
- BoostLab does not run `setup.exe` directly, pass installer switches, partition
  disks, format media, mutate registry/services/packages/devices/drivers, or
  reboot by itself.

## Side Effects

`Apply` downloads an executable to the source-defined Windows Temp path and
launches it. The Microsoft Media Creation Tool can continue into media creation,
refresh, reinstall, session changes, or reboot after the user proceeds inside
that tool.

`Analyze`, `Open`, `Default`, and `Restore` do not perform system-changing
operations.

## Capabilities

- RequiresAdmin: true
- RequiresInternet: true
- CanReboot: true
- CanModifyRegistry: false
- CanModifyServices: false
- CanInstallSoftware: true
- CanDownload: true
- CanModifyDrivers: false
- CanModifySecurity: false
- CanDeleteFiles: false
- UsesTrustedInstaller: false
- UsesSafeMode: false
- SupportsDefault: false
- SupportsRestore: false
- NeedsExplicitConfirmation: true

## Risk Level

High. The approved Windows 11 Apply path downloads and launches the
source-defined Media Creation Tool, and the Microsoft tool can continue into
media creation, refresh, reinstall, session changes, or reboot after user action
inside that tool.

## Confirmation Requirements

`Apply` requires explicit Action Plan confirmation before any download or launch.
`Open` prepares guidance only. `Default` and `Restore` return unavailable
results and perform no operation.

## Default And Restore

Default is unavailable because the source defines no safe Default branch.
Restore is unavailable until BoostLab has captured eligible reinstall/setup
state and an approved Restore contract. Default is not Restore.

## Restart Behavior

BoostLab does not call `shutdown`, `Restart-Computer`, `setup.exe`, or any reboot
command. The launched Microsoft Media Creation Tool may later request session
changes or reboot if the user continues inside it.

## Test Requirements

- Verify source path and SHA-256.
- Verify Analyze is read-only.
- Verify Open prepares guidance only and opens no external tool.
- Verify Apply is confirmation-gated and is not executed by automated tests.
- Verify Apply preserves the source-defined Windows 11 URL, output path, and
  `Start-Process` launch.
- Verify Windows 10 branch remains unsupported.
- Verify Default and Restore are unavailable.
- Verify no artifact provenance or production allowlist entry is added.
- Verify source paths remain untouched and deleted tools remain deleted.

## Yazan Approval Status

Phase 110 outcome: `DoneYazanAcceptedNearParity`.

Yazan accepts the controlled Windows 11 branch as near parity because the
practical Windows 11 Ultimate result remains available behind safer GUI
confirmation and validation. Windows 10 branch support remains outside product scope.
