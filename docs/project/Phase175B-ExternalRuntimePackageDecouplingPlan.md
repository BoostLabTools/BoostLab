# Phase 175B - External Runtime Package Boundary and Source Dependency Decoupling Plan

Date: 2026-06-27
Baseline: `479ca42 Add project hygiene delivery audit`

## Summary

Phase 175A confirmed that BoostLab can be split conceptually into a runtime package and an internal development repository, but the current runtime still depends on protected source folders. Phase 175B defines the future decoupling plan only. It does not change runtime behavior, UI visuals, tool order, tool scope, customer-facing copy, source files, tests, or config.

The recommended model is a hybrid internal/external mode:

- Internal development mode keeps protected source folders and validates raw source parity.
- External runtime package mode excludes protected source folders and validates against a generated runtime source-intent manifest.

This preserves internal source-parity discipline while allowing a clean customer package later.

## Mode Model

### Internal Development Mode

Internal development mode remains the authoritative BoostLab repository mode.

It keeps:

- `source-ultimate/`
- `source-extra/`
- `intake/`
- tests
- migration records
- protected checksum baselines
- parity/provenance docs
- Codex/agent workflow material

It validates:

- raw or canonical source hashes
- protected source file presence
- source-promoted intake mirror integrity
- source-to-module parity decisions
- package manifest generation inputs
- full safe/static suite

This mode is for Yazan/development/Codex use and must remain strict. Missing or drifted protected source should continue to fail internal validation.

### External Runtime Package Mode

External runtime package mode should be generated from the internal repository after decoupling.

It should exclude:

- `source-ultimate/`
- `source-extra/`
- `intake/`
- tests
- internal docs and migration records
- prompts/scaffolding/provenance notes
- Codex/OpenAI/agent workflow material

It should include only the runtime application, runtime-safe config, package metadata, public docs, and generated runtime manifests needed to run BoostLab honestly without protected source access.

External mode must not pretend raw source exists. If a diagnostic view reports source identity, it should say that the package was built from a verified internal source manifest rather than claiming a local `source-ultimate/` file was checked.

## Source Dependency Map Summary

Current runtime/source dependency classes found by static scan:

| Area | Classification | Current package implication |
| --- | --- | --- |
| `core/SourceVerification.psm1` | Runtime required today | Verifies real files with `Test-Path` and byte hashing. Needs external manifest-aware mode before source folders can be excluded. |
| Source-backed modules | Runtime required today | 20 modules reference `source-ultimate/` or `source-extra/` source identity directly. |
| Direct source-text readers | Runtime required today | 4 modules parse protected source text for payload or descriptor extraction. These need generated payload/descriptor manifest entries. |
| `config/ExternalArtifactSources.psd1` | Runtime config plus provenance | Loaded by `core/DownloadProvenance.psm1`; contains `SourceScriptPath` and phase/provenance metadata. Needs a public runtime subset. |
| `config/ArtifactProvenance.psd1` | Runtime/dev provenance config | Loaded by provenance helpers and many tests; contains protected source path links. Needs split between internal provenance and external runtime artifact metadata. |
| `config/ParityStatusBaseline.psd1` | Development/source-parity baseline | Heavily test/docs oriented; should remain internal unless a public summary is generated. |
| `docs/` and `tests/` references | Development/documentation only | Safe external exclusions after package assembly is separated. |
| `intake/` references | Development/source-intake only | Safe external exclusion after package assembly is separated; not a live runtime path from current scan. |

## Runtime Dependency Blockers

### Hash-Only Source Identity Blockers

These modules currently verify source identity by locating protected source paths and calling `Test-BoostLabSourceChecksum`. If the source file is removed, analysis/apply paths can report missing source identity and block or fail verification.

