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
        throw 'Unable to determine the Defender Optimize Assistant validator script path.'
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
$modulePath = Join-Path $ProjectRoot 'modules\Advanced\defender-optimize-assistant.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\8 Advanced\7 Defender Optimize Assistant.ps1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$designPath = Join-Path $ProjectRoot 'docs\tool-designs\defender-optimize-assistant-scope-design.md'
$servicePolicyPath = Join-Path $ProjectRoot 'config\ServiceRollbackPolicy.psd1'
$rollbackPolicyPath = Join-Path $ProjectRoot 'config\RollbackPolicy.psd1'
$trustedPolicyPath = Join-Path $ProjectRoot 'config\TrustedInstallerPolicy.psd1'
$safeModePolicyPath = Join-Path $ProjectRoot 'config\SafeModeRecoveryPolicy.psd1'
$rebootPolicyPath = Join-Path $ProjectRoot 'config\RebootRecoveryPolicy.psd1'
$artifactPolicyPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$cleanupPolicyPath = Join-Path $ProjectRoot 'config\CleanupPolicy.psd1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

foreach ($path in @(
    $configPath,
    $modulePath,
    $sourcePath,
    $actionPlanPath,
    $executionPath,
    $designPath,
    $servicePolicyPath,
    $rollbackPolicyPath,
    $trustedPolicyPath,
    $safeModePolicyPath,
    $rebootPolicyPath,
    $artifactPolicyPath,
    $cleanupPolicyPath
)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file was not found: $path"
    }
}

$expectedSourceHash = '512F12D805715E9232304ABE5BA400BE6B3965D63F77D3B39E4C304507BFB9B6'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
if ($actualSourceHash -ne $expectedSourceHash) {
    throw "Defender Optimize Assistant source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."
}

$config = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })
$tool = @($allTools | Where-Object { [string]$_.Id -eq 'defender-optimize-assistant' }) | Select-Object -First 1
if ($null -eq $tool) {
    throw 'Defender Optimize Assistant catalog entry was not found.'
}
if (
    [string]$tool.Stage -ne 'Advanced' -or
    [int]$tool.Order -ne 2 -or
    [string]$tool.Type -ne 'assistant' -or
    [string]$tool.RiskLevel -ne 'high' -or
    (@($tool.Actions) -join ',') -ne 'Analyze,Apply,Default'
) {
    throw 'Defender Optimize Assistant stage metadata is incorrect.'
}

$capabilities = $tool.Capabilities
foreach ($field in @('RequiresAdmin', 'CanReboot', 'CanModifyRegistry', 'CanModifyServices', 'CanModifyDrivers', 'CanModifySecurity', 'CanDeleteFiles', 'UsesTrustedInstaller', 'UsesSafeMode', 'SupportsDefault', 'NeedsExplicitConfirmation')) {
    if (-not [bool]$capabilities[$field]) {
        throw "Defender Optimize Assistant capability '$field' must be true."
    }
}
foreach ($field in @('RequiresInternet', 'CanInstallSoftware', 'CanDownload', 'SupportsRestore')) {
    if ([bool]$capabilities[$field]) {
        throw "Defender Optimize Assistant capability '$field' must be false."
    }
}

$sourceText = Get-Content -Raw -LiteralPath $sourcePath
foreach ($requiredSourceText in @(
    '1. Defender: Optimize (Recommended)'
    '2. Defender: Default'
    '$DefenderOptimize = @'''
    '$DefenderDefault = @'''
    'Set-Content -Path "$env:SystemRoot\Temp\defenderoptimize.ps1" -Value $DefenderOptimize -Force'
    'Set-Content -Path "$env:SystemRoot\Temp\defenderdefault.ps1" -Value $DefenderDefault -Force'
    'Run-Trusted'
    'sc.exe config TrustedInstaller binPath='
    'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
    '*defenderoptimize'
    '*defenderdefault'
    'bcdedit /set {current} safeboot minimal'
    'bcdedit /deletevalue {current} safeboot'
    'shutdown -r -t 00'
    'TamperProtection'
    'VulnerableDriverBlocklistEnable'
    'schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Disable'
    'schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Enable'
)) {
    if (-not $sourceText.Contains($requiredSourceText)) {
        throw "Defender Optimize Assistant source no longer contains: $requiredSourceText"
    }
}
if ($sourceText -match 'https?://|Invoke-WebRequest|Start-BitsTransfer|curl\.exe|msiexec') {
    throw 'Defender Optimize Assistant source unexpectedly contains download or installer behavior.'
}

