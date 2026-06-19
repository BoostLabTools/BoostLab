# NVIDIA Path B Catalog Design

## Purpose

Phase 73 defines NVIDIA App Path B as an ordered workflow catalog.

This is not an implementation phase. It does not add tool cards, modules,
runtime behavior, action buttons, production allowlists, artifact approvals,
downloads, installers, driver operations, NVIDIA profile writes, Default
behavior, or Restore behavior.

The catalog exists to preserve the original Ultimate author's alternate NVIDIA
workflow and Yazan's required ordering decision before any future BoostLab UI
or implementation phase tries to expose these scripts.

Official BoostLab counts remain unchanged:

* Active tools: **48**
* Implemented tools: **30**
* Deferred/placeholders: **14**
* Source-promoted intake candidates: **7 separate from official counts**

Phase 124 current-state note: `Driver Install Latest` has since been promoted
as a source-equivalent, branch-selected runtime for its source-defined NVIDIA,
AMD, and INTEL branches with BoostLab GUI confirmation and test-safe executor
injection. `Nvidia Settings` remains an active controlled manual-handoff tool.
This does not approve reusable/global NVIDIA, AMD, or INTEL artifact
provenance, standalone driver artifacts, 7-Zip download/install, NVIDIA Profile
Inspector download/execution, `.nip` import/export, production allowlists,
NVIDIA registry/profile mutation beyond implemented source-equivalent tools,
Control Panel launch, external process launch outside implemented tools,
Default, Restore, or the remaining Path B steps.

Phase 95 current-state note: `Hdcp` has since been promoted as Path B step 3
with controlled NVIDIA-only registry targeting. It preserves the source-defined
`RMHdcpKeyglobZero` Apply value `DWORD 1` and Default value `DWORD 0` only after
source checksum validation, NVIDIA-only target discovery, registry state capture,
and verification. Restore remains unavailable without a selected captured-state
restore flow.

Phase 96 current-state note: `P0 State` has since been promoted as Path B step
4 with controlled NVIDIA-only registry targeting. It preserves the
source-defined `DisableDynamicPstate` Apply value `DWORD 1` and Default value
`DWORD 0` only after source checksum validation, NVIDIA-only target discovery,
registry state capture, and verification. Restore remains unavailable without a
selected captured-state restore flow.

Phase 97 current-state note: `Msi Mode` has since been promoted as Path B step
5 with controlled NVIDIA-only display-device Enum registry targeting. It
preserves the source-defined `MSISupported` Apply value `DWORD 1` and Default
value `DWORD 0` only after source checksum validation, NVIDIA-only target
discovery, registry state capture, and verification. Restore remains unavailable
without a selected captured-state restore flow.

## Path A vs Path B

BoostLab currently has one approved active Graphics catalog path:

* Path A: `Driver Install Debloat & Settings`

The Phase 72 source-promotion mirror also contains the five scripts that form
the alternate NVIDIA App workflow:

* Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

Path A is the existing debloat/configuration workflow.

Path B is the alternate NVIDIA workflow for users who want to keep or use
NVIDIA App features such as recording or related NVIDIA App features.

Future UI must guide users to choose one workflow intentionally. Path A and
Path B must be presented as mutually guided workflows, not as unrelated
unordered Graphics tools. Future UI must warn against and prevent accidental mixing unless a later explicit design approves a safe mixed workflow.

Path B steps must preserve this exact order:

1. `Driver Install Latest`
2. `Nvidia Settings`
3. `Hdcp`
4. `P0 State`
5. `Msi Mode`

## Ordered Path B Catalog

