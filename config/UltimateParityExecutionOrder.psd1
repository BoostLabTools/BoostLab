@{
    SchemaVersion = 1
    Purpose = 'Phase 107 ordered Ultimate parity execution baseline'
    Rule = 'Future parity work follows stage order and then tool order unless Yazan explicitly overrides.'
    StageOrder = @(
        'Check'
        'Refresh'
        'Setup'
        'Installers'
        'Graphics'
        'Windows'
        'Advanced'
    )
    Stages = @(
        @{
            Name = 'Check'
            Order = 1
            Tools = @(
                @{ Order = 1; ToolId = 'bios-information'; DisplayName = 'BIOS Information' }
                @{ Order = 2; ToolId = 'bios-settings'; DisplayName = 'BIOS Settings' }
            )
        }
        @{
            Name = 'Refresh'
            Order = 2
            Tools = @(
                @{ Order = 1; ToolId = 'reinstall'; DisplayName = 'Reinstall' }
                @{ Order = 2; ToolId = 'unattended'; DisplayName = 'Unattended' }
                @{ Order = 3; ToolId = 'updates-drivers-block'; DisplayName = 'Updates Drivers Block' }
                @{ Order = 4; ToolId = 'to-bios'; DisplayName = 'To BIOS' }
            )
        }
        @{
            Name = 'Setup'
            Order = 3
            Tools = @(
                @{ Order = 1; ToolId = 'memory-compression'; DisplayName = 'Memory Compression' }
                @{ Order = 2; ToolId = 'date-language-region-time'; DisplayName = 'Date Language Region Time' }
                @{ Order = 3; ToolId = 'startup-apps-settings'; DisplayName = 'Startup Apps (Settings)' }
                @{ Order = 4; ToolId = 'startup-apps-task-manager'; DisplayName = 'Startup Apps (Task Manager)' }
                @{ Order = 5; ToolId = 'background-apps'; DisplayName = 'Background Apps' }
                @{ Order = 6; ToolId = 'edge-settings'; DisplayName = 'Edge Settings' }
                @{ Order = 7; ToolId = 'store-settings'; DisplayName = 'Store Settings' }
                @{ Order = 8; ToolId = 'updates-pause'; DisplayName = 'Updates Pause' }
                @{ Order = 9; ToolId = 'bitlocker'; DisplayName = 'BitLocker' }
            )
        }
        @{
            Name = 'Installers'
            Order = 4
            Tools = @(
                @{ Order = 1; ToolId = 'installers'; DisplayName = 'Installers' }
            )
        }
        @{
            Name = 'Graphics'
            Order = 5
            Tools = @(
                @{ Order = 1; ToolId = 'driver-clean'; DisplayName = 'Driver Clean' }
                @{ Order = 2; ToolId = 'driver-install-latest'; DisplayName = 'Driver Install Latest' }
                @{ Order = 3; ToolId = 'nvidia-settings'; DisplayName = 'Nvidia Settings' }
                @{ Order = 4; ToolId = 'hdcp'; DisplayName = 'HDCP' }
                @{ Order = 5; ToolId = 'p0-state'; DisplayName = 'P0 State' }
                @{ Order = 6; ToolId = 'msi-mode'; DisplayName = 'Msi Mode' }
                @{ Order = 7; ToolId = 'driver-install-debloat-settings'; DisplayName = 'Driver Install Debloat & Settings' }
                @{ Order = 8; ToolId = 'directx'; DisplayName = 'DirectX' }
                @{ Order = 9; ToolId = 'visual-cpp'; DisplayName = 'Visual C++' }
                @{ Order = 10; ToolId = 'graphics-configuration-center'; DisplayName = 'Graphics Configuration Center' }
            )
        }
        @{
            Name = 'Windows'
            Order = 6
            Tools = @(
                @{ Order = 1; ToolId = 'start-menu-taskbar'; DisplayName = 'Start Menu Taskbar' }
                @{ Order = 2; ToolId = 'start-menu-layout'; DisplayName = 'Start Menu Layout' }
                @{ Order = 3; ToolId = 'context-menu'; DisplayName = 'Context Menu' }
                @{ Order = 4; ToolId = 'theme-black'; DisplayName = 'Theme Black' }
                @{ Order = 5; ToolId = 'signout-lockscreen-wallpaper-black'; DisplayName = 'Signout LockScreen Wallpaper Black' }
                @{ Order = 6; ToolId = 'user-account-pictures-black'; DisplayName = 'User Account Pictures Black' }
                @{ Order = 7; ToolId = 'widgets'; DisplayName = 'Widgets' }
                @{ Order = 8; ToolId = 'copilot'; DisplayName = 'Copilot' }
                @{ Order = 9; ToolId = 'game-mode'; DisplayName = 'GameMode' }
                @{ Order = 10; ToolId = 'pointer-precision'; DisplayName = 'Pointer Precision' }
                @{ Order = 11; ToolId = 'bloatware'; DisplayName = 'Bloatware' }
                @{ Order = 12; ToolId = 'game-bar'; DisplayName = 'GameBar' }
                @{ Order = 13; ToolId = 'edge-webview'; DisplayName = 'Edge & WebView' }
                @{ Order = 14; ToolId = 'notepad-settings'; DisplayName = 'Notepad Settings' }
                @{ Order = 15; ToolId = 'control-panel-settings'; DisplayName = 'Control Panel Settings' }
                @{ Order = 16; ToolId = 'sound'; DisplayName = 'Sound' }
                @{ Order = 17; ToolId = 'device-manager-power-savings-wake'; DisplayName = 'Device Manager Power Savings & Wake' }
                @{ Order = 18; ToolId = 'network-adapter-power-savings-wake'; DisplayName = 'Network Adapter Power Savings & Wake' }
                @{ Order = 19; ToolId = 'write-cache-buffer-flushing'; DisplayName = 'Write Cache Buffer Flushing' }
                @{ Order = 20; ToolId = 'power-plan'; DisplayName = 'Power Plan' }
                @{ Order = 21; ToolId = 'cleanup'; DisplayName = 'Cleanup' }
                @{ Order = 22; ToolId = 'restore-point'; DisplayName = 'Restore Point' }
            )
        }
        @{
            Name = 'Advanced'
            Order = 7
            Tools = @(
                @{ Order = 1; ToolId = 'spectre-meltdown-assistant'; DisplayName = 'Spectre / Meltdown Assistant' }
                @{ Order = 2; ToolId = 'mmagent-assistant'; DisplayName = 'MMAgent Assistant' }
                @{ Order = 3; ToolId = 'resizable-bar-assistant'; DisplayName = 'Resizable BAR Assistant' }
                @{ Order = 4; ToolId = 'smt-ht-assistant'; DisplayName = 'SMT / HT Assistant' }
                @{ Order = 5; ToolId = 'services-optimizer'; DisplayName = 'Services Optimizer' }
                @{ Order = 6; ToolId = 'timer-resolution-assistant'; DisplayName = 'Timer Resolution Assistant' }
                @{ Order = 7; ToolId = 'defender-optimize-assistant'; DisplayName = 'Defender Optimize Assistant' }
            )
        }
    )
}
