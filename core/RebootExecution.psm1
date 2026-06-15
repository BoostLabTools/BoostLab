Set-StrictMode -Version Latest

Import-Module `
    -Name (Join-Path $PSScriptRoot 'RebootWorkflow.psm1') `
    -Scope Local `
    -ErrorAction Stop

function New-BoostLabRebootExecutionResult {
    param(
        [Parameter(Mandatory)]
        [string]$Status,

        [AllowNull()]
        [object]$Plan,

        [Parameter(Mandatory)]
        [string]$Message,

        [AllowNull()]
        [object[]]$Errors
    )

    return [pscustomobject]@{
        Success          = $false
        Status           = $Status
        OperationId      = [string]$Plan.OperationId
        ToolId           = [string]$Plan.ToolId
        ActionId         = [string]$Plan.ActionId
        RequestedRebootType = [string]$Plan.RequestedRebootType
        RebootInitiated  = $false
        ScheduleCreated  = $false
        Message          = $Message
        Errors           = @($Errors)
        Timestamp        = Get-Date
    }
}

function Test-BoostLabRebootExecutionRequest {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [object]$Plan,

        [AllowNull()]
        [object]$ActionPlan,

        [bool]$Confirmed,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    if ($null -eq $Plan) {
        $errors.Add('Reboot workflow plan is missing.')
    }
    else {
        if (-not [bool]$Plan.IsAllowed -or [string]$Plan.Status -ne 'Allowed') {
            $errors.Add('Reboot workflow plan is not approved.')
            $errors.AddRange([string[]]@($Plan.Errors))
        }
        if (-not [bool]$Plan.IsDryRun) {
            $errors.Add('Reboot execution requires a validated dry-run plan.')
        }
        $target = Test-BoostLabRebootWorkflowTarget `
            -ToolId ([string]$Plan.ToolId) `
            -ActionId ([string]$Plan.ActionId) `
            -ScopeId ([string]$Plan.ScopeId) `
            -RebootType ([string]$Plan.RequestedRebootType) `
            -Policy $Policy
        if (-not $target.IsAllowed) {
            $errors.AddRange([string[]]@($target.Errors))
        }
    }
    if ($null -eq $ActionPlan) {
        $errors.Add('A matching Action Plan is required.')
    }
    elseif ($null -ne $Plan) {
        if ([string]$ActionPlan.ToolId -ne [string]$Plan.ToolId) {
            $errors.Add('Action Plan tool identity does not match.')
        }
        if ([string]$ActionPlan.Action -ne [string]$Plan.ActionId) {
            $errors.Add('Action Plan action identity does not match.')
        }
        if (-not [bool]$ActionPlan.NeedsExplicitConfirmation) {
            $errors.Add('Action Plan must require explicit confirmation.')
        }
    }
    if (-not $Confirmed) {
        $errors.Add('Reboot execution requires explicit user confirmation.')
    }

    return [pscustomobject]@{
        IsAllowed = $errors.Count -eq 0
        Status    = if ($errors.Count -eq 0) { 'Validated' } else { 'Blocked' }
        Errors    = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function Invoke-BoostLabRebootRequest {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Plan,

        [Parameter(Mandatory)]
        [object]$ActionPlan,

        [bool]$Confirmed,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    $request = Test-BoostLabRebootExecutionRequest `
        -Plan $Plan `
        -ActionPlan $ActionPlan `
        -Confirmed:$Confirmed `
        -Policy $Policy
    if (-not $request.IsAllowed) {
        return New-BoostLabRebootExecutionResult `
            -Status 'Blocked' `
            -Plan $Plan `
            -Message 'Reboot request was blocked by policy.' `
            -Errors @($request.Errors)
    }

    return New-BoostLabRebootExecutionResult `
        -Status 'NotImplemented' `
        -Plan $Plan `
        -Message (
            'Reboot execution is intentionally unavailable in the Phase 40 ' +
            'foundation.'
        ) `
        -Errors @()
}

function Register-BoostLabPostRebootResume {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Plan,

        [Parameter(Mandatory)]
        [object]$ActionPlan,

        [bool]$Confirmed,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    $request = Test-BoostLabRebootExecutionRequest `
        -Plan $Plan `
        -ActionPlan $ActionPlan `
        -Confirmed:$Confirmed `
        -Policy $Policy
    if (-not $request.IsAllowed) {
        return New-BoostLabRebootExecutionResult `
            -Status 'Blocked' `
            -Plan $Plan `
            -Message 'Post-reboot resume scheduling was blocked by policy.' `
            -Errors @($request.Errors)
    }
    if (@($Plan.PendingResumeSteps).Count -eq 0) {
        return New-BoostLabRebootExecutionResult `
            -Status 'Blocked' `
            -Plan $Plan `
            -Message 'No bounded post-reboot resume steps were recorded.' `
            -Errors @('Resume step list is empty.')
    }

    return New-BoostLabRebootExecutionResult `
        -Status 'NotImplemented' `
        -Plan $Plan `
        -Message (
            'RunOnce and Scheduled Task registration are intentionally ' +
            'unavailable in the Phase 40 foundation.'
        ) `
        -Errors @()
}

Export-ModuleMember -Function @(
    'Test-BoostLabRebootExecutionRequest'
    'Invoke-BoostLabRebootRequest'
    'Register-BoostLabPostRebootResume'
)
