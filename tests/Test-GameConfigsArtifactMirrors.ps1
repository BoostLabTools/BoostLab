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
        throw 'Unable to determine the Game Configs artifact mirror validator path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

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

$externalPath = Join-Path $ProjectRoot 'config\ExternalArtifactSources.psd1'
$provenancePath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$sourceManifestPath = Join-Path $ProjectRoot 'config\GameConfigArtifactSources.psd1'
$provenanceManifestPath = Join-Path $ProjectRoot 'config\GameConfigArtifactProvenance.psd1'
$runtimeManifestPath = Join-Path $ProjectRoot 'config\GameConfigs.psd1'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$allowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\GameConfigs\game-configs.psm1'

foreach ($requiredPath in @(
    $externalPath
    $provenancePath
    $sourceManifestPath
    $provenanceManifestPath
    $runtimeManifestPath
    $stagesPath
    $allowlistPath
    $modulePath
)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $requiredPath -PathType Leaf) "Required Game Configs file is missing: $requiredPath"
}

$external = Import-PowerShellDataFile -LiteralPath $externalPath
$provenance = Import-PowerShellDataFile -LiteralPath $provenancePath
$sources = Import-PowerShellDataFile -LiteralPath $sourceManifestPath
$gameProvenance = Import-PowerShellDataFile -LiteralPath $provenanceManifestPath
$runtimeManifest = Import-PowerShellDataFile -LiteralPath $runtimeManifestPath
$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$allowlist = Import-PowerShellDataFile -LiteralPath $allowlistPath

Assert-BoostLabCondition (@($external.ExternalSources).Count -eq 50) 'Existing active-stage external artifact source count changed.'
Assert-BoostLabCondition (@($provenance.ProvenanceOnlyApprovals).Count -eq 28) 'Existing active-stage provenance-only approval count changed.'
Assert-BoostLabCondition ([string]$external.GameConfigPayloadSourceManifest.Path -eq 'config/GameConfigArtifactSources.psd1') 'External artifact manifest does not point at the Game Configs source manifest.'
Assert-BoostLabCondition ([int]$external.GameConfigPayloadSourceManifest.RecordCount -eq 28) 'External artifact Game Config pointer count mismatch.'
Assert-BoostLabCondition ($external.GameConfigPayloadSourceManifest.RuntimeSourceSelectionApproved -eq $true) 'Game Config source pointer must approve runtime source selection in Phase 165D.'
Assert-BoostLabCondition ($external.GameConfigPayloadSourceManifest.ProductionAllowlistApproved -eq $false) 'Game Config source pointer must not add production allowlist approval.'
Assert-BoostLabCondition ($external.GameConfigPayloadSourceManifest.StageImplemented -eq $true) 'Game Config source pointer must record Stage 8 implementation.'
Assert-BoostLabCondition ([string]$provenance.GameConfigPayloadProvenanceManifest.Path -eq 'config/GameConfigArtifactProvenance.psd1') 'Artifact provenance manifest does not point at the Game Configs provenance manifest.'
Assert-BoostLabCondition ([int]$provenance.GameConfigPayloadProvenanceManifest.RecordCount -eq 28) 'Artifact provenance Game Config pointer count mismatch.'
Assert-BoostLabCondition ([string]$provenance.GameConfigPayloadProvenanceManifest.ApprovalStatus -eq 'ApprovedForStage8Runtime') 'Game Config provenance pointer approval status mismatch.'
Assert-BoostLabCondition ($provenance.GameConfigPayloadProvenanceManifest.RuntimeSourceSelectionApproved -eq $true) 'Game Config provenance pointer must approve runtime source selection in Phase 165D.'
Assert-BoostLabCondition ($provenance.GameConfigPayloadProvenanceManifest.ProductionAllowlistApproved -eq $false) 'Game Config provenance pointer must not add production allowlist approval.'
Assert-BoostLabCondition ($provenance.GameConfigPayloadProvenanceManifest.StageImplemented -eq $true) 'Game Config provenance pointer must record Stage 8 implementation.'

