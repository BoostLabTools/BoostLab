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
        throw 'Unable to determine validator path.'
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
        [AllowNull()]
        [string]$Text,

        [Parameter(Mandatory)]
        [string]$Needle,

        [Parameter(Mandatory)]
        [string]$Description
    )

    if ([string]::IsNullOrEmpty($Text) -or -not $Text.Contains($Needle)) {
        throw "$Description missing expected text: $Needle"
    }
}

function Get-BoostLabOperationByType {
    param(
        [Parameter(Mandatory)]
        [object]$Plan,

        [Parameter(Mandatory)]
        [string]$Type
    )

    @($Plan.Operations | Where-Object { [string]$_.Type -eq $Type })
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$parityPath = Join-Path $ProjectRoot 'config\ParityStatusBaseline.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Graphics\driver-install-latest.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate\5 Graphics\2 Driver Install Latest.ps1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$allowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'

foreach ($path in @($configPath, $parityPath, $modulePath, $sourcePath, $actionPlanPath, $artifactPath, $allowlistPath, $executionPath, $uiPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required file missing: $path"
}

$expectedSourceHash = '41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Driver Install Latest source hash mismatch: $actualSourceHash"

$sourceText = Get-Content -LiteralPath $sourcePath -Raw
foreach ($sourceNeedle in @(
    '# SCRIPT RUN AS ADMIN',
    'Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet',
    'AjaxDriverService.php?func=DriverManualLookup',
    'international.download.nvidia.com/Windows/$version',
    'IWR $url -OutFile "$env:SystemRoot\Temp\nvidiadriver.exe"',
    'Start-Process "$env:SystemRoot\Temp\nvidiadriver.exe"',
    'https://www.amd.com/en/support/download/drivers.html',
    'drivers\.amd\.com/drivers/installer/.*/whql/amd-software-adrenalin-edition-.*-minimalsetup-.*_web\.exe',
    'IWR $DownloadAmd.href',
    'Start-Process "$env:SystemRoot\Temp\amddriver.exe"',
    'https://www.intel.com/content/www/us/en/search.html#sortCriteria='
)) {
    Assert-BoostLabTextContains -Text $sourceText -Needle $sourceNeedle -Description 'Ultimate source behavior'
}

$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot
$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$config = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })
$graphicsStage = @($config.Stages | Where-Object { $_.Name -eq 'Graphics' })[0]
$tool = @($graphicsStage.Tools | Where-Object { $_.Id -eq 'driver-install-latest' })[0]
Assert-BoostLabCondition ($null -ne $tool) 'Driver Install Latest is missing from Graphics stage.'
Assert-BoostLabCondition ((@($tool.Actions) -join ',') -eq 'Analyze,Open,Apply,Default,Restore') 'Driver Install Latest must expose canonical Analyze/Open/Apply/Default/Restore actions.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.RequiresAdmin) 'Driver Install Latest must require admin.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.RequiresInternet) 'Driver Install Latest must require internet.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.CanDownload) 'Driver Install Latest must declare download capability.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.CanInstallSoftware) 'Driver Install Latest must declare installer capability.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.CanModifyDrivers) 'Driver Install Latest must declare driver capability.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.CanReboot) 'Driver Install Latest must disclose reboot/session-capable installer handoff.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.SupportsDefault) 'Driver Install Latest must not claim Default support.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.SupportsRestore) 'Driver Install Latest must not claim Restore support.'
Assert-BoostLabCondition ([string]$tool.SelectionMode -eq 'SingleSelect') 'Driver Install Latest must expose single branch selection, not checkbox multi-select.'
Assert-BoostLabCondition ((@($tool.SelectionRequiredActions) -join ',') -eq 'Open,Apply') 'Driver Install Latest selection actions mismatch.'
Assert-BoostLabCondition ([string]$tool.SelectionLabel -eq 'Select exactly one GPU branch') 'Driver Install Latest selection label must require exactly one branch.'
Assert-BoostLabCondition ((@($tool.SelectionItems | ForEach-Object { $_.Id }) -join ',') -eq 'NVIDIA,AMD,INTEL') 'Driver Install Latest branch selection items mismatch.'
$installersTool = @($allTools | Where-Object { [string]$_.Id -eq 'installers' })[0]
Assert-BoostLabCondition ($null -ne $installersTool) 'Installers tool is missing from runtime metadata.'
Assert-BoostLabCondition ([string]$installersTool.SelectionMode -eq 'MultiSelect') 'Installers must keep its checkbox multi-select model.'

