Set-StrictMode -Version Latest

$script:BoostLabRestoreSelectionPolicyPath = Join-Path `
    (Split-Path -Parent $PSScriptRoot) `
    'config\RestoreSelectionPolicy.psd1'

function Get-BoostLabRestoreSelectionPropertyValue {
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

function ConvertTo-BoostLabRestoreSelectionArray {
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return @()
    }
    return @($Value)
}

function Get-BoostLabRestoreSelectionPolicy {
    [CmdletBinding()]
    [OutputType([System.Collections.IDictionary])]
    param(
        [string]$PolicyPath = $script:BoostLabRestoreSelectionPolicyPath
    )

    if (-not (Test-Path -LiteralPath $PolicyPath -PathType Leaf)) {
        throw "Restore selection policy was not found: $PolicyPath"
    }

    return Import-PowerShellDataFile -LiteralPath $PolicyPath
}

function New-BoostLabRestoreSelectionIntegrityHash {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [object]$Record,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabRestoreSelectionPolicy
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($field in @($Policy.RequiredMetadataFields | Where-Object { $_ -ne 'IntegrityHash' } | Sort-Object)) {
        $value = Get-BoostLabRestoreSelectionPropertyValue -InputObject $Record -Name $field
        $json = ConvertTo-Json -InputObject $value -Compress -Depth 8
        $lines.Add(('{0}={1}' -f $field, $json))
    }

    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        return [BitConverter]::ToString(
            $sha256.ComputeHash(
                [Text.Encoding]::UTF8.GetBytes(($lines -join "`n"))
            )
        ).Replace('-', '')
    }
    finally {
        $sha256.Dispose()
    }
}

function Test-BoostLabRestoreSelectionPolicy {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabRestoreSelectionPolicy
    }

    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($field in @(
        'SchemaVersion'
        'SupportedRecordSchemaVersions'
        'MaxRecordAgeDays'
        'RecordTypes'
        'ScopeTypes'
        'RequiredMetadataFields'
        'EligibilityStates'
        'RiskLevels'
        'ApprovedRestoreHandlers'
        'RestoreSelectionScopes'
    )) {
        if (-not $Policy.Contains($field)) {
            $errors.Add("Restore selection policy is missing field: $field")
        }
    }

    if ($Policy.Contains('SchemaVersion') -and [string]$Policy.SchemaVersion -ne '1.0') {
        $errors.Add('Restore selection policy schema is unsupported.')
    }

    foreach ($requiredField in @(
        'RestoreRecordId'
        'ToolId'
        'ToolName'
        'SourcePath'
        'SourceChecksum'
        'SourceAction'
        'ScopeType'
        'RecordType'
        'CapturedTargetIdentities'
        'Timestamp'
        'MachineContext'
        'UserContext'
        'OperatingSystemContext'
        'ProductScopeContext'
        'PreMutationStateSummary'
        'PostMutationStateRequirement'
        'PostMutationStatePresent'
        'RestoreHandlerType'
        'IntegrityHash'
        'SchemaVersion'
        'ApprovalPolicyVersion'
        'RiskLevel'
        'RestoreEligibilityState'
        'DenialReason'
    )) {
        if ($Policy.Contains('RequiredMetadataFields') -and $requiredField -notin @($Policy.RequiredMetadataFields)) {
            $errors.Add("Restore selection policy is missing required metadata field: $requiredField")
        }
    }

    $scopeCount = 0
    if ($Policy.Contains('RestoreSelectionScopes')) {
        $scopeCount = @(ConvertTo-BoostLabRestoreSelectionArray $Policy.RestoreSelectionScopes).Count
    }
    $handlerCount = 0
    if ($Policy.Contains('ApprovedRestoreHandlers')) {
        $handlerCount = @(ConvertTo-BoostLabRestoreSelectionArray $Policy.ApprovedRestoreHandlers).Count
    }

    return [pscustomobject]@{
        IsValid      = $errors.Count -eq 0
        Status       = if ($errors.Count -eq 0) { 'Valid' } else { 'Invalid' }
        ScopeCount   = $scopeCount
        HandlerCount = $handlerCount
        Errors       = $errors.ToArray()
        Timestamp    = Get-Date
    }
}

