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

function New-BoostLabToolCard {
    param(
        [Parameter(Mandatory)]
        [string]$StageName,

        [Parameter(Mandatory)]
        [string]$ToolName
    )

    $card = [System.Windows.Controls.Border]::new()
    $card.Width = 310
    $card.MinHeight = 176
    $card.Margin = [System.Windows.Thickness]::new(0, 0, 14, 14)
    $card.Padding = [System.Windows.Thickness]::new(16)
    $card.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#182238')
    $card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#293653')
    $card.BorderThickness = [System.Windows.Thickness]::new(1)
    $card.CornerRadius = [System.Windows.CornerRadius]::new(9)

    $layout = [System.Windows.Controls.Grid]::new()
    $layout.RowDefinitions.Add([System.Windows.Controls.RowDefinition]::new())
    $layout.RowDefinitions.Add([System.Windows.Controls.RowDefinition]::new())
    $layout.RowDefinitions.Add([System.Windows.Controls.RowDefinition]::new())
    $layout.RowDefinitions[0].Height = [System.Windows.GridLength]::Auto
    $layout.RowDefinitions[1].Height = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $layout.RowDefinitions[2].Height = [System.Windows.GridLength]::Auto

    $title = [System.Windows.Controls.TextBlock]::new()
    $title.Text = $ToolName
    $title.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#F4F7FC')
    $title.FontSize = 16
    $title.FontWeight = [System.Windows.FontWeights]::SemiBold
    $title.TextWrapping = [System.Windows.TextWrapping]::Wrap
    [System.Windows.Controls.Grid]::SetRow($title, 0)
    $layout.Children.Add($title) | Out-Null

    $details = [System.Windows.Controls.StackPanel]::new()
    $details.Margin = [System.Windows.Thickness]::new(0, 10, 0, 12)

    $description = [System.Windows.Controls.TextBlock]::new()
    $description.Text = 'Phase 1 interface placeholder. No system action is connected.'
    $description.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#9EABC2')
    $description.FontSize = 12
    $description.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $details.Children.Add($description) | Out-Null

    $status = [System.Windows.Controls.TextBlock]::new()
    $status.Margin = [System.Windows.Thickness]::new(0, 10, 0, 0)
    $status.Text = 'Status: Not implemented'
    $status.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#FBBF24')
    $status.FontSize = 12
    $details.Children.Add($status) | Out-Null

    [System.Windows.Controls.Grid]::SetRow($details, 1)
    $layout.Children.Add($details) | Out-Null

    $actionButton = [System.Windows.Controls.Button]::new()
    $actionButton.Content = 'Action'
    $actionButton.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    $actionButton.Tag = [pscustomobject]@{
        Stage = $StageName
        Tool  = $ToolName
    }
    $actionButton.Style = $script:BoostLabWindow.FindResource('ActionButtonStyle')
    $actionButton.Add_Click({
        $context = $this.Tag
        Set-BoostLabStateValue -Name 'CurrentStatus' -Value 'Not implemented'
        (Get-BoostLabUiElement -Name 'ApplicationStatusText').Text = 'Not implemented'
        Write-BoostLabLog -Message 'Action not implemented yet' -Source "$($context.Stage) / $($context.Tool)" | Out-Null
    })

    [System.Windows.Controls.Grid]::SetRow($actionButton, 2)
    $layout.Children.Add($actionButton) | Out-Null

    $card.Child = $layout
    return $card
}

function Show-BoostLabStage {
    param(
        [Parameter(Mandatory)]
        [string]$StageName
    )

    $stage = $script:BoostLabStages | Where-Object { $_.Name -eq $StageName } | Select-Object -First 1
    if (-not $stage) {
        return
    }

    Set-BoostLabStateValue -Name 'CurrentStage' -Value $StageName

    (Get-BoostLabUiElement -Name 'StageTitleText').Text = $stage.Name
    (Get-BoostLabUiElement -Name 'StageDescriptionText').Text = $stage.Description

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

    foreach ($toolName in $stage.Tools) {
        $cardsPanel.Children.Add((New-BoostLabToolCard -StageName $stage.Name -ToolName $toolName)) | Out-Null
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
    $script:BoostLabStages = @($StageConfiguration.Stages | Sort-Object { [int]$_['Order'] })
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
        $button.Content = $stage.Name
        $button.Tag = $stage.Name
        $button.Style = $Window.FindResource('SidebarButtonStyle')
        $button.Add_Click({
            Show-BoostLabStage -StageName ([string]$this.Tag)
        })

        $script:BoostLabStageButtons[$stage.Name] = $button
        $navigationPanel.Children.Add($button) | Out-Null
    }

    Show-BoostLabStage -StageName 'Check'
    Write-BoostLabLog -Message 'BoostLab Phase 1 shell initialized.' | Out-Null
}
