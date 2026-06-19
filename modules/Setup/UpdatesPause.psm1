Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $verificationModulePath -Scope Local -Force -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'updates-pause'; Title = 'Updates Pause'; Stage = 'Setup'; Order = 9
    Type = 'action'; RiskLevel = 'low'
    Description = 'Pause Windows Update for 365 days or restore the default unpaused registry state.'
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
$script:BoostLabUpdatesPauseRegistryPath = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
$script:BoostLabUpdatesPauseSettingsUri = 'ms-settings:windowsupdate'
$script:BoostLabUpdatesPauseDefinitions = @(
    [pscustomobject]@{ Name = 'PauseUpdatesExpiryTime'; ValueType = 'Expiry' }
    [pscustomobject]@{ Name = 'PauseFeatureUpdatesEndTime'; ValueType = 'Expiry' }
    [pscustomobject]@{ Name = 'PauseFeatureUpdatesStartTime'; ValueType = 'Start' }
    [pscustomobject]@{ Name = 'PauseQualityUpdatesEndTime'; ValueType = 'Expiry' }
    [pscustomobject]@{ Name = 'PauseQualityUpdatesStartTime'; ValueType = 'Start' }
    [pscustomobject]@{ Name = 'PauseUpdatesStartTime'; ValueType = 'Start' }
)

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

function New-BoostLabUpdatesPauseResult {
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

        [bool]$RegistryProviderAvailable = $(
            $null -ne (Get-PSProvider -PSProvider Registry -ErrorAction SilentlyContinue)
        )
    )

    $supported = $OperatingSystem -eq 'Windows_NT' -and $RegistryProviderAvailable
    return [pscustomobject]@{
        Supported = $supported
        ToolId    = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason    = if ($OperatingSystem -ne 'Windows_NT') {
            'Updates Pause requires Windows.'
        }
        elseif (-not $RegistryProviderAvailable) {
            'Updates Pause is unavailable because the PowerShell Registry provider was not found.'
        }
        else {
            'Windows Update pause registry and Settings support are available.'
        }
        Timestamp = Get-Date
    }
}

