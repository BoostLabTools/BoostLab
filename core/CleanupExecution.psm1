Set-StrictMode -Version Latest

Import-Module `
    -Name (Join-Path $PSScriptRoot 'CleanupPolicy.psm1') `
    -Scope Local `
    -ErrorAction Stop

function Get-BoostLabCleanupExecutionPropertyValue {
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$Name
    )

    if ($null -eq $InputObject) {
        return $null
    }
    if ($InputObject -is [System.Collections.IDictionary]) {
        if ($InputObject.Contains($Name)) {
            return $InputObject[$Name]
        }

        return $null
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function New-BoostLabCleanupBlockedResult {
    param(
        [AllowNull()]
        [object]$Plan,

        [Parameter(Mandatory)]
        [string]$Message,

        [AllowNull()]
        [object[]]$Errors
    )

    return [pscustomobject]@{
        Success          = $false
        Status           = 'Blocked'
        OperationId      = [string](
            Get-BoostLabCleanupExecutionPropertyValue `
                -InputObject $Plan `
                -Name 'OperationId'
        )
        ToolId           = [string](
            Get-BoostLabCleanupExecutionPropertyValue `
                -InputObject $Plan `
                -Name 'ToolId'
        )
        ActionId         = [string](
            Get-BoostLabCleanupExecutionPropertyValue `
                -InputObject $Plan `
                -Name 'ActionId'
        )
        CleanupType      = [string](
            Get-BoostLabCleanupExecutionPropertyValue `
                -InputObject $Plan `
                -Name 'CleanupType'
        )
        TargetPath       = [string](
            Get-BoostLabCleanupExecutionPropertyValue `
                -InputObject $Plan `
                -Name 'ResolvedPath'
        )
        CleanupExecuted  = $false
        QuarantineRecord = $null
        Verification     = $null
        Message          = $Message
        Errors           = @($Errors)
        Timestamp        = Get-Date
    }
}

function Test-BoostLabCleanupExecutionRequest {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [object]$Plan,

        [AllowNull()]
        [object]$ActionPlan,

        [bool]$Confirmed,

        [AllowNull()]
        [object]$StateCaptureEvidence
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    if ($null -eq $Plan) {
        $errors.Add('Cleanup plan is missing.')
    }
    else {
        if (-not [bool]$Plan.IsAllowed -or [string]$Plan.Status -ne 'Allowed') {
            $errors.Add('Cleanup plan is not approved by policy.')
            $errors.AddRange([string[]]@($Plan.Errors))
        }
        if (-not [bool]$Plan.IsDryRun) {
            $errors.Add('Cleanup plan must originate from the dry-run planner.')
        }
        if (-not [bool]$Plan.RequiresExplicitConfirmation) {
            $errors.Add('Cleanup plan does not require explicit confirmation.')
        }
    }

    if ($null -eq $ActionPlan) {
        $errors.Add('Action Plan is required for destructive cleanup.')
    }
    elseif ($null -ne $Plan) {
        if ([string]$ActionPlan.ToolId -ne [string]$Plan.ToolId) {
            $errors.Add('Action Plan tool identity does not match the cleanup plan.')
        }
        if ([string]$ActionPlan.Action -ne [string]$Plan.ActionId) {
            $errors.Add('Action Plan action identity does not match the cleanup plan.')
        }
        if (-not [bool]$ActionPlan.NeedsExplicitConfirmation) {
            $errors.Add('Action Plan must require explicit confirmation.')
        }
    }
    if (-not $Confirmed) {
        $errors.Add('Destructive cleanup requires explicit user confirmation.')
    }

    if ($null -ne $Plan) {
        $captureValidation = Test-BoostLabCleanupStateCaptureEvidence `
            -Plan $Plan `
            -StateCaptureEvidence $StateCaptureEvidence
        if (-not $captureValidation.IsValid) {
            $errors.AddRange([string[]]@($captureValidation.Errors))
        }
    }

    return [pscustomobject]@{
        IsAllowed = $errors.Count -eq 0
        Status    = if ($errors.Count -eq 0) { 'Validated' } else { 'Blocked' }
        Errors    = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function Invoke-BoostLabCleanupOperation {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Plan,

        [Parameter(Mandatory)]
        [object]$ActionPlan,

        [bool]$Confirmed,

        [AllowNull()]
        [object]$StateCaptureEvidence,

        [Parameter(Mandatory)]
        [scriptblock]$CleanupExecutor,

        [Parameter(Mandatory)]
        [scriptblock]$CleanupVerifier,

        [string]$StateRoot = ''
    )

    if ([string]::IsNullOrWhiteSpace($StateRoot)) {
        $StateRoot = Get-BoostLabCleanupStateRoot
    }
    $request = Test-BoostLabCleanupExecutionRequest `
        -Plan $Plan `
        -ActionPlan $ActionPlan `
        -Confirmed:$Confirmed `
        -StateCaptureEvidence $StateCaptureEvidence
    if (-not $request.IsAllowed) {
        return New-BoostLabCleanupBlockedResult `
            -Plan $Plan `
            -Message 'Cleanup execution was blocked by policy.' `
            -Errors @($request.Errors)
    }

    $cleanupExecuted = $false
    try {
        $executionResult = & $CleanupExecutor $Plan
        if (
            $null -eq $executionResult -or
            $null -eq $executionResult.PSObject.Properties['Success'] -or
            $null -eq $executionResult.PSObject.Properties['CleanupExecuted'] -or
            -not [bool]$executionResult.Success -or
            -not [bool]$executionResult.CleanupExecuted
        ) {
            throw 'Cleanup executor did not report a completed cleanup operation.'
        }
        $cleanupExecuted = $true

        $verification = & $CleanupVerifier $Plan $executionResult
        if (
            $null -eq $verification -or
            $null -eq $verification.PSObject.Properties['Status'] -or
            [string]$verification.Status -ne 'Passed'
        ) {
            throw 'Cleanup verification did not report Passed.'
        }

        $quarantineRecordResult = $null
        if ([string]$Plan.CleanupType -eq 'Quarantine') {
            $quarantinePath = [string](
                Get-BoostLabCleanupExecutionPropertyValue `
                    -InputObject $executionResult `
                    -Name 'QuarantinePath'
            )
            $quarantineHash = [string](
                Get-BoostLabCleanupExecutionPropertyValue `
                    -InputObject $executionResult `
                    -Name 'QuarantineHash'
            )
            $quarantineMetadata = Get-BoostLabCleanupExecutionPropertyValue `
                -InputObject $executionResult `
                -Name 'QuarantineMetadata'
            if (-not $quarantinePath.Equals(
                [string]$Plan.QuarantinePath,
                [StringComparison]::OrdinalIgnoreCase
            )) {
                throw 'Cleanup executor returned an unexpected quarantine path.'
            }
            $record = New-BoostLabQuarantineRecord `
                -Plan $Plan `
                -QuarantinePath $quarantinePath `
                -QuarantineHash $quarantineHash `
                -QuarantineMetadata $quarantineMetadata `
                -RestoreEligible:([bool]$Plan.RollbackEligible)
            $saved = Save-BoostLabQuarantineRecord `
                -Record $record `
                -StateRoot $StateRoot
            $quarantineRecordResult = [pscustomobject]@{
                Record     = $record
                RecordPath = $saved.RecordPath
                RecordHash = $saved.RecordSha256
            }
        }

        return [pscustomobject]@{
            Success          = $true
            Status           = if ([string]$Plan.CleanupType -eq 'Quarantine') {
                'Quarantined'
            }
            else {
                'Completed'
            }
            OperationId      = [string]$Plan.OperationId
            ToolId           = [string]$Plan.ToolId
            ActionId         = [string]$Plan.ActionId
            CleanupType      = [string]$Plan.CleanupType
            TargetPath       = [string]$Plan.ResolvedPath
            CleanupExecuted  = $true
            QuarantineRecord = $quarantineRecordResult
            Verification     = $verification
            Message          = 'Approved bounded cleanup completed and was verified.'
            Errors           = @()
            Timestamp        = Get-Date
        }
    }
    catch {
        return [pscustomobject]@{
            Success          = $false
            Status           = 'Failed'
            OperationId      = [string]$Plan.OperationId
            ToolId           = [string]$Plan.ToolId
            ActionId         = [string]$Plan.ActionId
            CleanupType      = [string]$Plan.CleanupType
            TargetPath       = [string]$Plan.ResolvedPath
            CleanupExecuted  = $cleanupExecuted
            QuarantineRecord = $null
            Verification     = $null
            Message          = 'Cleanup execution failed.'
            Errors           = @($_.Exception.Message)
            Timestamp        = Get-Date
        }
    }
}

function Invoke-BoostLabQuarantineRestore {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$RecordPath,

        [Parameter(Mandatory)]
        [string]$StateRoot,

        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ActionId,

        [Parameter(Mandatory)]
        [object]$ActionPlan,

        [bool]$Confirmed,

        [Parameter(Mandatory)]
        [scriptblock]$QuarantineInspector,

        [Parameter(Mandatory)]
        [scriptblock]$OriginalPathInspector,

        [Parameter(Mandatory)]
        [scriptblock]$RestoreExecutor,

        [Parameter(Mandatory)]
        [scriptblock]$RestoreVerifier,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabCleanupPolicy
    }
    $errors = [System.Collections.Generic.List[string]]::new()
    $imported = Import-BoostLabQuarantineRecord `
        -RecordPath $RecordPath `
        -StateRoot $StateRoot
    if (-not $imported.IsValid) {
        return New-BoostLabCleanupBlockedResult `
            -Plan $null `
            -Message 'Quarantine restore was blocked because the record is invalid.' `
            -Errors @($imported.Errors)
    }

    $record = $imported.Record
    $recordValidation = Test-BoostLabQuarantineRecord `
        -Record $record `
        -ExpectedToolId $ToolId `
        -ExpectedActionId $ActionId `
        -StateRoot $StateRoot `
        -Policy $Policy
    if (-not $recordValidation.IsValid) {
        $errors.AddRange([string[]]@($recordValidation.Errors))
    }
    if (-not [bool]$record.RestoreEligible) {
        $errors.Add('Quarantine record is not restore eligible.')
    }
    if ([bool]$record.Restored) {
        $errors.Add('Quarantine record has already been restored.')
    }
    if (
        $null -eq $ActionPlan -or
        [string]$ActionPlan.ToolId -ne $ToolId -or
        [string]$ActionPlan.Action -ne $ActionId -or
        -not [bool]$ActionPlan.NeedsExplicitConfirmation
    ) {
        $errors.Add('Quarantine restore requires a matching confirmation Action Plan.')
    }
    if (-not $Confirmed) {
        $errors.Add('Quarantine restore requires explicit user confirmation.')
    }

    $targetValidation = Test-BoostLabCleanupTarget `
        -ToolId $ToolId `
        -ScopeId ([string]$record.ScopeId) `
        -TargetPath ([string]$record.OriginalResolvedPath) `
        -TargetType ([string]$record.TargetType) `
        -CleanupType Quarantine `
        -Recursive:([string]$record.TargetType -eq 'Directory') `
        -Policy $Policy `
        -PathInspector $OriginalPathInspector
    if (-not $targetValidation.IsAllowed) {
        $errors.AddRange([string[]]@($targetValidation.Errors))
    }
    elseif ([bool]$targetValidation.Snapshot.Exists) {
        $errors.Add('Original path currently exists; quarantine restore will not overwrite it.')
    }

    if ($errors.Count -eq 0) {
        try {
            $quarantineState = & $QuarantineInspector `
                ([string]$record.QuarantinePath) `
                ([string]$record.TargetType)
            if (
                $null -eq $quarantineState -or
                -not [bool]$quarantineState.Exists
            ) {
                $errors.Add('Quarantined target is missing.')
            }
            elseif (
                [bool](
                    Get-BoostLabCleanupExecutionPropertyValue `
                        -InputObject $quarantineState `
                        -Name 'IsReparsePoint'
                ) -or
                [bool](
                    Get-BoostLabCleanupExecutionPropertyValue `
                        -InputObject $quarantineState `
                        -Name 'ContainsReparsePoint'
                )
            ) {
                $errors.Add('Quarantined target contains a reparse point.')
            }
            elseif ([string]$quarantineState.Hash -ne [string]$record.QuarantineHash) {
                $errors.Add('Quarantined target hash does not match the verified record.')
            }
        }
        catch {
            $errors.Add("Quarantine verification failed: $($_.Exception.Message)")
        }
    }
    if ($errors.Count -gt 0) {
        return New-BoostLabCleanupBlockedResult `
            -Plan $null `
            -Message 'Quarantine restore was blocked by validation.' `
            -Errors $errors.ToArray()
    }

    try {
        $restoreResult = & $RestoreExecutor $record
        if (
            $null -eq $restoreResult -or
            -not [bool]$restoreResult.Success -or
            -not [bool]$restoreResult.RestoreExecuted
        ) {
            throw 'Quarantine restore executor did not report completion.'
        }
        $verification = & $RestoreVerifier $record $restoreResult
        if (
            $null -eq $verification -or
            [string]$verification.Status -ne 'Passed'
        ) {
            throw 'Quarantine restore verification did not report Passed.'
        }

        $recordTable = [ordered]@{}
        foreach ($property in $record.PSObject.Properties) {
            $recordTable[$property.Name] = $property.Value
        }
        $recordTable['Restored'] = $true
        $recordTable['RestoredAt'] = (Get-Date).ToUniversalTime().ToString('o')
        Save-BoostLabQuarantineRecord `
            -Record $recordTable `
            -StateRoot $StateRoot | Out-Null

        return [pscustomobject]@{
            Success          = $true
            Status           = 'Restored'
            OperationId      = [string]$record.OperationId
            ToolId           = $ToolId
            ActionId         = $ActionId
            CleanupType      = 'QuarantineRestore'
            TargetPath       = [string]$record.OriginalResolvedPath
            CleanupExecuted  = $false
            RestoreExecuted  = $true
            QuarantineRecord = $record
            Verification     = $verification
            Message          = 'Verified quarantined target was restored.'
            Errors           = @()
            Timestamp        = Get-Date
        }
    }
    catch {
        return [pscustomobject]@{
            Success          = $false
            Status           = 'Failed'
            OperationId      = [string]$record.OperationId
            ToolId           = $ToolId
            ActionId         = $ActionId
            CleanupType      = 'QuarantineRestore'
            TargetPath       = [string]$record.OriginalResolvedPath
            CleanupExecuted  = $false
            RestoreExecuted  = $false
            QuarantineRecord = $record
            Verification     = $null
            Message          = 'Quarantine restore failed.'
            Errors           = @($_.Exception.Message)
            Timestamp        = Get-Date
        }
    }
}

Export-ModuleMember -Function @(
    'Test-BoostLabCleanupExecutionRequest'
    'Invoke-BoostLabCleanupOperation'
    'Invoke-BoostLabQuarantineRestore'
)
