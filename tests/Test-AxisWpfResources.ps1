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
        throw 'Unable to determine the AXIS WPF resources test script path.'
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

$resourcePath = Join-Path $ProjectRoot 'ui\AxisResources.ps1'
Assert-BoostLabCondition (Test-Path -LiteralPath $resourcePath -PathType Leaf) 'AXIS WPF resource foundation file is missing.'

$resourceSource = Get-Content -Raw -LiteralPath $resourcePath
. $resourcePath

foreach ($functionName in @(
    'Get-AxisDesignTokens'
    'New-AxisWpfResourceDictionary'
    'Add-AxisResourcesToElement'
    'Get-AxisResourceValue'
    'Test-AxisDesignTokens'
)) {
    Assert-BoostLabCondition (
        $null -ne (Get-Command -Name $functionName -CommandType Function -ErrorAction SilentlyContinue)
    ) "Required AXIS resource function is missing: $functionName"
}

$tokens = Get-AxisDesignTokens
foreach ($categoryName in @(
    'Colors'
    'Brushes'
    'Typography'
    'Spacing'
    'Radius'
    'Borders'
    'StatusResults'
    'Risks'
    'Focus'
    'Diagnostics'
)) {
    Assert-BoostLabCondition ($tokens.Contains($categoryName)) "AXIS design token category is missing: $categoryName"
    Assert-BoostLabCondition ($tokens[$categoryName].Count -gt 0) "AXIS design token category is empty: $categoryName"
}

foreach ($colorKey in $tokens.Colors.Keys) {
    Assert-BoostLabCondition (
        [string]$tokens.Colors[$colorKey] -match '^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$'
    ) "AXIS color token is not a valid hex color: $colorKey"
}

$requiredResourceKeys = @(
    'Axis.Color.Background.App'
    'Axis.Color.Surface.Base'
    'Axis.Color.Surface.Raised'
    'Axis.Color.Text.Primary'
    'Axis.Color.Text.Secondary'
    'Axis.Color.Accent.Primary'
    'Axis.Brush.Background.App'
    'Axis.Brush.Surface.Base'
    'Axis.Brush.Text.Primary'
    'Axis.Brush.Accent.Primary'
    'Axis.Space.16'
    'Axis.Thickness.16'
    'Axis.Radius.Medium'
    'Axis.Border.Width.Default'
    'Axis.Status.Completed.Brush'
    'Axis.Status.CompletedWithNotes.Brush'
    'Axis.Status.NeedsAttention.Brush'
    'Axis.Status.RestartNeeded.Brush'
    'Axis.Status.WaitingForConfirmation.Brush'
    'Axis.Status.NotAvailableOnThisDevice.Brush'
    'Axis.Status.SkippedBecauseNotNeeded.Brush'
    'Axis.Status.Running.Brush'
    'Axis.Risk.SystemChange.Brush'
    'Axis.Risk.DriverChange.Brush'
    'Axis.Risk.SecuritySensitive.Brush'
    'Axis.Risk.RestartRequired.Brush'
    'Axis.Risk.DownloadRequired.Brush'
    'Axis.Risk.FileCleanup.Brush'
    'Axis.Risk.Advanced.Brush'
    'Axis.Risk.DeviceSpecific.Brush'
    'Axis.Focus.Ring.Brush'
    'Axis.Brush.Diagnostics.Background'
    'Axis.Type.Body.FontFamily'
    'Axis.Type.Body.FontSize'
    'Axis.Type.Body.FontWeight'
)

$dictionary = New-AxisWpfResourceDictionary -Tokens $tokens
Assert-BoostLabCondition ($dictionary -is [System.Windows.ResourceDictionary]) 'AXIS WPF resources did not create a ResourceDictionary.'
foreach ($resourceKey in $requiredResourceKeys) {
    Assert-BoostLabCondition ($dictionary.Contains($resourceKey)) "AXIS WPF resource key is missing: $resourceKey"
}

foreach ($brushKey in @(
    'Axis.Brush.Background.App'
    'Axis.Brush.Surface.Base'
    'Axis.Brush.Text.Primary'
    'Axis.Brush.Accent.Primary'
    'Axis.Status.Completed.Brush'
    'Axis.Status.CompletedWithNotes.Brush'
    'Axis.Risk.DriverChange.Brush'
    'Axis.Focus.Ring.Brush'
)) {
    Assert-BoostLabCondition ($dictionary[$brushKey] -is [System.Windows.Media.SolidColorBrush]) "AXIS resource is not a SolidColorBrush: $brushKey"
    Assert-BoostLabCondition ([bool]$dictionary[$brushKey].IsFrozen) "AXIS brush should be frozen for safe reuse: $brushKey"
}

