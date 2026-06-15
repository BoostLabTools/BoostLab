Set-StrictMode -Version Latest

Import-Module `
    -Name (Join-Path $PSScriptRoot 'DriverState.psm1') `
    -Scope Local `
    -ErrorAction Stop

function New-BoostLabDriverExecutionResult {
    param(
        [Parameter(Mandatory)]
        [string]$Status,

        [AllowNull()]
        [object]$Plan,

        [Parameter(Mandatory)]
        [string]$Message,

        [AllowNull()]
        [object]$Verification,

        [AllowNull()]
        [object[]]$Errors
    )

    return [pscustomobject][ordered]@{
        Success               = $Status -in @('Passed', 'Warning')
        Status                = $Status
        OperationId           = if ($null -ne $Plan) {
            [string]$Plan.OperationId
        }
        else {
            ''
        }
        ToolId                = if ($null -ne $Plan) {
            [string]$Plan.ToolId
        }
        else {
            ''
        }
        ActionId              = if ($null -ne $Plan) {
            [string]$Plan.ActionId
        }
        else {
            ''
        }
        DeviceInstanceId      = if ($null -ne $Plan) {
            [string]$Plan.DeviceInstanceId
        }
        else {
            ''
        }
        DriverPackageIdentity = if ($null -ne $Plan) {
            [string]$Plan.DriverPackageIdentity
        }
        else {
            ''
        }
        MutationType          = if ($null -ne $Plan) {
            [string]$Plan.MutationType
        }
        else {
            ''
        }
        ExecutionAttempted    = $Status -in @('Passed', 'Warning', 'Failed')
        Verification          = $Verification
        Message               = $Message
        Errors                = @($Errors)
        Timestamp             = Get-Date
    }
}

function Test-BoostLabDriverExecutionRequest {
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
        $errors.Add('Driver mutation plan is missing.')
    }
    else {
        if (-not [bool]$Plan.IsAllowed -or [string]$Plan.Status -ne 'Allowed') {
            $errors.Add('Driver mutation plan is not approved.')
            $errors.AddRange([string[]]@($Plan.Errors))
        }
        if (-not [bool]$Plan.IsDryRun) {
            $errors.Add('Driver execution requires a validated dry-run plan.')
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
            $errors.Add('Driver execution requires explicit confirmation.')
        }
    }
    if (-not $Confirmed) {
        $errors.Add('Driver execution requires explicit user confirmation.')
    }

    return [pscustomobject]@{
        IsAllowed = $errors.Count -eq 0
        Status    = if ($errors.Count -eq 0) { 'Validated' } else { 'Blocked' }
        Errors    = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function Invoke-BoostLabDriverMutation {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Plan,

        [Parameter(Mandatory)]
        [object]$ActionPlan,

        [bool]$Confirmed,

        [Parameter(Mandatory)]
        [scriptblock]$MutationExecutor,

        [Parameter(Mandatory)]
        [scriptblock]$MutationVerifier,

        [Parameter(Mandatory)]
        [string]$RecordPath,

        [Parameter(Mandatory)]
        [string]$StateRoot,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    $request = Test-BoostLabDriverExecutionRequest `
        -Plan $Plan `
        -ActionPlan $ActionPlan `
        -Confirmed:$Confirmed `
        -Policy $Policy
    if (-not $request.IsAllowed) {
        return New-BoostLabDriverExecutionResult `
            -Status 'Blocked' `
            -Plan $Plan `
            -Message 'Driver mutation was blocked by policy.' `
            -Verification $null `
            -Errors @($request.Errors)
    }

    try {
        $executionResult = & $MutationExecutor $Plan
        if (
            $null -eq $executionResult -or
            -not [bool]$executionResult.Success
        ) {
            throw 'Injected driver mutation executor did not report success.'
        }
        $verification = & $MutationVerifier $Plan $executionResult
        $verificationStatus = [string]$verification.Status
        if ($verificationStatus -notin @('Passed', 'Warning')) {
            return New-BoostLabDriverExecutionResult `
                -Status 'Failed' `
                -Plan $Plan `
                -Message 'Driver mutation verification failed.' `
                -Verification $verification `
                -Errors @('Driver mutation verification did not pass.')
        }
        $persisted = Set-BoostLabDriverMutationState `
            -RecordPath $RecordPath `
            -StateRoot $StateRoot `
            -PostMutationState $executionResult.PostMutationState `
            -VerificationResult $verification
        if (-not $persisted.Success) {
            return New-BoostLabDriverExecutionResult `
                -Status 'Failed' `
                -Plan $Plan `
                -Message 'Driver mutation completed but state persistence failed.' `
                -Verification $verification `
                -Errors @($persisted.Errors)
        }

        return New-BoostLabDriverExecutionResult `
            -Status $verificationStatus `
            -Plan $Plan `
            -Message 'Injected driver mutation completed and was verified.' `
            -Verification $verification `
            -Errors @()
    }
    catch {
        return New-BoostLabDriverExecutionResult `
            -Status 'Failed' `
            -Plan $Plan `
            -Message 'Driver mutation callback failed.' `
            -Verification $null `
            -Errors @($_.Exception.Message)
    }
}

