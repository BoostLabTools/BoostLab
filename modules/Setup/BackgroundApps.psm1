Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $verificationModulePath -Scope Local -Force -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'background-apps'; Title = 'Background Apps'; Stage = 'Setup'; Order = 5
    Type = 'action'; RiskLevel = 'low'
    Description = 'Disable background apps by machine policy or restore the approved default behavior.'
    Actions = @('Apply', 'Default')
    Capabilities = [ordered]@{
        RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false
        CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false
        CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false
        CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false
        SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Apply', 'Default')
$script:BoostLabAppPrivacyRegistryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy'
$script:BoostLabAppPrivacyProviderPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy'
$script:BoostLabBackgroundAppsValueName = 'LetAppsRunInBackground'
$script:BoostLabBackgroundAppsSettingsUri = 'ms-settings:privacy-backgroundapps'

function Test-BoostLabAdministrator {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function New-BoostLabBackgroundAppsResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$Message,

        [bool]$Cancelled = $false,

        [AllowNull()]
        [object]$Data = $null,

        [AllowNull()]
        [object]$VerificationResult = $null
    )

    return [pscustomobject]@{
        Success            = $Success
        ToolId             = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle          = [string]$script:BoostLabToolMetadata['Title']
        Action             = $Action
        Message            = $Message
        RestartRequired    = $false
        Cancelled          = $Cancelled
        Timestamp          = Get-Date
        Data               = $Data
        VerificationResult = $VerificationResult
    }
}

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        Id                 = [string]$script:BoostLabToolMetadata['Id']
        Title              = [string]$script:BoostLabToolMetadata['Title']
        Stage              = [string]$script:BoostLabToolMetadata['Stage']
        Order              = [int]$script:BoostLabToolMetadata['Order']
        Type               = [string]$script:BoostLabToolMetadata['Type']
        RiskLevel          = [string]$script:BoostLabToolMetadata['RiskLevel']
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
        [string]$OperatingSystem = $env:OS,

        [string]$SystemRoot = $env:SystemRoot
    )

    $commandProcessorPath = if ([string]::IsNullOrWhiteSpace($SystemRoot)) {
        ''
    }
    else {
        Join-Path $SystemRoot 'System32\cmd.exe'
    }
    $supported = (
        $OperatingSystem -eq 'Windows_NT' -and
        -not [string]::IsNullOrWhiteSpace($commandProcessorPath) -and
        (Test-Path -LiteralPath $commandProcessorPath -PathType Leaf)
    )

    return [pscustomobject]@{
        Supported = $supported
        ToolId    = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason    = if ($OperatingSystem -ne 'Windows_NT') {
            'Background Apps requires Windows.'
        }
        elseif ([string]::IsNullOrWhiteSpace($commandProcessorPath)) {
            'The Windows system directory is unavailable.'
        }
        elseif (-not $supported) {
            'Background Apps is unavailable because cmd.exe was not found.'
        }
        else {
            'Windows registry policy and Settings launch support are available.'
        }
        Timestamp = Get-Date
    }
}

function Get-BoostLabBackgroundAppsRegistryValue {
    param(
        [scriptblock]$RegistryReader = {
            param($Path, $Name)
            if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
                return [pscustomobject]@{
                    ReadSucceeded = $true
                    KeyExists     = $false
                    Exists        = $false
                    Value         = $null
                    DisplayValue  = 'Absent'
                    Message       = 'Registry path is absent.'
                }
            }

            $item = Get-ItemProperty -LiteralPath $Path -ErrorAction Stop
            $property = $item.PSObject.Properties[$Name]
            if ($null -eq $property) {
                return [pscustomobject]@{
                    ReadSucceeded = $true
                    KeyExists     = $true
                    Exists        = $false
                    Value         = $null
                    DisplayValue  = 'Absent'
                    Message       = 'Registry value is absent.'
                }
            }

            return [pscustomobject]@{
                ReadSucceeded = $true
                KeyExists     = $true
                Exists        = $true
                Value         = $property.Value
                DisplayValue  = [string]$property.Value
                Message       = 'Registry value detected.'
            }
        }
    )

    try {
        $results = @(
            & $RegistryReader `
                $script:BoostLabAppPrivacyProviderPath `
                $script:BoostLabBackgroundAppsValueName
        )
        if ($results.Count -eq 0 -or $null -eq $results[0]) {
            throw 'Registry reader returned no result.'
        }

        return $results[0]
    }
    catch {
        return [pscustomobject]@{
            ReadSucceeded = $false
            KeyExists     = $null
            Exists        = $false
            Value         = $null
            DisplayValue  = 'Unknown'
            Message       = $_.Exception.Message
        }
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $state = Get-BoostLabBackgroundAppsRegistryValue
    $status = if (-not [bool]$state.ReadSucceeded) {
        'Unavailable'
    }
    elseif (-not [bool]$state.Exists) {
        'Default'
    }
    elseif ([string]$state.Value -eq '2') {
        'Disabled by policy'
    }
    else {
        "Policy value: $($state.DisplayValue)"
    }

    return [pscustomobject]@{
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        Status          = $status
        LastAction      = $null
        LastResult      = $null
        RestartRequired = $false
        Timestamp       = Get-Date
    }
}

