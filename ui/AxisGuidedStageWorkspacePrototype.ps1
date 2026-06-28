Set-StrictMode -Version Latest

$script:AxisPrototypeResourcePath = Join-Path $PSScriptRoot 'AxisResources.ps1'
. $script:AxisPrototypeResourcePath

function Get-AxisPrototypeMapValue {
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

function Get-AxisPrototypeResource {
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

function New-AxisPrototypeThickness {
    [CmdletBinding()]
    param(
        [double]$Left,
        [double]$Top = $Left,
        [double]$Right = $Left,
        [double]$Bottom = $Top
    )

    return [System.Windows.Thickness]::new($Left, $Top, $Right, $Bottom)
}

function New-AxisPrototypeTextBlock {
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
        [System.Windows.Thickness]$Margin = (New-AxisPrototypeThickness -Left 0),
        [switch]$Wrap
    )

    $textBlock = [System.Windows.Controls.TextBlock]::new()
    $textBlock.Text = $Text
    $textBlock.FontFamily = Get-AxisPrototypeResource -Resources $Resources -Name $FontFamilyKey
    $textBlock.FontSize = [double](Get-AxisPrototypeResource -Resources $Resources -Name $FontSizeKey)
    $textBlock.FontWeight = Get-AxisPrototypeResource -Resources $Resources -Name $FontWeightKey
    $textBlock.Foreground = Get-AxisPrototypeResource -Resources $Resources -Name $ForegroundKey
    $textBlock.Margin = $Margin

    $resolvedLineHeightKey = if ([string]::IsNullOrWhiteSpace($LineHeightKey)) {
        $FontSizeKey -replace '\.FontSize$', '.LineHeight'
    }
    else {
        $LineHeightKey
    }
    $lineHeight = Get-AxisPrototypeResource -Resources $Resources -Name $resolvedLineHeightKey
    if ($null -ne $lineHeight) {
        $textBlock.LineHeight = [double]$lineHeight
    }

    if ($Wrap) {
        $textBlock.TextWrapping = [System.Windows.TextWrapping]::Wrap
    }

    return $textBlock
}

function New-AxisPrototypePanel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Resources,

        [string]$BackgroundKey = 'Axis.Brush.Surface.Base',
        [string]$BorderBrushKey = 'Axis.Brush.Border.Subtle',
        [string]$RadiusKey = 'Axis.Radius.Large',
        [System.Windows.Thickness]$Padding = (New-AxisPrototypeThickness -Left 16),
        [System.Windows.Thickness]$Margin = (New-AxisPrototypeThickness -Left 0),
        [System.Windows.Thickness]$BorderThickness = (New-AxisPrototypeThickness -Left 1)
    )

    $panel = [System.Windows.Controls.Border]::new()
    $panel.Background = Get-AxisPrototypeResource -Resources $Resources -Name $BackgroundKey
    $panel.BorderBrush = Get-AxisPrototypeResource -Resources $Resources -Name $BorderBrushKey
    $panel.BorderThickness = $BorderThickness
    $panel.CornerRadius = Get-AxisPrototypeResource -Resources $Resources -Name $RadiusKey
    $panel.Padding = $Padding
    $panel.Margin = $Margin

    return $panel
}

function Get-AxisPrototypeStatusResourceName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$State
    )

    switch ($State) {
        'Completed' { return 'Completed' }
        'CompletedWithNotes' { return 'CompletedWithNotes' }
        'NeedsAttention' { return 'NeedsAttention' }
        'RestartNeeded' { return 'RestartNeeded' }
        'WaitingForConfirmation' { return 'WaitingForConfirmation' }
        'NotAvailableOnThisDevice' { return 'NotAvailableOnThisDevice' }
        'SkippedBecauseNotNeeded' { return 'SkippedBecauseNotNeeded' }
        'Running' { return 'Running' }
        'Stopped' { return 'Stopped' }
        default { return '' }
    }
}

