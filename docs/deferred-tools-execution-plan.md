# Deferred Tools Execution Plan

## Purpose

This plan covers every active BoostLab tool that remains a placeholder after the first full migration pass.

These tools are not abandoned. They are blocked until the required foundation exists to preserve approved Ultimate behavior without weakening it, silently narrowing it, or bypassing current governance.

The follow-up implementation-readiness assessment for this same deferred queue
now lives in `docs/deferred-tool-readiness-review.md`.

The final post-design readiness matrix for the current deferred queue lives in
`docs/final-deferred-tools-readiness-matrix.md`.

The production allowlist approval rules for future exact scopes live in
`docs/production-allowlist-governance.md`.

The shared Restore selection UI/runtime foundation for future captured-state
Restore actions lives in `docs/restore-selection-ui-runtime.md`.

The shared Process Handling Policy foundation for future process detection,
close, stop, restart, and launch-handoff governance lives in
`docs/process-handling-policy.md`.

Phase 69 intake for seven manually supplied Ultimate scripts lives in
`docs/missing-ultimate-scripts-intake-review.md`. These scripts remain intake
candidates pending source promotion and do not change the official active or
deferred tool counts in this plan.

Phase 70 updates that intake review to record `Driver Clean.ps1` as a
Yazan-approved intake exception despite DDU usage. This does not approve
standalone DDU, DDU execution, downloads, artifacts, production scopes, or tool
behavior.

Phase 71 source-promotion planning lives in
`docs/missing-scripts-source-promotion-decision.md`. It recommends a future
source-promotion mirror under `source-ultimate/_intake-promoted/Ultimate/` and
does not change official counts or tool behavior.

Phase 72 completed the source-promotion mirror copy for all seven intake
scripts under `source-ultimate/_intake-promoted/Ultimate/`. They remain
source-promoted candidates only and still require future design/review before
any implementation or catalog change.

Phase 73 records the NVIDIA App Path B catalog design in
`docs/nvidia-path-b-catalog-design.md`. It defines the required Path B order
and Path A/Path B UI guidance as catalog-only planning, with no tool enablement
or production approval.

Phase 74 records the non-executing NVIDIA App Path B scope design in
`docs/tool-designs/nvidia-path-b-scope-design.md`.

Phase 75 records non-approved NVIDIA App Path B production allowlist planning
in `docs/tool-designs/nvidia-path-b-production-allowlist-planning.md`.

Phase 76 records non-approved NVIDIA App Path B artifact provenance review in
`docs/tool-designs/nvidia-path-b-artifact-provenance-review.md`. It does not
approve artifacts, downloads, installers, or production provenance config.

Phase 77 records the inert NVIDIA profile state capture model in
`docs/nvidia-profile-state-capture-model.md`. It approves no profile capture,
restore, import, export, Profile Inspector execution, `.nip` operation,
runtime behavior, or production scope.

Phase 78 records future Path A / Path B UI workflow design in
`docs/nvidia-path-b-ui-workflow-design.md`. It adds no UI implementation,
runtime workflow config, tool card, placeholder, or production approval.

Phase 79 records non-approved NVIDIA App Path B draft allowlist proposals in
`docs/tool-designs/nvidia-path-b-draft-allowlist-proposal.md`. It creates no
production allowlist config and approves no scope.

Phase 80 records NVIDIA App Path B production approval gate design in
`docs/tool-designs/nvidia-path-b-production-approval-gate-design.md`. It grants
no production approval and creates no production config.

Phase 81 records NVIDIA App Path B runtime gating design in
`docs/tool-designs/nvidia-path-b-runtime-gating-design.md`. It defines future
gate states, runtime result schema, and blocked-path behavior without adding
runtime gate implementation, production config, UI implementation, tool card,
placeholder enablement, or Path B execution behavior.

Phase 82 records NVIDIA App Path B non-executing Workflow Registry schema
design in
`docs/tool-designs/nvidia-path-b-non-executing-workflow-registry-schema-design.md`.
It defines future metadata fields and pseudo-schema only; it creates no active
workflow registry, runtime config, production config, UI implementation, tool
card, placeholder enablement, or Path B execution behavior.

Phase 92 implements `Driver Clean` as a controlled manual-handoff active tool
outside NVIDIA Path B. It verifies the source mirror checksum, reports
ManualHandoffOnly, keeps Auto blocked as `AutoBlockedUntilArtifactApproval`,
and performs no DDU or 7-Zip download/execution, external process start, Safe
Mode switch, RunOnce creation, `bcdedit` call, reboot, registry mutation, or
driver cleanup.

Phase 94 implements `Nvidia Settings` as a controlled manual-handoff active
tool for Path B step 2 after the Phase 93 `Driver Install Latest` manual
handoff. It verifies the source mirror checksum, reports ManualHandoffOnly,
keeps Auto blocked as `AutoBlockedUntilArtifactApproval`, and performs no
7-Zip download/install, NVIDIA Profile Inspector download/execution, `.nip`
import/export, browser opening, Control Panel launch, external process start,
registry/profile/system mutation, reboot, or session change. The remaining Path
B steps remain source-promoted intake candidates only.

