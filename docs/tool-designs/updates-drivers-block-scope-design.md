# Updates Drivers Block Scope Design

## Purpose

This Phase 57 document defines the future implementation scope for the
`Updates Drivers Block` tool. It is design-only.

No Updates Drivers Block behavior is implemented by this document. No runtime
behavior, module behavior, production registry scope, file scope, cleanup
scope, reboot scope, update-server scope, bootable-media scope, Default
behavior, or Restore behavior is approved here.

Updates Drivers Block remains a refused placeholder until a later approved
phase adds exact bounded production registry/file/reboot/media scopes,
generated-script ownership rules, update-policy verification, captured-state
rollback, and implementation.

## Source Reference

* Source path: `source-ultimate/2 Refresh/3 Updates Drivers Block.ps1`
* Source SHA-256: `4D4EC652C5A7F78824F53B7DC7FD46DDA948F3716A7CD6FD102D6C678EE11991`
* Current BoostLab module path:
  `modules/Refresh/updates-drivers-block.psm1`
* Current status: refused placeholder
* Current implemented actions: none

Relevant foundations:

* Phase 36: file and registry state capture and rollback
* Phase 38: destructive cleanup policy
* Phase 40: reboot and recovery workflow
* Phase 48: branch-level product scope

## Product Scope Decision

The source does not contain an explicit Windows 10-only branch or a separate
Windows 11 branch. It states `WINDOWS PRO/LTSC/IOT/SERVER ONLY` and exposes
shared Windows policy and bootable-media modes.

Under Phase 48 branch-level scope, the shared Windows behavior may be designed
for a future implementation only if it otherwise passes governance. Any future
explicit Windows 10-only optimization branch must remain unsupported, disabled,
visual-only, or NotApplicable unless Yazan expands scope later.

The bootable-media modes may be considered separately from live host policy
mutation because they generate `setupcomplete.cmd` content for installation
media. They still require exact media validation, file ownership, generated
script verification, and reboot/recovery policy before implementation.

## Source Behavior Summary

The Ultimate source:

1. self-elevates as Administrator
2. prints `WINDOWS PRO/LTSC/IOT/SERVER ONLY`
3. exposes six menu options:
   * `1. Block` under `DRIVER UPDATES`
   * `2. Block (Bootable USB)` under `DRIVER UPDATES`
   * `3. Unblock` under `DRIVER UPDATES`
   * `4. Block` under `UPDATES`
   * `5. Block (Bootable USB)` under `UPDATES`
   * `6. Unblock` under `UPDATES`
4. for live driver-update blocking, writes nine HKLM policy values
5. for bootable-USB driver-update blocking, writes a generated
   `setupcomplete.cmd` containing those nine registry writes plus
   `shutdown /r /t 0`, moves it into the selected media path, and opens that
   folder
6. for live driver-update unblocking, deletes the nine driver/update-related
   policy values
7. for live Windows Update blocking, writes eight HKLM policy values including
   three custom WSUS/update-server URL values pointing at
   `https://fuckyoumicrosoft.com/`
8. for bootable-USB Windows Update blocking, writes a generated
   `setupcomplete.cmd` containing those eight registry writes plus
   `shutdown /r /t 0`, moves it into the selected media path, and opens that
   folder
9. for live Windows Update unblocking, deletes the eight Windows Update policy
   values

The source contains no service control command such as `Stop-Service`,
`Set-Service`, or `sc.exe`. It does not download external artifacts.

## Current Decision

Do not implement Analyze, Apply, Default, Restore, or any bootable-media action
yet.

The source combines live HKLM Windows Update policy mutation, live driver
delivery policy mutation, custom update-server URL values, generated installation
media scripts, immediate reboot commands embedded inside those generated
scripts, user-selected removable-media paths, and policy deletion. These
behaviors require exact registry/file/reboot/media scopes and high-risk
confirmation before BoostLab can preserve the Ultimate behavior safely.

## Behavior Groups

