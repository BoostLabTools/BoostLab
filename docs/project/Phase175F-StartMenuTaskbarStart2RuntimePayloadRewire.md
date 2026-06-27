# Phase 175F - Start Menu Taskbar start2.bin Runtime Payload Rewire

Date: 2026-06-27
Baseline: `53e2c30 Rewire DIDS NIP to runtime payload`

## Purpose

Phase 175F rewires only the Start Menu Taskbar `start2.bin` payload to use the generated runtime payload artifact added in Phase 175D.

This phase does not rewire Timer Resolution or Defender Optimize payloads.

## Changed Behavior

Start Menu Taskbar now resolves `start2.bin` through `core/RuntimePayloads.psm1` before building the existing Clean operation catalog. The payload is raw-byte SHA-256 verified before its bytes are used for the existing `%SystemRoot%\Temp\start2.bin` write operation.

The payload path is:

`runtime-payloads/start-menu-taskbar/start2.bin`

The Start Menu Taskbar action names, operation order, scope, UI text, Default behavior, and final destination for `start2.bin` remain unchanged on the valid payload path.

## Manifest Status

`config/RuntimePayloadManifest.psd1` now marks `start-menu-taskbar-start2-bin` as `ReadyForExternalRuntime`.

`driver-install-debloat-settings-nvidia-profile` remains `ReadyForExternalRuntime`.

The other generated payload entries remain `InternalRuntimeStillUsesSource`:

- Timer Resolution C# service payload
- Defender Optimize Apply script
- Defender Optimize Default script

External runtime readiness remains blocked until the remaining payload/module dependencies are rewired.

## Internal Fallback

InternalDevelopment mode prefers the verified runtime payload. If that payload is missing or invalid, the module may fall back to the verified protected source certificate block when source folders are available.

Fallback is diagnostic and does not hide payload hash failure.

## External Mode

ExternalRuntime mode uses the verified runtime payload without requiring `source-ultimate/` or `source-extra/` for the `start2.bin` content.

If the `start2.bin` payload is missing or hash-invalid in ExternalRuntime mode, BoostLab returns a controlled blocker/failure and does not fall back to protected source text.

## Safety Boundary

This phase did not:

- modify `source-ultimate/`
- modify `source-extra/`
- modify `intake/`
- change active tool scope
- change Start Menu Taskbar operation order on the valid payload path
- change `start2.bin` bytes
- run real Apply actions
- mutate registry, services, tasks, drivers, packages, BitLocker, activation, installers, cleanup, or AppX state
- stage, commit, or push changes

## Validation

Validation covers runtime payload manifest readiness, raw-byte `start2.bin` equivalence, external valid/missing/invalid payload behavior, internal fallback behavior, Start Menu Taskbar exact parity, Start Menu Layout parity, source/package checksum policy, result severity policy, scaffolding, reverse GUI/runtime contracts, reached/action label parity, and the full static/mocked suite.
