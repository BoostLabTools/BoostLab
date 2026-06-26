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
        throw 'Unable to determine the Ultimate tolerated outcome catalog test script path.'
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

$catalogPath = Join-Path $ProjectRoot 'core\SourceToleratedOutcomes.psm1'
Assert-BoostLabCondition (Test-Path -LiteralPath $catalogPath) 'Source-tolerated outcome helper is missing.'

Import-Module -Name $catalogPath -Force -ErrorAction Stop

$catalog = @(Get-BoostLabSourceToleratedOutcomeCatalog)
$requiredOutcomes = @(
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
    [pscustomobject]@{ ToolId = 'device-manager-power-savings-wake'; ReasonCode = 'SourceToleratedAccessDenied' }
)

Assert-BoostLabCondition ($catalog.Count -ge $requiredOutcomes.Count) 'Source-tolerated outcome catalog is missing required entries.'

foreach ($requiredOutcome in $requiredOutcomes) {
    $matchingEntry = @(
        $catalog |
            Where-Object {
                [string]$_.ToolId -eq [string]$requiredOutcome.ToolId -and
                [string]$_.ReasonCode -eq [string]$requiredOutcome.ReasonCode
            }
    )
    Assert-BoostLabCondition ($matchingEntry.Count -eq 1) "Missing or duplicate source-tolerated outcome: $($requiredOutcome.ToolId)/$($requiredOutcome.ReasonCode)."
    Assert-BoostLabCondition (Test-BoostLabSourceToleratedOutcome -ToolId $requiredOutcome.ToolId -ReasonCode $requiredOutcome.ReasonCode) "Source-tolerated outcome lookup failed: $($requiredOutcome.ToolId)/$($requiredOutcome.ReasonCode)."
}

foreach ($entry in $catalog) {
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$entry.ToolId)) 'Source-tolerated outcome entry has a blank ToolId.'
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$entry.ReasonCode)) "Source-tolerated outcome entry has a blank ReasonCode for $($entry.ToolId)."
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$entry.SourceTolerance)) "Source-tolerated outcome entry is missing source context: $($entry.ToolId)/$($entry.ReasonCode)."
    Assert-BoostLabCondition (@($entry.SourcePatterns).Count -gt 0) "Source-tolerated outcome entry is missing representative source patterns: $($entry.ToolId)/$($entry.ReasonCode)."
    Assert-BoostLabCondition ([string]$entry.DefaultSeverity -in @('Info', 'Warning')) "Source-tolerated outcome entry has an invalid default severity: $($entry.ToolId)/$($entry.ReasonCode)."
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$entry.AppliesWhen)) "Source-tolerated outcome entry is missing applicability rules: $($entry.ToolId)/$($entry.ReasonCode)."
    Assert-BoostLabCondition (-not [bool]$entry.BlanketSuppression) "Source-tolerated outcome entry must not be a blanket suppression: $($entry.ToolId)/$($entry.ReasonCode)."
    Assert-BoostLabCondition ([string]$entry.ToolId -ne '*') 'Source-tolerated outcome catalog must not use wildcard ToolId suppression.'
    Assert-BoostLabCondition ([string]$entry.ReasonCode -notin @('*', 'AllWarnings', 'AllErrors')) "Source-tolerated outcome catalog must not use broad ReasonCode suppression: $($entry.ToolId)/$($entry.ReasonCode)."
}

$allPatterns = @($catalog | ForEach-Object { @($_.SourcePatterns) })
foreach ($expectedPattern in @(
    '-ErrorAction SilentlyContinue'
    'Remove-Item'
    'Remove-AppxPackage'
    'DisplayName'
    'msiexec.exe'
    'SnippingTool.exe'
    'powercfg'
    'reg import'
    'reg unload'
    'reg load'
    'setting specified does not exist'
    'driver does not expose this property'
    'Requested registry access is not allowed'
)) {
    Assert-BoostLabCondition ($expectedPattern -in $allPatterns) "Source-tolerated outcome catalog is missing representative source pattern: $expectedPattern"
}

$note = New-BoostLabSourceToleratedOutcomeNote `
    -ToolId 'cleanup' `
    -ReasonCode 'VolatileLeftoverIgnored' `
    -Message 'Mock locked Temp item remained after cleanup.' `
    -Details ([pscustomobject]@{ TargetId = 'UserTempContents' })

Assert-BoostLabCondition ([string]$note.Severity -eq 'Info') 'Source-tolerated outcome note did not inherit Info severity.'
Assert-BoostLabCondition ([string]$note.ToolId -eq 'cleanup') 'Source-tolerated outcome note did not preserve ToolId.'
Assert-BoostLabCondition ([string]$note.ReasonCode -eq 'VolatileLeftoverIgnored') 'Source-tolerated outcome note did not preserve ReasonCode.'
Assert-BoostLabCondition ([string]$note.Message -like '*locked Temp item*') 'Source-tolerated outcome note did not preserve message.'

$unknownOutcomeThrew = $false
try {
    New-BoostLabSourceToleratedOutcomeNote -ToolId 'unknown-tool' -ReasonCode 'UnknownReason' -Message 'Should throw.'
}
catch {
    $unknownOutcomeThrew = $true
}
Assert-BoostLabCondition $unknownOutcomeThrew 'Unknown source-tolerated outcome note creation must fail closed.'

Write-Output ([pscustomobject]@{
    Test = 'UltimateToleratedOutcomeCatalog'
    Passed = $true
    CatalogEntryCount = $catalog.Count
    RequiredOutcomeCount = $requiredOutcomes.Count
})
