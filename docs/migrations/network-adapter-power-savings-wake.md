# Network Adapter Power Savings & Wake Migration Record

* **Tool name:** Network Adapter Power Savings & Wake
* **Stage:** Windows
* **Source script path:** `source-ultimate/6 Windows/19 Network Adapter Power Savings & Wake.ps1`
* **Source checksum:** `1DAAC872ECB1C601FD165FD471BFA9B9137D895333FBFBC5ADE5427561D4BCEB`
* **Risk level:** Medium
* **Required privileges:** Administrator
* **Yazan approval status:** Approved by Yazan for Phase 23

## Original Ultimate Behavior

Ultimate enumerates numeric adapter keys under:

```text
HKLM:\System\ControlSet001\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}
```

Its recommended Off branch writes `PnPCapabilities = 24` as `REG_DWORD` and writes these power-saving and wake values as `REG_SZ = 0` on every detected adapter key:

```text
AdvancedEEE
*EEE
EEELinkAdvertisement
SipsEnabled
ULPMode
GigaLite
EnableGreenEthernet
PowerSavingMode
S5WakeOnLan
*WakeOnMagicPacket
*ModernStandbyWoLMagicPacket
*WakeOnPattern
WakeOnLink
```

The source repeats the `*ModernStandbyWoLMagicPacket` command at the end. Its Default branch removes the same values in the same order and repeats that final removal.

The source does not install, remove, replace, or update drivers; disable adapters; uninstall devices; reset TCP/IP or Winsock; change firewall, Defender, services, or security policy; download or install content; use TrustedInstaller or Safe Mode; delete files; or reboot.

## Preserved BoostLab Behavior

Apply maps to Ultimate's recommended Off branch. Default maps to Ultimate's explicit Default branch.

BoostLab preserves the source adapter class path, numeric-key filtering, value names, registry types, data, and execution order. The repeated Modern Standby operation remains represented in the operation sequence. Apply and Default use hard-coded source-defined registry commands; config and user input cannot provide arbitrary paths or commands.

BoostLab does not run the Ultimate script. It replaces self-elevation and the console menu with application-level Administrator enforcement, Action Plan confirmation, structured logging, and post-action verification.

## Preserved Commands and Values

For each detected numeric adapter key, Apply performs:

```text
reg add "<adapter-key>" /v "PnPCapabilities" /t REG_DWORD /d "24" /f
reg add "<adapter-key>" /v "<source-value>" /t REG_SZ /d "0" /f
```

Default performs:

```text
reg delete "<adapter-key>" /v "<source-value>" /f
```

Only the 14 unique source-defined values listed above are managed.

## Source-to-BoostLab Mapping Audit

The source line numbers below refer to `source-ultimate/6 Windows/19 Network Adapter Power Savings & Wake.ps1`. `New-BoostLabNetworkAdapterRegistryOperations` is the only function that builds write commands. `Test-BoostLabNetworkAdapterPowerWakeState` supplies the corresponding read-only verification checks.

| Ultimate source | Ultimate registry value | Apply value | Ultimate Default | BoostLab implementation | Verification check | Mapping |
|---|---|---|---|---|---|---|
| Lines 24-28 and 75-79 | Adapter keys under `HKLM:\System\ControlSet001\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\####` | Enumerate numeric keys | Enumerate the same numeric keys | `Get-BoostLabNetworkAdapterReadOnlyDiscovery`; `Get-BoostLabNetworkAdapterInventory` | `Network adapter enumeration` and `Adapter enumeration access \| <path>` | Preserved target rule; intentionally uses read-only `.NET RegistryKey` discovery instead of the provider |
| Lines 31 and 82 | `PnPCapabilities` | `REG_DWORD 24` | Delete value | `BoostLabAdapterValueDefinitions`; `New-BoostLabNetworkAdapterRegistryOperations` | `<adapter> \| <path>\PnPCapabilities` | Exact |
| Lines 34 and 85 | `AdvancedEEE` | `REG_SZ 0` | Delete value | Same functions | `<adapter> \| <path>\AdvancedEEE` | Exact |
| Lines 37 and 88 | `*EEE` | `REG_SZ 0` | Delete value | Same functions | `<adapter> \| <path>\*EEE` | Exact |
| Lines 38 and 89 | `EEELinkAdvertisement` | `REG_SZ 0` | Delete value | Same functions | `<adapter> \| <path>\EEELinkAdvertisement` | Exact |
| Lines 41 and 92 | `SipsEnabled` | `REG_SZ 0` | Delete value | Same functions | `<adapter> \| <path>\SipsEnabled` | Exact |
| Lines 44 and 95 | `ULPMode` | `REG_SZ 0` | Delete value | Same functions | `<adapter> \| <path>\ULPMode` | Exact |
| Lines 47 and 98 | `GigaLite` | `REG_SZ 0` | Delete value | Same functions | `<adapter> \| <path>\GigaLite` | Exact |
| Lines 50 and 101 | `EnableGreenEthernet` | `REG_SZ 0` | Delete value | Same functions | `<adapter> \| <path>\EnableGreenEthernet` | Exact |
| Lines 53 and 104 | `PowerSavingMode` | `REG_SZ 0` | Delete value | Same functions | `<adapter> \| <path>\PowerSavingMode` | Exact |
| Lines 56 and 107 | `S5WakeOnLan` | `REG_SZ 0` | Delete value | Same functions | `<adapter> \| <path>\S5WakeOnLan` | Exact |
| Lines 57 and 108 | `*WakeOnMagicPacket` | `REG_SZ 0` | Delete value | Same functions | `<adapter> \| <path>\*WakeOnMagicPacket` | Exact |
| Lines 58/61 and 109/112 | `*ModernStandbyWoLMagicPacket` | `REG_SZ 0`, repeated in source order | Delete value, repeated in source order | Same functions; both operation entries preserved | `<adapter> \| <path>\*ModernStandbyWoLMagicPacket` | Exact operation order; one unique verification check |
| Lines 59 and 110 | `*WakeOnPattern` | `REG_SZ 0` | Delete value | Same functions | `<adapter> \| <path>\*WakeOnPattern` | Exact |
| Lines 60 and 111 | `WakeOnLink` | `REG_SZ 0` | Delete value | Same functions | `<adapter> \| <path>\WakeOnLink` | Exact |

