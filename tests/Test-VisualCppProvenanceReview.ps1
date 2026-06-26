[CmdletBinding()]
param(
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'BoostLab.Hashing.ps1')
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $scriptPath = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $PSCommandPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $MyInvocation.MyCommand.Path
    }
    else {
        throw 'Unable to determine the Visual C++ provenance validator path.'
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

function Assert-BoostLabTextContains {
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

$expectedSourceHash = '01D6A5FAFD5E7C1FB9DA1913BD17C543EE0F8A4A7E2A7DF5583A50AEF1D82374'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\5 Graphics\3 C++.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Graphics\visual-cpp.psm1'
$reviewPath = Join-Path $ProjectRoot 'docs\visual-cpp-provenance-review.md'
$migrationRecordPath = Join-Path $ProjectRoot 'docs\migrations\visual-cpp.md'
$externalSourcesPath = Join-Path $ProjectRoot 'config\ExternalArtifactSources.psd1'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$allowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'

foreach ($requiredPath in @($sourcePath, $modulePath, $reviewPath, $migrationRecordPath, $externalSourcesPath, $artifactPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $requiredPath -PathType Leaf) "Required Visual C++ provenance file is missing: $requiredPath"
}

$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Visual C++ Ultimate source checksum changed: $actualSourceHash"

$packageFiles = @(
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
)

$sourceText = Get-Content -LiteralPath $sourcePath -Raw
$moduleText = Get-Content -LiteralPath $modulePath -Raw
$reviewText = Get-Content -LiteralPath $reviewPath -Raw
$migrationText = Get-Content -LiteralPath $migrationRecordPath -Raw
$externalSources = Import-PowerShellDataFile -LiteralPath $externalSourcesPath
$artifactProvenance = Import-PowerShellDataFile -LiteralPath $artifactPath

foreach ($packageFile in $packageFiles) {
    $url = "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/$packageFile"
    Assert-BoostLabTextContains -Text $sourceText -Needle "refs/heads/main/$packageFile" -Description 'Visual C++ source package URL'
    Assert-BoostLabTextContains -Text $moduleText -Needle 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main' -Description 'Visual C++ runtime URL base'
    Assert-BoostLabTextContains -Text $moduleText -Needle $packageFile -Description 'Visual C++ runtime URL package'
    Assert-BoostLabTextContains -Text $reviewText -Needle $packageFile -Description 'Visual C++ provenance package list'
}

foreach ($sourceBehavior in @(
    'Test-Connection -ComputerName "8.8.8.8"',
    'Start-Process',
    '/q',
    '/qb',
    '/passive /norestart'
)) {
    Assert-BoostLabTextContains -Text $sourceText -Needle $sourceBehavior -Description 'Visual C++ source installer behavior'
}

Assert-BoostLabTextContains -Text $moduleText -Needle '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'')' -Description 'Visual C++ implemented actions'
Assert-BoostLabTextContains -Text $moduleText -Needle 'Invoke-BoostLabVisualCppVerifiedArtifactDownload' -Description 'Visual C++ verified artifact download command'
Assert-BoostLabTextContains -Text $moduleText -Needle 'Start-Process' -Description 'Visual C++ source-equivalent installer command'
Assert-BoostLabTextContains -Text $moduleText -Needle 'OperationExecutor' -Description 'Visual C++ test-safe executor seam'
Assert-BoostLabCondition (-not $moduleText.Contains('ManualHandoffOnly')) 'Visual C++ module must not remain ManualHandoffOnly.'
Assert-BoostLabCondition (-not $moduleText.Contains('AutoBlockedUntilArtifactApproval')) 'Visual C++ module must not keep Auto blocked status.'

$visualEntries = @($externalSources.ExternalSources | Where-Object { [string]$_.ToolId -eq 'visual-cpp' })
Assert-BoostLabCondition ($visualEntries.Count -eq 12) 'Visual C++ must classify exactly twelve external source artifacts.'
foreach ($entry in $visualEntries) {
    Assert-BoostLabCondition ([string]$entry.SourceClassification -eq 'UltimateAuthorHostedArtifact') "Visual C++ artifact must remain UltimateAuthorHostedArtifact: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.MirrorStatus -eq 'BoostLabMirrorAvailable') "Visual C++ artifact must use verified BoostLab mirror status: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.ExpectedSha256 -match '^[A-Fa-f0-9]{64}$') "Visual C++ artifact must carry Phase 164B/164C SHA evidence: $($entry.Id)"
    Assert-BoostLabCondition ([int64]$entry.ExpectedSizeBytes -gt 0) "Visual C++ artifact must carry Phase 164B/164C size evidence: $($entry.Id)"
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$entry.VerifiedBoostLabMirrorUrl)) "Visual C++ artifact must carry verified mirror URL: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.IntendedBoostLabMirrorUrl -eq [string]$entry.VerifiedBoostLabMirrorUrl) "Visual C++ runtime mirror must match verified mirror URL: $($entry.Id)"
    Assert-BoostLabCondition ($entry.ContainsKey('BoostLabMirrorAvailable') -and $entry.BoostLabMirrorAvailable -eq $true) "Visual C++ mirror must be available: $($entry.Id)"
    Assert-BoostLabCondition ($entry.ContainsKey('ArtifactProvenanceApproved') -and $entry.ArtifactProvenanceApproved -eq $true) "Visual C++ provenance approval missing: $($entry.Id)"
    Assert-BoostLabCondition ($entry.ContainsKey('ProductionAllowlistApproved') -and $entry.ProductionAllowlistApproved -eq $true) "Visual C++ production approval missing: $($entry.Id)"
    Assert-BoostLabCondition ($entry.ContainsKey('RuntimeSourceSelectionApproved') -and $entry.RuntimeSourceSelectionApproved -eq $true) "Visual C++ runtime source selection approval missing: $($entry.Id)"
    Assert-BoostLabCondition ($entry.ContainsKey('DownloadExecutionApproved') -and $entry.DownloadExecutionApproved -eq $true) "Visual C++ download approval missing: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.ReleaseReadiness -eq 'RuntimeApprovedPendingOfficialVendorDirectClosure') "Visual C++ release readiness mismatch: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.OriginalDownloadUrl -like 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/vcredist*.exe') "Visual C++ source URL mismatch: $($entry.Id)"
}

