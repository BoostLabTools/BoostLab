Set-StrictMode -Version Latest

$script:BoostLabWindow = $null
$script:BoostLabStages = @()
$script:BoostLabStageButtons = @{}
$script:BoostLabVisibleLogText = [System.Collections.Generic.List[string]]::new()
$script:BoostLabLatestResult = $null
$script:BoostLabLatestResultToolMetadata = $null
$script:BoostLabLatestResultActionName = ''
$script:BoostLabLatestResultText = ''
$script:BoostLabToolSelectionControls = @{}
$script:BoostLabActionInProgress = $false
$script:BoostLabActionInProgressKey = ''
$script:BoostLabAsyncActionState = @{
    InProgress = $false
    Key        = ''
}

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

function ConvertTo-BoostLabDiagnosticValueText {
    param(
        [AllowNull()]
        [object]$Value,

        [int]$Depth = 0
    )

    if ($null -eq $Value) {
        return 'Not available'
    }
    if ($Value -is [string]) {
        return $(if ([string]::IsNullOrWhiteSpace($Value)) { 'Not available' } else { $Value })
    }
    if ($Value -is [datetime]) {
        return $Value.ToString('yyyy-MM-dd HH:mm:ss zzz')
    }
    if ($Value -is [ValueType]) {
        return [string]$Value
    }
    if ($Depth -ge 8) {
        return [string]$Value
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $lines = [System.Collections.Generic.List[string]]::new()
        foreach ($key in @($Value.Keys)) {
            $propertyText = ConvertTo-BoostLabDiagnosticValueText -Value $Value[$key] -Depth ($Depth + 1)
            $lines.Add(('{0}: {1}' -f [string]$key, $propertyText))
        }
        return $(if ($lines.Count -gt 0) { $lines -join [Environment]::NewLine } else { 'Not available' })
    }

    if ($Value -is [System.Collections.IEnumerable]) {
        $items = @($Value)
        if ($items.Count -eq 0) {
            return 'None'
        }

        return @(
            foreach ($item in $items) {
                $itemText = ConvertTo-BoostLabDiagnosticValueText -Value $item -Depth ($Depth + 1)
                if ($itemText.Contains([Environment]::NewLine)) {
                    "- $($itemText -replace [regex]::Escape([Environment]::NewLine), ([Environment]::NewLine + '  '))"
                }
                else {
                    "- $itemText"
                }
            }
        ) -join [Environment]::NewLine
    }

    $properties = @($Value.PSObject.Properties)
    if ($properties.Count -gt 0) {
        return @(
            foreach ($property in $properties) {
                '{0}: {1}' -f `
                    $property.Name, `
                    (ConvertTo-BoostLabDiagnosticValueText -Value $property.Value -Depth ($Depth + 1))
            }
        ) -join [Environment]::NewLine
    }

    return [string]$Value
}

