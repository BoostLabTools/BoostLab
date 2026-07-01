# AXIS Resume Contract

Date: 2026-07-01
Scope: owner-approved global first-use wizard resume design contract only

## Purpose

AXIS must always remember where the customer stopped, for every step and every script, even if the step does not reboot.

This is broader than restart-only behavior.

Restart-capable steps such as `bios-settings` still require extra care, because the customer-facing primary action will later restart the device into BIOS/UEFI. They are a special case inside the global resume requirement, not the only case.

This document records the design contract only. It does not implement persistence, startup behavior, scheduled tasks, registry state, runtime execution, BIOS opening, or reboot behavior.

## Global Resume State

AXIS should persist current stage and current step position throughout the first-use flow.

AXIS should preserve enough state to resume the same customer flow later, including:

- current stage
- current step ID
- current visible customer step
- whether the step was started
- whether the primary action was triggered
- whether the current step is ready, in progress, completed, or awaiting the customer to press `التالي`
- any customer navigation state required to avoid restarting the entire flow

This applies to all steps, including steps that do not restart the device.

## After Closing Or Reopening AXIS

After closing/reopening AXIS:

- AXIS should not force the customer to restart the whole flow.
- AXIS should restore the customer to the last relevant step.
- AXIS should not force the customer to repeat previous completed steps.
- AXIS should wait for the customer to continue instead of auto-advancing.

Exact persistence design and implementation are pending a later approved phase.

## Restart-Capable Step Extra Care

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
