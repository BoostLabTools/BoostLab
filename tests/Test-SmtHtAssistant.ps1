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
        throw 'Unable to determine the SMT / HT Assistant deletion guard path.'
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

$toolId = 'smt-ht-assistant'
$displayName = 'SMT / HT Assistant'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\8 Advanced\4 SMT  HT Assistant.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Advanced\smt-ht-assistant.psm1'
$migrationPath = Join-Path $ProjectRoot 'docs\migrations\smt-ht-assistant.md'
$expectedSourceHash = '5D53BF2A9A589ECB14D9F8F9048FF4830D2E6F4DEE7E4B54BA6B6B6F77F004FE'

$inventory = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
$stages = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\Stages.psd1')
$order = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$parity = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionSource = Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot 'core\Execution.psm1')
$actionPlanSource = Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot 'core\ActionPlan.psm1')
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })
$orderedTools = @($order.Stages | ForEach-Object { $_.Tools })

Assert-BoostLabCondition (Test-Path -LiteralPath $sourcePath -PathType Leaf) 'Archived SMT / HT Assistant source reference is missing.'
Assert-BoostLabCondition ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -eq $expectedSourceHash) 'Archived SMT / HT Assistant source checksum changed.'
Assert-BoostLabCondition (Test-Path -LiteralPath $migrationPath -PathType Leaf) 'Historical SMT / HT Assistant migration record should remain as archived project history.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) 'SMT / HT Assistant module must be deleted from active product modules.'
Assert-BoostLabCondition (@($allTools | Where-Object { [string]$_.Id -eq $toolId -or [string]$_.Title -eq $displayName }).Count -eq 0) 'SMT / HT Assistant must not appear in config/Stages.psd1.'
Assert-BoostLabCondition (@($orderedTools | Where-Object { [string]$_.ToolId -eq $toolId -or [string]$_.DisplayName -eq $displayName }).Count -eq 0) 'SMT / HT Assistant must not appear in ordered parity execution.'
Assert-BoostLabCondition (@($parity.Tools | Where-Object { [string]$_.ToolId -eq $toolId -or [string]$_.DisplayName -eq $displayName }).Count -eq 0) 'SMT / HT Assistant must not have an active parity baseline record.'
Assert-BoostLabCondition (@($parity.RefusedOrDeletedOutsideActiveCatalog | Where-Object { [string]$_ -eq $displayName }).Count -eq 1) 'SMT / HT Assistant must be recorded in the refused/deleted outside-active catalog.'
Assert-BoostLabCondition (-not $executionSource.Contains($toolId)) 'SMT / HT Assistant must not be routed by core/Execution.psm1.'
Assert-BoostLabCondition (-not $actionPlanSource.Contains($toolId)) 'SMT / HT Assistant must not have active Action Plan branches.'
Assert-BoostLabCondition ([int]$inventory.Snapshot.ActiveTools -eq [int]$inventory.Baseline.ActiveTools) 'Active tool inventory must match the central baseline.'
Assert-BoostLabCondition ([int]$inventory.Snapshot.ImplementedTools -eq [int]$inventory.Baseline.ImplementedTools) 'Implemented tool inventory must match the central baseline.'

[pscustomobject]@{
    Test = 'SmtHtAssistantFinalDeletionGuard'
    ToolId = $toolId
    SourceArchived = $true
    HistoricalMigrationRecordRetained = $true
    ActiveProductRemoved = $true
    RuntimeModuleDeleted = $true
    OrderedParityRemoved = $true
    Message = 'SMT / HT Assistant is permanently removed from BoostLab product scope while source-ultimate and migration history remain archived.'
}
