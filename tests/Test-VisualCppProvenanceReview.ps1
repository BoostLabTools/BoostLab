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

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

function Assert-BoostLabCondition {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-BoostLabTextContains {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$Needle,
        [Parameter(Mandatory)][string]$Description
    )
    if (-not $Text.Contains($Needle)) { throw "$Description is missing: $Needle" }
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

foreach ($requiredPath in @($sourcePath, $modulePath, $manifestPath, $reviewPath, $readinessPath, $migrationRecordPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $requiredPath -PathType Leaf) "Required Visual C++ provenance file is missing: $requiredPath"
}

$expectedSourceHash = '7ACB1F25ECFEEAD83FA389E2D0C1FEEF12232C4E9A740CB5DE64A326FFD38C09'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Visual C++ Ultimate source checksum changed: $actualSourceHash"

$packageFiles = @(
    'vcredist2005_x64.exe',
    'vcredist2005_x86.exe',
    'vcredist2008_x64.exe',
    'vcredist2008_x86.exe',
    'vcredist2010_x64.exe',
    'vcredist2010_x86.exe',
    'vcredist2012_x64.exe',
    'vcredist2012_x86.exe',
    'vcredist2013_x64.exe',
    'vcredist2013_x86.exe',
    'vcredist2015_2017_2019_2022_x64.exe',
    'vcredist2015_2017_2019_2022_x86.exe'
)

$sourceText = Get-Content -LiteralPath $sourcePath -Raw
foreach ($packageFile in $packageFiles) {
    Assert-BoostLabTextContains -Text $sourceText -Needle "refs/heads/main/$packageFile" -Description 'Visual C++ source package URL'
    Assert-BoostLabTextContains -Text $sourceText -Needle "Temp\$packageFile" -Description 'Visual C++ source temp target'
}
foreach ($sourceBehavior in @(
    'vcredist2005_x86.exe" -ArgumentList "/q"',
    'vcredist2008_x86.exe" -ArgumentList "/qb"',
    'vcredist2010_x86.exe" -ArgumentList "/passive /norestart"',
    'vcredist2012_x64.exe" -ArgumentList "/passive /norestart"',
    'vcredist2013_x64.exe" -ArgumentList "/passive /norestart"',
    'vcredist2015_2017_2019_2022_x64.exe" -ArgumentList "/passive /norestart"'
)) {
    Assert-BoostLabTextContains -Text $sourceText -Needle $sourceBehavior -Description 'Visual C++ source installer behavior'
}

$moduleText = Get-Content -LiteralPath $modulePath -Raw
Assert-BoostLabCondition (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) 'Visual C++ module must no longer be a placeholder.'
Assert-BoostLabTextContains -Text $moduleText -Needle '$script:BoostLabImplementedActions = @(''Analyze'', ''Open'', ''Apply'', ''Default'', ''Restore'')' -Description 'Visual C++ implemented actions'
foreach ($requiredPhrase in @(
    'ManualHandoffPrepared',
    'AutoBlockedUntilArtifactApproval',
    'DefaultUnavailable',
    'RestoreUnavailable',
    'No browser, external tool, Visual C++ download, installer launch, package change, registry change, temp-file change, file cleanup, or system mutation occurred.',
    $expectedSourceHash
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $requiredPhrase -Description 'Visual C++ module controlled manual handoff text'
}
foreach ($forbiddenCommand in @('Invoke-WebRequest', 'Start-Process', 'Invoke-BoostLabInstallerExecution', 'New-BoostLabArtifactDownloadRequest')) {
    Assert-BoostLabCondition (-not $moduleText.Contains($forbiddenCommand)) "Visual C++ module contains prohibited execution helper text: $forbiddenCommand"
}

$manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
$artifacts = @($manifest.Artifacts)
Assert-BoostLabCondition ($artifacts.Count -eq 0) "Expected no approved production artifacts, found $($artifacts.Count)."
foreach ($artifact in $artifacts) {
    if ([string]$artifact.Id -match 'visual|vcredist|cpp' -or @($artifact.SourceToolIds) -contains 'visual-cpp') {
        throw "Visual C++ artifact was added without complete approval: $($artifact.Id)"
    }
}

$reviewText = Get-Content -LiteralPath $reviewPath -Raw
foreach ($requiredPhrase in @(
    '# Visual C++ Artifact Provenance Review',
    'Visual C++ is implemented as a controlled manual-handoff tool only.',
    '`Apply` fails closed with',
    '`AutoBlockedUntilArtifactApproval`',
    'No real Visual C++ redistributable is approved.',
    'Until the complete twelve-artifact approval package exists, Visual C++ Auto',
    $expectedSourceHash
)) {
    Assert-BoostLabTextContains -Text $reviewText -Needle $requiredPhrase -Description 'Visual C++ provenance review'
}
foreach ($packageFile in $packageFiles) {
    Assert-BoostLabTextContains -Text $reviewText -Needle $packageFile -Description 'Visual C++ provenance package list'
}

$readinessText = Get-Content -LiteralPath $readinessPath -Raw
foreach ($requiredPhrase in @(
    'Foundation-ready but needs artifact provenance approvals: **3**',
    'Candidate for next implementation attempt: **0**',
    'Implemented in Phase 101 as controlled manual handoff',
    'Phase 101 manual handoff complete; Auto remains blocked',
    'docs/visual-cpp-provenance-review.md'
)) {
    Assert-BoostLabTextContains -Text $readinessText -Needle $requiredPhrase -Description 'Deferred readiness review Phase 101 result'
}

$migrationText = Get-Content -LiteralPath $migrationRecordPath -Raw
foreach ($requiredPhrase in @(
    '# Visual C++ Migration Record',
    $expectedSourceHash,
    'Analyze',
    'Open',
    'Apply',
    'Default',
    'Restore',
    'AutoBlockedUntilArtifactApproval',
    'DefaultUnavailable',
    'RestoreUnavailable',
    'does not download Visual C++ redistributables'
)) {
    Assert-BoostLabTextContains -Text $migrationText -Needle $requiredPhrase -Description 'Visual C++ migration record'
}

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration.Stages | ForEach-Object { $_.Tools })
$allModules = @(Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1' | Where-Object { $_.Directory.Parent.FullName -eq $modulesRoot })
$implementedModules = @($allModules | Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('$script:BoostLabImplementedActions') })
$placeholderModules = @($allModules | Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') })
Assert-BoostLabCondition ($tools.Count -eq $inventoryBaseline.ActiveTools) "Expected $($inventoryBaseline.ActiveTools) active tools, found $($tools.Count)."
Assert-BoostLabCondition ($allModules.Count -eq $inventoryBaseline.ActiveTools) "Expected $($inventoryBaseline.ActiveTools) modules, found $($allModules.Count)."
Assert-BoostLabCondition ($implementedModules.Count -eq $inventoryBaseline.ImplementedTools) "Expected $($inventoryBaseline.ImplementedTools) implemented modules, found $($implementedModules.Count)."
Assert-BoostLabCondition ($placeholderModules.Count -eq $inventoryBaseline.DeferredPlaceholders) "Expected $($inventoryBaseline.DeferredPlaceholders) placeholder modules, found $($placeholderModules.Count)."

$activeNames = @($tools | ForEach-Object {
    ([string]$_.Id -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()
    ([string]$_.Title -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()
})
foreach ($deletedTool in @('Loudness EQ', 'NVME Faster Driver')) {
    $normalized = ($deletedTool -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()
    Assert-BoostLabCondition ($normalized -notin $activeNames) "Deleted tool was reintroduced: $deletedTool"
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = @(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
    Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
    ForEach-Object { '{0}|{1}' -f $_.FullName.Substring($root.Length + 1).Replace('\', '/'), (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash })
$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $sourceManifestHash = [BitConverter]::ToString($sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n")))).Replace('-', '')
}
finally {
    $sha256.Dispose()
}
Assert-BoostLabCondition (@($sourceLines).Count -eq 49) "source-ultimate file count changed: $(@($sourceLines).Count)"
Assert-BoostLabCondition ($sourceManifestHash -eq '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') 'source-ultimate content or paths changed.'

[pscustomobject]@{
    Success                   = $true
    VisualCppImplemented      = $true
    ProductionArtifactCount   = $artifacts.Count
    VisualCppArtifactApproved = $false
    ImplementedModuleCount    = $implementedModules.Count
    PlaceholderModuleCount    = $placeholderModules.Count
    SourceUltimateUnchanged   = $true
    Message                   = 'Visual C++ controlled manual handoff is implemented; Auto remains denied until all twelve immutable artifact and installer approvals exist.'
    Timestamp                 = Get-Date
}