### 1. Windows Update Policy Registry Behavior

* Exact source targets:
  * `HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate`
    * `DoNotConnectToWindowsUpdateInternetLocations` = `REG_DWORD 1`
    * `UpdateServiceUrlAlternate` = `REG_SZ https://fuckyoumicrosoft.com/`
    * `WUStatusServer` = `REG_SZ https://fuckyoumicrosoft.com/`
    * `WUServer` = `REG_SZ https://fuckyoumicrosoft.com/`
    * `SetDisableUXWUAccess` = `REG_DWORD 1`
    * `ExcludeWUDriversInQualityUpdate` = `REG_DWORD 1`
  * `HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU`
    * `NoAutoUpdate` = `REG_DWORD 1`
    * `UseWUServer` = `REG_DWORD 1`
* Target type:
  * HKLM policy registry values.
* Intended mutation type:
  * Live Updates Block writes the values above.
  * Live Updates Unblock deletes the same values.
* Required foundation:
  * Phase 36 registry state capture and rollback.
* Required future production allowlist:
  * Exact tool/action/key/value/type/data scope for every value.
  * Explicit update-server URL approval if preserving the source URL values.
* Required inventory/capture before mutation:
  * Existing value existence, type, and data before every write or delete.
* Required confirmation level:
  * High-risk explicit confirmation because this can block Windows Update,
    redirect update policy, affect security update delivery, and override
    enterprise policy state.
* Required verification:
  * Apply verifies every value exists with the source-defined type/data.
  * Unblock/default-like behavior verifies value absence or reports exact
    deletion failure.
* Rollback/restore feasibility:
  * Restore is unavailable until exact captured prior policy values can be
    restored and verified.
* Risk level:
  * High
* Later implementation decision:
  * Can be reconsidered only with exact registry and update-server scopes.

### 2. Driver Update Blocking Registry Behavior

* Exact source targets:
  * `HKLM\Software\Policies\Microsoft\Windows\Device Metadata`
    * `PreventDeviceMetadataFromNetwork` = `REG_DWORD 1`
  * `HKLM\Software\Policies\Microsoft\Windows\DeviceInstall\Settings`
    * `DisableSendGenericDriverNotFoundToWER` = `REG_DWORD 1`
    * `DisableSendRequestAdditionalSoftwareToWER` = `REG_DWORD 1`
  * `HKLM\Software\Policies\Microsoft\Windows\DriverSearching`
    * `SearchOrderConfig` = `REG_DWORD 0`
  * `HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate`
    * `SetAllowOptionalContent` = `REG_DWORD 0`
    * `AllowTemporaryEnterpriseFeatureControl` = `REG_DWORD 0`
    * `ExcludeWUDriversInQualityUpdate` = `REG_DWORD 1`
  * `HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU`
    * `IncludeRecommendedUpdates` = `REG_DWORD 0`
    * `EnableFeaturedSoftware` = `REG_DWORD 0`
* Target type:
  * HKLM driver-delivery and Windows Update policy registry values.
* Intended mutation type:
  * Live Driver Updates Block writes the values above.
  * Live Driver Updates Unblock deletes the same values.
* Required foundation:
  * Phase 36 registry state capture and rollback.
* Required future production allowlist:
  * Exact tool/action/key/value/type/data scope for every value.
* Required inventory/capture before mutation:
  * Existing value existence, type, and data before every write or delete.
* Required confirmation level:
  * High-risk explicit confirmation because this can alter driver delivery and
    optional Windows Update behavior.
* Required verification:
  * Apply verifies every value exists with the source-defined type/data.
  * Unblock/default-like behavior verifies value absence or reports exact
    deletion failure.
* Rollback/restore feasibility:
  * Restore is unavailable until exact captured prior policy values can be
    restored and verified.
* Risk level:
  * High
* Later implementation decision:
  * Can be reconsidered only with exact bounded registry scopes.

### 3. Custom Update Server / WSUS URL Behavior

