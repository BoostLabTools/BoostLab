# Codex Instructions for BoostLab

## Project Name

BoostLab

## Goal

Build a Windows optimization workflow tool using PowerShell and a graphical interface.

BoostLab is inspired by the general idea of Chris Titus Tech's WinUtil, but must be an independent project.

Do not copy WinUtil branding, UI text, or code directly.

---

## Current Source

The folder `source-ultimate` contains the original approved source scripts.

Use these scripts only as source material.

Do not include deleted scripts.

Do not re-add removed functionality.

---

## Product Scope

Windows 11 is BoostLab's optimized target platform.

GPU-specific tooling is NVIDIA-only.

Windows 10 optimization, performance, service, and settings-improvement source branches are unsupported and must remain disabled, visual-only, or not implemented unless Yazan explicitly expands scope later.

A Windows 10 host may run an approved preparation, refresh, migration, or transition tool when that tool produces or prepares the supported Windows 11 outcome. Examples can include Windows 11 installation-media preparation tools such as Reinstall or Unattended, but each tool still requires its own approved migration phase and safety gates.

This host-usage exception does not authorize Windows 10-specific optimization behavior. If a tool combines Windows 11 preparation with Windows 10 optimization branches, only the preparation behavior may be implemented unless Yazan explicitly expands scope.

AMD GPU-specific source branches are currently unsupported and must remain disabled, visual-only, or not implemented unless Yazan explicitly expands scope later.

Intel GPU-specific source branches are currently unsupported and must remain disabled, visual-only, or not implemented unless Yazan explicitly expands scope later.

If a source script contains both supported and unsupported branches, future phases may implement only the supported Windows 11 target / NVIDIA behavior while leaving Windows 10 optimization and AMD/Intel branches disabled or visual-only. That is a product-scope decision, not accidental weakening.

If a tool is entirely outside the supported scope, keep it as a placeholder or disabled candidate with a clear reason.

Do not modify `source-ultimate` for scope reasons.

---

## Required UI Style

Build a WinUtil-inspired PowerShell GUI.

Use:

* PowerShell
* WPF
* Modular architecture
* Stage-based navigation

The UI should have:

* Left sidebar with stages
* Main content area with tools/cards
* Bottom status/log area
* Clear action buttons
* Descriptions and warnings
* Admin / internet / license status indicators

---

## Workflow Stages

The app must follow this exact order:

1. Check
2. Refresh
3. Setup
4. Installers
5. Graphics
6. Windows
7. Advanced

---

## Stage 1 - Check

1. BIOS Information
2. BIOS Settings

---

## Stage 2 - Refresh

1. Reinstall
2. Unattended
3. Updates Drivers Block
4. To BIOS

---

## Stage 3 - Setup

1. Memory Compression
2. Date Language Region Time
3. Startup Apps (Settings)
4. Startup Apps (Task Manager)
5. Background Apps
6. Edge Settings
7. Store Settings
8. Updates Pause

---

## Stage 4 - Installers

1. Installers

---

## Stage 5 - Graphics

1. Driver Install Debloat & Settings
2. DirectX
3. Visual C++
4. Graphics Configuration Center

---

## Stage 6 - Windows

1. Start Menu Taskbar
2. Start Menu Layout
3. Context Menu
4. Theme Black
5. Signout LockScreen Wallpaper Black
6. User Account Pictures Black
7. Widgets
8. Copilot
9. GameMode
10. Pointer Precision
11. Bloatware
12. GameBar
13. Edge & WebView
14. Notepad Settings
15. Control Panel Settings
16. Sound
17. Device Manager Power Savings & Wake
18. Network Adapter Power Savings & Wake
19. Write Cache Buffer Flushing
20. Power Plan
21. Cleanup
22. Restore Point

---

## Stage 7 - Advanced

