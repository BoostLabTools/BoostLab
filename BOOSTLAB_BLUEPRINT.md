# BoostLab Blueprint

## Project Overview

BoostLab is a Windows optimization and service workflow platform inspired by the workflow simplicity of Chris Titus Tech's WinUtil, but designed specifically for professional client servicing.

BoostLab is not intended to be a script collection.

BoostLab should guide the technician through a structured optimization workflow using stages.

The application must be built using PowerShell and a graphical user interface.

---

## Project Goals

* Professional Windows optimization workflow
* Clean GUI
* Easy for technicians
* Safe by default
* Modular architecture
* License support
* GitHub hosted
* Future cloud integration

## Product Scope

Windows 11 is BoostLab's preferred supported product target.

GPU-specific tooling targets NVIDIA only.

Product scope is branch-level scope, not a blanket host-OS or hardware-vendor block.

Approved shared Windows behavior from an Ultimate source may be preserved when it applies the same way to Windows 10 and Windows 11 and does not expose a Windows 10-only branch or option.

Windows 10 optimization branches, including Windows 10-only optimization, performance, service, and settings-improvement branches, are outside the supported scope unless Yazan explicitly changes scope later.

BoostLab may run on a Windows 10 host when an approved preparation, refresh, migration, or transition tool produces a Windows 11-targeted outcome. This exception permits Windows 11 preparation from Windows 10; it does not permit Windows 10-only optimization branches.

AMD/Intel GPU-specific branches remain outside the supported scope unless Yazan explicitly changes scope later.

Tool-specific exception: Phase 122 approves all source-defined NVIDIA, AMD, and
INTEL branches for `Driver Install Debloat & Settings` only. This exception is
for exact parity with `source-ultimate/5 Graphics/1 Driver Install Debloat &
Settings.ps1`; it does not broaden AMD/Intel support anywhere else.

GPU-neutral behavior and NVIDIA-specific behavior may be preserved when otherwise approved. Unsupported Windows 10-only or AMD/Intel-specific branches should stay disabled, visual-only, or not implemented rather than being ported silently.

---

## Workflow Structure

### Stage 1 - Check

1. BIOS Information
2. BIOS Settings

### Stage 2 - Refresh

1. Reinstall
2. Unattended
3. Updates Drivers Block
4. To BIOS

### Stage 3 - Setup

1. BitLocker
2. Memory Compression
3. Date Language Region Time
4. Startup Apps (Settings)
5. Startup Apps (Task Manager)
6. Background Apps
7. Edge Settings
8. Store Settings
9. Updates Pause

### Stage 4 - Installers

1. Installers

### Stage 5 - Graphics

1. Driver Clean
2. Driver Install Debloat & Settings
3. Install NVIDIA App
4. DirectX
5. Visual C++
6. Graphics Configuration Center

### Stage 6 - Windows

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

### Stage 7 - Advanced

1. Timer Resolution Assistant
2. Defender Optimize Assistant

---

## Deleted Components

The following components are intentionally excluded from BoostLab:

* Windows Activation Helper
* Firewall
* DEP
* File Download Security Warning
* MPO
* FSO
* FSE
* Hardware Flip
* ULPS
* WHQL Secure Boot Bypass
* Keyboard Shortcuts
* Search Shell Mobsync
* NVME Faster Driver
* Core 1 Thread 1
* DDU
* UAC
* Scaling
* Start Menu Shortcuts
* Loudness EQ
* Restore Point
* Spectre / Meltdown Assistant
* MMAgent Assistant
* Services Optimizer
* Driver Install Latest
* Nvidia Settings
* HDCP
* P0 State
* Msi Mode

### Phase 25 Removal Record

Loudness EQ was permanently removed from the BoostLab product by Yazan on June 10, 2026. It is not hidden, deferred, or eligible for future migration, and it must not be recreated under another name or inside another tool.

Phase 25 intentionally deleted only `source-ultimate/6 Windows/17 Loudness EQ.ps1` from the legacy source tree. The file's final SHA-256 was `2F11A145B3E035372AB023614662524159BDDFA122A3778D6FEE9824782416AE`. This one-file exception does not weaken the rule that all other `source-ultimate` files remain immutable reference material.

### Phase 70 Driver Clean Intake Exception

Driver Clean is a Yazan-approved intake exception despite DDU usage. Phase 120 supersedes the Phase 92 manual-handoff-only implementation and preserves the exact source-equivalent Driver Clean Auto and Manual workflow behind BoostLab confirmation.

This approval is Driver Clean-specific only. It does not approve standalone DDU, DDU use by other tools, broad DDU artifact approval, or production scopes outside Driver Clean. Standalone DDU remains excluded, and Loudness EQ and NVME Faster Driver remain permanently deleted.

---

## Assistant Philosophy

Advanced assistants must not simply enable or disable settings.

Assistants should:

* Analyze system configuration
* Detect hardware capabilities
* Explain benefits
* Explain risks
* Recommend actions
* Allow user confirmation before applying changes

Current examples:

* Timer Resolution Assistant
* Defender Optimize Assistant

---

## Bootstrap

Project entry point:

bootstrap.ps1

Responsibilities:

* Check Administrator
* Check Internet
* Check License
* Download or Update BoostLab
* Verify Files
* Launch GUI

---

## Technical Direction

Preferred stack:

* PowerShell
* WPF GUI
* GitHub Repository
* Modular Architecture

Inspired by:

Chris Titus Tech WinUtil

However:

* Do not clone WinUtil
* Do not copy branding
* Do not copy UI
* Do not copy code directly

BoostLab must be its own independent project.

---

## Current Status

Project implementation is in progress.

Next Phase:

Migration governance
Runtime hardening
Phase-by-phase implementation
Testing
Release readiness