function Get-BoostLabDiagnosticItems {
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$PropertyName
    )

    $value = Get-BoostLabObjectPropertyValue `
        -InputObject $InputObject `
        -PropertyName $PropertyName `
        -DefaultValue $null
    if ($null -eq $value) {
        return @()
    }

    return @($value)
}

function Format-BoostLabLatestResultText {
    param(
        [AllowNull()]
        [System.Collections.IDictionary]$ToolMetadata,

        [string]$ActionName = '',

        [AllowNull()]
        [object]$Result
    )

    $toolTitle = if (
        $null -ne $ToolMetadata -and
        $ToolMetadata.Contains('Title') -and
        -not [string]::IsNullOrWhiteSpace([string]$ToolMetadata['Title'])
    ) {
        [string]$ToolMetadata['Title']
    }
    else {
        [string](Get-BoostLabObjectPropertyValue $Result 'ToolTitle' 'Not available')
    }
    $toolId = if (
        $null -ne $ToolMetadata -and
        $ToolMetadata.Contains('Id') -and
        -not [string]::IsNullOrWhiteSpace([string]$ToolMetadata['Id'])
    ) {
        [string]$ToolMetadata['Id']
    }
    else {
        [string](Get-BoostLabObjectPropertyValue $Result 'ToolId' 'Not available')
    }
    $resolvedAction = if (-not [string]::IsNullOrWhiteSpace($ActionName)) {
        $ActionName
    }
    else {
        [string](Get-BoostLabObjectPropertyValue $Result 'Action' 'Not available')
    }
    $data = Get-BoostLabObjectPropertyValue $Result 'Data' $null
    $verification = Get-BoostLabObjectPropertyValue $Result 'VerificationResult' $null
    $actionPlan = Get-BoostLabObjectPropertyValue $Result 'ActionPlan' $null
    $overallStatus = if ($null -ne $Result) {
        Get-BoostLabResultStatus -Result $Result
    }
    else {
        'Not available'
    }
    $commandStatus = Get-BoostLabObjectPropertyValue `
        -InputObject $data `
        -PropertyName 'CommandStatus' `
        -DefaultValue (Get-BoostLabObjectPropertyValue $Result 'Status' $overallStatus)
    $verificationStatus = if ($null -ne $verification) {
        Get-BoostLabObjectPropertyValue $verification 'Status' 'Not available'
    }
    else {
        Get-BoostLabObjectPropertyValue $data 'VerificationStatus' 'Not available'
    }
    $message = Get-BoostLabObjectPropertyValue $Result 'Message' 'Not available'
    $timestamp = Get-BoostLabObjectPropertyValue `
        -InputObject $Result `
        -PropertyName 'Timestamp' `
        -DefaultValue (Get-BoostLabObjectPropertyValue $data 'CompletedAt' 'Not available')

    $builder = [System.Text.StringBuilder]::new()
    [void]$builder.AppendLine('BoostLab Latest Result')
    [void]$builder.AppendLine('======================')
    [void]$builder.AppendLine("Tool: $toolTitle")
    [void]$builder.AppendLine("Tool Id: $toolId")
    [void]$builder.AppendLine("Action: $resolvedAction")
    [void]$builder.AppendLine("Status: $overallStatus")
    [void]$builder.AppendLine("Command Status: $(ConvertTo-BoostLabDiagnosticValueText $commandStatus)")
    [void]$builder.AppendLine("Verification Status: $(ConvertTo-BoostLabDiagnosticValueText $verificationStatus)")
    [void]$builder.AppendLine("Timestamp: $(ConvertTo-BoostLabDiagnosticValueText $timestamp)")
    [void]$builder.AppendLine()
    [void]$builder.AppendLine('Message')
    [void]$builder.AppendLine('-------')
    [void]$builder.AppendLine((ConvertTo-BoostLabDiagnosticValueText $message))

    if ($null -ne $data) {
        [void]$builder.AppendLine()
        [void]$builder.AppendLine('Details')
        [void]$builder.AppendLine('-------')
        $detailProperties = @(
            $data.PSObject.Properties |
                Where-Object {
                    $_.Name -notin @(
                        'CommandStatus'
                        'VerificationStatus'
                        'Warnings'
                        'Errors'
                        'CompletedAt'
                        'Timestamp'
                    )
                }
        )
        if ($detailProperties.Count -eq 0) {
            [void]$builder.AppendLine('Not available')
        }
        else {
            foreach ($property in $detailProperties) {
                [void]$builder.AppendLine(('{0}:' -f $property.Name))
                [void]$builder.AppendLine((ConvertTo-BoostLabDiagnosticValueText $property.Value))
            }
        }
    }

    $warnings = @(
        @(Get-BoostLabDiagnosticItems $Result 'Warnings')
        @(Get-BoostLabDiagnosticItems $data 'Warnings')
    )
    [void]$builder.AppendLine()
    [void]$builder.AppendLine('Warnings')
    [void]$builder.AppendLine('--------')
    if ($warnings.Count -eq 0) {
        [void]$builder.AppendLine('None')
    }
    else {
        foreach ($warning in $warnings) {
            [void]$builder.AppendLine(('- {0}' -f (ConvertTo-BoostLabDiagnosticValueText $warning)))
        }
    }

    $errors = @(
        @(Get-BoostLabDiagnosticItems $Result 'Errors')
        @(Get-BoostLabDiagnosticItems $data 'Errors')
    )
    if ($errors.Count -eq 0 -and $overallStatus -in @('Error', 'Failed')) {
        $errors = @($message)
    }
    [void]$builder.AppendLine()
    [void]$builder.AppendLine('Errors')
    [void]$builder.AppendLine('------')
    if ($errors.Count -eq 0) {
        [void]$builder.AppendLine('None')
    }
    else {
        foreach ($errorText in $errors) {
            [void]$builder.AppendLine(('- {0}' -f (ConvertTo-BoostLabDiagnosticValueText $errorText)))
        }
    }

    [void]$builder.AppendLine()
    [void]$builder.AppendLine('Verification Checks')
    [void]$builder.AppendLine('-------------------')
    $checks = @(Get-BoostLabDiagnosticItems $verification 'Checks')
    if ($checks.Count -eq 0) {
        [void]$builder.AppendLine('Not available')
    }
    else {
        foreach ($check in $checks) {
            [void]$builder.AppendLine((
                '[{0}] {1}' -f `
                    (Get-BoostLabObjectPropertyValue $check 'Status' 'Not available'), `
                    (Get-BoostLabObjectPropertyValue $check 'Name' 'Not available')
            ))
            [void]$builder.AppendLine((
                '  Expected: {0}' -f `
                    (ConvertTo-BoostLabDiagnosticValueText (Get-BoostLabObjectPropertyValue $check 'Expected' 'Not available'))
            ))
            [void]$builder.AppendLine((
                '  Actual: {0}' -f `
                    (ConvertTo-BoostLabDiagnosticValueText (Get-BoostLabObjectPropertyValue $check 'Actual' 'Not available'))
            ))
            [void]$builder.AppendLine((
                '  Message: {0}' -f `
                    (ConvertTo-BoostLabDiagnosticValueText (Get-BoostLabObjectPropertyValue $check 'Message' 'Not available'))
            ))
        }
    }

    [void]$builder.AppendLine()
    [void]$builder.AppendLine('Action Plan')
    [void]$builder.AppendLine('-----------')
    if ($null -eq $actionPlan) {
        [void]$builder.AppendLine('Not available')
    }
    else {
        [void]$builder.AppendLine((
            'Summary: {0}' -f `
                (ConvertTo-BoostLabDiagnosticValueText (Get-BoostLabObjectPropertyValue $actionPlan 'Summary' 'Not available'))
        ))
        [void]$builder.AppendLine((
            'Risk: {0}' -f `
                (ConvertTo-BoostLabDiagnosticValueText (Get-BoostLabObjectPropertyValue $actionPlan 'RiskLevel' 'Not available'))
        ))
        [void]$builder.AppendLine('Planned Changes:')
        [void]$builder.AppendLine((ConvertTo-BoostLabDiagnosticValueText (Get-BoostLabObjectPropertyValue $actionPlan 'PlannedChanges' @())))
        [void]$builder.AppendLine('Side Effects:')
        [void]$builder.AppendLine((ConvertTo-BoostLabDiagnosticValueText (Get-BoostLabObjectPropertyValue $actionPlan 'SideEffects' @())))
        [void]$builder.AppendLine((
            'Confirmation: {0}' -f `
                (ConvertTo-BoostLabDiagnosticValueText (Get-BoostLabObjectPropertyValue $actionPlan 'ConfirmationMessage' 'Not available'))
        ))
    }

    return $builder.ToString().TrimEnd()
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

function Add-BoostLabResultBlock {
    param(
        [Parameter(Mandatory)]
        [System.Windows.Controls.Panel]$Panel,

        [Parameter(Mandatory)]
        [string]$Label,

        [AllowNull()]
        [object]$Value,

        [string]$Color = '#E2E8F0'
    )

    $container = [System.Windows.Controls.StackPanel]::new()
    $container.Margin = [System.Windows.Thickness]::new(0, 0, 0, 10)

    $labelText = [System.Windows.Controls.TextBlock]::new()
    $labelText.Margin = [System.Windows.Thickness]::new(0, 0, 0, 4)
    $labelText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#7F8DA5')
    $labelText.FontSize = 10
    $labelText.FontWeight = [System.Windows.FontWeights]::SemiBold
    $labelText.Text = "$Label`:"
    $container.Children.Add($labelText) | Out-Null

    $valueText = [System.Windows.Controls.TextBlock]::new()
    $valueText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Color)
    $valueText.FontFamily = [System.Windows.Media.FontFamily]::new('Consolas')
    $valueText.FontSize = 11
    $valueText.LineHeight = 17
    $valueText.Text = ConvertTo-BoostLabDiagnosticValueText -Value $Value
    $valueText.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $container.Children.Add($valueText) | Out-Null

    $Panel.Children.Add($container) | Out-Null
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

    $explicitStatus = [string](Get-BoostLabObjectPropertyValue `
        -InputObject $Result `
        -PropertyName 'Status' `
        -DefaultValue '')
    $success = [bool](Get-BoostLabObjectPropertyValue `
        -InputObject $Result `
        -PropertyName 'Success' `
        -DefaultValue $false)
    $message = [string](Get-BoostLabObjectPropertyValue `
        -InputObject $Result `
        -PropertyName 'Message' `
        -DefaultValue '')

    if ($explicitStatus -in @('NotImplemented', 'Not implemented')) {
        return 'Not implemented'
    }
    if ($explicitStatus -in @('NotApplicable', 'Not applicable')) {
        return 'Not applicable'
    }
    if ($explicitStatus -eq 'Warning') {
        return 'Warning'
    }
    if ($explicitStatus -in @('NeedsBranchSelection', 'SelectionRequired')) {
        return 'Warning'
    }
    if ($success -or $explicitStatus -in @('Passed', 'Success', 'Succeeded')) {
        return 'Success'
    }
    if ($message -eq 'Action not implemented yet') {
        return 'Not implemented'
    }

    return 'Error'
}

function Get-BoostLabToolActionDisplayLabel {
    param(
        [Parameter(Mandatory)]
        [object]$ToolMetadata,

        [Parameter(Mandatory)]
        [string]$ActionName
    )

    $toolId = [string]$ToolMetadata['Id']
    $sourceAlignedActionLabels = @{
        'memory-compression' = @{
            'Apply' = 'Off (Recommended)'
            'Default' = 'Enable'
        }
        'background-apps' = @{
            'Apply' = 'Off (Recommended)'
            'Default' = 'Default'
        }
        'edge-settings' = @{
            'Apply' = 'Optimize (Recommended)'
            'Default' = 'Default'
        }
        'store-settings' = @{
            'Apply' = 'Optimize (Recommended)'
            'Default' = 'Default'
        }
        'start-menu-layout' = @{
            'Apply' = '25H2 (Recommended)'
            'Default' = '24H2'
        }
        'context-menu' = @{
            'Apply' = 'Clean (Recommended)'
            'Default' = 'Default'
        }
        'theme-black' = @{
            'Apply' = 'Black (Recommended)'
            'Default' = 'Default'
        }
        'signout-lockscreen-wallpaper-black' = @{
            'Apply' = 'Black (Recommended)'
            'Default' = 'Default'
        }
        'user-account-pictures-black' = @{
            'Apply' = 'Black'
            'Default' = 'Default'
        }
        'widgets' = @{
            'Apply' = 'Off (Recommended)'
            'Default' = 'Default'
        }
        'copilot' = @{
            'Apply' = 'Off (Recommended)'
            'Default' = 'Default'
        }
        'game-bar' = @{
            'Apply' = 'Off (Recommended)'
            'Default' = 'Default'
        }
        'edge-webview' = @{
            'Apply' = 'Uninstall (Recommended)'
            'Default' = 'Default'
        }
        'notepad-settings' = @{
            'Apply' = 'On (Recommended)'
            'Default' = 'Default'
        }
        'control-panel-settings' = @{
            'Apply' = 'Optimize (Recommended)'
            'Default' = 'Default'
        }
        'device-manager-power-savings-wake' = @{
            'Apply' = 'Off (Recommended)'
            'Default' = 'Default'
        }
        'network-adapter-power-savings-wake' = @{
            'Apply' = 'Off (Recommended)'
            'Default' = 'Default'
        }
        'write-cache-buffer-flushing' = @{
            'Apply' = 'Off (Recommended)'
            'Default' = 'Default'
        }
        'power-plan' = @{
            'Apply' = 'On (Recommended)'
            'Default' = 'Default'
        }
    }
    if ($sourceAlignedActionLabels.ContainsKey($toolId)) {
        $toolActionLabels = $sourceAlignedActionLabels[$toolId]
        if ($toolActionLabels.ContainsKey($ActionName)) {
            return [string]$toolActionLabels[$ActionName]
        }
    }

    if ($toolId -eq 'driver-install-latest') {
        switch ($ActionName) {
            'Open' { return 'Open Intel Driver Page' }
            'Apply' { return 'Apply Source Workflow' }
        }
    }

    if ($toolId -eq 'driver-clean') {
        switch ($ActionName) {
            'Open' { return 'Manual' }
            'Apply' { return 'Auto' }
        }
    }

    if ($toolId -eq 'nvidia-settings') {
        switch ($ActionName) {
            'Apply' { return 'On (Recommended)' }
            'Default' { return 'Default' }
        }
    }

    if ($toolId -eq 'start-menu-taskbar') {
        switch ($ActionName) {
            'Apply' { return 'Clean (Recommended)' }
            'Default' { return 'Default' }
        }
    }

    if ($toolId -eq 'hdcp') {
        switch ($ActionName) {
            'Apply' { return 'Off (Recommended)' }
            'Default' { return 'Default' }
        }
    }

    if ($toolId -eq 'p0-state') {
        switch ($ActionName) {
            'Apply' { return 'On (Recommended)' }
            'Default' { return 'Default' }
        }
    }

    if ($toolId -eq 'msi-mode') {
        switch ($ActionName) {
            'Apply' { return 'On (Recommended)' }
            'Off' { return 'Off' }
        }
    }

    if ($toolId -eq 'directx') {
        switch ($ActionName) {
            'Apply' { return 'Install DirectX' }
        }
    }

    if ($toolId -eq 'visual-cpp') {
        switch ($ActionName) {
            'Apply' { return 'Install Visual C++' }
        }
    }

    return $ActionName
}

function New-BoostLabUiActionFailureResult {
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$ToolMetadata,

        [Parameter(Mandatory)]
        [string]$ActionName,

        [Parameter(Mandatory)]
        [string]$Message
    )

    return [pscustomobject]@{
        Success            = $false
        ToolId             = [string]$ToolMetadata['Id']
        ToolTitle          = [string]$ToolMetadata['Title']
        Action             = $ActionName
        Status             = 'Failed'
        Message            = $Message
        RestartRequired    = $false
        Cancelled          = $false
        ActionPlan         = $null
        VerificationResult = $null
        Data               = $null
        Timestamp          = Get-Date
    }
}

function New-BoostLabUiActionBusyResult {
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$ToolMetadata,

        [Parameter(Mandatory)]
        [string]$ActionName,

        [Parameter(Mandatory)]
        [string]$Message
    )

    return [pscustomobject]@{
        Success            = $false
        ToolId             = [string]$ToolMetadata['Id']
        ToolTitle          = [string]$ToolMetadata['Title']
        Action             = $ActionName
        Status             = 'Warning'
        CommandStatus      = 'Blocked before execution'
        VerificationStatus = 'NotApplicable'
        Message            = $Message
        RestartRequired    = $false
        Cancelled          = $false
        ChangesExecuted    = $false
        ActionPlan         = $null
        VerificationResult = $null
        Data               = $null
        Warnings           = @($Message)
        Errors             = @()
        Timestamp          = Get-Date
    }
}

function Complete-BoostLabToolCardAction {
    param(
        [Parameter(Mandatory)]
        [object]$Context,

        [Parameter(Mandatory)]
        [object]$Result
    )

    $toolMetadata = $Context.ToolMetadata
    $actionName = [string]$Context.ActionName

    Add-BoostLabToolActionActivityEntry `
        -ToolMetadata $toolMetadata `
        -ActionName $actionName `
        -Result $Result

    Show-BoostLabActionResult `
        -ToolMetadata $toolMetadata `
        -ActionName $actionName `
        -Result $Result

    $Context.StatusText.Text = 'Status: {0}' -f (Get-BoostLabResultStatus -Result $Result)
    $resultToolTitle = [string](Get-BoostLabObjectPropertyValue `
        -InputObject $Result `
        -PropertyName 'ToolTitle' `
        -DefaultValue ([string]$toolMetadata['Title']))
    $resultMessage = [string](Get-BoostLabObjectPropertyValue `
        -InputObject $Result `
        -PropertyName 'Message' `
        -DefaultValue 'No result message was provided.')
    (Get-BoostLabUiElement -Name 'ApplicationStatusText').Text = "${resultToolTitle}: $resultMessage"
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
    $data = Get-BoostLabObjectPropertyValue `
        -InputObject $Result `
        -PropertyName 'Data' `
        -DefaultValue $null
    $verificationResult = Get-BoostLabObjectPropertyValue `
        -InputObject $Result `
        -PropertyName 'VerificationResult' `
        -DefaultValue $null
    $panel = Get-BoostLabUiElement -Name 'LatestResultPanel'
    $panel.Children.Clear()

    (Get-BoostLabUiElement -Name 'SelectedToolNameText').Text = $toolTitle
    (Get-BoostLabUiElement -Name 'SelectedToolActionText').Text = $ActionName.ToUpperInvariant()

    $statusText = Get-BoostLabUiElement -Name 'LatestResultStatusText'
    $statusText.Text = $status.ToUpperInvariant()
    $statusText.Foreground = switch ($status) {
        'Success' { [System.Windows.Media.BrushConverter]::new().ConvertFromString('#86EFAC') }
        'Warning' { [System.Windows.Media.BrushConverter]::new().ConvertFromString('#FDE68A') }
        'Cancelled' { [System.Windows.Media.BrushConverter]::new().ConvertFromString('#FDE68A') }
        'Not implemented' { [System.Windows.Media.BrushConverter]::new().ConvertFromString('#93C5FD') }
        'Not applicable' { [System.Windows.Media.BrushConverter]::new().ConvertFromString('#93C5FD') }
        default { [System.Windows.Media.BrushConverter]::new().ConvertFromString('#FCA5A5') }
    }

    $commandStatus = Get-BoostLabObjectPropertyValue `
        -InputObject $data `
        -PropertyName 'CommandStatus' `
        -DefaultValue (Get-BoostLabObjectPropertyValue $Result 'Status' $status)
    $message = Get-BoostLabObjectPropertyValue $Result 'Message' 'Not available'
    $timestamp = Get-BoostLabObjectPropertyValue `
        -InputObject $Result `
        -PropertyName 'Timestamp' `
        -DefaultValue (Get-BoostLabObjectPropertyValue $data 'CompletedAt' 'Not available')

    Add-BoostLabResultRow -Panel $panel -Label 'Tool' -Value $toolTitle
    Add-BoostLabResultRow -Panel $panel -Label 'Tool Id' -Value $toolId
    Add-BoostLabResultRow -Panel $panel -Label 'Action' -Value $ActionName
    Add-BoostLabResultRow -Panel $panel -Label 'Command Status' -Value $commandStatus
    if ($null -ne $verificationResult) {
        Add-BoostLabResultRow `
            -Panel $panel `
            -Label 'Verification Status' `
            -Value (Get-BoostLabObjectPropertyValue $verificationResult 'Status' 'Not available')
    }
    Add-BoostLabResultBlock -Panel $panel -Label 'Message' -Value $message

    $resultWarnings = @(
        @(Get-BoostLabDiagnosticItems $Result 'Warnings')
        @(Get-BoostLabDiagnosticItems $data 'Warnings')
    )
    if ($resultWarnings.Count -gt 0) {
        Add-BoostLabResultBlock `
            -Panel $panel `
            -Label 'Warnings' `
            -Value $resultWarnings `
            -Color '#FDE68A'
    }

    $resultErrors = @(
        @(Get-BoostLabDiagnosticItems $Result 'Errors')
        @(Get-BoostLabDiagnosticItems $data 'Errors')
    )
    if ($resultErrors.Count -eq 0 -and $status -eq 'Error') {
        $resultErrors = @($message)
    }
    if ($resultErrors.Count -gt 0) {
        Add-BoostLabResultBlock `
            -Panel $panel `
            -Label 'Errors' `
            -Value $resultErrors `
            -Color '#FCA5A5'
    }
    Add-BoostLabResultRow -Panel $panel -Label 'Timestamp' -Value $timestamp

    if ($null -ne $verificationResult) {
        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Verification'
        Add-BoostLabResultRow `
            -Panel $panel `
            -Label 'Verification Status' `
            -Value (Get-BoostLabObjectPropertyValue $verificationResult 'Status' 'Not available')

        if ($toolId -eq 'widgets') {
            $detectedState = Get-BoostLabObjectPropertyValue `
                -InputObject $verificationResult `
                -PropertyName 'DetectedState' `
                -DefaultValue $null
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'PolicyManager value' `
                -Value (Get-BoostLabObjectPropertyValue $detectedState 'PolicyManagerValue')
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'Dsh policy state' `
                -Value (Get-BoostLabObjectPropertyValue $detectedState 'DshPolicyState')
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'Widgets process state' `
                -Value (Get-BoostLabObjectPropertyValue $detectedState 'WidgetsProcessState')
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'WidgetService process state' `
                -Value (Get-BoostLabObjectPropertyValue $detectedState 'WidgetServiceProcessState')
        }
        elseif ($toolId -eq 'memory-compression') {
            $expectedState = Get-BoostLabObjectPropertyValue `
                -InputObject $verificationResult `
                -PropertyName 'ExpectedState' `
                -DefaultValue $null
            $detectedState = Get-BoostLabObjectPropertyValue `
                -InputObject $verificationResult `
                -PropertyName 'DetectedState' `
                -DefaultValue $null
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'Expected MemoryCompression state' `
                -Value (Get-BoostLabObjectPropertyValue $expectedState 'MemoryCompression')
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'Detected MemoryCompression state' `
                -Value (Get-BoostLabObjectPropertyValue $detectedState 'MemoryCompression')
        }
        elseif ($toolId -eq 'background-apps') {
            $expectedState = Get-BoostLabObjectPropertyValue `
                -InputObject $verificationResult `
                -PropertyName 'ExpectedState' `
                -DefaultValue $null
            $detectedState = Get-BoostLabObjectPropertyValue `
                -InputObject $verificationResult `
                -PropertyName 'DetectedState' `
                -DefaultValue $null
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'Expected Background Apps state' `
                -Value (Get-BoostLabObjectPropertyValue $expectedState 'BackgroundApps')
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'Detected Background Apps state' `
                -Value (Get-BoostLabObjectPropertyValue $detectedState 'BackgroundApps')
        }
        elseif ($toolId -eq 'store-settings') {
            $expectedState = Get-BoostLabObjectPropertyValue `
                -InputObject $verificationResult `
                -PropertyName 'ExpectedState' `
                -DefaultValue $null
            $detectedState = Get-BoostLabObjectPropertyValue `
                -InputObject $verificationResult `
                -PropertyName 'DetectedState' `
                -DefaultValue $null
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'Expected Store Settings state' `
                -Value (Get-BoostLabObjectPropertyValue $expectedState 'StoreSettings')
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'Detected Store Settings state' `
                -Value (Get-BoostLabObjectPropertyValue $detectedState 'StoreSettings')
        }
        elseif ($toolId -eq 'updates-pause') {
            $expectedState = Get-BoostLabObjectPropertyValue `
                -InputObject $verificationResult `
                -PropertyName 'ExpectedState' `
                -DefaultValue $null
            $detectedState = Get-BoostLabObjectPropertyValue `
                -InputObject $verificationResult `
                -PropertyName 'DetectedState' `
                -DefaultValue $null
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'Expected Updates Pause state' `
                -Value (Get-BoostLabObjectPropertyValue $expectedState 'UpdatesPause')
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'Detected Updates Pause state' `
                -Value (Get-BoostLabObjectPropertyValue $detectedState 'UpdatesPause')
        }
        elseif ($toolId -eq 'theme-black') {
            $expectedState = Get-BoostLabObjectPropertyValue `
                -InputObject $verificationResult `
                -PropertyName 'ExpectedState' `
                -DefaultValue $null
            $detectedState = Get-BoostLabObjectPropertyValue `
                -InputObject $verificationResult `
                -PropertyName 'DetectedState' `
                -DefaultValue $null
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'Expected Theme state' `
                -Value (Get-BoostLabObjectPropertyValue $expectedState 'Theme')
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'Detected Theme state' `
                -Value (Get-BoostLabObjectPropertyValue $detectedState 'Theme')
        }
        elseif ($toolId -eq 'start-menu-layout') {
            $expectedState = Get-BoostLabObjectPropertyValue `
                -InputObject $verificationResult `
                -PropertyName 'ExpectedState' `
                -DefaultValue $null
            $detectedState = Get-BoostLabObjectPropertyValue `
                -InputObject $verificationResult `
                -PropertyName 'DetectedState' `
                -DefaultValue $null
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'Expected Start Menu Layout state' `
                -Value (Get-BoostLabObjectPropertyValue $expectedState 'StartMenuLayout')
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'Detected Start Menu Layout state' `
                -Value (Get-BoostLabObjectPropertyValue $detectedState 'StartMenuLayout')
        }
        elseif ($toolId -eq 'context-menu') {
            $expectedState = Get-BoostLabObjectPropertyValue `
                -InputObject $verificationResult `
                -PropertyName 'ExpectedState' `
                -DefaultValue $null
            $detectedState = Get-BoostLabObjectPropertyValue `
                -InputObject $verificationResult `
                -PropertyName 'DetectedState' `
                -DefaultValue $null
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'Expected Context Menu state' `
                -Value (Get-BoostLabObjectPropertyValue $expectedState 'ContextMenu')
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'Detected Context Menu state' `
                -Value (Get-BoostLabObjectPropertyValue $detectedState 'ContextMenu')
        }
        elseif ($toolId -eq 'signout-lockscreen-wallpaper-black') {
            $expectedState = Get-BoostLabObjectPropertyValue `
                -InputObject $verificationResult `
                -PropertyName 'ExpectedState' `
                -DefaultValue $null
            $detectedState = Get-BoostLabObjectPropertyValue `
                -InputObject $verificationResult `
                -PropertyName 'DetectedState' `
                -DefaultValue $null
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'Expected Lock Screen / Signout Wallpaper state' `
                -Value (Get-BoostLabObjectPropertyValue $expectedState 'Wallpaper')
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'Detected Lock Screen / Signout Wallpaper state' `
                -Value (Get-BoostLabObjectPropertyValue $detectedState 'Wallpaper')
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'File disposition' `
                -Value (Get-BoostLabObjectPropertyValue $detectedState 'FileDisposition')
        }
        elseif ($toolId -eq 'network-adapter-power-savings-wake') {
            $expectedState = Get-BoostLabObjectPropertyValue `
                -InputObject $verificationResult `
                -PropertyName 'ExpectedState' `
                -DefaultValue $null
            $detectedState = Get-BoostLabObjectPropertyValue `
                -InputObject $verificationResult `
                -PropertyName 'DetectedState' `
                -DefaultValue $null
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'Expected adapter power/wake state' `
                -Value (Get-BoostLabObjectPropertyValue $expectedState 'AdapterPowerWake')
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'Detected adapter power/wake state' `
                -Value (Get-BoostLabObjectPropertyValue $detectedState 'AdapterPowerWake')
        }
        elseif ($toolId -eq 'power-plan') {
            $expectedState = Get-BoostLabObjectPropertyValue `
                -InputObject $verificationResult `
                -PropertyName 'ExpectedState' `
                -DefaultValue $null
            $detectedState = Get-BoostLabObjectPropertyValue `
                -InputObject $verificationResult `
                -PropertyName 'DetectedState' `
                -DefaultValue $null
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'Expected Power Plan state' `
                -Value (Get-BoostLabObjectPropertyValue $expectedState 'PowerPlan')
            Add-BoostLabResultRow `
                -Panel $panel `
                -Label 'Detected Power Plan state' `
                -Value (Get-BoostLabObjectPropertyValue $detectedState 'PowerPlan')
        }
        else {
            foreach ($stateDefinition in @(
                [pscustomobject]@{
                    Title = 'Expected State'
                    Value = Get-BoostLabObjectPropertyValue $verificationResult 'ExpectedState' $null
                }
                [pscustomobject]@{
                    Title = 'Detected State'
                    Value = Get-BoostLabObjectPropertyValue $verificationResult 'DetectedState' $null
                }
            )) {
                Add-BoostLabResultSectionTitle -Panel $panel -Text $stateDefinition.Title
                if ($null -ne $stateDefinition.Value) {
                    foreach ($property in @($stateDefinition.Value.PSObject.Properties)) {
                        Add-BoostLabResultRow -Panel $panel -Label $property.Name -Value $property.Value
                    }
                }
            }
        }

        Add-BoostLabResultBlock `
            -Panel $panel `
            -Label 'Verification Message' `
            -Value (Get-BoostLabObjectPropertyValue $verificationResult 'Message' 'Not available')
        $verificationChecks = @(Get-BoostLabDiagnosticItems $verificationResult 'Checks')
        if ($verificationChecks.Count -gt 0) {
            Add-BoostLabResultSectionTitle -Panel $panel -Text 'Verification Checks'
            foreach ($check in $verificationChecks) {
                $checkText = '{0} [{1}] Expected: {2}; Actual: {3}. {4}' -f `
                    (Get-BoostLabObjectPropertyValue $check 'Name' 'Not available'), `
                    (Get-BoostLabObjectPropertyValue $check 'Status' 'Not available'), `
                    (ConvertTo-BoostLabDiagnosticValueText (Get-BoostLabObjectPropertyValue $check 'Expected' 'Not available')), `
                    (ConvertTo-BoostLabDiagnosticValueText (Get-BoostLabObjectPropertyValue $check 'Actual' 'Not available')), `
                    (Get-BoostLabObjectPropertyValue $check 'Message' 'Not available')
                $checkColor = switch ([string](Get-BoostLabObjectPropertyValue $check 'Status' 'Not available')) {
                    'Passed' { '#86EFAC' }
                    'Warning' { '#FDE68A' }
                    'Failed' { '#FCA5A5' }
                    default { '#AAB7CA' }
                }
                Add-BoostLabResultBullet -Panel $panel -Text $checkText -Color $checkColor
            }
        }
    }

    $actionPlan = Get-BoostLabObjectPropertyValue -InputObject $Result -PropertyName 'ActionPlan' -DefaultValue $null
    if ($null -ne $actionPlan) {
        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Action Plan'
        $riskLevel = [string](Get-BoostLabObjectPropertyValue $actionPlan 'RiskLevel' 'Not available')
        Add-BoostLabResultRow -Panel $panel -Label 'Risk' -Value $riskLevel.ToUpperInvariant()
        Add-BoostLabResultBlock `
            -Panel $panel `
            -Label 'Summary' `
            -Value (Get-BoostLabObjectPropertyValue $actionPlan 'Summary' 'Not available')
        Add-BoostLabResultRow `
            -Panel $panel `
            -Label 'Administrator' `
            -Value $(if ([bool](Get-BoostLabObjectPropertyValue $actionPlan 'RequiresAdmin' $false)) { 'Required' } else { 'Not required by this tool' })
        Add-BoostLabResultRow `
            -Panel $panel `
            -Label 'TrustedInstaller' `
            -Value $(if ([bool](Get-BoostLabObjectPropertyValue $actionPlan 'UsesTrustedInstaller' $false)) { 'Required for approved execution' } else { 'Not declared' })
        Add-BoostLabResultRow `
            -Panel $panel `
            -Label 'Confirmation' `
            -Value $(if ([bool](Get-BoostLabObjectPropertyValue $actionPlan 'NeedsExplicitConfirmation' $false)) { 'Required' } else { 'Not required' })
        Add-BoostLabResultRow `
            -Panel $panel `
            -Label 'Plan mode' `
            -Value $(if ([bool](Get-BoostLabObjectPropertyValue $actionPlan 'IsDryRun' $false)) { 'Dry run' } else { 'Execution request' })

        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Planned Changes'
        foreach ($plannedChange in @(Get-BoostLabObjectPropertyValue $actionPlan 'PlannedChanges' @())) {
            Add-BoostLabResultBullet -Panel $panel -Text ([string]$plannedChange)
        }

        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Side Effects'
        foreach ($sideEffect in @(Get-BoostLabObjectPropertyValue $actionPlan 'SideEffects' @())) {
            Add-BoostLabResultBullet -Panel $panel -Text ([string]$sideEffect) -Color '#FDE68A'
        }

        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Confirmation Message'
        Add-BoostLabResultBullet `
            -Panel $panel `
            -Text ([string](Get-BoostLabObjectPropertyValue $actionPlan 'ConfirmationMessage' 'Not available'))
    }

    if ($null -ne $data) {
        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Details'
    }

    if ($toolId -eq 'restore-point' -and $null -ne $data) {
        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Restore Point'
        Add-BoostLabResultRow -Panel $panel -Label 'Restore point name' -Value (Get-BoostLabObjectPropertyValue $data 'RestorePointName')
        Add-BoostLabResultRow -Panel $panel -Label 'Restore point type' -Value (Get-BoostLabObjectPropertyValue $data 'RestorePointType')
        Add-BoostLabResultRow -Panel $panel -Label 'Drive' -Value (Get-BoostLabObjectPropertyValue $data 'Drive')
        Add-BoostLabResultRow -Panel $panel -Label 'System Restore enabled' -Value (Get-BoostLabObjectPropertyValue $data 'SystemRestoreEnabled')
        Add-BoostLabResultRow -Panel $panel -Label 'Restore point created' -Value (Get-BoostLabObjectPropertyValue $data 'RestorePointCreated')
        Add-BoostLabResultRow -Panel $panel -Label 'Timestamp' -Value (Get-BoostLabObjectPropertyValue $data 'CreatedAt')
    }
    elseif ($toolId -eq 'widgets' -and $null -ne $data) {
        $registryChanges = @((Get-BoostLabObjectPropertyValue $data 'RegistryChangesAttempted' @())) -join [Environment]::NewLine
        $processesStopped = @((Get-BoostLabObjectPropertyValue $data 'ProcessesStopped' @()))
        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Widgets Changes'
        Add-BoostLabResultRow -Panel $panel -Label 'Registry changes attempted' -Value $registryChanges
        Add-BoostLabResultRow `
            -Panel $panel `
            -Label 'Processes stopped' `
            -Value $(if ($processesStopped.Count -gt 0) { $processesStopped -join ', ' } else { 'None (not running or not applicable)' })
        Add-BoostLabResultRow -Panel $panel -Label 'Timestamp' -Value (Get-BoostLabObjectPropertyValue $data 'CompletedAt')
    }
    elseif ($toolId -eq 'memory-compression' -and $null -ne $data) {
        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Memory Compression'
        Add-BoostLabResultRow -Panel $panel -Label 'Command Status' -Value (Get-BoostLabObjectPropertyValue $data 'CommandStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Expected state' -Value (Get-BoostLabObjectPropertyValue $data 'ExpectedMemoryCompression')
        Add-BoostLabResultRow -Panel $panel -Label 'Detected state' -Value (Get-BoostLabObjectPropertyValue $data 'DetectedMemoryCompression')
        Add-BoostLabResultRow -Panel $panel -Label 'Timestamp' -Value (Get-BoostLabObjectPropertyValue $data 'CompletedAt')
    }
    elseif ($toolId -eq 'background-apps' -and $null -ne $data) {
        $registryValuesChecked = @(
            (Get-BoostLabObjectPropertyValue $data 'RegistryValuesChecked' @())
        ) -join [Environment]::NewLine
        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Background Apps'
        Add-BoostLabResultRow -Panel $panel -Label 'Command Status' -Value (Get-BoostLabObjectPropertyValue $data 'CommandStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Expected state' -Value (Get-BoostLabObjectPropertyValue $data 'ExpectedBackgroundAppsState')
        Add-BoostLabResultRow -Panel $panel -Label 'Detected state' -Value (Get-BoostLabObjectPropertyValue $data 'DetectedBackgroundAppsState')
        Add-BoostLabResultRow -Panel $panel -Label 'Registry values checked' -Value $registryValuesChecked
        Add-BoostLabResultRow -Panel $panel -Label 'Settings page' -Value (Get-BoostLabObjectPropertyValue $data 'SettingsPageStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Timestamp' -Value (Get-BoostLabObjectPropertyValue $data 'CompletedAt')
    }
    elseif ($toolId -eq 'store-settings' -and $null -ne $data) {
        $registryValuesChecked = @(
            (Get-BoostLabObjectPropertyValue $data 'RegistryValuesChecked' @())
        ) -join [Environment]::NewLine
        $processActions = @(
            (Get-BoostLabObjectPropertyValue $data 'ProcessActions' @())
        ) -join [Environment]::NewLine
        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Store Settings'
        Add-BoostLabResultRow -Panel $panel -Label 'Command Status' -Value (Get-BoostLabObjectPropertyValue $data 'CommandStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Expected state' -Value (Get-BoostLabObjectPropertyValue $data 'ExpectedStoreSettingsState')
        Add-BoostLabResultRow -Panel $panel -Label 'Detected state' -Value (Get-BoostLabObjectPropertyValue $data 'DetectedStoreSettingsState')
        Add-BoostLabResultRow -Panel $panel -Label 'Registry values checked' -Value $registryValuesChecked
        Add-BoostLabResultRow -Panel $panel -Label 'Process actions' -Value $processActions
        Add-BoostLabResultRow -Panel $panel -Label 'Store UI actions' -Value (Get-BoostLabObjectPropertyValue $data 'StoreUiActions')
        Add-BoostLabResultRow -Panel $panel -Label 'Timestamp' -Value (Get-BoostLabObjectPropertyValue $data 'CompletedAt')
    }
    elseif ($toolId -eq 'updates-pause' -and $null -ne $data) {
        $registryValuesChecked = @(
            (Get-BoostLabObjectPropertyValue $data 'RegistryValuesChecked' @())
        ) -join [Environment]::NewLine
        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Updates Pause'
        Add-BoostLabResultRow -Panel $panel -Label 'Command Status' -Value (Get-BoostLabObjectPropertyValue $data 'CommandStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Expected state' -Value (Get-BoostLabObjectPropertyValue $data 'ExpectedUpdatesPauseState')
        Add-BoostLabResultRow -Panel $panel -Label 'Detected state' -Value (Get-BoostLabObjectPropertyValue $data 'DetectedUpdatesPauseState')
        Add-BoostLabResultRow -Panel $panel -Label 'Registry values checked' -Value $registryValuesChecked
        Add-BoostLabResultRow -Panel $panel -Label 'Settings page' -Value (Get-BoostLabObjectPropertyValue $data 'SettingsPageStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Pause start' -Value (Get-BoostLabObjectPropertyValue $data 'PauseStartTime')
        Add-BoostLabResultRow -Panel $panel -Label 'Pause expiry' -Value (Get-BoostLabObjectPropertyValue $data 'PauseExpiryTime')
        Add-BoostLabResultRow -Panel $panel -Label 'Timestamp' -Value (Get-BoostLabObjectPropertyValue $data 'CompletedAt')
    }
    elseif ($toolId -eq 'theme-black' -and $null -ne $data) {
        $registryValuesChecked = @(
            (Get-BoostLabObjectPropertyValue $data 'RegistryValuesChecked' @())
        ) -join [Environment]::NewLine
        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Theme Black'
        Add-BoostLabResultRow -Panel $panel -Label 'Command Status' -Value (Get-BoostLabObjectPropertyValue $data 'CommandStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Expected Theme state' -Value (Get-BoostLabObjectPropertyValue $data 'ExpectedThemeState')
        Add-BoostLabResultRow -Panel $panel -Label 'Detected Theme state' -Value (Get-BoostLabObjectPropertyValue $data 'DetectedThemeState')
        Add-BoostLabResultRow -Panel $panel -Label 'Registry values checked' -Value $registryValuesChecked
        Add-BoostLabResultRow -Panel $panel -Label 'Registry file' -Value (Get-BoostLabObjectPropertyValue $data 'RegistryFileStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Theme import' -Value (Get-BoostLabObjectPropertyValue $data 'ThemeImportStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'UI refresh / Settings launch' -Value (Get-BoostLabObjectPropertyValue $data 'UiRefreshStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Timestamp' -Value (Get-BoostLabObjectPropertyValue $data 'CompletedAt')
    }
    elseif ($toolId -eq 'start-menu-layout' -and $null -ne $data) {
        $registryValuesChecked = @(
            (Get-BoostLabObjectPropertyValue $data 'RegistryValuesChecked' @())
        ) -join [Environment]::NewLine
        $filePathsChecked = @(
            (Get-BoostLabObjectPropertyValue $data 'FilePathsChecked' @())
        ) -join [Environment]::NewLine
        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Start Menu Layout'
        Add-BoostLabResultRow -Panel $panel -Label 'Command Status' -Value (Get-BoostLabObjectPropertyValue $data 'CommandStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Expected Start Menu Layout state' -Value (Get-BoostLabObjectPropertyValue $data 'ExpectedStartMenuLayoutState')
        Add-BoostLabResultRow -Panel $panel -Label 'Detected Start Menu Layout state' -Value (Get-BoostLabObjectPropertyValue $data 'DetectedStartMenuLayoutState')
        Add-BoostLabResultRow -Panel $panel -Label 'Registry values checked' -Value $registryValuesChecked
        Add-BoostLabResultRow -Panel $panel -Label 'File paths checked' -Value $filePathsChecked
        Add-BoostLabResultRow -Panel $panel -Label 'Registry file' -Value (Get-BoostLabObjectPropertyValue $data 'RegistryFileStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Registry import' -Value (Get-BoostLabObjectPropertyValue $data 'RegistryImportStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'UI refresh / Settings launch' -Value (Get-BoostLabObjectPropertyValue $data 'UiRefreshStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Timestamp' -Value (Get-BoostLabObjectPropertyValue $data 'CompletedAt')
    }
    elseif ($toolId -eq 'context-menu' -and $null -ne $data) {
        $registryStatesChecked = @(
            (Get-BoostLabObjectPropertyValue $data 'RegistryStatesChecked' @())
        ) -join [Environment]::NewLine
        $operationWarnings = @(
            (Get-BoostLabObjectPropertyValue $data 'RegistryOperationWarnings' @())
        ) -join [Environment]::NewLine
        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Context Menu'
        Add-BoostLabResultRow -Panel $panel -Label 'Command Status' -Value (Get-BoostLabObjectPropertyValue $data 'CommandStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Expected Context Menu state' -Value (Get-BoostLabObjectPropertyValue $data 'ExpectedContextMenuState')
        Add-BoostLabResultRow -Panel $panel -Label 'Detected Context Menu state' -Value (Get-BoostLabObjectPropertyValue $data 'DetectedContextMenuState')
        Add-BoostLabResultRow -Panel $panel -Label 'Registry keys and values checked' -Value $registryStatesChecked
        Add-BoostLabResultRow -Panel $panel -Label 'Registry command warnings' -Value $(if ([string]::IsNullOrWhiteSpace($operationWarnings)) { 'None' } else { $operationWarnings })
        Add-BoostLabResultRow -Panel $panel -Label 'Registry file' -Value (Get-BoostLabObjectPropertyValue $data 'RegistryFileStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Registry import' -Value (Get-BoostLabObjectPropertyValue $data 'RegistryImportStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'UI / Explorer refresh' -Value (Get-BoostLabObjectPropertyValue $data 'UiRefreshStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Timestamp' -Value (Get-BoostLabObjectPropertyValue $data 'CompletedAt')
    }
    elseif ($toolId -eq 'signout-lockscreen-wallpaper-black' -and $null -ne $data) {
        $registryValuesChecked = @(
            (Get-BoostLabObjectPropertyValue $data 'RegistryValuesChecked' @())
        ) -join [Environment]::NewLine
        $filePathsChecked = @(
            (Get-BoostLabObjectPropertyValue $data 'FilePathsChecked' @())
        ) -join [Environment]::NewLine
        $warnings = @(
            (Get-BoostLabObjectPropertyValue $data 'Warnings' @())
        ) -join [Environment]::NewLine
        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Signout LockScreen Wallpaper Black'
        Add-BoostLabResultRow -Panel $panel -Label 'Command Status' -Value (Get-BoostLabObjectPropertyValue $data 'CommandStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Expected Lock Screen / Signout Wallpaper state' -Value (Get-BoostLabObjectPropertyValue $data 'ExpectedWallpaperState')
        Add-BoostLabResultRow -Panel $panel -Label 'Detected Lock Screen / Signout Wallpaper state' -Value (Get-BoostLabObjectPropertyValue $data 'DetectedWallpaperState')
        Add-BoostLabResultRow -Panel $panel -Label 'Registry values checked' -Value $registryValuesChecked
        Add-BoostLabResultRow -Panel $panel -Label 'File paths checked' -Value $filePathsChecked
        Add-BoostLabResultRow -Panel $panel -Label 'Backup / ownership status' -Value (Get-BoostLabObjectPropertyValue $data 'BackupOwnershipStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Backup path' -Value (Get-BoostLabObjectPropertyValue $data 'BackupPath')
        Add-BoostLabResultRow -Panel $panel -Label 'File disposition' -Value (Get-BoostLabObjectPropertyValue $data 'FileDisposition')
        Add-BoostLabResultRow -Panel $panel -Label 'Wallpaper refresh' -Value (Get-BoostLabObjectPropertyValue $data 'WallpaperRefreshStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Warnings' -Value $(if ([string]::IsNullOrWhiteSpace($warnings)) { 'None' } else { $warnings })
        Add-BoostLabResultRow -Panel $panel -Label 'Timestamp' -Value (Get-BoostLabObjectPropertyValue $data 'CompletedAt')
    }
    elseif ($toolId -eq 'notepad-settings' -and $null -ne $data) {
        $registryValuesChecked = @(
            (Get-BoostLabObjectPropertyValue $data 'RegistryValuesChecked' @())
        ) -join [Environment]::NewLine
        $processActions = @(
            (Get-BoostLabObjectPropertyValue $data 'ProcessActions' @())
        ) -join [Environment]::NewLine
        $hiveOperations = @(
            (Get-BoostLabObjectPropertyValue $data 'HiveOperations' @())
        ) -join [Environment]::NewLine
        $warnings = @(
            (Get-BoostLabObjectPropertyValue $data 'Warnings' @())
        ) -join [Environment]::NewLine
        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Notepad Settings'
        Add-BoostLabResultRow -Panel $panel -Label 'Command Status' -Value (Get-BoostLabObjectPropertyValue $data 'CommandStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Verification Status' -Value (Get-BoostLabObjectPropertyValue $data 'VerificationStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Expected state' -Value (Get-BoostLabObjectPropertyValue $data 'ExpectedNotepadSettingsState')
        Add-BoostLabResultRow -Panel $panel -Label 'Detected state' -Value (Get-BoostLabObjectPropertyValue $data 'DetectedNotepadSettingsState')
        Add-BoostLabResultRow -Panel $panel -Label 'settings.dat path' -Value (Get-BoostLabObjectPropertyValue $data 'SettingsDatPath')
        Add-BoostLabResultRow -Panel $panel -Label 'Notepad package directory' -Value (Get-BoostLabObjectPropertyValue $data 'NotepadPackageDirectoryPath')
        Add-BoostLabResultRow -Panel $panel -Label 'Package directory exists' -Value (Get-BoostLabObjectPropertyValue $data 'NotepadPackageDirectoryExists')
        Add-BoostLabResultRow -Panel $panel -Label 'settings.dat exists' -Value (Get-BoostLabObjectPropertyValue $data 'SettingsDatExists')
        Add-BoostLabResultRow -Panel $panel -Label 'Changes executed' -Value (Get-BoostLabObjectPropertyValue $data 'ChangesExecuted')
        Add-BoostLabResultRow -Panel $panel -Label 'Compatibility' -Value (Get-BoostLabObjectPropertyValue $data 'CompatibilityStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Compatibility detail' -Value (Get-BoostLabObjectPropertyValue $data 'CompatibilityMessage')
        Add-BoostLabResultRow -Panel $panel -Label 'Backup status' -Value (Get-BoostLabObjectPropertyValue $data 'BackupStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Backup path' -Value (Get-BoostLabObjectPropertyValue $data 'BackupPath')
        Add-BoostLabResultRow -Panel $panel -Label 'Original SHA-256' -Value (Get-BoostLabObjectPropertyValue $data 'OriginalSha256')
        Add-BoostLabResultRow -Panel $panel -Label 'Detected SHA-256' -Value (Get-BoostLabObjectPropertyValue $data 'DetectedSha256')
        Add-BoostLabResultRow -Panel $panel -Label 'Process actions' -Value $(if ([string]::IsNullOrWhiteSpace($processActions)) { 'None' } else { $processActions })
        Add-BoostLabResultRow -Panel $panel -Label 'Hive operations' -Value $(if ([string]::IsNullOrWhiteSpace($hiveOperations)) { 'None' } else { $hiveOperations })
        Add-BoostLabResultRow -Panel $panel -Label 'Registry values checked' -Value $(if ([string]::IsNullOrWhiteSpace($registryValuesChecked)) { 'None' } else { $registryValuesChecked })
        Add-BoostLabResultRow -Panel $panel -Label 'File disposition' -Value (Get-BoostLabObjectPropertyValue $data 'FileDisposition')
        Add-BoostLabResultRow -Panel $panel -Label 'Warnings' -Value $(if ([string]::IsNullOrWhiteSpace($warnings)) { 'None' } else { $warnings })
        Add-BoostLabResultRow -Panel $panel -Label 'Timestamp' -Value (Get-BoostLabObjectPropertyValue $data 'CompletedAt')
    }
    elseif ($toolId -eq 'network-adapter-power-savings-wake' -and $null -ne $data) {
        $adapterNames = @(
            (Get-BoostLabObjectPropertyValue $data 'AdapterNamesTargeted' @())
        ) -join [Environment]::NewLine
        $registryValuesChecked = @(
            (Get-BoostLabObjectPropertyValue $data 'RegistryValuesChecked' @())
        ) -join [Environment]::NewLine
        $propertiesChanged = @(
            (Get-BoostLabObjectPropertyValue $data 'PropertiesAppliedOrDefaulted' @())
        ) -join [Environment]::NewLine
        $inaccessibleTargets = @(
            (Get-BoostLabObjectPropertyValue $data 'InaccessibleAdapterTargets' @())
        ) -join [Environment]::NewLine
        $inaccessibleProperties = @(
            (Get-BoostLabObjectPropertyValue $data 'InaccessibleOrUnsupportedProperties' @())
        ) -join [Environment]::NewLine
        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Network Adapter Power Savings & Wake'
        Add-BoostLabResultRow -Panel $panel -Label 'Adapter enumeration status' -Value (Get-BoostLabObjectPropertyValue $data 'AdapterEnumerationStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Command Status' -Value (Get-BoostLabObjectPropertyValue $data 'CommandStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Verification Status' -Value (Get-BoostLabObjectPropertyValue $data 'VerificationStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Expected adapter power/wake state' -Value (Get-BoostLabObjectPropertyValue $data 'ExpectedAdapterPowerWakeState')
        Add-BoostLabResultRow -Panel $panel -Label 'Detected adapter power/wake state' -Value (Get-BoostLabObjectPropertyValue $data 'DetectedAdapterPowerWakeState')
        Add-BoostLabResultRow -Panel $panel -Label 'Adapter names targeted' -Value $(if ([string]::IsNullOrWhiteSpace($adapterNames)) { 'None found' } else { $adapterNames })
        Add-BoostLabResultRow -Panel $panel -Label 'Properties applied / defaulted' -Value $(if ([string]::IsNullOrWhiteSpace($propertiesChanged)) { 'None' } else { $propertiesChanged })
        Add-BoostLabResultRow -Panel $panel -Label 'Inaccessible adapter targets' -Value $(if ([string]::IsNullOrWhiteSpace($inaccessibleTargets)) { 'None' } else { $inaccessibleTargets })
        Add-BoostLabResultRow -Panel $panel -Label 'Inaccessible / unsupported properties' -Value $(if ([string]::IsNullOrWhiteSpace($inaccessibleProperties)) { 'None' } else { $inaccessibleProperties })
        Add-BoostLabResultRow -Panel $panel -Label 'Registry values / properties checked' -Value $(if ([string]::IsNullOrWhiteSpace($registryValuesChecked)) { 'None' } else { $registryValuesChecked })
        Add-BoostLabResultRow -Panel $panel -Label 'Timestamp' -Value (Get-BoostLabObjectPropertyValue $data 'CompletedAt')
    }
    elseif ($toolId -eq 'power-plan' -and $null -ne $data) {
        $targetedGuids = @(
            (Get-BoostLabObjectPropertyValue $data 'PowerPlanGuidsTargeted' @())
        ) -join [Environment]::NewLine
        $powerChecks = @(
            (Get-BoostLabObjectPropertyValue $data 'PowerCfgCommandsOrSettingsChecked' @())
        ) -join [Environment]::NewLine
        $registryChecks = @(
            (Get-BoostLabObjectPropertyValue $data 'RegistryValuesOrFilesChecked' @())
        ) -join [Environment]::NewLine
        $warnings = @(
            (Get-BoostLabObjectPropertyValue $data 'Warnings' @())
        ) -join [Environment]::NewLine
        Add-BoostLabResultSectionTitle -Panel $panel -Text 'Power Plan'
        Add-BoostLabResultRow -Panel $panel -Label 'Command Status' -Value (Get-BoostLabObjectPropertyValue $data 'CommandStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Verification Status' -Value (Get-BoostLabObjectPropertyValue $data 'VerificationStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Expected Power Plan state' -Value (Get-BoostLabObjectPropertyValue $data 'ExpectedPowerPlanState')
        Add-BoostLabResultRow -Panel $panel -Label 'Detected Power Plan state' -Value (Get-BoostLabObjectPropertyValue $data 'DetectedPowerPlanState')
        Add-BoostLabResultRow -Panel $panel -Label 'Power plan GUIDs targeted' -Value $(if ([string]::IsNullOrWhiteSpace($targetedGuids)) { 'None' } else { $targetedGuids })
        Add-BoostLabResultRow -Panel $panel -Label 'Powercfg commands / settings checked' -Value $(if ([string]::IsNullOrWhiteSpace($powerChecks)) { 'None' } else { $powerChecks })
        Add-BoostLabResultRow -Panel $panel -Label 'Registry values / files checked' -Value $(if ([string]::IsNullOrWhiteSpace($registryChecks)) { 'None' } else { $registryChecks })
        Add-BoostLabResultRow -Panel $panel -Label 'Power Options' -Value (Get-BoostLabObjectPropertyValue $data 'PowerOptionsStatus')
        Add-BoostLabResultRow -Panel $panel -Label 'Warnings' -Value $(if ([string]::IsNullOrWhiteSpace($warnings)) { 'None' } else { $warnings })
        Add-BoostLabResultRow -Panel $panel -Label 'Timestamp' -Value (Get-BoostLabObjectPropertyValue $data 'CompletedAt')
    }
    elseif ($toolId -eq 'bios-information' -and $ActionName -eq 'Analyze' -and $null -ne $data) {
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

    $script:BoostLabLatestResult = $Result
    $script:BoostLabLatestResultToolMetadata = $ToolMetadata
    $script:BoostLabLatestResultActionName = $ActionName
    try {
        $script:BoostLabLatestResultText = Format-BoostLabLatestResultText `
            -ToolMetadata $ToolMetadata `
            -ActionName $ActionName `
            -Result $Result
    }
    catch {
        $script:BoostLabLatestResultText = @(
            'BoostLab Latest Result'
            "Tool: $toolTitle"
            "Tool Id: $toolId"
            "Action: $ActionName"
            "Status: $status"
            "Message: $(ConvertTo-BoostLabDiagnosticValueText $message)"
            "Formatting Error: $($_.Exception.Message)"
            "Timestamp: $(ConvertTo-BoostLabDiagnosticValueText $timestamp)"
        ) -join [Environment]::NewLine
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
    $verificationResult = Get-BoostLabObjectPropertyValue `
        -InputObject $Result `
        -PropertyName 'VerificationResult' `
        -DefaultValue $null
    $verificationStatus = if ($null -ne $verificationResult) {
        [string](Get-BoostLabObjectPropertyValue $verificationResult 'Status' '')
    }
    else {
        ''
    }
    $resultSuccess = [bool](Get-BoostLabObjectPropertyValue $Result 'Success' $false)
    $resultMessage = [string](Get-BoostLabObjectPropertyValue $Result 'Message' 'Not available')
    $level = if ($status -eq 'Success' -and $verificationStatus -eq 'Warning') {
        'Warning'
    }
    elseif ($status -eq 'Success' -and $verificationStatus -eq 'Failed') {
        'Error'
    }
    else {
        switch ($status) {
        'Success' { 'Success' }
        'Warning' { 'Warning' }
        'Not implemented' { 'Info' }
        'Not applicable' { 'Info' }
        'Cancelled' { 'Info' }
        default { 'Error' }
        }
    }
    $message = if (
        [string]$ToolMetadata['Id'] -eq 'bios-information' -and
        $ActionName -eq 'Analyze' -and
        $resultSuccess
    ) {
        'Hardware and BIOS information detected.'
    }
    elseif ($verificationStatus -in @('Warning', 'Failed')) {
        '{0} Verification {1}: {2}' -f `
            $resultMessage, `
            $verificationStatus.ToLowerInvariant(), `
            [string](Get-BoostLabObjectPropertyValue $verificationResult 'Message' 'Not available')
    }
    else {
        $resultMessage
    }

    Add-BoostLabActivityEntry -Entry ([pscustomobject]@{
        Timestamp = Get-Date
        Level     = $level
        Source    = [string]$ToolMetadata['Title']
        EventId   = $ActionName
        Message   = $message
    })
}

function Get-BoostLabToolCardActionOptions {
    param(
        [Parameter(Mandatory)]
        [object]$Context
    )

    $options = @{}
    $toolMetadata = $Context.ToolMetadata
    $actionName = [string]$Context.ActionName
    $toolId = [string]$toolMetadata['Id']
    $selectionMode = if (
        $toolMetadata -is [System.Collections.IDictionary] -and
        $toolMetadata.Contains('SelectionMode')
    ) {
        [string]$toolMetadata['SelectionMode']
    }
    else {
        ''
    }
    $selectionRequiredActions = if (
        $toolMetadata -is [System.Collections.IDictionary] -and
        $toolMetadata.Contains('SelectionRequiredActions')
    ) {
        @($toolMetadata['SelectionRequiredActions'])
    }
    else {
        @()
    }

    if ($selectionMode -eq 'MultiSelect' -and $actionName -in $selectionRequiredActions) {
        $selectedIds = @()
        if ($script:BoostLabToolSelectionControls.ContainsKey($toolId)) {
            $selectedIds = @(
                $script:BoostLabToolSelectionControls[$toolId] |
                    Where-Object { [bool]$_.IsChecked } |
                    ForEach-Object { [string]$_.Tag }
            )
        }
        $options['SelectedAppIds'] = @($selectedIds)
    }
    elseif ($selectionMode -eq 'SingleSelect' -and $actionName -in $selectionRequiredActions) {
        $selectedIds = @()
        if ($script:BoostLabToolSelectionControls.ContainsKey($toolId)) {
            $selectedIds = @(
                $script:BoostLabToolSelectionControls[$toolId] |
                    Where-Object { [bool]$_.IsChecked } |
                    ForEach-Object { [string]$_.Tag }
            )
        }
        $options['Branch'] = if ($selectedIds.Count -eq 1) {
            [string]$selectedIds[0]
        }
        else {
            ''
        }
    }

    return $options
}

function Invoke-BoostLabToolCardAction {
    param(
        [Parameter(Mandatory)]
        [object]$Context,

        [scriptblock]$ActionInvoker = {
            param($ToolMetadata, $ActionName, $ActionOptions)

            Invoke-BoostLabToolAction `
                -ToolMetadata $ToolMetadata `
                -ActionName $ActionName `
                -ActionOptions $ActionOptions `
                -ConfirmationCallback {
                    param($ActionPlan)
                    Show-BoostLabActionPlanConfirmation -ActionPlan $ActionPlan
                }
        }
    )

    $toolMetadata = $Context.ToolMetadata
    $actionName = [string]$Context.ActionName
    $actionOptions = Get-BoostLabToolCardActionOptions -Context $Context
    (Get-BoostLabUiElement -Name 'SelectedToolNameText').Text = [string]$toolMetadata['Title']
    (Get-BoostLabUiElement -Name 'SelectedToolActionText').Text = $actionName.ToUpperInvariant()

    try {
        $result = & $ActionInvoker $toolMetadata $actionName $actionOptions
        if ($null -eq $result) {
            throw 'Tool execution returned no result.'
        }
    }
    catch {
        $message = "Tool execution failed: $($_.Exception.Message)"
        $result = New-BoostLabUiActionFailureResult `
            -ToolMetadata $toolMetadata `
            -ActionName $actionName `
            -Message $message

        try {
            if (Get-Command -Name 'Write-BoostLabError' -ErrorAction SilentlyContinue) {
                Write-BoostLabError `
                    -Message ('[{0}] [{1}] {2}' -f [string]$toolMetadata['Title'], $actionName, $message) `
                    -Source 'UI' `
                    -EventId 'ToolAction.UiRuntimeFailed' `
                    -Data @{
                        ToolId = [string]$toolMetadata['Id']
                        Error  = $_.Exception.Message
                    } | Out-Null
            }
        }
        catch {
            # The visible Activity Log below remains the final reporting path.
        }
    }

    Complete-BoostLabToolCardAction -Context $Context -Result $result

    return $result
}

function Test-BoostLabToolUsesAsyncUiDispatch {
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$ToolMetadata
    )

    $toolId = [string]$ToolMetadata['Id']
    return $toolId -in @(
        'bios-information'
        'bios-settings'
        'reinstall'
        'unattended'
        'updates-drivers-block'
        'to-bios'
        'bitlocker'
        'memory-compression'
        'date-language-region-time'
        'startup-apps-settings'
        'startup-apps-task-manager'
        'background-apps'
        'edge-settings'
        'store-settings'
        'updates-pause'
        'installers'
        'driver-clean'
        'driver-install-debloat-settings'
        'driver-install-latest'
        'nvidia-settings'
        'hdcp'
        'p0-state'
        'msi-mode'
        'directx'
        'visual-cpp'
    )
}

function Add-BoostLabAsyncDiagnosticsToResult {
    param(
        [Parameter(Mandatory)]
        [object]$Result,

        [AllowNull()]
        [object]$Diagnostics
    )

    if ($null -eq $Diagnostics) {
        return $Result
    }

    $hasDiagnostics = $false
    foreach ($propertyName in @('Output', 'Error', 'Warning', 'Progress', 'Verbose', 'Debug', 'Information')) {
        $property = $Diagnostics.PSObject.Properties[$propertyName]
        if ($null -ne $property -and @($property.Value).Count -gt 0) {
            $hasDiagnostics = $true
            break
        }
    }
    if (-not $hasDiagnostics) {
        return $Result
    }

    if ($null -eq $Result.PSObject.Properties['Data'] -or $null -eq $Result.Data) {
        $Result | Add-Member -NotePropertyName 'Data' -NotePropertyValue ([pscustomobject]@{}) -Force
    }

    $Result.Data | Add-Member -NotePropertyName 'AsyncDiagnostics' -NotePropertyValue $Diagnostics -Force
    return $Result
}

function Get-BoostLabAsyncExceptionDiagnosticMessage {
    param(
        [Parameter(Mandatory)]
        [string]$Prefix,

        [Parameter(Mandatory)]
        [System.Exception]$Exception
    )

    $parts = [System.Collections.Generic.List[string]]::new()
    $parts.Add(('{0}: {1}' -f $Prefix, [string]$Exception.Message))

    $innerException = $Exception.InnerException
    while ($null -ne $innerException) {
        $parts.Add(('Inner exception: {0}' -f [string]$innerException.Message))
        $innerException = $innerException.InnerException
    }

    $errorRecord = $null
    if ($null -ne $Exception.PSObject.Properties['ErrorRecord']) {
        $errorRecord = $Exception.ErrorRecord
    }
    elseif ($null -ne $Exception.InnerException -and $null -ne $Exception.InnerException.PSObject.Properties['ErrorRecord']) {
        $errorRecord = $Exception.InnerException.ErrorRecord
    }

    if ($null -ne $errorRecord) {
        if (-not [string]::IsNullOrWhiteSpace([string]$errorRecord.ScriptStackTrace)) {
            $parts.Add(('Script stack: {0}' -f [string]$errorRecord.ScriptStackTrace))
        }
        if (
            $null -ne $errorRecord.InvocationInfo -and
            -not [string]::IsNullOrWhiteSpace([string]$errorRecord.InvocationInfo.PositionMessage)
        ) {
            $parts.Add(('Invocation: {0}' -f [string]$errorRecord.InvocationInfo.PositionMessage))
        }
    }

    return ($parts -join ' | ')
}

function New-BoostLabAsyncRuntimeFailureResult {
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$ToolMetadata,

        [Parameter(Mandatory)]
        [string]$ActionName,

        [Parameter(Mandatory)]
        [string]$Message,

        [AllowNull()]
        [object]$Diagnostics = $null
    )

    $result = New-BoostLabUiActionFailureResult `
        -ToolMetadata $ToolMetadata `
        -ActionName $ActionName `
        -Message $Message
    $result | Add-Member -NotePropertyName 'CommandStatus' -NotePropertyValue 'Completed with errors' -Force
    $result | Add-Member -NotePropertyName 'VerificationStatus' -NotePropertyValue 'Failed' -Force
    $result | Add-Member -NotePropertyName 'Errors' -NotePropertyValue @($Message) -Force
    $result | Add-Member -NotePropertyName 'Warnings' -NotePropertyValue @() -Force
    return Add-BoostLabAsyncDiagnosticsToResult -Result $result -Diagnostics $Diagnostics
}

function Get-BoostLabAsyncStreamDiagnostics {
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.PowerShell]$PowerShell,

        [AllowNull()]
        [object[]]$Output = @()
    )

    return [pscustomobject]@{
        Output      = @($Output | ForEach-Object { ConvertTo-BoostLabDiagnosticValueText $_ })
        Error       = @($PowerShell.Streams.Error | ForEach-Object { [string]$_ })
        Warning     = @($PowerShell.Streams.Warning | ForEach-Object { [string]$_ })
        Progress    = @($PowerShell.Streams.Progress | ForEach-Object {
            '{0} {1} {2}%' -f $_.Activity, $_.StatusDescription, $_.PercentComplete
        })
        Verbose     = @($PowerShell.Streams.Verbose | ForEach-Object { [string]$_ })
        Debug       = @($PowerShell.Streams.Debug | ForEach-Object { [string]$_ })
        Information = @($PowerShell.Streams.Information | ForEach-Object { [string]$_.MessageData })
    }
}

function Invoke-BoostLabToolCardActionAsync {
    param(
        [Parameter(Mandatory)]
        [object]$Context
    )

    $toolMetadata = $Context.ToolMetadata
    $actionName = [string]$Context.ActionName
    $toolId = [string]$toolMetadata['Id']
    $actionKey = '{0}:{1}' -f $toolId, $actionName
    $asyncActionState = $script:BoostLabAsyncActionState

    if (-not (Test-BoostLabToolUsesAsyncUiDispatch -ToolMetadata $toolMetadata)) {
        Invoke-BoostLabToolCardAction -Context $Context | Out-Null
        return
    }

    if ([bool]$asyncActionState['InProgress']) {
        $runningActionKey = [string]$asyncActionState['Key']
        if ([string]::IsNullOrWhiteSpace($runningActionKey)) {
            $runningActionKey = [string]$script:BoostLabActionInProgressKey
        }
        $busyResult = New-BoostLabUiActionBusyResult `
            -ToolMetadata $toolMetadata `
            -ActionName $actionName `
            -Message ("Another BoostLab action is already running: {0}. Wait for it to finish before starting {1}." -f $runningActionKey, $actionKey)
        Complete-BoostLabToolCardAction -Context $Context -Result $busyResult
        return
    }

    $actionOptions = Get-BoostLabToolCardActionOptions -Context $Context
    (Get-BoostLabUiElement -Name 'SelectedToolNameText').Text = [string]$toolMetadata['Title']
    (Get-BoostLabUiElement -Name 'SelectedToolActionText').Text = $actionName.ToUpperInvariant()

    try {
        $actionPlan = New-BoostLabActionPlan `
            -ToolMetadata $toolMetadata `
            -ActionName $actionName `
            -IsDryRun:$false
    }
    catch {
        $failureResult = New-BoostLabUiActionFailureResult `
            -ToolMetadata $toolMetadata `
            -ActionName $actionName `
            -Message "Tool action planning failed: $($_.Exception.Message)"
        Complete-BoostLabToolCardAction -Context $Context -Result $failureResult
        return
    }

    if ([bool]$actionPlan.NeedsExplicitConfirmation -and $actionName -ne 'Analyze') {
        $confirmed = $false
        try {
            $confirmed = Show-BoostLabActionPlanConfirmation -ActionPlan $actionPlan
        }
        catch {
            $failureResult = New-BoostLabUiActionFailureResult `
                -ToolMetadata $toolMetadata `
                -ActionName $actionName `
                -Message "Tool action confirmation failed: $($_.Exception.Message)"
            $failureResult | Add-Member -NotePropertyName 'ActionPlan' -NotePropertyValue $actionPlan -Force
            Complete-BoostLabToolCardAction -Context $Context -Result $failureResult
            return
        }

        if (-not $confirmed) {
            $cancelledResult = [pscustomobject]@{
                Success         = $false
                ToolId          = [string]$toolMetadata['Id']
                ToolTitle       = [string]$toolMetadata['Title']
                Action          = $actionName
                Status          = 'Cancelled'
                CommandStatus   = 'Cancelled before execution'
                Message         = 'Cancelled by user'
                RestartRequired = $false
                Cancelled       = $true
                ChangesExecuted = $false
                ActionPlan      = $actionPlan
                Timestamp       = Get-Date
            }
            Complete-BoostLabToolCardAction -Context $Context -Result $cancelledResult
            return
        }
    }

    $asyncActionState['InProgress'] = $true
    $asyncActionState['Key'] = $actionKey
    $script:BoostLabActionInProgress = $true
    $script:BoostLabActionInProgressKey = $actionKey
    $Context.StatusText.Text = 'Status: Running...'
    (Get-BoostLabUiElement -Name 'ApplicationStatusText').Text = ('Running {0}: {1}...' -f [string]$toolMetadata['Title'], $actionName)
    if ($null -ne $Context.PSObject.Properties['ActionButton'] -and $null -ne $Context.ActionButton) {
        $Context.ActionButton.IsEnabled = $false
        $Context.ActionButton.Content = 'Running...'
    }

    $projectRoot = Split-Path -Parent $PSScriptRoot
    $workerScript = {
        param(
            [Parameter(Mandatory)]
            [string]$ProjectRoot,

            [Parameter(Mandatory)]
            [System.Collections.IDictionary]$ToolMetadata,

            [Parameter(Mandatory)]
            [string]$ActionName,

            [AllowNull()]
            [hashtable]$ActionOptions = @{}
        )

        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'

        if ($null -eq $ActionOptions) {
            $ActionOptions = @{}
        }
        else {
            $normalizedActionOptions = @{}
            foreach ($optionName in @($ActionOptions.Keys)) {
                $optionValue = $ActionOptions[$optionName]
                if ($null -eq $optionValue) {
                    $normalizedActionOptions[[string]$optionName] = $null
                }
                elseif ($optionValue -is [array]) {
                    $normalizedActionOptions[[string]$optionName] = @($optionValue)
                }
                else {
                    $normalizedActionOptions[[string]$optionName] = $optionValue
                }
            }
            $ActionOptions = $normalizedActionOptions
        }

        foreach ($relativeModulePath in @(
            'core\Environment.psm1'
            'core\Logging.psm1'
            'core\ActionPlan.psm1'
            'core\Safety.psm1'
            'core\State.psm1'
            'core\Verification.psm1'
            'core\Execution.psm1'
        )) {
            $modulePath = Join-Path $ProjectRoot $relativeModulePath
            if (Test-Path -LiteralPath $modulePath -PathType Leaf) {
                Import-Module -Name $modulePath -Force -ErrorAction Stop
            }
        }

        if (Get-Command -Name 'Initialize-BoostLabLogging' -ErrorAction SilentlyContinue) {
            Initialize-BoostLabLogging | Out-Null
        }
        if (Get-Command -Name 'Initialize-BoostLabState' -ErrorAction SilentlyContinue) {
            Initialize-BoostLabState | Out-Null
        }

        Invoke-BoostLabToolAction `
            -ToolMetadata $ToolMetadata `
            -ActionName $ActionName `
            -ActionOptions $ActionOptions `
            -RiskConfirmed
    }

    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.ApartmentState = [System.Threading.ApartmentState]::STA
    $runspace.ThreadOptions = [System.Management.Automation.Runspaces.PSThreadOptions]::ReuseThread
    $runspace.Open()

    $powerShell = [powershell]::Create()
    $powerShell.Runspace = $runspace
    [void]$powerShell.AddScript($workerScript)
    [void]$powerShell.AddArgument($projectRoot)
    [void]$powerShell.AddArgument($toolMetadata)
    [void]$powerShell.AddArgument($actionName)
    [void]$powerShell.AddArgument($actionOptions)

    try {
        $asyncResult = $powerShell.BeginInvoke()
    }
    catch {
        $asyncActionState['InProgress'] = $false
        $asyncActionState['Key'] = ''
        $script:BoostLabActionInProgress = $false
        $script:BoostLabActionInProgressKey = ''
        if ($null -ne $Context.PSObject.Properties['ActionButton'] -and $null -ne $Context.ActionButton) {
            $Context.ActionButton.IsEnabled = $true
            $Context.ActionButton.Content = [string]$Context.ActionLabel
        }
        $powerShell.Dispose()
        $runspace.Dispose()
        $failureResult = New-BoostLabUiActionFailureResult `
            -ToolMetadata $toolMetadata `
            -ActionName $actionName `
            -Message "Tool background launch failed: $($_.Exception.Message)"
        $failureResult | Add-Member -NotePropertyName 'ActionPlan' -NotePropertyValue $actionPlan -Force
        Complete-BoostLabToolCardAction -Context $Context -Result $failureResult
        return
    }

    $getDiagnosticsCommand = ${function:Get-BoostLabAsyncStreamDiagnostics}
    $getExceptionMessageCommand = ${function:Get-BoostLabAsyncExceptionDiagnosticMessage}
    $newFailureResultCommand = ${function:New-BoostLabAsyncRuntimeFailureResult}
    $addDiagnosticsCommand = ${function:Add-BoostLabAsyncDiagnosticsToResult}
    $completeActionCommand = ${function:Complete-BoostLabToolCardAction}
    $newMinimalFailureResultCommand = {
        param(
            [Parameter(Mandatory)]
            [System.Collections.IDictionary]$ToolMetadata,

            [Parameter(Mandatory)]
            [string]$ActionName,

            [Parameter(Mandatory)]
            [string]$Message,

            [AllowNull()]
            [object]$Diagnostics = $null
        )

        $data = [pscustomobject]@{}
        if ($null -ne $Diagnostics) {
            $data | Add-Member -NotePropertyName 'AsyncDiagnostics' -NotePropertyValue $Diagnostics -Force
        }

        return [pscustomobject]@{
            Success            = $false
            ToolId             = [string]$ToolMetadata['Id']
            ToolTitle          = [string]$ToolMetadata['Title']
            Action             = $ActionName
            Status             = 'Error'
            CommandStatus      = 'Completed with errors'
            VerificationStatus = 'Failed'
            Message            = $Message
            RestartRequired    = $false
            Cancelled          = $false
            ChangesExecuted    = $false
            ActionPlan         = $null
            VerificationResult = $null
            Data               = $data
            Warnings           = @()
            Errors             = @($Message)
            Timestamp          = Get-Date
        }
    }.GetNewClosure()

    $timer = [System.Windows.Threading.DispatcherTimer]::new()
    $timer.Interval = [TimeSpan]::FromMilliseconds(250)
    $timer.Add_Tick(({
        if (-not $asyncResult.IsCompleted) {
            return
        }

        $timer.Stop()
        $output = @()
        $result = $null
        $diagnostics = $null
        $completionError = $null
        try {
            try {
                $output = @($powerShell.EndInvoke($asyncResult))
            }
            catch {
                $completionError = $_.Exception
            }

            try {
                $diagnostics = & $getDiagnosticsCommand -PowerShell $powerShell -Output $output
            }
            catch {
                $diagnostics = [pscustomobject]@{
                    Output      = @($output | ForEach-Object { [string]$_ })
                    Error       = @("Async diagnostics collection failed: $($_.Exception.Message)")
                    Warning     = @()
                    Progress    = @()
                    Verbose     = @()
                    Debug       = @()
                    Information = @()
                }
            }

            if ($null -ne $completionError) {
                $completionMessage = & $getExceptionMessageCommand `
                    -Prefix 'Tool background execution failed' `
                    -Exception $completionError
                try {
                    $result = & $newFailureResultCommand `
                        -ToolMetadata $toolMetadata `
                        -ActionName $actionName `
                        -Message $completionMessage `
                        -Diagnostics $diagnostics
                }
                catch {
                    $result = & $newMinimalFailureResultCommand `
                        -ToolMetadata $toolMetadata `
                        -ActionName $actionName `
                        -Message $completionMessage `
                        -Diagnostics $diagnostics
                }
            }
            elseif ($output.Count -gt 0) {
                $result = $output[$output.Count - 1]
            }
            else {
                try {
                    $result = & $newFailureResultCommand `
                        -ToolMetadata $toolMetadata `
                        -ActionName $actionName `
                        -Message 'Tool background execution returned no result.' `
                        -Diagnostics $diagnostics
                }
                catch {
                    $result = & $newMinimalFailureResultCommand `
                        -ToolMetadata $toolMetadata `
                        -ActionName $actionName `
                        -Message 'Tool background execution returned no result.' `
                        -Diagnostics $diagnostics
                }
            }
        }
        catch {
            $completionMessage = & $getExceptionMessageCommand `
                -Prefix 'Tool async completion failed' `
                -Exception $_.Exception
            try {
                $result = & $newFailureResultCommand `
                    -ToolMetadata $toolMetadata `
                    -ActionName $actionName `
                    -Message $completionMessage `
                    -Diagnostics $diagnostics
            }
            catch {
                $result = & $newMinimalFailureResultCommand `
                    -ToolMetadata $toolMetadata `
                    -ActionName $actionName `
                    -Message $completionMessage `
                    -Diagnostics $diagnostics
            }
        }
        finally {
            try {
                $powerShell.Dispose()
            }
            catch {
            }
            try {
                $runspace.Dispose()
            }
            catch {
            }
            $asyncActionState['InProgress'] = $false
            $asyncActionState['Key'] = ''
            $script:BoostLabActionInProgress = $false
            $script:BoostLabActionInProgressKey = ''
            if ($null -ne $Context.PSObject.Properties['ActionButton'] -and $null -ne $Context.ActionButton) {
                $Context.ActionButton.IsEnabled = $true
                $Context.ActionButton.Content = [string]$Context.ActionLabel
            }
        }

        if ($null -eq $result) {
            try {
                $result = & $newFailureResultCommand `
                    -ToolMetadata $toolMetadata `
                    -ActionName $actionName `
                    -Message 'Tool background execution returned no result.' `
                    -Diagnostics $diagnostics
            }
            catch {
                $result = & $newMinimalFailureResultCommand `
                    -ToolMetadata $toolMetadata `
                    -ActionName $actionName `
                    -Message 'Tool background execution returned no result.' `
                    -Diagnostics $diagnostics
            }
        }
        elseif ($null -ne $diagnostics) {
            try {
                $result = & $addDiagnosticsCommand -Result $result -Diagnostics $diagnostics
            }
            catch {
            }
        }

        try {
            & $completeActionCommand -Context $Context -Result $result
        }
        catch {
            try {
                $Context.StatusText.Text = 'Status: Error'
                (Get-BoostLabUiElement -Name 'ApplicationStatusText').Text = "Tool result rendering failed: $($_.Exception.Message)"
            }
            catch {
            }
        }
    }).GetNewClosure())
    $timer.Start()
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

function Copy-BoostLabLatestResult {
    if ([string]::IsNullOrWhiteSpace($script:BoostLabLatestResultText)) {
        (Get-BoostLabUiElement -Name 'ApplicationStatusText').Text = 'Latest result is empty'
        return
    }

    try {
        [System.Windows.Clipboard]::SetText($script:BoostLabLatestResultText)
        (Get-BoostLabUiElement -Name 'ApplicationStatusText').Text = 'Latest result copied'
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
    Add-BoostLabResultRow `
        -Panel $content `
        -Label 'Administrator' `
        -Value $(if ([bool]$ActionPlan.RequiresAdmin) { 'Required' } else { 'Not required by this tool' })
    Add-BoostLabResultRow `
        -Panel $content `
        -Label 'TrustedInstaller' `
        -Value $(if ([bool]$ActionPlan.UsesTrustedInstaller) { 'Required for approved execution' } else { 'Not declared' })

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
    if ($Tool.Contains('SelectionMode') -and [string]$Tool['SelectionMode'] -eq 'MultiSelect') {
        $card.Height = 458
    }
    elseif ($Tool.Contains('SelectionMode') -and [string]$Tool['SelectionMode'] -eq 'SingleSelect') {
        $card.Height = 372
    }
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

    $contentPanel = [System.Windows.Controls.StackPanel]::new()
    $contentPanel.Margin = [System.Windows.Thickness]::new(0, 12, 0, 8)
    $contentPanel.VerticalAlignment = [System.Windows.VerticalAlignment]::Top

    $description = [System.Windows.Controls.TextBlock]::new()
    $description.Text = [string]$Tool['Description']
    $description.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#9EABC2')
    $description.FontSize = 12
    $description.LineHeight = 18
    $description.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $description.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
    $contentPanel.Children.Add($description) | Out-Null

    $selectionMode = if ($Tool.Contains('SelectionMode')) {
        [string]$Tool['SelectionMode']
    }
    else {
        ''
    }
    if ($selectionMode -in @('MultiSelect', 'SingleSelect') -and $Tool.Contains('SelectionItems')) {
        $selectionLabel = [System.Windows.Controls.TextBlock]::new()
        $selectionLabel.Margin = [System.Windows.Thickness]::new(0, 10, 0, 5)
        $selectionLabel.Text = if ($Tool.Contains('SelectionLabel')) {
            [string]$Tool['SelectionLabel']
        }
        elseif ($selectionMode -eq 'SingleSelect') {
            'Select one option'
        }
        else {
            'Select apps for Apply'
        }
        $selectionLabel.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#E0E7FF')
        $selectionLabel.FontSize = 11
        $selectionLabel.FontWeight = [System.Windows.FontWeights]::SemiBold
        $contentPanel.Children.Add($selectionLabel) | Out-Null

        $selectionScroll = [System.Windows.Controls.ScrollViewer]::new()
        $selectionScroll.MaxHeight = if ($selectionMode -eq 'SingleSelect') { 96 } else { 172 }
        $selectionScroll.VerticalScrollBarVisibility = [System.Windows.Controls.ScrollBarVisibility]::Auto
        $selectionScroll.HorizontalScrollBarVisibility = [System.Windows.Controls.ScrollBarVisibility]::Disabled

        $selectionPanel = [System.Windows.Controls.StackPanel]::new()
        $script:BoostLabToolSelectionControls[$toolId] = @()
        foreach ($selectionItem in @($Tool['SelectionItems'])) {
            if ($selectionMode -eq 'SingleSelect') {
                $selectionControl = [System.Windows.Controls.RadioButton]::new()
                $selectionControl.GroupName = "BoostLab_$($toolId)_Selection"
            }
            else {
                $selectionControl = [System.Windows.Controls.CheckBox]::new()
            }
            $selectionControl.Content = ('{0}. {1}' -f [int]$selectionItem['SourceMenuNumber'], [string]$selectionItem['Title'])
            $selectionControl.Tag = [string]$selectionItem['Id']
            $selectionControl.Margin = [System.Windows.Thickness]::new(0, 1, 0, 1)
            $selectionControl.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#CBD5E1')
            $selectionControl.FontSize = 11
            $selectionPanel.Children.Add($selectionControl) | Out-Null
            $script:BoostLabToolSelectionControls[$toolId] = @($script:BoostLabToolSelectionControls[$toolId]) + @($selectionControl)
        }
        $selectionScroll.Content = $selectionPanel
        $contentPanel.Children.Add($selectionScroll) | Out-Null
    }

    [System.Windows.Controls.Grid]::SetRow($contentPanel, 2)
    $layout.Children.Add($contentPanel) | Out-Null

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
        $actionName = [string]$actionName
        $actionDisplayLabel = Get-BoostLabToolActionDisplayLabel -ToolMetadata $Tool -ActionName $actionName
        $actionButton = [System.Windows.Controls.Button]::new()
        $actionButton.Content = $actionDisplayLabel
        if ($toolId -eq 'driver-install-latest' -and $actionName -eq 'Open') {
            $actionButton.ToolTip = 'Only the INTEL branch has a source-defined standalone Open page. NVIDIA and AMD run through Apply Source Workflow.'
        }
        elseif ($toolId -eq 'driver-install-debloat-settings' -and $actionName -in @('Open', 'Apply')) {
            $actionButton.ToolTip = 'Select exactly one GPU branch: NVIDIA, AMD, or INTEL. No branch is selected automatically.'
        }
        $actionButton.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
        $actionButton.Margin = [System.Windows.Thickness]::new(0, 0, 7, 0)
        $actionButton.Tag = [pscustomobject]@{
            ToolMetadata = $Tool
            ActionName   = $actionName
            ActionLabel  = $actionDisplayLabel
            StatusText   = $status
            ActionButton = $actionButton
        }
        $actionButton.Style = $script:BoostLabWindow.FindResource('ActionButtonStyle')
        $actionButton.Add_Click({
            $context = $this.Tag
            try {
                Invoke-BoostLabToolCardActionAsync -Context $context | Out-Null
            }
            catch {
                $message = "Tool result presentation failed: $($_.Exception.Message)"
                $fallbackResult = New-BoostLabUiActionFailureResult `
                    -ToolMetadata $context.ToolMetadata `
                    -ActionName $context.ActionName `
                    -Message $message

                try {
                    Add-BoostLabToolActionActivityEntry `
                        -ToolMetadata $context.ToolMetadata `
                        -ActionName $context.ActionName `
                        -Result $fallbackResult
                }
                catch {
                    # Never allow a secondary Activity Log failure to escape the WPF event.
                }
                try {
                    Show-BoostLabActionResult `
                        -ToolMetadata $context.ToolMetadata `
                        -ActionName $context.ActionName `
                        -Result $fallbackResult
                }
                catch {
                    # Keep the application open even if the detailed renderer is unavailable.
                }

                $context.StatusText.Text = 'Status: Error'
                (Get-BoostLabUiElement -Name 'ApplicationStatusText').Text = $message
            }
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
    $script:BoostLabToolSelectionControls = @{}

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
    $script:BoostLabLatestResult = $null
    $script:BoostLabLatestResultToolMetadata = $null
    $script:BoostLabLatestResultActionName = ''
    $script:BoostLabLatestResultText = ''
    $script:BoostLabToolSelectionControls = @{}

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
    (Get-BoostLabUiElement -Name 'CopyLatestResultButton').Add_Click({
        Copy-BoostLabLatestResult
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
