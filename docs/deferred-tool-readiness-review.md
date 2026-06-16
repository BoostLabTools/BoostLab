# Deferred Tool Readiness Review

## Purpose

This review reassesses every currently deferred BoostLab tool after the
foundation sequence in Phases 35 through 43.

The goal is not to re-open implementation. The goal is to answer a narrower
question:

* Which deferred tools are closer to implementation because the shared
  foundations now exist?
* Which ones are still blocked by missing approvals, exact allowlists, or
  unresolved tool-specific design?

All existing foundations remain deny-by-default. No production scope, artifact,
installer, driver, TrustedInstaller command, or Safe Mode workflow becomes
approved just because a foundation now exists.

## Review Inputs

This review is based on:

* `docs/deferred-tools-execution-plan.md`
* `docs/download-provenance-installer-policy.md`
* `docs/file-registry-state-capture-rollback.md`
* `docs/destructive-cleanup-policy.md`
* `docs/appx-package-inventory-restore.md`
* `docs/reboot-recovery-workflow.md`
* `docs/driver-state-capture-rollback.md`
* `docs/safe-mode-recovery-resume.md`
* `docs/trusted-installer-execution.md`
* The Phase 35-43 policy files under `config/`
* The current placeholder inventory in `config/Stages.psd1` and `modules/`

Current inventory:

* Active tools: **48**
* Implemented tools: **30**
* Deferred/placeholders: **18**

## Category Definitions

* **Not ready:** still missing a major governance layer or decomposition step,
  even after the foundation phases.
* **Foundation-ready but needs production allowlists:** the shared foundation
  exists, but the tool still needs exact production scopes or bounded target
  allowlists before implementation can begin.
* **Foundation-ready but needs artifact provenance approvals:** the runtime
  model exists, but real reviewed artifacts and exact execution approvals do not.
* **Foundation-ready but needs tool-specific design:** the generic foundations
  exist, but the tool still needs a deliberate behavior design or decomposition
  before exact scopes can be approved safely.
* **Candidate for next implementation attempt:** not safe yet, but the remaining
  gap is comparatively narrow and a dedicated tool phase could reasonably start
  next.

## Readiness Summary

* Not ready: **3**
* Foundation-ready but needs production allowlists: **3**
* Foundation-ready but needs artifact provenance approvals: **8**
* Foundation-ready but needs tool-specific design: **4**
* Candidate for next implementation attempt: **0**

## Per-Tool Review

