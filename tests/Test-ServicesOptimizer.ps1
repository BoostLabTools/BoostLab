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
        throw 'Unable to determine the Services Optimizer test script path.'
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
$modulePath = Join-Path $ProjectRoot 'modules\Advanced\services-optimizer.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\8 Advanced\5 Services Optimizer.ps1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration.Stages | ForEach-Object { $_.Tools })
$tool = $tools | Where-Object { $_.Id -eq 'services-optimizer' } | Select-Object -First 1
if ($null -eq $tool) {
    throw 'Services Optimizer metadata is missing.'
}
if (
    [string]$tool.Stage -ne 'Advanced' -or
    [int]$tool.Order -ne 3 -or
    [string]$tool.Type -ne 'assistant' -or
    [string]$tool.RiskLevel -ne 'high' -or
    (@($tool.Actions) -join ',') -ne 'Analyze,Apply,Default'
) {
    throw 'Services Optimizer metadata is incorrect.'
}

$capabilities = $tool.Capabilities
foreach ($field in @('RequiresAdmin', 'CanReboot', 'CanModifyRegistry', 'CanModifyServices', 'CanModifySecurity', 'CanDeleteFiles', 'UsesTrustedInstaller', 'UsesSafeMode', 'SupportsDefault', 'NeedsExplicitConfirmation')) {
    if (-not [bool]$capabilities[$field]) {
        throw "Services Optimizer capability '$field' must be true."
    }
}
foreach ($field in @('RequiresInternet', 'CanInstallSoftware', 'CanDownload', 'CanModifyDrivers', 'SupportsRestore')) {
    if ([bool]$capabilities[$field]) {
        throw "Services Optimizer capability '$field' must be false."
    }
}

$allActiveToolIds = @($tools | ForEach-Object { [string]$_.Id })
foreach ($deletedToolId in @('resizable-bar-assistant', 'smt-ht-assistant')) {
    if ($allActiveToolIds -contains $deletedToolId) {
        throw "Deleted tool returned to active product scope: $deletedToolId"
    }
}

$approvedSourceHash = '386EEF403F48907E82C2E8E4BE5DFE509B0ED93CADBB5639B42D6326163EDB8F'
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne $approvedSourceHash) {
    throw 'Services Optimizer Ultimate source hash changed.'
}

$source = Get-Content -Raw -LiteralPath $sourcePath
foreach ($requiredSourceText in @(
    '1. Services: Off'
    '2. Services: Default'
    'Enable-ComputerRestore -Drive "C:\"'
    'Checkpoint-Computer -Description "beforeservices" -RestorePointType "MODIFY_SETTINGS"'
    'function Run-Trusted([String]$command)'
    'sc.exe config TrustedInstaller binPath='
    'Regedit.exe /S `"$env:SystemRoot\Temp\servicesoff.reg`"'
    'Regedit.exe /S `"$env:SystemRoot\Temp\serviceson.reg`"'
    'bcdedit /set {current} safeboot minimal'
    'bcdedit /deletevalue {current} safeboot'
    'shutdown -r -t 00'
    '*servicesoff'
    '*serviceson'
)) {
    if (-not $source.Contains($requiredSourceText)) {
        throw "Services Optimizer source no longer contains: $requiredSourceText"
    }
}

$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredModuleText in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
    'Get-BoostLabServicesOptimizerBranchDefinition'
    'RunOnceValueName'
    'bcdedit /set {current} safeboot minimal'
    'shutdown -r -t 00'
    'No smart device analyzer.'
    'No Gaming, Performance, or Extreme profiles.'
    'SupportsRestore = $false'
)) {
    if (-not $moduleSource.Contains($requiredModuleText)) {
        throw "Services Optimizer module is missing: $requiredModuleText"
    }
}
foreach ($forbiddenText in @(
    'GamingProfile'
    'PerformanceProfile'
    'ExtremeProfile'
    'CompatibilityScore'
    'RecommendationEngine'
    'SupportsRestore = $true'
)) {
    if ($moduleSource.Contains($forbiddenText)) {
        throw "Services Optimizer module contains rejected redesign or Restore behavior: $forbiddenText"
    }
}

$parityRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'services-optimizer' }) | Select-Object -First 1
if ($null -eq $parityRecord) {
    throw 'Services Optimizer parity baseline record is missing.'
}
if (
    [string]$parityRecord.RuntimeStatus -ne 'RuntimeImplemented' -or
    [string]$parityRecord.ImplementationLevel -ne 'ParityImplemented' -or
    [string]$parityRecord.UltimateParity -ne 'Yes' -or
    [bool]$parityRecord.YazanFinalException
) {
    throw 'Services Optimizer parity baseline was not finalized as exact Ultimate parity.'
}

$nextOrderedTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
if ($null -eq $nextOrderedTarget) {
    throw 'Ordered parity cursor did not identify the next Advanced target after Services Optimizer.'
}
if ([string]$parityBaseline.CurrentOrderedParityTarget -ne [string]$nextOrderedTarget.ToolId) {
    throw 'Central ordered parity cursor does not match the derived first non-final target.'
}
$advancedOrder = @($executionOrder.Stages | Where-Object { [string]$_.Name -eq 'Advanced' } | Select-Object -First 1)
$advancedTools = @($advancedOrder.Tools)
$advancedToolIds = @($advancedTools | ForEach-Object { [string]$_.ToolId })
$servicesIndex = -1
$nextIndex = -1
for ($index = 0; $index -lt $advancedTools.Count; $index++) {
    if ([string]$advancedTools[$index].ToolId -eq 'services-optimizer') {
        $servicesIndex = $index
    }
    if ([string]$advancedTools[$index].ToolId -eq [string]$nextOrderedTarget.ToolId) {
        $nextIndex = $index
    }
}
if ($servicesIndex -lt 0) {
    throw 'Services Optimizer was not found in the ordered Advanced stage.'
}
if ($nextIndex -ge 0 -and $nextIndex -le $servicesIndex) {
    throw 'Services Optimizer acceptance did not move the ordered cursor beyond Services Optimizer.'
}
if (
    $advancedToolIds -contains 'timer-resolution-assistant' -and
    [string]$nextOrderedTarget.ToolId -eq 'timer-resolution-assistant'
) {
    throw 'Timer Resolution Assistant should not remain the next ordered target after Phase 160.'
}

