# Final Deferred Tools Readiness Matrix

## Purpose

This matrix is the final Phase 65 readiness snapshot for the current BoostLab deferred queue.

It uses the completed deferred execution plan, readiness review, provenance reviews, and tool-specific scope designs to identify what remains blocked before any deferred tool can be safely implemented.

This document does not approve production scopes, allowlists, artifacts, installer execution, TrustedInstaller execution, Safe Mode workflows, cleanup targets, driver targets, package targets, or tool behavior.

## Current Inventory

* Active tools: **49**
* Implemented tools: **31**
* Deferred/placeholders: **18**
* Source-promoted mirror files: **7** (`docs/missing-ultimate-scripts-intake-review.md`)
* Remaining unimplemented source-promoted intake candidates: **6**
* Design/review coverage: **18/18 deferred tools covered**
* Production allowlists/scopes approved by this phase: **0**
* Tool behavior changed by this phase: **No**
* `source-ultimate/` modified by this phase: **No**

Phase 70 note: `Driver Clean.ps1` is a Yazan-approved intake exception despite DDU usage. It remains separate from official active/deferred counts and does not approve standalone DDU, DDU execution, downloads, artifacts, production scopes, or tool behavior.

Phase 71 note: source-promotion planning for the seven intake scripts lives in `docs/missing-scripts-source-promotion-decision.md`. The recommended future strategy is a source-promotion mirror under `source-ultimate/_intake-promoted/Ultimate/`, with no count or behavior changes in this phase.

Phase 72 note: the seven intake scripts were copied into `source-ultimate/_intake-promoted/Ultimate/` as source-promoted mirror references. Official active/deferred counts remain unchanged, and no tool behavior or production approval was added.

Phase 73 note: NVIDIA App Path B catalog planning lives in `docs/nvidia-path-b-catalog-design.md`. It documents Path A versus Path B and preserves the required five-step Path B order as catalog-only planning, with no implementation or production approval.

Phase 74 note: NVIDIA App Path B scope design lives in `docs/tool-designs/nvidia-path-b-scope-design.md`. It inventories the five source-promoted scripts and documents future foundations without enabling implementation.

Phase 75 note: NVIDIA App Path B production allowlist planning lives in `docs/tool-designs/nvidia-path-b-production-allowlist-planning.md`. It documents candidate allowlist categories and unresolved approval questions without adding production scopes.

Phase 76 note: NVIDIA App Path B artifact provenance review lives in `docs/tool-designs/nvidia-path-b-artifact-provenance-review.md`. It documents artifact evidence and approval blockers without approving artifacts, downloads, installers, production scopes, or provenance config.

Phase 77 note: NVIDIA profile state capture model lives in `docs/nvidia-profile-state-capture-model.md`. It documents profile capture/restore/import/export requirements without approving NVIDIA Profile Inspector execution, `.nip` operations, profile writes, runtime behavior, or production scopes.

Phase 78 note: NVIDIA Path B UI workflow design lives in `docs/nvidia-path-b-ui-workflow-design.md`. It documents future Path A versus Path B choice, ordered stepper, gating, messaging, and result/log expectations without adding UI implementation or enabling Path B behavior.

Phase 79 note: NVIDIA Path B draft allowlist proposal lives in `docs/tool-designs/nvidia-path-b-draft-allowlist-proposal.md`. It structures future candidate scopes while keeping every entry non-approved and adding no production allowlist config.

Phase 80 note: NVIDIA Path B production approval gate design lives in `docs/tool-designs/nvidia-path-b-production-approval-gate-design.md`. It defines future gate criteria for draft entries without granting production approval or creating production config.

Phase 81 note: NVIDIA Path B runtime gating design lives in `docs/tool-designs/nvidia-path-b-runtime-gating-design.md`. It defines future gate states and result schema without implementing runtime gates, creating production config, granting production approval, enabling UI, or changing tool behavior.

Phase 82 note: NVIDIA Path B non-executing Workflow Registry schema design lives in `docs/tool-designs/nvidia-path-b-non-executing-workflow-registry-schema-design.md`. It defines future metadata fields and pseudo-schema only; it creates no active workflow registry, runtime config, production config, UI implementation, or tool behavior.

