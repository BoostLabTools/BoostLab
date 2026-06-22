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
        throw 'Unable to determine the DirectX artifact source review validator path.'
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

function Assert-BoostLabTextContains {
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [string]$Needle,

        [Parameter(Mandatory)]
        [string]$Description
    )

    if (-not $Text.Contains($Needle)) {
        throw "$Description is missing: $Needle"
    }
}

$sourcePath = Join-Path $ProjectRoot 'source-ultimate\5 Graphics\2 DirectX.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Graphics\directx.psm1'
$artifactProvenancePath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$externalSourcesPath = Join-Path $ProjectRoot 'config\ExternalArtifactSources.psd1'
$reviewPath = Join-Path $ProjectRoot 'docs\directx-provenance-review.md'
$migrationRecordPath = Join-Path $ProjectRoot 'docs\migrations\directx.md'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

foreach ($requiredPath in @(
    $sourcePath
    $modulePath
    $artifactProvenancePath
    $externalSourcesPath
    $reviewPath
    $migrationRecordPath
    $configPath
)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $requiredPath -PathType Leaf) "Required DirectX review file is missing: $requiredPath"
}

$expectedSourceHash = '17051A2F0F7A0CF16BE525121720406E8F1630C94E5977A7CD4C18652A87EE05'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "DirectX Ultimate source checksum changed: $actualSourceHash"

$sourceText = Get-Content -LiteralPath $sourcePath -Raw
foreach ($sourceBehavior in @(
    'refs/heads/main/7zip.exe'
    'Start-Process -Wait "$env:SystemRoot\Temp\7zip.exe" -ArgumentList "/S"'
    'HKEY_CURRENT_USER\Software\7-Zip\Options'
    'refs/heads/main/directx.exe'
    'Program Files\7-Zip\7z.exe'
    'DXSETUP.exe'
)) {
    Assert-BoostLabTextContains -Text $sourceText -Needle $sourceBehavior -Description 'DirectX source reviewed behavior'
}

$moduleText = Get-Content -LiteralPath $modulePath -Raw
Assert-BoostLabCondition (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) 'DirectX module must not be a placeholder.'
foreach ($requiredPhrase in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'')',
    'SourceEquivalentControlledRuntime',
    'SourceEquivalentDirectXInstall',
    'Invoke-BoostLabDirectXVerifiedArtifactDownload',
    'Start-Process',
    'New-ItemProperty',
    'Move-Item',
    'Remove-Item',
    'BoostLabMirrorAvailable',
    $expectedSourceHash
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $requiredPhrase -Description 'DirectX source-equivalent module text'
}
Assert-BoostLabCondition (-not $moduleText.Contains('AutoBlockedUntilArtifactApproval')) 'DirectX Apply must not remain blocked as AutoBlockedUntilArtifactApproval.'
Assert-BoostLabCondition (-not $moduleText.Contains('ManualHandoffPrepared')) 'DirectX must not remain manual handoff.'

$artifactProvenance = Import-PowerShellDataFile -LiteralPath $artifactProvenancePath
$artifacts = @($artifactProvenance.Artifacts)
Assert-BoostLabCondition ($artifacts.Count -eq 0) "Expected no approved production artifacts, found $($artifacts.Count)."

$externalSources = Import-PowerShellDataFile -LiteralPath $externalSourcesPath
$directXEntries = @($externalSources.ExternalSources | Where-Object { [string]$_.ToolId -eq 'directx' })
Assert-BoostLabCondition ($directXEntries.Count -eq 2) 'External artifact source manifest must track DirectX 7zip.exe and directx.exe.'
foreach ($entry in $directXEntries) {
    Assert-BoostLabCondition ([string]$entry.SourceClassification -eq 'UltimateAuthorHostedArtifact') "DirectX entry must remain author-hosted: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.MirrorStatus -eq 'BoostLabMirrorAvailable') "DirectX entry must use verified BoostLab mirror status: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.ExpectedSha256 -match '^[A-Fa-f0-9]{64}$') "DirectX entry must carry Phase 164B/164C SHA evidence: $($entry.Id)"
    Assert-BoostLabCondition ([int64]$entry.ExpectedSizeBytes -gt 0) "DirectX entry must carry Phase 164B/164C size evidence: $($entry.Id)"
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$entry.VerifiedBoostLabMirrorUrl)) "DirectX entry must carry verified mirror URL: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.IntendedBoostLabMirrorUrl -eq [string]$entry.VerifiedBoostLabMirrorUrl) "DirectX runtime mirror must match verified mirror URL: $($entry.Id)"
    Assert-BoostLabCondition ($entry.ContainsKey('BoostLabMirrorAvailable') -and $entry.BoostLabMirrorAvailable -eq $true) "DirectX mirror must be available: $($entry.Id)"
    Assert-BoostLabCondition ($entry.ContainsKey('ArtifactProvenanceApproved') -and $entry.ArtifactProvenanceApproved -eq $true) "DirectX provenance approval missing: $($entry.Id)"
    Assert-BoostLabCondition ($entry.ContainsKey('ProductionAllowlistApproved') -and $entry.ProductionAllowlistApproved -eq $true) "DirectX production approval missing: $($entry.Id)"
    Assert-BoostLabCondition ($entry.ContainsKey('RuntimeSourceSelectionApproved') -and $entry.RuntimeSourceSelectionApproved -eq $true) "DirectX runtime source selection approval missing: $($entry.Id)"
    Assert-BoostLabCondition ($entry.ContainsKey('DownloadExecutionApproved') -and $entry.DownloadExecutionApproved -eq $true) "DirectX download approval missing: $($entry.Id)"
    Assert-BoostLabCondition ([string]$entry.ReleaseReadiness -eq 'RuntimeApprovedPendingOfficialVendorDirectClosure') "DirectX release readiness mismatch: $($entry.Id)"
}

