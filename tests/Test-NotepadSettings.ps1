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
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\notepad-settings.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\14 Notepad Settings.ps1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

function Assert-BoostLabCondition {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

$sourceHash = '2086D75FAA560C9746B1FA2EDB29AE9A8364633FD6268DEEDBE7FB4720EA39FB'
Assert-BoostLabCondition ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -eq $sourceHash) 'Notepad Settings Ultimate source hash changed.'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration['Stages'] | ForEach-Object { $_['Tools'] })
$tool = $tools | Where-Object { $_['Id'] -eq 'notepad-settings' } | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $tool) 'Notepad Settings metadata is missing.'
Assert-BoostLabCondition ([string]$tool['Stage'] -eq 'Windows') 'Notepad Settings stage is incorrect.'
Assert-BoostLabCondition ([int]$tool['Order'] -eq 14) 'Notepad Settings order is incorrect.'
Assert-BoostLabCondition ([string]$tool['Type'] -eq 'action') 'Notepad Settings type is incorrect.'
Assert-BoostLabCondition ([string]$tool['RiskLevel'] -eq 'medium') 'Notepad Settings risk level is incorrect.'
Assert-BoostLabCondition ((@($tool['Actions']) -join ',') -eq 'Apply,Default') 'Notepad Settings actions are incorrect.'

$trueCapabilities = @('RequiresAdmin', 'CanModifyRegistry', 'CanDeleteFiles', 'SupportsDefault', 'NeedsExplicitConfirmation')
foreach ($field in $tool['Capabilities'].Keys) {
    Assert-BoostLabCondition ([bool]$tool['Capabilities'][$field] -eq ($field -in $trueCapabilities)) "Notepad Settings capability '$field' is incorrect."
}

$source = Get-Content -Raw -LiteralPath $sourcePath
foreach ($requiredText in @(
    'Stop-Process -Name "Notepad" -Force -ErrorAction SilentlyContinue'
    'Start-Sleep -Seconds 2'
    'Set-Content -Path "$env:SystemRoot\Temp\notepadsettings.reg" -Value $NotepadSettings -Force'
    'reg load "HKLM\Settings" $SettingsDat'
    'if ($LASTEXITCODE -eq 0) {'
    'reg import $RegFileNotepadSettings'
    'reg unload "HKLM\Settings"'
    'Remove-Item "$env:LocalAppData\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings\settings.dat" -Force'
)) {
    Assert-BoostLabCondition ($source.Contains($requiredText)) "Notepad Settings source no longer contains: $requiredText"
}
foreach ($forbiddenSourceText in @(
    'Invoke-WebRequest'
    'Get-AppxPackage'
    'Remove-AppxPackage'
    'Get-Service'
    'Get-ScheduledTask'
    'Restart-Computer'
    'Copy-Item'
)) {
    Assert-BoostLabCondition (-not $source.Contains($forbiddenSourceText)) "Notepad Settings source unexpectedly contains unsupported behavior: $forbiddenSourceText"
}

$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredText in @(
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    '$script:BoostLabNotepadProcessName = ''Notepad'''
    'Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings\settings.dat'
    '"OpenFile"=hex(5f5e104):01,00,00,00,d1,55,24,57,d1,84,db,01'
    '"GhostFile"=hex(5f5e10b):00,42,60,f1,5a,d1,84,db,01'
    '"RewriteEnabled"=hex(5f5e10b):00,12,4a,7f,5f,d1,84,db,01'
    'Stop-Process -Name $script:BoostLabNotepadProcessName -Force -ErrorAction SilentlyContinue'
    'Set-Content -LiteralPath $Path -Value $Content -Force -ErrorAction Stop'
    'Remove-Item -LiteralPath $Path -Force -ErrorAction Stop'
    'if ($null -ne $loadResult -and [bool]$loadResult.Success)'
    '[bool]$Confirmed = $false'
    'New-BoostLabVerificationResult'
)) {
    Assert-BoostLabCondition ($moduleSource.Contains($requiredText)) "Notepad Settings module is missing: $requiredText"
}
foreach ($forbiddenText in @(
    'New-BoostLabNotepadNotApplicableResult'
    'NotApplicable'
    'Already default'
    'Backups\NotepadSettings'
    'Backup-BoostLabNotepadSettingsFile'
    'Save-BoostLabNotepadState'
    'BackupWriter'
    'StateWriter'
    'ProgramData\BoostLab\State'
    'Remove-AppxPackage'
    'Get-AppxPackage'
    'Invoke-WebRequest'
    'Start-BitsTransfer'
    'Set-Service'
    'Stop-Service'
    'Restart-Computer'
    'UsesTrustedInstaller = $true'
    'safeboot'
)) {
    Assert-BoostLabCondition (-not $moduleSource.Contains($forbiddenText)) "Notepad Settings module contains non-source behavior: $forbiddenText"
}

