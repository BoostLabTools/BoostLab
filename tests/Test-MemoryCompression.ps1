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
        throw 'Unable to determine the Memory Compression test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Setup\MemoryCompression.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\3 Setup\1 Memory Compression.ps1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$verificationPath = Join-Path $ProjectRoot 'core\Verification.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$recordPath = Join-Path $ProjectRoot 'docs\migrations\memory-compression.md'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration['Stages'] | ForEach-Object { $_['Tools'] })
$tool = $tools | Where-Object { $_['Id'] -eq 'memory-compression' } | Select-Object -First 1
if ($null -eq $tool) {
    throw 'Memory Compression metadata is missing.'
}
if (
    [string]$tool['Stage'] -ne 'Setup' -or
    [int]$tool['Order'] -ne 1 -or
    [string]$tool['RiskLevel'] -ne 'low' -or
    (@($tool['Actions']) -join ',') -ne 'Apply,Default'
) {
    throw 'Memory Compression stage, order, risk, or actions are incorrect.'
}

$capabilities = $tool['Capabilities']
$expectedTrueCapabilities = @(
    'RequiresAdmin'
    'SupportsDefault'
    'NeedsExplicitConfirmation'
)
foreach ($field in $capabilities.Keys) {
    $expected = $field -in $expectedTrueCapabilities
    if ([bool]$capabilities[$field] -ne $expected) {
        throw "Memory Compression capability '$field' is incorrect."
    }
}

if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne 'CCBABB01D249C1206F4762579665DCE6F95F12A8D221D9A65A6310A0393C2352') {
    throw 'Memory Compression Ultimate source hash changed.'
}

$source = Get-Content -Raw -LiteralPath $sourcePath
$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredText in @(
    'Disable-MMAgent -MemoryCompression -ErrorAction Stop'
    'Enable-MMAgent -MemoryCompression -ErrorAction Stop'
    'Get-MMAgent -ErrorAction Stop'
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    'function Test-BoostLabMemoryCompressionState'
    'New-BoostLabVerificationResult'
    '-VerificationResult $verificationResult'
    '[bool]$Confirmed = $false'
    'Memory compression disabled.'
    'Memory compression restored to default.'
    '$missingCommands = @('
    '$stateResults = @(& $StateReader)'
    '$mmaAgentResults = @(& $MMAgentReader)'
    '$resolvedCommands = @(& $CommandResolver $commandName)'
)) {
    if (-not $moduleSource.Contains($requiredText)) {
        throw "Memory Compression module is missing: $requiredText"
    }
}

foreach ($sourceText in @(
    'Disable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue'
    'Enable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue'
    'get-mmagent'
)) {
    if (-not $source.Contains($sourceText)) {
        throw "Memory Compression source no longer contains: $sourceText"
    }
}

foreach ($forbiddenText in @(
    'Restart-Computer'
    'Stop-Computer'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'Set-Service'
    'Stop-Service'
    'Set-MMAgent'
    '-PageCombining'
    '-ApplicationPreLaunch'
    'Start-Process'
)) {
    if ($moduleSource.Contains($forbiddenText)) {
        throw "Memory Compression module contains unrelated behavior: $forbiddenText"
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
    throw "Memory Compression module syntax error: $($parseErrors[0].Message)"
}
$commands = @(
    $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
        $true
    ) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }
)
if (@($commands | Where-Object { $_ -eq 'Disable-MMAgent' }).Count -ne 1) {
    throw 'Memory Compression must contain one Disable-MMAgent command.'
}
if (@($commands | Where-Object { $_ -eq 'Enable-MMAgent' }).Count -ne 1) {
    throw 'Memory Compression must contain one Enable-MMAgent command.'
}
if (@($commands | Where-Object { $_ -eq 'Get-MMAgent' }).Count -ne 1) {
    throw 'Memory Compression must contain one Get-MMAgent command.'
}

