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

1. Memory Compression
2. Date Language Region Time
3. Startup Apps (Settings)
4. Startup Apps (Task Manager)
5. Background Apps
6. Edge Settings
7. Store Settings
8. Updates Pause

### Stage 4 - Installers

1. Installers

### Stage 5 - Graphics

1. Driver Install Debloat & Settings
2. DirectX
3. Visual C++
4. Graphics Configuration Center

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
17. Loudness EQ
18. Device Manager Power Savings & Wake
19. Network Adapter Power Savings & Wake
20. Write Cache Buffer Flushing
21. Power Plan
22. Cleanup
23. Restore Point

### Stage 7 - Advanced

1. Spectre / Meltdown Assistant
2. MMAgent Assistant
3. Resizable BAR Assistant
4. SMT / HT Assistant
5. Services Optimizer
6. Timer Resolution Assistant
7. Defender Optimize Assistant

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

Examples:

* Spectre / Meltdown Assistant
* MMAgent Assistant
* Resizable BAR Assistant
* SMT / HT Assistant
* Services Optimizer
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

Project Planning Phase Complete.

Next Phase:

Architecture
GUI Design
Codex Implementation
Testing
Release