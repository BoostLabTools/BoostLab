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
        throw 'Unable to determine the ordered Ultimate parity reset validator path.'
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

$inventoryAssertion = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
$inventoryBaseline = $inventoryAssertion.Baseline
$inventorySnapshot = $inventoryAssertion.Snapshot

$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$stages = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\Stages.psd1')
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })
$parityTools = @($parityBaseline.Tools)

Assert-BoostLabCondition ([int]$parityBaseline.Counts.ActiveTools -eq [int]$inventoryBaseline.ActiveTools) 'Parity baseline active count must match central inventory baseline.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.RuntimeImplementedTools -eq [int]$inventoryBaseline.ImplementedTools) 'Runtime implemented count must match central inventory baseline.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.DeferredPlaceholders -eq [int]$inventoryBaseline.DeferredPlaceholders) 'Deferred placeholder count must match central inventory baseline.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.SourcePromotedMirrorFiles -eq [int]$inventoryBaseline.SourcePromotedMirrorFiles) 'Source-promoted mirror count must match central inventory baseline.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.RemainingSourcePromotedIntakeCandidates -eq [int]$inventoryBaseline.RemainingSourcePromotedIntakeCandidates) 'Remaining source-promoted intake count must match central inventory baseline.'

Assert-BoostLabCondition ($parityTools.Count -eq $allTools.Count) 'Every active tool must have exactly one parity baseline record.'
$toolIds = @($allTools | ForEach-Object { [string]$_['Id'] })
$baselineToolIds = @($parityTools | ForEach-Object { [string]$_.ToolId })
foreach ($toolId in $toolIds) {
    Assert-BoostLabCondition (@($baselineToolIds | Where-Object { $_ -eq $toolId }).Count -eq 1) "Missing or duplicate parity baseline record for active tool: $toolId"
}
foreach ($toolId in $baselineToolIds) {
    Assert-BoostLabCondition ($toolIds -contains $toolId) "Parity baseline contains non-active tool: $toolId"
}

$allowedLevels = @(
    'ParityImplemented'
    'NearParityControlled'
    'ControlledSubset'
    'ManualHandoffOnly'
    'SecurityAssistantOnly'
    'DeferredForParityWork'
    'RefusedOrDeleted'
)
$allowedParityValues = @('Yes', 'No', 'Partial')
$allowedRuntimeStatuses = @('RuntimeImplemented', 'DeferredPlaceholder', 'RefusedOrDeleted')
foreach ($record in $parityTools) {
    Assert-BoostLabCondition ($allowedLevels -contains [string]$record.ImplementationLevel) "Invalid implementation level for $($record.ToolId)."
    Assert-BoostLabCondition ($allowedParityValues -contains [string]$record.UltimateParity) "Invalid UltimateParity value for $($record.ToolId)."
    Assert-BoostLabCondition ($allowedRuntimeStatuses -contains [string]$record.RuntimeStatus) "Invalid RuntimeStatus value for $($record.ToolId)."
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$record.GapSummary)) "Missing GapSummary for $($record.ToolId)."
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$record.NextParityAction)) "Missing NextParityAction for $($record.ToolId)."
}

$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
$expectedCategoryCounts = @{
    ParityImplemented = $parityBaseline.Counts.UltimateParityImplemented
    NearParityControlled = $parityBaseline.Counts.NearParityControlled
    ControlledSubset = $parityBaseline.Counts.ControlledSubset
    ManualHandoffOnly = $parityBaseline.Counts.ManualHandoffOnly
    SecurityAssistantOnly = $parityBaseline.Counts.SecurityAssistantOnly
    DeferredForParityWork = $parityBaseline.Counts.DeferredForParityWork
}
foreach ($level in $expectedCategoryCounts.Keys) {
    $actual = if ($categoryCounts.ContainsKey($level)) { [int]$categoryCounts[$level] } else { 0 }
    Assert-BoostLabCondition ($actual -eq [int]$expectedCategoryCounts[$level]) "Unexpected parity category count for $level."
}

$ultimateParityRecords = @($parityTools | Where-Object { [string]$_.UltimateParity -eq 'Yes' })
Assert-BoostLabCondition ($ultimateParityRecords.Count -eq [int]$parityBaseline.Counts.UltimateParityImplemented) 'Ultimate parity implemented count must be independent of runtime implementation count.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.RuntimeImplementedTools -ne [int]$parityBaseline.Counts.UltimateParityImplemented) 'Runtime implemented must not equal Ultimate parity implemented by assumption.'

