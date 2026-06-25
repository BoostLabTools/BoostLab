Set-StrictMode -Version Latest

$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$verificationModulePath = Join-Path $projectRoot 'core\Verification.psm1'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $verificationModulePath -Scope Local -Force -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'input-language-hotkey'; Title = 'Input Language Hotkey'; Stage = 'Windows'; Order = 16
    Type = 'action'; RiskLevel = 'low'
    SourceType = 'BoostLabSpecificUserApproved'
    Description = 'Set the current user input language switching hotkey to Left Alt + Shift while keeping keyboard-layout switching Not Assigned.'
    Actions = @('Apply')
    Capabilities = [ordered]@{
        RequiresAdmin = $false; RequiresInternet = $false; CanReboot = $false
        CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false
        CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false
        CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false
        SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Apply')
$script:BoostLabRegistryProviderPath = 'HKCU:\Keyboard Layout\Toggle'
$script:BoostLabRegistryRelativePath = 'Keyboard Layout\Toggle'
$script:BoostLabExpectedValues = [ordered]@{
    'Hotkey' = '1'
    'Language Hotkey' = '1'
    'Layout Hotkey' = '3'
}

function New-BoostLabInputLanguageHotkeyResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$CommandStatus,

        [Parameter(Mandatory)]
        [string]$VerificationStatus,

        [Parameter(Mandatory)]
        [string]$Message,

        [bool]$Cancelled = $false,

        [AllowNull()]
        [object]$Data = $null,

        [AllowNull()]
        [object]$VerificationResult = $null,

        [string[]]$Warnings = @(),

        [string[]]$Errors = @()
    )

    [pscustomobject]@{
        Success            = $Success
        Status             = $Status
        ToolId             = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle          = [string]$script:BoostLabToolMetadata['Title']
        Action             = $Action
        CommandStatus      = $CommandStatus
        VerificationStatus = $VerificationStatus
        Message            = $Message
        RestartRequired    = $false
        Cancelled          = $Cancelled
        Warnings           = @($Warnings)
        Errors             = @($Errors)
        Data               = $Data
        VerificationResult = $VerificationResult
        Timestamp          = Get-Date
    }
}

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        Id                 = [string]$script:BoostLabToolMetadata['Id']
        Title              = [string]$script:BoostLabToolMetadata['Title']
        Stage              = [string]$script:BoostLabToolMetadata['Stage']
        Order              = [int]$script:BoostLabToolMetadata['Order']
        Type               = [string]$script:BoostLabToolMetadata['Type']
        RiskLevel          = [string]$script:BoostLabToolMetadata['RiskLevel']
        SourceType         = [string]$script:BoostLabToolMetadata['SourceType']
        Description        = [string]$script:BoostLabToolMetadata['Description']
        Actions            = @($script:BoostLabToolMetadata['Actions'])
        Capabilities       = [pscustomobject]$script:BoostLabToolMetadata['Capabilities']
        ImplementedActions = @($script:BoostLabImplementedActions)
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$OperatingSystem = $env:OS
    )

    $isWindows = $OperatingSystem -eq 'Windows_NT'
    [pscustomobject]@{
        Supported = $isWindows
        ToolId    = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason    = if ($isWindows) {
            'Current-user keyboard layout toggle registry values are available on Windows.'
        }
        else {
            'Input Language Hotkey requires Windows.'
        }
        Timestamp = Get-Date
    }
}

function Get-BoostLabInputLanguageHotkeyRegistryValue {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $key = $null
    try {
        $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($script:BoostLabRegistryRelativePath, $false)
        if ($null -eq $key) {
            return [pscustomobject]@{
                ReadSucceeded = $true
                KeyExists     = $false
                Exists        = $false
                Value         = $null
                ValueKind     = ''
                DisplayValue  = 'Absent'
                Message       = 'Registry key is absent.'
            }
        }

        if ($Name -notin @($key.GetValueNames())) {
            return [pscustomobject]@{
                ReadSucceeded = $true
                KeyExists     = $true
                Exists        = $false
                Value         = $null
                ValueKind     = ''
                DisplayValue  = 'Absent'
                Message       = 'Registry value is absent.'
            }
        }

        $value = $key.GetValue($Name, $null)
        $valueKind = $key.GetValueKind($Name).ToString()
        return [pscustomobject]@{
            ReadSucceeded = $true
            KeyExists     = $true
            Exists        = $true
            Value         = $value
            ValueKind     = $valueKind
            DisplayValue  = [string]$value
            Message       = 'Registry value detected.'
        }
    }
    catch {
        return [pscustomobject]@{
            ReadSucceeded = $false
            KeyExists     = $null
            Exists        = $false
            Value         = $null
            ValueKind     = ''
            DisplayValue  = 'Unknown'
            Message       = $_.Exception.Message
        }
    }
    finally {
        if ($null -ne $key) {
            $key.Dispose()
        }
    }
}

