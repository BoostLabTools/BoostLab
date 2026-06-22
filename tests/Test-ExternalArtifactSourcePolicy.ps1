[CmdletBinding()]
param(
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $scriptPath = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $PSCommandPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $MyInvocation.MyCommand.Path
    }
    else {
        throw 'Unable to determine the external artifact source policy validator path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')

function Assert-BoostLabCondition {
    param(
        [Parameter(Mandatory)]
        [bool]$Condition,

        [Parameter(Mandatory)]
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-BoostLabContains {
    param(
        [AllowNull()]
        [string]$Text,

        [Parameter(Mandatory)]
        [string]$Needle,

        [Parameter(Mandatory)]
        [string]$Description
    )

    if ([string]::IsNullOrEmpty($Text) -or -not $Text.Contains($Needle)) {
        throw "$Description missing expected text: $Needle"
    }
}

function Get-BoostLabStageToolIndex {
    param(
        [Parameter(Mandatory)]
        [object]$Stages
    )

    $index = @{}
    foreach ($stage in @($Stages)) {
        foreach ($tool in @($stage.Tools)) {
            $index[[string]$tool.Id] = [pscustomobject]@{
                Stage = [string]$stage.Name
                StageOrder = [int]$stage.Order
                ToolOrder = [int]$tool.Order
                Title = [string]$tool.Title
            }
        }
    }

    return $index
}

$manifestPath = Join-Path $ProjectRoot 'config\ExternalArtifactSources.psd1'
$policyDocPath = Join-Path $ProjectRoot 'docs\external-artifact-source-policy.md'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$artifactProvenancePath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$allowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'

Assert-BoostLabCondition (Test-Path -LiteralPath $manifestPath -PathType Leaf) 'External artifact source manifest is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $policyDocPath -PathType Leaf) 'External artifact source policy doc is missing.'

$manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
$stagesConfig = Import-PowerShellDataFile -LiteralPath $stagesPath
$artifactProvenance = Import-PowerShellDataFile -LiteralPath $artifactProvenancePath
$stageToolIndex = Get-BoostLabStageToolIndex -Stages $stagesConfig.Stages

$inventoryAssertion = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
$baseline = $inventoryAssertion.Baseline
$snapshot = $inventoryAssertion.Snapshot
Assert-BoostLabCondition ([int]$snapshot.ActiveTools -eq [int]$baseline.ActiveTools) 'Active tool count changed during external artifact source policy phase.'
Assert-BoostLabCondition ([int]$snapshot.ImplementedTools -eq [int]$baseline.ImplementedTools) 'Implemented tool count changed during external artifact source policy phase.'
Assert-BoostLabCondition ([int]$snapshot.DeferredPlaceholders -eq [int]$baseline.DeferredPlaceholders) 'Deferred placeholder count changed during external artifact source policy phase.'

$allowedClassifications = @($manifest.SourceClassifications | ForEach-Object { [string]$_ })
$allowedMirrorStatuses = @($manifest.MirrorStatuses | ForEach-Object { [string]$_ })
$entries = @($manifest.ExternalSources)

Assert-BoostLabCondition ([string]$manifest.SchemaVersion -eq '1.0') 'External artifact source manifest schema version mismatch.'
Assert-BoostLabCondition ($entries.Count -gt 0) 'External artifact source manifest has no entries.'

$requiredFields = @(
    'Id'
    'ToolId'
    'ToolTitle'
    'Stage'
    'StageOrder'
    'ToolOrder'
    'CanonicalOrder'
    'SourceScriptPath'
    'OriginalDownloadUrl'
    'SourceClassification'
    'IntendedBoostLabMirrorUrl'
    'ExpectedSha256'
    'MirrorStatus'
    'OperationKind'
    'Notes'
)

$ids = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($entry in $entries) {
    foreach ($field in $requiredFields) {
        Assert-BoostLabCondition ($entry.ContainsKey($field)) "Manifest entry '$($entry.Id)' is missing field $field."
    }

    Assert-BoostLabCondition ($ids.Add([string]$entry.Id)) "Duplicate external source manifest id: $($entry.Id)"
    Assert-BoostLabCondition ($allowedClassifications -contains [string]$entry.SourceClassification) "Invalid source classification for $($entry.Id)."
    Assert-BoostLabCondition ($allowedMirrorStatuses -contains [string]$entry.MirrorStatus) "Invalid mirror status for $($entry.Id)."
    Assert-BoostLabCondition ([string]$entry.OriginalDownloadUrl -match '^https://') "Manifest URL must be HTTPS for $($entry.Id)."
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$entry.SourceScriptPath)) "Source script path missing for $($entry.Id)."

    $toolId = [string]$entry.ToolId
    Assert-BoostLabCondition ($stageToolIndex.ContainsKey($toolId)) "Manifest references unknown tool id: $toolId"
    $toolInfo = $stageToolIndex[$toolId]
    Assert-BoostLabCondition ([string]$entry.ToolTitle -eq [string]$toolInfo.Title) "Manifest title mismatch for $toolId."
    Assert-BoostLabCondition ([string]$entry.Stage -eq [string]$toolInfo.Stage) "Manifest stage mismatch for $toolId."
    Assert-BoostLabCondition ([int]$entry.StageOrder -eq [int]$toolInfo.StageOrder) "Manifest stage order mismatch for $toolId."
    Assert-BoostLabCondition ([int]$entry.ToolOrder -eq [int]$toolInfo.ToolOrder) "Manifest tool order mismatch for $toolId."

    if ([string]$entry.SourceClassification -eq 'OfficialVendorDirect') {
        Assert-BoostLabCondition ([string]$entry.MirrorStatus -eq 'NotRequiredOfficial') "Official source must not require BoostLab mirror: $($entry.Id)"
        Assert-BoostLabCondition ([string]::IsNullOrWhiteSpace([string]$entry.IntendedBoostLabMirrorUrl)) "Official source must not set a BoostLab mirror URL: $($entry.Id)"
    }
    elseif ([string]$entry.SourceClassification -in @('UltimateAuthorHostedArtifact', 'ThirdPartyMirrorArtifact')) {
        if ([string]$entry.MirrorStatus -ne 'BoostLabMirrorAvailable') {
            Assert-BoostLabCondition ([string]$entry.MirrorStatus -eq 'NeedsBoostLabMirror') "Author/third-party mirror artifact must need BoostLab mirror until exact mirror+hash exists: $($entry.Id)"
            Assert-BoostLabCondition ([string]::IsNullOrWhiteSpace([string]$entry.IntendedBoostLabMirrorUrl)) "Unapproved mirrored artifact must not set a BoostLab mirror URL: $($entry.Id)"
        }
    }
    elseif ([string]$entry.SourceClassification -eq 'BoostLabControlledMirror') {
        Assert-BoostLabCondition ([string]$entry.MirrorStatus -eq 'BoostLabMirrorAvailable') "BoostLab mirror source must use BoostLabMirrorAvailable status: $($entry.Id)"
        Assert-BoostLabCondition ([string]$entry.ExpectedSha256 -match '^[A-Fa-f0-9]{64}$') "BoostLab mirror source must have SHA-256: $($entry.Id)"
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$entry.ExpectedSha256)) {
        Assert-BoostLabCondition ([string]$entry.ExpectedSha256 -match '^[A-Fa-f0-9]{64}$') "Malformed SHA-256 in manifest entry: $($entry.Id)"
    }
}

