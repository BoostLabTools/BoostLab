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
        throw 'Unable to determine the inventory baseline churn validator script path.'
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

$baselinePath = Join-Path $ProjectRoot 'config\InventoryBaseline.psd1'
$helperPath = Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$sourcePromotedRoot = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate'

Assert-BoostLabCondition (Test-Path -LiteralPath $baselinePath -PathType Leaf) 'Central inventory baseline file is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $helperPath -PathType Leaf) 'Inventory baseline test helper is missing.'

$baseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot
$assertion = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
$snapshot = $assertion.Snapshot

Assert-BoostLabCondition ([int]$baseline.ActiveTools -eq 55) 'Inventory baseline ActiveTools must remain 55 for Phase 103.'
Assert-BoostLabCondition ([int]$baseline.ImplementedTools -eq 45) 'Inventory baseline ImplementedTools must remain 45 after Phase 118 Edge Settings near-parity implementation.'
Assert-BoostLabCondition ([int]$baseline.DeferredPlaceholders -eq 10) 'Inventory baseline DeferredPlaceholders must remain 10 after Phase 118 Edge Settings near-parity implementation.'
Assert-BoostLabCondition ([int]$baseline.SourcePromotedMirrorFiles -eq 7) 'Inventory baseline SourcePromotedMirrorFiles must remain 7 for Phase 103.'
Assert-BoostLabCondition ([int]$baseline.RemainingSourcePromotedIntakeCandidates -eq 0) 'Inventory baseline RemainingSourcePromotedIntakeCandidates must remain 0 for Phase 103.'
Assert-BoostLabCondition ([int]$snapshot.RemainingSourcePromotedIntakeCandidates -eq [int]$baseline.RemainingSourcePromotedIntakeCandidates) 'Live remaining source-promoted intake count does not match the baseline.'

$helperCommands = @(
    'Get-BoostLabInventoryBaseline'
    'Get-BoostLabInventorySnapshot'
    'Assert-BoostLabInventoryBaseline'
)
foreach ($commandName in $helperCommands) {
    Assert-BoostLabCondition ([bool](Get-Command -Name $commandName -ErrorAction SilentlyContinue)) "Inventory helper command is not importable: $commandName"
}

$testsRoot = Join-Path $ProjectRoot 'tests'
$validatorFiles = @(
    Get-ChildItem -LiteralPath $testsRoot -Filter 'Test-*.ps1' -File |
        Where-Object { $_.Name -ne 'Test-InventoryBaselineChurnReduction.ps1' }
)
$baselineUsingFiles = @(
    $validatorFiles | Where-Object {
        (Get-Content -LiteralPath $_.FullName -Raw).Contains('$inventoryBaseline')
    }
)
foreach ($file in $baselineUsingFiles) {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    Assert-BoostLabCondition (
        $text.Contains('BoostLab.InventoryBaseline.ps1')
    ) "Validator uses inventoryBaseline without importing the central helper: $($file.Name)"
}

$forbiddenHardcodedPatterns = @(
    'Expected 55 active tools',
    'Expected 44 implemented tools',
    'Expected 11 deferred/placeholders',
    'Expected 7 source-promoted mirror files',
    'ActiveToolCount = 55',
    'ImplementedModuleCount = 44',
    'PlaceholderModuleCount = 11',
    'SourcePromotedMirrorFileCount = 7',
    'RemainingSourcePromotedIntake = 0',
    'implementedCount -ne 44',
    'implementedCount -eq 44',
    'placeholderCount -ne 11',
    'placeholderCount -eq 11',
    'activeTools.Count -ne 55',
    'allTools.Count -ne 55',
    'allTools.Count -eq 55',
    'sourcePromotedFiles.Count -ne 7',
    'sourcePromotedFiles.Count -eq 7'
)

$hardcodedHits = foreach ($file in $validatorFiles) {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    foreach ($pattern in $forbiddenHardcodedPatterns) {
        if ($text.Contains($pattern)) {
            [pscustomobject]@{
                File = $file.Name
                Pattern = $pattern
            }
        }
    }
}
Assert-BoostLabCondition (@($hardcodedHits).Count -eq 0) "Global inventory count baselines are still hardcoded in validators: $(@($hardcodedHits | ForEach-Object { "$($_.File): $($_.Pattern)" }) -join '; ')"

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
        Where-Object {
            $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*')
        } |
        Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
        ForEach-Object {
            $relativePath = $_.FullName.Substring($root.Length + 1).Replace('\', '/')
            $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
            "$relativePath|$hash"
        }
)
$sourceManifestHash = if ($sourceLines.Count -gt 0) {
    $joinedSourceLines = $sourceLines -join "`n"
    $bytes = [Text.Encoding]::UTF8.GetBytes($joinedSourceLines)
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '')
    }
    finally {
        $sha.Dispose()
    }
}
else {
    ''
}
Assert-BoostLabCondition (@($sourceLines).Count -eq 49) "source-ultimate file count changed: $(@($sourceLines).Count)"
Assert-BoostLabCondition ($sourceManifestHash -eq '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') 'source-ultimate content or paths changed.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }).Count -eq 0) 'NVME Faster Driver source was reintroduced.'

$artifactPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1')
$productionPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1')
if ($artifactPolicy.ContainsKey('Artifacts')) {
    Assert-BoostLabCondition (@($artifactPolicy.Artifacts).Count -eq 0) 'Artifact provenance approvals changed unexpectedly.'
}
if ($productionPolicy.ContainsKey('ProductionAllowlistProposals')) {
    Assert-BoostLabCondition (@($productionPolicy.ProductionAllowlistProposals).Count -eq 0) 'Production allowlist proposals changed unexpectedly.'
}

[pscustomobject]@{
    Test = 'InventoryBaselineChurnReduction'
    ActiveTools = $snapshot.ActiveTools
    ImplementedTools = $snapshot.ImplementedTools
    DeferredPlaceholders = $snapshot.DeferredPlaceholders
    SourcePromotedMirrorFiles = $snapshot.SourcePromotedMirrorFiles
    RemainingSourcePromotedIntakeCandidates = $snapshot.RemainingSourcePromotedIntakeCandidates
    ValidatorsUsingCentralBaseline = @($baselineUsingFiles).Count
    SourceUltimateUnchanged = $true
    DeletedToolsRemainDeleted = $true
    Message = 'Inventory baseline is centralized and current counts remain unchanged.'
}
