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
        throw 'Unable to determine the BIOS Information test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$environmentPath = Join-Path $ProjectRoot 'core\Environment.psm1'
$modulePath = Join-Path $ProjectRoot 'modules\Check\BIOSInformation.psm1'
$modulesRoot = Join-Path $ProjectRoot 'modules'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$biosTool = $configuration['Stages'] |
    ForEach-Object { $_['Tools'] } |
    Where-Object { $_['Id'] -eq 'bios-information' } |
    Select-Object -First 1
if ($null -eq $biosTool) {
    throw 'BIOS Information metadata was not found.'
}
if (@($biosTool['Actions']) -join ',' -ne 'Analyze,Open') {
    throw 'BIOS Information must expose Analyze and Open only.'
}

$environmentModule = Import-Module `
    -Name $environmentPath `
    -Force `
    -PassThru `
    -Scope Local `
    -ErrorAction Stop
$biosModule = Import-Module `
    -Name $modulePath `
    -Force `
    -PassThru `
    -Prefix 'BiosTool' `
    -Scope Local `
    -DisableNameChecking `
    -ErrorAction Stop

try {
    $toolInfo = Get-BiosToolBoostLabToolInfo
    $compatibility = Test-BiosToolBoostLabToolCompatibility
    $analysisResult = Invoke-BiosToolBoostLabToolAction -ActionName 'Analyze'
    $blockedResult = Invoke-BiosToolBoostLabToolAction -ActionName 'Apply'

    if (-not $compatibility.Supported) {
        throw 'BIOS Information compatibility must be supported.'
    }
    if (@($toolInfo.ImplementedActions) -join ',' -ne 'Analyze,Open') {
        throw 'BIOS Information implemented actions are incorrect.'
    }
    if (-not $analysisResult.Success -or $analysisResult.Message -ne 'Analysis complete') {
        throw 'BIOS Information Analyze did not return a successful structured result.'
    }
    if ($null -eq $analysisResult.Data) {
        throw 'BIOS Information Analyze did not return structured data.'
    }

    $requiredDataFields = @(
        'MotherboardManufacturer'
        'MotherboardModel'
        'BiosManufacturer'
        'BiosVersion'
        'BiosReleaseDate'
        'SystemManufacturer'
        'SystemModel'
        'SecureBootStatus'
        'TpmStatus'
        'CpuName'
        'WindowsVersion'
        'WindowsBuild'
        'Timestamp'
    )
    foreach ($field in $requiredDataFields) {
        if ($null -eq $analysisResult.Data.PSObject.Properties[$field]) {
            throw "BIOS Information analysis is missing field: $field"
        }
        if ($field -ne 'Timestamp' -and [string]::IsNullOrWhiteSpace([string]$analysisResult.Data.$field)) {
            throw "BIOS Information analysis returned a blank field: $field"
        }
    }
    if (
        $null -ne (Get-Command -Name 'Get-BoostLabWindowsVersion' -ErrorAction SilentlyContinue) -and
        $analysisResult.Data.WindowsVersion -eq 'Unknown'
    ) {
        throw 'BIOS Information did not use the available environment Windows version.'
    }

    if ($blockedResult.Success) {
        throw 'BIOS Information allowed an unsupported action.'
    }

    $allModules = @(
        Get-ChildItem `
            (Join-Path $modulesRoot 'Check'), `
            (Join-Path $modulesRoot 'Refresh'), `
            (Join-Path $modulesRoot 'Setup'), `
            (Join-Path $modulesRoot 'Installers'), `
            (Join-Path $modulesRoot 'Graphics'), `
            (Join-Path $modulesRoot 'Windows'), `
            (Join-Path $modulesRoot 'Advanced') `
            -File `
            -Filter '*.psm1'
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

    if ($implementedCount -ne 25 -or $placeholderCount -ne 23) {
        throw "Unexpected implementation counts: $implementedCount implemented, $placeholderCount placeholders."
    }

    $biosSource = Get-Content -Raw -LiteralPath $modulePath
    if ($biosSource.Contains('source-ultimate')) {
        throw 'BIOS Information references source-ultimate.'
    }

    [pscustomobject]@{
        Success             = $true
        ToolId              = $toolInfo.Id
        ImplementedActions  = @($toolInfo.ImplementedActions)
        AnalysisFieldCount  = $requiredDataFields.Count
        ImplementedModules  = $implementedCount
        PlaceholderModules  = $placeholderCount
        OpenActionExecuted  = $false
        Message             = 'BIOS Information Analyze returned structured data; Open was not executed.'
        Timestamp           = Get-Date
    }
}
finally {
    Remove-Module -ModuleInfo $biosModule -Force -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $environmentModule -Force -ErrorAction SilentlyContinue
}
