Set-StrictMode -Version Latest

function Initialize-AxisWpfAssemblies {
    [CmdletBinding()]
    param()

    foreach ($assemblyName in @('PresentationCore', 'PresentationFramework', 'WindowsBase')) {
        Add-Type -AssemblyName $assemblyName -ErrorAction Stop
    }
}

function Get-AxisDesignTokens {
    [CmdletBinding()]
    param()

    $colors = [ordered]@{
        'Axis.Color.Background.App' = '#090D12'
        'Axis.Color.Background.Panel' = '#0D131A'
        'Axis.Color.Background.Deep' = '#05080C'
        'Axis.Color.Background.Inset' = '#111923'

        'Axis.Color.Wizard.Background' = '#080808'
        'Axis.Color.Wizard.WindowSurface' = '#080808'
        'Axis.Color.Wizard.AppBackground' = '#0C0C0C'
        'Axis.Color.Wizard.HeaderBackground' = '#0C0C0C'
        'Axis.Color.Wizard.StageStripBackground' = '#0C0C0C'
        'Axis.Color.Wizard.Panel' = '#161616'
        'Axis.Color.Wizard.MainPanel' = '#161616'
        'Axis.Color.Wizard.MainCardBackground' = '#161616'
        'Axis.Color.Wizard.Surface' = '#161616'
        'Axis.Color.Wizard.ElevatedCard' = '#181818'
        'Axis.Color.Wizard.CardAlt' = '#202020'
        'Axis.Color.Wizard.StatusPanel' = '#161616'
        'Axis.Color.Wizard.SecondaryButton' = '#161616'
        'Axis.Color.Wizard.SurfaceSoft' = '#202020'
        'Axis.Color.Wizard.Card' = '#161616'
        'Axis.Color.Wizard.InfoCard' = '#181818'
        'Axis.Color.Wizard.SurfaceElevated' = '#202020'
        'Axis.Color.Wizard.SecondaryButtonHover' = '#202020'
        'Axis.Color.Wizard.Border' = '#242424'
        'Axis.Color.Wizard.BorderSoft' = '#242424'
        'Axis.Color.Wizard.BorderStrong' = '#363636'
        'Axis.Color.Wizard.TextPrimary' = '#FAF9F6'
        'Axis.Color.Wizard.TextHighlight' = '#F5F5F5'
        'Axis.Color.Wizard.TextSecondary' = '#EDEDED'
        'Axis.Color.Wizard.TextMuted' = '#C9C9C9'
        'Axis.Color.Wizard.TextDim' = '#9A9A9A'
        'Axis.Color.Wizard.Accent' = '#F0F2F5'
        'Axis.Color.Wizard.AccentHover' = '#F5F5F5'
        'Axis.Color.Wizard.AccentPressed' = '#EDEDED'
        'Axis.Color.Wizard.AccentText' = '#F0F2F5'
        'Axis.Color.Wizard.AccentSoft' = '#202020'
        'Axis.Color.Wizard.BrandWarm' = '#F0F2F5'
        'Axis.Color.Wizard.WarmAccent' = '#F0F2F5'
        'Axis.Color.Wizard.WarmAccentHover' = '#F5F5F5'
        'Axis.Color.Wizard.WarmAccentPressed' = '#EDEDED'
        'Axis.Color.Wizard.WarmAccentMuted' = '#C9C9C9'
        'Axis.Color.Wizard.WarmAccentSoft' = '#202020'
        'Axis.Color.Wizard.IconStone' = '#F5F5F5'
        'Axis.Color.Wizard.IconSoft' = '#C9C9C9'
        'Axis.Color.Wizard.PrimaryButton' = '#F0F2F5'
        'Axis.Color.Wizard.PrimaryButtonHover' = '#F5F5F5'
        'Axis.Color.Wizard.PrimaryButtonText' = '#101010'
        'Axis.Color.Wizard.StateReady.Background' = '#161616'
        'Axis.Color.Wizard.StateReady.Border' = '#363636'
        'Axis.Color.Wizard.StateReady.Text' = '#EDEDED'
        'Axis.Color.Wizard.StateChecking.Background' = '#161616'
        'Axis.Color.Wizard.StateChecking.Border' = '#F0F2F5'
        'Axis.Color.Wizard.StateChecking.Text' = '#FAF9F6'
        'Axis.Color.Wizard.StateCompleted.Background' = '#161616'
        'Axis.Color.Wizard.StateCompleted.Border' = '#F0F2F5'
        'Axis.Color.Wizard.StateCompleted.Text' = '#FAF9F6'
        'Axis.Color.Wizard.SuccessCalm' = '#F0F2F5'
        'Axis.Color.Wizard.Disabled' = '#363636'
        'Axis.Color.Wizard.Shadow' = '#080808'

        'Axis.Color.Surface.Base' = '#121A24'
        'Axis.Color.Surface.Raised' = '#172231'
        'Axis.Color.Surface.Elevated' = '#1B2838'
        'Axis.Color.Surface.Interactive' = '#1A2634'
        'Axis.Color.Surface.InteractiveHover' = '#223246'
        'Axis.Color.Surface.InteractivePressed' = '#101822'

        'Axis.Color.Border.Subtle' = '#243244'
        'Axis.Color.Border.Default' = '#314154'
        'Axis.Color.Border.Strong' = '#4A5F78'
        'Axis.Color.Border.Divider' = '#1F2A38'
        'Axis.Color.Border.Focus' = '#55B7FF'

        'Axis.Color.Text.Primary' = '#F2F7FC'
        'Axis.Color.Text.Secondary' = '#B8C6D6'
        'Axis.Color.Text.Muted' = '#7F8EA3'
        'Axis.Color.Text.Disabled' = '#546172'
        'Axis.Color.Text.Inverse' = '#061019'
        'Axis.Color.Text.Diagnostics' = '#C7D3E2'

        'Axis.Color.Accent.Primary' = '#2FA8FF'
        'Axis.Color.Accent.Hover' = '#55B7FF'
        'Axis.Color.Accent.Pressed' = '#1688D8'
        'Axis.Color.Accent.Subtle' = '#14304A'
        'Axis.Color.Accent.Text' = '#8FD2FF'

        'Axis.Color.Focus.Ring' = '#67C3FF'
        'Axis.Color.Focus.Inner' = '#0A1420'
        'Axis.Color.Selection.Background' = '#123A58'
        'Axis.Color.Selection.Border' = '#2FA8FF'
        'Axis.Color.Overlay.Modal' = '#020509CC'
        'Axis.Color.Overlay.Subtle' = '#02050988'

        'Axis.Color.Status.Completed' = '#4CCB7A'
        'Axis.Color.Status.Completed.Background' = '#102318'
        'Axis.Color.Status.Completed.Border' = '#245C39'
        'Axis.Color.Status.Completed.Text' = '#A8F0C0'

        'Axis.Color.Status.CompletedWithNotes' = '#5BC8D6'
        'Axis.Color.Status.CompletedWithNotes.Background' = '#0E2830'
        'Axis.Color.Status.CompletedWithNotes.Border' = '#2E7080'
        'Axis.Color.Status.CompletedWithNotes.Text' = '#B9F2F8'

        'Axis.Color.Status.NeedsAttention' = '#F4B84A'
        'Axis.Color.Status.NeedsAttention.Background' = '#33250D'
        'Axis.Color.Status.NeedsAttention.Border' = '#7A5A1A'
        'Axis.Color.Status.NeedsAttention.Text' = '#FFE2A3'

        'Axis.Color.Status.Stopped' = '#F16B6B'
        'Axis.Color.Status.Stopped.Background' = '#351818'
        'Axis.Color.Status.Stopped.Border' = '#7B3434'
        'Axis.Color.Status.Stopped.Text' = '#FFC7C7'

        'Axis.Color.Status.RestartNeeded' = '#6EA8FF'
        'Axis.Color.Status.RestartNeeded.Background' = '#12233E'
        'Axis.Color.Status.RestartNeeded.Border' = '#315B96'
        'Axis.Color.Status.RestartNeeded.Text' = '#C8DDFF'

        'Axis.Color.Status.WaitingForConfirmation' = '#9AA7FF'
        'Axis.Color.Status.WaitingForConfirmation.Background' = '#1D2142'
        'Axis.Color.Status.WaitingForConfirmation.Border' = '#555FA5'
        'Axis.Color.Status.WaitingForConfirmation.Text' = '#DDE2FF'

        'Axis.Color.Status.NotAvailableOnThisDevice' = '#8A96A8'
        'Axis.Color.Status.NotAvailableOnThisDevice.Background' = '#1B2028'
        'Axis.Color.Status.NotAvailableOnThisDevice.Border' = '#4A5564'
        'Axis.Color.Status.NotAvailableOnThisDevice.Text' = '#D4DAE3'

        'Axis.Color.Status.SkippedBecauseNotNeeded' = '#7EA0B8'
        'Axis.Color.Status.SkippedBecauseNotNeeded.Background' = '#172531'
        'Axis.Color.Status.SkippedBecauseNotNeeded.Border' = '#496A7F'
        'Axis.Color.Status.SkippedBecauseNotNeeded.Text' = '#D2E6F2'

        'Axis.Color.Status.Running' = '#2FA8FF'
        'Axis.Color.Status.Running.Background' = '#102B44'
        'Axis.Color.Status.Running.Border' = '#2A74A8'
        'Axis.Color.Status.Running.Text' = '#C9ECFF'

        'Axis.Color.Risk.SystemChange' = '#5EA8FF'
        'Axis.Color.Risk.SystemChange.Background' = '#102844'
        'Axis.Color.Risk.SystemChange.Border' = '#2D6194'
        'Axis.Color.Risk.SystemChange.Text' = '#C8E4FF'

        'Axis.Color.Risk.DriverChange' = '#45D5E8'
        'Axis.Color.Risk.DriverChange.Background' = '#0D2B31'
        'Axis.Color.Risk.DriverChange.Border' = '#28717B'
        'Axis.Color.Risk.DriverChange.Text' = '#BDF5FC'

        'Axis.Color.Risk.SecuritySensitive' = '#F2C14E'
        'Axis.Color.Risk.SecuritySensitive.Background' = '#322709'
        'Axis.Color.Risk.SecuritySensitive.Border' = '#7C641D'
        'Axis.Color.Risk.SecuritySensitive.Text' = '#FFE7A6'

        'Axis.Color.Risk.RestartRequired' = '#9AA7FF'
        'Axis.Color.Risk.RestartRequired.Background' = '#1B2042'
        'Axis.Color.Risk.RestartRequired.Border' = '#5661A7'
        'Axis.Color.Risk.RestartRequired.Text' = '#E0E4FF'

        'Axis.Color.Risk.DownloadRequired' = '#58BDF7'
        'Axis.Color.Risk.DownloadRequired.Background' = '#102C42'
        'Axis.Color.Risk.DownloadRequired.Border' = '#2B6F96'
        'Axis.Color.Risk.DownloadRequired.Text' = '#C8EDFF'

        'Axis.Color.Risk.FileCleanup' = '#FF9F4A'
        'Axis.Color.Risk.FileCleanup.Background' = '#36210D'
        'Axis.Color.Risk.FileCleanup.Border' = '#845020'
        'Axis.Color.Risk.FileCleanup.Text' = '#FFD9B7'

        'Axis.Color.Risk.Advanced' = '#8E9BFF'
        'Axis.Color.Risk.Advanced.Background' = '#1A1F42'
        'Axis.Color.Risk.Advanced.Border' = '#515AA1'
        'Axis.Color.Risk.Advanced.Text' = '#DDE2FF'

        'Axis.Color.Risk.DeviceSpecific' = '#4EC9B0'
        'Axis.Color.Risk.DeviceSpecific.Background' = '#0F2B26'
        'Axis.Color.Risk.DeviceSpecific.Border' = '#2B6D61'
        'Axis.Color.Risk.DeviceSpecific.Text' = '#BFF2E8'

        'Axis.Color.Diagnostics.Background' = '#0A1017'
        'Axis.Color.Diagnostics.Border' = '#263445'
        'Axis.Color.Diagnostics.Text' = '#C7D3E2'
        'Axis.Color.Diagnostics.Muted' = '#7F8EA3'
    }

    $brushes = [ordered]@{}
    foreach ($colorKey in $colors.Keys) {
        $brushSuffix = [string]$colorKey
        $brushSuffix = $brushSuffix.Substring('Axis.Color.'.Length)
        $brushes["Axis.Brush.$brushSuffix"] = [string]$colorKey
    }

    foreach ($stateName in @(
        'Completed'
        'CompletedWithNotes'
        'NeedsAttention'
        'Stopped'
        'RestartNeeded'
        'WaitingForConfirmation'
        'NotAvailableOnThisDevice'
        'SkippedBecauseNotNeeded'
        'Running'
    )) {
        $brushes["Axis.Status.$stateName.Brush"] = "Axis.Color.Status.$stateName"
        $brushes["Axis.Status.$stateName.BackgroundBrush"] = "Axis.Color.Status.$stateName.Background"
        $brushes["Axis.Status.$stateName.BorderBrush"] = "Axis.Color.Status.$stateName.Border"
        $brushes["Axis.Status.$stateName.TextBrush"] = "Axis.Color.Status.$stateName.Text"
    }

    foreach ($riskName in @(
        'SystemChange'
        'DriverChange'
        'SecuritySensitive'
        'RestartRequired'
        'DownloadRequired'
        'FileCleanup'
        'Advanced'
        'DeviceSpecific'
    )) {
        $brushes["Axis.Risk.$riskName.Brush"] = "Axis.Color.Risk.$riskName"
        $brushes["Axis.Risk.$riskName.BackgroundBrush"] = "Axis.Color.Risk.$riskName.Background"
        $brushes["Axis.Risk.$riskName.BorderBrush"] = "Axis.Color.Risk.$riskName.Border"
        $brushes["Axis.Risk.$riskName.TextBrush"] = "Axis.Color.Risk.$riskName.Text"
    }

    $brushes['Axis.Focus.Ring.Brush'] = 'Axis.Color.Focus.Ring'
    $brushes['Axis.Focus.Inner.Brush'] = 'Axis.Color.Focus.Inner'

    $typography = [ordered]@{
        'Axis.Type.Display.FontFamily' = 'Segoe UI'
        'Axis.Type.Display.FontSize' = 32.0
        'Axis.Type.Display.FontWeight' = 'Bold'
        'Axis.Type.Display.LineHeight' = 40.0

        'Axis.Type.PageTitle.FontFamily' = 'Segoe UI'
        'Axis.Type.PageTitle.FontSize' = 28.0
        'Axis.Type.PageTitle.FontWeight' = 'SemiBold'
        'Axis.Type.PageTitle.LineHeight' = 36.0

        'Axis.Type.SectionTitle.FontFamily' = 'Segoe UI'
        'Axis.Type.SectionTitle.FontSize' = 18.0
        'Axis.Type.SectionTitle.FontWeight' = 'SemiBold'
        'Axis.Type.SectionTitle.LineHeight' = 26.0

        'Axis.Type.CardTitle.FontFamily' = 'Segoe UI'
        'Axis.Type.CardTitle.FontSize' = 17.0
        'Axis.Type.CardTitle.FontWeight' = 'SemiBold'
        'Axis.Type.CardTitle.LineHeight' = 24.0

        'Axis.Type.Body.FontFamily' = 'Segoe UI'
        'Axis.Type.Body.FontSize' = 15.0
        'Axis.Type.Body.FontWeight' = 'Normal'
        'Axis.Type.Body.LineHeight' = 23.0

        'Axis.Type.BodySmall.FontFamily' = 'Segoe UI'
        'Axis.Type.BodySmall.FontSize' = 15.0
        'Axis.Type.BodySmall.FontWeight' = 'Normal'
        'Axis.Type.BodySmall.LineHeight' = 21.0

        'Axis.Type.Caption.FontFamily' = 'Segoe UI'
        'Axis.Type.Caption.FontSize' = 13.0
        'Axis.Type.Caption.FontWeight' = 'Normal'
        'Axis.Type.Caption.LineHeight' = 18.0

        'Axis.Type.Micro.FontFamily' = 'Segoe UI'
        'Axis.Type.Micro.FontSize' = 14.0
        'Axis.Type.Micro.FontWeight' = 'Medium'
        'Axis.Type.Micro.LineHeight' = 19.0

        'Axis.Type.DiagnosticsMono.FontFamily' = 'Cascadia Mono, Consolas'
        'Axis.Type.DiagnosticsMono.FontSize' = 12.0
        'Axis.Type.DiagnosticsMono.FontWeight' = 'Normal'
        'Axis.Type.DiagnosticsMono.LineHeight' = 18.0
    }

    $spacing = [ordered]@{
        'Axis.Space.2' = 2.0
        'Axis.Space.4' = 4.0
        'Axis.Space.6' = 6.0
        'Axis.Space.8' = 8.0
        'Axis.Space.12' = 12.0
        'Axis.Space.16' = 16.0
        'Axis.Space.20' = 20.0
        'Axis.Space.24' = 24.0
        'Axis.Space.32' = 32.0
        'Axis.Space.40' = 40.0
        'Axis.Space.48' = 48.0
    }

    $radius = [ordered]@{
        'Axis.Radius.None' = 0.0
        'Axis.Radius.Small' = 4.0
        'Axis.Radius.Medium' = 6.0
        'Axis.Radius.Large' = 8.0
        'Axis.Radius.XLarge' = 12.0
        'Axis.Radius.Pill' = 999.0
        'Axis.Radius.Wizard.Window' = 14.0
        'Axis.Radius.Wizard.MainCard' = 16.0
        'Axis.Radius.Wizard.InfoCard' = 12.0
        'Axis.Radius.Wizard.Button' = 14.0
        'Axis.Radius.Wizard.IconBackplate' = 20.0
        'Axis.Radius.Wizard.StatusPanel' = 12.0
    }

    $borders = [ordered]@{
        'Axis.Border.Width.Hairline' = 1.0
        'Axis.Border.Width.Default' = 1.0
        'Axis.Border.Width.Emphasis' = 2.0
    }

    $statusResults = [ordered]@{
        Completed = 'Step finished as expected'
        CompletedWithNotes = 'Step finished with useful notes'
        NeedsAttention = 'Review before continuing'
        Stopped = 'Workflow did not continue'
        RestartNeeded = 'Restart is required to finish'
        WaitingForConfirmation = 'Paused until the user decides'
        NotAvailableOnThisDevice = 'Step is not applicable here'
        SkippedBecauseNotNeeded = 'Checked and avoided unnecessary work'
        Running = 'Work is active'
    }

    $risks = [ordered]@{
        SystemChange = 'Windows settings, policy, services, or behavior'
        DriverChange = 'Driver or graphics-related work'
        SecuritySensitive = 'Security, encryption, or protection state'
        RestartRequired = 'Restart before or after action'
        DownloadRequired = 'Internet or approved artifact need'
        FileCleanup = 'Scoped cleanup or deletion'
        Advanced = 'Deeper technical behavior'
        DeviceSpecific = 'Hardware, edition, or state-dependent'
    }

    $focus = [ordered]@{
        'Axis.Focus.Ring.Thickness' = 2.0
        'Axis.Focus.Inner.Thickness' = 1.0
    }

    $diagnostics = [ordered]@{
        'Axis.Diagnostics.CopyReportAction' = 'Copy technical report'
        'Axis.Diagnostics.DefaultFontFamily' = 'Cascadia Mono, Consolas'
        'Axis.Diagnostics.DefaultLineHeight' = 18.0
    }

    return [ordered]@{
        Colors = $colors
        Brushes = $brushes
        Typography = $typography
        Spacing = $spacing
        Radius = $radius
        Borders = $borders
        StatusResults = $statusResults
        Risks = $risks
        Focus = $focus
        Diagnostics = $diagnostics
    }
}