Phase 97 implements `Msi Mode` as Path B step 5 controlled NVIDIA-only
display-device Enum registry behavior. It verifies the source mirror checksum,
captures `MSISupported` before mutation, applies source-defined `DWORD 1`,
defaults to source-defined `DWORD 0`, verifies results, and keeps Restore
unavailable without selected captured state. It performs no downloads, external
process launch, device restart, reboot, driver operation, or production
allowlist/artifact approval.

Phase 102 implements `Updates Drivers Block` as a controlled live Driver
Updates policy tool. It verifies the source checksum, supports Analyze, Apply,
Default, and selected captured-state Restore for only the nine source-defined
Driver Updates policy values, captures prior state before mutation, and keeps
the broad Windows Updates, custom update-server URL, bootable-media,
generated-script, external-process, and reboot branches blocked.

Tool-specific scope designs created after the first-pass review:

* Updates Drivers Block: `docs/tool-designs/updates-drivers-block-scope-design.md`
* Start Menu Taskbar: `docs/tool-designs/start-menu-taskbar-scope-design.md`
* Cleanup: `docs/tool-designs/cleanup-scope-design.md`
* Bloatware: `docs/tool-designs/bloatware-scope-design.md`
* Edge & WebView: `docs/tool-designs/edge-webview-scope-design.md`
* Services Optimizer: `docs/tool-designs/services-optimizer-scope-design.md`
* Defender Optimize Assistant: `docs/tool-designs/defender-optimize-assistant-scope-design.md`
* Timer Resolution Assistant: `docs/tool-designs/timer-resolution-assistant-scope-design.md`
* Resizable BAR Assistant: `docs/tool-designs/resizable-bar-assistant-scope-design.md`
* GameBar: `docs/tool-designs/gamebar-scope-design.md`
* Copilot: `docs/tool-designs/copilot-scope-design.md`
* Edge Settings: `docs/tool-designs/edge-settings-scope-design.md`
* Control Panel Settings: `docs/tool-designs/control-panel-settings-scope-design.md`
* Reinstall: `docs/tool-designs/reinstall-scope-provenance-design.md`
* Installers: `docs/tool-designs/installers-scope-provenance-design.md`
* Driver Install Debloat & Settings: `docs/tool-designs/driver-install-debloat-settings-scope-provenance-design.md`

Current inventory at the time of this plan:

* Active approved tools: **55**
* Implemented tools: **43**
* Remaining placeholders: **12**
* Remaining unimplemented source-promoted intake candidates: **0**
* Deleted tools that must never return: **Loudness EQ**, **NVME Faster Driver**

## Product Scope Context

Windows 11 is BoostLab's optimized target platform. NVIDIA is the only supported vendor scope for GPU-specific tooling.

Windows 10 optimization branches remain unsupported. A Windows 10 host may still be valid for approved Windows 11 preparation or migration workflows, but that exception does not convert Windows 10 optimization branches into supported migration targets.

AMD and Intel GPU-specific branches remain disabled, visual-only, or not implemented unless Yazan expands product scope later.

## Status Meanings

* `Placeholder`: module still uses the shared placeholder contract.
* `Refused`: direct implementation was explicitly rejected because it would violate current governance or weaken Ultimate behavior.
* `Deferred`: blocked until a required foundation is approved and implemented.

In practice, every tool in this document is either still a placeholder and currently blocked, or has a narrow implemented manual-handoff/read-only path while its unsafe Auto behavior remains blocked. Where a tool was explicitly reviewed in a dedicated phase and rejected, its status is recorded as `Refused`.

## Deferred / Refused Tools