1. Spectre / Meltdown Assistant
2. MMAgent Assistant
3. Resizable BAR Assistant
4. SMT / HT Assistant
5. Services Optimizer
6. Timer Resolution Assistant
7. Defender Optimize Assistant

---

## Deleted Features

Do not implement or reintroduce:

* Windows Activation Helper
* Firewall Disable / Enable
* DEP Disable / Enable
* File Download Security Warning
* MPO
* FSO
* FSE
* Hardware Flip
* AMD ULPS
* WHQL Secure Boot Bypass
* Keyboard Shortcuts
* Search Shell Mobsync
* NVME Faster Driver
* Core 1 Thread 1
* DDU
* UAC Disable / Enable
* Scaling
* Start Menu Shortcuts
* Loudness EQ

### Phase 25 Permanent Product Removal

* Loudness EQ was permanently removed from the BoostLab product by Yazan on June 10, 2026.
* This is a product deletion, not a hidden feature, deferred migration, or future candidate.
* Loudness EQ must never be recreated directly, indirectly, under another name, or as part of another tool.
* Phase 25 intentionally deleted `source-ultimate/6 Windows/17 Loudness EQ.ps1` under a one-file exception to the normal legacy-source immutability rule.
* The deleted source file's final SHA-256 was `2F11A145B3E035372AB023614662524159BDDFA122A3778D6FEE9824782416AE`.
* The authorized deletion scope was limited to the catalog entry, placeholder module, source file, documentation references, and validation baselines required to remove Loudness EQ completely.

---

## Architecture Requirements

Create a clean structure:

```text
BoostLab/
├─ bootstrap.ps1
├─ Start-BoostLab.ps1
├─ BOOSTLAB_BLUEPRINT.md
├─ CODEX_INSTRUCTIONS.md
├─ config/
├─ core/
├─ license/
├─ ui/
├─ modules/
└─ source-ultimate/
```

---

## bootstrap.ps1

The root `bootstrap.ps1` should become the project launcher.

It should:

* Check administrator rights
* Check internet connection
* Check or prepare required runtime
* Download or update BoostLab if needed
* Later support license verification
* Launch the GUI

Do not permanently set system-wide ExecutionPolicy to Unrestricted.

Use temporary process-level execution bypass only when needed.

---

## License System

BoostLab will later use:

* GitHub Public Repository
* Cloudflare Workers License API

For now, prepare the architecture for licensing but do not require a real API yet.

Create placeholder license functions if needed.

---

## Advanced Assistant Rules

Advanced tools must not be simple on/off scripts.

They must:

* Analyze the system first
* Explain benefits
* Explain risks
* Show recommendation
* Ask for confirmation before applying changes

This applies to:

* Spectre / Meltdown Assistant
* MMAgent Assistant
* Resizable BAR Assistant
* SMT / HT Assistant
* Services Optimizer
* Timer Resolution Assistant
* Defender Optimize Assistant

---

## Script Migration Policy

### Normal Approved Action Tools

When migrating a normal approved action tool from Ultimate:

* Preserve the original Ultimate behavior as closely as possible.
* Do not change registry keys, service names, command logic, paths, revert/default logic, or execution order unless explicitly instructed.
* Refactor only the interface layer required to integrate the behavior into BoostLab.
* Convert console menus, including `Read-Host` option prompts, into equivalent GUI actions.
* Remove or replace console-only behavior such as `Clear-Host`, `Pause`, `Exit`, and `Write-Host` with GUI logging and appropriate user prompts.
* Keep the original Apply / Default / On / Off behavior equivalent.

### Redesigned or Assistant Tools

For redesigned or assistant tools:

* Use the original Ultimate script as source reference only.
* Add analysis, recommendations, warnings, confirmations, and relevant system checks.
* Do not blindly execute high-risk changes.

This policy applies to examples including:

* BIOS Information
* Graphics Configuration Center
* Spectre / Meltdown Assistant
* MMAgent Assistant
* Resizable BAR Assistant
* SMT / HT Assistant
* Services Optimizer
* Timer Resolution Assistant
* Defender Optimize Assistant

