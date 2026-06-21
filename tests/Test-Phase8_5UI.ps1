[CmdletBinding()]
param(
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([Threading.Thread]::CurrentThread.ApartmentState -ne [Threading.ApartmentState]::STA) {
    throw 'Test-Phase8_5UI.ps1 must run with powershell.exe -STA.'
}

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $scriptPath = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $PSCommandPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $MyInvocation.MyCommand.Path
    }
    else {
        throw 'Unable to determine the Phase 8.5 UI test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$xamlPath = Join-Path $ProjectRoot 'ui\MainWindow.xaml'
$controllerPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$biosInformationPath = Join-Path $ProjectRoot 'modules\Check\BIOSInformation.psm1'
$biosSettingsPath = Join-Path $ProjectRoot 'modules\Check\BIOSSettings.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

function Get-BoostLabTestText {
    param(
        [Parameter(Mandatory)]
        [System.Windows.DependencyObject]$Root
    )

    $text = [System.Collections.Generic.List[string]]::new()
    $queue = [System.Collections.Generic.Queue[System.Windows.DependencyObject]]::new()
    $queue.Enqueue($Root)

    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        if ($current -is [System.Windows.Controls.TextBlock]) {
            $text.Add([string]$current.Text)
        }

        $childCount = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($current)
        for ($index = 0; $index -lt $childCount; $index++) {
            $queue.Enqueue([System.Windows.Media.VisualTreeHelper]::GetChild($current, $index))
        }
    }

    return $text.ToArray()
}

[xml]$xaml = Get-Content -Raw -LiteralPath $xamlPath
$reader = [System.Xml.XmlNodeReader]::new($xaml)
$window = $null
$biosInformationModule = $null
$biosSettingsModule = $null
$executionModule = $null
$clipboardCaptured = $false
$originalClipboardText = ''

