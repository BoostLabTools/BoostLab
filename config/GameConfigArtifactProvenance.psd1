@{
    SchemaVersion = '1.0'
    Phase = '165D'
    StageImplemented = $true
    RuntimeSourceSelectionApproved = $true
    ProductionAllowlistApproved = $false
    ReleaseReady = $false
    Release = @{
        Repository = 'BoostLabTools/BoostLab'
        Tag = 'boostlab-game-configs-v1'
        Title = 'BoostLab Game Config Mirrors v1'
        Url = 'https://github.com/BoostLabTools/BoostLab/releases/tag/boostlab-game-configs-v1'
        Prerelease = $true
        Latest = $false
        AssetCount = 28
        HeadVerifiedCount = 28
        HeadVerificationMethod = 'HEAD'
    }
    ProvenanceApprovals = @(
        @{
            Id = 'phase165c-game-configs-arc-raiders'
            ArtifactId = 'game-configs.arc-raiders'
            DisplayName = 'Game Configs - ARC Raiders.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/ARC%20Raiders/ARC%20Raiders.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-arc-raiders__ARC.Raiders.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-arc-raiders__ARC.Raiders.zip'
            ExpectedFileName = 'ARC Raiders.zip'
            ExpectedMirrorAssetName = 'game-configs-arc-raiders__ARC.Raiders.zip'
            ExpectedSha256 = '8E6119B01D1EAA056CF1233F5880EB9A350C10886B961C8BBB2B5AE3D8BA42F9'
            ExpectedSha1 = 'FFA56347B148D69FA94E52028A220B463F7249D4'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'ARC Raiders/ARC Raiders.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-arc-raiders__ARC.Raiders.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 1104
            MirrorContentLength = 1104
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-battlefield-1'
            ArtifactId = 'game-configs.battlefield-1'
            DisplayName = 'Game Configs - Battlefield 1.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Battlefield/Battlefield%201.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-battlefield-1__Battlefield.1.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-battlefield-1__Battlefield.1.zip'
            ExpectedFileName = 'Battlefield 1.zip'
            ExpectedMirrorAssetName = 'game-configs-battlefield-1__Battlefield.1.zip'
            ExpectedSha256 = '92351A54A05421CC88799929D144DC99AFEDDA82CA582B5AD0FDD3F009E6F93A'
            ExpectedSha1 = 'E17229045CC1B0613FC54A119FA8A624BF542936'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Battlefield/Battlefield 1.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-battlefield-1__Battlefield.1.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 5689
            MirrorContentLength = 5689
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-battlefield-2042'
            ArtifactId = 'game-configs.battlefield-2042'
            DisplayName = 'Game Configs - Battlefield 2042.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Battlefield/Battlefield%202042.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-battlefield-2042__Battlefield.2042.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-battlefield-2042__Battlefield.2042.zip'
            ExpectedFileName = 'Battlefield 2042.zip'
            ExpectedMirrorAssetName = 'game-configs-battlefield-2042__Battlefield.2042.zip'
            ExpectedSha256 = 'BB4BBAC075E495A77AD603F54ED5467AA14C5E959341D910B400E8A3ADBAFB5E'
            ExpectedSha1 = 'F6A744E2EACE63C6FDD6A2220E04F5C73D8E0576'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Battlefield/Battlefield 2042.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-battlefield-2042__Battlefield.2042.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 1873
            MirrorContentLength = 1873
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-battlefield-3'
            ArtifactId = 'game-configs.battlefield-3'
            DisplayName = 'Game Configs - Battlefield 3.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Battlefield/Battlefield%203.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-battlefield-3__Battlefield.3.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-battlefield-3__Battlefield.3.zip'
            ExpectedFileName = 'Battlefield 3.zip'
            ExpectedMirrorAssetName = 'game-configs-battlefield-3__Battlefield.3.zip'
            ExpectedSha256 = 'D6C794F5329F395DE71690B9953D803DEADA44C7A087F06D9C5CE3275CFE8802'
            ExpectedSha1 = 'F7371BAF424034E5903F6AC75CAC22E6ED8F6EDC'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Battlefield/Battlefield 3.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-battlefield-3__Battlefield.3.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 1078
            MirrorContentLength = 1078
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-battlefield-4'
            ArtifactId = 'game-configs.battlefield-4'
            DisplayName = 'Game Configs - Battlefield 4.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Battlefield/Battlefield%204.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-battlefield-4__Battlefield.4.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-battlefield-4__Battlefield.4.zip'
            ExpectedFileName = 'Battlefield 4.zip'
            ExpectedMirrorAssetName = 'game-configs-battlefield-4__Battlefield.4.zip'
            ExpectedSha256 = 'D8D8293736F71C2B186BF2FBA4C90BEB306F26B786A0DEEAB910B890F70C0D28'
            ExpectedSha1 = '5BA47D08D831601BFD0CC0FCDA2E613FA90E0194'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Battlefield/Battlefield 4.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-battlefield-4__Battlefield.4.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 919
            MirrorContentLength = 919
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-battlefield-6'
            ArtifactId = 'game-configs.battlefield-6'
            DisplayName = 'Game Configs - Battlefield 6.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Battlefield/Battlefield%206.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-battlefield-6__Battlefield.6.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-battlefield-6__Battlefield.6.zip'
            ExpectedFileName = 'Battlefield 6.zip'
            ExpectedMirrorAssetName = 'game-configs-battlefield-6__Battlefield.6.zip'
            ExpectedSha256 = 'B87C7DFA83E1A374AAD8B64C314DB11DC5E8527559EE76F4F1EB4AEAF2637712'
            ExpectedSha1 = '88D442742066853AFB31E9D4C03F1683B2A13DDB'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Battlefield/Battlefield 6.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-battlefield-6__Battlefield.6.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 4428
            MirrorContentLength = 4428
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-battlefield-bad-company-2'
            ArtifactId = 'game-configs.battlefield-bad-company-2'
            DisplayName = 'Game Configs - Battlefield Bad Company 2.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Battlefield/Battlefield%20Bad%20Company%202.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-battlefield-bad-company-2__Battlefield.Bad.Company.2.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-battlefield-bad-company-2__Battlefield.Bad.Company.2.zip'
            ExpectedFileName = 'Battlefield Bad Company 2.zip'
            ExpectedMirrorAssetName = 'game-configs-battlefield-bad-company-2__Battlefield.Bad.Company.2.zip'
            ExpectedSha256 = '08755C09CABC3AACA35D2F86465BB49F6F35D9038E30D6E79AF6F1A701C94310'
            ExpectedSha1 = '9803707B74A38952381AA674325104CF10C58B80'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Battlefield/Battlefield Bad Company 2.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-battlefield-bad-company-2__Battlefield.Bad.Company.2.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 161706
            MirrorContentLength = 161706
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-battlefield-hardline'
            ArtifactId = 'game-configs.battlefield-hardline'
            DisplayName = 'Game Configs - Battlefield Hardline.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Battlefield/Battlefield%20Hardline.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-battlefield-hardline__Battlefield.Hardline.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-battlefield-hardline__Battlefield.Hardline.zip'
            ExpectedFileName = 'Battlefield Hardline.zip'
            ExpectedMirrorAssetName = 'game-configs-battlefield-hardline__Battlefield.Hardline.zip'
            ExpectedSha256 = 'F79ED37A0304449335B6AAFD4BDB76D89F6D1BAF5C59B7578CE65F15DEECA5C6'
            ExpectedSha1 = '6D117C58BF4A6F9061DA6EC05E10654748DC2B66'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Battlefield/Battlefield Hardline.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-battlefield-hardline__Battlefield.Hardline.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 2052
            MirrorContentLength = 2052
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-battlefield-v'
            ArtifactId = 'game-configs.battlefield-v'
            DisplayName = 'Game Configs - Battlefield V.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Battlefield/Battlefield%20V.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-battlefield-v__Battlefield.V.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-battlefield-v__Battlefield.V.zip'
            ExpectedFileName = 'Battlefield V.zip'
            ExpectedMirrorAssetName = 'game-configs-battlefield-v__Battlefield.V.zip'
            ExpectedSha256 = '9E25E595C440EF4435E351B1DC8C6F01726EA11997E297E87F4DA5172A544546'
            ExpectedSha1 = '25FF01ACB941283D528B811B7D061EC614B19086'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Battlefield/Battlefield V.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-battlefield-v__Battlefield.V.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 7530
            MirrorContentLength = 7530
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-call-of-duty-black-ops-4'
            ArtifactId = 'game-configs.call-of-duty-black-ops-4'
            DisplayName = 'Game Configs - Call of Duty Black Ops 4.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Call%20of%20Duty/Call%20of%20Duty%20Black%20Ops%204.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-call-of-duty-black-ops-4__Call.of.Duty.Black.Ops.4.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-call-of-duty-black-ops-4__Call.of.Duty.Black.Ops.4.zip'
            ExpectedFileName = 'Call of Duty Black Ops 4.zip'
            ExpectedMirrorAssetName = 'game-configs-call-of-duty-black-ops-4__Call.of.Duty.Black.Ops.4.zip'
            ExpectedSha256 = '05864B0915EEBA0FE1FE5B9BBC3FA2CF26B3840FC238D1426B9E01ADC7C349BA'
            ExpectedSha1 = '671359C46221861DF77339D37835CAE028505043'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Call of Duty/Call of Duty Black Ops 4.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-call-of-duty-black-ops-4__Call.of.Duty.Black.Ops.4.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 6601
            MirrorContentLength = 6601
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-call-of-duty-black-ops-6'
            ArtifactId = 'game-configs.call-of-duty-black-ops-6'
            DisplayName = 'Game Configs - Call of Duty Black Ops 6.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Call%20of%20Duty/Call%20of%20Duty%20Black%20Ops%206.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-call-of-duty-black-ops-6__Call.of.Duty.Black.Ops.6.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-call-of-duty-black-ops-6__Call.of.Duty.Black.Ops.6.zip'
            ExpectedFileName = 'Call of Duty Black Ops 6.zip'
            ExpectedMirrorAssetName = 'game-configs-call-of-duty-black-ops-6__Call.of.Duty.Black.Ops.6.zip'
            ExpectedSha256 = '05F2E47137C62ECC13FBB3C55EB85B6088E96E7B8D86DFD97FD351EE586936E7'
            ExpectedSha1 = '47CDC7183E25B7D0E746BD20925A97373DEA696E'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Call of Duty/Call of Duty Black Ops 6.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-call-of-duty-black-ops-6__Call.of.Duty.Black.Ops.6.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 34446
            MirrorContentLength = 34446
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-call-of-duty-black-ops-7'
            ArtifactId = 'game-configs.call-of-duty-black-ops-7'
            DisplayName = 'Game Configs - Call of Duty Black Ops 7.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Call%20of%20Duty/Call%20of%20Duty%20Black%20Ops%207.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-call-of-duty-black-ops-7__Call.of.Duty.Black.Ops.7.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-call-of-duty-black-ops-7__Call.of.Duty.Black.Ops.7.zip'
            ExpectedFileName = 'Call of Duty Black Ops 7.zip'
            ExpectedMirrorAssetName = 'game-configs-call-of-duty-black-ops-7__Call.of.Duty.Black.Ops.7.zip'
            ExpectedSha256 = '02437F4AD94E4640259D160BBB58BBBC37E42281518672DCD20A12D690AC20A1'
            ExpectedSha1 = '95CA8BE802E42205871B0A2C6BAA8BE40B3BF1A9'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Call of Duty/Call of Duty Black Ops 7.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-call-of-duty-black-ops-7__Call.of.Duty.Black.Ops.7.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 11514
            MirrorContentLength = 11514
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-call-of-duty-black-ops-cold-war'
            ArtifactId = 'game-configs.call-of-duty-black-ops-cold-war'
            DisplayName = 'Game Configs - Call of Duty Black Ops Cold War.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Call%20of%20Duty/Call%20of%20Duty%20Black%20Ops%20Cold%20War.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-call-of-duty-black-ops-cold-war__Call.of.Duty.Black.Ops.Cold.War.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-call-of-duty-black-ops-cold-war__Call.of.Duty.Black.Ops.Cold.War.zip'
            ExpectedFileName = 'Call of Duty Black Ops Cold War.zip'
            ExpectedMirrorAssetName = 'game-configs-call-of-duty-black-ops-cold-war__Call.of.Duty.Black.Ops.Cold.War.zip'
            ExpectedSha256 = 'BF500CABA3519CB5DB0C53E99C04DC57EC8DF8FED6A8F1EA95E5E3F80EF4F299'
            ExpectedSha1 = '504832A69A7433E909C97470E25191DED7777B82'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Call of Duty/Call of Duty Black Ops Cold War.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-call-of-duty-black-ops-cold-war__Call.of.Duty.Black.Ops.Cold.War.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 6758
            MirrorContentLength = 6758
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-call-of-duty-modern-warfare-2019'
            ArtifactId = 'game-configs.call-of-duty-modern-warfare-2019'
            DisplayName = 'Game Configs - Call of Duty Modern Warfare 2019.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Call%20of%20Duty/Call%20of%20Duty%20Modern%20Warfare%202019.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-call-of-duty-modern-warfare-2019__Call.of.Duty.Modern.Warfare.2019.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-call-of-duty-modern-warfare-2019__Call.of.Duty.Modern.Warfare.2019.zip'
            ExpectedFileName = 'Call of Duty Modern Warfare 2019.zip'
            ExpectedMirrorAssetName = 'game-configs-call-of-duty-modern-warfare-2019__Call.of.Duty.Modern.Warfare.2019.zip'
            ExpectedSha256 = '1D0AF950A214943073E16300CB278F74D81785BCD9A212CFB5AFD734A51D9230'
            ExpectedSha1 = 'B7A62B9C9BD557774EEEFCECA41CF803DF7E4916'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Call of Duty/Call of Duty Modern Warfare 2019.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-call-of-duty-modern-warfare-2019__Call.of.Duty.Modern.Warfare.2019.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 3130
            MirrorContentLength = 3130
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-call-of-duty-modern-warfare-2-2022'
            ArtifactId = 'game-configs.call-of-duty-modern-warfare-2-2022'
            DisplayName = 'Game Configs - Call of Duty Modern Warfare 2 2022.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Call%20of%20Duty/Call%20of%20Duty%20Modern%20Warfare%202%202022.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-call-of-duty-modern-warfare-2-2022__Call.of.Duty.Modern.Warfare.2.2022.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-call-of-duty-modern-warfare-2-2022__Call.of.Duty.Modern.Warfare.2.2022.zip'
            ExpectedFileName = 'Call of Duty Modern Warfare 2 2022.zip'
            ExpectedMirrorAssetName = 'game-configs-call-of-duty-modern-warfare-2-2022__Call.of.Duty.Modern.Warfare.2.2022.zip'
            ExpectedSha256 = '4E428676AA754A38155C66711188E48AFCAEA5C732A23DC8D51DC69C39057E0B'
            ExpectedSha1 = 'AF0DAC15ACCE4B34279AD0A715557E2E51B25495'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Call of Duty/Call of Duty Modern Warfare 2 2022.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-call-of-duty-modern-warfare-2-2022__Call.of.Duty.Modern.Warfare.2.2022.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 16505
            MirrorContentLength = 16505
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-call-of-duty-modern-warfare-3-2023'
            ArtifactId = 'game-configs.call-of-duty-modern-warfare-3-2023'
            DisplayName = 'Game Configs - Call of Duty Modern Warfare 3 2023.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Call%20of%20Duty/Call%20of%20Duty%20Modern%20Warfare%203%202023.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-call-of-duty-modern-warfare-3-2023__Call.of.Duty.Modern.Warfare.3.2023.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-call-of-duty-modern-warfare-3-2023__Call.of.Duty.Modern.Warfare.3.2023.zip'
            ExpectedFileName = 'Call of Duty Modern Warfare 3 2023.zip'
            ExpectedMirrorAssetName = 'game-configs-call-of-duty-modern-warfare-3-2023__Call.of.Duty.Modern.Warfare.3.2023.zip'
            ExpectedSha256 = 'A1D08D7DFD347132447A9043771AA92011D3C3FC765E9AF9BD247D5036046AC8'
            ExpectedSha1 = '03C24FFB2E242F3B6A902A60DAAE089C40E0AE4B'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Call of Duty/Call of Duty Modern Warfare 3 2023.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-call-of-duty-modern-warfare-3-2023__Call.of.Duty.Modern.Warfare.3.2023.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 16407
            MirrorContentLength = 16407
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-call-of-duty-vanguard'
            ArtifactId = 'game-configs.call-of-duty-vanguard'
            DisplayName = 'Game Configs - Call of Duty Vanguard.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Call%20of%20Duty/Call%20of%20Duty%20Vanguard.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-call-of-duty-vanguard__Call.of.Duty.Vanguard.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-call-of-duty-vanguard__Call.of.Duty.Vanguard.zip'
            ExpectedFileName = 'Call of Duty Vanguard.zip'
            ExpectedMirrorAssetName = 'game-configs-call-of-duty-vanguard__Call.of.Duty.Vanguard.zip'
            ExpectedSha256 = '861C8D09A1D142BF3F87864B339EA05AFBD6223C8070C83F383B7D03CF3C7FB2'
            ExpectedSha1 = '05D3B5965B4A857ADB92034F49263333EBA0CF0E'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Call of Duty/Call of Duty Vanguard.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-call-of-duty-vanguard__Call.of.Duty.Vanguard.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 6349
            MirrorContentLength = 6349
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-counter-strike-2'
            ArtifactId = 'game-configs.counter-strike-2'
            DisplayName = 'Game Configs - Counter Strike 2.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Counter%20Strike%202/Counter%20Strike%202.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-counter-strike-2__Counter.Strike.2.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-counter-strike-2__Counter.Strike.2.zip'
            ExpectedFileName = 'Counter Strike 2.zip'
            ExpectedMirrorAssetName = 'game-configs-counter-strike-2__Counter.Strike.2.zip'
            ExpectedSha256 = '9401BF2027833101D203DF9EB49DCF1A6904FDFE3E63E142A9051CEA647D8665'
            ExpectedSha1 = '4CF43B442F879758AC7263F9DFE723CFECB06F60'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Counter Strike 2/Counter Strike 2.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-counter-strike-2__Counter.Strike.2.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 1016
            MirrorContentLength = 1016
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-delta-force'
            ArtifactId = 'game-configs.delta-force'
            DisplayName = 'Game Configs - Delta Force.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Delta%20Force/Delta%20Force.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-delta-force__Delta.Force.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-delta-force__Delta.Force.zip'
            ExpectedFileName = 'Delta Force.zip'
            ExpectedMirrorAssetName = 'game-configs-delta-force__Delta.Force.zip'
            ExpectedSha256 = '5A94147507D31BDAD113AA2227AD39379159EA8E83D8D34304CEC7134A558826'
            ExpectedSha1 = '51F8941D9009BA78F12C5C771EA73AA1F3E2CBD6'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Delta Force/Delta Force.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-delta-force__Delta.Force.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 5052
            MirrorContentLength = 5052
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-frag-punk'
            ArtifactId = 'game-configs.frag-punk'
            DisplayName = 'Game Configs - Frag Punk.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Frag%20Punk/Frag%20Punk.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-frag-punk__Frag.Punk.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-frag-punk__Frag.Punk.zip'
            ExpectedFileName = 'Frag Punk.zip'
            ExpectedMirrorAssetName = 'game-configs-frag-punk__Frag.Punk.zip'
            ExpectedSha256 = '0E332682C735021AA7197638A92229E559B9A56492B7A9FF891AF6D260C26187'
            ExpectedSha1 = 'CFB8B69A07554EC718FF05561A32A749AF1A10D1'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Frag Punk/Frag Punk.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-frag-punk__Frag.Punk.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 9715
            MirrorContentLength = 9715
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-marvel-rivals'
            ArtifactId = 'game-configs.marvel-rivals'
            DisplayName = 'Game Configs - Marvel Rivals.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Marvel%20Rivals/Marvel%20Rivals.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-marvel-rivals__Marvel.Rivals.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-marvel-rivals__Marvel.Rivals.zip'
            ExpectedFileName = 'Marvel Rivals.zip'
            ExpectedMirrorAssetName = 'game-configs-marvel-rivals__Marvel.Rivals.zip'
            ExpectedSha256 = '88027AA368D60146A03392C608B097A8AACF4B53BF4519876E72B4A28E43ABE9'
            ExpectedSha1 = '871CD2833C0EB796767BB13394307B6A817D589C'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Marvel Rivals/Marvel Rivals.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-marvel-rivals__Marvel.Rivals.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 1902
            MirrorContentLength = 1902
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-profile-inspector-inspector-exe'
            ArtifactId = 'game-configs.profile-inspector.inspector-exe'
            DisplayName = 'Game Configs - inspector.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/inspector.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-profile-inspector-inspector-exe__inspector.exe'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-profile-inspector-inspector-exe__inspector.exe'
            ExpectedFileName = 'inspector.exe'
            ExpectedMirrorAssetName = 'game-configs-profile-inspector-inspector-exe__inspector.exe'
            ExpectedSha256 = '7D5510DEEAACB50C88A49BBF1D894DAE44C5CE58C00D5A88392346646B14E8F3'
            ExpectedSha1 = 'FB8A3490780107C504F4D135CC4BEC02E19AC2F6'
            AuthenticodeStatus = 'NotSigned'
            ExpectedPublisher = $null
            FileVersion = '2.4.0.31'
            ProductVersion = '2.4.0.31'
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Battlefield/Battlefield 6.ps1; Frag Punk/Frag Punk.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-profile-inspector-inspector-exe__inspector.exe'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 643072
            MirrorContentLength = 643072
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $true
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'UnsignedExecutableExactHash'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-pubg-battlegrounds'
            ArtifactId = 'game-configs.pubg-battlegrounds'
            DisplayName = 'Game Configs - PUBG BATTLEGROUNDS.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/PUBG%20BATTLEGROUNDS/PUBG%20BATTLEGROUNDS.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-pubg-battlegrounds__PUBG.BATTLEGROUNDS.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-pubg-battlegrounds__PUBG.BATTLEGROUNDS.zip'
            ExpectedFileName = 'PUBG BATTLEGROUNDS.zip'
            ExpectedMirrorAssetName = 'game-configs-pubg-battlegrounds__PUBG.BATTLEGROUNDS.zip'
            ExpectedSha256 = 'F32848AB668479FBB3418732028A1C500FB2DDD78B7D7709A12498473561223F'
            ExpectedSha1 = '91DFB7DDF92B59038F384CDDA5302A0AAA2BAE1F'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'PUBG BATTLEGROUNDS/PUBG BATTLEGROUNDS.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-pubg-battlegrounds__PUBG.BATTLEGROUNDS.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 26153
            MirrorContentLength = 26153
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-splitgate-1'
            ArtifactId = 'game-configs.splitgate-1'
            DisplayName = 'Game Configs - Splitgate 1.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Splitgate/Splitgate%201.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-splitgate-1__Splitgate.1.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-splitgate-1__Splitgate.1.zip'
            ExpectedFileName = 'Splitgate 1.zip'
            ExpectedMirrorAssetName = 'game-configs-splitgate-1__Splitgate.1.zip'
            ExpectedSha256 = 'F59A93341667A31446BDCAB6705C4AC9E7F10B229A263CDBB46F7DC345CB8B3B'
            ExpectedSha1 = '0887F735E9016F68F2F6FAE367881CEE71D8281D'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Splitgate/Splitgate 1.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-splitgate-1__Splitgate.1.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 639
            MirrorContentLength = 639
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-splitgate-2'
            ArtifactId = 'game-configs.splitgate-2'
            DisplayName = 'Game Configs - Splitgate 2.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Splitgate/Splitgate%202.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-splitgate-2__Splitgate.2.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-splitgate-2__Splitgate.2.zip'
            ExpectedFileName = 'Splitgate 2.zip'
            ExpectedMirrorAssetName = 'game-configs-splitgate-2__Splitgate.2.zip'
            ExpectedSha256 = '2B67E8643F07C4007154DBD7850423175E44D5B6EE0715A31BC84947B4ABD58F'
            ExpectedSha1 = 'F1CF7DB43960CCA54FC57A0FDAE1F8ADF7BEE20E'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'Splitgate/Splitgate 2.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-splitgate-2__Splitgate.2.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 1167
            MirrorContentLength = 1167
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-star-wars-battlefront-i-2015'
            ArtifactId = 'game-configs.star-wars-battlefront-i-2015'
            DisplayName = 'Game Configs - STAR WARS Battlefront I 2015.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/STAR%20WARS%20Battlefront/STAR%20WARS%20Battlefront%20I%202015.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-star-wars-battlefront-i-2015__STAR.WARS.Battlefront.I.2015.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-star-wars-battlefront-i-2015__STAR.WARS.Battlefront.I.2015.zip'
            ExpectedFileName = 'STAR WARS Battlefront I 2015.zip'
            ExpectedMirrorAssetName = 'game-configs-star-wars-battlefront-i-2015__STAR.WARS.Battlefront.I.2015.zip'
            ExpectedSha256 = '0937796E96BE17AAFABFC371FED2D8784EE4D3B8443EEED9ED0FAD58BDFABCD9'
            ExpectedSha1 = '4D7517E3E06CDB9D808EE0F2521DDF14069CFC9E'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'STAR WARS Battlefront/STAR WARS Battlefront I 2015.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-star-wars-battlefront-i-2015__STAR.WARS.Battlefront.I.2015.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 2086
            MirrorContentLength = 2086
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-star-wars-battlefront-ii-2017'
            ArtifactId = 'game-configs.star-wars-battlefront-ii-2017'
            DisplayName = 'Game Configs - STAR WARS Battlefront II 2017.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/STAR%20WARS%20Battlefront/STAR%20WARS%20Battlefront%20II%202017.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-star-wars-battlefront-ii-2017__STAR.WARS.Battlefront.II.2017.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-star-wars-battlefront-ii-2017__STAR.WARS.Battlefront.II.2017.zip'
            ExpectedFileName = 'STAR WARS Battlefront II 2017.zip'
            ExpectedMirrorAssetName = 'game-configs-star-wars-battlefront-ii-2017__STAR.WARS.Battlefront.II.2017.zip'
            ExpectedSha256 = 'E39FBD225F1472A88E171873E18B7806A799BF09E8D4C1261A9A38AA3549E4B5'
            ExpectedSha1 = '9CBD46735C3281DDB21D333BE62B0764176BC054'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'STAR WARS Battlefront/STAR WARS Battlefront II 2017.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-star-wars-battlefront-ii-2017__STAR.WARS.Battlefront.II.2017.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 2217
            MirrorContentLength = 2217
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
        @{
            Id = 'phase165c-game-configs-the-finals'
            ArtifactId = 'game-configs.the-finals'
            DisplayName = 'Game Configs - The Finals.zip'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/The%20Finals/The%20Finals.zip'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/game-configs-the-finals__The.Finals.zip'
            MirrorReleaseTag = 'boostlab-game-configs-v1'
            MirrorAssetName = 'game-configs-the-finals__The.Finals.zip'
            ExpectedFileName = 'The Finals.zip'
            ExpectedMirrorAssetName = 'game-configs-the-finals__The.Finals.zip'
            ExpectedSha256 = 'FD198ADCE2D1942DBFAE8AA65E4E3B0781E52B3FD6BCD414641100BCD05124E2'
            ExpectedSha1 = 'DFF336DE9F1D64255BF56D41475DA7F1F9BB7040'
            AuthenticodeStatus = 'NotApplicableZipPayload'
            ExpectedPublisher = $null
            FileVersion = $null
            ProductVersion = $null
            SourceToolId = 'game-configs'
            SourceToolTitle = 'Game Configs'
            SourceRecipePath = 'The Finals/The Finals.ps1'
            MirrorCandidatePath = 'game-configs/game-configs-the-finals__The.Finals.zip'
            EvidenceSource = 'Phase165BLocalIntake'
            EvidenceCapturedAt = 'Phase165B'
            MirrorVerifiedAt = 'Phase165C'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '200'
            ApprovalStatus = 'ApprovedForStage8Runtime'
            YazanApprovalSource = 'Phase165C'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'Stage8RuntimeImplemented'
            ExpectedSizeBytes = 1959
            MirrorContentLength = 1959
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $true
            CanReboot = $false
            RuntimeSourceSelectionApproved = $true
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $true
            ReleaseReady = $false
            SourceToolIds = @(
                'game-configs'
            )
            EvidencePhases = @(
                'Phase165B'
                'Phase165C'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 165C Game Config payload mirror metadata'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'ArchivePayload'
            )
            Constraints = @(
                'Stage 8 Game Configs runtime is implemented in Phase 165D.'
                'Runtime source selection is approved only through verified BoostLab mirrors for the native Stage 8 Game Configs runtime.'
                'Raw upstream Github-Game-Configs URLs are not approved final runtime sources.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'No direct network execution is approved.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for native Stage 8 Game Configs runtime source selection with local file name, SHA-256, and size verification. This record does not approve production allowlist scope, installers, or direct network execution.'
        }
    )
}


