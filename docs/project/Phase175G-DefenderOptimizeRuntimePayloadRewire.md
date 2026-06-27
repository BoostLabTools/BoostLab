# Phase 175G - Defender Optimize Runtime Payload Rewire

Date: 2026-06-27
Baseline: `e1d400c Rewire Start Menu payload to runtime artifact`

## Purpose

Phase 175G rewires only the Defender Optimize Assistant generated Apply and Default scripts to use the generated runtime payload artifacts added in Phase 175D.

This phase does not rewire Timer Resolution.

## Changed Behavior

Defender Optimize Assistant now resolves its generated script content through `core/RuntimePayloads.psm1` before staging the existing Apply or Default workflow. Each payload is hash-verified before the content is used for the existing `%SystemRoot%\Temp\defenderoptimize.ps1` or `%SystemRoot%\Temp\defenderdefault.ps1` write step.

The payload paths are:

`runtime-payloads/defender-optimize-assistant/defenderoptimize.ps1`

`runtime-payloads/defender-optimize-assistant/defenderdefault.ps1`

The tool id, action labels, staging order, RunOnce behavior, normal-boot command order, Safe Mode intent, TrustedInstaller intent, restart intent, and customer-facing UI text remain unchanged on the valid payload path.

## Manifest Status

`config/RuntimePayloadManifest.psd1` now marks these entries as `ReadyForExternalRuntime`:

- `defender-optimize-apply-script`
- `defender-optimize-default-script`

These entries remain `ReadyForExternalRuntime`:

- `driver-install-debloat-settings-nvidia-profile`
- `start-menu-taskbar-start2-bin`

`timer-resolution-csharp-service` remains `InternalRuntimeStillUsesSource`.

External runtime readiness remains blocked until the remaining Timer Resolution payload/module dependency is rewired, plus any separate non-payload source-intent blockers recorded by the runtime source intent manifest.

## Internal Fallback

InternalDevelopment mode prefers the verified runtime payload. If the Defender Apply or Default runtime payload is missing or invalid, the module may fall back to the verified protected source here-string when source folders are available.

Fallback is diagnostic and does not hide payload hash failure.

## External Mode

ExternalRuntime mode uses the verified runtime payload without requiring `source-ultimate/` or `source-extra/` for Defender Apply or Defender Default generated script content.

If either Defender payload is missing or hash-invalid in ExternalRuntime mode, BoostLab returns a controlled blocker/failure and does not fall back to protected source text.

## Safety Boundary

This phase did not:

- modify `source-ultimate/`
- modify `source-extra/`
- modify `intake/`
- change active tool scope
- change Defender Optimize Apply or Default payload content
- execute generated Defender scripts
- run Defender Optimize Apply
- run Defender Optimize Default
- run Defender commands such as `Set-MpPreference`, `Add-MpPreference`, `Remove-MpPreference`, service changes, scheduled-task changes, registry changes, PowerShell security changes, or Windows Security mutation
- mutate registry, services, tasks, drivers, packages, BitLocker, activation, installers, cleanup, AppX, Defender, or host system state
- stage, commit, or push changes

## Validation

Validation covers runtime payload manifest readiness, Defender Apply/Default payload equivalence, important Defender source-intent command text, ExternalRuntime valid/missing/invalid payload behavior, InternalDevelopment fallback behavior, DIDS and Start Menu Taskbar readiness preservation, Timer Resolution blocked status preservation, source checksum policy, result severity policy, tolerated outcome catalog, scaffolding, reverse GUI/runtime contract, reached/action label parity, and the full static/mocked suite.