| Path B step | Display name | Source mirror path | SHA-256 | Original Ultimate relative path | Stage | Relationship | Likely future design requirement | Major risk groups | Can be implemented now | Why not implemented now |
|---:|---|---|---|---|---|---|---|---|---|---|
| 1 | Driver Install Latest | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1` | `41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F` | `5 Graphics/2 Driver Install Latest.ps1` | Graphics | First Path B step. Must complete before NVIDIA settings/profile steps are considered. | Phase 124 source-equivalent branch runtime is implemented for NVIDIA, AMD, and INTEL in this tool only. It preserves admin/internet checks, dynamic vendor lookup/download/page handoff, installer/process launch, and source operation order with explicit BoostLab confirmation. | Downloads, installer launch, driver install/update, NVIDIA API use, AMD page scrape, Intel driver page handoff, vendor branch selection, admin execution, process handoff, rollback/support boundaries. | Source-equivalent controlled runtime active | No reusable/global artifact provenance, production allowlist, standalone driver artifact approval, Default, Restore, or cross-tool AMD/Intel scope is approved. |
| 2 | Nvidia Settings | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1` | `903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5` | `5 Graphics/4 Nvidia Settings.ps1` | Graphics | Runs after driver installation in Path B. Prepares NVIDIA registry/profile settings before focused display-device steps. | Controlled manual handoff is implemented; Auto remains blocked until 7-Zip, NVIDIA Profile Inspector, `.nip`, profile capture/restore, registry/file rollback, process, and verification approvals exist. | Downloads, installer execution, registry mutation, generated `.nip` profile data, NVIDIA Profile Inspector execution, Control Panel launch, file cleanup, Default behavior. | Manual handoff only | Required artifacts, profile import rules, registry scopes, generated-artifact ownership, process handling, verification, and Default/Restore semantics are not approved. |
| 3 | Hdcp | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1` | `5C350D28F795D678051E6088F34968DF8D90B3D9024F558C5FAFB2899D1A906A` | `5 Graphics/5 Hdcp.ps1` | Graphics | Runs after broad NVIDIA settings. Applies a focused NVIDIA display-class registry behavior before P0 State. | Controlled registry implementation is active for Analyze, Apply, Default, and blocked Restore. | NVIDIA display registry discovery, HKLM registry mutation, display driver state, source-defined Default behavior, verification and rollback boundaries. | Controlled implementation active | Apply/Default require checksum validation, NVIDIA-only targets, capture before mutation, and verification; Restore remains unavailable without selected captured state. |
| 4 | P0 State | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1` | `382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC` | `5 Graphics/6 P0 State.ps1` | Graphics | Runs after Hdcp and before Msi Mode. Applies another focused NVIDIA display-class registry behavior. | Controlled registry implementation is active for Analyze, Apply, Default, and blocked Restore. | NVIDIA display registry discovery, HKLM registry mutation, display driver state, Default behavior, verification and rollback boundaries. | Controlled implementation active | Apply/Default require checksum validation, NVIDIA-only targets, capture before mutation, and verification; Restore remains unavailable without selected captured state. |
| 5 | Msi Mode | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1` | `94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7` | `5 Graphics/7 Msi Mode.ps1` | Graphics | Final Path B step. Must not be exposed as an unordered independent graphics tweak. | Controlled registry implementation is active for Analyze, Apply, Default, and blocked Restore. | NVIDIA display-device Enum registry discovery, interrupt-management registry mutation, display driver state, Default behavior, verification and rollback boundaries. | Controlled implementation active | Apply/Default require checksum validation, NVIDIA-only targets, capture before mutation, and verification; Restore remains unavailable without selected captured state. |

## Required Future Design Work

### Driver Install Latest

Phase 124 implements the source-equivalent Driver Install Latest runtime for
NVIDIA, AMD, and INTEL branches in this tool only. Future work here is limited
to any later reusable/global artifact provenance or rollback model Yazan might
approve; it is not required for the current source-equivalent branch runtime.

Required future approvals include:

* Any reusable/global artifact provenance approval for vendor driver artifacts.
* Any future production allowlist entry for standalone driver artifacts.
* Any captured-state driver rollback/support model beyond source handoff.
* Any Default or Restore behavior, which the source does not define.

### Nvidia Settings

Future work must define a driver/profile/settings design because the source
downloads and installs 7-Zip, downloads NVIDIA Profile Inspector, writes NVIDIA
registry values, creates `.nip` profile content, imports it through Inspector,
and opens NVIDIA Control Panel.

Required future approvals include:

* Artifact provenance for 7-Zip and NVIDIA Profile Inspector if preserved.
* Installer execution descriptor for 7-Zip if preserved.
* Generated `.nip` ownership, hashing, cleanup, and profile-import policy.
* Exact NVIDIA registry scopes and file scopes.
* NVIDIA Control Panel launch policy.
* Default versus Restore semantics for registry/profile state.

### Hdcp

Future work must define an NVIDIA display-class registry design because the
source writes `RMHdcpKeyglobZero` under NVIDIA display-class registry
instances.

Required future approvals include:

* Exact target discovery rules.
* NVIDIA-only product-scope validation.
* Registry state capture before mutation.
* Post-mutation verification.
* Default versus Restore semantics.

### P0 State

Phase 96 implemented a controlled NVIDIA display-class registry path for the
source-defined `DisableDynamicPstate` behavior. Future work for this step is
limited to captured-state Restore selection and any later workflow UI that
links Path B steps together.

The current implementation requires:

* Exact target discovery rules.
* NVIDIA-only product-scope validation.
* Registry state capture before mutation.
* Post-mutation verification.
* Default versus Restore semantics.

### Msi Mode

Phase 97 implemented a controlled NVIDIA display-device Enum registry path for
the source-defined `MSISupported` behavior. Future work for this step is limited
to captured-state Restore selection and any later workflow UI that links Path B
steps together.

The current implementation requires:

* Exact display-device identity rules.
* NVIDIA-only GPU target validation.
* AMD/Intel exclusion or NotApplicable reporting.
* Registry state capture before mutation.
* Post-mutation verification.
* Default versus Restore semantics.

## Catalog Metadata Design

Before implementation or UI exposure, each future Path B catalog entry should
define:

* `WorkflowId`
* `WorkflowName`
* `WorkflowPathLabel`
* `Stage`
* `StepNumber`
* `StepId`
* `DisplayName`
* `SourceMirrorPath`
* `SourceChecksum`
* `SourceRelativePath`
* `PrerequisiteStep`
* `NextStep`
* `MutuallyExclusiveWorkflowId`
* `TargetGpuVendor`
* `NvidiaAppCompatibilityNote`
* `ExpectedUserIntent`
* `RiskLevel`
* `RequiredFoundationApprovals`
* `RequiredFutureDesignDocument`
* `ImplementationStatus`
* `UIWarningText`
* `ActionPlanRequirements`
* `ActivityLogRequirements`
* `LatestResultExpectations`
* `DefaultRestoreStatus`
* `ProvenanceStatus`
* `ProductionAllowlistStatus`

If a future config file is created for this metadata, it must remain
catalog-only until a later explicit phase wires UI or implementation behavior.
`CatalogOnly`, `DesignPending`, or `NotImplemented` status values must not be
treated as runtime execution permission.

## UI/UX Guidance

Future UI should present Path A and Path B as guided workflow choices.

Path B steps must be shown in this exact order:

`Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

