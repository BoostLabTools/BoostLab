# Final Deferred Tools Readiness Matrix

## Purpose

This matrix is the final Phase 65 readiness snapshot for the current BoostLab deferred queue.

It uses the completed deferred execution plan, readiness review, provenance reviews, and tool-specific scope designs to identify what remains blocked before any deferred tool can be safely implemented.

This document does not approve production scopes, allowlists, artifacts, installer execution, TrustedInstaller execution, Safe Mode workflows, cleanup targets, driver targets, package targets, or tool behavior.

## Current Inventory

* Active tools: **55**
* Implemented tools: **47**
* Deferred/placeholders: **8**
* Source-promoted mirror files: **7** (`docs/missing-ultimate-scripts-intake-review.md`)
* Remaining unimplemented source-promoted intake candidates: **0**
* Design/review coverage: **8/8 deferred tools covered**
* Production allowlists/scopes approved by this phase: **0**
* Tool behavior changed by this phase: **No**
* `source-ultimate/` modified by this phase: **No**

Phase 70 note: `Driver Clean.ps1` is a Yazan-approved intake exception despite DDU usage. The original intake exception did not approve standalone DDU, DDU execution, downloads, artifacts, production scopes, or tool behavior.

Phase 71 note: source-promotion planning for the seven intake scripts lives in `docs/missing-scripts-source-promotion-decision.md`. The recommended future strategy is a source-promotion mirror under `source-ultimate/_intake-promoted/Ultimate/`, with no count or behavior changes in this phase.

Phase 72 note: the seven intake scripts were copied into `source-ultimate/_intake-promoted/Ultimate/` as source-promoted mirror references. Official active/deferred counts remain unchanged, and no tool behavior or production approval was added.

Phase 73 note: NVIDIA App Path B catalog planning lives in `docs/nvidia-path-b-catalog-design.md`. It documents Path A versus Path B and preserves the required five-step Path B order as catalog-only planning, with no implementation or production approval.

Phase 74 note: NVIDIA App Path B scope design lives in `docs/tool-designs/nvidia-path-b-scope-design.md`. It inventories the five source-promoted scripts and documents future foundations without enabling implementation.

Phase 75 note: NVIDIA App Path B production allowlist planning lives in `docs/tool-designs/nvidia-path-b-production-allowlist-planning.md`. It documents candidate allowlist categories and unresolved approval questions without adding production scopes.

Phase 76 note: NVIDIA App Path B artifact provenance review lives in `docs/tool-designs/nvidia-path-b-artifact-provenance-review.md`. It documents artifact evidence and approval blockers without approving artifacts, downloads, installers, production scopes, or provenance config.

Phase 124 note: `Driver Install Latest` is implemented as a source-equivalent branch-selected runtime for its source-defined NVIDIA, AMD, and INTEL branches in this tool only. `Nvidia Settings` remains a controlled manual-handoff active tool for Path B step 2. No reusable/global artifact provenance, standalone driver artifact approval, 7-Zip download/install, NVIDIA Profile Inspector download/execution, `.nip` import/export, production allowlist, cross-tool AMD/Intel scope, Default, or Restore was approved.

Phase 77 note: NVIDIA profile state capture model lives in `docs/nvidia-profile-state-capture-model.md`. It documents profile capture/restore/import/export requirements without approving NVIDIA Profile Inspector execution, `.nip` operations, profile writes, runtime behavior, or production scopes.

Phase 78 note: NVIDIA Path B UI workflow design lives in `docs/nvidia-path-b-ui-workflow-design.md`. It documents future Path A versus Path B choice, ordered stepper, gating, messaging, and result/log expectations without adding UI implementation or enabling Path B behavior.

Phase 79 note: NVIDIA Path B draft allowlist proposal lives in `docs/tool-designs/nvidia-path-b-draft-allowlist-proposal.md`. It structures future candidate scopes while keeping every entry non-approved and adding no production allowlist config.

