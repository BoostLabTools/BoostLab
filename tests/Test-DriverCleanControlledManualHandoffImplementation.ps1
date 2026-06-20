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
        throw 'Unable to determine the Driver Clean exact parity validator path.'
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
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot

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

function Assert-BoostLabNoDuplicateWarnings {
    param(
        [Parameter(Mandatory)]
        [object]$Result,

        [Parameter(Mandatory)]
        [string]$Description
    )

    $resultWarnings = @($Result.Warnings)
    $dataWarnings = if ($null -ne $Result.Data -and $null -ne $Result.Data.PSObject.Properties['Warnings']) {
        @($Result.Data.Warnings)
    }
    else {
        @()
    }
    $combinedWarnings = @($resultWarnings + $dataWarnings)
    $uniqueWarnings = @($combinedWarnings | Select-Object -Unique)

    Assert-BoostLabCondition ($resultWarnings.Count -eq 0) "$Description should keep warnings in structured Data only."
    Assert-BoostLabCondition ($combinedWarnings.Count -eq $uniqueWarnings.Count) "$Description contains duplicate warning text."
}

$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$modulePath = Join-Path $ProjectRoot 'modules\Graphics\driver-clean.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate\5 Graphics\1 Driver Clean.ps1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$modulesRoot = Join-Path $ProjectRoot 'modules'

