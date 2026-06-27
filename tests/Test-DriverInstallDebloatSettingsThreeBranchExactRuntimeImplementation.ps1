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

function Get-BoostLabCanonicalTextHashFromString {
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Text)
    $normalized = [Collections.Generic.List[byte]]::new($bytes.Length)
    for ($index = 0; $index -lt $bytes.Length; $index++) {
        $byte = $bytes[$index]
        if ($byte -eq 0x0D) {
            $normalized.Add([byte]0x0A)
            if (($index + 1) -lt $bytes.Length -and $bytes[$index + 1] -eq 0x0A) {
                $index++
            }
            continue
        }

        $normalized.Add($byte)
    }

    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha256.ComputeHash($normalized.ToArray()))).Replace('-', '')
    }
    finally {
        $sha256.Dispose()
    }
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
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$runtimePayloadManifestPath = Join-Path $ProjectRoot 'config\RuntimePayloadManifest.psd1'
$runtimePayloadHelperPath = Join-Path $ProjectRoot 'core\RuntimePayloads.psm1'
$didsNipPayloadPath = Join-Path $ProjectRoot 'runtime-payloads\driver-install-debloat-settings\inspector.nip'

foreach ($path in @($modulePath, $sourcePath, $stagesPath, $parityPath, $orderPath, $artifactPath, $allowlistPath, $actionPlanPath, $runtimePayloadManifestPath, $runtimePayloadHelperPath, $didsNipPayloadPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required file is missing: $path"
}

$moduleText = Get-Content -LiteralPath $modulePath -Raw
Assert-BoostLabCondition (-not $moduleText.Contains('ms-settings:display')) 'Driver Install Debloat & Settings module must not open Windows Display Settings at the refresh-rate checkpoint.'
Assert-BoostLabCondition (-not $moduleText.Contains('mmsys.cpl')) 'Driver Install Debloat & Settings module must not open Windows Sound Settings at the refresh-rate checkpoint.'
Assert-BoostLabCondition (-not $moduleText.Contains('Read-Host')) 'Driver Install Debloat & Settings must not introduce raw console prompts.'
Assert-BoostLabTextContains -Text $moduleText -Needle 'ConfirmationCallbackAvailable' -Description 'Driver Install Debloat & Settings confirmation callback diagnostics'
Assert-BoostLabTextContains -Text $moduleText -Needle 'ConfirmationFailureKind' -Description 'Driver Install Debloat & Settings confirmation failure classification'

$expectedSourceHash = '00D7EA2C941DF776F729CD35A9386FE18D59D02717DCB3CF43282714E345A6D3'
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
$nvidiaAppTool = @($graphicsStage.Tools | Where-Object { [string]$_.Id -eq 'nvidia-app-install' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $nvidiaAppTool) 'NVIDIA App installer must remain separate from Driver Install Debloat & Settings.'
Assert-BoostLabCondition ((@($nvidiaAppTool.Actions) -join '|') -eq 'Analyze|Apply') 'NVIDIA App installer must remain a separate installer flow.'
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

Import-Module -Name $actionPlanPath -Force -ErrorAction Stop
Import-Module -Name $runtimePayloadHelperPath -Force -ErrorAction Stop
$applyActionPlan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Apply'
$applyActionPlanText = @(
    [string]$applyActionPlan.Summary
    @($applyActionPlan.PlannedChanges) -join [Environment]::NewLine
    @($applyActionPlan.SideEffects) -join [Environment]::NewLine
    [string]$applyActionPlan.ConfirmationMessage
) -join [Environment]::NewLine
Assert-BoostLabTextContains -Text $applyActionPlanText -Needle 'open NVIDIA Control Panel for refresh-rate adjustment' -Description 'Driver Install Debloat & Settings ActionPlan refresh-rate instruction'
Assert-BoostLabTextContains -Text $applyActionPlanText -Needle 'waits for explicit confirmation' -Description 'Driver Install Debloat & Settings ActionPlan restart gate'
Assert-BoostLabTextContains -Text $applyActionPlanText -Needle 'no automatic restart happens before that confirmation' -Description 'Driver Install Debloat & Settings ActionPlan no immediate restart text'
Assert-BoostLabCondition (-not ($applyActionPlanText -match 'Display Settings|Sound Settings|display/sound')) 'Driver Install Debloat & Settings ActionPlan must not mention opening Display or Sound settings.'

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

    $invokeRefreshRateConfirmationOperation = {
        param($Callback)

        & $module {
            param($CallbackValue)

            $plan = Get-BoostLabDriverInstallDebloatSettingsOperationPlan `
                -Branch 'NVIDIA' `
                -InstallFile 'C:\BoostLabMock\NVIDIA-driver.exe'
            $confirmationOperation = @(
                $plan.Operations |
                    Where-Object { [string]$_.Type -eq 'RefreshRateRestartConfirmation' }
            ) | Select-Object -First 1
            if ($null -eq $confirmationOperation) {
                throw 'NVIDIA refresh-rate confirmation operation was not found.'
            }

            $context = [ordered]@{
                Branch                          = 'NVIDIA'
                InstallFile                     = 'C:\BoostLabMock\NVIDIA-driver.exe'
                RefreshRateConfirmationCallback = $CallbackValue
            }

            Invoke-BoostLabDriverInstallDebloatSettingsRealOperation `
                -Operation $confirmationOperation `
                -Context $context
        } $Callback
    }

    $confirmedRefreshRate = & $invokeRefreshRateConfirmationOperation {
        param($Prompt, $Branch, $Operation)
        return (
            [string]$Prompt -eq 'Have you adjusted the refresh rate and are you ready to restart?' -and
            [string]$Branch -eq 'NVIDIA' -and
            [string]$Operation.Type -eq 'RefreshRateRestartConfirmation'
        )
    }
    Assert-BoostLabCondition ([bool]$confirmedRefreshRate.Success) 'Valid refresh-rate confirmation callback should allow restart continuation.'
    Assert-BoostLabCondition ([bool]$confirmedRefreshRate.Data.ConfirmationCallbackAvailable) 'Valid refresh-rate confirmation callback must be reported available.'
    Assert-BoostLabCondition ([bool]$confirmedRefreshRate.Data.ConfirmationCallbackUsed) 'Valid refresh-rate confirmation callback must be used.'
    Assert-BoostLabCondition ([bool]$confirmedRefreshRate.Data.RestartConfirmedByUser) 'Valid refresh-rate confirmation callback must set RestartConfirmedByUser.'
    Assert-BoostLabCondition (-not [bool]$confirmedRefreshRate.Data.RestartTriggered) 'Refresh-rate confirmation operation itself must not trigger restart.'
    Assert-BoostLabCondition ([string]$confirmedRefreshRate.Data.ConfirmationFailureKind -eq 'Not available') 'Successful refresh-rate confirmation must report no failure classification.'
    Assert-BoostLabCondition ([string]$confirmedRefreshRate.Data.ConfirmationError -eq '') 'Successful refresh-rate confirmation must not report an error.'
    Assert-BoostLabCondition ([bool]$confirmedRefreshRate.Data.ConfirmationDialogClosed) 'Successful refresh-rate confirmation must report the dialog closed before continuation.'
    Assert-BoostLabCondition (-not [bool]$confirmedRefreshRate.Data.PostConfirmationContinuationStarted) 'The confirmation operation itself must not start post-confirmation work.'
    Assert-BoostLabCondition (-not [bool]$confirmedRefreshRate.Data.PostConfirmationRunsInsideCallback) 'Post-confirmation work must not run inside the confirmation callback.'

    $structuredConfirmedRefreshRate = & $invokeRefreshRateConfirmationOperation {
        param($Prompt, $Branch, $Operation)
        return [pscustomobject]@{
            Succeeded                           = $true
            Confirmed                           = $true
            ConfirmationDialogClosed            = $true
            DialogClosed                        = $true
            ConfirmationFailureKind             = 'Not available'
            Error                               = ''
            PostConfirmationContinuationStarted = $false
            PostConfirmationRunsInsideCallback  = $false
        }
    }
    Assert-BoostLabCondition ([bool]$structuredConfirmedRefreshRate.Success) 'Structured refresh-rate confirmation should allow restart continuation.'
    Assert-BoostLabCondition ([bool]$structuredConfirmedRefreshRate.Data.RestartConfirmedByUser) 'Structured refresh-rate confirmation must set RestartConfirmedByUser.'
    Assert-BoostLabCondition ([bool]$structuredConfirmedRefreshRate.Data.ConfirmationDialogClosed) 'Structured refresh-rate confirmation must prove the dialog closed.'

    $declinedRefreshRate = & $invokeRefreshRateConfirmationOperation {
        param($Prompt, $Branch, $Operation)
        return $false
    }
    Assert-BoostLabCondition (-not [bool]$declinedRefreshRate.Success) 'Declined refresh-rate confirmation callback must not allow restart continuation.'
    Assert-BoostLabCondition ([bool]$declinedRefreshRate.Data.ConfirmationCallbackAvailable) 'Declined refresh-rate confirmation callback must still be reported available.'
    Assert-BoostLabCondition ([bool]$declinedRefreshRate.Data.ConfirmationCallbackUsed) 'Declined refresh-rate confirmation callback must still be used.'
    Assert-BoostLabCondition (-not [bool]$declinedRefreshRate.Data.RestartConfirmedByUser) 'Declined refresh-rate confirmation must report RestartConfirmedByUser false.'
    Assert-BoostLabCondition (-not [bool]$declinedRefreshRate.Data.RestartTriggered) 'Declined refresh-rate confirmation must not trigger restart.'
    Assert-BoostLabCondition ([string]$declinedRefreshRate.Data.ConfirmationFailureKind -eq 'Not available') 'Declined refresh-rate confirmation must not be classified as callback infrastructure failure.'

    $dialogNotClosedConfirmation = & $invokeRefreshRateConfirmationOperation {
        param($Prompt, $Branch, $Operation)
        return [pscustomobject]@{
            Succeeded                           = $true
            Confirmed                           = $true
            ConfirmationDialogClosed            = $false
            DialogClosed                        = $false
            ConfirmationFailureKind             = 'Not available'
            Error                               = ''
            PostConfirmationContinuationStarted = $false
            PostConfirmationRunsInsideCallback  = $false
        }
    }
    Assert-BoostLabCondition (-not [bool]$dialogNotClosedConfirmation.Success) 'Refresh-rate confirmation must fail closed if Yes returns before dialog close is observed.'
    Assert-BoostLabCondition (-not [bool]$dialogNotClosedConfirmation.Data.RestartTriggered) 'Dialog-not-closed confirmation must not trigger restart.'
    Assert-BoostLabCondition ([string]$dialogNotClosedConfirmation.Data.ConfirmationFailureKind -eq 'DialogNotClosed') 'Dialog-not-closed confirmation must be classified.'

    $callbackContinuationViolation = & $invokeRefreshRateConfirmationOperation {
        param($Prompt, $Branch, $Operation)
        return [pscustomobject]@{
            Succeeded                           = $true
            Confirmed                           = $true
            ConfirmationDialogClosed            = $true
            DialogClosed                        = $true
            ConfirmationFailureKind             = 'Not available'
            Error                               = ''
            PostConfirmationContinuationStarted = $true
            PostConfirmationRunsInsideCallback  = $true
        }
    }
    Assert-BoostLabCondition (-not [bool]$callbackContinuationViolation.Success) 'Refresh-rate confirmation must fail closed if the callback tries to run post-confirmation work.'
    Assert-BoostLabCondition (-not [bool]$callbackContinuationViolation.Data.RestartTriggered) 'Callback continuation violation must not trigger restart.'
    Assert-BoostLabCondition ([string]$callbackContinuationViolation.Data.ConfirmationFailureKind -eq 'CallbackContinuationViolation') 'Callback continuation violation must be classified.'

    $missingCallbackConfirmation = & $invokeRefreshRateConfirmationOperation $null
    Assert-BoostLabCondition (-not [bool]$missingCallbackConfirmation.Success) 'Missing refresh-rate confirmation callback must not allow restart continuation.'
    Assert-BoostLabCondition (-not [bool]$missingCallbackConfirmation.Data.RestartTriggered) 'Missing refresh-rate confirmation callback must not trigger restart.'
    Assert-BoostLabCondition ([string]$missingCallbackConfirmation.Data.ConfirmationFailureKind -eq 'MissingCallback') 'Missing refresh-rate confirmation callback must be classified.'

    $invalidCallbackConfirmation = & $invokeRefreshRateConfirmationOperation ([pscustomobject]@{ NotACallback = $true })
    Assert-BoostLabCondition (-not [bool]$invalidCallbackConfirmation.Success) 'Invalid refresh-rate confirmation callback must not allow restart continuation.'
    Assert-BoostLabCondition (-not [bool]$invalidCallbackConfirmation.Data.RestartTriggered) 'Invalid refresh-rate confirmation callback must not trigger restart.'
    Assert-BoostLabCondition ([string]$invalidCallbackConfirmation.Data.ConfirmationFailureKind -eq 'InvalidCallback') 'Invalid refresh-rate confirmation callback must be classified.'

    $ampersandCrashText = "The expression after '&' in a pipeline element produced an object that was not valid."
    $crashingCallbackConfirmation = & $invokeRefreshRateConfirmationOperation {
        param($Prompt, $Branch, $Operation)
        throw $ampersandCrashText
    }
    Assert-BoostLabCondition (-not [bool]$crashingCallbackConfirmation.Success) 'Crashing refresh-rate confirmation callback must not allow restart continuation.'
    Assert-BoostLabCondition (-not [bool]$crashingCallbackConfirmation.Data.RestartTriggered) 'Crashing refresh-rate confirmation callback must not trigger restart.'
    Assert-BoostLabCondition ([string]$crashingCallbackConfirmation.Data.ConfirmationFailureKind -eq 'CallbackError') 'Crashing refresh-rate confirmation callback must be classified.'
    Assert-BoostLabTextContains -Text ([string]$crashingCallbackConfirmation.Data.ConfirmationError) -Needle "expression after '&'" -Description 'Refresh-rate confirmation callback crash diagnostic'

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
        foreach ($requiredShared in @('Disable automatically manage color for apps', 'Enable MSI mode for all display devices', 'Show all hidden taskbar icons', 'Restart the PC immediately')) {
            Assert-BoostLabCondition (@($plan.Operations | Where-Object { [string]$_.Label -eq $requiredShared }).Count -gt 0) "$branch plan missing shared operation: $requiredShared"
        }
        Assert-BoostLabCondition (@($plan.Operations | Where-Object { [string]$_.SourceCommand -match 'ms-settings:display|mmsys\.cpl' -or [string]$_.Label -match 'display settings|Sound Control Panel' }).Count -eq 0) "$branch plan must not open Windows Display Settings or Sound Settings."
    }

    $nvidiaPlan = Get-BoostLabDriverInstallDebloatSettingsOperationPlan -Branch 'NVIDIA'
    $nvidiaControlPanelOpen = Get-BoostLabOperationByTypeAndLabel -Operations $nvidiaPlan.Operations -Type 'OpenNvidiaControlPanelForRefreshRate' -LabelNeedle 'refresh-rate'
    $refreshConfirmation = Get-BoostLabOperationByTypeAndLabel -Operations $nvidiaPlan.Operations -Type 'RefreshRateRestartConfirmation' -LabelNeedle 'refresh-rate confirmation'
    $restartOperation = Get-BoostLabOperationByTypeAndLabel -Operations $nvidiaPlan.Operations -Type 'ShutdownRestart' -LabelNeedle 'Restart'
    Assert-BoostLabCondition ($null -ne $nvidiaControlPanelOpen) 'NVIDIA plan must open NVIDIA Control Panel for refresh-rate adjustment.'
    Assert-BoostLabCondition ($null -ne $refreshConfirmation) 'NVIDIA plan must require refresh-rate restart confirmation.'
    Assert-BoostLabCondition ([string]$nvidiaControlPanelOpen.Parameters.FilePath -eq 'shell:appsFolder\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj!NVIDIACorp.NVIDIAControlPanel') 'NVIDIA Control Panel open target mismatch.'
    Assert-BoostLabCondition ([string]$refreshConfirmation.Parameters.Prompt -eq 'Have you adjusted the refresh rate and are you ready to restart?') 'Refresh-rate confirmation prompt mismatch.'
    Assert-BoostLabCondition ([int]$nvidiaControlPanelOpen.Order -lt [int]$refreshConfirmation.Order) 'NVIDIA Control Panel must open before the confirmation prompt.'
    Assert-BoostLabCondition ([int]$refreshConfirmation.Order -lt [int]$restartOperation.Order) 'Refresh-rate confirmation must happen before restart.'
    Assert-BoostLabCondition ($null -ne (Get-BoostLabOperationByTypeAndLabel -Operations $nvidiaPlan.Operations -Type 'RemoveItem' -LabelNeedle 'Display.Nview')) 'NVIDIA plan must remove Display.Nview.'
    Assert-BoostLabCondition ($null -ne (Get-BoostLabOperationByTypeAndLabel -Operations $nvidiaPlan.Operations -Type 'StartProcess' -LabelNeedle 'Install NVIDIA driver silently')) 'NVIDIA plan must run setup.exe.'
    Assert-BoostLabCondition ($null -ne (Get-BoostLabOperationByTypeAndLabel -Operations $nvidiaPlan.Operations -Type 'StartProcess' -LabelNeedle 'NVIDIA Control Panel')) 'NVIDIA plan must install NVIDIA Control Panel through winget.'
    Assert-BoostLabCondition ($null -ne (Get-BoostLabOperationByTypeAndLabel -Operations $nvidiaPlan.Operations -Type 'RemoveAppxPackagePattern' -LabelNeedle 'Microsoft.Winget.Source')) 'NVIDIA plan must remove Microsoft.Winget.Source.'
    Assert-BoostLabCondition ($null -ne (Get-BoostLabOperationByTypeAndLabel -Operations $nvidiaPlan.Operations -Type 'DynamicDisplayClassRegAdd' -LabelNeedle 'DisableDynamicPstate')) 'NVIDIA plan must set DisableDynamicPstate.'
    Assert-BoostLabCondition ($null -ne (Get-BoostLabOperationByTypeAndLabel -Operations $nvidiaPlan.Operations -Type 'DynamicDisplayClassRegAdd' -LabelNeedle 'RMHdcpKeyglobZero')) 'NVIDIA plan must set RMHdcpKeyglobZero.'
    $nipOperation = Get-BoostLabOperationByTypeAndLabel -Operations $nvidiaPlan.Operations -Type 'WriteTextFile' -LabelNeedle '.nip'
    Assert-BoostLabCondition ($null -ne $nipOperation) 'NVIDIA plan must write the .nip profile.'
    Assert-BoostLabCondition ([int]$nipOperation.Parameters.ProfileSettingCount -eq 31) 'NVIDIA .nip profile must preserve 31 settings.'
    Assert-BoostLabCondition ([string]$nipOperation.Parameters.PayloadId -eq 'driver-install-debloat-settings-nvidia-profile') 'NVIDIA .nip operation must use the runtime payload id.'
    Assert-BoostLabCondition ([string]$nipOperation.Parameters.PayloadContentSource -eq 'RuntimePayload') 'NVIDIA .nip operation must prefer the generated runtime payload.'
    Assert-BoostLabCondition ([string]$nipOperation.Parameters.PayloadChecksumStatus -eq 'Passed') 'NVIDIA .nip runtime payload hash must pass before use.'
    Assert-BoostLabCondition ([string]$nipOperation.Parameters.PayloadVerificationMode -in @('ExactRawSha256', 'CanonicalTextSha256')) 'NVIDIA .nip runtime payload verification mode mismatch.'
    Assert-BoostLabCondition (-not [bool]$nipOperation.Parameters.RuntimePayloadFallbackUsed) 'NVIDIA .nip operation must not use protected source fallback while the runtime payload is valid.'
    Assert-BoostLabCondition (-not [bool]$nipOperation.Parameters.RuntimePayloadUsedProtectedSource) 'NVIDIA .nip operation must not read protected source while the runtime payload is valid.'
    Assert-BoostLabCondition ([string]$nipOperation.Parameters.RuntimePayloadPath -like '*runtime-payloads*driver-install-debloat-settings*inspector.nip') 'NVIDIA .nip operation must resolve the generated payload path.'
    $sourceNipContent = & $module {
        Get-BoostLabDriverInstallDebloatSettingsNipContentFromSource
    }
    $operationNipCanonical = Get-BoostLabCanonicalTextHashFromString -Text ([string]$nipOperation.Parameters.Content)
    $sourceNipCanonical = Get-BoostLabCanonicalTextHashFromString -Text ([string]$sourceNipContent)
    Assert-BoostLabCondition ($operationNipCanonical -eq $sourceNipCanonical) 'Runtime payload .nip content must remain equivalent to the source-derived .nip content.'
    [xml]$nipXml = [string]$nipOperation.Parameters.Content
    $profileSettings = @($nipXml.ArrayOfProfile.Profile.Settings.ProfileSetting)
    Assert-BoostLabCondition ($profileSettings.Count -eq 31) 'Generated .nip payload must contain exactly 31 Profile Inspector settings.'
    $settingsByName = @{}
    foreach ($profileSetting in $profileSettings) {
        $settingsByName[[string]$profileSetting.SettingNameInfo] = $profileSetting
    }
    $expectedNipValues = [ordered]@{
        'Frame Rate Limiter V3' = '0'
        'GSYNC - Application Mode' = '0'
        'GSYNC - Application State' = '4'
        'GSYNC - Global Feature' = '0'
        'GSYNC - Global Mode' = '0'
        'GSYNC - Indicator Overlay' = '0'
        'Maximum Pre-Rendered Frames' = '1'
        'Preferred Refresh Rate' = '1'
        'Ultra Low Latency - CPL State' = '2'
        'Ultra Low Latency - Enabled' = '1'
        'Vertical Sync' = '138504007'
        'Vertical Sync - Smooth AFR Behavior' = '0'
        'Vertical Sync - Tear Control' = '2525368439'
        'CUDA - Force P2 State' = '0'
        'CUDA - Sysmem Fallback Policy' = '1'
        'Power Management - Mode' = '1'
        'Shader Cache - Cache Size' = '4294967295'
        'Threaded Optimization' = '1'
        'Preferred OpenGL GPU' = 'id,2.0:268410DE,00000100,GF - (400,2,161,24564) @ (0)'
    }
    foreach ($settingName in $expectedNipValues.Keys) {
        Assert-BoostLabCondition ($settingsByName.ContainsKey($settingName)) "Generated .nip payload is missing setting: $settingName"
        Assert-BoostLabCondition ([string]$settingsByName[$settingName].SettingValue -eq [string]$expectedNipValues[$settingName]) "Generated .nip payload value changed for $settingName."
    }
    Assert-BoostLabCondition ($null -ne (Get-BoostLabOperationByTypeAndLabel -Operations $nvidiaPlan.Operations -Type 'StartProcess' -LabelNeedle 'Import NVIDIA Profile Inspector')) 'NVIDIA plan must import Profile Inspector .nip.'

    $runtimePayloadManifest = Import-PowerShellDataFile -LiteralPath $runtimePayloadManifestPath
    $payloadStatus = @(Test-BoostLabRuntimePayload -ProjectRoot $ProjectRoot -PayloadId 'driver-install-debloat-settings-nvidia-profile' -Manifest $runtimePayloadManifest | Select-Object -First 1)
    Assert-BoostLabCondition ($payloadStatus.Count -eq 1) 'DIDS .nip runtime payload status should resolve exactly once.'
    Assert-BoostLabCondition ([string]$payloadStatus[0].ChecksumStatus -eq 'Passed') 'DIDS .nip runtime payload status must pass hash validation.'
    Assert-BoostLabCondition (-not [bool]$payloadStatus[0].ExternalRuntimeBlocked) 'DIDS .nip runtime payload status must no longer be externally blocked.'

    $tempPayloadRoot = Join-Path ([IO.Path]::GetTempPath()) ('BoostLabDidsNipPayload-' + [guid]::NewGuid().ToString('N'))
    New-Item -Path $tempPayloadRoot -ItemType Directory -Force | Out-Null
    try {
        $validExternalRoot = Join-Path $tempPayloadRoot 'valid-external'
        $validExternalPayload = Join-Path $validExternalRoot 'runtime-payloads\driver-install-debloat-settings\inspector.nip'
        New-Item -Path (Split-Path -Parent $validExternalPayload) -ItemType Directory -Force | Out-Null
        Copy-Item -LiteralPath $didsNipPayloadPath -Destination $validExternalPayload -Force
        $externalValid = & $module {
            param($Root, $Manifest)
            Resolve-BoostLabDriverInstallDebloatSettingsNipPayload -RequestedMode 'ExternalRuntime' -ProjectRoot $Root -PayloadManifest $Manifest
        } $validExternalRoot $runtimePayloadManifest
        Assert-BoostLabCondition ([bool]$externalValid.Success) 'ExternalRuntime with a valid DIDS .nip payload should resolve successfully.'
        Assert-BoostLabCondition ([string]$externalValid.ContentSource -eq 'RuntimePayload') 'ExternalRuntime valid DIDS .nip must use runtime payload content.'
        Assert-BoostLabCondition (-not [bool]$externalValid.UsedProtectedSource) 'ExternalRuntime valid DIDS .nip must not read protected source text.'
        Assert-BoostLabCondition (-not [bool]$externalValid.RequiresProtectedSource) 'ExternalRuntime valid DIDS .nip must not require protected source folders.'
        Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $validExternalRoot 'source-ultimate') -PathType Container)) 'ExternalRuntime valid-payload temp root should not contain source-ultimate.'
        Assert-BoostLabCondition ((Get-BoostLabCanonicalTextHashFromString -Text ([string]$externalValid.Content)) -eq $sourceNipCanonical) 'ExternalRuntime valid DIDS .nip content must match source-derived canonical content.'

        $missingExternalRoot = Join-Path $tempPayloadRoot 'missing-external'
        New-Item -Path $missingExternalRoot -ItemType Directory -Force | Out-Null
        $externalMissing = & $module {
            param($Root, $Manifest)
            Resolve-BoostLabDriverInstallDebloatSettingsNipPayload -RequestedMode 'ExternalRuntime' -ProjectRoot $Root -PayloadManifest $Manifest
        } $missingExternalRoot $runtimePayloadManifest
        Assert-BoostLabCondition (-not [bool]$externalMissing.Success) 'ExternalRuntime missing DIDS .nip payload should fail closed.'
        Assert-BoostLabCondition ([string]$externalMissing.Status -eq 'RuntimePayloadUnavailable') 'ExternalRuntime missing DIDS .nip status mismatch.'
        Assert-BoostLabCondition ([string]$externalMissing.PayloadChecksumStatus -eq 'Missing') 'ExternalRuntime missing DIDS .nip checksum status mismatch.'
        Assert-BoostLabCondition (-not [bool]$externalMissing.UsedProtectedSource) 'ExternalRuntime missing DIDS .nip must not fall back to protected source.'
        Assert-BoostLabCondition ([string]$externalMissing.Message -like '*cannot fall back to protected source text*') 'ExternalRuntime missing DIDS .nip must explain source fallback is blocked.'

        $invalidExternalRoot = Join-Path $tempPayloadRoot 'invalid-external'
        $invalidExternalPayload = Join-Path $invalidExternalRoot 'runtime-payloads\driver-install-debloat-settings\inspector.nip'
        New-Item -Path (Split-Path -Parent $invalidExternalPayload) -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath $invalidExternalPayload -Value '<ArrayOfProfile>mutated</ArrayOfProfile>' -Encoding UTF8
        $externalInvalid = & $module {
            param($Root, $Manifest)
            Resolve-BoostLabDriverInstallDebloatSettingsNipPayload -RequestedMode 'ExternalRuntime' -ProjectRoot $Root -PayloadManifest $Manifest
        } $invalidExternalRoot $runtimePayloadManifest
        Assert-BoostLabCondition (-not [bool]$externalInvalid.Success) 'ExternalRuntime invalid DIDS .nip payload should fail closed.'
        Assert-BoostLabCondition ([string]$externalInvalid.PayloadChecksumStatus -eq 'Failed') 'ExternalRuntime invalid DIDS .nip checksum status mismatch.'
        Assert-BoostLabCondition (-not [bool]$externalInvalid.UsedProtectedSource) 'ExternalRuntime invalid DIDS .nip must not fall back to protected source.'

        $internalFallbackManifest = Import-PowerShellDataFile -LiteralPath $runtimePayloadManifestPath
        $internalFallbackManifest.Entries['driver-install-debloat-settings-nvidia-profile'].RuntimePayloadRelativePath = 'runtime-payloads/driver-install-debloat-settings/missing-inspector.nip'
        $internalFallback = & $module {
            param($Root, $Manifest)
            Resolve-BoostLabDriverInstallDebloatSettingsNipPayload -RequestedMode 'InternalDevelopment' -ProjectRoot $Root -PayloadManifest $Manifest
        } $ProjectRoot $internalFallbackManifest
        Assert-BoostLabCondition ([bool]$internalFallback.Success) 'InternalDevelopment missing DIDS .nip payload should use protected-source fallback when source is available.'
        Assert-BoostLabCondition ([string]$internalFallback.ContentSource -eq 'ProtectedSourceFallback') 'InternalDevelopment missing DIDS .nip should report protected-source fallback.'
        Assert-BoostLabCondition ([bool]$internalFallback.FallbackUsed) 'InternalDevelopment missing DIDS .nip should report fallback used.'
        Assert-BoostLabCondition ([bool]$internalFallback.UsedProtectedSource) 'InternalDevelopment missing DIDS .nip should report protected source use.'
        Assert-BoostLabCondition ((Get-BoostLabCanonicalTextHashFromString -Text ([string]$internalFallback.Content)) -eq $sourceNipCanonical) 'InternalDevelopment fallback DIDS .nip content must match source-derived canonical content.'
    }
    finally {
        Remove-Item -LiteralPath $tempPayloadRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

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
        if ($branch -eq 'NVIDIA') {
            Assert-BoostLabCondition ([bool]$apply.Data.RefreshRateConfirmationRequired) 'NVIDIA Apply must report refresh-rate confirmation required.'
            Assert-BoostLabCondition ([bool]$apply.Data.RestartConfirmedByUser) 'NVIDIA Apply must report restart confirmation when the confirmation operation succeeds.'
            Assert-BoostLabCondition ([bool]$apply.Data.RestartTriggered) 'NVIDIA Apply must report restart triggered after confirmation.'
            Assert-BoostLabCondition ([string]$apply.Data.ConfirmationFailureKind -eq 'Not available') 'NVIDIA Apply success must report no refresh-rate confirmation failure classification.'
            Assert-BoostLabCondition ([bool]$apply.Data.ConfirmationDialogClosed) 'NVIDIA Apply success must report the confirmation dialog closed before continuation.'
            Assert-BoostLabCondition ([bool]$apply.Data.PostConfirmationContinuationStarted) 'NVIDIA Apply success must report post-confirmation continuation started.'
            Assert-BoostLabCondition (-not [bool]$apply.Data.PostConfirmationRunsInsideCallback) 'NVIDIA Apply success must not run post-confirmation work inside the dialog callback.'
        }
    }

    $script:DriverInstallDebloatSettingsDeclineOps = [System.Collections.Generic.List[object]]::new()
    $declineExecutor = {
        param($Operation, $SelectedBranch, $Context)
        $script:DriverInstallDebloatSettingsDeclineOps.Add($Operation)
        if ([string]$Operation.Type -eq 'RefreshRateRestartConfirmation') {
            return [pscustomobject]@{
                Success = $false
                Order = [int]$Operation.Order
                Branch = [string]$Operation.Branch
                Category = [string]$Operation.Category
                Type = [string]$Operation.Type
                Label = [string]$Operation.Label
                SourceCommand = [string]$Operation.SourceCommand
                Message = 'Refresh-rate restart confirmation was not granted. Restart was not triggered.'
                Data = [pscustomobject]@{
                    NvidiaControlPanelOpenAttempted = $true
                    NvidiaControlPanelOpenSucceeded = $true
                    NvidiaControlPanelOpenCommand = 'Start-Process shell:appsFolder\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj!NVIDIACorp.NVIDIAControlPanel'
                    NvidiaControlPanelOpenPath = 'shell:appsFolder\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj!NVIDIACorp.NVIDIAControlPanel'
                    RefreshRateConfirmationRequired = $true
                    RestartConfirmedByUser = $false
                    RestartTriggered = $false
                    ConfirmationFailureKind = 'Not available'
                    ConfirmationDialogClosed = $true
                    PostConfirmationContinuationStarted = $false
                    PostConfirmationRunsInsideCallback = $false
                    FinalStatusReason = 'Refresh-rate restart confirmation was not granted; restart was not triggered.'
                }
                Timestamp = Get-Date
            }
        }

        return [pscustomobject]@{
            Success = $true
            Order = [int]$Operation.Order
            Branch = [string]$Operation.Branch
            Category = [string]$Operation.Category
            Type = [string]$Operation.Type
            Label = [string]$Operation.Label
            SourceCommand = [string]$Operation.SourceCommand
            Message = 'Mocked operation before refresh-rate confirmation.'
            Data = if ([string]$Operation.Type -eq 'SelectInstaller') {
                [pscustomobject]@{ SelectedInstaller = 'C:\BoostLabMock\NVIDIA-driver.exe' }
            }
            elseif ([string]$Operation.Type -eq 'OpenNvidiaControlPanelForRefreshRate') {
                [pscustomobject]@{
                    NvidiaControlPanelOpenAttempted = $true
                    NvidiaControlPanelOpenSucceeded = $true
                    NvidiaControlPanelOpenCommand = 'Start-Process shell:appsFolder\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj!NVIDIACorp.NVIDIAControlPanel'
                    NvidiaControlPanelOpenPath = 'shell:appsFolder\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj!NVIDIACorp.NVIDIAControlPanel'
                    RefreshRateConfirmationRequired = $true
                    RestartConfirmedByUser = $false
                    RestartTriggered = $false
                    FinalStatusReason = 'NVIDIA Control Panel opened for refresh-rate adjustment.'
                }
            }
            else {
                $null
            }
            Timestamp = Get-Date
        }
    }
    $declinedApply = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true -Branch 'NVIDIA' -InstallFile 'C:\BoostLabMock\NVIDIA-driver.exe' -SkipEnvironmentChecks:$true -OperationExecutor $declineExecutor
    Assert-BoostLabCondition ([bool]$declinedApply.Success) 'Declined refresh-rate confirmation should return a warning result, not a hard driver failure.'
    Assert-BoostLabCondition ([string]$declinedApply.Status -eq 'Warning') 'Declined refresh-rate confirmation status must be Warning.'
    Assert-BoostLabCondition ([string]$declinedApply.CommandStatus -eq 'PendingRefreshRateRestartConfirmation') 'Declined refresh-rate confirmation command status mismatch.'
    Assert-BoostLabCondition ([bool]$declinedApply.RestartRequired) 'Declined refresh-rate confirmation must keep restart required.'
    Assert-BoostLabCondition (-not [bool]$declinedApply.Data.RestartConfirmedByUser) 'Declined refresh-rate confirmation must report RestartConfirmedByUser false.'
    Assert-BoostLabCondition (-not [bool]$declinedApply.Data.RestartTriggered) 'Declined refresh-rate confirmation must not trigger restart.'
    Assert-BoostLabCondition ([string]$declinedApply.Data.ConfirmationFailureKind -eq 'Not available') 'Declined refresh-rate confirmation must not be classified as callback infrastructure failure.'
    Assert-BoostLabCondition ([bool]$declinedApply.Data.ConfirmationDialogClosed) 'Declined refresh-rate confirmation must report the dialog closed.'
    Assert-BoostLabCondition (-not [bool]$declinedApply.Data.PostConfirmationContinuationStarted) 'Declined refresh-rate confirmation must not continue into post-confirmation operations.'
    Assert-BoostLabCondition (-not [bool]$declinedApply.Data.PostConfirmationRunsInsideCallback) 'Declined refresh-rate confirmation must not run post-confirmation work inside the callback.'
    Assert-BoostLabCondition (@($script:DriverInstallDebloatSettingsDeclineOps | Where-Object { [string]$_.Type -eq 'ShutdownRestart' }).Count -eq 0) 'Restart operation must not run before refresh-rate confirmation.'

    $script:DriverInstallDebloatSettingsRestartFailOps = [System.Collections.Generic.List[object]]::new()
    $restartFailureExecutor = {
        param($Operation, $SelectedBranch, $Context)
        $script:DriverInstallDebloatSettingsRestartFailOps.Add($Operation)
        if ([string]$Operation.Type -eq 'ShutdownRestart') {
            return [pscustomobject]@{
                Success = $false
                Order = [int]$Operation.Order
                Branch = [string]$Operation.Branch
                Category = [string]$Operation.Category
                Type = [string]$Operation.Type
                Label = [string]$Operation.Label
                SourceCommand = [string]$Operation.SourceCommand
                Message = 'Mocked restart command unavailable.'
                Data = [pscustomobject]@{ RestartTriggered = $false; RestartCommand = 'shutdown -r -t 00' }
                Timestamp = Get-Date
            }
        }

        return [pscustomobject]@{
            Success = $true
            Order = [int]$Operation.Order
            Branch = [string]$Operation.Branch
            Category = [string]$Operation.Category
            Type = [string]$Operation.Type
            Label = [string]$Operation.Label
            SourceCommand = [string]$Operation.SourceCommand
            Message = 'Mocked operation before restart failure.'
            Data = if ([string]$Operation.Type -eq 'SelectInstaller') {
                [pscustomobject]@{ SelectedInstaller = 'C:\BoostLabMock\NVIDIA-driver.exe' }
            }
            elseif ([string]$Operation.Type -eq 'OpenNvidiaControlPanelForRefreshRate') {
                [pscustomobject]@{
                    NvidiaControlPanelOpenAttempted = $true
                    NvidiaControlPanelOpenSucceeded = $true
                    NvidiaControlPanelOpenCommand = 'Start-Process shell:appsFolder\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj!NVIDIACorp.NVIDIAControlPanel'
                    NvidiaControlPanelOpenPath = 'shell:appsFolder\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj!NVIDIACorp.NVIDIAControlPanel'
                    RefreshRateConfirmationRequired = $true
                    RestartConfirmedByUser = $false
                    RestartTriggered = $false
                    FinalStatusReason = 'NVIDIA Control Panel opened for refresh-rate adjustment.'
                }
            }
            elseif ([string]$Operation.Type -eq 'RefreshRateRestartConfirmation') {
                [pscustomobject]@{
                    NvidiaControlPanelOpenAttempted = $true
                    NvidiaControlPanelOpenSucceeded = $true
                    NvidiaControlPanelOpenCommand = 'Start-Process shell:appsFolder\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj!NVIDIACorp.NVIDIAControlPanel'
                    NvidiaControlPanelOpenPath = 'shell:appsFolder\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj!NVIDIACorp.NVIDIAControlPanel'
                    RefreshRateConfirmationRequired = $true
                    RestartConfirmedByUser = $true
                    RestartTriggered = $false
                    ConfirmationCallbackAvailable = $true
                    ConfirmationCallbackUsed = $true
                    ConfirmationFailureKind = 'Not available'
                    ConfirmationError = ''
                    ConfirmationDialogClosed = $true
                    PostConfirmationContinuationStarted = $false
                    PostConfirmationRunsInsideCallback = $false
                    FinalStatusReason = 'User confirmed refresh-rate adjustment is complete and restart may continue.'
                }
            }
            else {
                $null
            }
            Timestamp = Get-Date
        }
    }
    $restartFailedApply = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true -Branch 'NVIDIA' -InstallFile 'C:\BoostLabMock\NVIDIA-driver.exe' -SkipEnvironmentChecks:$true -OperationExecutor $restartFailureExecutor
    Assert-BoostLabCondition (-not [bool]$restartFailedApply.Success) 'Restart command failure must return a controlled failed result.'
    Assert-BoostLabCondition ([string]$restartFailedApply.Status -eq 'OperationFailed') 'Restart command failure status mismatch.'
    Assert-BoostLabCondition ([bool]$restartFailedApply.Data.RestartConfirmedByUser) 'Restart command failure must preserve the prior Yes confirmation diagnostic.'
    Assert-BoostLabCondition ([bool]$restartFailedApply.Data.ConfirmationDialogClosed) 'Restart command failure must preserve dialog-closed diagnostic.'
    Assert-BoostLabCondition ([bool]$restartFailedApply.Data.PostConfirmationContinuationStarted) 'Restart command failure must report post-confirmation continuation started.'
    Assert-BoostLabCondition (-not [bool]$restartFailedApply.Data.RestartTriggered) 'Failed restart command must not report restart triggered.'
    Assert-BoostLabCondition (@($script:DriverInstallDebloatSettingsRestartFailOps | Where-Object { [string]$_.Type -eq 'ShutdownRestart' }).Count -eq 1) 'Restart command failure must attempt the approved restart operation exactly once.'

    $script:DriverInstallDebloatSettingsOpenFailOps = [System.Collections.Generic.List[object]]::new()
    $openFailureExecutor = {
        param($Operation, $SelectedBranch, $Context)
        $script:DriverInstallDebloatSettingsOpenFailOps.Add($Operation)
        if ([string]$Operation.Type -eq 'OpenNvidiaControlPanelForRefreshRate') {
            return [pscustomobject]@{
                Success = $false
                Order = [int]$Operation.Order
                Branch = [string]$Operation.Branch
                Category = [string]$Operation.Category
                Type = [string]$Operation.Type
                Label = [string]$Operation.Label
                SourceCommand = [string]$Operation.SourceCommand
                Message = 'NVIDIA Control Panel could not be opened: mocked missing AppX target.'
                Data = [pscustomobject]@{
                    NvidiaControlPanelOpenAttempted = $true
                    NvidiaControlPanelOpenSucceeded = $false
                    NvidiaControlPanelOpenCommand = 'Start-Process shell:appsFolder\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj!NVIDIACorp.NVIDIAControlPanel'
                    NvidiaControlPanelOpenPath = 'shell:appsFolder\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj!NVIDIACorp.NVIDIAControlPanel'
                    RefreshRateConfirmationRequired = $true
                    RestartConfirmedByUser = $false
                    RestartTriggered = $false
                    FinalStatusReason = 'NVIDIA Control Panel could not be opened; restart was not triggered.'
                }
                Timestamp = Get-Date
            }
        }

        return [pscustomobject]@{
            Success = $true
            Order = [int]$Operation.Order
            Branch = [string]$Operation.Branch
            Category = [string]$Operation.Category
            Type = [string]$Operation.Type
            Label = [string]$Operation.Label
            SourceCommand = [string]$Operation.SourceCommand
            Message = 'Mocked operation before NVIDIA Control Panel launch.'
            Data = if ([string]$Operation.Type -eq 'SelectInstaller') { [pscustomobject]@{ SelectedInstaller = 'C:\BoostLabMock\NVIDIA-driver.exe' } } else { $null }
            Timestamp = Get-Date
        }
    }
    $openFailedApply = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true -Branch 'NVIDIA' -InstallFile 'C:\BoostLabMock\NVIDIA-driver.exe' -SkipEnvironmentChecks:$true -OperationExecutor $openFailureExecutor
    Assert-BoostLabCondition ([bool]$openFailedApply.Success) 'NVIDIA Control Panel launch failure should return a warning result and stop before restart.'
    Assert-BoostLabCondition ([string]$openFailedApply.Status -eq 'Warning') 'NVIDIA Control Panel launch failure status must be Warning.'
    Assert-BoostLabCondition ([string]$openFailedApply.CommandStatus -eq 'NvidiaControlPanelOpenFailed') 'NVIDIA Control Panel launch failure command status mismatch.'
    Assert-BoostLabCondition ([bool]$openFailedApply.Data.NvidiaControlPanelOpenAttempted) 'NVIDIA Control Panel launch failure must report attempted open.'
    Assert-BoostLabCondition (-not [bool]$openFailedApply.Data.NvidiaControlPanelOpenSucceeded) 'NVIDIA Control Panel launch failure must report open did not succeed.'
    Assert-BoostLabCondition (-not [bool]$openFailedApply.Data.RestartTriggered) 'NVIDIA Control Panel launch failure must not trigger restart.'
    Assert-BoostLabCondition (@($script:DriverInstallDebloatSettingsOpenFailOps | Where-Object { [string]$_.Type -in @('RefreshRateRestartConfirmation', 'ShutdownRestart') }).Count -eq 0) 'NVIDIA Control Panel launch failure must stop before confirmation and restart.'

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
