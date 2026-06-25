Set-StrictMode -Version Latest

if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1') -Force
}
if (-not (Get-Command -Name 'Invoke-BoostLabOfficialVendorDownload' -ErrorAction SilentlyContinue)) {
    Import-Module (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\DownloadProvenance.psm1') -Force
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'installers'
    Title = 'Installers'
    Stage = 'Installers'
    Order = 1
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Single-app installer workflow. Installs exactly one Yazan-retained Ultimate app choice per Apply after confirmation; removed app choices are hidden and unavailable.'
    Actions = @('Analyze', 'Open', 'Apply', 'Default', 'Restore')
    Capabilities = [ordered]@{
        RequiresAdmin             = $true
        RequiresInternet          = $true
        CanReboot                 = $false
        CanModifyRegistry         = $true
        CanModifyServices         = $true
        CanInstallSoftware        = $true
        CanDownload               = $true
        CanModifyDrivers          = $false
        CanModifySecurity         = $false
        CanDeleteFiles            = $true
        UsesTrustedInstaller      = $false
        UsesSafeMode              = $false
        SupportsDefault           = $false
        SupportsRestore           = $false
        NeedsExplicitConfirmation = $true
    }
}

$script:BoostLabImplementedActions = @('Analyze', 'Open', 'Apply', 'Default', 'Restore')
$script:BoostLabExpectedSourceHash = '1065D64183457D4E7B28EA78DDE41525EC8F7C4A4BCA12D29B70D991141C0C67'
$script:BoostLabExpectedCanonicalSourceHash = '268C1EFE627FADDA17892223D4C35E4845833506C22AADD3240C894ED046A6F8'
$script:BoostLabSourceRelativePath = 'source-ultimate/4 Installers/1 Installers.ps1'

$script:BoostLabInstallersRemovedMenuEntries = @(
    [pscustomobject]@{ SourceMenuNumber = 9; AppId = 'escape-from-tarkov'; DisplayName = 'Escape From Tarkov' }
    [pscustomobject]@{ SourceMenuNumber = 11; AppId = 'frame-view'; DisplayName = 'Frame View' }
    [pscustomobject]@{ SourceMenuNumber = 12; AppId = 'gog-launcher'; DisplayName = 'GOG launcher' }
    [pscustomobject]@{ SourceMenuNumber = 15; AppId = 'notepad-plus-plus'; DisplayName = 'Notepad ++' }
    [pscustomobject]@{ SourceMenuNumber = 16; AppId = 'nvidia-app'; DisplayName = 'Nvidia App' }
    [pscustomobject]@{ SourceMenuNumber = 18; AppId = 'onboard-memory-manager'; DisplayName = 'Onboard Memory Manager' }
    [pscustomobject]@{ SourceMenuNumber = 19; AppId = 'pot-player'; DisplayName = 'Pot Player' }
)

function New-BoostLabInstallersOperation {
    param(
        [Parameter(Mandatory)][string]$Type,
        [Parameter(Mandatory)][string]$Label,
        [hashtable]$Parameters = @{}
    )

    [pscustomobject]@{
        Type       = $Type
        Label      = $Label
        Parameters = [ordered]@{} + $Parameters
    }
}

function New-BoostLabInstallersAppDescriptor {
    param(
        [Parameter(Mandatory)][int]$SourceMenuNumber,
        [Parameter(Mandatory)][string]$AppId,
        [Parameter(Mandatory)][string]$DisplayName,
        [object[]]$Artifacts = @(),
        [object[]]$InstallerCommands = @(),
        [object[]]$Operations = @(),
        [string[]]$SideEffectFamilies = @()
    )

    [pscustomobject]@{
        SourceMenuNumber  = $SourceMenuNumber
        AppId             = $AppId
        DisplayName       = $DisplayName
        RemovedByYazan    = $false
        Visible           = $true
        Selectable        = $true
        Artifacts         = @($Artifacts)
        InstallerCommands = @($InstallerCommands)
        Operations        = @($Operations)
        SideEffectFamilies = @($SideEffectFamilies)
    }
}

function New-BoostLabInstallersArtifact {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$DestinationPath
    )

    [pscustomobject]@{
        Url             = $Url
        DestinationPath = $DestinationPath
    }
}

function New-BoostLabInstallersCommand {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [string]$Arguments = '',
        [bool]$Wait = $false,
        [string]$Launcher = 'Start-Process'
    )

    [pscustomobject]@{
        Launcher  = $Launcher
        FilePath  = $FilePath
        Arguments = $Arguments
        Wait      = $Wait
    }
}

function Get-BoostLabInstallersFullSourceMenu {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param()

    @(
        [pscustomobject]@{ SourceMenuNumber = 1; AppId = 'exit'; DisplayName = 'Exit'; RemovedByYazan = $false; Visible = $false; Selectable = $false }
        [pscustomobject]@{ SourceMenuNumber = 2; AppId = 'discord'; DisplayName = 'Discord'; RemovedByYazan = $false; Visible = $true; Selectable = $true }
        [pscustomobject]@{ SourceMenuNumber = 3; AppId = 'roblox'; DisplayName = 'Roblox'; RemovedByYazan = $false; Visible = $true; Selectable = $true }
        [pscustomobject]@{ SourceMenuNumber = 4; AppId = 'seven-zip'; DisplayName = '7-Zip'; RemovedByYazan = $false; Visible = $true; Selectable = $true }
        [pscustomobject]@{ SourceMenuNumber = 5; AppId = 'battle-net'; DisplayName = 'Battle.net'; RemovedByYazan = $false; Visible = $true; Selectable = $true }
        [pscustomobject]@{ SourceMenuNumber = 6; AppId = 'brave'; DisplayName = 'Brave'; RemovedByYazan = $false; Visible = $true; Selectable = $true }
        [pscustomobject]@{ SourceMenuNumber = 7; AppId = 'electronic-arts'; DisplayName = 'Electronic Arts'; RemovedByYazan = $false; Visible = $true; Selectable = $true }
        [pscustomobject]@{ SourceMenuNumber = 8; AppId = 'epic-games'; DisplayName = 'Epic Games'; RemovedByYazan = $false; Visible = $true; Selectable = $true }
        [pscustomobject]@{ SourceMenuNumber = 9; AppId = 'escape-from-tarkov'; DisplayName = 'Escape From Tarkov'; RemovedByYazan = $true; Visible = $false; Selectable = $false }
        [pscustomobject]@{ SourceMenuNumber = 10; AppId = 'firefox'; DisplayName = 'Firefox'; RemovedByYazan = $false; Visible = $true; Selectable = $true }
        [pscustomobject]@{ SourceMenuNumber = 11; AppId = 'frame-view'; DisplayName = 'Frame View'; RemovedByYazan = $true; Visible = $false; Selectable = $false }
        [pscustomobject]@{ SourceMenuNumber = 12; AppId = 'gog-launcher'; DisplayName = 'GOG launcher'; RemovedByYazan = $true; Visible = $false; Selectable = $false }
        [pscustomobject]@{ SourceMenuNumber = 13; AppId = 'google-chrome'; DisplayName = 'Google Chrome'; RemovedByYazan = $false; Visible = $true; Selectable = $true }
        [pscustomobject]@{ SourceMenuNumber = 14; AppId = 'league-of-legends'; DisplayName = 'League Of Legends'; RemovedByYazan = $false; Visible = $true; Selectable = $true }
        [pscustomobject]@{ SourceMenuNumber = 15; AppId = 'notepad-plus-plus'; DisplayName = 'Notepad ++'; RemovedByYazan = $true; Visible = $false; Selectable = $false }
        [pscustomobject]@{ SourceMenuNumber = 16; AppId = 'nvidia-app'; DisplayName = 'Nvidia App'; RemovedByYazan = $true; Visible = $false; Selectable = $false }
        [pscustomobject]@{ SourceMenuNumber = 17; AppId = 'obs-studio'; DisplayName = 'OBS Studio'; RemovedByYazan = $false; Visible = $true; Selectable = $true }
        [pscustomobject]@{ SourceMenuNumber = 18; AppId = 'onboard-memory-manager'; DisplayName = 'Onboard Memory Manager'; RemovedByYazan = $true; Visible = $false; Selectable = $false }
        [pscustomobject]@{ SourceMenuNumber = 19; AppId = 'pot-player'; DisplayName = 'Pot Player'; RemovedByYazan = $true; Visible = $false; Selectable = $false }
        [pscustomobject]@{ SourceMenuNumber = 20; AppId = 'rockstar-games'; DisplayName = 'Rockstar Games'; RemovedByYazan = $false; Visible = $true; Selectable = $true }
        [pscustomobject]@{ SourceMenuNumber = 21; AppId = 'spotify'; DisplayName = 'Spotify'; RemovedByYazan = $false; Visible = $true; Selectable = $true }
        [pscustomobject]@{ SourceMenuNumber = 22; AppId = 'steam'; DisplayName = 'Steam'; RemovedByYazan = $false; Visible = $true; Selectable = $true }
        [pscustomobject]@{ SourceMenuNumber = 23; AppId = 'ubisoft-connect'; DisplayName = 'Ubisoft Connect'; RemovedByYazan = $false; Visible = $true; Selectable = $true }
        [pscustomobject]@{ SourceMenuNumber = 24; AppId = 'valorant'; DisplayName = 'Valorant'; RemovedByYazan = $false; Visible = $true; Selectable = $true }
    )
}

