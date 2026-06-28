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
        throw 'Unable to determine the AXIS prototype test script path.'
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

function Get-AxisPrototypeTextValues {
    param(
        [Parameter(Mandatory)]
        [object]$Root
    )

    $values = [System.Collections.Generic.List[string]]::new()
    $visited = [System.Collections.Generic.HashSet[int]]::new()

    function Add-AxisPrototypeTextFromObject {
        param(
            [AllowNull()]
            [object]$Node
        )

        if ($null -eq $Node) {
            return
        }

        $hashCode = [System.Runtime.CompilerServices.RuntimeHelpers]::GetHashCode($Node)
        if (-not $visited.Add($hashCode)) {
            return
        }

        if ($Node -is [string]) {
            if (-not [string]::IsNullOrWhiteSpace($Node)) {
                $values.Add([string]$Node)
            }
            return
        }

        if ($Node -is [System.Windows.Controls.TextBlock]) {
            if (-not [string]::IsNullOrWhiteSpace($Node.Text)) {
                $values.Add([string]$Node.Text)
            }
        }

        if ($Node -is [System.Windows.Controls.HeaderedContentControl]) {
            Add-AxisPrototypeTextFromObject -Node $Node.Header
        }

        if ($Node -is [System.Windows.Controls.ContentControl]) {
            Add-AxisPrototypeTextFromObject -Node $Node.Content
        }

        if ($Node -is [System.Windows.Controls.Panel]) {
            foreach ($child in @($Node.Children)) {
                Add-AxisPrototypeTextFromObject -Node $child
            }
        }

        if ($Node -is [System.Windows.Controls.Decorator]) {
            Add-AxisPrototypeTextFromObject -Node $Node.Child
        }

        if ($Node -is [System.Windows.DependencyObject]) {
            $childCount = 0
            try {
                $childCount = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($Node)
            }
            catch {
                $childCount = 0
            }

            for ($index = 0; $index -lt $childCount; $index++) {
                Add-AxisPrototypeTextFromObject -Node ([System.Windows.Media.VisualTreeHelper]::GetChild($Node, $index))
            }
        }
    }

    Add-AxisPrototypeTextFromObject -Node $Root
    return @($values)
}

function Get-AxisPrototypeTaggedElements {
    param(
        [Parameter(Mandatory)]
        [object]$Root,

        [Parameter(Mandatory)]
        [string]$Tag
    )

    $matches = [System.Collections.Generic.List[object]]::new()
    $visited = [System.Collections.Generic.HashSet[int]]::new()

    function Visit-AxisPrototypeNode {
        param(
            [AllowNull()]
            [object]$Node
        )

        if ($null -eq $Node) {
            return
        }

        $hashCode = [System.Runtime.CompilerServices.RuntimeHelpers]::GetHashCode($Node)
        if (-not $visited.Add($hashCode)) {
            return
        }

        if ($Node -is [System.Windows.FrameworkElement] -and [string]$Node.Tag -eq $Tag) {
            $matches.Add($Node)
        }

        if ($Node -is [System.Windows.Controls.ContentControl]) {
            Visit-AxisPrototypeNode -Node $Node.Content
        }

        if ($Node -is [System.Windows.Controls.Panel]) {
            foreach ($child in @($Node.Children)) {
                Visit-AxisPrototypeNode -Node $child
            }
        }

        if ($Node -is [System.Windows.Controls.Decorator]) {
            Visit-AxisPrototypeNode -Node $Node.Child
        }

        if ($Node -is [System.Windows.DependencyObject]) {
            $childCount = 0
            try {
                $childCount = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($Node)
            }
            catch {
                $childCount = 0
            }

            for ($index = 0; $index -lt $childCount; $index++) {
                Visit-AxisPrototypeNode -Node ([System.Windows.Media.VisualTreeHelper]::GetChild($Node, $index))
            }
        }
    }

    Visit-AxisPrototypeNode -Node $Root
    return @($matches)
}

$prototypePath = Join-Path $ProjectRoot 'ui\AxisGuidedStageWorkspacePrototype.ps1'
$resourcePath = Join-Path $ProjectRoot 'ui\AxisResources.ps1'
$mainWindowPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'