foreach ($temporaryLevel in @('ManualHandoffOnly', 'ControlledSubset', 'SecurityAssistantOnly')) {
    $badRecords = @(
        $parityTools | Where-Object {
            [string]$_.ImplementationLevel -eq $temporaryLevel -and [string]$_.UltimateParity -eq 'Yes'
        }
    )
    Assert-BoostLabCondition ($badRecords.Count -eq 0) "$temporaryLevel must not be counted as full Ultimate parity."
}

$finalExceptions = @($parityTools | Where-Object { [bool]$_.YazanFinalException })
Assert-BoostLabCondition ($finalExceptions.Count -eq 2) 'Exactly two YazanFinalException records should be true after Updates Drivers Block and Installers final scopes.'
Assert-BoostLabCondition ([string]$finalExceptions[0].ToolId -eq 'updates-drivers-block') 'Updates Drivers Block must be the recorded Yazan final exception.'
Assert-BoostLabCondition (-not [bool]$parityBaseline.DesignSystemReady) 'Design System readiness must remain false until parity status is clear.'

Assert-BoostLabCondition ([bool]$parityBaseline.Policy.UltimateParityIsDefaultFinalTarget) 'Ultimate parity default-final-target policy is missing.'
Assert-BoostLabCondition ([bool]$parityBaseline.Policy.RuntimeImplementedIsNotUltimateParity) 'Runtime implementation separation policy is missing.'
Assert-BoostLabCondition ([bool]$parityBaseline.Policy.WorkOrderFollowsStageToolOrder) 'Ordered parity work policy is missing.'
Assert-BoostLabCondition ([string]$executionOrder.Rule -match 'final canonical') 'Ordered parity execution rule must record the Phase 116 canonical Yazan order.'

$expectedStageOrder = @($stages.Stages | ForEach-Object { [string]$_.Name })
$actualStageOrder = @($executionOrder.StageOrder | ForEach-Object { [string]$_ })
Assert-BoostLabCondition (($expectedStageOrder -join '|') -eq ($actualStageOrder -join '|')) 'Execution order stage list must match config/Stages.psd1.'

$flattenedOrder = @()
$catalogById = @{}
foreach ($tool in $allTools) {
    $catalogById[[string]$tool['Id']] = $tool
}
foreach ($stageIndex in 0..($stages.Stages.Count - 1)) {
    $stage = $stages.Stages[$stageIndex]
    $orderStage = $executionOrder.Stages[$stageIndex]
    Assert-BoostLabCondition ([string]$orderStage.Name -eq [string]$stage.Name) "Execution order stage mismatch at index $stageIndex."
    Assert-BoostLabCondition ([int]$orderStage.Order -eq ($stageIndex + 1)) "Execution order stage number mismatch for $($stage.Name)."
    $stageTools = @($stage.Tools)
    $orderTools = @($orderStage.Tools)
    Assert-BoostLabCondition ($stageTools.Count -eq $orderTools.Count) "Execution order tool count mismatch for stage $($stage.Name)."
    $stageToolIds = @($stageTools | ForEach-Object { [string]$_['Id'] } | Sort-Object)
    $orderToolIds = @($orderTools | ForEach-Object { [string]$_.ToolId } | Sort-Object)
    Assert-BoostLabCondition (($stageToolIds -join '|') -eq ($orderToolIds -join '|')) "Execution order tool set mismatch for stage $($stage.Name)."
    if ([string]$stage.Name -eq 'Setup') {
        Assert-BoostLabCondition ([string]$orderTools[0].ToolId -eq 'bitlocker') 'Canonical Yazan order requires BitLocker to be first in Setup parity order.'
    }
    foreach ($toolIndex in 0..($orderTools.Count - 1)) {
        $orderTool = $orderTools[$toolIndex]
        $catalogTool = $catalogById[[string]$orderTool.ToolId]
        Assert-BoostLabCondition ($null -ne $catalogTool) "Execution order references unknown tool: $($orderTool.ToolId)."
        Assert-BoostLabCondition ([int]$orderTool.Order -eq ($toolIndex + 1)) "Execution order tool number mismatch for $($orderTool.ToolId)."
        Assert-BoostLabCondition ([string]$orderTool.DisplayName -eq [string]$catalogTool['Title']) "Execution order display name mismatch for $($orderTool.ToolId)."
        $flattenedOrder += [string]$orderTool.ToolId
    }
}
Assert-BoostLabCondition ($flattenedOrder.Count -eq [int]$inventoryBaseline.ActiveTools) 'Flattened execution order must include every active tool.'

