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
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$allowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'

foreach ($requiredPath in @(
    $externalPath
    $provenancePath
    $sourceManifestPath
    $provenanceManifestPath
    $stagesPath
    $allowlistPath
)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $requiredPath -PathType Leaf) "Required Phase 165C file is missing: $requiredPath"
}

$external = Import-PowerShellDataFile -LiteralPath $externalPath
$provenance = Import-PowerShellDataFile -LiteralPath $provenancePath
$sources = Import-PowerShellDataFile -LiteralPath $sourceManifestPath
$gameProvenance = Import-PowerShellDataFile -LiteralPath $provenanceManifestPath
$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$allowlist = Import-PowerShellDataFile -LiteralPath $allowlistPath

Assert-BoostLabCondition (@($external.ExternalSources).Count -eq 50) 'Existing active-stage external artifact source count changed.'
Assert-BoostLabCondition (@($provenance.ProvenanceOnlyApprovals).Count -eq 28) 'Existing provenance-only approval count changed.'
Assert-BoostLabCondition ([string]$external.GameConfigPayloadSourceManifest.Path -eq 'config/GameConfigArtifactSources.psd1') 'External artifact manifest does not point at the Game Configs source manifest.'
Assert-BoostLabCondition ([int]$external.GameConfigPayloadSourceManifest.RecordCount -eq 28) 'External artifact Game Config pointer count mismatch.'
Assert-BoostLabCondition ([string]$provenance.GameConfigPayloadProvenanceManifest.Path -eq 'config/GameConfigArtifactProvenance.psd1') 'Artifact provenance manifest does not point at the Game Configs provenance manifest.'
Assert-BoostLabCondition ([int]$provenance.GameConfigPayloadProvenanceManifest.RecordCount -eq 28) 'Artifact provenance Game Config pointer count mismatch.'

$payloadSources = @($sources.PayloadSources)
$provenanceApprovals = @($gameProvenance.ProvenanceApprovals)
Assert-BoostLabCondition ($payloadSources.Count -eq 28) 'Phase 165C must record exactly 28 Game Config payload sources.'
Assert-BoostLabCondition ($provenanceApprovals.Count -eq 28) 'Phase 165C must record exactly 28 Game Config provenance records.'
Assert-BoostLabCondition ([string]$sources.Release.Tag -eq 'boostlab-game-configs-v1') 'Game Config source manifest release tag mismatch.'
Assert-BoostLabCondition ([string]$gameProvenance.Release.Tag -eq 'boostlab-game-configs-v1') 'Game Config provenance manifest release tag mismatch.'
Assert-BoostLabCondition ([int]$sources.Release.HeadVerifiedCount -eq 28) 'Game Config mirror HEAD verification count mismatch.'
Assert-BoostLabCondition ([int]$gameProvenance.Release.HeadVerifiedCount -eq 28) 'Game Config provenance HEAD verification count mismatch.'
Assert-BoostLabCondition ($sources.RuntimeSourceSelectionApproved -eq $false) 'Phase 165C must not approve Stage 8 runtime source selection.'
Assert-BoostLabCondition ($gameProvenance.RuntimeSourceSelectionApproved -eq $false) 'Phase 165C must not approve Stage 8 provenance runtime selection.'
Assert-BoostLabCondition ($sources.ProductionAllowlistApproved -eq $false) 'Phase 165C must not add Game Config production allowlist approval.'
Assert-BoostLabCondition ($gameProvenance.ProductionAllowlistApproved -eq $false) 'Phase 165C provenance must not add production allowlist approval.'

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
    Assert-BoostLabCondition ($entry.ArtifactProvenanceOnlyApproved -eq $true) "Game Config provenance-only approval not recorded: $($entry.Id)"
    Assert-BoostLabCondition ($entry.ProductionAllowlistApproved -eq $false) "Game Config payload must not be production allowlist-approved yet: $($entry.Id)"
    Assert-BoostLabCondition ($entry.RuntimeSourceSelectionApproved -eq $false) "Game Config payload must not be runtime source-selection approved before Stage 8: $($entry.Id)"
    Assert-BoostLabCondition ($entry.DownloadExecutionApproved -eq $false) "Game Config payload must not approve runtime downloads in Phase 165C: $($entry.Id)"
    Assert-BoostLabCondition ($entry.InstallerExecutionApproved -eq $false) "Game Config payload must not approve installers in Phase 165C: $($entry.Id)"
}