$registryLines = @($sourceText -split "`r?`n" | Where-Object { $_ -match 'reg (add|delete) `"' })
if ($registryLines.Count -ne 85) {
    throw "Expected 85 registry command lines, found $($registryLines.Count)."
}
$taskTargets = @(
    Select-String -Path $sourcePath -Pattern 'schtasks /Change /TN "([^"]+)" /(Disable|Enable)' |
        ForEach-Object { $_.Matches[0].Groups[1].Value } |
        Sort-Object -Unique
)
if ($taskTargets.Count -ne 5) {
    throw "Expected 5 unique scheduled task targets, found $($taskTargets.Count)."
}

$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredModuleText in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
    $expectedSourceHash
    'Get-BoostLabDefenderScriptPayload'
    'Get-BoostLabDefenderSecurityCommands'
    'defenderoptimize.ps1'
    'defenderdefault.ps1'
    '*defenderoptimize'
    '*defenderdefault'
    'Set-BoostLabDefenderRunOnceValue'
    'ExpectedRunOnceData'
    'SourceRunOnceCommandExecuted'
    '/d /c '
    'SupportsRestore = $false'
    'SupportsDefault = $true'
    'UsesTrustedInstaller = $true'
    'UsesSafeMode = $true'
    'RunOnce'
    'bcdedit /set {current} safeboot minimal'
    'shutdown -r -t 00'
)) {
    if (-not $moduleSource.Contains($requiredModuleText)) {
        throw "Defender Optimize Assistant module is missing: $requiredModuleText"
    }
}
foreach ($forbiddenModuleText in @(
    'ToolModule.Placeholder.ps1'
    'SupportsRestore = $true'
    'Invoke-WebRequest'
    'Start-BitsTransfer'
    'msiexec'
    'Start-Process'
    '[scriptblock]::Create($CommandText)'
)) {
    if ($moduleSource.Contains($forbiddenModuleText)) {
        throw "Defender Optimize Assistant module contains stale or unrelated behavior: $forbiddenModuleText"
    }
}

$actionPlanSource = Get-Content -Raw -LiteralPath $actionPlanPath
foreach ($requiredActionPlanText in @(
    'Stage the approved Ultimate Defender: Optimize (Recommended) workflow'
    'Stage the approved Ultimate Defender: Default workflow'
    'Write %SystemRoot%\Temp\defenderoptimize.ps1'
    'Write %SystemRoot%\Temp\defenderdefault.ps1'
    'Create RunOnce value *defenderoptimize'
    'Create RunOnce value *defenderdefault'
    'Default is the source-defined Defender: Default preset, not captured-state Restore.'
)) {
    if (-not $actionPlanSource.Contains($requiredActionPlanText)) {
        throw "ActionPlan is missing Defender Optimize Assistant wording: $requiredActionPlanText"
    }
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
if (-not $executionSource.Contains("'defender-optimize-assistant' = @{")) {
    throw 'Execution routing does not include Defender Optimize Assistant.'
}

$parityRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'defender-optimize-assistant' }) | Select-Object -First 1
if ($null -eq $parityRecord) {
    throw 'Defender Optimize Assistant parity baseline record is missing.'
}
if (
    [string]$parityRecord.RuntimeStatus -ne 'RuntimeImplemented' -or
    [string]$parityRecord.ImplementationLevel -ne 'ParityImplemented' -or
    [string]$parityRecord.UltimateParity -ne 'Yes' -or
    [string]$parityRecord.FinalProgressStatus -ne 'DoneParity' -or
    [bool]$parityRecord.YazanFinalException
) {
    throw 'Defender Optimize Assistant parity baseline was not finalized as exact Ultimate parity.'
}
if ($null -ne $parityBaseline.CurrentOrderedParityTarget) {
    throw 'CurrentOrderedParityTarget must be null after the final ordered parity target is accepted.'
}
if (-not [bool]$parityBaseline.OrderedParityComplete) {
    throw 'OrderedParityComplete must be true after Defender Optimize Assistant acceptance.'
}
$nextOrderedTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
if ($null -eq $nextOrderedTarget -or -not [bool]$nextOrderedTarget.IsOrderedParityComplete -or $null -ne $nextOrderedTarget.ToolId) {
    throw 'Ordered parity helper must report completion after the final target is accepted.'
}