Phase 80 note: NVIDIA Path B production approval gate design lives in `docs/tool-designs/nvidia-path-b-production-approval-gate-design.md`. It defines future gate criteria for draft entries without granting production approval or creating production config.

Phase 81 note: NVIDIA Path B runtime gating design lives in `docs/tool-designs/nvidia-path-b-runtime-gating-design.md`. It defines future gate states and result schema without implementing runtime gates, creating production config, granting production approval, enabling UI, or changing tool behavior.

Phase 82 note: NVIDIA Path B non-executing Workflow Registry schema design lives in `docs/tool-designs/nvidia-path-b-non-executing-workflow-registry-schema-design.md`. It defines future metadata fields and pseudo-schema only; it creates no active workflow registry, runtime config, production config, UI implementation, or tool behavior.

Phase 92 note: `Driver Clean` was first implemented as controlled manual handoff only.

Phase 120 note: `Driver Clean` now preserves the exact source-equivalent Auto and Manual workflow after BoostLab confirmation. It downloads the source-defined 7-Zip and DDU artifacts, installs/configures 7-Zip, extracts/configures DDU, captures and sets the source driver-search policy value, creates the source-defined RunOnce/Safe Mode scripts, enables Safe Mode with `bcdedit`, and restarts. This approval is Driver Clean-specific only and does not approve standalone DDU or DDU use outside Driver Clean.

Phase 124/94 note: `Driver Install Latest` is implemented as source-equivalent branch-selected runtime for Path B step 1 with explicit BoostLab confirmation and test-safe executor injection. `Nvidia Settings` remains controlled manual handoff only for Path B step 2. Driver Install Latest no longer reports ManualHandoffOnly; it preserves the source-defined NVIDIA, AMD, and INTEL branches for this tool only while leaving reusable/global artifact approvals, Default, Restore, and cross-tool AMD/Intel scope unapproved.

Phase 95 note: `HDCP` is implemented as Path B step 3 using controlled
NVIDIA-only registry targeting. It verifies the source mirror checksum, discovers
only the source display-class registry scope, captures `RMHdcpKeyglobZero` before
mutation, applies source-defined `DWORD 1`, defaults to source-defined `DWORD 0`,
verifies results, and keeps Restore unavailable without selected captured state.

Phase 96 note: `P0 State` is implemented as Path B step 4 using controlled
NVIDIA-only registry targeting. It verifies the source mirror checksum, discovers
only the source display-class registry scope, captures `DisableDynamicPstate`
before mutation, applies source-defined `DWORD 1`, defaults to source-defined
`DWORD 0`, verifies results, and keeps Restore unavailable without selected
captured state.

Phase 97 note: `Msi Mode` is implemented as Path B step 5 using controlled
NVIDIA-only display-device Enum registry targeting. It verifies the source
mirror checksum, discovers source-targeted display-device interrupt-management
registry scopes, captures `MSISupported` before mutation, applies
source-defined `DWORD 1`, defaults to source-defined `DWORD 0`, verifies
results, and keeps Restore unavailable without selected captured state.

## Coverage Summary

The current deferred queue has complete documentation coverage:

* Scope or scope/provenance design covered tools: **8**
* Standalone provenance review covered tools: **0**
* Manual-handoff implemented with Auto provenance review still blocking automation: **6**
* Total deferred tools covered by design or review: **8/8**

Scope or scope/provenance design coverage:

* `bloatware`
* `game-bar`
* `control-panel-settings`
* `cleanup`
* `resizable-bar-assistant`
* `services-optimizer`
* `timer-resolution-assistant`
* `defender-optimize-assistant`

Standalone provenance review coverage:


## Matrix

