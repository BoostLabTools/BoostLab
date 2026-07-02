# AXIS Input Window Contract

Date: 2026-07-02
Scope: owner-approved input-window behavior and USB selector visual clarity only

## Purpose

This document records global AXIS first-use wizard input-window rules.

This phase is documentation-only. It does not implement UI behavior, detect USB devices, write files, run Apply, wire anything into `ui/MainWindow.ps1`, or mutate host state.

## Input Window Pattern

An AXIS input window or overlay collects required customer input before a step starts its simulated or future real flow.

Input windows are not confirmation checkbox windows unless a step-specific owner-approved blueprint explicitly says otherwise.

The global no-Cancel rule remains active:

- no Cancel button appears
- no hidden or disabled Cancel placeholder appears
- `رجوع` is return-only and not Cancel

`رجوع` closes only the input window and returns to the main step screen.

Primary input-window actions remain disabled until the required input for that step is valid.

## USB Selector Visual Clarity Contract

Yazan's Phase 181A global requirement: AXIS USB selection windows must be clear, readable, and visually consistent with the dark AXIS UI.

This applies to:

- AutoUnattend
- Updates Drivers Block
- any future step that asks the customer to choose USB media

Rules:

- USB selector should not look like a harsh plain white system control.
- Options must be easy to read.
- Selected USB value must be clearly visible.
- Dropdown/selector should fit the dark AXIS style.
- Selector must be visually obvious as an interactive input.
- Labels must be clear and right-aligned in Arabic.
- Input window buttons remain consistent: primary action and `رجوع`.
- No Cancel appears.
- Future real USB detection must not guess or show unsafe/unclear targets.
- Technical drive details belong in diagnostics unless Yazan approves customer-facing copy.

## USB Safety Boundary

In documentation and prototype phases:

- do not detect real removable media
- do not format USB media
- do not erase USB media
- do not write to USB media
- do not create files on USB media
- do not open directories
- do not create backups
- do not mutate the host

Future real USB behavior must be separately approved before implementation.

## Boundaries

This document does not approve or implement:

- UI implementation
- runtime implementation
- real Apply execution
- USB detection
- USB formatting
- USB file operations
- setupcomplete/autounattend file creation
- MainWindow integration
- source-ultimate, source-extra, or intake changes
