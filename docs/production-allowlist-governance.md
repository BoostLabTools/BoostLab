# Production Allowlist Governance

## Purpose

Production allowlists are the bridge between a completed tool design and actual execution permission.

Phase 66 defines how future BoostLab production scopes must be proposed, reviewed, validated, approved, versioned, tested, and linked to one specific tool and one specific Ultimate source behavior before any deferred tool can use them.

This foundation exists because Phase 65 showed that the remaining deferred tools are no longer blocked only by missing generic foundations. They are mostly blocked by missing exact production allowlists, artifact approvals, generated-artifact ownership rules, process and scheduled-task governance, and restore selection design.

Phase 66 approves no production scope, no download artifact, no installer execution, no driver target, no service target, no registry target, no file target, no AppX package, no cleanup target, no reboot workflow, no TrustedInstaller target, no Safe Mode workflow, and no deferred tool behavior.

## Relationship To Phase 65

`docs/final-deferred-tools-readiness-matrix.md` identifies every current deferred tool, its current blocker category, and the production scopes or allowlists it would need before implementation can be reattempted.

This document defines the governance rules for creating those future scopes. The matrix tells BoostLab what is missing. This policy defines how a missing scope becomes a reviewed proposal and, eventually, an approved production entry.

The existence of this policy does not make any deferred tool ready. Future phases must still add exact entries to the correct policy file and tests for the specific tool, action, source behavior group, and target.

## Approval Lifecycle

Every future production allowlist entry must use one of these approval states:

* `Draft`: proposal is being written and must not be used by runtime execution.
* `Reviewed`: source behavior, target identity, risk, and tests have been reviewed, but execution is still not approved.
* `Approved`: Yazan has approved the exact entry, validators cover it, and the matching runtime foundation may consider it.
* `Rejected`: proposal was reviewed and refused. The denial reason must remain documented.
* `Deprecated`: proposal used to be valid but must no longer be used by new operations.

Only `Approved` entries may ever be considered by future execution paths. All other states are non-executing.

## Required Metadata Fields

Every future production allowlist entry must include:

* `ToolId`
* `ToolName`
* `SourcePath`
* `SourceChecksum`
* `DesignReviewDocument`
* `SourceBehaviorGroup`
* `ScopeType`
* `ExactTargetIdentity`
* `MutationType`
* `SupportedAction`
* `RequiredFoundationDependency`
* `RequiredCaptureBeforeMutation`
* `RequiredConfirmationLevel`
* `RequiredPreMutationVerification`
* `RequiredPostMutationVerification`
* `RollbackFeasibility`
* `DefaultRestoreStatus`
* `ProductScopeImpact`
* `RiskLevel`
* `OwnerApprovalNote`
* `ApprovalStatus`
* `ApprovalDateOrVersion`
* `TestsRequired`
* `ValidatorRequired`
* `DenialReason`

Missing metadata blocks approval. Vague metadata blocks approval. Metadata that cannot be traced back to an approved Ultimate source behavior group blocks approval.

## Scope Types

Supported proposal scope types are:

* `Registry`
* `File`
* `Cleanup`
* `Service`
* `AppX`
* `Driver`
* `ScheduledTask`
* `Process`
* `DownloadArtifact`
* `InstallerExecution`
* `RebootWorkflow`
* `TrustedInstaller`
* `SafeMode`
* `RunOnce`
* `ActiveSetup`
* `BHO`
* `GeneratedScript`

Adding a scope type to this list does not implement that scope. It only gives future proposals a consistent vocabulary.

## Review Gates

Future production allowlist proposals must pass these gates before approval:

1. **Source Mapping Gate**
   The proposal must point to an exact source path, source checksum, and design or provenance review document.
2. **Behavior Group Gate**
   The proposal must name the source behavior group it preserves.
3. **Product Scope Gate**
   Windows 10-only optimization branches and AMD/Intel GPU-specific branches remain unsupported unless Yazan explicitly changes scope.
4. **Foundation Gate**
   The required foundation must exist and remain compatible with the proposed scope.
5. **Exact Target Gate**
   The target identity must be exact, bounded, and non-wildcard.
6. **Capture Gate**
   Mutating scopes must declare whether capture, inventory, checkpoint, or provenance verification is required before mutation.