function Get-BoostLabInstallersCatalog {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param()

    @(
        New-BoostLabInstallersAppDescriptor -SourceMenuNumber 2 -AppId 'discord' -DisplayName 'Discord' -Artifacts @(
            New-BoostLabInstallersArtifact -Url 'https://discord.com/api/downloads/distributions/app/installers/latest?channel=stable&platform=win&arch=x64' -DestinationPath '$tempDir\Discord.exe'
        ) -InstallerCommands @(
            New-BoostLabInstallersCommand -FilePath '$tempDir\Discord.exe'
        ) -Operations @(
            New-BoostLabInstallersOperation -Type 'WriteTextFile' -Label 'Write Discord settings.json' -Parameters @{ Path = '$env:APPDATA\discord\settings.json'; Content = '{ "SKIP_HOST_UPDATE": true, "DEVELOPER_MODE": true, "enableHardwareAcceleration": false, "MINIMIZE_TO_TRAY": true, "OPEN_ON_STARTUP": false, "START_MINIMIZED": false, "IS_MAXIMIZED": true, "IS_MINIMIZED": false, "debugLogging": false }' }
            New-BoostLabInstallersOperation -Type 'Download' -Label 'Download Discord installer' -Parameters @{ Url = 'https://discord.com/api/downloads/distributions/app/installers/latest?channel=stable&platform=win&arch=x64'; DestinationPath = '$tempDir\Discord.exe' }
            New-BoostLabInstallersOperation -Type 'StartProcess' -Label 'Start Discord installer' -Parameters @{ FilePath = '$tempDir\Discord.exe'; Arguments = ''; Wait = $false }
        ) -SideEffectFamilies @('AppConfiguration', 'Download', 'InstallerLaunch')

        New-BoostLabInstallersAppDescriptor -SourceMenuNumber 3 -AppId 'roblox' -DisplayName 'Roblox' -Artifacts @(
            New-BoostLabInstallersArtifact -Url 'https://www.roblox.com/download/client?os=win' -DestinationPath '$env:SystemRoot\Temp\Roblox.exe'
        ) -InstallerCommands @(
            New-BoostLabInstallersCommand -FilePath '$env:SystemRoot\Temp\Roblox.exe' -Arguments '/S'
        ) -Operations @(
            New-BoostLabInstallersOperation -Type 'Download' -Label 'Download Roblox installer' -Parameters @{ Url = 'https://www.roblox.com/download/client?os=win'; DestinationPath = '$env:SystemRoot\Temp\Roblox.exe' }
            New-BoostLabInstallersOperation -Type 'StartProcess' -Label 'Start Roblox installer' -Parameters @{ FilePath = '$env:SystemRoot\Temp\Roblox.exe'; Arguments = '/S'; Wait = $false }
        ) -SideEffectFamilies @('Download', 'InstallerLaunch')

        New-BoostLabInstallersAppDescriptor -SourceMenuNumber 4 -AppId 'seven-zip' -DisplayName '7-Zip' -Artifacts @(
            New-BoostLabInstallersArtifact -Url 'https://www.7-zip.org/a/7z2301-x64.exe' -DestinationPath '$env:SystemRoot\Temp\7 Zip.exe'
        ) -InstallerCommands @(
            New-BoostLabInstallersCommand -FilePath '$env:SystemRoot\Temp\7 Zip.exe' -Arguments '/S' -Wait $true
        ) -Operations @(
            New-BoostLabInstallersOperation -Type 'Download' -Label 'Download 7-Zip installer' -Parameters @{ Url = 'https://www.7-zip.org/a/7z2301-x64.exe'; DestinationPath = '$env:SystemRoot\Temp\7 Zip.exe' }
            New-BoostLabInstallersOperation -Type 'StartProcess' -Label 'Install 7-Zip silently' -Parameters @{ FilePath = '$env:SystemRoot\Temp\7 Zip.exe'; Arguments = '/S'; Wait = $true }
            New-BoostLabInstallersOperation -Type 'SetRegistryValue' -Label 'Set 7-Zip context menu policy' -Parameters @{ Path = 'HKCU:\Software\7-Zip\Options'; Name = 'ContextMenu'; Type = 'DWord'; Value = 259 }
            New-BoostLabInstallersOperation -Type 'SetRegistryValue' -Label 'Disable 7-Zip cascaded menu' -Parameters @{ Path = 'HKCU:\Software\7-Zip\Options'; Name = 'CascadedMenu'; Type = 'DWord'; Value = 0 }
            New-BoostLabInstallersOperation -Type 'MoveItem' -Label 'Move 7-Zip Start Menu shortcut' -Parameters @{ Path = '$env:ProgramData\Microsoft\Windows\Start Menu\Programs\7-Zip\7-Zip File Manager.lnk'; Destination = '$env:ProgramData\Microsoft\Windows\Start Menu\Programs\7-Zip File Manager.lnk'; IgnoreMissing = $true }
            New-BoostLabInstallersOperation -Type 'RemoveItem' -Label 'Remove 7-Zip Start Menu folder' -Parameters @{ Path = '$env:ProgramData\Microsoft\Windows\Start Menu\Programs\7-Zip'; Recurse = $true; IgnoreMissing = $true }
            New-BoostLabInstallersOperation -Type 'CreateShortcut' -Label 'Create 7-Zip desktop shortcut' -Parameters @{ Path = '$Desktop\7-Zip File Manager.lnk'; TargetPath = '$env:SystemDrive\Program Files\7-Zip\7zFM.exe'; WorkingDirectory = '$env:SystemDrive\Program Files\7-Zip' }
        ) -SideEffectFamilies @('Download', 'InstallerLaunch', 'Registry', 'Shortcut', 'FileMove', 'Cleanup')

        New-BoostLabInstallersAppDescriptor -SourceMenuNumber 5 -AppId 'battle-net' -DisplayName 'Battle.net' -Artifacts @(
            New-BoostLabInstallersArtifact -Url 'https://downloader.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe' -DestinationPath '$env:SystemRoot\Temp\Battle.net.exe'
        ) -InstallerCommands @(
            New-BoostLabInstallersCommand -FilePath '$env:SystemRoot\Temp\Battle.net.exe' -Arguments '--lang=enUS --installpath="C:\Program Files (x86)\Battle.net"'
        ) -Operations @(
            New-BoostLabInstallersOperation -Type 'Download' -Label 'Download Battle.net installer' -Parameters @{ Url = 'https://downloader.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe'; DestinationPath = '$env:SystemRoot\Temp\Battle.net.exe' }
            New-BoostLabInstallersOperation -Type 'StartProcess' -Label 'Start Battle.net installer' -Parameters @{ FilePath = '$env:SystemRoot\Temp\Battle.net.exe'; Arguments = '--lang=enUS --installpath="C:\Program Files (x86)\Battle.net"'; Wait = $false }
            New-BoostLabInstallersOperation -Type 'CreateShortcut' -Label 'Create Battle.net desktop shortcut' -Parameters @{ Path = '$Desktop\Battle.net.lnk'; TargetPath = '$env:SystemDrive\Program Files (x86)\Battle.net\Battle.net Launcher.exe'; WorkingDirectory = '$env:SystemDrive\Program Files (x86)\Battle.net' }
            New-BoostLabInstallersOperation -Type 'CreateShortcut' -Label 'Create Battle.net Start Menu shortcut' -Parameters @{ Path = '$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Battle.net.lnk'; TargetPath = '$env:SystemDrive\Program Files (x86)\Battle.net\Battle.net Launcher.exe'; WorkingDirectory = '$env:SystemDrive\Program Files (x86)\Battle.net' }
        ) -SideEffectFamilies @('Download', 'InstallerLaunch', 'Shortcut')

        New-BoostLabInstallersAppDescriptor -SourceMenuNumber 6 -AppId 'brave' -DisplayName 'Brave' -Artifacts @(
            New-BoostLabInstallersArtifact -Url 'https://brave-browser-downloads.s3.brave.com/latest/brave_installer-x64.exe' -DestinationPath '$env:SystemRoot\Temp\BraveInstaller.exe'
        ) -InstallerCommands @(
            New-BoostLabInstallersCommand -FilePath '$env:SystemRoot\Temp\BraveInstaller.exe' -Arguments '--system-level' -Wait $true
        ) -Operations @(
            New-BoostLabInstallersOperation -Type 'Download' -Label 'Download Brave installer' -Parameters @{ Url = 'https://brave-browser-downloads.s3.brave.com/latest/brave_installer-x64.exe'; DestinationPath = '$env:SystemRoot\Temp\BraveInstaller.exe' }
            New-BoostLabInstallersOperation -Type 'StartProcess' -Label 'Install Brave system-level' -Parameters @{ FilePath = '$env:SystemRoot\Temp\BraveInstaller.exe'; Arguments = '--system-level'; Wait = $true }
            New-BoostLabInstallersOperation -Type 'SetRegistryValue' -Label 'Force install uBlock Origin in Brave' -Parameters @{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave\ExtensionInstallForcelist'; Name = '1'; Type = 'String'; Value = 'cjpalhdlnbpafiamejdnhcphjbkeiagm;https://clients2.google.com/service/update2/crx' }
            New-BoostLabInstallersOperation -Type 'SetRegistryValue' -Label 'Disable Brave hardware acceleration' -Parameters @{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'HardwareAccelerationModeEnabled'; Type = 'DWord'; Value = 0 }
            New-BoostLabInstallersOperation -Type 'SetRegistryValue' -Label 'Disable Brave background mode' -Parameters @{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'BackgroundModeEnabled'; Type = 'DWord'; Value = 0 }
            New-BoostLabInstallersOperation -Type 'SetRegistryValue' -Label 'Enable Brave high efficiency policy' -Parameters @{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'HighEfficiencyModeEnabled'; Type = 'DWord'; Value = 1 }
            New-BoostLabInstallersOperation -Type 'RemoveActiveSetupByDefaultMatch' -Label 'Remove Brave Active Setup entries' -Parameters @{ Path = 'HKLM:\Software\Microsoft\Active Setup\Installed Components'; Pattern = '*Brave*' }
            New-BoostLabInstallersOperation -Type 'StopDeleteServicesByNameMatch' -Label 'Stop and delete Brave services' -Parameters @{ Pattern = 'Brave' }
            New-BoostLabInstallersOperation -Type 'RemoveScheduledTasksByNameLike' -Label 'Remove Brave scheduled tasks' -Parameters @{ Pattern = '*Brave*' }
        ) -SideEffectFamilies @('Download', 'InstallerLaunch', 'Registry', 'ActiveSetup', 'ServiceStopDelete', 'ScheduledTaskRemoval')

        New-BoostLabInstallersAppDescriptor -SourceMenuNumber 7 -AppId 'electronic-arts' -DisplayName 'Electronic Arts' -Artifacts @(
            New-BoostLabInstallersArtifact -Url 'https://origin-a.akamaihd.net/EA-Desktop-Client-Download/installer-releases/EAappInstaller.exe' -DestinationPath '$env:SystemRoot\Temp\Electronic Arts.exe'
        ) -InstallerCommands @(
            New-BoostLabInstallersCommand -FilePath '$env:SystemRoot\Temp\Electronic Arts.exe'
        ) -Operations @(
            New-BoostLabInstallersOperation -Type 'Download' -Label 'Download Electronic Arts installer' -Parameters @{ Url = 'https://origin-a.akamaihd.net/EA-Desktop-Client-Download/installer-releases/EAappInstaller.exe'; DestinationPath = '$env:SystemRoot\Temp\Electronic Arts.exe' }
            New-BoostLabInstallersOperation -Type 'StartProcess' -Label 'Start Electronic Arts installer' -Parameters @{ FilePath = '$env:SystemRoot\Temp\Electronic Arts.exe'; Arguments = ''; Wait = $false }
        ) -SideEffectFamilies @('Download', 'InstallerLaunch')

        New-BoostLabInstallersAppDescriptor -SourceMenuNumber 8 -AppId 'epic-games' -DisplayName 'Epic Games' -Artifacts @(
            New-BoostLabInstallersArtifact -Url 'https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi' -DestinationPath '$env:SystemRoot\Temp\Epic Games.msi'
        ) -InstallerCommands @(
            New-BoostLabInstallersCommand -FilePath '$env:SystemRoot\Temp\Epic Games.msi' -Arguments '/quiet' -Wait $true
            New-BoostLabInstallersCommand -FilePath '$env:SystemDrive\Program Files\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe' -Wait $true
            New-BoostLabInstallersCommand -FilePath 'msiexec.exe' -Arguments '/x <Epic Online Services GUID> /qn' -Wait $true
        ) -Operations @(
            New-BoostLabInstallersOperation -Type 'Download' -Label 'Download Epic Games installer' -Parameters @{ Url = 'https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi'; DestinationPath = '$env:SystemRoot\Temp\Epic Games.msi' }
            New-BoostLabInstallersOperation -Type 'StartProcess' -Label 'Install Epic Games silently' -Parameters @{ FilePath = '$env:SystemRoot\Temp\Epic Games.msi'; Arguments = '/quiet'; Wait = $true }
            New-BoostLabInstallersOperation -Type 'LaunchEpicGamesLauncher' -Label 'Launch Epic Games for update/EOS install' -Parameters @{ SourceDefinedPath = '$env:SystemDrive\Program Files\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe'; Arguments = ''; Wait = $true; MaxWaitSeconds = 45; PollIntervalSeconds = 3 }
            New-BoostLabInstallersOperation -Type 'UninstallByDisplayName' -Label 'Uninstall Epic Online Services' -Parameters @{ RegistryPath = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'; DisplayNameLike = '*Epic Online Services*'; Arguments = '/x {0} /qn' }
            New-BoostLabInstallersOperation -Type 'RemoveRegistryValue' -Label 'Remove Epic Games startup value' -Parameters @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'; Name = 'EpicGamesLauncher'; IgnoreMissing = $true }
        ) -SideEffectFamilies @('Download', 'InstallerLaunch', 'ExternalAppLaunch', 'Uninstall', 'StartupRegistryCleanup')

        New-BoostLabInstallersAppDescriptor -SourceMenuNumber 10 -AppId 'firefox' -DisplayName 'Firefox' -Artifacts @(
            New-BoostLabInstallersArtifact -Url 'https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US' -DestinationPath '$env:SystemRoot\Temp\Firefox.exe'
            New-BoostLabInstallersArtifact -Url 'https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi' -DestinationPath 'C:\Program Files\Mozilla Firefox\distribution\extensions\uBlock0@raymondhill.net.xpi'
        ) -InstallerCommands @(
            New-BoostLabInstallersCommand -FilePath '$env:SystemRoot\Temp\Firefox.exe' -Arguments '/S' -Wait $true
            New-BoostLabInstallersCommand -FilePath 'C:\Program Files (x86)\Mozilla Maintenance Service\uninstall.exe' -Arguments '/S' -Wait $true
            New-BoostLabInstallersCommand -FilePath '$env:SystemDrive\Program Files\Mozilla Firefox\firefox.exe' -Arguments '--headless'
        ) -Operations @(
            New-BoostLabInstallersOperation -Type 'Download' -Label 'Download Firefox installer' -Parameters @{ Url = 'https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US'; DestinationPath = '$env:SystemRoot\Temp\Firefox.exe' }
            New-BoostLabInstallersOperation -Type 'StartProcess' -Label 'Install Firefox silently' -Parameters @{ FilePath = '$env:SystemRoot\Temp\Firefox.exe'; Arguments = '/S'; Wait = $true }
            New-BoostLabInstallersOperation -Type 'StartProcess' -Label 'Uninstall Mozilla Maintenance Service' -Parameters @{ FilePath = 'C:\Program Files (x86)\Mozilla Maintenance Service\uninstall.exe'; Arguments = '/S'; Wait = $true; IgnoreMissing = $true }
            New-BoostLabInstallersOperation -Type 'RemoveScheduledTasksByNameMatch' -Label 'Remove Firefox scheduled tasks' -Parameters @{ Pattern = 'Firefox' }
            New-BoostLabInstallersOperation -Type 'EnsureDirectory' -Label 'Create Firefox extension distribution folder' -Parameters @{ Path = 'C:\Program Files\Mozilla Firefox\distribution\extensions' }
            New-BoostLabInstallersOperation -Type 'Download' -Label 'Download uBlock Origin XPI' -Parameters @{ Url = 'https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi'; DestinationPath = 'C:\Program Files\Mozilla Firefox\distribution\extensions\uBlock0@raymondhill.net.xpi' }
            New-BoostLabInstallersOperation -Type 'SetRegistryValue' -Label 'Disable Firefox updates policy' -Parameters @{ Path = 'HKLM:\SOFTWARE\Policies\Mozilla\Firefox'; Name = 'AppAutoUpdate'; Type = 'DWord'; Value = 0 }
            New-BoostLabInstallersOperation -Type 'StartProcess' -Label 'Start Firefox headless for profile creation' -Parameters @{ FilePath = '$env:SystemDrive\Program Files\Mozilla Firefox\firefox.exe'; Arguments = '--headless'; Wait = $false }
            New-BoostLabInstallersOperation -Type 'Sleep' -Label 'Wait for Firefox profile creation' -Parameters @{ Seconds = 5 }
            New-BoostLabInstallersOperation -Type 'StopProcess' -Label 'Stop Firefox' -Parameters @{ Name = 'firefox' }
            New-BoostLabInstallersOperation -Type 'WriteFirefoxUserJs' -Label 'Disable Firefox hardware acceleration in user.js' -Parameters @{ ProfileRoot = '$env:APPDATA\Mozilla\Firefox\Profiles'; Content = 'user_pref("layers.acceleration.disabled", true);`nuser_pref("gfx.direct2d.disabled", true);' }
        ) -SideEffectFamilies @('Download', 'InstallerLaunch', 'Uninstall', 'ScheduledTaskRemoval', 'Registry', 'FileWrite', 'ProcessStop')

        New-BoostLabInstallersAppDescriptor -SourceMenuNumber 13 -AppId 'google-chrome' -DisplayName 'Google Chrome' -Artifacts @(
            New-BoostLabInstallersArtifact -Url 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi' -DestinationPath '$env:SystemRoot\Temp\Chrome.msi'
        ) -InstallerCommands @(
            New-BoostLabInstallersCommand -FilePath '$env:SystemRoot\Temp\Chrome.msi' -Arguments '/quiet' -Wait $true
        ) -Operations @(
            New-BoostLabInstallersOperation -Type 'Download' -Label 'Download Google Chrome enterprise installer' -Parameters @{ Url = 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi'; DestinationPath = '$env:SystemRoot\Temp\Chrome.msi' }
            New-BoostLabInstallersOperation -Type 'StartProcess' -Label 'Install Google Chrome quietly' -Parameters @{ FilePath = '$env:SystemRoot\Temp\Chrome.msi'; Arguments = '/quiet'; Wait = $true }
            New-BoostLabInstallersOperation -Type 'SetRegistryValue' -Label 'Force install uBlock Origin Lite in Chrome' -Parameters @{ Path = 'HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist'; Name = '1'; Type = 'String'; Value = 'ddkjiahejlhfcafbddmgiahcphecmpfh;https://clients2.google.com/service/update2/crx' }
            New-BoostLabInstallersOperation -Type 'SetRegistryValue' -Label 'Disable Chrome hardware acceleration' -Parameters @{ Path = 'HKLM:\SOFTWARE\Policies\Google\Chrome'; Name = 'HardwareAccelerationModeEnabled'; Type = 'DWord'; Value = 0 }
            New-BoostLabInstallersOperation -Type 'SetRegistryValue' -Label 'Disable Chrome background mode' -Parameters @{ Path = 'HKLM:\SOFTWARE\Policies\Google\Chrome'; Name = 'BackgroundModeEnabled'; Type = 'DWord'; Value = 0 }
            New-BoostLabInstallersOperation -Type 'SetRegistryValue' -Label 'Enable Chrome high efficiency policy' -Parameters @{ Path = 'HKLM:\SOFTWARE\Policies\Google\Chrome'; Name = 'HighEfficiencyModeEnabled'; Type = 'DWord'; Value = 1 }
            New-BoostLabInstallersOperation -Type 'RemoveActiveSetupByDefaultMatch' -Label 'Remove Chrome Active Setup entries' -Parameters @{ Path = 'HKLM:\Software\Microsoft\Active Setup\Installed Components'; Pattern = '*Chrome*' }
            New-BoostLabInstallersOperation -Type 'StopDeleteServicesByNameMatch' -Label 'Stop and delete Google services' -Parameters @{ Pattern = 'Google' }
            New-BoostLabInstallersOperation -Type 'RemoveScheduledTasksByNameLike' -Label 'Remove Google scheduled tasks' -Parameters @{ Pattern = '*Google*' }
        ) -SideEffectFamilies @('Download', 'InstallerLaunch', 'Registry', 'ActiveSetup', 'ServiceStopDelete', 'ScheduledTaskRemoval')

        New-BoostLabInstallersAppDescriptor -SourceMenuNumber 14 -AppId 'league-of-legends' -DisplayName 'League Of Legends' -Artifacts @(
            New-BoostLabInstallersArtifact -Url 'https://lol.secure.dyn.riotcdn.net/channels/public/x/installer/current/live.na.exe' -DestinationPath '$env:SystemRoot\Temp\League Of Legends.exe'
        ) -InstallerCommands @(
            New-BoostLabInstallersCommand -FilePath '$env:SystemRoot\Temp\League Of Legends.exe' -Arguments '--skip-to-install'
        ) -Operations @(
            New-BoostLabInstallersOperation -Type 'Download' -Label 'Download League Of Legends installer' -Parameters @{ Url = 'https://lol.secure.dyn.riotcdn.net/channels/public/x/installer/current/live.na.exe'; DestinationPath = '$env:SystemRoot\Temp\League Of Legends.exe' }
            New-BoostLabInstallersOperation -Type 'StartProcess' -Label 'Start League Of Legends installer' -Parameters @{ FilePath = '$env:SystemRoot\Temp\League Of Legends.exe'; Arguments = '--skip-to-install'; Wait = $false }
        ) -SideEffectFamilies @('Download', 'InstallerLaunch')

        New-BoostLabInstallersAppDescriptor -SourceMenuNumber 17 -AppId 'obs-studio' -DisplayName 'OBS Studio' -Artifacts @(
            New-BoostLabInstallersArtifact -Url 'https://cdn-fastly.obsproject.com/downloads/OBS-Studio-32.1.0-Windows-x64-Installer.exe' -DestinationPath '$env:SystemRoot\Temp\OBS Studio.exe'
        ) -InstallerCommands @(
            New-BoostLabInstallersCommand -FilePath '$env:SystemRoot\Temp\OBS Studio.exe' -Arguments '/S' -Wait $true
        ) -Operations @(
            New-BoostLabInstallersOperation -Type 'Download' -Label 'Download OBS Studio installer' -Parameters @{ Url = 'https://cdn-fastly.obsproject.com/downloads/OBS-Studio-32.1.0-Windows-x64-Installer.exe'; DestinationPath = '$env:SystemRoot\Temp\OBS Studio.exe' }
            New-BoostLabInstallersOperation -Type 'StartProcess' -Label 'Install OBS Studio silently' -Parameters @{ FilePath = '$env:SystemRoot\Temp\OBS Studio.exe'; Arguments = '/S'; Wait = $true }
        ) -SideEffectFamilies @('Download', 'InstallerLaunch')

        New-BoostLabInstallersAppDescriptor -SourceMenuNumber 20 -AppId 'rockstar-games' -DisplayName 'Rockstar Games' -Artifacts @(
            New-BoostLabInstallersArtifact -Url 'https://gamedownloads.rockstargames.com/public/installer/Rockstar-Games-Launcher.exe' -DestinationPath '$env:SystemRoot\Temp\Rockstar Games.exe'
        ) -InstallerCommands @(
            New-BoostLabInstallersCommand -FilePath '$env:SystemRoot\Temp\Rockstar Games.exe' -Arguments '/s /f' -Wait $true
        ) -Operations @(
            New-BoostLabInstallersOperation -Type 'Download' -Label 'Download Rockstar Games installer' -Parameters @{ Url = 'https://gamedownloads.rockstargames.com/public/installer/Rockstar-Games-Launcher.exe'; DestinationPath = '$env:SystemRoot\Temp\Rockstar Games.exe' }
            New-BoostLabInstallersOperation -Type 'StartProcess' -Label 'Install Rockstar Games silently' -Parameters @{ FilePath = '$env:SystemRoot\Temp\Rockstar Games.exe'; Arguments = '/s /f'; Wait = $true }
            New-BoostLabInstallersOperation -Type 'MoveItem' -Label 'Move Rockstar Start Menu shortcut' -Parameters @{ Path = '$env:AppData\Microsoft\Windows\Start Menu\Programs\Rockstar Games\Rockstar Games Launcher.lnk'; Destination = '$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Rockstar Games Launcher.lnk'; IgnoreMissing = $true }
            New-BoostLabInstallersOperation -Type 'RemoveItem' -Label 'Remove Rockstar user Start Menu folder' -Parameters @{ Path = '$env:AppData\Microsoft\Windows\Start Menu\Programs\Rockstar Games'; Recurse = $true; IgnoreMissing = $true }
        ) -SideEffectFamilies @('Download', 'InstallerLaunch', 'FileMove', 'Cleanup')

        New-BoostLabInstallersAppDescriptor -SourceMenuNumber 21 -AppId 'spotify' -DisplayName 'Spotify' -Artifacts @(
            New-BoostLabInstallersArtifact -Url 'https://download.scdn.co/SpotifySetup.exe' -DestinationPath '$tempDir\Spotify.exe'
        ) -InstallerCommands @(
            New-BoostLabInstallersCommand -FilePath 'explorer.exe' -Arguments '$tempDir\Spotify.exe'
        ) -Operations @(
            New-BoostLabInstallersOperation -Type 'WriteTextFile' -Label 'Write Spotify prefs' -Parameters @{ Path = '$env:APPDATA\Spotify\prefs'; Content = 'app.autostart-configured=true`napp.autostart-mode="off"`nui.hardware_acceleration=false' }
            New-BoostLabInstallersOperation -Type 'Download' -Label 'Download Spotify installer' -Parameters @{ Url = 'https://download.scdn.co/SpotifySetup.exe'; DestinationPath = '$tempDir\Spotify.exe' }
            New-BoostLabInstallersOperation -Type 'StartProcess' -Label 'Start Spotify installer through Explorer' -Parameters @{ FilePath = 'explorer.exe'; Arguments = '$tempDir\Spotify.exe'; Wait = $false }
        ) -SideEffectFamilies @('AppConfiguration', 'Download', 'InstallerLaunch')

        New-BoostLabInstallersAppDescriptor -SourceMenuNumber 22 -AppId 'steam' -DisplayName 'Steam' -Artifacts @(
            New-BoostLabInstallersArtifact -Url 'https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe' -DestinationPath '$env:SystemRoot\Temp\Steam.exe'
        ) -InstallerCommands @(
            New-BoostLabInstallersCommand -FilePath '$env:SystemRoot\Temp\Steam.exe' -Arguments '/S' -Wait $true
        ) -Operations @(
            New-BoostLabInstallersOperation -Type 'Download' -Label 'Download Steam installer' -Parameters @{ Url = 'https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe'; DestinationPath = '$env:SystemRoot\Temp\Steam.exe' }
            New-BoostLabInstallersOperation -Type 'StartProcess' -Label 'Install Steam silently' -Parameters @{ FilePath = '$env:SystemRoot\Temp\Steam.exe'; Arguments = '/S'; Wait = $true }
            New-BoostLabInstallersOperation -Type 'MoveItem' -Label 'Move Steam Start Menu shortcut' -Parameters @{ Path = '$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Steam\Steam.lnk'; Destination = '$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Steam.lnk'; IgnoreMissing = $true }
            New-BoostLabInstallersOperation -Type 'RemoveItem' -Label 'Remove Steam Start Menu folder' -Parameters @{ Path = '$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Steam'; Recurse = $true; IgnoreMissing = $true }
            New-BoostLabInstallersOperation -Type 'RemoveRegistryValue' -Label 'Remove Steam startup value' -Parameters @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'; Name = 'Steam'; IgnoreMissing = $true }
        ) -SideEffectFamilies @('Download', 'InstallerLaunch', 'FileMove', 'Cleanup', 'StartupRegistryCleanup')

        New-BoostLabInstallersAppDescriptor -SourceMenuNumber 23 -AppId 'ubisoft-connect' -DisplayName 'Ubisoft Connect' -Artifacts @(
            New-BoostLabInstallersArtifact -Url 'https://static3.cdn.ubi.com/orbit/launcher_installer/UbisoftConnectInstaller.exe' -DestinationPath '$env:SystemRoot\Temp\Ubisoft Connect.exe'
        ) -InstallerCommands @(
            New-BoostLabInstallersCommand -FilePath '$env:SystemRoot\Temp\Ubisoft Connect.exe' -Arguments '/S' -Wait $true
        ) -Operations @(
            New-BoostLabInstallersOperation -Type 'Download' -Label 'Download Ubisoft Connect installer' -Parameters @{ Url = 'https://static3.cdn.ubi.com/orbit/launcher_installer/UbisoftConnectInstaller.exe'; DestinationPath = '$env:SystemRoot\Temp\Ubisoft Connect.exe' }
            New-BoostLabInstallersOperation -Type 'StartProcess' -Label 'Install Ubisoft Connect silently' -Parameters @{ FilePath = '$env:SystemRoot\Temp\Ubisoft Connect.exe'; Arguments = '/S'; Wait = $true }
            New-BoostLabInstallersOperation -Type 'MoveItem' -Label 'Move Ubisoft Connect Start Menu shortcut' -Parameters @{ Path = '$env:AppData\Microsoft\Windows\Start Menu\Programs\Ubisoft\Ubisoft Connect\Ubisoft Connect.lnk'; Destination = '$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Ubisoft Connect.lnk'; IgnoreMissing = $true }
            New-BoostLabInstallersOperation -Type 'RemoveItem' -Label 'Remove Ubisoft user Start Menu folder' -Parameters @{ Path = '$env:AppData\Microsoft\Windows\Start Menu\Programs\Ubisoft'; Recurse = $true; IgnoreMissing = $true }
        ) -SideEffectFamilies @('Download', 'InstallerLaunch', 'FileMove', 'Cleanup')

        New-BoostLabInstallersAppDescriptor -SourceMenuNumber 24 -AppId 'valorant' -DisplayName 'Valorant' -Artifacts @(
            New-BoostLabInstallersArtifact -Url 'https://valorant.secure.dyn.riotcdn.net/channels/public/x/installer/current/live.live.ap.exe' -DestinationPath '$env:SystemRoot\Temp\Valorant.exe'
        ) -InstallerCommands @(
            New-BoostLabInstallersCommand -FilePath '$env:SystemRoot\Temp\Valorant.exe' -Arguments '--skip-to-install'
        ) -Operations @(
            New-BoostLabInstallersOperation -Type 'Download' -Label 'Download Valorant installer' -Parameters @{ Url = 'https://valorant.secure.dyn.riotcdn.net/channels/public/x/installer/current/live.live.ap.exe'; DestinationPath = '$env:SystemRoot\Temp\Valorant.exe' }
            New-BoostLabInstallersOperation -Type 'StartProcess' -Label 'Start Valorant installer' -Parameters @{ FilePath = '$env:SystemRoot\Temp\Valorant.exe'; Arguments = '--skip-to-install'; Wait = $false }
        ) -SideEffectFamilies @('Download', 'InstallerLaunch')
    )
}

function Get-BoostLabInstallersSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $projectRoot ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabInstallersSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabInstallersSourcePath
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $sourceVerificationModulePath = Join-Path $projectRoot 'core\SourceVerification.psm1'
    if (-not (Get-Command -Name 'Test-BoostLabSourceChecksum' -ErrorAction SilentlyContinue)) {
        Import-Module -Name $sourceVerificationModulePath -Scope Local -Force -ErrorAction Stop
    }

    $verification = Test-BoostLabSourceChecksum -LiteralPath $sourcePath -ExpectedSha256 $script:BoostLabExpectedSourceHash -ExpectedCanonicalSha256 $script:BoostLabExpectedCanonicalSourceHash

    [pscustomobject]@{
        SourcePath                = $sourcePath
        SourceRelativePath        = $script:BoostLabSourceRelativePath
        Exists                    = [bool]$verification.Exists
        ExpectedSha256            = $script:BoostLabExpectedSourceHash
        DetectedSha256            = [string]$verification.DetectedSha256
        ExpectedCanonicalSha256   = $script:BoostLabExpectedCanonicalSourceHash
        DetectedCanonicalSha256   = [string]$verification.DetectedCanonicalSha256
        ChecksumStatus            = [string]$verification.ChecksumStatus
        RawChecksumStatus         = [string]$verification.RawChecksumStatus
        CanonicalChecksumStatus   = [string]$verification.CanonicalChecksumStatus
        VerificationMode          = [string]$verification.VerificationMode
    }
}

function Test-BoostLabInstallersRemovedMenuMapping {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $expected = @{
        9 = 'Escape From Tarkov'
        11 = 'Frame View'
        12 = 'GOG launcher'
        15 = 'Notepad ++'
        16 = 'Nvidia App'
        18 = 'Onboard Memory Manager'
        19 = 'Pot Player'
    }
    $menu = Get-BoostLabInstallersFullSourceMenu
    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($number in $expected.Keys) {
        $entry = @($menu | Where-Object { [int]$_.SourceMenuNumber -eq [int]$number }) | Select-Object -First 1
        if ($null -eq $entry -or [string]$entry.DisplayName -ne [string]$expected[$number]) {
            $actual = if ($null -eq $entry) { '<missing>' } else { [string]$entry.DisplayName }
            $errors.Add("Menu $number expected '$($expected[$number])' but found '$actual'.")
        }
    }

    [pscustomobject]@{
        IsValid = $errors.Count -eq 0
        Errors  = $errors.ToArray()
    }
}

function New-BoostLabInstallersVerification {
    param(
        [Parameter(Mandatory)][string]$Action,
        [Parameter(Mandatory)][string]$Status,
        [Parameter(Mandatory)][object]$ExpectedState,
        [Parameter(Mandatory)][object]$DetectedState,
        [object[]]$Checks = @(),
        [Parameter(Mandatory)][string]$Message
    )

    New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $Action `
        -Status $Status `
        -ExpectedState $ExpectedState `
        -DetectedState $DetectedState `
        -Checks $Checks `
        -Message $Message
}

function New-BoostLabInstallersResult {
    param(
        [Parameter(Mandatory)][bool]$Success,
        [Parameter(Mandatory)][string]$Action,
        [Parameter(Mandatory)][string]$Status,
        [Parameter(Mandatory)][string]$CommandStatus,
        [Parameter(Mandatory)][string]$VerificationStatus,
        [Parameter(Mandatory)][string]$Message,
        [AllowNull()][object]$Data = $null,
        [AllowNull()][object]$VerificationResult = $null,
        [string[]]$Warnings = @(),
        [string[]]$Errors = @(),
        [bool]$Cancelled = $false,
        [bool]$ChangesExecuted = $false
    )

    [pscustomobject]@{
        Success            = $Success
        ToolId             = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle          = [string]$script:BoostLabToolMetadata['Title']
        Action             = $Action
        Status             = $Status
        CommandStatus      = $CommandStatus
        VerificationStatus = $VerificationStatus
        Message            = $Message
        RestartRequired    = $false
        Cancelled          = $Cancelled
        ChangesExecuted    = $ChangesExecuted
        Timestamp          = Get-Date
        Data               = $Data
        VerificationResult = $VerificationResult
        Warnings           = @($Warnings)
        Errors             = @($Errors)
    }
}

function Get-BoostLabInstallersRiskWarnings {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'Original Ultimate source requires Administrator and internet access.'
        'The selected retained app downloads vendor-defined artifacts and runs source-defined installers/helpers.'
        'The selected retained app may write app configuration, browser policy, startup values, shortcuts, services, scheduled tasks, or cleanup targets exactly as described by its source-derived descriptor.'
        'Removed Yazan-excluded menu entries are hidden and unavailable.'
        'Installers runs exactly one selected app per Apply. To install another app, run Installers again and select another app.'
    )
}

function Get-BoostLabInstallersAnalysis {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabInstallersSourceStatus
    $catalog = @(Get-BoostLabInstallersCatalog)
    $fullMenu = @(Get-BoostLabInstallersFullSourceMenu)
    $mapping = Test-BoostLabInstallersRemovedMenuMapping
    $artifactCount = @($catalog | ForEach-Object { $_.Artifacts }).Count

    [pscustomobject]@{
        Mode                         = 'SingleSelectedAppInstall'
        AutoMode                     = 'YazanScopedSingleSelectedApp'
        Source                       = $sourceStatus
        RemovedMenuMappingValid      = [bool]$mapping.IsValid
        RemovedMenuMappingErrors     = @($mapping.Errors)
        SourceMenuMapping            = $fullMenu
        YazanRemovedAppMenuEntries   = @($script:BoostLabInstallersRemovedMenuEntries)
        RetainedVisibleCatalog       = $catalog
        RetainedAppCount             = $catalog.Count
        RetainedArtifactCount        = $artifactCount
        SelectionModel               = 'SingleSelect'
        QueueOrder                   = 'Not applicable; exactly one retained app runs per Apply.'
        SourceBehaviorSummary        = @(
            'Checks for Administrator rights and internet connectivity.'
            'Presents 23 app installer choices plus Exit.'
            'Downloads source-defined installer artifacts for the selected app.'
            'Runs source-defined installers/helpers with source-defined arguments.'
            'Performs source-defined post-install configuration, policy, shortcut, service, task, startup, uninstall, and cleanup side effects for the selected app.'
            'Does not define a safe global Default or captured-state Restore model for all installed apps and side effects.'
        )
        Warnings                     = @(Get-BoostLabInstallersRiskWarnings)
        NoMutationOccurred           = $true
        NoDownloadOccurred           = $true
        NoInstallerExecutionOccurred = $true
        NoExternalProcessStarted     = $true
    }
}

function Resolve-BoostLabInstallersPathExpression {
    param([AllowNull()][string]$Expression)

    if ([string]::IsNullOrWhiteSpace($Expression)) {
        return ''
    }

    $tempDir = [System.IO.Path]::GetTempPath().TrimEnd('\')
    $desktop = (New-Object -ComObject Shell.Application).Namespace('shell:Desktop').Self.Path
    return $Expression.
        Replace('$tempDir', $tempDir).
        Replace('$Desktop', $desktop).
        Replace('$env:SystemRoot', $env:SystemRoot).
        Replace('$env:SystemDrive', $env:SystemDrive).
        Replace('$env:ProgramData', $env:ProgramData).
        Replace('$env:APPDATA', $env:APPDATA).
        Replace('$env:AppData', $env:APPDATA)
}

function Get-BoostLabInstallersOfficialArtifactIdForUrl {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Url
    )

    $map = @{
        'https://discord.com/api/downloads/distributions/app/installers/latest?channel=stable&platform=win&arch=x64' = 'installers-discord'
        'https://www.roblox.com/download/client?os=win' = 'installers-roblox'
        'https://www.7-zip.org/a/7z2301-x64.exe' = 'installers-seven-zip'
        'https://downloader.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe' = 'installers-battle-net'
        'https://brave-browser-downloads.s3.brave.com/latest/brave_installer-x64.exe' = 'installers-brave'
        'https://origin-a.akamaihd.net/EA-Desktop-Client-Download/installer-releases/EAappInstaller.exe' = 'installers-electronic-arts'
        'https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi' = 'installers-epic-games'
        'https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US' = 'installers-firefox'
        'https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi' = 'installers-ublock-origin-xpi'
        'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi' = 'installers-google-chrome'
        'https://lol.secure.dyn.riotcdn.net/channels/public/x/installer/current/live.na.exe' = 'installers-league-of-legends'
        'https://cdn-fastly.obsproject.com/downloads/OBS-Studio-32.1.0-Windows-x64-Installer.exe' = 'installers-obs-studio'
        'https://gamedownloads.rockstargames.com/public/installer/Rockstar-Games-Launcher.exe' = 'installers-rockstar-games'
        'https://download.scdn.co/SpotifySetup.exe' = 'installers-spotify'
        'https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe' = 'installers-steam'
        'https://static3.cdn.ubi.com/orbit/launcher_installer/UbisoftConnectInstaller.exe' = 'installers-ubisoft-connect'
        'https://valorant.secure.dyn.riotcdn.net/channels/public/x/installer/current/live.live.ap.exe' = 'installers-valorant'
    }

    if (-not $map.ContainsKey($Url)) {
        throw "Installers download URL is not in the official vendor runtime policy map: $Url"
    }

    return [string]$map[$Url]
}

function Get-BoostLabInstallersPropertyValue {
    param(
        [AllowNull()][object]$InputObject,
        [Parameter(Mandatory)][string]$Name
    )

    if ($null -eq $InputObject) {
        return $null
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function Convert-BoostLabInstallersExecutablePathCandidate {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return ''
    }

    $text = ([string]$Value).Trim()
    if ([string]::IsNullOrWhiteSpace($text)) {
        return ''
    }

    $quotedMatch = [regex]::Match($text, '^"([^"]+)"')
    if ($quotedMatch.Success) {
        return [string]$quotedMatch.Groups[1].Value
    }

    return ($text -replace ',\s*\d+\s*$', '').Trim([char[]]@('"', ' '))
}

function Add-BoostLabInstallersEpicLauncherCandidate {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$Candidates,
        [Parameter(Mandatory)][hashtable]$Seen,
        [AllowNull()][string]$Path,
        [Parameter(Mandatory)][string]$Source,
        [string]$Evidence = ''
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return
    }

    $normalizedPath = [string]$Path
    if ([System.IO.Path]::GetFileName($normalizedPath) -ne 'EpicGamesLauncher.exe') {
        return
    }

    $key = $normalizedPath.ToLowerInvariant()
    if ($Seen.ContainsKey($key)) {
        return
    }

    $Seen[$key] = $true
    $Candidates.Add([pscustomobject]@{
        Path = $normalizedPath
        Source = $Source
        Evidence = $Evidence
    })
}

function Add-BoostLabInstallersEpicLauncherDirectoryCandidates {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$Candidates,
        [Parameter(Mandatory)][hashtable]$Seen,
        [AllowNull()][string]$Directory,
        [Parameter(Mandatory)][string]$Source,
        [string]$Evidence = ''
    )

    if ([string]::IsNullOrWhiteSpace($Directory)) {
        return
    }

    $trimmedDirectory = ([string]$Directory).Trim([char[]]@('"', ' ', '\'))
    if ([string]::IsNullOrWhiteSpace($trimmedDirectory)) {
        return
    }

    Add-BoostLabInstallersEpicLauncherCandidate -Candidates $Candidates -Seen $Seen -Path (Join-Path $trimmedDirectory 'EpicGamesLauncher.exe') -Source $Source -Evidence $Evidence
    Add-BoostLabInstallersEpicLauncherCandidate -Candidates $Candidates -Seen $Seen -Path (Join-Path $trimmedDirectory 'Portal\Binaries\Win64\EpicGamesLauncher.exe') -Source $Source -Evidence $Evidence
    Add-BoostLabInstallersEpicLauncherCandidate -Candidates $Candidates -Seen $Seen -Path (Join-Path $trimmedDirectory 'Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe') -Source $Source -Evidence $Evidence
}

function Get-BoostLabInstallersEpicLauncherCandidates {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [Parameter(Mandatory)][string]$SourceDefinedPathExpression,

        [scriptblock]$UninstallEntryEnumerator = {
            @(
                Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue
                Get-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue
            )
        },

        [scriptblock]$ShortcutEnumerator = {
            $roots = @(
                (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs')
                (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs')
            )
            foreach ($root in $roots) {
                if (-not [string]::IsNullOrWhiteSpace($root) -and (Test-Path -LiteralPath $root)) {
                    Get-ChildItem -LiteralPath $root -Filter '*.lnk' -Recurse -ErrorAction SilentlyContinue |
                        Where-Object { $_.Name -like '*Epic*' }
                }
            }
        },

        [scriptblock]$ShortcutTargetResolver = {
            param([object]$Shortcut)
            $shell = New-Object -ComObject WScript.Shell
            $link = $shell.CreateShortcut([string]$Shortcut.FullName)
            [string]$link.TargetPath
        }
    )

    $candidates = [System.Collections.Generic.List[object]]::new()
    $seen = @{}
    $sourceDefinedPath = Resolve-BoostLabInstallersPathExpression $SourceDefinedPathExpression
    Add-BoostLabInstallersEpicLauncherCandidate -Candidates $candidates -Seen $seen -Path $sourceDefinedPath -Source 'SourceDefinedPath' -Evidence $SourceDefinedPathExpression

    $systemDrive = [Environment]::GetEnvironmentVariable('SystemDrive')
    if ([string]::IsNullOrWhiteSpace($systemDrive)) {
        $systemDrive = $env:SystemDrive
    }
    $programFiles = [Environment]::GetEnvironmentVariable('ProgramFiles')
    $programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')

    if (-not [string]::IsNullOrWhiteSpace($systemDrive)) {
        Add-BoostLabInstallersEpicLauncherDirectoryCandidates -Candidates $candidates -Seen $seen -Directory (Join-Path $systemDrive 'Program Files\Epic Games') -Source 'SystemDriveProgramFiles' -Evidence '%SystemDrive%\Program Files'
        Add-BoostLabInstallersEpicLauncherDirectoryCandidates -Candidates $candidates -Seen $seen -Directory (Join-Path $systemDrive 'Program Files (x86)\Epic Games') -Source 'SystemDriveProgramFilesX86' -Evidence '%SystemDrive%\Program Files (x86)'
    }
    if (-not [string]::IsNullOrWhiteSpace($programFiles)) {
        Add-BoostLabInstallersEpicLauncherDirectoryCandidates -Candidates $candidates -Seen $seen -Directory (Join-Path $programFiles 'Epic Games') -Source 'ProgramFiles' -Evidence '%ProgramFiles%'
    }
    if (-not [string]::IsNullOrWhiteSpace($programFilesX86)) {
        Add-BoostLabInstallersEpicLauncherDirectoryCandidates -Candidates $candidates -Seen $seen -Directory (Join-Path $programFilesX86 'Epic Games') -Source 'ProgramFilesX86' -Evidence '%ProgramFiles(x86)%'
    }

    try {
        foreach ($entry in @(& $UninstallEntryEnumerator)) {
            $displayName = Get-BoostLabInstallersPropertyValue -InputObject $entry -Name 'DisplayName'
            if ([string]::IsNullOrWhiteSpace([string]$displayName) -or [string]$displayName -notlike '*Epic Games Launcher*') {
                continue
            }

            $entryIdentity = Get-BoostLabInstallersPropertyValue -InputObject $entry -Name 'PSPath'
            if ([string]::IsNullOrWhiteSpace([string]$entryIdentity)) {
                $entryIdentity = Get-BoostLabInstallersPropertyValue -InputObject $entry -Name 'PSChildName'
            }

            $installLocation = Get-BoostLabInstallersPropertyValue -InputObject $entry -Name 'InstallLocation'
            Add-BoostLabInstallersEpicLauncherDirectoryCandidates -Candidates $candidates -Seen $seen -Directory ([string]$installLocation) -Source 'RegistryInstallLocation' -Evidence ([string]$entryIdentity)

            $displayIcon = Convert-BoostLabInstallersExecutablePathCandidate (Get-BoostLabInstallersPropertyValue -InputObject $entry -Name 'DisplayIcon')
            Add-BoostLabInstallersEpicLauncherCandidate -Candidates $candidates -Seen $seen -Path $displayIcon -Source 'RegistryDisplayIcon' -Evidence ([string]$entryIdentity)
        }
    }
    catch {
        $candidates.Add([pscustomobject]@{
            Path = ''
            Source = 'RegistryEnumerationError'
            Evidence = $_.Exception.Message
        })
    }

    try {
        foreach ($shortcut in @(& $ShortcutEnumerator)) {
            $shortcutName = Get-BoostLabInstallersPropertyValue -InputObject $shortcut -Name 'Name'
            $shortcutPath = Get-BoostLabInstallersPropertyValue -InputObject $shortcut -Name 'FullName'
            if ([string]::IsNullOrWhiteSpace([string]$shortcutName) -or [string]$shortcutName -notlike '*Epic*') {
                continue
            }

            $targetPath = & $ShortcutTargetResolver $shortcut
            Add-BoostLabInstallersEpicLauncherCandidate -Candidates $candidates -Seen $seen -Path ([string]$targetPath) -Source 'StartMenuShortcut' -Evidence ([string]$shortcutPath)
        }
    }
    catch {
        $candidates.Add([pscustomobject]@{
            Path = ''
            Source = 'ShortcutEnumerationError'
            Evidence = $_.Exception.Message
        })
    }

    $candidates.ToArray()
}

function Resolve-BoostLabInstallersEpicLauncher {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$SourceDefinedPathExpression,
        [int]$MaxWaitSeconds = 45,
        [int]$PollIntervalSeconds = 3,
        [scriptblock]$PathTester = {
            param([string]$Path)
            Test-Path -LiteralPath $Path -PathType Leaf
        },
        [scriptblock]$Sleeper = {
            param([int]$Seconds)
            Start-Sleep -Seconds $Seconds
        },
        [scriptblock]$UninstallEntryEnumerator,
        [scriptblock]$ShortcutEnumerator,
        [scriptblock]$ShortcutTargetResolver
    )

    $elapsed = 0
    $attempts = 0
    $checkedPaths = [System.Collections.Generic.List[object]]::new()
    $registryCandidates = [System.Collections.Generic.List[object]]::new()
    $shortcutCandidates = [System.Collections.Generic.List[object]]::new()
    $lastCandidates = @()

    do {
        $attempts++
        $candidateParameters = @{
            SourceDefinedPathExpression = $SourceDefinedPathExpression
        }
        if ($null -ne $UninstallEntryEnumerator) {
            $candidateParameters['UninstallEntryEnumerator'] = $UninstallEntryEnumerator
        }
        if ($null -ne $ShortcutEnumerator) {
            $candidateParameters['ShortcutEnumerator'] = $ShortcutEnumerator
        }
        if ($null -ne $ShortcutTargetResolver) {
            $candidateParameters['ShortcutTargetResolver'] = $ShortcutTargetResolver
        }

        $lastCandidates = @(Get-BoostLabInstallersEpicLauncherCandidates @candidateParameters)
        foreach ($candidate in $lastCandidates) {
            if ([string]$candidate.Source -like 'Registry*') {
                $registryCandidates.Add($candidate)
            }
            if ([string]$candidate.Source -eq 'StartMenuShortcut' -or [string]$candidate.Source -eq 'ShortcutEnumerationError') {
                $shortcutCandidates.Add($candidate)
            }
            if ([string]::IsNullOrWhiteSpace([string]$candidate.Path)) {
                continue
            }
            $checkedPaths.Add($candidate)
            if (& $PathTester ([string]$candidate.Path)) {
                return [pscustomobject]@{
                    Success = $true
                    Status = 'Found'
                    ResolvedPath = [string]$candidate.Path
                    SourceDefinedPath = Resolve-BoostLabInstallersPathExpression $SourceDefinedPathExpression
                    SourceDefinedPathExpression = $SourceDefinedPathExpression
                    MatchedSource = [string]$candidate.Source
                    Attempts = $attempts
                    ElapsedWaitSeconds = $elapsed
                    MaxWaitSeconds = $MaxWaitSeconds
                    PollIntervalSeconds = $PollIntervalSeconds
                    CheckedPaths = $checkedPaths.ToArray()
                    RegistryCandidates = $registryCandidates.ToArray()
                    ShortcutCandidates = $shortcutCandidates.ToArray()
                    Message = "Epic Games launcher found at $($candidate.Path)."
                }
            }
        }

        if ($elapsed -ge $MaxWaitSeconds) {
            break
        }

        $sleepSeconds = [Math]::Min([Math]::Max(1, $PollIntervalSeconds), [Math]::Max(1, $MaxWaitSeconds - $elapsed))
        & $Sleeper $sleepSeconds
        $elapsed += $sleepSeconds
    } while ($true)

    [pscustomobject]@{
        Success = $false
        Status = 'EpicLauncherNotFoundAfterInstall'
        ResolvedPath = ''
        SourceDefinedPath = Resolve-BoostLabInstallersPathExpression $SourceDefinedPathExpression
        SourceDefinedPathExpression = $SourceDefinedPathExpression
        MatchedSource = ''
        Attempts = $attempts
        ElapsedWaitSeconds = $elapsed
        MaxWaitSeconds = $MaxWaitSeconds
        PollIntervalSeconds = $PollIntervalSeconds
        CheckedPaths = $checkedPaths.ToArray()
        RegistryCandidates = $registryCandidates.ToArray()
        ShortcutCandidates = $shortcutCandidates.ToArray()
        Message = 'EpicLauncherNotFoundAfterInstall. EpicGamesLauncher.exe was not found after the bounded post-install discovery wait.'
    }
}

function Invoke-BoostLabInstallersEpicLauncher {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$SourceDefinedPathExpression,
        [string]$Arguments = '',
        [bool]$Wait = $true,
        [int]$MaxWaitSeconds = 45,
        [int]$PollIntervalSeconds = 3,
        [scriptblock]$PathTester,
        [scriptblock]$Sleeper,
        [scriptblock]$UninstallEntryEnumerator,
        [scriptblock]$ShortcutEnumerator,
        [scriptblock]$ShortcutTargetResolver,
        [scriptblock]$Launcher = {
            param([string]$FilePath, [string]$ArgumentList, [bool]$ShouldWait)
            $startParams = @{
                FilePath = $FilePath
                ErrorAction = 'Stop'
            }
            if (-not [string]::IsNullOrWhiteSpace($ArgumentList)) {
                $startParams['ArgumentList'] = $ArgumentList
            }
            if ($ShouldWait) {
                $startParams['Wait'] = $true
            }
            Start-Process @startParams
        }
    )

    $resolveParameters = @{
        SourceDefinedPathExpression = $SourceDefinedPathExpression
        MaxWaitSeconds = $MaxWaitSeconds
        PollIntervalSeconds = $PollIntervalSeconds
    }
    if ($null -ne $PathTester) {
        $resolveParameters['PathTester'] = $PathTester
    }
    if ($null -ne $Sleeper) {
        $resolveParameters['Sleeper'] = $Sleeper
    }
    if ($null -ne $UninstallEntryEnumerator) {
        $resolveParameters['UninstallEntryEnumerator'] = $UninstallEntryEnumerator
    }
    if ($null -ne $ShortcutEnumerator) {
        $resolveParameters['ShortcutEnumerator'] = $ShortcutEnumerator
    }
    if ($null -ne $ShortcutTargetResolver) {
        $resolveParameters['ShortcutTargetResolver'] = $ShortcutTargetResolver
    }

    $resolution = Resolve-BoostLabInstallersEpicLauncher @resolveParameters
    if (-not [bool]$resolution.Success) {
        return [pscustomobject]@{
            Success = $false
            Status = 'EpicLauncherNotFoundAfterInstall'
            Message = [string]$resolution.Message
            Resolution = $resolution
            LaunchedPath = ''
        }
    }

    try {
        & $Launcher ([string]$resolution.ResolvedPath) $Arguments $Wait
        [pscustomobject]@{
            Success = $true
            Status = 'Launched'
            Message = "Launched Epic Games for update/EOS install from $($resolution.ResolvedPath)."
            Resolution = $resolution
            LaunchedPath = [string]$resolution.ResolvedPath
        }
    }
    catch {
        [pscustomobject]@{
            Success = $false
            Status = 'LaunchFailed'
            Message = "Epic Games launcher was found but failed to launch: $($_.Exception.Message)"
            Resolution = $resolution
            LaunchedPath = [string]$resolution.ResolvedPath
        }
    }
}

function Invoke-BoostLabInstallersActiveSetupDefaultMatchRemoval {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Pattern,

        [scriptblock]$KeyEnumerator = {
            param([string]$TargetPath)
            if (Test-Path -LiteralPath $TargetPath) {
                Get-ChildItem -LiteralPath $TargetPath -ErrorAction Stop
            }
        },

        [scriptblock]$DefaultValueReader = {
            param([object]$Key)
            $Key.GetValue('', $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        },

        [scriptblock]$KeyRemover = {
            param([object]$Key)
            Remove-Item -LiteralPath ([string]$Key.PSPath) -Force -ErrorAction Stop
        }
    )

    $inspected = [System.Collections.Generic.List[string]]::new()
    $matched = [System.Collections.Generic.List[string]]::new()
    $removed = [System.Collections.Generic.List[string]]::new()
    $missingDefault = [System.Collections.Generic.List[string]]::new()
    $noMatch = [System.Collections.Generic.List[string]]::new()
    $failures = [System.Collections.Generic.List[string]]::new()

    try {
        $keys = @(& $KeyEnumerator $Path)
    }
    catch {
        $failures.Add("Failed to enumerate Active Setup keys at $Path`: $($_.Exception.Message)")
        $keys = @()
    }

    foreach ($key in @($keys)) {
        $keyPath = if ($null -ne $key -and $null -ne $key.PSObject.Properties['PSPath']) {
            [string]$key.PSPath
        }
        elseif ($null -ne $key -and $null -ne $key.PSObject.Properties['Name']) {
            [string]$key.Name
        }
        else {
            [string]$key
        }
        $inspected.Add($keyPath)

        try {
            $defaultValue = & $DefaultValueReader $key
        }
        catch {
            $failures.Add("Failed to read Active Setup default value for $keyPath`: $($_.Exception.Message)")
            continue
        }

        if ($null -eq $defaultValue) {
            $missingDefault.Add($keyPath)
            continue
        }

        if ([string]$defaultValue -notlike $Pattern) {
            $noMatch.Add($keyPath)
            continue
        }

        $matched.Add($keyPath)
        try {
            & $KeyRemover $key
            $removed.Add($keyPath)
        }
        catch {
            $failures.Add("Failed to remove Active Setup key $keyPath`: $($_.Exception.Message)")
        }
    }

    [pscustomobject]@{
        Success = ($failures.Count -eq 0)
        Path = $Path
        Pattern = $Pattern
        InspectedCount = $inspected.Count
        MatchedCount = $matched.Count
        RemovedCount = $removed.Count
        MissingDefaultCount = $missingDefault.Count
        NoMatchCount = $noMatch.Count
        FailureCount = $failures.Count
        InspectedKeys = $inspected.ToArray()
        MatchedKeys = $matched.ToArray()
        RemovedKeys = $removed.ToArray()
        MissingDefaultKeys = $missingDefault.ToArray()
        NoMatchKeys = $noMatch.ToArray()
        Failures = $failures.ToArray()
    }
}

function Invoke-BoostLabInstallersDisplayNameUninstall {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$RegistryPath,

        [Parameter(Mandatory)]
        [string]$DisplayNameLike,

        [Parameter(Mandatory)]
        [string]$Arguments,

        [scriptblock]$EntryEnumerator = {
            param([string]$TargetPath)
            Get-ItemProperty -Path $TargetPath -ErrorAction Stop
        },

        [scriptblock]$Uninstaller = {
            param([object]$Entry, [string]$ArgumentList)
            Start-Process -FilePath 'msiexec.exe' -ArgumentList $ArgumentList -Wait -NoNewWindow -ErrorAction Stop
        }
    )

    $inspected = [System.Collections.Generic.List[string]]::new()
    $matched = [System.Collections.Generic.List[string]]::new()
    $missingDisplayName = [System.Collections.Generic.List[string]]::new()
    $noMatch = [System.Collections.Generic.List[string]]::new()
    $uninstallSucceeded = [System.Collections.Generic.List[string]]::new()
    $failures = [System.Collections.Generic.List[string]]::new()
    $uninstallAttempted = 0

    try {
        $entries = @(& $EntryEnumerator $RegistryPath)
    }
    catch {
        $failures.Add("Failed to enumerate uninstall registry entries at $RegistryPath`: $($_.Exception.Message)")
        $entries = @()
    }

    foreach ($entry in @($entries)) {
        $entryPath = if ($null -ne $entry -and $null -ne $entry.PSObject.Properties['PSPath']) {
            [string]$entry.PSPath
        }
        elseif ($null -ne $entry -and $null -ne $entry.PSObject.Properties['Name']) {
            [string]$entry.Name
        }
        elseif ($null -ne $entry -and $null -ne $entry.PSObject.Properties['PSChildName']) {
            [string]$entry.PSChildName
        }
        else {
            [string]$entry
        }
        $inspected.Add($entryPath)

        $displayNameProperty = if ($null -ne $entry) { $entry.PSObject.Properties['DisplayName'] } else { $null }
        if ($null -eq $displayNameProperty -or [string]::IsNullOrWhiteSpace([string]$displayNameProperty.Value)) {
            $missingDisplayName.Add($entryPath)
            continue
        }

        $displayName = [string]$displayNameProperty.Value
        if ($displayName -notlike $DisplayNameLike) {
            $noMatch.Add("$entryPath [$displayName]")
            continue
        }

        $matched.Add("$entryPath [$displayName]")
        $childNameProperty = $entry.PSObject.Properties['PSChildName']
        if ($null -eq $childNameProperty -or [string]::IsNullOrWhiteSpace([string]$childNameProperty.Value)) {
            $failures.Add("Matched uninstall entry $entryPath [$displayName] did not expose PSChildName for the source-defined uninstall command.")
            continue
        }

        $uninstallAttempted++
        $argumentList = [string]::Format($Arguments, [string]$childNameProperty.Value)
        try {
            & $Uninstaller $entry $argumentList
            $uninstallSucceeded.Add("$entryPath [$displayName]")
        }
        catch {
            $failures.Add("Failed to uninstall $entryPath [$displayName]: $($_.Exception.Message)")
        }
    }

    [pscustomobject]@{
        Success = ($failures.Count -eq 0)
        RegistryPath = $RegistryPath
        DisplayNameLike = $DisplayNameLike
        InspectedCount = $inspected.Count
        MissingDisplayNameCount = $missingDisplayName.Count
        NoMatchCount = $noMatch.Count
        MatchedCount = $matched.Count
        UninstallAttemptedCount = $uninstallAttempted
        UninstallSucceededCount = $uninstallSucceeded.Count
        FailureCount = $failures.Count
        InspectedEntries = $inspected.ToArray()
        MissingDisplayNameEntries = $missingDisplayName.ToArray()
        NoMatchEntries = $noMatch.ToArray()
        MatchedEntries = $matched.ToArray()
        UninstallSucceededEntries = $uninstallSucceeded.ToArray()
        FailureEntries = $failures.ToArray()
        MissingDisplayNameSamples = @($missingDisplayName.ToArray() | Select-Object -First 10)
        NoMatchSamples = @($noMatch.ToArray() | Select-Object -First 10)
        MatchedSamples = @($matched.ToArray() | Select-Object -First 10)
        FailureSamples = @($failures.ToArray() | Select-Object -First 10)
    }
}

