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
        throw 'Unable to determine the Timer Resolution Assistant validator path.'
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

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Advanced\timer-resolution-assistant.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\8 Advanced\6 Timer Resolution Assistant.ps1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration.Stages | ForEach-Object { $_.Tools })
$tool = @($tools | Where-Object { $_.Id -eq 'timer-resolution-assistant' }) | Select-Object -First 1
if ($null -eq $tool) {
    throw 'Timer Resolution Assistant metadata is missing.'
}
if (
    [string]$tool.Stage -ne 'Advanced' -or
    [int]$tool.Order -ne 1 -or
    [string]$tool.Type -ne 'assistant' -or
    [string]$tool.RiskLevel -ne 'high' -or
    (@($tool.Actions) -join ',') -ne 'Analyze,Apply,Default'
) {
    throw 'Timer Resolution Assistant metadata is incorrect.'
}

$capabilities = $tool.Capabilities
foreach ($field in @('RequiresAdmin', 'CanModifyRegistry', 'CanModifyServices', 'CanInstallSoftware', 'CanDeleteFiles', 'SupportsDefault', 'NeedsExplicitConfirmation')) {
    if (-not [bool]$capabilities[$field]) {
        throw "Timer Resolution Assistant capability '$field' must be true."
    }
}
foreach ($field in @('RequiresInternet', 'CanReboot', 'CanDownload', 'CanModifyDrivers', 'CanModifySecurity', 'UsesTrustedInstaller', 'UsesSafeMode', 'SupportsRestore')) {
    if ([bool]$capabilities[$field]) {
        throw "Timer Resolution Assistant capability '$field' must be false."
    }
}

$expectedSourceHash = '883F7CF4E6179383DE02E44B94FFC8DAFD380246751F1B1D81CAB8800B1E8621'
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne $expectedSourceHash) {
    throw 'Timer Resolution Assistant Ultimate source hash changed.'
}

$source = Get-Content -Raw -LiteralPath $sourcePath
foreach ($requiredSourceText in @(
    '1. Timer Resolution: On (Recommended)'
    '2. Timer Resolution: Default'
    'Set-Content -Path "$env:SystemDrive\Windows\SetTimerResolutionService.cs" -Value $csfile -Force'
    'Start-Process -Wait "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"'
    '-out:C:\Windows\SetTimerResolutionService.exe C:\Windows\SetTimerResolutionService.cs'
    'Remove-Item "$env:SystemDrive\Windows\SetTimerResolutionService.cs"'
    'sc.exe delete "Set Timer Resolution Service"'
    'New-Service -Name "Set Timer Resolution Service"'
    'Set-Service -Name "Set Timer Resolution Service" -StartupType Auto'
    'Set-Service -Name "Set Timer Resolution Service" -Status Running'
    'Set-Service -Name "Set Timer Resolution Service" -StartupType Disabled'
    'Set-Service -Name "Set Timer Resolution Service" -Status Stopped'
    'GlobalTimerResolutionRequests'
    'Start-Process taskmgr.exe'
    'ServiceAccount.LocalSystem'
    'NtSetTimerResolution'
    'NtQueryTimerResolution'
)) {
    if (-not $source.Contains($requiredSourceText)) {
        throw "Timer Resolution Assistant source no longer contains: $requiredSourceText"
    }
}
if ($source -match 'https?://|Invoke-WebRequest|Start-BitsTransfer|msiexec|Restart-Computer|bcdedit') {
    throw 'Timer Resolution Assistant source unexpectedly contains download, installer, reboot, or boot configuration behavior.'
}

$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredModuleText in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
    $expectedSourceHash
    'Get-BoostLabTimerCSharpPayload'
    'Set Timer Resolution Service'
    'STR'
    'SetTimerResolutionService.cs'
    'SetTimerResolutionService.exe'
    'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
    'GlobalTimerResolutionRequests'
    'taskmgr.exe'
    'SupportsRestore = $false'
)) {
    if (-not $moduleSource.Contains($requiredModuleText)) {
        throw "Timer Resolution Assistant module is missing: $requiredModuleText"
    }
}
foreach ($forbiddenModuleText in @(
    'ToolModule.Placeholder.ps1'
    'SupportsRestore = $true'
    'UsesTrustedInstaller = $true'
    'UsesSafeMode = $true'
    'Restart-Computer'
    'Stop-Computer'
    'bcdedit'
    'Invoke-WebRequest'
    'Start-BitsTransfer'
    'msiexec'
)) {
    if ($moduleSource.Contains($forbiddenModuleText)) {
        throw "Timer Resolution Assistant module contains stale or unrelated behavior: $forbiddenModuleText"
    }
}

$parityRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'timer-resolution-assistant' }) | Select-Object -First 1
if ($null -eq $parityRecord) {
    throw 'Timer Resolution Assistant parity baseline record is missing.'
}
if (
    [string]$parityRecord.RuntimeStatus -ne 'RuntimeImplemented' -or
    [string]$parityRecord.ImplementationLevel -ne 'ParityImplemented' -or
    [string]$parityRecord.UltimateParity -ne 'Yes' -or
    [bool]$parityRecord.YazanFinalException
) {
    throw 'Timer Resolution Assistant parity baseline was not finalized as exact Ultimate parity.'
}

$nextOrderedTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
if ($null -eq $nextOrderedTarget) {
    throw 'Ordered parity cursor helper did not return a result after Timer Resolution Assistant.'
}
$defenderRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'defender-optimize-assistant' }) | Select-Object -First 1
if ($null -eq $defenderRecord) {
    throw 'Defender Optimize Assistant parity record is missing.'
}
$isOrderedParityComplete = ($parityBaseline.ContainsKey('OrderedParityComplete') -and [bool]$parityBaseline.OrderedParityComplete)
if ($isOrderedParityComplete) {
    if (-not (Test-BoostLabParityRecordFinal -Record $defenderRecord) -or $null -ne $parityBaseline.CurrentOrderedParityTarget -or -not [bool]$nextOrderedTarget.IsOrderedParityComplete) {
        throw 'Timer Resolution Assistant acceptance did not reach the final Defender Optimize Assistant completion state.'
    }
}
else {
    if ([string]$nextOrderedTarget.ToolId -ne 'defender-optimize-assistant') {
        throw 'Timer Resolution Assistant acceptance did not advance the ordered cursor to Defender Optimize Assistant.'
    }
    if ([string]$parityBaseline.CurrentOrderedParityTarget -ne [string]$nextOrderedTarget.ToolId) {
        throw 'Central ordered parity cursor does not match the derived first non-final target.'
    }
}

