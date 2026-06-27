# Phase 175K - External Runtime Source Intent Descriptor Wiring

Date: 2026-06-28
Baseline: `48b09d5 Add generated operation descriptors foundation`

## Purpose

Phase 175K wires ExternalRuntime source-intent readiness to the generated operation descriptors added in Phase 175J.

This phase does not remove internal source folders, does not remove InternalDevelopment source parity checks, and does not change tool Apply behavior. It updates readiness metadata and read-only helper reporting so ExternalRuntime can distinguish payload-backed source evidence, descriptor-backed source evidence, and remaining package-launch blockers.

## Relationship To Phase 175J

Phase 175J created static operation descriptors for the 16 source-intent entries that were still blocked after runtime payload rewiring. Phase 175K makes those descriptors count as valid ExternalRuntime source-intent evidence when they exist and validate.

The descriptor helper still reports module-level wiring separately. Modules are not rewired in this phase.

## Payload Readiness

Runtime payload readiness remains unchanged:

- Total generated runtime payloads: 5
- Ready generated runtime payloads: 5
- Blocked generated runtime payloads: 0
- Runtime payload readiness: true

Payload-backed source-intent entries:

- `driver-install-debloat-settings.source`
- `start-menu-taskbar.source`
- `timer-resolution-assistant.source`
- `defender-optimize-assistant.source`

## Descriptor Readiness

Operation descriptor coverage remains:

- Total operation descriptors: 16
- Valid operation descriptors: 16
- Missing or invalid descriptors: 0
- Descriptor coverage readiness: true

Descriptor-backed source-intent entries:

- `reinstall.source`
- `updates-drivers-block.source`
- `bitlocker.source`
- `convert-home-to-pro.source`
- `edge-settings.source`
- `installers.source`
- `driver-clean.source`
- `nvidia-app-install.source`
- `directx.source`
- `visual-cpp.source`
- `bloatware.source`
- `copilot.source`
- `game-bar.source`
- `edge-webview.source`
- `control-panel-settings.source`
- `cleanup.source`

## Source-Intent Readiness

Before this phase:

- Total source-intent entries: 20
- Payload-backed ready entries: 4
- Descriptor-backed ready entries: 0
- Remaining source-intent blockers: 16
- ExternalRuntime source-intent readiness: false

After this phase:

- Total source-intent entries: 20
- Payload-backed ready entries: 4
- Descriptor-backed ready entries: 16
- Remaining source-intent blockers: 0
- ExternalRuntime source-intent readiness: true

ExternalRuntime readiness does not claim raw source verification. InternalDevelopment still records and validates the protected source references.

## Package Readiness Boundary

ExternalRuntime source-intent readiness is not the same as full source-free package build readiness.

The current working tree still has direct module/core source references. These are reported by `Get-BoostLabExternalPackageSourceReferenceScan` and keep package readiness false:

- `ExternalRuntimeReady`: true
- `ExternalPackageBuildReady`: false
- `ExternalPackageSourceFreeLaunchBlocked`: true

Current blocker classes:

- module source-relative path references
- module source checksum/status diagnostics
- core internal-development source-folder probes
- developer evidence text

Only the module references are treated as source-free package launch blockers. Core probes and diagnostics remain visible as internal-development or developer evidence.

## Helper Changes

`core/RuntimeSourceIntent.psm1` now reports:

- payload readiness totals
- operation descriptor readiness totals
- payload-backed source-intent readiness
- descriptor-backed source-intent readiness
- structured source-intent blockers for missing or invalid evidence
- raw source verification claim count for the requested mode
- package source-reference scan results

`Resolve-BoostLabRuntimeSourceIntent` now includes `SourceEvidenceMode`, `SourceEvidenceSatisfied`, `EvidenceRecords`, `EvidenceBlockers`, and `RawSourceVerificationClaimed`.

## Remaining Work

Recommended next phases:

1. Move direct module source status checks behind a central mode-aware helper.
2. Keep InternalDevelopment source parity strict while making ExternalRuntime use payload or descriptor evidence.
3. Add source-free package launch tests against a generated package root.
4. Decide whether descriptor-backed modules should report descriptor evidence in normal diagnostics.

## Safety Boundary

This phase did not:

- modify `source-ultimate/`
- modify `source-extra/`
- modify `intake/`
- delete or move protected source folders
- change tool module Apply behavior
- change operation order
- change active tool scope
- change UI visuals
- rewrite customer-facing copy
- run real Apply/runtime actions
- mutate registry, services, tasks, packages, AppX, drivers, BitLocker, activation, cleanup targets, installers, Timer, Defender, Start Menu layout, NVIDIA, or host state
- stage, commit, or push changes

## Validation

Validation covers source-intent metadata, operation descriptor coverage, runtime payload readiness, combined ExternalRuntime readiness, missing descriptor blockers, invalid descriptor blockers, missing payload blockers, source-free temp-root behavior, direct source-reference package blockers, InternalDevelopment source parity expectations, protected source cleanliness, and the full static/mocked suite.
