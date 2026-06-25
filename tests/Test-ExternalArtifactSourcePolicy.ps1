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
    $isBoostLabProductShortcut = (
        [string]$entry.ToolId -eq 'nvidia-app-download' -and
        [string]$entry.OperationKind -eq 'VendorPage' -and
        [string]$entry.SourceClassification -eq 'OfficialVendorDirect'
    )
    if ($isBoostLabProductShortcut) {
        Assert-BoostLabCondition ([string]::IsNullOrWhiteSpace([string]$entry.SourceScriptPath)) "BoostLab-owned shortcut must not pretend to have an Ultimate source script: $($entry.Id)."
    }
    else {
        Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$entry.SourceScriptPath)) "Source script path missing for $($entry.Id)."
    }

    $toolId = [string]$entry.ToolId
    Assert-BoostLabCondition ($stageToolIndex.ContainsKey($toolId)) "Manifest references unknown tool id: $toolId"
    $toolInfo = $stageToolIndex[$toolId]
    Assert-BoostLabCondition ([string]$entry.ToolTitle -eq [string]$toolInfo.Title) "Manifest title mismatch for $toolId."
    Assert-BoostLabCondition ([string]$entry.Stage -eq [string]$toolInfo.Stage) "Manifest stage mismatch for $toolId."
    Assert-BoostLabCondition ([int]$entry.StageOrder -eq [int]$toolInfo.StageOrder) "Manifest stage order mismatch for $toolId."
    Assert-BoostLabCondition ([int]$entry.ToolOrder -gt 0) "Manifest tool order must remain positive for $toolId."

    if ([string]$entry.SourceClassification -eq 'OfficialVendorDirect') {
        Assert-BoostLabCondition ([string]$entry.MirrorStatus -eq 'NotRequiredOfficial') "Official source must not require BoostLab mirror: $($entry.Id)"
        Assert-BoostLabCondition ([string]::IsNullOrWhiteSpace([string]$entry.IntendedBoostLabMirrorUrl)) "Official source must not set a BoostLab mirror URL: $($entry.Id)"
    }
    elseif ([string]$entry.SourceClassification -in @('UltimateAuthorHostedArtifact', 'ThirdPartyMirrorArtifact')) {
        if ([string]$entry.MirrorStatus -ne 'BoostLabMirrorAvailable') {
            Assert-BoostLabCondition ([string]$entry.MirrorStatus -eq 'NeedsBoostLabMirror') "Author/third-party mirror artifact must need BoostLab mirror until exact mirror+hash exists: $($entry.Id)"
            Assert-BoostLabCondition ([string]::IsNullOrWhiteSpace([string]$entry.IntendedBoostLabMirrorUrl)) "Unapproved mirrored artifact must not set a BoostLab mirror URL: $($entry.Id)"
        }
        else {
            Assert-BoostLabCondition ([string]$entry.IntendedBoostLabMirrorUrl -eq [string]$entry.VerifiedBoostLabMirrorUrl) "Approved mirrored artifact must point runtime selection to the verified BoostLab mirror URL: $($entry.Id)"
            Assert-BoostLabCondition ($entry.ProductionAllowlistApproved -eq $true) "Approved mirrored artifact must have production approval: $($entry.Id)"
            Assert-BoostLabCondition ($entry.RuntimeSourceSelectionApproved -eq $true) "Approved mirrored artifact must have runtime source-selection approval: $($entry.Id)"
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
    'nvidia-app-download'
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

$nvidiaAppEntries = @($entries | Where-Object { [string]$_.ToolId -eq 'nvidia-app-download' })
Assert-BoostLabCondition ($nvidiaAppEntries.Count -eq 1) 'NVIDIA App shortcut must classify exactly one official page source.'
Assert-BoostLabCondition ([string]$nvidiaAppEntries[0].OriginalDownloadUrl -eq 'https://www.nvidia.com/en-us/software/nvidia-app/') 'NVIDIA App shortcut URL classification mismatch.'
Assert-BoostLabCondition ([string]$nvidiaAppEntries[0].SourceClassification -eq 'OfficialVendorDirect') 'NVIDIA App shortcut must be OfficialVendorDirect.'
Assert-BoostLabCondition ([string]$nvidiaAppEntries[0].MirrorStatus -eq 'NotRequiredOfficial') 'NVIDIA App shortcut must not require a BoostLab mirror.'

$directXEntries = @($entries | Where-Object { [string]$_.ToolId -eq 'directx' })
Assert-BoostLabCondition ($directXEntries.Count -eq 2) 'DirectX must classify exactly 7-Zip and DirectX runtime source artifacts.'
Assert-BoostLabCondition (@($directXEntries | Where-Object { [string]$_.OriginalDownloadUrl -like '*7zip.exe' -and [string]$_.SourceClassification -eq 'UltimateAuthorHostedArtifact' -and [string]$_.MirrorStatus -eq 'BoostLabMirrorAvailable' }).Count -eq 1) 'DirectX 7-Zip artifact classification mismatch.'
Assert-BoostLabCondition (@($directXEntries | Where-Object { [string]$_.OriginalDownloadUrl -like '*directx.exe' -and [string]$_.SourceClassification -eq 'UltimateAuthorHostedArtifact' -and [string]$_.MirrorStatus -eq 'BoostLabMirrorAvailable' }).Count -eq 1) 'DirectX runtime artifact classification mismatch.'

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
    Assert-BoostLabCondition ([string]$entry.MirrorStatus -eq 'BoostLabMirrorAvailable') "Visual C++ mirror status mismatch for $packageFile."
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
        Assert-BoostLabCondition ([string]$entry.MirrorStatus -eq 'BoostLabMirrorAvailable') "Mirror status mismatch for $($expectation.ToolId) artifact $artifactFile."
        Assert-BoostLabCondition ([string]$entry.IntendedBoostLabMirrorUrl -eq [string]$entry.VerifiedBoostLabMirrorUrl) "Runtime BoostLab mirror URL mismatch for $($expectation.ToolId) artifact $artifactFile."
    }
}

