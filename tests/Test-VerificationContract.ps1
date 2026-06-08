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
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$verificationModule = Import-Module `
    -Name $verificationPath `
    -Force `
    -PassThru `
    -Scope Local `
    -ErrorAction Stop
try {
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

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredText in @(
    'Verification.psm1'
    'Test-BoostLabVerificationResult'
    '-ExpectedToolId $toolId'
    '-ExpectedToolTitle $toolTitle'
    '-ExpectedAction $ActionName'
    'ToolAction.VerificationContractFailed'
)) {
    if (-not $executionSource.Contains($requiredText)) {
        throw "Execution runtime is missing verification behavior: $requiredText"
    }
}

$startSource = Get-Content -Raw -LiteralPath $startPath
if (-not $startSource.Contains('core\Verification.psm1')) {
    throw 'Start-BoostLab does not import the verification contract.'
}

$uiSource = Get-Content -Raw -LiteralPath $uiPath
foreach ($requiredText in @(
    '''Command Status'''
    '-Label ''Verification Status'''
    'Verification Checks'
    'Expected: {2}; Actual: {3}'
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
    @($sourceLines).Count -ne 50 -or
    $sourceManifestHash -ne '4F96170AFF67F9EE7A2E765A8DE268570651E22D2F3EE2C02923E0654D2C8EBF'
) {
    throw 'source-ultimate content or paths changed.'
}

[pscustomobject]@{
    Success                 = $true
    VerificationStatusCount = $statuses.Count
    ResultFieldCount        = $requiredResultFields.Count
    CheckFieldCount         = $requiredCheckFields.Count
    ToolActionsExecuted     = $false
    SourceUltimateUnchanged = $true
    Message                 = 'Verification contract and runtime/UI integration are valid.'
    Timestamp               = Get-Date
}
