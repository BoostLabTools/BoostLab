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
        throw 'Unable to determine the Updates Pause test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Setup\UpdatesPause.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\3 Setup\8 Updates Pause.ps1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$recordPath = Join-Path $ProjectRoot 'docs\migrations\updates-pause.md'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$registryPath = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
$valueDefinitions = [ordered]@{
    PauseUpdatesExpiryTime       = 'Expiry'
    PauseFeatureUpdatesEndTime   = 'Expiry'
    PauseFeatureUpdatesStartTime = 'Start'
    PauseQualityUpdatesEndTime   = 'Expiry'
    PauseQualityUpdatesStartTime = 'Start'
    PauseUpdatesStartTime        = 'Start'
}

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration['Stages'] | ForEach-Object { $_['Tools'] })
$tool = $tools | Where-Object { $_['Id'] -eq 'updates-pause' } | Select-Object -First 1
if ($null -eq $tool) {
    throw 'Updates Pause metadata is missing.'
}
if (
    [string]$tool['Stage'] -ne 'Setup' -or
    [int]$tool['Order'] -ne 8 -or
    [string]$tool['Type'] -ne 'action' -or
    [string]$tool['RiskLevel'] -ne 'low' -or
    (@($tool['Actions']) -join ',') -ne 'Apply,Default'
) {
    throw 'Updates Pause stage, order, type, risk, or actions are incorrect.'
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
        throw "Updates Pause capability '$field' is incorrect."
    }
}

if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne '4BBEF16C51FBEBAFAECB58307F8C619A37CD10BB3DC489BD4DF9A59DDBD1A0BD') {
    throw 'Updates Pause Ultimate source hash changed.'
}
$source = Get-Content -Raw -LiteralPath $sourcePath
foreach ($requiredText in @(
    '$pause = (Get-Date).AddDays(365)'
    '$today = Get-Date'
    '$today = $today.ToUniversalTime().ToString( "yyyy-MM-ddTHH:mm:ssZ" )'
    '$pause = $pause.ToUniversalTime().ToString( "yyyy-MM-ddTHH:mm:ssZ" )'
    'Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -Value $pause -Force'
    'Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseFeatureUpdatesEndTime" -Value $pause -Force'
    'Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseFeatureUpdatesStartTime" -Value $today -Force'
    'Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseQualityUpdatesEndTime" -Value $pause -Force'
    'Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseQualityUpdatesStartTime" -Value $today -Force'
    'Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesStartTime" -Value $today -Force'
    'Start-Process ms-settings:windowsupdate'
)) {
    if (-not $source.Contains($requiredText)) {
        throw "Updates Pause source no longer contains: $requiredText"
    }
}
foreach ($forbiddenSourceText in @(
    'Set-Service'
    'Stop-Service'
    'Restart-Service'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'Restart-Computer'
    'Stop-Computer'
    'shutdown.exe'
    'bcdedit'
    'TrustedInstaller'
    'safeboot'
    'Stop-Process'
)) {
    if ($source.Contains($forbiddenSourceText)) {
        throw "Updates Pause source failed the Phase 17 safety gate: $forbiddenSourceText"
    }
}

