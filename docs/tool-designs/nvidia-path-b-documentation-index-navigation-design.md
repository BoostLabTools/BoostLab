# NVIDIA Path B Documentation Index And Navigation Design

## Purpose And Status

Phase 87 defines documentation index and navigation design for the NVIDIA App
Path B documentation set.

This is documentation index and navigation design only. This is not live UI navigation. This is not runtime navigation. No active docs runtime, app catalog, preview config, or workflow registry is enabled. No UI implementation is added. No runtime behavior changes. No tool card or placeholder is enabled. No executable workflow is created. No production approval is granted.

This document does not create active docs runtime, active UI config, active
runtime config, active preview config, production config, allowlist config,
runtime module, executable helper, tool module, or WPF runtime behavior.

NVIDIA App Path B exact required order:

`Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

Path relationship:

* Path A: `Driver Install Debloat & Settings`
* Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`
* Path A is the debloat/configuration workflow.
* Path B is the NVIDIA App compatible workflow for users who want to keep or
  use NVIDIA App features such as recording or related NVIDIA App features.
* Future UI/runtime must preserve guided separation between Path A and Path B
  and prevent accidental mixing unless later explicitly approved.

Source mirror references:

| Step | Script name | Source mirror path | SHA-256 |
|---:|---|---|---|
| 1 | Driver Install Latest | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1` | `41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F` |
| 2 | Nvidia Settings | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1` | `903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5` |
| 3 | Hdcp | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1` | `5C350D28F795D678051E6088F34968DF8D90B3D9024F558C5FAFB2899D1A906A` |
| 4 | P0 State | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1` | `382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC` |
| 5 | Msi Mode | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1` | `94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7` |

Related but out of scope:

* Driver Clean remains outside the five-step NVIDIA Path B workflow and needs a
  separate Driver Clean scope/provenance/safety design later.
* BitLocker remains outside the five-step NVIDIA Path B workflow and needs
  future security-sensitive design.

## Documentation Set Overview

Recommended reading order:

1. Phase 73: NVIDIA Path B Catalog Design -
   `docs/nvidia-path-b-catalog-design.md`
2. Phase 74: NVIDIA Path B Scope Design -
   `docs/tool-designs/nvidia-path-b-scope-design.md`
3. Phase 75: NVIDIA Path B Production Allowlist Planning -
   `docs/tool-designs/nvidia-path-b-production-allowlist-planning.md`
4. Phase 76: NVIDIA Path B Artifact Provenance Review -
   `docs/tool-designs/nvidia-path-b-artifact-provenance-review.md`
5. Phase 77: NVIDIA Profile State Capture Model -
   `docs/nvidia-profile-state-capture-model.md`
6. Phase 78: NVIDIA Path B UI Workflow Design -
   `docs/nvidia-path-b-ui-workflow-design.md`
7. Phase 79: NVIDIA Path B Draft Allowlist Proposal -
   `docs/tool-designs/nvidia-path-b-draft-allowlist-proposal.md`
8. Phase 80: NVIDIA Path B Production Approval Gate Design -
   `docs/tool-designs/nvidia-path-b-production-approval-gate-design.md`
9. Phase 81: NVIDIA Path B Runtime Gating Design -
   `docs/tool-designs/nvidia-path-b-runtime-gating-design.md`
10. Phase 82: NVIDIA Path B Non-Executing Workflow Registry Schema Design -
    `docs/tool-designs/nvidia-path-b-non-executing-workflow-registry-schema-design.md`
11. Phase 83: NVIDIA Path B Readiness Badge Design -
    `docs/tool-designs/nvidia-path-b-readiness-badge-design.md`
12. Phase 84: NVIDIA Path B Path Conflict Copy And Status Text Design -
    `docs/tool-designs/nvidia-path-b-path-conflict-copy-status-text-design.md`
13. Phase 85: NVIDIA Path B Non-Executing Catalog Preview Data Design -
    `docs/tool-designs/nvidia-path-b-non-executing-catalog-preview-data-design.md`
14. Phase 86: NVIDIA Path B Preview Data Integrity And Drift Rules Design -
    `docs/tool-designs/nvidia-path-b-preview-data-integrity-drift-rules-design.md`
15. Phase 87: NVIDIA Path B Documentation Index And Navigation Design -
    `docs/tool-designs/nvidia-path-b-documentation-index-navigation-design.md`

Every document in this set is non-executing and does not approve Path B
runtime behavior.

## Navigation Goals

Navigation goals:

* Give maintainers one entry point for Path B docs.
* Preserve phase order.
* Show dependency order.
* Show which docs are design-only.
* Show which docs are gating/governance docs.
* Show which docs are future UI/docs/reference docs.
* Show which docs are future runtime prerequisites.
* Show which docs block execution.
* Show that no current Path B doc enables execution.
* Show counts remain unchanged.
* Show Driver Clean and BitLocker remain out of Path B.
* Show standalone DDU remains absent.
* Show Loudness EQ and NVME Faster Driver remain deleted.

## Documentation Index Table

Every execution status is non-executing. This table deliberately avoids
`Approved` and `Enabled` as execution states.

| phase | document title | file path | document role | depends on | feeds into | execution status | approval status | runtime impact | UI impact | source impact | current validator |
|---:|---|---|---|---|---|---|---|---|---|---|---|
| 73 | NVIDIA Path B Catalog Design | `docs/nvidia-path-b-catalog-design.md` | Catalog orientation | Source promotion | Scope design | DesignOnly | NotApproved | None | None | None | `tests/Test-NvidiaPathBCatalogDesign.ps1` |
| 74 | NVIDIA Path B Scope Design | `docs/tool-designs/nvidia-path-b-scope-design.md` | Source behavior decomposition | Catalog design | Allowlist planning | DesignOnly | NotApproved | None | None | None | `tests/Test-NvidiaPathBScopeDesign.ps1` |
| 75 | NVIDIA Path B Production Allowlist Planning | `docs/tool-designs/nvidia-path-b-production-allowlist-planning.md` | Planning for future scopes | Scope design | Artifact review and draft proposal | DesignOnly | NotApproved | None | None | None | `tests/Test-NvidiaPathBProductionAllowlistPlanning.ps1` |
| 76 | NVIDIA Path B Artifact Provenance Review | `docs/tool-designs/nvidia-path-b-artifact-provenance-review.md` | Provenance review | Allowlist planning | Profile state and approval gate | NonExecuting | NotApproved | None | None | None | `tests/Test-NvidiaPathBArtifactProvenanceReview.ps1` |
| 77 | NVIDIA Profile State Capture Model | `docs/nvidia-profile-state-capture-model.md` | Profile capture model | Scope and provenance review | UI workflow and runtime gates | DesignOnly | NotApproved | None | None | None | `tests/Test-NvidiaProfileStateCaptureModel.ps1` |
| 78 | NVIDIA Path B UI Workflow Design | `docs/nvidia-path-b-ui-workflow-design.md` | Future UI workflow design | Catalog, scope, profile model | Draft allowlist and status text | DesignOnly | NotApproved | None | None | None | `tests/Test-NvidiaPathBUIWorkflowDesign.ps1` |
| 79 | NVIDIA Path B Draft Allowlist Proposal | `docs/tool-designs/nvidia-path-b-draft-allowlist-proposal.md` | Non-approved draft proposal | UI workflow, scope, provenance | Approval gate | NonExecuting | NotApproved | None | None | None | `tests/Test-NvidiaPathBDraftAllowlistProposal.ps1` |
| 80 | NVIDIA Path B Production Approval Gate Design | `docs/tool-designs/nvidia-path-b-production-approval-gate-design.md` | Future approval criteria | Draft allowlist | Runtime gates | DesignOnly | NotApproved | None | None | None | `tests/Test-NvidiaPathBProductionApprovalGateDesign.ps1` |
| 81 | NVIDIA Path B Runtime Gating Design | `docs/tool-designs/nvidia-path-b-runtime-gating-design.md` | Future runtime gate design | Approval gate | Workflow schema and badges | DesignOnly | NotApproved | None | None | None | `tests/Test-NvidiaPathBRuntimeGatingDesign.ps1` |
| 82 | NVIDIA Path B Non-Executing Workflow Registry Schema Design | `docs/tool-designs/nvidia-path-b-non-executing-workflow-registry-schema-design.md` | Future schema design | Runtime gates | Badges and preview data | NotImplemented | NotApproved | None | None | None | `tests/Test-NvidiaPathBNonExecutingWorkflowRegistrySchemaDesign.ps1` |
| 83 | NVIDIA Path B Readiness Badge Design | `docs/tool-designs/nvidia-path-b-readiness-badge-design.md` | Badge taxonomy | Runtime gates and workflow schema | Copy/status text and preview data | DesignOnly | NotApproved | None | None | None | `tests/Test-NvidiaPathBReadinessBadgeDesign.ps1` |
| 84 | NVIDIA Path B Path Conflict Copy And Status Text Design | `docs/tool-designs/nvidia-path-b-path-conflict-copy-status-text-design.md` | Future user-facing wording | Badges and UI workflow | Preview data | DesignOnly | NotApproved | None | None | None | `tests/Test-NvidiaPathBPathConflictCopyStatusTextDesign.ps1` |
| 85 | NVIDIA Path B Non-Executing Catalog Preview Data Design | `docs/tool-designs/nvidia-path-b-non-executing-catalog-preview-data-design.md` | Preview metadata design | Badges and copy/status text | Integrity/drift rules | NonExecuting | NotApproved | None | None | None | `tests/Test-NvidiaPathBNonExecutingCatalogPreviewDataDesign.ps1` |
| 86 | NVIDIA Path B Preview Data Integrity And Drift Rules Design | `docs/tool-designs/nvidia-path-b-preview-data-integrity-drift-rules-design.md` | Future drift/integrity rules | Preview data | Index/navigation | DesignOnly | NotApproved | None | None | None | `tests/Test-NvidiaPathBPreviewDataIntegrityDriftRulesDesign.ps1` |
| 87 | NVIDIA Path B Documentation Index And Navigation Design | `docs/tool-designs/nvidia-path-b-documentation-index-navigation-design.md` | Navigation layer | All prior Path B docs | Future review phases | DesignOnly | NotApproved | None | None | None | `tests/Test-NvidiaPathBDocumentationIndexNavigationDesign.ps1` |

## Document Dependency Graph

Ordered dependency map:

```text
Catalog -> Scope -> Allowlist Planning -> Artifact Provenance -> Profile State Model
UI Workflow -> Draft Allowlist -> Production Approval Gate
Runtime Gating -> Non-Executing Workflow Registry Schema
Readiness Badges -> Path Conflict Copy/Status Text
Catalog Preview Data -> Preview Data Integrity/Drift Rules
Documentation Index/Navigation as the navigation layer
```

Expanded flow:

```text
Catalog
  -> Scope
      -> Allowlist Planning
          -> Artifact Provenance
          -> Profile State Model
              -> UI Workflow
                  -> Draft Allowlist
                      -> Production Approval Gate
                          -> Runtime Gating
                              -> Non-Executing Workflow Registry Schema
                                  -> Readiness Badges
                                      -> Path Conflict Copy/Status Text
                                          -> Catalog Preview Data
                                              -> Preview Data Integrity/Drift Rules
                                                  -> Documentation Index/Navigation
