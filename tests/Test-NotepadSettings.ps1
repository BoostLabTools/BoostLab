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

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\notepad-settings.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\14 Notepad Settings.ps1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$recordPath = Join-Path $ProjectRoot 'docs\migrations\notepad-settings.md'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$sourceHash = '2086D75FAA560C9746B1FA2EDB29AE9A8364633FD6268DEEDBE7FB4720EA39FB'
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne $sourceHash) {
    throw 'Notepad Settings Ultimate source hash changed.'
}

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration['Stages'] | ForEach-Object { $_['Tools'] })
$tool = $tools | Where-Object { $_['Id'] -eq 'notepad-settings' } | Select-Object -First 1
if ($null -eq $tool) {
    throw 'Notepad Settings metadata is missing.'
}
if (
    [string]$tool['Stage'] -ne 'Windows' -or
    [int]$tool['Order'] -ne 14 -or
    [string]$tool['Type'] -ne 'action' -or
    [string]$tool['RiskLevel'] -ne 'medium' -or
    (@($tool['Actions']) -join ',') -ne 'Apply,Default'
) {
    throw 'Notepad Settings metadata does not match Phase 32.'
}
$trueCapabilities = @('RequiresAdmin', 'CanModifyRegistry', 'CanDeleteFiles', 'SupportsDefault', 'NeedsExplicitConfirmation')
foreach ($field in $tool['Capabilities'].Keys) {
    if ([bool]$tool['Capabilities'][$field] -ne ($field -in $trueCapabilities)) {
        throw "Notepad Settings capability '$field' is incorrect."
    }
}

$source = Get-Content -Raw -LiteralPath $sourcePath
foreach ($requiredText in @(
    'Stop-Process -Name "Notepad" -Force -ErrorAction SilentlyContinue'
    'Start-Sleep -Seconds 2'
    'Set-Content -Path "$env:SystemRoot\Temp\notepadsettings.reg" -Value $NotepadSettings -Force'
    'reg load "HKLM\Settings" $SettingsDat'
    'reg import $RegFileNotepadSettings'
    'reg unload "HKLM\Settings"'
    'Remove-Item "$env:LocalAppData\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings\settings.dat" -Force'
)) {
    if (-not $source.Contains($requiredText)) {
        throw "Notepad Settings source no longer contains: $requiredText"
    }
}