$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredText in @(
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    '$script:BoostLabUpdatesPauseRegistryPath = ''HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'''
    '.AddDays(365).ToUniversalTime().ToString(''yyyy-MM-ddTHH:mm:ssZ'')'
    'Set-ItemProperty'
    'Remove-ItemProperty'
    'Start-Process ms-settings:windowsupdate -ErrorAction Stop'
    'function Test-BoostLabUpdatesPauseState'
    'New-BoostLabVerificationResult'
    '-VerificationResult $verificationResult'
    '[bool]$Confirmed = $false'
    'Windows updates paused for 365 days.'
    'Windows Update pause values restored to default.'
    'Windows Update pause values are already default.'
)) {
    if (-not $moduleSource.Contains($requiredText)) {
        throw "Updates Pause module is missing: $requiredText"
    }
}
foreach ($valueName in $valueDefinitions.Keys) {
    if (-not $moduleSource.Contains([string]$valueName)) {
        throw "Updates Pause module is missing source value: $valueName"
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
    'shutdown.exe'
    'bcdedit'
    'Stop-Process'
    'UsesTrustedInstaller = $true'
    'safeboot'
)) {
    if ($moduleSource.Contains($forbiddenModuleText)) {
        throw "Updates Pause module contains unrelated behavior: $forbiddenModuleText"
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
    throw "Updates Pause module syntax error: $($parseErrors[0].Message)"
}
$commands = @(
    $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
        $true
    ) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }
)
if (@($commands | Where-Object { $_ -eq 'Start-Process' }).Count -ne 1) {
    throw 'Updates Pause must contain exactly one approved Start-Process call.'
}
if (@($commands | Where-Object { $_ -eq 'Set-ItemProperty' }).Count -ne 1) {
    throw 'Updates Pause must contain one registry write helper.'
}
if (@($commands | Where-Object { $_ -eq 'Remove-ItemProperty' }).Count -ne 1) {
    throw 'Updates Pause must contain one registry removal helper.'
}