| Tool id | Title | Stage | Ultimate source | Source SHA-256 | Current status | Main blocker category | Why direct implementation was refused or unsafe | Required foundation before implementation | Product-scope effect | Suggested future phase | Visual-only / disabled until ready |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `reinstall` | Reinstall | Refresh | `source-ultimate/2 Refresh/1 Reinstall.ps1` | `137F519926293F37052817ACBBE20851652E5EA1B9F3B5B9F933AA1E22C2D9FB` | Implemented manual handoff; Auto blocked | Download provenance and installer execution policy | Phase 104 implements Analyze/Open manual handoff only. Auto remains blocked because the source downloads and launches Windows 10/Windows 11 Media Creation Tool executables from mutable third-party mirror URLs. No approved artifact provenance, executable launch approval, generated-file ownership, reboot/session, recovery, or support contract exists yet. Phase 58 scope/provenance design: `docs/tool-designs/reinstall-scope-provenance-design.md`; migration record: `docs/migrations/reinstall.md`. | Future Auto requires download provenance and checksum/signature policy; installer execution policy; reboot/recovery workflow; file state capture for generated executable paths | Windows 10 branch is unsupported; Windows 10 host use is limited to manual handoff for the Windows 11 target outcome | `Refresh Reinstall Auto Approval Package` | No for manual handoff; Yes for Auto |
| `updates-drivers-block` | Updates Drivers Block | Refresh | `source-ultimate/2 Refresh/3 Updates Drivers Block.ps1` | `4D4EC652C5A7F78824F53B7DC7FD46DDA948F3716A7CD6FD102D6C678EE11991` | Implemented controlled live policy; broader branches blocked | Reboot/recovery workflow for blocked branches | Phase 102 implements only the bounded live Driver Updates policy branch. Broad Windows Updates, custom update-server URL, bootable-media `setupcomplete.cmd`, generated-script, external-process, and embedded reboot branches remain blocked. Scope design: `docs/tool-designs/updates-drivers-block-scope-design.md`. | Future broad Updates or bootable-media work still needs reboot/recovery workflow; file state capture; generated-script ownership policy; exact update-server URL approval | Shared Windows live Driver Updates policy behavior is implemented; explicit Windows 10-only optimization branches remain unsupported | `Update and Driver Policy Assistant - Broad Branch Approval` | No for live driver policy; Yes for blocked branches |
| `edge-settings` | Edge Settings | Setup | `source-ultimate/3 Setup/6 Edge Settings.ps1` | `342869157930ECF0869A07B4254CB8F174C63648CD329DB3914BAD291CD5FF28` | Refused | Download provenance and checksum/signature policy | Current catalog suggests an `Open`-style tool, but source changes policy, RunOnce, services, and downloads a repair installer. Phase 63 scope design: `docs/tool-designs/edge-settings-scope-design.md`. | Download provenance and checksum/signature policy; installer execution policy; service state capture and rollback; file/registry state capture and rollback | No scope exception | `Edge Policy and Repair Workflow` | Yes |
| `installers` | Installers | Installers | `source-ultimate/4 Installers/1 Installers.ps1` | `1065D64183457D4E7B28EA78DDE41525EC8F7C4A4BCA12D29B70D991141C0C67` | Implemented manual handoff; Auto blocked | Installer execution policy | Phase 105 implements Analyze/Open manual handoff only. Auto remains blocked because the source downloads 24 external artifacts and launches installers/helpers with per-app post-install changes, shortcut cleanup, service deletion, task removal, uninstall calls, and policy/config edits. Phase 59 scope/provenance design: `docs/tool-designs/installers-scope-provenance-design.md`; migration record: `docs/migrations/installers.md`. | Future Auto requires download provenance and checksum/signature policy; installer execution policy; service state capture and rollback; file/registry state capture and rollback; destructive cleanup policy; scheduled task governance; app inventory and support policy | NVIDIA-only scope helps only for FrameView/Nvidia App; most blockers are GPU-neutral multi-installer governance | `Approved Installer Framework` | No for manual handoff; Yes for Auto |
| `driver-install-debloat-settings` | Driver Install Debloat & Settings | Graphics | `source-ultimate/5 Graphics/1 Driver Install Debloat & Settings.ps1` | `E69EFF538E7CE6108233C525A2BB88BA2D549CE6954AE751BE7BED778271C26F` | Implemented manual handoff; Auto blocked | Driver state capture and rollback | Phase 99 implements Analyze/Open manual handoff only. Auto remains blocked because the NVIDIA path downloads unpinned tools, debloats extracted driver contents, installs drivers, imports profiles, writes registry, deletes files, removes packages, and restarts. AMD/Intel branches are product-scope unsupported. Phase 60 scope/provenance design: `docs/tool-designs/driver-install-debloat-settings-scope-provenance-design.md`. | Download provenance and checksum/signature policy; installer execution policy; driver state capture and rollback; reboot/recovery workflow; file/registry state capture and rollback; AppX inventory/restore; destructive cleanup policy | AMD and Intel branches must stay disabled; only NVIDIA Auto could ever be considered later with exact artifacts, driver scopes, profile scopes, AppX scopes, cleanup scopes, and reboot workflow | `Graphics Driver Auto Approval Package` | No for manual handoff; Yes for Auto |
| `directx` | DirectX | Graphics | `source-ultimate/5 Graphics/2 DirectX.ps1` | `17051A2F0F7A0CF16BE525121720406E8F1630C94E5977A7CD4C18652A87EE05` | Implemented manual handoff; Auto blocked | Download provenance and checksum/signature policy | Phase 100 implements Analyze/Open manual handoff only. Auto remains blocked because the source uses mutable `refs/heads/main` downloads for unverified `7zip.exe` and `directx.exe`, then installs/configures 7-Zip, changes Start Menu state, extracts DirectX, and launches an independently unverified `DXSETUP.exe`. | Future Auto requires immutable artifact sources; exact hash, size, signer, license, extraction inventory, and `DXSETUP.exe` provenance; approved installer execution; exact file/registry/shortcut/temp scopes | No scope exception | `DirectX Artifact Approval and Installer Execution` | No for manual handoff; Yes for Auto |
| `visual-cpp` | Visual C++ | Graphics | `source-ultimate/5 Graphics/3 C++.ps1` | `7ACB1F25ECFEEAD83FA389E2D0C1FEEF12232C4E9A740CB5DE64A326FFD38C09` | Implemented manual handoff; Auto blocked | Download provenance and checksum/signature policy | Phase 101 implements Analyze/Open manual handoff only. Auto remains blocked because the source downloads twelve x86/x64 redistributables from mutable `refs/heads/main` mirror URLs and launches every package with version-specific quiet or passive switches, but provides no hashes, sizes, signer requirements, authoritative release evidence, exit-code rules, or temp ownership policy. | Future Auto requires immutable artifact sources and exact hash, size, version, signer, license, and redistributability evidence for all twelve files; approved installer requests, exit-code rules, and exact generated-temp-path scopes | No scope exception | `Visual C++ Artifact Approval and Installer Execution` | No for manual handoff; Yes for Auto |
| `start-menu-taskbar` | Start Menu Taskbar | Windows | `source-ultimate/6 Windows/1 Start Menu Taskbar.ps1` | `88BEB0E8C41F7A32AAE6A0A6E184E87E678FB25BEDEB092C63F4BA98B8712E91` | Refused | File/registry state capture and rollback | Replaces `start2.bin`, deletes Quick Launch state, writes policy XML, and terminates Explorer without captured prior user state. Phase 49 scope design: `docs/tool-designs/start-menu-taskbar-scope-design.md`. | File/registry state capture and rollback; destructive cleanup policy | No scope exception | `Start and Taskbar State Migration` | Yes |
| `copilot` | Copilot | Windows | `source-ultimate/6 Windows/8 Copilot.ps1` | `21B58212B241A6C0B74582063E3E74F746014E9137194B58B088CC6692F22A90` | Refused | AppX/package inventory and restore framework | Registry-only behavior would weaken Ultimate; full source removes/re-registers AppX and stops a broad process set. Phase 62 scope design: `docs/tool-designs/copilot-scope-design.md`. | AppX/package inventory and restore framework; process-handling policy | No scope exception | `Copilot Package and Policy Workflow` | Yes |
| `bloatware` | Bloatware | Windows | `source-ultimate/6 Windows/11 Bloatware.ps1` | `36677A334B37025A7234F4320EE54EF50E9528D1814E2B3A463EEB564C5814F5` | Refused | AppX/package inventory and restore framework | Broad AppX removal/re-registration, services, downloads, installers, security-related features, and deletion with no single reversible baseline. Phase 51 scope design: `docs/tool-designs/bloatware-scope-design.md`. | AppX/package inventory and restore framework; service state capture and rollback; destructive cleanup policy; download provenance and installer execution policies | No scope exception | `Bloatware Analysis and Package Plan` | Yes |
| `game-bar` | GameBar | Windows | `source-ultimate/6 Windows/12 Gamebar.ps1` | `8C6703E68C251D63ADD81A87B7CB6C1F572A4CE55A1E092C33B9B444A9884E59` | Refused | TrustedInstaller execution framework | Full source removes AppX, uninstalls GameInput, changes services/protocols, downloads repair tools, and uses TrustedInstaller. Phase 61 scope design: `docs/tool-designs/gamebar-scope-design.md`. | AppX/package inventory and restore framework; TrustedInstaller execution framework; download provenance and installer execution policies; service state capture and rollback | No scope exception | `GameBar and Gaming Services Repair` | Yes |
| `edge-webview` | Edge & WebView | Windows | `source-ultimate/6 Windows/13 Edge & WebView.ps1` | `161ED9C99D437E45650369CB7E15D5737DED363712E647138F134B049AC7E691` | Refused | Destructive cleanup policy | Removes Edge/WebView files and services, changes RunOnce, and downloads repair installers. Phase 52 scope design: `docs/tool-designs/edge-webview-scope-design.md`. | Download provenance and checksum/signature policy; installer execution policy; service state capture and rollback; destructive cleanup policy; file/registry state capture and rollback | No scope exception | `Edge and WebView Removal/Repair` | Yes |
| `control-panel-settings` | Control Panel Settings | Windows | `source-ultimate/6 Windows/15 Control Panel Settings.ps1` | `B78F643D21069F14E7E766769FB1EE15AEF974ABDF3CA010FE808D9EC162FB0B` | Refused | TrustedInstaller execution framework | Very large optimization source with services, deletion, security-sensitive policy, and TrustedInstaller. Current `Open` metadata understates risk. Phase 64 scope design: `docs/tool-designs/control-panel-settings-scope-design.md`. | TrustedInstaller execution framework; service state capture and rollback; file/registry state capture and rollback; destructive cleanup policy | No scope exception | `Control Panel Settings Decomposition` | Yes |
| `write-cache-buffer-flushing` | Write Cache Buffer Flushing | Windows | `source-ultimate/6 Windows/20 Write Cache Buffer Flushing.ps1` | `67D8CA0FECBFD9FCE7D2C81CE1713F1B08E83B729DC8FEC7B8C2E33806F9AD5D` | Implemented in Phase 47 | File/registry state capture and rollback | Phase 47 preserves Apply with exact value capture and refuses source Default because it deletes complete device `Disk` subkeys. | Future Restore would require a reviewed captured-state selection flow; Default remains unavailable. | No scope exception; NVME Faster Driver must remain deleted | `Storage Write Cache Restore Review` | No |
| `cleanup` | Cleanup | Windows | `source-ultimate/6 Windows/22 Cleanup.ps1` | `3419A995AD4483A145999B659268302F02BE982733DE831554ADA1C40F07CCAA` | Refused | Destructive cleanup policy | Recursively deletes temp data, `Windows.old`, `inetpub`, `PerfLogs`, and dumps with no approved rollback path. Phase 50 scope design: `docs/tool-designs/cleanup-scope-design.md`. | Destructive cleanup policy; file/registry state capture and rollback | No scope exception | `Cleanup Inventory and Confirmation` | Yes |
| `resizable-bar-assistant` | Resizable BAR Assistant | Advanced | `source-ultimate/8 Advanced/3 Resizable BAR Assistant.ps1` | `E2E1D919B350FA5190DFD4FAF23F3AB51ED2A324155CAFF49CDE774B092FB443` | Refused | Driver state capture and rollback | NVIDIA-only in scope, but still downloads NVIDIA Profile Inspector from a mutable URL, writes generated `.nip` files, unblocks NVIDIA DRS files, imports driver profiles, opens Inspector, and includes firmware restart. Phase 56 scope design: `docs/tool-designs/resizable-bar-assistant-scope-design.md`. | Download provenance and checksum/signature policy; file/registry state capture; driver state capture and rollback; reboot/recovery workflow | AMD and Intel remain disabled; NVIDIA-only path could be revisited later with exact artifact, driver-profile, and firmware scopes | `Resizable BAR Driver and Firmware Assistant` | Yes |
| `services-optimizer` | Services Optimizer | Advanced | `source-ultimate/8 Advanced/5 Services Optimizer.ps1` | `386EEF403F48907E82C2E8E4BE5DFE509B0ED93CADBB5639B42D6326163EDB8F` | Refused | Safe Mode recovery/resume framework | Heavy multi-stage privileged workflow with Safe Mode, TrustedInstaller, RunOnce, service/security changes, generated scripts/REG files, and reboot behavior. Phase 53 scope design: `docs/tool-designs/services-optimizer-scope-design.md`. | Safe Mode recovery/resume framework; TrustedInstaller execution framework; service state capture and rollback; reboot/recovery workflow | No scope exception | `Services Optimizer Recovery Architecture` | Yes |
| `timer-resolution-assistant` | Timer Resolution Assistant | Advanced | `source-ultimate/8 Advanced/6 Timer Resolution Assistant.ps1` | `883F7CF4E6179383DE02E44B94FFC8DAFD380246751F1B1D81CAB8800B1E8621` | Refused | Service state capture and rollback | Narrower than Services Optimizer, but still generates C# under `C:\Windows`, compiles a binary, creates/removes a service, changes protected timer registry state, and deletes scoped files without approved provenance or service rollback guarantees. Phase 55 scope design: `docs/tool-designs/timer-resolution-assistant-scope-design.md`. | Service state capture and rollback; file/registry state capture; compiler/generated artifact approval; destructive cleanup policy | No scope exception | `Timer Resolution Service Assistant` | Yes |
| `defender-optimize-assistant` | Defender Optimize Assistant | Advanced | `source-ultimate/8 Advanced/7 Defender Optimize Assistant.ps1` | `512F12D805715E9232304ABE5BA400BE6B3965D63F77D3B39E4C304507BFB9B6` | Refused | Safe Mode recovery/resume framework | Security-sensitive workflow using TrustedInstaller, Safe Mode, RunOnce, BCD edits, generated scripts, scheduled task changes, Defender/security registry mutation, and repeated reboots. Phase 54 scope design: `docs/tool-designs/defender-optimize-assistant-scope-design.md`. | Safe Mode recovery/resume framework; TrustedInstaller execution framework; service state capture and rollback; reboot/recovery workflow | No scope exception | `Defender Safe Mode Recovery Assistant` | Yes |