Assert-BoostLabCondition ([int]$inventoryBaseline.ActiveTools -eq 55) 'Active tool baseline changed unexpectedly.'
Assert-BoostLabCondition ([int]$inventoryBaseline.ImplementedTools -eq [int](Get-BoostLabInventorySnapshot -ProjectRoot $ProjectRoot).ImplementedTools) 'Runtime implemented tool baseline changed unexpectedly.'
Assert-BoostLabCondition ([int]$inventoryBaseline.DeferredPlaceholders -eq [int](Get-BoostLabInventorySnapshot -ProjectRoot $ProjectRoot).DeferredPlaceholders) 'Deferred placeholder baseline changed unexpectedly.'

$driverRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'driver-install-latest' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $driverRecord) 'Driver Install Latest parity record missing.'
Assert-BoostLabCondition ([string]$driverRecord.ImplementationLevel -eq 'NearParityControlled') 'Driver Install Latest implementation level must be NearParityControlled.'
Assert-BoostLabCondition ([string]$driverRecord.UltimateParity -eq 'Partial') 'Driver Install Latest UltimateParity must follow near-parity convention.'
Assert-BoostLabCondition ([string]$driverRecord.FinalProgressStatus -eq 'DoneYazanAcceptedNearParity') 'Driver Install Latest final progress status mismatch.'
Assert-BoostLabCondition ([bool]$driverRecord.YazanAcceptedNearParity) 'Driver Install Latest must be Yazan-accepted near parity.'
Assert-BoostLabCondition (-not [bool]$driverRecord.YazanFinalException) 'Driver Install Latest must not use YazanFinalException.'
Assert-BoostLabTextContains -Text ([string]$driverRecord.GapSummary) -Needle 'exact source-equivalent Driver Install Latest behavior' -Description 'Driver Install Latest gap summary'

$simulatedPrePhaseBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$simulatedRecord = @($simulatedPrePhaseBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'driver-install-latest' }) | Select-Object -First 1
$simulatedRecord['ImplementationLevel'] = 'ManualHandoffOnly'
$simulatedRecord['UltimateParity'] = 'No'
$simulatedRecord['FinalProgressStatus'] = 'NeedsParityUpgrade'
$simulatedRecord['YazanAcceptedNearParity'] = $false
$simulatedRecord['YazanFinalException'] = $false
$simulatedTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $simulatedPrePhaseBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ([string]$simulatedTarget.ToolId -eq 'driver-install-latest') 'Driver Install Latest should be the ordered target before Phase 124 completion.'

$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq [string]$parityBaseline.CurrentOrderedParityTarget) 'Next ordered parity target must match the central parity baseline cursor.'
$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
Assert-BoostLabCondition ([int]$categoryCounts['NearParityControlled'] -eq [int]$parityBaseline.Counts.NearParityControlled) 'NearParityControlled count mismatch.'
Assert-BoostLabCondition ([int]$categoryCounts['ManualHandoffOnly'] -eq [int]$parityBaseline.Counts.ManualHandoffOnly) 'ManualHandoffOnly count should match the current parity baseline.'
Assert-BoostLabCondition (-not [bool]$parityBaseline.DesignSystemReady) 'Design System readiness must remain false.'

