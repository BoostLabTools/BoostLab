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
        throw 'Unable to determine the Driver Install Debloat & Settings Phase 123 validator path.'
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

function Get-BoostLabOperationByTypeAndLabel {
    param(
        [Parameter(Mandatory)]
        [object[]]$Operations,

        [Parameter(Mandatory)]
        [string]$Type,

        [Parameter(Mandatory)]
        [string]$LabelNeedle
    )

    @($Operations | Where-Object {
        [string]$_.Type -eq $Type -and [string]$_.Label -like "*$LabelNeedle*"
    }) | Select-Object -First 1
}

$inventoryAssertion = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
$inventoryBaseline = $inventoryAssertion.Baseline

$modulePath = Join-Path $ProjectRoot 'modules\Graphics\driver-install-debloat-settings.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\5 Graphics\1 Driver Install Debloat & Settings.ps1'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$parityPath = Join-Path $ProjectRoot 'config\ParityStatusBaseline.psd1'
$orderPath = Join-Path $ProjectRoot 'config\UltimateParityExecutionOrder.psd1'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$allowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'

foreach ($path in @($modulePath, $sourcePath, $stagesPath, $parityPath, $orderPath, $artifactPath, $allowlistPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required file is missing: $path"
}

$expectedSourceHash = 'E69EFF538E7CE6108233C525A2BB88BA2D549CE6954AE751BE7BED778271C26F'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Driver Install Debloat & Settings source hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."

$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$currentRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'driver-install-debloat-settings' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $currentRecord) 'Driver Install Debloat & Settings parity record is missing.'
Assert-BoostLabCondition ([string]$currentRecord.ImplementationLevel -eq 'NearParityControlled') 'Driver Install Debloat & Settings must be NearParityControlled after Phase 123.'
Assert-BoostLabCondition ([string]$currentRecord.UltimateParity -eq 'Partial') 'Driver Install Debloat & Settings UltimateParity should remain Partial with BoostLab GUI/test-safe mechanics.'
Assert-BoostLabCondition ([bool]$currentRecord.YazanAcceptedNearParity) 'YazanAcceptedNearParity must be true.'
Assert-BoostLabCondition (-not [bool]$currentRecord.YazanFinalException) 'YazanFinalException must remain false; AMD/INTEL are not omitted.'
Assert-BoostLabCondition ([string]$currentRecord.FinalProgressStatus -eq 'DoneYazanAcceptedNearParity') 'FinalProgressStatus mismatch.'
Assert-BoostLabTextContains -Text ([string]$currentRecord.GapSummary) -Needle 'exact source-equivalent NVIDIA, AMD, and INTEL' -Description 'Parity GapSummary'
Assert-BoostLabCondition ((@($currentRecord.ApprovedSourceBranches) -join '|') -eq 'NVIDIA|AMD|INTEL') 'Approved source branches must be exactly NVIDIA, AMD, INTEL.'

$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ($null -ne $nextTarget) 'Next ordered parity target should exist after Driver Install Debloat & Settings.'
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq [string]$parityBaseline.CurrentOrderedParityTarget) 'Next ordered parity target must match the central parity baseline cursor.'

