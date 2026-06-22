@{
    SchemaVersion = '1.0'

    # Phase 35 keeps runtime artifact execution deny-by-default.
    # Phase 164G adds provenance-only approvals for verified BoostLab mirror
    # evidence. These records are not production allowlist approvals, do not
    # switch runtime URLs, and do not permit download or installer execution.
    Artifacts = @()

    ProvenanceOnlyApprovalStatuses = @(
        'ApprovedForProvenanceOnly'
    )

    ProvenanceOnlyApprovals = @(
        @{
            Id = 'phase164g-reinstall-windows11-media-creation-tool'
            ArtifactId = 'reinstall-windows11-media-creation-tool'
            DisplayName = 'Reinstall - mediacreationtoolw11.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw11.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/reinstall-windows11-media-creation-tool__mediacreationtoolw11.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'reinstall-windows11-media-creation-tool__mediacreationtoolw11.exe'
            ExpectedFileName = 'mediacreationtoolw11.exe'
            ExpectedMirrorAssetName = 'reinstall-windows11-media-creation-tool__mediacreationtoolw11.exe'
            ExpectedSha256 = 'E887DFFF70BAF09A8C1DEBFE8C304DD9F2D9652FAE8B7C83B3C24554A79BBD7F'
            ExpectedSha1 = 'A65AB70110BE0862AA3A05845C15E72DDD588752'
            AuthenticodeStatus = 'Valid'
            ExpectedPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            SourceToolId = 'reinstall'
            SourceToolTitle = 'Reinstall'
            SourceScriptPath = 'source-ultimate/2 Refresh/1 Reinstall.ps1'
            MirrorCandidatePath = 'mirrors/reinstall/mediacreationtoolw11.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 21591048
            MirrorContentLength = 21591048
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'reinstall'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'AuthenticodeSigner'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-edge-settings-edge-exe'
            ArtifactId = 'edge-settings-edge-exe'
            DisplayName = 'Edge Settings - edge.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/edge-settings-edge-exe__edge.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'edge-settings-edge-exe__edge.exe'
            ExpectedFileName = 'edge.exe'
            ExpectedMirrorAssetName = 'edge-settings-edge-exe__edge.exe'
            ExpectedSha256 = '61A2F3AD5B6DF4167D2FFAFADE138FAE84CB1603C40251D46AA0A8FFA8BFF138'
            ExpectedSha1 = 'EEB875C9A9CDFA6279F9CAC2CE0D36407B2ABADB'
            AuthenticodeStatus = 'Valid'
            ExpectedPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            SourceToolId = 'edge-settings'
            SourceToolTitle = 'Edge Settings'
            SourceScriptPath = 'source-ultimate/3 Setup/6 Edge Settings.ps1'
            MirrorCandidatePath = 'mirrors/edge-settings/edge.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 1683472
            MirrorContentLength = 1683472
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'edge-settings'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'AuthenticodeSigner'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-driver-clean-ddu'
            ArtifactId = 'driver-clean-ddu'
            DisplayName = 'Driver Clean - ddu.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/ddu.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/driver-clean-ddu__ddu.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'driver-clean-ddu__ddu.exe'
            ExpectedFileName = 'ddu.exe'
            ExpectedMirrorAssetName = 'driver-clean-ddu__ddu.exe'
            ExpectedSha256 = '6073E6D311290D45B7A8AE4E832994C9487082531F89E4E01C99F86C0E38DA6C'
            ExpectedSha1 = '9F95FA4EDB7E8D94E833D8CCCEA9A1C0FAE661CE'
            AuthenticodeStatus = 'Valid'
            ExpectedPublisher = 'CN=Wagnardsoft, O=Wagnardsoft, S=Quebec, C=CA'
            SourceToolId = 'driver-clean'
            SourceToolTitle = 'Driver Clean'
            SourceScriptPath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/1 Driver Clean.ps1'
            MirrorCandidatePath = 'mirrors/driver-clean/ddu.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 1717592
            MirrorContentLength = 1717592
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'driver-clean'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'AuthenticodeSigner'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-driver-clean-seven-zip'
            ArtifactId = 'driver-clean-seven-zip'
            DisplayName = 'Driver Clean - 7zip.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/driver-clean-seven-zip__7zip.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'driver-clean-seven-zip__7zip.exe'
            ExpectedFileName = '7zip.exe'
            ExpectedMirrorAssetName = 'driver-clean-seven-zip__7zip.exe'
            ExpectedSha256 = '26CB6E9F56333682122FAFE79DBCDFD51E9F47CC7217DCCD29AC6FC33B5598CD'
            ExpectedSha1 = '7DF28D340D7084647921CC25A8C2068BB192BDBB'
            AuthenticodeStatus = 'NotSigned'
            ExpectedPublisher = ''
            SourceToolId = 'driver-clean'
            SourceToolTitle = 'Driver Clean'
            SourceScriptPath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/1 Driver Clean.ps1'
            MirrorCandidatePath = 'mirrors/driver-clean/7zip.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 1589510
            MirrorContentLength = 1589510
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'driver-clean'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-driver-install-debloat-settings-inspector'
            ArtifactId = 'driver-install-debloat-settings-inspector'
            DisplayName = 'Driver Install Debloat & Settings - inspector.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/inspector.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/driver-install-debloat-settings-inspector__inspector.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'driver-install-debloat-settings-inspector__inspector.exe'
            ExpectedFileName = 'inspector.exe'
            ExpectedMirrorAssetName = 'driver-install-debloat-settings-inspector__inspector.exe'
            ExpectedSha256 = '7D5510DEEAACB50C88A49BBF1D894DAE44C5CE58C00D5A88392346646B14E8F3'
            ExpectedSha1 = 'FB8A3490780107C504F4D135CC4BEC02E19AC2F6'
            AuthenticodeStatus = 'NotSigned'
            ExpectedPublisher = ''
            SourceToolId = 'driver-install-debloat-settings'
            SourceToolTitle = 'Driver Install Debloat & Settings'
            SourceScriptPath = 'source-ultimate/5 Graphics/1 Driver Install Debloat & Settings.ps1'
            MirrorCandidatePath = 'mirrors/driver-install-debloat-settings/inspector.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 643072
            MirrorContentLength = 643072
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'driver-install-debloat-settings'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-driver-install-debloat-settings-seven-zip'
            ArtifactId = 'driver-install-debloat-settings-seven-zip'
            DisplayName = 'Driver Install Debloat & Settings - 7zip.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/driver-install-debloat-settings-seven-zip__7zip.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'driver-install-debloat-settings-seven-zip__7zip.exe'
            ExpectedFileName = '7zip.exe'
            ExpectedMirrorAssetName = 'driver-install-debloat-settings-seven-zip__7zip.exe'
            ExpectedSha256 = '26CB6E9F56333682122FAFE79DBCDFD51E9F47CC7217DCCD29AC6FC33B5598CD'
            ExpectedSha1 = '7DF28D340D7084647921CC25A8C2068BB192BDBB'
            AuthenticodeStatus = 'NotSigned'
            ExpectedPublisher = ''
            SourceToolId = 'driver-install-debloat-settings'
            SourceToolTitle = 'Driver Install Debloat & Settings'
            SourceScriptPath = 'source-ultimate/5 Graphics/1 Driver Install Debloat & Settings.ps1'
            MirrorCandidatePath = 'mirrors/driver-install-debloat-settings/7zip.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 1589510
            MirrorContentLength = 1589510
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'driver-install-debloat-settings'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-nvidia-settings-inspector'
            ArtifactId = 'nvidia-settings-inspector'
            DisplayName = 'Nvidia Settings - inspector.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/inspector.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/nvidia-settings-inspector__inspector.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'nvidia-settings-inspector__inspector.exe'
            ExpectedFileName = 'inspector.exe'
            ExpectedMirrorAssetName = 'nvidia-settings-inspector__inspector.exe'
            ExpectedSha256 = '7D5510DEEAACB50C88A49BBF1D894DAE44C5CE58C00D5A88392346646B14E8F3'
            ExpectedSha1 = 'FB8A3490780107C504F4D135CC4BEC02E19AC2F6'
            AuthenticodeStatus = 'NotSigned'
            ExpectedPublisher = ''
            SourceToolId = 'nvidia-settings'
            SourceToolTitle = 'Nvidia Settings'
            SourceScriptPath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
            MirrorCandidatePath = 'mirrors/nvidia-settings/inspector.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 643072
            MirrorContentLength = 643072
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'nvidia-settings'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-nvidia-settings-seven-zip'
            ArtifactId = 'nvidia-settings-seven-zip'
            DisplayName = 'Nvidia Settings - 7zip.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/nvidia-settings-seven-zip__7zip.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'nvidia-settings-seven-zip__7zip.exe'
            ExpectedFileName = '7zip.exe'
            ExpectedMirrorAssetName = 'nvidia-settings-seven-zip__7zip.exe'
            ExpectedSha256 = '26CB6E9F56333682122FAFE79DBCDFD51E9F47CC7217DCCD29AC6FC33B5598CD'
            ExpectedSha1 = '7DF28D340D7084647921CC25A8C2068BB192BDBB'
            AuthenticodeStatus = 'NotSigned'
            ExpectedPublisher = ''
            SourceToolId = 'nvidia-settings'
            SourceToolTitle = 'Nvidia Settings'
            SourceScriptPath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
            MirrorCandidatePath = 'mirrors/nvidia-settings/7zip.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 1589510
            MirrorContentLength = 1589510
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'nvidia-settings'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-directx-runtime-package'
            ArtifactId = 'directx-runtime-package'
            DisplayName = 'DirectX - directx.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/directx.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/directx-runtime-package__directx.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'directx-runtime-package__directx.exe'
            ExpectedFileName = 'directx.exe'
            ExpectedMirrorAssetName = 'directx-runtime-package__directx.exe'
            ExpectedSha256 = '053F76DCBB28802E23341B6A787E3B0791C0FA5C8D4D011B1044172DBF89C73B'
            ExpectedSha1 = '7E5D2E5E1A13FBC47F990CC55CBDB428CD12F759'
            AuthenticodeStatus = 'Valid'
            ExpectedPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            SourceToolId = 'directx'
            SourceToolTitle = 'DirectX'
            SourceScriptPath = 'source-ultimate/5 Graphics/2 DirectX.ps1'
            MirrorCandidatePath = 'mirrors/directx/directx.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 100275120
            MirrorContentLength = 100275120
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'directx'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'AuthenticodeSigner'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-directx-seven-zip'
            ArtifactId = 'directx-seven-zip'
            DisplayName = 'DirectX - 7zip.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/directx-seven-zip__7zip.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'directx-seven-zip__7zip.exe'
            ExpectedFileName = '7zip.exe'
            ExpectedMirrorAssetName = 'directx-seven-zip__7zip.exe'
            ExpectedSha256 = '26CB6E9F56333682122FAFE79DBCDFD51E9F47CC7217DCCD29AC6FC33B5598CD'
            ExpectedSha1 = '7DF28D340D7084647921CC25A8C2068BB192BDBB'
            AuthenticodeStatus = 'NotSigned'
            ExpectedPublisher = ''
            SourceToolId = 'directx'
            SourceToolTitle = 'DirectX'
            SourceScriptPath = 'source-ultimate/5 Graphics/2 DirectX.ps1'
            MirrorCandidatePath = 'mirrors/directx/7zip.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 1589510
            MirrorContentLength = 1589510
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'directx'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-visual-cpp-vcredist2005-x64'
            ArtifactId = 'visual-cpp-vcredist2005-x64'
            DisplayName = 'Visual C++ - vcredist2005_x64.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2005_x64.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2005-x64__vcredist2005_x64.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2005-x64__vcredist2005_x64.exe'
            ExpectedFileName = 'vcredist2005_x64.exe'
            ExpectedMirrorAssetName = 'visual-cpp-vcredist2005-x64__vcredist2005_x64.exe'
            ExpectedSha256 = '4487570BD86E2E1AAC29DB2A1D0A91EB63361FCAAC570808EB327CD4E0E2240D'
            ExpectedSha1 = 'F4D74643A0E117EA80B2C7EBCD908A6DD26AA9EA'
            AuthenticodeStatus = 'Valid'
            ExpectedPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            SourceToolId = 'visual-cpp'
            SourceToolTitle = 'Visual C++'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2005_x64.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 3179000
            MirrorContentLength = 3179000
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'visual-cpp'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'AuthenticodeSigner'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-visual-cpp-vcredist2005-x86'
            ArtifactId = 'visual-cpp-vcredist2005-x86'
            DisplayName = 'Visual C++ - vcredist2005_x86.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2005_x86.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2005-x86__vcredist2005_x86.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2005-x86__vcredist2005_x86.exe'
            ExpectedFileName = 'vcredist2005_x86.exe'
            ExpectedMirrorAssetName = 'visual-cpp-vcredist2005-x86__vcredist2005_x86.exe'
            ExpectedSha256 = '8648C5FC29C44B9112FE52F9A33F80E7FC42D10F3B5B42B2121542A13E44ADFD'
            ExpectedSha1 = '56AE8221E8024C8DEED430E01A6160795C64CF53'
            AuthenticodeStatus = 'Valid'
            ExpectedPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            SourceToolId = 'visual-cpp'
            SourceToolTitle = 'Visual C++'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2005_x86.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 2710520
            MirrorContentLength = 2710520
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'visual-cpp'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'AuthenticodeSigner'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-visual-cpp-vcredist2008-x64'
            ArtifactId = 'visual-cpp-vcredist2008-x64'
            DisplayName = 'Visual C++ - vcredist2008_x64.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2008_x64.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2008-x64__vcredist2008_x64.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2008-x64__vcredist2008_x64.exe'
            ExpectedFileName = 'vcredist2008_x64.exe'
            ExpectedMirrorAssetName = 'visual-cpp-vcredist2008-x64__vcredist2008_x64.exe'
            ExpectedSha256 = 'C5E273A4A16AB4D5471E91C7477719A2F45DDADB76C7F98A38FA5074A6838654'
            ExpectedSha1 = 'CE8FF6572E86B0BBA39D88FA3A6D56B59100613D'
            AuthenticodeStatus = 'Valid'
            ExpectedPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            SourceToolId = 'visual-cpp'
            SourceToolTitle = 'Visual C++'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2008_x64.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 5211080
            MirrorContentLength = 5211080
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'visual-cpp'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'AuthenticodeSigner'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-visual-cpp-vcredist2008-x86'
            ArtifactId = 'visual-cpp-vcredist2008-x86'
            DisplayName = 'Visual C++ - vcredist2008_x86.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2008_x86.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2008-x86__vcredist2008_x86.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2008-x86__vcredist2008_x86.exe'
            ExpectedFileName = 'vcredist2008_x86.exe'
            ExpectedMirrorAssetName = 'visual-cpp-vcredist2008-x86__vcredist2008_x86.exe'
            ExpectedSha256 = '8742BCBF24EF328A72D2A27B693CC7071E38D3BB4B9B44DEC42AA3D2C8D61D92'
            ExpectedSha1 = '0940EC60DCC3162E482C1A797CA033D5996AB256'
            AuthenticodeStatus = 'Valid'
            ExpectedPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            SourceToolId = 'visual-cpp'
            SourceToolTitle = 'Visual C++'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2008_x86.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 4483040
            MirrorContentLength = 4483040
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'visual-cpp'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'AuthenticodeSigner'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-visual-cpp-vcredist2010-x64'
            ArtifactId = 'visual-cpp-vcredist2010-x64'
            DisplayName = 'Visual C++ - vcredist2010_x64.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2010_x64.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2010-x64__vcredist2010_x64.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2010-x64__vcredist2010_x64.exe'
            ExpectedFileName = 'vcredist2010_x64.exe'
            ExpectedMirrorAssetName = 'visual-cpp-vcredist2010-x64__vcredist2010_x64.exe'
            ExpectedSha256 = 'F3B7A76D84D23F91957AA18456A14B4E90609E4CE8194C5653384ED38DADA6F3'
            ExpectedSha1 = '8691972F0A5BF919701AC3B80FB693FC715420C2'
            AuthenticodeStatus = 'Valid'
            ExpectedPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            SourceToolId = 'visual-cpp'
            SourceToolTitle = 'Visual C++'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2010_x64.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 10277328
            MirrorContentLength = 10277328
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'visual-cpp'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'AuthenticodeSigner'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-visual-cpp-vcredist2010-x86'
            ArtifactId = 'visual-cpp-vcredist2010-x86'
            DisplayName = 'Visual C++ - vcredist2010_x86.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2010_x86.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2010-x86__vcredist2010_x86.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2010-x86__vcredist2010_x86.exe'
            ExpectedFileName = 'vcredist2010_x86.exe'
            ExpectedMirrorAssetName = 'visual-cpp-vcredist2010-x86__vcredist2010_x86.exe'
            ExpectedSha256 = '99DCE3C841CC6028560830F7866C9CE2928C98CF3256892EF8E6CF755147B0D8'
            ExpectedSha1 = '2222FC008E469FEC77D0D291877F357C6E1EB16D'
            AuthenticodeStatus = 'Valid'
            ExpectedPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            SourceToolId = 'visual-cpp'
            SourceToolTitle = 'Visual C++'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2010_x86.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 8993744
            MirrorContentLength = 8993744
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'visual-cpp'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'AuthenticodeSigner'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-visual-cpp-vcredist2012-x64'
            ArtifactId = 'visual-cpp-vcredist2012-x64'
            DisplayName = 'Visual C++ - vcredist2012_x64.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2012_x64.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2012-x64__vcredist2012_x64.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2012-x64__vcredist2012_x64.exe'
            ExpectedFileName = 'vcredist2012_x64.exe'
            ExpectedMirrorAssetName = 'visual-cpp-vcredist2012-x64__vcredist2012_x64.exe'
            ExpectedSha256 = '681BE3E5BA9FD3DA02C09D7E565ADFA078640ED66A0D58583EFAD2C1E3CC4064'
            ExpectedSha1 = '1A5D93DDDBC431AB27B1DA711CD3370891542797'
            AuthenticodeStatus = 'Valid'
            ExpectedPublisher = 'CN=Microsoft Corporation, OU=MOPR, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            SourceToolId = 'visual-cpp'
            SourceToolTitle = 'Visual C++'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2012_x64.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 7186992
            MirrorContentLength = 7186992
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'visual-cpp'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'AuthenticodeSigner'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-visual-cpp-vcredist2012-x86'
            ArtifactId = 'visual-cpp-vcredist2012-x86'
            DisplayName = 'Visual C++ - vcredist2012_x86.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2012_x86.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2012-x86__vcredist2012_x86.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2012-x86__vcredist2012_x86.exe'
            ExpectedFileName = 'vcredist2012_x86.exe'
            ExpectedMirrorAssetName = 'visual-cpp-vcredist2012-x86__vcredist2012_x86.exe'
            ExpectedSha256 = 'B924AD8062EAF4E70437C8BE50FA612162795FF0839479546CE907FFA8D6E386'
            ExpectedSha1 = '96B377A27AC5445328CBAAE210FC4F0AAA750D3F'
            AuthenticodeStatus = 'Valid'
            ExpectedPublisher = 'CN=Microsoft Corporation, OU=MOPR, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            SourceToolId = 'visual-cpp'
            SourceToolTitle = 'Visual C++'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2012_x86.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 6554576
            MirrorContentLength = 6554576
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'visual-cpp'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'AuthenticodeSigner'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-visual-cpp-vcredist2013-x64'
            ArtifactId = 'visual-cpp-vcredist2013-x64'
            DisplayName = 'Visual C++ - vcredist2013_x64.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2013_x64.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2013-x64__vcredist2013_x64.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2013-x64__vcredist2013_x64.exe'
            ExpectedFileName = 'vcredist2013_x64.exe'
            ExpectedMirrorAssetName = 'visual-cpp-vcredist2013-x64__vcredist2013_x64.exe'
            ExpectedSha256 = 'E554425243E3E8CA1CD5FE550DB41E6FA58A007C74FAD400274B128452F38FB8'
            ExpectedSha1 = '8BF41BA9EEF02D30635A10433817DBB6886DA5A2'
            AuthenticodeStatus = 'Valid'
            ExpectedPublisher = 'CN=Microsoft Corporation, OU=MOPR, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            SourceToolId = 'visual-cpp'
            SourceToolTitle = 'Visual C++'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2013_x64.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 7194312
            MirrorContentLength = 7194312
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'visual-cpp'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'AuthenticodeSigner'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-visual-cpp-vcredist2013-x86'
            ArtifactId = 'visual-cpp-vcredist2013-x86'
            DisplayName = 'Visual C++ - vcredist2013_x86.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2013_x86.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2013-x86__vcredist2013_x86.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2013-x86__vcredist2013_x86.exe'
            ExpectedFileName = 'vcredist2013_x86.exe'
            ExpectedMirrorAssetName = 'visual-cpp-vcredist2013-x86__vcredist2013_x86.exe'
            ExpectedSha256 = 'A22895E55B26202EAE166838EDBE2EA6AAD00D7EA600C11F8A31EDE5CBCE2048'
            ExpectedSha1 = 'DF7F0A73BFA077E483E51BFB97F5E2ECEEDFB6A3'
            AuthenticodeStatus = 'Valid'
            ExpectedPublisher = 'CN=Microsoft Corporation, OU=MOPR, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            SourceToolId = 'visual-cpp'
            SourceToolTitle = 'Visual C++'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2013_x86.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 6503984
            MirrorContentLength = 6503984
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'visual-cpp'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'AuthenticodeSigner'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-visual-cpp-vcredist2015-2017-2019-2022-x64'
            ArtifactId = 'visual-cpp-vcredist2015-2017-2019-2022-x64'
            DisplayName = 'Visual C++ - vcredist2015_2017_2019_2022_x64.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2015_2017_2019_2022_x64.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2015-2017-2019-2022-x64__vcredist2015_2017_2019_2022_x64.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2015-2017-2019-2022-x64__vcredist2015_2017_2019_2022_x64.exe'
            ExpectedFileName = 'vcredist2015_2017_2019_2022_x64.exe'
            ExpectedMirrorAssetName = 'visual-cpp-vcredist2015-2017-2019-2022-x64__vcredist2015_2017_2019_2022_x64.exe'
            ExpectedSha256 = 'CC0FF0EB1DC3F5188AE6300FAEF32BF5BEEBA4BDD6E8E445A9184072096B713B'
            ExpectedSha1 = '21CE0EE54BFF57F69FAFA741025BF2F15B356405'
            AuthenticodeStatus = 'Valid'
            ExpectedPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            SourceToolId = 'visual-cpp'
            SourceToolTitle = 'Visual C++'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2015_2017_2019_2022_x64.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 25635768
            MirrorContentLength = 25635768
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'visual-cpp'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'AuthenticodeSigner'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-visual-cpp-vcredist2015-2017-2019-2022-x86'
            ArtifactId = 'visual-cpp-vcredist2015-2017-2019-2022-x86'
            DisplayName = 'Visual C++ - vcredist2015_2017_2019_2022_x86.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist2015_2017_2019_2022_x86.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/visual-cpp-vcredist2015-2017-2019-2022-x86__vcredist2015_2017_2019_2022_x86.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'visual-cpp-vcredist2015-2017-2019-2022-x86__vcredist2015_2017_2019_2022_x86.exe'
            ExpectedFileName = 'vcredist2015_2017_2019_2022_x86.exe'
            ExpectedMirrorAssetName = 'visual-cpp-vcredist2015-2017-2019-2022-x86__vcredist2015_2017_2019_2022_x86.exe'
            ExpectedSha256 = '0C09F2611660441084CE0DF425C51C11E147E6447963C3690F97E0B25C55ED64'
            ExpectedSha1 = 'C2743FFC36D2AF40ADE0E370BE52D6B202874114'
            AuthenticodeStatus = 'Valid'
            ExpectedPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            SourceToolId = 'visual-cpp'
            SourceToolTitle = 'Visual C++'
            SourceScriptPath = 'source-ultimate/5 Graphics/3 C++.ps1'
            MirrorCandidatePath = 'mirrors/visual-cpp/vcredist2015_2017_2019_2022_x86.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 13953392
            MirrorContentLength = 13953392
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'visual-cpp'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'AuthenticodeSigner'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-bloatware-remote-desktop-connection'
            ArtifactId = 'bloatware-remote-desktop-connection'
            DisplayName = 'Bloatware - remotedesktopconnection.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/remotedesktopconnection.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/bloatware-remote-desktop-connection__remotedesktopconnection.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'bloatware-remote-desktop-connection__remotedesktopconnection.exe'
            ExpectedFileName = 'remotedesktopconnection.exe'
            ExpectedMirrorAssetName = 'bloatware-remote-desktop-connection__remotedesktopconnection.exe'
            ExpectedSha256 = 'B3F79EB8432F5C1EBED1E3BAE254541AA87839CDFBCFF4ADD392538B88C46021'
            ExpectedSha1 = 'D3F1F088B431E554EE9C2C6C298C63A572DCB795'
            AuthenticodeStatus = 'Valid'
            ExpectedPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            SourceToolId = 'bloatware'
            SourceToolTitle = 'Bloatware'
            SourceScriptPath = 'source-ultimate/6 Windows/11 Bloatware.ps1'
            MirrorCandidatePath = 'mirrors/bloatware/remotedesktopconnection.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 268344
            MirrorContentLength = 268344
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'bloatware'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'AuthenticodeSigner'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-bloatware-snipping-tool'
            ArtifactId = 'bloatware-snipping-tool'
            DisplayName = 'Bloatware - snippingtool.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/snippingtool.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/bloatware-snipping-tool__snippingtool.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'bloatware-snipping-tool__snippingtool.exe'
            ExpectedFileName = 'snippingtool.exe'
            ExpectedMirrorAssetName = 'bloatware-snipping-tool__snippingtool.exe'
            ExpectedSha256 = 'BDC9E0B26F62CA67E530671EAFD41F67BA8B86121CED44C966D008C7E077B321'
            ExpectedSha1 = '650480BF8B63706539B250DAF5F125D7466FDAB6'
            AuthenticodeStatus = 'Valid'
            ExpectedPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            SourceToolId = 'bloatware'
            SourceToolTitle = 'Bloatware'
            SourceScriptPath = 'source-ultimate/6 Windows/11 Bloatware.ps1'
            MirrorCandidatePath = 'mirrors/bloatware/snippingtool.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 260016
            MirrorContentLength = 260016
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'bloatware'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'AuthenticodeSigner'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-game-bar-edge-webview'
            ArtifactId = 'game-bar-edge-webview'
            DisplayName = 'GameBar - edgewebview.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edgewebview.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/game-bar-edge-webview__edgewebview.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'game-bar-edge-webview__edgewebview.exe'
            ExpectedFileName = 'edgewebview.exe'
            ExpectedMirrorAssetName = 'game-bar-edge-webview__edgewebview.exe'
            ExpectedSha256 = '02C97E5E32A97D896163EC68A3EA3AB0339E57F274348B8689399638B649B2B9'
            ExpectedSha1 = 'BFD5343FA72541DE388B346C64B1B67237F906C4'
            AuthenticodeStatus = 'Valid'
            ExpectedPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            SourceToolId = 'game-bar'
            SourceToolTitle = 'GameBar'
            SourceScriptPath = 'source-ultimate/6 Windows/12 Gamebar.ps1'
            MirrorCandidatePath = 'mirrors/game-bar/edgewebview.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 1683424
            MirrorContentLength = 1683424
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'game-bar'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'AuthenticodeSigner'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-game-bar-gaming-repair-tool'
            ArtifactId = 'game-bar-gaming-repair-tool'
            DisplayName = 'GameBar - gamingrepairtool.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/gamingrepairtool.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/game-bar-gaming-repair-tool__gamingrepairtool.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'game-bar-gaming-repair-tool__gamingrepairtool.exe'
            ExpectedFileName = 'gamingrepairtool.exe'
            ExpectedMirrorAssetName = 'game-bar-gaming-repair-tool__gamingrepairtool.exe'
            ExpectedSha256 = '1EA33E868BDB2C7D1606FD2098C2BD04495DFAEBEBD6E794B32FE72F198598DB'
            ExpectedSha1 = '2C9DCA57673012B0F6CDE764D4DCD80B9B4A1322'
            AuthenticodeStatus = 'Valid'
            ExpectedPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            SourceToolId = 'game-bar'
            SourceToolTitle = 'GameBar'
            SourceScriptPath = 'source-ultimate/6 Windows/12 Gamebar.ps1'
            MirrorCandidatePath = 'mirrors/game-bar/gamingrepairtool.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 751992
            MirrorContentLength = 751992
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'game-bar'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'AuthenticodeSigner'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-edge-webview-edge-exe'
            ArtifactId = 'edge-webview-edge-exe'
            DisplayName = 'Edge & WebView - edge.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/edge-webview-edge-exe__edge.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'edge-webview-edge-exe__edge.exe'
            ExpectedFileName = 'edge.exe'
            ExpectedMirrorAssetName = 'edge-webview-edge-exe__edge.exe'
            ExpectedSha256 = '61A2F3AD5B6DF4167D2FFAFADE138FAE84CB1603C40251D46AA0A8FFA8BFF138'
            ExpectedSha1 = 'EEB875C9A9CDFA6279F9CAC2CE0D36407B2ABADB'
            AuthenticodeStatus = 'Valid'
            ExpectedPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            SourceToolId = 'edge-webview'
            SourceToolTitle = 'Edge & WebView'
            SourceScriptPath = 'source-ultimate/6 Windows/13 Edge & WebView.ps1'
            MirrorCandidatePath = 'mirrors/edge-webview/edge.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 1683472
            MirrorContentLength = 1683472
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'edge-webview'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'AuthenticodeSigner'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
        @{
            Id = 'phase164g-edge-webview-edge-webview'
            ArtifactId = 'edge-webview-edge-webview'
            DisplayName = 'Edge & WebView - edgewebview.exe'
            SourceClassification = 'UltimateAuthorHostedArtifact'
            OriginalDownloadUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edgewebview.exe'
            VerifiedBoostLabMirrorUrl = 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/edge-webview-edge-webview__edgewebview.exe'
            MirrorReleaseTag = 'boostlab-artifacts-v1'
            MirrorAssetName = 'edge-webview-edge-webview__edgewebview.exe'
            ExpectedFileName = 'edgewebview.exe'
            ExpectedMirrorAssetName = 'edge-webview-edge-webview__edgewebview.exe'
            ExpectedSha256 = '02C97E5E32A97D896163EC68A3EA3AB0339E57F274348B8689399638B649B2B9'
            ExpectedSha1 = 'BFD5343FA72541DE388B346C64B1B67237F906C4'
            AuthenticodeStatus = 'Valid'
            ExpectedPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
            SourceToolId = 'edge-webview'
            SourceToolTitle = 'Edge & WebView'
            SourceScriptPath = 'source-ultimate/6 Windows/13 Edge & WebView.ps1'
            MirrorCandidatePath = 'mirrors/edge-webview/edgewebview.exe'
            EvidenceSource = 'Phase164BLocalIntake'
            EvidenceCapturedAt = '20260621-205731'
            MirrorVerifiedAt = 'Phase164E'
            MirrorVerificationMethod = 'HEAD'
            MirrorHttpStatus = '302 -> 200'
            ApprovalStatus = 'ApprovedForProvenanceOnly'
            YazanApprovalSource = 'Phase164G'
            ProductionApprovalStatus = 'NotApproved'
            ReleaseReadiness = 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification'
            ExpectedSizeBytes = 1683424
            MirrorContentLength = 1683424
            VerifiedBoostLabMirrorAvailable = $true
            ArtifactProvenanceApproved = $true
            AllowExecution = $false
            RequiresAdmin = $false
            CanReboot = $false
            RuntimeSourceSelectionApproved = $false
            ProductionAllowlistApproved = $false
            InstallerExecutionApproved = $false
            DownloadExecutionApproved = $false
            ReleaseReady = $false
            SourceToolIds = @(
                'edge-webview'
            )
            EvidencePhases = @(
                'Phase164B'
                'Phase164C'
                'Phase164E'
                'Phase164F'
                'Phase164G'
            )
            EvidenceTypes = @(
                'Local SHA-256/size/signature capture'
                'Public BoostLab mirror HEAD verification'
                'Phase 164G provenance-only approval'
            )
            VerificationRequirements = @(
                'FileName'
                'SHA256'
                'FileSize'
                'MirrorUrl'
                'LocalFileOnly'
                'NoDirectNetworkExecution'
                'AuthenticodeSigner'
            )
            Constraints = @(
                'Provenance approval is not production allowlist approval.'
                'Runtime source selection remains blocked.'
                'Download and installer execution remain blocked.'
                'Runtime must verify local file name, SHA-256, and size before use.'
                'Executable artifacts must not execute from a URL or unverified temp path.'
                'Release readiness remains blocked pending production allowlist and runtime integration.'
            )
            Notes = 'Verified BoostLab mirror evidence is approved for provenance tracking only. This record does not authorize runtime URL switching, downloading, installing, or execution.'
        }
    )
}
