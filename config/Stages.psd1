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
                    Type        = 'assistant'
                    RiskLevel   = 'high'
                    Description = 'Review prerequisites and prepare a guided Windows reinstall workflow.'
                    Actions     = @('Analyze', 'Apply')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $true; CanModifyRegistry = $true; CanModifyServices = $true; CanInstallSoftware = $true; CanDownload = $true; CanModifyDrivers = $true; CanModifySecurity = $true; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'unattended'
                    Title       = 'Unattended'
                    Stage       = 'Refresh'
                    Order       = 2
                    Type        = 'action'
                    RiskLevel   = 'high'
                    Description = 'Prepare unattended Windows setup options for review before use.'
                    Actions     = @('Analyze', 'Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $true; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $true; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'updates-drivers-block'
                    Title       = 'Updates Drivers Block'
                    Stage       = 'Refresh'
                    Order       = 3
                    Type        = 'action'
                    RiskLevel   = 'medium'
                    Description = 'Manage the policy that controls driver delivery through Windows Update.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $true; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
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
                    Id          = 'memory-compression'
                    Title       = 'Memory Compression'
                    Stage       = 'Setup'
                    Order       = 1
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
                    Order       = 2
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
                    Order       = 3
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
                    Order       = 4
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
                    Order       = 5
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
                    Order       = 6
                    Type        = 'assistant'
                    RiskLevel   = 'low'
                    Description = 'Open Microsoft Edge settings for technician-guided configuration.'
                    Actions     = @('Open')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $true; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'store-settings'
                    Title       = 'Store Settings'
                    Stage       = 'Setup'
                    Order       = 7
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
                    Order       = 8
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
                    Type        = 'action'
                    RiskLevel   = 'medium'
                    Description = 'Review and prepare approved application installation selections.'
                    Actions     = @('Open', 'Apply')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $true; CanInstallSoftware = $true; CanDownload = $true; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
            )
        }
        @{
            Name        = 'Graphics'
            Order       = 5
            Description = 'Prepare graphics drivers, runtimes, and display configuration.'
            Tools       = @(
                @{
                    Id          = 'driver-install-debloat-settings'
                    Title       = 'Driver Install Debloat & Settings'
                    Stage       = 'Graphics'
                    Order       = 1
                    Type        = 'assistant'
                    RiskLevel   = 'high'
                    Description = 'Analyze graphics hardware and prepare a guided driver installation workflow.'
                    Actions     = @('Analyze', 'Apply', 'Restore')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $true; CanModifyRegistry = $true; CanModifyServices = $true; CanInstallSoftware = $true; CanDownload = $true; CanModifyDrivers = $true; CanModifySecurity = $true; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $true; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'directx'
                    Title       = 'DirectX'
                    Stage       = 'Graphics'
                    Order       = 2
                    Type        = 'action'
                    RiskLevel   = 'medium'
                    Description = 'Review and prepare the approved DirectX runtime installation.'
                    Actions     = @('Analyze', 'Apply')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $true; CanDownload = $true; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'visual-cpp'
                    Title       = 'Visual C++'
                    Stage       = 'Graphics'
                    Order       = 3
                    Type        = 'action'
                    RiskLevel   = 'medium'
                    Description = 'Review and prepare approved Microsoft Visual C++ runtime installation.'
                    Actions     = @('Analyze', 'Apply')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $true; CanDownload = $true; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'graphics-configuration-center'
                    Title       = 'Graphics Configuration Center'
                    Stage       = 'Graphics'
                    Order       = 4
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
                    Type        = 'assistant'
                    RiskLevel   = 'low'
                    Description = 'Open Windows personalization controls for Start and taskbar settings.'
                    Actions     = @('Open')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $false }
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
                    RiskLevel   = 'low'
                    Description = 'Apply or restore the approved black user account image set.'
                    Actions     = @('Apply', 'Restore')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $true; NeedsExplicitConfirmation = $true }
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
                    RiskLevel   = 'medium'
                    Description = 'Manage supported Windows Copilot policy preferences.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
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
                    RiskLevel   = 'medium'
                    Description = 'Analyze installed applications before preparing a reviewed removal plan.'
                    Actions     = @('Analyze', 'Apply', 'Restore')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $true; CanInstallSoftware = $true; CanDownload = $true; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $true; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'game-bar'
                    Title       = 'GameBar'
                    Stage       = 'Windows'
                    Order       = 12
                    Type        = 'action'
                    RiskLevel   = 'low'
                    Description = 'Manage the reversible Xbox Game Bar preference.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $true; CanInstallSoftware = $true; CanDownload = $true; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $true; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'edge-webview'
                    Title       = 'Edge & WebView'
                    Stage       = 'Windows'
                    Order       = 13
                    Type        = 'assistant'
                    RiskLevel   = 'medium'
                    Description = 'Review Microsoft Edge and WebView components before making changes.'
                    Actions     = @('Analyze', 'Open')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $true; CanInstallSoftware = $true; CanDownload = $true; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'notepad-settings'
                    Title       = 'Notepad Settings'
                    Stage       = 'Windows'
                    Order       = 14
                    Type        = 'assistant'
                    RiskLevel   = 'low'
                    Description = 'Open Notepad settings for technician-guided configuration.'
                    Actions     = @('Open')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $false }
                }
                @{
                    Id          = 'control-panel-settings'
                    Title       = 'Control Panel Settings'
                    Stage       = 'Windows'
                    Order       = 15
                    Type        = 'assistant'
                    RiskLevel   = 'low'
                    Description = 'Open Control Panel for technician-guided Windows configuration.'
                    Actions     = @('Open')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $true; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $true; CanDeleteFiles = $true; UsesTrustedInstaller = $true; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
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
                    Id          = 'loudness-eq'
                    Title       = 'Loudness EQ'
                    Stage       = 'Windows'
                    Order       = 17
                    Type        = 'assistant'
                    RiskLevel   = 'low'
                    Description = 'Open audio device properties for loudness equalization review.'
                    Actions     = @('Open')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $true; CanModifyServices = $true; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'device-manager-power-savings-wake'
                    Title       = 'Device Manager Power Savings & Wake'
                    Stage       = 'Windows'
                    Order       = 18
                    Type        = 'assistant'
                    RiskLevel   = 'low'
                    Description = 'Open Device Manager for guided power-saving and wake configuration.'
                    Actions     = @('Open')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $false }
                }
                @{
                    Id          = 'network-adapter-power-savings-wake'
                    Title       = 'Network Adapter Power Savings & Wake'
                    Stage       = 'Windows'
                    Order       = 19
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
                    Order       = 20
                    Type        = 'assistant'
                    RiskLevel   = 'high'
                    Description = 'Analyze storage hardware before changing write-cache buffer flushing.'
                    Actions     = @('Analyze', 'Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $true; CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $true; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'power-plan'
                    Title       = 'Power Plan'
                    Stage       = 'Windows'
                    Order       = 21
                    Type        = 'action'
                    RiskLevel   = 'medium'
                    Description = 'Apply or reset the approved Windows power plan configuration.'
                    Actions     = @('Apply', 'Default')
                    Capabilities = @{ RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false; CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false; CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false; CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false; SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true }
                }
                @{
                    Id          = 'cleanup'
                    Title       = 'Cleanup'
                    Stage       = 'Windows'
                    Order       = 22
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
                    Order       = 23
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
                    Description = 'Analyze Windows memory-management features before recommending changes.'
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
                    Description = 'Analyze processor topology and explain SMT or Hyper-Threading tradeoffs.'
                    Actions     = @('Analyze', 'Open')
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