function Test-BoostLabDriverRollbackRequest {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [object]$Plan,

        [AllowNull()]
        [object]$ActionPlan,

        [bool]$Confirmed
    )

    return Test-BoostLabDriverExecutionRequest `
        -Plan $Plan `
        -ActionPlan $ActionPlan `
        -Confirmed:$Confirmed
}

function Invoke-BoostLabDriverRollback {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Plan,

        [Parameter(Mandatory)]
        [object]$ActionPlan,

        [bool]$Confirmed,

        [Parameter(Mandatory)]
        [scriptblock]$RollbackExecutor,

        [Parameter(Mandatory)]
        [scriptblock]$RollbackVerifier,

        [Parameter(Mandatory)]
        [string]$RecordPath,

        [Parameter(Mandatory)]
        [string]$StateRoot
    )

    $request = Test-BoostLabDriverRollbackRequest `
        -Plan $Plan `
        -ActionPlan $ActionPlan `
        -Confirmed:$Confirmed
    if (-not $request.IsAllowed) {
        return New-BoostLabDriverExecutionResult `
            -Status 'Blocked' `
            -Plan $Plan `
            -Message 'Driver rollback was blocked by policy.' `
            -Verification $null `
            -Errors @($request.Errors)
    }

    try {
        $executionResult = & $RollbackExecutor $Plan
        if (
            $null -eq $executionResult -or
            -not [bool]$executionResult.Success
        ) {
            throw 'Injected driver rollback executor did not report success.'
        }
        $verification = & $RollbackVerifier $Plan $executionResult
        $verificationStatus = [string]$verification.Status
        if ($verificationStatus -notin @('Passed', 'Warning')) {
            return New-BoostLabDriverExecutionResult `
                -Status 'Failed' `
                -Plan $Plan `
                -Message 'Driver rollback verification failed.' `
                -Verification $verification `
                -Errors @('Driver rollback verification did not pass.')
        }
        $persisted = Set-BoostLabDriverRollbackState `
            -RecordPath $RecordPath `
            -StateRoot $StateRoot `
            -PostRollbackState $executionResult.PostRollbackState `
            -VerificationResult $verification
        if (-not $persisted.Success) {
            return New-BoostLabDriverExecutionResult `
                -Status 'Failed' `
                -Plan $Plan `
                -Message 'Driver rollback completed but state persistence failed.' `
                -Verification $verification `
                -Errors @($persisted.Errors)
        }

        return New-BoostLabDriverExecutionResult `
            -Status $verificationStatus `
            -Plan $Plan `
            -Message 'Injected driver rollback completed and was verified.' `
            -Verification $verification `
            -Errors @()
    }
    catch {
        return New-BoostLabDriverExecutionResult `
            -Status 'Failed' `
            -Plan $Plan `
            -Message 'Driver rollback callback failed.' `
            -Verification $null `
            -Errors @($_.Exception.Message)
    }
}

Export-ModuleMember -Function @(
    'Test-BoostLabDriverExecutionRequest'
    'Invoke-BoostLabDriverMutation'
    'Test-BoostLabDriverRollbackRequest'
    'Invoke-BoostLabDriverRollback'
)
