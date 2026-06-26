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
        throw 'Unable to determine the result severity policy test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

function Assert-BoostLabCondition {
    param(
        [Parameter(Mandatory)]
        [bool]$Condition,

        [Parameter(Mandatory)]
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

$severityPolicyPath = Join-Path $ProjectRoot 'core\ResultSeverityPolicy.psm1'
$sourceToleratedPath = Join-Path $ProjectRoot 'core\SourceToleratedOutcomes.psm1'
Assert-BoostLabCondition (Test-Path -LiteralPath $severityPolicyPath -PathType Leaf) 'Result severity policy helper is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $sourceToleratedPath -PathType Leaf) 'Source-tolerated outcome helper is missing.'

Import-Module -Name $severityPolicyPath -Force -ErrorAction Stop
Import-Module -Name $sourceToleratedPath -Force -ErrorAction Stop

$intentionalWarnings = @(Get-BoostLabIntentionalWarningCatalog)
$allowedCategories = @(
    'ManualConfirmationPending'
    'VerificationPartial'
    'UserAttentionRequired'
    'WorkflowIncomplete'
    'MeaningfulCompatibilityCaveat'
    'FailedVerification'
    'UnexpectedFailure'
)
Assert-BoostLabCondition ($intentionalWarnings.Count -gt 0) 'Intentional warning catalog must not be empty.'

foreach ($entry in $intentionalWarnings) {
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$entry.ToolId)) 'Intentional warning entry has a blank ToolId.'
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$entry.ReasonCode)) "Intentional warning entry has a blank ReasonCode for $($entry.ToolId)."
    Assert-BoostLabCondition ([string]$entry.Category -in $allowedCategories) "Intentional warning entry has an invalid category: $($entry.ToolId)/$($entry.ReasonCode)."
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$entry.AppliesWhen)) "Intentional warning entry is missing AppliesWhen: $($entry.ToolId)/$($entry.ReasonCode)."
    Assert-BoostLabCondition (-not [bool]$entry.BlanketSuppression) "Intentional warning entry must not be blanket suppression: $($entry.ToolId)/$($entry.ReasonCode)."
    Assert-BoostLabCondition ([string]$entry.ToolId -ne '*') 'Intentional warning catalog must not use wildcard ToolId suppression.'
    Assert-BoostLabCondition ([string]$entry.ReasonCode -notin @('*', 'AllWarnings', 'AllErrors')) "Intentional warning catalog must not use broad ReasonCode suppression: $($entry.ToolId)/$($entry.ReasonCode)."
}

$modulesRoot = Join-Path $ProjectRoot 'modules'
$warningPattern = "(?s)(Status\s*=\s*'Warning'|-Status\s+'Warning'|VerificationStatus\s+'Warning'|Completed with warnings|Status -eq 'Warning'|VerificationResult\.Status -eq 'Warning')"
$warningModules = @(
    Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1' |
        Where-Object {
            $source = Get-Content -Raw -LiteralPath $_.FullName
            $source -match $warningPattern
        } |
        ForEach-Object {
            $source = Get-Content -Raw -LiteralPath $_.FullName
            $toolId = if ($source -match "Id\s*=\s*'([^']+)'") { [string]$Matches[1] } else { [string]$_.BaseName }
            [pscustomobject]@{
                ToolId = $toolId
                Path = $_.FullName.Substring($ProjectRoot.Length + 1)
            }
        }
)

$classifiedWarningToolIds = @(
    $intentionalWarnings | ForEach-Object { [string]$_.ToolId }
    Get-BoostLabSourceToleratedOutcomeCatalog |
        Where-Object { [string]$_.DefaultSeverity -eq 'Warning' } |
        ForEach-Object { [string]$_.ToolId }
) | Select-Object -Unique

foreach ($warningModule in $warningModules) {
    Assert-BoostLabCondition (
        [string]$warningModule.ToolId -in $classifiedWarningToolIds
    ) "Warning-producing active module has no intentional warning policy entry: $($warningModule.ToolId) at $($warningModule.Path)."
}

