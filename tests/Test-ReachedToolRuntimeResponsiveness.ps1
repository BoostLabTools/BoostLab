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
        throw 'Unable to determine the runtime responsiveness validator path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')

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

function Invoke-BoostLabAsyncAnalyzeSimulation {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$ToolMetadata
    )

    $tempProgramData = Join-Path ([System.IO.Path]::GetTempPath()) ('BoostLabAsyncAnalyze_' + [guid]::NewGuid().ToString('N'))
    $powerShell = $null
    $runspace = $null
    New-Item -ItemType Directory -Path $tempProgramData -Force -ErrorAction Stop | Out-Null

    try {
        $workerScript = {
            param(
                [Parameter(Mandatory)]
                [string]$ProjectRoot,

                [Parameter(Mandatory)]
                [string]$ProgramDataRoot,

                [Parameter(Mandatory)]
                [System.Collections.IDictionary]$ToolMetadata,

                [Parameter(Mandatory)]
                [string]$ActionName,

                [AllowNull()]
                [hashtable]$ActionOptions = @{}
            )

            Set-StrictMode -Version Latest
            $ErrorActionPreference = 'Stop'
            $env:ProgramData = $ProgramDataRoot

            if ($null -eq $ActionOptions) {
                $ActionOptions = @{}
            }
            else {
                $normalizedActionOptions = @{}
                foreach ($optionName in @($ActionOptions.Keys)) {
                    $optionValue = $ActionOptions[$optionName]
                    if ($null -eq $optionValue) {
                        $normalizedActionOptions[[string]$optionName] = $null
                    }
                    elseif ($optionValue -is [array]) {
                        $normalizedActionOptions[[string]$optionName] = @($optionValue)
                    }
                    else {
                        $normalizedActionOptions[[string]$optionName] = $optionValue
                    }
                }
                $ActionOptions = $normalizedActionOptions
            }

            foreach ($relativeModulePath in @(
                'core\Environment.psm1'
                'core\Logging.psm1'
                'core\ActionPlan.psm1'
                'core\Safety.psm1'
                'core\State.psm1'
                'core\Verification.psm1'
                'core\Execution.psm1'
            )) {
                $modulePath = Join-Path $ProjectRoot $relativeModulePath
                if (Test-Path -LiteralPath $modulePath -PathType Leaf) {
                    Import-Module -Name $modulePath -Force -ErrorAction Stop
                }
            }

            function global:Test-BoostLabAdministrator {
                return $true
            }

            if (Get-Command -Name 'Initialize-BoostLabLogging' -ErrorAction SilentlyContinue) {
                Initialize-BoostLabLogging | Out-Null
            }
            if (Get-Command -Name 'Initialize-BoostLabState' -ErrorAction SilentlyContinue) {
                Initialize-BoostLabState | Out-Null
            }

            Invoke-BoostLabToolAction `
                -ToolMetadata $ToolMetadata `
                -ActionName $ActionName `
                -ActionOptions $ActionOptions `
                -RiskConfirmed
        }

        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.ApartmentState = [System.Threading.ApartmentState]::STA
        $runspace.ThreadOptions = [System.Management.Automation.Runspaces.PSThreadOptions]::ReuseThread
        $runspace.Open()

        $powerShell = [powershell]::Create()
        $powerShell.Runspace = $runspace
        [void]$powerShell.AddScript($workerScript)
        [void]$powerShell.AddArgument($ProjectRoot)
        [void]$powerShell.AddArgument($tempProgramData)
        [void]$powerShell.AddArgument($ToolMetadata)
        [void]$powerShell.AddArgument('Analyze')
        [void]$powerShell.AddArgument(@{})

        $asyncResult = $powerShell.BeginInvoke()
        try {
            $output = @($powerShell.EndInvoke($asyncResult))
        }
        catch {
            $messageParts = [System.Collections.Generic.List[string]]::new()
            $messageParts.Add($_.Exception.Message)
            $innerException = $_.Exception.InnerException
            while ($null -ne $innerException) {
                $messageParts.Add($innerException.Message)
                $innerException = $innerException.InnerException
            }
            throw ('Async Analyze EndInvoke failed for {0}: {1}' -f [string]$ToolMetadata['Id'], ($messageParts -join ' | '))
        }

        return [pscustomobject]@{
            Result       = if ($output.Count -gt 0) { $output[$output.Count - 1] } else { $null }
            OutputCount  = $output.Count
            ErrorCount   = $powerShell.Streams.Error.Count
            StateCreated = Test-Path -LiteralPath (Join-Path $tempProgramData 'BoostLab\State\runtime-state.json') -PathType Leaf
        }
    }
    finally {
        if ($null -ne $powerShell) {
            $powerShell.Dispose()
        }
        if ($null -ne $runspace) {
            $runspace.Dispose()
        }
        Remove-Item -LiteralPath $tempProgramData -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$driverInstallLatestModulePath = Join-Path $ProjectRoot 'modules\Graphics\driver-install-latest.psm1'
$installersModulePath = Join-Path $ProjectRoot 'modules\Installers\installers.psm1'
$driverCleanModulePath = Join-Path $ProjectRoot 'modules\Graphics\driver-clean.psm1'
$edgeSettingsModulePath = Join-Path $ProjectRoot 'modules\Setup\edge-settings.psm1'
$bitLockerModulePath = Join-Path $ProjectRoot 'modules\Setup\bitlocker.psm1'
$directXModulePath = Join-Path $ProjectRoot 'modules\Graphics\directx.psm1'
$visualCppModulePath = Join-Path $ProjectRoot 'modules\Graphics\visual-cpp.psm1'

foreach ($path in @(
    $uiPath
    $configPath
    $driverInstallLatestModulePath
    $installersModulePath
    $driverCleanModulePath
    $edgeSettingsModulePath
    $bitLockerModulePath
    $directXModulePath
    $visualCppModulePath
)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required file missing: $path"
}

$uiText = Get-Content -LiteralPath $uiPath -Raw
$config = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })
$inventoryAssertion = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
$inventoryBaseline = $inventoryAssertion.Baseline
$inventorySnapshot = $inventoryAssertion.Snapshot