* Exact source targets:
  * `UpdateServiceUrlAlternate` = `https://fuckyoumicrosoft.com/`
  * `WUStatusServer` = `https://fuckyoumicrosoft.com/`
  * `WUServer` = `https://fuckyoumicrosoft.com/`
  * `UseWUServer` = `REG_DWORD 1`
  * `DoNotConnectToWindowsUpdateInternetLocations` = `REG_DWORD 1`
* Target type:
  * Windows Update policy registry values and custom update-server URL data.
* Intended mutation type:
  * Redirect or disable ordinary Windows Update behavior through policy.
* Required foundation:
  * Phase 36 registry capture and rollback.
* Required future production allowlist:
  * Exact URL value approval.
  * Exact warning text explaining the impact of custom WSUS/update-server
    values.
* Required inventory/capture before mutation:
  * Existing WSUS/update-server values and `UseWUServer` state.
* Required confirmation level:
  * High-risk explicit confirmation. The UI must warn that Windows Update,
    driver delivery, Microsoft update connectivity, and security updates may be
    affected.
* Required verification:
  * Verify written URL values and `UseWUServer`.
  * Verify deletion/restoration behavior if future Default/Restore is approved.
* Rollback/restore feasibility:
  * Restore requires exact prior policy values; deleting them is not equivalent
    to restoring enterprise policy.
* Risk level:
  * High
* Later implementation decision:
  * Must remain refused until update-server URL scope is explicitly approved.

### 4. Windows Update Service-Related Behavior If Present

* Exact source logic:
  * No service stop/start/configuration command is present.
  * No `Stop-Service`, `Set-Service`, `New-Service`, `sc.exe`, or service
    deletion behavior appears in the source.
* Target type:
  * Not applicable in the current source.
* Intended mutation type:
  * Not applicable.
* Required foundation:
  * Service state capture is not required for the current source behavior.
* Required future production allowlist:
  * None for Phase 57.
  * If a future source revision adds service changes, they require exact
    service scopes.
* Required inventory/capture before mutation:
  * Not applicable unless service behavior is added later.
* Required confirmation level:
  * Not applicable.
* Required verification:
  * Future tests should continue proving this design does not approve service
    mutation.
* Rollback/restore feasibility:
  * Not applicable.
* Risk level:
  * None for current source, high if service behavior is added later.
* Later implementation decision:
  * Must remain refused if implementation attempts to invent service behavior.

### 5. Six-Mode Menu/Option Behavior

* Exact source modes:
  * Mode 1: `Blocked: Driver Updates`
  * Mode 2: `Blocked: Driver Updates (Bootable USB)`
  * Mode 3: `Unblocked: Driver Updates`
  * Mode 4: `Blocked: Updates`
  * Mode 5: `Blocked: Updates (Bootable USB)`
  * Mode 6: `Unblocked: Updates`
* Target type:
  * Console menu and action mapping.
* Intended mutation type:
  * Convert `Read-Host` menu choices into future GUI actions only after exact
    behavior scopes are approved.
* Required foundation:
  * Action Plan and confirmation framework.
  * Phase 36, Phase 38, and Phase 40 depending on mode.
* Required future production allowlist:
  * Exact action names and exact mode-to-action mapping.
* Required inventory/capture before mutation:
  * Live registry modes require registry capture.
  * Bootable-media modes require generated file ownership and media target
    validation.
* Required confirmation level:
  * High-risk explicit confirmation for every mutating mode.
* Required verification:
  * Every mode must report source-defined target state, skipped unsupported
    branch, or refusal.
* Rollback/restore feasibility:
  * Restore must be record-based and separate from Unblock.
* Risk level:
  * High
* Later implementation decision:
  * Must remain refused until action mapping is approved.

### 6. Bootable-Media Script Behavior