function Test-BoostLabRestoreSelectionBroadTarget {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [string]$ScopeType,

        [AllowNull()]
        [object]$Targets
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($targetValue in @(ConvertTo-BoostLabRestoreSelectionArray $Targets)) {
        $target = ([string]$targetValue).Trim()
        if ([string]::IsNullOrWhiteSpace($target)) {
            $errors.Add('Captured target identity cannot be empty.')
            continue
        }
        if ($target.IndexOfAny([char[]]'*?[]') -ge 0) {
            $errors.Add("Wildcard restore target is denied: $target")
        }
        if ($target -match '^\s*(HKLM:|HKCU:|HKEY_LOCAL_MACHINE|HKEY_CURRENT_USER)\\?\s*$') {
            $errors.Add("Broad registry hive restore is denied: $target")
        }
        if ($target -match '^\s*(HKLM:\\SYSTEM|Registry::HKEY_LOCAL_MACHINE\\SYSTEM|HKEY_LOCAL_MACHINE\\SYSTEM)\s*$') {
            $errors.Add("Broad protected registry restore is denied: $target")
        }
        if ($target -match '(?i)^([A-Z]:\\?|[A-Z]:\\Windows\\?|[A-Z]:\\Program Files\\?|[A-Z]:\\Program Files \(x86\)\\?)$') {
            $errors.Add("Broad file root restore is denied: $target")
        }
        if ($target -match '(?i)^[A-Z]:\\Users\\[^\\]+\\?(Documents|Desktop|Downloads)?\\?$') {
            $errors.Add("Broad user-profile restore is denied: $target")
        }
    }

    return [pscustomobject]@{
        IsDenied = $errors.Count -gt 0
        Errors   = $errors.ToArray()
    }
}

