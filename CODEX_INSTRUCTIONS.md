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

BoostLab currently supports Windows 11 only.

GPU-specific tooling is NVIDIA-only.

Windows 10 source branches are currently unsupported and must remain disabled, visual-only, or not implemented unless Yazan explicitly expands scope later.

AMD GPU-specific source branches are currently unsupported and must remain disabled, visual-only, or not implemented unless Yazan explicitly expands scope later.

Intel GPU-specific source branches are currently unsupported and must remain disabled, visual-only, or not implemented unless Yazan explicitly expands scope later.

If a source script contains both supported and unsupported branches, future phases may implement only the supported Windows 11 / NVIDIA behavior while leaving unsupported branches disabled or visual-only. That is a product-scope decision, not accidental weakening.

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