| Tool name | Tool id | Stage | Source path | Source checksum | Current status | Design/review document | Primary blocker category | Foundations already available | Foundations still missing | Production allowlists/scopes required | Default | Restore | Windows 10 branch-level scope | NVIDIA/AMD/Intel product scope | Risk level | Near-term implementation candidate | Recommended next action | Suggested phase priority |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Installers | `installers` | Installers | `source-ultimate/4 Installers/1 Installers.ps1` | `1065D64183457D4E7B28EA78DDE41525EC8F7C4A4BCA12D29B70D991141C0C67` | Implemented selected-app queue with Yazan final app-list exception | `docs/tool-designs/installers-scope-provenance-design.md`; `docs/migrations/installers.md` | Removed app choices excluded by Yazan final scope; Default/Restore unavailable | Download provenance foundation; installer policy; service rollback foundation; file/registry rollback foundation; cleanup policy; Phase 119 retained-app descriptors | Restore remains unavailable without captured package/file/registry/service/task/shortcut/config state; removed menu entries remain unavailable | No reusable/global production allowlists; retained-app operations are module-scoped and source-derived | Unavailable | Restore unavailable until captured-state restore contract exists | No Windows 10 optimization branch should be ported | NVIDIA-only removed entries Frame View/Nvidia App are excluded; AMD/Intel remain unsupported | High | Complete for Yazan-scoped retained app list | Maintain retained catalog; future work would need explicit Restore contract only | P7 |
| Driver Install Debloat & Settings | `driver-install-debloat-settings` | Graphics | `source-ultimate/5 Graphics/1 Driver Install Debloat & Settings.ps1` | `E69EFF538E7CE6108233C525A2BB88BA2D549CE6954AE751BE7BED778271C26F` | Implemented source-equivalent NVIDIA/AMD/INTEL controlled runtime in Phase 123 | `docs/tool-designs/driver-install-debloat-settings-scope-provenance-design.md`; `docs/migrations/driver-install-debloat-settings.md` | Default/Restore unavailable without captured-state restore contract | Phase 123 branch descriptors, confirmation, logging, test-safe executor injection; download provenance foundation; installer policy; driver rollback foundation; reboot recovery foundation; AppX foundation; cleanup policy; file/registry rollback foundation; Phase 122 approves NVIDIA/AMD/INTEL branches for this tool only | Future Restore still needs selected captured-state records for driver/profile/package/registry/file/service/task/process/reboot state | No reusable/global production allowlist; no project-wide AMD/Intel scope expansion | Unavailable | Restore unavailable until selected captured-state restore contract exists | Shared Windows behavior only; Windows 10 optimization branches unsupported | Tool-specific exception: NVIDIA/AMD/INTEL branches approved for this tool only; project-wide AMD/Intel scope unchanged | High | Complete as Yazan-accepted near parity | Maintain exact three-branch descriptors; future work would need explicit Restore contract only | P13 |
| DirectX | `directx` | Graphics | `source-ultimate/5 Graphics/2 DirectX.ps1` | `17051A2F0F7A0CF16BE525121720406E8F1630C94E5977A7CD4C18652A87EE05` | Implemented source-equivalent controlled runtime in Phase 129 | `docs/directx-provenance-review.md`; `docs/migrations/directx.md` | Restore unavailable without captured installer/artifact/registry/shortcut/temp state | Source-equivalent runtime implemented with confirmation, operation descriptors, test-safe executor injection, download provenance foundation, installer policy, file/registry rollback foundation, and cleanup policy | Future mirror/provenance work still needs immutable source URLs, exact hash/size/signer evidence, extracted `DXSETUP.exe` provenance, installer descriptor, and temp ownership scopes before reusable artifact approval or mirror substitution | No artifact provenance approval; no production allowlist; future mirror/provenance or Restore contract only | Unavailable | Restore unavailable until captured-state restore contract exists | No Windows 10 branch issue documented | Not GPU-specific | High | Complete as Yazan-accepted near parity | Maintain source-equivalent runtime; future work is mirror/provenance/Restore only | P10 |
| Visual C++ | `visual-cpp` | Graphics | `source-ultimate/5 Graphics/3 C++.ps1` | `7ACB1F25ECFEEAD83FA389E2D0C1FEEF12232C4E9A740CB5DE64A326FFD38C09` | Implemented source-equivalent controlled runtime in Phase 130 | `docs/visual-cpp-provenance-review.md`; `docs/migrations/visual-cpp.md` | Future mirror/provenance and Restore only | Source-equivalent runtime implemented with confirmation, operation descriptors, test-safe executor injection, download provenance foundation, and installer policy | Future mirror/provenance work still needs immutable source URLs, exact hash/size/version/signer evidence, installer exit-code rules, and temp ownership scopes before reusable artifact approval or mirror substitution | No artifact provenance approval; no production allowlist; future mirror/provenance or Restore contract only | Unavailable | Restore unavailable until captured-state restore contract exists | No Windows 10 branch issue documented | Not GPU-specific | High | Complete as Yazan-accepted near parity | Maintain source-equivalent runtime; future work is mirror/provenance/Restore only | P11 |
| Reinstall | `reinstall` | Refresh | `source-ultimate/2 Refresh/1 Reinstall.ps1` | `137F519926293F37052817ACBBE20851652E5EA1B9F3B5B9F933AA1E22C2D9FB` | Implemented manual handoff; Auto blocked | `docs/tool-designs/reinstall-scope-provenance-design.md`; `docs/migrations/reinstall.md` | Missing artifact provenance for Auto | Manual handoff implemented; download provenance foundation; installer policy; reboot recovery foundation; file/registry rollback foundation | Auto still needs approved Windows 11 media artifact, exact hash/size/signer evidence, exact execution descriptor, generated-file ownership, approved handoff/reboot workflow, and support contract | Future Auto artifact approvals; installer execution descriptor; generated-file scope; reboot/handoff workflow scope | Unavailable | Restore unavailable until captured-state restore contract exists | Windows 10 branch unsupported; Windows 10 host may be valid only for Windows 11 preparation output | Not GPU-specific | High | Complete for manual handoff only | Auto remains blocked until exact Windows 11 Media Creation Tool approval package exists | P4 |
| Bloatware | `bloatware` | Windows | `source-ultimate/6 Windows/11 Bloatware.ps1` | `36677A334B37025A7234F4320EE54EF50E9528D1814E2B3A463EEB564C5814F5` | Placeholder/refused; scope design complete | `docs/tool-designs/bloatware-scope-design.md` | Missing AppX/package restore model | AppX package inventory foundation; destructive cleanup policy; service rollback foundation; download/installer foundation; file/registry rollback foundation | Exact AppX/package allowlists, all-users/provisioned restore policy, cleanup scopes, service scopes, artifact decisions | Package scopes; service scopes; cleanup scopes; file/registry scopes; possible artifact approvals | Source restore/default behavior not approved | Restore refused until exact inventory restore or quarantine restore is approved | Shared Windows behavior only if otherwise approved | Not GPU-specific | High | Maybe after one foundation | Decompose into package-only candidate after exact package allowlists exist | P5 |
| GameBar | `game-bar` | Windows | `source-ultimate/6 Windows/12 Gamebar.ps1` | `8C6703E68C251D63ADD81A87B7CB6C1F572A4CE55A1E092C33B9B444A9884E59` | Placeholder/refused; scope design complete | `docs/tool-designs/gamebar-scope-design.md` | Missing TrustedInstaller approved target flow | AppX foundation; service rollback foundation; download/installer foundation; TrustedInstaller foundation; reboot recovery foundation; file/registry rollback foundation | Exact package scopes, TrustedInstaller command scopes, repair artifact approvals, service scopes, protocol/registry scopes | AppX scopes; TI scopes; artifact approvals; service scopes; registry scopes; reboot scopes if repair requires | Source Default exists but not approved | Restore refused until AppX/service/registry restore records are approved | Shared Windows behavior only if otherwise approved | Not GPU-specific | High | No | Keep refused until exact TI, package, service, and repair scopes exist | P14 |
| Edge & WebView | `edge-webview` | Windows | `source-ultimate/6 Windows/13 Edge & WebView.ps1` | `161ED9C99D437E45650369CB7E15D5737DED363712E647138F134B049AC7E691` | Implemented manual handoff; Auto blocked | `docs/tool-designs/edge-webview-scope-design.md`; `docs/migrations/edge-webview.md` | Missing artifact provenance for Auto | Manual handoff implemented; download provenance foundation; installer policy; service rollback foundation; destructive cleanup policy; file/registry rollback foundation | Auto still needs exact repair artifacts, installer descriptors, package/process/service/task/file/registry cleanup scopes, RunOnce governance, and support policy | Artifact approvals; installer descriptors; package scopes; process scopes; service scopes; cleanup scopes; registry/RunOnce scopes | Unavailable | Restore unavailable until service/file/registry/package records are approved | Shared Windows behavior only if otherwise approved | Not GPU-specific | High | Complete for manual handoff only | Auto remains blocked until exact Edge/WebView approval packages exist | P12 |
| Control Panel Settings | `control-panel-settings` | Windows | `source-ultimate/6 Windows/15 Control Panel Settings.ps1` | `B78F643D21069F14E7E766769FB1EE15AEF974ABDF3CA010FE808D9EC162FB0B` | Placeholder/refused; scope design complete; not ready | `docs/tool-designs/control-panel-settings-scope-design.md` | Missing TrustedInstaller approved target flow | File/registry rollback foundation; service rollback foundation; cleanup policy; TrustedInstaller foundation | Tool decomposition, exact registry/privacy/security scopes, exact service scopes, exact TI target flow, scheduled task and process governance | Many sub-tool registry scopes; service scopes; TI scopes; cleanup scopes; scheduled task scopes; process scopes | Source Default exists but direct Default remains refused | Restore refused until source is decomposed and captured-state restore UI/runtime exists | No Windows 10-only branch found; blocked by governance, not product scope | Not GPU-specific | High | No | Keep refused; decompose into smaller approved candidates before scopes | P18 |
| Cleanup | `cleanup` | Windows | `source-ultimate/6 Windows/22 Cleanup.ps1` | `3419A995AD4483A145999B659268302F02BE982733DE831554ADA1C40F07CCAA` | Placeholder/refused; scope design complete | `docs/tool-designs/cleanup-scope-design.md` | Missing cleanup/quarantine scopes | Destructive cleanup policy; file/registry rollback foundation | Exact cleanup target scopes, ownership map, quarantine versus delete decisions, limits, restore selection UI/runtime | Cleanup scopes; quarantine scopes; file capture scopes if rollback is claimed | Not applicable | Restore refused until quarantine/capture restore selection exists | Shared Windows behavior may be considered if exact scopes are approved | Not GPU-specific | High | Yes | Add bounded cleanup allowlists and quarantine policy per target | P2 |
| Resizable BAR Assistant | `resizable-bar-assistant` | Advanced | `source-ultimate/8 Advanced/3 Resizable BAR Assistant.ps1` | `E2E1D919B350FA5190DFD4FAF23F3AB51ED2A324155CAFF49CDE774B092FB443` | Placeholder/refused; scope design complete | `docs/tool-designs/resizable-bar-assistant-scope-design.md` | Missing artifact provenance | Download provenance foundation; file/registry rollback foundation; driver rollback foundation; reboot recovery foundation | NVIDIA Profile Inspector artifact approval, generated `.nip` scope, NVIDIA profile rollback, firmware restart workflow | Artifact approvals; driver/profile scopes; generated file scopes; firmware reboot workflow | Not applicable | Restore refused until NVIDIA profile state capture exists | Shared Windows behavior only if otherwise approved | NVIDIA path only may be considered; AMD/Intel branches unsupported | High | No | NVIDIA artifact and driver-profile approval design | P15 |
| Services Optimizer | `services-optimizer` | Advanced | `source-ultimate/8 Advanced/5 Services Optimizer.ps1` | `386EEF403F48907E82C2E8E4BE5DFE509B0ED93CADBB5639B42D6326163EDB8F` | Placeholder/refused; scope design complete | `docs/tool-designs/services-optimizer-scope-design.md` | Missing Safe Mode/reboot workflow approval | Service rollback foundation; reboot recovery foundation; TrustedInstaller foundation; Safe Mode foundation; file/registry rollback foundation | Exact service scopes, Safe Mode workflow scope, TI scopes, RunOnce/BCD/reboot scopes, generated artifact ownership, restore point integration decision | Service scopes; TI scopes; Safe Mode scopes; reboot scopes; file/registry scopes; RunOnce/BCD scopes | Source Default/Restore not approved | Restore refused until service/registry/workflow rollback is fully designed | Shared Windows behavior only if otherwise approved | Not GPU-specific | High | No | Keep late-stage; approve exact service/Safe Mode/TI workflow only after recovery drills exist | P17 |
| Timer Resolution Assistant | `timer-resolution-assistant` | Advanced | `source-ultimate/8 Advanced/6 Timer Resolution Assistant.ps1` | `883F7CF4E6179383DE02E44B94FFC8DAFD380246751F1B1D81CAB8800B1E8621` | Placeholder/refused; scope design complete | `docs/tool-designs/timer-resolution-assistant-scope-design.md` | Missing artifact provenance | Service rollback foundation; file/registry rollback foundation; destructive cleanup policy; download/installer provenance model | Generated C# and binary artifact policy, compiler permission, exact service scope, protected path scope, timer registry scope | Generated artifact scope; compiler/execution descriptor; service scope; registry scope; cleanup scope | Source Default exists but not approved | Restore refused until service/file/registry records exist | Shared Windows behavior only if otherwise approved | Not GPU-specific | High | Maybe after one foundation | Generated Script / Temp Artifact Ownership Policy, then service scope review | P6 |
| Defender Optimize Assistant | `defender-optimize-assistant` | Advanced | `source-ultimate/8 Advanced/7 Defender Optimize Assistant.ps1` | `512F12D805715E9232304ABE5BA400BE6B3965D63F77D3B39E4C304507BFB9B6` | Placeholder/refused; scope design complete | `docs/tool-designs/defender-optimize-assistant-scope-design.md` | Missing Safe Mode/reboot workflow approval | Service rollback foundation; reboot recovery foundation; TrustedInstaller foundation; Safe Mode foundation; cleanup policy; file/registry rollback foundation | Security-sensitive registry scopes, Defender verification plan, TI scopes, Safe Mode workflow, scheduled task governance, RunOnce/BCD/reboot scopes | Defender/security registry scopes; TI scopes; Safe Mode scopes; scheduled task scopes; RunOnce/BCD/reboot scopes; generated file scopes | Source Default/Restore not approved | Restore refused until security state capture and Safe Mode recovery are approved | Shared Windows behavior only if otherwise approved | Not GPU-specific | High | No | Keep late-stage; build security-change approval and recovery drills first | P16 |