function Get-BoostLabUpdatesPauseRegistryValue {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [scriptblock]$RegistryReader = {
            param($Path, $RequestedName)
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
            $property = $item.PSObject.Properties[$RequestedName]
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
            & $RegistryReader $script:BoostLabUpdatesPauseRegistryPath $Name
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

    $states = @(
        foreach ($definition in $script:BoostLabUpdatesPauseDefinitions) {
            Get-BoostLabUpdatesPauseRegistryValue -Name ([string]$definition.Name)
        }
    )
    $unavailableCount = @($states | Where-Object { -not [bool]$_.ReadSucceeded }).Count
    $presentCount = @($states | Where-Object { [bool]$_.ReadSucceeded -and [bool]$_.Exists }).Count
    $status = if ($unavailableCount -gt 0) {
        'Unavailable'
    }
    elseif ($presentCount -eq $script:BoostLabUpdatesPauseDefinitions.Count) {
        'Paused'
    }
    elseif ($presentCount -eq 0) {
        'Default'
    }
    else {
        'Partially configured'
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

function Test-BoostLabUpdatesPauseState {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [AllowNull()]
        [System.Collections.IDictionary]$ExpectedValues = $null,

        [scriptblock]$RegistryReader = {
            param($Name)
            Get-BoostLabUpdatesPauseRegistryValue -Name $Name
        }
    )

    if ($ActionName -eq 'Apply' -and $null -eq $ExpectedValues) {
        throw 'Apply verification requires the expected pause values.'
    }

    $checks = [System.Collections.Generic.List[object]]::new()
    foreach ($definition in $script:BoostLabUpdatesPauseDefinitions) {
        $name = [string]$definition.Name
        try {
            $stateResults = @(& $RegistryReader $name)
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
        $actualValue = if (
            $readSucceeded -and
            $null -ne $state.PSObject.Properties['Value']
        ) {
            [string]$state.Value
        }
        elseif ($readSucceeded) {
            'Absent'
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
            'The registry value could not be read.'
        }
        $expectedValue = if ($ActionName -eq 'Apply') {
            [string]$ExpectedValues[$name]
        }
        else {
            'Absent'
        }
        $status = if (-not $readSucceeded) {
            'Warning'
        }
        elseif ($ActionName -eq 'Apply' -and $exists -and $actualValue -eq $expectedValue) {
            'Passed'
        }
        elseif ($ActionName -eq 'Default' -and -not $exists) {
            'Passed'
        }
        else {
            'Failed'
        }

        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name "$($script:BoostLabUpdatesPauseRegistryPath)\$name" `
                -Expected $expectedValue `
                -Actual $actualValue `
                -Status $status `
                -Message $stateMessage)
        )
    }

    $overallStatus = if (@($checks | Where-Object { $_.Status -eq 'Failed' }).Count -gt 0) {
        'Failed'
    }
    elseif (@($checks | Where-Object { $_.Status -eq 'Warning' }).Count -gt 0) {
        'Warning'
    }
    else {
        'Passed'
    }
    $expectedPauseState = if ($ActionName -eq 'Apply') {
        "Paused through $($ExpectedValues['PauseUpdatesExpiryTime'])"
    }
    else {
        'Default (pause values absent)'
    }
    $detectedPauseState = if ($overallStatus -eq 'Passed') {
        $expectedPauseState
    }
    elseif ($overallStatus -eq 'Warning') {
        'Partially detected'
    }
    else {
        'Unexpected Windows Update pause values'
    }
    $message = switch ($overallStatus) {
        'Passed' { 'The expected Windows Update pause state was detected.' }
        'Warning' { 'The command completed, but one or more Windows Update pause values could not be detected.' }
        default { 'The detected Windows Update pause values do not match the expected state.' }
    }

    return New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $ActionName `
        -Status $overallStatus `
        -ExpectedState ([pscustomobject]@{ UpdatesPause = $expectedPauseState }) `
        -DetectedState ([pscustomobject]@{ UpdatesPause = $detectedPauseState }) `
        -Checks $checks.ToArray() `
        -Message $message
}

function Set-BoostLabUpdatesPauseRegistryValue {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Value
    )

    Set-ItemProperty `
        -LiteralPath $script:BoostLabUpdatesPauseRegistryPath `
        -Name $Name `
        -Value $Value `
        -Force `
        -ErrorAction Stop
}

function Remove-BoostLabUpdatesPauseRegistryValue {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    if (-not (Test-Path -LiteralPath $script:BoostLabUpdatesPauseRegistryPath -PathType Container)) {
        return
    }
    $item = Get-ItemProperty -LiteralPath $script:BoostLabUpdatesPauseRegistryPath -ErrorAction Stop
    if ($null -eq $item.PSObject.Properties[$Name]) {
        return
    }

    Remove-ItemProperty `
        -LiteralPath $script:BoostLabUpdatesPauseRegistryPath `
        -Name $Name `
        -Force `
        -ErrorAction Stop
}

function Invoke-BoostLabUpdatesPauseAction {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [scriptblock]$AdministratorChecker = {
            Test-BoostLabAdministrator
        },

        [scriptblock]$DateProvider = {
            Get-Date
        },

        [scriptblock]$RegistryWriter = {
            param($Name, $Value)
            Set-BoostLabUpdatesPauseRegistryValue -Name $Name -Value $Value
        },

        [scriptblock]$RegistryRemover = {
            param($Name)
            Remove-BoostLabUpdatesPauseRegistryValue -Name $Name
        },

        [scriptblock]$RegistryReader = {
            param($Name)
            Get-BoostLabUpdatesPauseRegistryValue -Name $Name
        },

        [scriptblock]$SettingsLauncher = {
            Start-Process ms-settings:windowsupdate -ErrorAction Stop
        }
    )

    if (-not [bool](& $AdministratorChecker)) {
        return New-BoostLabUpdatesPauseResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Administrator rights are required to change Windows Update pause values.'
    }

    $expectedValues = [ordered]@{}
    $pauseStartTime = $null
    $pauseExpiryTime = $null
    if ($ActionName -eq 'Apply') {
        try {
            $pauseBaseResults = @(& $DateProvider)
            $todayResults = @(& $DateProvider)
            if (
                $pauseBaseResults.Count -eq 0 -or
                $todayResults.Count -eq 0 -or
                $null -eq $pauseBaseResults[0] -or
                $null -eq $todayResults[0]
            ) {
                throw 'Date provider returned no timestamp.'
            }

            $pauseExpiryTime = ([datetime]$pauseBaseResults[0]).AddDays(365).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
            $pauseStartTime = ([datetime]$todayResults[0]).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
            foreach ($definition in $script:BoostLabUpdatesPauseDefinitions) {
                $expectedValues[[string]$definition.Name] = if ($definition.ValueType -eq 'Expiry') {
                    $pauseExpiryTime
                }
                else {
                    $pauseStartTime
                }
            }
        }
        catch {
            return New-BoostLabUpdatesPauseResult `
                -Success $false `
                -Action $ActionName `
                -Message "Windows Update pause timestamps could not be prepared: $($_.Exception.Message)"
        }
    }

    $registryChanges = [System.Collections.Generic.List[string]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    $commandStatus = 'Pending'
    $settingsPageStatus = 'Not launched'
    $alreadyDefault = $false

    if ($ActionName -eq 'Default') {
        $initialStates = @(
            foreach ($definition in $script:BoostLabUpdatesPauseDefinitions) {
                & $RegistryReader ([string]$definition.Name)
            }
        )
        $alreadyDefault = (
            $initialStates.Count -eq $script:BoostLabUpdatesPauseDefinitions.Count -and
            @(
                $initialStates | Where-Object {
                    $null -eq $_ -or
                    $null -eq $_.PSObject.Properties['ReadSucceeded'] -or
                    -not [bool]$_.ReadSucceeded -or
                    (
                        $null -ne $_.PSObject.Properties['Exists'] -and
                        [bool]$_.Exists
                    )
                }
            ).Count -eq 0
        )
    }

    if ($alreadyDefault) {
        $commandStatus = 'Already default'
    }
    else {
        foreach ($definition in $script:BoostLabUpdatesPauseDefinitions) {
            $name = [string]$definition.Name
            try {
                if ($ActionName -eq 'Apply') {
                    $value = [string]$expectedValues[$name]
                    & $RegistryWriter $name $value | Out-Null
                    $registryChanges.Add("$($script:BoostLabUpdatesPauseRegistryPath)\$name = $value")
                }
                else {
                    & $RegistryRemover $name | Out-Null
                    $registryChanges.Add("$($script:BoostLabUpdatesPauseRegistryPath)\$name removed")
                }
            }
            catch {
                $errors.Add("$name failed: $($_.Exception.Message)")
            }
        }
        $commandStatus = if ($errors.Count -gt 0) {
            'Completed with errors'
        }
        else {
            'Completed'
        }
    }

    try {
        & $SettingsLauncher | Out-Null
        $settingsPageStatus = 'Launched'
    }
    catch {
        $settingsPageStatus = 'Failed'
        $errors.Add("Windows Update Settings launch failed: $($_.Exception.Message)")
    }

    $verificationResult = Test-BoostLabUpdatesPauseState `
        -ActionName $ActionName `
        -ExpectedValues $(if ($ActionName -eq 'Apply') { $expectedValues } else { $null }) `
        -RegistryReader $RegistryReader
    $expectedState = [string]$verificationResult.ExpectedState.UpdatesPause
    $detectedState = [string]$verificationResult.DetectedState.UpdatesPause
    $completedAt = Get-Date
    $data = [pscustomobject]@{
        CommandStatus                    = $commandStatus
        ExpectedUpdatesPauseState        = $expectedState
        DetectedUpdatesPauseState        = $detectedState
        RegistryValuesChecked            = @(
            $script:BoostLabUpdatesPauseDefinitions | ForEach-Object {
                "$($script:BoostLabUpdatesPauseRegistryPath)\$($_.Name)"
            }
        )
        RegistryChangesAttempted         = $registryChanges.ToArray()
        SettingsPageStatus               = $settingsPageStatus
        PauseStartTime                   = $pauseStartTime
        PauseExpiryTime                  = $pauseExpiryTime
        CompletedAt                      = $completedAt
    }

    if ($errors.Count -gt 0) {
        return New-BoostLabUpdatesPauseResult `
            -Success $false `
            -Action $ActionName `
            -Message ("Updates Pause action completed with errors: {0}" -f ($errors -join '; ')) `
            -Data $data `
            -VerificationResult $verificationResult
    }

    $message = if ($verificationResult.Status -eq 'Warning') {
        'Updates Pause command completed, but verification was incomplete.'
    }
    elseif ($verificationResult.Status -eq 'Failed') {
        'Updates Pause command completed, but verification detected an unexpected state.'
    }
    elseif ($alreadyDefault) {
        'Windows Update pause values are already default.'
    }
    elseif ($ActionName -eq 'Apply') {
        'Windows updates paused for 365 days.'
    }
    else {
        'Windows Update pause values restored to default.'
    }

    return New-BoostLabUpdatesPauseResult `
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
        return New-BoostLabUpdatesPauseResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Unsupported action. Only Apply and Default are allowed.'
    }
    if (-not $Confirmed) {
        return New-BoostLabUpdatesPauseResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    return Invoke-BoostLabUpdatesPauseAction -ActionName $ActionName
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