* Exact source targets:
  * Temporary generated file:
    `%SystemRoot%\Temp\setupcomplete.cmd`
  * User-entered destination:
    `<DriveLetter>:\sources\$OEM$\$$\Setup\Scripts`
  * Final destination:
    `<DriveLetter>:\sources\$OEM$\$$\Setup\Scripts\setupcomplete.cmd`
  * Open-folder command:
    `Start-Process "<DriveLetter>:\sources\$OEM$\$$\Setup\Scripts"`
* Target type:
  * Generated setup script and installation-media file path.
* Intended mutation type:
  * Write a generated `setupcomplete.cmd`, create the target media scripts
    directory, move the generated file to media, and open the folder.
* Required foundation:
  * Phase 36 file state capture and rollback.
  * Phase 38 cleanup/ownership policy for generated file cleanup or overwrite.
* Required future production allowlist:
  * Exact removable-media validation.
  * Exact setup scripts path.
  * Exact generated content hashes for driver-block and updates-block scripts.
  * Exact overwrite/backup policy for existing `setupcomplete.cmd`.
* Required inventory/capture before mutation:
  * Existing target file existence, hash, metadata, and backup if overwritten.
  * Generated temp file ownership.
* Required confirmation level:
  * High-risk explicit confirmation because generated setup scripts run during
    Windows setup and include reboot commands.
* Required verification:
  * Destination is valid removable or selected installation media.
  * Generated script content exactly matches approved source-preserved content.
  * Target file exists at the approved path after write/move.
* Rollback/restore feasibility:
  * Restore unavailable until exact file backup/restore and generated-file
    ownership are approved.
* Risk level:
  * High
* Later implementation decision:
  * Must remain refused until bootable-media scope and generated-script
    ownership are approved.

### 7. Temporary/Generated Script Behavior

* Exact source targets:
  * `%SystemRoot%\Temp\setupcomplete.cmd`
  * `Set-Content -Path "$env:SystemRoot\Temp\setupcomplete.cmd"`
  * `Move-Item -Path "$env:SystemRoot\Temp\setupcomplete.cmd" -Destination ... -Force`
* Target type:
  * Temporary generated command script.
* Intended mutation type:
  * Create and move script content into bootable media.
* Required foundation:
  * Phase 36 file state capture and rollback.
  * Phase 38 cleanup policy.
* Required future production allowlist:
  * Exact temp file path.
  * Exact generated content hashes.
  * Exact move destination.
  * Exact overwrite behavior.
* Required inventory/capture before mutation:
  * Prior temp file and destination file state.
* Required confirmation level:
  * High-risk explicit confirmation.
* Required verification:
  * Temp file content matches approved hash before move.
  * Destination file content matches approved hash after move.
* Rollback/restore feasibility:
  * Restore unavailable without captured prior destination state.
* Risk level:
  * High
* Later implementation decision:
  * Must remain refused until generated-script ownership is approved.

### 8. Immediate Reboot Commands

* Exact source targets:
  * `shutdown /r /t 0` inside the generated driver-block bootable-media
    `setupcomplete.cmd`
  * `shutdown /r /t 0` inside the generated updates-block bootable-media
    `setupcomplete.cmd`
* Target type:
  * Reboot command embedded in generated setup script.
* Intended mutation type:
  * Reboot immediately during setup completion on the future target machine.
* Required foundation:
  * Phase 40 reboot and recovery workflow.
* Required future production allowlist:
  * Exact generated-script reboot behavior and warning text.
  * Exact future workflow decision on whether reboot during setup is preserved.
* Required inventory/capture before mutation:
  * Generated script record and selected media record.
* Required confirmation level:
  * High-risk explicit confirmation. User must understand the generated media
    will reboot the target machine after applying setup-complete policy.
* Required verification:
  * Generated script includes or omits the reboot line exactly as approved.
* Rollback/restore feasibility:
  * Not a live Restore action. Removing or restoring the script requires file
    capture/backup.
* Risk level:
  * High
* Later implementation decision:
  * Must remain refused until bootable-media and reboot workflow scopes are
    approved.

### 9. Default/Restore Behavior

