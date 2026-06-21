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
        throw 'Unable to determine the Cleanup test script path.'
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

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\cleanup.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\22 Cleanup.ps1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$migrationPath = Join-Path $ProjectRoot 'docs\migrations\cleanup.md'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$modulesRoot = Join-Path $ProjectRoot 'modules'

$expectedSourceHash = '3419A995AD4483A145999B659268302F02BE982733DE831554ADA1C40F07CCAA'
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot
$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$parityOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot

foreach ($path in @($configPath, $modulePath, $sourcePath, $actionPlanPath, $executionPath, $migrationPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required file is missing: $path"
}

Assert-BoostLabCondition ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -eq $expectedSourceHash) 'Cleanup Ultimate source hash changed.'
$source = Get-Content -Raw -LiteralPath $sourcePath
foreach ($requiredSourceText in @(
    'Remove-Item -Path "$env:USERPROFILE\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue',
    'Remove-Item -Path "$env:SystemDrive\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue',
    'Remove-Item "$env:SystemDrive\inetpub" -Recurse -Force -ErrorAction SilentlyContinue',
    'Remove-Item "$env:SystemDrive\PerfLogs" -Recurse -Force -ErrorAction SilentlyContinue',
    'Remove-Item "$env:SystemDrive\Windows.old" -Recurse -Force -ErrorAction SilentlyContinue',
    'Remove-Item "$env:SystemDrive\DumpStack.log" -Force -ErrorAction SilentlyContinue',
    'Start-Process cleanmgr.exe'
)) {
    Assert-BoostLabCondition ($source.Contains($requiredSourceText)) "Cleanup source is missing: $requiredSourceText"
}
foreach ($forbiddenSourceText in @(
    'Invoke-WebRequest',
    'Invoke-RestMethod',
    'Start-BitsTransfer',
    'reg add',
    'reg delete',
    'Set-Service',
    'Stop-Service',
    'Unregister-ScheduledTask',
    'Restart-Computer',
    'shutdown.exe',
    'DISM',
    'Clear-RecycleBin'
)) {
    Assert-BoostLabCondition (-not $source.Contains($forbiddenSourceText)) "Cleanup source contains unexpected behavior: $forbiddenSourceText"
}

$config = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($config.Stages | ForEach-Object { @($_.Tools) })
$tool = @($tools | Where-Object { [string]$_.Id -eq 'cleanup' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $tool) 'Cleanup stage metadata is missing.'
Assert-BoostLabCondition ([string]$tool.Stage -eq 'Windows') 'Cleanup must remain in Windows stage.'
Assert-BoostLabCondition ([int]$tool.Order -eq 21) 'Cleanup order changed.'
Assert-BoostLabCondition ([string]$tool.Type -eq 'action') 'Cleanup must remain an action tool.'
Assert-BoostLabCondition ([string]$tool.RiskLevel -eq 'high') 'Cleanup must be high risk.'
Assert-BoostLabCondition ((@($tool.Actions) -join ',') -eq 'Apply') 'Cleanup must expose only source-defined Apply.'
$expectedTrueCapabilities = @('RequiresAdmin', 'CanDeleteFiles', 'NeedsExplicitConfirmation')
foreach ($capabilityName in @($tool.Capabilities.Keys)) {
    Assert-BoostLabCondition ([bool]$tool.Capabilities[$capabilityName] -eq ($capabilityName -in $expectedTrueCapabilities)) "Cleanup capability '$capabilityName' is incorrect."
}

$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredModuleText in @(
    '$script:BoostLabImplementedActions = @(''Apply'')',
    '$script:BoostLabExpectedSourceHash',
    'Get-BoostLabCleanupTargets',
    'Invoke-BoostLabCleanupRemoveTarget',
    'Test-BoostLabCleanupState',
    'Invoke-BoostLabCleanupApply',
    'Remove-Item -Path ([string]$Target.Path) -Recurse -Force -ErrorAction SilentlyContinue',
    'Start-Process ''cleanmgr.exe''',
    'SupportsDefault           = $false',
    'SupportsRestore           = $false'
)) {
    Assert-BoostLabCondition ($moduleSource.Contains($requiredModuleText)) "Cleanup module is missing: $requiredModuleText"
}
foreach ($forbiddenModuleText in @(
    'ToolModule.Placeholder.ps1',
    'Invoke-WebRequest',
    'Invoke-RestMethod',
    'Start-BitsTransfer',
    'Restart-Computer',
    'shutdown.exe',
    'Set-Service',
    'Stop-Service',
    'Unregister-ScheduledTask',
    'Clear-RecycleBin',
    'SupportsDefault           = $true',
    'SupportsRestore           = $true',
    'UsesTrustedInstaller      = $true',
    'UsesSafeMode              = $true'
)) {
    Assert-BoostLabCondition (-not $moduleSource.Contains($forbiddenModuleText)) "Cleanup module contains forbidden behavior: $forbiddenModuleText"
}

