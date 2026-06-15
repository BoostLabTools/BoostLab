# Spectre / Meltdown Assistant Migration Record

* **Tool name:** Spectre / Meltdown Assistant
* **Stage:** Advanced
* **Source script path:** `source-ultimate/8 Advanced/1 Spectre  Meltdown Assistant.ps1`
* **Source checksum:** `3989B93BC4B3367B1ED0CF831C93DA6C2E87C556D945854FEE4ECA5D4C66AB50`
* **Risk level:** High
* **Required privileges:** Administrator
* **Yazan approval status:** Approved by Yazan for Phase 30

## Original Ultimate Behavior

The source presents two choices:

* `Spectre Meltdown: Disable`
* `Spectre Meltdown: Enable (Default)`

The Disable branch writes these exact DWORD values in this order:

```powershell
reg add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /t REG_DWORD /d "3" /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /t REG_DWORD /d "3" /f
```

The Enable (Default) branch deletes those exact values in the same order:

```powershell
reg delete "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /f
reg delete "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /f
```

The source does not modify BCD, services, drivers, processes, scheduled tasks, or boot configuration. It does not download or install anything and does not restart Windows.

## Approved BoostLab Behavior

BoostLab exposes:

* `Analyze`
* `Apply`
* `Default`

`Analyze` is the required assistant layer. It reads only the two source-defined values, classifies the current policy, and explains the security/performance tradeoff.

`Apply` maps to Ultimate `Disable`.

`Default` maps to Ultimate `Enable (Default)`.

## Preserved Behavior

BoostLab preserves:

* the exact `ControlSet001` registry path
* the exact two value names
* DWORD value `3`
* source command order
* value-only Default deletion
* Administrator requirement
* no reboot behavior

Default is idempotent. A source-defined value that is already absent is reported as already default and is not treated as an error.

## Intentional Deviations

BoostLab adds:

* read-only analysis
* explicit security warnings
* Action Plan confirmation
* structured command results
* independent verification for both values

These additions do not alter the operational effect of Apply or Default.

## Security Impact

`Apply` disables the source-targeted speculative-execution mitigations and reduces CPU vulnerability protection. It must never execute silently.

`Default` removes the source-defined overrides so Windows can use its approved default mitigation policy.

Verification confirms registry configuration only. It does not claim to measure the currently active kernel mitigation state.

## Capabilities

* `RequiresAdmin = true`
* `RequiresInternet = false`
* `CanReboot = false`
* `CanModifyRegistry = true`
* `CanModifyServices = false`
* `CanInstallSoftware = false`
* `CanDownload = false`
* `CanModifyDrivers = false`
* `CanModifySecurity = true`
* `CanDeleteFiles = false`
* `UsesTrustedInstaller = false`
* `UsesSafeMode = false`
* `SupportsDefault = true`
* `SupportsRestore = false`
* `NeedsExplicitConfirmation = true`

## Confirmation Requirements

`Analyze` is read-only.

`Apply` and `Default` require explicit Action Plan confirmation. Apply confirmation must state that vulnerability protection is reduced.

## Verification Strategy

After Apply:

* `FeatureSettingsOverrideMask` must exist with value `3`.
* `FeatureSettingsOverride` must exist with value `3`.

After Default:

* `FeatureSettingsOverrideMask` must be absent.
* `FeatureSettingsOverride` must be absent.

Each value receives an independent `Passed`, `Warning`, or `Failed` check.

## Test Requirements

Automated tests must be static or mocked only and must not modify real mitigation policy.

Validate:

* source checksum
* exact registry path, values, DWORD data, and order
* Analyze structured output
* Apply confirmation and mocked execution
* Default confirmation, mocked execution, and already-default behavior
* per-value verification
* absence of BCD, reboot, service, driver, download, installer, scheduled task, and TrustedInstaller behavior
* source-ultimate integrity
* permanent Loudness EQ deletion
