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
        throw 'Unable to determine the Widgets test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\Widgets.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\7 Widgets.ps1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$verificationPath = Join-Path $ProjectRoot 'core\Verification.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$recordPath = Join-Path $ProjectRoot 'docs\migrations\widgets.md'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration['Stages'] | ForEach-Object { $_['Tools'] })
$tool = $tools | Where-Object { $_['Id'] -eq 'widgets' } | Select-Object -First 1
if ($null -eq $tool) {
    throw 'Widgets metadata is missing.'
}
if (
    [string]$tool['Stage'] -ne 'Windows' -or
    [int]$tool['Order'] -ne 7 -or
    [string]$tool['RiskLevel'] -ne 'low' -or
    (@($tool['Actions']) -join ',') -ne 'Apply,Default'
) {
    throw 'Widgets stage, order, risk, or actions are incorrect.'
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
        throw "Widgets capability '$field' is incorrect."
    }
}

if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne '7A530557AA503EE038BDF910007D6A496DABFE61FA0D8818C189774E33892A73') {
    throw 'Widgets Ultimate source hash changed.'
}

$source = Get-Content -Raw -LiteralPath $sourcePath
$moduleSource = Get-Content -Raw -LiteralPath $modulePath
$applyPolicyManagerCommand = 'reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" /v "value" /t REG_DWORD /d "0" /f'
$applyDshCommand = 'reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d "0" /f'
$defaultPolicyManagerCommand = 'reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" /v "value" /t REG_DWORD /d "1" /f'
$defaultDshCommand = 'reg delete "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /f'

foreach ($requiredText in @(
    $applyPolicyManagerCommand
    $applyDshCommand
    $defaultPolicyManagerCommand
    $defaultDshCommand
    '$script:BoostLabWidgetProcessNames = @(''Widgets'', ''WidgetService'')'
    'Stop-Process -Force -Name $processName -ErrorAction Stop'
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    '[bool]$Confirmed = $false'
    'if (-not $Confirmed)'
    'Widgets disabled.'
    'Widgets restored to default.'
    'Widgets already default.'
    '$script:BoostLabPolicyManagerProviderPath = ''HKLM:\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests'''
    '$script:BoostLabDshPolicyProviderPath = ''HKLM:\SOFTWARE\Policies\Microsoft\Dsh'''
    'function Test-BoostLabWidgetsState'
    'function New-BoostLabWidgetsRegistryOperations'
    'function Test-BoostLabWidgetsAlreadyDefault'
    'Get-ItemProperty -LiteralPath $Path -ErrorAction Stop'
    '[System.Diagnostics.Process]::GetProcessesByName($Name)'
    '-VerificationResult $verificationResult'
)) {
    if (-not $moduleSource.Contains([string]$requiredText)) {
        throw "Widgets module is missing: $requiredText"
    }
}

foreach ($sourceText in @(
    'AllowNewsAndInterests`" /v `"value`" /t REG_DWORD /d `"0`" /f'
    'SOFTWARE\Policies\Microsoft\Dsh`" /v `"AllowNewsAndInterests`" /t REG_DWORD /d `"0`" /f'
    'Stop-Process -Force -Name Widgets -ErrorAction SilentlyContinue'
    'Stop-Process -Force -Name WidgetService -ErrorAction SilentlyContinue'
    'AllowNewsAndInterests`" /v `"value`" /t REG_DWORD /d `"1`" /f'
    'reg delete `"HKLM\SOFTWARE\Policies\Microsoft\Dsh`" /f'
)) {
    if (-not $source.Contains($sourceText)) {
        throw "Widgets source no longer contains: $sourceText"
    }
}

$applyPolicyManagerIndex = $moduleSource.IndexOf($applyPolicyManagerCommand)
$applyDshIndex = $moduleSource.IndexOf($applyDshCommand)
$defaultPolicyManagerIndex = $moduleSource.IndexOf($defaultPolicyManagerCommand)
$defaultDshIndex = $moduleSource.IndexOf($defaultDshCommand)
if (
    $applyPolicyManagerIndex -lt 0 -or
    $applyDshIndex -le $applyPolicyManagerIndex -or
    $defaultPolicyManagerIndex -le $applyDshIndex -or
    $defaultDshIndex -le $defaultPolicyManagerIndex
) {
    throw 'Widgets registry operation order no longer matches Ultimate.'
}

