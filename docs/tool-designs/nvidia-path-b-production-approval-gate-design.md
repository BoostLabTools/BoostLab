# NVIDIA Path B Production Approval Gate Design

## Purpose And Status

Phase 80 defines a future production approval gate design for NVIDIA App Path B.

This is production approval gate design only. No production approval is granted.
No production allowlist is created or changed. No production scope is approved.
No artifact, download, installer, Profile Inspector, `.nip`, driver/profile
write, registry write, file mutation, process, reboot, Default, or Restore
operation is approved. No implementation, placeholder, tool card, or runtime
behavior change was added.

NVIDIA App Path B exact required order:

`Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

Path relationship:

* Path A: `Driver Install Debloat & Settings`
* Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

Path B is for users who want to keep or use NVIDIA App features such as
recording or related NVIDIA App features. Future UI must preserve guided
separation between Path A and Path B and prevent accidental mixing unless later
explicitly approved.

## Approval Gate Model

Future gate states:

* `DraftOnly`
* `GateBlocked`
* `GateReadyForReview`
* `GateReviewRequired`
* `GateRejected`
* `ApprovedInFuturePhaseOnly`
* `NotApproved`

Do not use current `Approved` as an active status in this phase.

`ApprovedInFuturePhaseOnly` is descriptive only. It means a gate design could
imagine a later explicit approval phase; it must not be treated as production
approval, execution permission, visible UI enablement, or runtime readiness.

## Universal Approval Gates

Before any NVIDIA Path B draft entry can become production-approved in a later
phase, it must pass all applicable universal gates:

* Source mirror checksum validation.
* Tool/source path validation.
* Exact workflow step mapping.
* Exact Path B ordering validation.
* Path A/Path B mutual exclusion validation.
* Production Allowlist Governance approval.
* Artifact provenance approval if external artifact is involved.
* Installer descriptor approval if installer or executable launch is involved.
* Driver state capture/rollback approval if driver mutation is involved.
* NVIDIA profile state capture/restore approval if profile import/write is
  involved.
* File/registry state capture approval for registry/file changes.
* Process policy approval if process launch/close/wait is involved.
* Reboot/recovery approval if reboot/device restart/session transition is
  involved.
* Restore Selection integration if Restore is offered.
* Default vs Restore distinction documented.
* NVIDIA-only targeting validation.
* AMD/Intel GPU-specific branch rejection.
* Action Plan text approval.
* Confirmation UI approval.
* Activity Log and Latest Result schema approval.
* Verification validator approval.
* Failure/rollback behavior approval.

Missing any applicable gate keeps the entry `GateBlocked`, `GateReviewRequired`,
or `NotApproved`.

## Per-Step Approval Gates

### Driver Install Latest Gates

Future gates required before this step can be considered:

* NVIDIA driver source/provenance gate.
* Driver artifact hash/signature/size/destination gate.
* Installer execution descriptor gate.
* Driver state capture/rollback gate.
* Process handoff gate.
* Reboot/session handling gate.
* Post-install verification gate.
* UI disclosure and confirmation gate.

The AMD and Intel branches in the source remain out of NVIDIA Path B scope and
must be rejected unless Yazan changes GPU product scope later.

### Nvidia Settings Gates

Future gates required before this step can be considered:

* 7-Zip/archive provenance gate if preserved.
* NVIDIA Profile Inspector provenance and execution descriptor gate.
* Generated/imported `.nip` ownership and validation gate.
* Profile state capture before import gate.
* Profile restore model gate.
* Registry/file mutation scope gates.
* Control Panel launch handling gate.
* Process policy gate.
* Verification gate.
* UI disclosure and confirmation gate.

No `.nip` import, profile write, Profile Inspector execution, registry write,
or file mutation is approved by this design.

### Hdcp Gates

Future gates required before this step can be considered:

* Exact `RMHdcpKeyglobZero` registry scope gate.
* NVIDIA-only targeting gate.
* Registry capture/rollback gate.
* Content-protection/security review gate.
* Verification gate.
* Restore/Default decision gate.

### P0 State Gates

Future gates required before this step can be considered:

* Exact `DisableDynamicPstate` registry scope gate.
* NVIDIA-only targeting gate.
* Registry capture/rollback gate.
* Power/thermal/stability warning gate.
* Verification gate.
* Restore/Default decision gate.

### Msi Mode Gates

Future gates required before this step can be considered:

* Exact `MSISupported` interrupt registry scope gate.
* Display device instance validation gate.
* NVIDIA-only device targeting gate.
* Registry capture/rollback gate.
* Reboot/device restart disclosure gate.
* Verification gate.
* Restore/Default decision gate.

## Gate Checklist Table

| Gate id | Path B step number | Script name | Draft dependency | Required gate | Required evidence | Responsible foundation/document | Current status | Blocking reason | Future approval phase type | Validator requirement |
|---|---:|---|---|---|---|---|---|---|---|---|
| NPB-GATE-001 | 1 | Driver Install Latest | NPB-DRAFT-001 | NVIDIA driver source/provenance | Official source proof, URL/version model, response schema, artifact identity | NVIDIA Path B Artifact Provenance Review; Download Provenance and Installer Execution Policy | GateReviewRequired | Dynamic latest-driver source is not pinned or approved | Per-artifact approval phase | Verify source authority, version, URL, hash, signer, and size |
| NPB-GATE-002 | 1 | Driver Install Latest | NPB-DRAFT-002 | Driver artifact hash/signature/size/destination | Exact filename, SHA-256, signer, size bounds, bounded destination | Download Provenance and Installer Execution Policy | GateBlocked | Driver artifact provenance is incomplete | Per-artifact approval phase | Validate artifact metadata and destination bounds |
| NPB-GATE-003 | 1 | Driver Install Latest | NPB-DRAFT-003 | Installer execution descriptor | Exact command, args, signer, exit/handoff behavior, timeout | Installer Execution Policy; Process Handling Policy | GateBlocked | Installer execution descriptor is missing | Per-step production allowlist approval phase | Validate command descriptor and no URL execution |
| NPB-GATE-004 | 1 | Driver Install Latest | NPB-DRAFT-004 | Driver state capture/rollback | Current driver/device/package capture and rollback feasibility | Driver State Capture and Rollback | GateBlocked | Driver rollback scope is not approved | Driver rollback approval phase | Validate pre/post driver state and rollback plan |
| NPB-GATE-005 | 1 | Driver Install Latest | NPB-DRAFT-005 | Process handoff | Expected process identity, user handoff, timeout, log/result fields | Process Handling Policy | GateReviewRequired | Process launch policy is not approved | Process policy approval phase | Validate process identity and result schema |
| NPB-GATE-006 | 1 | Driver Install Latest | NPB-DRAFT-006 | Reboot/session handling | Reboot possibility, pending reboot, resume/recovery behavior | Reboot/Recovery Workflow | GateReviewRequired | Driver install reboot/session behavior is not approved | Reboot workflow approval phase | Validate reboot disclosure and recovery behavior |
| NPB-GATE-007 | 1 | Driver Install Latest | NPB-DRAFT-007 | Post-install verification | Artifact hash/signer plus detected NVIDIA driver version/state | Verification contract | GateBlocked | Verification checks are not implemented or approved | Per-step verification validator phase | Validate artifact and installed driver state |
| NPB-GATE-008 | 2 | Nvidia Settings | NPB-DRAFT-008 | 7-Zip/archive provenance | Immutable source, SHA-256, signer, size, license | NVIDIA Path B Artifact Provenance Review; Download Provenance and Installer Execution Policy | GateRejected | Mutable branch URL is not acceptable provenance | Per-artifact approval phase | Validate immutable source and artifact metadata |
| NPB-GATE-009 | 2 | Nvidia Settings | NPB-DRAFT-009 | 7-Zip installer descriptor | Exact `/S` command, exit codes, timeout, install verification | Installer Execution Policy | GateBlocked | Installer descriptor is not approved | Per-step production allowlist approval phase | Validate descriptor and execution constraints |
| NPB-GATE-010 | 2 | Nvidia Settings | NPB-DRAFT-010 | 7-Zip registry scope | Exact HKCU key/value/type/data and capture | File/Registry State Capture and Rollback | GateReviewRequired | Registry scope not approved | Per-step production allowlist approval phase | Validate key/value exactness and capture |
| NPB-GATE-011 | 2 | Nvidia Settings | NPB-DRAFT-011 | 7-Zip shortcut/file mutation scope | Exact path bounds, backup/quarantine, delete/move semantics | File/Registry State Capture and Rollback; Destructive Cleanup Policy | GateBlocked | File move/delete scope is not approved | Per-step production allowlist approval phase | Validate bounded paths and no broad deletion |
| NPB-GATE-012 | 2 | Nvidia Settings | NPB-DRAFT-012 | DRS file unblock scope | Exact DRS path, recursion bounds, no reparse traversal | File/Registry State Capture and Rollback | GateBlocked | Recursive file operation scope is not approved | Per-step production allowlist approval phase | Validate path bounds and file count/size limits |
| NPB-GATE-013 | 2 | Nvidia Settings | NPB-DRAFT-013 | NVIDIA NVTweak registry scope | Exact HKLM key/value/type/data and capture | File/Registry State Capture and Rollback; Driver State Capture and Rollback | GateReviewRequired | Driver registry scope not approved | Per-step production allowlist approval phase | Validate exact values and NVIDIA driver identity |
| NPB-GATE-014 | 2 | Nvidia Settings | NPB-DRAFT-014 | Display-class NVIDIA-only registry targeting | NVIDIA display identity, non-Configuration filter, capture | Driver State Capture and Rollback; File/Registry State Capture and Rollback | GateBlocked | Dynamic display-class enumeration lacks targeting approval | Per-step production allowlist approval phase | Validate NVIDIA-only instance selection |
| NPB-GATE-015 | 2 | Nvidia Settings | NPB-DRAFT-015 | NVIDIA tray registry scope | Exact HKCU key/value capture and key-delete semantics | File/Registry State Capture and Rollback | GateReviewRequired | Key-level delete needs restore design | Per-step production allowlist approval phase | Validate key/value capture and no unrelated value loss |
| NPB-GATE-016 | 2 | Nvidia Settings | NPB-DRAFT-016 | FTS `EnableGR535` registry scope | Exact control-set paths, types, data, capture | File/Registry State Capture and Rollback; Driver State Capture and Rollback | GateReviewRequired | Multiple control-set paths are not approved | Per-step production allowlist approval phase | Validate exact paths and post-state |
| NPB-GATE-017 | 2 | Nvidia Settings | NPB-DRAFT-017 | NVIDIA Profile Inspector provenance | Immutable source, SHA-256, signer, size, license | NVIDIA Path B Artifact Provenance Review; Download Provenance and Installer Execution Policy | GateRejected | Mutable branch URL is not acceptable provenance | Per-artifact approval phase | Validate trusted source and artifact metadata |
| NPB-GATE-018 | 2 | Nvidia Settings | NPB-DRAFT-018 | Generated `.nip` ownership and validation | Content hash, bounded path, profile scope, cleanup/quarantine | NVIDIA Profile State Capture Model | GateBlocked | Generated profile artifact policy is not approved | NVIDIA profile import/restore approval phase | Validate generated `.nip` identity and scope |
| NPB-GATE-019 | 2 | Nvidia Settings | NPB-DRAFT-019 | Profile import and pre-capture | Pre-capture, Inspector descriptor, import verification, restore eligibility | NVIDIA Profile State Capture Model; Process Handling Policy | GateBlocked | Profile import without approved pre-capture is denied | NVIDIA profile import/restore approval phase | Validate capture, import, and restore eligibility |
| NPB-GATE-020 | 2 | Nvidia Settings | NPB-DRAFT-020 | NVIDIA Control Panel launch handling | App identity, launch result, missing-app behavior | Process Handling Policy | GateReviewRequired | Local app launch policy is not approved | Process policy approval phase | Validate package identity and handoff logging |
| NPB-GATE-021 | 2 | Nvidia Settings | NPB-DRAFT-021 | Settings/profile verification | Registry/profile/generated file/import result checks | NVIDIA Profile State Capture Model; Verification contract | GateBlocked | Verification model is not approved | Per-step verification validator phase | Validate every source-defined setting and profile effect |
| NPB-GATE-022 | 3 | Hdcp | NPB-DRAFT-022 | Exact `RMHdcpKeyglobZero` registry scope | Exact value/type/data, NVIDIA display identity, capture | File/Registry State Capture and Rollback; Driver State Capture and Rollback | GateReviewRequired | Dynamic display-class target not approved | Per-step production allowlist approval phase | Validate exact target and capture |
| NPB-GATE-023 | 3 | Hdcp | NPB-DRAFT-023 | Content-protection/security review | Risk classification, warning text, confirmation, user-visible effects | Production Allowlist Governance | GateReviewRequired | HDCP risk review is not complete | Per-step production allowlist approval phase | Validate warning, confirmation, and risk disclosure |
| NPB-GATE-024 | 3 | Hdcp | NPB-DRAFT-024 | HDCP verification | Readback of `RMHdcpKeyglobZero` on approved NVIDIA targets | Verification contract | GateBlocked | Verification checks not approved | Per-step verification validator phase | Validate expected values on every approved target |
| NPB-GATE-025 | 4 | P0 State | NPB-DRAFT-025 | Exact `DisableDynamicPstate` registry scope | Exact value/type/data, NVIDIA display identity, capture | File/Registry State Capture and Rollback; Driver State Capture and Rollback | GateReviewRequired | Dynamic display-class target not approved | Per-step production allowlist approval phase | Validate exact target and capture |
| NPB-GATE-026 | 4 | P0 State | NPB-DRAFT-026 | Power/thermal/stability warning | Risk classification, warning text, confirmation | Driver State Capture and Rollback; Production Allowlist Governance | GateReviewRequired | Power/thermal risk design is incomplete | Per-step production allowlist approval phase | Validate warning, confirmation, and risk disclosure |
| NPB-GATE-027 | 4 | P0 State | NPB-DRAFT-027 | P0 verification | Readback of `DisableDynamicPstate` on approved NVIDIA targets | Verification contract | GateBlocked | Verification checks not approved | Per-step verification validator phase | Validate expected values on every approved target |
| NPB-GATE-028 | 5 | Msi Mode | NPB-DRAFT-028 | Exact `MSISupported` interrupt registry scope | NVIDIA device instance, exact path, capture | File/Registry State Capture and Rollback; Driver State Capture and Rollback | GateBlocked | Source enumerates all display devices; NVIDIA-only targeting not approved | Per-step production allowlist approval phase | Validate NVIDIA hardware/vendor identity and path bounds |
| NPB-GATE-029 | 5 | Msi Mode | NPB-DRAFT-029 | Reboot/device restart disclosure | Reboot or device restart impact, pending restart/recovery guidance | Reboot/Recovery Workflow | GateReviewRequired | Restart implications are not approved | Reboot workflow approval phase | Validate disclosure and recovery guidance |
| NPB-GATE-030 | 5 | Msi Mode | NPB-DRAFT-030 | MSI verification | Readback of `MSISupported` on approved NVIDIA display instances | Verification contract | GateBlocked | Verification checks not approved | Per-step verification validator phase | Validate expected values on every approved target |

## Rejection Criteria

Future approval must be rejected if any of these are true:

* Missing or mismatched source checksum.
* Unbounded or wildcard registry scope.
* Unknown or non-NVIDIA device target.
* AMD/Intel GPU-specific target.
* Mutable or unpinned external artifact.
* Missing SHA-256 or signer validation where required.
* Executing from untracked temp path.
* Profile Inspector without approved provenance.
* `.nip` import without pre-capture.
* Registry/file mutation without rollback capture.
* Driver mutation without driver rollback model.
* Reboot behavior without Reboot/Recovery approval.
* Process behavior without Process Handling approval.
* Path A/Path B mixed workflow without explicit approval.
* Missing Action Plan or confirmation text.
* Missing verification validator.
* Ambiguous Restore/Default semantics.

## Future Approval Phase Sequence

Future sequence before any Path B implementation attempt:

1. Per-artifact approval phase for Driver Install Latest / NVIDIA Inspector /
   7-Zip where applicable.
2. NVIDIA profile import/restore approval phase.
3. Per-step production allowlist approval phase.
4. Per-step verification validator phase.
5. Path B workflow gating/runtime design phase.
6. Path B UI implementation phase.
7. Individual per-step implementation attempts.
8. Final Path B workflow integration validation.

Each phase must remain narrow. A later phase that approves one artifact or one
scope must not imply approval for the entire Path B workflow.

## Relationship To Existing Documents

This gate design relates to:

* NVIDIA Path B Catalog Design
* NVIDIA Path B Scope Design
* NVIDIA Path B Production Allowlist Planning
* NVIDIA Path B Artifact Provenance Review
* NVIDIA Profile State Capture Model
* NVIDIA Path B UI Workflow Design
* NVIDIA Path B Draft Allowlist Proposal
* Production Allowlist Governance
* Download Provenance and Installer Execution Policy
* Driver State Capture and Rollback
* File/Registry State Capture and Rollback
* Process Handling Policy
* Reboot/Recovery Workflow
* Restore Selection UI / Runtime

This document defines gates only. It does not modify any policy file or approve
any draft entry.

## Explicit Non-Actions

Phase 80 is gate design only.

* No production approval granted.
* No production config or allowlist config created or changed.
* No production scope approved.
* No artifact, download, installer, Profile Inspector, `.nip`, driver, profile
  write, profile import, profile export, registry, file, AppX, service, task,
  process, cleanup, reboot, TrustedInstaller, Safe Mode, Default, or Restore
  approval was added.
* No source mirror files changed.
* No intake files changed.
* No legacy source-ultimate files changed.
* No executable module created.
* No tool or placeholder enabled.
* No runtime behavior changed.
* No DDU execution, DDU download, or DDU artifact approval was added.
* Standalone DDU was not introduced.
* Loudness EQ and NVME Faster Driver remain deleted.
* Counts remain unchanged: 48 active tools, 30 implemented tools, 18
  deferred/placeholders, and 7 source-promoted intake candidates separate from
  official counts.

## Recommended Next Phase

Recommended next phase: **NVIDIA Path B Runtime Gating Design**.

That phase should remain design-only unless Yazan explicitly approves a narrow
runtime foundation. It should define how a future runtime would read approved
Path B workflow gates, block non-approved steps, report missing gates, and
prevent Path A/Path B mixing without enabling any Path B tool behavior.

Phase 81 records that design in
`docs/tool-designs/nvidia-path-b-runtime-gating-design.md`. It adds no runtime
gate implementation, production config, production approval, UI implementation,
tool card, placeholder enablement, or Path B execution behavior.

Phase 82 records non-executing Workflow Registry schema design in
`docs/tool-designs/nvidia-path-b-non-executing-workflow-registry-schema-design.md`.
It does not create an active workflow registry, production config, allowlist
config, executable handler, UI implementation, or Path B runtime behavior.

Phase 87 records documentation index/navigation design in
`docs/tool-designs/nvidia-path-b-documentation-index-navigation-design.md`. It
provides a documentation-only navigation layer and grants no production
approval.

Phase 88 records documentation backlink audit design in
`docs/tool-designs/nvidia-path-b-documentation-backlink-audit-design.md`. It
defines future backlink audit rules without creating a live backlink auditor,
active docs runtime, active config, production approval, or Path B execution
behavior.

Phase 89 records governance freeze review in
`docs/tool-designs/nvidia-path-b-governance-freeze-review.md`. It freezes the
Path B documentation set as design-only and non-executing without creating
active governance runtime, production approval, UI approval, runtime approval,
or Path B execution behavior.