$payloadSources = @($sources.PayloadSources)
$provenanceApprovals = @($gameProvenance.ProvenanceApprovals)
$runtimeGames = @($runtimeManifest.Games)
Assert-BoostLabCondition ($payloadSources.Count -eq 28) 'Game Config source manifest must record exactly 28 payload sources.'
Assert-BoostLabCondition ($provenanceApprovals.Count -eq 28) 'Game Config provenance manifest must record exactly 28 payload records.'
Assert-BoostLabCondition ($runtimeGames.Count -eq 27) 'Game Config runtime manifest must expose exactly 27 Apply entries.'
Assert-BoostLabCondition ([string]$sources.Release.Tag -eq 'boostlab-game-configs-v1') 'Game Config source manifest release tag mismatch.'
Assert-BoostLabCondition ([string]$gameProvenance.Release.Tag -eq 'boostlab-game-configs-v1') 'Game Config provenance manifest release tag mismatch.'
Assert-BoostLabCondition ([int]$sources.Release.HeadVerifiedCount -eq 28) 'Game Config mirror HEAD verification count mismatch.'
Assert-BoostLabCondition ([int]$gameProvenance.Release.HeadVerifiedCount -eq 28) 'Game Config provenance HEAD verification count mismatch.'
Assert-BoostLabCondition ($sources.StageImplemented -eq $true) 'Game Config source manifest must record Stage 8 implementation.'
Assert-BoostLabCondition ($gameProvenance.StageImplemented -eq $true) 'Game Config provenance manifest must record Stage 8 implementation.'
Assert-BoostLabCondition ($sources.RuntimeSourceSelectionApproved -eq $true) 'Game Config source manifest must approve runtime source selection.'
Assert-BoostLabCondition ($gameProvenance.RuntimeSourceSelectionApproved -eq $true) 'Game Config provenance manifest must approve runtime source selection.'
Assert-BoostLabCondition ($sources.ProductionAllowlistApproved -eq $false) 'Game Config source manifest must not add production allowlist approval.'
Assert-BoostLabCondition ($gameProvenance.ProductionAllowlistApproved -eq $false) 'Game Config provenance manifest must not add production allowlist approval.'
Assert-BoostLabCondition ($runtimeManifest.RuntimeUsesBoostLabMirrors -eq $true) 'Game Config runtime manifest must require BoostLab mirrors.'
Assert-BoostLabCondition ($runtimeManifest.RuntimeUsesRawUpstreamPayloadUrls -eq $false) 'Game Config runtime manifest must not use raw upstream payload URLs.'