$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
if ([int]$categoryCounts['ParityImplemented'] -ne [int]$parityBaseline.Counts.UltimateParityImplemented) {
    throw 'ParityImplemented count mismatch.'
}
if ($categoryCounts.ContainsKey('DeferredForParityWork') -and [int]$categoryCounts['DeferredForParityWork'] -ne 0) {
    throw 'No tools should remain DeferredForParityWork after Defender Optimize Assistant acceptance.'
}
if ([int]$parityBaseline.Counts.DeferredForParityWork -ne 0) {
    throw 'DeferredForParityWork baseline count must be zero after final acceptance.'
}

$module = Import-Module -Name $modulePath -Force -PassThru -Prefix 'DefenderTest' -Scope Local -DisableNameChecking -ErrorAction Stop
try {
    $info = & (Get-Command -Name 'Get-DefenderTestBoostLabToolInfo' -Module $module.Name -ErrorAction Stop)
    if (
        [string]$info.Id -ne 'defender-optimize-assistant' -or
        (@($info.Actions) -join ',') -ne 'Analyze,Apply,Default' -or
        (@($info.ImplementedActions) -join ',') -ne 'Analyze,Apply,Default' -or
        [string]$info.ActionLabels.Apply -ne 'Defender: Optimize (Recommended)' -or
        [string]$info.ActionLabels.Default -ne 'Defender: Default' -or
        [bool]$info.Capabilities.SupportsRestore
    ) {
        throw 'Defender Optimize Assistant exported metadata, implemented actions, labels, or restore capability are incorrect.'
    }

    $compatibility = & (Get-Command -Name 'Test-DefenderTestBoostLabToolCompatibility' -Module $module.Name -ErrorAction Stop) `
        -OperatingSystem 'Windows_NT' `
        -SystemRoot 'C:\Windows' `
        -PathChecker { param($Path) return ($Path -in @('C:\Windows\System32\cmd.exe', 'C:\Windows\System32\schtasks.exe', 'C:\Windows\System32\bcdedit.exe', 'C:\Windows\System32\shutdown.exe')) }
    if (-not [bool]$compatibility.Supported) {
        throw "Defender Optimize Assistant mocked compatibility did not pass: $($compatibility.Reason)"
    }

    $analysisResult = & (Get-Command -Name 'Invoke-DefenderTestBoostLabToolAction' -Module $module.Name -ErrorAction Stop) `
        -ActionName 'Analyze' `
        -SystemRoot 'C:\Windows'
    $analysis = $analysisResult.Data
    if (
        -not $analysisResult.Success -or
        -not [bool]$analysis.SourceHashMatches -or
        [string]$analysis.ApplyBranch.Label -ne 'Defender: Optimize (Recommended)' -or
        [string]$analysis.DefaultBranch.Label -ne 'Defender: Default' -or
        [int]$analysis.ApplyBranch.NormalBootCommandCount -ne 8 -or
        [int]$analysis.DefaultBranch.NormalBootCommandCount -ne 8 -or
        [int]$analysis.ScheduledTaskCount -ne 5 -or
        @($analysis.Downloads).Count -ne 0 -or
        @($analysis.ExternalArtifacts).Count -ne 0 -or
        [bool]$analysis.SupportsOpen -or
        [bool]$analysis.SupportsRestore -or
        -not [bool]$analysis.UsesSafeMode -or
        -not [bool]$analysis.UsesTrustedInstaller
    ) {
        throw 'Defender Optimize Assistant Analyze did not report the expected read-only source workflow.'
    }

    foreach ($actionName in @('Apply', 'Default')) {
        $cancelled = & (Get-Command -Name 'Invoke-DefenderTestBoostLabToolAction' -Module $module.Name -ErrorAction Stop) `
            -ActionName $actionName `
            -Confirmed:$false `
            -SystemRoot 'C:\Windows'
        if (-not $cancelled.Cancelled -or $cancelled.Message -ne 'Cancelled by user') {
            throw "Defender Optimize Assistant $actionName confirmation handling is incorrect."
        }
    }

    foreach ($case in @(
        [pscustomobject]@{
            Action = 'Apply'
            Label = 'Defender: Optimize (Recommended)'
            ScriptPath = 'C:\Windows\Temp\defenderoptimize.ps1'
            RunOnce = '*defenderoptimize'
            TaskSwitch = '/Disable'
            EdgeCommand = 'SmartScreenEnabled /t REG_DWORD /d 0'
        }
        [pscustomobject]@{
            Action = 'Default'
            Label = 'Defender: Default'
            ScriptPath = 'C:\Windows\Temp\defenderdefault.ps1'
            RunOnce = '*defenderdefault'
            TaskSwitch = '/Enable'
            EdgeCommand = 'SmartScreenEnabled /t REG_DWORD /d 1'
        }
    )) {
        $fileWrites = @{}
        $runOnceInstalls = [System.Collections.Generic.List[object]]::new()
        $commandCalls = [System.Collections.Generic.List[string]]::new()
        $sleepCalls = [System.Collections.Generic.List[int]]::new()
        $restartCalls = [System.Collections.Generic.List[string]]::new()

        $fileWriter = {
            param($Path, $Content)
            $fileWrites[$Path] = $Content
            [pscustomobject]@{ Success = $true; Output = '' }
        }.GetNewClosure()
        $commandInvoker = {
            param($CommandText)
            $commandCalls.Add([string]$CommandText)
            [pscustomobject]@{ Success = $true; Output = ''; CommandText = $CommandText }
        }.GetNewClosure()
        $runOnceInstaller = {
            param($KeyPath, $ValueName, $ValueData, $SourceCommandText)
            $record = [pscustomobject]@{
                KeyPath = [string]$KeyPath
                ValueName = [string]$ValueName
                ValueData = [string]$ValueData
                SourceCommandText = [string]$SourceCommandText
            }
            $runOnceInstalls.Add($record)
            [pscustomobject]@{
                Success = $true
                Output = 'Mocked RunOnce value was installed and verified.'
                KeyPath = [string]$KeyPath
                ValueName = [string]$ValueName
                ExpectedValueData = [string]$ValueData
                ActualValueData = [string]$ValueData
                Method = 'MockRegistryApi'
                SourceCommandText = [string]$SourceCommandText
                SourceCommandExecuted = $false
            }
        }.GetNewClosure()
        $sleepInvoker = {
            param($Seconds)
            $sleepCalls.Add([int]$Seconds)
            [pscustomobject]@{ Success = $true; Output = '' }
        }.GetNewClosure()
        $restartInvoker = {
            $restartCalls.Add('shutdown -r -t 00')
            [pscustomobject]@{ Success = $true; Output = '' }
        }.GetNewClosure()

        $result = & (Get-Command -Name 'Invoke-DefenderTestBoostLabToolAction' -Module $module.Name -ErrorAction Stop) `
            -ActionName $case.Action `
            -Confirmed:$true `
            -AdministratorChecker { $true } `
            -SystemRoot 'C:\Windows' `
            -FileWriter $fileWriter `
            -CommandInvoker $commandInvoker `
            -RunOnceInstaller $runOnceInstaller `
            -SleepInvoker $sleepInvoker `
            -RestartInvoker $restartInvoker

        if (-not $result.Success -or -not [bool]$result.RestartRequired) {
            throw "Defender Optimize Assistant $($case.Action) mocked workflow did not succeed."
        }
        if (-not $fileWrites.ContainsKey($case.ScriptPath)) {
            throw "Defender Optimize Assistant $($case.Action) did not write the source-defined generated script path."
        }
        $payload = [string]$fileWrites[$case.ScriptPath]
        if (-not $payload.Contains('Run-Trusted') -or -not $payload.Contains('bcdedit /deletevalue {current} safeboot') -or -not $payload.Contains('shutdown -r -t 00')) {
            throw "Defender Optimize Assistant $($case.Action) generated script payload is missing required Safe Mode/TrustedInstaller behavior."
        }
        if ($runOnceInstalls.Count -ne 1) {
            throw "Defender Optimize Assistant $($case.Action) did not create exactly one mocked RunOnce value."
        }
        $runOnceInstall = $runOnceInstalls[0]
        $expectedRunOnceData = 'powershell.exe -nop -ep bypass -WindowStyle Maximized -f {0}' -f $case.ScriptPath
        if (
            [string]$runOnceInstall.KeyPath -ne 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -or
            [string]$runOnceInstall.ValueName -ne [string]$case.RunOnce -or
            [string]$runOnceInstall.ValueData -ne $expectedRunOnceData
        ) {
            throw "Defender Optimize Assistant $($case.Action) RunOnce value name or data is incorrect."
        }
        if (-not ([string]$runOnceInstall.SourceCommandText).Contains('>nul 2>&1')) {
            throw "Defender Optimize Assistant $($case.Action) must preserve the source-derived RunOnce command text for reporting."
        }
        if (@($commandCalls | Where-Object { $_ -like '*RunOnce*' -or $_ -like "*$($case.RunOnce)*" }).Count -ne 0) {
            throw "Defender Optimize Assistant $($case.Action) must not execute the source RunOnce command text through the command invoker."
        }
        if ($commandCalls.Count -ne 8) {
            throw "Defender Optimize Assistant $($case.Action) should issue 8 normal-boot commands after native RunOnce staging; saw $($commandCalls.Count)."
        }
        if (-not (@($commandCalls | Where-Object { $_ -like "*$($case.EdgeCommand)*" }).Count -eq 1)) {
            throw "Defender Optimize Assistant $($case.Action) did not set the expected normal-boot Edge SmartScreen command."
        }
        $taskCommands = @($commandCalls | Where-Object { $_ -like 'schtasks /Change*' })
        if ($taskCommands.Count -ne 5 -or @($taskCommands | Where-Object { $_ -notlike "*$($case.TaskSwitch)*" }).Count -ne 0) {
            throw "Defender Optimize Assistant $($case.Action) did not use the expected scheduled-task switch."
        }
        if (@($commandCalls | Where-Object { $_ -eq 'bcdedit /set {current} safeboot minimal >nul 2>&1' }).Count -ne 1) {
            throw "Defender Optimize Assistant $($case.Action) did not stage safeboot minimal exactly once."
        }
        if ($sleepCalls.Count -ne 1 -or $sleepCalls[0] -ne 5 -or $restartCalls.Count -ne 1) {
            throw "Defender Optimize Assistant $($case.Action) did not preserve the source-defined sleep/restart sequence."
        }
        if (
            [string]$result.Data.SourceBranchLabel -ne [string]$case.Label -or
            [string]$result.Data.ExpectedRunOnceData -ne $expectedRunOnceData -or
            [string]$result.Data.ActualRunOnceData -ne $expectedRunOnceData -or
            [string]$result.Data.RunOnceInstallMethod -ne 'MockRegistryApi' -or
            [bool]$result.Data.SourceRunOnceCommandExecuted -or
            [int]$result.Data.GeneratedSecurityCommandCount -le 30 -or
            @($result.Data.Downloads).Count -ne 0 -or
            @($result.Data.ExternalArtifacts).Count -ne 0
        ) {
            throw "Defender Optimize Assistant $($case.Action) result data did not report the expected source workflow."
        }
    }

    $failureFileWrites = @{}
    $failureCommandCalls = [System.Collections.Generic.List[string]]::new()
    $failureSleepCalls = [System.Collections.Generic.List[int]]::new()
    $failureRestartCalls = [System.Collections.Generic.List[string]]::new()
    $failureFileWriter = {
        param($Path, $Content)
        $failureFileWrites[$Path] = $Content
        [pscustomobject]@{ Success = $true; Output = '' }
    }.GetNewClosure()
    $failureCommandInvoker = {
        param($CommandText)
        $failureCommandCalls.Add([string]$CommandText)
        [pscustomobject]@{ Success = $true; Output = ''; CommandText = $CommandText }
    }.GetNewClosure()
    $failingRunOnceInstaller = {
        param($KeyPath, $ValueName, $ValueData, $SourceCommandText)
        [pscustomobject]@{
            Success = $false
            Output = 'Mocked RunOnce install failure without FileStream/NUL device redirection.'
            KeyPath = [string]$KeyPath
            ValueName = [string]$ValueName
            ExpectedValueData = [string]$ValueData
            ActualValueData = ''
            Method = 'MockRegistryApi'
            SourceCommandText = [string]$SourceCommandText
            SourceCommandExecuted = $false
        }
    }
    $failureSleepInvoker = {
        param($Seconds)
        $failureSleepCalls.Add([int]$Seconds)
        [pscustomobject]@{ Success = $true; Output = '' }
    }.GetNewClosure()
    $failureRestartInvoker = {
        $failureRestartCalls.Add('shutdown -r -t 00')
        [pscustomobject]@{ Success = $true; Output = '' }
    }.GetNewClosure()
    $runOnceFailure = & (Get-Command -Name 'Invoke-DefenderTestBoostLabToolAction' -Module $module.Name -ErrorAction Stop) `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -SystemRoot 'C:\Windows' `
        -FileWriter $failureFileWriter `
        -CommandInvoker $failureCommandInvoker `
        -RunOnceInstaller $failingRunOnceInstaller `
        -SleepInvoker $failureSleepInvoker `
        -RestartInvoker $failureRestartInvoker
    if ([bool]$runOnceFailure.Success -or [string]$runOnceFailure.Message -notmatch 'RunOnce install failure') {
        throw 'Defender Optimize Assistant must fail clearly when RunOnce staging fails.'
    }
    if (
        -not $failureFileWrites.ContainsKey('C:\Windows\Temp\defenderoptimize.ps1') -or
        $failureCommandCalls.Count -ne 0 -or
        $failureSleepCalls.Count -ne 0 -or
        $failureRestartCalls.Count -ne 0
    ) {
        throw 'Defender Optimize Assistant must stop before normal-boot commands, safeboot, sleep, or restart when RunOnce staging fails.'
    }
    if ([bool]$runOnceFailure.Data.SourceRunOnceCommandExecuted) {
        throw 'Defender Optimize Assistant must not execute the source RunOnce redirection command when native staging fails.'
    }
}
finally {
    Remove-Module -Name $module.Name -Force -ErrorAction SilentlyContinue
}

$activeTools = @($allTools)
$placeholderModules = @(
    Get-ChildItem -Path (Join-Path $ProjectRoot 'modules') -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
if ($activeTools.Count -ne $inventoryBaseline.ActiveTools) {
    throw "Expected $($inventoryBaseline.ActiveTools) active tools, found $($activeTools.Count)."
}
if ($placeholderModules.Count -ne $inventoryBaseline.DeferredPlaceholders) {
    throw "Expected $($inventoryBaseline.DeferredPlaceholders) placeholder modules, found $($placeholderModules.Count)."
}
if (($activeTools.Count - $placeholderModules.Count) -ne $inventoryBaseline.ImplementedTools) {
    throw "Expected $($inventoryBaseline.ImplementedTools) implemented tools, found $($activeTools.Count - $placeholderModules.Count)."
}

$servicePolicy = Import-PowerShellDataFile -LiteralPath $servicePolicyPath
$rollbackPolicy = Import-PowerShellDataFile -LiteralPath $rollbackPolicyPath
$trustedPolicy = Import-PowerShellDataFile -LiteralPath $trustedPolicyPath
$safeModePolicy = Import-PowerShellDataFile -LiteralPath $safeModePolicyPath
$rebootPolicy = Import-PowerShellDataFile -LiteralPath $rebootPolicyPath
$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPolicyPath
$cleanupPolicy = Import-PowerShellDataFile -LiteralPath $cleanupPolicyPath
if ($servicePolicy.ServiceScopes.Count -ne 0) {
    throw "Service production scopes were approved unexpectedly: $($servicePolicy.ServiceScopes.Count)"
}
if ($rollbackPolicy.FileScopes.Count -ne 0 -or $rollbackPolicy.RegistryScopes.Count -ne 0) {
    throw 'File or registry production scopes were approved unexpectedly.'
}
if ($trustedPolicy.TrustedInstallerScopes.Count -ne 0) {
    throw "TrustedInstaller production scopes were approved unexpectedly: $($trustedPolicy.TrustedInstallerScopes.Count)"
}
if ($safeModePolicy.SafeModeScopes.Count -ne 0) {
    throw "Safe Mode production scopes were approved unexpectedly: $($safeModePolicy.SafeModeScopes.Count)"
}
if ($rebootPolicy.WorkflowScopes.Count -ne 0) {
    throw "Reboot workflow production scopes were approved unexpectedly: $($rebootPolicy.WorkflowScopes.Count)"
}
if ($artifactPolicy.Artifacts.Count -ne 0) {
    throw "Artifact approvals were added unexpectedly: $($artifactPolicy.Artifacts.Count)"
}
if ($cleanupPolicy.CleanupScopes.Count -ne 0) {
    throw "Cleanup production scopes were approved unexpectedly: $($cleanupPolicy.CleanupScopes.Count)"
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceManifestLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
    Sort-Object {
        $_.FullName.Substring($root.Length + 1).Replace('\', '/')
    } |
    ForEach-Object {
        '{0}|{1}' -f `
            $_.FullName.Substring($root.Length + 1).Replace('\', '/'), `
            (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    }
$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $manifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash(
            [Text.Encoding]::UTF8.GetBytes(($sourceManifestLines -join "`n"))
        )
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}

if (
    @($sourceManifestLines).Count -ne 49 -or
    $manifestHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477'
) {
    throw 'source-ultimate content or paths changed.'
}

$loudnessPath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'
if (Test-Path -LiteralPath $loudnessPath) {
    throw 'Loudness EQ source was reintroduced.'
}
$nvmeSource = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Where-Object { $_.Name -like '*NVME Faster Driver*' }
)
if ($nvmeSource.Count -ne 0) {
    throw 'NVME Faster Driver source was reintroduced.'
}