Phase 92 note: `Driver Clean` is now an implemented active tool using controlled manual handoff only. It verifies the source mirror checksum, reports ManualHandoffOnly, keeps Auto blocked as `AutoBlockedUntilArtifactApproval`, performs no DDU or 7-Zip download/execution, performs no Safe Mode/RunOnce/bcdedit/reboot automation, and remains outside NVIDIA Path B.

## Coverage Summary

The current deferred queue has complete documentation coverage:

* Scope or scope/provenance design covered tools: **16**
* Standalone provenance review covered tools: **2**
* Total deferred tools covered by design or review: **18/18**

Scope or scope/provenance design coverage:

* `updates-drivers-block`
* `reinstall`
* `installers`
* `driver-install-debloat-settings`
* `start-menu-taskbar`
* `copilot`
* `bloatware`
* `game-bar`
* `edge-settings`
* `edge-webview`
* `control-panel-settings`
* `cleanup`
* `resizable-bar-assistant`
* `services-optimizer`
* `timer-resolution-assistant`
* `defender-optimize-assistant`

Standalone provenance review coverage:

* `directx`
* `visual-cpp`

## Matrix

| Tool name | Tool id | Stage | Source path | Source checksum | Current status | Design/review document | Primary blocker category | Foundations already available | Foundations still missing | Production allowlists/scopes required | Default | Restore | Windows 10 branch-level scope | NVIDIA/AMD/Intel product scope | Risk level | Near-term implementation candidate | Recommended next action | Suggested phase priority |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Reinstall | `reinstall` | Refresh | `source-ultimate/2 Refresh/1 Reinstall.ps1` | `137F519926293F37052817ACBBE20851652E5EA1B9F3B5B9F933AA1E22C2D9FB` | Placeholder/refused; scope/provenance design complete | `docs/tool-designs/reinstall-scope-provenance-design.md` | Missing artifact provenance | Download provenance foundation; installer policy; reboot recovery foundation; file/registry rollback foundation | Approved Windows 11 media artifact, exact hash/size/signer evidence, exact execution descriptor, approved handoff/reboot workflow | Artifact manifest entries; installer execution descriptor; generated-file scope; reboot/handoff workflow scope | Not applicable | Refused until captured-state workflow exists | Windows 10 branch unsupported; Windows 10 host may be valid only for Windows 11 preparation output | Not GPU-specific | High | Maybe after one foundation | Artifact provenance review, then implementation reattempt only if exact Windows 11 artifact approval exists | P4 |
| Updates Drivers Block | `updates-drivers-block` | Refresh | `source-ultimate/2 Refresh/3 Updates Drivers Block.ps1` | `4D4EC652C5A7F78824F53B7DC7FD46DDA948F3716A7CD6FD102D6C678EE11991` | Placeholder/refused; scope design complete | `docs/tool-designs/updates-drivers-block-scope-design.md` | Missing production allowlist | File/registry rollback foundation; reboot recovery foundation; generated-script ownership can be designed through file policy | Exact Windows Update policy scopes, generated media/script file scope, custom URL decision, reboot workflow approval | Registry scopes; generated script/media scopes; reboot workflow scope | Source has Default intent but not approved | Restore refused until exact captured-state selection exists | Shared Windows behavior may be considered; explicit Windows 10-only optimization remains unsupported | Not GPU-specific | High | Maybe after one foundation | Add production allowlists only after deciding live-policy versus media-script boundaries | P3 |
| Edge Settings | `edge-settings` | Setup | `source-ultimate/3 Setup/6 Edge Settings.ps1` | `342869157930ECF0869A07B4254CB8F174C63648CD329DB3914BAD291CD5FF28` | Placeholder/refused; scope design complete; not ready | `docs/tool-designs/edge-settings-scope-design.md` | Missing scheduled task governance | File/registry rollback foundation; service rollback foundation; download provenance foundation; installer policy | RunOnce/Active Setup governance, process handling governance, exact Edge repair artifact approval, exact service scopes | Registry scopes; service scopes; RunOnce/Active Setup scopes; artifact approvals; installer descriptor | Not applicable until design split | Refused until exact captured-state selection exists | No known product-scope exception; shared behavior only if otherwise approved | Not GPU-specific | High | No | Build RunOnce/Active Setup and process-handling policy before any implementation reattempt | P8 |
| Installers | `installers` | Installers | `source-ultimate/4 Installers/1 Installers.ps1` | `1065D64183457D4E7B28EA78DDE41525EC8F7C4A4BCA12D29B70D991141C0C67` | Placeholder/refused; scope/provenance design complete | `docs/tool-designs/installers-scope-provenance-design.md` | Missing artifact provenance | Download provenance foundation; installer policy; service rollback foundation; file/registry rollback foundation; cleanup policy | Approved per-app artifacts, exact installer descriptors, scheduled task governance, app inventory/uninstall model | Artifact approvals; installer descriptors; per-app service/file/registry/task/shortcut scopes | Not applicable | Refused until installer/app inventory and restore model exists | No Windows 10 optimization branch should be ported | NVIDIA-only affects only any GPU-specific installer branch; AMD/Intel remain unsupported | High | No | Artifact Approval Intake Process, then app-by-app approval packages | P7 |
| Driver Install Debloat & Settings | `driver-install-debloat-settings` | Graphics | `source-ultimate/5 Graphics/1 Driver Install Debloat & Settings.ps1` | `E69EFF538E7CE6108233C525A2BB88BA2D549CE6954AE751BE7BED778271C26F` | Placeholder/refused; scope/provenance design complete | `docs/tool-designs/driver-install-debloat-settings-scope-provenance-design.md` | Missing driver/profile rollback approval | Download provenance foundation; installer policy; driver rollback foundation; reboot recovery foundation; AppX foundation; cleanup policy; file/registry rollback foundation | Exact NVIDIA artifacts, driver/package scopes, profile import rollback, cleanup scopes, AppX scopes, reboot workflow | NVIDIA artifact approvals; driver scopes; profile scopes; cleanup scopes; AppX scopes; reboot scope | Not applicable | Refused until driver rollback and profile restore are approved for exact targets | Shared Windows behavior only; Windows 10 optimization branches unsupported | NVIDIA path only may be considered; AMD/Intel branches disabled | High | No | Driver state and profile allowlist design before artifact approval | P13 |
| DirectX | `directx` | Graphics | `source-ultimate/5 Graphics/2 DirectX.ps1` | `17051A2F0F7A0CF16BE525121720406E8F1630C94E5977A7CD4C18652A87EE05` | Provenance refused | `docs/directx-provenance-review.md` | Missing artifact provenance | Download provenance foundation; installer policy; file/registry rollback foundation; cleanup policy | Immutable source URLs, exact hash/size/signer evidence, extracted `DXSETUP.exe` provenance, installer descriptor, temp ownership scopes | Artifact approvals; installer descriptor; extraction inventory; file/temp cleanup scopes | Not applicable | Not applicable | No Windows 10 branch issue documented | Not GPU-specific | High | No | Keep refused until immutable artifact provenance package exists | P10 |
| Visual C++ | `visual-cpp` | Graphics | `source-ultimate/5 Graphics/3 C++.ps1` | `7ACB1F25ECFEEAD83FA389E2D0C1FEEF12232C4E9A740CB5DE64A326FFD38C09` | Provenance refused | `docs/visual-cpp-provenance-review.md` | Missing artifact provenance | Download provenance foundation; installer policy | Immutable sources, exact hash/size/version/signer evidence for all packages, exit-code rules, temp ownership scopes | Artifact approvals; installer descriptors; generated-temp-path scopes | Not applicable | Not applicable | No Windows 10 branch issue documented | Not GPU-specific | High | No | Keep refused until all twelve redistributable approvals exist | P11 |
| Start Menu Taskbar | `start-menu-taskbar` | Windows | `source-ultimate/6 Windows/1 Start Menu Taskbar.ps1` | `88BEB0E8C41F7A32AAE6A0A6E184E87E678FB25BEDEB092C63F4BA98B8712E91` | Placeholder/refused; scope design complete | `docs/tool-designs/start-menu-taskbar-scope-design.md` | Missing production allowlist | File/registry rollback foundation; cleanup policy; reboot recovery guidance for Explorer handling | Exact file scopes, registry scopes, cleanup ownership rules, process handling governance for Explorer, restore selection UI/runtime | File scopes; registry scopes; cleanup scopes; Explorer process handling scope | Source Default exists but remains refused | Restore refused until captured-state selection UI/runtime exists | Shared Windows behavior may be considered; explicit Windows 10-only branches remain unsupported | Not GPU-specific | High | Maybe after one foundation | Add exact file/registry scopes and Explorer process handling design | P1 |
| Copilot | `copilot` | Windows | `source-ultimate/6 Windows/8 Copilot.ps1` | `21B58212B241A6C0B74582063E3E74F746014E9137194B58B088CC6692F22A90` | Placeholder/refused; scope design complete; not ready | `docs/tool-designs/copilot-scope-design.md` | Missing process handling governance | AppX package inventory and restore foundation; file/registry rollback foundation | Process stop governance; exact package scopes; exact package restore model | AppX package scopes; process target scopes; registry scopes if preserved | Source Default exists but not approved | Restore refused until AppX/package restore records are approved | Shared Windows behavior only if otherwise approved | Not GPU-specific | High | No | Build process handling policy, then package allowlist review | P9 |
| Bloatware | `bloatware` | Windows | `source-ultimate/6 Windows/11 Bloatware.ps1` | `36677A334B37025A7234F4320EE54EF50E9528D1814E2B3A463EEB564C5814F5` | Placeholder/refused; scope design complete | `docs/tool-designs/bloatware-scope-design.md` | Missing AppX/package restore model | AppX package inventory foundation; destructive cleanup policy; service rollback foundation; download/installer foundation; file/registry rollback foundation | Exact AppX/package allowlists, all-users/provisioned restore policy, cleanup scopes, service scopes, artifact decisions | Package scopes; service scopes; cleanup scopes; file/registry scopes; possible artifact approvals | Source restore/default behavior not approved | Restore refused until exact inventory restore or quarantine restore is approved | Shared Windows behavior only if otherwise approved | Not GPU-specific | High | Maybe after one foundation | Decompose into package-only candidate after exact package allowlists exist | P5 |
| GameBar | `game-bar` | Windows | `source-ultimate/6 Windows/12 Gamebar.ps1` | `8C6703E68C251D63ADD81A87B7CB6C1F572A4CE55A1E092C33B9B444A9884E59` | Placeholder/refused; scope design complete | `docs/tool-designs/gamebar-scope-design.md` | Missing TrustedInstaller approved target flow | AppX foundation; service rollback foundation; download/installer foundation; TrustedInstaller foundation; reboot recovery foundation; file/registry rollback foundation | Exact package scopes, TrustedInstaller command scopes, repair artifact approvals, service scopes, protocol/registry scopes | AppX scopes; TI scopes; artifact approvals; service scopes; registry scopes; reboot scopes if repair requires | Source Default exists but not approved | Restore refused until AppX/service/registry restore records are approved | Shared Windows behavior only if otherwise approved | Not GPU-specific | High | No | Keep refused until exact TI, package, service, and repair scopes exist | P14 |
| Edge & WebView | `edge-webview` | Windows | `source-ultimate/6 Windows/13 Edge & WebView.ps1` | `161ED9C99D437E45650369CB7E15D5737DED363712E647138F134B049AC7E691` | Placeholder/refused; scope design complete | `docs/tool-designs/edge-webview-scope-design.md` | Missing artifact provenance | Download provenance foundation; installer policy; service rollback foundation; destructive cleanup policy; file/registry rollback foundation | Exact repair artifacts, service scopes, file cleanup ownership map, RunOnce governance | Artifact approvals; installer descriptors; service scopes; cleanup scopes; registry/RunOnce scopes | Source repair/default behavior not approved | Restore refused until service/file/registry/package records are approved | Shared Windows behavior only if otherwise approved | Not GPU-specific | High | No | Repair artifact provenance and cleanup ownership design | P12 |
| Control Panel Settings | `control-panel-settings` | Windows | `source-ultimate/6 Windows/15 Control Panel Settings.ps1` | `B78F643D21069F14E7E766769FB1EE15AEF974ABDF3CA010FE808D9EC162FB0B` | Placeholder/refused; scope design complete; not ready | `docs/tool-designs/control-panel-settings-scope-design.md` | Missing TrustedInstaller approved target flow | File/registry rollback foundation; service rollback foundation; cleanup policy; TrustedInstaller foundation | Tool decomposition, exact registry/privacy/security scopes, exact service scopes, exact TI target flow, scheduled task and process governance | Many sub-tool registry scopes; service scopes; TI scopes; cleanup scopes; scheduled task scopes; process scopes | Source Default exists but direct Default remains refused | Restore refused until source is decomposed and captured-state restore UI/runtime exists | No Windows 10-only branch found; blocked by governance, not product scope | Not GPU-specific | High | No | Keep refused; decompose into smaller approved candidates before scopes | P18 |
| Cleanup | `cleanup` | Windows | `source-ultimate/6 Windows/22 Cleanup.ps1` | `3419A995AD4483A145999B659268302F02BE982733DE831554ADA1C40F07CCAA` | Placeholder/refused; scope design complete | `docs/tool-designs/cleanup-scope-design.md` | Missing cleanup/quarantine scopes | Destructive cleanup policy; file/registry rollback foundation | Exact cleanup target scopes, ownership map, quarantine versus delete decisions, limits, restore selection UI/runtime | Cleanup scopes; quarantine scopes; file capture scopes if rollback is claimed | Not applicable | Restore refused until quarantine/capture restore selection exists | Shared Windows behavior may be considered if exact scopes are approved | Not GPU-specific | High | Yes | Add bounded cleanup allowlists and quarantine policy per target | P2 |
| Resizable BAR Assistant | `resizable-bar-assistant` | Advanced | `source-ultimate/8 Advanced/3 Resizable BAR Assistant.ps1` | `E2E1D919B350FA5190DFD4FAF23F3AB51ED2A324155CAFF49CDE774B092FB443` | Placeholder/refused; scope design complete | `docs/tool-designs/resizable-bar-assistant-scope-design.md` | Missing artifact provenance | Download provenance foundation; file/registry rollback foundation; driver rollback foundation; reboot recovery foundation | NVIDIA Profile Inspector artifact approval, generated `.nip` scope, NVIDIA profile rollback, firmware restart workflow | Artifact approvals; driver/profile scopes; generated file scopes; firmware reboot workflow | Not applicable | Restore refused until NVIDIA profile state capture exists | Shared Windows behavior only if otherwise approved | NVIDIA path only may be considered; AMD/Intel branches unsupported | High | No | NVIDIA artifact and driver-profile approval design | P15 |
| Services Optimizer | `services-optimizer` | Advanced | `source-ultimate/8 Advanced/5 Services Optimizer.ps1` | `386EEF403F48907E82C2E8E4BE5DFE509B0ED93CADBB5639B42D6326163EDB8F` | Placeholder/refused; scope design complete | `docs/tool-designs/services-optimizer-scope-design.md` | Missing Safe Mode/reboot workflow approval | Service rollback foundation; reboot recovery foundation; TrustedInstaller foundation; Safe Mode foundation; file/registry rollback foundation | Exact service scopes, Safe Mode workflow scope, TI scopes, RunOnce/BCD/reboot scopes, generated artifact ownership, restore point integration decision | Service scopes; TI scopes; Safe Mode scopes; reboot scopes; file/registry scopes; RunOnce/BCD scopes | Source Default/Restore not approved | Restore refused until service/registry/workflow rollback is fully designed | Shared Windows behavior only if otherwise approved | Not GPU-specific | High | No | Keep late-stage; approve exact service/Safe Mode/TI workflow only after recovery drills exist | P17 |
| Timer Resolution Assistant | `timer-resolution-assistant` | Advanced | `source-ultimate/8 Advanced/6 Timer Resolution Assistant.ps1` | `883F7CF4E6179383DE02E44B94FFC8DAFD380246751F1B1D81CAB8800B1E8621` | Placeholder/refused; scope design complete | `docs/tool-designs/timer-resolution-assistant-scope-design.md` | Missing artifact provenance | Service rollback foundation; file/registry rollback foundation; destructive cleanup policy; download/installer provenance model | Generated C# and binary artifact policy, compiler permission, exact service scope, protected path scope, timer registry scope | Generated artifact scope; compiler/execution descriptor; service scope; registry scope; cleanup scope | Source Default exists but not approved | Restore refused until service/file/registry records exist | Shared Windows behavior only if otherwise approved | Not GPU-specific | High | Maybe after one foundation | Generated Script / Temp Artifact Ownership Policy, then service scope review | P6 |
| Defender Optimize Assistant | `defender-optimize-assistant` | Advanced | `source-ultimate/8 Advanced/7 Defender Optimize Assistant.ps1` | `512F12D805715E9232304ABE5BA400BE6B3965D63F77D3B39E4C304507BFB9B6` | Placeholder/refused; scope design complete | `docs/tool-designs/defender-optimize-assistant-scope-design.md` | Missing Safe Mode/reboot workflow approval | Service rollback foundation; reboot recovery foundation; TrustedInstaller foundation; Safe Mode foundation; cleanup policy; file/registry rollback foundation | Security-sensitive registry scopes, Defender verification plan, TI scopes, Safe Mode workflow, scheduled task governance, RunOnce/BCD/reboot scopes | Defender/security registry scopes; TI scopes; Safe Mode scopes; scheduled task scopes; RunOnce/BCD/reboot scopes; generated file scopes | Source Default/Restore not approved | Restore refused until security state capture and Safe Mode recovery are approved | Shared Windows behavior only if otherwise approved | Not GPU-specific | High | No | Keep late-stage; build security-change approval and recovery drills first | P16 |