7. **Confirmation Gate**
   Risk, privilege, reboot, security, destructive, TrustedInstaller, Safe Mode, driver, installer, and service-changing scopes require explicit confirmation.
8. **Verification Gate**
   The proposal must define pre-mutation and post-mutation verification.
9. **Rollback Gate**
   The proposal must state whether Default, Restore, both, or neither is available. Restore requires exact captured-state selection and verification.
10. **Test Gate**
    A validator must prove the scope is exact, source-linked, and does not drift.
11. **Approval Gate**
    Yazan approval must be recorded before a proposal can become `Approved`.

## Per-Scope-Type Rules

### Registry

Registry scopes must name exact hives, keys, value names, value types, mutation types, and source behavior groups. Broad hives such as `HKLM:\`, `HKCU:\`, `HKLM:\SYSTEM`, or entire policy roots are denied unless a future phase adds a narrowly bounded child path with explicit source evidence.

### File

File scopes must use exact local paths, bounded roots, known item types, and state capture where overwrite or delete is possible. Broad roots such as `C:\`, `C:\Windows`, `C:\Program Files`, user profile root, `Documents`, `Desktop`, and `Downloads` are denied unless a future phase approves an exact bounded child path.

### Cleanup

Cleanup scopes require bounded roots, target type, delete or quarantine semantics, recursion permission, file-count limits, byte limits, reparse-point rules, confirmation, and verification. Wildcard-only cleanup and broad recursive deletion are denied.

### Service

Service scopes must use exact service names and exact allowed mutations. Unknown services, wildcard services, broad enumeration, protected service changes, create/delete behavior, and dynamic service mutation are denied unless a future exact source-mapped exception is approved.

### AppX

AppX scopes must name exact packages, package families, user scope, provisioned scope, dependencies, inventory requirements, restore feasibility, and protected-package exceptions. Unknown packages, framework packages, dependency packages, system-critical packages, and wildcard packages are denied without an explicit exception model.

### Driver

Driver scopes must name exact device, vendor, hardware, package, INF, profile, and rollback identities where applicable. GPU-specific branches remain NVIDIA-only. AMD and Intel GPU-specific scopes are denied unless product scope changes.

### Scheduled Task

Scheduled task scopes must use exact task paths and exact allowed mutations. Dynamic scheduled task mutation, broad task folders, and wildcard task names are denied.

### Process

Process scopes must name exact process targets, reason, interruption handling, confirmation, and verification. Broad process stop and shell-critical process handling are denied until exact policy exists.

### Download Artifact

Download artifact scopes must use the Phase 35 provenance model. Unknown artifacts, mutable URLs, missing hashes, missing signer requirements for executable artifacts, and unverified downloads are denied.

### Installer Execution

Installer execution scopes require a verified artifact, exact command descriptor, exact switches, exit-code expectations, timeout, confirmation, logging, and verification. Execution from a URL or unverified temp path is denied.

### Reboot Workflow

Reboot scopes require a Phase 40 workflow, explicit confirmation, checkpoints, state references, recovery instructions, and post-reboot verification. Firmware restart requires exact workflow approval.

### TrustedInstaller

TrustedInstaller scopes require exact target-specific command descriptors, adjacent foundation references, explicit confirmation, and structured verification. Generic TrustedInstaller execution is denied.

### Safe Mode

Safe Mode scopes require an exact Safe Mode workflow, verified exit path, recovery plan, resume handler, expiration, cancellation behavior, and post-resume verification. Safe Mode without a recovery/exit plan is denied.

### RunOnce, Active Setup, And BHO

RunOnce, Active Setup, and Browser Helper Object scopes require exact key allowlists, capture before mutation, cancellation or cleanup rules, confirmation, and verification. Broad startup persistence mutation is denied.

### Generated Script

Generated script scopes must define the generated path, ownership, content source, hash, cleanup rule, allowed interpreter, execution permission, and verification. Generated scripts without ownership, hash, or path policy are denied.

## Hard Denial Rules

The following are denied by default:

* Wildcard-only targets.
* Broad registry hives or entire system roots.
* Broad file roots such as `C:\`, `C:\Windows`, `Program Files`, user profile root, `Documents`, `Desktop`, or `Downloads` unless an exact bounded child path is approved later.
* Unknown AppX packages.
* Framework, dependency, or system-critical packages without an explicit exception model.
* Unknown services.
* Wildcard services.
* Dynamic scheduled task mutation.
* Broad process stop.
* Unverified downloads.
* Mutable URLs without approved hash, signer, and provenance.
* Installer execution without an exact descriptor.
* Reboot or firmware restart without workflow policy.
* TrustedInstaller use without a target-specific descriptor.
* Safe Mode flow without a recovery and exit plan.
* RunOnce, Active Setup, or BHO mutation without exact key allowlist and capture.
* Generated scripts without ownership, hash, and path policy.
* Default behavior that deletes broad keys or paths, cannot be verified, or cannot be safely distinguished from unrelated system state.
* Restore behavior without exact captured-state selection and verification.

## Scope Drift Validation

Every future production allowlist validator must prove:

* The entry maps to the exact current source checksum.
* The design or provenance review document still exists.
* The target identity is exact.
* The scope does not use wildcards or broad roots.
* The correct foundation policy file contains only the intended new entry.
* The proposal does not enable unrelated tools.
* The matching module remains placeholder until a separate implementation phase wires behavior.
* Deleted tools remain deleted.
* `source-ultimate/` remains unchanged.

Any drift must fail validation before runtime can use the scope.

## Preserving Ultimate Execution Strength

This foundation prevents weakening Ultimate behavior by requiring every future allowlist proposal to map to an exact source behavior group and to state whether it preserves, rejects, or explicitly decomposes that behavior.

Production allowlists must preserve the approved Ultimate behavior they represent. They must not silently weaken source behavior by approving only a comfortable subset while presenting it as the original tool.

If a source behavior cannot be safely approved as-is, the proposal must be `Rejected`, or the source must be decomposed into a smaller explicitly approved behavior group with Yazan approval.

## Preventing Unsafe Partial Implementation

This foundation prevents unsafe partial implementation by requiring future phases to separate planning evidence from execution permission.

A production allowlist must never be used to imply that a whole deferred tool is implemented. A tool remains deferred until a dedicated implementation phase wires exact behavior, validation, Action Plan confirmation, verification, and result reporting.

Future phases must not approve registry-only, policy-only, or UI-only slices when that would misrepresent a heavier Ultimate tool. Narrow slices are allowed only when they are explicitly named as separate approved behavior groups and do not claim full tool parity.

## Future Approval Workflow

1. Use the Phase 65 matrix to select a deferred tool and blocker.
2. Read the tool-specific scope or provenance design.
3. Draft one exact allowlist proposal for one tool, action, source behavior group, and target.
4. Validate the proposal with `core/ProductionAllowlistGovernance.psm1`.
5. Add tests proving the proposal is exact and that unrelated scopes remain empty.
6. Ask Yazan to approve or reject the proposal.
7. If approved, add the exact production entry to the appropriate foundation policy file.
8. Only in a later implementation phase, wire the approved scope to the tool behavior.

## Phase 66 Production State

Phase 66 creates governance only.

* Production allowlist proposals: **0**
* Approved production scopes: **0**
* Approved artifacts: **0**
* Approved installer executions: **0**
* Deferred tools enabled: **0**
* Runtime tool behavior changes: **0**

## Recommended Next Phases

1. **Restore Selection UI / Runtime Foundation**
   Required before captured-state Restore can be exposed confidently.
2. **Process Handling Policy Foundation**
   Required for Copilot, Start Menu Taskbar, Control Panel Settings, Edge Settings, and several heavy workflows. Phase 68 documents this foundation in `docs/process-handling-policy.md`; it approves no production process scopes or targets.
3. **Scheduled Task State Capture / Rollback Foundation**
   Required for Edge Settings, Control Panel Settings, Defender Optimize Assistant, and installer-like workflows.
4. **Generated Script / Temp Artifact Ownership Policy**
   Required for Updates Drivers Block, Timer Resolution Assistant, Defender Optimize Assistant, DirectX-style extraction, and registry-import workflows.
5. **RunOnce / Active Setup Governance**
   Required before persistent startup or post-reboot repair behavior can be approved.