function Test-BoostLabRestoreSelectionCandidate {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Candidate,

        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$SourceAction,

        [Parameter(Mandatory)]
        [string]$ScopeType,

        [Parameter(Mandatory)]
        [string]$RecordType,

        [string[]]$TargetIdentities = @(),

        [bool]$Confirmed = $false,

        [string[]]$ApprovedHandlerTypes = @(),

        [AllowNull()]
        [System.Collections.IDictionary]$Policy,

        [datetime]$Now = (Get-Date)
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabRestoreSelectionPolicy
    }

    $errors = [System.Collections.Generic.List[string]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()

    foreach ($field in @($Policy.RequiredMetadataFields)) {
        if ($null -eq (Get-BoostLabRestoreSelectionPropertyValue -InputObject $Candidate -Name $field)) {
            $errors.Add("Restore candidate is missing field: $field")
        }
    }

    $recordId = [string](Get-BoostLabRestoreSelectionPropertyValue -InputObject $Candidate -Name 'RestoreRecordId')
    $candidateToolId = [string](Get-BoostLabRestoreSelectionPropertyValue -InputObject $Candidate -Name 'ToolId')
    $candidateToolName = [string](Get-BoostLabRestoreSelectionPropertyValue -InputObject $Candidate -Name 'ToolName')
    $candidateSourceChecksum = [string](Get-BoostLabRestoreSelectionPropertyValue -InputObject $Candidate -Name 'SourceChecksum')
    $candidateAction = [string](Get-BoostLabRestoreSelectionPropertyValue -InputObject $Candidate -Name 'SourceAction')
    $candidateScopeType = [string](Get-BoostLabRestoreSelectionPropertyValue -InputObject $Candidate -Name 'ScopeType')
    $candidateRecordType = [string](Get-BoostLabRestoreSelectionPropertyValue -InputObject $Candidate -Name 'RecordType')
    $capturedTargets = @(
        ConvertTo-BoostLabRestoreSelectionArray (
            Get-BoostLabRestoreSelectionPropertyValue -InputObject $Candidate -Name 'CapturedTargetIdentities'
        )
    ) | ForEach-Object { [string]$_ }
    $timestampValue = Get-BoostLabRestoreSelectionPropertyValue -InputObject $Candidate -Name 'Timestamp'
    $postMutationRequirement = [string](Get-BoostLabRestoreSelectionPropertyValue -InputObject $Candidate -Name 'PostMutationStateRequirement')
    $postMutationPresent = Get-BoostLabRestoreSelectionPropertyValue -InputObject $Candidate -Name 'PostMutationStatePresent'
    $handlerType = [string](Get-BoostLabRestoreSelectionPropertyValue -InputObject $Candidate -Name 'RestoreHandlerType')
    $integrityHash = [string](Get-BoostLabRestoreSelectionPropertyValue -InputObject $Candidate -Name 'IntegrityHash')
    $schemaVersion = [string](Get-BoostLabRestoreSelectionPropertyValue -InputObject $Candidate -Name 'SchemaVersion')
    $riskLevel = [string](Get-BoostLabRestoreSelectionPropertyValue -InputObject $Candidate -Name 'RiskLevel')
    $eligibilityState = [string](Get-BoostLabRestoreSelectionPropertyValue -InputObject $Candidate -Name 'RestoreEligibilityState')

    if ([string]::IsNullOrWhiteSpace($recordId)) {
        $errors.Add('RestoreRecordId cannot be empty.')
    }
    if ($schemaVersion -notin @($Policy.SupportedRecordSchemaVersions)) {
        $errors.Add("Unsupported restore record schema version: $schemaVersion")
    }
    if ($candidateToolId -ne $ToolId) {
        $errors.Add("Tool id mismatch. Expected $ToolId, found $candidateToolId.")
    }
    if ($candidateAction -ne $SourceAction) {
        $errors.Add("Source action mismatch. Expected $SourceAction, found $candidateAction.")
    }
    if ($candidateScopeType -ne $ScopeType) {
        $errors.Add("Scope type mismatch. Expected $ScopeType, found $candidateScopeType.")
    }
    if ($candidateRecordType -ne $RecordType) {
        $errors.Add("Record type mismatch. Expected $RecordType, found $candidateRecordType.")
    }
    if ($candidateScopeType -notin @($Policy.ScopeTypes)) {
        $errors.Add("Scope type is not supported by policy: $candidateScopeType")
    }
    if ($candidateRecordType -notin @($Policy.RecordTypes)) {
        $errors.Add("Record type is not supported by policy: $candidateRecordType")
    }
    if ($candidateSourceChecksum -notmatch '^[A-Fa-f0-9]{64}$') {
        $errors.Add('SourceChecksum must be a complete SHA-256 hash.')
    }
    if ($riskLevel -notin @($Policy.RiskLevels)) {
        $errors.Add("RiskLevel is not supported by policy: $riskLevel")
    }
    if ($eligibilityState -notin @($Policy.EligibilityStates)) {
        $errors.Add("RestoreEligibilityState is not supported by policy: $eligibilityState")
    }
    if ($candidateToolName -match '(?i)Loudness\s*EQ|NVME\s+Faster\s+Driver' -or $candidateToolId -match '(?i)loudness|nvme') {
        $errors.Add('Restore would reintroduce a deleted tool.')
    }
    if ($handlerType -notin @($ApprovedHandlerTypes)) {
        $errors.Add("Restore handler is not approved by policy for this request: $handlerType")
    }
    if (-not $Confirmed) {
        $errors.Add('Explicit user confirmation is required before Restore.')
    }
    if ($postMutationRequirement -notin @('', 'None', 'NotRequired') -and $postMutationPresent -ne $true) {
        $errors.Add('Required post-mutation state is not present.')
    }

    $timestamp = [datetime]::MinValue
    if (-not [datetime]::TryParse([string]$timestampValue, [ref]$timestamp)) {
        $errors.Add('Timestamp is not a valid DateTime.')
    }
    else {
        $maxAgeDays = [int]$Policy.MaxRecordAgeDays
        if ($timestamp -lt $Now.AddDays(-1 * $maxAgeDays)) {
            $errors.Add("Restore record is stale beyond policy: $maxAgeDays days.")
        }
    }

    if ($TargetIdentities.Count -gt 0) {
        $expectedTargets = @($TargetIdentities | Sort-Object -Unique)
        $actualTargets = @($capturedTargets | Sort-Object -Unique)
        if (
            $expectedTargets.Count -ne $actualTargets.Count -or
            @(Compare-Object -ReferenceObject $expectedTargets -DifferenceObject $actualTargets).Count -ne 0
        ) {
            $errors.Add('Target identity mismatch.')
        }
    }

    $targetValidation = Test-BoostLabRestoreSelectionBroadTarget -ScopeType $candidateScopeType -Targets $capturedTargets
    foreach ($targetError in @($targetValidation.Errors)) {
        $errors.Add($targetError)
    }

    if ($integrityHash -notmatch '^[A-Fa-f0-9]{64}$') {
        $errors.Add('IntegrityHash must be a complete SHA-256 hash.')
    }
    else {
        $computedHash = New-BoostLabRestoreSelectionIntegrityHash -Record $Candidate -Policy $Policy
        if ($computedHash -ne $integrityHash) {
            $errors.Add('Integrity check failed.')
        }
    }

    if ($eligibilityState -eq 'Denied') {
        $warnings.Add('Candidate record is already marked Denied.')
    }
    if ($eligibilityState -eq 'NotApplicable') {
        $warnings.Add('Candidate record is marked NotApplicable.')
    }

    $status = if ($errors.Count -eq 0) { 'Eligible' } else { 'Denied' }

    return [pscustomobject]@{
        IsEligible       = $errors.Count -eq 0
        Status           = $status
        RestoreRecordId  = $recordId
        ToolId           = $candidateToolId
        SourceAction     = $candidateAction
        ScopeType        = $candidateScopeType
        RecordType       = $candidateRecordType
        TargetIdentities = $capturedTargets
        RuntimeAllowed   = $false
        Errors           = $errors.ToArray()
        Warnings         = $warnings.ToArray()
        Timestamp        = Get-Date
    }
}