$officialEntries = @($entries | Where-Object { [string]$_.SourceClassification -eq 'OfficialVendorDirect' })
$officialPolicy = $manifest.OfficialVendorDirectRuntimePolicy
$officialPolicyEntries = @($officialPolicy.Entries)
$needsMirrorEntries = @($entries | Where-Object { [string]$_.MirrorStatus -eq 'NeedsBoostLabMirror' })
$availableMirrorEntries = @($entries | Where-Object { $_.ContainsKey('VerifiedBoostLabMirrorAvailable') -and $_.VerifiedBoostLabMirrorAvailable -eq $true })
$provenanceOnlyLinkedEntries = @($entries | Where-Object { $_.ContainsKey('ArtifactProvenanceOnlyApproved') -and $_.ArtifactProvenanceOnlyApproved -eq $true })
Assert-BoostLabCondition ($officialEntries.Count -eq 19) 'Expected exactly 19 active official vendor/project sources after Phase 173A Graphics simplification.'
Assert-BoostLabCondition ([int]$officialPolicy.ApprovedCount -eq 19) 'OfficialVendorDirect policy approved count mismatch.'
Assert-BoostLabCondition ($officialPolicyEntries.Count -eq 19) 'OfficialVendorDirect policy entry count mismatch.'
$officialEntryIds = @($officialEntries | ForEach-Object { [string]$_.Id } | Sort-Object)
$officialPolicyIds = @($officialPolicyEntries | ForEach-Object { [string]$_.Id } | Sort-Object)
Assert-BoostLabCondition (($officialEntryIds -join '|') -eq ($officialPolicyIds -join '|')) 'OfficialVendorDirect policy entries must map one-to-one to OfficialVendorDirect manifest entries.'
$officialKindCounts = @{}
foreach ($group in @($officialPolicyEntries | ForEach-Object { [string]$_['OfficialSourceKind'] } | Group-Object)) {
    $officialKindCounts[[string]$group.Name] = [int]$group.Count
}
$expectedOfficialKindCounts = @{
    StaticOfficialInstaller = 3
    FloatingOfficialInstaller = 14
    OfficialVendorLookupPage = 1
    OfficialVendorApi = 0
    BrowserExtensionOfficialSource = 1
}
foreach ($kind in $expectedOfficialKindCounts.Keys) {
    Assert-BoostLabCondition ([int]$officialKindCounts[$kind] -eq [int]$expectedOfficialKindCounts[$kind]) "OfficialVendorDirect classification count mismatch for $kind."
}
foreach ($policyEntry in $officialPolicyEntries) {
    $id = [string]$policyEntry['Id']
    $kind = [string]$policyEntry['OfficialSourceKind']
    Assert-BoostLabCondition ($kind -in @($officialPolicy.AllowedSourceKinds | ForEach-Object { [string]$_ })) "Invalid OfficialVendorDirect source kind for $id."
    Assert-BoostLabCondition ($policyEntry['ProductionAllowlistApproved'] -eq $true) "OfficialVendorDirect production approval missing for $id."
    Assert-BoostLabCondition ($policyEntry['RuntimeSourceSelectionApproved'] -eq $true) "OfficialVendorDirect runtime source-selection approval missing for $id."
    Assert-BoostLabCondition ($policyEntry['NoUrlExecution'] -eq $true) "OfficialVendorDirect must block URL execution for $id."
    $sourceEntry = @($officialEntries | Where-Object { [string]$_.Id -eq $id })[0]
    Assert-BoostLabCondition ([string]$sourceEntry.IntendedBoostLabMirrorUrl -eq '') "OfficialVendorDirect must not use a BoostLab mirror URL: $id."
    Assert-BoostLabCondition ([string]$sourceEntry.MirrorStatus -eq 'NotRequiredOfficial') "OfficialVendorDirect mirror status mismatch: $id."
    $hostAllowlist = @($policyEntry['OfficialHostAllowlist'] | ForEach-Object { [string]$_ })
    Assert-BoostLabCondition ($hostAllowlist.Count -gt 0) "OfficialVendorDirect host allowlist missing for $id."
    $sourceUri = [Uri]([string]$sourceEntry.OriginalDownloadUrl)
    Assert-BoostLabCondition ($sourceUri.Scheme -eq 'https') "OfficialVendorDirect URL must be HTTPS for $id."
    Assert-BoostLabCondition ([string]$sourceUri.Host -in $hostAllowlist) "OfficialVendorDirect URL host is not allowlisted for $id."
    if ($kind -in @('OfficialVendorLookupPage', 'OfficialVendorApi')) {
        Assert-BoostLabCondition ($policyEntry['LookupExecutionApproved'] -eq $true) "OfficialVendorDirect lookup/API approval missing for $id."
    }
    if ($kind -eq 'BrowserExtensionOfficialSource') {
        Assert-BoostLabCondition ([string]$policyEntry['ExpectedExtension'] -eq '.xpi') "Official browser extension source must require XPI extension for $id."
    }
}
$unsignedOfficialPolicyEntries = @($officialPolicyEntries | Where-Object { [string]$_['ExpectedSignatureStatus'] -eq 'NotSigned' })
Assert-BoostLabCondition ($unsignedOfficialPolicyEntries.Count -eq 1) 'Exactly one OfficialVendorDirect NotSigned installer exception is allowed.'
$sevenZipUnsignedPolicy = $unsignedOfficialPolicyEntries[0]
Assert-BoostLabCondition ([string]$sevenZipUnsignedPolicy['Id'] -eq 'installers-seven-zip') 'Only Installers 7-Zip may use the OfficialVendorDirect NotSigned exception.'
Assert-BoostLabCondition ($sevenZipUnsignedPolicy['UnsignedOfficialArtifactApproved'] -eq $true) 'Installers 7-Zip unsigned exception must be explicitly approved.'
Assert-BoostLabCondition ([string]$sevenZipUnsignedPolicy['UnsignedApprovalScope'] -eq 'ExactArtifactIdUrlHostFilenameShaSize') 'Installers 7-Zip unsigned exception scope mismatch.'
Assert-BoostLabCondition ([string]$sevenZipUnsignedPolicy['ExpectedSourceFileName'] -eq '7z2301-x64.exe') 'Installers 7-Zip source filename evidence mismatch.'
Assert-BoostLabCondition ([string]$sevenZipUnsignedPolicy['ExpectedFileName'] -eq '7 Zip.exe') 'Installers 7-Zip destination filename evidence mismatch.'
Assert-BoostLabCondition ([string]$sevenZipUnsignedPolicy['ExpectedSha256'] -eq '26CB6E9F56333682122FAFE79DBCDFD51E9F47CC7217DCCD29AC6FC33B5598CD') 'Installers 7-Zip SHA-256 evidence mismatch.'
Assert-BoostLabCondition ([int64]$sevenZipUnsignedPolicy['ExpectedSizeBytes'] -eq 1589510) 'Installers 7-Zip size evidence mismatch.'
foreach ($policyEntry in @($officialPolicyEntries | Where-Object { [string]$_['Id'] -ne 'installers-seven-zip' })) {
    Assert-BoostLabCondition ([string]$policyEntry['ExpectedSignatureStatus'] -ne 'NotSigned') "Unexpected OfficialVendorDirect unsigned exception: $($policyEntry['Id'])"
    Assert-BoostLabCondition ($policyEntry['UnsignedOfficialArtifactApproved'] -ne $true) "Unexpected unsigned approval flag outside Installers 7-Zip: $($policyEntry['Id'])"
}
Assert-BoostLabCondition ($needsMirrorEntries.Count -eq 0) 'Author-hosted artifacts should no longer require mirror governance after Phase 164H runtime approval.'
Assert-BoostLabCondition ($availableMirrorEntries.Count -eq 26) 'Expected all 26 active author-hosted artifacts to record verified public BoostLab mirror evidence after Phase 173A retired Nvidia Settings.'
Assert-BoostLabCondition ($provenanceOnlyLinkedEntries.Count -eq 26) 'Expected all 26 active verified mirror entries to link to provenance-only approvals.'
Assert-BoostLabCondition (@($entries | Where-Object { [string]$_.MirrorStatus -eq 'BoostLabMirrorAvailable' }).Count -eq 26) 'Exactly 26 active verified mirror artifacts must be available for runtime source selection.'
Assert-BoostLabCondition (@($entries | Where-Object { $_.ContainsKey('ArtifactProvenanceApproved') -and $_.ArtifactProvenanceApproved -eq $true }).Count -eq 26) 'Exactly 26 active verified mirror artifacts must have artifact provenance approved for runtime gating.'
Assert-BoostLabCondition (@($entries | Where-Object { $_.ContainsKey('ProductionAllowlistApproved') -and $_.ProductionAllowlistApproved -eq $true }).Count -eq 26) 'Exactly 26 active verified mirror artifacts must have production allowlist approval.'
Assert-BoostLabCondition (@($entries | Where-Object { $_.ContainsKey('RuntimeSourceSelectionApproved') -and $_.RuntimeSourceSelectionApproved -eq $true }).Count -eq 26) 'Exactly 26 active verified mirror artifacts must have runtime source-selection approval.'
Assert-BoostLabCondition (@($officialEntries | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.ExpectedSha256) }).Count -eq 0) 'Official vendor direct entries must not receive Phase 164B SHA evidence.'

