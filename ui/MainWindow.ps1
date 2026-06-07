Set-StrictMode -Version Latest

$script:BoostLabWindow = $null
$script:BoostLabStages = @()
$script:BoostLabStageButtons = @{}

function Get-BoostLabUiElement {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    return $script:BoostLabWindow.FindName($Name)
}

function New-BoostLabBadge {
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [string]$Background,

        [Parameter(Mandatory)]
        [string]$Foreground,

        [Parameter(Mandatory)]
        [string]$Border
    )

    $badge = [System.Windows.Controls.Border]::new()
    $badge.Height = 22
    $badge.Margin = [System.Windows.Thickness]::new(0, 0, 6, 0)
    $badge.Padding = [System.Windows.Thickness]::new(8, 0, 8, 0)
    $badge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Background)
    $badge.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Border)
    $badge.BorderThickness = [System.Windows.Thickness]::new(1)
    $badge.CornerRadius = [System.Windows.CornerRadius]::new(5)

    $label = [System.Windows.Controls.TextBlock]::new()
    $label.Text = $Text.ToUpperInvariant()
    $label.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Foreground)
    $label.FontSize = 10
    $label.FontWeight = [System.Windows.FontWeights]::SemiBold
    $label.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

    $badge.Child = $label
    return $badge
}

