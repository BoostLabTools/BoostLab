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
        throw 'Unable to determine the DirectX provenance validator path.'
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
$modulePath = Join-Path $ProjectRoot 'modules\Graphics\DirectX.psm1'
$manifestPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$reviewPath = Join-Path $ProjectRoot 'docs\directx-provenance-review.md'
$readinessPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$migrationRecordPath = Join-Path $ProjectRoot 'docs\migrations\directx.md'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

foreach ($requiredPath in @(
    $sourcePath
    $modulePath
    $manifestPath
    $reviewPath
    $readinessPath
    $migrationRecordPath
)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $requiredPath -PathType Leaf) "Required DirectX provenance file is missing: $requiredPath"
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
Assert-BoostLabCondition (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) 'DirectX module must no longer be a placeholder.'
Assert-BoostLabTextContains -Text $moduleText -Needle '$script:BoostLabImplementedActions = @(''Analyze'', ''Open'', ''Apply'', ''Default'', ''Restore'')' -Description 'DirectX implemented actions'
foreach ($requiredPhrase in @(
    'ManualHandoffPrepared'
    'AutoBlockedUntilArtifactApproval'
    'DefaultUnavailable'
    'RestoreUnavailable'
    'No browser, external tool, 7-Zip download/install, DirectX download, extraction, setup launch, registry change, shortcut cleanup, file cleanup, or system mutation occurred.'
    $expectedSourceHash
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $requiredPhrase -Description 'DirectX module controlled manual handoff text'
}
foreach ($forbiddenCommand in @(
    'Invoke-WebRequest'
    'Start-Process'
    'Invoke-BoostLabInstallerExecution'
    'New-BoostLabArtifactDownloadRequest'
)) {
    Assert-BoostLabCondition (-not $moduleText.Contains($forbiddenCommand)) "DirectX module contains prohibited execution helper text: $forbiddenCommand"
}

$manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
$artifacts = @($manifest.Artifacts)
Assert-BoostLabCondition ($artifacts.Count -eq 0) "Expected no approved production artifacts, found $($artifacts.Count)."
foreach ($artifact in $artifacts) {
    if (
        [string]$artifact.Id -match 'directx|7zip' -or
        @($artifact.SourceToolIds) -contains 'directx'
    ) {
        throw "DirectX artifact was added without complete approval: $($artifact.Id)"
    }
}

$reviewText = Get-Content -LiteralPath $reviewPath -Raw
foreach ($requiredPhrase in @(
    '# DirectX Artifact Provenance Review'
    'DirectX is implemented as a controlled manual-handoff tool only.'
    '`Apply` fails closed with'
    '`AutoBlockedUntilArtifactApproval`'
    'No real DirectX or 7-Zip artifact is approved.'
    'Until that package exists, DirectX Auto remains blocked.'
    'manual handoff instructions inside'
    $expectedSourceHash
)) {
    Assert-BoostLabTextContains -Text $reviewText -Needle $requiredPhrase -Description 'DirectX provenance review'
}

$readinessText = Get-Content -LiteralPath $readinessPath -Raw
foreach ($requiredPhrase in @(
    'Foundation-ready but needs artifact provenance approvals: **5**'
    'Candidate for next implementation attempt: **0**'
    'Implemented in Phase 100 as controlled manual handoff'
    'Phase 100 manual handoff complete; Auto remains blocked'
    'docs/directx-provenance-review.md'
)) {
    Assert-BoostLabTextContains -Text $readinessText -Needle $requiredPhrase -Description 'Deferred readiness review Phase 100 result'
}

$migrationText = Get-Content -LiteralPath $migrationRecordPath -Raw
foreach ($requiredPhrase in @(
    '# DirectX Migration Record'
    $expectedSourceHash
    'Analyze'
    'Open'
    'Apply'
    'Default'
    'Restore'
    'AutoBlockedUntilArtifactApproval'
    'DefaultUnavailable'
    'RestoreUnavailable'
    'does not download 7-Zip or DirectX'
)) {
    Assert-BoostLabTextContains -Text $migrationText -Needle $requiredPhrase -Description 'DirectX migration record'
}

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration.Stages | ForEach-Object { $_.Tools })
$directXTool = @($tools | Where-Object { $_.Id -eq 'directx' })[0]
Assert-BoostLabCondition ($null -ne $directXTool) 'DirectX tool is missing from config.'
Assert-BoostLabCondition ((@($directXTool.Actions) -join '|') -eq 'Analyze|Open|Apply|Default|Restore') 'DirectX actions mismatch.'

$allModules = @(
    Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1' |
        Where-Object { $_.Directory.Parent.FullName -eq $modulesRoot }
)
$implementedModules = @(
    $allModules | Where-Object {
        (Get-Content -LiteralPath $_.FullName -Raw).Contains('$script:BoostLabImplementedActions')
    }
)
$placeholderModules = @(
    $allModules | Where-Object {
        (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1')
    }
)
Assert-BoostLabCondition ($tools.Count -eq 55) "Expected 55 active tools, found $($tools.Count)."
Assert-BoostLabCondition ($allModules.Count -eq 55) "Expected 55 modules, found $($allModules.Count)."
Assert-BoostLabCondition ($implementedModules.Count -eq 41) "Expected 41 implemented modules, found $($implementedModules.Count)."
Assert-BoostLabCondition ($placeholderModules.Count -eq 14) "Expected 14 placeholder modules, found $($placeholderModules.Count)."

$activeNames = @(
    $tools | ForEach-Object {
        ([string]$_.Id -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()
        ([string]$_.Title -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()
    }
)
foreach ($deletedTool in @('Loudness EQ', 'NVME Faster Driver')) {
    $normalized = ($deletedTool -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()
    Assert-BoostLabCondition ($normalized -notin $activeNames) "Deleted tool was reintroduced: $deletedTool"
}

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
    Success                   = $true
    DirectXImplemented        = $true
    ProductionArtifactCount   = $artifacts.Count
    DirectXArtifactApproved   = $false
    ImplementedModuleCount    = $implementedModules.Count
    PlaceholderModuleCount    = $placeholderModules.Count
    SourceUltimateUnchanged   = $true
    Message                   = 'DirectX controlled manual handoff is implemented; Auto remains denied until immutable artifact provenance and installer approvals exist.'
    Timestamp                 = Get-Date
}