| Tool title | Tool id | Stage | Current status | Original refusal / defer reason | Foundations now available that help | Foundations still missing or not approved | Required production allowlists / artifact approvals before implementation | Can start next | Category | Recommended next action |
|---|---|---|---|---|---|---|---|---|---|---|
| Reinstall | `reinstall` | Refresh | Refused placeholder | Windows 10 and Windows 11 Media Creation Tool download/launch workflow from mutable third-party mirror URLs | Download provenance, installer policy, reboot workflow | No approved Windows 11 setup artifact, no hash/signer/size/version evidence, no approved executable launch, no approved reboot or handoff scope for this tool; Windows 10 branch is unsupported | Exact Windows 11 media artifact, signer/hash/size evidence, exact command line, exact generated-file scope, exact reboot/handoff scope | No | Foundation-ready but needs artifact provenance approvals | Use `docs/tool-designs/reinstall-scope-provenance-design.md` before any second attempt |
| Updates Drivers Block | `updates-drivers-block` | Refresh | Refused placeholder | Mixed live HKLM Windows Update and driver-delivery policy changes, custom update-server URL values, bootable-media `setupcomplete.cmd` generation, and embedded reboot commands | File/registry rollback, cleanup/generated-script policy, reboot workflow | No exact production registry scopes, no approved update-server URL scope, no approved generated-script/media file scope, no approved reboot workflow scope | Exact live-policy scopes, exact update-server URL approval, exact generated-script/media scopes, exact reboot workflow scope, exact decision on whether media-generation branches stay deferred | No | Foundation-ready but needs production allowlists | Use `docs/tool-designs/updates-drivers-block-scope-design.md` before any second attempt |
| Edge Settings | `edge-settings` | Setup | Refused placeholder | Source is not open-only; uses policy, Active Setup, RunOnce, services, and repair download | File/registry rollback, service rollback, download/installer policy | No dedicated RunOnce/Active Setup governance, no approved repair artifacts, no approved service scopes | Exact policy/service/file scopes and any repair artifact approvals | No | Not ready | Use `docs/tool-designs/edge-settings-scope-design.md`, then decompose the source into policy, service, task, process, and repair behaviors before any migration phase |
| Installers | `installers` | Installers | Refused placeholder | Multi-app download/install workflow with post-install registry, service, task, shortcut, config, and uninstall side effects | Download provenance, installer policy, service rollback, file/registry rollback, cleanup policy | No approved app list, no approved artifacts, no approved execution descriptors, no scheduled task governance, no approved per-app side-effect design | Exact artifact records, exact install commands, exact per-app service/policy/file/task/shortcut/config/uninstall allowlists | No | Foundation-ready but needs artifact provenance approvals | Use `docs/tool-designs/installers-scope-provenance-design.md` before any second attempt |
| Driver Install Debloat & Settings | `driver-install-debloat-settings` | Graphics | Refused placeholder | NVIDIA path still downloads tools, installs drivers, imports profiles, removes components, and reboots; AMD/Intel branches are product-scope unsupported | Download provenance, installer policy, driver rollback, reboot workflow, file/registry rollback, AppX policy, cleanup policy | No approved NVIDIA artifacts, no approved user-selected-driver validation, no approved driver scopes, no approved profile/AppX/cleanup/reboot scopes; AMD/Intel branches remain disabled | Exact NVIDIA device/package scopes, exact artifact approvals, exact profile/AppX/cleanup/registry scopes, exact reboot workflow, exact refusal of AMD/Intel branches | No | Foundation-ready but needs artifact provenance approvals | Use `docs/tool-designs/driver-install-debloat-settings-scope-provenance-design.md` before any second attempt |
| DirectX | `directx` | Graphics | Refused placeholder after Phase 45 provenance review | Downloads/extracts tools, installs/configures 7-Zip, changes Start Menu state, and launches DirectX runtime installer | Download provenance, installer policy, file/registry rollback, and cleanup policy | Source URLs are mutable branch references; no approved hashes, sizes, signers, extraction inventory, `DXSETUP.exe` provenance, installer execution, or exact side-effect scopes | Immutable artifact sources, exact hash/size/signer evidence for downloads and extracted executables, approved installer requests, and exact registry/file/shortcut/temp scopes | No | Foundation-ready but needs artifact provenance approvals | Keep disabled until the complete approval package in `docs/directx-provenance-review.md` exists |
| Visual C++ | `visual-cpp` | Graphics | Refused placeholder after Phase 46 provenance review | Downloads twelve redistributables from mutable mirror URLs and installs every x86/x64 package with version-specific switches | Download provenance and installer policy | All source URLs are mutable branch references; no approved hashes, sizes, package versions, signers, authoritative source evidence, exit-code rules, installer execution, or temp ownership scopes | Immutable artifact sources and exact hash/size/version/signer evidence for all twelve packages, approved installer requests and exit-code rules, and exact generated-temp-path scopes | No | Foundation-ready but needs artifact provenance approvals | Keep disabled until the complete approval package in `docs/visual-cpp-provenance-review.md` exists |
| Start Menu Taskbar | `start-menu-taskbar` | Windows | Refused placeholder | Replaces layout files, deletes state, writes policy, and restarts Explorer | File/registry rollback and cleanup policy | No approved file/registry/cleanup scopes, no approved ownership rule for replaced user state | Exact file targets, exact registry targets, exact cleanup ownership rules, exact rollback design | No | Foundation-ready but needs production allowlists | Use `docs/tool-designs/start-menu-taskbar-scope-design.md` before any second attempt |
| Copilot | `copilot` | Windows | Refused placeholder | Registry-only implementation would weaken Ultimate; full source removes/re-registers AppX and stops many processes | AppX inventory and restore foundation | No process-handling governance, no exact package/process policy for this tool | Exact package scope and a separately approved process-handling model | No | Not ready | Use `docs/tool-designs/copilot-scope-design.md`, then keep deferred until process-stop governance is defined or the tool is redesigned |
| Bloatware | `bloatware` | Windows | Refused placeholder | Broad AppX, service, cleanup, download, and repair workflow | AppX inventory, service rollback, cleanup policy, download/installer policy | No approved package list, no approved service scopes, no approved cleanup ownership map, no unified restore design | Exact package allowlists, exact service scopes, exact cleanup scopes, any artifact approvals | No | Foundation-ready but needs tool-specific design | Use `docs/tool-designs/bloatware-scope-design.md` before any second attempt |
| GameBar | `game-bar` | Windows | Refused placeholder | AppX, service, download, repair, and TrustedInstaller workflow | AppX inventory, service rollback, download/installer policy, TrustedInstaller policy | No approved package scopes, no approved TI scope, no approved repair artifacts, no exact service targets | Exact package/service/TI scopes and exact repair artifact approvals | No | Foundation-ready but needs tool-specific design | Use `docs/tool-designs/gamebar-scope-design.md` before any second attempt |
| Edge & WebView | `edge-webview` | Windows | Refused placeholder | File/service deletion plus repair installers and RunOnce changes | File/registry rollback, cleanup policy, service rollback, download/installer policy | No approved repair artifacts, no approved service scopes, no approved file cleanup ownership map | Exact service scopes, exact cleanup scopes, exact repair artifacts and installer requests | No | Foundation-ready but needs artifact provenance approvals | Use `docs/tool-designs/edge-webview-scope-design.md` before any second attempt |
| Control Panel Settings | `control-panel-settings` | Windows | Refused placeholder | Very broad optimization source with services, security, deletion, and TrustedInstaller | File/registry rollback, service rollback, cleanup policy, TrustedInstaller policy | Still lacks decomposition into implementable slices; too broad for direct scope approval | Any future work would require many exact sub-tool scopes, not one blanket approval | No | Not ready | Keep deferred until the source is split into smaller approved candidates |
| Cleanup | `cleanup` | Windows | Refused placeholder | Broad recursive deletion with no restore path | Cleanup policy and file rollback foundations | No approved exact cleanup scopes, no approved ownership map, no decision on permanent delete versus quarantine per target | Exact bounded cleanup scopes and per-target ownership/rollback decisions | No | Foundation-ready but needs production allowlists | Use `docs/tool-designs/cleanup-scope-design.md` before any second attempt |
| Resizable BAR Assistant | `resizable-bar-assistant` | Advanced | Refused placeholder | NVIDIA Profile Inspector download from mutable URL, generated `.nip` profile imports, NVIDIA DRS unblocking, driver profile mutation, and firmware restart path | Download provenance, file/registry rollback, driver rollback, reboot workflow | No approved NVIDIA artifact, no approved Inspector execution descriptor, no approved generated `.nip` file scopes, no approved NVIDIA driver profile scope, no approved firmware restart workflow | Exact NVIDIA artifact approval, exact Inspector command descriptors, exact generated `.nip` hashes, exact NVIDIA profile scopes, exact firmware restart scope | No | Foundation-ready but needs artifact provenance approvals | Use `docs/tool-designs/resizable-bar-assistant-scope-design.md` before any second attempt |
| Services Optimizer | `services-optimizer` | Advanced | Refused placeholder | Heavy Safe Mode, TrustedInstaller, service, security, generated script/REG file, RunOnce, BCD, and reboot workflow | Service rollback, reboot workflow, TrustedInstaller policy, Safe Mode policy, cleanup policy | No approved production service scopes, no approved Safe Mode scope, no approved TI scope, no approved RunOnce/BCD/reboot scope, no approved generated-artifact scope | Exact service scopes, exact TI scopes, exact Safe Mode scope, exact file/registry/RunOnce/BCD/reboot scopes | No | Foundation-ready but needs tool-specific design | Use `docs/tool-designs/services-optimizer-scope-design.md` before any second attempt |
| Timer Resolution Assistant | `timer-resolution-assistant` | Advanced | Refused placeholder | Generates C# under `C:\Windows`, compiles a binary, creates/deletes a Windows service, changes timer registry policy, and deletes protected-path files | Service rollback, cleanup policy, file/registry rollback, download/installer provenance model | No approved compiler scope, no generated artifact hash/provenance strategy, no approved service scope, no approved protected-path file scope, no approved registry scope, service identity mismatch unresolved | Exact compiler scope, generated source/binary hashes, exact service scope, exact file/registry scopes, exact cleanup scope | No | Foundation-ready but needs artifact provenance approvals | Use `docs/tool-designs/timer-resolution-assistant-scope-design.md` before any second attempt |
| Defender Optimize Assistant | `defender-optimize-assistant` | Advanced | Refused placeholder | Security-sensitive Safe Mode, TrustedInstaller, Defender/security registry mutation, scheduled task changes, RunOnce, BCD, generated script, and reboot workflow | Service rollback, reboot workflow, TrustedInstaller policy, Safe Mode policy, cleanup policy | No approved security-sensitive scopes, no approved TI scope, no approved Safe Mode scope, no approved scheduled-task/RunOnce/BCD/reboot scope, no approved generated-artifact scope | Exact Defender/security registry scopes, exact task scopes, exact TI scopes, exact Safe Mode scope, exact file/RunOnce/BCD/reboot scopes plus security verification plan | No | Foundation-ready but needs tool-specific design | Use `docs/tool-designs/defender-optimize-assistant-scope-design.md` before any second attempt |
| Write Cache Buffer Flushing | `write-cache-buffer-flushing` | Windows | Implemented in Phase 47 | Apply writes one value; source Default deletes broad disk subkeys | File/registry rollback and cleanup policy | Restore remains unavailable until a reviewed captured-state selection flow exists | None for Phase 47 Apply; future Restore would need exact captured-state selection and verification rules | Complete | Phase 47 complete | Apply is implemented with pre-change value capture; Default remains refused because it would delete complete storage `Disk` keys |