Assert-BoostLabCondition (Test-Path -LiteralPath $prototypePath -PathType Leaf) 'AXIS Guided Stage Workspace prototype file is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $resourcePath -PathType Leaf) 'AXIS WPF resources file is missing.'

$prototypeSource = Get-Content -Raw -LiteralPath $prototypePath
. $prototypePath

foreach ($functionName in @(
    'New-AxisGuidedStageWorkspacePrototype'
    'New-AxisGuidedStageWorkspacePrototypeWindow'
    'New-AxisPrototypeStageNavigation'
    'New-AxisPrototypeStageScreen'
    'New-AxisPrototypeToolCard'
    'New-AxisPrototypeToolDetailPanel'
    'New-AxisPrototypeRiskBadge'
    'New-AxisPrototypeResultSummary'
    'New-AxisPrototypeDiagnosticsDrawer'
    'Get-AxisPrototypeSampleState'
)) {
    Assert-BoostLabCondition (
        $null -ne (Get-Command -Name $functionName -CommandType Function -ErrorAction SilentlyContinue)
    ) "Required AXIS prototype function is missing: $functionName"
}

$sampleState = Get-AxisPrototypeSampleState
$prototype = New-AxisGuidedStageWorkspacePrototype -SampleState $sampleState
Assert-BoostLabCondition ($prototype -is [System.Windows.Controls.Grid]) 'AXIS prototype did not create a WPF Grid root.'
Assert-BoostLabCondition ($prototype.Resources.Contains('Axis.Brush.Background.App')) 'AXIS prototype root does not include the AXIS resource dictionary.'
Assert-BoostLabCondition ($prototype.Resources.Contains('Axis.Status.Completed.Brush')) 'AXIS prototype root is missing customer status resources.'

$prototypeWindow = New-AxisGuidedStageWorkspacePrototypeWindow -SampleState $sampleState
Assert-BoostLabCondition ($prototypeWindow -is [System.Windows.Window]) 'AXIS prototype preview window was not created as a WPF Window.'
Assert-BoostLabCondition ($prototypeWindow.Content -is [System.Windows.Controls.Grid]) 'AXIS prototype preview window does not host the prototype grid.'

$texts = @(Get-AxisPrototypeTextValues -Root $prototype)
$joinedText = $texts -join [Environment]::NewLine
foreach ($requiredText in @(
    'AXIS'
    'Guided setup'
    'Windows'
    'Windows steps'
    'Result summary'
    'Diagnostics'
    'Copy technical report'
    'Completed'
    'Completed with notes'
    'Needs attention'
    'Restart needed'
    'Waiting for your confirmation'
    'Not available on this device'
    'Skipped because not needed'
    'Running'
)) {
    Assert-BoostLabCondition ($joinedText.Contains($requiredText)) "AXIS prototype is missing expected customer-facing text: $requiredText"
}

foreach ($rawPrimaryLabel in @('Success', 'Warning', 'Error')) {
    Assert-BoostLabCondition (-not ($joinedText -match "(?m)\b$rawPrimaryLabel\b")) "AXIS prototype uses a raw technical status as primary customer text: $rawPrimaryLabel"
}

foreach ($forbiddenCustomerText in @(
    'Ultimate'
    'source-ultimate'
    'source-extra'
    'source-defined'
    'source-equivalent'
    'Codex'
    'ChatGPT'
    'OpenAI'
    'Yazan'
)) {
    Assert-BoostLabCondition (-not ($joinedText -match [regex]::Escape($forbiddenCustomerText))) "AXIS prototype exposes forbidden internal text in the customer surface: $forbiddenCustomerText"
}

