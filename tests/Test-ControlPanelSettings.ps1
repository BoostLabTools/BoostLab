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
    else {
        $MyInvocation.MyCommand.Path
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
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\15 Control Panel Settings.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\control-panel-settings.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$expectedSourceHash = 'B78F643D21069F14E7E766769FB1EE15AEF974ABDF3CA010FE808D9EC162FB0B'
Assert-BoostLabCondition ((Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash -eq $expectedSourceHash) 'Control Panel Settings Ultimate source hash changed.'

$sourceText = Get-Content -LiteralPath $sourcePath -Raw
foreach ($requiredSourceText in @(
    'function Run-Trusted([String]$command)'
    'Write-Host "1. Control Panel Settings: Optimize (Recommended)"'
    'Write-Host "2. Control Panel Settings: Default`n"'
    'Write-Host "Control Panel Settings: Optimize..."'
    'Write-Host "Control Panel Settings: Default..."'
    'Stop-Service -Name ''camsvc'' -Force -ErrorAction SilentlyContinue'
    'Run-Trusted -command $capabilityconsentstoragedb'
    'registryoptimize.reg'
    'registrydefaults.reg'
    'disablesetprioritynotifications.reg'
    'appactions.reg'
    'Get-ScheduledTask | Where-Object {$_.TaskName -match ''ScheduledDefrag''} | Disable-ScheduledTask | Out-Null'
    'Get-ScheduledTask | Where-Object {$_.TaskName -match ''ScheduledDefrag''} | Enable-ScheduledTask | Out-Null'
    'powercfg /setdcvalueindex scheme_current sub_none consolelock 0'
    'powercfg /setdcvalueindex scheme_current sub_none consolelock 1'
    'reg load "HKLM\Settings" $settingsdat'
    'reg import $regfileappactions'
    'Remove-Item "$env:LOCALAPPDATA\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\Settings\settings.dat" -Force -ErrorAction SilentlyContinue | Out-Null'
)) {
    Assert-BoostLabCondition ($sourceText.Contains($requiredSourceText)) "Control Panel Settings source is missing expected behavior: $requiredSourceText"
}
foreach ($forbiddenSourceText in @(
    'Invoke-WebRequest'
    'Restart-Computer'
    'bcdedit'
)) {
    Assert-BoostLabCondition (-not $sourceText.Contains($forbiddenSourceText)) "Control Panel Settings source unexpectedly contains out-of-scope behavior: $forbiddenSourceText"
}

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$windowsStage = @($configuration.Stages | Where-Object { $_.Name -eq 'Windows' })[0]
$tool = @($windowsStage.Tools | Where-Object { $_.Id -eq 'control-panel-settings' })[0]
Assert-BoostLabCondition ([string]$tool.Type -eq 'action') 'Control Panel Settings must be an action tool.'
Assert-BoostLabCondition ([string]$tool.RiskLevel -eq 'high') 'Control Panel Settings risk level must be high.'
Assert-BoostLabCondition ((@($tool.Actions) -join ',') -eq 'Apply,Default') 'Control Panel Settings must expose only Apply and Default.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.RequiresAdmin) 'Control Panel Settings must require admin.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.CanModifyRegistry) 'Control Panel Settings must report registry mutation.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.CanModifyServices) 'Control Panel Settings must report service mutation.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.CanModifySecurity) 'Control Panel Settings must report security mutation.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.CanDeleteFiles) 'Control Panel Settings must report file deletion.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.UsesTrustedInstaller) 'Control Panel Settings must report TrustedInstaller usage.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.SupportsDefault) 'Control Panel Settings must support source Default.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.SupportsRestore) 'Control Panel Settings must not expose Restore.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.NeedsExplicitConfirmation) 'Control Panel Settings must require confirmation.'

$moduleSource = Get-Content -LiteralPath $modulePath -Raw
foreach ($requiredModuleText in @(
    '$script:BoostLabExpectedSourceHash'
    '$script:BoostLabSourceRelativePath'
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    'Get-BoostLabControlPanelSettingsRunTrustedBlock'
    'Get-BoostLabControlPanelSettingsBranchScript'
    'ConvertTo-BoostLabControlPanelSettingsRuntimeScript'
    'Invoke-BoostLabControlPanelSettingsScript'
    'ContainsExit'
    'SourceVerificationFailed'
)) {
    Assert-BoostLabCondition ($moduleSource.Contains($requiredModuleText)) "Control Panel Settings module is missing expected implementation text: $requiredModuleText"
}
foreach ($forbiddenModuleText in @(
    'ToolModule.Placeholder.ps1'
    'ManualHandoffOnly'
    'Actions = @(''Open'')'
    'SupportsRestore           = $true'
    'Invoke-WebRequest'
    'Restart-Computer'
    'bcdedit'
)) {
    Assert-BoostLabCondition (-not $moduleSource.Contains($forbiddenModuleText)) "Control Panel Settings module contains forbidden behavior or stale placeholder text: $forbiddenModuleText"
}

