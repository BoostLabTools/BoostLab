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

$baseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot
Assert-BoostLabCondition ([int]$baseline.ActiveTools -eq 55) 'Active tool count changed during external artifact source policy phase.'
Assert-BoostLabCondition ([int]$baseline.ImplementedTools -eq 45) 'Implemented tool count changed during external artifact source policy phase.'
Assert-BoostLabCondition ([int]$baseline.DeferredPlaceholders -eq 10) 'Deferred placeholder count changed during external artifact source policy phase.'

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
)
Assert-BoostLabCondition ((@($reachedToolIds) -join '|') -eq (@($expectedReachedToolIds) -join '|')) 'Reached-tool artifact source audit scope changed.'
Assert-BoostLabCondition ('visual-cpp' -in @($manifest.AuditScope.PrepOnlyToolIds | ForEach-Object { [string]$_ })) 'Visual C++ must be prep-classified before its parity phase.'

$toolsWithRuntimeExternalDownloads = @(
    'reinstall'
    'edge-settings'
    'installers'
    'driver-clean'
    'driver-install-debloat-settings'
    'driver-install-latest'
    'nvidia-settings'
    'directx'
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

$officialEntries = @($entries | Where-Object { [string]$_.SourceClassification -eq 'OfficialVendorDirect' })
$needsMirrorEntries = @($entries | Where-Object { [string]$_.MirrorStatus -eq 'NeedsBoostLabMirror' })
Assert-BoostLabCondition ($officialEntries.Count -ge 20) 'Expected official vendor/project sources were not classified.'
Assert-BoostLabCondition ($needsMirrorEntries.Count -ge 8) 'Expected author-hosted artifacts were not classified as needing BoostLab mirror.'
Assert-BoostLabCondition (@($entries | Where-Object { [string]$_.MirrorStatus -eq 'BoostLabMirrorAvailable' }).Count -eq 0) 'No BoostLab mirror should be approved in this phase.'

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
        Assert-BoostLabContains -Text $text -Needle $url -Description "Original URL retained for $($entry.Id)"
    }

    if ([string]$entry.MirrorStatus -ne 'BoostLabMirrorAvailable') {
        Assert-BoostLabCondition ([string]::IsNullOrWhiteSpace([string]$entry.IntendedBoostLabMirrorUrl)) "Runtime URL must not be substituted without verified mirror/hash: $($entry.Id)"
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
    ArtifactProvenanceApprovals = @($artifactProvenance.Artifacts).Count
    BinaryFilesAdded = $binaryFiles.Count
    RuntimeUrlsChanged = $false
    SourceUltimateUnchanged = $true
    Message = 'External artifact source policy manifest is parseable, reached-tool coverage is scoped, and no runtime URL or artifact approval changed.'
}
