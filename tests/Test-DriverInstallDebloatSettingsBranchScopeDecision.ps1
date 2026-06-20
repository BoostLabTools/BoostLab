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

$sourcePath = Join-Path $ProjectRoot 'source-ultimate\5 Graphics\1 Driver Install Debloat & Settings.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Graphics\driver-install-debloat-settings.psm1'
$codexPath = Join-Path $ProjectRoot 'CODEX_INSTRUCTIONS.md'
$blueprintPath = Join-Path $ProjectRoot 'BOOSTLAB_BLUEPRINT.md'
$expectedSourceHash = 'E69EFF538E7CE6108233C525A2BB88BA2D549CE6954AE751BE7BED778271C26F'

Assert-BoostLabCondition ((Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash -eq $expectedSourceHash) 'Source hash mismatch.'

$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$record = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'driver-install-debloat-settings' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $record) 'Driver Install Debloat & Settings parity record is missing.'
Assert-BoostLabTextContains -Text ([string]$record.BranchScopeDecision) -Needle 'NVIDIA, AMD, and INTEL branches for Driver Install Debloat & Settings only' -Description 'Parity branch-scope decision'
Assert-BoostLabTextContains -Text ([string]$record.BranchScopeDecision) -Needle 'does not expand project-wide AMD/Intel GPU scope' -Description 'Parity branch-scope decision'
Assert-BoostLabCondition ((@($record.ApprovedSourceBranches) -join '|') -eq 'NVIDIA|AMD|INTEL') 'Approved branches must be exactly NVIDIA, AMD, INTEL.'
Assert-BoostLabCondition ([string]$record.ImplementationLevel -eq 'NearParityControlled') 'Phase 123 should move implementation level to NearParityControlled.'
Assert-BoostLabCondition ([bool]$record.YazanAcceptedNearParity) 'Phase 123 should set YazanAcceptedNearParity.'
Assert-BoostLabCondition (-not [bool]$record.YazanFinalException) 'YazanFinalException must remain false.'

$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq [string]$parityBaseline.CurrentOrderedParityTarget) 'Next ordered parity target must match the central parity baseline cursor.'

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

$module = Import-Module -Name $modulePath -Force -PassThru -ErrorAction Stop
try {
    $analysis = Invoke-BoostLabToolAction -ActionName 'Analyze'
    Assert-BoostLabCondition ([string]$analysis.Data.Mode -eq 'SourceEquivalentThreeBranchRuntime') 'Analyze must report Phase 123 runtime mode.'
    Assert-BoostLabCondition ((@($analysis.Data.ApprovedSourceBranches) -join '|') -eq 'NVIDIA|AMD|INTEL') 'Analyze branch list mismatch.'
    Assert-BoostLabCondition (@($analysis.Data.UnsupportedBranches).Count -eq 0) 'AMD/INTEL must not be unsupported for this tool.'

    $applyNoBranch = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true
    Assert-BoostLabCondition ([string]$applyNoBranch.Status -eq 'NeedsBranchSelection') 'Apply should require explicit branch selection.'
    Assert-BoostLabCondition (-not [bool]$applyNoBranch.ChangesExecuted) 'Apply without branch must execute no changes.'
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
}

[pscustomobject]@{
    Test = 'DriverInstallDebloatSettingsBranchScopeDecision'
    ToolId = 'driver-install-debloat-settings'
    ApprovedSourceBranches = @('NVIDIA', 'AMD', 'INTEL')
    ProjectWideAmdIntelScopeExpanded = $false
    FirstOrderedNonFinalParityTarget = $nextTarget.ToolId
    SourceHash = $expectedSourceHash
    Message = 'Phase 122 branch-scope decision remains tool-specific, and Phase 123 implements all approved branches.'
}