Assert-BoostLabCondition ([int]$inventorySnapshot.ActiveTools -eq [int]$inventoryBaseline.ActiveTools) 'Active tool baseline changed unexpectedly.'
Assert-BoostLabCondition ([int]$inventorySnapshot.ImplementedTools -eq [int]$inventoryBaseline.ImplementedTools) 'Implemented tool baseline changed unexpectedly.'
Assert-BoostLabCondition ([int]$inventorySnapshot.DeferredPlaceholders -eq [int]$inventoryBaseline.DeferredPlaceholders) 'Deferred placeholder baseline changed unexpectedly.'

foreach ($needle in @(
    'function Invoke-BoostLabToolCardActionAsync'
    'function Test-BoostLabToolUsesAsyncUiDispatch'
    '$script:BoostLabAsyncActionState = @{'
    '$asyncActionState = $script:BoostLabAsyncActionState'
    "[bool]`$asyncActionState['InProgress']"
    "`$asyncActionState['InProgress'] = `$true"
    "`$asyncActionState['InProgress'] = `$false"
    '[runspacefactory]::CreateRunspace()'
    '$runspace.ApartmentState = [System.Threading.ApartmentState]::STA'
    '$powerShell.BeginInvoke()'
    '$powerShell.EndInvoke($asyncResult)'
    '[System.Windows.Threading.DispatcherTimer]::new()'
    '$getDiagnosticsCommand = ${function:Get-BoostLabAsyncStreamDiagnostics}'
    '$getExceptionMessageCommand = ${function:Get-BoostLabAsyncExceptionDiagnosticMessage}'
    '$newFailureResultCommand = ${function:New-BoostLabAsyncRuntimeFailureResult}'
    '$addDiagnosticsCommand = ${function:Add-BoostLabAsyncDiagnosticsToResult}'
    '$completeActionCommand = ${function:Complete-BoostLabToolCardAction}'
    '& $getDiagnosticsCommand -PowerShell $powerShell -Output $output'
    '& $newFailureResultCommand `'
    '& $addDiagnosticsCommand -Result $result -Diagnostics $diagnostics'
    '& $completeActionCommand -Context $Context -Result $result'
    'Tool async completion failed'
    'Inner exception:'
    'Script stack:'
    'Async diagnostics collection failed:'
    'Initialize-BoostLabState | Out-Null'
    'Complete-BoostLabToolCardAction -Context $Context -Result $result'
    'Show-BoostLabActionPlanConfirmation -ActionPlan $actionPlan'
    'Invoke-BoostLabToolAction `'
    '-RiskConfirmed'
    '$script:BoostLabActionInProgress'
    '$Context.ActionButton.IsEnabled = $false'
    '$Context.ActionButton.IsEnabled = $true'
    'Get-BoostLabAsyncStreamDiagnostics'
    '$PowerShell.Streams.Progress'
    '$PowerShell.Streams.Error'
    'New-BoostLabUiActionBusyResult'
    'Another BoostLab action is already running'
)) {
    Assert-BoostLabTextContains -Text $uiText -Needle $needle -Description 'UI runtime responsiveness dispatcher'
}