## Blocker Frequency Summary

Primary blocker counts across the 8 deferred/placeholders:

| Primary blocker category | Count | Tools |
|---|---:|---|
| Missing artifact provenance | 2 | Resizable BAR Assistant; Timer Resolution Assistant |
| Missing production allowlist | 1 | Cleanup |
| Missing AppX/package restore model | 1 | Bloatware |
| Missing TrustedInstaller approved target flow | 2 | GameBar; Control Panel Settings |
| Missing Safe Mode/reboot workflow approval | 2 | Services Optimizer; Defender Optimize Assistant |

Secondary blockers appear more often than the primary count shows. The most common secondary blockers are process handling, RunOnce/Active Setup behavior, scheduled task governance, generated script/temp artifact ownership, restore selection UI/runtime, and exact production scope approval.

## Near-Term Candidate Shortlist

These are not ready today. They are the comparatively safest next implementation attempts after limited additional foundation or allowlist work:

1. **Cleanup**
   Needs bounded cleanup scopes, quarantine/delete decisions, file-count and byte limits, and restore selection UI/runtime if any Restore claim is made.
2. **Bloatware**
   Could start as a package-inventory design reattempt only after exact package allowlists exist. It must not become a broad debloat pass.
3. **Timer Resolution Assistant**
   Could be reattempted after a generated script/temp artifact ownership policy and exact service scope approval. It remains high risk.

