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

function ConvertTo-AxisWizardBlueprintMojibakeText {
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    return [Text.Encoding]::GetEncoding(1252).GetString([Text.Encoding]::UTF8.GetBytes($Text))
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

function Get-AxisFirstUseWizardInlineText {
    param(
        [AllowNull()]
        [object]$Inline
    )

    if ($null -eq $Inline) {
        return ''
    }

    if ($Inline -is [System.Windows.Documents.Run]) {
        return [string]$Inline.Text
    }

    if ($Inline -is [System.Windows.Documents.LineBreak]) {
        return [Environment]::NewLine
    }

    if ($Inline -is [System.Windows.Documents.Span]) {
        $parts = [System.Collections.Generic.List[string]]::new()
        foreach ($childInline in @($Inline.Inlines)) {
            $parts.Add((Get-AxisFirstUseWizardInlineText -Inline $childInline))
        }
        return ($parts -join '')
    }

    return ''
}

function Get-AxisFirstUseWizardTextBlockPlainText {
    param(
        [Parameter(Mandatory)]
        [System.Windows.Controls.TextBlock]$TextBlock
    )

    if (-not [string]::IsNullOrWhiteSpace($TextBlock.Text)) {
        return [string]$TextBlock.Text
    }

    $parts = [System.Collections.Generic.List[string]]::new()
    foreach ($inline in @($TextBlock.Inlines)) {
        $parts.Add((Get-AxisFirstUseWizardInlineText -Inline $inline))
    }

    return ($parts -join '')
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
        elseif ($Node -is [System.Windows.Controls.TextBlock]) {
            $text = Get-AxisFirstUseWizardTextBlockPlainText -TextBlock $Node
            if (-not [string]::IsNullOrWhiteSpace($text)) {
                $values.Add($text)
            }
        }
    }

    return @($values)
}

function ConvertTo-AxisFirstUseWizardNormalizedText {
    param(
        [AllowNull()]
        [string]$Text
    )

    if ($null -eq $Text) {
        return ''
    }

    return [regex]::Replace($Text, '\s+', ' ').Trim()
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

function Get-AxisFirstUseWizardTextBlocksByText {
    param(
        [Parameter(Mandatory)]
        [object]$Root,

        [Parameter(Mandatory)]
        [string]$Text
    )

    return @(
        Get-AxisFirstUseWizardTypedElements -Root $Root -Type ([System.Windows.Controls.TextBlock]) |
            Where-Object { (Get-AxisFirstUseWizardTextBlockPlainText -TextBlock $_) -eq $Text }
    )
}

function Get-AxisFirstUseWizardTextBlocksContainingText {
    param(
        [Parameter(Mandatory)]
        [object]$Root,

        [Parameter(Mandatory)]
        [string]$Text
    )

    return @(
        Get-AxisFirstUseWizardTypedElements -Root $Root -Type ([System.Windows.Controls.TextBlock]) |
            Where-Object { (Get-AxisFirstUseWizardTextBlockPlainText -TextBlock $_).Contains($Text) }
    )
}

function Get-AxisFirstUseWizardSolidBrushHex {
    param(
        [AllowNull()]
        [object]$Brush
    )

    if ($Brush -is [System.Windows.Media.SolidColorBrush]) {
        return [string]([System.Windows.Media.SolidColorBrush]$Brush).Color
    }

    return ''
}

function Assert-AxisFirstUseWizardForegroundColor {
    param(
        [Parameter(Mandatory)]
        [object]$Element,

        [Parameter(Mandatory)]
        [string]$ExpectedColor,

        [Parameter(Mandatory)]
        [string]$Name
    )

    Assert-BoostLabCondition ($Element -is [System.Windows.Controls.Control] -or $Element -is [System.Windows.Controls.TextBlock]) "AXIS $Name should expose a foreground property."
    Assert-BoostLabCondition (
        (Get-AxisFirstUseWizardSolidBrushHex -Brush $Element.Foreground) -eq $ExpectedColor
    ) "AXIS $Name foreground should use $ExpectedColor."
}

function Assert-AxisFirstUseWizardForegroundNotColor {
    param(
        [Parameter(Mandatory)]
        [object]$Element,

        [Parameter(Mandatory)]
        [string]$RejectedColor,

        [Parameter(Mandatory)]
        [string]$Name
    )

    Assert-BoostLabCondition ($Element -is [System.Windows.Controls.Control] -or $Element -is [System.Windows.Controls.TextBlock]) "AXIS $Name should expose a foreground property."
    Assert-BoostLabCondition (
        (Get-AxisFirstUseWizardSolidBrushHex -Brush $Element.Foreground) -ne $RejectedColor
    ) "AXIS $Name foreground should not use rejected color $RejectedColor."
}

function Invoke-AxisFirstUseWizardButtonClick {
    param(
        [Parameter(Mandatory)]
        [System.Windows.Controls.Button]$Button
    )

    $Button.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, $Button))
}

function Wait-AxisFirstUseWizardCondition {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Condition,

        [int]$TimeoutMilliseconds = 2500
    )

    $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMilliseconds)
    while ([DateTime]::UtcNow -lt $deadline) {
        if ([bool](& $Condition)) {
            return $true
        }

        $frame = [System.Windows.Threading.DispatcherFrame]::new()
        $timer = [System.Windows.Threading.DispatcherTimer]::new()
        $timer.Interval = [TimeSpan]::FromMilliseconds(25)
        $timer.Add_Tick({
            $timer.Stop()
            $frame.Continue = $false
        }.GetNewClosure())
        $timer.Start()
        [System.Windows.Threading.Dispatcher]::PushFrame($frame)
    }

    return [bool](& $Condition)
}

function Assert-AxisFirstUseWizardRightAnchor {
    param(
        [Parameter(Mandatory)]
        [object]$Anchor,

        [Parameter(Mandatory)]
        [string]$Name,

        [double]$ExpectedMaxWidth = 0.0
    )

    Assert-BoostLabCondition ($Anchor -is [System.Windows.Controls.Grid]) "AXIS $Name right anchor should be a full-width positioning Grid."
    Assert-BoostLabCondition ($Anchor.FlowDirection -eq [System.Windows.FlowDirection]::LeftToRight) "AXIS $Name right anchor should use physical LTR positioning."
    Assert-BoostLabCondition ($Anchor.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Stretch) "AXIS $Name right anchor should span the available region."
    Assert-BoostLabCondition ($Anchor.Children.Count -eq 1) "AXIS $Name right anchor should contain one right-aligned Arabic group."
    $child = $Anchor.Children[0]
    Assert-BoostLabCondition ($child -is [System.Windows.FrameworkElement]) "AXIS $Name right anchor child should be a FrameworkElement."
    Assert-BoostLabCondition ($child.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) "AXIS $Name Arabic group should be physically anchored to the right."
    Assert-BoostLabCondition ($child.FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) "AXIS $Name Arabic group should use RTL flow."
    if ($ExpectedMaxWidth -gt 0.0) {
        Assert-BoostLabCondition ([double]$child.MaxWidth -eq $ExpectedMaxWidth) "AXIS $Name Arabic group should use the expected max width."
    }

    return $child
}

function Assert-AxisFirstUseWizardSelectorPhysicalLeftAboveRequirements {
    param(
        [Parameter(Mandatory)]
        [object]$Row,

        [Parameter(Mandatory)]
        [object]$Selector,

        [Parameter(Mandatory)]
        [object]$Label,

        [Parameter(Mandatory)]
        [object]$ContentGrid,

        [Parameter(Mandatory)]
        [object]$DetailsGrid,

        [Parameter(Mandatory)]
        [string]$Name
    )

    Assert-BoostLabCondition ($Row -is [System.Windows.Controls.Grid]) "AXIS $Name selector row should be a physical placement Grid."
    Assert-BoostLabCondition ([bool]$Row.Resources['AxisFirstUseWizard.SelectorPhysicalLeftAboveRequirements']) "AXIS $Name selector row should expose the physical-left above-requirements marker."
    Assert-BoostLabCondition ([bool]$Row.Resources['AxisFirstUseWizard.SelectorLabelPhysicalRightOfControl']) "AXIS $Name selector row should expose the label-right-of-control marker."
    Assert-BoostLabCondition ($Row.FlowDirection -eq [System.Windows.FlowDirection]::LeftToRight) "AXIS $Name selector row should use physical LTR placement."
    Assert-BoostLabCondition ($Row.ColumnDefinitions.Count -eq 3) "AXIS $Name selector row should use control, label, and fill columns."
    Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($Selector) -eq 0) "AXIS $Name selector control should sit on the physical left."
    Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($Label) -eq 1) "AXIS $Name selector label should sit to the physical right of the control."
    Assert-BoostLabCondition ($Selector.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Left) "AXIS $Name selector control should be left-aligned inside its physical-left column."
    Assert-BoostLabCondition ([double]$Label.Margin.Left -ge 10.0 -and [double]$Label.Margin.Right -eq 0.0) "AXIS $Name selector label should keep a clean gap to the right of the selector."
    Assert-BoostLabCondition ($ContentGrid.Children.IndexOf($Row) -ge 0) "AXIS $Name selector row should be in the main step content."
    Assert-BoostLabCondition ($ContentGrid.Children.IndexOf($Row) -lt $ContentGrid.Children.IndexOf($DetailsGrid)) "AXIS $Name selector row should appear above the requirements card row."
}

function Assert-AxisFirstUseWizardStageLineState {
    param(
        [Parameter(Mandatory)]
        [object]$Fill,

        [Parameter(Mandatory)]
        [string]$ExpectedAutomationId,

        [Parameter(Mandatory)]
        [string]$ExpectedColor,

        [Parameter(Mandatory)]
        [string]$Name
    )

    Assert-BoostLabCondition ($Fill -is [System.Windows.Controls.Border]) "AXIS $Name stage line should be a Border."
    Assert-BoostLabCondition ([double]$Fill.Width -eq 104.0) "AXIS $Name stage line should use the full-line width."
    Assert-BoostLabCondition (
        [System.Windows.Automation.AutomationProperties]::GetAutomationId($Fill) -eq $ExpectedAutomationId
    ) "AXIS $Name stage line state marker changed."
    Assert-BoostLabCondition ($Fill.Background -is [System.Windows.Media.SolidColorBrush]) "AXIS $Name stage line should use a solid brush."
    Assert-BoostLabCondition (
        [string]([System.Windows.Media.SolidColorBrush]$Fill.Background).Color -eq $ExpectedColor
    ) "AXIS $Name stage line color changed."
}

function Assert-AxisFirstUseWizardNextDisabledNonBlue {
    param(
        [Parameter(Mandatory)]
        [System.Windows.Controls.Button]$Button,

        [Parameter(Mandatory)]
        [string]$Name
    )

    Assert-BoostLabCondition (-not [bool]$Button.IsEnabled) "AXIS $Name Next should be disabled before simulated completion."
    Assert-BoostLabCondition (
        [System.Windows.Automation.AutomationProperties]::GetAutomationId($Button) -ne 'AxisFirstUseWizard.EnabledNextButtonBlue'
    ) "AXIS $Name disabled Next should not expose the enabled blue marker."
    Assert-BoostLabCondition (
        (Get-AxisFirstUseWizardSolidBrushHex -Brush $Button.Background) -ne '#FF2563EB'
    ) "AXIS $Name disabled Next should not use the enabled blue fill."
    Assert-BoostLabCondition (
        (Get-AxisFirstUseWizardSolidBrushHex -Brush $Button.BorderBrush) -ne '#FF60A5FA'
    ) "AXIS $Name disabled Next should not use the enabled blue border."
    Assert-BoostLabCondition ($null -eq $Button.Effect) "AXIS $Name disabled Next should not keep the enabled shadow effect."
    Assert-BoostLabCondition (
        [string]$Button.Resources['AxisFirstUseWizard.EnabledNextButtonHoverReadable'] -ne 'BlueHoverKeepsReadableText'
    ) "AXIS $Name disabled Next should not keep the enabled hover readability marker."
    Assert-BoostLabCondition (
        (Get-AxisFirstUseWizardSolidBrushHex -Brush $Button.Resources['AxisFirstUseWizard.ButtonHoverBackground']) -ne '#FF1D4ED8'
    ) "AXIS $Name disabled Next should not keep the enabled blue hover fill."
    Assert-BoostLabCondition (
        (Get-AxisFirstUseWizardSolidBrushHex -Brush $Button.Resources['AxisFirstUseWizard.ButtonHoverBorder']) -ne '#FF93C5FD'
    ) "AXIS $Name disabled Next should not keep the enabled blue hover border."
}

function Assert-AxisFirstUseWizardSharedPhysicalRightEdgeGroup {
    param(
        [Parameter(Mandatory)]
        [object]$Group,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string[]]$ExpectedTexts,

        [double]$ExpectedMaxWidth = 0.0
    )

    Assert-BoostLabCondition ($Group -is [System.Windows.Controls.Grid]) "AXIS $Name should use a deterministic physical right-edge Grid."
    Assert-BoostLabCondition ($Group.FlowDirection -eq [System.Windows.FlowDirection]::LeftToRight) "AXIS $Name physical right-edge group should use LTR physical placement."
    Assert-BoostLabCondition ($Group.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) "AXIS $Name physical right-edge group should be right-anchored."
    Assert-BoostLabCondition ([double]::IsNaN([double]$Group.Width)) "AXIS $Name physical right-edge group must not use a fixed width."
    if ($ExpectedMaxWidth -gt 0.0) {
        Assert-BoostLabCondition ([double]$Group.MaxWidth -eq $ExpectedMaxWidth) "AXIS $Name physical right-edge group should keep the expected max width."
    }

    Assert-BoostLabCondition ($Group.ColumnDefinitions.Count -eq 1) "AXIS $Name physical right-edge group should use one shared right column."
    Assert-BoostLabCondition ($Group.ColumnDefinitions[0].Width.GridUnitType -eq [System.Windows.GridUnitType]::Auto) "AXIS $Name shared right column should be auto-sized."

    $lineTextBlocks = @(Get-AxisFirstUseWizardTypedElements -Root $Group -Type ([System.Windows.Controls.TextBlock]))
    Assert-BoostLabCondition ($lineTextBlocks.Count -eq $ExpectedTexts.Count) "AXIS $Name should expose the expected number of physical right-edge lines."

    for ($index = 0; $index -lt $ExpectedTexts.Count; $index++) {
        $textBlock = $lineTextBlocks[$index]
        Assert-BoostLabCondition (@($Group.Children) -contains $textBlock) "AXIS $Name line $index should be a direct child of the shared physical right-edge group."
        Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($textBlock) -eq 0) "AXIS $Name line $index should use the shared right-edge column."
        Assert-BoostLabCondition ($textBlock.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) "AXIS $Name line $index should be physically right-aligned."
        Assert-BoostLabCondition ($textBlock.TextAlignment -eq [System.Windows.TextAlignment]::Right) "AXIS $Name line $index should keep right text alignment."
        Assert-BoostLabCondition ($textBlock.FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) "AXIS $Name line $index should keep RTL text flow."
        Assert-BoostLabCondition ([double]$textBlock.Margin.Right -eq 0.0) "AXIS $Name line $index should share the same zero right margin."
        Assert-BoostLabCondition ([string](Get-AxisFirstUseWizardTextBlockPlainText -TextBlock $textBlock) -eq $ExpectedTexts[$index]) "AXIS $Name line $index text changed."
    }

    return @($lineTextBlocks)
}

$prototypePath = Join-Path $ProjectRoot 'ui\AxisFirstUseWizardPrototype.ps1'
$resourcePath = Join-Path $ProjectRoot 'ui\AxisResources.ps1'
$mainWindowPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$stageConfigPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$blueprintPath = Join-Path $ProjectRoot 'docs\design\steps\BIOS-Information-Step-Blueprint.md'
$biosSettingsBlueprintPath = Join-Path $ProjectRoot 'docs\design\steps\BIOS-Settings-Step-Blueprint.md'
$reinstallBlueprintPath = Join-Path $ProjectRoot 'docs\design\steps\Reinstall-Step-Blueprint.md'
$autoUnattendBlueprintPath = Join-Path $ProjectRoot 'docs\design\steps\AutoUnattend-Step-Blueprint.md'
$updatesDriversBlueprintPath = Join-Path $ProjectRoot 'docs\design\steps\Updates-Drivers-Block-Step-Blueprint.md'
$toBiosBlueprintPath = Join-Path $ProjectRoot 'docs\design\steps\To-BIOS-Step-Blueprint.md'
$installersBlueprintPath = Join-Path $ProjectRoot 'docs\design\steps\Installers-Step-Blueprint.md'
$installersStartupAppsSettingsBlueprintPath = Join-Path $ProjectRoot 'docs\design\steps\Installers-Startup-Apps-Settings-Step-Blueprint.md'
$installersStartupAppsTaskManagerBlueprintPath = Join-Path $ProjectRoot 'docs\design\steps\Installers-Startup-Apps-Task-Manager-Step-Blueprint.md'
$restartAfterInstallersBlueprintPath = Join-Path $ProjectRoot 'docs\design\steps\Restart-After-Installers-Step-Blueprint.md'
$edgeWebViewBlueprintPath = Join-Path $ProjectRoot 'docs\design\steps\Edge-WebView-Step-Blueprint.md'
$timerResolutionAssistantBlueprintPath = Join-Path $ProjectRoot 'docs\design\steps\Timer-Resolution-Assistant-Step-Blueprint.md'
$defenderOptimizeAssistantBlueprintPath = Join-Path $ProjectRoot 'docs\design\steps\Defender-Optimize-Assistant-Step-Blueprint.md'
$graphicsBlueprintPaths = @(
    Join-Path $ProjectRoot 'docs\design\steps\Driver-Clean-Step-Blueprint.md'
    Join-Path $ProjectRoot 'docs\design\steps\Driver-Install-Debloat-Settings-Step-Blueprint.md'
    Join-Path $ProjectRoot 'docs\design\steps\NVIDIA-App-Install-Step-Blueprint.md'
    Join-Path $ProjectRoot 'docs\design\steps\DirectX-Step-Blueprint.md'
    Join-Path $ProjectRoot 'docs\design\steps\Visual-Cpp-Step-Blueprint.md'
    Join-Path $ProjectRoot 'docs\design\steps\Graphics-Configuration-Center-Step-Blueprint.md'
)
$setupBlueprintPaths = @(
    Join-Path $ProjectRoot 'docs\design\steps\BitLocker-Step-Blueprint.md'
    Join-Path $ProjectRoot 'docs\design\steps\Convert-Home-To-Pro-Step-Blueprint.md'
    Join-Path $ProjectRoot 'docs\design\steps\Memory-Compression-Step-Blueprint.md'
    Join-Path $ProjectRoot 'docs\design\steps\Date-Language-Region-Time-Step-Blueprint.md'
    Join-Path $ProjectRoot 'docs\design\steps\Startup-Apps-Settings-Step-Blueprint.md'
    Join-Path $ProjectRoot 'docs\design\steps\Startup-Apps-Task-Manager-Step-Blueprint.md'
    Join-Path $ProjectRoot 'docs\design\steps\Background-Apps-Step-Blueprint.md'
    Join-Path $ProjectRoot 'docs\design\steps\Edge-Settings-Step-Blueprint.md'
    Join-Path $ProjectRoot 'docs\design\steps\Store-Settings-Step-Blueprint.md'
    Join-Path $ProjectRoot 'docs\design\steps\Updates-Pause-Step-Blueprint.md'
)

Assert-BoostLabCondition (Test-Path -LiteralPath $prototypePath -PathType Leaf) 'AXIS first-use wizard prototype file is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $resourcePath -PathType Leaf) 'AXIS WPF resources file is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $blueprintPath -PathType Leaf) 'AXIS BIOS Information step blueprint is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $biosSettingsBlueprintPath -PathType Leaf) 'AXIS BIOS Settings step blueprint is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $reinstallBlueprintPath -PathType Leaf) 'AXIS Reinstall step blueprint is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $autoUnattendBlueprintPath -PathType Leaf) 'AXIS AutoUnattend step blueprint is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $updatesDriversBlueprintPath -PathType Leaf) 'AXIS Updates Drivers Block step blueprint is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $toBiosBlueprintPath -PathType Leaf) 'AXIS To BIOS step blueprint is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $installersBlueprintPath -PathType Leaf) 'AXIS Installers step blueprint is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $installersStartupAppsSettingsBlueprintPath -PathType Leaf) 'AXIS Installers Startup Apps Settings extension blueprint is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $installersStartupAppsTaskManagerBlueprintPath -PathType Leaf) 'AXIS Installers Startup Apps Task Manager extension blueprint is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $restartAfterInstallersBlueprintPath -PathType Leaf) 'AXIS Restart After Installers extension blueprint is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $edgeWebViewBlueprintPath -PathType Leaf) 'AXIS Edge WebView step blueprint is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $timerResolutionAssistantBlueprintPath -PathType Leaf) 'AXIS Timer Resolution Assistant step blueprint is missing.'
Assert-BoostLabCondition (Test-Path -LiteralPath $defenderOptimizeAssistantBlueprintPath -PathType Leaf) 'AXIS Defender Optimize Assistant step blueprint is missing.'
foreach ($graphicsBlueprintPath in $graphicsBlueprintPaths) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $graphicsBlueprintPath -PathType Leaf) "AXIS Graphics step blueprint is missing: $graphicsBlueprintPath"
}
foreach ($setupBlueprintPath in $setupBlueprintPaths) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $setupBlueprintPath -PathType Leaf) "AXIS Setup step blueprint is missing: $setupBlueprintPath"
}

$prototypeSource = Get-Content -Raw -LiteralPath $prototypePath
$blueprintSource = Get-Content -Raw -LiteralPath $blueprintPath
$biosSettingsBlueprintSource = Get-Content -Raw -Encoding UTF8 -LiteralPath $biosSettingsBlueprintPath
$reinstallBlueprintSource = Get-Content -Raw -Encoding UTF8 -LiteralPath $reinstallBlueprintPath
$autoUnattendBlueprintSource = Get-Content -Raw -Encoding UTF8 -LiteralPath $autoUnattendBlueprintPath
$updatesDriversBlueprintSource = Get-Content -Raw -Encoding UTF8 -LiteralPath $updatesDriversBlueprintPath
$toBiosBlueprintSource = Get-Content -Raw -Encoding UTF8 -LiteralPath $toBiosBlueprintPath
$installersBlueprintSource = Get-Content -Raw -Encoding UTF8 -LiteralPath $installersBlueprintPath
$installersStartupAppsSettingsBlueprintSource = Get-Content -Raw -Encoding UTF8 -LiteralPath $installersStartupAppsSettingsBlueprintPath
$installersStartupAppsTaskManagerBlueprintSource = Get-Content -Raw -Encoding UTF8 -LiteralPath $installersStartupAppsTaskManagerBlueprintPath
$restartAfterInstallersBlueprintSource = Get-Content -Raw -Encoding UTF8 -LiteralPath $restartAfterInstallersBlueprintPath
$edgeWebViewBlueprintSource = Get-Content -Raw -Encoding UTF8 -LiteralPath $edgeWebViewBlueprintPath
$timerResolutionAssistantBlueprintSource = Get-Content -Raw -Encoding UTF8 -LiteralPath $timerResolutionAssistantBlueprintPath
$defenderOptimizeAssistantBlueprintSource = Get-Content -Raw -Encoding UTF8 -LiteralPath $defenderOptimizeAssistantBlueprintPath
. $prototypePath

foreach ($functionName in @(
    'Get-AxisFirstUseWizardSampleState'
    'Get-AxisFirstUseWizardInstallersCatalogNames'
    'Get-AxisWizardArabicText'
    'Get-AxisWizardIntroFinalText'
    'Get-AxisWizardSetupText'
    'Get-AxisWizardGraphicsText'
    'Get-AxisWizardWindowsText'
    'Get-AxisWizardAdvancedText'
    'New-AxisFirstUseWizardPrototype'
    'New-AxisFirstUseWizardPrototypeWindow'
    'New-AxisStageProgressStrip'
    'New-AxisWizardStepContent'
    'New-AxisBiosInformationStep'
    'New-AxisBiosSettingsStep'
    'New-AxisReinstallStep'
    'New-AxisAutoUnattendStep'
    'New-AxisUpdatesDriversBlockStep'
    'New-AxisToBiosStep'
    'New-AxisSetupStep'
    'New-AxisInstallersStep'
    'Split-AxisInstallersEpicInstructionVisualLines'
    'New-AxisInstallersEpicInstructionBodyGroup'
    'New-AxisInstallersEpicInstructionOverlay'
    'New-AxisSetupPhysicalRightEdgeTextGroup'
    'New-AxisWizardMixedBidiTextBlock'
    'New-AxisWizardAxisTitleRightAnchor'
    'New-AxisWizardToBiosTitleRightAnchor'
    'Split-AxisAutoUnattendInformationText'
    'New-AxisAutoUnattendInformationTextGroup'
    'Split-AxisUpdatesDriversInformationText'
    'New-AxisUpdatesDriversInformationTextGroup'
    'Split-AxisToBiosInformationText'
    'New-AxisToBiosInformationTextGroup'
    'New-AxisAutoUnattendInputOverlay'
    'Get-AxisWizardSelectorComboBoxStyle'
    'New-AxisWizardSelectorComboBoxItemStyle'
    'Set-AxisWizardSelectorComboBoxStyle'
    'New-AxisWizardUsbComboBoxItemStyle'
    'New-AxisFirstUseWizardStepContent'
    'New-AxisIntroFinalWizardPage'
    'New-AxisStepDocumentationButton'
    'New-AxisStepPrimaryActionArea'
    'New-AxisStepStatusArea'
    'New-AxisStepSupportPanel'
    'New-AxisStepAcknowledgementOverlay'
    'New-AxisWizardRuntimeStatusEffect'
    'New-AxisWizardRuntimeStatusContent'
    'New-AxisWizardShadowEffect'
    'New-AxisWizardColorBrush'
    'New-AxisWizardSuccessGlowEffect'
    'Get-AxisWizardFilledSquareCheckboxStyle'
    'Set-AxisWizardEnabledNextButtonBlue'
    'New-AxisWizardSpacer'
    'New-AxisWizardRightAnchor'
    'Add-AxisWizardGridRow'
)) {
    Assert-BoostLabCondition (
        $null -ne (Get-Command -Name $functionName -CommandType Function -ErrorAction SilentlyContinue)
    ) "Required AXIS first-use wizard function is missing: $functionName"
}

$arabicOpen = Get-AxisWizardArabicText -Name 'Open'
$arabicSubtitle = Get-AxisWizardArabicText -Name 'Subtitle'
$arabicInfoTitle = Get-AxisWizardArabicText -Name 'InformationCardTitle'
$arabicNetworkDriver = Get-AxisWizardArabicText -Name 'NetworkDriver'
$arabicAudioDriver = Get-AxisWizardArabicText -Name 'AudioDriver'
$arabicDocumentation = Get-AxisWizardArabicText -Name 'Documentation'
$arabicBack = Get-AxisWizardArabicText -Name 'Back'
$arabicNext = Get-AxisWizardArabicText -Name 'Next'
$arabicReturn = Get-AxisWizardArabicText -Name 'Return'
$arabicAcknowledgement = Get-AxisWizardArabicText -Name 'Acknowledgement'
$arabicSupportTitle = Get-AxisWizardArabicText -Name 'SupportTitle'
$arabicSupportBody = Get-AxisWizardArabicText -Name 'SupportBody'
$arabicChecking = Get-AxisWizardArabicText -Name 'Checking'
$arabicCompleted = Get-AxisWizardArabicText -Name 'Completed'
$arabicRestart = Get-AxisWizardArabicText -Name 'Restart'
$axisIntroTitle = Get-AxisWizardIntroFinalText -Name 'IntroTitle'
$axisIntroSubtitle = Get-AxisWizardIntroFinalText -Name 'IntroSubtitle'
$axisIntroPrimary = Get-AxisWizardIntroFinalText -Name 'IntroPrimary'
$axisIntroInfoTitle = Get-AxisWizardIntroFinalText -Name 'IntroInfoTitle'
$axisIntroInfoBullet1 = Get-AxisWizardIntroFinalText -Name 'IntroInfoBullet1'
$axisIntroInfoBullet2 = Get-AxisWizardIntroFinalText -Name 'IntroInfoBullet2'
$axisIntroInfoBullet3 = Get-AxisWizardIntroFinalText -Name 'IntroInfoBullet3'
$axisFinalTitle = Get-AxisWizardIntroFinalText -Name 'FinalTitle'
$axisFinalSubtitle = Get-AxisWizardIntroFinalText -Name 'FinalSubtitle'
$axisFinalButton = Get-AxisWizardIntroFinalText -Name 'FinalButton'
$axisFinalInfoTitle = Get-AxisWizardIntroFinalText -Name 'FinalInfoTitle'
$axisFinalInfoBullet1 = Get-AxisWizardIntroFinalText -Name 'FinalInfoBullet1'
$axisFinalInfoBullet2 = Get-AxisWizardIntroFinalText -Name 'FinalInfoBullet2'
$axisFinalInfoBullet3 = Get-AxisWizardIntroFinalText -Name 'FinalInfoBullet3'
$arabicBiosSettingsSubtitle = Get-AxisWizardArabicText -Name 'BiosSettingsSubtitle'
$arabicBiosSettingsInfoTitle = Get-AxisWizardArabicText -Name 'BiosSettingsInfoTitle'
$arabicBiosSettingsInfoIntro = Get-AxisWizardArabicText -Name 'BiosSettingsInfoIntro'
$arabicIntelTitle = Get-AxisWizardArabicText -Name 'IntelTitle'
$arabicIntelRam = Get-AxisWizardArabicText -Name 'IntelRam'
$arabicIntelCStates = Get-AxisWizardArabicText -Name 'IntelCStates'
$arabicIntelRebar = Get-AxisWizardArabicText -Name 'IntelRebar'
$arabicIntelIgpu = Get-AxisWizardArabicText -Name 'IntelIgpu'
$arabicAmdTitle = Get-AxisWizardArabicText -Name 'AmdTitle'
$arabicAmdRam = Get-AxisWizardArabicText -Name 'AmdRam'
$arabicAmdPbo = Get-AxisWizardArabicText -Name 'AmdPbo'
$arabicAmdRebar = Get-AxisWizardArabicText -Name 'AmdRebar'
$arabicAmdIgpu = Get-AxisWizardArabicText -Name 'AmdIgpu'
$arabicMotherboardTitle = Get-AxisWizardArabicText -Name 'MotherboardTitle'
$arabicMotherboardIntro = Get-AxisWizardArabicText -Name 'MotherboardIntro'
$arabicAsusUtility = Get-AxisWizardArabicText -Name 'AsusUtility'
$arabicMsiUtility = Get-AxisWizardArabicText -Name 'MsiUtility'
$arabicGigabyteUtility = Get-AxisWizardArabicText -Name 'GigabyteUtility'
$arabicAsrockUtility = Get-AxisWizardArabicText -Name 'AsrockUtility'
$arabicRequirementsTitle = Get-AxisWizardArabicText -Name 'RequirementsTitle'
$arabicReqNavigation = Get-AxisWizardArabicText -Name 'ReqNavigation'
$arabicReqSupport = Get-AxisWizardArabicText -Name 'ReqSupport'
$arabicRestartAcknowledgement = Get-AxisWizardArabicText -Name 'RestartAcknowledgement'
$arabicRestarting = Get-AxisWizardArabicText -Name 'Restarting'
$arabicReinstallTitle = Get-AxisWizardArabicText -Name 'ReinstallTitle'
$arabicReinstallSubtitle = Get-AxisWizardArabicText -Name 'ReinstallSubtitle'
$arabicReinstallInfoTitle = Get-AxisWizardArabicText -Name 'ReinstallInfoTitle'
$arabicReinstallInfoBullet = Get-AxisWizardArabicText -Name 'ReinstallInfoBullet'
$arabicReinstallRequirementUsbSize = Get-AxisWizardArabicText -Name 'ReinstallRequirementUsbSize'
$arabicReinstallRequirementNoData = Get-AxisWizardArabicText -Name 'ReinstallRequirementNoData'
$arabicReinstallPrimaryAction = Get-AxisWizardArabicText -Name 'ReinstallPrimaryAction'
$arabicReinstallRunning = Get-AxisWizardArabicText -Name 'ReinstallRunning'
$arabicReinstallCompleted = Get-AxisWizardArabicText -Name 'ReinstallCompleted'
$arabicAutoUnattendSubtitle = Get-AxisWizardArabicText -Name 'AutoUnattendSubtitle'
$arabicAutoUnattendInfoTitle = Get-AxisWizardArabicText -Name 'AutoUnattendInfoTitle'
$arabicAutoUnattendInfoBulletOobe = Get-AxisWizardArabicText -Name 'AutoUnattendInfoBulletOobe'
$arabicAutoUnattendInfoBulletSetup = Get-AxisWizardArabicText -Name 'AutoUnattendInfoBulletSetup'
$arabicAutoUnattendInfoBulletUsb = Get-AxisWizardArabicText -Name 'AutoUnattendInfoBulletUsb'
$arabicAutoUnattendRequirementAccount = Get-AxisWizardArabicText -Name 'AutoUnattendRequirementAccount'
$arabicAutoUnattendRequirementUsb = Get-AxisWizardArabicText -Name 'AutoUnattendRequirementUsb'
$arabicAutoUnattendPrimaryAction = Get-AxisWizardArabicText -Name 'AutoUnattendPrimaryAction'
$arabicAutoUnattendInputTitle = Get-AxisWizardArabicText -Name 'AutoUnattendInputTitle'
$arabicAutoUnattendAccountLabel = Get-AxisWizardArabicText -Name 'AutoUnattendAccountLabel'
$arabicAutoUnattendUsbLabel = Get-AxisWizardArabicText -Name 'AutoUnattendUsbLabel'
$arabicAutoUnattendRunning = Get-AxisWizardArabicText -Name 'AutoUnattendRunning'
$arabicAutoUnattendCompleted = Get-AxisWizardArabicText -Name 'AutoUnattendCompleted'
$arabicUpdatesDriversSubtitle = Get-AxisWizardArabicText -Name 'UpdatesDriversSubtitle'
$arabicUpdatesDriversInfoTitle = Get-AxisWizardArabicText -Name 'UpdatesDriversInfoTitle'
$arabicUpdatesDriversInfoBulletSetupcomplete = Get-AxisWizardArabicText -Name 'UpdatesDriversInfoBulletSetupcomplete'
$arabicUpdatesDriversInfoBulletWindowsUpdate = Get-AxisWizardArabicText -Name 'UpdatesDriversInfoBulletWindowsUpdate'
$arabicUpdatesDriversRequirementUsb = Get-AxisWizardArabicText -Name 'UpdatesDriversRequirementUsb'
$arabicUpdatesDriversPrimaryAction = Get-AxisWizardArabicText -Name 'UpdatesDriversPrimaryAction'
$arabicUpdatesDriversInputTitle = Get-AxisWizardArabicText -Name 'UpdatesDriversInputTitle'
$arabicUpdatesDriversUsbLabel = Get-AxisWizardArabicText -Name 'UpdatesDriversUsbLabel'
$arabicUpdatesDriversInputCreate = Get-AxisWizardArabicText -Name 'UpdatesDriversInputCreate'
$arabicUpdatesDriversRunning = Get-AxisWizardArabicText -Name 'UpdatesDriversRunning'
$arabicUpdatesDriversCompleted = Get-AxisWizardArabicText -Name 'UpdatesDriversCompleted'
$arabicToBiosTitle = Get-AxisWizardArabicText -Name 'ToBiosTitle'
$arabicToBiosSubtitle = Get-AxisWizardArabicText -Name 'ToBiosSubtitle'
$arabicToBiosInfoTitle = Get-AxisWizardArabicText -Name 'ToBiosInfoTitle'
$arabicToBiosInfoBulletRestart = Get-AxisWizardArabicText -Name 'ToBiosInfoBulletRestart'
$arabicToBiosInfoBulletUsbBoot = Get-AxisWizardArabicText -Name 'ToBiosInfoBulletUsbBoot'
$arabicToBiosInfoBulletInstall = Get-AxisWizardArabicText -Name 'ToBiosInfoBulletInstall'
$arabicToBiosPrimaryAction = Get-AxisWizardArabicText -Name 'ToBiosPrimaryAction'
$arabicInstallersTitle = Get-AxisWizardArabicText -Name 'InstallersTitle'
$arabicInstallersSubtitle = Get-AxisWizardArabicText -Name 'InstallersSubtitle'
$arabicInstallersSelectorLabel = Get-AxisWizardArabicText -Name 'InstallersSelectorLabel'
$arabicInstallersSelectorPlaceholder = Get-AxisWizardArabicText -Name 'InstallersSelectorPlaceholder'
$arabicInstallersInfoTitle = Get-AxisWizardArabicText -Name 'InstallersInfoTitle'
$arabicInstallersInfoBullet1 = Get-AxisWizardArabicText -Name 'InstallersInfoBullet1'
$arabicInstallersInfoBullet2 = Get-AxisWizardArabicText -Name 'InstallersInfoBullet2'
$arabicInstallersInfoBullet3 = Get-AxisWizardArabicText -Name 'InstallersInfoBullet3'
$arabicInstallersRequirement1 = Get-AxisWizardArabicText -Name 'InstallersRequirementsBullet1'
$arabicInstallersRequirement2 = Get-AxisWizardArabicText -Name 'InstallersRequirementsBullet2'
$arabicInstallersRunning = Get-AxisWizardArabicText -Name 'InstallersRunning'
$arabicInstallersCompleted = Get-AxisWizardArabicText -Name 'InstallersCompleted'
$arabicInstallersSelectedProgramPrefix = Get-AxisWizardArabicText -Name 'InstallersSelectedProgramPrefix'
$arabicInstallersEpicOverlayTitle = Get-AxisWizardArabicText -Name 'InstallersEpicOverlayTitle'
$arabicInstallersEpicOverlayBody1 = Get-AxisWizardArabicText -Name 'InstallersEpicOverlayBody1'
$arabicInstallersEpicOverlayBody2 = Get-AxisWizardArabicText -Name 'InstallersEpicOverlayBody2'
$arabicInstallersEpicOverlayBody3 = Get-AxisWizardArabicText -Name 'InstallersEpicOverlayBody3'
$arabicInstallersEpicOverlayReturn = Get-AxisWizardArabicText -Name 'InstallersEpicOverlayReturn'
$arabicRestartAfterInstallersTitle = Get-AxisWizardArabicText -Name 'RestartAfterInstallersTitle'
$arabicRestartAfterInstallersSubtitle = Get-AxisWizardArabicText -Name 'RestartAfterInstallersSubtitle'
$arabicRestartAfterInstallersInfoBullet1 = Get-AxisWizardArabicText -Name 'RestartAfterInstallersInfoBullet1'
$arabicRestartAfterInstallersInfoBullet2 = Get-AxisWizardArabicText -Name 'RestartAfterInstallersInfoBullet2'
$arabicRestartAfterInstallersInfoBullet3 = Get-AxisWizardArabicText -Name 'RestartAfterInstallersInfoBullet3'
$graphicsDriverCleanTitle = Get-AxisWizardGraphicsText -Name 'DriverCleanTitle'
$graphicsDriverCleanSubtitle = Get-AxisWizardGraphicsText -Name 'DriverCleanSubtitle'
$graphicsDriverCleanPrimary = Get-AxisWizardGraphicsText -Name 'DriverCleanPrimary'
$graphicsDriverCleanInfoTitle = Get-AxisWizardGraphicsText -Name 'DriverCleanInfoTitle'
$graphicsDriverCleanInfoBullet1 = Get-AxisWizardGraphicsText -Name 'DriverCleanInfoBullet1'
$graphicsDriverCleanInfoBullet2 = Get-AxisWizardGraphicsText -Name 'DriverCleanInfoBullet2'
$graphicsDriverCleanInfoBullet3 = Get-AxisWizardGraphicsText -Name 'DriverCleanInfoBullet3'
$graphicsDriverCleanShortInfoBullet1 = ConvertFrom-AxisWizardCodePoints @(0x062A, 0x0646, 0x0638, 0x064A, 0x0641, 0x0020, 0x062A, 0x0639, 0x0631, 0x064A, 0x0641, 0x0627, 0x062A, 0x0020, 0x0643, 0x0631, 0x062A, 0x0020, 0x0627, 0x0644, 0x0634, 0x0627, 0x0634, 0x0629, 0x0020, 0x0627, 0x0644, 0x0642, 0x062F, 0x064A, 0x0645, 0x0629, 0x0020, 0x0642, 0x0628, 0x0644, 0x0020, 0x062A, 0x062B, 0x0628, 0x064A, 0x062A, 0x0020, 0x0627, 0x0644, 0x062A, 0x0639, 0x0631, 0x064A, 0x0641, 0x0020, 0x0627, 0x0644, 0x062C, 0x062F, 0x064A, 0x062F, 0x002E)
$graphicsDriverCleanShortInfoBullet2 = ConvertFrom-AxisWizardCodePoints @(0x064A, 0x062A, 0x0645, 0x0020, 0x062A, 0x0646, 0x0641, 0x064A, 0x0630, 0x0020, 0x062E, 0x0637, 0x0648, 0x0629, 0x0020, 0x0627, 0x0644, 0x062A, 0x0646, 0x0638, 0x064A, 0x0641, 0x0020, 0x062A, 0x0644, 0x0642, 0x0627, 0x0626, 0x064A, 0x064B, 0x0627, 0x0020, 0x062D, 0x0633, 0x0628, 0x0020, 0x0627, 0x0644, 0x0645, 0x0633, 0x0627, 0x0631, 0x0020, 0x0627, 0x0644, 0x0645, 0x0639, 0x062A, 0x0645, 0x062F, 0x002E)
$graphicsDriverCleanShortInfoBullet3 = ConvertFrom-AxisWizardCodePoints @(0x0628, 0x0639, 0x062F, 0x0020, 0x0627, 0x0643, 0x062A, 0x0645, 0x0627, 0x0644, 0x0020, 0x0627, 0x0644, 0x062A, 0x0646, 0x0638, 0x064A, 0x0641, 0x060C, 0x0020, 0x064A, 0x0645, 0x0643, 0x0646, 0x0643, 0x0020, 0x0645, 0x062A, 0x0627, 0x0628, 0x0639, 0x0629, 0x0020, 0x0625, 0x0639, 0x062F, 0x0627, 0x062F, 0x0020, 0x0627, 0x0644, 0x062A, 0x0639, 0x0631, 0x064A, 0x0641, 0x0020, 0x0627, 0x0644, 0x062C, 0x062F, 0x064A, 0x062F, 0x002E)
Assert-BoostLabCondition ($graphicsDriverCleanInfoBullet1 -eq $graphicsDriverCleanShortInfoBullet1) 'AXIS Driver Clean information bullet 1 should use the shortened owner-approved in-card copy.'
Assert-BoostLabCondition ($graphicsDriverCleanInfoBullet2 -eq $graphicsDriverCleanShortInfoBullet2) 'AXIS Driver Clean information bullet 2 should use the shortened owner-approved in-card copy.'
Assert-BoostLabCondition ($graphicsDriverCleanInfoBullet3 -eq $graphicsDriverCleanShortInfoBullet3) 'AXIS Driver Clean information bullet 3 should use the shortened owner-approved in-card copy.'
$graphicsDriverCleanRequirement1 = Get-AxisWizardGraphicsText -Name 'DriverCleanRequirement1'
$graphicsDriverCleanRequirement2 = Get-AxisWizardGraphicsText -Name 'DriverCleanRequirement2'
$graphicsDriverCleanRequirement3 = Get-AxisWizardGraphicsText -Name 'DriverCleanRequirement3'
$graphicsDriverCleanRunning = Get-AxisWizardGraphicsText -Name 'DriverCleanRunning'
$graphicsGpuSetupSelectorLabel = Get-AxisWizardGraphicsText -Name 'GpuSetupSelectorLabel'
$graphicsGpuSetupAmdLater = Get-AxisWizardGraphicsText -Name 'GpuSetupAmdLater'
$graphicsGpuSetupIntelLater = Get-AxisWizardGraphicsText -Name 'GpuSetupIntelLater'
$graphicsGpuSetupSubtitle = Get-AxisWizardGraphicsText -Name 'GpuSetupSubtitle'
$graphicsGpuSetupPrimary = Get-AxisWizardGraphicsText -Name 'GpuSetupPrimary'
$graphicsGpuSetupInfoTitle = Get-AxisWizardGraphicsText -Name 'GpuSetupInfoTitle'
$graphicsGpuSetupInfoBullet1 = Get-AxisWizardGraphicsText -Name 'GpuSetupInfoBullet1'
$graphicsGpuSetupInfoBullet2 = Get-AxisWizardGraphicsText -Name 'GpuSetupInfoBullet2'
$graphicsGpuSetupInfoBullet3 = Get-AxisWizardGraphicsText -Name 'GpuSetupInfoBullet3'
$graphicsGpuSetupRequirement1 = Get-AxisWizardGraphicsText -Name 'GpuSetupRequirement1'
$graphicsGpuSetupRequirement2 = Get-AxisWizardGraphicsText -Name 'GpuSetupRequirement2'
$graphicsGpuSetupRequirement3 = Get-AxisWizardGraphicsText -Name 'GpuSetupRequirement3'
$graphicsGpuSetupRunning = Get-AxisWizardGraphicsText -Name 'GpuSetupRunning'
$graphicsNvidiaAppSubtitle = Get-AxisWizardGraphicsText -Name 'NvidiaAppSubtitle'
$graphicsNvidiaAppOptionalContinuation = Get-AxisWizardGraphicsText -Name 'NvidiaAppOptionalContinuation'
$graphicsNvidiaAppInfoTitle = Get-AxisWizardGraphicsText -Name 'NvidiaAppInfoTitle'
$graphicsNvidiaAppInfoBullet1 = Get-AxisWizardGraphicsText -Name 'NvidiaAppInfoBullet1'
$graphicsNvidiaAppInfoBullet2 = Get-AxisWizardGraphicsText -Name 'NvidiaAppInfoBullet2'
$graphicsNvidiaAppInfoBullet3 = Get-AxisWizardGraphicsText -Name 'NvidiaAppInfoBullet3'
$graphicsNvidiaAppRunning = Get-AxisWizardGraphicsText -Name 'NvidiaAppRunning'
$graphicsNvidiaAppCompleted = Get-AxisWizardGraphicsText -Name 'NvidiaAppCompleted'
$graphicsDirectXSubtitle = Get-AxisWizardGraphicsText -Name 'DirectXSubtitle'
$graphicsDirectXPrimary = Get-AxisWizardGraphicsText -Name 'DirectXPrimary'
$graphicsDirectXInfoTitle = Get-AxisWizardGraphicsText -Name 'DirectXInfoTitle'
$graphicsDirectXInfoBullet1 = Get-AxisWizardGraphicsText -Name 'DirectXInfoBullet1'
$graphicsDirectXInfoBullet2 = Get-AxisWizardGraphicsText -Name 'DirectXInfoBullet2'
$graphicsDirectXInfoBullet3 = Get-AxisWizardGraphicsText -Name 'DirectXInfoBullet3'
$graphicsDirectXRunning = Get-AxisWizardGraphicsText -Name 'DirectXRunning'
$graphicsVisualCppSubtitle = Get-AxisWizardGraphicsText -Name 'VisualCppSubtitle'
$graphicsVisualCppPrimary = Get-AxisWizardGraphicsText -Name 'VisualCppPrimary'
$graphicsVisualCppInfoTitle = Get-AxisWizardGraphicsText -Name 'VisualCppInfoTitle'
$graphicsVisualCppInfoBullet1 = Get-AxisWizardGraphicsText -Name 'VisualCppInfoBullet1'
$graphicsVisualCppInfoBullet2 = Get-AxisWizardGraphicsText -Name 'VisualCppInfoBullet2'
$graphicsVisualCppInfoBullet3 = Get-AxisWizardGraphicsText -Name 'VisualCppInfoBullet3'
$graphicsConfigSubtitle = Get-AxisWizardGraphicsText -Name 'GraphicsConfigSubtitle'
$graphicsConfigPrimary = Get-AxisWizardGraphicsText -Name 'GraphicsConfigPrimary'
$graphicsConfigInfoTitle = Get-AxisWizardGraphicsText -Name 'GraphicsConfigInfoTitle'
$graphicsConfigInfoBullet1 = Get-AxisWizardGraphicsText -Name 'GraphicsConfigInfoBullet1'
$graphicsConfigInfoBullet2 = Get-AxisWizardGraphicsText -Name 'GraphicsConfigInfoBullet2'
$graphicsConfigInfoBullet3 = Get-AxisWizardGraphicsText -Name 'GraphicsConfigInfoBullet3'
$windowsStartMenuTaskbarSubtitle = Get-AxisWizardWindowsText -Name 'StartMenuTaskbarSubtitle'
$windowsStartMenuTaskbarInfoTitle = Get-AxisWizardWindowsText -Name 'StartMenuTaskbarInfoTitle'
$windowsStartMenuTaskbarInfoBullet1 = Get-AxisWizardWindowsText -Name 'StartMenuTaskbarInfoBullet1'
$windowsStartMenuTaskbarInfoBullet2 = Get-AxisWizardWindowsText -Name 'StartMenuTaskbarInfoBullet2'
$windowsStartMenuTaskbarInfoBullet3 = Get-AxisWizardWindowsText -Name 'StartMenuTaskbarInfoBullet3'
$windowsStartMenuLayoutSubtitle = Get-AxisWizardWindowsText -Name 'StartMenuLayoutSubtitle'
$windowsStartMenuLayoutInfoTitle = Get-AxisWizardWindowsText -Name 'StartMenuLayoutInfoTitle'
$windowsStartMenuLayoutInfoBullet1 = Get-AxisWizardWindowsText -Name 'StartMenuLayoutInfoBullet1'
$windowsStartMenuLayoutInfoBullet2 = Get-AxisWizardWindowsText -Name 'StartMenuLayoutInfoBullet2'
$windowsStartMenuLayoutInfoBullet3 = Get-AxisWizardWindowsText -Name 'StartMenuLayoutInfoBullet3'
$windowsContextMenuSubtitle = Get-AxisWizardWindowsText -Name 'ContextMenuSubtitle'
$windowsContextMenuInfoTitle = Get-AxisWizardWindowsText -Name 'ContextMenuInfoTitle'
$windowsContextMenuInfoBullet1 = Get-AxisWizardWindowsText -Name 'ContextMenuInfoBullet1'
$windowsContextMenuInfoBullet2 = Get-AxisWizardWindowsText -Name 'ContextMenuInfoBullet2'
$windowsContextMenuInfoBullet3 = Get-AxisWizardWindowsText -Name 'ContextMenuInfoBullet3'
$windowsThemeBlackSubtitle = Get-AxisWizardWindowsText -Name 'ThemeBlackSubtitle'
$windowsThemeBlackPrimary = Get-AxisWizardWindowsText -Name 'ThemeBlackPrimary'
$windowsThemeBlackInfoTitle = Get-AxisWizardWindowsText -Name 'ThemeBlackInfoTitle'
$windowsThemeBlackInfoBullet1 = Get-AxisWizardWindowsText -Name 'ThemeBlackInfoBullet1'
$windowsThemeBlackInfoBullet2 = Get-AxisWizardWindowsText -Name 'ThemeBlackInfoBullet2'
$windowsBlackLockScreenWallpaperSubtitle = Get-AxisWizardWindowsText -Name 'BlackLockScreenWallpaperSubtitle'
$windowsBlackLockScreenWallpaperPrimary = Get-AxisWizardWindowsText -Name 'BlackLockScreenWallpaperPrimary'
$windowsBlackLockScreenWallpaperInfoTitle = Get-AxisWizardWindowsText -Name 'BlackLockScreenWallpaperInfoTitle'
$windowsBlackLockScreenWallpaperInfoBullet1 = Get-AxisWizardWindowsText -Name 'BlackLockScreenWallpaperInfoBullet1'
$windowsBlackLockScreenWallpaperInfoBullet2 = Get-AxisWizardWindowsText -Name 'BlackLockScreenWallpaperInfoBullet2'
$windowsBlackAccountPicturesSubtitle = Get-AxisWizardWindowsText -Name 'BlackAccountPicturesSubtitle'
$windowsBlackAccountPicturesPrimary = Get-AxisWizardWindowsText -Name 'BlackAccountPicturesPrimary'
$windowsBlackAccountPicturesInfoTitle = Get-AxisWizardWindowsText -Name 'BlackAccountPicturesInfoTitle'
$windowsBlackAccountPicturesInfoBullet1 = Get-AxisWizardWindowsText -Name 'BlackAccountPicturesInfoBullet1'
$windowsBlackAccountPicturesInfoBullet2 = Get-AxisWizardWindowsText -Name 'BlackAccountPicturesInfoBullet2'
$windowsWidgetsSubtitle = Get-AxisWizardWindowsText -Name 'WidgetsSubtitle'
$windowsWidgetsPrimary = Get-AxisWizardWindowsText -Name 'WidgetsPrimary'
$windowsWidgetsInfoTitle = Get-AxisWizardWindowsText -Name 'WidgetsInfoTitle'
$windowsWidgetsInfoBullet1 = Get-AxisWizardWindowsText -Name 'WidgetsInfoBullet1'
$windowsWidgetsInfoBullet2 = Get-AxisWizardWindowsText -Name 'WidgetsInfoBullet2'
$windowsWidgetsInfoBullet3 = Get-AxisWizardWindowsText -Name 'WidgetsInfoBullet3'
$windowsCopilotSubtitle = Get-AxisWizardWindowsText -Name 'CopilotSubtitle'
$windowsCopilotPrimary = Get-AxisWizardWindowsText -Name 'CopilotPrimary'
$windowsCopilotInfoTitle = Get-AxisWizardWindowsText -Name 'CopilotInfoTitle'
$windowsCopilotInfoBullet1 = Get-AxisWizardWindowsText -Name 'CopilotInfoBullet1'
$windowsCopilotInfoBullet2 = Get-AxisWizardWindowsText -Name 'CopilotInfoBullet2'
$windowsCopilotInfoBullet3 = Get-AxisWizardWindowsText -Name 'CopilotInfoBullet3'
$windowsGameModeSubtitle = Get-AxisWizardWindowsText -Name 'GameModeSubtitle'
$windowsGameModePrimary = Get-AxisWizardWindowsText -Name 'GameModePrimary'
$windowsGameModeInfoTitle = Get-AxisWizardWindowsText -Name 'GameModeInfoTitle'
$windowsGameModeInfoBullet1 = Get-AxisWizardWindowsText -Name 'GameModeInfoBullet1'
$windowsGameModeInfoBullet2 = Get-AxisWizardWindowsText -Name 'GameModeInfoBullet2'
$windowsGameModeInfoBullet3 = Get-AxisWizardWindowsText -Name 'GameModeInfoBullet3'
$windowsGameModeRunning = Get-AxisWizardWindowsText -Name 'GameModeRunning'
$windowsPointerPrecisionSubtitle = Get-AxisWizardWindowsText -Name 'PointerPrecisionSubtitle'
$windowsPointerPrecisionPrimary = Get-AxisWizardWindowsText -Name 'PointerPrecisionPrimary'
$windowsPointerPrecisionInfoTitle = Get-AxisWizardWindowsText -Name 'PointerPrecisionInfoTitle'
$windowsPointerPrecisionInfoBullet1 = Get-AxisWizardWindowsText -Name 'PointerPrecisionInfoBullet1'
$windowsPointerPrecisionInfoBullet2 = Get-AxisWizardWindowsText -Name 'PointerPrecisionInfoBullet2'
$windowsPointerPrecisionInfoBullet3 = Get-AxisWizardWindowsText -Name 'PointerPrecisionInfoBullet3'
$windowsPointerPrecisionRunning = Get-AxisWizardWindowsText -Name 'PointerPrecisionRunning'
$windowsBloatwareSubtitle = Get-AxisWizardWindowsText -Name 'BloatwareSubtitle'
$windowsBloatwarePrimary = Get-AxisWizardWindowsText -Name 'BloatwarePrimary'
$windowsBloatwareInfoTitle = Get-AxisWizardWindowsText -Name 'BloatwareInfoTitle'
$windowsBloatwareInfoBullet1 = Get-AxisWizardWindowsText -Name 'BloatwareInfoBullet1'
$windowsBloatwareInfoBullet2 = Get-AxisWizardWindowsText -Name 'BloatwareInfoBullet2'
$windowsBloatwareInfoBullet3 = Get-AxisWizardWindowsText -Name 'BloatwareInfoBullet3'
$windowsBloatwareRequirement1 = Get-AxisWizardWindowsText -Name 'BloatwareRequirement1'
$windowsBloatwareRequirement2 = Get-AxisWizardWindowsText -Name 'BloatwareRequirement2'
$windowsBloatwareSelectorLabel = Get-AxisWizardWindowsText -Name 'BloatwareSelectorLabel'
$windowsBloatwareSelectorPlaceholder = Get-AxisWizardWindowsText -Name 'BloatwareSelectorPlaceholder'
$windowsGameBarSubtitle = Get-AxisWizardWindowsText -Name 'GameBarSubtitle'
$windowsGameBarPrimary = Get-AxisWizardWindowsText -Name 'GameBarPrimary'
$windowsGameBarInfoTitle = Get-AxisWizardWindowsText -Name 'GameBarInfoTitle'
$windowsGameBarInfoBullet1 = Get-AxisWizardWindowsText -Name 'GameBarInfoBullet1'
$windowsGameBarInfoBullet2 = Get-AxisWizardWindowsText -Name 'GameBarInfoBullet2'
$windowsGameBarInfoBullet3 = Get-AxisWizardWindowsText -Name 'GameBarInfoBullet3'
$windowsEdgeWebViewSubtitle = Get-AxisWizardWindowsText -Name 'EdgeWebViewSubtitle'
$windowsEdgeWebViewPrimary = Get-AxisWizardWindowsText -Name 'EdgeWebViewPrimary'
$windowsEdgeWebViewInfoTitle = Get-AxisWizardWindowsText -Name 'EdgeWebViewInfoTitle'
$windowsEdgeWebViewInfoBullet1 = Get-AxisWizardWindowsText -Name 'EdgeWebViewInfoBullet1'
$windowsEdgeWebViewInfoBullet2 = Get-AxisWizardWindowsText -Name 'EdgeWebViewInfoBullet2'
$windowsEdgeWebViewInfoBullet3 = Get-AxisWizardWindowsText -Name 'EdgeWebViewInfoBullet3'
$windowsEdgeWebViewApprovedBullet1 = ConvertFrom-AxisWizardCodePoints @(0x0625, 0x0632, 0x0627, 0x0644, 0x0629, 0x0020, 0x0045, 0x0064, 0x0067, 0x0065, 0x0020, 0x0057, 0x0065, 0x0062, 0x0056, 0x0069, 0x0065, 0x0077, 0x0020, 0x0648, 0x062A, 0x0642, 0x0644, 0x064A, 0x0644, 0x0020, 0x0627, 0x0644, 0x0645, 0x0643, 0x0648, 0x0646, 0x0627, 0x062A, 0x0020, 0x063A, 0x064A, 0x0631, 0x0020, 0x0627, 0x0644, 0x0636, 0x0631, 0x0648, 0x0631, 0x064A, 0x0629, 0x0020, 0x0627, 0x0644, 0x0645, 0x0631, 0x062A, 0x0628, 0x0637, 0x0629, 0x0020, 0x0628, 0x0647, 0x002E)
$windowsEdgeWebViewOldBoostLabBullet1 = ConvertFrom-AxisWizardCodePoints @(0x0625, 0x0632, 0x0627, 0x0644, 0x0629, 0x0020, 0x0045, 0x0064, 0x0067, 0x0065, 0x0020, 0x0057, 0x0065, 0x0062, 0x0056, 0x0069, 0x0065, 0x0077, 0x0020, 0x062D, 0x0633, 0x0628, 0x0020, 0x0645, 0x0633, 0x0627, 0x0631, 0x0020, 0x0042, 0x006F, 0x006F, 0x0073, 0x0074, 0x004C, 0x0061, 0x0062, 0x0020, 0x0627, 0x0644, 0x0645, 0x0639, 0x062A, 0x0645, 0x062F, 0x002E)
Assert-BoostLabCondition ($windowsEdgeWebViewInfoBullet1 -eq $windowsEdgeWebViewApprovedBullet1) 'AXIS Edge WebView information bullet 1 should use the owner-approved no-BoostLab customer copy.'
Assert-BoostLabCondition (-not $windowsEdgeWebViewInfoBullet1.Contains('BoostLab')) 'AXIS Edge WebView information bullet 1 must not expose BoostLab in customer-facing copy.'
Assert-BoostLabCondition ($windowsEdgeWebViewInfoBullet1 -ne $windowsEdgeWebViewOldBoostLabBullet1) 'AXIS Edge WebView information bullet 1 must not retain the old BoostLab-branded copy.'
$windowsNotepadSettingsSubtitle = Get-AxisWizardWindowsText -Name 'NotepadSettingsSubtitle'
$windowsNotepadSettingsPrimary = Get-AxisWizardWindowsText -Name 'NotepadSettingsPrimary'
$windowsNotepadSettingsInfoTitle = Get-AxisWizardWindowsText -Name 'NotepadSettingsInfoTitle'
$windowsNotepadSettingsInfoBullet1 = Get-AxisWizardWindowsText -Name 'NotepadSettingsInfoBullet1'
$windowsNotepadSettingsInfoBullet2 = Get-AxisWizardWindowsText -Name 'NotepadSettingsInfoBullet2'
$windowsNotepadSettingsInfoBullet3 = Get-AxisWizardWindowsText -Name 'NotepadSettingsInfoBullet3'
$windowsControlPanelSettingsSubtitle = Get-AxisWizardWindowsText -Name 'ControlPanelSettingsSubtitle'
$windowsControlPanelSettingsPrimary = Get-AxisWizardWindowsText -Name 'ControlPanelSettingsPrimary'
$windowsControlPanelSettingsInfoTitle = Get-AxisWizardWindowsText -Name 'ControlPanelSettingsInfoTitle'
$windowsControlPanelSettingsInfoBullet1 = Get-AxisWizardWindowsText -Name 'ControlPanelSettingsInfoBullet1'
$windowsControlPanelSettingsInfoBullet2 = Get-AxisWizardWindowsText -Name 'ControlPanelSettingsInfoBullet2'
$windowsControlPanelSettingsInfoBullet3 = Get-AxisWizardWindowsText -Name 'ControlPanelSettingsInfoBullet3'
$windowsInputLanguageHotkeySubtitle = Get-AxisWizardWindowsText -Name 'InputLanguageHotkeySubtitle'
$windowsInputLanguageHotkeyPrimary = Get-AxisWizardWindowsText -Name 'InputLanguageHotkeyPrimary'
$windowsInputLanguageHotkeyInfoTitle = Get-AxisWizardWindowsText -Name 'InputLanguageHotkeyInfoTitle'
$windowsInputLanguageHotkeyInfoBullet1 = Get-AxisWizardWindowsText -Name 'InputLanguageHotkeyInfoBullet1'
$windowsInputLanguageHotkeyInfoBullet2 = Get-AxisWizardWindowsText -Name 'InputLanguageHotkeyInfoBullet2'
$windowsInputLanguageHotkeyInfoBullet3 = Get-AxisWizardWindowsText -Name 'InputLanguageHotkeyInfoBullet3'
$windowsSoundSubtitle = Get-AxisWizardWindowsText -Name 'SoundSubtitle'
$windowsSoundPrimary = Get-AxisWizardWindowsText -Name 'SoundPrimary'
$windowsSoundInfoTitle = Get-AxisWizardWindowsText -Name 'SoundInfoTitle'
$windowsSoundInfoBullet1 = Get-AxisWizardWindowsText -Name 'SoundInfoBullet1'
$windowsSoundInfoBullet2 = Get-AxisWizardWindowsText -Name 'SoundInfoBullet2'
$windowsSoundInfoBullet3 = Get-AxisWizardWindowsText -Name 'SoundInfoBullet3'
$windowsDeviceManagerPowerSavingsWakeSubtitle = Get-AxisWizardWindowsText -Name 'DeviceManagerPowerSavingsWakeSubtitle'
$windowsDeviceManagerPowerSavingsWakePrimary = Get-AxisWizardWindowsText -Name 'DeviceManagerPowerSavingsWakePrimary'
$windowsDeviceManagerPowerSavingsWakeInfoTitle = Get-AxisWizardWindowsText -Name 'DeviceManagerPowerSavingsWakeInfoTitle'
$windowsDeviceManagerPowerSavingsWakeInfoBullet1 = Get-AxisWizardWindowsText -Name 'DeviceManagerPowerSavingsWakeInfoBullet1'
$windowsDeviceManagerPowerSavingsWakeInfoBullet2 = Get-AxisWizardWindowsText -Name 'DeviceManagerPowerSavingsWakeInfoBullet2'
$windowsDeviceManagerPowerSavingsWakeInfoBullet3 = Get-AxisWizardWindowsText -Name 'DeviceManagerPowerSavingsWakeInfoBullet3'
$windowsNetworkAdapterPowerSavingsWakeSubtitle = Get-AxisWizardWindowsText -Name 'NetworkAdapterPowerSavingsWakeSubtitle'
$windowsNetworkAdapterPowerSavingsWakePrimary = Get-AxisWizardWindowsText -Name 'NetworkAdapterPowerSavingsWakePrimary'
$windowsNetworkAdapterPowerSavingsWakeInfoTitle = Get-AxisWizardWindowsText -Name 'NetworkAdapterPowerSavingsWakeInfoTitle'
$windowsNetworkAdapterPowerSavingsWakeInfoBullet1 = Get-AxisWizardWindowsText -Name 'NetworkAdapterPowerSavingsWakeInfoBullet1'
$windowsNetworkAdapterPowerSavingsWakeInfoBullet2 = Get-AxisWizardWindowsText -Name 'NetworkAdapterPowerSavingsWakeInfoBullet2'
$windowsNetworkAdapterPowerSavingsWakeInfoBullet3 = Get-AxisWizardWindowsText -Name 'NetworkAdapterPowerSavingsWakeInfoBullet3'
$windowsWriteCacheBufferFlushingSubtitle = Get-AxisWizardWindowsText -Name 'WriteCacheBufferFlushingSubtitle'
$windowsWriteCacheBufferFlushingPrimary = Get-AxisWizardWindowsText -Name 'WriteCacheBufferFlushingPrimary'
$windowsWriteCacheBufferFlushingInfoTitle = Get-AxisWizardWindowsText -Name 'WriteCacheBufferFlushingInfoTitle'
$windowsWriteCacheBufferFlushingInfoBullet1 = Get-AxisWizardWindowsText -Name 'WriteCacheBufferFlushingInfoBullet1'
$windowsWriteCacheBufferFlushingInfoBullet2 = Get-AxisWizardWindowsText -Name 'WriteCacheBufferFlushingInfoBullet2'
$windowsWriteCacheBufferFlushingInfoBullet3 = Get-AxisWizardWindowsText -Name 'WriteCacheBufferFlushingInfoBullet3'
$windowsPowerPlanSubtitle = Get-AxisWizardWindowsText -Name 'PowerPlanSubtitle'
$windowsPowerPlanPrimary = Get-AxisWizardWindowsText -Name 'PowerPlanPrimary'
$windowsPowerPlanInfoTitle = Get-AxisWizardWindowsText -Name 'PowerPlanInfoTitle'
$windowsPowerPlanInfoBullet1 = Get-AxisWizardWindowsText -Name 'PowerPlanInfoBullet1'
$windowsPowerPlanInfoBullet2 = Get-AxisWizardWindowsText -Name 'PowerPlanInfoBullet2'
$windowsPowerPlanInfoBullet3 = Get-AxisWizardWindowsText -Name 'PowerPlanInfoBullet3'
$windowsCleanupSubtitle = Get-AxisWizardWindowsText -Name 'CleanupSubtitle'
$windowsCleanupPrimary = Get-AxisWizardWindowsText -Name 'CleanupPrimary'
$windowsCleanupInfoTitle = Get-AxisWizardWindowsText -Name 'CleanupInfoTitle'
$windowsCleanupInfoBullet1 = Get-AxisWizardWindowsText -Name 'CleanupInfoBullet1'
$windowsCleanupInfoBullet2 = Get-AxisWizardWindowsText -Name 'CleanupInfoBullet2'
$windowsCleanupInfoBullet3 = Get-AxisWizardWindowsText -Name 'CleanupInfoBullet3'
$windowsRunning = Get-AxisWizardWindowsText -Name 'Running'
$windowsCompleted = Get-AxisWizardWindowsText -Name 'Completed'
$advancedTimerResolutionSubtitle = Get-AxisWizardAdvancedText -Name 'TimerResolutionSubtitle'
$advancedTimerResolutionPrimary = Get-AxisWizardAdvancedText -Name 'TimerResolutionPrimary'
$advancedTimerResolutionInfoTitle = Get-AxisWizardAdvancedText -Name 'TimerResolutionInfoTitle'
$advancedTimerResolutionInfoBullet1 = Get-AxisWizardAdvancedText -Name 'TimerResolutionInfoBullet1'
$advancedTimerResolutionInfoBullet2 = Get-AxisWizardAdvancedText -Name 'TimerResolutionInfoBullet2'
$advancedTimerResolutionInfoBullet3 = Get-AxisWizardAdvancedText -Name 'TimerResolutionInfoBullet3'
$advancedDefenderOptimizeSubtitle = Get-AxisWizardAdvancedText -Name 'DefenderOptimizeSubtitle'
$advancedDefenderOptimizeInfoTitle = Get-AxisWizardAdvancedText -Name 'DefenderOptimizeInfoTitle'
$advancedDefenderOptimizeInfoBullet1 = Get-AxisWizardAdvancedText -Name 'DefenderOptimizeInfoBullet1'
$advancedDefenderOptimizeInfoBullet2 = Get-AxisWizardAdvancedText -Name 'DefenderOptimizeInfoBullet2'
$advancedDefenderOptimizeInfoBullet3 = Get-AxisWizardAdvancedText -Name 'DefenderOptimizeInfoBullet3'
$advancedDefenderOptimizeRequirementsTitle = Get-AxisWizardAdvancedText -Name 'DefenderOptimizeRequirementsTitle'
$advancedDefenderOptimizeRequirement1 = Get-AxisWizardAdvancedText -Name 'DefenderOptimizeRequirement1'
$advancedDefenderOptimizeRequirement2 = Get-AxisWizardAdvancedText -Name 'DefenderOptimizeRequirement2'
$advancedDefenderOptimizeRequirement3 = Get-AxisWizardAdvancedText -Name 'DefenderOptimizeRequirement3'
$advancedRunning = Get-AxisWizardAdvancedText -Name 'Running'
$advancedCompleted = Get-AxisWizardAdvancedText -Name 'Completed'
$advancedDefenderOptimizeApprovedBullet1 = ConvertFrom-AxisWizardCodePoints @(
    0x062A, 0x0637, 0x0628, 0x064A, 0x0642, 0x0020, 0x0627, 0x0644,
    0x0645, 0x0633, 0x0627, 0x0631, 0x0020, 0x0627, 0x0644, 0x0645,
    0x0639, 0x062A, 0x0645, 0x062F, 0x0020, 0x0644, 0x0636, 0x0628,
    0x0637, 0x0020, 0x0625, 0x0639, 0x062F, 0x0627, 0x062F, 0x0627,
    0x062A, 0x0020, 0x0044, 0x0065, 0x0066, 0x0065, 0x006E, 0x0064,
    0x0065, 0x0072, 0x002E
)
$advancedDefenderOptimizeOldBoostLabBullet1 = ConvertFrom-AxisWizardCodePoints @(
    0x062A, 0x0637, 0x0628, 0x064A, 0x0642, 0x0020, 0x0645, 0x0633,
    0x0627, 0x0631, 0x0020, 0x0042, 0x006F, 0x006F, 0x0073, 0x0074,
    0x004C, 0x0061, 0x0062, 0x0020, 0x0627, 0x0644, 0x0645, 0x0639,
    0x062A, 0x0645, 0x062F, 0x0020, 0x0644, 0x0636, 0x0628, 0x0637,
    0x0020, 0x0625, 0x0639, 0x062F, 0x0627, 0x062F, 0x0627, 0x062A,
    0x0020, 0x0044, 0x0065, 0x0066, 0x0065, 0x006E, 0x0064, 0x0065,
    0x0072, 0x002E
)
Assert-BoostLabCondition ($advancedDefenderOptimizeInfoBullet1 -eq $advancedDefenderOptimizeApprovedBullet1) 'AXIS Defender Optimize information bullet 1 should use the owner-approved no-BoostLab customer copy.'
Assert-BoostLabCondition (-not $advancedDefenderOptimizeInfoBullet1.Contains('BoostLab')) 'AXIS Defender Optimize information bullet 1 must not expose BoostLab in customer-facing copy.'
Assert-BoostLabCondition ($advancedDefenderOptimizeInfoBullet1 -ne $advancedDefenderOptimizeOldBoostLabBullet1) 'AXIS Defender Optimize information bullet 1 must not retain the old BoostLab-branded copy.'
$arabicInstallersRemovedEpicCheckbox = -join ([char[]]@(
    0x062A, 0x0645, 0x0020, 0x0625, 0x063A, 0x0644, 0x0627, 0x0642, 0x0020, 0x0646,
    0x0627, 0x0641, 0x0630, 0x0629, 0x0020, 0x0045, 0x0070, 0x0069, 0x0063, 0x0020,
    0x0047, 0x0061, 0x006D, 0x0065, 0x0073, 0x0020, 0x004C, 0x0061, 0x0075, 0x006E,
    0x0063, 0x0068, 0x0065, 0x0072
))
$expectedInstallersCatalogNames = @(Get-AxisFirstUseWizardInstallersCatalogNames)
$setupStepSpecs = @(
    [ordered]@{
        Id = 'bitlocker'
        TagRoot = 'SetupBitLocker'
        Title = 'BitLocker'
        Primary = Get-AxisWizardSetupText -Name 'BitLockerPrimaryAction'
        Subtitle = Get-AxisWizardSetupText -Name 'BitLockerSubtitle'
        InfoTitle = Get-AxisWizardSetupText -Name 'BitLockerInfoTitle'
        InfoItems = @(
            Get-AxisWizardSetupText -Name 'BitLockerInfoBullet1'
            Get-AxisWizardSetupText -Name 'BitLockerInfoBullet2'
            Get-AxisWizardSetupText -Name 'BitLockerInfoBullet3'
        )
        Running = Get-AxisWizardSetupText -Name 'BitLockerRunning'
        Completed = Get-AxisWizardSetupText -Name 'BitLockerCompleted'
        Requirements = @()
        Overlay = $false
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
    }
    [ordered]@{
        Id = 'convert-home-to-pro'
        TagRoot = 'SetupConvertHomeToPro'
        Title = 'Convert Home to Pro'
        Primary = Get-AxisWizardSetupText -Name 'ConvertHomeToProPrimaryAction'
        Subtitle = Get-AxisWizardSetupText -Name 'ConvertHomeToProSubtitle'
        InfoTitle = Get-AxisWizardSetupText -Name 'ConvertHomeToProInfoTitle'
        InfoItems = @(
            Get-AxisWizardSetupText -Name 'ConvertHomeToProInfoBullet1'
            Get-AxisWizardSetupText -Name 'ConvertHomeToProInfoBullet2'
            Get-AxisWizardSetupText -Name 'ConvertHomeToProInfoBullet3'
        )
        Requirements = @(
            Get-AxisWizardSetupText -Name 'ConvertHomeToProRequirement1'
            Get-AxisWizardSetupText -Name 'ConvertHomeToProRequirement2'
        )
        Running = Get-AxisWizardSetupText -Name 'ConvertHomeToProRunning'
        Completed = Get-AxisWizardSetupText -Name 'ConvertHomeToProCompleted'
        Overlay = $false
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
    }
    [ordered]@{
        Id = 'memory-compression'
        TagRoot = 'SetupMemoryCompression'
        Title = 'Memory Compression'
        Primary = Get-AxisWizardSetupText -Name 'MemoryCompressionPrimaryAction'
        Subtitle = Get-AxisWizardSetupText -Name 'MemoryCompressionSubtitle'
        InfoTitle = Get-AxisWizardSetupText -Name 'MemoryCompressionInfoTitle'
        InfoItems = @(
            Get-AxisWizardSetupText -Name 'MemoryCompressionInfoBullet1'
            Get-AxisWizardSetupText -Name 'MemoryCompressionInfoBullet2'
            Get-AxisWizardSetupText -Name 'MemoryCompressionInfoBullet3'
        )
        Requirements = @()
        Running = Get-AxisWizardSetupText -Name 'MemoryCompressionRunning'
        Completed = Get-AxisWizardSetupText -Name 'MemoryCompressionCompleted'
        Overlay = $false
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
    }
    [ordered]@{
        Id = 'date-language-region-time'
        TagRoot = 'SetupDateLanguageRegionTime'
        Title = Get-AxisWizardSetupText -Name 'DateLanguageRegionTimeTitle'
        Primary = Get-AxisWizardSetupText -Name 'DateLanguageRegionTimePrimaryAction'
        Subtitle = Get-AxisWizardSetupText -Name 'DateLanguageRegionTimeSubtitle'
        InfoTitle = Get-AxisWizardSetupText -Name 'DateLanguageRegionTimeInfoTitle'
        InfoItems = @(
            Get-AxisWizardSetupText -Name 'DateLanguageRegionTimeInfoBullet1'
            Get-AxisWizardSetupText -Name 'DateLanguageRegionTimeInfoBullet2'
            Get-AxisWizardSetupText -Name 'DateLanguageRegionTimeInfoBullet3'
        )
        Requirements = @()
        Running = Get-AxisWizardSetupText -Name 'DateLanguageRegionTimeRunning'
        Completed = Get-AxisWizardSetupText -Name 'DateLanguageRegionTimeCompleted'
        Overlay = $false
        CustomerAction = 'Open'
        FutureInternalAction = 'Open'
        OpenMappedPrototypeOnly = $true
    }
    [ordered]@{
        Id = 'startup-apps-settings'
        TagRoot = 'SetupStartupAppsSettings'
        Title = 'Startup Apps Settings'
        Primary = Get-AxisWizardSetupText -Name 'StartupAppsSettingsPrimaryAction'
        Subtitle = Get-AxisWizardSetupText -Name 'StartupAppsSettingsSubtitle'
        InfoTitle = Get-AxisWizardSetupText -Name 'StartupAppsSettingsInfoTitle'
        InfoItems = @(
            Get-AxisWizardSetupText -Name 'StartupAppsSettingsInfoBullet1'
            Get-AxisWizardSetupText -Name 'StartupAppsSettingsInfoBullet2'
            Get-AxisWizardSetupText -Name 'StartupAppsSettingsInfoBullet3'
        )
        Requirements = @(
            Get-AxisWizardSetupText -Name 'StartupAppsSettingsRequirement1'
            Get-AxisWizardSetupText -Name 'StartupAppsSettingsRequirement2'
        )
        Running = Get-AxisWizardSetupText -Name 'StartupAppsSettingsRunning'
        Completed = Get-AxisWizardSetupText -Name 'StartupAppsSettingsCompleted'
        Overlay = $false
        CustomerAction = 'Open'
        FutureInternalAction = 'Open'
        OpenMappedPrototypeOnly = $true
    }
    [ordered]@{
        Id = 'startup-apps-task-manager'
        TagRoot = 'SetupStartupAppsTaskManager'
        Title = 'Startup Apps Task Manager'
        Primary = Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerPrimaryAction'
        Subtitle = Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerSubtitle'
        InfoTitle = Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerInfoTitle'
        InfoItems = @(
            Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerInfoBullet1'
            Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerInfoBullet2'
            Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerInfoBullet3'
        )
        Requirements = @(
            Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerRequirement1'
            Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerRequirement2'
        )
        Running = Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerRunning'
        Completed = Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerCompleted'
        Overlay = $false
        CustomerAction = 'Open'
        FutureInternalAction = 'Open'
        OpenMappedPrototypeOnly = $true
    }
    [ordered]@{
        Id = 'background-apps'
        TagRoot = 'SetupBackgroundApps'
        Title = 'Background Apps'
        Primary = Get-AxisWizardSetupText -Name 'BackgroundAppsPrimaryAction'
        Subtitle = Get-AxisWizardSetupText -Name 'BackgroundAppsSubtitle'
        InfoTitle = Get-AxisWizardSetupText -Name 'BackgroundAppsInfoTitle'
        InfoItems = @(
            Get-AxisWizardSetupText -Name 'BackgroundAppsInfoBullet1'
            Get-AxisWizardSetupText -Name 'BackgroundAppsInfoBullet2'
            Get-AxisWizardSetupText -Name 'BackgroundAppsInfoBullet3'
        )
        Requirements = @()
        Running = Get-AxisWizardSetupText -Name 'BackgroundAppsRunning'
        Completed = Get-AxisWizardSetupText -Name 'BackgroundAppsCompleted'
        Overlay = $false
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
    }
    [ordered]@{
        Id = 'edge-settings'
        TagRoot = 'SetupEdgeSettings'
        Title = 'Microsoft Edge Settings'
        Primary = Get-AxisWizardSetupText -Name 'EdgeSettingsPrimaryAction'
        Subtitle = Get-AxisWizardSetupText -Name 'EdgeSettingsSubtitle'
        InfoTitle = Get-AxisWizardSetupText -Name 'EdgeSettingsInfoTitle'
        InfoItems = @(
            Get-AxisWizardSetupText -Name 'EdgeSettingsInfoBullet1'
            Get-AxisWizardSetupText -Name 'EdgeSettingsInfoBullet2'
            Get-AxisWizardSetupText -Name 'EdgeSettingsInfoBullet3'
        )
        Requirements = @()
        Running = Get-AxisWizardSetupText -Name 'EdgeSettingsRunning'
        Completed = Get-AxisWizardSetupText -Name 'EdgeSettingsCompleted'
        Overlay = $false
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
    }
    [ordered]@{
        Id = 'store-settings'
        TagRoot = 'SetupStoreSettings'
        Title = 'Microsoft Store Settings'
        Primary = Get-AxisWizardSetupText -Name 'StoreSettingsPrimaryAction'
        Subtitle = Get-AxisWizardSetupText -Name 'StoreSettingsSubtitle'
        InfoTitle = Get-AxisWizardSetupText -Name 'StoreSettingsInfoTitle'
        InfoItems = @(
            Get-AxisWizardSetupText -Name 'StoreSettingsInfoBullet1'
            Get-AxisWizardSetupText -Name 'StoreSettingsInfoBullet2'
            Get-AxisWizardSetupText -Name 'StoreSettingsInfoBullet3'
        )
        Requirements = @()
        Running = Get-AxisWizardSetupText -Name 'StoreSettingsRunning'
        Completed = Get-AxisWizardSetupText -Name 'StoreSettingsCompleted'
        Overlay = $false
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
    }
    [ordered]@{
        Id = 'updates-pause'
        TagRoot = 'SetupUpdatesPause'
        Title = 'Pause Windows Updates'
        Primary = Get-AxisWizardSetupText -Name 'UpdatesPausePrimaryAction'
        Subtitle = Get-AxisWizardSetupText -Name 'UpdatesPauseSubtitle'
        InfoTitle = Get-AxisWizardSetupText -Name 'UpdatesPauseInfoTitle'
        InfoItems = @(
            Get-AxisWizardSetupText -Name 'UpdatesPauseInfoBullet1'
            Get-AxisWizardSetupText -Name 'UpdatesPauseInfoBullet2'
            Get-AxisWizardSetupText -Name 'UpdatesPauseInfoBullet3'
        )
        Requirements = @(
            Get-AxisWizardSetupText -Name 'UpdatesPauseRequirement1'
        )
        Running = Get-AxisWizardSetupText -Name 'UpdatesPauseRunning'
        Completed = Get-AxisWizardSetupText -Name 'UpdatesPauseCompleted'
        Overlay = $true
        Checkbox = Get-AxisWizardSetupText -Name 'UpdatesPauseConfirmationCheckbox'
        ConfirmationPrimary = Get-AxisWizardSetupText -Name 'UpdatesPauseConfirmationPrimary'
        ConfirmationReturn = Get-AxisWizardSetupText -Name 'UpdatesPauseConfirmationReturn'
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
    }
)
$setupStepOrder = @($setupStepSpecs | ForEach-Object { [string]$_['Id'] })
$setupStepTitles = @($setupStepSpecs | ForEach-Object { [string]$_['Title'] })
$installersExtensionStepSpecs = @(
    [ordered]@{
        Id = 'installers-startup-apps-settings'
        SourceSetupId = 'startup-apps-settings'
        TagRoot = 'InstallersStartupAppsSettings'
        Title = 'Startup Apps Settings'
        Primary = Get-AxisWizardSetupText -Name 'StartupAppsSettingsPrimaryAction'
        Subtitle = Get-AxisWizardSetupText -Name 'StartupAppsSettingsSubtitle'
        InfoTitle = Get-AxisWizardSetupText -Name 'StartupAppsSettingsInfoTitle'
        InfoItems = @(
            Get-AxisWizardSetupText -Name 'StartupAppsSettingsInfoBullet1'
            Get-AxisWizardSetupText -Name 'StartupAppsSettingsInfoBullet2'
            Get-AxisWizardSetupText -Name 'StartupAppsSettingsInfoBullet3'
        )
        Requirements = @(
            Get-AxisWizardSetupText -Name 'StartupAppsSettingsRequirement1'
            Get-AxisWizardSetupText -Name 'StartupAppsSettingsRequirement2'
        )
        Running = Get-AxisWizardSetupText -Name 'StartupAppsSettingsRunning'
        Completed = Get-AxisWizardSetupText -Name 'StartupAppsSettingsCompleted'
        CustomerAction = 'Open'
        FutureInternalAction = 'Open'
        NoRealActionMarker = 'AxisFirstUseWizard.InstallersStartupAppsSettingsPrototypeOnlyNoRuntimeAction'
        OpenMappedPrototypeOnly = $true
    }
    [ordered]@{
        Id = 'installers-startup-apps-task-manager'
        SourceSetupId = 'startup-apps-task-manager'
        TagRoot = 'InstallersStartupAppsTaskManager'
        Title = 'Startup Apps Task Manager'
        Primary = Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerPrimaryAction'
        Subtitle = Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerSubtitle'
        InfoTitle = Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerInfoTitle'
        InfoItems = @(
            Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerInfoBullet1'
            Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerInfoBullet2'
            Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerInfoBullet3'
        )
        Requirements = @(
            Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerRequirement1'
            Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerRequirement2'
        )
        Running = Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerRunning'
        Completed = Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerCompleted'
        CustomerAction = 'Open'
        FutureInternalAction = 'Open'
        NoRealActionMarker = 'AxisFirstUseWizard.InstallersStartupAppsTaskManagerPrototypeOnlyNoRuntimeAction'
        OpenMappedPrototypeOnly = $true
    }
    [ordered]@{
        Id = 'restart-after-installers'
        SourceSetupId = ''
        TagRoot = 'RestartAfterInstallers'
        Title = $arabicRestartAfterInstallersTitle
        Primary = $arabicRestart
        Subtitle = $arabicRestartAfterInstallersSubtitle
        InfoTitle = $arabicRestartAfterInstallersTitle
        InfoItems = @(
            $arabicRestartAfterInstallersInfoBullet1
            $arabicRestartAfterInstallersInfoBullet2
            $arabicRestartAfterInstallersInfoBullet3
        )
        Requirements = @()
        Running = $arabicRestarting
        Completed = $arabicCompleted
        CustomerAction = 'Restart'
        FutureInternalAction = 'Restart'
        NoRealActionMarker = 'AxisFirstUseWizard.RestartAfterInstallersPrototypeOnlyNoRuntimeAction'
        OpenMappedPrototypeOnly = $false
    }
)
$installersExtensionStepOrder = @($installersExtensionStepSpecs | ForEach-Object { [string]$_['Id'] })
$installersExtensionStepTitles = @($installersExtensionStepSpecs | ForEach-Object { [string]$_['Title'] })
$graphicsStepSpecs = @(
    [ordered]@{
        Id = 'driver-clean'
        TagRoot = 'GraphicsDriverClean'
        Title = $graphicsDriverCleanTitle
        Primary = $graphicsDriverCleanPrimary
        Subtitle = $graphicsDriverCleanSubtitle
        InfoTitle = $graphicsDriverCleanInfoTitle
        InfoItems = @($graphicsDriverCleanInfoBullet1, $graphicsDriverCleanInfoBullet2, $graphicsDriverCleanInfoBullet3)
        Requirements = @($graphicsDriverCleanRequirement1, $graphicsDriverCleanRequirement2, $graphicsDriverCleanRequirement3)
        Running = $graphicsDriverCleanRunning
        Completed = $arabicCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.DriverCleanPrototypeOnlyNoRuntimeAction'
        Overlay = $true
        Selector = $false
        OptionalContinuation = ''
        OpenMappedPrototypeOnly = $false
    }
    [ordered]@{
        Id = 'driver-install-debloat-settings'
        TagRoot = 'GraphicsGpuDriverSetup'
        Title = 'GPU Driver Setup'
        Primary = $graphicsGpuSetupPrimary
        Subtitle = $graphicsGpuSetupSubtitle
        InfoTitle = $graphicsGpuSetupInfoTitle
        InfoItems = @($graphicsGpuSetupInfoBullet1, $graphicsGpuSetupInfoBullet2, $graphicsGpuSetupInfoBullet3)
        Requirements = @($graphicsGpuSetupRequirement1, $graphicsGpuSetupRequirement2, $graphicsGpuSetupRequirement3)
        Running = $graphicsGpuSetupRunning
        Completed = $arabicCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.GpuDriverSetupPrototypeOnlyNoRuntimeAction'
        Overlay = $true
        Selector = $true
        OptionalContinuation = ''
        OpenMappedPrototypeOnly = $false
    }
    [ordered]@{
        Id = 'nvidia-app-install'
        TagRoot = 'GraphicsNvidiaAppInstall'
        Title = 'NVIDIA App Install'
        Primary = 'Install NVIDIA App'
        Subtitle = $graphicsNvidiaAppSubtitle
        InfoTitle = $graphicsNvidiaAppInfoTitle
        InfoItems = @($graphicsNvidiaAppInfoBullet1, $graphicsNvidiaAppInfoBullet2, $graphicsNvidiaAppInfoBullet3)
        Requirements = @()
        Running = $graphicsNvidiaAppRunning
        Completed = $graphicsNvidiaAppCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.NvidiaAppInstallPrototypeOnlyNoRuntimeAction'
        Overlay = $true
        Selector = $false
        OptionalContinuation = $graphicsNvidiaAppOptionalContinuation
        OpenMappedPrototypeOnly = $false
    }
    [ordered]@{
        Id = 'directx'
        TagRoot = 'GraphicsDirectX'
        Title = 'DirectX'
        Primary = $graphicsDirectXPrimary
        Subtitle = $graphicsDirectXSubtitle
        InfoTitle = $graphicsDirectXInfoTitle
        InfoItems = @($graphicsDirectXInfoBullet1, $graphicsDirectXInfoBullet2, $graphicsDirectXInfoBullet3)
        Requirements = @()
        Running = $graphicsDirectXRunning
        Completed = $arabicCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.DirectXPrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OptionalContinuation = ''
        OpenMappedPrototypeOnly = $false
    }
    [ordered]@{
        Id = 'visual-cpp'
        TagRoot = 'GraphicsVisualCpp'
        Title = 'Visual C++ Runtimes'
        Primary = $graphicsVisualCppPrimary
        Subtitle = $graphicsVisualCppSubtitle
        InfoTitle = $graphicsVisualCppInfoTitle
        InfoItems = @($graphicsVisualCppInfoBullet1, $graphicsVisualCppInfoBullet2, $graphicsVisualCppInfoBullet3)
        Requirements = @()
        Running = $graphicsDirectXRunning
        Completed = $arabicCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.VisualCppPrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OptionalContinuation = ''
        OpenMappedPrototypeOnly = $false
    }
    [ordered]@{
        Id = 'graphics-configuration-center'
        TagRoot = 'GraphicsConfigurationCenter'
        Title = 'Graphics Configuration Center'
        Primary = $graphicsConfigPrimary
        Subtitle = $graphicsConfigSubtitle
        InfoTitle = $graphicsConfigInfoTitle
        InfoItems = @($graphicsConfigInfoBullet1, $graphicsConfigInfoBullet2, $graphicsConfigInfoBullet3)
        Requirements = @()
        Running = $graphicsConfigPrimary
        Completed = $arabicCompleted
        CustomerAction = 'Open'
        FutureInternalAction = 'Open'
        NoRealActionMarker = 'AxisFirstUseWizard.GraphicsConfigurationCenterPrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OptionalContinuation = ''
        OpenMappedPrototypeOnly = $true
    }
)
$graphicsStepOrder = @($graphicsStepSpecs | ForEach-Object { [string]$_['Id'] })
$graphicsStepTitles = @($graphicsStepSpecs | ForEach-Object { [string]$_['Title'] })
$windowsPartAStepSpecs = @(
    [ordered]@{
        Id = 'start-menu-taskbar'
        TagRoot = 'WindowsStartMenuTaskbar'
        Title = 'Start Menu Taskbar'
        Primary = 'Tweaks Start Menu Taskbar'
        Subtitle = $windowsStartMenuTaskbarSubtitle
        InfoTitle = $windowsStartMenuTaskbarInfoTitle
        InfoItems = @($windowsStartMenuTaskbarInfoBullet1, $windowsStartMenuTaskbarInfoBullet2, $windowsStartMenuTaskbarInfoBullet3)
        Requirements = @()
        Running = $windowsRunning
        Completed = $windowsCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.WindowsStartMenuTaskbarPrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OpenMappedPrototypeOnly = $false
    }
    [ordered]@{
        Id = 'start-menu-layout'
        TagRoot = 'WindowsStartMenuLayout'
        Title = 'Start Menu Layout'
        Primary = 'Tweaks Start Menu Layout'
        Subtitle = $windowsStartMenuLayoutSubtitle
        InfoTitle = $windowsStartMenuLayoutInfoTitle
        InfoItems = @($windowsStartMenuLayoutInfoBullet1, $windowsStartMenuLayoutInfoBullet2, $windowsStartMenuLayoutInfoBullet3)
        Requirements = @()
        Running = $windowsRunning
        Completed = $windowsCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.WindowsStartMenuLayoutPrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OpenMappedPrototypeOnly = $false
    }
    [ordered]@{
        Id = 'context-menu'
        TagRoot = 'WindowsContextMenu'
        Title = 'Context Menu'
        Primary = 'Tweaks Context Menu'
        Subtitle = $windowsContextMenuSubtitle
        InfoTitle = $windowsContextMenuInfoTitle
        InfoItems = @($windowsContextMenuInfoBullet1, $windowsContextMenuInfoBullet2, $windowsContextMenuInfoBullet3)
        Requirements = @()
        Running = $windowsRunning
        Completed = $windowsCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.WindowsContextMenuPrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OpenMappedPrototypeOnly = $false
    }
    [ordered]@{
        Id = 'theme-black'
        TagRoot = 'WindowsThemeBlack'
        Title = 'Theme Black'
        Primary = $windowsThemeBlackPrimary
        Subtitle = $windowsThemeBlackSubtitle
        InfoTitle = $windowsThemeBlackInfoTitle
        InfoItems = @($windowsThemeBlackInfoBullet1, $windowsThemeBlackInfoBullet2)
        Requirements = @()
        Running = $windowsRunning
        Completed = $windowsCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.WindowsThemeBlackPrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OpenMappedPrototypeOnly = $false
    }
    [ordered]@{
        Id = 'signout-lockscreen-wallpaper-black'
        TagRoot = 'WindowsBlackLockScreenWallpaper'
        Title = 'Black Lock Screen Wallpaper'
        Primary = $windowsBlackLockScreenWallpaperPrimary
        Subtitle = $windowsBlackLockScreenWallpaperSubtitle
        InfoTitle = $windowsBlackLockScreenWallpaperInfoTitle
        InfoItems = @($windowsBlackLockScreenWallpaperInfoBullet1, $windowsBlackLockScreenWallpaperInfoBullet2)
        Requirements = @()
        Running = $windowsRunning
        Completed = $windowsCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.WindowsBlackLockScreenWallpaperPrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OpenMappedPrototypeOnly = $false
    }
    [ordered]@{
        Id = 'user-account-pictures-black'
        TagRoot = 'WindowsBlackAccountPictures'
        Title = 'Black Account Pictures'
        Primary = $windowsBlackAccountPicturesPrimary
        Subtitle = $windowsBlackAccountPicturesSubtitle
        InfoTitle = $windowsBlackAccountPicturesInfoTitle
        InfoItems = @($windowsBlackAccountPicturesInfoBullet1, $windowsBlackAccountPicturesInfoBullet2)
        Requirements = @()
        Running = $windowsRunning
        Completed = $windowsCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.WindowsBlackAccountPicturesPrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OpenMappedPrototypeOnly = $false
    }
    [ordered]@{
        Id = 'widgets'
        TagRoot = 'WindowsWidgets'
        Title = 'Widgets'
        Primary = $windowsWidgetsPrimary
        Subtitle = $windowsWidgetsSubtitle
        InfoTitle = $windowsWidgetsInfoTitle
        InfoItems = @($windowsWidgetsInfoBullet1, $windowsWidgetsInfoBullet2, $windowsWidgetsInfoBullet3)
        Requirements = @()
        Running = $windowsRunning
        Completed = $windowsCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.WindowsWidgetsPrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OpenMappedPrototypeOnly = $false
    }
    [ordered]@{
        Id = 'copilot'
        TagRoot = 'WindowsCopilot'
        Title = 'Copilot'
        Primary = $windowsCopilotPrimary
        Subtitle = $windowsCopilotSubtitle
        InfoTitle = $windowsCopilotInfoTitle
        InfoItems = @($windowsCopilotInfoBullet1, $windowsCopilotInfoBullet2, $windowsCopilotInfoBullet3)
        Requirements = @()
        Running = $windowsRunning
        Completed = $windowsCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.WindowsCopilotPrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OpenMappedPrototypeOnly = $false
    }
    [ordered]@{
        Id = 'game-mode'
        TagRoot = 'WindowsGameMode'
        Title = 'Game Mode'
        Primary = $windowsGameModePrimary
        Subtitle = $windowsGameModeSubtitle
        InfoTitle = $windowsGameModeInfoTitle
        InfoItems = @($windowsGameModeInfoBullet1, $windowsGameModeInfoBullet2, $windowsGameModeInfoBullet3)
        Requirements = @()
        Running = $windowsGameModeRunning
        Completed = $windowsCompleted
        CustomerAction = 'Open'
        FutureInternalAction = 'Open'
        NoRealActionMarker = 'AxisFirstUseWizard.WindowsGameModePrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OpenMappedPrototypeOnly = $true
    }
    [ordered]@{
        Id = 'pointer-precision'
        TagRoot = 'WindowsPointerPrecision'
        Title = 'Pointer Precision'
        Primary = $windowsPointerPrecisionPrimary
        Subtitle = $windowsPointerPrecisionSubtitle
        InfoTitle = $windowsPointerPrecisionInfoTitle
        InfoItems = @($windowsPointerPrecisionInfoBullet1, $windowsPointerPrecisionInfoBullet2, $windowsPointerPrecisionInfoBullet3)
        Requirements = @()
        Running = $windowsPointerPrecisionRunning
        Completed = $windowsCompleted
        CustomerAction = 'Open'
        FutureInternalAction = 'Open'
        NoRealActionMarker = 'AxisFirstUseWizard.WindowsPointerPrecisionPrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OpenMappedPrototypeOnly = $true
    }
    [ordered]@{
        Id = 'bloatware'
        TagRoot = 'WindowsBloatware'
        Title = 'Bloatware'
        Primary = $windowsBloatwarePrimary
        Subtitle = $windowsBloatwareSubtitle
        InfoTitle = $windowsBloatwareInfoTitle
        InfoItems = @($windowsBloatwareInfoBullet1, $windowsBloatwareInfoBullet2, $windowsBloatwareInfoBullet3)
        Requirements = @($windowsBloatwareRequirement1, $windowsBloatwareRequirement2)
        Running = $windowsRunning
        Completed = $windowsCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.WindowsBloatwarePrototypeOnlyNoRuntimeAction'
        Overlay = $true
        Selector = $true
        SelectorLabel = $windowsBloatwareSelectorLabel
        SelectorPlaceholder = $windowsBloatwareSelectorPlaceholder
        SelectorOptions = @('Remove All Bloatware', 'Install Store', 'Install Snipping Tool')
        OpenMappedPrototypeOnly = $false
    }
)
$windowsPartAStepOrder = @($windowsPartAStepSpecs | ForEach-Object { [string]$_['Id'] })
$windowsPartAStepTitles = @($windowsPartAStepSpecs | ForEach-Object { [string]$_['Title'] })
$windowsPartBStepSpecs = @(
    [ordered]@{
        Id = 'game-bar'
        TagRoot = 'WindowsGameBar'
        Title = 'Game Bar'
        Primary = $windowsGameBarPrimary
        Subtitle = $windowsGameBarSubtitle
        InfoTitle = $windowsGameBarInfoTitle
        InfoItems = @($windowsGameBarInfoBullet1, $windowsGameBarInfoBullet2, $windowsGameBarInfoBullet3)
        Requirements = @()
        Running = $windowsRunning
        Completed = $windowsCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.WindowsGameBarPrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OpenMappedPrototypeOnly = $false
        WindowsStageBatchMarker = 'AxisFirstUseWizard.WindowsStagePartBPrototypeOnly'
    }
    [ordered]@{
        Id = 'edge-webview'
        TagRoot = 'WindowsEdgeWebView'
        Title = 'Edge WebView'
        Primary = $windowsEdgeWebViewPrimary
        Subtitle = $windowsEdgeWebViewSubtitle
        InfoTitle = $windowsEdgeWebViewInfoTitle
        InfoItems = @($windowsEdgeWebViewInfoBullet1, $windowsEdgeWebViewInfoBullet2, $windowsEdgeWebViewInfoBullet3)
        Requirements = @()
        Running = $windowsRunning
        Completed = $windowsCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.WindowsEdgeWebViewPrototypeOnlyNoRuntimeAction'
        Overlay = $true
        Selector = $false
        OpenMappedPrototypeOnly = $false
        WindowsStageBatchMarker = 'AxisFirstUseWizard.WindowsStagePartBPrototypeOnly'
    }
    [ordered]@{
        Id = 'notepad-settings'
        TagRoot = 'WindowsNotepadSettings'
        Title = 'Notepad Settings'
        Primary = $windowsNotepadSettingsPrimary
        Subtitle = $windowsNotepadSettingsSubtitle
        InfoTitle = $windowsNotepadSettingsInfoTitle
        InfoItems = @($windowsNotepadSettingsInfoBullet1, $windowsNotepadSettingsInfoBullet2, $windowsNotepadSettingsInfoBullet3)
        Requirements = @()
        Running = $windowsRunning
        Completed = $windowsCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.WindowsNotepadSettingsPrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OpenMappedPrototypeOnly = $false
        WindowsStageBatchMarker = 'AxisFirstUseWizard.WindowsStagePartBPrototypeOnly'
    }
    [ordered]@{
        Id = 'control-panel-settings'
        TagRoot = 'WindowsControlPanelSettings'
        Title = 'Control Panel Settings'
        Primary = $windowsControlPanelSettingsPrimary
        Subtitle = $windowsControlPanelSettingsSubtitle
        InfoTitle = $windowsControlPanelSettingsInfoTitle
        InfoItems = @($windowsControlPanelSettingsInfoBullet1, $windowsControlPanelSettingsInfoBullet2, $windowsControlPanelSettingsInfoBullet3)
        Requirements = @()
        Running = $windowsRunning
        Completed = $windowsCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.WindowsControlPanelSettingsPrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OpenMappedPrototypeOnly = $false
        WindowsStageBatchMarker = 'AxisFirstUseWizard.WindowsStagePartBPrototypeOnly'
    }
    [ordered]@{
        Id = 'input-language-hotkey'
        TagRoot = 'WindowsInputLanguageHotkey'
        Title = 'Input Language Hotkey'
        Primary = $windowsInputLanguageHotkeyPrimary
        Subtitle = $windowsInputLanguageHotkeySubtitle
        InfoTitle = $windowsInputLanguageHotkeyInfoTitle
        InfoItems = @($windowsInputLanguageHotkeyInfoBullet1, $windowsInputLanguageHotkeyInfoBullet2, $windowsInputLanguageHotkeyInfoBullet3)
        Requirements = @()
        Running = $windowsRunning
        Completed = $windowsCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.WindowsInputLanguageHotkeyPrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OpenMappedPrototypeOnly = $false
        WindowsStageBatchMarker = 'AxisFirstUseWizard.WindowsStagePartBPrototypeOnly'
    }
    [ordered]@{
        Id = 'sound'
        TagRoot = 'WindowsSound'
        Title = 'Sound'
        Primary = $windowsSoundPrimary
        Subtitle = $windowsSoundSubtitle
        InfoTitle = $windowsSoundInfoTitle
        InfoItems = @($windowsSoundInfoBullet1, $windowsSoundInfoBullet2, $windowsSoundInfoBullet3)
        Requirements = @()
        Running = $windowsRunning
        Completed = $windowsCompleted
        CustomerAction = 'Open'
        FutureInternalAction = 'Open'
        NoRealActionMarker = 'AxisFirstUseWizard.WindowsSoundPrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OpenMappedPrototypeOnly = $true
        WindowsStageBatchMarker = 'AxisFirstUseWizard.WindowsStagePartBPrototypeOnly'
    }
    [ordered]@{
        Id = 'device-manager-power-savings-wake'
        TagRoot = 'WindowsDeviceManagerPowerSavingsWake'
        Title = 'Device Manager Power Savings Wake'
        Primary = $windowsDeviceManagerPowerSavingsWakePrimary
        Subtitle = $windowsDeviceManagerPowerSavingsWakeSubtitle
        InfoTitle = $windowsDeviceManagerPowerSavingsWakeInfoTitle
        InfoItems = @($windowsDeviceManagerPowerSavingsWakeInfoBullet1, $windowsDeviceManagerPowerSavingsWakeInfoBullet2, $windowsDeviceManagerPowerSavingsWakeInfoBullet3)
        Requirements = @()
        Running = $windowsRunning
        Completed = $windowsCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.WindowsDeviceManagerPowerSavingsWakePrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OpenMappedPrototypeOnly = $false
        WindowsStageBatchMarker = 'AxisFirstUseWizard.WindowsStagePartBPrototypeOnly'
    }
    [ordered]@{
        Id = 'network-adapter-power-savings-wake'
        TagRoot = 'WindowsNetworkAdapterPowerSavingsWake'
        Title = 'Network Adapter Power Savings Wake'
        Primary = $windowsNetworkAdapterPowerSavingsWakePrimary
        Subtitle = $windowsNetworkAdapterPowerSavingsWakeSubtitle
        InfoTitle = $windowsNetworkAdapterPowerSavingsWakeInfoTitle
        InfoItems = @($windowsNetworkAdapterPowerSavingsWakeInfoBullet1, $windowsNetworkAdapterPowerSavingsWakeInfoBullet2, $windowsNetworkAdapterPowerSavingsWakeInfoBullet3)
        Requirements = @()
        Running = $windowsRunning
        Completed = $windowsCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.WindowsNetworkAdapterPowerSavingsWakePrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OpenMappedPrototypeOnly = $false
        WindowsStageBatchMarker = 'AxisFirstUseWizard.WindowsStagePartBPrototypeOnly'
    }
    [ordered]@{
        Id = 'write-cache-buffer-flushing'
        TagRoot = 'WindowsWriteCacheBufferFlushing'
        Title = 'Write Cache Buffer Flushing'
        Primary = $windowsWriteCacheBufferFlushingPrimary
        Subtitle = $windowsWriteCacheBufferFlushingSubtitle
        InfoTitle = $windowsWriteCacheBufferFlushingInfoTitle
        InfoItems = @($windowsWriteCacheBufferFlushingInfoBullet1, $windowsWriteCacheBufferFlushingInfoBullet2, $windowsWriteCacheBufferFlushingInfoBullet3)
        Requirements = @()
        Running = $windowsRunning
        Completed = $windowsCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.WindowsWriteCacheBufferFlushingPrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OpenMappedPrototypeOnly = $false
        WindowsStageBatchMarker = 'AxisFirstUseWizard.WindowsStagePartBPrototypeOnly'
    }
    [ordered]@{
        Id = 'power-plan'
        TagRoot = 'WindowsPowerPlan'
        Title = 'Power Plan'
        Primary = $windowsPowerPlanPrimary
        Subtitle = $windowsPowerPlanSubtitle
        InfoTitle = $windowsPowerPlanInfoTitle
        InfoItems = @($windowsPowerPlanInfoBullet1, $windowsPowerPlanInfoBullet2, $windowsPowerPlanInfoBullet3)
        Requirements = @()
        Running = $windowsRunning
        Completed = $windowsCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.WindowsPowerPlanPrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OpenMappedPrototypeOnly = $false
        WindowsStageBatchMarker = 'AxisFirstUseWizard.WindowsStagePartBPrototypeOnly'
    }
    [ordered]@{
        Id = 'cleanup'
        TagRoot = 'WindowsCleanup'
        Title = 'Cleanup'
        Primary = $windowsCleanupPrimary
        Subtitle = $windowsCleanupSubtitle
        InfoTitle = $windowsCleanupInfoTitle
        InfoItems = @($windowsCleanupInfoBullet1, $windowsCleanupInfoBullet2, $windowsCleanupInfoBullet3)
        Requirements = @()
        Running = $windowsRunning
        Completed = $windowsCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.WindowsCleanupPrototypeOnlyNoRuntimeAction'
        Overlay = $false
        Selector = $false
        OpenMappedPrototypeOnly = $false
        WindowsStageBatchMarker = 'AxisFirstUseWizard.WindowsStagePartBPrototypeOnly'
    }
)
$windowsPartBStepOrder = @($windowsPartBStepSpecs | ForEach-Object { [string]$_['Id'] })
$windowsPartBStepTitles = @($windowsPartBStepSpecs | ForEach-Object { [string]$_['Title'] })
$windowsStepSpecs = @($windowsPartAStepSpecs + $windowsPartBStepSpecs)
$windowsStepOrder = @($windowsStepSpecs | ForEach-Object { [string]$_['Id'] })
$windowsStepTitles = @($windowsStepSpecs | ForEach-Object { [string]$_['Title'] })
$advancedStepSpecs = @(
    [ordered]@{
        Id = 'timer-resolution-assistant'
        TagRoot = 'AdvancedTimerResolutionAssistant'
        Title = 'Timer Resolution Assistant'
        Primary = $advancedTimerResolutionPrimary
        Subtitle = $advancedTimerResolutionSubtitle
        InfoTitle = $advancedTimerResolutionInfoTitle
        InfoItems = @($advancedTimerResolutionInfoBullet1, $advancedTimerResolutionInfoBullet2, $advancedTimerResolutionInfoBullet3)
        Requirements = @()
        Running = $advancedRunning
        Completed = $advancedCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.AdvancedTimerResolutionAssistantPrototypeOnlyNoRuntimeAction'
        Overlay = $false
    }
    [ordered]@{
        Id = 'defender-optimize-assistant'
        TagRoot = 'AdvancedDefenderOptimizeAssistant'
        Title = 'Defender Optimize Assistant'
        Primary = 'Apply Defender Optimize'
        Subtitle = $advancedDefenderOptimizeSubtitle
        InfoTitle = $advancedDefenderOptimizeInfoTitle
        InfoItems = @($advancedDefenderOptimizeInfoBullet1, $advancedDefenderOptimizeInfoBullet2, $advancedDefenderOptimizeInfoBullet3)
        Requirements = @($advancedDefenderOptimizeRequirement1, $advancedDefenderOptimizeRequirement2, $advancedDefenderOptimizeRequirement3)
        Running = $advancedRunning
        Completed = $advancedCompleted
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        NoRealActionMarker = 'AxisFirstUseWizard.AdvancedDefenderOptimizeAssistantPrototypeOnlyNoRuntimeAction'
        Overlay = $true
    }
)
$advancedStepOrder = @($advancedStepSpecs | ForEach-Object { [string]$_['Id'] })
$advancedStepTitles = @($advancedStepSpecs | ForEach-Object { [string]$_['Title'] })
$axisSetupRightAlignedVisualLineRendererAutomationId = 'AxisFirstUseWizard.SetupRightAlignedVisualLineRenderer.NoLeftFloatingWrappedArabicLines'
$axisSharedCardBodyTextRendererMarker = 'AxisFirstUseWizard.SharedCardBodyTextRenderer'
$axisSharedCardBodyNoLeftFloatingMarker = 'AxisFirstUseWizard.SharedCardBodyNoLeftFloatingWrappedArabic'
$axisSharedCardBodyMixedBidiMarker = 'AxisFirstUseWizard.SharedCardBodyMixedBidiSafeVisualLines'
$axisSharedCardBodyFutureGuardMarker = 'AxisFirstUseWizard.SharedCardBodyFutureStageGuard'
$oldArabicToBiosTitle = ConvertFrom-AxisWizardCodePoints @(0x0627, 0x0644, 0x0627, 0x0646, 0x062A, 0x0642, 0x0627, 0x0644, 0x0020, 0x0625, 0x0644, 0x0649, 0x0020, 0x0042, 0x0049, 0x004F, 0x0053)
$arabicStartupAppsStartupPhrase = ConvertFrom-AxisWizardCodePoints @(0x0628, 0x062F, 0x0621, 0x0020, 0x0627, 0x0644, 0x062A, 0x0634, 0x063A, 0x064A, 0x0644)
$arabicUpdatesPauseDeviceOrphan = ConvertFrom-AxisWizardCodePoints @(0x0627, 0x0644, 0x062C, 0x0647, 0x0627, 0x0632, 0x002E)
$arabicUpdatesPauseUpdatesOrphan = ConvertFrom-AxisWizardCodePoints @(0x0628, 0x0627, 0x0644, 0x062A, 0x062D, 0x062F, 0x064A, 0x062B, 0x0627, 0x062A, 0x002E)
$axisDefaultDocumentationForeground = '#FFEDEDED'
$axisDefaultAcknowledgementForeground = '#FFEDEDED'
$axisDefaultCardTitleForeground = '#FFFAF9F6'
$axisRejectedAcknowledgementAccentForeground = '#FFE65F2B'
$axisRejectedInformationCardTitleForeground = '#FF8A2BE2'
$axisRejectedRequirementsCardTitleForeground = '#FFD9A74A'
$oldArabicIntelRebar = ConvertFrom-AxisWizardCodePoints @(
    0x062A, 0x0641, 0x0639, 0x064A, 0x0644, 0x0020,
    0x0052, 0x0065, 0x0073, 0x0069, 0x007A, 0x0061, 0x0062, 0x006C, 0x0065, 0x0020,
    0x0042, 0x0041, 0x0052, 0x003A, 0x0020,
    0x0052, 0x0045, 0x0042, 0x0041, 0x0052, 0x0020,
    0x002F, 0x0020,
    0x0043, 0x002E, 0x0041, 0x002E, 0x004D, 0x002E
)
$oldArabicIntelCStates = ConvertFrom-AxisWizardCodePoints @(
    0x062A, 0x0639, 0x0637, 0x064A, 0x0644, 0x0020,
    0x0043, 0x002D, 0x0053, 0x0074, 0x0061, 0x0074, 0x0065, 0x0073, 0x0020,
    0x0644, 0x0645, 0x0639, 0x0627, 0x0644, 0x062C, 0x0627, 0x062A, 0x0020,
    0x004B, 0x0020,
    0x0641, 0x0642, 0x0637
)
$oldArabicRestartAcknowledgement = ConvertFrom-AxisWizardCodePoints @(
    0x0644, 0x0642, 0x062F, 0x0020,
    0x0642, 0x0631, 0x0623, 0x062A, 0x0020,
    0x0627, 0x0644, 0x062A, 0x0639, 0x0644, 0x064A, 0x0645, 0x0627, 0x062A, 0x0020,
    0x0648, 0x0623, 0x0639, 0x0644, 0x0645, 0x0020,
    0x0623, 0x0646, 0x0647, 0x0020,
    0x0633, 0x064A, 0x062A, 0x0645, 0x0020,
    0x0625, 0x0639, 0x0627, 0x062F, 0x0629, 0x0020,
    0x062A, 0x0634, 0x063A, 0x064A, 0x0644, 0x0020,
    0x0627, 0x0644, 0x062C, 0x0647, 0x0627, 0x0632, 0x0020,
    0x0625, 0x0644, 0x0649, 0x0020,
    0x0634, 0x0627, 0x0634, 0x0629, 0x0020,
    0x0042, 0x0049, 0x004F, 0x0053, 0x002F, 0x0055, 0x0045, 0x0046, 0x0049, 0x002E
)

$sampleState = Get-AxisFirstUseWizardSampleState
$prototype = New-AxisFirstUseWizardPrototype -SampleState $sampleState
$window = New-AxisFirstUseWizardPrototypeWindow -SampleState $sampleState

Assert-BoostLabCondition ($prototype -is [System.Windows.Controls.Grid]) 'AXIS first-use wizard did not create a WPF Grid root.'
Assert-BoostLabCondition ($window -is [System.Windows.Window]) 'AXIS first-use wizard preview window was not created as a WPF Window.'
Assert-BoostLabCondition ([double]$window.Width -eq 900.0) 'AXIS first-use wizard target window width should be 900.'
Assert-BoostLabCondition ([double]$window.Height -eq 650.0) 'AXIS first-use wizard target window height should be 650.'
Assert-BoostLabCondition ($window.WindowStyle -eq [System.Windows.WindowStyle]::SingleBorderWindow) 'AXIS first-use wizard preview should use normal Windows titlebar/chrome.'
Assert-BoostLabCondition ($window.ResizeMode -eq [System.Windows.ResizeMode]::NoResize) 'AXIS first-use wizard preview should keep the fixed 900x650 target size.'
Assert-BoostLabCondition ($prototype.FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) 'AXIS first-use wizard Arabic surface must use RTL FlowDirection.'
Assert-BoostLabCondition ($prototype.RowDefinitions.Count -eq 4) 'AXIS first-use wizard should keep header, progress, content, and footer rows separate.'
Assert-BoostLabCondition ([double]$prototype.RowDefinitions[0].Height.Value -eq 76.0) 'AXIS first-use wizard header row should leave room for normal Windows chrome.'
Assert-BoostLabCondition ([double]$prototype.RowDefinitions[1].Height.Value -eq 0.0) 'AXIS intro page should collapse the stage strip row.'
Assert-BoostLabCondition ([double]$prototype.RowDefinitions[3].Height.Value -eq 0.0) 'AXIS intro page should collapse the footer row.'
Assert-BoostLabCondition ($prototype.Resources.Contains('Axis.Brush.Wizard.Background')) 'AXIS first-use wizard root does not include wizard resources.'

$stageConfig = Import-PowerShellDataFile -LiteralPath $stageConfigPath -ErrorAction Stop
$expectedStageNames = @(
    'Check'
    'Refresh'
    'Setup'
    'Installers'
    'Graphics'
    'Windows'
    'Advanced'
)
$configuredStageNames = @(
    @($stageConfig.Stages) |
        Sort-Object -Property @{ Expression = { [int]$_['Order'] } } |
        ForEach-Object { [string]$_['Name'] }
)
Assert-BoostLabCondition (
    (($configuredStageNames -join '|') -eq ($expectedStageNames -join '|'))
) 'AXIS first-use wizard canonical stage order must match the project stage config explicit Order fields.'

$sampleStageNames = @($sampleState['Stages'] | ForEach-Object { [string]$_['Name'] })
Assert-BoostLabCondition (
    (($sampleStageNames -join '|') -eq ($expectedStageNames -join '|'))
) 'AXIS first-use wizard sample state must keep the exact canonical stage order.'

$samplePages = @($sampleState['Steps'])
$sampleSteps = @($sampleState['ToolSteps'])
Assert-BoostLabCondition ($samplePages.Count -eq 52) 'AXIS first-use wizard sample state should include intro-welcome, the 50 approved tool steps, and final-completion.'
Assert-BoostLabCondition ($sampleSteps.Count -eq 50) 'AXIS first-use wizard ToolSteps should include the approved Check/Refresh steps, the ten Setup steps, the four Installers-stage steps, the six Graphics-stage steps, the twenty-two Windows steps, and the two Advanced steps.'
$expectedStepOrder = @(
    'bios-information'
    'bios-settings'
    'reinstall'
    'unattended'
    'updates-drivers-block'
    'to-bios'
) + $setupStepOrder + @('installers') + $installersExtensionStepOrder + $graphicsStepOrder + $windowsStepOrder + $advancedStepOrder
$expectedPageOrder = @('intro-welcome') + $expectedStepOrder + @('final-completion')
Assert-BoostLabCondition ((@($samplePages | ForEach-Object { [string]$_['Id'] }) -join '|') -eq ($expectedPageOrder -join '|')) 'AXIS first-use wizard page order should be intro, the unchanged 50 tool steps, then final completion.'
Assert-BoostLabCondition ((@($sampleSteps | ForEach-Object { [string]$_['Id'] }) -join '|') -eq ($expectedStepOrder -join '|')) 'AXIS first-use wizard tool-step order should keep Check/Refresh, then Setup, then Installers, Graphics, Windows Part A, Windows Part B, and Advanced after Cleanup.'
$expectedStepTitles = @(
    'BIOS Drivers & Downloads'
    'BIOS Settings'
    $arabicReinstallTitle
    'AutoUnattend'
    'Updates Drivers Block'
    $arabicToBiosTitle
) + $setupStepTitles + @($arabicInstallersTitle) + $installersExtensionStepTitles + $graphicsStepTitles + $windowsStepTitles + $advancedStepTitles
Assert-BoostLabCondition ((@($sampleSteps | ForEach-Object { [string]$_['Title'] }) -join '|') -eq ($expectedStepTitles -join '|')) 'AXIS first-use wizard customer step title order changed.'
Assert-BoostLabCondition ([int]$sampleState['CurrentStepIndex'] -eq 0) 'AXIS first-use wizard should start on intro-welcome.'
Assert-BoostLabCondition ($sampleState['Step'] -eq $samplePages[0]) 'AXIS first-use wizard compatibility Step entry should be the first non-tool intro page.'
Assert-BoostLabCondition ($sampleState['FirstToolStep'] -eq $sampleSteps[0]) 'AXIS first-use wizard should preserve the first accepted tool step separately from non-tool pages.'
$introPage = [System.Collections.IDictionary]$samplePages[0]
$finalPage = [System.Collections.IDictionary]$samplePages[$samplePages.Count - 1]
Assert-BoostLabCondition ([string]$introPage['Id'] -eq 'intro-welcome') 'AXIS intro page should be first.'
Assert-BoostLabCondition ([string]$introPage['PageKind'] -eq 'IntroWelcome') 'AXIS intro page should be marked as a non-tool intro page.'
Assert-BoostLabCondition (-not [bool]$introPage['IsToolStep']) 'AXIS intro page must not be treated as a tool/runtime step.'
Assert-BoostLabCondition ([string]$introPage['Title'] -eq $axisIntroTitle) 'AXIS intro title changed.'
Assert-BoostLabCondition ([string]$introPage['Description'] -eq $axisIntroSubtitle) 'AXIS intro subtitle changed.'
Assert-BoostLabCondition ([string]$introPage['PrimaryActionLabel'] -eq $axisIntroPrimary) 'AXIS intro primary button text changed.'
Assert-BoostLabCondition ([string]$introPage['InformationCardTitle'] -eq $axisIntroInfoTitle) 'AXIS intro information title changed.'
Assert-BoostLabCondition ((@($introPage['InformationItems']) -join '|') -eq (@($axisIntroInfoBullet1, $axisIntroInfoBullet2, $axisIntroInfoBullet3) -join '|')) 'AXIS intro information bullets changed.'
Assert-BoostLabCondition ([bool]$introPage['HideStageStrip']) 'AXIS intro page should hide the stage strip.'
Assert-BoostLabCondition ([bool]$introPage['NoSupportCard'] -and [bool]$introPage['NoRequirementsCard'] -and [bool]$introPage['NoRuntimeStatus']) 'AXIS intro page should not expose support, requirements, or runtime status.'
Assert-BoostLabCondition ([string]$finalPage['Id'] -eq 'final-completion') 'AXIS final completion page should be last.'
Assert-BoostLabCondition ([string]$finalPage['PageKind'] -eq 'FinalCompletion') 'AXIS final page should be marked as a non-tool final page.'
Assert-BoostLabCondition (-not [bool]$finalPage['IsToolStep']) 'AXIS final page must not be treated as a tool/runtime step.'
Assert-BoostLabCondition ([string]$finalPage['Title'] -eq $axisFinalTitle) 'AXIS final completion title changed.'
Assert-BoostLabCondition ([string]$finalPage['Description'] -eq $axisFinalSubtitle) 'AXIS final completion subtitle changed.'
Assert-BoostLabCondition ([string]$finalPage['PrimaryActionLabel'] -eq $axisFinalButton) 'AXIS final completion button text changed.'
Assert-BoostLabCondition ([string]$finalPage['InformationCardTitle'] -eq $axisFinalInfoTitle) 'AXIS final completion information title changed.'
Assert-BoostLabCondition ((@($finalPage['InformationItems']) -join '|') -eq (@($axisFinalInfoBullet1, $axisFinalInfoBullet2, $axisFinalInfoBullet3) -join '|')) 'AXIS final completion information bullets changed.'
Assert-BoostLabCondition ([bool]$finalPage['AllStagesCompleted']) 'AXIS final page should mark every stage completed.'
Assert-BoostLabCondition ([bool]$finalPage['NoSupportCard'] -and [bool]$finalPage['NoRequirementsCard'] -and [bool]$finalPage['NoRuntimeStatus']) 'AXIS final page should not expose support, requirements, or runtime status.'
$mockHardwareProfile = [System.Collections.IDictionary]$sampleState['MockHardwareProfile']
Assert-BoostLabCondition ([string]$mockHardwareProfile['Marker'] -eq 'AxisFirstUseWizard.MockHardwareProfile') 'AXIS BIOS Settings prototype should expose a local mock hardware profile marker.'
Assert-BoostLabCondition ([string]$mockHardwareProfile['CpuVendor'] -eq 'Intel') 'AXIS BIOS Settings prototype mock CPU vendor should be Intel.'
Assert-BoostLabCondition ([string]$mockHardwareProfile['MotherboardVendor'] -eq 'MSI') 'AXIS BIOS Settings prototype mock motherboard vendor should be MSI.'
Assert-BoostLabCondition ([string]$mockHardwareProfile['Summary'] -eq 'CPU=Intel; Motherboard=MSI') 'AXIS BIOS Settings prototype mock profile should expose CPU=Intel and Motherboard=MSI markers.'
Assert-BoostLabCondition ([bool]$mockHardwareProfile['PrototypeOnly']) 'AXIS BIOS Settings mock hardware profile should be clearly prototype-only.'

$introContentHost = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.StepContentHost') | Select-Object -First 1
$introVisibleContent = $introContentHost.Child
$introVisibleText = (Get-AxisFirstUseWizardTextValues -Root $introVisibleContent) -join [Environment]::NewLine
$introStartButton = @(Get-AxisFirstUseWizardTaggedElements -Root $introVisibleContent -Tag 'AxisFirstUseWizard.IntroWelcomeStartButton') | Select-Object -First 1
$introBackButton = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.BackButton') | Select-Object -First 1
$introContinueButton = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.ContinueButton') | Select-Object -First 1
$introBottomNavigation = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.BottomNavigation') | Select-Object -First 1
$introStageStrip = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.StageProgressStrip') | Select-Object -First 1
$introTitleComposition = @(Get-AxisFirstUseWizardTaggedElements -Root $introVisibleContent -Tag 'AxisFirstUseWizard.IntroWelcomeAxisTitleVisualComposition') | Select-Object -First 1
$introInformationGroup = @(Get-AxisFirstUseWizardTaggedElements -Root $introVisibleContent -Tag 'AxisFirstUseWizard.IntroWelcomeInformationSharedPhysicalRightEdge') | Select-Object -First 1

Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $introVisibleContent -Tag 'AxisFirstUseWizard.IntroWelcomePage').Count -eq 1) 'AXIS intro page should be the default first visible page.'
Assert-BoostLabCondition ($introVisibleText.Contains($axisIntroSubtitle)) 'AXIS intro page should show the approved subtitle.'
Assert-BoostLabCondition ($introVisibleText.Contains($axisIntroInfoTitle)) 'AXIS intro page should show the approved information title.'
Assert-BoostLabCondition ($introVisibleText.Contains($axisIntroInfoBullet1) -and $introVisibleText.Contains($axisIntroInfoBullet2) -and $introVisibleText.Contains($axisIntroInfoBullet3)) 'AXIS intro page should show the approved information bullets.'
Assert-BoostLabCondition ($introTitleComposition -is [System.Windows.Controls.StackPanel]) 'AXIS intro title should use dedicated AXIS BiDi-safe visual composition.'
Assert-BoostLabCondition ([bool]$introTitleComposition.Resources['AxisFirstUseWizard.AxisInArabicTitleBidiSafe']) 'AXIS intro title should expose the AXIS-in-Arabic BiDi-safe marker.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($introInformationGroup) -eq 'AxisFirstUseWizard.IntroWelcomeInformationAxisBidiSafeText') 'AXIS intro information card should use the BiDi-safe shared text group.'
Assert-BoostLabCondition ($introStartButton -is [System.Windows.Controls.Button]) 'AXIS intro page should include one Start primary button.'
Assert-BoostLabCondition ([string]$introStartButton.Content -eq $axisIntroPrimary) 'AXIS intro Start button text changed.'
Assert-BoostLabCondition ([double]$introStartButton.Height -eq 42.0 -and [double]$introStartButton.Width -eq 118.0) 'AXIS intro Start button should keep no-clipping dimensions.'
Assert-BoostLabCondition ($introBottomNavigation.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS intro page should not show footer navigation.'
Assert-BoostLabCondition ($introBackButton.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS intro page should not show Previous.'
Assert-BoostLabCondition ($introContinueButton.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS intro page should not show Next.'
Assert-BoostLabCondition ($introStageStrip.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS intro page should hide the stage strip.'
Assert-BoostLabCondition ($prototype.RowDefinitions[1].Height.Value -eq 0.0 -and $prototype.RowDefinitions[3].Height.Value -eq 0.0) 'AXIS intro page should collapse stage and footer rows.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $introVisibleContent -Tag 'AxisFirstUseWizard.SupportPanel').Count -eq 0) 'AXIS intro page should not include a support card.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $introVisibleContent -Tag 'AxisFirstUseWizard.RuntimeStatusArea').Count -eq 0) 'AXIS intro page should not include runtime status.'
Assert-BoostLabCondition (-not $introVisibleText.Contains('BoostLab')) 'AXIS intro customer-facing copy must not mention BoostLab.'
Assert-BoostLabCondition (-not $introVisibleText.Contains('dashboard')) 'AXIS intro customer-facing copy must not mention a dashboard.'
Assert-BoostLabCondition (-not $introVisibleText.Contains([string][char]0xFFFD)) 'AXIS intro visible copy must not contain replacement glyphs.'

Invoke-AxisFirstUseWizardButtonClick -Button $introStartButton
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $introContentHost.Child -Tag 'AxisFirstUseWizard.BiosInformationStep').Count -eq 1) 'AXIS intro Start should advance to BIOS Drivers & Downloads.'
Assert-BoostLabCondition ($introBottomNavigation.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS BIOS page should restore footer navigation after intro Start.'
Assert-BoostLabCondition ($introStageStrip.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS BIOS page should restore the stage strip after intro Start.'
Assert-AxisFirstUseWizardNextDisabledNonBlue -Button $introContinueButton -Name 'BIOS Drivers & Downloads after intro Start'

$finalSampleState = Get-AxisFirstUseWizardSampleState
$finalIndex = @($finalSampleState['Steps']).Count - 1
$finalSampleState['CurrentStepIndex'] = $finalIndex
$finalSampleState['Step'] = $finalSampleState['Steps'][$finalIndex]
$finalPrototype = New-AxisFirstUseWizardPrototype -SampleState $finalSampleState
$finalContentHost = @(Get-AxisFirstUseWizardTaggedElements -Root $finalPrototype -Tag 'AxisFirstUseWizard.StepContentHost') | Select-Object -First 1
$finalVisibleContent = $finalContentHost.Child
$finalVisibleText = (Get-AxisFirstUseWizardTextValues -Root $finalVisibleContent) -join [Environment]::NewLine
$finalBackButton = @(Get-AxisFirstUseWizardTaggedElements -Root $finalPrototype -Tag 'AxisFirstUseWizard.BackButton') | Select-Object -First 1
$finalContinueButton = @(Get-AxisFirstUseWizardTaggedElements -Root $finalPrototype -Tag 'AxisFirstUseWizard.ContinueButton') | Select-Object -First 1
$finalButtonElement = @(Get-AxisFirstUseWizardTaggedElements -Root $finalPrototype -Tag 'AxisFirstUseWizard.FinalCompletionButton') | Select-Object -First 1
$finalStageStrip = @(Get-AxisFirstUseWizardTaggedElements -Root $finalPrototype -Tag 'AxisFirstUseWizard.StageProgressStrip') | Select-Object -First 1
$finalTitleComposition = @(Get-AxisFirstUseWizardTaggedElements -Root $finalVisibleContent -Tag 'AxisFirstUseWizard.FinalCompletionAxisTitleVisualComposition') | Select-Object -First 1
$finalInformationGroup = @(Get-AxisFirstUseWizardTaggedElements -Root $finalVisibleContent -Tag 'AxisFirstUseWizard.FinalCompletionInformationSharedPhysicalRightEdge') | Select-Object -First 1

Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $finalVisibleContent -Tag 'AxisFirstUseWizard.FinalCompletionPage').Count -eq 1) 'AXIS final completion page should render after the last tool step.'
Assert-BoostLabCondition ($finalVisibleText.Contains($axisFinalSubtitle)) 'AXIS final completion page should show the approved subtitle.'
Assert-BoostLabCondition ($finalVisibleText.Contains($axisFinalInfoTitle)) 'AXIS final completion page should show the approved information title.'
Assert-BoostLabCondition ($finalVisibleText.Contains($axisFinalInfoBullet1) -and $finalVisibleText.Contains($axisFinalInfoBullet2) -and $finalVisibleText.Contains($axisFinalInfoBullet3)) 'AXIS final completion page should show the approved information bullets.'
Assert-BoostLabCondition ($finalTitleComposition -is [System.Windows.Controls.StackPanel]) 'AXIS final title should use dedicated AXIS BiDi-safe visual composition.'
Assert-BoostLabCondition ([bool]$finalTitleComposition.Resources['AxisFirstUseWizard.AxisInArabicTitleBidiSafe']) 'AXIS final title should expose the AXIS-in-Arabic BiDi-safe marker.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($finalInformationGroup) -eq 'AxisFirstUseWizard.FinalCompletionInformationAxisBidiSafeText') 'AXIS final information card should use the BiDi-safe shared text group.'
Assert-BoostLabCondition ($finalBackButton.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS final completion page should show Previous.'
Assert-BoostLabCondition ($finalContinueButton.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS final completion page should not show Next.'
Assert-BoostLabCondition ($finalButtonElement.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS final completion page should show Finish.'
Assert-BoostLabCondition ([string]$finalButtonElement.Content -eq $axisFinalButton) 'AXIS final Finish button text changed.'
Assert-BoostLabCondition ([double]$finalButtonElement.Height -eq 40.0 -and [double]$finalButtonElement.Width -eq 104.0) 'AXIS final Finish button should keep no-clipping dimensions.'
Assert-BoostLabCondition ($finalStageStrip.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS final completion page should show the stage strip.'
foreach ($stageName in $expectedStageNames) {
    $finalStageFill = @(Get-AxisFirstUseWizardTaggedElements -Root $finalPrototype -Tag "AxisFirstUseWizard.StageProgressFill.$stageName") | Select-Object -First 1
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $finalStageFill -ExpectedAutomationId "AxisFirstUseWizard.StageLineCompletedFullGreen.$stageName" -ExpectedColor '#FF22C55E' -Name "final completion $stageName completed")
}
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $finalVisibleContent -Tag 'AxisFirstUseWizard.SupportPanel').Count -eq 0) 'AXIS final completion page should not include a support card.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $finalVisibleContent -Tag 'AxisFirstUseWizard.RuntimeStatusArea').Count -eq 0) 'AXIS final completion page should not include runtime status.'
Assert-BoostLabCondition (-not $finalVisibleText.Contains('BoostLab')) 'AXIS final customer-facing copy must not mention BoostLab.'
Assert-BoostLabCondition (-not $finalVisibleText.Contains('dashboard')) 'AXIS final customer-facing copy must not mention a dashboard.'
Assert-BoostLabCondition (-not $finalVisibleText.Contains([string][char]0xFFFD)) 'AXIS final visible copy must not contain replacement glyphs.'
Invoke-AxisFirstUseWizardButtonClick -Button $finalBackButton
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $finalContentHost.Child -Tag 'AxisFirstUseWizard.AdvancedDefenderOptimizeAssistantStep').Count -eq 1) 'AXIS final Previous should return to Defender Optimize Assistant.'

$toolStartSampleState = Get-AxisFirstUseWizardSampleState
$toolStartSampleState['CurrentStepIndex'] = 1
$toolStartSampleState['Step'] = $toolStartSampleState['Steps'][1]
$prototype = New-AxisFirstUseWizardPrototype -SampleState $toolStartSampleState
Assert-BoostLabCondition ([double]$prototype.RowDefinitions[1].Height.Value -eq 50.0) 'AXIS tool pages should restore the stage strip row height.'
Assert-BoostLabCondition ([double]$prototype.RowDefinitions[3].Height.Value -eq 72.0) 'AXIS tool pages should restore the footer row height for unclipped buttons.'

$toolPageIdsForInitialNext = @($toolStartSampleState['Steps'] | ForEach-Object { [string]$_['Id'] })
foreach ($toolStepForInitialNext in $sampleSteps) {
    $toolStepIdForInitialNext = [string]$toolStepForInitialNext['Id']
    $toolPageIndexForInitialNext = [Array]::IndexOf($toolPageIdsForInitialNext, $toolStepIdForInitialNext)
    Assert-BoostLabCondition ($toolPageIndexForInitialNext -ge 0) "AXIS initial Next regression guard should find tool page: $toolStepIdForInitialNext"

    $toolInitialNextSampleState = Get-AxisFirstUseWizardSampleState
    $toolInitialNextSampleState['CurrentStepIndex'] = $toolPageIndexForInitialNext
    $toolInitialNextSampleState['Step'] = $toolInitialNextSampleState['Steps'][$toolPageIndexForInitialNext]
    $toolInitialNextPrototype = New-AxisFirstUseWizardPrototype -SampleState $toolInitialNextSampleState
    $toolInitialNextButton = @(Get-AxisFirstUseWizardTaggedElements -Root $toolInitialNextPrototype -Tag 'AxisFirstUseWizard.ContinueButton') | Select-Object -First 1
    Assert-BoostLabCondition ($toolInitialNextButton -is [System.Windows.Controls.Button]) "AXIS initial Next regression guard should find Next button for $toolStepIdForInitialNext"
    Assert-AxisFirstUseWizardNextDisabledNonBlue -Button $toolInitialNextButton -Name "initial $toolStepIdForInitialNext"
}

$texts = @(Get-AxisFirstUseWizardTextValues -Root $prototype)
$joinedText = $texts -join [Environment]::NewLine
$oldArabicSubtitle = ConvertFrom-AxisWizardCodePoints @(
    0x062A, 0x062D, 0x0645, 0x064A, 0x0644, 0x0020,
    0x0627, 0x0644, 0x062A, 0x0639, 0x0631, 0x064A, 0x0641, 0x0627, 0x062A, 0x0020,
    0x0645, 0x0646, 0x0020,
    0x0635, 0x0641, 0x062D, 0x0629, 0x0020,
    0x0627, 0x0644, 0x0644, 0x0648, 0x062D, 0x0629, 0x0020,
    0x0627, 0x0644, 0x0627, 0x0645, 0x0020,
    0x0627, 0x0644, 0x0631, 0x0633, 0x0645, 0x064A
)
$oldArabicInfoTitle = ConvertFrom-AxisWizardCodePoints @(
    0x0645, 0x0627, 0x0020,
    0x0647, 0x0648, 0x0020,
    0x0639, 0x0644, 0x064A, 0x0643, 0x0020,
    0x062A, 0x062D, 0x0645, 0x064A, 0x0644, 0x0647, 0x0020,
    0x0643, 0x0627, 0x0644, 0x0627, 0x062A, 0x064A
)
$oldArabicNetworkDriver = ConvertFrom-AxisWizardCodePoints @(
    0x062A, 0x0639, 0x0631, 0x064A, 0x0641, 0x0020,
    0x0643, 0x0631, 0x062A, 0x0020,
    0x0627, 0x0644, 0x0634, 0x0628, 0x0643, 0x0629
)
$oldArabicAudioDriver = ConvertFrom-AxisWizardCodePoints @(
    0x062A, 0x0639, 0x0631, 0x064A, 0x0641, 0x0020,
    0x0643, 0x0631, 0x062A, 0x0020,
    0x0627, 0x0644, 0x0635, 0x0648, 0x062A
)
$oldArabicAcknowledgement = ConvertFrom-AxisWizardCodePoints @(
    0x0644, 0x0642, 0x062F, 0x0020,
    0x0642, 0x0631, 0x0627, 0x062A, 0x0020,
    0x0627, 0x0644, 0x062A, 0x0639, 0x0644, 0x064A, 0x0645, 0x0627, 0x062A
)
$oldArabicSupportBody = ConvertFrom-AxisWizardCodePoints @(
    0x064A, 0x0645, 0x0643, 0x0646, 0x0643, 0x0020,
    0x0627, 0x0644, 0x062A, 0x0648, 0x0627, 0x0635, 0x0644, 0x0020,
    0x0645, 0x0639, 0x0020,
    0x0627, 0x062E, 0x0635, 0x0627, 0x0626, 0x064A, 0x0020,
    0x0627, 0x0644, 0x062F, 0x0639, 0x0645, 0x0020,
    0x0645, 0x0646, 0x0020,
    0x062E, 0x0644, 0x0627, 0x0644, 0x0020,
    0x062E, 0x0627, 0x062F, 0x0645, 0x0020,
    0x0627, 0x0644, 0x062F, 0x0633, 0x0643, 0x0648, 0x0631, 0x062F, 0x0020,
    0x0627, 0x0644, 0x062E, 0x0627, 0x0635, 0x0020,
    0x0628, 0x0627, 0x0644, 0x0645, 0x062A, 0x062C, 0x0631
)

foreach ($requiredText in @(
    'AXIS'
    'Check'
    'BIOS Drivers & Downloads'
    $arabicSubtitle
    $arabicInfoTitle
    $arabicNetworkDriver
    $arabicAudioDriver
    $arabicOpen
    $arabicDocumentation
    $arabicBack
    $arabicNext
    $arabicReturn
    $arabicAcknowledgement
    $arabicSupportTitle
    $arabicSupportBody
)) {
    Assert-BoostLabCondition ($joinedText.Contains($requiredText)) "AXIS first-use wizard is missing expected visible/content text: $requiredText"
}
foreach ($oldText in @(
    $oldArabicSubtitle
    $oldArabicInfoTitle
    $oldArabicNetworkDriver
    $oldArabicAudioDriver
    $oldArabicAcknowledgement
    $oldArabicSupportBody
)) {
    Assert-BoostLabCondition (-not $joinedText.Contains($oldText)) "AXIS first-use wizard still exposes superseded Arabic wording: $oldText"
}
foreach ($rightAlignedText in @(
    $arabicSubtitle
    $arabicInfoTitle
    $arabicNetworkDriver
    $arabicAudioDriver
    $arabicSupportTitle
    $arabicSupportBody
)) {
    $matchingTextBlocks = @(Get-AxisFirstUseWizardTextBlocksContainingText -Root $prototype -Text $rightAlignedText)
    Assert-BoostLabCondition ($matchingTextBlocks.Count -ge 1) "AXIS first-use wizard missing text block for right-aligned Arabic text: $rightAlignedText"
    foreach ($textBlock in $matchingTextBlocks) {
        Assert-BoostLabCondition ($textBlock.FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) "Arabic text block should use RTL FlowDirection: $rightAlignedText"
        Assert-BoostLabCondition ($textBlock.TextAlignment -eq [System.Windows.TextAlignment]::Right) "Arabic text block should be right-aligned: $rightAlignedText"
        Assert-BoostLabCondition (
            $textBlock.HorizontalAlignment -in @(
                [System.Windows.HorizontalAlignment]::Right,
                [System.Windows.HorizontalAlignment]::Stretch
            )
        ) "Arabic text block should be physically right-anchored or stretched inside a shared right-origin group: $rightAlignedText"
    }
}
foreach ($stageName in $expectedStageNames) {
    Assert-BoostLabCondition ($joinedText.Contains($stageName)) "AXIS first-use wizard is missing canonical stage name: $stageName"
}

$strip = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.StageProgressStrip') | Select-Object -First 1
$stripGrid = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.StageProgressGrid') | Select-Object -First 1
$stripItems = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.StageProgressItem')
$initialCurrentStageHeader = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.CurrentStageHeader') | Select-Object -First 1
$stageProgressCheckFill = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.StageProgressFill.Check') | Select-Object -First 1
$stageProgressRefreshFill = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.StageProgressFill.Refresh') | Select-Object -First 1
$stageProgressSetupFill = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.StageProgressFill.Setup') | Select-Object -First 1
$stageProgressInstallersFill = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.StageProgressFill.Installers') | Select-Object -First 1
$stageProgressGraphicsFill = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.StageProgressFill.Graphics') | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $strip) 'AXIS first-use wizard stage progress strip is missing.'
Assert-BoostLabCondition ($null -ne $stripGrid) 'AXIS first-use wizard stage progress grid is missing.'
Assert-BoostLabCondition ($null -ne $initialCurrentStageHeader) 'AXIS first-use wizard current stage header is missing.'
Assert-BoostLabCondition ([string]$initialCurrentStageHeader.Text -eq 'Check') 'AXIS BIOS Drivers initial current stage header should be Check.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($strip) -eq 'AxisFirstUseWizard.StageStripNoPartialProgress') 'AXIS stage strip should expose the no-partial-progress marker.'
Assert-BoostLabCondition ($strip.FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) 'AXIS stage strip should be mirrored for RTL.'
Assert-BoostLabCondition ($stripGrid.FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) 'AXIS stage grid should be mirrored for RTL.'
Assert-BoostLabCondition ($stripItems.Count -eq $expectedStageNames.Count) 'AXIS stage progress should show canonical stage names only.'
Assert-BoostLabCondition ($null -ne $stageProgressCheckFill) 'AXIS stage progress Check fill marker is missing.'
Assert-BoostLabCondition ($null -ne $stageProgressRefreshFill) 'AXIS stage progress Refresh fill marker is missing.'
Assert-BoostLabCondition ($null -ne $stageProgressSetupFill) 'AXIS stage progress Setup fill marker is missing.'
Assert-BoostLabCondition ($null -ne $stageProgressInstallersFill) 'AXIS stage progress Installers fill marker is missing.'
Assert-BoostLabCondition ($null -ne $stageProgressGraphicsFill) 'AXIS stage progress Graphics fill marker is missing.'
[void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressCheckFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineActiveFullWhite.Check' -ExpectedColor '#FFF0F2F5' -Name 'BIOS Drivers Check active')
[void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressRefreshFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineInactiveDim.Refresh' -ExpectedColor '#FF242424' -Name 'BIOS Drivers Refresh inactive')
[void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressSetupFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineInactiveDim.Setup' -ExpectedColor '#FF242424' -Name 'BIOS Drivers Setup inactive')
[void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressInstallersFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineInactiveDim.Installers' -ExpectedColor '#FF242424' -Name 'BIOS Drivers Installers inactive')
[void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressGraphicsFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineInactiveDim.Graphics' -ExpectedColor '#FF242424' -Name 'BIOS Drivers Graphics inactive')
$activeStageItems = @(
    $stripItems |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_).StartsWith('AxisFirstUseWizard.StageProgressActive.') }
)
$completedStageItems = @(
    $stripItems |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_).StartsWith('AxisFirstUseWizard.StageProgressCompleted.') }
)
Assert-BoostLabCondition ($activeStageItems.Count -eq 1) 'AXIS stage strip should expose exactly one active stage marker.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($activeStageItems[0]) -eq 'AxisFirstUseWizard.StageProgressActive.Check') 'AXIS BIOS Drivers active stage marker should be Check.'
Assert-BoostLabCondition ($completedStageItems.Count -eq 0) 'AXIS BIOS Drivers should not mark a completed stage before Check is complete.'
$stripTexts = @(Get-AxisFirstUseWizardTextValues -Root $strip)
$stripStageOrder = @($stripTexts | Where-Object { $_ -in $expectedStageNames })
Assert-BoostLabCondition (
    (($stripStageOrder -join '|') -eq ($expectedStageNames -join '|'))
) 'AXIS stage progress strip logical stage order changed.'
Assert-BoostLabCondition (-not ('BIOS Drivers & Downloads' -in $stripTexts)) 'AXIS stage progress strip must show stage names only, not step/script names.'

$biosStep = $sampleSteps[0]
$biosSettingsStep = $sampleSteps[1]
$reinstallStep = $sampleSteps[2]
$autoUnattendStep = $sampleSteps[3]
$updatesDriversStep = $sampleSteps[4]
$toBiosStep = $sampleSteps[5]
$setupSteps = @($sampleSteps[6..15])
$installersStep = [System.Collections.IDictionary]$sampleSteps[16]
$installersExtensionSteps = @($sampleSteps[17..19])
$installersStartupAppsSettingsStep = [System.Collections.IDictionary]$sampleSteps[17]
$installersStartupAppsTaskManagerStep = [System.Collections.IDictionary]$sampleSteps[18]
$restartAfterInstallersStep = [System.Collections.IDictionary]$sampleSteps[19]
$graphicsSteps = @($sampleSteps[20..25])
$driverCleanStep = [System.Collections.IDictionary]$sampleSteps[20]
$gpuDriverSetupStep = [System.Collections.IDictionary]$sampleSteps[21]
$nvidiaAppInstallStep = [System.Collections.IDictionary]$sampleSteps[22]
$directXStep = [System.Collections.IDictionary]$sampleSteps[23]
$visualCppStep = [System.Collections.IDictionary]$sampleSteps[24]
$graphicsConfigurationCenterStep = [System.Collections.IDictionary]$sampleSteps[25]
$windowsPartASteps = @($sampleSteps[26..36])
$startMenuTaskbarStep = [System.Collections.IDictionary]$sampleSteps[26]
$startMenuLayoutStep = [System.Collections.IDictionary]$sampleSteps[27]
$contextMenuStep = [System.Collections.IDictionary]$sampleSteps[28]
$themeBlackStep = [System.Collections.IDictionary]$sampleSteps[29]
$blackLockScreenWallpaperStep = [System.Collections.IDictionary]$sampleSteps[30]
$blackAccountPicturesStep = [System.Collections.IDictionary]$sampleSteps[31]
$widgetsStep = [System.Collections.IDictionary]$sampleSteps[32]
$copilotStep = [System.Collections.IDictionary]$sampleSteps[33]
$gameModeStep = [System.Collections.IDictionary]$sampleSteps[34]
$pointerPrecisionStep = [System.Collections.IDictionary]$sampleSteps[35]
$bloatwareStep = [System.Collections.IDictionary]$sampleSteps[36]
$windowsPartBSteps = @($sampleSteps[37..47])
$windowsSteps = @($sampleSteps[26..47])
$gameBarStep = [System.Collections.IDictionary]$sampleSteps[37]
$edgeWebViewStep = [System.Collections.IDictionary]$sampleSteps[38]
$notepadSettingsStep = [System.Collections.IDictionary]$sampleSteps[39]
$controlPanelSettingsStep = [System.Collections.IDictionary]$sampleSteps[40]
$inputLanguageHotkeyStep = [System.Collections.IDictionary]$sampleSteps[41]
$soundStep = [System.Collections.IDictionary]$sampleSteps[42]
$deviceManagerPowerSavingsWakeStep = [System.Collections.IDictionary]$sampleSteps[43]
$networkAdapterPowerSavingsWakeStep = [System.Collections.IDictionary]$sampleSteps[44]
$writeCacheBufferFlushingStep = [System.Collections.IDictionary]$sampleSteps[45]
$powerPlanStep = [System.Collections.IDictionary]$sampleSteps[46]
$cleanupStep = [System.Collections.IDictionary]$sampleSteps[47]
$advancedSteps = @($sampleSteps[48..49])
$timerResolutionAssistantStep = [System.Collections.IDictionary]$sampleSteps[48]
$defenderOptimizeAssistantStep = [System.Collections.IDictionary]$sampleSteps[49]
Assert-BoostLabCondition ([string]$biosStep['Id'] -eq 'bios-information') 'AXIS first-use wizard internal tool id changed.'
Assert-BoostLabCondition ([string]$biosStep['Title'] -eq 'BIOS Drivers & Downloads') 'AXIS first-use wizard customer title changed.'
Assert-BoostLabCondition ([string]$biosStep['StageName'] -eq 'Check') 'AXIS first-use wizard customer stage label changed.'
Assert-BoostLabCondition ([string]$biosStep['CustomerAction'] -eq 'Open') 'AXIS first-use wizard customer action should map to Open.'
Assert-BoostLabCondition ((@($biosStep['CustomerVisibleActions']) -join '|') -eq 'Open') 'AXIS first-use wizard should expose only Open to the customer.'
Assert-BoostLabCondition (-not ('Analyze' -in @($biosStep['CustomerVisibleActions']))) 'AXIS first-use wizard must not expose Analyze as a customer action.'
Assert-BoostLabCondition (-not [bool]$biosStep['ShowRequirements']) 'AXIS first-use wizard requirements card should be absent for this step.'
Assert-BoostLabCondition ([string]$biosSettingsStep['Id'] -eq 'bios-settings') 'AXIS BIOS Settings internal tool id should be bios-settings.'
Assert-BoostLabCondition ([string]$biosSettingsStep['Title'] -eq 'BIOS Settings') 'AXIS BIOS Settings customer title changed.'
Assert-BoostLabCondition ([string]$biosSettingsStep['StageName'] -eq 'Check') 'AXIS BIOS Settings customer stage label should remain Check.'
Assert-BoostLabCondition ([string]$biosSettingsStep['CustomerAction'] -eq 'Open') 'AXIS BIOS Settings customer restart label should map to internal Open later.'
Assert-BoostLabCondition ((@($biosSettingsStep['CustomerVisibleActions']) -join '|') -eq 'Open') 'AXIS BIOS Settings should expose only the Open path to the customer.'
Assert-BoostLabCondition (-not ('Analyze' -in @($biosSettingsStep['CustomerVisibleActions']))) 'AXIS BIOS Settings must not expose Analyze as a customer action.'
Assert-BoostLabCondition (-not ('Apply' -in @($biosSettingsStep['CustomerVisibleActions']))) 'AXIS BIOS Settings must not expose Apply as a customer action.'
Assert-BoostLabCondition (-not ('Default' -in @($biosSettingsStep['CustomerVisibleActions']))) 'AXIS BIOS Settings must not expose Default as a customer action.'
Assert-BoostLabCondition (-not ('Restore' -in @($biosSettingsStep['CustomerVisibleActions']))) 'AXIS BIOS Settings must not expose Restore as a customer action.'
Assert-BoostLabCondition (-not [bool]$biosSettingsStep['ShowRequirements']) 'AXIS BIOS Settings requirements card should be absent.'
Assert-BoostLabCondition (-not $biosSettingsStep.Contains('RequirementsTitle')) 'AXIS BIOS Settings sample state should not carry a visible requirements title.'
Assert-BoostLabCondition (-not $biosSettingsStep.Contains('RequirementsItems')) 'AXIS BIOS Settings sample state should not carry visible requirements items.'
Assert-BoostLabCondition ([string]$biosSettingsStep['HardwareAwarePrototypeMarker'] -eq 'AxisFirstUseWizard.BiosSettingsHardwareAwarePrototype') 'AXIS BIOS Settings should carry the hardware-aware prototype marker.'
Assert-BoostLabCondition (-not $biosSettingsStep.Contains('VisibleProcessorGroupMarker')) 'AXIS BIOS Settings should not expose an Intel group header marker after Phase 178D copy trimming.'
Assert-BoostLabCondition ([string]$biosSettingsStep['VisibleMotherboardUtilityMarker'] -eq 'BiosSettingsVisibleMsiUtility') 'AXIS BIOS Settings should mark the visible MSI utility.'
Assert-BoostLabCondition ([string]$reinstallStep['Id'] -eq 'reinstall') 'AXIS Reinstall internal tool id should be reinstall.'
Assert-BoostLabCondition ([string]$reinstallStep['Title'] -eq $arabicReinstallTitle) 'AXIS Reinstall customer title changed.'
Assert-BoostLabCondition ([string]$reinstallStep['StageName'] -eq 'Refresh') 'AXIS Reinstall customer stage label should be Refresh.'
Assert-BoostLabCondition ([string]$reinstallStep['PrimaryActionLabel'] -eq $arabicReinstallPrimaryAction) 'AXIS Reinstall primary action label changed.'
Assert-BoostLabCondition ([string]$reinstallStep['CheckingStatusTitle'] -eq $arabicReinstallRunning) 'AXIS Reinstall running status label changed.'
Assert-BoostLabCondition ([string]$reinstallStep['CompletedStatusTitle'] -eq $arabicReinstallCompleted) 'AXIS Reinstall completed status label changed.'
Assert-BoostLabCondition ([bool]$reinstallStep['ShowRequirements']) 'AXIS Reinstall should show the owner-approved requirements card.'
Assert-BoostLabCondition (-not [bool]$reinstallStep['RequiresConfirmationAcknowledgement']) 'AXIS Reinstall must not require a confirmation acknowledgement overlay.'
Assert-BoostLabCondition ([bool]$reinstallStep['NoConfirmationOverlay']) 'AXIS Reinstall should carry the no-confirmation overlay marker.'
Assert-BoostLabCondition ([bool]$reinstallStep['PrototypeOnlySimulation']) 'AXIS Reinstall should be marked as prototype-only simulation.'
Assert-BoostLabCondition ((@($reinstallStep['CustomerVisibleActions']) -join '|') -eq $arabicReinstallPrimaryAction) 'AXIS Reinstall should expose only the owner-approved Arabic customer action label.'
Assert-BoostLabCondition (-not ('Analyze' -in @($reinstallStep['CustomerVisibleActions']))) 'AXIS Reinstall must not expose Analyze as a customer action.'
Assert-BoostLabCondition (-not ('Open' -in @($reinstallStep['CustomerVisibleActions']))) 'AXIS Reinstall must not expose Open as a customer action.'
Assert-BoostLabCondition (-not ('Apply' -in @($reinstallStep['CustomerVisibleActions']))) 'AXIS Reinstall must not expose Apply as a customer action.'
Assert-BoostLabCondition (-not ('Default' -in @($reinstallStep['CustomerVisibleActions']))) 'AXIS Reinstall must not expose Default as a customer action.'
Assert-BoostLabCondition (-not ('Restore' -in @($reinstallStep['CustomerVisibleActions']))) 'AXIS Reinstall must not expose Restore as a customer action.'
Assert-BoostLabCondition ([string]$autoUnattendStep['Id'] -eq 'unattended') 'AXIS AutoUnattend internal tool id should be unattended.'
Assert-BoostLabCondition ([string]$autoUnattendStep['Title'] -eq 'AutoUnattend') 'AXIS AutoUnattend customer title changed.'
Assert-BoostLabCondition ([string]$autoUnattendStep['StageName'] -eq 'Refresh') 'AXIS AutoUnattend customer stage label should be Refresh.'
Assert-BoostLabCondition ([string]$autoUnattendStep['PrimaryActionLabel'] -eq $arabicAutoUnattendPrimaryAction) 'AXIS AutoUnattend primary action label changed.'
Assert-BoostLabCondition ([string]$autoUnattendStep['CheckingStatusTitle'] -eq $arabicAutoUnattendRunning) 'AXIS AutoUnattend running status label changed.'
Assert-BoostLabCondition ([string]$autoUnattendStep['CompletedStatusTitle'] -eq $arabicAutoUnattendCompleted) 'AXIS AutoUnattend completed status label changed.'
Assert-BoostLabCondition ([bool]$autoUnattendStep['ShowRequirements']) 'AXIS AutoUnattend should show the owner-approved requirements card.'
Assert-BoostLabCondition (-not [bool]$autoUnattendStep['RequiresConfirmationAcknowledgement']) 'AXIS AutoUnattend must not require a confirmation acknowledgement overlay.'
Assert-BoostLabCondition ([bool]$autoUnattendStep['RequiresInputWindow']) 'AXIS AutoUnattend should require the input-window prototype path.'
Assert-BoostLabCondition ([bool]$autoUnattendStep['NoConfirmationOverlay']) 'AXIS AutoUnattend should carry the no-confirmation overlay marker.'
Assert-BoostLabCondition ([bool]$autoUnattendStep['PrototypeOnlySimulation']) 'AXIS AutoUnattend should be marked as prototype-only simulation.'
Assert-BoostLabCondition ((@($autoUnattendStep['CustomerVisibleActions']) -join '|') -eq $arabicAutoUnattendPrimaryAction) 'AXIS AutoUnattend should expose only the owner-approved Arabic customer action label.'
Assert-BoostLabCondition (-not ('Analyze' -in @($autoUnattendStep['CustomerVisibleActions']))) 'AXIS AutoUnattend must not expose Analyze as a customer action.'
Assert-BoostLabCondition (-not ('Open' -in @($autoUnattendStep['CustomerVisibleActions']))) 'AXIS AutoUnattend must not expose Open as a customer action.'
Assert-BoostLabCondition (-not ('Apply' -in @($autoUnattendStep['CustomerVisibleActions']))) 'AXIS AutoUnattend must not expose Apply as a customer action.'
Assert-BoostLabCondition (-not ('Default' -in @($autoUnattendStep['CustomerVisibleActions']))) 'AXIS AutoUnattend must not expose Default as a customer action.'
Assert-BoostLabCondition (-not ('Restore' -in @($autoUnattendStep['CustomerVisibleActions']))) 'AXIS AutoUnattend must not expose Restore as a customer action.'
Assert-BoostLabCondition ([string]$updatesDriversStep['Id'] -eq 'updates-drivers-block') 'AXIS Updates Drivers Block internal tool id should be updates-drivers-block.'
Assert-BoostLabCondition ([string]$updatesDriversStep['Title'] -eq 'Updates Drivers Block') 'AXIS Updates Drivers Block customer title changed.'
Assert-BoostLabCondition ([string]$updatesDriversStep['StageName'] -eq 'Refresh') 'AXIS Updates Drivers Block customer stage label should be Refresh.'
Assert-BoostLabCondition ([string]$updatesDriversStep['PrimaryActionLabel'] -eq $arabicUpdatesDriversPrimaryAction) 'AXIS Updates Drivers Block primary action label changed.'
Assert-BoostLabCondition ([string]$updatesDriversStep['CheckingStatusTitle'] -eq $arabicUpdatesDriversRunning) 'AXIS Updates Drivers Block running status label changed.'
Assert-BoostLabCondition ([string]$updatesDriversStep['CompletedStatusTitle'] -eq $arabicUpdatesDriversCompleted) 'AXIS Updates Drivers Block completed status label changed.'
Assert-BoostLabCondition ([bool]$updatesDriversStep['ShowRequirements']) 'AXIS Updates Drivers Block should show the owner-approved requirements card.'
Assert-BoostLabCondition (-not [bool]$updatesDriversStep['RequiresConfirmationAcknowledgement']) 'AXIS Updates Drivers Block must not require a confirmation acknowledgement overlay.'
Assert-BoostLabCondition ([bool]$updatesDriversStep['RequiresInputWindow']) 'AXIS Updates Drivers Block should require the input-window prototype path.'
Assert-BoostLabCondition (-not [bool]$updatesDriversStep['RequiresAccountName']) 'AXIS Updates Drivers Block input window should be USB-only.'
Assert-BoostLabCondition ([bool]$updatesDriversStep['NoConfirmationOverlay']) 'AXIS Updates Drivers Block should carry the no-confirmation overlay marker.'
Assert-BoostLabCondition ([bool]$updatesDriversStep['PrototypeOnlySimulation']) 'AXIS Updates Drivers Block should be marked as prototype-only simulation.'
Assert-BoostLabCondition ((@($updatesDriversStep['CustomerVisibleActions']) -join '|') -eq $arabicUpdatesDriversPrimaryAction) 'AXIS Updates Drivers Block should expose only the owner-approved Arabic customer action label.'
Assert-BoostLabCondition (-not ('Analyze' -in @($updatesDriversStep['CustomerVisibleActions']))) 'AXIS Updates Drivers Block must not expose Analyze as a customer action.'
Assert-BoostLabCondition (-not ('Open' -in @($updatesDriversStep['CustomerVisibleActions']))) 'AXIS Updates Drivers Block must not expose Open as a customer action.'
Assert-BoostLabCondition (-not ('Apply' -in @($updatesDriversStep['CustomerVisibleActions']))) 'AXIS Updates Drivers Block must not expose Apply as a customer action.'
Assert-BoostLabCondition (-not ('Default' -in @($updatesDriversStep['CustomerVisibleActions']))) 'AXIS Updates Drivers Block must not expose Default as a customer action.'
Assert-BoostLabCondition (-not ('Restore' -in @($updatesDriversStep['CustomerVisibleActions']))) 'AXIS Updates Drivers Block must not expose Restore as a customer action.'
Assert-BoostLabCondition ([string]$arabicToBiosTitle -eq 'To BIOS') 'AXIS To BIOS customer title should now be English-only.'
Assert-BoostLabCondition ([string]$toBiosStep['Id'] -eq 'to-bios') 'AXIS To BIOS internal tool id should be to-bios.'
Assert-BoostLabCondition ([string]$toBiosStep['Title'] -eq $arabicToBiosTitle) 'AXIS To BIOS customer title changed.'
Assert-BoostLabCondition ([string]$toBiosStep['StageName'] -eq 'Refresh') 'AXIS To BIOS customer stage label should be Refresh.'
Assert-BoostLabCondition ([string]$toBiosStep['PrimaryActionLabel'] -eq $arabicToBiosPrimaryAction) 'AXIS To BIOS primary action label changed.'
Assert-BoostLabCondition ([string]$toBiosStep['CheckingStatusTitle'] -eq $arabicRestarting) 'AXIS To BIOS running status label changed.'
Assert-BoostLabCondition ([string]$toBiosStep['CompletedStatusTitle'] -eq $arabicCompleted) 'AXIS To BIOS completed status label changed.'
Assert-BoostLabCondition (-not [bool]$toBiosStep['ShowRequirements']) 'AXIS To BIOS must not show a requirements card.'
Assert-BoostLabCondition (-not $toBiosStep.Contains('RequirementsTitle')) 'AXIS To BIOS sample state should not carry a visible requirements title.'
Assert-BoostLabCondition (-not $toBiosStep.Contains('RequirementsItems')) 'AXIS To BIOS sample state should not carry visible requirements items.'
Assert-BoostLabCondition ([bool]$toBiosStep['RequiresConfirmationAcknowledgement']) 'AXIS To BIOS should require the confirmation acknowledgement overlay.'
Assert-BoostLabCondition (-not [bool]$toBiosStep['RequiresInputWindow']) 'AXIS To BIOS must not use an input window.'
Assert-BoostLabCondition ([bool]$toBiosStep['PrototypeOnlySimulation']) 'AXIS To BIOS should be marked as prototype-only simulation.'
Assert-BoostLabCondition ([string]$toBiosStep['CustomerAction'] -eq 'Open') 'AXIS To BIOS should retain the future internal Open mapping as data.'
Assert-BoostLabCondition ([string]$toBiosStep['FutureInternalAction'] -eq 'Open') 'AXIS To BIOS should record future internal Open mapping only.'
Assert-BoostLabCondition ((@($toBiosStep['CustomerVisibleActions']) -join '|') -eq $arabicToBiosPrimaryAction) 'AXIS To BIOS should expose only the owner-approved Arabic customer action label.'
Assert-BoostLabCondition (-not ('Analyze' -in @($toBiosStep['CustomerVisibleActions']))) 'AXIS To BIOS must not expose Analyze as a customer action.'
Assert-BoostLabCondition (-not ('Open' -in @($toBiosStep['CustomerVisibleActions']))) 'AXIS To BIOS must not expose Open as customer-facing action text.'
Assert-BoostLabCondition (-not ('Apply' -in @($toBiosStep['CustomerVisibleActions']))) 'AXIS To BIOS must not expose Apply as a customer action.'
Assert-BoostLabCondition (-not ('Default' -in @($toBiosStep['CustomerVisibleActions']))) 'AXIS To BIOS must not expose Default as a customer action.'
Assert-BoostLabCondition (-not ('Restore' -in @($toBiosStep['CustomerVisibleActions']))) 'AXIS To BIOS must not expose Restore as a customer action.'

Assert-BoostLabCondition ($setupSteps.Count -eq $setupStepSpecs.Count) 'AXIS Setup batch should include exactly ten steps after To BIOS.'
for ($setupIndex = 0; $setupIndex -lt $setupStepSpecs.Count; $setupIndex++) {
    $setupSpec = [System.Collections.IDictionary]$setupStepSpecs[$setupIndex]
    $setupStep = [System.Collections.IDictionary]$setupSteps[$setupIndex]
    $setupName = [string]$setupSpec['Id']
    Assert-BoostLabCondition ([string]$setupStep['Id'] -eq [string]$setupSpec['Id']) "AXIS Setup step order changed at index $setupIndex."
    Assert-BoostLabCondition ([string]$setupStep['Title'] -eq [string]$setupSpec['Title']) "AXIS Setup title changed for $setupName."
    Assert-BoostLabCondition ([string]$setupStep['StageName'] -eq 'Setup') "AXIS Setup step should be in Setup stage: $setupName"
    Assert-BoostLabCondition ([string]$setupStep['PrimaryActionLabel'] -eq [string]$setupSpec['Primary']) "AXIS Setup primary action changed for $setupName."
    Assert-BoostLabCondition ([string]$setupStep['Description'] -eq [string]$setupSpec['Subtitle']) "AXIS Setup subtitle changed for $setupName."
    Assert-BoostLabCondition ([string]$setupStep['InformationCardTitle'] -eq [string]$setupSpec['InfoTitle']) "AXIS Setup information title changed for $setupName."
    Assert-BoostLabCondition ((@($setupStep['InformationItems']) -join '|') -eq (@($setupSpec['InfoItems']) -join '|')) "AXIS Setup information bullets changed for $setupName."
    Assert-BoostLabCondition ([string]$setupStep['CheckingStatusTitle'] -eq [string]$setupSpec['Running']) "AXIS Setup running status changed for $setupName."
    Assert-BoostLabCondition ([string]$setupStep['CompletedStatusTitle'] -eq [string]$setupSpec['Completed']) "AXIS Setup completed status changed for $setupName."
    Assert-BoostLabCondition ([string]$setupStep['CompletionStateLabel'] -eq [string]$setupSpec['Completed']) "AXIS Setup completion label changed for $setupName."
    Assert-BoostLabCondition ([bool]$setupStep['PrototypeOnlySimulation']) "AXIS Setup step should be prototype-only simulation: $setupName"
    Assert-BoostLabCondition ([string]$setupStep['SetupStageBatchMarker'] -eq 'AxisFirstUseWizard.SetupStageBatchPrototypeOnly') "AXIS Setup step should expose the batch prototype-only marker: $setupName"
    Assert-BoostLabCondition ([string]$setupStep['NoRealActionMarker'] -eq 'AxisFirstUseWizard.SetupPrototypeOnlyNoRuntimeAction') "AXIS Setup step should expose the no-real-action marker: $setupName"
    Assert-BoostLabCondition ([string]$setupStep['CustomerAction'] -eq [string]$setupSpec['CustomerAction']) "AXIS Setup internal action mapping changed for $setupName."
    Assert-BoostLabCondition ([string]$setupStep['FutureInternalAction'] -eq [string]$setupSpec['FutureInternalAction']) "AXIS Setup future internal action changed for $setupName."
    Assert-BoostLabCondition ((@($setupStep['CustomerVisibleActions']) -join '|') -eq [string]$setupSpec['Primary']) "AXIS Setup customer-visible action should be the owner-approved label only: $setupName"
    foreach ($forbiddenSetupCustomerAction in @('Analyze', 'Apply', 'Default', 'Restore')) {
        Assert-BoostLabCondition (-not ($forbiddenSetupCustomerAction -in @($setupStep['CustomerVisibleActions']))) "AXIS Setup step must not expose internal action text $forbiddenSetupCustomerAction as customer-visible action: $setupName"
    }
    if ([string]$setupSpec['CustomerAction'] -ne 'Open') {
        Assert-BoostLabCondition (-not ('Open' -in @($setupStep['CustomerVisibleActions']))) "AXIS Setup non-Open step must not expose Open as customer-facing action text: $setupName"
    }

    if (@($setupSpec['Requirements']).Count -gt 0) {
        Assert-BoostLabCondition ([bool]$setupStep['ShowRequirements']) "AXIS Setup requirements card should be present for $setupName."
        Assert-BoostLabCondition ((@($setupStep['RequirementsItems']) -join '|') -eq (@($setupSpec['Requirements']) -join '|')) "AXIS Setup requirements copy changed for $setupName."
    }
    else {
        Assert-BoostLabCondition (-not [bool]$setupStep['ShowRequirements']) "AXIS Setup requirements card should be absent for $setupName."
        Assert-BoostLabCondition (-not $setupStep.Contains('RequirementsItems')) "AXIS Setup no-requirements step should not carry requirements items: $setupName"
    }

    if ([bool]$setupSpec['Overlay']) {
        Assert-BoostLabCondition ([bool]$setupStep['RequiresConfirmationAcknowledgement']) "AXIS Setup overlay should be enabled for $setupName."
        Assert-BoostLabCondition ([string]$setupStep['DocumentationAcknowledgementText'] -eq [string]$setupSpec['Checkbox']) "AXIS Setup overlay checkbox text changed for $setupName."
        Assert-BoostLabCondition ([string]$setupStep['ConfirmationActionLabel'] -eq [string]$setupSpec['ConfirmationPrimary']) "AXIS Setup overlay primary text changed for $setupName."
        Assert-BoostLabCondition ([string]$setupStep['ConfirmationReturnLabel'] -eq [string]$setupSpec['ConfirmationReturn']) "AXIS Setup overlay return text changed for $setupName."
    }
    else {
        Assert-BoostLabCondition (-not [bool]$setupStep['RequiresConfirmationAcknowledgement']) "AXIS Setup overlay should be absent for $setupName."
        Assert-BoostLabCondition ([bool]$setupStep['NoConfirmationOverlay']) "AXIS Setup no-overlay marker should be present for $setupName."
    }

    if ([bool](Get-AxisWizardMapValue -Map $setupSpec -Name 'OpenMappedPrototypeOnly' -DefaultValue $false)) {
        Assert-BoostLabCondition ([bool]$setupStep['OpenMappedPrototypeOnly']) "AXIS Setup Open-mapped step should be prototype-only: $setupName"
    }
}

Assert-BoostLabCondition ([string]$installersStep['Id'] -eq 'installers') 'AXIS Installers internal tool id should be installers.'
Assert-BoostLabCondition ([string]$installersStep['Title'] -eq $arabicInstallersTitle) 'AXIS Installers customer title changed.'
Assert-BoostLabCondition ([string]$installersStep['StageName'] -eq 'Installers') 'AXIS Installers customer stage label should be Installers.'
Assert-BoostLabCondition ([string]$installersStep['PrimaryActionLabel'] -eq 'Install') 'AXIS Installers primary action label should be English-only Install.'
Assert-BoostLabCondition ([string]$installersStep['Description'] -eq $arabicInstallersSubtitle) 'AXIS Installers subtitle changed.'
Assert-BoostLabCondition ([string]$installersStep['InformationCardTitle'] -eq $arabicInstallersInfoTitle) 'AXIS Installers information title changed.'
Assert-BoostLabCondition ((@($installersStep['InformationItems']) -join '|') -eq (@($arabicInstallersInfoBullet1, $arabicInstallersInfoBullet2, $arabicInstallersInfoBullet3) -join '|')) 'AXIS Installers information bullets changed.'
Assert-BoostLabCondition ([bool]$installersStep['ShowRequirements']) 'AXIS Installers should show the owner-approved requirements card.'
Assert-BoostLabCondition ((@($installersStep['RequirementsItems']) -join '|') -eq (@($arabicInstallersRequirement1, $arabicInstallersRequirement2) -join '|')) 'AXIS Installers requirements bullets changed.'
Assert-BoostLabCondition ([string]$installersStep['CheckingStatusTitle'] -eq $arabicInstallersRunning) 'AXIS Installers running status label changed.'
Assert-BoostLabCondition ([string]$installersStep['CompletedStatusTitle'] -eq $arabicInstallersCompleted) 'AXIS Installers completed status label changed.'
Assert-BoostLabCondition (-not [bool]$installersStep['RequiresConfirmationAcknowledgement']) 'AXIS Installers must not require a confirmation acknowledgement overlay.'
Assert-BoostLabCondition (-not [bool]$installersStep['RequiresInputWindow']) 'AXIS Installers must not use an input window.'
Assert-BoostLabCondition ([bool]$installersStep['NoConfirmationOverlay']) 'AXIS Installers should carry the no-confirmation overlay marker.'
Assert-BoostLabCondition ([bool]$installersStep['PrimaryActionRequiresSelection']) 'AXIS Installers Install button should require a program selection.'
Assert-BoostLabCondition ([bool]$installersStep['PrototypeOnlySimulation']) 'AXIS Installers should be marked as prototype-only simulation.'
Assert-BoostLabCondition ([string]$installersStep['NoRealActionMarker'] -eq 'AxisFirstUseWizard.InstallersPrototypeOnlyNoRuntimeAction') 'AXIS Installers should expose the prototype-only no-real-action marker.'
Assert-BoostLabCondition ([string]$installersStep['CustomerAction'] -eq 'Apply') 'AXIS Installers should retain the future internal Apply mapping as data.'
Assert-BoostLabCondition ([string]$installersStep['FutureInternalAction'] -eq 'Apply') 'AXIS Installers should record future internal Apply mapping only.'
Assert-BoostLabCondition ((@($installersStep['CustomerVisibleActions']) -join '|') -eq 'Install') 'AXIS Installers should expose only the owner-approved Install action.'
Assert-BoostLabCondition ([string]$installersStep['InstallerEpicInstructionOverlayTitle'] -eq $arabicInstallersEpicOverlayTitle) 'AXIS Installers Epic overlay title changed.'
Assert-BoostLabCondition ((@($installersStep['InstallerEpicInstructionOverlayItems']) -join '|') -eq (@($arabicInstallersEpicOverlayBody1, $arabicInstallersEpicOverlayBody2, $arabicInstallersEpicOverlayBody3) -join '|')) 'AXIS Installers Epic overlay body changed.'
Assert-BoostLabCondition ([string]$installersStep['InstallerEpicInstructionOverlayReturnLabel'] -eq $arabicInstallersEpicOverlayReturn) 'AXIS Installers Epic overlay return label changed.'
Assert-BoostLabCondition ([string]$installersStep['InstallerEpicInstructionOverlayMarker'] -eq 'AxisFirstUseWizard.InstallersEpicInstructionOverlayPrototypeOnly') 'AXIS Installers Epic overlay should remain prototype-only.'
foreach ($forbiddenInstallersCustomerAction in @('Analyze', 'Apply', 'Open', 'Default', 'Restore')) {
    Assert-BoostLabCondition (-not ($forbiddenInstallersCustomerAction -in @($installersStep['CustomerVisibleActions']))) "AXIS Installers must not expose internal action text as customer-visible action: $forbiddenInstallersCustomerAction"
}
Assert-BoostLabCondition ((@($installersStep['InstallerCatalogNames']) -join '|') -eq ($expectedInstallersCatalogNames -join '|')) 'AXIS Installers selector catalog should use the current BoostLab retained installer catalog names.'
Assert-BoostLabCondition ($expectedInstallersCatalogNames.Count -ge 16) 'AXIS Installers catalog should include the retained installer app names.'
Assert-BoostLabCondition ('Epic Games' -in @($installersStep['InstallerCatalogNames'])) 'AXIS Installers catalog should include the current Epic Games retained catalog item.'
foreach ($removedInstallerName in @('Escape From Tarkov', 'Frame View', 'GOG launcher', 'Notepad ++', 'Nvidia App', 'Onboard Memory Manager', 'Pot Player', 'Exit')) {
    Assert-BoostLabCondition (-not ($removedInstallerName -in @($installersStep['InstallerCatalogNames']))) "AXIS Installers selector must not include removed/non-selectable catalog item: $removedInstallerName"
}

$expectedInstallersStageOrder = @(
    'installers'
    'installers-startup-apps-settings'
    'installers-startup-apps-task-manager'
    'restart-after-installers'
)
$actualInstallersStageOrder = @($sampleSteps | Where-Object { [string]$_['StageName'] -eq 'Installers' } | ForEach-Object { [string]$_['Id'] })
Assert-BoostLabCondition (($actualInstallersStageOrder -join '|') -eq ($expectedInstallersStageOrder -join '|')) 'AXIS Installers stage order should be installers, startup apps settings, startup apps task manager, restart after installers.'
Assert-BoostLabCondition (@($setupSteps | Where-Object { [string]$_['Id'] -eq 'startup-apps-settings' }).Count -eq 1) 'AXIS original Setup startup-apps-settings step must remain in Setup.'
Assert-BoostLabCondition (@($setupSteps | Where-Object { [string]$_['Id'] -eq 'startup-apps-task-manager' }).Count -eq 1) 'AXIS original Setup startup-apps-task-manager step must remain in Setup.'
Assert-BoostLabCondition ($installersExtensionSteps.Count -eq 3) 'AXIS Installers extension should add exactly three steps after installers.'
for ($extensionIndex = 0; $extensionIndex -lt $installersExtensionStepSpecs.Count; $extensionIndex++) {
    $extensionSpec = [System.Collections.IDictionary]$installersExtensionStepSpecs[$extensionIndex]
    $extensionStep = [System.Collections.IDictionary]$installersExtensionSteps[$extensionIndex]
    $extensionName = [string]$extensionSpec['Id']
    Assert-BoostLabCondition ([string]$extensionStep['Id'] -eq $extensionName) "AXIS Installers extension step order changed at index $extensionIndex."
    Assert-BoostLabCondition ([string]$extensionStep['Title'] -eq [string]$extensionSpec['Title']) "AXIS Installers extension title changed for $extensionName."
    Assert-BoostLabCondition ([string]$extensionStep['StageName'] -eq 'Installers') "AXIS Installers extension step should be in Installers stage: $extensionName"
    Assert-BoostLabCondition ([string]$extensionStep['PrimaryActionLabel'] -eq [string]$extensionSpec['Primary']) "AXIS Installers extension primary action changed for $extensionName."
    Assert-BoostLabCondition ([string]$extensionStep['Description'] -eq [string]$extensionSpec['Subtitle']) "AXIS Installers extension subtitle changed for $extensionName."
    Assert-BoostLabCondition ([string]$extensionStep['InformationCardTitle'] -eq [string]$extensionSpec['InfoTitle']) "AXIS Installers extension information title changed for $extensionName."
    Assert-BoostLabCondition ((@($extensionStep['InformationItems']) -join '|') -eq (@($extensionSpec['InfoItems']) -join '|')) "AXIS Installers extension information bullets changed for $extensionName."
    Assert-BoostLabCondition ([string]$extensionStep['CheckingStatusTitle'] -eq [string]$extensionSpec['Running']) "AXIS Installers extension running status changed for $extensionName."
    Assert-BoostLabCondition ([string]$extensionStep['CompletedStatusTitle'] -eq [string]$extensionSpec['Completed']) "AXIS Installers extension completed status changed for $extensionName."
    Assert-BoostLabCondition ([string]$extensionStep['CompletionStateLabel'] -eq [string]$extensionSpec['Completed']) "AXIS Installers extension completion label changed for $extensionName."
    Assert-BoostLabCondition ([bool]$extensionStep['PrototypeOnlySimulation']) "AXIS Installers extension step should be prototype-only simulation: $extensionName"
    Assert-BoostLabCondition ([string]$extensionStep['InstallersStageExtensionMarker'] -eq 'AxisFirstUseWizard.InstallersStageExtensionPrototypeOnly') "AXIS Installers extension marker missing for $extensionName."
    Assert-BoostLabCondition ([string]$extensionStep['NoRealActionMarker'] -eq [string]$extensionSpec['NoRealActionMarker']) "AXIS Installers extension no-real-action marker changed for $extensionName."
    Assert-BoostLabCondition ([string]$extensionStep['CustomerAction'] -eq [string]$extensionSpec['CustomerAction']) "AXIS Installers extension internal action mapping changed for $extensionName."
    Assert-BoostLabCondition ([string]$extensionStep['FutureInternalAction'] -eq [string]$extensionSpec['FutureInternalAction']) "AXIS Installers extension future internal action changed for $extensionName."
    Assert-BoostLabCondition ((@($extensionStep['CustomerVisibleActions']) -join '|') -eq [string]$extensionSpec['Primary']) "AXIS Installers extension customer-visible action should be the owner-approved label only: $extensionName"
    Assert-BoostLabCondition (-not [bool]$extensionStep['RequiresConfirmationAcknowledgement']) "AXIS Installers extension must not show a confirmation overlay: $extensionName"
    Assert-BoostLabCondition (-not [bool]$extensionStep['RequiresInputWindow']) "AXIS Installers extension must not show an input window: $extensionName"
    Assert-BoostLabCondition ([bool]$extensionStep['NoConfirmationOverlay']) "AXIS Installers extension no-overlay marker should be present for $extensionName."
    foreach ($forbiddenExtensionCustomerAction in @('Analyze', 'Apply', 'Open', 'Default', 'Restore')) {
        Assert-BoostLabCondition (-not ($forbiddenExtensionCustomerAction -in @($extensionStep['CustomerVisibleActions']))) "AXIS Installers extension must not expose internal action text $forbiddenExtensionCustomerAction as customer-visible action: $extensionName"
    }

    if (@($extensionSpec['Requirements']).Count -gt 0) {
        Assert-BoostLabCondition ([bool]$extensionStep['ShowRequirements']) "AXIS Installers extension requirements card should be present for $extensionName."
        Assert-BoostLabCondition ((@($extensionStep['RequirementsItems']) -join '|') -eq (@($extensionSpec['Requirements']) -join '|')) "AXIS Installers extension requirements copy changed for $extensionName."
    }
    else {
        Assert-BoostLabCondition (-not [bool]$extensionStep['ShowRequirements']) "AXIS Installers extension requirements card should be absent for $extensionName."
        Assert-BoostLabCondition (-not $extensionStep.Contains('RequirementsItems')) "AXIS Installers extension no-requirements step should not carry requirements items: $extensionName"
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$extensionSpec['SourceSetupId'])) {
        $sourceSetupStep = [System.Collections.IDictionary](@($setupSteps | Where-Object { [string]$_['Id'] -eq [string]$extensionSpec['SourceSetupId'] })[0])
        Assert-BoostLabCondition ($null -ne $sourceSetupStep) "AXIS Installers extension source Setup step missing for $extensionName."
        Assert-BoostLabCondition ([string]$extensionStep['Title'] -eq [string]$sourceSetupStep['Title']) "AXIS Installers duplicate title should match source Setup step for $extensionName."
        Assert-BoostLabCondition ([string]$extensionStep['Description'] -eq [string]$sourceSetupStep['Description']) "AXIS Installers duplicate subtitle should match source Setup step for $extensionName."
        Assert-BoostLabCondition ([string]$extensionStep['InformationCardTitle'] -eq [string]$sourceSetupStep['InformationCardTitle']) "AXIS Installers duplicate information title should match source Setup step for $extensionName."
        Assert-BoostLabCondition ((@($extensionStep['InformationItems']) -join '|') -eq (@($sourceSetupStep['InformationItems']) -join '|')) "AXIS Installers duplicate information bullets should match source Setup step for $extensionName."
        Assert-BoostLabCondition ((@($extensionStep['RequirementsItems']) -join '|') -eq (@($sourceSetupStep['RequirementsItems']) -join '|')) "AXIS Installers duplicate requirements should match source Setup step for $extensionName."
        Assert-BoostLabCondition ([bool]$extensionStep['OpenMappedPrototypeOnly']) "AXIS Installers duplicated Open step should be marked prototype-only: $extensionName."
    }
}
Assert-BoostLabCondition (-not [bool]$restartAfterInstallersStep['ShowRequirements']) 'AXIS restart-after-installers should not show a requirements card.'
Assert-BoostLabCondition (-not $restartAfterInstallersStep.Contains('RequirementsTitle')) 'AXIS restart-after-installers sample state should not carry a visible requirements title.'
Assert-BoostLabCondition (-not $restartAfterInstallersStep.Contains('RequirementsItems')) 'AXIS restart-after-installers sample state should not carry visible requirements items.'
Assert-BoostLabCondition ([bool]$restartAfterInstallersStep['NoExistingBoostLabTool']) 'AXIS restart-after-installers should be marked as not an existing BoostLab tool.'
Assert-BoostLabCondition ([string]$restartAfterInstallersStep['AxisCustomStepOrigin'] -eq 'AXIS custom future restart step') 'AXIS restart-after-installers should record custom AXIS origin.'

$actualGraphicsStageOrder = @($sampleSteps | Where-Object { [string]$_['StageName'] -eq 'Graphics' } | ForEach-Object { [string]$_['Id'] })
Assert-BoostLabCondition (($actualGraphicsStageOrder -join '|') -eq ($graphicsStepOrder -join '|')) 'AXIS Graphics stage order should be Driver Clean, GPU Driver Setup, NVIDIA App Install, DirectX, Visual C++, Graphics Configuration Center.'
Assert-BoostLabCondition ($graphicsSteps.Count -eq 6) 'AXIS Graphics stage should add exactly six isolated prototype steps.'
for ($graphicsIndex = 0; $graphicsIndex -lt $graphicsStepSpecs.Count; $graphicsIndex++) {
    $graphicsSpec = [System.Collections.IDictionary]$graphicsStepSpecs[$graphicsIndex]
    $graphicsStep = [System.Collections.IDictionary]$graphicsSteps[$graphicsIndex]
    $graphicsName = [string]$graphicsSpec['Id']
    Assert-BoostLabCondition ([string]$graphicsStep['Id'] -eq $graphicsName) "AXIS Graphics step order changed at index $graphicsIndex."
    Assert-BoostLabCondition ([string]$graphicsStep['Title'] -eq [string]$graphicsSpec['Title']) "AXIS Graphics title changed for $graphicsName."
    Assert-BoostLabCondition ([string]$graphicsStep['StageName'] -eq 'Graphics') "AXIS Graphics step should be in Graphics stage: $graphicsName"
    Assert-BoostLabCondition ([string]$graphicsStep['PrimaryActionLabel'] -eq [string]$graphicsSpec['Primary']) "AXIS Graphics primary action changed for $graphicsName."
    Assert-BoostLabCondition ([string]$graphicsStep['Description'] -eq [string]$graphicsSpec['Subtitle']) "AXIS Graphics subtitle changed for $graphicsName."
    Assert-BoostLabCondition ([string]$graphicsStep['InformationCardTitle'] -eq [string]$graphicsSpec['InfoTitle']) "AXIS Graphics information title changed for $graphicsName."
    Assert-BoostLabCondition ((@($graphicsStep['InformationItems']) -join '|') -eq (@($graphicsSpec['InfoItems']) -join '|')) "AXIS Graphics information bullets changed for $graphicsName."
    Assert-BoostLabCondition ([string]$graphicsStep['CheckingStatusTitle'] -eq [string]$graphicsSpec['Running']) "AXIS Graphics running status changed for $graphicsName."
    Assert-BoostLabCondition ([string]$graphicsStep['CompletedStatusTitle'] -eq [string]$graphicsSpec['Completed']) "AXIS Graphics completed status changed for $graphicsName."
    Assert-BoostLabCondition ([string]$graphicsStep['CompletionStateLabel'] -eq [string]$graphicsSpec['Completed']) "AXIS Graphics completion label changed for $graphicsName."
    Assert-BoostLabCondition ([bool]$graphicsStep['PrototypeOnlySimulation']) "AXIS Graphics step should be prototype-only simulation: $graphicsName"
    Assert-BoostLabCondition ([string]$graphicsStep['GraphicsStageBatchMarker'] -eq 'AxisFirstUseWizard.GraphicsStageBatchPrototypeOnly') "AXIS Graphics batch marker missing for $graphicsName."
    Assert-BoostLabCondition ([string]$graphicsStep['NoRealActionMarker'] -eq [string]$graphicsSpec['NoRealActionMarker']) "AXIS Graphics no-real-action marker changed for $graphicsName."
    Assert-BoostLabCondition ([string]$graphicsStep['CustomerAction'] -eq [string]$graphicsSpec['CustomerAction']) "AXIS Graphics internal action mapping changed for $graphicsName."
    Assert-BoostLabCondition ([string]$graphicsStep['FutureInternalAction'] -eq [string]$graphicsSpec['FutureInternalAction']) "AXIS Graphics future internal action changed for $graphicsName."
    Assert-BoostLabCondition ((@($graphicsStep['CustomerVisibleActions']) -join '|') -eq [string]$graphicsSpec['Primary']) "AXIS Graphics customer-visible action should be the owner-approved label only: $graphicsName"
    foreach ($forbiddenGraphicsCustomerAction in @('Analyze', 'Apply', 'Open', 'Default', 'Restore')) {
        Assert-BoostLabCondition (-not ($forbiddenGraphicsCustomerAction -in @($graphicsStep['CustomerVisibleActions']))) "AXIS Graphics must not expose internal action text $forbiddenGraphicsCustomerAction as customer-visible action: $graphicsName"
    }

    if ([bool]$graphicsSpec['Overlay']) {
        Assert-BoostLabCondition ([bool]$graphicsStep['RequiresConfirmationAcknowledgement']) "AXIS Graphics confirmation overlay should be present for $graphicsName."
        Assert-BoostLabCondition ([string]$graphicsStep['DocumentationAcknowledgementText'] -eq $arabicAcknowledgement) "AXIS Graphics confirmation checkbox copy changed for $graphicsName."
        Assert-BoostLabCondition ([string]$graphicsStep['ConfirmationActionLabel'] -eq [string]$graphicsSpec['Primary']) "AXIS Graphics confirmation primary copy changed for $graphicsName."
        Assert-BoostLabCondition ([string]$graphicsStep['ConfirmationReturnLabel'] -eq $arabicReturn) "AXIS Graphics confirmation return copy changed for $graphicsName."
    }
    else {
        Assert-BoostLabCondition (-not [bool]$graphicsStep['RequiresConfirmationAcknowledgement']) "AXIS Graphics confirmation overlay should be absent for $graphicsName."
        Assert-BoostLabCondition ([bool]$graphicsStep['NoConfirmationOverlay']) "AXIS Graphics no-overlay marker should be present for $graphicsName."
    }

    if (@($graphicsSpec['Requirements']).Count -gt 0) {
        Assert-BoostLabCondition ([bool]$graphicsStep['ShowRequirements']) "AXIS Graphics requirements card should be present for $graphicsName."
        Assert-BoostLabCondition ((@($graphicsStep['RequirementsItems']) -join '|') -eq (@($graphicsSpec['Requirements']) -join '|')) "AXIS Graphics requirements copy changed for $graphicsName."
    }
    else {
        Assert-BoostLabCondition (-not [bool]$graphicsStep['ShowRequirements']) "AXIS Graphics requirements card should be absent for $graphicsName."
        Assert-BoostLabCondition (-not $graphicsStep.Contains('RequirementsItems')) "AXIS Graphics no-requirements step should not carry requirements items: $graphicsName"
    }

    Assert-BoostLabCondition ([bool]$graphicsStep['RequiresInputWindow'] -eq $false) "AXIS Graphics step must not show an input window: $graphicsName"
    if ([bool]$graphicsSpec['Selector']) {
        Assert-BoostLabCondition ([bool]$graphicsStep['RequiresGpuSelector']) 'AXIS GPU Driver Setup should require the NVIDIA-only GPU selector.'
        Assert-BoostLabCondition ([bool]$graphicsStep['PrimaryActionRequiresSelection']) 'AXIS GPU Driver Setup primary action should remain disabled until NVIDIA is selected.'
        Assert-BoostLabCondition ((@($graphicsStep['GpuSelectorOptions']) -join '|') -eq "NVIDIA|$graphicsGpuSetupAmdLater|$graphicsGpuSetupIntelLater") 'AXIS GPU selector options changed.'
        Assert-BoostLabCondition ((@($graphicsStep['GpuSelectorEnabledOptions']) -join '|') -eq 'NVIDIA') 'AXIS GPU selector should only enable NVIDIA.'
    }
    else {
        Assert-BoostLabCondition (-not [bool]$graphicsStep['RequiresGpuSelector']) "AXIS Graphics step should not require a GPU selector: $graphicsName"
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$graphicsSpec['OptionalContinuation'])) {
        Assert-BoostLabCondition ([string]$graphicsStep['OptionalContinuationLabel'] -eq [string]$graphicsSpec['OptionalContinuation']) 'AXIS NVIDIA App optional continuation label changed.'
        Assert-BoostLabCondition ([bool]$graphicsStep['OptionalContinuationNoRuntimeAction']) 'AXIS NVIDIA App optional continuation should be marked no-runtime.'
    }
    else {
        Assert-BoostLabCondition (-not $graphicsStep.Contains('OptionalContinuationLabel')) "AXIS Graphics step should not expose optional continuation: $graphicsName"
    }

    if ([bool]$graphicsSpec['OpenMappedPrototypeOnly']) {
        Assert-BoostLabCondition ([bool]$graphicsStep['OpenMappedPrototypeOnly']) "AXIS Graphics Open-mapped step should be marked prototype-only: $graphicsName"
    }
}

$actualWindowsStageOrder = @($sampleSteps | Where-Object { [string]$_['StageName'] -eq 'Windows' } | ForEach-Object { [string]$_['Id'] })
Assert-BoostLabCondition (($actualWindowsStageOrder -join '|') -eq ($windowsStepOrder -join '|')) 'AXIS Windows stage order should keep Part A followed by Part B: Start Menu Taskbar through Bloatware, then Game Bar through Cleanup.'
Assert-BoostLabCondition ($windowsPartASteps.Count -eq 11) 'AXIS Windows Part A should keep exactly eleven isolated prototype steps.'
Assert-BoostLabCondition ($windowsPartBSteps.Count -eq 11) 'AXIS Windows Part B should add exactly eleven isolated prototype steps.'
Assert-BoostLabCondition ($windowsSteps.Count -eq 22) 'AXIS Windows stage should include exactly twenty-two isolated prototype steps.'
for ($windowsIndex = 0; $windowsIndex -lt $windowsStepSpecs.Count; $windowsIndex++) {
    $windowsSpec = [System.Collections.IDictionary]$windowsStepSpecs[$windowsIndex]
    $windowsStep = [System.Collections.IDictionary]$windowsSteps[$windowsIndex]
    $windowsName = [string]$windowsSpec['Id']
    $expectedWindowsStageBatchMarker = if ($windowsSpec.Contains('WindowsStageBatchMarker')) {
        [string]$windowsSpec['WindowsStageBatchMarker']
    }
    else {
        'AxisFirstUseWizard.WindowsStagePartAPrototypeOnly'
    }
    Assert-BoostLabCondition ([string]$windowsStep['Id'] -eq $windowsName) "AXIS Windows step order changed at index $windowsIndex."
    Assert-BoostLabCondition ([string]$windowsStep['Title'] -eq [string]$windowsSpec['Title']) "AXIS Windows title changed for $windowsName."
    Assert-BoostLabCondition ([string]$windowsStep['StageName'] -eq 'Windows') "AXIS Windows step should be in Windows stage: $windowsName"
    Assert-BoostLabCondition ([string]$windowsStep['PrimaryActionLabel'] -eq [string]$windowsSpec['Primary']) "AXIS Windows primary action changed for $windowsName."
    Assert-BoostLabCondition ([string]$windowsStep['Description'] -eq [string]$windowsSpec['Subtitle']) "AXIS Windows subtitle changed for $windowsName."
    Assert-BoostLabCondition ([string]$windowsStep['InformationCardTitle'] -eq [string]$windowsSpec['InfoTitle']) "AXIS Windows information title changed for $windowsName."
    Assert-BoostLabCondition ((@($windowsStep['InformationItems']) -join '|') -eq (@($windowsSpec['InfoItems']) -join '|')) "AXIS Windows information bullets changed for $windowsName."
    Assert-BoostLabCondition ([string]$windowsStep['CheckingStatusTitle'] -eq [string]$windowsSpec['Running']) "AXIS Windows running status changed for $windowsName."
    Assert-BoostLabCondition ([string]$windowsStep['CompletedStatusTitle'] -eq [string]$windowsSpec['Completed']) "AXIS Windows completed status changed for $windowsName."
    Assert-BoostLabCondition ([string]$windowsStep['CompletionStateLabel'] -eq [string]$windowsSpec['Completed']) "AXIS Windows completion label changed for $windowsName."
    Assert-BoostLabCondition ([bool]$windowsStep['PrototypeOnlySimulation']) "AXIS Windows step should be prototype-only simulation: $windowsName"
    Assert-BoostLabCondition ([string]$windowsStep['WindowsStageBatchMarker'] -eq $expectedWindowsStageBatchMarker) "AXIS Windows batch marker changed for $windowsName."
    Assert-BoostLabCondition ([string]$windowsStep['NoRealActionMarker'] -eq [string]$windowsSpec['NoRealActionMarker']) "AXIS Windows no-real-action marker changed for $windowsName."
    Assert-BoostLabCondition ([string]$windowsStep['CustomerAction'] -eq [string]$windowsSpec['CustomerAction']) "AXIS Windows internal action mapping changed for $windowsName."
    Assert-BoostLabCondition ([string]$windowsStep['FutureInternalAction'] -eq [string]$windowsSpec['FutureInternalAction']) "AXIS Windows future internal action changed for $windowsName."
    Assert-BoostLabCondition ((@($windowsStep['CustomerVisibleActions']) -join '|') -eq [string]$windowsSpec['Primary']) "AXIS Windows customer-visible action should be the owner-approved label only: $windowsName"
    foreach ($forbiddenWindowsCustomerAction in @('Analyze', 'Apply', 'Open', 'Default', 'Restore')) {
        Assert-BoostLabCondition (-not ($forbiddenWindowsCustomerAction -in @($windowsStep['CustomerVisibleActions']))) "AXIS Windows must not expose internal action text $forbiddenWindowsCustomerAction as customer-visible action: $windowsName"
    }

    if ([bool]$windowsSpec['Overlay']) {
        Assert-BoostLabCondition ([bool]$windowsStep['RequiresConfirmationAcknowledgement']) "AXIS Windows confirmation overlay should be present for $windowsName."
        Assert-BoostLabCondition ([string]$windowsStep['DocumentationAcknowledgementText'] -eq $arabicAcknowledgement) "AXIS Windows confirmation checkbox copy changed for $windowsName."
        Assert-BoostLabCondition ([string]$windowsStep['ConfirmationActionLabel'] -eq [string]$windowsSpec['Primary']) "AXIS Windows confirmation primary copy changed for $windowsName."
        Assert-BoostLabCondition ([string]$windowsStep['ConfirmationReturnLabel'] -eq $arabicReturn) "AXIS Windows confirmation return copy changed for $windowsName."
    }
    else {
        Assert-BoostLabCondition (-not [bool]$windowsStep['RequiresConfirmationAcknowledgement']) "AXIS Windows confirmation overlay should be absent for $windowsName."
        Assert-BoostLabCondition ([bool]$windowsStep['NoConfirmationOverlay']) "AXIS Windows no-overlay marker should be present for $windowsName."
    }

    if (@($windowsSpec['Requirements']).Count -gt 0) {
        Assert-BoostLabCondition ([bool]$windowsStep['ShowRequirements']) "AXIS Windows requirements card should be present for $windowsName."
        Assert-BoostLabCondition ((@($windowsStep['RequirementsItems']) -join '|') -eq (@($windowsSpec['Requirements']) -join '|')) "AXIS Windows requirements copy changed for $windowsName."
    }
    else {
        Assert-BoostLabCondition (-not [bool]$windowsStep['ShowRequirements']) "AXIS Windows requirements card should be absent for $windowsName."
        Assert-BoostLabCondition (-not $windowsStep.Contains('RequirementsItems')) "AXIS Windows no-requirements step should not carry requirements items: $windowsName"
    }

    Assert-BoostLabCondition ([bool]$windowsStep['RequiresInputWindow'] -eq $false) "AXIS Windows step must not show an input window: $windowsName"
    if ([bool]$windowsSpec['Selector']) {
        Assert-BoostLabCondition ([bool]$windowsStep['RequiresActionSelector']) 'AXIS Bloatware should require the owner-approved action selector.'
        Assert-BoostLabCondition ([bool]$windowsStep['PrimaryActionRequiresSelection']) 'AXIS Bloatware primary action should remain disabled until an action is selected.'
        Assert-BoostLabCondition ([bool]$windowsStep['ActionSelectorSingleSelect']) 'AXIS Bloatware selector should be single-select.'
        Assert-BoostLabCondition ([string]$windowsStep['ActionSelectorLabel'] -eq [string]$windowsSpec['SelectorLabel']) 'AXIS Bloatware selector label changed.'
        Assert-BoostLabCondition ([string]$windowsStep['ActionSelectorPlaceholder'] -eq [string]$windowsSpec['SelectorPlaceholder']) 'AXIS Bloatware selector placeholder changed.'
        Assert-BoostLabCondition ((@($windowsStep['ActionSelectorOptions']) -join '|') -eq (@($windowsSpec['SelectorOptions']) -join '|')) 'AXIS Bloatware selector options changed.'
    }
    else {
        Assert-BoostLabCondition (-not [bool]$windowsStep['RequiresActionSelector']) "AXIS Windows step should not require an action selector: $windowsName"
    }

    if ([bool]$windowsSpec['OpenMappedPrototypeOnly']) {
        Assert-BoostLabCondition ([bool]$windowsStep['OpenMappedPrototypeOnly']) "AXIS Windows Open-mapped step should be marked prototype-only: $windowsName"
    }
}

$actualAdvancedStageOrder = @($sampleSteps | Where-Object { [string]$_['StageName'] -eq 'Advanced' } | ForEach-Object { [string]$_['Id'] })
Assert-BoostLabCondition (($actualAdvancedStageOrder -join '|') -eq ($advancedStepOrder -join '|')) 'AXIS Advanced stage order should be Timer Resolution Assistant then Defender Optimize Assistant.'
Assert-BoostLabCondition ($advancedSteps.Count -eq 2) 'AXIS Advanced stage should add exactly two isolated prototype steps.'
for ($advancedIndex = 0; $advancedIndex -lt $advancedStepSpecs.Count; $advancedIndex++) {
    $advancedSpec = [System.Collections.IDictionary]$advancedStepSpecs[$advancedIndex]
    $advancedStep = [System.Collections.IDictionary]$advancedSteps[$advancedIndex]
    $advancedName = [string]$advancedSpec['Id']
    Assert-BoostLabCondition ([string]$advancedStep['Id'] -eq $advancedName) "AXIS Advanced step order changed at index $advancedIndex."
    Assert-BoostLabCondition ([string]$advancedStep['Title'] -eq [string]$advancedSpec['Title']) "AXIS Advanced title changed for $advancedName."
    Assert-BoostLabCondition ([string]$advancedStep['StageName'] -eq 'Advanced') "AXIS Advanced step should be in Advanced stage: $advancedName"
    Assert-BoostLabCondition ([string]$advancedStep['PrimaryActionLabel'] -eq [string]$advancedSpec['Primary']) "AXIS Advanced primary action changed for $advancedName."
    Assert-BoostLabCondition ([string]$advancedStep['Description'] -eq [string]$advancedSpec['Subtitle']) "AXIS Advanced subtitle changed for $advancedName."
    Assert-BoostLabCondition ([string]$advancedStep['InformationCardTitle'] -eq [string]$advancedSpec['InfoTitle']) "AXIS Advanced information title changed for $advancedName."
    Assert-BoostLabCondition ((@($advancedStep['InformationItems']) -join '|') -eq (@($advancedSpec['InfoItems']) -join '|')) "AXIS Advanced information bullets changed for $advancedName."
    Assert-BoostLabCondition ([string]$advancedStep['CheckingStatusTitle'] -eq [string]$advancedSpec['Running']) "AXIS Advanced running status changed for $advancedName."
    Assert-BoostLabCondition ([string]$advancedStep['CompletedStatusTitle'] -eq [string]$advancedSpec['Completed']) "AXIS Advanced completed status changed for $advancedName."
    Assert-BoostLabCondition ([string]$advancedStep['CompletionStateLabel'] -eq [string]$advancedSpec['Completed']) "AXIS Advanced completion label changed for $advancedName."
    Assert-BoostLabCondition ([bool]$advancedStep['PrototypeOnlySimulation']) "AXIS Advanced step should be prototype-only simulation: $advancedName"
    Assert-BoostLabCondition ([string]$advancedStep['AdvancedStageBatchMarker'] -eq 'AxisFirstUseWizard.AdvancedStageBatchPrototypeOnly') "AXIS Advanced batch marker missing for $advancedName."
    Assert-BoostLabCondition ([string]$advancedStep['NoRealActionMarker'] -eq [string]$advancedSpec['NoRealActionMarker']) "AXIS Advanced no-real-action marker changed for $advancedName."
    Assert-BoostLabCondition ([string]$advancedStep['CustomerAction'] -eq [string]$advancedSpec['CustomerAction']) "AXIS Advanced internal action mapping changed for $advancedName."
    Assert-BoostLabCondition ([string]$advancedStep['FutureInternalAction'] -eq [string]$advancedSpec['FutureInternalAction']) "AXIS Advanced future internal action changed for $advancedName."
    Assert-BoostLabCondition ((@($advancedStep['CustomerVisibleActions']) -join '|') -eq [string]$advancedSpec['Primary']) "AXIS Advanced customer-visible action should be the owner-approved label only: $advancedName"
    foreach ($forbiddenAdvancedCustomerAction in @('Analyze', 'Default', 'Restore')) {
        Assert-BoostLabCondition (-not ($forbiddenAdvancedCustomerAction -in @($advancedStep['CustomerVisibleActions']))) "AXIS Advanced must not expose internal action text $forbiddenAdvancedCustomerAction as customer-visible action: $advancedName"
    }

    if (@($advancedSpec['Requirements']).Count -gt 0) {
        Assert-BoostLabCondition ([bool]$advancedStep['ShowRequirements']) "AXIS Advanced requirements card should be present for $advancedName."
        Assert-BoostLabCondition ((@($advancedStep['RequirementsItems']) -join '|') -eq (@($advancedSpec['Requirements']) -join '|')) "AXIS Advanced requirements copy changed for $advancedName."
    }
    else {
        Assert-BoostLabCondition (-not [bool]$advancedStep['ShowRequirements']) "AXIS Advanced requirements card should be absent for $advancedName."
        Assert-BoostLabCondition (-not $advancedStep.Contains('RequirementsItems')) "AXIS Advanced no-requirements step should not carry requirements items: $advancedName"
    }

    if ([bool]$advancedSpec['Overlay']) {
        Assert-BoostLabCondition ([bool]$advancedStep['RequiresConfirmationAcknowledgement']) "AXIS Advanced confirmation overlay should be present for $advancedName."
        Assert-BoostLabCondition ([string]$advancedStep['DocumentationAcknowledgementText'] -eq $arabicAcknowledgement) "AXIS Advanced confirmation checkbox copy changed for $advancedName."
        Assert-BoostLabCondition ([string]$advancedStep['ConfirmationActionLabel'] -eq [string]$advancedSpec['Primary']) "AXIS Advanced confirmation primary copy changed for $advancedName."
        Assert-BoostLabCondition ([string]$advancedStep['ConfirmationReturnLabel'] -eq $arabicReturn) "AXIS Advanced confirmation return copy changed for $advancedName."
    }
    else {
        Assert-BoostLabCondition (-not [bool]$advancedStep['RequiresConfirmationAcknowledgement']) "AXIS Advanced confirmation overlay should be absent for $advancedName."
        Assert-BoostLabCondition ([bool]$advancedStep['NoConfirmationOverlay']) "AXIS Advanced no-overlay marker should be present for $advancedName."
    }

    Assert-BoostLabCondition ([bool]$advancedStep['RequiresInputWindow'] -eq $false) "AXIS Advanced step must not show an input window: $advancedName"
}
Assert-BoostLabCondition ($advancedDefenderOptimizeInfoBullet1 -eq $advancedDefenderOptimizeApprovedBullet1) 'AXIS Defender Optimize should use the approved no-BoostLab bullet in the sample model.'
Assert-BoostLabCondition (-not $advancedDefenderOptimizeInfoBullet1.Contains('BoostLab')) 'AXIS Defender Optimize normal UI copy must not include BoostLab.'

$taggedBiosInformationStep = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.BiosInformationStep')
$taggedContentHost = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.StepContentHost')
$taggedStepTextContent = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.StepTextContent')
$taggedArabicSubtitleRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.ArabicSubtitleRightAnchor')
$taggedInformationCard = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.InformationCard')
$taggedArabicInfoCardRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.ArabicInfoCardRightAnchor')
$taggedInformationCardContent = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.InformationCardContent')
$taggedInformationCardSharedPhysicalRightEdge = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.InformationCardSharedPhysicalRightEdge')
$taggedPrimaryActionArea = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.PrimaryActionArea')
$taggedPrimaryButtonRow = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.PrimaryActionButtonRow')
$taggedPrimaryButtonSpacer = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.PrimaryActionButtonSpacer')
$taggedActionRuntimeStatusSpacer = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.ActionRuntimeStatusSpacer')
$taggedRuntimeStatusArea = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.RuntimeStatusArea')
$taggedDocumentationButton = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.DocumentationButton')
$taggedPrimaryOpenButton = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.PrimaryOpenButton')
$taggedSupportPanel = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.SupportPanel')
$taggedArabicSupportPanelRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.ArabicSupportPanelRightAnchor')
$taggedSupportPanelContent = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.SupportPanelContent')
$taggedSupportSharedPhysicalRightEdge = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.SupportSharedPhysicalRightEdge')
$taggedBottomNavigation = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.BottomNavigation')
$taggedBottomButtons = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.BottomButtons')
$taggedFooterButtonSpacer = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.FooterButtonSpacer')
$taggedOptionalContinuationButton = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.OptionalContinuationButton')
$taggedOptionalContinuationFooterSpacer = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.OptionalContinuationFooterSpacer')
$taggedContinueButtons = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.ContinueButton')
$taggedOverlay = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.ConfirmationOverlay')
$taggedAutoUnattendInputOverlay = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.AutoUnattendInputOverlay')
$taggedUpdatesDriversInputOverlay = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.UpdatesDriversInputOverlay')
$firstStepOverlay = $taggedOverlay[0]
$taggedConfirmationRightAlignedGroup = @(Get-AxisFirstUseWizardTaggedElements -Root $firstStepOverlay -Tag 'AxisFirstUseWizard.ConfirmationRightAlignedGroup')
$taggedAcknowledgementRightAnchorRow = @(Get-AxisFirstUseWizardTaggedElements -Root $firstStepOverlay -Tag 'AxisFirstUseWizard.AcknowledgementRightAnchorRow')
$taggedOverlayAcknowledgement = @(Get-AxisFirstUseWizardTaggedElements -Root $firstStepOverlay -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgement')
$taggedOverlayAcknowledgementText = @(Get-AxisFirstUseWizardTaggedElements -Root $firstStepOverlay -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgementText')
$taggedOverlayButtonArea = @(Get-AxisFirstUseWizardTaggedElements -Root $firstStepOverlay -Tag 'AxisFirstUseWizard.ConfirmationButtonArea')
$taggedOverlayControlSpacer = @(Get-AxisFirstUseWizardTaggedElements -Root $firstStepOverlay -Tag 'AxisFirstUseWizard.ConfirmationControlSpacer')
$taggedOverlayOpenButton = @(Get-AxisFirstUseWizardTaggedElements -Root $firstStepOverlay -Tag 'AxisFirstUseWizard.ConfirmationOpenButton')
$taggedOverlayReturnButton = @(Get-AxisFirstUseWizardTaggedElements -Root $firstStepOverlay -Tag 'AxisFirstUseWizard.ConfirmationReturnButton')
$taggedOverlayReturnButtonSpacer = @(Get-AxisFirstUseWizardTaggedElements -Root $firstStepOverlay -Tag 'AxisFirstUseWizard.ConfirmationReturnButtonSpacer')

Assert-BoostLabCondition ($taggedBiosInformationStep.Count -eq 1) 'AXIS BIOS Drivers & Downloads step is missing.'
Assert-BoostLabCondition ($taggedContentHost.Count -eq 1) 'AXIS first-use wizard step content host is missing.'
Assert-BoostLabCondition ([double]$taggedBiosInformationStep[0].Height -eq 382.0) 'AXIS BIOS Drivers & Downloads main card should keep the polished height.'
Assert-BoostLabCondition ($taggedBiosInformationStep[0].FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) 'AXIS step card must be RTL.'
Assert-BoostLabCondition ($taggedStepTextContent.Count -eq 1) 'AXIS BIOS Drivers & Downloads step should expose one text-only content column.'
Assert-BoostLabCondition ($taggedBiosInformationStep[0].Child -eq $taggedStepTextContent[0]) 'AXIS BIOS Drivers & Downloads step should not keep an icon column or wrapper.'
Assert-BoostLabCondition ($taggedStepTextContent[0] -is [System.Windows.Controls.Grid]) 'AXIS step text content should use a full-width Grid so Arabic text starts from the right.'
Assert-BoostLabCondition ($taggedStepTextContent[0].HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Stretch) 'AXIS step text content grid should stretch to the card width.'
Assert-BoostLabCondition ($taggedArabicSubtitleRightAnchor.Count -eq 1) 'AXIS subtitle/body should use a named physical right anchor.'
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $taggedArabicSubtitleRightAnchor[0] -Name 'subtitle/body' -ExpectedMaxWidth 690)
Assert-BoostLabCondition ($taggedInformationCard.Count -eq 1) 'AXIS BIOS Drivers & Downloads should show exactly one information card.'
Assert-BoostLabCondition ($taggedInformationCard[0].FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) 'AXIS information card must use RTL flow.'
Assert-BoostLabCondition ($taggedInformationCard[0].HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Stretch) 'AXIS information card should stretch so Arabic starts from the right.'
Assert-BoostLabCondition ($taggedArabicInfoCardRightAnchor.Count -eq 1) 'AXIS information card should use a named physical right anchor.'
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $taggedArabicInfoCardRightAnchor[0] -Name 'information card' -ExpectedMaxWidth 650)
Assert-BoostLabCondition ($taggedInformationCardContent.Count -eq 1) 'AXIS information card should use a full-width content grid.'
Assert-BoostLabCondition ($taggedInformationCardContent[0] -is [System.Windows.Controls.Grid]) 'AXIS information card content should use Grid layout for full-width Arabic rows.'
Assert-BoostLabCondition ($taggedInformationCardContent[0].HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) 'AXIS information card Arabic group should be physically right-anchored.'
Assert-BoostLabCondition ([double]$taggedInformationCardContent[0].MaxWidth -eq 650.0) 'AXIS information card should keep the Phase 177H max-width anchor model.'
Assert-BoostLabCondition ([double]::IsNaN([double]$taggedInformationCardContent[0].Width)) 'AXIS information card must not reintroduce a fixed-width 177I block.'
Assert-BoostLabCondition ($taggedInformationCardSharedPhysicalRightEdge.Count -eq 1) 'AXIS information card lines should use one shared physical right-edge marker.'
$informationCardPhysicalRightLines = Assert-AxisFirstUseWizardSharedPhysicalRightEdgeGroup `
    -Group $taggedInformationCardSharedPhysicalRightEdge[0] `
    -Name 'information card' `
    -ExpectedTexts @($arabicInfoTitle, $arabicNetworkDriver, $arabicAudioDriver) `
    -ExpectedMaxWidth 650
Assert-BoostLabCondition (@($taggedInformationCardContent[0].Children) -contains $taggedInformationCardSharedPhysicalRightEdge[0]) 'AXIS information card shared physical right-edge group should be a direct child of the existing shared container.'
Assert-BoostLabCondition ($informationCardPhysicalRightLines[0].FontWeight -eq (Get-AxisWizardResource -Resources $prototype.Resources -Name 'Axis.Type.CardTitle.FontWeight')) 'AXIS information card title should keep the title weight.'
[void](Assert-AxisFirstUseWizardForegroundColor -Element $informationCardPhysicalRightLines[0] -ExpectedColor $axisDefaultCardTitleForeground -Name 'BIOS Drivers & Downloads information card title')
[void](Assert-AxisFirstUseWizardForegroundNotColor -Element $informationCardPhysicalRightLines[0] -RejectedColor $axisRejectedInformationCardTitleForeground -Name 'BIOS Drivers & Downloads information card title')
foreach ($informationCardLine in $informationCardPhysicalRightLines) {
    Assert-BoostLabCondition ([double]$informationCardLine.Margin.Right -eq [double]$informationCardPhysicalRightLines[0].Margin.Right) 'AXIS information card lines should share the same physical right coordinate margin.'
    Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($informationCardLine) -eq [System.Windows.Controls.Grid]::GetColumn($informationCardPhysicalRightLines[0])) 'AXIS information card lines should share the same physical right coordinate column.'
}
Assert-BoostLabCondition ($taggedPrimaryActionArea.Count -eq 1) 'AXIS BIOS Drivers & Downloads primary action area is missing.'
Assert-BoostLabCondition ($taggedPrimaryActionArea[0] -is [System.Windows.Controls.Grid]) 'AXIS primary action area should use a stable Grid layout.'
Assert-BoostLabCondition ($taggedPrimaryActionArea[0].FlowDirection -eq [System.Windows.FlowDirection]::LeftToRight) 'AXIS primary action grid should avoid ambiguous RTL column mirroring.'
Assert-BoostLabCondition ($taggedPrimaryButtonRow.Count -eq 1) 'AXIS BIOS Drivers & Downloads primary action button row is missing.'
Assert-BoostLabCondition ($taggedPrimaryButtonRow[0].FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) 'AXIS primary action row should use RTL flow.'
Assert-BoostLabCondition ($taggedPrimaryButtonSpacer.Count -eq 1) 'AXIS primary/documentation buttons should use an explicit spacer.'
Assert-BoostLabCondition ([double]$taggedPrimaryButtonSpacer[0].Width -ge 12.0 -and [double]$taggedPrimaryButtonSpacer[0].Width -le 20.0) 'AXIS primary/documentation spacer should provide a clear 12-20px gap.'
Assert-BoostLabCondition ($taggedRuntimeStatusArea.Count -eq 1) 'AXIS runtime status area is missing.'
Assert-BoostLabCondition ($taggedRuntimeStatusArea[0] -ne $taggedSupportPanel[0]) 'AXIS runtime status area must be separate from the support panel.'
Assert-BoostLabCondition ($taggedRuntimeStatusArea[0].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS runtime status area should start hidden before the primary action flow.'
Assert-BoostLabCondition ($taggedRuntimeStatusArea[0].HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) 'AXIS runtime status area should align near the primary action row.'
Assert-BoostLabCondition ([double]$taggedRuntimeStatusArea[0].Width -eq 214.0) 'AXIS BIOS Drivers & Downloads runtime status width should remain unchanged.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($taggedRuntimeStatusArea[0]) -ne 'AxisFirstUseWizard.BiosSettingsRuntimeStatusNoClipping') 'AXIS BIOS Drivers & Downloads runtime status should not use the BIOS Settings-only no-clipping marker.'
Assert-BoostLabCondition ($taggedActionRuntimeStatusSpacer.Count -eq 1) 'AXIS action/runtime status spacer is missing.'
Assert-BoostLabCondition ($taggedDocumentationButton.Count -eq 1) 'AXIS BIOS Drivers & Downloads documentation button is missing.'
Assert-BoostLabCondition ($taggedPrimaryOpenButton.Count -eq 1) 'AXIS BIOS Drivers & Downloads primary Open button is missing.'
Assert-BoostLabCondition ([string]$taggedPrimaryOpenButton[0].Content -eq $arabicOpen) 'AXIS primary action label should be owner-approved Arabic Open.'
Assert-BoostLabCondition ([string]$taggedDocumentationButton[0].Content -eq $arabicDocumentation) 'AXIS documentation action label should be owner-approved Arabic text.'
[void](Assert-AxisFirstUseWizardForegroundColor -Element $taggedDocumentationButton[0] -ExpectedColor $axisDefaultDocumentationForeground -Name 'BIOS Drivers & Downloads documentation button')
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($taggedDocumentationButton[0]) -eq 'AxisFirstUseWizard.DocumentationDefaultForeground') 'AXIS documentation button should expose the default foreground marker.'
Assert-BoostLabCondition ([string]([System.Windows.Media.SolidColorBrush]$taggedDocumentationButton[0].Foreground).Color -ne '#FFE65F2B') 'AXIS documentation button must not use the rejected orange accent.'
Assert-BoostLabCondition ([double]$taggedDocumentationButton[0].Margin.Right -eq 0.0) 'AXIS documentation button should not rely on RTL margin behavior for spacing.'
Assert-BoostLabCondition ($taggedSupportPanel.Count -eq 1) 'AXIS BIOS Drivers & Downloads support panel is missing.'
Assert-BoostLabCondition ($taggedSupportPanel[0].HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Stretch) 'AXIS support panel should stretch so Arabic starts from the right.'
Assert-BoostLabCondition ($taggedArabicSupportPanelRightAnchor.Count -eq 1) 'AXIS support panel should use a named physical right anchor.'
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $taggedArabicSupportPanelRightAnchor[0] -Name 'support panel' -ExpectedMaxWidth 720)
Assert-BoostLabCondition ($taggedSupportPanelContent.Count -eq 1) 'AXIS support panel should use a full-width content grid.'
Assert-BoostLabCondition ($taggedSupportPanelContent[0] -is [System.Windows.Controls.Grid]) 'AXIS support panel content should use Grid layout for full-width Arabic rows.'
Assert-BoostLabCondition ($taggedSupportPanelContent[0].HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) 'AXIS support panel Arabic group should be physically right-anchored.'
Assert-BoostLabCondition ([double]$taggedSupportPanelContent[0].MaxWidth -eq 720.0) 'AXIS support panel should keep the Phase 177H max-width anchor model.'
Assert-BoostLabCondition ([double]::IsNaN([double]$taggedSupportPanelContent[0].Width)) 'AXIS support panel must not reintroduce a fixed-width 177I block.'
Assert-BoostLabCondition ($taggedSupportSharedPhysicalRightEdge.Count -eq 1) 'AXIS support panel title/body should use one shared physical right-edge marker.'
$supportPhysicalRightLines = Assert-AxisFirstUseWizardSharedPhysicalRightEdgeGroup `
    -Group $taggedSupportSharedPhysicalRightEdge[0] `
    -Name 'support panel' `
    -ExpectedTexts @($arabicSupportTitle, $arabicSupportBody) `
    -ExpectedMaxWidth 720
Assert-BoostLabCondition (@($taggedSupportPanelContent[0].Children) -contains $taggedSupportSharedPhysicalRightEdge[0]) 'AXIS support shared physical right-edge group should be a direct child of the existing shared container.'
Assert-BoostLabCondition ($supportPhysicalRightLines[0].FontWeight -eq (Get-AxisWizardResource -Resources $prototype.Resources -Name 'Axis.Type.Micro.FontWeight')) 'AXIS support title should keep the title weight.'
Assert-BoostLabCondition ($supportPhysicalRightLines[1].TextWrapping -eq [System.Windows.TextWrapping]::Wrap) 'AXIS support body should remain wrapped inside the support panel.'
foreach ($supportLine in $supportPhysicalRightLines) {
    Assert-BoostLabCondition ([double]$supportLine.Margin.Right -eq [double]$supportPhysicalRightLines[0].Margin.Right) 'AXIS support lines should share the same physical right coordinate margin.'
    Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($supportLine) -eq [System.Windows.Controls.Grid]::GetColumn($supportPhysicalRightLines[0])) 'AXIS support lines should share the same physical right coordinate column.'
}

Assert-BoostLabCondition ($taggedBottomNavigation.Count -eq 1) 'AXIS first-use wizard bottom navigation is missing.'
Assert-BoostLabCondition (-not [bool]$taggedBottomNavigation[0].ClipToBounds) 'AXIS first-use wizard footer should not clip button borders or shadows.'
Assert-BoostLabCondition ($taggedBottomButtons.Count -eq 1) 'AXIS first-use wizard footer button row is missing.'
Assert-BoostLabCondition ($taggedBottomButtons[0].FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) 'AXIS footer buttons should use RTL flow.'
$footerButtons = @(Get-AxisFirstUseWizardTypedElements -Root $taggedBottomButtons[0] -Type ([System.Windows.Controls.Button]))
Assert-BoostLabCondition ($footerButtons.Count -eq 4) 'AXIS first-use wizard footer should include Back, NVIDIA App optional continuation, Continue, and the hidden final-completion Finish button.'
Assert-BoostLabCondition ((@($footerButtons | ForEach-Object { [string]$_.Content }) -join '|') -eq "$arabicBack|$graphicsNvidiaAppOptionalContinuation|$arabicNext|$axisFinalButton") 'AXIS first-use wizard footer button labels changed.'
$toolPageFinalButton = @($footerButtons | Where-Object { [string]$_.Tag -eq 'AxisFirstUseWizard.FinalCompletionButton' }) | Select-Object -First 1
Assert-BoostLabCondition ($toolPageFinalButton.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS final-completion Finish button should stay hidden on normal tool pages.'
Assert-BoostLabCondition ($taggedOptionalContinuationButton.Count -eq 1) 'AXIS NVIDIA App optional continuation footer button is missing.'
Assert-BoostLabCondition ($taggedOptionalContinuationButton[0].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS NVIDIA App optional continuation footer button should start hidden before its step.'
Assert-BoostLabCondition (-not [bool]$taggedOptionalContinuationButton[0].IsEnabled) 'AXIS NVIDIA App optional continuation footer button should start disabled before its step.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($taggedOptionalContinuationButton[0]) -eq 'AxisFirstUseWizard.NvidiaAppOptionalContinuationNoApplySimulation') 'AXIS NVIDIA App optional continuation should be marked as no-runtime simulation.'
Assert-BoostLabCondition ([double]$taggedOptionalContinuationButton[0].Width -ge 244.0) 'AXIS NVIDIA App optional continuation footer button should be wide enough for the approved mixed Arabic/English label.'
Assert-BoostLabCondition ($taggedOptionalContinuationFooterSpacer.Count -eq 1) 'AXIS optional continuation footer spacer is missing.'
Assert-BoostLabCondition ($taggedOptionalContinuationFooterSpacer[0].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS optional continuation footer spacer should start hidden.'
Assert-BoostLabCondition ($taggedFooterButtonSpacer.Count -eq 1) 'AXIS footer buttons should use an explicit spacer.'
Assert-BoostLabCondition ([double]$taggedFooterButtonSpacer[0].Width -ge 12.0 -and [double]$taggedFooterButtonSpacer[0].Width -le 20.0) 'AXIS footer spacer should provide a clear 12-20px gap.'
Assert-BoostLabCondition ($taggedContinueButtons.Count -eq 1) 'AXIS first-use wizard Continue button is missing.'
Assert-BoostLabCondition (-not [bool]$taggedContinueButtons[0].IsEnabled) 'AXIS Continue/Next should start disabled before completion.'
Assert-AxisFirstUseWizardNextDisabledNonBlue -Button $taggedContinueButtons[0] -Name 'BIOS Drivers & Downloads initial'
$continueStartsDisabled = -not [bool]$taggedContinueButtons[0].IsEnabled
Assert-BoostLabCondition ([double]$taggedContinueButtons[0].Margin.Right -eq 0.0) 'AXIS Continue/Next should not rely on RTL margin behavior for spacing.'
foreach ($footerButton in $footerButtons) {
    Assert-BoostLabCondition ([double]$footerButton.Height -eq 40.0) 'AXIS first-use wizard footer buttons should use the polished height to avoid bottom clipping.'
    Assert-BoostLabCondition ([double]$footerButton.Margin.Bottom -ge 0.0) 'AXIS first-use wizard footer buttons must not use negative bottom margins.'
    Assert-BoostLabCondition ($null -ne $footerButton.Style) 'AXIS first-use wizard footer buttons should use the shared interactive button style.'
    Assert-BoostLabCondition ([bool]$footerButton.Focusable) 'AXIS first-use wizard footer buttons should remain focusable for the focus visual.'
}
$buttonStyleSource = [regex]::Match(
    $prototypeSource,
    '(?s)function Get-AxisWizardButtonStyle.*?function Get-AxisWizardFilledSquareCheckboxStyle'
).Value
Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace($buttonStyleSource)) 'AXIS first-use wizard button style source should be statically inspectable.'
foreach ($requiredButtonInteractionMarker in @(
    'AxisFirstUseWizard.ButtonHoverInteractiveEffect'
    'AxisFirstUseWizard.ButtonHoverCrispEffect'
    'AxisFirstUseWizard.ButtonHoverPointerAffordance'
    'AxisFirstUseWizard.ButtonHoverCrispGlow'
    'AxisFirstUseWizard.ButtonHoverCrispNoScale'
    'AxisFirstUseWizard.NoHoverScaleTransform'
    'AxisFirstUseWizard.NoHoverGrowScale'
    'AxisFirstUseWizard.ButtonPressedInteractiveEffect'
    'AxisFirstUseWizard.ButtonPressedInEffect'
    'AxisFirstUseWizard.DisabledButtonsNoHoverEffect'
    'AxisFirstUseWizard.DisabledButtonsNoPressedEffect'
    'Set-AxisWizardButtonHoverResources'
    'AxisFirstUseWizard.ButtonHoverBackground'
    'AxisFirstUseWizard.ButtonHoverBorder'
    'AxisFirstUseWizard.EnabledNextButtonHoverReadable'
    'BlueHoverKeepsReadableText'
    '#1D4ED8'
    '#93C5FD'
    '<Setter Property="Cursor" Value="Hand" />'
    '<Setter Property="Cursor" Value="Arrow" />'
    'Property="Background" Value="{DynamicResource AxisFirstUseWizard.ButtonHoverBackground}"'
    'Property="BorderBrush" Value="{DynamicResource AxisFirstUseWizard.ButtonHoverBorder}"'
    'IsMouseOver'
    'IsKeyboardFocusWithin'
    'IsPressed'
    'DropShadowEffect'
    'UseLayoutRounding'
    'SnapsToDevicePixels'
    'Property="Margin" Value="1"'
    'Property="Margin" Value="0"'
    '<Condition Property="IsEnabled" Value="True" />'
    '<Trigger Property="IsEnabled" Value="False">'
)) {
    Assert-BoostLabCondition ($prototypeSource.Contains($requiredButtonInteractionMarker)) "AXIS first-use wizard button interaction style is missing: $requiredButtonInteractionMarker"
}
Assert-BoostLabCondition (-not $buttonStyleSource.Contains('<ScaleTransform')) 'AXIS crisp button hover should not scale the full button or text.'
Assert-BoostLabCondition (-not $buttonStyleSource.Contains('ScaleX')) 'AXIS pressed-in effect should not grow or scale the text layer.'
Assert-BoostLabCondition (-not $buttonStyleSource.Contains('ScaleY')) 'AXIS pressed-in effect should not grow or scale the text layer.'
foreach ($rejectedPhase180DPrototypeText in @(
    'AxisFirstUseWizard.AcknowledgementAccentForeground'
    'Axis.Brush.Wizard.AcknowledgementAccentForeground'
    'Axis.Brush.Wizard.InformationCardTitleForeground'
    'Axis.Brush.Wizard.RequirementsCardTitleForeground'
    '#8A2BE2'
    '#D9A74A'
)) {
    Assert-BoostLabCondition (-not $prototypeSource.Contains($rejectedPhase180DPrototypeText)) "AXIS first-use wizard prototype should not contain rejected Phase 180D accent text: $rejectedPhase180DPrototypeText"
}

Assert-BoostLabCondition ($taggedOverlay.Count -eq 10) 'AXIS first-use wizard should create confirmation overlays for BIOS Drivers, BIOS Settings, To BIOS, Updates Pause, Driver Clean, GPU Driver Setup, NVIDIA App Install, Bloatware, Edge WebView, and Defender Optimize Assistant only.'
Assert-BoostLabCondition ($taggedAutoUnattendInputOverlay.Count -eq 1) 'AXIS first-use wizard should create one AutoUnattend input overlay.'
Assert-BoostLabCondition ($taggedAutoUnattendInputOverlay[0].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS AutoUnattend input overlay should start hidden.'
Assert-BoostLabCondition ($taggedUpdatesDriversInputOverlay.Count -eq 1) 'AXIS first-use wizard should create one Updates Drivers Block input overlay.'
Assert-BoostLabCondition ($taggedUpdatesDriversInputOverlay[0].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Updates Drivers Block input overlay should start hidden.'
Assert-BoostLabCondition ($taggedOverlay[0].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS first-step confirmation overlay should start hidden.'
Assert-BoostLabCondition ($taggedOverlay[1].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS BIOS Settings confirmation overlay should start hidden.'
Assert-BoostLabCondition ($taggedOverlay[2].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS To BIOS confirmation overlay should start hidden.'
Assert-BoostLabCondition ($taggedOverlay[3].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Updates Pause confirmation overlay should start hidden.'
Assert-BoostLabCondition ($taggedOverlay[4].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Driver Clean confirmation overlay should start hidden.'
Assert-BoostLabCondition ($taggedOverlay[5].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS GPU Driver Setup confirmation overlay should start hidden.'
Assert-BoostLabCondition ($taggedOverlay[6].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS NVIDIA App Install confirmation overlay should start hidden.'
Assert-BoostLabCondition ($taggedOverlay[7].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Bloatware confirmation overlay should start hidden.'
Assert-BoostLabCondition ($taggedOverlay[8].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Edge WebView confirmation overlay should start hidden.'
Assert-BoostLabCondition ($taggedOverlay[9].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Defender Optimize Assistant confirmation overlay should start hidden.'
$allConfirmationButtonAreas = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.ConfirmationButtonArea')
Assert-BoostLabCondition ($allConfirmationButtonAreas.Count -eq $taggedOverlay.Count) 'AXIS confirmation overlays should each expose one shared no-clipping button area.'
foreach ($confirmationButtonArea in $allConfirmationButtonAreas) {
    $confirmationOpenButton = @(Get-AxisFirstUseWizardTaggedElements -Root $confirmationButtonArea -Tag 'AxisFirstUseWizard.ConfirmationOpenButton') | Select-Object -First 1
    $confirmationReturnButton = @(Get-AxisFirstUseWizardTaggedElements -Root $confirmationButtonArea -Tag 'AxisFirstUseWizard.ConfirmationReturnButton') | Select-Object -First 1
    $confirmationReturnSpacer = @(Get-AxisFirstUseWizardTaggedElements -Root $confirmationButtonArea -Tag 'AxisFirstUseWizard.ConfirmationReturnButtonSpacer') | Select-Object -First 1
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($confirmationButtonArea) -eq 'AxisFirstUseWizard.ConfirmationButtonAreaNoClipping') 'AXIS shared confirmation button rows should expose the no-clipping marker.'
    Assert-BoostLabCondition ($null -ne $confirmationOpenButton -and $null -ne $confirmationReturnButton -and $null -ne $confirmationReturnSpacer) 'AXIS shared confirmation button rows should contain primary, spacer, and Return controls.'
    Assert-BoostLabCondition ([double]$confirmationReturnButton.Width -ge 118.0) 'AXIS shared confirmation Return buttons should be wide enough for Arabic text.'
    Assert-BoostLabCondition ([double]$confirmationReturnSpacer.Width -eq 16.0) 'AXIS shared confirmation button rows should keep a clear 16px gap.'
    Assert-BoostLabCondition ([double]$confirmationButtonArea.MinWidth -ge ([double]$confirmationOpenButton.Width + [double]$confirmationReturnSpacer.Width + [double]$confirmationReturnButton.Width)) 'AXIS shared confirmation button rows should reserve enough width for long primary labels plus Return.'
}
Assert-BoostLabCondition ($taggedConfirmationRightAlignedGroup.Count -eq 1) 'AXIS confirmation overlay should use one right-aligned inner vertical group.'
Assert-BoostLabCondition ($taggedConfirmationRightAlignedGroup[0] -is [System.Windows.Controls.StackPanel]) 'AXIS confirmation right-aligned group should be a StackPanel.'
Assert-BoostLabCondition ($taggedConfirmationRightAlignedGroup[0].HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) 'AXIS confirmation inner group should be right-aligned without resizing the overlay.'
Assert-BoostLabCondition ([double]::IsNaN([double]$taggedConfirmationRightAlignedGroup[0].Width)) 'AXIS confirmation inner group should not reintroduce a fixed compact overlay width.'
Assert-BoostLabCondition ($taggedAcknowledgementRightAnchorRow.Count -eq 1) 'AXIS confirmation acknowledgement should use a compact physical right-anchor row.'
Assert-BoostLabCondition ($taggedAcknowledgementRightAnchorRow[0] -is [System.Windows.Controls.StackPanel]) 'AXIS confirmation acknowledgement row should be a compact StackPanel.'
Assert-BoostLabCondition ($taggedAcknowledgementRightAnchorRow[0].HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) 'AXIS confirmation acknowledgement row should be physically anchored to the right.'
Assert-BoostLabCondition ($taggedAcknowledgementRightAnchorRow[0].FlowDirection -eq [System.Windows.FlowDirection]::LeftToRight) 'AXIS confirmation acknowledgement row should use physical LTR ordering so the checkbox stays rightmost.'
Assert-BoostLabCondition ($taggedAcknowledgementRightAnchorRow[0].Children.Count -eq 2) 'AXIS confirmation acknowledgement row should contain only the label and checkbox.'
Assert-BoostLabCondition ($taggedOverlayAcknowledgementText.Count -eq 1) 'AXIS confirmation acknowledgement text block is missing.'
[void](Assert-AxisFirstUseWizardForegroundColor -Element $taggedOverlayAcknowledgementText[0] -ExpectedColor $axisDefaultAcknowledgementForeground -Name 'BIOS Drivers & Downloads acknowledgement text')
[void](Assert-AxisFirstUseWizardForegroundNotColor -Element $taggedOverlayAcknowledgementText[0] -RejectedColor $axisRejectedAcknowledgementAccentForeground -Name 'BIOS Drivers & Downloads acknowledgement text')
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($taggedOverlayAcknowledgementText[0]) -ne 'AxisFirstUseWizard.AcknowledgementAccentForeground') 'AXIS acknowledgement text should not expose the rejected acknowledgement accent marker.'
Assert-BoostLabCondition ([string]$taggedOverlayAcknowledgementText[0].Text -eq $arabicAcknowledgement) 'AXIS confirmation checkbox text changed.'
Assert-BoostLabCondition ($taggedOverlayAcknowledgementText[0].FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) 'AXIS confirmation acknowledgement text should use RTL flow.'
Assert-BoostLabCondition ($taggedOverlayAcknowledgementText[0].TextAlignment -eq [System.Windows.TextAlignment]::Right) 'AXIS confirmation acknowledgement text should be right-aligned.'
Assert-BoostLabCondition ($taggedOverlayAcknowledgementText[0].HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) 'AXIS confirmation acknowledgement text should be physically right-anchored inside the compact row.'
Assert-BoostLabCondition ([double]$taggedOverlayAcknowledgementText[0].Margin.Right -ge 6.0 -and [double]$taggedOverlayAcknowledgementText[0].Margin.Right -le 10.0) 'AXIS confirmation checkbox text should keep a close 6-10px gap from the checkbox square.'
Assert-BoostLabCondition ($taggedOverlayAcknowledgement.Count -eq 1) 'AXIS confirmation overlay acknowledgement checkbox is missing.'
Assert-BoostLabCondition ($null -eq $taggedOverlayAcknowledgement[0].Content) 'AXIS confirmation checkbox should not use separated CheckBox content.'
Assert-BoostLabCondition ($null -ne $taggedOverlayAcknowledgement[0].Style) 'AXIS confirmation checkbox should use the local filled-square checkbox style.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($taggedOverlayAcknowledgement[0]) -eq 'AxisFirstUseWizard.AcknowledgementBlueFilledSquareCheckbox') 'AXIS confirmation checkbox should expose the blue filled-square visual marker.'
Assert-BoostLabCondition ([double]$taggedOverlayAcknowledgement[0].Width -eq 16.0 -and [double]$taggedOverlayAcknowledgement[0].Height -eq 16.0) 'AXIS confirmation checkbox should remain a small square control.'
Assert-BoostLabCondition ($prototypeSource.Contains('InnerFill')) 'AXIS confirmation checkbox template should use an inner filled square.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.AcknowledgementBlueFilledSquareCheckbox')) 'AXIS confirmation checkbox source should include the blue filled-square marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('Background="#2563EB"')) 'AXIS confirmation checkbox checked inner fill should use the owner-approved blue.'
Assert-BoostLabCondition (-not $prototypeSource.Contains('Background="#0C0C0C"')) 'AXIS confirmation checkbox checked inner fill should not remain black.'
Assert-BoostLabCondition (-not $prototypeSource.Contains('CheckMark')) 'AXIS confirmation checkbox checked state should not use a default check mark glyph marker.'
Assert-BoostLabCondition ($taggedOverlayAcknowledgement[0].FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) 'AXIS confirmation checkbox should use RTL flow.'
Assert-BoostLabCondition ($taggedOverlayAcknowledgement[0].HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) 'AXIS confirmation checkbox should stay as a compact right-aligned RTL row.'
Assert-BoostLabCondition ($taggedOverlayAcknowledgement[0].HorizontalContentAlignment -eq [System.Windows.HorizontalAlignment]::Right) 'AXIS confirmation checkbox content should be right-aligned.'
Assert-BoostLabCondition ($taggedAcknowledgementRightAnchorRow[0].Children[1] -eq $taggedOverlayAcknowledgement[0]) 'AXIS confirmation checkbox should be the rightmost element in the compact row.'
Assert-BoostLabCondition ([double]$taggedOverlayAcknowledgement[0].Margin.Bottom -eq 0.0) 'AXIS confirmation checkbox should not rely on bottom margin for overlay control spacing.'
Assert-BoostLabCondition ($taggedOverlayControlSpacer.Count -eq 1) 'AXIS confirmation overlay should use an explicit spacer between checkbox and button area.'
Assert-BoostLabCondition ([double]$taggedOverlayControlSpacer[0].Height -ge 12.0 -and [double]$taggedOverlayControlSpacer[0].Height -le 20.0) 'AXIS confirmation overlay spacer should provide a clear 12-20px gap.'
Assert-BoostLabCondition ($taggedOverlayButtonArea.Count -eq 1) 'AXIS confirmation overlay button area is missing.'
Assert-BoostLabCondition ($taggedOverlayButtonArea[0].FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) 'AXIS confirmation overlay button area should use RTL flow.'
Assert-BoostLabCondition ($taggedOverlayButtonArea[0].HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) 'AXIS confirmation overlay button area should align to the right.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($taggedOverlayButtonArea[0]) -eq 'AxisFirstUseWizard.ConfirmationButtonAreaNoClipping') 'AXIS confirmation overlay button area should expose the shared no-clipping marker.'
Assert-BoostLabCondition ($taggedOverlayReturnButtonSpacer.Count -eq 1) 'AXIS confirmation overlay should space Open and Return with an explicit spacer.'
Assert-BoostLabCondition ([double]$taggedOverlayReturnButtonSpacer[0].Width -eq 16.0) 'AXIS confirmation overlay Return spacer should provide the shared no-clipping gap.'
Assert-BoostLabCondition (@($taggedConfirmationRightAlignedGroup[0].Children) -contains $taggedAcknowledgementRightAnchorRow[0]) 'AXIS confirmation checkbox row should be inside the same right-aligned inner group.'
Assert-BoostLabCondition (@($taggedConfirmationRightAlignedGroup[0].Children) -contains $taggedOverlayButtonArea[0]) 'AXIS confirmation Open button area should be inside the same right-aligned inner group.'
Assert-BoostLabCondition ($taggedOverlayOpenButton.Count -eq 1) 'AXIS confirmation overlay Open button is missing.'
Assert-BoostLabCondition ([string]$taggedOverlayOpenButton[0].Content -eq $arabicOpen) 'AXIS confirmation button should reuse the owner-approved Open label.'
Assert-BoostLabCondition ([double]$taggedOverlayOpenButton[0].Margin.Top -eq 0.0) 'AXIS confirmation button should not rely on top margin for overlay spacing.'
Assert-BoostLabCondition ($taggedOverlayReturnButton.Count -eq 1) 'AXIS confirmation overlay Return button is missing.'
Assert-BoostLabCondition ([string]$taggedOverlayReturnButton[0].Content -eq $arabicReturn) 'AXIS confirmation Return button should use owner-approved Arabic Return.'
Assert-BoostLabCondition ([double]$taggedOverlayReturnButton[0].Width -ge 118.0) 'AXIS confirmation Return button should be wide enough for unclipped Arabic text.'
Assert-BoostLabCondition ([double]$taggedOverlayButtonArea[0].MinWidth -ge ([double]$taggedOverlayOpenButton[0].Width + [double]$taggedOverlayReturnButtonSpacer[0].Width + [double]$taggedOverlayReturnButton[0].Width)) 'AXIS confirmation overlay button row should reserve enough width for both buttons and the gap.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($taggedOverlayReturnButton[0]) -eq 'AxisFirstUseWizard.ConfirmationReturnOnlyClosesOverlay') 'AXIS confirmation Return should be marked as overlay-only close behavior.'
Assert-BoostLabCondition ([bool]$taggedOverlayReturnButton[0].IsEnabled) 'AXIS confirmation Return should always be available.'
Assert-BoostLabCondition (@($taggedOverlayButtonArea[0].Children) -contains $taggedOverlayOpenButton[0]) 'AXIS confirmation Open button should stay in the overlay button row.'
Assert-BoostLabCondition (@($taggedOverlayButtonArea[0].Children) -contains $taggedOverlayReturnButton[0]) 'AXIS confirmation Return button should stay beside Open in the overlay button row.'
Assert-BoostLabCondition (-not [bool]$taggedOverlayOpenButton[0].IsEnabled) 'AXIS confirmation button should be disabled until acknowledgement is checked.'
$taggedOverlayAcknowledgement[0].IsChecked = $true
Assert-BoostLabCondition ([bool]$taggedOverlayOpenButton[0].IsEnabled) 'AXIS confirmation button should enable after acknowledgement is checked.'
Assert-AxisFirstUseWizardNextDisabledNonBlue -Button $taggedContinueButtons[0] -Name 'BIOS Drivers & Downloads after confirmation acknowledgement'
$taggedOverlayAcknowledgement[0].IsChecked = $false
Assert-BoostLabCondition (-not [bool]$taggedOverlayOpenButton[0].IsEnabled) 'AXIS confirmation button should disable again if acknowledgement is unchecked.'

Invoke-AxisFirstUseWizardButtonClick -Button $taggedPrimaryOpenButton[0]
Assert-BoostLabCondition ($taggedOverlay[0].Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS primary Open should reveal the confirmation overlay without showing a real browser/runtime action.'
Assert-BoostLabCondition (-not [bool]$taggedOverlayOpenButton[0].IsEnabled) 'AXIS confirmation Open should be disabled when the overlay first opens.'
$taggedOverlayAcknowledgement[0].IsChecked = $true
Assert-BoostLabCondition ([bool]$taggedOverlayOpenButton[0].IsEnabled) 'AXIS confirmation Open should enable after acknowledgement before Return is tested.'
Invoke-AxisFirstUseWizardButtonClick -Button $taggedOverlayReturnButton[0]
Assert-BoostLabCondition ($taggedOverlay[0].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS confirmation Return should close only the overlay.'
Assert-BoostLabCondition (-not [bool]$taggedOverlayAcknowledgement[0].IsChecked) 'AXIS confirmation Return should reset acknowledgement to unchecked.'
Assert-BoostLabCondition (-not [bool]$taggedOverlayOpenButton[0].IsEnabled) 'AXIS confirmation Return should leave overlay Open disabled after reset.'
Assert-BoostLabCondition (-not [bool]$taggedContinueButtons[0].IsEnabled) 'AXIS confirmation Return must not enable Continue/Next.'
Assert-BoostLabCondition ($taggedRuntimeStatusArea[0].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS confirmation Return must not start checking runtime status.'
$afterReturnText = (Get-AxisFirstUseWizardTextValues -Root $taggedContentHost[0].Child) -join [Environment]::NewLine
Assert-BoostLabCondition (-not $afterReturnText.Contains($arabicChecking)) 'AXIS confirmation Return must not show checking text.'
Assert-BoostLabCondition (-not $afterReturnText.Contains($arabicCompleted)) 'AXIS confirmation Return must not show completed text.'
Invoke-AxisFirstUseWizardButtonClick -Button $taggedPrimaryOpenButton[0]
Assert-BoostLabCondition ($taggedOverlay[0].Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS primary Open should reopen the confirmation overlay after Return.'
Assert-BoostLabCondition (-not [bool]$taggedOverlayAcknowledgement[0].IsChecked) 'AXIS reopened confirmation overlay should keep acknowledgement reset.'
Assert-BoostLabCondition (-not [bool]$taggedOverlayOpenButton[0].IsEnabled) 'AXIS reopened confirmation overlay should keep Open disabled until acknowledgement is checked.'
$taggedOverlayAcknowledgement[0].IsChecked = $true
Invoke-AxisFirstUseWizardButtonClick -Button $taggedOverlayOpenButton[0]
Assert-BoostLabCondition ($taggedOverlay[0].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS confirmation Open should close the overlay after acknowledgement.'
$interactiveCheckingText = (Get-AxisFirstUseWizardTextValues -Root $taggedContentHost[0].Child) -join [Environment]::NewLine
Assert-BoostLabCondition ($interactiveCheckingText.Contains($arabicChecking)) 'AXIS confirmation Open should transition to the Arabic checking state.'
Assert-BoostLabCondition ($interactiveCheckingText.Contains($arabicSupportBody)) 'AXIS support panel should remain visible during the checking state.'
Assert-BoostLabCondition ($taggedRuntimeStatusArea[0].Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS runtime status area should become visible during checking.'
Assert-BoostLabCondition ($taggedActionRuntimeStatusSpacer[0].Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS runtime status spacer should become visible during checking.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $taggedRuntimeStatusArea[0] -Tag 'AxisFirstUseWizard.CheckingAnimation').Count -eq 1) 'AXIS checking animation should render inside the compact runtime status area.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $taggedRuntimeStatusArea[0] -Tag 'AxisFirstUseWizard.RuntimeStatusArabicRightAnchor').Count -eq 1) 'AXIS checking runtime status should use a physical Arabic right anchor.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $taggedRuntimeStatusArea[0] -Tag 'AxisFirstUseWizard.SupportPanel').Count -eq 0) 'AXIS support panel must not be nested inside the runtime status area.'
$completedByTimer = Wait-AxisFirstUseWizardCondition -Condition { [bool]$taggedContinueButtons[0].IsEnabled } -TimeoutMilliseconds 3000
Assert-BoostLabCondition ([bool]$completedByTimer) 'AXIS confirmation Open should complete the simulated checking flow and enable Continue/Next.'
$interactiveCompletedText = (Get-AxisFirstUseWizardTextValues -Root $taggedContentHost[0].Child) -join [Environment]::NewLine
Assert-BoostLabCondition ($interactiveCompletedText.Contains($arabicCompleted)) 'AXIS simulated checking flow should transition to the Arabic completed state.'
Assert-BoostLabCondition ($interactiveCompletedText.Contains($arabicSupportBody)) 'AXIS support panel should remain visible after completion.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $taggedRuntimeStatusArea[0] -Tag 'AxisFirstUseWizard.CompletedEffect').Count -eq 1) 'AXIS completed effect should render inside the compact runtime status area.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $taggedRuntimeStatusArea[0] -Tag 'AxisFirstUseWizard.RuntimeStatusArabicRightAnchor').Count -eq 1) 'AXIS completed runtime status should use a physical Arabic right anchor.'
$interactiveCompletedGlow = @(Get-AxisFirstUseWizardTaggedElements -Root $taggedRuntimeStatusArea[0] -Tag 'AxisFirstUseWizard.CompletedRuntimeSuccessGlow')
Assert-BoostLabCondition ($interactiveCompletedGlow.Count -ge 1) 'AXIS completed runtime status should expose the green success glow marker.'
Assert-BoostLabCondition (@($interactiveCompletedGlow | Where-Object { $null -ne $_.Effect }).Count -ge 1) 'AXIS completed runtime status glow marker should carry a WPF glow effect.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($taggedContinueButtons[0]) -eq 'AxisFirstUseWizard.EnabledNextButtonBlue') 'AXIS Continue/Next should expose the enabled blue marker after completion.'
Assert-BoostLabCondition ($taggedContinueButtons[0].Background -is [System.Windows.Media.SolidColorBrush]) 'AXIS enabled Continue/Next should use a solid blue fill.'
Assert-BoostLabCondition ([string]([System.Windows.Media.SolidColorBrush]$taggedContinueButtons[0].Background).Color -eq '#FF2563EB') 'AXIS enabled Continue/Next should become blue after completion.'
Assert-BoostLabCondition ([string]([System.Windows.Media.SolidColorBrush]$taggedContinueButtons[0].Foreground).Color -eq '#FFFAF9F6') 'AXIS enabled Continue/Next should keep readable off-white text.'
Assert-BoostLabCondition ([string]$taggedContinueButtons[0].Resources['AxisFirstUseWizard.EnabledNextButtonHoverReadable'] -eq 'BlueHoverKeepsReadableText') 'AXIS enabled Continue/Next should expose the readable hover marker after completion.'
Assert-BoostLabCondition ([string]([System.Windows.Media.SolidColorBrush]$taggedContinueButtons[0].Resources['AxisFirstUseWizard.ButtonHoverBackground']).Color -eq '#FF1D4ED8') 'AXIS enabled Continue/Next hover should stay blue instead of switching to the light primary hover.'
Assert-BoostLabCondition ([string]([System.Windows.Media.SolidColorBrush]$taggedContinueButtons[0].Resources['AxisFirstUseWizard.ButtonHoverBorder']).Color -eq '#FF93C5FD') 'AXIS enabled Continue/Next hover border should keep readable blue-family contrast.'
Assert-BoostLabCondition ([string]([System.Windows.Media.SolidColorBrush]$taggedContinueButtons[0].Resources['AxisFirstUseWizard.ButtonHoverBackground']).Color -ne '#FFF5F5F5') 'AXIS enabled Continue/Next hover must not become white/light with off-white text.'

Invoke-AxisFirstUseWizardButtonClick -Button $taggedContinueButtons[0]
$biosSettingsVisibleContent = $taggedContentHost[0].Child
$biosSettingsVisibleText = (Get-AxisFirstUseWizardTextValues -Root $biosSettingsVisibleContent) -join [Environment]::NewLine
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsVisibleContent -Tag 'AxisFirstUseWizard.BiosSettingsStep').Count -eq 1) 'AXIS Continue/Next from completed BIOS Drivers should move to BIOS Settings.'
Assert-BoostLabCondition ([string]$initialCurrentStageHeader.Text -eq 'Check') 'AXIS BIOS Settings current stage header should remain Check.'
[void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressCheckFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineActiveFullWhite.Check' -ExpectedColor '#FFF0F2F5' -Name 'BIOS Settings Check active')
[void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressRefreshFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineInactiveDim.Refresh' -ExpectedColor '#FF242424' -Name 'BIOS Settings Refresh inactive')
$activeStageItems = @(
    $stripItems |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_).StartsWith('AxisFirstUseWizard.StageProgressActive.') }
)
$completedStageItems = @(
    $stripItems |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_).StartsWith('AxisFirstUseWizard.StageProgressCompleted.') }
)
Assert-BoostLabCondition ($activeStageItems.Count -eq 1) 'AXIS BIOS Settings should still expose exactly one active stage marker.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($activeStageItems[0]) -eq 'AxisFirstUseWizard.StageProgressActive.Check') 'AXIS BIOS Settings active stage marker should remain Check.'
Assert-BoostLabCondition ($completedStageItems.Count -eq 0) 'AXIS BIOS Settings should not mark Check completed while still on Check.'
Assert-BoostLabCondition (-not [bool]$taggedContinueButtons[0].IsEnabled) 'AXIS BIOS Settings Continue/Next should start disabled.'
foreach ($requiredBiosSettingsText in @(
    'BIOS Settings'
    $arabicBiosSettingsSubtitle
    $arabicBiosSettingsInfoTitle
    $arabicIntelRam
    $arabicIntelCStates
    $arabicIntelRebar
    $arabicIntelIgpu
    $arabicMsiUtility
    $arabicRestart
    $arabicDocumentation
    $arabicSupportTitle
    $arabicSupportBody
)) {
    Assert-BoostLabCondition ($biosSettingsVisibleText.Contains($requiredBiosSettingsText)) "AXIS BIOS Settings view is missing owner-approved text: $requiredBiosSettingsText"
}
Assert-BoostLabCondition ($arabicAmdRebar -eq $arabicIntelRebar) 'AXIS BIOS Settings AMD and Intel Resizable BAR labels should share the punctuation-approved text.'
Assert-BoostLabCondition (-not $arabicIntelRebar.EndsWith('.')) 'AXIS BIOS Settings Resizable BAR label should not end with a trailing dot.'
$biosSettingsRequirementItems = @(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsVisibleContent -Tag 'AxisFirstUseWizard.BiosSettingsRequirementItem')
Assert-BoostLabCondition ($biosSettingsRequirementItems.Count -eq 0) 'AXIS BIOS Settings requirements should not render after Phase 178E removal.'
$biosSettingsTextBlocks = @(Get-AxisFirstUseWizardTypedElements -Root $biosSettingsVisibleContent -Type ([System.Windows.Controls.TextBlock]))
foreach ($biosSettingsTextBlock in $biosSettingsTextBlocks) {
    Assert-BoostLabCondition ($biosSettingsTextBlock.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS BIOS Settings text blocks should remain visible, not hidden to avoid clipping.'
}
foreach ($hiddenBiosSettingsText in @(
    $arabicBiosSettingsInfoIntro
    $arabicIntelTitle
    $arabicAmdTitle
    $arabicAmdPbo
    $arabicMotherboardTitle
    $arabicMotherboardIntro
    $arabicRequirementsTitle
    $arabicReqNavigation
    $arabicReqSupport
    $oldArabicIntelRebar
    $oldArabicIntelCStates
    $oldArabicRestartAcknowledgement
    $arabicAsusUtility
    $arabicGigabyteUtility
    $arabicAsrockUtility
)) {
    Assert-BoostLabCondition (-not $biosSettingsVisibleText.Contains($hiddenBiosSettingsText)) "AXIS BIOS Settings default Intel/MSI mock view should not show removed or non-matching content: $hiddenBiosSettingsText"
}
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsVisibleContent -Tag 'AxisFirstUseWizard.BiosSettingsVisibleIntelGroup').Count -eq 0) 'AXIS BIOS Settings should not expose the removed visible Intel group marker.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsVisibleContent -Tag 'AxisFirstUseWizard.BiosSettingsVisibleMsiUtility').Count -eq 1) 'AXIS BIOS Settings should expose the visible MSI utility marker.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsVisibleContent -Tag 'AxisFirstUseWizard.BiosSettingsVisibleAsusUtility').Count -eq 0) 'AXIS BIOS Settings should not expose the old ASUS utility marker.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsVisibleContent -Tag 'AxisFirstUseWizard.BiosSettingsRequirementsCard').Count -eq 0) 'AXIS BIOS Settings should not render the removed requirements card.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsVisibleContent -Tag 'AxisFirstUseWizard.BiosSettingsRequirementsTitle').Count -eq 0) 'AXIS BIOS Settings should not render the removed requirements title.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsVisibleContent -Tag 'AxisFirstUseWizard.SupportPanel').Count -eq 1) 'AXIS BIOS Settings support panel should remain separate and visible.'
$biosSettingsNoClippingMarkers = @(
    Get-AxisFirstUseWizardTypedElements -Root $biosSettingsVisibleContent -Type ([System.Windows.FrameworkElement]) |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_) -eq 'AxisFirstUseWizard.BiosSettingsNoClippingLayout' }
)
Assert-BoostLabCondition ($biosSettingsNoClippingMarkers.Count -ge 2) 'AXIS BIOS Settings should expose the no-clipping layout marker on the step and details region.'
$biosSettingsStepElement = @(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsVisibleContent -Tag 'AxisFirstUseWizard.BiosSettingsStep') | Select-Object -First 1
$biosSettingsContentGrid = @(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsVisibleContent -Tag 'AxisFirstUseWizard.StepTextContent') | Select-Object -First 1
$biosSettingsDetails = @(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsVisibleContent -Tag 'AxisFirstUseWizard.BiosSettingsDetails') | Select-Object -First 1
$biosSettingsInformationCard = @(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsVisibleContent -Tag 'AxisFirstUseWizard.BiosSettingsInformationCard') | Select-Object -First 1
$biosSettingsInformationTitle = @(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsVisibleContent -Tag 'AxisFirstUseWizard.BiosSettingsInformationTitle') | Select-Object -First 1
$biosSettingsActionArea = @(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsVisibleContent -Tag 'AxisFirstUseWizard.PrimaryActionArea') | Select-Object -First 1
$biosSettingsSupportPanel = @(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsVisibleContent -Tag 'AxisFirstUseWizard.SupportPanel') | Select-Object -First 1
$biosSettingsDocumentationButton = @(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsVisibleContent -Tag 'AxisFirstUseWizard.DocumentationButton') | Select-Object -First 1
Assert-BoostLabCondition ([double]$biosSettingsStepElement.Height -eq 382.0) 'AXIS BIOS Settings should fit inside the 900x650 preview client area without clipping.'
Assert-BoostLabCondition ([double]$taggedBiosInformationStep[0].Height -eq 382.0) 'AXIS BIOS Drivers & Downloads card height should remain unchanged by BIOS Settings clipping fix.'
Assert-BoostLabCondition ($null -ne $biosSettingsInformationTitle) 'AXIS BIOS Settings information title is missing.'
[void](Assert-AxisFirstUseWizardForegroundColor -Element $biosSettingsInformationTitle -ExpectedColor $axisDefaultCardTitleForeground -Name 'BIOS Settings information card title')
[void](Assert-AxisFirstUseWizardForegroundNotColor -Element $biosSettingsInformationTitle -RejectedColor $axisRejectedInformationCardTitleForeground -Name 'BIOS Settings information card title')
Assert-BoostLabCondition ($null -ne $biosSettingsDocumentationButton) 'AXIS BIOS Settings documentation button is missing.'
[void](Assert-AxisFirstUseWizardForegroundColor -Element $biosSettingsDocumentationButton -ExpectedColor $axisDefaultDocumentationForeground -Name 'BIOS Settings documentation button')
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($biosSettingsDocumentationButton) -eq 'AxisFirstUseWizard.DocumentationDefaultForeground') 'AXIS BIOS Settings documentation button should expose the default foreground marker.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($biosSettingsActionArea) -eq 'AxisFirstUseWizard.BiosSettingsActionRowSeparated') 'AXIS BIOS Settings action row should expose the separated action-row marker.'
Assert-BoostLabCondition ($biosSettingsContentGrid.Children.IndexOf($biosSettingsDetails) -lt $biosSettingsContentGrid.Children.IndexOf($biosSettingsActionArea)) 'AXIS BIOS Settings details must appear before the action row.'
Assert-BoostLabCondition ($biosSettingsContentGrid.Children.IndexOf($biosSettingsActionArea) -lt $biosSettingsContentGrid.Children.IndexOf($biosSettingsSupportPanel)) 'AXIS BIOS Settings action row must remain separated above the support panel.'
Assert-BoostLabCondition ($biosSettingsSupportPanel.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS BIOS Settings support panel should be visible before the simulated restart flow.'
$biosSettingsCompactInformationMarkers = @(
    Get-AxisFirstUseWizardTypedElements -Root $biosSettingsVisibleContent -Type ([System.Windows.FrameworkElement]) |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_) -eq 'AxisFirstUseWizard.BiosSettingsCompactInformationColumns' }
)
Assert-BoostLabCondition ($biosSettingsCompactInformationMarkers.Count -eq 1) 'AXIS BIOS Settings should use compact information columns instead of a clipping-prone single long stack.'
$biosSettingsStepElement.Measure([System.Windows.Size]::new(826.0, 389.0))
$biosSettingsRowTotal = 0.0
foreach ($biosSettingsRowChild in @($biosSettingsContentGrid.Children)) {
    $biosSettingsRowChild.Measure([System.Windows.Size]::new(758.0, [double]::PositiveInfinity))
    $biosSettingsRowTotal += [double]$biosSettingsRowChild.DesiredSize.Height
}
$biosSettingsInnerHeight = [double]$biosSettingsStepElement.Height -
    [double]$biosSettingsStepElement.Padding.Top -
    [double]$biosSettingsStepElement.Padding.Bottom -
    [double]$biosSettingsStepElement.BorderThickness.Top -
    [double]$biosSettingsStepElement.BorderThickness.Bottom
Assert-BoostLabCondition ($biosSettingsRowTotal -le $biosSettingsInnerHeight) 'AXIS BIOS Settings row content should fit inside the card without bottom clipping.'
Assert-BoostLabCondition ([double]$biosSettingsInformationCard.Height -eq 144.0) 'AXIS BIOS Settings information card should use the shorter 178E height after requirements removal.'
$biosSettingsInformationCard.Child.Measure([System.Windows.Size]::new([double]::PositiveInfinity, [double]::PositiveInfinity))
$biosSettingsInformationCardInnerHeight = [double]$biosSettingsInformationCard.Height - [double]$biosSettingsInformationCard.Padding.Top - [double]$biosSettingsInformationCard.Padding.Bottom
Assert-BoostLabCondition ([double]$biosSettingsInformationCard.Child.DesiredSize.Height -le $biosSettingsInformationCardInnerHeight) 'AXIS BIOS Settings information card content should fit without clipping inside its reserved card height.'

$taggedBackButtons = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.BackButton')
Assert-BoostLabCondition ($taggedBackButtons.Count -eq 1) 'AXIS first-use wizard footer Back button should be tagged for navigation.'
Invoke-AxisFirstUseWizardButtonClick -Button $taggedBackButtons[0]
$returnedFirstStepText = (Get-AxisFirstUseWizardTextValues -Root $taggedContentHost[0].Child) -join [Environment]::NewLine
Assert-BoostLabCondition ($returnedFirstStepText.Contains('BIOS Drivers & Downloads')) 'AXIS Back from BIOS Settings should return to BIOS Drivers & Downloads.'
Assert-BoostLabCondition ([bool]$taggedContinueButtons[0].IsEnabled) 'AXIS Continue/Next should remain enabled when returning to the completed first step.'
Assert-BoostLabCondition ([string]$taggedContinueButtons[0].Resources['AxisFirstUseWizard.EnabledNextButtonHoverReadable'] -eq 'BlueHoverKeepsReadableText') 'AXIS Continue/Next readable hover marker should be restored when navigating back to a completed step.'
Assert-BoostLabCondition ([string]([System.Windows.Media.SolidColorBrush]$taggedContinueButtons[0].Resources['AxisFirstUseWizard.ButtonHoverBackground']).Color -eq '#FF1D4ED8') 'AXIS Continue/Next hover should stay blue when restored by navigation.'
Invoke-AxisFirstUseWizardButtonClick -Button $taggedContinueButtons[0]
$biosSettingsVisibleContent = $taggedContentHost[0].Child
$biosSettingsOverlay = $taggedOverlay[1]
$biosSettingsPrimaryButton = @(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsVisibleContent -Tag 'AxisFirstUseWizard.PrimaryOpenButton') | Select-Object -First 1
$biosSettingsRuntimeStatusArea = @(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsVisibleContent -Tag 'AxisFirstUseWizard.RuntimeStatusArea') | Select-Object -First 1
$biosSettingsRuntimeStatusSpacer = @(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsVisibleContent -Tag 'AxisFirstUseWizard.ActionRuntimeStatusSpacer') | Select-Object -First 1
$biosSettingsSupportPanel = @(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsVisibleContent -Tag 'AxisFirstUseWizard.SupportPanel') | Select-Object -First 1
$biosSettingsOverlayAcknowledgement = @(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsOverlay -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgement') | Select-Object -First 1
$biosSettingsOverlayAcknowledgementText = @(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsOverlay -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgementText') | Select-Object -First 1
$biosSettingsOverlayOpenButton = @(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsOverlay -Tag 'AxisFirstUseWizard.ConfirmationOpenButton') | Select-Object -First 1
$biosSettingsOverlayReturnButton = @(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsOverlay -Tag 'AxisFirstUseWizard.ConfirmationReturnButton') | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $biosSettingsPrimaryButton) 'AXIS BIOS Settings primary restart button is missing.'
Assert-BoostLabCondition ([string]$biosSettingsPrimaryButton.Content -eq $arabicRestart) 'AXIS BIOS Settings primary button should use owner-approved restart label.'
Assert-BoostLabCondition ($biosSettingsRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS BIOS Settings runtime status should start hidden.'
Assert-BoostLabCondition ([double]$biosSettingsRuntimeStatusArea.Width -eq 252.0) 'AXIS BIOS Settings runtime status should use the wider no-clipping width.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($biosSettingsRuntimeStatusArea) -eq 'AxisFirstUseWizard.BiosSettingsRuntimeStatusNoClipping') 'AXIS BIOS Settings runtime status should expose the no-clipping marker.'
Assert-BoostLabCondition ($biosSettingsSupportPanel.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS BIOS Settings support panel should start visible before restart confirmation.'
Assert-BoostLabCondition ([string]$biosSettingsOverlayAcknowledgementText.Text -eq $arabicRestartAcknowledgement) 'AXIS BIOS Settings confirmation checkbox text changed.'
Assert-BoostLabCondition ([string]$biosSettingsOverlayAcknowledgementText.Text -eq $arabicAcknowledgement) 'AXIS BIOS Settings confirmation checkbox should use the shortened acknowledgement text.'
Assert-BoostLabCondition (-not ([string]$biosSettingsOverlayAcknowledgementText.Text).Contains($oldArabicRestartAcknowledgement)) 'AXIS BIOS Settings confirmation checkbox should not include the old long reboot acknowledgement.'
[void](Assert-AxisFirstUseWizardForegroundColor -Element $biosSettingsOverlayAcknowledgementText -ExpectedColor $axisDefaultAcknowledgementForeground -Name 'BIOS Settings acknowledgement text')
[void](Assert-AxisFirstUseWizardForegroundNotColor -Element $biosSettingsOverlayAcknowledgementText -RejectedColor $axisRejectedAcknowledgementAccentForeground -Name 'BIOS Settings acknowledgement text')
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($biosSettingsOverlayAcknowledgementText) -ne 'AxisFirstUseWizard.AcknowledgementAccentForeground') 'AXIS BIOS Settings acknowledgement text should not expose the rejected acknowledgement accent marker.'
Assert-BoostLabCondition ([string]$biosSettingsOverlayOpenButton.Content -eq $arabicRestart) 'AXIS BIOS Settings confirmation button should use restart label.'
Assert-BoostLabCondition ([string]$biosSettingsOverlayReturnButton.Content -eq $arabicReturn) 'AXIS BIOS Settings confirmation Return button should use owner-approved Arabic Return.'
Assert-BoostLabCondition (-not [bool]$biosSettingsOverlayOpenButton.IsEnabled) 'AXIS BIOS Settings confirm button should start disabled until acknowledgement.'
Invoke-AxisFirstUseWizardButtonClick -Button $biosSettingsPrimaryButton
Assert-BoostLabCondition ($biosSettingsOverlay.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS BIOS Settings restart should reveal the confirmation overlay only.'
$biosSettingsOverlayAcknowledgement.IsChecked = $true
Assert-BoostLabCondition ([bool]$biosSettingsOverlayOpenButton.IsEnabled) 'AXIS BIOS Settings confirm should enable after acknowledgement.'
Assert-AxisFirstUseWizardNextDisabledNonBlue -Button $taggedContinueButtons[0] -Name 'BIOS Settings after confirmation acknowledgement'
Invoke-AxisFirstUseWizardButtonClick -Button $biosSettingsOverlayReturnButton
Assert-BoostLabCondition ($biosSettingsOverlay.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS BIOS Settings Return should close only the overlay.'
Assert-BoostLabCondition (-not [bool]$biosSettingsOverlayAcknowledgement.IsChecked) 'AXIS BIOS Settings Return should reset acknowledgement.'
Assert-BoostLabCondition (-not [bool]$taggedContinueButtons[0].IsEnabled) 'AXIS BIOS Settings Return must not complete the step or enable Continue/Next.'
Assert-BoostLabCondition ($biosSettingsRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS BIOS Settings Return must not start restart simulation.'
Invoke-AxisFirstUseWizardButtonClick -Button $biosSettingsPrimaryButton
$biosSettingsOverlayAcknowledgement.IsChecked = $true
Invoke-AxisFirstUseWizardButtonClick -Button $biosSettingsOverlayOpenButton
Assert-BoostLabCondition ($biosSettingsOverlay.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS BIOS Settings confirm should close the overlay.'
$biosSettingsCheckingText = (Get-AxisFirstUseWizardTextValues -Root $biosSettingsVisibleContent) -join [Environment]::NewLine
Assert-BoostLabCondition ($biosSettingsCheckingText.Contains($arabicRestarting)) 'AXIS BIOS Settings confirm should show the Arabic restarting simulation state.'
Assert-BoostLabCondition ($biosSettingsCheckingText.Contains($arabicSupportBody)) 'AXIS BIOS Settings support panel should remain visible during restart simulation.'
Assert-BoostLabCondition ($biosSettingsSupportPanel.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS BIOS Settings support panel should remain visible during restart simulation.'
Assert-BoostLabCondition ($biosSettingsRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS BIOS Settings runtime status should become visible during restart simulation.'
Assert-BoostLabCondition ($biosSettingsRuntimeStatusSpacer.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS BIOS Settings runtime status spacer should become visible during restart simulation.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsRuntimeStatusArea -Tag 'AxisFirstUseWizard.CheckingAnimation').Count -eq 1) 'AXIS BIOS Settings restart simulation should use the runtime checking animation.'
$biosSettingsRuntimeNoClippingMarkers = @(
    Get-AxisFirstUseWizardTypedElements -Root $biosSettingsRuntimeStatusArea -Type ([System.Windows.FrameworkElement]) |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_) -eq 'AxisFirstUseWizard.BiosSettingsRuntimeStatusNoClipping' }
)
Assert-BoostLabCondition ($biosSettingsRuntimeNoClippingMarkers.Count -ge 2) 'AXIS BIOS Settings runtime status should mark both the host and content as no-clipping.'
$biosSettingsRuntimeStatusRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsRuntimeStatusArea -Tag 'AxisFirstUseWizard.RuntimeStatusArabicRightAnchor')
Assert-BoostLabCondition ($biosSettingsRuntimeStatusRightAnchor.Count -eq 1) 'AXIS BIOS Settings running status should keep the runtime text near the action row.'
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $biosSettingsRuntimeStatusRightAnchor[0] -Name 'BIOS Settings running runtime status' -ExpectedMaxWidth 126)
$biosSettingsRunningStatusTextBlocks = @(Get-AxisFirstUseWizardTextBlocksByText -Root $biosSettingsRuntimeStatusArea -Text $arabicRestarting)
Assert-BoostLabCondition ($biosSettingsRunningStatusTextBlocks.Count -ge 1) 'AXIS BIOS Settings running status text should remain exact and visible.'
foreach ($biosSettingsRunningTextBlock in $biosSettingsRunningStatusTextBlocks) {
    Assert-BoostLabCondition ([string]$biosSettingsRunningTextBlock.Tag -eq 'AxisFirstUseWizard.RuntimeStatusArabicTextInset') 'AXIS BIOS Settings running status text should keep the safe Arabic text inset marker.'
    Assert-BoostLabCondition ([double]$biosSettingsRunningTextBlock.Margin.Right -ge 6.0 -and [double]$biosSettingsRunningTextBlock.Margin.Right -le 10.0) 'AXIS BIOS Settings running status text should keep a small right inset.'
}
$biosSettingsCompletedByTimer = Wait-AxisFirstUseWizardCondition -Condition { [bool]$taggedContinueButtons[0].IsEnabled } -TimeoutMilliseconds 3000
Assert-BoostLabCondition ([bool]$biosSettingsCompletedByTimer) 'AXIS BIOS Settings simulated restart flow should enable Continue/Next after completion.'
$biosSettingsCompletedText = (Get-AxisFirstUseWizardTextValues -Root $biosSettingsVisibleContent) -join [Environment]::NewLine
Assert-BoostLabCondition ($biosSettingsCompletedText.Contains($arabicCompleted)) 'AXIS BIOS Settings simulated restart flow should end in the Arabic completed state.'
Assert-BoostLabCondition ($biosSettingsCompletedText.Contains($arabicSupportBody)) 'AXIS BIOS Settings support panel should remain visible after restart simulation completion.'
Assert-BoostLabCondition ($biosSettingsSupportPanel.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS BIOS Settings support panel should remain visible after restart simulation completion.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsRuntimeStatusArea -Tag 'AxisFirstUseWizard.CompletedEffect').Count -eq 1) 'AXIS BIOS Settings completed state should render the completed runtime effect.'
$biosSettingsCompletedRuntimeStatusRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $biosSettingsRuntimeStatusArea -Tag 'AxisFirstUseWizard.RuntimeStatusArabicRightAnchor')
Assert-BoostLabCondition ($biosSettingsCompletedRuntimeStatusRightAnchor.Count -eq 1) 'AXIS BIOS Settings completed status should keep the runtime text near the action row.'
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $biosSettingsCompletedRuntimeStatusRightAnchor[0] -Name 'BIOS Settings completed runtime status' -ExpectedMaxWidth 126)
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($taggedContinueButtons[0]) -eq 'AxisFirstUseWizard.EnabledNextButtonBlue') 'AXIS BIOS Settings Continue/Next should become blue after simulated completion.'
Assert-BoostLabCondition ([string]([System.Windows.Media.SolidColorBrush]$taggedContinueButtons[0].Background).Color -eq '#FF2563EB') 'AXIS BIOS Settings enabled Continue/Next should use the approved blue fill.'

Invoke-AxisFirstUseWizardButtonClick -Button $taggedContinueButtons[0]
$reinstallVisibleContent = $taggedContentHost[0].Child
$reinstallVisibleText = (Get-AxisFirstUseWizardTextValues -Root $reinstallVisibleContent) -join [Environment]::NewLine
$currentStageHeader = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.CurrentStageHeader') | Select-Object -First 1
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.ReinstallStep').Count -eq 1) 'AXIS Continue/Next from completed BIOS Settings should move to Reinstall.'
Assert-BoostLabCondition ($null -ne $currentStageHeader) 'AXIS current stage header should be tagged for step navigation verification.'
Assert-BoostLabCondition ([string]$currentStageHeader.Text -eq 'Refresh') 'AXIS Reinstall current stage header should show Refresh.'
[void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressCheckFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Check' -ExpectedColor '#FF22C55E' -Name 'Reinstall Check completed')
[void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressRefreshFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineActiveFullWhite.Refresh' -ExpectedColor '#FFF0F2F5' -Name 'Reinstall Refresh active')
$activeStageItems = @(
    $stripItems |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_).StartsWith('AxisFirstUseWizard.StageProgressActive.') }
)
$completedStageItems = @(
    $stripItems |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_).StartsWith('AxisFirstUseWizard.StageProgressCompleted.') }
)
Assert-BoostLabCondition ($activeStageItems.Count -eq 1) 'AXIS Reinstall should expose exactly one active stage marker.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($activeStageItems[0]) -eq 'AxisFirstUseWizard.StageProgressActive.Refresh') 'AXIS Reinstall active stage marker should be Refresh.'
Assert-BoostLabCondition ($completedStageItems.Count -eq 1) 'AXIS Reinstall should expose exactly one completed previous stage marker.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($completedStageItems[0]) -eq 'AxisFirstUseWizard.StageProgressCompleted.Check') 'AXIS Reinstall completed stage marker should be Check.'
Assert-BoostLabCondition (-not [bool]$taggedContinueButtons[0].IsEnabled) 'AXIS Reinstall Continue/Next should start disabled.'
foreach ($requiredReinstallText in @(
    'Refresh'
    $arabicReinstallTitle
    $arabicReinstallSubtitle
    $arabicReinstallInfoTitle
    $arabicReinstallInfoBullet
    $arabicRequirementsTitle
    $arabicReinstallRequirementUsbSize
    $arabicReinstallRequirementNoData
    $arabicReinstallPrimaryAction
    $arabicDocumentation
    $arabicSupportTitle
    $arabicSupportBody
)) {
    Assert-BoostLabCondition ($reinstallVisibleText.Contains($requiredReinstallText)) "AXIS Reinstall view is missing owner-approved text: $requiredReinstallText"
}
foreach ($forbiddenReinstallInternalText in @(
    'Analyze'
    'Open'
    'Apply'
    'Default'
    'Restore'
    'Cancel'
)) {
    Assert-BoostLabCondition (-not $reinstallVisibleText.Contains($forbiddenReinstallInternalText)) "AXIS Reinstall view exposes forbidden internal/customer action text: $forbiddenReinstallInternalText"
}
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.ConfirmationOverlay').Count -eq 0) 'AXIS Reinstall content must not include a confirmation overlay.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgement').Count -eq 0) 'AXIS Reinstall content must not include a confirmation checkbox.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.ConfirmationReturnButton').Count -eq 0) 'AXIS Reinstall content must not include an overlay Return button.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.ReinstallInformationCard').Count -eq 1) 'AXIS Reinstall should render one information card.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.ReinstallRequirementsCard').Count -eq 1) 'AXIS Reinstall should render one requirements card.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.ReinstallRequirementItem').Count -eq 2) 'AXIS Reinstall should render both owner-approved requirements.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.SupportPanel').Count -eq 1) 'AXIS Reinstall support panel should remain separate and visible.'
$reinstallNoClippingMarkers = @(
    Get-AxisFirstUseWizardTypedElements -Root $reinstallVisibleContent -Type ([System.Windows.FrameworkElement]) |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_) -eq 'AxisFirstUseWizard.ReinstallNoClippingLayout' }
)
Assert-BoostLabCondition ($reinstallNoClippingMarkers.Count -ge 2) 'AXIS Reinstall should expose no-clipping layout markers on the step and details region.'
$reinstallStepElement = @(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.ReinstallStep') | Select-Object -First 1
$reinstallContentGrid = @(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.StepTextContent') | Select-Object -First 1
$reinstallDetails = @(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.ReinstallDetails') | Select-Object -First 1
$reinstallInformationCard = @(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.ReinstallInformationCard') | Select-Object -First 1
$reinstallRequirementsCard = @(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.ReinstallRequirementsCard') | Select-Object -First 1
$reinstallInformationTitle = @(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.ReinstallInformationTitle') | Select-Object -First 1
$reinstallRequirementsTitle = @(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.ReinstallRequirementsTitle') | Select-Object -First 1
$reinstallTitleRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.ReinstallTitleRightAligned') | Select-Object -First 1
$reinstallInformationSharedRightEdge = @(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.ReinstallInformationSharedPhysicalRightEdge') | Select-Object -First 1
$reinstallRequirementsSharedRightEdge = @(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.ReinstallRequirementsSharedPhysicalRightEdge') | Select-Object -First 1
$reinstallInformationRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.ReinstallInformationRightAnchor') | Select-Object -First 1
$reinstallRequirementsRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.ReinstallRequirementsRightAnchor') | Select-Object -First 1
$reinstallActionArea = @(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.PrimaryActionArea') | Select-Object -First 1
$reinstallSupportPanel = @(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.SupportPanel') | Select-Object -First 1
$reinstallDocumentationButton = @(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.DocumentationButton') | Select-Object -First 1
Assert-BoostLabCondition ([double]$reinstallStepElement.Height -eq 382.0) 'AXIS Reinstall should fit inside the 900x650 preview client area without clipping.'
Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($reinstallInformationCard) -eq 2) 'AXIS Reinstall information card should be assigned to the visual right-side column.'
Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($reinstallRequirementsCard) -eq 0) 'AXIS Reinstall requirements card should be assigned to the visual left-side column.'
Assert-BoostLabCondition ($null -ne $reinstallInformationTitle) 'AXIS Reinstall information title is missing.'
Assert-BoostLabCondition ($null -ne $reinstallRequirementsTitle) 'AXIS Reinstall requirements title is missing.'
[void](Assert-AxisFirstUseWizardForegroundColor -Element $reinstallInformationTitle -ExpectedColor $axisDefaultCardTitleForeground -Name 'Reinstall information card title')
[void](Assert-AxisFirstUseWizardForegroundNotColor -Element $reinstallInformationTitle -RejectedColor $axisRejectedInformationCardTitleForeground -Name 'Reinstall information card title')
[void](Assert-AxisFirstUseWizardForegroundColor -Element $reinstallRequirementsTitle -ExpectedColor $axisDefaultCardTitleForeground -Name 'Reinstall requirements card title')
[void](Assert-AxisFirstUseWizardForegroundNotColor -Element $reinstallRequirementsTitle -RejectedColor $axisRejectedRequirementsCardTitleForeground -Name 'Reinstall requirements card title')
Assert-BoostLabCondition ($null -ne $reinstallDocumentationButton) 'AXIS Reinstall documentation button is missing.'
[void](Assert-AxisFirstUseWizardForegroundColor -Element $reinstallDocumentationButton -ExpectedColor $axisDefaultDocumentationForeground -Name 'Reinstall documentation button')
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($reinstallDocumentationButton) -eq 'AxisFirstUseWizard.DocumentationDefaultForeground') 'AXIS Reinstall documentation button should expose the default foreground marker.'
$reinstallInformationRightMarkers = @(
    Get-AxisFirstUseWizardTypedElements -Root $reinstallVisibleContent -Type ([System.Windows.FrameworkElement]) |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_) -eq 'AxisFirstUseWizard.ReinstallInformationRightCard' }
)
$reinstallRequirementsLeftMarkers = @(
    Get-AxisFirstUseWizardTypedElements -Root $reinstallVisibleContent -Type ([System.Windows.FrameworkElement]) |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_) -eq 'AxisFirstUseWizard.ReinstallRequirementsLeftCard' }
)
$reinstallSharedRightEdgeMarkers = @(
    Get-AxisFirstUseWizardTypedElements -Root $reinstallVisibleContent -Type ([System.Windows.FrameworkElement]) |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_) -eq 'AxisFirstUseWizard.ReinstallSharedPhysicalRightEdge' }
)
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $reinstallTitleRightAnchor -Name 'Reinstall title' -ExpectedMaxWidth 690)
$reinstallTitleTextBlocks = @(Get-AxisFirstUseWizardTypedElements -Root $reinstallTitleRightAnchor -Type ([System.Windows.Controls.TextBlock]))
Assert-BoostLabCondition ($reinstallTitleTextBlocks.Count -eq 1) 'AXIS Reinstall title right anchor should contain one title TextBlock.'
Assert-BoostLabCondition ([string](Get-AxisFirstUseWizardTextBlockPlainText -TextBlock $reinstallTitleTextBlocks[0]) -eq $arabicReinstallTitle) 'AXIS Reinstall right-aligned title text changed.'
Assert-BoostLabCondition ($reinstallTitleTextBlocks[0].TextAlignment -eq [System.Windows.TextAlignment]::Right) 'AXIS Reinstall title should keep right text alignment.'
Assert-BoostLabCondition ($reinstallInformationRightMarkers.Count -eq 1) 'AXIS Reinstall information card should expose the right-card marker.'
Assert-BoostLabCondition ($reinstallRequirementsLeftMarkers.Count -eq 1) 'AXIS Reinstall requirements card should expose the left-card marker.'
Assert-BoostLabCondition ($reinstallSharedRightEdgeMarkers.Count -eq 2) 'AXIS Reinstall information and requirements groups should expose shared physical right-edge markers.'
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $reinstallInformationRightAnchor -Name 'Reinstall information card' -ExpectedMaxWidth 320)
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $reinstallRequirementsRightAnchor -Name 'Reinstall requirements card' -ExpectedMaxWidth 320)
[void](Assert-AxisFirstUseWizardSharedPhysicalRightEdgeGroup `
    -Group $reinstallInformationSharedRightEdge `
    -Name 'Reinstall information card' `
    -ExpectedTexts @($arabicReinstallInfoTitle, $arabicReinstallInfoBullet) `
    -ExpectedMaxWidth 320)
[void](Assert-AxisFirstUseWizardSharedPhysicalRightEdgeGroup `
    -Group $reinstallRequirementsSharedRightEdge `
    -Name 'Reinstall requirements card' `
    -ExpectedTexts @($arabicRequirementsTitle, $arabicReinstallRequirementUsbSize, $arabicReinstallRequirementNoData) `
    -ExpectedMaxWidth 320)
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($reinstallActionArea) -eq 'AxisFirstUseWizard.ReinstallDirectSimulationActionRow') 'AXIS Reinstall action row should expose the direct simulation marker.'
Assert-BoostLabCondition ($reinstallContentGrid.Children.IndexOf($reinstallDetails) -lt $reinstallContentGrid.Children.IndexOf($reinstallActionArea)) 'AXIS Reinstall details must appear before the action row.'
Assert-BoostLabCondition ($reinstallContentGrid.Children.IndexOf($reinstallActionArea) -lt $reinstallContentGrid.Children.IndexOf($reinstallSupportPanel)) 'AXIS Reinstall action row must remain separated above the support panel.'
Assert-BoostLabCondition ($reinstallSupportPanel.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS Reinstall support panel should be visible before the simulated flow.'
$reinstallStepElement.Measure([System.Windows.Size]::new(826.0, 389.0))
$reinstallRowTotal = 0.0
foreach ($reinstallRowChild in @($reinstallContentGrid.Children)) {
    $reinstallRowChild.Measure([System.Windows.Size]::new(758.0, [double]::PositiveInfinity))
    $reinstallRowTotal += [double]$reinstallRowChild.DesiredSize.Height
}
$reinstallInnerHeight = [double]$reinstallStepElement.Height -
    [double]$reinstallStepElement.Padding.Top -
    [double]$reinstallStepElement.Padding.Bottom -
    [double]$reinstallStepElement.BorderThickness.Top -
    [double]$reinstallStepElement.BorderThickness.Bottom
Assert-BoostLabCondition ($reinstallRowTotal -le $reinstallInnerHeight) 'AXIS Reinstall row content should fit inside the card without bottom clipping.'
Assert-BoostLabCondition ([double]$reinstallInformationCard.Height -eq 118.0) 'AXIS Reinstall information card should use the compact no-clipping height.'
Assert-BoostLabCondition ([double]$reinstallRequirementsCard.Height -eq 118.0) 'AXIS Reinstall requirements card should use the compact no-clipping height.'
$reinstallPrimaryButton = @(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.PrimaryOpenButton') | Select-Object -First 1
$reinstallRuntimeStatusArea = @(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.RuntimeStatusArea') | Select-Object -First 1
$reinstallRuntimeStatusSpacer = @(Get-AxisFirstUseWizardTaggedElements -Root $reinstallVisibleContent -Tag 'AxisFirstUseWizard.ActionRuntimeStatusSpacer') | Select-Object -First 1
Assert-BoostLabCondition ([string]$reinstallPrimaryButton.Content -eq $arabicReinstallPrimaryAction) 'AXIS Reinstall primary button should use the owner-approved Arabic label.'
Assert-BoostLabCondition ([double]$reinstallPrimaryButton.Width -ge 300.0) 'AXIS Reinstall primary button should be wide enough for the owner-approved label.'
Assert-BoostLabCondition ($reinstallRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Reinstall runtime status should start hidden.'
Assert-BoostLabCondition ([double]$reinstallRuntimeStatusArea.Width -eq 234.0) 'AXIS Reinstall runtime status should use a no-clipping width for the Arabic running state.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($reinstallRuntimeStatusArea) -eq 'AxisFirstUseWizard.ReinstallRuntimeStatusNoClipping') 'AXIS Reinstall runtime status should expose the no-clipping marker.'
Invoke-AxisFirstUseWizardButtonClick -Button $reinstallPrimaryButton
Assert-BoostLabCondition ($taggedOverlay[0].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Reinstall primary action must not reveal the BIOS Drivers confirmation overlay.'
Assert-BoostLabCondition ($taggedOverlay[1].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Reinstall primary action must not reveal the BIOS Settings confirmation overlay.'
Assert-BoostLabCondition (-not [bool]$taggedContinueButtons[0].IsEnabled) 'AXIS Reinstall Continue/Next should remain disabled during the simulated running state.'
Assert-BoostLabCondition ($reinstallRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS Reinstall runtime status should become visible during the simulated flow.'
Assert-BoostLabCondition ($reinstallRuntimeStatusSpacer.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS Reinstall runtime status spacer should become visible during the simulated flow.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $reinstallRuntimeStatusArea -Tag 'AxisFirstUseWizard.CheckingAnimation').Count -eq 1) 'AXIS Reinstall simulated flow should use the runtime checking animation.'
$reinstallRunningText = (Get-AxisFirstUseWizardTextValues -Root $reinstallVisibleContent) -join [Environment]::NewLine
Assert-BoostLabCondition ($reinstallRunningText.Contains($arabicReinstallRunning)) 'AXIS Reinstall simulated flow should show the owner-approved running state.'
Assert-BoostLabCondition ($reinstallRunningText.Contains($arabicSupportBody)) 'AXIS Reinstall support panel should remain visible during the simulated flow.'
$reinstallRunningRuntimeStatusRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $reinstallRuntimeStatusArea -Tag 'AxisFirstUseWizard.RuntimeStatusArabicRightAnchor')
Assert-BoostLabCondition ($reinstallRunningRuntimeStatusRightAnchor.Count -eq 1) 'AXIS Reinstall running status should keep the runtime text near the action row.'
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $reinstallRunningRuntimeStatusRightAnchor[0] -Name 'Reinstall running runtime status' -ExpectedMaxWidth 106)
$reinstallCompletedByTimer = Wait-AxisFirstUseWizardCondition -Condition { [bool]$taggedContinueButtons[0].IsEnabled } -TimeoutMilliseconds 3000
Assert-BoostLabCondition ([bool]$reinstallCompletedByTimer) 'AXIS Reinstall simulated flow should enable Continue/Next after completion.'
$reinstallCompletedText = (Get-AxisFirstUseWizardTextValues -Root $reinstallVisibleContent) -join [Environment]::NewLine
Assert-BoostLabCondition ($reinstallCompletedText.Contains($arabicReinstallCompleted)) 'AXIS Reinstall simulated flow should end in the owner-approved ready state.'
Assert-BoostLabCondition ($reinstallCompletedText.Contains($arabicSupportBody)) 'AXIS Reinstall support panel should remain visible after simulated completion.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $reinstallRuntimeStatusArea -Tag 'AxisFirstUseWizard.CompletedEffect').Count -eq 1) 'AXIS Reinstall completed state should render the completed runtime effect.'
$reinstallCompletedRuntimeStatusRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $reinstallRuntimeStatusArea -Tag 'AxisFirstUseWizard.RuntimeStatusArabicRightAnchor')
Assert-BoostLabCondition ($reinstallCompletedRuntimeStatusRightAnchor.Count -eq 1) 'AXIS Reinstall completed status should keep the runtime text near the action row.'
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $reinstallCompletedRuntimeStatusRightAnchor[0] -Name 'Reinstall completed runtime status' -ExpectedMaxWidth 106)
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($taggedContinueButtons[0]) -eq 'AxisFirstUseWizard.EnabledNextButtonBlue') 'AXIS Reinstall Continue/Next should become blue after simulated completion.'
Assert-BoostLabCondition ([string]([System.Windows.Media.SolidColorBrush]$taggedContinueButtons[0].Background).Color -eq '#FF2563EB') 'AXIS Reinstall enabled Continue/Next should use the approved blue fill.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $taggedContentHost[0].Child -Tag 'AxisFirstUseWizard.ReinstallStep').Count -eq 1) 'AXIS Reinstall should not auto-advance after simulated completion.'
Invoke-AxisFirstUseWizardButtonClick -Button $taggedContinueButtons[0]
$autoUnattendVisibleContent = $taggedContentHost[0].Child
$autoUnattendVisibleText = (Get-AxisFirstUseWizardTextValues -Root $autoUnattendVisibleContent) -join [Environment]::NewLine
$autoUnattendVisibleTextNormalized = ConvertTo-AxisFirstUseWizardNormalizedText -Text $autoUnattendVisibleText
$currentStageHeader = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.CurrentStageHeader') | Select-Object -First 1
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.AutoUnattendStep').Count -eq 1) 'AXIS Continue/Next from completed Reinstall should move to AutoUnattend.'
Assert-BoostLabCondition ($null -ne $currentStageHeader) 'AXIS current stage header should remain tagged for AutoUnattend navigation verification.'
Assert-BoostLabCondition ([string]$currentStageHeader.Text -eq 'Refresh') 'AXIS AutoUnattend current stage header should show Refresh.'
[void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressCheckFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Check' -ExpectedColor '#FF22C55E' -Name 'AutoUnattend Check completed')
[void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressRefreshFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineActiveFullWhite.Refresh' -ExpectedColor '#FFF0F2F5' -Name 'AutoUnattend Refresh active')
$activeStageItems = @(
    $stripItems |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_).StartsWith('AxisFirstUseWizard.StageProgressActive.') }
)
$completedStageItems = @(
    $stripItems |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_).StartsWith('AxisFirstUseWizard.StageProgressCompleted.') }
)
Assert-BoostLabCondition ($activeStageItems.Count -eq 1) 'AXIS AutoUnattend should expose exactly one active stage marker.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($activeStageItems[0]) -eq 'AxisFirstUseWizard.StageProgressActive.Refresh') 'AXIS AutoUnattend active stage marker should be Refresh.'
Assert-BoostLabCondition ($completedStageItems.Count -eq 1) 'AXIS AutoUnattend should expose exactly one completed previous stage marker.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($completedStageItems[0]) -eq 'AxisFirstUseWizard.StageProgressCompleted.Check') 'AXIS AutoUnattend completed stage marker should be Check.'
Assert-BoostLabCondition (-not [bool]$taggedContinueButtons[0].IsEnabled) 'AXIS AutoUnattend Continue/Next should start disabled.'
foreach ($requiredAutoUnattendText in @(
    'Refresh'
    'AutoUnattend'
    $arabicAutoUnattendSubtitle
    $arabicAutoUnattendInfoTitle
    $arabicAutoUnattendInfoBulletOobe
    $arabicAutoUnattendInfoBulletSetup
    $arabicAutoUnattendInfoBulletUsb
    $arabicRequirementsTitle
    $arabicAutoUnattendRequirementAccount
    $arabicAutoUnattendRequirementUsb
    $arabicAutoUnattendPrimaryAction
    $arabicDocumentation
    $arabicSupportTitle
    $arabicSupportBody
)) {
    $requiredAutoUnattendTextNormalized = ConvertTo-AxisFirstUseWizardNormalizedText -Text $requiredAutoUnattendText
    Assert-BoostLabCondition (
        $autoUnattendVisibleText.Contains($requiredAutoUnattendText) -or
        $autoUnattendVisibleTextNormalized.Contains($requiredAutoUnattendTextNormalized)
    ) "AXIS AutoUnattend view is missing owner-approved text: $requiredAutoUnattendText"
}
foreach ($forbiddenAutoUnattendInternalText in @(
    'Analyze'
    'Open'
    'Apply'
    'Default'
    'Restore'
    'Cancel'
)) {
    Assert-BoostLabCondition (-not $autoUnattendVisibleText.Contains($forbiddenAutoUnattendInternalText)) "AXIS AutoUnattend view exposes forbidden internal/customer action text: $forbiddenAutoUnattendInternalText"
}
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.ConfirmationOverlay').Count -eq 0) 'AXIS AutoUnattend content must not include a confirmation overlay.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgement').Count -eq 0) 'AXIS AutoUnattend content must not include a confirmation checkbox.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.AutoUnattendInformationCard').Count -eq 1) 'AXIS AutoUnattend should render one information card.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.AutoUnattendRequirementsCard').Count -eq 1) 'AXIS AutoUnattend should render one requirements card.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.AutoUnattendInformationItem').Count -eq 3) 'AXIS AutoUnattend should render all three owner-approved information items.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.AutoUnattendRequirementItem').Count -eq 2) 'AXIS AutoUnattend should render both owner-approved requirements.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.SupportPanel').Count -eq 1) 'AXIS AutoUnattend support panel should remain separate and visible.'
$autoUnattendNoClippingMarkers = @(
    Get-AxisFirstUseWizardTypedElements -Root $autoUnattendVisibleContent -Type ([System.Windows.FrameworkElement]) |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_) -eq 'AxisFirstUseWizard.AutoUnattendNoClippingLayout' }
)
Assert-BoostLabCondition ($autoUnattendNoClippingMarkers.Count -ge 2) 'AXIS AutoUnattend should expose no-clipping layout markers on the step and details region.'
$autoUnattendStepElement = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.AutoUnattendStep') | Select-Object -First 1
$autoUnattendContentGrid = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.StepTextContent') | Select-Object -First 1
$autoUnattendDetails = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.AutoUnattendDetails') | Select-Object -First 1
$autoUnattendInformationCard = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.AutoUnattendInformationCard') | Select-Object -First 1
$autoUnattendRequirementsCard = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.AutoUnattendRequirementsCard') | Select-Object -First 1
$autoUnattendInformationTitle = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.AutoUnattendInformationTitle') | Select-Object -First 1
$autoUnattendRequirementsTitle = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.AutoUnattendRequirementsTitle') | Select-Object -First 1
$autoUnattendTitleRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.AutoUnattendTitleRightAligned') | Select-Object -First 1
$autoUnattendInformationSharedRightEdge = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.AutoUnattendInformationSharedPhysicalRightEdge') | Select-Object -First 1
$autoUnattendRequirementsSharedRightEdge = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.AutoUnattendRequirementsSharedPhysicalRightEdge') | Select-Object -First 1
$autoUnattendInformationRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.AutoUnattendInformationRightAnchor') | Select-Object -First 1
$autoUnattendRequirementsRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.AutoUnattendRequirementsRightAnchor') | Select-Object -First 1
$autoUnattendActionArea = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.PrimaryActionArea') | Select-Object -First 1
$autoUnattendSupportPanel = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.SupportPanel') | Select-Object -First 1
$autoUnattendDocumentationButton = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.DocumentationButton') | Select-Object -First 1
Assert-BoostLabCondition ([double]$autoUnattendStepElement.Height -eq 382.0) 'AXIS AutoUnattend should fit inside the 900x650 preview client area without clipping.'
Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($autoUnattendInformationCard) -eq 2) 'AXIS AutoUnattend information card should be assigned to the visual right-side column.'
Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($autoUnattendRequirementsCard) -eq 0) 'AXIS AutoUnattend requirements card should be assigned to the visual left-side column.'
Assert-BoostLabCondition ($null -ne $autoUnattendInformationTitle) 'AXIS AutoUnattend information title is missing.'
Assert-BoostLabCondition ($null -ne $autoUnattendRequirementsTitle) 'AXIS AutoUnattend requirements title is missing.'
[void](Assert-AxisFirstUseWizardForegroundColor -Element $autoUnattendInformationTitle -ExpectedColor $axisDefaultCardTitleForeground -Name 'AutoUnattend information card title')
[void](Assert-AxisFirstUseWizardForegroundNotColor -Element $autoUnattendInformationTitle -RejectedColor $axisRejectedInformationCardTitleForeground -Name 'AutoUnattend information card title')
[void](Assert-AxisFirstUseWizardForegroundColor -Element $autoUnattendRequirementsTitle -ExpectedColor $axisDefaultCardTitleForeground -Name 'AutoUnattend requirements card title')
[void](Assert-AxisFirstUseWizardForegroundNotColor -Element $autoUnattendRequirementsTitle -RejectedColor $axisRejectedRequirementsCardTitleForeground -Name 'AutoUnattend requirements card title')
Assert-BoostLabCondition ($null -ne $autoUnattendDocumentationButton) 'AXIS AutoUnattend documentation button is missing.'
[void](Assert-AxisFirstUseWizardForegroundColor -Element $autoUnattendDocumentationButton -ExpectedColor $axisDefaultDocumentationForeground -Name 'AutoUnattend documentation button')
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($autoUnattendDocumentationButton) -eq 'AxisFirstUseWizard.DocumentationDefaultForeground') 'AXIS AutoUnattend documentation button should expose the default foreground marker.'
Assert-BoostLabCondition ($autoUnattendTitleRightAnchor -is [System.Windows.Controls.Grid]) 'AXIS AutoUnattend title right anchor should be a full-width positioning Grid.'
Assert-BoostLabCondition ($autoUnattendTitleRightAnchor.FlowDirection -eq [System.Windows.FlowDirection]::LeftToRight) 'AXIS AutoUnattend title right anchor should use physical LTR positioning.'
Assert-BoostLabCondition ($autoUnattendTitleRightAnchor.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Stretch) 'AXIS AutoUnattend title right anchor should span the available region.'
Assert-BoostLabCondition ($autoUnattendTitleRightAnchor.Children.Count -eq 1) 'AXIS AutoUnattend title right anchor should contain one right-aligned title.'
Assert-BoostLabCondition ($autoUnattendTitleRightAnchor.Children[0].HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) 'AXIS AutoUnattend title should be physically anchored to the right.'
Assert-BoostLabCondition ([double]$autoUnattendTitleRightAnchor.Children[0].MaxWidth -eq 690.0) 'AXIS AutoUnattend title should use the expected max width.'
$autoUnattendTitleTextBlocks = @(Get-AxisFirstUseWizardTypedElements -Root $autoUnattendTitleRightAnchor -Type ([System.Windows.Controls.TextBlock]))
Assert-BoostLabCondition ($autoUnattendTitleTextBlocks.Count -eq 1) 'AXIS AutoUnattend title right anchor should contain one title TextBlock.'
Assert-BoostLabCondition ([string](Get-AxisFirstUseWizardTextBlockPlainText -TextBlock $autoUnattendTitleTextBlocks[0]) -eq 'AutoUnattend') 'AXIS AutoUnattend right-aligned title text changed.'
Assert-BoostLabCondition ($autoUnattendTitleTextBlocks[0].TextAlignment -eq [System.Windows.TextAlignment]::Right) 'AXIS AutoUnattend title should keep right text alignment.'
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $autoUnattendInformationRightAnchor -Name 'AutoUnattend information card' -ExpectedMaxWidth 320)
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $autoUnattendRequirementsRightAnchor -Name 'AutoUnattend requirements card' -ExpectedMaxWidth 320)
$autoUnattendMixedBidiMarkers = @(
    Get-AxisFirstUseWizardTypedElements -Root $autoUnattendInformationSharedRightEdge -Type ([System.Windows.FrameworkElement]) |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_) -eq 'AxisFirstUseWizard.AutoUnattendMixedBidiSafeInfoText' }
)
$autoUnattendInfoCardNoClippingMarkers = @(
    Get-AxisFirstUseWizardTypedElements -Root $autoUnattendInformationCard -Type ([System.Windows.FrameworkElement]) |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_) -eq 'AxisFirstUseWizard.AutoUnattendInfoCardNoClipping' }
)
Assert-BoostLabCondition ($autoUnattendMixedBidiMarkers.Count -eq 1) 'AXIS AutoUnattend information card should expose the mixed BiDi-safe marker.'
Assert-BoostLabCondition ($autoUnattendInfoCardNoClippingMarkers.Count -eq 1) 'AXIS AutoUnattend information card should expose the no-clipping marker.'
Assert-BoostLabCondition ($autoUnattendInformationSharedRightEdge -is [System.Windows.Controls.Grid]) 'AXIS AutoUnattend information card should keep a shared right-origin grid.'
Assert-BoostLabCondition ($autoUnattendInformationSharedRightEdge.FlowDirection -eq [System.Windows.FlowDirection]::LeftToRight) 'AXIS AutoUnattend information card shared group should use physical LTR positioning.'
Assert-BoostLabCondition ($autoUnattendInformationSharedRightEdge.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) 'AXIS AutoUnattend information card shared group should be physically anchored to the right.'
Assert-BoostLabCondition ([double]$autoUnattendInformationSharedRightEdge.MaxWidth -eq 320.0) 'AXIS AutoUnattend information card shared group should use the expected max width.'
$autoUnattendInfoTextBlocks = @(Get-AxisFirstUseWizardTypedElements -Root $autoUnattendInformationSharedRightEdge -Type ([System.Windows.Controls.TextBlock]))
Assert-BoostLabCondition ($autoUnattendInfoTextBlocks.Count -ge 8) 'AXIS AutoUnattend information card should split mixed Arabic/English copy into deterministic right-aligned lines.'
foreach ($autoUnattendInfoTextBlock in $autoUnattendInfoTextBlocks) {
    Assert-BoostLabCondition ($autoUnattendInfoTextBlock.FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) 'AXIS AutoUnattend mixed information text should use RTL flow.'
    Assert-BoostLabCondition ($autoUnattendInfoTextBlock.TextAlignment -eq [System.Windows.TextAlignment]::Right) 'AXIS AutoUnattend mixed information text should stay right-aligned.'
    Assert-BoostLabCondition ($autoUnattendInfoTextBlock.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) 'AXIS AutoUnattend mixed information text should share the physical right edge.'
    Assert-BoostLabCondition ($autoUnattendInfoTextBlock.TextWrapping -eq [System.Windows.TextWrapping]::NoWrap) 'AXIS AutoUnattend mixed information text should avoid WPF automatic BiDi wrapping.'
}
$autoUnattendInfoNormalized = ConvertTo-AxisFirstUseWizardNormalizedText -Text ((Get-AxisFirstUseWizardTextValues -Root $autoUnattendInformationSharedRightEdge) -join [Environment]::NewLine)
foreach ($requiredAutoUnattendInfoText in @(
    $arabicAutoUnattendInfoTitle
    $arabicAutoUnattendInfoBulletOobe
    $arabicAutoUnattendInfoBulletSetup
    $arabicAutoUnattendInfoBulletUsb
)) {
    Assert-BoostLabCondition ($autoUnattendInfoNormalized.Contains((ConvertTo-AxisFirstUseWizardNormalizedText -Text $requiredAutoUnattendInfoText))) "AXIS AutoUnattend information card should preserve approved text after line control: $requiredAutoUnattendInfoText"
}
$autoUnattendOobeLines = @(Split-AxisAutoUnattendInformationText -Name 'Oobe' -Text $arabicAutoUnattendInfoBulletOobe)
$autoUnattendSetupLines = @(Split-AxisAutoUnattendInformationText -Name 'Setup' -Text $arabicAutoUnattendInfoBulletSetup)
$autoUnattendWindowsInstallFragment = @($autoUnattendOobeLines | Where-Object { $_.Contains('Windows.') }) | Select-Object -First 1
$arabicBeginningFragmentText = ConvertFrom-AxisWizardCodePoints @(0x0627, 0x0644, 0x0628, 0x062F, 0x0627, 0x064A, 0x0629, 0x002E)
$autoUnattendBeginningFragment = @($autoUnattendSetupLines | Where-Object { $_.Contains($arabicBeginningFragmentText) }) | Select-Object -First 1
foreach ($safeFragment in @($autoUnattendWindowsInstallFragment, $autoUnattendBeginningFragment)) {
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace($safeFragment)) 'AXIS AutoUnattend should keep the reviewed wrapped fragment in a deterministic line.'
    $fragmentTextBlocks = @(Get-AxisFirstUseWizardTextBlocksByText -Root $autoUnattendInformationSharedRightEdge -Text $safeFragment)
    Assert-BoostLabCondition ($fragmentTextBlocks.Count -eq 1) "AXIS AutoUnattend reviewed fragment should render as one safe right-aligned line: $safeFragment"
    Assert-BoostLabCondition ([string]$fragmentTextBlocks[0].Tag -eq 'AxisFirstUseWizard.AutoUnattendInformationItemLine') "AXIS AutoUnattend reviewed fragment should use the mixed-line marker: $safeFragment"
    Assert-BoostLabCondition ($fragmentTextBlocks[0].HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) "AXIS AutoUnattend reviewed fragment should not drift to the physical left: $safeFragment"
}
$autoUnattendEnglishRuns = @(
    $autoUnattendInfoTextBlocks |
        ForEach-Object { @($_.Inlines) } |
        Where-Object { $_ -is [System.Windows.Documents.Run] -and $_.FlowDirection -eq [System.Windows.FlowDirection]::LeftToRight }
)
foreach ($requiredEnglishTerm in @('AutoUnattend', 'OOBE', 'Windows', 'Microsoft', 'USB')) {
    Assert-BoostLabCondition (@($autoUnattendEnglishRuns | Where-Object { [string]$_.Text -eq $requiredEnglishTerm }).Count -ge 1) "AXIS AutoUnattend information card should isolate the English term in an LTR Run: $requiredEnglishTerm"
}
[void](Assert-AxisFirstUseWizardSharedPhysicalRightEdgeGroup `
    -Group $autoUnattendRequirementsSharedRightEdge `
    -Name 'AutoUnattend requirements card' `
    -ExpectedTexts @($arabicRequirementsTitle, $arabicAutoUnattendRequirementAccount, $arabicAutoUnattendRequirementUsb) `
    -ExpectedMaxWidth 320)
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($autoUnattendActionArea) -eq 'AxisFirstUseWizard.AutoUnattendInputActionRow') 'AXIS AutoUnattend action row should expose the input-window marker.'
Assert-BoostLabCondition ($autoUnattendContentGrid.Children.IndexOf($autoUnattendDetails) -lt $autoUnattendContentGrid.Children.IndexOf($autoUnattendActionArea)) 'AXIS AutoUnattend details must appear before the action row.'
Assert-BoostLabCondition ($autoUnattendContentGrid.Children.IndexOf($autoUnattendActionArea) -lt $autoUnattendContentGrid.Children.IndexOf($autoUnattendSupportPanel)) 'AXIS AutoUnattend action row must remain separated above the support panel.'
Assert-BoostLabCondition ($autoUnattendSupportPanel.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS AutoUnattend support panel should be visible before the simulated flow.'
$autoUnattendStepElement.Measure([System.Windows.Size]::new(826.0, 389.0))
$autoUnattendRowTotal = 0.0
foreach ($autoUnattendRowChild in @($autoUnattendContentGrid.Children)) {
    $autoUnattendRowChild.Measure([System.Windows.Size]::new(758.0, [double]::PositiveInfinity))
    $autoUnattendRowTotal += [double]$autoUnattendRowChild.DesiredSize.Height
}
$autoUnattendInnerHeight = [double]$autoUnattendStepElement.Height -
    [double]$autoUnattendStepElement.Padding.Top -
    [double]$autoUnattendStepElement.Padding.Bottom -
    [double]$autoUnattendStepElement.BorderThickness.Top -
    [double]$autoUnattendStepElement.BorderThickness.Bottom
Assert-BoostLabCondition ($autoUnattendRowTotal -le $autoUnattendInnerHeight) 'AXIS AutoUnattend row content should fit inside the card without bottom clipping.'
Assert-BoostLabCondition ([double]$autoUnattendInformationCard.Height -eq 152.0) 'AXIS AutoUnattend information card should reserve enough height for the approved copy.'
Assert-BoostLabCondition ([double]$autoUnattendRequirementsCard.Height -eq 152.0) 'AXIS AutoUnattend requirements card should align with the information card height.'
$autoUnattendInformationCard.Child.Measure([System.Windows.Size]::new([double]::PositiveInfinity, [double]::PositiveInfinity))
$autoUnattendInformationCardInnerHeight = [double]$autoUnattendInformationCard.Height -
    [double]$autoUnattendInformationCard.Padding.Top -
    [double]$autoUnattendInformationCard.Padding.Bottom
Assert-BoostLabCondition ([double]$autoUnattendInformationCard.Child.DesiredSize.Height -le $autoUnattendInformationCardInnerHeight) 'AXIS AutoUnattend information card content should fit without clipping inside its reserved card height.'
$autoUnattendPrimaryButton = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.PrimaryOpenButton') | Select-Object -First 1
$autoUnattendRuntimeStatusArea = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.RuntimeStatusArea') | Select-Object -First 1
$autoUnattendRuntimeStatusSpacer = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendVisibleContent -Tag 'AxisFirstUseWizard.ActionRuntimeStatusSpacer') | Select-Object -First 1
Assert-BoostLabCondition ([string]$autoUnattendPrimaryButton.Content -eq $arabicAutoUnattendPrimaryAction) 'AXIS AutoUnattend primary button should use the owner-approved Arabic label.'
Assert-BoostLabCondition ([double]$autoUnattendPrimaryButton.Width -ge 150.0) 'AXIS AutoUnattend primary button should be wide enough for the owner-approved label.'
Assert-BoostLabCondition ($autoUnattendRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS AutoUnattend runtime status should start hidden.'
Assert-BoostLabCondition ([double]$autoUnattendRuntimeStatusArea.Width -eq 252.0) 'AXIS AutoUnattend runtime status should use a no-clipping width for the Arabic running state.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($autoUnattendRuntimeStatusArea) -eq 'AxisFirstUseWizard.AutoUnattendRuntimeStatusNoClipping') 'AXIS AutoUnattend runtime status should expose the no-clipping marker.'
$autoUnattendInputOverlay = $taggedAutoUnattendInputOverlay[0]
$autoUnattendInputText = (Get-AxisFirstUseWizardTextValues -Root $autoUnattendInputOverlay) -join [Environment]::NewLine
foreach ($requiredAutoUnattendInputText in @(
    $arabicAutoUnattendInputTitle
    $arabicAutoUnattendAccountLabel
    $arabicAutoUnattendUsbLabel
    $arabicAutoUnattendPrimaryAction
    $arabicReturn
)) {
    Assert-BoostLabCondition ($autoUnattendInputText.Contains($requiredAutoUnattendInputText)) "AXIS AutoUnattend input window is missing owner-approved text: $requiredAutoUnattendInputText"
}
$autoUnattendInputCardMarkers = @(
    Get-AxisFirstUseWizardTypedElements -Root $autoUnattendInputOverlay -Type ([System.Windows.FrameworkElement]) |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_) -eq 'AxisFirstUseWizard.AutoUnattendInputWindowNoCheckbox' }
)
$autoUnattendAccountBox = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendInputOverlay -Tag 'AxisFirstUseWizard.AutoUnattendAccountTextBox') | Select-Object -First 1
$autoUnattendUsbSelector = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendInputOverlay -Tag 'AxisFirstUseWizard.AutoUnattendUsbSelector') | Select-Object -First 1
$autoUnattendInputCreateButton = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendInputOverlay -Tag 'AxisFirstUseWizard.AutoUnattendInputCreateButton') | Select-Object -First 1
$autoUnattendInputReturnButton = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendInputOverlay -Tag 'AxisFirstUseWizard.AutoUnattendInputReturnButton') | Select-Object -First 1
Assert-BoostLabCondition ($autoUnattendInputCardMarkers.Count -eq 1) 'AXIS AutoUnattend input window should expose the no-checkbox marker.'
Assert-BoostLabCondition ($autoUnattendAccountBox -is [System.Windows.Controls.TextBox]) 'AXIS AutoUnattend input window should include an account TextBox.'
Assert-BoostLabCondition ($autoUnattendUsbSelector -is [System.Windows.Controls.ComboBox]) 'AXIS AutoUnattend input window should include a mock USB ComboBox.'
Assert-BoostLabCondition ($autoUnattendInputCreateButton -is [System.Windows.Controls.Button]) 'AXIS AutoUnattend input window Create button is missing.'
Assert-BoostLabCondition ($autoUnattendInputReturnButton -is [System.Windows.Controls.Button]) 'AXIS AutoUnattend input window Return button is missing.'
Assert-BoostLabCondition ([string]$autoUnattendInputCreateButton.Content -eq $arabicAutoUnattendPrimaryAction) 'AXIS AutoUnattend input Create button label changed.'
Assert-BoostLabCondition ([string]$autoUnattendInputReturnButton.Content -eq $arabicReturn) 'AXIS AutoUnattend input Return button label changed.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($autoUnattendInputReturnButton) -eq 'AxisFirstUseWizard.AutoUnattendInputReturnOnlyClosesOverlay') 'AXIS AutoUnattend input Return should be marked as overlay-only close behavior.'
Assert-BoostLabCondition ($autoUnattendUsbSelector.Items.Count -eq 1) 'AXIS AutoUnattend prototype should expose exactly one safe mock USB item.'
Assert-BoostLabCondition ([string]$autoUnattendUsbSelector.Items[0] -eq 'USB') 'AXIS AutoUnattend mock USB label should remain generic and local.'
Assert-BoostLabCondition ($autoUnattendUsbSelector.SelectedIndex -eq -1) 'AXIS AutoUnattend mock USB selector should start unselected.'
Assert-BoostLabCondition (-not [bool]$autoUnattendInputCreateButton.IsEnabled) 'AXIS AutoUnattend input Create should start disabled.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($autoUnattendInputCreateButton) -eq 'AxisFirstUseWizard.AutoUnattendInputCreateDisabledUntilValid') 'AXIS AutoUnattend input Create should expose the disabled-until-valid marker.'
Invoke-AxisFirstUseWizardButtonClick -Button $autoUnattendPrimaryButton
Assert-BoostLabCondition ($autoUnattendInputOverlay.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS AutoUnattend primary action should open the input window only.'
Assert-BoostLabCondition ($taggedOverlay[0].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS AutoUnattend primary action must not reveal the BIOS Drivers confirmation overlay.'
Assert-BoostLabCondition ($taggedOverlay[1].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS AutoUnattend primary action must not reveal the BIOS Settings confirmation overlay.'
Assert-BoostLabCondition (-not [bool]$taggedContinueButtons[0].IsEnabled) 'AXIS AutoUnattend Continue/Next should remain disabled while the input window is open.'
Assert-BoostLabCondition ($autoUnattendRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS AutoUnattend primary action must not start runtime status before valid input.'
$autoUnattendAccountBox.Text = 'Yazan User'
$autoUnattendUsbSelector.SelectedIndex = 0
Assert-BoostLabCondition (-not [bool]$autoUnattendInputCreateButton.IsEnabled) 'AXIS AutoUnattend input Create should reject account names containing spaces.'
$autoUnattendAccountBox.Text = 'Yazan'
Assert-BoostLabCondition ([bool]$autoUnattendInputCreateButton.IsEnabled) 'AXIS AutoUnattend input Create should enable for a valid account name and mock USB selection.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($autoUnattendInputCreateButton) -eq 'AxisFirstUseWizard.AutoUnattendInputCreateEnabledWithValidMockInput') 'AXIS AutoUnattend input Create should expose the valid mock input marker.'
Invoke-AxisFirstUseWizardButtonClick -Button $autoUnattendInputReturnButton
Assert-BoostLabCondition ($autoUnattendInputOverlay.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS AutoUnattend input Return should close only the input window.'
Assert-BoostLabCondition ([string]$autoUnattendAccountBox.Text -eq '') 'AXIS AutoUnattend input Return should reset the account field.'
Assert-BoostLabCondition ($autoUnattendUsbSelector.SelectedIndex -eq -1) 'AXIS AutoUnattend input Return should reset the mock USB selection.'
Assert-BoostLabCondition (-not [bool]$autoUnattendInputCreateButton.IsEnabled) 'AXIS AutoUnattend input Return should leave Create disabled after reset.'
Assert-BoostLabCondition (-not [bool]$taggedContinueButtons[0].IsEnabled) 'AXIS AutoUnattend input Return must not complete the step or enable Continue/Next.'
Assert-BoostLabCondition ($autoUnattendRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS AutoUnattend input Return must not start create simulation.'
Invoke-AxisFirstUseWizardButtonClick -Button $autoUnattendPrimaryButton
Assert-BoostLabCondition ($autoUnattendInputOverlay.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS AutoUnattend primary action should reopen the input window after Return.'
$autoUnattendAccountBox.Text = 'Yazan'
$autoUnattendUsbSelector.SelectedIndex = 0
Assert-BoostLabCondition ([bool]$autoUnattendInputCreateButton.IsEnabled) 'AXIS AutoUnattend input Create should enable after valid reopened input.'
Invoke-AxisFirstUseWizardButtonClick -Button $autoUnattendInputCreateButton
Assert-BoostLabCondition ($autoUnattendInputOverlay.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS AutoUnattend input Create should close the input window before simulated creation.'
Assert-BoostLabCondition (-not [bool]$taggedContinueButtons[0].IsEnabled) 'AXIS AutoUnattend Continue/Next should remain disabled during the simulated creation state.'
Assert-BoostLabCondition ($autoUnattendRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS AutoUnattend runtime status should become visible during the simulated creation flow.'
Assert-BoostLabCondition ($autoUnattendRuntimeStatusSpacer.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS AutoUnattend runtime status spacer should become visible during the simulated creation flow.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendRuntimeStatusArea -Tag 'AxisFirstUseWizard.CheckingAnimation').Count -eq 1) 'AXIS AutoUnattend simulated flow should use the runtime checking animation.'
$autoUnattendRunningText = (Get-AxisFirstUseWizardTextValues -Root $autoUnattendVisibleContent) -join [Environment]::NewLine
Assert-BoostLabCondition ($autoUnattendRunningText.Contains($arabicAutoUnattendRunning)) 'AXIS AutoUnattend simulated flow should show the owner-approved running state.'
Assert-BoostLabCondition ($autoUnattendRunningText.Contains($arabicSupportBody)) 'AXIS AutoUnattend support panel should remain visible during the simulated flow.'
$autoUnattendRunningRuntimeStatusRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendRuntimeStatusArea -Tag 'AxisFirstUseWizard.RuntimeStatusArabicRightAnchor')
Assert-BoostLabCondition ($autoUnattendRunningRuntimeStatusRightAnchor.Count -eq 1) 'AXIS AutoUnattend running status should keep the runtime text near the action row.'
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $autoUnattendRunningRuntimeStatusRightAnchor[0] -Name 'AutoUnattend running runtime status' -ExpectedMaxWidth 126)
$autoUnattendCompletedByTimer = Wait-AxisFirstUseWizardCondition -Condition { [bool]$taggedContinueButtons[0].IsEnabled } -TimeoutMilliseconds 3000
Assert-BoostLabCondition ([bool]$autoUnattendCompletedByTimer) 'AXIS AutoUnattend simulated flow should enable Continue/Next after completion.'
$autoUnattendCompletedText = (Get-AxisFirstUseWizardTextValues -Root $autoUnattendVisibleContent) -join [Environment]::NewLine
Assert-BoostLabCondition ($autoUnattendCompletedText.Contains($arabicAutoUnattendCompleted)) 'AXIS AutoUnattend simulated flow should end in the owner-approved completed state.'
Assert-BoostLabCondition ($autoUnattendCompletedText.Contains($arabicSupportBody)) 'AXIS AutoUnattend support panel should remain visible after simulated completion.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendRuntimeStatusArea -Tag 'AxisFirstUseWizard.CompletedEffect').Count -eq 1) 'AXIS AutoUnattend completed state should render the completed runtime effect.'
$autoUnattendCompletedRuntimeStatusRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $autoUnattendRuntimeStatusArea -Tag 'AxisFirstUseWizard.RuntimeStatusArabicRightAnchor')
Assert-BoostLabCondition ($autoUnattendCompletedRuntimeStatusRightAnchor.Count -eq 1) 'AXIS AutoUnattend completed status should keep the runtime text near the action row.'
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $autoUnattendCompletedRuntimeStatusRightAnchor[0] -Name 'AutoUnattend completed runtime status' -ExpectedMaxWidth 126)
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($taggedContinueButtons[0]) -eq 'AxisFirstUseWizard.EnabledNextButtonBlue') 'AXIS AutoUnattend Continue/Next should become blue after simulated completion.'
Assert-BoostLabCondition ([string]([System.Windows.Media.SolidColorBrush]$taggedContinueButtons[0].Background).Color -eq '#FF2563EB') 'AXIS AutoUnattend enabled Continue/Next should use the approved blue fill.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $taggedContentHost[0].Child -Tag 'AxisFirstUseWizard.AutoUnattendStep').Count -eq 1) 'AXIS AutoUnattend should not auto-advance after simulated completion.'
Invoke-AxisFirstUseWizardButtonClick -Button $taggedContinueButtons[0]
$updatesDriversVisibleContent = $taggedContentHost[0].Child
$updatesDriversVisibleText = (Get-AxisFirstUseWizardTextValues -Root $updatesDriversVisibleContent) -join [Environment]::NewLine
$updatesDriversVisibleTextNormalized = ConvertTo-AxisFirstUseWizardNormalizedText -Text $updatesDriversVisibleText
$currentStageHeader = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.CurrentStageHeader') | Select-Object -First 1
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.UpdatesDriversStep').Count -eq 1) 'AXIS Continue/Next from completed AutoUnattend should move to Updates Drivers Block.'
Assert-BoostLabCondition ([string]$currentStageHeader.Text -eq 'Refresh') 'AXIS Updates Drivers Block current stage header should show Refresh.'
[void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressCheckFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Check' -ExpectedColor '#FF22C55E' -Name 'Updates Drivers Block Check completed')
[void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressRefreshFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineActiveFullWhite.Refresh' -ExpectedColor '#FFF0F2F5' -Name 'Updates Drivers Block Refresh active')
$activeStageItems = @(
    $stripItems |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_).StartsWith('AxisFirstUseWizard.StageProgressActive.') }
)
$completedStageItems = @(
    $stripItems |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_).StartsWith('AxisFirstUseWizard.StageProgressCompleted.') }
)
Assert-BoostLabCondition ($activeStageItems.Count -eq 1) 'AXIS Updates Drivers Block should expose exactly one active stage marker.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($activeStageItems[0]) -eq 'AxisFirstUseWizard.StageProgressActive.Refresh') 'AXIS Updates Drivers Block active stage marker should be Refresh.'
Assert-BoostLabCondition ($completedStageItems.Count -eq 1) 'AXIS Updates Drivers Block should expose exactly one completed previous stage marker.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($completedStageItems[0]) -eq 'AxisFirstUseWizard.StageProgressCompleted.Check') 'AXIS Updates Drivers Block completed stage marker should be Check.'
Assert-BoostLabCondition (-not [bool]$taggedContinueButtons[0].IsEnabled) 'AXIS Updates Drivers Block Continue/Next should start disabled.'
foreach ($requiredUpdatesDriversText in @(
    'Refresh'
    'Updates Drivers Block'
    $arabicUpdatesDriversSubtitle
    $arabicUpdatesDriversInfoTitle
    $arabicUpdatesDriversInfoBulletSetupcomplete
    $arabicUpdatesDriversInfoBulletWindowsUpdate
    $arabicRequirementsTitle
    $arabicUpdatesDriversRequirementUsb
    $arabicUpdatesDriversPrimaryAction
    $arabicDocumentation
    $arabicSupportTitle
    $arabicSupportBody
)) {
    $requiredUpdatesDriversTextNormalized = ConvertTo-AxisFirstUseWizardNormalizedText -Text $requiredUpdatesDriversText
    Assert-BoostLabCondition (
        $updatesDriversVisibleText.Contains($requiredUpdatesDriversText) -or
        $updatesDriversVisibleTextNormalized.Contains($requiredUpdatesDriversTextNormalized)
    ) "AXIS Updates Drivers Block view is missing owner-approved text: $requiredUpdatesDriversText"
}
foreach ($forbiddenUpdatesDriversInternalText in @(
    'Analyze'
    'Open'
    'Apply'
    'Default'
    'Restore'
    'Cancel'
)) {
    Assert-BoostLabCondition (-not $updatesDriversVisibleText.Contains($forbiddenUpdatesDriversInternalText)) "AXIS Updates Drivers Block view exposes forbidden internal/customer action text: $forbiddenUpdatesDriversInternalText"
}
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.ConfirmationOverlay').Count -eq 0) 'AXIS Updates Drivers Block content must not include a confirmation overlay.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgement').Count -eq 0) 'AXIS Updates Drivers Block content must not include a confirmation checkbox.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.UpdatesDriversInformationCard').Count -eq 1) 'AXIS Updates Drivers Block should render one information card.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.UpdatesDriversRequirementsCard').Count -eq 1) 'AXIS Updates Drivers Block should render one requirements card.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.UpdatesDriversInformationItem').Count -eq 2) 'AXIS Updates Drivers Block should render both owner-approved information items.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.UpdatesDriversRequirementItem').Count -eq 1) 'AXIS Updates Drivers Block should render the owner-approved USB requirement.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.SupportPanel').Count -eq 1) 'AXIS Updates Drivers Block support panel should remain separate and visible.'
$updatesDriversStepElement = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.UpdatesDriversStep') | Select-Object -First 1
$updatesDriversContentGrid = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.StepTextContent') | Select-Object -First 1
$updatesDriversDetails = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.UpdatesDriversDetails') | Select-Object -First 1
$updatesDriversInformationCard = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.UpdatesDriversInformationCard') | Select-Object -First 1
$updatesDriversRequirementsCard = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.UpdatesDriversRequirementsCard') | Select-Object -First 1
$updatesDriversInformationTitle = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.UpdatesDriversInformationTitle') | Select-Object -First 1
$updatesDriversRequirementsTitle = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.UpdatesDriversRequirementsTitle') | Select-Object -First 1
$updatesDriversTitleRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.UpdatesDriversTitleRightAligned') | Select-Object -First 1
$updatesDriversInformationSharedRightEdge = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.UpdatesDriversInformationSharedPhysicalRightEdge') | Select-Object -First 1
$updatesDriversRequirementsSharedRightEdge = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.UpdatesDriversRequirementsSharedPhysicalRightEdge') | Select-Object -First 1
$updatesDriversInformationRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.UpdatesDriversInformationRightAnchor') | Select-Object -First 1
$updatesDriversRequirementsRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.UpdatesDriversRequirementsRightAnchor') | Select-Object -First 1
$updatesDriversActionArea = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.PrimaryActionArea') | Select-Object -First 1
$updatesDriversSupportPanel = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.SupportPanel') | Select-Object -First 1
$updatesDriversDocumentationButton = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.DocumentationButton') | Select-Object -First 1
Assert-BoostLabCondition ([double]$updatesDriversStepElement.Height -eq 382.0) 'AXIS Updates Drivers Block should fit inside the 900x650 preview client area without clipping.'
Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($updatesDriversInformationCard) -eq 2) 'AXIS Updates Drivers Block information card should be assigned to the visual right-side column.'
Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($updatesDriversRequirementsCard) -eq 0) 'AXIS Updates Drivers Block requirements card should be assigned to the visual left-side column.'
[void](Assert-AxisFirstUseWizardForegroundColor -Element $updatesDriversInformationTitle -ExpectedColor $axisDefaultCardTitleForeground -Name 'Updates Drivers Block information card title')
[void](Assert-AxisFirstUseWizardForegroundNotColor -Element $updatesDriversInformationTitle -RejectedColor $axisRejectedInformationCardTitleForeground -Name 'Updates Drivers Block information card title')
[void](Assert-AxisFirstUseWizardForegroundColor -Element $updatesDriversRequirementsTitle -ExpectedColor $axisDefaultCardTitleForeground -Name 'Updates Drivers Block requirements card title')
[void](Assert-AxisFirstUseWizardForegroundNotColor -Element $updatesDriversRequirementsTitle -RejectedColor $axisRejectedRequirementsCardTitleForeground -Name 'Updates Drivers Block requirements card title')
Assert-BoostLabCondition ($null -ne $updatesDriversDocumentationButton) 'AXIS Updates Drivers Block documentation button is missing.'
[void](Assert-AxisFirstUseWizardForegroundColor -Element $updatesDriversDocumentationButton -ExpectedColor $axisDefaultDocumentationForeground -Name 'Updates Drivers Block documentation button')
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($updatesDriversDocumentationButton) -eq 'AxisFirstUseWizard.DocumentationDefaultForeground') 'AXIS Updates Drivers Block documentation button should expose the default foreground marker.'
Assert-BoostLabCondition ($updatesDriversTitleRightAnchor -is [System.Windows.Controls.Grid]) 'AXIS Updates Drivers Block title right anchor should be a full-width positioning Grid.'
Assert-BoostLabCondition ($updatesDriversTitleRightAnchor.FlowDirection -eq [System.Windows.FlowDirection]::LeftToRight) 'AXIS Updates Drivers Block title right anchor should use physical LTR positioning.'
Assert-BoostLabCondition ($updatesDriversTitleRightAnchor.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Stretch) 'AXIS Updates Drivers Block title right anchor should span the available region.'
Assert-BoostLabCondition ($updatesDriversTitleRightAnchor.Children.Count -eq 1) 'AXIS Updates Drivers Block title right anchor should contain one right-aligned title.'
Assert-BoostLabCondition ($updatesDriversTitleRightAnchor.Children[0].HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) 'AXIS Updates Drivers Block title should be physically anchored to the right.'
Assert-BoostLabCondition ([double]$updatesDriversTitleRightAnchor.Children[0].MaxWidth -eq 690.0) 'AXIS Updates Drivers Block title should use the expected max width.'
$updatesDriversTitleTextBlocks = @(Get-AxisFirstUseWizardTypedElements -Root $updatesDriversTitleRightAnchor -Type ([System.Windows.Controls.TextBlock]))
Assert-BoostLabCondition ($updatesDriversTitleTextBlocks.Count -eq 1) 'AXIS Updates Drivers Block title right anchor should contain one title TextBlock.'
Assert-BoostLabCondition ([string](Get-AxisFirstUseWizardTextBlockPlainText -TextBlock $updatesDriversTitleTextBlocks[0]) -eq 'Updates Drivers Block') 'AXIS Updates Drivers Block right-aligned title text changed.'
Assert-BoostLabCondition ($updatesDriversTitleTextBlocks[0].TextAlignment -eq [System.Windows.TextAlignment]::Right) 'AXIS Updates Drivers Block title should keep right text alignment.'
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $updatesDriversInformationRightAnchor -Name 'Updates Drivers Block information card' -ExpectedMaxWidth 320)
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $updatesDriversRequirementsRightAnchor -Name 'Updates Drivers Block requirements card' -ExpectedMaxWidth 320)
$updatesDriversMixedBidiMarkers = @(
    Get-AxisFirstUseWizardTypedElements -Root $updatesDriversInformationSharedRightEdge -Type ([System.Windows.FrameworkElement]) |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_) -eq 'AxisFirstUseWizard.UpdatesDriversMixedBidiSafeInfoText' }
)
Assert-BoostLabCondition ($updatesDriversMixedBidiMarkers.Count -eq 1) 'AXIS Updates Drivers Block information card should expose the mixed BiDi-safe marker.'
$updatesDriversInfoTextBlocks = @(Get-AxisFirstUseWizardTypedElements -Root $updatesDriversInformationSharedRightEdge -Type ([System.Windows.Controls.TextBlock]))
Assert-BoostLabCondition ($updatesDriversInfoTextBlocks.Count -ge 5) 'AXIS Updates Drivers Block information card should split mixed Arabic/English copy into deterministic right-aligned lines.'
foreach ($updatesDriversInfoTextBlock in $updatesDriversInfoTextBlocks) {
    Assert-BoostLabCondition ($updatesDriversInfoTextBlock.FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) 'AXIS Updates Drivers Block mixed information text should use RTL flow.'
    Assert-BoostLabCondition ($updatesDriversInfoTextBlock.TextAlignment -eq [System.Windows.TextAlignment]::Right) 'AXIS Updates Drivers Block mixed information text should stay right-aligned.'
    Assert-BoostLabCondition ($updatesDriversInfoTextBlock.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) 'AXIS Updates Drivers Block mixed information text should share the physical right edge.'
    Assert-BoostLabCondition ($updatesDriversInfoTextBlock.TextWrapping -eq [System.Windows.TextWrapping]::NoWrap) 'AXIS Updates Drivers Block mixed information text should avoid WPF automatic BiDi wrapping.'
}
$updatesDriversEnglishRuns = @(
    $updatesDriversInfoTextBlocks |
        ForEach-Object { @($_.Inlines) } |
        Where-Object { $_ -is [System.Windows.Documents.Run] -and $_.FlowDirection -eq [System.Windows.FlowDirection]::LeftToRight }
)
foreach ($requiredUpdatesEnglishTerm in @('setupcomplete.cmd', 'USB', 'Windows', 'Windows Update')) {
    Assert-BoostLabCondition (@($updatesDriversEnglishRuns | Where-Object { [string]$_.Text -eq $requiredUpdatesEnglishTerm }).Count -ge 1) "AXIS Updates Drivers Block information card should isolate the English term in an LTR Run: $requiredUpdatesEnglishTerm"
}
[void](Assert-AxisFirstUseWizardSharedPhysicalRightEdgeGroup `
    -Group $updatesDriversRequirementsSharedRightEdge `
    -Name 'Updates Drivers Block requirements card' `
    -ExpectedTexts @($arabicRequirementsTitle, $arabicUpdatesDriversRequirementUsb) `
    -ExpectedMaxWidth 320)
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($updatesDriversActionArea) -eq 'AxisFirstUseWizard.UpdatesDriversInputActionRow') 'AXIS Updates Drivers Block action row should expose the input-window marker.'
Assert-BoostLabCondition ($updatesDriversContentGrid.Children.IndexOf($updatesDriversDetails) -lt $updatesDriversContentGrid.Children.IndexOf($updatesDriversActionArea)) 'AXIS Updates Drivers Block details must appear before the action row.'
Assert-BoostLabCondition ($updatesDriversContentGrid.Children.IndexOf($updatesDriversActionArea) -lt $updatesDriversContentGrid.Children.IndexOf($updatesDriversSupportPanel)) 'AXIS Updates Drivers Block action row must remain separated above the support panel.'
$updatesDriversPrimaryButton = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.PrimaryOpenButton') | Select-Object -First 1
$updatesDriversRuntimeStatusArea = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.RuntimeStatusArea') | Select-Object -First 1
$updatesDriversRuntimeStatusSpacer = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversVisibleContent -Tag 'AxisFirstUseWizard.ActionRuntimeStatusSpacer') | Select-Object -First 1
Assert-BoostLabCondition ([string]$updatesDriversPrimaryButton.Content -eq $arabicUpdatesDriversPrimaryAction) 'AXIS Updates Drivers Block primary button should use the owner-approved Arabic label.'
Assert-BoostLabCondition ([double]$updatesDriversPrimaryButton.Width -ge 250.0) 'AXIS Updates Drivers Block primary button should be wide enough for the owner-approved label.'
Assert-BoostLabCondition ($updatesDriversRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Updates Drivers Block runtime status should start hidden.'
Assert-BoostLabCondition ([double]$updatesDriversRuntimeStatusArea.Width -eq 234.0) 'AXIS Updates Drivers Block runtime status should use a no-clipping width for the Arabic running state.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($updatesDriversRuntimeStatusArea) -eq 'AxisFirstUseWizard.UpdatesDriversRuntimeStatusNoClipping') 'AXIS Updates Drivers Block runtime status should expose the no-clipping marker.'
$updatesDriversInputOverlay = $taggedUpdatesDriversInputOverlay[0]
$updatesDriversInputText = (Get-AxisFirstUseWizardTextValues -Root $updatesDriversInputOverlay) -join [Environment]::NewLine
foreach ($requiredUpdatesInputText in @(
    $arabicUpdatesDriversInputTitle
    $arabicUpdatesDriversUsbLabel
    $arabicUpdatesDriversInputCreate
    $arabicReturn
)) {
    Assert-BoostLabCondition ($updatesDriversInputText.Contains($requiredUpdatesInputText)) "AXIS Updates Drivers Block input window is missing owner-approved text: $requiredUpdatesInputText"
}
Assert-BoostLabCondition (-not $updatesDriversInputText.Contains($arabicAutoUnattendAccountLabel)) 'AXIS Updates Drivers Block input window must not show the AutoUnattend account field label.'
$updatesDriversInputCardMarkers = @(
    Get-AxisFirstUseWizardTypedElements -Root $updatesDriversInputOverlay -Type ([System.Windows.FrameworkElement]) |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_) -eq 'AxisFirstUseWizard.UpdatesDriversInputWindowNoCheckbox' }
)
$updatesDriversAccountBox = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversInputOverlay -Tag 'AxisFirstUseWizard.AutoUnattendAccountTextBox') | Select-Object -First 1
$updatesDriversUsbSelector = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversInputOverlay -Tag 'AxisFirstUseWizard.UpdatesDriversUsbSelector') | Select-Object -First 1
$updatesDriversInputCreateButton = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversInputOverlay -Tag 'AxisFirstUseWizard.UpdatesDriversInputCreateButton') | Select-Object -First 1
$updatesDriversInputReturnButton = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversInputOverlay -Tag 'AxisFirstUseWizard.UpdatesDriversInputReturnButton') | Select-Object -First 1
Assert-BoostLabCondition ($updatesDriversInputCardMarkers.Count -eq 1) 'AXIS Updates Drivers Block input window should expose the no-checkbox marker.'
Assert-BoostLabCondition ($null -eq $updatesDriversAccountBox) 'AXIS Updates Drivers Block input window should be USB-only with no account TextBox.'
Assert-BoostLabCondition ($updatesDriversUsbSelector -is [System.Windows.Controls.ComboBox]) 'AXIS Updates Drivers Block input window should include a mock USB ComboBox.'
Assert-BoostLabCondition ($updatesDriversInputCreateButton -is [System.Windows.Controls.Button]) 'AXIS Updates Drivers Block input window Create button is missing.'
Assert-BoostLabCondition ($updatesDriversInputReturnButton -is [System.Windows.Controls.Button]) 'AXIS Updates Drivers Block input window Return button is missing.'
Assert-BoostLabCondition ([string]$updatesDriversInputCreateButton.Content -eq $arabicUpdatesDriversInputCreate) 'AXIS Updates Drivers Block input Create button label changed.'
Assert-BoostLabCondition ([string]$updatesDriversInputReturnButton.Content -eq $arabicReturn) 'AXIS Updates Drivers Block input Return button label changed.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($updatesDriversInputReturnButton) -eq 'AxisFirstUseWizard.UpdatesDriversInputReturnOnlyClosesOverlay') 'AXIS Updates Drivers Block input Return should be marked as overlay-only close behavior.'
Assert-BoostLabCondition ($updatesDriversUsbSelector.Items.Count -eq 1) 'AXIS Updates Drivers Block prototype should expose exactly one safe mock USB item.'
Assert-BoostLabCondition ([string]$updatesDriversUsbSelector.Items[0] -eq 'USB') 'AXIS Updates Drivers Block mock USB label should remain generic and local.'
Assert-BoostLabCondition ($updatesDriversUsbSelector.SelectedIndex -eq -1) 'AXIS Updates Drivers Block mock USB selector should start unselected.'
Assert-BoostLabCondition (-not [bool]$updatesDriversInputCreateButton.IsEnabled) 'AXIS Updates Drivers Block input Create should start disabled.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($updatesDriversInputCreateButton) -eq 'AxisFirstUseWizard.UpdatesDriversInputCreateDisabledUntilValid') 'AXIS Updates Drivers Block input Create should expose the disabled-until-valid marker.'
foreach ($usbSelectorUnderTest in @($autoUnattendUsbSelector, $updatesDriversUsbSelector)) {
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($usbSelectorUnderTest) -eq 'AxisFirstUseWizard.UsbSelectorReadableDarkStyle') 'AXIS USB selector should expose the readable dark style marker.'
    Assert-BoostLabCondition ([bool]$usbSelectorUnderTest.Resources['AxisFirstUseWizard.UsbSelectorReadableDarkStyle']) 'AXIS USB selector should carry the readable dark style resource marker.'
    Assert-BoostLabCondition ([bool]$usbSelectorUnderTest.Resources['AxisFirstUseWizard.UsbSelectorMockOnly']) 'AXIS USB selector should carry the mock-only resource marker.'
    Assert-BoostLabCondition ([bool]$usbSelectorUnderTest.Resources['AxisFirstUseWizard.UsbInputWindowNoRealDriveDetection']) 'AXIS USB selector should carry the no-real-drive-detection marker.'
    Assert-BoostLabCondition ($usbSelectorUnderTest.Background -eq (Get-AxisWizardResource -Resources $prototype.Resources -Name 'Axis.Brush.Wizard.SurfaceSoft')) 'AXIS USB selector should use the dark wizard surface fill.'
    Assert-BoostLabCondition ($usbSelectorUnderTest.Foreground -eq (Get-AxisWizardResource -Resources $prototype.Resources -Name 'Axis.Brush.Wizard.TextPrimary')) 'AXIS USB selector selected value should be readable on the dark surface.'
}
Invoke-AxisFirstUseWizardButtonClick -Button $updatesDriversPrimaryButton
Assert-BoostLabCondition ($updatesDriversInputOverlay.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS Updates Drivers Block primary action should open the input window only.'
Assert-BoostLabCondition ($taggedOverlay[0].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Updates Drivers Block primary action must not reveal the BIOS Drivers confirmation overlay.'
Assert-BoostLabCondition ($taggedOverlay[1].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Updates Drivers Block primary action must not reveal the BIOS Settings confirmation overlay.'
Assert-BoostLabCondition (-not [bool]$taggedContinueButtons[0].IsEnabled) 'AXIS Updates Drivers Block Continue/Next should remain disabled while the input window is open.'
Assert-BoostLabCondition ($updatesDriversRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Updates Drivers Block primary action must not start runtime status before valid input.'
$updatesDriversUsbSelector.SelectedIndex = 0
Assert-BoostLabCondition ([bool]$updatesDriversInputCreateButton.IsEnabled) 'AXIS Updates Drivers Block input Create should enable for mock USB selection.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($updatesDriversInputCreateButton) -eq 'AxisFirstUseWizard.UpdatesDriversInputCreateEnabledWithMockUsbSelection') 'AXIS Updates Drivers Block input Create should expose the mock USB selection marker.'
Invoke-AxisFirstUseWizardButtonClick -Button $updatesDriversInputReturnButton
Assert-BoostLabCondition ($updatesDriversInputOverlay.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Updates Drivers Block input Return should close only the input window.'
Assert-BoostLabCondition ($updatesDriversUsbSelector.SelectedIndex -eq -1) 'AXIS Updates Drivers Block input Return should reset the mock USB selection.'
Assert-BoostLabCondition (-not [bool]$updatesDriversInputCreateButton.IsEnabled) 'AXIS Updates Drivers Block input Return should leave Create disabled after reset.'
Assert-BoostLabCondition (-not [bool]$taggedContinueButtons[0].IsEnabled) 'AXIS Updates Drivers Block input Return must not complete the step or enable Continue/Next.'
Assert-BoostLabCondition ($updatesDriversRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Updates Drivers Block input Return must not start create simulation.'
Invoke-AxisFirstUseWizardButtonClick -Button $updatesDriversPrimaryButton
Assert-BoostLabCondition ($updatesDriversInputOverlay.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS Updates Drivers Block primary action should reopen the input window after Return.'
Assert-BoostLabCondition ($updatesDriversUsbSelector.SelectedIndex -eq -1) 'AXIS Updates Drivers Block reopened input window should reset the mock USB selection.'
Assert-BoostLabCondition (-not [bool]$updatesDriversInputCreateButton.IsEnabled) 'AXIS Updates Drivers Block reopened input window should keep Create disabled until mock USB selection.'
$updatesDriversUsbSelector.SelectedIndex = 0
Assert-BoostLabCondition ([bool]$updatesDriversInputCreateButton.IsEnabled) 'AXIS Updates Drivers Block input Create should enable after valid reopened input.'
Invoke-AxisFirstUseWizardButtonClick -Button $updatesDriversInputCreateButton
Assert-BoostLabCondition ($updatesDriversInputOverlay.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Updates Drivers Block input Create should close the input window before simulated creation.'
Assert-BoostLabCondition (-not [bool]$taggedContinueButtons[0].IsEnabled) 'AXIS Updates Drivers Block Continue/Next should remain disabled during the simulated creation state.'
Assert-BoostLabCondition ($updatesDriversRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS Updates Drivers Block runtime status should become visible during the simulated flow.'
Assert-BoostLabCondition ($updatesDriversRuntimeStatusSpacer.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS Updates Drivers Block runtime status spacer should become visible during the simulated flow.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversRuntimeStatusArea -Tag 'AxisFirstUseWizard.CheckingAnimation').Count -eq 1) 'AXIS Updates Drivers Block simulated flow should use the runtime checking animation.'
$updatesDriversRunningText = (Get-AxisFirstUseWizardTextValues -Root $updatesDriversVisibleContent) -join [Environment]::NewLine
Assert-BoostLabCondition ($updatesDriversRunningText.Contains($arabicUpdatesDriversRunning)) 'AXIS Updates Drivers Block simulated flow should show the owner-approved running state.'
Assert-BoostLabCondition ($updatesDriversRunningText.Contains($arabicSupportBody)) 'AXIS Updates Drivers Block support panel should remain visible during the simulated flow.'
$updatesDriversRunningRuntimeStatusRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversRuntimeStatusArea -Tag 'AxisFirstUseWizard.RuntimeStatusArabicRightAnchor')
Assert-BoostLabCondition ($updatesDriversRunningRuntimeStatusRightAnchor.Count -eq 1) 'AXIS Updates Drivers Block running status should keep the runtime text near the action row.'
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $updatesDriversRunningRuntimeStatusRightAnchor[0] -Name 'Updates Drivers Block running runtime status' -ExpectedMaxWidth 106)
$updatesDriversCompletedByTimer = Wait-AxisFirstUseWizardCondition -Condition { [bool]$taggedContinueButtons[0].IsEnabled } -TimeoutMilliseconds 3000
Assert-BoostLabCondition ([bool]$updatesDriversCompletedByTimer) 'AXIS Updates Drivers Block simulated flow should enable Continue/Next after completion.'
$updatesDriversCompletedText = (Get-AxisFirstUseWizardTextValues -Root $updatesDriversVisibleContent) -join [Environment]::NewLine
Assert-BoostLabCondition ($updatesDriversCompletedText.Contains($arabicUpdatesDriversCompleted)) 'AXIS Updates Drivers Block simulated flow should end in the owner-approved completed state.'
Assert-BoostLabCondition ($updatesDriversCompletedText.Contains($arabicSupportBody)) 'AXIS Updates Drivers Block support panel should remain visible after simulated completion.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversRuntimeStatusArea -Tag 'AxisFirstUseWizard.CompletedEffect').Count -eq 1) 'AXIS Updates Drivers Block completed state should render the completed runtime effect.'
$updatesDriversCompletedRuntimeStatusRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $updatesDriversRuntimeStatusArea -Tag 'AxisFirstUseWizard.RuntimeStatusArabicRightAnchor')
Assert-BoostLabCondition ($updatesDriversCompletedRuntimeStatusRightAnchor.Count -eq 1) 'AXIS Updates Drivers Block completed status should keep the runtime text near the action row.'
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $updatesDriversCompletedRuntimeStatusRightAnchor[0] -Name 'Updates Drivers Block completed runtime status' -ExpectedMaxWidth 106)
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($taggedContinueButtons[0]) -eq 'AxisFirstUseWizard.EnabledNextButtonBlue') 'AXIS Updates Drivers Block Continue/Next should become blue after simulated completion.'
Assert-BoostLabCondition ([string]([System.Windows.Media.SolidColorBrush]$taggedContinueButtons[0].Background).Color -eq '#FF2563EB') 'AXIS Updates Drivers Block enabled Continue/Next should use the approved blue fill.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $taggedContentHost[0].Child -Tag 'AxisFirstUseWizard.UpdatesDriversStep').Count -eq 1) 'AXIS Updates Drivers Block should not auto-advance after simulated completion.'
Invoke-AxisFirstUseWizardButtonClick -Button $taggedContinueButtons[0]
$toBiosVisibleContent = $taggedContentHost[0].Child
$toBiosVisibleText = (Get-AxisFirstUseWizardTextValues -Root $toBiosVisibleContent) -join [Environment]::NewLine
$toBiosVisibleTextNormalized = ConvertTo-AxisFirstUseWizardNormalizedText -Text $toBiosVisibleText
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $toBiosVisibleContent -Tag 'AxisFirstUseWizard.ToBiosStep').Count -eq 1) 'AXIS Continue/Next from completed Updates Drivers Block should move to To BIOS.'
Assert-BoostLabCondition ([string]$currentStageHeader.Text -eq 'Refresh') 'AXIS To BIOS current stage header should show Refresh.'
[void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressCheckFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Check' -ExpectedColor '#FF22C55E' -Name 'To BIOS Check completed')
[void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressRefreshFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineActiveFullWhite.Refresh' -ExpectedColor '#FFF0F2F5' -Name 'To BIOS Refresh active')
Assert-BoostLabCondition (-not [bool]$taggedContinueButtons[0].IsEnabled) 'AXIS To BIOS Continue/Next should start disabled.'
foreach ($requiredToBiosText in @(
    'Refresh'
    $arabicToBiosTitle
    $arabicToBiosSubtitle
    $arabicToBiosInfoTitle
    $arabicToBiosInfoBulletRestart
    $arabicToBiosInfoBulletUsbBoot
    $arabicToBiosInfoBulletInstall
    $arabicToBiosPrimaryAction
    $arabicDocumentation
    $arabicSupportTitle
    $arabicSupportBody
)) {
    $requiredToBiosTextNormalized = ConvertTo-AxisFirstUseWizardNormalizedText -Text $requiredToBiosText
    Assert-BoostLabCondition (
        $toBiosVisibleText.Contains($requiredToBiosText) -or
        $toBiosVisibleTextNormalized.Contains($requiredToBiosTextNormalized)
    ) "AXIS To BIOS view is missing owner-approved text: $requiredToBiosText"
}
foreach ($forbiddenToBiosInternalText in @(
    'Analyze'
    'Open'
    'Apply'
    'Default'
    'Restore'
    'Cancel'
)) {
    Assert-BoostLabCondition (-not $toBiosVisibleText.Contains($forbiddenToBiosInternalText)) "AXIS To BIOS view exposes forbidden internal/customer action text: $forbiddenToBiosInternalText"
}
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $toBiosVisibleContent -Tag 'AxisFirstUseWizard.ToBiosInformationCard').Count -eq 1) 'AXIS To BIOS should render one information card.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $toBiosVisibleContent -Tag 'AxisFirstUseWizard.ToBiosInformationItem').Count -eq 3) 'AXIS To BIOS should render all three owner-approved information items.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $toBiosVisibleContent -Tag 'AxisFirstUseWizard.ToBiosRequirementsCard').Count -eq 0) 'AXIS To BIOS must not render a requirements card.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTypedElements -Root $toBiosVisibleContent -Type ([System.Windows.Controls.ComboBox])).Count -eq 0) 'AXIS To BIOS must not render a USB selector or input window control.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $toBiosVisibleContent -Tag 'AxisFirstUseWizard.SupportPanel').Count -eq 1) 'AXIS To BIOS support panel should remain separate and visible.'
$toBiosStepElement = @(Get-AxisFirstUseWizardTaggedElements -Root $toBiosVisibleContent -Tag 'AxisFirstUseWizard.ToBiosStep') | Select-Object -First 1
$toBiosContentGrid = @(Get-AxisFirstUseWizardTaggedElements -Root $toBiosVisibleContent -Tag 'AxisFirstUseWizard.StepTextContent') | Select-Object -First 1
$toBiosInformationCard = @(Get-AxisFirstUseWizardTaggedElements -Root $toBiosVisibleContent -Tag 'AxisFirstUseWizard.ToBiosInformationCard') | Select-Object -First 1
$toBiosInformationSharedRightEdge = @(Get-AxisFirstUseWizardTaggedElements -Root $toBiosVisibleContent -Tag 'AxisFirstUseWizard.ToBiosInformationSharedPhysicalRightEdge') | Select-Object -First 1
$toBiosActionArea = @(Get-AxisFirstUseWizardTaggedElements -Root $toBiosVisibleContent -Tag 'AxisFirstUseWizard.PrimaryActionArea') | Select-Object -First 1
$toBiosSupportPanel = @(Get-AxisFirstUseWizardTaggedElements -Root $toBiosVisibleContent -Tag 'AxisFirstUseWizard.SupportPanel') | Select-Object -First 1
$toBiosPrimaryButton = @(Get-AxisFirstUseWizardTaggedElements -Root $toBiosVisibleContent -Tag 'AxisFirstUseWizard.PrimaryOpenButton') | Select-Object -First 1
$toBiosDocumentationButton = @(Get-AxisFirstUseWizardTaggedElements -Root $toBiosVisibleContent -Tag 'AxisFirstUseWizard.DocumentationButton') | Select-Object -First 1
$toBiosRuntimeStatusArea = @(Get-AxisFirstUseWizardTaggedElements -Root $toBiosVisibleContent -Tag 'AxisFirstUseWizard.RuntimeStatusArea') | Select-Object -First 1
$toBiosRuntimeStatusSpacer = @(Get-AxisFirstUseWizardTaggedElements -Root $toBiosVisibleContent -Tag 'AxisFirstUseWizard.ActionRuntimeStatusSpacer') | Select-Object -First 1
$toBiosTitleAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $toBiosVisibleContent -Tag 'AxisFirstUseWizard.ToBiosTitleRightAnchor') | Select-Object -First 1
$toBiosEnglishOnlyTitle = @(Get-AxisFirstUseWizardTaggedElements -Root $toBiosVisibleContent -Tag 'AxisFirstUseWizard.ToBiosTitleEnglishOnlyText') | Select-Object -First 1
$toBiosTitleGroup = @(Get-AxisFirstUseWizardTaggedElements -Root $toBiosVisibleContent -Tag 'AxisFirstUseWizard.ToBiosTitleExplicitVisualGroup')
$toBiosTitleArabicSegment = @(Get-AxisFirstUseWizardTaggedElements -Root $toBiosVisibleContent -Tag 'AxisFirstUseWizard.ToBiosTitleArabicSegment')
$toBiosTitleEnglishSegment = @(Get-AxisFirstUseWizardTaggedElements -Root $toBiosVisibleContent -Tag 'AxisFirstUseWizard.ToBiosTitleEnglishSegment')
$toBiosSingleMixedTitleBlocks = @(Get-AxisFirstUseWizardTaggedElements -Root $toBiosVisibleContent -Tag 'AxisFirstUseWizard.ToBiosTitleBidiSafeRuns')
Assert-BoostLabCondition ([double]$toBiosStepElement.Height -eq 382.0) 'AXIS To BIOS should fit inside the 900x650 preview client area without clipping.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($toBiosStepElement) -eq 'AxisFirstUseWizard.ToBiosNoClippingLayout') 'AXIS To BIOS step should expose the fixed no-clipping layout marker.'
Assert-BoostLabCondition ($toBiosContentGrid.Children.IndexOf($toBiosActionArea) -lt $toBiosContentGrid.Children.IndexOf($toBiosSupportPanel)) 'AXIS To BIOS action row must remain separated above the support panel.'
Assert-BoostLabCondition ($null -ne $toBiosTitleAnchor) 'AXIS To BIOS title should use a physical right anchor.'
Assert-BoostLabCondition ($toBiosTitleAnchor.FlowDirection -eq [System.Windows.FlowDirection]::LeftToRight) 'AXIS To BIOS title anchor should use physical LTR positioning.'
Assert-BoostLabCondition ($toBiosTitleAnchor.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Stretch) 'AXIS To BIOS title anchor should span the content width.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($toBiosTitleAnchor) -eq 'AxisFirstUseWizard.ToBiosTitleRightAnchoredEnglishOnly') 'AXIS To BIOS title anchor should expose the English-only marker.'
Assert-BoostLabCondition ($toBiosSingleMixedTitleBlocks.Count -eq 0) 'AXIS To BIOS title must not regress to a single mixed BiDi title TextBlock.'
Assert-BoostLabCondition ($toBiosTitleGroup.Count -eq 0) 'AXIS To BIOS English-only title should not use the old explicit mixed visual group.'
Assert-BoostLabCondition ($toBiosTitleArabicSegment.Count -eq 0 -and $toBiosTitleEnglishSegment.Count -eq 0) 'AXIS To BIOS English-only title should not render old Arabic/BIOS title segment controls.'
Assert-BoostLabCondition ($null -ne $toBiosEnglishOnlyTitle) 'AXIS To BIOS title should render as a dedicated English-only TextBlock.'
Assert-BoostLabCondition ($toBiosTitleAnchor.Children.Count -eq 1 -and $toBiosTitleAnchor.Children[0] -eq $toBiosEnglishOnlyTitle) 'AXIS To BIOS title anchor should contain only the English-only title TextBlock.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($toBiosEnglishOnlyTitle) -eq 'AxisFirstUseWizard.ToBiosTitleEnglishOnlyLtr') 'AXIS To BIOS title TextBlock should expose the English-only LTR marker.'
Assert-BoostLabCondition ([string]$toBiosEnglishOnlyTitle.Text -eq 'To BIOS') 'AXIS To BIOS visible title should be exactly To BIOS.'
Assert-BoostLabCondition ([string]$toBiosEnglishOnlyTitle.Text -eq $arabicToBiosTitle) 'AXIS To BIOS title TextBlock should preserve the owner-approved title value.'
Assert-BoostLabCondition (-not $toBiosVisibleText.Contains($oldArabicToBiosTitle)) 'AXIS To BIOS visible title should not show the old mixed Arabic/English title.'
Assert-BoostLabCondition ($toBiosEnglishOnlyTitle.FlowDirection -eq [System.Windows.FlowDirection]::LeftToRight) 'AXIS To BIOS English-only title should render LTR.'
Assert-BoostLabCondition ($toBiosEnglishOnlyTitle.TextAlignment -eq [System.Windows.TextAlignment]::Right) 'AXIS To BIOS English-only title should remain right-aligned within the AXIS title area.'
Assert-BoostLabCondition ($toBiosEnglishOnlyTitle.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) 'AXIS To BIOS English-only title should remain physically anchored to the right.'
Assert-BoostLabCondition ($toBiosEnglishOnlyTitle.TextWrapping -eq [System.Windows.TextWrapping]::NoWrap) 'AXIS To BIOS English-only title should not wrap.'
Assert-BoostLabCondition ($toBiosInformationCard.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Stretch) 'AXIS To BIOS information card should stretch so Arabic starts from the right.'
Assert-BoostLabCondition ($toBiosInformationSharedRightEdge -is [System.Windows.Controls.Grid]) 'AXIS To BIOS information text should use a shared physical right-edge group.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($toBiosInformationSharedRightEdge) -eq 'AxisFirstUseWizard.ToBiosMixedBidiSafeInfoText') 'AXIS To BIOS information card should expose the mixed BiDi-safe marker.'
$toBiosInfoTextBlocks = @(Get-AxisFirstUseWizardTypedElements -Root $toBiosInformationSharedRightEdge -Type ([System.Windows.Controls.TextBlock]))
Assert-BoostLabCondition ($toBiosInfoTextBlocks.Count -ge 6) 'AXIS To BIOS information card should split mixed Arabic/English copy into deterministic right-aligned lines.'
foreach ($toBiosInfoTextBlock in $toBiosInfoTextBlocks) {
    Assert-BoostLabCondition ($toBiosInfoTextBlock.FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) 'AXIS To BIOS mixed information text should use RTL flow.'
    Assert-BoostLabCondition ($toBiosInfoTextBlock.TextAlignment -eq [System.Windows.TextAlignment]::Right) 'AXIS To BIOS mixed information text should stay right-aligned.'
    Assert-BoostLabCondition ($toBiosInfoTextBlock.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) 'AXIS To BIOS mixed information text should share the physical right edge.'
    Assert-BoostLabCondition ($toBiosInfoTextBlock.TextWrapping -eq [System.Windows.TextWrapping]::NoWrap) 'AXIS To BIOS mixed information text should avoid WPF automatic BiDi wrapping.'
}
$toBiosEnglishRuns = @(
    $toBiosInfoTextBlocks |
        ForEach-Object { @($_.Inlines) } |
        Where-Object { $_ -is [System.Windows.Documents.Run] -and $_.FlowDirection -eq [System.Windows.FlowDirection]::LeftToRight }
)
foreach ($requiredToBiosEnglishTerm in @('BIOS', 'USB', 'Windows')) {
    Assert-BoostLabCondition (@($toBiosEnglishRuns | Where-Object { [string]$_.Text -eq $requiredToBiosEnglishTerm }).Count -ge 1) "AXIS To BIOS information card should isolate the English term in an LTR Run: $requiredToBiosEnglishTerm"
}
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($toBiosSupportPanel) -eq 'AxisFirstUseWizard.ToBiosSupportCardNoClipping') 'AXIS To BIOS support panel should expose the no-clipping marker.'
Assert-BoostLabCondition ([double]$toBiosSupportPanel.MinHeight -eq 54.0) 'AXIS To BIOS support panel should use the compact no-clipping support height.'
Assert-BoostLabCondition ([double]$toBiosSupportPanel.Padding.Top -eq 7.0 -and [double]$toBiosSupportPanel.Padding.Bottom -eq 7.0) 'AXIS To BIOS support panel should keep enough internal padding without clipping.'
$toBiosStepElement.Measure([System.Windows.Size]::new(826.0, 389.0))
$toBiosRowTotal = 0.0
foreach ($toBiosRowChild in @($toBiosContentGrid.Children)) {
    $toBiosRowChild.Measure([System.Windows.Size]::new(758.0, [double]::PositiveInfinity))
    $toBiosRowTotal += [double]$toBiosRowChild.DesiredSize.Height
}
$toBiosInnerHeight = [double]$toBiosStepElement.Height -
    [double]$toBiosStepElement.Padding.Top -
    [double]$toBiosStepElement.Padding.Bottom -
    [double]$toBiosStepElement.BorderThickness.Top -
    [double]$toBiosStepElement.BorderThickness.Bottom
Assert-BoostLabCondition ($toBiosRowTotal -le $toBiosInnerHeight) 'AXIS To BIOS row content should fit inside the card without bottom support clipping.'
$toBiosSupportText = (Get-AxisFirstUseWizardTextValues -Root $toBiosSupportPanel) -join [Environment]::NewLine
Assert-BoostLabCondition ($toBiosSupportText.Contains($arabicSupportTitle) -and $toBiosSupportText.Contains($arabicSupportBody)) 'AXIS To BIOS support card should show the full approved support title and body.'
Assert-BoostLabCondition ([string]$toBiosPrimaryButton.Content -eq $arabicToBiosPrimaryAction) 'AXIS To BIOS primary button should use the owner-approved Arabic label.'
Assert-BoostLabCondition ([double]$toBiosPrimaryButton.Width -ge 200.0) 'AXIS To BIOS primary button should be wide enough for the owner-approved label.'
Assert-BoostLabCondition ($null -ne $toBiosDocumentationButton) 'AXIS To BIOS documentation button is missing.'
[void](Assert-AxisFirstUseWizardForegroundColor -Element $toBiosDocumentationButton -ExpectedColor $axisDefaultDocumentationForeground -Name 'To BIOS documentation button')
Assert-BoostLabCondition ($toBiosRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS To BIOS runtime status should start hidden.'
Assert-BoostLabCondition ([double]$toBiosRuntimeStatusArea.Width -eq 252.0) 'AXIS To BIOS runtime status should use a no-clipping width for the Arabic running state.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($toBiosRuntimeStatusArea) -eq 'AxisFirstUseWizard.ToBiosRuntimeStatusNoClipping') 'AXIS To BIOS runtime status should expose the no-clipping marker.'
$toBiosOverlay = $taggedOverlay[2]
$toBiosOverlayAcknowledgement = @(Get-AxisFirstUseWizardTaggedElements -Root $toBiosOverlay -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgement') | Select-Object -First 1
$toBiosOverlayAcknowledgementText = @(Get-AxisFirstUseWizardTaggedElements -Root $toBiosOverlay -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgementText') | Select-Object -First 1
$toBiosOverlayActionButton = @(Get-AxisFirstUseWizardTaggedElements -Root $toBiosOverlay -Tag 'AxisFirstUseWizard.ConfirmationOpenButton') | Select-Object -First 1
$toBiosOverlayReturnButton = @(Get-AxisFirstUseWizardTaggedElements -Root $toBiosOverlay -Tag 'AxisFirstUseWizard.ConfirmationReturnButton') | Select-Object -First 1
Assert-BoostLabCondition ([string]$toBiosOverlayAcknowledgementText.Text -eq $arabicAcknowledgement) 'AXIS To BIOS confirmation checkbox text changed.'
Assert-BoostLabCondition ([string]$toBiosOverlayActionButton.Content -eq $arabicRestart) 'AXIS To BIOS confirmation action button should use restart label.'
Assert-BoostLabCondition ([string]$toBiosOverlayReturnButton.Content -eq $arabicReturn) 'AXIS To BIOS confirmation Return button should use owner-approved Arabic Return.'
Assert-BoostLabCondition (-not [bool]$toBiosOverlayActionButton.IsEnabled) 'AXIS To BIOS confirmation action should start disabled until acknowledgement.'
Invoke-AxisFirstUseWizardButtonClick -Button $toBiosPrimaryButton
Assert-BoostLabCondition ($toBiosOverlay.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS To BIOS primary action should reveal the confirmation overlay only.'
Assert-BoostLabCondition ($toBiosRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS To BIOS primary action must not start restart simulation before confirmation.'
$toBiosOverlayAcknowledgement.IsChecked = $true
Assert-BoostLabCondition ([bool]$toBiosOverlayActionButton.IsEnabled) 'AXIS To BIOS confirm should enable after acknowledgement.'
Assert-AxisFirstUseWizardNextDisabledNonBlue -Button $taggedContinueButtons[0] -Name 'To BIOS after confirmation acknowledgement'
Invoke-AxisFirstUseWizardButtonClick -Button $toBiosOverlayReturnButton
Assert-BoostLabCondition ($toBiosOverlay.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS To BIOS Return should close only the overlay.'
Assert-BoostLabCondition (-not [bool]$toBiosOverlayAcknowledgement.IsChecked) 'AXIS To BIOS Return should reset acknowledgement.'
Assert-BoostLabCondition (-not [bool]$taggedContinueButtons[0].IsEnabled) 'AXIS To BIOS Return must not complete the step or enable Continue/Next.'
Assert-BoostLabCondition ($toBiosRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS To BIOS Return must not start restart simulation.'
Invoke-AxisFirstUseWizardButtonClick -Button $toBiosPrimaryButton
$toBiosOverlayAcknowledgement.IsChecked = $true
Invoke-AxisFirstUseWizardButtonClick -Button $toBiosOverlayActionButton
Assert-BoostLabCondition ($toBiosOverlay.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS To BIOS confirm should close the overlay.'
$toBiosRunningText = (Get-AxisFirstUseWizardTextValues -Root $toBiosVisibleContent) -join [Environment]::NewLine
Assert-BoostLabCondition ($toBiosRunningText.Contains($arabicRestarting)) 'AXIS To BIOS confirm should show the Arabic restarting simulation state.'
Assert-BoostLabCondition ($toBiosRunningText.Contains($arabicSupportBody)) 'AXIS To BIOS support panel should remain visible during restart simulation.'
Assert-BoostLabCondition ($toBiosRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS To BIOS runtime status should become visible during restart simulation.'
Assert-BoostLabCondition ($toBiosRuntimeStatusSpacer.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS To BIOS runtime status spacer should become visible during restart simulation.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $toBiosRuntimeStatusArea -Tag 'AxisFirstUseWizard.CheckingAnimation').Count -eq 1) 'AXIS To BIOS restart simulation should use the runtime checking animation.'
$toBiosRuntimeNoClippingMarkers = @(
    Get-AxisFirstUseWizardTypedElements -Root $toBiosRuntimeStatusArea -Type ([System.Windows.FrameworkElement]) |
        Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_) -eq 'AxisFirstUseWizard.ToBiosRuntimeStatusNoClipping' }
)
Assert-BoostLabCondition ($toBiosRuntimeNoClippingMarkers.Count -ge 2) 'AXIS To BIOS runtime status should mark both the host and content as no-clipping.'
$toBiosRunningRuntimeStatusRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $toBiosRuntimeStatusArea -Tag 'AxisFirstUseWizard.RuntimeStatusArabicRightAnchor')
Assert-BoostLabCondition ($toBiosRunningRuntimeStatusRightAnchor.Count -eq 1) 'AXIS To BIOS running status should keep the runtime text near the action row.'
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $toBiosRunningRuntimeStatusRightAnchor[0] -Name 'To BIOS running runtime status' -ExpectedMaxWidth 126)
$toBiosCompletedByTimer = Wait-AxisFirstUseWizardCondition -Condition { [bool]$taggedContinueButtons[0].IsEnabled } -TimeoutMilliseconds 3000
Assert-BoostLabCondition ([bool]$toBiosCompletedByTimer) 'AXIS To BIOS simulated flow should enable Continue/Next after completion.'
$toBiosCompletedText = (Get-AxisFirstUseWizardTextValues -Root $toBiosVisibleContent) -join [Environment]::NewLine
Assert-BoostLabCondition ($toBiosCompletedText.Contains($arabicCompleted)) 'AXIS To BIOS simulated flow should end in the owner-approved completed state.'
Assert-BoostLabCondition ($toBiosCompletedText.Contains($arabicSupportBody)) 'AXIS To BIOS support panel should remain visible after simulated completion.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $toBiosRuntimeStatusArea -Tag 'AxisFirstUseWizard.CompletedEffect').Count -eq 1) 'AXIS To BIOS completed state should render the completed runtime effect.'
$toBiosCompletedRuntimeStatusRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $toBiosRuntimeStatusArea -Tag 'AxisFirstUseWizard.RuntimeStatusArabicRightAnchor')
Assert-BoostLabCondition ($toBiosCompletedRuntimeStatusRightAnchor.Count -eq 1) 'AXIS To BIOS completed status should keep the runtime text near the action row.'
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $toBiosCompletedRuntimeStatusRightAnchor[0] -Name 'To BIOS completed runtime status' -ExpectedMaxWidth 126)
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($taggedContinueButtons[0]) -eq 'AxisFirstUseWizard.EnabledNextButtonBlue') 'AXIS To BIOS Continue/Next should become blue after simulated completion.'
Assert-BoostLabCondition ([string]([System.Windows.Media.SolidColorBrush]$taggedContinueButtons[0].Background).Color -eq '#FF2563EB') 'AXIS To BIOS enabled Continue/Next should use the approved blue fill.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $taggedContentHost[0].Child -Tag 'AxisFirstUseWizard.ToBiosStep').Count -eq 1) 'AXIS To BIOS should not auto-advance after simulated completion.'
Invoke-AxisFirstUseWizardButtonClick -Button $taggedContinueButtons[0]
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $taggedContentHost[0].Child -Tag 'AxisFirstUseWizard.SetupBitLockerStep').Count -eq 1) 'AXIS To BIOS Continue/Next should navigate to the first Setup step, BitLocker.'

for ($setupIndex = 0; $setupIndex -lt $setupStepSpecs.Count; $setupIndex++) {
    $setupSpec = [System.Collections.IDictionary]$setupStepSpecs[$setupIndex]
    $setupStep = [System.Collections.IDictionary]$setupSteps[$setupIndex]
    $tagRoot = [string]$setupSpec['TagRoot']
    $setupId = [string]$setupSpec['Id']
    $setupVisibleContent = $taggedContentHost[0].Child
    $setupVisibleText = (Get-AxisFirstUseWizardTextValues -Root $setupVisibleContent) -join [Environment]::NewLine
    $setupVisibleTextNormalized = ConvertTo-AxisFirstUseWizardNormalizedText -Text $setupVisibleText

    Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $setupVisibleContent -Tag "AxisFirstUseWizard.${tagRoot}Step").Count -eq 1) "AXIS Setup step should render the expected step card: $setupId"
    Assert-BoostLabCondition ([string]$currentStageHeader.Text -eq 'Setup') "AXIS Setup current stage header should show Setup for $setupId."
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressCheckFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Check' -ExpectedColor '#FF22C55E' -Name "$setupId Check completed")
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressRefreshFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Refresh' -ExpectedColor '#FF22C55E' -Name "$setupId Refresh completed")
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressSetupFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineActiveFullWhite.Setup' -ExpectedColor '#FFF0F2F5' -Name "$setupId Setup active")
    Assert-BoostLabCondition (-not [bool]$taggedContinueButtons[0].IsEnabled) "AXIS Setup Continue/Next should start disabled for $setupId."
    Assert-BoostLabCondition (-not $setupVisibleText.Contains([string][char]0xFFFD)) "AXIS Setup visible copy must not contain a replacement glyph for $setupId."
    Assert-BoostLabCondition (-not $setupVisibleText.Contains('?')) "AXIS Setup visible copy must not contain a stray ASCII question mark for $setupId."

    $setupTitleTextBlock = @(Get-AxisFirstUseWizardTaggedElements -Root $setupVisibleContent -Tag "AxisFirstUseWizard.${tagRoot}TitleText") | Select-Object -First 1
    Assert-BoostLabCondition ($null -ne $setupTitleTextBlock) "AXIS Setup title TextBlock is missing for $setupId."
    Assert-BoostLabCondition ([string](Get-AxisFirstUseWizardTextBlockPlainText -TextBlock $setupTitleTextBlock) -eq [string]$setupSpec['Title']) "AXIS Setup title changed for $setupId."
    Assert-BoostLabCondition ($setupTitleTextBlock.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) "AXIS Setup title should remain physically anchored right for $setupId."
    Assert-BoostLabCondition ($setupTitleTextBlock.TextAlignment -eq [System.Windows.TextAlignment]::Right) "AXIS Setup title should remain right-aligned for $setupId."
    if ([regex]::IsMatch([string]$setupSpec['Title'], '^[\x00-\x7F]+$')) {
        Assert-BoostLabCondition ($setupTitleTextBlock.FlowDirection -eq [System.Windows.FlowDirection]::LeftToRight) "AXIS Setup English-only title should render LTR for $setupId."
        Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($setupTitleTextBlock) -eq "AxisFirstUseWizard.EnglishOnlyTitleRightAnchored.${tagRoot}") "AXIS Setup English-only title should expose the right-anchored LTR marker for $setupId."
    }
    else {
        Assert-BoostLabCondition ($setupTitleTextBlock.FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) "AXIS Setup Arabic title should render RTL for $setupId."
    }
    if ($setupId -eq 'background-apps') {
        Assert-BoostLabCondition ([string](Get-AxisFirstUseWizardTextBlockPlainText -TextBlock $setupTitleTextBlock) -eq 'Background Apps') 'AXIS Background Apps visible title should use the owner-approved English-only title.'
    }

    foreach ($requiredSetupText in @(
        'Setup'
        [string]$setupSpec['Title']
        [string]$setupSpec['Subtitle']
        [string]$setupSpec['InfoTitle']
        @($setupSpec['InfoItems'])
        @($setupSpec['Requirements'])
        [string]$setupSpec['Primary']
        $arabicDocumentation
        $arabicSupportTitle
        $arabicSupportBody
    )) {
        foreach ($requiredSetupTextItem in @($requiredSetupText)) {
            if ([string]::IsNullOrWhiteSpace([string]$requiredSetupTextItem)) {
                continue
            }
            $requiredSetupTextNormalized = ConvertTo-AxisFirstUseWizardNormalizedText -Text ([string]$requiredSetupTextItem)
            Assert-BoostLabCondition (
                $setupVisibleText.Contains([string]$requiredSetupTextItem) -or
                $setupVisibleTextNormalized.Contains($requiredSetupTextNormalized)
            ) "AXIS Setup view is missing owner-approved text for ${setupId}: $requiredSetupTextItem"
        }
    }

    foreach ($forbiddenSetupVisibleText in @('Analyze', 'Apply', 'Default', 'Restore', 'Cancel')) {
        Assert-BoostLabCondition (-not $setupVisibleText.Contains($forbiddenSetupVisibleText)) "AXIS Setup view exposes forbidden internal/customer action text for ${setupId}: $forbiddenSetupVisibleText"
    }

    $setupDetailsGrid = @(Get-AxisFirstUseWizardTaggedElements -Root $setupVisibleContent -Tag "AxisFirstUseWizard.${tagRoot}StepDetails") | Select-Object -First 1
    $setupInformationCard = @(Get-AxisFirstUseWizardTaggedElements -Root $setupVisibleContent -Tag "AxisFirstUseWizard.${tagRoot}InformationCard") | Select-Object -First 1
    $setupInformationSharedRightEdge = @(Get-AxisFirstUseWizardTaggedElements -Root $setupVisibleContent -Tag "AxisFirstUseWizard.${tagRoot}InformationSharedPhysicalRightEdge") | Select-Object -First 1
    Assert-BoostLabCondition ($null -ne $setupDetailsGrid) "AXIS Setup details grid is missing for $setupId."
    Assert-BoostLabCondition ($null -ne $setupInformationCard) "AXIS Setup should render one information card for $setupId."
    Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $setupVisibleContent -Tag "AxisFirstUseWizard.${tagRoot}InformationItem").Count -eq @($setupSpec['InfoItems']).Count) "AXIS Setup information item count changed for $setupId."
    Assert-BoostLabCondition ($null -ne $setupInformationSharedRightEdge) "AXIS Setup information should use one shared physical right edge for $setupId."
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($setupInformationSharedRightEdge) -eq "AxisFirstUseWizard.${tagRoot}MixedBidiSafeInfoText") "AXIS Setup information should expose the mixed BiDi-safe marker for $setupId."
    foreach ($setupInformationTextBlock in @(Get-AxisFirstUseWizardTypedElements -Root $setupInformationSharedRightEdge -Type ([System.Windows.Controls.TextBlock]))) {
        Assert-BoostLabCondition ($setupInformationTextBlock.FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) "AXIS Setup information text should stay RTL for $setupId."
        Assert-BoostLabCondition ($setupInformationTextBlock.TextAlignment -eq [System.Windows.TextAlignment]::Right) "AXIS Setup information text should stay right-aligned for $setupId."
        Assert-BoostLabCondition ($setupInformationTextBlock.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) "AXIS Setup information text should share the physical right edge for $setupId."
    }
    if ($setupId -eq 'updates-pause') {
        $updatesPauseRightAlignedVisualLines = @(
            Get-AxisFirstUseWizardTypedElements -Root $setupInformationSharedRightEdge -Type ([System.Windows.Controls.TextBlock]) |
                Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_) -eq $axisSetupRightAlignedVisualLineRendererAutomationId }
        )
        Assert-BoostLabCondition ($updatesPauseRightAlignedVisualLines.Count -ge 4) 'AXIS Updates Pause information should use right-aligned visual lines for wrapped Arabic phrases.'
        foreach ($updatesPauseRightAlignedVisualLine in $updatesPauseRightAlignedVisualLines) {
            Assert-BoostLabCondition ($updatesPauseRightAlignedVisualLine.TextWrapping -eq [System.Windows.TextWrapping]::NoWrap) 'AXIS Updates Pause right-aligned visual lines should bypass automatic WPF wrapping.'
            Assert-BoostLabCondition ($updatesPauseRightAlignedVisualLine.TextAlignment -eq [System.Windows.TextAlignment]::Right) 'AXIS Updates Pause right-aligned visual lines should stay right-aligned.'
            Assert-BoostLabCondition ($updatesPauseRightAlignedVisualLine.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) 'AXIS Updates Pause right-aligned visual lines should stay physically anchored right.'
        }
        $updatesPauseRightAlignedVisualLineText = @($updatesPauseRightAlignedVisualLines | ForEach-Object { [string](Get-AxisFirstUseWizardTextBlockPlainText -TextBlock $_).Trim() })
        Assert-BoostLabCondition (-not ($updatesPauseRightAlignedVisualLineText -contains $arabicUpdatesPauseDeviceOrphan)) 'AXIS Updates Pause information must not leave device text as an orphan left-floating word.'
        Assert-BoostLabCondition (-not ($updatesPauseRightAlignedVisualLineText -contains $arabicUpdatesPauseUpdatesOrphan)) 'AXIS Updates Pause information must not leave updates text as an orphan left-floating word.'
    }
    if (@($setupSpec['Requirements']).Count -gt 0) {
        $setupRequirementsCard = @(Get-AxisFirstUseWizardTaggedElements -Root $setupVisibleContent -Tag "AxisFirstUseWizard.${tagRoot}RequirementsCard") | Select-Object -First 1
        $setupRequirementsSharedRightEdge = @(Get-AxisFirstUseWizardTaggedElements -Root $setupVisibleContent -Tag "AxisFirstUseWizard.${tagRoot}RequirementsSharedPhysicalRightEdge") | Select-Object -First 1
        Assert-BoostLabCondition ($setupDetailsGrid.FlowDirection -eq [System.Windows.FlowDirection]::LeftToRight) "AXIS Setup two-card grid should use physical LTR column placement for $setupId."
        Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($setupDetailsGrid) -eq 'AxisFirstUseWizard.SetupCardsPhysicalOrderInfoRightRequirementsLeft') "AXIS Setup two-card grid should expose the info-right requirements-left marker for $setupId."
        Assert-BoostLabCondition ($null -ne $setupRequirementsCard) "AXIS Setup should render a requirements card for $setupId."
        Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($setupRequirementsCard) -eq 0) "AXIS Setup requirements card should stay in the physical left column for $setupId."
        Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($setupInformationCard) -eq 2) "AXIS Setup information card should stay in the physical right column for $setupId."
        Assert-BoostLabCondition ([double]$setupInformationCard.Height -le 146.0 -and [double]$setupRequirementsCard.Height -le 146.0) "AXIS Setup two-card rows should leave support room inside 900x650 for $setupId."
        Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $setupVisibleContent -Tag "AxisFirstUseWizard.${tagRoot}RequirementItem").Count -eq @($setupSpec['Requirements']).Count) "AXIS Setup requirement item count changed for $setupId."
        Assert-BoostLabCondition ($null -ne $setupRequirementsSharedRightEdge) "AXIS Setup requirements should use one shared physical right edge for $setupId."
        Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($setupRequirementsSharedRightEdge) -eq "AxisFirstUseWizard.${tagRoot}MixedBidiSafeRequirementsText") "AXIS Setup requirements should expose the mixed BiDi-safe marker for $setupId."
        foreach ($setupRequirementTextBlock in @(Get-AxisFirstUseWizardTypedElements -Root $setupRequirementsSharedRightEdge -Type ([System.Windows.Controls.TextBlock]))) {
            Assert-BoostLabCondition ($setupRequirementTextBlock.FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) "AXIS Setup requirements text should stay RTL for $setupId."
            Assert-BoostLabCondition ($setupRequirementTextBlock.TextAlignment -eq [System.Windows.TextAlignment]::Right) "AXIS Setup requirements text should stay right-aligned for $setupId."
            Assert-BoostLabCondition ($setupRequirementTextBlock.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) "AXIS Setup requirements text should share the physical right edge for $setupId."
        }
        if ($setupId -eq 'startup-apps-settings') {
            $startupAppsSettingsRightAlignedVisualLines = @(
                Get-AxisFirstUseWizardTypedElements -Root $setupRequirementsSharedRightEdge -Type ([System.Windows.Controls.TextBlock]) |
                    Where-Object { [System.Windows.Automation.AutomationProperties]::GetAutomationId($_) -eq $axisSetupRightAlignedVisualLineRendererAutomationId }
            )
            Assert-BoostLabCondition ($startupAppsSettingsRightAlignedVisualLines.Count -ge 2) 'AXIS Startup Apps Settings requirements should use right-aligned visual lines for wrapped Arabic phrases.'
            foreach ($startupAppsSettingsRightAlignedVisualLine in $startupAppsSettingsRightAlignedVisualLines) {
                Assert-BoostLabCondition ($startupAppsSettingsRightAlignedVisualLine.TextWrapping -eq [System.Windows.TextWrapping]::NoWrap) 'AXIS Startup Apps Settings right-aligned visual lines should bypass automatic WPF wrapping.'
                Assert-BoostLabCondition ($startupAppsSettingsRightAlignedVisualLine.TextAlignment -eq [System.Windows.TextAlignment]::Right) 'AXIS Startup Apps Settings right-aligned visual lines should stay right-aligned.'
                Assert-BoostLabCondition ($startupAppsSettingsRightAlignedVisualLine.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) 'AXIS Startup Apps Settings right-aligned visual lines should stay physically anchored right.'
            }
            $startupAppsSettingsRightAlignedVisualLineText = @($startupAppsSettingsRightAlignedVisualLines | ForEach-Object { [string](Get-AxisFirstUseWizardTextBlockPlainText -TextBlock $_).Trim() })
            Assert-BoostLabCondition (@($startupAppsSettingsRightAlignedVisualLineText | Where-Object { $_.Contains($arabicStartupAppsStartupPhrase) }).Count -ge 1) 'AXIS Startup Apps Settings requirements should keep the startup phrase in a right-aligned visual line.'
        }
    }
    else {
        Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($setupInformationCard) -eq 0) "AXIS Setup single information card should stay in its only column for $setupId."
        Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $setupVisibleContent -Tag "AxisFirstUseWizard.${tagRoot}RequirementsCard").Count -eq 0) "AXIS Setup should not render a requirements card for $setupId."
    }
    Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTypedElements -Root $setupVisibleContent -Type ([System.Windows.Controls.ComboBox])).Count -eq 0) "AXIS Setup step should not render an input selector for $setupId."
    $setupSupportPanel = @(Get-AxisFirstUseWizardTaggedElements -Root $setupVisibleContent -Tag 'AxisFirstUseWizard.SupportPanel') | Select-Object -First 1
    $setupActionArea = @(Get-AxisFirstUseWizardTaggedElements -Root $setupVisibleContent -Tag 'AxisFirstUseWizard.PrimaryActionArea') | Select-Object -First 1
    $setupContentGrid = @(Get-AxisFirstUseWizardTaggedElements -Root $setupVisibleContent -Tag 'AxisFirstUseWizard.StepTextContent') | Select-Object -First 1
    Assert-BoostLabCondition ($null -ne $setupSupportPanel) "AXIS Setup support panel should remain separate for $setupId."
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($setupSupportPanel) -eq 'AxisFirstUseWizard.SetupSupportCardNoClipping') "AXIS Setup support panel should expose the no-clipping marker for $setupId."
    Assert-BoostLabCondition ([double]$setupSupportPanel.MinHeight -eq 54.0) "AXIS Setup support panel should use compact no-clipping support height for $setupId."
    Assert-BoostLabCondition ([double]$setupSupportPanel.Padding.Top -eq 7.0 -and [double]$setupSupportPanel.Padding.Bottom -eq 7.0) "AXIS Setup support panel should keep enough compact internal padding for $setupId."
    Assert-BoostLabCondition ($setupContentGrid.Children.IndexOf($setupActionArea) -lt $setupContentGrid.Children.IndexOf($setupSupportPanel)) "AXIS Setup action row must remain separated above the support panel for $setupId."
    $setupStepElement = @(Get-AxisFirstUseWizardTaggedElements -Root $setupVisibleContent -Tag "AxisFirstUseWizard.${tagRoot}Step") | Select-Object -First 1
    $setupStepElement.Measure([System.Windows.Size]::new(826.0, 389.0))
    $setupRowTotal = 0.0
    foreach ($setupRowChild in @($setupContentGrid.Children)) {
        $setupRowChild.Measure([System.Windows.Size]::new(758.0, [double]::PositiveInfinity))
        $setupRowTotal += [double]$setupRowChild.DesiredSize.Height
    }
    $setupInnerHeight = [double]$setupStepElement.Height -
        [double]$setupStepElement.Padding.Top -
        [double]$setupStepElement.Padding.Bottom -
        [double]$setupStepElement.BorderThickness.Top -
        [double]$setupStepElement.BorderThickness.Bottom
    Assert-BoostLabCondition ($setupRowTotal -le $setupInnerHeight) "AXIS Setup row content should fit inside the card without support clipping for $setupId."

    $setupPrimaryButton = @(Get-AxisFirstUseWizardTaggedElements -Root $setupVisibleContent -Tag 'AxisFirstUseWizard.PrimaryOpenButton') | Select-Object -First 1
    $setupRuntimeStatusArea = @(Get-AxisFirstUseWizardTaggedElements -Root $setupVisibleContent -Tag 'AxisFirstUseWizard.RuntimeStatusArea') | Select-Object -First 1
    $setupRuntimeStatusSpacer = @(Get-AxisFirstUseWizardTaggedElements -Root $setupVisibleContent -Tag 'AxisFirstUseWizard.ActionRuntimeStatusSpacer') | Select-Object -First 1
    Assert-BoostLabCondition ([string]$setupPrimaryButton.Content -eq [string]$setupSpec['Primary']) "AXIS Setup primary button text changed for $setupId."
    Assert-BoostLabCondition ($setupRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) "AXIS Setup runtime status should start hidden for $setupId."
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($setupRuntimeStatusArea) -eq 'AxisFirstUseWizard.SetupRuntimeStatusNoClipping') "AXIS Setup runtime status should expose the no-clipping marker for $setupId."

    if ([bool]$setupSpec['Overlay']) {
        $setupOverlay = $taggedOverlay[3]
        $setupOverlayAcknowledgement = @(Get-AxisFirstUseWizardTaggedElements -Root $setupOverlay -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgement') | Select-Object -First 1
        $setupOverlayAcknowledgementText = @(Get-AxisFirstUseWizardTaggedElements -Root $setupOverlay -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgementText') | Select-Object -First 1
        $setupOverlayActionButton = @(Get-AxisFirstUseWizardTaggedElements -Root $setupOverlay -Tag 'AxisFirstUseWizard.ConfirmationOpenButton') | Select-Object -First 1
        $setupOverlayReturnButton = @(Get-AxisFirstUseWizardTaggedElements -Root $setupOverlay -Tag 'AxisFirstUseWizard.ConfirmationReturnButton') | Select-Object -First 1
        Assert-BoostLabCondition ([string]$setupOverlayAcknowledgementText.Text -eq [string]$setupSpec['Checkbox']) 'AXIS Updates Pause confirmation checkbox text changed.'
        Assert-BoostLabCondition ([string]$setupOverlayActionButton.Content -eq [string]$setupSpec['ConfirmationPrimary']) 'AXIS Updates Pause confirmation primary text changed.'
        Assert-BoostLabCondition ([string]$setupOverlayReturnButton.Content -eq [string]$setupSpec['ConfirmationReturn']) 'AXIS Updates Pause confirmation return text changed.'
        Assert-BoostLabCondition (-not [bool]$setupOverlayActionButton.IsEnabled) 'AXIS Updates Pause confirmation primary should start disabled.'
        Invoke-AxisFirstUseWizardButtonClick -Button $setupPrimaryButton
        Assert-BoostLabCondition ($setupOverlay.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS Updates Pause primary action should reveal the confirmation overlay only.'
        Assert-BoostLabCondition ($setupRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Updates Pause primary action must not start simulation before acknowledgement.'
        $setupOverlayAcknowledgement.IsChecked = $true
        Assert-BoostLabCondition ([bool]$setupOverlayActionButton.IsEnabled) 'AXIS Updates Pause confirmation primary should enable after acknowledgement.'
        Assert-AxisFirstUseWizardNextDisabledNonBlue -Button $taggedContinueButtons[0] -Name "$setupId after confirmation acknowledgement"
        Invoke-AxisFirstUseWizardButtonClick -Button $setupOverlayReturnButton
        Assert-BoostLabCondition ($setupOverlay.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Updates Pause Return should close only the overlay.'
        Assert-BoostLabCondition (-not [bool]$setupOverlayAcknowledgement.IsChecked) 'AXIS Updates Pause Return should reset acknowledgement.'
        Assert-BoostLabCondition (-not [bool]$taggedContinueButtons[0].IsEnabled) 'AXIS Updates Pause Return must not complete the step.'
        Invoke-AxisFirstUseWizardButtonClick -Button $setupPrimaryButton
        $setupOverlayAcknowledgement.IsChecked = $true
        Invoke-AxisFirstUseWizardButtonClick -Button $setupOverlayActionButton
        Assert-BoostLabCondition ($setupOverlay.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Updates Pause confirmation should close the overlay.'
    }
    else {
        Invoke-AxisFirstUseWizardButtonClick -Button $setupPrimaryButton
        Assert-BoostLabCondition ($taggedOverlay[0].Visibility -eq [System.Windows.Visibility]::Collapsed) "AXIS Setup direct action must not reveal BIOS Drivers overlay for $setupId."
        Assert-BoostLabCondition ($taggedOverlay[1].Visibility -eq [System.Windows.Visibility]::Collapsed) "AXIS Setup direct action must not reveal BIOS Settings overlay for $setupId."
        Assert-BoostLabCondition ($taggedOverlay[2].Visibility -eq [System.Windows.Visibility]::Collapsed) "AXIS Setup direct action must not reveal To BIOS overlay for $setupId."
        Assert-BoostLabCondition ($taggedOverlay[3].Visibility -eq [System.Windows.Visibility]::Collapsed) "AXIS Setup direct action must not reveal Updates Pause overlay for $setupId."
    }

    $setupRunningText = (Get-AxisFirstUseWizardTextValues -Root $setupVisibleContent) -join [Environment]::NewLine
    Assert-BoostLabCondition ($setupRunningText.Contains([string]$setupSpec['Running'])) "AXIS Setup should show the owner-approved running text for $setupId."
    Assert-BoostLabCondition ($setupRunningText.Contains($arabicSupportBody)) "AXIS Setup support panel should remain visible during simulation for $setupId."
    Assert-BoostLabCondition ($setupRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Visible) "AXIS Setup runtime status should become visible during simulation for $setupId."
    Assert-BoostLabCondition ($setupRuntimeStatusSpacer.Visibility -eq [System.Windows.Visibility]::Visible) "AXIS Setup runtime status spacer should become visible during simulation for $setupId."
    Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $setupRuntimeStatusArea -Tag 'AxisFirstUseWizard.CheckingAnimation').Count -eq 1) "AXIS Setup simulated flow should use the runtime checking animation for $setupId."
    $setupRuntimeStatusRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $setupRuntimeStatusArea -Tag 'AxisFirstUseWizard.RuntimeStatusArabicRightAnchor')
    Assert-BoostLabCondition ($setupRuntimeStatusRightAnchor.Count -eq 1) "AXIS Setup running status should keep text near the action row for $setupId."
    [void](Assert-AxisFirstUseWizardRightAnchor -Anchor $setupRuntimeStatusRightAnchor[0] -Name "$setupId running runtime status" -ExpectedMaxWidth ([double]$setupStep['RuntimeStatusTextMaxWidth']))

    Assert-BoostLabCondition (Wait-AxisFirstUseWizardCondition -Condition { [bool]$taggedContinueButtons[0].IsEnabled } -TimeoutMilliseconds 3000) "AXIS Setup simulated flow should enable Continue/Next for $setupId."
    $setupCompletedText = (Get-AxisFirstUseWizardTextValues -Root $setupVisibleContent) -join [Environment]::NewLine
    Assert-BoostLabCondition ($setupCompletedText.Contains([string]$setupSpec['Completed'])) "AXIS Setup should show the owner-approved completed text for $setupId."
    Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $setupRuntimeStatusArea -Tag 'AxisFirstUseWizard.CompletedEffect').Count -eq 1) "AXIS Setup completed state should render the completed runtime effect for $setupId."
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($taggedContinueButtons[0]) -eq 'AxisFirstUseWizard.EnabledNextButtonBlue') "AXIS Setup Continue/Next should become blue after simulated completion for $setupId."
    Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $taggedContentHost[0].Child -Tag "AxisFirstUseWizard.${tagRoot}Step").Count -eq 1) "AXIS Setup should not auto-advance after simulated completion for $setupId."

    Invoke-AxisFirstUseWizardButtonClick -Button $taggedContinueButtons[0]
    if ($setupIndex -lt ($setupStepSpecs.Count - 1)) {
        $nextTagRoot = [string]([System.Collections.IDictionary]$setupStepSpecs[$setupIndex + 1])['TagRoot']
        Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $taggedContentHost[0].Child -Tag "AxisFirstUseWizard.${nextTagRoot}Step").Count -eq 1) "AXIS Setup Continue/Next should navigate to the next Setup step after $setupId."
    }
    else {
        Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $taggedContentHost[0].Child -Tag 'AxisFirstUseWizard.InstallersStep').Count -eq 1) 'AXIS Updates Pause Continue/Next should navigate to the Installers step.'
    }
}

$installersVisibleContent = $taggedContentHost[0].Child
$installersVisibleText = (Get-AxisFirstUseWizardTextValues -Root $installersVisibleContent) -join [Environment]::NewLine
$installersVisibleTextNormalized = ConvertTo-AxisFirstUseWizardNormalizedText -Text $installersVisibleText
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.InstallersStep').Count -eq 1) 'AXIS Installers step should render immediately after Updates Pause.'
Assert-BoostLabCondition ([string]$currentStageHeader.Text -eq 'Installers') 'AXIS Installers current stage header should show Installers.'
[void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressCheckFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Check' -ExpectedColor '#FF22C55E' -Name 'Installers Check completed')
[void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressRefreshFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Refresh' -ExpectedColor '#FF22C55E' -Name 'Installers Refresh completed')
[void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressSetupFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Setup' -ExpectedColor '#FF22C55E' -Name 'Installers Setup completed')
[void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressInstallersFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineActiveFullWhite.Installers' -ExpectedColor '#FFF0F2F5' -Name 'Installers active')
Assert-BoostLabCondition (-not [bool]$taggedContinueButtons[0].IsEnabled) 'AXIS Installers Continue/Next should start disabled.'
Assert-BoostLabCondition (-not $installersVisibleText.Contains([string][char]0xFFFD)) 'AXIS Installers visible copy must not contain a replacement glyph.'

foreach ($requiredInstallersText in @(
    'Installers'
    $arabicInstallersTitle
    $arabicInstallersSubtitle
    $arabicInstallersSelectorLabel
    $arabicInstallersInfoTitle
    $arabicInstallersInfoBullet1
    $arabicInstallersInfoBullet2
    $arabicInstallersInfoBullet3
    $arabicRequirementsTitle
    $arabicInstallersRequirement1
    $arabicInstallersRequirement2
    'Install'
    $arabicDocumentation
    $arabicSupportTitle
    $arabicSupportBody
)) {
    $requiredInstallersTextNormalized = ConvertTo-AxisFirstUseWizardNormalizedText -Text $requiredInstallersText
    Assert-BoostLabCondition (
        $installersVisibleText.Contains($requiredInstallersText) -or
        $installersVisibleTextNormalized.Contains($requiredInstallersTextNormalized)
    ) "AXIS Installers view is missing owner-approved text: $requiredInstallersText"
}
foreach ($forbiddenInstallersVisibleText in @('Analyze', 'Apply', 'Default', 'Restore', 'Cancel')) {
    Assert-BoostLabCondition (-not $installersVisibleText.Contains($forbiddenInstallersVisibleText)) "AXIS Installers view exposes forbidden internal/customer action text: $forbiddenInstallersVisibleText"
}
foreach ($removedInstallerVisibleName in @('Escape From Tarkov', 'Frame View', 'GOG launcher', 'Notepad ++', 'Nvidia App', 'Onboard Memory Manager', 'Pot Player', 'Exit')) {
    Assert-BoostLabCondition (-not $installersVisibleText.Contains($removedInstallerVisibleName)) "AXIS Installers visible selector must not expose removed/non-selectable app: $removedInstallerVisibleName"
}

$installersStepElement = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.InstallersStep') | Select-Object -First 1
$installersContentGrid = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.StepTextContent') | Select-Object -First 1
$installersTitleText = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.InstallersTitleText') | Select-Object -First 1
$installersTitleRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.InstallersTitleRightAnchor') | Select-Object -First 1
$installersDetailsGrid = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.InstallersStepDetails') | Select-Object -First 1
$installersInformationCard = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.InstallersInformationCard') | Select-Object -First 1
$installersRequirementsCard = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.InstallersRequirementsCard') | Select-Object -First 1
$installersInformationSharedRightEdge = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.InstallersInformationSharedPhysicalRightEdge') | Select-Object -First 1
$installersRequirementsSharedRightEdge = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.InstallersRequirementsSharedPhysicalRightEdge') | Select-Object -First 1
$installersInformationRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.InstallersInformationRightAnchor') | Select-Object -First 1
$installersRequirementsRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.InstallersRequirementsRightAnchor') | Select-Object -First 1
$installersActionArea = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.PrimaryActionArea') | Select-Object -First 1
$installersSupportPanel = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.SupportPanel') | Select-Object -First 1
$installersRuntimeStatusArea = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.RuntimeStatusArea') | Select-Object -First 1
$installersRuntimeStatusSpacer = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.ActionRuntimeStatusSpacer') | Select-Object -First 1
$installersPrimaryButton = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.PrimaryOpenButton') | Select-Object -First 1
$installersSelectorRow = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.InstallersSelectorRow') | Select-Object -First 1
$installersSelectorLabel = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.InstallersSelectorLabel') | Select-Object -First 1
$installersSelector = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.InstallersProgramSelector') | Select-Object -First 1
$installersSelectedProgramDisplay = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.InstallersSelectedProgramDisplay') | Select-Object -First 1
$installersSelectedProgramName = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.InstallersSelectedProgramName') | Select-Object -First 1
$installersSelectedProgramPrefix = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.InstallersSelectedProgramPrefix') | Select-Object -First 1
$installersInlineEpicGuidanceBlocks = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.InstallersEpicGuidanceBlock')
$installersInlineEpicCheckboxes = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.InstallersEpicCheckbox')
$installersInlineEpicCheckboxTexts = @(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.InstallersEpicCheckboxText')
$installersEpicInstructionOverlay = @(Get-AxisFirstUseWizardTaggedElements -Root $prototype -Tag 'AxisFirstUseWizard.InstallersEpicInstructionOverlay') | Select-Object -First 1
$installersEpicInstructionTitle = @(Get-AxisFirstUseWizardTaggedElements -Root $installersEpicInstructionOverlay -Tag 'AxisFirstUseWizard.InstallersEpicInstructionTitle') | Select-Object -First 1
$installersEpicInstructionBodyItems = @(Get-AxisFirstUseWizardTaggedElements -Root $installersEpicInstructionOverlay -Tag 'AxisFirstUseWizard.InstallersEpicInstructionBodyItem')
$installersEpicInstructionBodyGroup = @(Get-AxisFirstUseWizardTaggedElements -Root $installersEpicInstructionOverlay -Tag 'AxisFirstUseWizard.InstallersEpicInstructionBodySharedPhysicalRightEdge') | Select-Object -First 1
$installersEpicInstructionBodyVisualLines = @(Get-AxisFirstUseWizardTaggedElements -Root $installersEpicInstructionOverlay -Tag 'AxisFirstUseWizard.InstallersEpicInstructionBodyVisualLine')
$installersEpicInstructionInstallButton = @(Get-AxisFirstUseWizardTaggedElements -Root $installersEpicInstructionOverlay -Tag 'AxisFirstUseWizard.InstallersEpicInstructionInstallButton') | Select-Object -First 1
$installersEpicInstructionReturnButton = @(Get-AxisFirstUseWizardTaggedElements -Root $installersEpicInstructionOverlay -Tag 'AxisFirstUseWizard.InstallersEpicInstructionReturnButton') | Select-Object -First 1
Assert-BoostLabCondition ([double]$installersStepElement.Height -eq 382.0) 'AXIS Installers should use the normal 900x650 content row height after removing inline Epic content.'
Assert-BoostLabCondition ($installersTitleRightAnchor -is [System.Windows.Controls.Grid]) 'AXIS Installers title right anchor should be a full-width positioning Grid.'
Assert-BoostLabCondition ($installersTitleText.FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) 'AXIS Installers Arabic title should render RTL.'
Assert-BoostLabCondition ($installersTitleText.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) 'AXIS Installers title should be physically anchored right.'
Assert-BoostLabCondition ([string](Get-AxisFirstUseWizardTextBlockPlainText -TextBlock $installersTitleText) -eq $arabicInstallersTitle) 'AXIS Installers title text changed.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($installersDetailsGrid) -eq 'AxisFirstUseWizard.InstallersCardsPhysicalOrderInfoRightRequirementsLeft') 'AXIS Installers two-card grid should expose the info-right requirements-left marker.'
Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($installersInformationCard) -eq 2) 'AXIS Installers information card should stay in the physical right column.'
Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($installersRequirementsCard) -eq 0) 'AXIS Installers requirements card should stay in the physical left column.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.InstallersInformationItem').Count -eq 3) 'AXIS Installers should render all three information bullets.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.InstallersRequirementItem').Count -eq 2) 'AXIS Installers should render both requirements bullets.'
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $installersInformationRightAnchor -Name 'Installers information card' -ExpectedMaxWidth 340)
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $installersRequirementsRightAnchor -Name 'Installers requirements card' -ExpectedMaxWidth 340)
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($installersInformationSharedRightEdge) -eq 'AxisFirstUseWizard.InstallersMixedBidiSafeInfoText') 'AXIS Installers information card should expose the mixed BiDi-safe marker.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($installersRequirementsSharedRightEdge) -eq 'AxisFirstUseWizard.InstallersMixedBidiSafeRequirementsText') 'AXIS Installers requirements card should expose the mixed BiDi-safe marker.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($installersSupportPanel) -eq 'AxisFirstUseWizard.InstallersSupportCardNoClipping') 'AXIS Installers support panel should expose the no-clipping marker.'
Assert-BoostLabCondition ([double]$installersSupportPanel.MinHeight -eq 54.0) 'AXIS Installers support card should use the shared compact no-clipping support height.'
Assert-BoostLabCondition ([double]$installersSupportPanel.Padding.Top -eq 7.0 -and [double]$installersSupportPanel.Padding.Bottom -eq 7.0) 'AXIS Installers support card should use shared compact internal padding without clipping.'
Assert-BoostLabCondition ($installersContentGrid.Children.IndexOf($installersDetailsGrid) -lt $installersContentGrid.Children.IndexOf($installersActionArea)) 'AXIS Installers details must appear before the action row.'
Assert-BoostLabCondition ($installersContentGrid.Children.IndexOf($installersActionArea) -lt $installersContentGrid.Children.IndexOf($installersSupportPanel)) 'AXIS Installers action row must stay separated above the support panel.'
Assert-BoostLabCondition ($installersSelector -is [System.Windows.Controls.ComboBox]) 'AXIS Installers should render a ComboBox selector.'
Assert-BoostLabCondition ([bool]$installersSelectorRow.Resources['AxisFirstUseWizard.InstallersSelectorPhysicalLeftAboveRequirements']) 'AXIS Installers selector should expose the physical-left above-requirements marker.'
[void](Assert-AxisFirstUseWizardSelectorPhysicalLeftAboveRequirements -Row $installersSelectorRow -Selector $installersSelector -Label $installersSelectorLabel -ContentGrid $installersContentGrid -DetailsGrid $installersDetailsGrid -Name 'Installers')
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($installersSelector) -eq 'AxisFirstUseWizard.InstallersSingleSelectCatalogSelector') 'AXIS Installers selector should expose the single-select marker.'
Assert-BoostLabCondition ($installersSelector.Style -eq (Get-AxisWizardSelectorComboBoxStyle)) 'AXIS Installers selector should use the shared AXIS dark selector style.'
Assert-BoostLabCondition ($null -ne $installersSelector.ItemContainerStyle) 'AXIS Installers selector should have a dark item container style for generated dropdown items.'
Assert-BoostLabCondition ([bool]$installersSelector.Resources['AxisFirstUseWizard.SharedDarkSelectorStyle']) 'AXIS Installers selector should carry the shared dark selector marker.'
Assert-BoostLabCondition ([bool]$installersSelector.Resources['AxisFirstUseWizard.InstallersSelectorUsesSharedDarkAxisStyle']) 'AXIS Installers selector should use the shared AXIS selector styling path.'
Assert-BoostLabCondition ([string]$installersSelector.Resources['AxisFirstUseWizard.SelectorPopupNotNativeWhite'] -eq '#121212') 'AXIS Installers selector popup should be marked as non-native-white.'
Assert-BoostLabCondition ([bool]$installersSelector.Resources['AxisFirstUseWizard.SelectorClosedFieldDarkStyle']) 'AXIS Installers closed selector field should use dark AXIS styling.'
Assert-BoostLabCondition ([bool]$installersSelector.Resources['AxisFirstUseWizard.SelectorHoverSelectedStates']) 'AXIS Installers selector should expose hover/selected state styling.'
Assert-BoostLabCondition ([bool]$installersSelector.Resources['AxisFirstUseWizard.FutureGpuBloatwareSelectorStyleReady']) 'AXIS shared selector style should be ready for future GPU/Bloatware selectors.'
Assert-BoostLabCondition ((Get-AxisFirstUseWizardSolidBrushHex -Brush $installersSelector.Background) -ne '#FFFFFFFF') 'AXIS Installers selector background must not be native bright white.'
Assert-BoostLabCondition ((Get-AxisFirstUseWizardSolidBrushHex -Brush $installersSelector.Foreground) -ne '#FF000000') 'AXIS Installers selector text must not use low-contrast native black.'
Assert-BoostLabCondition ([bool]$installersSelector.Resources['AxisFirstUseWizard.InstallersSelectorSingleSelect']) 'AXIS Installers selector should carry the single-select resource marker.'
Assert-BoostLabCondition ([bool]$installersSelector.Resources['AxisFirstUseWizard.InstallersSelectorNoRuntimeAction']) 'AXIS Installers selector should carry the no-runtime-action marker.'
Assert-BoostLabCondition ([string]$installersSelector.Resources['AxisFirstUseWizard.InstallersCatalogSource'] -eq 'modules/Installers/installers.psm1') 'AXIS Installers selector should document the read-only catalog source.'
Assert-BoostLabCondition ($installersSelector.Items.Count -eq ($expectedInstallersCatalogNames.Count + 1)) 'AXIS Installers selector should expose the placeholder plus current retained catalog names.'
Assert-BoostLabCondition ($installersSelector.Items[0] -is [System.Windows.Controls.ComboBoxItem]) 'AXIS Installers selector placeholder should be a ComboBoxItem.'
Assert-BoostLabCondition ([string]$installersSelector.Items[0].Content -eq $arabicInstallersSelectorPlaceholder) 'AXIS Installers selector placeholder changed.'
Assert-BoostLabCondition (-not [bool]$installersSelector.Items[0].IsEnabled) 'AXIS Installers selector placeholder should not count as a selectable program.'
Assert-BoostLabCondition ($null -ne $installersSelector.Items[0].Style) 'AXIS Installers selector placeholder should use the shared dark item style.'
$actualInstallersCatalogNames = @(
    for ($catalogIndex = 1; $catalogIndex -lt $installersSelector.Items.Count; $catalogIndex++) {
        [string]$installersSelector.Items[$catalogIndex].Content
    }
)
Assert-BoostLabCondition (($actualInstallersCatalogNames -join '|') -eq ($expectedInstallersCatalogNames -join '|')) 'AXIS Installers selector items should match the current retained BoostLab installers catalog names.'
foreach ($programItem in @($installersSelector.Items | Select-Object -Skip 1)) {
    Assert-BoostLabCondition ($programItem -is [System.Windows.Controls.ComboBoxItem]) 'AXIS Installers catalog item should be a ComboBoxItem.'
    Assert-BoostLabCondition ($programItem.FlowDirection -eq [System.Windows.FlowDirection]::LeftToRight) "AXIS Installers English app names should render LTR: $($programItem.Content)"
    Assert-BoostLabCondition ($programItem.HorizontalContentAlignment -eq [System.Windows.HorizontalAlignment]::Left) "AXIS Installers English app names should stay visually LTR-aligned inside the selector: $($programItem.Content)"
    Assert-BoostLabCondition ($null -ne $programItem.Style) "AXIS Installers catalog item should use the shared dark dropdown item style: $($programItem.Content)"
}
Assert-BoostLabCondition ([string]$installersPrimaryButton.Content -eq 'Install') 'AXIS Installers primary button should use the owner-approved Install label.'
Assert-BoostLabCondition (-not [bool]$installersPrimaryButton.IsEnabled) 'AXIS Installers Install button should start disabled until a program is selected.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($installersPrimaryButton) -eq 'AxisFirstUseWizard.InstallersInstallDisabledUntilProgramSelected') 'AXIS Installers Install button should expose the disabled-until-selection marker.'
Assert-BoostLabCondition ($installersRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Installers runtime status should start hidden.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($installersRuntimeStatusArea) -eq 'AxisFirstUseWizard.InstallersRuntimeStatusNoClipping') 'AXIS Installers runtime status should expose the no-clipping marker.'
Assert-BoostLabCondition ($installersSelectedProgramDisplay.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Installers selected program display should start hidden.'
Assert-BoostLabCondition ($installersInlineEpicGuidanceBlocks.Count -eq 0) 'AXIS Installers must not render an inline Epic guidance block.'
Assert-BoostLabCondition ($installersInlineEpicCheckboxes.Count -eq 0) 'AXIS Installers must not render an inline Epic checkbox.'
Assert-BoostLabCondition ($installersInlineEpicCheckboxTexts.Count -eq 0) 'AXIS Installers must not render inline Epic checkbox text.'
Assert-BoostLabCondition (-not $installersVisibleText.Contains($arabicInstallersRemovedEpicCheckbox)) 'AXIS Installers visible page must not contain the removed inline Epic checkbox text.'
Assert-BoostLabCondition ($installersEpicInstructionOverlay -is [System.Windows.Controls.Border]) 'AXIS Installers should create a root-level Epic instructional overlay.'
Assert-BoostLabCondition ($installersEpicInstructionOverlay.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Installers Epic instructional overlay should start hidden.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($installersEpicInstructionOverlay) -eq 'AxisFirstUseWizard.InstallersEpicInstructionOverlayNoCheckbox') 'AXIS Installers Epic overlay should expose the no-checkbox marker.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($installersEpicInstructionBodyGroup) -eq 'AxisFirstUseWizard.InstallersEpicInstructionMixedBidiSafeVisualLines') 'AXIS Installers Epic overlay body should expose mixed BiDi-safe visual line rendering.'
Assert-BoostLabCondition ([bool]$installersEpicInstructionBodyGroup.Resources['AxisFirstUseWizard.InstallersEpicInstructionVisualLinesRightAligned']) 'AXIS Installers Epic overlay body should mark right-aligned visual lines.'
Assert-BoostLabCondition ([bool]$installersEpicInstructionBodyGroup.Resources['AxisFirstUseWizard.InstallersEpicInstructionNoOrphanEnglishTokens']) 'AXIS Installers Epic overlay body should guard against orphan English tokens.'
Assert-BoostLabCondition ([bool]$installersEpicInstructionBodyGroup.Resources['AxisFirstUseWizard.InstallersEpicInstructionNoLeftFloatingWrappedArabicLines']) 'AXIS Installers Epic overlay body should guard against left-floating wrapped Arabic lines.'
$installersEpicInstructionOverlayText = (Get-AxisFirstUseWizardTextValues -Root $installersEpicInstructionOverlay) -join [Environment]::NewLine
foreach ($requiredEpicInstructionText in @($arabicInstallersEpicOverlayTitle, 'Install', $arabicInstallersEpicOverlayReturn)) {
    Assert-BoostLabCondition ($installersEpicInstructionOverlayText.Contains($requiredEpicInstructionText)) "AXIS Installers Epic instructional overlay is missing owner-approved text: $requiredEpicInstructionText"
}
Assert-BoostLabCondition (-not $installersEpicInstructionOverlayText.Contains([string][char]0xFFFD)) 'AXIS Installers Epic overlay text must not contain replacement glyphs.'
Assert-BoostLabCondition ([string](Get-AxisFirstUseWizardTextBlockPlainText -TextBlock $installersEpicInstructionTitle) -eq $arabicInstallersEpicOverlayTitle) 'AXIS Installers Epic overlay title changed.'
Assert-BoostLabCondition ($installersEpicInstructionBodyItems.Count -eq 3) 'AXIS Installers Epic overlay should render exactly three instruction groups.'
Assert-BoostLabCondition ($installersEpicInstructionBodyVisualLines.Count -eq 5) 'AXIS Installers Epic overlay should render body copy as five explicit visual lines.'
$expectedEpicInstructionBodies = @(
    $arabicInstallersEpicOverlayBody1
    $arabicInstallersEpicOverlayBody2
    $arabicInstallersEpicOverlayBody3
)
for ($epicInstructionIndex = 0; $epicInstructionIndex -lt $expectedEpicInstructionBodies.Count; $epicInstructionIndex++) {
    $epicInstructionItemText = (Get-AxisFirstUseWizardTextValues -Root $installersEpicInstructionBodyItems[$epicInstructionIndex]) -join ' '
    Assert-BoostLabCondition (
        (ConvertTo-AxisFirstUseWizardNormalizedText -Text $epicInstructionItemText) -eq
        (ConvertTo-AxisFirstUseWizardNormalizedText -Text $expectedEpicInstructionBodies[$epicInstructionIndex])
    ) "AXIS Installers Epic overlay visual line group should preserve approved body text at index $epicInstructionIndex."
}
foreach ($epicInstructionVisualLine in $installersEpicInstructionBodyVisualLines) {
    $epicInstructionVisualLineText = Get-AxisFirstUseWizardTextBlockPlainText -TextBlock $epicInstructionVisualLine
    Assert-BoostLabCondition ($epicInstructionVisualLine.TextWrapping -eq [System.Windows.TextWrapping]::NoWrap) 'AXIS Installers Epic overlay visual lines should not rely on WPF wrapping.'
    Assert-BoostLabCondition ($epicInstructionVisualLine.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) 'AXIS Installers Epic overlay visual lines should be physically right-aligned.'
    Assert-BoostLabCondition ($epicInstructionVisualLine.TextAlignment -eq [System.Windows.TextAlignment]::Right) 'AXIS Installers Epic overlay visual line text should be right-aligned.'
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($epicInstructionVisualLine) -eq 'AxisFirstUseWizard.InstallersEpicInstructionRightAlignedNoWrapMixedBidiLine') 'AXIS Installers Epic overlay visual lines should use the no-wrap mixed BiDi renderer.'
    Assert-BoostLabCondition (-not ([regex]::IsMatch($epicInstructionVisualLineText, '^(Launcher|Games|Epic Games|Epic Games Launcher)$'))) "AXIS Installers Epic overlay should not orphan an English token on its own visual line: $epicInstructionVisualLineText"
}
Assert-BoostLabCondition ([string]$installersEpicInstructionInstallButton.Content -eq 'Install') 'AXIS Installers Epic overlay primary button should be Install.'
Assert-BoostLabCondition ([string]$installersEpicInstructionReturnButton.Content -eq $arabicInstallersEpicOverlayReturn) 'AXIS Installers Epic overlay return button changed.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $installersEpicInstructionOverlay -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgement').Count -eq 0) 'AXIS Installers Epic overlay must not include a checkbox.'
Assert-BoostLabCondition (-not $installersEpicInstructionOverlayText.Contains('Cancel')) 'AXIS Installers Epic overlay must not include a Cancel button.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.ConfirmationOverlay').Count -eq 0) 'AXIS Installers content must not include a confirmation overlay.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $installersVisibleContent -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgement').Count -eq 0) 'AXIS Installers content must not include a confirmation checkbox overlay.'
Invoke-AxisFirstUseWizardButtonClick -Button $installersPrimaryButton
Assert-BoostLabCondition ($installersRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Installers disabled Install button must not start simulation before a program is selected.'
Assert-BoostLabCondition ($installersEpicInstructionOverlay.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Installers disabled Install button must not open the Epic overlay before a program is selected.'

$discordSelectorIndex = [Array]::IndexOf($actualInstallersCatalogNames, 'Discord') + 1
$epicSelectorIndex = [Array]::IndexOf($actualInstallersCatalogNames, 'Epic Games') + 1
Assert-BoostLabCondition ($discordSelectorIndex -gt 0) 'AXIS Installers selector should include Discord from the retained catalog.'
Assert-BoostLabCondition ($epicSelectorIndex -gt 0) 'AXIS Installers selector should include Epic Games from the retained catalog.'
$installersSelector.SelectedIndex = $epicSelectorIndex
Assert-BoostLabCondition ([bool]$installersPrimaryButton.IsEnabled) 'AXIS Installers Install button should enable after Epic Games is selected.'
Assert-AxisFirstUseWizardNextDisabledNonBlue -Button $taggedContinueButtons[0] -Name 'Installers after Epic Games selector selection'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($installersPrimaryButton) -eq 'AxisFirstUseWizard.InstallersInstallEnabledWithProgramSelection') 'AXIS Installers enabled Install button should expose the selected-program marker.'
Assert-BoostLabCondition ($installersSelectedProgramDisplay.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS Installers selected program micro-row should remain visible for Epic Games like any other app.'
Assert-BoostLabCondition ([string]$installersSelectedProgramName.Text -eq 'Epic Games') 'AXIS Installers selected app display should show the selected Epic catalog item.'
Assert-BoostLabCondition ([string]$installersSelectedProgramPrefix.Text -eq $arabicInstallersSelectedProgramPrefix) 'AXIS Installers selected app display prefix changed.'
Assert-BoostLabCondition ([bool]$installersPrimaryButton.Resources['AxisFirstUseWizard.InstallersEpicSelected']) 'AXIS Installers should mark Epic Games as the overlay-gated selection.'
Assert-BoostLabCondition ($installersEpicInstructionOverlay.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Installers Epic overlay should remain hidden until the main Install button is pressed.'
Invoke-AxisFirstUseWizardButtonClick -Button $installersPrimaryButton
Assert-BoostLabCondition ($installersEpicInstructionOverlay.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS Installers Epic overlay should open after pressing Install with Epic Games selected.'
Assert-BoostLabCondition ($installersRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Installers Epic overlay should not start simulation before overlay Install is pressed.'
Assert-BoostLabCondition ($installersRuntimeStatusSpacer.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Installers Epic overlay should not show runtime spacing before overlay Install is pressed.'
Assert-BoostLabCondition (-not [bool]$taggedContinueButtons[0].IsEnabled) 'AXIS Installers Continue/Next should remain disabled while the Epic overlay is informational.'
Invoke-AxisFirstUseWizardButtonClick -Button $installersEpicInstructionReturnButton
Assert-BoostLabCondition ($installersEpicInstructionOverlay.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Installers Epic overlay return button should close the overlay only.'
Assert-BoostLabCondition ($installersRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Installers Epic overlay return should not start the simulated install.'

$installersStepElement.Measure([System.Windows.Size]::new(826.0, 389.0))
$installersRowTotal = 0.0
foreach ($installersRowChild in @($installersContentGrid.Children)) {
    $installersRowChild.Measure([System.Windows.Size]::new(758.0, [double]::PositiveInfinity))
    $installersRowTotal += [double]$installersRowChild.DesiredSize.Height
}
$installersInnerHeight = [double]$installersStepElement.Height -
    [double]$installersStepElement.Padding.Top -
    [double]$installersStepElement.Padding.Bottom -
    [double]$installersStepElement.BorderThickness.Top -
    [double]$installersStepElement.BorderThickness.Bottom
Assert-BoostLabCondition ($installersRowTotal -le $installersInnerHeight) 'AXIS Installers row content should fit inside the card without support clipping.'

Invoke-AxisFirstUseWizardButtonClick -Button $installersPrimaryButton
Assert-BoostLabCondition ($installersEpicInstructionOverlay.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS Installers Epic overlay should open again from the main Install button.'
Invoke-AxisFirstUseWizardButtonClick -Button $installersEpicInstructionInstallButton
Assert-BoostLabCondition ($installersEpicInstructionOverlay.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Installers Epic overlay Install should close the overlay before simulation.'
Assert-BoostLabCondition ($installersRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS Installers runtime status should become visible during simulated install.'
Assert-BoostLabCondition ($installersRuntimeStatusSpacer.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS Installers runtime status spacer should become visible during simulation.'
Assert-BoostLabCondition (-not [bool]$taggedContinueButtons[0].IsEnabled) 'AXIS Installers Continue/Next should remain disabled during simulated install.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $installersRuntimeStatusArea -Tag 'AxisFirstUseWizard.CheckingAnimation').Count -eq 1) 'AXIS Installers simulated flow should use the runtime checking animation.'
$installersRunningText = (Get-AxisFirstUseWizardTextValues -Root $installersVisibleContent) -join [Environment]::NewLine
Assert-BoostLabCondition ($installersRunningText.Contains($arabicInstallersRunning)) 'AXIS Installers simulated flow should show the owner-approved running state.'
Assert-BoostLabCondition ($installersRunningText.Contains($arabicSupportBody)) 'AXIS Installers support panel should remain visible during the simulated flow.'
$installersRunningRuntimeStatusRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $installersRuntimeStatusArea -Tag 'AxisFirstUseWizard.RuntimeStatusArabicRightAnchor')
Assert-BoostLabCondition ($installersRunningRuntimeStatusRightAnchor.Count -eq 1) 'AXIS Installers running status should keep text near the action row.'
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $installersRunningRuntimeStatusRightAnchor[0] -Name 'Installers running runtime status' -ExpectedMaxWidth 110)
Assert-BoostLabCondition (Wait-AxisFirstUseWizardCondition -Condition { [bool]$taggedContinueButtons[0].IsEnabled } -TimeoutMilliseconds 3000) 'AXIS Installers simulated flow should enable Continue/Next after completion.'
$installersCompletedText = (Get-AxisFirstUseWizardTextValues -Root $installersVisibleContent) -join [Environment]::NewLine
Assert-BoostLabCondition ($installersCompletedText.Contains($arabicInstallersCompleted)) 'AXIS Installers simulated flow should end in the owner-approved completed state.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $installersRuntimeStatusArea -Tag 'AxisFirstUseWizard.CompletedEffect').Count -eq 1) 'AXIS Installers completed state should render the completed runtime effect.'
$installersCompletedRuntimeStatusRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $installersRuntimeStatusArea -Tag 'AxisFirstUseWizard.RuntimeStatusArabicRightAnchor')
Assert-BoostLabCondition ($installersCompletedRuntimeStatusRightAnchor.Count -eq 1) 'AXIS Installers completed status should keep text near the action row.'
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $installersCompletedRuntimeStatusRightAnchor[0] -Name 'Installers completed runtime status' -ExpectedMaxWidth 110)
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($taggedContinueButtons[0]) -eq 'AxisFirstUseWizard.EnabledNextButtonBlue') 'AXIS Installers Continue/Next should become blue after simulated completion.'
Assert-BoostLabCondition ([string]([System.Windows.Media.SolidColorBrush]$taggedContinueButtons[0].Background).Color -eq '#FF2563EB') 'AXIS Installers enabled Continue/Next should use the approved blue fill.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $taggedContentHost[0].Child -Tag 'AxisFirstUseWizard.InstallersStep').Count -eq 1) 'AXIS Installers should not auto-advance after simulated completion.'

$nonEpicInstallersSampleState = Get-AxisFirstUseWizardSampleState
$nonEpicStepIds = @($nonEpicInstallersSampleState['Steps'] | ForEach-Object { [string]$_['Id'] })
$nonEpicInstallersIndex = [Array]::IndexOf($nonEpicStepIds, 'installers')
Assert-BoostLabCondition ($nonEpicInstallersIndex -ge 0) 'AXIS Installers non-Epic regression guard should find the Installers step.'
$nonEpicInstallersSampleState['CurrentStepIndex'] = $nonEpicInstallersIndex
$nonEpicInstallersPrototype = New-AxisFirstUseWizardPrototype -SampleState $nonEpicInstallersSampleState
$nonEpicInstallersContentHost = @(Get-AxisFirstUseWizardTaggedElements -Root $nonEpicInstallersPrototype -Tag 'AxisFirstUseWizard.StepContentHost') | Select-Object -First 1
$nonEpicInstallersContinueButton = @(Get-AxisFirstUseWizardTaggedElements -Root $nonEpicInstallersPrototype -Tag 'AxisFirstUseWizard.ContinueButton') | Select-Object -First 1
$nonEpicInstallersContent = $nonEpicInstallersContentHost.Child
$nonEpicInstallersSelector = @(Get-AxisFirstUseWizardTaggedElements -Root $nonEpicInstallersContent -Tag 'AxisFirstUseWizard.InstallersProgramSelector') | Select-Object -First 1
$nonEpicInstallersPrimaryButton = @(Get-AxisFirstUseWizardTaggedElements -Root $nonEpicInstallersContent -Tag 'AxisFirstUseWizard.PrimaryOpenButton') | Select-Object -First 1
$nonEpicInstallersRuntimeStatusArea = @(Get-AxisFirstUseWizardTaggedElements -Root $nonEpicInstallersContent -Tag 'AxisFirstUseWizard.RuntimeStatusArea') | Select-Object -First 1
$nonEpicInstallersEpicOverlay = @(Get-AxisFirstUseWizardTaggedElements -Root $nonEpicInstallersPrototype -Tag 'AxisFirstUseWizard.InstallersEpicInstructionOverlay') | Select-Object -First 1
$nonEpicActualInstallersCatalogNames = @(
    for ($catalogIndex = 1; $catalogIndex -lt $nonEpicInstallersSelector.Items.Count; $catalogIndex++) {
        [string]$nonEpicInstallersSelector.Items[$catalogIndex].Content
    }
)
$nonEpicDiscordSelectorIndex = [Array]::IndexOf($nonEpicActualInstallersCatalogNames, 'Discord') + 1
Assert-BoostLabCondition ($nonEpicDiscordSelectorIndex -gt 0) 'AXIS Installers non-Epic regression guard should include Discord.'
$nonEpicInstallersSelector.SelectedIndex = $nonEpicDiscordSelectorIndex
Assert-BoostLabCondition (-not [bool]$nonEpicInstallersPrimaryButton.Resources['AxisFirstUseWizard.InstallersEpicSelected']) 'AXIS Installers should not mark non-Epic apps as Epic overlay selections.'
Assert-AxisFirstUseWizardNextDisabledNonBlue -Button $nonEpicInstallersContinueButton -Name 'Installers after non-Epic selector selection'
Invoke-AxisFirstUseWizardButtonClick -Button $nonEpicInstallersPrimaryButton
Assert-BoostLabCondition ($nonEpicInstallersEpicOverlay.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Installers non-Epic app should not show the Epic instructional overlay.'
Assert-BoostLabCondition ($nonEpicInstallersRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS Installers non-Epic app should start simulated install directly.'
Assert-BoostLabCondition (Wait-AxisFirstUseWizardCondition -Condition { [bool]$nonEpicInstallersContinueButton.IsEnabled } -TimeoutMilliseconds 3000) 'AXIS Installers non-Epic direct simulation should still complete.'

Invoke-AxisFirstUseWizardButtonClick -Button $taggedContinueButtons[0]
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $taggedContentHost[0].Child -Tag 'AxisFirstUseWizard.InstallersStartupAppsSettingsStep').Count -eq 1) 'AXIS Installers Continue/Next should navigate to the Installers Startup Apps Settings extension step.'

Invoke-AxisFirstUseWizardButtonClick -Button $taggedBackButtons[0]
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $taggedContentHost[0].Child -Tag 'AxisFirstUseWizard.InstallersStep').Count -eq 1) 'AXIS Back from Installers Startup Apps Settings should return to Installers.'
Invoke-AxisFirstUseWizardButtonClick -Button $taggedBackButtons[0]
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $taggedContentHost[0].Child -Tag 'AxisFirstUseWizard.SetupUpdatesPauseStep').Count -eq 1) 'AXIS Back from Installers should return to Updates Pause.'
Invoke-AxisFirstUseWizardButtonClick -Button $taggedBackButtons[0]
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $taggedContentHost[0].Child -Tag 'AxisFirstUseWizard.SetupStoreSettingsStep').Count -eq 1) 'AXIS Back from Updates Pause should return to Store Settings.'

foreach ($extensionSpec in $installersExtensionStepSpecs) {
    $extensionStepId = [string]$extensionSpec['Id']
    $extensionTagRoot = [string]$extensionSpec['TagRoot']
    $extensionSampleState = Get-AxisFirstUseWizardSampleState
    $extensionStepIds = @($extensionSampleState['Steps'] | ForEach-Object { [string]$_['Id'] })
    $extensionStepIndex = [Array]::IndexOf($extensionStepIds, $extensionStepId)
    Assert-BoostLabCondition ($extensionStepIndex -ge 0) "AXIS extension render test should find step: $extensionStepId"
    $extensionSampleState['CurrentStepIndex'] = $extensionStepIndex
    $extensionPrototype = New-AxisFirstUseWizardPrototype -SampleState $extensionSampleState
    $extensionContentHost = @(Get-AxisFirstUseWizardTaggedElements -Root $extensionPrototype -Tag 'AxisFirstUseWizard.StepContentHost') | Select-Object -First 1
    $extensionContinueButton = @(Get-AxisFirstUseWizardTaggedElements -Root $extensionPrototype -Tag 'AxisFirstUseWizard.ContinueButton') | Select-Object -First 1
    $extensionVisibleContent = $extensionContentHost.Child
    $extensionStepElement = @(Get-AxisFirstUseWizardTaggedElements -Root $extensionVisibleContent -Tag "AxisFirstUseWizard.${extensionTagRoot}Step") | Select-Object -First 1
    $extensionTitleText = @(Get-AxisFirstUseWizardTaggedElements -Root $extensionVisibleContent -Tag "AxisFirstUseWizard.${extensionTagRoot}TitleText") | Select-Object -First 1
    $extensionDetailsGrid = @(Get-AxisFirstUseWizardTaggedElements -Root $extensionVisibleContent -Tag "AxisFirstUseWizard.${extensionTagRoot}StepDetails") | Select-Object -First 1
    $extensionInformationCard = @(Get-AxisFirstUseWizardTaggedElements -Root $extensionVisibleContent -Tag "AxisFirstUseWizard.${extensionTagRoot}InformationCard") | Select-Object -First 1
    $extensionRequirementsCard = @(Get-AxisFirstUseWizardTaggedElements -Root $extensionVisibleContent -Tag "AxisFirstUseWizard.${extensionTagRoot}RequirementsCard") | Select-Object -First 1
    $extensionInformationSharedRightEdge = @(Get-AxisFirstUseWizardTaggedElements -Root $extensionVisibleContent -Tag "AxisFirstUseWizard.${extensionTagRoot}InformationSharedPhysicalRightEdge") | Select-Object -First 1
    $extensionSupportPanel = @(Get-AxisFirstUseWizardTaggedElements -Root $extensionVisibleContent -Tag 'AxisFirstUseWizard.SupportPanel') | Select-Object -First 1
    $extensionRuntimeStatusArea = @(Get-AxisFirstUseWizardTaggedElements -Root $extensionVisibleContent -Tag 'AxisFirstUseWizard.RuntimeStatusArea') | Select-Object -First 1
    $extensionRuntimeStatusSpacer = @(Get-AxisFirstUseWizardTaggedElements -Root $extensionVisibleContent -Tag 'AxisFirstUseWizard.ActionRuntimeStatusSpacer') | Select-Object -First 1
    $extensionPrimaryButton = @(Get-AxisFirstUseWizardTaggedElements -Root $extensionVisibleContent -Tag 'AxisFirstUseWizard.PrimaryOpenButton') | Select-Object -First 1
    $extensionVisibleText = (Get-AxisFirstUseWizardTextValues -Root $extensionVisibleContent) -join [Environment]::NewLine

    Assert-BoostLabCondition ($extensionStepElement -is [System.Windows.Controls.Border]) "AXIS Installers extension should render a step card: $extensionStepId"
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($extensionStepElement) -eq 'AxisFirstUseWizard.InstallersStageExtensionPrototypeOnly') "AXIS Installers extension should expose prototype-only automation marker: $extensionStepId"
    Assert-BoostLabCondition ([string](Get-AxisFirstUseWizardTextBlockPlainText -TextBlock $extensionTitleText) -eq [string]$extensionSpec['Title']) "AXIS Installers extension visible title changed: $extensionStepId"
    Assert-BoostLabCondition ([string]$extensionPrimaryButton.Content -eq [string]$extensionSpec['Primary']) "AXIS Installers extension primary button text changed: $extensionStepId"
    Assert-BoostLabCondition (-not [bool]$extensionContinueButton.IsEnabled) "AXIS Installers extension Next should start disabled until simulated completion: $extensionStepId"
    Assert-BoostLabCondition ($extensionRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) "AXIS Installers extension runtime status should start hidden: $extensionStepId"
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($extensionRuntimeStatusArea) -eq 'AxisFirstUseWizard.InstallersRuntimeStatusNoClipping') "AXIS Installers extension runtime status should expose no-clipping marker: $extensionStepId"
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($extensionSupportPanel) -eq 'AxisFirstUseWizard.InstallersSupportCardNoClipping') "AXIS Installers extension support panel should expose the no-clipping marker: $extensionStepId"
    Assert-BoostLabCondition ([double]$extensionSupportPanel.MinHeight -eq 54.0) "AXIS Installers extension support panel should use compact no-clipping height: $extensionStepId"
    Assert-BoostLabCondition ($extensionVisibleText.Contains($arabicSupportTitle) -and $extensionVisibleText.Contains($arabicSupportBody)) "AXIS Installers extension support card should remain visible: $extensionStepId"
    Assert-BoostLabCondition (-not $extensionVisibleText.Contains([string][char]0xFFFD)) "AXIS Installers extension visible copy must not contain replacement glyphs: $extensionStepId"
    Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $extensionVisibleContent -Tag 'AxisFirstUseWizard.ConfirmationOverlay').Count -eq 0) "AXIS Installers extension content must not include a confirmation overlay: $extensionStepId"
    Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $extensionVisibleContent -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgement').Count -eq 0) "AXIS Installers extension content must not include a confirmation checkbox: $extensionStepId"
    Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $extensionVisibleContent -Tag 'AxisFirstUseWizard.AutoUnattendInputOverlay').Count -eq 0) "AXIS Installers extension content must not include an input overlay: $extensionStepId"
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($extensionInformationSharedRightEdge) -eq "AxisFirstUseWizard.${extensionTagRoot}MixedBidiSafeInfoText") "AXIS Installers extension information card should use mixed BiDi-safe text grouping: $extensionStepId"

    if (@($extensionSpec['Requirements']).Count -gt 0) {
        Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($extensionDetailsGrid) -eq 'AxisFirstUseWizard.InstallersExtensionCardsPhysicalOrderInfoRightRequirementsLeft') "AXIS Installers extension should mark physical info-right requirements-left order: $extensionStepId"
        Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($extensionInformationCard) -eq 2) "AXIS Installers extension information card should be physical right: $extensionStepId"
        Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($extensionRequirementsCard) -eq 0) "AXIS Installers extension requirements card should be physical left: $extensionStepId"
    }
    else {
        Assert-BoostLabCondition ($null -eq $extensionRequirementsCard) "AXIS Installers extension restart step must not render a requirements card: $extensionStepId"
        Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($extensionInformationCard) -eq 0) "AXIS Installers extension single information card should use the only details column: $extensionStepId"
    }

    Invoke-AxisFirstUseWizardButtonClick -Button $extensionPrimaryButton
    Assert-BoostLabCondition ($extensionRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Visible) "AXIS Installers extension simulated action should show runtime status: $extensionStepId"
    Assert-BoostLabCondition ($extensionRuntimeStatusSpacer.Visibility -eq [System.Windows.Visibility]::Visible) "AXIS Installers extension runtime spacer should be visible during simulation: $extensionStepId"
    $extensionRunningText = (Get-AxisFirstUseWizardTextValues -Root $extensionVisibleContent) -join [Environment]::NewLine
    Assert-BoostLabCondition ($extensionRunningText.Contains([string]$extensionSpec['Running'])) "AXIS Installers extension should show owner-approved running status: $extensionStepId"
    Assert-BoostLabCondition ($extensionRunningText.Contains($arabicSupportBody)) "AXIS Installers extension support panel should remain visible during simulation: $extensionStepId"
    Assert-BoostLabCondition (Wait-AxisFirstUseWizardCondition -Condition { [bool]$extensionContinueButton.IsEnabled } -TimeoutMilliseconds 3000) "AXIS Installers extension should enable Next after simulated completion: $extensionStepId"
    $extensionCompletedText = (Get-AxisFirstUseWizardTextValues -Root $extensionVisibleContent) -join [Environment]::NewLine
    Assert-BoostLabCondition ($extensionCompletedText.Contains([string]$extensionSpec['Completed'])) "AXIS Installers extension should end in owner-approved completed status: $extensionStepId"
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($extensionContinueButton) -eq 'AxisFirstUseWizard.EnabledNextButtonBlue') "AXIS Installers extension Next should become blue after simulated completion: $extensionStepId"

    if ($extensionStepId -eq 'restart-after-installers') {
        Invoke-AxisFirstUseWizardButtonClick -Button $extensionContinueButton
        $extensionGraphicsStageHeader = @(Get-AxisFirstUseWizardTaggedElements -Root $extensionPrototype -Tag 'AxisFirstUseWizard.CurrentStageHeader') | Select-Object -First 1
        $extensionCheckFill = @(Get-AxisFirstUseWizardTaggedElements -Root $extensionPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Check') | Select-Object -First 1
        $extensionRefreshFill = @(Get-AxisFirstUseWizardTaggedElements -Root $extensionPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Refresh') | Select-Object -First 1
        $extensionSetupFill = @(Get-AxisFirstUseWizardTaggedElements -Root $extensionPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Setup') | Select-Object -First 1
        $extensionInstallersFill = @(Get-AxisFirstUseWizardTaggedElements -Root $extensionPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Installers') | Select-Object -First 1
        $extensionGraphicsFill = @(Get-AxisFirstUseWizardTaggedElements -Root $extensionPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Graphics') | Select-Object -First 1
        Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $extensionContentHost.Child -Tag 'AxisFirstUseWizard.GraphicsDriverCleanStep').Count -eq 1) 'AXIS restart-after-installers Continue/Next should navigate to Driver Clean.'
        Assert-BoostLabCondition ([string]$extensionGraphicsStageHeader.Text -eq 'Graphics') 'AXIS Driver Clean current stage header should show Graphics.'
        [void](Assert-AxisFirstUseWizardStageLineState -Fill $extensionCheckFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Check' -ExpectedColor '#FF22C55E' -Name 'Driver Clean Check completed')
        [void](Assert-AxisFirstUseWizardStageLineState -Fill $extensionRefreshFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Refresh' -ExpectedColor '#FF22C55E' -Name 'Driver Clean Refresh completed')
        [void](Assert-AxisFirstUseWizardStageLineState -Fill $extensionSetupFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Setup' -ExpectedColor '#FF22C55E' -Name 'Driver Clean Setup completed')
        [void](Assert-AxisFirstUseWizardStageLineState -Fill $extensionInstallersFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Installers' -ExpectedColor '#FF22C55E' -Name 'Driver Clean Installers completed')
        [void](Assert-AxisFirstUseWizardStageLineState -Fill $extensionGraphicsFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineActiveFullWhite.Graphics' -ExpectedColor '#FFF0F2F5' -Name 'Driver Clean Graphics active')
    }
}

foreach ($graphicsSpec in $graphicsStepSpecs) {
    $graphicsStepId = [string]$graphicsSpec['Id']
    $graphicsTagRoot = [string]$graphicsSpec['TagRoot']
    $graphicsSampleState = Get-AxisFirstUseWizardSampleState
    $graphicsStepIds = @($graphicsSampleState['Steps'] | ForEach-Object { [string]$_['Id'] })
    $graphicsStepIndex = [Array]::IndexOf($graphicsStepIds, $graphicsStepId)
    Assert-BoostLabCondition ($graphicsStepIndex -ge 0) "AXIS Graphics render test should find step: $graphicsStepId"
    $graphicsSampleState['CurrentStepIndex'] = $graphicsStepIndex
    $graphicsPrototype = New-AxisFirstUseWizardPrototype -SampleState $graphicsSampleState
    $graphicsContentHost = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsPrototype -Tag 'AxisFirstUseWizard.StepContentHost') | Select-Object -First 1
    $graphicsContinueButton = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsPrototype -Tag 'AxisFirstUseWizard.ContinueButton') | Select-Object -First 1
    $graphicsOptionalContinuationButton = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsPrototype -Tag 'AxisFirstUseWizard.OptionalContinuationButton') | Select-Object -First 1
    $graphicsVisibleContent = $graphicsContentHost.Child
    $graphicsVisibleText = (Get-AxisFirstUseWizardTextValues -Root $graphicsVisibleContent) -join [Environment]::NewLine
    $graphicsStepElement = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsVisibleContent -Tag "AxisFirstUseWizard.${graphicsTagRoot}Step") | Select-Object -First 1
    $graphicsTitleText = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsVisibleContent -Tag "AxisFirstUseWizard.${graphicsTagRoot}TitleText") | Select-Object -First 1
    $graphicsDetailsGrid = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsVisibleContent -Tag "AxisFirstUseWizard.${graphicsTagRoot}StepDetails") | Select-Object -First 1
    $graphicsInformationCard = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsVisibleContent -Tag "AxisFirstUseWizard.${graphicsTagRoot}InformationCard") | Select-Object -First 1
    $graphicsRequirementsCard = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsVisibleContent -Tag "AxisFirstUseWizard.${graphicsTagRoot}RequirementsCard") | Select-Object -First 1
    $graphicsInformationSharedRightEdge = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsVisibleContent -Tag "AxisFirstUseWizard.${graphicsTagRoot}InformationSharedPhysicalRightEdge") | Select-Object -First 1
    $graphicsRequirementsSharedRightEdge = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsVisibleContent -Tag "AxisFirstUseWizard.${graphicsTagRoot}RequirementsSharedPhysicalRightEdge") | Select-Object -First 1
    $graphicsPrimaryButton = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsVisibleContent -Tag 'AxisFirstUseWizard.PrimaryOpenButton') | Select-Object -First 1
    $graphicsRuntimeStatusArea = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsVisibleContent -Tag 'AxisFirstUseWizard.RuntimeStatusArea') | Select-Object -First 1
    $graphicsRuntimeStatusSpacer = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsVisibleContent -Tag 'AxisFirstUseWizard.ActionRuntimeStatusSpacer') | Select-Object -First 1
    $graphicsSupportPanel = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsVisibleContent -Tag 'AxisFirstUseWizard.SupportPanel') | Select-Object -First 1
    $graphicsDocumentationButton = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsVisibleContent -Tag 'AxisFirstUseWizard.DocumentationButton') | Select-Object -First 1
    $graphicsStageHeader = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsPrototype -Tag 'AxisFirstUseWizard.CurrentStageHeader') | Select-Object -First 1
    $graphicsCheckFill = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Check') | Select-Object -First 1
    $graphicsRefreshFill = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Refresh') | Select-Object -First 1
    $graphicsSetupFill = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Setup') | Select-Object -First 1
    $graphicsInstallersFill = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Installers') | Select-Object -First 1
    $graphicsGraphicsFill = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Graphics') | Select-Object -First 1

    Assert-BoostLabCondition ($graphicsStepElement -is [System.Windows.Controls.Border]) "AXIS Graphics step should render a step card: $graphicsStepId"
    Assert-BoostLabCondition ([double]$graphicsStepElement.Height -eq 382.0) "AXIS Graphics step should fit inside the 900x650 preview client area: $graphicsStepId"
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($graphicsStepElement) -eq 'AxisFirstUseWizard.GraphicsStageBatchPrototypeOnly') "AXIS Graphics step should expose prototype-only batch marker: $graphicsStepId"
    Assert-BoostLabCondition ([string](Get-AxisFirstUseWizardTextBlockPlainText -TextBlock $graphicsTitleText) -eq [string]$graphicsSpec['Title']) "AXIS Graphics visible title changed: $graphicsStepId"
    Assert-BoostLabCondition ($graphicsTitleText.FlowDirection -eq [System.Windows.FlowDirection]::LeftToRight) "AXIS Graphics English title should render LTR while right-anchored: $graphicsStepId"
    Assert-BoostLabCondition ([string]$graphicsPrimaryButton.Content -eq [string]$graphicsSpec['Primary']) "AXIS Graphics primary button text changed: $graphicsStepId"
    Assert-BoostLabCondition (-not [bool]$graphicsContinueButton.IsEnabled) "AXIS Graphics Next should start disabled until simulated completion: $graphicsStepId"
    Assert-BoostLabCondition ($graphicsRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) "AXIS Graphics runtime status should start hidden: $graphicsStepId"
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($graphicsRuntimeStatusArea) -eq 'AxisFirstUseWizard.GraphicsRuntimeStatusNoClipping') "AXIS Graphics runtime status should expose no-clipping marker: $graphicsStepId"
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($graphicsSupportPanel) -eq 'AxisFirstUseWizard.GraphicsSupportCardNoClipping') "AXIS Graphics support panel should expose no-clipping marker: $graphicsStepId"
    Assert-BoostLabCondition ([double]$graphicsSupportPanel.MinHeight -eq 52.0) "AXIS Graphics support panel should use compact no-clipping height: $graphicsStepId"
    Assert-BoostLabCondition ([double]$graphicsSupportPanel.Padding.Top -eq 6.0 -and [double]$graphicsSupportPanel.Padding.Bottom -eq 6.0) "AXIS Graphics support panel should keep compact internal padding: $graphicsStepId"
    Assert-BoostLabCondition ([double]$graphicsSupportPanel.Margin.Top -eq 4.0) "AXIS Graphics support panel should avoid bottom clipping with a compact top margin: $graphicsStepId"
    Assert-BoostLabCondition ([string]$graphicsStageHeader.Text -eq 'Graphics') "AXIS Graphics current stage header should show Graphics: $graphicsStepId"
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $graphicsCheckFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Check' -ExpectedColor '#FF22C55E' -Name "$graphicsStepId Check completed")
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $graphicsRefreshFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Refresh' -ExpectedColor '#FF22C55E' -Name "$graphicsStepId Refresh completed")
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $graphicsSetupFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Setup' -ExpectedColor '#FF22C55E' -Name "$graphicsStepId Setup completed")
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $graphicsInstallersFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Installers' -ExpectedColor '#FF22C55E' -Name "$graphicsStepId Installers completed")
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $graphicsGraphicsFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineActiveFullWhite.Graphics' -ExpectedColor '#FFF0F2F5' -Name "$graphicsStepId Graphics active")

    foreach ($requiredGraphicsText in @(
        'Graphics'
        [string]$graphicsSpec['Title']
        [string]$graphicsSpec['Subtitle']
        [string]$graphicsSpec['InfoTitle']
        @($graphicsSpec['InfoItems'])
        @($graphicsSpec['Requirements'])
        [string]$graphicsSpec['Primary']
        $arabicDocumentation
        $arabicSupportTitle
        $arabicSupportBody
    )) {
        foreach ($requiredGraphicsTextItem in @($requiredGraphicsText)) {
            if ([string]::IsNullOrWhiteSpace([string]$requiredGraphicsTextItem)) {
                continue
            }
            $requiredGraphicsTextNormalized = ConvertTo-AxisFirstUseWizardNormalizedText -Text ([string]$requiredGraphicsTextItem)
            $graphicsVisibleTextNormalized = ConvertTo-AxisFirstUseWizardNormalizedText -Text $graphicsVisibleText
            Assert-BoostLabCondition (
                $graphicsVisibleText.Contains([string]$requiredGraphicsTextItem) -or
                $graphicsVisibleTextNormalized.Contains($requiredGraphicsTextNormalized)
            ) "AXIS Graphics view is missing owner-approved text for ${graphicsStepId}: $requiredGraphicsTextItem"
        }
    }
    Assert-BoostLabCondition (-not $graphicsVisibleText.Contains([string][char]0xFFFD)) "AXIS Graphics visible copy must not contain replacement glyphs: $graphicsStepId"
    foreach ($forbiddenGraphicsVisibleText in @('Analyze', 'Apply', 'Default', 'Restore', 'Cancel', 'Skip', 'Skipped', 'Completed with notes')) {
        Assert-BoostLabCondition (-not $graphicsVisibleText.Contains($forbiddenGraphicsVisibleText)) "AXIS Graphics view exposes forbidden customer text for ${graphicsStepId}: $forbiddenGraphicsVisibleText"
    }
    Assert-BoostLabCondition ($graphicsRuntimeStatusArea -ne $graphicsSupportPanel) "AXIS Graphics runtime status must remain separate from support panel: $graphicsStepId"
    Assert-BoostLabCondition ($null -ne $graphicsDocumentationButton) "AXIS Graphics documentation button is missing: $graphicsStepId"
    Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $graphicsVisibleContent -Tag 'AxisFirstUseWizard.AutoUnattendInputOverlay').Count -eq 0) "AXIS Graphics content must not include an input overlay: $graphicsStepId"
    Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTypedElements -Root $graphicsVisibleContent -Type ([System.Windows.Controls.Image])).Count -eq 0) "AXIS Graphics content must not render image icons: $graphicsStepId"
    Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTypedElements -Root $graphicsVisibleContent -Type ([System.Windows.Shapes.Shape])).Count -eq 0) "AXIS Graphics content must not render vector icons: $graphicsStepId"
    Assert-BoostLabCondition ($null -ne $graphicsInformationSharedRightEdge) "AXIS Graphics information card should use the shared physical right-edge text renderer: $graphicsStepId"
    Assert-BoostLabCondition ([string]$graphicsInformationSharedRightEdge.Resources[$axisSharedCardBodyTextRendererMarker] -eq 'RightAlignedVisualLines') "AXIS Graphics information cards should use shared right-aligned visual lines: $graphicsStepId"
    Assert-BoostLabCondition ([bool]$graphicsInformationSharedRightEdge.Resources[$axisSharedCardBodyNoLeftFloatingMarker]) "AXIS Graphics information cards should prevent left-floating wrapped Arabic lines: $graphicsStepId"
    Assert-BoostLabCondition ([bool]$graphicsInformationSharedRightEdge.Resources[$axisSharedCardBodyMixedBidiMarker]) "AXIS Graphics information cards should use the mixed BiDi-safe visual-line path: $graphicsStepId"
    Assert-BoostLabCondition ([string]$graphicsInformationSharedRightEdge.Resources[$axisSharedCardBodyFutureGuardMarker] -eq 'GraphicsWindowsAdvanced') "AXIS shared card renderer should guard future Graphics/Windows/Advanced batches: $graphicsStepId"
    $graphicsInformationBodyLines = @(
        Get-AxisFirstUseWizardTypedElements -Root $graphicsInformationSharedRightEdge -Type ([System.Windows.Controls.TextBlock]) |
            Where-Object { [string]$_.Tag -like "AxisFirstUseWizard.${graphicsTagRoot}InformationItem*" }
    )
    Assert-BoostLabCondition ($graphicsInformationBodyLines.Count -ge @($graphicsSpec['InfoItems']).Count) "AXIS Graphics information body lines should render approved bullets: $graphicsStepId"
    foreach ($graphicsInformationBodyLine in $graphicsInformationBodyLines) {
        Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($graphicsInformationBodyLine) -eq $axisSetupRightAlignedVisualLineRendererAutomationId) "AXIS Graphics information body line should use the safe no-left-floating marker: $graphicsStepId"
        Assert-BoostLabCondition ($graphicsInformationBodyLine.TextWrapping -eq [System.Windows.TextWrapping]::NoWrap) "AXIS Graphics information body line should bypass automatic WPF wrapping: $graphicsStepId"
        Assert-BoostLabCondition ($graphicsInformationBodyLine.TextAlignment -eq [System.Windows.TextAlignment]::Right) "AXIS Graphics information body line should stay right-aligned: $graphicsStepId"
        Assert-BoostLabCondition ($graphicsInformationBodyLine.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) "AXIS Graphics information body line should stay physically anchored right: $graphicsStepId"
        Assert-BoostLabCondition ($graphicsInformationBodyLine.FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) "AXIS Graphics information body line should remain RTL-shaped: $graphicsStepId"
    }
    if ($graphicsStepId -eq 'driver-install-debloat-settings') {
        Assert-BoostLabCondition (@($graphicsInformationBodyLines | Where-Object { [string]$_.Tag -like '*.VisualLine' }).Count -ge 1) "AXIS Graphics long mixed information text should use explicit visual split lines: $graphicsStepId"
    }
    $graphicsInformationSharedRightEdge.Measure([System.Windows.Size]::new(340.0, [double]::PositiveInfinity))
    $graphicsInformationInnerHeight = [double]$graphicsInformationCard.Height -
        [double]$graphicsInformationCard.Padding.Top -
        [double]$graphicsInformationCard.Padding.Bottom -
        [double]$graphicsInformationCard.BorderThickness.Top -
        [double]$graphicsInformationCard.BorderThickness.Bottom
    Assert-BoostLabCondition ([double]$graphicsInformationSharedRightEdge.DesiredSize.Height -le $graphicsInformationInnerHeight) "AXIS Graphics information card text should fit without top/bottom clipping: $graphicsStepId"

    $graphicsContentGrid = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsVisibleContent -Tag 'AxisFirstUseWizard.StepTextContent') | Select-Object -First 1
    $graphicsStepElement.Measure([System.Windows.Size]::new(826.0, 389.0))
    $graphicsRowTotal = 0.0
    foreach ($graphicsRowChild in @($graphicsContentGrid.Children)) {
        $graphicsRowChild.Measure([System.Windows.Size]::new(758.0, [double]::PositiveInfinity))
        $graphicsRowTotal += [double]$graphicsRowChild.DesiredSize.Height
    }
    $graphicsInnerHeight = [double]$graphicsStepElement.Height -
        [double]$graphicsStepElement.Padding.Top -
        [double]$graphicsStepElement.Padding.Bottom -
        [double]$graphicsStepElement.BorderThickness.Top -
        [double]$graphicsStepElement.BorderThickness.Bottom
    Assert-BoostLabCondition ($graphicsRowTotal -le $graphicsInnerHeight) "AXIS Graphics row content should fit without clipped information/support/footer content: $graphicsStepId"

    if (@($graphicsSpec['Requirements']).Count -gt 0) {
        Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($graphicsDetailsGrid) -eq 'AxisFirstUseWizard.GraphicsCardsPhysicalOrderInfoRightRequirementsLeft') "AXIS Graphics should mark physical info-right requirements-left order: $graphicsStepId"
        Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($graphicsInformationCard) -eq 2) "AXIS Graphics information card should be physical right: $graphicsStepId"
        Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($graphicsRequirementsCard) -eq 0) "AXIS Graphics requirements card should be physical left: $graphicsStepId"
        Assert-BoostLabCondition ($null -ne $graphicsRequirementsSharedRightEdge) "AXIS Graphics requirements card should use the shared physical right-edge text renderer: $graphicsStepId"
        Assert-BoostLabCondition ([string]$graphicsRequirementsSharedRightEdge.Resources[$axisSharedCardBodyTextRendererMarker] -eq 'RightAlignedVisualLines') "AXIS Graphics requirements cards should use shared right-aligned visual lines: $graphicsStepId"
        Assert-BoostLabCondition ([bool]$graphicsRequirementsSharedRightEdge.Resources[$axisSharedCardBodyNoLeftFloatingMarker]) "AXIS Graphics requirements cards should prevent left-floating wrapped Arabic lines: $graphicsStepId"
        Assert-BoostLabCondition ([bool]$graphicsRequirementsSharedRightEdge.Resources[$axisSharedCardBodyMixedBidiMarker]) "AXIS Graphics requirements cards should use the mixed BiDi-safe visual-line path: $graphicsStepId"
        $graphicsRequirementBodyLines = @(
            Get-AxisFirstUseWizardTypedElements -Root $graphicsRequirementsSharedRightEdge -Type ([System.Windows.Controls.TextBlock]) |
                Where-Object { [string]$_.Tag -like "AxisFirstUseWizard.${graphicsTagRoot}RequirementItem*" }
        )
        Assert-BoostLabCondition ($graphicsRequirementBodyLines.Count -ge @($graphicsSpec['Requirements']).Count) "AXIS Graphics requirements body lines should render approved bullets: $graphicsStepId"
        foreach ($graphicsRequirementBodyLine in $graphicsRequirementBodyLines) {
            Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($graphicsRequirementBodyLine) -eq $axisSetupRightAlignedVisualLineRendererAutomationId) "AXIS Graphics requirements body line should use the safe no-left-floating marker: $graphicsStepId"
            Assert-BoostLabCondition ($graphicsRequirementBodyLine.TextWrapping -eq [System.Windows.TextWrapping]::NoWrap) "AXIS Graphics requirements body line should bypass automatic WPF wrapping: $graphicsStepId"
            Assert-BoostLabCondition ($graphicsRequirementBodyLine.TextAlignment -eq [System.Windows.TextAlignment]::Right) "AXIS Graphics requirements body line should stay right-aligned: $graphicsStepId"
            Assert-BoostLabCondition ($graphicsRequirementBodyLine.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) "AXIS Graphics requirements body line should stay physically anchored right: $graphicsStepId"
            Assert-BoostLabCondition ($graphicsRequirementBodyLine.FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) "AXIS Graphics requirements body line should remain RTL-shaped: $graphicsStepId"
        }
        $graphicsRequirementsSharedRightEdge.Measure([System.Windows.Size]::new(340.0, [double]::PositiveInfinity))
        $graphicsRequirementsInnerHeight = [double]$graphicsRequirementsCard.Height -
            [double]$graphicsRequirementsCard.Padding.Top -
            [double]$graphicsRequirementsCard.Padding.Bottom -
            [double]$graphicsRequirementsCard.BorderThickness.Top -
            [double]$graphicsRequirementsCard.BorderThickness.Bottom
        Assert-BoostLabCondition ([double]$graphicsRequirementsSharedRightEdge.DesiredSize.Height -le $graphicsRequirementsInnerHeight) "AXIS Graphics requirements card text should fit without top/bottom clipping: $graphicsStepId"
    }
    else {
        Assert-BoostLabCondition ($null -eq $graphicsRequirementsCard) "AXIS Graphics no-requirements step must not render a requirements card: $graphicsStepId"
        Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($graphicsInformationCard) -eq 0) "AXIS Graphics single information card should use the only details column: $graphicsStepId"
    }

    if ([bool]$graphicsSpec['Selector']) {
        $graphicsGpuSelectorRow = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsVisibleContent -Tag 'AxisFirstUseWizard.GraphicsGpuSelectorRow') | Select-Object -First 1
        $graphicsGpuSelectorLabel = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsVisibleContent -Tag 'AxisFirstUseWizard.GraphicsGpuSelectorLabel') | Select-Object -First 1
        $graphicsGpuSelector = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsVisibleContent -Tag 'AxisFirstUseWizard.GraphicsGpuSelector') | Select-Object -First 1
        Assert-BoostLabCondition ($graphicsGpuSelector -is [System.Windows.Controls.ComboBox]) 'AXIS GPU Driver Setup should render the GPU selector.'
        Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($graphicsGpuSelector) -eq 'AxisFirstUseWizard.GraphicsGpuSelectorNvidiaOnly') 'AXIS GPU selector should expose the NVIDIA-only marker.'
        Assert-BoostLabCondition ([bool]$graphicsGpuSelectorRow.Resources['AxisFirstUseWizard.GraphicsGpuSelectorPhysicalLeftAboveRequirements']) 'AXIS GPU selector should expose the physical-left above-requirements marker.'
        [void](Assert-AxisFirstUseWizardSelectorPhysicalLeftAboveRequirements -Row $graphicsGpuSelectorRow -Selector $graphicsGpuSelector -Label $graphicsGpuSelectorLabel -ContentGrid $graphicsContentGrid -DetailsGrid $graphicsDetailsGrid -Name 'GPU Driver Setup')
        Assert-BoostLabCondition ([bool]$graphicsGpuSelector.Resources['AxisFirstUseWizard.GraphicsGpuSelectorUsesSharedDarkAxisStyle']) 'AXIS GPU selector should use the shared dark AXIS selector style.'
        Assert-BoostLabCondition ([bool]$graphicsGpuSelector.Resources['AxisFirstUseWizard.GraphicsGpuSelectorNoRuntimeAction']) 'AXIS GPU selector should be marked no-runtime.'
        Assert-BoostLabCondition ([bool]$graphicsGpuSelector.Resources['AxisFirstUseWizard.GraphicsGpuSelectorAmdIntelDisabled']) 'AXIS GPU selector should mark AMD/Intel as disabled.'
        Assert-BoostLabCondition ($graphicsGpuSelector.Items.Count -eq 3) 'AXIS GPU selector should expose exactly NVIDIA, AMD later, and Intel later.'
        Assert-BoostLabCondition ([string]$graphicsGpuSelector.Items[0].Content -eq 'NVIDIA') 'AXIS GPU selector first option should be NVIDIA.'
        Assert-BoostLabCondition ([string]$graphicsGpuSelector.Items[1].Content -eq $graphicsGpuSetupAmdLater) 'AXIS GPU selector AMD option text changed.'
        Assert-BoostLabCondition ([string]$graphicsGpuSelector.Items[2].Content -eq $graphicsGpuSetupIntelLater) 'AXIS GPU selector Intel option text changed.'
        Assert-BoostLabCondition ([bool]$graphicsGpuSelector.Items[0].IsEnabled) 'AXIS GPU selector NVIDIA should be selectable.'
        Assert-BoostLabCondition (-not [bool]$graphicsGpuSelector.Items[1].IsEnabled) 'AXIS GPU selector AMD should be disabled.'
        Assert-BoostLabCondition (-not [bool]$graphicsGpuSelector.Items[2].IsEnabled) 'AXIS GPU selector Intel should be disabled.'
        Assert-BoostLabCondition (-not [bool]$graphicsPrimaryButton.IsEnabled) 'AXIS GPU Driver Setup primary should start disabled until NVIDIA is selected.'
        Invoke-AxisFirstUseWizardButtonClick -Button $graphicsPrimaryButton
        Assert-BoostLabCondition ($graphicsRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS GPU Driver Setup disabled primary should not start simulation.'
        $graphicsGpuSelector.SelectedIndex = 0
        Assert-BoostLabCondition ([bool]$graphicsPrimaryButton.IsEnabled) 'AXIS GPU Driver Setup primary should enable after NVIDIA is selected.'
        Assert-AxisFirstUseWizardNextDisabledNonBlue -Button $graphicsContinueButton -Name 'GPU Driver Setup after NVIDIA selector selection'
        Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($graphicsPrimaryButton) -eq 'AxisFirstUseWizard.GraphicsGpuSetupPrimaryEnabledWithNvidiaSelection') 'AXIS GPU Driver Setup enabled primary should expose NVIDIA selection marker.'
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$graphicsSpec['OptionalContinuation'])) {
        Assert-BoostLabCondition ([string]$graphicsOptionalContinuationButton.Content -eq [string]$graphicsSpec['OptionalContinuation']) 'AXIS NVIDIA App optional continuation label changed in the footer.'
        Assert-BoostLabCondition ($graphicsOptionalContinuationButton.Visibility -eq [System.Windows.Visibility]::Visible) 'AXIS NVIDIA App optional continuation should be visible on the NVIDIA App step.'
        Assert-BoostLabCondition ([bool]$graphicsOptionalContinuationButton.IsEnabled) 'AXIS NVIDIA App optional continuation should be enabled on the NVIDIA App step.'
        Assert-BoostLabCondition ([double]$graphicsOptionalContinuationButton.Width -ge 244.0) 'AXIS NVIDIA App optional continuation should keep enough width for the full mixed Arabic/English label.'
        $graphicsOptionalContinuationButton.Measure([System.Windows.Size]::new([double]$graphicsOptionalContinuationButton.Width, [double]$graphicsOptionalContinuationButton.Height))
        Assert-BoostLabCondition ([double]$graphicsOptionalContinuationButton.DesiredSize.Width -le ([double]$graphicsOptionalContinuationButton.Width + 1.0)) 'AXIS NVIDIA App optional continuation label should not be clipped or truncated.'
        Invoke-AxisFirstUseWizardButtonClick -Button $graphicsOptionalContinuationButton
        Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $graphicsContentHost.Child -Tag 'AxisFirstUseWizard.GraphicsDirectXStep').Count -eq 1) 'AXIS NVIDIA App optional continuation should advance to DirectX.'
        Assert-BoostLabCondition ($graphicsRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS NVIDIA App optional continuation must not start runtime status.'
        Assert-BoostLabCondition (-not [bool]$graphicsContinueButton.IsEnabled) 'AXIS DirectX Next should start disabled after optional NVIDIA App continuation.'

        $graphicsSampleState = Get-AxisFirstUseWizardSampleState
        $graphicsSampleState['CurrentStepIndex'] = $graphicsStepIndex
        $graphicsPrototype = New-AxisFirstUseWizardPrototype -SampleState $graphicsSampleState
        $graphicsContentHost = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsPrototype -Tag 'AxisFirstUseWizard.StepContentHost') | Select-Object -First 1
        $graphicsContinueButton = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsPrototype -Tag 'AxisFirstUseWizard.ContinueButton') | Select-Object -First 1
        $graphicsVisibleContent = $graphicsContentHost.Child
        $graphicsPrimaryButton = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsVisibleContent -Tag 'AxisFirstUseWizard.PrimaryOpenButton') | Select-Object -First 1
        $graphicsRuntimeStatusArea = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsVisibleContent -Tag 'AxisFirstUseWizard.RuntimeStatusArea') | Select-Object -First 1
        $graphicsRuntimeStatusSpacer = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsVisibleContent -Tag 'AxisFirstUseWizard.ActionRuntimeStatusSpacer') | Select-Object -First 1
    }
    else {
        Assert-BoostLabCondition ($graphicsOptionalContinuationButton.Visibility -eq [System.Windows.Visibility]::Collapsed) "AXIS optional continuation should stay hidden outside NVIDIA App step: $graphicsStepId"
    }

    $graphicsOverlays = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsPrototype -Tag 'AxisFirstUseWizard.ConfirmationOverlay')
    if ([bool]$graphicsSpec['Overlay']) {
        Invoke-AxisFirstUseWizardButtonClick -Button $graphicsPrimaryButton
        $visibleGraphicsOverlays = @($graphicsOverlays | Where-Object { $_.Visibility -eq [System.Windows.Visibility]::Visible })
        Assert-BoostLabCondition ($visibleGraphicsOverlays.Count -eq 1) "AXIS Graphics primary should reveal one confirmation overlay only: $graphicsStepId"
        $graphicsOverlay = $visibleGraphicsOverlays[0]
        $graphicsOverlayText = (Get-AxisFirstUseWizardTextValues -Root $graphicsOverlay) -join [Environment]::NewLine
        Assert-BoostLabCondition ($graphicsOverlayText.Contains($arabicAcknowledgement)) "AXIS Graphics overlay should show acknowledgement copy: $graphicsStepId"
        Assert-BoostLabCondition ($graphicsOverlayText.Contains([string]$graphicsSpec['Primary'])) "AXIS Graphics overlay should show matching primary copy: $graphicsStepId"
        Assert-BoostLabCondition ($graphicsOverlayText.Contains($arabicReturn)) "AXIS Graphics overlay should show Return copy: $graphicsStepId"
        $graphicsOverlayAcknowledgement = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsOverlay -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgement') | Select-Object -First 1
        $graphicsOverlayOpenButton = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsOverlay -Tag 'AxisFirstUseWizard.ConfirmationOpenButton') | Select-Object -First 1
        $graphicsOverlayReturnButton = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsOverlay -Tag 'AxisFirstUseWizard.ConfirmationReturnButton') | Select-Object -First 1
        Assert-BoostLabCondition (-not [bool]$graphicsOverlayOpenButton.IsEnabled) "AXIS Graphics confirmation should start disabled until acknowledgement: $graphicsStepId"
        Invoke-AxisFirstUseWizardButtonClick -Button $graphicsOverlayReturnButton
        Assert-BoostLabCondition ($graphicsOverlay.Visibility -eq [System.Windows.Visibility]::Collapsed) "AXIS Graphics Return should close only the overlay: $graphicsStepId"
        Assert-BoostLabCondition (-not [bool]$graphicsContinueButton.IsEnabled) "AXIS Graphics Return must not enable Next: $graphicsStepId"
        Assert-BoostLabCondition ($graphicsRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) "AXIS Graphics Return must not start runtime status: $graphicsStepId"
        Invoke-AxisFirstUseWizardButtonClick -Button $graphicsPrimaryButton
        $visibleGraphicsOverlays = @($graphicsOverlays | Where-Object { $_.Visibility -eq [System.Windows.Visibility]::Visible })
        $graphicsOverlay = $visibleGraphicsOverlays[0]
        $graphicsOverlayAcknowledgement = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsOverlay -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgement') | Select-Object -First 1
        $graphicsOverlayOpenButton = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsOverlay -Tag 'AxisFirstUseWizard.ConfirmationOpenButton') | Select-Object -First 1
        $graphicsOverlayAcknowledgement.IsChecked = $true
        Assert-BoostLabCondition ([bool]$graphicsOverlayOpenButton.IsEnabled) "AXIS Graphics confirmation should enable after acknowledgement: $graphicsStepId"
        Assert-AxisFirstUseWizardNextDisabledNonBlue -Button $graphicsContinueButton -Name "$graphicsStepId after confirmation acknowledgement"
        Invoke-AxisFirstUseWizardButtonClick -Button $graphicsOverlayOpenButton
        Assert-BoostLabCondition ($graphicsOverlay.Visibility -eq [System.Windows.Visibility]::Collapsed) "AXIS Graphics confirmation should close before simulation: $graphicsStepId"
    }
    else {
        Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $graphicsVisibleContent -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgement').Count -eq 0) "AXIS Graphics content must not include a confirmation checkbox: $graphicsStepId"
        Invoke-AxisFirstUseWizardButtonClick -Button $graphicsPrimaryButton
        $visibleGraphicsOverlays = @($graphicsOverlays | Where-Object { $_.Visibility -eq [System.Windows.Visibility]::Visible })
        Assert-BoostLabCondition ($visibleGraphicsOverlays.Count -eq 0) "AXIS Graphics no-overlay step should not reveal a confirmation overlay: $graphicsStepId"
    }

    Assert-BoostLabCondition ($graphicsRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Visible) "AXIS Graphics simulated action should show runtime status: $graphicsStepId"
    Assert-BoostLabCondition ($graphicsRuntimeStatusSpacer.Visibility -eq [System.Windows.Visibility]::Visible) "AXIS Graphics runtime spacer should be visible during simulation: $graphicsStepId"
    $graphicsRunningText = (Get-AxisFirstUseWizardTextValues -Root $graphicsVisibleContent) -join [Environment]::NewLine
    Assert-BoostLabCondition ($graphicsRunningText.Contains([string]$graphicsSpec['Running'])) "AXIS Graphics should show owner-approved running status: $graphicsStepId"
    Assert-BoostLabCondition ($graphicsRunningText.Contains($arabicSupportBody)) "AXIS Graphics support panel should remain visible during simulation: $graphicsStepId"
    $graphicsRunningRuntimeStatusRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $graphicsRuntimeStatusArea -Tag 'AxisFirstUseWizard.RuntimeStatusArabicRightAnchor')
    Assert-BoostLabCondition ($graphicsRunningRuntimeStatusRightAnchor.Count -eq 1) "AXIS Graphics running status should keep text near the action row: $graphicsStepId"
    Assert-BoostLabCondition (Wait-AxisFirstUseWizardCondition -Condition { [bool]$graphicsContinueButton.IsEnabled } -TimeoutMilliseconds 3000) "AXIS Graphics should enable Next after simulated completion: $graphicsStepId"
    $graphicsCompletedText = (Get-AxisFirstUseWizardTextValues -Root $graphicsVisibleContent) -join [Environment]::NewLine
    Assert-BoostLabCondition ($graphicsCompletedText.Contains([string]$graphicsSpec['Completed'])) "AXIS Graphics should end in owner-approved completed status: $graphicsStepId"
    Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $graphicsRuntimeStatusArea -Tag 'AxisFirstUseWizard.CompletedEffect').Count -eq 1) "AXIS Graphics completed state should render the completed runtime effect: $graphicsStepId"
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($graphicsContinueButton) -eq 'AxisFirstUseWizard.EnabledNextButtonBlue') "AXIS Graphics Next should become blue after simulated completion: $graphicsStepId"

    if ($graphicsStepId -eq 'graphics-configuration-center') {
        Invoke-AxisFirstUseWizardButtonClick -Button $graphicsContinueButton
        Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $graphicsContentHost.Child -Tag 'AxisFirstUseWizard.WindowsStartMenuTaskbarStep').Count -eq 1) 'AXIS Graphics Configuration Center Continue/Next should navigate to the first Windows Part A step.'
    }
}

foreach ($windowsSpec in $windowsStepSpecs) {
    $windowsStepId = [string]$windowsSpec['Id']
    $windowsTagRoot = [string]$windowsSpec['TagRoot']
    $windowsSampleState = Get-AxisFirstUseWizardSampleState
    $windowsStepIds = @($windowsSampleState['Steps'] | ForEach-Object { [string]$_['Id'] })
    $windowsStepIndex = [Array]::IndexOf($windowsStepIds, $windowsStepId)
    Assert-BoostLabCondition ($windowsStepIndex -ge 0) "AXIS Windows render test should find step: $windowsStepId"
    $windowsSampleState['CurrentStepIndex'] = $windowsStepIndex
    $expectedWindowsStageBatchMarker = if ($windowsSpec.Contains('WindowsStageBatchMarker')) {
        [string]$windowsSpec['WindowsStageBatchMarker']
    }
    else {
        'AxisFirstUseWizard.WindowsStagePartAPrototypeOnly'
    }
    $windowsPrototype = New-AxisFirstUseWizardPrototype -SampleState $windowsSampleState
    $windowsContentHost = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsPrototype -Tag 'AxisFirstUseWizard.StepContentHost') | Select-Object -First 1
    $windowsContinueButton = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsPrototype -Tag 'AxisFirstUseWizard.ContinueButton') | Select-Object -First 1
    $windowsVisibleContent = $windowsContentHost.Child
    $windowsVisibleText = (Get-AxisFirstUseWizardTextValues -Root $windowsVisibleContent) -join [Environment]::NewLine
    $windowsStepElement = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsVisibleContent -Tag "AxisFirstUseWizard.${windowsTagRoot}Step") | Select-Object -First 1
    $windowsTitleText = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsVisibleContent -Tag "AxisFirstUseWizard.${windowsTagRoot}TitleText") | Select-Object -First 1
    $windowsDetailsGrid = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsVisibleContent -Tag "AxisFirstUseWizard.${windowsTagRoot}StepDetails") | Select-Object -First 1
    $windowsInformationCard = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsVisibleContent -Tag "AxisFirstUseWizard.${windowsTagRoot}InformationCard") | Select-Object -First 1
    $windowsRequirementsCard = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsVisibleContent -Tag "AxisFirstUseWizard.${windowsTagRoot}RequirementsCard") | Select-Object -First 1
    $windowsInformationSharedRightEdge = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsVisibleContent -Tag "AxisFirstUseWizard.${windowsTagRoot}InformationSharedPhysicalRightEdge") | Select-Object -First 1
    $windowsRequirementsSharedRightEdge = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsVisibleContent -Tag "AxisFirstUseWizard.${windowsTagRoot}RequirementsSharedPhysicalRightEdge") | Select-Object -First 1
    $windowsPrimaryButton = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsVisibleContent -Tag 'AxisFirstUseWizard.PrimaryOpenButton') | Select-Object -First 1
    $windowsRuntimeStatusArea = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsVisibleContent -Tag 'AxisFirstUseWizard.RuntimeStatusArea') | Select-Object -First 1
    $windowsRuntimeStatusSpacer = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsVisibleContent -Tag 'AxisFirstUseWizard.ActionRuntimeStatusSpacer') | Select-Object -First 1
    $windowsSupportPanel = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsVisibleContent -Tag 'AxisFirstUseWizard.SupportPanel') | Select-Object -First 1
    $windowsDocumentationButton = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsVisibleContent -Tag 'AxisFirstUseWizard.DocumentationButton') | Select-Object -First 1
    $windowsStageHeader = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsPrototype -Tag 'AxisFirstUseWizard.CurrentStageHeader') | Select-Object -First 1
    $windowsCheckFill = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Check') | Select-Object -First 1
    $windowsRefreshFill = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Refresh') | Select-Object -First 1
    $windowsSetupFill = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Setup') | Select-Object -First 1
    $windowsInstallersFill = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Installers') | Select-Object -First 1
    $windowsGraphicsFill = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Graphics') | Select-Object -First 1
    $windowsWindowsFill = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Windows') | Select-Object -First 1
    $windowsAdvancedFill = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Advanced') | Select-Object -First 1

    Assert-BoostLabCondition ($windowsStepElement -is [System.Windows.Controls.Border]) "AXIS Windows Part A step should render a step card: $windowsStepId"
    Assert-BoostLabCondition ([double]$windowsStepElement.Height -eq 382.0) "AXIS Windows Part A step should fit inside the 900x650 preview client area: $windowsStepId"
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($windowsStepElement) -eq $expectedWindowsStageBatchMarker) "AXIS Windows step should expose the expected prototype-only batch marker: $windowsStepId"
    Assert-BoostLabCondition ([string](Get-AxisFirstUseWizardTextBlockPlainText -TextBlock $windowsTitleText) -eq [string]$windowsSpec['Title']) "AXIS Windows Part A visible title changed: $windowsStepId"
    Assert-BoostLabCondition ($windowsTitleText.FlowDirection -eq [System.Windows.FlowDirection]::LeftToRight) "AXIS Windows Part A English title should render LTR while right-anchored: $windowsStepId"
    Assert-BoostLabCondition ([string]$windowsPrimaryButton.Content -eq [string]$windowsSpec['Primary']) "AXIS Windows Part A primary button text changed: $windowsStepId"
    $windowsPrimaryNoClippingMarkers = @{
        'start-menu-layout' = 'AxisFirstUseWizard.WindowsStartMenuLayoutPrimaryNoClipping'
        'context-menu' = 'AxisFirstUseWizard.WindowsContextMenuPrimaryNoClipping'
        'user-account-pictures-black' = 'AxisFirstUseWizard.WindowsBlackAccountPicturesPrimaryNoClipping'
        'game-mode' = 'AxisFirstUseWizard.WindowsGameModePrimaryNoClipping'
    }
    $windowsPrimaryNoClippingMinimums = @{
        'start-menu-layout' = 242.0
        'context-menu' = 218.0
        'user-account-pictures-black' = 224.0
        'game-mode' = 232.0
    }
    if ($windowsPrimaryNoClippingMarkers.ContainsKey($windowsStepId)) {
        $windowsPrimaryNoClippingMarker = [string]$windowsPrimaryNoClippingMarkers[$windowsStepId]
        Assert-BoostLabCondition ([bool]$windowsPrimaryButton.Resources['AxisFirstUseWizard.WindowsPrimaryActionSharedNoClippingSizing']) "AXIS Windows Part A primary button should use shared no-clipping sizing: $windowsStepId"
        Assert-BoostLabCondition ([bool]$windowsPrimaryButton.Resources[$windowsPrimaryNoClippingMarker]) "AXIS Windows Part A primary button should expose its no-clipping marker: $windowsStepId"
        Assert-BoostLabCondition ([double]$windowsPrimaryButton.Width -ge [double]$windowsPrimaryNoClippingMinimums[$windowsStepId]) "AXIS Windows Part A primary button should keep enough width for its full label: $windowsStepId"
        $windowsPrimaryButton.Measure([System.Windows.Size]::new([double]$windowsPrimaryButton.Width, [double]$windowsPrimaryButton.Height))
        Assert-BoostLabCondition ([double]$windowsPrimaryButton.DesiredSize.Width -le ([double]$windowsPrimaryButton.Width + 1.0)) "AXIS Windows Part A primary button label should not be clipped: $windowsStepId"
    }
    Assert-BoostLabCondition (-not [bool]$windowsContinueButton.IsEnabled) "AXIS Windows Part A Next should start disabled until simulated completion: $windowsStepId"
    Assert-BoostLabCondition ($windowsRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) "AXIS Windows Part A runtime status should start hidden: $windowsStepId"
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($windowsRuntimeStatusArea) -eq 'AxisFirstUseWizard.WindowsRuntimeStatusNoClipping') "AXIS Windows Part A runtime status should expose no-clipping marker: $windowsStepId"
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($windowsSupportPanel) -eq 'AxisFirstUseWizard.WindowsSupportCardNoClipping') "AXIS Windows Part A support panel should expose no-clipping marker: $windowsStepId"
    Assert-BoostLabCondition ([double]$windowsSupportPanel.MinHeight -eq 52.0) "AXIS Windows Part A support panel should use compact no-clipping height: $windowsStepId"
    Assert-BoostLabCondition ([double]$windowsSupportPanel.Padding.Top -eq 6.0 -and [double]$windowsSupportPanel.Padding.Bottom -eq 6.0) "AXIS Windows Part A support panel should keep compact internal padding: $windowsStepId"
    Assert-BoostLabCondition ([double]$windowsSupportPanel.Margin.Top -eq 4.0) "AXIS Windows Part A support panel should avoid bottom clipping with a compact top margin: $windowsStepId"
    Assert-BoostLabCondition ([string]$windowsStageHeader.Text -eq 'Windows') "AXIS Windows Part A current stage header should show Windows: $windowsStepId"
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $windowsCheckFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Check' -ExpectedColor '#FF22C55E' -Name "$windowsStepId Check completed")
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $windowsRefreshFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Refresh' -ExpectedColor '#FF22C55E' -Name "$windowsStepId Refresh completed")
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $windowsSetupFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Setup' -ExpectedColor '#FF22C55E' -Name "$windowsStepId Setup completed")
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $windowsInstallersFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Installers' -ExpectedColor '#FF22C55E' -Name "$windowsStepId Installers completed")
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $windowsGraphicsFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Graphics' -ExpectedColor '#FF22C55E' -Name "$windowsStepId Graphics completed")
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $windowsWindowsFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineActiveFullWhite.Windows' -ExpectedColor '#FFF0F2F5' -Name "$windowsStepId Windows active")
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $windowsAdvancedFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineInactiveDim.Advanced' -ExpectedColor '#FF242424' -Name "$windowsStepId Advanced inactive")

    foreach ($requiredWindowsText in @(
        'Windows'
        [string]$windowsSpec['Title']
        [string]$windowsSpec['Subtitle']
        [string]$windowsSpec['InfoTitle']
        @($windowsSpec['InfoItems'])
        @($windowsSpec['Requirements'])
        [string]$windowsSpec['Primary']
        $arabicDocumentation
        $arabicSupportTitle
        $arabicSupportBody
    )) {
        foreach ($requiredWindowsTextItem in @($requiredWindowsText)) {
            if ([string]::IsNullOrWhiteSpace([string]$requiredWindowsTextItem)) {
                continue
            }
            $requiredWindowsTextNormalized = ConvertTo-AxisFirstUseWizardNormalizedText -Text ([string]$requiredWindowsTextItem)
            $windowsVisibleTextNormalized = ConvertTo-AxisFirstUseWizardNormalizedText -Text $windowsVisibleText
            Assert-BoostLabCondition (
                $windowsVisibleText.Contains([string]$requiredWindowsTextItem) -or
                $windowsVisibleTextNormalized.Contains($requiredWindowsTextNormalized)
            ) "AXIS Windows Part A view is missing owner-approved text for ${windowsStepId}: $requiredWindowsTextItem"
        }
    }
    Assert-BoostLabCondition (-not $windowsVisibleText.Contains([string][char]0xFFFD)) "AXIS Windows Part A visible copy must not contain replacement glyphs: $windowsStepId"
    Assert-BoostLabCondition (-not $windowsVisibleText.Contains('BoostLab')) "AXIS Windows normal customer UI must not expose BoostLab branding: $windowsStepId"
    foreach ($forbiddenWindowsVisibleText in @('Analyze', 'Default', 'Restore', 'Cancel', 'Skip', 'Skipped', 'Completed with notes', '25H2', '24H2', 'Clean (Recommended)', 'Explorer restart')) {
        Assert-BoostLabCondition (-not $windowsVisibleText.Contains($forbiddenWindowsVisibleText)) "AXIS Windows Part A view exposes forbidden customer text for ${windowsStepId}: $forbiddenWindowsVisibleText"
    }
    Assert-BoostLabCondition ($windowsRuntimeStatusArea -ne $windowsSupportPanel) "AXIS Windows Part A runtime status must remain separate from support panel: $windowsStepId"
    Assert-BoostLabCondition ($null -ne $windowsDocumentationButton) "AXIS Windows Part A documentation button is missing: $windowsStepId"
    Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $windowsVisibleContent -Tag 'AxisFirstUseWizard.AutoUnattendInputOverlay').Count -eq 0) "AXIS Windows Part A content must not include an input overlay: $windowsStepId"
    Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTypedElements -Root $windowsVisibleContent -Type ([System.Windows.Controls.Image])).Count -eq 0) "AXIS Windows Part A content must not render image icons: $windowsStepId"
    Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTypedElements -Root $windowsVisibleContent -Type ([System.Windows.Shapes.Shape])).Count -eq 0) "AXIS Windows Part A content must not render vector icons: $windowsStepId"
    Assert-BoostLabCondition ($null -ne $windowsInformationSharedRightEdge) "AXIS Windows Part A information card should use the shared physical right-edge text renderer: $windowsStepId"
    Assert-BoostLabCondition ([string]$windowsInformationSharedRightEdge.Resources[$axisSharedCardBodyTextRendererMarker] -eq 'RightAlignedVisualLines') "AXIS Windows Part A information cards should use shared right-aligned visual lines: $windowsStepId"
    Assert-BoostLabCondition ([bool]$windowsInformationSharedRightEdge.Resources[$axisSharedCardBodyNoLeftFloatingMarker]) "AXIS Windows Part A information cards should prevent left-floating wrapped Arabic lines: $windowsStepId"
    Assert-BoostLabCondition ([bool]$windowsInformationSharedRightEdge.Resources[$axisSharedCardBodyMixedBidiMarker]) "AXIS Windows Part A information cards should use the mixed BiDi-safe visual-line path: $windowsStepId"
    Assert-BoostLabCondition ([string]$windowsInformationSharedRightEdge.Resources[$axisSharedCardBodyFutureGuardMarker] -eq 'GraphicsWindowsAdvanced') "AXIS shared card renderer should guard future Graphics/Windows/Advanced batches: $windowsStepId"
    $windowsInformationBodyLines = @(
        Get-AxisFirstUseWizardTypedElements -Root $windowsInformationSharedRightEdge -Type ([System.Windows.Controls.TextBlock]) |
            Where-Object { [string]$_.Tag -like "AxisFirstUseWizard.${windowsTagRoot}InformationItem*" }
    )
    Assert-BoostLabCondition ($windowsInformationBodyLines.Count -ge @($windowsSpec['InfoItems']).Count) "AXIS Windows Part A information body lines should render approved bullets: $windowsStepId"
    foreach ($windowsInformationBodyLine in $windowsInformationBodyLines) {
        Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($windowsInformationBodyLine) -eq $axisSetupRightAlignedVisualLineRendererAutomationId) "AXIS Windows Part A information body line should use the safe no-left-floating marker: $windowsStepId"
        Assert-BoostLabCondition ($windowsInformationBodyLine.TextWrapping -eq [System.Windows.TextWrapping]::NoWrap) "AXIS Windows Part A information body line should bypass automatic WPF wrapping: $windowsStepId"
        Assert-BoostLabCondition ($windowsInformationBodyLine.TextAlignment -eq [System.Windows.TextAlignment]::Right) "AXIS Windows Part A information body line should stay right-aligned: $windowsStepId"
        Assert-BoostLabCondition ($windowsInformationBodyLine.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) "AXIS Windows Part A information body line should stay physically anchored right: $windowsStepId"
        Assert-BoostLabCondition ($windowsInformationBodyLine.FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) "AXIS Windows Part A information body line should remain RTL-shaped: $windowsStepId"
    }

    $windowsInfoMeasureWidth = if (@($windowsSpec['Requirements']).Count -gt 0) { 340.0 } else { 650.0 }
    $windowsInformationSharedRightEdge.Measure([System.Windows.Size]::new($windowsInfoMeasureWidth, [double]::PositiveInfinity))
    $windowsInformationInnerHeight = [double]$windowsInformationCard.Height -
        [double]$windowsInformationCard.Padding.Top -
        [double]$windowsInformationCard.Padding.Bottom -
        [double]$windowsInformationCard.BorderThickness.Top -
        [double]$windowsInformationCard.BorderThickness.Bottom
    Assert-BoostLabCondition ([double]$windowsInformationSharedRightEdge.DesiredSize.Height -le $windowsInformationInnerHeight) "AXIS Windows Part A information card text should fit without top/bottom clipping: $windowsStepId"

    $windowsContentGrid = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsVisibleContent -Tag 'AxisFirstUseWizard.StepTextContent') | Select-Object -First 1
    $windowsStepElement.Measure([System.Windows.Size]::new(826.0, 389.0))
    $windowsRowTotal = 0.0
    foreach ($windowsRowChild in @($windowsContentGrid.Children)) {
        $windowsRowChild.Measure([System.Windows.Size]::new(758.0, [double]::PositiveInfinity))
        $windowsRowTotal += [double]$windowsRowChild.DesiredSize.Height
    }
    $windowsInnerHeight = [double]$windowsStepElement.Height -
        [double]$windowsStepElement.Padding.Top -
        [double]$windowsStepElement.Padding.Bottom -
        [double]$windowsStepElement.BorderThickness.Top -
        [double]$windowsStepElement.BorderThickness.Bottom
    Assert-BoostLabCondition ($windowsRowTotal -le $windowsInnerHeight) "AXIS Windows Part A row content should fit without clipped information/support/footer content: $windowsStepId"

    if (@($windowsSpec['Requirements']).Count -gt 0) {
        Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($windowsDetailsGrid) -eq 'AxisFirstUseWizard.WindowsCardsPhysicalOrderInfoRightRequirementsLeft') "AXIS Windows Part A should mark physical info-right requirements-left order: $windowsStepId"
        Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($windowsInformationCard) -eq 2) "AXIS Windows Part A information card should be physical right: $windowsStepId"
        Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($windowsRequirementsCard) -eq 0) "AXIS Windows Part A requirements card should be physical left: $windowsStepId"
        Assert-BoostLabCondition ($null -ne $windowsRequirementsSharedRightEdge) "AXIS Windows Part A requirements card should use the shared physical right-edge text renderer: $windowsStepId"
        Assert-BoostLabCondition ([string]$windowsRequirementsSharedRightEdge.Resources[$axisSharedCardBodyTextRendererMarker] -eq 'RightAlignedVisualLines') "AXIS Windows Part A requirements cards should use shared right-aligned visual lines: $windowsStepId"
        Assert-BoostLabCondition ([bool]$windowsRequirementsSharedRightEdge.Resources[$axisSharedCardBodyNoLeftFloatingMarker]) "AXIS Windows Part A requirements cards should prevent left-floating wrapped Arabic lines: $windowsStepId"
        Assert-BoostLabCondition ([bool]$windowsRequirementsSharedRightEdge.Resources[$axisSharedCardBodyMixedBidiMarker]) "AXIS Windows Part A requirements cards should use the mixed BiDi-safe visual-line path: $windowsStepId"
        $windowsRequirementsSharedRightEdge.Measure([System.Windows.Size]::new(340.0, [double]::PositiveInfinity))
        $windowsRequirementsInnerHeight = [double]$windowsRequirementsCard.Height -
            [double]$windowsRequirementsCard.Padding.Top -
            [double]$windowsRequirementsCard.Padding.Bottom -
            [double]$windowsRequirementsCard.BorderThickness.Top -
            [double]$windowsRequirementsCard.BorderThickness.Bottom
        Assert-BoostLabCondition ([double]$windowsRequirementsSharedRightEdge.DesiredSize.Height -le $windowsRequirementsInnerHeight) "AXIS Windows Part A requirements card text should fit without top/bottom clipping: $windowsStepId"
    }
    else {
        Assert-BoostLabCondition ($null -eq $windowsRequirementsCard) "AXIS Windows Part A no-requirements step must not render a requirements card: $windowsStepId"
        Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($windowsInformationCard) -eq 0) "AXIS Windows Part A single information card should use the only details column: $windowsStepId"
    }

    $windowsOverlays = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsPrototype -Tag 'AxisFirstUseWizard.ConfirmationOverlay')
    if ([bool]$windowsSpec['Selector']) {
        $windowsActionSelectorRow = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsVisibleContent -Tag 'AxisFirstUseWizard.WindowsBloatwareActionSelectorRow') | Select-Object -First 1
        $windowsActionSelectorLabel = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsVisibleContent -Tag 'AxisFirstUseWizard.WindowsBloatwareActionSelectorLabel') | Select-Object -First 1
        $windowsActionSelector = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsVisibleContent -Tag 'AxisFirstUseWizard.WindowsBloatwareActionSelector') | Select-Object -First 1
        Assert-BoostLabCondition ($windowsActionSelector -is [System.Windows.Controls.ComboBox]) 'AXIS Bloatware action selector should render as a ComboBox.'
        Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($windowsActionSelector) -eq 'AxisFirstUseWizard.WindowsBloatwareActionSelectorSingleSelect') 'AXIS Bloatware action selector should expose the single-select marker.'
        Assert-BoostLabCondition ([bool]$windowsActionSelectorRow.Resources['AxisFirstUseWizard.WindowsBloatwareSelectorPhysicalLeftAboveRequirements']) 'AXIS Bloatware selector should expose the physical-left above-requirements marker.'
        [void](Assert-AxisFirstUseWizardSelectorPhysicalLeftAboveRequirements -Row $windowsActionSelectorRow -Selector $windowsActionSelector -Label $windowsActionSelectorLabel -ContentGrid $windowsContentGrid -DetailsGrid $windowsDetailsGrid -Name 'Bloatware')
        Assert-BoostLabCondition ([bool]$windowsActionSelector.Resources['AxisFirstUseWizard.WindowsBloatwareActionSelectorNoRuntimeAction']) 'AXIS Bloatware action selector should be marked no-runtime.'
        Assert-BoostLabCondition ([bool]$windowsActionSelector.Resources['AxisFirstUseWizard.WindowsBloatwareActionSelectorUsesSharedDarkAxisStyle']) 'AXIS Bloatware action selector should use the shared dark AXIS style.'
        Assert-BoostLabCondition ([bool]$windowsActionSelector.Resources['AxisFirstUseWizard.WindowsBloatwareActionSelectorOptionsOwnerApprovedOnly']) 'AXIS Bloatware action selector should mark owner-approved options only.'
        Assert-BoostLabCondition (-not [bool]$windowsActionSelector.IsEditable) 'AXIS Bloatware action selector should not allow free text.'
        Assert-BoostLabCondition ([string]$windowsActionSelector.Items[0].Content -eq [string]$windowsSpec['SelectorPlaceholder']) 'AXIS Bloatware action selector placeholder changed.'
        Assert-BoostLabCondition (-not [bool]$windowsActionSelector.Items[0].IsEnabled) 'AXIS Bloatware action selector placeholder should be disabled.'
        Assert-BoostLabCondition ((@($windowsActionSelector.Items | Select-Object -Skip 1 | ForEach-Object { [string]$_.Content }) -join '|') -eq (@($windowsSpec['SelectorOptions']) -join '|')) 'AXIS Bloatware action selector options changed.'
        Assert-BoostLabCondition (-not [bool]$windowsPrimaryButton.IsEnabled) 'AXIS Bloatware primary should start disabled until an option is selected.'
        Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($windowsPrimaryButton) -eq 'AxisFirstUseWizard.WindowsBloatwarePrimaryDisabledUntilActionSelected') 'AXIS Bloatware primary should expose the disabled-until-selection marker.'
        $windowsActionSelector.SelectedIndex = 1
        Assert-BoostLabCondition ([bool]$windowsPrimaryButton.IsEnabled) 'AXIS Bloatware primary should enable after selecting an owner-approved action.'
        Assert-AxisFirstUseWizardNextDisabledNonBlue -Button $windowsContinueButton -Name 'Bloatware after action selector selection'
        Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($windowsPrimaryButton) -eq 'AxisFirstUseWizard.WindowsBloatwarePrimaryEnabledWithActionSelection') 'AXIS Bloatware primary should expose the enabled-with-selection marker.'
        Assert-BoostLabCondition ([string]$windowsPrimaryButton.Resources['AxisFirstUseWizard.WindowsBloatwareSelectedAction'] -eq 'Remove All Bloatware') 'AXIS Bloatware selected action marker changed.'
    }

    if ([bool]$windowsSpec['Overlay']) {
        Invoke-AxisFirstUseWizardButtonClick -Button $windowsPrimaryButton
        $visibleWindowsOverlays = @($windowsOverlays | Where-Object { $_.Visibility -eq [System.Windows.Visibility]::Visible })
        Assert-BoostLabCondition ($visibleWindowsOverlays.Count -eq 1) "AXIS Windows Part A primary should reveal one confirmation overlay only: $windowsStepId"
        $windowsOverlay = $visibleWindowsOverlays[0]
        $windowsOverlayText = (Get-AxisFirstUseWizardTextValues -Root $windowsOverlay) -join [Environment]::NewLine
        Assert-BoostLabCondition ($windowsOverlayText.Contains($arabicAcknowledgement)) "AXIS Windows Part A overlay should show acknowledgement copy: $windowsStepId"
        Assert-BoostLabCondition ($windowsOverlayText.Contains([string]$windowsSpec['Primary'])) "AXIS Windows Part A overlay should show matching primary copy: $windowsStepId"
        Assert-BoostLabCondition ($windowsOverlayText.Contains($arabicReturn)) "AXIS Windows Part A overlay should show Return copy: $windowsStepId"
        $windowsOverlayAcknowledgement = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsOverlay -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgement') | Select-Object -First 1
        $windowsOverlayOpenButton = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsOverlay -Tag 'AxisFirstUseWizard.ConfirmationOpenButton') | Select-Object -First 1
        $windowsOverlayReturnButton = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsOverlay -Tag 'AxisFirstUseWizard.ConfirmationReturnButton') | Select-Object -First 1
        Assert-BoostLabCondition (-not [bool]$windowsOverlayOpenButton.IsEnabled) "AXIS Windows Part A confirmation should start disabled until acknowledgement: $windowsStepId"
        Invoke-AxisFirstUseWizardButtonClick -Button $windowsOverlayReturnButton
        Assert-BoostLabCondition ($windowsOverlay.Visibility -eq [System.Windows.Visibility]::Collapsed) "AXIS Windows Part A Return should close only the overlay: $windowsStepId"
        Assert-BoostLabCondition (-not [bool]$windowsContinueButton.IsEnabled) "AXIS Windows Part A Return must not enable Next: $windowsStepId"
        Assert-BoostLabCondition ($windowsRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) "AXIS Windows Part A Return must not start runtime status: $windowsStepId"
        Invoke-AxisFirstUseWizardButtonClick -Button $windowsPrimaryButton
        $visibleWindowsOverlays = @($windowsOverlays | Where-Object { $_.Visibility -eq [System.Windows.Visibility]::Visible })
        $windowsOverlay = $visibleWindowsOverlays[0]
        $windowsOverlayAcknowledgement = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsOverlay -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgement') | Select-Object -First 1
        $windowsOverlayOpenButton = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsOverlay -Tag 'AxisFirstUseWizard.ConfirmationOpenButton') | Select-Object -First 1
        $windowsOverlayAcknowledgement.IsChecked = $true
        Assert-BoostLabCondition ([bool]$windowsOverlayOpenButton.IsEnabled) "AXIS Windows Part A confirmation should enable after acknowledgement: $windowsStepId"
        Assert-AxisFirstUseWizardNextDisabledNonBlue -Button $windowsContinueButton -Name "$windowsStepId after confirmation acknowledgement"
        Invoke-AxisFirstUseWizardButtonClick -Button $windowsOverlayOpenButton
        Assert-BoostLabCondition ($windowsOverlay.Visibility -eq [System.Windows.Visibility]::Collapsed) "AXIS Windows Part A confirmation should close before simulation: $windowsStepId"
    }
    else {
        Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $windowsVisibleContent -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgement').Count -eq 0) "AXIS Windows Part A content must not include a confirmation checkbox: $windowsStepId"
        Invoke-AxisFirstUseWizardButtonClick -Button $windowsPrimaryButton
        $visibleWindowsOverlays = @($windowsOverlays | Where-Object { $_.Visibility -eq [System.Windows.Visibility]::Visible })
        Assert-BoostLabCondition ($visibleWindowsOverlays.Count -eq 0) "AXIS Windows Part A no-overlay step should not reveal a confirmation overlay: $windowsStepId"
    }

    Assert-BoostLabCondition ($windowsRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Visible) "AXIS Windows Part A simulated action should show runtime status: $windowsStepId"
    Assert-BoostLabCondition ($windowsRuntimeStatusSpacer.Visibility -eq [System.Windows.Visibility]::Visible) "AXIS Windows Part A runtime spacer should be visible during simulation: $windowsStepId"
    $windowsRunningText = (Get-AxisFirstUseWizardTextValues -Root $windowsVisibleContent) -join [Environment]::NewLine
    Assert-BoostLabCondition ($windowsRunningText.Contains([string]$windowsSpec['Running'])) "AXIS Windows Part A should show owner-approved running status: $windowsStepId"
    Assert-BoostLabCondition ($windowsRunningText.Contains($arabicSupportBody)) "AXIS Windows Part A support panel should remain visible during simulation: $windowsStepId"
    $windowsRunningRuntimeStatusRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsRuntimeStatusArea -Tag 'AxisFirstUseWizard.RuntimeStatusArabicRightAnchor')
    Assert-BoostLabCondition ($windowsRunningRuntimeStatusRightAnchor.Count -eq 1) "AXIS Windows Part A running status should keep text near the action row: $windowsStepId"
    $windowsRuntimeNoClippingMarkers = @{
        'game-mode' = 'AxisFirstUseWizard.WindowsGameModeRuntimeStatusNoClipping'
        'pointer-precision' = 'AxisFirstUseWizard.WindowsPointerPrecisionRuntimeStatusNoClipping'
    }
    $windowsRuntimeNoClippingTextWidths = @{
        'game-mode' = 174.0
        'pointer-precision' = 152.0
    }
    if ($windowsRuntimeNoClippingMarkers.ContainsKey($windowsStepId)) {
        $windowsRuntimeNoClippingMarker = [string]$windowsRuntimeNoClippingMarkers[$windowsStepId]
        $windowsRunningRuntimeStatusContent = @(Get-AxisFirstUseWizardTaggedElements -Root $windowsRuntimeStatusArea -Tag 'AxisFirstUseWizard.RuntimeStatusContent.Checking') | Select-Object -First 1
        Assert-BoostLabCondition ([bool]$windowsRuntimeStatusArea.Resources[$windowsRuntimeNoClippingMarker]) "AXIS Windows Part A runtime status panel should expose the step-specific no-clipping marker: $windowsStepId"
        Assert-BoostLabCondition ([bool]$windowsRunningRuntimeStatusContent.Resources[$windowsRuntimeNoClippingMarker]) "AXIS Windows Part A runtime status content should expose the step-specific no-clipping marker: $windowsStepId"
        [void](Assert-AxisFirstUseWizardRightAnchor -Anchor $windowsRunningRuntimeStatusRightAnchor[0] -Name "$windowsStepId running runtime status" -ExpectedMaxWidth ([double]$windowsRuntimeNoClippingTextWidths[$windowsStepId]))
    }
    Assert-BoostLabCondition (Wait-AxisFirstUseWizardCondition -Condition { [bool]$windowsContinueButton.IsEnabled } -TimeoutMilliseconds 3000) "AXIS Windows Part A should enable Next after simulated completion: $windowsStepId"
    $windowsCompletedText = (Get-AxisFirstUseWizardTextValues -Root $windowsVisibleContent) -join [Environment]::NewLine
    Assert-BoostLabCondition ($windowsCompletedText.Contains([string]$windowsSpec['Completed'])) "AXIS Windows Part A should end in owner-approved completed status: $windowsStepId"
    Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $windowsRuntimeStatusArea -Tag 'AxisFirstUseWizard.CompletedEffect').Count -eq 1) "AXIS Windows Part A completed state should render the completed runtime effect: $windowsStepId"
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($windowsContinueButton) -eq 'AxisFirstUseWizard.EnabledNextButtonBlue') "AXIS Windows Part A Next should become blue after simulated completion: $windowsStepId"

    if ($windowsStepId -eq 'bloatware') {
        Invoke-AxisFirstUseWizardButtonClick -Button $windowsContinueButton
        Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $windowsContentHost.Child -Tag 'AxisFirstUseWizard.WindowsGameBarStep').Count -eq 1) 'AXIS Bloatware Continue/Next should navigate to the first Windows Part B step.'
    }
    elseif ($windowsStepId -eq 'cleanup') {
        Invoke-AxisFirstUseWizardButtonClick -Button $windowsContinueButton
        Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $windowsContentHost.Child -Tag 'AxisFirstUseWizard.AdvancedTimerResolutionAssistantStep').Count -eq 1) 'AXIS Cleanup Continue/Next should navigate to the first Advanced step.'
    }
}

foreach ($advancedSpec in $advancedStepSpecs) {
    $advancedStepId = [string]$advancedSpec['Id']
    $advancedTagRoot = [string]$advancedSpec['TagRoot']
    $advancedSampleState = Get-AxisFirstUseWizardSampleState
    $advancedStepIds = @($advancedSampleState['Steps'] | ForEach-Object { [string]$_['Id'] })
    $advancedStepIndex = [Array]::IndexOf($advancedStepIds, $advancedStepId)
    Assert-BoostLabCondition ($advancedStepIndex -ge 0) "AXIS Advanced render test should find step: $advancedStepId"
    $advancedSampleState['CurrentStepIndex'] = $advancedStepIndex
    $advancedPrototype = New-AxisFirstUseWizardPrototype -SampleState $advancedSampleState
    $advancedContentHost = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedPrototype -Tag 'AxisFirstUseWizard.StepContentHost') | Select-Object -First 1
    $advancedContinueButton = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedPrototype -Tag 'AxisFirstUseWizard.ContinueButton') | Select-Object -First 1
    $advancedVisibleContent = $advancedContentHost.Child
    $advancedVisibleText = (Get-AxisFirstUseWizardTextValues -Root $advancedVisibleContent) -join [Environment]::NewLine
    $advancedStepElement = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedVisibleContent -Tag "AxisFirstUseWizard.${advancedTagRoot}Step") | Select-Object -First 1
    $advancedTitleText = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedVisibleContent -Tag "AxisFirstUseWizard.${advancedTagRoot}TitleText") | Select-Object -First 1
    $advancedDetailsGrid = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedVisibleContent -Tag "AxisFirstUseWizard.${advancedTagRoot}StepDetails") | Select-Object -First 1
    $advancedInformationCard = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedVisibleContent -Tag "AxisFirstUseWizard.${advancedTagRoot}InformationCard") | Select-Object -First 1
    $advancedRequirementsCard = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedVisibleContent -Tag "AxisFirstUseWizard.${advancedTagRoot}RequirementsCard") | Select-Object -First 1
    $advancedInformationSharedRightEdge = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedVisibleContent -Tag "AxisFirstUseWizard.${advancedTagRoot}InformationSharedPhysicalRightEdge") | Select-Object -First 1
    $advancedRequirementsSharedRightEdge = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedVisibleContent -Tag "AxisFirstUseWizard.${advancedTagRoot}RequirementsSharedPhysicalRightEdge") | Select-Object -First 1
    $advancedPrimaryButton = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedVisibleContent -Tag 'AxisFirstUseWizard.PrimaryOpenButton') | Select-Object -First 1
    $advancedRuntimeStatusArea = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedVisibleContent -Tag 'AxisFirstUseWizard.RuntimeStatusArea') | Select-Object -First 1
    $advancedRuntimeStatusSpacer = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedVisibleContent -Tag 'AxisFirstUseWizard.ActionRuntimeStatusSpacer') | Select-Object -First 1
    $advancedSupportPanel = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedVisibleContent -Tag 'AxisFirstUseWizard.SupportPanel') | Select-Object -First 1
    $advancedDocumentationButton = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedVisibleContent -Tag 'AxisFirstUseWizard.DocumentationButton') | Select-Object -First 1
    $advancedStageHeader = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedPrototype -Tag 'AxisFirstUseWizard.CurrentStageHeader') | Select-Object -First 1
    $advancedCheckFill = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Check') | Select-Object -First 1
    $advancedRefreshFill = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Refresh') | Select-Object -First 1
    $advancedSetupFill = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Setup') | Select-Object -First 1
    $advancedInstallersFill = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Installers') | Select-Object -First 1
    $advancedGraphicsFill = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Graphics') | Select-Object -First 1
    $advancedWindowsFill = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Windows') | Select-Object -First 1
    $advancedAdvancedFill = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Advanced') | Select-Object -First 1

    Assert-BoostLabCondition ($advancedStepElement -is [System.Windows.Controls.Border]) "AXIS Advanced step should render a step card: $advancedStepId"
    Assert-BoostLabCondition ([double]$advancedStepElement.Height -eq 382.0) "AXIS Advanced step should fit inside the 900x650 preview client area: $advancedStepId"
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($advancedStepElement) -eq 'AxisFirstUseWizard.AdvancedStageBatchPrototypeOnly') "AXIS Advanced step should expose prototype-only batch marker: $advancedStepId"
    Assert-BoostLabCondition ([string](Get-AxisFirstUseWizardTextBlockPlainText -TextBlock $advancedTitleText) -eq [string]$advancedSpec['Title']) "AXIS Advanced visible title changed: $advancedStepId"
    Assert-BoostLabCondition ($advancedTitleText.FlowDirection -eq [System.Windows.FlowDirection]::LeftToRight) "AXIS Advanced English-only title should render LTR while right-anchored: $advancedStepId"
    Assert-BoostLabCondition ([string]$advancedPrimaryButton.Content -eq [string]$advancedSpec['Primary']) "AXIS Advanced primary button text changed: $advancedStepId"
    Assert-BoostLabCondition ([bool]$advancedPrimaryButton.Resources['AxisFirstUseWizard.AdvancedPrimaryActionSharedNoClippingSizing']) "AXIS Advanced primary button should use shared no-clipping sizing: $advancedStepId"
    Assert-BoostLabCondition ([double]$advancedPrimaryButton.Width -ge 232.0) "AXIS Advanced primary button should keep enough width for its full label: $advancedStepId"
    Assert-BoostLabCondition (-not [bool]$advancedContinueButton.IsEnabled) "AXIS Advanced Next should start disabled until simulated completion: $advancedStepId"
    Assert-BoostLabCondition ($advancedRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) "AXIS Advanced runtime status should start hidden: $advancedStepId"
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($advancedRuntimeStatusArea) -eq 'AxisFirstUseWizard.AdvancedRuntimeStatusNoClipping') "AXIS Advanced runtime status should expose no-clipping marker: $advancedStepId"
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($advancedSupportPanel) -eq 'AxisFirstUseWizard.AdvancedSupportCardNoClipping') "AXIS Advanced support panel should expose no-clipping marker: $advancedStepId"
    Assert-BoostLabCondition ([double]$advancedSupportPanel.MinHeight -eq 52.0) "AXIS Advanced support panel should use compact no-clipping height: $advancedStepId"
    Assert-BoostLabCondition ([double]$advancedSupportPanel.Padding.Top -eq 6.0 -and [double]$advancedSupportPanel.Padding.Bottom -eq 6.0) "AXIS Advanced support panel should keep compact internal padding: $advancedStepId"
    Assert-BoostLabCondition ([double]$advancedSupportPanel.Margin.Top -eq 4.0) "AXIS Advanced support panel should avoid bottom clipping with a compact top margin: $advancedStepId"
    Assert-BoostLabCondition ([string]$advancedStageHeader.Text -eq 'Advanced') "AXIS Advanced current stage header should show Advanced: $advancedStepId"
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $advancedCheckFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Check' -ExpectedColor '#FF22C55E' -Name "$advancedStepId Check completed")
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $advancedRefreshFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Refresh' -ExpectedColor '#FF22C55E' -Name "$advancedStepId Refresh completed")
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $advancedSetupFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Setup' -ExpectedColor '#FF22C55E' -Name "$advancedStepId Setup completed")
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $advancedInstallersFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Installers' -ExpectedColor '#FF22C55E' -Name "$advancedStepId Installers completed")
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $advancedGraphicsFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Graphics' -ExpectedColor '#FF22C55E' -Name "$advancedStepId Graphics completed")
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $advancedWindowsFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Windows' -ExpectedColor '#FF22C55E' -Name "$advancedStepId Windows completed")
    [void](Assert-AxisFirstUseWizardStageLineState -Fill $advancedAdvancedFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineActiveFullWhite.Advanced' -ExpectedColor '#FFF0F2F5' -Name "$advancedStepId Advanced active")

    foreach ($requiredAdvancedText in @(
        'Advanced'
        [string]$advancedSpec['Title']
        [string]$advancedSpec['Subtitle']
        [string]$advancedSpec['InfoTitle']
        @($advancedSpec['InfoItems'])
        @($advancedSpec['Requirements'])
        [string]$advancedSpec['Primary']
        $arabicDocumentation
        $arabicSupportTitle
        $arabicSupportBody
    )) {
        foreach ($requiredAdvancedTextItem in @($requiredAdvancedText)) {
            if ([string]::IsNullOrWhiteSpace([string]$requiredAdvancedTextItem)) {
                continue
            }
            $requiredAdvancedTextNormalized = ConvertTo-AxisFirstUseWizardNormalizedText -Text ([string]$requiredAdvancedTextItem)
            $advancedVisibleTextNormalized = ConvertTo-AxisFirstUseWizardNormalizedText -Text $advancedVisibleText
            Assert-BoostLabCondition (
                $advancedVisibleText.Contains([string]$requiredAdvancedTextItem) -or
                $advancedVisibleTextNormalized.Contains($requiredAdvancedTextNormalized)
            ) "AXIS Advanced view is missing owner-approved text for ${advancedStepId}: $requiredAdvancedTextItem"
        }
    }
    Assert-BoostLabCondition (-not $advancedVisibleText.Contains([string][char]0xFFFD)) "AXIS Advanced visible copy must not contain replacement glyphs: $advancedStepId"
    Assert-BoostLabCondition (-not $advancedVisibleText.Contains('BoostLab')) "AXIS Advanced normal customer UI must not expose BoostLab branding: $advancedStepId"
    foreach ($forbiddenAdvancedVisibleText in @('Analyze', 'Default', 'Restore', 'Cancel', 'Skip', 'Skipped', 'Completed with notes', 'PowerShell', 'Registry', 'TrustedInstaller', 'logs', 'diagnostics')) {
        Assert-BoostLabCondition (-not $advancedVisibleText.Contains($forbiddenAdvancedVisibleText)) "AXIS Advanced view exposes forbidden customer text for ${advancedStepId}: $forbiddenAdvancedVisibleText"
    }
    Assert-BoostLabCondition ($advancedRuntimeStatusArea -ne $advancedSupportPanel) "AXIS Advanced runtime status must remain separate from support panel: $advancedStepId"
    Assert-BoostLabCondition ($null -ne $advancedDocumentationButton) "AXIS Advanced documentation button is missing: $advancedStepId"
    Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $advancedVisibleContent -Tag 'AxisFirstUseWizard.AutoUnattendInputOverlay').Count -eq 0) "AXIS Advanced content must not include an input overlay: $advancedStepId"
    Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTypedElements -Root $advancedVisibleContent -Type ([System.Windows.Controls.Image])).Count -eq 0) "AXIS Advanced content must not render image icons: $advancedStepId"
    Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTypedElements -Root $advancedVisibleContent -Type ([System.Windows.Shapes.Shape])).Count -eq 0) "AXIS Advanced content must not render vector icons: $advancedStepId"
    Assert-BoostLabCondition ($null -ne $advancedInformationSharedRightEdge) "AXIS Advanced information card should use the shared physical right-edge text renderer: $advancedStepId"
    Assert-BoostLabCondition ([string]$advancedInformationSharedRightEdge.Resources[$axisSharedCardBodyTextRendererMarker] -eq 'RightAlignedVisualLines') "AXIS Advanced information cards should use shared right-aligned visual lines: $advancedStepId"
    Assert-BoostLabCondition ([bool]$advancedInformationSharedRightEdge.Resources[$axisSharedCardBodyNoLeftFloatingMarker]) "AXIS Advanced information cards should prevent left-floating wrapped Arabic lines: $advancedStepId"
    Assert-BoostLabCondition ([bool]$advancedInformationSharedRightEdge.Resources[$axisSharedCardBodyMixedBidiMarker]) "AXIS Advanced information cards should use the mixed BiDi-safe visual-line path: $advancedStepId"
    Assert-BoostLabCondition ([string]$advancedInformationSharedRightEdge.Resources[$axisSharedCardBodyFutureGuardMarker] -eq 'GraphicsWindowsAdvanced') "AXIS shared card renderer should guard future Graphics/Windows/Advanced batches: $advancedStepId"

    $advancedInformationBodyLines = @(
        Get-AxisFirstUseWizardTypedElements -Root $advancedInformationSharedRightEdge -Type ([System.Windows.Controls.TextBlock]) |
            Where-Object { [string]$_.Tag -like "AxisFirstUseWizard.${advancedTagRoot}InformationItem*" }
    )
    Assert-BoostLabCondition ($advancedInformationBodyLines.Count -ge @($advancedSpec['InfoItems']).Count) "AXIS Advanced information body lines should render approved bullets: $advancedStepId"
    foreach ($advancedInformationBodyLine in $advancedInformationBodyLines) {
        Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($advancedInformationBodyLine) -eq $axisSetupRightAlignedVisualLineRendererAutomationId) "AXIS Advanced information body line should use the safe no-left-floating marker: $advancedStepId"
        Assert-BoostLabCondition ($advancedInformationBodyLine.TextWrapping -eq [System.Windows.TextWrapping]::NoWrap) "AXIS Advanced information body line should bypass automatic WPF wrapping: $advancedStepId"
        Assert-BoostLabCondition ($advancedInformationBodyLine.TextAlignment -eq [System.Windows.TextAlignment]::Right) "AXIS Advanced information body line should stay right-aligned: $advancedStepId"
        Assert-BoostLabCondition ($advancedInformationBodyLine.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) "AXIS Advanced information body line should stay physically anchored right: $advancedStepId"
        Assert-BoostLabCondition ($advancedInformationBodyLine.FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) "AXIS Advanced information body line should remain RTL-shaped: $advancedStepId"
    }

    $advancedInfoMeasureWidth = if (@($advancedSpec['Requirements']).Count -gt 0) { 340.0 } else { 650.0 }
    $advancedInformationSharedRightEdge.Measure([System.Windows.Size]::new($advancedInfoMeasureWidth, [double]::PositiveInfinity))
    $advancedInformationInnerHeight = [double]$advancedInformationCard.Height -
        [double]$advancedInformationCard.Padding.Top -
        [double]$advancedInformationCard.Padding.Bottom -
        [double]$advancedInformationCard.BorderThickness.Top -
        [double]$advancedInformationCard.BorderThickness.Bottom
    Assert-BoostLabCondition ([double]$advancedInformationSharedRightEdge.DesiredSize.Height -le $advancedInformationInnerHeight) "AXIS Advanced information card text should fit without top/bottom clipping: $advancedStepId"

    $advancedContentGrid = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedVisibleContent -Tag 'AxisFirstUseWizard.StepTextContent') | Select-Object -First 1
    $advancedStepElement.Measure([System.Windows.Size]::new(826.0, 389.0))
    $advancedRowTotal = 0.0
    foreach ($advancedRowChild in @($advancedContentGrid.Children)) {
        $advancedRowChild.Measure([System.Windows.Size]::new(758.0, [double]::PositiveInfinity))
        $advancedRowTotal += [double]$advancedRowChild.DesiredSize.Height
    }
    $advancedInnerHeight = [double]$advancedStepElement.Height -
        [double]$advancedStepElement.Padding.Top -
        [double]$advancedStepElement.Padding.Bottom -
        [double]$advancedStepElement.BorderThickness.Top -
        [double]$advancedStepElement.BorderThickness.Bottom
    Assert-BoostLabCondition ($advancedRowTotal -le $advancedInnerHeight) "AXIS Advanced row content should fit without clipped information/support/footer content: $advancedStepId"

    if (@($advancedSpec['Requirements']).Count -gt 0) {
        Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($advancedDetailsGrid) -eq 'AxisFirstUseWizard.AdvancedCardsPhysicalOrderInfoRightRequirementsLeft') "AXIS Advanced should mark physical info-right requirements-left order: $advancedStepId"
        Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($advancedInformationCard) -eq 2) "AXIS Advanced information card should be physical right: $advancedStepId"
        Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($advancedRequirementsCard) -eq 0) "AXIS Advanced requirements card should be physical left: $advancedStepId"
        Assert-BoostLabCondition ($null -ne $advancedRequirementsSharedRightEdge) "AXIS Advanced requirements card should use the shared physical right-edge text renderer: $advancedStepId"
        Assert-BoostLabCondition ([string]$advancedRequirementsSharedRightEdge.Resources[$axisSharedCardBodyTextRendererMarker] -eq 'RightAlignedVisualLines') "AXIS Advanced requirements cards should use shared right-aligned visual lines: $advancedStepId"
        Assert-BoostLabCondition ([bool]$advancedRequirementsSharedRightEdge.Resources[$axisSharedCardBodyNoLeftFloatingMarker]) "AXIS Advanced requirements cards should prevent left-floating wrapped Arabic lines: $advancedStepId"
        Assert-BoostLabCondition ([bool]$advancedRequirementsSharedRightEdge.Resources[$axisSharedCardBodyMixedBidiMarker]) "AXIS Advanced requirements cards should use the mixed BiDi-safe visual-line path: $advancedStepId"
        $advancedRequirementsSharedRightEdge.Measure([System.Windows.Size]::new(340.0, [double]::PositiveInfinity))
        $advancedRequirementsInnerHeight = [double]$advancedRequirementsCard.Height -
            [double]$advancedRequirementsCard.Padding.Top -
            [double]$advancedRequirementsCard.Padding.Bottom -
            [double]$advancedRequirementsCard.BorderThickness.Top -
            [double]$advancedRequirementsCard.BorderThickness.Bottom
        Assert-BoostLabCondition ([double]$advancedRequirementsSharedRightEdge.DesiredSize.Height -le $advancedRequirementsInnerHeight) "AXIS Advanced requirements card text should fit without top/bottom clipping: $advancedStepId"
    }
    else {
        Assert-BoostLabCondition ($null -eq $advancedRequirementsCard) "AXIS Advanced no-requirements step must not render a requirements card: $advancedStepId"
        Assert-BoostLabCondition ([System.Windows.Controls.Grid]::GetColumn($advancedInformationCard) -eq 0) "AXIS Advanced single information card should use the only details column: $advancedStepId"
    }

    $advancedOverlays = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedPrototype -Tag 'AxisFirstUseWizard.ConfirmationOverlay')
    if ([bool]$advancedSpec['Overlay']) {
        Invoke-AxisFirstUseWizardButtonClick -Button $advancedPrimaryButton
        $visibleAdvancedOverlays = @($advancedOverlays | Where-Object { $_.Visibility -eq [System.Windows.Visibility]::Visible })
        Assert-BoostLabCondition ($visibleAdvancedOverlays.Count -eq 1) "AXIS Advanced primary should reveal one confirmation overlay only: $advancedStepId"
        $advancedOverlay = $visibleAdvancedOverlays[0]
        $advancedOverlayText = (Get-AxisFirstUseWizardTextValues -Root $advancedOverlay) -join [Environment]::NewLine
        Assert-BoostLabCondition ($advancedOverlayText.Contains($arabicAcknowledgement)) "AXIS Advanced overlay should show acknowledgement copy: $advancedStepId"
        Assert-BoostLabCondition ($advancedOverlayText.Contains([string]$advancedSpec['Primary'])) "AXIS Advanced overlay should show matching primary copy: $advancedStepId"
        Assert-BoostLabCondition ($advancedOverlayText.Contains($arabicReturn)) "AXIS Advanced overlay should show Return copy: $advancedStepId"
        Assert-BoostLabCondition (-not $advancedOverlayText.Contains('Cancel')) "AXIS Advanced overlay must not show Cancel: $advancedStepId"
        $advancedOverlayAcknowledgement = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedOverlay -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgement') | Select-Object -First 1
        $advancedOverlayOpenButton = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedOverlay -Tag 'AxisFirstUseWizard.ConfirmationOpenButton') | Select-Object -First 1
        $advancedOverlayReturnButton = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedOverlay -Tag 'AxisFirstUseWizard.ConfirmationReturnButton') | Select-Object -First 1
        $advancedOverlayButtonArea = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedOverlay -Tag 'AxisFirstUseWizard.ConfirmationButtonArea') | Select-Object -First 1
        $advancedOverlayReturnSpacer = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedOverlay -Tag 'AxisFirstUseWizard.ConfirmationReturnButtonSpacer') | Select-Object -First 1
        Assert-BoostLabCondition ([string]$advancedOverlayOpenButton.Content -eq [string]$advancedSpec['Primary']) "AXIS Advanced confirmation primary text changed for $advancedStepId."
        Assert-BoostLabCondition ([string]$advancedOverlayReturnButton.Content -eq $arabicReturn) "AXIS Advanced confirmation Return text changed for $advancedStepId."
        Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($advancedOverlayButtonArea) -eq 'AxisFirstUseWizard.ConfirmationButtonAreaNoClipping') "AXIS Advanced confirmation button row should expose the shared no-clipping marker: $advancedStepId"
        Assert-BoostLabCondition ([double]$advancedOverlayReturnButton.Width -ge 118.0) "AXIS Advanced confirmation Return button should be wide enough for unclipped Arabic text: $advancedStepId"
        Assert-BoostLabCondition ([double]$advancedOverlayReturnSpacer.Width -eq 16.0) "AXIS Advanced confirmation buttons should keep the shared no-clipping gap: $advancedStepId"
        Assert-BoostLabCondition ([double]$advancedOverlayButtonArea.MinWidth -ge ([double]$advancedOverlayOpenButton.Width + [double]$advancedOverlayReturnSpacer.Width + [double]$advancedOverlayReturnButton.Width)) "AXIS Advanced confirmation button row should reserve enough width for the primary and Return buttons: $advancedStepId"
        Assert-BoostLabCondition (-not $advancedOverlayText.Contains([string][char]0xFFFD)) "AXIS Advanced overlay should not contain replacement glyphs: $advancedStepId"
        if ($advancedStepId -eq 'defender-optimize-assistant') {
            Assert-BoostLabCondition ([string]$advancedOverlayOpenButton.Content -eq 'Apply Defender Optimize') 'AXIS Defender Optimize overlay primary should stay exactly Apply Defender Optimize.'
            Assert-BoostLabCondition ([string]$advancedOverlayReturnButton.Content -eq $arabicReturn) 'AXIS Defender Optimize overlay Return should stay exactly the owner-approved Arabic Return.'
            Assert-BoostLabCondition (-not $advancedOverlayText.Contains('BoostLab')) 'AXIS Defender Optimize overlay must not expose BoostLab customer-facing text.'
            Assert-BoostLabCondition (-not $advancedOverlayText.Contains('Cancel')) 'AXIS Defender Optimize overlay must not show Cancel.'
        }
        Assert-BoostLabCondition (-not [bool]$advancedOverlayOpenButton.IsEnabled) "AXIS Advanced confirmation should start disabled until acknowledgement: $advancedStepId"
        Invoke-AxisFirstUseWizardButtonClick -Button $advancedOverlayReturnButton
        Assert-BoostLabCondition ($advancedOverlay.Visibility -eq [System.Windows.Visibility]::Collapsed) "AXIS Advanced Return should close only the overlay: $advancedStepId"
        Assert-BoostLabCondition (-not [bool]$advancedContinueButton.IsEnabled) "AXIS Advanced Return must not enable Next: $advancedStepId"
        Assert-BoostLabCondition ($advancedRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Collapsed) "AXIS Advanced Return must not start runtime status: $advancedStepId"
        Invoke-AxisFirstUseWizardButtonClick -Button $advancedPrimaryButton
        $visibleAdvancedOverlays = @($advancedOverlays | Where-Object { $_.Visibility -eq [System.Windows.Visibility]::Visible })
        $advancedOverlay = $visibleAdvancedOverlays[0]
        $advancedOverlayAcknowledgement = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedOverlay -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgement') | Select-Object -First 1
        $advancedOverlayOpenButton = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedOverlay -Tag 'AxisFirstUseWizard.ConfirmationOpenButton') | Select-Object -First 1
        $advancedOverlayAcknowledgement.IsChecked = $true
        Assert-BoostLabCondition ([bool]$advancedOverlayOpenButton.IsEnabled) "AXIS Advanced confirmation should enable after acknowledgement: $advancedStepId"
        Assert-AxisFirstUseWizardNextDisabledNonBlue -Button $advancedContinueButton -Name "$advancedStepId after confirmation acknowledgement"
        Invoke-AxisFirstUseWizardButtonClick -Button $advancedOverlayOpenButton
        Assert-BoostLabCondition ($advancedOverlay.Visibility -eq [System.Windows.Visibility]::Collapsed) "AXIS Advanced confirmation should close before simulation: $advancedStepId"
    }
    else {
        Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $advancedVisibleContent -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgement').Count -eq 0) "AXIS Advanced content must not include a confirmation checkbox: $advancedStepId"
        Invoke-AxisFirstUseWizardButtonClick -Button $advancedPrimaryButton
        $visibleAdvancedOverlays = @($advancedOverlays | Where-Object { $_.Visibility -eq [System.Windows.Visibility]::Visible })
        Assert-BoostLabCondition ($visibleAdvancedOverlays.Count -eq 0) "AXIS Advanced no-overlay step should not reveal a confirmation overlay: $advancedStepId"
    }

    Assert-BoostLabCondition ($advancedRuntimeStatusArea.Visibility -eq [System.Windows.Visibility]::Visible) "AXIS Advanced simulated action should show runtime status: $advancedStepId"
    Assert-BoostLabCondition ($advancedRuntimeStatusSpacer.Visibility -eq [System.Windows.Visibility]::Visible) "AXIS Advanced runtime spacer should be visible during simulation: $advancedStepId"
    $advancedRunningText = (Get-AxisFirstUseWizardTextValues -Root $advancedVisibleContent) -join [Environment]::NewLine
    Assert-BoostLabCondition ($advancedRunningText.Contains([string]$advancedSpec['Running'])) "AXIS Advanced should show owner-approved running status: $advancedStepId"
    Assert-BoostLabCondition ($advancedRunningText.Contains($arabicSupportBody)) "AXIS Advanced support panel should remain visible during simulation: $advancedStepId"
    $advancedRunningRuntimeStatusRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $advancedRuntimeStatusArea -Tag 'AxisFirstUseWizard.RuntimeStatusArabicRightAnchor')
    Assert-BoostLabCondition ($advancedRunningRuntimeStatusRightAnchor.Count -eq 1) "AXIS Advanced running status should keep text near the action row: $advancedStepId"
    [void](Assert-AxisFirstUseWizardRightAnchor -Anchor $advancedRunningRuntimeStatusRightAnchor[0] -Name "$advancedStepId running runtime status" -ExpectedMaxWidth 126)
    Assert-BoostLabCondition (Wait-AxisFirstUseWizardCondition -Condition { [bool]$advancedContinueButton.IsEnabled } -TimeoutMilliseconds 3000) "AXIS Advanced should enable Next after simulated completion: $advancedStepId"
    $advancedCompletedText = (Get-AxisFirstUseWizardTextValues -Root $advancedVisibleContent) -join [Environment]::NewLine
    Assert-BoostLabCondition ($advancedCompletedText.Contains([string]$advancedSpec['Completed'])) "AXIS Advanced should end in owner-approved completed status: $advancedStepId"
    Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $advancedRuntimeStatusArea -Tag 'AxisFirstUseWizard.CompletedEffect').Count -eq 1) "AXIS Advanced completed state should render the completed runtime effect: $advancedStepId"
    Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($advancedContinueButton) -eq 'AxisFirstUseWizard.EnabledNextButtonBlue') "AXIS Advanced Next should become blue after simulated completion: $advancedStepId"
    if ($advancedStepId -eq 'timer-resolution-assistant') {
        Invoke-AxisFirstUseWizardButtonClick -Button $advancedContinueButton
        Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $advancedContentHost.Child -Tag 'AxisFirstUseWizard.AdvancedDefenderOptimizeAssistantStep').Count -eq 1) 'AXIS Timer Resolution Assistant Continue/Next should navigate to Defender Optimize Assistant.'
    }
    elseif ($advancedStepId -eq 'defender-optimize-assistant') {
        Invoke-AxisFirstUseWizardButtonClick -Button $advancedContinueButton
        Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $advancedContentHost.Child -Tag 'AxisFirstUseWizard.FinalCompletionPage').Count -eq 1) 'AXIS Defender Optimize Assistant Continue/Next should navigate to the final completion page.'
    }
}

function New-AxisFirstUseWizardPreviewScopedPrototypeForTest {
    param(
        [Parameter(Mandatory)]
        [string]$PrototypeScriptPath
    )

    . $PrototypeScriptPath
    return New-AxisFirstUseWizardPrototype -SampleState (Get-AxisFirstUseWizardSampleState)
}

if ($null -ne (Get-Command -Name 'Set-AxisStageProgressStripActiveStage' -CommandType Function -ErrorAction SilentlyContinue)) {
    Remove-Item -LiteralPath 'Function:\Set-AxisStageProgressStripActiveStage' -Force
}

$previewScopedPrototype = New-AxisFirstUseWizardPreviewScopedPrototypeForTest -PrototypeScriptPath $prototypePath
Assert-BoostLabCondition (
    $null -eq (Get-Command -Name 'Set-AxisStageProgressStripActiveStage' -CommandType Function -ErrorAction SilentlyContinue)
) 'AXIS preview-scope navigation smoke test should run without a global stage-strip helper function.'
$previewScopedContentHost = @(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedPrototype -Tag 'AxisFirstUseWizard.StepContentHost') | Select-Object -First 1
$previewScopedContinueButton = @(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedPrototype -Tag 'AxisFirstUseWizard.ContinueButton') | Select-Object -First 1
$previewScopedBackButton = @(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedPrototype -Tag 'AxisFirstUseWizard.BackButton') | Select-Object -First 1
$previewScopedStageHeader = @(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedPrototype -Tag 'AxisFirstUseWizard.CurrentStageHeader') | Select-Object -First 1
$previewScopedCheckFill = @(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Check') | Select-Object -First 1
$previewScopedRefreshFill = @(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedPrototype -Tag 'AxisFirstUseWizard.StageProgressFill.Refresh') | Select-Object -First 1
$previewScopedOverlays = @(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedPrototype -Tag 'AxisFirstUseWizard.ConfirmationOverlay')
Assert-BoostLabCondition ($null -ne $previewScopedContentHost) 'AXIS preview-scope smoke test content host is missing.'
Assert-BoostLabCondition ($null -ne $previewScopedContinueButton) 'AXIS preview-scope smoke test Continue/Next button is missing.'
Assert-BoostLabCondition ($null -ne $previewScopedBackButton) 'AXIS preview-scope smoke test Back button is missing.'
$previewScopedIntroStartButton = @(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedContentHost.Child -Tag 'AxisFirstUseWizard.IntroWelcomeStartButton') | Select-Object -First 1
Assert-BoostLabCondition ($previewScopedIntroStartButton -is [System.Windows.Controls.Button]) 'AXIS preview-scope smoke test should start on intro-welcome.'
Invoke-AxisFirstUseWizardButtonClick -Button $previewScopedIntroStartButton
Assert-BoostLabCondition ($previewScopedOverlays.Count -eq 10) 'AXIS preview-scope smoke test should have BIOS Drivers, BIOS Settings, To BIOS, Updates Pause, Driver Clean, GPU Driver Setup, NVIDIA App Install, Bloatware, Edge WebView, and Defender Optimize Assistant confirmation overlays only.'
Assert-BoostLabCondition ([string]$previewScopedStageHeader.Text -eq 'Check') 'AXIS preview-scope smoke test should start on Check.'
[void](Assert-AxisFirstUseWizardStageLineState -Fill $previewScopedCheckFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineActiveFullWhite.Check' -ExpectedColor '#FFF0F2F5' -Name 'preview-scope Check active')
[void](Assert-AxisFirstUseWizardStageLineState -Fill $previewScopedRefreshFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineInactiveDim.Refresh' -ExpectedColor '#FF242424' -Name 'preview-scope Refresh inactive')

$previewScopedFirstPrimary = @(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedContentHost.Child -Tag 'AxisFirstUseWizard.PrimaryOpenButton') | Select-Object -First 1
$previewScopedFirstAcknowledgement = @(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedOverlays[0] -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgement') | Select-Object -First 1
$previewScopedFirstConfirm = @(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedOverlays[0] -Tag 'AxisFirstUseWizard.ConfirmationOpenButton') | Select-Object -First 1
Invoke-AxisFirstUseWizardButtonClick -Button $previewScopedFirstPrimary
$previewScopedFirstAcknowledgement.IsChecked = $true
Invoke-AxisFirstUseWizardButtonClick -Button $previewScopedFirstConfirm
Assert-BoostLabCondition (Wait-AxisFirstUseWizardCondition -Condition { [bool]$previewScopedContinueButton.IsEnabled } -TimeoutMilliseconds 3000) 'AXIS preview-scope BIOS Drivers simulation should enable Continue/Next.'
Invoke-AxisFirstUseWizardButtonClick -Button $previewScopedContinueButton
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedContentHost.Child -Tag 'AxisFirstUseWizard.BiosSettingsStep').Count -eq 1) 'AXIS preview-scope Continue/Next should navigate to BIOS Settings without a missing helper crash.'
Assert-BoostLabCondition ([string]$previewScopedStageHeader.Text -eq 'Check') 'AXIS preview-scope BIOS Settings stage header should remain Check.'
[void](Assert-AxisFirstUseWizardStageLineState -Fill $previewScopedCheckFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineActiveFullWhite.Check' -ExpectedColor '#FFF0F2F5' -Name 'preview-scope BIOS Settings Check active')
[void](Assert-AxisFirstUseWizardStageLineState -Fill $previewScopedRefreshFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineInactiveDim.Refresh' -ExpectedColor '#FF242424' -Name 'preview-scope BIOS Settings Refresh inactive')

$previewScopedSettingsPrimary = @(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedContentHost.Child -Tag 'AxisFirstUseWizard.PrimaryOpenButton') | Select-Object -First 1
$previewScopedSettingsAcknowledgement = @(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedOverlays[1] -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgement') | Select-Object -First 1
$previewScopedSettingsConfirm = @(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedOverlays[1] -Tag 'AxisFirstUseWizard.ConfirmationOpenButton') | Select-Object -First 1
Invoke-AxisFirstUseWizardButtonClick -Button $previewScopedSettingsPrimary
$previewScopedSettingsAcknowledgement.IsChecked = $true
Invoke-AxisFirstUseWizardButtonClick -Button $previewScopedSettingsConfirm
Assert-BoostLabCondition (Wait-AxisFirstUseWizardCondition -Condition { [bool]$previewScopedContinueButton.IsEnabled } -TimeoutMilliseconds 3000) 'AXIS preview-scope BIOS Settings simulation should enable Continue/Next.'
Invoke-AxisFirstUseWizardButtonClick -Button $previewScopedContinueButton
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedContentHost.Child -Tag 'AxisFirstUseWizard.ReinstallStep').Count -eq 1) 'AXIS preview-scope Continue/Next should navigate to Reinstall without a missing helper crash.'
Assert-BoostLabCondition ([string]$previewScopedStageHeader.Text -eq 'Refresh') 'AXIS preview-scope Reinstall stage header should become Refresh.'
[void](Assert-AxisFirstUseWizardStageLineState -Fill $previewScopedCheckFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Check' -ExpectedColor '#FF22C55E' -Name 'preview-scope Reinstall Check completed')
[void](Assert-AxisFirstUseWizardStageLineState -Fill $previewScopedRefreshFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineActiveFullWhite.Refresh' -ExpectedColor '#FFF0F2F5' -Name 'preview-scope Reinstall Refresh active')
$previewScopedReinstallPrimary = @(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedContentHost.Child -Tag 'AxisFirstUseWizard.PrimaryOpenButton') | Select-Object -First 1
Invoke-AxisFirstUseWizardButtonClick -Button $previewScopedReinstallPrimary
Assert-BoostLabCondition (Wait-AxisFirstUseWizardCondition -Condition { [bool]$previewScopedContinueButton.IsEnabled } -TimeoutMilliseconds 3000) 'AXIS preview-scope Reinstall simulation should enable Continue/Next.'
Invoke-AxisFirstUseWizardButtonClick -Button $previewScopedContinueButton
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedContentHost.Child -Tag 'AxisFirstUseWizard.AutoUnattendStep').Count -eq 1) 'AXIS preview-scope Continue/Next should navigate to AutoUnattend without a missing helper crash.'
Assert-BoostLabCondition ([string]$previewScopedStageHeader.Text -eq 'Refresh') 'AXIS preview-scope AutoUnattend stage header should remain Refresh.'
[void](Assert-AxisFirstUseWizardStageLineState -Fill $previewScopedCheckFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Check' -ExpectedColor '#FF22C55E' -Name 'preview-scope AutoUnattend Check completed')
[void](Assert-AxisFirstUseWizardStageLineState -Fill $previewScopedRefreshFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineActiveFullWhite.Refresh' -ExpectedColor '#FFF0F2F5' -Name 'preview-scope AutoUnattend Refresh active')
Assert-BoostLabCondition (-not [bool]$previewScopedContinueButton.IsEnabled) 'AXIS preview-scope AutoUnattend Continue/Next should start disabled.'
$previewScopedAutoPrimary = @(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedContentHost.Child -Tag 'AxisFirstUseWizard.PrimaryOpenButton') | Select-Object -First 1
$previewScopedAutoOverlay = @(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedPrototype -Tag 'AxisFirstUseWizard.AutoUnattendInputOverlay') | Select-Object -First 1
$previewScopedAutoAccount = @(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedAutoOverlay -Tag 'AxisFirstUseWizard.AutoUnattendAccountTextBox') | Select-Object -First 1
$previewScopedAutoUsb = @(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedAutoOverlay -Tag 'AxisFirstUseWizard.AutoUnattendUsbSelector') | Select-Object -First 1
$previewScopedAutoCreate = @(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedAutoOverlay -Tag 'AxisFirstUseWizard.AutoUnattendInputCreateButton') | Select-Object -First 1
Invoke-AxisFirstUseWizardButtonClick -Button $previewScopedAutoPrimary
$previewScopedAutoAccount.Text = 'Yazan'
$previewScopedAutoUsb.SelectedIndex = 0
Assert-BoostLabCondition ([bool]$previewScopedAutoCreate.IsEnabled) 'AXIS preview-scope AutoUnattend input Create should enable for valid mock input.'
Invoke-AxisFirstUseWizardButtonClick -Button $previewScopedAutoCreate
Assert-BoostLabCondition (Wait-AxisFirstUseWizardCondition -Condition { [bool]$previewScopedContinueButton.IsEnabled } -TimeoutMilliseconds 3000) 'AXIS preview-scope AutoUnattend simulation should enable Continue/Next.'
Invoke-AxisFirstUseWizardButtonClick -Button $previewScopedContinueButton
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedContentHost.Child -Tag 'AxisFirstUseWizard.UpdatesDriversStep').Count -eq 1) 'AXIS preview-scope Continue/Next should navigate to Updates Drivers Block without a missing helper crash.'
Assert-BoostLabCondition ([string]$previewScopedStageHeader.Text -eq 'Refresh') 'AXIS preview-scope Updates Drivers Block stage header should remain Refresh.'
[void](Assert-AxisFirstUseWizardStageLineState -Fill $previewScopedCheckFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Check' -ExpectedColor '#FF22C55E' -Name 'preview-scope Updates Drivers Block Check completed')
[void](Assert-AxisFirstUseWizardStageLineState -Fill $previewScopedRefreshFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineActiveFullWhite.Refresh' -ExpectedColor '#FFF0F2F5' -Name 'preview-scope Updates Drivers Block Refresh active')
Assert-BoostLabCondition (-not [bool]$previewScopedContinueButton.IsEnabled) 'AXIS preview-scope Updates Drivers Block Continue/Next should start disabled.'
Invoke-AxisFirstUseWizardButtonClick -Button $previewScopedBackButton
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedContentHost.Child -Tag 'AxisFirstUseWizard.AutoUnattendStep').Count -eq 1) 'AXIS preview-scope Back should navigate from Updates Drivers Block to AutoUnattend without a missing helper crash.'
Assert-BoostLabCondition ([string]$previewScopedStageHeader.Text -eq 'Refresh') 'AXIS preview-scope Back to AutoUnattend should keep Refresh stage header.'
Invoke-AxisFirstUseWizardButtonClick -Button $previewScopedBackButton
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedContentHost.Child -Tag 'AxisFirstUseWizard.ReinstallStep').Count -eq 1) 'AXIS preview-scope Back should navigate from AutoUnattend to Reinstall without a missing helper crash.'
Assert-BoostLabCondition ([string]$previewScopedStageHeader.Text -eq 'Refresh') 'AXIS preview-scope Back to Reinstall should keep Refresh stage header.'
[void](Assert-AxisFirstUseWizardStageLineState -Fill $previewScopedCheckFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineCompletedFullGreen.Check' -ExpectedColor '#FF22C55E' -Name 'preview-scope Back to Reinstall Check completed')
[void](Assert-AxisFirstUseWizardStageLineState -Fill $previewScopedRefreshFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineActiveFullWhite.Refresh' -ExpectedColor '#FFF0F2F5' -Name 'preview-scope Back to Reinstall Refresh active')
Assert-BoostLabCondition ([bool]$previewScopedContinueButton.IsEnabled) 'AXIS preview-scope Back to completed Reinstall should restore enabled Continue/Next.'
Invoke-AxisFirstUseWizardButtonClick -Button $previewScopedBackButton
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $previewScopedContentHost.Child -Tag 'AxisFirstUseWizard.BiosSettingsStep').Count -eq 1) 'AXIS preview-scope Back should navigate from Reinstall to BIOS Settings without a missing helper crash.'
Assert-BoostLabCondition ([string]$previewScopedStageHeader.Text -eq 'Check') 'AXIS preview-scope Back to BIOS Settings should restore Check stage header.'
[void](Assert-AxisFirstUseWizardStageLineState -Fill $previewScopedCheckFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineActiveFullWhite.Check' -ExpectedColor '#FFF0F2F5' -Name 'preview-scope Back Check active')
[void](Assert-AxisFirstUseWizardStageLineState -Fill $previewScopedRefreshFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineInactiveDim.Refresh' -ExpectedColor '#FF242424' -Name 'preview-scope Back Refresh inactive')

$completedSampleState = Copy-AxisWizardMap -Map $sampleState
$completedStep = Copy-AxisWizardMap -Map $biosStep
$completedStep['State'] = 'Completed'
$completedSampleState['Step'] = $completedStep
$completedSampleState['Steps'] = @(
    $completedStep
    $biosSettingsStep
    $reinstallStep
    $autoUnattendStep
    $updatesDriversStep
    $toBiosStep
    $setupSteps
    $installersStep
    $installersExtensionSteps
    $graphicsSteps
    $windowsSteps
)
$completedPrototype = New-AxisFirstUseWizardPrototype -SampleState $completedSampleState
$completedContinueButton = @(Get-AxisFirstUseWizardTaggedElements -Root $completedPrototype -Tag 'AxisFirstUseWizard.ContinueButton') | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $completedContinueButton) 'AXIS completed prototype should include Continue/Next.'
Assert-BoostLabCondition ([bool]$completedContinueButton.IsEnabled) 'AXIS Continue/Next should become enabled after completion.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($completedContinueButton) -eq 'AxisFirstUseWizard.EnabledNextButtonBlue') 'AXIS completed prototype Continue/Next should use the enabled blue marker.'
Assert-BoostLabCondition ([string]([System.Windows.Media.SolidColorBrush]$completedContinueButton.Background).Color -eq '#FF2563EB') 'AXIS completed prototype Continue/Next should use the enabled blue fill.'

$checkingStep = Copy-AxisWizardMap -Map $biosStep
$checkingStep['State'] = 'Checking'
$checkingContent = New-AxisBiosInformationStep -Step $checkingStep -Resources (New-AxisWpfResourceDictionary)
$checkingText = (Get-AxisFirstUseWizardTextValues -Root $checkingContent) -join [Environment]::NewLine
Assert-BoostLabCondition ($checkingText.Contains($arabicChecking)) 'AXIS checking state should use owner-approved Arabic checking text.'
Assert-BoostLabCondition ($checkingText.Contains($arabicSupportBody)) 'AXIS checking state should keep the support panel visible.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $checkingContent -Tag 'AxisFirstUseWizard.CheckingAnimation').Count -eq 1) 'AXIS checking state should render a real WPF animation surface.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $checkingContent -Tag 'AxisFirstUseWizard.CompletedRuntimeSuccessGlow').Count -eq 0) 'AXIS checking state should not show the completed green success glow.'
$checkingRuntimeStatusArea = @(Get-AxisFirstUseWizardTaggedElements -Root $checkingContent -Tag 'AxisFirstUseWizard.RuntimeStatusArea')
$checkingSupportPanel = @(Get-AxisFirstUseWizardTaggedElements -Root $checkingContent -Tag 'AxisFirstUseWizard.SupportPanel')
Assert-BoostLabCondition ($checkingRuntimeStatusArea.Count -eq 1) 'AXIS checking state should include one runtime status area.'
Assert-BoostLabCondition ($checkingSupportPanel.Count -eq 1) 'AXIS checking state should include one separate support panel.'
Assert-BoostLabCondition ($checkingRuntimeStatusArea[0] -ne $checkingSupportPanel[0]) 'AXIS checking runtime status and support panel must be separate containers.'
$checkingRuntimeStatusRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $checkingContent -Tag 'AxisFirstUseWizard.RuntimeStatusArabicRightAnchor')
Assert-BoostLabCondition ($checkingRuntimeStatusRightAnchor.Count -eq 1) 'AXIS checking status text should use a named physical right anchor.'
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $checkingRuntimeStatusRightAnchor[0] -Name 'checking runtime status' -ExpectedMaxWidth 86)

$completedContent = New-AxisBiosInformationStep -Step $completedStep -Resources (New-AxisWpfResourceDictionary)
$completedText = (Get-AxisFirstUseWizardTextValues -Root $completedContent) -join [Environment]::NewLine
Assert-BoostLabCondition ($completedText.Contains($arabicCompleted)) 'AXIS completed state should use owner-approved Arabic completed text.'
Assert-BoostLabCondition ($completedText.Contains($arabicSupportBody)) 'AXIS completed state should keep the support panel visible.'
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $completedContent -Tag 'AxisFirstUseWizard.CompletedEffect').Count -eq 1) 'AXIS completed state should render a completion effect surface.'
$completedSuccessGlow = @(Get-AxisFirstUseWizardTaggedElements -Root $completedContent -Tag 'AxisFirstUseWizard.CompletedRuntimeSuccessGlow')
Assert-BoostLabCondition ($completedSuccessGlow.Count -ge 1) 'AXIS completed state should render the green success glow effect.'
Assert-BoostLabCondition (@($completedSuccessGlow | Where-Object { $null -ne $_.Effect }).Count -ge 1) 'AXIS completed green success glow should carry a WPF effect.'
$completedRuntimeStatusArea = @(Get-AxisFirstUseWizardTaggedElements -Root $completedContent -Tag 'AxisFirstUseWizard.RuntimeStatusArea')
$completedSupportPanel = @(Get-AxisFirstUseWizardTaggedElements -Root $completedContent -Tag 'AxisFirstUseWizard.SupportPanel')
Assert-BoostLabCondition ($completedRuntimeStatusArea.Count -eq 1) 'AXIS completed state should include one runtime status area.'
Assert-BoostLabCondition ($completedSupportPanel.Count -eq 1) 'AXIS completed state should include one separate support panel.'
Assert-BoostLabCondition ($completedRuntimeStatusArea[0] -ne $completedSupportPanel[0]) 'AXIS completed runtime status and support panel must be separate containers.'
$completedRuntimeStatusRightAnchor = @(Get-AxisFirstUseWizardTaggedElements -Root $completedContent -Tag 'AxisFirstUseWizard.RuntimeStatusArabicRightAnchor')
Assert-BoostLabCondition ($completedRuntimeStatusRightAnchor.Count -eq 1) 'AXIS completed status text should use a named physical right anchor.'
[void](Assert-AxisFirstUseWizardRightAnchor -Anchor $completedRuntimeStatusRightAnchor[0] -Name 'completed runtime status' -ExpectedMaxWidth 86)

foreach ($runtimeStatusLabel in @(
    @{ Root = $checkingContent; Text = $arabicChecking },
    @{ Root = $completedContent; Text = $arabicCompleted }
)) {
    $runtimeTextBlocks = @(Get-AxisFirstUseWizardTextBlocksByText -Root $runtimeStatusLabel.Root -Text $runtimeStatusLabel.Text)
    Assert-BoostLabCondition ($runtimeTextBlocks.Count -ge 1) "AXIS runtime status text is missing: $($runtimeStatusLabel.Text)"
    foreach ($textBlock in $runtimeTextBlocks) {
        Assert-BoostLabCondition ($textBlock.FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft) "AXIS runtime status text should use RTL FlowDirection: $($runtimeStatusLabel.Text)"
        Assert-BoostLabCondition ($textBlock.TextAlignment -eq [System.Windows.TextAlignment]::Right) "AXIS runtime status text should be right-aligned: $($runtimeStatusLabel.Text)"
        Assert-BoostLabCondition ($textBlock.HorizontalAlignment -eq [System.Windows.HorizontalAlignment]::Right) "AXIS runtime status text should be physically right-anchored inside its compact runtime status region: $($runtimeStatusLabel.Text)"
        Assert-BoostLabCondition ([string]$textBlock.Tag -eq 'AxisFirstUseWizard.RuntimeStatusArabicTextInset') "AXIS runtime status text should carry the safe inset marker: $($runtimeStatusLabel.Text)"
        Assert-BoostLabCondition ([double]$textBlock.Margin.Right -ge 6.0 -and [double]$textBlock.Margin.Right -le 10.0) "AXIS runtime status text should have a small right inset to prevent first-letter clipping: $($runtimeStatusLabel.Text)"
        Assert-BoostLabCondition ([double]$textBlock.Margin.Left -eq 0.0 -and [double]$textBlock.Margin.Top -eq 0.0 -and [double]$textBlock.Margin.Bottom -eq 0.0) "AXIS runtime status clipping fix should not move text on other sides: $($runtimeStatusLabel.Text)"
    }
}

Assert-BoostLabCondition ($prototypeSource.Contains('DoubleAnimation')) 'AXIS checking/completed status should use WPF animation primitives.'
Assert-BoostLabCondition ($prototypeSource.Contains('BeginAnimation')) 'AXIS checking/completed status should start WPF animation effects.'
foreach ($rejectedPhase177IText in @(
    'New-AxisWizardArabicRightPaddedBlock'
    'ArabicSubtitleRightPaddedBlock'
    'ArabicInfoCardRightPaddedBlock'
    'ArabicSupportRightPaddedBlock'
    'CompactAcknowledgementOverlay'
    '-Width 520'
    '-Width 660'
    'Width = 520'
    'Width = 660'
)) {
    Assert-BoostLabCondition (-not $prototypeSource.Contains($rejectedPhase177IText)) "AXIS first-use wizard must not reintroduce rejected Phase 177I fixed-width/right-padded model text: $rejectedPhase177IText"
}
foreach ($blockedIconSourceText in @(
    'Get-AxisFirstUseWizardIconAssetRoot'
    'Get-AxisFirstUseWizardStepIconAssetPath'
    'New-AxisStepImageIcon'
    'New-AxisStepVectorIcon'
    'New-AxisStepIcon'
    'BitmapImage'
    'System.Windows.Controls.Image'
    'Stretch]::Uniform'
    'DecodePixelWidth'
    'assets\icons'
    'bios-information.png'
    'BiosInformationIcon'
    'StepStatusIndicator'
)) {
    Assert-BoostLabCondition (-not $prototypeSource.Contains($blockedIconSourceText)) "AXIS first-use wizard prototype must remain free of static script icon dependency: $blockedIconSourceText"
}

$imageElements = @(Get-AxisFirstUseWizardTypedElements -Root $prototype -Type ([System.Windows.Controls.Image]))
$canvasElements = @(Get-AxisFirstUseWizardTypedElements -Root $prototype -Type ([System.Windows.Controls.Canvas]))
$shapeElements = @(Get-AxisFirstUseWizardTypedElements -Root $prototype -Type ([System.Windows.Shapes.Shape]))
Assert-BoostLabCondition ($imageElements.Count -eq 0) 'AXIS first-use wizard must not render image icons.'
Assert-BoostLabCondition ($canvasElements.Count -eq 0) 'AXIS first-use wizard must not render WPF canvas/vector icons.'
Assert-BoostLabCondition ($shapeElements.Count -eq 0) 'AXIS first-use wizard must not render WPF shape-based icons.'

foreach ($forbiddenVisibleText in @(
    'Cancel'
    'Analyze'
    'Default'
    'Restore'
    'Ready'
    'Requirements'
    'BIOS Information'
    'BIOS/UEFI version'
    'Motherboard and vendor details'
    'motherboard model'
    'vendor'
    'boot mode'
    'raw command output'
    'diagnostics'
    'Error'
    'Failed'
    'Warning'
    'Needs attention'
    'Stopped'
    'Restart needed'
    'Waiting for confirmation'
    'Not available'
    'Skipped'
    'Completed with notes'
)) {
    Assert-BoostLabCondition (-not ($joinedText -match [regex]::Escape($forbiddenVisibleText))) "AXIS first-use wizard exposes forbidden customer text: $forbiddenVisibleText"
    Assert-BoostLabCondition (-not ($checkingText -match [regex]::Escape($forbiddenVisibleText))) "AXIS checking state exposes forbidden customer text: $forbiddenVisibleText"
    Assert-BoostLabCondition (-not ($completedText -match [regex]::Escape($forbiddenVisibleText))) "AXIS completed state exposes forbidden customer text: $forbiddenVisibleText"
}
foreach ($visibleTextValue in @($texts)) {
    Assert-BoostLabCondition ([string]$visibleTextValue -ne 'Apply') 'AXIS first-use wizard must not expose standalone internal Apply as customer text.'
}

Assert-BoostLabCondition (-not $prototypeSource.Contains('Cancel')) 'AXIS first-use wizard source must not contain a Cancel button path.'
Assert-BoostLabCondition (-not $prototypeSource.Contains('Set-AxisWizardButtonVisualVariant')) 'AXIS checkbox event path must not call the removed helper that crashed the preview.'
Assert-BoostLabCondition (-not $prototypeSource.Contains('Set-AxisStageProgressStripActiveStage')) 'AXIS navigation event path must not call the unavailable stage-strip helper that crashed the preview.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.ReinstallTitleRightAligned')) 'AXIS Reinstall title should expose the right-aligned title marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.AutoUnattendInputOverlay')) 'AXIS AutoUnattend should expose the input overlay marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.AutoUnattendInputCreateDisabledUntilValid')) 'AXIS AutoUnattend input Create button should expose the disabled-until-valid marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.AutoUnattendInputCreateEnabledWithValidMockInput')) 'AXIS AutoUnattend input Create button should expose the valid mock input marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.AutoUnattendInputReturnOnlyClosesOverlay')) 'AXIS AutoUnattend Return should be overlay-only.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.UpdatesDriversStep')) 'AXIS Updates Drivers Block should expose the step marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.UpdatesDriversInputOverlay')) 'AXIS Updates Drivers Block should expose the input overlay marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.UpdatesDriversInputCreateDisabledUntilValid')) 'AXIS Updates Drivers Block input Create button should expose the disabled-until-valid marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.UpdatesDriversInputCreateEnabledWithMockUsbSelection')) 'AXIS Updates Drivers Block input Create button should expose the mock USB selection marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.UpdatesDriversInputReturnOnlyClosesOverlay')) 'AXIS Updates Drivers Block Return should be overlay-only.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.UsbSelectorReadableDarkStyle')) 'AXIS shared USB selector should expose the readable dark style marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.UsbSelectorMockOnly')) 'AXIS shared USB selector should expose the mock-only marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.UsbInputWindowNoRealDriveDetection')) 'AXIS shared USB selector should expose the no-real-drive-detection marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.SelectorPhysicalLeftAboveRequirements')) 'AXIS shared selector rows should expose the physical-left above-requirements marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.UpdatesDriversMixedBidiSafeInfoText')) 'AXIS Updates Drivers Block should expose the mixed BiDi-safe marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.SetupStageBatchPrototypeOnly')) 'AXIS Setup batch should expose the prototype-only batch marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.SetupPrototypeOnlyNoRuntimeAction')) 'AXIS Setup batch should expose the no-real-action marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.SetupRuntimeStatusNoClipping')) 'AXIS Setup runtime status should expose the no-clipping marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.SetupSupportCardNoClipping')) 'AXIS Setup support card should expose the no-clipping marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.SetupCardsPhysicalOrderInfoRightRequirementsLeft')) 'AXIS Setup two-card layout should expose the physical info-right requirements-left marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.EnglishOnlyTitleRightAnchored')) 'AXIS English-only Setup titles should expose the LTR right-anchored marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('Get-AxisWizardGraphicsText')) 'AXIS Graphics batch should expose a dedicated approved-copy text resource helper.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.GraphicsStageBatchPrototypeOnly')) 'AXIS Graphics batch should expose the prototype-only batch marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.GraphicsRuntimeStatusNoClipping')) 'AXIS Graphics runtime status should expose the no-clipping marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.GraphicsSupportCardNoClipping')) 'AXIS Graphics support card should expose the no-clipping marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.GraphicsCardsPhysicalOrderInfoRightRequirementsLeft')) 'AXIS Graphics two-card layout should expose the physical info-right requirements-left marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.GraphicsGpuSelectorNvidiaOnly')) 'AXIS GPU Driver Setup should expose the NVIDIA-only selector marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.GraphicsGpuSelectorAmdIntelDisabled')) 'AXIS GPU Driver Setup should expose disabled AMD/Intel selector marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.GraphicsGpuSetupPrimaryDisabledUntilNvidiaSelected')) 'AXIS GPU Driver Setup should keep primary disabled until NVIDIA is selected.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.GraphicsGpuSelectorPhysicalLeftAboveRequirements')) 'AXIS GPU selector should expose the physical-left above-requirements marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.InstallersSelectorPhysicalLeftAboveRequirements')) 'AXIS Installers selector should expose the physical-left above-requirements marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.NvidiaAppOptionalContinuationNoApplySimulation')) 'AXIS NVIDIA App optional continuation should be marked no-runtime.'
Assert-BoostLabCondition ($prototypeSource.Contains('Get-AxisWizardWindowsText')) 'AXIS Windows Part A batch should expose a dedicated approved-copy text resource helper.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.WindowsStagePartAPrototypeOnly')) 'AXIS Windows Part A batch should expose the prototype-only batch marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.WindowsStagePartBPrototypeOnly')) 'AXIS Windows Part B batch should expose the prototype-only batch marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.WindowsRuntimeStatusNoClipping')) 'AXIS Windows Part A runtime status should expose the no-clipping marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.WindowsSupportCardNoClipping')) 'AXIS Windows Part A support card should expose the no-clipping marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.WindowsCardsPhysicalOrderInfoRightRequirementsLeft')) 'AXIS Windows Part A two-card layout should expose the physical info-right requirements-left marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('Get-AxisWizardAdvancedText')) 'AXIS Advanced batch should expose a dedicated approved-copy text resource helper.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.AdvancedStageBatchPrototypeOnly')) 'AXIS Advanced batch should expose the prototype-only batch marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.AdvancedRuntimeStatusNoClipping')) 'AXIS Advanced runtime status should expose the no-clipping marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.AdvancedSupportCardNoClipping')) 'AXIS Advanced support card should expose the no-clipping marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.AdvancedCardsPhysicalOrderInfoRightRequirementsLeft')) 'AXIS Advanced two-card layout should expose the physical info-right requirements-left marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.AdvancedPrimaryActionSharedNoClippingSizing')) 'AXIS Advanced primary actions should expose shared no-clipping sizing.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.ConfirmationButtonAreaNoClipping')) 'AXIS confirmation overlays should expose the shared button-row no-clipping marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.WindowsBloatwareActionSelectorSingleSelect')) 'AXIS Bloatware should expose the single-select action selector marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.WindowsBloatwareActionSelectorNoRuntimeAction')) 'AXIS Bloatware selector should expose the no-runtime marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.WindowsBloatwarePrimaryDisabledUntilActionSelected')) 'AXIS Bloatware should keep primary disabled until an action is selected.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.WindowsBloatwarePrototypeOnlyNoRuntimeAction')) 'AXIS Bloatware should expose the no-real-action marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.WindowsBloatwareSelectorPhysicalLeftAboveRequirements')) 'AXIS Bloatware selector should expose the physical-left above-requirements marker.'
foreach ($windowsPartBNoRuntimeMarker in @(
    'AxisFirstUseWizard.WindowsGameBarPrototypeOnlyNoRuntimeAction',
    'AxisFirstUseWizard.WindowsEdgeWebViewPrototypeOnlyNoRuntimeAction',
    'AxisFirstUseWizard.WindowsNotepadSettingsPrototypeOnlyNoRuntimeAction',
    'AxisFirstUseWizard.WindowsControlPanelSettingsPrototypeOnlyNoRuntimeAction',
    'AxisFirstUseWizard.WindowsInputLanguageHotkeyPrototypeOnlyNoRuntimeAction',
    'AxisFirstUseWizard.WindowsSoundPrototypeOnlyNoRuntimeAction',
    'AxisFirstUseWizard.WindowsDeviceManagerPowerSavingsWakePrototypeOnlyNoRuntimeAction',
    'AxisFirstUseWizard.WindowsNetworkAdapterPowerSavingsWakePrototypeOnlyNoRuntimeAction',
    'AxisFirstUseWizard.WindowsWriteCacheBufferFlushingPrototypeOnlyNoRuntimeAction',
    'AxisFirstUseWizard.WindowsPowerPlanPrototypeOnlyNoRuntimeAction',
    'AxisFirstUseWizard.WindowsCleanupPrototypeOnlyNoRuntimeAction'
)) {
    Assert-BoostLabCondition ($prototypeSource.Contains($windowsPartBNoRuntimeMarker)) "AXIS Windows Part B should expose no-real-action marker: $windowsPartBNoRuntimeMarker"
}
foreach ($advancedNoRuntimeMarker in @(
    'AxisFirstUseWizard.AdvancedTimerResolutionAssistantPrototypeOnlyNoRuntimeAction',
    'AxisFirstUseWizard.AdvancedDefenderOptimizeAssistantPrototypeOnlyNoRuntimeAction'
)) {
    Assert-BoostLabCondition ($prototypeSource.Contains($advancedNoRuntimeMarker)) "AXIS Advanced should expose no-real-action marker: $advancedNoRuntimeMarker"
}
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.SelectorLabelPhysicalRightOfControl')) 'AXIS selector placement should expose the label-right-of-control marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.WindowsPrimaryActionSharedNoClippingSizing')) 'AXIS Windows primary actions should expose the shared no-clipping sizing marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.WindowsStartMenuLayoutPrimaryNoClipping')) 'AXIS Start Menu Layout primary action should expose a no-clipping marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.WindowsContextMenuPrimaryNoClipping')) 'AXIS Context Menu primary action should expose a no-clipping marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.WindowsBlackAccountPicturesPrimaryNoClipping')) 'AXIS Black Account Pictures primary action should expose a no-clipping marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.WindowsGameModePrimaryNoClipping')) 'AXIS Game Mode primary action should expose a no-clipping marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.WindowsGameModeRuntimeStatusNoClipping')) 'AXIS Game Mode runtime status should expose a no-clipping marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.WindowsPointerPrecisionRuntimeStatusNoClipping')) 'AXIS Pointer Precision runtime status should expose a no-clipping marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('Split-AxisSetupRightAlignedVisualLines')) 'AXIS Setup cards should expose the shared right-aligned visual line renderer.'
Assert-BoostLabCondition ($prototypeSource.Contains('Get-AxisSetupRightAlignedVisualBreakPhrases')) 'AXIS Setup cards should expose phrase-specific right-aligned visual break hints.'
Assert-BoostLabCondition ($prototypeSource.Contains($axisSetupRightAlignedVisualLineRendererAutomationId)) 'AXIS Setup cards should expose the no-left-floating wrapped Arabic line marker.'
Assert-BoostLabCondition ($prototypeSource.Contains($axisSharedCardBodyTextRendererMarker)) 'AXIS shared card body renderer marker should be present for future stage batches.'
Assert-BoostLabCondition ($prototypeSource.Contains($axisSharedCardBodyNoLeftFloatingMarker)) 'AXIS shared card body renderer should guard against left-floating wrapped Arabic lines.'
Assert-BoostLabCondition ($prototypeSource.Contains($axisSharedCardBodyMixedBidiMarker)) 'AXIS shared card body renderer should guard mixed Arabic/English visual lines.'
Assert-BoostLabCondition ($prototypeSource.Contains($axisSharedCardBodyFutureGuardMarker)) 'AXIS shared card body renderer should guard future Graphics/Windows/Advanced batches.'
Assert-BoostLabCondition ($prototypeSource.Contains('MaxVisualLineLength')) 'AXIS shared card body renderer should expose bounded visual line splitting.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.StageStripNoPartialProgress')) 'AXIS stage strip should expose the no-partial-progress marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.StageLineActiveFullWhite')) 'AXIS stage strip should expose the active full-white line marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.StageLineCompletedFullGreen')) 'AXIS stage strip should expose the completed full-green line marker.'
Assert-BoostLabCondition (-not $prototypeSource.Contains('87.36')) 'AXIS stage strip must not keep the old partial active underline width.'
Assert-BoostLabCondition (-not $prototypeSource.Contains('0.84')) 'AXIS stage strip must not keep the old partial progress value.'
$eventHandlerBlocks = [System.Collections.Generic.List[string]]::new()
foreach ($eventName in @('Add_Checked', 'Add_Unchecked', 'Add_Click', 'Add_Tick')) {
    foreach ($match in [regex]::Matches($prototypeSource, "(?s)\.$eventName\(\s*\{(?<Body>.*?)\}\.GetNewClosure\(\)\s*\)")) {
        $eventHandlerBlocks.Add([string]$match.Groups['Body'].Value)
    }
}
Assert-BoostLabCondition ($eventHandlerBlocks.Count -ge 4) 'AXIS first-use wizard should expose statically inspectable event handlers for the preview interaction flow.'
foreach ($eventHandlerBlock in $eventHandlerBlocks) {
    foreach ($blockedEventHelper in @(
        'New-AxisWizardShadowEffect'
        'Set-AxisWizardButtonVisualVariant'
        'Set-AxisWizardEnabledNextButtonBlue'
        'Set-AxisStageProgressStripActiveStage'
        'Copy-AxisWizardMap'
        'New-AxisBiosInformationStep'
        'New-AxisStep'
        'New-AxisWizardButton'
    )) {
        Assert-BoostLabCondition (-not $eventHandlerBlock.Contains($blockedEventHelper)) "AXIS preview event handlers must not call helper functions that can disappear from the handler scope: $blockedEventHelper"
    }
}
Assert-BoostLabCondition (-not $prototypeSource.Contains('Invoke-BoostLabToolAction')) 'AXIS first-use wizard must not call runtime tool actions.'
Assert-BoostLabCondition (-not $prototypeSource.Contains('Start-Process')) 'AXIS first-use wizard must not open real pages or processes.'
Assert-BoostLabCondition (-not $prototypeSource.Contains('autounattend.xml')) 'AXIS first-use wizard prototype must not create or reference a real autounattend.xml output path.'
Assert-BoostLabCondition (-not $prototypeSource.Contains('setupcomplete.cmd')) 'AXIS first-use wizard prototype must not create or reference a real setupcomplete.cmd output path.'
foreach ($blockedRuntimeText in @(
    'New-BoostLabActionPlan'
    'Set-ItemProperty'
    'New-ItemProperty'
    'Remove-ItemProperty'
    'Restart-Computer'
    'Stop-Computer'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'DownloadFile'
    'System.Net.WebClient'
    'Set-Content'
    'Add-Content'
    'Out-File'
    'New-Item'
    'Copy-Item'
    'Get-CimInstance'
    'Get-WmiObject'
    'Win32_Processor'
    'Win32_BaseBoard'
    'MediaCreationTool'
    'Get-PSDrive'
    'Get-Disk'
    'Clear-Disk'
    'Initialize-Disk'
    'Set-Disk'
    'New-Partition'
    'Remove-Partition'
    'Set-Partition'
    'Get-Partition'
    'Get-Volume'
    'Format-Volume'
    'Set-Volume'
    'Win32_LogicalDisk'
    'DriveType'
    'Removable'
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
    'sources\$OEM$'
)) {
    Assert-BoostLabCondition (-not $prototypeSource.Contains($blockedRuntimeText)) "AXIS first-use wizard must not contain runtime/system mutation text: $blockedRuntimeText"
}

foreach ($requiredBlueprintContractText in @(
    'Phase 177G Prototype Runtime Mapping Contract'
    'simulates the primary action flow only'
    'must not invoke the real BoostLab `Open` action'
    'same internal `Open` behavior for `bios-information`'
    'pending a later approved phase'
    'The checked checkbox visual uses a small blue inner square fill'
    '`رجوع` only closes the acknowledgement overlay'
    '`رجوع` is not Cancel'
)) {
    Assert-BoostLabCondition ($blueprintSource.Contains($requiredBlueprintContractText)) "AXIS BIOS Information blueprint is missing the Phase 177G runtime mapping contract text: $requiredBlueprintContractText"
}

foreach ($requiredBiosSettingsContractText in @(
    'The isolated first-use wizard prototype may use a mock hardware profile only for visual review.'
    'CPU: Intel'
    'Motherboard: MSI'
    'The final integrated AXIS implementation must remove static vendor assumptions'
    'must detect CPU and motherboard vendor from reliable system data'
    'must not show a vendor-specific motherboard utility item unless the motherboard vendor is confidently detected'
    'must not guess ASUS, MSI, Gigabyte, or ASRock'
    'Vendor detection values, raw manufacturer strings, WMI/system data, and uncertainty details belong in diagnostics/developer reporting'
)) {
    Assert-BoostLabCondition ($biosSettingsBlueprintSource.Contains($requiredBiosSettingsContractText)) "AXIS BIOS Settings blueprint is missing the Phase 178D hardware correctness contract text: $requiredBiosSettingsContractText"
}

foreach ($requiredBiosSettingsPhase178EText in @(
    'Phase 178E removes the requirements card from the normal customer-facing BIOS Settings prototype.'
    'not owner-approved visible UI for BIOS Settings'
    'requirements card not shown for BIOS Settings unless Yazan approves new visible requirement copy later'
)) {
    Assert-BoostLabCondition ($biosSettingsBlueprintSource.Contains($requiredBiosSettingsPhase178EText)) "AXIS BIOS Settings blueprint is missing the Phase 178E visible-copy contract text: $requiredBiosSettingsPhase178EText"
}
Assert-BoostLabCondition ($biosSettingsBlueprintSource.Contains($arabicIntelRebar)) 'AXIS BIOS Settings blueprint should record the punctuation-approved Resizable BAR label.'
Assert-BoostLabCondition (-not $biosSettingsBlueprintSource.Contains($oldArabicIntelRebar)) 'AXIS BIOS Settings blueprint should not retain the old dotted Resizable BAR label.'
Assert-BoostLabCondition ($biosSettingsBlueprintSource.Contains($arabicRestartAcknowledgement)) 'AXIS BIOS Settings blueprint should record the shortened confirmation checkbox text.'
Assert-BoostLabCondition (-not $biosSettingsBlueprintSource.Contains($oldArabicRestartAcknowledgement)) 'AXIS BIOS Settings blueprint should not retain the old long confirmation checkbox text.'

foreach ($requiredReinstallBlueprintText in @(
    'Internal tool ID | `reinstall`'
    'Stage | `Refresh`'
    'Pressing the primary button should start the customer-facing flow directly.'
    'No confirmation overlay appears for this step.'
    'No checkbox appears for this step.'
    'The isolated prototype must not create, format, erase, or modify any USB device.'
    'Do not implement persistence in this phase.'
    $arabicReinstallTitle
    $arabicReinstallSubtitle
    $arabicReinstallInfoTitle
    $arabicReinstallInfoBullet
    $arabicReinstallRequirementUsbSize
    $arabicReinstallRequirementNoData
    $arabicReinstallPrimaryAction
    $arabicReinstallRunning
    $arabicReinstallCompleted
)) {
    Assert-BoostLabCondition ($reinstallBlueprintSource.Contains($requiredReinstallBlueprintText)) "AXIS Reinstall blueprint is missing owner-approved contract text: $requiredReinstallBlueprintText"
}

foreach ($requiredAutoUnattendBlueprintText in @(
    'Internal tool ID | `unattended`'
    'Stage | `Refresh`'
    'Pressing the customer-facing primary button'
    'This is not a confirmation checkbox window.'
    'No confirmation checkbox is required for this step.'
    'The input-window'
    'button should remain disabled until the required fields are valid.'
    'Do not create `autounattend.xml`.'
    'Do not write to USB.'
    'Do not detect real removable media.'
    'Do not implement persistence in this phase.'
    $arabicAutoUnattendSubtitle
    $arabicAutoUnattendInfoTitle
    $arabicAutoUnattendInfoBulletOobe
    $arabicAutoUnattendInfoBulletSetup
    $arabicAutoUnattendInfoBulletUsb
    $arabicRequirementsTitle
    $arabicAutoUnattendRequirementAccount
    $arabicAutoUnattendRequirementUsb
    $arabicAutoUnattendInputTitle
    $arabicAutoUnattendAccountLabel
    $arabicAutoUnattendUsbLabel
    $arabicAutoUnattendPrimaryAction
    $arabicDocumentation
    $arabicReturn
    $arabicBack
    $arabicNext
    $arabicAutoUnattendRunning
    $arabicAutoUnattendCompleted
    $arabicSupportTitle
    $arabicSupportBody
)) {
    Assert-BoostLabCondition ($autoUnattendBlueprintSource.Contains($requiredAutoUnattendBlueprintText)) "AXIS AutoUnattend blueprint is missing owner-approved contract text: $requiredAutoUnattendBlueprintText"
}

foreach ($requiredUpdatesDriversBlueprintText in @(
    'Internal tool ID | `updates-drivers-block`'
    'Stage | `Refresh`'
    'USB selection'
    'USB selection label'
    'button should remain disabled until a USB option is selected.'
    'use mock/input-only simulation and do not touch USB.'
    'USB selector should not look like a harsh plain white system control.'
    'Selected USB value must be clearly visible.'
    'Future UI implementation must use BiDi-safe rendering, deterministic line breaks, or explicit LTR runs'
    'Do not run `Apply`.'
    'Do not write `setupcomplete.cmd`.'
    'Do not detect real removable media.'
    'Do not create backups.'
    'Do not open directories.'
    'Do not mutate the host.'
    'Do not keep `#E65F2B` for documentation button text.'
    'Do not auto-advance.'
    'input window has USB selection only'
    $arabicUpdatesDriversSubtitle
    $arabicUpdatesDriversInfoTitle
    $arabicUpdatesDriversInfoBulletSetupcomplete
    $arabicUpdatesDriversInfoBulletWindowsUpdate
    $arabicRequirementsTitle
    $arabicUpdatesDriversRequirementUsb
    $arabicUpdatesDriversInputTitle
    $arabicUpdatesDriversUsbLabel
    $arabicUpdatesDriversPrimaryAction
    $arabicUpdatesDriversInputCreate
    $arabicDocumentation
    $arabicReturn
    $arabicBack
    $arabicNext
    $arabicUpdatesDriversRunning
    $arabicUpdatesDriversCompleted
    $arabicSupportTitle
    $arabicSupportBody
)) {
    Assert-BoostLabCondition ($updatesDriversBlueprintSource.Contains($requiredUpdatesDriversBlueprintText)) "AXIS Updates Drivers Block blueprint is missing owner-approved contract text: $requiredUpdatesDriversBlueprintText"
}

foreach ($requiredToBiosBlueprintText in @(
    'Internal tool ID | `to-bios`'
    'Stage | `Refresh`'
    'The `to-bios` step is the next Refresh-stage first-use wizard step after Updates Drivers Block.'
    'No requirements card should be shown for this step.'
    'Pressing customer-facing'
    $arabicToBiosPrimaryAction
    'opens a confirmation overlay.'
    'The confirmation primary button stays disabled until the checkbox is checked.'
    'The real `Open` behavior must not execute in this docs/prototype phase.'
    'The prototype may simulate the confirmation flow'
    'Do not implement persistence in this phase.'
    $arabicToBiosTitle
    $arabicToBiosSubtitle
    $arabicToBiosInfoTitle
    $arabicToBiosInfoBulletRestart
    $arabicToBiosInfoBulletUsbBoot
    $arabicToBiosInfoBulletInstall
    $arabicToBiosPrimaryAction
    $arabicDocumentation
    $arabicAcknowledgement
    $arabicRestart
    $arabicReturn
    $arabicBack
    $arabicNext
    $arabicRestarting
    $arabicCompleted
    $arabicSupportTitle
    $arabicSupportBody
)) {
    Assert-BoostLabCondition ($toBiosBlueprintSource.Contains($requiredToBiosBlueprintText)) "AXIS To BIOS blueprint is missing owner-approved contract text: $requiredToBiosBlueprintText"
}

$edgeWebViewBlueprintApprovedBullet1 = ConvertTo-AxisWizardBlueprintMojibakeText -Text $windowsEdgeWebViewApprovedBullet1
$edgeWebViewBlueprintOldBoostLabBullet1 = ConvertTo-AxisWizardBlueprintMojibakeText -Text $windowsEdgeWebViewOldBoostLabBullet1
foreach ($requiredEdgeWebViewBlueprintText in @(
    'Internal tool ID | `edge-webview`'
    'Customer-facing step title | `Edge WebView`'
    $edgeWebViewBlueprintApprovedBullet1
    'Do not show `BoostLab` in normal customer-facing copy for this step.'
    'AXIS is the customer-facing product; BoostLab is internal/repo/code branding only.'
)) {
    Assert-BoostLabCondition ($edgeWebViewBlueprintSource.Contains($requiredEdgeWebViewBlueprintText)) "AXIS Edge WebView blueprint is missing owner-approved branding/copy contract text: $requiredEdgeWebViewBlueprintText"
}
Assert-BoostLabCondition (-not $edgeWebViewBlueprintSource.Contains($edgeWebViewBlueprintOldBoostLabBullet1)) 'AXIS Edge WebView blueprint must not retain the old customer-facing BoostLab bullet.'

$defenderOptimizeBlueprintApprovedBullet1 = ConvertTo-AxisWizardBlueprintMojibakeText -Text $advancedDefenderOptimizeApprovedBullet1
$defenderOptimizeBlueprintOldBoostLabBullet1 = ConvertTo-AxisWizardBlueprintMojibakeText -Text $advancedDefenderOptimizeOldBoostLabBullet1
foreach ($requiredTimerResolutionBlueprintText in @(
    'Internal tool ID | `timer-resolution-assistant`'
    'Stage | `Advanced`'
    'Customer-facing step title | `Timer Resolution Assistant`'
    'Production action mapping | customer-facing'
    $advancedTimerResolutionPrimary
    $advancedTimerResolutionSubtitle
    $advancedTimerResolutionInfoTitle
    $advancedTimerResolutionInfoBullet1
    $advancedTimerResolutionInfoBullet2
    $advancedTimerResolutionInfoBullet3
    $advancedRunning
    $advancedCompleted
)) {
    $requiredTimerResolutionBlueprintTextToFind = if ($requiredTimerResolutionBlueprintText -match '[\u0600-\u06FF]') {
        ConvertTo-AxisWizardBlueprintMojibakeText -Text $requiredTimerResolutionBlueprintText
    }
    else {
        $requiredTimerResolutionBlueprintText
    }
    Assert-BoostLabCondition ($timerResolutionAssistantBlueprintSource.Contains($requiredTimerResolutionBlueprintTextToFind)) "AXIS Timer Resolution Assistant blueprint is missing owner-approved contract text: $requiredTimerResolutionBlueprintText"
}
foreach ($requiredDefenderOptimizeBlueprintText in @(
    'Internal tool ID | `defender-optimize-assistant`'
    'Stage | `Advanced`'
    'Customer-facing step title | `Defender Optimize Assistant`'
    'Production action mapping | customer-facing `Apply Defender Optimize` maps later to internal `Apply`'
    $defenderOptimizeBlueprintApprovedBullet1
    'Do not show `BoostLab` in normal customer-facing copy for this step.'
    'AXIS is the customer-facing product; BoostLab is internal/repo/code branding only.'
    'Apply Defender Optimize'
    $advancedDefenderOptimizeSubtitle
    $advancedDefenderOptimizeInfoTitle
    $advancedDefenderOptimizeInfoBullet2
    $advancedDefenderOptimizeInfoBullet3
    $advancedDefenderOptimizeRequirementsTitle
    $advancedDefenderOptimizeRequirement1
    $advancedDefenderOptimizeRequirement2
    $advancedDefenderOptimizeRequirement3
    $advancedRunning
    $advancedCompleted
)) {
    $requiredDefenderOptimizeBlueprintTextToFind = if ($requiredDefenderOptimizeBlueprintText -match '[\u0600-\u06FF]') {
        ConvertTo-AxisWizardBlueprintMojibakeText -Text $requiredDefenderOptimizeBlueprintText
    }
    else {
        $requiredDefenderOptimizeBlueprintText
    }
    Assert-BoostLabCondition ($defenderOptimizeAssistantBlueprintSource.Contains($requiredDefenderOptimizeBlueprintTextToFind)) "AXIS Defender Optimize Assistant blueprint is missing owner-approved branding/copy contract text: $requiredDefenderOptimizeBlueprintText"
}
Assert-BoostLabCondition (-not $defenderOptimizeAssistantBlueprintSource.Contains($defenderOptimizeBlueprintOldBoostLabBullet1)) 'AXIS Defender Optimize blueprint must not retain the old customer-facing BoostLab bullet.'
Assert-BoostLabCondition ($defenderOptimizeAssistantBlueprintSource.Contains($defenderOptimizeBlueprintApprovedBullet1)) 'AXIS Defender Optimize blueprint must use the approved no-BoostLab customer-facing bullet.'

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
    FlowDirection = [string]$prototype.FlowDirection
    StageProgressItemCount = $stripItems.Count
    FirstStep = [string]$biosStep['Title']
    CustomerVisibleAction = [string]$biosStep['CustomerAction']
    ContinueStartsDisabled = $continueStartsDisabled
    RuntimeActionsStarted = $false
    MainWindowTouched = $false
    ProtectedSourceUnchanged = $true
}