$informationalExpectedOutcomes = @(
    [pscustomobject]@{ ToolId = 'store-settings'; ReasonCode = 'BestEffortVerified' }
    [pscustomobject]@{ ToolId = 'cleanup'; ReasonCode = 'VolatileLeftoverIgnored' }
    [pscustomobject]@{ ToolId = 'bloatware'; ReasonCode = 'SourceToleratedProtectedAppx' }
    [pscustomobject]@{ ToolId = 'bloatware'; ReasonCode = 'SourceToleratedDependencyFramework' }
    [pscustomobject]@{ ToolId = 'bloatware'; ReasonCode = 'SourceToleratedInUseFrameworkRuntime' }
    [pscustomobject]@{ ToolId = 'bloatware'; ReasonCode = 'SourceToleratedMissingTarget' }
    [pscustomobject]@{ ToolId = 'bloatware'; ReasonCode = 'ExpectedNoOp' }
    [pscustomobject]@{ ToolId = 'installers'; ReasonCode = 'ExpectedNoOp' }
    [pscustomobject]@{ ToolId = 'power-plan'; ReasonCode = 'HardwareSpecificUnsupportedSetting' }
    [pscustomobject]@{ ToolId = 'power-plan'; ReasonCode = 'ActiveSchemeDeleteAttemptExpected' }
    [pscustomobject]@{ ToolId = 'power-plan'; ReasonCode = 'ExistingTargetSchemeReuse' }
    [pscustomobject]@{ ToolId = 'network-adapter-power-savings-wake'; ReasonCode = 'HardwareSpecificUnsupportedSetting' }
    [pscustomobject]@{ ToolId = 'notepad-settings'; ReasonCode = 'NativeExitCodeMissingRecoveredByVerification' }
    [pscustomobject]@{ ToolId = 'notepad-settings'; ReasonCode = 'PreExistingHiveMountRecovered' }
    [pscustomobject]@{ ToolId = 'notepad-settings'; ReasonCode = 'HiveLoadAccessDeniedRecovered' }
)

foreach ($expectedOutcome in $informationalExpectedOutcomes) {
    $entry = @(Get-BoostLabSourceToleratedOutcomeCatalog -ToolId $expectedOutcome.ToolId -ReasonCode $expectedOutcome.ReasonCode | Select-Object -First 1)
    Assert-BoostLabCondition ($entry.Count -eq 1) "Expected informational source-tolerated outcome is missing: $($expectedOutcome.ToolId)/$($expectedOutcome.ReasonCode)."
    Assert-BoostLabCondition ([string]$entry[0].DefaultSeverity -eq 'Info') "Expected/no-op verified outcome must stay Info, not Warning: $($expectedOutcome.ToolId)/$($expectedOutcome.ReasonCode)."
}

$allowedWarning = Test-BoostLabResultSeverityPolicy `
    -ToolId 'driver-install-debloat-settings' `
    -Success $true `
    -Status 'Warning' `
    -VerificationStatus 'Warning' `
    -WarningReasonCodes @('RefreshConfirmationPending') `
    -HasUserFacingWarnings $true
Assert-BoostLabCondition ([bool]$allowedWarning.Allowed) "Known manual/pending warning should be allowed: $($allowedWarning.Reasons -join '; ')"

$unclassifiedWarning = Test-BoostLabResultSeverityPolicy `
    -ToolId 'store-settings' `
    -Success $true `
    -Status 'Warning' `
    -VerificationStatus 'Passed' `
    -HasUserFacingWarnings $true
Assert-BoostLabCondition (-not [bool]$unclassifiedWarning.Allowed) 'Unclassified warnings must be rejected by result severity policy.'

$failedVerificationSuccess = Test-BoostLabResultSeverityPolicy `
    -ToolId 'notepad-settings' `
    -Success $true `
    -Status 'Passed' `
    -VerificationStatus 'Failed'
Assert-BoostLabCondition (-not [bool]$failedVerificationSuccess.Allowed) 'Successful results with failed verification must be rejected.'

$passedWithUserWarning = Test-BoostLabResultSeverityPolicy `
    -ToolId 'cleanup' `
    -Success $true `
    -Status 'Passed' `
    -VerificationStatus 'Passed' `
    -HasUserFacingWarnings $true `
    -WarningReasonCodes @('VerificationUnavailable')
Assert-BoostLabCondition (-not [bool]$passedWithUserWarning.Allowed) 'Passed/Success results with user-facing warnings must be rejected; use informational diagnostics.'

Write-Output ([pscustomobject]@{
    Test = 'ResultSeverityPolicy'
    Passed = $true
    WarningProducingModuleCount = $warningModules.Count
    IntentionalWarningEntryCount = $intentionalWarnings.Count
    InformationalOutcomeCount = $informationalExpectedOutcomes.Count
})
