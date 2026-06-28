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
        throw 'Unable to determine the AXIS first-use wizard preview harness test script path.'
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

function Get-BoostLabGitExecutable {
    $gitCommand = Get-Command -Name 'git' -ErrorAction SilentlyContinue
    if ($null -ne $gitCommand) {
        return [string]$gitCommand.Source
    }

    $githubDesktopRoot = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'GitHubDesktop'
    if (Test-Path -LiteralPath $githubDesktopRoot -PathType Container) {
        $githubDesktopGit = @(
            Get-ChildItem -LiteralPath $githubDesktopRoot -Directory -Filter 'app-*' -ErrorAction SilentlyContinue |
                Sort-Object -Property Name -Descending |
                ForEach-Object { Join-Path $_.FullName 'resources\app\git\cmd\git.exe' } |
                Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }
        ) | Select-Object -First 1

        if (-not [string]::IsNullOrWhiteSpace($githubDesktopGit)) {
            return [string]$githubDesktopGit
        }
    }

    return ''
}

$launcherPath = Join-Path $ProjectRoot 'tools\dev\Start-AxisFirstUseWizardPreview.ps1'
$resourcePath = Join-Path $ProjectRoot 'ui\AxisResources.ps1'
$prototypePath = Join-Path $ProjectRoot 'ui\AxisFirstUseWizardPrototype.ps1'
$mainWindowPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'

Assert-BoostLabCondition (Test-Path -LiteralPath $launcherPath -PathType Leaf) 'AXIS first-use wizard preview launcher is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $resourcePath -PathType Leaf) 'AXIS WPF resource file is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $prototypePath -PathType Leaf) 'AXIS first-use wizard prototype file is missing.'

$launcherSource = Get-Content -Raw -LiteralPath $launcherPath
Assert-BoostLabCondition ($launcherSource.Contains('AxisResources.ps1')) 'AXIS first-use wizard preview launcher must import/use AxisResources.ps1.'
Assert-BoostLabCondition ($launcherSource.Contains('AxisFirstUseWizardPrototype.ps1')) 'AXIS first-use wizard preview launcher must import/use AxisFirstUseWizardPrototype.ps1.'
Assert-BoostLabCondition ($launcherSource.Contains('BuildOnly')) 'AXIS first-use wizard preview launcher must expose BuildOnly mode.'
Assert-BoostLabCondition ($launcherSource.Contains('NoShow')) 'AXIS first-use wizard preview launcher must expose NoShow mode.'
Assert-BoostLabCondition ($launcherSource.Contains('ValidateOnly')) 'AXIS first-use wizard preview launcher should provide a ValidateOnly alias.'

. $launcherPath -BuildOnly -ProjectRoot $ProjectRoot

Assert-BoostLabCondition (
    $null -ne (Get-Command -Name 'Invoke-AxisFirstUseWizardPreview' -CommandType Function -ErrorAction SilentlyContinue)
) 'AXIS first-use wizard preview launcher did not import safely or define Invoke-AxisFirstUseWizardPreview.'

$buildOnlyResult = Invoke-AxisFirstUseWizardPreview -BuildOnly -ProjectRoot $ProjectRoot
Assert-BoostLabCondition ($buildOnlyResult.Preview -eq 'AxisFirstUseWizard') 'AXIS first-use wizard preview harness returned an unexpected preview name.'
Assert-BoostLabCondition ($buildOnlyResult.Mode -eq 'BuildOnly') 'AXIS first-use wizard preview harness did not report BuildOnly mode.'
Assert-BoostLabCondition ([bool]$buildOnlyResult.WindowCreated) 'AXIS first-use wizard preview harness did not create the prototype window in BuildOnly mode.'
Assert-BoostLabCondition (-not [bool]$buildOnlyResult.WindowShown) 'AXIS first-use wizard preview harness must not show the window in BuildOnly mode.'
Assert-BoostLabCondition ([double]$buildOnlyResult.WindowWidth -eq 900.0) 'AXIS first-use wizard preview window width should be 900.'
Assert-BoostLabCondition ([double]$buildOnlyResult.WindowHeight -eq 650.0) 'AXIS first-use wizard preview window height should be 650.'
Assert-BoostLabCondition ([string]$buildOnlyResult.WindowStyle -eq 'SingleBorderWindow') 'AXIS first-use wizard preview harness should restore normal Windows window chrome.'
Assert-BoostLabCondition ([string]$buildOnlyResult.ResizeMode -eq 'NoResize') 'AXIS first-use wizard preview harness should keep the fixed prototype size.'
Assert-BoostLabCondition (-not [bool]$buildOnlyResult.CustomChrome) 'AXIS first-use wizard preview harness should report that custom chrome is disabled.'
Assert-BoostLabCondition ([bool]$buildOnlyResult.DefaultTitlebarVisible) 'AXIS first-use wizard preview should keep the normal titlebar visible.'
Assert-BoostLabCondition ([bool]$buildOnlyResult.UsesAxisResources) 'AXIS first-use wizard preview harness did not create a preview using AXIS resources.'
Assert-BoostLabCondition (-not [bool]$buildOnlyResult.RuntimeActionsStarted) 'AXIS first-use wizard preview harness must not start runtime actions.'
Assert-BoostLabCondition (-not [bool]$buildOnlyResult.HostMutated) 'AXIS first-use wizard preview harness must not mutate host state.'

