# Phase 175I - External Runtime Source Intent Readiness Audit

Date: 2026-06-28
Baseline: `7cd0571 Rewire Timer payload to runtime artifact`

## Purpose

Phase 175I audits the remaining runtime source-intent records after Phase 175H completed the generated runtime payload rewires.

This phase does not implement external packaging and does not decouple tool modules from their internal source parity checks. It updates only source-intent metadata/classification and documents the exact blockers that remain before a clean external BoostLab package can exclude `source-ultimate/` and `source-extra/`.

## Payload Readiness

`config/RuntimePayloadManifest.psd1` is externally ready for generated payload artifacts:

- Total generated payload entries: 5
- Runtime-wired generated payload entries: 5
- Runtime payload blockers: 0
- Runtime payload `ExternalRuntimeReady`: `True`

Ready generated payloads:

- `driver-install-debloat-settings-nvidia-profile`
- `start-menu-taskbar-start2-bin`
- `defender-optimize-apply-script`
- `defender-optimize-default-script`
- `timer-resolution-csharp-service`

## Source-Intent Readiness

`config/RuntimeSourceIntentManifest.psd1` now distinguishes payload readiness from remaining protected-source dependencies:

- Total source-intent entries: 20
- External-ready source-intent entries: 4
- Remaining blocked source-intent entries: 16
- Generated payload required blockers: 0
- Internal raw source parity records: 20
- Source-intent `ExternalRuntimeReady`: `False`

The four external-ready source-intent entries are `ManifestOnly` with `RuntimePayloadReady`, `DevelopmentOnlySourceParity`, and `ExternalRuntimeCanExcludeSource` treatments. They still keep internal source parity/provenance metadata.

## Payload-Solved Entries

| SourceIntentId | Tool | Runtime payloads | External treatment | Internal source use | Risk | Future phase |
| --- | --- | --- | --- | --- | --- | --- |
| `driver-install-debloat-settings.source` | Driver Install Debloat & Settings | `driver-install-debloat-settings-nvidia-profile` | `ManifestOnly`, `RuntimePayloadReady`, `ExternalRuntimeCanExcludeSource` | Source parity/provenance only; payload generation solved | High | Packaging validation and customer-copy cleanup |
| `start-menu-taskbar.source` | Start Menu Taskbar | `start-menu-taskbar-start2-bin` | `ManifestOnly`, `RuntimePayloadReady`, `ExternalRuntimeCanExcludeSource` | Source parity/provenance only; payload generation solved | High | Packaging validation and customer-copy cleanup |
| `defender-optimize-assistant.source` | Defender Optimize Assistant | `defender-optimize-apply-script`, `defender-optimize-default-script` | `ManifestOnly`, `RuntimePayloadReady`, `ExternalRuntimeCanExcludeSource` | Source parity/provenance only; payload generation solved | High | Packaging validation and customer-copy cleanup |
| `timer-resolution-assistant.source` | Timer Resolution Assistant | `timer-resolution-csharp-service` | `ManifestOnly`, `RuntimePayloadReady`, `ExternalRuntimeCanExcludeSource` | Source parity/provenance only; payload generation solved | High | Packaging validation and customer-copy cleanup |

These entries no longer count as generated-payload blockers. External runtime can exclude protected source for their generated payload content when the runtime payload artifacts are present and hash-verified.

## Remaining Blockers

The remaining 16 source-intent entries still require module/source decoupling before an external package can exclude protected source folders.