$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredText in @(
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    '$script:BoostLabNotepadProcessName = ''Notepad'''
    'Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings\settings.dat'
    '"OpenFile"=hex(5f5e104):01,00,00,00,d1,55,24,57,d1,84,db,01'
    '"GhostFile"=hex(5f5e10b):00,42,60,f1,5a,d1,84,db,01'
    '"RewriteEnabled"=hex(5f5e10b):00,12,4a,7f,5f,d1,84,db,01'
    'Copy-Item -LiteralPath $SourcePath -Destination $BackupPath -Force -ErrorAction Stop'
    'Remove-Item -LiteralPath $Path -Force -ErrorAction Stop'
    'Backups\NotepadSettings'
    'BoostLabOwnsTargetFile = $false'
    '[bool]$Confirmed = $false'
    'New-BoostLabVerificationResult'
)) {
    if (-not $moduleSource.Contains($requiredText)) {
        throw "Notepad Settings module is missing: $requiredText"
    }
}
foreach ($forbiddenText in @(
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
    if ($moduleSource.Contains($forbiddenText)) {
        throw "Notepad Settings module contains unrelated behavior: $forbiddenText"
    }
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
    if (
        [string]$info.Id -ne 'notepad-settings' -or
        (@($info.Actions) -join ',') -ne 'Apply,Default' -or
        (@($info.ImplementedActions) -join ',') -ne 'Apply,Default'
    ) {
        throw 'Notepad Settings exported metadata is incorrect.'
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
    $backupWriter = {
        param($SourcePath, $BackupPath)
        [pscustomobject]@{ Success = $true; BackupPath = $BackupPath; Sha256 = 'ORIGINAL'; Message = 'Verified settings.dat backup created.' }
    }
    $stateWriter = { param($State, $ManifestPath) }
    $processStopper = { [pscustomobject]@{ Success = $true; Status = 'Stopped'; Message = 'Notepad stopped.' } }
    $delay = { param($Seconds) }
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
    if (
        -not [bool]$compatibility.Supported -or
        [bool]$compatibility.Applicable -or
        -not [bool]$compatibility.PackageDirectoryExists -or
        [bool]$compatibility.SettingsDatExists -or
        [string]$compatibility.ExpectedSettingsDatPath -ne 'C:\Users\Tester\AppData\Local\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings\settings.dat'
    ) {
        throw 'Notepad Settings compatibility diagnostics are incorrect for a missing settings.dat.'
    }

    $missingApplyEvents = [System.Collections.Generic.List[string]]::new()
    $missingApplyResult = & $notepadModule {
        param($FileState, $Events)
        Invoke-BoostLabNotepadSettingsAction `
            -ActionName 'Apply' `
            -Confirmed:$true `
            -AdministratorChecker { $true } `
            -DirectoryTester { param($Path) $true } `
            -FileStateReader { param($Path) $FileState } `
            -ProcessStopper { $Events.Add('PROCESS'); throw 'Process handling must not run.' } `
            -DelayInvoker { param($Seconds) $Events.Add('DELAY'); throw 'Delay must not run.' } `
            -BackupWriter { param($Source, $Destination) $Events.Add('BACKUP'); throw 'Backup must not run.' } `
            -StateWriter { param($State, $Path) $Events.Add('STATE'); throw 'State write must not run.' } `
            -RegistryFileWriter { param($Path, $Content) $Events.Add('REGFILE'); throw 'Registry file write must not run.' } `
            -RegistryCommandInvoker { param($Operation, $Arguments, $Root) $Events.Add('REGCOMMAND'); throw 'Registry command must not run.' } `
            -RegistryReader { param($Name) $Events.Add('REGREAD'); throw 'Registry read must not run.' } `
            -FileRemover { param($Path) $Events.Add('DELETE'); throw 'Delete must not run.' } `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows' `
            -ProgramData 'C:\ProgramData'
    } (& $newFileState $false $null 'File absent.') $missingApplyEvents
    if (
        -not $missingApplyResult.Success -or
        [string]$missingApplyResult.Status -ne 'NotApplicable' -or
        [string]$missingApplyResult.Data.CommandStatus -ne 'Not applicable' -or
        [string]$missingApplyResult.Data.VerificationStatus -ne 'NotApplicable' -or
        $null -ne $missingApplyResult.VerificationResult -or
        [bool]$missingApplyResult.Data.SettingsDatExists -or
        [bool]$missingApplyResult.Data.ChangesExecuted -or
        -not [bool]$missingApplyResult.Data.NotepadPackageDirectoryExists -or
        $missingApplyEvents.Count -ne 0 -or
        [string]$missingApplyResult.Message -notmatch 'classic Notepad'
    ) {
        throw "Missing settings.dat Apply did not return a clean side-effect-free NotApplicable result: $($missingApplyResult | ConvertTo-Json -Depth 8 -Compress)"
    }

    $applyEvents = [System.Collections.Generic.List[string]]::new()
    $applyCommand = {
        param($Operation, $Arguments, $Root)
        $applyEvents.Add("$Operation|$($Arguments -join '|')")
        [pscustomobject]@{ Success = $true; Operation = $Operation }
    }.GetNewClosure()
    $applyReadCount = 0
    $applyFileReader = {
        param($Path)
        $applyReadCount++
        if ($applyReadCount -eq 1) { return (& $newFileState $true 'ORIGINAL' 'Original detected.') }
        return (& $newFileState $true 'UPDATED' 'Updated file detected.')
    }.GetNewClosure()
    $applyResult = & $notepadModule {
        param($FileReader, $BackupWriter, $StateWriter, $ProcessStopper, $Delay, $RegistryWriter, $RegistryCommand, $RegistryReader)
        Invoke-BoostLabNotepadSettingsAction `
            -ActionName 'Apply' `
            -Confirmed:$true `
            -AdministratorChecker { $true } `
            -FileStateReader $FileReader `
            -BackupWriter $BackupWriter `
            -StateWriter $StateWriter `
            -ProcessStopper $ProcessStopper `
            -DelayInvoker $Delay `
            -RegistryFileWriter $RegistryWriter `
            -RegistryCommandInvoker $RegistryCommand `
            -RegistryReader $RegistryReader `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows' `
            -ProgramData 'C:\ProgramData'
    } $applyFileReader $backupWriter $stateWriter $processStopper $delay $registryWriter $applyCommand $registryReader
    if (
        -not $applyResult.Success -or
        $applyResult.Message -ne 'Notepad settings applied.' -or
        $applyResult.VerificationResult.Status -ne 'Passed' -or
        $applyResult.Data.CommandStatus -ne 'Completed'
    ) {
        throw 'Mocked Notepad Settings Apply did not pass.'
    }
    if (($applyEvents -join ',') -ne 'load|HKLM\Settings|C:\Users\Tester\AppData\Local\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings\settings.dat,import|C:\Windows\Temp\notepadsettings.reg,unload|HKLM\Settings') {
        throw "Notepad Settings hive operation order changed: $($applyEvents -join ',')"
    }

    $defaultStates = [System.Collections.Queue]::new()
    $defaultStates.Enqueue((& $newFileState $true 'ORIGINAL' 'Original detected.'))
    $defaultStates.Enqueue((& $newFileState $false $null 'File absent.'))
    $defaultFileReader = {
        param($Path)
        return $defaultStates.Dequeue()
    }.GetNewClosure()
    $removedPaths = [System.Collections.Generic.List[string]]::new()
    $fileRemover = { param($Path) $removedPaths.Add($Path) }.GetNewClosure()
    $defaultResult = & $notepadModule {
        param($FileReader, $BackupWriter, $StateWriter, $ProcessStopper, $Delay, $FileRemover)
        Invoke-BoostLabNotepadSettingsAction `
            -ActionName 'Default' `
            -Confirmed:$true `
            -AdministratorChecker { $true } `
            -FileStateReader $FileReader `
            -BackupWriter $BackupWriter `
            -StateWriter $StateWriter `
            -ProcessStopper $ProcessStopper `
            -DelayInvoker $Delay `
            -FileRemover $FileRemover `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows' `
            -ProgramData 'C:\ProgramData'
    } $defaultFileReader $backupWriter $stateWriter $processStopper $delay $fileRemover
    if (
        -not $defaultResult.Success -or
        $defaultResult.Message -ne 'Notepad settings restored to default.' -or
        $defaultResult.VerificationResult.Status -ne 'Passed' -or
        $removedPaths.Count -ne 1 -or
        $removedPaths[0] -ne 'C:\Users\Tester\AppData\Local\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings\settings.dat'
    ) {
        throw "Mocked Notepad Settings Default did not delete only the approved file. Result: $($defaultResult | ConvertTo-Json -Depth 8 -Compress) Removed: $($removedPaths -join ',')"
    }

    $alreadyDefaultEvents = [System.Collections.Generic.List[string]]::new()
    $alreadyDefaultResult = & $notepadModule {
        param($FileState, $Events)
        Invoke-BoostLabNotepadSettingsAction `
            -ActionName 'Default' `
            -Confirmed:$true `
            -AdministratorChecker { $true } `
            -DirectoryTester { param($Path) $false } `
            -FileStateReader { param($Path) $FileState } `
            -ProcessStopper { $Events.Add('PROCESS'); throw 'Process handling must not run.' } `
            -DelayInvoker { param($Seconds) $Events.Add('DELAY'); throw 'Delay must not run.' } `
            -BackupWriter { param($Source, $Destination) $Events.Add('BACKUP'); throw 'Backup must not run.' } `
            -StateWriter { param($State, $Path) $Events.Add('STATE'); throw 'State write must not run.' } `
            -RegistryFileWriter { param($Path, $Content) $Events.Add('REGFILE'); throw 'Registry file write must not run.' } `
            -RegistryCommandInvoker { param($Operation, $Arguments, $Root) $Events.Add('REGCOMMAND'); throw 'Registry command must not run.' } `
            -RegistryReader { param($Name) $Events.Add('REGREAD'); throw 'Registry read must not run.' } `
            -FileRemover { param($Path) $Events.Add('DELETE'); throw 'Delete must not run.' } `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows' `
            -ProgramData 'C:\ProgramData'
    } (& $newFileState $false $null 'File absent.') $alreadyDefaultEvents
    if (
        -not $alreadyDefaultResult.Success -or
        $alreadyDefaultResult.Message -notmatch 'No action was needed' -or
        $alreadyDefaultResult.Data.CommandStatus -ne 'Already default' -or
        [bool]$alreadyDefaultResult.Data.ChangesExecuted -or
        $alreadyDefaultEvents.Count -ne 0
    ) {
        throw "Notepad Settings already-default handling is incorrect. Result: $($alreadyDefaultResult | ConvertTo-Json -Depth 8 -Compress) Events: $($alreadyDefaultEvents -join ',')"
    }

    $mutationCalled = $false
    $backupFailureResult = & $notepadModule {
        param($FileState, $StateWriter, $ProcessStopper, $Delay, [ref]$MutationCalled)
        Invoke-BoostLabNotepadSettingsAction `
            -ActionName 'Default' `
            -Confirmed:$true `
            -AdministratorChecker { $true } `
            -FileStateReader { param($Path) $FileState } `
            -BackupWriter { param($Source, $Destination) [pscustomobject]@{ Success = $false; Message = 'Mock backup failure.' } } `
            -StateWriter $StateWriter `
            -ProcessStopper $ProcessStopper `
            -DelayInvoker $Delay `
            -FileRemover { param($Path) $MutationCalled.Value = $true } `
            -LocalAppData 'C:\Users\Tester\AppData\Local' `
            -SystemRoot 'C:\Windows' `
            -ProgramData 'C:\ProgramData'
    } (& $newFileState $true 'ORIGINAL' 'Original detected.') $stateWriter $processStopper $delay ([ref]$mutationCalled)
    if ($backupFailureResult.Success -or $mutationCalled -or $backupFailureResult.Message -notmatch 'backup failed') {
        throw 'Notepad Settings did not block mutation after backup failure.'
    }
}
finally {
    Remove-Module -ModuleInfo $notepadModule -Force -ErrorAction SilentlyContinue
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
$actionPlanSource = Get-Content -Raw -LiteralPath $actionPlanPath
$uiSource = Get-Content -Raw -LiteralPath $uiPath
$recordSource = Get-Content -Raw -LiteralPath $recordPath
foreach ($requiredText in @(
    '''notepad-settings'' = @{'
    'Windows\notepad-settings.psm1'
    'ToolAction.NotApplicable'
    '''Not applicable'''
)) {
    if (-not $executionSource.Contains($requiredText)) {
        throw "Execution runtime is missing Notepad Settings integration: $requiredText"
    }
}
foreach ($requiredText in @(
    'Create and verify a unique backup of the exact Notepad settings.dat before mutation.'
    'Delete only Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings\settings.dat'
    'Running Notepad is closed and unsaved Notepad work can be lost.'
)) {
    if (-not $actionPlanSource.Contains($requiredText)) {
        throw "Action Plan is missing Notepad Settings safety text: $requiredText"
    }
}
foreach ($requiredText in @(
    '$toolId -eq ''notepad-settings'''
    '''Backup status'''
    '''File disposition'''
    '''Package directory exists'''
    '''settings.dat exists'''
    '''Changes executed'''
    '''Compatibility detail'''
    'return ''Not applicable'''
)) {
    if (-not $uiSource.Contains($requiredText)) {
        throw "Latest Result is missing Notepad Settings output: $requiredText"
    }
}
foreach ($requiredText in @(
    $sourceHash
    'SupportsRestore = false'
    'No unrelated AppX package'
    'Approved by Yazan for Phase 32'
)) {
    if (-not $recordSource.Contains($requiredText)) {
        throw "Notepad Settings migration record is incomplete: $requiredText"
    }
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    $plan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Default' -IsDryRun:$false
    if (
        -not [bool]$plan.NeedsExplicitConfirmation -or
        -not [bool]$plan.RequiresAdmin -or
        -not [bool]$plan.Capabilities.CanDeleteFiles -or
        (@($plan.PlannedChanges) -join ' ') -notmatch 'backup' -or
        [string]$plan.ConfirmationMessage -notmatch 'delete only that file'
    ) {
        throw 'Notepad Settings Action Plan does not enforce the approved confirmation and backup policy.'
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$implementedCount = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'modules') -Recurse -File -Filter '*.psm1' |
        Where-Object { $_.Directory.Parent.FullName -eq (Join-Path $ProjectRoot 'modules') } |
        Where-Object { (Get-Content -Raw -LiteralPath $_.FullName).Contains('$script:BoostLabImplementedActions') }
).Count
$placeholderCount = 55 - $implementedCount
if ($implementedCount -ne 39 -or $placeholderCount -ne 16) {
    throw "Unexpected Phase 32 inventory: $implementedCount implemented, $placeholderCount placeholders."
}

$deletedNames = @('Loudness EQ', 'Windows Activation Helper', 'Firewall', 'DEP', 'DDU', 'UAC')
$normalizedCatalog = @($tools | ForEach-Object { ([string]$_['Title'] -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant() })
foreach ($deletedName in $deletedNames) {
    if ((($deletedName -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()) -in $normalizedCatalog) {
        throw "Deleted tool returned to the catalog: $deletedName"
    }
}
if (Test-Path -LiteralPath (Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1')) {
    throw 'Loudness EQ source was reintroduced.'
}

[pscustomobject]@{
    Test = 'Notepad Settings'
    Passed = $true
    SourceHash = $sourceHash
    ImplementedCount = $implementedCount
    PlaceholderCount = $placeholderCount
    Message = 'Notepad Settings passed static and mocked Phase 32 validation.'
}