Updates Drivers Block is implemented in Phase 102 for the live Driver Updates
policy branch only. The broader Windows Updates, custom update-server URL,
bootable-media, generated-script, and reboot branches remain blocked for any
future approval package.

## Shared Foundation Roadmap

Recommended shared foundations before any heavy deferred implementation resumes:

1. **Production Allowlist Governance**
   Define how exact production file, registry, service, cleanup, package, driver, TrustedInstaller, Safe Mode, and reboot scopes are proposed, reviewed, approved, versioned, and revoked. Phase 66 documents this governance foundation in `docs/production-allowlist-governance.md`; it approves no production scopes.
2. **Restore Selection UI / Runtime Foundation**
   Build the user-facing and runtime model for choosing a captured-state restore record without confusing `Default` with `Restore`. Phase 67 documents this foundation in `docs/restore-selection-ui-runtime.md`; it approves no production Restore scopes or handlers.
3. **Process Handling Policy Foundation**
   Define exact process target scopes, user confirmation, interruption handling, verification, and refusal rules for broad or shell-critical process stops. Phase 68 documents this foundation in `docs/process-handling-policy.md`; it approves no production process scopes or targets.
4. **Scheduled Task State Capture / Rollback Foundation**
   Define exact task scopes, capture, mutation, verification, rollback, and recovery rules.