foreach ($forbiddenText in @(
    'Restart-Computer'
    'Stop-Computer'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'Set-Service'
    'Stop-Service'
    'Remove-Item'
    'Disable-ComputerRestore'
)) {
    if ($moduleSource.Contains($forbiddenText)) {
        throw "Widgets module contains forbidden behavior: $forbiddenText"
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
    throw "Widgets module syntax error: $($parseErrors[0].Message)"
}
$commands = @(
    $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
        $true
    ) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }
)
if (@($commands | Where-Object { $_ -eq 'Stop-Process' }).Count -ne 1) {
    throw 'Widgets must contain one allowlisted Stop-Process call.'
}
if ('Start-Process' -in $commands -or 'Restart-Computer' -in $commands) {
    throw 'Widgets must not launch or restart anything.'
}

$widgetsModule = Import-Module `
    -Name $modulePath `
    -Force `
    -PassThru `
    -Prefix 'WidgetsTest' `
    -Scope Local `
    -DisableNameChecking `
    -ErrorAction Stop
try {
    $infoCommand = Get-Command `
        -Name 'Get-WidgetsTestBoostLabToolInfo' `
        -Module $widgetsModule.Name `
        -ErrorAction Stop
    $toolInfo = & $infoCommand
    if (
        [string]$toolInfo.Id -ne 'widgets' -or
        (@($toolInfo.Actions) -join ',') -ne 'Apply,Default' -or
        (@($toolInfo.ImplementedActions) -join ',') -ne 'Apply,Default'
    ) {
        throw 'Widgets exported metadata or implemented actions are incorrect.'
    }

    $dshKeyAbsent = [pscustomobject]@{
        ReadSucceeded = $true
        KeyExists     = $false
        Exists        = $false
        Value         = $null
        DisplayValue  = 'Absent'
        Message       = 'Mock Dsh key is absent.'
    }
    $keyAbsentOperations = & $widgetsModule {
        param($DshPolicyState)
        New-BoostLabWidgetsRegistryOperations `
            -ActionName 'Default' `
            -DshPolicyState $DshPolicyState
    } $dshKeyAbsent
    if (
        @($keyAbsentOperations).Count -ne 2 -or
        [bool]$keyAbsentOperations[0].Skip -or
        -not [bool]$keyAbsentOperations[1].Skip -or
        $keyAbsentOperations[1].Command -ne $defaultDshCommand
    ) {
        throw 'Widgets Default does not treat an absent Dsh key as already default.'
    }

    $dshValueAbsent = [pscustomobject]@{
        ReadSucceeded = $true
        KeyExists     = $true
        Exists        = $false
        Value         = $null
        DisplayValue  = 'Absent'
        Message       = 'Mock Dsh value is absent.'
    }
    $valueAbsentOperations = & $widgetsModule {
        param($DshPolicyState)
        New-BoostLabWidgetsRegistryOperations `
            -ActionName 'Default' `
            -DshPolicyState $DshPolicyState
    } $dshValueAbsent
    if (-not [bool]$valueAbsentOperations[1].Skip) {
        throw 'Widgets Default does not treat a missing AllowNewsAndInterests value as already default.'
    }

    $policyManagerDefault = [pscustomobject]@{
        ReadSucceeded = $true
        KeyExists     = $true
        Exists        = $true
        Value         = 1
        DisplayValue  = '1'
        Message       = 'Mock PolicyManager value is default.'
    }
    $keyAbsentIsDefault = & $widgetsModule {
        param($PolicyManagerState, $DshPolicyState)
        Test-BoostLabWidgetsAlreadyDefault `
            -PolicyManagerState $PolicyManagerState `
            -DshPolicyState $DshPolicyState
    } $policyManagerDefault $dshKeyAbsent
    $valueAbsentIsDefault = & $widgetsModule {
        param($PolicyManagerState, $DshPolicyState)
        Test-BoostLabWidgetsAlreadyDefault `
            -PolicyManagerState $PolicyManagerState `
            -DshPolicyState $DshPolicyState
    } $policyManagerDefault $dshValueAbsent
    if (-not $keyAbsentIsDefault -or -not $valueAbsentIsDefault) {
        throw 'Widgets already-default state detection failed for an absent Dsh key or value.'
    }

    $dshUnreadable = [pscustomobject]@{
        ReadSucceeded = $false
        KeyExists     = $null
        Exists        = $false
        Value         = $null
        DisplayValue  = 'Unknown'
        Message       = 'Mock Dsh state is unreadable.'
    }
    $unreadableOperations = & $widgetsModule {
        param($DshPolicyState)
        New-BoostLabWidgetsRegistryOperations `
            -ActionName 'Default' `
            -DshPolicyState $DshPolicyState
    } $dshUnreadable
    if ([bool]$unreadableOperations[1].Skip) {
        throw 'Widgets Default must retain the original delete attempt when Dsh state is unreadable.'
    }

    $applyOperations = & $widgetsModule {
        New-BoostLabWidgetsRegistryOperations -ActionName 'Apply'
    }
    if (
        @($applyOperations).Count -ne 2 -or
        @($applyOperations | Where-Object { $_.Skip }).Count -ne 0 -or
        $applyOperations[0].Command -ne $applyPolicyManagerCommand -or
        $applyOperations[1].Command -ne $applyDshCommand
    ) {
        throw 'Widgets Apply registry behavior changed while adding Default idempotency.'
    }

    $applyPassedRegistryReader = {
        param($Path, $Name)
        return [pscustomobject]@{
            ReadSucceeded = $true
            Exists        = $true
            Value         = 0
            DisplayValue  = '0'
            Message       = 'Mock registry value detected.'
        }
    }
    $notRunningProcessReader = {
        param($Name)
        return [pscustomobject]@{
            ReadSucceeded = $true
            IsRunning     = $false
            DisplayValue  = 'Not running'
            Message       = "$Name is not running."
        }
    }
    $applyPassed = & $widgetsModule {
        param($RegistryReader, $ProcessReader)
        Test-BoostLabWidgetsState `
            -ActionName 'Apply' `
            -RegistryReader $RegistryReader `
            -ProcessReader $ProcessReader
    } $applyPassedRegistryReader $notRunningProcessReader
    if ($applyPassed.Status -ne 'Passed') {
        throw "Widgets Apply expected Passed, found $($applyPassed.Status)."
    }

    $uncertainProcessReader = {
        param($Name)
        return [pscustomobject]@{
            ReadSucceeded = $false
            IsRunning     = $null
            DisplayValue  = 'Unknown'
            Message       = "$Name state could not be read."
        }
    }
    $applyWarning = & $widgetsModule {
        param($RegistryReader, $ProcessReader)
        Test-BoostLabWidgetsState `
            -ActionName 'Apply' `
            -RegistryReader $RegistryReader `
            -ProcessReader $ProcessReader
    } $applyPassedRegistryReader $uncertainProcessReader
    if ($applyWarning.Status -ne 'Warning') {
        throw "Widgets Apply expected Warning, found $($applyWarning.Status)."
    }

    $applyFailedRegistryReader = {
        param($Path, $Name)
        $value = if ($Path -like '*PolicyManager*') { 1 } else { 0 }
        return [pscustomobject]@{
            ReadSucceeded = $true
            Exists        = $true
            Value         = $value
            DisplayValue  = [string]$value
            Message       = 'Mock registry value detected.'
        }
    }
    $applyFailed = & $widgetsModule {
        param($RegistryReader, $ProcessReader)
        Test-BoostLabWidgetsState `
            -ActionName 'Apply' `
            -RegistryReader $RegistryReader `
            -ProcessReader $ProcessReader
    } $applyFailedRegistryReader $notRunningProcessReader
    if ($applyFailed.Status -ne 'Failed') {
        throw "Widgets Apply expected Failed, found $($applyFailed.Status)."
    }

    $defaultPassedRegistryReader = {
        param($Path, $Name)
        if ($Path -like '*PolicyManager*') {
            return [pscustomobject]@{
                ReadSucceeded = $true
                Exists        = $true
                Value         = 1
                DisplayValue  = '1'
                Message       = 'Mock registry value detected.'
            }
        }

        return [pscustomobject]@{
            ReadSucceeded = $true
            Exists        = $false
            Value         = $null
            DisplayValue  = 'Absent'
            Message       = 'Mock registry value is absent.'
        }
    }
    $runningProcessReader = {
        param($Name)
        return [pscustomobject]@{
            ReadSucceeded = $true
            IsRunning     = $true
            DisplayValue  = 'Running'
            Message       = "$Name is running."
        }
    }
    $defaultPassed = & $widgetsModule {
        param($RegistryReader, $ProcessReader)
        Test-BoostLabWidgetsState `
            -ActionName 'Default' `
            -RegistryReader $RegistryReader `
            -ProcessReader $ProcessReader
    } $defaultPassedRegistryReader $runningProcessReader
    if (
        $defaultPassed.Status -ne 'Passed' -or
        @($defaultPassed.Checks | Where-Object { $_.Status -eq 'NotApplicable' }).Count -ne 2
    ) {
        throw 'Widgets Default process state is not informational-only.'
    }

    $defaultWarningRegistryReader = {
        param($Path, $Name)
        if ($Path -like '*PolicyManager*') {
            return [pscustomobject]@{
                ReadSucceeded = $true
                Exists        = $true
                Value         = 1
                DisplayValue  = '1'
                Message       = 'Mock registry value detected.'
            }
        }

        return [pscustomobject]@{
            ReadSucceeded = $false
            Exists        = $false
            Value         = $null
            DisplayValue  = 'Unknown'
            Message       = 'Mock Dsh state is unreadable.'
        }
    }
    $defaultWarning = & $widgetsModule {
        param($RegistryReader, $ProcessReader)
        Test-BoostLabWidgetsState `
            -ActionName 'Default' `
            -RegistryReader $RegistryReader `
            -ProcessReader $ProcessReader
    } $defaultWarningRegistryReader $runningProcessReader
    if ($defaultWarning.Status -ne 'Warning') {
        throw "Widgets Default expected Warning, found $($defaultWarning.Status)."
    }

    $defaultFailedRegistryReader = {
        param($Path, $Name)
        return [pscustomobject]@{
            ReadSucceeded = $true
            Exists        = $true
            Value         = 0
            DisplayValue  = '0'
            Message       = 'Mock blocking value detected.'
        }
    }
    $defaultFailed = & $widgetsModule {
        param($RegistryReader, $ProcessReader)
        Test-BoostLabWidgetsState `
            -ActionName 'Default' `
            -RegistryReader $RegistryReader `
            -ProcessReader $ProcessReader
    } $defaultFailedRegistryReader $runningProcessReader
    if ($defaultFailed.Status -ne 'Failed') {
        throw "Widgets Default expected Failed, found $($defaultFailed.Status)."
    }

    foreach ($verificationResult in @(
        $applyPassed
        $applyWarning
        $applyFailed
        $defaultPassed
        $defaultWarning
        $defaultFailed
    )) {
        foreach ($field in @(
            'ToolId'
            'ToolTitle'
            'Action'
            'Status'
            'ExpectedState'
            'DetectedState'
            'Checks'
            'Message'
            'Timestamp'
        )) {
            if ($null -eq $verificationResult.PSObject.Properties[$field]) {
                throw "Widgets VerificationResult is missing field: $field"
            }
        }
        if (@($verificationResult.Checks).Count -ne 4) {
            throw 'Widgets VerificationResult must contain four checks.'
        }
    }
}
finally {
    Remove-Module -ModuleInfo $widgetsModule -Force -ErrorAction SilentlyContinue
}