## Foundation Groups

### Download provenance and checksum/signature policy

Needed when a tool downloads any executable, installer, archive, or helper.

Phase 35 establishes the deny-by-default manifest schema and inert local verification helpers. It approves no real artifacts and does not by itself make any deferred tool executable. Each future artifact still needs a dedicated approval record, manually verified source/hash/signature evidence, and tool-specific tests.

The Phase 45 DirectX provenance review is documented in
`docs/directx-provenance-review.md`. Phase 100 implements controlled
manual handoff only. DirectX Auto remains blocked because its source URLs are
mutable, required hash/signer evidence is absent, extracted `DXSETUP.exe` is
not independently approved, and installer execution remains inert.

The Phase 46 Visual C++ provenance review is documented in
`docs/visual-cpp-provenance-review.md`. Phase 101 implements controlled manual
handoff only. Visual C++ Auto remains blocked because all twelve source URLs
are mutable, required hash/size/version/signer evidence is absent, and no
installer or temp-file scope is approved.

Affected tools:

* `edge-settings`
* `installers`
* `game-bar`
* `edge-webview`
* `resizable-bar-assistant`
* `timer-resolution-assistant`

### Installer execution policy

Needed when a tool launches MSI, EXE, setup, or repair packages and BoostLab must define allowed switches, visible/non-visible execution rules, exit-code handling, and post-install verification.

