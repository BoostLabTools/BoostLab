[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$environmentModulePath = Join-Path $PSScriptRoot 'core\Environment.psm1'
$startScriptPath = Join-Path $PSScriptRoot 'Start-BoostLab.ps1'

if (-not (Test-Path -LiteralPath $environmentModulePath -PathType Leaf)) {
    throw "BoostLab environment module was not found: $environmentModulePath"
}

if (-not (Test-Path -LiteralPath $startScriptPath -PathType Leaf)) {
    throw "BoostLab start script was not found: $startScriptPath"
}

Import-Module -Name $environmentModulePath -Force -ErrorAction Stop

if (-not (Test-BoostLabAdministrator)) {
    $windowsPowerShell = (Get-Command powershell.exe -ErrorAction Stop).Source
    $arguments = @(
        '-NoProfile'
        '-ExecutionPolicy'
        'Bypass'
        '-File'
        "`"$PSCommandPath`""
    )

    try {
        Start-Process -FilePath $windowsPowerShell -ArgumentList $arguments -Verb RunAs -ErrorAction Stop
    }
    catch {
        throw "BoostLab requires Administrator rights. Elevation was not completed: $($_.Exception.Message)"
    }
    return
}

$hasInternet = Test-BoostLabInternet

& $startScriptPath `
    -AdminStatus 'True' `
    -InternetStatus $hasInternet.ToString()