* Exact source behavior:
  * Driver Updates Unblock deletes the nine driver-update policy values.
  * Updates Unblock deletes the eight Windows Update policy values.
  * No captured-state Restore exists in the source.
* Target type:
  * Registry value deletion.
* Intended mutation type:
  * Delete source-defined policy values.
* Required foundation:
  * Phase 36 registry state capture and rollback.
* Required future production allowlist:
  * Exact decision whether source `Unblock` maps to future `Default`.
  * Separate exact Restore contract if prior values are captured.
* Required inventory/capture before mutation:
  * Existing values before deletion.
* Required confirmation level:
  * High-risk explicit confirmation because deleting policy values may remove
    enterprise or technician-defined policy state.
* Required verification:
  * Source-defined Unblock verifies absence of the selected values.
  * Restore verifies prior captured values are restored exactly.
* Rollback/restore feasibility:
  * Unblock is not Restore. Restore remains unavailable until captured-state
    selection and verification are approved.
* Risk level:
  * High
* Later implementation decision:
  * Current Default/Restore must remain unavailable.

### 10. Unsupported Broad Registry or Policy Targets

* Exact source behavior:
  * Source uses exact values, not whole-key deletion.
  * Future implementation must not broaden this into whole-key removal or
    unrelated Windows Update reset behavior.
* Target type:
  * Policy registry boundaries.
* Intended mutation type:
  * Exact value add/delete only.
* Required foundation:
  * Phase 36 registry rollback.
* Required future production allowlist:
  * Exact values only.
* Required inventory/capture before mutation:
  * Per-value state capture before every write/delete.
* Required confirmation level:
  * High-risk explicit confirmation.
* Required verification:
  * Verify only approved values changed.
* Rollback/restore feasibility:
  * Broad key deletion remains refused.
* Risk level:
  * High
* Later implementation decision:
  * Unknown, broad, wildcard, whole-key, or unrelated policy targets remain
    denied.

### 11. Unsupported Windows 10-Only Branches/Options If Present

* Exact source behavior:
  * No explicit Windows 10-only branch or option is present.
  * The source says `WINDOWS PRO/LTSC/IOT/SERVER ONLY`.
* Target type:
  * Product-scope classification.
* Intended mutation type:
  * Not applicable in current source.
* Required foundation:
  * Phase 48 branch-level product scope.
* Required future production allowlist:
  * None for Windows 10-only optimization behavior.
* Required inventory/capture before mutation:
  * Future implementation should detect unsupported editions or branches and
    report NotApplicable before mutation.
* Required confirmation level:
  * Not applicable for unsupported branches.
* Required verification:
  * Tests must prove no explicit Windows 10-only optimization branch is exposed
    if one appears later.
* Rollback/restore feasibility:
  * Not applicable.
* Risk level:
  * High if future implementation invents unsupported branch behavior.
* Later implementation decision:
  * Explicit Windows 10-only branches must remain refused unless Yazan expands
    scope.

## Exact Source Target Inventory

This list is inventory only, not approval.

### Live Driver-Update Policy Values

| Registry key | Value | Type | Apply data | Source unblock behavior |
|---|---|---|---|---|
| `HKLM\Software\Policies\Microsoft\Windows\Device Metadata` | `PreventDeviceMetadataFromNetwork` | `REG_DWORD` | `1` | delete value |
| `HKLM\Software\Policies\Microsoft\Windows\DeviceInstall\Settings` | `DisableSendGenericDriverNotFoundToWER` | `REG_DWORD` | `1` | delete value |
| `HKLM\Software\Policies\Microsoft\Windows\DeviceInstall\Settings` | `DisableSendRequestAdditionalSoftwareToWER` | `REG_DWORD` | `1` | delete value |
| `HKLM\Software\Policies\Microsoft\Windows\DriverSearching` | `SearchOrderConfig` | `REG_DWORD` | `0` | delete value |
| `HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate` | `SetAllowOptionalContent` | `REG_DWORD` | `0` | delete value |
| `HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate` | `AllowTemporaryEnterpriseFeatureControl` | `REG_DWORD` | `0` | delete value |
| `HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate` | `ExcludeWUDriversInQualityUpdate` | `REG_DWORD` | `1` | delete value |
| `HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU` | `IncludeRecommendedUpdates` | `REG_DWORD` | `0` | delete value |
| `HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU` | `EnableFeaturedSoftware` | `REG_DWORD` | `0` | delete value |

