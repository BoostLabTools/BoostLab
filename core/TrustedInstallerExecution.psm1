Set-StrictMode -Version Latest

Import-Module `
    -Name (Join-Path $PSScriptRoot 'TrustedInstaller.psm1') `
    -Scope Local `
    -ErrorAction Stop

function New-BoostLabTrustedInstallerExecutionResult {
    param(
        [Parameter(Mandatory)]
        [string]$Status,

        [AllowNull()]
        [object]$Request,

        [Parameter(Mandatory)]
        [string]$Message,

        [AllowNull()]
        [object]$Verification,

        [AllowNull()]
        [object[]]$Errors
    )

    $targetScope = if ($null -ne $Request) {
        $Request.Targets | ConvertTo-Json -Compress -Depth 10
    }
    else {
        ''
    }
    return [pscustomobject][ordered]@{
        Success            = $false
        Status             = $Status
        OperationId        = if ($null -ne $Request) {
            [string]$Request.OperationId
        }
        else {
            ''
        }
        ToolId             = if ($null -ne $Request) {
            [string]$Request.ToolId
        }
        else {
            ''
        }
        ActionId           = if ($null -ne $Request) {
            [string]$Request.ActionId
        }
        else {
            ''
        }
        RequestedIdentity  = if ($null -ne $Request) {
            [string]$Request.RequestedExecutionIdentity
        }
        else {
            'NT SERVICE\TrustedInstaller'
        }
        CommandId          = if ($null -ne $Request) {
            [string]$Request.RequestedCommandId
        }
        else {
            ''
        }
        TargetScope        = $targetScope
        ProcessStarted     = $false
        CommandExecuted    = $false
        Verification       = $Verification
        Message            = $Message
        Errors             = @($Errors)
        LogEntries         = @(
            [pscustomobject]@{
                Level       = 'Warning'
                Identity    = if ($null -ne $Request) {
                    [string]$Request.RequestedExecutionIdentity
                }
                else {
                    'NT SERVICE\TrustedInstaller'
                }
                CommandId   = if ($null -ne $Request) {
                    [string]$Request.RequestedCommandId
                }
                else {
                    ''
                }
                TargetScope = $targetScope
                Message     = $Message
            }
        )
        Timestamp          = Get-Date
    }
}

function Test-BoostLabTrustedInstallerExecutionRequest {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [object]$Request,

        [AllowNull()]
        [object]$ActionPlan,

        [bool]$Confirmed,

        [bool]$AdministratorHostVerified,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $validation = Test-BoostLabTrustedInstallerRequest `
        -Request $Request `
        -Policy $Policy
    if (-not $validation.IsAllowed) {
        $errors.AddRange([string[]]@($validation.Errors))
    }
    if ($null -eq $ActionPlan) {
        $errors.Add('A matching Action Plan is required for execution.')
    }
    elseif ($null -ne $Request) {
        if ([string]$ActionPlan.ToolId -ne [string]$Request.ToolId) {
            $errors.Add('Execution Action Plan tool identity does not match.')
        }
        if ([string]$ActionPlan.Action -ne [string]$Request.ActionId) {
            $errors.Add('Execution Action Plan action identity does not match.')
        }
        if (
            -not [bool]$ActionPlan.NeedsExplicitConfirmation -or
            -not [bool]$ActionPlan.UsesTrustedInstaller
        ) {
            $errors.Add(
                'Execution Action Plan lacks TrustedInstaller confirmation metadata.'
            )
        }
    }
    if (-not $Confirmed) {
        $errors.Add('Execution requires explicit confirmation.')
    }
    if (-not $AdministratorHostVerified) {
        $errors.Add('Execution requires a verified Administrator host.')
    }
    return [pscustomobject]@{
        IsAllowed = $errors.Count -eq 0
        Status    = if ($errors.Count -eq 0) { 'Validated' } else { 'Blocked' }
        Errors    = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function Test-BoostLabTrustedInstallerMockResult {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [object]$ExecutionResult,

        [Parameter(Mandatory)]
        [object]$Request
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    if ($null -eq $ExecutionResult) {
        $errors.Add('Mock execution returned no result.')
    }
    else {
        if ([bool]$ExecutionResult.ProcessStarted) {
            $errors.Add('Mock result must not start a real process.')
        }
        if ([bool]$ExecutionResult.CommandExecuted) {
            $errors.Add('Mock result must not claim command execution.')
        }
        if (-not [bool]$ExecutionResult.Simulated) {
            $errors.Add('Mock result must be marked Simulated.')
        }
        if (
            [string]$ExecutionResult.CommandId -ne
            [string]$Request.RequestedCommandId
        ) {
            $errors.Add('Mock result command identity mismatch.')
        }
        if (
            [string]$ExecutionResult.Status -notin @(
                'Passed'
                'Warning'
                'Failed'
            )
        ) {
            $errors.Add('Mock result status is unsupported.')
        }
    }
    return [pscustomobject]@{
        IsValid = $errors.Count -eq 0
        Status  = if ($errors.Count -eq 0) { 'Valid' } else { 'Blocked' }
        Errors  = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function Invoke-BoostLabTrustedInstallerRequest {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Request,

        [Parameter(Mandatory)]
        [object]$ActionPlan,

        [bool]$Confirmed,

        [bool]$AdministratorHostVerified,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    $validation = Test-BoostLabTrustedInstallerExecutionRequest `
        -Request $Request `
        -ActionPlan $ActionPlan `
        -Confirmed:$Confirmed `
        -AdministratorHostVerified:$AdministratorHostVerified `
        -Policy $Policy
    if (-not $validation.IsAllowed) {
        return New-BoostLabTrustedInstallerExecutionResult `
            -Status 'Blocked' `
            -Request $Request `
            -Message 'TrustedInstaller execution request was refused.' `
            -Verification $null `
            -Errors @($validation.Errors)
    }

    return New-BoostLabTrustedInstallerExecutionResult `
        -Status 'NotImplemented' `
        -Request $Request `
        -Message (
            'TrustedInstaller process execution is intentionally unavailable ' +
            'in the Phase 42 foundation.'
        ) `
        -Verification $null `
        -Errors @()
}

Export-ModuleMember -Function @(
    'Test-BoostLabTrustedInstallerExecutionRequest'
    'Test-BoostLabTrustedInstallerMockResult'
    'Invoke-BoostLabTrustedInstallerRequest'
)