function New-BoostLabToolCard {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Tool
    )

    $toolId = [string]$Tool['Id']
    $toolTitle = [string]$Tool['Title']
    $stageName = [string]$Tool['Stage']
    $toolType = ([string]$Tool['Type']).ToLowerInvariant()
    $riskLevel = ([string]$Tool['RiskLevel']).ToLowerInvariant()

    $card = [System.Windows.Controls.Border]::new()
    $card.Width = 304
    $card.Height = 282
    $card.Margin = [System.Windows.Thickness]::new(0, 0, 14, 14)
    $card.Padding = [System.Windows.Thickness]::new(16)
    $card.CornerRadius = [System.Windows.CornerRadius]::new(10)

    if ($riskLevel -eq 'high') {
        $card.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#211B29')
        $card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#9A5967')
        $card.BorderThickness = [System.Windows.Thickness]::new(3, 1, 1, 1)
    }
    elseif ($toolType -eq 'assistant') {
        $card.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#191E35')
        $card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#514B82')
        $card.BorderThickness = [System.Windows.Thickness]::new(1)
    }
    else {
        $card.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#142132')
        $card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#276276')
        $card.BorderThickness = [System.Windows.Thickness]::new(1)
    }

    $layout = [System.Windows.Controls.Grid]::new()
    $layout.RowDefinitions.Add([System.Windows.Controls.RowDefinition]::new())
    $layout.RowDefinitions.Add([System.Windows.Controls.RowDefinition]::new())
    $layout.RowDefinitions.Add([System.Windows.Controls.RowDefinition]::new())
    $layout.RowDefinitions.Add([System.Windows.Controls.RowDefinition]::new())
    $layout.RowDefinitions.Add([System.Windows.Controls.RowDefinition]::new())
    $layout.RowDefinitions[0].Height = [System.Windows.GridLength]::Auto
    $layout.RowDefinitions[1].Height = [System.Windows.GridLength]::Auto
    $layout.RowDefinitions[2].Height = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $layout.RowDefinitions[3].Height = [System.Windows.GridLength]::Auto
    $layout.RowDefinitions[4].Height = [System.Windows.GridLength]::Auto

    $title = [System.Windows.Controls.TextBlock]::new()
    $title.Text = $toolTitle
    $title.Height = 40
    $title.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#F4F7FC')
    $title.FontSize = 15
    $title.FontWeight = [System.Windows.FontWeights]::SemiBold
    $title.LineHeight = 20
    $title.TextTrimming = [System.Windows.TextTrimming]::CharacterEllipsis
    $title.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $title.ToolTip = $toolTitle
    [System.Windows.Controls.Grid]::SetRow($title, 0)
    $layout.Children.Add($title) | Out-Null

    $badges = [System.Windows.Controls.WrapPanel]::new()
    $badges.Margin = [System.Windows.Thickness]::new(0, 8, 0, 0)

    if ($toolType -eq 'assistant') {
        $badges.Children.Add(
            (New-BoostLabBadge -Text 'Assistant' -Background '#2E294E' -Foreground '#DDD6FE' -Border '#5D5590')
        ) | Out-Null
    }
    else {
        $badges.Children.Add(
            (New-BoostLabBadge -Text 'Action' -Background '#123746' -Foreground '#CFFAFE' -Border '#28677A')
        ) | Out-Null
    }

    $riskBadgeColors = switch ($riskLevel) {
        'high' {
            @{
                Background = '#49272F'
                Foreground = '#FEE2E2'
                Border     = '#8F505D'
            }
        }
        'medium' {
            @{
                Background = '#49361F'
                Foreground = '#FEF3C7'
                Border     = '#80612E'
            }
        }
        default {
            @{
                Background = '#183B2A'
                Foreground = '#DCFCE7'
                Border     = '#34704E'
            }
        }
    }
    $badges.Children.Add(
        (
            New-BoostLabBadge `
                -Text "$riskLevel risk" `
                -Background $riskBadgeColors['Background'] `
                -Foreground $riskBadgeColors['Foreground'] `
                -Border $riskBadgeColors['Border']
        )
    ) | Out-Null
    [System.Windows.Controls.Grid]::SetRow($badges, 1)
    $layout.Children.Add($badges) | Out-Null

    $description = [System.Windows.Controls.TextBlock]::new()
    $description.Margin = [System.Windows.Thickness]::new(0, 12, 0, 8)
    $description.Text = [string]$Tool['Description']
    $description.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#9EABC2')
    $description.FontSize = 12
    $description.LineHeight = 18
    $description.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $description.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
    [System.Windows.Controls.Grid]::SetRow($description, 2)
    $layout.Children.Add($description) | Out-Null

    $statusContainer = [System.Windows.Controls.Border]::new()
    $statusContainer.Padding = [System.Windows.Thickness]::new(9, 6, 9, 6)
    $statusContainer.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#101827')
    $statusContainer.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#29364B')
    $statusContainer.BorderThickness = [System.Windows.Thickness]::new(1)
    $statusContainer.CornerRadius = [System.Windows.CornerRadius]::new(6)

    $status = [System.Windows.Controls.TextBlock]::new()
    $status.Text = 'Status: Not implemented'
    $status.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#FDE68A')
    $status.FontSize = 11
    $status.FontWeight = [System.Windows.FontWeights]::SemiBold
    $statusContainer.Child = $status
    [System.Windows.Controls.Grid]::SetRow($statusContainer, 3)
    $layout.Children.Add($statusContainer) | Out-Null

    $actionsPanel = [System.Windows.Controls.WrapPanel]::new()
    $actionsPanel.Margin = [System.Windows.Thickness]::new(0, 12, 0, 0)
    $actionsPanel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left

    foreach ($actionName in @($Tool['Actions'])) {
        $actionButton = [System.Windows.Controls.Button]::new()
        $actionButton.Content = [string]$actionName
        $actionButton.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
        $actionButton.Margin = [System.Windows.Thickness]::new(0, 0, 7, 0)
        $actionButton.Tag = [pscustomobject]@{
            Stage      = $stageName
            ToolId     = $toolId
            ToolTitle  = $toolTitle
            ActionName = [string]$actionName
        }
        $actionButton.Style = $script:BoostLabWindow.FindResource('ActionButtonStyle')
        $actionButton.Add_Click({
            $context = $this.Tag
            $message = '[{0}] [{1}] not implemented yet' -f $context.ToolTitle, $context.ActionName

            Set-BoostLabStateValue -Name 'CurrentStatus' -Value 'Not implemented'
            (Get-BoostLabUiElement -Name 'ApplicationStatusText').Text = "$($context.ToolTitle): Not implemented"
            Write-BoostLabLog -Message $message -Source "$($context.Stage) / $($context.ToolId)" | Out-Null
        })

        $actionsPanel.Children.Add($actionButton) | Out-Null
    }
    [System.Windows.Controls.Grid]::SetRow($actionsPanel, 4)
    $layout.Children.Add($actionsPanel) | Out-Null

    $card.Child = $layout
    return $card
}

