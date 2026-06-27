# Phase 175E - DIDS NIP Runtime Payload Rewire

Date: 2026-06-27
Baseline: `d00aa2c Add runtime payload artifacts foundation`

## Purpose

Phase 175E rewires only the Driver Install Debloat & Settings NVIDIA Profile Inspector `.nip` payload to use the generated runtime payload artifact added in Phase 175D.

This phase does not rewire Timer Resolution, Defender Optimize, or Start Menu Taskbar payloads.

## Changed Behavior

Driver Install Debloat & Settings now resolves the NVIDIA Profile Inspector profile through `core/RuntimePayloads.psm1` before building the NVIDIA operation plan. The payload is hash-verified before its content is used for the existing `%SystemRoot%\Temp\inspector.nip` write operation.

The payload path is:

`runtime-payloads/driver-install-debloat-settings/inspector.nip`

The NVIDIA operation order and Profile Inspector import command remain unchanged on the valid payload path.

## Manifest Status

`config/RuntimePayloadManifest.psd1` now marks `driver-install-debloat-settings-nvidia-profile` as `ReadyForExternalRuntime`.

The other generated payload entries remain `InternalRuntimeStillUsesSource`:

- Timer Resolution C# service payload
- Defender Optimize Apply script
- Defender Optimize Default script
- Start Menu Taskbar `start2.bin`

External runtime readiness remains blocked until the remaining payload/module dependencies are rewired.

## Internal Fallback

InternalDevelopment mode prefers the verified runtime payload. If that payload is missing or invalid, the module may fall back to the verified protected source here-string when source folders are available.

Fallback is diagnostic and does not hide payload hash failure.

## External Mode

ExternalRuntime mode uses the verified runtime payload without requiring `source-ultimate/` for the `.nip` content.

If the `.nip` payload is missing or hash-invalid in ExternalRuntime mode, BoostLab returns a controlled blocker/failure and does not fall back to protected source text.

## Safety Boundary

This phase did not:

- modify `source-ultimate/`
- modify `source-extra/`
- modify `intake/`
- change active tool scope
- change NVIDIA driver/debloat operation order on the valid payload path
- change `.nip` content
- run NVIDIA Profile Inspector
- install drivers
- launch NVIDIA Control Panel in tests
- restart
- run real Apply actions
- stage, commit, or push changes

## Validation

Validation covers runtime payload manifest readiness, source-derived `.nip` equivalence, 31 Profile Inspector settings, important NVIDIA setting values, external valid/missing/invalid payload behavior, internal fallback behavior, graphics confirmation behavior, and the full static/mocked suite.