function Set-BoostLabInputLanguageHotkeyRegistryValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Value
    )

    $key = $null
    try {
        $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($script:BoostLabRegistryRelativePath)
        if ($null -eq $key) {
            throw 'Unable to create or open the current-user keyboard layout toggle key.'
        }

        $key.SetValue($Name, [string]$Value, [Microsoft.Win32.RegistryValueKind]::String)
    }
    finally {
        if ($null -ne $key) {
            $key.Dispose()
        }
    }
}

function Test-BoostLabInputLanguageHotkeyState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [scriptblock]$RegistryReader = {
            param($Path, $Name)
            Get-BoostLabInputLanguageHotkeyRegistryValue -Name $Name
        }
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    $detectedValues = [ordered]@{}
    foreach ($entry in $script:BoostLabExpectedValues.GetEnumerator()) {
        $name = [string]$entry.Key
        $expectedValue = [string]$entry.Value
        $readResult = $null
        try {
            $results = @(& $RegistryReader $script:BoostLabRegistryProviderPath $name)
            $readResult = if ($results.Count -gt 0) { $results[0] } else { $null }
        }
        catch {
            $readResult = [pscustomobject]@{
                ReadSucceeded = $false
                Exists        = $false
                Value         = $null
                ValueKind     = ''
                DisplayValue  = 'Unknown'
                Message       = $_.Exception.Message
            }
        }

        $displayValue = if ($null -ne $readResult -and $null -ne $readResult.PSObject.Properties['DisplayValue']) {
            [string]$readResult.DisplayValue
        }
        elseif ($null -ne $readResult -and $null -ne $readResult.PSObject.Properties['Value']) {
            [string]$readResult.Value
        }
        else {
            'Unknown'
        }
        $valueKind = if ($null -ne $readResult -and $null -ne $readResult.PSObject.Properties['ValueKind']) {
            [string]$readResult.ValueKind
        }
        else {
            ''
        }
        $message = if ($null -ne $readResult -and $null -ne $readResult.PSObject.Properties['Message']) {
            [string]$readResult.Message
        }
        else {
            'Registry value could not be read.'
        }
        $readSucceeded = (
            $null -ne $readResult -and
            $null -ne $readResult.PSObject.Properties['ReadSucceeded'] -and
            [bool]$readResult.ReadSucceeded
        )
        $exists = (
            $readSucceeded -and
            $null -ne $readResult.PSObject.Properties['Exists'] -and
            [bool]$readResult.Exists
        )
        $actualValue = if ($exists -and $null -ne $readResult.PSObject.Properties['Value']) {
            [string]$readResult.Value
        }
        else {
            $null
        }

        $detectedValues[$name] = $displayValue
        $status = if (-not $readSucceeded) {
            'Failed'
        }
        elseif (-not $exists) {
            'Failed'
        }
        elseif (-not [string]::IsNullOrWhiteSpace($valueKind) -and $valueKind -ne 'String') {
            'Failed'
        }
        elseif ($actualValue -ne $expectedValue) {
            'Failed'
        }
        else {
            'Passed'
        }
        $expectedDescription = if ($name -eq 'Layout Hotkey') {
            "$name = $expectedValue (Not Assigned)"
        }
        else {
            "$name = $expectedValue (Left Alt + Shift)"
        }
        $actualDescription = if ([string]::IsNullOrWhiteSpace($valueKind)) {
            $displayValue
        }
        else {
            "$displayValue [$valueKind]"
        }

        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name "$($script:BoostLabRegistryProviderPath)\$name" `
                -Expected $expectedDescription `
                -Actual $actualDescription `
                -Status $status `
                -Message $message)
        )
    }

    $overallStatus = if (@($checks | Where-Object { [string]$_.Status -eq 'Failed' }).Count -gt 0) {
        'Failed'
    }
    else {
        'Passed'
    }
    $expectedState = [pscustomobject]@{
        RegistryPath = $script:BoostLabRegistryProviderPath
        Hotkey = '1'
        LanguageHotkey = '1'
        LayoutHotkey = '3'
        InputLanguageSwitch = 'Left Alt + Shift'
        KeyboardLayoutSwitch = 'Not Assigned'
    }
    $detectedState = [pscustomobject]@{
        RegistryPath = $script:BoostLabRegistryProviderPath
        Hotkey = [string]$detectedValues['Hotkey']
        LanguageHotkey = [string]$detectedValues['Language Hotkey']
        LayoutHotkey = [string]$detectedValues['Layout Hotkey']
    }
    $message = if ($overallStatus -eq 'Passed') {
        'Input language hotkey registry values match Left Alt + Shift with keyboard-layout switching Not Assigned.'
    }
    else {
        'Input language hotkey registry values do not match the expected state.'
    }

    New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action 'Apply' `
        -Status $overallStatus `
        -ExpectedState $expectedState `
        -DetectedState $detectedState `
        -Checks $checks.ToArray() `
        -Message $message
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $verification = Test-BoostLabInputLanguageHotkeyState
    $status = if ([string]$verification.Status -eq 'Passed') {
        'Left Alt + Shift'
    }
    else {
        'Not configured'
    }

    [pscustomobject]@{
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        Status          = $status
        LastAction      = $null
        LastResult      = $null
        RestartRequired = $false
        Timestamp       = Get-Date
    }
}

function Invoke-BoostLabInputLanguageHotkeyApply {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [scriptblock]$RegistryWriter = {
            param($Path, $Name, $Value)
            Set-BoostLabInputLanguageHotkeyRegistryValue -Name $Name -Value $Value
            [pscustomobject]@{ Success = $true; Message = "Set $Name." }
        },

        [scriptblock]$RegistryReader = {
            param($Path, $Name)
            Get-BoostLabInputLanguageHotkeyRegistryValue -Name $Name
        }
    )

    $writeResults = [System.Collections.Generic.List[object]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($entry in $script:BoostLabExpectedValues.GetEnumerator()) {
        $name = [string]$entry.Key
        $value = [string]$entry.Value
        try {
            $results = @(& $RegistryWriter $script:BoostLabRegistryProviderPath $name $value)
            $writeResults.Add([pscustomobject]@{
                Name = $name
                ExpectedValue = $value
                Success = $true
                Message = if ($results.Count -gt 0 -and $null -ne $results[0] -and $null -ne $results[0].PSObject.Properties['Message']) { [string]$results[0].Message } else { "Set $name." }
            })
        }
        catch {
            $errors.Add("$name write failed: $($_.Exception.Message)")
            $writeResults.Add([pscustomobject]@{
                Name = $name
                ExpectedValue = $value
                Success = $false
                Message = $_.Exception.Message
            })
        }
    }

    $verification = Test-BoostLabInputLanguageHotkeyState -RegistryReader $RegistryReader
    $verificationStatus = [string]$verification.Status
    $warnings = @()

    $finalStatusReason = if ($errors.Count -gt 0) {
        'Registry write failed.'
    }
    elseif ($verificationStatus -eq 'Failed') {
        'Registry verification failed.'
    }
    else {
        'Registry verification passed.'
    }
    $data = [pscustomobject]@{
        RegistryPath = $script:BoostLabRegistryProviderPath
        RegistryValuesChecked = @($script:BoostLabExpectedValues.GetEnumerator() | ForEach-Object {
            [pscustomobject]@{ Name = [string]$_.Key; ExpectedValue = [string]$_.Value }
        })
        RegistryWriteResults = $writeResults.ToArray()
        ExpectedInputLanguageHotkey = 'Left Alt + Shift'
        DetectedInputLanguageHotkey = 'Hotkey={0}; Language Hotkey={1}' -f [string]$verification.DetectedState.Hotkey, [string]$verification.DetectedState.LanguageHotkey
        ExpectedKeyboardLayoutHotkey = 'Not Assigned'
        DetectedKeyboardLayoutHotkey = [string]$verification.DetectedState.LayoutHotkey
        FinalStatusReason = $finalStatusReason
        HkcuOnly = $true
        HklmMutation = $false
        UiAutomationUsed = $false
    }

    if ($errors.Count -gt 0 -or $verificationStatus -eq 'Failed') {
        return New-BoostLabInputLanguageHotkeyResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'Error' `
            -CommandStatus $(if ($errors.Count -gt 0) { 'Failed' } else { 'Completed' }) `
            -VerificationStatus $verificationStatus `
            -Message 'Input Language Hotkey Apply failed; expected HKCU keyboard layout toggle values were not fully verified.' `
            -Data $data `
            -VerificationResult $verification `
            -Warnings $warnings `
            -Errors $errors.ToArray()
    }

    $status = 'Completed'
    $commandStatus = 'Completed'
    $message = 'Input Language Hotkey was applied and verified.'

    New-BoostLabInputLanguageHotkeyResult `
        -Success $true `
        -Action 'Apply' `
        -Status $status `
        -CommandStatus $commandStatus `
        -VerificationStatus $verificationStatus `
        -Message $message `
        -Data $data `
        -VerificationResult $verification `
        -Warnings $warnings
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ActionName,

        [bool]$Confirmed = $false,

        [scriptblock]$RegistryWriter,

        [scriptblock]$RegistryReader
    )

    if ($ActionName -notin @($script:BoostLabImplementedActions)) {
        return New-BoostLabInputLanguageHotkeyResult `
            -Success $false `
            -Action $ActionName `
            -Status 'UnsupportedAction' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Unsupported action. Input Language Hotkey exposes only Apply.' `
            -Errors @("Unsupported Input Language Hotkey action: $ActionName")
    }

    if (-not $Confirmed) {
        return New-BoostLabInputLanguageHotkeyResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'Cancelled' `
            -CommandStatus 'Cancelled before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Input Language Hotkey Apply cancelled. No HKCU keyboard layout toggle values were attempted.' `
            -Cancelled $true
    }

    $applyParameters = @{}
    if ($PSBoundParameters.ContainsKey('RegistryWriter')) {
        $applyParameters['RegistryWriter'] = $RegistryWriter
    }
    if ($PSBoundParameters.ContainsKey('RegistryReader')) {
        $applyParameters['RegistryReader'] = $RegistryReader
    }

    Invoke-BoostLabInputLanguageHotkeyApply @applyParameters
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [bool]$Confirmed = $false
    )

    Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed:$Confirmed
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
