# AXIS Localization and RTL Contract

Date: 2026-06-29
Scope: design contract only

## Purpose

This document defines the AXIS localization source-of-truth workflow and the layout direction contract for Arabic and English customer-facing UI.

This phase does not implement UI behavior, wire anything into `ui/MainWindow.ps1`, change runtime behavior, or approve final customer-facing copy.

## Supported Languages

AXIS must support:

- Arabic
- English

## Source-of-Truth Workflow

Arabic customer-facing copy is authored and approved first by Yazan.

English customer-facing copy is translated later from the approved Arabic copy. English copy is not the source of truth, and it must remain reviewable before final implementation.

ChatGPT/Codex must not invent final customer-facing copy.

BoostLab config/module descriptions must not become customer-facing AXIS copy automatically.

Technical config and module data may be used only for internal mapping, such as tool identity, stage order, runtime action mapping, capability metadata, diagnostics mapping, and implementation references.

## Global First-Use Wizard Interaction Rules

Yazan's Phase 177C owner decisions apply globally to the AXIS first-use wizard.

`Cancel` must not appear anywhere in the first-use wizard. It must not appear in any script, step, footer, or confirmation dialog, and it must not remain as a disabled or hidden customer-facing placeholder.

Running/checking status must use a real runtime animation or effect when implemented. This must not be a static icon, static PNG, or static SVG, and it must not reintroduce script icons or decorative step icons.

These rules are documented here only. This phase does not implement UI behavior.

## Arabic RTL Behavior

Arabic mode must use:

- `FlowDirection = RightToLeft`
- right-aligned primary text
- mirrored layout
- mirrored stage strip
- mirrored content flow
- mirrored footer/navigation layout
- mirrored button placement where appropriate
- RTL-aware spacing and alignment
- no left-to-right layout assumptions for Arabic screens

Arabic mode is not Arabic text inside an English layout. The full UI structure must respect right-to-left reading direction and visual flow.

## English LTR Behavior

English mode must use:

- `FlowDirection = LeftToRight`
- normal left-to-right layout
- normal English text alignment
- normal English navigation layout

## Stage Strip Behavior

The logical AXIS stage order remains:

1. Check
2. Refresh
3. Setup
4. Installers
5. Graphics
6. Windows
7. Advanced

The visual stage strip direction depends on the active language:

- English: left-to-right visual order
- Arabic: right-to-left mirrored visual order

Final Arabic stage labels are not decided in this phase. They remain pending Yazan approval.

## Per-Step Content Model

Each AXIS step should eventually support localized owner-approved fields.

Arabic fields:

- Arabic title
- Arabic subtitle
- Arabic body
- Arabic panel titles
- Arabic bullets
- Arabic button labels
- Arabic Ready text
- Arabic Checking text
- Arabic Completed text
- Arabic documentation/acknowledgement text, if any

English fields:

- English title
- English subtitle
- English body
- English panel titles
- English bullets
- English button labels
- English Ready text
- English Checking text
- English Completed text
- English documentation/acknowledgement text, if any

For now:

- Arabic fields are owner-authored and pending Yazan approval.
- English fields are pending future translation after Arabic approval.

## Mixed Arabic/English Technical Text

Arabic UI may still contain technical acronyms or product names such as:

- AXIS
- BIOS
- UEFI
- NVIDIA
- AMD
- Intel
- DirectX

These mixed-direction terms must remain readable and must not be distorted by RTL layout. Future implementation should handle mixed-direction text safely.

## Customer State Policy Across Languages

For both Arabic and English customer UI, only these normal customer-facing state keys are allowed:

- Ready
- Checking
- Completed

`Completed` is the only customer-facing end state.

Arabic equivalents are pending Yazan approval.

Problem/error labels remain excluded from normal customer-facing first-use UI.

## Diagnostics-Only Content

Diagnostics/developer views may contain:

- raw technical status
- command status
- verification details
- logs
- raw values
- exceptions

These details are not normal customer-facing first-use wizard copy.

## Acceptance Criteria

- Arabic-first workflow is documented.
- English-later translation workflow is documented.
- Arabic RTL full mirroring requirement is documented.
- English LTR requirement is documented.
- BoostLab config text cannot be used as customer copy automatically.
- All customer-facing Arabic copy remains pending Yazan approval until explicitly approved.
- Cancel is globally disallowed in the customer-facing first-use wizard.
- Checking/running status animation requirements are documented.
- No UI implementation is performed in this phase.
- No runtime behavior is changed.
- No `ui/MainWindow.ps1` integration is added.
- No protected source paths are changed.