$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
Assert-BoostLabCondition ([int]$categoryCounts['NearParityControlled'] -eq [int]$parityBaseline.Counts.NearParityControlled) 'NearParityControlled baseline count mismatch.'
Assert-BoostLabCondition ([int]$categoryCounts['ManualHandoffOnly'] -eq [int]$parityBaseline.Counts.ManualHandoffOnly) 'ManualHandoffOnly baseline count mismatch.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.NearParityControlled -eq [int]$categoryCounts['NearParityControlled']) 'NearParityControlled baseline count must match the current parity records.'
Assert-BoostLabCondition ([int]$categoryCounts['ManualHandoffOnly'] -eq [int]$parityBaseline.Counts.ManualHandoffOnly) 'ManualHandoffOnly count should match the current parity baseline.'
Assert-BoostLabCondition (-not [bool]$parityBaseline.DesignSystemReady) 'Design System readiness must remain false.'

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$graphicsStage = @($stages.Stages | Where-Object { [string]$_.Name -eq 'Graphics' }) | Select-Object -First 1
$tool = @($graphicsStage.Tools | Where-Object { [string]$_.Id -eq 'driver-install-debloat-settings' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $tool) 'Driver Install Debloat & Settings catalog entry is missing.'
Assert-BoostLabCondition ([int]$tool.Order -eq 2) 'Driver Install Debloat & Settings must remain Graphics order 2.'
Assert-BoostLabCondition ((@($tool.Actions) -join '|') -eq 'Analyze|Open|Apply|Default|Restore') 'Canonical actions changed.'
Assert-BoostLabCondition ([string]$tool.SelectionMode -eq 'SingleSelect') 'Driver Install Debloat & Settings must expose a single-select branch model.'
Assert-BoostLabCondition ((@($tool.SelectionRequiredActions) -join '|') -eq 'Open|Apply') 'Driver Install Debloat & Settings Open and Apply must require exactly one selected branch.'
Assert-BoostLabCondition ([string]$tool.SelectionLabel -eq 'Select exactly one GPU branch for Open or Apply') 'Driver Install Debloat & Settings selection label must make branch selection obvious.'
Assert-BoostLabCondition ((@($tool.SelectionItems | ForEach-Object { [string]$_.Id }) -join '|') -eq 'NVIDIA|AMD|INTEL') 'Driver Install Debloat & Settings branch selection items must be exactly NVIDIA, AMD, INTEL.'
Assert-BoostLabCondition ((@($tool.SelectionItems | ForEach-Object { [string]$_.Title }) -join '|') -eq 'NVIDIA|AMD|INTEL') 'Driver Install Debloat & Settings visible branch labels must be exactly NVIDIA, AMD, INTEL.'
$driverInstallLatestTool = @($graphicsStage.Tools | Where-Object { [string]$_.Id -eq 'driver-install-latest' }) | Select-Object -First 1
Assert-BoostLabCondition ([string]$driverInstallLatestTool.SelectionMode -eq 'SingleSelect') 'Driver Install Latest single-select model must remain unchanged.'
Assert-BoostLabCondition ((@($driverInstallLatestTool.SelectionItems | ForEach-Object { [string]$_.Id }) -join '|') -eq 'NVIDIA|AMD|INTEL') 'Driver Install Latest branch items must remain unchanged.'
$installersStage = @($stages.Stages | Where-Object { [string]$_.Name -eq 'Installers' }) | Select-Object -First 1
$installersTool = @($installersStage.Tools | Where-Object { [string]$_.Id -eq 'installers' }) | Select-Object -First 1
Assert-BoostLabCondition ([string]$installersTool.SelectionMode -eq 'SingleSelect') 'Installers must use single-app selection behavior.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.RequiresAdmin) 'Apply requires Administrator.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.RequiresInternet) 'Apply requires internet.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.CanDownload) 'CanDownload must be true.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.CanInstallSoftware) 'CanInstallSoftware must be true.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.CanModifyDrivers) 'CanModifyDrivers must be true.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.CanModifyRegistry) 'CanModifyRegistry must be true.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.CanModifyServices) 'CanModifyServices must be true.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.CanDeleteFiles) 'CanDeleteFiles must be true.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.CanReboot) 'CanReboot must be true.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.SupportsDefault) 'SupportsDefault must remain false.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.SupportsRestore) 'SupportsRestore must remain false.'