function ConvertTo-AxisWpfColor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$')]
        [string]$Hex
    )

    Initialize-AxisWpfAssemblies
    return [System.Windows.Media.ColorConverter]::ConvertFromString($Hex)
}

function New-AxisFrozenSolidColorBrush {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Color
    )

    $brush = [System.Windows.Media.SolidColorBrush]::new($Color)
    if ($brush.CanFreeze) {
        $brush.Freeze()
    }

    return $brush
}

function ConvertTo-AxisFontWeight {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    Initialize-AxisWpfAssemblies
    switch ($Name) {
        'Medium' { return [System.Windows.FontWeights]::Medium }
        'SemiBold' { return [System.Windows.FontWeights]::SemiBold }
        'Bold' { return [System.Windows.FontWeights]::Bold }
        default { return [System.Windows.FontWeights]::Normal }
    }
}

function New-AxisWpfResourceDictionary {
    [CmdletBinding()]
    param(
        [hashtable]$Tokens = (Get-AxisDesignTokens)
    )

    Initialize-AxisWpfAssemblies
    $resources = [System.Windows.ResourceDictionary]::new()

    foreach ($colorKey in $Tokens.Colors.Keys) {
        $resources[$colorKey] = ConvertTo-AxisWpfColor -Hex ([string]$Tokens.Colors[$colorKey])
    }

    foreach ($brushKey in $Tokens.Brushes.Keys) {
        $colorKey = [string]$Tokens.Brushes[$brushKey]
        $resources[$brushKey] = New-AxisFrozenSolidColorBrush -Color $resources[$colorKey]
    }

    foreach ($typeKey in $Tokens.Typography.Keys) {
        $value = $Tokens.Typography[$typeKey]
        if ($typeKey.EndsWith('.FontFamily', [StringComparison]::Ordinal)) {
            $resources[$typeKey] = [System.Windows.Media.FontFamily]::new([string]$value)
        }
        elseif ($typeKey.EndsWith('.FontWeight', [StringComparison]::Ordinal)) {
            $resources[$typeKey] = ConvertTo-AxisFontWeight -Name ([string]$value)
        }
        else {
            $resources[$typeKey] = [double]$value
        }
    }

    foreach ($spaceKey in $Tokens.Spacing.Keys) {
        $space = [double]$Tokens.Spacing[$spaceKey]
        $resources[$spaceKey] = $space
        $resources[$spaceKey.Replace('Axis.Space.', 'Axis.Thickness.')] = [System.Windows.Thickness]::new($space)
    }

    foreach ($radiusKey in $Tokens.Radius.Keys) {
        $resources[$radiusKey] = [System.Windows.CornerRadius]::new([double]$Tokens.Radius[$radiusKey])
    }

    foreach ($borderKey in $Tokens.Borders.Keys) {
        $resources[$borderKey] = [double]$Tokens.Borders[$borderKey]
    }

    foreach ($focusKey in $Tokens.Focus.Keys) {
        $resources[$focusKey] = [double]$Tokens.Focus[$focusKey]
    }

    foreach ($diagnosticKey in $Tokens.Diagnostics.Keys) {
        $value = $Tokens.Diagnostics[$diagnosticKey]
        if ($diagnosticKey.EndsWith('FontFamily', [StringComparison]::Ordinal)) {
            $resources[$diagnosticKey] = [System.Windows.Media.FontFamily]::new([string]$value)
        }
        elseif ($value -is [ValueType]) {
            $resources[$diagnosticKey] = [double]$value
        }
        else {
            $resources[$diagnosticKey] = [string]$value
        }
    }

    return $resources
}