foreach ($path in @($stagesPath, $executionPath, $actionPlanPath, $modulePath, $uiPath, $sourcePath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required file was not found: $path"
}

$expectedSourceHash = 'CF9E1C55ACAFD8A52D2200AC3E6C3AFDF9823837C7B68101C2D4B83E074D325A'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Driver Clean source mirror hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."
$sourceText = Get-Content -LiteralPath $sourcePath -Raw
Assert-BoostLabTextContains -Text $sourceText -Needle 'DDU: Auto' -Description 'Driver Clean Ultimate source labels'
Assert-BoostLabTextContains -Text $sourceText -Needle 'DDU: Manual' -Description 'Driver Clean Ultimate source labels'

$config = Import-PowerShellDataFile -LiteralPath $stagesPath
$graphicsStage = @($config.Stages | Where-Object { $_.Name -eq 'Graphics' })[0]
Assert-BoostLabCondition ($null -ne $graphicsStage) 'Graphics stage was not found.'

$driverCleanTool = @($graphicsStage.Tools | Where-Object { $_.Id -eq 'driver-clean' })[0]
Assert-BoostLabCondition ($null -ne $driverCleanTool) 'Driver Clean was not found as an active Graphics tool.'
Assert-BoostLabCondition ([string]$driverCleanTool.Title -eq 'Driver Clean') 'Driver Clean title mismatch.'
Assert-BoostLabCondition ([int]$driverCleanTool.Order -eq 1) 'Driver Clean must remain separate first Graphics tool.'
Assert-BoostLabCondition ([string]$driverCleanTool.Type -eq 'assistant') 'Driver Clean must remain an assistant tool.'
Assert-BoostLabCondition ([string]$driverCleanTool.RiskLevel -eq 'high') 'Driver Clean must remain high risk.'
Assert-BoostLabCondition ((@($driverCleanTool.Actions) -join '|') -eq 'Analyze|Open|Apply') 'Driver Clean actions must remain canonical Analyze, Open, Apply.'
Assert-BoostLabTextContains -Text ([string]$driverCleanTool.Description) -Needle 'Source-equivalent Driver Clean workflow' -Description 'Driver Clean description'
Assert-BoostLabTextContains -Text ([string]$driverCleanTool.Description) -Needle 'Ultimate DDU Auto branch' -Description 'Driver Clean description'
Assert-BoostLabTextContains -Text ([string]$driverCleanTool.Description) -Needle 'Ultimate DDU Manual branch' -Description 'Driver Clean description'

$capabilities = $driverCleanTool.Capabilities
foreach ($trueCapability in @(
    'RequiresAdmin'
    'RequiresInternet'
    'CanReboot'
    'CanModifyRegistry'
    'CanInstallSoftware'
    'CanDownload'
    'CanModifyDrivers'
    'CanDeleteFiles'
    'UsesSafeMode'
    'NeedsExplicitConfirmation'
)) {
    Assert-BoostLabCondition ([bool]$capabilities[$trueCapability]) "Driver Clean capability should be true: $trueCapability"
}
foreach ($falseCapability in @(
    'CanModifyServices'
    'CanModifySecurity'
    'UsesTrustedInstaller'
    'SupportsDefault'
    'SupportsRestore'
)) {
    Assert-BoostLabCondition (-not [bool]$capabilities[$falseCapability]) "Driver Clean capability should be false: $falseCapability"
}

$allTools = @($config.Stages | ForEach-Object { $_.Tools })
$placeholderModules = @(
    Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
Assert-BoostLabCondition ($allTools.Count -eq $inventoryBaseline.ActiveTools) "Expected $($inventoryBaseline.ActiveTools) active tools, found $($allTools.Count)."
Assert-BoostLabCondition ($placeholderModules.Count -eq $inventoryBaseline.DeferredPlaceholders) "Expected $($inventoryBaseline.DeferredPlaceholders) placeholders, found $($placeholderModules.Count)."
Assert-BoostLabCondition (($allTools.Count - $placeholderModules.Count) -eq $inventoryBaseline.ImplementedTools) "Expected $($inventoryBaseline.ImplementedTools) implemented tools, found $($allTools.Count - $placeholderModules.Count)."

$sourcePromotedFiles = @(Get-ChildItem -LiteralPath (Join-Path $sourceRoot '_intake-promoted\Ultimate') -Recurse -File)
Assert-BoostLabCondition ($sourcePromotedFiles.Count -eq $inventoryBaseline.SourcePromotedMirrorFiles) "Expected $($inventoryBaseline.SourcePromotedMirrorFiles) source-promoted mirror files, found $($sourcePromotedFiles.Count)."
Assert-BoostLabCondition ([int]$inventoryBaseline.RemainingSourcePromotedIntakeCandidates -eq 0) 'Remaining source-promoted intake candidates baseline must remain 0.'

$executionText = Get-Content -LiteralPath $executionPath -Raw
foreach ($needle in @(
    "'driver-clean'",
    "Graphics\driver-clean.psm1",
    "'Analyze', 'Open', 'Apply'"
)) {
    Assert-BoostLabTextContains -Text $executionText -Needle $needle -Description 'Execution registry'
}

$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($needle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Open'', ''Apply'')',
    'SourceEquivalentDriverClean',
    'SourceEquivalentAutoAvailable',
    'SourceEquivalentManualAvailable',
    'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe',
    'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/ddu.exe',
    'Display Driver Uninstaller.exe',
    '-CleanSoundBlaster -CleanRealtek -CleanAllGpus -Restart',
    'SearchOrderConfig',
    'driver-clean-driver-search-policy',
    'bcdedit /set {current} safeboot minimal',
    'shutdown -r -t 00',
    $expectedSourceHash
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'Driver Clean module'
}

$artifactText = Get-Content -LiteralPath (Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1') -Raw
Assert-BoostLabCondition (-not ($artifactText -match '(?i)Display Driver Uninstaller|DDU|7-Zip|7zip')) 'DDU or 7-Zip artifact approval was unexpectedly added.'

foreach ($forbiddenPath in @(
    'config\DriverCleanPolicy.psd1'
    'config\DriverCleanAllowlist.psd1'
    'config\DduPolicy.psd1'
    'config\DduArtifacts.psd1'
    'config\DriverCleanArtifacts.psd1'
    'config\DriverCleanWorkflow.psd1'
    'config\DriverCleanRuntime.psd1'
)) {
    Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $forbiddenPath))) "Driver Clean/DDU production approval config was unexpectedly created: $forbiddenPath"
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
$module = Import-Module -Name $modulePath -Force -PassThru -ErrorAction Stop
try {
    $info = Get-BoostLabToolInfo
    Assert-BoostLabCondition ([string]$info.Id -eq 'driver-clean') 'Driver Clean module info Id mismatch.'
    Assert-BoostLabCondition ((@($info.ImplementedActions) -join '|') -eq 'Analyze|Open|Apply') 'Driver Clean implemented actions mismatch.'
    Assert-BoostLabCondition ((@($info.ConfirmationRequiredActions) -join '|') -eq 'Open|Apply') 'Driver Clean confirmation-required actions must remain canonical.'

    $analysisResult = Invoke-BoostLabToolAction -ActionName 'Analyze'
    Assert-BoostLabCondition ([bool]$analysisResult.Success) 'Driver Clean Analyze should pass when source checksum matches.'
    Assert-BoostLabCondition ([string]$analysisResult.Status -eq 'Analyzed') 'Driver Clean Analyze status mismatch.'
    Assert-BoostLabCondition ([string]$analysisResult.CommandStatus -eq 'No execution performed') 'Analyze must remain read-only.'
    Assert-BoostLabCondition (-not [bool]$analysisResult.ChangesExecuted) 'Analyze must report no changes executed.'
    Assert-BoostLabCondition ([string]$analysisResult.Data.Mode -eq 'SourceEquivalentDriverClean') 'Analyze mode mismatch.'
    Assert-BoostLabCondition ([string]$analysisResult.Data.AutoMode -eq 'SourceEquivalentAutoAvailable') 'Analyze Auto mode mismatch.'
    Assert-BoostLabCondition ([string]$analysisResult.Data.ManualMode -eq 'SourceEquivalentManualAvailable') 'Analyze Manual mode mismatch.'
    Assert-BoostLabCondition ([string]$analysisResult.Data.Source.ChecksumStatus -eq 'Passed') 'Analyze source checksum status mismatch.'
    Assert-BoostLabCondition ([int]$analysisResult.Data.ApplyPlan.OperationCount -eq 16) 'Auto operation count must match the source branch.'
    Assert-BoostLabCondition ([int]$analysisResult.Data.OpenPlan.OperationCount -eq 16) 'Manual operation count must match the source branch.'
    Assert-BoostLabCondition ([bool]$analysisResult.Data.NoMutationOccurred) 'Analyze must report no mutation.'
    Assert-BoostLabCondition ([bool]$analysisResult.Data.NoDownloadOccurred) 'Analyze must report no download.'
    Assert-BoostLabCondition ([bool]$analysisResult.Data.NoExternalProcessStarted) 'Analyze must report no external process.'
    Assert-BoostLabNoDuplicateWarnings -Result $analysisResult -Description 'Driver Clean Analyze'

    $autoPlan = $analysisResult.Data.ApplyPlan
    $manualPlan = $analysisResult.Data.OpenPlan
    Assert-BoostLabCondition ((@($autoPlan.Operations | ForEach-Object { $_.Type }) -join '|') -eq 'DownloadFile|StartProcess|Cmd|Cmd|MoveItem|RemoveItem|DownloadFile|ExternalCommand|WriteTextFile|SetFileReadOnly|SetDriverSearchPolicy|WriteTextFile|Cmd|Cmd|Sleep|ShutdownRestart') 'Auto operation sequence must preserve source order.'
    Assert-BoostLabCondition ((@($manualPlan.Operations | ForEach-Object { $_.Type }) -join '|') -eq 'DownloadFile|StartProcess|Cmd|Cmd|MoveItem|RemoveItem|DownloadFile|ExternalCommand|WriteTextFile|SetFileReadOnly|SetDriverSearchPolicy|WriteTextFile|Cmd|Cmd|Sleep|ShutdownRestart') 'Manual operation sequence must preserve source order.'
    Assert-BoostLabCondition ([string]$autoPlan.Downloads[0].Uri -eq 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe') '7-Zip source URL mismatch.'
    Assert-BoostLabCondition ([string]$autoPlan.Downloads[1].Uri -eq 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/ddu.exe') 'DDU source URL mismatch.'
    Assert-BoostLabCondition ([string]$autoPlan.DriverSearchPolicy.RegistryPath -eq 'HKLM:\Software\Microsoft\Windows\CurrentVersion\DriverSearching') 'Driver search policy path mismatch.'
    Assert-BoostLabCondition ([string]$autoPlan.DriverSearchPolicy.ValueName -eq 'SearchOrderConfig') 'Driver search policy value name mismatch.'
    Assert-BoostLabCondition ([int]$autoPlan.DriverSearchPolicy.ValueData -eq 0) 'Driver search policy value data mismatch.'
    Assert-BoostLabCondition ((@($autoPlan.Operations | Where-Object { $_.SourceCommand -match 'RunOnce' -and $_.SourceCommand -match '\*ddu' }).Count -eq 1)) 'Auto RunOnce entry must use *ddu.'
    Assert-BoostLabCondition ((@($manualPlan.Operations | Where-Object { $_.SourceCommand -match 'RunOnce' -and $_.SourceCommand -match '\*ddumanual' }).Count -eq 1)) 'Manual RunOnce entry must use *ddumanual.'
    Assert-BoostLabCondition (($autoPlan.Operations[11].Parameters.Content.Contains('Start-Process "$env:SystemRoot\Temp\ddu\Display Driver Uninstaller.exe" -ArgumentList "-CleanSoundBlaster -CleanRealtek -CleanAllGpus -Restart" -Wait'))) 'Auto generated script must preserve DDU Auto command.'
    Assert-BoostLabCondition (($manualPlan.Operations[11].Parameters.Content.Contains('Start-Process -Wait "$env:SystemRoot\Temp\ddu\Display Driver Uninstaller.exe"'))) 'Manual generated script must preserve DDU Manual launch.'

    $executedOperations = [System.Collections.Generic.List[object]]::new()
    $mockExecutor = {
        param($Operation, $Mode)

        $script:executedOperations.Add([pscustomobject]@{
            Mode = $Mode
            Type = [string]$Operation.Type
            Label = [string]$Operation.Label
            SourceCommand = [string]$Operation.SourceCommand
            Parameters = $Operation.Parameters
        }) | Out-Null

        [pscustomobject]@{
            Success = $true
            Operation = $Operation
            Message = 'Mocked operation completed.'
            Captures = if ([string]$Operation.Type -eq 'SetDriverSearchPolicy') {
                @([pscustomobject]@{ Success = $true; ScopeId = [string]$Operation.Parameters.ScopeId; RegistryPath = [string]$Operation.Parameters.RegistryPath; ValueName = [string]$Operation.Parameters.ValueName })
            }
            else {
                @()
            }
            Errors = @()
        }
    }.GetNewClosure()

    $script:executedOperations = $executedOperations
    $applyResult = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true -SkipEnvironmentChecks:$true -OperationExecutor $mockExecutor
    Assert-BoostLabCondition ([bool]$applyResult.Success) 'Mocked Apply Auto should succeed.'
    Assert-BoostLabCondition ([string]$applyResult.Status -eq 'AutoWorkflowScheduled') 'Apply Auto status mismatch.'
    Assert-BoostLabCondition ([string]$applyResult.CommandStatus -eq 'Completed source-equivalent Driver Clean preparation; reboot requested') 'Apply Auto command status mismatch.'
    Assert-BoostLabCondition ([bool]$applyResult.ChangesExecuted) 'Apply Auto must report changes executed.'
    Assert-BoostLabCondition ([bool]$applyResult.RestartRequired) 'Apply Auto must report restart required.'
    Assert-BoostLabCondition ([int]$applyResult.Data.CompletedOperationCount -eq 16) 'Apply Auto should execute all source operations with the mock executor.'
    Assert-BoostLabCondition ((@($applyResult.Data.Captures).Count -eq 1)) 'Apply Auto should capture the source-defined driver-search policy value before mutation.'
    Assert-BoostLabTextContains -Text ([string]$applyResult.Message) -Needle '-CleanSoundBlaster -CleanRealtek -CleanAllGpus -Restart' -Description 'Apply Auto result message'

    $applyOperations = @($script:executedOperations | Where-Object { $_.Mode -eq 'Auto' })
    Assert-BoostLabCondition ($applyOperations.Count -eq 16) 'Mocked Apply Auto operation count mismatch.'
    Assert-BoostLabCondition ((@($applyOperations | Where-Object { $_.Type -eq 'ShutdownRestart' }).Count -eq 1)) 'Apply Auto must include restart operation.'
    Assert-BoostLabCondition ((@($applyOperations | Where-Object { $_.SourceCommand -eq 'shutdown -r -t 00' }).Count -eq 1)) 'Apply Auto must preserve shutdown command.'

    $script:executedOperations.Clear()
    $openResult = Invoke-BoostLabToolAction -ActionName 'Open' -Confirmed:$true -SkipEnvironmentChecks:$true -OperationExecutor $mockExecutor
    Assert-BoostLabCondition ([bool]$openResult.Success) 'Mocked Open Manual should succeed.'
    Assert-BoostLabCondition ([string]$openResult.Status -eq 'ManualWorkflowScheduled') 'Open Manual status mismatch.'
    Assert-BoostLabCondition ([bool]$openResult.ChangesExecuted) 'Open Manual must report changes executed.'
    Assert-BoostLabCondition ([bool]$openResult.RestartRequired) 'Open Manual must report restart required.'
    Assert-BoostLabCondition ([int]$openResult.Data.CompletedOperationCount -eq 16) 'Open Manual should execute all source operations with the mock executor.'
    Assert-BoostLabTextContains -Text ([string]$openResult.Message) -Needle 'RunOnce will launch DDU manually' -Description 'Open Manual result message'

    $openOperations = @($script:executedOperations | Where-Object { $_.Mode -eq 'Manual' })
    Assert-BoostLabCondition ($openOperations.Count -eq 16) 'Mocked Open Manual operation count mismatch.'
    Assert-BoostLabCondition ((@($openOperations | Where-Object { $_.SourceCommand -match '\*ddumanual' }).Count -eq 1)) 'Open Manual must preserve *ddumanual RunOnce value.'

    $failingExecutor = {
        param($Operation, $Mode)
        if ([string]$Operation.Type -eq 'SetDriverSearchPolicy') {
            return [pscustomobject]@{
                Success = $false
                Operation = $Operation
                Message = 'Capture failed.'
                Captures = @()
                Errors = @('Registry capture failed before mutation.')
            }
        }

        [pscustomobject]@{
            Success = $true
            Operation = $Operation
            Message = 'Mocked operation completed.'
            Captures = @()
            Errors = @()
        }
    }
    $failedApply = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true -SkipEnvironmentChecks:$true -OperationExecutor $failingExecutor
    Assert-BoostLabCondition (-not [bool]$failedApply.Success) 'Apply Auto must fail closed when capture/write preparation fails.'
    Assert-BoostLabCondition ([string]$failedApply.Status -eq 'OperationFailed') 'Failed Apply status mismatch.'
    Assert-BoostLabTextContains -Text ((@($failedApply.Errors) -join "`n")) -Needle 'Registry capture failed before mutation' -Description 'Failed Apply errors'

    foreach ($refusedAction in @('Default', 'Restore')) {
        $refused = Invoke-BoostLabToolAction -ActionName $refusedAction
        Assert-BoostLabCondition (-not [bool]$refused.Success) "$refusedAction must remain unavailable."
        Assert-BoostLabCondition ([string]$refused.Status -eq 'Unavailable') "$refusedAction status mismatch."
        Assert-BoostLabTextContains -Text ([string]$refused.Message) -Needle 'Default is not Restore' -Description "$refusedAction refusal"
        Assert-BoostLabTextContains -Text ([string]$refused.Message) -Needle 'selected captured state' -Description "$refusedAction refusal"
    }

    $analyzePlan = New-BoostLabActionPlan -ToolMetadata $driverCleanTool -ActionName 'Analyze'
    Assert-BoostLabTextContains -Text ([string]$analyzePlan.Summary) -Needle 'source-equivalent Auto and Manual DDU workflows' -Description 'Analyze Action Plan summary'
    Assert-BoostLabCondition (-not ((@($analyzePlan.PlannedChanges) -join "`n") -match 'Download the source-defined')) 'Analyze plan must remain read-only.'

    $openPlan = New-BoostLabActionPlan -ToolMetadata $driverCleanTool -ActionName 'Open'
    $openPlanText = @(
        $openPlan.Summary
        @($openPlan.PlannedChanges)
        @($openPlan.SideEffects)
        $openPlan.ConfirmationMessage
    ) -join "`n"
    foreach ($needle in @(
        'source-equivalent Driver Clean Manual branch',
        'Download the source-defined 7-Zip and DDU artifacts',
        'Create the source-defined ddumanual.ps1 script and RunOnce entry',
        'enable bcdedit Safe Mode minimal',
        'restart'
    )) {
        Assert-BoostLabTextContains -Text $openPlanText -Needle $needle -Description 'Open Action Plan'
    }
    Assert-BoostLabCondition (-not $openPlanText.Contains('manual handoff instructions only')) 'Open Action Plan must not use old manual-only wording.'
    Assert-BoostLabCondition (-not $openPlanText.Contains('Auto mode is blocked')) 'Open Action Plan must not use old blocked wording.'

    $applyPlan = New-BoostLabActionPlan -ToolMetadata $driverCleanTool -ActionName 'Apply'
    $applyPlanText = @(
        $applyPlan.Summary
        @($applyPlan.PlannedChanges)
        @($applyPlan.SideEffects)
        $applyPlan.ConfirmationMessage
    ) -join "`n"
    foreach ($needle in @(
        'source-equivalent Driver Clean Auto branch',
        'Create the source-defined ddu.ps1 script and RunOnce entry',
        '-CleanSoundBlaster -CleanRealtek -CleanAllGpus -Restart',
        'enable bcdedit Safe Mode minimal',
        'restart'
    )) {
        Assert-BoostLabTextContains -Text $applyPlanText -Needle $needle -Description 'Apply Action Plan'
    }
    Assert-BoostLabCondition (-not $applyPlanText.Contains('Auto mode is blocked')) 'Apply Action Plan must not use old blocked wording.'
    Assert-BoostLabCondition (-not $applyPlanText.Contains('Do not execute any approved Auto behavior')) 'Apply Action Plan must not use old no-execution wording.'
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$driverCleanRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'driver-clean' })[0]
Assert-BoostLabCondition ($null -ne $driverCleanRecord) 'Driver Clean parity record was not found.'
Assert-BoostLabCondition ([string]$driverCleanRecord.ImplementationLevel -eq 'NearParityControlled') 'Driver Clean implementation level must be NearParityControlled after Phase 120.'
Assert-BoostLabCondition ([string]$driverCleanRecord.UltimateParity -eq 'Partial') 'Driver Clean UltimateParity should remain Partial due BoostLab GUI confirmation/test-safe mechanics.'
Assert-BoostLabCondition ([bool]$driverCleanRecord.YazanAcceptedNearParity) 'Driver Clean must be Yazan-accepted near parity.'
Assert-BoostLabCondition ([string]$driverCleanRecord.FinalProgressStatus -eq 'DoneYazanAcceptedNearParity') 'Driver Clean final progress status mismatch.'
Assert-BoostLabTextContains -Text ([string]$driverCleanRecord.GapSummary) -Needle 'exact source-equivalent Driver Clean DDU Auto/Manual behavior' -Description 'Driver Clean gap summary'

$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
Assert-BoostLabCondition ([int]$categoryCounts['ParityImplemented'] -eq [int]$parityBaseline.Counts.UltimateParityImplemented) 'ParityImplemented count mismatch.'
Assert-BoostLabCondition ([int]$categoryCounts['NearParityControlled'] -eq [int]$parityBaseline.Counts.NearParityControlled) 'NearParityControlled count mismatch.'
Assert-BoostLabCondition ([int]$categoryCounts['ManualHandoffOnly'] -eq [int]$parityBaseline.Counts.ManualHandoffOnly) 'ManualHandoffOnly count mismatch.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.NearParityControlled -eq 22) 'NearParityControlled baseline should be 22 after Driver Install Latest.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.ManualHandoffOnly -eq 4) 'ManualHandoffOnly baseline should be 4 after Driver Install Latest.'