$module = Import-Module -Name $modulePath -Force -PassThru -ErrorAction Stop
try {
    $analysis = Invoke-BoostLabToolAction -ActionName 'Analyze'
    Assert-BoostLabCondition ([bool]$analysis.Success) 'Analyze should succeed.'
    Assert-BoostLabCondition ([string]$analysis.Status -eq 'Analyzed') 'Analyze status mismatch.'
    Assert-BoostLabCondition ([string]$analysis.CommandStatus -eq 'No execution performed') 'Analyze must be read-only.'
    Assert-BoostLabCondition ([string]$analysis.Data.Mode -eq 'SourceEquivalentThreeBranchRuntime') 'Analyze mode mismatch.'
    Assert-BoostLabCondition ([string]$analysis.Data.AutoMode -eq 'BranchSelectedSourceEquivalentApply') 'Analyze AutoMode mismatch.'
    Assert-BoostLabCondition ((@($analysis.Data.ApprovedSourceBranches) -join '|') -eq 'NVIDIA|AMD|INTEL') 'Analyze must report all approved branches.'
    Assert-BoostLabCondition ([bool]$analysis.Data.NoMutationOccurred) 'Analyze must report no mutation.'
    Assert-BoostLabCondition ([bool]$analysis.Data.NoDownloadOccurred) 'Analyze must report no download.'
    Assert-BoostLabCondition ([bool]$analysis.Data.NoInstallerExecutionOccurred) 'Analyze must report no installer execution.'
    Assert-BoostLabCondition ([bool]$analysis.Data.NoRegistryMutationOccurred) 'Analyze must report no registry mutation.'
    Assert-BoostLabCondition ([bool]$analysis.Data.NoRebootOrSessionChangeOccurred) 'Analyze must report no reboot/session change.'

    $info = Get-BoostLabToolInfo
    Assert-BoostLabCondition ([string]$info.SelectionMode -eq 'SingleSelect') 'Module info must expose SingleSelect branch mode.'
    Assert-BoostLabCondition ((@($info.SelectionRequiredActions) -join '|') -eq 'Open|Apply') 'Module info selection-required actions mismatch.'
    Assert-BoostLabCondition ((@($info.SelectionItems | ForEach-Object { [string]$_.Id }) -join '|') -eq 'NVIDIA|AMD|INTEL') 'Module info branch selection items mismatch.'

    foreach ($branch in @('NVIDIA', 'AMD', 'INTEL')) {
        $plan = Get-BoostLabDriverInstallDebloatSettingsOperationPlan -Branch $branch
        Assert-BoostLabCondition ([string]$plan.Branch -eq $branch) "Plan branch mismatch for $branch."
        Assert-BoostLabCondition ([bool]$plan.RequiresAdmin) "$branch plan must require admin."
        Assert-BoostLabCondition ([bool]$plan.RequiresInternet) "$branch plan must require internet."
        Assert-BoostLabCondition ([bool]$plan.RestartRequired) "$branch plan must include restart."
        Assert-BoostLabCondition ([bool]$plan.ExecutesOneBranchOnly) "$branch plan must execute one branch only."
        Assert-BoostLabCondition ([int]$plan.OperationCount -gt 40) "$branch plan should contain source operation descriptors."
        foreach ($requiredType in @('RequireAdministrator', 'RequireInternet', 'DownloadFile', 'SelectInstaller', 'ExternalCommand', 'StartProcess', 'ShutdownRestart')) {
            Assert-BoostLabCondition (@($plan.Operations | Where-Object { [string]$_.Type -eq $requiredType }).Count -gt 0) "$branch plan missing operation type $requiredType."
        }
        foreach ($requiredShared in @('Open Windows display settings', 'Open Windows Sound Control Panel', 'Disable automatically manage color for apps', 'Enable MSI mode for all display devices', 'Show all hidden taskbar icons', 'Restart the PC immediately')) {
            Assert-BoostLabCondition (@($plan.Operations | Where-Object { [string]$_.Label -eq $requiredShared }).Count -gt 0) "$branch plan missing shared operation: $requiredShared"
        }
    }

    $nvidiaPlan = Get-BoostLabDriverInstallDebloatSettingsOperationPlan -Branch 'NVIDIA'
    Assert-BoostLabCondition ($null -ne (Get-BoostLabOperationByTypeAndLabel -Operations $nvidiaPlan.Operations -Type 'RemoveItem' -LabelNeedle 'Display.Nview')) 'NVIDIA plan must remove Display.Nview.'
    Assert-BoostLabCondition ($null -ne (Get-BoostLabOperationByTypeAndLabel -Operations $nvidiaPlan.Operations -Type 'StartProcess' -LabelNeedle 'Install NVIDIA driver silently')) 'NVIDIA plan must run setup.exe.'
    Assert-BoostLabCondition ($null -ne (Get-BoostLabOperationByTypeAndLabel -Operations $nvidiaPlan.Operations -Type 'StartProcess' -LabelNeedle 'NVIDIA Control Panel')) 'NVIDIA plan must install NVIDIA Control Panel through winget.'
    Assert-BoostLabCondition ($null -ne (Get-BoostLabOperationByTypeAndLabel -Operations $nvidiaPlan.Operations -Type 'RemoveAppxPackagePattern' -LabelNeedle 'Microsoft.Winget.Source')) 'NVIDIA plan must remove Microsoft.Winget.Source.'
    Assert-BoostLabCondition ($null -ne (Get-BoostLabOperationByTypeAndLabel -Operations $nvidiaPlan.Operations -Type 'DynamicDisplayClassRegAdd' -LabelNeedle 'DisableDynamicPstate')) 'NVIDIA plan must set DisableDynamicPstate.'
    Assert-BoostLabCondition ($null -ne (Get-BoostLabOperationByTypeAndLabel -Operations $nvidiaPlan.Operations -Type 'DynamicDisplayClassRegAdd' -LabelNeedle 'RMHdcpKeyglobZero')) 'NVIDIA plan must set RMHdcpKeyglobZero.'
    $nipOperation = Get-BoostLabOperationByTypeAndLabel -Operations $nvidiaPlan.Operations -Type 'WriteTextFile' -LabelNeedle '.nip'
    Assert-BoostLabCondition ($null -ne $nipOperation) 'NVIDIA plan must write the .nip profile.'
    Assert-BoostLabCondition ([int]$nipOperation.Parameters.ProfileSettingCount -eq 31) 'NVIDIA .nip profile must preserve 31 settings.'
    Assert-BoostLabCondition ($null -ne (Get-BoostLabOperationByTypeAndLabel -Operations $nvidiaPlan.Operations -Type 'StartProcess' -LabelNeedle 'Import NVIDIA Profile Inspector')) 'NVIDIA plan must import Profile Inspector .nip.'

    $amdPlan = Get-BoostLabDriverInstallDebloatSettingsOperationPlan -Branch 'AMD'
    $amdXml = Get-BoostLabOperationByTypeAndLabel -Operations $amdPlan.Operations -Type 'EditXmlFiles' -LabelNeedle 'AMD XML'
    Assert-BoostLabCondition ($null -ne $amdXml) 'AMD plan must edit XML files.'
    Assert-BoostLabCondition (@($amdXml.Parameters.Paths).Count -eq 10) 'AMD plan must edit 10 XML files.'
    $amdJson = Get-BoostLabOperationByTypeAndLabel -Operations $amdPlan.Operations -Type 'EditJsonFiles' -LabelNeedle 'AMD JSON'
    Assert-BoostLabCondition ($null -ne $amdJson) 'AMD plan must edit JSON files.'
    Assert-BoostLabCondition (@($amdJson.Parameters.Paths).Count -eq 2) 'AMD plan must edit 2 JSON files.'
    Assert-BoostLabCondition ($null -ne (Get-BoostLabOperationByTypeAndLabel -Operations $amdPlan.Operations -Type 'StartProcess' -LabelNeedle 'ATISetup')) 'AMD plan must run ATISetup.exe.'
    Assert-BoostLabCondition ($null -ne (Get-BoostLabOperationByTypeAndLabel -Operations $amdPlan.Operations -Type 'UnregisterScheduledTask' -LabelNeedle 'StartCN')) 'AMD plan must unregister StartCN.'
    foreach ($service in @('AMD Crash Defender Service', 'amdfendr', 'amdfendrmgr', 'amdacpbus', 'AMDSAFD', 'AtiHDAudioService')) {
        Assert-BoostLabCondition (@($amdPlan.Operations | Where-Object { [string]$_.Label -like "*$service*" }).Count -ge 2) "AMD plan must stop/delete $service."
    }
    foreach ($value in @('VSyncControl', 'TFQ', 'Tessellation', 'Tessellation_OPTION', 'abmlevel')) {
        Assert-BoostLabCondition (@($amdPlan.Operations | Where-Object { $_.Parameters.Contains('ValueName') -and [string]$_.Parameters.ValueName -eq $value }).Count -gt 0) "AMD plan missing registry value $value."
    }

    $intelPlan = Get-BoostLabDriverInstallDebloatSettingsOperationPlan -Branch 'INTEL'
    Assert-BoostLabCondition ($null -ne (Get-BoostLabOperationByTypeAndLabel -Operations $intelPlan.Operations -Type 'StartProcess' -LabelNeedle 'Installer.exe')) 'INTEL plan must run Installer.exe.'
    Assert-BoostLabCondition ($null -ne (Get-BoostLabOperationByTypeAndLabel -Operations $intelPlan.Operations -Type 'StartFirstMatchingProcess' -LabelNeedle 'Intel Graphics Software')) 'INTEL plan must install Intel Graphics Software extra package.'
    foreach ($service in @('IntelGFXFWupdateTool', 'cplspcon', 'CtaChildDriver', 'GSCAuxDriver', 'GSCx64')) {
        Assert-BoostLabCondition (@($intelPlan.Operations | Where-Object { [string]$_.Label -like "*$service*" }).Count -ge 2) "INTEL plan must stop/delete $service."
    }
    Assert-BoostLabCondition ($null -ne (Get-BoostLabOperationByTypeAndLabel -Operations $intelPlan.Operations -Type 'StopProcess' -LabelNeedle 'IntelGraphicsSoftware')) 'INTEL plan must stop IntelGraphicsSoftware and PresentMonService.'
    Assert-BoostLabCondition ($null -ne (Get-BoostLabOperationByTypeAndLabel -Operations $intelPlan.Operations -Type 'DynamicDisplayClassCreateSubkey' -LabelNeedle '3DKeys')) 'INTEL plan must create 3DKeys.'
    foreach ($value in @('Global_AsyncFlipMode', 'Global_LowLatency')) {
        Assert-BoostLabCondition (@($intelPlan.Operations | Where-Object { $_.Parameters.Contains('ValueName') -and [string]$_.Parameters.ValueName -eq $value }).Count -gt 0) "INTEL plan missing registry value $value."
    }

    $needsBranch = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true
    Assert-BoostLabCondition (-not [bool]$needsBranch.Success) 'Apply without branch must fail closed.'
    Assert-BoostLabCondition ([string]$needsBranch.Status -eq 'NeedsBranchSelection') 'Apply without branch status mismatch.'
    Assert-BoostLabCondition (-not [bool]$needsBranch.ChangesExecuted) 'Apply without branch must execute nothing.'

    $multiBranch = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true -SelectedAppIds @('NVIDIA', 'AMD') -OperationExecutor { throw 'Multi-select input must not execute.' } -SkipEnvironmentChecks:$true
    Assert-BoostLabCondition (-not [bool]$multiBranch.Success) 'Apply with multiple selected branches must fail closed.'
    Assert-BoostLabCondition ([string]$multiBranch.Status -eq 'NeedsBranchSelection') 'Apply with multiple selected branches status mismatch.'
    Assert-BoostLabCondition (-not [bool]$multiBranch.ChangesExecuted) 'Apply with multiple selected branches must execute nothing.'

    foreach ($branch in @('NVIDIA', 'AMD', 'INTEL')) {
        $script:DriverInstallDebloatSettingsMockedOperations = [System.Collections.Generic.List[object]]::new()
        $mockExecutor = {
            param($Operation, $SelectedBranch, $Context)
            $script:DriverInstallDebloatSettingsMockedOperations.Add($Operation)
            [pscustomobject]@{
                Success = $true
                Order = [int]$Operation.Order
                Branch = [string]$Operation.Branch
                Category = [string]$Operation.Category
                Type = [string]$Operation.Type
                Label = [string]$Operation.Label
                SourceCommand = [string]$Operation.SourceCommand
                Message = 'Mocked; no host mutation.'
                Data = if ([string]$Operation.Type -eq 'SelectInstaller') {
                    [pscustomobject]@{ SelectedInstaller = "C:\BoostLabMock\$SelectedBranch-driver.exe" }
                }
                else {
                    $null
                }
                Timestamp = Get-Date
            }
        }
        $apply = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true -Branch $branch -InstallFile "C:\BoostLabMock\$branch-driver.exe" -SkipEnvironmentChecks:$true -OperationExecutor $mockExecutor
        Assert-BoostLabCondition ([bool]$apply.Success) "$branch mocked Apply should succeed."
        Assert-BoostLabCondition ([string]$apply.Status -eq ("{0}WorkflowCompleted" -f $branch)) "$branch Apply status mismatch."
        Assert-BoostLabCondition ([bool]$apply.ChangesExecuted) "$branch Apply should report changes executed under mock."
        Assert-BoostLabCondition ([bool]$apply.RestartRequired) "$branch Apply should report restart required."
        Assert-BoostLabCondition (@($apply.Data.OperationResults).Count -eq [int]$apply.Data.Plan.OperationCount) "$branch operation results must match plan count."
        Assert-BoostLabCondition (@($script:DriverInstallDebloatSettingsMockedOperations | Where-Object { [string]$_.Branch -ne $branch }).Count -eq 0) "$branch Apply must not run other branch operations."
        Assert-BoostLabCondition (@($script:DriverInstallDebloatSettingsMockedOperations | Where-Object { [string]$_.Type -eq 'ShutdownRestart' }).Count -eq 1) "$branch Apply must represent exactly one restart operation."
    }

    $script:DriverInstallDebloatSettingsSelectedBranchOps = [System.Collections.Generic.List[object]]::new()
    $selectedBranchExecutor = {
        param($Operation, $SelectedBranch, $Context)
        $script:DriverInstallDebloatSettingsSelectedBranchOps.Add($Operation)
        [pscustomobject]@{
            Success = $true
            Order = [int]$Operation.Order
            Branch = [string]$Operation.Branch
            Category = [string]$Operation.Category
            Type = [string]$Operation.Type
            Label = [string]$Operation.Label
            SourceCommand = [string]$Operation.SourceCommand
            Message = 'Mocked selected branch operation.'
            Data = if ([string]$Operation.Type -eq 'SelectInstaller') {
                [pscustomobject]@{ SelectedInstaller = "C:\BoostLabMock\$SelectedBranch-driver.exe" }
            }
            else {
                $null
            }
            Timestamp = Get-Date
        }
    }
    $selectedBranchApply = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true -SelectedAppIds @('INTEL') -InstallFile 'C:\BoostLabMock\INTEL-driver.exe' -SkipEnvironmentChecks:$true -OperationExecutor $selectedBranchExecutor
    Assert-BoostLabCondition ([bool]$selectedBranchApply.Success) 'Apply must accept exactly one selected branch from UI action options.'
    Assert-BoostLabCondition ([string]$selectedBranchApply.Status -eq 'INTELWorkflowCompleted') 'Selected branch Apply did not run the INTEL branch.'
    Assert-BoostLabCondition (@($script:DriverInstallDebloatSettingsSelectedBranchOps | Where-Object { [string]$_.Branch -ne 'INTEL' }).Count -eq 0) 'Selected branch Apply must not run other branch operations.'

    $openWithoutBranch = Invoke-BoostLabToolAction -ActionName 'Open' -Confirmed:$true
    Assert-BoostLabCondition (-not [bool]$openWithoutBranch.Success) 'Open without branch must fail closed.'
    Assert-BoostLabCondition ([string]$openWithoutBranch.Status -eq 'NeedsBranchSelection') 'Open without branch status mismatch.'
    Assert-BoostLabCondition (-not [bool]$openWithoutBranch.ChangesExecuted) 'Open without branch must execute nothing.'

    foreach ($branch in @('NVIDIA', 'AMD', 'INTEL')) {
        $script:DriverInstallDebloatSettingsOpenOps = [System.Collections.Generic.List[object]]::new()
        $openMock = {
            param($Operation, $SelectedBranch, $Context)
            $script:DriverInstallDebloatSettingsOpenOps.Add($Operation)
            [pscustomobject]@{
                Success = $true
                Order = [int]$Operation.Order
                Branch = [string]$Operation.Branch
                Category = [string]$Operation.Category
                Type = [string]$Operation.Type
                Label = [string]$Operation.Label
                SourceCommand = [string]$Operation.SourceCommand
                Message = 'Mocked Open operation.'
                Data = $null
                Timestamp = Get-Date
            }
        }
        $open = Invoke-BoostLabToolAction -ActionName 'Open' -Confirmed:$true -SelectedAppIds @($branch) -OperationExecutor $openMock
        Assert-BoostLabCondition ([bool]$open.Success) "$branch Open with selected branch should succeed under mock."
        Assert-BoostLabCondition ([string]$open.Status -eq 'SourceDriverPageOpened') "$branch Open status mismatch."
        Assert-BoostLabCondition (@($script:DriverInstallDebloatSettingsOpenOps | Where-Object { [string]$_.Category -ne 'DriverPage' }).Count -eq 0) "$branch Open must only execute DriverPage operations."
        Assert-BoostLabCondition (@($script:DriverInstallDebloatSettingsOpenOps | Where-Object { [string]$_.Branch -ne $branch }).Count -eq 0) "$branch Open must only execute selected branch operations."
    }

    $default = Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed:$true
    Assert-BoostLabCondition (-not [bool]$default.Success) 'Default must remain unavailable.'
    Assert-BoostLabCondition ([string]$default.Status -eq 'DefaultUnavailable') 'Default status mismatch.'
    Assert-BoostLabTextContains -Text ([string]$default.Message) -Needle 'Default is not Restore' -Description 'Default message'

    $restore = Invoke-BoostLabToolAction -ActionName 'Restore' -Confirmed:$true
    Assert-BoostLabCondition (-not [bool]$restore.Success) 'Restore must remain unavailable.'
    Assert-BoostLabCondition ([string]$restore.Status -eq 'RestoreUnavailable') 'Restore status mismatch.'
    Assert-BoostLabTextContains -Text ([string]$restore.Message) -Needle 'No restore mutation is planned' -Description 'Restore message'
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
}