## Readiness Categories

### Not ready

These still need a major governance or decomposition step before exact scopes
would be meaningful:

* Edge Settings
* Copilot
* Control Panel Settings

The Edge Settings tool-specific scope design is documented in
`docs/tool-designs/edge-settings-scope-design.md`.

The Copilot tool-specific scope design is documented in
`docs/tool-designs/copilot-scope-design.md`.

### Foundation-ready but needs production allowlists

These now have enough shared foundation coverage to plan a future migration,
but they still need exact bounded production scopes:

* Updates Drivers Block
* Start Menu Taskbar
* Cleanup

The Updates Drivers Block tool-specific scope design is documented in
`docs/tool-designs/updates-drivers-block-scope-design.md`.

### Foundation-ready but needs artifact provenance approvals

These mostly moved from “missing foundation” to “waiting on exact artifact and
execution approval”:

* Reinstall
* Installers
* Driver Install Debloat & Settings
* DirectX
* Visual C++
* Edge & WebView
* Resizable BAR Assistant
* Timer Resolution Assistant

The Reinstall tool-specific scope/provenance design is documented in
`docs/tool-designs/reinstall-scope-provenance-design.md`.

The Installers tool-specific scope/provenance design is documented in
`docs/tool-designs/installers-scope-provenance-design.md`.

