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
        throw 'Unable to determine the Visual C++ provenance validator path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$sourcePath = Join-Path $ProjectRoot 'source-ultimate\5 Graphics\3 C++.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Graphics\visual-cpp.psm1'
$manifestPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$reviewPath = Join-Path $ProjectRoot 'docs\visual-cpp-provenance-review.md'
$readinessPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$migrationRecordPath = Join-Path $ProjectRoot 'docs\migrations\visual-cpp.md'
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
        $errors.Add("Required Visual C++ provenance review file is missing: $requiredPath")
    }
}
if ($errors.Count -gt 0) {
    throw "Visual C++ provenance review validation failed:`r`n- $($errors -join "`r`n- ")"
}

$expectedSourceHash = '7ACB1F25ECFEEAD83FA389E2D0C1FEEF12232C4E9A740CB5DE64A326FFD38C09'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
if ($actualSourceHash -ne $expectedSourceHash) {
    $errors.Add("Visual C++ Ultimate source checksum changed: $actualSourceHash")
}

$sourceText = Get-Content -LiteralPath $sourcePath -Raw
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
foreach ($packageFile in $packageFiles) {
    if (-not $sourceText.Contains("refs/heads/main/$packageFile")) {
        $errors.Add("Visual C++ source no longer contains reviewed package URL: $packageFile")
    }
    if (-not $sourceText.Contains("Temp\$packageFile")) {
        $errors.Add("Visual C++ source no longer contains reviewed temp target: $packageFile")
    }
}

foreach ($sourceBehavior in @(
    'vcredist2005_x86.exe" -ArgumentList "/q"'
    'vcredist2008_x86.exe" -ArgumentList "/qb"'
    'vcredist2010_x86.exe" -ArgumentList "/passive /norestart"'
    'vcredist2012_x64.exe" -ArgumentList "/passive /norestart"'
    'vcredist2013_x64.exe" -ArgumentList "/passive /norestart"'
    'vcredist2015_2017_2019_2022_x64.exe" -ArgumentList "/passive /norestart"'
)) {
    if (-not $sourceText.Contains($sourceBehavior)) {
        $errors.Add("Visual C++ source no longer contains reviewed installer behavior: $sourceBehavior")
    }
}

$moduleText = Get-Content -LiteralPath $modulePath -Raw
if (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) {
    $errors.Add('Visual C++ module is no longer a placeholder.')
}
if ($moduleText.Contains('$script:BoostLabImplementedActions')) {
    $errors.Add('Visual C++ module unexpectedly declares implemented actions.')
}
foreach ($forbiddenCommand in @(
    'Invoke-WebRequest'
    'Start-Process'
    'Invoke-BoostLabInstallerExecution'
    'New-BoostLabArtifactDownloadRequest'
)) {
    if ($moduleText.Contains($forbiddenCommand)) {
        $errors.Add("Visual C++ placeholder contains executable behavior: $forbiddenCommand")
    }
}

$manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
$artifacts = @($manifest.Artifacts)
if ($artifacts.Count -ne 0) {
    $errors.Add("Expected no approved production artifacts, found $($artifacts.Count).")
}
foreach ($artifact in $artifacts) {
    if (
        [string]$artifact.Id -match 'visual|vcredist|cpp' -or
        @($artifact.SourceToolIds) -contains 'visual-cpp'
    ) {
        $errors.Add("Visual C++ artifact was added without complete approval: $($artifact.Id)")
    }
}

$reviewText = Get-Content -LiteralPath $reviewPath -Raw
foreach ($requiredPhrase in @(
    '# Visual C++ Artifact Provenance Review'
    'Visual C++ remains a refused placeholder.'
    'all twelve executables'
    'refs/heads/main'
    'Exact SHA-256.'
    'Verified Authenticode status and expected Microsoft publisher/signer.'
    'The Phase 35 installer helper is intentionally inert.'
    'No real Visual C++ redistributable is approved.'
    'Until the complete twelve-artifact approval package exists'
    $expectedSourceHash
)) {
    if (-not $reviewText.Contains($requiredPhrase)) {
        $errors.Add("Visual C++ provenance review is missing phrase: $requiredPhrase")
    }
}
foreach ($packageFile in $packageFiles) {
    if (-not $reviewText.Contains($packageFile)) {
        $errors.Add("Visual C++ provenance review is missing package: $packageFile")
    }
}

$readinessText = Get-Content -LiteralPath $readinessPath -Raw
foreach ($requiredPhrase in @(
    'Foundation-ready but needs artifact provenance approvals: **6**'
    'Candidate for next implementation attempt: **0**'
    'Refused placeholder after Phase 46 provenance review'
    'docs/visual-cpp-provenance-review.md'
)) {
    if (-not $readinessText.Contains($requiredPhrase)) {
        $errors.Add("Deferred readiness review is missing Phase 46 result: $requiredPhrase")
    }
}

if (Test-Path -LiteralPath $migrationRecordPath -PathType Leaf) {
    $errors.Add('Visual C++ migration record must not exist while the tool remains unimplemented.')
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
    $implementedModules.Count -ne 39 -or
    $placeholderModules.Count -ne 16
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
    throw "Visual C++ provenance review validation failed:`r`n- $($errors -join "`r`n- ")"
}

[pscustomobject]@{
    Success                    = $true
    VisualCppImplemented       = $false
    ProductionArtifactCount    = $artifacts.Count
    VisualCppArtifactApproved  = $false
    ImplementedModuleCount     = $implementedModules.Count
    PlaceholderModuleCount     = $placeholderModules.Count
    SourceUltimateUnchanged    = $true
    Message                    = 'Visual C++ remains denied until all twelve immutable artifact and installer approvals exist.'
    Timestamp                  = Get-Date
}