$tokens = $null
$parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseFile(
    $modulePath,
    [ref]$tokens,
    [ref]$parseErrors
) | Out-Null
if (@($parseErrors).Count -gt 0) {
    throw "Control Panel Settings module syntax error: $($parseErrors[0].Message)"
}

$controlPanelModule = Import-Module -Name $modulePath -Force -PassThru -Prefix 'ControlPanelTest' -Scope Local -DisableNameChecking -ErrorAction Stop
try {
    $info = Get-ControlPanelTestBoostLabToolInfo
    Assert-BoostLabCondition ([string]$info.Id -eq 'control-panel-settings') 'Module info id mismatch.'
    Assert-BoostLabCondition ((@($info.Actions) -join ',') -eq 'Apply,Default') 'Module info actions mismatch.'
    Assert-BoostLabCondition ((@($info.ImplementedActions) -join ',') -eq 'Apply,Default') 'Module implemented actions mismatch.'
    Assert-BoostLabCondition (-not ('Open' -in @($info.Actions))) 'Control Panel Settings must not expose Open.'
    Assert-BoostLabCondition (-not ('Restore' -in @($info.Actions))) 'Control Panel Settings must not expose Restore.'

    $sourceStatus = & $controlPanelModule { Get-BoostLabControlPanelSettingsSourceStatus }
    Assert-BoostLabCondition ([string]$sourceStatus.ChecksumStatus -eq 'Passed') 'Control Panel Settings source status must pass.'

    $applyBranch = & $controlPanelModule {
        param($Source)
        Get-BoostLabControlPanelSettingsBranchScript -ActionName Apply -SourceText $Source
    } $sourceText
    $defaultBranch = & $controlPanelModule {
        param($Source)
        Get-BoostLabControlPanelSettingsBranchScript -ActionName Default -SourceText $Source
    } $sourceText

    foreach ($branch in @($applyBranch, $defaultBranch)) {
        Assert-BoostLabCondition ([bool]$branch.ContainsRunTrusted) "$($branch.ActionName) branch must contain Run-Trusted."
        Assert-BoostLabCondition ([bool]$branch.ContainsRegistryPayload) "$($branch.ActionName) branch must contain registry payload."
        Assert-BoostLabCondition (-not [bool]$branch.ContainsExit) "$($branch.ActionName) branch script passed to runtime must not contain terminal exit."
    }
    foreach ($requiredApplyText in @(
        'Control Panel Settings: Optimize...'
        'Stop-Service -Name ''camsvc'''
        'reg add `"HKLM\SYSTEM\ControlSet001\Services\CDPUserSvc`" /v `"Start`" /t REG_DWORD /d `"4`"'
        '$RegistryOptimize = @"'
        'registryoptimize.reg'
        'Disable-ScheduledTask'
        'powercfg /setdcvalueindex scheme_current sub_none consolelock 0'
        'disablesetprioritynotifications.reg'
        'reg load "HKLM\Settings" $settingsdat'
        'reg import $regfileappactions'
    )) {
        Assert-BoostLabCondition ($applyBranch.ScriptText.Contains($requiredApplyText)) "Apply branch is missing source text: $requiredApplyText"
    }
    foreach ($requiredDefaultText in @(
        'Control Panel Settings: Default...'
        'Stop-Service -Name ''camsvc'''
        'reg add `"HKLM\SYSTEM\ControlSet001\Services\CDPUserSvc`" /v `"Start`" /t REG_DWORD /d `"2`"'
        '$RegistryDefaults = @"'
        'registrydefaults.reg'
        'Enable-ScheduledTask'
        'powercfg /setdcvalueindex scheme_current sub_none consolelock 1'
        'reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current'
        'Remove-Item "$env:LOCALAPPDATA\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\Settings\settings.dat" -Force -ErrorAction SilentlyContinue | Out-Null'
    )) {
        Assert-BoostLabCondition ($defaultBranch.ScriptText.Contains($requiredDefaultText)) "Default branch is missing source text: $requiredDefaultText"
    }

    $runnerCalls = [System.Collections.Generic.List[object]]::new()
    $scriptRunner = {
        param([string]$ScriptText, [string]$ActionName)
        $runnerCalls.Add([pscustomobject]@{
            ActionName = $ActionName
            ScriptText = $ScriptText
        })
        [pscustomobject]@{ Success = $true; Message = 'Mock source branch executed.'; ExitCode = 0 }
    }.GetNewClosure()
    $applyResult = Invoke-ControlPanelTestBoostLabToolAction `
        -ActionName Apply `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -ScriptRunner $scriptRunner
    Assert-BoostLabCondition ([bool]$applyResult.Success) 'Mocked Apply should succeed.'
    Assert-BoostLabCondition ([string]$applyResult.Status -eq 'Completed') 'Mocked Apply status should be Completed.'
    Assert-BoostLabCondition ([string]$applyResult.Data.SourceMenuBranch -eq 'Control Panel Settings: Optimize (Recommended)') 'Apply source menu branch mismatch.'
    Assert-BoostLabCondition ([bool]$applyResult.Data.ChangesExecuted) 'Apply should report source branch execution.'
    Assert-BoostLabCondition (-not [bool]$applyResult.Data.RestoreAvailable) 'Apply must not expose Restore.'
    Assert-BoostLabCondition ($runnerCalls.Count -eq 1 -and [string]$runnerCalls[0].ActionName -eq 'Apply') 'Apply must call the mock script runner exactly once.'

    $defaultResult = Invoke-ControlPanelTestBoostLabToolAction `
        -ActionName Default `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -ScriptRunner $scriptRunner
    Assert-BoostLabCondition ([bool]$defaultResult.Success) 'Mocked Default should succeed.'
    Assert-BoostLabCondition ([string]$defaultResult.Status -eq 'Completed') 'Mocked Default status should be Completed.'
    Assert-BoostLabCondition ([string]$defaultResult.Data.SourceMenuBranch -eq 'Control Panel Settings: Default') 'Default source menu branch mismatch.'
    Assert-BoostLabCondition ($runnerCalls.Count -eq 2 -and [string]$runnerCalls[1].ActionName -eq 'Default') 'Default must call the mock script runner exactly once.'

    $blockedResult = Invoke-ControlPanelTestBoostLabToolAction -ActionName Apply -Confirmed:$false -ScriptRunner $scriptRunner
    Assert-BoostLabCondition (-not [bool]$blockedResult.Success) 'Unconfirmed Apply must block.'
    Assert-BoostLabCondition ([bool]$blockedResult.Cancelled) 'Unconfirmed Apply should be marked cancelled.'
    Assert-BoostLabCondition ($runnerCalls.Count -eq 2) 'Unconfirmed Apply must not call the runner.'

    $adminResult = Invoke-ControlPanelTestBoostLabToolAction -ActionName Apply -Confirmed:$true -AdministratorChecker { $false } -ScriptRunner $scriptRunner
    Assert-BoostLabCondition (-not [bool]$adminResult.Success) 'Apply without admin must block.'
    Assert-BoostLabCondition ([string]$adminResult.Status -eq 'NeedsAdmin') 'Apply without admin must return NeedsAdmin.'
    Assert-BoostLabCondition ($runnerCalls.Count -eq 2) 'Apply without admin must not call the runner.'

    $sourceMismatchResult = Invoke-ControlPanelTestBoostLabToolAction `
        -ActionName Apply `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -HashReader { param($Path) 'BADHASH' } `
        -ScriptRunner $scriptRunner
    Assert-BoostLabCondition (-not [bool]$sourceMismatchResult.Success) 'Source mismatch must block.'
    Assert-BoostLabCondition ([string]$sourceMismatchResult.Status -eq 'SourceVerificationFailed') 'Source mismatch must report SourceVerificationFailed.'
    Assert-BoostLabCondition ($runnerCalls.Count -eq 2) 'Source mismatch must not call the runner.'

    $hostUiOnlyScript = @'
Clear-Host
Write-Host "Control Panel Settings: Optimize..."
$script:ControlPanelSettingsHostUiShimMarker = 'Ran'
'@
    $hostUiRunnerResult = & $controlPanelModule {
        param($ScriptText)
        Invoke-BoostLabControlPanelSettingsScript -ScriptText $ScriptText -ActionName Apply -SourcePath 'mock-source.ps1'
    } $hostUiOnlyScript
    Assert-BoostLabCondition ([bool]$hostUiRunnerResult.Success) 'Host UI-only source script lines must not crash the Control Panel Settings runner.'
    Assert-BoostLabCondition ([string]$hostUiRunnerResult.FailureKind -eq 'None') 'Host UI-only runner should not report a source operation failure.'
    Assert-BoostLabCondition ([bool]$hostUiRunnerResult.HostUiShimmed) 'Host UI-only runner must report that host UI lines were shimmed.'
    Assert-BoostLabCondition (@($hostUiRunnerResult.RemovedHostUiLines).Count -eq 2) 'Host UI-only runner must remove Clear-Host and Write-Host lines.'
    Assert-BoostLabCondition (@($hostUiRunnerResult.RemovedHostUiLines | Where-Object { [string]$_.Text -eq 'Clear-Host' }).Count -eq 1) 'Host UI shim evidence must include Clear-Host.'
    Assert-BoostLabCondition (@($hostUiRunnerResult.RemovedHostUiLines | Where-Object { [string]$_.Text -like 'Write-Host*' }).Count -eq 1) 'Host UI shim evidence must include Write-Host.'

    $realFailureRunnerResult = & $controlPanelModule {
        Invoke-BoostLabControlPanelSettingsScript -ScriptText 'throw "Real registry failure."' -ActionName Apply -SourcePath 'mock-source.ps1'
    }
    Assert-BoostLabCondition (-not [bool]$realFailureRunnerResult.Success) 'Real source operation failure must still fail.'
    Assert-BoostLabCondition ([string]$realFailureRunnerResult.FailureKind -eq 'SourceOperationFailure') 'Real source operation failure must be classified as SourceOperationFailure.'
    Assert-BoostLabCondition ([string]$realFailureRunnerResult.FailureScope -eq 'SourceOperation') 'Real source operation failure must not be classified as host UI.'

    $failedRunner = {
        param([string]$ScriptText, [string]$ActionName)
        [pscustomobject]@{
            Success = $false
            Message = 'Real registry failure.'
            ExitCode = 1
            RunnerKind = 'MockRunner'
            RunnerCommand = 'mock command'
            RunnerPath = 'mock-source.ps1'
            FailureKind = 'SourceOperationFailure'
            FailureScope = 'SourceOperation'
            HostUiShimmed = $true
            HostUiShimReason = 'mock host UI shim'
            RemovedHostUiLines = @([pscustomobject]@{ SourceBranchLine = 1; Text = 'Clear-Host'; Reason = 'HostUiOnlyConsoleOperation' })
        }
    }
    $failedRunnerResult = Invoke-ControlPanelTestBoostLabToolAction `
        -ActionName Apply `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -ScriptRunner $failedRunner
    Assert-BoostLabCondition (-not [bool]$failedRunnerResult.Success) 'Failed source runner result must fail the action.'
    Assert-BoostLabCondition ([string]$failedRunnerResult.Status -eq 'Failed') 'Failed source runner result must return Failed.'
    Assert-BoostLabCondition ([string]$failedRunnerResult.Data.RunnerFailureKind -eq 'SourceOperationFailure') 'Failed action must preserve runner failure kind.'
    Assert-BoostLabCondition ([string]$failedRunnerResult.Data.RunnerFailureScope -eq 'SourceOperation') 'Failed action must preserve runner failure scope.'
    Assert-BoostLabCondition ([bool]$failedRunnerResult.Data.RuntimeHostUiShimmed) 'Failed action must include host UI shim state in result data.'
    Assert-BoostLabCondition (@($failedRunnerResult.Data.RuntimeHostUiShimEvidence).Count -eq 1) 'Failed action must include host UI shim evidence in result data.'
}
finally {
    Remove-Module -ModuleInfo $controlPanelModule -Force -ErrorAction SilentlyContinue
}

$executionText = Get-Content -LiteralPath $executionPath -Raw
Assert-BoostLabCondition ($executionText.Contains("'control-panel-settings' = @{")) 'Execution registry is missing Control Panel Settings.'
Assert-BoostLabCondition ($executionText.Contains("Windows\control-panel-settings.psm1")) 'Execution registry points to the wrong Control Panel Settings module.'
Assert-BoostLabCondition ($executionText.Contains("Actions = @('Apply', 'Default')")) 'Execution registry must route Apply and Default.'

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    $plan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName Apply -IsDryRun:$false
    Assert-BoostLabCondition ([bool]$plan.NeedsExplicitConfirmation) 'Control Panel Settings Apply must require confirmation.'
    Assert-BoostLabCondition ([bool]$plan.RequiresAdmin) 'Control Panel Settings Apply must require admin.'
    Assert-BoostLabCondition ([bool]$plan.Capabilities.UsesTrustedInstaller) 'Control Panel Settings Apply plan must report TrustedInstaller usage.'
    $planText = (@($plan.PlannedChanges) + @($plan.SideEffects) + @($plan.ConfirmationMessage)) -join ' '
    foreach ($requiredPlanText in @(
        'Verify the Control Panel Settings Ultimate source checksum'
        'TrustedInstaller'
        'scheduled tasks'
        'No Restore action is exposed'
    )) {
        Assert-BoostLabCondition ($planText.Contains($requiredPlanText)) "Control Panel Settings Action Plan missing text: $requiredPlanText"
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$record = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'control-panel-settings' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $record) 'Control Panel Settings parity record is missing.'
Assert-BoostLabCondition ([string]$record.RuntimeStatus -eq 'RuntimeImplemented') 'Control Panel Settings runtime status must be RuntimeImplemented.'
Assert-BoostLabCondition ([string]$record.ImplementationLevel -eq 'ParityImplemented') 'Control Panel Settings must be marked ParityImplemented.'
Assert-BoostLabCondition ([string]$record.UltimateParity -eq 'Yes') 'Control Panel Settings UltimateParity must be Yes.'
Assert-BoostLabCondition (-not [bool]$record.YazanFinalException) 'Control Panel Settings must not use YazanFinalException.'
Assert-BoostLabCondition ([string]$record.FinalProgressStatus -eq 'DoneParity') 'Control Panel Settings final status must be DoneParity.'
Assert-BoostLabCondition ([string]$record.NextParityAction -eq 'DoneParity') 'Control Panel Settings next action must be DoneParity.'
$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ([string]$parityBaseline.CurrentOrderedParityTarget -eq [string]$nextTarget.ToolId) 'Current ordered parity target must match the central first non-final target.'
$deviceManagerRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'device-manager-power-savings-wake' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $deviceManagerRecord) 'Device Manager Power Savings & Wake parity record is missing.'
Assert-BoostLabCondition ([string]$deviceManagerRecord.FinalProgressStatus -eq 'DoneParity') 'Device Manager Power Savings & Wake must remain final accepted after Phase 150.'

$windowsOrder = @($executionOrder.Stages | Where-Object { [string]$_.Name -eq 'Windows' })[0]
$controlOrder = @($windowsOrder.Tools | Where-Object { [string]$_.ToolId -eq 'control-panel-settings' })[0]
$sourceOrderNext = @($windowsOrder.Tools | Where-Object { [int]$_.Order -eq ([int]$controlOrder.Order + 1) })[0]
Assert-BoostLabCondition ([string]$sourceOrderNext.ToolId -eq 'sound') 'Sound must remain the next source-order tool after Control Panel Settings.'

$inventoryAssertion = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot
Assert-BoostLabCondition ([int]$inventoryAssertion.Snapshot.ActiveTools -eq [int]$inventoryAssertion.Baseline.ActiveTools) 'Active tool count mismatch.'
Assert-BoostLabCondition ([int]$inventoryAssertion.Snapshot.ImplementedTools -eq [int]$inventoryAssertion.Baseline.ImplementedTools) 'Implemented tool count mismatch.'
Assert-BoostLabCondition ([int]$inventoryAssertion.Snapshot.DeferredPlaceholders -eq [int]$inventoryAssertion.Baseline.DeferredPlaceholders) 'Deferred placeholder count mismatch.'

$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
Assert-BoostLabCondition ([int]$categoryCounts['ParityImplemented'] -eq [int]$parityBaseline.Counts.UltimateParityImplemented) 'ParityImplemented count mismatch.'
Assert-BoostLabCondition ([int]$categoryCounts['DeferredForParityWork'] -eq [int]$parityBaseline.Counts.DeferredForParityWork) 'DeferredForParityWork count mismatch.'

$artifactText = Get-Content -LiteralPath $artifactPath -Raw
$allowlistText = Get-Content -LiteralPath $productionAllowlistPath -Raw
Assert-BoostLabCondition (-not $artifactText.Contains('control-panel-settings')) 'Control Panel Settings must not add artifact provenance entries.'
Assert-BoostLabCondition (-not $allowlistText.Contains('control-panel-settings')) 'Control Panel Settings must not add production allowlist entries.'

Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $sourceRoot '5 Graphics\NVME Faster Driver.ps1'))) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    Test = 'Control Panel Settings exact Ultimate parity'
    Passed = $true
    SourceHash = $expectedSourceHash
    RuntimeImplementedTools = [int]$inventoryAssertion.Snapshot.ImplementedTools
    DeferredPlaceholders = [int]$inventoryAssertion.Snapshot.DeferredPlaceholders
    SourceOrderNextTool = [string]$sourceOrderNext.ToolId
    CurrentOrderedParityTarget = [string]$parityBaseline.CurrentOrderedParityTarget
    MockedRunnerCalls = $runnerCalls.Count
    Message = 'Control Panel Settings exact parity is implemented through a checksum-verified source-backed runner with test-safe mocks.'
}
