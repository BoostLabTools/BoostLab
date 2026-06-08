Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'restore-point'; Title = 'Restore Point'; Stage = 'Windows'; Order = 23
    Type = 'action'; RiskLevel = 'medium'
    Description = 'Create an approved Windows restore point or open System Protection and System Restore.'
    Actions = @('Apply', 'Open')
    Capabilities = [ordered]@{
        RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false
        CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false
        CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false
        CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false
        SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Apply', 'Open')
$script:BoostLabRestorePointName = 'backup'
$script:BoostLabRestorePointType = 'MODIFY_SETTINGS'
$script:BoostLabRestoreDrive = 'C:\'

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

function New-BoostLabRestorePointResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$Message,

        [bool]$Cancelled = $false,

        [AllowNull()]
        [object]$Data = $null
    )

    return [pscustomobject]@{
        Success         = $Success
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        Action          = $Action
        Message         = $Message
        RestartRequired = $false
        Cancelled       = $Cancelled
        Timestamp       = Get-Date
        Data            = $Data
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
    param()

    $isWindows = $env:OS -eq 'Windows_NT'
    return [pscustomobject]@{
        Supported = $isWindows
        ToolId    = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason    = if ($isWindows) {
            'Windows System Restore and recovery interfaces are available for action-specific checks.'
        }
        else {
            'Restore Point requires Windows.'
        }
        Timestamp = Get-Date
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $commandsAvailable = (
        $null -ne (Get-Command -Name 'Enable-ComputerRestore' -ErrorAction SilentlyContinue) -and
        $null -ne (Get-Command -Name 'Checkpoint-Computer' -ErrorAction SilentlyContinue)
    )
    return [pscustomobject]@{
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        Status          = if ($commandsAvailable) { 'Ready' } else { 'System Restore unavailable' }
        LastAction      = $null
        LastResult      = $null
        RestartRequired = $false
        Timestamp       = Get-Date
    }
}

function Invoke-BoostLabRestorePointApply {
    if (-not (Test-BoostLabAdministrator)) {
        return New-BoostLabRestorePointResult `
            -Success $false `
            -Action 'Apply' `
            -Message 'Administrator rights are required to create a restore point.'
    }

    foreach ($commandName in @('Enable-ComputerRestore', 'Checkpoint-Computer')) {
        if ($null -eq (Get-Command -Name $commandName -ErrorAction SilentlyContinue)) {
            return New-BoostLabRestorePointResult `
                -Success $false `
                -Action 'Apply' `
                -Message "Windows System Restore is unavailable because $commandName was not found."
        }
    }
    if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        return New-BoostLabRestorePointResult `
            -Success $false `
            -Action 'Apply' `
            -Message 'Windows System Restore is unavailable because the Windows system directory could not be determined.'
    }

    $commandProcessorPath = Join-Path $env:SystemRoot 'System32\cmd.exe'
    if (-not (Test-Path -LiteralPath $commandProcessorPath -PathType Leaf)) {
        return New-BoostLabRestorePointResult `
            -Success $false `
            -Action 'Apply' `
            -Message 'Windows System Restore is unavailable because cmd.exe was not found.'
    }

    $frequencyOverrideSet = $false
    $systemRestoreEnabled = $false
    $restorePointCreated = $false
    $createdAt = $null
    $operationError = ''
    $cleanupError = ''
    $frequencyAddCommand = 'reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "SystemRestorePointCreationFrequency" /t REG_DWORD /d "0" /f'
    $frequencyDeleteCommand = 'reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "SystemRestorePointCreationFrequency" /f'

    try {
        $null = & $commandProcessorPath /c $frequencyAddCommand 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "The temporary restore-point frequency override could not be set. reg.exe returned exit code $LASTEXITCODE."
        }
        $frequencyOverrideSet = $true

        Enable-ComputerRestore -Drive $script:BoostLabRestoreDrive -ErrorAction Stop | Out-Null
        $systemRestoreEnabled = $true
        Checkpoint-Computer `
            -Description $script:BoostLabRestorePointName `
            -RestorePointType $script:BoostLabRestorePointType `
            -ErrorAction Stop | Out-Null

        $restorePointCreated = $true
        $createdAt = Get-Date
    }
    catch {
        $operationError = $_.Exception.Message
    }
    finally {
        if ($frequencyOverrideSet) {
            $null = & $commandProcessorPath /c $frequencyDeleteCommand 2>&1
            if ($LASTEXITCODE -ne 0) {
                $cleanupError = "The temporary restore-point frequency override could not be removed. reg.exe returned exit code $LASTEXITCODE."
            }
        }
    }

    $data = [pscustomobject]@{
        RestorePointName     = $script:BoostLabRestorePointName
        RestorePointType     = $script:BoostLabRestorePointType
        Drive                = $script:BoostLabRestoreDrive
        SystemRestoreEnabled = $systemRestoreEnabled
        RestorePointCreated  = $restorePointCreated
        CreatedAt            = $createdAt
    }

    if (-not [string]::IsNullOrWhiteSpace($operationError)) {
        return New-BoostLabRestorePointResult `
            -Success $false `
            -Action 'Apply' `
            -Message "Restore point creation failed: $operationError" `
            -Data $data
    }
    if (-not [string]::IsNullOrWhiteSpace($cleanupError)) {
        return New-BoostLabRestorePointResult `
            -Success $false `
            -Action 'Apply' `
            -Message "Restore point created, but cleanup failed: $cleanupError" `
            -Data $data
    }

    return New-BoostLabRestorePointResult `
        -Success $true `
        -Action 'Apply' `
        -Message 'Restore point created.' `
        -Data $data
}

function Invoke-BoostLabRestorePointOpen {
    if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        return New-BoostLabRestorePointResult `
            -Success $false `
            -Action 'Open' `
            -Message 'Windows recovery interfaces could not be opened because the Windows system directory is unavailable.'
    }

    try {
        Start-Process "$env:SystemRoot\system32\control.exe" -ArgumentList "sysdm.cpl,,4"
        Start-Process "rstrui"
        return New-BoostLabRestorePointResult `
            -Success $true `
            -Action 'Open' `
            -Message 'System Protection and System Restore opened.' `
            -Data ([pscustomobject]@{
                Interfaces = @('System Protection', 'System Restore')
            })
    }
    catch {
        return New-BoostLabRestorePointResult `
            -Success $false `
            -Action 'Open' `
            -Message "Windows recovery interfaces could not be opened: $($_.Exception.Message)"
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
        return New-BoostLabRestorePointResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Unsupported action. Only Apply and Open are allowed.'
    }

    if ($ActionName -eq 'Apply') {
        if (-not $Confirmed) {
            return New-BoostLabRestorePointResult `
                -Success $false `
                -Action 'Apply' `
                -Message 'Cancelled by user' `
                -Cancelled $true
        }

        return Invoke-BoostLabRestorePointApply
    }

    return Invoke-BoostLabRestorePointOpen
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return New-BoostLabRestorePointResult `
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