## Blocker Frequency Summary

Primary blocker counts across the 18 deferred/placeholders:

| Primary blocker category | Count | Tools |
|---|---:|---|
| Missing artifact provenance | 8 | Reinstall; Installers; Driver Install Debloat & Settings; DirectX; Visual C++; Edge & WebView; Resizable BAR Assistant; Timer Resolution Assistant |
| Missing production allowlist | 3 | Updates Drivers Block; Start Menu Taskbar; Cleanup |
| Missing scheduled task governance | 1 | Edge Settings |
| Missing process handling governance | 1 | Copilot |
| Missing AppX/package restore model | 1 | Bloatware |
| Missing TrustedInstaller approved target flow | 2 | GameBar; Control Panel Settings |
| Missing Safe Mode/reboot workflow approval | 2 | Services Optimizer; Defender Optimize Assistant |

Secondary blockers appear more often than the primary count shows. The most common secondary blockers are process handling, RunOnce/Active Setup behavior, scheduled task governance, generated script/temp artifact ownership, restore selection UI/runtime, and exact production scope approval.

## Near-Term Candidate Shortlist

These are not ready today. They are the comparatively safest next implementation attempts after limited additional foundation or allowlist work:

1. **Start Menu Taskbar**
   Needs exact file/registry scopes, Explorer process handling rules, and a clear refusal of Default/Restore until captured-state restore selection exists.