$reachedToolIds = @($manifest.AuditScope.ReachedToolIds | ForEach-Object { [string]$_ })
$expectedReachedToolIds = @(
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
Assert-BoostLabCondition ((@($reachedToolIds) -join '|') -eq (@($expectedReachedToolIds) -join '|')) 'Reached-tool artifact source audit scope changed.'
Assert-BoostLabCondition ('visual-cpp' -notin @($manifest.AuditScope.PrepOnlyToolIds | ForEach-Object { [string]$_ })) 'Visual C++ must no longer be prep-classified after Phase 130.'

$toolsWithRuntimeExternalDownloads = @(
    'reinstall'
    'edge-settings'
    'installers'
    'driver-clean'
    'driver-install-debloat-settings'
    'driver-install-latest'
    'nvidia-settings'
    'directx'
    'visual-cpp'
    'bloatware'
    'game-bar'
    'edge-webview'
)
foreach ($toolId in $toolsWithRuntimeExternalDownloads) {
    Assert-BoostLabCondition (@($entries | Where-Object { [string]$_.ToolId -eq $toolId }).Count -gt 0) "Reached tool with runtime external download has no manifest entries: $toolId"
}

$noRuntimeArtifactTools = @($manifest.AuditedNoRuntimeArtifactToolIds | ForEach-Object { [string]$_ })
foreach ($toolId in $noRuntimeArtifactTools) {
    Assert-BoostLabCondition (@($entries | Where-Object { [string]$_.ToolId -eq $toolId }).Count -eq 0) "Tool marked as no-runtime-artifact has manifest entries: $toolId"
}

$nvidiaSettingsEntries = @($entries | Where-Object { [string]$_.ToolId -eq 'nvidia-settings' })
Assert-BoostLabCondition ($nvidiaSettingsEntries.Count -eq 2) 'Nvidia Settings must classify exactly 7-Zip and Profile Inspector source artifacts.'
Assert-BoostLabCondition (@($nvidiaSettingsEntries | Where-Object { [string]$_.OriginalDownloadUrl -like '*7zip.exe' -and [string]$_.SourceClassification -eq 'UltimateAuthorHostedArtifact' -and [string]$_.MirrorStatus -eq 'NeedsBoostLabMirror' }).Count -eq 1) 'Nvidia Settings 7-Zip artifact classification mismatch.'
Assert-BoostLabCondition (@($nvidiaSettingsEntries | Where-Object { [string]$_.OriginalDownloadUrl -like '*inspector.exe' -and [string]$_.SourceClassification -eq 'UltimateAuthorHostedArtifact' -and [string]$_.MirrorStatus -eq 'NeedsBoostLabMirror' }).Count -eq 1) 'Nvidia Settings inspector artifact classification mismatch.'

$directXEntries = @($entries | Where-Object { [string]$_.ToolId -eq 'directx' })
Assert-BoostLabCondition ($directXEntries.Count -eq 2) 'DirectX must classify exactly 7-Zip and DirectX runtime source artifacts.'
Assert-BoostLabCondition (@($directXEntries | Where-Object { [string]$_.OriginalDownloadUrl -like '*7zip.exe' -and [string]$_.SourceClassification -eq 'UltimateAuthorHostedArtifact' -and [string]$_.MirrorStatus -eq 'NeedsBoostLabMirror' }).Count -eq 1) 'DirectX 7-Zip artifact classification mismatch.'
Assert-BoostLabCondition (@($directXEntries | Where-Object { [string]$_.OriginalDownloadUrl -like '*directx.exe' -and [string]$_.SourceClassification -eq 'UltimateAuthorHostedArtifact' -and [string]$_.MirrorStatus -eq 'NeedsBoostLabMirror' }).Count -eq 1) 'DirectX runtime artifact classification mismatch.'

$visualCppEntries = @($entries | Where-Object { [string]$_.ToolId -eq 'visual-cpp' })
Assert-BoostLabCondition ($visualCppEntries.Count -eq 12) 'Visual C++ must classify exactly twelve redistributable source artifacts.'
foreach ($packageFile in @(
    'vcredist2005_x64.exe'
    'vcredist2005_x86.exe'
    'vcredist2008_x64.exe'
    'vcredist2008_x86.exe'
    'vcredist2010_x64.exe'
    'vcredist2010_x86.exe'
    'vcredist2012_x64.exe'
    'vcredist2012_x86.exe'
    'vcredist2013_x64.exe'
    'vcredist2013_x86.exe'
    'vcredist2015_2017_2019_2022_x64.exe'
    'vcredist2015_2017_2019_2022_x86.exe'
)) {
    $url = "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/$packageFile"
    $entry = @($visualCppEntries | Where-Object { [string]$_.OriginalDownloadUrl -eq $url })[0]
    Assert-BoostLabCondition ($null -ne $entry) "Visual C++ external source missing for $packageFile."
    Assert-BoostLabCondition ([string]$entry.SourceClassification -eq 'UltimateAuthorHostedArtifact') "Visual C++ source classification mismatch for $packageFile."
    Assert-BoostLabCondition ([string]$entry.MirrorStatus -eq 'NeedsBoostLabMirror') "Visual C++ mirror status mismatch for $packageFile."
}

$windowsArtifactExpectations = @(
    @{
        ToolId = 'bloatware'
        ExpectedCount = 2
        Artifacts = @(
            'remotedesktopconnection.exe'
            'snippingtool.exe'
        )
    }
    @{
        ToolId = 'game-bar'
        ExpectedCount = 2
        Artifacts = @(
            'edgewebview.exe'
            'gamingrepairtool.exe'
        )
    }
    @{
        ToolId = 'edge-webview'
        ExpectedCount = 2
        Artifacts = @(
            'edge.exe'
            'edgewebview.exe'
        )
    }
)
foreach ($expectation in $windowsArtifactExpectations) {
    $toolEntries = @($entries | Where-Object { [string]$_.ToolId -eq [string]$expectation.ToolId })
    Assert-BoostLabCondition ($toolEntries.Count -eq [int]$expectation.ExpectedCount) "Windows artifact source count mismatch for $($expectation.ToolId)."

    foreach ($artifactFile in @($expectation.Artifacts)) {
        $url = "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/$artifactFile"
        $entry = @($toolEntries | Where-Object { [string]$_.OriginalDownloadUrl -eq $url })[0]
        Assert-BoostLabCondition ($null -ne $entry) "External source missing for $($expectation.ToolId) artifact $artifactFile."
        Assert-BoostLabCondition ([string]$entry.SourceClassification -eq 'UltimateAuthorHostedArtifact') "Source classification mismatch for $($expectation.ToolId) artifact $artifactFile."
        Assert-BoostLabCondition ([string]$entry.MirrorStatus -eq 'NeedsBoostLabMirror') "Mirror status mismatch for $($expectation.ToolId) artifact $artifactFile."
        Assert-BoostLabCondition ([string]::IsNullOrWhiteSpace([string]$entry.IntendedBoostLabMirrorUrl)) "Unexpected runtime BoostLab mirror URL for $($expectation.ToolId) artifact $artifactFile."
    }
}

$officialEntries = @($entries | Where-Object { [string]$_.SourceClassification -eq 'OfficialVendorDirect' })
$needsMirrorEntries = @($entries | Where-Object { [string]$_.MirrorStatus -eq 'NeedsBoostLabMirror' })
$availableMirrorEntries = @($entries | Where-Object { $_.ContainsKey('VerifiedBoostLabMirrorAvailable') -and $_.VerifiedBoostLabMirrorAvailable -eq $true })
Assert-BoostLabCondition ($officialEntries.Count -ge 20) 'Expected official vendor/project sources were not classified.'
Assert-BoostLabCondition ($needsMirrorEntries.Count -eq 28) 'Author-hosted artifacts must still require BoostLab mirror governance for runtime source selection.'
Assert-BoostLabCondition ($availableMirrorEntries.Count -eq 28) 'Expected all 28 author-hosted artifacts to record verified public BoostLab mirror evidence after Phase 164F.'
Assert-BoostLabCondition (@($entries | Where-Object { [string]$_.MirrorStatus -eq 'BoostLabMirrorAvailable' }).Count -eq 0) 'Verified mirror evidence must not flip runtime mirror status approval.'
Assert-BoostLabCondition (@($officialEntries | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.ExpectedSha256) }).Count -eq 0) 'Official vendor direct entries must not receive Phase 164B SHA evidence.'

