Set-StrictMode -Version Latest

Import-Module `
    -Name (Join-Path $PSScriptRoot 'AppxPackageInventory.psm1') `
    -Scope Local `
    -ErrorAction Stop

function Get-BoostLabAppxExecutionPropertyValue {
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

function New-BoostLabAppxBlockedResult {
    param(
        [AllowNull()]
        [object]$Plan,

        [Parameter(Mandatory)]
        [string]$Message,

        [AllowNull()]
        [object[]]$Errors
    )

    return [pscustomobject]@{
        Success           = $false
        Status            = 'Blocked'
        OperationId       = [string](
            Get-BoostLabAppxExecutionPropertyValue $Plan 'OperationId'
        )
        ToolId            = [string](
            Get-BoostLabAppxExecutionPropertyValue $Plan 'ToolId'
        )
        ActionId          = [string](
            Get-BoostLabAppxExecutionPropertyValue $Plan 'ActionId'
        )
        PackageFamilyName = [string](
            Get-BoostLabAppxExecutionPropertyValue $Plan 'PackageFamilyName'
        )
        PackageChanged    = $false
        Verification      = $null
        Message           = $Message
        Errors            = @($Errors)
        Timestamp         = Get-Date
    }
}

function Test-BoostLabAppxExecutionRequest {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [object]$Plan,

        [AllowNull()]
        [object]$ActionPlan,

        [bool]$Confirmed,

        [string]$StateRoot = '',

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    if ($null -eq $Plan) {
        $errors.Add('AppX package plan is missing.')
    }
    else {
        if (-not [bool]$Plan.IsAllowed -or [string]$Plan.Status -ne 'Allowed') {
            $errors.Add('AppX package plan is not approved by policy.')
            $errors.AddRange([string[]]@($Plan.Errors))
        }
        if (-not [bool]$Plan.IsDryRun) {
            $errors.Add('AppX package plan must originate from the dry-run planner.')
        }
        if (-not [bool]$Plan.RequiresExplicitConfirmation) {
            $errors.Add('AppX package plan must require explicit confirmation.')
        }
        if (-not [bool]$Plan.InventoryVerified) {
            $errors.Add('AppX mutation requires a verified inventory record.')
        }
        if ([string]::IsNullOrWhiteSpace($StateRoot)) {
            $errors.Add('AppX execution requires the package state root.')
        }
        else {
            try {
                $validatedPlan = New-BoostLabAppxMutationPlan `
                    -RecordPath ([string]$Plan.InventoryRecordPath) `
                    -StateRoot $StateRoot `
                    -ToolId ([string]$Plan.ToolId) `
                    -ActionId ([string]$Plan.ActionId) `
                    -PackageFamilyName ([string]$Plan.PackageFamilyName) `
                    -IntendedMutation ([string]$Plan.IntendedMutation) `
                    -Policy $Policy
                if (-not $validatedPlan.IsAllowed) {
                    $errors.Add(
                        'AppX inventory and policy checks failed at execution time.'
                    )
                    $errors.AddRange([string[]]@($validatedPlan.Errors))
                }
            }
            catch {
                $errors.Add(
                    "AppX execution revalidation failed: $($_.Exception.Message)"
                )
            }
        }
    }

    if ($null -eq $ActionPlan) {
        $errors.Add('Action Plan is required for AppX package mutation.')
    }
    elseif ($null -ne $Plan) {
        if ([string]$ActionPlan.ToolId -ne [string]$Plan.ToolId) {
            $errors.Add('Action Plan tool identity does not match the AppX plan.')
        }
        if ([string]$ActionPlan.Action -ne [string]$Plan.ActionId) {
            $errors.Add('Action Plan action identity does not match the AppX plan.')
        }
        if (-not [bool]$ActionPlan.NeedsExplicitConfirmation) {
            $errors.Add('Action Plan must require explicit confirmation.')
        }
    }
    if (-not $Confirmed) {
        $errors.Add('AppX package mutation requires explicit user confirmation.')
    }

    return [pscustomobject]@{
        IsAllowed = $errors.Count -eq 0
        Status    = if ($errors.Count -eq 0) { 'Validated' } else { 'Blocked' }
        Errors    = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function Invoke-BoostLabAppxPackageMutation {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Plan,

        [Parameter(Mandatory)]
        [object]$ActionPlan,

        [bool]$Confirmed,

        [Parameter(Mandatory)]
        [scriptblock]$PackageMutator,

        [Parameter(Mandatory)]
        [scriptblock]$PackageVerifier,

        [Parameter(Mandatory)]
        [string]$StateRoot,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    $request = Test-BoostLabAppxExecutionRequest `
        -Plan $Plan `
        -ActionPlan $ActionPlan `
        -Confirmed:$Confirmed `
        -StateRoot $StateRoot `
        -Policy $Policy
    if (-not $request.IsAllowed) {
        return New-BoostLabAppxBlockedResult `
            -Plan $Plan `
            -Message 'AppX package mutation was blocked by policy.' `
            -Errors @($request.Errors)
    }

    try {
        $mutationResult = & $PackageMutator $Plan
        if (
            $null -eq $mutationResult -or
            -not [bool](
                Get-BoostLabAppxExecutionPropertyValue `
                    $mutationResult `
                    'Success'
            ) -or
            -not [bool](
                Get-BoostLabAppxExecutionPropertyValue `
                    $mutationResult `
                    'PackageChanged'
            )
        ) {
            throw 'AppX package mutator did not report a completed mutation.'
        }

        $verification = & $PackageVerifier $Plan $mutationResult
        if (
            $null -eq $verification -or
            [string](
                Get-BoostLabAppxExecutionPropertyValue $verification 'Status'
            ) -ne 'Passed'
        ) {
            throw 'AppX package verification did not report Passed.'
        }

        Set-BoostLabAppxInventoryMutationState `
            -RecordPath $Plan.InventoryRecordPath `
            -StateRoot $StateRoot `
            -PostMutationState (
                Get-BoostLabAppxExecutionPropertyValue `
                    $verification `
                    'DetectedState'
            ) | Out-Null

        return [pscustomobject]@{
            Success           = $true
            Status            = 'Completed'
            OperationId       = [string]$Plan.OperationId
            ToolId            = [string]$Plan.ToolId
            ActionId          = [string]$Plan.ActionId
            PackageFamilyName = [string]$Plan.PackageFamilyName
            PackageChanged    = $true
            Verification      = $verification
            Message           = 'Approved AppX package mutation completed.'
            Errors            = @()
            Timestamp         = Get-Date
        }
    }
    catch {
        return [pscustomobject]@{
            Success           = $false
            Status            = 'Failed'
            OperationId       = [string]$Plan.OperationId
            ToolId            = [string]$Plan.ToolId
            ActionId          = [string]$Plan.ActionId
            PackageFamilyName = [string]$Plan.PackageFamilyName
            PackageChanged    = $false
            Verification      = $null
            Message           = $_.Exception.Message
            Errors            = @($_.Exception.Message)
            Timestamp         = Get-Date
        }
    }
}

function Test-BoostLabAppxRestoreExecutionRequest {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [object]$Plan,

        [AllowNull()]
        [object]$ActionPlan,

        [bool]$Confirmed,

        [string]$StateRoot = '',

        [AllowNull()]
        [scriptblock]$ManifestInspector,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    if ($null -eq $Plan) {
        $errors.Add('AppX restore plan is missing.')
    }
    else {
        if (-not [bool]$Plan.IsAllowed -or [string]$Plan.Status -ne 'Allowed') {
            $errors.Add('AppX restore plan is not approved by policy.')
            $errors.AddRange([string[]]@($Plan.Errors))
        }
        if (-not [bool]$Plan.IsDryRun) {
            $errors.Add('AppX restore plan must originate from the dry-run planner.')
        }
        if (-not [bool]$Plan.RequiresExplicitConfirmation) {
            $errors.Add('AppX restore plan must require explicit confirmation.')
        }
        if ([string]::IsNullOrWhiteSpace($StateRoot)) {
            $errors.Add('AppX restore execution requires the package state root.')
        }
        elseif ($null -eq $ManifestInspector) {
            $errors.Add(
                'AppX restore execution requires manifest revalidation.'
            )
        }
        else {
            try {
                $validatedPlan = New-BoostLabAppxRestorePlan `
                    -RecordPath ([string]$Plan.InventoryRecordPath) `
                    -StateRoot $StateRoot `
                    -ToolId ([string]$Plan.ToolId) `
                    -ActionId ([string]$Plan.ActionId) `
                    -SourceActionId ([string]$Plan.SourceActionId) `
                    -RestoreMutation ([string]$Plan.RestoreMutation) `
                    -ManifestInspector $ManifestInspector `
                    -Policy $Policy
                if (-not $validatedPlan.IsAllowed) {
                    $errors.Add(
                        'AppX restore record and policy checks failed at ' +
                        'execution time.'
                    )
                    $errors.AddRange([string[]]@($validatedPlan.Errors))
                }
            }
            catch {
                $errors.Add(
                    "AppX restore revalidation failed: $($_.Exception.Message)"
                )
            }
        }
    }
    if ($null -eq $ActionPlan) {
        $errors.Add('Action Plan is required for AppX restore.')
    }
    elseif ($null -ne $Plan) {
        if ([string]$ActionPlan.ToolId -ne [string]$Plan.ToolId) {
            $errors.Add('Action Plan tool identity does not match restore plan.')
        }
        if ([string]$ActionPlan.Action -ne [string]$Plan.ActionId) {
            $errors.Add('Action Plan action identity does not match restore plan.')
        }
        if (-not [bool]$ActionPlan.NeedsExplicitConfirmation) {
            $errors.Add('Action Plan must require explicit confirmation.')
        }
    }
    if (-not $Confirmed) {
        $errors.Add('AppX restore requires explicit user confirmation.')
    }

    return [pscustomobject]@{
        IsAllowed = $errors.Count -eq 0
        Status    = if ($errors.Count -eq 0) { 'Validated' } else { 'Blocked' }
        Errors    = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function Invoke-BoostLabAppxPackageRestore {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Plan,

        [Parameter(Mandatory)]
        [object]$ActionPlan,

        [bool]$Confirmed,

        [Parameter(Mandatory)]
        [scriptblock]$RestoreExecutor,

        [Parameter(Mandatory)]
        [scriptblock]$RestoreVerifier,

        [Parameter(Mandatory)]
        [string]$StateRoot,

        [Parameter(Mandatory)]
        [scriptblock]$ManifestInspector,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    $request = Test-BoostLabAppxRestoreExecutionRequest `
        -Plan $Plan `
        -ActionPlan $ActionPlan `
        -Confirmed:$Confirmed `
        -StateRoot $StateRoot `
        -ManifestInspector $ManifestInspector `
        -Policy $Policy
    if (-not $request.IsAllowed) {
        return New-BoostLabAppxBlockedResult `
            -Plan $Plan `
            -Message 'AppX package restore was blocked by policy.' `
            -Errors @($request.Errors)
    }

    try {
        $restoreResult = & $RestoreExecutor $Plan
        if (
            $null -eq $restoreResult -or
            -not [bool](
                Get-BoostLabAppxExecutionPropertyValue $restoreResult 'Success'
            ) -or
            -not [bool](
                Get-BoostLabAppxExecutionPropertyValue `
                    $restoreResult `
                    'PackageChanged'
            )
        ) {
            throw 'AppX restore executor did not report a completed restore.'
        }

        $verification = & $RestoreVerifier $Plan $restoreResult
        if (
            $null -eq $verification -or
            [string](
                Get-BoostLabAppxExecutionPropertyValue $verification 'Status'
            ) -ne 'Passed'
        ) {
            throw 'AppX restore verification did not report Passed.'
        }

        Set-BoostLabAppxInventoryRestoreState `
            -RecordPath $Plan.InventoryRecordPath `
            -StateRoot $StateRoot `
            -PostRestoreState (
                Get-BoostLabAppxExecutionPropertyValue `
                    $verification `
                    'DetectedState'
            ) | Out-Null

        return [pscustomobject]@{
            Success           = $true
            Status            = 'Restored'
            OperationId       = [string]$Plan.OperationId
            ToolId            = [string]$Plan.ToolId
            ActionId          = [string]$Plan.ActionId
            PackageFamilyName = [string]$Plan.PackageFamilyName
            PackageChanged    = $true
            Verification      = $verification
            Message           = 'Approved AppX package restore completed.'
            Errors            = @()
            Timestamp         = Get-Date
        }
    }
    catch {
        return [pscustomobject]@{
            Success           = $false
            Status            = 'Failed'
            OperationId       = [string]$Plan.OperationId
            ToolId            = [string]$Plan.ToolId
            ActionId          = [string]$Plan.ActionId
            PackageFamilyName = [string]$Plan.PackageFamilyName
            PackageChanged    = $false
            Verification      = $null
            Message           = $_.Exception.Message
            Errors            = @($_.Exception.Message)
            Timestamp         = Get-Date
        }
    }
}

Export-ModuleMember -Function @(
    'Test-BoostLabAppxExecutionRequest'
    'Invoke-BoostLabAppxPackageMutation'
    'Test-BoostLabAppxRestoreExecutionRequest'
    'Invoke-BoostLabAppxPackageRestore'
)