### Deleted Scripts

* Deleted scripts must never be reintroduced.
* Deleted functionality must not be recreated indirectly under a new name.

### Legacy Source

* The `source-ultimate` directory must remain untouched as the legacy reference source.
* All migrated production logic must live in `modules/`.
* The only approved exception is the Phase 25 deletion of `source-ultimate/6 Windows/17 Loudness EQ.ps1`; this exception does not authorize any other source modification.

---

## Preserve Ultimate Execution Strength

### Approved Normal Action Tools

* Preserve the original Ultimate behavior and enforcement strength as closely as possible.
* Do not weaken registry, service, policy, process, driver, power, security, or cleanup commands.
* Do not replace strong commands with softer alternatives unless explicitly instructed.
* If the original Ultimate script requires Administrator rights, BoostLab must preserve that requirement at the application or runtime level.
* BoostLab may replace console interaction with GUI controls, but must not weaken the actual operational effect.
* Convert `Read-Host` menus into equivalent GUI buttons.
* Replace `Pause`, `Clear-Host`, `Write-Host`, and `Exit` with GUI status, logging, result panels, or prompts as appropriate.
* Preserve Apply / Default / On / Off / Restore behavior equivalence.
* Preserve execution order unless explicitly instructed.

### Approved High-Risk Tools

* Preserve the intended original behavior while adding clear GUI warnings, confirmations, logging, and result reporting.
* Do not silently execute destructive or rebooting actions.
* Do not remove required confirmations for reboot, Safe Mode, TrustedInstaller, driver, Defender, service, or security-sensitive flows.
* Do not reduce the tool's intended effect merely to make it appear safer.

### Redesigned Assistant Tools

* Use the Ultimate script as a source reference when applicable.
* Add analysis, recommendations, and warnings.
* If an Apply or Open action is intended to preserve original behavior, it must preserve the original behavior's effective result.
* Document every intentional deviation from Ultimate in code comments and project documentation.

### Deleted Tools

* Never reintroduce deleted tools directly or indirectly.

---

## BoostLab Governance Decisions

* Ultimate is the source of approved operational intent, not an untouchable source of defects.
* Approved normal tools should preserve Ultimate behavior and execution strength.
* Any intentional deviation from Ultimate must be documented and approved by Yazan before it becomes production behavior.
* Deleted tools must never be reintroduced directly, indirectly, under a different name, or as part of another tool.
* `Default` means the tool's approved default behavior. It does not automatically mean the current Windows default unless that is the approved behavior.
* `Restore` means returning to a previous system state captured by BoostLab. A tool must not expose working Restore behavior unless BoostLab has captured the state required for that restoration.
* BoostLab is currently a technician-focused tool, not a fully automated consumer optimizer.
* BoostLab is expected to run elevated as Administrator. Elevation does not replace high-risk confirmation, logging, compatibility checks, or result reporting.
* Strong execution is allowed for approved tools, but silent destructive execution is not allowed.
* Capability metadata in `config/Stages.psd1` is conservative governance metadata. A capability set to `true` identifies behavior that a completed migration may perform and must be considered by runtime safety checks.
* Capability metadata does not authorize implementation. A placeholder remains a placeholder until its migration is separately approved.

---

## Privilege Preservation Policy

