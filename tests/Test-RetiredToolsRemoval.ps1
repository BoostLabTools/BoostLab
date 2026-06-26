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
        throw 'Unable to determine the retired tools removal test path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
. (Join-Path $ProjectRoot 'tests\BoostLab.ParityStatusBaseline.ps1')

$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot
$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$orderPath = Join-Path $ProjectRoot 'config\UltimateParityExecutionOrder.psd1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$retiredTools = @(
    [pscustomobject]@{
        ToolId = 'restore-point'
        DisplayName = 'Restore Point'
        ModulePath = 'modules\Windows\RestorePoint.psm1'
        SourcePath = 'source-ultimate\6 Windows\23 Restore Point.ps1'
    }
    [pscustomobject]@{
        ToolId = 'spectre-meltdown-assistant'
        DisplayName = 'Spectre / Meltdown Assistant'
        ModulePath = 'modules\Advanced\spectre-meltdown-assistant.psm1'
        SourcePath = 'source-ultimate\8 Advanced\1 Spectre  Meltdown Assistant.ps1'
    }
    [pscustomobject]@{
        ToolId = 'mmagent-assistant'
        DisplayName = 'MMAgent Assistant'
        ModulePath = 'modules\Advanced\mmagent-assistant.psm1'
        SourcePath = 'source-ultimate\8 Advanced\2 MMAgent Assistant.ps1'
    }
    [pscustomobject]@{
        ToolId = 'services-optimizer'
        DisplayName = 'Services Optimizer'
        ModulePath = 'modules\Advanced\services-optimizer.psm1'
        SourcePath = 'source-ultimate\8 Advanced\5 Services Optimizer.ps1'
    }
)

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($configuration.Stages | ForEach-Object { $_.Tools })
$executionText = Get-Content -Raw -LiteralPath $executionPath
$actionPlanText = Get-Content -Raw -LiteralPath $actionPlanPath
$uiText = Get-Content -Raw -LiteralPath $uiPath
$orderText = Get-Content -Raw -LiteralPath $orderPath
$activeIds = @($allTools | ForEach-Object { [string]$_.Id })
$activeTitles = @($allTools | ForEach-Object { [string]$_.Title })

if (
    [int]$inventoryBaseline.ActiveTools -ne $allTools.Count -or
    [int]$inventoryBaseline.ImplementedTools -ne $allTools.Count -or
    [int]$inventoryBaseline.DeferredPlaceholders -ne 0
) {
    throw 'Inventory baseline must match the current active implemented tool catalog after permanent retirements.'
}

$refusedOrDeletedCount = @($parityBaseline.RefusedOrDeletedOutsideActiveCatalog).Count
if (
    [int]$parityBaseline.Counts.ActiveTools -ne [int]$inventoryBaseline.ActiveTools -or
    [int]$parityBaseline.Counts.RuntimeImplementedTools -ne [int]$inventoryBaseline.ImplementedTools -or
    [int]$parityBaseline.Counts.RefusedOrDeletedOutsideActiveCatalog -ne $refusedOrDeletedCount -or
    -not [bool]$parityBaseline.OrderedParityComplete -or
    $null -ne $parityBaseline.CurrentOrderedParityTarget
) {
    throw 'Parity baseline counts/order completion were not updated for permanent retirement.'
}

foreach ($retiredTool in $retiredTools) {
    if ($activeIds -contains [string]$retiredTool.ToolId) {
        throw "Retired tool is still active in Stages.psd1: $($retiredTool.ToolId)"
    }
    if ($activeTitles -contains [string]$retiredTool.DisplayName) {
        throw "Retired tool title is still active in Stages.psd1: $($retiredTool.DisplayName)"
    }
    if (Test-Path -LiteralPath (Join-Path $ProjectRoot $retiredTool.ModulePath)) {
        throw "Retired runtime module still exists: $($retiredTool.ModulePath)"
    }
    if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $retiredTool.SourcePath))) {
        throw "Immutable source archive reference is missing unexpectedly: $($retiredTool.SourcePath)"
    }
    if ($executionText.Contains("'$($retiredTool.ToolId)' = @{")) {
        throw "Retired tool is still invokable through Execution.psm1: $($retiredTool.ToolId)"
    }
    if ($actionPlanText.Contains("'$($retiredTool.ToolId)'")) {
        throw "Retired tool still has action-plan routing: $($retiredTool.ToolId)"
    }
    if ($uiText.Contains("'$($retiredTool.ToolId)'")) {
        throw "Retired tool still has UI-specific rendering: $($retiredTool.ToolId)"
    }
    if ($orderText.Contains("ToolId = '$($retiredTool.ToolId)'")) {
        throw "Retired tool is still in the ordered parity execution list: $($retiredTool.ToolId)"
    }

    $parityRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq [string]$retiredTool.ToolId })
    if ($parityRecord.Count -ne 0) {
        throw "Retired tool still has an active parity tool record: $($retiredTool.ToolId)"
    }
    $retiredCatalogRecord = @($parityBaseline.RefusedOrDeletedOutsideActiveCatalog | Where-Object { [string]$_ -eq [string]$retiredTool.DisplayName })
    if ($retiredCatalogRecord.Count -ne 1) {
        throw "Retired tool is not recorded exactly once in RefusedOrDeletedOutsideActiveCatalog: $($retiredTool.DisplayName)"
    }
}

$advancedStage = @($configuration.Stages | Where-Object { [string]$_.Name -eq 'Advanced' }) | Select-Object -First 1
$advancedIds = @($advancedStage.Tools | ForEach-Object { [string]$_.Id })
if (($advancedIds -join ',') -ne 'timer-resolution-assistant,defender-optimize-assistant') {
    throw "Advanced stage active order is incorrect after retirement: $($advancedIds -join ',')"
}

[pscustomobject]@{
    Success = $true
    RetiredToolCount = $retiredTools.Count
    ActiveToolCount = $inventoryBaseline.ActiveTools
    ImplementedToolCount = $inventoryBaseline.ImplementedTools
    DeferredPlaceholderCount = $inventoryBaseline.DeferredPlaceholders
    OrderedParityComplete = $parityBaseline.OrderedParityComplete
    CurrentOrderedParityTarget = $parityBaseline.CurrentOrderedParityTarget
    SourceArchivePreserved = $true
    Message = 'The four Yazan-retired tools are absent from active inventory, runtime modules, action routing, action plans, UI-specific rendering, and ordered parity records.'
    Timestamp = Get-Date
}
