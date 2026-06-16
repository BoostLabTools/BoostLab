# Restore Selection UI / Runtime Foundation

## Purpose

Restore is not a synonym for Default.

`Default` means the approved default behavior for a tool. `Restore` means returning to a selected captured prior state from a previous BoostLab operation. Restore requires a valid capture record, a verified handler, exact target matching, explicit confirmation, and post-restore verification.

Phase 67 defines the future Restore selector model and adds inert runtime helpers for validating restore candidate records. It does not enable Restore for any deferred tool, approve any production restore scope, expose any new Restore button, or execute any restore mutation.

## Relationship To Existing Foundations

This foundation connects several earlier safety layers:

* **Phase 36 file/registry rollback:** provides exact file and registry capture records. Restore selection chooses one valid record before a future rollback handler may run.
* **Phase 37 service rollback:** provides service state records. Restore selection must verify service identity, tool/action, scope, and post-mutation state before any future service rollback.
* **Phase 38 cleanup/quarantine restore:** provides cleanup/quarantine records. Restore selection must distinguish quarantine restore from permanent deletion and block broad cleanup reversal.
* **Phase 39 AppX restore:** provides package inventory records. Restore selection must require exact package identity, provisioned/current-user scope, captured manifest, and protected-package policy.
* **Phase 40 reboot/recovery workflow:** restore work that needs reboot or resume must reference an approved workflow and cannot create its own reboot path.
* **Phase 41 driver rollback:** driver restore must use exact device/package/profile state and a verified driver rollback record.
* **Phase 66 production allowlist governance:** future Restore handlers and scope use must be approved through exact production allowlist governance before production execution.

The selector is a gate. It does not replace any foundation's own rollback checks.

## Restore Record Discovery

Future Restore discovery must enumerate candidate restore or capture records only from approved BoostLab state locations, such as operation-specific records beneath BoostLab-controlled state roots.

Discovery must:

* Be bounded by tool id where possible.
* Be bounded by source action where possible.
* Be bounded by scope type where possible.
* Be bounded by record type where possible.
* Ignore user-supplied arbitrary paths as trusted record sources.
* Avoid broad disk scanning.
* Return structured candidates with eligibility and denial reasons.

Phase 67 helper functions validate record objects supplied by tests or future callers. They do not scan arbitrary disk paths and do not mutate state.

## Restore Record Metadata

Every restore candidate must include or validate:

* `RestoreRecordId`
* `ToolId`
* `ToolName`
* `SourcePath`
* `SourceChecksum`
* `SourceAction`
* `ScopeType`
* `RecordType`
* `CapturedTargetIdentities`
* `Timestamp`
* `MachineContext`
* `UserContext`
* `OperatingSystemContext`
* `ProductScopeContext`
* `PreMutationStateSummary`
* `PostMutationStateRequirement`
* `PostMutationStatePresent`
* `RestoreHandlerType`
* `IntegrityHash`
* `SchemaVersion`
* `ApprovalPolicyVersion`
* `RiskLevel`
* `RestoreEligibilityState`
* `DenialReason`

Missing metadata blocks eligibility. Unsupported schema blocks eligibility. Unsupported handler type blocks eligibility.

## Eligibility Gates

A restore candidate must be refused when:

* Integrity check fails.
* Schema version is unsupported.
* Tool id mismatches the requesting tool.
* Source action mismatches the requested source action.
* Scope type mismatches.
* Record type mismatches.
* Target identity mismatches.
* Machine context mismatches when required.
* User context mismatches when required.
* Product-scope context mismatches when required.
* Record is stale beyond policy where relevant.
* Source checksum mismatches where required.
* Required post-mutation state is not present.
* Target now belongs to a different owner or unknown state.
* Target is outside current approved scopes.
* Record attempts broad registry hive restore.
* Record attempts broad file root restore.
* Restore would cross from one tool to another.
* Restore would reintroduce deleted tools.
* Restore would require unapproved TrustedInstaller, Safe Mode, reboot, installer, download, AppX, service, driver, or cleanup behavior.
* Restore requires a handler not approved by policy.
* Restore target is ambiguous or has multiple conflicting records.
* User confirmation is missing.

The default production policy approves no production Restore handlers and no production Restore scopes.

## Future Restore Selector UI

A future Restore selector UI should:

* List eligible records.
* Show ineligible records with denial reasons, but disable execution.
* Show timestamp, tool, source action, target summary, risk level, record type, scope type, schema version, and eligibility state.
* Show captured pre-mutation summary and required post-mutation state.
* Show the Action Plan before Restore.
* Require explicit user confirmation before Restore.
* Show verification results after Restore.
* Make the difference between Default and Restore visually explicit.
* Avoid broad record browsing or arbitrary file selection.

Phase 67 does not add visible Restore UI controls. It documents the future UI and provides mock-friendly validation helpers.

## Runtime Helper Behavior

`core/RestoreSelection.psm1` is deny-by-default and non-mutating.

The helper functions may:

* Load the restore selection policy.
* Validate policy shape.
* Compute a deterministic integrity hash for test records.
* Validate fake or future candidate record objects.
* Return structured `Eligible`, `Denied`, `Invalid`, or `NotApplicable` style results.
* Detect ambiguous candidate sets.

The helper functions must not:

* Execute file, registry, service, AppX, driver, cleanup, reboot, TrustedInstaller, Safe Mode, download, installer, RunOnce, Active Setup, BHO, or generated-script operations.
* Read or write protected targets.
* Treat arbitrary paths as trusted restore records.
* Approve production handlers.
* Enable Restore for any placeholder.

## Default Versus Restore

Default is not the same as Restore.

* `Default` means the tool's approved default behavior.
* `Restore` means reverting to a selected captured prior state.
* `Restore` cannot exist without a valid selected capture record and verified handler.
* Broad Default deletion must not be treated as Restore.
* A tool may have Default without Restore.
* A tool may not claim Restore merely because it knows a default value.

## Deferred Tool Impact

This foundation reduces one blocker for tools whose designs mention missing Restore selection, but it does not make those tools ready.

Deferred tools still require their other blockers, such as:

* Production allowlists/scopes.
* Artifact provenance.
* Installer execution descriptors.
* Process handling governance.
* Scheduled task governance.
* TrustedInstaller target flows.
* Safe Mode/reboot workflow approval.
* Driver/profile rollback scopes.
* AppX/package scopes.
* Cleanup/quarantine scopes.
* Generated script/temp artifact ownership policy.
* RunOnce, Active Setup, and BHO governance.

No deferred placeholder is enabled by Phase 67.

The current deferred queue snapshot and implementation ordering remain tracked in
`docs/final-deferred-tools-readiness-matrix.md`.

## Phase 67 Production State

Phase 67 creates Restore selection governance and inert validation helpers only.

* Production Restore scopes: **0**
* Approved Restore handlers: **0**
* Deferred tools enabled: **0**
* Visible Restore buttons added: **0**
* Runtime tool behavior changes: **0**
* Protected system mutations: **0**

## Recommended Next Phases

1. **Process Handling Policy Foundation**
   Required for Copilot, Start Menu Taskbar, Control Panel Settings, Edge Settings, and several heavy workflows.
2. **Scheduled Task State Capture / Rollback Foundation**
   Required before scheduled task changes can be captured, restored, or verified safely.
3. **Generated Script / Temp Artifact Ownership Policy**
   Required before generated `.reg`, `.ps1`, `.cmd`, `.xml`, `.nip`, C#, binary, or installer extraction artifacts can be approved.
4. **RunOnce / Active Setup Governance**
   Required before persistent startup or post-reboot repair behavior can be approved.
