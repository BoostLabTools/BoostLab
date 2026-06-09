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
        throw 'Unable to determine the verification contract test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$verificationPath = Join-Path $ProjectRoot 'core\Verification.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$startPath = Join-Path $ProjectRoot 'Start-BoostLab.ps1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$phase22ModulePath = Join-Path $ProjectRoot 'modules\Windows\SignoutLockScreenWallpaperBlack.psm1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$cleanSessionScript = @"
`$ErrorActionPreference = 'Stop'
`$verificationModule = Import-Module -Name '$($verificationPath.Replace("'", "''"))' -Scope Local -Force -PassThru -ErrorAction Stop
foreach (`$modulePath in @(
    '$((Join-Path $ProjectRoot 'core\Environment.psm1').Replace("'", "''"))'
    '$((Join-Path $ProjectRoot 'core\Logging.psm1').Replace("'", "''"))'
    '$((Join-Path $ProjectRoot 'core\ActionPlan.psm1').Replace("'", "''"))'
    '$((Join-Path $ProjectRoot 'core\Safety.psm1').Replace("'", "''"))'
    '$((Join-Path $ProjectRoot 'core\State.psm1').Replace("'", "''"))'
    '$((Join-Path $ProjectRoot 'core\TrustedInstaller.psm1').Replace("'", "''"))'
    '$($executionPath.Replace("'", "''"))'
    '$((Join-Path $ProjectRoot 'license\LicenseProvider.psm1').Replace("'", "''"))'
)) {
    Import-Module -Name `$modulePath -Force -ErrorAction Stop
}
foreach (`$commandName in @(
    'New-BoostLabVerificationCheck'
    'New-BoostLabVerificationResult'
    'Test-BoostLabVerificationResult'
)) {
    if (
        -not `$verificationModule.ExportedCommands.ContainsKey(`$commandName) -or
        -not (Get-Command -Name `$commandName -Module `$verificationModule.Name -ErrorAction SilentlyContinue)
    ) {
        throw "Clean session could not import verification command: `$commandName"
    }
}
'Verification startup import sequence passed.'
"@
$encodedCleanSessionScript = [Convert]::ToBase64String(
    [Text.Encoding]::Unicode.GetBytes($cleanSessionScript)
)
$cleanSessionOutput = & powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -EncodedCommand $encodedCleanSessionScript 2>&1
if (
    $LASTEXITCODE -ne 0 -or
    -not ((@($cleanSessionOutput) -join [Environment]::NewLine).Contains(
        'Verification startup import sequence passed.'
    ))
) {
    throw "Verification helpers were not importable in a clean PowerShell session: $($cleanSessionOutput -join ' ')"
}