function Invoke-BoostLabInstallersOperation {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][object]$Operation,
        [Parameter(Mandatory)][object]$App
    )

    $parameters = $Operation.Parameters
    $operationDetails = $null
    try {
        switch ([string]$Operation.Type) {
            'Download' {
                $destination = Resolve-BoostLabInstallersPathExpression ([string]$parameters['DestinationPath'])
                $parent = Split-Path -Parent $destination
                if (-not [string]::IsNullOrWhiteSpace($parent)) {
                    New-Item -Path $parent -ItemType Directory -Force | Out-Null
                }
                $url = [string]$parameters['Url']
                $artifactId = Get-BoostLabInstallersOfficialArtifactIdForUrl -Url $url
                Invoke-BoostLabOfficialVendorDownload `
                    -ArtifactId $artifactId `
                    -SourceUrl $url `
                    -Destination $destination | Out-Null
            }
            'StartProcess' {
                $filePath = Resolve-BoostLabInstallersPathExpression ([string]$parameters['FilePath'])
                if ([bool]($parameters['IgnoreMissing']) -and -not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
                    break
                }
                $arguments = Resolve-BoostLabInstallersPathExpression ([string]$parameters['Arguments'])
                $startParams = @{
                    FilePath = $filePath
                    ErrorAction = 'Stop'
                }
                if (-not [string]::IsNullOrWhiteSpace($arguments)) {
                    $startParams['ArgumentList'] = $arguments
                }
                if ([bool]$parameters['Wait']) {
                    $startParams['Wait'] = $true
                }
                Start-Process @startParams
            }
            'LaunchEpicGamesLauncher' {
                $operationDetails = Invoke-BoostLabInstallersEpicLauncher `
                    -SourceDefinedPathExpression ([string]$parameters['SourceDefinedPath']) `
                    -Arguments (Resolve-BoostLabInstallersPathExpression ([string]$parameters['Arguments'])) `
                    -Wait ([bool]$parameters['Wait']) `
                    -MaxWaitSeconds ([int]$parameters['MaxWaitSeconds']) `
                    -PollIntervalSeconds ([int]$parameters['PollIntervalSeconds'])
                if (-not [bool]$operationDetails.Success) {
                    throw [string]$operationDetails.Message
                }
            }
            'WriteTextFile' {
                $path = Resolve-BoostLabInstallersPathExpression ([string]$parameters['Path'])
                $parent = Split-Path -Parent $path
                if (-not [string]::IsNullOrWhiteSpace($parent)) {
                    New-Item -Path $parent -ItemType Directory -Force | Out-Null
                }
                Set-Content -LiteralPath $path -Value ([string]$parameters['Content']) -Force -ErrorAction Stop
            }
            'SetRegistryValue' {
                New-Item -Path ([string]$parameters['Path']) -Force | Out-Null
                New-ItemProperty -Path ([string]$parameters['Path']) -Name ([string]$parameters['Name']) -Value $parameters['Value'] -PropertyType ([string]$parameters['Type']) -Force -ErrorAction Stop | Out-Null
            }
            'RemoveRegistryValue' {
                Remove-ItemProperty -Path ([string]$parameters['Path']) -Name ([string]$parameters['Name']) -ErrorAction SilentlyContinue
            }
            'MoveItem' {
                $path = Resolve-BoostLabInstallersPathExpression ([string]$parameters['Path'])
                $destination = Resolve-BoostLabInstallersPathExpression ([string]$parameters['Destination'])
                if ([bool]($parameters['IgnoreMissing']) -and -not (Test-Path -LiteralPath $path)) {
                    break
                }
                Move-Item -Path $path -Destination $destination -Force -ErrorAction Stop | Out-Null
            }
            'RemoveItem' {
                $path = Resolve-BoostLabInstallersPathExpression ([string]$parameters['Path'])
                if ([bool]($parameters['IgnoreMissing']) -and -not (Test-Path -LiteralPath $path)) {
                    break
                }
                Remove-Item -Path $path -Recurse:([bool]$parameters['Recurse']) -Force -ErrorAction Stop | Out-Null
            }
            'EnsureDirectory' {
                New-Item -Path (Resolve-BoostLabInstallersPathExpression ([string]$parameters['Path'])) -ItemType Directory -Force | Out-Null
            }
            'CreateShortcut' {
                $path = Resolve-BoostLabInstallersPathExpression ([string]$parameters['Path'])
                $parent = Split-Path -Parent $path
                if (-not [string]::IsNullOrWhiteSpace($parent)) {
                    New-Item -Path $parent -ItemType Directory -Force | Out-Null
                }
                $shell = New-Object -ComObject WScript.Shell
                $shortcut = $shell.CreateShortcut($path)
                $shortcut.TargetPath = Resolve-BoostLabInstallersPathExpression ([string]$parameters['TargetPath'])
                $shortcut.WorkingDirectory = Resolve-BoostLabInstallersPathExpression ([string]$parameters['WorkingDirectory'])
                $shortcut.Save()
            }
            'RemoveActiveSetupByDefaultMatch' {
                $operationDetails = Invoke-BoostLabInstallersActiveSetupDefaultMatchRemoval `
                    -Path ([string]$parameters['Path']) `
                    -Pattern ([string]$parameters['Pattern'])
                if (-not [bool]$operationDetails.Success) {
                    throw "Active Setup cleanup failed: $($operationDetails.Failures -join '; ')"
                }
            }
            'StopDeleteServicesByNameMatch' {
                Get-Service | Where-Object { $_.Name -match [string]$parameters['Pattern'] } | ForEach-Object {
                    & sc.exe stop $_.Name | Out-Null
                    & sc.exe delete $_.Name | Out-Null
                }
            }
            'RemoveScheduledTasksByNameLike' {
                Get-ScheduledTask | Where-Object { $_.TaskName -like [string]$parameters['Pattern'] } | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
            }
            'RemoveScheduledTasksByNameMatch' {
                Get-ScheduledTask | Where-Object { $_.TaskName -match [string]$parameters['Pattern'] } | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
            }
            'UninstallByDisplayName' {
                $operationDetails = Invoke-BoostLabInstallersDisplayNameUninstall `
                    -RegistryPath ([string]$parameters['RegistryPath']) `
                    -DisplayNameLike ([string]$parameters['DisplayNameLike']) `
                    -Arguments ([string]$parameters['Arguments'])
                if (-not [bool]$operationDetails.Success) {
                    throw "Display-name uninstall failed: $($operationDetails.FailureEntries -join '; ')"
                }
            }
            'Sleep' {
                Start-Sleep -Seconds ([int]$parameters['Seconds'])
            }
            'StopProcess' {
                Stop-Process -Name ([string]$parameters['Name']) -Force -ErrorAction SilentlyContinue
            }
            'WriteFirefoxUserJs' {
                $profileRoot = Resolve-BoostLabInstallersPathExpression ([string]$parameters['ProfileRoot'])
                $profile = Get-ChildItem -Path $profileRoot -Directory -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -match '\.default-release$' } |
                    Sort-Object LastWriteTime -Descending |
                    Select-Object -First 1
                if ($null -ne $profile) {
                    [System.IO.File]::WriteAllText((Join-Path $profile.FullName 'user.js'), [string]$parameters['Content'], [System.Text.UTF8Encoding]::new($false))
                }
            }
            default {
                throw "Unsupported Installers operation type: $($Operation.Type)"
            }
        }

        [pscustomobject]@{
            Success = $true
            Message = "Completed operation: $($Operation.Label)"
            Operation = $Operation
            AppId = [string]$App.AppId
            Details = $operationDetails
        }
    }
    catch {
        [pscustomobject]@{
            Success = $false
            Message = $_.Exception.Message
            Operation = $Operation
            AppId = [string]$App.AppId
            Details = $operationDetails
        }
    }
}

function Test-BoostLabInstallersRuntimePrerequisites {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $errors = [System.Collections.Generic.List[string]]::new()
    $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
        $errors.Add('Administrator rights are required for the source-defined Installers workflow.')
    }
    if (-not (Test-Connection -ComputerName '8.8.8.8' -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
        $errors.Add('Internet connectivity is required for source-defined installer downloads.')
    }

    [pscustomobject]@{
        Passed = $errors.Count -eq 0
        Errors = $errors.ToArray()
    }
}

function Invoke-BoostLabInstallersSelectedApp {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$SelectedAppIds,
        [scriptblock]$OperationExecutor,
        [switch]$SkipEnvironmentChecks
    )

    $catalog = @(Get-BoostLabInstallersCatalog)
    $catalogById = @{}
    foreach ($app in $catalog) {
        $catalogById[[string]$app.AppId] = $app
    }

    $normalizedSelection = @($SelectedAppIds | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    $invalidSelection = @($normalizedSelection | Where-Object { -not $catalogById.ContainsKey($_) })
    if ($invalidSelection.Count -gt 0) {
        return [pscustomobject]@{
            Success = $false
            Status = 'InvalidSelection'
            Message = 'The selected Installers app ID is not retained or selectable.'
            SelectedApp = $null
            CompletedApp = $null
            FailedApp = $null
            LegacyDiagnosticQueue = @()
            Queue = @()
            CompletedApps = @()
            RemainingApps = @()
            OperationResults = @()
            Errors = @("Invalid selected app ids: $($invalidSelection -join ', ')")
            ChangesExecuted = $false
        }
    }
    if ($normalizedSelection.Count -eq 0) {
        return [pscustomobject]@{
            Success = $false
            Status = 'SelectionRequired'
            Message = 'Select exactly one retained Installers app before Apply.'
            SelectedApp = $null
            CompletedApp = $null
            FailedApp = $null
            LegacyDiagnosticQueue = @()
            Queue = @()
            CompletedApps = @()
            RemainingApps = @()
            OperationResults = @()
            Errors = @('Exactly one retained Installers app must be selected before Apply.')
            ChangesExecuted = $false
        }
    }
    if ($normalizedSelection.Count -gt 1) {
        return [pscustomobject]@{
            Success = $false
            Status = 'SelectionRequired'
            Message = 'Select exactly one retained Installers app before Apply; multiple app selection is not allowed.'
            SelectedApp = $null
            CompletedApp = $null
            FailedApp = $null
            LegacyDiagnosticQueue = @()
            Queue = @()
            CompletedApps = @()
            RemainingApps = @()
            OperationResults = @()
            Errors = @("Multiple selected app ids are not allowed: $($normalizedSelection -join ', ')")
            ChangesExecuted = $false
        }
    }

    $selectedApp = $catalogById[[string]$normalizedSelection[0]]
    if (-not $SkipEnvironmentChecks) {
        $prerequisites = Test-BoostLabInstallersRuntimePrerequisites
        if (-not [bool]$prerequisites.Passed) {
            return [pscustomobject]@{
                Success = $false
                Status = 'PrerequisiteFailed'
                Message = 'Installers Apply blocked before download or installer execution because runtime prerequisites failed.'
                SelectedApp = $selectedApp
                CompletedApp = $null
                FailedApp = $null
                LegacyDiagnosticQueue = @($selectedApp)
                Queue = @($selectedApp)
                CompletedApps = @()
                RemainingApps = @()
                OperationResults = @()
                Errors = @($prerequisites.Errors)
                ChangesExecuted = $false
            }
        }
    }

    $executor = if ($null -ne $OperationExecutor) {
        $OperationExecutor
    }
    else {
        { param($Operation, $App) Invoke-BoostLabInstallersOperation -Operation $Operation -App $App }
    }

    $operationResults = [System.Collections.Generic.List[object]]::new()
    foreach ($operation in @($selectedApp.Operations)) {
        $operationResult = & $executor $operation $selectedApp
        if ($null -eq $operationResult) {
            $operationResult = [pscustomobject]@{
                Success = $false
                Message = 'Operation executor returned no result.'
                Operation = $operation
                AppId = [string]$selectedApp.AppId
            }
        }
        $operationResults.Add($operationResult)
        if (-not [bool]$operationResult.Success) {
            return [pscustomobject]@{
                Success = $false
                Status = 'SelectedAppFailed'
                Message = "Installers selected app failed in $($selectedApp.DisplayName): $($operationResult.Message)"
                SelectedApp = $selectedApp
                CompletedApp = $null
                FailedApp = $selectedApp
                LegacyDiagnosticQueue = @($selectedApp)
                Queue = @($selectedApp)
                CompletedApps = @()
                RemainingApps = @()
                OperationResults = $operationResults.ToArray()
                Errors = @([string]$operationResult.Message)
                ChangesExecuted = $operationResults.Count -gt 0
            }
        }
    }

    [pscustomobject]@{
        Success = $true
        Status = 'Completed'
        Message = "Selected Installers app completed: $($selectedApp.DisplayName). To install another app, run Installers again and select another app."
        SelectedApp = $selectedApp
        CompletedApp = $selectedApp
        FailedApp = $null
        LegacyDiagnosticQueue = @($selectedApp)
        Queue = @($selectedApp)
        CompletedApps = @($selectedApp)
        RemainingApps = @()
        OperationResults = $operationResults.ToArray()
        Errors = @()
        ChangesExecuted = $true
    }
}

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        Id                          = [string]$script:BoostLabToolMetadata['Id']
        Title                       = [string]$script:BoostLabToolMetadata['Title']
        Stage                       = [string]$script:BoostLabToolMetadata['Stage']
        Order                       = [int]$script:BoostLabToolMetadata['Order']
        Type                        = [string]$script:BoostLabToolMetadata['Type']
        RiskLevel                   = [string]$script:BoostLabToolMetadata['RiskLevel']
        Description                 = [string]$script:BoostLabToolMetadata['Description']
        Actions                     = @($script:BoostLabToolMetadata['Actions'])
        Capabilities                = $script:BoostLabToolMetadata['Capabilities']
        ImplementedActions          = @($script:BoostLabImplementedActions)
        SelectionMode               = 'SingleSelect'
        SelectionLabel              = 'Select exactly one app to install'
        SelectionRequiredActions    = @('Apply')
        SelectionItems              = @(Get-BoostLabInstallersCatalog | ForEach-Object {
            [pscustomobject]@{
                Id               = [string]$_.AppId
                Title            = [string]$_.DisplayName
                SourceMenuNumber = [int]$_.SourceMenuNumber
            }
        })
        ConfirmationRequiredActions = @('Apply')
        ConfirmationText            = 'Installers will download and run the source-defined installers/helpers for the selected retained app only. To install another app, run Installers again and select another app. Removed Yazan-excluded apps are not available. Continue?'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabInstallersSourceStatus
    [pscustomobject]@{
        Supported            = $true
        ToolId               = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle            = [string]$script:BoostLabToolMetadata['Title']
        Reason               = 'Installers single selected-app workflow is available for retained Yazan-approved app choices.'
        SourceChecksumStatus = [string]$sourceStatus.ChecksumStatus
        Timestamp            = Get-Date
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        Status          = 'SingleSelectedAppInstall'
        LastAction      = $null
        LastResult      = $null
        RestartRequired = $false
        Timestamp       = Get-Date
    }
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ActionName,

        [bool]$Confirmed = $false,

        [AllowEmptyCollection()]
        [string[]]$SelectedAppIds = @(),

        [string]$Branch = '',

        [scriptblock]$OperationExecutor,

        [switch]$SkipEnvironmentChecks
    )

    $canonicalActionName = switch ($ActionName) {
        'Prepare Manual Handoff' { 'Open' }
        'Manual Handoff' { 'Open' }
        'Apply Auto' { 'Apply' }
        default { $ActionName }
    }

    if ($canonicalActionName -notin @($script:BoostLabImplementedActions)) {
        return New-BoostLabInstallersResult -Success $false -Action $canonicalActionName -Status 'Unsupported' -CommandStatus 'Refused before execution' -VerificationStatus 'NotApplicable' -Message 'Unsupported Installers action. Only Analyze, Open, Apply, Default, and Restore are exposed.'
    }

    if ($canonicalActionName -eq 'Analyze') {
        $analysis = Get-BoostLabInstallersAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        $mappingOk = [bool]$analysis.RemovedMenuMappingValid
        $success = $sourceOk -and $mappingOk
        $status = if ($success) { 'Analyzed' } elseif (-not $mappingOk) { 'NeedsYazanMenuNumberConfirmation' } else { 'SourceVerificationFailed' }
        $message = if ($success) {
            'Installers analyzed. Retained app catalog is available for single-app Apply; Yazan-excluded source menu entries are hidden.'
        }
        elseif (-not $mappingOk) {
            'NeedsYazanMenuNumberConfirmation. Removed source menu numbers did not match Yazan-approved app names.'
        }
        else {
            'Installers source checksum verification failed or source file is missing.'
        }
        $checks = @(
            New-BoostLabVerificationCheck -Name 'Source checksum' -Expected $script:BoostLabExpectedSourceHash -Actual ([string]$analysis.Source.DetectedSha256) -Status $(if ($sourceOk) { 'Passed' } else { 'Failed' }) -Message 'Installers source checksum must match the approved Ultimate source.'
            New-BoostLabVerificationCheck -Name 'Removed menu mapping' -Expected '9 Escape From Tarkov; 11 Frame View; 12 GOG launcher; 15 Notepad ++; 16 Nvidia App; 18 Onboard Memory Manager; 19 Pot Player' -Actual (($analysis.YazanRemovedAppMenuEntries | ForEach-Object { '{0} {1}' -f $_.SourceMenuNumber, $_.DisplayName }) -join '; ') -Status $(if ($mappingOk) { 'Passed' } else { 'Failed' }) -Message 'Yazan removed menu entries must match the source exactly.'
            New-BoostLabVerificationCheck -Name 'Analyze mutation' -Expected 'No mutation' -Actual 'No mutation' -Status 'Passed' -Message 'Analyze is read-only.'
        )
        $verification = New-BoostLabInstallersVerification -Action 'Analyze' -Status $(if ($success) { 'Passed' } else { 'Failed' }) -ExpectedState 'Verified source identity, removed mapping, and retained catalog.' -DetectedState $analysis -Checks $checks -Message $message
        return New-BoostLabInstallersResult -Success $success -Action 'Analyze' -Status $status -CommandStatus 'No execution performed' -VerificationStatus ([string]$verification.Status) -Message $message -Data $analysis -VerificationResult $verification -Errors @($analysis.RemovedMenuMappingErrors)
    }

    if ($canonicalActionName -eq 'Open') {
        $analysis = Get-BoostLabInstallersAnalysis
        $verification = New-BoostLabInstallersVerification -Action 'Open' -Status 'Passed' -ExpectedState 'Retained catalog guidance only.' -DetectedState ([pscustomobject]@{ RetainedAppCount = $analysis.RetainedAppCount; RetainedArtifactCount = $analysis.RetainedArtifactCount }) -Checks @(
            New-BoostLabVerificationCheck -Name 'Open mutation' -Expected 'No external process, download, installer, or mutation' -Actual 'No external process, download, installer, or mutation' -Status 'Passed' -Message 'Open prepares retained catalog guidance only.'
        ) -Message 'Installers retained catalog guidance prepared inside BoostLab.'
        return New-BoostLabInstallersResult -Success $true -Action 'Open' -Status 'CatalogGuidancePrepared' -CommandStatus 'No execution performed' -VerificationStatus 'Passed' -Message 'Installers retained catalog guidance prepared. No browser, external tool, download, installer launch, package action, file mutation, registry/service/task/shortcut mutation, cleanup, reboot, or system mutation occurred.' -Data $analysis -VerificationResult $verification
    }

    if ($canonicalActionName -eq 'Apply') {
        $analysis = Get-BoostLabInstallersAnalysis
        if ([string]$analysis.Source.ChecksumStatus -ne 'Passed') {
            $verification = New-BoostLabInstallersVerification -Action 'Apply' -Status 'Failed' -ExpectedState $script:BoostLabExpectedSourceHash -DetectedState ([string]$analysis.Source.DetectedSha256) -Checks @(
                New-BoostLabVerificationCheck -Name 'Source checksum' -Expected $script:BoostLabExpectedSourceHash -Actual ([string]$analysis.Source.DetectedSha256) -Status 'Failed' -Message 'Apply is blocked when source identity does not match.'
            ) -Message 'Installers Apply blocked by source checksum failure.'
            return New-BoostLabInstallersResult -Success $false -Action 'Apply' -Status 'SourceVerificationFailed' -CommandStatus 'Blocked before execution' -VerificationStatus 'Failed' -Message 'Installers Apply blocked because source checksum verification failed or source file is missing.' -Data $analysis -VerificationResult $verification -Errors @('Installers source checksum did not match the expected value or the source file is missing.')
        }
        if (-not [bool]$analysis.RemovedMenuMappingValid) {
            return New-BoostLabInstallersResult -Success $false -Action 'Apply' -Status 'NeedsYazanMenuNumberConfirmation' -CommandStatus 'Blocked before execution' -VerificationStatus 'Failed' -Message 'NeedsYazanMenuNumberConfirmation. Removed source menu numbers did not match Yazan-approved app names.' -Data $analysis -Errors @($analysis.RemovedMenuMappingErrors)
        }
        if (-not $Confirmed) {
            return New-BoostLabInstallersResult -Success $false -Action 'Apply' -Status 'Cancelled' -CommandStatus 'Cancelled before execution' -VerificationStatus 'NotApplicable' -Message 'Installers Apply cancelled before starting the selected app. No download, installer launch, package action, file mutation, registry/service/task/shortcut mutation, cleanup, reboot, or system mutation occurred.' -Cancelled $true
        }

        $effectiveSelectedAppIds = @($SelectedAppIds)
        if ($effectiveSelectedAppIds.Count -eq 0 -and -not [string]::IsNullOrWhiteSpace($Branch)) {
            $effectiveSelectedAppIds = @([string]$Branch)
        }
        $selectedAppResult = Invoke-BoostLabInstallersSelectedApp -SelectedAppIds $effectiveSelectedAppIds -OperationExecutor $OperationExecutor -SkipEnvironmentChecks:$SkipEnvironmentChecks
        $verificationStatus = if ([bool]$selectedAppResult.Success) { 'Passed' } elseif ([string]$selectedAppResult.Status -eq 'SelectionRequired') { 'NotApplicable' } else { 'Failed' }
        $checks = @(
            New-BoostLabVerificationCheck -Name 'Single app selection' -Expected 'Exactly one retained selectable app' -Actual (($selectedAppResult.Queue | ForEach-Object { $_.AppId }) -join ', ') -Status $(if (@($selectedAppResult.Queue).Count -eq 1) { 'Passed' } elseif ([string]$selectedAppResult.Status -eq 'SelectionRequired') { 'NotApplicable' } else { 'Failed' }) -Message 'Apply requires exactly one retained selected app ID.'
            New-BoostLabVerificationCheck -Name 'No queue execution' -Expected 'One selected app only' -Actual ('{0} selected app(s)' -f @($selectedAppResult.Queue).Count) -Status $(if (@($selectedAppResult.Queue).Count -le 1 -and [string]$selectedAppResult.Status -ne 'InvalidSelection') { 'Passed' } else { 'Failed' }) -Message 'Installers runs one selected app per Apply; to install another app, run Installers again.'
            New-BoostLabVerificationCheck -Name 'Failure handling' -Expected 'Selected app fails closed' -Actual ([string]$selectedAppResult.Status) -Status $(if ([string]$selectedAppResult.Status -eq 'SelectedAppFailed') { 'Failed' } elseif ([bool]$selectedAppResult.Success) { 'Passed' } else { 'NotApplicable' }) -Message 'If the selected app operation fails, that app run fails closed.'
        )
        $verification = New-BoostLabInstallersVerification -Action 'Apply' -Status $verificationStatus -ExpectedState 'Exactly one selected retained app completes or fails closed.' -DetectedState $selectedAppResult -Checks $checks -Message ([string]$selectedAppResult.Message)
        return New-BoostLabInstallersResult -Success ([bool]$selectedAppResult.Success) -Action 'Apply' -Status ([string]$selectedAppResult.Status) -CommandStatus $(if ([bool]$selectedAppResult.Success) { 'Completed' } else { 'Stopped or blocked before completion' }) -VerificationStatus $verificationStatus -Message ([string]$selectedAppResult.Message) -Data $selectedAppResult -VerificationResult $verification -Errors @($selectedAppResult.Errors) -ChangesExecuted ([bool]$selectedAppResult.ChangesExecuted)
    }

    if ($canonicalActionName -eq 'Default') {
        return New-BoostLabInstallersResult -Success $false -Action 'Default' -Status 'DefaultUnavailable' -CommandStatus 'Refused before execution' -VerificationStatus 'NotApplicable' -Message 'Default is unavailable for Installers. The source does not define a safe global Default branch; Default is not Restore, and no app, package, file, registry, service, task, shortcut, cleanup, reboot, or system state is changed.'
    }

    if ($canonicalActionName -eq 'Restore') {
        return New-BoostLabInstallersResult -Success $false -Action 'Restore' -Status 'RestoreUnavailable' -CommandStatus 'Refused before execution' -VerificationStatus 'NotApplicable' -Message 'Restore is unavailable without selected captured package, installer, file, registry, service, scheduled-task, shortcut, app configuration, cleanup, and support state plus an approved Restore contract. Default is not Restore, and no system-changing operation is planned.'
    }
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    Invoke-BoostLabToolAction -ActionName 'Default'
}

Export-ModuleMember -Function @(
    'Get-BoostLabInstallersCatalog'
    'Get-BoostLabInstallersFullSourceMenu'
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
