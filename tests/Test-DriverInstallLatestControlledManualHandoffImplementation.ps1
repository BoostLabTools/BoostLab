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
        throw 'Unable to determine validator path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$phase124Validator = Join-Path $ProjectRoot 'tests\Test-DriverInstallLatestExactUltimateParityImplementation.ps1'
if (-not (Test-Path -LiteralPath $phase124Validator -PathType Leaf)) {
    throw "Phase 124 Driver Install Latest validator is missing: $phase124Validator"
}

& $phase124Validator -ProjectRoot $ProjectRoot | Out-Null

[pscustomobject]@{
    Test = 'DriverInstallLatestControlledManualHandoffImplementation'
    SupersededManualHandoffOnly = $true
    CurrentMode = 'SourceEquivalentThreeBranchRuntime'
    ToolId = 'driver-install-latest'
    Message = 'Phase 124 supersedes the old manual-handoff-only Driver Install Latest validator with exact Ultimate parity coverage.'
}