| File | Protected source | Tool | If source removed | Decoupling approach | Risk | Test needed |
| --- | --- | --- | --- | --- | --- | --- |
| `modules/Graphics/directx.psm1` | `source-ultimate/5 Graphics/2 DirectX.ps1` | DirectX | Source checksum missing/fails. | Manifest source identity check plus runtime artifact metadata. | Medium | External package no-source DirectX analyze/apply planning smoke. |
| `modules/Graphics/driver-clean.psm1` | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/1 Driver Clean.ps1` | Driver Clean | Source-promoted intake checksum missing/fails. | Manifest entry with intake-promotion source label and approved hashes. | High | External package Driver Clean analyze/open confirmation smoke. |
| `modules/Graphics/nvidia-app-install.psm1` | `source-ultimate/4 Installers/1 Installers.ps1` | Install NVIDIA App | Source checksum missing/fails. | Manifest links tool to generated source-intent entry from Installers source. | Medium | External package NVIDIA App analyze/apply planning smoke. |
| `modules/Graphics/visual-cpp.psm1` | `source-ultimate/5 Graphics/3 C++.ps1` | Visual C++ | Source checksum missing/fails. | Manifest source identity plus external artifact metadata. | Medium | Visual C++ no-source manifest validation test. |
| `modules/Installers/installers.psm1` | `source-ultimate/4 Installers/1 Installers.ps1` | Installers | Source checksum missing/fails. | Manifest source identity plus generated retained-app catalog evidence. | High | Installers retained catalog generated-manifest parity test. |
| `modules/Refresh/reinstall.psm1` | `source-ultimate/2 Refresh/1 Reinstall.ps1` | Reinstall | Source checksum missing/fails. | Manifest source identity plus artifact handoff metadata. | Medium | Reinstall no-source analyze/open/apply planning smoke. |
| `modules/Refresh/updates-drivers-block.psm1` | `source-ultimate/2 Refresh/3 Updates Drivers Block.ps1` | Updates Drivers Block | Source checksum missing/fails. | Manifest source identity plus generated USB payload hash. | High | USB payload generated-manifest parity test. |
| `modules/Setup/bitlocker.psm1` | `source-ultimate/_intake-promoted/Ultimate/3 Setup/1 BitLocker.ps1` | BitLocker | Source-promoted intake checksum missing/fails. | Manifest entry with source-promoted intake identity. | High | BitLocker no-source analyze/security path smoke. |
| `modules/Setup/convert-home-to-pro.psm1` | `source-extra/forgotten-scripts/3 Convert Home To Pro.ps1` | Convert Home To Pro | Source-extra checksum missing/fails. | Manifest source identity for Yazan-provided extra source. | Medium | Convert Home To Pro no-source apply planning smoke. |
| `modules/Setup/edge-settings.psm1` | `source-ultimate/3 Setup/6 Edge Settings.ps1` | Edge Settings | Source checksum missing/fails. | Manifest source identity plus operation-family summary. | High | Edge Settings no-source analyze/action-plan smoke. |
| `modules/Windows/bloatware.psm1` | `source-ultimate/6 Windows/11 Bloatware.ps1` | Bloatware | Source checksum missing/fails. | Manifest source identity plus branch operation summaries. | High | Bloatware no-source branch planning smoke. |
| `modules/Windows/cleanup.psm1` | `source-ultimate/6 Windows/22 Cleanup.ps1` | Cleanup | Source checksum missing/fails. | Manifest source identity plus cleanup target summary. | High | Cleanup no-source analysis/action-plan smoke. |
| `modules/Windows/control-panel-settings.psm1` | `source-ultimate/6 Windows/15 Control Panel Settings.ps1` | Control Panel Settings | Source checksum missing/fails. | Manifest source identity plus generated operation catalog hash. | High | Control Panel Settings no-source action-plan smoke. |
| `modules/Windows/copilot.psm1` | `source-ultimate/6 Windows/8 Copilot.ps1` | Copilot | Source checksum missing/fails. | Manifest source identity plus operation summary. | Medium | Copilot no-source analyze/action-plan smoke. |
| `modules/Windows/edge-webview.psm1` | `source-ultimate/6 Windows/13 Edge & WebView.ps1` | Edge & WebView | Source checksum missing/fails. | Manifest source identity plus artifact/process metadata. | High | Edge & WebView no-source analyze/open smoke. |
| `modules/Windows/game-bar.psm1` | `source-ultimate/6 Windows/12 Gamebar.ps1` | GameBar | Source checksum missing/fails. | Manifest source identity plus branch operation summary. | High | GameBar no-source branch planning smoke. |

### Source Text Extraction Blockers

These modules read protected source content directly. They are the highest-priority decoupling targets because a hash manifest alone is not enough.

| File | Protected source use | Runtime reason | If source removed | Decoupling approach | Risk | Test needed |
| --- | --- | --- | --- | --- | --- | --- |
| `modules/Advanced/timer-resolution-assistant.psm1` | Reads Timer Resolution source text. | Extracts the source-defined C# service payload. | Payload extraction throws and analysis/apply planning cannot proceed. | Generate a manifest entry containing the approved C# payload hash and either the approved payload text or a packaged payload artifact with hash. | High | Generated Timer payload equals internal source extraction; external package analyzes without source. |
| `modules/Advanced/defender-optimize-assistant.psm1` | Reads Defender Optimize source text. | Extracts generated Safe Mode scripts and security command lists. | Payload extraction throws and branch definitions cannot be built. | Generate protected script payload descriptors and hashes from internal source. External runtime consumes packaged descriptors, not raw source. | High | Generated Defender payloads equal internal source extraction; external package analyzes without source. |
| `modules/Graphics/driver-install-debloat-settings.psm1` | Reads Driver Install Debloat & Settings source. | Extracts NVIDIA Profile Inspector `.nip` content. | `.nip` extraction throws and NVIDIA branch planning can fail. | Generate `.nip` payload artifact/manifest entry with hash and source label. | High | Generated `.nip` payload equals internal source extraction; external package branch analysis works without source. |
| `modules/Windows/start-menu-taskbar.psm1` | Reads Start Menu Taskbar source. | Extracts embedded `start2.bin` PEM/base64 payload. | Payload extraction throws and payload status/apply path fails. | Generate packaged `start2.bin` payload or manifest payload with expected length/hash. | High | Generated `start2.bin` equals internal source extraction; external package verifies payload without source. |

### Config and Manifest Blockers

| File | Dependency reason | If shipped as-is | Decoupling approach | Risk | Test needed |
| --- | --- | --- | --- | --- | --- |
| `config/ExternalArtifactSources.psd1` | Runtime artifact source manifest loaded by `core/DownloadProvenance.psm1`; contains `SourceScriptPath`, phase ids, and provenance-only notes. | Customer package leaks internal source paths and phase/provenance language. | Generate public runtime artifact manifest with only tool id, artifact id, verified URL/source policy, hashes, size/signature requirements, and package-safe diagnostics. | Medium | Public manifest schema test and no-internal-term package scan. |
| `config/ArtifactProvenance.psd1` | Runtime/dev provenance manifest; tests and helpers import it; contains many protected source paths. | Customer package leaks internal source provenance and protected path map. | Keep internal; generate external artifact metadata subset if needed by runtime. | Medium | Runtime uses external manifest without importing internal provenance manifest. |
| `config/ParityStatusBaseline.psd1` | Source-parity/development baseline with `SourceScriptPath` and internal parity language. | Customer package leaks phase/parity/source wording. | Keep internal; generate public "tool support/status" summary only if UX needs it. | Low | Package excludes parity baseline and still launches. |
| `config/Stages.psd1` | Runtime catalog; contains customer-visible descriptions with internal terms. | Customer UI exposes `Yazan`, `Ultimate`, `source-defined`, and `source-equivalent`. | Later UX/microcopy phase should rewrite public copy while preserving internal diagnostics. | Medium | Customer UI term scan. |

## Recommended Decoupling Architecture

Use Option C: a hybrid manifest model.

### Internal Source Manifest Generation

Add a future internal-only generator that reads protected source folders and emits a runtime source-intent manifest. The generator should run only in internal development mode.

The generated manifest should contain:

- manifest schema version
- generation timestamp and repo commit
- source id
- tool id
- source label
- original protected relative path
- raw SHA-256
- canonical text SHA-256
- source promotion classification where relevant
- expected operation summary hash
- extracted payload entries where needed
- payload hashes, lengths, and safe labels
- artifact ids linked to the source intent
- generator version

Protected source text should not be copied into the manifest unless that payload is required at runtime and approved for external shipment. For payloads that must be shipped, package them as explicit generated runtime payload artifacts with their own hashes and labels.

### Internal Development Validation

Internal tests should prove:

- generated manifest entries match current `source-ultimate/` and `source-extra/`
- source text extraction outputs match generated payload artifacts
- protected source folders remain unchanged
- module embedded metadata and generated manifest metadata agree
- line-ending normalization remains supported

Internal mode should fail closed if protected source is missing or hash mismatched.

### External Runtime Validation

External runtime should:

- load the generated source-intent manifest
- verify manifest integrity
- verify packaged payload hashes
- verify artifact metadata
- avoid checking raw protected source paths
- report diagnostics honestly as "verified package source manifest" rather than "local source file verified"

External mode should fail closed when the runtime manifest is missing, malformed, unsigned when signing exists, hash-mismatched, wrong version, or incompatible with module metadata.

### Why Not Option A Alone

A generated manifest alone handles hash-only source identity, but it does not solve modules that extract payloads from source text. Timer Resolution, Defender Optimize, Driver Install Debloat & Settings, and Start Menu Taskbar need generated payload artifacts or payload descriptors.

### Why Not Option B Alone

Embedding all source metadata into modules reduces files but mixes generated provenance with hand-maintained runtime code. It also makes public package audits harder and increases risk of accidental source/provenance churn inside tool modules.

### Why Hybrid Is Preferred

Hybrid keeps internal source parity strict, makes external packages clean, supports generated payload artifacts, and creates a single package validator target. It also lets BoostLab keep internal manifests and public runtime manifests separate without weakening Ultimate behavior.

## Proposed Future External Package Layout

Candidate external runtime package:

```text
BoostLab/
  Start-BoostLab.ps1
  bootstrap.ps1
  core/
  modules/
  ui/
  config/
    Stages.psd1
    RuntimeArtifactSources.psd1
    RuntimeSourceIntent.psd1
    RuntimeSafetyPolicies/
  license/
  docs/
    README.md
    USER_GUIDE.md
    SUPPORT.md
  assets/
  runtime-payloads/
