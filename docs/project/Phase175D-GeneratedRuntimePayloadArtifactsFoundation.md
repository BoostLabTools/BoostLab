# Phase 175D - Generated Runtime Payload Artifacts Foundation

Date: 2026-06-27
Baseline: `152d99f Add runtime source intent manifest foundation`

## Purpose

Phase 175D adds the first generated runtime payload artifact boundary for a future clean external BoostLab package. It keeps protected source folders as the internal development authority while recording generated payload files that can be verified without executing legacy source scripts.

This phase does not complete packaging, remove source folders, change runtime behavior, or wire modules to the new payload files.

## Added Foundation

- `config/RuntimePayloadManifest.psd1` records generated runtime payload artifacts, source-intent links, hashes, lengths, and wiring status.
- `core/RuntimePayloads.psm1` loads the manifest, resolves payload entries, verifies generated payload hashes, and reports external-readiness blockers.
- `runtime-payloads/` contains generated payload artifacts extracted by deterministic static source reads.
- `tests/Test-RuntimePayloadManifest.ps1` validates manifest schema, payload hashes, source-extraction parity, readiness reporting, and scope guards.

## Generated Payload Artifacts

Five generated payload files now cover the four high-risk blockers from Phase 175C:

- Timer Resolution Assistant C# service payload: `runtime-payloads/timer-resolution-assistant/SetTimerResolutionService.cs`
- Defender Optimize Assistant Apply script: `runtime-payloads/defender-optimize-assistant/defenderoptimize.ps1`
- Defender Optimize Assistant Default script: `runtime-payloads/defender-optimize-assistant/defenderdefault.ps1`
- Driver Install Debloat & Settings NVIDIA Profile Inspector profile: `runtime-payloads/driver-install-debloat-settings/inspector.nip`
- Start Menu Taskbar binary payload: `runtime-payloads/start-menu-taskbar/start2.bin`

All payloads are marked `GeneratedRuntimePayloadAvailable`, and all remain `InternalRuntimeStillUsesSource` because runtime modules have not been rewired yet.

## Safety Boundary

Payload extraction was limited to static file reads from approved protected source paths. No protected source script was executed. No BoostLab Apply/runtime action was run. No registry, service, task, driver, package, BitLocker, activation, installer, cleanup, or AppX mutation was performed.

The generated payload manifest is not customer-visible and does not embed payload bodies, certificates, here-strings, or source text. Text payloads use canonical text hashes so checkout line endings do not break validation.

## Not Changed

This phase did not:

- modify `source-ultimate/`
- modify `source-extra/`
- modify `intake/`
- remove internal source parity validation
- change tool behavior, order, scope, UI copy, or action strength
- wire modules to `runtime-payloads/`
- run runtime Apply actions
- stage, commit, or push changes

## Future Work

Next phases can teach the source-backed modules to prefer verified runtime payload artifacts in external runtime mode while preserving strict internal source validation for development mode. The external runtime package should remain blocked until those modules no longer need protected source reads at runtime.