try {
    $window = [Windows.Markup.XamlReader]::Load($reader)
    . $controllerPath
    $script:BoostLabWindow = $window
    $script:BoostLabVisibleLogText.Clear()

    $rootGrid = [System.Windows.Controls.Grid]$window.Content
    if ($rootGrid.ColumnDefinitions.Count -ne 3) {
        throw 'The main layout does not contain sidebar, content, and results columns.'
    }
    if ([int]$rootGrid.ColumnDefinitions[0].Width.Value -ne 226) {
        throw 'The workflow sidebar width is incorrect.'
    }
    if ([int]$rootGrid.ColumnDefinitions[2].Width.Value -ne 372) {
        throw 'The Activity & Results panel width is incorrect.'
    }
    if ($window.MinWidth -gt 1280 -or $window.MinHeight -gt 720) {
        throw 'The window minimum size prevents use at 1280x720.'
    }

    foreach ($controlName in @(
        'SelectedToolNameText'
        'SelectedToolActionText'
        'LatestResultPanel'
        'LatestResultStatusText'
        'CopyLatestResultButton'
        'ActivityLogRichTextBox'
        'ClearLogButton'
        'CopyLogButton'
    )) {
        if ($null -eq $window.FindName($controlName)) {
            throw "The Activity & Results panel is missing control: $controlName"
        }
    }

    $configuration = Import-PowerShellDataFile -LiteralPath $configPath
    $tools = @($configuration['Stages'] | ForEach-Object { $_['Tools'] })
    $biosInformationTool = $tools | Where-Object { $_['Id'] -eq 'bios-information' } | Select-Object -First 1
    $biosSettingsTool = $tools | Where-Object { $_['Id'] -eq 'bios-settings' } | Select-Object -First 1
    $powerPlanTool = $tools | Where-Object { $_['Id'] -eq 'power-plan' } | Select-Object -First 1
    $placeholderTool = $tools |
        Where-Object {
            $candidateModulePath = Join-Path $modulesRoot ("{0}\{1}.psm1" -f [string]$_['Stage'], [string]$_['Id'])
            (Test-Path -LiteralPath $candidateModulePath -PathType Leaf) -and
            (Get-Content -Raw -LiteralPath $candidateModulePath).Contains('ToolModule.Placeholder.ps1')
        } |
        Select-Object -First 1
    if ($null -eq $placeholderTool) {
        throw 'No placeholder tool is available for UI placeholder rendering validation.'
    }

    $biosInformationModule = Import-Module `
        -Name $biosInformationPath `
        -Force `
        -PassThru `
        -Prefix 'Phase85BiosInformation' `
        -Scope Local `
        -DisableNameChecking `
        -ErrorAction Stop
    $biosSettingsModule = Import-Module `
        -Name $biosSettingsPath `
        -Force `
        -PassThru `
        -Prefix 'Phase85BiosSettings' `
        -Scope Local `
        -DisableNameChecking `
        -ErrorAction Stop

    $biosInformationResult = Invoke-Phase85BiosInformationBoostLabToolAction -ActionName 'Analyze'
    Show-BoostLabActionResult `
        -ToolMetadata $biosInformationTool `
        -ActionName 'Analyze' `
        -Result $biosInformationResult
    $biosInformationText = Get-BoostLabTestText -Root $window.FindName('LatestResultPanel')
    foreach ($expectedLabel in @(
        'Motherboard Manufacturer:'
        'Motherboard Model:'
        'BIOS Vendor:'
        'BIOS Version:'
        'BIOS Date:'
        'TPM:'
        'Secure Boot:'
        'CPU:'
        'Windows:'
    )) {
        if ($expectedLabel -notin $biosInformationText) {
            throw "BIOS Information result formatting is missing: $expectedLabel"
        }
    }

    $biosSettingsResult = Invoke-Phase85BiosSettingsBoostLabToolAction -ActionName 'Analyze'
    Show-BoostLabActionResult `
        -ToolMetadata $biosSettingsTool `
        -ActionName 'Analyze' `
        -Result $biosSettingsResult
    $biosSettingsText = Get-BoostLabTestText -Root $window.FindName('LatestResultPanel')
    foreach ($expectedText in @(
        'INTEL CPU'
        'AMD CPU'
        ([string][char]0x2022 + ' ENABLE ram profile (XMP DOCP EXPO)')
        ([string][char]0x2022 + ' ENABLE precision boost overdrive (PBO)')
        ([string][char]0x2022 + ' MAX pump and set fans to performance')
    )) {
        if ($expectedText -notin $biosSettingsText) {
            throw "BIOS Settings result formatting is missing: $expectedText"
        }
    }

    function global:Write-BoostLabInfo {
        param($Message, $Source, $EventId, $Data)
        return [pscustomobject]@{ Message = $Message }
    }
    function global:Write-BoostLabError {
        param($Message, $Source, $EventId, $Data)
        return [pscustomobject]@{ Message = $Message }
    }
    function global:Set-BoostLabToolState {
        param($ToolId, $Status, $LastAction, $LastResult, [switch]$NoSave)
        return [pscustomobject]@{ Status = $Status }
    }
    function global:Set-BoostLabStateValue {
        param($Name, $Value, [switch]$NoSave)
        return [pscustomobject]@{ Name = $Name; Value = $Value }
    }
    function global:Set-BoostLabRestartRequired {
        param([bool]$Required, $Reason)
        return [pscustomobject]@{ RestartRequired = $Required }
    }

    $executionModule = Import-Module `
        -Name $executionPath `
        -Force `
        -PassThru `
        -Scope Local `
        -ErrorAction Stop

    $placeholderCard = New-BoostLabToolCard -Tool $placeholderTool
    $placeholderCardLayout = [System.Windows.Controls.Grid]$placeholderCard.Child
    $placeholderActionsPanel = $placeholderCardLayout.Children |
        Where-Object {
            $_ -is [System.Windows.Controls.WrapPanel] -and
            [System.Windows.Controls.Grid]::GetRow($_) -eq 4
        } |
        Select-Object -First 1
    $placeholderAnalyzeButton = $placeholderActionsPanel.Children |
        Where-Object { [string]$_.Content -eq 'Analyze' } |
        Select-Object -First 1
    if ($null -eq $placeholderAnalyzeButton) {
        throw 'The placeholder Analyze button was not generated.'
    }

    $logCountBeforeClick = $script:BoostLabVisibleLogText.Count
    $placeholderAnalyzeButton.RaiseEvent(
        [System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent)
    )
    if ($script:BoostLabVisibleLogText.Count -ne ($logCountBeforeClick + 1)) {
        throw 'A real placeholder card click did not append exactly one visible activity entry.'
    }

    $placeholderText = Get-BoostLabTestText -Root $window.FindName('LatestResultPanel')
    foreach ($expectedText in @(
        'Tool:'
        [string]$placeholderTool['Title']
        'Action:'
        'Analyze'
        'Command Status:'
        'Not implemented'
        'Message:'
        'Action not implemented yet'
    )) {
        if ($expectedText -notin $placeholderText) {
            throw "Placeholder result formatting is missing: $expectedText"
        }
    }

    $failureStatusText = [System.Windows.Controls.TextBlock]::new()
    $failureContext = [pscustomobject]@{
        ToolMetadata = $placeholderTool
        ActionName   = 'Analyze'
        StatusText   = $failureStatusText
    }
    $failureLogCountBefore = $script:BoostLabVisibleLogText.Count
    $runtimeFailureResult = Invoke-BoostLabToolCardAction `
        -Context $failureContext `
        -ActionInvoker {
            throw "The term 'Get-BoostLabVerificationValidation' is not recognized as the name of a cmdlet, function, script file, or operable program."
        }
    if (
        [bool]$runtimeFailureResult.Success -or
        [string]$runtimeFailureResult.Status -ne 'Failed' -or
        -not ([string]$runtimeFailureResult.Message).Contains('Get-BoostLabVerificationValidation') -or
        [string]$failureStatusText.Text -ne 'Status: Error'
    ) {
        throw 'The WPF action boundary did not return a structured Failed result for a missing verification helper.'
    }
    if ($script:BoostLabVisibleLogText.Count -ne ($failureLogCountBefore + 1)) {
        throw 'The WPF action boundary did not append the verification helper failure to Activity Log.'
    }
    $failureLogEntry = [string]$script:BoostLabVisibleLogText[$script:BoostLabVisibleLogText.Count - 1]
    if (
        -not $failureLogEntry.Contains('[ERROR]') -or
        -not $failureLogEntry.Contains('Get-BoostLabVerificationValidation')
    ) {
        throw 'The verification helper failure Activity Log entry is incomplete.'
    }
    $runtimeFailureText = Get-BoostLabTestText -Root $window.FindName('LatestResultPanel')
    foreach ($expectedText in @(
        'Status:'
        'Error'
        'Message:'
        'Get-BoostLabVerificationValidation'
    )) {
        if (-not (@($runtimeFailureText | Where-Object { $_ -like "*$expectedText*" }).Count -gt 0)) {
            throw "Latest Result did not render the verification helper failure: $expectedText"
        }
    }

    $originalClipboardText = [System.Windows.Clipboard]::GetText()
    $clipboardCaptured = $true
    $longPowerPlanError = 'POWER_PLAN_ERROR_BEGIN ' + ('diagnostic-segment ' * 320) + 'POWER_PLAN_ERROR_END'
    $powerPlanDiagnosticResult = [pscustomobject]@{
        Success            = $false
        ToolId             = 'power-plan'
        ToolTitle          = 'Power Plan'
        Action             = 'Apply'
        Status             = 'Failed'
        Message            = $longPowerPlanError
        RestartRequired    = $false
        Cancelled          = $false
        ActionPlan         = [pscustomobject]@{
            RiskLevel                = 'Medium'
            Summary                  = 'Apply the approved Power Plan configuration.'
            PlannedChanges           = @('Run approved powercfg commands.')
            SideEffects              = @('Active power behavior may change.')
            RequiresAdmin            = $true
            UsesTrustedInstaller      = $false
            NeedsExplicitConfirmation = $true
            IsDryRun                  = $false
            ConfirmationMessage      = 'Confirm the approved Power Plan Apply action.'
        }
        VerificationResult = [pscustomobject]@{
            Status        = 'Failed'
            Message       = 'The detected active plan did not match the expected plan.'
            ExpectedState = [pscustomobject]@{ PowerPlan = 'BoostLab approved plan' }
            DetectedState = [pscustomobject]@{ PowerPlan = 'Balanced' }
            Checks        = @(
                [pscustomobject]@{
                    Name     = 'Active Power Plan'
                    Status   = 'Failed'
                    Expected = 'BoostLab approved plan'
                    Actual   = 'Balanced'
                    Message  = 'The active power plan differs from the requested plan.'
                }
            )
        }
        Data               = [pscustomobject]@{
            CommandStatus                    = 'Failed'
            VerificationStatus               = 'Failed'
            PowerPlanGuidsTargeted            = @('00000000-0000-0000-0000-000000000000')
            PowerCfgCommandsOrSettingsChecked = @('powercfg diagnostic command text')
            RegistryValuesOrFilesChecked     = @('No diagnostic fixture writes were performed.')
            PowerOptionsStatus               = 'Not opened'
            Warnings                         = @('Power Plan diagnostic warning text.')
            Errors                           = @($longPowerPlanError)
            CompletedAt                      = Get-Date
        }
        Timestamp          = Get-Date
    }

    Show-BoostLabActionResult `
        -ToolMetadata $powerPlanTool `
        -ActionName 'Apply' `
        -Result $powerPlanDiagnosticResult
    $powerPlanResultText = Get-BoostLabTestText -Root $window.FindName('LatestResultPanel')
    if ($longPowerPlanError -notin $powerPlanResultText) {
        throw 'Latest Result truncated or omitted the full Power Plan error text.'
    }
    foreach ($expectedText in @(
        'Tool:'
        'Tool Id:'
        'Command Status:'
        'Verification Status:'
        'Message:'
        'Warnings:'
        'Errors:'
        'Verification Checks'
        'Timestamp:'
    )) {
        if (-not (@($powerPlanResultText | Where-Object { $_ -like "*$expectedText*" }).Count -gt 0)) {
            throw "Latest Result is missing diagnostic field: $expectedText"
        }
    }

    $formattedPowerPlanResult = Format-BoostLabLatestResultText `
        -ToolMetadata $powerPlanTool `
        -ActionName 'Apply' `
        -Result $powerPlanDiagnosticResult
    if (
        -not $formattedPowerPlanResult.Contains($longPowerPlanError) -or
        -not $formattedPowerPlanResult.Contains('Active Power Plan') -or
        -not $formattedPowerPlanResult.Contains('Expected: BoostLab approved plan') -or
        -not $formattedPowerPlanResult.Contains('Actual: Balanced') -or
        -not $formattedPowerPlanResult.Contains('Apply the approved Power Plan configuration.')
    ) {
        throw 'The plain-text Latest Result formatter omitted structured Power Plan diagnostics.'
    }

    Copy-BoostLabLatestResult
    $copiedLatestResult = [System.Windows.Clipboard]::GetText()
    if (
        -not $copiedLatestResult.Contains($longPowerPlanError) -or
        -not $copiedLatestResult.Contains('Tool Id: power-plan') -or
        -not $copiedLatestResult.Contains('Verification Checks') -or
        -not $copiedLatestResult.Contains('Action Plan')
    ) {
        throw 'Copy Latest Result did not copy the complete structured result.'
    }

    $minimalResult = [pscustomobject]@{
        Success   = $false
        Message   = 'Minimal diagnostic failure.'
        Timestamp = Get-Date
    }
    Show-BoostLabActionResult `
        -ToolMetadata $powerPlanTool `
        -ActionName 'Apply' `
        -Result $minimalResult
    $minimalFormattedResult = Format-BoostLabLatestResultText `
        -ToolMetadata $powerPlanTool `
        -ActionName 'Apply' `
        -Result $minimalResult
    if (
        -not $minimalFormattedResult.Contains('Minimal diagnostic failure.') -or
        -not $minimalFormattedResult.Contains('Verification Status: Not available')
    ) {
        throw 'Latest Result did not handle missing optional result properties cleanly.'
    }

    $notApplicableTool = [ordered]@{
        Id = 'notepad-settings'
        Title = 'Notepad Settings'
    }
    $notApplicableResult = [pscustomobject]@{
        Success = $true
        ToolId = 'notepad-settings'
        ToolTitle = 'Notepad Settings'
        Action = 'Apply'
        Status = 'NotApplicable'
        Message = 'The source-targeted Notepad settings.dat is absent.'
        Data = [pscustomobject]@{
            CommandStatus = 'Not applicable'
            VerificationStatus = 'NotApplicable'
            ChangesExecuted = $false
        }
        Timestamp = Get-Date
    }
    Add-BoostLabToolActionActivityEntry `
        -ToolMetadata $notApplicableTool `
        -ActionName 'Apply' `
        -Result $notApplicableResult

    Add-BoostLabStartupActivityEntry
    Add-BoostLabToolActionActivityEntry `
        -ToolMetadata $biosInformationTool `
        -ActionName 'Analyze' `
        -Result $biosInformationResult
    Add-BoostLabToolActionActivityEntry `
        -ToolMetadata $biosSettingsTool `
        -ActionName 'Analyze' `
        -Result $biosSettingsResult
    Add-BoostLabActivityEntry -Entry ([pscustomobject]@{
        Timestamp = Get-Date
        Level     = 'Warning'
        Source    = 'UI Test'
        EventId   = 'Warning'
        Message   = 'Warning message'
    })
    Add-BoostLabActivityEntry -Entry ([pscustomobject]@{
        Timestamp = Get-Date
        Level     = 'Error'
        Source    = 'UI Test'
        EventId   = 'Error'
        Message   = 'Error message'
    })
    Add-BoostLabActivityEntry -Entry ([pscustomobject]@{
        Timestamp = Get-Date
        Level     = 'Debug'
        Source    = 'UI Test'
        EventId   = 'Detail'
        Message   = 'Detail message'
    })
    Add-BoostLabActivityEntry -Entry ([pscustomobject]@{
        Timestamp = Get-Date
        Level     = 'Error'
        Source    = 'Power Plan'
        EventId   = 'Apply'
        Message   = $longPowerPlanError
    })
    $visibleLogText = $script:BoostLabVisibleLogText -join "`r`n"
    foreach ($displayLevel in @('INFO', 'SUCCESS', 'WARNING', 'ERROR', 'DETAIL')) {
        if ($visibleLogText -notmatch "\[$displayLevel\]") {
            throw "The visible log is missing level: $displayLevel"
        }
    }
    if (
        $visibleLogText -notmatch '\[INFO\]\s+Notepad Settings' -or
        $visibleLogText -match '\[ERROR\]\s+Notepad Settings'
    ) {
        throw 'NotApplicable activity severity did not render as a neutral INFO entry.'
    }
    foreach ($expectedEntryText in @(
        'BoostLab'
        'Startup'
        'Interface initialized.'
        'The source-targeted Notepad settings.dat is absent.'
        'BIOS Information'
        'Hardware and BIOS information detected.'
        'BIOS Settings'
        'Guidance prepared'
        [string]$placeholderTool['Title']
        'Action not implemented yet'
        ([string][char]0x2192)
    )) {
        if (-not $visibleLogText.Contains($expectedEntryText)) {
            throw "The visible log is missing action entry text: $expectedEntryText"
        }
    }

    Copy-BoostLabVisibleActivityLog
    $copiedText = [System.Windows.Clipboard]::GetText()
    if (
        -not $copiedText.Contains('BIOS Information') -or
        -not $copiedText.Contains('Analyze') -or
        -not $copiedText.Contains('Hardware and BIOS information detected.') -or
        -not $copiedText.Contains($longPowerPlanError)
    ) {
        throw 'Copy Log did not copy the complete visible activity text.'
    }

    Clear-BoostLabVisibleActivityLog
    $activityLog = [System.Windows.Controls.RichTextBox]$window.FindName('ActivityLogRichTextBox')
    if ($script:BoostLabVisibleLogText.Count -ne 0 -or $activityLog.Document.Blocks.Count -ne 0) {
        throw 'Clear Log did not clear the visible UI log.'
    }

    $biosInformationSource = Get-Content -Raw -LiteralPath $biosInformationPath
    if (
        -not $biosInformationSource.Contains('https://www.google.com/search?q=') -or
        -not $biosInformationSource.Contains('Start-Process $searchUrl')
    ) {
        throw 'BIOS Information Open behavior changed.'
    }
    $biosSettingsSource = Get-Content -Raw -LiteralPath $biosSettingsPath
    if (
        -not $biosSettingsSource.Contains('/r /fw /t 0') -or
        -not $biosSettingsSource.Contains('[bool]$Confirmed = $false')
    ) {
        throw 'BIOS Settings Open behavior changed.'
    }

    [pscustomobject]@{
        Success                    = $true
        LayoutColumns              = $rootGrid.ColumnDefinitions.Count
        BiosInformationAnalyze     = $biosInformationResult.Success
        BiosSettingsAnalyze        = $biosSettingsResult.Success
        PlaceholderResultRendered  = $true
        RuntimeFailureContained    = $true
        VisibleLogLevels           = 5
        ClearLogValidated          = $true
        CopyLatestResultValidated  = $true
        CopyLogValidated           = $true
        OpenActionsExecuted        = $false
        Message                    = 'Phase 8.5 Activity & Results presentation validated without executing Open actions.'
        Timestamp                  = Get-Date
    }
}
finally {
    if ($clipboardCaptured) {
        if ([string]::IsNullOrEmpty($originalClipboardText)) {
            [System.Windows.Clipboard]::Clear()
        }
        else {
            [System.Windows.Clipboard]::SetText($originalClipboardText)
        }
    }
    if ($null -ne $biosSettingsModule) {
        Remove-Module -ModuleInfo $biosSettingsModule -Force -ErrorAction SilentlyContinue
    }
    if ($null -ne $executionModule) {
        Remove-Module -ModuleInfo $executionModule -Force -ErrorAction SilentlyContinue
    }
    if ($null -ne $biosInformationModule) {
        Remove-Module -ModuleInfo $biosInformationModule -Force -ErrorAction SilentlyContinue
    }
    if ($null -ne $window) {
        $window.Close()
    }
    $reader.Close()
}
