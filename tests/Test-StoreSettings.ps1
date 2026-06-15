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
        throw 'Unable to determine the Store Settings test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Setup\StoreSettings.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\3 Setup\7 Store Settings.ps1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$recordPath = Join-Path $ProjectRoot 'docs\migrations\store-settings.md'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$autoDownloadCommand = 'reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" /v "AutoDownload" /t REG_DWORD /d "2" /f'
$defaultDeleteCommand = 'reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore" /f'
$regLoadPrefix = 'reg load "HKLM\Settings"'
$regImportPrefix = 'reg import'
$regUnloadCommand = 'reg unload "HKLM\Settings"'
$windowsStoreProviderPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore'
$autoDownloadProviderValue = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate\AutoDownload'
$expectedHiveValues = [ordered]@{
    'HKLM:\Settings\LocalState|VideoAutoplay' = '00,96,9d,69,8d,cd,93,dc,01'
    'HKLM:\Settings\LocalState|EnableAppInstallNotifications' = '00,36,d0,88,8e,cd,93,dc,01'
    'HKLM:\Settings\LocalState\PersistentSettings|PersonalizationEnabled' = '00,0d,56,a1,8a,cd,93,dc,01'
}

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration['Stages'] | ForEach-Object { $_['Tools'] })
$tool = $tools | Where-Object { $_['Id'] -eq 'store-settings' } | Select-Object -First 1
if ($null -eq $tool) {
    throw 'Store Settings metadata is missing.'
}
if (
    [string]$tool['Stage'] -ne 'Setup' -or
    [int]$tool['Order'] -ne 7 -or
    [string]$tool['Type'] -ne 'action' -or
    [string]$tool['RiskLevel'] -ne 'low' -or
    (@($tool['Actions']) -join ',') -ne 'Apply,Default'
) {
    throw 'Store Settings stage, order, type, risk, or actions are incorrect.'
}

$capabilities = $tool['Capabilities']
$expectedTrueCapabilities = @(
    'RequiresAdmin'
    'CanModifyRegistry'
    'SupportsDefault'
    'NeedsExplicitConfirmation'
)
foreach ($field in $capabilities.Keys) {
    $expected = $field -in $expectedTrueCapabilities
    if ([bool]$capabilities[$field] -ne $expected) {
        throw "Store Settings capability '$field' is incorrect."
    }
}

if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne 'D6B2AF6B399E2E9A34198578472FCCAFB924E2E8B15D1A38B85091BE3DDF3167') {
    throw 'Store Settings Ultimate source hash changed.'
}
$source = Get-Content -Raw -LiteralPath $sourcePath
foreach ($requiredText in @(
    'Start-Process "ms-windows-store:settings"'
    'Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue'
    'reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate`" /v `"AutoDownload`" /t REG_DWORD /d `"2`" /f'
    'Set-Content -Path "$env:SystemRoot\Temp\windowsstore.reg" -Value $storesettings -Force'
    'reg load "HKLM\Settings" $settingsdat'
    'reg import $regfilewindowsstore'
    'reg unload "HKLM\Settings"'
    'reg delete HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore /f'
    'Start-Process "wsreset.exe" -WindowStyle Hidden'
)) {
    if (-not $source.Contains($requiredText)) {
        throw "Store Settings source no longer contains: $requiredText"
    }
}
foreach ($forbiddenSourceText in @(
    'Set-Service'
    'Stop-Service'
    'Invoke-WebRequest'
    'Restart-Computer'
    'shutdown.exe'
    'TrustedInstaller'
    'safeboot'
)) {
    if ($source.Contains($forbiddenSourceText)) {
        throw "Store Settings source failed the Phase 16 safety gate: $forbiddenSourceText"
    }
}