* BoostLab preserves Ultimate's Administrator requirement at the application and runtime level.
* Do not duplicate Ultimate's per-script self-elevation block inside every tool module.
* `bootstrap.ps1` and `Start-BoostLab.ps1` must ensure the application is elevated before privileged runtime execution.
* If BoostLab is not elevated and a tool declares `RequiresAdmin = true`, execution must be blocked or the application must be relaunched with a clear elevation message.
* Tool metadata must declare `RequiresAdmin` accurately. Open-only tools do not require Administrator unless their approved Ultimate source actually requires it.
* Strong approved execution must not be weakened merely to avoid elevation.
* Ultimate console elevation code is replaced by BoostLab bootstrap and runtime elevation.
* Tool modules must not silently self-elevate unless Yazan explicitly approves that exception.
* Future migrations must preserve the privilege requirement demonstrated by the approved source script and record it in the migration record.
* BoostLab runs globally as Administrator. It must not run the entire application as TrustedInstaller.
* TrustedInstaller may be used only by a specific approved tool whose Ultimate source requires it and whose metadata declares `UsesTrustedInstaller = true`.
* TrustedInstaller actions require explicit confirmation, a visible Action Plan warning, centralized runtime dispatch, and clear logging.
* Generic modules must never invoke TrustedInstaller silently or use it for tools whose approved source does not require it.
* `core/TrustedInstaller.psm1` is the only approved future runtime boundary for TrustedInstaller execution. Its Phase 14.5 implementation is a non-executing placeholder.

---

## Download Provenance and Installer Execution Policy

* Downloads and installer execution are denied by default.
* A future tool must reference an artifact listed in `config/ArtifactProvenance.psd1`; editable URLs or arbitrary paths from tool metadata must never be executed.
* Every approved artifact record must declare its id, display name, HTTPS source URL, exact SHA-256, expected file name, size or size bounds when required, expected publisher for executable content, future consumer tool ids, license or redistributability note, execution permission, Administrator requirement, reboot possibility, verification requirements, and approval status.
* Unknown artifacts, missing hashes, malformed hashes, hash mismatches, revoked or unapproved artifacts, and artifacts absent from the manifest are blocked.
* Executable or installer artifacts allowed to run must declare and pass an Authenticode signer/publisher requirement. Missing signer policy is allowed only when the artifact is explicitly non-executable.
* Downloads must never be executed directly from a URL. A future downloader must save to a controlled local path and complete provenance verification before any use.
* Installer execution requires a matching verified artifact, a matching tool id and action id, an exact documented command line, source-approved switches, explicit Action Plan confirmation, process start/finish logging, timeout handling, and exit-code capture.
* Silent execution is prohibited unless its switches are preserved from approved source behavior and documented in the migration record.
* Unverified temporary paths, unsigned executable content, hash-mismatched content, and unrelated cleanup are prohibited.
* Adding an artifact to the manifest does not implement or authorize a tool. A dedicated approved phase must add the artifact record, manual source/hash/signature evidence, tests, migration record updates, and tool wiring.
* Phase 35 approves no real third-party artifacts. `core/DownloadProvenance.psm1` and `core/InstallerExecution.psm1` are inert policy boundaries; the installer entry point does not start a process.

---

## File and Registry State Capture Policy

* File and registry capture and rollback are denied by default.
* A future tool must use an exact tool-specific scope listed in `config/RollbackPolicy.psd1`. Phase 36 approves no production scopes.
* Capture records must identify the operation, tool, action, schema/version, exact source path, item type, original existence, original metadata, file hashes and backup location where applicable, intended mutation, rollback eligibility, verification requirement, and risk.
* File capture must use an absolute literal target inside an approved bounded root. Wildcards, drive roots, Windows, Program Files, the user-profile root, System32, reparse points, and targets outside the approved scope are blocked.
* Directory capture requires an explicit scope with file-count and byte limits. It must not roam into unrelated user data.
* Registry capture must use an exact HKCU or HKLM path approved for the tool. Registry values require an exact approved value name. Broad hives and protected `HKLM\SYSTEM` paths are blocked unless a future dedicated scope explicitly approves that source behavior.
* Restore is permitted only from an integrity-verified BoostLab rollback record under the BoostLab state directory.
* File restore requires a verified backup whose hash matches both the captured original hash and recorded backup hash.
* Rollback requires recorded post-mutation state. If the current target no longer matches that state, rollback must refuse rather than overwrite unrelated later changes.
* Missing, corrupt, mismatched, ineligible, out-of-scope, or wrong-tool/action records are blocked.
* `Default` remains the approved default behavior of a tool. `Restore` means returning to state captured before that operation; the terms are not interchangeable.
* Phase 36 does not wire capture or rollback into any tool. Future tool phases must add exact scopes, migration-record details, Action Plan coverage, and tool-specific tests before use.