$module = Import-Module -Name $modulePath -Force -PassThru -Prefix 'TimerTest' -Scope Local -DisableNameChecking -ErrorAction Stop
try {
    $info = & (Get-Command -Name 'Get-TimerTestBoostLabToolInfo' -Module $module.Name -ErrorAction Stop)
    if (
        [string]$info.Id -ne 'timer-resolution-assistant' -or
        (@($info.Actions) -join ',') -ne 'Analyze,Apply,Default' -or
        (@($info.ImplementedActions) -join ',') -ne 'Analyze,Apply,Default' -or
        [string]$info.ActionLabels.Apply -ne 'Timer Resolution: On (Recommended)' -or
        [string]$info.ActionLabels.Default -ne 'Timer Resolution: Default'
    ) {
        throw 'Timer Resolution Assistant exported metadata, implemented actions, or labels are incorrect.'
    }

    $compatibility = & (Get-Command -Name 'Test-TimerTestBoostLabToolCompatibility' -Module $module.Name -ErrorAction Stop) `
        -OperatingSystem 'Windows_NT' `
        -SystemDrive 'C:' `
        -SystemRoot 'C:\Windows' `
        -PathChecker { param($Path) return ($Path -in @('C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe', 'C:\Windows\System32\cmd.exe')) } `
        -CommandResolver { param($CommandName) return [pscustomobject]@{ Name = $CommandName } }
    if (-not [bool]$compatibility.Supported) {
        throw "Timer Resolution Assistant mocked compatibility did not pass: $($compatibility.Reason)"
    }

    $analysisResult = & (Get-Command -Name 'Invoke-TimerTestBoostLabToolAction' -Module $module.Name -ErrorAction Stop) -ActionName 'Analyze'
    $analysis = $analysisResult.Data
    if (
        -not $analysisResult.Success -or
        -not [bool]$analysis.SourceHashMatches -or
        [int]$analysis.CSharpPayloadLength -lt 5000 -or
        -not [bool]$analysis.CSharpContainsNtSetTimerResolution -or
        -not [bool]$analysis.CSharpContainsNtQueryTimerResolution -or
        [string]$analysis.ServiceName -ne 'Set Timer Resolution Service' -or
        [string]$analysis.InternalServiceName -ne 'STR' -or
        [string]$analysis.CompilerPath -ne 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe' -or
        [string]$analysis.RegistryValueName -ne 'GlobalTimerResolutionRequests' -or
        @($analysis.Downloads).Count -ne 0 -or
        @($analysis.ExternalArtifacts).Count -ne 0
    ) {
        throw 'Timer Resolution Assistant Analyze did not report the expected read-only source workflow.'
    }

    foreach ($actionName in @('Apply', 'Default')) {
        $cancelled = & (Get-Command -Name 'Invoke-TimerTestBoostLabToolAction' -Module $module.Name -ErrorAction Stop) -ActionName $actionName -Confirmed:$false
        if (-not $cancelled.Cancelled -or $cancelled.Message -ne 'Cancelled by user') {
            throw "Timer Resolution Assistant $actionName confirmation handling is incorrect."
        }
    }

    foreach ($case in @(
        [pscustomobject]@{ Action = 'Apply'; Label = 'Timer Resolution: On (Recommended)'; ExpectedSteps = @('WriteCSharpSource', 'CompileServiceExecutable', 'RemoveCSharpSource', 'GetExistingService', 'DeleteExistingServiceIfPresent', 'NewService', 'SetServiceStartupAuto', 'SetServiceRunning', 'EnableGlobalTimerResolutionRequests', 'OpenTaskManager') }
        [pscustomobject]@{ Action = 'Default'; Label = 'Timer Resolution: Default'; ExpectedSteps = @('SetServiceStartupDisabled', 'SetServiceStopped', 'DeleteService', 'RemoveServiceExecutable', 'DisableGlobalTimerResolutionRequests', 'OpenTaskManager') }
    )) {
        $fileWrites = @{}
        $fileRemovals = [System.Collections.Generic.List[string]]::new()
        $processCalls = [System.Collections.Generic.List[object]]::new()
        $serviceCalls = [System.Collections.Generic.List[object]]::new()
        $commandCalls = [System.Collections.Generic.List[string]]::new()
        $sleepCalls = [System.Collections.Generic.List[int]]::new()

        $fileWriter = {
            param($Path, $Content)
            $fileWrites[$Path] = $Content
            [pscustomobject]@{ Success = $true; Output = '' }
        }.GetNewClosure()
        $fileRemover = {
            param($Path)
            $fileRemovals.Add($Path) | Out-Null
            [pscustomobject]@{ Success = $true; Output = '' }
        }.GetNewClosure()
        $processInvoker = {
            param($FilePath, $ArgumentList, $Wait, $WindowStyle)
            $processCalls.Add([pscustomobject]@{
                FilePath = $FilePath
                ArgumentList = $ArgumentList
                Wait = [bool]$Wait
                WindowStyle = $WindowStyle
            }) | Out-Null
            [pscustomobject]@{ Success = $true; Output = '' }
        }.GetNewClosure()
        $serviceInvoker = {
            param($Operation, $ServiceName, $BinaryPathName)
            $serviceCalls.Add([pscustomobject]@{
                Operation = $Operation
                ServiceName = $ServiceName
                BinaryPathName = $BinaryPathName
            }) | Out-Null
            [pscustomobject]@{ Success = $true; Exists = ($Operation -eq 'Get'); Output = '' }
        }.GetNewClosure()
        $commandInvoker = {
            param($CommandText)
            $commandCalls.Add($CommandText) | Out-Null
            [pscustomobject]@{ Success = $true; Output = '' }
        }.GetNewClosure()
        $sleepInvoker = {
            param($Seconds)
            $sleepCalls.Add([int]$Seconds) | Out-Null
            [pscustomobject]@{ Success = $true; Output = '' }
        }.GetNewClosure()

        $result = & $module {
            param($ActionName, $FileWriter, $FileRemover, $ProcessInvoker, $ServiceInvoker, $CommandInvoker, $SleepInvoker)
            Invoke-BoostLabTimerResolutionAction `
                -ActionName $ActionName `
                -AdministratorChecker { return $true } `
                -FileWriter $FileWriter `
                -FileRemover $FileRemover `
                -ProcessInvoker $ProcessInvoker `
                -ServiceInvoker $ServiceInvoker `
                -CommandInvoker $CommandInvoker `
                -SleepInvoker $SleepInvoker `
                -SystemDrive 'C:'
        } $case.Action $fileWriter $fileRemover $processInvoker $serviceInvoker $commandInvoker $sleepInvoker

        if (
            -not $result.Success -or
            [string]$result.Data.SourceBranchLabel -ne [string]$case.Label -or
            @($result.Data.Errors).Count -ne 0
        ) {
            throw "Mocked Timer Resolution Assistant $($case.Action) workflow did not return the expected structured result."
        }
        $actualSteps = @($result.Data.Operations | ForEach-Object { [string]$_.Step })
        if (($actualSteps -join '|') -ne (@($case.ExpectedSteps) -join '|')) {
            throw "Mocked Timer Resolution Assistant $($case.Action) operation order is incorrect: $($actualSteps -join '|')"
        }

        if ($case.Action -eq 'Apply') {
            if (-not $fileWrites.ContainsKey('C:\Windows\SetTimerResolutionService.cs')) {
                throw 'Mocked Timer Resolution Apply did not write the source-defined C# path.'
            }
            $payload = [string]$fileWrites['C:\Windows\SetTimerResolutionService.cs']
            foreach ($requiredPayloadText in @('NtSetTimerResolution', 'NtQueryTimerResolution', 'ServiceAccount.LocalSystem', 'ServiceName = "STR"', 'Set Timer Resolution Service')) {
                if (-not $payload.Contains($requiredPayloadText)) {
                    throw "Generated Timer Resolution C# payload is missing: $requiredPayloadText"
                }
            }
            if (@($fileRemovals | Where-Object { $_ -eq 'C:\Windows\SetTimerResolutionService.cs' }).Count -ne 1) {
                throw 'Mocked Timer Resolution Apply did not remove the generated source file.'
            }
            if (@($processCalls | Where-Object { $_.FilePath -eq 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe' -and $_.ArgumentList -eq '-out:C:\Windows\SetTimerResolutionService.exe C:\Windows\SetTimerResolutionService.cs' -and $_.Wait -and $_.WindowStyle -eq 'Hidden' }).Count -ne 1) {
                throw 'Mocked Timer Resolution Apply did not invoke the exact source compiler command.'
            }
            if (@($serviceCalls | Where-Object { $_.Operation -eq 'New' -and $_.ServiceName -eq 'Set Timer Resolution Service' -and $_.BinaryPathName -eq 'C:\Windows\SetTimerResolutionService.exe' }).Count -ne 1) {
                throw 'Mocked Timer Resolution Apply did not create the exact source service.'
            }
            if (@($commandCalls | Where-Object { $_ -eq 'sc.exe delete "Set Timer Resolution Service"' }).Count -ne 1 -or $sleepCalls.Count -ne 1 -or [int]$sleepCalls[0] -ne 2) {
                throw 'Mocked Timer Resolution Apply did not preserve existing-service deletion and pause behavior.'
            }
            if (@($commandCalls | Where-Object { $_ -match 'reg add "HKLM\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\kernel" /v "GlobalTimerResolutionRequests" /t REG_DWORD /d "1" /f' }).Count -ne 1) {
                throw 'Mocked Timer Resolution Apply did not set the source-defined registry value.'
            }
        }
        else {
            foreach ($expectedOperation in @('SetStartupDisabled', 'SetStopped')) {
                if (@($serviceCalls | Where-Object { $_.Operation -eq $expectedOperation -and $_.ServiceName -eq 'Set Timer Resolution Service' }).Count -ne 1) {
                    throw "Mocked Timer Resolution Default did not call service operation: $expectedOperation"
                }
            }
            if (@($fileRemovals | Where-Object { $_ -eq 'C:\Windows\SetTimerResolutionService.exe' }).Count -ne 1) {
                throw 'Mocked Timer Resolution Default did not remove the source-defined executable.'
            }
            if (@($commandCalls | Where-Object { $_ -eq 'sc.exe delete "Set Timer Resolution Service"' }).Count -ne 1) {
                throw 'Mocked Timer Resolution Default did not issue the source-defined service delete command.'
            }
            if (@($commandCalls | Where-Object { $_ -match 'reg delete "HKLM\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\kernel" /v "GlobalTimerResolutionRequests" /f' }).Count -ne 1) {
                throw 'Mocked Timer Resolution Default did not delete the source-defined registry value.'
            }
        }

        if (@($processCalls | Where-Object { $_.FilePath -eq 'taskmgr.exe' }).Count -ne 1) {
            throw "Mocked Timer Resolution $($case.Action) did not preserve the source-defined Task Manager launch."
        }
    }
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    $analyzePlan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Analyze' -IsDryRun $false
    if ($analyzePlan.Summary -notmatch 'Timer Resolution' -or (@($analyzePlan.SideEffects) -join ' ') -notmatch 'No system changes') {
        throw 'Timer Resolution Assistant Analyze action plan is incomplete.'
    }

    foreach ($actionName in @('Apply', 'Default')) {
        $plan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName $actionName -IsDryRun $false
        if (
            -not $plan.NeedsExplicitConfirmation -or
            -not $plan.RequiresAdmin -or
            $plan.CanReboot -or
            $plan.ConfirmationMessage -notmatch 'Set Timer Resolution Service' -or
            $plan.ConfirmationMessage -notmatch 'GlobalTimerResolutionRequests' -or
            (@($plan.SideEffects) -join ' ') -notmatch 'Task Manager' -or
            (@($plan.PlannedChanges) -join ' ') -notmatch 'C:\\Windows'
        ) {
            throw "Timer Resolution Assistant $actionName action plan does not expose the required source workflow risk."
        }
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredText in @(
    '''timer-resolution-assistant'' = @{'
    '''Advanced\timer-resolution-assistant.psm1'''
    'Actions = @(''Analyze'', ''Apply'', ''Default'')'
)) {
    if (-not $executionSource.Contains($requiredText)) {
        throw "Timer Resolution Assistant runtime mapping is missing: $requiredText"
    }
}

$allModules = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'modules') -Recurse -File -Filter '*.psm1' |
        Where-Object { $_.Directory.Parent.FullName -eq (Join-Path $ProjectRoot 'modules') }
)
$implementedCount = @(
    $allModules | Where-Object {
        (Get-Content -Raw -LiteralPath $_.FullName).Contains('$script:BoostLabImplementedActions')
    }
).Count
$placeholderCount = @(
    $allModules | Where-Object {
        (Get-Content -Raw -LiteralPath $_.FullName).Contains('ToolModule.Placeholder.ps1')
    }
).Count
if ($implementedCount -ne $inventoryBaseline.ImplementedTools -or $placeholderCount -ne $inventoryBaseline.DeferredPlaceholders) {
    throw "Unexpected module counts: $implementedCount implemented, $placeholderCount placeholders."
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
    Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
    ForEach-Object {
        '{0}|{1}' -f `
            $_.FullName.Substring($root.Length + 1).Replace('\', '/'), `
            (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    }
$sha256 = [System.Security.Cryptography.SHA256]::Create()
try {
    $sourceManifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n")))
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}
if (
    @($sourceLines).Count -ne 49 -or
    $sourceManifestHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477'
) {
    throw 'source-ultimate content or paths changed.'
}

[pscustomobject]@{
    Success = $true
    ToolId = 'timer-resolution-assistant'
    ImplementedActions = @('Analyze', 'Apply', 'Default')
    MockedApplyPassed = $true
    MockedDefaultPassed = $true
    ImplementedModuleCount = $implementedCount
    PlaceholderModuleCount = $placeholderCount
    CurrentOrderedParityTarget = $parityBaseline.CurrentOrderedParityTarget
    SourceUltimateUnchanged = $true
    DeletedToolsRemainDeleted = $true
    Message = 'Timer Resolution Assistant exact source workflow was validated with mocked file, compiler, service, registry, process, and cleanup operations only.'
    Timestamp = Get-Date
}
