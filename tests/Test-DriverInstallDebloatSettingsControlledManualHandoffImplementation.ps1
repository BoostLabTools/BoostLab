[CmdletBinding()]
param(
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'BoostLab.Hashing.ps1')
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $scriptPath = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $PSCommandPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $MyInvocation.MyCommand.Path
    }
    else {
        throw 'Unable to determine the Driver Install Debloat & Settings compatibility validator path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$phase123Validator = Join-Path $ProjectRoot 'tests\Test-DriverInstallDebloatSettingsThreeBranchExactRuntimeImplementation.ps1'
if (-not (Test-Path -LiteralPath $phase123Validator -PathType Leaf)) {
    throw "Phase 123 Driver Install Debloat & Settings validator is missing: $phase123Validator"
}

$result = & $phase123Validator -ProjectRoot $ProjectRoot
if (-not [bool]$result) {
    throw 'Phase 123 Driver Install Debloat & Settings validator returned no result.'
}

[pscustomobject]@{
    Test = 'DriverInstallDebloatSettingsControlledManualHandoffCompatibility'
    SupersededManualHandoffOnly = $true
    CurrentMode = 'SourceEquivalentThreeBranchRuntime'
    ToolId = 'driver-install-debloat-settings'
    NextOrderedPendingParityTarget = $result.NextOrderedPendingParityTarget
    Message = 'Phase 99/122 manual-handoff assertions are superseded by Phase 123 three-branch controlled runtime validation.'
}