Phase 35 establishes the request-validation and non-executing runtime boundary. Real process launch remains disabled until a later phase approves the execution implementation and at least one real artifact.

Affected tools:

* `edge-settings`
* `installers`
* `driver-install-debloat-settings`
* `game-bar`
* `edge-webview`

### Process handling policy

Needed before a tool can detect, wait for, gracefully close, stop, restart, or
handoff to a process outside currently implemented safe launchers.

Phase 68 establishes exact process operation vocabulary, required process
metadata, shell/Explorer handling rules, tool-owned cleanup boundaries, UI and
Activity Log expectations, and deny-by-default mock validation helpers. It
approves no production process targets and performs no real process operation.

The affected tools remain deferred because each still needs exact production
process scopes, tool-specific confirmation text, and its remaining AppX,
registry, service, cleanup, installer, TrustedInstaller, Safe Mode, reboot, or
artifact approvals.

Affected tools:

* `copilot`
* `start-menu-taskbar`
* `game-bar`
* `edge-settings`
* `edge-webview`
* `control-panel-settings`
* `defender-optimize-assistant`
* `services-optimizer`
* `driver-install-debloat-settings`

### AppX/package inventory and restore framework

Needed before any tool removes, re-registers, or repairs Store/AppX packages and before any Restore claim can be meaningful.