foreach ($entry in $provenanceApprovals) {
    Assert-BoostLabCondition ($provenanceIds.Add([string]$entry.Id)) "Duplicate Game Config provenance id: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.SourceToolId -eq 'game-configs') "Unexpected Game Config provenance tool id: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.ApprovalStatus -eq 'ApprovedForProvenanceOnly') "Game Config provenance approval status mismatch: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.ProductionApprovalStatus -eq 'NotApproved') "Game Config provenance production status mismatch: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.VerifiedBoostLabMirrorUrl -like 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/*') "Game Config provenance mirror URL mismatch: $($entry.Id)"
    Assert-BoostLabCondition ([int64]$entry.MirrorContentLength -eq [int64]$entry.ExpectedSizeBytes) "Game Config provenance mirror size mismatch: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.ExpectedSha256 -match '^[A-Fa-f0-9]{64}$') "Game Config provenance SHA-256 is malformed: $($entry.Id)"
    Assert-BoostLabCondition ($entry.ArtifactProvenanceApproved -eq $true) "Game Config provenance approval flag missing: $($entry.Id)"
    Assert-BoostLabCondition ($entry.RuntimeSourceSelectionApproved -eq $false) "Game Config provenance must not approve runtime source selection: $($entry.Id)"
    Assert-BoostLabCondition ($entry.ProductionAllowlistApproved -eq $false) "Game Config provenance must not approve production allowlist: $($entry.Id)"
    Assert-BoostLabCondition ($entry.DownloadExecutionApproved -eq $false) "Game Config provenance must not approve downloads: $($entry.Id)"
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
Assert-BoostLabCondition ('UnsignedExecutableExactHash' -in @($inspectorProvenance.VerificationRequirements | ForEach-Object { [string]$_ })) 'inspector.exe provenance must require exact hash verification.'

$zipSources = @($payloadSources | Where-Object { [string]$_.ExpectedFileName -like '*.zip' })
Assert-BoostLabCondition ($zipSources.Count -eq 27) 'Phase 165C must record exactly 27 Game Config ZIP payloads.'
foreach ($zip in $zipSources) {
    Assert-BoostLabCondition ([string]$zip.OperationKind -eq 'DownloadArchive') "ZIP payload must be classified as DownloadArchive: $($zip.Id)"
    $zipProvenance = $provenanceApprovals | Where-Object { [string]$_.Id -eq [string]$zip.ArtifactProvenanceId } | Select-Object -First 1
    Assert-BoostLabCondition ('ArchivePayload' -in @($zipProvenance.VerificationRequirements | ForEach-Object { [string]$_ })) "ZIP payload provenance must require ArchivePayload verification: $($zip.Id)"
}

$allStageNames = @($stages.Stages | ForEach-Object { [string]$_.Name })
$allToolIds = @($stages.Stages | ForEach-Object { @($_.Tools) } | ForEach-Object { [string]$_.Id })
Assert-BoostLabCondition ('Game Configs' -notin $allStageNames) 'Phase 165C must not implement the Stage 8 Game Configs UI/runtime stage.'
Assert-BoostLabCondition ('game-configs' -notin $allToolIds) 'Phase 165C must not register a Game Configs runtime tool.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'modules\GameConfigs'))) 'Phase 165C must not add Game Configs runtime modules.'
Assert-BoostLabCondition (@($allowlist.ProductionAllowlistProposals | Where-Object { [string]$_.ToolId -eq 'game-configs' }).Count -eq 0) 'Phase 165C must not add Game Configs production allowlist proposals.'

Write-Host 'Game Configs artifact mirror metadata validated.'