| SourceIntentId | Tool | Module | SourceRole | Source needed for | Current blocker | Recommended treatment | Risk | Proposed future phase |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `reinstall.source` | Reinstall | `modules/Refresh/reinstall.psm1` | `ProtectedUltimateSource` | Source parity validation; runtime verification; action-plan evidence | Module verifies protected source before action path | `ExternalRuntimeStillBlocked`, `NeedsModuleDecoupling` | Medium | Generated operation descriptor for media-prep workflow |
| `updates-drivers-block.source` | Updates Drivers Block | `modules/Refresh/updates-drivers-block.psm1` | `ProtectedUltimateSource` | Source parity validation; runtime verification; setup script evidence | Module verifies protected source before USB script generation | `ExternalRuntimeStillBlocked`, `NeedsModuleDecoupling` | Medium | Generated setup-script descriptor |
| `bitlocker.source` | BitLocker | `modules/Setup/bitlocker.psm1` | `SourcePromotedIntake` | Source parity validation; runtime verification; diagnostics | Module verifies promoted source for security assistant actions | `ExternalRuntimeStillBlocked`, `NeedsModuleDecoupling` | High | Generated security-action descriptor |
| `convert-home-to-pro.source` | Convert Home To Pro | `modules/Setup/convert-home-to-pro.psm1` | `SourceExtra` | Source parity validation; runtime verification; provenance diagnostics | Module verifies `source-extra` before edition flow | `ExternalRuntimeStillBlocked`, `NeedsModuleDecoupling` | Medium | Generated edition-flow descriptor |
| `edge-settings.source` | Edge Settings | `modules/Setup/edge-settings.psm1` | `ProtectedUltimateSource` | Source parity validation; runtime verification; action-plan evidence | Module verifies protected source before Edge actions | `ExternalRuntimeStillBlocked`, `NeedsModuleDecoupling` | High | Generated Edge operation catalog |
| `installers.source` | Installers | `modules/Installers/installers.psm1` | `ProtectedUltimateSource` | Source parity validation; runtime verification; provenance evidence | Module verifies protected installer source | `ExternalRuntimeStillBlocked`, `NeedsModuleDecoupling` | High | Generated retained-installer catalog metadata |
| `driver-clean.source` | Driver Clean | `modules/Graphics/driver-clean.psm1` | `SourcePromotedIntake` | Source parity validation; runtime verification; DDU workflow evidence | Module verifies promoted source before action planning | `ExternalRuntimeStillBlocked`, `NeedsModuleDecoupling` | High | Generated Driver Clean workflow descriptor |
| `nvidia-app-install.source` | Install NVIDIA App | `modules/Graphics/nvidia-app-install.psm1` | `ProtectedUltimateSource` | Source parity validation; runtime verification; installer-source evidence | Module verifies installer source identity | `ExternalRuntimeStillBlocked`, `NeedsModuleDecoupling` | High | Generated NVIDIA App installer descriptor |
| `directx.source` | DirectX | `modules/Graphics/directx.psm1` | `ProtectedUltimateSource` | Source parity validation; runtime verification; artifact/source evidence | Module verifies protected source before DirectX plan | `ExternalRuntimeStillBlocked`, `NeedsModuleDecoupling` | High | Generated DirectX install descriptor |
| `visual-cpp.source` | Visual C++ | `modules/Graphics/visual-cpp.psm1` | `ProtectedUltimateSource` | Source parity validation; runtime verification; installer evidence | Module verifies protected source before installer plan | `ExternalRuntimeStillBlocked`, `NeedsModuleDecoupling` | High | Generated Visual C++ installer descriptor |
| `bloatware.source` | Bloatware | `modules/Windows/bloatware.psm1` | `ProtectedUltimateSource` | Source parity validation; runtime verification; branch evidence | Module verifies protected source before branch planning | `ExternalRuntimeStillBlocked`, `NeedsModuleDecoupling` | High | Generated bloatware branch descriptor |
| `copilot.source` | Copilot | `modules/Windows/copilot.psm1` | `ProtectedUltimateSource` | Source parity validation; runtime verification; branch evidence | Module verifies protected source before action planning | `ExternalRuntimeStillBlocked`, `NeedsModuleDecoupling` | High | Generated Copilot operation descriptor |
| `game-bar.source` | GameBar | `modules/Windows/game-bar.psm1` | `ProtectedUltimateSource` | Source parity validation; runtime verification; branch evidence | Module verifies protected source before action planning | `ExternalRuntimeStillBlocked`, `NeedsModuleDecoupling` | Medium | Generated GameBar operation descriptor |
| `edge-webview.source` | Edge & WebView | `modules/Windows/edge-webview.psm1` | `ProtectedUltimateSource` | Source parity validation; runtime verification; Edge/WebView evidence | Module verifies protected source before action planning | `ExternalRuntimeStillBlocked`, `NeedsModuleDecoupling` | High | Generated Edge/WebView operation descriptor |
| `control-panel-settings.source` | Control Panel Settings | `modules/Windows/control-panel-settings.psm1` | `ProtectedUltimateSource` | Source parity validation; runtime verification; registry script evidence | Module verifies protected source before action planning | `ExternalRuntimeStillBlocked`, `NeedsModuleDecoupling` | Medium | Generated registry-operation descriptor |
| `cleanup.source` | Cleanup | `modules/Windows/cleanup.psm1` | `ProtectedUltimateSource` | Source parity validation; runtime verification; cleanup target evidence | Module verifies protected source before cleanup planning | `ExternalRuntimeStillBlocked`, `NeedsModuleDecoupling` | High | Generated cleanup target descriptor |

## External Package Status

External package readiness is not complete.

The generated runtime payload layer is ready, but the runtime source-intent layer still has 16 blockers where modules or diagnostics rely on protected source files for runtime verification, source parity evidence, or source-derived operation descriptors. External packaging must not exclude `source-ultimate/` or `source-extra/` until those dependencies are moved to generated, hash-verified metadata or made explicitly internal-development-only.

## Customer-Facing Cleanup Notes

This phase does not rewrite customer-facing copy.

Terms found in source-intent and nearby runtime surfaces should be treated as follows:

- `source-ultimate`, `source-extra`, source paths, and source hashes: developer diagnostics only; must be hidden from normal customer UI.
- `Ultimate`: may remain in developer parity and governance diagnostics; should be replaced or hidden in customer UX copy where it is not necessary for support/debugging.
- `source-defined` and `source-equivalent`: useful in developer tests and diagnostics; should be replaced in normal UX/microcopy with product-facing phrasing such as approved workflow, original workflow, or BoostLab workflow.
- Provenance and parity labels: internal only unless exposed through an explicit diagnostic/debug view.

## Recommended Next Phases

1. Generate external operation descriptors for the 16 non-payload blockers, grouped by risk and tool family.
2. Add external-mode conditional behavior that uses generated descriptors while preserving InternalDevelopment source parity checks.
3. Add packaging validation that proves `source-ultimate/`, `source-extra/`, and `intake/` can be absent only when all source-intent blockers are resolved.
4. Run a customer-facing microcopy cleanup phase to hide internal source/provenance terms from normal UI without weakening developer diagnostics.

## Safety Boundary

This phase did not:

- modify `source-ultimate/`
- modify `source-extra/`
- modify `intake/`
- change tool module behavior
- change runtime Apply behavior
- change UI visuals or customer copy
- remove internal source parity validation
- implement external packaging
- run real Apply/runtime actions
- mutate registry, services, tasks, packages, AppX, drivers, BitLocker, activation, cleanup targets, installers, Timer, Defender, Start Menu layout, NVIDIA, or host state
- stage, commit, or push changes

## Validation

Validation covers source-intent schema and classification, runtime payload readiness, internal source parity preservation, absence of embedded protected source bodies in manifests, protected folder working-tree guards, source/hash policy, source policy, result severity policy, tolerated outcome policy, scaffolding, GUI/runtime contracts, reached/action label parity, and the full static/mocked suite.