Phase 39 establishes exact package/tool/action scopes, protected-package
defaults, pre-mutation inventory records, integrity and age validation,
separate current-user/all-user/provisioned mutation gates, callback-only
execution, structured verification, and record-based restore planning. It
approves no production package scopes and performs no real package operation.

The affected tools remain deferred because each still needs exact package
allowlists, per-package rollback decisions, and other foundations required by
its Ultimate source.

Affected tools:

* `copilot`
* `bloatware`
* `game-bar`

### TrustedInstaller execution framework

Needed for tools whose approved Ultimate source explicitly depends on TrustedInstaller-level execution.

Phase 42 establishes exact tool/action/command/target scopes, structured
argument-only requests, Administrator-host and confirmation gating, required
adjacent-foundation references, verification plans, timeouts, logging,
recovery metadata, and an inert execution boundary. It approves no production
TrustedInstaller scope and starts no privileged process.

The affected tools remain deferred because each still needs an exact
tool-specific command/target allowlist, separately approved execution
implementation, and its remaining service, AppX, cleanup, Safe Mode, reboot,
download, installer, file/registry, or security foundations.

Affected tools:

* `game-bar`
* `control-panel-settings`
* `services-optimizer`
* `defender-optimize-assistant`

### Safe Mode recovery/resume framework

Needed for multi-stage tools that change boot flow and must survive interruption or failed resumes.

Phase 43 establishes exact tool/action/type scopes, required Phase 40 reboot
workflow references, pre-Safe-Mode checkpoints, verified adjacent-foundation
state records, bounded known resume handlers, mandatory exit plans,
integrity-protected workflow records, cancellation, expiration, machine-state
validation, structured verification, and recovery guidance. It approves no
production Safe Mode scope and performs no BCD, reboot, RunOnce, Scheduled
Task, service, TrustedInstaller, registry, protected-file, or process action.

The affected tools remain deferred because each still needs an exact
tool-specific Safe Mode allowlist, approved execution implementation, exact
service/security/TrustedInstaller operations, and recovery tests for its
source-defined workflow.

Affected tools:

* `services-optimizer`
* `defender-optimize-assistant`

### Service state capture and rollback

Needed before changing or deleting services so BoostLab can prove what changed and restore a captured prior state where appropriate.

Phase 37 establishes exact-name policy scopes, integrity-protected service state records, post-mutation identity checks, read-only verification, and callback-based rollback for explicitly eligible startup type, delayed auto-start, and running status. It approves no production service names and does not enable service creation, deletion, recreation, protected-service changes, or arbitrary configuration rollback.

