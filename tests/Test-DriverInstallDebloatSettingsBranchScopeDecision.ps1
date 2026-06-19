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
        throw 'Unable to determine the Driver Install Debloat & Settings branch-scope validator path.'
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

$inventoryAssertion = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
$inventoryBaseline = $inventoryAssertion.Baseline

$sourcePath = Join-Path $ProjectRoot 'source-ultimate\5 Graphics\1 Driver Install Debloat & Settings.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Graphics\driver-install-debloat-settings.psm1'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$parityPath = Join-Path $ProjectRoot 'config\ParityStatusBaseline.psd1'
$orderPath = Join-Path $ProjectRoot 'config\UltimateParityExecutionOrder.psd1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$migrationPath = Join-Path $ProjectRoot 'docs\migrations\driver-install-debloat-settings.md'
$designPath = Join-Path $ProjectRoot 'docs\tool-designs\driver-install-debloat-settings-scope-provenance-design.md'
$codexPath = Join-Path $ProjectRoot 'CODEX_INSTRUCTIONS.md'
$blueprintPath = Join-Path $ProjectRoot 'BOOSTLAB_BLUEPRINT.md'

foreach ($path in @($sourcePath, $modulePath, $stagesPath, $parityPath, $orderPath, $actionPlanPath, $migrationPath, $designPath, $codexPath, $blueprintPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required branch-scope decision file is missing: $path"
}

$expectedSourceHash = 'E69EFF538E7CE6108233C525A2BB88BA2D549CE6954AE751BE7BED778271C26F'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Driver Install Debloat & Settings source hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."

$sourceText = Get-Content -LiteralPath $sourcePath -Raw
foreach ($needle in @(
    'Write-Host " 1.  NVIDIA"',
    'Write-Host " 2.  AMD"',
    'Write-Host " 3.  INTEL`n"',
    'Start-Process "https://www.nvidia.com/en-us/drivers"',
    'Start-Process "https://www.amd.com/en/support/download/drivers.html"',
    'Start-Process "https://www.intel.com/content/www/us/en/search.html'
)) {
    Assert-BoostLabTextContains -Text $sourceText -Needle $needle -Description 'Ultimate source branch inventory'
}

$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$record = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'driver-install-debloat-settings' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $record) 'Driver Install Debloat & Settings parity record is missing.'
Assert-BoostLabCondition ([string]$record.ImplementationLevel -eq 'ManualHandoffOnly') 'Driver Install Debloat & Settings must remain pending ManualHandoffOnly until full implementation completes.'
Assert-BoostLabCondition ([string]$record.UltimateParity -eq 'No') 'Driver Install Debloat & Settings must not be marked as Ultimate parity by the branch-scope decision alone.'
Assert-BoostLabCondition (-not [bool]$record.YazanFinalException) 'Driver Install Debloat & Settings must not use a YazanFinalException to omit AMD/Intel.'
Assert-BoostLabTextContains -Text ([string]$record.BranchScopeDecision) -Needle 'NVIDIA, AMD, and INTEL branches for Driver Install Debloat & Settings only' -Description 'Parity branch-scope decision'
Assert-BoostLabTextContains -Text ([string]$record.BranchScopeDecision) -Needle 'does not expand project-wide AMD/Intel GPU scope' -Description 'Parity branch-scope decision'
Assert-BoostLabCondition ((@($record.ApprovedSourceBranches) -join '|') -eq 'NVIDIA|AMD|INTEL') 'Approved source branch list must be exactly NVIDIA, AMD, INTEL.'
Assert-BoostLabTextContains -Text ([string]$record.NextParityAction) -Needle 'Implement exact source-equivalent NVIDIA, AMD, and INTEL branch behavior' -Description 'Next parity action'

$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq 'driver-install-debloat-settings') 'Branch-scope decision must not move the ordered parity cursor.'

$codexText = Get-Content -LiteralPath $codexPath -Raw
$blueprintText = Get-Content -LiteralPath $blueprintPath -Raw
foreach ($textAndName in @(
    @{ Text = $codexText; Name = 'CODEX_INSTRUCTIONS.md' },
    @{ Text = $blueprintText; Name = 'BOOSTLAB_BLUEPRINT.md' }
)) {
    Assert-BoostLabTextContains -Text $textAndName.Text -Needle 'Tool-specific exception' -Description $textAndName.Name
    Assert-BoostLabTextContains -Text $textAndName.Text -Needle 'Driver Install Debloat & Settings' -Description $textAndName.Name
    Assert-BoostLabTextContains -Text $textAndName.Text -Needle 'does not' -Description $textAndName.Name
}
Assert-BoostLabTextContains -Text $codexText -Needle 'AMD GPU-specific source branches are currently unsupported' -Description 'General AMD scope policy'
Assert-BoostLabTextContains -Text $codexText -Needle 'Intel GPU-specific source branches are currently unsupported' -Description 'General Intel scope policy'
Assert-BoostLabTextContains -Text $blueprintText -Needle 'AMD/Intel GPU-specific branches remain outside the supported scope unless Yazan explicitly changes scope later' -Description 'General AMD/Intel blueprint scope'

