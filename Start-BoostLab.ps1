[CmdletBinding()]
param(
    [ValidateSet('True', 'False', 'Unknown')]
    [string]$AdminStatus = 'Unknown',

    [ValidateSet('True', 'False', 'Unknown')]
    [string]$InternetStatus = 'Unknown',

    [switch]$ElevationAttempted
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
    throw 'BoostLab requires Windows because the interface uses WPF.'
}

$environmentModulePath = Join-Path $PSScriptRoot 'core\Environment.psm1'
if (-not (Test-Path -LiteralPath $environmentModulePath -PathType Leaf)) {
    throw "BoostLab environment module was not found: $environmentModulePath"
}
Import-Module -Name $environmentModulePath -Force -ErrorAction Stop

if (-not (Test-BoostLabAdministrator)) {
    if ($ElevationAttempted) {
        throw 'BoostLab requires Administrator rights, but the elevated process is not running as Administrator.'
    }

    $windowsPowerShell = (Get-Command powershell.exe -ErrorAction Stop).Source
    $arguments = @(
        '-NoProfile'
        '-ExecutionPolicy'
        'Bypass'
        '-STA'
        '-File'
        "`"$PSCommandPath`""
        '-AdminStatus'
        'True'
        '-InternetStatus'
        $InternetStatus
        '-ElevationAttempted'
    )

    try {
        Start-Process `
            -FilePath $windowsPowerShell `
            -ArgumentList $arguments `
            -Verb RunAs `
            -ErrorAction Stop
    }
    catch {
        throw "BoostLab requires Administrator rights. Elevation was not completed: $($_.Exception.Message)"
    }
    return
}

if ([Threading.Thread]::CurrentThread.ApartmentState -ne [Threading.ApartmentState]::STA) {
    $windowsPowerShell = (Get-Command powershell.exe -ErrorAction Stop).Source
    $arguments = @(
        '-NoProfile'
        '-ExecutionPolicy'
        'Bypass'
        '-STA'
        '-File'
        "`"$PSCommandPath`""
        '-AdminStatus'
        $AdminStatus
        '-InternetStatus'
        $InternetStatus
    )
    if ($ElevationAttempted) {
        $arguments += '-ElevationAttempted'
    }

    Start-Process -FilePath $windowsPowerShell -ArgumentList $arguments
    return
}

$projectRoot = $PSScriptRoot
$verificationModulePath = Join-Path $projectRoot 'core\Verification.psm1'
if (-not (Test-Path -LiteralPath $verificationModulePath -PathType Leaf)) {
    throw "BoostLab verification module was not found: $verificationModulePath"
}
$verificationModule = Import-Module `
    -Name $verificationModulePath `
    -Scope Local `
    -Force `
    -PassThru `
    -ErrorAction Stop

$modulePaths = @(
    'core\Environment.psm1'
    'core\Logging.psm1'
    'core\ActionPlan.psm1'
    'core\Safety.psm1'
    'core\State.psm1'
    'core\TrustedInstaller.psm1'
    'core\Execution.psm1'
    'license\LicenseProvider.psm1'
)

foreach ($relativeModulePath in $modulePaths) {
    $modulePath = Join-Path $projectRoot $relativeModulePath
    if (Test-Path -LiteralPath $modulePath) {
        Import-Module -Name $modulePath -Force -ErrorAction Stop
    }
}

foreach ($verificationCommand in @(
    'New-BoostLabVerificationCheck'
    'New-BoostLabVerificationResult'
    'Get-BoostLabVerificationValidation'
)) {
    if (
        -not $verificationModule.ExportedCommands.ContainsKey($verificationCommand) -or
        -not (Get-Command `
            -Name $verificationCommand `
            -Module $verificationModule.Name `
            -ErrorAction SilentlyContinue)
    ) {
        throw "BoostLab verification runtime command was not imported: $verificationCommand"
    }
}

Initialize-BoostLabLogging | Out-Null

$stagesPath = Join-Path $projectRoot 'config\Stages.psd1'
$xamlPath = Join-Path $projectRoot 'ui\MainWindow.xaml'
$uiControllerPath = Join-Path $projectRoot 'ui\MainWindow.ps1'

foreach ($requiredPath in @($stagesPath, $xamlPath, $uiControllerPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required BoostLab file was not found: $requiredPath"
    }
}

$environmentInfo = Get-BoostLabEnvironmentInfo
if ($AdminStatus -ne 'Unknown') {
    $environmentInfo.IsAdministrator = [bool]::Parse($AdminStatus)
}
if ($InternetStatus -ne 'Unknown') {
    $environmentInfo.HasInternet = [bool]::Parse($InternetStatus)
}

$licenseStatus = Get-BoostLabLicenseStatus
$stageConfiguration = Import-PowerShellDataFile -LiteralPath $stagesPath

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

[xml]$xaml = Get-Content -Raw -LiteralPath $xamlPath
$xmlReader = [System.Xml.XmlNodeReader]::new($xaml)
try {
    $window = [Windows.Markup.XamlReader]::Load($xmlReader)
}
finally {
    $xmlReader.Close()
}

. $uiControllerPath

Initialize-BoostLabMainWindow `
    -Window $window `
    -StageConfiguration $stageConfiguration `
    -EnvironmentInfo $environmentInfo `
    -LicenseStatus $licenseStatus `
    -WindowsVersion $environmentInfo.Windows

$window.ShowDialog() | Out-Null