$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPath
$allowlistPolicy = Import-PowerShellDataFile -LiteralPath $allowlistPath
if ($artifactPolicy.ContainsKey('Artifacts')) {
    Assert-BoostLabCondition (@($artifactPolicy.Artifacts).Count -eq 0) 'No real artifact approvals should be added in Phase 123.'
}
if ($allowlistPolicy.ContainsKey('ProductionAllowlistProposals')) {
    Assert-BoostLabCondition (@($allowlistPolicy.ProductionAllowlistProposals).Count -eq 0) 'No production allowlist proposals should be added in Phase 123.'
}

$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }).Count -eq 0) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    Test = 'DriverInstallDebloatSettingsThreeBranchExactRuntimeImplementation'
    ActiveTools = $inventoryBaseline.ActiveTools
    RuntimeImplementedTools = $inventoryBaseline.ImplementedTools
    DeferredPlaceholders = $inventoryBaseline.DeferredPlaceholders
    ToolId = 'driver-install-debloat-settings'
    SourceHash = $actualSourceHash
    ApprovedSourceBranches = @('NVIDIA', 'AMD', 'INTEL')
    NextOrderedPendingParityTarget = $nextTarget.ToolId
    ProjectWideAmdIntelScopeExpanded = $false
    HostMutationDuringValidation = $false
    Message = 'Driver Install Debloat & Settings maps NVIDIA, AMD, and INTEL source branches and validates with mocked execution only.'
}