```

## Reader Paths

Maintainer trying to understand Path B from scratch:

1. `docs/nvidia-path-b-catalog-design.md`
2. `docs/tool-designs/nvidia-path-b-scope-design.md`
3. `docs/nvidia-path-b-ui-workflow-design.md`
4. `docs/tool-designs/nvidia-path-b-readiness-badge-design.md`
5. `docs/tool-designs/nvidia-path-b-documentation-index-navigation-design.md`

Future implementer preparing a runtime gate evaluator:

1. `docs/tool-designs/nvidia-path-b-production-approval-gate-design.md`
2. `docs/tool-designs/nvidia-path-b-runtime-gating-design.md`
3. `docs/tool-designs/nvidia-path-b-non-executing-workflow-registry-schema-design.md`
4. `docs/tool-designs/nvidia-path-b-preview-data-integrity-drift-rules-design.md`
5. `docs/production-allowlist-governance.md`

Future UI designer preparing Path B stepper/preview/badges:

1. `docs/nvidia-path-b-ui-workflow-design.md`
2. `docs/tool-designs/nvidia-path-b-readiness-badge-design.md`
3. `docs/tool-designs/nvidia-path-b-path-conflict-copy-status-text-design.md`
4. `docs/tool-designs/nvidia-path-b-non-executing-catalog-preview-data-design.md`
5. `docs/tool-designs/nvidia-path-b-documentation-index-navigation-design.md`

Future security reviewer reviewing downloads/installers/Profile Inspector/.nip/profile/registry changes:

1. `docs/tool-designs/nvidia-path-b-scope-design.md`
2. `docs/tool-designs/nvidia-path-b-artifact-provenance-review.md`
3. `docs/download-provenance-installer-policy.md`
4. `docs/nvidia-profile-state-capture-model.md`
5. `docs/file-registry-state-capture-rollback.md`
6. `docs/tool-designs/nvidia-path-b-production-approval-gate-design.md`

Future tester/validator author:

1. `docs/tool-designs/nvidia-path-b-documentation-index-navigation-design.md`
2. `docs/tool-designs/nvidia-path-b-preview-data-integrity-drift-rules-design.md`
3. `docs/tool-designs/nvidia-path-b-non-executing-catalog-preview-data-design.md`
4. Existing `tests/Test-NvidiaPathB*.ps1` validators.

Future reviewer checking why Path B cannot execute today:

1. `docs/tool-designs/nvidia-path-b-production-approval-gate-design.md`
2. `docs/tool-designs/nvidia-path-b-runtime-gating-design.md`
3. `docs/tool-designs/nvidia-path-b-readiness-badge-design.md`
4. `docs/tool-designs/nvidia-path-b-non-executing-catalog-preview-data-design.md`

Future reviewer checking Path A vs Path B conflict handling:

1. `docs/nvidia-path-b-ui-workflow-design.md`
2. `docs/tool-designs/nvidia-path-b-runtime-gating-design.md`
3. `docs/tool-designs/nvidia-path-b-readiness-badge-design.md`
4. `docs/tool-designs/nvidia-path-b-path-conflict-copy-status-text-design.md`

## Cross-Reference Rules

Future cross-reference rules:

* Each Path B design doc should link to the index/navigation design once
  available.
* Docs that define gates should link to readiness badges and copy/status text
  docs.
* Docs that define preview data should link to integrity/drift rules.
* Docs that define UI concepts should link to runtime gating and workflow
  registry schema.
* Docs must distinguish Path B from Driver Clean and BitLocker.
* Docs must not imply approval, enablement, or runtime execution unless a future
  phase explicitly grants it.
* Docs should preserve the exact Path B order whenever they describe step
  sequence.
* Docs should state when content is design-only, non-executing, not approved, or
  not implemented.

## Navigation Metadata Design

Future documentation metadata fields:

* `docId`
* `phase`
* `title`
* `path`
* `role`
* `status`
* `approvalStatus`
* `executionImpact`
* `runtimeImpact`
* `uiImpact`
* `sourceImpact`
* `dependencies`
* `downstreamReferences`
* `relatedSourceFiles`
* `relatedValidators`
* `ownerArea`
* `lastReviewedPhase`
* `nextReviewTrigger`
* `nonExecutionGuarantee`

This is metadata design only, not a live metadata registry. A future metadata
registry must not be consumed by runtime or UI unless a separate phase approves
read-only consumption and proves no action button enablement.

## Review Checklist

Future documentation review checklist:

* all Path B docs exist.
* phase order is correct.
* source checksums match.
* all five Path B steps are referenced in exact order.
* Path A vs Path B distinction is visible.
* Driver Clean and BitLocker are out of Path B.
* all current docs state non-execution/no approval where appropriate.
* no doc claims Approved or Enabled for Path B execution.
* no doc implies production allowlist exists.
* no doc implies artifact/download/installer/Profile Inspector/.nip approval
  exists.
* no doc implies Default/Restore is available without capture.
* validators cover the current document set.
* counts remain 48/30/18 and 7 source-promoted intake candidates.

## Future Navigation Activation Path

Future live UI/docs navigation consumption would require:

* explicit UI phase.
* read-only docs/catalog integration approval.
* non-executing metadata source.
* validator confirming no action button enablement.
* runtime gate checks still deny execution.
* localization plan if exposed to users.
* review that source mirror files remain unchanged.
* review that counts remain separated.

Any future activation must be read-only until a separate implementation phase
approves exact runtime behavior. Navigation must not become a backdoor for
action enablement.

## Explicit Non-Actions

Phase 87 is documentation index/navigation design only.

* No live UI navigation implemented.
* No active docs runtime added.
* No active preview config created.
* No active UI config created.
* No active runtime config created.
* No production config or allowlist config created or changed.
* No production approval granted.
* No executable handler/module/action created.
* No tool or placeholder enabled.
* No runtime behavior changed.
* No source mirror files changed.
* No intake files changed.
* No legacy source-ultimate files changed.
* No artifact, download, installer, Profile Inspector, `.nip`, driver,
  profile, Windows Registry, file, process, reboot, Default, or Restore
  approval added.
* No AppX, service, task, cleanup, TrustedInstaller, or Safe Mode approval
  added.
* No DDU execution/download/artifact approval added.
* Standalone DDU not introduced.
* Loudness EQ and NVME Faster Driver remain deleted.
* Counts unchanged: 48 active tools, 30 implemented tools, 18
  deferred/placeholders, and 7 source-promoted intake candidates separate from
  official counts.

## Recommended Next Phase

Recommended next phase: **NVIDIA Path B Documentation Backlink Audit Design**.

That phase should remain documentation-only unless Yazan explicitly approves a
narrow foundation. It should audit whether all Path B documents link back to
the index and to their direct dependencies without creating active docs runtime,
UI config, runtime config, production config, modules, action buttons,
artifacts, allowlists, or execution behavior.