[pscustomobject]@{
    Success                          = $true
    ToolId                           = 'defender-optimize-assistant'
    SourceHash                       = $actualSourceHash
    RegistryCommandCount             = $registryLines.Count
    ScheduledTaskTargetCount         = $taskTargets.Count
    ActiveToolCount                  = $activeTools.Count
    ImplementedToolCount             = $activeTools.Count - $placeholderModules.Count
    PlaceholderToolCount             = $placeholderModules.Count
    OrderedParityComplete            = [bool]$parityBaseline.OrderedParityComplete
    ProductionServiceScopes          = $servicePolicy.ServiceScopes.Count
    ProductionFileScopes             = $rollbackPolicy.FileScopes.Count
    ProductionRegistryScopes         = $rollbackPolicy.RegistryScopes.Count
    ProductionTrustedInstallerScopes = $trustedPolicy.TrustedInstallerScopes.Count
    ProductionSafeModeScopes         = $safeModePolicy.SafeModeScopes.Count
    ProductionRebootScopes           = $rebootPolicy.WorkflowScopes.Count
    ArtifactApprovals                = $artifactPolicy.Artifacts.Count
    SourceUltimateUnchanged          = $true
    DeletedToolsRemainDeleted        = $true
    Message                          = 'Defender Optimize Assistant exact Ultimate parity implementation is present and tested with mocked side effects.'
    Timestamp                        = Get-Date
}
