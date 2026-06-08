Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'widgets'; Title = 'Widgets'; Stage = 'Windows'; Order = 7
    Type = 'action'; RiskLevel = 'low'
    Description = 'Disable Windows Widgets or restore the approved default policy behavior.'
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
$script:BoostLabWidgetProcessNames = @('Widgets', 'WidgetService')
$script:BoostLabPolicyManagerPath = 'HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests'
$script:BoostLabDshPolicyPath = 'HKLM\SOFTWARE\Policies\Microsoft\Dsh'

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

function New-BoostLabWidgetsResult {
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
            'Windows registry policy commands are available for action-specific checks.'
        }
        else {
            'Widgets requires Windows.'
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

function Invoke-BoostLabWidgetsRegistryCommand {
    param(
        [Parameter(Mandatory)]
        [string]$CommandProcessorPath,

        [Parameter(Mandatory)]
        [string]$CommandText,

        [Parameter(Mandatory)]
        [string]$Description
    )

    $output = & $CommandProcessorPath /c $CommandText 2>&1
    if ($LASTEXITCODE -ne 0) {
        $detail = (@($output) -join ' ').Trim()
        if ([string]::IsNullOrWhiteSpace($detail)) {
            $detail = "reg.exe returned exit code $LASTEXITCODE."
        }

        throw "$Description failed: $detail"
    }
}

function Invoke-BoostLabWidgetsAction {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName
    )

    if (-not (Test-BoostLabAdministrator)) {
        return New-BoostLabWidgetsResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Administrator rights are required to change Widgets policy.'
    }
    if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        return New-BoostLabWidgetsResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Widgets policy could not be changed because the Windows system directory is unavailable.'
    }

    $commandProcessorPath = Join-Path $env:SystemRoot 'System32\cmd.exe'
    if (-not (Test-Path -LiteralPath $commandProcessorPath -PathType Leaf)) {
        return New-BoostLabWidgetsResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Widgets policy could not be changed because cmd.exe was not found.'
    }

    $registryOperations = if ($ActionName -eq 'Apply') {
        @(
            [pscustomobject]@{
                Description = 'Set PolicyManager AllowNewsAndInterests value to 0'
                Command = 'reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" /v "value" /t REG_DWORD /d "0" /f'
            }
            [pscustomobject]@{
                Description = 'Set Dsh AllowNewsAndInterests value to 0'
                Command = 'reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d "0" /f'
            }
        )
    }
    else {
        @(
            [pscustomobject]@{
                Description = 'Set PolicyManager AllowNewsAndInterests value to 1'
                Command = 'reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" /v "value" /t REG_DWORD /d "1" /f'
            }
            [pscustomobject]@{
                Description = 'Remove the Dsh Widgets blocking policy key'
                Command = 'reg delete "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /f'
            }
        )
    }

    $registryChangesAttempted = [System.Collections.Generic.List[string]]::new()
    $registryChangesCompleted = [System.Collections.Generic.List[string]]::new()
    $processesStopped = [System.Collections.Generic.List[string]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()

    foreach ($operation in $registryOperations) {
        $registryChangesAttempted.Add([string]$operation.Description)
        try {
            Invoke-BoostLabWidgetsRegistryCommand `
                -CommandProcessorPath $commandProcessorPath `
                -CommandText ([string]$operation.Command) `
                -Description ([string]$operation.Description)
            $registryChangesCompleted.Add([string]$operation.Description)
        }
        catch {
            $errors.Add($_.Exception.Message)
        }
    }

    if ($ActionName -eq 'Apply') {
        foreach ($processName in $script:BoostLabWidgetProcessNames) {
            $runningProcesses = @(Get-Process -Name $processName -ErrorAction SilentlyContinue)
            if ($runningProcesses.Count -eq 0) {
                continue
            }

            try {
                Stop-Process -Force -Name $processName -ErrorAction Stop
                $processesStopped.Add($processName)
            }
            catch {
                if (@(Get-Process -Name $processName -ErrorAction SilentlyContinue).Count -gt 0) {
                    $errors.Add("Stopping $processName failed: $($_.Exception.Message)")
                }
            }
        }
    }

    $completedAt = Get-Date
    $data = [pscustomobject]@{
        RegistryChangesAttempted = $registryChangesAttempted.ToArray()
        RegistryChangesCompleted = $registryChangesCompleted.ToArray()
        ProcessesStopped         = $processesStopped.ToArray()
        CompletedAt              = $completedAt
    }

    if ($errors.Count -gt 0) {
        return New-BoostLabWidgetsResult `
            -Success $false `
            -Action $ActionName `
            -Message ("Widgets action completed with errors: {0}" -f ($errors -join '; ')) `
            -Data $data
    }

    $message = if ($ActionName -eq 'Apply') {
        'Widgets disabled.'
    }
    else {
        'Widgets restored to default.'
    }
    return New-BoostLabWidgetsResult `
        -Success $true `
        -Action $ActionName `
        -Message $message `
        -Data $data
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
        return New-BoostLabWidgetsResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Unsupported action. Only Apply and Default are allowed.'
    }
    if (-not $Confirmed) {
        return New-BoostLabWidgetsResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    return Invoke-BoostLabWidgetsAction -ActionName $ActionName
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
