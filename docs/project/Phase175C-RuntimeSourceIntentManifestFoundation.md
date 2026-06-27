# Phase 175C - Runtime Source Intent Manifest Foundation

Date: 2026-06-27
Baseline: `55536fd Add external runtime package decoupling plan`

## Purpose

Phase 175C adds the first source-intent boundary for a future clean external BoostLab runtime package. It introduces a metadata-only manifest and read-only helper functions that can distinguish the current internal development mode from a requested external runtime mode.

This phase does not complete packaging, remove source folders, change runtime behavior, or decouple existing modules.

## Added Foundation

- `config/RuntimeSourceIntentManifest.psd1` records current runtime source dependencies without embedding protected source bodies or generated payload content.
- `core/RuntimeSourceIntent.psm1` loads the manifest, resolves source-intent entries, reports package mode, and returns structured external-readiness blockers.
- `tests/Test-RuntimeSourceIntentManifest.ps1` validates manifest schema, mode behavior, blocker reporting, source hash portability, and scope guards.

## Modes

Internal development mode remains the default. It keeps `source-ultimate/`, `source-extra/`, and `intake/` present and preserves existing raw/canonical source validation.

External runtime mode can be requested explicitly for tests or future package work. It does not claim readiness yet. It reports controlled blockers while source-backed modules still depend on protected source paths or generated payload extraction.

## Current State

The manifest contains 20 runtime source-intent entries, covering the known live dependencies from Phase 175B. All entries remain externally blocked until future decoupling work is implemented.

Four high-risk generated payload blockers are recorded:

- Timer Resolution Assistant C# service payload
- Defender Optimize Assistant generated script descriptors
- Driver Install Debloat & Settings NVIDIA profile payload
- Start Menu Taskbar `start2.bin`

## Not Changed

This phase did not:

- modify `source-ultimate/`
- modify `source-extra/`
- modify `intake/`
- remove internal source parity validation
- change tool behavior, order, scope, or UI copy
- run runtime Apply actions
- generate or ship runtime payload artifacts

## Future Work

Next phases can generate manifest entries from protected sources, add signed or hashed runtime payload artifacts, split public runtime config from internal provenance config, and teach source-backed modules to use external-mode manifest/payload records while preserving strict internal validation.
