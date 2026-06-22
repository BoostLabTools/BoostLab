@{
    SchemaVersion = '1.0'

    # This manifest classifies external source URLs for reached tools. It is
    # not an artifact approval list, does not replace
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

    OfficialVendorDirectRuntimePolicy = @{
        SchemaVersion = '1.0'
        Phase = '164I'
        ApprovedCount = 22
        RequiredScheme = 'https'
        AllowedSourceKinds = @(
            'StaticOfficialInstaller'
            'FloatingOfficialInstaller'
            'OfficialVendorLookupPage'
            'OfficialVendorApi'
            'BrowserExtensionOfficialSource'
        )
        Entries = @(
            @{
                Id = 'installers-discord'
                OfficialSourceKind = 'FloatingOfficialInstaller'
                OfficialHostAllowlist = @('discord.com')
                ExpectedFileName = 'Discord.exe'
                ExpectedExtension = '.exe'
                DownloadExecutionApproved = $true
                ResolvedDownloadExecutionApproved = $false
                LookupExecutionApproved = $false
                InstallerExecutionApproved = $true
                ProductionAllowlistApproved = $true
                RuntimeSourceSelectionApproved = $true
                RequiresVerifiedLocalPath = $true
                NoUrlExecution = $true
                SignatureVerificationRequired = $true
                ExpectedSignatureStatus = 'Valid'
            }
            @{
                Id = 'installers-roblox'
                OfficialSourceKind = 'FloatingOfficialInstaller'
                OfficialHostAllowlist = @('www.roblox.com')
                ExpectedFileName = 'Roblox.exe'
                ExpectedExtension = '.exe'
                DownloadExecutionApproved = $true
                ResolvedDownloadExecutionApproved = $false
                LookupExecutionApproved = $false
                InstallerExecutionApproved = $true
                ProductionAllowlistApproved = $true
                RuntimeSourceSelectionApproved = $true
                RequiresVerifiedLocalPath = $true
                NoUrlExecution = $true
                SignatureVerificationRequired = $true
                ExpectedSignatureStatus = 'Valid'
            }
            @{
                Id = 'installers-seven-zip'
                OfficialSourceKind = 'StaticOfficialInstaller'
                OfficialHostAllowlist = @('www.7-zip.org')
                ExpectedFileName = '7 Zip.exe'
                ExpectedExtension = '.exe'
                DownloadExecutionApproved = $true
                ResolvedDownloadExecutionApproved = $false
                LookupExecutionApproved = $false
                InstallerExecutionApproved = $true
                ProductionAllowlistApproved = $true
                RuntimeSourceSelectionApproved = $true
                RequiresVerifiedLocalPath = $true
                NoUrlExecution = $true
                SignatureVerificationRequired = $true
                ExpectedSignatureStatus = 'Valid'
            }
            @{
                Id = 'installers-battle-net'
                OfficialSourceKind = 'FloatingOfficialInstaller'
                OfficialHostAllowlist = @('downloader.battle.net')
                ExpectedFileName = 'Battle.net.exe'
                ExpectedExtension = '.exe'
                DownloadExecutionApproved = $true
                ResolvedDownloadExecutionApproved = $false
                LookupExecutionApproved = $false
                InstallerExecutionApproved = $true
                ProductionAllowlistApproved = $true
                RuntimeSourceSelectionApproved = $true
                RequiresVerifiedLocalPath = $true
                NoUrlExecution = $true
                SignatureVerificationRequired = $true
                ExpectedSignatureStatus = 'Valid'
            }
            @{
                Id = 'installers-brave'
                OfficialSourceKind = 'FloatingOfficialInstaller'
                OfficialHostAllowlist = @('brave-browser-downloads.s3.brave.com')
                ExpectedFileName = 'BraveInstaller.exe'
                ExpectedExtension = '.exe'
                DownloadExecutionApproved = $true
                ResolvedDownloadExecutionApproved = $false
                LookupExecutionApproved = $false
                InstallerExecutionApproved = $true
                ProductionAllowlistApproved = $true
                RuntimeSourceSelectionApproved = $true
                RequiresVerifiedLocalPath = $true
                NoUrlExecution = $true
                SignatureVerificationRequired = $true
                ExpectedSignatureStatus = 'Valid'
            }
            @{
                Id = 'installers-electronic-arts'
                OfficialSourceKind = 'FloatingOfficialInstaller'
                OfficialHostAllowlist = @('origin-a.akamaihd.net')
                ExpectedFileName = 'Electronic Arts.exe'
                ExpectedExtension = '.exe'
                DownloadExecutionApproved = $true
                ResolvedDownloadExecutionApproved = $false
                LookupExecutionApproved = $false
                InstallerExecutionApproved = $true
                ProductionAllowlistApproved = $true
                RuntimeSourceSelectionApproved = $true
                RequiresVerifiedLocalPath = $true
                NoUrlExecution = $true
                SignatureVerificationRequired = $true
                ExpectedSignatureStatus = 'Valid'
            }
            @{
                Id = 'installers-epic-games'
                OfficialSourceKind = 'FloatingOfficialInstaller'
                OfficialHostAllowlist = @('launcher-public-service-prod06.ol.epicgames.com')
                ExpectedFileName = 'Epic Games.msi'
                ExpectedExtension = '.msi'
                DownloadExecutionApproved = $true
                ResolvedDownloadExecutionApproved = $false
                LookupExecutionApproved = $false
                InstallerExecutionApproved = $true
                ProductionAllowlistApproved = $true
                RuntimeSourceSelectionApproved = $true
                RequiresVerifiedLocalPath = $true
                NoUrlExecution = $true
                SignatureVerificationRequired = $true
                ExpectedSignatureStatus = 'Valid'
            }
            @{
                Id = 'installers-escape-from-tarkov'
                OfficialSourceKind = 'FloatingOfficialInstaller'
                OfficialHostAllowlist = @('prod.escapefromtarkov.com')
                ExpectedFileName = 'Escape From Tarkov.exe'
                ExpectedExtension = '.exe'
                DownloadExecutionApproved = $true
                ResolvedDownloadExecutionApproved = $false
                LookupExecutionApproved = $false
                InstallerExecutionApproved = $true
                ProductionAllowlistApproved = $true
                RuntimeSourceSelectionApproved = $true
                RequiresVerifiedLocalPath = $true
                NoUrlExecution = $true
                SignatureVerificationRequired = $true
                ExpectedSignatureStatus = 'Valid'
            }
            @{
                Id = 'installers-firefox'
                OfficialSourceKind = 'FloatingOfficialInstaller'
                OfficialHostAllowlist = @('download.mozilla.org')
                ExpectedFileName = 'Firefox.exe'
                ExpectedExtension = '.exe'
                DownloadExecutionApproved = $true
                ResolvedDownloadExecutionApproved = $false
                LookupExecutionApproved = $false
                InstallerExecutionApproved = $true
                ProductionAllowlistApproved = $true
                RuntimeSourceSelectionApproved = $true
                RequiresVerifiedLocalPath = $true
                NoUrlExecution = $true
                SignatureVerificationRequired = $true
                ExpectedSignatureStatus = 'Valid'
            }
            @{
                Id = 'installers-ublock-origin-xpi'
                OfficialSourceKind = 'BrowserExtensionOfficialSource'
                OfficialHostAllowlist = @('addons.mozilla.org')
                ExpectedFileName = 'uBlock0@raymondhill.net.xpi'
                ExpectedExtension = '.xpi'
                DownloadExecutionApproved = $true
                ResolvedDownloadExecutionApproved = $false
                LookupExecutionApproved = $false
                InstallerExecutionApproved = $false
                ProductionAllowlistApproved = $true
                RuntimeSourceSelectionApproved = $true
                RequiresVerifiedLocalPath = $true
                NoUrlExecution = $true
                SignatureVerificationRequired = $false
                BrowserExtensionVerificationRequired = $true
            }
            @{
                Id = 'installers-google-chrome'
                OfficialSourceKind = 'StaticOfficialInstaller'
                OfficialHostAllowlist = @('dl.google.com')
                ExpectedFileName = 'Chrome.msi'
                ExpectedExtension = '.msi'
                DownloadExecutionApproved = $true
                ResolvedDownloadExecutionApproved = $false
                LookupExecutionApproved = $false
                InstallerExecutionApproved = $true
                ProductionAllowlistApproved = $true
                RuntimeSourceSelectionApproved = $true
                RequiresVerifiedLocalPath = $true
                NoUrlExecution = $true
                SignatureVerificationRequired = $true
                ExpectedSignatureStatus = 'Valid'
            }
            @{
                Id = 'installers-league-of-legends'
                OfficialSourceKind = 'FloatingOfficialInstaller'
                OfficialHostAllowlist = @('lol.secure.dyn.riotcdn.net')
                ExpectedFileName = 'League Of Legends.exe'
                ExpectedExtension = '.exe'
                DownloadExecutionApproved = $true
                ResolvedDownloadExecutionApproved = $false
                LookupExecutionApproved = $false
                InstallerExecutionApproved = $true
                ProductionAllowlistApproved = $true
                RuntimeSourceSelectionApproved = $true
                RequiresVerifiedLocalPath = $true
                NoUrlExecution = $true
                SignatureVerificationRequired = $true
                ExpectedSignatureStatus = 'Valid'
            }
            @{
                Id = 'installers-obs-studio'
                OfficialSourceKind = 'StaticOfficialInstaller'
                OfficialHostAllowlist = @('cdn-fastly.obsproject.com')
                ExpectedFileName = 'OBS Studio.exe'
                ExpectedExtension = '.exe'
                DownloadExecutionApproved = $true
                ResolvedDownloadExecutionApproved = $false
                LookupExecutionApproved = $false
                InstallerExecutionApproved = $true
                ProductionAllowlistApproved = $true
                RuntimeSourceSelectionApproved = $true
                RequiresVerifiedLocalPath = $true
                NoUrlExecution = $true
                SignatureVerificationRequired = $true
                ExpectedSignatureStatus = 'Valid'
            }
            @{
                Id = 'installers-rockstar-games'
                OfficialSourceKind = 'FloatingOfficialInstaller'
                OfficialHostAllowlist = @('gamedownloads.rockstargames.com')
                ExpectedFileName = 'Rockstar Games.exe'
                ExpectedExtension = '.exe'
                DownloadExecutionApproved = $true
                ResolvedDownloadExecutionApproved = $false
                LookupExecutionApproved = $false
                InstallerExecutionApproved = $true
                ProductionAllowlistApproved = $true
                RuntimeSourceSelectionApproved = $true
                RequiresVerifiedLocalPath = $true
                NoUrlExecution = $true
                SignatureVerificationRequired = $true
                ExpectedSignatureStatus = 'Valid'
            }
            @{
                Id = 'installers-spotify'
                OfficialSourceKind = 'FloatingOfficialInstaller'
                OfficialHostAllowlist = @('download.scdn.co')
                ExpectedFileName = 'Spotify.exe'
                ExpectedExtension = '.exe'
                DownloadExecutionApproved = $true
                ResolvedDownloadExecutionApproved = $false
                LookupExecutionApproved = $false
                InstallerExecutionApproved = $true
                ProductionAllowlistApproved = $true
                RuntimeSourceSelectionApproved = $true
                RequiresVerifiedLocalPath = $true
                NoUrlExecution = $true
                SignatureVerificationRequired = $true
                ExpectedSignatureStatus = 'Valid'
            }
            @{
                Id = 'installers-steam'
                OfficialSourceKind = 'FloatingOfficialInstaller'
                OfficialHostAllowlist = @('cdn.cloudflare.steamstatic.com')
                ExpectedFileName = 'Steam.exe'
                ExpectedExtension = '.exe'
                DownloadExecutionApproved = $true
                ResolvedDownloadExecutionApproved = $false
                LookupExecutionApproved = $false
                InstallerExecutionApproved = $true
                ProductionAllowlistApproved = $true
                RuntimeSourceSelectionApproved = $true
                RequiresVerifiedLocalPath = $true
                NoUrlExecution = $true
                SignatureVerificationRequired = $true
                ExpectedSignatureStatus = 'Valid'
            }
            @{
                Id = 'installers-ubisoft-connect'
                OfficialSourceKind = 'FloatingOfficialInstaller'
                OfficialHostAllowlist = @('static3.cdn.ubi.com')
                ExpectedFileName = 'Ubisoft Connect.exe'
                ExpectedExtension = '.exe'
                DownloadExecutionApproved = $true
                ResolvedDownloadExecutionApproved = $false
                LookupExecutionApproved = $false
                InstallerExecutionApproved = $true
                ProductionAllowlistApproved = $true
                RuntimeSourceSelectionApproved = $true
                RequiresVerifiedLocalPath = $true
                NoUrlExecution = $true
                SignatureVerificationRequired = $true
                ExpectedSignatureStatus = 'Valid'
            }
            @{
                Id = 'installers-valorant'
                OfficialSourceKind = 'FloatingOfficialInstaller'
                OfficialHostAllowlist = @('valorant.secure.dyn.riotcdn.net')
                ExpectedFileName = 'Valorant.exe'
                ExpectedExtension = '.exe'
                DownloadExecutionApproved = $true
                ResolvedDownloadExecutionApproved = $false
                LookupExecutionApproved = $false
                InstallerExecutionApproved = $true
                ProductionAllowlistApproved = $true
                RuntimeSourceSelectionApproved = $true
                RequiresVerifiedLocalPath = $true
                NoUrlExecution = $true
                SignatureVerificationRequired = $true
                ExpectedSignatureStatus = 'Valid'
            }
            @{
                Id = 'driver-install-latest-nvidia-lookup'
                OfficialSourceKind = 'OfficialVendorApi'
                OfficialHostAllowlist = @('gfwsl.geforce.com')
                ExpectedFileName = $null
                ExpectedExtension = $null
                DownloadExecutionApproved = $false
                ResolvedDownloadExecutionApproved = $false
                LookupExecutionApproved = $true
                InstallerExecutionApproved = $false
                ProductionAllowlistApproved = $true
                RuntimeSourceSelectionApproved = $true
                RequiresVerifiedLocalPath = $false
                NoUrlExecution = $true
                SignatureVerificationRequired = $false
            }
            @{
                Id = 'driver-install-latest-nvidia-driver-template'
                OfficialSourceKind = 'FloatingOfficialInstaller'
                OfficialHostAllowlist = @('international.download.nvidia.com')
                ResolvedDownloadHostAllowlist = @('international.download.nvidia.com')
                ResolvedDownloadUrlPattern = '^https://international\.download\.nvidia\.com/Windows/[^/]+/[^/]+-desktop-win10-win11-64bit-international-dch-whql\.exe$'
                ExpectedFileName = 'nvidiadriver.exe'
                ExpectedExtension = '.exe'
                DownloadExecutionApproved = $true
                ResolvedDownloadExecutionApproved = $true
                LookupExecutionApproved = $false
                InstallerExecutionApproved = $true
                ProductionAllowlistApproved = $true
                RuntimeSourceSelectionApproved = $true
                RequiresVerifiedLocalPath = $true
                NoUrlExecution = $true
                SignatureVerificationRequired = $true
                ExpectedSignatureStatus = 'Valid'
            }
            @{
                Id = 'driver-install-latest-amd-support-page'
                OfficialSourceKind = 'OfficialVendorLookupPage'
                OfficialHostAllowlist = @('www.amd.com')
                ResolvedDownloadHostAllowlist = @('drivers.amd.com')
                ResolvedDownloadUrlPattern = '^https://drivers\.amd\.com/drivers/installer/.*/whql/amd-software-adrenalin-edition-.*-minimalsetup-.*_web\.exe$'
                ExpectedFileName = 'amddriver.exe'
                ExpectedExtension = '.exe'
                DownloadExecutionApproved = $false
                ResolvedDownloadExecutionApproved = $true
                LookupExecutionApproved = $true
                InstallerExecutionApproved = $true
                ProductionAllowlistApproved = $true
                RuntimeSourceSelectionApproved = $true
                RequiresVerifiedLocalPath = $true
                NoUrlExecution = $true
                SignatureVerificationRequired = $true
                ExpectedSignatureStatus = 'Valid'
            }
            @{
                Id = 'driver-install-latest-intel-driver-page'
                OfficialSourceKind = 'OfficialVendorLookupPage'
                OfficialHostAllowlist = @('www.intel.com')
                ExpectedFileName = $null
                ExpectedExtension = $null
                DownloadExecutionApproved = $false
                ResolvedDownloadExecutionApproved = $false
                LookupExecutionApproved = $true
                InstallerExecutionApproved = $false
                ProductionAllowlistApproved = $true
                RuntimeSourceSelectionApproved = $true
                RequiresVerifiedLocalPath = $false
                NoUrlExecution = $true
                SignatureVerificationRequired = $false
            }
        )
    }

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
            'visual-cpp'
            'bloatware'
            'game-bar'
            'edge-webview'
        )
        PrepOnlyToolIds = @()
        ExplicitlyOutOfScopeToolIds = @(
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
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/reinstall-windows11-media-creation-tool__mediacreationtoolw11.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/reinstall-windows11-media-creation-tool__mediacreationtoolw11.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'reinstall-windows11-media-creation-tool__mediacreationtoolw11.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 21591048
            MirrorCandidatePath = 'mirrors/reinstall/mediacreationtoolw11.exe'
            ExpectedSha256 = 'E887DFFF70BAF09A8C1DEBFE8C304DD9F2D9652FAE8B7C83B3C24554A79BBD7F'
            ExpectedSha1 = 'A65AB70110BE0862AA3A05845C15E72DDD588752'
            ExpectedSizeBytes = 21591048
            AuthenticodeStatus = 'Valid'
            SignerPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            FileVersion = '10.0.26100.7019 (ge_release_svc_prod3.251023-1855)'
            ProductVersion = '10.0.26100.7019'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = $null
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-reinstall-windows11-media-creation-tool'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadArtifact'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
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
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/edge-settings-edge-exe__edge.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/edge-settings-edge-exe__edge.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'edge-settings-edge-exe__edge.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 1683472
            MirrorCandidatePath = 'mirrors/edge-settings/edge.exe'
            ExpectedSha256 = '61A2F3AD5B6DF4167D2FFAFADE138FAE84CB1603C40251D46AA0A8FFA8BFF138'
            ExpectedSha1 = 'EEB875C9A9CDFA6279F9CAC2CE0D36407B2ABADB'
            ExpectedSizeBytes = 1683472
            AuthenticodeStatus = 'Valid'
            SignerPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            FileVersion = '1.3.225.7'
            ProductVersion = '1.3.225.7'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = 'DUP-SHA256-01'
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-edge-settings-edge-exe'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadArtifact'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
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
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/driver-clean-seven-zip__7zip.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/driver-clean-seven-zip__7zip.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'driver-clean-seven-zip__7zip.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 1589510
            MirrorCandidatePath = 'mirrors/driver-clean/7zip.exe'
            ExpectedSha256 = '26CB6E9F56333682122FAFE79DBCDFD51E9F47CC7217DCCD29AC6FC33B5598CD'
            ExpectedSha1 = '7DF28D340D7084647921CC25A8C2068BB192BDBB'
            ExpectedSizeBytes = 1589510
            AuthenticodeStatus = 'NotSigned'
            SignerPublisher = $null
            FileVersion = '23.01'
            ProductVersion = '23.01'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = 'DUP-SHA256-02'
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-driver-clean-seven-zip'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadArtifact'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
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
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/driver-clean-ddu__ddu.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/driver-clean-ddu__ddu.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'driver-clean-ddu__ddu.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 1717592
            MirrorCandidatePath = 'mirrors/driver-clean/ddu.exe'
            ExpectedSha256 = '6073E6D311290D45B7A8AE4E832994C9487082531F89E4E01C99F86C0E38DA6C'
            ExpectedSha1 = '9F95FA4EDB7E8D94E833D8CCCEA9A1C0FAE661CE'
            ExpectedSizeBytes = 1717592
            AuthenticodeStatus = 'Valid'
            SignerPublisher = 'CN=Wagnardsoft, O=Wagnardsoft, S=Quebec, C=CA'
            FileVersion = '18.1.4.2'
            ProductVersion = '18.1.4.2'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = $null
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-driver-clean-ddu'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadArtifact'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
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
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/driver-install-debloat-settings-seven-zip__7zip.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/driver-install-debloat-settings-seven-zip__7zip.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'driver-install-debloat-settings-seven-zip__7zip.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 1589510
            MirrorCandidatePath = 'mirrors/driver-install-debloat-settings/7zip.exe'
            ExpectedSha256 = '26CB6E9F56333682122FAFE79DBCDFD51E9F47CC7217DCCD29AC6FC33B5598CD'
            ExpectedSha1 = '7DF28D340D7084647921CC25A8C2068BB192BDBB'
            ExpectedSizeBytes = 1589510
            AuthenticodeStatus = 'NotSigned'
            SignerPublisher = $null
            FileVersion = '23.01'
            ProductVersion = '23.01'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = 'DUP-SHA256-02'
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-driver-install-debloat-settings-seven-zip'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadArtifact'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
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
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/driver-install-debloat-settings-inspector__inspector.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/driver-install-debloat-settings-inspector__inspector.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'driver-install-debloat-settings-inspector__inspector.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 643072
            MirrorCandidatePath = 'mirrors/driver-install-debloat-settings/inspector.exe'
            ExpectedSha256 = '7D5510DEEAACB50C88A49BBF1D894DAE44C5CE58C00D5A88392346646B14E8F3'
            ExpectedSha1 = 'FB8A3490780107C504F4D135CC4BEC02E19AC2F6'
            ExpectedSizeBytes = 643072
            AuthenticodeStatus = 'NotSigned'
            SignerPublisher = $null
            FileVersion = '2.4.0.31'
            ProductVersion = '2.4.0.31'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = 'DUP-SHA256-03'
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-driver-install-debloat-settings-inspector'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadArtifact'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
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
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/nvidia-settings-seven-zip__7zip.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/nvidia-settings-seven-zip__7zip.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'nvidia-settings-seven-zip__7zip.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 1589510
            MirrorCandidatePath = 'mirrors/nvidia-settings/7zip.exe'
            ExpectedSha256 = '26CB6E9F56333682122FAFE79DBCDFD51E9F47CC7217DCCD29AC6FC33B5598CD'
            ExpectedSha1 = '7DF28D340D7084647921CC25A8C2068BB192BDBB'
            ExpectedSizeBytes = 1589510
            AuthenticodeStatus = 'NotSigned'
            SignerPublisher = $null
            FileVersion = '23.01'
            ProductVersion = '23.01'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = 'DUP-SHA256-02'
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-nvidia-settings-seven-zip'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadArtifact'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
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
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/nvidia-settings-inspector__inspector.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/nvidia-settings-inspector__inspector.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'nvidia-settings-inspector__inspector.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 643072
            MirrorCandidatePath = 'mirrors/nvidia-settings/inspector.exe'
            ExpectedSha256 = '7D5510DEEAACB50C88A49BBF1D894DAE44C5CE58C00D5A88392346646B14E8F3'
            ExpectedSha1 = 'FB8A3490780107C504F4D135CC4BEC02E19AC2F6'
            ExpectedSizeBytes = 643072
            AuthenticodeStatus = 'NotSigned'
            SignerPublisher = $null
            FileVersion = '2.4.0.31'
            ProductVersion = '2.4.0.31'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = 'DUP-SHA256-03'
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-nvidia-settings-inspector'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadArtifact'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
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
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/directx-seven-zip__7zip.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/directx-seven-zip__7zip.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'directx-seven-zip__7zip.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 1589510
            MirrorCandidatePath = 'mirrors/directx/7zip.exe'
            ExpectedSha256 = '26CB6E9F56333682122FAFE79DBCDFD51E9F47CC7217DCCD29AC6FC33B5598CD'
            ExpectedSha1 = '7DF28D340D7084647921CC25A8C2068BB192BDBB'
            ExpectedSizeBytes = 1589510
            AuthenticodeStatus = 'NotSigned'
            SignerPublisher = $null
            FileVersion = '23.01'
            ProductVersion = '23.01'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = 'DUP-SHA256-02'
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-directx-seven-zip'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadArtifact'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
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
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/directx-runtime-package__directx.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/directx-runtime-package__directx.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'directx-runtime-package__directx.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 100275120
            MirrorCandidatePath = 'mirrors/directx/directx.exe'
            ExpectedSha256 = '053F76DCBB28802E23341B6A787E3B0791C0FA5C8D4D011B1044172DBF89C73B'
            ExpectedSha1 = '7E5D2E5E1A13FBC47F990CC55CBDB428CD12F759'
            ExpectedSizeBytes = 100275120
            AuthenticodeStatus = 'Valid'
            SignerPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            FileVersion = '9.00.8112.16421 (WIN7_IE9_RTM.110308-0330)'
            ProductVersion = '9.00.8112.16421'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = $null
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-directx-runtime-package'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadArtifact'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
        }
        @{
            Id = 'visual-cpp-vcredist2005-x64'
            ToolId = 'visual-cpp'
            ToolTitle = 'Visual C++'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 9
            CanonicalOrder = 'Graphics 9'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2005_x64.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2005-x64__vcredist2005_x64.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2005-x64__vcredist2005_x64.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2005-x64__vcredist2005_x64.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 3179000
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2005_x64.exe'
            ExpectedSha256 = '4487570BD86E2E1AAC29DB2A1D0A91EB63361FCAAC570808EB327CD4E0E2240D'
            ExpectedSha1 = 'F4D74643A0E117EA80B2C7EBCD908A6DD26AA9EA'
            ExpectedSizeBytes = 3179000
            AuthenticodeStatus = 'Valid'
            SignerPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            FileVersion = '6.00.2900.2180 (xpsp_sp2_rtm.040803-2158)'
            ProductVersion = '6.00.2900.2180'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = $null
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-visual-cpp-vcredist2005-x64'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadInstaller'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
        }
        @{
            Id = 'visual-cpp-vcredist2005-x86'
            ToolId = 'visual-cpp'
            ToolTitle = 'Visual C++'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 9
            CanonicalOrder = 'Graphics 9'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2005_x86.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2005-x86__vcredist2005_x86.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2005-x86__vcredist2005_x86.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2005-x86__vcredist2005_x86.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 2710520
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2005_x86.exe'
            ExpectedSha256 = '8648C5FC29C44B9112FE52F9A33F80E7FC42D10F3B5B42B2121542A13E44ADFD'
            ExpectedSha1 = '56AE8221E8024C8DEED430E01A6160795C64CF53'
            ExpectedSizeBytes = 2710520
            AuthenticodeStatus = 'Valid'
            SignerPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            FileVersion = '6.00.2900.2180 (xpsp_sp2_rtm.040803-2158)'
            ProductVersion = '6.00.2900.2180'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = $null
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-visual-cpp-vcredist2005-x86'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadInstaller'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
        }
        @{
            Id = 'visual-cpp-vcredist2008-x64'
            ToolId = 'visual-cpp'
            ToolTitle = 'Visual C++'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 9
            CanonicalOrder = 'Graphics 9'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2008_x64.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2008-x64__vcredist2008_x64.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2008-x64__vcredist2008_x64.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2008-x64__vcredist2008_x64.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 5211080
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2008_x64.exe'
            ExpectedSha256 = 'C5E273A4A16AB4D5471E91C7477719A2F45DDADB76C7F98A38FA5074A6838654'
            ExpectedSha1 = 'CE8FF6572E86B0BBA39D88FA3A6D56B59100613D'
            ExpectedSizeBytes = 5211080
            AuthenticodeStatus = 'Valid'
            SignerPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            FileVersion = '9.0.30729.5677'
            ProductVersion = '9.0.30729.5677'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = $null
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-visual-cpp-vcredist2008-x64'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadInstaller'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
        }
        @{
            Id = 'visual-cpp-vcredist2008-x86'
            ToolId = 'visual-cpp'
            ToolTitle = 'Visual C++'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 9
            CanonicalOrder = 'Graphics 9'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2008_x86.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2008-x86__vcredist2008_x86.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2008-x86__vcredist2008_x86.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2008-x86__vcredist2008_x86.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 4483040
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2008_x86.exe'
            ExpectedSha256 = '8742BCBF24EF328A72D2A27B693CC7071E38D3BB4B9B44DEC42AA3D2C8D61D92'
            ExpectedSha1 = '0940EC60DCC3162E482C1A797CA033D5996AB256'
            ExpectedSizeBytes = 4483040
            AuthenticodeStatus = 'Valid'
            SignerPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            FileVersion = '9.0.30729.5677'
            ProductVersion = '9.0.30729.5677'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = $null
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-visual-cpp-vcredist2008-x86'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadInstaller'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
        }
        @{
            Id = 'visual-cpp-vcredist2010-x64'
            ToolId = 'visual-cpp'
            ToolTitle = 'Visual C++'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 9
            CanonicalOrder = 'Graphics 9'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2010_x64.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2010-x64__vcredist2010_x64.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2010-x64__vcredist2010_x64.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2010-x64__vcredist2010_x64.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 10277328
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2010_x64.exe'
            ExpectedSha256 = 'F3B7A76D84D23F91957AA18456A14B4E90609E4CE8194C5653384ED38DADA6F3'
            ExpectedSha1 = '8691972F0A5BF919701AC3B80FB693FC715420C2'
            ExpectedSizeBytes = 10277328
            AuthenticodeStatus = 'Valid'
            SignerPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            FileVersion = '10.0.40219.325'
            ProductVersion = '10.0.40219.325'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = $null
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-visual-cpp-vcredist2010-x64'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadInstaller'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
        }
        @{
            Id = 'visual-cpp-vcredist2010-x86'
            ToolId = 'visual-cpp'
            ToolTitle = 'Visual C++'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 9
            CanonicalOrder = 'Graphics 9'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2010_x86.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2010-x86__vcredist2010_x86.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2010-x86__vcredist2010_x86.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2010-x86__vcredist2010_x86.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 8993744
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2010_x86.exe'
            ExpectedSha256 = '99DCE3C841CC6028560830F7866C9CE2928C98CF3256892EF8E6CF755147B0D8'
            ExpectedSha1 = '2222FC008E469FEC77D0D291877F357C6E1EB16D'
            ExpectedSizeBytes = 8993744
            AuthenticodeStatus = 'Valid'
            SignerPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            FileVersion = '10.0.40219.325'
            ProductVersion = '10.0.40219.325'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = $null
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-visual-cpp-vcredist2010-x86'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadInstaller'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
        }
        @{
            Id = 'visual-cpp-vcredist2012-x64'
            ToolId = 'visual-cpp'
            ToolTitle = 'Visual C++'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 9
            CanonicalOrder = 'Graphics 9'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2012_x64.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2012-x64__vcredist2012_x64.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2012-x64__vcredist2012_x64.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2012-x64__vcredist2012_x64.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 7186992
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2012_x64.exe'
            ExpectedSha256 = '681BE3E5BA9FD3DA02C09D7E565ADFA078640ED66A0D58583EFAD2C1E3CC4064'
            ExpectedSha1 = '1A5D93DDDBC431AB27B1DA711CD3370891542797'
            ExpectedSizeBytes = 7186992
            AuthenticodeStatus = 'Valid'
            SignerPublisher = 'CN=Microsoft Corporation, OU=MOPR, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            FileVersion = '11.0.61030.0'
            ProductVersion = '11.0.61030.0'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = $null
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-visual-cpp-vcredist2012-x64'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadInstaller'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
        }
        @{
            Id = 'visual-cpp-vcredist2012-x86'
            ToolId = 'visual-cpp'
            ToolTitle = 'Visual C++'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 9
            CanonicalOrder = 'Graphics 9'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2012_x86.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2012-x86__vcredist2012_x86.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2012-x86__vcredist2012_x86.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2012-x86__vcredist2012_x86.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 6554576
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2012_x86.exe'
            ExpectedSha256 = 'B924AD8062EAF4E70437C8BE50FA612162795FF0839479546CE907FFA8D6E386'
            ExpectedSha1 = '96B377A27AC5445328CBAAE210FC4F0AAA750D3F'
            ExpectedSizeBytes = 6554576
            AuthenticodeStatus = 'Valid'
            SignerPublisher = 'CN=Microsoft Corporation, OU=MOPR, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            FileVersion = '11.0.61030.0'
            ProductVersion = '11.0.61030.0'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = $null
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-visual-cpp-vcredist2012-x86'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadInstaller'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
        }
        @{
            Id = 'visual-cpp-vcredist2013-x64'
            ToolId = 'visual-cpp'
            ToolTitle = 'Visual C++'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 9
            CanonicalOrder = 'Graphics 9'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2013_x64.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2013-x64__vcredist2013_x64.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2013-x64__vcredist2013_x64.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2013-x64__vcredist2013_x64.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 7194312
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2013_x64.exe'
            ExpectedSha256 = 'E554425243E3E8CA1CD5FE550DB41E6FA58A007C74FAD400274B128452F38FB8'
            ExpectedSha1 = '8BF41BA9EEF02D30635A10433817DBB6886DA5A2'
            ExpectedSizeBytes = 7194312
            AuthenticodeStatus = 'Valid'
            SignerPublisher = 'CN=Microsoft Corporation, OU=MOPR, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            FileVersion = '12.0.30501.0'
            ProductVersion = '12.0.30501.0'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = $null
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-visual-cpp-vcredist2013-x64'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadInstaller'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
        }
        @{
            Id = 'visual-cpp-vcredist2013-x86'
            ToolId = 'visual-cpp'
            ToolTitle = 'Visual C++'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 9
            CanonicalOrder = 'Graphics 9'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2013_x86.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2013-x86__vcredist2013_x86.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2013-x86__vcredist2013_x86.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2013-x86__vcredist2013_x86.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 6503984
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2013_x86.exe'
            ExpectedSha256 = 'A22895E55B26202EAE166838EDBE2EA6AAD00D7EA600C11F8A31EDE5CBCE2048'
            ExpectedSha1 = 'DF7F0A73BFA077E483E51BFB97F5E2ECEEDFB6A3'
            ExpectedSizeBytes = 6503984
            AuthenticodeStatus = 'Valid'
            SignerPublisher = 'CN=Microsoft Corporation, OU=MOPR, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            FileVersion = '12.0.30501.0'
            ProductVersion = '12.0.30501.0'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = $null
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-visual-cpp-vcredist2013-x86'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadInstaller'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
        }
        @{
            Id = 'visual-cpp-vcredist2015-2017-2019-2022-x64'
            ToolId = 'visual-cpp'
            ToolTitle = 'Visual C++'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 9
            CanonicalOrder = 'Graphics 9'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2015_2017_2019_2022_x64.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2015-2017-2019-2022-x64__vcredist2015_2017_2019_2022_x64.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2015-2017-2019-2022-x64__vcredist2015_2017_2019_2022_x64.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2015-2017-2019-2022-x64__vcredist2015_2017_2019_2022_x64.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 25635768
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2015_2017_2019_2022_x64.exe'
            ExpectedSha256 = 'CC0FF0EB1DC3F5188AE6300FAEF32BF5BEEBA4BDD6E8E445A9184072096B713B'
            ExpectedSha1 = '21CE0EE54BFF57F69FAFA741025BF2F15B356405'
            ExpectedSizeBytes = 25635768
            AuthenticodeStatus = 'Valid'
            SignerPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            FileVersion = '14.44.35211.0'
            ProductVersion = '14.44.35211.0'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = $null
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-visual-cpp-vcredist2015-2017-2019-2022-x64'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadInstaller'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
        }
        @{
            Id = 'visual-cpp-vcredist2015-2017-2019-2022-x86'
            ToolId = 'visual-cpp'
            ToolTitle = 'Visual C++'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 9
            CanonicalOrder = 'Graphics 9'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2015_2017_2019_2022_x86.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2015-2017-2019-2022-x86__vcredist2015_2017_2019_2022_x86.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2015-2017-2019-2022-x86__vcredist2015_2017_2019_2022_x86.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2015-2017-2019-2022-x86__vcredist2015_2017_2019_2022_x86.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 13953392
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2015_2017_2019_2022_x86.exe'
            ExpectedSha256 = '0C09F2611660441084CE0DF425C51C11E147E6447963C3690F97E0B25C55ED64'
            ExpectedSha1 = 'C2743FFC36D2AF40ADE0E370BE52D6B202874114'
            ExpectedSizeBytes = 13953392
            AuthenticodeStatus = 'Valid'
            SignerPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            FileVersion = '14.44.35211.0'
            ProductVersion = '14.44.35211.0'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = $null
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-visual-cpp-vcredist2015-2017-2019-2022-x86'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadInstaller'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
        }
        @{
            Id = 'bloatware-remote-desktop-connection'
            ToolId = 'bloatware'
            ToolTitle = 'Bloatware'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 11
            CanonicalOrder = 'Windows 11'
            SourceScriptPath = 'source-ultimate/6 Windows/11 Bloatware.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/remotedesktopconnection.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/bloatware-remote-desktop-connection__remotedesktopconnection.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/bloatware-remote-desktop-connection__remotedesktopconnection.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'bloatware-remote-desktop-connection__remotedesktopconnection.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 268344
            MirrorCandidatePath = 'mirrors/bloatware/remotedesktopconnection.exe'
            ExpectedSha256 = 'B3F79EB8432F5C1EBED1E3BAE254541AA87839CDFBCFF4ADD392538B88C46021'
            ExpectedSha1 = 'D3F1F088B431E554EE9C2C6C298C63A572DCB795'
            ExpectedSizeBytes = 268344
            AuthenticodeStatus = 'Valid'
            SignerPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            FileVersion = '10.0.26100.1 (WinBuild.160101.0800)'
            ProductVersion = '10.0.26100.1'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = $null
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-bloatware-remote-desktop-connection'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadInstaller'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
        }
        @{
            Id = 'bloatware-snipping-tool'
            ToolId = 'bloatware'
            ToolTitle = 'Bloatware'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 11
            CanonicalOrder = 'Windows 11'
            SourceScriptPath = 'source-ultimate/6 Windows/11 Bloatware.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/snippingtool.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/bloatware-snipping-tool__snippingtool.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/bloatware-snipping-tool__snippingtool.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'bloatware-snipping-tool__snippingtool.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 260016
            MirrorCandidatePath = 'mirrors/bloatware/snippingtool.exe'
            ExpectedSha256 = 'BDC9E0B26F62CA67E530671EAFD41F67BA8B86121CED44C966D008C7E077B321'
            ExpectedSha1 = '650480BF8B63706539B250DAF5F125D7466FDAB6'
            ExpectedSizeBytes = 260016
            AuthenticodeStatus = 'Valid'
            SignerPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            FileVersion = '10.0.26020.1000 (WinBuild.160101.0800)'
            ProductVersion = '10.0.26020.1000'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = $null
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-bloatware-snipping-tool'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadInstaller'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
        }
        @{
            Id = 'game-bar-edge-webview'
            ToolId = 'game-bar'
            ToolTitle = 'GameBar'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 12
            CanonicalOrder = 'Windows 12'
            SourceScriptPath = 'source-ultimate/6 Windows/12 Gamebar.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edgewebview.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/game-bar-edge-webview__edgewebview.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/game-bar-edge-webview__edgewebview.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'game-bar-edge-webview__edgewebview.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 1683424
            MirrorCandidatePath = 'mirrors/game-bar/edgewebview.exe'
            ExpectedSha256 = '02C97E5E32A97D896163EC68A3EA3AB0339E57F274348B8689399638B649B2B9'
            ExpectedSha1 = 'BFD5343FA72541DE388B346C64B1B67237F906C4'
            ExpectedSizeBytes = 1683424
            AuthenticodeStatus = 'Valid'
            SignerPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            FileVersion = '1.3.225.7'
            ProductVersion = '1.3.225.7'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = 'DUP-SHA256-04'
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-game-bar-edge-webview'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadInstaller'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
        }
        @{
            Id = 'game-bar-gaming-repair-tool'
            ToolId = 'game-bar'
            ToolTitle = 'GameBar'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 12
            CanonicalOrder = 'Windows 12'
            SourceScriptPath = 'source-ultimate/6 Windows/12 Gamebar.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/gamingrepairtool.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/game-bar-gaming-repair-tool__gamingrepairtool.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/game-bar-gaming-repair-tool__gamingrepairtool.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'game-bar-gaming-repair-tool__gamingrepairtool.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 751992
            MirrorCandidatePath = 'mirrors/game-bar/gamingrepairtool.exe'
            ExpectedSha256 = '1EA33E868BDB2C7D1606FD2098C2BD04495DFAEBEBD6E794B32FE72F198598DB'
            ExpectedSha1 = '2C9DCA57673012B0F6CDE764D4DCD80B9B4A1322'
            ExpectedSizeBytes = 751992
            AuthenticodeStatus = 'Valid'
            SignerPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            FileVersion = '10.0.26100.6893 (WinBuild.160101.0800)'
            ProductVersion = '10.0.26100.6893'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = $null
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-game-bar-gaming-repair-tool'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadInstaller'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
        }
        @{
            Id = 'edge-webview-edge-exe'
            ToolId = 'edge-webview'
            ToolTitle = 'Edge & WebView'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 13
            CanonicalOrder = 'Windows 13'
            SourceScriptPath = 'source-ultimate/6 Windows/13 Edge & WebView.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/edge-webview-edge-exe__edge.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/edge-webview-edge-exe__edge.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'edge-webview-edge-exe__edge.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 1683472
            MirrorCandidatePath = 'mirrors/edge-webview/edge.exe'
            ExpectedSha256 = '61A2F3AD5B6DF4167D2FFAFADE138FAE84CB1603C40251D46AA0A8FFA8BFF138'
            ExpectedSha1 = 'EEB875C9A9CDFA6279F9CAC2CE0D36407B2ABADB'
            ExpectedSizeBytes = 1683472
            AuthenticodeStatus = 'Valid'
            SignerPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            FileVersion = '1.3.225.7'
            ProductVersion = '1.3.225.7'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = 'DUP-SHA256-01'
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-edge-webview-edge-exe'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadInstaller'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
        }
        @{
            Id = 'edge-webview-edge-webview'
            ToolId = 'edge-webview'
            ToolTitle = 'Edge & WebView'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 13
            CanonicalOrder = 'Windows 13'
            SourceScriptPath = 'source-ultimate/6 Windows/13 Edge & WebView.ps1'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edgewebview.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            IntendedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/edge-webview-edge-webview__edgewebview.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/edge-webview-edge-webview__edgewebview.exe'
            VerifiedBoostLabMirrorAvailable = $true
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'edge-webview-edge-webview__edgewebview.exe'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            MirrorContentLength = 1683424
            MirrorCandidatePath = 'mirrors/edge-webview/edgewebview.exe'
            ExpectedSha256 = '02C97E5E32A97D896163EC68A3EA3AB0339E57F274348B8689399638B649B2B9'
            ExpectedSha1 = 'BFD5343FA72541DE388B346C64B1B67237F906C4'
            ExpectedSizeBytes = 1683424
            AuthenticodeStatus = 'Valid'
            SignerPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            FileVersion = '1.3.225.7'
            ProductVersion = '1.3.225.7'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            DuplicateHashGroup = 'DUP-SHA256-04'
            BoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            ArtifactProvenanceOnlyApproved = $true
            ArtifactProvenanceId = 'phase164g-edge-webview-edge-webview'
            ProductionAllowlistApproved = $true
            RuntimeSourceSelectionApproved = $true
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
            ReleaseReadiness = 'RuntimeApprovedPendingOfficialVendorDirectClosure'
            MirrorStatus = 'BoostLabMirrorAvailable'
            OperationKind = 'DownloadInstaller'
            Notes = 'Phase 164H approves this verified BoostLab mirror for runtime source selection and production artifact use with filename, size, SHA-256, signature, local-path, and no-direct-network-execution verification gates. OfficialVendorDirect entries remain unchanged.'
        }
    )

}