$memoryModule = Import-Module `
    -Name $modulePath `
    -Force `
    -PassThru `
    -Prefix 'MemoryTest' `
    -Scope Local `
    -DisableNameChecking `
    -ErrorAction Stop
try {
    $infoCommand = Get-Command `
        -Name 'Get-MemoryTestBoostLabToolInfo' `
        -Module $memoryModule.Name `
        -ErrorAction Stop
    $toolInfo = & $infoCommand
    if (
        [string]$toolInfo.Id -ne 'memory-compression' -or
        (@($toolInfo.Actions) -join ',') -ne 'Apply,Default' -or
        (@($toolInfo.ImplementedActions) -join ',') -ne 'Apply,Default'
    ) {
        throw 'Memory Compression exported metadata or implemented actions are incorrect.'
    }

    $scalarCommandResolver = {
        param($CommandName)
        return [pscustomobject]@{ Name = $CommandName }
    }
    $compatibility = & $memoryModule {
        param($CommandResolver)
        Test-BoostLabToolCompatibility `
            -CommandResolver $CommandResolver `
            -OperatingSystem 'Windows_NT'
    } $scalarCommandResolver
    if (-not $compatibility.Supported) {
        throw 'Memory Compression compatibility failed when every command resolver returned a scalar object.'
    }

    $oneMissingCommandResolver = {
        param($CommandName)
        if ($CommandName -ne 'Get-MMAgent') {
            return [pscustomobject]@{ Name = $CommandName }
        }
    }
    $unsupportedCompatibility = & $memoryModule {
        param($CommandResolver)
        Test-BoostLabToolCompatibility `
            -CommandResolver $CommandResolver `
            -OperatingSystem 'Windows_NT'
    } $oneMissingCommandResolver
    if (
        $unsupportedCompatibility.Supported -or
        $unsupportedCompatibility.Reason -notmatch 'Get-MMAgent'
    ) {
        throw 'Memory Compression compatibility did not normalize a scalar missing-command result.'
    }

    $normalScalarState = & $memoryModule {
        param($CommandResolver)
        Get-BoostLabMemoryCompressionState `
            -CommandResolver $CommandResolver `
            -MMAgentReader {
                [pscustomobject]@{ MemoryCompression = $false }
            }
    } $scalarCommandResolver
    if (
        -not $normalScalarState.ReadSucceeded -or
        [bool]$normalScalarState.MemoryCompression
    ) {
        throw 'A normal scalar Get-MMAgent result was not read correctly.'
    }

    $nullState = & $memoryModule {
        param($CommandResolver)
        Get-BoostLabMemoryCompressionState `
            -CommandResolver $CommandResolver `
            -MMAgentReader { return $null }
    } $scalarCommandResolver
    if (
        $nullState.ReadSucceeded -or
        $nullState.DisplayValue -ne 'Unknown'
    ) {
        throw 'A null Get-MMAgent result was not handled as unavailable.'
    }

    foreach ($case in @(
        [pscustomobject]@{ Action = 'Apply'; Detected = $false; ReadSucceeded = $true; ExpectedStatus = 'Passed' }
        [pscustomobject]@{ Action = 'Default'; Detected = $true; ReadSucceeded = $true; ExpectedStatus = 'Passed' }
        [pscustomobject]@{ Action = 'Apply'; Detected = $true; ReadSucceeded = $true; ExpectedStatus = 'Failed' }
        [pscustomobject]@{ Action = 'Default'; Detected = $false; ReadSucceeded = $true; ExpectedStatus = 'Failed' }
        [pscustomobject]@{ Action = 'Apply'; Detected = $null; ReadSucceeded = $false; ExpectedStatus = 'Warning' }
    )) {
        $stateReader = {
            return [pscustomobject]@{
                ReadSucceeded    = $case.ReadSucceeded
                MemoryCompression = $case.Detected
                DisplayValue     = if ($case.ReadSucceeded) { [string]$case.Detected } else { 'Unknown' }
                Message          = 'Mock Get-MMAgent result.'
            }
        }.GetNewClosure()
        $verification = & $memoryModule {
            param($ActionName, $StateReader)
            Test-BoostLabMemoryCompressionState `
                -ActionName $ActionName `
                -StateReader $StateReader
        } $case.Action $stateReader

        if ($verification.Status -ne $case.ExpectedStatus) {
            throw "Memory Compression $($case.Action) expected $($case.ExpectedStatus), found $($verification.Status)."
        }
        if (@($verification.Checks).Count -ne 1) {
            throw 'Memory Compression VerificationResult must contain one check.'
        }
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
            if ($null -eq $verification.PSObject.Properties[$field]) {
                throw "Memory Compression VerificationResult is missing field: $field"
            }
        }
    }

    $nullVerification = & $memoryModule {
        Test-BoostLabMemoryCompressionState `
            -ActionName 'Apply' `
            -StateReader { return $null }
    }
    if (
        $nullVerification.Status -ne 'Warning' -or
        @($nullVerification.Checks).Count -ne 1
    ) {
        throw 'A null verification state was not normalized safely.'
    }

    $mockedActionResults = [System.Collections.Generic.List[object]]::new()
    foreach ($actionCase in @(
        [pscustomobject]@{ Action = 'Apply'; ExpectedState = $false; ExpectedCall = 'Apply' }
        [pscustomobject]@{ Action = 'Default'; ExpectedState = $true; ExpectedCall = 'Default' }
    )) {
        $commandCalls = [System.Collections.Generic.List[string]]::new()
        $commandInvoker = {
            param($RequestedAction)
            $commandCalls.Add([string]$RequestedAction)
        }.GetNewClosure()
        $detectedState = [bool]$actionCase.ExpectedState
        $stateReader = {
            return [pscustomobject]@{
                ReadSucceeded     = $true
                MemoryCompression = $detectedState
                DisplayValue      = [string]$detectedState
                Message           = 'Mock Get-MMAgent result.'
            }
        }.GetNewClosure()

        $result = & $memoryModule {
            param($ActionName, $CommandResolver, $CommandInvoker, $StateReader)
            Invoke-BoostLabMemoryCompressionAction `
                -ActionName $ActionName `
                -AdministratorChecker { return $true } `
                -CommandResolver $CommandResolver `
                -CommandInvoker $CommandInvoker `
                -StateReader $StateReader
        } $actionCase.Action $scalarCommandResolver $commandInvoker $stateReader

        if (
            -not $result.Success -or
            $result.Action -ne $actionCase.Action -or
            $result.Data.CommandStatus -ne 'Completed' -or
            [bool]$result.Data.ExpectedMemoryCompression -ne [bool]$actionCase.ExpectedState -or
            [bool]$result.Data.DetectedMemoryCompression -ne [bool]$actionCase.ExpectedState -or
            $result.VerificationResult.Status -ne 'Passed' -or
            $commandCalls.Count -ne 1 -or
            $commandCalls[0] -ne $actionCase.ExpectedCall
        ) {
            throw "Mocked Memory Compression $($actionCase.Action) path did not return the expected structured result."
        }

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
                throw "Mocked Memory Compression $($actionCase.Action) result is missing field: $field"
            }
        }
        $mockedActionResults.Add($result)
    }
    if ($mockedActionResults.Count -ne 2) {
        throw 'Both mocked Memory Compression action paths were not validated.'
    }
}
finally {
    Remove-Module -ModuleInfo $memoryModule -Force -ErrorAction SilentlyContinue
}

$verificationModule = Import-Module `
    -Name $verificationPath `
    -Force `
    -PassThru `
    -Prefix 'ShapeTest' `
    -Scope Local `
    -DisableNameChecking `
    -ErrorAction Stop
try {
    $shapeCheck = [pscustomobject]@{
        Name     = 'MemoryCompression'
        Expected = $true
        Actual   = $true
        Status   = 'Passed'
        Message  = 'Mock check passed.'
    }
    $resultShapes = @(
        [pscustomobject]@{ Name = 'Scalar'; Checks = $shapeCheck }
        [pscustomobject]@{ Name = 'Null'; Checks = $null }
        [pscustomobject]@{ Name = 'Array'; Checks = @($shapeCheck) }
    )
    foreach ($shape in $resultShapes) {
        $shapeResult = [pscustomobject]@{
            ToolId        = 'memory-compression'
            ToolTitle     = 'Memory Compression'
            Action        = 'Default'
            Status        = 'Passed'
            ExpectedState = [pscustomobject]@{ MemoryCompression = $true }
            DetectedState = [pscustomobject]@{ MemoryCompression = $true }
            Checks        = $shape.Checks
            Message       = 'Mock verification result.'
            Timestamp     = Get-Date
        }
        $validationCommand = Get-Command `
            -Name 'Test-ShapeTestBoostLabVerificationResult' `
            -Module $verificationModule.Name `
            -ErrorAction Stop
        $shapeValidation = & $validationCommand `
            -VerificationResult $shapeResult `
            -ExpectedToolId 'memory-compression' `
            -ExpectedToolTitle 'Memory Compression' `
            -ExpectedAction 'Default'
        if (-not $shapeValidation.IsValid) {
            throw "Verification result shape '$($shape.Name)' was not normalized safely."
        }
    }
}
finally {
    Remove-Module -ModuleInfo $verificationModule -Force -ErrorAction SilentlyContinue
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    foreach ($actionName in @('Apply', 'Default')) {
        $plan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName $actionName -IsDryRun $false
        $expectedCommand = if ($actionName -eq 'Apply') {
            'Disable-MMAgent -MemoryCompression'
        }
        else {
            'Enable-MMAgent -MemoryCompression'
        }
        if (
            -not $plan.NeedsExplicitConfirmation -or
            $plan.CanReboot -or
            $plan.RequiresInternet -or
            $plan.ConfirmationMessage -notmatch [regex]::Escape($expectedCommand) -or
            $plan.ConfirmationMessage -notmatch 'No restart is required'
        ) {
            throw "Memory Compression $actionName action plan is incorrect."
        }
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredText in @(
    '''memory-compression'' = @{'
    '''Setup\MemoryCompression.psm1'''
    'Actions = @(''Apply'', ''Default'')'
    '$actionCommand.Parameters.ContainsKey(''Confirmed'')'
    'Test-BoostLabVerificationResult'
)) {
    if (-not $executionSource.Contains($requiredText)) {
        throw "Memory Compression runtime mapping is missing: $requiredText"
    }
}

$uiSource = Get-Content -Raw -LiteralPath $uiPath
foreach ($requiredText in @(
    '$toolId -eq ''memory-compression'''
    '-Label ''Command Status'''
    '-Label ''Verification Status'''
    '-Label ''Expected MemoryCompression state'''
    '-Label ''Detected MemoryCompression state'''
    '-Label ''Expected state'''
    '-Label ''Detected state'''
    '-Label ''Timestamp'''
)) {
    if (-not $uiSource.Contains($requiredText)) {
        throw "Memory Compression Latest Result rendering is missing: $requiredText"
    }
}

$record = Get-Content -Raw -LiteralPath $recordPath
foreach ($requiredText in @(
    'source-ultimate/3 Setup/1 Memory Compression.ps1'
    'CCBABB01D249C1206F4762579665DCE6F95F12A8D221D9A65A6310A0393C2352'
    'Approved by Yazan'
    'Disable-MMAgent -MemoryCompression'
    'Enable-MMAgent -MemoryCompression'
    'Get-MMAgent'
    'Verification Strategy'
    'Automated tests must not invoke the real Apply or Default command paths.'
)) {
    if (-not $record.Contains($requiredText)) {
        throw "Memory Compression migration record is missing: $requiredText"
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
if ($implementedCount -ne 19 -or $placeholderCount -ne 30) {
    throw "Unexpected module counts: $implementedCount implemented, $placeholderCount placeholders."
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
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
    @($sourceLines).Count -ne 50 -or
    $sourceManifestHash -ne '4F96170AFF67F9EE7A2E765A8DE268570651E22D2F3EE2C02923E0654D2C8EBF'
) {
    throw 'source-ultimate content or paths changed.'
}

[pscustomobject]@{
    Success                 = $true
    ToolId                  = 'memory-compression'
    ImplementedActions      = @('Apply', 'Default')
    ApplyExecuted           = $false
    DefaultExecuted         = $false
    MockedApplyPassed       = $true
    MockedDefaultPassed     = $true
    ResultShapesValidated   = 3
    ImplementedModuleCount  = $implementedCount
    PlaceholderModuleCount  = $placeholderCount
    SourceUltimateUnchanged = $true
    Message                 = 'Memory Compression Apply/Default behavior and mocked verification were validated without changing MMAgent state.'
    Timestamp               = Get-Date
}