$reviewText = Get-Content -LiteralPath $reviewPath -Raw
foreach ($requiredPhrase in @(
    '# DirectX Artifact Source Review',
    'Phase 129 implements DirectX as a source-equivalent controlled runtime',
    'no entry is added to `config/ArtifactProvenance.psd1`',
    '`UltimateAuthorHostedArtifact` with',
    '`NeedsBoostLabMirror`',
    'Exact SHA-256 for `7zip.exe`',
    'Exact SHA-256 for `directx.exe`',
    'Future Mirror Approval Package',
    $expectedSourceHash
)) {
    Assert-BoostLabTextContains -Text $reviewText -Needle $requiredPhrase -Description 'DirectX artifact source review'
}

$migrationText = Get-Content -LiteralPath $migrationRecordPath -Raw
foreach ($requiredPhrase in @(
    '# DirectX Migration Record',
    'Phase 129 upgrades DirectX',
    'source-equivalent controlled runtime',
    'Analyze',
    'Apply',
    'Open',
    'Default',
    'Restore',
    'Install 7-Zip',
    'Launch `%SystemRoot%\Temp\directx\DXSETUP.exe`',
    'NeedsBoostLabMirror',
    'no artifact provenance record',
    $expectedSourceHash
)) {
    Assert-BoostLabTextContains -Text $migrationText -Needle $requiredPhrase -Description 'DirectX migration record'
}

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration.Stages | ForEach-Object { $_.Tools })
$directXTool = @($tools | Where-Object { $_.Id -eq 'directx' })[0]
Assert-BoostLabCondition ($null -ne $directXTool) 'DirectX tool is missing from config.'
Assert-BoostLabCondition ((@($directXTool.Actions) -join '|') -eq 'Analyze|Apply') 'DirectX actions mismatch.'

$inventory = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
Assert-BoostLabCondition ([int]$inventory.Snapshot.ActiveTools -eq [int]$inventory.Baseline.ActiveTools) 'Active tool count changed.'
Assert-BoostLabCondition ([int]$inventory.Snapshot.ImplementedTools -eq [int]$inventory.Baseline.ImplementedTools) 'Implemented tool count changed.'
Assert-BoostLabCondition ([int]$inventory.Snapshot.DeferredPlaceholders -eq [int]$inventory.Baseline.DeferredPlaceholders) 'Deferred placeholder count changed.'

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Sort-Object {
            $_.FullName.Substring($root.Length + 1).Replace('\', '/')
        } |
        ForEach-Object {
            '{0}|{1}' -f `
                $_.FullName.Substring($root.Length + 1).Replace('\', '/'), `
                (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
        }
)
$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $sourceManifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash(
            [Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n"))
        )
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}
Assert-BoostLabCondition (@($sourceLines).Count -eq 49) "source-ultimate file count changed: $(@($sourceLines).Count)"
Assert-BoostLabCondition ($sourceManifestHash -eq '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') 'source-ultimate content or paths changed.'

[pscustomobject]@{
    Success = $true
    DirectXImplemented = $true
    ProductionArtifactCount = $artifacts.Count
    DirectXExternalSourceEntries = $directXEntries.Count
    DirectXArtifactApproved = $true
    SourceUltimateUnchanged = $true
    Message = 'DirectX source-equivalent runtime uses verified BoostLab mirror artifacts with SHA, size, provenance, and production/runtime approval gates.'
    Timestamp = Get-Date
}
