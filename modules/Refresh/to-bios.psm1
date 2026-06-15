Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'to-bios'; Title = 'To BIOS'; Stage = 'Refresh'; Order = 4
    Type = 'assistant'; RiskLevel = 'high'
    Description = 'Review restart guidance before opening Windows firmware startup options.'
    Actions = @('Analyze', 'Open')
    Capabilities = [ordered]@{
        RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $true
        CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false
        CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false
        CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false
        SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Analyze', 'Open')
$script:BoostLabFirmwareConfirmationText = 'This PC will restart immediately and attempt to enter BIOS/UEFI firmware settings. Save your work before continuing. Do you want to proceed?'

function New-BoostLabToBiosVerificationResult {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Passed', 'Warning', 'Failed', 'NotApplicable')]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$ExpectedState,

        [Parameter(Mandatory)]
        [string]$DetectedState,

        [Parameter(Mandatory)]
        [string]$Message,

        [object[]]$Checks = @()
    )

    return [pscustomobject]@{
        ToolId        = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle     = [string]$script:BoostLabToolMetadata['Title']
        Action        = 'Open'
        Status        = $Status
        ExpectedState = $ExpectedState
        DetectedState = $DetectedState
        Checks        = @($Checks)
        Message       = $Message
        Timestamp     = Get-Date
    }
}

function New-BoostLabToBiosResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$Message,

        [string]$CommandStatus = 'Not started',

        [string]$VerificationStatus = 'NotApplicable',

        [bool]$RestartRequired = $false,

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
        Status             = if ($Success) { 'Success' } elseif ($Cancelled) { 'Cancelled' } else { 'Failed' }
        CommandStatus      = $CommandStatus
        VerificationStatus = $VerificationStatus
        Message            = $Message
        RestartRequired    = $RestartRequired
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
        Id                          = [string]$script:BoostLabToolMetadata['Id']
        Title                       = [string]$script:BoostLabToolMetadata['Title']
        Stage                       = [string]$script:BoostLabToolMetadata['Stage']
        Order                       = [int]$script:BoostLabToolMetadata['Order']
        Type                        = [string]$script:BoostLabToolMetadata['Type']
        RiskLevel                   = [string]$script:BoostLabToolMetadata['RiskLevel']
        Description                 = [string]$script:BoostLabToolMetadata['Description']
        Actions                     = @($script:BoostLabToolMetadata['Actions'])
        Capabilities                = [pscustomobject]$script:BoostLabToolMetadata['Capabilities']
        ImplementedActions          = @($script:BoostLabImplementedActions)
        ConfirmationRequiredActions = @('Open')
        ConfirmationText            = $script:BoostLabFirmwareConfirmationText
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $supported = (
        -not [string]::IsNullOrWhiteSpace($env:SystemRoot) -and
        (Test-Path -LiteralPath (Join-Path $env:SystemRoot 'System32\cmd.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $env:SystemRoot 'System32\shutdown.exe') -PathType Leaf)
    )

    return [pscustomobject]@{
        Supported = $supported
        ToolId    = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason    = if ($supported) {
            'The Windows command processor and firmware restart command are available.'
        }
        else {
            'The required Windows firmware restart commands are unavailable.'
        }
        Timestamp = Get-Date
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        Status          = 'Ready'
        LastAction      = $null
        LastResult      = $null
        RestartRequired = $false
        Timestamp       = Get-Date
    }
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
        return New-BoostLabToBiosResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Unsupported action. Only Analyze and Open are allowed.'
    }

    if ($ActionName -eq 'Analyze') {
        return New-BoostLabToBiosResult `
            -Success $true `
            -Action 'Analyze' `
            -CommandStatus 'Read only' `
            -Message 'Firmware restart guidance prepared.' `
            -Data ([pscustomobject]@{
                CommandStatus        = 'Read only'
                VerificationStatus   = 'NotApplicable'
                RestartBehavior      = 'Restart Windows immediately and request BIOS/UEFI firmware settings.'
                ApprovedCommand      = 'cmd /c C:\Windows\System32\shutdown.exe /r /fw /t 0'
                ConfirmationRequired = $true
                Warnings             = @(
                    'Save all work before continuing.'
                    'The confirmed Open action restarts the PC immediately.'
                    'Windows and the system firmware must support restart-to-firmware.'
                    'BoostLab does not modify BIOS settings.'
                )
                CompletedAt          = Get-Date
            })
    }

    if (-not $Confirmed) {
        return New-BoostLabToBiosResult `
            -Success $false `
            -Action 'Open' `
            -CommandStatus 'Cancelled' `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        return New-BoostLabToBiosResult `
            -Success $false `
            -Action 'Open' `
            -CommandStatus 'Failed' `
            -VerificationStatus 'Failed' `
            -Message 'Cannot enter BIOS/UEFI because the Windows system directory is unavailable.'
    }

    $commandProcessorPath = Join-Path $env:SystemRoot 'System32\cmd.exe'
    $shutdownPath = Join-Path $env:SystemRoot 'System32\shutdown.exe'
    if (
        -not (Test-Path -LiteralPath $commandProcessorPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $shutdownPath -PathType Leaf)
    ) {
        return New-BoostLabToBiosResult `
            -Success $false `
            -Action 'Open' `
            -CommandStatus 'Failed' `
            -VerificationStatus 'Failed' `
            -Message 'Cannot enter BIOS/UEFI because the required Windows system command was not found.'
    }

    $firmwareRestartCommand = "`"$shutdownPath`" /r /fw /t 0"
    $firmwareRestartArguments = @('/c', $firmwareRestartCommand)
    try {
        & $commandProcessorPath @firmwareRestartArguments
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            return New-BoostLabToBiosResult `
                -Success $false `
                -Action 'Open' `
                -CommandStatus 'Failed' `
                -VerificationStatus 'Failed' `
                -Message "Windows could not schedule a restart to BIOS/UEFI. shutdown.exe returned exit code $exitCode."
        }

        $verification = New-BoostLabToBiosVerificationResult `
            -Status 'Passed' `
            -ExpectedState 'Windows accepts the approved restart-to-firmware request.' `
            -DetectedState 'shutdown.exe returned exit code 0.' `
            -Message 'The firmware restart request was accepted by Windows.' `
            -Checks @(
                [pscustomobject]@{
                    Name     = 'Firmware restart request'
                    Expected = 'shutdown.exe exit code 0'
                    Actual   = 'shutdown.exe exit code 0'
                    Status   = 'Passed'
                    Message  = 'Windows accepted the source-defined restart-to-firmware command.'
                }
            )

        return New-BoostLabToBiosResult `
            -Success $true `
            -Action 'Open' `
            -CommandStatus 'Restart requested' `
            -VerificationStatus 'Passed' `
            -Message 'Restart to BIOS/UEFI requested' `
            -RestartRequired $true `
            -VerificationResult $verification `
            -Data ([pscustomobject]@{
                CommandStatus      = 'Restart requested'
                VerificationStatus = 'Passed'
                Executable         = $commandProcessorPath
                Arguments          = @($firmwareRestartArguments)
                CompletedAt        = Get-Date
            })
    }
    catch {
        return New-BoostLabToBiosResult `
            -Success $false `
            -Action 'Open' `
            -CommandStatus 'Failed' `
            -VerificationStatus 'Failed' `
            -Message "Windows could not schedule a restart to BIOS/UEFI: $($_.Exception.Message)"
    }
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return New-BoostLabToBiosResult `
        -Success $false `
        -Action 'Default' `
        -Message 'Action is not declared for this tool.'
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