```

`config/RuntimeSourceIntent.psd1` and `runtime-payloads/` are proposed names only. Their exact names can change in the implementation phase.

## Include List

| Path | Include status | Notes |
| --- | --- | --- |
| `Start-BoostLab.ps1` | Include | Runtime launcher. |
| `bootstrap.ps1` | Include | Bootstrap launcher if retained for external package. |
| `core/` | Include runtime subset | Include runtime helpers; exclude future internal-only generator helpers from public package. |
| `modules/` | Include | Approved tool implementations. |
| `ui/` | Include | WPF shell and controller. |
| `config/Stages.psd1` | Include after microcopy cleanup | Runtime catalog, but current descriptions need customer-facing cleanup later. |
| Runtime safety policies | Include as needed | Include policies needed by live runtime validation. |
| Runtime source-intent manifest | Include after generation implementation | Replaces raw source-folder dependency in external mode. |
| Runtime payload artifacts | Include only when required | Needed for Timer, Defender, Driver Install `.nip`, Start Menu Taskbar `start2.bin`, and any future source-derived payloads. |
| `license/` | Include after placeholder replacement | Current placeholder copy is not external-ready. |
| Public README/user guide/support docs | Include | Must be separate from internal governance docs. |

## Exclude List

| Path/material | Exclusion status | Reason |
| --- | --- | --- |
| `source-ultimate/` | Safe only after decoupling | Runtime still depends on source paths and source text extraction. Do not delete internally. |
| `source-extra/` | Safe only after decoupling | Convert Home To Pro verifies `source-extra` at runtime. Do not delete internally. |
| `intake/` | Safe now for external package; unsafe to remove internally | Current runtime scan found no live `intake/` path dependency, but it remains internal source-intake evidence. |
| `tests/` | Safe now for external package; unsafe to remove internally | Development validation only. |
| `docs/migrations/` | Safe now for external package; unsafe to remove internally | Internal migration and parity record. |
| `docs/tool-designs/` | Safe now for external package; unsafe to remove internally | Internal design/governance material. |
| internal phase docs | Safe now for external package; unsafe to remove internally | Customer-irrelevant development history. |
| Codex/OpenAI/agent workflow files | Safe now for external package; unsafe to remove internally | Development workflow material, not runtime. |
| prompts/scaffolding/provenance notes | Safe now for external package; unsafe to remove internally | Internal process material. |
| `config/ParityStatusBaseline.psd1` | Safe only after runtime config split is verified | Development baseline; should not be required by runtime launch. |
| `config/ArtifactProvenance.psd1` | Safe only after runtime artifact manifest split is verified | Runtime/helpers currently know this path; external package should use public runtime artifact metadata instead. |
| `config/ExternalArtifactSources.psd1` | Replace with public subset | Current file contains internal source paths and phase/provenance language. |

## Customer-Facing Cleanup Targets

This phase does not rewrite UI or copy. These are future UX/microcopy targets.

| Term/surface | Classification | Recommendation |
| --- | --- | --- |
| `Yazan` in runtime descriptions/action plans | Hide from normal customer UI | Keep internally as governance attribution; replace customer copy with product-neutral wording. |
| `Ultimate` | Hide from normal customer UI | Keep in diagnostics/source history only. |
| `source-defined` | Reword in UX/microcopy phase | Customer copy should describe the action, not the source derivation. |
| `source-equivalent` | Reword in UX/microcopy phase | Keep in developer diagnostics if needed. |
| raw `Success` | Replace as primary customer result language | Diagnostics can retain exact status enum. |
| raw `Warning` | Replace as primary customer result language | Diagnostics can retain exact severity. |
| raw `Error` | Replace as primary customer result language | Customer UI should use action-oriented recovery language. |
| verification/status labels | Move to diagnostics/developer view | Normal UI should summarize outcome and next step. |
| placeholder license copy | Replace before external delivery | External package should not expose placeholder licensing. |
| hash/provenance details in normal UI | Move to diagnostics/developer view | Keep available for support logs and technical mode. |

## Future Validation Gates

Before external packaging is allowed, add or require these gates:

1. External package build test.
2. External package launch/import test.
3. No `source-ultimate/` dependency test.
4. No `source-extra/` dependency test.
5. No `intake/` dependency test.
6. Runtime source-intent manifest integrity test.
7. Generated payload parity tests for Timer, Defender, Driver Install `.nip`, and Start Menu Taskbar `start2.bin`.
8. Internal mode raw source-parity test.
9. External mode no-raw-source smoke tests for all source-backed modules.
10. External config subset schema test.
11. No internal term visible in normal customer UI test.
12. Public package forbidden-file scan.
13. Public package forbidden-term scan for Codex/OpenAI/prompts/scaffolding/internal phase material.
14. Full safe/static suite in internal mode.
15. Packaging smoke test on a copy that excludes protected/internal materials.

## Recommended Next Phases

1. Define the runtime source-intent manifest schema and generated payload artifact policy.
2. Build an internal-only manifest generator and tests that compare generated output to protected source.
3. Add external-mode source verification helpers without changing tool behavior yet.
4. Convert the four source-text extraction blockers to use generated payload artifacts in external mode while preserving internal raw-source validation.
5. Split public runtime artifact config from internal provenance config.
6. Add a package builder and forbidden-file/forbidden-term validators.
7. Run a UX/microcopy phase for customer-facing descriptions, result statuses, and diagnostics separation.
8. Replace placeholder licensing copy before external delivery.

## Explicit Non-Changes

This phase made no runtime behavior changes.

This phase did not:

- delete `source-ultimate/`
- delete `source-extra/`
- delete `intake/`
- modify protected source content
- change UI visuals
- change customer-facing copy
- change tool order
- change tool scope
- weaken source-equivalent behavior
- run runtime Apply actions
- stage, commit, or push

`source-ultimate/` and `source-extra/` must not be deleted from the internal repository yet. They remain required for internal source-parity validation and for current runtime source dependency behavior until a future decoupling implementation is complete.