function New-AxisPrototypeStatePill {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$State,

        [Parameter(Mandatory)]
        [string]$Label,

        [Parameter(Mandatory)]
        [object]$Resources
    )

    $statusName = Get-AxisPrototypeStatusResourceName -State $State
    if ([string]::IsNullOrWhiteSpace($statusName)) {
        $backgroundKey = if ($State -eq 'Selected') { 'Axis.Brush.Accent.Subtle' } else { 'Axis.Brush.Surface.Interactive' }
        $borderKey = if ($State -eq 'Selected') { 'Axis.Brush.Accent.Primary' } else { 'Axis.Brush.Border.Default' }
        $textKey = if ($State -eq 'Selected') { 'Axis.Brush.Accent.Text' } else { 'Axis.Brush.Text.Secondary' }
    }
    else {
        $backgroundKey = "Axis.Status.$statusName.BackgroundBrush"
        $borderKey = "Axis.Status.$statusName.BorderBrush"
        $textKey = "Axis.Status.$statusName.TextBrush"
    }

    $pill = New-AxisPrototypePanel `
        -Resources $Resources `
        -BackgroundKey $backgroundKey `
        -BorderBrushKey $borderKey `
        -RadiusKey 'Axis.Radius.Pill' `
        -Padding (New-AxisPrototypeThickness -Left 8 -Top 4 -Right 8 -Bottom 4)
    $pill.Tag = 'AxisPrototype.StatePill'
    $pill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    $pill.Child = New-AxisPrototypeTextBlock `
        -Text $Label `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.Micro.FontSize' `
        -FontWeightKey 'Axis.Type.Micro.FontWeight' `
        -ForegroundKey $textKey

    return $pill
}

function Get-AxisPrototypeRiskResourceName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Risk
    )

    switch ($Risk) {
        'System change' { return 'SystemChange' }
        'Driver change' { return 'DriverChange' }
        'Security-sensitive' { return 'SecuritySensitive' }
        'Restart required' { return 'RestartRequired' }
        'Download required' { return 'DownloadRequired' }
        'File cleanup' { return 'FileCleanup' }
        'Advanced' { return 'Advanced' }
        'Device-specific' { return 'DeviceSpecific' }
        default { return 'Advanced' }
    }
}

function New-AxisPrototypeRiskBadge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Risk,

        [Parameter(Mandatory)]
        [object]$Resources
    )

    $riskName = Get-AxisPrototypeRiskResourceName -Risk $Risk
    $badge = New-AxisPrototypePanel `
        -Resources $Resources `
        -BackgroundKey "Axis.Risk.$riskName.BackgroundBrush" `
        -BorderBrushKey "Axis.Risk.$riskName.BorderBrush" `
        -RadiusKey 'Axis.Radius.Small' `
        -Padding (New-AxisPrototypeThickness -Left 8 -Top 4 -Right 8 -Bottom 4) `
        -Margin (New-AxisPrototypeThickness -Left 0 -Top 0 -Right 6 -Bottom 6)
    $badge.Tag = 'AxisPrototype.RiskBadge'
    $badge.Child = New-AxisPrototypeTextBlock `
        -Text $Risk `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.Micro.FontSize' `
        -FontWeightKey 'Axis.Type.Micro.FontWeight' `
        -ForegroundKey "Axis.Risk.$riskName.TextBrush"

    return $badge
}

function New-AxisPrototypeButton {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [object]$Resources,

        [ValidateSet('Primary', 'Secondary', 'Quiet')]
        [string]$Variant = 'Secondary'
    )

    $button = [System.Windows.Controls.Button]::new()
    $button.Content = $Text
    $button.Padding = New-AxisPrototypeThickness -Left 12 -Top 8 -Right 12 -Bottom 8
    $button.Margin = New-AxisPrototypeThickness -Left 0 -Top 0 -Right 8 -Bottom 0
    $button.BorderThickness = New-AxisPrototypeThickness -Left 1
    $button.FontFamily = Get-AxisPrototypeResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontFamily'
    $button.FontSize = [double](Get-AxisPrototypeResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontSize')
    $button.FontWeight = Get-AxisPrototypeResource -Resources $Resources -Name 'Axis.Type.BodySmall.FontWeight'
    $button.Focusable = $false
    $button.IsHitTestVisible = $false
    $button.Tag = 'AxisPrototype.ActionButton'

    if ($Variant -eq 'Primary') {
        $button.Background = Get-AxisPrototypeResource -Resources $Resources -Name 'Axis.Brush.Accent.Primary'
        $button.BorderBrush = Get-AxisPrototypeResource -Resources $Resources -Name 'Axis.Brush.Accent.Hover'
        $button.Foreground = Get-AxisPrototypeResource -Resources $Resources -Name 'Axis.Brush.Text.Inverse'
    }
    elseif ($Variant -eq 'Quiet') {
        $button.Background = Get-AxisPrototypeResource -Resources $Resources -Name 'Axis.Brush.Background.Inset'
        $button.BorderBrush = Get-AxisPrototypeResource -Resources $Resources -Name 'Axis.Brush.Border.Subtle'
        $button.Foreground = Get-AxisPrototypeResource -Resources $Resources -Name 'Axis.Brush.Text.Secondary'
    }
    else {
        $button.Background = Get-AxisPrototypeResource -Resources $Resources -Name 'Axis.Brush.Surface.Interactive'
        $button.BorderBrush = Get-AxisPrototypeResource -Resources $Resources -Name 'Axis.Brush.Border.Default'
        $button.Foreground = Get-AxisPrototypeResource -Resources $Resources -Name 'Axis.Brush.Text.Primary'
    }

    return $button
}

function Get-AxisPrototypeSampleState {
    [CmdletBinding()]
    param()

    $tools = @(
        [ordered]@{
            Title = 'Start menu and taskbar'
            State = 'Selected'
            StateLabel = 'Selected'
            Purpose = 'Shape the everyday Windows entry points before deeper setup work.'
            Risks = @('System change', 'Device-specific')
            Requirements = @('Administrator access', 'Windows 11 target')
            ExpectedOutcome = 'A cleaner layout with fewer distractions.'
        }
        [ordered]@{
            Title = 'Context menu'
            State = 'Completed'
            StateLabel = 'Completed'
            Purpose = 'Keep the right-click experience predictable and familiar.'
            Risks = @('System change')
            Requirements = @('Restart may be requested later')
            ExpectedOutcome = 'The desktop context menu is ready.'
        }
        [ordered]@{
            Title = 'Theme and wallpaper'
            State = 'CompletedWithNotes'
            StateLabel = 'Completed with notes'
            Purpose = 'Apply a quiet visual baseline for the Windows desktop.'
            Risks = @('System change')
            Requirements = @('User profile setting')
            ExpectedOutcome = 'Theme choices were checked with a note to review personalization.'
        }
        [ordered]@{
            Title = 'Widgets'
            State = 'SkippedBecauseNotNeeded'
            StateLabel = 'Skipped because not needed'
            Purpose = 'Avoid changing a Windows feature that is already in the desired state.'
            Risks = @('System change')
            Requirements = @('Current device state')
            ExpectedOutcome = 'No extra work is needed for this step.'
        }
        [ordered]@{
            Title = 'Copilot'
            State = 'NotAvailableOnThisDevice'
            StateLabel = 'Not available on this device'
            Purpose = 'Show when a feature is unavailable without treating it as a failure.'
            Risks = @('Device-specific')
            Requirements = @('Supported Windows edition')
            ExpectedOutcome = 'The setup path can continue.'
        }
        [ordered]@{
            Title = 'Game Mode'
            State = 'Default'
            StateLabel = 'Ready to review'
            Purpose = 'Review the gaming-focused Windows behavior before any change.'
            Risks = @('System change')
            Requirements = @('User confirmation later')
            ExpectedOutcome = 'Recommended behavior is explained before the user decides.'
        }
        [ordered]@{
            Title = 'Power plan'
            State = 'Running'
            StateLabel = 'Running'
            Purpose = 'Represent active work without exposing command noise in the main view.'
            Risks = @('System change', 'Advanced')
            Requirements = @('Power settings access')
            ExpectedOutcome = 'The device is being prepared for a consistent performance profile.'
        }
        [ordered]@{
            Title = 'Cleanup'
            State = 'NeedsAttention'
            StateLabel = 'Needs attention'
            Purpose = 'Review cleanup scope before anything is removed.'
            Risks = @('File cleanup', 'Security-sensitive')
            Requirements = @('Explicit review')
            ExpectedOutcome = 'The user understands what would be cleaned before continuing.'
        }
        [ordered]@{
            Title = 'Restart checkpoint'
            State = 'RestartNeeded'
            StateLabel = 'Restart needed'
            Purpose = 'Make restart timing visible and predictable.'
            Risks = @('Restart required')
            Requirements = @('Save work before restart')
            ExpectedOutcome = 'The setup path pauses at a clear checkpoint.'
        }
    )

    return [ordered]@{
        BrandName = 'AXIS'
        ModeLabel = 'Guided setup'
        Stage = [ordered]@{
            Name = 'Windows'
            Purpose = 'Configure core Windows experience'
            Summary = 'Review the everyday Windows surface, privacy-adjacent controls, performance-sensitive choices, and final cleanup checkpoints in a calm guided workspace.'
            Progress = '4 of 9 sample steps are already resolved'
            NextStep = 'Review Start menu and taskbar'
        }
        Stages = @(
            [ordered]@{ Name = 'Prepare'; State = 'Completed'; StateLabel = 'Completed' }
            [ordered]@{ Name = 'Setup'; State = 'CompletedWithNotes'; StateLabel = 'Completed with notes' }
            [ordered]@{ Name = 'Windows'; State = 'Selected'; StateLabel = 'Current' }
            [ordered]@{ Name = 'Apps'; State = 'Default'; StateLabel = 'Ready later' }
            [ordered]@{ Name = 'Graphics'; State = 'NeedsAttention'; StateLabel = 'Needs attention' }
            [ordered]@{ Name = 'Performance'; State = 'Default'; StateLabel = 'Ready later' }
            [ordered]@{ Name = 'Cleanup'; State = 'SkippedBecauseNotNeeded'; StateLabel = 'Skipped because not needed' }
            [ordered]@{ Name = 'Finish'; State = 'WaitingForConfirmation'; StateLabel = 'Waiting for your confirmation' }
        )
        Tools = $tools
        SelectedTool = $tools[0]
        ResultSummary = @(
            [ordered]@{ Label = 'Completed'; Value = '2 steps' }
            [ordered]@{ Label = 'Completed with notes'; Value = '1 note' }
            [ordered]@{ Label = 'Needs attention'; Value = '1 review' }
            [ordered]@{ Label = 'Restart needed'; Value = '1 checkpoint' }
            [ordered]@{ Label = 'Waiting for your confirmation'; Value = '1 decision' }
        )
        Diagnostics = [ordered]@{
            Summary = 'Static prototype data only.'
            TechnicalStatus = 'Sample status for layout review.'
            Operations = @(
                'No live operation is connected.'
                'No action handlers are registered.'
                'No device state is queried.'
            )
            Logs = @(
                'Preview opened from static sample state.'
                'Diagnostics are intentionally secondary.'
            )
        }
    }
}

function New-AxisPrototypeStageNavigation {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$SampleState = (Get-AxisPrototypeSampleState),

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    $container = New-AxisPrototypePanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Background.Panel' `
        -BorderBrushKey 'Axis.Brush.Border.Divider' `
        -RadiusKey 'Axis.Radius.None' `
        -Padding (New-AxisPrototypeThickness -Left 18 -Top 20 -Right 18 -Bottom 20) `
        -BorderThickness (New-AxisPrototypeThickness -Left 0 -Top 0 -Right 1 -Bottom 0)
    $container.Tag = 'AxisPrototype.StageNavigation'

    $stack = [System.Windows.Controls.StackPanel]::new()
    $stack.Orientation = [System.Windows.Controls.Orientation]::Vertical

    [void]$stack.Children.Add((New-AxisPrototypeTextBlock `
        -Text 'Guided setup' `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.SectionTitle.FontSize' `
        -FontWeightKey 'Axis.Type.SectionTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Text.Primary'))
    [void]$stack.Children.Add((New-AxisPrototypeTextBlock `
        -Text 'Your setup path' `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.Caption.FontSize' `
        -ForegroundKey 'Axis.Brush.Text.Muted' `
        -Margin (New-AxisPrototypeThickness -Left 0 -Top 2 -Right 0 -Bottom 16)))

    foreach ($stage in @(Get-AxisPrototypeMapValue -Map $SampleState -Name 'Stages' -DefaultValue @())) {
        $state = [string](Get-AxisPrototypeMapValue -Map $stage -Name 'State' -DefaultValue 'Default')
        $label = [string](Get-AxisPrototypeMapValue -Map $stage -Name 'StateLabel' -DefaultValue 'Ready later')
        $isSelected = $state -eq 'Selected'
        $stagePanel = New-AxisPrototypePanel `
            -Resources $Resources `
            -BackgroundKey $(if ($isSelected) { 'Axis.Brush.Selection.Background' } else { 'Axis.Brush.Background.Panel' }) `
            -BorderBrushKey $(if ($isSelected) { 'Axis.Brush.Selection.Border' } else { 'Axis.Brush.Border.Divider' }) `
            -RadiusKey 'Axis.Radius.Medium' `
            -Padding (New-AxisPrototypeThickness -Left 12 -Top 10 -Right 12 -Bottom 10) `
            -Margin (New-AxisPrototypeThickness -Left 0 -Top 0 -Right 0 -Bottom 8)
        $stagePanel.Tag = 'AxisPrototype.StageNavigationItem'

        $stageStack = [System.Windows.Controls.StackPanel]::new()
        $stageStack.Orientation = [System.Windows.Controls.Orientation]::Vertical
        [void]$stageStack.Children.Add((New-AxisPrototypeTextBlock `
            -Text ([string](Get-AxisPrototypeMapValue -Map $stage -Name 'Name')) `
            -Resources $Resources `
            -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
            -FontWeightKey 'Axis.Type.Micro.FontWeight' `
            -ForegroundKey $(if ($isSelected) { 'Axis.Brush.Text.Primary' } else { 'Axis.Brush.Text.Secondary' })))
        [void]$stageStack.Children.Add((New-AxisPrototypeTextBlock `
            -Text $label `
            -Resources $Resources `
            -FontSizeKey 'Axis.Type.Micro.FontSize' `
            -ForegroundKey $(if ($isSelected) { 'Axis.Brush.Accent.Text' } else { 'Axis.Brush.Text.Muted' }) `
            -Margin (New-AxisPrototypeThickness -Left 0 -Top 2 -Right 0 -Bottom 0)))
        $stagePanel.Child = $stageStack
        [void]$stack.Children.Add($stagePanel)
    }

    $container.Child = $stack
    return $container
}

