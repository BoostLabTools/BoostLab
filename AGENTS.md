# BoostLab Agent Instructions

These instructions apply to Codex when working in the BoostLab repository.

1. Read `CODEX_INSTRUCTIONS.md` first.
2. Follow `BOOSTLAB_BLUEPRINT.md`, `config/Stages.psd1`, `docs/remaining-tool-migration-triage.md`, the migration records in `docs/migrations/`, and the tests in `tests/`.
3. Preserve Ultimate execution strength for approved tools.
4. Never weaken Ultimate behavior unless Yazan explicitly approves it.
5. Never reintroduce deleted tools.
6. Treat `source-ultimate/` as immutable legacy reference material except for the already-approved Loudness EQ deletion.
7. Implement only the requested phase or tool.
8. Stop and report if a source requires behavior outside the current governance rules.
9. Run all validators before reporting completion.

10. Respect the current product scope: BoostLab supports Windows 11 only, and NVIDIA-only behavior for GPU-specific tooling. Windows 10 branches and AMD/Intel GPU-specific branches remain unsupported unless Yazan explicitly changes scope later. Unsupported branches must stay disabled, visual-only, or not implemented, and must not be turned into active command execution by accident.

When in doubt, prefer the existing project documentation and the approved source mapping over invention.
