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
        throw 'Unable to determine the AXIS first-use wizard test script path.'
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

function Visit-AxisFirstUseWizardTree {
    param(
        [AllowNull()]
        [object]$Root,

        [Parameter(Mandatory)]
        [scriptblock]$Visitor,

        [System.Collections.Generic.HashSet[int]]$Visited = ([System.Collections.Generic.HashSet[int]]::new())
    )

    if ($null -eq $Root) {
        return
    }

    $hashCode = [System.Runtime.CompilerServices.RuntimeHelpers]::GetHashCode($Root)
    if (-not $Visited.Add($hashCode)) {
        return
    }

    & $Visitor $Root

    if ($Root -is [System.Windows.Controls.HeaderedContentControl]) {
        Visit-AxisFirstUseWizardTree -Root $Root.Header -Visitor $Visitor -Visited $Visited
    }
    if ($Root -is [System.Windows.Controls.ContentControl]) {
        Visit-AxisFirstUseWizardTree -Root $Root.Content -Visitor $Visitor -Visited $Visited
    }
    if ($Root -is [System.Windows.Controls.Panel]) {
        foreach ($child in @($Root.Children)) {
            Visit-AxisFirstUseWizardTree -Root $child -Visitor $Visitor -Visited $Visited
        }
    }
    if ($Root -is [System.Windows.Controls.Decorator]) {
        Visit-AxisFirstUseWizardTree -Root $Root.Child -Visitor $Visitor -Visited $Visited
    }
    if ($Root -is [System.Windows.Controls.Button]) {
        Visit-AxisFirstUseWizardTree -Root $Root.Content -Visitor $Visitor -Visited $Visited
    }
    if ($Root -is [System.Windows.Controls.CheckBox]) {
        Visit-AxisFirstUseWizardTree -Root $Root.Content -Visitor $Visitor -Visited $Visited
    }

    if ($Root -is [System.Windows.DependencyObject]) {
        $childCount = 0
        try {
            $childCount = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($Root)
        }
        catch {
            $childCount = 0
        }

        for ($index = 0; $index -lt $childCount; $index++) {
            Visit-AxisFirstUseWizardTree -Root ([System.Windows.Media.VisualTreeHelper]::GetChild($Root, $index)) -Visitor $Visitor -Visited $Visited
        }
    }
}

function Get-AxisFirstUseWizardTextValues {
    param(
        [Parameter(Mandatory)]
        [object]$Root
    )

    $values = [System.Collections.Generic.List[string]]::new()
    Visit-AxisFirstUseWizardTree -Root $Root -Visitor {
        param($Node)

        if ($Node -is [string] -and -not [string]::IsNullOrWhiteSpace($Node)) {
            $values.Add([string]$Node)
        }
        elseif ($Node -is [System.Windows.Controls.TextBlock] -and -not [string]::IsNullOrWhiteSpace($Node.Text)) {
            $values.Add([string]$Node.Text)
        }
    }

    return @($values)
}

function Get-AxisFirstUseWizardTaggedElements {
    param(
        [Parameter(Mandatory)]
        [object]$Root,

        [Parameter(Mandatory)]
        [string]$Tag
    )

    $matches = [System.Collections.Generic.List[object]]::new()
    Visit-AxisFirstUseWizardTree -Root $Root -Visitor {
        param($Node)

        if ($Node -is [System.Windows.FrameworkElement] -and [string]$Node.Tag -eq $Tag) {
            $matches.Add($Node)
        }
    }

    return @($matches)
}

function Get-AxisFirstUseWizardTypedElements {
    param(
        [Parameter(Mandatory)]
        [object]$Root,

        [Parameter(Mandatory)]
        [type]$Type
    )

    $matches = [System.Collections.Generic.List[object]]::new()
    Visit-AxisFirstUseWizardTree -Root $Root -Visitor {
        param($Node)

        if ($Node -is $Type) {
            $matches.Add($Node)
        }
    }

    return @($matches)
}

$prototypePath = Join-Path $ProjectRoot 'ui\AxisFirstUseWizardPrototype.ps1'
$resourcePath = Join-Path $ProjectRoot 'ui\AxisResources.ps1'
$mainWindowPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'

Assert-BoostLabCondition (Test-Path -LiteralPath $prototypePath -PathType Leaf) 'AXIS first-use wizard prototype file is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $resourcePath -PathType Leaf) 'AXIS WPF resources file is missing.'

$prototypeSource = Get-Content -Raw -LiteralPath $prototypePath
. $prototypePath

foreach ($functionName in @(
    'Get-AxisFirstUseWizardSampleState'
    'New-AxisFirstUseWizardPrototype'
    'New-AxisFirstUseWizardPrototypeWindow'
    'New-AxisStageProgressStrip'
    'New-AxisWizardStepContent'
    'New-AxisBiosInformationStep'
    'New-AxisStepDocumentationButton'
    'New-AxisStepPrimaryActionArea'
    'New-AxisStepStatusArea'
    'New-AxisStepIcon'
)) {
    Assert-BoostLabCondition (
        $null -ne (Get-Command -Name $functionName -CommandType Function -ErrorAction SilentlyContinue)
    ) "Required AXIS first-use wizard function is missing: $functionName"
}