$phase164BEvidenceIds = @(
    'reinstall-windows11-media-creation-tool'
    'edge-settings-edge-exe'
    'driver-clean-ddu'
    'driver-clean-seven-zip'
    'driver-install-debloat-settings-inspector'
    'driver-install-debloat-settings-seven-zip'
    'nvidia-settings-inspector'
    'nvidia-settings-seven-zip'
    'directx-runtime-package'
    'directx-seven-zip'
    'visual-cpp-vcredist2005-x64'
    'visual-cpp-vcredist2005-x86'
    'visual-cpp-vcredist2008-x64'
    'visual-cpp-vcredist2008-x86'
    'visual-cpp-vcredist2010-x64'
    'visual-cpp-vcredist2010-x86'
    'visual-cpp-vcredist2012-x64'
    'visual-cpp-vcredist2012-x86'
    'visual-cpp-vcredist2013-x64'
    'visual-cpp-vcredist2013-x86'
    'visual-cpp-vcredist2015-2017-2019-2022-x64'
    'visual-cpp-vcredist2015-2017-2019-2022-x86'
    'bloatware-remote-desktop-connection'
    'bloatware-snipping-tool'
    'game-bar-edge-webview'
    'game-bar-gaming-repair-tool'
    'edge-webview-edge-exe'
    'edge-webview-edge-webview'
)
$phase164BMirrorCandidates = @{
    'reinstall-windows11-media-creation-tool' = 'mirrors/reinstall/mediacreationtoolw11.exe'
    'edge-settings-edge-exe' = 'mirrors/edge-settings/edge.exe'
    'driver-clean-ddu' = 'mirrors/driver-clean/ddu.exe'
    'driver-clean-seven-zip' = 'mirrors/driver-clean/7zip.exe'
    'driver-install-debloat-settings-inspector' = 'mirrors/driver-install-debloat-settings/inspector.exe'
    'driver-install-debloat-settings-seven-zip' = 'mirrors/driver-install-debloat-settings/7zip.exe'
    'nvidia-settings-inspector' = 'mirrors/nvidia-settings/inspector.exe'
    'nvidia-settings-seven-zip' = 'mirrors/nvidia-settings/7zip.exe'
    'directx-runtime-package' = 'mirrors/directx/directx.exe'
    'directx-seven-zip' = 'mirrors/directx/7zip.exe'
    'visual-cpp-vcredist2005-x64' = 'mirrors/visual-cpp/vcredist2005_x64.exe'
    'visual-cpp-vcredist2005-x86' = 'mirrors/visual-cpp/vcredist2005_x86.exe'
    'visual-cpp-vcredist2008-x64' = 'mirrors/visual-cpp/vcredist2008_x64.exe'
    'visual-cpp-vcredist2008-x86' = 'mirrors/visual-cpp/vcredist2008_x86.exe'
    'visual-cpp-vcredist2010-x64' = 'mirrors/visual-cpp/vcredist2010_x64.exe'
    'visual-cpp-vcredist2010-x86' = 'mirrors/visual-cpp/vcredist2010_x86.exe'
    'visual-cpp-vcredist2012-x64' = 'mirrors/visual-cpp/vcredist2012_x64.exe'
    'visual-cpp-vcredist2012-x86' = 'mirrors/visual-cpp/vcredist2012_x86.exe'
    'visual-cpp-vcredist2013-x64' = 'mirrors/visual-cpp/vcredist2013_x64.exe'
    'visual-cpp-vcredist2013-x86' = 'mirrors/visual-cpp/vcredist2013_x86.exe'
    'visual-cpp-vcredist2015-2017-2019-2022-x64' = 'mirrors/visual-cpp/vcredist2015_2017_2019_2022_x64.exe'
    'visual-cpp-vcredist2015-2017-2019-2022-x86' = 'mirrors/visual-cpp/vcredist2015_2017_2019_2022_x86.exe'
    'bloatware-remote-desktop-connection' = 'mirrors/bloatware/remotedesktopconnection.exe'
    'bloatware-snipping-tool' = 'mirrors/bloatware/snippingtool.exe'
    'game-bar-edge-webview' = 'mirrors/game-bar/edgewebview.exe'
    'game-bar-gaming-repair-tool' = 'mirrors/game-bar/gamingrepairtool.exe'
    'edge-webview-edge-exe' = 'mirrors/edge-webview/edge.exe'
    'edge-webview-edge-webview' = 'mirrors/edge-webview/edgewebview.exe'
}
$phase164BEvidenceEntries = @($entries | Where-Object { $phase164BEvidenceIds -contains [string]$_.Id })
Assert-BoostLabCondition ($phase164BEvidenceEntries.Count -eq 28) 'Phase 164B SHA evidence entry count mismatch.'
foreach ($entry in $phase164BEvidenceEntries) {
    $id = [string]$entry.Id
    Assert-BoostLabCondition ([string]$entry.SourceClassification -eq 'UltimateAuthorHostedArtifact') "Phase 164B evidence entry must remain UltimateAuthorHostedArtifact: $id"
    $mirrorAssetName = ('{0}__{1}' -f $id, (Split-Path -Leaf ([string]$phase164BMirrorCandidates[$id])))
    $mirrorUrl = ('https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/{0}' -f $mirrorAssetName)
    Assert-BoostLabCondition ([string]$entry.MirrorStatus -eq 'NeedsBoostLabMirror') "Phase 164F evidence must not approve runtime mirror source selection: $id"
    Assert-BoostLabCondition ([string]::IsNullOrWhiteSpace([string]$entry.IntendedBoostLabMirrorUrl)) "Phase 164F evidence must not populate runtime mirror URL: $id"
    Assert-BoostLabCondition ([string]$entry.VerifiedBoostLabMirrorUrl -eq $mirrorUrl) "Phase 164F verified mirror URL mismatch: $id"
    Assert-BoostLabCondition ($entry.VerifiedBoostLabMirrorAvailable -eq $true) "Phase 164F verified mirror availability mismatch: $id"
    Assert-BoostLabCondition ([string]$entry.MirrorReleaseTag -eq 'boostlab-artifacts-v1') "Phase 164F mirror release tag mismatch: $id"
    Assert-BoostLabCondition ([string]$entry.MirrorAssetName -eq $mirrorAssetName) "Phase 164F mirror asset name mismatch: $id"
    Assert-BoostLabCondition ([string]$entry.MirrorVerifiedAt -eq 'Phase164E') "Phase 164F mirror verification evidence mismatch: $id"
    Assert-BoostLabCondition ([string]$entry.MirrorVerificationMethod -eq 'HEAD') "Phase 164F mirror verification method mismatch: $id"
    Assert-BoostLabCondition ([string]$entry.MirrorHttpStatus -eq '302 -> 200') "Phase 164F mirror HTTP status mismatch: $id"
    Assert-BoostLabCondition ([int64]$entry.MirrorContentLength -eq [int64]$entry.ExpectedSizeBytes) "Phase 164F mirror content length mismatch: $id"
    Assert-BoostLabCondition ([string]$entry.ExpectedSha256 -match '^[A-Fa-f0-9]{64}$') "Phase 164B evidence SHA-256 missing or malformed: $id"
    Assert-BoostLabCondition ([string]$entry.ExpectedSha1 -match '^[A-Fa-f0-9]{40}$') "Phase 164B evidence SHA-1 missing or malformed: $id"
    Assert-BoostLabCondition ([int64]$entry.ExpectedSizeBytes -gt 0) "Phase 164B evidence size missing: $id"
    Assert-BoostLabCondition ([string]$entry.AuthenticodeStatus -in @('Valid', 'NotSigned')) "Phase 164B evidence signature status unexpected: $id"
    Assert-BoostLabCondition ([string]$entry.EvidenceSource -eq 'Phase164BLocalIntake') "Phase 164B evidence source mismatch: $id"
    Assert-BoostLabCondition ([string]$entry.EvidenceCapturedAt -eq '20260621-205731') "Phase 164B evidence timestamp mismatch: $id"
    Assert-BoostLabCondition ([string]$entry.MirrorCandidatePath -eq [string]$phase164BMirrorCandidates[$id]) "Phase 164B mirror candidate path mismatch: $id"
    Assert-BoostLabCondition ($entry.BoostLabMirrorAvailable -eq $false) "Phase 164F evidence must not approve mirror use for runtime: $id"
    Assert-BoostLabCondition ($entry.ArtifactProvenanceApproved -eq $false) "Phase 164B evidence must not approve artifact provenance: $id"
    Assert-BoostLabCondition ($entry.ProductionAllowlistApproved -eq $false) "Phase 164B evidence must not approve production allowlist: $id"
    Assert-BoostLabCondition ([string]$entry.ReleaseReadiness -eq 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification') "Phase 164F evidence must remain release-blocked: $id"
}

$expectedDuplicateGroups = @(
    @('edge-settings-edge-exe', 'edge-webview-edge-exe')
    @('driver-clean-seven-zip', 'driver-install-debloat-settings-seven-zip', 'nvidia-settings-seven-zip', 'directx-seven-zip')
    @('driver-install-debloat-settings-inspector', 'nvidia-settings-inspector')
    @('game-bar-edge-webview', 'edge-webview-edge-webview')
)
foreach ($group in $expectedDuplicateGroups) {
    $hashes = @($phase164BEvidenceEntries | Where-Object { $group -contains [string]$_.Id } | ForEach-Object { [string]$_.ExpectedSha256 } | Sort-Object -Unique)
    Assert-BoostLabCondition ($hashes.Count -eq 1) "Phase 164B duplicate SHA group mismatch: $($group -join ', ')"
}
Assert-BoostLabCondition (@($phase164BEvidenceEntries | Where-Object { [string]$_.ReleaseReadiness -eq 'ReleaseReady' }).Count -eq 0) 'Phase 164B evidence must not mark any entry release-ready.'

$outOfScopeToolIds = @($manifest.AuditScope.ExplicitlyOutOfScopeToolIds | ForEach-Object { [string]$_ })
foreach ($toolId in $outOfScopeToolIds) {
    Assert-BoostLabCondition (@($entries | Where-Object { [string]$_.ToolId -eq $toolId }).Count -eq 0) "Unreached out-of-scope tool was classified in this phase: $toolId"
}

$sourceTextByTool = @{
    'reinstall' = Get-Content -LiteralPath (Join-Path $ProjectRoot 'modules\Refresh\reinstall.psm1') -Raw
    'edge-settings' = Get-Content -LiteralPath (Join-Path $ProjectRoot 'modules\Setup\edge-settings.psm1') -Raw
    'installers' = Get-Content -LiteralPath (Join-Path $ProjectRoot 'modules\Installers\installers.psm1') -Raw
    'driver-clean' = Get-Content -LiteralPath (Join-Path $ProjectRoot 'modules\Graphics\driver-clean.psm1') -Raw
    'driver-install-debloat-settings' = Get-Content -LiteralPath (Join-Path $ProjectRoot 'modules\Graphics\driver-install-debloat-settings.psm1') -Raw
    'driver-install-latest' = Get-Content -LiteralPath (Join-Path $ProjectRoot 'modules\Graphics\driver-install-latest.psm1') -Raw
    'nvidia-settings' = Get-Content -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate\5 Graphics\4 Nvidia Settings.ps1') -Raw
    'directx' = Get-Content -LiteralPath (Join-Path $ProjectRoot 'modules\Graphics\directx.psm1') -Raw
    'visual-cpp' = Get-Content -LiteralPath (Join-Path $ProjectRoot 'modules\Graphics\visual-cpp.psm1') -Raw
    'bloatware' = Get-Content -LiteralPath (Join-Path $ProjectRoot 'modules\Windows\bloatware.psm1') -Raw
    'game-bar' = Get-Content -LiteralPath (Join-Path $ProjectRoot 'modules\Windows\game-bar.psm1') -Raw
    'edge-webview' = Get-Content -LiteralPath (Join-Path $ProjectRoot 'modules\Windows\edge-webview.psm1') -Raw
}

foreach ($entry in $entries) {
    $toolId = [string]$entry.ToolId
    Assert-BoostLabCondition ($sourceTextByTool.ContainsKey($toolId)) "No source/module text loaded for manifest entry tool: $toolId"

    $text = [string]$sourceTextByTool[$toolId]
    $url = [string]$entry.OriginalDownloadUrl
    if ([string]$entry.Id -eq 'driver-install-latest-nvidia-driver-template') {
        Assert-BoostLabContains -Text $text -Needle 'https://international.download.nvidia.com/Windows/{0}/{0}-desktop-{1}-{2}-international-dch-whql.exe' -Description 'Driver Install Latest NVIDIA dynamic download template'
    }
    else {
        if ($toolId -eq 'visual-cpp') {
            Assert-BoostLabContains -Text $text -Needle 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main' -Description "Original URL base retained for $($entry.Id)"
            Assert-BoostLabContains -Text $text -Needle ([IO.Path]::GetFileName($url)) -Description "Original URL package retained for $($entry.Id)"
        }
        else {
            Assert-BoostLabContains -Text $text -Needle $url -Description "Original URL retained for $($entry.Id)"
        }
    }

    if ([string]$entry.MirrorStatus -ne 'BoostLabMirrorAvailable') {
        Assert-BoostLabCondition ([string]::IsNullOrWhiteSpace([string]$entry.IntendedBoostLabMirrorUrl)) "Runtime URL must not be substituted without verified mirror/hash: $($entry.Id)"
    }
    else {
        Assert-BoostLabCondition (-not $text.Contains([string]$entry.IntendedBoostLabMirrorUrl)) "Runtime module/source must not switch to the BoostLab mirror URL yet: $($entry.Id)"
    }

    if ($entry.ContainsKey('VerifiedBoostLabMirrorUrl')) {
        Assert-BoostLabCondition (-not $text.Contains([string]$entry.VerifiedBoostLabMirrorUrl)) "Runtime module/source must not switch to the verified BoostLab mirror URL yet: $($entry.Id)"
    }
}

$policyDoc = Get-Content -LiteralPath $policyDocPath -Raw
foreach ($needle in @(
    'Official vendor downloads remain direct.'
    'Author-hosted or third-party mirror artifacts are tracked as'
    'Mirror substitution is allowed only when'
    'This manifest is separate from `config/ArtifactProvenance.psd1`.'
    'It does not download, upload, vendor, or commit binary files.'
)) {
    Assert-BoostLabContains -Text $policyDoc -Needle $needle -Description 'External artifact source policy documentation'
}

Assert-BoostLabCondition (@($artifactProvenance.Artifacts).Count -eq 0) 'Artifact provenance config must remain empty; no real artifacts were approved.'
if (Test-Path -LiteralPath $allowlistPath -PathType Leaf) {
    $allowlistText = Get-Content -LiteralPath $allowlistPath -Raw
    Assert-BoostLabCondition (-not $allowlistText.Contains('BoostLabMirrorAvailable')) 'Production allowlist must not approve external artifact mirrors.'
}

$binaryExtensions = @('.exe', '.msi', '.zip', '.7z', '.xpi', '.dll')
$binaryFiles = @(
    Get-ChildItem -LiteralPath $ProjectRoot -Recurse -File -ErrorAction Stop |
        Where-Object {
            $_.FullName -notlike '*\.git\*' -and
            $binaryExtensions -contains $_.Extension.ToLowerInvariant()
        }
)
Assert-BoostLabCondition ($binaryFiles.Count -eq 0) 'Binary artifact files must not be added to the repository in this phase.'

foreach ($protectedPath in @('source-ultimate', 'source-ultimate\_intake-promoted', 'intake')) {
    $fullPath = Join-Path $ProjectRoot $protectedPath
    if (Test-Path -LiteralPath $fullPath) {
        $recent = @(Get-ChildItem -LiteralPath $fullPath -Recurse -File | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-6) })
        Assert-BoostLabCondition ($recent.Count -eq 0) "Protected source/intake path has recent modifications during external source policy phase: $protectedPath"
    }
}

Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\23 NVME Faster Driver.ps1'))) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    TestName = 'ExternalArtifactSourcePolicy'
    ManifestPath = $manifestPath
    PolicyDocPath = $policyDocPath
    ReachedToolCount = $reachedToolIds.Count
    PrepOnlyToolIds = @($manifest.AuditScope.PrepOnlyToolIds)
    ExternalSourceCount = $entries.Count
    OfficialVendorDirectCount = $officialEntries.Count
    NeedsBoostLabMirrorCount = $needsMirrorEntries.Count
    BoostLabMirrorAvailableCount = @($entries | Where-Object { [string]$_.MirrorStatus -eq 'BoostLabMirrorAvailable' }).Count
    VerifiedBoostLabMirrorAvailableCount = $availableMirrorEntries.Count
    ArtifactProvenanceApprovals = @($artifactProvenance.Artifacts).Count
    BinaryFilesAdded = $binaryFiles.Count
    RuntimeUrlsChanged = $false
    SourceUltimateUnchanged = $true
    Message = 'External artifact source policy manifest is parseable, reached-tool coverage is scoped, and no runtime URL or artifact approval changed.'
}
