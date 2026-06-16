# Write Cache Buffer Flushing Migration Record

## Tool

- Tool name: Write Cache Buffer Flushing
- Tool id: `write-cache-buffer-flushing`
- Stage: Windows
- Source script path: `source-ultimate/6 Windows/20 Write Cache Buffer Flushing.ps1`
- Source SHA-256: `67D8CA0FECBFD9FCE7D2C81CE1713F1B08E83B729DC8FEC7B8C2E33806F9AD5D`
- Yazan approval status: Phase 47 approved Apply-only re-attempt with unsafe Default refused.

## Original Ultimate Behavior

The approved Ultimate Apply path discovers `Device Parameters` keys recursively under:

- `HKLM:\SYSTEM\ControlSet001\Enum\SCSI`
- `HKLM:\SYSTEM\ControlSet001\Enum\NVME`

For each discovered `Device Parameters` key, it targets the child `Disk` key and writes:

- Value name: `CacheIsPowerProtected`
- Value type: `REG_DWORD`
- Value data: `1`

The original Ultimate Default path discovers `Disk` keys under the same SCSI and NVME roots and deletes each complete `Disk` key.

## Approved BoostLab Behavior

BoostLab preserves the Apply behavior by discovering the same SCSI and NVME registry targets and setting only `CacheIsPowerProtected` to `REG_DWORD 1`.

Because this is a Windows performance/storage optimization tool, it is supported only on Windows 11 under the current BoostLab product scope. Windows 10 hosts receive a clean `NotApplicable` result for Analyze and Apply before registry discovery, capture, or mutation. This is not treated as a runtime error because Windows 10 optimization branches are outside scope unless Yazan expands scope later.

Before any registry write, BoostLab captures the exact prior state of the target value using the Phase 36 registry state capture foundation:

- target path
- value name
- previous existence
- previous type
- previous data

Execution is blocked if capture fails for any discovered target.

## Preserved Commands And Targets

- Preserved roots: `HKLM:\SYSTEM\ControlSet001\Enum\SCSI`, `HKLM:\SYSTEM\ControlSet001\Enum\NVME`
- Preserved discovery concept: recursive `Device Parameters` discovery with `Disk` child targeting
- Preserved value: `CacheIsPowerProtected`
- Preserved value type/data: `REG_DWORD 1`

## Intentional Deviations

Default is not implemented because the Ultimate Default deletes complete storage `Disk` keys. That broad deletion can remove unrelated storage configuration and is outside the approved Phase 47 safety scope.

Restore is not exposed in this phase. BoostLab records pre-change value state, but there is not yet a reviewed user-facing restore-selection flow for this tool. A future Restore may restore only captured prior state for exact values changed by BoostLab.

The source warning referencing `NVME Faster Driver.ps1` is not acted on. `NVME Faster Driver` is permanently deleted and must not be reintroduced.

## Side Effects

- Writes only `CacheIsPowerProtected` on discovered source-targeted storage registry paths.
- Does not delete registry keys.
- Does not modify drivers.
- Does not modify services.
- Does not reboot.
- Does not download or install anything.

## Required Privileges

Administrator is required because the approved Apply behavior writes under `HKLM:\SYSTEM`.

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
- SupportsDefault: false
- SupportsRestore: false
- NeedsExplicitConfirmation: true

## Risk Level

High. The tool targets storage-related registry paths.

## Confirmation Requirements

Apply requires explicit Action Plan confirmation. Analyze is read-only.

## Rollback / Default Behavior

Default is unavailable because preserving the original Default would require broad `Disk` key deletion. Restore is unavailable until a tool-specific captured-state restore flow is reviewed and approved.

## Restart Behavior

No restart is performed.

## Verification Strategy

Apply verifies:

- target discovery completed
- pre-change capture records exist before mutation
- every changed value equals `REG_DWORD 1`
- no broad key deletion behavior is present in the BoostLab module

Analyze reports discovered targets and current value states without mutation.

## Test Requirements

- Static and mocked tests only.
- Tests must not touch real disk registry keys.
- Verify missing targets are reported as not applicable, not failure.
- Verify capture failure blocks writes.
- Verify Apply writes only `CacheIsPowerProtected = 1`.
- Verify Default is not exposed.
- Verify source-ultimate is untouched.
- Verify Loudness EQ and NVME Faster Driver remain deleted.