The mapping contains every `reg add` and `reg delete` value from the Ultimate source. The module has no other registry write definitions. Default removes only the values represented by Apply.

The only intentional deviations are interface and safety handling:

* Registry discovery and verification use read-only `.NET RegistryKey` handles rather than the PowerShell registry provider.
* A protected numeric adapter key is skipped and reported as `Warning`; accessible source-approved adapter keys continue.
* Default skips a source-defined delete when the value is already confirmed absent.
* Command failures and post-action verification are reported instead of suppressed.

No additional adapter property, DNS, TCP/IP, firewall, service, driver installation, or network-stack behavior is introduced.

## Intentional Deviations

The source suppresses every registry command error. BoostLab checks command results and reports failures.

Default is idempotent: a value that is already absent is treated as the expected default state and its delete command is skipped. This also prevents the source's repeated Modern Standby deletion from producing a false failure after the first deletion succeeds. The effective Ultimate result and operation ordering remain preserved.

The source does not report adapter names or unsupported properties. BoostLab reads `DriverDesc` through a read-only registry handle when available, reports each targeted adapter, and treats an absent or unreadable value after Apply as `Warning` because some adapter drivers do not expose or retain every vendor-specific property.

The original provider enumeration can fail when a protected numeric class key denies the provider's access request. BoostLab opens the class key and every candidate subkey with `OpenSubKey(..., $false)`. It never requests write access for discovery or verification. A denied subkey is recorded with its path and error, skipped as a write target, and does not prevent accessible adapters from being processed.

## Capabilities

`RequiresAdmin = true`; `CanModifyRegistry = true`; `CanModifyDrivers = true`; `SupportsDefault = true`; `NeedsExplicitConfirmation = true`.

`CanModifyDrivers` records that the tool modifies network driver configuration values. It does not authorize driver installation, removal, replacement, or update.

Internet, reboot, service, installer, download, security, file deletion, TrustedInstaller, Safe Mode, and Restore capabilities are false.

## Confirmation and Restart

Apply and Default require Action Plan confirmation. The plan states that detected adapter class keys and only the source-defined values are affected.

Neither action disables an adapter, resets the network stack, changes services, or restarts Windows. Device Manager, adapter refresh, or sign-out may be needed before every visible driver UI state updates.

## Default Behavior

Default removes only the exact values written by Apply from each detected numeric adapter class key. It does not delete adapter keys or unrelated values.

An already-absent value is accepted as default. No inverse behavior had to be invented because Ultimate contains an explicit Default branch.

## Verification Strategy

After Apply or Default, BoostLab checks all 14 unique values on every detected adapter key.

* `Passed`: every detected value matches the requested state.
* `Warning`: no matching adapters were found, a value is unavailable or unsupported, a registry read failed, or a device refresh may be required.
* `Failed`: a detected value contradicts the requested state.

Apply expects `PnPCapabilities = 24` and every other value to equal string `0`. Default expects every managed value to be absent.

Command completion and verification status remain separate in the structured result.

## Test Requirements

Automated tests must use static inspection and injected mocks only. They must not modify the real registry, change real adapter properties, disable devices, install/remove/update drivers, reset the network stack, or execute the real Apply or Default paths.

Tests must validate the source checksum, exact class path, value names, types, data, repeated Modern Standby operation, execution order, explicit Default, metadata, capabilities, confirmation plans, Passed/Warning/Failed verification, structured results, runtime mapping, UI rendering, source-ultimate integrity, deleted-tool exclusion, protected-module hashes, and implemented/placeholder counts.