function Show-BoostLabStage {
    param(
        [Parameter(Mandatory)]
        [string]$StageName
    )

    $stage = $script:BoostLabStages | Where-Object { $_['Name'] -eq $StageName } | Select-Object -First 1
    if (-not $stage) {
        return
    }

    Set-BoostLabStateValue -Name 'CurrentStage' -Value $StageName

    $tools = @($stage['Tools'] | Sort-Object { [int]$_['Order'] })
    $toolCountText = if ($tools.Count -eq 1) {
        '1 TOOL'
    }
    else {
        "$($tools.Count) TOOLS"
    }

    (Get-BoostLabUiElement -Name 'StageEyebrowText').Text = 'WORKFLOW STAGE {0:D2} / {1:D2}' -f [int]$stage['Order'], $script:BoostLabStages.Count
    (Get-BoostLabUiElement -Name 'StageTitleText').Text = [string]$stage['Name']
    (Get-BoostLabUiElement -Name 'StageDescriptionText').Text = [string]$stage['Description']
    (Get-BoostLabUiElement -Name 'StageToolCountText').Text = $toolCountText

    foreach ($buttonName in $script:BoostLabStageButtons.Keys) {
        $button = $script:BoostLabStageButtons[$buttonName]
        if ($buttonName -eq $StageName) {
            $button.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#173A5E')
            $button.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#38BDF8')
            $button.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#F8FAFC')
            $button.FontWeight = [System.Windows.FontWeights]::SemiBold
        }
        else {
            $button.Background = [System.Windows.Media.Brushes]::Transparent
            $button.BorderBrush = [System.Windows.Media.Brushes]::Transparent
            $button.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#B8C5D9')
            $button.FontWeight = [System.Windows.FontWeights]::Normal
        }
    }

    $cardsPanel = Get-BoostLabUiElement -Name 'ToolCardsPanel'
    $cardsPanel.Children.Clear()

    foreach ($tool in $tools) {
        $cardsPanel.Children.Add((New-BoostLabToolCard -Tool $tool)) | Out-Null
    }
}

function Initialize-BoostLabMainWindow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Windows.Window]$Window,

        [Parameter(Mandatory)]
        [hashtable]$StageConfiguration,

        [Parameter(Mandatory)]
        [bool]$IsAdministrator,

        [Parameter(Mandatory)]
        [bool]$HasInternet,

        [Parameter(Mandatory)]
        [pscustomobject]$LicenseStatus,

        [Parameter(Mandatory)]
        [pscustomobject]$WindowsVersion
    )

    $script:BoostLabWindow = $Window
    $script:BoostLabStages = @($StageConfiguration['Stages'] | Sort-Object { [int]$_['Order'] })
    $script:BoostLabStageButtons = @{}

    Initialize-BoostLabState

    $adminStatusText = Get-BoostLabUiElement -Name 'AdminStatusText'
    $adminStatusText.Text = if ($IsAdministrator) {
        'Admin: Yes'
    }
    else {
        'Admin: No'
    }
    $adminStatusText.Foreground = if ($IsAdministrator) {
        [System.Windows.Media.BrushConverter]::new().ConvertFromString('#86EFAC')
    }
    else {
        [System.Windows.Media.BrushConverter]::new().ConvertFromString('#FDE68A')
    }

    $internetStatusText = Get-BoostLabUiElement -Name 'InternetStatusText'
    $internetStatusText.Text = if ($HasInternet) {
        'Internet: Online'
    }
    else {
        'Internet: Offline'
    }
    $internetStatusText.Foreground = if ($HasInternet) {
        [System.Windows.Media.BrushConverter]::new().ConvertFromString('#86EFAC')
    }
    else {
        [System.Windows.Media.BrushConverter]::new().ConvertFromString('#FCA5A5')
    }

    (Get-BoostLabUiElement -Name 'LicenseStatusText').Text = "License: $($LicenseStatus.Status)"
    (Get-BoostLabUiElement -Name 'WindowsStatusText').Text = $WindowsVersion.DisplayName

    $logTextBox = Get-BoostLabUiElement -Name 'LogTextBox'
    $logSink = {
        param($Entry)

        $line = '[{0:HH:mm:ss}] [{1}] {2}' -f $Entry.Timestamp, $Entry.Level, $Entry.Message
        $logTextBox.AppendText("$line`r`n")
        $logTextBox.CaretIndex = $logTextBox.Text.Length
        $logTextBox.ScrollToEnd()
    }.GetNewClosure()
    Register-BoostLabLogSink -Sink $logSink

    $navigationPanel = Get-BoostLabUiElement -Name 'StageNavigationPanel'
    foreach ($stage in $script:BoostLabStages) {
        $button = [System.Windows.Controls.Button]::new()
        $button.Content = [string]$stage['Name']
        $button.Tag = [string]$stage['Name']
        $button.ToolTip = [string]$stage['Description']
        $button.Style = $Window.FindResource('SidebarButtonStyle')
        $button.Add_Click({
            Show-BoostLabStage -StageName ([string]$this.Tag)
        })

        $script:BoostLabStageButtons[[string]$stage['Name']] = $button
        $navigationPanel.Children.Add($button) | Out-Null
    }

    Show-BoostLabStage -StageName 'Check'
    Write-BoostLabLog -Message 'BoostLab interface initialized.' | Out-Null
}
