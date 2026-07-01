# AXIS Customer-Visible Copy Contract

Date: 2026-07-01
Scope: owner-approved global customer-visible copy contract only

## Purpose

Only owner-approved content appears to the customer in the normal AXIS first-use UI.

This document records Yazan's global product rule for customer-facing copy. It does not implement UI behavior, localization, diagnostics, runtime behavior, or production integration.

## Owner-Approved Copy Rule

If Yazan did not explicitly approve a text, label, instruction, warning, result, note, action, or status for a step, it must not appear in the normal customer-facing AXIS first-use UI.

Normal customer UI should show only the exact approved copy for each step.

## Internal Technical Copy Boundary

BoostLab config/module descriptions are internal technical references only.

Internal action names are not customer-facing unless Yazan explicitly chooses them.

Examples of internal action names that must not appear as customer-facing labels unless explicitly owner-approved:

- Analyze
- Open
- Apply
- Default
- Restore

Diagnostics, raw errors, command status, logs, detection details, uncertainty, verification details, result contracts, and structured runtime data belong in diagnostics/developer reporting, not in normal customer-facing wizard copy.

## Customer Problem-State Policy

For normal customer-facing first-use UI, do not show:

- Error
- Failed
- Warning
- Needs attention
- Stopped
- Restart needed
- Waiting for confirmation
- Not available
- Skipped
- Completed with notes
- Arabic equivalents of those problem states

Technical truth remains diagnostics-only.

## Step Blueprint Relationship

Each step blueprint records the approved customer-facing content for that step.

The normal first-use UI may use only the step-specific approved copy plus global owner-approved shell labels such as `السابق` and `التالي`.

If a step needs new visible text later, that text must be explicitly owner-approved and recorded before appearing in the normal customer-facing UI.

## Boundaries

This document does not approve or implement:

- UI implementation
- runtime implementation
- MainWindow integration
- diagnostics changes
- result contract changes
- localization implementation
- English final copy
- Apply/Open/Default/Restore behavior changes
- source-ultimate, source-extra, or intake changes