$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredText in @(
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    '$script:BoostLabStoreProcessNames = @(''WinStore.App'', ''backgroundTaskHost'', ''StoreDesktopExtension'')'
    $autoDownloadCommand
    $defaultDeleteCommand
    'Start-Process "ms-windows-store:settings" -ErrorAction Stop'
    'Start-Process "wsreset.exe" -WindowStyle Hidden -ErrorAction Stop'
    'Set-Content -LiteralPath $Path -Value $Content -Force -ErrorAction Stop'
    'reg load "HKLM\Settings"'
    'reg import'
    'reg unload "HKLM\Settings"'
    'VideoAutoplay'
    'EnableAppInstallNotifications'
    'PersonalizationEnabled'
    'function Test-BoostLabStoreSettingsState'
    'New-BoostLabVerificationResult'
    '-VerificationResult $verificationResult'
    '[bool]$Confirmed = $false'
    'Store settings optimized.'
    'Store settings restored to default.'
)) {
    if (-not $moduleSource.Contains($requiredText)) {
        throw "Store Settings module is missing: $requiredText"
    }
}
foreach ($forbiddenModuleText in @(
    'Set-Service'
    'Stop-Service'
    'Restart-Service'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'Restart-Computer'
    'Stop-Computer'
    'UsesTrustedInstaller = $true'
    'safeboot'
    'Remove-Item '
    'Remove-ItemProperty'
)) {
    if ($moduleSource.Contains($forbiddenModuleText)) {
        throw "Store Settings module contains unrelated behavior: $forbiddenModuleText"
    }
}

$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $modulePath,
    [ref]$tokens,
    [ref]$parseErrors
)
if (@($parseErrors).Count -gt 0) {
    throw "Store Settings module syntax error: $($parseErrors[0].Message)"
}
$commands = @(
    $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
        $true
    ) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }
)
if (@($commands | Where-Object { $_ -eq 'Start-Process' }).Count -ne 2) {
    throw 'Store Settings must contain exactly two approved Start-Process calls.'
}
if (@($commands | Where-Object { $_ -eq 'Stop-Process' }).Count -ne 1) {
    throw 'Store Settings must contain one approved Stop-Process call inside the process allowlist helper.'
}