$sourceIds = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$provenanceIds = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($entry in $payloadSources) {
    Assert-BoostLabCondition ($sourceIds.Add([string]$entry.Id)) "Duplicate Game Config payload source id: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.ToolId -eq 'game-configs') "Unexpected Game Config payload tool id: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.Stage -eq 'Game Configs') "Unexpected Game Config payload stage: $($entry.Id)"
    Assert-BoostLabCondition ([int]$entry.StageOrder -eq 8) "Unexpected Game Config payload stage order: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.SourceClassification -eq 'UltimateAuthorHostedArtifact') "Game Config payload must be classified as upstream-hosted: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.MirrorStatus -eq 'BoostLabMirrorAvailable') "Game Config payload mirror is not marked available: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.OriginalDownloadUrl -like 'https://github.com/FR33THYFR33THY/*') "Game Config original URL must stay traceable to upstream: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.VerifiedBoostLabMirrorUrl -like 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/*') "Game Config verified mirror URL must use the BoostLab release: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.IntendedBoostLabMirrorUrl -eq [string]$entry.VerifiedBoostLabMirrorUrl) "Game Config intended mirror URL must match the verified mirror URL: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.IntendedBoostLabMirrorUrl -notlike 'https://github.com/FR33THYFR33THY/*') "Raw upstream URL must not be the final Game Config mirror source: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.MirrorReleaseTag -eq 'boostlab-game-configs-v1') "Game Config mirror release tag mismatch: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.MirrorVerificationMethod -eq 'HEAD') "Game Config mirror verification must be HEAD-only: $($entry.Id)"
    Assert-BoostLabCondition ([int]$entry.MirrorHttpStatus -eq 200) "Game Config mirror HEAD status mismatch: $($entry.Id)"
    Assert-BoostLabCondition ([int64]$entry.ExpectedSizeBytes -gt 0) "Game Config payload size is missing: $($entry.Id)"
    Assert-BoostLabCondition ([int64]$entry.MirrorContentLength -eq [int64]$entry.ExpectedSizeBytes) "Game Config mirror size mismatch: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.ExpectedSha256 -match '^[A-Fa-f0-9]{64}$') "Game Config SHA-256 is malformed: $($entry.Id)"
    Assert-BoostLabCondition ($entry.VerifiedBoostLabMirrorAvailable -eq $true) "Game Config mirror availability not recorded: $($entry.Id)"
    Assert-BoostLabCondition ($entry.ArtifactProvenanceApproved -eq $true) "Game Config provenance approval not recorded: $($entry.Id)"
    Assert-BoostLabCondition ($entry.ProductionAllowlistApproved -eq $false) "Game Config payload must not be production allowlist-approved: $($entry.Id)"
    Assert-BoostLabCondition ($entry.RuntimeSourceSelectionApproved -eq $true) "Game Config payload must be runtime source-selection approved in Phase 165D: $($entry.Id)"
    Assert-BoostLabCondition ($entry.DownloadExecutionApproved -eq $true) "Game Config payload download must be approved in Phase 165D: $($entry.Id)"
    Assert-BoostLabCondition ($entry.InstallerExecutionApproved -eq $false) "Game Config payload must not approve installers: $($entry.Id)"
}

foreach ($entry in $provenanceApprovals) {
    Assert-BoostLabCondition ($provenanceIds.Add([string]$entry.Id)) "Duplicate Game Config provenance id: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.SourceToolId -eq 'game-configs') "Unexpected Game Config provenance tool id: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.ApprovalStatus -eq 'ApprovedForStage8Runtime') "Game Config provenance approval status mismatch: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.ProductionApprovalStatus -eq 'NotApproved') "Game Config provenance production status mismatch: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.VerifiedBoostLabMirrorUrl -like 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/*') "Game Config provenance mirror URL mismatch: $($entry.Id)"
    Assert-BoostLabCondition ([int64]$entry.MirrorContentLength -eq [int64]$entry.ExpectedSizeBytes) "Game Config provenance mirror size mismatch: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.ExpectedSha256 -match '^[A-Fa-f0-9]{64}$') "Game Config provenance SHA-256 is malformed: $($entry.Id)"
    Assert-BoostLabCondition ($entry.ArtifactProvenanceApproved -eq $true) "Game Config provenance approval flag missing: $($entry.Id)"
    Assert-BoostLabCondition ($entry.RuntimeSourceSelectionApproved -eq $true) "Game Config provenance must approve runtime source selection: $($entry.Id)"
    Assert-BoostLabCondition ($entry.ProductionAllowlistApproved -eq $false) "Game Config provenance must not approve production allowlist: $($entry.Id)"
    Assert-BoostLabCondition ($entry.DownloadExecutionApproved -eq $true) "Game Config provenance must approve verified mirror downloads: $($entry.Id)"
    Assert-BoostLabCondition ($entry.InstallerExecutionApproved -eq $false) "Game Config provenance must not approve installers: $($entry.Id)"
    foreach ($requirement in @('FileName', 'SHA256', 'FileSize', 'MirrorUrl', 'LocalFileOnly', 'NoDirectNetworkExecution')) {
        Assert-BoostLabCondition ($requirement -in @($entry.VerificationRequirements | ForEach-Object { [string]$_ })) "Game Config provenance missing verification requirement '$requirement': $($entry.Id)"
    }
}

$sourceProvenanceIds = @($payloadSources | ForEach-Object { [string]$_.ArtifactProvenanceId } | Sort-Object)
$recordIds = @($provenanceApprovals | ForEach-Object { [string]$_.Id } | Sort-Object)
Assert-BoostLabCondition ((@($sourceProvenanceIds) -join '|') -eq (@($recordIds) -join '|')) 'Game Config payload source/provenance id sets differ.'

$inspectorSource = $payloadSources | Where-Object { [string]$_.ExpectedFileName -eq 'inspector.exe' } | Select-Object -First 1
$inspectorProvenance = $provenanceApprovals | Where-Object { [string]$_.ExpectedFileName -eq 'inspector.exe' } | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $inspectorSource) 'Game Config inspector.exe source record is missing.'
Assert-BoostLabCondition ($null -ne $inspectorProvenance) 'Game Config inspector.exe provenance record is missing.'
Assert-BoostLabCondition ([string]$inspectorSource.OperationKind -eq 'DownloadExecutable') 'inspector.exe must be classified as an executable download payload.'
Assert-BoostLabCondition ([string]$inspectorSource.AuthenticodeStatus -eq 'NotSigned') 'inspector.exe signature evidence must remain NotSigned.'
Assert-BoostLabCondition ([string]$inspectorSource.ExpectedSha256 -eq '7D5510DEEAACB50C88A49BBF1D894DAE44C5CE58C00D5A88392346646B14E8F3') 'inspector.exe SHA-256 evidence changed.'
Assert-BoostLabCondition ($inspectorProvenance.AllowExecution -eq $true) 'inspector.exe must be executable only through the selected Battlefield 6 / Frag Punk Stage 8 recipes.'
Assert-BoostLabCondition ('UnsignedExecutableExactHash' -in @($inspectorProvenance.VerificationRequirements | ForEach-Object { [string]$_ })) 'inspector.exe provenance must require exact hash verification.'

$zipSources = @($payloadSources | Where-Object { [string]$_.ExpectedFileName -like '*.zip' })
Assert-BoostLabCondition ($zipSources.Count -eq 27) 'Game Configs must record exactly 27 ZIP payloads.'
foreach ($zip in $zipSources) {
    Assert-BoostLabCondition ([string]$zip.OperationKind -eq 'DownloadArchive') "ZIP payload must be classified as DownloadArchive: $($zip.Id)"
    $zipProvenance = $provenanceApprovals | Where-Object { [string]$_.Id -eq [string]$zip.ArtifactProvenanceId } | Select-Object -First 1
    Assert-BoostLabCondition ($zipProvenance.AllowExecution -eq $false) "ZIP payloads must not be directly executable: $($zip.Id)"
    Assert-BoostLabCondition ('ArchivePayload' -in @($zipProvenance.VerificationRequirements | ForEach-Object { [string]$_ })) "ZIP payload provenance must require ArchivePayload verification: $($zip.Id)"
}

$gameStage = @($stages.Stages | Where-Object { [string]$_.Name -eq 'Game Configs' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $gameStage) 'Stage 8 Game Configs UI/runtime stage is missing.'
Assert-BoostLabCondition ([int]$gameStage.Order -eq 8) 'Game Configs must be Stage 8.'
$gameTool = @($gameStage.Tools | Where-Object { [string]$_.Id -eq 'game-configs' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $gameTool) 'Game Configs runtime tool is not registered.'
Assert-BoostLabCondition ((@($gameTool.Actions) -join '|') -eq 'Apply') 'Game Configs must expose Apply only.'
Assert-BoostLabCondition ([string]$gameTool.SelectionMode -eq 'SingleSelect') 'Game Configs must use a single-select game selector.'
Assert-BoostLabCondition ((@($gameTool.SelectionRequiredActions) -join '|') -eq 'Apply') 'Game Configs must require selection for Apply only.'
Assert-BoostLabCondition (@($gameTool.SelectionItems).Count -eq 27) 'Game Configs must expose exactly 27 selectable entries.'
Assert-BoostLabCondition ((@($gameTool.SelectionItems | ForEach-Object { [string]$_.Id } | Sort-Object) -join '|') -eq ((@($runtimeGames | ForEach-Object { [string]$_.GameId } | Sort-Object) -join '|'))) 'Stage selection items must match the runtime Game Config manifest.'
Assert-BoostLabCondition (@($gameTool.Actions | Where-Object { [string]$_ -in @('Analyze', 'Open', 'Default', 'Restore', 'Backup') }).Count -eq 0) 'Game Configs must not invent Analyze/Open/Default/Restore/Backup actions.'
Assert-BoostLabCondition (@($allowlist.ProductionAllowlistProposals | Where-Object { [string]$_.ToolId -eq 'game-configs' }).Count -eq 0) 'Game Configs must not add production allowlist proposals.'

$bf6 = $runtimeGames | Where-Object { [string]$_.GameId -eq 'battlefield-6' } | Select-Object -First 1
$fragPunk = $runtimeGames | Where-Object { [string]$_.GameId -eq 'frag-punk' } | Select-Object -First 1
$bf3 = $runtimeGames | Where-Object { [string]$_.GameId -eq 'battlefield-3' } | Select-Object -First 1
$badCompany2 = $runtimeGames | Where-Object { [string]$_.GameId -eq 'battlefield-bad-company-2' } | Select-Object -First 1
Assert-BoostLabCondition ($bf6.NeedsInspector -eq $true) 'Battlefield 6 must use the inspector flow.'
Assert-BoostLabCondition ($fragPunk.NeedsInspector -eq $true) 'Frag Punk must use the inspector flow.'
Assert-BoostLabCondition ($bf3.OpensUrl -eq $true) 'Battlefield 3 browser-open behavior must be represented.'
Assert-BoostLabCondition ($badCompany2.OpensUrl -eq $true) 'Battlefield Bad Company 2 browser-open behavior must be represented.'

$runtimeManifestText = Get-Content -LiteralPath $runtimeManifestPath -Raw
$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($forbiddenText in @(
    'Invoke-Expression'
    'irm | iex'
    'FR33THYFR33THY/Github-Game-Configs/raw'
    'AllowScripts.cmd'
)) {
    if ($forbiddenText -eq 'AllowScripts.cmd') {
        Assert-BoostLabCondition ($moduleText -notlike "*$forbiddenText*") "Game Configs module must not include launcher path text: $forbiddenText"
    }
    else {
        Assert-BoostLabCondition ($moduleText -notlike "*$forbiddenText*") "Game Configs module must not contain runtime-forbidden text: $forbiddenText"
        Assert-BoostLabCondition ($runtimeManifestText -notlike "*$forbiddenText*") "Game Configs runtime manifest must not contain runtime-forbidden text: $forbiddenText"
    }
}

Write-Host 'Game Configs Stage 8 artifact mirror and metadata validated.'