The Driver Install Debloat & Settings tool-specific scope/provenance design is
documented in
`docs/tool-designs/driver-install-debloat-settings-scope-provenance-design.md`.

The Edge & WebView tool-specific scope design is documented in
`docs/tool-designs/edge-webview-scope-design.md`.

The Resizable BAR Assistant tool-specific scope design is documented in
`docs/tool-designs/resizable-bar-assistant-scope-design.md`.

The Timer Resolution Assistant tool-specific scope design is documented in
`docs/tool-designs/timer-resolution-assistant-scope-design.md`.

### Foundation-ready but needs tool-specific design

These now have most generic safety building blocks, but they still need a
deliberate tool design before scopes or artifacts can be approved safely:

* Bloatware
* GameBar
* Services Optimizer
* Defender Optimize Assistant

The Services Optimizer tool-specific scope design is documented in
`docs/tool-designs/services-optimizer-scope-design.md`.

The Defender Optimize Assistant tool-specific scope design is documented in
`docs/tool-designs/defender-optimize-assistant-scope-design.md`.

The Bloatware tool-specific scope design is documented in
`docs/tool-designs/bloatware-scope-design.md`.

The GameBar tool-specific scope design is documented in
`docs/tool-designs/gamebar-scope-design.md`.

### Candidate for next implementation attempt

No deferred tool currently qualifies as a conservative next implementation
attempt without first obtaining production scopes, artifact approvals, or a
tool-specific design.

## Recommended Next Phase List

In conservative order:

1. `Start Menu Taskbar`
   Needs exact owned file/registry scope and rollback decisions, but no new foundation category. The tool-specific scope design is documented in `docs/tool-designs/start-menu-taskbar-scope-design.md`.
2. `Cleanup`
   Needs exact target ownership and quarantine/delete choices before implementation can be attempted safely. The tool-specific scope design is documented in `docs/tool-designs/cleanup-scope-design.md`.

DirectX was removed from the candidate list by the Phase 45 provenance review.
Its source uses mutable branch downloads and lacks the hashes, signer evidence,
extraction inventory, and approved installer execution required by Phase 35.

Visual C++ was removed from the candidate list by the Phase 46 provenance
review. All twelve source packages use mutable branch downloads and lack the
complete hash, size, version, signer, authoritative-source, exit-code, and
installer approvals required by Phase 35.

## Remaining Blockers

The biggest blockers after Phase 43 are no longer “we need a new foundation.”
They are:

* Exact production scopes remain empty across every heavy foundation.
* No real third-party artifacts are approved in the provenance manifest.
* No real installer executions are approved.
* No real driver scopes are approved.
* No real TrustedInstaller scopes are approved.
* No real Safe Mode scopes are approved.
* Several tools still need decomposition before exact scopes can even be proposed.
* Process-handling, RunOnce, and Active Setup behavior still need tool-specific governance where source behavior depends on them.

## Conclusion

The deferred queue is healthier than it was before Phases 35 through 43. The
project now has the shared policy boundaries needed to talk concretely about
implementation readiness. What it still does not have is permission to execute
those behaviors. The next implementation phases should therefore be narrow,
tool-specific approval phases, not new broad foundation phases.