function Test-BoostLabBackgroundAppsState {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [scriptblock]$RegistryReader = {
            Get-BoostLabBackgroundAppsRegistryValue
        }
    )

    try {
        $stateResults = @(& $RegistryReader)
        $state = if ($stateResults.Count -gt 0) {
            $stateResults[0]
        }
        else {
            $null
        }
    }
    catch {
        $state = $null
    }

    $readSucceeded = (
        $null -ne $state -and
        $null -ne $state.PSObject.Properties['ReadSucceeded'] -and
        [bool]$state.ReadSucceeded
    )
    $exists = (
        $readSucceeded -and
        $null -ne $state.PSObject.Properties['Exists'] -and
        [bool]$state.Exists
    )
    $detectedValue = if (
        $readSucceeded -and
        $null -ne $state.PSObject.Properties['Value']
    ) {
        $state.Value
    }
    else {
        $null
    }
    $displayValue = if (
        $null -ne $state -and
        $null -ne $state.PSObject.Properties['DisplayValue']
    ) {
        [string]$state.DisplayValue
    }
    else {
        'Unknown'
    }
    $stateMessage = if (
        $null -ne $state -and
        $null -ne $state.PSObject.Properties['Message']
    ) {
        [string]$state.Message
    }
    else {
        'The Background Apps policy value could not be read.'
    }

    $expectedState = if ($ActionName -eq 'Apply') {
        'Disabled by policy (LetAppsRunInBackground = 2)'
    }
    else {
        'Default (LetAppsRunInBackground absent)'
    }
    $detectedState = if (-not $readSucceeded) {
        'Unknown'
    }
    elseif (-not $exists) {
        'Default (value absent)'
    }
    elseif ([string]$detectedValue -eq '2') {
        'Disabled by policy (value = 2)'
    }
    else {
        "Policy value = $displayValue"
    }
    $status = if (-not $readSucceeded) {
        'Warning'
    }
    elseif ($ActionName -eq 'Apply' -and $exists -and [string]$detectedValue -eq '2') {
        'Passed'
    }
    elseif ($ActionName -eq 'Default' -and -not $exists) {
        'Passed'
    }
    else {
        'Failed'
    }
    $message = switch ($status) {
        'Passed' { 'The expected Background Apps policy state was detected.' }
        'Warning' { 'The command completed, but the Background Apps policy value could not be detected.' }
        default { 'The detected Background Apps policy state does not match the expected result.' }
    }
    $check = New-BoostLabVerificationCheck `
        -Name 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy\LetAppsRunInBackground' `
        -Expected $expectedState `
        -Actual $detectedState `
        -Status $status `
        -Message $stateMessage

    return New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $ActionName `
        -Status $status `
        -ExpectedState ([pscustomobject]@{ BackgroundApps = $expectedState }) `
        -DetectedState ([pscustomobject]@{ BackgroundApps = $detectedState }) `
        -Checks @($check) `
        -Message $message
}

function Invoke-BoostLabBackgroundAppsRegistryCommand {
    param(
        [Parameter(Mandatory)]
        [string]$CommandText
    )

    if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        throw 'The Windows system directory is unavailable.'
    }
    $commandProcessorPath = Join-Path $env:SystemRoot 'System32\cmd.exe'
    if (-not (Test-Path -LiteralPath $commandProcessorPath -PathType Leaf)) {
        throw 'cmd.exe was not found.'
    }

    $output = & $commandProcessorPath /c $CommandText 2>&1
    if ($LASTEXITCODE -ne 0) {
        $detail = (@($output) -join ' ').Trim()
        if ([string]::IsNullOrWhiteSpace($detail)) {
            $detail = "reg.exe returned exit code $LASTEXITCODE."
        }

        throw $detail
    }
}