The affected tools below remain deferred because their Ultimate behavior also depends on downloads/installers, AppX operations, TrustedInstaller, Safe Mode, driver handling, destructive cleanup, reboot recovery, broad multi-service plans, or service create/delete semantics that Phase 37 intentionally does not provide.

Affected tools:

* `edge-settings`
* `installers`
* `driver-install-debloat-settings`
* `bloatware`
* `game-bar`
* `edge-webview`
* `control-panel-settings`
* `services-optimizer`
* `timer-resolution-assistant`
* `defender-optimize-assistant`

### Driver state capture and rollback

Needed before driver installers, profile imports, vendor-service removals, or graphics-driver registry changes.

Phase 41 establishes exact tool/action/device/package scopes, NVIDIA-only GPU
governance, pre-mutation inventory records, provenance and reboot-reference
requirements, integrity/age validation, current-device identity checks,
callback-only mutation/rollback, and persisted verification. It approves no
production driver targets and performs no real driver or device operation.

The affected tools remain deferred because each still needs an exact
tool-specific NVIDIA scope, approved artifacts/installers or profile sources,
operation-specific rollback decisions, and the other foundations required by
its Ultimate source.

Affected tools:

* `driver-install-debloat-settings`
* `resizable-bar-assistant`

### File/registry state capture and rollback

Needed where Ultimate replaces user/system files, writes broad registry state, or deletes keys/values that cannot be reconstructed safely without a captured baseline.

Phase 36 establishes integrity-protected records, bounded file and registry scopes, verified file backups, post-mutation identity checks, and deny-by-default rollback helpers. It approves no production scopes and does not enable any deferred tool. Each future migration still needs exact tool-specific paths and rollback rules.

Affected tools:

* `start-menu-taskbar`
* `edge-settings`
* `edge-webview`
* `control-panel-settings`

`updates-drivers-block` used this foundation in Phase 102 for exact live Driver
Updates policy value capture. It is no longer a remaining placeholder, but its
broad Windows Updates and bootable-media branches still need future exact
registry/file/reboot scope approval.

`write-cache-buffer-flushing` used this foundation in Phase 47 for Apply-only
value capture. It is no longer a remaining placeholder, but any future Restore
still needs a reviewed captured-state selection flow.

### Destructive cleanup policy

Needed for tools that remove files, folders, extracted components, package debris, or registry trees where “delete what Ultimate deleted” is not automatically safe enough for BoostLab.

Phase 38 establishes exact bounded target scopes, broad-root and reparse-point denial, recursive file-count/byte limits, mandatory confirmation, state-capture evidence requirements, callback-only execution, and integrity-protected quarantine records. It approves no production cleanup targets and does not perform real deletion or quarantine.

The affected tools remain deferred because they still need exact per-tool ownership decisions and additional foundations such as AppX inventory, installer provenance, driver rollback, service recovery, TrustedInstaller, Safe Mode, registry rollback, or reboot continuation.

Affected tools:

* `driver-install-debloat-settings`
* `edge-webview`
* `cleanup`
* `control-panel-settings`
* `bloatware`
* `timer-resolution-assistant`

`write-cache-buffer-flushing` no longer depends on destructive cleanup policy
for Phase 47 because the source Default broad `Disk` key deletion was refused.

### Reboot/recovery workflow

Needed when a tool can reboot, hand control to firmware or setup, or leave the machine mid-workflow.

Phase 40 establishes exact tool/action scopes, persisted workflow records,
mandatory checkpoints and state references, bounded known resume handler ids,
machine-state validation, cancellation, recovery instructions, expiration, and
structured post-reboot verification. Production scopes remain empty, and
reboot and scheduling entry points return `NotImplemented`.

The affected tools remain deferred because each still requires an approved
tool-specific workflow scope and additional foundations such as installer
approval, driver rollback, TrustedInstaller, Safe Mode recovery, security
governance, or exact service and state plans.

Affected tools:

* `reinstall`
* `driver-install-debloat-settings`
* `resizable-bar-assistant`
* `services-optimizer`
* `defender-optimize-assistant`

`updates-drivers-block` no longer depends on reboot/recovery for its Phase 102
live Driver Updates policy implementation. Its bootable-media generated-script
branches remain blocked until a future reboot/recovery workflow is approved.

## Recommended Foundation Roadmap

1. **Download provenance and checksum/signature policy**
   This unblocks the broadest set of deferred tools and prevents every future download phase from reinventing trust rules.
2. **Installer execution policy**
   This should define visible vs silent installs, switch allowlists, exit-code handling, temp-file ownership, and verification expectations.
3. **File/registry state capture and rollback**
   This is the baseline for any future `Default` narrowing or true `Restore` path on system-state tools.
4. **Service state capture and rollback**
   Phase 37 adds the deny-by-default capture, verification, and guarded startup/status rollback contract. Future work still needs explicit per-tool service scopes and separate approval for protected services, create/delete/recreation, multi-service recovery, and interrupted workflows.