$updatesModule = Import-Module `
    -Name $modulePath `
    -Force `
    -PassThru `
    -Prefix 'UpdatesTest' `
    -Scope Local `
    -DisableNameChecking `
    -ErrorAction Stop
try {
    $infoCommand = Get-Command `
        -Name 'Get-UpdatesTestBoostLabToolInfo' `
        -Module $updatesModule.Name `
        -ErrorAction Stop
    $toolInfo = & $infoCommand
    if (
        [string]$toolInfo.Id -ne 'updates-pause' -or
        (@($toolInfo.Actions) -join ',') -ne 'Apply,Default' -or
        (@($toolInfo.ImplementedActions) -join ',') -ne 'Apply,Default'
    ) {
        throw 'Updates Pause exported metadata or implemented actions are incorrect.'
    }

    $newRegistryState = {
        param(
            [bool]$ReadSucceeded,
            [bool]$Exists,
            [AllowNull()][object]$Value,
            [string]$Message
        )

        return [pscustomobject]@{
            ReadSucceeded = $ReadSucceeded
            KeyExists     = if ($ReadSucceeded) { $true } else { $null }
            Exists        = $Exists
            Value         = $Value
            DisplayValue  = if (-not $ReadSucceeded) {
                'Unknown'
            }
            elseif ($Exists) {
                [string]$Value
            }
            else {
                'Absent'
            }
            Message       = $Message
        }
    }

    $pauseBase = [datetime]'2026-06-09T08:00:00+03:00'
    $today = [datetime]'2026-06-09T08:00:01+03:00'
    $expectedExpiry = $pauseBase.AddDays(365).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $expectedStart = $today.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $expectedValues = [ordered]@{}
    foreach ($entry in $valueDefinitions.GetEnumerator()) {
        $expectedValues[$entry.Key] = if ($entry.Value -eq 'Expiry') {
            $expectedExpiry
        }
        else {
            $expectedStart
        }
    }

    $applyVerificationReader = {
        param($Name)
        return (& $newRegistryState $true $true $expectedValues[$Name] 'Mock value detected.')
    }.GetNewClosure()
    $applyVerification = & $updatesModule {
        param($ExpectedValues, $RegistryReader)
        Test-BoostLabUpdatesPauseState `
            -ActionName 'Apply' `
            -ExpectedValues $ExpectedValues `
            -RegistryReader $RegistryReader
    } $expectedValues $applyVerificationReader
    if ($applyVerification.Status -ne 'Passed' -or @($applyVerification.Checks).Count -ne 6) {
        throw 'Updates Pause Apply verification did not pass all six values.'
    }

    $warningReader = {
        param($Name)
        if ($Name -eq 'PauseUpdatesStartTime') {
            return (& $newRegistryState $false $false $null 'Mock read failure.')
        }

        return (& $newRegistryState $true $true $expectedValues[$Name] 'Mock value detected.')
    }.GetNewClosure()
    $warningVerification = & $updatesModule {
        param($ExpectedValues, $RegistryReader)
        Test-BoostLabUpdatesPauseState `
            -ActionName 'Apply' `
            -ExpectedValues $ExpectedValues `
            -RegistryReader $RegistryReader
    } $expectedValues $warningReader
    if ($warningVerification.Status -ne 'Warning') {
        throw "Updates Pause expected Warning, found $($warningVerification.Status)."
    }

    $failedReader = {
        param($Name)
        $value = if ($Name -eq 'PauseUpdatesExpiryTime') {
            '2000-01-01T00:00:00Z'
        }
        else {
            $expectedValues[$Name]
        }
        return (& $newRegistryState $true $true $value 'Mock value detected.')
    }.GetNewClosure()
    $failedVerification = & $updatesModule {
        param($ExpectedValues, $RegistryReader)
        Test-BoostLabUpdatesPauseState `
            -ActionName 'Apply' `
            -ExpectedValues $ExpectedValues `
            -RegistryReader $RegistryReader
    } $expectedValues $failedReader
    if ($failedVerification.Status -ne 'Failed') {
        throw "Updates Pause expected Failed, found $($failedVerification.Status)."
    }

    $defaultReader = {
        param($Name)
        return (& $newRegistryState $true $false $null 'Mock value absent.')
    }.GetNewClosure()
    $defaultVerification = & $updatesModule {
        param($RegistryReader)
        Test-BoostLabUpdatesPauseState `
            -ActionName 'Default' `
            -RegistryReader $RegistryReader
    } $defaultReader
    if ($defaultVerification.Status -ne 'Passed' -or @($defaultVerification.Checks).Count -ne 6) {
        throw 'Updates Pause Default verification did not pass when all six values were absent.'
    }

    $applyEvents = [System.Collections.Generic.List[string]]::new()
    $applyValues = [ordered]@{}
    $dateQueue = [System.Collections.Generic.Queue[datetime]]::new()
    $dateQueue.Enqueue($pauseBase)
    $dateQueue.Enqueue($today)
    $dateProvider = { return $dateQueue.Dequeue() }.GetNewClosure()
    $registryWriter = {
        param($Name, $Value)
        $applyValues[$Name] = $Value
        $applyEvents.Add("WRITE:$Name=$Value")
    }.GetNewClosure()
    $applyReader = {
        param($Name)
        if ($applyValues.Contains($Name)) {
            return (& $newRegistryState $true $true $applyValues[$Name] 'Mock value detected.')
        }

        return (& $newRegistryState $true $false $null 'Mock value absent.')
    }.GetNewClosure()
    $applyLauncher = { $applyEvents.Add('LAUNCH:ms-settings:windowsupdate') }.GetNewClosure()
    $applyResult = & $updatesModule {
        param($DateProvider, $RegistryWriter, $RegistryReader, $SettingsLauncher)
        Invoke-BoostLabUpdatesPauseAction `
            -ActionName 'Apply' `
            -AdministratorChecker { return $true } `
            -DateProvider $DateProvider `
            -RegistryWriter $RegistryWriter `
            -RegistryReader $RegistryReader `
            -SettingsLauncher $SettingsLauncher
    } $dateProvider $registryWriter $applyReader $applyLauncher
    if (
        -not $applyResult.Success -or
        $applyResult.Message -ne 'Windows updates paused for 365 days.' -or
        $applyResult.Data.CommandStatus -ne 'Completed' -or
        $applyResult.VerificationResult.Status -ne 'Passed' -or
        $applyResult.Data.PauseStartTime -ne $expectedStart -or
        $applyResult.Data.PauseExpiryTime -ne $expectedExpiry
    ) {
        throw 'Mocked Updates Pause Apply did not return the expected structured result.'
    }
    $expectedEventOrder = @(
        "WRITE:PauseUpdatesExpiryTime=$expectedExpiry"
        "WRITE:PauseFeatureUpdatesEndTime=$expectedExpiry"
        "WRITE:PauseFeatureUpdatesStartTime=$expectedStart"
        "WRITE:PauseQualityUpdatesEndTime=$expectedExpiry"
        "WRITE:PauseQualityUpdatesStartTime=$expectedStart"
        "WRITE:PauseUpdatesStartTime=$expectedStart"
        'LAUNCH:ms-settings:windowsupdate'
    )
    if (($applyEvents -join '|') -ne ($expectedEventOrder -join '|')) {
        throw "Updates Pause Apply execution order changed: $($applyEvents -join '|')"
    }

    $defaultEvents = [System.Collections.Generic.List[string]]::new()
    $defaultValues = [ordered]@{}
    foreach ($entry in $expectedValues.GetEnumerator()) {
        $defaultValues[$entry.Key] = $entry.Value
    }
    $defaultActionReader = {
        param($Name)
        if ($defaultValues.Contains($Name)) {
            return (& $newRegistryState $true $true $defaultValues[$Name] 'Mock value detected.')
        }

        return (& $newRegistryState $true $false $null 'Mock value absent.')
    }.GetNewClosure()
    $registryRemover = {
        param($Name)
        $defaultValues.Remove($Name)
        $defaultEvents.Add("REMOVE:$Name")
    }.GetNewClosure()
    $defaultLauncher = { $defaultEvents.Add('LAUNCH:ms-settings:windowsupdate') }.GetNewClosure()
    $defaultResult = & $updatesModule {
        param($RegistryRemover, $RegistryReader, $SettingsLauncher)
        Invoke-BoostLabUpdatesPauseAction `
            -ActionName 'Default' `
            -AdministratorChecker { return $true } `
            -RegistryRemover $RegistryRemover `
            -RegistryReader $RegistryReader `
            -SettingsLauncher $SettingsLauncher
    } $registryRemover $defaultActionReader $defaultLauncher
    if (
        -not $defaultResult.Success -or
        $defaultResult.Message -ne 'Windows Update pause values restored to default.' -or
        $defaultResult.Data.CommandStatus -ne 'Completed' -or
        $defaultResult.VerificationResult.Status -ne 'Passed' -or
        $defaultValues.Count -ne 0
    ) {
        throw 'Mocked Updates Pause Default did not return the expected structured result.'
    }
    $expectedDefaultOrder = @(
        'REMOVE:PauseUpdatesExpiryTime'
        'REMOVE:PauseFeatureUpdatesEndTime'
        'REMOVE:PauseFeatureUpdatesStartTime'
        'REMOVE:PauseQualityUpdatesEndTime'
        'REMOVE:PauseQualityUpdatesStartTime'
        'REMOVE:PauseUpdatesStartTime'
        'LAUNCH:ms-settings:windowsupdate'
    )
    if (($defaultEvents -join '|') -ne ($expectedDefaultOrder -join '|')) {
        throw "Updates Pause Default execution order changed: $($defaultEvents -join '|')"
    }

    $alreadyDefaultEvents = [System.Collections.Generic.List[string]]::new()
    $unexpectedRemover = {
        param($Name)
        $alreadyDefaultEvents.Add("REMOVE:$Name")
    }.GetNewClosure()
    $alreadyDefaultLauncher = {
        $alreadyDefaultEvents.Add('LAUNCH:ms-settings:windowsupdate')
    }.GetNewClosure()
    $alreadyDefaultResult = & $updatesModule {
        param($RegistryRemover, $RegistryReader, $SettingsLauncher)
        Invoke-BoostLabUpdatesPauseAction `
            -ActionName 'Default' `
            -AdministratorChecker { return $true } `
            -RegistryRemover $RegistryRemover `
            -RegistryReader $RegistryReader `
            -SettingsLauncher $SettingsLauncher
    } $unexpectedRemover $defaultReader $alreadyDefaultLauncher
    if (
        -not $alreadyDefaultResult.Success -or
        $alreadyDefaultResult.Message -ne 'Windows Update pause values are already default.' -or
        $alreadyDefaultResult.Data.CommandStatus -ne 'Already default' -or
        @($alreadyDefaultEvents | Where-Object { $_ -like 'REMOVE:*' }).Count -ne 0 -or
        @($alreadyDefaultEvents | Where-Object { $_ -eq 'LAUNCH:ms-settings:windowsupdate' }).Count -ne 1
    ) {
        throw 'Updates Pause Default is not idempotent when all six values are absent.'
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
                throw "Updates Pause result is missing field: $field"
            }
        }
        foreach ($dataField in @(
            'CommandStatus'
            'ExpectedUpdatesPauseState'
            'DetectedUpdatesPauseState'
            'RegistryValuesChecked'
            'RegistryChangesAttempted'
            'SettingsPageStatus'
            'PauseStartTime'
            'PauseExpiryTime'
            'CompletedAt'
        )) {
            if ($null -eq $result.Data.PSObject.Properties[$dataField]) {
                throw "Updates Pause result data is missing field: $dataField"
            }
        }
    }
}
finally {
    Remove-Module -ModuleInfo $updatesModule -Force -ErrorAction SilentlyContinue
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
            $plan.ConfirmationMessage -notmatch 'Windows Update' -or
            $plan.ConfirmationMessage -notmatch 'No restart is required'
        ) {
            throw "Updates Pause $actionName Action Plan is incorrect."
        }
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredText in @(
    '''updates-pause'' = @{'
    '''Setup\UpdatesPause.psm1'''
    'Actions = @(''Apply'', ''Default'')'
    '$actionCommand.Parameters.ContainsKey(''Confirmed'')'
    'Test-BoostLabVerificationResult'
)) {
    if (-not $executionSource.Contains($requiredText)) {
        throw "Updates Pause runtime mapping is missing: $requiredText"
    }
}

$uiSource = Get-Content -Raw -LiteralPath $uiPath
foreach ($requiredText in @(
    '$toolId -eq ''updates-pause'''
    '-Label ''Command Status'''
    '-Label ''Verification Status'''
    '-Label ''Expected Updates Pause state'''
    '-Label ''Detected Updates Pause state'''
    '-Label ''Registry values checked'''
    '-Label ''Settings page'''
    '-Label ''Pause start'''
    '-Label ''Pause expiry'''
    '-Label ''Timestamp'''
)) {
    if (-not $uiSource.Contains($requiredText)) {
        throw "Updates Pause Latest Result rendering is missing: $requiredText"
    }
}

$record = Get-Content -Raw -LiteralPath $recordPath
foreach ($requiredText in @(
    'source-ultimate/3 Setup/8 Updates Pause.ps1'
    '4BBEF16C51FBEBAFAECB58307F8C619A37CD10BB3DC489BD4DF9A59DDBD1A0BD'
    'Approved by Yazan'
    'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
    'PauseUpdatesExpiryTime'
    'PauseFeatureUpdatesEndTime'
    'PauseFeatureUpdatesStartTime'
    'PauseQualityUpdatesEndTime'
    'PauseQualityUpdatesStartTime'
    'PauseUpdatesStartTime'
    'Start-Process ms-settings:windowsupdate'
    'Intentional Deviations'
    'Verification Strategy'
    'Automated tests must not modify the real registry, launch Settings, stop services, or execute tool actions through the production runtime.'
)) {
    if (-not $record.Contains($requiredText)) {
        throw "Updates Pause migration record is missing: $requiredText"
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
if ($implementedCount -ne 34 -or $placeholderCount -ne 18) {
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
    ToolId                  = 'updates-pause'
    ImplementedActions      = @('Apply', 'Default')
    ApplyExecuted           = $false
    DefaultExecuted         = $false
    MockedApplyPassed       = $true
    MockedDefaultPassed     = $true
    VerificationCheckCount  = 6
    ImplementedModuleCount  = $implementedCount
    PlaceholderModuleCount  = $placeholderCount
    SourceUltimateUnchanged = $true
    Message                 = 'Updates Pause Apply/Default and verification were validated with mocks only.'
    Timestamp               = Get-Date
}