$taggedRoot = @(Get-AxisPrototypeTaggedElements -Root $prototype -Tag 'AxisPrototype.GuidedStageWorkspace')
$taggedProductHeader = @(Get-AxisPrototypeTaggedElements -Root $prototype -Tag 'AxisPrototype.ProductHeader')
$taggedStageNavigation = @(Get-AxisPrototypeTaggedElements -Root $prototype -Tag 'AxisPrototype.StageNavigation')
$taggedStageScreen = @(Get-AxisPrototypeTaggedElements -Root $prototype -Tag 'AxisPrototype.StageScreen')
$taggedToolDetailPanel = @(Get-AxisPrototypeTaggedElements -Root $prototype -Tag 'AxisPrototype.ToolDetailPanel')
$taggedActionArea = @(Get-AxisPrototypeTaggedElements -Root $prototype -Tag 'AxisPrototype.ActionArea')
$taggedResultSummary = @(Get-AxisPrototypeTaggedElements -Root $prototype -Tag 'AxisPrototype.ResultSummary')
$taggedDiagnosticsDrawer = @(Get-AxisPrototypeTaggedElements -Root $prototype -Tag 'AxisPrototype.DiagnosticsDrawer')
$taggedToolCards = @(Get-AxisPrototypeTaggedElements -Root $prototype -Tag 'AxisPrototype.ToolCard')
$taggedRiskBadges = @(Get-AxisPrototypeTaggedElements -Root $prototype -Tag 'AxisPrototype.RiskBadge')

Assert-BoostLabCondition ($taggedRoot.Count -eq 1) 'AXIS prototype root tag is missing.'
Assert-BoostLabCondition ($taggedProductHeader.Count -eq 1) 'AXIS product header is missing.'
Assert-BoostLabCondition ($taggedStageNavigation.Count -eq 1) 'AXIS stage navigation is missing.'
Assert-BoostLabCondition ($taggedStageScreen.Count -eq 1) 'AXIS stage screen is missing.'
Assert-BoostLabCondition ($taggedToolDetailPanel.Count -eq 1) 'AXIS tool detail panel is missing.'
Assert-BoostLabCondition ($taggedActionArea.Count -eq 1) 'AXIS action area is missing.'
Assert-BoostLabCondition ($taggedResultSummary.Count -eq 1) 'AXIS result summary is missing.'
Assert-BoostLabCondition ($taggedDiagnosticsDrawer.Count -eq 1) 'AXIS diagnostics drawer is missing.'
Assert-BoostLabCondition ($taggedToolCards.Count -ge 9) 'AXIS prototype should include tool/step cards.'
Assert-BoostLabCondition ($taggedRiskBadges.Count -gt 0) 'AXIS prototype should include risk badges.'

$toolStates = @($sampleState['Tools'] | ForEach-Object { [string]$_['State'] })
$toolStateLabels = @($sampleState['Tools'] | ForEach-Object { [string]$_['StateLabel'] })
foreach ($stateName in @(
    'Default'
    'Selected'
    'Running'
    'Completed'
    'CompletedWithNotes'
    'NeedsAttention'
    'RestartNeeded'
    'NotAvailableOnThisDevice'
    'SkippedBecauseNotNeeded'
)) {
    Assert-BoostLabCondition ($stateName -in $toolStates) "AXIS prototype sample state is missing card state: $stateName"
}
foreach ($stateLabel in @(
    'Completed with notes'
    'Needs attention'
    'Restart needed'
    'Not available on this device'
    'Skipped because not needed'
)) {
    Assert-BoostLabCondition ($stateLabel -in $toolStateLabels) "AXIS prototype sample state is missing customer card label: $stateLabel"
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
    'powercfg'
    'winget'
    'schtasks'
)) {
    Assert-BoostLabCondition (-not $prototypeSource.Contains($blockedRuntimeText)) "AXIS prototype file must not contain runtime/system mutation text: $blockedRuntimeText"
}

$mainWindowSource = Get-Content -Raw -LiteralPath $mainWindowPath
Assert-BoostLabCondition (-not $mainWindowSource.Contains('AxisGuidedStageWorkspacePrototype')) 'MainWindow should not be wired to the isolated AXIS prototype by default.'
Assert-BoostLabCondition (-not $mainWindowSource.Contains('BOOSTLAB_AXIS_PROTOTYPE')) 'MainWindow should not contain a default-on AXIS prototype flag path.'

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
    Test = 'AxisGuidedStageWorkspacePrototype'
    Passed = $true
    PrototypePath = $prototypePath
    ToolCardCount = $taggedToolCards.Count
    CustomerTextCount = $texts.Count
    UsesAxisResources = $true
    MainWindowTouched = $false
    ProtectedSourceUnchanged = $true
    RuntimeActionsStarted = $false
}
