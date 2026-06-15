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

10. Respect the current product scope: Windows 11 is BoostLab's optimized target platform, and GPU-specific tooling is NVIDIA-only. Windows 10 optimization, performance, service, and settings-improvement branches remain unsupported unless Yazan explicitly changes scope. A Windows 10 host may run an approved preparation, refresh, migration, or transition tool when that tool's output and goal target Windows 11. AMD/Intel GPU-specific branches remain disabled, visual-only, or not implemented.

When in doubt, prefer the existing project documentation and the approved source mapping over invention.
