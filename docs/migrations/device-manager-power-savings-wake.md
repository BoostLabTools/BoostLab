# Device Manager Power Savings & Wake Migration Record

* **Tool name:** Device Manager Power Savings & Wake
* **Stage:** Windows
* **Source script path:** `source-ultimate/6 Windows/18 Device Manager Power Savings & Wake.ps1`
* **Source checksum:** `FB543A5C6BD8F2FBEA5CD3069FD72DCDCCAB847D9E4753FD33BB0909843D209F`
* **Risk level:** Medium
* **Required privileges:** Administrator
* **Yazan approval status:** Approved by Yazan for Phase 26

## Original Ultimate Behavior

Ultimate offers two console choices:

* Recommended Off
* Default

Both branches recursively enumerate these four source-defined device classes:

```text
HKLM:\SYSTEM\ControlSet001\Enum\ACPI
HKLM:\SYSTEM\ControlSet001\Enum\HID
HKLM:\SYSTEM\ControlSet001\Enum\PCI
HKLM:\SYSTEM\ControlSet001\Enum\USB
```

Only subkeys named `Device Parameters` or `WDF` are targeted.

Apply writes:

* `EnhancedPowerManagementEnabled = 0` as `REG_DWORD`
* `SelectiveSuspendOn = 0` as `REG_DWORD`
* `IdleInWorkingState = 0` as `REG_DWORD` under `WDF`
* `WaitWakeEnabled = 0` as `REG_DWORD`
* `SeleactiveSuspendEnabled = 00` as `REG_BINARY` for ACPI
* `SelectiveSuspendEnabled = 00` as `REG_BINARY` for HID, PCI, and USB

Default removes source-defined value names without deleting any device key. The Ultimate source removes the misspelled `SeleactiveSuspendEnabled` name for all four classes. It therefore does not remove the correctly spelled `SelectiveSuspendEnabled` value that Apply writes for HID, PCI, and USB.

The source does not install, remove, update, disable, or uninstall devices or drivers. It does not use `pnputil`, `devcon`, DISM driver commands, services, downloads, installers, AppX, TrustedInstaller, Safe Mode, file deletion, security policy, or reboot behavior.

## Preserved BoostLab Behavior

Apply maps to Ultimate's recommended Off branch. Default maps to Ultimate's explicit Default branch.

BoostLab preserves:

* The four device class roots.
* Recursive matching of `Device Parameters` and `WDF`.
* Every registry value name, type, and data value.
* The source block order: class power values, class WDF value, then class wake values.
* The source's misspelled ACPI Apply value.
* The source's misspelled Default deletion for every class.

BoostLab does not run the source script. Console elevation and `Read-Host` are replaced by application-level Administrator enforcement, Action Plan confirmation, structured results, and read-only verification.

## Source-to-BoostLab Mapping

| Ultimate source | Class / target | Apply | Default | BoostLab mapping |
|---|---|---|---|---|
| Lines 23-31, 128-136 | ACPI `Device Parameters` | `EnhancedPowerManagementEnabled` DWORD `0`; `SeleactiveSuspendEnabled` binary `00`; `SelectiveSuspendOn` DWORD `0` | Delete the same three names | Exact |
| Lines 32-37, 137-142 | ACPI `WDF` | `IdleInWorkingState` DWORD `0` | Delete value | Exact |
| Lines 39-47, 144-152 | HID `Device Parameters` | `EnhancedPowerManagementEnabled` DWORD `0`; `SelectiveSuspendEnabled` binary `00`; `SelectiveSuspendOn` DWORD `0` | Delete `EnhancedPowerManagementEnabled`, misspelled `SeleactiveSuspendEnabled`, and `SelectiveSuspendOn` | Exact source asymmetry preserved |
| Lines 48-53, 153-158 | HID `WDF` | `IdleInWorkingState` DWORD `0` | Delete value | Exact |
| Lines 55-63, 160-168 | PCI `Device Parameters` | Same correctly spelled Apply values as HID | Same misspelled Default deletion as HID | Exact source asymmetry preserved |
| Lines 64-69, 169-174 | PCI `WDF` | `IdleInWorkingState` DWORD `0` | Delete value | Exact |
| Lines 71-79, 176-184 | USB `Device Parameters` | Same correctly spelled Apply values as HID | Same misspelled Default deletion as HID | Exact source asymmetry preserved |
| Lines 80-85, 185-190 | USB `WDF` | `IdleInWorkingState` DWORD `0` | Delete value | Exact |
| Lines 87-117, 192-222 | ACPI, HID, PCI, USB `Device Parameters` | `WaitWakeEnabled` DWORD `0` | Delete value | Exact |