$processNamesMatch = [regex]::Matches(
    $moduleSource,
    '\$script:BoostLabWidgetProcessNames\s*=\s*@\(''(?<First>[^'']+)'',\s*''(?<Second>[^'']+)''\)'
)
if (
    $processNamesMatch.Count -ne 1 -or
    $processNamesMatch[0].Groups['First'].Value -ne 'Widgets' -or
    $processNamesMatch[0].Groups['Second'].Value -ne 'WidgetService'
) {
    throw 'Widgets process target allowlist changed.'
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    foreach ($actionName in @('Apply', 'Default')) {
        $plan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName $actionName -IsDryRun $false
        if (
            -not $plan.NeedsExplicitConfirmation -or
            $plan.CanReboot -or
            $plan.RequiresInternet -or
            $plan.ConfirmationMessage -notmatch 'No restart is required'
        ) {
            throw "Widgets $actionName action plan is not safely confirmation-gated."
        }
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredText in @(
    '''widgets'' = @{'
    '''Windows\Widgets.psm1'''
    'Actions = @(''Apply'', ''Default'')'
    '$actionCommand.Parameters.ContainsKey(''Confirmed'')'
    'ToolAction.Completed'
    'Test-BoostLabVerificationResult'
)) {
    if (-not $executionSource.Contains($requiredText)) {
        throw "Widgets runtime mapping is missing: $requiredText"
    }
}

$uiSource = Get-Content -Raw -LiteralPath $uiPath
foreach ($requiredText in @(
    '$toolId -eq ''widgets'''
    '-Label ''Registry changes attempted'''
    '-Label ''Processes stopped'''
    '-Label ''Timestamp'''
    '''Command Status'''
    '-Label ''Verification Status'''
    '-Label ''PolicyManager value'''
    '-Label ''Dsh policy state'''
    '-Label ''Widgets process state'''
    '-Label ''WidgetService process state'''
)) {
    if (-not $uiSource.Contains($requiredText)) {
        throw "Widgets Latest Result rendering is missing: $requiredText"
    }
}

$record = Get-Content -Raw -LiteralPath $recordPath
foreach ($requiredText in @(
    'source-ultimate/6 Windows/7 Widgets.ps1'
    '7A530557AA503EE038BDF910007D6A496DABFE61FA0D8818C189774E33892A73'
    'Approved by Yazan'
    'Verification Strategy'
    'Windows may delay the taskbar''s visual update'
    'Default is idempotent'
    'already absent'
    'Automated tests must not invoke the real Apply or Default command paths.'
)) {
    if (-not $record.Contains($requiredText)) {
        throw "Widgets migration record is missing: $requiredText"
    }
}

$deletedToolNames = @(
    'Windows Activation Helper'
    'Firewall'
    'DEP'
    'File Download Security Warning'
    'MPO'
    'FSO'
    'FSE'
    'Hardware Flip'
    'AMD ULPS'
    'WHQL Secure Boot Bypass'
    'Keyboard Shortcuts'
    'Search Shell Mobsync'
    'NVME Faster Driver'
    'Core 1 Thread 1'
    'DDU'
    'UAC'
    'Scaling'
    'Start Menu Shortcuts'
    'Loudness EQ'
)
$normalizedDeletedNames = @(
    $deletedToolNames | ForEach-Object {
        ($_ -replace '[^a-zA-Z0-9]+', '-').Trim('-').ToLowerInvariant()
    }
)
$deletedModules = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'modules') -Recurse -File -Filter '*.psm1' |
        Where-Object {
            [System.IO.Path]::GetFileNameWithoutExtension($_.Name).ToLowerInvariant() -in $normalizedDeletedNames
        }
)
if ($deletedModules.Count -gt 0) {
    throw "Deleted tool modules were found: $($deletedModules.FullName -join ', ')"
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
if ($implementedCount -ne 41 -or $placeholderCount -ne 14) {
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
    Success                 = $true
    ToolId                  = 'widgets'
    ImplementedActions      = @('Apply', 'Default')
    ApplyExecuted           = $false
    DefaultExecuted         = $false
    ImplementedModuleCount  = $implementedCount
    PlaceholderModuleCount  = $placeholderCount
    SourceUltimateUnchanged = $true
    Message                 = 'Widgets Apply/Default behavior was validated statically; no registry or process action was executed.'
    Timestamp               = Get-Date
}



