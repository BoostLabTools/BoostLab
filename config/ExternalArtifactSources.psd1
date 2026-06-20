@{
    SchemaVersion = '1.0'

    # This manifest classifies external source URLs for reached tools and the
    # next ordered target. It is not an artifact approval list, does not replace
    # config/ArtifactProvenance.psd1, and does not change runtime URLs.
    #
    # Policy:
    # - Official vendor/project downloads remain direct.
    # - Ultimate-author-hosted or third-party mirror artifacts should be moved
    #   to a future BoostLab-controlled mirror before final production reliance.
    # - Mirror substitution is allowed only when the BoostLab mirror serves the
    #   exact original file and SHA-256 verification passes.
    # - Source behavior and Ultimate parity must not be weakened by changing
    #   download source governance.
    SourceClassifications = @(
        'OfficialVendorDirect'
        'UltimateAuthorHostedArtifact'
        'ThirdPartyMirrorArtifact'
        'BoostLabControlledMirror'
    )

    MirrorStatuses = @(
        'NotRequiredOfficial'
        'NeedsBoostLabMirror'
        'BoostLabMirrorAvailable'
        'BlockedMissingHash'
    )

    AuditScope = @{
        ReachedToolIds = @(
            'bios-information'
            'bios-settings'
            'reinstall'
            'unattended'
            'updates-drivers-block'
            'to-bios'
            'bitlocker'
            'memory-compression'
            'date-language-region-time'
            'startup-apps-settings'
            'startup-apps-task-manager'
            'background-apps'
            'edge-settings'
            'store-settings'
            'updates-pause'
            'installers'
            'driver-clean'
            'driver-install-debloat-settings'
            'driver-install-latest'
            'nvidia-settings'
            'hdcp'
            'p0-state'
            'msi-mode'
            'directx'
        )
        PrepOnlyToolIds = @(
            'visual-cpp'
        )
        ExplicitlyOutOfScopeToolIds = @(
            'visual-cpp'
            'graphics-configuration-center'
        )
    }

    AuditedNoRuntimeArtifactToolIds = @(
        'bios-information'
        'bios-settings'
        'unattended'
        'updates-drivers-block'
        'to-bios'
        'bitlocker'
        'memory-compression'
        'date-language-region-time'
        'startup-apps-settings'
        'startup-apps-task-manager'
            'background-apps'
            'store-settings'
            'updates-pause'
            'hdcp'
            'p0-state'
            'msi-mode'
        )

    ExternalSources = @(
        @{
            Id = 'reinstall-windows11-media-creation-tool'
            ToolId = 'reinstall'
            ToolTitle = 'Reinstall'
            Stage = 'Refresh'
            StageOrder = 2
            ToolOrder = 1
            CanonicalOrder = 'Refresh 1'
            SourceScriptPath = 'source-ultimate/2 Refresh/1 Reinstall.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw11.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NeedsBoostLabMirror'
            OperationKind = 'DownloadArtifact'
            Notes = 'Source-defined Windows 11 Media Creation Tool artifact comes from the Ultimate author mirror. Runtime URL remains unchanged until an exact BoostLab mirror and SHA-256 are approved.'
        }
        @{
            Id = 'edge-settings-edge-exe'
            ToolId = 'edge-settings'
            ToolTitle = 'Edge Settings'
            Stage = 'Setup'
            StageOrder = 3
            ToolOrder = 7
            CanonicalOrder = 'Setup 7'
            SourceScriptPath = 'source-ultimate/3 Setup/6 Edge Settings.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NeedsBoostLabMirror'
            OperationKind = 'DownloadArtifact'
            Notes = 'Source-defined Edge Settings Default downloads edge.exe from the Ultimate author mirror. No mirror substitution is approved.'
        }
        @{
            Id = 'installers-discord'
            ToolId = 'installers'
            ToolTitle = 'Installers'
            Stage = 'Installers'
            StageOrder = 4
            ToolOrder = 1
            CanonicalOrder = 'Installers 1'
            SourceScriptPath = 'source-ultimate/4 Installers/1 Installers.ps1'
            OriginalDownloadUrl = 'https://discord.com/api/downloads/distributions/app/installers/latest?channel=stable&platform=win&arch=x64'
            SourceClassification = 'OfficialVendorDirect'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NotRequiredOfficial'
            OperationKind = 'DownloadArtifact'
            Notes = 'Retained Installers app source; official Discord download endpoint remains direct.'
        }
        @{
            Id = 'installers-roblox'
            ToolId = 'installers'
            ToolTitle = 'Installers'
            Stage = 'Installers'
            StageOrder = 4
            ToolOrder = 1
            CanonicalOrder = 'Installers 1'
            SourceScriptPath = 'source-ultimate/4 Installers/1 Installers.ps1'
            OriginalDownloadUrl = 'https://www.roblox.com/download/client?os=win'
            SourceClassification = 'OfficialVendorDirect'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NotRequiredOfficial'
            OperationKind = 'DownloadArtifact'
            Notes = 'Retained Installers app source; official Roblox endpoint remains direct.'
        }
        @{
            Id = 'installers-seven-zip'
            ToolId = 'installers'
            ToolTitle = 'Installers'
            Stage = 'Installers'
            StageOrder = 4
            ToolOrder = 1
            CanonicalOrder = 'Installers 1'
            SourceScriptPath = 'source-ultimate/4 Installers/1 Installers.ps1'
            OriginalDownloadUrl = 'https://www.7-zip.org/a/7z2301-x64.exe'
            SourceClassification = 'OfficialVendorDirect'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NotRequiredOfficial'
            OperationKind = 'DownloadArtifact'
            Notes = 'Retained Installers app source; official 7-Zip vendor URL remains direct.'
        }
        @{
            Id = 'installers-battle-net'
            ToolId = 'installers'
            ToolTitle = 'Installers'
            Stage = 'Installers'
            StageOrder = 4
            ToolOrder = 1
            CanonicalOrder = 'Installers 1'
            SourceScriptPath = 'source-ultimate/4 Installers/1 Installers.ps1'
            OriginalDownloadUrl = 'https://downloader.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe'
            SourceClassification = 'OfficialVendorDirect'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NotRequiredOfficial'
            OperationKind = 'DownloadArtifact'
            Notes = 'Retained Installers app source; official Battle.net downloader remains direct.'
        }
        @{
            Id = 'installers-brave'
            ToolId = 'installers'
            ToolTitle = 'Installers'
            Stage = 'Installers'
            StageOrder = 4
            ToolOrder = 1
            CanonicalOrder = 'Installers 1'
            SourceScriptPath = 'source-ultimate/4 Installers/1 Installers.ps1'
            OriginalDownloadUrl = 'https://brave-browser-downloads.s3.brave.com/latest/brave_installer-x64.exe'
            SourceClassification = 'OfficialVendorDirect'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NotRequiredOfficial'
            OperationKind = 'DownloadArtifact'
            Notes = 'Retained Installers app source; Brave official download bucket remains direct.'
        }
        @{
            Id = 'installers-electronic-arts'
            ToolId = 'installers'
            ToolTitle = 'Installers'
            Stage = 'Installers'
            StageOrder = 4
            ToolOrder = 1
            CanonicalOrder = 'Installers 1'
            SourceScriptPath = 'source-ultimate/4 Installers/1 Installers.ps1'
            OriginalDownloadUrl = 'https://origin-a.akamaihd.net/EA-Desktop-Client-Download/installer-releases/EAappInstaller.exe'
            SourceClassification = 'OfficialVendorDirect'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NotRequiredOfficial'
            OperationKind = 'DownloadArtifact'
            Notes = 'Retained Installers app source; EA official CDN endpoint remains direct.'
        }
        @{
            Id = 'installers-epic-games'
            ToolId = 'installers'
            ToolTitle = 'Installers'
            Stage = 'Installers'
            StageOrder = 4
            ToolOrder = 1
            CanonicalOrder = 'Installers 1'
            SourceScriptPath = 'source-ultimate/4 Installers/1 Installers.ps1'
            OriginalDownloadUrl = 'https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi'
            SourceClassification = 'OfficialVendorDirect'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NotRequiredOfficial'
            OperationKind = 'DownloadArtifact'
            Notes = 'Retained Installers app source; Epic Games official launcher API remains direct.'
        }
        @{
            Id = 'installers-escape-from-tarkov'
            ToolId = 'installers'
            ToolTitle = 'Installers'
            Stage = 'Installers'
            StageOrder = 4
            ToolOrder = 1
            CanonicalOrder = 'Installers 1'
            SourceScriptPath = 'source-ultimate/4 Installers/1 Installers.ps1'
            OriginalDownloadUrl = 'https://prod.escapefromtarkov.com/launcher/download'
            SourceClassification = 'OfficialVendorDirect'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NotRequiredOfficial'
            OperationKind = 'DownloadArtifact'
            Notes = 'Retained Installers app source; official Escape From Tarkov launcher endpoint remains direct.'
        }
        @{
            Id = 'installers-firefox'
            ToolId = 'installers'
            ToolTitle = 'Installers'
            Stage = 'Installers'
            StageOrder = 4
            ToolOrder = 1
            CanonicalOrder = 'Installers 1'
            SourceScriptPath = 'source-ultimate/4 Installers/1 Installers.ps1'
            OriginalDownloadUrl = 'https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US'
            SourceClassification = 'OfficialVendorDirect'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NotRequiredOfficial'
            OperationKind = 'DownloadArtifact'
            Notes = 'Retained Installers app source; Mozilla official redirect remains direct.'
        }
        @{
            Id = 'installers-ublock-origin-xpi'
            ToolId = 'installers'
            ToolTitle = 'Installers'
            Stage = 'Installers'
            StageOrder = 4
            ToolOrder = 1
            CanonicalOrder = 'Installers 1'
            SourceScriptPath = 'source-ultimate/4 Installers/1 Installers.ps1'
            OriginalDownloadUrl = 'https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi'
            SourceClassification = 'OfficialVendorDirect'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NotRequiredOfficial'
            OperationKind = 'DownloadArtifact'
            Notes = 'Retained Installers extension source; official Mozilla Add-ons distribution remains direct.'
        }
        @{
            Id = 'installers-google-chrome'
            ToolId = 'installers'
            ToolTitle = 'Installers'
            Stage = 'Installers'
            StageOrder = 4
            ToolOrder = 1
            CanonicalOrder = 'Installers 1'
            SourceScriptPath = 'source-ultimate/4 Installers/1 Installers.ps1'
            OriginalDownloadUrl = 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi'
            SourceClassification = 'OfficialVendorDirect'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NotRequiredOfficial'
            OperationKind = 'DownloadArtifact'
            Notes = 'Retained Installers app source; official Google Chrome enterprise installer remains direct.'
        }
        @{
            Id = 'installers-league-of-legends'
            ToolId = 'installers'
            ToolTitle = 'Installers'
            Stage = 'Installers'
            StageOrder = 4
            ToolOrder = 1
            CanonicalOrder = 'Installers 1'
            SourceScriptPath = 'source-ultimate/4 Installers/1 Installers.ps1'
            OriginalDownloadUrl = 'https://lol.secure.dyn.riotcdn.net/channels/public/x/installer/current/live.na.exe'
            SourceClassification = 'OfficialVendorDirect'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NotRequiredOfficial'
            OperationKind = 'DownloadArtifact'
            Notes = 'Retained Installers app source; official Riot CDN endpoint remains direct.'
        }
        @{
            Id = 'installers-obs-studio'
            ToolId = 'installers'
            ToolTitle = 'Installers'
            Stage = 'Installers'
            StageOrder = 4
            ToolOrder = 1
            CanonicalOrder = 'Installers 1'
            SourceScriptPath = 'source-ultimate/4 Installers/1 Installers.ps1'
            OriginalDownloadUrl = 'https://cdn-fastly.obsproject.com/downloads/OBS-Studio-32.1.0-Windows-x64-Installer.exe'
            SourceClassification = 'OfficialVendorDirect'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NotRequiredOfficial'
            OperationKind = 'DownloadArtifact'
            Notes = 'Retained Installers app source; official OBS Project CDN endpoint remains direct.'
        }
        @{
            Id = 'installers-rockstar-games'
            ToolId = 'installers'
            ToolTitle = 'Installers'
            Stage = 'Installers'
            StageOrder = 4
            ToolOrder = 1
            CanonicalOrder = 'Installers 1'
            SourceScriptPath = 'source-ultimate/4 Installers/1 Installers.ps1'
            OriginalDownloadUrl = 'https://gamedownloads.rockstargames.com/public/installer/Rockstar-Games-Launcher.exe'
            SourceClassification = 'OfficialVendorDirect'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NotRequiredOfficial'
            OperationKind = 'DownloadArtifact'
            Notes = 'Retained Installers app source; official Rockstar Games endpoint remains direct.'
        }
        @{
            Id = 'installers-spotify'
            ToolId = 'installers'
            ToolTitle = 'Installers'
            Stage = 'Installers'
            StageOrder = 4
            ToolOrder = 1
            CanonicalOrder = 'Installers 1'
            SourceScriptPath = 'source-ultimate/4 Installers/1 Installers.ps1'
            OriginalDownloadUrl = 'https://download.scdn.co/SpotifySetup.exe'
            SourceClassification = 'OfficialVendorDirect'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NotRequiredOfficial'
            OperationKind = 'DownloadArtifact'
            Notes = 'Retained Installers app source; official Spotify CDN endpoint remains direct.'
        }
        @{
            Id = 'installers-steam'
            ToolId = 'installers'
            ToolTitle = 'Installers'
            Stage = 'Installers'
            StageOrder = 4
            ToolOrder = 1
            CanonicalOrder = 'Installers 1'
            SourceScriptPath = 'source-ultimate/4 Installers/1 Installers.ps1'
            OriginalDownloadUrl = 'https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe'
            SourceClassification = 'OfficialVendorDirect'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NotRequiredOfficial'
            OperationKind = 'DownloadArtifact'
            Notes = 'Retained Installers app source; official Steam static CDN endpoint remains direct.'
        }
        @{
            Id = 'installers-ubisoft-connect'
            ToolId = 'installers'
            ToolTitle = 'Installers'
            Stage = 'Installers'
            StageOrder = 4
            ToolOrder = 1
            CanonicalOrder = 'Installers 1'
            SourceScriptPath = 'source-ultimate/4 Installers/1 Installers.ps1'
            OriginalDownloadUrl = 'https://static3.cdn.ubi.com/orbit/launcher_installer/UbisoftConnectInstaller.exe'
            SourceClassification = 'OfficialVendorDirect'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NotRequiredOfficial'
            OperationKind = 'DownloadArtifact'
            Notes = 'Retained Installers app source; official Ubisoft CDN endpoint remains direct.'
        }
        @{
            Id = 'installers-valorant'
            ToolId = 'installers'
            ToolTitle = 'Installers'
            Stage = 'Installers'
            StageOrder = 4
            ToolOrder = 1
            CanonicalOrder = 'Installers 1'
            SourceScriptPath = 'source-ultimate/4 Installers/1 Installers.ps1'
            OriginalDownloadUrl = 'https://valorant.secure.dyn.riotcdn.net/channels/public/x/installer/current/live.live.ap.exe'
            SourceClassification = 'OfficialVendorDirect'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NotRequiredOfficial'
            OperationKind = 'DownloadArtifact'
            Notes = 'Retained Installers app source; official Riot CDN endpoint remains direct.'
        }
        @{
            Id = 'driver-clean-seven-zip'
            ToolId = 'driver-clean'
            ToolTitle = 'Driver Clean'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 1
            CanonicalOrder = 'Graphics 1'
            SourceScriptPath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/1 Driver Clean.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NeedsBoostLabMirror'
            OperationKind = 'DownloadArtifact'
            Notes = 'Driver Clean keeps the Yazan-approved intake exception, but the author-hosted 7-Zip artifact still needs future BoostLab mirror and SHA-256 evidence.'
        }
        @{
            Id = 'driver-clean-ddu'
            ToolId = 'driver-clean'
            ToolTitle = 'Driver Clean'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 1
            CanonicalOrder = 'Graphics 1'
            SourceScriptPath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/1 Driver Clean.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/ddu.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NeedsBoostLabMirror'
            OperationKind = 'DownloadArtifact'
            Notes = 'DDU remains scoped only to Driver Clean; this does not approve standalone DDU, uncontrolled DDU execution, or DDU artifact provenance.'
        }
        @{
            Id = 'driver-install-debloat-settings-seven-zip'
            ToolId = 'driver-install-debloat-settings'
            ToolTitle = 'Driver Install Debloat & Settings'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 2
            CanonicalOrder = 'Graphics 2'
            SourceScriptPath = 'source-ultimate/5 Graphics/1 Driver Install Debloat & Settings.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NeedsBoostLabMirror'
            OperationKind = 'DownloadArtifact'
            Notes = 'Source-defined three-branch workflow downloads 7-Zip from the Ultimate author mirror; exact mirror/hash approval is still required for future source substitution.'
        }
        @{
            Id = 'driver-install-debloat-settings-inspector'
            ToolId = 'driver-install-debloat-settings'
            ToolTitle = 'Driver Install Debloat & Settings'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 2
            CanonicalOrder = 'Graphics 2'
            SourceScriptPath = 'source-ultimate/5 Graphics/1 Driver Install Debloat & Settings.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/inspector.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NeedsBoostLabMirror'
            OperationKind = 'DownloadArtifact'
            Notes = 'NVIDIA branch downloads Profile Inspector from the Ultimate author mirror; future BoostLab mirror must preserve the exact file and SHA-256.'
        }
        @{
            Id = 'driver-install-latest-nvidia-lookup'
            ToolId = 'driver-install-latest'
            ToolTitle = 'Driver Install Latest'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 3
            CanonicalOrder = 'Graphics 3'
            SourceScriptPath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
            OriginalDownloadUrl = 'https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=120&pfid=929&osID=57&languageCode=1033&isWHQL=1&dch=1&sort1=0&numberOfResults=1'
            SourceClassification = 'OfficialVendorDirect'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NotRequiredOfficial'
            OperationKind = 'LookupApi'
            Notes = 'Source-defined NVIDIA latest-driver lookup uses NVIDIA service endpoint directly.'
        }
        @{
            Id = 'driver-install-latest-nvidia-driver-template'
            ToolId = 'driver-install-latest'
            ToolTitle = 'Driver Install Latest'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 3
            CanonicalOrder = 'Graphics 3'
            SourceScriptPath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
            OriginalDownloadUrl = 'https://international.download.nvidia.com/Windows/{version}/{version}-desktop-{windowsVersion}-{windowsArchitecture}-international-dch-whql.exe'
            SourceClassification = 'OfficialVendorDirect'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NotRequiredOfficial'
            OperationKind = 'DynamicDownloadTemplate'
            Notes = 'Source builds the final NVIDIA driver URL from NVIDIA lookup data; official vendor download remains direct.'
        }
        @{
            Id = 'driver-install-latest-amd-support-page'
            ToolId = 'driver-install-latest'
            ToolTitle = 'Driver Install Latest'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 3
            CanonicalOrder = 'Graphics 3'
            SourceScriptPath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
            OriginalDownloadUrl = 'https://www.amd.com/en/support/download/drivers.html'
            SourceClassification = 'OfficialVendorDirect'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NotRequiredOfficial'
            OperationKind = 'LookupPage'
            Notes = 'Source scrapes AMD support page and downloads the discovered drivers.amd.com web installer; official vendor flow remains direct.'
        }
        @{
            Id = 'driver-install-latest-intel-driver-page'
            ToolId = 'driver-install-latest'
            ToolTitle = 'Driver Install Latest'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 3
            CanonicalOrder = 'Graphics 3'
            SourceScriptPath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
            OriginalDownloadUrl = 'https://www.intel.com/content/www/us/en/search.html#sortCriteria=%40lastmodifieddt%20descending&f-operatingsystem_en=Windows%2011%20Family*&f-downloadtype=Drivers&cf-tabfilter=Downloads&cf-downloadsppth=Graphics'
            SourceClassification = 'OfficialVendorDirect'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NotRequiredOfficial'
            OperationKind = 'VendorPage'
            Notes = 'Source opens the Intel official driver page rather than downloading an artifact directly.'
        }
        @{
            Id = 'nvidia-settings-seven-zip'
            ToolId = 'nvidia-settings'
            ToolTitle = 'Nvidia Settings'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 4
            CanonicalOrder = 'Graphics 4'
            SourceScriptPath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NeedsBoostLabMirror'
            OperationKind = 'DownloadArtifact'
            Notes = 'Phase 125 prep classification only. Source downloads 7-Zip from the Ultimate author mirror; no runtime implementation or source substitution is approved here.'
        }
        @{
            Id = 'nvidia-settings-inspector'
            ToolId = 'nvidia-settings'
            ToolTitle = 'Nvidia Settings'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 4
            CanonicalOrder = 'Graphics 4'
            SourceScriptPath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/inspector.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NeedsBoostLabMirror'
            OperationKind = 'DownloadArtifact'
            Notes = 'Phase 125 prep classification only. Source downloads NVIDIA Profile Inspector from the Ultimate author mirror for both Apply and Default branches.'
        }
        @{
            Id = 'directx-seven-zip'
            ToolId = 'directx'
            ToolTitle = 'DirectX'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 8
            CanonicalOrder = 'Graphics 8'
            SourceScriptPath = 'source-ultimate/5 Graphics/2 DirectX.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NeedsBoostLabMirror'
            OperationKind = 'DownloadArtifact'
            Notes = 'DirectX source-equivalent workflow downloads 7-Zip from the Ultimate author mirror; exact BoostLab mirror/hash approval is still required for future source substitution.'
        }
        @{
            Id = 'directx-runtime-package'
            ToolId = 'directx'
            ToolTitle = 'DirectX'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 8
            CanonicalOrder = 'Graphics 8'
            SourceScriptPath = 'source-ultimate/5 Graphics/2 DirectX.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/directx.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = $null
            ExpectedSha256 = $null
            MirrorStatus = 'NeedsBoostLabMirror'
            OperationKind = 'DownloadArtifact'
            Notes = 'DirectX source-equivalent workflow downloads the DirectX package from the Ultimate author mirror; exact BoostLab mirror/hash approval is still required for future source substitution.'
        }
    )
}