5. **Generated Script / Temp Artifact Ownership Policy**
   Define how generated `.reg`, `.ps1`, `.cmd`, `.xml`, `.nip`, C#, binary, and temp artifacts are named, hashed, owned, verified, and cleaned up.
6. **RunOnce / Active Setup Governance**
   Define when persistent post-reboot/startup behavior may be written, how it is captured, and how it is safely cancelled.
7. **Artifact Approval Intake Process**
   Define evidence requirements for immutable URLs, hashes, size, signer, license/redistributability, and authoritative source proof before any artifact enters `config/ArtifactProvenance.psd1`.
8. **Installer/App Inventory and Uninstall Model**
   Define app install state capture, exit-code handling, uninstall or repair semantics, and app-specific side effect ownership.
9. **Security-Sensitive Change Approval Model**
   Define extra confirmation, verification, rollback, and support rules for Defender, mitigations, privacy, security policy, and kernel/boot-related changes.

## High-Risk Deferred Set

These tools should remain late-stage because their sources combine driver, installer, reboot, TrustedInstaller, Safe Mode, security, or destructive behavior:

* Resizable BAR Assistant
* Services Optimizer
* Defender Optimize Assistant
* GameBar
* Control Panel Settings
* Edge & WebView

## Product Scope Notes

BoostLab product scope is branch-level scope:

