Set-StrictMode -Version Latest

$script:AxisFirstUseWizardResourcePath = Join-Path $PSScriptRoot 'AxisResources.ps1'
. $script:AxisFirstUseWizardResourcePath

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
        [string]$ForegroundKey = 'Axis.Brush.Text.Secondary',
        [string]$LineHeightKey = '',
        [System.Windows.Thickness]$Margin = (New-AxisWizardThickness -Left 0),
        [switch]$Wrap
    )

    $textBlock = [System.Windows.Controls.TextBlock]::new()
    $textBlock.Text = $Text
    $textBlock.FontFamily = Get-AxisWizardResource -Resources $Resources -Name $FontFamilyKey
    $textBlock.FontSize = [double](Get-AxisWizardResource -Resources $Resources -Name $FontSizeKey)
    $textBlock.FontWeight = Get-AxisWizardResource -Resources $Resources -Name $FontWeightKey
    $textBlock.Foreground = Get-AxisWizardResource -Resources $Resources -Name $ForegroundKey
    $textBlock.Margin = $Margin

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
        [System.Windows.Thickness]$BorderThickness = (New-AxisWizardThickness -Left 1)
    )

    $panel = [System.Windows.Controls.Border]::new()
    $panel.Background = Get-AxisWizardResource -Resources $Resources -Name $BackgroundKey
    $panel.BorderBrush = Get-AxisWizardResource -Resources $Resources -Name $BorderBrushKey
    $panel.BorderThickness = $BorderThickness
    $panel.CornerRadius = Get-AxisWizardResource -Resources $Resources -Name $RadiusKey
    $panel.Padding = $Padding
    $panel.Margin = $Margin

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

        [bool]$Enabled = $true
    )

    $button = [System.Windows.Controls.Button]::new()
    $button.Content = $Text
    $button.Padding = New-AxisWizardThickness -Left 14 -Top 8 -Right 14 -Bottom 8
    $button.Margin = New-AxisWizardThickness -Left 8 -Top 0 -Right 0 -Bottom 0
    $button.BorderThickness = New-AxisWizardThickness -Left 1
    $button.FontFamily = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontFamily'
    $button.FontSize = [double](Get-AxisWizardResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontSize')
    $button.FontWeight = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Type.Micro.FontWeight'
    $button.Focusable = $false
    $button.IsHitTestVisible = $false
    $button.IsEnabled = $Enabled
    $button.Tag = 'AxisFirstUseWizard.VisualButton'

    if (-not $Enabled) {
        $button.Background = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Surface.InteractivePressed'
        $button.BorderBrush = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Border.Subtle'
        $button.Foreground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Text.Disabled'
    }
    elseif ($Variant -eq 'Primary') {
        $button.Background = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Accent.Primary'
        $button.BorderBrush = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Accent.Hover'
        $button.Foreground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Text.Inverse'
    }
    elseif ($Variant -eq 'Quiet') {
        $button.Background = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Background.Inset'
        $button.BorderBrush = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Border.Subtle'
        $button.Foreground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Text.Secondary'
    }
    else {
        $button.Background = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Surface.Interactive'
        $button.BorderBrush = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Border.Default'
        $button.Foreground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Text.Primary'
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

function Get-AxisFirstUseWizardSampleState {
    [CmdletBinding()]
    param()

    $biosStep = [ordered]@{
        Id = 'bios-information'
        Title = 'BIOS Information'
        StageName = 'Check'
        State = 'Ready'
        StateLabel = 'Ready'
        PrimaryActionLabel = 'Check firmware information'
        RunningActionLabel = 'Checking...'
        ReadyStatusText = 'Ready when you are.'
        RunningStatusText = 'Checking firmware information...'
        CompletionStateLabel = 'Completed'
        CompletedStatusText = 'BIOS Information completed.'
        Description = 'Review basic firmware and motherboard information before continuing the setup flow.'
        WhatThisStepChecks = @(
            'BIOS/UEFI version'
            'Motherboard and vendor details'
            'Windows boot mode when available later'
            'Basic firmware readiness signals'
        )
        Requirements = @(
            'No special action is needed.'
            'AXIS may ask for administrator context during the full setup flow.'
        )
        DocumentationTitle = 'AXIS Documentation'
        DocumentationLabel = 'View documentation'
        DocumentationDescription = 'BIOS Information guide and setup notes will live in AXIS documentation later.'
        RequiresDocumentationAcknowledgement = $false
        DocumentationAcknowledgementText = 'I have read the instructions for this step.'
        SampleValues = [ordered]@{
            Firmware = 'Sample UEFI firmware'
            Board = 'Sample motherboard family'
            BootMode = 'UEFI expected'
        }
    }

    return [ordered]@{
        BrandName = 'AXIS'
        ModeLabel = 'Guided setup'
        CurrentStageName = 'Check'
        Window = [ordered]@{
            Width = 900.0
            Height = 650.0
            Title = 'AXIS First-use wizard prototype'
        }
        Stages = @(
            [ordered]@{ Name = 'Check'; State = 'Current'; Progress = 0.33 }
            [ordered]@{ Name = 'Refresh'; State = 'Future'; Progress = 0.0 }
            [ordered]@{ Name = 'Setup'; State = 'Future'; Progress = 0.0 }
            [ordered]@{ Name = 'Apps'; State = 'Future'; Progress = 0.0 }
            [ordered]@{ Name = 'Graphics'; State = 'Future'; Progress = 0.0 }
            [ordered]@{ Name = 'Windows'; State = 'Future'; Progress = 0.0 }
            [ordered]@{ Name = 'Finish'; State = 'Future'; Progress = 0.0 }
        )
        SupportedStepStates = @(
            'Ready'
            'Checking'
            'Completed'
        )
        Step = $biosStep
        DangerousStepPattern = [ordered]@{
            Title = 'Sample protected step'
            PrimaryActionLabel = 'Continue'
            RequiresDocumentationAcknowledgement = $true
            DocumentationAcknowledgementText = 'I have read the instructions for this step.'
            Acknowledged = $false
        }
    }
}

function New-AxisStepIcon {
    [CmdletBinding()]
    param(
        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    $canvas = [System.Windows.Controls.Canvas]::new()
    $canvas.Width = 92
    $canvas.Height = 92
    $canvas.Tag = 'AxisFirstUseWizard.BiosInformationIcon'

    $outer = [System.Windows.Shapes.Rectangle]::new()
    $outer.Width = 72
    $outer.Height = 72
    $outer.RadiusX = 10
    $outer.RadiusY = 10
    $outer.StrokeThickness = 2
    $outer.Stroke = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Accent.Primary'
    $outer.Fill = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Background.Inset'
    [System.Windows.Controls.Canvas]::SetLeft($outer, 10)
    [System.Windows.Controls.Canvas]::SetTop($outer, 10)
    [void]$canvas.Children.Add($outer)

    $chip = [System.Windows.Shapes.Rectangle]::new()
    $chip.Width = 34
    $chip.Height = 34
    $chip.RadiusX = 5
    $chip.RadiusY = 5
    $chip.StrokeThickness = 1.5
    $chip.Stroke = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Risk.DeviceSpecific.Border'
    $chip.Fill = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Surface.Raised'
    [System.Windows.Controls.Canvas]::SetLeft($chip, 29)
    [System.Windows.Controls.Canvas]::SetTop($chip, 29)
    [void]$canvas.Children.Add($chip)

    foreach ($pin in @(
        [ordered]@{ X = 18; Y = 24; W = 8; H = 2 }
        [ordered]@{ X = 18; Y = 38; W = 8; H = 2 }
        [ordered]@{ X = 18; Y = 52; W = 8; H = 2 }
        [ordered]@{ X = 66; Y = 24; W = 8; H = 2 }
        [ordered]@{ X = 66; Y = 38; W = 8; H = 2 }
        [ordered]@{ X = 66; Y = 52; W = 8; H = 2 }
    )) {
        $line = [System.Windows.Shapes.Rectangle]::new()
        $line.Width = [double]$pin['W']
        $line.Height = [double]$pin['H']
        $line.Fill = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Border.Strong'
        [System.Windows.Controls.Canvas]::SetLeft($line, [double]$pin['X'])
        [System.Windows.Controls.Canvas]::SetTop($line, [double]$pin['Y'])
        [void]$canvas.Children.Add($line)
    }

    $spark = [System.Windows.Shapes.Ellipse]::new()
    $spark.Width = 9
    $spark.Height = 9
    $spark.Fill = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Accent.Hover'
    [System.Windows.Controls.Canvas]::SetLeft($spark, 58)
    [System.Windows.Controls.Canvas]::SetTop($spark, 20)
    [void]$canvas.Children.Add($spark)

    return $canvas
}

function New-AxisStageProgressStrip {
    [CmdletBinding()]
    param(
        [System.Collections.IEnumerable]$Stages,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    $strip = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Background.Panel' `
        -BorderBrushKey 'Axis.Brush.Border.Divider' `
        -RadiusKey 'Axis.Radius.None' `
        -Padding (New-AxisWizardThickness -Left 28 -Top 12 -Right 28 -Bottom 12) `
        -BorderThickness (New-AxisWizardThickness -Left 0 -Top 1 -Right 0 -Bottom 1)
    $strip.Tag = 'AxisFirstUseWizard.StageProgressStrip'

    $grid = [System.Windows.Controls.Grid]::new()
    $grid.Tag = 'AxisFirstUseWizard.StageProgressGrid'

    $stageItems = @($Stages)
    foreach ($stage in $stageItems) {
        $column = [System.Windows.Controls.ColumnDefinition]::new()
        $column.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        [void]$grid.ColumnDefinitions.Add($column)
    }

    for ($index = 0; $index -lt $stageItems.Count; $index++) {
        $stage = $stageItems[$index]
        $stageName = [string](Get-AxisWizardMapValue -Map $stage -Name 'Name')
        $stageState = [string](Get-AxisWizardMapValue -Map $stage -Name 'State' -DefaultValue 'Future')
        $progress = [double](Get-AxisWizardMapValue -Map $stage -Name 'Progress' -DefaultValue 0.0)

        if ($stageState -eq 'Complete') {
            $progress = 1.0
        }

        $item = [System.Windows.Controls.StackPanel]::new()
        $item.Orientation = [System.Windows.Controls.Orientation]::Vertical
        $item.Margin = New-AxisWizardThickness -Left 0 -Top 0 -Right 10 -Bottom 0
        $item.Tag = 'AxisFirstUseWizard.StageProgressItem'

        $labelForeground = if ($stageState -eq 'Current') {
            'Axis.Brush.Accent.Text'
        }
        elseif ($stageState -eq 'Complete') {
            'Axis.Status.Completed.TextBrush'
        }
        else {
            'Axis.Brush.Text.Muted'
        }

        [void]$item.Children.Add((New-AxisWizardTextBlock `
            -Text $stageName `
            -Resources $Resources `
            -FontSizeKey 'Axis.Type.Caption.FontSize' `
            -FontWeightKey 'Axis.Type.Micro.FontWeight' `
            -ForegroundKey $labelForeground))

        $barBackground = [System.Windows.Controls.Border]::new()
        $barBackground.Height = 4
        $barBackground.Margin = New-AxisWizardThickness -Left 0 -Top 8 -Right 0 -Bottom 0
        $barBackground.CornerRadius = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Radius.Small'
        $barBackground.Background = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Surface.InteractivePressed'

        $fill = [System.Windows.Controls.Border]::new()
        $fill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
        $fill.Width = [Math]::Max(0, [Math]::Min(1, $progress)) * 86
        $fill.CornerRadius = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Radius.Small'
        $fill.Background = if ($stageState -eq 'Complete') {
            Get-AxisWizardResource -Resources $Resources -Name 'Axis.Status.Completed.Brush'
        }
        elseif ($stageState -eq 'Current') {
            Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Accent.Primary'
        }
        else {
            Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Border.Subtle'
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
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'DocumentationLabel' -DefaultValue 'View documentation')) `
        -Resources $Resources `
        -Variant 'Quiet'
    $button.Tag = 'AxisFirstUseWizard.DocumentationButton'
    return $button
}

function New-AxisStepStatusArea {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Step,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    $state = [string](Get-AxisWizardMapValue -Map $Step -Name 'State' -DefaultValue 'Ready')
    $stateLabel = [string](Get-AxisWizardMapValue -Map $Step -Name 'StateLabel' -DefaultValue 'Ready')
    $statusName = Get-AxisWizardStatusResourceName -State $state
    $statusText = if ($state -eq 'Completed') {
        [string](Get-AxisWizardMapValue -Map $Step -Name 'CompletedStatusText' -DefaultValue 'Completed')
    }
    elseif ($state -in @('Checking', 'Running')) {
        [string](Get-AxisWizardMapValue -Map $Step -Name 'RunningStatusText' -DefaultValue 'Checking...')
    }
    else {
        [string](Get-AxisWizardMapValue -Map $Step -Name 'ReadyStatusText' -DefaultValue 'Ready when you are.')
    }

    $panel = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey "Axis.Status.$statusName.BackgroundBrush" `
        -BorderBrushKey "Axis.Status.$statusName.BorderBrush" `
        -RadiusKey 'Axis.Radius.Large' `
        -Padding (New-AxisWizardThickness -Left 14 -Top 12 -Right 14 -Bottom 12) `
        -Margin (New-AxisWizardThickness -Left 0 -Top 16 -Right 0 -Bottom 0)
    $panel.Tag = 'AxisFirstUseWizard.StepStatusArea'

    $stack = [System.Windows.Controls.StackPanel]::new()
    $stack.Orientation = [System.Windows.Controls.Orientation]::Vertical
    [void]$stack.Children.Add((New-AxisWizardTextBlock `
        -Text $stateLabel `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -FontWeightKey 'Axis.Type.Micro.FontWeight' `
        -ForegroundKey "Axis.Status.$statusName.TextBrush"))
    [void]$stack.Children.Add((New-AxisWizardTextBlock `
        -Text $statusText `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.Caption.FontSize' `
        -ForegroundKey "Axis.Status.$statusName.TextBrush" `
        -Margin (New-AxisWizardThickness -Left 0 -Top 4 -Right 0 -Bottom 0) `
        -Wrap))

    $panel.Child = $stack
    return $panel
}

function New-AxisStepPrimaryActionArea {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Step,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    $requiresAcknowledgement = [bool](Get-AxisWizardMapValue -Map $Step -Name 'RequiresDocumentationAcknowledgement' -DefaultValue $false)
    $acknowledged = [bool](Get-AxisWizardMapValue -Map $Step -Name 'Acknowledged' -DefaultValue $false)
    $primaryEnabled = -not $requiresAcknowledgement -or $acknowledged
    $state = [string](Get-AxisWizardMapValue -Map $Step -Name 'State' -DefaultValue 'Ready')
    $buttonText = if ($state -in @('Checking', 'Running')) {
        [string](Get-AxisWizardMapValue -Map $Step -Name 'RunningActionLabel' -DefaultValue 'Checking...')
    }
    else {
        [string](Get-AxisWizardMapValue -Map $Step -Name 'PrimaryActionLabel' -DefaultValue 'Continue')
    }

    $panel = [System.Windows.Controls.StackPanel]::new()
    $panel.Orientation = [System.Windows.Controls.Orientation]::Vertical
    $panel.Tag = 'AxisFirstUseWizard.PrimaryActionArea'

    if ($requiresAcknowledgement) {
        $checkbox = [System.Windows.Controls.CheckBox]::new()
        $checkbox.Content = [string](Get-AxisWizardMapValue -Map $Step -Name 'DocumentationAcknowledgementText' -DefaultValue 'I have read the instructions for this step.')
        $checkbox.IsChecked = $acknowledged
        $checkbox.IsHitTestVisible = $false
        $checkbox.Focusable = $false
        $checkbox.Margin = New-AxisWizardThickness -Left 0 -Top 0 -Right 0 -Bottom 12
        $checkbox.Foreground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Text.Secondary'
        $checkbox.FontFamily = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontFamily'
        $checkbox.FontSize = [double](Get-AxisWizardResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontSize')
        $checkbox.Tag = 'AxisFirstUseWizard.DocumentationAcknowledgement'
        [void]$panel.Children.Add($checkbox)
    }

    $buttonRow = [System.Windows.Controls.StackPanel]::new()
    $buttonRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $buttonRow.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    [void]$buttonRow.Children.Add((New-AxisWizardButton -Text $buttonText -Resources $Resources -Variant 'Primary' -Enabled $primaryEnabled))
    [void]$buttonRow.Children.Add((New-AxisStepDocumentationButton -Step $Step -Resources $Resources))
    [void]$panel.Children.Add($buttonRow)

    return $panel
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

    $container = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Surface.Base' `
        -BorderBrushKey 'Axis.Brush.Border.Subtle' `
        -RadiusKey 'Axis.Radius.XLarge' `
        -Padding (New-AxisWizardThickness -Left 32 -Top 28 -Right 32 -Bottom 28)
    $container.Tag = 'AxisFirstUseWizard.BiosInformationStep'

    $grid = [System.Windows.Controls.Grid]::new()
    $iconColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $iconColumn.Width = [System.Windows.GridLength]::new(120)
    $contentColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $contentColumn.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    [void]$grid.ColumnDefinitions.Add($iconColumn)
    [void]$grid.ColumnDefinitions.Add($contentColumn)

    $icon = New-AxisStepIcon -Resources $Resources
    [System.Windows.Controls.Grid]::SetColumn($icon, 0)
    [void]$grid.Children.Add($icon)

    $content = [System.Windows.Controls.StackPanel]::new()
    $content.Orientation = [System.Windows.Controls.Orientation]::Vertical

    [void]$content.Children.Add((New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue 'Check')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.Caption.FontSize' `
        -FontWeightKey 'Axis.Type.Micro.FontWeight' `
        -ForegroundKey 'Axis.Brush.Accent.Text'))
    [void]$content.Children.Add((New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'Title' -DefaultValue 'BIOS Information')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.PageTitle.FontSize' `
        -FontWeightKey 'Axis.Type.PageTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Text.Primary' `
        -Margin (New-AxisWizardThickness -Left 0 -Top 4 -Right 0 -Bottom 8)))
    [void]$content.Children.Add((New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'Description')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.Body.FontSize' `
        -ForegroundKey 'Axis.Brush.Text.Secondary' `
        -Wrap))

    $detailsGrid = [System.Windows.Controls.Grid]::new()
    $detailsGrid.Margin = New-AxisWizardThickness -Left 0 -Top 20 -Right 0 -Bottom 18
    $detailsGrid.Tag = 'AxisFirstUseWizard.StepDetails'
    $leftDetail = [System.Windows.Controls.ColumnDefinition]::new()
    $leftDetail.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $rightDetail = [System.Windows.Controls.ColumnDefinition]::new()
    $rightDetail.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    [void]$detailsGrid.ColumnDefinitions.Add($leftDetail)
    [void]$detailsGrid.ColumnDefinitions.Add($rightDetail)

    $checksPanel = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Background.Inset' `
        -BorderBrushKey 'Axis.Brush.Border.Divider' `
        -RadiusKey 'Axis.Radius.Large' `
        -Padding (New-AxisWizardThickness -Left 14)
    $checksStack = [System.Windows.Controls.StackPanel]::new()
    [void]$checksStack.Children.Add((New-AxisWizardTextBlock `
        -Text 'What this step checks' `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.CardTitle.FontSize' `
        -FontWeightKey 'Axis.Type.CardTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Text.Primary' `
        -Margin (New-AxisWizardThickness -Left 0 -Top 0 -Right 0 -Bottom 8)))
    foreach ($item in @(Get-AxisWizardMapValue -Map $Step -Name 'WhatThisStepChecks' -DefaultValue @())) {
        [void]$checksStack.Children.Add((New-AxisWizardTextBlock `
            -Text ("- {0}" -f [string]$item) `
            -Resources $Resources `
            -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
            -ForegroundKey 'Axis.Brush.Text.Secondary' `
            -Wrap))
    }
    $checksPanel.Child = $checksStack
    [System.Windows.Controls.Grid]::SetColumn($checksPanel, 0)
    [void]$detailsGrid.Children.Add($checksPanel)

    $requirementsPanel = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Background.Inset' `
        -BorderBrushKey 'Axis.Brush.Border.Divider' `
        -RadiusKey 'Axis.Radius.Large' `
        -Padding (New-AxisWizardThickness -Left 14) `
        -Margin (New-AxisWizardThickness -Left 12 -Top 0 -Right 0 -Bottom 0)
    $requirementsStack = [System.Windows.Controls.StackPanel]::new()
    [void]$requirementsStack.Children.Add((New-AxisWizardTextBlock `
        -Text 'Requirements' `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.CardTitle.FontSize' `
        -FontWeightKey 'Axis.Type.CardTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Text.Primary' `
        -Margin (New-AxisWizardThickness -Left 0 -Top 0 -Right 0 -Bottom 8)))
    foreach ($item in @(Get-AxisWizardMapValue -Map $Step -Name 'Requirements' -DefaultValue @())) {
        [void]$requirementsStack.Children.Add((New-AxisWizardTextBlock `
            -Text ("- {0}" -f [string]$item) `
            -Resources $Resources `
            -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
            -ForegroundKey 'Axis.Brush.Text.Secondary' `
            -Wrap))
    }
    $requirementsPanel.Child = $requirementsStack
    [System.Windows.Controls.Grid]::SetColumn($requirementsPanel, 1)
    [void]$detailsGrid.Children.Add($requirementsPanel)
    [void]$content.Children.Add($detailsGrid)

    [void]$content.Children.Add((New-AxisStepPrimaryActionArea -Step $Step -Resources $Resources))
    [void]$content.Children.Add((New-AxisStepStatusArea -Step $Step -Resources $Resources))

    [System.Windows.Controls.Grid]::SetColumn($content, 1)
    [void]$grid.Children.Add($content)
    $container.Child = $grid

    return $container
}

function New-AxisWizardStepContent {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$SampleState = (Get-AxisFirstUseWizardSampleState),

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    $step = Get-AxisWizardMapValue -Map $SampleState -Name 'Step'
    return New-AxisBiosInformationStep -Step $step -Resources $Resources
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
    $root.Width = [double](Get-AxisWizardMapValue -Map $windowInfo -Name 'Width' -DefaultValue 900.0)
    $root.Height = [double](Get-AxisWizardMapValue -Map $windowInfo -Name 'Height' -DefaultValue 650.0)
    $root.MinWidth = 900
    $root.MinHeight = 650
    $root.Background = Get-AxisWizardResource -Resources $resources -Name 'Axis.Brush.Background.App'
    [void](Add-AxisResourcesToElement -Element $root -Resources $resources)

    foreach ($height in @(76, 72, 1, 76)) {
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
        -BackgroundKey 'Axis.Brush.Background.Panel' `
        -BorderBrushKey 'Axis.Brush.Border.Divider' `
        -RadiusKey 'Axis.Radius.None' `
        -Padding (New-AxisWizardThickness -Left 28 -Top 16 -Right 28 -Bottom 14) `
        -BorderThickness (New-AxisWizardThickness -Left 0 -Top 0 -Right 0 -Bottom 1)
    $header.Tag = 'AxisFirstUseWizard.Header'

    $headerGrid = [System.Windows.Controls.Grid]::new()
    $leftColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $leftColumn.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $rightColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $rightColumn.Width = [System.Windows.GridLength]::Auto
    [void]$headerGrid.ColumnDefinitions.Add($leftColumn)
    [void]$headerGrid.ColumnDefinitions.Add($rightColumn)

    $brandStack = [System.Windows.Controls.StackPanel]::new()
    $brandStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    [void]$brandStack.Children.Add((New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $SampleState -Name 'BrandName' -DefaultValue 'AXIS')) `
        -Resources $resources `
        -FontSizeKey 'Axis.Type.PageTitle.FontSize' `
        -FontWeightKey 'Axis.Type.PageTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Text.Primary'))
    [void]$brandStack.Children.Add((New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $SampleState -Name 'ModeLabel' -DefaultValue 'Guided setup')) `
        -Resources $resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -ForegroundKey 'Axis.Brush.Accent.Text' `
        -Margin (New-AxisWizardThickness -Left 18 -Top 9 -Right 0 -Bottom 0)))
    [System.Windows.Controls.Grid]::SetColumn($brandStack, 0)
    [void]$headerGrid.Children.Add($brandStack)

    $stageText = New-AxisWizardTextBlock `
        -Text ("Stage: {0}" -f [string](Get-AxisWizardMapValue -Map $SampleState -Name 'CurrentStageName' -DefaultValue 'Check')) `
        -Resources $resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -ForegroundKey 'Axis.Brush.Text.Secondary' `
        -Margin (New-AxisWizardThickness -Left 0 -Top 9 -Right 0 -Bottom 0)
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

    $contentHost = [System.Windows.Controls.Grid]::new()
    $contentHost.Margin = New-AxisWizardThickness -Left 42 -Top 28 -Right 42 -Bottom 22
    $contentHost.Tag = 'AxisFirstUseWizard.StepContentHost'
    [void]$contentHost.Children.Add((New-AxisWizardStepContent -SampleState $SampleState -Resources $resources))
    [System.Windows.Controls.Grid]::SetRow($contentHost, 2)
    [void]$root.Children.Add($contentHost)

    $bottom = New-AxisWizardPanel `
        -Resources $resources `
        -BackgroundKey 'Axis.Brush.Background.Panel' `
        -BorderBrushKey 'Axis.Brush.Border.Divider' `
        -RadiusKey 'Axis.Radius.None' `
        -Padding (New-AxisWizardThickness -Left 28 -Top 16 -Right 28 -Bottom 16) `
        -BorderThickness (New-AxisWizardThickness -Left 0 -Top 1 -Right 0 -Bottom 0)
    $bottom.Tag = 'AxisFirstUseWizard.BottomNavigation'

    $bottomGrid = [System.Windows.Controls.Grid]::new()
    $bottomLeft = [System.Windows.Controls.ColumnDefinition]::new()
    $bottomLeft.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $bottomRight = [System.Windows.Controls.ColumnDefinition]::new()
    $bottomRight.Width = [System.Windows.GridLength]::Auto
    [void]$bottomGrid.ColumnDefinitions.Add($bottomLeft)
    [void]$bottomGrid.ColumnDefinitions.Add($bottomRight)

    $note = New-AxisWizardTextBlock `
        -Text 'Prototype only. Buttons are visual and no setup step runs from this window.' `
        -Resources $resources `
        -FontSizeKey 'Axis.Type.Caption.FontSize' `
        -ForegroundKey 'Axis.Brush.Text.Muted' `
        -Margin (New-AxisWizardThickness -Left 0 -Top 9 -Right 0 -Bottom 0)
    [System.Windows.Controls.Grid]::SetColumn($note, 0)
    [void]$bottomGrid.Children.Add($note)

    $buttons = [System.Windows.Controls.StackPanel]::new()
    $buttons.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $buttons.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $buttons.Tag = 'AxisFirstUseWizard.BottomButtons'
    [void]$buttons.Children.Add((New-AxisWizardButton -Text 'Back' -Resources $resources -Variant 'Quiet'))
    [void]$buttons.Children.Add((New-AxisWizardButton -Text 'Continue' -Resources $resources -Variant 'Primary'))
    [void]$buttons.Children.Add((New-AxisWizardButton -Text 'Cancel' -Resources $resources -Variant 'Secondary'))
    [System.Windows.Controls.Grid]::SetColumn($buttons, 1)
    [void]$bottomGrid.Children.Add($buttons)

    $bottom.Child = $bottomGrid
    [System.Windows.Controls.Grid]::SetRow($bottom, 3)
    [void]$root.Children.Add($bottom)

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
    $window.ResizeMode = [System.Windows.ResizeMode]::NoResize
    $window.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterScreen
    $window.Content = New-AxisFirstUseWizardPrototype -SampleState $SampleState
    return $window
}
