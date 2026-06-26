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
        throw 'Unable to determine the Start Menu Layout exact parity validator script path.'
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

$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\2 Start Menu Layout.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\StartMenuLayout.psm1'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$existingValidatorPath = Join-Path $ProjectRoot 'tests\Test-StartMenuLayout.ps1'

$expectedSourceHash = 'B769C351189A3DC2BB8E4A595F9E745A9F25E5A69923DF10619B6D9C34D37724'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) 'Start Menu Layout source checksum mismatch.'

$configuration = Import-PowerShellDataFile -LiteralPath $stagesPath
$allTools = @($configuration.Stages | ForEach-Object { $_.Tools })
$tool = $allTools | Where-Object { $_.Id -eq 'start-menu-layout' } | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $tool) 'Start Menu Layout stage metadata was not found.'
Assert-BoostLabCondition ((@($tool.Actions) -join ',') -eq 'Apply,Default') 'Start Menu Layout must expose Apply/Default only.'
Assert-BoostLabCondition ([string]$tool.RiskLevel -eq 'low') 'Start Menu Layout risk metadata changed.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.RequiresAdmin) 'Start Menu Layout must require Administrator.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.CanModifyRegistry) 'Start Menu Layout must declare registry mutation.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.CanDeleteFiles) 'Start Menu Layout must not declare file deletion.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.SupportsDefault) 'Start Menu Layout must support source-defined Default.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.SupportsRestore) 'Start Menu Layout must not support Restore.'

$moduleText = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredText in @(
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')',
    'newstartmenu.reg',
    'oldstartmenu.reg',
    '"EnabledState"=dword:00000002',
    '"EnabledState"=-',
    '"AllAppsViewMode"=dword:00000002',
    '"AllAppsViewMode"=dword:00000000',
    'Start Menu 25H2 layout applied.',
    'Start Menu 24H2 layout restored as default.'
)) {
    Assert-BoostLabCondition ($moduleText.Contains($requiredText)) "Start Menu Layout module is missing source-equivalent behavior: $requiredText"
}
foreach ($forbiddenText in @(
    'ToolModule.Placeholder.ps1',
    'RestoreUnavailable',
    'Start-Process "ms-settings:',
    'Stop-Process',
    'Remove-Item',
    'Invoke-WebRequest',
    'Restart-Computer'
)) {
    Assert-BoostLabCondition (-not $moduleText.Contains($forbiddenText)) "Start Menu Layout module contains unsupported behavior: $forbiddenText"
}

$parity = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$record = @($parity.Tools | Where-Object { [string]$_.ToolId -eq 'start-menu-layout' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $record) 'Start Menu Layout parity record was not found.'
Assert-BoostLabCondition ([string]$record.RuntimeStatus -eq 'RuntimeImplemented') 'Start Menu Layout runtime status mismatch.'
Assert-BoostLabCondition ([string]$record.ImplementationLevel -eq 'ParityImplemented') 'Start Menu Layout must be final accepted parity after Phase 136.'
Assert-BoostLabCondition ([string]$record.UltimateParity -eq 'Yes') 'Start Menu Layout must be marked Ultimate parity after Yazan acceptance.'
Assert-BoostLabCondition (-not [bool]$record.YazanFinalException) 'Start Menu Layout must not use YazanFinalException.'
Assert-BoostLabCondition (Test-BoostLabParityRecordFinal -Record $record) 'Start Menu Layout must be treated as final after Yazan acceptance.'

$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parity -ExecutionOrder $executionOrder
Assert-BoostLabCondition ($null -ne $nextTarget) 'Ordered parity cursor must identify a next target.'
$isOrderedParityComplete = ($parity.ContainsKey('OrderedParityComplete') -and [bool]$parity.OrderedParityComplete)
if ($isOrderedParityComplete) {
    Assert-BoostLabCondition ($null -eq $parity.CurrentOrderedParityTarget) 'Completed ordered parity must not keep a current target.'
    Assert-BoostLabCondition ([bool]$nextTarget.IsOrderedParityComplete) 'Ordered parity helper must report completion.'
}
else {
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$parity.CurrentOrderedParityTarget)) 'Current ordered parity target must remain populated.'
    Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq [string]$parity.CurrentOrderedParityTarget) 'Next ordered parity target must match the central parity baseline cursor.'
}

$inventory = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
Assert-BoostLabCondition ([int]$inventory.Baseline.ActiveTools -eq [int]$inventory.Snapshot.ActiveTools) 'Active inventory count mismatch.'
Assert-BoostLabCondition ([int]$inventory.Baseline.ImplementedTools -eq [int]$inventory.Snapshot.ImplementedTools) 'Implemented inventory count mismatch.'
Assert-BoostLabCondition ([int]$inventory.Baseline.DeferredPlaceholders -eq [int]$inventory.Snapshot.DeferredPlaceholders) 'Deferred inventory count mismatch.'

& $existingValidatorPath -ProjectRoot $ProjectRoot | Out-Null

foreach ($protectedPath in @(
    'source-ultimate\6 Windows\2 Start Menu Layout.ps1',
    'config\ArtifactProvenance.psd1',
    'config\ProductionAllowlistGovernance.psd1'
)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath (Join-Path $ProjectRoot $protectedPath)) "Protected path missing: $protectedPath"
}

Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
$nvmeSource = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'source-ultimate') -Recurse -File |
        Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }
)
Assert-BoostLabCondition ($nvmeSource.Count -eq 0) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    Success = $true
    ToolId = 'start-menu-layout'
    SourceHash = $actualSourceHash
    ImplementedActions = @('Apply', 'Default')
    CurrentOrderedParityTarget = [string]$parity.CurrentOrderedParityTarget
    FinalProgressStatus = 'ParityImplemented'
    MockedRuntimeValidatorPassed = $true
    SourceUltimateUnchanged = $true
    Message = 'Start Menu Layout source-equivalent Apply and Default behavior is verified with mocks and accepted for ordered parity.'
    Timestamp = Get-Date
}
