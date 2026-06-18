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

$sourcePath = Join-Path $ProjectRoot 'source-ultimate\5 Graphics\2 DirectX.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Graphics\DirectX.psm1'
$manifestPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$reviewPath = Join-Path $ProjectRoot 'docs\directx-provenance-review.md'
$readinessPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$migrationRecordPath = Join-Path $ProjectRoot 'docs\migrations\directx.md'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$errors = [System.Collections.Generic.List[string]]::new()
foreach ($requiredPath in @(
    $sourcePath
    $modulePath
    $manifestPath
    $reviewPath
    $readinessPath
)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        $errors.Add("Required DirectX provenance review file is missing: $requiredPath")
    }
}
if ($errors.Count -gt 0) {
    throw "DirectX provenance review validation failed:`r`n- $($errors -join "`r`n- ")"
}

$expectedSourceHash = '17051A2F0F7A0CF16BE525121720406E8F1630C94E5977A7CD4C18652A87EE05'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
if ($actualSourceHash -ne $expectedSourceHash) {
    $errors.Add("DirectX Ultimate source checksum changed: $actualSourceHash")
}

$sourceText = Get-Content -LiteralPath $sourcePath -Raw
foreach ($sourceBehavior in @(
    'refs/heads/main/7zip.exe'
    'Start-Process -Wait "$env:SystemRoot\Temp\7zip.exe" -ArgumentList "/S"'
    'HKEY_CURRENT_USER\Software\7-Zip\Options'
    'refs/heads/main/directx.exe'
    'Program Files\7-Zip\7z.exe'
    'DXSETUP.exe'
)) {
    if (-not $sourceText.Contains($sourceBehavior)) {
        $errors.Add("DirectX source no longer contains reviewed behavior: $sourceBehavior")
    }
}

$moduleText = Get-Content -LiteralPath $modulePath -Raw
if (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) {
    $errors.Add('DirectX module is no longer a placeholder.')
}
if ($moduleText.Contains('$script:BoostLabImplementedActions')) {
    $errors.Add('DirectX module unexpectedly declares implemented actions.')
}
foreach ($forbiddenCommand in @(
    'Invoke-WebRequest'
    'Start-Process'
    'Invoke-BoostLabInstallerExecution'
    'New-BoostLabArtifactDownloadRequest'
)) {
    if ($moduleText.Contains($forbiddenCommand)) {
        $errors.Add("DirectX placeholder contains executable behavior: $forbiddenCommand")
    }
}

$manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
$artifacts = @($manifest.Artifacts)
if ($artifacts.Count -ne 0) {
    $errors.Add("Expected no approved production artifacts, found $($artifacts.Count).")
}
foreach ($artifact in $artifacts) {
    if (
        [string]$artifact.Id -match 'directx|7zip' -or
        @($artifact.SourceToolIds) -contains 'directx'
    ) {
        $errors.Add("DirectX artifact was added without complete approval: $($artifact.Id)")
    }
}

$reviewText = Get-Content -LiteralPath $reviewPath -Raw
foreach ($requiredPhrase in @(
    '# DirectX Artifact Provenance Review'
    'DirectX remains a refused placeholder.'
    'refs/heads/main'
    'Exact SHA-256 for `7zip.exe`.'
    'Exact SHA-256 for `directx.exe`.'
    'Exact extraction inventory and expected SHA-256 for `DXSETUP.exe`.'
    'The Phase 35 installer helper is also intentionally inert.'
    'No real DirectX or 7-Zip artifact is approved.'
    'Until that package exists, DirectX remains disabled and visual-only.'
    $expectedSourceHash
)) {
    if (-not $reviewText.Contains($requiredPhrase)) {
        $errors.Add("DirectX provenance review is missing phrase: $requiredPhrase")
    }
}

$readinessText = Get-Content -LiteralPath $readinessPath -Raw
foreach ($requiredPhrase in @(
    'Foundation-ready but needs artifact provenance approvals: **8**'
    'Candidate for next implementation attempt: **0**'
    'Refused placeholder after Phase 45 provenance review'
    'docs/directx-provenance-review.md'
)) {
    if (-not $readinessText.Contains($requiredPhrase)) {
        $errors.Add("Deferred readiness review is missing Phase 45 result: $requiredPhrase")
    }
}

if (Test-Path -LiteralPath $migrationRecordPath -PathType Leaf) {
    $errors.Add('DirectX migration record must not exist while the tool remains unimplemented.')
}

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration.Stages | ForEach-Object { $_.Tools })
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
if (
    $tools.Count -ne 55 -or
    $allModules.Count -ne 55 -or
    $implementedModules.Count -ne 37 -or
    $placeholderModules.Count -ne 18
) {
    $errors.Add(
        "Tool inventory changed: tools=$($tools.Count), modules=$($allModules.Count), implemented=$($implementedModules.Count), placeholders=$($placeholderModules.Count)."
    )
}

$activeNames = @(
    $tools | ForEach-Object {
        ([string]$_.Id -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()
        ([string]$_.Title -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()
    }
)
foreach ($deletedTool in @('Loudness EQ', 'NVME Faster Driver')) {
    $normalized = ($deletedTool -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()
    if ($normalized -in $activeNames) {
        $errors.Add("Deleted tool was reintroduced: $deletedTool")
    }
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
if (
    $sourceLines.Count -ne 49 -or
    $sourceManifestHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477'
) {
    $errors.Add('source-ultimate content or paths changed.')
}

if ($errors.Count -gt 0) {
    throw "DirectX provenance review validation failed:`r`n- $($errors -join "`r`n- ")"
}

[pscustomobject]@{
    Success                   = $true
    DirectXImplemented        = $false
    ProductionArtifactCount   = $artifacts.Count
    DirectXArtifactApproved   = $false
    ImplementedModuleCount    = $implementedModules.Count
    PlaceholderModuleCount    = $placeholderModules.Count
    SourceUltimateUnchanged   = $true
    Message                   = 'DirectX remains denied until immutable artifact provenance and installer approvals exist.'
    Timestamp                 = Get-Date
}