$phase164BEvidenceIds = @(
    'reinstall-windows11-media-creation-tool'
    'edge-settings-edge-exe'
    'driver-clean-ddu'
    'driver-clean-seven-zip'
    'driver-install-debloat-settings-inspector'
    'driver-install-debloat-settings-seven-zip'
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
Assert-BoostLabCondition ($phase164BEvidenceEntries.Count -eq 26) 'Active Phase 164B SHA evidence entry count mismatch after Phase 173A retired Nvidia Settings.'
$provenanceOnlyApprovals = @($artifactProvenance.ProvenanceOnlyApprovals)
Assert-BoostLabCondition (@($artifactProvenance.Artifacts).Count -eq 0) 'Runtime artifact allowlist must remain empty; Phase 164G approvals are provenance-only.'
Assert-BoostLabCondition ($provenanceOnlyApprovals.Count -eq 26) 'Active Phase 164G provenance-only approval count mismatch after Phase 173A retired Nvidia Settings.'
$provenanceOnlyApprovalByArtifactId = @{}
foreach ($approval in $provenanceOnlyApprovals) {
    $artifactId = [string]$approval.ArtifactId
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace($artifactId)) 'Phase 164G provenance-only approval is missing ArtifactId.'
    Assert-BoostLabCondition ($phase164BEvidenceIds -contains $artifactId) "Phase 164G approval is outside the verified mirror evidence scope: $artifactId"
    Assert-BoostLabCondition (-not $provenanceOnlyApprovalByArtifactId.ContainsKey($artifactId)) "Duplicate Phase 164G approval for artifact: $artifactId"
    $provenanceOnlyApprovalByArtifactId[$artifactId] = $approval

    Assert-BoostLabCondition ([string]$approval.Id -eq "phase164g-$artifactId") "Phase 164G approval id mismatch: $artifactId"
    Assert-BoostLabCondition ([string]$approval.ApprovalStatus -eq 'ApprovedForProvenanceOnly') "Phase 164G approval status mismatch: $artifactId"
    Assert-BoostLabCondition ([string]$approval.SourceClassification -eq 'UltimateAuthorHostedArtifact') "Phase 164G approval classification mismatch: $artifactId"
    Assert-BoostLabCondition ([string]$approval.VerifiedBoostLabMirrorUrl -like 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/*') "Phase 164G approval mirror URL mismatch: $artifactId"
    Assert-BoostLabCondition ([string]$approval.ExpectedSha256 -match '^[A-Fa-f0-9]{64}$') "Phase 164G approval SHA-256 missing or malformed: $artifactId"
    Assert-BoostLabCondition ([int64]$approval.ExpectedSizeBytes -gt 0) "Phase 164G approval size missing: $artifactId"
    Assert-BoostLabCondition ($approval.VerifiedBoostLabMirrorAvailable -eq $true) "Phase 164G approval mirror evidence missing: $artifactId"
    Assert-BoostLabCondition ($approval.ArtifactProvenanceApproved -eq $true) "Phase 164G approval flag mismatch: $artifactId"
    Assert-BoostLabCondition ($approval.ProductionAllowlistApproved -eq $false) "Phase 164G approval must not approve production allowlist: $artifactId"
    Assert-BoostLabCondition ($approval.RuntimeSourceSelectionApproved -eq $false) "Phase 164G approval must not approve runtime source selection: $artifactId"
    Assert-BoostLabCondition ($approval.DownloadExecutionApproved -eq $false) "Phase 164G approval must not approve download execution: $artifactId"
    Assert-BoostLabCondition ($approval.InstallerExecutionApproved -eq $false) "Phase 164G approval must not approve installer execution: $artifactId"
    Assert-BoostLabCondition ($approval.AllowExecution -eq $false) "Phase 164G approval must not allow execution: $artifactId"
    Assert-BoostLabCondition ($approval.ReleaseReady -eq $false) "Phase 164G approval must not mark release ready: $artifactId"
    Assert-BoostLabCondition ('SHA256' -in @($approval.VerificationRequirements)) "Phase 164G approval must require SHA256 verification: $artifactId"
    Assert-BoostLabCondition ('NoDirectNetworkExecution' -in @($approval.VerificationRequirements)) "Phase 164G approval must block direct network execution: $artifactId"
    Assert-BoostLabCondition ('Phase164G' -in @($approval.EvidencePhases)) "Phase 164G approval must record the approval phase: $artifactId"
}
foreach ($entry in $phase164BEvidenceEntries) {
    $id = [string]$entry.Id
    Assert-BoostLabCondition ([string]$entry.SourceClassification -eq 'UltimateAuthorHostedArtifact') "Phase 164B evidence entry must remain UltimateAuthorHostedArtifact: $id"
    Assert-BoostLabCondition ($provenanceOnlyApprovalByArtifactId.ContainsKey($id)) "Phase 164G approval missing for evidence entry: $id"
    $approval = $provenanceOnlyApprovalByArtifactId[$id]
    $mirrorAssetName = ('{0}__{1}' -f $id, (Split-Path -Leaf ([string]$phase164BMirrorCandidates[$id])))
    $mirrorUrl = ('https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/{0}' -f $mirrorAssetName)
    Assert-BoostLabCondition ([string]$entry.MirrorStatus -eq 'BoostLabMirrorAvailable') "Phase 164H must approve runtime mirror source selection: $id"
    Assert-BoostLabCondition ([string]$entry.IntendedBoostLabMirrorUrl -eq $mirrorUrl) "Phase 164H runtime mirror URL mismatch: $id"
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
    Assert-BoostLabCondition ($entry.BoostLabMirrorAvailable -eq $true) "Phase 164H must approve mirror use for runtime: $id"
    Assert-BoostLabCondition ($entry.ArtifactProvenanceApproved -eq $true) "Phase 164H must approve artifact provenance for runtime gating: $id"
    Assert-BoostLabCondition ($entry.ArtifactProvenanceOnlyApproved -eq $true) "Phase 164G evidence must approve provenance-only tracking: $id"
    Assert-BoostLabCondition ([string]$entry.ArtifactProvenanceId -eq "phase164g-$id") "Phase 164G evidence provenance id mismatch: $id"
    Assert-BoostLabCondition ($entry.ProductionAllowlistApproved -eq $true) "Phase 164H must approve production allowlist for the verified mirror artifact: $id"
    Assert-BoostLabCondition ($entry.RuntimeSourceSelectionApproved -eq $true) "Phase 164H must approve runtime source selection for the verified mirror artifact: $id"
    Assert-BoostLabCondition ($entry.DownloadExecutionApproved -eq $true) "Phase 164H must approve download execution for the verified mirror artifact: $id"
    Assert-BoostLabCondition ($entry.InstallerExecutionApproved -eq $true) "Phase 164H must approve installer/artifact execution gating for the verified mirror artifact: $id"
    Assert-BoostLabCondition ([string]$entry.ReleaseReadiness -eq 'RuntimeApprovedPendingOfficialVendorDirectClosure') "Phase 164H release readiness status mismatch: $id"
    Assert-BoostLabCondition ([string]$approval.VerifiedBoostLabMirrorUrl -eq [string]$entry.VerifiedBoostLabMirrorUrl) "Phase 164G approval mirror URL linkage mismatch: $id"
    Assert-BoostLabCondition ([string]$approval.ExpectedSha256 -eq [string]$entry.ExpectedSha256) "Phase 164G approval SHA linkage mismatch: $id"
    Assert-BoostLabCondition ([int64]$approval.ExpectedSizeBytes -eq [int64]$entry.ExpectedSizeBytes) "Phase 164G approval size linkage mismatch: $id"
}

$expectedDuplicateGroups = @(
    @('edge-settings-edge-exe', 'edge-webview-edge-exe')
    @('driver-clean-seven-zip', 'driver-install-debloat-settings-seven-zip', 'directx-seven-zip')
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
    'nvidia-app-download' = Get-Content -LiteralPath (Join-Path $ProjectRoot 'modules\Graphics\nvidia-app-download.psm1') -Raw
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
    if ($toolId -eq 'visual-cpp') {
        Assert-BoostLabContains -Text $text -Needle 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main' -Description "Original URL base retained for $($entry.Id)"
        Assert-BoostLabContains -Text $text -Needle ([IO.Path]::GetFileName($url)) -Description "Original URL package retained for $($entry.Id)"
    }
    else {
        Assert-BoostLabContains -Text $text -Needle $url -Description "Original URL retained for $($entry.Id)"
    }

    if ([string]$entry.MirrorStatus -ne 'BoostLabMirrorAvailable') {
        Assert-BoostLabCondition ([string]::IsNullOrWhiteSpace([string]$entry.IntendedBoostLabMirrorUrl)) "Runtime URL must not be substituted without verified mirror/hash: $($entry.Id)"
    }
    else {
        Assert-BoostLabCondition ([string]$entry.IntendedBoostLabMirrorUrl -eq [string]$entry.VerifiedBoostLabMirrorUrl) "Runtime URL must use the verified BoostLab mirror URL for $($entry.Id)"
        Assert-BoostLabCondition (-not $text.Contains([string]$entry.IntendedBoostLabMirrorUrl)) "Runtime module/source must not hard-code the BoostLab mirror URL; it must use artifact-id source selection: $($entry.Id)"
    }

    if ($entry.ContainsKey('VerifiedBoostLabMirrorUrl')) {
        Assert-BoostLabCondition (-not $text.Contains([string]$entry.VerifiedBoostLabMirrorUrl)) "Runtime module/source must not hard-code the verified BoostLab mirror URL: $($entry.Id)"
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

Assert-BoostLabCondition (@($artifactProvenance.Artifacts).Count -eq 0) 'Runtime artifact allowlist must remain empty; no artifact execution approval was added.'
Assert-BoostLabCondition (@($artifactProvenance.ProvenanceOnlyApprovals).Count -eq 26) 'Provenance-only approvals must remain exactly scoped to 26 active verified mirror entries after Phase 173A.'
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
    ProvenanceOnlyLinkedCount = $provenanceOnlyLinkedEntries.Count
    RuntimeArtifactApprovals = @($artifactProvenance.Artifacts).Count
    ProvenanceOnlyApprovals = @($artifactProvenance.ProvenanceOnlyApprovals).Count
    BinaryFilesAdded = $binaryFiles.Count
    RuntimeUrlsChanged = $true
    SourceUltimateUnchanged = $true
    Message = 'External artifact source policy manifest is parseable, reached-tool coverage is scoped, and exactly 26 active verified BoostLab mirror artifacts are approved for runtime source selection.'
}
