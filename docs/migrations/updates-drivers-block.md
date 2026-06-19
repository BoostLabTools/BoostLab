# Updates Drivers Block Migration Record

## Identity

- Tool name: Updates Drivers Block
- Tool id: `updates-drivers-block`
- Stage: Refresh
- Module: `modules/Refresh/updates-drivers-block.psm1`
- Source script path: `source-ultimate/2 Refresh/3 Updates Drivers Block.ps1`
- Source SHA-256: `4D4EC652C5A7F78824F53B7DC7FD46DDA948F3716A7CD6FD102D6C678EE11991`

## Original Ultimate Behavior

The Ultimate script requires Administrator rights and exposes six console menu
branches:

- Driver Updates `Block`
- Driver Updates `Block (Bootable USB)`
- Driver Updates `Unblock`
- broad Updates `Block`
- broad Updates `Block (Bootable USB)`
- broad Updates `Unblock`

The selected source branch for Phase 112 is menu option `2`, `Driver Updates
Block (Bootable USB)`. It creates `setupcomplete.cmd`, places it under
`<DriveLetter>:\sources\$OEM$\$$\Setup\Scripts\setupcomplete.cmd`, and the
generated script contains the nine Driver Updates policy `reg add` commands plus
`shutdown /r /t 0` for Windows Setup context.

## Yazan Final Scope Decision

Yazan selected this final scope for BoostLab:

- Driver Updates only
- Bootable USB option only
- no Unblock option
- no broad Updates Block option
- no broad Updates Block Bootable USB option
- no custom WSUS/update-server behavior
- no live local Driver Updates unblock/default option as final customer behavior

This is recorded as a controlled subset with a Yazan final exception, not full
Ultimate parity.

## Approved BoostLab Behavior

- `Analyze`: verifies source identity, reports the USB-only final scope,
  reports omitted branches, and performs no mutation.
- `Apply`: requires explicit confirmation and selected removable USB media,
  captures the existing target `setupcomplete.cmd` file state, writes only the
  source-equivalent Driver Updates Block USB script, verifies content, and
  records post-mutation state.
- `Default`: unavailable. It is not Unblock and does not delete live host
  registry values or USB files.
- `Restore`: requires a selected captured USB `setupcomplete.cmd` file rollback
  record from Apply and restores only that captured file state.

## Preserved Commands And Content

BoostLab preserves the source-equivalent generated `setupcomplete.cmd` content:

- `PreventDeviceMetadataFromNetwork = REG_DWORD 1`
- `DisableSendGenericDriverNotFoundToWER = REG_DWORD 1`
- `DisableSendRequestAdditionalSoftwareToWER = REG_DWORD 1`
- `SearchOrderConfig = REG_DWORD 0`
- `SetAllowOptionalContent = REG_DWORD 0`
- `AllowTemporaryEnterpriseFeatureControl = REG_DWORD 0`
- `ExcludeWUDriversInQualityUpdate = REG_DWORD 1`
- `IncludeRecommendedUpdates = REG_DWORD 0`
- `EnableFeaturedSoftware = REG_DWORD 0`
- `shutdown /r /t 0`

BoostLab writes the script to USB media only. It does not execute the script on
the host.

## Intentional Deviations

The source's temporary `%SystemRoot%\Temp\setupcomplete.cmd` staging and folder
opening are not preserved because Yazan's final scope requires no external tool
launch and BoostLab can write the selected USB destination directly after file
state capture.

The following source branches are intentionally not implemented:

- live local Driver Updates Block
- live local Driver Updates Unblock
- broad Windows Updates Block
- broad Windows Updates Block Bootable USB
- broad Windows Updates Unblock
- custom WSUS/update-server URL values

## Side Effects

Implemented `Apply` creates or overwrites only:

`<SelectedUsbRoot>\sources\$OEM$\$$\Setup\Scripts\setupcomplete.cmd`

No host registry mutation, host registry deletion, Windows Update execution,
driver/device mutation, service change, download, installer, external process,
source script execution, or BoostLab-triggered reboot is added.

## Capabilities

- RequiresAdmin: true
- RequiresInternet: false
- CanReboot: false
- CanModifyRegistry: false
- CanModifyServices: false
- CanInstallSoftware: false
- CanDownload: false
- CanModifyDrivers: false
- CanModifySecurity: false
- CanDeleteFiles: true
- UsesTrustedInstaller: false
- UsesSafeMode: false
- SupportsDefault: false
- SupportsRestore: true
- NeedsExplicitConfirmation: true

## Risk Level

High. BoostLab only writes a USB file, but the generated script changes Windows
driver-update policy and reboots when Windows Setup later executes it.

## Confirmation Requirements

`Apply` and `Restore` require explicit confirmation. `Apply` also requires a
selected removable USB target. `Restore` requires a selected captured USB file
rollback record.

## Default And Restore

Default is unavailable because Yazan rejected Unblock for the final tool scope.
Restore is selected captured USB file state only and is not Unblock.

## Restart Behavior

BoostLab does not reboot. The generated `setupcomplete.cmd` preserves the
source's `shutdown /r /t 0` line for Windows Setup context only.

## Test Requirements

- Verify source path and SHA-256.
- Verify Analyze is read-only and reports USB-only final scope.
- Verify Apply requires selected removable USB media.
- Verify Apply captures file state before writing.
- Verify generated `setupcomplete.cmd` path/content matches the selected source
  branch.
- Verify the generated script is not executed on the host.
- Verify Default is unavailable and does not delete host registry values.
- Verify Restore requires selected captured USB file state and is not Unblock.
- Verify broad Updates, custom update-server, live registry block/unblock,
  Windows Update execution, downloads, external processes, and reboot behavior
  remain unsupported.
- Verify no artifact provenance or production allowlist entry is added.
- Verify source paths remain untouched and deleted tools remain deleted.

## Yazan Approval Status

Phase 112 approved the USB-only final scope for Updates Drivers Block and marked
the omitted Ultimate branches as an explicit Yazan final exception.
