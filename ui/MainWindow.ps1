Set-StrictMode -Version Latest

$script:BoostLabWindow = $null
$script:BoostLabStages = @()
$script:BoostLabStageButtons = @{}
$script:BoostLabVisibleLogText = [System.Collections.Generic.List[string]]::new()

function Get-BoostLabUiElement {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    return $script:BoostLabWindow.FindName($Name)
}

function Get-BoostLabObjectPropertyValue {
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$PropertyName,

        [AllowNull()]
        [object]$DefaultValue = 'Unknown'
    )

    if ($null -eq $InputObject) {
        return $DefaultValue
    }

    $property = $InputObject.PSObject.Properties[$PropertyName]
    if ($null -eq $property -or $null -eq $property.Value) {
        return $DefaultValue
    }

    if ($property.Value -is [string] -and [string]::IsNullOrWhiteSpace($property.Value)) {
        return $DefaultValue
    }

    return $property.Value
}

function Add-BoostLabResultSectionTitle {
    param(
        [Parameter(Mandatory)]
        [System.Windows.Controls.Panel]$Panel,

        [Parameter(Mandatory)]
        [string]$Text
    )

    $title = [System.Windows.Controls.TextBlock]::new()
    $title.Margin = [System.Windows.Thickness]::new(0, 10, 0, 6)
    $title.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#7DD3FC')
    $title.FontSize = 10
    $title.FontWeight = [System.Windows.FontWeights]::SemiBold
    $title.Text = $Text.ToUpperInvariant()
    $Panel.Children.Add($title) | Out-Null
}

function Add-BoostLabResultRow {
    param(
        [Parameter(Mandatory)]
        [System.Windows.Controls.Panel]$Panel,

        [Parameter(Mandatory)]
        [string]$Label,

        [AllowNull()]
        [object]$Value
    )

    $row = [System.Windows.Controls.Grid]::new()
    $row.Margin = [System.Windows.Thickness]::new(0, 0, 0, 7)
    $row.ColumnDefinitions.Add([System.Windows.Controls.ColumnDefinition]::new())
    $row.ColumnDefinitions.Add([System.Windows.Controls.ColumnDefinition]::new())
    $row.ColumnDefinitions[0].Width = [System.Windows.GridLength]::new(116)
    $row.ColumnDefinitions[1].Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)

    $labelText = [System.Windows.Controls.TextBlock]::new()
    $labelText.Margin = [System.Windows.Thickness]::new(0, 0, 9, 0)
    $labelText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#7F8DA5')
    $labelText.FontSize = 10
    $labelText.FontWeight = [System.Windows.FontWeights]::SemiBold
    $labelText.Text = "$Label`:"
    $labelText.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $row.Children.Add($labelText) | Out-Null

    $valueText = [System.Windows.Controls.TextBlock]::new()
    $valueText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#E2E8F0')
    $valueText.FontSize = 11
    $valueText.LineHeight = 16
    $valueText.Text = if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
        'Unknown'
    }
    else {
        [string]$Value
    }
    $valueText.TextWrapping = [System.Windows.TextWrapping]::Wrap
    [System.Windows.Controls.Grid]::SetColumn($valueText, 1)
    $row.Children.Add($valueText) | Out-Null

    $Panel.Children.Add($row) | Out-Null
}

function Add-BoostLabResultBullet {
    param(
        [Parameter(Mandatory)]
        [System.Windows.Controls.Panel]$Panel,

        [Parameter(Mandatory)]
        [string]$Text,

        [string]$Color = '#D6DFED'
    )

    $line = [System.Windows.Controls.TextBlock]::new()
    $line.Margin = [System.Windows.Thickness]::new(2, 0, 0, 6)
    $line.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Color)
    $line.FontSize = 11
    $line.LineHeight = 17
    $line.Text = '{0} {1}' -f [char]0x2022, $Text
    $line.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $Panel.Children.Add($line) | Out-Null
}

function Get-BoostLabResultStatus {
    param(
        [Parameter(Mandatory)]
        [object]$Result
    )

    $cancelled = [bool](Get-BoostLabObjectPropertyValue -InputObject $Result -PropertyName 'Cancelled' -DefaultValue $false)
    if ($cancelled) {
        return 'Cancelled'
    }
    if ([bool]$Result.Success) {
        return 'Success'
    }
    if ([string]$Result.Message -eq 'Action not implemented yet') {
        return 'Not implemented'
    }

    return 'Error'
}