---

## Service State Capture and Rollback Policy

* Service capture and rollback are denied by default.
* A future service-changing tool must use an exact tool-specific scope in `config/ServiceRollbackPolicy.psd1`. Phase 37 approves no production service scopes.
* Scopes must list exact service names and exact allowed mutation types. Wildcards, unknown services, broad enumeration, and unapproved names are blocked.
* Protected/core Windows services remain denied unless a future migration explicitly scopes the exact service and receives Yazan approval with recovery requirements.
* Capture must occur before mutation and record original existence, status, startup type, delayed auto-start, binary path, account, dependencies, description, failure actions where available, intended mutation, rollback eligibility, verification requirements, and risk.
* The complete post-mutation service state must be recorded before rollback can be attempted.
* Rollback requires an integrity-verified, non-stale BoostLab service record whose tool, action, scope, service identity, and current state all match.
* Service identity drift, missing or corrupt records, stale records, current-state drift, out-of-scope services, and ineligible mutations are blocked.
* Phase 37 may restore only explicitly approved startup type, delayed auto-start, and running status through a narrow runtime boundary.
* Service creation, deletion, recreation, arbitrary binary/account/dependency changes, and protected-service recovery remain disabled until separately approved infrastructure exists.
* Service rollback failures must return structured results and must never be ignored silently.
* `Default` remains the approved tool default. Service rollback means restoring a captured prior service state and is not an optimizer preset.
* Phase 37 does not wire service helpers into any module or enable any deferred tool.

---

## Destructive Cleanup Policy

* Destructive cleanup, quarantine, and restore are denied by default.
* A future cleanup-capable tool must use an exact tool-specific scope in `config/CleanupPolicy.psd1`. Phase 38 approves no production cleanup scopes.
* Scopes must declare one bounded root, exact target paths, target types, cleanup types, recursion permission, file-count/byte limits, state-capture requirements, and delete/quarantine permission.
* Drive roots, Windows, System32, Program Files, ProgramData root, user-profile root, Desktop, Documents, Downloads, AppData roots, Temp root, wildcards, traversal, unresolved variables, out-of-scope paths, and reparse points are denied.
* Recursive cleanup requires an exact directory target plus positive file-count and byte limits.
* Unrelated user documents must never be deleted. User-library targets require a separately approved exact scope and must not cover a whole library root.
* Every destructive operation requires an Action Plan and explicit user confirmation.
* Rollback-eligible cleanup requires matching pre-mutation state capture from the file rollback foundation.
* Permanent deletion and quarantine are distinct. Permanent deletion requires explicit scope permission. Quarantine requires an operation-specific BoostLab path, matching hashes, metadata, reason, identity, and restore eligibility.
* Quarantine restore is allowed only from an integrity-verified, non-stale BoostLab record when the original path is absent and the quarantined content still matches its recorded hash.
* Cleanup execution and restore failures must return structured results and must never be ignored silently.
* Phase 38 contains no built-in destructive file command, wires no cleanup helper into a module, and enables no deferred tool.

---

## AppX Package Inventory and Restore Policy

