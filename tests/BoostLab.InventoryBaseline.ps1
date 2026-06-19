Set-StrictMode -Version Latest

function Get-BoostLabInventoryBaseline {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot
    )

    $baselinePath = Join-Path $ProjectRoot 'config\InventoryBaseline.psd1'
    if (-not (Test-Path -LiteralPath $baselinePath -PathType Leaf)) {
        throw "Inventory baseline file is missing: $baselinePath"
    }

    return Import-PowerShellDataFile -LiteralPath $baselinePath
}

function Get-BoostLabInventorySnapshot {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot
    )

    $configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
    $modulesRoot = Join-Path $ProjectRoot 'modules'
    $sourcePromotedRoot = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate'

    $config = Import-PowerShellDataFile -LiteralPath $configPath
    $tools = @($config.Stages | ForEach-Object { $_.Tools })
    $modules = @(Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1')
    $placeholderModules = @(
        $modules | Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1')
        }
    )
    $sourcePromotedFiles = if (Test-Path -LiteralPath $sourcePromotedRoot -PathType Container) {
        @(Get-ChildItem -LiteralPath $sourcePromotedRoot -Recurse -File)
    }
    else {
        @()
    }

    return [pscustomobject]@{
        ActiveTools = $tools.Count
        ModuleFiles = $modules.Count
        ImplementedTools = $tools.Count - $placeholderModules.Count
        DeferredPlaceholders = $placeholderModules.Count
        SourcePromotedMirrorFiles = $sourcePromotedFiles.Count
        RemainingSourcePromotedIntakeCandidates = 0
    }
}

function Assert-BoostLabInventoryBaseline {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot,

        [switch]$IncludeSourcePromoted
    )

    $baseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot
    $snapshot = Get-BoostLabInventorySnapshot -ProjectRoot $ProjectRoot

    if ([int]$snapshot.ActiveTools -ne [int]$baseline.ActiveTools) {
        throw "Expected $($baseline.ActiveTools) active tools, found $($snapshot.ActiveTools)."
    }
    if ([int]$snapshot.ImplementedTools -ne [int]$baseline.ImplementedTools) {
        throw "Expected $($baseline.ImplementedTools) implemented tools, found $($snapshot.ImplementedTools)."
    }
    if ([int]$snapshot.DeferredPlaceholders -ne [int]$baseline.DeferredPlaceholders) {
        throw "Expected $($baseline.DeferredPlaceholders) deferred/placeholders, found $($snapshot.DeferredPlaceholders)."
    }
    if ($IncludeSourcePromoted -and [int]$snapshot.SourcePromotedMirrorFiles -ne [int]$baseline.SourcePromotedMirrorFiles) {
        throw "Expected $($baseline.SourcePromotedMirrorFiles) source-promoted mirror files, found $($snapshot.SourcePromotedMirrorFiles)."
    }

    return [pscustomobject]@{
        Baseline = $baseline
        Snapshot = $snapshot
    }
}