$storeModule = Import-Module `
    -Name $modulePath `
    -Force `
    -PassThru `
    -Prefix 'StoreTest' `
    -Scope Local `
    -DisableNameChecking `
    -ErrorAction Stop
try {
    $infoCommand = Get-Command `
        -Name 'Get-StoreTestBoostLabToolInfo' `
        -Module $storeModule.Name `
        -ErrorAction Stop
    $toolInfo = & $infoCommand
    if (
        [string]$toolInfo.Id -ne 'store-settings' -or
        (@($toolInfo.Actions) -join ',') -ne 'Apply,Default' -or
        (@($toolInfo.ImplementedActions) -join ',') -ne 'Apply,Default'
    ) {
        throw 'Store Settings exported metadata or implemented actions are incorrect.'
    }

    $newRegistryValueState = {
        param(
            [bool]$ReadSucceeded,
            [bool]$Exists,
            [AllowNull()][object]$Value,
            [string]$DisplayValue,
            [string]$Message
        )

        return [pscustomobject]@{
            ReadSucceeded = $ReadSucceeded
            KeyExists     = if ($ReadSucceeded) { $true } else { $null }
            Exists        = $Exists
            Value         = $Value
            DisplayValue  = $DisplayValue
            Message       = $Message
        }
    }
    $newPathState = {
        param(
            [bool]$ReadSucceeded,
            [bool]$Exists,
            [string]$DisplayValue,
            [string]$Message
        )

        return [pscustomobject]@{
            ReadSucceeded = $ReadSucceeded
            Exists        = $Exists
            DisplayValue  = $DisplayValue
            Message       = $Message
        }
    }
    $newProcessResults = {
        return @(
            [pscustomobject]@{ Name = 'WinStore.App'; Status = 'Stopped'; Success = $true; Message = 'Stopped.' }
            [pscustomobject]@{ Name = 'backgroundTaskHost'; Status = 'Stopped'; Success = $true; Message = 'Stopped.' }
            [pscustomobject]@{ Name = 'StoreDesktopExtension'; Status = 'Stopped'; Success = $true; Message = 'Stopped.' }
        )
    }

    $capturedHiveStates = @(
        foreach ($key in $expectedHiveValues.Keys) {
            $parts = $key -split '\|', 2
            $state = & $newRegistryValueState $true $true $expectedHiveValues[$key] $expectedHiveValues[$key] 'Mock Store hive value detected.'
            $state | Add-Member -NotePropertyName 'Path' -NotePropertyValue $parts[0] -Force
            $state | Add-Member -NotePropertyName 'Name' -NotePropertyValue $parts[1] -Force
            $state
        }
    )
    $autoDownloadReader = {
        param($Path, $Name)
        if ($Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate' -and $Name -eq 'AutoDownload') {
            return (& $newRegistryValueState $true $true 2 '2' 'Mock AutoDownload detected.')
        }

        return (& $newRegistryValueState $false $false $null 'Unknown' 'Unexpected registry read.')
    }.GetNewClosure()
    $applyPassed = & $storeModule {
        param($RegistryReader, $CapturedStoreHiveStates)
        Test-BoostLabStoreSettingsState `
            -ActionName 'Apply' `
            -RegistryReader $RegistryReader `
            -CapturedStoreHiveStates $CapturedStoreHiveStates
    } $autoDownloadReader $capturedHiveStates
    if ($applyPassed.Status -ne 'Passed' -or @($applyPassed.Checks).Count -ne 4) {
        throw 'Store Settings Apply verification did not pass with all expected values.'
    }

    $capturedMissingState = @($capturedHiveStates)
    $capturedMissingState[0] = [pscustomobject]@{
        Path = 'HKLM:\Settings\LocalState'
        Name = 'VideoAutoplay'
        ReadSucceeded = $false
        Exists = $false
        Value = $null
        DisplayValue = 'Unknown'
        Message = 'Mock read failure.'
    }
    $applyWarning = & $storeModule {
        param($RegistryReader, $CapturedStoreHiveStates)
        Test-BoostLabStoreSettingsState `
            -ActionName 'Apply' `
            -RegistryReader $RegistryReader `
            -CapturedStoreHiveStates $CapturedStoreHiveStates
    } $autoDownloadReader $capturedMissingState
    if ($applyWarning.Status -ne 'Warning') {
        throw "Store Settings Apply expected Warning, found $($applyWarning.Status)."
    }

    $wrongAutoDownloadReader = {
        param($Path, $Name)
        return (& $newRegistryValueState $true $true 4 '4' 'Mock wrong AutoDownload detected.')
    }.GetNewClosure()
    $applyFailed = & $storeModule {
        param($RegistryReader, $CapturedStoreHiveStates)
        Test-BoostLabStoreSettingsState `
            -ActionName 'Apply' `
            -RegistryReader $RegistryReader `
            -CapturedStoreHiveStates $CapturedStoreHiveStates
    } $wrongAutoDownloadReader $capturedHiveStates
    if ($applyFailed.Status -ne 'Failed') {
        throw "Store Settings Apply expected Failed, found $($applyFailed.Status)."
    }

    $defaultAbsentReader = {
        param($Path, $Name)
        return (& $newRegistryValueState $true $false $null 'Absent' 'Mock AutoDownload absent.')
    }.GetNewClosure()
    $defaultAbsentPathReader = {
        param($Path)
        return (& $newPathState $true $false 'Absent' 'Mock WindowsStore key absent.')
    }.GetNewClosure()
    $defaultPassed = & $storeModule {
        param($RegistryReader, $RegistryPathReader)
        Test-BoostLabStoreSettingsState `
            -ActionName 'Default' `
            -RegistryReader $RegistryReader `
            -RegistryPathReader $RegistryPathReader
    } $defaultAbsentReader $defaultAbsentPathReader
    if ($defaultPassed.Status -ne 'Passed' -or @($defaultPassed.Checks).Count -ne 1) {
        throw 'Store Settings Default verification did not pass when WindowsStore key is absent.'
    }

    $defaultPresentPathReader = {
        param($Path)
        return (& $newPathState $true $true 'Present' 'Mock WindowsStore key remains.')
    }.GetNewClosure()
    $defaultFailed = & $storeModule {
        param($RegistryReader, $RegistryPathReader)
        Test-BoostLabStoreSettingsState `
            -ActionName 'Default' `
            -RegistryReader $RegistryReader `
            -RegistryPathReader $RegistryPathReader
    } $defaultAbsentReader $defaultPresentPathReader
    if ($defaultFailed.Status -ne 'Failed') {
        throw "Store Settings Default expected Failed, found $($defaultFailed.Status)."
    }

    $applyEvents = [System.Collections.Generic.List[string]]::new()
    $applyCommandInvoker = {
        param($CommandText)
        $applyEvents.Add("COMMAND:$CommandText")
    }.GetNewClosure()
    $applyStoreLauncher = {
        param($Target)
        $applyEvents.Add("LAUNCH:$Target")
    }.GetNewClosure()
    $applyDelay = {
        param($Seconds)
        $applyEvents.Add("DELAY:$Seconds")
    }.GetNewClosure()
    $applyFileWriter = {
        param($Path, $Content)
        $applyEvents.Add("FILE:$Path")
        if ($Content -notmatch 'PersonalizationEnabled') {
            throw 'Mock registry content missing personalization setting.'
        }
    }.GetNewClosure()
    $applyPathTester = {
        param($Path)
        $applyEvents.Add("PATH:$Path")
        return $true
    }.GetNewClosure()
    $applyRegistryReader = {
        param($Path, $Name)
        if ($Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate') {
            return (& $newRegistryValueState $true $true 2 '2' 'Mock AutoDownload detected.')
        }

        $expected = $expectedHiveValues["$Path|$Name"]
        return (& $newRegistryValueState $true $true $expected $expected 'Mock Store hive value detected.')
    }.GetNewClosure()
    $processStopper = {
        $applyEvents.Add('PROCESSES')
        return (& $newProcessResults)
    }.GetNewClosure()
    $applyResult = & $storeModule {
        param($CommandInvoker, $StoreLauncher, $Delay, $FileWriter, $PathTester, $RegistryReader, $ProcessStopper)
        Invoke-BoostLabStoreSettingsAction `
            -ActionName 'Apply' `
            -AdministratorChecker { return $true } `
            -RegistryCommandInvoker $CommandInvoker `
            -StoreLauncher $StoreLauncher `
            -DelayInvoker $Delay `
            -RegistryFileWriter $FileWriter `
            -PathTester $PathTester `
            -RegistryReader $RegistryReader `
            -ProcessStopper $ProcessStopper `
            -SystemRoot 'C:\Windows' `
            -LocalAppData 'C:\Users\Tester\AppData\Local'
    } $applyCommandInvoker $applyStoreLauncher $applyDelay $applyFileWriter $applyPathTester $applyRegistryReader $processStopper
    if (
        -not $applyResult.Success -or
        $applyResult.Message -ne 'Store settings optimized.' -or
        $applyResult.VerificationResult.Status -ne 'Passed' -or
        $applyResult.Data.CommandStatus -ne 'Completed'
    ) {
        throw 'Mocked Store Settings Apply did not return the expected structured result.'
    }
    $applyEventText = $applyEvents -join '|'
    foreach ($requiredEventText in @(
        'LAUNCH:Settings'
        'DELAY:5'
        'PROCESSES'
        "COMMAND:$autoDownloadCommand"
        'FILE:C:\Windows\Temp\windowsstore.reg'
        'PATH:C:\Users\Tester\AppData\Local\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\Settings\settings.dat'
        'COMMAND:reg load "HKLM\Settings" "C:\Users\Tester\AppData\Local\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\Settings\settings.dat"'
        'COMMAND:reg import "C:\Windows\Temp\windowsstore.reg"'
        "COMMAND:$regUnloadCommand"
    )) {
        if ($applyEventText -notmatch [regex]::Escape($requiredEventText)) {
            throw "Mocked Store Settings Apply did not record: $requiredEventText"
        }
    }
    if ($applyEventText.IndexOf("COMMAND:$autoDownloadCommand") -gt $applyEventText.IndexOf('COMMAND:reg load "HKLM\Settings"')) {
        throw 'Store Settings Apply command order changed: AutoDownload must be set before loading the Store hive.'
    }

    $defaultEvents = [System.Collections.Generic.List[string]]::new()
    $defaultCommandInvoker = {
        param($CommandText)
        $defaultEvents.Add("COMMAND:$CommandText")
    }.GetNewClosure()
    $defaultStoreLauncher = {
        param($Target)
        $defaultEvents.Add("LAUNCH:$Target")
    }.GetNewClosure()
    $defaultDelay = {
        param($Seconds)
        $defaultEvents.Add("DELAY:$Seconds")
    }.GetNewClosure()
    $defaultProcessStopper = {
        $defaultEvents.Add('PROCESSES')
        return (& $newProcessResults)
    }.GetNewClosure()
    $defaultPathStates = [System.Collections.Generic.Queue[object]]::new()
    $defaultPathStates.Enqueue((& $newPathState $true $true 'Present' 'Mock key exists before Default.'))
    $defaultPathStates.Enqueue((& $newPathState $true $false 'Absent' 'Mock key absent after Default.'))
    $defaultPathReader = { return $defaultPathStates.Dequeue() }.GetNewClosure()
    $defaultResult = & $storeModule {
        param($CommandInvoker, $StoreLauncher, $Delay, $ProcessStopper, $RegistryReader, $RegistryPathReader)
        Invoke-BoostLabStoreSettingsAction `
            -ActionName 'Default' `
            -AdministratorChecker { return $true } `
            -RegistryCommandInvoker $CommandInvoker `
            -StoreLauncher $StoreLauncher `
            -DelayInvoker $Delay `
            -ProcessStopper $ProcessStopper `
            -RegistryReader $RegistryReader `
            -RegistryPathReader $RegistryPathReader `
            -SystemRoot 'C:\Windows' `
            -LocalAppData 'C:\Users\Tester\AppData\Local'
    } $defaultCommandInvoker $defaultStoreLauncher $defaultDelay $defaultProcessStopper $defaultAbsentReader $defaultPathReader
    if (
        -not $defaultResult.Success -or
        $defaultResult.Message -ne 'Store settings restored to default.' -or
        $defaultResult.VerificationResult.Status -ne 'Passed' -or
        $defaultResult.Data.CommandStatus -ne 'Completed'
    ) {
        throw 'Mocked Store Settings Default did not return the expected structured result.'
    }
    $defaultEventText = $defaultEvents -join '|'
    foreach ($requiredEventText in @(
        "COMMAND:$defaultDeleteCommand"
        'PROCESSES'
        'LAUNCH:Reset'
        'LAUNCH:Settings'
    )) {
        if ($defaultEventText -notmatch [regex]::Escape($requiredEventText)) {
            throw "Mocked Store Settings Default did not record: $requiredEventText"
        }
    }
    if ($defaultEventText.IndexOf("COMMAND:$defaultDeleteCommand") -gt $defaultEventText.IndexOf('LAUNCH:Reset')) {
        throw 'Store Settings Default command order changed: registry delete must happen before wsreset.exe.'
    }

    $alreadyDefaultEvents = [System.Collections.Generic.List[string]]::new()
    $alreadyDefaultPathReader = {
        param($Path)
        return (& $newPathState $true $false 'Absent' 'Mock key already absent.')
    }.GetNewClosure()
    $alreadyDefaultCommandInvoker = {
        param($CommandText)
        $alreadyDefaultEvents.Add("COMMAND:$CommandText")
    }.GetNewClosure()
    $alreadyDefaultLauncher = {
        param($Target)
        $alreadyDefaultEvents.Add("LAUNCH:$Target")
    }.GetNewClosure()
    $alreadyDefaultProcessStopper = {
        $alreadyDefaultEvents.Add('PROCESSES')
        return (& $newProcessResults)
    }.GetNewClosure()
    $alreadyDefaultResult = & $storeModule {
        param($CommandInvoker, $StoreLauncher, $ProcessStopper, $RegistryReader, $RegistryPathReader)
        Invoke-BoostLabStoreSettingsAction `
            -ActionName 'Default' `
            -AdministratorChecker { return $true } `
            -RegistryCommandInvoker $CommandInvoker `
            -StoreLauncher $StoreLauncher `
            -DelayInvoker { param($Seconds) } `
            -ProcessStopper $ProcessStopper `
            -RegistryReader $RegistryReader `
            -RegistryPathReader $RegistryPathReader `
            -SystemRoot 'C:\Windows' `
            -LocalAppData 'C:\Users\Tester\AppData\Local'
    } $alreadyDefaultCommandInvoker $alreadyDefaultLauncher $alreadyDefaultProcessStopper $defaultAbsentReader $alreadyDefaultPathReader
    if (
        -not $alreadyDefaultResult.Success -or
        $alreadyDefaultResult.Data.CommandStatus -ne 'Registry already default' -or
        @($alreadyDefaultEvents | Where-Object { $_ -like 'COMMAND:*' }).Count -ne 0 -or
        @($alreadyDefaultEvents | Where-Object { $_ -eq 'LAUNCH:Reset' }).Count -ne 1 -or
        @($alreadyDefaultEvents | Where-Object { $_ -eq 'LAUNCH:Settings' }).Count -ne 1
    ) {
        throw 'Store Settings Default did not keep Store reset behavior when the registry was already default.'
    }

    foreach ($result in @($applyResult, $defaultResult, $alreadyDefaultResult)) {
        foreach ($field in @(
            'Success'
            'ToolId'
            'ToolTitle'
            'Action'
            'Message'
            'RestartRequired'
            'Cancelled'
            'Timestamp'
            'Data'
            'VerificationResult'
        )) {
            if ($null -eq $result.PSObject.Properties[$field]) {
                throw "Store Settings result is missing field: $field"
            }
        }
        foreach ($dataField in @(
            'CommandStatus'
            'ExpectedStoreSettingsState'
            'DetectedStoreSettingsState'
            'RegistryValuesChecked'
            'ProcessActions'
            'StoreUiActions'
            'CompletedAt'
        )) {
            if ($null -eq $result.Data.PSObject.Properties[$dataField]) {
                throw "Store Settings result data is missing field: $dataField"
            }
        }
    }
}
finally {
    Remove-Module -ModuleInfo $storeModule -Force -ErrorAction SilentlyContinue
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    foreach ($actionName in @('Apply', 'Default')) {
        $plan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName $actionName -IsDryRun $false
        if (
            -not $plan.RequiresAdmin -or
            -not $plan.NeedsExplicitConfirmation -or
            $plan.CanReboot -or
            $plan.RequiresInternet -or
            $plan.UsesTrustedInstaller -or
            $plan.ConfirmationMessage -notmatch 'Store' -or
            $plan.ConfirmationMessage -notmatch 'No restart is required'
        ) {
            throw "Store Settings $actionName Action Plan is incorrect."
        }
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredText in @(
    '''store-settings'' = @{'
    '''Setup\StoreSettings.psm1'''
    'Actions = @(''Apply'', ''Default'')'
    '$actionCommand.Parameters.ContainsKey(''Confirmed'')'
    'Test-BoostLabVerificationResult'
)) {
    if (-not $executionSource.Contains($requiredText)) {
        throw "Store Settings runtime mapping is missing: $requiredText"
    }
}

$uiSource = Get-Content -Raw -LiteralPath $uiPath
foreach ($requiredText in @(
    '$toolId -eq ''store-settings'''
    '-Label ''Command Status'''
    '-Label ''Verification Status'''
    '-Label ''Expected Store Settings state'''
    '-Label ''Detected Store Settings state'''
    '-Label ''Registry values checked'''
    '-Label ''Process actions'''
    '-Label ''Store UI actions'''
    '-Label ''Timestamp'''
)) {
    if (-not $uiSource.Contains($requiredText)) {
        throw "Store Settings Latest Result rendering is missing: $requiredText"
    }
}

$record = Get-Content -Raw -LiteralPath $recordPath
foreach ($requiredText in @(
    'source-ultimate/3 Setup/7 Store Settings.ps1'
    'D6B2AF6B399E2E9A34198578472FCCAFB924E2E8B15D1A38B85091BE3DDF3167'
    'Approved by Yazan'
    $autoDownloadCommand
    $defaultDeleteCommand
    'Start-Process "ms-windows-store:settings"'
    'Start-Process "wsreset.exe" -WindowStyle Hidden'
    'WinStore.App'
    'backgroundTaskHost'
    'StoreDesktopExtension'
    'Verification Strategy'
    'Automated tests must not modify the real registry, stop real processes, write the temporary `.reg` file, launch Store UI, or run `wsreset.exe`.'
)) {
    if (-not $record.Contains($requiredText)) {
        throw "Store Settings migration record is missing: $requiredText"
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
if ($implementedCount -ne 26 -or $placeholderCount -ne 22) {
    throw "Unexpected module counts: $implementedCount implemented, $placeholderCount placeholders."
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
        Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
        ForEach-Object {
            '{0}|{1}' -f `
                $_.FullName.Substring($root.Length + 1).Replace('\', '/'), `
                (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
        }
)
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
    $sourceLines.Count -ne 49 -or
    $sourceManifestHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477'
) {
    throw 'source-ultimate content or paths changed.'
}

[pscustomobject]@{
    Success                 = $true
    ToolId                  = 'store-settings'
    ImplementedActions      = @('Apply', 'Default')
    ApplyExecuted           = $false
    DefaultExecuted         = $false
    MockedApplyPassed       = $true
    MockedDefaultPassed     = $true
    ImplementedModuleCount  = $implementedCount
    PlaceholderModuleCount  = $placeholderCount
    SourceUltimateUnchanged = $true
    Message                 = 'Store Settings Apply/Default and verification were validated with mocks only.'
    Timestamp               = Get-Date
}
