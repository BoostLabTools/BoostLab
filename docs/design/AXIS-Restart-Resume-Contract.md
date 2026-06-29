# AXIS Restart Resume Contract

Date: 2026-06-29
Scope: owner-approved restart/resume design contract only

## Purpose

AXIS must remember where the customer stopped when a first-use wizard step triggers a restart.

This contract is especially important for restart-capable steps such as `bios-settings`, where the customer-facing primary action will later restart the device into BIOS/UEFI.

This document records the design contract only. It does not implement persistence, startup behavior, scheduled tasks, registry state, runtime execution, BIOS opening, or reboot behavior.

## Resume State

Before a restart-capable step runs, AXIS should persist enough state to resume the same customer flow later, including:

- current stage
- current step ID
- current visible customer step
- whether the step was started
- whether the primary action was triggered
- whether the step should return as completed or ready for continuation
- any customer navigation state required to avoid restarting the entire flow

## After Windows Returns

After the customer returns to Windows and launches AXIS again:

- AXIS should resume at the same step instead of starting from the beginning.
- AXIS should not force the customer to repeat previous completed steps.
- AXIS should wait for the customer to continue instead of auto-advancing.

For BIOS Settings specifically, the intended future behavior is:

- return to the BIOS Settings step
- show the completed state `مكتمل` when appropriate
- enable `التالي`
- wait for the customer to press `التالي`

Exact persistence design and implementation are pending a later approved phase.

## Website Command Launch Context

This contract also applies to the future website/command-launched AXIS flow:

- customer runs a PowerShell command
- AXIS is downloaded or opened from the store website flow
- after restart, launching AXIS again should restore the current flow position

## Boundaries

This document does not approve or implement:

- creating runtime state files
- creating registry keys
- creating scheduled tasks
- creating startup entries
- rebooting
- opening BIOS/UEFI
- querying live firmware state
- changing MainWindow integration
- changing runtime module behavior
- changing Apply, Default, Restore, Open, diagnostics, or result contracts

