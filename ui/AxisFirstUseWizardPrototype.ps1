Set-StrictMode -Version Latest

$script:AxisFirstUseWizardResourcePath = Join-Path $PSScriptRoot 'AxisResources.ps1'
. $script:AxisFirstUseWizardResourcePath
$script:AxisFirstUseWizardButtonStyle = $null
$script:AxisFirstUseWizardFilledSquareCheckboxStyle = $null

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

        [double]$MaxWidth = 0.0
    )

    $anchor = [System.Windows.Controls.Grid]::new()
    $anchor.Tag = $Tag
    $anchor.FlowDirection = [System.Windows.FlowDirection]::LeftToRight
    $anchor.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch

    $Child.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $Child.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
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
            'ReinstallCompleted'
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
    }
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
    $contentWidth = if ($isBiosSettingsStep) { 228.0 } elseif ($isReinstallStep) { 210.0 } else { 190.0 }
    $labelAnchorMaxWidth = if ($isBiosSettingsStep) { 126.0 } elseif ($isReinstallStep) { 106.0 } else { 86.0 }

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

    $panel = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey ([string]$stateResources['Background']) `
        -BorderBrushKey ([string]$stateResources['Border']) `
        -RadiusKey 'Axis.Radius.Wizard.StatusPanel' `
        -Padding (New-AxisWizardThickness -Left 12 -Top 6 -Right 12 -Bottom 6) `
        -Margin (New-AxisWizardThickness -Left 0)
    $panel.MinHeight = 42
    $panel.Width = if ($isBiosSettingsStep) { 252 } elseif ($isReinstallStep) { 234 } else { 214 }
    $panel.Tag = 'AxisFirstUseWizard.RuntimeStatusArea'
    if ($isBiosSettingsStep) {
        $panel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.BiosSettingsRuntimeStatusNoClipping')
    }
    elseif ($isReinstallStep) {
        $panel.SetValue([System.Windows.Automation.AutomationProperties]::AutomationIdProperty, 'AxisFirstUseWizard.ReinstallRuntimeStatusNoClipping')
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

    $stateResources = Get-AxisWizardStepStateResourceKeys -State 'Ready'
    $panel = New-AxisWizardPanel `
        -Resources $Resources `
        -BackgroundKey ([string]$stateResources['Background']) `
        -BorderBrushKey ([string]$stateResources['Border']) `
        -RadiusKey 'Axis.Radius.Wizard.StatusPanel' `
        -Padding (New-AxisWizardThickness -Left 14 -Top 8 -Right 14 -Bottom 8) `
        -Margin (New-AxisWizardThickness -Left 0 -Top 8 -Right 0 -Bottom 0)
    $panel.MinHeight = 58
    $panel.Tag = 'AxisFirstUseWizard.SupportPanel'
    $panel.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $panel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch

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
    $buttonText = [string](Get-AxisWizardMapValue -Map $Step -Name 'PrimaryActionLabel' -DefaultValue (Get-AxisWizardArabicText -Name 'Open'))
    $stepId = [string](Get-AxisWizardMapValue -Map $Step -Name 'Id')
    $primaryButtonWidth = if ($stepId -eq 'reinstall') { 320.0 } else { 142.0 }

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
        -Padding (New-AxisWizardThickness -Left 34 -Top 20 -Right 34 -Bottom 16) `
        -Elevation 'Card'
    $container.Height = 382
    $container.Tag = 'AxisFirstUseWizard.BiosInformationStep'
    $container.FlowDirection = [System.Windows.FlowDirection]::RightToLeft

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
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'Title' -DefaultValue 'BIOS Drivers & Downloads')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.PageTitle.FontSize' `
        -FontWeightKey 'Axis.Type.PageTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Wizard.TextPrimary' `
        -Margin (New-AxisWizardThickness -Left 0 -Top 4 -Right 0 -Bottom 8) `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::LeftToRight)))
    $descriptionText = New-AxisWizardTextBlock `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'Description')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.Body.FontSize' `
        -ForegroundKey 'Axis.Brush.Wizard.TextSecondary' `
        -TextAlignment ([System.Windows.TextAlignment]::Right) `
        -FlowDirection ([System.Windows.FlowDirection]::RightToLeft) `
        -Wrap
    [void](Add-AxisWizardGridRow -Grid $content -Child (New-AxisWizardRightAnchor `
        -Child $descriptionText `
        -Tag 'AxisFirstUseWizard.ArabicSubtitleRightAnchor' `
        -MaxWidth 690))

    $detailsGrid = [System.Windows.Controls.Grid]::new()
    $detailsGrid.Margin = New-AxisWizardThickness -Left 0 -Top 10 -Right 0 -Bottom 8
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
        -Padding (New-AxisWizardThickness -Left 15 -Top 10 -Right 15 -Bottom 10) `
        -Elevation 'Soft'
    $checksPanel.MinHeight = 96
    $checksPanel.Tag = 'AxisFirstUseWizard.InformationCard'
    $checksPanel.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $checksPanel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $checksStack = [System.Windows.Controls.Grid]::new()
    $checksStack.FlowDirection = [System.Windows.FlowDirection]::RightToLeft
    $checksStack.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $checksStack.MaxWidth = 650
    $checksStack.Tag = 'AxisFirstUseWizard.InformationCardContent'
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

function New-AxisFirstUseWizardStepContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Step,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    $stepId = [string](Get-AxisWizardMapValue -Map $Step -Name 'Id')
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
    $overlay.Padding = New-AxisWizardThickness -Left 260 -Top 190 -Right 260 -Bottom 190

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

    $confirmButton = New-AxisWizardButton `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'ConfirmationActionLabel' -DefaultValue (Get-AxisWizardArabicText -Name 'Open'))) `
        -Resources $Resources `
        -Variant 'Primary' `
        -Enabled $false `
        -Width 124 `
        -Height 42 `
        -Margin (New-AxisWizardThickness -Left 0)
    $confirmButton.Tag = 'AxisFirstUseWizard.ConfirmationOpenButton'
    $confirmButton.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right

    $returnButton = New-AxisWizardButton `
        -Text ([string](Get-AxisWizardMapValue -Map $Step -Name 'ConfirmationReturnLabel' -DefaultValue (Get-AxisWizardArabicText -Name 'Return'))) `
        -Resources $Resources `
        -Variant 'Quiet' `
        -Enabled $true `
        -Width 104 `
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
    [void]$buttonRow.Children.Add((New-AxisWizardSpacer -Width 12 -Tag 'AxisFirstUseWizard.ConfirmationReturnButtonSpacer'))
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
    $stepCompletedFlags = [bool[]]::new($steps.Count)
    $stepStageNames = [string[]]::new($steps.Count)
    for ($stepIndex = 0; $stepIndex -lt $steps.Count; $stepIndex++) {
        $stepMap = [System.Collections.IDictionary]$steps[$stepIndex]
        $stepViews[$stepIndex] = New-AxisFirstUseWizardStepContent -Step $stepMap -Resources $resources
        $requiresConfirmationAcknowledgement = [bool](Get-AxisWizardMapValue -Map $stepMap -Name 'RequiresConfirmationAcknowledgement' -DefaultValue $false)
        if ($requiresConfirmationAcknowledgement) {
            $stepOverlays[$stepIndex] = New-AxisStepAcknowledgementOverlay -Step $stepMap -Resources $resources
        }
        else {
            $stepOverlays[$stepIndex] = $null
        }
        $stepCompletedFlags[$stepIndex] = ([string](Get-AxisWizardMapValue -Map $stepMap -Name 'State' -DefaultValue 'Ready') -eq 'Completed')
        $stepStageNames[$stepIndex] = [string](Get-AxisWizardMapValue -Map $stepMap -Name 'StageName' -DefaultValue 'Check')
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
    $continueDisabledBackgroundForNavigation = $continueButton.Background
    $continueDisabledBorderForNavigation = $continueButton.BorderBrush
    $continueDisabledForegroundForNavigation = $continueButton.Foreground
    $continueDisabledEffectForNavigation = $continueButton.Effect
    $continueAutomationIdPropertyForNavigation = [System.Windows.Automation.AutomationProperties]::AutomationIdProperty

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
            }
            else {
                $continueButtonForNavigation.IsEnabled = $false
                $continueButtonForNavigation.SetValue($continueAutomationIdPropertyForNavigation, '')
                $continueButtonForNavigation.Background = $continueDisabledBackgroundForNavigation
                $continueButtonForNavigation.BorderBrush = $continueDisabledBorderForNavigation
                $continueButtonForNavigation.Foreground = $continueDisabledForegroundForNavigation
                $continueButtonForNavigation.Effect = $continueDisabledEffectForNavigation
            }
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
            }
            else {
                $continueButtonForNavigation.IsEnabled = $false
                $continueButtonForNavigation.SetValue($continueAutomationIdPropertyForNavigation, '')
                $continueButtonForNavigation.Background = $continueDisabledBackgroundForNavigation
                $continueButtonForNavigation.BorderBrush = $continueDisabledBorderForNavigation
                $continueButtonForNavigation.Foreground = $continueDisabledForegroundForNavigation
                $continueButtonForNavigation.Effect = $continueDisabledEffectForNavigation
            }
        }.GetNewClosure())
    }

    for ($handlerStepIndex = 0; $handlerStepIndex -lt $steps.Count; $handlerStepIndex++) {
        $handlerStep = [System.Collections.IDictionary]$steps[$handlerStepIndex]
        $handlerContent = $stepViews[$handlerStepIndex]
        $handlerOverlay = $stepOverlays[$handlerStepIndex]

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

        $checkingRuntimeStatusForHandler = New-AxisWizardRuntimeStatusContent -State 'Checking' -Step $handlerStep -Resources $resources
        $completedRuntimeStatusForHandler = New-AxisWizardRuntimeStatusContent -State 'Completed' -Step $handlerStep -Resources $resources
        $completionTimerForHandler = [System.Windows.Threading.DispatcherTimer]::new()
        $completionTimerForHandler.Interval = [TimeSpan]::FromMilliseconds(950)
        $handlerStepIndexForClosure = $handlerStepIndex
        $handlerOverlayForClosure = $handlerOverlay
        $runtimeStatusHostForHandler = $runtimeStatusHost
        $runtimeStatusSpacerForHandler = $runtimeStatusSpacer
        $confirmationAcknowledgementForHandler = $confirmationAcknowledgement
        $stepOverlaysForHandler = $stepOverlays
        $hasConfirmationOverlayForHandler = ($null -ne $handlerOverlay)
        $stepCompletedFlagsForHandler = $stepCompletedFlagsForNavigation
        $continueButtonForHandler = $continueButton
        $continueEnabledBlueMarkerForHandler = $continueEnabledBlueMarkerForNavigation
        $continueEnabledBlueBackgroundForHandler = $continueEnabledBlueBackgroundForNavigation
        $continueEnabledBlueBorderForHandler = $continueEnabledBlueBorderForNavigation
        $continueEnabledBlueForegroundForHandler = $continueEnabledBlueForegroundForNavigation
        $continueEnabledBlueEffectForHandler = $continueEnabledBlueEffectForNavigation
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
            }
        }.GetNewClosure())

        if ($primaryButton -is [System.Windows.Controls.Button]) {
            $primaryButton.Add_Click({
                foreach ($overlayForHandler in @($stepOverlaysForHandler)) {
                    if ($null -eq $overlayForHandler) {
                        continue
                    }

                    $overlayForHandler.Visibility = [System.Windows.Visibility]::Collapsed
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
