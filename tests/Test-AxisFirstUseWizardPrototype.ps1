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
. $prototypePath

foreach ($functionName in @(
    'Get-AxisFirstUseWizardSampleState'
    'Get-AxisWizardArabicText'
    'Get-AxisWizardSetupText'
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
    'New-AxisSetupPhysicalRightEdgeTextGroup'
    'New-AxisWizardMixedBidiTextBlock'
    'New-AxisWizardToBiosTitleRightAnchor'
    'Split-AxisAutoUnattendInformationText'
    'New-AxisAutoUnattendInformationTextGroup'
    'Split-AxisUpdatesDriversInformationText'
    'New-AxisUpdatesDriversInformationTextGroup'
    'Split-AxisToBiosInformationText'
    'New-AxisToBiosInformationTextGroup'
    'New-AxisAutoUnattendInputOverlay'
    'New-AxisWizardUsbComboBoxItemStyle'
    'New-AxisFirstUseWizardStepContent'
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
$axisSetupRightAlignedVisualLineRendererAutomationId = 'AxisFirstUseWizard.SetupRightAlignedVisualLineRenderer.NoLeftFloatingWrappedArabicLines'
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
Assert-BoostLabCondition ([double]$prototype.RowDefinitions[1].Height.Value -eq 50.0) 'AXIS first-use wizard stage strip row should leave room for normal Windows chrome.'
Assert-BoostLabCondition ([double]$prototype.RowDefinitions[3].Height.Value -eq 72.0) 'AXIS first-use wizard footer row should leave enough room for unclipped buttons.'
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

$sampleSteps = @($sampleState['Steps'])
Assert-BoostLabCondition ($sampleSteps.Count -eq 16) 'AXIS first-use wizard sample state should include the six approved Check/Refresh steps plus the ten Setup steps.'
$expectedStepOrder = @(
    'bios-information'
    'bios-settings'
    'reinstall'
    'unattended'
    'updates-drivers-block'
    'to-bios'
) + $setupStepOrder
Assert-BoostLabCondition ((@($sampleSteps | ForEach-Object { [string]$_['Id'] }) -join '|') -eq ($expectedStepOrder -join '|')) 'AXIS first-use wizard step order should keep the approved Check/Refresh steps, then the full Setup batch after To BIOS.'
$expectedStepTitles = @(
    'BIOS Drivers & Downloads'
    'BIOS Settings'
    $arabicReinstallTitle
    'AutoUnattend'
    'Updates Drivers Block'
    $arabicToBiosTitle
) + $setupStepTitles
Assert-BoostLabCondition ((@($sampleSteps | ForEach-Object { [string]$_['Title'] }) -join '|') -eq ($expectedStepTitles -join '|')) 'AXIS first-use wizard customer step title order changed.'
Assert-BoostLabCondition ([int]$sampleState['CurrentStepIndex'] -eq 0) 'AXIS first-use wizard should start on BIOS Drivers & Downloads.'
Assert-BoostLabCondition ($sampleState['Step'] -eq $sampleSteps[0]) 'AXIS first-use wizard compatibility Step entry should remain the first visible step.'
$mockHardwareProfile = [System.Collections.IDictionary]$sampleState['MockHardwareProfile']
Assert-BoostLabCondition ([string]$mockHardwareProfile['Marker'] -eq 'AxisFirstUseWizard.MockHardwareProfile') 'AXIS BIOS Settings prototype should expose a local mock hardware profile marker.'
Assert-BoostLabCondition ([string]$mockHardwareProfile['CpuVendor'] -eq 'Intel') 'AXIS BIOS Settings prototype mock CPU vendor should be Intel.'
Assert-BoostLabCondition ([string]$mockHardwareProfile['MotherboardVendor'] -eq 'MSI') 'AXIS BIOS Settings prototype mock motherboard vendor should be MSI.'
Assert-BoostLabCondition ([string]$mockHardwareProfile['Summary'] -eq 'CPU=Intel; Motherboard=MSI') 'AXIS BIOS Settings prototype mock profile should expose CPU=Intel and Motherboard=MSI markers.'
Assert-BoostLabCondition ([bool]$mockHardwareProfile['PrototypeOnly']) 'AXIS BIOS Settings mock hardware profile should be clearly prototype-only.'

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
[void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressCheckFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineActiveFullWhite.Check' -ExpectedColor '#FFF0F2F5' -Name 'BIOS Drivers Check active')
[void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressRefreshFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineInactiveDim.Refresh' -ExpectedColor '#FF242424' -Name 'BIOS Drivers Refresh inactive')
[void](Assert-AxisFirstUseWizardStageLineState -Fill $stageProgressSetupFill -ExpectedAutomationId 'AxisFirstUseWizard.StageLineInactiveDim.Setup' -ExpectedColor '#FF242424' -Name 'BIOS Drivers Setup inactive')
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
Assert-BoostLabCondition ($footerButtons.Count -eq 2) 'AXIS first-use wizard footer should include only Back and Continue.'
Assert-BoostLabCondition ((@($footerButtons | ForEach-Object { [string]$_.Content }) -join '|') -eq "$arabicBack|$arabicNext") 'AXIS first-use wizard footer button labels changed.'
Assert-BoostLabCondition ($taggedFooterButtonSpacer.Count -eq 1) 'AXIS footer buttons should use an explicit spacer.'
Assert-BoostLabCondition ([double]$taggedFooterButtonSpacer[0].Width -ge 12.0 -and [double]$taggedFooterButtonSpacer[0].Width -le 20.0) 'AXIS footer spacer should provide a clear 12-20px gap.'
Assert-BoostLabCondition ($taggedContinueButtons.Count -eq 1) 'AXIS first-use wizard Continue button is missing.'
Assert-BoostLabCondition (-not [bool]$taggedContinueButtons[0].IsEnabled) 'AXIS Continue/Next should start disabled before completion.'
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

Assert-BoostLabCondition ($taggedOverlay.Count -eq 4) 'AXIS first-use wizard should create confirmation overlays for BIOS Drivers, BIOS Settings, To BIOS, and Updates Pause only.'
Assert-BoostLabCondition ($taggedAutoUnattendInputOverlay.Count -eq 1) 'AXIS first-use wizard should create one AutoUnattend input overlay.'
Assert-BoostLabCondition ($taggedAutoUnattendInputOverlay[0].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS AutoUnattend input overlay should start hidden.'
Assert-BoostLabCondition ($taggedUpdatesDriversInputOverlay.Count -eq 1) 'AXIS first-use wizard should create one Updates Drivers Block input overlay.'
Assert-BoostLabCondition ($taggedUpdatesDriversInputOverlay[0].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Updates Drivers Block input overlay should start hidden.'
Assert-BoostLabCondition ($taggedOverlay[0].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS first-step confirmation overlay should start hidden.'
Assert-BoostLabCondition ($taggedOverlay[1].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS BIOS Settings confirmation overlay should start hidden.'
Assert-BoostLabCondition ($taggedOverlay[2].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS To BIOS confirmation overlay should start hidden.'
Assert-BoostLabCondition ($taggedOverlay[3].Visibility -eq [System.Windows.Visibility]::Collapsed) 'AXIS Updates Pause confirmation overlay should start hidden.'
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
Assert-BoostLabCondition ($taggedOverlayReturnButtonSpacer.Count -eq 1) 'AXIS confirmation overlay should space Open and Return with an explicit spacer.'
Assert-BoostLabCondition ([double]$taggedOverlayReturnButtonSpacer[0].Width -ge 10.0 -and [double]$taggedOverlayReturnButtonSpacer[0].Width -le 16.0) 'AXIS confirmation overlay Return spacer should stay compact.'
Assert-BoostLabCondition (@($taggedConfirmationRightAlignedGroup[0].Children) -contains $taggedAcknowledgementRightAnchorRow[0]) 'AXIS confirmation checkbox row should be inside the same right-aligned inner group.'
Assert-BoostLabCondition (@($taggedConfirmationRightAlignedGroup[0].Children) -contains $taggedOverlayButtonArea[0]) 'AXIS confirmation Open button area should be inside the same right-aligned inner group.'
Assert-BoostLabCondition ($taggedOverlayOpenButton.Count -eq 1) 'AXIS confirmation overlay Open button is missing.'
Assert-BoostLabCondition ([string]$taggedOverlayOpenButton[0].Content -eq $arabicOpen) 'AXIS confirmation button should reuse the owner-approved Open label.'
Assert-BoostLabCondition ([double]$taggedOverlayOpenButton[0].Margin.Top -eq 0.0) 'AXIS confirmation button should not rely on top margin for overlay spacing.'
Assert-BoostLabCondition ($taggedOverlayReturnButton.Count -eq 1) 'AXIS confirmation overlay Return button is missing.'
Assert-BoostLabCondition ([string]$taggedOverlayReturnButton[0].Content -eq $arabicReturn) 'AXIS confirmation Return button should use owner-approved Arabic Return.'
Assert-BoostLabCondition ([System.Windows.Automation.AutomationProperties]::GetAutomationId($taggedOverlayReturnButton[0]) -eq 'AxisFirstUseWizard.ConfirmationReturnOnlyClosesOverlay') 'AXIS confirmation Return should be marked as overlay-only close behavior.'
Assert-BoostLabCondition ([bool]$taggedOverlayReturnButton[0].IsEnabled) 'AXIS confirmation Return should always be available.'
Assert-BoostLabCondition (@($taggedOverlayButtonArea[0].Children) -contains $taggedOverlayOpenButton[0]) 'AXIS confirmation Open button should stay in the overlay button row.'
Assert-BoostLabCondition (@($taggedOverlayButtonArea[0].Children) -contains $taggedOverlayReturnButton[0]) 'AXIS confirmation Return button should stay beside Open in the overlay button row.'
Assert-BoostLabCondition (-not [bool]$taggedOverlayOpenButton[0].IsEnabled) 'AXIS confirmation button should be disabled until acknowledgement is checked.'
$taggedOverlayAcknowledgement[0].IsChecked = $true
Assert-BoostLabCondition ([bool]$taggedOverlayOpenButton[0].IsEnabled) 'AXIS confirmation button should enable after acknowledgement is checked.'
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
        Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $taggedContentHost[0].Child -Tag "AxisFirstUseWizard.${tagRoot}Step").Count -eq 1) 'AXIS final Setup step should not navigate past the last prototype step.'
    }
}

Invoke-AxisFirstUseWizardButtonClick -Button $taggedBackButtons[0]
Assert-BoostLabCondition (@(Get-AxisFirstUseWizardTaggedElements -Root $taggedContentHost[0].Child -Tag 'AxisFirstUseWizard.SetupStoreSettingsStep').Count -eq 1) 'AXIS Back from final Setup step should return to Store Settings.'

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
Assert-BoostLabCondition ($previewScopedOverlays.Count -eq 4) 'AXIS preview-scope smoke test should have BIOS Drivers, BIOS Settings, To BIOS, and Updates Pause confirmation overlays only.'
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
    'Apply'
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
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.UpdatesDriversMixedBidiSafeInfoText')) 'AXIS Updates Drivers Block should expose the mixed BiDi-safe marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.SetupStageBatchPrototypeOnly')) 'AXIS Setup batch should expose the prototype-only batch marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.SetupPrototypeOnlyNoRuntimeAction')) 'AXIS Setup batch should expose the no-real-action marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.SetupRuntimeStatusNoClipping')) 'AXIS Setup runtime status should expose the no-clipping marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.SetupSupportCardNoClipping')) 'AXIS Setup support card should expose the no-clipping marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.SetupCardsPhysicalOrderInfoRightRequirementsLeft')) 'AXIS Setup two-card layout should expose the physical info-right requirements-left marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('AxisFirstUseWizard.EnglishOnlyTitleRightAnchored')) 'AXIS English-only Setup titles should expose the LTR right-anchored marker.'
Assert-BoostLabCondition ($prototypeSource.Contains('Split-AxisSetupRightAlignedVisualLines')) 'AXIS Setup cards should expose the shared right-aligned visual line renderer.'
Assert-BoostLabCondition ($prototypeSource.Contains('Get-AxisSetupRightAlignedVisualBreakPhrases')) 'AXIS Setup cards should expose phrase-specific right-aligned visual break hints.'
Assert-BoostLabCondition ($prototypeSource.Contains($axisSetupRightAlignedVisualLineRendererAutomationId)) 'AXIS Setup cards should expose the no-left-floating wrapped Arabic line marker.'
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