$runtimeImplementedFromBaseline = @($parityTools | Where-Object { [string]$_.RuntimeStatus -eq 'RuntimeImplemented' })
$deferredFromBaseline = @($parityTools | Where-Object { [string]$_.RuntimeStatus -eq 'DeferredPlaceholder' })
Assert-BoostLabCondition ($runtimeImplementedFromBaseline.Count -eq [int]$inventorySnapshot.ImplementedTools) 'Runtime implemented parity records must match live module inventory.'
Assert-BoostLabCondition ($deferredFromBaseline.Count -eq [int]$inventorySnapshot.DeferredPlaceholders) 'Deferred parity records must match live module inventory.'

$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
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
$sha = [Security.Cryptography.SHA256]::Create()
try {
    $sourceManifestHash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n"))))).Replace('-', '')
}
finally {
    $sha.Dispose()
}
Assert-BoostLabCondition (@($sourceLines).Count -eq 49) 'Legacy source file count changed.'
Assert-BoostLabCondition ($sourceManifestHash -eq '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') 'Legacy source manifest changed.'

$sourcePromotedRoot = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate'
$sourcePromotedFiles = @(Get-ChildItem -LiteralPath $sourcePromotedRoot -Recurse -File)
Assert-BoostLabCondition ($sourcePromotedFiles.Count -eq [int]$inventoryBaseline.SourcePromotedMirrorFiles) 'Source-promoted mirror file count changed.'

$artifactPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1')
$productionPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1')
if ($artifactPolicy.ContainsKey('Artifacts')) {
    Assert-BoostLabCondition (@($artifactPolicy.Artifacts).Count -eq 0) 'Artifact provenance approvals must remain empty.'
}
if ($productionPolicy.ContainsKey('ProductionAllowlistProposals')) {
    Assert-BoostLabCondition (@($productionPolicy.ProductionAllowlistProposals).Count -eq 0) 'Production allowlist proposals must remain empty.'
}

foreach ($deletedName in @('Loudness EQ', 'NVME Faster Driver')) {
    $normalizedDeleted = ($deletedName -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()
    $catalogHit = @(
        $allTools | Where-Object {
            (([string]$_['Title'] -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()) -eq $normalizedDeleted
        }
    )
    Assert-BoostLabCondition ($catalogHit.Count -eq 0) "Deleted tool returned to active catalog: $deletedName"
}
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }).Count -eq 0) 'NVME Faster Driver source was reintroduced.'

$firstNonFinal = $null
$firstNonFinal = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ($null -ne $firstNonFinal) 'Ordered parity baseline must identify a next non-final parity target.'
Assert-BoostLabCondition ([string]$firstNonFinal.ToolId -eq 'driver-install-debloat-settings') 'The first ordered pending parity target should advance past Driver Clean near-parity acceptance.'

[pscustomobject]@{
    Test = 'OrderedUltimateParityExecutionReset'
    ActiveTools = $inventorySnapshot.ActiveTools
    RuntimeImplementedTools = $inventorySnapshot.ImplementedTools
    UltimateParityImplemented = $parityBaseline.Counts.UltimateParityImplemented
    NearParityControlled = $parityBaseline.Counts.NearParityControlled
    ControlledSubset = $parityBaseline.Counts.ControlledSubset
    ManualHandoffOnly = $parityBaseline.Counts.ManualHandoffOnly
    SecurityAssistantOnly = $parityBaseline.Counts.SecurityAssistantOnly
    DeferredForParityWork = $parityBaseline.Counts.DeferredForParityWork
    DesignSystemReady = $parityBaseline.DesignSystemReady
    FirstOrderedNonFinalParityTarget = $firstNonFinal.ToolId
    SourceUltimateUnchanged = $true
    DeletedToolsRemainDeleted = $true
    Message = 'Ordered Ultimate parity execution reset baseline is complete and non-runtime.'
}