function Invoke-BoostLabBackgroundAppsAction {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [scriptblock]$AdministratorChecker = {
            Test-BoostLabAdministrator
        },

        [scriptblock]$RegistryReader = {
            Get-BoostLabBackgroundAppsRegistryValue
        },

        [scriptblock]$RegistryCommandInvoker = {
            param($CommandText)
            Invoke-BoostLabBackgroundAppsRegistryCommand -CommandText $CommandText
        },

        [scriptblock]$SettingsLauncher = {
            Start-Process ms-settings:privacy-backgroundapps -ErrorAction Stop
        }
    )

    if (-not [bool](& $AdministratorChecker)) {
        return New-BoostLabBackgroundAppsResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Administrator rights are required to change Background Apps policy.'
    }

    $commandText = if ($ActionName -eq 'Apply') {
        'reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /t REG_DWORD /d "2" /f'
    }
    else {
        'reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /f'
    }
    $initialState = if ($ActionName -eq 'Default') {
        Get-BoostLabBackgroundAppsRegistryValue -RegistryReader $RegistryReader
    }
    else {
        $null
    }
    $alreadyDefault = (
        $ActionName -eq 'Default' -and
        $null -ne $initialState -and
        $null -ne $initialState.PSObject.Properties['ReadSucceeded'] -and
        [bool]$initialState.ReadSucceeded -and
        $null -ne $initialState.PSObject.Properties['Exists'] -and
        -not [bool]$initialState.Exists
    )
    $commandStatus = if ($alreadyDefault) { 'Already default' } else { 'Pending' }
    $settingsPageStatus = 'Not launched'
    $errors = [System.Collections.Generic.List[string]]::new()

    if (-not $alreadyDefault) {
        try {
            & $RegistryCommandInvoker $commandText | Out-Null
            $commandStatus = 'Completed'
        }
        catch {
            $commandStatus = 'Failed'
            $errors.Add("Registry command failed: $($_.Exception.Message)")
        }
    }

    try {
        & $SettingsLauncher | Out-Null
        $settingsPageStatus = 'Launched'
    }
    catch {
        $settingsPageStatus = 'Failed'
        $errors.Add("Background Apps Settings launch failed: $($_.Exception.Message)")
    }

    $verificationResult = Test-BoostLabBackgroundAppsState `
        -ActionName $ActionName `
        -RegistryReader $RegistryReader
    $expectedState = [string]$verificationResult.ExpectedState.BackgroundApps
    $detectedState = [string]$verificationResult.DetectedState.BackgroundApps
    $completedAt = Get-Date
    $data = [pscustomobject]@{
        CommandStatus               = $commandStatus
        ExpectedBackgroundAppsState = $expectedState
        DetectedBackgroundAppsState = $detectedState
        RegistryValuesChecked       = @(
            'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy\LetAppsRunInBackground'
        )
        SettingsPageStatus          = $settingsPageStatus
        CompletedAt                 = $completedAt
    }

    if ($errors.Count -gt 0) {
        return New-BoostLabBackgroundAppsResult `
            -Success $false `
            -Action $ActionName `
            -Message ("Background Apps action completed with errors: {0}" -f ($errors -join '; ')) `
            -Data $data `
            -VerificationResult $verificationResult
    }

    $message = if ($verificationResult.Status -eq 'Warning') {
        'Background Apps command completed, but verification was unavailable.'
    }
    elseif ($verificationResult.Status -eq 'Failed') {
        'Background Apps command completed, but verification detected an unexpected state.'
    }
    elseif ($alreadyDefault) {
        'Background Apps already default.'
    }
    elseif ($ActionName -eq 'Apply') {
        'Background apps disabled.'
    }
    else {
        'Background apps restored to default.'
    }

    return New-BoostLabBackgroundAppsResult `
        -Success $true `
        -Action $ActionName `
        -Message $message `
        -Data $data `
        -VerificationResult $verificationResult
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ActionName,

        [bool]$Confirmed = $false
    )

    if ($ActionName -notin @($script:BoostLabImplementedActions)) {
        return New-BoostLabBackgroundAppsResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Unsupported action. Only Apply and Default are allowed.'
    }
    if (-not $Confirmed) {
        return New-BoostLabBackgroundAppsResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    return Invoke-BoostLabBackgroundAppsAction -ActionName $ActionName
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [bool]$Confirmed = $false
    )

    return Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed:$Confirmed
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
