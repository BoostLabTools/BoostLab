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
17. Loudness EQ
18. Device Manager Power Savings & Wake
19. Network Adapter Power Savings & Wake
20. Write Cache Buffer Flushing
21. Power Plan
22. Cleanup
23. Restore Point

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