Every BoostLab write or delete command maps to one of these source operations. No additional class, leaf name, registry value, driver command, device command, service, power-plan setting, or cleanup target was added.

## Action Mapping

* `Apply`: Ultimate recommended Device Manager Power Savings & Wake Off behavior.
* `Default`: Ultimate explicit Default value-removal behavior.

No `Open`, `Restore`, or invented inverse action is exposed.

## Capabilities

* `RequiresAdmin = true`
* `RequiresInternet = false`
* `CanReboot = false`
* `CanModifyRegistry = true`
* `CanModifyServices = false`
* `CanInstallSoftware = false`
* `CanDownload = false`
* `CanModifyDrivers = false`
* `CanModifySecurity = false`
* `CanDeleteFiles = false`
* `UsesTrustedInstaller = false`
* `UsesSafeMode = false`
* `SupportsDefault = true`
* `SupportsRestore = false`
* `NeedsExplicitConfirmation = true`

`CanModifyDrivers` is false because the tool changes device-instance registry values only. It does not install, remove, update, replace, disable, or uninstall a driver or device.

## Confirmation and Restart

Apply and Default require Action Plan confirmation. The plan identifies Administrator and registry requirements.

Neither action restarts Windows, disables a device, restarts a service, or refreshes a driver. A later device restart or Windows refresh may be needed before every device reflects the changed power policy, but BoostLab does not perform that action.

## Device Registry Safety Policy

The module uses a hard-coded allowlist:

* Classes: `ACPI`, `HID`, `PCI`, `USB`
* Leaf keys: `Device Parameters`, `WDF`
* Values: the five names present in Ultimate

Every discovered target must remain beneath:

```text
HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Enum\<approved-class>\
```

and must end in an approved leaf name. An out-of-scope target is rejected before command construction.

The module never deletes registry keys. Default uses only `reg delete ... /v <source-value>`, so unrelated values and device keys remain intact. Paths cannot come from config or user input.

## Verification and Reporting

After Apply or Default, BoostLab reads each source-targeted value:

* `Passed`: the detected value equals the source-defined Apply value, or a Default-targeted value is absent.
* `Warning`: an optional class/key is missing or inaccessible, or a value cannot be read.
* `Failed`: a readable value contradicts the requested source-defined state.

Structured results include command status, verification status, expected and detected summaries, targeted classes and registry paths, completed values, skipped items, warnings, and errors.

Missing optional classes are not fatal. Unexpected registry command failures remain errors.

## Intentional Deviations

Ultimate suppresses every `reg.exe` error. BoostLab reports command errors and verifies the resulting state.

Default is idempotent. A source-defined value already confirmed absent is skipped instead of invoking a failing delete command.

The source's selective-suspend spelling mismatch is not corrected. This preserves the approved source behavior, even though Default leaves the correctly spelled HID, PCI, and USB value outside its removal set.

## Test Requirements

Automated tests must use static inspection and injected mocks only. They must not modify the real registry or execute a real device action.

Tests must validate the source checksum, class/leaf/value allowlists, source operation order, Apply and Default command mapping, spelling asymmetry, idempotent Default, Passed/Warning/Failed verification, Action Plan confirmation, structured results, runtime mapping, capability metadata, migration record, source integrity, Loudness EQ deletion, protected module hashes, and implemented/placeholder counts.
