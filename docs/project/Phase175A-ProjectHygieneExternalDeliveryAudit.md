# Phase 175A - Project Hygiene and External Delivery Boundary Audit

Date: 2026-06-27
Baseline: `e31f042 Fix Graphics refresh confirmation Yes-path freeze`

## Scope

This audit reviews BoostLab's current repository hygiene and external delivery boundary before UX, visual identity, and design-system work. It is diagnostic only. No runtime source, module, config, test, or legacy source file was edited as part of this phase.

## Runtime Dependency Boundary

| Path | Current classification | External delivery note |
| --- | --- | --- |
| `Start-BoostLab.ps1` | Runtime entrypoint | Include. Launches the WPF runtime, validates admin/STA, imports core modules, loads config and UI. |
| `bootstrap.ps1` | Runtime bootstrap | Include if the external package keeps the bootstrap launch path. |
| `core/` | Runtime required | Include. Contains environment, verification, logging, action plan, safety, state, trusted installer, and execution services. |
| `modules/` | Runtime required | Include. Contains the approved tool implementations. |
| `ui/` | Runtime required | Include. Contains WPF layout and controller. |
| `config/` | Runtime required plus internal governance data | Include only after deciding whether public runtime config should be split from provenance/internal policy manifests. |
| `license/` | Runtime required placeholder | Include only after replacing placeholder licensing copy for external delivery. |
| `source-ultimate/` | Runtime source-parity dependency | Current external package blocker. Multiple modules and provenance configs verify source hashes, and some modules read source text directly. Do not exclude until runtime source dependency is replaced. |
| `source-extra/` | Runtime source-parity dependency for Convert Home To Pro | Current external package blocker. `convert-home-to-pro` verifies the Yazan-provided source-extra script at runtime. Do not exclude until this dependency is replaced. |
| `intake/` | Internal intake/provenance material | Safe external exclusion based on current runtime scan; not a live runtime path. Unsafe to remove internally until provenance decisions are complete. |
| `tests/` | Development validation | Exclude from customer package. Keep internally. |
| `docs/` | Mixed internal documentation and product documentation | Exclude internal governance, migration, prompt, source-intake, and tool-design docs from customer package. Create a separate public README/user guide set. |
| `CODEX_INSTRUCTIONS.md`, `AGENTS.md`, `BOOSTLAB_BLUEPRINT.md` | Internal agent/governance material | Exclude from customer package. Keep internally. |

## Packaging Blockers

The current runtime is not ready for a clean customer package that excludes all internal source material. `source-ultimate/` and `source-extra/` are referenced by live modules, config, and action-plan text for checksum/provenance validation. Some source-backed modules also read source text directly to derive approved payloads.

This means an external package that removes those folders would risk failing validation or blocking tools. Before external delivery, BoostLab needs a source-decoupled runtime manifest or equivalent mechanism that preserves approved hashes, payload identity, and internal parity tests without shipping internal source trees.

## Safe External Exclusions

These are safe to exclude from a customer-facing package after package assembly is separated from the development repository:

- `tests/`
- `docs/migrations/`
- `docs/tool-designs/`
- internal policy/governance docs
- `intake/`
- agent instructions and Codex/OpenAI workflow material
- prompts, scaffolding notes, and migration provenance docs

`source-ultimate/` and `source-extra/` should become external exclusions, but they are not safe to exclude from the current runtime until the source-parity dependency is decoupled.

## Unsafe Internal Removal

Do not remove these from the internal repository based on this audit:

- `source-ultimate/`
- `source-extra/`
- `intake/`
- `tests/`
- migration/provenance documentation
- protected source checksum and parity baselines

They remain important for governance, parity verification, regression testing, and future package-boundary work.

## Internal Term Findings

No runtime-tree matches were found for `Codex`, `ChatGPT`, or `OpenAI`. A standalone `AI` scan was noisy because it matched ordinary words such as `Failed` and `Available`.

Runtime-visible or near-runtime internal terms remain:

- `Yazan`: present in tool descriptions, installer metadata, action-plan text, and source exception text.
- `Ultimate`: present in runtime descriptions and source-parity language.
- `source-defined`, `source-equivalent`, `controlled runtime`: present in catalog descriptions and action-plan text.
- `phase`: present in placeholder licensing and provenance comments.
- `source-ultimate`: present in module source paths and provenance configs.
- `source-extra`: present in Convert Home To Pro source verification and action-plan text.
- `intake`: present as a Driver Clean exception explanation string.
- `debug`: used as a diagnostic stream/result level, not as customer copy.
- `placeholder`: present in license and placeholder module behavior.

These are acceptable for internal diagnostics and governance, but several are not suitable as primary customer-facing copy.

## Customer-Facing Text Findings

The current UI and catalog still expose technical implementation language as part of the primary experience:

- Tool descriptions include internal phrases such as `Yazan-selected`, `Yazan-retained`, `Ultimate`, `source-defined`, and `source-equivalent`.
- Result surfaces expose raw statuses such as `Success`, `Warning`, `Error`, `Cancelled`, and `Not implemented`.
- Detail panels expose technical labels such as `Command Status`, `Verification Status`, `Warnings`, `Errors`, `Verification Checks`, `ExpectedState`, and `DetectedState`.
- Action-plan text often describes provenance, source checksums, protected behavior, and internal exception logic.
- License UI still displays placeholder licensing copy.

Recommendation: keep the raw technical fields available in diagnostics/developer detail, but introduce customer-facing result language and tool descriptions during the UX/microcopy phase.

## Proposed External Package Boundary

Candidate include set:

- `Start-BoostLab.ps1`
- `bootstrap.ps1`
- `core/`
- `modules/`
- `ui/`
- public/runtime-safe subset of `config/`
- finalized `license/`
- public README, user guide, and support/logging instructions

Candidate exclude set:

- `tests/`
- internal docs and migration records
- `source-ultimate/` after runtime source decoupling
- `source-extra/` after runtime source decoupling
- `intake/`
- agent instructions
- Codex/OpenAI workflow material
- prompts, scaffolding, and internal provenance notes

## Recommended Follow-Up Work

1. Add a package-boundary spec and a static package validator that fails when forbidden internal files or terms leak into a customer package.
2. Decouple runtime source checks from `source-ultimate/` and `source-extra/` while preserving internal checksum/parity validators.
3. Split public runtime config from internal provenance/governance manifests where practical.
4. Run a UX microcopy pass for tool titles, descriptions, confirmations, results, warnings, and diagnostic panels.
5. Replace placeholder licensing copy before any external package is produced.