Assert-BoostLabCondition (@($artifactProvenance.Artifacts).Count -eq 0) 'No Visual C++ artifact provenance approvals may be added.'
if (Test-Path -LiteralPath $allowlistPath -PathType Leaf) {
    $allowlistText = Get-Content -LiteralPath $allowlistPath -Raw
    Assert-BoostLabCondition (-not $allowlistText.Contains('visual-cpp')) 'Visual C++ must not be added to production allowlists.'
}

foreach ($requiredPhrase in @(
    '# Visual C++ Artifact Provenance Review',
    'Phase 130 supersedes the manual-handoff-only runtime',
    'source-equivalent controlled behavior accepted by Yazan as near parity',
    'These entries classify source URLs only. They are not artifact approvals.',
    'No real Visual C++ redistributable is approved as a reusable BoostLab'
)) {
    Assert-BoostLabTextContains -Text $reviewText -Needle $requiredPhrase -Description 'Visual C++ provenance review'
}

foreach ($requiredPhrase in @(
    '# Visual C++ Migration Record',
    'Phase 130 replaces the earlier manual-handoff implementation',
    'source-equivalent controlled runtime',
    'No `config/ArtifactProvenance.psd1`',
    'DoneYazanAcceptedNearParity'
)) {
    Assert-BoostLabTextContains -Text $migrationText -Needle $requiredPhrase -Description 'Visual C++ migration record'
}

$binaryExtensions = @('.exe', '.msi', '.zip', '.7z', '.xpi', '.dll')
$binaryFiles = @(
    Get-ChildItem -LiteralPath $ProjectRoot -Recurse -File -ErrorAction Stop |
        Where-Object {
            $_.FullName -notlike '*\.git\*' -and
            $binaryExtensions -contains $_.Extension.ToLowerInvariant()
        }
)
Assert-BoostLabCondition ($binaryFiles.Count -eq 0) 'No binary artifact files may be added for Visual C++.'

Assert-BoostLabTestProtectedPathsClean `
    -ProjectRoot $ProjectRoot `
    -ProtectedPath @('source-ultimate', 'source-ultimate\_intake-promoted', 'intake') `
    -Message 'Protected source/intake paths changed during Visual C++ provenance phase'

Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\23 NVME Faster Driver.ps1'))) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    TestName                     = 'Visual C++ provenance review'
    SourcePath                   = $sourcePath
    SourceSha256                 = $actualSourceHash
    ExternalSourceEntries        = $visualEntries.Count
    ArtifactProvenanceApprovals  = @($artifactProvenance.Artifacts).Count
    RuntimeUrlsChanged           = $true
    BinaryFilesAdded             = $binaryFiles.Count
    SourceUltimateUnchanged      = $true
    DeletedToolsRemainDeleted    = $true
    Message                      = 'Visual C++ source-equivalent runtime uses verified BoostLab mirror artifacts with SHA, size, provenance, and production/runtime approval gates.'
}
