Set-StrictMode -Version Latest

Import-Module `
    -Name (Join-Path $PSScriptRoot 'ServiceState.psm1') `
    -Scope Local `
    -ErrorAction Stop

function Get-BoostLabServiceRollbackPropertyValue {
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

function ConvertTo-BoostLabServiceRollbackRecordTable {
    param(
        [Parameter(Mandatory)]
        [object]$Record
    )

    $table = [ordered]@{}
    foreach ($property in $Record.PSObject.Properties) {
        $table[$property.Name] = $property.Value
    }

    return $table
}

function Get-BoostLabCapturedOriginalServiceState {
    param(
        [Parameter(Mandatory)]
        [object]$Record
    )

    return [pscustomobject][ordered]@{
        Exists           = [bool](
            Get-BoostLabServiceRollbackPropertyValue `
                -InputObject $Record `
                -Name 'OriginalExists'
        )
        ServiceName      = [string](
            Get-BoostLabServiceRollbackPropertyValue `
                -InputObject $Record `
                -Name 'ServiceName'
        )
        DisplayName      = [string](
            Get-BoostLabServiceRollbackPropertyValue `
                -InputObject $Record `
                -Name 'DisplayName'
        )
        Status           = [string](
            Get-BoostLabServiceRollbackPropertyValue `
                -InputObject $Record `
                -Name 'OriginalStatus'
        )
        StartupType      = [string](
            Get-BoostLabServiceRollbackPropertyValue `
                -InputObject $Record `
                -Name 'OriginalStartupType'
        )
        DelayedAutoStart = Get-BoostLabServiceRollbackPropertyValue `
            -InputObject $Record `
            -Name 'OriginalDelayedAutoStart'
        BinaryPath       = [string](
            Get-BoostLabServiceRollbackPropertyValue `
                -InputObject $Record `
                -Name 'OriginalBinaryPath'
        )
        ServiceAccount   = [string](
            Get-BoostLabServiceRollbackPropertyValue `
                -InputObject $Record `
                -Name 'OriginalServiceAccount'
        )
        Dependencies     = @(
            Get-BoostLabServiceRollbackPropertyValue `
                -InputObject $Record `
                -Name 'OriginalDependencies'
        )
        Description      = [string](
            Get-BoostLabServiceRollbackPropertyValue `
                -InputObject $Record `
                -Name 'OriginalDescription'
        )
        FailureActions   = Get-BoostLabServiceRollbackPropertyValue `
            -InputObject $Record `
            -Name 'OriginalFailureActions'
    }
}

function Compare-BoostLabServiceRollbackValue {
    param(
        [AllowNull()]
        [object]$Left,

        [AllowNull()]
        [object]$Right
    )

    $leftJson = $Left | ConvertTo-Json -Compress -Depth 30
    $rightJson = $Right | ConvertTo-Json -Compress -Depth 30
    return $leftJson -eq $rightJson
}

function New-BoostLabServiceRollbackBlockedResult {
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ActionId,

        [string]$RecordPath = '',

        [string]$ServiceName = '',

        [Parameter(Mandatory)]
        [string]$Message,

        [AllowNull()]
        [object[]]$Errors
    )

    return [pscustomobject]@{
        Success          = $false
        Status           = 'Blocked'
        ToolId           = $ToolId
        ActionId         = $ActionId
        RecordPath       = $RecordPath
        ServiceName      = $ServiceName
        RestoreAttempted = $false
        MutationPlan     = $null
        Message          = $Message
        Errors           = @($Errors)
        Verification     = $null
        Timestamp        = Get-Date
    }
}

function Invoke-BoostLabServiceRollback {
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
        [scriptblock]$ServiceReader,

        [Parameter(Mandatory)]
        [scriptblock]$ServiceMutator,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabServiceRollbackPolicy
    }

    $errors = [System.Collections.Generic.List[string]]::new()
    $imported = Import-BoostLabServiceRollbackRecord `
        -RecordPath $RecordPath `
        -StateRoot $StateRoot
    if (-not $imported.IsValid) {
        return New-BoostLabServiceRollbackBlockedResult `
            -ToolId $ToolId `
            -ActionId $ActionId `
            -RecordPath $RecordPath `
            -Message 'Service rollback was blocked because the record is missing or invalid.' `
            -Errors @($imported.Errors)
    }

    $record = $imported.Record
    $recordValidation = Test-BoostLabServiceRollbackRecord `
        -Record $record `
        -ExpectedToolId $ToolId `
        -ExpectedActionId $ActionId `
        -Policy $Policy
    if (-not $recordValidation.IsValid) {
        $errors.AddRange([string[]]@($recordValidation.Errors))
    }

    $serviceName = [string](
        Get-BoostLabServiceRollbackPropertyValue `
            -InputObject $record `
            -Name 'ServiceName'
    )
    $scopeId = [string](
        Get-BoostLabServiceRollbackPropertyValue `
            -InputObject $record `
            -Name 'ScopeId'
    )
    $intendedMutation = [string](
        Get-BoostLabServiceRollbackPropertyValue `
            -InputObject $record `
            -Name 'IntendedMutation'
    )
    $targetValidation = Test-BoostLabServiceCaptureTarget `
        -ToolId $ToolId `
        -ScopeId $scopeId `
        -ServiceName $serviceName `
        -IntendedMutation $intendedMutation `
        -Policy $Policy
    if (-not $targetValidation.IsAllowed) {
        $errors.AddRange([string[]]@($targetValidation.Errors))
    }
    if (
        -not [bool](
            Get-BoostLabServiceRollbackPropertyValue `
                -InputObject $record `
                -Name 'RollbackEligible'
        )
    ) {
        $errors.Add('Service rollback record is not eligible for rollback.')
    }
    if (
        -not [bool](
            Get-BoostLabServiceRollbackPropertyValue `
                -InputObject $record `
                -Name 'MutationRecorded'
        )
    ) {
        $errors.Add('Service rollback is blocked until post-mutation state is recorded.')
    }

    $originalState = Get-BoostLabCapturedOriginalServiceState -Record $record
    if (-not $originalState.Exists) {
        $errors.Add(
            'Service recreation is not available in the Phase 37 rollback foundation.'
        )
    }

    $scope = $targetValidation.Scope
    if (
        $null -ne $scope -and
        (
            [bool](
                Get-BoostLabServiceRollbackPropertyValue `
                    -InputObject $scope `
                    -Name 'AllowCreateService'
            ) -or
            [bool](
                Get-BoostLabServiceRollbackPropertyValue `
                    -InputObject $scope `
                    -Name 'AllowDeleteService'
            ) -or
            [bool](
                Get-BoostLabServiceRollbackPropertyValue `
                    -InputObject $scope `
                    -Name 'AllowRecreateMissingService'
            )
        )
    ) {
        $errors.Add(
            'Service creation, deletion, and recreation are not implemented by this foundation.'
        )
    }

    $postMutationState = Get-BoostLabServiceRollbackPropertyValue `
        -InputObject $record `
        -Name 'PostMutationState'
    if ($null -eq $postMutationState) {
        $errors.Add('Recorded post-mutation service state is missing.')
    }
    elseif ($errors.Count -eq 0) {
        $currentVerification = Test-BoostLabServiceState `
            -ServiceName $serviceName `
            -ExpectedState $postMutationState `
            -ServiceReader $ServiceReader
        if ($currentVerification.Status -ne 'Passed') {
            $errors.Add(
                'Current service state does not exactly match the recorded post-mutation state.'
            )
            foreach ($check in @(
                $currentVerification.Checks |
                    Where-Object { $_.Status -ne 'Passed' }
            )) {
                $errors.Add("$($check.Name): $($check.Message)")
            }
            $errors.AddRange([string[]]@($currentVerification.Errors))
        }
    }

    if ($null -ne $postMutationState) {
        foreach ($identityProperty in @(
            'ServiceName'
            'BinaryPath'
            'ServiceAccount'
            'Dependencies'
        )) {
            $originalValue = Get-BoostLabServiceRollbackPropertyValue `
                -InputObject $originalState `
                -Name $identityProperty
            $postValue = Get-BoostLabServiceRollbackPropertyValue `
                -InputObject $postMutationState `
                -Name $identityProperty
            if (-not (Compare-BoostLabServiceRollbackValue $originalValue $postValue)) {
                $errors.Add(
                    "Service identity/configuration field '$identityProperty' changed and cannot be restored by this foundation."
                )
            }
        }
        foreach ($unsupportedProperty in @(
            'DisplayName'
            'Description'
            'FailureActions'
        )) {
            $originalValue = Get-BoostLabServiceRollbackPropertyValue `
                -InputObject $originalState `
                -Name $unsupportedProperty
            $postValue = Get-BoostLabServiceRollbackPropertyValue `
                -InputObject $postMutationState `
                -Name $unsupportedProperty
            if (-not (Compare-BoostLabServiceRollbackValue $originalValue $postValue)) {
                $errors.Add(
                    "Service configuration field '$unsupportedProperty' changed and is outside Phase 37 rollback support."
                )
            }
        }
    }

    if ($errors.Count -gt 0) {
        return New-BoostLabServiceRollbackBlockedResult `
            -ToolId $ToolId `
            -ActionId $ActionId `
            -RecordPath $imported.RecordPath `
            -ServiceName $serviceName `
            -Message 'Service rollback was blocked by validation.' `
            -Errors $errors.ToArray()
    }

    $operations = [System.Collections.Generic.List[object]]::new()
    $restoreStartupType = [bool](
        Get-BoostLabServiceRollbackPropertyValue `
            -InputObject $scope `
            -Name 'RestoreStartupType'
    )
    $restoreDelayedAutoStart = [bool](
        Get-BoostLabServiceRollbackPropertyValue `
            -InputObject $scope `
            -Name 'RestoreDelayedAutoStart'
    )
    $restoreStatus = [bool](
        Get-BoostLabServiceRollbackPropertyValue `
            -InputObject $scope `
            -Name 'RestoreStatus'
    )
    if (
        $restoreStartupType -and
        -not (Compare-BoostLabServiceRollbackValue `
            $originalState.StartupType `
            (Get-BoostLabServiceRollbackPropertyValue `
                -InputObject $postMutationState `
                -Name 'StartupType'))
    ) {
        $operations.Add([pscustomobject]@{
            Operation = 'SetStartupType'
            Value     = $originalState.StartupType
        })
    }
    if (
        $restoreDelayedAutoStart -and
        -not (Compare-BoostLabServiceRollbackValue `
            $originalState.DelayedAutoStart `
            (Get-BoostLabServiceRollbackPropertyValue `
                -InputObject $postMutationState `
                -Name 'DelayedAutoStart'))
    ) {
        $operations.Add([pscustomobject]@{
            Operation = 'SetDelayedAutoStart'
            Value     = $originalState.DelayedAutoStart
        })
    }
    if (
        $restoreStatus -and
        -not (Compare-BoostLabServiceRollbackValue `
            $originalState.Status `
            (Get-BoostLabServiceRollbackPropertyValue `
                -InputObject $postMutationState `
                -Name 'Status'))
    ) {
        $operations.Add([pscustomobject]@{
            Operation = if ($originalState.Status -eq 'Running') { 'Start' } else { 'Stop' }
            Value     = $originalState.Status
        })
    }

    $mutationPlan = [pscustomobject][ordered]@{
        ServiceName = $serviceName
        Operations  = $operations.ToArray()
        Create      = $false
        Delete      = $false
        Timestamp   = Get-Date
    }
    try {
        $mutationResult = & $ServiceMutator $mutationPlan
        if (
            $null -eq $mutationResult -or
            $null -eq $mutationResult.PSObject.Properties['Success'] -or
            -not [bool]$mutationResult.Success
        ) {
            throw 'Service mutator did not report successful completion.'
        }

        $verification = Test-BoostLabServiceState `
            -ServiceName $serviceName `
            -ExpectedState $originalState `
            -ServiceReader $ServiceReader
        if ($verification.Status -ne 'Passed') {
            throw 'Restored service state did not match the captured original state.'
        }

        $recordTable = ConvertTo-BoostLabServiceRollbackRecordTable -Record $record
        $recordTable['RollbackCompleted'] = $true
        $recordTable['RollbackCompletedAt'] = (Get-Date).ToUniversalTime().ToString('o')
        Save-BoostLabServiceRollbackRecord `
            -Record $recordTable `
            -StateRoot $StateRoot | Out-Null

        return [pscustomobject]@{
            Success          = $true
            Status           = 'Restored'
            ToolId           = $ToolId
            ActionId         = $ActionId
            RecordPath       = $imported.RecordPath
            ServiceName      = $serviceName
            RestoreAttempted = $true
            MutationPlan     = $mutationPlan
            Message          = 'Service rollback restored the captured startup and running state.'
            Errors           = @()
            Verification     = $verification
            Timestamp        = Get-Date
        }
    }
    catch {
        return [pscustomobject]@{
            Success          = $false
            Status           = 'Failed'
            ToolId           = $ToolId
            ActionId         = $ActionId
            RecordPath       = $imported.RecordPath
            ServiceName      = $serviceName
            RestoreAttempted = $true
            MutationPlan     = $mutationPlan
            Message          = 'Service rollback failed.'
            Errors           = @($_.Exception.Message)
            Verification     = $null
            Timestamp        = Get-Date
        }
    }
}

Export-ModuleMember -Function @(
    'Invoke-BoostLabServiceRollback'
)