$module = Import-Module -Name $modulePath -Force -PassThru -Prefix 'ServicesTest' -Scope Local -DisableNameChecking -ErrorAction Stop
try {
    $info = & (Get-Command -Name 'Get-ServicesTestBoostLabToolInfo' -Module $module.Name -ErrorAction Stop)
    if (
        [string]$info.Id -ne 'services-optimizer' -or
        (@($info.Actions) -join ',') -ne 'Analyze,Apply,Default' -or
        (@($info.ImplementedActions) -join ',') -ne 'Analyze,Apply,Default' -or
        [string]$info.ActionLabels.Apply -ne 'Services: Off' -or
        [string]$info.ActionLabels.Default -ne 'Services: Default'
    ) {
        throw 'Services Optimizer exported metadata, implemented actions, or labels are incorrect.'
    }

    $analysis = & $module {
        Get-BoostLabServicesOptimizerAnalyzeData
    }
    if (
        -not [bool]$analysis.SourceHashMatches -or
        [int]$analysis.ApplyBranch.ServiceTargetCount -lt 250 -or
        [int]$analysis.DefaultBranch.ServiceTargetCount -lt 250 -or
        [string]$analysis.ApplyBranch.RunOnceValueName -ne '*servicesoff' -or
        [string]$analysis.DefaultBranch.RunOnceValueName -ne '*serviceson' -or
        @($analysis.RejectedRedesignBehavior | Where-Object { $_ -match 'smart device analyzer' }).Count -ne 1
    ) {
        throw 'Services Optimizer Analyze data does not describe the source-defined workflow.'
    }

    $applyBranch = & $module {
        Get-BoostLabServicesOptimizerBranchDefinition -ActionName 'Apply'
    }
    $defaultBranch = & $module {
        Get-BoostLabServicesOptimizerBranchDefinition -ActionName 'Default'
    }
    if (
        [string]$applyBranch.SourceLabel -ne 'Services: Off' -or
        [string]$defaultBranch.SourceLabel -ne 'Services: Default' -or
        $applyBranch.ServiceTargetCount -ne $defaultBranch.ServiceTargetCount -or
        @($applyBranch.ServiceTargets | Where-Object { $_.Name -eq 'ADPSvc' -and [int]$_.StartValue -eq 4 }).Count -ne 1 -or
        @($defaultBranch.ServiceTargets | Where-Object { $_.Name -eq 'ADPSvc' -and [int]$_.StartValue -eq 3 }).Count -ne 1 -or
        @($applyBranch.ServiceTargets | Where-Object { $_.Name -eq 'TrustedInstaller' -and [int]$_.StartValue -eq 3 }).Count -ne 1 -or
        @($defaultBranch.ServiceTargets | Where-Object { $_.Name -eq 'TrustedInstaller' -and [int]$_.StartValue -eq 3 }).Count -ne 1
    ) {
        throw 'Services Optimizer source branch extraction does not preserve expected service targets.'
    }

    $cancelled = & $module {
        Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$false
    }
    if (-not $cancelled.Cancelled -or $cancelled.Message -ne 'Cancelled by user') {
        throw 'Services Optimizer confirmation handling is incorrect.'
    }

    foreach ($case in @(
        [pscustomobject]@{ Action = 'Apply'; Label = 'Services: Off'; Script = 'servicesoff.ps1'; RunOnce = '*servicesoff'; RegFile = 'servicesoff.reg' }
        [pscustomobject]@{ Action = 'Default'; Label = 'Services: Default'; Script = 'serviceson.ps1'; RunOnce = '*serviceson'; RegFile = 'serviceson.reg' }
    )) {
        $commands = [System.Collections.Generic.List[string]]::new()
        $powershellCalls = [System.Collections.Generic.List[string]]::new()
        $fileWrites = @{}
        $runOnceValues = @{}
        $patchedFiles = [System.Collections.Generic.List[string]]::new()
        $sleepCalls = [System.Collections.Generic.List[int]]::new()
        $restartCalls = [System.Collections.Generic.List[string]]::new()

        $commandInvoker = {
            param($CommandText)
            $commands.Add($CommandText) | Out-Null
            [pscustomobject]@{ Success = $true; Output = '' }
        }.GetNewClosure()
        $powerShellInvoker = {
            param($CommandName)
            $powershellCalls.Add($CommandName) | Out-Null
            [pscustomobject]@{ Success = $true; Output = '' }
        }.GetNewClosure()
        $fileWriter = {
            param($Path, $Content)
            $fileWrites[$Path] = $Content
            [pscustomobject]@{ Success = $true; Output = '' }
        }.GetNewClosure()
        $filePatcher = {
            param($Path)
            if (-not $fileWrites.ContainsKey($Path)) {
                throw "Missing generated script for patch: $Path"
            }
            $fileWrites[$Path] = $fileWrites[$Path] -replace "``'@", "'@"
            $patchedFiles.Add($Path) | Out-Null
            [pscustomobject]@{ Success = $true; Output = '' }
        }.GetNewClosure()
        $sleepInvoker = {
            param($Seconds)
            $sleepCalls.Add([int]$Seconds) | Out-Null
            [pscustomobject]@{ Success = $true; Output = '' }
        }.GetNewClosure()
        $restartInvoker = {
            $restartCalls.Add('shutdown -r -t 00') | Out-Null
            [pscustomobject]@{ Success = $true; Output = '' }
        }.GetNewClosure()
        $runOnceWriter = {
            param($RegistryPath, $ValueName, $ValueData)
            if ([string]$RegistryPath -ne 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce') {
                throw "Unexpected RunOnce path: $RegistryPath"
            }
            $runOnceValues[$ValueName] = $ValueData
            [pscustomobject]@{ Success = $true; Output = 'mock write' }
        }.GetNewClosure()
        $runOnceReader = {
            param($RegistryPath, $ValueName)
            if (-not $runOnceValues.ContainsKey($ValueName)) {
                [pscustomobject]@{ Success = $false; Output = 'mock missing'; Value = $null }
            }
            else {
                [pscustomobject]@{ Success = $true; Output = 'mock read'; Value = [string]$runOnceValues[$ValueName] }
            }
        }.GetNewClosure()

        $result = & $module {
            param($ActionName, $CommandInvoker, $PowerShellInvoker, $FileWriter, $FilePatcher, $SleepInvoker, $RestartInvoker, $RunOnceWriter, $RunOnceReader)
            Invoke-BoostLabServicesOptimizerAction `
                -ActionName $ActionName `
                -AdministratorChecker { return $true } `
                -CommandInvoker $CommandInvoker `
                -PowerShellInvoker $PowerShellInvoker `
                -FileWriter $FileWriter `
                -FilePatcher $FilePatcher `
                -SleepInvoker $SleepInvoker `
                -RestartInvoker $RestartInvoker `
                -RunOnceWriter $RunOnceWriter `
                -RunOnceReader $RunOnceReader `
                -SystemRoot 'C:\Windows'
        } $case.Action $commandInvoker $powerShellInvoker $fileWriter $filePatcher $sleepInvoker $restartInvoker $runOnceWriter $runOnceReader

        if (
            -not $result.Success -or
            -not $result.RestartRequired -or
            [string]$result.Data.SourceBranchLabel -ne [string]$case.Label -or
            [string]$result.Data.GeneratedScriptFileName -ne [string]$case.Script -or
            [string]$result.Data.GeneratedRegFileName -ne [string]$case.RegFile -or
            [string]$result.Data.RunOnceValueName -ne [string]$case.RunOnce -or
            [string]$result.Data.RunOnceKeyPath -ne 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -or
            [string]$result.Data.RunOnceExpectedValueData -ne "powershell.exe -nop -ep bypass -WindowStyle Maximized -f C:\Windows\Temp\$($case.Script)" -or
            [string]$result.Data.RunOnceDetectedValueData -ne [string]$result.Data.RunOnceExpectedValueData -or
            @($result.Data.Errors).Count -ne 0
        ) {
            throw "Mocked Services Optimizer $($case.Action) staging did not return the expected structured result."
        }
        if (
            -not $runOnceValues.ContainsKey([string]$case.RunOnce) -or
            [string]$runOnceValues[[string]$case.RunOnce] -ne [string]$result.Data.RunOnceExpectedValueData -or
            [string]$result.Data.RunOnceCommand -notmatch [regex]::Escape([string]$case.RunOnce) -or
            [string]$result.Data.RunOnceCommand -notmatch [regex]::Escape([string]$result.Data.RunOnceExpectedValueData)
        ) {
            throw "Mocked Services Optimizer $($case.Action) did not write and report the exact source-equivalent RunOnce value."
        }
        if ($fileWrites.Keys.Count -ne 1 -or $patchedFiles.Count -ne 1) {
            throw "Mocked Services Optimizer $($case.Action) did not write and patch exactly one generated script."
        }
        $writtenContent = [string]($fileWrites.Values | Select-Object -First 1)
        foreach ($requiredGeneratedText in @(
            'function Run-Trusted([String]$command)'
            'Regedit.exe /S'
            $case.RegFile
            'bcdedit /deletevalue {current} safeboot'
            'shutdown -r -t 00'
            'TrustedInstaller'
        )) {
            if (-not $writtenContent.Contains($requiredGeneratedText)) {
                throw "Generated $($case.Script) is missing source text: $requiredGeneratedText"
            }
        }
        if ($writtenContent.Contains("``'@")) {
            throw "Generated $($case.Script) was not patched like the Ultimate source."
        }
        foreach ($requiredCommandText in @(
            'SystemRestorePointCreationFrequency'
            'bcdedit /set {current} safeboot minimal'
        )) {
            if ((@($commands | Where-Object { $_ -match [regex]::Escape($requiredCommandText) }).Count) -lt 1) {
                throw "Mocked Services Optimizer $($case.Action) did not issue expected command containing: $requiredCommandText"
            }
        }
        if (($powershellCalls -join '|') -ne 'Enable-ComputerRestore|Checkpoint-Computer') {
            throw "Mocked Services Optimizer $($case.Action) did not attempt the source restore point prelude."
        }
        if ($sleepCalls.Count -ne 1 -or [int]$sleepCalls[0] -ne 5 -or $restartCalls.Count -ne 1) {
            throw "Mocked Services Optimizer $($case.Action) did not preserve the source restart staging sequence."
        }
    }

    $failingCommands = [System.Collections.Generic.List[string]]::new()
    $failingRestarts = [System.Collections.Generic.List[string]]::new()
    $failingRunOnceWriter = {
        param($RegistryPath, $ValueName, $ValueData)
        [pscustomobject]@{ Success = $false; Output = '' }
    }.GetNewClosure()
    $failingResult = & $module {
        param($CommandCalls, $RestartCalls, $RunOnceWriter)
        Invoke-BoostLabServicesOptimizerAction `
            -ActionName 'Apply' `
            -AdministratorChecker { return $true } `
            -CommandInvoker {
                param($CommandText)
                $CommandCalls.Add($CommandText) | Out-Null
                [pscustomobject]@{ Success = $true; Output = '' }
            } `
            -PowerShellInvoker { [pscustomobject]@{ Success = $true; Output = '' } } `
            -FileWriter { [pscustomobject]@{ Success = $true; Output = '' } } `
            -FilePatcher { [pscustomobject]@{ Success = $true; Output = '' } } `
            -SleepInvoker { [pscustomobject]@{ Success = $true; Output = '' } } `
            -RestartInvoker {
                $RestartCalls.Add('restart') | Out-Null
                [pscustomobject]@{ Success = $true; Output = '' }
            } `
            -RunOnceWriter $RunOnceWriter `
            -RunOnceReader { [pscustomobject]@{ Success = $false; Output = 'should not read'; Value = $null } } `
            -SystemRoot 'C:\Windows'
    } $failingCommands $failingRestarts $failingRunOnceWriter
    if (
        $failingResult.Success -or
        [string]$failingResult.Message -notmatch 'InstallRunOnce failed: RunOnce registry write failed without diagnostic output' -or
        @($failingResult.Data.Operations | Where-Object { $_.Step -eq 'SetSafeBootMinimal' }).Count -ne 0 -or
        @($failingCommands | Where-Object { $_ -match 'bcdedit /set \{current\} safeboot minimal' }).Count -ne 0 -or
        $failingRestarts.Count -ne 0
    ) {
        throw 'Services Optimizer RunOnce failure did not fail closed before bcdedit/restart with a non-empty diagnostic.'
    }

    $mismatchRunOnceValues = @{}
    $mismatchResult = & $module {
        param($RunOnceValues)
        Invoke-BoostLabServicesOptimizerAction `
            -ActionName 'Apply' `
            -AdministratorChecker { return $true } `
            -CommandInvoker { [pscustomobject]@{ Success = $true; Output = '' } } `
            -PowerShellInvoker { [pscustomobject]@{ Success = $true; Output = '' } } `
            -FileWriter { [pscustomobject]@{ Success = $true; Output = '' } } `
            -FilePatcher { [pscustomobject]@{ Success = $true; Output = '' } } `
            -SleepInvoker { [pscustomobject]@{ Success = $true; Output = '' } } `
            -RestartInvoker { throw 'Restart must not be reached after RunOnce verification mismatch.' } `
            -RunOnceWriter {
                param($RegistryPath, $ValueName, $ValueData)
                $RunOnceValues[$ValueName] = $ValueData
                [pscustomobject]@{ Success = $true; Output = 'mock write' }
            } `
            -RunOnceReader {
                [pscustomobject]@{ Success = $true; Output = 'mock read'; Value = 'powershell.exe -bad-data' }
            } `
            -SystemRoot 'C:\Windows'
    } $mismatchRunOnceValues
    if (
        $mismatchResult.Success -or
        [string]$mismatchResult.Message -notmatch 'detected value data did not match' -or
        [string]$mismatchResult.Data.RunOnceDetectedValueData -ne 'powershell.exe -bad-data'
    ) {
        throw 'Services Optimizer RunOnce verification mismatch did not fail closed with detected data.'
    }
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    $analyzePlan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Analyze' -IsDryRun $false
    if ($analyzePlan.Summary -notmatch 'Services Off' -or (@($analyzePlan.SideEffects) -join ' ') -notmatch 'No system changes') {
        throw 'Services Optimizer Analyze action plan is incomplete.'
    }

    foreach ($actionName in @('Apply', 'Default')) {
        $plan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName $actionName -IsDryRun $false
        if (
            -not $plan.NeedsExplicitConfirmation -or
            -not $plan.RequiresAdmin -or
            -not $plan.CanReboot -or
            $plan.ConfirmationMessage -notmatch 'RunOnce' -or
            $plan.ConfirmationMessage -notmatch 'safeboot minimal' -or
            (@($plan.SideEffects) -join ' ') -notmatch 'TrustedInstaller' -or
            (@($plan.PlannedChanges) -join ' ') -notmatch 'shutdown -r -t 00'
        ) {
            throw "Services Optimizer $actionName action plan does not expose the required source workflow risk."
        }
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredText in @(
    '''services-optimizer'' = @{'
    '''Advanced\services-optimizer.psm1'''
    'Actions = @(''Analyze'', ''Apply'', ''Default'')'
)) {
    if (-not $executionSource.Contains($requiredText)) {
        throw "Services Optimizer runtime mapping is missing: $requiredText"
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
    ToolId = 'services-optimizer'
    ImplementedActions = @('Analyze', 'Apply', 'Default')
    MockedApplyPassed = $true
    MockedDefaultPassed = $true
    ImplementedModuleCount = $implementedCount
    PlaceholderModuleCount = $placeholderCount
    SourceUltimateUnchanged = $true
    DeletedToolsRemainDeleted = $true
    Message = 'Services Optimizer exact source workflow was validated with mocked file, registry, BCD, RunOnce, Safe Mode, TrustedInstaller, and reboot operations only.'
    Timestamp = Get-Date
}