$verificationModule = Import-Module `
    -Name $verificationPath `
    -Force `
    -PassThru `
    -Scope Local `
    -ErrorAction Stop
try {
    foreach ($requiredCommand in @(
        'New-BoostLabVerificationCheck'
        'New-BoostLabVerificationResult'
        'Test-BoostLabVerificationResult'
    )) {
        if (-not $verificationModule.ExportedCommands.ContainsKey($requiredCommand)) {
            throw "Verification module does not export: $requiredCommand"
        }
        if (-not (Get-Command -Name $requiredCommand -Module $verificationModule.Name -ErrorAction SilentlyContinue)) {
            throw "Verification command is not importable: $requiredCommand"
        }
    }

    $requiredResultFields = @(
        'ToolId'
        'ToolTitle'
        'Action'
        'Status'
        'ExpectedState'
        'DetectedState'
        'Checks'
        'Message'
        'Timestamp'
    )
    $requiredCheckFields = @('Name', 'Expected', 'Actual', 'Status', 'Message')
    $statuses = @('Passed', 'Warning', 'Failed', 'NotApplicable', 'NotImplemented')

    foreach ($status in $statuses) {
        $check = New-BoostLabVerificationCheck `
            -Name 'Contract check' `
            -Expected 'Expected' `
            -Actual 'Actual' `
            -Status $status `
            -Message 'Contract test.'
        foreach ($field in $requiredCheckFields) {
            if ($null -eq $check.PSObject.Properties[$field]) {
                throw "Verification check is missing field: $field"
            }
        }

        $result = New-BoostLabVerificationResult `
            -ToolId 'contract-test' `
            -ToolTitle 'Contract Test' `
            -Action 'Apply' `
            -Status $status `
            -ExpectedState ([pscustomobject]@{ Value = 'Expected' }) `
            -DetectedState ([pscustomobject]@{ Value = 'Actual' }) `
            -Checks @($check) `
            -Message 'Verification contract test.'
        foreach ($field in $requiredResultFields) {
            if ($null -eq $result.PSObject.Properties[$field]) {
                throw "VerificationResult is missing field: $field"
            }
        }

        $validation = Test-BoostLabVerificationResult `
            -VerificationResult $result `
            -ExpectedToolId 'contract-test' `
            -ExpectedToolTitle 'Contract Test' `
            -ExpectedAction 'Apply'
        if (-not $validation.IsValid) {
            throw "Valid verification result failed validation: $($validation.Errors -join '; ')"
        }
    }

    $mismatchResult = New-BoostLabVerificationResult `
        -ToolId 'wrong-tool' `
        -ToolTitle 'Contract Test' `
        -Action 'Default' `
        -Status 'Passed' `
        -ExpectedState 'Expected' `
        -DetectedState 'Detected' `
        -Checks @() `
        -Message 'Mismatch test.'
    $mismatchValidation = Test-BoostLabVerificationResult `
        -VerificationResult $mismatchResult `
        -ExpectedToolId 'contract-test' `
        -ExpectedToolTitle 'Contract Test' `
        -ExpectedAction 'Apply'
    if ($mismatchValidation.IsValid -or $mismatchValidation.Errors.Count -lt 2) {
        throw 'Verification identity mismatch was not rejected.'
    }
}
finally {
    Remove-Module -ModuleInfo $verificationModule -Force -ErrorAction SilentlyContinue
}

$executionModule = Import-Module `
    -Name $executionPath `
    -Force `
    -PassThru `
    -Scope Local `
    -ErrorAction Stop
$phase22Module = $null
try {
    foreach ($requiredCommand in @(
        'New-BoostLabVerificationCheck'
        'New-BoostLabVerificationResult'
        'Test-BoostLabVerificationResult'
    )) {
        $executionCommandAvailable = & $executionModule {
            param($CommandName)
            [bool](Get-Command -Name $CommandName -ErrorAction SilentlyContinue)
        } $requiredCommand
        if (-not $executionCommandAvailable) {
            throw "Execution module does not own a callable verification command: $requiredCommand"
        }
    }

    $phase22Module = Import-Module `
        -Name $phase22ModulePath `
        -Force `
        -PassThru `
        -Prefix 'VerificationScopeTest' `
        -Scope Local `
        -DisableNameChecking `
        -ErrorAction Stop
    Remove-Module -ModuleInfo $phase22Module -Force -ErrorAction Stop
    $phase22Module = $null

    $validatorStillAvailable = & $executionModule {
        [bool](Get-Command -Name 'Test-BoostLabVerificationResult' -ErrorAction SilentlyContinue)
    }
    if (-not $validatorStillAvailable) {
        throw 'Execution lost its private verification validator after the Phase 22 module was unloaded.'
    }
}
finally {
    if ($null -ne $phase22Module) {
        Remove-Module -ModuleInfo $phase22Module -Force -ErrorAction SilentlyContinue
    }
    Remove-Module -ModuleInfo $executionModule -Force -ErrorAction SilentlyContinue
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredText in @(
    'Verification.psm1'
    '-Scope Local'
    'Test-BoostLabVerificationResult'
    'ToolAction.VerificationRuntimeFailed'
    'Verification contract validation failed'
    '-ExpectedToolId $toolId'
    '-ExpectedToolTitle $toolTitle'
    '-ExpectedAction $ActionName'
    'ToolAction.VerificationContractFailed'
)) {
    if (-not $executionSource.Contains($requiredText)) {
        throw "Execution runtime is missing verification behavior: $requiredText"
    }
}
$executionVerificationImportIndex = $executionSource.IndexOf(
    "-Name (Join-Path `$PSScriptRoot 'Verification.psm1')"
)
$executionVerificationImportBlock = if ($executionVerificationImportIndex -ge 0) {
    $executionSource.Substring(
        $executionVerificationImportIndex,
        [Math]::Min(220, $executionSource.Length - $executionVerificationImportIndex)
    )
}
else {
    ''
}
if ($executionVerificationImportBlock.Contains('-Force')) {
    throw 'Execution force-reloads Verification.psm1 and can remove startup-visible exports.'
}