function Select-BoostLabRestoreSelectionCandidate {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object[]]$Candidates,

        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$SourceAction,

        [Parameter(Mandatory)]
        [string]$ScopeType,

        [Parameter(Mandatory)]
        [string]$RecordType,

        [string[]]$TargetIdentities = @(),

        [bool]$Confirmed = $false,

        [string[]]$ApprovedHandlerTypes = @(),

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabRestoreSelectionPolicy
    }

    $evaluations = @(
        foreach ($candidate in @($Candidates)) {
            Test-BoostLabRestoreSelectionCandidate `
                -Candidate $candidate `
                -ToolId $ToolId `
                -SourceAction $SourceAction `
                -ScopeType $ScopeType `
                -RecordType $RecordType `
                -TargetIdentities $TargetIdentities `
                -Confirmed:$Confirmed `
                -ApprovedHandlerTypes $ApprovedHandlerTypes `
                -Policy $Policy
        }
    )
    $eligible = @($evaluations | Where-Object { $_.IsEligible })

    if ($eligible.Count -eq 0) {
        return [pscustomobject]@{
            IsSelected     = $false
            Status         = 'Denied'
            RuntimeAllowed = $false
            SelectedRecord = $null
            Evaluations    = $evaluations
            Errors         = @('No eligible restore record was found.')
            Timestamp      = Get-Date
        }
    }

    if ($eligible.Count -gt 1) {
        return [pscustomobject]@{
            IsSelected     = $false
            Status         = 'Denied'
            RuntimeAllowed = $false
            SelectedRecord = $null
            Evaluations    = $evaluations
            Errors         = @('Restore target is ambiguous or has multiple conflicting eligible records.')
            Timestamp      = Get-Date
        }
    }

    return [pscustomobject]@{
        IsSelected     = $true
        Status         = 'Eligible'
        RuntimeAllowed = $false
        SelectedRecord = $eligible[0]
        Evaluations    = $evaluations
        Errors         = @()
        Timestamp      = Get-Date
    }
}

function New-BoostLabRestoreSelectionPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$CandidateEvaluation
    )

    return [pscustomobject]@{
        Success        = $false
        Status         = if ($CandidateEvaluation.IsEligible) { 'NotImplemented' } else { 'Denied' }
        RuntimeAllowed = $false
        ToolId         = $CandidateEvaluation.ToolId
        SourceAction   = $CandidateEvaluation.SourceAction
        ScopeType      = $CandidateEvaluation.ScopeType
        RecordType     = $CandidateEvaluation.RecordType
        Message        = if ($CandidateEvaluation.IsEligible) {
            'Restore selection planning is available, but production restore execution is not implemented in Phase 67.'
        }
        else {
            'Restore selection candidate is not eligible.'
        }
        Errors         = @($CandidateEvaluation.Errors)
        Timestamp      = Get-Date
    }
}

Export-ModuleMember -Function @(
    'Get-BoostLabRestoreSelectionPolicy'
    'New-BoostLabRestoreSelectionIntegrityHash'
    'Test-BoostLabRestoreSelectionPolicy'
    'Test-BoostLabRestoreSelectionCandidate'
    'Select-BoostLabRestoreSelectionCandidate'
    'New-BoostLabRestoreSelectionPlan'
)
