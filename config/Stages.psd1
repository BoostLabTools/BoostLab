@{
    Stages = @(
        @{
            Name        = 'Check'
            Order       = 1
            Description = 'Review system and firmware information before making changes.'
            Tools       = @(
                'BIOS Information'
                'BIOS Settings'
            )
        }
        @{
            Name        = 'Refresh'
            Order       = 2
            Description = 'Prepare Windows installation and recovery workflows.'
            Tools       = @(
                'Reinstall'
                'Unattended'
                'Updates Drivers Block'
                'To BIOS'
            )
        }
        @{
            Name        = 'Setup'
            Order       = 3
            Description = 'Complete initial Windows and application setup tasks.'
            Tools       = @(
                'Memory Compression'
                'Date Language Region Time'
                'Startup Apps (Settings)'
                'Startup Apps (Task Manager)'
                'Background Apps'
                'Edge Settings'
                'Store Settings'
                'Updates Pause'
            )
        }
        @{
            Name        = 'Installers'
            Order       = 4
            Description = 'Install and configure approved client applications.'
            Tools       = @(
                'Installers'
            )
        }
        @{
            Name        = 'Graphics'
            Order       = 5
            Description = 'Prepare graphics drivers, runtimes, and display configuration.'
            Tools       = @(
                'Driver Install Debloat & Settings'
                'DirectX'
                'Visual C++'
                'Graphics Configuration Center'
            )
        }
        @{
            Name        = 'Windows'
            Order       = 6
            Description = 'Configure approved Windows appearance, behavior, and maintenance tools.'
            Tools       = @(
                'Start Menu Taskbar'
                'Start Menu Layout'
                'Context Menu'
                'Theme Black'
                'Signout LockScreen Wallpaper Black'
                'User Account Pictures Black'
                'Widgets'
                'Copilot'
                'GameMode'
                'Pointer Precision'
                'Bloatware'
                'GameBar'
                'Edge & WebView'
                'Notepad Settings'
                'Control Panel Settings'
                'Sound'
                'Loudness EQ'
                'Device Manager Power Savings & Wake'
                'Network Adapter Power Savings & Wake'
                'Write Cache Buffer Flushing'
                'Power Plan'
                'Cleanup'
                'Restore Point'
            )
        }
        @{
            Name        = 'Advanced'
            Order       = 7
            Description = 'Analyze advanced performance and security options before applying changes.'
            Tools       = @(
                'Spectre / Meltdown Assistant'
                'MMAgent Assistant'
                'Resizable BAR Assistant'
                'SMT / HT Assistant'
                'Services Optimizer'
                'Timer Resolution Assistant'
                'Defender Optimize Assistant'
            )
        }
    )
}