function Show-BoostLabActionResult {
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$ToolMetadata,

        [Parameter(Mandatory)]
        [string]$ActionName,

        [Parameter(Mandatory)]
        [object]$Result
    )

    $toolId = [string]$ToolMetadata['Id']
    $toolTitle = [string]$ToolMetadata['Title']
    $status = Get-BoostLabResultStatus -Result $Result
    $panel = Get-BoostLabUiElement -Name 'LatestResultPanel'
    $panel.Children.Clear()

    (Get-BoostLabUiElement -Name 'SelectedToolNameText').Text = $toolTitle
    (Get-BoostLabUiElement -Name 'SelectedToolActionText').Text = $ActionName.ToUpperInvariant()

    $statusText = Get-BoostLabUiElement -Name 'LatestResultStatusText'
    $statusText.Text = $status.ToUpperInvariant()
    $statusText.Foreground = switch ($status) {
        'Success' { [System.Windows.Media.BrushConverter]::new().ConvertFromString('#86EFAC') }
        'Cancelled' { [System.Windows.Media.BrushConverter]::new().ConvertFromString('#FDE68A') }
        'Not implemented' { [System.Windows.Media.BrushConverter]::new().ConvertFromString('#93C5FD') }
        default { [System.Windows.Media.BrushConverter]::new().ConvertFromString('#FCA5A5') }
    }

    Add-BoostLabResultRow -Panel $panel -Label 'Tool' -Value $toolTitle
    Add-BoostLabResultRow -Panel $panel -Label 'Action' -Value $ActionName
    Add-BoostLabResultRow -Panel $panel -Label 'Status' -Value $status
    Add-BoostLabResultRow -Panel $panel -Label 'Message' -Value ([string]$Result.Message)

    $actionPlan = Get-BoostLabObjectPropertyValue -InputObject $Result -PropertyName 'ActionPlan' -DefaultValue $null
    if ($null -ne $actionPlan) {
        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Action Plan'
        Add-BoostLabResultRow -Panel $panel -Label 'Risk' -Value ([string]$actionPlan.RiskLevel).ToUpperInvariant()
        Add-BoostLabResultRow -Panel $panel -Label 'Summary' -Value ([string]$actionPlan.Summary)
        Add-BoostLabResultRow `
            -Panel $panel `
            -Label 'Confirmation' `
            -Value $(if ([bool]$actionPlan.NeedsExplicitConfirmation) { 'Required' } else { 'Not required' })
        Add-BoostLabResultRow `
            -Panel $panel `
            -Label 'Plan mode' `
            -Value $(if ([bool]$actionPlan.IsDryRun) { 'Dry run' } else { 'Execution request' })

        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Planned Changes'
        foreach ($plannedChange in @($actionPlan.PlannedChanges)) {
            Add-BoostLabResultBullet -Panel $panel -Text ([string]$plannedChange)
        }

        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Side Effects'
        foreach ($sideEffect in @($actionPlan.SideEffects)) {
            Add-BoostLabResultBullet -Panel $panel -Text ([string]$sideEffect) -Color '#FDE68A'
        }

        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Confirmation Message'
        Add-BoostLabResultBullet -Panel $panel -Text ([string]$actionPlan.ConfirmationMessage)
    }

    $data = Get-BoostLabObjectPropertyValue -InputObject $Result -PropertyName 'Data' -DefaultValue $null
    if ($toolId -eq 'bios-information' -and $ActionName -eq 'Analyze' -and $null -ne $data) {
        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Detected System'
        Add-BoostLabResultRow -Panel $panel -Label 'Motherboard Manufacturer' -Value (Get-BoostLabObjectPropertyValue $data 'MotherboardManufacturer')
        Add-BoostLabResultRow -Panel $panel -Label 'Motherboard Model' -Value (Get-BoostLabObjectPropertyValue $data 'MotherboardModel')
        Add-BoostLabResultRow -Panel $panel -Label 'BIOS Vendor' -Value (Get-BoostLabObjectPropertyValue $data 'BiosManufacturer')
        Add-BoostLabResultRow -Panel $panel -Label 'BIOS Version' -Value (Get-BoostLabObjectPropertyValue $data 'BiosVersion')
        Add-BoostLabResultRow -Panel $panel -Label 'BIOS Date' -Value (Get-BoostLabObjectPropertyValue $data 'BiosReleaseDate')
        Add-BoostLabResultRow -Panel $panel -Label 'TPM' -Value (Get-BoostLabObjectPropertyValue $data 'TpmStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Secure Boot' -Value (Get-BoostLabObjectPropertyValue $data 'SecureBootStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'CPU' -Value (Get-BoostLabObjectPropertyValue $data 'CpuName')
        $windowsValue = '{0} (Build {1})' -f `
            (Get-BoostLabObjectPropertyValue $data 'WindowsVersion'), `
            (Get-BoostLabObjectPropertyValue $data 'WindowsBuild')
        Add-BoostLabResultRow -Panel $panel -Label 'Windows' -Value $windowsValue
    }
    elseif ($toolId -eq 'bios-settings' -and $ActionName -eq 'Analyze' -and $null -ne $data) {
        foreach ($section in @($data.Guidance)) {
            Add-BoostLabResultSectionTitle -Panel $panel -Text ([string]$section.Title)
            foreach ($instruction in @($section.Instructions)) {
                Add-BoostLabResultBullet -Panel $panel -Text ([string]$instruction)
            }
        }

        if (@($data.Warnings).Count -gt 0) {
            Add-BoostLabResultSectionTitle -Panel $panel -Text 'Warnings'
            foreach ($warning in @($data.Warnings)) {
                Add-BoostLabResultBullet -Panel $panel -Text ([string]$warning) -Color '#FDE68A'
            }
        }
    }
    elseif ($null -ne $data) {
        $displayProperties = @(
            $data.PSObject.Properties |
                Where-Object {
                    $_.Name -notin @('Timestamp') -and
                    ($null -eq $_.Value -or $_.Value -is [string] -or $_.Value -is [ValueType])
                }
        )
        if ($displayProperties.Count -gt 0) {
            Add-BoostLabResultSectionTitle -Panel $panel -Text 'Details'
            foreach ($property in $displayProperties) {
                Add-BoostLabResultRow -Panel $panel -Label $property.Name -Value $property.Value
            }
        }
    }

    (Get-BoostLabUiElement -Name 'LatestResultScrollViewer').ScrollToTop()
}

function Add-BoostLabActivityEntry {
    param(
        [Parameter(Mandatory)]
        [object]$Entry
    )

    $displayLevel = if ([string]$Entry.Level -eq 'Debug') {
        'DETAIL'
    }
    else {
        ([string]$Entry.Level).ToUpperInvariant()
    }
    $toolName = [string]$Entry.Source
    $actionName = [string]$Entry.EventId
    $message = [string]$Entry.Message
    $match = [regex]::Match(
        $message,
        '^\[(?<Tool>[^\]]+)\]\s+\[(?<Action>[^\]]+)\]\s*(?<Message>.*)$',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    if ($match.Success) {
        $toolName = $match.Groups['Tool'].Value
        $actionName = $match.Groups['Action'].Value
        $message = $match.Groups['Message'].Value
    }

    $arrow = [char]0x2192
    $header = '[{0:HH:mm:ss}] [{1}]' -f `
        $Entry.Timestamp, `
        $displayLevel
    $actionLine = '{0} {1} {2}' -f $toolName, $arrow, $actionName
    $visibleText = "$header`r`n$actionLine`r`n$message"
    $script:BoostLabVisibleLogText.Add($visibleText)

    $levelColor = switch ($displayLevel) {
        'SUCCESS' { '#86EFAC' }
        'WARNING' { '#FDE68A' }
        'ERROR' { '#FCA5A5' }
        'DETAIL' { '#C4B5FD' }
        default { '#7DD3FC' }
    }

    $paragraph = [System.Windows.Documents.Paragraph]::new()
    $paragraph.Margin = [System.Windows.Thickness]::new(0, 0, 0, 10)
    $paragraph.LineHeight = 17

    $headerRun = [System.Windows.Documents.Run]::new($header)
    $headerRun.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($levelColor)
    $headerRun.FontWeight = [System.Windows.FontWeights]::SemiBold
    $paragraph.Inlines.Add($headerRun)
    $paragraph.Inlines.Add([System.Windows.Documents.LineBreak]::new())

    $actionRun = [System.Windows.Documents.Run]::new($actionLine)
    $actionRun.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#E2E8F0')
    $actionRun.FontWeight = [System.Windows.FontWeights]::SemiBold
    $paragraph.Inlines.Add($actionRun)
    $paragraph.Inlines.Add([System.Windows.Documents.LineBreak]::new())

    $messageRun = [System.Windows.Documents.Run]::new($message)
    $messageRun.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#AAB7CA')
    $paragraph.Inlines.Add($messageRun)

    $activityLog = Get-BoostLabUiElement -Name 'ActivityLogRichTextBox'
    $activityLog.Document.Blocks.Add($paragraph)
    $activityLog.ScrollToEnd()
}

function Add-BoostLabToolActionActivityEntry {
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$ToolMetadata,

        [Parameter(Mandatory)]
        [string]$ActionName,

        [Parameter(Mandatory)]
        [object]$Result
    )

    $status = Get-BoostLabResultStatus -Result $Result
    $level = switch ($status) {
        'Success' { 'Success' }
        'Not implemented' { 'Info' }
        'Cancelled' { 'Info' }
        default { 'Error' }
    }
    $message = if (
        [string]$ToolMetadata['Id'] -eq 'bios-information' -and
        $ActionName -eq 'Analyze' -and
        [bool]$Result.Success
    ) {
        'Hardware and BIOS information detected.'
    }
    else {
        [string]$Result.Message
    }

    Add-BoostLabActivityEntry -Entry ([pscustomobject]@{
        Timestamp = Get-Date
        Level     = $level
        Source    = [string]$ToolMetadata['Title']
        EventId   = $ActionName
        Message   = $message
    })
}

function Add-BoostLabStartupActivityEntry {
    Add-BoostLabActivityEntry -Entry ([pscustomobject]@{
        Timestamp = Get-Date
        Level     = 'Info'
        Source    = 'BoostLab'
        EventId   = 'Startup'
        Message   = 'Interface initialized.'
    })
}

function Clear-BoostLabVisibleActivityLog {
    $activityLog = Get-BoostLabUiElement -Name 'ActivityLogRichTextBox'
    $activityLog.Document.Blocks.Clear()
    $script:BoostLabVisibleLogText.Clear()
    (Get-BoostLabUiElement -Name 'ApplicationStatusText').Text = 'Visible log cleared'
}

function Copy-BoostLabVisibleActivityLog {
    $visibleText = $script:BoostLabVisibleLogText -join "`r`n`r`n"
    if ([string]::IsNullOrWhiteSpace($visibleText)) {
        (Get-BoostLabUiElement -Name 'ApplicationStatusText').Text = 'Log is empty'
        return
    }

    try {
        [System.Windows.Clipboard]::SetText($visibleText)
        (Get-BoostLabUiElement -Name 'ApplicationStatusText').Text = 'Visible log copied'
    }
    catch {
        (Get-BoostLabUiElement -Name 'ApplicationStatusText').Text = 'Clipboard unavailable'
    }
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

function Show-BoostLabActionPlanConfirmation {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [object]$ActionPlan
    )

    $dialog = [System.Windows.Window]::new()
    $dialog.Title = 'Confirm BoostLab Action'
    $dialog.Width = 620
    $dialog.Height = 640
    $dialog.MinWidth = 520
    $dialog.MinHeight = 500
    $dialog.ResizeMode = [System.Windows.ResizeMode]::CanResize
    $dialog.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterOwner
    $dialog.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#0B1220')
    $dialog.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#E2E8F0')
    if ($null -ne $script:BoostLabWindow -and $script:BoostLabWindow.IsVisible) {
        $dialog.Owner = $script:BoostLabWindow
    }

    $root = [System.Windows.Controls.Grid]::new()
    $root.Margin = [System.Windows.Thickness]::new(22)
    $root.RowDefinitions.Add([System.Windows.Controls.RowDefinition]::new())
    $root.RowDefinitions.Add([System.Windows.Controls.RowDefinition]::new())
    $root.RowDefinitions[0].Height = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $root.RowDefinitions[1].Height = [System.Windows.GridLength]::Auto

    $scrollViewer = [System.Windows.Controls.ScrollViewer]::new()
    $scrollViewer.VerticalScrollBarVisibility = [System.Windows.Controls.ScrollBarVisibility]::Auto
    $scrollViewer.HorizontalScrollBarVisibility = [System.Windows.Controls.ScrollBarVisibility]::Disabled

    $content = [System.Windows.Controls.StackPanel]::new()
    $heading = [System.Windows.Controls.TextBlock]::new()
    $heading.Text = 'Review Action Plan'
    $heading.FontSize = 22
    $heading.FontWeight = [System.Windows.FontWeights]::SemiBold
    $heading.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#F8FAFC')
    $content.Children.Add($heading) | Out-Null

    $subheading = [System.Windows.Controls.TextBlock]::new()
    $subheading.Margin = [System.Windows.Thickness]::new(0, 5, 0, 16)
    $subheading.Text = 'Review the operation before BoostLab continues.'
    $subheading.FontSize = 12
    $subheading.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#94A3B8')
    $content.Children.Add($subheading) | Out-Null

    Add-BoostLabResultRow -Panel $content -Label 'Tool' -Value ([string]$ActionPlan.ToolTitle)
    Add-BoostLabResultRow -Panel $content -Label 'Action' -Value ([string]$ActionPlan.Action)
    Add-BoostLabResultRow -Panel $content -Label 'Risk' -Value ([string]$ActionPlan.RiskLevel).ToUpperInvariant()
    Add-BoostLabResultRow -Panel $content -Label 'Summary' -Value ([string]$ActionPlan.Summary)

    Add-BoostLabResultSectionTitle -Panel $content -Text 'Planned Changes'
    foreach ($plannedChange in @($ActionPlan.PlannedChanges)) {
        Add-BoostLabResultBullet -Panel $content -Text ([string]$plannedChange)
    }

    Add-BoostLabResultSectionTitle -Panel $content -Text 'Side Effects'
    foreach ($sideEffect in @($ActionPlan.SideEffects)) {
        Add-BoostLabResultBullet -Panel $content -Text ([string]$sideEffect) -Color '#FDE68A'
    }

    $messageBorder = [System.Windows.Controls.Border]::new()
    $messageBorder.Margin = [System.Windows.Thickness]::new(0, 12, 0, 0)
    $messageBorder.Padding = [System.Windows.Thickness]::new(12)
    $messageBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#2A2020')
    $messageBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#8F505D')
    $messageBorder.BorderThickness = [System.Windows.Thickness]::new(1)
    $messageBorder.CornerRadius = [System.Windows.CornerRadius]::new(7)

    $messageText = [System.Windows.Controls.TextBlock]::new()
    $messageText.Text = [string]$ActionPlan.ConfirmationMessage
    $messageText.FontSize = 12
    $messageText.LineHeight = 18
    $messageText.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $messageText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#FDE68A')
    $messageBorder.Child = $messageText
    $content.Children.Add($messageBorder) | Out-Null

    $scrollViewer.Content = $content
    [System.Windows.Controls.Grid]::SetRow($scrollViewer, 0)
    $root.Children.Add($scrollViewer) | Out-Null

    $buttons = [System.Windows.Controls.StackPanel]::new()
    $buttons.Margin = [System.Windows.Thickness]::new(0, 18, 0, 0)
    $buttons.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $buttons.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right

    $cancelButton = [System.Windows.Controls.Button]::new()
    $cancelButton.Content = 'Cancel'
    $cancelButton.Width = 104
    $cancelButton.Height = 36
    $cancelButton.Margin = [System.Windows.Thickness]::new(0, 0, 10, 0)
    $cancelButton.IsCancel = $true
    $cancelButton.Add_Click(({
        $dialog.DialogResult = $false
    }).GetNewClosure())
    $buttons.Children.Add($cancelButton) | Out-Null

    $confirmButton = [System.Windows.Controls.Button]::new()
    $confirmButton.Content = 'Confirm'
    $confirmButton.Width = 104
    $confirmButton.Height = 36
    $confirmButton.IsDefault = $true
    $confirmButton.Add_Click(({
        $dialog.DialogResult = $true
    }).GetNewClosure())
    $buttons.Children.Add($confirmButton) | Out-Null

    [System.Windows.Controls.Grid]::SetRow($buttons, 1)
    $root.Children.Add($buttons) | Out-Null
    $dialog.Content = $root

    return $dialog.ShowDialog() -eq $true
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
            ToolMetadata = $Tool
            ActionName   = [string]$actionName
            StatusText   = $status
        }
        $actionButton.Style = $script:BoostLabWindow.FindResource('ActionButtonStyle')
        $actionButton.Add_Click({
            $context = $this.Tag
            (Get-BoostLabUiElement -Name 'SelectedToolNameText').Text = [string]$context.ToolMetadata['Title']
            (Get-BoostLabUiElement -Name 'SelectedToolActionText').Text = ([string]$context.ActionName).ToUpperInvariant()

            $result = Invoke-BoostLabToolAction `
                -ToolMetadata $context.ToolMetadata `
                -ActionName $context.ActionName `
                -ConfirmationCallback {
                    param($ActionPlan)
                    Show-BoostLabActionPlanConfirmation -ActionPlan $ActionPlan
                }

            Add-BoostLabToolActionActivityEntry `
                -ToolMetadata $context.ToolMetadata `
                -ActionName $context.ActionName `
                -Result $result

            Show-BoostLabActionResult `
                -ToolMetadata $context.ToolMetadata `
                -ActionName $context.ActionName `
                -Result $result

            $context.StatusText.Text = 'Status: {0}' -f (Get-BoostLabResultStatus -Result $result)
            (Get-BoostLabUiElement -Name 'ApplicationStatusText').Text = "$($result.ToolTitle): $($result.Message)"
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
        [pscustomobject]$EnvironmentInfo,

        [Parameter(Mandatory)]
        [pscustomobject]$LicenseStatus,

        [Parameter(Mandatory)]
        [pscustomobject]$WindowsVersion
    )

    $script:BoostLabWindow = $Window
    $script:BoostLabStages = @($StageConfiguration['Stages'] | Sort-Object { [int]$_['Order'] })
    $script:BoostLabStageButtons = @{}
    $script:BoostLabVisibleLogText.Clear()

    Initialize-BoostLabState

    $adminStatusText = Get-BoostLabUiElement -Name 'AdminStatusText'
    $adminStatusText.Text = if ($EnvironmentInfo.IsAdministrator) {
        'Admin: Yes'
    }
    else {
        'Admin: No'
    }
    $adminStatusText.Foreground = if ($EnvironmentInfo.IsAdministrator) {
        [System.Windows.Media.BrushConverter]::new().ConvertFromString('#86EFAC')
    }
    else {
        [System.Windows.Media.BrushConverter]::new().ConvertFromString('#FDE68A')
    }

    $internetStatusText = Get-BoostLabUiElement -Name 'InternetStatusText'
    $internetStatusText.Text = if ($EnvironmentInfo.HasInternet) {
        'Internet: Online'
    }
    else {
        'Internet: Offline'
    }
    $internetStatusText.Foreground = if ($EnvironmentInfo.HasInternet) {
        [System.Windows.Media.BrushConverter]::new().ConvertFromString('#86EFAC')
    }
    else {
        [System.Windows.Media.BrushConverter]::new().ConvertFromString('#FCA5A5')
    }

    (Get-BoostLabUiElement -Name 'LicenseStatusText').Text = "License: $($LicenseStatus.Status)"
    (Get-BoostLabUiElement -Name 'WindowsStatusText').Text = $WindowsVersion.DisplayName

    (Get-BoostLabUiElement -Name 'ClearLogButton').Add_Click({
        Clear-BoostLabVisibleActivityLog
    })
    (Get-BoostLabUiElement -Name 'CopyLogButton').Add_Click({
        Copy-BoostLabVisibleActivityLog
    })

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
    Write-BoostLabInfo `
        -Message 'BoostLab interface initialized.' `
        -Source 'UI' `
        -EventId 'UI.Initialized' `
        -Data @{
            PowerShellVersion = [string]$EnvironmentInfo.PowerShell.Version
            Architecture      = [string]$EnvironmentInfo.Architecture.OperatingSystem
            PendingReboot     = [bool]$EnvironmentInfo.PendingReboot.IsPending
        } | Out-Null
    Add-BoostLabStartupActivityEntry
}
