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
        throw 'Unable to determine the Background Apps test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Setup\BackgroundApps.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\3 Setup\5 Background Apps.ps1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$recordPath = Join-Path $ProjectRoot 'docs\migrations\background-apps.md'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$applyCommand = 'reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /t REG_DWORD /d "2" /f'
$defaultCommand = 'reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /f'
$providerValuePath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy\LetAppsRunInBackground'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration['Stages'] | ForEach-Object { $_['Tools'] })
$tool = $tools | Where-Object { $_['Id'] -eq 'background-apps' } | Select-Object -First 1
if ($null -eq $tool) {
    throw 'Background Apps metadata is missing.'
}
if (
    [string]$tool['Stage'] -ne 'Setup' -or
    [int]$tool['Order'] -ne 5 -or
    [string]$tool['Type'] -ne 'action' -or
    [string]$tool['RiskLevel'] -ne 'low' -or
    (@($tool['Actions']) -join ',') -ne 'Apply,Default'
) {
    throw 'Background Apps stage, order, type, risk, or actions are incorrect.'
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
        throw "Background Apps capability '$field' is incorrect."
    }
}

if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne '2DF15DE03306CCAF19180940F215972E943EA94E7B2C52B7D6EC2B6403E79445') {
    throw 'Background Apps Ultimate source hash changed.'
}
$source = Get-Content -Raw -LiteralPath $sourcePath
foreach ($requiredText in @(
    'reg add `"HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy`" /v `"LetAppsRunInBackground`" /t REG_DWORD /d `"2`" /f'
    'reg delete `"HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy`" /v `"LetAppsRunInBackground`" /f'
    'Start-Process ms-settings:privacy-backgroundapps'
)) {
    if (-not $source.Contains($requiredText)) {
        throw "Background Apps source no longer contains: $requiredText"
    }
}
foreach ($forbiddenSourceText in @(
    'Stop-Process'
    'Set-Service'
    'Stop-Service'
    'Invoke-WebRequest'
    'Restart-Computer'
    'shutdown.exe'
    'UsesTrustedInstaller = $true'
    'safeboot'
)) {
    if ($source.Contains($forbiddenSourceText)) {
        throw "Background Apps source failed the Phase 15 safety gate: $forbiddenSourceText"
    }
}

$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredText in @(
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    $applyCommand
    $defaultCommand
    'Start-Process ms-settings:privacy-backgroundapps -ErrorAction Stop'
    '$script:BoostLabAppPrivacyProviderPath = ''HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy'''
    '$script:BoostLabBackgroundAppsValueName = ''LetAppsRunInBackground'''
    'function Test-BoostLabBackgroundAppsState'
    'New-BoostLabVerificationResult'
    '-VerificationResult $verificationResult'
    '[bool]$Confirmed = $false'
    'Background apps disabled.'
    'Background apps restored to default.'
    'Background Apps already default.'
)) {
    if (-not $moduleSource.Contains($requiredText)) {
        throw "Background Apps module is missing: $requiredText"
    }
}
foreach ($forbiddenModuleText in @(
    'Stop-Process'
    'Get-Process'
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
        throw "Background Apps module contains unrelated behavior: $forbiddenModuleText"
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
    throw "Background Apps module syntax error: $($parseErrors[0].Message)"
}
$commands = @(
    $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
        $true
    ) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }
)
if (@($commands | Where-Object { $_ -eq 'Start-Process' }).Count -ne 1) {
    throw 'Background Apps must contain exactly one approved Start-Process call.'
}