The user should not accidentally run Path A and Path B as if they are
independent unordered tools. Path B should clearly explain that it is for users
who want NVIDIA App features such as recording or related NVIDIA App features.

Any future mixed Path A/Path B workflow requires explicit design approval.

Until future implementation phases approve any remaining workflow UI, the UI
status for unimplemented or design-only Path B behavior must remain
`Not implemented / design pending` or equivalent visual-only text. No visible
action button should imply that unapproved source-promoted behavior is safe to
run.

## Related Source-Promoted Scripts Outside Path B

### Driver Clean

`Driver Clean` exists in the source-promotion mirror as a Yazan-approved intake
exception despite DDU usage.

It is not one of the five ordered NVIDIA App Path B steps in this catalog. It
does not approve standalone DDU, DDU execution, DDU download, DDU artifact
provenance, Safe Mode behavior, RunOnce behavior, reboot behavior, driver
cleanup behavior, or production scopes.

### BitLocker

`BitLocker` exists in the source-promotion mirror, but it is unrelated to NVIDIA Path B.

It remains pending future security-sensitive design and must not be treated as
part of this Graphics workflow catalog.

## Non-Actions

Phase 73 is catalog/design only.

* No tools were implemented.
* No placeholders or tool cards were enabled.
* No executable modules were created for Path B scripts.
* No runtime behavior changed.
* No source mirror files were moved, renamed, or modified.
* No intake files were moved, renamed, or modified.
* No production approvals were added.
* No driver, download, install, profile write, registry write, file write,
  AppX, service, scheduled task, process handling, cleanup, reboot,
  TrustedInstaller, Safe Mode, Default, or Restore scope was approved.
