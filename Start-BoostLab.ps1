[CmdletBinding()]
param(
    [ValidateSet('True', 'False', 'Unknown')]
    [string]$AdminStatus = 'Unknown',

    [ValidateSet('True', 'False', 'Unknown')]
    [string]$InternetStatus = 'Unknown'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
    throw 'BoostLab requires Windows because the interface uses WPF.'
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

    Start-Process -FilePath $windowsPowerShell -ArgumentList $arguments
    return
}

$projectRoot = $PSScriptRoot
$modulePaths = @(
    'core\Environment.psm1'
    'core\Logging.psm1'
    'core\ActionPlan.psm1'
    'core\Verification.psm1'
    'core\Safety.psm1'
    'core\State.psm1'
    'core\Execution.psm1'
    'license\LicenseProvider.psm1'
)

foreach ($relativeModulePath in $modulePaths) {
    $modulePath = Join-Path $projectRoot $relativeModulePath
    if (Test-Path -LiteralPath $modulePath) {
        Import-Module -Name $modulePath -Force -ErrorAction Stop
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