$timerMatch = [regex]::Match(
    $uiText,
    '\$timer\.Add_Tick\(\(\{(?<Body>.*?)\}\)\.GetNewClosure\(\)\)',
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)
Assert-BoostLabCondition $timerMatch.Success 'Could not locate async DispatcherTimer completion body.'
$timerBody = $timerMatch.Groups['Body'].Value
foreach ($bareHelperCall in @(
    'Get-BoostLabAsyncStreamDiagnostics -PowerShell',
    'New-BoostLabAsyncRuntimeFailureResult `',
    'Complete-BoostLabToolCardAction -Context'
)) {
    Assert-BoostLabCondition (-not $timerBody.Contains($bareHelperCall)) "Async timer completion must use captured helper scriptblocks, not bare helper command calls: $bareHelperCall"
}
Assert-BoostLabTextContains -Text $timerBody -Needle "`$asyncActionState['InProgress'] = `$false" -Description 'Async timer busy-state cleanup'
Assert-BoostLabTextContains -Text $timerBody -Needle '& $completeActionCommand -Context $Context -Result $result' -Description 'Async timer visible result completion'
Assert-BoostLabTextContains -Text $timerBody -Needle 'Tool async completion failed' -Description 'Async timer structured failure result path'
Assert-BoostLabTextContains -Text $uiText -Needle 'function Get-BoostLabAsyncExceptionDiagnosticMessage' -Description 'Async EndInvoke diagnostic helper'
Assert-BoostLabTextContains -Text $uiText -Needle 'if ($null -eq $ActionOptions) {' -Description 'Async worker nullable action option normalization'
Assert-BoostLabTextContains -Text $uiText -Needle 'Initialize-BoostLabState | Out-Null' -Description 'Async worker isolated state initialization'

$asyncScopeMatch = [regex]::Match(
    $uiText,
    'function Test-BoostLabToolUsesAsyncUiDispatch(?<Body>.*?)^}',
    [System.Text.RegularExpressions.RegexOptions]::Singleline -bor [System.Text.RegularExpressions.RegexOptions]::Multiline
)
Assert-BoostLabCondition $asyncScopeMatch.Success 'Could not locate Test-BoostLabToolUsesAsyncUiDispatch body.'
$asyncScopeText = $asyncScopeMatch.Groups['Body'].Value

$reachedToolIds = @(
    'bios-information'
    'bios-settings'
    'reinstall'
    'unattended'
    'updates-drivers-block'
    'to-bios'
    'bitlocker'
    'memory-compression'
    'date-language-region-time'
    'startup-apps-settings'
    'startup-apps-task-manager'
    'background-apps'
    'edge-settings'
    'store-settings'
    'updates-pause'
    'installers'
    'driver-clean'
    'driver-install-debloat-settings'
    'driver-install-latest'
    'nvidia-settings'
    'hdcp'
    'p0-state'
    'msi-mode'
    'directx'
    'visual-cpp'
)
foreach ($toolId in $reachedToolIds) {
    Assert-BoostLabTextContains -Text $asyncScopeText -Needle "'$toolId'" -Description 'Async reached-tool scope'
    Assert-BoostLabCondition (@($allTools | Where-Object { [string]$_.Id -eq $toolId }).Count -eq 1) "Reached tool missing from Stages.psd1: $toolId"
}

