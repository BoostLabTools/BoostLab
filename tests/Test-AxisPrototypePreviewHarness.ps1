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
        throw 'Unable to determine the AXIS preview harness test script path.'
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

$launcherPath = Join-Path $ProjectRoot 'tools\dev\Start-AxisPrototypePreview.ps1'
$resourcePath = Join-Path $ProjectRoot 'ui\AxisResources.ps1'
$prototypePath = Join-Path $ProjectRoot 'ui\AxisGuidedStageWorkspacePrototype.ps1'
$mainWindowPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'

Assert-BoostLabCondition (Test-Path -LiteralPath $launcherPath -PathType Leaf) 'AXIS prototype preview launcher is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $resourcePath -PathType Leaf) 'AXIS WPF resource file is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $prototypePath -PathType Leaf) 'AXIS Guided Stage Workspace prototype file is missing.'

$launcherSource = Get-Content -Raw -LiteralPath $launcherPath
Assert-BoostLabCondition ($launcherSource.Contains('AxisResources.ps1')) 'AXIS preview launcher must import/use AxisResources.ps1.'
Assert-BoostLabCondition ($launcherSource.Contains('AxisGuidedStageWorkspacePrototype.ps1')) 'AXIS preview launcher must import/use AxisGuidedStageWorkspacePrototype.ps1.'
Assert-BoostLabCondition ($launcherSource.Contains('BuildOnly')) 'AXIS preview launcher must expose a build-only test-safe mode.'
Assert-BoostLabCondition ($launcherSource.Contains('NoShow')) 'AXIS preview launcher must expose a no-show test-safe mode.'
Assert-BoostLabCondition ($launcherSource.Contains('ValidateOnly')) 'AXIS preview launcher should provide a validate-only alias for test-safe mode.'

. $launcherPath -BuildOnly -ProjectRoot $ProjectRoot

Assert-BoostLabCondition (
    $null -ne (Get-Command -Name 'Invoke-AxisPrototypePreview' -CommandType Function -ErrorAction SilentlyContinue)
) 'AXIS preview launcher did not import safely or define Invoke-AxisPrototypePreview.'

$buildOnlyResult = Invoke-AxisPrototypePreview -BuildOnly -ProjectRoot $ProjectRoot
Assert-BoostLabCondition ($buildOnlyResult.Preview -eq 'AxisGuidedStageWorkspace') 'AXIS preview harness returned an unexpected preview name.'
Assert-BoostLabCondition ($buildOnlyResult.Mode -eq 'BuildOnly') 'AXIS preview harness did not report BuildOnly mode.'
Assert-BoostLabCondition ([bool]$buildOnlyResult.WindowCreated) 'AXIS preview harness did not create the prototype window in BuildOnly mode.'
Assert-BoostLabCondition (-not [bool]$buildOnlyResult.WindowShown) 'AXIS preview harness must not show the window in BuildOnly mode.'
Assert-BoostLabCondition ([bool]$buildOnlyResult.UsesAxisResources) 'AXIS preview harness did not create a preview using AXIS resources.'
Assert-BoostLabCondition (-not [bool]$buildOnlyResult.RuntimeActionsStarted) 'AXIS preview harness must not start runtime actions.'
Assert-BoostLabCondition (-not [bool]$buildOnlyResult.HostMutated) 'AXIS preview harness must not mutate host state.'

$noShowResult = Invoke-AxisPrototypePreview -NoShow -ProjectRoot $ProjectRoot
Assert-BoostLabCondition ($noShowResult.Mode -eq 'NoShow') 'AXIS preview harness did not report NoShow mode.'
Assert-BoostLabCondition (-not [bool]$noShowResult.WindowShown) 'AXIS preview harness must not show the window in NoShow mode.'
Assert-BoostLabCondition ([bool]$noShowResult.WindowCreated) 'AXIS preview harness did not create the prototype window in NoShow mode.'

$externalOutput = & powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File $launcherPath -BuildOnly -ProjectRoot $ProjectRoot 2>&1
Assert-BoostLabCondition ($LASTEXITCODE -eq 0) 'AXIS preview launcher failed when run as a script in BuildOnly mode.'
Assert-BoostLabCondition (
    (($externalOutput | Out-String).Contains('AxisGuidedStageWorkspace'))
) 'AXIS preview launcher script output did not include the expected preview identity.'

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
    Assert-BoostLabCondition (-not $launcherSource.Contains($blockedRuntimeText)) "AXIS preview harness must not contain runtime/system mutation text: $blockedRuntimeText"
}

foreach ($blockedActionWord in @('Apply', 'Default', 'Restore')) {
    Assert-BoostLabCondition (-not ($launcherSource -match "\b$blockedActionWord\b")) "AXIS preview harness must not call or expose runtime action word: $blockedActionWord"
}

foreach ($blockedPathText in @(
    'source-ultimate'
    'source-extra'
    'intake'
)) {
    Assert-BoostLabCondition (-not $launcherSource.Contains($blockedPathText)) "AXIS preview harness must not require protected source/intake path: $blockedPathText"
}

foreach ($forbiddenCustomerText in @(
    'Ultimate'
    'source-defined'
    'source-equivalent'
    'Codex'
    'ChatGPT'
    'OpenAI'
    'Yazan'
)) {
    Assert-BoostLabCondition (-not ($launcherSource -match [regex]::Escape($forbiddenCustomerText))) "AXIS preview harness contains forbidden internal/customer text: $forbiddenCustomerText"
}

$mainWindowSource = Get-Content -Raw -LiteralPath $mainWindowPath
foreach ($blockedMainWindowText in @(
    'Start-AxisPrototypePreview'
    'AxisPrototypePreview'
    'AxisGuidedStageWorkspacePrototype'
    'BOOSTLAB_AXIS_PROTOTYPE'
)) {
    Assert-BoostLabCondition (-not $mainWindowSource.Contains($blockedMainWindowText)) "MainWindow must not be wired to the AXIS prototype preview harness: $blockedMainWindowText"
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
    Test = 'AxisPrototypePreviewHarness'
    Passed = $true
    LauncherPath = $launcherPath
    BuildOnlyWindowCreated = [bool]$buildOnlyResult.WindowCreated
    NoShowWindowShown = [bool]$noShowResult.WindowShown
    UsesAxisResources = [bool]$buildOnlyResult.UsesAxisResources
    MainWindowTouched = $false
    ProtectedSourceUnchanged = $true
    RuntimeActionsStarted = $false
}