Assert-BoostLabCondition ($dictionary['Axis.Space.16'] -is [double]) 'Axis.Space.16 should be a numeric spacing resource.'
Assert-BoostLabCondition ($dictionary['Axis.Thickness.16'] -is [System.Windows.Thickness]) 'Axis.Thickness.16 should be a Thickness resource.'
Assert-BoostLabCondition ($dictionary['Axis.Radius.Medium'] -is [System.Windows.CornerRadius]) 'Axis.Radius.Medium should be a CornerRadius resource.'
Assert-BoostLabCondition ($dictionary['Axis.Type.Body.FontFamily'] -is [System.Windows.Media.FontFamily]) 'Axis.Type.Body.FontFamily should be a FontFamily resource.'
Assert-BoostLabCondition ($dictionary['Axis.Type.Body.FontWeight'] -is [System.Windows.FontWeight]) 'Axis.Type.Body.FontWeight should be a FontWeight resource.'

$testElement = [System.Windows.Controls.Grid]::new()
$attachedResources = Add-AxisResourcesToElement -Element $testElement -Resources $dictionary
Assert-BoostLabCondition ([object]::ReferenceEquals($attachedResources, $testElement.Resources)) 'AXIS resources should be added to the target WPF element resource collection.'
Assert-BoostLabCondition ($testElement.Resources.Contains('Axis.Brush.Background.App')) 'AXIS resources were not attached to the target WPF element.'

$expectedCustomerStates = @(
    'Completed'
    'CompletedWithNotes'
    'NeedsAttention'
    'Stopped'
    'RestartNeeded'
    'WaitingForConfirmation'
    'NotAvailableOnThisDevice'
    'SkippedBecauseNotNeeded'
    'Running'
)
$actualCustomerStates = @($tokens.StatusResults.Keys | ForEach-Object { [string]$_ })
foreach ($stateName in $expectedCustomerStates) {
    Assert-BoostLabCondition ($stateName -in $actualCustomerStates) "Customer-facing AXIS state is missing: $stateName"
}
foreach ($rawStateName in @('Success', 'Warning', 'Error')) {
    Assert-BoostLabCondition ($rawStateName -notin $actualCustomerStates) "Raw technical state must not be a primary AXIS customer state: $rawStateName"
    Assert-BoostLabCondition (-not $dictionary.Contains("Axis.Status.$rawStateName.Brush")) "Raw technical state resource must not exist as a primary AXIS status: $rawStateName"
}

$expectedRisks = @(
    'SystemChange'
    'DriverChange'
    'SecuritySensitive'
    'RestartRequired'
    'DownloadRequired'
    'FileCleanup'
    'Advanced'
    'DeviceSpecific'
)
$actualRisks = @($tokens.Risks.Keys | ForEach-Object { [string]$_ })
foreach ($riskName in $expectedRisks) {
    Assert-BoostLabCondition ($riskName -in $actualRisks) "AXIS risk token is missing: $riskName"
    Assert-BoostLabCondition ($dictionary.Contains("Axis.Risk.$riskName.Brush")) "AXIS risk brush is missing: $riskName"
}

$selfTest = Test-AxisDesignTokens
Assert-BoostLabCondition ([bool]$selfTest.Passed) "AXIS design token self-test failed: $($selfTest.MissingKeys -join ', ')"

foreach ($forbiddenPattern in @(
    '(?i)\bCodex\b'
    '(?i)\bChatGPT\b'
    '(?i)\bOpenAI\b'
    '(?i)\bprompt\b'
    '(?i)\bYazan\b'
    '(?i)\bUltimate\b'
    '(?i)\bsource-defined\b'
    '(?i)\bsource-equivalent\b'
)) {
    Assert-BoostLabCondition (-not ($resourceSource -match $forbiddenPattern)) "AXIS resource file contains forbidden internal/workflow text: $forbiddenPattern"
}

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
    'schtasks'
)) {
    Assert-BoostLabCondition (-not $resourceSource.Contains($blockedRuntimeText)) "AXIS resource file must not contain runtime/system mutation text: $blockedRuntimeText"
}

$gitPath = Get-BoostLabGitExecutable
Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace($gitPath)) 'Git executable was not found for protected source working-tree guard.'
$protectedSourceChanges = @(
    & $gitPath -C $ProjectRoot status --short -- 'source-ultimate' 'source-extra' 'intake'
)
Assert-BoostLabCondition ($LASTEXITCODE -eq 0) 'Unable to inspect protected source/intake working-tree status.'
Assert-BoostLabCondition ($protectedSourceChanges.Count -eq 0) "Protected source/intake paths have working-tree modifications: $($protectedSourceChanges -join '; ')"

[pscustomobject]@{
    Test = 'AxisWpfResources'
    Passed = $true
    ResourcePath = $resourcePath
    TokenCategoryCount = $tokens.Keys.Count
    ResourceCount = $dictionary.Keys.Count
    CustomerStateCount = $actualCustomerStates.Count
    RiskTokenCount = $actualRisks.Count
    ProtectedSourceUnchanged = $true
    RuntimeActionsStarted = $false
}
