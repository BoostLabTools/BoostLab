# BoostLab Action Plan and Confirmation Framework

Phase 11 introduces a reusable planning and confirmation boundary for future system-changing actions. It does not authorize or implement new tool behavior.

## Action Planning Lifecycle

The runtime target remains:

```text
Preflight -> Plan -> Confirm -> Checkpoint -> Execute -> Verify -> Persist -> Restart or Rollback
```

Phase 11 implements the Plan and reusable Confirm boundary:

1. Validate the tool catalog metadata and requested action.
2. Build an Action Plan from the tool's risk and capability metadata.
3. Decide whether an implemented action can continue without confirmation.
4. Request confirmation through a UI callback when confirmation is required.
5. Block the implemented action when confirmation is declined or unavailable.
6. Attach the Action Plan to the structured result for UI and logging use.

Phase 13.5 adds the reusable post-action verification contract and the first implementation for Widgets. Checkpoint, generalized verification coverage, rollback, and durable restart continuation remain future work.

## Action Plan Contract

`New-BoostLabActionPlan` is provided by `core/ActionPlan.psm1`. It returns:

* `ToolId`
* `ToolTitle`
* `Action`
* `RiskLevel`
* `Capabilities`
* `Summary`
* `PlannedChanges`
* `SideEffects`
* `RequiresAdmin`
* `RequiresInternet`
* `CanReboot`
* `NeedsExplicitConfirmation`
* `SupportsDefault`
* `SupportsRestore`
* `ConfirmationMessage`
* `IsDryRun`
* `Timestamp`

The planner reads `config/Stages.psd1`; it does not infer permission from module code and does not execute commands.

## Capability-Driven Confirmation

A plan requires confirmation when the tool is high risk or declares confirmation-sensitive capability, including:

* Reboot
* Service changes
* Software installation
* Downloads
* Driver changes
* Security changes
* File deletion
* TrustedInstaller
* Safe Mode

The explicit catalog flag `NeedsExplicitConfirmation` is also honored.

Planning and execution gating are related but distinct. A high-risk Analyze plan remains visibly high risk, but a read-only Analyze action is not interrupted by an execution confirmation dialog. Placeholder actions receive a dry-run plan and still return `Action not implemented yet`; confirmation never turns a placeholder into an executable action.

Safe implemented Open-only tools do not receive unnecessary confirmation. BIOS Settings Open remains confirmation-gated because its approved behavior can immediately restart the PC into BIOS/UEFI.

## Action Meanings

* **Open** launches an approved interface or resource. It requires confirmation only when the approved Open workflow has confirmation-sensitive effects such as reboot.
* **Analyze** collects and reports information without applying changes.
* **Apply** performs the approved operational behavior after required planning and confirmation.
* **Default** applies the tool's approved default behavior. It does not mean an inferred Windows default.
* **Restore** returns to a previous state captured by BoostLab. Restore must not execute without valid captured state.

## UI Contract

The WPF controller supplies a confirmation callback to the runtime. The callback receives the complete Action Plan and presents:

* Tool
* Action
* Risk
* Summary
* Planned changes
* Side effects
* Confirmation message
* Confirm and Cancel controls

Latest Result renders an attached Action Plan independently of the confirmation dialog. This preserves a visible record of what was proposed, including placeholder dry-run plans.

## Post-Action Verification

After a real action completes, the module should safely inspect the resulting state when possible and return a `VerificationResult`. The runtime validates the verification schema and tool/action identity before exposing it to state and UI layers.

Command and verification status must remain distinct:

* **Command Success** means the approved execution path completed without a reported command failure.
* **Verification Passed** means the expected system state was detected.
* **Verification Warning** means the command completed but detection was incomplete or Windows may still require refresh, sign-out, policy refresh, or restart.
* **Verification Failed** means the detected state contradicts the expected result.

Verification must be read-only. It must not silently retry, restart Explorer, reboot, or expand the action beyond its migration record.

## Migration Governance

The framework supports preserving Ultimate execution strength without permitting silent destructive execution. Future migrations still require:

* An approved migration record.
* Accurate capability metadata.
* A reviewable plan.
* Required confirmation.
* Compatibility and privilege checks.
* Post-action verification when the resulting state can be detected safely.
* Checkpoint, persistence, restart, and rollback behavior appropriate to the tool.

Confirmation is not authorization to exceed the approved migration record or capability set.
