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
branches. Phase 102 implements only the bounded live Driver Updates policy
branch:

- menu option `1. Block` under `DRIVER UPDATES`
- menu option `3. Unblock` under `DRIVER UPDATES`

The source also includes bootable-USB branches that generate
`setupcomplete.cmd` with embedded reboot commands, plus broad Windows Update
blocking branches with custom WSUS/update-server URL values. Those branches are
not implemented in Phase 102.

## Approved BoostLab Behavior

- `Analyze`: verifies source identity and reports current state for the nine
  supported live Driver Updates policy registry values.
- `Apply`: captures each supported value, then writes only the exact
  source-defined Driver Updates policy values.
- `Default`: captures each supported value, then removes only the exact
  source-defined Driver Updates policy values. Default is not Restore.
- `Restore`: requires a selected captured rollback record from this tool and
  restores only that exact captured registry value state.

## Preserved Commands

BoostLab preserves the effective result of the source `reg add` and `reg
delete` commands for the live Driver Updates policy branch using PowerShell
registry APIs and BoostLab state capture. The source script is not executed.

## Exact Supported Registry Values

- `HKLM:\Software\Policies\Microsoft\Windows\Device Metadata`
  - `PreventDeviceMetadataFromNetwork` = `REG_DWORD 1`
- `HKLM:\Software\Policies\Microsoft\Windows\DeviceInstall\Settings`
  - `DisableSendGenericDriverNotFoundToWER` = `REG_DWORD 1`
  - `DisableSendRequestAdditionalSoftwareToWER` = `REG_DWORD 1`
- `HKLM:\Software\Policies\Microsoft\Windows\DriverSearching`
  - `SearchOrderConfig` = `REG_DWORD 0`
- `HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate`
  - `SetAllowOptionalContent` = `REG_DWORD 0`
  - `AllowTemporaryEnterpriseFeatureControl` = `REG_DWORD 0`
  - `ExcludeWUDriversInQualityUpdate` = `REG_DWORD 1`
- `HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU`
  - `IncludeRecommendedUpdates` = `REG_DWORD 0`
  - `EnableFeaturedSoftware` = `REG_DWORD 0`

## Intentional Deviations

Phase 102 does not implement:

- Driver Updates Bootable USB generation
- Windows Updates Block
- Windows Updates Block Bootable USB generation
- Windows Updates Unblock
- custom WSUS/update-server URL writes
- `setupcomplete.cmd` creation or movement
- embedded reboot commands
- folder opening or external process launch

These branches remain blocked because they require generated-script/media,
custom URL, reboot/recovery, and broader policy approvals that are outside this
phase.

## Side Effects

Implemented `Apply` and `Default` modify only the exact registry values listed
above, after capture. No driver device mutation, driver installation/removal,
Windows Update execution, service change, download, installer, external
process, generated script, media write, or reboot behavior is added.

## Capabilities

- RequiresAdmin: true
- RequiresInternet: false
- CanReboot: false
- CanModifyRegistry: true
- CanModifyServices: false
- CanInstallSoftware: false
- CanDownload: false
- CanModifyDrivers: false
- CanModifySecurity: false
- CanDeleteFiles: false
- UsesTrustedInstaller: false
- UsesSafeMode: false
- SupportsDefault: true
- SupportsRestore: true
- NeedsExplicitConfirmation: true

## Risk Level

High. The supported branch is bounded, but it changes HKLM Windows policy values
that affect driver delivery through Windows Update.

## Confirmation Requirements

`Apply`, `Default`, and `Restore` require explicit confirmation. `Restore` also
requires a selected captured rollback record.

## Default And Restore

Default removes only the source-defined Driver Updates policy values. Restore
uses selected captured state and is not equivalent to Default.

## Restart Behavior

No restart or reboot is implemented.

## Test Requirements

- Verify source path and SHA-256.
- Verify Analyze is read-only.
- Verify Apply writes only the nine supported values after capture.
- Verify Default removes only the nine supported values after capture.
- Verify Restore requires selected captured state and restores exact captured
  value state.
- Verify unsupported source branches remain blocked.
- Verify no artifact provenance or production allowlist entry is added.
- Verify source paths remain untouched and deleted tools remain deleted.

## Yazan Approval Status

Approved for Phase 102 controlled live Driver Updates policy implementation
only. Bootable-media branches, broad Windows Update block/unblock branches,
custom update-server URL values, generated setup scripts, folder opening, and
reboot behavior remain unapproved.
