Set-StrictMode -Version Latest

$script:AxisFirstUseWizardResourcePath = Join-Path $PSScriptRoot 'AxisResources.ps1'
. $script:AxisFirstUseWizardResourcePath
$script:AxisFirstUseWizardButtonStyle = $null
$script:AxisFirstUseWizardFilledSquareCheckboxStyle = $null
$script:AxisFirstUseWizardSelectorComboBoxStyle = $null

function Get-AxisWizardMapValue {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [System.Collections.IDictionary]$Map,

        [Parameter(Mandatory)]
        [string]$Name,

        [AllowNull()]
        [object]$DefaultValue = ''
    )

    if ($null -eq $Map -or -not $Map.Contains($Name) -or $null -eq $Map[$Name]) {
        return $DefaultValue
    }

    return $Map[$Name]
}

function Get-AxisWizardResource {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Resources,

        [Parameter(Mandatory)]
        [string]$Name
    )

    if ($Resources.Contains($Name)) {
        return $Resources[$Name]
    }

    return Get-AxisResourceValue -Name $Name -ResourceDictionary $Resources
}

function New-AxisWizardThickness {
    [CmdletBinding()]
    param(
        [double]$Left,
        [double]$Top = $Left,
        [double]$Right = $Left,
        [double]$Bottom = $Top
    )

    return [System.Windows.Thickness]::new($Left, $Top, $Right, $Bottom)
}

function New-AxisWizardSpacer {
    [CmdletBinding()]
    param(
        [double]$Width = 0.0,

        [double]$Height = 0.0,

        [string]$Tag = ''
    )

    $spacer = [System.Windows.Controls.Border]::new()
    $spacer.Background = [System.Windows.Media.Brushes]::Transparent
    $spacer.IsHitTestVisible = $false
    if ($Width -gt 0.0) {
        $spacer.Width = $Width
    }
    if ($Height -gt 0.0) {
        $spacer.Height = $Height
    }
    if (-not [string]::IsNullOrWhiteSpace($Tag)) {
        $spacer.Tag = $Tag
    }

    return $spacer
}

function Add-AxisWizardGridRow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Windows.Controls.Grid]$Grid,

        [Parameter(Mandatory)]
        [System.Windows.UIElement]$Child
    )

    $rowIndex = $Grid.RowDefinitions.Count
    $row = [System.Windows.Controls.RowDefinition]::new()
    $row.Height = [System.Windows.GridLength]::Auto
    [void]$Grid.RowDefinitions.Add($row)
    [System.Windows.Controls.Grid]::SetRow($Child, $rowIndex)
    [void]$Grid.Children.Add($Child)

    return $Child
}

function New-AxisWizardRightAnchor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Windows.FrameworkElement]$Child,

        [Parameter(Mandatory)]
        [string]$Tag,

        [double]$MaxWidth = 0.0,

        [switch]$PreserveChildFlowDirection
    )

    $anchor = [System.Windows.Controls.Grid]::new()
    $anchor.Tag = $Tag
    $anchor.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $anchor.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch

    $Child.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    if (-not $PreserveChildFlowDirection) {
        $Child.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    }
    if ($MaxWidth -gt 0.0) {
        $Child.MaxWidth = $MaxWidth
    }

    [void]$anchor.Children.Add($Child)
    return $anchor
}

function New-AxisWizardPhysicalRightEdgeTextGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Tag,

        [Parameter(Mandatory)]
        [object]$Resources,

        [Parameter(Mandatory)]
        [System.Collections.IEnumerable]$Lines,

        [double]$MaxWidth = 0.0
    )

    $group = [System.Windows.Controls.Grid]::new()
    $group.Tag = $Tag
    $group.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $group.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    if ($MaxWidth -gt 0.0) {
        $group.MaxWidth = $MaxWidth
    }

    $rightColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $rightColumn.Width = [System.Windows.GridLength]::Auto
    [void]$group.ColumnDefinitions.Add($rightColumn)

    foreach ($line in @($Lines)) {
        if ($line -isnot [System.Collections.IDictionary]) {
            continue
        }

        $textBlock = New-AxisWizardTextBlock `
            -Text ([string](Get-AxisWizardMapValue -Map $line -Name 'Text')) `
            -Resources $Resources `
            -FontSizeKey ([string](Get-AxisWizardMapValue -Map $line -Name 'FontSizeKey' -DefaultValue 'Axis.Type.BodySmall.FontSize')) `
            -FontWeightKey ([string](Get-AxisWizardMapValue -Map $line -Name 'FontWeightKey' -DefaultValue 'Axis.Type.Body.FontWeight')) `
            -FontFamilyKey ([string](Get-AxisWizardMapValue -Map $line -Name 'FontFamilyKey' -DefaultValue 'Axis.Type.Body.FontFamily')) `
            -ForegroundKey ([string](Get-AxisWizardMapValue -Map $line -Name 'ForegroundKey' -DefaultValue 'Axis.Brush.Wizard.TextSecondary')) `
            -Margin (New-AxisWizardThickness -Left 0 -Top ([double](Get-AxisWizardMapValue -Map $line -Name 'TopMargin' -DefaultValue 0.0)) -Right 0 -Bottom 0) `
            -TextAlignment ([System.Windows.TextAlignment]::Right) `
            -FlowDirection ([System.Windows.FlowDirection]::RightToLeft) `
            -Wrap:([bool](Get-AxisWizardMapValue -Map $line -Name 'Wrap' -DefaultValue $false))

        $lineTag = [string](Get-AxisWizardMapValue -Map $line -Name 'Tag')
        if (-not [string]::IsNullOrWhiteSpace($lineTag)) {
            $textBlock.Tag = $lineTag
        }

        $lineMaxWidth = [double](Get-AxisWizardMapValue -Map $line -Name 'MaxWidth' -DefaultValue 0.0)
        if ($lineMaxWidth -gt 0.0) {
            $textBlock.MaxWidth = $lineMaxWidth
        }

        [System.Windows.Controls.Grid]::SetColumn($textBlock, 0)
        [void](Add-AxisWizardGridRow -Grid $group -Child $textBlock)
    }

    return $group
}

function New-AxisWizardMixedBidiTextBlock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [object]$Resources,

        [string]$Tag = '',
        [string]$FontSizeKey = 'Axis.Type.Caption.FontSize',
        [string]$FontWeightKey = 'Axis.Type.Body.FontWeight',
        [string]$FontFamilyKey = 'Axis.Type.Caption.FontFamily',
        [string]$ForegroundKey = 'Axis.Brush.Wizard.TextSecondary',
        [System.Windows.Thickness]$Margin = (New-AxisWizardThickness -Left 0),
        [double]$MaxWidth = 0.0
    )

    $textBlock = New-AxisWizardTextBlock `
        -Text $Text `
        -Resources $Resources `
        -FontSizeKey $FontSizeKey `
        -FontWeightKey $FontWeightKey `
        -FontFamilyKey $FontFamilyKey `
        -ForegroundKey $ForegroundKey `
        -Margin $Margin `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::RightToLeft)
    $textBlock.TextWrapping = [System.Windows.TextWrapping]::NoWrap
    $textBlock.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    if ($MaxWidth -gt 0.0) {
        $textBlock.MaxWidth = $MaxWidth
    }
    if (-not [string]::IsNullOrWhiteSpace($Tag)) {
        $textBlock.Tag = $Tag
    }

    $textBlock.Inlines.Clear()
    $englishTermPattern = 'setupcomplete\.cmd|Epic Games Launcher|Epic Games|Memory Compression|Microsoft Edge|Microsoft Store|Windows Update|Task Manager|Windows Home|Windows Pro|Resizable BAR|BitLocker|AutoUnattend|Ctrl \+ V|Microsoft|Windows|BIOS|OOBE|USB|XML'
    $currentIndex = 0
    foreach ($match in [regex]::Matches($Text, $englishTermPattern)) {
        if ($match.Index -gt $currentIndex) {
            $arabicRun = [System.Windows.Documents.Run]::new($Text.Substring($currentIndex, $match.Index - $currentIndex))
            $arabicRun.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
            [void]$textBlock.Inlines.Add($arabicRun)
        }

        $englishRun = [System.Windows.Documents.Run]::new($match.Value)
        $englishRun.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
        [void]$textBlock.Inlines.Add($englishRun)
        $currentIndex = $match.Index + $match.Length
    }

    if ($currentIndex -lt $Text.Length) {
        $arabicTailRun = [System.Windows.Documents.Run]::new($Text.Substring($currentIndex))
        $arabicTailRun.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
        [void]$textBlock.Inlines.Add($arabicTailRun)
    }

    return $textBlock
}

function New-AxisWizardToBiosTitleRightAnchor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [object]$Resources
    )

    $titleText = New-AxisWizardTextBlock `
        -Text $Text `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.PageTitle.FontSize' `
        -FontWeightKey 'Axis.Type.PageTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.TextPrimary' `
        -Margin (New-AxisWizardThickness -Left 0 -Top 4 -Right 0 -Bottom 6) `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::LeftToRight)
    $titleText.Tag = 'AxisFirstUseWizard.ToBiosTitleEnglishOnlyText'
    $titleText.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $titleText.TextWrapping = [System.Windows.TextWrapping]::NoWrap
    $titleText.MaxWidth = 690
    $titleText.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.ToBiosTitleEnglishOnlyLtr')

    $anchor = [System.Windows.Controls.Grid]::new()
    $anchor.Tag = 'AxisFirstUseWizard.ToBiosTitleRightAnchor'
    $anchor.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $anchor.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $anchor.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.ToBiosTitleRightAnchoredEnglishOnly')
    [void]$anchor.Children.Add($titleText)

    return $anchor
}

function Split-AxisAutoUnattendInformationText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Title', 'Oobe', 'Setup', 'Usb')]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Text
    )

    if ($Name -eq 'Title') {
        return @($Text)
    }

    if ($Name -eq 'Oobe') {
        $marker = ' OOBE '
        $markerIndex = $Text.IndexOf($marker, [System.StringComparison]::Ordinal)
        if ($markerIndex -ge 0) {
            return @(
                $Text.Substring(0, $markerIndex + $marker.Trim().Length + 1).Trim()
                $Text.Substring($markerIndex + $marker.Length).Trim()
            )
        }
    }

    if ($Name -eq 'Setup') {
        $arabicComma = [string][char]0x060C
        $parts = $Text.Split([char]0x060C)
        if ($parts.Count -eq 3) {
            return @(
                ($parts[0].Trim() + $arabicComma)
                ($parts[1].Trim() + $arabicComma)
                $parts[2].Trim()
            )
        }
    }

    if ($Name -eq 'Usb') {
        $marker = 'Windows '
        $markerIndex = $Text.IndexOf($marker, [System.StringComparison]::Ordinal)
        if ($markerIndex -ge 0) {
            return @(
                $Text.Substring(0, $markerIndex + 'Windows'.Length).Trim()
                $Text.Substring($markerIndex + $marker.Length).Trim()
            )
        }
    }

    return @($Text)
}

function New-AxisAutoUnattendInformationTextGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Step,

        [Parameter(Mandatory)]
        [object]$Resources,

        [double]$MaxWidth = 320.0
    )

    $group = [System.Windows.Controls.Grid]::new()
    $group.Tag = 'AxisFirstUseWizard.AutoUnattendInformationSharedPhysicalRightEdge'
    $group.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $group.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $group.MaxWidth = $MaxWidth
    $group.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.AutoUnattendMixedBidiSafeInfoText')

    $rightColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $rightColumn.Width = [System.Windows.GridLength]::Auto
    [void]$group.ColumnDefinitions.Add($rightColumn)

    $titleLines = Split-AxisAutoUnattendInformationText `
        -Name 'Title' `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'InformationCardTitle' -DefaultValue (Get-AxisWizardArabicText -Name 'AutoUnattendInfoTitle')))
    foreach ($line in $titleLines) {
        [void](Add-AxisWizardGridRow -Grid $group -Child (New-AxisWizardMixedBidiTextBlock `
            -Text $line `
            -Resources $Resources `
            -Tag 'AxisFirstUseWizard.AutoUnattendInformationTitle' `
            -FontSizeKey 'Axis.Type.Caption.FontSize' `
            -FontWeightKey 'Axis.Type.CardTitle.FontWeight' `
            -FontFamilyKey 'Axis.Type.Caption.FontFamily' `
            -ForegroundKey 'Axis.Brush.Wizard.TextPrimary' `
            -MaxWidth $MaxWidth))
    }

    $itemNames = @('Oobe', 'Setup', 'Usb')
    $items = @(Get-AxisWizardMapValue -Map $Step -Name 'InformationItems' -DefaultValue @())
    for ($itemIndex = 0; $itemIndex -lt $items.Count; $itemIndex++) {
        $itemContainer = [System.Windows.Controls.Grid]::new()
        $itemContainer.Tag = 'AxisFirstUseWizard.AutoUnattendInformationItem'
        $itemContainer.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
        $itemContainer.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
        $itemContainer.MaxWidth = $MaxWidth
        $itemContainer.Margin = New-AxisWizardThickness -Left 0 -Top 1 -Right 0 -Bottom 0

        $itemColumn = [System.Windows.Controls.ColumnDefinition]::new()
        $itemColumn.Width = [System.Windows.GridLength]::Auto
        [void]$itemContainer.ColumnDefinitions.Add($itemColumn)

        $splitName = if ($itemIndex -lt $itemNames.Count) { $itemNames[$itemIndex] } else { 'Oobe' }
        foreach ($line in @(Split-AxisAutoUnattendInformationText -Name $splitName -Text ([string]$items[$itemIndex]))) {
            [void](Add-AxisWizardGridRow -Grid $itemContainer -Child (New-AxisWizardMixedBidiTextBlock `
                -Text $line `
                -Resources $Resources `
                -Tag 'AxisFirstUseWizard.AutoUnattendInformationItemLine' `
                -FontSizeKey 'Axis.Type.Caption.FontSize' `
                -FontWeightKey 'Axis.Type.Body.FontWeight' `
                -FontFamilyKey 'Axis.Type.Caption.FontFamily' `
                -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
                -MaxWidth $MaxWidth))
        }

        [void](Add-AxisWizardGridRow -Grid $group -Child $itemContainer)
    }

    return $group
}

function Split-AxisUpdatesDriversInformationText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Title', 'Setupcomplete', 'WindowsUpdate')]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Text
    )

    if ($Name -eq 'Title') {
        return @($Text)
    }

    if ($Name -eq 'Setupcomplete') {
        $marker = ConvertFrom-AxisWizardCodePoints @(0x0020, 0x062F, 0x0627, 0x062E, 0x0644, 0x0020)
        $markerIndex = $Text.IndexOf($marker, [System.StringComparison]::Ordinal)
        if ($markerIndex -ge 0) {
            return @(
                $Text.Substring(0, $markerIndex).Trim()
                $Text.Substring($markerIndex + 1).Trim()
            )
        }
    }

    if ($Name -eq 'WindowsUpdate') {
        $marker = ConvertFrom-AxisWizardCodePoints @(0x0020, 0x062A, 0x0644, 0x0642, 0x0627, 0x0626, 0x064A)
        $markerIndex = $Text.IndexOf($marker, [System.StringComparison]::Ordinal)
        if ($markerIndex -ge 0) {
            return @(
                $Text.Substring(0, $markerIndex).Trim()
                $Text.Substring($markerIndex + 1).Trim()
            )
        }
    }

    return @($Text)
}

function New-AxisUpdatesDriversInformationTextGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Step,

        [Parameter(Mandatory)]
        [object]$Resources,

        [double]$MaxWidth = 320.0
    )

    $group = [System.Windows.Controls.Grid]::new()
    $group.Tag = 'AxisFirstUseWizard.UpdatesDriversInformationSharedPhysicalRightEdge'
    $group.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $group.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $group.MaxWidth = $MaxWidth
    $group.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.UpdatesDriversMixedBidiSafeInfoText')

    $rightColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $rightColumn.Width = [System.Windows.GridLength]::Auto
    [void]$group.ColumnDefinitions.Add($rightColumn)

    foreach ($line in @(Split-AxisUpdatesDriversInformationText -Name 'Title' -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'InformationCardTitle' -DefaultValue (Get-AxisWizardArabicText -Name 'UpdatesDriversInfoTitle'))))) {
        [void](Add-AxisWizardGridRow -Grid $group -Child (New-AxisWizardMixedBidiTextBlock `
            -Text $line `
            -Resources $Resources `
            -Tag 'AxisFirstUseWizard.UpdatesDriversInformationTitle' `
            -FontSizeKey 'Axis.Type.Caption.FontSize' `
            -FontWeightKey 'Axis.Type.CardTitle.FontWeight' `
            -FontFamilyKey 'Axis.Type.Caption.FontFamily' `
            -ForegroundKey 'Axis.Brush.Wizard.TextPrimary' `
            -MaxWidth $MaxWidth))
    }

    $itemNames = @('Setupcomplete', 'WindowsUpdate')
    $items = @(Get-AxisWizardMapValue -Map $Step -Name 'InformationItems' -DefaultValue @())
    for ($itemIndex = 0; $itemIndex -lt $items.Count; $itemIndex++) {
        $itemContainer = [System.Windows.Controls.Grid]::new()
        $itemContainer.Tag = 'AxisFirstUseWizard.UpdatesDriversInformationItem'
        $itemContainer.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
        $itemContainer.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
        $itemContainer.MaxWidth = $MaxWidth
        $itemContainer.Margin = New-AxisWizardThickness -Left 0 -Top 3 -Right 0 -Bottom 0

        $itemColumn = [System.Windows.Controls.ColumnDefinition]::new()
        $itemColumn.Width = [System.Windows.GridLength]::Auto
        [void]$itemContainer.ColumnDefinitions.Add($itemColumn)

        $splitName = if ($itemIndex -lt $itemNames.Count) { $itemNames[$itemIndex] } else { 'Setupcomplete' }
        foreach ($line in @(Split-AxisUpdatesDriversInformationText -Name $splitName -Text ([string]$items[$itemIndex]))) {
            [void](Add-AxisWizardGridRow -Grid $itemContainer -Child (New-AxisWizardMixedBidiTextBlock `
                -Text $line `
                -Resources $Resources `
                -Tag 'AxisFirstUseWizard.UpdatesDriversInformationItemLine' `
                -FontSizeKey 'Axis.Type.Caption.FontSize' `
                -FontWeightKey 'Axis.Type.Body.FontWeight' `
                -FontFamilyKey 'Axis.Type.Caption.FontFamily' `
                -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
                -MaxWidth $MaxWidth))
        }

        [void](Add-AxisWizardGridRow -Grid $group -Child $itemContainer)
    }

    return $group
}

function Split-AxisToBiosInformationText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Title', 'Restart', 'UsbBoot', 'Install')]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Text
    )

    if ($Name -in @('Title', 'Restart')) {
        return @($Text)
    }

    if ($Name -eq 'UsbBoot') {
        $marker = ' Windows '
        $markerIndex = $Text.IndexOf($marker, [System.StringComparison]::Ordinal)
        if ($markerIndex -ge 0) {
            return @(
                $Text.Substring(0, $markerIndex + ' Windows'.Length).Trim()
                $Text.Substring($markerIndex + $marker.Length).Trim()
            )
        }
    }

    if ($Name -eq 'Install') {
        $arabicComma = [string][char]0x060C
        $commaIndex = $Text.IndexOf($arabicComma, [System.StringComparison]::Ordinal)
        if ($commaIndex -ge 0) {
            return @(
                $Text.Substring(0, $commaIndex + 1).Trim()
                $Text.Substring($commaIndex + 1).Trim()
            )
        }
    }

    return @($Text)
}

function New-AxisToBiosInformationTextGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Step,

        [Parameter(Mandatory)]
        [object]$Resources,

        [double]$MaxWidth = 650.0
    )

    $group = [System.Windows.Controls.Grid]::new()
    $group.Tag = 'AxisFirstUseWizard.ToBiosInformationSharedPhysicalRightEdge'
    $group.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $group.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $group.MaxWidth = $MaxWidth
    $group.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.ToBiosMixedBidiSafeInfoText')

    $rightColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $rightColumn.Width = [System.Windows.GridLength]::Auto
    [void]$group.ColumnDefinitions.Add($rightColumn)

    foreach ($line in @(Split-AxisToBiosInformationText -Name 'Title' -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'InformationCardTitle' -DefaultValue (Get-AxisWizardArabicText -Name 'ToBiosInfoTitle'))))) {
        [void](Add-AxisWizardGridRow -Grid $group -Child (New-AxisWizardMixedBidiTextBlock `
            -Text $line `
            -Resources $Resources `
            -Tag 'AxisFirstUseWizard.ToBiosInformationTitle' `
            -FontSizeKey 'Axis.Type.CardTitle.FontSize' `
            -FontWeightKey 'Axis.Type.CardTitle.FontWeight' `
            -FontFamilyKey 'Axis.Type.BodySmall.FontFamily' `
            -ForegroundKey 'Axis.Brush.Wizard.TextPrimary' `
            -MaxWidth $MaxWidth))
    }

    $itemNames = @('Restart', 'UsbBoot', 'Install')
    $items = @(Get-AxisWizardMapValue -Map $Step -Name 'InformationItems' -DefaultValue @())
    for ($itemIndex = 0; $itemIndex -lt $items.Count; $itemIndex++) {
        $itemContainer = [System.Windows.Controls.Grid]::new()
        $itemContainer.Tag = 'AxisFirstUseWizard.ToBiosInformationItem'
        $itemContainer.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
        $itemContainer.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
        $itemContainer.MaxWidth = $MaxWidth
        $itemContainer.Margin = New-AxisWizardThickness -Left 0 -Top 2 -Right 0 -Bottom 0

        $itemColumn = [System.Windows.Controls.ColumnDefinition]::new()
        $itemColumn.Width = [System.Windows.GridLength]::Auto
        [void]$itemContainer.ColumnDefinitions.Add($itemColumn)

        $splitName = if ($itemIndex -lt $itemNames.Count) { $itemNames[$itemIndex] } else { 'Restart' }
        foreach ($line in @(Split-AxisToBiosInformationText -Name $splitName -Text ([string]$items[$itemIndex]))) {
            [void](Add-AxisWizardGridRow -Grid $itemContainer -Child (New-AxisWizardMixedBidiTextBlock `
                -Text $line `
                -Resources $Resources `
                -Tag 'AxisFirstUseWizard.ToBiosInformationItemLine' `
                -FontSizeKey 'Axis.Type.Caption.FontSize' `
                -FontWeightKey 'Axis.Type.Body.FontWeight' `
                -FontFamilyKey 'Axis.Type.Caption.FontFamily' `
                -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
                -MaxWidth $MaxWidth))
        }

        [void](Add-AxisWizardGridRow -Grid $group -Child $itemContainer)
    }

    return $group
}

function Get-AxisWizardSelectorComboBoxStyle {
    [CmdletBinding()]
    param()

    if ($null -eq $script:AxisFirstUseWizardSelectorComboBoxStyle) {
        $styleXaml = @'
<Style xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
       xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
       TargetType="{x:Type ComboBox}">
  <Setter Property="Background" Value="{DynamicResource Axis.Brush.Wizard.SurfaceSoft}" />
  <Setter Property="Foreground" Value="{DynamicResource Axis.Brush.Wizard.TextPrimary}" />
  <Setter Property="BorderBrush" Value="{DynamicResource Axis.Brush.Wizard.BorderStrong}" />
  <Setter Property="BorderThickness" Value="1" />
  <Setter Property="Padding" Value="12,6,12,6" />
  <Setter Property="SnapsToDevicePixels" Value="True" />
  <Setter Property="UseLayoutRounding" Value="True" />
  <Setter Property="ScrollViewer.CanContentScroll" Value="True" />
  <Setter Property="Template">
    <Setter.Value>
      <ControlTemplate TargetType="{x:Type ComboBox}">
        <!-- AxisFirstUseWizard.SharedDarkSelectorStyle -->
        <!-- AxisFirstUseWizard.SelectorPopupNotNativeWhite -->
        <!-- AxisFirstUseWizard.SelectorHoverSelectedStates -->
        <Grid SnapsToDevicePixels="True" UseLayoutRounding="True">
          <ToggleButton x:Name="ToggleButton"
                        Focusable="False"
                        ClickMode="Press"
                        IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}">
            <ToggleButton.Template>
              <ControlTemplate TargetType="{x:Type ToggleButton}">
                <ContentPresenter />
              </ControlTemplate>
            </ToggleButton.Template>
            <Border x:Name="Chrome"
                    Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}"
                    CornerRadius="12"
                    Padding="{TemplateBinding Padding}"
                    SnapsToDevicePixels="True"
                    UseLayoutRounding="True">
              <Grid>
                <Grid.ColumnDefinitions>
                  <ColumnDefinition Width="*" />
                  <ColumnDefinition Width="22" />
                </Grid.ColumnDefinitions>
                <ContentPresenter x:Name="ContentSite"
                                  Content="{TemplateBinding SelectionBoxItem}"
                                  ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                                  ContentTemplateSelector="{TemplateBinding ItemTemplateSelector}"
                                  HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}"
                                  VerticalAlignment="Center"
                                  IsHitTestVisible="False"
                                  Margin="0"
                                  RecognizesAccessKey="True"
                                  SnapsToDevicePixels="True"
                                  UseLayoutRounding="True" />
                <Path Grid.Column="1"
                      Data="M 0 0 L 4 4 L 8 0 Z"
                      Fill="{DynamicResource Axis.Brush.Wizard.TextSecondary}"
                      HorizontalAlignment="Center"
                      VerticalAlignment="Center"
                      Stretch="Uniform"
                      Width="8"
                      Height="5" />
              </Grid>
            </Border>
          </ToggleButton>
          <Popup x:Name="PART_Popup"
                 AllowsTransparency="True"
                 Focusable="False"
                 IsOpen="{TemplateBinding IsDropDownOpen}"
                 Placement="Bottom"
                 PopupAnimation="Fade">
            <Grid MinWidth="{Binding ActualWidth, RelativeSource={RelativeSource TemplatedParent}}"
                  MaxHeight="{TemplateBinding MaxDropDownHeight}">
              <Border Background="{DynamicResource Axis.Brush.Wizard.ElevatedCard}"
                      BorderBrush="{DynamicResource Axis.Brush.Wizard.BorderStrong}"
                      BorderThickness="1"
                      CornerRadius="12"
                      Margin="0,4,0,0"
                      Padding="4"
                      SnapsToDevicePixels="True"
                      UseLayoutRounding="True">
                <ScrollViewer SnapsToDevicePixels="True"
                              UseLayoutRounding="True"
                              CanContentScroll="True"
                              VerticalScrollBarVisibility="Auto">
                  <ItemsPresenter />
                </ScrollViewer>
              </Border>
            </Grid>
          </Popup>
        </Grid>
        <ControlTemplate.Triggers>
          <Trigger Property="IsMouseOver" Value="True">
            <Setter TargetName="Chrome" Property="Background" Value="{DynamicResource Axis.Brush.Wizard.SecondaryButtonHover}" />
            <Setter TargetName="Chrome" Property="BorderBrush" Value="{DynamicResource Axis.Brush.Wizard.BorderStrong}" />
          </Trigger>
          <Trigger Property="IsKeyboardFocusWithin" Value="True">
            <Setter TargetName="Chrome" Property="BorderBrush" Value="{DynamicResource Axis.Brush.Wizard.TextHighlight}" />
          </Trigger>
          <Trigger Property="IsDropDownOpen" Value="True">
            <Setter TargetName="Chrome" Property="Background" Value="{DynamicResource Axis.Brush.Wizard.SecondaryButtonHover}" />
            <Setter TargetName="Chrome" Property="BorderBrush" Value="{DynamicResource Axis.Brush.Wizard.TextHighlight}" />
          </Trigger>
          <Trigger Property="IsEnabled" Value="False">
            <Setter TargetName="Chrome" Property="Opacity" Value="0.62" />
          </Trigger>
        </ControlTemplate.Triggers>
      </ControlTemplate>
    </Setter.Value>
  </Setter>
</Style>
'@
        $script:AxisFirstUseWizardSelectorComboBoxStyle = [System.Windows.Markup.XamlReader]::Parse($styleXaml)
    }

    return $script:AxisFirstUseWizardSelectorComboBoxStyle
}

function New-AxisWizardSelectorComboBoxItemStyle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Resources,

        [System.Windows.HorizontalAlignment]$HorizontalContentAlignment = [System.Windows.HorizontalAlignment]::Right
    )

    $alignment = $HorizontalContentAlignment.ToString()
    $styleXaml = @"
<Style xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
       xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
       TargetType="{x:Type ComboBoxItem}">
  <Setter Property="Background" Value="{DynamicResource Axis.Brush.Wizard.ElevatedCard}" />
  <Setter Property="Foreground" Value="{DynamicResource Axis.Brush.Wizard.TextPrimary}" />
  <Setter Property="BorderBrush" Value="Transparent" />
  <Setter Property="BorderThickness" Value="1" />
  <Setter Property="Padding" Value="12,7,12,7" />
  <Setter Property="HorizontalContentAlignment" Value="$alignment" />
  <Setter Property="Template">
    <Setter.Value>
      <ControlTemplate TargetType="{x:Type ComboBoxItem}">
        <Border x:Name="ItemChrome"
                Background="{TemplateBinding Background}"
                BorderBrush="{TemplateBinding BorderBrush}"
                BorderThickness="{TemplateBinding BorderThickness}"
                CornerRadius="8"
                Padding="{TemplateBinding Padding}"
                SnapsToDevicePixels="True"
                UseLayoutRounding="True">
          <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}"
                            VerticalAlignment="Center"
                            RecognizesAccessKey="True"
                            SnapsToDevicePixels="True"
                            UseLayoutRounding="True" />
        </Border>
        <ControlTemplate.Triggers>
          <Trigger Property="IsHighlighted" Value="True">
            <Setter TargetName="ItemChrome" Property="Background" Value="{DynamicResource Axis.Brush.Wizard.SecondaryButtonHover}" />
            <Setter TargetName="ItemChrome" Property="BorderBrush" Value="{DynamicResource Axis.Brush.Wizard.BorderStrong}" />
            <Setter Property="Foreground" Value="{DynamicResource Axis.Brush.Wizard.TextHighlight}" />
          </Trigger>
          <Trigger Property="IsSelected" Value="True">
            <Setter TargetName="ItemChrome" Property="Background" Value="{DynamicResource Axis.Brush.Wizard.SurfaceSoft}" />
            <Setter TargetName="ItemChrome" Property="BorderBrush" Value="{DynamicResource Axis.Brush.Wizard.TextHighlight}" />
            <Setter Property="Foreground" Value="{DynamicResource Axis.Brush.Wizard.TextPrimary}" />
          </Trigger>
          <Trigger Property="IsEnabled" Value="False">
            <Setter TargetName="ItemChrome" Property="Opacity" Value="0.56" />
            <Setter Property="Foreground" Value="{DynamicResource Axis.Brush.Wizard.TextMuted}" />
          </Trigger>
        </ControlTemplate.Triggers>
      </ControlTemplate>
    </Setter.Value>
  </Setter>
</Style>
"@

    return [System.Windows.Markup.XamlReader]::Parse($styleXaml)
}

function Set-AxisWizardSelectorComboBoxStyle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Windows.Controls.ComboBox]$Selector,

        [Parameter(Mandatory)]
        [object]$Resources,

        [System.Windows.FlowDirection]$FlowDirection = [System.Windows.FlowDirection]::RightToLeft,

        [System.Windows.HorizontalAlignment]$HorizontalContentAlignment = [System.Windows.HorizontalAlignment]::Right,

        [System.Windows.Thickness]$Padding = (New-AxisWizardThickness -Left 12 -Top 6 -Right 12 -Bottom 6)
    )

    [void](Add-AxisResourcesToElement -Element $Selector -Resources $Resources)
    $Selector.Style = Get-AxisWizardSelectorComboBoxStyle
    $Selector.ItemContainerStyle = New-AxisWizardSelectorComboBoxItemStyle -Resources $Resources -HorizontalContentAlignment $HorizontalContentAlignment
    $Selector.FlowDirection = $FlowDirection
    $Selector.HorizontalContentAlignment = $HorizontalContentAlignment
    $Selector.VerticalContentAlignment = [System.Windows.VerticalAlignment]::Center
    $Selector.SnapsToDevicePixels = $true
    $Selector.UseLayoutRounding = $true
    $Selector.Padding = $Padding
    $Selector.Background = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.SurfaceSoft'
    $Selector.BorderBrush = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.BorderStrong'
    $Selector.Foreground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.TextPrimary'
    $Selector.BorderThickness = New-AxisWizardThickness -Left 1
    $Selector.Resources[[System.Windows.SystemColors]::WindowBrushKey] = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.ElevatedCard'
    $Selector.Resources[[System.Windows.SystemColors]::ControlBrushKey] = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.SurfaceSoft'
    $Selector.Resources[[System.Windows.SystemColors]::HighlightBrushKey] = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.SecondaryButtonHover'
    $Selector.Resources[[System.Windows.SystemColors]::HighlightTextBrushKey] = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.TextHighlight'
    $Selector.Resources[[System.Windows.SystemColors]::ControlTextBrushKey] = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.TextPrimary'
    $Selector.Resources[[System.Windows.SystemColors]::InactiveSelectionHighlightBrushKey] = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.SurfaceSoft'
    $Selector.Resources[[System.Windows.SystemColors]::InactiveSelectionHighlightTextBrushKey] = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.TextPrimary'
    $Selector.Resources['AxisFirstUseWizard.SharedDarkSelectorStyle'] = $true
    $Selector.Resources['AxisFirstUseWizard.SelectorPopupNotNativeWhite'] = '#121212'
    $Selector.Resources['AxisFirstUseWizard.SelectorClosedFieldDarkStyle'] = $true
    $Selector.Resources['AxisFirstUseWizard.SelectorHoverSelectedStates'] = $true
    $Selector.Resources['AxisFirstUseWizard.FutureGpuBloatwareSelectorStyleReady'] = $true
}

function New-AxisWizardUsbComboBoxItemStyle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Resources
    )

    return New-AxisWizardSelectorComboBoxItemStyle -Resources $Resources -HorizontalContentAlignment ([System.Windows.HorizontalAlignment]::Right)
}

function Get-AxisFirstUseWizardCanonicalStageNames {
    [CmdletBinding()]
    param()

    return @(
        'Check'
        'Refresh'
        'Setup'
        'Installers'
        'Graphics'
        'Windows'
        'Advanced'
    )
}

function Test-AxisFirstUseWizardStageNameSequence {
    [CmdletBinding()]
    param(
        [string[]]$ActualStageNames,

        [string[]]$ExpectedStageNames = (Get-AxisFirstUseWizardCanonicalStageNames)
    )

    if ($ActualStageNames.Count -ne $ExpectedStageNames.Count) {
        return $false
    }

    for ($index = 0; $index -lt $ExpectedStageNames.Count; $index++) {
        if ($ActualStageNames[$index] -ne $ExpectedStageNames[$index]) {
            return $false
        }
    }

    return $true
}

function Get-AxisFirstUseWizardProjectRoot {
    [CmdletBinding()]
    param()

    return (Split-Path -Parent $PSScriptRoot)
}

function Get-AxisFirstUseWizardOrderedStageNames {
    [CmdletBinding()]
    param(
        [string]$ProjectRoot = (Get-AxisFirstUseWizardProjectRoot)
    )

    $canonicalStageNames = @(Get-AxisFirstUseWizardCanonicalStageNames)
    $stageConfigPath = Join-Path $ProjectRoot 'config\Stages.psd1'
    if (Test-Path -LiteralPath $stageConfigPath -PathType Leaf) {
        $stageConfig = Import-PowerShellDataFile -LiteralPath $stageConfigPath -ErrorAction Stop
        $configuredStageNames = @(
            @($stageConfig.Stages) |
                Where-Object {
                    $_ -is [System.Collections.IDictionary] -and
                    $_.Contains('Name') -and
                    $_.Contains('Order')
                } |
                Sort-Object -Property @{ Expression = { [int]$_['Order'] } } |
                ForEach-Object { [string]$_['Name'] }
        )

        if (Test-AxisFirstUseWizardStageNameSequence -ActualStageNames $configuredStageNames -ExpectedStageNames $canonicalStageNames) {
            return $configuredStageNames
        }
    }

    return $canonicalStageNames
}

function Get-AxisFirstUseWizardCanonicalStages {
    [CmdletBinding()]
    param(
        [string]$ProjectRoot = (Get-AxisFirstUseWizardProjectRoot)
    )

    $stageNames = @(Get-AxisFirstUseWizardOrderedStageNames -ProjectRoot $ProjectRoot)

    return @(
        for ($index = 0; $index -lt $stageNames.Count; $index++) {
            [ordered]@{
                Name = $stageNames[$index]
                State = $(if ($index -eq 0) { 'Current' } else { 'Future' })
                Progress = $(if ($index -eq 0) { 1.0 } else { 0.0 })
            }
        }
    )
}

function Resolve-AxisFirstUseWizardStageItems {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [System.Collections.IEnumerable]$Stages,

        [string]$ProjectRoot = (Get-AxisFirstUseWizardProjectRoot)
    )

    $incomingStagesByName = @{}
    foreach ($stage in @($Stages)) {
        if ($stage -isnot [System.Collections.IDictionary]) {
            continue
        }

        $stageName = [string](Get-AxisWizardMapValue -Map $stage -Name 'Name')
        if (-not [string]::IsNullOrWhiteSpace($stageName)) {
            $incomingStagesByName[$stageName] = $stage
        }
    }

    $orderedStageNames = @(Get-AxisFirstUseWizardOrderedStageNames -ProjectRoot $ProjectRoot)
    return @(
        for ($index = 0; $index -lt $orderedStageNames.Count; $index++) {
            $stageName = $orderedStageNames[$index]
            $sourceStage = $null
            if ($incomingStagesByName.ContainsKey($stageName)) {
                $sourceStage = $incomingStagesByName[$stageName]
            }

            [ordered]@{
                Name = $stageName
                State = $(if ($null -ne $sourceStage) {
                    [string](Get-AxisWizardMapValue -Map $sourceStage -Name 'State' -DefaultValue 'Future')
                }
                elseif ($index -eq 0) {
                    'Current'
                }
                else {
                    'Future'
                })
                Progress = $(if ($null -ne $sourceStage) {
                    [double](Get-AxisWizardMapValue -Map $sourceStage -Name 'Progress' -DefaultValue 0.0)
                }
                elseif ($index -eq 0) {
                    1.0
                }
                else {
                    0.0
                })
            }
        }
    )
}

function New-AxisWizardShadowEffect {
    [CmdletBinding()]
    param(
        [double]$Opacity = 0.12,

        [double]$BlurRadius = 18.0,

        [double]$ShadowDepth = 4.0
    )

    $effect = [System.Windows.Media.Effects.DropShadowEffect]::new()
    $effect.Color = [System.Windows.Media.ColorConverter]::ConvertFromString('#000000')
    $effect.Direction = 270
    $effect.Opacity = $Opacity
    $effect.BlurRadius = $BlurRadius
    $effect.ShadowDepth = $ShadowDepth
    return $effect
}

function New-AxisWizardColorBrush {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Color
    )

    return [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.ColorConverter]::ConvertFromString($Color))
}

function New-AxisWizardSuccessGlowEffect {
    [CmdletBinding()]
    param()

    $effect = [System.Windows.Media.Effects.DropShadowEffect]::new()
    $effect.Color = [System.Windows.Media.ColorConverter]::ConvertFromString('#22C55E')
    $effect.Direction = 0
    $effect.Opacity = 0.58
    $effect.BlurRadius = 14
    $effect.ShadowDepth = 0
    return $effect
}

function Set-AxisWizardButtonHoverResources {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Windows.Controls.Button]$Button,

        [Parameter(Mandatory)]
        [System.Windows.Media.Brush]$HoverBackground,

        [Parameter(Mandatory)]
        [System.Windows.Media.Brush]$HoverBorder
    )

    $Button.Resources['AxisFirstUseWizard.ButtonHoverBackground'] = $HoverBackground
    $Button.Resources['AxisFirstUseWizard.ButtonHoverBorder'] = $HoverBorder
}

function Set-AxisWizardEnabledNextButtonBlue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Windows.Controls.Button]$Button
    )

    $Button.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.EnabledNextButtonBlue')
    $Button.Background = New-AxisWizardColorBrush -Color '#2563EB'
    $Button.BorderBrush = New-AxisWizardColorBrush -Color '#60A5FA'
    $Button.Foreground = New-AxisWizardColorBrush -Color '#FAF9F6'
    $Button.Effect = New-AxisWizardShadowEffect -Opacity 0.20 -BlurRadius 18 -ShadowDepth 3
    $Button.Resources['AxisFirstUseWizard.EnabledNextButtonHoverReadable'] = 'BlueHoverKeepsReadableText'
    Set-AxisWizardButtonHoverResources `
        -Button $Button `
        -HoverBackground (New-AxisWizardColorBrush -Color '#1D4ED8') `
        -HoverBorder (New-AxisWizardColorBrush -Color '#93C5FD')
}

function Get-AxisWizardButtonStyle {
    [CmdletBinding()]
    param()

    if ($null -eq $script:AxisFirstUseWizardButtonStyle) {
        $styleXaml = @'
<Style xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
       xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
       TargetType="{x:Type Button}">
  <Setter Property="MinHeight" Value="36" />
  <Setter Property="Cursor" Value="Hand" />
  <Setter Property="SnapsToDevicePixels" Value="True" />
  <Setter Property="UseLayoutRounding" Value="True" />
  <Setter Property="Template">
    <Setter.Value>
      <ControlTemplate TargetType="{x:Type Button}">
        <Border x:Name="Chrome"
                Background="{TemplateBinding Background}"
                BorderBrush="{TemplateBinding BorderBrush}"
                BorderThickness="{TemplateBinding BorderThickness}"
                CornerRadius="14"
                Margin="0"
                Padding="{TemplateBinding Padding}"
                SnapsToDevicePixels="True"
                UseLayoutRounding="True">
          <ContentPresenter HorizontalAlignment="Center"
                            VerticalAlignment="Center"
                            SnapsToDevicePixels="True"
                            UseLayoutRounding="True"
                            RecognizesAccessKey="True" />
        </Border>
        <ControlTemplate.Triggers>
          <!-- AxisFirstUseWizard.ButtonHoverInteractiveEffect -->
          <!-- AxisFirstUseWizard.ButtonHoverCrispEffect -->
          <!-- AxisFirstUseWizard.ButtonHoverPointerAffordance -->
          <!-- AxisFirstUseWizard.ButtonHoverCrispGlow -->
          <!-- AxisFirstUseWizard.ButtonHoverCrispNoScale -->
          <!-- AxisFirstUseWizard.NoHoverScaleTransform -->
          <!-- AxisFirstUseWizard.NoHoverGrowScale -->
          <MultiTrigger>
            <MultiTrigger.Conditions>
              <Condition Property="IsEnabled" Value="True" />
              <Condition Property="IsMouseOver" Value="True" />
            </MultiTrigger.Conditions>
            <Setter TargetName="Chrome" Property="Background" Value="{DynamicResource AxisFirstUseWizard.ButtonHoverBackground}" />
            <Setter TargetName="Chrome" Property="BorderBrush" Value="{DynamicResource AxisFirstUseWizard.ButtonHoverBorder}" />
            <Setter TargetName="Chrome" Property="Opacity" Value="1" />
            <Setter TargetName="Chrome" Property="Effect">
              <Setter.Value>
                <DropShadowEffect Color="#080808" Opacity="0.30" BlurRadius="12" ShadowDepth="2" />
              </Setter.Value>
            </Setter>
          </MultiTrigger>
          <MultiTrigger>
            <MultiTrigger.Conditions>
              <Condition Property="IsEnabled" Value="True" />
              <Condition Property="IsKeyboardFocusWithin" Value="True" />
            </MultiTrigger.Conditions>
            <Setter TargetName="Chrome" Property="Opacity" Value="1" />
            <Setter TargetName="Chrome" Property="Effect">
              <Setter.Value>
                <DropShadowEffect Color="#080808" Opacity="0.22" BlurRadius="9" ShadowDepth="1" />
              </Setter.Value>
            </Setter>
          </MultiTrigger>
          <!-- AxisFirstUseWizard.ButtonPressedInteractiveEffect -->
          <!-- AxisFirstUseWizard.ButtonPressedInEffect -->
          <MultiTrigger>
            <MultiTrigger.Conditions>
              <Condition Property="IsEnabled" Value="True" />
              <Condition Property="IsPressed" Value="True" />
            </MultiTrigger.Conditions>
            <Setter TargetName="Chrome" Property="Margin" Value="1" />
            <Setter TargetName="Chrome" Property="Opacity" Value="0.92" />
            <Setter TargetName="Chrome" Property="Effect">
              <Setter.Value>
                <DropShadowEffect Color="#080808" Opacity="0.14" BlurRadius="6" ShadowDepth="0" />
              </Setter.Value>
            </Setter>
          </MultiTrigger>
          <!-- AxisFirstUseWizard.DisabledButtonsNoHoverEffect -->
          <!-- AxisFirstUseWizard.DisabledButtonsNoPressedEffect -->
          <Trigger Property="IsEnabled" Value="False">
            <Setter Property="Cursor" Value="Arrow" />
            <Setter TargetName="Chrome" Property="Margin" Value="0" />
            <Setter TargetName="Chrome" Property="Opacity" Value="0.62" />
            <Setter TargetName="Chrome" Property="Effect" Value="{x:Null}" />
          </Trigger>
        </ControlTemplate.Triggers>
        </ControlTemplate>
    </Setter.Value>
  </Setter>
  <Style.Triggers>
    <Trigger Property="IsEnabled" Value="False">
      <Setter Property="Cursor" Value="Arrow" />
    </Trigger>
  </Style.Triggers>
</Style>
'@
        $script:AxisFirstUseWizardButtonStyle = [System.Windows.Markup.XamlReader]::Parse($styleXaml)
    }

    return $script:AxisFirstUseWizardButtonStyle
}

function Get-AxisWizardFilledSquareCheckboxStyle {
    [CmdletBinding()]
    param()

    if ($null -eq $script:AxisFirstUseWizardFilledSquareCheckboxStyle) {
        $styleXaml = @'
<Style xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
       xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
       TargetType="{x:Type CheckBox}">
  <Setter Property="Focusable" Value="False" />
  <Setter Property="Width" Value="16" />
  <Setter Property="Height" Value="16" />
  <Setter Property="Template">
    <Setter.Value>
      <ControlTemplate TargetType="{x:Type CheckBox}">
        <Border x:Name="OuterBox"
                Width="16"
                Height="16"
                Background="Transparent"
                BorderBrush="#EDEDED"
                BorderThickness="1"
                CornerRadius="2"
                SnapsToDevicePixels="True">
          <Border x:Name="InnerFill"
                  Width="8"
                  Height="8"
                  Background="#2563EB"
                  CornerRadius="1"
                  HorizontalAlignment="Center"
                  VerticalAlignment="Center"
                  Opacity="0" />
        </Border>
        <ControlTemplate.Triggers>
          <Trigger Property="IsChecked" Value="True">
            <Setter TargetName="InnerFill" Property="Opacity" Value="1" />
            <Setter TargetName="OuterBox" Property="BorderBrush" Value="#FAF9F6" />
          </Trigger>
          <Trigger Property="IsEnabled" Value="False">
            <Setter TargetName="OuterBox" Property="Opacity" Value="0.62" />
          </Trigger>
        </ControlTemplate.Triggers>
      </ControlTemplate>
    </Setter.Value>
  </Setter>
</Style>
'@
        $script:AxisFirstUseWizardFilledSquareCheckboxStyle = [System.Windows.Markup.XamlReader]::Parse($styleXaml)
    }

    return $script:AxisFirstUseWizardFilledSquareCheckboxStyle
}

function New-AxisWizardTextBlock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [object]$Resources,

        [string]$FontSizeKey = 'Axis.Type.Body.FontSize',
        [string]$FontWeightKey = 'Axis.Type.Body.FontWeight',
        [string]$FontFamilyKey = 'Axis.Type.Body.FontFamily',
        [string]$ForegroundKey = 'Axis.Brush.Wizard.TextSecondary',
        [string]$LineHeightKey = '',
        [System.Windows.Thickness]$Margin = (New-AxisWizardThickness -Left 0),
        [switch]$Wrap,
        [System.Windows.TextAlignment]$TextAlignment = [System.Windows.TextAlignment]::Left,
        [System.Windows.FlowDirection]$FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    )

    $textBlock = [System.Windows.Controls.TextBlock]::new()
    $textBlock.Text = $Text
    $textBlock.FontFamily = Get-AxisWizardResource -Resources $Resources -Name $FontFamilyKey
    $textBlock.FontSize = [double](Get-AxisWizardResource -Resources $Resources -Name $FontSizeKey)
    $textBlock.FontWeight = Get-AxisWizardResource -Resources $Resources -Name $FontWeightKey
    $textBlock.Foreground = Get-AxisWizardResource -Resources $Resources -Name $ForegroundKey
    $textBlock.Margin = $Margin
    $textBlock.TextAlignment = $TextAlignment
    $textBlock.FlowDirection = $FlowDirection
    if ($FlowDirection -eq [System.Windows.FlowDirection]::RightToLeft -and $TextAlignment -eq [System.Windows.TextAlignment]::Right) {
        $textBlock.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    }
    else {
        $textBlock.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    }

    $resolvedLineHeightKey = if ([string]::IsNullOrWhiteSpace($LineHeightKey)) {
        $FontSizeKey -replace '\.FontSize$', '.LineHeight'
    }
    else {
        $LineHeightKey
    }
    $lineHeight = Get-AxisWizardResource -Resources $Resources -Name $resolvedLineHeightKey
    if ($null -ne $lineHeight) {
        $textBlock.LineHeight = [double]$lineHeight
    }

    if ($Wrap) {
        $textBlock.TextWrapping = [System.Windows.TextWrapping]::Wrap
    }

    return $textBlock
}

function Copy-AxisWizardMap {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [System.Collections.IDictionary]$Map
    )

    $copy = [ordered]@{}
    if ($null -eq $Map) {
        return $copy
    }

    foreach ($key in $Map.Keys) {
        $copy[$key] = $Map[$key]
    }

    return $copy
}

function ConvertFrom-AxisWizardCodePoints {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int[]]$CodePoints
    )

    return [string]::Concat(@($CodePoints | ForEach-Object { [char]$_ }))
}

function ConvertFrom-AxisWizardBase64Text {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Value
    )

    return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Value))
}

function Get-AxisWizardSetupText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $values = @{
        BitLockerSubtitle = '2KrYudi32YrZhCDYqti02YHZitixIEJpdExvY2tlciDYudmE2Ykg2KfZhNmC2LHYtS4='
        BitLockerPrimaryAction = '2KXZitmC2KfZgSBCaXRMb2NrZXI='
        BitLockerInfoTitle = '2KrYudi32YrZhCDYqti02YHZitixINin2YTZgtix2LU='
        BitLockerInfoBullet1 = '2KrYudi32YrZhCDYqtmC2YbZitipIEJpdExvY2tlciDYudmE2Ykg2KfZhNmC2LHYtS4='
        BitLockerInfoBullet2 = '2YrYs9in2LnYryDYsNmE2YMg2LnZhNmJINil2LLYp9mE2Kkg2KfZhNiq2LTZgdmK2LEg2YXZhiDYp9mE2YLYsdi1INmC2KjZhCDZhdiq2KfYqNi52Kkg2KXYudiv2KfYryDYp9mE2YbYuNin2YUu'
        BitLockerInfoBullet3 = '2KjYudivINin2YPYqtmF2KfZhCDYp9mE2K7Yt9mI2KnYjCDZiti12KjYrSDYp9mE2YLYsdi1INis2KfZh9iy2YvYpyDZhNmE2YXYqtin2KjYudipINio2K/ZiNmGINiq2LTZgdmK2LEgQml0TG9ja2VyLg=='
        BitLockerRunning = '2KzYp9ix2Yog2KfZhNiq2YbZgdmK2LA='
        BitLockerCompleted = '2YXZg9iq2YXZhA=='
        ConvertHomeToProSubtitle = '2KfZhNiq2K3ZiNmK2YQg2YXZhiDYpdi12K/Yp9ixIFdpbmRvd3MgSG9tZSDYpdmE2YkgV2luZG93cyBQcm8u'
        ConvertHomeToProPrimaryAction = '2KfZhNiq2LHZgtmK2Kkg2KXZhNmJIFdpbmRvd3MgUHJv'
        ConvertHomeToProInfoTitle = '2KrYsdmC2YrYqSDYpdi12K/Yp9ixIFdpbmRvd3M='
        ConvertHomeToProInfoBullet1 = '2KrYrNmH2YrYsiDYp9mE2KrYrdmI2YrZhCDZhdmGINil2LXYr9in2LEgV2luZG93cyBIb21lINil2YTZiSBXaW5kb3dzIFByby4='
        ConvertHomeToProInfoBullet2 = '2LPZitiq2YUg2YHYqtitINmG2KfZgdiw2Kkg2KXYr9iu2KfZhCDZhdmB2KrYp9itINin2YTZhdmG2KrYrCDYr9in2K7ZhCBXaW5kb3dzLg=='
        ConvertHomeToProInfoBullet3 = '2KjYudivINmB2KrYrSDYp9mE2YbYp9mB2LDYqdiMINmK2YXZg9mG2YMg2YTYtdmCINin2YTZhdmB2KrYp9itINmF2KjYp9i02LHYqSDZhNmE2YXYqtin2KjYudipLg=='
        ConvertHomeToProRequirementsTitle = '2KfZhNmF2KrYt9mE2KjYp9iq'
        ConvertHomeToProRequirement1 = '2LPZitiq2YUg2YbYs9iuINin2YTZhdmB2KrYp9itINiq2YTZgtin2KbZitmL2Kcu'
        ConvertHomeToProRequirement2 = '2LnZhtivINi42YfZiNixINmG2KfZgdiw2Kkg2KXYr9iu2KfZhCDYp9mE2YXZgdiq2KfYrdiMINin2LPYqtiu2K/ZhSBDdHJsICsgViDZhNmE2LXZgiDYp9mE2YXZgdiq2KfYrS4='
        ConvertHomeToProRunning = '2YrYqtmFINin2YTYqtis2YfZitiy'
        ConvertHomeToProCompleted = '2KzYp9mH2LIg2YTZhNi12YI='
        MemoryCompressionSubtitle = '2KrYudi32YrZhCDZhdmK2LLYqSBNZW1vcnkgQ29tcHJlc3Npb24g2YXZhiDYp9mE2YbYuNin2YUu'
        MemoryCompressionPrimaryAction = '2KrYudi32YrZhCBNZW1vcnkgQ29tcHJlc3Npb24='
        MemoryCompressionInfoTitle = '2KrYudi32YrZhCDYtti62Lcg2KfZhNiw2KfZg9ix2Kk='
        MemoryCompressionInfoBullet1 = '2KrYudi32YrZhCDZhdmK2LLYqSBNZW1vcnkgQ29tcHJlc3Npb24g2YHZiiBXaW5kb3dzLg=='
        MemoryCompressionInfoBullet2 = '2KrYs9in2LnYryDZh9iw2Ycg2KfZhNiu2LfZiNipINi52YTZiSDYrNi52YQg2KXYr9in2LHYqSDYp9mE2LDYp9mD2LHYqSDYo9mD2KvYsSDZhdio2KfYtNix2Kkg2KPYq9mG2KfYoSDYp9mE2KfYs9iq2K7Yr9in2YUu'
        MemoryCompressionInfoBullet3 = '2YrYqtmFINiq2LfYqNmK2YIg2KfZhNil2LnYr9in2K8g2KrZhNmC2KfYptmK2YvYpyDYqNiv2YjZhiDYo9mKINiu2LfZiNin2Kog2KXYttin2YHZitipINmF2YYg2KfZhNi52YXZitmELg=='
        MemoryCompressionRunning = '2KzYp9ix2Yog2KfZhNiq2YbZgdmK2LA='
        MemoryCompressionCompleted = '2YXZg9iq2YXZhA=='
        DateLanguageRegionTimeTitle = '2KfZhNiq2KfYsdmK2K4g2YjYp9mE2YjZgtiq'
        DateLanguageRegionTimeSubtitle = '2LbYqNi3INil2LnYr9in2K/Yp9iqIFdpbmRvd3Mg2YrYr9mI2YrZi9inLg=='
        DateLanguageRegionTimePrimaryAction = '2KfZgdiq2K0='
        DateLanguageRegionTimeInfoTitle = '2YXYsdin2KzYudipINil2LnYr9in2K/Yp9iqINin2YTZhdmG2LfZgtipINmI2KfZhNmI2YLYqg=='
        DateLanguageRegionTimeInfoBullet1 = '2KfZgdiq2K0g2KXYudiv2KfYr9in2Kog2KfZhNiq2KfYsdmK2K4g2YjYp9mE2YjZgtiqINiv2KfYrtmEIFdpbmRvd3Mu'
        DateLanguageRegionTimeInfoBullet2 = '2LHYp9is2Lkg2KfZhNmE2LrYqSDZiNin2YTZhdmG2LfZgtipINit2LPYqCDYqtmB2LbZitmE2KfYqtmDLg=='
        DateLanguageRegionTimeInfoBullet3 = '2KrYo9mD2K8g2KPZhiDYp9mE2YjZgtiqINmI2KfZhNmF2YbYt9mC2Kkg2YXYttio2YjYt9mK2YYg2YLYqNmEINmF2KrYp9io2LnYqSDYp9mE2KXYudiv2KfYry4='
        DateLanguageRegionTimeRunning = '2KzYp9ix2Yog2KfZhNiq2YbZgdmK2LA='
        DateLanguageRegionTimeCompleted = '2YXZg9iq2YXZhA=='
        StartupAppsSettingsSubtitle = '2KXYudiv2KfYr9in2Kog2KrYt9io2YrZgtin2Kog2KjYr9ihINin2YTYqti02LrZitmELg=='
        StartupAppsSettingsPrimaryAction = '2KfZgdiq2K0='
        StartupAppsSettingsInfoTitle = '2KrYt9io2YrZgtin2Kog2KjYr9ihINin2YTYqti02LrZitmE'
        StartupAppsSettingsInfoBullet1 = '2KfZgdiq2K0g2KXYudiv2KfYr9in2Kog2KrYt9io2YrZgtin2Kog2KjYr9ihINin2YTYqti02LrZitmEINiv2KfYrtmEIFdpbmRvd3Mu'
        StartupAppsSettingsInfoBullet2 = '2LHYp9is2Lkg2KfZhNiq2LfYqNmK2YLYp9iqINin2YTYqtmKINiq2LnZhdmEINiq2YTZgtin2KbZitmL2Kcg2LnZhtivINiq2LTYutmK2YQg2KfZhNis2YfYp9iyLg=='
        StartupAppsSettingsInfoBullet3 = '2KrYudi32YrZhCDYp9mE2KrYt9io2YrZgtin2Kog2LrZitixINin2YTYttix2YjYsdmK2Kkg2YrYs9in2LnYryDYudmE2Ykg2KrYrdiz2YrZhiDYs9ix2LnYqSDYp9mE2KXZgtmE2KfYuS4='
        StartupAppsSettingsRequirementsTitle = '2KfZhNmF2KrYt9mE2KjYp9iq'
        StartupAppsSettingsRequirement1 = '2YLZhSDYqNil2LrZhNin2YIg2KzZhdmK2Lkg2KfZhNiq2LfYqNmK2YLYp9iqINmC2KjZhCDYp9mE2YXYqtin2KjYudipLg=='
        StartupAppsSettingsRequirement2 = '2YfYsNmHINin2YTYrti32YjYqSDZhdmI2LXZiSDYqNmH2Kcg2YTZhNit2LXZiNmEINi52YTZiSDZhdix2KfYrNi52Kkg2KPZiNi22K0g2YTYqti32KjZitmC2KfYqiDYqNiv2KEg2KfZhNiq2LTYutmK2YQu'
        StartupAppsSettingsRunning = '2KzYp9ix2Yog2KfZhNiq2YbZgdmK2LA='
        StartupAppsSettingsCompleted = '2YXZg9iq2YXZhA=='
        StartupAppsTaskManagerSubtitle = '2KXYudiv2KfYr9in2Kog2KjYr9ihINin2YTYqti02LrZitmEINmF2YYgVGFzayBNYW5hZ2VyLg=='
        StartupAppsTaskManagerPrimaryAction = '2KfZgdiq2K0='
        StartupAppsTaskManagerInfoTitle = '2YXYsdin2KzYudipINio2K/YoSDYp9mE2KrYtNi62YrZhA=='
        StartupAppsTaskManagerInfoBullet1 = '2KfZgdiq2K0gVGFzayBNYW5hZ2VyINi52YTZiSDZgtiz2YUg2KrYt9io2YrZgtin2Kog2KjYr9ihINin2YTYqti02LrZitmELg=='
        StartupAppsTaskManagerInfoBullet2 = '2LHYp9is2Lkg2KfZhNiq2LfYqNmK2YLYp9iqINin2YTYqtmKINiq2LnZhdmEINiq2YTZgtin2KbZitmL2Kcg2LnZhtivINil2YLZhNin2LkgV2luZG93cy4='
        StartupAppsTaskManagerInfoBullet3 = '2YfYsNmHINin2YTZhdix2KfYrNi52Kkg2KrYs9in2LnYr9mDINi52YTZiSDYqti52LfZitmEINin2YTYudmG2KfYtdixINi62YrYsSDYp9mE2LbYsdmI2LHZitipLg=='
        StartupAppsTaskManagerRequirementsTitle = '2KfZhNmF2KrYt9mE2KjYp9iq'
        StartupAppsTaskManagerRequirement1 = '2YLZhSDYqNil2LrZhNin2YIg2KzZhdmK2Lkg2KfZhNiq2LfYqNmK2YLYp9iqINmC2KjZhCDYp9mE2YXYqtin2KjYudipLg=='
        StartupAppsTaskManagerRequirement2 = '2YfYsNmHINin2YTYrti32YjYqSDZhdmI2LXZiSDYqNmH2Kcg2YLYqNmEINmF2LHYp9is2LnYqSDYqti32KjZitmC2KfYqiDYqNiv2KEg2KfZhNiq2LTYutmK2YQu'
        StartupAppsTaskManagerRunning = '2KzYp9ix2Yog2KfZhNiq2YbZgdmK2LA='
        StartupAppsTaskManagerCompleted = '2YXZg9iq2YXZhA=='
        BackgroundAppsTitle = '2KrYt9io2YrZgtin2Kog2KfZhNiu2YTZgdmK2Kk='
        BackgroundAppsSubtitle = '2KrYudi32YrZhCDYudmF2YQg2KfZhNiq2LfYqNmK2YLYp9iqINmB2Yog2KfZhNiu2YTZgdmK2Kku'
        BackgroundAppsPrimaryAction = '2KrYudi32YrZhCDYqti32KjZitmC2KfYqiDYp9mE2K7ZhNmB2YrYqQ=='
        BackgroundAppsInfoTitle = '2KrZgtmE2YrZhCDZhti02KfYtyDYp9mE2KrYt9io2YrZgtin2Ko='
        BackgroundAppsInfoBullet1 = '2KrYudi32YrZhCDYudmF2YQg2KfZhNiq2LfYqNmK2YLYp9iqINi62YrYsSDYp9mE2LbYsdmI2LHZitipINmB2Yog2KfZhNiu2YTZgdmK2Kku'
        BackgroundAppsInfoBullet2 = '2YrYs9in2LnYryDYsNmE2YMg2LnZhNmJINiq2YLZhNmK2YQg2KfYs9iq2YfZhNin2YMg2KfZhNmF2YjYp9ix2K8g2KPYq9mG2KfYoSDYp9iz2KrYrtiv2KfZhSDYp9mE2KzZh9in2LIu'
        BackgroundAppsInfoBullet3 = '2YrYqtmFINiq2LfYqNmK2YIg2KfZhNil2LnYr9in2K8g2KrZhNmC2KfYptmK2YvYpyDYqNiv2YjZhiDYp9mE2K3Yp9is2Kkg2KXZhNmJINiu2LfZiNin2Kog2KXYttin2YHZitipLg=='
        BackgroundAppsRunning = '2KzYp9ix2Yog2KfZhNiq2YbZgdmK2LA='
        BackgroundAppsCompleted = '2YXZg9iq2YXZhA=='
        EdgeSettingsSubtitle = '2LbYqNi3IE1pY3Jvc29mdCBFZGdlINmI2KrZgtmE2YrZhCDYp9mE2KXYudiv2KfYr9in2Kog2LrZitixINin2YTYttix2YjYsdmK2Kku'
        EdgeSettingsPrimaryAction = 'T3B0aW1pemUgTWljcm9zb2Z0IEVkZ2U='
        EdgeSettingsInfoTitle = '2KrYrdiz2YrZhiDYpdi52K/Yp9iv2KfYqiDYp9mE2YXYqti12YHYrQ=='
        EdgeSettingsInfoBullet1 = '2LbYqNi3INil2LnYr9in2K/Yp9iqIE1pY3Jvc29mdCBFZGdlINmE2KrYrNix2KjYqSDYp9iz2KrYrtiv2KfZhSDYo9mG2LjZgS4='
        EdgeSettingsInfoBullet2 = '2KrZgtmE2YrZhCDYp9mE2LnZhtin2LXYsSDZiNin2YTYpdi52K/Yp9iv2KfYqiDYutmK2LEg2KfZhNi22LHZiNix2YrYqSDYr9in2K7ZhCDYp9mE2YXYqti12YHYrS4='
        EdgeSettingsInfoBullet3 = '2YrYqtmFINiq2LfYqNmK2YIg2KfZhNil2LnYr9in2K/Yp9iqINin2YTZhdmG2KfYs9io2Kkg2KrZhNmC2KfYptmK2YvYpyDYo9ir2YbYp9ihINmH2LDZhyDYp9mE2K7Yt9mI2Kku'
        EdgeSettingsRunning = '2KzYp9ix2Yog2KfZhNiq2YbZgdmK2LA='
        EdgeSettingsCompleted = '2YXZg9iq2YXZhA=='
        StoreSettingsSubtitle = '2LbYqNi3IE1pY3Jvc29mdCBTdG9yZSDZiNiq2YLZhNmK2YQg2KfZhNil2LnYr9in2K/Yp9iqINi62YrYsSDYp9mE2LbYsdmI2LHZitipLg=='
        StoreSettingsPrimaryAction = 'T3B0aW1pemUgTWljcm9zb2Z0IFN0b3Jl'
        StoreSettingsInfoTitle = '2KrYrdiz2YrZhiDYpdi52K/Yp9iv2KfYqiDYp9mE2YXYqtis2LE='
        StoreSettingsInfoBullet1 = '2LbYqNi3INil2LnYr9in2K/Yp9iqIE1pY3Jvc29mdCBTdG9yZSDZhNiq2KzYsdio2Kkg2KfYs9iq2K7Yr9in2YUg2KPZhti42YEu'
        StoreSettingsInfoBullet2 = '2KrZgtmE2YrZhCDYp9mE2LnZhtin2LXYsSDZiNin2YTYpdi52K/Yp9iv2KfYqiDYutmK2LEg2KfZhNi22LHZiNix2YrYqSDYr9in2K7ZhCDYp9mE2YXYqtis2LEu'
        StoreSettingsInfoBullet3 = '2YrYqtmFINiq2LfYqNmK2YIg2KfZhNil2LnYr9in2K/Yp9iqINin2YTZhdmG2KfYs9io2Kkg2KrZhNmC2KfYptmK2YvYpyDYo9ir2YbYp9ihINmH2LDZhyDYp9mE2K7Yt9mI2Kku'
        StoreSettingsRunning = '2KzYp9ix2Yog2KfZhNiq2YbZgdmK2LA='
        StoreSettingsCompleted = '2YXZg9iq2YXZhA=='
        UpdatesPauseSubtitle = '2KXZitmC2KfZgSDZhdik2YLYqiDZhNiq2K3Yr9mK2KvYp9iqIFdpbmRvd3Mu'
        UpdatesPausePrimaryAction = '2KXZitmC2KfZgSDYp9mE2KrYrdiv2YrYq9in2Ko='
        UpdatesPauseInfoTitle = '2KXZitmC2KfZgSDYqtit2K/Zitir2KfYqiBXaW5kb3dzINmF2KTZgtiq2YvYpw=='
        UpdatesPauseInfoBullet1 = '2KXZitmC2KfZgSDYqtit2K/Zitir2KfYqiBXaW5kb3dzINmF2KTZgtiq2YvYpyDZhNiq2YLZhNmK2YQg2KfZhNmF2YLYp9i32LnYp9iqINij2KvZhtin2KEg2KfYs9iq2K7Yr9in2YUg2KfZhNis2YfYp9iyLg=='
        UpdatesPauseInfoBullet2 = '2YrYs9in2LnYryDYsNmE2YMg2LnZhNmJINiq2YjZgdmK2LEg2KrYrNix2KjYqSDYo9mD2KvYsSDZh9iv2YjYodmL2Kcg2KjYr9mI2YYg2KfZhti02LrYp9mEINmF2LPYqtmF2LEg2KjYp9mE2KrYrdiv2YrYq9in2Kou'
        UpdatesPauseInfoBullet3 = '2YrZhdmD2YYg2YXYqtin2KjYudipINil2LnYr9in2K8g2KfZhNmG2LjYp9mFINio2LnYryDYp9mD2KrZhdin2YQg2YfYsNmHINin2YTYrti32YjYqS4='
        UpdatesPauseRequirementsTitle = '2KfZhNmF2KrYt9mE2KjYp9iq'
        UpdatesPauseRequirement1 = '2KfZgtix2KMg2KfZhNiq2LnZhNmK2YXYp9iqINmC2KjZhCDYpdmK2YLYp9mBINin2YTYqtit2K/Zitir2KfYqi4='
        UpdatesPauseConfirmationCheckbox = '2YTZgtivINmC2LHYo9iqINin2YTYqti52YTZitmF2KfYqg=='
        UpdatesPauseConfirmationPrimary = '2KXZitmC2KfZgSDYp9mE2KrYrdiv2YrYq9in2Ko='
        UpdatesPauseConfirmationReturn = '2LHYrNmI2Lk='
        UpdatesPauseRunning = '2KzYp9ix2Yog2KfZhNiq2YbZgdmK2LA='
        UpdatesPauseCompleted = '2YXZg9iq2YXZhA=='
    }

    if (-not $values.ContainsKey($Name)) {
        throw "Unknown AXIS Setup text resource: $Name"
    }

    return ConvertFrom-AxisWizardBase64Text -Value ([string]$values[$Name])
}

function Get-AxisWizardGraphicsText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $values = @{
        DriverCleanTitle = 'RHJpdmVyIENsZWFu'
        DriverCleanSubtitle = '2KrZhti42YrZgSDYqti52LHZitmB2KfYqiDZg9ix2Kog2KfZhNi02KfYtNipINmC2KjZhCDYqtir2KjZitiqINin2YTYqti52LHZitmBINin2YTYrNiv2YrYry4='
        DriverCleanPrimary = '2KrZhti42YrZgSDYp9mE2KrYudix2YrZgdin2Ko='
        DriverCleanInfoTitle = '2KrZhti42YrZgSDYqti52LHZitmB2KfYqiDZg9ix2Kog2KfZhNi02KfYtNip'
        DriverCleanInfoBullet1 = '2KrZhti42YrZgSDYqti52LHZitmB2KfYqiDZg9ix2Kog2KfZhNi02KfYtNipINin2YTZgtiv2YrZhdipINmC2KjZhCDYqtir2KjZitiqINin2YTYqti52LHZitmBINin2YTYrNiv2YrYry4='
        DriverCleanInfoBullet2 = '2YrYqtmFINiq2YbZgdmK2LAg2K7Yt9mI2Kkg2KfZhNiq2YbYuNmK2YEg2KrZhNmC2KfYptmK2YvYpyDYrdiz2Kgg2KfZhNmF2LPYp9ixINin2YTZhdi52KrZhdivLg=='
        DriverCleanInfoBullet3 = '2KjYudivINin2YPYqtmF2KfZhCDYp9mE2KrZhti42YrZgdiMINmK2YXZg9mG2YMg2YXYqtin2KjYudipINil2LnYr9in2K8g2KfZhNiq2LnYsdmK2YEg2KfZhNis2K/ZitivLg=='
        DriverCleanRequirement1 = '2KfZgtix2KMg2KfZhNiq2LnZhNmK2YXYp9iqINmC2KjZhCDYqNiv2KEg2KrZhti42YrZgSDYp9mE2KrYudix2YrZgdin2Kou'
        DriverCleanRequirement2 = '2KfYrdmB2Lgg2KPZiiDYudmF2YQg2YXZgdiq2YjYrSDZgtio2YQg2KfZhNmF2KrYp9io2LnYqS4='
        DriverCleanRequirement3 = '2KfZhtiq2LjYsSDYrdiq2Ykg2KrZg9iq2YXZhCDYp9mE2LnZhdmE2YrYqSDYqNin2YTZg9in2YXZhC4='
        DriverCleanRunning = '2KzYp9ix2Yog2KfZhNiq2YbZgdmK2LA='
        GpuSetupSelectorLabel = '2KfYrtiq2LEg2YbZiNi5INmD2LHYqiDYp9mE2LTYp9i02Kk='
        GpuSetupAmdLater = 'QU1EIOKAlCDZhNin2K3ZgtmL2Kc='
        GpuSetupIntelLater = 'SW50ZWwg4oCUINmE2KfYrdmC2YvYpw=='
        GpuSetupSubtitle = '2KrYq9io2YrYqiDZiNi22KjYtyDYqti52LHZitmBINmD2LHYqiDYp9mE2LTYp9i02Kku'
        GpuSetupPrimary = '2KrYq9io2YrYqiDZiNi22KjYtyDYp9mE2KrYudix2YrZgQ=='
        GpuSetupInfoTitle = '2KrYq9io2YrYqiDZiNi22KjYtyDYqti52LHZitmBINmD2LHYqiDYp9mE2LTYp9i02Kk='
        GpuSetupInfoBullet1 = '2YrYqtmFINmB2KrYrSDYtdmB2K3YqSBOVklESUEg2KfZhNix2LPZhdmK2Kkg2YTYqtit2YXZitmEINin2YTYqti52LHZitmBINin2YTZhdmG2KfYs9ioINit2LPYqCDZhtmI2Lkg2YPYsdiqINin2YTYtNin2LTYqS4='
        GpuSetupInfoBullet2 = '2KjYudivINiq2K3ZhdmK2YQg2KfZhNiq2LnYsdmK2YHYjCDYp9iu2KrYsSDZhdmE2YEg2KfZhNiq2LnYsdmK2YEg2YXZhiDZhtin2YHYsNipINin2K7YqtmK2KfYsSDYp9mE2KrYudix2YrZgS4='
        GpuSetupInfoBullet3 = '2KjYudivINin2K7YqtmK2KfYsSDYp9mE2YXZhNmB2Iwg2YrYqtmFINiq2KvYqNmK2Kog2KfZhNiq2LnYsdmK2YEg2YjYttio2Lcg2KfZhNil2LnYr9in2K/Yp9iqINin2YTZhdmG2KfYs9io2Kkg2KrZhNmC2KfYptmK2YvYpy4='
        GpuSetupRequirement1 = '2KfZgtix2KMg2KfZhNiq2LnZhNmK2YXYp9iqINmC2KjZhCDYqNiv2KEg2KrYq9io2YrYqiDZiNi22KjYtyDYp9mE2KrYudix2YrZgS4='
        GpuSetupRequirement2 = '2KfYrtiq2LEg2YbZiNi5INmD2LHYqiDYp9mE2LTYp9i02Kkg2KfZhNi12K3ZititINmC2KjZhCDYp9mE2YXYqtin2KjYudipLg=='
        GpuSetupRequirement3 = '2KfYqtio2Lkg2YbYp9mB2LDYqSDYp9iu2KrZitin2LEg2KfZhNiq2LnYsdmK2YEg2LnZhtivINi42YfZiNix2YfYpy4='
        GpuSetupRunning = '2KzYp9ix2Yog2KfZhNiq2YbZgdmK2LA='
        NvidiaAppSubtitle = '2KrYq9io2YrYqiDYqti32KjZitmCIE5WSURJQSDZhNmE2K3YtdmI2YQg2LnZhNmJINmF2YrYstin2Kog2KfZhNiq2LfYqNmK2YIu'
        NvidiaAppOptionalContinuation = '2YXYqtin2KjYudipINio2K/ZiNmGIE5WSURJQSBBcHA='
        NvidiaAppInfoTitle = '2KrYq9io2YrYqiDYqti32KjZitmCIE5WSURJQQ=='
        NvidiaAppInfoBullet1 = '2KrYq9io2YrYqiBOVklESUEgQXBwINmE2YXZhiDZitix2YrYryDZhdmK2LLYp9iqINin2YTYqti32KjZitmCINmF2KvZhCDYp9mE2KrYs9is2YrZhCDZiNin2YTYqti12YjZitixLg=='
        NvidiaAppInfoBullet2 = '2YrZhdmD2YYg2YXYqtin2KjYudipINin2YTYpdi52K/Yp9ivINio2K/ZiNmGINiq2KvYqNmK2Kog2KfZhNiq2LfYqNmK2YIg2KXYsNinINmE2YUg2KrZg9mGINiq2K3Yqtin2Kwg2YfYsNmHINin2YTZhdmK2LLYp9iqLg=='
        NvidiaAppInfoBullet3 = '2KrYudix2YrZgSDZg9ix2Kog2KfZhNi02KfYtNipINmK2YPZiNmGINmF2KvYqNiq2YvYpyDZiNmF2LbYqNmI2LfZi9inINmF2YYg2KfZhNiu2LfZiNipINin2YTYs9in2KjZgtipLg=='
        NvidiaAppRunning = '2KzYp9ix2Yog2KfZhNiq2KvYqNmK2Ko='
        NvidiaAppCompleted = '2KrZhSDYp9mE2KrYq9io2YrYqg=='
        DirectXSubtitle = '2KrYq9io2YrYqiDZhdmD2YjZhtin2KogRGlyZWN0WCDYp9mE2YXYt9mE2YjYqNipINmE2YTYo9mE2LnYp9ioINmI2KfZhNio2LHYp9mF2Kwu'
        DirectXPrimary = '2KrYq9io2YrYqiBEaXJlY3RY'
        DirectXInfoTitle = '2YXZg9mI2YbYp9iqINiq2LTYutmK2YQg2KfZhNij2YTYudin2Kgg2YjYp9mE2KjYsdin2YXYrA=='
        DirectXInfoBullet1 = '2KrYq9io2YrYqiDZhdmD2YjZhtin2KogRGlyZWN0WCDYp9mE2LbYsdmI2LHZitipINmE2KrYtNi62YrZhCDYp9mE2LnYr9mK2K8g2YXZhiDYp9mE2KPZhNi52KfYqCDZiNin2YTYqNix2KfZhdisLg=='
        DirectXInfoBullet2 = '2KrYs9in2LnYryDZh9iw2Ycg2KfZhNmF2YPZiNmG2KfYqiDYudmE2Ykg2KrYrdiz2YrZhiDYqtmI2KfZgdmCINin2YTYo9mE2LnYp9ioINmI2KfZhNio2LHYp9mF2Kwg2YXYuSBXaW5kb3dzLg=='
        DirectXInfoBullet3 = '2YrYqtmFINiq2KzZh9mK2LIg2KfZhNmF2YPZiNmG2KfYqiDZiNiq2KvYqNmK2KrZh9inINiq2YTZgtin2KbZitmL2Kcg2KPYq9mG2KfYoSDZh9iw2Ycg2KfZhNiu2LfZiNipLg=='
        DirectXRunning = '2KzYp9ix2Yog2KfZhNiq2K3ZhdmK2YQ='
        VisualCppSubtitle = '2KrYq9io2YrYqiDZhdmD2YjZhtin2Kog2KrYtNi62YrZhCDYttix2YjYsdmK2Kkg2YTZhNij2YTYudin2Kgg2YjYp9mE2KjYsdin2YXYrC4='
        VisualCppPrimary = '2KrYq9io2YrYqiDZhdmD2YjZhtin2KogVmlzdWFsIEMrKw=='
        VisualCppInfoTitle = '2YXZg9mI2YbYp9iqINiq2LTYutmK2YQg2KfZhNij2YTYudin2Kgg2YjYp9mE2KjYsdin2YXYrA=='
        VisualCppInfoBullet1 = '2KrYq9io2YrYqiDZhdmD2YjZhtin2KogVmlzdWFsIEMrKyDYp9mE2LbYsdmI2LHZitipINmE2KrYtNi62YrZhCDYp9mE2LnYr9mK2K8g2YXZhiDYp9mE2KPZhNi52KfYqCDZiNin2YTYqNix2KfZhdisLg=='
        VisualCppInfoBullet2 = '2KrYs9in2LnYryDZh9iw2Ycg2KfZhNmF2YPZiNmG2KfYqiDYudmE2Ykg2KrYrdiz2YrZhiDYqtmI2KfZgdmCINin2YTYqNix2KfZhdisINin2YTYqtmKINiq2K3Yqtin2Kwg2YXZg9iq2KjYp9iqINiq2LTYutmK2YQg2KXYttin2YHZitipLg=='
        VisualCppInfoBullet3 = '2YrYqtmFINiq2KzZh9mK2LIg2KfZhNmF2YPZiNmG2KfYqiDZiNiq2KvYqNmK2KrZh9inINiq2YTZgtin2KbZitmL2Kcg2KPYq9mG2KfYoSDZh9iw2Ycg2KfZhNiu2LfZiNipLg=='
        GraphicsConfigSubtitle = '2YHYqtitINil2LnYr9in2K/Yp9iqINin2YTYsdiz2YjZhdin2Kog2YTZhNmF2LHYp9is2LnYqS4='
        GraphicsConfigPrimary = '2YHYqtitINil2LnYr9in2K/Yp9iqINin2YTYsdiz2YjZhdin2Ko='
        GraphicsConfigInfoTitle = '2YXYsdin2KzYudipINil2LnYr9in2K/Yp9iqINin2YTYsdiz2YjZhdin2Ko='
        GraphicsConfigInfoBullet1 = '2KfZgdiq2K0g2KXYudiv2KfYr9in2Kog2KfZhNix2LPZiNmF2KfYqiDYr9in2K7ZhCBXaW5kb3dzINmE2YXYsdin2KzYudipINiu2YrYp9ix2KfYqiDYp9mE2KPYr9in2KEu'
        GraphicsConfigInfoBullet2 = '2KrYo9mD2K8g2KPZhiDYrtmK2KfYsSBPcHRpbWl6YXRpb25zIGZvciB3aW5kb3dlZCBnYW1lcyDZhdi22KjZiNi3INi52YTZiSBPTi4='
        GraphicsConfigInfoBullet3 = '2KrYo9mD2K8g2KPZhiDYrtmK2KfYsSBIYXJkd2FyZS1hY2NlbGVyYXRlZCBHUFUgc2NoZWR1bGluZyDZhdi22KjZiNi3INi52YTZiSBPTi4='
    }

    if (-not $values.ContainsKey($Name)) {
        throw "Unknown AXIS Graphics text resource: $Name"
    }

    return ConvertFrom-AxisWizardBase64Text -Value ([string]$values[$Name])
}

function Get-AxisWizardWindowsText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $values = @{
        StartMenuTaskbarSubtitle = '2KrYudiv2YrZhNin2Kog2YjYqtmG2LjZitmBINi52YTZiSDYtNix2YrYtyDYp9mE2YXZh9in2YUg2YjZgtin2KbZhdipINin2KjYr9ijLg=='
        StartMenuTaskbarInfoTitle = '2KrYrdiz2YrZhiDYtNix2YrYtyDYp9mE2YXZh9in2YUg2YjZgtin2KbZhdipINin2KjYr9ij'
        StartMenuTaskbarInfoBullet1 = '2KrYt9io2YrZgiDYqti52K/ZitmE2KfYqiDZhdiu2LXYtdipINi52YTZiSDYtNix2YrYtyDYp9mE2YXZh9in2YUg2YjZgtin2KbZhdipINin2KjYr9ijLg=='
        StartMenuTaskbarInfoBullet2 = '2KrZhti42YrZgSDYp9mE2LnZhtin2LXYsSDYutmK2LEg2KfZhNi22LHZiNix2YrYqSDZhNiq2K3Ys9mK2YYg2LTZg9mEINmI2KrYrNix2KjYqSDYp9mE2KfYs9iq2K7Yr9in2YUu'
        StartMenuTaskbarInfoBullet3 = '2YrYqtmFINiq2LfYqNmK2YIg2KfZhNil2LnYr9in2K/Yp9iqINin2YTZhdmG2KfYs9io2Kkg2KrZhNmC2KfYptmK2YvYpyDYo9ir2YbYp9ihINmH2LDZhyDYp9mE2K7Yt9mI2Kku'
        StartMenuLayoutSubtitle = '2LbYqNi3INiq2K7Yt9mK2Lcg2YLYp9im2YXYqSDYp9io2K/Yoy4='
        StartMenuLayoutInfoTitle = '2KrYsdiq2YrYqCDZgtin2KbZhdipINin2KjYr9ij'
        StartMenuLayoutInfoBullet1 = '2KrYt9io2YrZgiDYqtiu2LfZiti3INmF2K7Ytdi1INmE2YLYp9im2YXYqSDYp9io2K/Yoy4='
        StartMenuLayoutInfoBullet2 = '2YrYs9in2LnYryDYsNmE2YMg2LnZhNmJINis2LnZhCDYp9mE2YLYp9im2YXYqSDYo9mG2LjZgSDZiNij2LPZh9mEINmB2Yog2KfZhNin2LPYqtiu2K/Yp9mFLg=='
        StartMenuLayoutInfoBullet3 = '2YrYqtmFINiq2LfYqNmK2YIg2KfZhNiq2K7Yt9mK2Lcg2KfZhNmF2YbYp9iz2Kgg2KrZhNmC2KfYptmK2YvYpyDYo9ir2YbYp9ihINmH2LDZhyDYp9mE2K7Yt9mI2Kku'
        ContextMenuSubtitle = '2KrYudiv2YrZhNin2Kog2LnZhNmJINmC2KfYptmF2Kkg2KfZhNiy2LEg2KfZhNij2YrZhdmGLg=='
        ContextMenuInfoTitle = '2KrZhti42YrZgSDZgtin2KbZhdipINin2YTYstixINin2YTYo9mK2YXZhg=='
        ContextMenuInfoBullet1 = '2KrYt9io2YrZgiDYqti52K/ZitmE2KfYqiDZhdiu2LXYtdipINi52YTZiSDZgtin2KbZhdipINin2YTYstixINin2YTYo9mK2YXZhi4='
        ContextMenuInfoBullet2 = '2KrZgtmE2YrZhCDYp9mE2LnZhtin2LXYsSDYutmK2LEg2KfZhNi22LHZiNix2YrYqSDYr9in2K7ZhCDYp9mE2YLYp9im2YXYqS4='
        ContextMenuInfoBullet3 = '2YrYs9in2LnYryDYsNmE2YMg2LnZhNmJINis2LnZhCDYp9mE2YLYp9im2YXYqSDYo9io2LPYtyDZiNij2LPYsdi5INmB2Yog2KfZhNin2LPYqtiu2K/Yp9mFLg=='
        ThemeBlackSubtitle = '2KrYt9io2YrZgiDYp9mE2KvZitmFINin2YTYr9in2YPZhi4='
        ThemeBlackPrimary = '2KrYt9io2YrZgiDYp9mE2KvZitmFINin2YTYr9in2YPZhg=='
        ThemeBlackInfoTitle = '2KfZhNir2YrZhSDYp9mE2K/Yp9mD2YY='
        ThemeBlackInfoBullet1 = '2KrYt9io2YrZgiDYp9mE2YXYuNmH2LEg2KfZhNiv2KfZg9mGINi52YTZiSBXaW5kb3dzLg=='
        ThemeBlackInfoBullet2 = '2YrYqtmFINi22KjYtyDYp9mE2YXYuNmH2LEg2KrZhNmC2KfYptmK2YvYpyDYo9ir2YbYp9ihINmH2LDZhyDYp9mE2K7Yt9mI2Kku'
        BlackLockScreenWallpaperSubtitle = '2KrYt9io2YrZgiDYrtmE2YHZitin2Kog2LPZiNiv2KfYoSDZhNi02KfYtNipINin2YTZgtmB2YQg2YjYqtiz2KzZitmEINin2YTYrtix2YjYrC4='
        BlackLockScreenWallpaperPrimary = '2KrYt9io2YrZgiDYp9mE2K7ZhNmB2YrYp9iqINin2YTYs9mI2K/Yp9ih'
        BlackLockScreenWallpaperInfoTitle = '2KfZhNiu2YTZgdmK2KfYqiDYp9mE2LPZiNiv2KfYoQ=='
        BlackLockScreenWallpaperInfoBullet1 = '2KrYt9io2YrZgiDYrtmE2YHZitin2Kog2LPZiNiv2KfYoSDYudmE2Ykg2LTYp9i02Kkg2KfZhNmC2YHZhCDZiNiq2LPYrNmK2YQg2KfZhNiu2LHZiNisLg=='
        BlackLockScreenWallpaperInfoBullet2 = '2YrYs9in2LnYryDYsNmE2YMg2LnZhNmJINiq2YjYrdmK2K8g2KfZhNmF2LjZh9ixINin2YTYudin2YUg2YTZhNmG2LjYp9mFLg=='
        BlackAccountPicturesSubtitle = '2KrYt9io2YrZgiDYtdmI2LEg2K3Ys9in2Kgg2LPZiNiv2KfYoS4='
        BlackAccountPicturesPrimary = '2KrYt9io2YrZgiDYtdmI2LEg2KfZhNit2LPYp9ioINin2YTYs9mI2K/Yp9ih'
        BlackAccountPicturesInfoTitle = '2LXZiNixINin2YTYrdiz2KfYqA=='
        BlackAccountPicturesInfoBullet1 = '2KfYs9iq2KjYr9in2YQg2LXZiNixINit2LPYp9ioINin2YTZhdiz2KrYrtiv2YUg2KjYtdmI2LEg2LPZiNiv2KfYoS4='
        BlackAccountPicturesInfoBullet2 = '2YrYs9in2LnYryDYsNmE2YMg2LnZhNmJINiq2YjYrdmK2K8g2YXYuNmH2LEg2K3Ys9in2KjYp9iqIFdpbmRvd3Mu'
        WidgetsSubtitle = '2KrYudi32YrZhCBXaWRnZXRzINmE2KrZgtmE2YrZhCDYp9mE2YbYtNin2Lcg2LrZitixINin2YTYttix2YjYsdmKLg=='
        WidgetsPrimary = '2KrYudi32YrZhCBXaWRnZXRz'
        WidgetsInfoTitle = '2KrYudi32YrZhCBXaWRnZXRz'
        WidgetsInfoBullet1 = '2KrYudi32YrZhCBXaWRnZXRzINiv2KfYrtmEIFdpbmRvd3Mu'
        WidgetsInfoBullet2 = '2YrYs9in2LnYryDYsNmE2YMg2LnZhNmJINiq2YLZhNmK2YQg2KfZhNmG2LTYp9i3INi62YrYsSDYp9mE2LbYsdmI2LHZiiDZgdmKINin2YTYrtmE2YHZitipLg=='
        WidgetsInfoBullet3 = '2KrYs9in2YfZhSDZh9iw2Ycg2KfZhNiu2LfZiNipINmB2Yog2KrYrdiz2YrZhiDYp9iz2KrZh9mE2KfZgyDYp9mE2YXZiNin2LHYryDYo9ir2YbYp9ihINin2YTYp9iz2KrYrtiv2KfZhS4='
        CopilotSubtitle = '2KrYudi32YrZhCBDb3BpbG90INmI2KrZgtmE2YrZhCDYp9mE2YbYtNin2Lcg2LrZitixINin2YTYttix2YjYsdmKLg=='
        CopilotPrimary = '2KrYudi32YrZhCBDb3BpbG90'
        CopilotInfoTitle = '2KrYudi32YrZhCBDb3BpbG90'
        CopilotInfoBullet1 = '2KrYudi32YrZhCBDb3BpbG90INiv2KfYrtmEIFdpbmRvd3Mu'
        CopilotInfoBullet2 = '2YrYs9in2LnYryDYsNmE2YMg2LnZhNmJINiq2YLZhNmK2YQg2KfZhNi52YbYp9i12LEg2LrZitixINin2YTYttix2YjYsdmK2Kkg2YHZiiDYp9mE2YbYuNin2YUu'
        CopilotInfoBullet3 = '2KrYs9in2YfZhSDZh9iw2Ycg2KfZhNiu2LfZiNipINmB2Yog2KrYrdiz2YrZhiDYqtis2LHYqNipINin2YTYp9iz2KrYrtiv2KfZhSDZiNin2LPYqtmH2YTYp9mDINin2YTZhdmI2KfYsdivLg=='
        GameModeSubtitle = '2YHYqtitINil2LnYr9in2K/Yp9iqINin2YTYo9mE2LnYp9ioINmE2YTYqtij2YPYryDZhdmGINiq2YHYudmK2YQgR2FtZSBNb2RlLg=='
        GameModePrimary = '2YHYqtitINil2LnYr9in2K/Yp9iqIEdhbWUgTW9kZQ=='
        GameModeInfoTitle = '2YXYsdin2KzYudipINil2LnYr9in2K/Yp9iqINin2YTYo9mE2LnYp9io'
        GameModeInfoBullet1 = '2KfZgdiq2K0g2KXYudiv2KfYr9in2Kog2KfZhNij2YTYudin2Kgg2K/Yp9iu2YQgV2luZG93cy4='
        GameModeInfoBullet2 = '2KrYo9mD2K8g2KPZhiDYrtmK2KfYsSBHYW1lIE1vZGUg2YXYttio2YjYtyDYudmE2YkgT04u'
        GameModeInfoBullet3 = '2KjYudivINin2YTYqtij2YPYryDZhdmGINin2YTYpdi52K/Yp9iv2Iwg2YrZhdmD2YbZgyDZhdiq2KfYqNi52Kkg2KfZhNiu2LfZiNin2Kog2KfZhNiq2KfZhNmK2Kku'
        GameModeRunning = '2YHYqtitINil2LnYr9in2K/Yp9iqIEdhbWUgTW9kZQ=='
        PointerPrecisionSubtitle = '2YHYqtitINil2LnYr9in2K/Yp9iqINin2YTZhdik2LTYsSDZhNiq2LnYt9mK2YQgRW5oYW5jZSBwb2ludGVyIHByZWNpc2lvbi4='
        PointerPrecisionPrimary = '2YHYqtitINil2LnYr9in2K/Yp9iqINin2YTZhdik2LTYsQ=='
        PointerPrecisionInfoTitle = '2YXYsdin2KzYudipINil2LnYr9in2K/Yp9iqINin2YTZhdik2LTYsQ=='
        PointerPrecisionInfoBullet1 = '2KfZgdiq2K0g2KXYudiv2KfYr9in2Kog2YXYpNi02LEg2KfZhNmF2KfZiNizLg=='
        PointerPrecisionInfoBullet2 = '2KPYstmEINiq2K3Yr9mK2K8g2K7Zitin2LEgRW5oYW5jZSBwb2ludGVyIHByZWNpc2lvbi4='
        PointerPrecisionInfoBullet3 = '2KjYudivINiw2YTZgyDYp9i22LrYtyBBcHBseSDYq9mFIE9LINmE2K3Zgdi4INin2YTYpdi52K/Yp9ivLg=='
        PointerPrecisionRunning = '2YHYqtitINil2LnYr9in2K/Yp9iqINin2YTZhdik2LTYsQ=='
        BloatwareSubtitle = '2KXYstin2YTYqSDYp9mE2KrYt9io2YrZgtin2Kog2LrZitixINin2YTYttix2YjYsdmK2Kkg2KPZiCDYqtir2KjZitiqINmF2YPZiNmG2KfYqiDZhdit2K/Yr9ipLg=='
        BloatwarePrimary = '2KrZhtmB2YrYsCDYp9mE2K7Zitin2LE='
        BloatwareInfoTitle = '2KrZhti42YrZgSDYqti32KjZitmC2KfYqiDYp9mE2YbYuNin2YU='
        BloatwareInfoBullet1 = '2KrYs9in2LnYryDZh9iw2Ycg2KfZhNiu2LfZiNipINi52YTZiSDYpdiy2KfZhNipINin2YTYqti32KjZitmC2KfYqiDYutmK2LEg2KfZhNi22LHZiNix2YrYqSDYo9mIINiq2KvYqNmK2Kog2YXZg9mI2YbYp9iqINmF2K3Yr9iv2Kkg2K3Ys9ioINin2YTYrtmK2KfYsSDYp9mE2YXYrtiq2KfYsS4='
        BloatwareInfoBullet2 = '2KfYrtiq2YrYp9ixIFJlbW92ZSBBbGwgQmxvYXR3YXJlINmK2LHZg9iyINi52YTZiSDYqtmG2LjZitmBINin2YTYqti32KjZitmC2KfYqiDYutmK2LEg2KfZhNi22LHZiNix2YrYqS4='
        BloatwareInfoBullet3 = '2KfYrtiq2YrYp9ixIEluc3RhbGwgU3RvcmUg2KPZiCBJbnN0YWxsIFNuaXBwaW5nIFRvb2wg2YrYs9iq2K7Yr9mFINmE2KrYq9io2YrYqiDYp9mE2YXZg9mI2YYg2KfZhNmF2LfZhNmI2Kgg2YHZgti3Lg=='
        BloatwareRequirement1 = '2KfZgtix2KMg2KfZhNiq2LnZhNmK2YXYp9iqINmC2KjZhCDYqtmG2YHZitiwINin2YTYrtmK2KfYsSDYp9mE2YXYrdiv2K8u'
        BloatwareRequirement2 = '2KrYo9mD2K8g2YXZhiDYp9iu2KrZitin2LEg2KfZhNil2KzYsdin2KEg2KfZhNi12K3ZititINmF2YYg2KfZhNmC2KfYptmF2Kkg2YLYqNmEINin2YTZhdiq2KfYqNi52Kku'
        BloatwareSelectorLabel = '2KfYrtiq2LEg2KfZhNil2KzYsdin2KE='
        BloatwareSelectorPlaceholder = '2KfYrtiq2LEg2KXYrNix2KfYodmLINmF2YYg2KfZhNmC2KfYptmF2Kk='
        GameBarSubtitle = '2KrYudi32YrZhCBHYW1lIEJhciDZiNiq2YLZhNmK2YQg2YXZg9mI2YbYp9iqINin2YTYo9mE2LnYp9ioINi62YrYsSDYp9mE2LbYsdmI2LHZitipLg=='
        GameBarPrimary = '2KrYudi32YrZhCBHYW1lIEJhcg=='
        GameBarInfoTitle = '2KrYrdiz2YrZhiDYqtis2LHYqNipINin2YTYo9mE2LnYp9io'
        GameBarInfoBullet1 = '2KrYudi32YrZhCBHYW1lIEJhciDZhNiq2YLZhNmK2YQg2KfZhNmG2LTYp9i3INi62YrYsSDYp9mE2LbYsdmI2LHZiiDYo9ir2YbYp9ihINin2YTYp9iz2KrYrtiv2KfZhS4='
        GameBarInfoBullet2 = '2YrYs9in2LnYryDYsNmE2YMg2LnZhNmJINiq2K7ZgdmK2YEg2KfYs9iq2YfZhNin2YMg2KfZhNmF2YjYp9ix2K8g2YHZiiDYp9mE2K7ZhNmB2YrYqS4='
        GameBarInfoBullet3 = '2KrYs9in2YfZhSDZh9iw2Ycg2KfZhNiu2LfZiNipINmB2Yog2KrYrdiz2YrZhiDYqtis2LHYqNipINin2YTYrNmH2KfYsiDYo9ir2YbYp9ihINin2YTZhNi52Kgg2YjYp9mE2KfYs9iq2K7Yr9in2YUg2KfZhNmK2YjZhdmKLg=='
        EdgeWebViewSubtitle = '2KXYstin2YTYqSBFZGdlIFdlYlZpZXcg2YjYqtmC2YTZitmEINin2YTZhdmD2YjZhtin2Kog2LrZitixINin2YTYttix2YjYsdmK2Kkg2YTYqtit2LPZitmGINin2YTYo9iv2KfYoS4='
        EdgeWebViewPrimary = '2KXYstin2YTYqSBFZGdlIFdlYlZpZXc='
        EdgeWebViewInfoTitle = '2KrZhti42YrZgSDZhdmD2YjZhtin2KogRWRnZSBXZWJWaWV3'
        EdgeWebViewInfoBullet1 = '2KXYstin2YTYqSBFZGdlIFdlYlZpZXcg2YjYqtmC2YTZitmEINin2YTZhdmD2YjZhtin2Kog2LrZitixINin2YTYttix2YjYsdmK2Kkg2KfZhNmF2LHYqtio2LfYqSDYqNmHLg=='
        EdgeWebViewInfoBullet2 = '2KrZgtmE2YrZhCDYp9mE2YXZg9mI2YbYp9iqINi62YrYsSDYp9mE2LbYsdmI2LHZitipINmK2LPYp9i52K8g2LnZhNmJINis2LnZhCDYp9mE2YbYuNin2YUg2KPYrtmBINij2KvZhtin2KEg2KfZhNin2LPYqtiu2K/Yp9mFLg=='
        EdgeWebViewInfoBullet3 = '2YrYqtmFINiq2YbZgdmK2LAg2KfZhNil2LnYr9in2K8g2KfZhNmF2YbYp9iz2Kgg2KrZhNmC2KfYptmK2YvYpyDYo9ir2YbYp9ihINmH2LDZhyDYp9mE2K7Yt9mI2Kku'
        NotepadSettingsSubtitle = '2LbYqNi3INil2LnYr9in2K/Yp9iqIE5vdGVwYWQg2YTYqtit2LPZitmGINiq2KzYsdio2Kkg2KfZhNin2LPYqtiu2K/Yp9mFLg=='
        NotepadSettingsPrimary = '2LbYqNi3IE5vdGVwYWQ='
        NotepadSettingsInfoTitle = '2KrYrdiz2YrZhiDYpdi52K/Yp9iv2KfYqiBOb3RlcGFk'
        NotepadSettingsInfoBullet1 = '2KrYt9io2YrZgiDYpdi52K/Yp9iv2KfYqiDZhdmG2KfYs9io2Kkg2YTYqtis2LHYqNipINin2LPYqtiu2K/Yp9mFINij2YHYttmEINiv2KfYrtmEIE5vdGVwYWQu'
        NotepadSettingsInfoBullet2 = '2KzYudmEINil2LnYr9in2K/Yp9iqINin2YTYqti32KjZitmCINij2KjYs9i3INmI2KPZhti42YEg2YTZhNin2LPYqtiu2K/Yp9mFINin2YTZitmI2YXZii4='
        NotepadSettingsInfoBullet3 = '2YrYqtmFINiq2LfYqNmK2YIg2KfZhNil2LnYr9in2K/Yp9iqINiq2YTZgtin2KbZitmL2Kcg2KPYq9mG2KfYoSDZh9iw2Ycg2KfZhNiu2LfZiNipLg=='
        ControlPanelSettingsSubtitle = '2LbYqNi3INil2LnYr9in2K/Yp9iqIENvbnRyb2wgUGFuZWwg2YTYqtit2LPZitmGINiq2KzYsdio2KkgV2luZG93cy4='
        ControlPanelSettingsPrimary = '2LbYqNi3IENvbnRyb2wgUGFuZWw='
        ControlPanelSettingsInfoTitle = '2KrYrdiz2YrZhiDYpdi52K/Yp9iv2KfYqiDYp9mE2YbYuNin2YU='
        ControlPanelSettingsInfoBullet1 = '2KrYt9io2YrZgiDYpdi52K/Yp9iv2KfYqiDZhdmH2YXYqSDYr9in2K7ZhCBDb250cm9sIFBhbmVsINmE2KrYrdiz2YrZhiDYqtis2LHYqNipIFdpbmRvd3Mu'
        ControlPanelSettingsInfoBullet2 = '2KrZgtmE2YrZhCDYp9mE2KXYudiv2KfYr9in2Kog2LrZitixINin2YTYttix2YjYsdmK2Kkg2YjYrNi52YQg2KfZhNmG2LjYp9mFINij2YPYq9ixINis2KfZh9iy2YrYqSDZhNmE2KfYs9iq2K7Yr9in2YUu'
        ControlPanelSettingsInfoBullet3 = '2YrYqtmFINiq2LfYqNmK2YIg2KfZhNil2LnYr9in2K/Yp9iqINin2YTZhdmG2KfYs9io2Kkg2KrZhNmC2KfYptmK2YvYpyDYo9ir2YbYp9ihINmH2LDZhyDYp9mE2K7Yt9mI2Kku'
        InputLanguageHotkeySubtitle = '2LbYqNi3INin2K7Yqti12KfYsSDYqtio2K/ZitmEINmE2LrYqSDYp9mE2KXYr9iu2KfZhCDYqtmE2YLYp9im2YrZi9inLg=='
        InputLanguageHotkeyPrimary = '2LbYqNi3INin2K7Yqti12KfYsSDYp9mE2YTYutip'
        InputLanguageHotkeyInfoTitle = '2KfYrtiq2LXYp9ixINiq2KjYr9mK2YQg2KfZhNmE2LrYqQ=='
        InputLanguageHotkeyInfoBullet1 = '2LbYqNi3INin2K7Yqti12KfYsSDYqtio2K/ZitmEINmE2LrYqSDYp9mE2KXYr9iu2KfZhCDYr9in2K7ZhCBXaW5kb3dzLg=='
        InputLanguageHotkeyInfoBullet2 = '2YrYqtmFINiq2LnZitmK2YYg2KfZhNin2K7Yqti12KfYsSDYpdmE2YkgTGVmdCBBbHQgKyBTaGlmdC4='
        InputLanguageHotkeyInfoBullet3 = '2YrYs9in2LnYryDYsNmE2YMg2LnZhNmJINiq2KjYr9mK2YQg2KfZhNmE2LrYqSDYqNiz2LHYudipINij2KvZhtin2KEg2KfZhNmD2KrYp9io2Kku'
        SoundSubtitle = '2YHYqtitINil2LnYr9in2K/Yp9iqINin2YTYtdmI2Kog2YTZhdix2KfYrNi52Kkg2KfZhNiz2YXYp9i52Kkg2YjYp9mE2YXYp9mK2YPYsdmI2YHZiNmGLg=='
        SoundPrimary = '2YHYqtitINil2LnYr9in2K/Yp9iqINin2YTYtdmI2Ko='
        SoundInfoTitle = '2YXYsdin2KzYudipINil2LnYr9in2K/Yp9iqINin2YTYtdmI2Ko='
        SoundInfoBullet1 = '2KfZgdiq2K0g2KXYudiv2KfYr9in2Kog2KfZhNi12YjYqiDYr9in2K7ZhCBXaW5kb3dzLg=='
        SoundInfoBullet2 = '2LHYp9is2Lkg2KXYudiv2KfYr9in2Kog2KfZhNiz2YXYp9i52Kkg2YjYp9mE2YXYp9mK2YPYsdmI2YHZiNmGINit2LPYqCDYp9iz2KrYrtiv2KfZhdmDLg=='
        SoundInfoBullet3 = '2KXYsNinINin2K3Yqtis2Kog2YXYs9in2LnYr9ipINmB2Yog2LbYqNi3INin2YTYtdmI2KrYjCDZitmF2YPZhtmDINin2YTYqtmI2KfYtdmEINmF2Lkg2KfZhNiv2LnZhS4='
        DeviceManagerPowerSavingsWakeSubtitle = '2KrYudi32YrZhCDYqtmI2YHZitixINin2YTYt9in2YLYqSDYutmK2LEg2KfZhNi22LHZiNix2Yog2YTZhNij2KzZh9iy2Kkg2YTYqtit2LPZitmGINin2YTYp9iz2KrYrNin2KjYqS4='
        DeviceManagerPowerSavingsWakePrimary = '2KrYudi32YrZhCDYqtmI2YHZitixINin2YTYt9in2YLYqSDZhNmE2KPYrNmH2LLYqQ=='
        DeviceManagerPowerSavingsWakeInfoTitle = '2KrYrdiz2YrZhiDYp9iz2KrYrNin2KjYqSDYp9mE2KPYrNmH2LLYqQ=='
        DeviceManagerPowerSavingsWakeInfoBullet1 = '2KrYudi32YrZhCDYpdi52K/Yp9iv2KfYqiDYqtmI2YHZitixINin2YTYt9in2YLYqSDYutmK2LEg2KfZhNi22LHZiNix2YrYqSDZhNmE2KPYrNmH2LLYqS4='
        DeviceManagerPowerSavingsWakeInfoBullet2 = '2YrYs9in2LnYryDYsNmE2YMg2LnZhNmJINiq2K3Ys9mK2YYg2KfZhNin2LPYqtis2KfYqNipINmI2KrZgtmE2YrZhCDYp9mE2KrYo9iu2YrYsSDYo9ir2YbYp9ihINin2YTYp9iz2KrYrtiv2KfZhS4='
        DeviceManagerPowerSavingsWakeInfoBullet3 = '2YrYqtmFINiq2LfYqNmK2YIg2KfZhNil2LnYr9in2K/Yp9iqINin2YTZhdmG2KfYs9io2Kkg2KrZhNmC2KfYptmK2YvYpyDYo9ir2YbYp9ihINmH2LDZhyDYp9mE2K7Yt9mI2Kku'
        NetworkAdapterPowerSavingsWakeSubtitle = '2KrYudi32YrZhCDYqtmI2YHZitixINin2YTYt9in2YLYqSDZhNmF2K3ZiNmEINin2YTYtNio2YPYqSDZhNiq2K3Ys9mK2YYg2KfYs9iq2YLYsdin2LEg2KfZhNin2KrYtdin2YQu'
        NetworkAdapterPowerSavingsWakePrimary = '2KrYudi32YrZhCDYqtmI2YHZitixINin2YTYt9in2YLYqSDZhNmE2LTYqNmD2Kk='
        NetworkAdapterPowerSavingsWakeInfoTitle = '2KrYrdiz2YrZhiDYp9iz2KrZgtix2KfYsSDYp9mE2LTYqNmD2Kk='
        NetworkAdapterPowerSavingsWakeInfoBullet1 = '2KrYudi32YrZhCDYpdi52K/Yp9iv2KfYqiDYqtmI2YHZitixINin2YTYt9in2YLYqSDYutmK2LEg2KfZhNi22LHZiNix2YrYqSDZhNmF2K3ZiNmEINin2YTYtNio2YPYqS4='
        NetworkAdapterPowerSavingsWakeInfoBullet2 = '2YrYs9in2LnYryDYsNmE2YMg2LnZhNmJINiq2K3Ys9mK2YYg2KfYs9iq2YLYsdin2LEg2KfZhNin2KrYtdin2YQg2YjYqtmC2YTZitmEINin2YTYp9mG2YLYt9in2LnYp9iqLg=='
        NetworkAdapterPowerSavingsWakeInfoBullet3 = '2YrYqtmFINiq2LfYqNmK2YIg2KfZhNil2LnYr9in2K/Yp9iqINin2YTZhdmG2KfYs9io2Kkg2KrZhNmC2KfYptmK2YvYpyDYo9ir2YbYp9ihINmH2LDZhyDYp9mE2K7Yt9mI2Kku'
        WriteCacheBufferFlushingSubtitle = '2KrYrdiz2YrZhiDYt9ix2YrZgtipINiq2LnYp9mF2YQg2YjYrdiv2KfYqiDYp9mE2KrYrtiy2YrZhiDZhdi5INin2YTZgtix2KfYodipINmI2KfZhNmD2KrYp9io2Kku'
        WriteCacheBufferFlushingPrimary = '2KrYrdiz2YrZhiDYp9mE2KrYrtiy2YrZhg=='
        WriteCacheBufferFlushingInfoTitle = '2KrYrdiz2YrZhiDYo9iv2KfYoSDYp9mE2KrYrtiy2YrZhg=='
        WriteCacheBufferFlushingInfoBullet1 = '2LbYqNi3INil2LnYr9in2K/Yp9iqINiq2LPYp9i52K8g2LnZhNmJINiq2K3Ys9mK2YYg2KPYr9in2KEg2YjYrdiv2KfYqiDYp9mE2KrYrtiy2YrZhi4='
        WriteCacheBufferFlushingInfoBullet2 = '2YrYs9in2LnYryDYsNmE2YMg2LnZhNmJINiq2K3Ys9mK2YYg2KrYrNix2KjYqSDYp9mE2YLYsdin2KHYqSDZiNin2YTZg9iq2KfYqNipINij2KvZhtin2KEg2KfZhNin2LPYqtiu2K/Yp9mFLg=='
        WriteCacheBufferFlushingInfoBullet3 = '2YrYqtmFINiq2LfYqNmK2YIg2KfZhNil2LnYr9in2K/Yp9iqINin2YTZhdmG2KfYs9io2Kkg2KrZhNmC2KfYptmK2YvYpyDYo9ir2YbYp9ihINmH2LDZhyDYp9mE2K7Yt9mI2Kku'
        PowerPlanSubtitle = '2KrYt9io2YrZgiDYrti32Kkg2LfYp9mC2Kkg2YXZiNis2YfYqSDZhNmE2KPYr9in2KEu'
        PowerPlanPrimary = '2KrYt9io2YrZgiDYrti32Kkg2KfZhNij2K/Yp9ih'
        PowerPlanInfoTitle = '2K7Yt9ipINin2YTYo9iv2KfYoQ=='
        PowerPlanInfoBullet1 = '2KrYt9io2YrZgiDYpdi52K/Yp9iv2KfYqiDYt9in2YLYqSDYqtiz2KfYudivINin2YTYrNmH2KfYsiDYudmE2Ykg2KfYs9iq2K7Yr9in2YUg2YPYp9mF2YQg2YLZiNiq2Ycu'
        PowerPlanInfoBullet2 = '2KrYs9in2LnYryDZh9iw2Ycg2KfZhNiu2LfZiNipINi52YTZiSDYqtit2LPZitmGINin2YTYo9iv2KfYoSDZiNin2YTYp9iz2KrYrNin2KjYqSDYo9ir2YbYp9ihINin2YTYp9iz2KrYrtiv2KfZhS4='
        PowerPlanInfoBullet3 = '2YrYqtmFINi22KjYtyDYrti32Kkg2KfZhNi32KfZgtipINin2YTZhdmG2KfYs9io2Kkg2KrZhNmC2KfYptmK2YvYpy4='
        CleanupSubtitle = '2KrZhti42YrZgSDYp9mE2YXZhNmB2KfYqiDYp9mE2YXYpNmC2KrYqSDZiNin2YTZhdiu2YTZgdin2Kog2LrZitixINin2YTYttix2YjYsdmK2Kku'
        CleanupPrimary = '2KrZhti42YrZgSDYp9mE2KzZh9in2LI='
        CleanupInfoTitle = '2KrZhti42YrZgSDYp9mE2YbYuNin2YU='
        CleanupInfoBullet1 = '2KrZhti42YrZgSDYp9mE2YXZhNmB2KfYqiDYp9mE2YXYpNmC2KrYqSDZiNin2YTZhdiu2YTZgdin2Kog2LrZitixINin2YTYttix2YjYsdmK2Kku'
        CleanupInfoBullet2 = '2YrYs9in2LnYryDYsNmE2YMg2LnZhNmJINiq2K7ZgdmK2YEg2KfZhNmG2LjYp9mFINmI2KzYudmEINin2YTYqtis2LHYqNipINij2YPYq9ixINiz2YTYp9iz2Kku'
        CleanupInfoBullet3 = '2YrYqtmFINiq2YbZgdmK2LAg2KfZhNiq2YbYuNmK2YEg2KrZhNmC2KfYptmK2YvYpyDYo9ir2YbYp9ihINmH2LDZhyDYp9mE2K7Yt9mI2Kku'
        Running = '2KzYp9ix2Yog2KfZhNiq2YbZgdmK2LA='
        Completed = '2YXZg9iq2YXZhA=='
    }

    if (-not $values.ContainsKey($Name)) {
        throw "Unknown AXIS Windows text resource: $Name"
    }

    return ConvertFrom-AxisWizardBase64Text -Value ([string]$values[$Name])
}

function Get-AxisWizardAdvancedText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $values = @{
        TimerResolutionSubtitle = '2LbYqNi3IFRpbWVyIFJlc29sdXRpb24g2YTYqtit2LPZitmGINin2LPYqtis2KfYqNipINin2YTZhti42KfZhS4='
        TimerResolutionPrimary = '2KrZgdi52YrZhCBUaW1lciBSZXNvbHV0aW9u'
        TimerResolutionInfoTitle = '2KrYrdiz2YrZhiDYp9iz2KrYrNin2KjYqSDYp9mE2YbYuNin2YU='
        TimerResolutionInfoBullet1 = '2KrZgdi52YrZhCDYpdi52K/Yp9ivIFRpbWVyIFJlc29sdXRpb24g2YTYqtit2LPZitmGINin2LPYqtis2KfYqNipINin2YTZhti42KfZhSDYo9ir2YbYp9ihINin2YTYp9iz2KrYrtiv2KfZhS4='
        TimerResolutionInfoBullet2 = '2YrYs9in2LnYryDYsNmE2YMg2LnZhNmJINis2LnZhCDYp9mE2KrZgdin2LnZhCDZhdi5INin2YTZhti42KfZhSDYo9mD2KvYsSDYs9mE2KfYs9ipLg=='
        TimerResolutionInfoBullet3 = '2YrYqtmFINiq2LfYqNmK2YIg2KfZhNil2LnYr9in2K8g2KfZhNmF2YbYp9iz2Kgg2KrZhNmC2KfYptmK2YvYpyDYo9ir2YbYp9ihINmH2LDZhyDYp9mE2K7Yt9mI2Kku'
        DefenderOptimizeSubtitle = '2LbYqNi3INil2LnYr9in2K/Yp9iqIERlZmVuZGVyINmE2KrYrdiz2YrZhiDYp9mE2KrYrNix2KjYqS4='
        DefenderOptimizeInfoTitle = '2KrYrdiz2YrZhiDYpdi52K/Yp9iv2KfYqiBEZWZlbmRlcg=='
        DefenderOptimizeInfoBullet1 = '2KrYt9io2YrZgiDYp9mE2YXYs9in2LEg2KfZhNmF2LnYqtmF2K8g2YTYttio2Lcg2KXYudiv2KfYr9in2KogRGVmZW5kZXIu'
        DefenderOptimizeInfoBullet2 = '2YrYqtmFINiq2YbZgdmK2LAg2KfZhNmF2LPYp9ixINiq2YTZgtin2KbZitmL2KfYjCDYqNmF2Kcg2YHZiiDYsNmE2YMg2KXYudin2K/YqSDYp9mE2KrYtNi62YrZhCDZiNin2YTYr9iu2YjZhCDYpdmE2YkgU2FmZSBNb2RlINi52YbYryDYp9mE2K3Yp9is2Kku'
        DefenderOptimizeInfoBullet3 = '2KjYudivINin2YPYqtmF2KfZhCDYp9mE2YXYs9in2LHYjCDZiti52YjYryDYp9mE2KzZh9in2LIg2YTZhNmI2LbYuSDYp9mE2LfYqNmK2LnZiiDZhNin2LPYqtmD2YXYp9mEINin2YTYpdi52K/Yp9ivLg=='
        DefenderOptimizeRequirementsTitle = '2KfZhNmF2KrYt9mE2KjYp9iq'
        DefenderOptimizeRequirement1 = '2KfZgtix2KMg2KfZhNiq2LnZhNmK2YXYp9iqINmC2KjZhCDYqNiv2KEg2LbYqNi3INil2LnYr9in2K/Yp9iqIERlZmVuZGVyLg=='
        DefenderOptimizeRequirement2 = '2KfYrdmB2Lgg2KPZiiDYudmF2YQg2YXZgdiq2YjYrSDZgtio2YQg2KfZhNmF2KrYp9io2LnYqS4='
        DefenderOptimizeRequirement3 = '2KfZhtiq2LjYsSDYrdiq2Ykg2KrZg9iq2YXZhCDYp9mE2LnZhdmE2YrYqSDYqNin2YTZg9in2YXZhC4='
        Running = '2KzYp9ix2Yog2KfZhNiq2YbZgdmK2LA='
        Completed = '2YXZg9iq2YXZhA=='
    }

    if (-not $values.ContainsKey($Name)) {
        throw "Unknown AXIS Advanced text resource: $Name"
    }

    return ConvertFrom-AxisWizardBase64Text -Value ([string]$values[$Name])
}

function Get-AxisWizardArabicText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet(
            'Open',
            'Completed',
            'Subtitle',
            'InformationCardTitle',
            'NetworkDriver',
            'AudioDriver',
            'Documentation',
            'Acknowledgement',
            'SupportTitle',
            'SupportBody',
            'Checking',
            'Back',
            'Next',
            'Return',
            'Restart',
            'BiosSettingsSubtitle',
            'BiosSettingsInfoTitle',
            'BiosSettingsInfoIntro',
            'IntelTitle',
            'IntelRam',
            'IntelCStates',
            'IntelRebar',
            'IntelIgpu',
            'AmdTitle',
            'AmdRam',
            'AmdPbo',
            'AmdRebar',
            'AmdIgpu',
            'MotherboardTitle',
            'MotherboardIntro',
            'AsusUtility',
            'MsiUtility',
            'GigabyteUtility',
            'AsrockUtility',
            'RequirementsTitle',
            'ReqNavigation',
            'ReqSupport',
            'RestartAcknowledgement',
            'Restarting',
            'ReinstallTitle',
            'ReinstallSubtitle',
            'ReinstallInfoTitle',
            'ReinstallInfoBullet',
            'ReinstallRequirementUsbSize',
            'ReinstallRequirementNoData',
            'ReinstallPrimaryAction',
            'ReinstallRunning',
            'ReinstallCompleted',
            'AutoUnattendSubtitle',
            'AutoUnattendInfoTitle',
            'AutoUnattendInfoBulletOobe',
            'AutoUnattendInfoBulletSetup',
            'AutoUnattendInfoBulletUsb',
            'AutoUnattendRequirementAccount',
            'AutoUnattendRequirementUsb',
            'AutoUnattendPrimaryAction',
            'AutoUnattendInputTitle',
            'AutoUnattendAccountLabel',
            'AutoUnattendUsbLabel',
            'AutoUnattendRunning',
            'AutoUnattendCompleted',
            'UpdatesDriversSubtitle',
            'UpdatesDriversInfoTitle',
            'UpdatesDriversInfoBulletSetupcomplete',
            'UpdatesDriversInfoBulletWindowsUpdate',
            'UpdatesDriversRequirementUsb',
            'UpdatesDriversPrimaryAction',
            'UpdatesDriversInputTitle',
            'UpdatesDriversUsbLabel',
            'UpdatesDriversInputCreate',
            'UpdatesDriversRunning',
            'UpdatesDriversCompleted',
            'ToBiosTitle',
            'ToBiosSubtitle',
            'ToBiosInfoTitle',
            'ToBiosInfoBulletRestart',
            'ToBiosInfoBulletUsbBoot',
            'ToBiosInfoBulletInstall',
            'ToBiosPrimaryAction',
            'InstallersTitle',
            'InstallersSubtitle',
            'InstallersSelectorLabel',
            'InstallersSelectorPlaceholder',
            'InstallersInfoTitle',
            'InstallersInfoBullet1',
            'InstallersInfoBullet2',
            'InstallersInfoBullet3',
            'InstallersRequirementsBullet1',
            'InstallersRequirementsBullet2',
            'InstallersRunning',
            'InstallersCompleted',
            'InstallersSelectedProgramPrefix',
            'InstallersEpicOverlayTitle',
            'InstallersEpicOverlayBody1',
            'InstallersEpicOverlayBody2',
            'InstallersEpicOverlayBody3',
            'InstallersEpicOverlayReturn',
            'RestartAfterInstallersTitle',
            'RestartAfterInstallersSubtitle',
            'RestartAfterInstallersInfoBullet1',
            'RestartAfterInstallersInfoBullet2',
            'RestartAfterInstallersInfoBullet3'
        )]
        [string]$Name
    )

    switch ($Name) {
        'Open' { return ConvertFrom-AxisWizardCodePoints @(0x0627, 0x0641, 0x062A, 0x062D) }
        'Completed' { return ConvertFrom-AxisWizardCodePoints @(0x0645, 0x0643, 0x062A, 0x0645, 0x0644) }
        'Subtitle' {
            return ConvertFrom-AxisWizardCodePoints @(
                0x0627, 0x0641, 0x062A, 0x062D, 0x0020,
                0x0635, 0x0641, 0x062D, 0x0629, 0x0020,
                0x0627, 0x0644, 0x062F, 0x0639, 0x0645, 0x0020,
                0x0627, 0x0644, 0x0631, 0x0633, 0x0645, 0x064A, 0x0629, 0x0020,
                0x0644, 0x0644, 0x0648, 0x062D, 0x0629, 0x0020,
                0x0627, 0x0644, 0x0623, 0x0645, 0x0020,
                0x0644, 0x062A, 0x062D, 0x0645, 0x064A, 0x0644, 0x0020,
                0x0627, 0x0644, 0x062A, 0x0639, 0x0631, 0x064A, 0x0641, 0x0627, 0x062A, 0x0020,
                0x0627, 0x0644, 0x0623, 0x0633, 0x0627, 0x0633, 0x064A, 0x0629, 0x0020,
                0x0627, 0x0644, 0x0645, 0x0637, 0x0644, 0x0648, 0x0628, 0x0629, 0x002E
            )
        }
        'InformationCardTitle' {
            return ConvertFrom-AxisWizardCodePoints @(
                0x0627, 0x0644, 0x062A, 0x0639, 0x0631, 0x064A, 0x0641, 0x0627, 0x062A, 0x0020,
                0x0627, 0x0644, 0x0645, 0x0637, 0x0644, 0x0648, 0x0628, 0x0629
            )
        }
        'NetworkDriver' {
            return ConvertFrom-AxisWizardCodePoints @(
                0x062A, 0x0639, 0x0631, 0x064A, 0x0641, 0x0020,
                0x0627, 0x0644, 0x0634, 0x0628, 0x0643, 0x0629
            )
        }
        'AudioDriver' {
            return ConvertFrom-AxisWizardCodePoints @(
                0x062A, 0x0639, 0x0631, 0x064A, 0x0641, 0x0020,
                0x0627, 0x0644, 0x0635, 0x0648, 0x062A
            )
        }
        'Documentation' {
            return ConvertFrom-AxisWizardCodePoints @(0x0627, 0x0644, 0x062A, 0x0639, 0x0644, 0x064A, 0x0645, 0x0627, 0x062A)
        }
        'Acknowledgement' {
            return ConvertFrom-AxisWizardCodePoints @(
                0x0644, 0x0642, 0x062F, 0x0020,
                0x0642, 0x0631, 0x0623, 0x062A, 0x0020,
                0x0627, 0x0644, 0x062A, 0x0639, 0x0644, 0x064A, 0x0645, 0x0627, 0x062A
            )
        }
        'SupportTitle' {
            return ConvertFrom-AxisWizardCodePoints @(0x0645, 0x0633, 0x0627, 0x0639, 0x062F, 0x0629)
        }
        'SupportBody' {
            return ConvertFrom-AxisWizardCodePoints @(
                0x062A, 0x062D, 0x062A, 0x0627, 0x062C, 0x0020,
                0x0645, 0x0633, 0x0627, 0x0639, 0x062F, 0x0629, 0x061F, 0x0020,
                0x064A, 0x0645, 0x0643, 0x0646, 0x0643, 0x0020,
                0x0627, 0x0644, 0x062A, 0x0648, 0x0627, 0x0635, 0x0644, 0x0020,
                0x0645, 0x0639, 0x0020,
                0x0623, 0x062E, 0x0635, 0x0627, 0x0626, 0x064A, 0x0020,
                0x0627, 0x0644, 0x062F, 0x0639, 0x0645, 0x0020,
                0x0639, 0x0628, 0x0631, 0x0020,
                0x062E, 0x0627, 0x062F, 0x0645, 0x0020,
                0x0044, 0x0069, 0x0073, 0x0063, 0x006F, 0x0072, 0x0064, 0x0020,
                0x0627, 0x0644, 0x062E, 0x0627, 0x0635, 0x0020,
                0x0628, 0x0627, 0x0644, 0x0645, 0x062A, 0x062C, 0x0631, 0x002E
            )
        }
        'Checking' {
            return ConvertFrom-AxisWizardCodePoints @(0x062C, 0x0627, 0x0631, 0x064A, 0x20, 0x0627, 0x0644, 0x062A, 0x062D, 0x0642, 0x0642)
        }
        'Back' {
            return ConvertFrom-AxisWizardCodePoints @(0x0627, 0x0644, 0x0633, 0x0627, 0x0628, 0x0642)
        }
        'Next' {
            return ConvertFrom-AxisWizardCodePoints @(0x0627, 0x0644, 0x062A, 0x0627, 0x0644, 0x064A)
        }
        'Return' {
            return ConvertFrom-AxisWizardCodePoints @(0x0631, 0x062C, 0x0648, 0x0639)
        }
        'Restart' {
            return ConvertFrom-AxisWizardCodePoints @(0x0625, 0x0639, 0x0627, 0x062F, 0x0629, 0x0020, 0x0627, 0x0644, 0x062A, 0x0634, 0x063A, 0x064A, 0x0644)
        }
        'BiosSettingsSubtitle' {
            return ConvertFrom-AxisWizardCodePoints @(
                0x0627, 0x0636, 0x0628, 0x0637, 0x0020,
                0x0625, 0x0639, 0x062F, 0x0627, 0x062F, 0x0627, 0x062A, 0x0020,
                0x0042, 0x0049, 0x004F, 0x0053, 0x002F, 0x0055, 0x0045, 0x0046, 0x0049, 0x0020,
                0x0627, 0x0644, 0x062E, 0x0627, 0x0635, 0x0629, 0x0020,
                0x0628, 0x0627, 0x0644, 0x0644, 0x0648, 0x062D, 0x0629, 0x0020,
                0x0627, 0x0644, 0x0623, 0x0645, 0x0020,
                0x0644, 0x062A, 0x062C, 0x0647, 0x064A, 0x0632, 0x0020,
                0x0627, 0x0644, 0x062C, 0x0647, 0x0627, 0x0632, 0x0020,
                0x0644, 0x0644, 0x062E, 0x0637, 0x0648, 0x0627, 0x062A, 0x0020,
                0x0627, 0x0644, 0x062A, 0x0627, 0x0644, 0x064A, 0x0629, 0x002E
            )
        }
        'BiosSettingsInfoTitle' {
            return ConvertFrom-AxisWizardCodePoints @(
                0x0627, 0x0644, 0x0625, 0x0639, 0x062F, 0x0627, 0x062F, 0x0627, 0x062A, 0x0020,
                0x0627, 0x0644, 0x0645, 0x0642, 0x062A, 0x0631, 0x062D, 0x0629, 0x0020,
                0x0644, 0x062C, 0x0647, 0x0627, 0x0632, 0x0643
            )
        }
        'BiosSettingsInfoIntro' {
            return ConvertFrom-AxisWizardCodePoints @(
                0x064A, 0x0639, 0x0631, 0x0636, 0x0020, 0x0041, 0x0058, 0x0049, 0x0053, 0x0020,
                0x0627, 0x0644, 0x0625, 0x0639, 0x062F, 0x0627, 0x062F, 0x0627, 0x062A, 0x0020,
                0x0627, 0x0644, 0x0645, 0x0646, 0x0627, 0x0633, 0x0628, 0x0629, 0x0020,
                0x0641, 0x0642, 0x0637, 0x0020,
                0x062D, 0x0633, 0x0628, 0x0020,
                0x0646, 0x0648, 0x0639, 0x0020,
                0x0627, 0x0644, 0x0645, 0x0639, 0x0627, 0x0644, 0x062C, 0x0020,
                0x0648, 0x0627, 0x0644, 0x0644, 0x0648, 0x062D, 0x0629, 0x0020,
                0x0627, 0x0644, 0x0623, 0x0645, 0x0020,
                0x0641, 0x064A, 0x0020,
                0x062C, 0x0647, 0x0627, 0x0632, 0x0643, 0x002E
            )
        }
        'IntelTitle' {
            return ConvertFrom-AxisWizardCodePoints @(0x0645, 0x0639, 0x0627, 0x0644, 0x062C, 0x0020, 0x0049, 0x006E, 0x0074, 0x0065, 0x006C)
        }
        'IntelRam' {
            return ConvertFrom-AxisWizardCodePoints @(0x062A, 0x0641, 0x0639, 0x064A, 0x0644, 0x0020, 0x0072, 0x0061, 0x006D, 0x0020, 0x0070, 0x0072, 0x006F, 0x0066, 0x0069, 0x006C, 0x0065, 0x003A, 0x0020, 0x0058, 0x004D, 0x0050, 0x0020, 0x002F, 0x0020, 0x0044, 0x004F, 0x0043, 0x0050, 0x0020, 0x002F, 0x0020, 0x0045, 0x0058, 0x0050, 0x004F)
        }
        'IntelCStates' {
            return ConvertFrom-AxisWizardCodePoints @(0x062A, 0x0639, 0x0637, 0x064A, 0x0644, 0x0020, 0x0043, 0x002D, 0x0053, 0x0074, 0x0061, 0x0074, 0x0065, 0x0073)
        }
        'IntelRebar' {
            return ConvertFrom-AxisWizardCodePoints @(0x062A, 0x0641, 0x0639, 0x064A, 0x0644, 0x0020, 0x0052, 0x0065, 0x0073, 0x0069, 0x007A, 0x0061, 0x0062, 0x006C, 0x0065, 0x0020, 0x0042, 0x0041, 0x0052, 0x003A, 0x0020, 0x0052, 0x0045, 0x0042, 0x0041, 0x0052, 0x0020, 0x002F, 0x0020, 0x0043, 0x002E, 0x0041, 0x002E, 0x004D)
        }
        'IntelIgpu' {
            return ConvertFrom-AxisWizardCodePoints @(0x062A, 0x0639, 0x0637, 0x064A, 0x0644, 0x0020, 0x0069, 0x0047, 0x0050, 0x0055)
        }
        'AmdTitle' {
            return ConvertFrom-AxisWizardCodePoints @(0x0645, 0x0639, 0x0627, 0x0644, 0x062C, 0x0020, 0x0041, 0x004D, 0x0044)
        }
        'AmdRam' {
            return Get-AxisWizardArabicText -Name 'IntelRam'
        }
        'AmdPbo' {
            return ConvertFrom-AxisWizardCodePoints @(0x062A, 0x0641, 0x0639, 0x064A, 0x0644, 0x0020, 0x0050, 0x0072, 0x0065, 0x0063, 0x0069, 0x0073, 0x0069, 0x006F, 0x006E, 0x0020, 0x0042, 0x006F, 0x006F, 0x0073, 0x0074, 0x0020, 0x004F, 0x0076, 0x0065, 0x0072, 0x0064, 0x0072, 0x0069, 0x0076, 0x0065, 0x003A, 0x0020, 0x0050, 0x0042, 0x004F)
        }
        'AmdRebar' {
            return Get-AxisWizardArabicText -Name 'IntelRebar'
        }
        'AmdIgpu' {
            return Get-AxisWizardArabicText -Name 'IntelIgpu'
        }
        'MotherboardTitle' {
            return ConvertFrom-AxisWizardCodePoints @(0x0625, 0x0639, 0x062F, 0x0627, 0x062F, 0x0627, 0x062A, 0x0020, 0x0627, 0x0644, 0x0644, 0x0648, 0x062D, 0x0629, 0x0020, 0x0627, 0x0644, 0x0623, 0x0645, 0x0020, 0x0064, 0x0072, 0x0069, 0x0076, 0x0065, 0x0072, 0x0020, 0x0069, 0x006E, 0x0073, 0x0074, 0x0061, 0x006C, 0x006C, 0x0065, 0x0072, 0x0020, 0x0073, 0x006F, 0x0066, 0x0074, 0x0077, 0x0061, 0x0072, 0x0065, 0x0020, 0x003A)
        }
        'MotherboardIntro' {
            return ConvertFrom-AxisWizardCodePoints @(0x064A, 0x0639, 0x0631, 0x0636, 0x0020, 0x0041, 0x0058, 0x0049, 0x0053, 0x0020, 0x0627, 0x0644, 0x062E, 0x064A, 0x0627, 0x0631, 0x0020, 0x0627, 0x0644, 0x0645, 0x0646, 0x0627, 0x0633, 0x0628, 0x0020, 0x062D, 0x0633, 0x0628, 0x0020, 0x0627, 0x0644, 0x0634, 0x0631, 0x0643, 0x0629, 0x0020, 0x0627, 0x0644, 0x0645, 0x0635, 0x0646, 0x0639, 0x0629, 0x0020, 0x0644, 0x0644, 0x0648, 0x062D, 0x0629, 0x0020, 0x0627, 0x0644, 0x0623, 0x0645, 0x0020, 0x0641, 0x0642, 0x0637, 0x003A)
        }
        'AsusUtility' {
            return ConvertFrom-AxisWizardCodePoints @(0x062A, 0x0639, 0x0637, 0x064A, 0x0644, 0x0020, 0x0041, 0x0053, 0x0055, 0x0053, 0x0020, 0x0041, 0x0072, 0x006D, 0x006F, 0x0075, 0x0072, 0x0079, 0x0020, 0x0043, 0x0072, 0x0061, 0x0074, 0x0065)
        }
        'MsiUtility' {
            return ConvertFrom-AxisWizardCodePoints @(0x062A, 0x0639, 0x0637, 0x064A, 0x0644, 0x0020, 0x004D, 0x0053, 0x0049, 0x0020, 0x0044, 0x0072, 0x0069, 0x0076, 0x0065, 0x0072, 0x0020, 0x0055, 0x0074, 0x0069, 0x006C, 0x0069, 0x0074, 0x0079)
        }
        'GigabyteUtility' {
            return ConvertFrom-AxisWizardCodePoints @(0x062A, 0x0639, 0x0637, 0x064A, 0x0644, 0x0020, 0x0047, 0x0069, 0x0067, 0x0061, 0x0062, 0x0079, 0x0074, 0x0065, 0x0020, 0x0055, 0x0070, 0x0064, 0x0061, 0x0074, 0x0065, 0x0020, 0x0055, 0x0074, 0x0069, 0x006C, 0x0069, 0x0074, 0x0079)
        }
        'AsrockUtility' {
            return ConvertFrom-AxisWizardCodePoints @(0x062A, 0x0639, 0x0637, 0x064A, 0x0644, 0x0020, 0x0041, 0x0053, 0x0052, 0x006F, 0x0063, 0x006B, 0x0020, 0x004D, 0x006F, 0x0074, 0x0068, 0x0065, 0x0072, 0x0062, 0x006F, 0x0061, 0x0072, 0x0064, 0x0020, 0x0055, 0x0074, 0x0069, 0x006C, 0x0069, 0x0074, 0x0079)
        }
        'RequirementsTitle' {
            return ConvertFrom-AxisWizardCodePoints @(0x0627, 0x0644, 0x0645, 0x062A, 0x0637, 0x0644, 0x0628, 0x0627, 0x062A)
        }
        'ReqNavigation' {
            return ConvertFrom-AxisWizardCodePoints @(0x0661, 0x002E, 0x0020, 0x062A, 0x0623, 0x0643, 0x062F, 0x0020, 0x0645, 0x0646, 0x0020, 0x0641, 0x0647, 0x0645, 0x0020, 0x0637, 0x0631, 0x064A, 0x0642, 0x0629, 0x0020, 0x0627, 0x0644, 0x062A, 0x0646, 0x0642, 0x0644, 0x0020, 0x062F, 0x0627, 0x062E, 0x0644, 0x0020, 0x0634, 0x0627, 0x0634, 0x0629, 0x0020, 0x0042, 0x0049, 0x004F, 0x0053, 0x002F, 0x0055, 0x0045, 0x0046, 0x0049, 0x0020, 0x0642, 0x0628, 0x0644, 0x0020, 0x0627, 0x0644, 0x0645, 0x062A, 0x0627, 0x0628, 0x0639, 0x0629, 0x002E)
        }
        'ReqSupport' {
            return ConvertFrom-AxisWizardCodePoints @(0x0662, 0x002E, 0x0020, 0x0625, 0x0630, 0x0627, 0x0020, 0x0644, 0x0645, 0x0020, 0x062A, 0x0643, 0x0646, 0x0020, 0x0645, 0x062A, 0x0623, 0x0643, 0x062F, 0x064B, 0x0627, 0x0020, 0x0645, 0x0646, 0x0020, 0x0637, 0x0631, 0x064A, 0x0642, 0x0629, 0x0020, 0x0636, 0x0628, 0x0637, 0x0020, 0x0627, 0x0644, 0x0625, 0x0639, 0x062F, 0x0627, 0x062F, 0x0627, 0x062A, 0x0020, 0x062D, 0x062A, 0x0649, 0x0020, 0x0628, 0x0639, 0x062F, 0x0020, 0x0642, 0x0631, 0x0627, 0x0621, 0x0629, 0x0020, 0x0627, 0x0644, 0x062A, 0x0639, 0x0644, 0x064A, 0x0645, 0x0627, 0x062A, 0x060C, 0x0020, 0x062A, 0x0648, 0x0627, 0x0635, 0x0644, 0x0020, 0x0645, 0x0639, 0x0020, 0x0627, 0x0644, 0x062F, 0x0639, 0x0645, 0x0020, 0x0644, 0x064A, 0x062A, 0x0645, 0x0020, 0x0625, 0x0631, 0x0634, 0x0627, 0x062F, 0x0643, 0x0020, 0x062E, 0x0637, 0x0648, 0x0629, 0x0020, 0x0628, 0x062E, 0x0637, 0x0648, 0x0629, 0x002E)
        }
        'RestartAcknowledgement' {
            return Get-AxisWizardArabicText -Name 'Acknowledgement'
        }
        'Restarting' {
            return ConvertFrom-AxisWizardCodePoints @(0x062C, 0x0627, 0x0631, 0x064A, 0x0020, 0x0625, 0x0639, 0x0627, 0x062F, 0x0629, 0x0020, 0x0627, 0x0644, 0x062A, 0x0634, 0x063A, 0x064A, 0x0644)
        }
        'ReinstallTitle' {
            return ConvertFrom-AxisWizardCodePoints @(0x062A, 0x062C, 0x0647, 0x064A, 0x0632, 0x0020, 0x062A, 0x062B, 0x0628, 0x064A, 0x062A, 0x0020, 0x0057, 0x0069, 0x006E, 0x0064, 0x006F, 0x0077, 0x0073)
        }
        'ReinstallSubtitle' {
            return ConvertFrom-AxisWizardCodePoints @(
                0x062A, 0x062C, 0x0647, 0x064A, 0x0632, 0x0020,
                0x0055, 0x0053, 0x0042, 0x0020,
                0x0628, 0x0627, 0x0633, 0x062A, 0x062E, 0x062F, 0x0627, 0x0645, 0x0020,
                0x062D, 0x0632, 0x0645, 0x0629, 0x0020,
                0x0057, 0x0069, 0x006E, 0x0064, 0x006F, 0x0077, 0x0073, 0x0020,
                0x0031, 0x0031, 0x0020,
                0x0627, 0x0644, 0x0631, 0x0633, 0x0645, 0x064A, 0x0629, 0x002E
            )
        }
        'ReinstallInfoTitle' {
            return ConvertFrom-AxisWizardCodePoints @(
                0x0625, 0x062C, 0x0631, 0x0627, 0x0621, 0x0020,
                0x0625, 0x0639, 0x0627, 0x062F, 0x0629, 0x0020,
                0x062A, 0x062B, 0x0628, 0x064A, 0x062A, 0x0020,
                0x0644, 0x0646, 0x0638, 0x0627, 0x0645, 0x0020,
                0x0627, 0x0644, 0x062A, 0x0634, 0x063A, 0x064A, 0x0644, 0x0020,
                0x0057, 0x0069, 0x006E, 0x0064, 0x006F, 0x0077, 0x0073, 0x0020,
                0x0031, 0x0031
            )
        }
        'ReinstallInfoBullet' {
            return ConvertFrom-AxisWizardCodePoints @(
                0x062A, 0x0646, 0x0632, 0x064A, 0x0644, 0x0020,
                0x0623, 0x062F, 0x0627, 0x0629, 0x0020,
                0x0625, 0x0646, 0x0634, 0x0627, 0x0621, 0x0020,
                0x0627, 0x0644, 0x0648, 0x0633, 0x0627, 0x0626, 0x0637, 0x0020,
                0x0627, 0x0644, 0x0631, 0x0633, 0x0645, 0x064A, 0x0629, 0x0020,
                0x0644, 0x0625, 0x0646, 0x0634, 0x0627, 0x0621, 0x0020,
                0x0055, 0x0053, 0x0042, 0x0020,
                0x0642, 0x0627, 0x0628, 0x0644, 0x0020,
                0x0644, 0x0644, 0x062A, 0x0645, 0x0647, 0x064A, 0x062F, 0x002E
            )
        }
        'ReinstallRequirementUsbSize' {
            return ConvertFrom-AxisWizardCodePoints @(
                0x0627, 0x0633, 0x062A, 0x062E, 0x062F, 0x0627, 0x0645, 0x0020,
                0x0055, 0x0053, 0x0042, 0x0020,
                0x0628, 0x0633, 0x0639, 0x0629, 0x0020,
                0x0644, 0x0627, 0x0020,
                0x062A, 0x0642, 0x0644, 0x0020,
                0x0639, 0x0646, 0x0020,
                0x0038, 0x0047, 0x0042, 0x002E
            )
        }
        'ReinstallRequirementNoData' {
            return ConvertFrom-AxisWizardCodePoints @(
                0x0627, 0x0644, 0x062A, 0x0623, 0x0643, 0x062F, 0x0020,
                0x0645, 0x0646, 0x0020,
                0x0639, 0x062F, 0x0645, 0x0020,
                0x0648, 0x062C, 0x0648, 0x062F, 0x0020,
                0x0628, 0x064A, 0x0627, 0x0646, 0x0627, 0x062A, 0x0020,
                0x0645, 0x0647, 0x0645, 0x0629, 0x0020,
                0x062F, 0x0627, 0x062E, 0x0644, 0x0020,
                0x0627, 0x0644, 0x0640, 0x0020,
                0x0055, 0x0053, 0x0042, 0x002E
            )
        }
        'ReinstallPrimaryAction' {
            return ConvertFrom-AxisWizardCodePoints @(
                0x0625, 0x0646, 0x0634, 0x0627, 0x0621, 0x0020,
                0x0648, 0x0633, 0x0627, 0x0626, 0x0637, 0x0020,
                0x062A, 0x062B, 0x0628, 0x064A, 0x062A, 0x0020,
                0x0057, 0x0069, 0x006E, 0x0064, 0x006F, 0x0077, 0x0073, 0x0020,
                0x0031, 0x0031
            )
        }
        'ReinstallRunning' {
            return ConvertFrom-AxisWizardCodePoints @(0x062C, 0x0627, 0x0631, 0x064A, 0x0020, 0x0627, 0x0644, 0x062A, 0x062C, 0x0647, 0x064A, 0x0632)
        }
        'ReinstallCompleted' {
            return ConvertFrom-AxisWizardCodePoints @(0x062C, 0x0627, 0x0647, 0x0632)
        }
        'AutoUnattendSubtitle' {
            return ConvertFrom-AxisWizardCodePoints @(
                0x0625, 0x0646, 0x0634, 0x0627, 0x0621, 0x0020, 0x0645, 0x0644, 0x0641, 0x0020,
                0x0058, 0x004D, 0x004C, 0x0020,
                0x0644, 0x0625, 0x0639, 0x062F, 0x0627, 0x062F, 0x0020,
                0x062A, 0x062B, 0x0628, 0x064A, 0x062A, 0x0020,
                0x0057, 0x0069, 0x006E, 0x0064, 0x006F, 0x0077, 0x0073, 0x0020,
                0x062A, 0x0644, 0x0642, 0x0627, 0x0626, 0x064A, 0x064B, 0x0627, 0x002E
            )
        }
        'AutoUnattendInfoTitle' {
            return ConvertFrom-AxisWizardCodePoints @(
                0x0645, 0x0644, 0x0641, 0x0020,
                0x0625, 0x0639, 0x062F, 0x0627, 0x062F, 0x0020,
                0x062A, 0x0644, 0x0642, 0x0627, 0x0626, 0x064A, 0x0020,
                0x0644, 0x062A, 0x062B, 0x0628, 0x064A, 0x062A, 0x0020,
                0x0057, 0x0069, 0x006E, 0x0064, 0x006F, 0x0077, 0x0073
            )
        }
        'AutoUnattendInfoBulletOobe' {
            return ConvertFrom-AxisWizardCodePoints @(
                0x064A, 0x0633, 0x0627, 0x0639, 0x062F, 0x0020,
                0x0645, 0x0644, 0x0641, 0x0020,
                0x0041, 0x0075, 0x0074, 0x006F, 0x0055, 0x006E, 0x0061, 0x0074, 0x0074, 0x0065, 0x006E, 0x0064, 0x0020,
                0x0639, 0x0644, 0x0649, 0x0020,
                0x062A, 0x062E, 0x0637, 0x064A, 0x0020,
                0x0645, 0x0631, 0x062D, 0x0644, 0x0629, 0x0020,
                0x004F, 0x004F, 0x0042, 0x0045, 0x0020,
                0x0623, 0x062B, 0x0646, 0x0627, 0x0621, 0x0020,
                0x062A, 0x062B, 0x0628, 0x064A, 0x062A, 0x0020,
                0x0057, 0x0069, 0x006E, 0x0064, 0x006F, 0x0077, 0x0073, 0x002E
            )
        }
        'AutoUnattendInfoBulletSetup' {
            return ConvertFrom-AxisWizardCodePoints @(
                0x064A, 0x062A, 0x062C, 0x0627, 0x0648, 0x0632, 0x0020,
                0x062E, 0x0637, 0x0648, 0x0627, 0x062A, 0x0020,
                0x0627, 0x0644, 0x0625, 0x0639, 0x062F, 0x0627, 0x062F, 0x0020,
                0x0627, 0x0644, 0x0623, 0x0648, 0x0644, 0x0649, 0x0020,
                0x0645, 0x062B, 0x0644, 0x0020,
                0x0625, 0x0639, 0x062F, 0x0627, 0x062F, 0x0627, 0x062A, 0x0020,
                0x0627, 0x0644, 0x062E, 0x0635, 0x0648, 0x0635, 0x064A, 0x0629, 0x060C, 0x0020,
                0x062A, 0x0633, 0x062C, 0x064A, 0x0644, 0x0020,
                0x0627, 0x0644, 0x062F, 0x062E, 0x0648, 0x0644, 0x0020,
                0x0628, 0x062D, 0x0633, 0x0627, 0x0628, 0x0020,
                0x004D, 0x0069, 0x0063, 0x0072, 0x006F, 0x0073, 0x006F, 0x0066, 0x0074, 0x060C, 0x0020,
                0x0648, 0x0627, 0x062E, 0x062A, 0x064A, 0x0627, 0x0631, 0x0020,
                0x0628, 0x0639, 0x0636, 0x0020,
                0x0625, 0x0639, 0x062F, 0x0627, 0x062F, 0x0627, 0x062A, 0x0020,
                0x0627, 0x0644, 0x0628, 0x062F, 0x0627, 0x064A, 0x0629, 0x002E
            )
        }
        'AutoUnattendInfoBulletUsb' {
            return ConvertFrom-AxisWizardCodePoints @(
                0x064A, 0x062A, 0x0645, 0x0020,
                0x0625, 0x0646, 0x0634, 0x0627, 0x0621, 0x0020,
                0x0627, 0x0644, 0x0645, 0x0644, 0x0641, 0x0020,
                0x062F, 0x0627, 0x062E, 0x0644, 0x0020,
                0x0055, 0x0053, 0x0042, 0x0020,
                0x062A, 0x062B, 0x0628, 0x064A, 0x062A, 0x0020,
                0x0057, 0x0069, 0x006E, 0x0064, 0x006F, 0x0077, 0x0073, 0x0020,
                0x0644, 0x064A, 0x062A, 0x0645, 0x0020,
                0x0627, 0x0633, 0x062A, 0x062E, 0x062F, 0x0627, 0x0645, 0x0647, 0x0020,
                0x0623, 0x062B, 0x0646, 0x0627, 0x0621, 0x0020,
                0x0639, 0x0645, 0x0644, 0x064A, 0x0629, 0x0020,
                0x0627, 0x0644, 0x062A, 0x062B, 0x0628, 0x064A, 0x062A, 0x002E
            )
        }
        'AutoUnattendRequirementAccount' {
            return ConvertFrom-AxisWizardCodePoints @(0x0627, 0x062E, 0x062A, 0x064A, 0x0627, 0x0631, 0x0020, 0x0627, 0x0633, 0x0645, 0x0020, 0x0627, 0x0644, 0x062D, 0x0633, 0x0627, 0x0628, 0x002E)
        }
        'AutoUnattendRequirementUsb' {
            return ConvertFrom-AxisWizardCodePoints @(0x0627, 0x062E, 0x062A, 0x064A, 0x0627, 0x0631, 0x0020, 0x0055, 0x0053, 0x0042, 0x0020, 0x0627, 0x0644, 0x0635, 0x062D, 0x064A, 0x062D, 0x002E)
        }
        'AutoUnattendPrimaryAction' {
            return ConvertFrom-AxisWizardCodePoints @(0x0625, 0x0646, 0x0634, 0x0627, 0x0621, 0x0020, 0x0627, 0x0644, 0x0645, 0x0644, 0x0641)
        }
        'AutoUnattendInputTitle' {
            return ConvertFrom-AxisWizardCodePoints @(0x0646, 0x0627, 0x0641, 0x0630, 0x0629, 0x0020, 0x0625, 0x0646, 0x0634, 0x0627, 0x0621, 0x0020, 0x0627, 0x0644, 0x0645, 0x0644, 0x0641)
        }
        'AutoUnattendAccountLabel' {
            return ConvertFrom-AxisWizardCodePoints @(0x0623, 0x062F, 0x062E, 0x0644, 0x0020, 0x0627, 0x0633, 0x0645, 0x0020, 0x0627, 0x0644, 0x062D, 0x0633, 0x0627, 0x0628, 0x0020, 0x0628, 0x062F, 0x0648, 0x0646, 0x0020, 0x0645, 0x0633, 0x0627, 0x0641, 0x0627, 0x062A, 0x002E)
        }
        'AutoUnattendUsbLabel' {
            return ConvertFrom-AxisWizardCodePoints @(0x0627, 0x062E, 0x062A, 0x0631, 0x0020, 0x0055, 0x0053, 0x0042, 0x002E)
        }
        'AutoUnattendRunning' {
            return ConvertFrom-AxisWizardCodePoints @(0x062C, 0x0627, 0x0631, 0x064A, 0x0020, 0x0627, 0x0644, 0x0625, 0x0646, 0x0634, 0x0627, 0x0621)
        }
        'AutoUnattendCompleted' {
            return ConvertFrom-AxisWizardCodePoints @(0x062A, 0x0645, 0x0020, 0x0627, 0x0644, 0x0625, 0x0646, 0x0634, 0x0627, 0x0621)
        }
        'UpdatesDriversSubtitle' {
            return ConvertFrom-AxisWizardCodePoints @(0x0645, 0x0646, 0x0639, 0x0020, 0x062A, 0x062D, 0x062F, 0x064A, 0x062B, 0x0627, 0x062A, 0x0020, 0x0627, 0x0644, 0x062A, 0x0639, 0x0631, 0x064A, 0x0641, 0x0627, 0x062A, 0x0020, 0x0645, 0x0646, 0x0020, 0x0057, 0x0069, 0x006E, 0x0064, 0x006F, 0x0077, 0x0073, 0x0020, 0x0055, 0x0070, 0x0064, 0x0061, 0x0074, 0x0065, 0x002E)
        }
        'UpdatesDriversInfoTitle' {
            return ConvertFrom-AxisWizardCodePoints @(0x062D, 0x0638, 0x0631, 0x0020, 0x062A, 0x062D, 0x062F, 0x064A, 0x062B, 0x0627, 0x062A, 0x0020, 0x0627, 0x0644, 0x062A, 0x0639, 0x0631, 0x064A, 0x0641, 0x0627, 0x062A, 0x0020, 0x063A, 0x064A, 0x0631, 0x0020, 0x0627, 0x0644, 0x0636, 0x0631, 0x0648, 0x0631, 0x064A, 0x0629)
        }
        'UpdatesDriversInfoBulletSetupcomplete' {
            return ConvertFrom-AxisWizardCodePoints @(0x0625, 0x0646, 0x0634, 0x0627, 0x0621, 0x0020, 0x0645, 0x0644, 0x0641, 0x0020, 0x0073, 0x0065, 0x0074, 0x0075, 0x0070, 0x0063, 0x006F, 0x006D, 0x0070, 0x006C, 0x0065, 0x0074, 0x0065, 0x002E, 0x0063, 0x006D, 0x0064, 0x0020, 0x062F, 0x0627, 0x062E, 0x0644, 0x0020, 0x0055, 0x0053, 0x0042, 0x0020, 0x062A, 0x062B, 0x0628, 0x064A, 0x062A, 0x0020, 0x0057, 0x0069, 0x006E, 0x0064, 0x006F, 0x0077, 0x0073, 0x002E)
        }
        'UpdatesDriversInfoBulletWindowsUpdate' {
            return ConvertFrom-AxisWizardCodePoints @(0x064A, 0x0645, 0x0646, 0x0639, 0x0020, 0x0057, 0x0069, 0x006E, 0x0064, 0x006F, 0x0077, 0x0073, 0x0020, 0x0055, 0x0070, 0x0064, 0x0061, 0x0074, 0x0065, 0x0020, 0x0645, 0x0646, 0x0020, 0x062A, 0x062B, 0x0628, 0x064A, 0x062A, 0x0020, 0x0627, 0x0644, 0x062A, 0x0639, 0x0631, 0x064A, 0x0641, 0x0627, 0x062A, 0x0020, 0x062A, 0x0644, 0x0642, 0x0627, 0x0626, 0x064A, 0x064B, 0x0627, 0x0020, 0x0623, 0x062B, 0x0646, 0x0627, 0x0621, 0x0020, 0x0625, 0x0639, 0x062F, 0x0627, 0x062F, 0x0020, 0x0627, 0x0644, 0x0646, 0x0638, 0x0627, 0x0645, 0x002E)
        }
        'UpdatesDriversRequirementUsb' {
            return ConvertFrom-AxisWizardCodePoints @(0x0627, 0x062E, 0x062A, 0x064A, 0x0627, 0x0631, 0x0020, 0x0055, 0x0053, 0x0042, 0x0020, 0x0627, 0x0644, 0x0635, 0x062D, 0x064A, 0x062D, 0x002E)
        }
        'UpdatesDriversPrimaryAction' {
            return ConvertFrom-AxisWizardCodePoints @(0x0625, 0x0646, 0x0634, 0x0627, 0x0621, 0x0020, 0x0645, 0x0644, 0x0641, 0x0020, 0x0645, 0x0646, 0x0639, 0x0020, 0x0627, 0x0644, 0x062A, 0x0639, 0x0631, 0x064A, 0x0641, 0x0627, 0x062A)
        }
        'UpdatesDriversInputTitle' {
            return ConvertFrom-AxisWizardCodePoints @(0x0646, 0x0627, 0x0641, 0x0630, 0x0629, 0x0020, 0x0625, 0x0646, 0x0634, 0x0627, 0x0621, 0x0020, 0x0627, 0x0644, 0x0645, 0x0644, 0x0641)
        }
        'UpdatesDriversUsbLabel' {
            return ConvertFrom-AxisWizardCodePoints @(0x0627, 0x062E, 0x062A, 0x0631, 0x0020, 0x0055, 0x0053, 0x0042, 0x002E)
        }
        'UpdatesDriversInputCreate' {
            return ConvertFrom-AxisWizardCodePoints @(0x0625, 0x0646, 0x0634, 0x0627, 0x0621, 0x0020, 0x0627, 0x0644, 0x0645, 0x0644, 0x0641)
        }
        'UpdatesDriversRunning' {
            return ConvertFrom-AxisWizardCodePoints @(0x062C, 0x0627, 0x0631, 0x064A, 0x0020, 0x0627, 0x0644, 0x062A, 0x062C, 0x0647, 0x064A, 0x0632)
        }
        'UpdatesDriversCompleted' {
            return ConvertFrom-AxisWizardCodePoints @(0x062C, 0x0627, 0x0647, 0x0632)
        }
        'ToBiosTitle' {
            return 'To BIOS'
        }
        'ToBiosSubtitle' {
            return ConvertFrom-AxisWizardCodePoints @(0x0625, 0x0639, 0x0627, 0x062F, 0x0629, 0x0020, 0x0627, 0x0644, 0x062A, 0x0634, 0x063A, 0x064A, 0x0644, 0x0020, 0x0648, 0x0627, 0x0644, 0x062F, 0x062E, 0x0648, 0x0644, 0x0020, 0x0625, 0x0644, 0x0649, 0x0020, 0x0625, 0x0639, 0x062F, 0x0627, 0x062F, 0x0627, 0x062A, 0x0020, 0x0042, 0x0049, 0x004F, 0x0053, 0x002E)
        }
        'ToBiosInfoTitle' {
            return ConvertFrom-AxisWizardCodePoints @(0x0627, 0x0644, 0x062F, 0x062E, 0x0648, 0x0644, 0x0020, 0x0625, 0x0644, 0x0649, 0x0020, 0x0625, 0x0639, 0x062F, 0x0627, 0x062F, 0x0627, 0x062A, 0x0020, 0x0042, 0x0049, 0x004F, 0x0053)
        }
        'ToBiosInfoBulletRestart' {
            return ConvertFrom-AxisWizardCodePoints @(0x0633, 0x064A, 0x062A, 0x0645, 0x0020, 0x0625, 0x0639, 0x0627, 0x062F, 0x0629, 0x0020, 0x062A, 0x0634, 0x063A, 0x064A, 0x0644, 0x0020, 0x0627, 0x0644, 0x062C, 0x0647, 0x0627, 0x0632, 0x0020, 0x0648, 0x0627, 0x0644, 0x062F, 0x062E, 0x0648, 0x0644, 0x0020, 0x0625, 0x0644, 0x0649, 0x0020, 0x0634, 0x0627, 0x0634, 0x0629, 0x0020, 0x0042, 0x0049, 0x004F, 0x0053, 0x002E)
        }
        'ToBiosInfoBulletUsbBoot' {
            return ConvertFrom-AxisWizardCodePoints @(0x064A, 0x0645, 0x0643, 0x0646, 0x0643, 0x0020, 0x0628, 0x0639, 0x062F, 0x0647, 0x0627, 0x0020, 0x0627, 0x062E, 0x062A, 0x064A, 0x0627, 0x0631, 0x0020, 0x0627, 0x0644, 0x0625, 0x0642, 0x0644, 0x0627, 0x0639, 0x0020, 0x0645, 0x0646, 0x0020, 0x0055, 0x0053, 0x0042, 0x0020, 0x062A, 0x062B, 0x0628, 0x064A, 0x062A, 0x0020, 0x0057, 0x0069, 0x006E, 0x0064, 0x006F, 0x0077, 0x0073, 0x0020, 0x0627, 0x0644, 0x0630, 0x064A, 0x0020, 0x062A, 0x0645, 0x0020, 0x062A, 0x062C, 0x0647, 0x064A, 0x0632, 0x0647, 0x0020, 0x0645, 0x0633, 0x0628, 0x0642, 0x064B, 0x0627, 0x002E)
        }
        'ToBiosInfoBulletInstall' {
            return ConvertFrom-AxisWizardCodePoints @(0x0628, 0x0639, 0x062F, 0x0020, 0x0627, 0x0644, 0x0625, 0x0642, 0x0644, 0x0627, 0x0639, 0x0020, 0x0645, 0x0646, 0x0020, 0x0055, 0x0053, 0x0042, 0x060C, 0x0020, 0x064A, 0x0645, 0x0643, 0x0646, 0x0643, 0x0020, 0x0628, 0x062F, 0x0621, 0x0020, 0x062A, 0x062B, 0x0628, 0x064A, 0x062A, 0x0020, 0x0057, 0x0069, 0x006E, 0x0064, 0x006F, 0x0077, 0x0073, 0x0020, 0x0639, 0x0644, 0x0649, 0x0020, 0x0627, 0x0644, 0x062C, 0x0647, 0x0627, 0x0632, 0x002E)
        }
        'ToBiosPrimaryAction' {
            return ConvertFrom-AxisWizardCodePoints @(0x0625, 0x0639, 0x0627, 0x062F, 0x0629, 0x0020, 0x0627, 0x0644, 0x062A, 0x0634, 0x063A, 0x064A, 0x0644, 0x0020, 0x0625, 0x0644, 0x0649, 0x0020, 0x0042, 0x0049, 0x004F, 0x0053)
        }
        'InstallersTitle' {
            return ConvertFrom-AxisWizardCodePoints @(0x062A, 0x062B, 0x0628, 0x064A, 0x062A, 0x0020, 0x0627, 0x0644, 0x0628, 0x0631, 0x0627, 0x0645, 0x062C)
        }
        'InstallersSubtitle' {
            return ConvertFrom-AxisWizardCodePoints @(0x0627, 0x062E, 0x062A, 0x064A, 0x0627, 0x0631, 0x0020, 0x0648, 0x062A, 0x062B, 0x0628, 0x064A, 0x062A, 0x0020, 0x0627, 0x0644, 0x0628, 0x0631, 0x0627, 0x0645, 0x062C, 0x0020, 0x0627, 0x0644, 0x0623, 0x0633, 0x0627, 0x0633, 0x064A, 0x0629, 0x0020, 0x0639, 0x0644, 0x0649, 0x0020, 0x0627, 0x0644, 0x062C, 0x0647, 0x0627, 0x0632, 0x002E)
        }
        'InstallersSelectorLabel' {
            return ConvertFrom-AxisWizardCodePoints @(0x0627, 0x062E, 0x062A, 0x0631, 0x0020, 0x0627, 0x0644, 0x0628, 0x0631, 0x0646, 0x0627, 0x0645, 0x062C)
        }
        'InstallersSelectorPlaceholder' {
            return ConvertFrom-AxisWizardCodePoints @(0x0627, 0x062E, 0x062A, 0x0631, 0x0020, 0x0628, 0x0631, 0x0646, 0x0627, 0x0645, 0x062C, 0x064B, 0x0627, 0x0020, 0x0645, 0x0646, 0x0020, 0x0627, 0x0644, 0x0642, 0x0627, 0x0626, 0x0645, 0x0629)
        }
        'InstallersInfoTitle' {
            return ConvertFrom-AxisWizardCodePoints @(0x0627, 0x062E, 0x062A, 0x064A, 0x0627, 0x0631, 0x0020, 0x0627, 0x0644, 0x0628, 0x0631, 0x0646, 0x0627, 0x0645, 0x062C)
        }
        'InstallersInfoBullet1' {
            return ConvertFrom-AxisWizardCodePoints @(0x0627, 0x062E, 0x062A, 0x0631, 0x0020, 0x0627, 0x0644, 0x0628, 0x0631, 0x0646, 0x0627, 0x0645, 0x062C, 0x0020, 0x0627, 0x0644, 0x0645, 0x0637, 0x0644, 0x0648, 0x0628, 0x0020, 0x0645, 0x0646, 0x0020, 0x0627, 0x0644, 0x0642, 0x0627, 0x0626, 0x0645, 0x0629, 0x002E)
        }
        'InstallersInfoBullet2' {
            return ConvertFrom-AxisWizardCodePoints @(0x0633, 0x064A, 0x062A, 0x0645, 0x0020, 0x062A, 0x062C, 0x0647, 0x064A, 0x0632, 0x0020, 0x062A, 0x062B, 0x0628, 0x064A, 0x062A, 0x0020, 0x0627, 0x0644, 0x0628, 0x0631, 0x0646, 0x0627, 0x0645, 0x062C, 0x0020, 0x0627, 0x0644, 0x0645, 0x062D, 0x062F, 0x062F, 0x0020, 0x0639, 0x0644, 0x0649, 0x0020, 0x0627, 0x0644, 0x062C, 0x0647, 0x0627, 0x0632, 0x002E)
        }
        'InstallersInfoBullet3' {
            return ConvertFrom-AxisWizardCodePoints @(0x064A, 0x0638, 0x0647, 0x0631, 0x0020, 0x0627, 0x0633, 0x0645, 0x0020, 0x0627, 0x0644, 0x0628, 0x0631, 0x0646, 0x0627, 0x0645, 0x062C, 0x0020, 0x0627, 0x0644, 0x0645, 0x062D, 0x062F, 0x062F, 0x0020, 0x0623, 0x062B, 0x0646, 0x0627, 0x0621, 0x0020, 0x0639, 0x0645, 0x0644, 0x064A, 0x0629, 0x0020, 0x0627, 0x0644, 0x062A, 0x062B, 0x0628, 0x064A, 0x062A, 0x002E)
        }
        'InstallersRequirementsBullet1' {
            return ConvertFrom-AxisWizardCodePoints @(0x0642, 0x0645, 0x0020, 0x0628, 0x0625, 0x063A, 0x0644, 0x0627, 0x0642, 0x0020, 0x0627, 0x0644, 0x0628, 0x0631, 0x0627, 0x0645, 0x062C, 0x0020, 0x0627, 0x0644, 0x0645, 0x0641, 0x062A, 0x0648, 0x062D, 0x0629, 0x0020, 0x0642, 0x0628, 0x0644, 0x0020, 0x0628, 0x062F, 0x0621, 0x0020, 0x0627, 0x0644, 0x062A, 0x062B, 0x0628, 0x064A, 0x062A, 0x002E)
        }
        'InstallersRequirementsBullet2' {
            return ConvertFrom-AxisWizardCodePoints @(0x0627, 0x0646, 0x062A, 0x0638, 0x0631, 0x0020, 0x062D, 0x062A, 0x0649, 0x0020, 0x062A, 0x0643, 0x062A, 0x0645, 0x0644, 0x0020, 0x0639, 0x0645, 0x0644, 0x064A, 0x0629, 0x0020, 0x062A, 0x062B, 0x0628, 0x064A, 0x062A, 0x0020, 0x0627, 0x0644, 0x0628, 0x0631, 0x0646, 0x0627, 0x0645, 0x062C, 0x0020, 0x0627, 0x0644, 0x0645, 0x062D, 0x062F, 0x062F, 0x002E)
        }
        'InstallersRunning' {
            return ConvertFrom-AxisWizardCodePoints @(0x062C, 0x0627, 0x0631, 0x064A, 0x0020, 0x0627, 0x0644, 0x062A, 0x062B, 0x0628, 0x064A, 0x062A)
        }
        'InstallersCompleted' {
            return ConvertFrom-AxisWizardCodePoints @(0x062A, 0x0645, 0x0020, 0x0627, 0x0644, 0x062A, 0x062B, 0x064A, 0x062A)
        }
        'InstallersSelectedProgramPrefix' {
            return ConvertFrom-AxisWizardCodePoints @(0x0627, 0x0644, 0x0628, 0x0631, 0x0646, 0x0627, 0x0645, 0x062C, 0x0020, 0x0627, 0x0644, 0x0645, 0x062D, 0x062F, 0x062F, 0x003A)
        }
        'InstallersEpicOverlayTitle' {
            return ConvertFrom-AxisWizardCodePoints @(0x062E, 0x0637, 0x0648, 0x0629, 0x0020, 0x0625, 0x0636, 0x0627, 0x0641, 0x064A, 0x0629, 0x0020, 0x0644, 0x0640, 0x0020, 0x0045, 0x0070, 0x0069, 0x0063, 0x0020, 0x0047, 0x0061, 0x006D, 0x0065, 0x0073)
        }
        'InstallersEpicOverlayBody1' {
            return ConvertFrom-AxisWizardCodePoints @(0x0628, 0x0639, 0x062F, 0x0020, 0x0627, 0x0643, 0x062A, 0x0645, 0x0627, 0x0644, 0x0020, 0x062A, 0x062B, 0x0628, 0x064A, 0x062A, 0x0020, 0x0045, 0x0070, 0x0069, 0x0063, 0x0020, 0x0047, 0x0061, 0x006D, 0x0065, 0x0073, 0x0020, 0x004C, 0x0061, 0x0075, 0x006E, 0x0063, 0x0068, 0x0065, 0x0072, 0x0020, 0x0648, 0x0638, 0x0647, 0x0648, 0x0631, 0x0020, 0x0646, 0x0627, 0x0641, 0x0630, 0x062A, 0x0647, 0x060C, 0x0020, 0x0623, 0x063A, 0x0644, 0x0642, 0x0020, 0x0646, 0x0627, 0x0641, 0x0630, 0x0629, 0x0020, 0x0045, 0x0070, 0x0069, 0x0063, 0x0020, 0x0047, 0x0061, 0x006D, 0x0065, 0x0073, 0x0020, 0x004C, 0x0061, 0x0075, 0x006E, 0x0063, 0x0068, 0x0065, 0x0072, 0x0020, 0x0623, 0x0648, 0x0644, 0x064B, 0x0627, 0x002E)
        }
        'InstallersEpicOverlayBody2' {
            return ConvertFrom-AxisWizardCodePoints @(0x0628, 0x0639, 0x062F, 0x0020, 0x0630, 0x0644, 0x0643, 0x0020, 0x0633, 0x062A, 0x0638, 0x0647, 0x0631, 0x0020, 0x0646, 0x0627, 0x0641, 0x0630, 0x0629, 0x0020, 0x0625, 0x0632, 0x0627, 0x0644, 0x0629, 0x0020, 0x062E, 0x062F, 0x0645, 0x0629, 0x0020, 0x0045, 0x0070, 0x0069, 0x0063, 0x0020, 0x0047, 0x0061, 0x006D, 0x0065, 0x0073, 0x0020, 0x063A, 0x064A, 0x0631, 0x0020, 0x0627, 0x0644, 0x0636, 0x0631, 0x0648, 0x0631, 0x064A, 0x0629, 0x0020, 0x0645, 0x0646, 0x0020, 0x0645, 0x062B, 0x0628, 0x062A, 0x0020, 0x0045, 0x0070, 0x0069, 0x0063, 0x0020, 0x0047, 0x0061, 0x006D, 0x0065, 0x0073, 0x002E)
        }
        'InstallersEpicOverlayBody3' {
            return ConvertFrom-AxisWizardCodePoints @(0x0627, 0x062E, 0x062A, 0x0631, 0x0020, 0x0627, 0x0644, 0x0625, 0x0632, 0x0627, 0x0644, 0x0629, 0x0020, 0x0623, 0x0648, 0x0020, 0x0627, 0x0644, 0x0645, 0x0648, 0x0627, 0x0641, 0x0642, 0x0629, 0x0020, 0x0645, 0x0646, 0x0020, 0x0627, 0x0644, 0x0646, 0x0627, 0x0641, 0x0630, 0x0629, 0x0020, 0x0644, 0x0625, 0x0643, 0x0645, 0x0627, 0x0644, 0x0020, 0x062A, 0x062D, 0x0633, 0x064A, 0x0646, 0x0020, 0x062A, 0x062C, 0x0631, 0x0628, 0x0629, 0x0020, 0x0627, 0x0644, 0x062A, 0x0634, 0x063A, 0x064A, 0x0644, 0x002E)
        }
        'InstallersEpicOverlayReturn' {
            return ConvertFrom-AxisWizardCodePoints @(0x0631, 0x062C, 0x0648, 0x0639)
        }
        'RestartAfterInstallersTitle' {
            return ConvertFrom-AxisWizardCodePoints @(0x0625, 0x0639, 0x0627, 0x062F, 0x0629, 0x0020, 0x062A, 0x0634, 0x063A, 0x064A, 0x0644, 0x0020, 0x0627, 0x0644, 0x062C, 0x0647, 0x0627, 0x0632)
        }
        'RestartAfterInstallersSubtitle' {
            return ConvertFrom-AxisWizardCodePoints @(0x0625, 0x0639, 0x0627, 0x062F, 0x0629, 0x0020, 0x062A, 0x0634, 0x063A, 0x064A, 0x0644, 0x0020, 0x0627, 0x0644, 0x062C, 0x0647, 0x0627, 0x0632, 0x0020, 0x0628, 0x0639, 0x062F, 0x0020, 0x062A, 0x062B, 0x0628, 0x064A, 0x062A, 0x0020, 0x0627, 0x0644, 0x0628, 0x0631, 0x0627, 0x0645, 0x062C, 0x0020, 0x0648, 0x0645, 0x0631, 0x0627, 0x062C, 0x0639, 0x0629, 0x0020, 0x0628, 0x062F, 0x0621, 0x0020, 0x0627, 0x0644, 0x062A, 0x0634, 0x063A, 0x064A, 0x0644, 0x002E)
        }
        'RestartAfterInstallersInfoBullet1' {
            return ConvertFrom-AxisWizardCodePoints @(0x0628, 0x0639, 0x062F, 0x0020, 0x062A, 0x062B, 0x0628, 0x064A, 0x062A, 0x0020, 0x0627, 0x0644, 0x0628, 0x0631, 0x0627, 0x0645, 0x062C, 0x0020, 0x0648, 0x0645, 0x0631, 0x0627, 0x062C, 0x0639, 0x0629, 0x0020, 0x062A, 0x0637, 0x0628, 0x064A, 0x0642, 0x0627, 0x062A, 0x0020, 0x0628, 0x062F, 0x0621, 0x0020, 0x0627, 0x0644, 0x062A, 0x0634, 0x063A, 0x064A, 0x0644, 0x060C, 0x0020, 0x0623, 0x0639, 0x062F, 0x0020, 0x062A, 0x0634, 0x063A, 0x064A, 0x0644, 0x0020, 0x0627, 0x0644, 0x062C, 0x0647, 0x0627, 0x0632, 0x0020, 0x0644, 0x062A, 0x0637, 0x0628, 0x064A, 0x0642, 0x0020, 0x0627, 0x0644, 0x062A, 0x0631, 0x062A, 0x064A, 0x0628, 0x0020, 0x0627, 0x0644, 0x062C, 0x062F, 0x064A, 0x062F, 0x002E)
        }
        'RestartAfterInstallersInfoBullet2' {
            return ConvertFrom-AxisWizardCodePoints @(0x062A, 0x0633, 0x0627, 0x0639, 0x062F, 0x0020, 0x0625, 0x0639, 0x0627, 0x062F, 0x0629, 0x0020, 0x0627, 0x0644, 0x062A, 0x0634, 0x063A, 0x064A, 0x0644, 0x0020, 0x0639, 0x0644, 0x0649, 0x0020, 0x0625, 0x063A, 0x0644, 0x0627, 0x0642, 0x0020, 0x0627, 0x0644, 0x0639, 0x0645, 0x0644, 0x064A, 0x0627, 0x062A, 0x0020, 0x0627, 0x0644, 0x062C, 0x062F, 0x064A, 0x062F, 0x0629, 0x0020, 0x0648, 0x0628, 0x062F, 0x0621, 0x0020, 0x0627, 0x0644, 0x0646, 0x0638, 0x0627, 0x0645, 0x0020, 0x0628, 0x0634, 0x0643, 0x0644, 0x0020, 0x0646, 0x0638, 0x064A, 0x0641, 0x002E)
        }
        'RestartAfterInstallersInfoBullet3' {
            return ConvertFrom-AxisWizardCodePoints @(0x0628, 0x0639, 0x062F, 0x0020, 0x0627, 0x0643, 0x062A, 0x0645, 0x0627, 0x0644, 0x0020, 0x0647, 0x0630, 0x0647, 0x0020, 0x0627, 0x0644, 0x062E, 0x0637, 0x0648, 0x0629, 0x060C, 0x0020, 0x064A, 0x0645, 0x0643, 0x0646, 0x0643, 0x0020, 0x0645, 0x062A, 0x0627, 0x0628, 0x0639, 0x0629, 0x0020, 0x0625, 0x0639, 0x062F, 0x0627, 0x062F, 0x0020, 0x0041, 0x0058, 0x0049, 0x0053, 0x002E)
        }
    }
}

function Get-AxisFirstUseWizardInstallersCatalogNames {
    [CmdletBinding()]
    param(
        [string]$ProjectRoot = (Get-AxisFirstUseWizardProjectRoot)
    )

    $modulePath = Join-Path $ProjectRoot 'modules\Installers\installers.psm1'
    $fallbackCatalogNames = @(
        'Discord',
        'Roblox',
        '7-Zip',
        'Battle.net',
        'Brave',
        'Electronic Arts',
        'Epic Games',
        'Firefox',
        'Google Chrome',
        'League Of Legends',
        'OBS Studio',
        'Rockstar Games',
        'Spotify',
        'Steam',
        'Ubisoft Connect',
        'Valorant'
    )

    if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
        return $fallbackCatalogNames
    }

    $moduleSource = Get-Content -Raw -LiteralPath $modulePath
    $catalogItems = [System.Collections.Generic.List[object]]::new()
    foreach ($match in [regex]::Matches($moduleSource, "(?m)^\s*New-BoostLabInstallersAppDescriptor\s+-SourceMenuNumber\s+(?<Number>\d+)\s+-AppId\s+'(?<AppId>[^']+)'\s+-DisplayName\s+'(?<DisplayName>[^']+)'")) {
        $catalogItems.Add([pscustomobject]@{
            Number = [int]$match.Groups['Number'].Value
            AppId = [string]$match.Groups['AppId'].Value
            DisplayName = [string]$match.Groups['DisplayName'].Value
        })
    }

    $displayNames = @(
        $catalogItems |
            Sort-Object Number |
            ForEach-Object { [string]$_.DisplayName } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
    if ($displayNames.Count -eq 0) {
        return $fallbackCatalogNames
    }

    return $displayNames
}

function New-AxisWizardPanel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Resources,

        [string]$BackgroundKey = 'Axis.Brush.Surface.Base',
        [string]$BorderBrushKey = 'Axis.Brush.Border.Subtle',
        [string]$RadiusKey = 'Axis.Radius.Large',
        [System.Windows.Thickness]$Padding = (New-AxisWizardThickness -Left 16),
        [System.Windows.Thickness]$Margin = (New-AxisWizardThickness -Left 0),
        [System.Windows.Thickness]$BorderThickness = (New-AxisWizardThickness -Left 1),
        [ValidateSet('None', 'Soft', 'Card')]
        [string]$Elevation = 'None'
    )

    $panel = [System.Windows.Controls.Border]::new()
    $panel.Background = Get-AxisWizardResource -Resources $Resources -Name $BackgroundKey
    $panel.BorderBrush = Get-AxisWizardResource -Resources $Resources -Name $BorderBrushKey
    $panel.BorderThickness = $BorderThickness
    $panel.CornerRadius = Get-AxisWizardResource -Resources $Resources -Name $RadiusKey
    $panel.Padding = $Padding
    $panel.Margin = $Margin
    if ($Elevation -eq 'Soft') {
        $panel.Effect = New-AxisWizardShadowEffect -Opacity 0.08 -BlurRadius 14 -ShadowDepth 2
    }
    elseif ($Elevation -eq 'Card') {
        $panel.Effect = New-AxisWizardShadowEffect -Opacity 0.12 -BlurRadius 24 -ShadowDepth 5
    }
    return $panel
}

function New-AxisWizardButton {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [object]$Resources,

        [ValidateSet('Primary', 'Secondary', 'Quiet')]
        [string]$Variant = 'Secondary',

        [bool]$Enabled = $true,

        [double]$Width = 0.0,

        [double]$Height = 42.0,

        [System.Windows.Thickness]$Margin = (New-AxisWizardThickness -Left 8 -Top 0 -Right 0 -Bottom 0)
    )

    $button = [System.Windows.Controls.Button]::new()
    $button.Content = $Text
    $button.Padding = New-AxisWizardThickness -Left 18 -Top 8 -Right 18 -Bottom 8
    $button.Margin = $Margin
    $button.BorderThickness = New-AxisWizardThickness -Left 1
    $button.FontFamily = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontFamily'
    $button.FontSize = [double](Get-AxisWizardResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontSize')
    $button.FontWeight = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Type.Micro.FontWeight'
    $button.Height = $Height
    $button.MinHeight = $Height
    $button.SnapsToDevicePixels = $true
    $button.UseLayoutRounding = $true
    if ($Width -gt 0) {
        $button.Width = $Width
    }
    $button.Style = Get-AxisWizardButtonStyle
    $button.Focusable = $true
    $button.IsHitTestVisible = $true
    $button.IsEnabled = $Enabled
    $button.Tag = 'AxisFirstUseWizard.VisualButton'

    if (-not $Enabled) {
        $button.Background = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.SurfaceSoft'
        $button.BorderBrush = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.BorderSoft'
        $button.Foreground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.TextMuted'
    }
    elseif ($Variant -eq 'Primary') {
        $button.Background = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.PrimaryButton'
        $button.BorderBrush = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.PrimaryButtonHover'
        $button.Foreground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.PrimaryButtonText'
        $button.Effect = New-AxisWizardShadowEffect -Opacity 0.16 -BlurRadius 16 -ShadowDepth 3
    }
    elseif ($Variant -eq 'Quiet') {
        $button.Background = [System.Windows.Media.Brushes]::Transparent
        $button.BorderBrush = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.BorderSoft'
        $button.Foreground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.TextSecondary'
    }
    else {
        $button.Background = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.SecondaryButton'
        $button.BorderBrush = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.Border'
        $button.Foreground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.TextPrimary'
        $button.Effect = New-AxisWizardShadowEffect -Opacity 0.08 -BlurRadius 12 -ShadowDepth 2
    }

    if ($Variant -eq 'Primary') {
        Set-AxisWizardButtonHoverResources `
            -Button $button `
            -HoverBackground (Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.PrimaryButtonHover') `
            -HoverBorder (Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.TextHighlight')
    }
    else {
        Set-AxisWizardButtonHoverResources `
            -Button $button `
            -HoverBackground (Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.SecondaryButtonHover') `
            -HoverBorder (Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.BorderStrong')
    }

    return $button
}

function Get-AxisWizardStatusResourceName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$State
    )

    switch ($State) {
        'Ready' { return 'Running' }
        'Checking' { return 'Running' }
        'Running' { return 'Running' }
        'Completed' { return 'Completed' }
        default { return 'Running' }
    }
}

function Get-AxisWizardStepStateResourceKeys {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$State
    )

    $stateKey = switch ($State) {
        'Completed' { 'StateCompleted' }
        'Checking' { 'StateChecking' }
        'Running' { 'StateChecking' }
        default { 'StateReady' }
    }

    return [ordered]@{
        Background = "Axis.Brush.Wizard.$stateKey.Background"
        Border = "Axis.Brush.Wizard.$stateKey.Border"
        Text = "Axis.Brush.Wizard.$stateKey.Text"
    }
}

function Get-AxisFirstUseWizardSampleState {
    [CmdletBinding()]
    param()

    $mockHardwareProfile = [ordered]@{
        Marker = 'AxisFirstUseWizard.MockHardwareProfile'
        CpuVendor = 'Intel'
        MotherboardVendor = 'MSI'
        Summary = 'CPU=Intel; Motherboard=MSI'
        PrototypeOnly = $true
    }

    function New-AxisSetupWizardStepState {
        param(
            [Parameter(Mandatory)]
            [string]$Id,

            [Parameter(Mandatory)]
            [string]$Title,

            [Parameter(Mandatory)]
            [string]$Description,

            [Parameter(Mandatory)]
            [string]$PrimaryActionLabel,

            [Parameter(Mandatory)]
            [string]$InformationCardTitle,

            [Parameter(Mandatory)]
            [string[]]$InformationItems,

            [Parameter(Mandatory)]
            [string]$CheckingStatusTitle,

            [Parameter(Mandatory)]
            [string]$CompletedStatusTitle,

            [Parameter(Mandatory)]
            [string]$CustomerAction,

            [Parameter(Mandatory)]
            [string]$FutureInternalAction,

            [Parameter(Mandatory)]
            [string]$TagRoot,

            [string[]]$RequirementsItems = @(),

            [string]$RequirementsTitle = '',

            [bool]$RequiresConfirmationAcknowledgement = $false,

            [string]$DocumentationAcknowledgementText = '',

            [string]$ConfirmationActionLabel = '',

            [string]$ConfirmationReturnLabel = '',

            [bool]$OpenMappedPrototypeOnly = $false,

            [double]$PrimaryActionWidth = 142.0,

            [double]$RuntimeStatusWidth = 234.0,

            [double]$RuntimeStatusContentWidth = 210.0,

            [double]$RuntimeStatusTextMaxWidth = 106.0,

            [double]$ConfirmationActionWidth = 124.0,

            [string]$StageName = 'Setup',

            [string]$StageBatchMarker = 'AxisFirstUseWizard.SetupStageBatchPrototypeOnly',

            [string]$NoRealActionMarker = 'AxisFirstUseWizard.SetupPrototypeOnlyNoRuntimeAction',

            [bool]$RequiresGpuSelector = $false,

            [string]$GpuSelectorLabel = '',

            [string[]]$GpuSelectorOptions = @(),

            [string[]]$GpuSelectorEnabledOptions = @(),

            [bool]$RequiresActionSelector = $false,

            [string]$ActionSelectorLabel = '',

            [string]$ActionSelectorPlaceholder = '',

            [string[]]$ActionSelectorOptions = @(),

            [string]$OptionalContinuationLabel = ''
        )

        $step = [ordered]@{
            Id = $Id
            Title = $Title
            StageName = $StageName
            State = 'Ready'
            StateLabel = ''
            PrimaryActionLabel = $PrimaryActionLabel
            RunningActionLabel = $PrimaryActionLabel
            CompletionStateLabel = $CompletedStatusTitle
            CompletedStatusText = ''
            Description = $Description
            InformationCardTitle = $InformationCardTitle
            InformationItems = @($InformationItems)
            ShowRequirements = ($RequirementsItems.Count -gt 0)
            DocumentationLabel = (Get-AxisWizardArabicText -Name 'Documentation')
            RequiresConfirmationAcknowledgement = $RequiresConfirmationAcknowledgement
            SupportTitle = (Get-AxisWizardArabicText -Name 'SupportTitle')
            SupportBody = (Get-AxisWizardArabicText -Name 'SupportBody')
            CheckingStatusTitle = $CheckingStatusTitle
            CompletedStatusTitle = $CompletedStatusTitle
            CustomerAction = $CustomerAction
            FutureInternalAction = $FutureInternalAction
            CustomerVisibleActions = @($PrimaryActionLabel)
            PrototypeOnlySimulation = $true
            SetupStageBatchMarker = $StageBatchMarker
            NoRealActionMarker = $NoRealActionMarker
            TagRoot = $TagRoot
            PrimaryActionWidth = $PrimaryActionWidth
            RuntimeStatusWidth = $RuntimeStatusWidth
            RuntimeStatusContentWidth = $RuntimeStatusContentWidth
            RuntimeStatusTextMaxWidth = $RuntimeStatusTextMaxWidth
        }

        if ($StageName -eq 'Installers') {
            $step['InstallersStageExtensionMarker'] = $StageBatchMarker
        }
        elseif ($StageName -eq 'Graphics') {
            $step['GraphicsStageBatchMarker'] = $StageBatchMarker
        }
        elseif ($StageName -eq 'Windows') {
            $step['WindowsStageBatchMarker'] = $StageBatchMarker
        }
        elseif ($StageName -eq 'Advanced') {
            $step['AdvancedStageBatchMarker'] = $StageBatchMarker
        }

        if ($RequirementsItems.Count -gt 0) {
            $step['RequirementsTitle'] = $RequirementsTitle
            $step['RequirementsItems'] = @($RequirementsItems)
        }
        else {
            $step['NoRequirementsCard'] = $true
        }

        if ($RequiresConfirmationAcknowledgement) {
            $step['DocumentationAcknowledgementText'] = $DocumentationAcknowledgementText
            $step['ConfirmationActionLabel'] = $ConfirmationActionLabel
            $step['ConfirmationReturnLabel'] = $ConfirmationReturnLabel
            $step['ConfirmationActionWidth'] = $ConfirmationActionWidth
        }
        else {
            $step['NoConfirmationOverlay'] = $true
        }

        if ($OpenMappedPrototypeOnly) {
            $step['OpenMappedPrototypeOnly'] = $true
        }

        if ($RequiresGpuSelector) {
            $step['RequiresGpuSelector'] = $true
            $step['GpuSelectorLabel'] = $GpuSelectorLabel
            $step['GpuSelectorOptions'] = @($GpuSelectorOptions)
            $step['GpuSelectorEnabledOptions'] = @($GpuSelectorEnabledOptions)
            $step['PrimaryActionRequiresSelection'] = $true
            $step['GpuSelectorPrototypeOnly'] = $true
        }

        if ($RequiresActionSelector) {
            $step['RequiresActionSelector'] = $true
            $step['ActionSelectorLabel'] = $ActionSelectorLabel
            $step['ActionSelectorPlaceholder'] = $ActionSelectorPlaceholder
            $step['ActionSelectorOptions'] = @($ActionSelectorOptions)
            $step['PrimaryActionRequiresSelection'] = $true
            $step['ActionSelectorPrototypeOnly'] = $true
            $step['ActionSelectorSingleSelect'] = $true
        }

        if (-not [string]::IsNullOrWhiteSpace($OptionalContinuationLabel)) {
            $step['OptionalContinuationLabel'] = $OptionalContinuationLabel
            $step['OptionalContinuationNoRuntimeAction'] = $true
            $step['OptionalContinuationAutomationId'] = 'AxisFirstUseWizard.NvidiaAppOptionalContinuationNoApplySimulation'
        }

        return $step
    }

    $biosStep = [ordered]@{
        Id = 'bios-information'
        Title = 'BIOS Drivers & Downloads'
        StageName = 'Check'
        State = 'Ready'
        StateLabel = ''
        PrimaryActionLabel = (Get-AxisWizardArabicText -Name 'Open')
        RunningActionLabel = (Get-AxisWizardArabicText -Name 'Open')
        CompletionStateLabel = (Get-AxisWizardArabicText -Name 'Completed')
        CompletedStatusText = ''
        Description = (Get-AxisWizardArabicText -Name 'Subtitle')
        InformationCardTitle = (Get-AxisWizardArabicText -Name 'InformationCardTitle')
        InformationItems = @(
            (Get-AxisWizardArabicText -Name 'NetworkDriver')
            (Get-AxisWizardArabicText -Name 'AudioDriver')
        )
        ShowRequirements = $false
        DocumentationLabel = (Get-AxisWizardArabicText -Name 'Documentation')
        RequiresConfirmationAcknowledgement = $true
        DocumentationAcknowledgementText = (Get-AxisWizardArabicText -Name 'Acknowledgement')
        ConfirmationActionLabel = (Get-AxisWizardArabicText -Name 'Open')
        ConfirmationReturnLabel = (Get-AxisWizardArabicText -Name 'Return')
        SupportTitle = (Get-AxisWizardArabicText -Name 'SupportTitle')
        SupportBody = (Get-AxisWizardArabicText -Name 'SupportBody')
        CheckingStatusTitle = (Get-AxisWizardArabicText -Name 'Checking')
        CompletedStatusTitle = (Get-AxisWizardArabicText -Name 'Completed')
        CustomerAction = 'Open'
        CustomerVisibleActions = @('Open')
    }

    $biosSettingsStep = [ordered]@{
        Id = 'bios-settings'
        Title = 'BIOS Settings'
        StageName = 'Check'
        State = 'Ready'
        StateLabel = ''
        PrimaryActionLabel = (Get-AxisWizardArabicText -Name 'Restart')
        RunningActionLabel = (Get-AxisWizardArabicText -Name 'Restart')
        CompletionStateLabel = (Get-AxisWizardArabicText -Name 'Completed')
        CompletedStatusText = ''
        Description = (Get-AxisWizardArabicText -Name 'BiosSettingsSubtitle')
        InformationCardTitle = (Get-AxisWizardArabicText -Name 'BiosSettingsInfoTitle')
        VisibleProcessorItems = @(
            (Get-AxisWizardArabicText -Name 'IntelRam')
            (Get-AxisWizardArabicText -Name 'IntelCStates')
            (Get-AxisWizardArabicText -Name 'IntelRebar')
            (Get-AxisWizardArabicText -Name 'IntelIgpu')
        )
        VisibleMotherboardUtility = (Get-AxisWizardArabicText -Name 'MsiUtility')
        ShowRequirements = $false
        DocumentationLabel = (Get-AxisWizardArabicText -Name 'Documentation')
        RequiresConfirmationAcknowledgement = $true
        DocumentationAcknowledgementText = (Get-AxisWizardArabicText -Name 'RestartAcknowledgement')
        ConfirmationActionLabel = (Get-AxisWizardArabicText -Name 'Restart')
        ConfirmationReturnLabel = (Get-AxisWizardArabicText -Name 'Return')
        SupportTitle = (Get-AxisWizardArabicText -Name 'SupportTitle')
        SupportBody = (Get-AxisWizardArabicText -Name 'SupportBody')
        CheckingStatusTitle = (Get-AxisWizardArabicText -Name 'Restarting')
        CompletedStatusTitle = (Get-AxisWizardArabicText -Name 'Completed')
        CustomerAction = 'Open'
        CustomerVisibleActions = @('Open')
        MockHardwareProfile = $mockHardwareProfile
        HardwareAwarePrototypeMarker = 'AxisFirstUseWizard.BiosSettingsHardwareAwarePrototype'
        VisibleMotherboardUtilityMarker = 'BiosSettingsVisibleMsiUtility'
    }

    $reinstallStep = [ordered]@{
        Id = 'reinstall'
        Title = (Get-AxisWizardArabicText -Name 'ReinstallTitle')
        StageName = 'Refresh'
        State = 'Ready'
        StateLabel = ''
        PrimaryActionLabel = (Get-AxisWizardArabicText -Name 'ReinstallPrimaryAction')
        RunningActionLabel = (Get-AxisWizardArabicText -Name 'ReinstallPrimaryAction')
        CompletionStateLabel = (Get-AxisWizardArabicText -Name 'ReinstallCompleted')
        CompletedStatusText = ''
        Description = (Get-AxisWizardArabicText -Name 'ReinstallSubtitle')
        InformationCardTitle = (Get-AxisWizardArabicText -Name 'ReinstallInfoTitle')
        InformationItems = @(
            (Get-AxisWizardArabicText -Name 'ReinstallInfoBullet')
        )
        ShowRequirements = $true
        RequirementsTitle = (Get-AxisWizardArabicText -Name 'RequirementsTitle')
        RequirementsItems = @(
            (Get-AxisWizardArabicText -Name 'ReinstallRequirementUsbSize')
            (Get-AxisWizardArabicText -Name 'ReinstallRequirementNoData')
        )
        DocumentationLabel = (Get-AxisWizardArabicText -Name 'Documentation')
        RequiresConfirmationAcknowledgement = $false
        SupportTitle = (Get-AxisWizardArabicText -Name 'SupportTitle')
        SupportBody = (Get-AxisWizardArabicText -Name 'SupportBody')
        CheckingStatusTitle = (Get-AxisWizardArabicText -Name 'ReinstallRunning')
        CompletedStatusTitle = (Get-AxisWizardArabicText -Name 'ReinstallCompleted')
        CustomerAction = 'CreateInstallationMedia'
        FutureInternalAction = 'Apply'
        CustomerVisibleActions = @((Get-AxisWizardArabicText -Name 'ReinstallPrimaryAction'))
        PrototypeOnlySimulation = $true
        NoConfirmationOverlay = $true
    }

    $autoUnattendStep = [ordered]@{
        Id = 'unattended'
        Title = 'AutoUnattend'
        StageName = 'Refresh'
        State = 'Ready'
        StateLabel = ''
        PrimaryActionLabel = (Get-AxisWizardArabicText -Name 'AutoUnattendPrimaryAction')
        RunningActionLabel = (Get-AxisWizardArabicText -Name 'AutoUnattendPrimaryAction')
        CompletionStateLabel = (Get-AxisWizardArabicText -Name 'AutoUnattendCompleted')
        CompletedStatusText = ''
        Description = (Get-AxisWizardArabicText -Name 'AutoUnattendSubtitle')
        InformationCardTitle = (Get-AxisWizardArabicText -Name 'AutoUnattendInfoTitle')
        InformationItems = @(
            (Get-AxisWizardArabicText -Name 'AutoUnattendInfoBulletOobe')
            (Get-AxisWizardArabicText -Name 'AutoUnattendInfoBulletSetup')
            (Get-AxisWizardArabicText -Name 'AutoUnattendInfoBulletUsb')
        )
        ShowRequirements = $true
        RequirementsTitle = (Get-AxisWizardArabicText -Name 'RequirementsTitle')
        RequirementsItems = @(
            (Get-AxisWizardArabicText -Name 'AutoUnattendRequirementAccount')
            (Get-AxisWizardArabicText -Name 'AutoUnattendRequirementUsb')
        )
        DocumentationLabel = (Get-AxisWizardArabicText -Name 'Documentation')
        RequiresConfirmationAcknowledgement = $false
        RequiresInputWindow = $true
        InputWindowTitle = (Get-AxisWizardArabicText -Name 'AutoUnattendInputTitle')
        InputAccountLabel = (Get-AxisWizardArabicText -Name 'AutoUnattendAccountLabel')
        InputUsbLabel = (Get-AxisWizardArabicText -Name 'AutoUnattendUsbLabel')
        InputCreateLabel = (Get-AxisWizardArabicText -Name 'AutoUnattendPrimaryAction')
        InputReturnLabel = (Get-AxisWizardArabicText -Name 'Return')
        MockUsbItems = @('USB')
        SupportTitle = (Get-AxisWizardArabicText -Name 'SupportTitle')
        SupportBody = (Get-AxisWizardArabicText -Name 'SupportBody')
        CheckingStatusTitle = (Get-AxisWizardArabicText -Name 'AutoUnattendRunning')
        CompletedStatusTitle = (Get-AxisWizardArabicText -Name 'AutoUnattendCompleted')
        CustomerAction = 'CreateAutoUnattendFile'
        FutureInternalAction = 'Apply'
        CustomerVisibleActions = @((Get-AxisWizardArabicText -Name 'AutoUnattendPrimaryAction'))
        PrototypeOnlySimulation = $true
        NoConfirmationOverlay = $true
        InputWindowPrototypeOnly = $true
    }

    $updatesDriversBlockStep = [ordered]@{
        Id = 'updates-drivers-block'
        Title = 'Updates Drivers Block'
        StageName = 'Refresh'
        State = 'Ready'
        StateLabel = ''
        PrimaryActionLabel = (Get-AxisWizardArabicText -Name 'UpdatesDriversPrimaryAction')
        RunningActionLabel = (Get-AxisWizardArabicText -Name 'UpdatesDriversPrimaryAction')
        CompletionStateLabel = (Get-AxisWizardArabicText -Name 'UpdatesDriversCompleted')
        CompletedStatusText = ''
        Description = (Get-AxisWizardArabicText -Name 'UpdatesDriversSubtitle')
        InformationCardTitle = (Get-AxisWizardArabicText -Name 'UpdatesDriversInfoTitle')
        InformationItems = @(
            (Get-AxisWizardArabicText -Name 'UpdatesDriversInfoBulletSetupcomplete')
            (Get-AxisWizardArabicText -Name 'UpdatesDriversInfoBulletWindowsUpdate')
        )
        ShowRequirements = $true
        RequirementsTitle = (Get-AxisWizardArabicText -Name 'RequirementsTitle')
        RequirementsItems = @(
            (Get-AxisWizardArabicText -Name 'UpdatesDriversRequirementUsb')
        )
        DocumentationLabel = (Get-AxisWizardArabicText -Name 'Documentation')
        RequiresConfirmationAcknowledgement = $false
        RequiresInputWindow = $true
        RequiresAccountName = $false
        InputWindowTitle = (Get-AxisWizardArabicText -Name 'UpdatesDriversInputTitle')
        InputUsbLabel = (Get-AxisWizardArabicText -Name 'UpdatesDriversUsbLabel')
        InputCreateLabel = (Get-AxisWizardArabicText -Name 'UpdatesDriversInputCreate')
        InputReturnLabel = (Get-AxisWizardArabicText -Name 'Return')
        InputOverlayTag = 'AxisFirstUseWizard.UpdatesDriversInputOverlay'
        InputWindowCardAutomationId = 'AxisFirstUseWizard.UpdatesDriversInputWindowNoCheckbox'
        InputWindowContentTag = 'AxisFirstUseWizard.UpdatesDriversInputWindowContent'
        InputTitleTag = 'AxisFirstUseWizard.UpdatesDriversInputTitle'
        InputTitleAnchorTag = 'AxisFirstUseWizard.UpdatesDriversInputTitleRightAnchor'
        InputUsbLabelTag = 'AxisFirstUseWizard.UpdatesDriversUsbLabel'
        InputUsbLabelAnchorTag = 'AxisFirstUseWizard.UpdatesDriversUsbLabelRightAnchor'
        InputUsbSelectorTag = 'AxisFirstUseWizard.UpdatesDriversUsbSelector'
        InputUsbSelectorAnchorTag = 'AxisFirstUseWizard.UpdatesDriversUsbSelectorRightAnchor'
        InputButtonAreaTag = 'AxisFirstUseWizard.UpdatesDriversInputButtonArea'
        InputCreateButtonTag = 'AxisFirstUseWizard.UpdatesDriversInputCreateButton'
        InputCreateDisabledAutomationId = 'AxisFirstUseWizard.UpdatesDriversInputCreateDisabledUntilValid'
        InputCreateEnabledAutomationId = 'AxisFirstUseWizard.UpdatesDriversInputCreateEnabledWithMockUsbSelection'
        InputReturnButtonTag = 'AxisFirstUseWizard.UpdatesDriversInputReturnButton'
        InputReturnAutomationId = 'AxisFirstUseWizard.UpdatesDriversInputReturnOnlyClosesOverlay'
        InputReturnSpacerTag = 'AxisFirstUseWizard.UpdatesDriversInputReturnButtonSpacer'
        MockUsbItems = @('USB')
        SupportTitle = (Get-AxisWizardArabicText -Name 'SupportTitle')
        SupportBody = (Get-AxisWizardArabicText -Name 'SupportBody')
        CheckingStatusTitle = (Get-AxisWizardArabicText -Name 'UpdatesDriversRunning')
        CompletedStatusTitle = (Get-AxisWizardArabicText -Name 'UpdatesDriversCompleted')
        CustomerAction = 'CreateUpdatesDriversBlockFile'
        FutureInternalAction = 'Apply'
        CustomerVisibleActions = @((Get-AxisWizardArabicText -Name 'UpdatesDriversPrimaryAction'))
        PrototypeOnlySimulation = $true
        NoConfirmationOverlay = $true
        InputWindowPrototypeOnly = $true
    }

    $toBiosStep = [ordered]@{
        Id = 'to-bios'
        Title = (Get-AxisWizardArabicText -Name 'ToBiosTitle')
        StageName = 'Refresh'
        State = 'Ready'
        StateLabel = ''
        PrimaryActionLabel = (Get-AxisWizardArabicText -Name 'ToBiosPrimaryAction')
        RunningActionLabel = (Get-AxisWizardArabicText -Name 'ToBiosPrimaryAction')
        CompletionStateLabel = (Get-AxisWizardArabicText -Name 'Completed')
        CompletedStatusText = ''
        Description = (Get-AxisWizardArabicText -Name 'ToBiosSubtitle')
        InformationCardTitle = (Get-AxisWizardArabicText -Name 'ToBiosInfoTitle')
        InformationItems = @(
            (Get-AxisWizardArabicText -Name 'ToBiosInfoBulletRestart')
            (Get-AxisWizardArabicText -Name 'ToBiosInfoBulletUsbBoot')
            (Get-AxisWizardArabicText -Name 'ToBiosInfoBulletInstall')
        )
        ShowRequirements = $false
        DocumentationLabel = (Get-AxisWizardArabicText -Name 'Documentation')
        RequiresConfirmationAcknowledgement = $true
        DocumentationAcknowledgementText = (Get-AxisWizardArabicText -Name 'Acknowledgement')
        ConfirmationActionLabel = (Get-AxisWizardArabicText -Name 'Restart')
        ConfirmationReturnLabel = (Get-AxisWizardArabicText -Name 'Return')
        SupportTitle = (Get-AxisWizardArabicText -Name 'SupportTitle')
        SupportBody = (Get-AxisWizardArabicText -Name 'SupportBody')
        CheckingStatusTitle = (Get-AxisWizardArabicText -Name 'Restarting')
        CompletedStatusTitle = (Get-AxisWizardArabicText -Name 'Completed')
        CustomerAction = 'Open'
        FutureInternalAction = 'Open'
        CustomerVisibleActions = @((Get-AxisWizardArabicText -Name 'ToBiosPrimaryAction'))
        PrototypeOnlySimulation = $true
    }

    $bitLockerStep = New-AxisSetupWizardStepState `
        -Id 'bitlocker' `
        -Title 'BitLocker' `
        -Description (Get-AxisWizardSetupText -Name 'BitLockerSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardSetupText -Name 'BitLockerPrimaryAction') `
        -InformationCardTitle (Get-AxisWizardSetupText -Name 'BitLockerInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardSetupText -Name 'BitLockerInfoBullet1')
            (Get-AxisWizardSetupText -Name 'BitLockerInfoBullet2')
            (Get-AxisWizardSetupText -Name 'BitLockerInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardSetupText -Name 'BitLockerRunning') `
        -CompletedStatusTitle (Get-AxisWizardSetupText -Name 'BitLockerCompleted') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'SetupBitLocker' `
        -PrimaryActionWidth 190.0

    $convertHomeToProStep = New-AxisSetupWizardStepState `
        -Id 'convert-home-to-pro' `
        -Title 'Convert Home to Pro' `
        -Description (Get-AxisWizardSetupText -Name 'ConvertHomeToProSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardSetupText -Name 'ConvertHomeToProPrimaryAction') `
        -InformationCardTitle (Get-AxisWizardSetupText -Name 'ConvertHomeToProInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardSetupText -Name 'ConvertHomeToProInfoBullet1')
            (Get-AxisWizardSetupText -Name 'ConvertHomeToProInfoBullet2')
            (Get-AxisWizardSetupText -Name 'ConvertHomeToProInfoBullet3')
        ) `
        -RequirementsTitle (Get-AxisWizardSetupText -Name 'ConvertHomeToProRequirementsTitle') `
        -RequirementsItems @(
            (Get-AxisWizardSetupText -Name 'ConvertHomeToProRequirement1')
            (Get-AxisWizardSetupText -Name 'ConvertHomeToProRequirement2')
        ) `
        -CheckingStatusTitle (Get-AxisWizardSetupText -Name 'ConvertHomeToProRunning') `
        -CompletedStatusTitle (Get-AxisWizardSetupText -Name 'ConvertHomeToProCompleted') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'SetupConvertHomeToPro' `
        -PrimaryActionWidth 238.0 `
        -RuntimeStatusWidth 252.0 `
        -RuntimeStatusContentWidth 228.0 `
        -RuntimeStatusTextMaxWidth 126.0

    $memoryCompressionStep = New-AxisSetupWizardStepState `
        -Id 'memory-compression' `
        -Title 'Memory Compression' `
        -Description (Get-AxisWizardSetupText -Name 'MemoryCompressionSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardSetupText -Name 'MemoryCompressionPrimaryAction') `
        -InformationCardTitle (Get-AxisWizardSetupText -Name 'MemoryCompressionInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardSetupText -Name 'MemoryCompressionInfoBullet1')
            (Get-AxisWizardSetupText -Name 'MemoryCompressionInfoBullet2')
            (Get-AxisWizardSetupText -Name 'MemoryCompressionInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardSetupText -Name 'MemoryCompressionRunning') `
        -CompletedStatusTitle (Get-AxisWizardSetupText -Name 'MemoryCompressionCompleted') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'SetupMemoryCompression' `
        -PrimaryActionWidth 260.0

    $dateLanguageRegionTimeStep = New-AxisSetupWizardStepState `
        -Id 'date-language-region-time' `
        -Title (Get-AxisWizardSetupText -Name 'DateLanguageRegionTimeTitle') `
        -Description (Get-AxisWizardSetupText -Name 'DateLanguageRegionTimeSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardSetupText -Name 'DateLanguageRegionTimePrimaryAction') `
        -InformationCardTitle (Get-AxisWizardSetupText -Name 'DateLanguageRegionTimeInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardSetupText -Name 'DateLanguageRegionTimeInfoBullet1')
            (Get-AxisWizardSetupText -Name 'DateLanguageRegionTimeInfoBullet2')
            (Get-AxisWizardSetupText -Name 'DateLanguageRegionTimeInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardSetupText -Name 'DateLanguageRegionTimeRunning') `
        -CompletedStatusTitle (Get-AxisWizardSetupText -Name 'DateLanguageRegionTimeCompleted') `
        -CustomerAction 'Open' `
        -FutureInternalAction 'Open' `
        -TagRoot 'SetupDateLanguageRegionTime' `
        -OpenMappedPrototypeOnly $true

    $startupAppsSettingsStep = New-AxisSetupWizardStepState `
        -Id 'startup-apps-settings' `
        -Title 'Startup Apps Settings' `
        -Description (Get-AxisWizardSetupText -Name 'StartupAppsSettingsSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardSetupText -Name 'StartupAppsSettingsPrimaryAction') `
        -InformationCardTitle (Get-AxisWizardSetupText -Name 'StartupAppsSettingsInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardSetupText -Name 'StartupAppsSettingsInfoBullet1')
            (Get-AxisWizardSetupText -Name 'StartupAppsSettingsInfoBullet2')
            (Get-AxisWizardSetupText -Name 'StartupAppsSettingsInfoBullet3')
        ) `
        -RequirementsTitle (Get-AxisWizardSetupText -Name 'StartupAppsSettingsRequirementsTitle') `
        -RequirementsItems @(
            (Get-AxisWizardSetupText -Name 'StartupAppsSettingsRequirement1')
            (Get-AxisWizardSetupText -Name 'StartupAppsSettingsRequirement2')
        ) `
        -CheckingStatusTitle (Get-AxisWizardSetupText -Name 'StartupAppsSettingsRunning') `
        -CompletedStatusTitle (Get-AxisWizardSetupText -Name 'StartupAppsSettingsCompleted') `
        -CustomerAction 'Open' `
        -FutureInternalAction 'Open' `
        -TagRoot 'SetupStartupAppsSettings' `
        -OpenMappedPrototypeOnly $true

    $startupAppsTaskManagerStep = New-AxisSetupWizardStepState `
        -Id 'startup-apps-task-manager' `
        -Title 'Startup Apps Task Manager' `
        -Description (Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerPrimaryAction') `
        -InformationCardTitle (Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerInfoBullet1')
            (Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerInfoBullet2')
            (Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerInfoBullet3')
        ) `
        -RequirementsTitle (Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerRequirementsTitle') `
        -RequirementsItems @(
            (Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerRequirement1')
            (Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerRequirement2')
        ) `
        -CheckingStatusTitle (Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerRunning') `
        -CompletedStatusTitle (Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerCompleted') `
        -CustomerAction 'Open' `
        -FutureInternalAction 'Open' `
        -TagRoot 'SetupStartupAppsTaskManager' `
        -OpenMappedPrototypeOnly $true

    $backgroundAppsStep = New-AxisSetupWizardStepState `
        -Id 'background-apps' `
        -Title 'Background Apps' `
        -Description (Get-AxisWizardSetupText -Name 'BackgroundAppsSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardSetupText -Name 'BackgroundAppsPrimaryAction') `
        -InformationCardTitle (Get-AxisWizardSetupText -Name 'BackgroundAppsInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardSetupText -Name 'BackgroundAppsInfoBullet1')
            (Get-AxisWizardSetupText -Name 'BackgroundAppsInfoBullet2')
            (Get-AxisWizardSetupText -Name 'BackgroundAppsInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardSetupText -Name 'BackgroundAppsRunning') `
        -CompletedStatusTitle (Get-AxisWizardSetupText -Name 'BackgroundAppsCompleted') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'SetupBackgroundApps' `
        -PrimaryActionWidth 220.0

    $edgeSettingsStep = New-AxisSetupWizardStepState `
        -Id 'edge-settings' `
        -Title 'Microsoft Edge Settings' `
        -Description (Get-AxisWizardSetupText -Name 'EdgeSettingsSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardSetupText -Name 'EdgeSettingsPrimaryAction') `
        -InformationCardTitle (Get-AxisWizardSetupText -Name 'EdgeSettingsInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardSetupText -Name 'EdgeSettingsInfoBullet1')
            (Get-AxisWizardSetupText -Name 'EdgeSettingsInfoBullet2')
            (Get-AxisWizardSetupText -Name 'EdgeSettingsInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardSetupText -Name 'EdgeSettingsRunning') `
        -CompletedStatusTitle (Get-AxisWizardSetupText -Name 'EdgeSettingsCompleted') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'SetupEdgeSettings' `
        -PrimaryActionWidth 238.0

    $storeSettingsStep = New-AxisSetupWizardStepState `
        -Id 'store-settings' `
        -Title 'Microsoft Store Settings' `
        -Description (Get-AxisWizardSetupText -Name 'StoreSettingsSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardSetupText -Name 'StoreSettingsPrimaryAction') `
        -InformationCardTitle (Get-AxisWizardSetupText -Name 'StoreSettingsInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardSetupText -Name 'StoreSettingsInfoBullet1')
            (Get-AxisWizardSetupText -Name 'StoreSettingsInfoBullet2')
            (Get-AxisWizardSetupText -Name 'StoreSettingsInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardSetupText -Name 'StoreSettingsRunning') `
        -CompletedStatusTitle (Get-AxisWizardSetupText -Name 'StoreSettingsCompleted') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'SetupStoreSettings' `
        -PrimaryActionWidth 238.0

    $updatesPauseStep = New-AxisSetupWizardStepState `
        -Id 'updates-pause' `
        -Title 'Pause Windows Updates' `
        -Description (Get-AxisWizardSetupText -Name 'UpdatesPauseSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardSetupText -Name 'UpdatesPausePrimaryAction') `
        -InformationCardTitle (Get-AxisWizardSetupText -Name 'UpdatesPauseInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardSetupText -Name 'UpdatesPauseInfoBullet1')
            (Get-AxisWizardSetupText -Name 'UpdatesPauseInfoBullet2')
            (Get-AxisWizardSetupText -Name 'UpdatesPauseInfoBullet3')
        ) `
        -RequirementsTitle (Get-AxisWizardSetupText -Name 'UpdatesPauseRequirementsTitle') `
        -RequirementsItems @(
            (Get-AxisWizardSetupText -Name 'UpdatesPauseRequirement1')
        ) `
        -CheckingStatusTitle (Get-AxisWizardSetupText -Name 'UpdatesPauseRunning') `
        -CompletedStatusTitle (Get-AxisWizardSetupText -Name 'UpdatesPauseCompleted') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'SetupUpdatesPause' `
        -RequiresConfirmationAcknowledgement $true `
        -DocumentationAcknowledgementText (Get-AxisWizardSetupText -Name 'UpdatesPauseConfirmationCheckbox') `
        -ConfirmationActionLabel (Get-AxisWizardSetupText -Name 'UpdatesPauseConfirmationPrimary') `
        -ConfirmationReturnLabel (Get-AxisWizardSetupText -Name 'UpdatesPauseConfirmationReturn') `
        -PrimaryActionWidth 210.0 `
        -ConfirmationActionWidth 148.0

    $installersStep = [ordered]@{
        Id = 'installers'
        Title = (Get-AxisWizardArabicText -Name 'InstallersTitle')
        StageName = 'Installers'
        State = 'Ready'
        StateLabel = ''
        PrimaryActionLabel = 'Install'
        RunningActionLabel = 'Install'
        CompletionStateLabel = (Get-AxisWizardArabicText -Name 'InstallersCompleted')
        CompletedStatusText = ''
        Description = (Get-AxisWizardArabicText -Name 'InstallersSubtitle')
        InformationCardTitle = (Get-AxisWizardArabicText -Name 'InstallersInfoTitle')
        InformationItems = @(
            (Get-AxisWizardArabicText -Name 'InstallersInfoBullet1')
            (Get-AxisWizardArabicText -Name 'InstallersInfoBullet2')
            (Get-AxisWizardArabicText -Name 'InstallersInfoBullet3')
        )
        ShowRequirements = $true
        RequirementsTitle = (Get-AxisWizardArabicText -Name 'RequirementsTitle')
        RequirementsItems = @(
            (Get-AxisWizardArabicText -Name 'InstallersRequirementsBullet1')
            (Get-AxisWizardArabicText -Name 'InstallersRequirementsBullet2')
        )
        DocumentationLabel = (Get-AxisWizardArabicText -Name 'Documentation')
        RequiresConfirmationAcknowledgement = $false
        NoConfirmationOverlay = $true
        RequiresInputWindow = $false
        SupportTitle = (Get-AxisWizardArabicText -Name 'SupportTitle')
        SupportBody = (Get-AxisWizardArabicText -Name 'SupportBody')
        CheckingStatusTitle = (Get-AxisWizardArabicText -Name 'InstallersRunning')
        CompletedStatusTitle = (Get-AxisWizardArabicText -Name 'InstallersCompleted')
        CustomerAction = 'Apply'
        FutureInternalAction = 'Apply'
        CustomerVisibleActions = @('Install')
        PrototypeOnlySimulation = $true
        NoRealActionMarker = 'AxisFirstUseWizard.InstallersPrototypeOnlyNoRuntimeAction'
        TagRoot = 'Installers'
        PrimaryActionWidth = 112.0
        PrimaryActionRequiresSelection = $true
        RuntimeStatusWidth = 234.0
        RuntimeStatusContentWidth = 214.0
        RuntimeStatusTextMaxWidth = 110.0
        InstallerCatalogNames = @(Get-AxisFirstUseWizardInstallersCatalogNames)
        InstallerSelectorLabel = (Get-AxisWizardArabicText -Name 'InstallersSelectorLabel')
        InstallerSelectorPlaceholder = (Get-AxisWizardArabicText -Name 'InstallersSelectorPlaceholder')
        InstallerSelectedProgramPrefix = (Get-AxisWizardArabicText -Name 'InstallersSelectedProgramPrefix')
        InstallerEpicCatalogDisplayName = 'Epic Games'
        InstallerEpicInstructionOverlayTitle = (Get-AxisWizardArabicText -Name 'InstallersEpicOverlayTitle')
        InstallerEpicInstructionOverlayItems = @(
            (Get-AxisWizardArabicText -Name 'InstallersEpicOverlayBody1')
            (Get-AxisWizardArabicText -Name 'InstallersEpicOverlayBody2')
            (Get-AxisWizardArabicText -Name 'InstallersEpicOverlayBody3')
        )
        InstallerEpicInstructionOverlayReturnLabel = (Get-AxisWizardArabicText -Name 'InstallersEpicOverlayReturn')
        InstallerEpicInstructionOverlayMarker = 'AxisFirstUseWizard.InstallersEpicInstructionOverlayPrototypeOnly'
        InstallersStagePrototypeMarker = 'AxisFirstUseWizard.InstallersStagePrototypeOnly'
    }

    $installersStartupAppsSettingsStep = New-AxisSetupWizardStepState `
        -Id 'installers-startup-apps-settings' `
        -Title 'Startup Apps Settings' `
        -Description (Get-AxisWizardSetupText -Name 'StartupAppsSettingsSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardSetupText -Name 'StartupAppsSettingsPrimaryAction') `
        -InformationCardTitle (Get-AxisWizardSetupText -Name 'StartupAppsSettingsInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardSetupText -Name 'StartupAppsSettingsInfoBullet1')
            (Get-AxisWizardSetupText -Name 'StartupAppsSettingsInfoBullet2')
            (Get-AxisWizardSetupText -Name 'StartupAppsSettingsInfoBullet3')
        ) `
        -RequirementsTitle (Get-AxisWizardSetupText -Name 'StartupAppsSettingsRequirementsTitle') `
        -RequirementsItems @(
            (Get-AxisWizardSetupText -Name 'StartupAppsSettingsRequirement1')
            (Get-AxisWizardSetupText -Name 'StartupAppsSettingsRequirement2')
        ) `
        -CheckingStatusTitle (Get-AxisWizardSetupText -Name 'StartupAppsSettingsRunning') `
        -CompletedStatusTitle (Get-AxisWizardSetupText -Name 'StartupAppsSettingsCompleted') `
        -CustomerAction 'Open' `
        -FutureInternalAction 'Open' `
        -TagRoot 'InstallersStartupAppsSettings' `
        -OpenMappedPrototypeOnly $true `
        -StageName 'Installers' `
        -StageBatchMarker 'AxisFirstUseWizard.InstallersStageExtensionPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.InstallersStartupAppsSettingsPrototypeOnlyNoRuntimeAction'

    $installersStartupAppsTaskManagerStep = New-AxisSetupWizardStepState `
        -Id 'installers-startup-apps-task-manager' `
        -Title 'Startup Apps Task Manager' `
        -Description (Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerPrimaryAction') `
        -InformationCardTitle (Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerInfoBullet1')
            (Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerInfoBullet2')
            (Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerInfoBullet3')
        ) `
        -RequirementsTitle (Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerRequirementsTitle') `
        -RequirementsItems @(
            (Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerRequirement1')
            (Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerRequirement2')
        ) `
        -CheckingStatusTitle (Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerRunning') `
        -CompletedStatusTitle (Get-AxisWizardSetupText -Name 'StartupAppsTaskManagerCompleted') `
        -CustomerAction 'Open' `
        -FutureInternalAction 'Open' `
        -TagRoot 'InstallersStartupAppsTaskManager' `
        -OpenMappedPrototypeOnly $true `
        -StageName 'Installers' `
        -StageBatchMarker 'AxisFirstUseWizard.InstallersStageExtensionPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.InstallersStartupAppsTaskManagerPrototypeOnlyNoRuntimeAction'

    $restartAfterInstallersStep = New-AxisSetupWizardStepState `
        -Id 'restart-after-installers' `
        -Title (Get-AxisWizardArabicText -Name 'RestartAfterInstallersTitle') `
        -Description (Get-AxisWizardArabicText -Name 'RestartAfterInstallersSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardArabicText -Name 'Restart') `
        -InformationCardTitle (Get-AxisWizardArabicText -Name 'RestartAfterInstallersTitle') `
        -InformationItems @(
            (Get-AxisWizardArabicText -Name 'RestartAfterInstallersInfoBullet1')
            (Get-AxisWizardArabicText -Name 'RestartAfterInstallersInfoBullet2')
            (Get-AxisWizardArabicText -Name 'RestartAfterInstallersInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardArabicText -Name 'Restarting') `
        -CompletedStatusTitle (Get-AxisWizardArabicText -Name 'Completed') `
        -CustomerAction 'Restart' `
        -FutureInternalAction 'Restart' `
        -TagRoot 'RestartAfterInstallers' `
        -StageName 'Installers' `
        -StageBatchMarker 'AxisFirstUseWizard.InstallersStageExtensionPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.RestartAfterInstallersPrototypeOnlyNoRuntimeAction' `
        -PrimaryActionWidth 166.0 `
        -RuntimeStatusWidth 252.0 `
        -RuntimeStatusContentWidth 228.0 `
        -RuntimeStatusTextMaxWidth 126.0

    $restartAfterInstallersStep['AxisCustomStepOrigin'] = 'AXIS custom future restart step'
    $restartAfterInstallersStep['NoExistingBoostLabTool'] = $true

    $driverCleanStep = New-AxisSetupWizardStepState `
        -Id 'driver-clean' `
        -Title (Get-AxisWizardGraphicsText -Name 'DriverCleanTitle') `
        -Description (Get-AxisWizardGraphicsText -Name 'DriverCleanSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardGraphicsText -Name 'DriverCleanPrimary') `
        -InformationCardTitle (Get-AxisWizardGraphicsText -Name 'DriverCleanInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardGraphicsText -Name 'DriverCleanInfoBullet1')
            (Get-AxisWizardGraphicsText -Name 'DriverCleanInfoBullet2')
            (Get-AxisWizardGraphicsText -Name 'DriverCleanInfoBullet3')
        ) `
        -RequirementsTitle (Get-AxisWizardArabicText -Name 'RequirementsTitle') `
        -RequirementsItems @(
            (Get-AxisWizardGraphicsText -Name 'DriverCleanRequirement1')
            (Get-AxisWizardGraphicsText -Name 'DriverCleanRequirement2')
            (Get-AxisWizardGraphicsText -Name 'DriverCleanRequirement3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardGraphicsText -Name 'DriverCleanRunning') `
        -CompletedStatusTitle (Get-AxisWizardArabicText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'GraphicsDriverClean' `
        -RequiresConfirmationAcknowledgement $true `
        -DocumentationAcknowledgementText (Get-AxisWizardArabicText -Name 'Acknowledgement') `
        -ConfirmationActionLabel (Get-AxisWizardGraphicsText -Name 'DriverCleanPrimary') `
        -ConfirmationReturnLabel (Get-AxisWizardArabicText -Name 'Return') `
        -PrimaryActionWidth 170.0 `
        -ConfirmationActionWidth 170.0 `
        -StageName 'Graphics' `
        -StageBatchMarker 'AxisFirstUseWizard.GraphicsStageBatchPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.DriverCleanPrototypeOnlyNoRuntimeAction'

    $gpuDriverSetupStep = New-AxisSetupWizardStepState `
        -Id 'driver-install-debloat-settings' `
        -Title 'GPU Driver Setup' `
        -Description (Get-AxisWizardGraphicsText -Name 'GpuSetupSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardGraphicsText -Name 'GpuSetupPrimary') `
        -InformationCardTitle (Get-AxisWizardGraphicsText -Name 'GpuSetupInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardGraphicsText -Name 'GpuSetupInfoBullet1')
            (Get-AxisWizardGraphicsText -Name 'GpuSetupInfoBullet2')
            (Get-AxisWizardGraphicsText -Name 'GpuSetupInfoBullet3')
        ) `
        -RequirementsTitle (Get-AxisWizardArabicText -Name 'RequirementsTitle') `
        -RequirementsItems @(
            (Get-AxisWizardGraphicsText -Name 'GpuSetupRequirement1')
            (Get-AxisWizardGraphicsText -Name 'GpuSetupRequirement2')
            (Get-AxisWizardGraphicsText -Name 'GpuSetupRequirement3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardGraphicsText -Name 'GpuSetupRunning') `
        -CompletedStatusTitle (Get-AxisWizardArabicText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'GraphicsGpuDriverSetup' `
        -RequiresConfirmationAcknowledgement $true `
        -DocumentationAcknowledgementText (Get-AxisWizardArabicText -Name 'Acknowledgement') `
        -ConfirmationActionLabel (Get-AxisWizardGraphicsText -Name 'GpuSetupPrimary') `
        -ConfirmationReturnLabel (Get-AxisWizardArabicText -Name 'Return') `
        -PrimaryActionWidth 190.0 `
        -ConfirmationActionWidth 190.0 `
        -StageName 'Graphics' `
        -StageBatchMarker 'AxisFirstUseWizard.GraphicsStageBatchPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.GpuDriverSetupPrototypeOnlyNoRuntimeAction' `
        -RequiresGpuSelector $true `
        -GpuSelectorLabel (Get-AxisWizardGraphicsText -Name 'GpuSetupSelectorLabel') `
        -GpuSelectorOptions @(
            'NVIDIA'
            (Get-AxisWizardGraphicsText -Name 'GpuSetupAmdLater')
            (Get-AxisWizardGraphicsText -Name 'GpuSetupIntelLater')
        ) `
        -GpuSelectorEnabledOptions @('NVIDIA')

    $nvidiaAppInstallStep = New-AxisSetupWizardStepState `
        -Id 'nvidia-app-install' `
        -Title 'NVIDIA App Install' `
        -Description (Get-AxisWizardGraphicsText -Name 'NvidiaAppSubtitle') `
        -PrimaryActionLabel 'Install NVIDIA App' `
        -InformationCardTitle (Get-AxisWizardGraphicsText -Name 'NvidiaAppInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardGraphicsText -Name 'NvidiaAppInfoBullet1')
            (Get-AxisWizardGraphicsText -Name 'NvidiaAppInfoBullet2')
            (Get-AxisWizardGraphicsText -Name 'NvidiaAppInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardGraphicsText -Name 'NvidiaAppRunning') `
        -CompletedStatusTitle (Get-AxisWizardGraphicsText -Name 'NvidiaAppCompleted') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'GraphicsNvidiaAppInstall' `
        -RequiresConfirmationAcknowledgement $true `
        -DocumentationAcknowledgementText (Get-AxisWizardArabicText -Name 'Acknowledgement') `
        -ConfirmationActionLabel 'Install NVIDIA App' `
        -ConfirmationReturnLabel (Get-AxisWizardArabicText -Name 'Return') `
        -PrimaryActionWidth 176.0 `
        -ConfirmationActionWidth 176.0 `
        -StageName 'Graphics' `
        -StageBatchMarker 'AxisFirstUseWizard.GraphicsStageBatchPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.NvidiaAppInstallPrototypeOnlyNoRuntimeAction' `
        -OptionalContinuationLabel (Get-AxisWizardGraphicsText -Name 'NvidiaAppOptionalContinuation')

    $directXStep = New-AxisSetupWizardStepState `
        -Id 'directx' `
        -Title 'DirectX' `
        -Description (Get-AxisWizardGraphicsText -Name 'DirectXSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardGraphicsText -Name 'DirectXPrimary') `
        -InformationCardTitle (Get-AxisWizardGraphicsText -Name 'DirectXInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardGraphicsText -Name 'DirectXInfoBullet1')
            (Get-AxisWizardGraphicsText -Name 'DirectXInfoBullet2')
            (Get-AxisWizardGraphicsText -Name 'DirectXInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardGraphicsText -Name 'DirectXRunning') `
        -CompletedStatusTitle (Get-AxisWizardArabicText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'GraphicsDirectX' `
        -PrimaryActionWidth 150.0 `
        -RuntimeStatusWidth 252.0 `
        -RuntimeStatusContentWidth 228.0 `
        -RuntimeStatusTextMaxWidth 126.0 `
        -StageName 'Graphics' `
        -StageBatchMarker 'AxisFirstUseWizard.GraphicsStageBatchPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.DirectXPrototypeOnlyNoRuntimeAction'

    $visualCppStep = New-AxisSetupWizardStepState `
        -Id 'visual-cpp' `
        -Title 'Visual C++ Runtimes' `
        -Description (Get-AxisWizardGraphicsText -Name 'VisualCppSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardGraphicsText -Name 'VisualCppPrimary') `
        -InformationCardTitle (Get-AxisWizardGraphicsText -Name 'VisualCppInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardGraphicsText -Name 'VisualCppInfoBullet1')
            (Get-AxisWizardGraphicsText -Name 'VisualCppInfoBullet2')
            (Get-AxisWizardGraphicsText -Name 'VisualCppInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardGraphicsText -Name 'DirectXRunning') `
        -CompletedStatusTitle (Get-AxisWizardArabicText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'GraphicsVisualCpp' `
        -PrimaryActionWidth 220.0 `
        -RuntimeStatusWidth 252.0 `
        -RuntimeStatusContentWidth 228.0 `
        -RuntimeStatusTextMaxWidth 126.0 `
        -StageName 'Graphics' `
        -StageBatchMarker 'AxisFirstUseWizard.GraphicsStageBatchPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.VisualCppPrototypeOnlyNoRuntimeAction'

    $graphicsConfigurationCenterStep = New-AxisSetupWizardStepState `
        -Id 'graphics-configuration-center' `
        -Title 'Graphics Configuration Center' `
        -Description (Get-AxisWizardGraphicsText -Name 'GraphicsConfigSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardGraphicsText -Name 'GraphicsConfigPrimary') `
        -InformationCardTitle (Get-AxisWizardGraphicsText -Name 'GraphicsConfigInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardGraphicsText -Name 'GraphicsConfigInfoBullet1')
            (Get-AxisWizardGraphicsText -Name 'GraphicsConfigInfoBullet2')
            (Get-AxisWizardGraphicsText -Name 'GraphicsConfigInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardGraphicsText -Name 'GraphicsConfigPrimary') `
        -CompletedStatusTitle (Get-AxisWizardArabicText -Name 'Completed') `
        -CustomerAction 'Open' `
        -FutureInternalAction 'Open' `
        -TagRoot 'GraphicsConfigurationCenter' `
        -OpenMappedPrototypeOnly $true `
        -PrimaryActionWidth 190.0 `
        -RuntimeStatusWidth 286.0 `
        -RuntimeStatusContentWidth 260.0 `
        -RuntimeStatusTextMaxWidth 158.0 `
        -StageName 'Graphics' `
        -StageBatchMarker 'AxisFirstUseWizard.GraphicsStageBatchPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.GraphicsConfigurationCenterPrototypeOnlyNoRuntimeAction'

    $startMenuTaskbarStep = New-AxisSetupWizardStepState `
        -Id 'start-menu-taskbar' `
        -Title 'Start Menu Taskbar' `
        -Description (Get-AxisWizardWindowsText -Name 'StartMenuTaskbarSubtitle') `
        -PrimaryActionLabel 'Tweaks Start Menu Taskbar' `
        -InformationCardTitle (Get-AxisWizardWindowsText -Name 'StartMenuTaskbarInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardWindowsText -Name 'StartMenuTaskbarInfoBullet1')
            (Get-AxisWizardWindowsText -Name 'StartMenuTaskbarInfoBullet2')
            (Get-AxisWizardWindowsText -Name 'StartMenuTaskbarInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardWindowsText -Name 'Running') `
        -CompletedStatusTitle (Get-AxisWizardWindowsText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'WindowsStartMenuTaskbar' `
        -PrimaryActionWidth 222.0 `
        -StageName 'Windows' `
        -StageBatchMarker 'AxisFirstUseWizard.WindowsStagePartAPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.WindowsStartMenuTaskbarPrototypeOnlyNoRuntimeAction'

    $startMenuLayoutStep = New-AxisSetupWizardStepState `
        -Id 'start-menu-layout' `
        -Title 'Start Menu Layout' `
        -Description (Get-AxisWizardWindowsText -Name 'StartMenuLayoutSubtitle') `
        -PrimaryActionLabel 'Tweaks Start Menu Layout' `
        -InformationCardTitle (Get-AxisWizardWindowsText -Name 'StartMenuLayoutInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardWindowsText -Name 'StartMenuLayoutInfoBullet1')
            (Get-AxisWizardWindowsText -Name 'StartMenuLayoutInfoBullet2')
            (Get-AxisWizardWindowsText -Name 'StartMenuLayoutInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardWindowsText -Name 'Running') `
        -CompletedStatusTitle (Get-AxisWizardWindowsText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'WindowsStartMenuLayout' `
        -PrimaryActionWidth 210.0 `
        -StageName 'Windows' `
        -StageBatchMarker 'AxisFirstUseWizard.WindowsStagePartAPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.WindowsStartMenuLayoutPrototypeOnlyNoRuntimeAction'

    $contextMenuStep = New-AxisSetupWizardStepState `
        -Id 'context-menu' `
        -Title 'Context Menu' `
        -Description (Get-AxisWizardWindowsText -Name 'ContextMenuSubtitle') `
        -PrimaryActionLabel 'Tweaks Context Menu' `
        -InformationCardTitle (Get-AxisWizardWindowsText -Name 'ContextMenuInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardWindowsText -Name 'ContextMenuInfoBullet1')
            (Get-AxisWizardWindowsText -Name 'ContextMenuInfoBullet2')
            (Get-AxisWizardWindowsText -Name 'ContextMenuInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardWindowsText -Name 'Running') `
        -CompletedStatusTitle (Get-AxisWizardWindowsText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'WindowsContextMenu' `
        -PrimaryActionWidth 184.0 `
        -StageName 'Windows' `
        -StageBatchMarker 'AxisFirstUseWizard.WindowsStagePartAPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.WindowsContextMenuPrototypeOnlyNoRuntimeAction'

    $themeBlackStep = New-AxisSetupWizardStepState `
        -Id 'theme-black' `
        -Title 'Theme Black' `
        -Description (Get-AxisWizardWindowsText -Name 'ThemeBlackSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardWindowsText -Name 'ThemeBlackPrimary') `
        -InformationCardTitle (Get-AxisWizardWindowsText -Name 'ThemeBlackInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardWindowsText -Name 'ThemeBlackInfoBullet1')
            (Get-AxisWizardWindowsText -Name 'ThemeBlackInfoBullet2')
        ) `
        -CheckingStatusTitle (Get-AxisWizardWindowsText -Name 'Running') `
        -CompletedStatusTitle (Get-AxisWizardWindowsText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'WindowsThemeBlack' `
        -PrimaryActionWidth 164.0 `
        -StageName 'Windows' `
        -StageBatchMarker 'AxisFirstUseWizard.WindowsStagePartAPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.WindowsThemeBlackPrototypeOnlyNoRuntimeAction'

    $blackLockScreenWallpaperStep = New-AxisSetupWizardStepState `
        -Id 'signout-lockscreen-wallpaper-black' `
        -Title 'Black Lock Screen Wallpaper' `
        -Description (Get-AxisWizardWindowsText -Name 'BlackLockScreenWallpaperSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardWindowsText -Name 'BlackLockScreenWallpaperPrimary') `
        -InformationCardTitle (Get-AxisWizardWindowsText -Name 'BlackLockScreenWallpaperInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardWindowsText -Name 'BlackLockScreenWallpaperInfoBullet1')
            (Get-AxisWizardWindowsText -Name 'BlackLockScreenWallpaperInfoBullet2')
        ) `
        -CheckingStatusTitle (Get-AxisWizardWindowsText -Name 'Running') `
        -CompletedStatusTitle (Get-AxisWizardWindowsText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'WindowsBlackLockScreenWallpaper' `
        -PrimaryActionWidth 186.0 `
        -StageName 'Windows' `
        -StageBatchMarker 'AxisFirstUseWizard.WindowsStagePartAPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.WindowsBlackLockScreenWallpaperPrototypeOnlyNoRuntimeAction'

    $blackAccountPicturesStep = New-AxisSetupWizardStepState `
        -Id 'user-account-pictures-black' `
        -Title 'Black Account Pictures' `
        -Description (Get-AxisWizardWindowsText -Name 'BlackAccountPicturesSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardWindowsText -Name 'BlackAccountPicturesPrimary') `
        -InformationCardTitle (Get-AxisWizardWindowsText -Name 'BlackAccountPicturesInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardWindowsText -Name 'BlackAccountPicturesInfoBullet1')
            (Get-AxisWizardWindowsText -Name 'BlackAccountPicturesInfoBullet2')
        ) `
        -CheckingStatusTitle (Get-AxisWizardWindowsText -Name 'Running') `
        -CompletedStatusTitle (Get-AxisWizardWindowsText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'WindowsBlackAccountPictures' `
        -PrimaryActionWidth 190.0 `
        -StageName 'Windows' `
        -StageBatchMarker 'AxisFirstUseWizard.WindowsStagePartAPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.WindowsBlackAccountPicturesPrototypeOnlyNoRuntimeAction'

    $widgetsStep = New-AxisSetupWizardStepState `
        -Id 'widgets' `
        -Title 'Widgets' `
        -Description (Get-AxisWizardWindowsText -Name 'WidgetsSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardWindowsText -Name 'WidgetsPrimary') `
        -InformationCardTitle (Get-AxisWizardWindowsText -Name 'WidgetsInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardWindowsText -Name 'WidgetsInfoBullet1')
            (Get-AxisWizardWindowsText -Name 'WidgetsInfoBullet2')
            (Get-AxisWizardWindowsText -Name 'WidgetsInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardWindowsText -Name 'Running') `
        -CompletedStatusTitle (Get-AxisWizardWindowsText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'WindowsWidgets' `
        -PrimaryActionWidth 142.0 `
        -StageName 'Windows' `
        -StageBatchMarker 'AxisFirstUseWizard.WindowsStagePartAPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.WindowsWidgetsPrototypeOnlyNoRuntimeAction'

    $copilotStep = New-AxisSetupWizardStepState `
        -Id 'copilot' `
        -Title 'Copilot' `
        -Description (Get-AxisWizardWindowsText -Name 'CopilotSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardWindowsText -Name 'CopilotPrimary') `
        -InformationCardTitle (Get-AxisWizardWindowsText -Name 'CopilotInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardWindowsText -Name 'CopilotInfoBullet1')
            (Get-AxisWizardWindowsText -Name 'CopilotInfoBullet2')
            (Get-AxisWizardWindowsText -Name 'CopilotInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardWindowsText -Name 'Running') `
        -CompletedStatusTitle (Get-AxisWizardWindowsText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'WindowsCopilot' `
        -PrimaryActionWidth 142.0 `
        -StageName 'Windows' `
        -StageBatchMarker 'AxisFirstUseWizard.WindowsStagePartAPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.WindowsCopilotPrototypeOnlyNoRuntimeAction'

    $gameModeStep = New-AxisSetupWizardStepState `
        -Id 'game-mode' `
        -Title 'Game Mode' `
        -Description (Get-AxisWizardWindowsText -Name 'GameModeSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardWindowsText -Name 'GameModePrimary') `
        -InformationCardTitle (Get-AxisWizardWindowsText -Name 'GameModeInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardWindowsText -Name 'GameModeInfoBullet1')
            (Get-AxisWizardWindowsText -Name 'GameModeInfoBullet2')
            (Get-AxisWizardWindowsText -Name 'GameModeInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardWindowsText -Name 'GameModeRunning') `
        -CompletedStatusTitle (Get-AxisWizardWindowsText -Name 'Completed') `
        -CustomerAction 'Open' `
        -FutureInternalAction 'Open' `
        -TagRoot 'WindowsGameMode' `
        -OpenMappedPrototypeOnly $true `
        -PrimaryActionWidth 190.0 `
        -RuntimeStatusWidth 300.0 `
        -RuntimeStatusContentWidth 276.0 `
        -RuntimeStatusTextMaxWidth 174.0 `
        -StageName 'Windows' `
        -StageBatchMarker 'AxisFirstUseWizard.WindowsStagePartAPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.WindowsGameModePrototypeOnlyNoRuntimeAction'

    $pointerPrecisionStep = New-AxisSetupWizardStepState `
        -Id 'pointer-precision' `
        -Title 'Pointer Precision' `
        -Description (Get-AxisWizardWindowsText -Name 'PointerPrecisionSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardWindowsText -Name 'PointerPrecisionPrimary') `
        -InformationCardTitle (Get-AxisWizardWindowsText -Name 'PointerPrecisionInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardWindowsText -Name 'PointerPrecisionInfoBullet1')
            (Get-AxisWizardWindowsText -Name 'PointerPrecisionInfoBullet2')
            (Get-AxisWizardWindowsText -Name 'PointerPrecisionInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardWindowsText -Name 'PointerPrecisionRunning') `
        -CompletedStatusTitle (Get-AxisWizardWindowsText -Name 'Completed') `
        -CustomerAction 'Open' `
        -FutureInternalAction 'Open' `
        -TagRoot 'WindowsPointerPrecision' `
        -OpenMappedPrototypeOnly $true `
        -PrimaryActionWidth 166.0 `
        -RuntimeStatusWidth 278.0 `
        -RuntimeStatusContentWidth 254.0 `
        -RuntimeStatusTextMaxWidth 152.0 `
        -StageName 'Windows' `
        -StageBatchMarker 'AxisFirstUseWizard.WindowsStagePartAPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.WindowsPointerPrecisionPrototypeOnlyNoRuntimeAction'

    $bloatwareStep = New-AxisSetupWizardStepState `
        -Id 'bloatware' `
        -Title 'Bloatware' `
        -Description (Get-AxisWizardWindowsText -Name 'BloatwareSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardWindowsText -Name 'BloatwarePrimary') `
        -InformationCardTitle (Get-AxisWizardWindowsText -Name 'BloatwareInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardWindowsText -Name 'BloatwareInfoBullet1')
            (Get-AxisWizardWindowsText -Name 'BloatwareInfoBullet2')
            (Get-AxisWizardWindowsText -Name 'BloatwareInfoBullet3')
        ) `
        -RequirementsTitle (Get-AxisWizardArabicText -Name 'RequirementsTitle') `
        -RequirementsItems @(
            (Get-AxisWizardWindowsText -Name 'BloatwareRequirement1')
            (Get-AxisWizardWindowsText -Name 'BloatwareRequirement2')
        ) `
        -CheckingStatusTitle (Get-AxisWizardWindowsText -Name 'Running') `
        -CompletedStatusTitle (Get-AxisWizardWindowsText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'WindowsBloatware' `
        -RequiresConfirmationAcknowledgement $true `
        -DocumentationAcknowledgementText (Get-AxisWizardArabicText -Name 'Acknowledgement') `
        -ConfirmationActionLabel (Get-AxisWizardWindowsText -Name 'BloatwarePrimary') `
        -ConfirmationReturnLabel (Get-AxisWizardArabicText -Name 'Return') `
        -PrimaryActionWidth 142.0 `
        -ConfirmationActionWidth 142.0 `
        -StageName 'Windows' `
        -StageBatchMarker 'AxisFirstUseWizard.WindowsStagePartAPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.WindowsBloatwarePrototypeOnlyNoRuntimeAction' `
        -RequiresActionSelector $true `
        -ActionSelectorLabel (Get-AxisWizardWindowsText -Name 'BloatwareSelectorLabel') `
        -ActionSelectorPlaceholder (Get-AxisWizardWindowsText -Name 'BloatwareSelectorPlaceholder') `
        -ActionSelectorOptions @(
            'Remove All Bloatware'
            'Install Store'
            'Install Snipping Tool'
        )

    $gameBarStep = New-AxisSetupWizardStepState `
        -Id 'game-bar' `
        -Title 'Game Bar' `
        -Description (Get-AxisWizardWindowsText -Name 'GameBarSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardWindowsText -Name 'GameBarPrimary') `
        -InformationCardTitle (Get-AxisWizardWindowsText -Name 'GameBarInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardWindowsText -Name 'GameBarInfoBullet1')
            (Get-AxisWizardWindowsText -Name 'GameBarInfoBullet2')
            (Get-AxisWizardWindowsText -Name 'GameBarInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardWindowsText -Name 'Running') `
        -CompletedStatusTitle (Get-AxisWizardWindowsText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'WindowsGameBar' `
        -PrimaryActionWidth 190.0 `
        -StageName 'Windows' `
        -StageBatchMarker 'AxisFirstUseWizard.WindowsStagePartBPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.WindowsGameBarPrototypeOnlyNoRuntimeAction'

    $edgeWebViewStep = New-AxisSetupWizardStepState `
        -Id 'edge-webview' `
        -Title 'Edge WebView' `
        -Description (Get-AxisWizardWindowsText -Name 'EdgeWebViewSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardWindowsText -Name 'EdgeWebViewPrimary') `
        -InformationCardTitle (Get-AxisWizardWindowsText -Name 'EdgeWebViewInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardWindowsText -Name 'EdgeWebViewInfoBullet1')
            (Get-AxisWizardWindowsText -Name 'EdgeWebViewInfoBullet2')
            (Get-AxisWizardWindowsText -Name 'EdgeWebViewInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardWindowsText -Name 'Running') `
        -CompletedStatusTitle (Get-AxisWizardWindowsText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'WindowsEdgeWebView' `
        -RequiresConfirmationAcknowledgement $true `
        -DocumentationAcknowledgementText (Get-AxisWizardArabicText -Name 'Acknowledgement') `
        -ConfirmationActionLabel (Get-AxisWizardWindowsText -Name 'EdgeWebViewPrimary') `
        -ConfirmationReturnLabel (Get-AxisWizardArabicText -Name 'Return') `
        -PrimaryActionWidth 210.0 `
        -ConfirmationActionWidth 210.0 `
        -StageName 'Windows' `
        -StageBatchMarker 'AxisFirstUseWizard.WindowsStagePartBPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.WindowsEdgeWebViewPrototypeOnlyNoRuntimeAction'

    $notepadSettingsStep = New-AxisSetupWizardStepState `
        -Id 'notepad-settings' `
        -Title 'Notepad Settings' `
        -Description (Get-AxisWizardWindowsText -Name 'NotepadSettingsSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardWindowsText -Name 'NotepadSettingsPrimary') `
        -InformationCardTitle (Get-AxisWizardWindowsText -Name 'NotepadSettingsInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardWindowsText -Name 'NotepadSettingsInfoBullet1')
            (Get-AxisWizardWindowsText -Name 'NotepadSettingsInfoBullet2')
            (Get-AxisWizardWindowsText -Name 'NotepadSettingsInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardWindowsText -Name 'Running') `
        -CompletedStatusTitle (Get-AxisWizardWindowsText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'WindowsNotepadSettings' `
        -PrimaryActionWidth 164.0 `
        -StageName 'Windows' `
        -StageBatchMarker 'AxisFirstUseWizard.WindowsStagePartBPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.WindowsNotepadSettingsPrototypeOnlyNoRuntimeAction'

    $controlPanelSettingsStep = New-AxisSetupWizardStepState `
        -Id 'control-panel-settings' `
        -Title 'Control Panel Settings' `
        -Description (Get-AxisWizardWindowsText -Name 'ControlPanelSettingsSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardWindowsText -Name 'ControlPanelSettingsPrimary') `
        -InformationCardTitle (Get-AxisWizardWindowsText -Name 'ControlPanelSettingsInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardWindowsText -Name 'ControlPanelSettingsInfoBullet1')
            (Get-AxisWizardWindowsText -Name 'ControlPanelSettingsInfoBullet2')
            (Get-AxisWizardWindowsText -Name 'ControlPanelSettingsInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardWindowsText -Name 'Running') `
        -CompletedStatusTitle (Get-AxisWizardWindowsText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'WindowsControlPanelSettings' `
        -PrimaryActionWidth 190.0 `
        -StageName 'Windows' `
        -StageBatchMarker 'AxisFirstUseWizard.WindowsStagePartBPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.WindowsControlPanelSettingsPrototypeOnlyNoRuntimeAction'

    $inputLanguageHotkeyStep = New-AxisSetupWizardStepState `
        -Id 'input-language-hotkey' `
        -Title 'Input Language Hotkey' `
        -Description (Get-AxisWizardWindowsText -Name 'InputLanguageHotkeySubtitle') `
        -PrimaryActionLabel (Get-AxisWizardWindowsText -Name 'InputLanguageHotkeyPrimary') `
        -InformationCardTitle (Get-AxisWizardWindowsText -Name 'InputLanguageHotkeyInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardWindowsText -Name 'InputLanguageHotkeyInfoBullet1')
            (Get-AxisWizardWindowsText -Name 'InputLanguageHotkeyInfoBullet2')
            (Get-AxisWizardWindowsText -Name 'InputLanguageHotkeyInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardWindowsText -Name 'Running') `
        -CompletedStatusTitle (Get-AxisWizardWindowsText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'WindowsInputLanguageHotkey' `
        -PrimaryActionWidth 222.0 `
        -StageName 'Windows' `
        -StageBatchMarker 'AxisFirstUseWizard.WindowsStagePartBPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.WindowsInputLanguageHotkeyPrototypeOnlyNoRuntimeAction'

    $soundStep = New-AxisSetupWizardStepState `
        -Id 'sound' `
        -Title 'Sound' `
        -Description (Get-AxisWizardWindowsText -Name 'SoundSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardWindowsText -Name 'SoundPrimary') `
        -InformationCardTitle (Get-AxisWizardWindowsText -Name 'SoundInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardWindowsText -Name 'SoundInfoBullet1')
            (Get-AxisWizardWindowsText -Name 'SoundInfoBullet2')
            (Get-AxisWizardWindowsText -Name 'SoundInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardWindowsText -Name 'Running') `
        -CompletedStatusTitle (Get-AxisWizardWindowsText -Name 'Completed') `
        -CustomerAction 'Open' `
        -FutureInternalAction 'Open' `
        -TagRoot 'WindowsSound' `
        -OpenMappedPrototypeOnly $true `
        -PrimaryActionWidth 224.0 `
        -StageName 'Windows' `
        -StageBatchMarker 'AxisFirstUseWizard.WindowsStagePartBPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.WindowsSoundPrototypeOnlyNoRuntimeAction'

    $deviceManagerPowerSavingsWakeStep = New-AxisSetupWizardStepState `
        -Id 'device-manager-power-savings-wake' `
        -Title 'Device Manager Power Savings Wake' `
        -Description (Get-AxisWizardWindowsText -Name 'DeviceManagerPowerSavingsWakeSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardWindowsText -Name 'DeviceManagerPowerSavingsWakePrimary') `
        -InformationCardTitle (Get-AxisWizardWindowsText -Name 'DeviceManagerPowerSavingsWakeInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardWindowsText -Name 'DeviceManagerPowerSavingsWakeInfoBullet1')
            (Get-AxisWizardWindowsText -Name 'DeviceManagerPowerSavingsWakeInfoBullet2')
            (Get-AxisWizardWindowsText -Name 'DeviceManagerPowerSavingsWakeInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardWindowsText -Name 'Running') `
        -CompletedStatusTitle (Get-AxisWizardWindowsText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'WindowsDeviceManagerPowerSavingsWake' `
        -PrimaryActionWidth 268.0 `
        -StageName 'Windows' `
        -StageBatchMarker 'AxisFirstUseWizard.WindowsStagePartBPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.WindowsDeviceManagerPowerSavingsWakePrototypeOnlyNoRuntimeAction'

    $networkAdapterPowerSavingsWakeStep = New-AxisSetupWizardStepState `
        -Id 'network-adapter-power-savings-wake' `
        -Title 'Network Adapter Power Savings Wake' `
        -Description (Get-AxisWizardWindowsText -Name 'NetworkAdapterPowerSavingsWakeSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardWindowsText -Name 'NetworkAdapterPowerSavingsWakePrimary') `
        -InformationCardTitle (Get-AxisWizardWindowsText -Name 'NetworkAdapterPowerSavingsWakeInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardWindowsText -Name 'NetworkAdapterPowerSavingsWakeInfoBullet1')
            (Get-AxisWizardWindowsText -Name 'NetworkAdapterPowerSavingsWakeInfoBullet2')
            (Get-AxisWizardWindowsText -Name 'NetworkAdapterPowerSavingsWakeInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardWindowsText -Name 'Running') `
        -CompletedStatusTitle (Get-AxisWizardWindowsText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'WindowsNetworkAdapterPowerSavingsWake' `
        -PrimaryActionWidth 260.0 `
        -StageName 'Windows' `
        -StageBatchMarker 'AxisFirstUseWizard.WindowsStagePartBPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.WindowsNetworkAdapterPowerSavingsWakePrototypeOnlyNoRuntimeAction'

    $writeCacheBufferFlushingStep = New-AxisSetupWizardStepState `
        -Id 'write-cache-buffer-flushing' `
        -Title 'Write Cache Buffer Flushing' `
        -Description (Get-AxisWizardWindowsText -Name 'WriteCacheBufferFlushingSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardWindowsText -Name 'WriteCacheBufferFlushingPrimary') `
        -InformationCardTitle (Get-AxisWizardWindowsText -Name 'WriteCacheBufferFlushingInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardWindowsText -Name 'WriteCacheBufferFlushingInfoBullet1')
            (Get-AxisWizardWindowsText -Name 'WriteCacheBufferFlushingInfoBullet2')
            (Get-AxisWizardWindowsText -Name 'WriteCacheBufferFlushingInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardWindowsText -Name 'Running') `
        -CompletedStatusTitle (Get-AxisWizardWindowsText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'WindowsWriteCacheBufferFlushing' `
        -PrimaryActionWidth 196.0 `
        -StageName 'Windows' `
        -StageBatchMarker 'AxisFirstUseWizard.WindowsStagePartBPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.WindowsWriteCacheBufferFlushingPrototypeOnlyNoRuntimeAction'

    $powerPlanStep = New-AxisSetupWizardStepState `
        -Id 'power-plan' `
        -Title 'Power Plan' `
        -Description (Get-AxisWizardWindowsText -Name 'PowerPlanSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardWindowsText -Name 'PowerPlanPrimary') `
        -InformationCardTitle (Get-AxisWizardWindowsText -Name 'PowerPlanInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardWindowsText -Name 'PowerPlanInfoBullet1')
            (Get-AxisWizardWindowsText -Name 'PowerPlanInfoBullet2')
            (Get-AxisWizardWindowsText -Name 'PowerPlanInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardWindowsText -Name 'Running') `
        -CompletedStatusTitle (Get-AxisWizardWindowsText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'WindowsPowerPlan' `
        -PrimaryActionWidth 218.0 `
        -StageName 'Windows' `
        -StageBatchMarker 'AxisFirstUseWizard.WindowsStagePartBPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.WindowsPowerPlanPrototypeOnlyNoRuntimeAction'

    $cleanupStep = New-AxisSetupWizardStepState `
        -Id 'cleanup' `
        -Title 'Cleanup' `
        -Description (Get-AxisWizardWindowsText -Name 'CleanupSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardWindowsText -Name 'CleanupPrimary') `
        -InformationCardTitle (Get-AxisWizardWindowsText -Name 'CleanupInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardWindowsText -Name 'CleanupInfoBullet1')
            (Get-AxisWizardWindowsText -Name 'CleanupInfoBullet2')
            (Get-AxisWizardWindowsText -Name 'CleanupInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardWindowsText -Name 'Running') `
        -CompletedStatusTitle (Get-AxisWizardWindowsText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'WindowsCleanup' `
        -PrimaryActionWidth 176.0 `
        -StageName 'Windows' `
        -StageBatchMarker 'AxisFirstUseWizard.WindowsStagePartBPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.WindowsCleanupPrototypeOnlyNoRuntimeAction'

    $timerResolutionAssistantStep = New-AxisSetupWizardStepState `
        -Id 'timer-resolution-assistant' `
        -Title 'Timer Resolution Assistant' `
        -Description (Get-AxisWizardAdvancedText -Name 'TimerResolutionSubtitle') `
        -PrimaryActionLabel (Get-AxisWizardAdvancedText -Name 'TimerResolutionPrimary') `
        -InformationCardTitle (Get-AxisWizardAdvancedText -Name 'TimerResolutionInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardAdvancedText -Name 'TimerResolutionInfoBullet1')
            (Get-AxisWizardAdvancedText -Name 'TimerResolutionInfoBullet2')
            (Get-AxisWizardAdvancedText -Name 'TimerResolutionInfoBullet3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardAdvancedText -Name 'Running') `
        -CompletedStatusTitle (Get-AxisWizardAdvancedText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'AdvancedTimerResolutionAssistant' `
        -PrimaryActionWidth 232.0 `
        -RuntimeStatusWidth 252.0 `
        -RuntimeStatusContentWidth 228.0 `
        -RuntimeStatusTextMaxWidth 126.0 `
        -StageName 'Advanced' `
        -StageBatchMarker 'AxisFirstUseWizard.AdvancedStageBatchPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.AdvancedTimerResolutionAssistantPrototypeOnlyNoRuntimeAction'

    $defenderOptimizeAssistantStep = New-AxisSetupWizardStepState `
        -Id 'defender-optimize-assistant' `
        -Title 'Defender Optimize Assistant' `
        -Description (Get-AxisWizardAdvancedText -Name 'DefenderOptimizeSubtitle') `
        -PrimaryActionLabel 'Apply Defender Optimize' `
        -InformationCardTitle (Get-AxisWizardAdvancedText -Name 'DefenderOptimizeInfoTitle') `
        -InformationItems @(
            (Get-AxisWizardAdvancedText -Name 'DefenderOptimizeInfoBullet1')
            (Get-AxisWizardAdvancedText -Name 'DefenderOptimizeInfoBullet2')
            (Get-AxisWizardAdvancedText -Name 'DefenderOptimizeInfoBullet3')
        ) `
        -RequirementsTitle (Get-AxisWizardAdvancedText -Name 'DefenderOptimizeRequirementsTitle') `
        -RequirementsItems @(
            (Get-AxisWizardAdvancedText -Name 'DefenderOptimizeRequirement1')
            (Get-AxisWizardAdvancedText -Name 'DefenderOptimizeRequirement2')
            (Get-AxisWizardAdvancedText -Name 'DefenderOptimizeRequirement3')
        ) `
        -CheckingStatusTitle (Get-AxisWizardAdvancedText -Name 'Running') `
        -CompletedStatusTitle (Get-AxisWizardAdvancedText -Name 'Completed') `
        -CustomerAction 'Apply' `
        -FutureInternalAction 'Apply' `
        -TagRoot 'AdvancedDefenderOptimizeAssistant' `
        -RequiresConfirmationAcknowledgement $true `
        -DocumentationAcknowledgementText (Get-AxisWizardArabicText -Name 'Acknowledgement') `
        -ConfirmationActionLabel 'Apply Defender Optimize' `
        -ConfirmationReturnLabel (Get-AxisWizardArabicText -Name 'Return') `
        -PrimaryActionWidth 232.0 `
        -ConfirmationActionWidth 232.0 `
        -RuntimeStatusWidth 252.0 `
        -RuntimeStatusContentWidth 228.0 `
        -RuntimeStatusTextMaxWidth 126.0 `
        -StageName 'Advanced' `
        -StageBatchMarker 'AxisFirstUseWizard.AdvancedStageBatchPrototypeOnly' `
        -NoRealActionMarker 'AxisFirstUseWizard.AdvancedDefenderOptimizeAssistantPrototypeOnlyNoRuntimeAction'

    return [ordered]@{
        BrandName = 'AXIS'
        ModeLabel = ''
        CurrentStageName = 'Check'
        FlowDirection = 'RightToLeft'
        BackLabel = (Get-AxisWizardArabicText -Name 'Back')
        ContinueLabel = (Get-AxisWizardArabicText -Name 'Next')
        Window = [ordered]@{
            Width = 900.0
            Height = 650.0
            Title = 'AXIS First-use wizard prototype'
        }
        Stages = @(Get-AxisFirstUseWizardCanonicalStages)
        CurrentStepIndex = 0
        Step = $biosStep
        Steps = @(
            $biosStep
            $biosSettingsStep
            $reinstallStep
            $autoUnattendStep
            $updatesDriversBlockStep
            $toBiosStep
            $bitLockerStep
            $convertHomeToProStep
            $memoryCompressionStep
            $dateLanguageRegionTimeStep
            $startupAppsSettingsStep
            $startupAppsTaskManagerStep
            $backgroundAppsStep
            $edgeSettingsStep
            $storeSettingsStep
            $updatesPauseStep
            $installersStep
            $installersStartupAppsSettingsStep
            $installersStartupAppsTaskManagerStep
            $restartAfterInstallersStep
            $driverCleanStep
            $gpuDriverSetupStep
            $nvidiaAppInstallStep
            $directXStep
            $visualCppStep
            $graphicsConfigurationCenterStep
            $startMenuTaskbarStep
            $startMenuLayoutStep
            $contextMenuStep
            $themeBlackStep
            $blackLockScreenWallpaperStep
            $blackAccountPicturesStep
            $widgetsStep
            $copilotStep
            $gameModeStep
            $pointerPrecisionStep
            $bloatwareStep
            $gameBarStep
            $edgeWebViewStep
            $notepadSettingsStep
            $controlPanelSettingsStep
            $inputLanguageHotkeyStep
            $soundStep
            $deviceManagerPowerSavingsWakeStep
            $networkAdapterPowerSavingsWakeStep
            $writeCacheBufferFlushingStep
            $powerPlanStep
            $cleanupStep
            $timerResolutionAssistantStep
            $defenderOptimizeAssistantStep
        )
        MockHardwareProfile = $mockHardwareProfile
        SupportedStepStates = @(
            'Ready'
            'Checking'
            'Completed'
        )
        DangerousStepPattern = [ordered]@{
            Title = 'Sample protected step'
            PrimaryActionLabel = (Get-AxisWizardArabicText -Name 'Open')
            RequiresDocumentationAcknowledgement = $true
            DocumentationAcknowledgementText = (Get-AxisWizardArabicText -Name 'Acknowledgement')
            ConfirmationReturnLabel = (Get-AxisWizardArabicText -Name 'Return')
            Acknowledged = $false
        }
    }
}

function New-AxisStageProgressStrip {
    [CmdletBinding()]
    param(
        [System.Collections.IEnumerable]$Stages,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    $strip = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Wizard.StageStripBackground' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderSoft' `
        -RadiusKey 'Axis.Radius.None' `
        -Padding (New-AxisWizardThickness -Left 37 -Top 8 -Right 37 -Bottom 7) `
        -BorderThickness (New-AxisWizardThickness -Left 0 -Top 1 -Right 0 -Bottom 1)
    $strip.Tag = 'AxisFirstUseWizard.StageProgressStrip'
    $strip.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.StageStripNoPartialProgress')
    $strip.ClipToBounds = $true
    $strip.FlowDirection = [System.Windows.FlowDirection]::RightToLeft

    $grid = [System.Windows.Controls.Grid]::new()
    $grid.Tag = 'AxisFirstUseWizard.StageProgressGrid'
    $grid.ClipToBounds = $true
    $grid.FlowDirection = [System.Windows.FlowDirection]::RightToLeft

    $stageItems = @(Resolve-AxisFirstUseWizardStageItems -Stages $Stages)
    foreach ($stage in $stageItems) {
        $column = [System.Windows.Controls.ColumnDefinition]::new()
        $column.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        [void]$grid.ColumnDefinitions.Add($column)
    }

    for ($index = 0; $index -lt $stageItems.Count; $index++) {
        $stage = $stageItems[$index]
        $stageName = [string](Get-AxisWizardMapValue -Map $stage -Name 'Name')
        $stageState = [string](Get-AxisWizardMapValue -Map $stage -Name 'State' -DefaultValue 'Future')

        $item = [System.Windows.Controls.StackPanel]::new()
        $item.Orientation = [System.Windows.Controls.Orientation]::Vertical
        $item.Margin = if ($index -lt ($stageItems.Count - 1)) {
            New-AxisWizardThickness -Left 0 -Top 0 -Right 8 -Bottom 0
        }
        else {
            New-AxisWizardThickness -Left 0
        }
        $item.MinWidth = 0
        $item.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $item.Tag = 'AxisFirstUseWizard.StageProgressItem'
        $item.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, "AxisFirstUseWizard.StageProgressItem.$stageName")

        $labelForeground = if ($stageState -eq 'Current') {
            'Axis.Brush.Wizard.AccentText'
        }
        elseif ($stageState -eq 'Complete') {
            'Axis.Brush.Wizard.StateCompleted.Text'
        }
        else {
            'Axis.Brush.Wizard.TextMuted'
        }

        $label = New-AxisWizardTextBlock `
            -Text $stageName `
            -Resources $Resources `
            -FontSizeKey 'Axis.Type.Micro.FontSize' `
            -FontWeightKey 'Axis.Type.Micro.FontWeight' `
            -ForegroundKey $labelForeground
        $label.TextAlignment = [System.Windows.TextAlignment]::Center
        $label.TextTrimming = [System.Windows.TextTrimming]::CharacterEllipsis
        $label.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $label.Tag = "AxisFirstUseWizard.StageProgressLabel.$stageName"
        [void]$item.Children.Add($label)

        $barBackground = [System.Windows.Controls.Border]::new()
        $barBackground.Height = 3
        $barBackground.Margin = New-AxisWizardThickness -Left 0 -Top 6 -Right 0 -Bottom 0
        $barBackground.CornerRadius = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Radius.Small'
        $barBackground.Background = [System.Windows.Media.Brushes]::Transparent
        $barBackground.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $barBackground.ClipToBounds = $false

        $fill = [System.Windows.Controls.Border]::new()
        $fill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $fill.Width = 104.0
        $fill.Tag = "AxisFirstUseWizard.StageProgressFill.$stageName"
        $fill.CornerRadius = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Radius.Small'
        $fill.Background = if ($stageState -eq 'Complete') {
            New-AxisWizardColorBrush -Color '#22C55E'
        }
        elseif ($stageState -eq 'Current') {
            Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.Accent'
        }
        else {
            Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.BorderSoft'
        }
        if ($stageState -eq 'Complete') {
            $fill.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, "AxisFirstUseWizard.StageLineCompletedFullGreen.$stageName")
        }
        elseif ($stageState -eq 'Current') {
            $fill.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, "AxisFirstUseWizard.StageLineActiveFullWhite.$stageName")
        }
        else {
            $fill.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, "AxisFirstUseWizard.StageLineInactiveDim.$stageName")
        }
        $barBackground.Child = $fill

        [void]$item.Children.Add($barBackground)
        [System.Windows.Controls.Grid]::SetColumn($item, $index)
        [void]$grid.Children.Add($item)
    }

    $strip.Child = $grid
    return $strip
}

function New-AxisStepDocumentationButton {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Step,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    $button = New-AxisWizardButton `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'DocumentationLabel' -DefaultValue (Get-AxisWizardArabicText -Name 'Documentation'))) `
        -Resources $Resources `
        -Variant 'Quiet' `
        -Width 150 `
        -Height 42 `
        -Margin (New-AxisWizardThickness -Left 0 -Top 0 -Right 24 -Bottom 0)
    $button.Tag = 'AxisFirstUseWizard.DocumentationButton'
    $button.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.DocumentationDefaultForeground')
    return $button
}

function New-AxisWizardRuntimeStatusEffect {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Checking', 'Completed')]
        [string]$State,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    $track = [System.Windows.Controls.Border]::new()
    $track.Width = 92
    $track.Height = 5
    $track.CornerRadius = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Radius.Small'
    $track.Background = if ($State -eq 'Completed') {
        New-AxisWizardColorBrush -Color '#0E2A1A'
    }
    else {
        Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.SurfaceSoft'
    }
    $track.ClipToBounds = $true
    $track.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $track.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $track.Tag = if ($State -eq 'Completed') {
        'AxisFirstUseWizard.CompletedEffect'
    }
    else {
        'AxisFirstUseWizard.CheckingAnimation'
    }

    $pulse = [System.Windows.Controls.Border]::new()
    $pulse.Height = 5
    $pulse.CornerRadius = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Radius.Small'
    $pulse.Background = if ($State -eq 'Completed') {
        New-AxisWizardColorBrush -Color '#22C55E'
    }
    else {
        Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.Accent'
    }
    $pulse.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right

    if ($State -eq 'Completed') {
        $track.Effect = New-AxisWizardSuccessGlowEffect
        $track.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.CompletedRuntimeSuccessGlow')
        $pulse.Tag = 'AxisFirstUseWizard.CompletedRuntimeSuccessGlow'
        $pulse.Effect = New-AxisWizardSuccessGlowEffect
        $pulse.Width = 92
        $pulse.Opacity = 0.86
        $fade = [System.Windows.Media.Animation.DoubleAnimation]::new()
        $fade.From = 0.86
        $fade.To = 1.0
        $fade.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(360))
        $fade.AutoReverse = $false
        $fade.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::new(1.0)
        $pulse.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fade)
    }
    else {
        $pulse.Width = 28
        $transform = [System.Windows.Media.TranslateTransform]::new()
        $pulse.RenderTransform = $transform
        $slide = [System.Windows.Media.Animation.DoubleAnimation]::new()
        $slide.From = 0.0
        $slide.To = -64.0
        $slide.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(760))
        $slide.AutoReverse = $true
        $slide.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $transform.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $slide)
    }

    $track.Child = $pulse
    return $track
}

function New-AxisWizardRuntimeStatusContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Checking', 'Completed')]
        [string]$State,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Step,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    $stateResources = Get-AxisWizardStepStateResourceKeys -State $State
    $stepId = [string](Get-AxisWizardMapValue -Map $Step -Name 'Id')
    $isBiosSettingsStep = ($stepId -eq 'bios-settings')
    $isReinstallStep = ($stepId -eq 'reinstall')
    $isAutoUnattendStep = ($stepId -eq 'unattended')
    $isUpdatesDriversStep = ($stepId -eq 'updates-drivers-block')
    $isToBiosStep = ($stepId -eq 'to-bios')
    $isInstallersStep = ($stepId -eq 'installers')
    $isInstallersStageStep = ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue '') -eq 'Installers')
    $isGraphicsStageStep = ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue '') -eq 'Graphics')
    $isWindowsStageStep = ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue '') -eq 'Windows')
    $isAdvancedStageStep = ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue '') -eq 'Advanced')
    $configuredRuntimeContentWidth = [double](Get-AxisWizardMapValue -Map $Step -Name 'RuntimeStatusContentWidth' -DefaultValue 0.0)
    $configuredRuntimeTextMaxWidth = [double](Get-AxisWizardMapValue -Map $Step -Name 'RuntimeStatusTextMaxWidth' -DefaultValue 0.0)
    $contentWidth = if ($configuredRuntimeContentWidth -gt 0.0) { $configuredRuntimeContentWidth } elseif ($isBiosSettingsStep -or $isAutoUnattendStep -or $isToBiosStep -or $isGraphicsStageStep -or $isWindowsStageStep -or $isAdvancedStageStep) { 228.0 } elseif ($isReinstallStep -or $isUpdatesDriversStep) { 210.0 } else { 190.0 }
    $labelAnchorMaxWidth = if ($configuredRuntimeTextMaxWidth -gt 0.0) { $configuredRuntimeTextMaxWidth } elseif ($isBiosSettingsStep -or $isAutoUnattendStep -or $isToBiosStep -or $isGraphicsStageStep -or $isWindowsStageStep -or $isAdvancedStageStep) { 126.0 } elseif ($isReinstallStep -or $isUpdatesDriversStep) { 106.0 } else { 86.0 }

    $content = [System.Windows.Controls.Grid]::new()
    $content.Width = $contentWidth
    $content.MinHeight = 30
    $content.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $content.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $content.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $content.Tag = "AxisFirstUseWizard.RuntimeStatusContent.$State"
    if ($isBiosSettingsStep) {
        $content.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.BiosSettingsRuntimeStatusNoClipping')
    }
    elseif ($isReinstallStep) {
        $content.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.ReinstallRuntimeStatusNoClipping')
    }
    elseif ($isAutoUnattendStep) {
        $content.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.AutoUnattendRuntimeStatusNoClipping')
    }
    elseif ($isUpdatesDriversStep) {
        $content.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.UpdatesDriversRuntimeStatusNoClipping')
    }
    elseif ($isToBiosStep) {
        $content.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.ToBiosRuntimeStatusNoClipping')
    }
    elseif ($isInstallersStageStep) {
        $content.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.InstallersRuntimeStatusNoClipping')
    }
    elseif ($isGraphicsStageStep) {
        $content.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.GraphicsRuntimeStatusNoClipping')
    }
    elseif ($isWindowsStageStep) {
        $content.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.WindowsRuntimeStatusNoClipping')
    }
    elseif ($isAdvancedStageStep) {
        $content.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.AdvancedRuntimeStatusNoClipping')
    }
    elseif ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue '') -eq 'Setup') {
        $content.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.SetupRuntimeStatusNoClipping')
    }
    if ($stepId -eq 'game-mode') {
        $content.Resources['AxisFirstUseWizard.WindowsGameModeRuntimeStatusNoClipping'] = $true
    }
    elseif ($stepId -eq 'pointer-precision') {
        $content.Resources['AxisFirstUseWizard.WindowsPointerPrecisionRuntimeStatusNoClipping'] = $true
    }

    $effectColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $effectColumn.Width = [System.Windows.GridLength]::Auto
    $spacerColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $spacerColumn.Width = [System.Windows.GridLength]::new(10.0)
    $textColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $textColumn.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    [void]$content.ColumnDefinitions.Add($effectColumn)
    [void]$content.ColumnDefinitions.Add($spacerColumn)
    [void]$content.ColumnDefinitions.Add($textColumn)

    $effect = New-AxisWizardRuntimeStatusEffect -State $State -Resources $Resources
    [System.Windows.Controls.Grid]::SetColumn($effect, 0)
    [void]$content.Children.Add($effect)

    $labelText = if ($State -eq 'Completed') {
        [string](Get-AxisWizardMapValue -Map $Step -Name 'CompletedStatusTitle' -DefaultValue (Get-AxisWizardArabicText -Name 'Completed'))
    }
    else {
        [string](Get-AxisWizardMapValue -Map $Step -Name 'CheckingStatusTitle' -DefaultValue (Get-AxisWizardArabicText -Name 'Checking'))
    }

    $label = New-AxisWizardTextBlock `
        -Text $labelText `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -FontWeightKey 'Axis.Type.Micro.FontWeight' `
        -ForegroundKey ([string]$stateResources['Text']) `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::RightToLeft)
    $label.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $label.Tag = 'AxisFirstUseWizard.RuntimeStatusArabicTextInset'
    $label.Margin = New-AxisWizardThickness -Left 0 -Top 0 -Right 8 -Bottom 0
    $labelAnchor = New-AxisWizardRightAnchor `
        -Child $label `
        -Tag 'AxisFirstUseWizard.RuntimeStatusArabicRightAnchor' `
        -MaxWidth $labelAnchorMaxWidth
    $labelAnchor.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    [System.Windows.Controls.Grid]::SetColumn($labelAnchor, 2)
    [void]$content.Children.Add($labelAnchor)

    return $content
}

function New-AxisStepStatusArea {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Step,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    $state = [string](Get-AxisWizardMapValue -Map $Step -Name 'State' -DefaultValue 'Ready')
    $stateResources = Get-AxisWizardStepStateResourceKeys -State $state
    $stepId = [string](Get-AxisWizardMapValue -Map $Step -Name 'Id')
    $isBiosSettingsStep = ($stepId -eq 'bios-settings')
    $isReinstallStep = ($stepId -eq 'reinstall')
    $isAutoUnattendStep = ($stepId -eq 'unattended')
    $isUpdatesDriversStep = ($stepId -eq 'updates-drivers-block')
    $isToBiosStep = ($stepId -eq 'to-bios')
    $isInstallersStep = ($stepId -eq 'installers')
    $isInstallersStageStep = ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue '') -eq 'Installers')
    $isGraphicsStageStep = ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue '') -eq 'Graphics')
    $isWindowsStageStep = ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue '') -eq 'Windows')
    $isAdvancedStageStep = ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue '') -eq 'Advanced')
    $configuredRuntimeStatusWidth = [double](Get-AxisWizardMapValue -Map $Step -Name 'RuntimeStatusWidth' -DefaultValue 0.0)

    $panel = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey ([string]$stateResources['Background']) `
        -BorderBrushKey ([string]$stateResources['Border']) `
        -RadiusKey 'Axis.Radius.Wizard.StatusPanel' `
        -Padding (New-AxisWizardThickness -Left 12 -Top 6 -Right 12 -Bottom 6) `
        -Margin (New-AxisWizardThickness -Left 0)
    $panel.MinHeight = 42
    $panel.Width = if ($configuredRuntimeStatusWidth -gt 0.0) { $configuredRuntimeStatusWidth } elseif ($isBiosSettingsStep -or $isAutoUnattendStep -or $isToBiosStep -or $isGraphicsStageStep -or $isWindowsStageStep -or $isAdvancedStageStep) { 252 } elseif ($isReinstallStep -or $isUpdatesDriversStep) { 234 } else { 214 }
    $panel.Tag = 'AxisFirstUseWizard.RuntimeStatusArea'
    if ($isBiosSettingsStep) {
        $panel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.BiosSettingsRuntimeStatusNoClipping')
    }
    elseif ($isReinstallStep) {
        $panel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.ReinstallRuntimeStatusNoClipping')
    }
    elseif ($isAutoUnattendStep) {
        $panel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.AutoUnattendRuntimeStatusNoClipping')
    }
    elseif ($isUpdatesDriversStep) {
        $panel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.UpdatesDriversRuntimeStatusNoClipping')
    }
    elseif ($isToBiosStep) {
        $panel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.ToBiosRuntimeStatusNoClipping')
    }
    elseif ($isInstallersStageStep) {
        $panel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.InstallersRuntimeStatusNoClipping')
    }
    elseif ($isGraphicsStageStep) {
        $panel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.GraphicsRuntimeStatusNoClipping')
    }
    elseif ($isWindowsStageStep) {
        $panel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.WindowsRuntimeStatusNoClipping')
    }
    elseif ($isAdvancedStageStep) {
        $panel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.AdvancedRuntimeStatusNoClipping')
    }
    elseif ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue '') -eq 'Setup') {
        $panel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.SetupRuntimeStatusNoClipping')
    }
    if ($stepId -eq 'game-mode') {
        $panel.Resources['AxisFirstUseWizard.WindowsGameModeRuntimeStatusNoClipping'] = $true
    }
    elseif ($stepId -eq 'pointer-precision') {
        $panel.Resources['AxisFirstUseWizard.WindowsPointerPrecisionRuntimeStatusNoClipping'] = $true
    }
    $panel.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $panel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $panel.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

    if ($state -eq 'Completed') {
        $panel.Child = New-AxisWizardRuntimeStatusContent -State 'Completed' -Step $Step -Resources $Resources
        $panel.Visibility = [System.Windows.Visibility]::Visible
    }
    elseif ($state -in @('Checking', 'Running')) {
        $panel.Child = New-AxisWizardRuntimeStatusContent -State 'Checking' -Step $Step -Resources $Resources
        $panel.Visibility = [System.Windows.Visibility]::Visible
    }
    else {
        $panel.Visibility = [System.Windows.Visibility]::Collapsed
    }

    return $panel
}

function New-AxisStepSupportPanel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Step,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    $stepId = [string](Get-AxisWizardMapValue -Map $Step -Name 'Id')
    $isToBiosStep = ($stepId -eq 'to-bios')
    $isInstallersStep = ($stepId -eq 'installers')
    $isInstallersStageStep = ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue '') -eq 'Installers')
    $isGraphicsStageStep = ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue '') -eq 'Graphics')
    $isWindowsStageStep = ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue '') -eq 'Windows')
    $isAdvancedStageStep = ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue '') -eq 'Advanced')
    $isSetupStep = ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue '') -eq 'Setup')
    $usesCompactSupport = ($isToBiosStep -or $isSetupStep -or $isInstallersStageStep -or $isGraphicsStageStep -or $isWindowsStageStep -or $isAdvancedStageStep)
    $supportPadding = if ($isGraphicsStageStep -or $isWindowsStageStep -or $isAdvancedStageStep) {
        New-AxisWizardThickness -Left 14 -Top 6 -Right 14 -Bottom 6
    }
    elseif ($usesCompactSupport) {
        New-AxisWizardThickness -Left 14 -Top 7 -Right 14 -Bottom 7
    }
    else {
        New-AxisWizardThickness -Left 14 -Top 8 -Right 14 -Bottom 8
    }
    $supportMargin = if ($isGraphicsStageStep -or $isWindowsStageStep -or $isAdvancedStageStep) {
        New-AxisWizardThickness -Left 0 -Top 4 -Right 0 -Bottom 0
    }
    elseif ($usesCompactSupport) {
        New-AxisWizardThickness -Left 0 -Top 6 -Right 0 -Bottom 0
    }
    else {
        New-AxisWizardThickness -Left 0 -Top 8 -Right 0 -Bottom 0
    }

    $stateResources = Get-AxisWizardStepStateResourceKeys -State 'Ready'
    $panel = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey ([string]$stateResources['Background']) `
        -BorderBrushKey ([string]$stateResources['Border']) `
        -RadiusKey 'Axis.Radius.Wizard.StatusPanel' `
        -Padding $supportPadding `
        -Margin $supportMargin
    $panel.MinHeight = if ($isGraphicsStageStep -or $isWindowsStageStep -or $isAdvancedStageStep) { 52 } elseif ($usesCompactSupport) { 54 } else { 58 }
    $panel.Tag = 'AxisFirstUseWizard.SupportPanel'
    $panel.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $panel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    if ($isToBiosStep) {
        $panel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.ToBiosSupportCardNoClipping')
    }
    elseif ($isInstallersStageStep) {
        $panel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.InstallersSupportCardNoClipping')
    }
    elseif ($isGraphicsStageStep) {
        $panel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.GraphicsSupportCardNoClipping')
    }
    elseif ($isWindowsStageStep) {
        $panel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.WindowsSupportCardNoClipping')
    }
    elseif ($isAdvancedStageStep) {
        $panel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.AdvancedSupportCardNoClipping')
    }
    elseif ($isSetupStep) {
        $panel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.SetupSupportCardNoClipping')
    }

    $support = [System.Windows.Controls.Grid]::new()
    $support.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $support.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $support.MaxWidth = 720
    $support.Tag = 'AxisFirstUseWizard.SupportPanelContent'
    $supportPhysicalRightEdge = New-AxisWizardPhysicalRightEdgeTextGroup `
        -Tag 'AxisFirstUseWizard.SupportSharedPhysicalRightEdge' `
        -Resources $Resources `
        -MaxWidth 720 `
        -Lines @(
            [ordered]@{
                Text = [string](Get-AxisWizardMapValue -Map $Step -Name 'SupportTitle' -DefaultValue (Get-AxisWizardArabicText -Name 'SupportTitle'))
                Tag = 'AxisFirstUseWizard.SupportPhysicalRightTitle'
                FontSizeKey = 'Axis.Type.BodySmall.FontSize'
                FontWeightKey = 'Axis.Type.Micro.FontWeight'
                FontFamilyKey = 'Axis.Type.Caption.FontFamily'
                ForegroundKey = [string]$stateResources['Text']
            }
            [ordered]@{
                Text = [string](Get-AxisWizardMapValue -Map $Step -Name 'SupportBody')
                Tag = 'AxisFirstUseWizard.SupportPhysicalRightBody'
                FontSizeKey = 'Axis.Type.Caption.FontSize'
                FontWeightKey = 'Axis.Type.Body.FontWeight'
                FontFamilyKey = 'Axis.Type.Caption.FontFamily'
                ForegroundKey = [string]$stateResources['Text']
                TopMargin = 2.0
                Wrap = $true
                MaxWidth = 720.0
            }
        )
    [void](Add-AxisWizardGridRow -Grid $support -Child $supportPhysicalRightEdge)

    $panel.Child = New-AxisWizardRightAnchor `
        -Child $support `
        -Tag 'AxisFirstUseWizard.ArabicSupportPanelRightAnchor' `
        -MaxWidth 720
    return $panel
}

function New-AxisStepPrimaryActionArea {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Step,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    $state = [string](Get-AxisWizardMapValue -Map $Step -Name 'State' -DefaultValue 'Ready')
    $primaryEnabled = ($state -eq 'Ready')
    if ([bool](Get-AxisWizardMapValue -Map $Step -Name 'PrimaryActionRequiresSelection' -DefaultValue $false)) {
        $primaryEnabled = $false
    }
    $buttonText = [string](Get-AxisWizardMapValue -Map $Step -Name 'PrimaryActionLabel' -DefaultValue (Get-AxisWizardArabicText -Name 'Open'))
    $stepId = [string](Get-AxisWizardMapValue -Map $Step -Name 'Id')
    $stageName = [string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue '')
    $configuredPrimaryButtonWidth = [double](Get-AxisWizardMapValue -Map $Step -Name 'PrimaryActionWidth' -DefaultValue 0.0)
    $primaryButtonWidth = if ($configuredPrimaryButtonWidth -gt 0.0) { $configuredPrimaryButtonWidth } elseif ($stepId -eq 'reinstall') { 320.0 } elseif ($stepId -eq 'updates-drivers-block') { 264.0 } elseif ($stepId -eq 'to-bios') { 210.0 } elseif ($stepId -eq 'unattended') { 154.0 } else { 142.0 }
    if ($stageName -eq 'Windows') {
        $windowsPrimaryButtonMinimum = [Math]::Min(242.0, [Math]::Max(142.0, ([double]$buttonText.Length * 7.0) + 58.0))
        $primaryButtonWidth = [Math]::Max($primaryButtonWidth, $windowsPrimaryButtonMinimum)
    }
    elseif ($stageName -eq 'Advanced') {
        $advancedPrimaryButtonMinimum = [Math]::Min(252.0, [Math]::Max(196.0, ([double]$buttonText.Length * 7.0) + 58.0))
        $primaryButtonWidth = [Math]::Max($primaryButtonWidth, $advancedPrimaryButtonMinimum)
    }
    $primaryNoClippingMinimums = @{
        'start-menu-layout' = 242.0
        'context-menu' = 218.0
        'user-account-pictures-black' = 224.0
        'game-mode' = 232.0
    }
    $primaryNoClippingMarkers = @{
        'start-menu-layout' = 'AxisFirstUseWizard.WindowsStartMenuLayoutPrimaryNoClipping'
        'context-menu' = 'AxisFirstUseWizard.WindowsContextMenuPrimaryNoClipping'
        'user-account-pictures-black' = 'AxisFirstUseWizard.WindowsBlackAccountPicturesPrimaryNoClipping'
        'game-mode' = 'AxisFirstUseWizard.WindowsGameModePrimaryNoClipping'
    }
    if ($primaryNoClippingMinimums.ContainsKey($stepId)) {
        $primaryButtonWidth = [Math]::Max($primaryButtonWidth, [double]$primaryNoClippingMinimums[$stepId])
    }

    $panel = [System.Windows.Controls.Grid]::new()
    $panel.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $panel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $panel.Tag = 'AxisFirstUseWizard.PrimaryActionArea'
    $fillColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $fillColumn.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $statusColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $statusColumn.Width = [System.Windows.GridLength]::Auto
    $statusSpacerColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $statusSpacerColumn.Width = [System.Windows.GridLength]::new(16.0)
    $buttonColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $buttonColumn.Width = [System.Windows.GridLength]::Auto
    [void]$panel.ColumnDefinitions.Add($fillColumn)
    [void]$panel.ColumnDefinitions.Add($statusColumn)
    [void]$panel.ColumnDefinitions.Add($statusSpacerColumn)
    [void]$panel.ColumnDefinitions.Add($buttonColumn)

    $buttonRow = [System.Windows.Controls.StackPanel]::new()
    $buttonRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $buttonRow.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $buttonRow.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $buttonRow.Tag = 'AxisFirstUseWizard.PrimaryActionButtonRow'
    $primaryButton = New-AxisWizardButton `
        -Text $buttonText `
        -Resources $Resources `
        -Variant 'Primary' `
        -Enabled $primaryEnabled `
        -Width $primaryButtonWidth `
        -Height 42 `
        -Margin (New-AxisWizardThickness -Left 0)
    $primaryButton.Tag = 'AxisFirstUseWizard.PrimaryOpenButton'
    if ($primaryNoClippingMarkers.ContainsKey($stepId)) {
        $primaryNoClippingMarker = [string]$primaryNoClippingMarkers[$stepId]
        $primaryButton.Resources['AxisFirstUseWizard.WindowsPrimaryActionSharedNoClippingSizing'] = $true
        $primaryButton.Resources[$primaryNoClippingMarker] = $true
    }
    elseif ($stageName -eq 'Advanced') {
        $primaryButton.Resources['AxisFirstUseWizard.AdvancedPrimaryActionSharedNoClippingSizing'] = $true
    }
    $documentationButton = New-AxisStepDocumentationButton -Step $Step -Resources $Resources
    $documentationButton.Margin = New-AxisWizardThickness -Left 0
    [void]$buttonRow.Children.Add($primaryButton)
    [void]$buttonRow.Children.Add((New-AxisWizardSpacer -Width 18 -Tag 'AxisFirstUseWizard.PrimaryActionButtonSpacer'))
    [void]$buttonRow.Children.Add($documentationButton)

    $runtimeStatus = New-AxisStepStatusArea -Step $Step -Resources $Resources
    [System.Windows.Controls.Grid]::SetColumn($runtimeStatus, 1)
    [void]$panel.Children.Add($runtimeStatus)

    $runtimeSpacer = New-AxisWizardSpacer -Width 16 -Tag 'AxisFirstUseWizard.ActionRuntimeStatusSpacer'
    if ($runtimeStatus.Visibility -eq [System.Windows.Visibility]::Collapsed) {
        $runtimeSpacer.Visibility = [System.Windows.Visibility]::Collapsed
    }
    [System.Windows.Controls.Grid]::SetColumn($runtimeSpacer, 2)
    [void]$panel.Children.Add($runtimeSpacer)

    [System.Windows.Controls.Grid]::SetColumn($buttonRow, 3)
    [void]$panel.Children.Add($buttonRow)

    return $panel
}

function Split-AxisSetupRightAlignedVisualLines {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$Text,

        [System.Collections.IEnumerable]$BreakBeforePhrases = @(),

        [int]$MaxVisualLineLength = 0
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $remaining = [string]$Text
    foreach ($phrase in @($BreakBeforePhrases)) {
        $breakPhrase = [string]$phrase
        if ([string]::IsNullOrWhiteSpace($breakPhrase)) {
            continue
        }

        $breakIndex = $remaining.IndexOf($breakPhrase, [System.StringComparison]::Ordinal)
        if ($breakIndex -le 0) {
            continue
        }

        $before = $remaining.Substring(0, $breakIndex).Trim()
        if (-not [string]::IsNullOrWhiteSpace($before)) {
            $lines.Add($before)
        }
        $remaining = $remaining.Substring($breakIndex).Trim()
    }

    if (-not [string]::IsNullOrWhiteSpace($remaining)) {
        $lines.Add($remaining)
    }

    if ($lines.Count -eq 0) {
        $lines.Add([string]$Text)
    }

    if ($MaxVisualLineLength -gt 0) {
        $splitLines = [System.Collections.Generic.List[string]]::new()
        foreach ($line in @($lines)) {
            $lineRemainder = ([string]$line).Trim()
            while ($lineRemainder.Length -gt $MaxVisualLineLength) {
                $splitIndex = $lineRemainder.LastIndexOf(' ', [Math]::Min($MaxVisualLineLength, $lineRemainder.Length - 1))
                if ($splitIndex -lt [Math]::Floor($MaxVisualLineLength * 0.55)) {
                    $forwardIndex = $lineRemainder.IndexOf(' ', [Math]::Min($MaxVisualLineLength, $lineRemainder.Length - 1))
                    if ($forwardIndex -gt 0) {
                        $splitIndex = $forwardIndex
                    }
                }

                if ($splitIndex -le 0) {
                    break
                }

                $candidateLine = $lineRemainder.Substring(0, $splitIndex).Trim()
                if (-not [string]::IsNullOrWhiteSpace($candidateLine)) {
                    $splitLines.Add($candidateLine)
                }
                $lineRemainder = $lineRemainder.Substring($splitIndex).Trim()
            }

            if (-not [string]::IsNullOrWhiteSpace($lineRemainder)) {
                $splitLines.Add($lineRemainder)
            }
        }

        if ($splitLines.Count -gt 1) {
            $lastIndex = $splitLines.Count - 1
            $lastLine = [string]$splitLines[$lastIndex]
            $previousLine = [string]$splitLines[$lastIndex - 1]
            if ($lastLine.Length -lt 10 -and ($previousLine.Length + 1 + $lastLine.Length) -le ($MaxVisualLineLength + 16)) {
                $splitLines[$lastIndex - 1] = "$previousLine $lastLine"
                $splitLines.RemoveAt($lastIndex)
            }
        }

        if ($splitLines.Count -gt 0) {
            $lines = $splitLines
        }
    }

    return @($lines)
}

function Get-AxisSetupRightAlignedVisualBreakPhrases {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$StepId,

        [Parameter(Mandatory)]
        [ValidateSet('Information', 'Requirements')]
        [string]$CardKind,

        [AllowNull()]
        [string]$Text
    )

    $phrases = [System.Collections.Generic.List[string]]::new()
    if ($StepId -in @('startup-apps-settings', 'installers-startup-apps-settings') -and $CardKind -eq 'Requirements') {
        $phrases.Add((ConvertFrom-AxisWizardCodePoints @(0x0644, 0x062A, 0x0637, 0x0628, 0x064A, 0x0642, 0x0627, 0x062A, 0x0020, 0x0628, 0x062F, 0x0621, 0x0020, 0x0627, 0x0644, 0x062A, 0x0634, 0x063A, 0x064A, 0x0644, 0x002E)))
    }
    elseif ($StepId -eq 'updates-pause' -and $CardKind -eq 'Information') {
        $phrases.Add((ConvertFrom-AxisWizardCodePoints @(0x0644, 0x062A, 0x0642, 0x0644, 0x064A, 0x0644, 0x0020, 0x0627, 0x0644, 0x0645, 0x0642, 0x0627, 0x0637, 0x0639, 0x0627, 0x062A)))
        $phrases.Add((ConvertFrom-AxisWizardCodePoints @(0x0628, 0x062F, 0x0648, 0x0646, 0x0020, 0x0627, 0x0646, 0x0634, 0x063A, 0x0627, 0x0644, 0x0020, 0x0645, 0x0633, 0x062A, 0x0645, 0x0631, 0x0020, 0x0628, 0x0627, 0x0644, 0x062A, 0x062D, 0x062F, 0x064A, 0x062B, 0x0627, 0x062A, 0x002E)))
    }

    return @(
        $phrases |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and ([string]$Text).Contains([string]$_) }
    )
}

function New-AxisSetupPhysicalRightEdgeTextGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Tag,

        [Parameter(Mandatory)]
        [object]$Resources,

        [Parameter(Mandatory)]
        [System.Collections.IEnumerable]$Lines,

        [double]$MaxWidth = 0.0,

        [string]$AutomationId = ''
    )

    $group = [System.Windows.Controls.Grid]::new()
    $group.Tag = $Tag
    $group.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $group.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    if ($MaxWidth -gt 0.0) {
        $group.MaxWidth = $MaxWidth
    }
    if (-not [string]::IsNullOrWhiteSpace($AutomationId)) {
        $group.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, $AutomationId)
    }
    $group.Resources['AxisFirstUseWizard.SharedCardBodyTextRenderer'] = 'RightAlignedVisualLines'
    $group.Resources['AxisFirstUseWizard.SharedCardBodyNoLeftFloatingWrappedArabic'] = $true
    $group.Resources['AxisFirstUseWizard.SharedCardBodyMixedBidiSafeVisualLines'] = $true
    $group.Resources['AxisFirstUseWizard.SharedCardBodyFutureStageGuard'] = 'GraphicsWindowsAdvanced'

    $rightColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $rightColumn.Width = [System.Windows.GridLength]::Auto
    [void]$group.ColumnDefinitions.Add($rightColumn)

    foreach ($line in @($Lines)) {
        if ($line -isnot [System.Collections.IDictionary]) {
            continue
        }

        $lineText = [string](Get-AxisWizardMapValue -Map $line -Name 'Text')
        $lineTag = [string](Get-AxisWizardMapValue -Map $line -Name 'Tag')
        $lineMaxWidth = [double](Get-AxisWizardMapValue -Map $line -Name 'MaxWidth' -DefaultValue $MaxWidth)
        $lineTopMargin = [double](Get-AxisWizardMapValue -Map $line -Name 'TopMargin' -DefaultValue 0.0)
        $visualBreakBeforePhrases = @(Get-AxisWizardMapValue -Map $line -Name 'VisualBreakBeforePhrases' -DefaultValue @())
        $useSafeVisualLineRenderer = [bool](Get-AxisWizardMapValue -Map $line -Name 'UseSafeVisualLineRenderer' -DefaultValue $false)
        $maxVisualLineLength = [int](Get-AxisWizardMapValue -Map $line -Name 'MaxVisualLineLength' -DefaultValue 0)
        $visualLineAdditionalTopMargin = [double](Get-AxisWizardMapValue -Map $line -Name 'VisualLineTopMargin' -DefaultValue 1.0)
        $visualLines = @(Split-AxisSetupRightAlignedVisualLines -Text $lineText -BreakBeforePhrases $visualBreakBeforePhrases -MaxVisualLineLength $maxVisualLineLength)
        $usesRightAlignedVisualLineRenderer = ($useSafeVisualLineRenderer -or $visualLines.Count -gt 1)

        for ($visualLineIndex = 0; $visualLineIndex -lt $visualLines.Count; $visualLineIndex++) {
            $visualLineTag = if ($visualLineIndex -eq 0) {
                $lineTag
            }
            elseif (-not [string]::IsNullOrWhiteSpace($lineTag)) {
                "$lineTag.VisualLine"
            }
            else {
                'AxisFirstUseWizard.SetupRightAlignedVisualLine'
            }
            $visualLineTopMargin = if ($visualLineIndex -eq 0) { $lineTopMargin } else { $visualLineAdditionalTopMargin }
            $textBlock = New-AxisWizardMixedBidiTextBlock `
                -Text ([string]$visualLines[$visualLineIndex]) `
                -Resources $Resources `
                -Tag $visualLineTag `
                -FontSizeKey ([string](Get-AxisWizardMapValue -Map $line -Name 'FontSizeKey' -DefaultValue 'Axis.Type.Caption.FontSize')) `
                -FontWeightKey ([string](Get-AxisWizardMapValue -Map $line -Name 'FontWeightKey' -DefaultValue 'Axis.Type.Body.FontWeight')) `
                -FontFamilyKey ([string](Get-AxisWizardMapValue -Map $line -Name 'FontFamilyKey' -DefaultValue 'Axis.Type.Caption.FontFamily')) `
                -ForegroundKey ([string](Get-AxisWizardMapValue -Map $line -Name 'ForegroundKey' -DefaultValue 'Axis.Brush.Wizard.TextSecondary')) `
                -Margin (New-AxisWizardThickness -Left 0 -Top $visualLineTopMargin -Right 0 -Bottom 0) `
                -MaxWidth $lineMaxWidth
            if ($usesRightAlignedVisualLineRenderer) {
                $textBlock.TextWrapping = [System.Windows.TextWrapping]::NoWrap
                $textBlock.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.SetupRightAlignedVisualLineRenderer.NoLeftFloatingWrappedArabicLines')
            }
            elseif ([bool](Get-AxisWizardMapValue -Map $line -Name 'Wrap' -DefaultValue $true)) {
                $textBlock.TextWrapping = [System.Windows.TextWrapping]::Wrap
            }
            else {
                $textBlock.TextWrapping = [System.Windows.TextWrapping]::NoWrap
            }
            [System.Windows.Controls.Grid]::SetColumn($textBlock, 0)
            [void](Add-AxisWizardGridRow -Grid $group -Child $textBlock)
        }
    }

    return $group
}

function New-AxisSetupStep {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$Step,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    if ($null -eq $Step) {
        $Step = @((Get-AxisFirstUseWizardSampleState)['Steps'])[6]
    }

    $stepId = [string](Get-AxisWizardMapValue -Map $Step -Name 'Id' -DefaultValue '')
    $tagRoot = [string](Get-AxisWizardMapValue -Map $Step -Name 'TagRoot' -DefaultValue 'SetupStep')
    $showRequirements = [bool](Get-AxisWizardMapValue -Map $Step -Name 'ShowRequirements' -DefaultValue $false)
    $stageName = [string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue 'Setup')
    $isInstallersExtensionStep = ($stageName -eq 'Installers' -and $stepId -ne 'installers')
    $isGraphicsStageStep = ($stageName -eq 'Graphics')
    $isWindowsStageStep = ($stageName -eq 'Windows')
    $isAdvancedStageStep = ($stageName -eq 'Advanced')
    $isCompactStageStep = ($isGraphicsStageStep -or $isWindowsStageStep -or $isAdvancedStageStep)
    $cardContainerPadding = if ($isCompactStageStep) {
        New-AxisWizardThickness -Left 34 -Top 6 -Right 34 -Bottom 3
    }
    else {
        New-AxisWizardThickness -Left 34 -Top 10 -Right 34 -Bottom 6
    }

    $container = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Wizard.MainCardBackground' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderSoft' `
        -RadiusKey 'Axis.Radius.Wizard.MainCard' `
        -Padding $cardContainerPadding `
        -Elevation 'Card'
    $container.Height = 382
    $container.Tag = "AxisFirstUseWizard.${tagRoot}Step"
    $container.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $containerAutomationId = if ($isInstallersExtensionStep) {
        'AxisFirstUseWizard.InstallersStageExtensionPrototypeOnly'
    }
    elseif ($isGraphicsStageStep) {
        'AxisFirstUseWizard.GraphicsStageBatchPrototypeOnly'
    }
    elseif ($isWindowsStageStep) {
        [string](Get-AxisWizardMapValue -Map $Step -Name 'WindowsStageBatchMarker' -DefaultValue 'AxisFirstUseWizard.WindowsStagePartAPrototypeOnly')
    }
    elseif ($isAdvancedStageStep) {
        [string](Get-AxisWizardMapValue -Map $Step -Name 'AdvancedStageBatchMarker' -DefaultValue 'AxisFirstUseWizard.AdvancedStageBatchPrototypeOnly')
    }
    else {
        'AxisFirstUseWizard.SetupStageBatchPrototypeOnly'
    }
    $container.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, $containerAutomationId)

    $content = [System.Windows.Controls.Grid]::new()
    $content.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $content.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $content.Tag = 'AxisFirstUseWizard.StepTextContent'

    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue 'Setup')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -FontWeightKey 'Axis.Type.Micro.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.AccentText' `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::LeftToRight)))

    $titleText = [string](Get-AxisWizardMapValue -Map $Step -Name 'Title')
    $titleFlow = if ([regex]::IsMatch($titleText, '^[\x00-\x7F]+$')) {
        [System.Windows.FlowDirection]::LeftToRight
    }
    else {
        [System.Windows.FlowDirection]::RightToLeft
    }
    $titleMargin = if ($isCompactStageStep) {
        New-AxisWizardThickness -Left 0 -Top 1 -Right 0 -Bottom 3
    }
    else {
        New-AxisWizardThickness -Left 0 -Top 3 -Right 0 -Bottom 5
    }
    $title = New-AxisWizardTextBlock `
        -Text $titleText `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.PageTitle.FontSize' `
        -FontWeightKey 'Axis.Type.PageTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.TextPrimary' `
        -Margin $titleMargin `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection $titleFlow
    $title.Tag = "AxisFirstUseWizard.${tagRoot}TitleText"
    $title.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $title.TextWrapping = [System.Windows.TextWrapping]::NoWrap
    $title.MaxWidth = 690
    if ($titleFlow -eq [System.Windows.FlowDirection]::LeftToRight) {
        $title.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, "AxisFirstUseWizard.EnglishOnlyTitleRightAnchored.${tagRoot}")
    }
    else {
        $title.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, "AxisFirstUseWizard.${tagRoot}TitleRightAnchoredBidiSafe")
    }
    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisWizardRightAnchor `
        -Child $title `
        -Tag "AxisFirstUseWizard.${tagRoot}TitleRightAnchor" `
        -MaxWidth 690 `
        -PreserveChildFlowDirection))

    $descriptionText = New-AxisWizardMixedBidiTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'Description')) `
        -Resources $Resources `
        -Tag "AxisFirstUseWizard.${tagRoot}Subtitle" `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -FontFamilyKey 'Axis.Type.BodySmall.FontFamily' `
        -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
        -MaxWidth 690
    $descriptionText.TextWrapping = [System.Windows.TextWrapping]::Wrap
    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisWizardRightAnchor `
        -Child $descriptionText `
        -Tag "AxisFirstUseWizard.${tagRoot}SubtitleRightAnchor" `
        -MaxWidth 690))

    $graphicsGpuSelector = $null
    $actionSelector = $null
    if ([bool](Get-AxisWizardMapValue -Map $Step -Name 'RequiresGpuSelector' -DefaultValue $false)) {
        $selectorGrid = [System.Windows.Controls.Grid]::new()
        $selectorGrid.Margin = New-AxisWizardThickness -Left 0 -Top 1 -Right 0 -Bottom 1
        $selectorGrid.Tag = 'AxisFirstUseWizard.GraphicsGpuSelectorRow'
        $selectorGrid.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
        $selectorGrid.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $selectorGrid.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.GraphicsGpuSelectorNvidiaOnly')
        $selectorControlColumn = [System.Windows.Controls.ColumnDefinition]::new()
        $selectorControlColumn.Width = [System.Windows.GridLength]::Auto
        $selectorLabelColumn = [System.Windows.Controls.ColumnDefinition]::new()
        $selectorLabelColumn.Width = [System.Windows.GridLength]::Auto
        $selectorFillColumn = [System.Windows.Controls.ColumnDefinition]::new()
        $selectorFillColumn.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        [void]$selectorGrid.ColumnDefinitions.Add($selectorControlColumn)
        [void]$selectorGrid.ColumnDefinitions.Add($selectorLabelColumn)
        [void]$selectorGrid.ColumnDefinitions.Add($selectorFillColumn)
        $selectorGrid.Resources['AxisFirstUseWizard.SelectorPhysicalLeftAboveRequirements'] = $true
        $selectorGrid.Resources['AxisFirstUseWizard.SelectorLabelPhysicalRightOfControl'] = $true
        $selectorGrid.Resources['AxisFirstUseWizard.GraphicsGpuSelectorPhysicalLeftAboveRequirements'] = $true

        $selectorLabel = New-AxisWizardTextBlock `
            -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'GpuSelectorLabel')) `
            -Resources $Resources `
            -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
            -FontWeightKey 'Axis.Type.Micro.FontWeight' `
            -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
            -TextAlignment ([System.Windows.TextAlignment]::Right) `
            -FlowDirection ([System.Windows.FlowDirection]::RightToLeft)
        $selectorLabel.Tag = 'AxisFirstUseWizard.GraphicsGpuSelectorLabel'
        $selectorLabel.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $selectorLabel.Margin = New-AxisWizardThickness -Left 12 -Top 0 -Right 0 -Bottom 0
        [System.Windows.Controls.Grid]::SetColumn($selectorLabel, 1)
        [void]$selectorGrid.Children.Add($selectorLabel)

        $graphicsGpuSelector = [System.Windows.Controls.ComboBox]::new()
        $graphicsGpuSelector.Tag = 'AxisFirstUseWizard.GraphicsGpuSelector'
        $graphicsGpuSelector.Width = 270
        $graphicsGpuSelector.Height = 34
        $graphicsGpuSelector.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
        $graphicsGpuSelector.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $graphicsGpuSelector.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
        $graphicsGpuSelector.IsEditable = $false
        $graphicsGpuSelector.MaxDropDownHeight = 150
        $graphicsGpuSelector.FontFamily = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontFamily'
        $graphicsGpuSelector.FontSize = [double](Get-AxisWizardResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontSize')
        Set-AxisWizardSelectorComboBoxStyle `
            -Selector $graphicsGpuSelector `
            -Resources $Resources `
            -FlowDirection ([System.Windows.FlowDirection]::LeftToRight) `
            -HorizontalContentAlignment ([System.Windows.HorizontalAlignment]::Left) `
            -Padding (New-AxisWizardThickness -Left 12 -Top 5 -Right 12 -Bottom 5)
        $graphicsGpuSelector.Resources['AxisFirstUseWizard.GraphicsGpuSelectorNvidiaOnly'] = $true
        $graphicsGpuSelector.Resources['AxisFirstUseWizard.GraphicsGpuSelectorAmdIntelDisabled'] = $true
        $graphicsGpuSelector.Resources['AxisFirstUseWizard.GraphicsGpuSelectorNoRuntimeAction'] = $true
        $graphicsGpuSelector.Resources['AxisFirstUseWizard.GraphicsGpuSelectorUsesSharedDarkAxisStyle'] = $true
        $graphicsGpuSelector.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.GraphicsGpuSelectorNvidiaOnly')
        $graphicsEnabledItemStyle = New-AxisWizardSelectorComboBoxItemStyle -Resources $Resources -HorizontalContentAlignment ([System.Windows.HorizontalAlignment]::Left)
        $graphicsDisabledItemStyle = New-AxisWizardSelectorComboBoxItemStyle -Resources $Resources -HorizontalContentAlignment ([System.Windows.HorizontalAlignment]::Left)
        $gpuSelectorOptions = @(Get-AxisWizardMapValue -Map $Step -Name 'GpuSelectorOptions' -DefaultValue @())
        $gpuSelectorEnabledOptions = @(Get-AxisWizardMapValue -Map $Step -Name 'GpuSelectorEnabledOptions' -DefaultValue @())
        foreach ($gpuSelectorOption in $gpuSelectorOptions) {
            $gpuItem = [System.Windows.Controls.ComboBoxItem]::new()
            $gpuItem.Content = [string]$gpuSelectorOption
            $gpuItem.Tag = [string]$gpuSelectorOption
            $gpuItem.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
            $gpuItem.HorizontalContentAlignment = [System.Windows.HorizontalAlignment]::Left
            $gpuItem.IsEnabled = ([string]$gpuSelectorOption -in [string[]]$gpuSelectorEnabledOptions)
            $gpuItem.Style = if ([bool]$gpuItem.IsEnabled) { $graphicsEnabledItemStyle } else { $graphicsDisabledItemStyle }
            [void]$graphicsGpuSelector.Items.Add($gpuItem)
        }
        $graphicsGpuSelector.SelectedIndex = -1
        [System.Windows.Controls.Grid]::SetColumn($graphicsGpuSelector, 0)
        [void]$selectorGrid.Children.Add($graphicsGpuSelector)
        [void](Add-AxisWizardGridRow -Grid $content -Child $selectorGrid)
    }

    if ([bool](Get-AxisWizardMapValue -Map $Step -Name 'RequiresActionSelector' -DefaultValue $false)) {
        $actionSelectorGrid = [System.Windows.Controls.Grid]::new()
        $actionSelectorGrid.Margin = New-AxisWizardThickness -Left 0 -Top 1 -Right 0 -Bottom 1
        $actionSelectorGrid.Tag = 'AxisFirstUseWizard.WindowsBloatwareActionSelectorRow'
        $actionSelectorGrid.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
        $actionSelectorGrid.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $actionSelectorGrid.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.WindowsBloatwareActionSelectorSingleSelect')
        $actionSelectorControlColumn = [System.Windows.Controls.ColumnDefinition]::new()
        $actionSelectorControlColumn.Width = [System.Windows.GridLength]::Auto
        $actionSelectorLabelColumn = [System.Windows.Controls.ColumnDefinition]::new()
        $actionSelectorLabelColumn.Width = [System.Windows.GridLength]::Auto
        $actionSelectorFillColumn = [System.Windows.Controls.ColumnDefinition]::new()
        $actionSelectorFillColumn.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        [void]$actionSelectorGrid.ColumnDefinitions.Add($actionSelectorControlColumn)
        [void]$actionSelectorGrid.ColumnDefinitions.Add($actionSelectorLabelColumn)
        [void]$actionSelectorGrid.ColumnDefinitions.Add($actionSelectorFillColumn)
        $actionSelectorGrid.Resources['AxisFirstUseWizard.SelectorPhysicalLeftAboveRequirements'] = $true
        $actionSelectorGrid.Resources['AxisFirstUseWizard.SelectorLabelPhysicalRightOfControl'] = $true
        $actionSelectorGrid.Resources['AxisFirstUseWizard.WindowsBloatwareSelectorPhysicalLeftAboveRequirements'] = $true

        $actionSelectorLabel = New-AxisWizardTextBlock `
            -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'ActionSelectorLabel')) `
            -Resources $Resources `
            -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
            -FontWeightKey 'Axis.Type.Micro.FontWeight' `
            -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
            -TextAlignment ([System.Windows.TextAlignment]::Right) `
            -FlowDirection ([System.Windows.FlowDirection]::RightToLeft)
        $actionSelectorLabel.Tag = 'AxisFirstUseWizard.WindowsBloatwareActionSelectorLabel'
        $actionSelectorLabel.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $actionSelectorLabel.Margin = New-AxisWizardThickness -Left 12 -Top 0 -Right 0 -Bottom 0
        [System.Windows.Controls.Grid]::SetColumn($actionSelectorLabel, 1)
        [void]$actionSelectorGrid.Children.Add($actionSelectorLabel)

        $actionSelector = [System.Windows.Controls.ComboBox]::new()
        $actionSelector.Tag = 'AxisFirstUseWizard.WindowsBloatwareActionSelector'
        $actionSelector.Width = 318
        $actionSelector.Height = 34
        $actionSelector.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
        $actionSelector.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $actionSelector.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
        $actionSelector.IsEditable = $false
        $actionSelector.MaxDropDownHeight = 150
        $actionSelector.FontFamily = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontFamily'
        $actionSelector.FontSize = [double](Get-AxisWizardResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontSize')
        Set-AxisWizardSelectorComboBoxStyle `
            -Selector $actionSelector `
            -Resources $Resources `
            -FlowDirection ([System.Windows.FlowDirection]::LeftToRight) `
            -HorizontalContentAlignment ([System.Windows.HorizontalAlignment]::Left) `
            -Padding (New-AxisWizardThickness -Left 12 -Top 5 -Right 12 -Bottom 5)
        $actionSelector.Resources['AxisFirstUseWizard.WindowsBloatwareActionSelectorSingleSelect'] = $true
        $actionSelector.Resources['AxisFirstUseWizard.WindowsBloatwareActionSelectorNoRuntimeAction'] = $true
        $actionSelector.Resources['AxisFirstUseWizard.WindowsBloatwareActionSelectorUsesSharedDarkAxisStyle'] = $true
        $actionSelector.Resources['AxisFirstUseWizard.WindowsBloatwareActionSelectorOptionsOwnerApprovedOnly'] = $true
        $actionSelector.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.WindowsBloatwareActionSelectorSingleSelect')
        $actionSelectorPlaceholderItemStyle = New-AxisWizardSelectorComboBoxItemStyle -Resources $Resources -HorizontalContentAlignment ([System.Windows.HorizontalAlignment]::Right)
        $actionSelectorOptionItemStyle = New-AxisWizardSelectorComboBoxItemStyle -Resources $Resources -HorizontalContentAlignment ([System.Windows.HorizontalAlignment]::Left)

        $actionPlaceholderItem = [System.Windows.Controls.ComboBoxItem]::new()
        $actionPlaceholderItem.Content = [string](Get-AxisWizardMapValue -Map $Step -Name 'ActionSelectorPlaceholder')
        $actionPlaceholderItem.Tag = 'AxisFirstUseWizard.WindowsBloatwareActionSelectorPlaceholderItem'
        $actionPlaceholderItem.IsEnabled = $false
        $actionPlaceholderItem.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
        $actionPlaceholderItem.Style = $actionSelectorPlaceholderItemStyle
        [void]$actionSelector.Items.Add($actionPlaceholderItem)

        foreach ($actionSelectorOption in @(Get-AxisWizardMapValue -Map $Step -Name 'ActionSelectorOptions' -DefaultValue @())) {
            $actionItem = [System.Windows.Controls.ComboBoxItem]::new()
            $actionItem.Content = [string]$actionSelectorOption
            $actionItem.Tag = [string]$actionSelectorOption
            $actionItem.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
            $actionItem.HorizontalContentAlignment = [System.Windows.HorizontalAlignment]::Left
            $actionItem.Style = $actionSelectorOptionItemStyle
            [void]$actionSelector.Items.Add($actionItem)
        }
        $actionSelector.SelectedIndex = 0
        [System.Windows.Controls.Grid]::SetColumn($actionSelector, 0)
        [void]$actionSelectorGrid.Children.Add($actionSelector)
        [void](Add-AxisWizardGridRow -Grid $content -Child $actionSelectorGrid)
    }

    $detailsGrid = [System.Windows.Controls.Grid]::new()
    $detailsGrid.Margin = if ($isCompactStageStep) {
        New-AxisWizardThickness -Left 0 -Top 2 -Right 0 -Bottom 3
    }
    else {
        New-AxisWizardThickness -Left 0 -Top 5 -Right 0 -Bottom 5
    }
    $detailsGrid.Tag = "AxisFirstUseWizard.${tagRoot}StepDetails"
    $detailsGrid.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $detailsGrid.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    if ($showRequirements) {
        $detailsGrid.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.SetupCardsPhysicalOrderInfoRightRequirementsLeft')
        if ($isInstallersExtensionStep) {
            $detailsGrid.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.InstallersExtensionCardsPhysicalOrderInfoRightRequirementsLeft')
        }
        elseif ($isGraphicsStageStep) {
            $detailsGrid.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.GraphicsCardsPhysicalOrderInfoRightRequirementsLeft')
        }
        elseif ($isWindowsStageStep) {
            $detailsGrid.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.WindowsCardsPhysicalOrderInfoRightRequirementsLeft')
        }
        elseif ($isAdvancedStageStep) {
            $detailsGrid.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.AdvancedCardsPhysicalOrderInfoRightRequirementsLeft')
        }
    }

    $setupTwoCardTextMaxWidth = 340.0
    $setupSingleCardTextMaxWidth = 650.0
    $setupCardHeight = if ($showRequirements) {
        if ($isCompactStageStep) { 144.0 } else { 146.0 }
    }
    else {
        if ($isCompactStageStep) { 126.0 } else { 128.0 }
    }
    $setupCardPadding = if ($isCompactStageStep) {
        New-AxisWizardThickness -Left 10 -Top 5 -Right 10 -Bottom 5
    }
    else {
        New-AxisWizardThickness -Left 10 -Top 6 -Right 10 -Bottom 6
    }
    $setupCardItemTopMargin = if ($isCompactStageStep) { 1.0 } else { 3.0 }
    $setupCardVisualLineTopMargin = if ($isCompactStageStep) { 0.0 } else { 1.0 }
    $setupCardItemMaxVisualLineLength = if ($showRequirements) {
        if ($isCompactStageStep) { 58 } else { 62 }
    }
    else {
        if ($isCompactStageStep) { 94 } else { 100 }
    }

    if ($showRequirements) {
        $requirementsColumn = [System.Windows.Controls.ColumnDefinition]::new()
        $requirementsColumn.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        $spacerColumn = [System.Windows.Controls.ColumnDefinition]::new()
        $spacerColumn.Width = [System.Windows.GridLength]::new(12.0)
        $informationColumn = [System.Windows.Controls.ColumnDefinition]::new()
        $informationColumn.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        [void]$detailsGrid.ColumnDefinitions.Add($requirementsColumn)
        [void]$detailsGrid.ColumnDefinitions.Add($spacerColumn)
        [void]$detailsGrid.ColumnDefinitions.Add($informationColumn)
    }
    else {
        $informationColumn = [System.Windows.Controls.ColumnDefinition]::new()
        $informationColumn.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        [void]$detailsGrid.ColumnDefinitions.Add($informationColumn)
    }

    $informationPanel = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Wizard.InfoCard' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderSoft' `
        -RadiusKey 'Axis.Radius.Wizard.InfoCard' `
        -Padding $setupCardPadding `
        -Elevation 'Soft'
    $informationPanel.Height = $setupCardHeight
    $informationPanel.Tag = "AxisFirstUseWizard.${tagRoot}InformationCard"
    $informationPanel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, "AxisFirstUseWizard.${tagRoot}InformationNoClipping")
    $informationPanel.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $informationPanel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch

    $informationLines = [System.Collections.Generic.List[object]]::new()
    $informationLines.Add([ordered]@{
        Text = [string](Get-AxisWizardMapValue -Map $Step -Name 'InformationCardTitle')
        Tag = "AxisFirstUseWizard.${tagRoot}InformationTitle"
        FontSizeKey = 'Axis.Type.BodySmall.FontSize'
        FontWeightKey = 'Axis.Type.CardTitle.FontWeight'
        FontFamilyKey = 'Axis.Type.BodySmall.FontFamily'
        ForegroundKey = 'Axis.Brush.Wizard.TextPrimary'
        Wrap = $true
        MaxWidth = if ($showRequirements) { $setupTwoCardTextMaxWidth } else { $setupSingleCardTextMaxWidth }
    })
    foreach ($item in @(Get-AxisWizardMapValue -Map $Step -Name 'InformationItems' -DefaultValue @())) {
        $informationItemText = [string]$item
        $informationLine = [ordered]@{
            Text = $informationItemText
            Tag = "AxisFirstUseWizard.${tagRoot}InformationItem"
            FontSizeKey = 'Axis.Type.Caption.FontSize'
            FontWeightKey = 'Axis.Type.Body.FontWeight'
            FontFamilyKey = 'Axis.Type.Caption.FontFamily'
            ForegroundKey = 'Axis.Brush.Wizard.TextSecondary'
            TopMargin = $setupCardItemTopMargin
            Wrap = $true
            MaxWidth = if ($showRequirements) { $setupTwoCardTextMaxWidth } else { $setupSingleCardTextMaxWidth }
            UseSafeVisualLineRenderer = $true
            MaxVisualLineLength = $setupCardItemMaxVisualLineLength
            VisualLineTopMargin = $setupCardVisualLineTopMargin
        }
        $informationVisualBreakBeforePhrases = @(Get-AxisSetupRightAlignedVisualBreakPhrases -StepId $stepId -CardKind 'Information' -Text $informationItemText)
        if ($informationVisualBreakBeforePhrases.Count -gt 0) {
            $informationLine['VisualBreakBeforePhrases'] = $informationVisualBreakBeforePhrases
        }
        $informationLines.Add($informationLine)
    }
    $informationMaxWidth = if ($showRequirements) { $setupTwoCardTextMaxWidth } else { $setupSingleCardTextMaxWidth }
    $informationGroup = New-AxisSetupPhysicalRightEdgeTextGroup `
        -Tag "AxisFirstUseWizard.${tagRoot}InformationSharedPhysicalRightEdge" `
        -Resources $Resources `
        -MaxWidth $informationMaxWidth `
        -Lines $informationLines `
        -AutomationId "AxisFirstUseWizard.${tagRoot}MixedBidiSafeInfoText"
    $informationContent = [System.Windows.Controls.Grid]::new()
    $informationContent.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $informationContent.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $informationContent.MaxWidth = $informationMaxWidth
    $informationContent.Tag = "AxisFirstUseWizard.${tagRoot}InformationCardContent"
    [void](Add-AxisWizardGridRow -Grid $informationContent -Child $informationGroup)
    $informationPanel.Child = New-AxisWizardRightAnchor `
        -Child $informationContent `
        -Tag "AxisFirstUseWizard.${tagRoot}InformationRightAnchor" `
        -MaxWidth $informationMaxWidth
    if ($showRequirements) {
        [System.Windows.Controls.Grid]::SetColumn($informationPanel, 2)
    }
    else {
        [System.Windows.Controls.Grid]::SetColumn($informationPanel, 0)
    }
    [void]$detailsGrid.Children.Add($informationPanel)

    if ($showRequirements) {
        $requirementsPanel = New-AxisWizardPanel `
            -Resources $Resources `
            -BackgroundKey 'Axis.Brush.Wizard.InfoCard' `
            -BorderBrushKey 'Axis.Brush.Wizard.BorderSoft' `
            -RadiusKey 'Axis.Radius.Wizard.InfoCard' `
            -Padding $setupCardPadding `
            -Elevation 'Soft'
        $requirementsPanel.Height = $setupCardHeight
        $requirementsPanel.Tag = "AxisFirstUseWizard.${tagRoot}RequirementsCard"
        $requirementsPanel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, "AxisFirstUseWizard.${tagRoot}RequirementsNoClipping")
        $requirementsPanel.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
        $requirementsPanel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch

        $requirementsLines = [System.Collections.Generic.List[object]]::new()
        $requirementsLines.Add([ordered]@{
            Text = [string](Get-AxisWizardMapValue -Map $Step -Name 'RequirementsTitle')
            Tag = "AxisFirstUseWizard.${tagRoot}RequirementsTitle"
            FontSizeKey = 'Axis.Type.BodySmall.FontSize'
            FontWeightKey = 'Axis.Type.CardTitle.FontWeight'
            FontFamilyKey = 'Axis.Type.BodySmall.FontFamily'
            ForegroundKey = 'Axis.Brush.Wizard.TextPrimary'
            Wrap = $true
            MaxWidth = $setupTwoCardTextMaxWidth
        })
        foreach ($item in @(Get-AxisWizardMapValue -Map $Step -Name 'RequirementsItems' -DefaultValue @())) {
            $requirementsItemText = [string]$item
            $requirementsLine = [ordered]@{
                Text = $requirementsItemText
                Tag = "AxisFirstUseWizard.${tagRoot}RequirementItem"
                FontSizeKey = 'Axis.Type.Caption.FontSize'
                FontWeightKey = 'Axis.Type.Body.FontWeight'
                FontFamilyKey = 'Axis.Type.Caption.FontFamily'
                ForegroundKey = 'Axis.Brush.Wizard.TextSecondary'
                TopMargin = $setupCardItemTopMargin
                Wrap = $true
                MaxWidth = $setupTwoCardTextMaxWidth
                UseSafeVisualLineRenderer = $true
                MaxVisualLineLength = $setupCardItemMaxVisualLineLength
                VisualLineTopMargin = $setupCardVisualLineTopMargin
            }
            $requirementsVisualBreakBeforePhrases = @(Get-AxisSetupRightAlignedVisualBreakPhrases -StepId $stepId -CardKind 'Requirements' -Text $requirementsItemText)
            if ($requirementsVisualBreakBeforePhrases.Count -gt 0) {
                $requirementsLine['VisualBreakBeforePhrases'] = $requirementsVisualBreakBeforePhrases
            }
            $requirementsLines.Add($requirementsLine)
        }
        $requirementsGroup = New-AxisSetupPhysicalRightEdgeTextGroup `
            -Tag "AxisFirstUseWizard.${tagRoot}RequirementsSharedPhysicalRightEdge" `
            -Resources $Resources `
            -MaxWidth $setupTwoCardTextMaxWidth `
            -Lines $requirementsLines `
            -AutomationId "AxisFirstUseWizard.${tagRoot}MixedBidiSafeRequirementsText"
        $requirementsContent = [System.Windows.Controls.Grid]::new()
        $requirementsContent.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
        $requirementsContent.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
        $requirementsContent.MaxWidth = $setupTwoCardTextMaxWidth
        $requirementsContent.Tag = "AxisFirstUseWizard.${tagRoot}RequirementsCardContent"
        [void](Add-AxisWizardGridRow -Grid $requirementsContent -Child $requirementsGroup)
        $requirementsPanel.Child = New-AxisWizardRightAnchor `
            -Child $requirementsContent `
            -Tag "AxisFirstUseWizard.${tagRoot}RequirementsRightAnchor" `
            -MaxWidth $setupTwoCardTextMaxWidth
        [System.Windows.Controls.Grid]::SetColumn($requirementsPanel, 0)
        [void]$detailsGrid.Children.Add($requirementsPanel)
    }

    [void](Add-AxisWizardGridRow -Grid $content -Child $detailsGrid)
    $primaryAction = New-AxisStepPrimaryActionArea -Step $Step -Resources $Resources
    $primaryAction.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, "AxisFirstUseWizard.${tagRoot}SimulationOnlyActionRow")
    [void](Add-AxisWizardGridRow -Grid $content -Child $primaryAction)
    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisStepSupportPanel -Step $Step -Resources $Resources))

    if ($graphicsGpuSelector -is [System.Windows.Controls.ComboBox]) {
        $graphicsPrimaryButton = $null
        foreach ($actionChild in @($primaryAction.Children)) {
            if ($actionChild -is [System.Windows.Controls.StackPanel] -and [string]$actionChild.Tag -eq 'AxisFirstUseWizard.PrimaryActionButtonRow') {
                foreach ($buttonCandidate in @($actionChild.Children)) {
                    if ($buttonCandidate -is [System.Windows.Controls.Button] -and [string]$buttonCandidate.Tag -eq 'AxisFirstUseWizard.PrimaryOpenButton') {
                        $graphicsPrimaryButton = $buttonCandidate
                        break
                    }
                }
            }
        }

        $graphicsPrimaryBackground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.PrimaryButton'
        $graphicsPrimaryBorder = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.PrimaryButtonHover'
        $graphicsPrimaryForeground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.PrimaryButtonText'
        $graphicsPrimaryEffect = New-AxisWizardShadowEffect -Opacity 0.16 -BlurRadius 16 -ShadowDepth 3
        $graphicsDisabledBackground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.SurfaceSoft'
        $graphicsDisabledBorder = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.BorderSoft'
        $graphicsDisabledForeground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.TextMuted'
        $graphicsPrimaryAutomationProperty = [System.Windows.Automation.AutomationProperties]::AutomationIdProperty
        $graphicsEnabledAutomationId = 'AxisFirstUseWizard.GraphicsGpuSetupPrimaryEnabledWithNvidiaSelection'
        $graphicsDisabledAutomationId = 'AxisFirstUseWizard.GraphicsGpuSetupPrimaryDisabledUntilNvidiaSelected'
        if ($graphicsPrimaryButton -is [System.Windows.Controls.Button]) {
            $graphicsPrimaryButton.SetValue($graphicsPrimaryAutomationProperty, $graphicsDisabledAutomationId)
            $graphicsPrimaryButton.Resources['AxisFirstUseWizard.GraphicsGpuSetupSelectedGpu'] = ''
        }

        $graphicsPrimaryButtonForSelector = $graphicsPrimaryButton
        $graphicsGpuSelectorForSelector = $graphicsGpuSelector
        $graphicsEnabledBackgroundForSelector = $graphicsPrimaryBackground
        $graphicsEnabledBorderForSelector = $graphicsPrimaryBorder
        $graphicsEnabledForegroundForSelector = $graphicsPrimaryForeground
        $graphicsEnabledEffectForSelector = $graphicsPrimaryEffect
        $graphicsDisabledBackgroundForSelector = $graphicsDisabledBackground
        $graphicsDisabledBorderForSelector = $graphicsDisabledBorder
        $graphicsDisabledForegroundForSelector = $graphicsDisabledForeground
        $graphicsAutomationPropertyForSelector = $graphicsPrimaryAutomationProperty
        $graphicsEnabledAutomationIdForSelector = $graphicsEnabledAutomationId
        $graphicsDisabledAutomationIdForSelector = $graphicsDisabledAutomationId
        $refreshGraphicsGpuSelectionState = {
            $selectedItem = $graphicsGpuSelectorForSelector.SelectedItem
            $selectedGpuName = ''
            if ($selectedItem -is [System.Windows.Controls.ComboBoxItem]) {
                $selectedGpuName = [string]$selectedItem.Tag
            }
            $hasNvidiaSelection = ($selectedGpuName -eq 'NVIDIA')

            if ($graphicsPrimaryButtonForSelector -is [System.Windows.Controls.Button]) {
                if ($hasNvidiaSelection) {
                    $graphicsPrimaryButtonForSelector.IsEnabled = $true
                    $graphicsPrimaryButtonForSelector.Background = $graphicsEnabledBackgroundForSelector
                    $graphicsPrimaryButtonForSelector.BorderBrush = $graphicsEnabledBorderForSelector
                    $graphicsPrimaryButtonForSelector.Foreground = $graphicsEnabledForegroundForSelector
                    $graphicsPrimaryButtonForSelector.Effect = $graphicsEnabledEffectForSelector
                    $graphicsPrimaryButtonForSelector.SetValue($graphicsAutomationPropertyForSelector, $graphicsEnabledAutomationIdForSelector)
                    $graphicsPrimaryButtonForSelector.Resources['AxisFirstUseWizard.GraphicsGpuSetupSelectedGpu'] = $selectedGpuName
                }
                else {
                    $graphicsPrimaryButtonForSelector.IsEnabled = $false
                    $graphicsPrimaryButtonForSelector.Background = $graphicsDisabledBackgroundForSelector
                    $graphicsPrimaryButtonForSelector.BorderBrush = $graphicsDisabledBorderForSelector
                    $graphicsPrimaryButtonForSelector.Foreground = $graphicsDisabledForegroundForSelector
                    $graphicsPrimaryButtonForSelector.Effect = $null
                    $graphicsPrimaryButtonForSelector.SetValue($graphicsAutomationPropertyForSelector, $graphicsDisabledAutomationIdForSelector)
                    $graphicsPrimaryButtonForSelector.Resources['AxisFirstUseWizard.GraphicsGpuSetupSelectedGpu'] = ''
                }
            }
        }.GetNewClosure()

        $graphicsGpuSelector.Add_SelectionChanged({
            & $refreshGraphicsGpuSelectionState
        }.GetNewClosure())
        & $refreshGraphicsGpuSelectionState
    }

    if ($actionSelector -is [System.Windows.Controls.ComboBox]) {
        $actionPrimaryButton = $null
        foreach ($actionChild in @($primaryAction.Children)) {
            if ($actionChild -is [System.Windows.Controls.StackPanel] -and [string]$actionChild.Tag -eq 'AxisFirstUseWizard.PrimaryActionButtonRow') {
                foreach ($buttonCandidate in @($actionChild.Children)) {
                    if ($buttonCandidate -is [System.Windows.Controls.Button] -and [string]$buttonCandidate.Tag -eq 'AxisFirstUseWizard.PrimaryOpenButton') {
                        $actionPrimaryButton = $buttonCandidate
                        break
                    }
                }
            }
        }

        $actionPrimaryBackground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.PrimaryButton'
        $actionPrimaryBorder = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.PrimaryButtonHover'
        $actionPrimaryForeground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.PrimaryButtonText'
        $actionPrimaryEffect = New-AxisWizardShadowEffect -Opacity 0.16 -BlurRadius 16 -ShadowDepth 3
        $actionDisabledBackground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.SurfaceSoft'
        $actionDisabledBorder = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.BorderSoft'
        $actionDisabledForeground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.TextMuted'
        $actionPrimaryAutomationProperty = [System.Windows.Automation.AutomationProperties]::AutomationIdProperty
        $actionEnabledAutomationId = 'AxisFirstUseWizard.WindowsBloatwarePrimaryEnabledWithActionSelection'
        $actionDisabledAutomationId = 'AxisFirstUseWizard.WindowsBloatwarePrimaryDisabledUntilActionSelected'
        if ($actionPrimaryButton -is [System.Windows.Controls.Button]) {
            $actionPrimaryButton.SetValue($actionPrimaryAutomationProperty, $actionDisabledAutomationId)
            $actionPrimaryButton.Resources['AxisFirstUseWizard.WindowsBloatwareSelectedAction'] = ''
        }

        $actionPrimaryButtonForSelector = $actionPrimaryButton
        $actionSelectorForSelector = $actionSelector
        $actionEnabledBackgroundForSelector = $actionPrimaryBackground
        $actionEnabledBorderForSelector = $actionPrimaryBorder
        $actionEnabledForegroundForSelector = $actionPrimaryForeground
        $actionEnabledEffectForSelector = $actionPrimaryEffect
        $actionDisabledBackgroundForSelector = $actionDisabledBackground
        $actionDisabledBorderForSelector = $actionDisabledBorder
        $actionDisabledForegroundForSelector = $actionDisabledForeground
        $actionAutomationPropertyForSelector = $actionPrimaryAutomationProperty
        $actionEnabledAutomationIdForSelector = $actionEnabledAutomationId
        $actionDisabledAutomationIdForSelector = $actionDisabledAutomationId
        $refreshActionSelectionState = {
            $selectedItem = $actionSelectorForSelector.SelectedItem
            $selectedActionName = ''
            if ($selectedItem -is [System.Windows.Controls.ComboBoxItem]) {
                $selectedActionName = [string]$selectedItem.Tag
            }
            $hasActionSelection = (
                -not [string]::IsNullOrWhiteSpace($selectedActionName) -and
                $selectedActionName -ne 'AxisFirstUseWizard.WindowsBloatwareActionSelectorPlaceholderItem'
            )

            if ($actionPrimaryButtonForSelector -is [System.Windows.Controls.Button]) {
                if ($hasActionSelection) {
                    $actionPrimaryButtonForSelector.IsEnabled = $true
                    $actionPrimaryButtonForSelector.Background = $actionEnabledBackgroundForSelector
                    $actionPrimaryButtonForSelector.BorderBrush = $actionEnabledBorderForSelector
                    $actionPrimaryButtonForSelector.Foreground = $actionEnabledForegroundForSelector
                    $actionPrimaryButtonForSelector.Effect = $actionEnabledEffectForSelector
                    $actionPrimaryButtonForSelector.SetValue($actionAutomationPropertyForSelector, $actionEnabledAutomationIdForSelector)
                    $actionPrimaryButtonForSelector.Resources['AxisFirstUseWizard.WindowsBloatwareSelectedAction'] = $selectedActionName
                }
                else {
                    $actionPrimaryButtonForSelector.IsEnabled = $false
                    $actionPrimaryButtonForSelector.Background = $actionDisabledBackgroundForSelector
                    $actionPrimaryButtonForSelector.BorderBrush = $actionDisabledBorderForSelector
                    $actionPrimaryButtonForSelector.Foreground = $actionDisabledForegroundForSelector
                    $actionPrimaryButtonForSelector.Effect = $null
                    $actionPrimaryButtonForSelector.SetValue($actionAutomationPropertyForSelector, $actionDisabledAutomationIdForSelector)
                    $actionPrimaryButtonForSelector.Resources['AxisFirstUseWizard.WindowsBloatwareSelectedAction'] = ''
                }
            }
        }.GetNewClosure()

        $actionSelector.Add_SelectionChanged({
            & $refreshActionSelectionState
        }.GetNewClosure())
        & $refreshActionSelectionState
    }

    $container.Child = $content

    return $container
}

function New-AxisInstallersStep {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$Step,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    if ($null -eq $Step) {
        $Step = @((Get-AxisFirstUseWizardSampleState)['Steps'] | Where-Object { [string]$_['Id'] -eq 'installers' })[0]
    }

    $tagRoot = [string](Get-AxisWizardMapValue -Map $Step -Name 'TagRoot' -DefaultValue 'Installers')
    $catalogNames = @(Get-AxisWizardMapValue -Map $Step -Name 'InstallerCatalogNames' -DefaultValue @())

    $container = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Wizard.MainCardBackground' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderSoft' `
        -RadiusKey 'Axis.Radius.Wizard.MainCard' `
        -Padding (New-AxisWizardThickness -Left 34 -Top 4 -Right 34 -Bottom 2) `
        -Elevation 'Card'
    $container.Height = 382
    $container.Tag = 'AxisFirstUseWizard.InstallersStep'
    $container.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $container.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.InstallersNoClippingLayout')

    $content = [System.Windows.Controls.Grid]::new()
    $content.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $content.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $content.Tag = 'AxisFirstUseWizard.StepTextContent'

    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue 'Installers')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -FontWeightKey 'Axis.Type.Micro.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.AccentText' `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::LeftToRight)))

    $title = New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'Title' -DefaultValue (Get-AxisWizardArabicText -Name 'InstallersTitle'))) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.PageTitle.FontSize' `
        -FontWeightKey 'Axis.Type.PageTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.TextPrimary' `
        -Margin (New-AxisWizardThickness -Left 0 -Top 2 -Right 0 -Bottom 4) `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::RightToLeft)
    $title.Tag = 'AxisFirstUseWizard.InstallersTitleText'
    $title.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $title.TextWrapping = [System.Windows.TextWrapping]::NoWrap
    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisWizardRightAnchor `
        -Child $title `
        -Tag 'AxisFirstUseWizard.InstallersTitleRightAnchor' `
        -MaxWidth 690))

    $descriptionText = New-AxisWizardMixedBidiTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'Description')) `
        -Resources $Resources `
        -Tag 'AxisFirstUseWizard.InstallersSubtitle' `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -FontFamilyKey 'Axis.Type.BodySmall.FontFamily' `
        -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
        -MaxWidth 690
    $descriptionText.TextWrapping = [System.Windows.TextWrapping]::Wrap
    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisWizardRightAnchor `
        -Child $descriptionText `
        -Tag 'AxisFirstUseWizard.InstallersSubtitleRightAnchor' `
        -MaxWidth 690))

    $selectorGrid = [System.Windows.Controls.Grid]::new()
    $selectorGrid.Margin = New-AxisWizardThickness -Left 0 -Top 3 -Right 0 -Bottom 2
    $selectorGrid.Tag = 'AxisFirstUseWizard.InstallersSelectorRow'
    $selectorGrid.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $selectorGrid.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $selectorGrid.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.InstallersCatalogSelectorFromModuleSource')
    $selectorControlColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $selectorControlColumn.Width = [System.Windows.GridLength]::Auto
    $selectorLabelColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $selectorLabelColumn.Width = [System.Windows.GridLength]::Auto
    $selectorFillColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $selectorFillColumn.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    [void]$selectorGrid.ColumnDefinitions.Add($selectorControlColumn)
    [void]$selectorGrid.ColumnDefinitions.Add($selectorLabelColumn)
    [void]$selectorGrid.ColumnDefinitions.Add($selectorFillColumn)
    $selectorGrid.Resources['AxisFirstUseWizard.SelectorPhysicalLeftAboveRequirements'] = $true
    $selectorGrid.Resources['AxisFirstUseWizard.SelectorLabelPhysicalRightOfControl'] = $true
    $selectorGrid.Resources['AxisFirstUseWizard.InstallersSelectorPhysicalLeftAboveRequirements'] = $true

    $selectorLabel = New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'InstallerSelectorLabel' -DefaultValue (Get-AxisWizardArabicText -Name 'InstallersSelectorLabel'))) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -FontWeightKey 'Axis.Type.Micro.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::RightToLeft)
    $selectorLabel.Tag = 'AxisFirstUseWizard.InstallersSelectorLabel'
    $selectorLabel.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $selectorLabel.Margin = New-AxisWizardThickness -Left 12 -Top 0 -Right 0 -Bottom 0
    [System.Windows.Controls.Grid]::SetColumn($selectorLabel, 1)
    [void]$selectorGrid.Children.Add($selectorLabel)

    $programSelector = [System.Windows.Controls.ComboBox]::new()
    $programSelector.Tag = 'AxisFirstUseWizard.InstallersProgramSelector'
    $programSelector.Width = 318
    $programSelector.Height = 36
    $programSelector.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    $programSelector.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $programSelector.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $programSelector.IsEditable = $false
    $programSelector.MaxDropDownHeight = 190
    $programSelector.FontFamily = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontFamily'
    $programSelector.FontSize = [double](Get-AxisWizardResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontSize')
    Set-AxisWizardSelectorComboBoxStyle `
        -Selector $programSelector `
        -Resources $Resources `
        -FlowDirection ([System.Windows.FlowDirection]::LeftToRight) `
        -HorizontalContentAlignment ([System.Windows.HorizontalAlignment]::Left) `
        -Padding (New-AxisWizardThickness -Left 12 -Top 6 -Right 12 -Bottom 6)
    $programSelector.Resources['AxisFirstUseWizard.InstallersSelectorSingleSelect'] = $true
    $programSelector.Resources['AxisFirstUseWizard.InstallersCatalogSource'] = 'modules/Installers/installers.psm1'
    $programSelector.Resources['AxisFirstUseWizard.InstallersSelectorNoRuntimeAction'] = $true
    $programSelector.Resources['AxisFirstUseWizard.InstallersSelectorUsesSharedDarkAxisStyle'] = $true
    $programSelector.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.InstallersSingleSelectCatalogSelector')
    $installersPlaceholderItemStyle = New-AxisWizardSelectorComboBoxItemStyle -Resources $Resources -HorizontalContentAlignment ([System.Windows.HorizontalAlignment]::Right)
    $installersProgramItemStyle = New-AxisWizardSelectorComboBoxItemStyle -Resources $Resources -HorizontalContentAlignment ([System.Windows.HorizontalAlignment]::Left)

    $placeholderItem = [System.Windows.Controls.ComboBoxItem]::new()
    $placeholderItem.Content = [string](Get-AxisWizardMapValue -Map $Step -Name 'InstallerSelectorPlaceholder' -DefaultValue (Get-AxisWizardArabicText -Name 'InstallersSelectorPlaceholder'))
    $placeholderItem.Tag = 'AxisFirstUseWizard.InstallersSelectorPlaceholderItem'
    $placeholderItem.IsEnabled = $false
    $placeholderItem.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $placeholderItem.Style = $installersPlaceholderItemStyle
    [void]$programSelector.Items.Add($placeholderItem)
    foreach ($catalogName in @($catalogNames)) {
        $programItem = [System.Windows.Controls.ComboBoxItem]::new()
        $programItem.Content = [string]$catalogName
        $programItem.Tag = [string]$catalogName
        $programItem.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
        $programItem.HorizontalContentAlignment = [System.Windows.HorizontalAlignment]::Left
        $programItem.Style = $installersProgramItemStyle
        [void]$programSelector.Items.Add($programItem)
    }
    $programSelector.SelectedIndex = 0
    [System.Windows.Controls.Grid]::SetColumn($programSelector, 0)
    [void]$selectorGrid.Children.Add($programSelector)
    [void](Add-AxisWizardGridRow -Grid $content -Child $selectorGrid)

    $detailsGrid = [System.Windows.Controls.Grid]::new()
    $detailsGrid.Margin = New-AxisWizardThickness -Left 0 -Top 2 -Right 0 -Bottom 3
    $detailsGrid.Tag = 'AxisFirstUseWizard.InstallersStepDetails'
    $detailsGrid.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $detailsGrid.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $detailsGrid.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.InstallersCardsPhysicalOrderInfoRightRequirementsLeft')
    $requirementsColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $requirementsColumn.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $spacerColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $spacerColumn.Width = [System.Windows.GridLength]::new(12.0)
    $informationColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $informationColumn.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    [void]$detailsGrid.ColumnDefinitions.Add($requirementsColumn)
    [void]$detailsGrid.ColumnDefinitions.Add($spacerColumn)
    [void]$detailsGrid.ColumnDefinitions.Add($informationColumn)

    $cardTextMaxWidth = 340.0
    $cardHeight = 100.0
    $informationPanel = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Wizard.InfoCard' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderSoft' `
        -RadiusKey 'Axis.Radius.Wizard.InfoCard' `
        -Padding (New-AxisWizardThickness -Left 10 -Top 4 -Right 10 -Bottom 4) `
        -Elevation 'Soft'
    $informationPanel.Height = $cardHeight
    $informationPanel.Tag = 'AxisFirstUseWizard.InstallersInformationCard'
    $informationPanel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.InstallersInformationNoClipping')
    $informationPanel.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $informationPanel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $informationLines = [System.Collections.Generic.List[object]]::new()
    $informationLines.Add([ordered]@{
        Text = [string](Get-AxisWizardMapValue -Map $Step -Name 'InformationCardTitle')
        Tag = 'AxisFirstUseWizard.InstallersInformationTitle'
        FontSizeKey = 'Axis.Type.BodySmall.FontSize'
        FontWeightKey = 'Axis.Type.CardTitle.FontWeight'
        FontFamilyKey = 'Axis.Type.BodySmall.FontFamily'
        ForegroundKey = 'Axis.Brush.Wizard.TextPrimary'
        Wrap = $true
        MaxWidth = $cardTextMaxWidth
    })
    foreach ($item in @(Get-AxisWizardMapValue -Map $Step -Name 'InformationItems' -DefaultValue @())) {
        $informationLines.Add([ordered]@{
            Text = [string]$item
            Tag = 'AxisFirstUseWizard.InstallersInformationItem'
            FontSizeKey = 'Axis.Type.Caption.FontSize'
            FontWeightKey = 'Axis.Type.Body.FontWeight'
            FontFamilyKey = 'Axis.Type.Caption.FontFamily'
            ForegroundKey = 'Axis.Brush.Wizard.TextSecondary'
            TopMargin = 2.0
            Wrap = $true
            MaxWidth = $cardTextMaxWidth
        })
    }
    $informationGroup = New-AxisSetupPhysicalRightEdgeTextGroup `
        -Tag 'AxisFirstUseWizard.InstallersInformationSharedPhysicalRightEdge' `
        -Resources $Resources `
        -MaxWidth $cardTextMaxWidth `
        -Lines $informationLines `
        -AutomationId 'AxisFirstUseWizard.InstallersMixedBidiSafeInfoText'
    $informationContent = [System.Windows.Controls.Grid]::new()
    $informationContent.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $informationContent.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $informationContent.MaxWidth = $cardTextMaxWidth
    $informationContent.Tag = 'AxisFirstUseWizard.InstallersInformationCardContent'
    [void](Add-AxisWizardGridRow -Grid $informationContent -Child $informationGroup)
    $informationPanel.Child = New-AxisWizardRightAnchor `
        -Child $informationContent `
        -Tag 'AxisFirstUseWizard.InstallersInformationRightAnchor' `
        -MaxWidth $cardTextMaxWidth
    [System.Windows.Controls.Grid]::SetColumn($informationPanel, 2)
    [void]$detailsGrid.Children.Add($informationPanel)

    $requirementsPanel = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Wizard.InfoCard' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderSoft' `
        -RadiusKey 'Axis.Radius.Wizard.InfoCard' `
        -Padding (New-AxisWizardThickness -Left 10 -Top 4 -Right 10 -Bottom 4) `
        -Elevation 'Soft'
    $requirementsPanel.Height = $cardHeight
    $requirementsPanel.Tag = 'AxisFirstUseWizard.InstallersRequirementsCard'
    $requirementsPanel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.InstallersRequirementsNoClipping')
    $requirementsPanel.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $requirementsPanel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $requirementsLines = [System.Collections.Generic.List[object]]::new()
    $requirementsLines.Add([ordered]@{
        Text = [string](Get-AxisWizardMapValue -Map $Step -Name 'RequirementsTitle' -DefaultValue (Get-AxisWizardArabicText -Name 'RequirementsTitle'))
        Tag = 'AxisFirstUseWizard.InstallersRequirementsTitle'
        FontSizeKey = 'Axis.Type.BodySmall.FontSize'
        FontWeightKey = 'Axis.Type.CardTitle.FontWeight'
        FontFamilyKey = 'Axis.Type.BodySmall.FontFamily'
        ForegroundKey = 'Axis.Brush.Wizard.TextPrimary'
        Wrap = $true
        MaxWidth = $cardTextMaxWidth
    })
    foreach ($item in @(Get-AxisWizardMapValue -Map $Step -Name 'RequirementsItems' -DefaultValue @())) {
        $requirementsLines.Add([ordered]@{
            Text = [string]$item
            Tag = 'AxisFirstUseWizard.InstallersRequirementItem'
            FontSizeKey = 'Axis.Type.Caption.FontSize'
            FontWeightKey = 'Axis.Type.Body.FontWeight'
            FontFamilyKey = 'Axis.Type.Caption.FontFamily'
            ForegroundKey = 'Axis.Brush.Wizard.TextSecondary'
            TopMargin = 2.0
            Wrap = $true
            MaxWidth = $cardTextMaxWidth
        })
    }
    $requirementsGroup = New-AxisSetupPhysicalRightEdgeTextGroup `
        -Tag 'AxisFirstUseWizard.InstallersRequirementsSharedPhysicalRightEdge' `
        -Resources $Resources `
        -MaxWidth $cardTextMaxWidth `
        -Lines $requirementsLines `
        -AutomationId 'AxisFirstUseWizard.InstallersMixedBidiSafeRequirementsText'
    $requirementsContent = [System.Windows.Controls.Grid]::new()
    $requirementsContent.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $requirementsContent.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $requirementsContent.MaxWidth = $cardTextMaxWidth
    $requirementsContent.Tag = 'AxisFirstUseWizard.InstallersRequirementsCardContent'
    [void](Add-AxisWizardGridRow -Grid $requirementsContent -Child $requirementsGroup)
    $requirementsPanel.Child = New-AxisWizardRightAnchor `
        -Child $requirementsContent `
        -Tag 'AxisFirstUseWizard.InstallersRequirementsRightAnchor' `
        -MaxWidth $cardTextMaxWidth
    [System.Windows.Controls.Grid]::SetColumn($requirementsPanel, 0)
    [void]$detailsGrid.Children.Add($requirementsPanel)
    [void](Add-AxisWizardGridRow -Grid $content -Child $detailsGrid)

    $selectedProgramDisplay = [System.Windows.Controls.Grid]::new()
    $selectedProgramDisplay.Tag = 'AxisFirstUseWizard.InstallersSelectedProgramDisplay'
    $selectedProgramDisplay.Visibility = [System.Windows.Visibility]::Collapsed
    $selectedProgramDisplay.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $selectedProgramDisplay.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $selectedProgramDisplay.Margin = New-AxisWizardThickness -Left 0 -Top 0 -Right 0 -Bottom 1
    $selectedProgramDisplay.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.InstallersSelectedProgramBidiSafeDisplay')
    $selectedProgramNameColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $selectedProgramNameColumn.Width = [System.Windows.GridLength]::Auto
    $selectedProgramSpacerColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $selectedProgramSpacerColumn.Width = [System.Windows.GridLength]::new(8.0)
    $selectedProgramPrefixColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $selectedProgramPrefixColumn.Width = [System.Windows.GridLength]::Auto
    [void]$selectedProgramDisplay.ColumnDefinitions.Add($selectedProgramNameColumn)
    [void]$selectedProgramDisplay.ColumnDefinitions.Add($selectedProgramSpacerColumn)
    [void]$selectedProgramDisplay.ColumnDefinitions.Add($selectedProgramPrefixColumn)

    $selectedProgramName = New-AxisWizardTextBlock `
        -Text ' ' `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.Caption.FontSize' `
        -FontWeightKey 'Axis.Type.Micro.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.TextPrimary' `
        -TextAlignment ([System.Windows.TextAlignment]::Left) `
        -FlowDirection ([System.Windows.FlowDirection]::LeftToRight)
    $selectedProgramName.Tag = 'AxisFirstUseWizard.InstallersSelectedProgramName'
    $selectedProgramName.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    [System.Windows.Controls.Grid]::SetColumn($selectedProgramName, 0)
    [void]$selectedProgramDisplay.Children.Add($selectedProgramName)

    $selectedProgramPrefix = New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'InstallerSelectedProgramPrefix' -DefaultValue (Get-AxisWizardArabicText -Name 'InstallersSelectedProgramPrefix'))) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.Caption.FontSize' `
        -FontWeightKey 'Axis.Type.Micro.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::RightToLeft)
    $selectedProgramPrefix.Tag = 'AxisFirstUseWizard.InstallersSelectedProgramPrefix'
    [System.Windows.Controls.Grid]::SetColumn($selectedProgramPrefix, 2)
    [void]$selectedProgramDisplay.Children.Add($selectedProgramPrefix)
    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisWizardRightAnchor `
        -Child $selectedProgramDisplay `
        -Tag 'AxisFirstUseWizard.InstallersSelectedProgramRightAnchor' `
        -MaxWidth 690 `
        -PreserveChildFlowDirection))

    $installersPrimaryAction = New-AxisStepPrimaryActionArea -Step $Step -Resources $Resources
    $installersPrimaryAction.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.InstallersSimulationOnlyActionRow')
    [void](Add-AxisWizardGridRow -Grid $content -Child $installersPrimaryAction)
    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisStepSupportPanel -Step $Step -Resources $Resources))

    $installersPrimaryButton = $null
    foreach ($actionChild in @($installersPrimaryAction.Children)) {
        if ($actionChild -is [System.Windows.Controls.StackPanel] -and [string]$actionChild.Tag -eq 'AxisFirstUseWizard.PrimaryActionButtonRow') {
            foreach ($buttonCandidate in @($actionChild.Children)) {
                if ($buttonCandidate -is [System.Windows.Controls.Button] -and [string]$buttonCandidate.Tag -eq 'AxisFirstUseWizard.PrimaryOpenButton') {
                    $installersPrimaryButton = $buttonCandidate
                    break
                }
            }
        }
    }

    $installersPrimaryBackground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.PrimaryButton'
    $installersPrimaryBorder = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.PrimaryButtonHover'
    $installersPrimaryForeground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.PrimaryButtonText'
    $installersPrimaryEffect = New-AxisWizardShadowEffect -Opacity 0.16 -BlurRadius 16 -ShadowDepth 3
    $installersDisabledBackground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.SurfaceSoft'
    $installersDisabledBorder = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.BorderSoft'
    $installersDisabledForeground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.TextMuted'
    $installersPrimaryAutomationProperty = [System.Windows.Automation.AutomationProperties]::AutomationIdProperty
    $installersEnabledAutomationId = 'AxisFirstUseWizard.InstallersInstallEnabledWithProgramSelection'
    $installersDisabledAutomationId = 'AxisFirstUseWizard.InstallersInstallDisabledUntilProgramSelected'
    $epicCatalogDisplayName = [string](Get-AxisWizardMapValue -Map $Step -Name 'InstallerEpicCatalogDisplayName' -DefaultValue 'Epic Games')
    if ($installersPrimaryButton -is [System.Windows.Controls.Button]) {
        $installersPrimaryButton.SetValue($installersPrimaryAutomationProperty, $installersDisabledAutomationId)
    }

    $primaryButtonForSelector = $installersPrimaryButton
    $selectedProgramDisplayForSelector = $selectedProgramDisplay
    $selectedProgramNameForSelector = $selectedProgramName
    $programSelectorForSelector = $programSelector
    $enabledBackgroundForSelector = $installersPrimaryBackground
    $enabledBorderForSelector = $installersPrimaryBorder
    $enabledForegroundForSelector = $installersPrimaryForeground
    $enabledEffectForSelector = $installersPrimaryEffect
    $disabledBackgroundForSelector = $installersDisabledBackground
    $disabledBorderForSelector = $installersDisabledBorder
    $disabledForegroundForSelector = $installersDisabledForeground
    $automationPropertyForSelector = $installersPrimaryAutomationProperty
    $enabledAutomationIdForSelector = $installersEnabledAutomationId
    $disabledAutomationIdForSelector = $installersDisabledAutomationId
    $epicCatalogDisplayNameForSelector = $epicCatalogDisplayName
    $refreshInstallersSelectionState = {
        $selectedItem = $programSelectorForSelector.SelectedItem
        $selectedProgramNameValue = ''
        if ($selectedItem -is [System.Windows.Controls.ComboBoxItem]) {
            $selectedProgramNameValue = [string]$selectedItem.Tag
        }
        $hasProgramSelection = (
            -not [string]::IsNullOrWhiteSpace($selectedProgramNameValue) -and
            $selectedProgramNameValue -ne 'AxisFirstUseWizard.InstallersSelectorPlaceholderItem'
        )

        if ($hasProgramSelection) {
            $selectedProgramNameForSelector.Text = $selectedProgramNameValue
            $selectedProgramDisplayForSelector.Visibility = [System.Windows.Visibility]::Visible
            $isEpicProgramSelection = ($selectedProgramNameValue -eq $epicCatalogDisplayNameForSelector -or $selectedProgramNameValue -eq 'Epic Games Launcher')
            if ($primaryButtonForSelector -is [System.Windows.Controls.Button]) {
                $primaryButtonForSelector.IsEnabled = $true
                $primaryButtonForSelector.Background = $enabledBackgroundForSelector
                $primaryButtonForSelector.BorderBrush = $enabledBorderForSelector
                $primaryButtonForSelector.Foreground = $enabledForegroundForSelector
                $primaryButtonForSelector.Effect = $enabledEffectForSelector
                $primaryButtonForSelector.SetValue($automationPropertyForSelector, $enabledAutomationIdForSelector)
                $primaryButtonForSelector.Resources['AxisFirstUseWizard.InstallersSelectedProgram'] = $selectedProgramNameValue
                $primaryButtonForSelector.Resources['AxisFirstUseWizard.InstallersEpicSelected'] = [bool]$isEpicProgramSelection
            }
        }
        else {
            $selectedProgramNameForSelector.Text = ''
            $selectedProgramDisplayForSelector.Visibility = [System.Windows.Visibility]::Collapsed
            if ($primaryButtonForSelector -is [System.Windows.Controls.Button]) {
                $primaryButtonForSelector.IsEnabled = $false
                $primaryButtonForSelector.Background = $disabledBackgroundForSelector
                $primaryButtonForSelector.BorderBrush = $disabledBorderForSelector
                $primaryButtonForSelector.Foreground = $disabledForegroundForSelector
                $primaryButtonForSelector.Effect = $null
                $primaryButtonForSelector.SetValue($automationPropertyForSelector, $disabledAutomationIdForSelector)
                $primaryButtonForSelector.Resources['AxisFirstUseWizard.InstallersSelectedProgram'] = ''
                $primaryButtonForSelector.Resources['AxisFirstUseWizard.InstallersEpicSelected'] = $false
            }
        }
    }.GetNewClosure()

    $programSelector.Add_SelectionChanged({
        & $refreshInstallersSelectionState
    }.GetNewClosure())
    & $refreshInstallersSelectionState

    $container.Child = $content

    return $container
}

function Split-AxisInstallersEpicInstructionVisualLines {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$Text,

        [int]$InstructionIndex = 0
    )

    $lineText = [string]$Text
    if ([string]::IsNullOrWhiteSpace($lineText)) {
        return @()
    }

    if ($InstructionIndex -eq 0) {
        $arabicComma = [string][char]0x060C
        $commaIndex = $lineText.IndexOf($arabicComma, [System.StringComparison]::Ordinal)
        if ($commaIndex -gt 0 -and $commaIndex -lt ($lineText.Length - 1)) {
            return @(
                $lineText.Substring(0, $commaIndex + 1).Trim()
                $lineText.Substring($commaIndex + 1).Trim()
            )
        }
    }
    elseif ($InstructionIndex -eq 1) {
        $breakPhrase = ConvertFrom-AxisWizardCodePoints @(0x0645, 0x0646, 0x0020, 0x0645, 0x062B, 0x0628, 0x062A, 0x0020, 0x0045, 0x0070, 0x0069, 0x0063, 0x0020, 0x0047, 0x0061, 0x006D, 0x0065, 0x0073, 0x002E)
        $breakIndex = $lineText.IndexOf($breakPhrase, [System.StringComparison]::Ordinal)
        if ($breakIndex -gt 0) {
            return @(
                $lineText.Substring(0, $breakIndex).Trim()
                $lineText.Substring($breakIndex).Trim()
            )
        }
    }

    return @($lineText.Trim())
}

function New-AxisInstallersEpicInstructionBodyGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Step,

        [Parameter(Mandatory)]
        [object]$Resources,

        [double]$MaxWidth = 560.0
    )

    $group = [System.Windows.Controls.Grid]::new()
    $group.Tag = 'AxisFirstUseWizard.InstallersEpicInstructionBodySharedPhysicalRightEdge'
    $group.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $group.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $group.MaxWidth = $MaxWidth
    $group.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.InstallersEpicInstructionMixedBidiSafeVisualLines')
    $group.Resources['AxisFirstUseWizard.InstallersEpicInstructionVisualLinesRightAligned'] = $true
    $group.Resources['AxisFirstUseWizard.InstallersEpicInstructionNoOrphanEnglishTokens'] = $true
    $group.Resources['AxisFirstUseWizard.InstallersEpicInstructionNoLeftFloatingWrappedArabicLines'] = $true

    $rightColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $rightColumn.Width = [System.Windows.GridLength]::Auto
    [void]$group.ColumnDefinitions.Add($rightColumn)

    $instructionItems = @(Get-AxisWizardMapValue -Map $Step -Name 'InstallerEpicInstructionOverlayItems' -DefaultValue @())
    for ($instructionIndex = 0; $instructionIndex -lt $instructionItems.Count; $instructionIndex++) {
        $instructionItemText = [string]$instructionItems[$instructionIndex]
        if ([string]::IsNullOrWhiteSpace($instructionItemText)) {
            continue
        }

        $itemContainer = [System.Windows.Controls.Grid]::new()
        $itemContainer.Tag = 'AxisFirstUseWizard.InstallersEpicInstructionBodyItem'
        $itemContainer.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
        $itemContainer.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
        $itemContainer.MaxWidth = $MaxWidth
        $itemContainer.Margin = New-AxisWizardThickness -Left 0 -Top 6 -Right 0 -Bottom 0
        $itemContainer.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.InstallersEpicInstructionBodyItemVisualLineGroup')
        $itemContainer.Resources['AxisFirstUseWizard.InstallersEpicInstructionOriginalText'] = $instructionItemText

        $itemColumn = [System.Windows.Controls.ColumnDefinition]::new()
        $itemColumn.Width = [System.Windows.GridLength]::Auto
        [void]$itemContainer.ColumnDefinitions.Add($itemColumn)

        foreach ($visualLine in @(Split-AxisInstallersEpicInstructionVisualLines -Text $instructionItemText -InstructionIndex $instructionIndex)) {
            $visualLineText = [string]$visualLine
            if ([string]::IsNullOrWhiteSpace($visualLineText)) {
                continue
            }

            $textBlock = New-AxisWizardMixedBidiTextBlock `
                -Text $visualLineText `
                -Resources $Resources `
                -Tag 'AxisFirstUseWizard.InstallersEpicInstructionBodyVisualLine' `
                -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
                -FontWeightKey 'Axis.Type.Body.FontWeight' `
                -FontFamilyKey 'Axis.Type.BodySmall.FontFamily' `
                -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
                -MaxWidth $MaxWidth
            $textBlock.TextWrapping = [System.Windows.TextWrapping]::NoWrap
            $textBlock.TextAlignment = [System.Windows.TextAlignment]::Right
            $textBlock.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
            $textBlock.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.InstallersEpicInstructionRightAlignedNoWrapMixedBidiLine')
            [System.Windows.Controls.Grid]::SetColumn($textBlock, 0)
            [void](Add-AxisWizardGridRow -Grid $itemContainer -Child $textBlock)
        }

        [System.Windows.Controls.Grid]::SetColumn($itemContainer, 0)
        [void](Add-AxisWizardGridRow -Grid $group -Child $itemContainer)
    }

    return $group
}

function New-AxisInstallersEpicInstructionOverlay {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Step,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    $overlay = [System.Windows.Controls.Border]::new()
    $overlay.Tag = 'AxisFirstUseWizard.InstallersEpicInstructionOverlay'
    $overlay.Visibility = [System.Windows.Visibility]::Collapsed
    $overlay.Background = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.ColorConverter]::ConvertFromString('#CC080808'))
    $overlay.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $overlay.Padding = New-AxisWizardThickness -Left 140 -Top 116 -Right 140 -Bottom 116
    $overlay.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.InstallersEpicInstructionOverlayNoCheckbox')

    $card = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Wizard.ElevatedCard' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderStrong' `
        -RadiusKey 'Axis.Radius.Wizard.MainCard' `
        -Padding (New-AxisWizardThickness -Left 24 -Top 22 -Right 24 -Bottom 20) `
        -Elevation 'Card'
    $card.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $card.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $card.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $card.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.InstallersEpicInstructionCardFits900x650')

    $stack = [System.Windows.Controls.Grid]::new()
    $stack.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $stack.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $stack.Tag = 'AxisFirstUseWizard.InstallersEpicInstructionContent'

    $title = New-AxisWizardMixedBidiTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'InstallerEpicInstructionOverlayTitle' -DefaultValue (Get-AxisWizardArabicText -Name 'InstallersEpicOverlayTitle'))) `
        -Resources $Resources `
        -Tag 'AxisFirstUseWizard.InstallersEpicInstructionTitle' `
        -FontSizeKey 'Axis.Type.SectionTitle.FontSize' `
        -FontWeightKey 'Axis.Type.SectionTitle.FontWeight' `
        -FontFamilyKey 'Axis.Type.SectionTitle.FontFamily' `
        -ForegroundKey 'Axis.Brush.Wizard.TextPrimary' `
        -MaxWidth 500
    $title.TextAlignment = [System.Windows.TextAlignment]::Right
    $title.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    [void](Add-AxisWizardGridRow -Grid $stack -Child (New-AxisWizardRightAnchor `
        -Child $title `
        -Tag 'AxisFirstUseWizard.InstallersEpicInstructionTitleRightAnchor' `
        -MaxWidth 500))

    $bodyGroup = New-AxisInstallersEpicInstructionBodyGroup `
        -Step $Step `
        -Resources $Resources `
        -MaxWidth 560
    $bodyContent = [System.Windows.Controls.Grid]::new()
    $bodyContent.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $bodyContent.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $bodyContent.MaxWidth = 560
    $bodyContent.Margin = New-AxisWizardThickness -Left 0 -Top 8 -Right 0 -Bottom 0
    $bodyContent.Tag = 'AxisFirstUseWizard.InstallersEpicInstructionBodyContent'
    [void](Add-AxisWizardGridRow -Grid $bodyContent -Child $bodyGroup)
    [void](Add-AxisWizardGridRow -Grid $stack -Child (New-AxisWizardRightAnchor `
        -Child $bodyContent `
        -Tag 'AxisFirstUseWizard.InstallersEpicInstructionBodyRightAnchor' `
        -MaxWidth 560))

    $buttonRow = [System.Windows.Controls.StackPanel]::new()
    $buttonRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $buttonRow.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $buttonRow.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $buttonRow.Margin = New-AxisWizardThickness -Left 0 -Top 18 -Right 0 -Bottom 0
    $buttonRow.Tag = 'AxisFirstUseWizard.InstallersEpicInstructionButtonArea'

    $installButton = New-AxisWizardButton `
        -Text 'Install' `
        -Resources $Resources `
        -Variant 'Primary' `
        -Enabled $true `
        -Width 118 `
        -Height 40 `
        -Margin (New-AxisWizardThickness -Left 0)
    $installButton.Tag = 'AxisFirstUseWizard.InstallersEpicInstructionInstallButton'
    $installButton.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.InstallersEpicInstructionInstallStartsSimulationOnly')

    $returnButton = New-AxisWizardButton `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'InstallerEpicInstructionOverlayReturnLabel' -DefaultValue (Get-AxisWizardArabicText -Name 'InstallersEpicOverlayReturn'))) `
        -Resources $Resources `
        -Variant 'Quiet' `
        -Enabled $true `
        -Width 104 `
        -Height 40 `
        -Margin (New-AxisWizardThickness -Left 0)
    $returnButton.Tag = 'AxisFirstUseWizard.InstallersEpicInstructionReturnButton'
    $returnButton.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.InstallersEpicInstructionReturnOnlyClosesOverlay')

    [void]$buttonRow.Children.Add($installButton)
    [void]$buttonRow.Children.Add((New-AxisWizardSpacer -Width 12 -Tag 'AxisFirstUseWizard.InstallersEpicInstructionButtonSpacer'))
    [void]$buttonRow.Children.Add($returnButton)
    [void](Add-AxisWizardGridRow -Grid $stack -Child $buttonRow)

    $card.Child = $stack
    $overlay.Child = $card

    return $overlay
}

function New-AxisBiosInformationStep {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$Step,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    if ($null -eq $Step) {
        $Step = (Get-AxisFirstUseWizardSampleState)['Step']
    }

    $stepId = [string](Get-AxisWizardMapValue -Map $Step -Name 'Id' -DefaultValue 'bios-information')
    $isToBiosStep = ($stepId -eq 'to-bios')
    $stepTag = if ($isToBiosStep) { 'AxisFirstUseWizard.ToBiosStep' } else { 'AxisFirstUseWizard.BiosInformationStep' }
    $defaultStage = if ($isToBiosStep) { 'Refresh' } else { 'Check' }
    $defaultTitle = if ($isToBiosStep) { Get-AxisWizardArabicText -Name 'ToBiosTitle' } else { 'BIOS Drivers & Downloads' }
    $informationCardTag = if ($isToBiosStep) { 'AxisFirstUseWizard.ToBiosInformationCard' } else { 'AxisFirstUseWizard.InformationCard' }
    $containerPadding = if ($isToBiosStep) {
        New-AxisWizardThickness -Left 34 -Top 14 -Right 34 -Bottom 10
    }
    else {
        New-AxisWizardThickness -Left 34 -Top 20 -Right 34 -Bottom 16
    }
    $descriptionFontSizeKey = if ($isToBiosStep) { 'Axis.Type.BodySmall.FontSize' } else { 'Axis.Type.Body.FontSize' }
    $detailsMargin = if ($isToBiosStep) {
        New-AxisWizardThickness -Left 0 -Top 6 -Right 0 -Bottom 5
    }
    else {
        New-AxisWizardThickness -Left 0 -Top 10 -Right 0 -Bottom 8
    }
    $informationCardPadding = if ($isToBiosStep) {
        New-AxisWizardThickness -Left 13 -Top 8 -Right 13 -Bottom 8
    }
    else {
        New-AxisWizardThickness -Left 15 -Top 10 -Right 15 -Bottom 10
    }

    $container = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Wizard.MainCardBackground' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderSoft' `
        -RadiusKey 'Axis.Radius.Wizard.MainCard' `
        -Padding $containerPadding `
        -Elevation 'Card'
    $container.Height = 382
    $container.Tag = $stepTag
    $container.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    if ($isToBiosStep) {
        $container.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.ToBiosNoClippingLayout')
    }

    $content = [System.Windows.Controls.Grid]::new()
    $content.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $content.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $content.Tag = 'AxisFirstUseWizard.StepTextContent'

    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue $defaultStage)) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -FontWeightKey 'Axis.Type.Micro.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.AccentText' `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::LeftToRight)))
    $titleText = [string](Get-AxisWizardMapValue -Map $Step -Name 'Title' -DefaultValue $defaultTitle)
    if ($isToBiosStep) {
        [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisWizardToBiosTitleRightAnchor `
            -Text $titleText `
            -Resources $Resources))
    }
    else {
        [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisWizardTextBlock `
            -Text $titleText `
            -Resources $Resources `
            -FontSizeKey 'Axis.Type.PageTitle.FontSize' `
            -FontWeightKey 'Axis.Type.PageTitle.FontWeight' `
            -ForegroundKey 'Axis.Brush.Wizard.TextPrimary' `
            -Margin (New-AxisWizardThickness -Left 0 -Top 4 -Right 0 -Bottom 8) `
            -TextAlignment ([System.Windows.TextAlignment]::Right) `
            -FlowDirection ([System.Windows.FlowDirection]::LeftToRight)))
    }
    $descriptionText = New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'Description')) `
        -Resources $Resources `
        -FontSizeKey $descriptionFontSizeKey `
        -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::RightToLeft) `
        -Wrap
    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisWizardRightAnchor `
        -Child $descriptionText `
        -Tag 'AxisFirstUseWizard.ArabicSubtitleRightAnchor' `
        -MaxWidth 690))

    $detailsGrid = [System.Windows.Controls.Grid]::new()
    $detailsGrid.Margin = $detailsMargin
    $detailsGrid.Tag = 'AxisFirstUseWizard.StepDetails'
    $detailsGrid.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $detailsGrid.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $detailColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $detailColumn.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    [void]$detailsGrid.ColumnDefinitions.Add($detailColumn)

    $checksPanel = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Wizard.InfoCard' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderSoft' `
        -RadiusKey 'Axis.Radius.Wizard.InfoCard' `
        -Padding $informationCardPadding `
        -Elevation 'Soft'
    $checksPanel.MinHeight = if ($isToBiosStep) { 90 } else { 96 }
    $checksPanel.Tag = $informationCardTag
    $checksPanel.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $checksPanel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $checksStack = [System.Windows.Controls.Grid]::new()
    $checksStack.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $checksStack.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $checksStack.MaxWidth = 650
    $checksStack.Tag = 'AxisFirstUseWizard.InformationCardContent'
    if ($isToBiosStep) {
        $informationPhysicalRightEdge = New-AxisToBiosInformationTextGroup `
            -Step $Step `
            -Resources $Resources `
            -MaxWidth 650
    }
    else {
        $informationLines = [System.Collections.Generic.List[object]]::new()
        $informationLines.Add([ordered]@{
            Text = [string](Get-AxisWizardMapValue -Map $Step -Name 'InformationCardTitle' -DefaultValue (Get-AxisWizardArabicText -Name 'InformationCardTitle'))
            Tag = 'AxisFirstUseWizard.InformationCardPhysicalRightTitle'
            FontSizeKey = 'Axis.Type.CardTitle.FontSize'
            FontWeightKey = 'Axis.Type.CardTitle.FontWeight'
            FontFamilyKey = 'Axis.Type.BodySmall.FontFamily'
            ForegroundKey = 'Axis.Brush.Wizard.TextPrimary'
        })
        foreach ($item in @(Get-AxisWizardMapValue -Map $Step -Name 'InformationItems' -DefaultValue @())) {
            $informationLines.Add([ordered]@{
                Text = [string]$item
                Tag = 'AxisFirstUseWizard.InformationCardPhysicalRightItem'
                FontSizeKey = 'Axis.Type.BodySmall.FontSize'
                FontWeightKey = 'Axis.Type.Body.FontWeight'
                FontFamilyKey = 'Axis.Type.BodySmall.FontFamily'
                ForegroundKey = 'Axis.Brush.Wizard.TextSecondary'
                TopMargin = 3.0
            })
        }
        $informationPhysicalRightEdge = New-AxisWizardPhysicalRightEdgeTextGroup `
            -Tag 'AxisFirstUseWizard.InformationCardSharedPhysicalRightEdge' `
            -Resources $Resources `
            -MaxWidth 650 `
            -Lines $informationLines
    }
    [void](Add-AxisWizardGridRow -Grid $checksStack -Child $informationPhysicalRightEdge)
    $checksPanel.Child = New-AxisWizardRightAnchor `
        -Child $checksStack `
        -Tag 'AxisFirstUseWizard.ArabicInfoCardRightAnchor' `
        -MaxWidth 650
    [System.Windows.Controls.Grid]::SetColumn($checksPanel, 0)
    [void]$detailsGrid.Children.Add($checksPanel)

    [void](Add-AxisWizardGridRow -Grid $content -Child $detailsGrid)

    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisStepPrimaryActionArea -Step $Step -Resources $Resources))
    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisStepSupportPanel -Step $Step -Resources $Resources))

    $container.Child = $content

    return $container
}

function New-AxisBiosSettingsStep {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$Step,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    if ($null -eq $Step) {
        $Step = @((Get-AxisFirstUseWizardSampleState)['Steps'])[1]
    }

    $container = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Wizard.MainCardBackground' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderSoft' `
        -RadiusKey 'Axis.Radius.Wizard.MainCard' `
        -Padding (New-AxisWizardThickness -Left 34 -Top 14 -Right 34 -Bottom 10) `
        -Elevation 'Card'
    $container.Height = 382
    $container.Tag = 'AxisFirstUseWizard.BiosSettingsStep'
    $container.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $container.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.BiosSettingsNoClippingLayout')

    $content = [System.Windows.Controls.Grid]::new()
    $content.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $content.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $content.Tag = 'AxisFirstUseWizard.StepTextContent'

    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue 'Check')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -FontWeightKey 'Axis.Type.Micro.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.AccentText' `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::LeftToRight)))
    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'Title' -DefaultValue 'BIOS Settings')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.PageTitle.FontSize' `
        -FontWeightKey 'Axis.Type.PageTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.TextPrimary' `
        -Margin (New-AxisWizardThickness -Left 0 -Top 4 -Right 0 -Bottom 4) `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::LeftToRight)))
    $descriptionText = New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'Description')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::RightToLeft) `
        -Wrap
    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisWizardRightAnchor `
        -Child $descriptionText `
        -Tag 'AxisFirstUseWizard.ArabicSubtitleRightAnchor' `
        -MaxWidth 690))

    $detailsGrid = [System.Windows.Controls.Grid]::new()
    $detailsGrid.Margin = New-AxisWizardThickness -Left 0 -Top 6 -Right 0 -Bottom 8
    $detailsGrid.Tag = 'AxisFirstUseWizard.BiosSettingsDetails'
    $detailsGrid.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $detailsGrid.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $detailsGrid.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.BiosSettingsNoClippingLayout')
    $informationColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $informationColumn.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    [void]$detailsGrid.ColumnDefinitions.Add($informationColumn)

    $informationPanel = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Wizard.InfoCard' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderSoft' `
        -RadiusKey 'Axis.Radius.Wizard.InfoCard' `
        -Padding (New-AxisWizardThickness -Left 11 -Top 7 -Right 11 -Bottom 7) `
        -Elevation 'Soft'
    $informationPanel.Height = 144
    $informationPanel.Tag = 'AxisFirstUseWizard.BiosSettingsInformationCard'
    $informationPanel.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $informationPanel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch

    $informationContent = [System.Windows.Controls.Grid]::new()
    $informationContent.Tag = 'AxisFirstUseWizard.BiosSettingsInformationCardContent'
    $informationContent.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $informationContent.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $informationContent.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.BiosSettingsCompactInformationColumns')

    $informationTopLines = [System.Collections.Generic.List[object]]::new()
    $informationTopLines.Add([ordered]@{
        Text = [string](Get-AxisWizardMapValue -Map $Step -Name 'InformationCardTitle')
        Tag = 'AxisFirstUseWizard.BiosSettingsInformationTitle'
        FontSizeKey = 'Axis.Type.BodySmall.FontSize'
        FontWeightKey = 'Axis.Type.CardTitle.FontWeight'
        FontFamilyKey = 'Axis.Type.BodySmall.FontFamily'
        ForegroundKey = 'Axis.Brush.Wizard.TextPrimary'
    })
    $informationTopGroup = New-AxisWizardPhysicalRightEdgeTextGroup `
        -Tag 'AxisFirstUseWizard.BiosSettingsInformationIntroSharedPhysicalRightEdge' `
        -Resources $Resources `
        -MaxWidth 650 `
        -Lines $informationTopLines
    [void](Add-AxisWizardGridRow -Grid $informationContent -Child (New-AxisWizardRightAnchor `
        -Child $informationTopGroup `
        -Tag 'AxisFirstUseWizard.BiosSettingsInformationIntroRightAnchor' `
        -MaxWidth 650))

    $hardwareGrid = [System.Windows.Controls.Grid]::new()
    $hardwareGrid.Margin = New-AxisWizardThickness -Left 0 -Top 5 -Right 0 -Bottom 0
    $hardwareGrid.Tag = 'AxisFirstUseWizard.BiosSettingsCompactHardwareGroups'
    $hardwareGrid.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $hardwareGrid.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $motherboardColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $motherboardColumn.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $hardwareSpacerColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $hardwareSpacerColumn.Width = [System.Windows.GridLength]::new(12.0)
    $processorColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $processorColumn.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    [void]$hardwareGrid.ColumnDefinitions.Add($motherboardColumn)
    [void]$hardwareGrid.ColumnDefinitions.Add($hardwareSpacerColumn)
    [void]$hardwareGrid.ColumnDefinitions.Add($processorColumn)

    $processorLines = [System.Collections.Generic.List[object]]::new()
    foreach ($item in @(Get-AxisWizardMapValue -Map $Step -Name 'VisibleProcessorItems' -DefaultValue @())) {
        $processorLines.Add([ordered]@{
            Text = [string]$item
            Tag = 'AxisFirstUseWizard.BiosSettingsProcessorItem'
            FontSizeKey = 'Axis.Type.Caption.FontSize'
            FontWeightKey = 'Axis.Type.Body.FontWeight'
            FontFamilyKey = 'Axis.Type.Caption.FontFamily'
            ForegroundKey = 'Axis.Brush.Wizard.TextSecondary'
            TopMargin = 1.0
            Wrap = $true
            MaxWidth = 300.0
        })
    }
    $processorGroup = New-AxisWizardPhysicalRightEdgeTextGroup `
        -Tag 'AxisFirstUseWizard.BiosSettingsProcessorSharedPhysicalRightEdge' `
        -Resources $Resources `
        -MaxWidth 300 `
        -Lines $processorLines
    [System.Windows.Controls.Grid]::SetColumn($processorGroup, 2)
    [void]$hardwareGrid.Children.Add($processorGroup)

    $motherboardLines = [System.Collections.Generic.List[object]]::new()
    $motherboardLines.Add([ordered]@{
        Text = [string](Get-AxisWizardMapValue -Map $Step -Name 'VisibleMotherboardUtility')
        Tag = 'AxisFirstUseWizard.BiosSettingsVisibleMsiUtility'
        FontSizeKey = 'Axis.Type.Caption.FontSize'
        FontWeightKey = 'Axis.Type.Body.FontWeight'
        FontFamilyKey = 'Axis.Type.Caption.FontFamily'
        ForegroundKey = 'Axis.Brush.Wizard.TextSecondary'
    })
    $motherboardGroup = New-AxisWizardPhysicalRightEdgeTextGroup `
        -Tag 'AxisFirstUseWizard.BiosSettingsMotherboardSharedPhysicalRightEdge' `
        -Resources $Resources `
        -MaxWidth 300 `
        -Lines $motherboardLines
    [System.Windows.Controls.Grid]::SetColumn($motherboardGroup, 0)
    [void]$hardwareGrid.Children.Add($motherboardGroup)

    [void](Add-AxisWizardGridRow -Grid $informationContent -Child $hardwareGrid)
    $informationPanel.Child = New-AxisWizardRightAnchor `
        -Child $informationContent `
        -Tag 'AxisFirstUseWizard.BiosSettingsArabicInfoCardRightAnchor' `
        -MaxWidth 650
    [System.Windows.Controls.Grid]::SetColumn($informationPanel, 0)
    [void]$detailsGrid.Children.Add($informationPanel)

    [void](Add-AxisWizardGridRow -Grid $content -Child $detailsGrid)
    $biosSettingsPrimaryAction = New-AxisStepPrimaryActionArea -Step $Step -Resources $Resources
    $biosSettingsPrimaryAction.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.BiosSettingsActionRowSeparated')
    [void](Add-AxisWizardGridRow -Grid $content -Child $biosSettingsPrimaryAction)
    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisStepSupportPanel -Step $Step -Resources $Resources))

    $container.Child = $content

    return $container
}

function New-AxisReinstallStep {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$Step,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    if ($null -eq $Step) {
        $Step = @((Get-AxisFirstUseWizardSampleState)['Steps'])[2]
    }

    $container = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Wizard.MainCardBackground' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderSoft' `
        -RadiusKey 'Axis.Radius.Wizard.MainCard' `
        -Padding (New-AxisWizardThickness -Left 34 -Top 14 -Right 34 -Bottom 10) `
        -Elevation 'Card'
    $container.Height = 382
    $container.Tag = 'AxisFirstUseWizard.ReinstallStep'
    $container.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $container.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.ReinstallNoClippingLayout')

    $content = [System.Windows.Controls.Grid]::new()
    $content.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $content.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $content.Tag = 'AxisFirstUseWizard.StepTextContent'

    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue 'Refresh')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -FontWeightKey 'Axis.Type.Micro.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.AccentText' `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::LeftToRight)))
    $reinstallTitleText = New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'Title' -DefaultValue (Get-AxisWizardArabicText -Name 'ReinstallTitle'))) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.PageTitle.FontSize' `
        -FontWeightKey 'Axis.Type.PageTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.TextPrimary' `
        -Margin (New-AxisWizardThickness -Left 0 -Top 4 -Right 0 -Bottom 4) `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::RightToLeft)
    $reinstallTitleText.Tag = 'AxisFirstUseWizard.ReinstallTitleText'
    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisWizardRightAnchor `
        -Child $reinstallTitleText `
        -Tag 'AxisFirstUseWizard.ReinstallTitleRightAligned' `
        -MaxWidth 690))
    $descriptionText = New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'Description')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::RightToLeft) `
        -Wrap
    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisWizardRightAnchor `
        -Child $descriptionText `
        -Tag 'AxisFirstUseWizard.ArabicSubtitleRightAnchor' `
        -MaxWidth 690))

    $detailsGrid = [System.Windows.Controls.Grid]::new()
    $detailsGrid.Margin = New-AxisWizardThickness -Left 0 -Top 6 -Right 0 -Bottom 8
    $detailsGrid.Tag = 'AxisFirstUseWizard.ReinstallDetails'
    $detailsGrid.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $detailsGrid.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $detailsGrid.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.ReinstallNoClippingLayout')
    $informationColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $informationColumn.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $spacerColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $spacerColumn.Width = [System.Windows.GridLength]::new(12.0)
    $requirementsColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $requirementsColumn.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    [void]$detailsGrid.ColumnDefinitions.Add($informationColumn)
    [void]$detailsGrid.ColumnDefinitions.Add($spacerColumn)
    [void]$detailsGrid.ColumnDefinitions.Add($requirementsColumn)

    $informationPanel = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Wizard.InfoCard' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderSoft' `
        -RadiusKey 'Axis.Radius.Wizard.InfoCard' `
        -Padding (New-AxisWizardThickness -Left 11 -Top 8 -Right 11 -Bottom 8) `
        -Elevation 'Soft'
    $informationPanel.Height = 118
    $informationPanel.Tag = 'AxisFirstUseWizard.ReinstallInformationCard'
    $informationPanel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.ReinstallInformationRightCard')
    $informationPanel.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $informationPanel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $informationLines = [System.Collections.Generic.List[object]]::new()
    $informationLines.Add([ordered]@{
        Text = [string](Get-AxisWizardMapValue -Map $Step -Name 'InformationCardTitle' -DefaultValue (Get-AxisWizardArabicText -Name 'ReinstallInfoTitle'))
        Tag = 'AxisFirstUseWizard.ReinstallInformationTitle'
        FontSizeKey = 'Axis.Type.BodySmall.FontSize'
        FontWeightKey = 'Axis.Type.CardTitle.FontWeight'
        FontFamilyKey = 'Axis.Type.BodySmall.FontFamily'
        ForegroundKey = 'Axis.Brush.Wizard.TextPrimary'
    })
    foreach ($item in @(Get-AxisWizardMapValue -Map $Step -Name 'InformationItems' -DefaultValue @())) {
        $informationLines.Add([ordered]@{
            Text = [string]$item
            Tag = 'AxisFirstUseWizard.ReinstallInformationItem'
            FontSizeKey = 'Axis.Type.Caption.FontSize'
            FontWeightKey = 'Axis.Type.Body.FontWeight'
            FontFamilyKey = 'Axis.Type.Caption.FontFamily'
            ForegroundKey = 'Axis.Brush.Wizard.TextSecondary'
            TopMargin = 3.0
            Wrap = $true
            MaxWidth = 320.0
        })
    }
    $informationGroup = New-AxisWizardPhysicalRightEdgeTextGroup `
        -Tag 'AxisFirstUseWizard.ReinstallInformationSharedPhysicalRightEdge' `
        -Resources $Resources `
        -MaxWidth 320 `
        -Lines $informationLines
    $informationGroup.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.ReinstallSharedPhysicalRightEdge')
    $informationContent = [System.Windows.Controls.Grid]::new()
    $informationContent.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $informationContent.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $informationContent.MaxWidth = 320
    $informationContent.Tag = 'AxisFirstUseWizard.ReinstallInformationCardContent'
    [void](Add-AxisWizardGridRow -Grid $informationContent -Child $informationGroup)
    $informationPanel.Child = New-AxisWizardRightAnchor `
        -Child $informationContent `
        -Tag 'AxisFirstUseWizard.ReinstallInformationRightAnchor' `
        -MaxWidth 320
    [System.Windows.Controls.Grid]::SetColumn($informationPanel, 2)
    [void]$detailsGrid.Children.Add($informationPanel)

    $requirementsPanel = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Wizard.InfoCard' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderSoft' `
        -RadiusKey 'Axis.Radius.Wizard.InfoCard' `
        -Padding (New-AxisWizardThickness -Left 11 -Top 8 -Right 11 -Bottom 8) `
        -Elevation 'Soft'
    $requirementsPanel.Height = 118
    $requirementsPanel.Tag = 'AxisFirstUseWizard.ReinstallRequirementsCard'
    $requirementsPanel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.ReinstallRequirementsLeftCard')
    $requirementsPanel.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $requirementsPanel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $requirementsLines = [System.Collections.Generic.List[object]]::new()
    $requirementsLines.Add([ordered]@{
        Text = [string](Get-AxisWizardMapValue -Map $Step -Name 'RequirementsTitle' -DefaultValue (Get-AxisWizardArabicText -Name 'RequirementsTitle'))
        Tag = 'AxisFirstUseWizard.ReinstallRequirementsTitle'
        FontSizeKey = 'Axis.Type.BodySmall.FontSize'
        FontWeightKey = 'Axis.Type.CardTitle.FontWeight'
        FontFamilyKey = 'Axis.Type.BodySmall.FontFamily'
        ForegroundKey = 'Axis.Brush.Wizard.TextPrimary'
    })
    foreach ($item in @(Get-AxisWizardMapValue -Map $Step -Name 'RequirementsItems' -DefaultValue @())) {
        $requirementsLines.Add([ordered]@{
            Text = [string]$item
            Tag = 'AxisFirstUseWizard.ReinstallRequirementItem'
            FontSizeKey = 'Axis.Type.Caption.FontSize'
            FontWeightKey = 'Axis.Type.Body.FontWeight'
            FontFamilyKey = 'Axis.Type.Caption.FontFamily'
            ForegroundKey = 'Axis.Brush.Wizard.TextSecondary'
            TopMargin = 3.0
            Wrap = $true
            MaxWidth = 320.0
        })
    }
    $requirementsGroup = New-AxisWizardPhysicalRightEdgeTextGroup `
        -Tag 'AxisFirstUseWizard.ReinstallRequirementsSharedPhysicalRightEdge' `
        -Resources $Resources `
        -MaxWidth 320 `
        -Lines $requirementsLines
    $requirementsGroup.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.ReinstallSharedPhysicalRightEdge')
    $requirementsContent = [System.Windows.Controls.Grid]::new()
    $requirementsContent.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $requirementsContent.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $requirementsContent.MaxWidth = 320
    $requirementsContent.Tag = 'AxisFirstUseWizard.ReinstallRequirementsCardContent'
    [void](Add-AxisWizardGridRow -Grid $requirementsContent -Child $requirementsGroup)
    $requirementsPanel.Child = New-AxisWizardRightAnchor `
        -Child $requirementsContent `
        -Tag 'AxisFirstUseWizard.ReinstallRequirementsRightAnchor' `
        -MaxWidth 320
    [System.Windows.Controls.Grid]::SetColumn($requirementsPanel, 0)
    [void]$detailsGrid.Children.Add($requirementsPanel)

    [void](Add-AxisWizardGridRow -Grid $content -Child $detailsGrid)
    $reinstallPrimaryAction = New-AxisStepPrimaryActionArea -Step $Step -Resources $Resources
    $reinstallPrimaryAction.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.ReinstallDirectSimulationActionRow')
    [void](Add-AxisWizardGridRow -Grid $content -Child $reinstallPrimaryAction)
    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisStepSupportPanel -Step $Step -Resources $Resources))

    $container.Child = $content

    return $container
}

function New-AxisAutoUnattendStep {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$Step,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    if ($null -eq $Step) {
        $Step = @((Get-AxisFirstUseWizardSampleState)['Steps'])[3]
    }

    $stepId = [string](Get-AxisWizardMapValue -Map $Step -Name 'Id' -DefaultValue 'unattended')
    $isUpdatesDriversStep = ($stepId -eq 'updates-drivers-block')
    $tagRoot = if ($isUpdatesDriversStep) { 'UpdatesDrivers' } else { 'AutoUnattend' }
    $defaultTitle = if ($isUpdatesDriversStep) { 'Updates Drivers Block' } else { 'AutoUnattend' }
    $stepTag = if ($isUpdatesDriversStep) { 'AxisFirstUseWizard.UpdatesDriversStep' } else { 'AxisFirstUseWizard.AutoUnattendStep' }
    $noClippingAutomationId = "AxisFirstUseWizard.${tagRoot}NoClippingLayout"

    $container = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Wizard.MainCardBackground' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderSoft' `
        -RadiusKey 'Axis.Radius.Wizard.MainCard' `
        -Padding (New-AxisWizardThickness -Left 34 -Top 12 -Right 34 -Bottom 8) `
        -Elevation 'Card'
    $container.Height = 382
    $container.Tag = $stepTag
    $container.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $container.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, $noClippingAutomationId)

    $content = [System.Windows.Controls.Grid]::new()
    $content.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $content.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $content.Tag = 'AxisFirstUseWizard.StepTextContent'

    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue 'Refresh')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -FontWeightKey 'Axis.Type.Micro.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.AccentText' `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::LeftToRight)))

    $titleText = New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'Title' -DefaultValue $defaultTitle)) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.PageTitle.FontSize' `
        -FontWeightKey 'Axis.Type.PageTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.TextPrimary' `
        -Margin (New-AxisWizardThickness -Left 0 -Top 4 -Right 0 -Bottom 4) `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::LeftToRight)
    $titleText.Tag = "AxisFirstUseWizard.${tagRoot}TitleText"
    $titleAnchor = New-AxisWizardRightAnchor `
        -Child $titleText `
        -Tag "AxisFirstUseWizard.${tagRoot}TitleRightAligned" `
        -MaxWidth 690
    $titleText.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    [void](Add-AxisWizardGridRow -Grid $content -Child $titleAnchor)

    $descriptionText = New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'Description')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::RightToLeft) `
        -Wrap
    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisWizardRightAnchor `
        -Child $descriptionText `
        -Tag 'AxisFirstUseWizard.ArabicSubtitleRightAnchor' `
        -MaxWidth 690))

    $detailsGrid = [System.Windows.Controls.Grid]::new()
    $detailsGrid.Margin = New-AxisWizardThickness -Left 0 -Top 5 -Right 0 -Bottom 5
    $detailsGrid.Tag = "AxisFirstUseWizard.${tagRoot}Details"
    $detailsGrid.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $detailsGrid.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $detailsGrid.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, $noClippingAutomationId)
    $informationColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $informationColumn.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $spacerColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $spacerColumn.Width = [System.Windows.GridLength]::new(12.0)
    $requirementsColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $requirementsColumn.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    [void]$detailsGrid.ColumnDefinitions.Add($informationColumn)
    [void]$detailsGrid.ColumnDefinitions.Add($spacerColumn)
    [void]$detailsGrid.ColumnDefinitions.Add($requirementsColumn)

    $informationPanel = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Wizard.InfoCard' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderSoft' `
        -RadiusKey 'Axis.Radius.Wizard.InfoCard' `
        -Padding (New-AxisWizardThickness -Left 10 -Top 2 -Right 10 -Bottom 2) `
        -Elevation 'Soft'
    $informationPanel.Height = 152
    $informationPanel.Tag = "AxisFirstUseWizard.${tagRoot}InformationCard"
    $informationPanel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, "AxisFirstUseWizard.${tagRoot}InformationRightCard")
    $informationPanel.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $informationPanel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch

    $informationGroup = if ($isUpdatesDriversStep) {
        New-AxisUpdatesDriversInformationTextGroup `
            -Step $Step `
            -Resources $Resources `
            -MaxWidth 320
    }
    else {
        New-AxisAutoUnattendInformationTextGroup `
            -Step $Step `
            -Resources $Resources `
            -MaxWidth 320
    }
    $informationContent = [System.Windows.Controls.Grid]::new()
    $informationContent.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $informationContent.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $informationContent.MaxWidth = 320
    $informationContent.Tag = "AxisFirstUseWizard.${tagRoot}InformationCardContent"
    $informationContent.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, "AxisFirstUseWizard.${tagRoot}InfoCardNoClipping")
    [void](Add-AxisWizardGridRow -Grid $informationContent -Child $informationGroup)
    $informationPanel.Child = New-AxisWizardRightAnchor `
        -Child $informationContent `
        -Tag "AxisFirstUseWizard.${tagRoot}InformationRightAnchor" `
        -MaxWidth 320
    [System.Windows.Controls.Grid]::SetColumn($informationPanel, 2)
    [void]$detailsGrid.Children.Add($informationPanel)

    $requirementsPanel = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Wizard.InfoCard' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderSoft' `
        -RadiusKey 'Axis.Radius.Wizard.InfoCard' `
        -Padding (New-AxisWizardThickness -Left 10 -Top 7 -Right 10 -Bottom 7) `
        -Elevation 'Soft'
    $requirementsPanel.Height = 152
    $requirementsPanel.Tag = "AxisFirstUseWizard.${tagRoot}RequirementsCard"
    $requirementsPanel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, "AxisFirstUseWizard.${tagRoot}RequirementsLeftCard")
    $requirementsPanel.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $requirementsPanel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $requirementsLines = [System.Collections.Generic.List[object]]::new()
    $requirementsLines.Add([ordered]@{
        Text = [string](Get-AxisWizardMapValue -Map $Step -Name 'RequirementsTitle' -DefaultValue (Get-AxisWizardArabicText -Name 'RequirementsTitle'))
        Tag = "AxisFirstUseWizard.${tagRoot}RequirementsTitle"
        FontSizeKey = 'Axis.Type.BodySmall.FontSize'
        FontWeightKey = 'Axis.Type.CardTitle.FontWeight'
        FontFamilyKey = 'Axis.Type.BodySmall.FontFamily'
        ForegroundKey = 'Axis.Brush.Wizard.TextPrimary'
    })
    foreach ($item in @(Get-AxisWizardMapValue -Map $Step -Name 'RequirementsItems' -DefaultValue @())) {
        $requirementsLines.Add([ordered]@{
            Text = [string]$item
            Tag = "AxisFirstUseWizard.${tagRoot}RequirementItem"
            FontSizeKey = 'Axis.Type.Caption.FontSize'
            FontWeightKey = 'Axis.Type.Body.FontWeight'
            FontFamilyKey = 'Axis.Type.Caption.FontFamily'
            ForegroundKey = 'Axis.Brush.Wizard.TextSecondary'
            TopMargin = 3.0
            Wrap = $true
            MaxWidth = 320.0
        })
    }
    $requirementsGroup = New-AxisWizardPhysicalRightEdgeTextGroup `
        -Tag "AxisFirstUseWizard.${tagRoot}RequirementsSharedPhysicalRightEdge" `
        -Resources $Resources `
        -MaxWidth 320 `
        -Lines $requirementsLines
    $requirementsGroup.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, "AxisFirstUseWizard.${tagRoot}SharedPhysicalRightEdge")
    $requirementsContent = [System.Windows.Controls.Grid]::new()
    $requirementsContent.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $requirementsContent.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $requirementsContent.MaxWidth = 320
    $requirementsContent.Tag = "AxisFirstUseWizard.${tagRoot}RequirementsCardContent"
    [void](Add-AxisWizardGridRow -Grid $requirementsContent -Child $requirementsGroup)
    $requirementsPanel.Child = New-AxisWizardRightAnchor `
        -Child $requirementsContent `
        -Tag "AxisFirstUseWizard.${tagRoot}RequirementsRightAnchor" `
        -MaxWidth 320
    [System.Windows.Controls.Grid]::SetColumn($requirementsPanel, 0)
    [void]$detailsGrid.Children.Add($requirementsPanel)

    [void](Add-AxisWizardGridRow -Grid $content -Child $detailsGrid)
    $inputPrimaryAction = New-AxisStepPrimaryActionArea -Step $Step -Resources $Resources
    $inputPrimaryAction.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, "AxisFirstUseWizard.${tagRoot}InputActionRow")
    [void](Add-AxisWizardGridRow -Grid $content -Child $inputPrimaryAction)
    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisStepSupportPanel -Step $Step -Resources $Resources))

    $container.Child = $content

    return $container
}

function New-AxisUpdatesDriversBlockStep {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$Step,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    if ($null -eq $Step) {
        $Step = @((Get-AxisFirstUseWizardSampleState)['Steps'])[4]
    }

    return New-AxisAutoUnattendStep -Step $Step -Resources $Resources
}

function New-AxisToBiosStep {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$Step,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    if ($null -eq $Step) {
        $Step = @((Get-AxisFirstUseWizardSampleState)['Steps'])[5]
    }

    return New-AxisBiosInformationStep -Step $Step -Resources $Resources
}

function New-AxisAutoUnattendInputOverlay {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Step,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    $requiresAccountName = [bool](Get-AxisWizardMapValue -Map $Step -Name 'RequiresAccountName' -DefaultValue $true)
    $overlayTag = [string](Get-AxisWizardMapValue -Map $Step -Name 'InputOverlayTag' -DefaultValue 'AxisFirstUseWizard.AutoUnattendInputOverlay')
    $cardAutomationId = [string](Get-AxisWizardMapValue -Map $Step -Name 'InputWindowCardAutomationId' -DefaultValue 'AxisFirstUseWizard.AutoUnattendInputWindowNoCheckbox')
    $contentTag = [string](Get-AxisWizardMapValue -Map $Step -Name 'InputWindowContentTag' -DefaultValue 'AxisFirstUseWizard.AutoUnattendInputWindowContent')
    $titleTag = [string](Get-AxisWizardMapValue -Map $Step -Name 'InputTitleTag' -DefaultValue 'AxisFirstUseWizard.AutoUnattendInputTitle')
    $titleAnchorTag = [string](Get-AxisWizardMapValue -Map $Step -Name 'InputTitleAnchorTag' -DefaultValue 'AxisFirstUseWizard.AutoUnattendInputTitleRightAnchor')
    $accountLabelTag = [string](Get-AxisWizardMapValue -Map $Step -Name 'InputAccountLabelTag' -DefaultValue 'AxisFirstUseWizard.AutoUnattendAccountLabel')
    $accountLabelAnchorTag = [string](Get-AxisWizardMapValue -Map $Step -Name 'InputAccountLabelAnchorTag' -DefaultValue 'AxisFirstUseWizard.AutoUnattendAccountLabelRightAnchor')
    $accountTextBoxTag = [string](Get-AxisWizardMapValue -Map $Step -Name 'InputAccountTextBoxTag' -DefaultValue 'AxisFirstUseWizard.AutoUnattendAccountTextBox')
    $accountInputAnchorTag = [string](Get-AxisWizardMapValue -Map $Step -Name 'InputAccountInputAnchorTag' -DefaultValue 'AxisFirstUseWizard.AutoUnattendAccountInputRightAnchor')
    $usbLabelTag = [string](Get-AxisWizardMapValue -Map $Step -Name 'InputUsbLabelTag' -DefaultValue 'AxisFirstUseWizard.AutoUnattendUsbLabel')
    $usbLabelAnchorTag = [string](Get-AxisWizardMapValue -Map $Step -Name 'InputUsbLabelAnchorTag' -DefaultValue 'AxisFirstUseWizard.AutoUnattendUsbLabelRightAnchor')
    $usbSelectorTag = [string](Get-AxisWizardMapValue -Map $Step -Name 'InputUsbSelectorTag' -DefaultValue 'AxisFirstUseWizard.AutoUnattendUsbSelector')
    $usbSelectorAnchorTag = [string](Get-AxisWizardMapValue -Map $Step -Name 'InputUsbSelectorAnchorTag' -DefaultValue 'AxisFirstUseWizard.AutoUnattendUsbSelectorRightAnchor')
    $buttonAreaTag = [string](Get-AxisWizardMapValue -Map $Step -Name 'InputButtonAreaTag' -DefaultValue 'AxisFirstUseWizard.AutoUnattendInputButtonArea')
    $createButtonTag = [string](Get-AxisWizardMapValue -Map $Step -Name 'InputCreateButtonTag' -DefaultValue 'AxisFirstUseWizard.AutoUnattendInputCreateButton')
    $createDisabledAutomationId = [string](Get-AxisWizardMapValue -Map $Step -Name 'InputCreateDisabledAutomationId' -DefaultValue 'AxisFirstUseWizard.AutoUnattendInputCreateDisabledUntilValid')
    $createEnabledAutomationId = [string](Get-AxisWizardMapValue -Map $Step -Name 'InputCreateEnabledAutomationId' -DefaultValue 'AxisFirstUseWizard.AutoUnattendInputCreateEnabledWithValidMockInput')
    $returnButtonTag = [string](Get-AxisWizardMapValue -Map $Step -Name 'InputReturnButtonTag' -DefaultValue 'AxisFirstUseWizard.AutoUnattendInputReturnButton')
    $returnAutomationId = [string](Get-AxisWizardMapValue -Map $Step -Name 'InputReturnAutomationId' -DefaultValue 'AxisFirstUseWizard.AutoUnattendInputReturnOnlyClosesOverlay')
    $returnSpacerTag = [string](Get-AxisWizardMapValue -Map $Step -Name 'InputReturnSpacerTag' -DefaultValue 'AxisFirstUseWizard.AutoUnattendInputReturnButtonSpacer')

    $overlay = [System.Windows.Controls.Border]::new()
    $overlay.Tag = $overlayTag
    $overlay.Visibility = [System.Windows.Visibility]::Collapsed
    $overlay.Background = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.ColorConverter]::ConvertFromString('#CC080808'))
    $overlay.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $overlay.Padding = New-AxisWizardThickness -Left 250 -Top 150 -Right 250 -Bottom 150

    $card = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Wizard.ElevatedCard' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderStrong' `
        -RadiusKey 'Axis.Radius.Wizard.MainCard' `
        -Padding (New-AxisWizardThickness -Left 22 -Top 20 -Right 22 -Bottom 20) `
        -Elevation 'Card'
    $card.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $card.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $card.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $card.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, $cardAutomationId)

    $stack = [System.Windows.Controls.Grid]::new()
    $stack.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $stack.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $stack.Tag = $contentTag

    $title = New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'InputWindowTitle' -DefaultValue (Get-AxisWizardArabicText -Name 'AutoUnattendInputTitle'))) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.SectionTitle.FontSize' `
        -FontWeightKey 'Axis.Type.SectionTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.TextPrimary' `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::RightToLeft)
    $title.Tag = $titleTag
    [void](Add-AxisWizardGridRow -Grid $stack -Child (New-AxisWizardRightAnchor `
        -Child $title `
        -Tag $titleAnchorTag `
        -MaxWidth 360))

    $accountBox = $null
    if ($requiresAccountName) {
        $accountLabel = New-AxisWizardTextBlock `
            -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'InputAccountLabel' -DefaultValue (Get-AxisWizardArabicText -Name 'AutoUnattendAccountLabel'))) `
            -Resources $Resources `
            -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
            -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
            -Margin (New-AxisWizardThickness -Left 0 -Top 14 -Right 0 -Bottom 4) `
            -TextAlignment ([System.Windows.TextAlignment]::Right) `
            -FlowDirection ([System.Windows.FlowDirection]::RightToLeft)
        $accountLabel.Tag = $accountLabelTag
        [void](Add-AxisWizardGridRow -Grid $stack -Child (New-AxisWizardRightAnchor `
            -Child $accountLabel `
            -Tag $accountLabelAnchorTag `
            -MaxWidth 360))

        $accountBox = [System.Windows.Controls.TextBox]::new()
        $accountBox.Tag = $accountTextBoxTag
        $accountBox.Width = 300
        $accountBox.Height = 34
        $accountBox.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
        $accountBox.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
        $accountBox.TextAlignment = [System.Windows.TextAlignment]::Right
        $accountBox.Padding = New-AxisWizardThickness -Left 10 -Top 6 -Right 10 -Bottom 6
        $accountBox.FontFamily = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontFamily'
        $accountBox.FontSize = [double](Get-AxisWizardResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontSize')
        $accountBox.Background = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.SurfaceSoft'
        $accountBox.BorderBrush = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.BorderStrong'
        $accountBox.Foreground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.TextPrimary'
        [void](Add-AxisWizardGridRow -Grid $stack -Child (New-AxisWizardRightAnchor `
            -Child $accountBox `
            -Tag $accountInputAnchorTag `
            -MaxWidth 360))
        $accountBox.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    }

    $usbLabel = New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'InputUsbLabel' -DefaultValue (Get-AxisWizardArabicText -Name 'AutoUnattendUsbLabel'))) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
        -Margin (New-AxisWizardThickness -Left 0 -Top 12 -Right 0 -Bottom 4) `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::RightToLeft)
    $usbLabel.Tag = $usbLabelTag
    [void](Add-AxisWizardGridRow -Grid $stack -Child (New-AxisWizardRightAnchor `
        -Child $usbLabel `
        -Tag $usbLabelAnchorTag `
        -MaxWidth 360))

    $usbSelector = [System.Windows.Controls.ComboBox]::new()
    $usbSelector.Tag = $usbSelectorTag
    $usbSelector.Width = 300
    $usbSelector.Height = 36
    $usbSelector.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $usbSelector.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $usbSelector.IsEditable = $false
    $usbSelector.MaxDropDownHeight = 160
    $usbSelector.FontFamily = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontFamily'
    $usbSelector.FontSize = [double](Get-AxisWizardResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontSize')
    Set-AxisWizardSelectorComboBoxStyle `
        -Selector $usbSelector `
        -Resources $Resources `
        -FlowDirection ([System.Windows.FlowDirection]::RightToLeft) `
        -HorizontalContentAlignment ([System.Windows.HorizontalAlignment]::Right) `
        -Padding (New-AxisWizardThickness -Left 10 -Top 6 -Right 12 -Bottom 6)
    $usbSelector.Resources['AxisFirstUseWizard.UsbSelectorReadableDarkStyle'] = $true
    $usbSelector.Resources['AxisFirstUseWizard.UsbSelectorMockOnly'] = $true
    $usbSelector.Resources['AxisFirstUseWizard.UsbInputWindowNoRealDriveDetection'] = $true
    $usbSelector.Resources['AxisFirstUseWizard.UsbSelectorUsesSharedDarkAxisStyle'] = $true
    $usbSelector.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.UsbSelectorReadableDarkStyle')
    foreach ($mockUsbItem in @(Get-AxisWizardMapValue -Map $Step -Name 'MockUsbItems' -DefaultValue @('USB'))) {
        [void]$usbSelector.Items.Add([string]$mockUsbItem)
    }
    $usbSelector.SelectedIndex = -1
    [void](Add-AxisWizardGridRow -Grid $stack -Child (New-AxisWizardRightAnchor `
        -Child $usbSelector `
        -Tag $usbSelectorAnchorTag `
        -MaxWidth 360))

    $buttonRow = [System.Windows.Controls.StackPanel]::new()
    $buttonRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $buttonRow.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $buttonRow.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $buttonRow.Margin = New-AxisWizardThickness -Left 0 -Top 16 -Right 0 -Bottom 0
    $buttonRow.Tag = $buttonAreaTag

    $createButton = New-AxisWizardButton `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'InputCreateLabel' -DefaultValue (Get-AxisWizardArabicText -Name 'AutoUnattendPrimaryAction'))) `
        -Resources $Resources `
        -Variant 'Primary' `
        -Enabled $false `
        -Width 132 `
        -Height 42 `
        -Margin (New-AxisWizardThickness -Left 0)
    $createButton.Tag = $createButtonTag
    $createButton.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, $createDisabledAutomationId)

    $returnButton = New-AxisWizardButton `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'InputReturnLabel' -DefaultValue (Get-AxisWizardArabicText -Name 'Return'))) `
        -Resources $Resources `
        -Variant 'Quiet' `
        -Enabled $true `
        -Width 104 `
        -Height 42 `
        -Margin (New-AxisWizardThickness -Left 0)
    $returnButton.Tag = $returnButtonTag
    $returnButton.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, $returnAutomationId)

    [void]$buttonRow.Children.Add($createButton)
    [void]$buttonRow.Children.Add((New-AxisWizardSpacer -Width 12 -Tag $returnSpacerTag))
    [void]$buttonRow.Children.Add($returnButton)
    [void](Add-AxisWizardGridRow -Grid $stack -Child $buttonRow)

    $primaryBackgroundForInput = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.PrimaryButton'
    $primaryBorderForInput = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.PrimaryButtonHover'
    $primaryForegroundForInput = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.PrimaryButtonText'
    $primaryEffectForInput = New-AxisWizardShadowEffect -Opacity 0.16 -BlurRadius 16 -ShadowDepth 3
    $disabledBackgroundForInput = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.SurfaceSoft'
    $disabledBorderForInput = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.BorderSoft'
    $disabledForegroundForInput = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.TextMuted'
    $accountBoxForInput = $accountBox
    $usbSelectorForInput = $usbSelector
    $createButtonForInput = $createButton
    $requiresAccountNameForInput = $requiresAccountName
    $createEnabledAutomationIdForInput = $createEnabledAutomationId
    $createDisabledAutomationIdForInput = $createDisabledAutomationId
    $inputCreateAutomationProperty = [System.Windows.Automation.AutomationProperties]::AutomationIdProperty
    $refreshInputCreateState = {
        $accountIsValid = $true
        if ($requiresAccountNameForInput) {
            $accountName = [string]$accountBoxForInput.Text
            $accountIsValid = (
                -not [string]::IsNullOrWhiteSpace($accountName) -and
                -not $accountName.Contains(' ') -and
                [regex]::IsMatch($accountName, '^[A-Za-z][A-Za-z0-9_-]{0,19}$')
            )
        }
        $usbIsSelected = ([int]$usbSelectorForInput.SelectedIndex -ge 0)
        if ($accountIsValid -and $usbIsSelected) {
            $createButtonForInput.IsEnabled = $true
            $createButtonForInput.Background = $primaryBackgroundForInput
            $createButtonForInput.BorderBrush = $primaryBorderForInput
            $createButtonForInput.Foreground = $primaryForegroundForInput
            $createButtonForInput.Effect = $primaryEffectForInput
            $createButtonForInput.SetValue($inputCreateAutomationProperty, $createEnabledAutomationIdForInput)
        }
        else {
            $createButtonForInput.IsEnabled = $false
            $createButtonForInput.Background = $disabledBackgroundForInput
            $createButtonForInput.BorderBrush = $disabledBorderForInput
            $createButtonForInput.Foreground = $disabledForegroundForInput
            $createButtonForInput.Effect = $null
            $createButtonForInput.SetValue($inputCreateAutomationProperty, $createDisabledAutomationIdForInput)
        }
    }.GetNewClosure()

    if ($accountBox -is [System.Windows.Controls.TextBox]) {
        $refreshInputCreateStateForAccount = $refreshInputCreateState
        $accountBox.Add_TextChanged({
            & $refreshInputCreateStateForAccount
        }.GetNewClosure())
    }

    $refreshInputCreateStateForUsb = $refreshInputCreateState
    $usbSelector.Add_SelectionChanged({
        & $refreshInputCreateStateForUsb
    }.GetNewClosure())

    $overlayForReturn = $overlay
    $accountBoxForReturn = $accountBox
    $usbSelectorForReturn = $usbSelector
    $refreshInputCreateStateForReturn = $refreshInputCreateState
    $returnButton.Add_Click({
        if ($accountBoxForReturn -is [System.Windows.Controls.TextBox]) {
            $accountBoxForReturn.Text = ''
        }
        $usbSelectorForReturn.SelectedIndex = -1
        & $refreshInputCreateStateForReturn
        $overlayForReturn.Visibility = [System.Windows.Visibility]::Collapsed
    }.GetNewClosure())

    & $refreshInputCreateState

    $card.Child = $stack
    $overlay.Child = $card

    return $overlay
}

function New-AxisFirstUseWizardStepContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Step,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    $stepId = [string](Get-AxisWizardMapValue -Map $Step -Name 'Id')
    if ($stepId -in @(
        'bitlocker',
        'convert-home-to-pro',
        'memory-compression',
        'date-language-region-time',
        'startup-apps-settings',
        'startup-apps-task-manager',
        'background-apps',
        'edge-settings',
        'store-settings',
        'updates-pause',
        'installers-startup-apps-settings',
        'installers-startup-apps-task-manager',
        'restart-after-installers',
        'driver-clean',
        'driver-install-debloat-settings',
        'nvidia-app-install',
        'directx',
        'visual-cpp',
        'graphics-configuration-center',
        'start-menu-taskbar',
        'start-menu-layout',
        'context-menu',
        'theme-black',
        'signout-lockscreen-wallpaper-black',
        'user-account-pictures-black',
        'widgets',
        'copilot',
        'game-mode',
        'pointer-precision',
        'bloatware',
        'game-bar',
        'edge-webview',
        'notepad-settings',
        'control-panel-settings',
        'input-language-hotkey',
        'sound',
        'device-manager-power-savings-wake',
        'network-adapter-power-savings-wake',
        'write-cache-buffer-flushing',
        'power-plan',
        'cleanup',
        'timer-resolution-assistant',
        'defender-optimize-assistant'
    )) {
        return New-AxisSetupStep -Step $Step -Resources $Resources
    }

    if ($stepId -eq 'unattended') {
        return New-AxisAutoUnattendStep -Step $Step -Resources $Resources
    }

    if ($stepId -eq 'updates-drivers-block') {
        return New-AxisUpdatesDriversBlockStep -Step $Step -Resources $Resources
    }

    if ($stepId -eq 'to-bios') {
        return New-AxisToBiosStep -Step $Step -Resources $Resources
    }

    if ($stepId -eq 'installers') {
        return New-AxisInstallersStep -Step $Step -Resources $Resources
    }

    if ($stepId -eq 'reinstall') {
        return New-AxisReinstallStep -Step $Step -Resources $Resources
    }

    if ($stepId -eq 'bios-settings') {
        return New-AxisBiosSettingsStep -Step $Step -Resources $Resources
    }

    return New-AxisBiosInformationStep -Step $Step -Resources $Resources
}

function New-AxisStepAcknowledgementOverlay {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Step,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    $overlay = [System.Windows.Controls.Border]::new()
    $overlay.Tag = 'AxisFirstUseWizard.ConfirmationOverlay'
    $overlay.Visibility = [System.Windows.Visibility]::Collapsed
    $overlay.Background = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.ColorConverter]::ConvertFromString('#CC080808'))
    $overlay.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $overlay.Padding = New-AxisWizardThickness -Left 220 -Top 190 -Right 220 -Bottom 190

    $card = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Wizard.ElevatedCard' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderStrong' `
        -RadiusKey 'Axis.Radius.Wizard.MainCard' `
        -Padding (New-AxisWizardThickness -Left 22 -Top 22 -Right 22 -Bottom 20) `
        -Elevation 'Card'
    $card.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $card.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $card.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $card.MinWidth = 420

    $stack = [System.Windows.Controls.StackPanel]::new()
    $stack.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $stack.Orientation = [System.Windows.Controls.Orientation]::Vertical
    $stack.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $stack.Tag = 'AxisFirstUseWizard.ConfirmationRightAlignedGroup'

    $acknowledgementText = [string](Get-AxisWizardMapValue -Map $Step -Name 'DocumentationAcknowledgementText' -DefaultValue (Get-AxisWizardArabicText -Name 'Acknowledgement'))
    $checkbox = [System.Windows.Controls.CheckBox]::new()
    $checkbox.IsChecked = $false
    $checkbox.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $checkbox.HorizontalContentAlignment = [System.Windows.HorizontalAlignment]::Right
    $checkbox.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $checkbox.Margin = New-AxisWizardThickness -Left 0
    $checkbox.Padding = New-AxisWizardThickness -Left 0
    $checkbox.Width = 16
    $checkbox.Height = 16
    $checkbox.Foreground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.TextSecondary'
    $checkbox.FontFamily = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontFamily'
    $checkbox.FontSize = [double](Get-AxisWizardResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontSize')
    $checkbox.Style = Get-AxisWizardFilledSquareCheckboxStyle
    $checkbox.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.AcknowledgementBlueFilledSquareCheckbox')
    $checkbox.Tag = 'AxisFirstUseWizard.ConfirmationAcknowledgement'

    $acknowledgementRow = [System.Windows.Controls.StackPanel]::new()
    $acknowledgementRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $acknowledgementRow.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $acknowledgementRow.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $acknowledgementRow.Tag = 'AxisFirstUseWizard.AcknowledgementRightAnchorRow'

    $acknowledgementLabel = New-AxisWizardTextBlock `
        -Text $acknowledgementText `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::RightToLeft)
    $acknowledgementLabel.Tag = 'AxisFirstUseWizard.ConfirmationAcknowledgementText'
    $acknowledgementLabel.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $acknowledgementLabel.Margin = New-AxisWizardThickness -Left 0 -Top 0 -Right 8 -Bottom 0

    [void]$acknowledgementRow.Children.Add($acknowledgementLabel)
    [void]$acknowledgementRow.Children.Add($checkbox)

    $confirmationActionWidth = [double](Get-AxisWizardMapValue -Map $Step -Name 'ConfirmationActionWidth' -DefaultValue 124.0)
    $confirmationReturnWidth = [Math]::Max([double](Get-AxisWizardMapValue -Map $Step -Name 'ConfirmationReturnWidth' -DefaultValue 118.0), 118.0)
    $confirmationButtonGap = 16.0

    $confirmButton = New-AxisWizardButton `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'ConfirmationActionLabel' -DefaultValue (Get-AxisWizardArabicText -Name 'Open'))) `
        -Resources $Resources `
        -Variant 'Primary' `
        -Enabled $false `
        -Width $confirmationActionWidth `
        -Height 42 `
        -Margin (New-AxisWizardThickness -Left 0)
    $confirmButton.Tag = 'AxisFirstUseWizard.ConfirmationOpenButton'
    $confirmButton.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right

    $returnButton = New-AxisWizardButton `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'ConfirmationReturnLabel' -DefaultValue (Get-AxisWizardArabicText -Name 'Return'))) `
        -Resources $Resources `
        -Variant 'Quiet' `
        -Enabled $true `
        -Width $confirmationReturnWidth `
        -Height 42 `
        -Margin (New-AxisWizardThickness -Left 0)
    $returnButton.Tag = 'AxisFirstUseWizard.ConfirmationReturnButton'
    $returnButton.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $returnButton.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.ConfirmationReturnOnlyClosesOverlay')

    $buttonRow = [System.Windows.Controls.StackPanel]::new()
    $buttonRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $buttonRow.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $buttonRow.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $buttonRow.Tag = 'AxisFirstUseWizard.ConfirmationButtonArea'
    $buttonRow.MinWidth = $confirmationActionWidth + $confirmationButtonGap + $confirmationReturnWidth
    $buttonRow.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.ConfirmationButtonAreaNoClipping')

    $confirmButtonForHandler = $confirmButton
    $primaryBackgroundForHandler = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.PrimaryButton'
    $primaryBorderForHandler = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.PrimaryButtonHover'
    $primaryForegroundForHandler = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.PrimaryButtonText'
    $primaryEffectForHandler = New-AxisWizardShadowEffect -Opacity 0.16 -BlurRadius 16 -ShadowDepth 3
    $disabledBackgroundForHandler = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.SurfaceSoft'
    $disabledBorderForHandler = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.BorderSoft'
    $disabledForegroundForHandler = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.TextMuted'
    $checkbox.Add_Checked({
        $confirmButtonForHandler.IsEnabled = $true
        $confirmButtonForHandler.Background = $primaryBackgroundForHandler
        $confirmButtonForHandler.BorderBrush = $primaryBorderForHandler
        $confirmButtonForHandler.Foreground = $primaryForegroundForHandler
        $confirmButtonForHandler.Effect = $primaryEffectForHandler
    }.GetNewClosure())
    $checkbox.Add_Unchecked({
        $confirmButtonForHandler.IsEnabled = $false
        $confirmButtonForHandler.Background = $disabledBackgroundForHandler
        $confirmButtonForHandler.BorderBrush = $disabledBorderForHandler
        $confirmButtonForHandler.Foreground = $disabledForegroundForHandler
        $confirmButtonForHandler.Effect = $null
    }.GetNewClosure())
    $overlayForReturnHandler = $overlay
    $checkboxForReturnHandler = $checkbox
    $returnButton.Add_Click({
        $checkboxForReturnHandler.IsChecked = $false
        $overlayForReturnHandler.Visibility = [System.Windows.Visibility]::Collapsed
    }.GetNewClosure())

    [void]$stack.Children.Add($acknowledgementRow)
    [void]$stack.Children.Add((New-AxisWizardSpacer -Height 14 -Tag 'AxisFirstUseWizard.ConfirmationControlSpacer'))
    [void]$buttonRow.Children.Add($confirmButton)
    [void]$buttonRow.Children.Add((New-AxisWizardSpacer -Width $confirmationButtonGap -Tag 'AxisFirstUseWizard.ConfirmationReturnButtonSpacer'))
    [void]$buttonRow.Children.Add($returnButton)
    [void]$stack.Children.Add($buttonRow)
    $card.Child = $stack
    $overlay.Child = $card

    return $overlay
}

function New-AxisWizardStepContent {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$SampleState = (Get-AxisFirstUseWizardSampleState),

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    $step = Get-AxisWizardMapValue -Map $SampleState -Name 'Step'
    return New-AxisFirstUseWizardStepContent -Step $step -Resources $Resources
}

function New-AxisFirstUseWizardPrototype {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$SampleState = (Get-AxisFirstUseWizardSampleState)
    )

    $resources = New-AxisWpfResourceDictionary
    $windowInfo = Get-AxisWizardMapValue -Map $SampleState -Name 'Window' -DefaultValue ([ordered]@{})

    $root = [System.Windows.Controls.Grid]::new()
    $root.Tag = 'AxisFirstUseWizard.Root'
    $root.Width = [double]::NaN
    $root.Height = [double]::NaN
    $root.MinWidth = 0
    $root.MinHeight = 0
    $root.Background = Get-AxisWizardResource -Resources $resources -Name 'Axis.Brush.Wizard.Background'
    $root.ClipToBounds = $true
    $root.UseLayoutRounding = $true
    $root.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    [void](Add-AxisResourcesToElement -Element $root -Resources $resources)

    foreach ($height in @(76, 50, 1, 72)) {
        $row = [System.Windows.Controls.RowDefinition]::new()
        if ($height -eq 1) {
            $row.Height = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        }
        else {
            $row.Height = [System.Windows.GridLength]::new($height)
        }
        [void]$root.RowDefinitions.Add($row)
    }

    $header = New-AxisWizardPanel `
        -Resources $resources `
        -BackgroundKey 'Axis.Brush.Wizard.HeaderBackground' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderSoft' `
        -RadiusKey 'Axis.Radius.None' `
        -Padding (New-AxisWizardThickness -Left 36 -Top 18 -Right 36 -Bottom 14) `
        -BorderThickness (New-AxisWizardThickness -Left 0 -Top 0 -Right 0 -Bottom 1)
    $header.Tag = 'AxisFirstUseWizard.Header'

    $headerGrid = [System.Windows.Controls.Grid]::new()
    $headerGrid.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $leftColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $leftColumn.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $rightColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $rightColumn.Width = [System.Windows.GridLength]::Auto
    [void]$headerGrid.ColumnDefinitions.Add($leftColumn)
    [void]$headerGrid.ColumnDefinitions.Add($rightColumn)

    $brandStack = [System.Windows.Controls.StackPanel]::new()
    $brandStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $brandStack.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    [void]$brandStack.Children.Add((New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $SampleState -Name 'BrandName' -DefaultValue 'AXIS')) `
        -Resources $resources `
        -FontSizeKey 'Axis.Type.Display.FontSize' `
        -FontWeightKey 'Axis.Type.Display.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.TextPrimary' `
        -FlowDirection ([System.Windows.FlowDirection]::LeftToRight)))
    [System.Windows.Controls.Grid]::SetColumn($brandStack, 0)
    [void]$headerGrid.Children.Add($brandStack)

    $stageText = New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $SampleState -Name 'CurrentStageName' -DefaultValue 'Check')) `
        -Resources $resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
        -Margin (New-AxisWizardThickness -Left 0 -Top 13 -Right 0 -Bottom 0) `
        -TextAlignment ([System.Windows.TextAlignment]::Left) `
        -FlowDirection ([System.Windows.FlowDirection]::LeftToRight)
    $stageText.Tag = 'AxisFirstUseWizard.CurrentStageHeader'
    [System.Windows.Controls.Grid]::SetColumn($stageText, 1)
    [void]$headerGrid.Children.Add($stageText)
    $header.Child = $headerGrid
    [System.Windows.Controls.Grid]::SetRow($header, 0)
    [void]$root.Children.Add($header)

    $progress = New-AxisStageProgressStrip `
        -Stages (Get-AxisWizardMapValue -Map $SampleState -Name 'Stages' -DefaultValue @()) `
        -Resources $resources
    [System.Windows.Controls.Grid]::SetRow($progress, 1)
    [void]$root.Children.Add($progress)
    $stageProgressActiveTextBrush = Get-AxisWizardResource -Resources $resources -Name 'Axis.Brush.Wizard.AccentText'
    $stageProgressMutedTextBrush = Get-AxisWizardResource -Resources $resources -Name 'Axis.Brush.Wizard.TextMuted'
    $stageProgressActiveFillBrush = Get-AxisWizardResource -Resources $resources -Name 'Axis.Brush.Wizard.Accent'
    $stageProgressCompletedTextBrush = New-AxisWizardColorBrush -Color '#22C55E'
    $stageProgressCompletedFillBrush = New-AxisWizardColorBrush -Color '#22C55E'
    $stageProgressInactiveFillBrush = Get-AxisWizardResource -Resources $resources -Name 'Axis.Brush.Wizard.BorderSoft'
    $stageProgressFullLineWidth = 104.0
    $setStageProgressActiveForNavigation = {
        param(
            [Parameter(Mandatory)]
            [string]$StageName
        )

        $progressGrid = $progress.Child
        if ($progressGrid -isnot [System.Windows.Controls.Grid]) {
            return
        }

        $stageItemsForProgress = @()
        foreach ($candidateItem in @($progressGrid.Children)) {
            if ($candidateItem -isnot [System.Windows.Controls.StackPanel] -or $candidateItem.Children.Count -lt 2) {
                continue
            }

            $stageItemsForProgress += $candidateItem
        }

        $stageNamesForProgress = @()
        foreach ($item in $stageItemsForProgress) {
            $label = $item.Children[0]
            if ($label -is [System.Windows.Controls.TextBlock]) {
                $stageNamesForProgress += [string]$label.Text
            }
        }

        $currentStageIndex = [Array]::IndexOf([string[]]$stageNamesForProgress, $StageName)
        foreach ($item in $stageItemsForProgress) {
            $label = $item.Children[0]
            $barBackground = $item.Children[1]
            if ($label -isnot [System.Windows.Controls.TextBlock] -or $barBackground -isnot [System.Windows.Controls.Border]) {
                continue
            }

            $fill = $barBackground.Child
            if ($fill -isnot [System.Windows.Controls.Border]) {
                continue
            }

            $itemStageName = [string]$label.Text
            $itemStageIndex = [Array]::IndexOf([string[]]$stageNamesForProgress, $itemStageName)
            $isCurrent = ($itemStageName -eq $StageName)
            $isCompleted = ($currentStageIndex -gt 0 -and $itemStageIndex -ge 0 -and $itemStageIndex -lt $currentStageIndex)
            $fill.Width = $stageProgressFullLineWidth
            if ($isCurrent) {
                $label.Foreground = $stageProgressActiveTextBrush
                $fill.Background = $stageProgressActiveFillBrush
                $fill.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, "AxisFirstUseWizard.StageLineActiveFullWhite.$itemStageName")
                $item.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, "AxisFirstUseWizard.StageProgressActive.$itemStageName")
            }
            elseif ($isCompleted) {
                $label.Foreground = $stageProgressCompletedTextBrush
                $fill.Background = $stageProgressCompletedFillBrush
                $fill.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, "AxisFirstUseWizard.StageLineCompletedFullGreen.$itemStageName")
                $item.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, "AxisFirstUseWizard.StageProgressCompleted.$itemStageName")
            }
            else {
                $label.Foreground = $stageProgressMutedTextBrush
                $fill.Background = $stageProgressInactiveFillBrush
                $fill.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, "AxisFirstUseWizard.StageLineInactiveDim.$itemStageName")
                $item.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, "AxisFirstUseWizard.StageProgressInactive.$itemStageName")
            }
        }
    }.GetNewClosure()

    $contentHost = [System.Windows.Controls.Border]::new()
    $contentHost.Padding = New-AxisWizardThickness -Left 37 -Top 13 -Right 37 -Bottom 8
    $contentHost.Background = Get-AxisWizardResource -Resources $resources -Name 'Axis.Brush.Wizard.Background'
    $contentHost.ClipToBounds = $true
    $contentHost.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $contentHost.Tag = 'AxisFirstUseWizard.StepContentHost'
    $steps = @(Get-AxisWizardMapValue -Map $SampleState -Name 'Steps' -DefaultValue @())
    if ($steps.Count -eq 0) {
        $steps = @((Get-AxisWizardMapValue -Map $SampleState -Name 'Step'))
    }
    $currentStepIndex = [int](Get-AxisWizardMapValue -Map $SampleState -Name 'CurrentStepIndex' -DefaultValue 0)
    if ($currentStepIndex -lt 0 -or $currentStepIndex -ge $steps.Count) {
        $currentStepIndex = 0
    }
    $step = $steps[$currentStepIndex]
    $stepViews = [object[]]::new($steps.Count)
    $stepOverlays = [object[]]::new($steps.Count)
    $stepInputOverlays = [object[]]::new($steps.Count)
    $stepEpicInstructionOverlays = [object[]]::new($steps.Count)
    $stepCompletedFlags = [bool[]]::new($steps.Count)
    $stepStageNames = [string[]]::new($steps.Count)
    $stepOptionalContinuationLabels = [string[]]::new($steps.Count)
    for ($stepIndex = 0; $stepIndex -lt $steps.Count; $stepIndex++) {
        $stepMap = [System.Collections.IDictionary]$steps[$stepIndex]
        $stepViews[$stepIndex] = New-AxisFirstUseWizardStepContent -Step $stepMap -Resources $resources
        $stepIdForOverlay = [string](Get-AxisWizardMapValue -Map $stepMap -Name 'Id')
        $requiresConfirmationAcknowledgement = [bool](Get-AxisWizardMapValue -Map $stepMap -Name 'RequiresConfirmationAcknowledgement' -DefaultValue $false)
        if ($requiresConfirmationAcknowledgement) {
            $stepOverlays[$stepIndex] = New-AxisStepAcknowledgementOverlay -Step $stepMap -Resources $resources
        }
        else {
            $stepOverlays[$stepIndex] = $null
        }
        $requiresInputWindow = [bool](Get-AxisWizardMapValue -Map $stepMap -Name 'RequiresInputWindow' -DefaultValue $false)
        if ($requiresInputWindow) {
            $stepInputOverlays[$stepIndex] = New-AxisAutoUnattendInputOverlay -Step $stepMap -Resources $resources
        }
        else {
            $stepInputOverlays[$stepIndex] = $null
        }
        if ($stepIdForOverlay -eq 'installers') {
            $stepEpicInstructionOverlays[$stepIndex] = New-AxisInstallersEpicInstructionOverlay -Step $stepMap -Resources $resources
        }
        else {
            $stepEpicInstructionOverlays[$stepIndex] = $null
        }
        $stepCompletedFlags[$stepIndex] = ([string](Get-AxisWizardMapValue -Map $stepMap -Name 'State' -DefaultValue 'Ready') -eq 'Completed')
        $stepStageNames[$stepIndex] = [string](Get-AxisWizardMapValue -Map $stepMap -Name 'StageName' -DefaultValue 'Check')
        $stepOptionalContinuationLabels[$stepIndex] = [string](Get-AxisWizardMapValue -Map $stepMap -Name 'OptionalContinuationLabel' -DefaultValue '')
    }
    $stageText.Text = $stepStageNames[$currentStepIndex]
    & $setStageProgressActiveForNavigation $stepStageNames[$currentStepIndex]
    $contentHost.Child = $stepViews[$currentStepIndex]
    [System.Windows.Controls.Grid]::SetRow($contentHost, 2)
    [void]$root.Children.Add($contentHost)

    $bottom = New-AxisWizardPanel `
        -Resources $resources `
        -BackgroundKey 'Axis.Brush.Wizard.HeaderBackground' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderSoft' `
        -RadiusKey 'Axis.Radius.None' `
        -Padding (New-AxisWizardThickness -Left 36 -Top 12 -Right 36 -Bottom 12) `
        -BorderThickness (New-AxisWizardThickness -Left 0 -Top 1 -Right 0 -Bottom 0)
    $bottom.Tag = 'AxisFirstUseWizard.BottomNavigation'
    $bottom.FlowDirection = [System.Windows.FlowDirection]::RightToLeft

    $bottomGrid = [System.Windows.Controls.Grid]::new()
    $bottomGrid.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $bottomLeft = [System.Windows.Controls.ColumnDefinition]::new()
    $bottomLeft.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $bottomRight = [System.Windows.Controls.ColumnDefinition]::new()
    $bottomRight.Width = [System.Windows.GridLength]::Auto
    [void]$bottomGrid.ColumnDefinitions.Add($bottomLeft)
    [void]$bottomGrid.ColumnDefinitions.Add($bottomRight)

    $buttons = [System.Windows.Controls.StackPanel]::new()
    $buttons.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $buttons.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $buttons.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $buttons.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $buttons.Tag = 'AxisFirstUseWizard.BottomButtons'
    $backButton = New-AxisWizardButton `
        -Text ([string](Get-AxisWizardMapValue -Map $SampleState -Name 'BackLabel' -DefaultValue (Get-AxisWizardArabicText -Name 'Back'))) `
        -Resources $resources `
        -Variant 'Quiet' `
        -Width 92 `
        -Height 40 `
        -Margin (New-AxisWizardThickness -Left 0)
    $backButton.Tag = 'AxisFirstUseWizard.BackButton'
    [void]$buttons.Children.Add($backButton)
    $optionalContinuationButton = New-AxisWizardButton `
        -Text (Get-AxisWizardGraphicsText -Name 'NvidiaAppOptionalContinuation') `
        -Resources $resources `
        -Variant 'Quiet' `
        -Enabled $false `
        -Width 244 `
        -Height 40 `
        -Margin (New-AxisWizardThickness -Left 0)
    $optionalContinuationButton.Tag = 'AxisFirstUseWizard.OptionalContinuationButton'
    $optionalContinuationButton.Visibility = [System.Windows.Visibility]::Collapsed
    $optionalContinuationButton.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.NvidiaAppOptionalContinuationNoApplySimulation')
    $optionalContinuationSpacer = New-AxisWizardSpacer -Width 18 -Tag 'AxisFirstUseWizard.OptionalContinuationFooterSpacer'
    $optionalContinuationSpacer.Visibility = [System.Windows.Visibility]::Collapsed
    [void]$buttons.Children.Add($optionalContinuationSpacer)
    [void]$buttons.Children.Add($optionalContinuationButton)
    $continueEnabled = [bool]$stepCompletedFlags[$currentStepIndex]
    $continueButton = New-AxisWizardButton `
        -Text ([string](Get-AxisWizardMapValue -Map $SampleState -Name 'ContinueLabel' -DefaultValue (Get-AxisWizardArabicText -Name 'Next'))) `
        -Resources $resources `
        -Variant 'Primary' `
        -Enabled $continueEnabled `
        -Width 96 `
        -Height 40 `
        -Margin (New-AxisWizardThickness -Left 0)
    $continueButton.Tag = 'AxisFirstUseWizard.ContinueButton'
    if ($continueEnabled) {
        Set-AxisWizardEnabledNextButtonBlue -Button $continueButton
    }
    [void]$buttons.Children.Add((New-AxisWizardSpacer -Width 18 -Tag 'AxisFirstUseWizard.FooterButtonSpacer'))
    [void]$buttons.Children.Add($continueButton)
    [System.Windows.Controls.Grid]::SetColumn($buttons, 1)
    [void]$bottomGrid.Children.Add($buttons)

    $bottom.Child = $bottomGrid
    [System.Windows.Controls.Grid]::SetRow($bottom, 3)
    [void]$root.Children.Add($bottom)

    foreach ($overlay in @($stepOverlays)) {
        if ($null -eq $overlay) {
            continue
        }

        [System.Windows.Controls.Grid]::SetRowSpan($overlay, 4)
        [void]$root.Children.Add($overlay)
    }
    foreach ($inputOverlay in @($stepInputOverlays)) {
        if ($null -eq $inputOverlay) {
            continue
        }

        [System.Windows.Controls.Grid]::SetRowSpan($inputOverlay, 4)
        [void]$root.Children.Add($inputOverlay)
    }
    foreach ($epicInstructionOverlay in @($stepEpicInstructionOverlays)) {
        if ($null -eq $epicInstructionOverlay) {
            continue
        }

        [System.Windows.Controls.Grid]::SetRowSpan($epicInstructionOverlay, 4)
        [void]$root.Children.Add($epicInstructionOverlay)
    }

    $primaryButton = $null
    $confirmButton = $null
    $runtimeStatusHost = $null
    $runtimeStatusSpacer = $null
    $visited = [System.Collections.Generic.HashSet[int]]::new()
    function Find-AxisWizardTaggedElement {
        param(
            [AllowNull()]
            [object]$Node,
            [Parameter(Mandatory)]
            [string]$Tag
        )

        if ($null -eq $Node) {
            return $null
        }

        $hash = [System.Runtime.CompilerServices.RuntimeHelpers]::GetHashCode($Node)
        if (-not $visited.Add($hash)) {
            return $null
        }

        if ($Node -is [System.Windows.FrameworkElement] -and [string]$Node.Tag -eq $Tag) {
            return $Node
        }

        if ($Node -is [System.Windows.Controls.ContentControl]) {
            $match = Find-AxisWizardTaggedElement -Node $Node.Content -Tag $Tag
            if ($null -ne $match) { return $match }
        }
        if ($Node -is [System.Windows.Controls.Panel]) {
            foreach ($child in @($Node.Children)) {
                $match = Find-AxisWizardTaggedElement -Node $child -Tag $Tag
                if ($null -ne $match) { return $match }
            }
        }
        if ($Node -is [System.Windows.Controls.Decorator]) {
            $match = Find-AxisWizardTaggedElement -Node $Node.Child -Tag $Tag
            if ($null -ne $match) { return $match }
        }

        return $null
    }

    $navigationStateForNavigation = [ordered]@{
        CurrentStepIndex = $currentStepIndex
    }
    $contentHostForNavigation = $contentHost
    $stepViewsForNavigation = $stepViews
    $stepOverlaysForNavigation = $stepOverlays
    $stepInputOverlaysForNavigation = $stepInputOverlays
    $stepEpicInstructionOverlaysForNavigation = $stepEpicInstructionOverlays
    $stepCompletedFlagsForNavigation = $stepCompletedFlags
    $stageTextForNavigation = $stageText
    $stepStageNamesForNavigation = $stepStageNames
    $setStageProgressActiveForNavigationClosure = $setStageProgressActiveForNavigation
    $continueButtonForNavigation = $continueButton
    $continueEnabledBlueMarkerForNavigation = 'AxisFirstUseWizard.EnabledNextButtonBlue'
    $continueEnabledBlueBackgroundForNavigation = New-AxisWizardColorBrush -Color '#2563EB'
    $continueEnabledBlueBorderForNavigation = New-AxisWizardColorBrush -Color '#60A5FA'
    $continueEnabledBlueForegroundForNavigation = New-AxisWizardColorBrush -Color '#FAF9F6'
    $continueEnabledBlueEffectForNavigation = New-AxisWizardShadowEffect -Opacity 0.20 -BlurRadius 18 -ShadowDepth 3
    $continueEnabledHoverReadableMarkerKeyForNavigation = 'AxisFirstUseWizard.EnabledNextButtonHoverReadable'
    $continueEnabledHoverReadableMarkerValueForNavigation = 'BlueHoverKeepsReadableText'
    $continueEnabledHoverBackgroundResourceKeyForNavigation = 'AxisFirstUseWizard.ButtonHoverBackground'
    $continueEnabledHoverBorderResourceKeyForNavigation = 'AxisFirstUseWizard.ButtonHoverBorder'
    $continueEnabledBlueHoverBackgroundForNavigation = New-AxisWizardColorBrush -Color '#1D4ED8'
    $continueEnabledBlueHoverBorderForNavigation = New-AxisWizardColorBrush -Color '#93C5FD'
    $continueDisabledBackgroundForNavigation = $continueButton.Background
    $continueDisabledBorderForNavigation = $continueButton.BorderBrush
    $continueDisabledForegroundForNavigation = $continueButton.Foreground
    $continueDisabledEffectForNavigation = $continueButton.Effect
    $continueAutomationIdPropertyForNavigation = [System.Windows.Automation.AutomationProperties]::AutomationIdProperty
    $optionalContinuationButtonForNavigation = $optionalContinuationButton
    $optionalContinuationSpacerForNavigation = $optionalContinuationSpacer
    $stepOptionalContinuationLabelsForNavigation = $stepOptionalContinuationLabels
    $updateOptionalContinuationForNavigation = {
        param(
            [int]$Index
        )

        $optionalLabel = ''
        if ($Index -ge 0 -and $Index -lt $stepOptionalContinuationLabelsForNavigation.Count) {
            $optionalLabel = [string]$stepOptionalContinuationLabelsForNavigation[$Index]
        }

        if (-not [string]::IsNullOrWhiteSpace($optionalLabel)) {
            $optionalContinuationButtonForNavigation.Content = $optionalLabel
            $optionalContinuationButtonForNavigation.IsEnabled = $true
            $optionalContinuationButtonForNavigation.Visibility = [System.Windows.Visibility]::Visible
            $optionalContinuationSpacerForNavigation.Visibility = [System.Windows.Visibility]::Visible
        }
        else {
            $optionalContinuationButtonForNavigation.IsEnabled = $false
            $optionalContinuationButtonForNavigation.Visibility = [System.Windows.Visibility]::Collapsed
            $optionalContinuationSpacerForNavigation.Visibility = [System.Windows.Visibility]::Collapsed
        }
    }.GetNewClosure()
    $updateOptionalContinuationForNavigationClosure = $updateOptionalContinuationForNavigation
    & $updateOptionalContinuationForNavigationClosure $currentStepIndex

    if ($backButton -is [System.Windows.Controls.Button]) {
        $backButton.Add_Click({
            $currentNavigationIndex = [int]$navigationStateForNavigation['CurrentStepIndex']
            if ($currentNavigationIndex -le 0) {
                return
            }

            foreach ($overlayForNavigation in @($stepOverlaysForNavigation)) {
                if ($null -eq $overlayForNavigation) {
                    continue
                }

                $overlayForNavigation.Visibility = [System.Windows.Visibility]::Collapsed
            }
            foreach ($inputOverlayForNavigation in @($stepInputOverlaysForNavigation)) {
                if ($null -eq $inputOverlayForNavigation) {
                    continue
                }

                $inputOverlayForNavigation.Visibility = [System.Windows.Visibility]::Collapsed
            }
            foreach ($epicInstructionOverlayForNavigation in @($stepEpicInstructionOverlaysForNavigation)) {
                if ($null -eq $epicInstructionOverlayForNavigation) {
                    continue
                }

                $epicInstructionOverlayForNavigation.Visibility = [System.Windows.Visibility]::Collapsed
            }

            $currentNavigationIndex = $currentNavigationIndex - 1
            $navigationStateForNavigation['CurrentStepIndex'] = $currentNavigationIndex
            $contentHostForNavigation.Child = $stepViewsForNavigation[$currentNavigationIndex]
            $stageTextForNavigation.Text = $stepStageNamesForNavigation[$currentNavigationIndex]
            & $setStageProgressActiveForNavigationClosure $stepStageNamesForNavigation[$currentNavigationIndex]
            if ($stepCompletedFlagsForNavigation[$currentNavigationIndex]) {
                $continueButtonForNavigation.IsEnabled = $true
                $continueButtonForNavigation.SetValue($continueAutomationIdPropertyForNavigation, $continueEnabledBlueMarkerForNavigation)
                $continueButtonForNavigation.Background = $continueEnabledBlueBackgroundForNavigation
                $continueButtonForNavigation.BorderBrush = $continueEnabledBlueBorderForNavigation
                $continueButtonForNavigation.Foreground = $continueEnabledBlueForegroundForNavigation
                $continueButtonForNavigation.Effect = $continueEnabledBlueEffectForNavigation
                $continueButtonForNavigation.Resources[$continueEnabledHoverReadableMarkerKeyForNavigation] = $continueEnabledHoverReadableMarkerValueForNavigation
                $continueButtonForNavigation.Resources[$continueEnabledHoverBackgroundResourceKeyForNavigation] = $continueEnabledBlueHoverBackgroundForNavigation
                $continueButtonForNavigation.Resources[$continueEnabledHoverBorderResourceKeyForNavigation] = $continueEnabledBlueHoverBorderForNavigation
            }
            else {
                $continueButtonForNavigation.IsEnabled = $false
                $continueButtonForNavigation.SetValue($continueAutomationIdPropertyForNavigation, '')
                $continueButtonForNavigation.Background = $continueDisabledBackgroundForNavigation
                $continueButtonForNavigation.BorderBrush = $continueDisabledBorderForNavigation
                $continueButtonForNavigation.Foreground = $continueDisabledForegroundForNavigation
                $continueButtonForNavigation.Effect = $continueDisabledEffectForNavigation
            }
            & $updateOptionalContinuationForNavigationClosure $currentNavigationIndex
        }.GetNewClosure())
    }

    if ($continueButton -is [System.Windows.Controls.Button]) {
        $continueButton.Add_Click({
            $currentNavigationIndex = [int]$navigationStateForNavigation['CurrentStepIndex']
            if (-not $stepCompletedFlagsForNavigation[$currentNavigationIndex]) {
                return
            }
            if ($currentNavigationIndex -ge ($stepViewsForNavigation.Count - 1)) {
                return
            }

            foreach ($overlayForNavigation in @($stepOverlaysForNavigation)) {
                if ($null -eq $overlayForNavigation) {
                    continue
                }

                $overlayForNavigation.Visibility = [System.Windows.Visibility]::Collapsed
            }
            foreach ($inputOverlayForNavigation in @($stepInputOverlaysForNavigation)) {
                if ($null -eq $inputOverlayForNavigation) {
                    continue
                }

                $inputOverlayForNavigation.Visibility = [System.Windows.Visibility]::Collapsed
            }
            foreach ($epicInstructionOverlayForNavigation in @($stepEpicInstructionOverlaysForNavigation)) {
                if ($null -eq $epicInstructionOverlayForNavigation) {
                    continue
                }

                $epicInstructionOverlayForNavigation.Visibility = [System.Windows.Visibility]::Collapsed
            }

            $currentNavigationIndex = $currentNavigationIndex + 1
            $navigationStateForNavigation['CurrentStepIndex'] = $currentNavigationIndex
            $contentHostForNavigation.Child = $stepViewsForNavigation[$currentNavigationIndex]
            $stageTextForNavigation.Text = $stepStageNamesForNavigation[$currentNavigationIndex]
            & $setStageProgressActiveForNavigationClosure $stepStageNamesForNavigation[$currentNavigationIndex]
            if ($stepCompletedFlagsForNavigation[$currentNavigationIndex]) {
                $continueButtonForNavigation.IsEnabled = $true
                $continueButtonForNavigation.SetValue($continueAutomationIdPropertyForNavigation, $continueEnabledBlueMarkerForNavigation)
                $continueButtonForNavigation.Background = $continueEnabledBlueBackgroundForNavigation
                $continueButtonForNavigation.BorderBrush = $continueEnabledBlueBorderForNavigation
                $continueButtonForNavigation.Foreground = $continueEnabledBlueForegroundForNavigation
                $continueButtonForNavigation.Effect = $continueEnabledBlueEffectForNavigation
                $continueButtonForNavigation.Resources[$continueEnabledHoverReadableMarkerKeyForNavigation] = $continueEnabledHoverReadableMarkerValueForNavigation
                $continueButtonForNavigation.Resources[$continueEnabledHoverBackgroundResourceKeyForNavigation] = $continueEnabledBlueHoverBackgroundForNavigation
                $continueButtonForNavigation.Resources[$continueEnabledHoverBorderResourceKeyForNavigation] = $continueEnabledBlueHoverBorderForNavigation
            }
            else {
                $continueButtonForNavigation.IsEnabled = $false
                $continueButtonForNavigation.SetValue($continueAutomationIdPropertyForNavigation, '')
                $continueButtonForNavigation.Background = $continueDisabledBackgroundForNavigation
                $continueButtonForNavigation.BorderBrush = $continueDisabledBorderForNavigation
                $continueButtonForNavigation.Foreground = $continueDisabledForegroundForNavigation
                $continueButtonForNavigation.Effect = $continueDisabledEffectForNavigation
            }
            & $updateOptionalContinuationForNavigationClosure $currentNavigationIndex
        }.GetNewClosure())
    }

    if ($optionalContinuationButton -is [System.Windows.Controls.Button]) {
        $optionalContinuationButton.Add_Click({
            $currentNavigationIndex = [int]$navigationStateForNavigation['CurrentStepIndex']
            if ($currentNavigationIndex -lt 0 -or $currentNavigationIndex -ge $stepOptionalContinuationLabelsForNavigation.Count) {
                return
            }
            if ([string]::IsNullOrWhiteSpace([string]$stepOptionalContinuationLabelsForNavigation[$currentNavigationIndex])) {
                return
            }
            if ($currentNavigationIndex -ge ($stepViewsForNavigation.Count - 1)) {
                return
            }

            foreach ($overlayForNavigation in @($stepOverlaysForNavigation)) {
                if ($null -eq $overlayForNavigation) {
                    continue
                }

                $overlayForNavigation.Visibility = [System.Windows.Visibility]::Collapsed
            }
            foreach ($inputOverlayForNavigation in @($stepInputOverlaysForNavigation)) {
                if ($null -eq $inputOverlayForNavigation) {
                    continue
                }

                $inputOverlayForNavigation.Visibility = [System.Windows.Visibility]::Collapsed
            }
            foreach ($epicInstructionOverlayForNavigation in @($stepEpicInstructionOverlaysForNavigation)) {
                if ($null -eq $epicInstructionOverlayForNavigation) {
                    continue
                }

                $epicInstructionOverlayForNavigation.Visibility = [System.Windows.Visibility]::Collapsed
            }

            $currentNavigationIndex = $currentNavigationIndex + 1
            $navigationStateForNavigation['CurrentStepIndex'] = $currentNavigationIndex
            $contentHostForNavigation.Child = $stepViewsForNavigation[$currentNavigationIndex]
            $stageTextForNavigation.Text = $stepStageNamesForNavigation[$currentNavigationIndex]
            & $setStageProgressActiveForNavigationClosure $stepStageNamesForNavigation[$currentNavigationIndex]
            if ($stepCompletedFlagsForNavigation[$currentNavigationIndex]) {
                $continueButtonForNavigation.IsEnabled = $true
                $continueButtonForNavigation.SetValue($continueAutomationIdPropertyForNavigation, $continueEnabledBlueMarkerForNavigation)
                $continueButtonForNavigation.Background = $continueEnabledBlueBackgroundForNavigation
                $continueButtonForNavigation.BorderBrush = $continueEnabledBlueBorderForNavigation
                $continueButtonForNavigation.Foreground = $continueEnabledBlueForegroundForNavigation
                $continueButtonForNavigation.Effect = $continueEnabledBlueEffectForNavigation
                $continueButtonForNavigation.Resources[$continueEnabledHoverReadableMarkerKeyForNavigation] = $continueEnabledHoverReadableMarkerValueForNavigation
                $continueButtonForNavigation.Resources[$continueEnabledHoverBackgroundResourceKeyForNavigation] = $continueEnabledBlueHoverBackgroundForNavigation
                $continueButtonForNavigation.Resources[$continueEnabledHoverBorderResourceKeyForNavigation] = $continueEnabledBlueHoverBorderForNavigation
            }
            else {
                $continueButtonForNavigation.IsEnabled = $false
                $continueButtonForNavigation.SetValue($continueAutomationIdPropertyForNavigation, '')
                $continueButtonForNavigation.Background = $continueDisabledBackgroundForNavigation
                $continueButtonForNavigation.BorderBrush = $continueDisabledBorderForNavigation
                $continueButtonForNavigation.Foreground = $continueDisabledForegroundForNavigation
                $continueButtonForNavigation.Effect = $continueDisabledEffectForNavigation
            }
            & $updateOptionalContinuationForNavigationClosure $currentNavigationIndex
        }.GetNewClosure())
    }

    for ($handlerStepIndex = 0; $handlerStepIndex -lt $steps.Count; $handlerStepIndex++) {
        $handlerStep = [System.Collections.IDictionary]$steps[$handlerStepIndex]
        $handlerContent = $stepViews[$handlerStepIndex]
        $handlerOverlay = $stepOverlays[$handlerStepIndex]
        $handlerInputOverlay = $stepInputOverlays[$handlerStepIndex]
        $handlerEpicInstructionOverlay = $stepEpicInstructionOverlays[$handlerStepIndex]

        $visited.Clear()
        $primaryButton = Find-AxisWizardTaggedElement -Node $handlerContent -Tag 'AxisFirstUseWizard.PrimaryOpenButton'
        $visited.Clear()
        $runtimeStatusHost = Find-AxisWizardTaggedElement -Node $handlerContent -Tag 'AxisFirstUseWizard.RuntimeStatusArea'
        $visited.Clear()
        $runtimeStatusSpacer = Find-AxisWizardTaggedElement -Node $handlerContent -Tag 'AxisFirstUseWizard.ActionRuntimeStatusSpacer'
        $visited.Clear()
        $confirmButton = Find-AxisWizardTaggedElement -Node $handlerOverlay -Tag 'AxisFirstUseWizard.ConfirmationOpenButton'
        $visited.Clear()
        $confirmationAcknowledgement = Find-AxisWizardTaggedElement -Node $handlerOverlay -Tag 'AxisFirstUseWizard.ConfirmationAcknowledgement'
        $inputCreateButtonTagForLookup = [string](Get-AxisWizardMapValue -Map $handlerStep -Name 'InputCreateButtonTag' -DefaultValue 'AxisFirstUseWizard.AutoUnattendInputCreateButton')
        $inputAccountTextBoxTagForLookup = [string](Get-AxisWizardMapValue -Map $handlerStep -Name 'InputAccountTextBoxTag' -DefaultValue 'AxisFirstUseWizard.AutoUnattendAccountTextBox')
        $inputUsbSelectorTagForLookup = [string](Get-AxisWizardMapValue -Map $handlerStep -Name 'InputUsbSelectorTag' -DefaultValue 'AxisFirstUseWizard.AutoUnattendUsbSelector')
        $visited.Clear()
        $inputCreateButton = Find-AxisWizardTaggedElement -Node $handlerInputOverlay -Tag $inputCreateButtonTagForLookup
        $visited.Clear()
        $inputAccountBox = Find-AxisWizardTaggedElement -Node $handlerInputOverlay -Tag $inputAccountTextBoxTagForLookup
        $visited.Clear()
        $inputUsbSelector = Find-AxisWizardTaggedElement -Node $handlerInputOverlay -Tag $inputUsbSelectorTagForLookup
        $visited.Clear()
        $epicInstructionInstallButton = Find-AxisWizardTaggedElement -Node $handlerEpicInstructionOverlay -Tag 'AxisFirstUseWizard.InstallersEpicInstructionInstallButton'
        $visited.Clear()
        $epicInstructionReturnButton = Find-AxisWizardTaggedElement -Node $handlerEpicInstructionOverlay -Tag 'AxisFirstUseWizard.InstallersEpicInstructionReturnButton'

        $checkingRuntimeStatusForHandler = New-AxisWizardRuntimeStatusContent -State 'Checking' -Step $handlerStep -Resources $resources
        $completedRuntimeStatusForHandler = New-AxisWizardRuntimeStatusContent -State 'Completed' -Step $handlerStep -Resources $resources
        $completionTimerForHandler = [System.Windows.Threading.DispatcherTimer]::new()
        $completionTimerForHandler.Interval = [TimeSpan]::FromMilliseconds(950)
        $handlerStepIndexForClosure = $handlerStepIndex
        $handlerOverlayForClosure = $handlerOverlay
        $handlerInputOverlayForClosure = $handlerInputOverlay
        $handlerEpicInstructionOverlayForClosure = $handlerEpicInstructionOverlay
        $runtimeStatusHostForHandler = $runtimeStatusHost
        $runtimeStatusSpacerForHandler = $runtimeStatusSpacer
        $primaryButtonForHandler = $primaryButton
        $confirmationAcknowledgementForHandler = $confirmationAcknowledgement
        $stepOverlaysForHandler = $stepOverlays
        $stepInputOverlaysForHandler = $stepInputOverlays
        $stepEpicInstructionOverlaysForHandler = $stepEpicInstructionOverlays
        $hasConfirmationOverlayForHandler = ($null -ne $handlerOverlay)
        $hasInputOverlayForHandler = ($null -ne $handlerInputOverlay)
        $inputCreateButtonForHandler = $inputCreateButton
        $inputAccountBoxForHandler = $inputAccountBox
        $inputUsbSelectorForHandler = $inputUsbSelector
        $stepCompletedFlagsForHandler = $stepCompletedFlagsForNavigation
        $continueButtonForHandler = $continueButton
        $continueEnabledBlueMarkerForHandler = $continueEnabledBlueMarkerForNavigation
        $continueEnabledBlueBackgroundForHandler = $continueEnabledBlueBackgroundForNavigation
        $continueEnabledBlueBorderForHandler = $continueEnabledBlueBorderForNavigation
        $continueEnabledBlueForegroundForHandler = $continueEnabledBlueForegroundForNavigation
        $continueEnabledBlueEffectForHandler = $continueEnabledBlueEffectForNavigation
        $continueEnabledHoverReadableMarkerKeyForHandler = $continueEnabledHoverReadableMarkerKeyForNavigation
        $continueEnabledHoverReadableMarkerValueForHandler = $continueEnabledHoverReadableMarkerValueForNavigation
        $continueEnabledHoverBackgroundResourceKeyForHandler = $continueEnabledHoverBackgroundResourceKeyForNavigation
        $continueEnabledHoverBorderResourceKeyForHandler = $continueEnabledHoverBorderResourceKeyForNavigation
        $continueEnabledBlueHoverBackgroundForHandler = $continueEnabledBlueHoverBackgroundForNavigation
        $continueEnabledBlueHoverBorderForHandler = $continueEnabledBlueHoverBorderForNavigation
        $continueAutomationIdPropertyForHandler = $continueAutomationIdPropertyForNavigation

        $completionTimerForHandler.Add_Tick({
            $completionTimerForHandler.Stop()
            $stepCompletedFlagsForHandler[$handlerStepIndexForClosure] = $true
            $runtimeStatusHostForHandler.Child = $completedRuntimeStatusForHandler
            $runtimeStatusHostForHandler.Visibility = [System.Windows.Visibility]::Visible
            if ([int]$navigationStateForNavigation['CurrentStepIndex'] -eq $handlerStepIndexForClosure) {
                $continueButtonForHandler.IsEnabled = $true
                $continueButtonForHandler.SetValue($continueAutomationIdPropertyForHandler, $continueEnabledBlueMarkerForHandler)
                $continueButtonForHandler.Background = $continueEnabledBlueBackgroundForHandler
                $continueButtonForHandler.BorderBrush = $continueEnabledBlueBorderForHandler
                $continueButtonForHandler.Foreground = $continueEnabledBlueForegroundForHandler
                $continueButtonForHandler.Effect = $continueEnabledBlueEffectForHandler
                $continueButtonForHandler.Resources[$continueEnabledHoverReadableMarkerKeyForHandler] = $continueEnabledHoverReadableMarkerValueForHandler
                $continueButtonForHandler.Resources[$continueEnabledHoverBackgroundResourceKeyForHandler] = $continueEnabledBlueHoverBackgroundForHandler
                $continueButtonForHandler.Resources[$continueEnabledHoverBorderResourceKeyForHandler] = $continueEnabledBlueHoverBorderForHandler
            }
        }.GetNewClosure())

        if ($primaryButton -is [System.Windows.Controls.Button]) {
            $primaryButton.Add_Click({
                if ($primaryButtonForHandler -is [System.Windows.Controls.Button] -and -not [bool]$primaryButtonForHandler.IsEnabled) {
                    return
                }
                foreach ($overlayForHandler in @($stepOverlaysForHandler)) {
                    if ($null -eq $overlayForHandler) {
                        continue
                    }

                    $overlayForHandler.Visibility = [System.Windows.Visibility]::Collapsed
                }
                foreach ($inputOverlayForHandler in @($stepInputOverlaysForHandler)) {
                    if ($null -eq $inputOverlayForHandler) {
                        continue
                    }

                    $inputOverlayForHandler.Visibility = [System.Windows.Visibility]::Collapsed
                }
                foreach ($epicInstructionOverlayForHandler in @($stepEpicInstructionOverlaysForHandler)) {
                    if ($null -eq $epicInstructionOverlayForHandler) {
                        continue
                    }

                    $epicInstructionOverlayForHandler.Visibility = [System.Windows.Visibility]::Collapsed
                }
                if ($hasInputOverlayForHandler) {
                    if ($inputAccountBoxForHandler -is [System.Windows.Controls.TextBox]) {
                        $inputAccountBoxForHandler.Text = ''
                    }
                    if ($inputUsbSelectorForHandler -is [System.Windows.Controls.ComboBox]) {
                        $inputUsbSelectorForHandler.SelectedIndex = -1
                    }
                    if ($inputCreateButtonForHandler -is [System.Windows.Controls.Button]) {
                        $inputCreateButtonForHandler.IsEnabled = $false
                    }
                    $handlerInputOverlayForClosure.Visibility = [System.Windows.Visibility]::Visible
                    return
                }
                if (
                    $handlerEpicInstructionOverlayForClosure -is [System.Windows.Controls.Border] -and
                    $primaryButtonForHandler -is [System.Windows.Controls.Button] -and
                    [bool]$primaryButtonForHandler.Resources['AxisFirstUseWizard.InstallersEpicSelected']
                ) {
                    $handlerEpicInstructionOverlayForClosure.Visibility = [System.Windows.Visibility]::Visible
                    return
                }
                if (-not $hasConfirmationOverlayForHandler) {
                    $runtimeStatusHostForHandler.Child = $checkingRuntimeStatusForHandler
                    $runtimeStatusHostForHandler.Visibility = [System.Windows.Visibility]::Visible
                    $runtimeStatusSpacerForHandler.Visibility = [System.Windows.Visibility]::Visible
                    $completionTimerForHandler.Stop()
                    $completionTimerForHandler.Start()
                    return
                }

                $confirmationAcknowledgementForHandler.IsChecked = $false
                $handlerOverlayForClosure.Visibility = [System.Windows.Visibility]::Visible
            }.GetNewClosure())
        }

        if ($confirmButton -is [System.Windows.Controls.Button]) {
            $confirmButton.Add_Click({
                $handlerOverlayForClosure.Visibility = [System.Windows.Visibility]::Collapsed
                $runtimeStatusHostForHandler.Child = $checkingRuntimeStatusForHandler
                $runtimeStatusHostForHandler.Visibility = [System.Windows.Visibility]::Visible
                $runtimeStatusSpacerForHandler.Visibility = [System.Windows.Visibility]::Visible
                $completionTimerForHandler.Stop()
                $completionTimerForHandler.Start()
            }.GetNewClosure())
        }

        if ($epicInstructionReturnButton -is [System.Windows.Controls.Button]) {
            $epicInstructionReturnButton.Add_Click({
                $handlerEpicInstructionOverlayForClosure.Visibility = [System.Windows.Visibility]::Collapsed
            }.GetNewClosure())
        }

        if ($epicInstructionInstallButton -is [System.Windows.Controls.Button]) {
            $epicInstructionInstallButton.Add_Click({
                $handlerEpicInstructionOverlayForClosure.Visibility = [System.Windows.Visibility]::Collapsed
                $runtimeStatusHostForHandler.Child = $checkingRuntimeStatusForHandler
                $runtimeStatusHostForHandler.Visibility = [System.Windows.Visibility]::Visible
                $runtimeStatusSpacerForHandler.Visibility = [System.Windows.Visibility]::Visible
                $completionTimerForHandler.Stop()
                $completionTimerForHandler.Start()
            }.GetNewClosure())
        }

        if ($inputCreateButton -is [System.Windows.Controls.Button]) {
            $inputCreateButton.Add_Click({
                if (-not [bool]$inputCreateButtonForHandler.IsEnabled) {
                    return
                }
                foreach ($inputOverlayForHandler in @($stepInputOverlaysForHandler)) {
                    if ($null -eq $inputOverlayForHandler) {
                        continue
                    }

                    $inputOverlayForHandler.Visibility = [System.Windows.Visibility]::Collapsed
                }
                $runtimeStatusHostForHandler.Child = $checkingRuntimeStatusForHandler
                $runtimeStatusHostForHandler.Visibility = [System.Windows.Visibility]::Visible
                $runtimeStatusSpacerForHandler.Visibility = [System.Windows.Visibility]::Visible
                $completionTimerForHandler.Stop()
                $completionTimerForHandler.Start()
            }.GetNewClosure())
        }
    }

    return $root
}

function New-AxisFirstUseWizardPrototypeWindow {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$SampleState = (Get-AxisFirstUseWizardSampleState)
    )

    $windowInfo = Get-AxisWizardMapValue -Map $SampleState -Name 'Window' -DefaultValue ([ordered]@{})
    $window = [System.Windows.Window]::new()
    $window.Title = [string](Get-AxisWizardMapValue -Map $windowInfo -Name 'Title' -DefaultValue 'AXIS First-use wizard prototype')
    $window.Width = [double](Get-AxisWizardMapValue -Map $windowInfo -Name 'Width' -DefaultValue 900.0)
    $window.Height = [double](Get-AxisWizardMapValue -Map $windowInfo -Name 'Height' -DefaultValue 650.0)
    $window.MinWidth = 900
    $window.MinHeight = 650
    $window.WindowStyle = [System.Windows.WindowStyle]::SingleBorderWindow
    $window.ResizeMode = [System.Windows.ResizeMode]::NoResize
    $window.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterScreen
    $window.Background = Get-AxisWizardResource -Resources (New-AxisWpfResourceDictionary) -Name 'Axis.Brush.Wizard.WindowSurface'
    $window.UseLayoutRounding = $true
    $window.SnapsToDevicePixels = $true
    $window.Content = New-AxisFirstUseWizardPrototype -SampleState $SampleState
    return $window
}
