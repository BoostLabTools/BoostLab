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
        throw 'Unable to determine the Resizable BAR Assistant deletion guard path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
. (Join-Path $ProjectRoot 'tests\BoostLab.ParityStatusBaseline.ps1')

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

$toolId = 'resizable-bar-assistant'
$displayName = 'Resizable BAR Assistant'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\8 Advanced\3 Resizable BAR Assistant.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Advanced\resizable-bar-assistant.psm1'
$expectedSourceHash = 'BE2DFA30206B92EE34BE32D8DE1D2360C5C214DEDE8F1A48B0698DD60A2BE3EA'

$inventory = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
$stages = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\Stages.psd1')
$order = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$parity = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionSource = Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot 'core\Execution.psm1')
$actionPlanSource = Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot 'core\ActionPlan.psm1')
$matrixText = Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot 'docs\final-deferred-tools-readiness-matrix.md')
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })
$orderedTools = @($order.Stages | ForEach-Object { $_.Tools })

Assert-BoostLabCondition (Test-Path -LiteralPath $sourcePath -PathType Leaf) 'Archived Resizable BAR Assistant source reference is missing.'
Assert-BoostLabCondition ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -eq $expectedSourceHash) 'Archived Resizable BAR Assistant source checksum changed.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) 'Resizable BAR Assistant module must be deleted from active product modules.'
Assert-BoostLabCondition (@($allTools | Where-Object { [string]$_.Id -eq $toolId -or [string]$_.Title -eq $displayName }).Count -eq 0) 'Resizable BAR Assistant must not appear in config/Stages.psd1.'
Assert-BoostLabCondition (@($orderedTools | Where-Object { [string]$_.ToolId -eq $toolId -or [string]$_.DisplayName -eq $displayName }).Count -eq 0) 'Resizable BAR Assistant must not appear in ordered parity execution.'
Assert-BoostLabCondition (@($parity.Tools | Where-Object { [string]$_.ToolId -eq $toolId -or [string]$_.DisplayName -eq $displayName }).Count -eq 0) 'Resizable BAR Assistant must not have an active parity baseline record.'
Assert-BoostLabCondition (@($parity.RefusedOrDeletedOutsideActiveCatalog | Where-Object { [string]$_ -eq $displayName }).Count -eq 1) 'Resizable BAR Assistant must be recorded in the refused/deleted outside-active catalog.'
Assert-BoostLabCondition (-not $executionSource.Contains($toolId)) 'Resizable BAR Assistant must not be routed by core/Execution.psm1.'
Assert-BoostLabCondition (-not $actionPlanSource.Contains($toolId)) 'Resizable BAR Assistant must not have active Action Plan branches.'
Assert-BoostLabCondition (-not $matrixText.Contains("| $displayName |")) 'Resizable BAR Assistant must not be listed as a final deferred candidate.'
Assert-BoostLabCondition ([int]$inventory.Snapshot.ActiveTools -eq [int]$inventory.Baseline.ActiveTools) 'Active tool inventory must match the central baseline.'
Assert-BoostLabCondition ([int]$inventory.Snapshot.DeferredPlaceholders -eq [int]$inventory.Baseline.DeferredPlaceholders) 'Deferred placeholder inventory must match the central baseline.'

[pscustomobject]@{
    Test = 'ResizableBarAssistantFinalDeletionGuard'
    ToolId = $toolId
    SourceArchived = $true
    ActiveProductRemoved = $true
    RuntimeModuleDeleted = $true
    OrderedParityRemoved = $true
    DeferredCandidateRemoved = $true
    Message = 'Resizable BAR Assistant is permanently removed from BoostLab product scope while source-ultimate remains archived.'
}