$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($moduleNeedle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Open'', ''Apply'', ''Default'', ''Restore'')',
    'SourceEquivalentThreeBranchRuntime',
    'BranchSelectedSourceEquivalentApply',
    'QueryNvidiaLatestDriver',
    'DownloadResolvedNvidiaDriver',
    'QueryAmdDriverInstaller',
    'DownloadResolvedAmdDriver',
    'Intel Windows 11 graphics driver search page',
    'DefaultUnavailable',
    'RestoreUnavailable'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $moduleNeedle -Description 'Driver Install Latest module'
}

foreach ($forbiddenText in @(
    'driver-clean.psm1',
    'driver-install-debloat-settings.psm1',
    'nvidia-settings.psm1',
    'hdcp.psm1',
    'p0-state.psm1',
    'msi-mode.psm1'
)) {
    Assert-BoostLabCondition (-not $moduleText.Contains($forbiddenText)) "Driver Install Latest module must not merge another Graphics tool: $forbiddenText"
}

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
foreach ($planNeedle in @(
    'Run the selected source-equivalent Driver Install Latest NVIDIA, AMD, or INTEL branch after explicit confirmation.',
    'Open the INTEL source-defined Driver Install Latest page only after selecting the INTEL branch; NVIDIA and AMD Open are unavailable and run no operation.',
    'For NVIDIA, query the source NVIDIA latest-driver API',
    'For AMD, scrape the source AMD support page',
    'For INTEL, open the source-defined Intel Windows 11 graphics driver search page.',
    'Default is unavailable because the Driver Install Latest source defines no Default branch.',
    'Restore is unavailable because no selected captured driver/download/installer/session state restore contract exists.'
)) {
    Assert-BoostLabTextContains -Text $actionPlanText -Needle $planNeedle -Description 'Driver Install Latest Action Plan'
}

$uiText = Get-Content -LiteralPath $uiPath -Raw
Assert-BoostLabTextContains -Text $uiText -Needle 'SelectionLabel' -Description 'UI branch selection label support'
Assert-BoostLabTextContains -Text $uiText -Needle '$selectionMode -eq ''SingleSelect''' -Description 'UI single-select branch support'
Assert-BoostLabTextContains -Text $uiText -Needle '[System.Windows.Controls.RadioButton]::new()' -Description 'UI single-select radio button support'
Assert-BoostLabTextContains -Text $uiText -Needle "[System.Windows.Controls.CheckBox]::new()" -Description 'UI multi-select checkbox support for other tools'
Assert-BoostLabTextContains -Text $uiText -Needle '$options[''Branch'']' -Description 'UI single-selected branch action option'
Assert-BoostLabTextContains -Text $uiText -Needle "if (`$toolId -eq 'driver-install-latest')" -Description 'Driver Install Latest dedicated UI action labels'
Assert-BoostLabTextContains -Text $uiText -Needle "'Open' { return 'Open Intel Driver Page' }" -Description 'Driver Install Latest Open UI action label'
Assert-BoostLabTextContains -Text $uiText -Needle "'Apply' { return 'Apply Source Workflow' }" -Description 'Driver Install Latest Apply UI action label'
Assert-BoostLabTextContains -Text $uiText -Needle 'Only the INTEL branch has a source-defined standalone Open page.' -Description 'Driver Install Latest Open tooltip'
Assert-BoostLabCondition (-not $uiText.Contains("@('driver-clean', 'driver-install-latest', 'nvidia-settings')")) 'Driver Install Latest must not share the Manual Handoff UI label mapping after Phase 124.'
Assert-BoostLabCondition (-not $uiText.Contains("'driver-install-latest') -and [string]`$Tool['SelectionMode'] -eq 'MultiSelect'")) 'Driver Install Latest must not use a dedicated MultiSelect UI path.'
Assert-BoostLabTextContains -Text (Get-Content -LiteralPath $executionPath -Raw) -Needle "'driver-install-latest'" -Description 'Execution registration'
Assert-BoostLabTextContains -Text (Get-Content -LiteralPath $executionPath -Raw) -Needle "'Analyze', 'Open', 'Apply', 'Default', 'Restore'" -Description 'Execution action registration'