$startSource = Get-Content -Raw -LiteralPath $startPath
foreach ($requiredText in @(
    'core\Verification.psm1'
    '$verificationModulePath = Join-Path $projectRoot ''core\Verification.psm1'''
    '$verificationModule = Import-Module'
    '-PassThru'
    '$verificationModule.ExportedCommands.ContainsKey($verificationCommand)'
    '-Module $verificationModule.Name'
    '''New-BoostLabVerificationCheck'''
    '''New-BoostLabVerificationResult'''
    '''Test-BoostLabVerificationResult'''
    'BoostLab verification runtime command was not imported'
)) {
    if (-not $startSource.Contains($requiredText)) {
        throw "Start-BoostLab verification import guard is missing: $requiredText"
    }
}
$verificationImportIndex = $startSource.IndexOf('$verificationModule = Import-Module')
$verificationGuardIndex = $startSource.IndexOf('$verificationModule.ExportedCommands.ContainsKey($verificationCommand)')
$executionImportIndex = $startSource.IndexOf('''core\Execution.psm1''')
if (
    $verificationImportIndex -lt 0 -or
    $verificationGuardIndex -lt 0 -or
    $executionImportIndex -lt 0 -or
    $verificationImportIndex -gt $executionImportIndex -or
    $verificationImportIndex -gt $verificationGuardIndex
) {
    throw 'Start-BoostLab does not import Verification.psm1 before Execution.psm1 and the startup guard.'
}

$uiSource = Get-Content -Raw -LiteralPath $uiPath
foreach ($requiredText in @(
    '''Command Status'''
    '-Label ''Verification Status'''
    'Verification Checks'
    'Expected: {2}; Actual: {3}'
    'function New-BoostLabUiActionFailureResult'
    'function Invoke-BoostLabToolCardAction'
    'Tool execution failed:'
    'ToolAction.UiRuntimeFailed'
    'Tool result presentation failed:'
)) {
    if (-not $uiSource.Contains($requiredText)) {
        throw "UI is missing verification rendering: $requiredText"
    }
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
    @($sourceLines).Count -ne 49 -or
    $sourceManifestHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477'
) {
    throw 'source-ultimate content or paths changed.'
}

[pscustomobject]@{
    Success                 = $true
    VerificationStatusCount = $statuses.Count
    ResultFieldCount        = $requiredResultFields.Count
    CheckFieldCount         = $requiredCheckFields.Count
    ExportedHelperCount     = 3
    CleanSessionImport      = $true
    StartupImportSmokeTest  = $true
    StartupImportOrder      = $true
    ExecutionPrivateImport  = $true
    UiFailureBoundary       = $true
    ToolActionsExecuted     = $false
    SourceUltimateUnchanged = $true
    Message                 = 'Verification contract and runtime/UI integration are valid.'
    Timestamp               = Get-Date
}
