# AXIS Visual Style Contract

Date: 2026-07-02
Scope: owner-approved visual style decisions only

## Purpose

This document records global AXIS first-use wizard visual decisions that affect customer-facing presentation.

This phase is documentation-only. It does not implement UI behavior, change runtime behavior, wire anything into `ui/MainWindow.ps1`, or modify protected source paths.

## Documentation Button Color Decision

Yazan's Phase 181A decision:

- Documentation button `التعليمات` returns to its previous/default normal button text color.
- Do not keep `#E65F2B` for documentation button text.
- Do not use a custom documentation accent color unless Yazan approves a new one later.

This decision is documented here only. UI implementation is deferred to a later approved prototype/UI phase.

## Rejected Accent Decisions

Preserve the previous rejected accent decisions:

- acknowledgement text is not `#E65F2B`
- information card titles are not `#8A2BE2`
- requirements card titles are not `#D9A74A`

These colors must not be reintroduced as normal customer-facing AXIS first-use wizard accents unless Yazan explicitly approves a new decision later.

## Boundaries

This document does not approve or implement:

- UI implementation
- runtime implementation
- Apply/Open/Default/Restore behavior changes
- MainWindow integration
- diagnostics changes
- source-ultimate, source-extra, or intake changes
