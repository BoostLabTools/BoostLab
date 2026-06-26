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
        throw 'Unable to determine the BIOS Information test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

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

$expectedWindowsDisplayName = 'BoostLab Test Windows 11 (Build 26100.1)'
$expectedWindowsBuild = '26100.1'
$script:BoostLabBiosInformationMockWindowsDisplayName = $expectedWindowsDisplayName
$script:BoostLabBiosInformationMockWindowsBuildText = $expectedWindowsBuild
function global:Get-BoostLabWindowsVersion {
    [pscustomobject]@{
        DisplayName = $script:BoostLabBiosInformationMockWindowsDisplayName
        BuildText   = $script:BoostLabBiosInformationMockWindowsBuildText
    }
}

try {
    $toolInfo = Get-BiosToolBoostLabToolInfo
    $compatibility = Test-BiosToolBoostLabToolCompatibility
    $analysisResult = Invoke-BiosToolBoostLabToolAction -ActionName 'Analyze'
    $blockedResult = Invoke-BiosToolBoostLabToolAction -ActionName 'Apply'
    $msiQuery = Get-BiosToolBoostLabBiosInformationSearchQuery -Analysis ([pscustomobject]@{
        MotherboardManufacturer = 'Micro-Star International Co., Ltd.'
        MotherboardModel        = 'MS-B9331'
        BiosManufacturer        = 'American Megatrends International, LLC.'
        BiosVersion             = '8.10'
    })
    $missingModelQuery = Get-BiosToolBoostLabBiosInformationSearchQuery -Analysis ([pscustomobject]@{
        MotherboardManufacturer = 'Micro-Star International Co., Ltd.'
        MotherboardModel        = 'Unknown'
        BiosVersion             = '8.10'
    })

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
    if ($analysisResult.Data.WindowsVersion -ne $expectedWindowsDisplayName) {
        throw "BIOS Information did not use the mocked environment Windows version. Actual: $($analysisResult.Data.WindowsVersion)"
    }
    if ($analysisResult.Data.WindowsBuild -ne $expectedWindowsBuild) {
        throw "BIOS Information did not use the mocked environment Windows build. Actual: $($analysisResult.Data.WindowsBuild)"
    }

    if ($blockedResult.Success) {
        throw 'BIOS Information allowed an unsupported action.'
    }
    if ($msiQuery -ne 'MS-B9331') {
        throw "BIOS Information Open query builder returned '$msiQuery' instead of 'MS-B9331'."
    }
    foreach ($forbiddenQueryText in @(
        'Micro-Star'
        'International'
        '8.10'
        'BIOS'
        'BIOS update'
    )) {
        if ($msiQuery.Contains($forbiddenQueryText)) {
            throw "BIOS Information Open query includes forbidden text: $forbiddenQueryText"
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($missingModelQuery)) {
        throw 'BIOS Information Open query builder must not broaden the query when motherboard model is unavailable.'
    }

    $inventorySnapshot = Get-BoostLabInventorySnapshot -ProjectRoot $ProjectRoot
    $implementedCount = [int]$inventorySnapshot.ImplementedTools
    $placeholderCount = [int]$inventorySnapshot.DeferredPlaceholders

    if ($implementedCount -ne $inventoryBaseline.ImplementedTools -or $placeholderCount -ne $inventoryBaseline.DeferredPlaceholders) {
        throw "Unexpected implementation counts: $implementedCount implemented, $placeholderCount placeholders."
    }

    $biosSource = Get-Content -Raw -LiteralPath $modulePath
    if ($biosSource.Contains('source-ultimate')) {
        throw 'BIOS Information references source-ultimate.'
    }
    foreach ($forbiddenSourceText in @(
        '$analysis.MotherboardManufacturer'
        '$analysis.BiosVersion'
        '''BIOS update'''
    )) {
        if ($biosSource.Contains($forbiddenSourceText)) {
            throw "BIOS Information Open query must not include widened query term: $forbiddenSourceText"
        }
    }
    if (-not $biosSource.Contains('MotherboardModelUnavailable')) {
        throw 'BIOS Information Open must fail closed when the motherboard model is unavailable.'
    }

    [pscustomobject]@{
        Success             = $true
        ToolId              = $toolInfo.Id
        ImplementedActions  = @($toolInfo.ImplementedActions)
        AnalysisFieldCount  = $requiredDataFields.Count
        ExampleOpenQuery    = $msiQuery
        ImplementedModules  = $implementedCount
        PlaceholderModules  = $placeholderCount
        OpenActionExecuted  = $false
        Message             = 'BIOS Information Analyze returned structured data; Open was not executed.'
        Timestamp           = Get-Date
    }
}
finally {
    Remove-Item -LiteralPath 'function:\global:Get-BoostLabWindowsVersion' -Force -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $biosModule -Force -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $environmentModule -Force -ErrorAction SilentlyContinue
}