$tokens = $null
$parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseFile($modulePath, [ref]$tokens, [ref]$parseErrors) | Out-Null
if (@($parseErrors).Count -gt 0) {
    throw "Cleanup module syntax error: $($parseErrors[0].Message)"
}

$module = Import-Module -Name $modulePath -Force -PassThru -Prefix 'CleanupTest' -Scope Local -DisableNameChecking -ErrorAction Stop
try {
    $toolInfo = & (Get-Command -Name 'Get-CleanupTestBoostLabToolInfo' -Module $module.Name -ErrorAction Stop)
    Assert-BoostLabCondition ([string]$toolInfo.Id -eq 'cleanup') 'Cleanup exported metadata id is incorrect.'
    Assert-BoostLabCondition ((@($toolInfo.Actions) -join ',') -eq 'Apply') 'Cleanup exported actions are incorrect.'
    Assert-BoostLabCondition ((@($toolInfo.ImplementedActions) -join ',') -eq 'Apply') 'Cleanup implemented actions are incorrect.'

    $targets = @(& $module {
        Get-BoostLabCleanupTargets -UserProfile 'C:\Users\BoostLabTest' -SystemDrive 'C:'
    })
    Assert-BoostLabCondition ($targets.Count -eq 6) "Cleanup must expose six source cleanup targets, found $($targets.Count)."
    $expectedTargets = @(
        '$env:USERPROFILE\AppData\Local\Temp\*',
        '$env:SystemDrive\Windows\Temp\*',
        '$env:SystemDrive\inetpub',
        '$env:SystemDrive\PerfLogs',
        '$env:SystemDrive\Windows.old',
        '$env:SystemDrive\DumpStack.log'
    )
    foreach ($expectedTarget in $expectedTargets) {
        Assert-BoostLabCondition ($expectedTarget -in @($targets.SourceExpression)) "Cleanup target is missing: $expectedTarget"
    }

    $events = [System.Collections.Generic.List[string]]::new()
    $mockTargetProvider = { return $targets }.GetNewClosure()
    $mockTargetRemover = {
        param($Target)
        $events.Add("DELETE:$($Target.Id):$($Target.Path)")
        return [pscustomobject]@{ Succeeded = $true; Message = 'Mock delete completed.' }
    }.GetNewClosure()
    $mockStateReader = {
        param($Target)
        $events.Add("VERIFY:$($Target.Id)")
        return [pscustomobject]@{
            ReadSucceeded = $true
            Exists = $false
            ItemCount = 0
            DisplayValue = 'Absent'
            Message = 'Mock target absent.'
        }
    }.GetNewClosure()
    $mockCleanMgr = {
        $events.Add('OPEN:cleanmgr.exe')
    }.GetNewClosure()

    $applyResult = & $module {
        param($TargetProvider, $TargetRemover, $StateReader, $CleanMgr)
        Invoke-BoostLabCleanupApply `
            -AdministratorChecker { return $true } `
            -TargetProvider $TargetProvider `
            -TargetRemover $TargetRemover `
            -TargetStateReader $StateReader `
            -CleanMgrLauncher $CleanMgr
    } $mockTargetProvider $mockTargetRemover $mockStateReader $mockCleanMgr

    Assert-BoostLabCondition ([bool]$applyResult.Success) 'Mocked Cleanup Apply did not succeed.'
    Assert-BoostLabCondition ([string]$applyResult.Status -eq 'Passed') 'Mocked Cleanup Apply did not pass.'
    Assert-BoostLabCondition ([string]$applyResult.Data.CommandStatus -eq 'Completed') 'Cleanup command status is incorrect.'
    Assert-BoostLabCondition ([string]$applyResult.VerificationResult.Status -eq 'Passed') 'Cleanup verification did not pass.'
    Assert-BoostLabCondition (@($applyResult.Data.TargetsAttempted).Count -eq 6) 'Cleanup did not attempt all six source targets.'
    Assert-BoostLabCondition (@($applyResult.Data.TargetsRemoved).Count -eq 6) 'Cleanup did not complete all six mocked target removals.'
    Assert-BoostLabCondition ([string]$applyResult.Data.CleanMgrStatus -eq 'Launched') 'Cleanup did not report cleanmgr launch.'
    Assert-BoostLabCondition (@($events | Where-Object { $_ -like 'DELETE:*' }).Count -eq 6) 'Cleanup test did not route deletions through the mock remover.'
    Assert-BoostLabCondition (@($events | Where-Object { $_ -like 'VERIFY:*' }).Count -eq 6) 'Cleanup test did not route verification through the mock reader.'
    $sourceOperationEvents = @($events | Where-Object { $_ -like 'DELETE:*' -or $_ -eq 'OPEN:cleanmgr.exe' })
    Assert-BoostLabCondition ($sourceOperationEvents[$sourceOperationEvents.Count - 1] -eq 'OPEN:cleanmgr.exe') 'Cleanup command ordering changed; cleanmgr must be the final source operation.'

    $remainingStateReader = {
        param($Target)
        return [pscustomobject]@{
            ReadSucceeded = $true
            Exists = ([string]$Target.Id -eq 'WindowsOldDirectory')
            ItemCount = if ([string]$Target.Id -eq 'WindowsOldDirectory') { 1 } else { 0 }
            DisplayValue = if ([string]$Target.Id -eq 'WindowsOldDirectory') { 'Present' } else { 'Absent' }
            Message = 'Mock state.'
        }
    }
    $remainingResult = & $module {
        param($TargetProvider, $TargetRemover, $StateReader, $CleanMgr)
        Invoke-BoostLabCleanupApply `
            -AdministratorChecker { return $true } `
            -TargetProvider $TargetProvider `
            -TargetRemover $TargetRemover `
            -TargetStateReader $StateReader `
            -CleanMgrLauncher $CleanMgr
    } $mockTargetProvider $mockTargetRemover $remainingStateReader $mockCleanMgr
    Assert-BoostLabCondition (-not [bool]$remainingResult.Success) 'Cleanup Apply should fail when a target remains.'
    Assert-BoostLabCondition ([string]$remainingResult.VerificationResult.Status -eq 'Failed') 'Cleanup remaining-target verification must fail.'

    $cancelled = & (Get-Command -Name 'Invoke-CleanupTestBoostLabToolAction' -Module $module.Name -ErrorAction Stop) -ActionName 'Apply' -Confirmed:$false
    Assert-BoostLabCondition (-not [bool]$cancelled.Success -and [bool]$cancelled.Cancelled) 'Cleanup Apply without confirmation must cancel.'
    Assert-BoostLabCondition (-not [bool]$cancelled.Data.ChangesExecuted) 'Cancelled Cleanup Apply must not execute changes.'

    $restoreBlocked = & (Get-Command -Name 'Restore-CleanupTestBoostLabToolDefault' -Module $module.Name -ErrorAction Stop) -Confirmed:$true
    Assert-BoostLabCondition (-not [bool]$restoreBlocked.Success) 'Cleanup Restore/Default helper must remain unavailable.'
    Assert-BoostLabCondition ([string]$restoreBlocked.Message -match 'no source-defined Default or Restore') 'Cleanup Restore/Default wording is incorrect.'
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    $plan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Apply' -IsDryRun $false
    Assert-BoostLabCondition ([bool]$plan.RequiresAdmin) 'Cleanup Action Plan must require Administrator.'
    Assert-BoostLabCondition ([bool]$plan.NeedsExplicitConfirmation) 'Cleanup Action Plan must require confirmation.'
    Assert-BoostLabCondition ([bool]$plan.Capabilities.CanDeleteFiles) 'Cleanup Action Plan must declare file deletion.'
    Assert-BoostLabCondition (-not [bool]$plan.Capabilities.CanModifyRegistry) 'Cleanup Action Plan must not declare registry mutation.'
    Assert-BoostLabCondition (-not [bool]$plan.CanReboot) 'Cleanup Action Plan must not declare reboot.'
    $planText = @($plan.PlannedChanges + $plan.SideEffects + $plan.ConfirmationMessage) -join ' '
    foreach ($needle in @('Temp', 'Windows.old', 'DumpStack.log', 'cleanmgr.exe', 'no Default or Restore', 'No registry')) {
        Assert-BoostLabCondition ($planText -match [regex]::Escape($needle)) "Cleanup Action Plan is missing: $needle"
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredExecutionText in @(
    '''cleanup'' = @{',
    '''Windows\cleanup.psm1''',
    'Actions = @(''Apply'')'
)) {
    Assert-BoostLabCondition ($executionSource.Contains($requiredExecutionText)) "Cleanup runtime mapping is missing: $requiredExecutionText"
}

$migrationText = Get-Content -Raw -LiteralPath $migrationPath
foreach ($requiredMigrationText in @(
    'source-ultimate/6 Windows/22 Cleanup.ps1',
    $expectedSourceHash,
    'Yazan approved complete exact Ultimate parity',
    'BoostLab preserves the source as one `Apply` action',
    'Cleanup has no source-defined Default branch',
    'no captured-state Restore contract',
    'Start-Process cleanmgr.exe',
    'Automated tests use static inspection and injected mocks only.'
)) {
    Assert-BoostLabCondition ($migrationText.Contains($requiredMigrationText)) "Cleanup migration record is missing: $requiredMigrationText"
}

$cleanupParityRecord = @(
    $parityBaseline.Tools |
        Where-Object { [string]$_.ToolId -eq 'cleanup' }
) | Select-Object -First 1
Assert-BoostLabCondition (
    $null -ne $cleanupParityRecord -and
    [string]$cleanupParityRecord.RuntimeStatus -eq 'RuntimeImplemented' -and
    [string]$cleanupParityRecord.ImplementationLevel -eq 'ParityImplemented' -and
    [string]$cleanupParityRecord.UltimateParity -eq 'Yes' -and
    -not [bool]$cleanupParityRecord.YazanFinalException -and
    [string]$cleanupParityRecord.FinalProgressStatus -eq 'DoneParity' -and
    [string]$cleanupParityRecord.NextParityAction -eq 'DoneParity'
) 'Cleanup parity baseline was not finalized as exact parity.'

$nextOrderedParityTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $parityOrder
Assert-BoostLabCondition (
    $null -ne $nextOrderedParityTarget -and
    [string]$nextOrderedParityTarget.ToolId -eq [string]$parityBaseline.CurrentOrderedParityTarget
) 'Cleanup did not advance to the central first non-final ordered parity target.'
$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
Assert-BoostLabCondition ([int]$categoryCounts['ParityImplemented'] -eq [int]$parityBaseline.Counts.UltimateParityImplemented) 'ParityImplemented count mismatch.'
Assert-BoostLabCondition ([int]$categoryCounts['DeferredForParityWork'] -eq [int]$parityBaseline.Counts.DeferredForParityWork) 'DeferredForParityWork count mismatch.'

$allModules = @(
    Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1' |
        Where-Object { $_.Directory.Parent.FullName -eq $modulesRoot }
)
$implementedModules = @($allModules | Where-Object { (Get-Content -Raw -LiteralPath $_.FullName).Contains('$script:BoostLabImplementedActions') })
$placeholderModules = @($allModules | Where-Object { (Get-Content -Raw -LiteralPath $_.FullName).Contains('ToolModule.Placeholder.ps1') })
Assert-BoostLabCondition ($implementedModules.Count -eq $inventoryBaseline.ImplementedTools) 'Implemented module count mismatch.'
Assert-BoostLabCondition ($placeholderModules.Count -eq $inventoryBaseline.DeferredPlaceholders) 'Placeholder module count mismatch.'

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
        ForEach-Object { '{0}|{1}' -f $_.FullName.Substring($root.Length + 1).Replace('\', '/'), (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash }
)
$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $sourceManifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n")))
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}
Assert-BoostLabCondition ($sourceLines.Count -eq 49 -and $sourceManifestHash -eq '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') 'source-ultimate content or paths changed.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File -Filter '*NVME Faster Driver*.ps1').Count -eq 0) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    Success                    = $true
    ToolId                     = 'cleanup'
    SourceHash                 = $expectedSourceHash
    ImplementedActions         = @('Apply')
    ApplyExecuted              = $false
    MockTargetCount            = $targets.Count
    MockedApplyPassed          = $true
    DefaultExposed             = $false
    RestoreExposed             = $false
    ImplementedModuleCount     = $implementedModules.Count
    PlaceholderModuleCount     = $placeholderModules.Count
    UltimateParityImplemented  = $parityBaseline.Counts.UltimateParityImplemented
    DeferredForParityWork      = $parityBaseline.Counts.DeferredForParityWork
    CurrentOrderedParityTarget = $parityBaseline.CurrentOrderedParityTarget
    SourceUltimateUnchanged    = $true
    DeletedToolsRemainDeleted  = $true
    Message                    = 'Cleanup exact parity was validated with static inspection and injected mocks only.'
    Timestamp                  = Get-Date
}