* No DDU execution, DDU download, or DDU artifact approval was added.
* Standalone DDU was not introduced.
* Loudness EQ and NVME Faster Driver remain deleted.
* Counts remain unchanged: 48 active tools, 30 implemented tools, 18
  deferred/placeholders, and 7 source-promoted intake candidates separate from
  official counts.

## Recommended Next Phase

Recommended next phase: **NVIDIA Path B Scope Design**.

That phase should remain design-only unless Yazan explicitly approves a
narrower implementation scope. It should create per-step design documents or a
single Path B scope design that covers artifact provenance, NVIDIA-only
targeting, driver/profile state capture, registry scopes, generated artifacts,
Action Plan confirmation, verification, Default/Restore semantics, and UI
workflow gating.

Phase 74 records that scope design in
`docs/tool-designs/nvidia-path-b-scope-design.md`. It remains non-executing and
approves no production scope.

Phase 75 records non-approved production allowlist planning in
`docs/tool-designs/nvidia-path-b-production-allowlist-planning.md`. It remains
planning-only and creates no production config.

Phase 76 records non-approved artifact provenance review in
`docs/tool-designs/nvidia-path-b-artifact-provenance-review.md`. It remains
review-only and creates no artifact approval or production provenance config.

Phase 77 records the inert NVIDIA profile state capture model in
`docs/nvidia-profile-state-capture-model.md`. It is foundation-only and does not
enable Path B behavior.

Phase 78 records future Path A / Path B UI workflow design in
`docs/nvidia-path-b-ui-workflow-design.md`. It keeps Path B catalog-only and
does not enable tool cards.

Phase 79 records non-approved draft allowlist proposals in
`docs/tool-designs/nvidia-path-b-draft-allowlist-proposal.md`. It creates no
production allowlist config and approves no scope.

Phase 80 records production approval gate design in
`docs/tool-designs/nvidia-path-b-production-approval-gate-design.md`. It defines
future gate criteria only and grants no production approval.

Phase 81 records runtime gating design in
`docs/tool-designs/nvidia-path-b-runtime-gating-design.md`. It defines future
gate states and result schema without adding runtime behavior.

Phase 82 records non-executing Workflow Registry schema design in
`docs/tool-designs/nvidia-path-b-non-executing-workflow-registry-schema-design.md`.
It defines future metadata fields for Path B without creating an active
workflow registry, production config, UI implementation, or tool behavior.

Phase 83 records readiness badge design in
`docs/tool-designs/nvidia-path-b-readiness-badge-design.md`. It keeps Path B
catalog-only and defines future badge language without adding active UI config,
runtime behavior, production approval, or tool behavior.

Phase 84 records path conflict copy/status text design in
`docs/tool-designs/nvidia-path-b-path-conflict-copy-status-text-design.md`. It
keeps Path B catalog-only and defines future user-facing status copy without
adding live UI strings, localization files, runtime behavior, production
approval, or tool behavior.

Phase 85 records non-executing catalog preview data design in
`docs/tool-designs/nvidia-path-b-non-executing-catalog-preview-data-design.md`.
It defines future preview metadata for catalog display without creating a live
runtime catalog, active UI config, active runtime config, production approval,
or tool behavior.

Phase 86 records preview data integrity/drift rules design in
`docs/tool-designs/nvidia-path-b-preview-data-integrity-drift-rules-design.md`.
It defines future integrity and drift checks for preview metadata without
creating active catalog config, runtime checks, production approval, or tool
behavior.

Phase 87 records documentation index/navigation design in
`docs/tool-designs/nvidia-path-b-documentation-index-navigation-design.md`. It
provides a documentation-only entry point for the Path B doc set and creates no
live catalog navigation or runtime behavior.

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