$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq 'nvidia-settings') 'Next ordered pending parity target should advance to Nvidia Settings.'

$uiText = Get-Content -LiteralPath $uiPath -Raw
foreach ($needle in @(
    'Get-BoostLabToolActionDisplayLabel',
    "if (`$toolId -eq 'driver-clean')",
    "'Open' { return 'Manual' }",
    "'Apply' { return 'Auto' }",
    "if (`$toolId -eq 'nvidia-settings')",
    "'Open' { return 'Manual Handoff' }",
    "'Apply' { return 'Apply Auto' }",
    'ActionName   = $actionName',
    'ActionLabel  = $actionDisplayLabel'
)) {
    Assert-BoostLabTextContains -Text $uiText -Needle $needle -Description 'Driver Clean UI display label mapping'
}
Assert-BoostLabCondition (-not $uiText.Contains("'driver-clean', 'nvidia-settings'")) 'Driver Clean must not share the Nvidia Settings Manual Handoff label mapping.'

Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'modules\Graphics\ddu.psm1'))) 'Standalone DDU module was reintroduced.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'modules\Graphics\DDU.psm1'))) 'Standalone DDU module was reintroduced.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\23 NVME Faster Driver.ps1'))) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    Passed = $true
    ActiveTools = $allTools.Count
    ImplementedTools = $allTools.Count - $placeholderModules.Count
    DeferredPlaceholders = $placeholderModules.Count
    SourcePromotedMirrorFiles = $sourcePromotedFiles.Count
    DriverCleanMode = 'SourceEquivalentDriverClean'
    AutoOperationCount = 16
    ManualOperationCount = 16
    NextOrderedParityTarget = [string]$nextTarget.ToolId
    Message = 'Driver Clean exact Ultimate Auto and Manual workflow parity is implemented with mock-safe validation.'
}
