Set-StrictMode -Version Latest

$script:BoostLabProductionAllowlistGovernancePath = Join-Path `
    (Split-Path -Parent $PSScriptRoot) `
    'config\ProductionAllowlistGovernance.psd1'

function Get-BoostLabProductionAllowlistPropertyValue {
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

function ConvertTo-BoostLabProductionAllowlistArray {
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return @()
    }

    return @($Value)
}

function Get-BoostLabProductionAllowlistGovernancePolicy {
    [CmdletBinding()]
    [OutputType([System.Collections.IDictionary])]
    param(
        [string]$PolicyPath = $script:BoostLabProductionAllowlistGovernancePath
    )

    if (-not (Test-Path -LiteralPath $PolicyPath -PathType Leaf)) {
        throw "Production allowlist governance policy was not found: $PolicyPath"
    }

    return Import-PowerShellDataFile -LiteralPath $PolicyPath
}

function Test-BoostLabProductionAllowlistPolicy {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabProductionAllowlistGovernancePolicy
    }

    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($field in @(
        'SchemaVersion'
        'ApprovalStates'
        'ScopeTypes'
        'SupportedActions'
        'RequiredMetadataFields'
        'HardDenialRules'
        'ProductionAllowlistProposals'
    )) {
        if (-not $Policy.Contains($field)) {
            $errors.Add("Production allowlist governance policy is missing field: $field")
        }
    }

    if (
        $Policy.Contains('SchemaVersion') -and
        [string]$Policy['SchemaVersion'] -ne '1.0'
    ) {
        $errors.Add('Production allowlist governance policy schema is unsupported.')
    }

    foreach ($state in @('Draft', 'Reviewed', 'Approved', 'Rejected', 'Deprecated')) {
        if ($Policy.Contains('ApprovalStates') -and $state -notin @($Policy['ApprovalStates'])) {
            $errors.Add("Production allowlist governance policy is missing approval state: $state")
        }
    }

    foreach ($field in @(
        'ToolId'
        'ToolName'
        'SourcePath'
        'SourceChecksum'
        'DesignReviewDocument'
        'SourceBehaviorGroup'
        'ScopeType'
        'ExactTargetIdentity'
        'MutationType'
        'SupportedAction'
        'RequiredFoundationDependency'
        'RequiredCaptureBeforeMutation'
        'RequiredConfirmationLevel'
        'RequiredPreMutationVerification'
        'RequiredPostMutationVerification'
        'RollbackFeasibility'
        'DefaultRestoreStatus'
        'ProductScopeImpact'
        'RiskLevel'
        'OwnerApprovalNote'
        'ApprovalStatus'
        'ApprovalDateOrVersion'
        'TestsRequired'
        'ValidatorRequired'
        'DenialReason'
    )) {
        if ($Policy.Contains('RequiredMetadataFields') -and $field -notin @($Policy['RequiredMetadataFields'])) {
            $errors.Add("Production allowlist governance policy is missing required metadata field: $field")
        }
    }

    $proposalCount = 0
    if ($Policy.Contains('ProductionAllowlistProposals')) {
        $proposalCount = @(ConvertTo-BoostLabProductionAllowlistArray $Policy['ProductionAllowlistProposals']).Count
    }

    return [pscustomobject]@{
        IsValid       = $errors.Count -eq 0
        Status        = if ($errors.Count -eq 0) { 'Valid' } else { 'Invalid' }
        ProposalCount = $proposalCount
        Errors        = $errors.ToArray()
        Timestamp     = Get-Date
    }
}