function New-AxisPrototypeToolCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Tool,

        [Parameter(Mandatory)]
        [object]$Resources
    )

    $state = [string](Get-AxisPrototypeMapValue -Map $Tool -Name 'State' -DefaultValue 'Default')
    $statusName = Get-AxisPrototypeStatusResourceName -State $state
    $isSelected = $state -eq 'Selected'
    $borderKey = if ($isSelected) {
        'Axis.Brush.Selection.Border'
    }
    elseif (-not [string]::IsNullOrWhiteSpace($statusName)) {
        "Axis.Status.$statusName.BorderBrush"
    }
    else {
        'Axis.Brush.Border.Subtle'
    }

    $card = New-AxisPrototypePanel `
        -Resources $Resources `
        -BackgroundKey $(if ($isSelected) { 'Axis.Brush.Surface.Raised' } else { 'Axis.Brush.Surface.Base' }) `
        -BorderBrushKey $borderKey `
        -RadiusKey 'Axis.Radius.Large' `
        -Padding (New-AxisPrototypeThickness -Left 16) `
        -Margin (New-AxisPrototypeThickness -Left 0 -Top 0 -Right 12 -Bottom 12)
    $card.Width = 274
    $card.MinHeight = 190
    $card.Tag = 'AxisPrototype.ToolCard'

    $stack = [System.Windows.Controls.StackPanel]::new()
    $stack.Orientation = [System.Windows.Controls.Orientation]::Vertical

    [void]$stack.Children.Add((New-AxisPrototypeStatePill `
        -State $state `
        -Label ([string](Get-AxisPrototypeMapValue -Map $Tool -Name 'StateLabel' -DefaultValue 'Ready to review')) `
        -Resources $Resources))
    [void]$stack.Children.Add((New-AxisPrototypeTextBlock `
        -Text ([string](Get-AxisPrototypeMapValue -Map $Tool -Name 'Title')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.CardTitle.FontSize' `
        -FontWeightKey 'Axis.Type.CardTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Text.Primary' `
        -Margin (New-AxisPrototypeThickness -Left 0 -Top 12 -Right 0 -Bottom 4) `
        -Wrap))
    [void]$stack.Children.Add((New-AxisPrototypeTextBlock `
        -Text ([string](Get-AxisPrototypeMapValue -Map $Tool -Name 'Purpose')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -ForegroundKey 'Axis.Brush.Text.Secondary' `
        -Wrap))

    $riskWrap = [System.Windows.Controls.WrapPanel]::new()
    $riskWrap.Margin = New-AxisPrototypeThickness -Left 0 -Top 12 -Right 0 -Bottom 0
    foreach ($risk in @(Get-AxisPrototypeMapValue -Map $Tool -Name 'Risks' -DefaultValue @())) {
        [void]$riskWrap.Children.Add((New-AxisPrototypeRiskBadge -Risk ([string]$risk) -Resources $Resources))
    }
    [void]$stack.Children.Add($riskWrap)

    $card.Child = $stack
    return $card
}