Import-Module -Name $modulePath -Force -ErrorAction Stop
try {
    $info = Get-BoostLabToolInfo
    Assert-BoostLabCondition ((@($info.ImplementedActions) -join ',') -eq 'Analyze,Open,Apply,Default,Restore') 'Implemented actions mismatch.'

    $analysis = Invoke-BoostLabToolAction -ActionName 'Analyze'
    Assert-BoostLabCondition ([bool]$analysis.Success) 'Analyze should succeed.'
    Assert-BoostLabCondition ([string]$analysis.Status -eq 'Analyzed') 'Analyze status mismatch.'
    Assert-BoostLabCondition ([string]$analysis.CommandStatus -eq 'No execution performed') 'Analyze must be read-only.'
    Assert-BoostLabCondition ([string]$analysis.Data.Mode -eq 'SourceEquivalentThreeBranchRuntime') 'Analyze mode mismatch.'
    Assert-BoostLabCondition ([string]$analysis.Data.AutoMode -eq 'BranchSelectedSourceEquivalentApply') 'Analyze auto mode mismatch.'
    foreach ($flag in @('NoMutationOccurred', 'NoDownloadOccurred', 'NoInstallerExecutionOccurred', 'NoExternalProcessStarted', 'NoDriverMutationOccurred', 'NoRegistryMutationOccurred', 'NoFileCleanupOccurred', 'NoRebootOrSessionChangeOccurred')) {
        Assert-BoostLabCondition ([bool]$analysis.Data.$flag) "Analyze expected no-mutation flag true: $flag"
    }
    Assert-BoostLabCondition ((@($analysis.Data.ApprovedSourceBranches) -join ',') -eq 'NVIDIA,AMD,INTEL') 'Analyze branch list mismatch.'
    Assert-BoostLabCondition (-not [bool]$analysis.Data.ProjectWideAmdIntelScopeExpanded) 'Project-wide AMD/Intel scope must not expand.'

    $plans = @($analysis.Data.OperationPlans)
    Assert-BoostLabCondition ($plans.Count -eq 3) 'Analyze must report all three branch plans.'
    $nvidiaPlan = @($plans | Where-Object { $_.Branch -eq 'NVIDIA' })[0]
    $amdPlan = @($plans | Where-Object { $_.Branch -eq 'AMD' })[0]
    $intelPlan = @($plans | Where-Object { $_.Branch -eq 'INTEL' })[0]

    foreach ($plan in @($nvidiaPlan, $amdPlan, $intelPlan)) {
        Assert-BoostLabCondition (@(Get-BoostLabOperationByType -Plan $plan -Type 'RequireAdministrator').Count -eq 1) "Missing admin operation for $($plan.Branch)."
        Assert-BoostLabCondition (@(Get-BoostLabOperationByType -Plan $plan -Type 'RequireInternet').Count -eq 1) "Missing internet operation for $($plan.Branch)."
    }
    Assert-BoostLabCondition (@(Get-BoostLabOperationByType -Plan $nvidiaPlan -Type 'QueryNvidiaLatestDriver').Count -eq 1) 'NVIDIA lookup operation missing.'
    Assert-BoostLabCondition (@(Get-BoostLabOperationByType -Plan $nvidiaPlan -Type 'DownloadResolvedNvidiaDriver').Count -eq 1) 'NVIDIA download operation missing.'
    Assert-BoostLabCondition (@(Get-BoostLabOperationByType -Plan $nvidiaPlan -Type 'StartProcess').Count -eq 1) 'NVIDIA installer launch operation missing.'
    Assert-BoostLabCondition (@(Get-BoostLabOperationByType -Plan $amdPlan -Type 'QueryAmdDriverInstaller').Count -eq 1) 'AMD lookup operation missing.'
    Assert-BoostLabCondition (@(Get-BoostLabOperationByType -Plan $amdPlan -Type 'DownloadResolvedAmdDriver').Count -eq 1) 'AMD download operation missing.'
    Assert-BoostLabCondition (@(Get-BoostLabOperationByType -Plan $amdPlan -Type 'StartProcess').Count -eq 1) 'AMD installer launch operation missing.'
    Assert-BoostLabCondition (@(Get-BoostLabOperationByType -Plan $intelPlan -Type 'StartProcess').Count -eq 1) 'INTEL driver page launch operation missing.'

    $observedOperations = [System.Collections.Generic.List[object]]::new()
    $mockExecutor = {
        param($Operation, $Branch, $Context)

        $observedOperations.Add($Operation) | Out-Null
        $data = $null
        if ([string]$Operation.Type -eq 'QueryNvidiaLatestDriver') {
            $data = [pscustomobject]@{
                NvidiaDriverVersion = '555.85'
                NvidiaDriverUrl = 'https://international.download.nvidia.com/Windows/555.85/555.85-desktop-win10-win11-64bit-international-dch-whql.exe'
            }
        }
        elseif ([string]$Operation.Type -eq 'QueryAmdDriverInstaller') {
            $data = [pscustomobject]@{
                AmdDriverUrl = 'https://drivers.amd.com/drivers/installer/24/whql/amd-software-adrenalin-edition-24.1.1-minimalsetup-240117_web.exe'
            }
        }

        [pscustomobject]@{
            Success = $true
            Message = 'Mocked operation; no host mutation.'
            Data = $data
        }
    }

    $noBranch = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true
    Assert-BoostLabCondition (-not [bool]$noBranch.Success) 'Apply without branch must fail closed.'
    Assert-BoostLabCondition ([string]$noBranch.Status -eq 'NeedsBranchSelection') 'Apply without branch status mismatch.'
    Assert-BoostLabCondition (-not [bool]$noBranch.ChangesExecuted) 'Apply without branch must execute no changes.'

    $multiBranch = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true -SelectedAppIds @('NVIDIA', 'AMD') -OperationExecutor $mockExecutor -SkipEnvironmentChecks:$true
    Assert-BoostLabCondition (-not [bool]$multiBranch.Success) 'Apply with multiple selected branches must fail closed.'
    Assert-BoostLabCondition ([string]$multiBranch.Status -eq 'NeedsBranchSelection') 'Apply with multiple selected branches status mismatch.'
    Assert-BoostLabCondition (-not [bool]$multiBranch.ChangesExecuted) 'Apply with multiple selected branches must execute no changes.'

    foreach ($branch in @('NVIDIA', 'AMD', 'INTEL')) {
        $observedOperations.Clear()
        $apply = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true -Branch $branch -OperationExecutor $mockExecutor -SkipEnvironmentChecks:$true
        Assert-BoostLabCondition ([bool]$apply.Success) "Mocked $branch Apply should succeed."
        Assert-BoostLabCondition ([string]$apply.Status -eq ("{0}WorkflowCompleted" -f $branch)) "$branch Apply status mismatch."
        Assert-BoostLabCondition ([bool]$apply.ChangesExecuted) "$branch Apply should report branch execution."
        Assert-BoostLabCondition ([string]$apply.CommandStatus -eq 'Completed') "$branch Apply command status mismatch."
        Assert-BoostLabCondition ([string]$apply.VerificationStatus -eq 'Passed') "$branch Apply verification status mismatch."
        Assert-BoostLabCondition (@($apply.Data.OperationResults).Count -eq [int]$apply.Data.Plan.OperationCount) "$branch Apply recorded operation count mismatch."
        Assert-BoostLabCondition (@($observedOperations).Count -eq ([int]$apply.Data.Plan.OperationCount - 2)) "$branch Apply mocked non-environment operation count mismatch."
    }

    $selectedApply = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true -SelectedAppIds @('NVIDIA') -OperationExecutor $mockExecutor -SkipEnvironmentChecks:$true
    Assert-BoostLabCondition ([bool]$selectedApply.Success) 'Apply should accept exactly one selected branch id from the GUI selection surface.'
    Assert-BoostLabCondition ([string]$selectedApply.Status -eq 'NVIDIAWorkflowCompleted') 'Selected branch Apply status mismatch.'

    $openIntel = Invoke-BoostLabToolAction -ActionName 'Open' -Confirmed:$true -Branch 'INTEL' -OperationExecutor $mockExecutor -SkipEnvironmentChecks:$true
    Assert-BoostLabCondition ([bool]$openIntel.Success) 'INTEL Open should follow the source page launch branch.'
    Assert-BoostLabCondition ([string]$openIntel.Status -eq 'IntelDriverPageOpened') 'INTEL Open status mismatch.'
    $openNvidia = Invoke-BoostLabToolAction -ActionName 'Open' -Confirmed:$true -Branch 'NVIDIA' -OperationExecutor $mockExecutor -SkipEnvironmentChecks:$true
    Assert-BoostLabCondition (-not [bool]$openNvidia.Success) 'NVIDIA Open should not invent a standalone browser/page behavior.'
    Assert-BoostLabCondition ([string]$openNvidia.Status -eq 'OpenUnavailableForBranch') 'NVIDIA Open unavailable status mismatch.'
    $openAmd = Invoke-BoostLabToolAction -ActionName 'Open' -Confirmed:$true -Branch 'AMD' -OperationExecutor $mockExecutor -SkipEnvironmentChecks:$true
    Assert-BoostLabCondition (-not [bool]$openAmd.Success) 'AMD Open should not invent a standalone browser/page behavior.'
    Assert-BoostLabCondition ([string]$openAmd.Status -eq 'OpenUnavailableForBranch') 'AMD Open unavailable status mismatch.'

    foreach ($unsupportedAction in @('Default', 'Restore')) {
        $unsupported = Invoke-BoostLabToolAction -ActionName $unsupportedAction
        Assert-BoostLabCondition (-not [bool]$unsupported.Success) "$unsupportedAction must be unavailable."
        Assert-BoostLabCondition ([string]$unsupported.Status -eq ("{0}Unavailable" -f $unsupportedAction)) "$unsupportedAction status mismatch."
        Assert-BoostLabCondition (-not [bool]$unsupported.ChangesExecuted) "$unsupportedAction must execute no changes."
    }
}
finally {
    Remove-Module -Name 'driver-install-latest' -Force -ErrorAction SilentlyContinue
}

