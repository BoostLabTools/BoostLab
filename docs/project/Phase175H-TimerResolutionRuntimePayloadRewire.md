# Phase 175H - Timer Resolution Runtime Payload Rewire

Date: 2026-06-27
Baseline: `e870ebb Rewire Defender payloads to runtime artifacts`

## Purpose

Phase 175H rewires only the Timer Resolution Assistant generated C# service payload to use the generated runtime payload artifact added in Phase 175D.

This phase completes the high-risk generated runtime payload rewire set.

## Changed Behavior

Timer Resolution Assistant now resolves the generated C# service payload through `core/RuntimePayloads.psm1` before using it for the existing `C:\Windows\SetTimerResolutionService.cs` write step. The payload is hash-verified before its content is used by the existing mocked Apply workflow.

The payload path is:

`runtime-payloads/timer-resolution-assistant/SetTimerResolutionService.cs`

The Timer Resolution tool id, action labels, operation order, service names, compiler path and arguments, registry intent, Task Manager launch intent, Default behavior, and customer-facing UI text remain unchanged on the valid payload path.

## Manifest Status

`config/RuntimePayloadManifest.psd1` now marks `timer-resolution-csharp-service` as `ReadyForExternalRuntime`.

These entries remain `ReadyForExternalRuntime`:

- `driver-install-debloat-settings-nvidia-profile`
- `start-menu-taskbar-start2-bin`
- `defender-optimize-apply-script`
- `defender-optimize-default-script`

All high-risk generated runtime payload entries are now runtime-wired and hash-verified by the runtime payload manifest.

External package readiness can still remain blocked by source-intent records outside the generated payload manifest. This phase does not rewrite the runtime source intent manifest or remove internal source validation records.

## Internal Fallback

InternalDevelopment mode prefers the verified runtime payload. If the Timer Resolution runtime payload is missing or invalid, the module may fall back to the verified protected source here-string when source folders are available.

Fallback is diagnostic and does not hide payload hash failure.

## External Mode

ExternalRuntime mode uses the verified runtime payload without requiring `source-ultimate/` or `source-extra/` for the Timer Resolution C# service content.

If the Timer payload is missing or hash-invalid in ExternalRuntime mode, BoostLab returns a controlled blocker/failure and does not fall back to protected source text.

## Safety Boundary

This phase did not:

- modify `source-ultimate/`
- modify `source-extra/`
- modify `intake/`
- change active tool scope
- change Timer Resolution payload content
- compile the Timer Resolution C# payload
- install, start, stop, delete, or modify any real service
- run Timer Resolution Apply or Default
- execute generated Timer payload code
- mutate registry, services, tasks, drivers, packages, BitLocker, activation, installers, cleanup, AppX, timer settings, boot config, or host system state
- stage, commit, or push changes

## Validation

Validation covers runtime payload manifest readiness, Timer Resolution C# payload source-equivalence, ExternalRuntime valid/missing/invalid payload behavior, InternalDevelopment fallback behavior, DIDS `.nip` readiness preservation, Start Menu Taskbar `start2.bin` readiness preservation, Defender Optimize Apply/Default readiness preservation, source intent manifest status, source checksum policy, result severity policy, tolerated outcome catalog, scaffolding, reverse GUI/runtime contract, reached/action label parity, and the full static/mocked suite.
