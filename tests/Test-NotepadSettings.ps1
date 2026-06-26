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

$sourceHash = 'CF139B4C5C96F57A2031F0CB9EDAC04E0F3CF86691BDC47F78DF5B45B76C1BA1'
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
    'Set-Content -LiteralPath $Path -Value $Content -Encoding Unicode -Force -ErrorAction Stop'
    'Remove-Item -LiteralPath $Path -Force -ErrorAction Stop'
    'Invoke-BoostLabNotepadSettingsHiveImport'
    'FinalStatusReason'
    'NativeExitCodeMissing'
    'ExitCodeCaptured'
    'HiveOperations'
    'RegistryValuesChecked'
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
    $continuousRegQueryValues = [ordered]@{
        OpenFile = '01000000D1552457D184DB01'
        GhostFile = '004260F15AD184DB01'
        RewriteEnabled = '00124A7F5FD184DB01'
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

    $notepadSettingsDatPath = 'C:\Users\Tester\AppData\Local\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings\settings.dat'
    $notepadRegFilePath = 'C:\Windows\Temp\notepadsettings.reg'
    $hiveMountAbsent = { [pscustomobject]@{ Exists = $false; CanUnload = $true; Message = 'No mock HKLM:\Settings mount.' } }
    $pathTesterPresent = { param($Path, $PathType) return ($Path -eq $notepadSettingsDatPath) }
    $pathTesterMissing = { param($Path, $PathType) return $false }
    $registryWriter = {
        param($Path, $Content)
        if ($Path -ne $notepadRegFilePath) {
            throw "Unexpected registry file path: $Path"
        }
        if ($Content -notmatch 'RewriteEnabled') {
            throw 'Missing source payload.'
        }
    }
    $registryReader = {
        param($Name)
        [pscustomobject]@{
            ReadSucceeded = $true; Exists = $true; Name = $Name
            DisplayValue = [string]$expectedValues[$Name]; Message = 'Mock value detected.'
        }
    }.GetNewClosure()

    $regQueryOutput = @'
HKEY_LOCAL_MACHINE\Settings\LocalState
    GhostFile    REG_5F5E10B    00 42 60 f1 5a d1
        84 db 01
'@
    $regQueryState = & $notepadModule {
        param($Output)
        ConvertFrom-BoostLabNotepadRegQueryOutput -Output $Output -Name 'GhostFile'
    } $regQueryOutput
    Assert-BoostLabCondition ([string]$regQueryState.ReadMethod -eq 'reg query') 'Notepad Settings reg query fallback must report reg query as the read method.'
    Assert-BoostLabCondition ([string]$regQueryState.ValueType -eq 'REG_5F5E10B') 'Notepad Settings reg query fallback must preserve custom value type.'
    Assert-BoostLabCondition ([string]$regQueryState.DisplayValue -eq $expectedValues['GhostFile']) 'Notepad Settings reg query fallback must normalize custom value bytes.'

    foreach ($valueName in @('OpenFile', 'GhostFile', 'RewriteEnabled')) {
        $byteComparison = & $notepadModule {
            param($Expected, $Actual)
            Compare-BoostLabNotepadByteDisplay -Expected $Expected -Actual $Actual
        } $expectedValues[$valueName] $continuousRegQueryValues[$valueName]
        Assert-BoostLabCondition ([bool]$byteComparison.ByteComparisonSucceeded) "Notepad Settings $valueName REG_NONE bytes should match continuous reg-query hex after normalization."
        Assert-BoostLabCondition ([string]$byteComparison.ExpectedBytesNormalized -eq [string]$byteComparison.ActualBytesNormalized) "Notepad Settings $valueName normalized bytes should match."
    }

    $mixedWhitespaceComparison = & $notepadModule {
        Compare-BoostLabNotepadByteDisplay -Expected ' 01, 00, 00, 00, D1,55,24,57,d1,84,db,01 ' -Actual '01000000d1552457D184DB01'
    }
    Assert-BoostLabCondition ([bool]$mixedWhitespaceComparison.ByteComparisonSucceeded) 'Notepad Settings byte comparison must accept whitespace and mixed hex casing.'

    $missingApplyEvents = [System.Collections.Generic.List[string]]::new()
    $missingApplyResult = & $notepadModule {
        param($FileState, $ProcessStopper, $Delay, $RegistryWriter, $PathTester, $HiveMountReader, $Events)
        Invoke-BoostLabNotepadSettingsAction `
            -ActionName 'Apply' `
            -Confirmed:$true `
            -AdministratorChecker { $true } `
            -FileStateReader { param($Path) $FileState } `
            -ProcessStopper $ProcessStopper `
            -DelayInvoker $Delay `
            -RegistryFileWriter $RegistryWriter `
            -RegistryCommandInvoker { param($Operation, $Arguments, $Root) $Events.Add("$Operation|$($Arguments -join '|')"); throw 'Registry commands must not run when settings.dat is missing.' } `
            -RegistryReader { param($Name) throw 'Registry read must not run when settings.dat is missing.' } `
            -FileRemover { param($Path) throw 'Delete must not run during Apply.' } `
            -PathTester $PathTester `
            -HiveMountReader $HiveMountReader `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows'
    } (& $newFileState $false $null 'File absent.') $processStopper $delay $registryWriter $pathTesterMissing $hiveMountAbsent $missingApplyEvents
    Assert-BoostLabCondition (-not [bool]$missingApplyResult.Success) 'Missing settings.dat Apply must fail closed.'
    Assert-BoostLabCondition ([string]$missingApplyResult.Status -eq 'Failed') 'Missing settings.dat Apply must report Failed.'
    Assert-BoostLabCondition ([string]$missingApplyResult.Data.CommandStatus -eq 'Failed') 'Missing settings.dat Apply command status must fail.'
    Assert-BoostLabCondition (-not [bool]$missingApplyResult.Data.SettingsDatExists) 'Missing settings.dat Apply must report SettingsDatExists false.'
    Assert-BoostLabCondition ([string]$missingApplyResult.Data.FinalStatusReason -eq 'SettingsDatMissing') 'Missing settings.dat Apply must report SettingsDatMissing.'
    Assert-BoostLabCondition (@($missingApplyResult.Data.HiveOperations).Count -eq 0) 'Missing settings.dat Apply must not run reg load/import/unload.'
    Assert-BoostLabCondition ($missingApplyEvents.Count -eq 0) 'Missing settings.dat Apply must not invoke registry commands.'

    $applyEvents = [System.Collections.Generic.List[string]]::new()
    $applyCommand = {
        param($Operation, $Arguments, $Root)
        $applyEvents.Add("$Operation|$($Arguments -join '|')")
        [pscustomobject]@{ Success = $true; Operation = $Operation; ExitCode = 0; Output = @('The operation completed successfully.') }
    }.GetNewClosure()
    $applyReader = {
        param($Name)
        $applyEvents.Add("read|$Name")
        [pscustomobject]@{
            ReadSucceeded = $true; Exists = $true; Name = $Name
            DisplayValue = [string]$expectedValues[$Name]; Message = 'Mock value detected.'
        }
    }.GetNewClosure()
    $applyResult = & $notepadModule {
        param($FileState, $ProcessStopper, $Delay, $RegistryWriter, $RegistryCommand, $RegistryReader, $PathTester, $HiveMountReader)
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
            -PathTester $PathTester `
            -HiveMountReader $HiveMountReader `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows'
    } (& $newFileState $true 'UPDATED' 'Updated file detected.') $processStopper $delay $registryWriter $applyCommand $applyReader $pathTesterPresent $hiveMountAbsent
    Assert-BoostLabCondition ([bool]$applyResult.Success) 'Mocked Notepad Settings Apply did not pass.'
    Assert-BoostLabCondition ([string]$applyResult.Message -eq 'Notepad settings Apply source sequence completed.') 'Apply message should describe source sequence completion.'
    Assert-BoostLabCondition ([string]$applyResult.VerificationResult.Status -eq 'Passed') 'Apply verification should pass for mocked values.'
    Assert-BoostLabCondition ([string]$applyResult.Data.CommandStatus -eq 'Completed') 'Apply command status should be completed.'
    Assert-BoostLabCondition (($applyEvents -join ',') -eq 'load|HKLM\Settings|C:\Users\Tester\AppData\Local\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings\settings.dat,import|C:\Windows\Temp\notepadsettings.reg,read|OpenFile,read|GhostFile,read|RewriteEnabled,unload|HKLM\Settings') "Notepad Settings hive operation/value-read order changed: $($applyEvents -join ',')"
    Assert-BoostLabCondition ([string]$applyResult.Data.FinalStatusReason -eq 'HiveImportVerified') 'Apply must report verified hive import as the final status reason.'
    Assert-BoostLabCondition ([string]$applyResult.Data.RegFileEncoding -eq 'Unicode') 'Apply must report Unicode .reg writing.'
    Assert-BoostLabCondition (@($applyResult.Data.RegistryValuesChecked).Count -eq 3) 'Apply must verify all three source-defined Notepad values before unload.'
    Assert-BoostLabCondition (@($applyResult.Data.HiveOperations | Where-Object { [bool]$_.ExitCodeCaptured -and [int]$_.ExitCode -eq 0 }).Count -eq 3) 'Apply load/import/unload must all capture ExitCode 0.'
    $applyImportOperation = @($applyResult.Data.HiveOperations | Where-Object { [string]$_.Stage -eq 'ImportNotepadSettingsPayload' }) | Select-Object -First 1
    Assert-BoostLabCondition ($null -ne $applyImportOperation) 'Apply must record ImportNotepadSettingsPayload.'
    Assert-BoostLabCondition ([bool]$applyImportOperation.Success) 'Import with native success output and ExitCode 0 must pass.'
    Assert-BoostLabCondition ([string]$applyImportOperation.StandardOutput -like '*operation completed successfully*') 'Import operation must preserve native success output as diagnostics.'
    Assert-BoostLabCondition ([string]$applyResult.Data.BackupStatus -match 'does not create a backup') 'Apply must not claim backup creation.'

    $accessDeniedEvents = [System.Collections.Generic.List[string]]::new()
    $accessDeniedProcessActions = [System.Collections.Generic.List[string]]::new()
    $accessDeniedStopper = {
        $accessDeniedProcessActions.Add('Stop-Notepad')
        [pscustomobject]@{ Success = $true; Status = 'StopRequested'; Message = 'Stop-Process Notepad was invoked with SilentlyContinue, matching Ultimate.' }
    }.GetNewClosure()
    $accessDeniedCommand = {
        param($Operation, $Arguments, $Root)
        $accessDeniedEvents.Add("$Operation|$($Arguments -join '|')")
        [pscustomobject]@{ Success = $false; Operation = $Operation; ExitCode = 5; Output = @('ERROR: Access is denied.') }
    }.GetNewClosure()
    $accessDeniedResult = & $notepadModule {
        param($FileState, $ProcessStopper, $Delay, $RegistryWriter, $RegistryCommand, $PathTester, $HiveMountReader)
        Invoke-BoostLabNotepadSettingsAction `
            -ActionName 'Apply' `
            -Confirmed:$true `
            -AdministratorChecker { $true } `
            -FileStateReader { param($Path) $FileState } `
            -ProcessStopper $ProcessStopper `
            -DelayInvoker $Delay `
            -RegistryFileWriter $RegistryWriter `
            -RegistryCommandInvoker $RegistryCommand `
            -RegistryReader { param($Name) throw 'Registry read must not run when hive load fails.' } `
            -PathTester $PathTester `
            -HiveMountReader $HiveMountReader `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows'
    } (& $newFileState $true 'UNCHANGED' 'File still present.') $accessDeniedStopper $delay $registryWriter $accessDeniedCommand $pathTesterPresent $hiveMountAbsent
    Assert-BoostLabCondition (-not [bool]$accessDeniedResult.Success) 'Access denied reg load must fail closed.'
    Assert-BoostLabCondition ([string]$accessDeniedResult.Data.FinalStatusReason -eq 'HiveLoadFailed') 'Access denied reg load must identify HiveLoadFailed.'
    Assert-BoostLabCondition (@($accessDeniedResult.Data.HiveOperations | Where-Object { [string]$_.Stage -eq 'LoadSettingsHive' }).Count -eq 2) 'Access denied reg load must retry only once after stopping Notepad again.'
    Assert-BoostLabCondition (($accessDeniedEvents.ToArray() -join ',') -eq "load|HKLM\Settings|$notepadSettingsDatPath,load|HKLM\Settings|$notepadSettingsDatPath") 'Access denied retry must not import or unload when load never succeeds.'
    Assert-BoostLabCondition (@($accessDeniedProcessActions).Count -eq 2) 'Access denied retry must invoke the Notepad stop path once before Apply and once before retry.'
    Assert-BoostLabCondition ([string]$accessDeniedResult.Message -like '*Access is denied*') 'Access denied result must preserve native output.'

    $recoveredAccessDeniedEvents = [System.Collections.Generic.List[string]]::new()
    $recoveredAccessDeniedProcessActions = [System.Collections.Generic.List[string]]::new()
    $recoveredAccessDeniedState = @{ LoadCount = 0 }
    $recoveredAccessDeniedStopper = {
        $recoveredAccessDeniedProcessActions.Add('Stop-Notepad')
        [pscustomobject]@{ Success = $true; Status = 'StopRequested'; Message = 'Stop-Process Notepad was invoked with SilentlyContinue, matching Ultimate.' }
    }.GetNewClosure()
    $recoveredAccessDeniedCommand = {
        param($Operation, $Arguments, $Root)
        $recoveredAccessDeniedEvents.Add("$Operation|$($Arguments -join '|')")
        if ($Operation -eq 'load') {
            $recoveredAccessDeniedState.LoadCount = [int]$recoveredAccessDeniedState.LoadCount + 1
            if ([int]$recoveredAccessDeniedState.LoadCount -eq 1) {
                return [pscustomobject]@{ Success = $false; Operation = $Operation; ExitCode = 5; Output = @('ERROR: Access is denied.') }
            }
        }

        [pscustomobject]@{ Success = $true; Operation = $Operation; ExitCode = 0; Output = @('The operation completed successfully.') }
    }.GetNewClosure()
    $recoveredAccessDeniedResult = & $notepadModule {
        param($FileState, $ProcessStopper, $Delay, $RegistryWriter, $RegistryCommand, $RegistryReader, $PathTester, $HiveMountReader)
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
            -PathTester $PathTester `
            -HiveMountReader $HiveMountReader `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows'
    } (& $newFileState $true 'UPDATED' 'Updated file detected.') $recoveredAccessDeniedStopper $delay $registryWriter $recoveredAccessDeniedCommand $registryReader $pathTesterPresent $hiveMountAbsent
    Assert-BoostLabCondition ([bool]$recoveredAccessDeniedResult.Success) 'Recovered access denied reg load must succeed after retry and value verification.'
    Assert-BoostLabCondition ([string]$recoveredAccessDeniedResult.Status -eq 'Passed') 'Recovered access denied reg load with verified values should not surface as Warning.'
    Assert-BoostLabCondition ([string]$recoveredAccessDeniedResult.VerificationResult.Status -eq 'Passed') 'Recovered access denied reg load should pass verification after value checks.'
    Assert-BoostLabCondition ([string]$recoveredAccessDeniedResult.Data.CommandStatus -eq 'Completed') 'Recovered access denied reg load should report completed with informational details.'
    Assert-BoostLabCondition (@($recoveredAccessDeniedResult.Data.Warnings).Count -eq 0) 'Recovered access denied reg load should not leave user-facing warnings.'
    Assert-BoostLabCondition (@($recoveredAccessDeniedResult.Data.InformationalNotes | Where-Object { [string]$_.ReasonCode -eq 'HiveLoadAccessDeniedRecovered' }).Count -eq 1) 'Recovered access denied reg load should be recorded as an informational source-tolerated outcome.'
    Assert-BoostLabCondition (($recoveredAccessDeniedEvents.ToArray() -join ',') -eq "load|HKLM\Settings|$notepadSettingsDatPath,load|HKLM\Settings|$notepadSettingsDatPath,import|$notepadRegFilePath,unload|HKLM\Settings") 'Recovered access denied retry must continue to import and unload after the second load succeeds.'
    Assert-BoostLabCondition (@($recoveredAccessDeniedProcessActions).Count -eq 2) 'Recovered access denied retry must invoke the Notepad stop path once before Apply and once before retry.'

    $staleMountEvents = [System.Collections.Generic.List[string]]::new()
    $staleMountCommand = {
        param($Operation, $Arguments, $Root)
        $staleMountEvents.Add("$Operation|$($Arguments -join '|')")
        [pscustomobject]@{ Success = $true; Operation = $Operation; ExitCode = 0; Output = @('The operation completed successfully.') }
    }.GetNewClosure()
    $staleMountResult = & $notepadModule {
        param($FileState, $ProcessStopper, $Delay, $RegistryWriter, $RegistryCommand, $RegistryReader, $PathTester)
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
            -PathTester $PathTester `
            -HiveMountReader { [pscustomobject]@{ Exists = $true; CanUnload = $true; Message = 'Mock stale BoostLab mount.' } } `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows'
    } (& $newFileState $true 'UPDATED' 'Updated file detected.') $processStopper $delay $registryWriter $staleMountCommand $registryReader $pathTesterPresent
    Assert-BoostLabCondition ([bool]$staleMountResult.Success) 'Unloadable stale HKLM:\Settings mount should be cleaned before Notepad import.'
    Assert-BoostLabCondition (($staleMountEvents.ToArray() -join ',') -eq "unload|HKLM\Settings,load|HKLM\Settings|$notepadSettingsDatPath,import|$notepadRegFilePath,unload|HKLM\Settings") 'Stale mount cleanup must unload before loading the Notepad hive.'
    Assert-BoostLabCondition ([string]$staleMountResult.Status -eq 'Passed') 'Recovered stale mount cleanup with verified values should not surface as Warning.'
    Assert-BoostLabCondition (@($staleMountResult.Data.Warnings).Count -eq 0) 'Recovered stale mount cleanup should not leave user-facing warnings.'
    Assert-BoostLabCondition (@($staleMountResult.Data.InformationalNotes | Where-Object { [string]$_.ReasonCode -eq 'PreExistingHiveMountRecovered' -and [string]$_.Message -like '*Pre-existing HKLM:\Settings mount*' }).Count -eq 1) 'Stale mount cleanup must be reported as an informational recovery detail.'

    $blockedMountEvents = [System.Collections.Generic.List[string]]::new()
    $blockedMountResult = & $notepadModule {
        param($FileState, $ProcessStopper, $Delay, $RegistryWriter, $RegistryCommand, $PathTester)
        Invoke-BoostLabNotepadSettingsAction `
            -ActionName 'Apply' `
            -Confirmed:$true `
            -AdministratorChecker { $true } `
            -FileStateReader { param($Path) $FileState } `
            -ProcessStopper $ProcessStopper `
            -DelayInvoker $Delay `
            -RegistryFileWriter $RegistryWriter `
            -RegistryCommandInvoker $RegistryCommand `
            -RegistryReader { param($Name) throw 'Registry read must not run when stale hive blocks import.' } `
            -PathTester $PathTester `
            -HiveMountReader { [pscustomobject]@{ Exists = $true; CanUnload = $false; Message = 'Mock non-owned mount.' } } `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows'
    } (& $newFileState $true 'UNCHANGED' 'File still present.') $processStopper $delay $registryWriter { param($Operation, $Arguments, $Root) $blockedMountEvents.Add("$Operation|$($Arguments -join '|')") } $pathTesterPresent
    Assert-BoostLabCondition (-not [bool]$blockedMountResult.Success) 'Non-unloadable HKLM:\Settings mount must fail closed before import.'
    Assert-BoostLabCondition ([string]$blockedMountResult.Data.FinalStatusReason -eq 'ExistingHiveMountBlocked') 'Blocked stale mount must report ExistingHiveMountBlocked.'
    Assert-BoostLabCondition ($blockedMountEvents.Count -eq 0) 'Blocked stale mount must not run registry commands.'

    $importFailureEvents = [System.Collections.Generic.List[string]]::new()
    $importFailureCommand = {
        param($Operation, $Arguments, $Root)
        $importFailureEvents.Add("$Operation|$($Arguments -join '|')")
        if ($Operation -eq 'import') {
            return [pscustomobject]@{ Success = $false; Operation = $Operation; ExitCode = 2; Output = @('Mock import failure.') }
        }
        [pscustomobject]@{ Success = $true; Operation = $Operation; ExitCode = 0; Output = @('The operation completed successfully.') }
    }.GetNewClosure()
    $importFailureResult = & $notepadModule {
        param($FileState, $ProcessStopper, $Delay, $RegistryWriter, $RegistryCommand, $PathTester, $HiveMountReader)
        Invoke-BoostLabNotepadSettingsAction `
            -ActionName 'Apply' `
            -Confirmed:$true `
            -AdministratorChecker { $true } `
            -FileStateReader { param($Path) $FileState } `
            -ProcessStopper $ProcessStopper `
            -DelayInvoker $Delay `
            -RegistryFileWriter $RegistryWriter `
            -RegistryCommandInvoker $RegistryCommand `
            -RegistryReader { param($Name) throw 'Registry read must not run when import fails.' } `
            -PathTester $PathTester `
            -HiveMountReader $HiveMountReader `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows'
    } (& $newFileState $true 'UNCHANGED' 'File still present.') $processStopper $delay $registryWriter $importFailureCommand $pathTesterPresent $hiveMountAbsent
    Assert-BoostLabCondition (-not [bool]$importFailureResult.Success) 'Import failure must fail closed.'
    Assert-BoostLabCondition ([string]$importFailureResult.Data.FinalStatusReason -eq 'HiveImportFailed') 'Non-zero import exit code must identify HiveImportFailed.'
    Assert-BoostLabCondition (($importFailureEvents.ToArray() -join ',') -eq "load|HKLM\Settings|$notepadSettingsDatPath,import|$notepadRegFilePath,unload|HKLM\Settings") 'Import failure must still unload the hive after successful load.'
    $failedImportOperation = @($importFailureResult.Data.HiveOperations | Where-Object { [string]$_.Stage -eq 'ImportNotepadSettingsPayload' }) | Select-Object -First 1
    Assert-BoostLabCondition ([int]$failedImportOperation.ExitCode -eq 2) 'Non-zero import failure must preserve the native exit code.'
    Assert-BoostLabCondition ([string]$failedImportOperation.FailureKind -eq 'NativeExitCodeNonZero') 'Non-zero import failure must report NativeExitCodeNonZero.'
    Assert-BoostLabCondition (@($importFailureResult.Data.RegistryValuesChecked).Count -eq 0) 'Failed import must not verify values before a successful import.'

    $recoverableExitCodeEvents = [System.Collections.Generic.List[string]]::new()
    $recoverableExitCodeCommand = {
        param($Operation, $Arguments, $Root)
        $recoverableExitCodeEvents.Add("$Operation|$($Arguments -join '|')")
        if ($Operation -eq 'import') {
            return [pscustomobject]@{ Success = $false; Operation = $Operation; Output = @('The operation completed successfully.') }
        }
        [pscustomobject]@{ Success = $true; Operation = $Operation; ExitCode = 0; Output = @('The operation completed successfully.') }
    }.GetNewClosure()
    $recoverableExitCodeReader = {
        param($Name)
        $recoverableExitCodeEvents.Add("read|$Name")
        [pscustomobject]@{
            ReadSucceeded = $true; Exists = $true; Name = $Name
            DisplayValue = [string]$continuousRegQueryValues[$Name]; Message = 'Mock continuous reg query value detected.'
        }
    }.GetNewClosure()
    $recoverableExitCodeResult = & $notepadModule {
        param($FileState, $ProcessStopper, $Delay, $RegistryWriter, $RegistryCommand, $RegistryReader, $PathTester, $HiveMountReader)
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
            -PathTester $PathTester `
            -HiveMountReader $HiveMountReader `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows'
    } (& $newFileState $true 'UPDATED' 'Updated file detected.') $processStopper $delay $registryWriter $recoverableExitCodeCommand $recoverableExitCodeReader $pathTesterPresent $hiveMountAbsent
    Assert-BoostLabCondition ([bool]$recoverableExitCodeResult.Success) 'Missing import exit code with native success output and matching values must not fail.'
    Assert-BoostLabCondition ([string]$recoverableExitCodeResult.Status -eq 'Passed') 'Recovered missing import exit code with verified values should not surface as Warning.'
    Assert-BoostLabCondition ([string]$recoverableExitCodeResult.VerificationResult.Status -eq 'Passed') 'Recovered missing import exit code should pass verification after value checks.'
    Assert-BoostLabCondition ([string]$recoverableExitCodeResult.Data.CommandStatus -eq 'Completed') 'Recovered missing import exit code should report completed with informational details.'
    Assert-BoostLabCondition ([string]$recoverableExitCodeResult.Data.FinalStatusReason -eq 'NativeExitCodeMissingRecoveredByVerification') 'Recovered import must report NativeExitCodeMissingRecoveredByVerification.'
    Assert-BoostLabCondition (@($recoverableExitCodeResult.Data.Warnings).Count -eq 0) 'Recovered missing import exit code should not leave user-facing warnings.'
    Assert-BoostLabCondition (@($recoverableExitCodeResult.Data.InformationalNotes | Where-Object { [string]$_.ReasonCode -eq 'NativeExitCodeMissingRecoveredByVerification' }).Count -eq 1) 'Recovered missing import exit code should be recorded as an informational source-tolerated outcome.'
    Assert-BoostLabCondition ([bool]$recoverableExitCodeResult.Data.RecoveryAttempted) 'Recovered import must report RecoveryAttempted.'
    Assert-BoostLabCondition ([string]$recoverableExitCodeResult.Data.RecoveryReason -eq 'NativeExitCodeMissingWithSuccessOutput') 'Recovered import must report the recovery reason.'
    Assert-BoostLabCondition (($recoverableExitCodeEvents.ToArray() -join ',') -eq "load|HKLM\Settings|$notepadSettingsDatPath,import|$notepadRegFilePath,read|OpenFile,read|GhostFile,read|RewriteEnabled,unload|HKLM\Settings") 'Recovered missing import exit code must verify values before unload.'
    $recoverableImportOperation = @($recoverableExitCodeResult.Data.HiveOperations | Where-Object { [string]$_.Stage -eq 'ImportNotepadSettingsPayload' }) | Select-Object -First 1
    Assert-BoostLabCondition ($null -ne $recoverableImportOperation) 'Recovered missing exit-code run must record the import operation.'
    Assert-BoostLabCondition (-not [bool]$recoverableImportOperation.ExitCodeCaptured) 'Recovered missing exit-code run must report ExitCodeCaptured false.'
    Assert-BoostLabCondition ($null -eq $recoverableImportOperation.ExitCode) 'Recovered missing exit-code run must leave ExitCode null.'
    Assert-BoostLabCondition ([string]$recoverableImportOperation.FailureKind -eq 'NativeExitCodeMissingWithSuccessOutput') 'Recovered missing exit-code run must classify the operation narrowly.'
    Assert-BoostLabCondition ([bool]$recoverableImportOperation.RecoveryAttempted) 'Recovered import operation must mark RecoveryAttempted.'
    Assert-BoostLabCondition ([string]$recoverableImportOperation.NativeOutput -like '*operation completed successfully*') 'Recovered missing exit-code diagnostics must preserve native output.'
    Assert-BoostLabCondition (@($recoverableExitCodeResult.Data.RegistryValuesChecked).Count -eq 3) 'Recovered missing import exit code must verify all source-defined values.'
    $failedRecoveredValueChecks = @($recoverableExitCodeResult.VerificationResult.Checks | Where-Object { [string]$_.Name -like 'Notepad LocalState | *' -and [string]$_.Status -eq 'Failed' })
    Assert-BoostLabCondition ($failedRecoveredValueChecks.Count -eq 0) 'Recovered continuous Notepad REG_NONE values must not produce failed value checks.'
    foreach ($state in @($recoverableExitCodeResult.Data.RegistryValuesChecked)) {
        Assert-BoostLabCondition ([bool]$state.ByteComparisonSucceeded) "Recovered $($state.Name) byte comparison should pass after normalization."
        Assert-BoostLabCondition ([string]$state.ExpectedBytesNormalized -eq [string]$state.ActualBytesNormalized) "Recovered $($state.Name) normalized expected/actual bytes should match."
        Assert-BoostLabCondition ([string]$state.ActualBytesRaw -eq [string]$continuousRegQueryValues[$state.Name]) "Recovered $($state.Name) should preserve raw continuous actual bytes in diagnostics."
    }

    $recoverableMismatchEvents = [System.Collections.Generic.List[string]]::new()
    $recoverableMismatchCommand = {
        param($Operation, $Arguments, $Root)
        $recoverableMismatchEvents.Add("$Operation|$($Arguments -join '|')")
        if ($Operation -eq 'import') {
            return [pscustomobject]@{ Success = $false; Operation = $Operation; Output = @('The operation completed successfully.') }
        }
        [pscustomobject]@{ Success = $true; Operation = $Operation; ExitCode = 0; Output = @('The operation completed successfully.') }
    }.GetNewClosure()
    $recoverableMismatchReader = {
        param($Name)
        $recoverableMismatchEvents.Add("read|$Name")
        if ($Name -eq 'RewriteEnabled') {
            return [pscustomobject]@{ ReadSucceeded = $true; Exists = $true; Name = $Name; DisplayValue = '00,00,00,00,00,00,00,00,00'; Message = 'Mock mismatched RewriteEnabled.' }
        }
        [pscustomobject]@{ ReadSucceeded = $true; Exists = $true; Name = $Name; DisplayValue = [string]$expectedValues[$Name]; Message = 'Mock value detected.' }
    }.GetNewClosure()
    $recoverableMismatchResult = & $notepadModule {
        param($FileState, $ProcessStopper, $Delay, $RegistryWriter, $RegistryCommand, $RegistryReader, $PathTester, $HiveMountReader)
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
            -PathTester $PathTester `
            -HiveMountReader $HiveMountReader `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows'
    } (& $newFileState $true 'UNCHANGED' 'File still present.') $processStopper $delay $registryWriter $recoverableMismatchCommand $recoverableMismatchReader $pathTesterPresent $hiveMountAbsent
    Assert-BoostLabCondition (-not [bool]$recoverableMismatchResult.Success) 'Success native output with mismatched values must fail closed.'
    Assert-BoostLabCondition ([string]$recoverableMismatchResult.Data.FinalStatusReason -eq 'HiveImportVerificationFailed') 'Recovered import with mismatched values must fail verification, not succeed from text output.'
    Assert-BoostLabCondition ([string]$recoverableMismatchResult.Message -like '*RewriteEnabled mismatch*') 'Recovered import mismatch failure must include value diagnostics.'
    Assert-BoostLabCondition (($recoverableMismatchEvents.ToArray() -join ',') -eq "load|HKLM\Settings|$notepadSettingsDatPath,import|$notepadRegFilePath,read|OpenFile,read|GhostFile,read|RewriteEnabled,unload|HKLM\Settings") 'Recovered import mismatch must still unload the hive after verification.'
    $recoverableMismatchImportOperation = @($recoverableMismatchResult.Data.HiveOperations | Where-Object { [string]$_.Stage -eq 'ImportNotepadSettingsPayload' }) | Select-Object -First 1
    Assert-BoostLabCondition ([string]$recoverableMismatchImportOperation.FailureKind -eq 'NativeExitCodeMissingWithSuccessOutput') 'Recovered mismatch import must preserve recoverable import classification.'

    $missingExitCodeEvents = [System.Collections.Generic.List[string]]::new()
    $missingExitCodeCommand = {
        param($Operation, $Arguments, $Root)
        $missingExitCodeEvents.Add("$Operation|$($Arguments -join '|')")
        if ($Operation -eq 'import') {
            return [pscustomobject]@{ Success = $false; Operation = $Operation; Output = @('Mock reg import returned no process status.') }
        }
        [pscustomobject]@{ Success = $true; Operation = $Operation; ExitCode = 0; Output = @('The operation completed successfully.') }
    }.GetNewClosure()
    $missingExitCodeResult = & $notepadModule {
        param($FileState, $ProcessStopper, $Delay, $RegistryWriter, $RegistryCommand, $PathTester, $HiveMountReader)
        Invoke-BoostLabNotepadSettingsAction `
            -ActionName 'Apply' `
            -Confirmed:$true `
            -AdministratorChecker { $true } `
            -FileStateReader { param($Path) $FileState } `
            -ProcessStopper $ProcessStopper `
            -DelayInvoker $Delay `
            -RegistryFileWriter $RegistryWriter `
            -RegistryCommandInvoker $RegistryCommand `
            -RegistryReader { param($Name) throw 'Registry read must not run when import exit code is missing without success output.' } `
            -PathTester $PathTester `
            -HiveMountReader $HiveMountReader `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows'
    } (& $newFileState $true 'UNCHANGED' 'File still present.') $processStopper $delay $registryWriter $missingExitCodeCommand $pathTesterPresent $hiveMountAbsent
    Assert-BoostLabCondition (-not [bool]$missingExitCodeResult.Success) 'Missing import exit code without success output must fail closed.'
    Assert-BoostLabCondition ([string]$missingExitCodeResult.Data.FinalStatusReason -eq 'NativeExitCodeMissing') 'Missing import exit code without success output must report NativeExitCodeMissing.'
    Assert-BoostLabCondition ([string]$missingExitCodeResult.Message -like '*NativeExitCodeMissing*') 'Missing import exit code message must identify the command-capture failure.'
    Assert-BoostLabCondition (($missingExitCodeEvents.ToArray() -join ',') -eq "load|HKLM\Settings|$notepadSettingsDatPath,import|$notepadRegFilePath,unload|HKLM\Settings") 'Missing import exit code without success output must still unload the hive after successful load.'
    $missingExitCodeImportOperation = @($missingExitCodeResult.Data.HiveOperations | Where-Object { [string]$_.Stage -eq 'ImportNotepadSettingsPayload' }) | Select-Object -First 1
    Assert-BoostLabCondition ($null -ne $missingExitCodeImportOperation) 'Missing exit-code run must record the import operation.'
    Assert-BoostLabCondition (-not [bool]$missingExitCodeImportOperation.ExitCodeCaptured) 'Missing exit-code run must report ExitCodeCaptured false.'
    Assert-BoostLabCondition ($null -eq $missingExitCodeImportOperation.ExitCode) 'Missing exit-code run must leave ExitCode null.'
    Assert-BoostLabCondition ([string]$missingExitCodeImportOperation.FailureKind -eq 'NativeExitCodeMissing') 'Missing exit-code run must classify the operation as NativeExitCodeMissing.'
    Assert-BoostLabCondition (-not [bool]$missingExitCodeImportOperation.RecoveryAttempted) 'Missing exit-code run without success output must not mark RecoveryAttempted.'
    Assert-BoostLabCondition (@($missingExitCodeResult.Data.RegistryValuesChecked).Count -eq 0) 'Missing import exit code without success output must not verify values before a proven or recoverable import.'

    $missingValueReader = {
        param($Name)
        if ($Name -eq 'GhostFile') {
            return [pscustomobject]@{ ReadSucceeded = $true; Exists = $false; Name = $Name; DisplayValue = 'Absent'; Message = 'Mock missing GhostFile.' }
        }
        [pscustomobject]@{ ReadSucceeded = $true; Exists = $true; Name = $Name; DisplayValue = [string]$expectedValues[$Name]; Message = 'Mock value detected.' }
    }.GetNewClosure()
    $missingValueResult = & $notepadModule {
        param($FileState, $ProcessStopper, $Delay, $RegistryWriter, $RegistryCommand, $RegistryReader, $PathTester, $HiveMountReader)
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
            -PathTester $PathTester `
            -HiveMountReader $HiveMountReader `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows'
    } (& $newFileState $true 'UNCHANGED' 'File still present.') $processStopper $delay $registryWriter $applyCommand $missingValueReader $pathTesterPresent $hiveMountAbsent
    Assert-BoostLabCondition (-not [bool]$missingValueResult.Success) 'Missing source-required Notepad registry value must fail closed.'
    Assert-BoostLabCondition ([string]$missingValueResult.Message -like '*GhostFile was absent*') 'Missing value failure must name the absent Notepad value.'

    $mismatchValueReader = {
        param($Name)
        if ($Name -eq 'RewriteEnabled') {
            return [pscustomobject]@{ ReadSucceeded = $true; Exists = $true; Name = $Name; DisplayValue = '00,00,00,00,00,00,00,00,00'; Message = 'Mock mismatched RewriteEnabled.' }
        }
        [pscustomobject]@{ ReadSucceeded = $true; Exists = $true; Name = $Name; DisplayValue = [string]$expectedValues[$Name]; Message = 'Mock value detected.' }
    }.GetNewClosure()
    $mismatchValueResult = & $notepadModule {
        param($FileState, $ProcessStopper, $Delay, $RegistryWriter, $RegistryCommand, $RegistryReader, $PathTester, $HiveMountReader)
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
            -PathTester $PathTester `
            -HiveMountReader $HiveMountReader `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows'
    } (& $newFileState $true 'UNCHANGED' 'File still present.') $processStopper $delay $registryWriter $applyCommand $mismatchValueReader $pathTesterPresent $hiveMountAbsent
    Assert-BoostLabCondition (-not [bool]$mismatchValueResult.Success) 'Mismatched source-required Notepad registry value must fail closed.'
    Assert-BoostLabCondition ([string]$mismatchValueResult.Message -like '*RewriteEnabled mismatch*') 'Mismatched value failure must include the value name.'
    $mismatchRewriteState = @($mismatchValueResult.Data.RegistryValuesChecked | Where-Object { [string]$_.Name -eq 'RewriteEnabled' }) | Select-Object -First 1
    Assert-BoostLabCondition ($null -ne $mismatchRewriteState) 'Mismatched RewriteEnabled state must be recorded.'
    Assert-BoostLabCondition (-not [bool]$mismatchRewriteState.ByteComparisonSucceeded) 'Mismatched RewriteEnabled bytes must fail normalized comparison.'
    Assert-BoostLabCondition ([string]$mismatchRewriteState.ExpectedBytesNormalized -ne [string]$mismatchRewriteState.ActualBytesNormalized) 'Mismatched RewriteEnabled diagnostics must show different normalized bytes.'

    $invalidActualReader = {
        param($Name)
        if ($Name -eq 'OpenFile') {
            return [pscustomobject]@{ ReadSucceeded = $true; Exists = $true; Name = $Name; DisplayValue = '01000000D1552457D184DB0'; Message = 'Mock invalid odd-length OpenFile.' }
        }
        [pscustomobject]@{ ReadSucceeded = $true; Exists = $true; Name = $Name; DisplayValue = [string]$continuousRegQueryValues[$Name]; Message = 'Mock value detected.' }
    }.GetNewClosure()
    $invalidActualResult = & $notepadModule {
        param($FileState, $ProcessStopper, $Delay, $RegistryWriter, $RegistryCommand, $RegistryReader, $PathTester, $HiveMountReader)
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
            -PathTester $PathTester `
            -HiveMountReader $HiveMountReader `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows'
    } (& $newFileState $true 'UNCHANGED' 'File still present.') $processStopper $delay $registryWriter $applyCommand $invalidActualReader $pathTesterPresent $hiveMountAbsent
    Assert-BoostLabCondition (-not [bool]$invalidActualResult.Success) 'Invalid actual Notepad byte data must fail closed.'
    Assert-BoostLabCondition ([string]$invalidActualResult.Data.FinalStatusReason -eq 'HiveImportVerificationFailed') 'Invalid actual Notepad byte data must report HiveImportVerificationFailed.'
    Assert-BoostLabCondition ([string]$invalidActualResult.Message -like '*Actual bytes could not be parsed*') 'Invalid actual byte failure must include parse diagnostics.'
    $invalidOpenFileState = @($invalidActualResult.Data.RegistryValuesChecked | Where-Object { [string]$_.Name -eq 'OpenFile' }) | Select-Object -First 1
    Assert-BoostLabCondition ($null -ne $invalidOpenFileState) 'Invalid OpenFile state must be recorded.'
    Assert-BoostLabCondition (-not [bool]$invalidOpenFileState.ByteComparisonSucceeded) 'Invalid OpenFile byte comparison must fail.'
    Assert-BoostLabCondition ([string]$invalidOpenFileState.ByteComparisonMessage -like '*Actual bytes could not be parsed*') 'Invalid OpenFile diagnostics must identify invalid actual byte format.'

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
$controlPanelRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'control-panel-settings' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $controlPanelRecord) 'Control Panel Settings parity record is missing.'
Assert-BoostLabCondition ([string]$controlPanelRecord.FinalProgressStatus -eq 'DoneParity') 'Control Panel Settings must remain final accepted after Phase 149.'

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