$migrationText = Get-Content -LiteralPath $migrationPath -Raw
$designText = Get-Content -LiteralPath $designPath -Raw
foreach ($textAndName in @(
    @{ Text = $migrationText; Name = 'migration record' },
    @{ Text = $designText; Name = 'scope design' }
)) {
    Assert-BoostLabTextContains -Text $textAndName.Text -Needle 'Phase 122' -Description $textAndName.Name
    Assert-BoostLabTextContains -Text $textAndName.Text -Needle 'NVIDIA, AMD, and INTEL' -Description $textAndName.Name
    Assert-BoostLabTextContains -Text $textAndName.Text -Needle 'does not expand project-wide AMD' -Description $textAndName.Name
}

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$graphicsStage = @($stages.Stages | Where-Object { [string]$_.Name -eq 'Graphics' }) | Select-Object -First 1
$tool = @($graphicsStage.Tools | Where-Object { [string]$_.Id -eq 'driver-install-debloat-settings' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $tool) 'Driver Install Debloat & Settings catalog entry is missing.'
Assert-BoostLabTextContains -Text ([string]$tool.Description) -Needle 'NVIDIA/AMD/Intel' -Description 'Catalog description'
Assert-BoostLabCondition ((@($tool.Actions) -join '|') -eq 'Analyze|Open|Apply|Default|Restore') 'Canonical actions changed unexpectedly.'
Assert-BoostLabCondition ([int]$tool.Order -eq 2) 'Graphics order changed unexpectedly.'

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
Assert-BoostLabTextContains -Text $actionPlanText -Needle 'Phase 122 NVIDIA/AMD/INTEL branch-scope decision' -Description 'Action Plan Analyze wording'
Assert-BoostLabTextContains -Text $actionPlanText -Needle 'NVIDIA/AMD/Intel driver artifacts' -Description 'Action Plan Open wording'
Assert-BoostLabCondition (-not $actionPlanText.Contains('unsupported AMD/Intel branches')) 'Action Plan must not describe AMD/Intel as unsupported for this tool.'

$module = Import-Module -Name $modulePath -Force -PassThru -ErrorAction Stop
try {
    $analysis = Invoke-BoostLabToolAction -ActionName 'Analyze'
    Assert-BoostLabCondition ([bool]$analysis.Success) 'Analyze should remain read-only and successful.'
    Assert-BoostLabCondition ([string]$analysis.Data.Mode -eq 'ManualHandoffOnly') 'Branch-scope decision must not enable Auto behavior.'
    Assert-BoostLabCondition ((@($analysis.Data.ApprovedSourceBranches) -join '|') -eq 'NVIDIA|AMD|INTEL') 'Analyze must report all approved source branches.'
    Assert-BoostLabCondition (@($analysis.Data.UnsupportedBranches).Count -eq 0) 'Analyze must not report AMD/Intel as unsupported for this tool.'
    Assert-BoostLabTextContains -Text ([string]$analysis.Data.ToolSpecificBranchScopeDecision) -Needle 'does not expand project-wide AMD/Intel GPU scope' -Description 'Analyze branch-scope decision'

    $apply = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true
    Assert-BoostLabCondition (-not [bool]$apply.Success) 'Apply must remain blocked until full source-equivalent implementation exists.'
    Assert-BoostLabCondition ([string]$apply.Status -eq 'AutoBlockedUntilArtifactApproval') 'Apply blocked status changed unexpectedly.'
    Assert-BoostLabCondition (-not [bool]$apply.ChangesExecuted) 'Branch-scope decision must not execute changes.'
    Assert-BoostLabTextContains -Text ([string]$apply.Message) -Needle 'NVIDIA/AMD/Intel driver' -Description 'Apply blocked message'
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
}

$artifactPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1')
$productionPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1')
if ($artifactPolicy.ContainsKey('Artifacts')) {
    Assert-BoostLabCondition (@($artifactPolicy.Artifacts).Count -eq 0) 'Artifact provenance approvals must remain empty.'
}
if ($productionPolicy.ContainsKey('ProductionAllowlistProposals')) {
    Assert-BoostLabCondition (@($productionPolicy.ProductionAllowlistProposals).Count -eq 0) 'Production allowlist proposals must remain empty.'
}

$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }).Count -eq 0) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    Test = 'DriverInstallDebloatSettingsBranchScopeDecision'
    ActiveTools = $inventoryBaseline.ActiveTools
    RuntimeImplementedTools = $inventoryBaseline.ImplementedTools
    DeferredPlaceholders = $inventoryBaseline.DeferredPlaceholders
    ToolId = 'driver-install-debloat-settings'
    ApprovedSourceBranches = @('NVIDIA', 'AMD', 'INTEL')
    ProjectWideAmdIntelScopeExpanded = $false
    AutoStillBlocked = $true
    FirstOrderedNonFinalParityTarget = $nextTarget.ToolId
    SourceHash = $actualSourceHash
    Message = 'Phase 122 records the Driver Install Debloat & Settings branch-scope decision without enabling runtime execution.'
}