$sampleState = Get-AxisFirstUseWizardSampleState
$prototype = New-AxisFirstUseWizardPrototype -SampleState $sampleState
$window = New-AxisFirstUseWizardPrototypeWindow -SampleState $sampleState

Assert-BoostLabCondition ($prototype -is [System.Windows.Controls.Grid]) 'AXIS first-use wizard did not create a WPF Grid root.'
Assert-BoostLabCondition ($window -is [System.Windows.Window]) 'AXIS first-use wizard preview window was not created as a WPF Window.'
Assert-BoostLabCondition ([double]$window.Width -eq 900.0) 'AXIS first-use wizard target window width should be 900.'
Assert-BoostLabCondition ([double]$window.Height -eq 650.0) 'AXIS first-use wizard target window height should be 650.'
Assert-BoostLabCondition ([double]$prototype.Width -eq 900.0) 'AXIS first-use wizard root width should be 900.'
Assert-BoostLabCondition ([double]$prototype.Height -eq 650.0) 'AXIS first-use wizard root height should be 650.'
Assert-BoostLabCondition ($prototype.Resources.Contains('Axis.Brush.Background.App')) 'AXIS first-use wizard root does not include AXIS resources.'

$texts = @(Get-AxisFirstUseWizardTextValues -Root $prototype)
$joinedText = $texts -join [Environment]::NewLine

foreach ($requiredText in @(
    'AXIS'
    'Guided setup'
    'Stage: Check'
    'Check'
    'Refresh'
    'Setup'
    'Apps'
    'Graphics'
    'Windows'
    'Finish'
    'BIOS Information'
    'Review basic firmware and motherboard information before continuing the setup flow.'
    'What this step checks'
    'BIOS/UEFI version'
    'Requirements'
    'View documentation'
    'Ready'
    'Back'
    'Continue'
    'Cancel'
)) {
    Assert-BoostLabCondition ($joinedText.Contains($requiredText)) "AXIS first-use wizard is missing expected text: $requiredText"
}

$taggedStageProgressStrip = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.StageProgressStrip')
$taggedBiosInformationStep = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.BiosInformationStep')
$taggedBiosInformationIcon = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.BiosInformationIcon')
$taggedDocumentationButton = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.DocumentationButton')
$taggedStageProgressItems = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.StageProgressItem')
$taggedBottomNavigation = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.BottomNavigation')
$taggedPreviousStageNavigation = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisPrototype.StageNavigation')

Assert-BoostLabCondition ($taggedStageProgressStrip.Count -eq 1) 'AXIS first-use wizard stage progress strip is missing.'
Assert-BoostLabCondition ($taggedBiosInformationStep.Count -eq 1) 'AXIS BIOS Information step is missing.'
Assert-BoostLabCondition ($taggedBiosInformationIcon.Count -eq 1) 'AXIS BIOS Information icon is missing.'
Assert-BoostLabCondition ($taggedDocumentationButton.Count -eq 1) 'AXIS BIOS Information documentation button is missing.'
Assert-BoostLabCondition ($taggedStageProgressItems.Count -eq 7) 'AXIS stage progress should show stage names only.'
Assert-BoostLabCondition ($taggedBottomNavigation.Count -eq 1) 'AXIS first-use wizard bottom navigation is missing.'
Assert-BoostLabCondition ($taggedPreviousStageNavigation.Count -eq 0) 'AXIS first-use wizard must not include the previous sidebar stage navigation.'
Assert-BoostLabCondition (-not $joinedText.Contains('Your setup path')) 'AXIS first-use wizard must not include sidebar navigation copy.'

$strip = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.StageProgressStrip') | Select-Object -First 1
$stripTexts = @(Get-AxisFirstUseWizardTextValues -Root $strip)
$expectedStageNames = @('Check', 'Refresh', 'Setup', 'Apps', 'Graphics', 'Windows', 'Finish')
foreach ($stageName in $expectedStageNames) {
    Assert-BoostLabCondition ($stageName -in $stripTexts) "AXIS stage progress strip is missing stage name: $stageName"
}
Assert-BoostLabCondition (-not ('BIOS Information' -in $stripTexts)) 'AXIS stage progress strip must show stage names only, not step/script names.'
Assert-BoostLabCondition (-not ('Start menu and taskbar' -in $stripTexts)) 'AXIS stage progress strip must not include previous workspace card names.'

$biosStep = $sampleState['Step']
Assert-BoostLabCondition ([string]$biosStep['Title'] -eq 'BIOS Information') 'AXIS first-use wizard first step should be BIOS Information.'
Assert-BoostLabCondition (-not [bool]$biosStep['RequiresDocumentationAcknowledgement']) 'BIOS Information should not require documentation acknowledgement by default.'