### Live Windows Update Policy Values

| Registry key | Value | Type | Apply data | Source unblock behavior |
|---|---|---|---|---|
| `HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate` | `DoNotConnectToWindowsUpdateInternetLocations` | `REG_DWORD` | `1` | delete value |
| `HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate` | `UpdateServiceUrlAlternate` | `REG_SZ` | `https://fuckyoumicrosoft.com/` | delete value |
| `HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate` | `WUStatusServer` | `REG_SZ` | `https://fuckyoumicrosoft.com/` | delete value |
| `HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate` | `WUServer` | `REG_SZ` | `https://fuckyoumicrosoft.com/` | delete value |
| `HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate` | `SetDisableUXWUAccess` | `REG_DWORD` | `1` | delete value |
| `HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate` | `ExcludeWUDriversInQualityUpdate` | `REG_DWORD` | `1` | delete value |
| `HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU` | `NoAutoUpdate` | `REG_DWORD` | `1` | delete value |
| `HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU` | `UseWUServer` | `REG_DWORD` | `1` | delete value |

### Bootable-Media Targets

* Temporary generated script:
  `%SystemRoot%\Temp\setupcomplete.cmd`
* Destination folder:
  `<DriveLetter>:\sources\$OEM$\$$\Setup\Scripts`
* Destination file:
  `<DriveLetter>:\sources\$OEM$\$$\Setup\Scripts\setupcomplete.cmd`
* Embedded reboot command:
  `shutdown /r /t 0`
* Confirmation folder launch:
  `Start-Process "<DriveLetter>:\sources\$OEM$\$$\Setup\Scripts"`

## Future Safe Apply Requirements

A future safe implementation would require all of the following:

1. A source-preserving Action Plan that separates live driver blocking, live
   update blocking, live unblocking, bootable-media generation, and generated
   reboot behavior.
2. Exact Phase 36 registry scopes for every key/value/type/data listed in this
   design.
3. Capture before every registry write/delete, including existing enterprise
   policy values.
4. Exact update-server URL approval if the Windows Update block source values
   are preserved.
5. Explicit high-risk confirmation explaining Windows Update, driver delivery,
   security update, and enterprise policy side effects.
6. Exact Phase 36 file scopes and Phase 38 cleanup/ownership rules for
   generated `setupcomplete.cmd`.
7. Exact removable-media validation and target-path allowlist for bootable USB
   modes.
8. Exact Phase 40 reboot warning and generated-script workflow record if
   preserving embedded `shutdown /r /t 0`.
9. Verification after every live registry action and after generated script
   creation/move.
10. Migration record approved by Yazan.

## Default and Restore Boundary

The source `Unblock` options delete source-defined policy values. They are not
the same thing as BoostLab Restore.

Current Default/Restore must remain unavailable. A future Default would need
the same registry capture and verification governance as Apply because deleting
policy values can remove intentional existing policy.

Deleting policy values can remove intentional existing policy.

Restore remains unavailable unless exact registry rollback, file rollback,
generated-script ownership, update policy verification, and captured-state
restore selection are approved. BoostLab must not infer prior Windows Update
or driver-delivery policy from the source's Unblock paths.

## Production Approval State

No production registry/file/cleanup/reboot/update-server/bootable-media scopes are approved by this document.

Updates Drivers Block remains a placeholder/refused tool.

The current placeholder module must remain non-executing. A future migration
phase must not implement a partial "safe-looking" subset if doing so would
weaken the source's effective Windows Update, driver-update, bootable-media, or
reboot behavior.
