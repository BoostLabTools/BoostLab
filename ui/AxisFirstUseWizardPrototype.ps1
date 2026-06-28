Set-StrictMode -Version Latest

$script:AxisFirstUseWizardResourcePath = Join-Path $PSScriptRoot 'AxisResources.ps1'
. $script:AxisFirstUseWizardResourcePath
$script:AxisFirstUseWizardButtonStyle = $null

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
                Progress = $(if ($index -eq 0) { 0.84 } else { 0.0 })
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
                    0.84
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

function Get-AxisWizardButtonStyle {
    [CmdletBinding()]
    param()

    if ($null -eq $script:AxisFirstUseWizardButtonStyle) {
        $styleXaml = @'
<Style xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
       xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
       TargetType="{x:Type Button}">
  <Setter Property="MinHeight" Value="36" />
  <Setter Property="Template">
    <Setter.Value>
      <ControlTemplate TargetType="{x:Type Button}">
        <Border x:Name="Chrome"
                Background="{TemplateBinding Background}"
                BorderBrush="{TemplateBinding BorderBrush}"
                BorderThickness="{TemplateBinding BorderThickness}"
                CornerRadius="14"
                Padding="{TemplateBinding Padding}"
                SnapsToDevicePixels="True">
          <ContentPresenter HorizontalAlignment="Center"
                            VerticalAlignment="Center"
                            RecognizesAccessKey="True" />
        </Border>
        <ControlTemplate.Triggers>
          <Trigger Property="IsEnabled" Value="False">
            <Setter TargetName="Chrome" Property="Opacity" Value="0.62" />
          </Trigger>
        </ControlTemplate.Triggers>
      </ControlTemplate>
    </Setter.Value>
  </Setter>
</Style>
'@
        $script:AxisFirstUseWizardButtonStyle = [System.Windows.Markup.XamlReader]::Parse($styleXaml)
    }

    return $script:AxisFirstUseWizardButtonStyle
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
    if ($Width -gt 0) {
        $button.Width = $Width
    }
    $button.Style = Get-AxisWizardButtonStyle
    $button.Focusable = $false
    $button.IsHitTestVisible = $false
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
        Stages = @(Get-AxisFirstUseWizardCanonicalStages)
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
    $strip.ClipToBounds = $true

    $grid = [System.Windows.Controls.Grid]::new()
    $grid.Tag = 'AxisFirstUseWizard.StageProgressGrid'
    $grid.ClipToBounds = $true

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
        $progress = [double](Get-AxisWizardMapValue -Map $stage -Name 'Progress' -DefaultValue 0.0)

        if ($stageState -eq 'Complete') {
            $progress = 1.0
        }

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
        [void]$item.Children.Add($label)

        $barBackground = [System.Windows.Controls.Border]::new()
        $barBackground.Height = 3
        $barBackground.Margin = New-AxisWizardThickness -Left 0 -Top 6 -Right 0 -Bottom 0
        $barBackground.CornerRadius = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Radius.Small'
        $barBackground.Background = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.SurfaceSoft'
        $barBackground.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $barBackground.ClipToBounds = $true

        $fill = [System.Windows.Controls.Border]::new()
        $fill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
        $fill.Width = [Math]::Max(0, [Math]::Min(1, $progress)) * 104
        $fill.CornerRadius = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Radius.Small'
        $fill.Background = if ($stageState -eq 'Complete') {
            Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.StateCompleted.Border'
        }
        elseif ($stageState -eq 'Current') {
            Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.Accent'
        }
        else {
            Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.BorderSoft'
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
        -Variant 'Quiet' `
        -Width 180 `
        -Height 42 `
        -Margin (New-AxisWizardThickness -Left 14 -Top 0 -Right 0 -Bottom 0)
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
    $stateResources = Get-AxisWizardStepStateResourceKeys -State $state
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
        -BackgroundKey ([string]$stateResources['Background']) `
        -BorderBrushKey ([string]$stateResources['Border']) `
        -RadiusKey 'Axis.Radius.Wizard.StatusPanel' `
        -Padding (New-AxisWizardThickness -Left 12 -Top 7 -Right 12 -Bottom 7) `
        -Margin (New-AxisWizardThickness -Left 0 -Top 8 -Right 0 -Bottom 0)
    $panel.MinHeight = 52
    $panel.Tag = 'AxisFirstUseWizard.StepStatusArea'

    $stack = [System.Windows.Controls.StackPanel]::new()
    $stack.Orientation = [System.Windows.Controls.Orientation]::Vertical
    [void]$stack.Children.Add((New-AxisWizardTextBlock `
        -Text $stateLabel `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -FontWeightKey 'Axis.Type.Micro.FontWeight' `
        -ForegroundKey ([string]$stateResources['Text'])))
    [void]$stack.Children.Add((New-AxisWizardTextBlock `
        -Text $statusText `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.Caption.FontSize' `
        -ForegroundKey ([string]$stateResources['Text']) `
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
        $checkbox.Foreground = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Brush.Wizard.TextSecondary'
        $checkbox.FontFamily = Get-AxisWizardResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontFamily'
        $checkbox.FontSize = [double](Get-AxisWizardResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontSize')
        $checkbox.Tag = 'AxisFirstUseWizard.DocumentationAcknowledgement'
        [void]$panel.Children.Add($checkbox)
    }

    $buttonRow = [System.Windows.Controls.StackPanel]::new()
    $buttonRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $buttonRow.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    [void]$buttonRow.Children.Add((New-AxisWizardButton `
        -Text $buttonText `
        -Resources $Resources `
        -Variant 'Primary' `
        -Enabled $primaryEnabled `
        -Width 235 `
        -Height 42 `
        -Margin (New-AxisWizardThickness -Left 0)))
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
        -BackgroundKey 'Axis.Brush.Wizard.MainCardBackground' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderSoft' `
        -RadiusKey 'Axis.Radius.Wizard.MainCard' `
        -Padding (New-AxisWizardThickness -Left 36 -Top 20 -Right 34 -Bottom 16) `
        -Elevation 'Card'
    $container.Height = 382
    $container.Tag = 'AxisFirstUseWizard.BiosInformationStep'

    $content = [System.Windows.Controls.StackPanel]::new()
    $content.Orientation = [System.Windows.Controls.Orientation]::Vertical
    $content.Tag = 'AxisFirstUseWizard.StepTextContent'

    [void]$content.Children.Add((New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'StageName' -DefaultValue 'Check')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -FontWeightKey 'Axis.Type.Micro.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.AccentText'))
    [void]$content.Children.Add((New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'Title' -DefaultValue 'BIOS Information')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.PageTitle.FontSize' `
        -FontWeightKey 'Axis.Type.PageTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.TextPrimary' `
        -Margin (New-AxisWizardThickness -Left 0 -Top 4 -Right 0 -Bottom 8)))
    [void]$content.Children.Add((New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'Description')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.Body.FontSize' `
        -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
        -Wrap))

    $detailsGrid = [System.Windows.Controls.Grid]::new()
    $detailsGrid.Margin = New-AxisWizardThickness -Left 0 -Top 10 -Right 0 -Bottom 8
    $detailsGrid.Tag = 'AxisFirstUseWizard.StepDetails'
    $leftDetail = [System.Windows.Controls.ColumnDefinition]::new()
    $leftDetail.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $rightDetail = [System.Windows.Controls.ColumnDefinition]::new()
    $rightDetail.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    [void]$detailsGrid.ColumnDefinitions.Add($leftDetail)
    [void]$detailsGrid.ColumnDefinitions.Add($rightDetail)

    $checksPanel = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Wizard.InfoCard' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderSoft' `
        -RadiusKey 'Axis.Radius.Wizard.InfoCard' `
        -Padding (New-AxisWizardThickness -Left 15 -Top 10 -Right 15 -Bottom 10) `
        -Elevation 'Soft'
    $checksPanel.MinHeight = 96
    $checksStack = [System.Windows.Controls.StackPanel]::new()
    [void]$checksStack.Children.Add((New-AxisWizardTextBlock `
        -Text 'What this step checks' `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.CardTitle.FontSize' `
        -FontWeightKey 'Axis.Type.CardTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.TextPrimary' `
        -Margin (New-AxisWizardThickness -Left 0 -Top 0 -Right 0 -Bottom 8)))
    foreach ($item in @(Get-AxisWizardMapValue -Map $Step -Name 'WhatThisStepChecks' -DefaultValue @())) {
        [void]$checksStack.Children.Add((New-AxisWizardTextBlock `
            -Text ("- {0}" -f [string]$item) `
            -Resources $Resources `
            -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
            -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
            -Wrap))
    }
    $checksPanel.Child = $checksStack
    [System.Windows.Controls.Grid]::SetColumn($checksPanel, 0)
    [void]$detailsGrid.Children.Add($checksPanel)

    $requirementsPanel = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Wizard.ElevatedCard' `
        -BorderBrushKey 'Axis.Brush.Wizard.BorderSoft' `
        -RadiusKey 'Axis.Radius.Wizard.InfoCard' `
        -Padding (New-AxisWizardThickness -Left 15 -Top 10 -Right 15 -Bottom 10) `
        -Margin (New-AxisWizardThickness -Left 16 -Top 0 -Right 0 -Bottom 0) `
        -Elevation 'Soft'
    $requirementsPanel.MinHeight = 96
    $requirementsStack = [System.Windows.Controls.StackPanel]::new()
    [void]$requirementsStack.Children.Add((New-AxisWizardTextBlock `
        -Text 'Requirements' `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.CardTitle.FontSize' `
        -FontWeightKey 'Axis.Type.CardTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.TextPrimary' `
        -Margin (New-AxisWizardThickness -Left 0 -Top 0 -Right 0 -Bottom 8)))
    foreach ($item in @(Get-AxisWizardMapValue -Map $Step -Name 'Requirements' -DefaultValue @())) {
        [void]$requirementsStack.Children.Add((New-AxisWizardTextBlock `
            -Text ("- {0}" -f [string]$item) `
            -Resources $Resources `
            -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
            -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
            -Wrap))
    }
    $requirementsPanel.Child = $requirementsStack
    [System.Windows.Controls.Grid]::SetColumn($requirementsPanel, 1)
    [void]$detailsGrid.Children.Add($requirementsPanel)
    [void]$content.Children.Add($detailsGrid)

    [void]$content.Children.Add((New-AxisStepPrimaryActionArea -Step $Step -Resources $Resources))
    [void]$content.Children.Add((New-AxisStepStatusArea -Step $Step -Resources $Resources))

    $container.Child = $content

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
    $root.Width = [double]::NaN
    $root.Height = [double]::NaN
    $root.MinWidth = 0
    $root.MinHeight = 0
    $root.Background = Get-AxisWizardResource -Resources $resources -Name 'Axis.Brush.Wizard.Background'
    $root.ClipToBounds = $true
    $root.UseLayoutRounding = $true
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
        -FontSizeKey 'Axis.Type.Display.FontSize' `
        -FontWeightKey 'Axis.Type.Display.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.TextPrimary'))
    [void]$brandStack.Children.Add((New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $SampleState -Name 'ModeLabel' -DefaultValue 'Guided setup')) `
        -Resources $resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -ForegroundKey 'Axis.Brush.Wizard.AccentText' `
        -Margin (New-AxisWizardThickness -Left 18 -Top 13 -Right 0 -Bottom 0)))
    [System.Windows.Controls.Grid]::SetColumn($brandStack, 0)
    [void]$headerGrid.Children.Add($brandStack)

    $stageText = New-AxisWizardTextBlock `
        -Text ("Stage: {0}" -f [string](Get-AxisWizardMapValue -Map $SampleState -Name 'CurrentStageName' -DefaultValue 'Check')) `
        -Resources $resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
        -Margin (New-AxisWizardThickness -Left 0 -Top 13 -Right 0 -Bottom 0)
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

    $contentHost = [System.Windows.Controls.Border]::new()
    $contentHost.Padding = New-AxisWizardThickness -Left 37 -Top 13 -Right 37 -Bottom 8
    $contentHost.Background = Get-AxisWizardResource -Resources $resources -Name 'Axis.Brush.Wizard.Background'
    $contentHost.ClipToBounds = $true
    $contentHost.Tag = 'AxisFirstUseWizard.StepContentHost'
    $contentHost.Child = New-AxisWizardStepContent -SampleState $SampleState -Resources $resources
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
        -ForegroundKey 'Axis.Brush.Wizard.TextMuted'
    $note.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    [System.Windows.Controls.Grid]::SetColumn($note, 0)
    [void]$bottomGrid.Children.Add($note)

    $buttons = [System.Windows.Controls.StackPanel]::new()
    $buttons.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $buttons.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $buttons.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $buttons.Tag = 'AxisFirstUseWizard.BottomButtons'
    [void]$buttons.Children.Add((New-AxisWizardButton `
        -Text 'Back' `
        -Resources $resources `
        -Variant 'Quiet' `
        -Width 82 `
        -Height 40 `
        -Margin (New-AxisWizardThickness -Left 0)))
    [void]$buttons.Children.Add((New-AxisWizardButton `
        -Text 'Continue' `
        -Resources $resources `
        -Variant 'Primary' `
        -Width 102 `
        -Height 40 `
        -Margin (New-AxisWizardThickness -Left 16 -Top 0 -Right 0 -Bottom 0)))
    [void]$buttons.Children.Add((New-AxisWizardButton `
        -Text 'Cancel' `
        -Resources $resources `
        -Variant 'Secondary' `
        -Width 82 `
        -Height 40 `
        -Margin (New-AxisWizardThickness -Left 16 -Top 0 -Right 0 -Bottom 0)))
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
    $window.WindowStyle = [System.Windows.WindowStyle]::SingleBorderWindow
    $window.ResizeMode = [System.Windows.ResizeMode]::NoResize
    $window.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterScreen
    $window.Background = Get-AxisWizardResource -Resources (New-AxisWpfResourceDictionary) -Name 'Axis.Brush.Wizard.WindowSurface'
    $window.UseLayoutRounding = $true
    $window.SnapsToDevicePixels = $true
    $window.Content = New-AxisFirstUseWizardPrototype -SampleState $SampleState
    return $window
}