$backgroundModule = Import-Module `
    -Name $modulePath `
    -Force `
    -PassThru `
    -Prefix 'BackgroundTest' `
    -Scope Local `
    -DisableNameChecking `
    -ErrorAction Stop
try {
    $infoCommand = Get-Command `
        -Name 'Get-BackgroundTestBoostLabToolInfo' `
        -Module $backgroundModule.Name `
        -ErrorAction Stop
    $toolInfo = & $infoCommand
    if (
        [string]$toolInfo.Id -ne 'background-apps' -or
        (@($toolInfo.Actions) -join ',') -ne 'Apply,Default' -or
        (@($toolInfo.ImplementedActions) -join ',') -ne 'Apply,Default'
    ) {
        throw 'Background Apps exported metadata or implemented actions are incorrect.'
    }

    $newRegistryState = {
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

    foreach ($verificationCase in @(
        [pscustomobject]@{
            Action = 'Apply'
            State = & $newRegistryState $true $true 2 '2' 'Mock value detected.'
            ExpectedStatus = 'Passed'
        }
        [pscustomobject]@{
            Action = 'Default'
            State = & $newRegistryState $true $false $null 'Absent' 'Mock value is absent.'
            ExpectedStatus = 'Passed'
        }
        [pscustomobject]@{
            Action = 'Apply'
            State = & $newRegistryState $true $true 1 '1' 'Mock contradictory value.'
            ExpectedStatus = 'Failed'
        }
        [pscustomobject]@{
            Action = 'Default'
            State = & $newRegistryState $true $true 2 '2' 'Mock blocking value remains.'
            ExpectedStatus = 'Failed'
        }
        [pscustomobject]@{
            Action = 'Apply'
            State = & $newRegistryState $false $false $null 'Unknown' 'Mock read failure.'
            ExpectedStatus = 'Warning'
        }
    )) {
        $mockState = $verificationCase.State
        $registryReader = { return $mockState }.GetNewClosure()
        $verification = & $backgroundModule {
            param($ActionName, $RegistryReader)
            Test-BoostLabBackgroundAppsState `
                -ActionName $ActionName `
                -RegistryReader $RegistryReader
        } $verificationCase.Action $registryReader

        if ($verification.Status -ne $verificationCase.ExpectedStatus) {
            throw "Background Apps $($verificationCase.Action) expected $($verificationCase.ExpectedStatus), found $($verification.Status)."
        }
        if (@($verification.Checks).Count -ne 1) {
            throw 'Background Apps VerificationResult must contain one registry check.'
        }
        if ([string]$verification.Checks[0].Name -ne $providerValuePath) {
            throw 'Background Apps verification checks the wrong registry value.'
        }
    }

    $nullVerification = & $backgroundModule {
        Test-BoostLabBackgroundAppsState `
            -ActionName 'Default' `
            -RegistryReader { return $null }
    }
    if ($nullVerification.Status -ne 'Warning') {
        throw 'Background Apps null registry state was not normalized to Warning.'
    }

    $applyEvents = [System.Collections.Generic.List[string]]::new()
    $applyCommandInvoker = {
        param($CommandText)
        $applyEvents.Add("COMMAND:$CommandText")
    }.GetNewClosure()
    $applySettingsLauncher = {
        $applyEvents.Add('SETTINGS:ms-settings:privacy-backgroundapps')
    }.GetNewClosure()
    $applyState = & $newRegistryState $true $true 2 '2' 'Mock value detected.'
    $applyReader = { return $applyState }.GetNewClosure()
    $applyResult = & $backgroundModule {
        param($CommandInvoker, $SettingsLauncher, $RegistryReader)
        Invoke-BoostLabBackgroundAppsAction `
            -ActionName 'Apply' `
            -AdministratorChecker { return $true } `
            -RegistryCommandInvoker $CommandInvoker `
            -SettingsLauncher $SettingsLauncher `
            -RegistryReader $RegistryReader
    } $applyCommandInvoker $applySettingsLauncher $applyReader
    if (
        -not $applyResult.Success -or
        $applyResult.Message -ne 'Background apps disabled.' -or
        $applyResult.Data.CommandStatus -ne 'Completed' -or
        $applyResult.Data.SettingsPageStatus -ne 'Launched' -or
        $applyResult.VerificationResult.Status -ne 'Passed' -or
        $applyEvents.Count -ne 2 -or
        $applyEvents[0] -ne "COMMAND:$applyCommand" -or
        $applyEvents[1] -ne 'SETTINGS:ms-settings:privacy-backgroundapps'
    ) {
        throw 'Mocked Background Apps Apply did not preserve command and Settings launch order.'
    }

    $defaultEvents = [System.Collections.Generic.List[string]]::new()
    $defaultStates = [System.Collections.Generic.Queue[object]]::new()
    $defaultStates.Enqueue(
        (& $newRegistryState $true $true 2 '2' 'Mock policy exists before Default.')
    )
    $defaultStates.Enqueue(
        (& $newRegistryState $true $false $null 'Absent' 'Mock value absent after Default.')
    )
    $defaultReader = {
        return $defaultStates.Dequeue()
    }.GetNewClosure()
    $defaultCommandInvoker = {
        param($CommandText)
        $defaultEvents.Add("COMMAND:$CommandText")
    }.GetNewClosure()
    $defaultSettingsLauncher = {
        $defaultEvents.Add('SETTINGS:ms-settings:privacy-backgroundapps')
    }.GetNewClosure()
    $defaultResult = & $backgroundModule {
        param($CommandInvoker, $SettingsLauncher, $RegistryReader)
        Invoke-BoostLabBackgroundAppsAction `
            -ActionName 'Default' `
            -AdministratorChecker { return $true } `
            -RegistryCommandInvoker $CommandInvoker `
            -SettingsLauncher $SettingsLauncher `
            -RegistryReader $RegistryReader
    } $defaultCommandInvoker $defaultSettingsLauncher $defaultReader
    if (
        -not $defaultResult.Success -or
        $defaultResult.Message -ne 'Background apps restored to default.' -or
        $defaultResult.VerificationResult.Status -ne 'Passed' -or
        $defaultEvents.Count -ne 2 -or
        $defaultEvents[0] -ne "COMMAND:$defaultCommand" -or
        $defaultEvents[1] -ne 'SETTINGS:ms-settings:privacy-backgroundapps'
    ) {
        throw 'Mocked Background Apps Default did not preserve command and Settings launch order.'
    }

    $alreadyDefaultEvents = [System.Collections.Generic.List[string]]::new()
    $alreadyDefaultState = & $newRegistryState $true $false $null 'Absent' 'Mock value is already absent.'
    $alreadyDefaultReader = { return $alreadyDefaultState }.GetNewClosure()
    $alreadyDefaultCommandInvoker = {
        param($CommandText)
        $alreadyDefaultEvents.Add("COMMAND:$CommandText")
    }.GetNewClosure()
    $alreadyDefaultSettingsLauncher = {
        $alreadyDefaultEvents.Add('SETTINGS:ms-settings:privacy-backgroundapps')
    }.GetNewClosure()
    $alreadyDefaultResult = & $backgroundModule {
        param($CommandInvoker, $SettingsLauncher, $RegistryReader)
        Invoke-BoostLabBackgroundAppsAction `
            -ActionName 'Default' `
            -AdministratorChecker { return $true } `
            -RegistryCommandInvoker $CommandInvoker `
            -SettingsLauncher $SettingsLauncher `
            -RegistryReader $RegistryReader
    } $alreadyDefaultCommandInvoker $alreadyDefaultSettingsLauncher $alreadyDefaultReader
    if (
        -not $alreadyDefaultResult.Success -or
        $alreadyDefaultResult.Message -ne 'Background Apps already default.' -or
        $alreadyDefaultResult.Data.CommandStatus -ne 'Already default' -or
        $alreadyDefaultEvents.Count -ne 1 -or
        $alreadyDefaultEvents[0] -ne 'SETTINGS:ms-settings:privacy-backgroundapps'
    ) {
        throw 'Background Apps Default is not idempotent when the policy value is absent.'
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
                throw "Background Apps result is missing field: $field"
            }
        }
        foreach ($dataField in @(
            'CommandStatus'
            'ExpectedBackgroundAppsState'
            'DetectedBackgroundAppsState'
            'RegistryValuesChecked'
            'SettingsPageStatus'
            'CompletedAt'
        )) {
            if ($null -eq $result.Data.PSObject.Properties[$dataField]) {
                throw "Background Apps result data is missing field: $dataField"
            }
        }
    }
}
finally {
    Remove-Module -ModuleInfo $backgroundModule -Force -ErrorAction SilentlyContinue
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
            $plan.ConfirmationMessage -notmatch 'LetAppsRunInBackground' -or
            $plan.ConfirmationMessage -notmatch 'No restart is required'
        ) {
            throw "Background Apps $actionName Action Plan is incorrect."
        }
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredText in @(
    '''background-apps'' = @{'
    '''Setup\BackgroundApps.psm1'''
    'Actions = @(''Apply'', ''Default'')'
    '$actionCommand.Parameters.ContainsKey(''Confirmed'')'
    'Test-BoostLabVerificationResult'
)) {
    if (-not $executionSource.Contains($requiredText)) {
        throw "Background Apps runtime mapping is missing: $requiredText"
    }
}

$uiSource = Get-Content -Raw -LiteralPath $uiPath
foreach ($requiredText in @(
    '$toolId -eq ''background-apps'''
    '-Label ''Command Status'''
    '-Label ''Verification Status'''
    '-Label ''Expected Background Apps state'''
    '-Label ''Detected Background Apps state'''
    '-Label ''Registry values checked'''
    '-Label ''Settings page'''
    '-Label ''Timestamp'''
)) {
    if (-not $uiSource.Contains($requiredText)) {
        throw "Background Apps Latest Result rendering is missing: $requiredText"
    }
}

$record = Get-Content -Raw -LiteralPath $recordPath
foreach ($requiredText in @(
    'source-ultimate/3 Setup/5 Background Apps.ps1'
    '2DF15DE03306CCAF19180940F215972E943EA94E7B2C52B7D6EC2B6403E79445'
    'Approved by Yazan'
    $applyCommand
    $defaultCommand
    'Start-Process ms-settings:privacy-backgroundapps'
    'Default is idempotent'
    'Verification Strategy'
    'Automated tests must not modify the real registry or open the Settings page.'
)) {
    if (-not $record.Contains($requiredText)) {
        throw "Background Apps migration record is missing: $requiredText"
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
if ($implementedCount -ne 35 -or $placeholderCount -ne 18) {
    throw "Unexpected module counts: $implementedCount implemented, $placeholderCount placeholders."
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
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
    ToolId                  = 'background-apps'
    ImplementedActions      = @('Apply', 'Default')
    ApplyExecuted           = $false
    DefaultExecuted         = $false
    MockedApplyPassed       = $true
    MockedDefaultPassed     = $true
    ImplementedModuleCount  = $implementedCount
    PlaceholderModuleCount  = $placeholderCount
    SourceUltimateUnchanged = $true
    Message                 = 'Background Apps Apply/Default and verification were validated with mocks only.'
    Timestamp               = Get-Date
}