foreach ($outOfScopeToolId in @(
    'graphics-configuration-center'
    'theme-black'
    'power-plan'
    'smt-ht-assistant'
)) {
    Assert-BoostLabCondition (-not $asyncScopeText.Contains("'$outOfScopeToolId'")) "Unreached tool must not be explicitly opted into the Phase 124 async scope: $outOfScopeToolId"
}

$driverInstallLatestTool = @($allTools | Where-Object { [string]$_.Id -eq 'driver-install-latest' })[0]
$installersTool = @($allTools | Where-Object { [string]$_.Id -eq 'installers' })[0]
Assert-BoostLabCondition ([string]$driverInstallLatestTool.SelectionMode -eq 'SingleSelect') 'Driver Install Latest must keep single-select branch UI.'
Assert-BoostLabCondition ([string]$installersTool.SelectionMode -eq 'SingleSelect') 'Installers must keep single-app selection UI.'

$directXTool = @($allTools | Where-Object { [string]$_.Id -eq 'directx' })[0]
$visualCppTool = @($allTools | Where-Object { [string]$_.Id -eq 'visual-cpp' })[0]
foreach ($asyncAnalyzeTool in @($installersTool, $driverInstallLatestTool, $directXTool, $visualCppTool)) {
    $asyncAnalyze = Invoke-BoostLabAsyncAnalyzeSimulation -ProjectRoot $ProjectRoot -ToolMetadata $asyncAnalyzeTool
    $toolId = [string]$asyncAnalyzeTool.Id

    Assert-BoostLabCondition ($asyncAnalyze.OutputCount -gt 0) "Async Analyze produced no result for $toolId."
    Assert-BoostLabCondition ($asyncAnalyze.ErrorCount -eq 0) "Async Analyze emitted unexpected error stream records for $toolId."
    Assert-BoostLabCondition ($null -ne $asyncAnalyze.Result) "Async Analyze returned null result for $toolId."
    Assert-BoostLabCondition ([bool]$asyncAnalyze.Result.Success) "Async Analyze should succeed for $toolId."
    Assert-BoostLabCondition ([string]$asyncAnalyze.Result.Action -eq 'Analyze') "Async Analyze returned wrong action for $toolId."
    Assert-BoostLabCondition ([string]$asyncAnalyze.Result.Status -eq 'Analyzed') "Async Analyze returned wrong status for $toolId."
    Assert-BoostLabCondition ($null -ne $asyncAnalyze.Result.PSObject.Properties['ActionPlan']) "Async Analyze did not attach ActionPlan for $toolId."
    Assert-BoostLabCondition ([string]$asyncAnalyze.Result.ActionPlan.Action -eq 'Analyze') "Async Analyze ActionPlan action mismatch for $toolId."
    Assert-BoostLabCondition ($asyncAnalyze.StateCreated) "Async Analyze did not initialize isolated temp state for $toolId."

    $data = $asyncAnalyze.Result.Data
    Assert-BoostLabCondition ($null -ne $data) "Async Analyze did not include structured data for $toolId."
    if ($null -ne $data.PSObject.Properties['NoMutationOccurred']) {
        Assert-BoostLabCondition ([bool]$data.NoMutationOccurred) "Async Analyze must report no mutation for $toolId."
    }
}

$driverInstallLatestText = Get-Content -LiteralPath $driverInstallLatestModulePath -Raw
foreach ($needle in @(
    'SourceEquivalentThreeBranchRuntime'
    'BranchSelectedSourceEquivalentApply'
    'QueryNvidiaLatestDriver'
    'DownloadResolvedNvidiaDriver'
    'QueryAmdDriverInstaller'
    'DownloadResolvedAmdDriver'
    'Intel Windows 11 graphics driver search page'
)) {
    Assert-BoostLabTextContains -Text $driverInstallLatestText -Needle $needle -Description 'Driver Install Latest source-equivalent behavior'
}