* Shared Windows behavior may be preserved when an Ultimate source applies the same behavior to Windows 10 and Windows 11 and otherwise passes governance.
* Explicit Windows 10-only optimization, performance, service, and settings-improvement branches remain unsupported.
* Windows 10 may host approved Windows 11 preparation, refresh, migration, or transition workflows when the output targets Windows 11.
* GPU-specific tooling is NVIDIA-only.
* AMD and Intel GPU-specific branches remain disabled, visual-only, or not implemented.
* GPU-neutral behavior is allowed when otherwise approved.

Current product-scope impact:

* `driver-install-debloat-settings` and `resizable-bar-assistant` are constrained to NVIDIA-only future behavior.
* `reinstall` is implemented as controlled manual handoff only; Auto may eventually support a Windows 10 host only for Windows 11 preparation/refresh output after exact approvals.
* `cleanup` and most remaining Windows tools are blocked by governance, not by host OS alone, unless a future source branch is explicitly Windows 10-only.

## Recommended Next Phases

1. **Scheduled Task State Capture / Rollback Foundation**
   Required by Control Panel Settings, Defender Optimize Assistant, and installer-style workflows.
2. **Generated Script / Temp Artifact Ownership Policy**
   Required by the broader Updates Drivers Block bootable-media branches, Services Optimizer, Timer Resolution Assistant, Defender Optimize Assistant, DirectX-style extraction, and several registry-import workflows.