function Add-AxisResourcesToElement {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Element,

        [object]$Resources = (New-AxisWpfResourceDictionary)
    )

    try {
        $targetResources = $Element.Resources
    }
    catch {
        $targetResources = $null
    }

    if ($null -eq $targetResources) {
        throw 'The target element does not expose a WPF Resources collection.'
    }

    foreach ($key in $Resources.Keys) {
        $targetResources[$key] = $Resources[$key]
    }

    return $targetResources
}

function Get-AxisTokenLookup {
    [CmdletBinding()]
    param(
        [hashtable]$Tokens = (Get-AxisDesignTokens)
    )

    $lookup = [ordered]@{}
    foreach ($categoryName in $Tokens.Keys) {
        $category = $Tokens[$categoryName]
        if ($category -is [System.Collections.IDictionary]) {
            foreach ($key in $category.Keys) {
                $lookup[[string]$key] = $category[$key]
            }
        }
    }

    return $lookup
}

function Get-AxisResourceValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [object]$ResourceDictionary
    )

    if ($null -ne $ResourceDictionary -and $ResourceDictionary.Contains($Name)) {
        return $ResourceDictionary[$Name]
    }

    $lookup = Get-AxisTokenLookup
    if ($lookup.Contains($Name)) {
        return $lookup[$Name]
    }

    return $null
}

function Test-AxisDesignTokens {
    [CmdletBinding()]
    param()

    $tokens = Get-AxisDesignTokens
    $resources = New-AxisWpfResourceDictionary -Tokens $tokens
    $requiredKeys = @(
        'Axis.Color.Background.App'
        'Axis.Brush.Background.App'
        'Axis.Color.Surface.Base'
        'Axis.Brush.Surface.Base'
        'Axis.Color.Text.Primary'
        'Axis.Brush.Text.Primary'
        'Axis.Color.Accent.Primary'
        'Axis.Brush.Accent.Primary'
        'Axis.Space.16'
        'Axis.Radius.Medium'
        'Axis.Status.Completed.Brush'
        'Axis.Status.CompletedWithNotes.Brush'
        'Axis.Risk.DriverChange.Brush'
        'Axis.Focus.Ring.Brush'
    )

    $missingKeys = @($requiredKeys | Where-Object { -not $resources.Contains($_) })

    return [pscustomobject]@{
        Passed = $missingKeys.Count -eq 0
        CategoryCount = $tokens.Keys.Count
        ResourceCount = $resources.Keys.Count
        MissingKeys = $missingKeys
    }
}
