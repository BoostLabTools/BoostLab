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
        [string]$Foreground
    )

    $badge = [System.Windows.Controls.Border]::new()
    $badge.Margin = [System.Windows.Thickness]::new(0, 0, 7, 0)
    $badge.Padding = [System.Windows.Thickness]::new(8, 3, 8, 3)
    $badge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Background)
    $badge.CornerRadius = [System.Windows.CornerRadius]::new(10)

    $label = [System.Windows.Controls.TextBlock]::new()
    $label.Text = $Text.ToUpperInvariant()
    $label.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Foreground)
    $label.FontSize = 10
    $label.FontWeight = [System.Windows.FontWeights]::SemiBold

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
    $card.Width = 310
    $card.MinHeight = 238
    $card.Margin = [System.Windows.Thickness]::new(0, 0, 14, 14)
    $card.Padding = [System.Windows.Thickness]::new(16)
    $card.CornerRadius = [System.Windows.CornerRadius]::new(9)

    if ($riskLevel -eq 'high') {
        $card.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#281923')
        $card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#DC2626')
        $card.BorderThickness = [System.Windows.Thickness]::new(2)
    }
    elseif ($toolType -eq 'assistant') {
        $card.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#1D203A')
        $card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#7C3AED')
        $card.BorderThickness = [System.Windows.Thickness]::new(1)
    }
    else {
        $card.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#182238')
        $card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#0E7490')
        $card.BorderThickness = [System.Windows.Thickness]::new(1)
    }

    $layout = [System.Windows.Controls.StackPanel]::new()

    $title = [System.Windows.Controls.TextBlock]::new()
    $title.Text = $toolTitle
    $title.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#F4F7FC')
    $title.FontSize = 16
    $title.FontWeight = [System.Windows.FontWeights]::SemiBold
    $title.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $layout.Children.Add($title) | Out-Null

    $badges = [System.Windows.Controls.WrapPanel]::new()
    $badges.Margin = [System.Windows.Thickness]::new(0, 10, 0, 0)

    if ($toolType -eq 'assistant') {
        $badges.Children.Add((New-BoostLabBadge -Text 'Assistant' -Background '#3B1D67' -Foreground '#DDD6FE')) | Out-Null
    }
    else {
        $badges.Children.Add((New-BoostLabBadge -Text 'Action' -Background '#164E63' -Foreground '#CFFAFE')) | Out-Null
    }

    $riskBadgeColors = switch ($riskLevel) {
        'high' {
            @{
                Background = '#7F1D1D'
                Foreground = '#FEE2E2'
            }
        }
        'medium' {
            @{
                Background = '#78350F'
                Foreground = '#FEF3C7'
            }
        }
        default {
            @{
                Background = '#14532D'
                Foreground = '#DCFCE7'
            }
        }
    }
    $badges.Children.Add(
        (New-BoostLabBadge -Text "$riskLevel risk" -Background $riskBadgeColors['Background'] -Foreground $riskBadgeColors['Foreground'])
    ) | Out-Null
    $layout.Children.Add($badges) | Out-Null

    $description = [System.Windows.Controls.TextBlock]::new()
    $description.Margin = [System.Windows.Thickness]::new(0, 12, 0, 0)
    $description.Text = [string]$Tool['Description']
    $description.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#9EABC2')
    $description.FontSize = 12
    $description.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $layout.Children.Add($description) | Out-Null

    $status = [System.Windows.Controls.TextBlock]::new()
    $status.Margin = [System.Windows.Thickness]::new(0, 10, 0, 0)
    $status.Text = 'Status: Not implemented'
    $status.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#FBBF24')
    $status.FontSize = 12
    $layout.Children.Add($status) | Out-Null

    $actionsPanel = [System.Windows.Controls.WrapPanel]::new()
    $actionsPanel.Margin = [System.Windows.Thickness]::new(0, 14, 0, 0)

    foreach ($actionName in @($Tool['Actions'])) {
        $actionButton = [System.Windows.Controls.Button]::new()
        $actionButton.Content = [string]$actionName
        $actionButton.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
        $actionButton.Margin = [System.Windows.Thickness]::new(0, 0, 8, 8)
        $actionButton.MinWidth = 72
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

    (Get-BoostLabUiElement -Name 'StageTitleText').Text = [string]$stage['Name']
    (Get-BoostLabUiElement -Name 'StageDescriptionText').Text = [string]$stage['Description']

    foreach ($buttonName in $script:BoostLabStageButtons.Keys) {
        $button = $script:BoostLabStageButtons[$buttonName]
        $button.Background = if ($buttonName -eq $StageName) {
            [System.Windows.Media.BrushConverter]::new().ConvertFromString('#075985')
        }
        else {
            [System.Windows.Media.Brushes]::Transparent
        }
    }

    $cardsPanel = Get-BoostLabUiElement -Name 'ToolCardsPanel'
    $cardsPanel.Children.Clear()

    foreach ($tool in @($stage['Tools'] | Sort-Object { [int]$_['Order'] })) {
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

    (Get-BoostLabUiElement -Name 'AdminStatusText').Text = if ($IsAdministrator) {
        'Admin: Yes'
    }
    else {
        'Admin: No'
    }

    (Get-BoostLabUiElement -Name 'InternetStatusText').Text = if ($HasInternet) {
        'Internet: Online'
    }
    else {
        'Internet: Offline'
    }

    (Get-BoostLabUiElement -Name 'LicenseStatusText').Text = "License: $($LicenseStatus.Status)"
    (Get-BoostLabUiElement -Name 'WindowsStatusText').Text = $WindowsVersion.DisplayName

    $logTextBox = Get-BoostLabUiElement -Name 'LogTextBox'
    $logSink = {
        param($Entry)

        $line = '[{0:HH:mm:ss}] [{1}] {2}' -f $Entry.Timestamp, $Entry.Level, $Entry.Message
        $logTextBox.AppendText("$line`r`n")
        $logTextBox.ScrollToEnd()
    }.GetNewClosure()
    Register-BoostLabLogSink -Sink $logSink

    $navigationPanel = Get-BoostLabUiElement -Name 'StageNavigationPanel'
    foreach ($stage in $script:BoostLabStages) {
        $button = [System.Windows.Controls.Button]::new()
        $button.Content = [string]$stage['Name']
        $button.Tag = [string]$stage['Name']
        $button.Style = $Window.FindResource('SidebarButtonStyle')
        $button.Add_Click({
            Show-BoostLabStage -StageName ([string]$this.Tag)
        })

        $script:BoostLabStageButtons[[string]$stage['Name']] = $button
        $navigationPanel.Children.Add($button) | Out-Null
    }

    Show-BoostLabStage -StageName 'Check'
    Write-BoostLabLog -Message 'BoostLab Phase 1 shell initialized.' | Out-Null
}