3. **RunOnce / Active Setup Governance**
   Required before persistent startup or post-reboot repair behavior can be approved.
4. **Cleanup Allowlist Review**
   A narrow tool-specific approval phase after cleanup scopes, quarantine rules, and restore selection are ready.

## Final Phase 65 Decision

No deferred tool is marked ready for implementation by this matrix.

The safest path is still foundation and allowlist work first, followed by narrow tool-specific reattempts. The presence of a scope design or provenance review is evidence for planning, not permission to execute.

Phase 83 adds `docs/tool-designs/nvidia-path-b-readiness-badge-design.md` as a
design-only badge taxonomy for future NVIDIA Path B status display. It does not
change readiness categories, approve scopes, enable UI, or implement Path B.

Phase 84 adds
`docs/tool-designs/nvidia-path-b-path-conflict-copy-status-text-design.md` as a
design-only wording plan for future Path A/Path B conflict and status text. It
does not change readiness categories, approve scopes, enable UI, add
localization runtime files, or implement Path B.

Phase 85 adds
`docs/tool-designs/nvidia-path-b-non-executing-catalog-preview-data-design.md`
as design-only preview metadata planning. It does not change readiness
categories, approve scopes, create an active catalog, enable UI, or implement
Path B.

Phase 86 adds
`docs/tool-designs/nvidia-path-b-preview-data-integrity-drift-rules-design.md`
as design-only integrity/drift rules for future Path B preview metadata. It
does not change readiness categories, approve scopes, create a drift checker,
enable UI, or implement Path B.

Phase 87 adds
`docs/tool-designs/nvidia-path-b-documentation-index-navigation-design.md` as a
documentation-only navigation layer for the Path B doc set. It does not change
readiness categories, approve scopes, create live navigation, enable UI, or
implement Path B.

Phase 88 adds
`docs/tool-designs/nvidia-path-b-documentation-backlink-audit-design.md` as a
documentation-only backlink audit design for the Path B doc set. It does not
change readiness categories, approve scopes, create a live backlink auditor,
enable UI, or implement Path B.

Phase 89 adds
`docs/tool-designs/nvidia-path-b-governance-freeze-review.md` as a
documentation-only governance freeze review for the Path B doc set. It does not
change readiness categories, approve scopes, create active governance runtime,
enable UI, or implement Path B.

Phase 90 adds
`docs/tool-designs/driver-clean-controlled-intake-implementation-readiness.md`
as a focused Driver Clean readiness decision. It keeps Driver Clean outside
NVIDIA Path B, records `NeedsArtifactDecision`, and does not approve standalone
DDU, DDU downloads, DDU artifacts, uncontrolled DDU execution, production
scopes, or tool behavior.

Phase 91 adds
`docs/tool-designs/driver-clean-controlled-implementation-plan.md` as a focused
Driver Clean implementation plan. It chooses `ManualHandoffFirst`, keeps Auto
blocked, and does not approve DDU/7-Zip downloads, artifacts, execution,
production scopes, or tool behavior.