function New-AxisPrototypeResultSummary {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$SampleState = (Get-AxisPrototypeSampleState),

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    $summaryPanel = New-AxisPrototypePanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Background.Inset' `
        -BorderBrushKey 'Axis.Brush.Border.Divider' `
        -RadiusKey 'Axis.Radius.Large' `
        -Padding (New-AxisPrototypeThickness -Left 16) `
        -Margin (New-AxisPrototypeThickness -Left 0 -Top 18 -Right 0 -Bottom 0)
    $summaryPanel.Tag = 'AxisPrototype.ResultSummary'

    $stack = [System.Windows.Controls.StackPanel]::new()
    $stack.Orientation = [System.Windows.Controls.Orientation]::Vertical
    [void]$stack.Children.Add((New-AxisPrototypeTextBlock `
        -Text 'Result summary' `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.SectionTitle.FontSize' `
        -FontWeightKey 'Axis.Type.SectionTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Text.Primary'))

    $wrap = [System.Windows.Controls.WrapPanel]::new()
    $wrap.Margin = New-AxisPrototypeThickness -Left 0 -Top 12 -Right 0 -Bottom 0
    foreach ($item in @(Get-AxisPrototypeMapValue -Map $SampleState -Name 'ResultSummary' -DefaultValue @())) {
        $itemPanel = New-AxisPrototypePanel `
            -Resources $Resources `
            -BackgroundKey 'Axis.Brush.Surface.Base' `
            -BorderBrushKey 'Axis.Brush.Border.Subtle' `
            -RadiusKey 'Axis.Radius.Medium' `
            -Padding (New-AxisPrototypeThickness -Left 12 -Top 10 -Right 12 -Bottom 10) `
            -Margin (New-AxisPrototypeThickness -Left 0 -Top 0 -Right 10 -Bottom 10)
        $itemPanel.Width = 176
        $itemStack = [System.Windows.Controls.StackPanel]::new()
        [void]$itemStack.Children.Add((New-AxisPrototypeTextBlock `
            -Text ([string](Get-AxisPrototypeMapValue -Map $item -Name 'Label')) `
            -Resources $Resources `
            -FontSizeKey 'Axis.Type.Caption.FontSize' `
            -ForegroundKey 'Axis.Brush.Text.Secondary'))
        [void]$itemStack.Children.Add((New-AxisPrototypeTextBlock `
            -Text ([string](Get-AxisPrototypeMapValue -Map $item -Name 'Value')) `
            -Resources $Resources `
            -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
            -FontWeightKey 'Axis.Type.Micro.FontWeight' `
            -ForegroundKey 'Axis.Brush.Text.Primary' `
            -Margin (New-AxisPrototypeThickness -Left 0 -Top 2 -Right 0 -Bottom 0)))
        $itemPanel.Child = $itemStack
        [void]$wrap.Children.Add($itemPanel)
    }

    [void]$stack.Children.Add($wrap)
    $summaryPanel.Child = $stack
    return $summaryPanel
}

function New-AxisPrototypeDiagnosticsDrawer {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$SampleState = (Get-AxisPrototypeSampleState),

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    $diagnostics = Get-AxisPrototypeMapValue -Map $SampleState -Name 'Diagnostics' -DefaultValue ([ordered]@{})
    $expander = [System.Windows.Controls.Expander]::new()
    $expander.Header = 'Diagnostics'
    $expander.IsExpanded = $false
    $expander.Margin = New-AxisPrototypeThickness -Left 0 -Top 12 -Right 0 -Bottom 0
    $expander.Foreground = Get-AxisPrototypeResource -Resources $Resources -Name 'Axis.Brush.Text.Diagnostics'
    $expander.Background = Get-AxisPrototypeResource -Resources $Resources -Name 'Axis.Brush.Diagnostics.Background'
    $expander.BorderBrush = Get-AxisPrototypeResource -Resources $Resources -Name 'Axis.Brush.Diagnostics.Border'
    $expander.BorderThickness = New-AxisPrototypeThickness -Left 1
    $expander.Padding = New-AxisPrototypeThickness -Left 12
    $expander.Tag = 'AxisPrototype.DiagnosticsDrawer'

    $stack = [System.Windows.Controls.StackPanel]::new()
    $stack.Orientation = [System.Windows.Controls.Orientation]::Vertical

    foreach ($section in @(
        [ordered]@{ Title = 'Summary'; Value = [string](Get-AxisPrototypeMapValue -Map $diagnostics -Name 'Summary') }
        [ordered]@{ Title = 'Technical status'; Value = [string](Get-AxisPrototypeMapValue -Map $diagnostics -Name 'TechnicalStatus') }
        [ordered]@{ Title = 'Operations'; Value = (@(Get-AxisPrototypeMapValue -Map $diagnostics -Name 'Operations' -DefaultValue @()) -join [Environment]::NewLine) }
        [ordered]@{ Title = 'Logs'; Value = (@(Get-AxisPrototypeMapValue -Map $diagnostics -Name 'Logs' -DefaultValue @()) -join [Environment]::NewLine) }
    )) {
        [void]$stack.Children.Add((New-AxisPrototypeTextBlock `
            -Text ([string]$section['Title']) `
            -Resources $Resources `
            -FontSizeKey 'Axis.Type.Caption.FontSize' `
            -FontWeightKey 'Axis.Type.Micro.FontWeight' `
            -ForegroundKey 'Axis.Brush.Text.Primary' `
            -Margin (New-AxisPrototypeThickness -Left 0 -Top 8 -Right 0 -Bottom 2)))
        [void]$stack.Children.Add((New-AxisPrototypeTextBlock `
            -Text ([string]$section['Value']) `
            -Resources $Resources `
            -FontSizeKey 'Axis.Type.DiagnosticsMono.FontSize' `
            -FontFamilyKey 'Axis.Type.DiagnosticsMono.FontFamily' `
            -ForegroundKey 'Axis.Brush.Diagnostics.Text' `
            -Wrap))
    }

    [void]$stack.Children.Add((New-AxisPrototypeButton -Text 'Copy technical report' -Resources $Resources -Variant 'Quiet'))
    $expander.Content = $stack
    return $expander
}

function New-AxisPrototypeToolDetailPanel {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$Tool,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    if ($null -eq $Tool) {
        $Tool = (Get-AxisPrototypeSampleState)['SelectedTool']
    }

    $detailPanel = New-AxisPrototypePanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Surface.Raised' `
        -BorderBrushKey 'Axis.Brush.Border.Subtle' `
        -RadiusKey 'Axis.Radius.Large' `
        -Padding (New-AxisPrototypeThickness -Left 20)
    $detailPanel.Tag = 'AxisPrototype.ToolDetailPanel'

    $stack = [System.Windows.Controls.StackPanel]::new()
    $stack.Orientation = [System.Windows.Controls.Orientation]::Vertical

    [void]$stack.Children.Add((New-AxisPrototypeTextBlock `
        -Text 'Selected step' `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.Caption.FontSize' `
        -ForegroundKey 'Axis.Brush.Accent.Text'))
    [void]$stack.Children.Add((New-AxisPrototypeTextBlock `
        -Text ([string](Get-AxisPrototypeMapValue -Map $Tool -Name 'Title')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.SectionTitle.FontSize' `
        -FontWeightKey 'Axis.Type.SectionTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Text.Primary' `
        -Margin (New-AxisPrototypeThickness -Left 0 -Top 4 -Right 0 -Bottom 8) `
        -Wrap))
    [void]$stack.Children.Add((New-AxisPrototypeTextBlock `
        -Text ([string](Get-AxisPrototypeMapValue -Map $Tool -Name 'Purpose')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.Body.FontSize' `
        -ForegroundKey 'Axis.Brush.Text.Secondary' `
        -Wrap))

    [void]$stack.Children.Add((New-AxisPrototypeTextBlock `
        -Text 'What this step changes' `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.CardTitle.FontSize' `
        -FontWeightKey 'Axis.Type.CardTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Text.Primary' `
        -Margin (New-AxisPrototypeThickness -Left 0 -Top 20 -Right 0 -Bottom 8)))
    [void]$stack.Children.Add((New-AxisPrototypeTextBlock `
        -Text ([string](Get-AxisPrototypeMapValue -Map $Tool -Name 'ExpectedOutcome')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -ForegroundKey 'Axis.Brush.Text.Secondary' `
        -Wrap))

    [void]$stack.Children.Add((New-AxisPrototypeTextBlock `
        -Text 'Requirements' `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.CardTitle.FontSize' `
        -FontWeightKey 'Axis.Type.CardTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Text.Primary' `
        -Margin (New-AxisPrototypeThickness -Left 0 -Top 20 -Right 0 -Bottom 8)))
    foreach ($requirement in @(Get-AxisPrototypeMapValue -Map $Tool -Name 'Requirements' -DefaultValue @())) {
        [void]$stack.Children.Add((New-AxisPrototypeTextBlock `
            -Text ("- {0}" -f [string]$requirement) `
            -Resources $Resources `
            -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
            -ForegroundKey 'Axis.Brush.Text.Secondary' `
            -Wrap))
    }

    $riskWrap = [System.Windows.Controls.WrapPanel]::new()
    $riskWrap.Margin = New-AxisPrototypeThickness -Left 0 -Top 18 -Right 0 -Bottom 16
    foreach ($risk in @(Get-AxisPrototypeMapValue -Map $Tool -Name 'Risks' -DefaultValue @())) {
        [void]$riskWrap.Children.Add((New-AxisPrototypeRiskBadge -Risk ([string]$risk) -Resources $Resources))
    }
    [void]$stack.Children.Add($riskWrap)

    $actionPanel = New-AxisPrototypePanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Background.Inset' `
        -BorderBrushKey 'Axis.Brush.Border.Divider' `
        -RadiusKey 'Axis.Radius.Medium' `
        -Padding (New-AxisPrototypeThickness -Left 14)
    $actionPanel.Tag = 'AxisPrototype.ActionArea'
    $actionStack = [System.Windows.Controls.StackPanel]::new()
    $actionStack.Orientation = [System.Windows.Controls.Orientation]::Vertical
    [void]$actionStack.Children.Add((New-AxisPrototypeTextBlock `
        -Text 'Action area' `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.CardTitle.FontSize' `
        -FontWeightKey 'Axis.Type.CardTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Text.Primary'))
    [void]$actionStack.Children.Add((New-AxisPrototypeTextBlock `
        -Text 'Prototype controls are visual only and do not run setup steps.' `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -ForegroundKey 'Axis.Brush.Text.Muted' `
        -Margin (New-AxisPrototypeThickness -Left 0 -Top 4 -Right 0 -Bottom 12) `
        -Wrap))
    $buttons = [System.Windows.Controls.WrapPanel]::new()
    [void]$buttons.Children.Add((New-AxisPrototypeButton -Text 'Review planned change' -Resources $Resources -Variant 'Primary'))
    [void]$buttons.Children.Add((New-AxisPrototypeButton -Text 'View details' -Resources $Resources -Variant 'Secondary'))
    [void]$buttons.Children.Add((New-AxisPrototypeButton -Text 'Skip for now' -Resources $Resources -Variant 'Quiet'))
    [void]$actionStack.Children.Add($buttons)
    $actionPanel.Child = $actionStack
    [void]$stack.Children.Add($actionPanel)

    $detailPanel.Child = $stack
    return $detailPanel
}

function New-AxisPrototypeStageScreen {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$SampleState = (Get-AxisPrototypeSampleState),

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    $stage = Get-AxisPrototypeMapValue -Map $SampleState -Name 'Stage' -DefaultValue ([ordered]@{})
    $screen = [System.Windows.Controls.ScrollViewer]::new()
    $screen.VerticalScrollBarVisibility = [System.Windows.Controls.ScrollBarVisibility]::Auto
    $screen.HorizontalScrollBarVisibility = [System.Windows.Controls.ScrollBarVisibility]::Disabled
    $screen.Tag = 'AxisPrototype.StageScreen'

    $stack = [System.Windows.Controls.StackPanel]::new()
    $stack.Orientation = [System.Windows.Controls.Orientation]::Vertical
    $stack.Margin = New-AxisPrototypeThickness -Left 28 -Top 26 -Right 28 -Bottom 26

    [void]$stack.Children.Add((New-AxisPrototypeTextBlock `
        -Text ([string](Get-AxisPrototypeMapValue -Map $stage -Name 'Name')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.PageTitle.FontSize' `
        -FontWeightKey 'Axis.Type.PageTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Text.Primary'))
    [void]$stack.Children.Add((New-AxisPrototypeTextBlock `
        -Text ([string](Get-AxisPrototypeMapValue -Map $stage -Name 'Purpose')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.Body.FontSize' `
        -ForegroundKey 'Axis.Brush.Accent.Text' `
        -Margin (New-AxisPrototypeThickness -Left 0 -Top 2 -Right 0 -Bottom 8) `
        -Wrap))
    [void]$stack.Children.Add((New-AxisPrototypeTextBlock `
        -Text ([string](Get-AxisPrototypeMapValue -Map $stage -Name 'Summary')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.Body.FontSize' `
        -ForegroundKey 'Axis.Brush.Text.Secondary' `
        -Wrap))

    $progressPanel = New-AxisPrototypePanel `
        -Resources $Resources `
        -BackgroundKey 'Axis.Brush.Accent.Subtle' `
        -BorderBrushKey 'Axis.Brush.Selection.Border' `
        -RadiusKey 'Axis.Radius.Large' `
        -Padding (New-AxisPrototypeThickness -Left 16) `
        -Margin (New-AxisPrototypeThickness -Left 0 -Top 18 -Right 0 -Bottom 18)
    $progressStack = [System.Windows.Controls.StackPanel]::new()
    $progressStack.Orientation = [System.Windows.Controls.Orientation]::Vertical
    [void]$progressStack.Children.Add((New-AxisPrototypeTextBlock `
        -Text ([string](Get-AxisPrototypeMapValue -Map $stage -Name 'Progress')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -FontWeightKey 'Axis.Type.Micro.FontWeight' `
        -ForegroundKey 'Axis.Brush.Text.Primary'))
    [void]$progressStack.Children.Add((New-AxisPrototypeTextBlock `
        -Text ("Next step: {0}" -f [string](Get-AxisPrototypeMapValue -Map $stage -Name 'NextStep')) `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -ForegroundKey 'Axis.Brush.Accent.Text' `
        -Margin (New-AxisPrototypeThickness -Left 0 -Top 4 -Right 0 -Bottom 0)))
    $progressPanel.Child = $progressStack
    [void]$stack.Children.Add($progressPanel)

    [void]$stack.Children.Add((New-AxisPrototypeTextBlock `
        -Text 'Windows steps' `
        -Resources $Resources `
        -FontSizeKey 'Axis.Type.SectionTitle.FontSize' `
        -FontWeightKey 'Axis.Type.SectionTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Text.Primary' `
        -Margin (New-AxisPrototypeThickness -Left 0 -Top 0 -Right 0 -Bottom 12)))

    $cards = [System.Windows.Controls.WrapPanel]::new()
    $cards.Tag = 'AxisPrototype.ToolCardList'
    foreach ($tool in @(Get-AxisPrototypeMapValue -Map $SampleState -Name 'Tools' -DefaultValue @())) {
        [void]$cards.Children.Add((New-AxisPrototypeToolCard -Tool $tool -Resources $Resources))
    }
    [void]$stack.Children.Add($cards)

    [void]$stack.Children.Add((New-AxisPrototypeResultSummary -SampleState $SampleState -Resources $Resources))
    [void]$stack.Children.Add((New-AxisPrototypeDiagnosticsDrawer -SampleState $SampleState -Resources $Resources))

    $screen.Content = $stack
    return $screen
}

function New-AxisGuidedStageWorkspacePrototype {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$SampleState = (Get-AxisPrototypeSampleState)
    )

    $resources = New-AxisWpfResourceDictionary

    $root = [System.Windows.Controls.Grid]::new()
    $root.Tag = 'AxisPrototype.GuidedStageWorkspace'
    $root.MinWidth = 1180
    $root.MinHeight = 720
    $root.Background = Get-AxisPrototypeResource -Resources $resources -Name 'Axis.Brush.Background.App'
    [void](Add-AxisResourcesToElement -Element $root -Resources $resources)

    $headerRow = [System.Windows.Controls.RowDefinition]::new()
    $headerRow.Height = [System.Windows.GridLength]::Auto
    [void]$root.RowDefinitions.Add($headerRow)
    $contentRow = [System.Windows.Controls.RowDefinition]::new()
    $contentRow.Height = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    [void]$root.RowDefinitions.Add($contentRow)

    $navColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $navColumn.Width = [System.Windows.GridLength]::new(246)
    $mainColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $mainColumn.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $detailColumn = [System.Windows.Controls.ColumnDefinition]::new()
    $detailColumn.Width = [System.Windows.GridLength]::new(360)

    $contentGrid = [System.Windows.Controls.Grid]::new()
    $contentGrid.Background = Get-AxisPrototypeResource -Resources $resources -Name 'Axis.Brush.Background.App'
    [void]$contentGrid.ColumnDefinitions.Add($navColumn)
    [void]$contentGrid.ColumnDefinitions.Add($mainColumn)
    [void]$contentGrid.ColumnDefinitions.Add($detailColumn)

    $header = New-AxisPrototypePanel `
        -Resources $resources `
        -BackgroundKey 'Axis.Brush.Background.Panel' `
        -BorderBrushKey 'Axis.Brush.Border.Divider' `
        -RadiusKey 'Axis.Radius.None' `
        -Padding (New-AxisPrototypeThickness -Left 24 -Top 16 -Right 24 -Bottom 16) `
        -BorderThickness (New-AxisPrototypeThickness -Left 0 -Top 0 -Right 0 -Bottom 1)
    $header.Tag = 'AxisPrototype.ProductHeader'
    $headerStack = [System.Windows.Controls.StackPanel]::new()
    $headerStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal

    [void]$headerStack.Children.Add((New-AxisPrototypeTextBlock `
        -Text ([string](Get-AxisPrototypeMapValue -Map $SampleState -Name 'BrandName' -DefaultValue 'AXIS')) `
        -Resources $resources `
        -FontSizeKey 'Axis.Type.PageTitle.FontSize' `
        -FontWeightKey 'Axis.Type.PageTitle.FontWeight' `
        -ForegroundKey 'Axis.Brush.Text.Primary'))
    [void]$headerStack.Children.Add((New-AxisPrototypeTextBlock `
        -Text ([string](Get-AxisPrototypeMapValue -Map $SampleState -Name 'ModeLabel' -DefaultValue 'Guided setup')) `
        -Resources $resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -ForegroundKey 'Axis.Brush.Accent.Text' `
        -Margin (New-AxisPrototypeThickness -Left 18 -Top 8 -Right 0 -Bottom 0)))
    [void]$headerStack.Children.Add((New-AxisPrototypeTextBlock `
        -Text 'Windows workspace prototype' `
        -Resources $resources `
        -FontSizeKey 'Axis.Type.BodySmall.FontSize' `
        -ForegroundKey 'Axis.Brush.Text.Muted' `
        -Margin (New-AxisPrototypeThickness -Left 18 -Top 8 -Right 0 -Bottom 0)))
    $header.Child = $headerStack

    [System.Windows.Controls.Grid]::SetRow($header, 0)
    [System.Windows.Controls.Grid]::SetColumnSpan($header, 3)
    [void]$root.Children.Add($header)

    [System.Windows.Controls.Grid]::SetRow($contentGrid, 1)
    [void]$root.Children.Add($contentGrid)

    $navigation = New-AxisPrototypeStageNavigation -SampleState $SampleState -Resources $resources
    [System.Windows.Controls.Grid]::SetColumn($navigation, 0)
    [void]$contentGrid.Children.Add($navigation)

    $stageScreen = New-AxisPrototypeStageScreen -SampleState $SampleState -Resources $resources
    [System.Windows.Controls.Grid]::SetColumn($stageScreen, 1)
    [void]$contentGrid.Children.Add($stageScreen)

    $detailHost = [System.Windows.Controls.Border]::new()
    $detailHost.Padding = New-AxisPrototypeThickness -Left 0 -Top 26 -Right 28 -Bottom 26
    $detailHost.BorderBrush = Get-AxisPrototypeResource -Resources $resources -Name 'Axis.Brush.Border.Divider'
    $detailHost.BorderThickness = New-AxisPrototypeThickness -Left 1 -Top 0 -Right 0 -Bottom 0
    $detailHost.Child = New-AxisPrototypeToolDetailPanel `
        -Tool (Get-AxisPrototypeMapValue -Map $SampleState -Name 'SelectedTool') `
        -Resources $resources
    [System.Windows.Controls.Grid]::SetColumn($detailHost, 2)
    [void]$contentGrid.Children.Add($detailHost)

    return $root
}

function New-AxisGuidedStageWorkspacePrototypeWindow {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$SampleState = (Get-AxisPrototypeSampleState)
    )

    $window = [System.Windows.Window]::new()
    $window.Title = 'AXIS Guided setup prototype'
    $window.Width = 1280
    $window.Height = 820
    $window.MinWidth = 1180
    $window.MinHeight = 720
    $window.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterScreen
    $window.Content = New-AxisGuidedStageWorkspacePrototype -SampleState $SampleState
    return $window
}