$tokens = $null
$parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseFile(
    $modulePath,
    [ref]$tokens,
    [ref]$parseErrors
) | Out-Null
if (@($parseErrors).Count -gt 0) {
    throw "Notepad Settings syntax error: $($parseErrors[0].Message)"
}

$notepadModule = Import-Module -Name $modulePath -Force -PassThru -Prefix 'NotepadTest' -Scope Local -DisableNameChecking -ErrorAction Stop
try {
    $info = Get-NotepadTestBoostLabToolInfo
    Assert-BoostLabCondition ([string]$info.Id -eq 'notepad-settings') 'Notepad Settings exported Id is incorrect.'
    Assert-BoostLabCondition ((@($info.Actions) -join ',') -eq 'Apply,Default') 'Notepad Settings exported actions are incorrect.'
    Assert-BoostLabCondition ((@($info.ImplementedActions) -join ',') -eq 'Apply,Default') 'Notepad Settings implemented actions are incorrect.'
    foreach ($unsupportedAction in @('Open', 'Restore')) {
        Assert-BoostLabCondition (-not ($unsupportedAction -in @($info.Actions) -or $unsupportedAction -in @($info.ImplementedActions))) "Notepad Settings must not expose unsupported action: $unsupportedAction"
    }

    $expectedValues = [ordered]@{
        OpenFile = '01,00,00,00,d1,55,24,57,d1,84,db,01'
        GhostFile = '00,42,60,f1,5a,d1,84,db,01'
        RewriteEnabled = '00,12,4a,7f,5f,d1,84,db,01'
    }
    $newFileState = {
        param([bool]$Exists, [string]$Hash, [string]$Message)
        [pscustomobject]@{
            ReadSucceeded = $true; Exists = $Exists
            Sha256 = $Hash; Length = if ($Exists) { 128 } else { $null }
            Message = $Message
        }
    }
    $processStopper = { [pscustomobject]@{ Success = $true; Status = 'StopRequested'; Message = 'Stop-Process Notepad was invoked with SilentlyContinue, matching Ultimate.' } }
    $delayEvents = [System.Collections.Generic.List[int]]::new()
    $delay = { param($Seconds) $delayEvents.Add([int]$Seconds) }.GetNewClosure()
    $registryWriter = { param($Path, $Content) if ($Content -notmatch 'RewriteEnabled') { throw 'Missing source payload.' } }
    $registryReader = {
        param($Name)
        [pscustomobject]@{
            ReadSucceeded = $true; Exists = $true; Name = $Name
            DisplayValue = [string]$expectedValues[$Name]; Message = 'Mock value detected.'
        }
    }.GetNewClosure()

    $compatibility = & $notepadModule {
        Test-BoostLabToolCompatibility `
            -OperatingSystem 'Windows_NT' `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows' `
            -PathTester {
                param($Path, $PathType)
                if ($Path -eq 'C:\Windows\System32\reg.exe') { return $true }
                if ($Path -eq 'C:\Users\Tester\AppData\Local\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe') { return $true }
                return $false
            }
    }
    Assert-BoostLabCondition ([bool]$compatibility.Supported) 'Notepad Settings compatibility should be supported on Windows with reg.exe.'
    Assert-BoostLabCondition ([bool]$compatibility.Applicable) 'Missing settings.dat must not make Notepad Settings NotApplicable because Ultimate does not gate on it.'
    Assert-BoostLabCondition (-not [bool]$compatibility.SettingsDatExists) 'Mock compatibility should report missing settings.dat.'
    Assert-BoostLabCondition ([string]$compatibility.Reason -match 'Ultimate still attempts') 'Compatibility reason should explain exact source behavior for missing settings.dat.'

    $missingApplyEvents = [System.Collections.Generic.List[string]]::new()
    $missingApplyCommand = {
        param($Operation, $Arguments, $Root)
        $missingApplyEvents.Add("$Operation|$($Arguments -join '|')")
        [pscustomobject]@{ Success = $false; Operation = $Operation; ExitCode = 1 }
    }.GetNewClosure()
    $missingApplyResult = & $notepadModule {
        param($FileState, $ProcessStopper, $Delay, $RegistryWriter, $RegistryCommand)
        Invoke-BoostLabNotepadSettingsAction `
            -ActionName 'Apply' `
            -Confirmed:$true `
            -AdministratorChecker { $true } `
            -FileStateReader { param($Path) $FileState } `
            -ProcessStopper $ProcessStopper `
            -DelayInvoker $Delay `
            -RegistryFileWriter $RegistryWriter `
            -RegistryCommandInvoker $RegistryCommand `
            -RegistryReader { param($Name) throw 'Registry read must not run when reg load fails.' } `
            -FileRemover { param($Path) throw 'Delete must not run during Apply.' } `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows'
    } (& $newFileState $false $null 'File absent.') $processStopper $delay $registryWriter $missingApplyCommand
    Assert-BoostLabCondition ([bool]$missingApplyResult.Success) 'Missing settings.dat Apply must complete the source sequence rather than return NotApplicable.'
    Assert-BoostLabCondition ([string]$missingApplyResult.Status -ne 'NotApplicable') 'Missing settings.dat Apply must not return NotApplicable.'
    Assert-BoostLabCondition ([string]$missingApplyResult.Data.CommandStatus -eq 'Completed') 'Missing settings.dat Apply should report completed source sequence.'
    Assert-BoostLabCondition ([bool]$missingApplyResult.Data.ChangesExecuted) 'Missing settings.dat Apply should report that the source command sequence was executed.'
    Assert-BoostLabCondition (($missingApplyEvents -join ',') -eq 'load|HKLM\Settings|C:\Users\Tester\AppData\Local\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings\settings.dat') "Missing settings.dat Apply must attempt only source reg load before skipping import. Events: $($missingApplyEvents -join ',')"

    $applyEvents = [System.Collections.Generic.List[string]]::new()
    $applyCommand = {
        param($Operation, $Arguments, $Root)
        $applyEvents.Add("$Operation|$($Arguments -join '|')")
        [pscustomobject]@{ Success = $true; Operation = $Operation; ExitCode = 0 }
    }.GetNewClosure()
    $applyResult = & $notepadModule {
        param($FileState, $ProcessStopper, $Delay, $RegistryWriter, $RegistryCommand, $RegistryReader)
        Invoke-BoostLabNotepadSettingsAction `
            -ActionName 'Apply' `
            -Confirmed:$true `
            -AdministratorChecker { $true } `
            -FileStateReader { param($Path) $FileState } `
            -ProcessStopper $ProcessStopper `
            -DelayInvoker $Delay `
            -RegistryFileWriter $RegistryWriter `
            -RegistryCommandInvoker $RegistryCommand `
            -RegistryReader $RegistryReader `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows'
    } (& $newFileState $true 'UPDATED' 'Updated file detected.') $processStopper $delay $registryWriter $applyCommand $registryReader
    Assert-BoostLabCondition ([bool]$applyResult.Success) 'Mocked Notepad Settings Apply did not pass.'
    Assert-BoostLabCondition ([string]$applyResult.Message -eq 'Notepad settings Apply source sequence completed.') 'Apply message should describe source sequence completion.'
    Assert-BoostLabCondition ([string]$applyResult.VerificationResult.Status -eq 'Passed') 'Apply verification should pass for mocked values.'
    Assert-BoostLabCondition ([string]$applyResult.Data.CommandStatus -eq 'Completed') 'Apply command status should be completed.'
    Assert-BoostLabCondition (($applyEvents -join ',') -eq 'load|HKLM\Settings|C:\Users\Tester\AppData\Local\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings\settings.dat,import|C:\Windows\Temp\notepadsettings.reg,unload|HKLM\Settings') "Notepad Settings hive operation order changed: $($applyEvents -join ',')"
    Assert-BoostLabCondition ([string]$applyResult.Data.BackupStatus -match 'does not create a backup') 'Apply must not claim backup creation.'

    $removedPaths = [System.Collections.Generic.List[string]]::new()
    $fileRemover = {
        param($Path)
        $removedPaths.Add($Path)
        [pscustomobject]@{ Success = $true; Message = 'settings.dat delete was invoked.' }
    }.GetNewClosure()
    $defaultResult = & $notepadModule {
        param($FileState, $ProcessStopper, $Delay, $FileRemover)
        Invoke-BoostLabNotepadSettingsAction `
            -ActionName 'Default' `
            -Confirmed:$true `
            -AdministratorChecker { $true } `
            -FileStateReader { param($Path) $FileState } `
            -ProcessStopper $ProcessStopper `
            -DelayInvoker $Delay `
            -FileRemover $FileRemover `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows'
    } (& $newFileState $false $null 'File absent.') $processStopper $delay $fileRemover
    Assert-BoostLabCondition ([bool]$defaultResult.Success) 'Mocked Notepad Settings Default did not pass.'
    Assert-BoostLabCondition ([string]$defaultResult.Message -eq 'Notepad settings Default source sequence completed.') 'Default message should describe source sequence completion.'
    Assert-BoostLabCondition ([string]$defaultResult.VerificationResult.Status -eq 'Passed') 'Default verification should pass when settings.dat is absent after delete.'
    Assert-BoostLabCondition ($removedPaths.Count -eq 1) 'Default must attempt exactly one delete operation.'
    Assert-BoostLabCondition ($removedPaths[0] -eq 'C:\Users\Tester\AppData\Local\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings\settings.dat') 'Default must delete only the exact source settings.dat path.'
    Assert-BoostLabCondition ([bool]$defaultResult.Data.ChangesExecuted) 'Default must not report an already-default short circuit.'
    Assert-BoostLabCondition ([string]$defaultResult.Data.BackupStatus -match 'does not create a backup') 'Default must not claim backup creation.'

    $missingDefaultEvents = [System.Collections.Generic.List[string]]::new()
    $missingDefaultRemover = {
        param($Path)
        $missingDefaultEvents.Add("DELETE|$Path")
        [pscustomobject]@{ Success = $false; Message = 'Cannot find path.' }
    }.GetNewClosure()
    $missingDefaultResult = & $notepadModule {
        param($FileState, $ProcessStopper, $Delay, $FileRemover)
        Invoke-BoostLabNotepadSettingsAction `
            -ActionName 'Default' `
            -Confirmed:$true `
            -AdministratorChecker { $true } `
            -FileStateReader { param($Path) $FileState } `
            -ProcessStopper $ProcessStopper `
            -DelayInvoker $Delay `
            -FileRemover $FileRemover `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows'
    } (& $newFileState $false $null 'File absent.') $processStopper $delay $missingDefaultRemover
    Assert-BoostLabCondition ([bool]$missingDefaultResult.Success) 'Missing settings.dat Default should still complete if the file is absent after the source delete attempt.'
    Assert-BoostLabCondition ([string]$missingDefaultResult.Status -ne 'NotApplicable') 'Missing settings.dat Default must not return NotApplicable.'
    Assert-BoostLabCondition ([string]$missingDefaultResult.Data.CommandStatus -eq 'Completed') 'Missing settings.dat Default should report completed source sequence.'
    Assert-BoostLabCondition ([bool]$missingDefaultResult.Data.ChangesExecuted) 'Missing settings.dat Default should report that the source delete action was attempted.'
    Assert-BoostLabCondition ($missingDefaultEvents.Count -eq 1) 'Missing settings.dat Default must still attempt the source delete action.'
}
finally {
    Remove-Module -ModuleInfo $notepadModule -Force -ErrorAction SilentlyContinue
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
$actionPlanSource = Get-Content -Raw -LiteralPath $actionPlanPath
$uiSource = Get-Content -Raw -LiteralPath $uiPath
foreach ($requiredText in @(
    '''notepad-settings'' = @{'
    'Windows\notepad-settings.psm1'
)) {
    Assert-BoostLabCondition ($executionSource.Contains($requiredText)) "Execution runtime is missing Notepad Settings integration: $requiredText"
}
foreach ($requiredText in @(
    'Stop only the Notepad process and wait for the source-defined two-second delay.'
    'Do not create a backup or state record because Ultimate does not define backup or Restore behavior.'
    'Running Notepad is closed and unsaved Notepad work can be lost.'
)) {
    Assert-BoostLabCondition ($actionPlanSource.Contains($requiredText)) "Action Plan is missing exact Notepad Settings text: $requiredText"
}
foreach ($forbiddenPlanText in @(
    'Create and verify a unique backup of the exact Notepad settings.dat'
    'Persist the target path, original hash, backup hash'
    'Treat an already-absent settings.dat as the approved default state'
)) {
    Assert-BoostLabCondition (-not $actionPlanSource.Contains($forbiddenPlanText)) "Action Plan still contains non-source Notepad behavior: $forbiddenPlanText"
}
foreach ($requiredText in @(
    '$toolId -eq ''notepad-settings'''
    '''Backup status'''
    '''File disposition'''
    '''settings.dat exists'''
    '''Changes executed'''
)) {
    Assert-BoostLabCondition ($uiSource.Contains($requiredText)) "Latest Result is missing Notepad Settings output: $requiredText"
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    $plan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Default' -IsDryRun:$false
    Assert-BoostLabCondition ([bool]$plan.NeedsExplicitConfirmation) 'Notepad Settings Default must still require Action Plan confirmation.'
    Assert-BoostLabCondition ([bool]$plan.RequiresAdmin) 'Notepad Settings Default must still require administrator execution.'
    Assert-BoostLabCondition ([bool]$plan.Capabilities.CanDeleteFiles) 'Notepad Settings Default must retain file-delete capability metadata.'
    Assert-BoostLabCondition ((@($plan.PlannedChanges) -join ' ') -notmatch 'Create and verify.*backup') 'Notepad Settings Action Plan must not claim a backup.'
    Assert-BoostLabCondition ([string]$plan.ConfirmationMessage -match 'source-defined delete action') 'Notepad Settings Action Plan confirmation must describe source delete behavior.'
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$notepadRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'notepad-settings' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $notepadRecord) 'Notepad Settings parity baseline record is missing.'
Assert-BoostLabCondition ([string]$notepadRecord.RuntimeStatus -eq 'RuntimeImplemented') 'Notepad Settings runtime status is incorrect.'
Assert-BoostLabCondition ([string]$notepadRecord.ImplementationLevel -eq 'ParityImplemented') 'Notepad Settings must be exact ParityImplemented.'
Assert-BoostLabCondition ([string]$notepadRecord.UltimateParity -eq 'Yes') 'Notepad Settings UltimateParity must be Yes.'
Assert-BoostLabCondition (-not [bool]$notepadRecord.YazanFinalException) 'Notepad Settings must not use a Yazan final exception.'
Assert-BoostLabCondition ($null -eq $notepadRecord.PSObject.Properties['YazanAcceptedNearParity']) 'Notepad Settings must not claim YazanAcceptedNearParity.'
Assert-BoostLabCondition ([string]$notepadRecord.FinalProgressStatus -eq 'DoneParity') 'Notepad Settings final status must be DoneParity.'
Assert-BoostLabCondition ([string]$notepadRecord.NextParityAction -eq 'DoneParity') 'Notepad Settings next action must be DoneParity.'

$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ([string]$parityBaseline.CurrentOrderedParityTarget -eq [string]$nextTarget.ToolId) 'Current ordered parity target must match the derived first non-final target.'
Assert-BoostLabCondition ([string]$parityBaseline.CurrentOrderedParityTarget -eq 'control-panel-settings') 'Current ordered parity target must advance to Control Panel Settings after exact Notepad parity.'

$categoryCounts = @{}
foreach ($record in @($parityBaseline.Tools)) {
    $level = [string]$record.ImplementationLevel
    if (-not $categoryCounts.ContainsKey($level)) {
        $categoryCounts[$level] = 0
    }
    $categoryCounts[$level]++
}
Assert-BoostLabCondition ([int]$categoryCounts['ParityImplemented'] -eq [int]$parityBaseline.Counts.UltimateParityImplemented) 'Ultimate parity implemented count mismatch.'
Assert-BoostLabCondition ([int]$categoryCounts['NearParityControlled'] -eq [int]$parityBaseline.Counts.NearParityControlled) 'NearParityControlled count mismatch.'

$implementedCount = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'modules') -Recurse -File -Filter '*.psm1' |
        Where-Object { $_.Directory.Parent.FullName -eq (Join-Path $ProjectRoot 'modules') } |
        Where-Object { (Get-Content -Raw -LiteralPath $_.FullName).Contains('$script:BoostLabImplementedActions') }
).Count
$placeholderCount = $inventoryBaseline.ActiveTools - $implementedCount
Assert-BoostLabCondition ($implementedCount -eq $inventoryBaseline.ImplementedTools) 'Implemented tool count changed unexpectedly.'
Assert-BoostLabCondition ($placeholderCount -eq $inventoryBaseline.DeferredPlaceholders) 'Placeholder count changed unexpectedly.'

$deletedNames = @('Loudness EQ', 'Windows Activation Helper', 'Firewall', 'DEP', 'DDU', 'UAC')
$normalizedCatalog = @($tools | ForEach-Object { ([string]$_['Title'] -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant() })
foreach ($deletedName in $deletedNames) {
    Assert-BoostLabCondition (-not (((($deletedName -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()) -in $normalizedCatalog))) "Deleted tool returned to the catalog: $deletedName"
}
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $sourceRoot '5 Graphics\NVME Faster Driver.ps1'))) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    Test = 'Notepad Settings'
    Passed = $true
    SourceHash = $sourceHash
    ImplementedCount = $implementedCount
    PlaceholderCount = $placeholderCount
    CurrentOrderedParityTarget = [string]$parityBaseline.CurrentOrderedParityTarget
    FinalProgressStatus = [string]$notepadRecord.FinalProgressStatus
    Message = 'Notepad Settings passed exact Ultimate parity validation with mocked source-equivalent Apply and Default actions.'
}