$noShowResult = Invoke-AxisFirstUseWizardPreview -NoShow -ProjectRoot $ProjectRoot
Assert-BoostLabCondition ($noShowResult.Mode -eq 'NoShow') 'AXIS first-use wizard preview harness did not report NoShow mode.'
Assert-BoostLabCondition (-not [bool]$noShowResult.WindowShown) 'AXIS first-use wizard preview harness must not show the window in NoShow mode.'
Assert-BoostLabCondition ([bool]$noShowResult.WindowCreated) 'AXIS first-use wizard preview harness did not create the prototype window in NoShow mode.'

$validateOnlyResult = Invoke-AxisFirstUseWizardPreview -ValidateOnly -ProjectRoot $ProjectRoot
Assert-BoostLabCondition ($validateOnlyResult.Mode -eq 'NoShow') 'AXIS first-use wizard preview harness ValidateOnly alias should use NoShow mode.'
Assert-BoostLabCondition (-not [bool]$validateOnlyResult.WindowShown) 'AXIS first-use wizard preview harness must not show the window in ValidateOnly mode.'

$externalOutput = & powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File $launcherPath -BuildOnly -ProjectRoot $ProjectRoot 2>&1
Assert-BoostLabCondition ($LASTEXITCODE -eq 0) 'AXIS first-use wizard preview launcher failed when run as a script in BuildOnly mode.'
Assert-BoostLabCondition (
    (($externalOutput | Out-String).Contains('AxisFirstUseWizard'))
) 'AXIS first-use wizard preview launcher script output did not include the expected preview identity.'

foreach ($blockedRuntimeText in @(
    'Invoke-BoostLabToolAction'
    'New-BoostLabActionPlan'
    'Start-Process'
    'Set-ItemProperty'
    'New-ItemProperty'
    'Remove-ItemProperty'
    'Restart-Computer'
    'Stop-Computer'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'manage-bde'
    'pnputil'
    'bcdedit'
    'powercfg'
    'winget'
    'schtasks'
    'Clear-RecycleBin'
    'Remove-AppxPackage'
    'Add-AppxPackage'
    'Set-MpPreference'
)) {
    Assert-BoostLabCondition (-not $launcherSource.Contains($blockedRuntimeText)) "AXIS first-use wizard preview harness must not contain runtime/system mutation text: $blockedRuntimeText"
}

foreach ($blockedActionCall in @(
    'Invoke-BoostLabToolAction'
    'Invoke-BoostLabToolDefault'
    'Invoke-BoostLabToolRestore'
)) {
    Assert-BoostLabCondition (-not $launcherSource.Contains($blockedActionCall)) "AXIS first-use wizard preview harness must not call runtime action: $blockedActionCall"
}

foreach ($blockedPathText in @(
    'source-ultimate'
    'source-extra'
    'intake'
)) {
    Assert-BoostLabCondition (-not $launcherSource.Contains($blockedPathText)) "AXIS first-use wizard preview harness must not require protected source/intake path: $blockedPathText"
}

foreach ($forbiddenCustomerText in @(
    'Ultimate'
    'source-defined'
    'source-equivalent'
    'TypeUI'
    'Untitled Project'
    'Bento Pro'
    'Codex'
    'ChatGPT'
    'OpenAI'
    'Yazan'
)) {
    Assert-BoostLabCondition (-not ($launcherSource -match [regex]::Escape($forbiddenCustomerText))) "AXIS first-use wizard preview harness contains forbidden internal/customer text: $forbiddenCustomerText"
}

$mainWindowSource = Get-Content -Raw -LiteralPath $mainWindowPath
foreach ($blockedMainWindowText in @(
    'Start-AxisFirstUseWizardPreview'
    'AxisFirstUseWizardPreview'
    'AxisFirstUseWizardPrototype'
)) {
    Assert-BoostLabCondition (-not $mainWindowSource.Contains($blockedMainWindowText)) "MainWindow must not be wired to the AXIS first-use wizard preview harness: $blockedMainWindowText"
}

$gitPath = Get-BoostLabGitExecutable
Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace($gitPath)) 'Git executable was not found for working-tree guards.'

$mainWindowChanges = @(
    & $gitPath -C $ProjectRoot status --short -- 'ui/MainWindow.ps1' 'ui/MainWindow.xaml'
)
Assert-BoostLabCondition ($LASTEXITCODE -eq 0) 'Unable to inspect MainWindow working-tree status.'
Assert-BoostLabCondition ($mainWindowChanges.Count -eq 0) "MainWindow files have working-tree modifications: $($mainWindowChanges -join '; ')"

$protectedSourceChanges = @(
    & $gitPath -C $ProjectRoot status --short -- 'source-ultimate' 'source-extra' 'intake'
)
Assert-BoostLabCondition ($LASTEXITCODE -eq 0) 'Unable to inspect protected source/intake working-tree status.'
Assert-BoostLabCondition ($protectedSourceChanges.Count -eq 0) "Protected source/intake paths have working-tree modifications: $($protectedSourceChanges -join '; ')"

[pscustomobject]@{
    Test = 'AxisFirstUseWizardPreviewHarness'
    Passed = $true
    LauncherPath = $launcherPath
    BuildOnlyWindowCreated = [bool]$buildOnlyResult.WindowCreated
    NoShowWindowShown = [bool]$noShowResult.WindowShown
    ValidateOnlyWindowShown = [bool]$validateOnlyResult.WindowShown
    WindowWidth = [double]$buildOnlyResult.WindowWidth
    WindowHeight = [double]$buildOnlyResult.WindowHeight
    UsesAxisResources = [bool]$buildOnlyResult.UsesAxisResources
    MainWindowTouched = $false
    ProtectedSourceUnchanged = $true
    RuntimeActionsStarted = $false
}