function Test-BoostLabProductionAllowlistBroadTarget {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [string]$ScopeType,

        [AllowNull()]
        [string]$Target
    )

    $reasons = [System.Collections.Generic.List[string]]::new()
    $targetText = ([string]$Target).Trim()

    if ([string]::IsNullOrWhiteSpace($targetText)) {
        $reasons.Add('ExactTargetIdentity is required.')
    }
    if ($targetText.IndexOfAny([char[]]'*?[]') -ge 0) {
        $reasons.Add('Wildcard targets are denied.')
    }
    if ($targetText -match '^\s*(HKLM:|HKCU:|HKEY_LOCAL_MACHINE|HKEY_CURRENT_USER)\\?\s*$') {
        $reasons.Add('Broad registry hives are denied.')
    }
    if ($targetText -match '^\s*(HKLM:\\SYSTEM|Registry::HKEY_LOCAL_MACHINE\\SYSTEM|HKEY_LOCAL_MACHINE\\SYSTEM)\s*$') {
        $reasons.Add('Entire protected HKLM SYSTEM roots are denied.')
    }
    if ($targetText -match '(?i)^([A-Z]:\\?|[A-Z]:\\Windows\\?|[A-Z]:\\Program Files\\?|[A-Z]:\\Program Files \(x86\)\\?)$') {
        $reasons.Add('Broad file roots are denied.')
    }
    if ($targetText -match '(?i)^[A-Z]:\\Users\\[^\\]+\\?(Documents|Desktop|Downloads)?\\?$') {
        $reasons.Add('Broad user profile and library roots are denied.')
    }
    if ([string]$ScopeType -eq 'Service' -and $targetText -match '(?i)^(\*|all|services|.*\*)$') {
        $reasons.Add('Wildcard or broad service targets are denied.')
    }
    if ([string]$ScopeType -eq 'Process' -and $targetText -match '(?i)^(\*|all|processes|.*\*)$') {
        $reasons.Add('Broad process stop targets are denied.')
    }
    if ([string]$ScopeType -eq 'ScheduledTask' -and $targetText -match '(?i)^(\*|all|\\?Microsoft\\?Windows\\?)$') {
        $reasons.Add('Dynamic scheduled task mutation is denied.')
    }
    if ([string]$ScopeType -eq 'DownloadArtifact' -and $targetText -match '(?i)(refs/heads|/latest|github\.com/.+/archive/refs|raw\.githubusercontent\.com/.+/main/)') {
        $reasons.Add('Mutable URLs without immutable provenance are denied.')
    }

    return [pscustomobject]@{
        IsDenied = $reasons.Count -gt 0
        Reasons  = $reasons.ToArray()
    }
}

