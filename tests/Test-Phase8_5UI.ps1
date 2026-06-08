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
    $placeholderTool = $tools | Where-Object { $_['Id'] -eq 'memory-compression' } | Select-Object -First 1

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
        'Status:'
        'Not implemented'
        'Message:'
        'Action not implemented yet'
    )) {
        if ($expectedText -notin $placeholderText) {
            throw "Placeholder result formatting is missing: $expectedText"
        }
    }

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
    $visibleLogText = $script:BoostLabVisibleLogText -join "`r`n"
    foreach ($displayLevel in @('INFO', 'SUCCESS', 'WARNING', 'ERROR', 'DETAIL')) {
        if ($visibleLogText -notmatch "\[$displayLevel\]") {
            throw "The visible log is missing level: $displayLevel"
        }
    }
    foreach ($expectedEntryText in @(
        'BoostLab'
        'Startup'
        'Interface initialized.'
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

    $originalClipboardText = [System.Windows.Clipboard]::GetText()
    $clipboardCaptured = $true
    Copy-BoostLabVisibleActivityLog
    $copiedText = [System.Windows.Clipboard]::GetText()
    if (
        -not $copiedText.Contains('BIOS Information') -or
        -not $copiedText.Contains('Analyze') -or
        -not $copiedText.Contains('Hardware and BIOS information detected.')
    ) {
        throw 'Copy Log did not copy the visible activity text.'
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
        VisibleLogLevels           = 5
        ClearLogValidated          = $true
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