5. **Destructive cleanup policy**
   Phase 38 adds deny-by-default bounded cleanup planning, confirmation, verification, and quarantine records. Future work still needs exact per-tool targets, ownership approval, Phase 36 capture scopes where rollback is claimed, and the other foundations required by each source.
6. **AppX/package inventory and restore framework**
   This is required for Copilot, Bloatware, and GameBar-class tools.
7. **Reboot/recovery workflow**
   This should cover preflight, confirmation, interrupted-run state, and post-restart continuation.
8. **Driver state capture and rollback**
   Phase 41 adds the deny-by-default inventory, verification, and guarded rollback contract. Future work still needs exact NVIDIA device/package scopes, approved provenance, execution implementation, and tool-specific rollback tests.
9. **TrustedInstaller execution framework**
   Phase 42 adds deny-by-default structured request validation, foundation references, verification, logging, and recovery policy. Future work still needs exact tool scopes and a separately approved process implementation.
10. **Safe Mode recovery/resume framework**
    Phase 43 adds the deny-by-default Safe Mode planning, record, resume, exit,
    cancellation, and recovery contract. Future work still needs exact
    per-tool allowlists and a separately approved execution implementation;
    no deferred tool is enabled by the foundation alone.
11. **Process handling policy**
    Phase 68 adds the deny-by-default process operation vocabulary, metadata
    requirements, Explorer handling rules, and mock-only validation helpers.
    Future work still needs exact production process scopes and tool-specific
    implementation approval.

## What This Means for Future Phases

* Refused tools are blocked, not abandoned.
* A future phase should pick one foundation at a time, implement that foundation, and then migrate only the tools unlocked by it.
* Visual-only or disabled cards are the correct state for these tools until their prerequisites exist.
* No future phase should “just do the safe part” of one of these tools when that would weaken the effective Ultimate behavior.

## First-Pass Completion State

The first migration pass established the runtime, confirmation, logging, state, verification, and assistant patterns needed for low- to medium-risk tools.

The remaining placeholders are concentrated in the heavy-governance categories above. The next project milestone is therefore foundation-building, not opportunistic tool migration.

NVIDIA Path B readiness badge design is tracked in
`docs/tool-designs/nvidia-path-b-readiness-badge-design.md`. It is a
documentation-only status/badge design and does not enable any deferred tool,
placeholder, production scope, artifact, runtime workflow, or UI action.

NVIDIA Path B path conflict copy/status text design is tracked in
`docs/tool-designs/nvidia-path-b-path-conflict-copy-status-text-design.md`. It
is documentation-only future wording guidance and does not add live UI strings,
localization files, runtime workflow config, production scope, artifact, or
tool behavior.

NVIDIA Path B non-executing catalog preview data design is tracked in
`docs/tool-designs/nvidia-path-b-non-executing-catalog-preview-data-design.md`.
It is documentation-only preview metadata guidance and does not create an
active runtime catalog, UI config, production scope, artifact, or tool behavior.

NVIDIA Path B preview data integrity/drift rules design is tracked in
`docs/tool-designs/nvidia-path-b-preview-data-integrity-drift-rules-design.md`.
It is documentation-only governance for future preview consistency and does not
create a live drift checker, active preview config, production scope, artifact,
or tool behavior.

NVIDIA Path B documentation index/navigation design is tracked in
`docs/tool-designs/nvidia-path-b-documentation-index-navigation-design.md`. It
is documentation-only navigation guidance and does not create active docs
runtime, active UI/runtime config, production scope, artifact, or tool behavior.

NVIDIA Path B documentation backlink audit design is tracked in
`docs/tool-designs/nvidia-path-b-documentation-backlink-audit-design.md`. It is
documentation-only backlink audit guidance and does not create a live backlink
auditor, active docs runtime, active UI/runtime config, production scope,
artifact, or tool behavior.

NVIDIA Path B governance freeze review is tracked in
`docs/tool-designs/nvidia-path-b-governance-freeze-review.md`. It is
documentation-only freeze guidance and does not create active governance
runtime, active docs runtime, production scope, artifact, or tool behavior.

Driver Clean controlled intake implementation readiness is tracked in
`docs/tool-designs/driver-clean-controlled-intake-implementation-readiness.md`.
It is a focused readiness decision, not implementation approval. Driver Clean
remains outside NVIDIA Path B, and the DDU intake exception does not approve
standalone DDU, DDU downloads, DDU artifacts, uncontrolled DDU execution,
production scopes, or tool behavior.

Driver Clean controlled implementation planning is tracked in
`docs/tool-designs/driver-clean-controlled-implementation-plan.md`. It selects
manual handoff as the safest future first slice and keeps Auto blocked until
artifact, process, Safe Mode, RunOnce, reboot/recovery, generated-script, and
driver-state approvals exist.


