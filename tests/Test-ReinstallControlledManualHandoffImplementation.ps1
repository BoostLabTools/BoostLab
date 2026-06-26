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
        throw 'Unable to determine the Reinstall compatibility validator path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

& powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File (Join-Path $ProjectRoot 'tests\Test-ReinstallOrderedParityUpgrade.ps1') `
    -ProjectRoot $ProjectRoot

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

[pscustomobject]@{
    Test = 'ReinstallControlledManualHandoffCompatibility'
    DelegatedTo = 'Test-ReinstallOrderedParityUpgrade.ps1'
    Message = 'Phase 104 Reinstall manual-handoff validator now delegates to the Phase 110 ordered parity upgrade validator.'
}