$installersText = Get-Content -LiteralPath $installersModulePath -Raw
Assert-BoostLabTextContains -Text $installersText -Needle 'SelectedAppIds' -Description 'Installers legacy selected-app option compatibility'
Assert-BoostLabTextContains -Text $installersText -Needle "QueueOrder                   = 'Not applicable; exactly one retained app runs per Apply.'" -Description 'Installers single-app execution behavior'

$driverCleanText = Get-Content -LiteralPath $driverCleanModulePath -Raw
Assert-BoostLabTextContains -Text $driverCleanText -Needle 'SourceEquivalentDriverClean' -Description 'Driver Clean exact workflow mode'
Assert-BoostLabTextContains -Text $driverCleanText -Needle 'RunOnce' -Description 'Driver Clean RunOnce mapping'

$edgeSettingsText = Get-Content -LiteralPath $edgeSettingsModulePath -Raw
Assert-BoostLabTextContains -Text $edgeSettingsText -Needle 'SourceEquivalent' -Description 'Edge Settings source-equivalent behavior'

$bitLockerText = Get-Content -LiteralPath $bitLockerModulePath -Raw
Assert-BoostLabTextContains -Text $bitLockerText -Needle 'Disable-BitLocker' -Description 'BitLocker source-equivalent Apply behavior'
Assert-BoostLabTextContains -Text $bitLockerText -Needle 'manage-bde' -Description 'BitLocker source-equivalent status behavior'

$directXText = Get-Content -LiteralPath $directXModulePath -Raw
Assert-BoostLabTextContains -Text $directXText -Needle 'SourceEquivalentControlledRuntime' -Description 'DirectX source-equivalent runtime behavior'
Assert-BoostLabTextContains -Text $directXText -Needle 'SourceEquivalentDirectXInstall' -Description 'DirectX controlled install action'

$visualCppText = Get-Content -LiteralPath $visualCppModulePath -Raw
Assert-BoostLabTextContains -Text $visualCppText -Needle 'SourceEquivalentControlledRuntime' -Description 'Visual C++ source-equivalent runtime behavior'
Assert-BoostLabTextContains -Text $visualCppText -Needle 'SourceEquivalentVisualCppInstall' -Description 'Visual C++ controlled install action'
Assert-BoostLabTextContains -Text $visualCppText -Needle 'OperationExecutor' -Description 'Visual C++ test-safe executor seam'

foreach ($protectedPath in @(
    'source-ultimate'
    'source-ultimate\_intake-promoted'
    'intake'
)) {
    $fullPath = Join-Path $ProjectRoot $protectedPath
    if (Test-Path -LiteralPath $fullPath) {
        $recent = @(Get-ChildItem -LiteralPath $fullPath -Recurse -File | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-6) })
        Assert-BoostLabCondition ($recent.Count -eq 0) "Protected path has recent modifications during responsiveness hotfix: $protectedPath"
    }
}

foreach ($deletedPath in @(
    'source-ultimate\6 Windows\17 Loudness EQ.ps1'
    'source-ultimate\6 Windows\30 NVME Faster Driver.ps1'
)) {
    Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $deletedPath))) "Deleted source was reintroduced: $deletedPath"
}

[pscustomobject]@{
    TestName                    = 'ReachedToolRuntimeResponsiveness'
    ReachedAsyncToolCount       = $reachedToolIds.Count
    AsyncDispatch               = 'STA runspace + DispatcherTimer'
    AsyncCompletionContract     = 'Captured helper scriptblocks + shared state cleanup'
    DuplicateClickPolicy        = 'Global single action in progress'
    DriverInstallLatestMode     = 'SourceEquivalentThreeBranchRuntime'
    InstallersSingleAppModel    = $true
    RealHostMutationDuringTest  = $false
    SourceUltimateUnchanged     = $true
    DeletedToolsRemainDeleted   = $true
    Message                     = 'Reached tools through Visual C++ use the non-blocking WPF dispatch path; validators are static/mock-safe.'
}
