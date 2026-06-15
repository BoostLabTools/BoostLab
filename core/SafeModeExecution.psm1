Set-StrictMode -Version Latest

Import-Module `
    -Name (Join-Path $PSScriptRoot 'SafeModeWorkflow.psm1') `
    -Scope Local `
    -ErrorAction Stop

function New-BoostLabSafeModeExecutionResult {
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

    return [pscustomobject][ordered]@{
        Success                 = $false
        Status                  = $Status
        OperationId             = if ($null -ne $Plan) {
            [string]$Plan.OperationId
        }
        else {
            ''
        }
        ToolId                  = if ($null -ne $Plan) {
            [string]$Plan.ToolId
        }
        else {
            ''
        }
        ActionId                = if ($null -ne $Plan) {
            [string]$Plan.ActionId
        }
        else {
            ''
        }
        RequestedSafeModeType   = if ($null -ne $Plan) {
            [string]$Plan.RequestedSafeModeType
        }
        else {
            ''
        }
        SafeModeConfigured      = $false
        BcdModified             = $false
        RebootInitiated         = $false
        ScheduleCreated         = $false
        ServiceChanged          = $false
        TrustedInstallerUsed    = $false
        ProtectedTargetModified = $false
        Message                 = $Message
        Errors                  = @($Errors)
        Timestamp               = Get-Date
    }
}

function Test-BoostLabSafeModeExecutionRequest {
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
        $errors.Add('Safe Mode workflow plan is missing.')
    }
    else {
        if (-not [bool]$Plan.IsAllowed -or [string]$Plan.Status -ne 'Allowed') {
            $errors.Add('Safe Mode workflow plan is not approved.')
            $errors.AddRange([string[]]@($Plan.Errors))
        }
        if (-not [bool]$Plan.IsDryRun) {
            $errors.Add('Safe Mode execution requires a validated dry-run plan.')
        }
        $target = Test-BoostLabSafeModeWorkflowTarget `
            -ToolId ([string]$Plan.ToolId) `
            -ActionId ([string]$Plan.ActionId) `
            -ScopeId ([string]$Plan.ScopeId) `
            -SafeModeType ([string]$Plan.RequestedSafeModeType) `
            -Policy $Policy
        if (-not $target.IsAllowed) {
            $errors.AddRange([string[]]@($target.Errors))
        }
        if (@($Plan.PlannedResumeSteps).Count -eq 0) {
            $errors.Add('A bounded Safe Mode resume plan is required.')
        }
        if (@($Plan.PlannedExitStrategy).Count -eq 0) {
            $errors.Add('A Safe Mode exit plan is required before entry.')
        }
        if ($null -eq $Plan.RebootWorkflowReference) {
            $errors.Add('A verified Phase 40 reboot workflow is required.')
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
        if (
            -not [bool]$ActionPlan.NeedsExplicitConfirmation -or
            -not [bool]$ActionPlan.UsesSafeMode
        ) {
            $errors.Add(
                'Action Plan lacks Safe Mode confirmation metadata.'
            )
        }
    }
    if (-not $Confirmed) {
        $errors.Add('Safe Mode execution requires explicit confirmation.')
    }
    return [pscustomobject]@{
        IsAllowed = $errors.Count -eq 0
        Status    = if ($errors.Count -eq 0) { 'Validated' } else { 'Blocked' }
        Errors    = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function Invoke-BoostLabSafeModeEntryRequest {
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

    $validation = Test-BoostLabSafeModeExecutionRequest `
        -Plan $Plan `
        -ActionPlan $ActionPlan `
        -Confirmed:$Confirmed `
        -Policy $Policy
    if (-not $validation.IsAllowed) {
        return New-BoostLabSafeModeExecutionResult `
            -Status 'Blocked' `
            -Plan $Plan `
            -Message 'Safe Mode entry request was blocked by policy.' `
            -Errors @($validation.Errors)
    }
    return New-BoostLabSafeModeExecutionResult `
        -Status 'NotImplemented' `
        -Plan $Plan `
        -Message (
            'Safe Mode entry, BCD changes, and reboot execution are ' +
            'intentionally unavailable in the Phase 43 foundation.'
        ) `
        -Errors @()
}

function Register-BoostLabSafeModeResume {
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

    $validation = Test-BoostLabSafeModeExecutionRequest `
        -Plan $Plan `
        -ActionPlan $ActionPlan `
        -Confirmed:$Confirmed `
        -Policy $Policy
    if (-not $validation.IsAllowed) {
        return New-BoostLabSafeModeExecutionResult `
            -Status 'Blocked' `
            -Plan $Plan `
            -Message 'Safe Mode resume scheduling was blocked by policy.' `
            -Errors @($validation.Errors)
    }
    return New-BoostLabSafeModeExecutionResult `
        -Status 'NotImplemented' `
        -Plan $Plan `
        -Message (
            'RunOnce, Scheduled Task, and service-based Safe Mode resume are ' +
            'intentionally unavailable in the Phase 43 foundation.'
        ) `
        -Errors @()
}

function Invoke-BoostLabSafeModeExitRequest {
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

    $validation = Test-BoostLabSafeModeExecutionRequest `
        -Plan $Plan `
        -ActionPlan $ActionPlan `
        -Confirmed:$Confirmed `
        -Policy $Policy
    if (-not $validation.IsAllowed) {
        return New-BoostLabSafeModeExecutionResult `
            -Status 'Blocked' `
            -Plan $Plan `
            -Message 'Safe Mode exit request was blocked by policy.' `
            -Errors @($validation.Errors)
    }
    return New-BoostLabSafeModeExecutionResult `
        -Status 'NotImplemented' `
        -Plan $Plan `
        -Message (
            'Safe Mode exit and boot-state restoration are intentionally ' +
            'unavailable in the Phase 43 foundation.'
        ) `
        -Errors @()
}

Export-ModuleMember -Function @(
    'Test-BoostLabSafeModeExecutionRequest'
    'Invoke-BoostLabSafeModeEntryRequest'
    'Register-BoostLabSafeModeResume'
    'Invoke-BoostLabSafeModeExitRequest'
)
