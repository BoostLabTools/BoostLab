# Write Cache Buffer Flushing Migration Record

## Tool

- Tool name: Write Cache Buffer Flushing
- Tool id: `write-cache-buffer-flushing`
- Stage: Windows
- Source script path: `source-ultimate/6 Windows/20 Write Cache Buffer Flushing.ps1`
- Source SHA-256: `67D8CA0FECBFD9FCE7D2C81CE1713F1B08E83B729DC8FEC7B8C2E33806F9AD5D`
- Yazan approval status: Phase 152 approved exact Ultimate parity with Apply and Default implemented.

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

BoostLab preserves the Default behavior by discovering source-targeted `Disk` keys recursively under the same SCSI and NVME roots and deleting each complete `Disk` key after confirmation and pre-mutation key-state capture.

The Ultimate source has no explicit Windows 10-only branch or option. Under the clarified branch-level product scope, BoostLab preserves this shared Windows behavior instead of blocking Windows 10 hosts merely because Windows 11 is the preferred supported product target. If a future source contains an explicit Windows 10-only optimization branch, that branch remains unsupported unless Yazan expands scope.

Before any registry write or source-defined key deletion, BoostLab captures the exact prior state of the target using the Phase 36 registry state capture foundation:

- target path
- value name
- previous existence
- previous type
- previous data
- key values when Default captures a complete `Disk` key

Execution is blocked if capture fails for any discovered target.

## Preserved Commands And Targets

- Preserved roots: `HKLM:\SYSTEM\ControlSet001\Enum\SCSI`, `HKLM:\SYSTEM\ControlSet001\Enum\NVME`
- Preserved discovery concept: recursive `Device Parameters` discovery with `Disk` child targeting
- Preserved value: `CacheIsPowerProtected`
- Preserved value type/data: `REG_DWORD 1`
- Preserved Default discovery concept: recursive `Disk` key discovery under the same SCSI and NVME roots
- Preserved Default operation: delete each complete discovered `Disk` registry key

## Intentional Deviations

Restore is not exposed in this phase. BoostLab records pre-change value state, but there is not yet a reviewed user-facing restore-selection flow for this tool. A future Restore may restore only captured prior state for exact values changed by BoostLab.

The source warning referencing `NVME Faster Driver.ps1` is not acted on. `NVME Faster Driver` is permanently deleted and must not be reintroduced.

## Side Effects

- Apply writes only `CacheIsPowerProtected` on discovered source-targeted storage registry paths.
- Default deletes complete source-discovered storage `Disk` registry keys.
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
- SupportsDefault: true
- SupportsRestore: false
- NeedsExplicitConfirmation: true

## Risk Level

High. The tool targets storage-related registry paths.

## Confirmation Requirements

Apply and Default require explicit Action Plan confirmation. Analyze is read-only.

## Rollback / Default Behavior

Default is the source-defined deletion of discovered SCSI/NVME `Disk` registry keys. Restore is unavailable until a tool-specific captured-state restore flow is reviewed and approved.

## Restart Behavior

No restart is performed.

## Verification Strategy

Apply verifies:

- target discovery completed
- pre-change capture records exist before mutation
- every changed value equals `REG_DWORD 1`

Default verifies:

- target discovery completed
- pre-change key capture records exist before mutation
- every source-discovered `Disk` key is absent after deletion

Analyze reports discovered targets and current value states without mutation.

## Test Requirements

- Static and mocked tests only.
- Tests must not touch real disk registry keys.
- Verify missing targets are reported as not applicable, not failure.
- Verify capture failure blocks writes.
- Verify Apply writes only `CacheIsPowerProtected = 1`.
- Verify Default deletes only source-discovered SCSI/NVME `Disk` keys through mocks.
- Verify source-ultimate is untouched.
- Verify Loudness EQ and NVME Faster Driver remain deleted.