2. **Cleanup**
   Needs bounded cleanup scopes, quarantine/delete decisions, file-count and byte limits, and restore selection UI/runtime if any Restore claim is made.
3. **Updates Drivers Block**
   Needs exact registry and generated media/script scopes plus a decision on reboot/media branches.
4. **Bloatware**
   Could start as a package-inventory design reattempt only after exact package allowlists exist. It must not become a broad debloat pass.
5. **Timer Resolution Assistant**
   Could be reattempted after a generated script/temp artifact ownership policy and exact service scope approval. It remains high risk.

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

* Driver Install Debloat & Settings
* Resizable BAR Assistant
* Services Optimizer
* Defender Optimize Assistant
* GameBar
* Control Panel Settings
* Reinstall
* Installers
* Edge & WebView
* DirectX
* Visual C++

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
* `reinstall` may eventually support a Windows 10 host only for Windows 11 preparation/refresh output.
* `updates-drivers-block`, `start-menu-taskbar`, `cleanup`, and most Windows tools are blocked by governance, not by host OS alone, unless a future source branch is explicitly Windows 10-only.

## Recommended Next Phases

1. **Scheduled Task State Capture / Rollback Foundation**
   Required by Edge Settings, Control Panel Settings, Defender Optimize Assistant, and installer-style workflows.
2. **Generated Script / Temp Artifact Ownership Policy**
   Required by Updates Drivers Block, Services Optimizer, Timer Resolution Assistant, Defender Optimize Assistant, DirectX-style extraction, and several registry-import workflows.
3. **RunOnce / Active Setup Governance**
   Required before persistent startup or post-reboot repair behavior can be approved.
4. **Start Menu Taskbar Allowlist Review**
   A narrow tool-specific approval phase after process handling and restore boundaries are clearer.
5. **Cleanup Allowlist Review**
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