function Test-BoostLabProductionAllowlistProposal {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Proposal,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabProductionAllowlistGovernancePolicy
    }

    $errors = [System.Collections.Generic.List[string]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()

    $requiredFields = @($Policy['RequiredMetadataFields'])
    foreach ($field in $requiredFields) {
        $value = Get-BoostLabProductionAllowlistPropertyValue -InputObject $Proposal -Name $field
        if ($null -eq $value) {
            $errors.Add("Allowlist proposal is missing field: $field")
        }
    }

    $toolId = [string](Get-BoostLabProductionAllowlistPropertyValue -InputObject $Proposal -Name 'ToolId')
    $toolName = [string](Get-BoostLabProductionAllowlistPropertyValue -InputObject $Proposal -Name 'ToolName')
    $sourcePath = [string](Get-BoostLabProductionAllowlistPropertyValue -InputObject $Proposal -Name 'SourcePath')
    $sourceChecksum = [string](Get-BoostLabProductionAllowlistPropertyValue -InputObject $Proposal -Name 'SourceChecksum')
    $designReviewDocument = [string](Get-BoostLabProductionAllowlistPropertyValue -InputObject $Proposal -Name 'DesignReviewDocument')
    $sourceBehaviorGroup = [string](Get-BoostLabProductionAllowlistPropertyValue -InputObject $Proposal -Name 'SourceBehaviorGroup')
    $scopeType = [string](Get-BoostLabProductionAllowlistPropertyValue -InputObject $Proposal -Name 'ScopeType')
    $target = [string](Get-BoostLabProductionAllowlistPropertyValue -InputObject $Proposal -Name 'ExactTargetIdentity')
    $mutationType = [string](Get-BoostLabProductionAllowlistPropertyValue -InputObject $Proposal -Name 'MutationType')
    $supportedAction = [string](Get-BoostLabProductionAllowlistPropertyValue -InputObject $Proposal -Name 'SupportedAction')
    $approvalStatus = [string](Get-BoostLabProductionAllowlistPropertyValue -InputObject $Proposal -Name 'ApprovalStatus')
    $riskLevel = [string](Get-BoostLabProductionAllowlistPropertyValue -InputObject $Proposal -Name 'RiskLevel')
    $denialReason = [string](Get-BoostLabProductionAllowlistPropertyValue -InputObject $Proposal -Name 'DenialReason')
    $approvalDateOrVersion = [string](Get-BoostLabProductionAllowlistPropertyValue -InputObject $Proposal -Name 'ApprovalDateOrVersion')
    $testsRequired = @(
        ConvertTo-BoostLabProductionAllowlistArray (
            Get-BoostLabProductionAllowlistPropertyValue -InputObject $Proposal -Name 'TestsRequired'
        )
    )
    $validatorRequired = [string](Get-BoostLabProductionAllowlistPropertyValue -InputObject $Proposal -Name 'ValidatorRequired')

    foreach ($textPair in @(
        @{ Name = 'ToolId'; Value = $toolId }
        @{ Name = 'ToolName'; Value = $toolName }
        @{ Name = 'SourcePath'; Value = $sourcePath }
        @{ Name = 'DesignReviewDocument'; Value = $designReviewDocument }
        @{ Name = 'SourceBehaviorGroup'; Value = $sourceBehaviorGroup }
        @{ Name = 'MutationType'; Value = $mutationType }
    )) {
        if ([string]::IsNullOrWhiteSpace([string]$textPair.Value)) {
            $errors.Add("$($textPair.Name) cannot be empty.")
        }
    }

    if ($sourceChecksum -notmatch '^[A-Fa-f0-9]{64}$') {
        $errors.Add('SourceChecksum must be a complete SHA-256 hash.')
    }
    if ($scopeType -notin @($Policy['ScopeTypes'])) {
        $errors.Add("ScopeType is not approved by governance: $scopeType")
    }
    if ($supportedAction -notin @($Policy['SupportedActions'])) {
        $errors.Add("SupportedAction is not approved by governance: $supportedAction")
    }
    if ($approvalStatus -notin @($Policy['ApprovalStates'])) {
        $errors.Add("ApprovalStatus is not approved by governance: $approvalStatus")
    }
    if ($riskLevel -notin @('low', 'medium', 'high')) {
        $errors.Add('RiskLevel must be low, medium, or high.')
    }
    if ($approvalStatus -eq 'Approved') {
        $errors.Add('Phase 66 helper cannot approve production scopes. Approval must be recorded in a later dedicated phase.')
    }
    if ($approvalStatus -eq 'Rejected' -and [string]::IsNullOrWhiteSpace($denialReason)) {
        $errors.Add('Rejected proposals must include DenialReason.')
    }
    if ($approvalStatus -in @('Reviewed', 'Approved', 'Deprecated') -and [string]::IsNullOrWhiteSpace($approvalDateOrVersion)) {
        $errors.Add('Reviewed, Approved, and Deprecated proposals must include ApprovalDateOrVersion.')
    }
    if ($testsRequired.Count -eq 0) {
        $errors.Add('TestsRequired must list at least one required test.')
    }
    if ([string]::IsNullOrWhiteSpace($validatorRequired)) {
        $errors.Add('ValidatorRequired cannot be empty.')
    }

    $targetValidation = Test-BoostLabProductionAllowlistBroadTarget -ScopeType $scopeType -Target $target
    foreach ($reason in @($targetValidation.Reasons)) {
        $errors.Add($reason)
    }

    foreach ($booleanField in @(
        'RequiredCaptureBeforeMutation'
        'RequiredPreMutationVerification'
        'RequiredPostMutationVerification'
    )) {
        $value = Get-BoostLabProductionAllowlistPropertyValue -InputObject $Proposal -Name $booleanField
        if ($value -isnot [bool]) {
            $errors.Add("$booleanField must be Boolean.")
        }
    }

    if ($approvalStatus -eq 'Draft') {
        $warnings.Add('Draft proposals are non-executing and not eligible for runtime use.')
    }
    if ($approvalStatus -eq 'Reviewed') {
        $warnings.Add('Reviewed proposals are non-executing until separately approved by Yazan.')
    }

    return [pscustomobject]@{
        IsValid        = $errors.Count -eq 0
        Status         = if ($errors.Count -eq 0) { 'ValidatedDraft' } else { 'Blocked' }
        ToolId         = $toolId
        ToolName       = $toolName
        ScopeType      = $scopeType
        ApprovalStatus = $approvalStatus
        RuntimeAllowed = $false
        Errors         = $errors.ToArray()
        Warnings       = $warnings.ToArray()
        Timestamp      = Get-Date
    }
}

function New-BoostLabProductionAllowlistDecision {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Proposal,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    $validation = Test-BoostLabProductionAllowlistProposal -Proposal $Proposal -Policy $Policy
    return [pscustomobject]@{
        Success        = $false
        Status         = if ($validation.IsValid) { 'NotImplemented' } else { 'Blocked' }
        RuntimeAllowed = $false
        ProcessStarted = $false
        CommandExecuted = $false
        ToolId         = $validation.ToolId
        ScopeType      = $validation.ScopeType
        Message        = if ($validation.IsValid) {
            'Production allowlist governance validation is advisory only in Phase 66.'
        }
        else {
            'Production allowlist proposal was blocked by governance validation.'
        }
        Errors         = @($validation.Errors)
        Warnings       = @($validation.Warnings)
        Timestamp      = Get-Date
    }
}

Export-ModuleMember -Function @(
    'Get-BoostLabProductionAllowlistGovernancePolicy'
    'Test-BoostLabProductionAllowlistPolicy'
    'Test-BoostLabProductionAllowlistProposal'
    'New-BoostLabProductionAllowlistDecision'
)