$artifactConfig = Import-PowerShellDataFile -LiteralPath $artifactPath
Assert-BoostLabCondition (@($artifactConfig.Artifacts).Count -eq 0) 'No real Driver Install Latest artifact provenance should be approved in Phase 124.'
$allowlistText = Get-Content -LiteralPath $allowlistPath -Raw
Assert-BoostLabCondition (-not ($allowlistText -match '(?i)driver-install-latest|nvidiadriver|amddriver|geforce|adrenalin')) 'No production allowlist scope should be approved for Driver Install Latest.'

foreach ($deletedPath in @(
    'source-ultimate\6 Windows\17 Loudness EQ.ps1',
    'source-ultimate\6 Windows\30 NVME Faster Driver.ps1'
)) {
    Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $deletedPath))) "Deleted source was reintroduced: $deletedPath"
}

[pscustomobject]@{
    Test                           = 'DriverInstallLatestExactUltimateParityImplementation'
    ActiveTools                    = $inventoryBaseline.ActiveTools
    RuntimeImplementedTools        = $inventoryBaseline.ImplementedTools
    DeferredPlaceholders           = $inventoryBaseline.DeferredPlaceholders
    SourceHash                     = $actualSourceHash
    ApprovedSourceBranches         = @('NVIDIA', 'AMD', 'INTEL')
    NextOrderedPendingParityTarget = $nextTarget.ToolId
    HostMutationDuringValidation   = $false
    Message                        = 'Driver Install Latest maps NVIDIA, AMD, and INTEL source branches and validates with mocked execution only.'
}