$completedBiosStep = [ordered]@{}
foreach ($key in $biosStep.Keys) {
    $completedBiosStep[$key] = $biosStep[$key]
}
$completedBiosStep['State'] = 'Completed'
$completedBiosStep['StateLabel'] = 'Completed'
$completedBiosStepContent = New-AxisBiosInformationStep -Step $completedBiosStep -Resources (New-AxisWpfResourceDictionary)
$completedBiosStepText = (Get-AxisFirstUseWizardTextValues -Root $completedBiosStepContent) -join [Environment]::NewLine
Assert-BoostLabCondition ($completedBiosStepText.Contains('Completed')) 'AXIS first-use wizard must expose the Completed customer-facing completion label for completed steps.'

$dangerousStep = $sampleState['DangerousStepPattern']
Assert-BoostLabCondition ([bool]$dangerousStep['RequiresDocumentationAcknowledgement']) 'AXIS wizard model should support required documentation acknowledgement for future protected steps.'
$dangerousActionArea = New-AxisStepPrimaryActionArea -Step $dangerousStep -Resources (New-AxisWpfResourceDictionary)
$acknowledgement = @(Get-AxisFirstUseWizardTaggedElements -Root $dangerousActionArea -Tag 'AxisFirstUseWizard.DocumentationAcknowledgement')
Assert-BoostLabCondition ($acknowledgement.Count -eq 1) 'AXIS wizard dangerous-step pattern should render a documentation acknowledgement checkbox.'
$dangerousButtons = @(Get-AxisFirstUseWizardTypedElements -Root $dangerousActionArea -Type ([System.Windows.Controls.Button]))
Assert-BoostLabCondition ($dangerousButtons.Count -ge 1) 'AXIS wizard dangerous-step pattern should render an action button.'
Assert-BoostLabCondition (-not [bool]$dangerousButtons[0].IsEnabled) 'AXIS wizard dangerous-step primary action should be disabled until acknowledged.'

foreach ($stateLabel in @(
    'Ready'
    'Checking'
    'Completed'
)) {
    Assert-BoostLabCondition ($stateLabel -in @($sampleState['SupportedStepStates'])) "AXIS first-use wizard does not support state label: $stateLabel"
}

foreach ($removedCustomerLabel in @(
    'Error'
    'Failed'
    'Warning'
    'Needs attention'
    'Stopped'
    'Restart needed'
    'Waiting for your confirmation'
    'Waiting for confirmation'
    'Not available'
    'Skipped'
)) {
    Assert-BoostLabCondition (-not ($joinedText -match "(?m)\b$([regex]::Escape($removedCustomerLabel))\b")) "AXIS first-use wizard exposes removed customer-facing state label: $removedCustomerLabel"
    Assert-BoostLabCondition (-not ($completedBiosStepText -match "(?m)\b$([regex]::Escape($removedCustomerLabel))\b")) "AXIS completed first-use wizard step exposes removed customer-facing state label: $removedCustomerLabel"
    Assert-BoostLabCondition ($removedCustomerLabel -notin @($sampleState['SupportedStepStates'])) "AXIS first-use wizard customer state model must not include removed label: $removedCustomerLabel"
}

Assert-BoostLabCondition ('Completed' -in @($sampleState['SupportedStepStates'])) 'AXIS first-use wizard customer state model must include Completed.'

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
    Assert-BoostLabCondition (-not ($joinedText -match [regex]::Escape($forbiddenCustomerText))) "AXIS first-use wizard exposes forbidden internal text: $forbiddenCustomerText"
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
    'Clear-RecycleBin'
    'Remove-AppxPackage'
    'Add-AppxPackage'
    'Set-MpPreference'
)) {
    Assert-BoostLabCondition (-not $prototypeSource.Contains($blockedRuntimeText)) "AXIS first-use wizard must not contain runtime/system mutation text: $blockedRuntimeText"
}

$mainWindowSource = Get-Content -Raw -LiteralPath $mainWindowPath
Assert-BoostLabCondition (-not $mainWindowSource.Contains('AxisFirstUseWizardPrototype')) 'MainWindow should not be wired to the AXIS first-use wizard prototype.'
Assert-BoostLabCondition (-not $mainWindowSource.Contains('Start-AxisFirstUseWizardPreview')) 'MainWindow should not be wired to the AXIS first-use wizard preview harness.'

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
    Test = 'AxisFirstUseWizardPrototype'
    Passed = $true
    PrototypePath = $prototypePath
    WindowWidth = [double]$window.Width
    WindowHeight = [double]$window.Height
    StageProgressItemCount = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.StageProgressItem').Count
    FirstStep = [string]$biosStep['Title']
    MainWindowTouched = $false
    ProtectedSourceUnchanged = $true
    RuntimeActionsStarted = $false
}
