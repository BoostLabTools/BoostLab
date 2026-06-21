@{
    Stages = @(
        @{
            Name        = 'Check'
            Order       = 1
            Description = 'Review system and firmware information before making changes.'
            Tools       = @(
                @{
                    Id          = 'bios-information'
                    Title       = 'BIOS Information'
                    Stage       = 'Check'
                    Order       = 1
                    Type        = 'assistant'
                    RiskLevel   = 'low'
                    Description = 'Review detected BIOS, firmware, and motherboard information.'
                    Actions     = @('Analyze', 'Open')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $false }
                }
                @{
                    Id          = 'bios-settings'
                    Title       = 'BIOS Settings'
                    Stage       = 'Check'
                    Order       = 2
                    Type        = 'assistant'
                    RiskLevel   = 'high'
                    Description = 'Review BIOS setting guidance and optionally restart into BIOS/UEFI firmware settings.'
                    Actions     = @('Analyze', 'Open')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $true; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
            )
        }
        @{
            Name        = 'Refresh'
            Order       = 2
            Description = 'Prepare Windows installation and recovery workflows.'
            Tools       = @(
                @{
                    Id          = 'reinstall'
                    Title       = 'Reinstall'
                    Stage       = 'Refresh'
                    Order       = 1
                    Type        = 'action'
                    RiskLevel   = 'high'
                    Description = 'Analyze or run the controlled source-defined Windows 11 Media Creation Tool reinstall handoff after explicit confirmation.'
                    Actions     = @('Analyze', 'Open', 'Apply', 'Default', 'Restore')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $true; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $true; CanDownload = $true; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'unattended'
                    Title       = 'Unattended'
                    Stage       = 'Refresh'
                    Order       = 2
                    Type        = 'action'
                    RiskLevel   = 'high'
                    Description = 'Create the approved Windows 11 autounattend.xml on selected removable installation media.'
                    Actions     = @('Analyze', 'Apply')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $true; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $true; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'updates-drivers-block'
                    Title       = 'Updates Drivers Block'
                    Stage       = 'Refresh'
                    Order       = 3
                    Type        = 'action'
                    RiskLevel   = 'high'
                    Description = 'Create the Yazan-selected Driver Updates Block setupcomplete.cmd on selected bootable USB media only; Default/Unblock is unavailable.'
                    Actions     = @('Analyze', 'Apply', 'Default', 'Restore')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $true; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'to-bios'
                    Title       = 'To BIOS'
                    Stage       = 'Refresh'
                    Order       = 4
                    Type        = 'assistant'
                    RiskLevel   = 'high'
                    Description = 'Review restart guidance before opening Windows firmware startup options.'
                    Actions     = @('Analyze', 'Open')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $true; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
            )
        }
        @{
            Name        = 'Setup'
            Order       = 3
            Description = 'Complete initial Windows and application setup tasks.'
            Tools       = @(
                @{
                    Id          = 'bitlocker'
                    Title       = 'BitLocker'
                    Stage       = 'Setup'
                    Order       = 1
                    Type        = 'assistant'
                    RiskLevel   = 'high'
                    Description = 'Analyze BitLocker state, run source-equivalent Off behavior, or open source-equivalent On/status behavior with explicit confirmation.'
                    Actions     = @('Analyze', 'Apply', 'Default', 'Restore', 'Open')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $true; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'memory-compression'
                    Title       = 'Memory Compression'
                    Stage       = 'Setup'
                    Order       = 2
                    Type        = 'action'
                    RiskLevel   = 'low'
                    Description = 'Disable Windows memory compression using the approved recommendation or restore the default enabled state.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'date-language-region-time'
                    Title       = 'Date Language Region Time'
                    Stage       = 'Setup'
                    Order       = 3
                    Type        = 'assistant'
                    RiskLevel   = 'low'
                    Description = 'Open the Windows Date & time settings page.'
                    Actions     = @('Open')
                    Capabilities = @{ RequiresAdmin = $false; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $false }
                }
                @{
                    Id          = 'startup-apps-settings'
                    Title       = 'Startup Apps (Settings)'
                    Stage       = 'Setup'
                    Order       = 4
                    Type        = 'assistant'
                    RiskLevel   = 'low'
                    Description = 'Open the Windows Settings page for startup application management.'
                    Actions     = @('Open')
                    Capabilities = @{ RequiresAdmin = $false; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $false }
                }
                @{
                    Id          = 'startup-apps-task-manager'
                    Title       = 'Startup Apps (Task Manager)'
                    Stage       = 'Setup'
                    Order       = 5
                    Type        = 'assistant'
                    RiskLevel   = 'low'
                    Description = 'Open Task Manager for detailed startup application review.'
                    Actions     = @('Open')
                    Capabilities = @{ RequiresAdmin = $false; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $false }
                }
                @{
                    Id          = 'background-apps'
                    Title       = 'Background Apps'
                    Stage       = 'Setup'
                    Order       = 6
                    Type        = 'action'
                    RiskLevel   = 'low'
                    Description = 'Disable background apps by machine policy or restore the approved default behavior.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'edge-settings'
                    Title       = 'Edge Settings'
                    Stage       = 'Setup'
                    Order       = 7
                    Type        = 'action'
                    RiskLevel   = 'high'
                    Description = 'Apply the full source-defined Microsoft Edge optimization workflow or run the source-defined Default repair/reset workflow with explicit confirmation.'
                    Actions     = @('Analyze', 'Apply', 'Default', 'Restore')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $true; CanInstallSoftware = $true; CanDownload = $true; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'store-settings'
                    Title       = 'Store Settings'
                    Stage       = 'Setup'
                    Order       = 8
                    Type        = 'action'
                    RiskLevel   = 'low'
                    Description = 'Optimize Microsoft Store update and preference settings or restore the approved default behavior.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'updates-pause'
                    Title       = 'Updates Pause'
                    Stage       = 'Setup'
                    Order       = 9
                    Type        = 'action'
                    RiskLevel   = 'low'
                    Description = 'Pause Windows Update for 365 days or restore the default unpaused registry state.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
            )
        }
        @{
            Name        = 'Installers'
            Order       = 4
            Description = 'Install and configure approved client applications.'
            Tools       = @(
                @{
                    Id          = 'installers'
                    Title       = 'Installers'
                    Stage       = 'Installers'
                    Order       = 1
                    Type        = 'assistant'
                    RiskLevel   = 'high'
                    Description = 'Selected-app installer queue. Installs only Yazan-retained Ultimate app choices in source order after confirmation; removed app choices are hidden and unavailable.'
                    Actions     = @('Analyze', 'Open', 'Apply', 'Default', 'Restore')
                    SelectionMode = 'MultiSelect'
                    SelectionRequiredActions = @('Apply')
                    SelectionItems = @(
                        @{ Id = 'discord'; Title = 'Discord'; SourceMenuNumber = 2 }
                        @{ Id = 'roblox'; Title = 'Roblox'; SourceMenuNumber = 3 }
                        @{ Id = 'seven-zip'; Title = '7-Zip'; SourceMenuNumber = 4 }
                        @{ Id = 'battle-net'; Title = 'Battle.net'; SourceMenuNumber = 5 }
                        @{ Id = 'brave'; Title = 'Brave'; SourceMenuNumber = 6 }
                        @{ Id = 'electronic-arts'; Title = 'Electronic Arts'; SourceMenuNumber = 7 }
                        @{ Id = 'epic-games'; Title = 'Epic Games'; SourceMenuNumber = 8 }
                        @{ Id = 'escape-from-tarkov'; Title = 'Escape From Tarkov'; SourceMenuNumber = 9 }
                        @{ Id = 'firefox'; Title = 'Firefox'; SourceMenuNumber = 10 }
                        @{ Id = 'google-chrome'; Title = 'Google Chrome'; SourceMenuNumber = 13 }
                        @{ Id = 'league-of-legends'; Title = 'League Of Legends'; SourceMenuNumber = 14 }
                        @{ Id = 'obs-studio'; Title = 'OBS Studio'; SourceMenuNumber = 17 }
                        @{ Id = 'rockstar-games'; Title = 'Rockstar Games'; SourceMenuNumber = 20 }
                        @{ Id = 'spotify'; Title = 'Spotify'; SourceMenuNumber = 21 }
                        @{ Id = 'steam'; Title = 'Steam'; SourceMenuNumber = 22 }
                        @{ Id = 'ubisoft-connect'; Title = 'Ubisoft Connect'; SourceMenuNumber = 23 }
                        @{ Id = 'valorant'; Title = 'Valorant'; SourceMenuNumber = 24 }
                    )
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $true; CanInstallSoftware = $true; CanDownload = $true; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
            )
        }
        @{
            Name        = 'Graphics'
            Order       = 5
            Description = 'Prepare graphics drivers, runtimes, and display configuration.'
            Tools       = @(
                @{
                    Id          = 'driver-clean'
                    Title       = 'Driver Clean'
                    Stage       = 'Graphics'
                    Order       = 1
                    Type        = 'assistant'
                    RiskLevel   = 'high'
                    Description = 'Source-equivalent Driver Clean workflow. Analyze is read-only; Apply runs the Ultimate DDU Auto branch after confirmation; Open runs the Ultimate DDU Manual branch after confirmation.'
                    Actions     = @('Analyze', 'Open', 'Apply')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $true; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $true; CanDownload = $true; CanModifyDrivers = $true; CanModifySecurity = $false; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $true; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'driver-install-debloat-settings'
                    Title       = 'Driver Install Debloat & Settings'
                    Stage       = 'Graphics'
                    Order       = 2
                    Type        = 'assistant'
                    RiskLevel   = 'high'
                    Description = 'Run the source-equivalent NVIDIA, AMD, or INTEL driver install/debloat workflow for one selected branch after explicit confirmation.'
                    Actions     = @('Analyze', 'Open', 'Apply', 'Default', 'Restore')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $true; CanModifyRegistry = $true; CanModifyServices = $true; CanInstallSoftware = $true; CanDownload = $true; CanModifyDrivers = $true; CanModifySecurity = $false; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                    SelectionMode = 'SingleSelect'
                    SelectionRequiredActions = @('Open', 'Apply')
                    SelectionLabel = 'Select exactly one GPU branch for Open or Apply'
                    SelectionItems = @(
                        @{ Id = 'NVIDIA'; Title = 'NVIDIA'; SourceMenuNumber = 1 }
                        @{ Id = 'AMD'; Title = 'AMD'; SourceMenuNumber = 2 }
                        @{ Id = 'INTEL'; Title = 'INTEL'; SourceMenuNumber = 3 }
                    )
                }
                @{
                    Id          = 'driver-install-latest'
                    Title       = 'Driver Install Latest'
                    Stage       = 'Graphics'
                    Order       = 3
                    Type        = 'assistant'
                    RiskLevel   = 'high'
                    Description = 'Run the source-equivalent NVIDIA, AMD, or INTEL latest driver workflow for one selected branch after explicit confirmation.'
                    Actions     = @('Analyze', 'Open', 'Apply', 'Default', 'Restore')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $true; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $true; CanDownload = $true; CanModifyDrivers = $true; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                    SelectionMode = 'SingleSelect'
                    SelectionRequiredActions = @('Open', 'Apply')
                    SelectionLabel = 'Select exactly one GPU branch'
                    SelectionItems = @(
                        @{ Id = 'NVIDIA'; Title = 'NVIDIA'; SourceMenuNumber = 1 }
                        @{ Id = 'AMD'; Title = 'AMD'; SourceMenuNumber = 2 }
                        @{ Id = 'INTEL'; Title = 'INTEL'; SourceMenuNumber = 3 }
                    )
                }
                @{
                    Id          = 'nvidia-settings'
                    Title       = 'Nvidia Settings'
                    Stage       = 'Graphics'
                    Order       = 4
                    Type        = 'assistant'
                    RiskLevel   = 'high'
                    Description = 'Source-equivalent controlled runtime. Path B step 2 of 5. Run the Ultimate Nvidia Settings On (Recommended) or Default branch after explicit confirmation.'
                    Actions     = @('Analyze', 'Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $true; CanDownload = $true; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'hdcp'
                    Title       = 'HDCP'
                    Stage       = 'Graphics'
                    Order       = 5
                    Type        = 'action'
                    RiskLevel   = 'high'
                    Description = 'Path B step 3 of 5. Set the source-defined NVIDIA HDCP registry value on every non-Configuration display-class subkey after explicit confirmation.'
                    Actions     = @('Analyze', 'Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'p0-state'
                    Title       = 'P0 State'
                    Stage       = 'Graphics'
                    Order       = 6
                    Type        = 'action'
                    RiskLevel   = 'high'
                    Description = 'Path B step 4 of 5. Set the source-defined NVIDIA P0 State registry value on every non-Configuration display-class subkey after explicit confirmation.'
                    Actions     = @('Analyze', 'Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'msi-mode'
                    Title       = 'Msi Mode'
                    Stage       = 'Graphics'
                    Order       = 7
                    Type        = 'action'
                    RiskLevel   = 'high'
                    Description = 'Path B step 5 of 5. Run the source-defined Msi Mode On or Off branch for every display device returned by Get-PnpDevice -Class Display after explicit confirmation.'
                    Actions     = @('Analyze', 'Apply', 'Off')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'directx'
                    Title       = 'DirectX'
                    Stage       = 'Graphics'
                    Order       = 8
                    Type        = 'action'
                    RiskLevel   = 'high'
                    Description = 'Source-equivalent controlled runtime. Install 7-Zip, configure its source-defined options, download/extract DirectX, and launch DXSETUP after explicit confirmation.'
                    Actions     = @('Analyze', 'Apply')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $true; CanDownload = $true; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'visual-cpp'
                    Title       = 'Visual C++'
                    Stage       = 'Graphics'
                    Order       = 9
                    Type        = 'action'
                    RiskLevel   = 'high'
                    Description = 'Source-equivalent controlled runtime. Download all twelve source-defined Visual C++ redistributable installers and run them sequentially with exact source arguments after explicit confirmation.'
                    Actions     = @('Analyze', 'Apply')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $true; CanDownload = $true; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'graphics-configuration-center'
                    Title       = 'Graphics Configuration Center'
                    Stage       = 'Graphics'
                    Order       = 10
                    Type        = 'assistant'
                    RiskLevel   = 'low'
                    Description = 'Open the installed graphics control center for guided configuration.'
                    Actions     = @('Open')
                    Capabilities = @{ RequiresAdmin = $false; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $false }
                }
            )
        }
        @{
            Name        = 'Windows'
            Order       = 6
            Description = 'Configure approved Windows appearance, behavior, and maintenance tools.'
            Tools       = @(
                @{
                    Id          = 'start-menu-taskbar'
                    Title       = 'Start Menu Taskbar'
                    Stage       = 'Windows'
                    Order       = 1
                    Type        = 'action'
                    RiskLevel   = 'high'
                    Description = 'Apply the source-defined Start menu and taskbar clean profile or restore its source-defined default behavior.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'start-menu-layout'
                    Title       = 'Start Menu Layout'
                    Stage       = 'Windows'
                    Order       = 2
                    Type        = 'action'
                    RiskLevel   = 'low'
                    Description = 'Apply the recommended 25H2 Start menu layout or restore the source 24H2 layout.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'context-menu'
                    Title       = 'Context Menu'
                    Stage       = 'Windows'
                    Order       = 3
                    Type        = 'action'
                    RiskLevel   = 'medium'
                    Description = 'Apply the approved clean context menu or restore its source-defined handlers safely.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $true; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'theme-black'
                    Title       = 'Theme Black'
                    Stage       = 'Windows'
                    Order       = 4
                    Type        = 'action'
                    RiskLevel   = 'low'
                    Description = 'Apply or reset the approved dark Windows theme preference.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'signout-lockscreen-wallpaper-black'
                    Title       = 'Signout LockScreen Wallpaper Black'
                    Stage       = 'Windows'
                    Order       = 5
                    Type        = 'action'
                    RiskLevel   = 'medium'
                    Description = 'Apply a generated black sign-out, lock screen, and desktop wallpaper or safely restore the approved default.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'user-account-pictures-black'
                    Title       = 'User Account Pictures Black'
                    Stage       = 'Windows'
                    Order       = 6
                    Type        = 'action'
                    RiskLevel   = 'medium'
                    Description = 'Replace Windows account pictures with black images, or copy the source-defined legacy account-picture backup back to the Microsoft account-picture directory.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'widgets'
                    Title       = 'Widgets'
                    Stage       = 'Windows'
                    Order       = 7
                    Type        = 'action'
                    RiskLevel   = 'low'
                    Description = 'Disable Windows Widgets or restore the approved default policy behavior.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'copilot'
                    Title       = 'Copilot'
                    Stage       = 'Windows'
                    Order       = 8
                    Type        = 'action'
                    RiskLevel   = 'high'
                    Description = 'Run the approved source-equivalent Copilot Off or Default workflow.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $true; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $true; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'game-mode'
                    Title       = 'GameMode'
                    Stage       = 'Windows'
                    Order       = 9
                    Type        = 'assistant'
                    RiskLevel   = 'low'
                    Description = 'Open the Windows Game Mode settings page.'
                    Actions     = @('Open')
                    Capabilities = @{ RequiresAdmin = $false; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $false }
                }
                @{
                    Id          = 'pointer-precision'
                    Title       = 'Pointer Precision'
                    Stage       = 'Windows'
                    Order       = 10
                    Type        = 'assistant'
                    RiskLevel   = 'low'
                    Description = 'Open the Windows Mouse Properties pointer options page.'
                    Actions     = @('Open')
                    Capabilities = @{ RequiresAdmin = $false; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $false }
                }
                @{
                    Id          = 'bloatware'
                    Title       = 'Bloatware'
                    Stage       = 'Windows'
                    Order       = 11
                    Type        = 'assistant'
                    RiskLevel   = 'high'
                    Description = 'Run one approved source-equivalent Bloatware branch after explicit confirmation.'
                    Actions     = @('Analyze', 'Apply')
                    SelectionMode = 'SingleSelect'
                    SelectionRequiredActions = @('Apply')
                    SelectionLabel = 'Select exactly one Bloatware source branch'
                    SelectionItems = @(
                        @{ Id = 'RemoveAllBloatware'; Title = 'Remove all bloatware'; SourceMenuNumber = 2 }
                        @{ Id = 'InstallStore'; Title = 'Install Store'; SourceMenuNumber = 3 }
                        @{ Id = 'InstallAllUwpApps'; Title = 'Install all UWP apps'; SourceMenuNumber = 4 }
                        @{ Id = 'OpenUwpFeatures'; Title = 'Open/list UWP optional features'; SourceMenuNumber = 5 }
                        @{ Id = 'OpenLegacyFeatures'; Title = 'Open/list legacy optional features'; SourceMenuNumber = 6 }
                        @{ Id = 'InstallOneDrive'; Title = 'Install OneDrive'; SourceMenuNumber = 7 }
                        @{ Id = 'InstallRemoteDesktopConnection'; Title = 'Install Remote Desktop Connection'; SourceMenuNumber = 8 }
                        @{ Id = 'InstallSnippingTool'; Title = 'Install Snipping Tool'; SourceMenuNumber = 9 }
                    )
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $true; CanInstallSoftware = $true; CanDownload = $true; CanModifyDrivers = $false; CanModifySecurity = $true; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'game-bar'
                    Title       = 'GameBar'
                    Stage       = 'Windows'
                    Order       = 12
                    Type        = 'action'
                    RiskLevel   = 'high'
                    Description = 'Apply the source-equivalent Gamebar Xbox Off branch or run the source-defined Default repair branch.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $true; CanInstallSoftware = $true; CanDownload = $true; CanModifyDrivers = $false; CanModifySecurity = $true; CanDeleteFiles = $false; UsesTrustedInstaller = $true; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'edge-webview'
                    Title       = 'Edge & WebView'
                    Stage       = 'Windows'
                    Order       = 13
                    Type        = 'action'
                    RiskLevel   = 'high'
                    Description = 'Run the source-equivalent Edge and WebView uninstall branch or the source-defined Default repair branch.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $true; CanInstallSoftware = $true; CanDownload = $true; CanModifyDrivers = $false; CanModifySecurity = $true; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'notepad-settings'
                    Title       = 'Notepad Settings'
                    Stage       = 'Windows'
                    Order       = 14
                    Type        = 'action'
                    RiskLevel   = 'medium'
                    Description = 'Apply the source-defined Notepad LocalState settings or reset Notepad by deleting its settings.dat.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'control-panel-settings'
                    Title       = 'Control Panel Settings'
                    Stage       = 'Windows'
                    Order       = 15
                    Type        = 'action'
                    RiskLevel   = 'high'
                    Description = 'Run the exact source-defined Control Panel Settings Optimize or Default branch after explicit confirmation.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $true; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $true; CanDeleteFiles = $true; UsesTrustedInstaller = $true; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'sound'
                    Title       = 'Sound'
                    Stage       = 'Windows'
                    Order       = 16
                    Type        = 'assistant'
                    RiskLevel   = 'low'
                    Description = 'Open Windows sound settings for device and output configuration.'
                    Actions     = @('Open')
                    Capabilities = @{ RequiresAdmin = $false; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $false }
                }
                @{
                    Id          = 'device-manager-power-savings-wake'
                    Title       = 'Device Manager Power Savings & Wake'
                    Stage       = 'Windows'
                    Order       = 17
                    Type        = 'action'
                    RiskLevel   = 'medium'
                    Description = 'Disable source-approved device power-saving and wake values or restore the Ultimate default value removals.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'network-adapter-power-savings-wake'
                    Title       = 'Network Adapter Power Savings & Wake'
                    Stage       = 'Windows'
                    Order       = 18
                    Type        = 'action'
                    RiskLevel   = 'medium'
                    Description = 'Disable approved network adapter power-saving and wake values or restore their default absent state.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $true; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'write-cache-buffer-flushing'
                    Title       = 'Write Cache Buffer Flushing'
                    Stage       = 'Windows'
                    Order       = 19
                    Type        = 'action'
                    RiskLevel   = 'high'
                    Description = 'Analyze and apply the approved storage write-cache buffer flushing registry value with captured prior state.'
                    Actions     = @('Analyze', 'Apply')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'power-plan'
                    Title       = 'Power Plan'
                    Stage       = 'Windows'
                    Order       = 20
                    Type        = 'action'
                    RiskLevel   = 'medium'
                    Description = 'Apply the approved Ultimate power configuration or restore Windows default power schemes.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'cleanup'
                    Title       = 'Cleanup'
                    Stage       = 'Windows'
                    Order       = 21
                    Type        = 'action'
                    RiskLevel   = 'medium'
                    Description = 'Analyze removable temporary data before preparing a cleanup operation.'
                    Actions     = @('Analyze', 'Apply')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'restore-point'
                    Title       = 'Restore Point'
                    Stage       = 'Windows'
                    Order       = 22
                    Type        = 'action'
                    RiskLevel   = 'medium'
                    Description = 'Create an approved Windows restore point or open System Protection and System Restore.'
                    Actions     = @('Apply', 'Open')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
            )
        }
        @{
            Name        = 'Advanced'
            Order       = 7
            Description = 'Analyze advanced performance and security options before applying changes.'
            Tools       = @(
                @{
                    Id          = 'spectre-meltdown-assistant'
                    Title       = 'Spectre / Meltdown Assistant'
                    Stage       = 'Advanced'
                    Order       = 1
                    Type        = 'assistant'
                    RiskLevel   = 'high'
                    Description = 'Analyze mitigation state and explain security and performance tradeoffs.'
                    Actions     = @('Analyze', 'Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $true; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'mmagent-assistant'
                    Title       = 'MMAgent Assistant'
                    Stage       = 'Advanced'
                    Order       = 2
                    Type        = 'assistant'
                    RiskLevel   = 'high'
                    Description = 'Analyze current MMAgent state and apply or restore the approved Ultimate MMAgent feature profile.'
                    Actions     = @('Analyze', 'Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'resizable-bar-assistant'
                    Title       = 'Resizable BAR Assistant'
                    Stage       = 'Advanced'
                    Order       = 3
                    Type        = 'assistant'
                    RiskLevel   = 'high'
                    Description = 'Analyze hardware support and explain firmware requirements for Resizable BAR.'
                    Actions     = @('Analyze', 'Open')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $true; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $true; CanModifyDrivers = $true; CanModifySecurity = $false; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'smt-ht-assistant'
                    Title       = 'SMT / HT Assistant'
                    Stage       = 'Advanced'
                    Order       = 4
                    Type        = 'assistant'
                    RiskLevel   = 'high'
                    Description = 'Analyze processor topology and temporarily disable sibling CPU threads per selected app or launcher.'
                    Actions     = @('Analyze', 'Apply', 'Open')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'services-optimizer'
                    Title       = 'Services Optimizer'
                    Stage       = 'Advanced'
                    Order       = 5
                    Type        = 'assistant'
                    RiskLevel   = 'high'
                    Description = 'Analyze Windows services and prepare a reviewed optimization plan.'
                    Actions     = @('Analyze', 'Apply', 'Restore')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $true; CanModifyRegistry = $true; CanModifyServices = $true; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $true; CanDeleteFiles = $true; UsesTrustedInstaller = $true; UsesSafeMode = $true; SupportsDefault = $false; SupportsRestore = $true; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'timer-resolution-assistant'
                    Title       = 'Timer Resolution Assistant'
                    Stage       = 'Advanced'
                    Order       = 6
                    Type        = 'assistant'
                    RiskLevel   = 'high'
                    Description = 'Analyze timer behavior and explain latency, power, and stability tradeoffs.'
                    Actions     = @('Analyze', 'Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $true; CanInstallSoftware = $true; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'defender-optimize-assistant'
                    Title       = 'Defender Optimize Assistant'
                    Stage       = 'Advanced'
                    Order       = 7
                    Type        = 'assistant'
                    RiskLevel   = 'high'
                    Description = 'Analyze Microsoft Defender settings before recommending approved changes.'
                    Actions     = @('Analyze', 'Apply', 'Restore')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $true; CanModifyRegistry = $true; CanModifyServices = $true; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $true; CanModifySecurity = $true; CanDeleteFiles = $true; UsesTrustedInstaller = $true; UsesSafeMode = $true; SupportsDefault = $false; SupportsRestore = $true; NeedsExplicitConfirmation = $true }
                }
            )
        }
    )
}