* AppX package inventory, mutation, and restore are denied by default.
* A future AppX-capable tool must use an exact tool/action/package scope in `config/AppxPackagePolicy.psd1`. Phase 39 approves no production package scopes.
* Inventory must be captured before removal and must record exact package family/full identity, publisher, version, architecture, install location, status, provisioned identity, user scope, original installed/provisioned state, registration manifest, dependencies, intended mutation, rollback eligibility, verification requirement, and risk.
* Unknown, wildcard, partial, broad, out-of-scope, framework, dependency, and system-critical package targets are blocked unless a future exact scope explicitly approves the specific source behavior.
* Edge, WebView, Store, Shell Experience Host, Start Menu Experience Host, Desktop App Installer, VCLibs, UI Xaml, .NET Native, Windows App Runtime, frameworks, and dependencies are protected by default.
* Current-user removal, all-user removal, and provisioned-image removal are different capabilities. All-user and provisioned removal require separate explicit scope permission.
* Every AppX mutation and restore requires a matching Action Plan, explicit confirmation, exact package identity, structured verification, and persisted post-operation state.
* Restore is allowed only from an integrity-verified, non-stale BoostLab inventory record after a recorded mutation. Missing, corrupt, stale, mismatched, ineligible, or out-of-scope records are blocked.
* Restore requires the exact captured install location, registration manifest, or provisioned identity needed by the approved restore path. Missing package content blocks restore; this foundation must not download or install replacement content.
* AppX inventory does not authorize services, downloads, installers, cleanup, file/registry changes, TrustedInstaller, Safe Mode, or broad package re-registration.
* Phase 39 contains no built-in AppX or DISM command, is not wired into any tool module, and enables no deferred tool.

---

## Reboot and Recovery Workflow Policy

* Reboot, resume scheduling, cancellation, and post-reboot continuation are denied by default.
* A future reboot-capable tool must use an exact tool/action scope in `config/RebootRecoveryPolicy.psd1`. Phase 40 approves no production workflow scopes.
* Workflow records must include operation/tool/action identity, schema/version, requested reboot type, reason, risk, confirmation level, passed pre-reboot checkpoints, verified state-capture references, bounded resume steps, post-reboot verification, expiration, cancellation rules, recovery instructions, and warning text.
* Immediate reboot, manual reboot required, and post-reboot continuation are distinct workflow types. Firmware and Safe Mode restart require separate explicit policy permission.
* Every reboot-capable plan requires a matching Action Plan and explicit confirmation. Missing checkpoints, state references, recovery instructions, or verification requirements block planning.
* Resume is allowed only from an integrity-verified, non-stale, non-expired, matching BoostLab workflow record in `PendingResume` state.
* Resume steps must use exact policy-approved handler ids and trusted artifact paths. Workflow records must never contain arbitrary command lines, executable names, arguments, scripts, URLs, or untrusted paths.
* Current machine state must match the recorded expected conditions before resume. Failed validation or verification must return a structured failure and must not continue silently.
* Eligible cancellation must persist the cancellation reason and timestamp, preserve recovery instructions, and permanently block later resume.
* Reboot workflow state does not authorize file/registry, service, AppX, cleanup, download, installer, driver, TrustedInstaller, Safe Mode, BCD, or recovery-environment behavior governed elsewhere.
* Phase 40 does not call reboot commands, create RunOnce entries or Scheduled Tasks, edit BCD, enter Safe Mode, modify recovery settings, wire helpers into modules, or enable deferred tools.

---

## Safety Rules

* Do not run dangerous changes automatically
* Prefer restore points before high-risk changes
* Show warnings for medium/high risk actions
* Keep restore/default functionality when available
* Log all executed actions
* Never silently disable core Windows security without warning

---

## UI Behavior

Each tool should show:

* Name
* Description
* Current status if detectable
* Risk level
* Action buttons
* Restore/default button when possible

Suggested action types:

* Apply
* Default
* Open
* Analyze
* Restore

---

## Final Goal

Convert the approved scripts and workflow into a polished BoostLab GUI application.

The first working version should focus on:

* Launching the GUI
* Showing all 7 stages
* Showing all approved tools
* Running simple tools safely
* Keeping advanced tools as assistant placeholders if full logic is not ready yet
