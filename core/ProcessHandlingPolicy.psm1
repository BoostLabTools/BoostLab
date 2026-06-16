Set-StrictMode -Version Latest

$script:BoostLabProcessHandlingPolicyPath = Join-Path `
    (Split-Path -Parent $PSScriptRoot) `
    'config\ProcessHandlingPolicy.psd1'

function Get-BoostLabProcessHandlingPropertyValue {
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

function ConvertTo-BoostLabProcessHandlingArray {
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return @()
    }
    return @($Value)
}

function Get-BoostLabProcessHandlingPolicy {
    [CmdletBinding()]
    [OutputType([System.Collections.IDictionary])]
    param(
        [string]$PolicyPath = $script:BoostLabProcessHandlingPolicyPath
    )

    if (-not (Test-Path -LiteralPath $PolicyPath -PathType Leaf)) {
        throw "Process handling policy was not found: $PolicyPath"
    }

    return Import-PowerShellDataFile -LiteralPath $PolicyPath
}

function Test-BoostLabProcessHandlingPolicy {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabProcessHandlingPolicy
    }

    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($field in @(
        'SchemaVersion'
        'ProcessOperationTypes'
        'NonMutatingOperationTypes'
        'MutatingOperationTypes'
        'ApprovalStates'
        'EligibilityStates'
        'RequiredMetadataFields'
        'RiskLevels'
        'ConfirmationLevels'
        'SystemCriticalProcessNames'
        'SecurityProcessNames'
        'ShellProcessNames'
        'BrowserProcessNames'
        'DeferredProcessToolIds'
        'HardDenialRules'
        'ProcessHandlingScopes'
        'ApprovedProcessTargets'
    )) {
        if (-not $Policy.Contains($field)) {
            $errors.Add("Process handling policy is missing field: $field")
        }
    }

    if ($Policy.Contains('SchemaVersion') -and [string]$Policy['SchemaVersion'] -ne '1.0') {
        $errors.Add('Process handling policy schema is unsupported.')
    }

    foreach ($operation in @(
        'DetectOnly'
        'WaitForExit'
        'GracefulClose'
        'StopProcess'
        'RestartProcess'
        'LaunchHandoff'
        'ExplorerRestart'
        'ToolOwnedProcessCleanup'
    )) {
        if ($Policy.Contains('ProcessOperationTypes') -and $operation -notin @($Policy['ProcessOperationTypes'])) {
            $errors.Add("Process handling policy is missing operation type: $operation")
        }
    }

    foreach ($field in @(
        'ToolId'
        'ToolName'
        'SourcePath'
        'SourceChecksum'
        'DesignReviewDocument'
        'SourceBehaviorGroup'
        'ProcessOperationType'
        'ExactProcessName'
        'ExactExecutablePathRequirement'
        'PublisherSignatureRequirement'
        'UserSessionScope'
        'OwnershipModel'
        'IsToolOwnedProcess'
        'UnsavedUserDataRisk'
        'ConfirmationLevel'
        'PreflightVerification'
        'PostOperationVerification'
        'TimeoutBehavior'
        'RetryBehavior'
        'RollbackRecoveryFeasibility'
        'ActionPlanTextRequirement'
        'ActivityLogTextRequirement'
        'RiskLevel'
        'ApprovalStatus'
        'DenialReason'
    )) {
        if ($Policy.Contains('RequiredMetadataFields') -and $field -notin @($Policy['RequiredMetadataFields'])) {
            $errors.Add("Process handling policy is missing required metadata field: $field")
        }
    }

    $scopeCount = 0
    if ($Policy.Contains('ProcessHandlingScopes')) {
        $scopeCount = @(ConvertTo-BoostLabProcessHandlingArray $Policy['ProcessHandlingScopes']).Count
    }
    $targetCount = 0
    if ($Policy.Contains('ApprovedProcessTargets')) {
        $targetCount = @(ConvertTo-BoostLabProcessHandlingArray $Policy['ApprovedProcessTargets']).Count
    }

    return [pscustomobject]@{
        IsValid     = $errors.Count -eq 0
        Status      = if ($errors.Count -eq 0) { 'Valid' } else { 'Invalid' }
        ScopeCount  = $scopeCount
        TargetCount = $targetCount
        Errors      = $errors.ToArray()
        Timestamp   = Get-Date
    }
}

function Test-BoostLabProcessNameDenied {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [string]$ProcessName,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabProcessHandlingPolicy
    }

    $errors = [System.Collections.Generic.List[string]]::new()
    $name = ([string]$ProcessName).Trim()

    if ([string]::IsNullOrWhiteSpace($name)) {
        $errors.Add('ExactProcessName is required.')
    }
    if ($name.IndexOfAny([char[]]'*?[]') -ge 0) {
        $errors.Add('Wildcard process names are denied.')
    }
    if ($name -match '(?i)^(\*|all|processes|allprocesses|.+\*)$') {
        $errors.Add('Broad process-stop patterns are denied.')
    }
    if ($name -match '(?i)^(Microsoft|Google|NVIDIA|AMD|Intel|Adobe|Mozilla|Valve|Epic|Xbox|Gaming)$') {
        $errors.Add('Stopping all processes from a vendor without exact names is denied.')
    }
    if ($name -in @($Policy['SystemCriticalProcessNames'])) {
        $errors.Add("System-critical process handling is denied: $name")
    }

    return [pscustomobject]@{
        IsDenied = $errors.Count -gt 0
        Errors   = $errors.ToArray()
    }
}

function Test-BoostLabProcessHandlingProposal {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Proposal,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy,

        [bool]$Confirmed = $false,

        [string[]]$ApprovedTestProcessNames = @(),

        [switch]$AllowMockApproval
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabProcessHandlingPolicy
    }

    $errors = [System.Collections.Generic.List[string]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()

    foreach ($field in @($Policy['RequiredMetadataFields'])) {
        if ($null -eq (Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name $field)) {
            $errors.Add("Process handling proposal is missing field: $field")
        }
    }

    $toolId = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'ToolId')
    $toolName = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'ToolName')
    $sourcePath = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'SourcePath')
    $sourceChecksum = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'SourceChecksum')
    $designReviewDocument = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'DesignReviewDocument')
    $sourceBehaviorGroup = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'SourceBehaviorGroup')
    $operationType = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'ProcessOperationType')
    $processName = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'ExactProcessName')
    $executablePathRequirement = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'ExactExecutablePathRequirement')
    $publisherSignatureRequirement = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'PublisherSignatureRequirement')
    $userSessionScope = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'UserSessionScope')
    $ownershipModel = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'OwnershipModel')
    $isToolOwned = Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'IsToolOwnedProcess'
    $unsavedRisk = Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'UnsavedUserDataRisk'
    $confirmationLevel = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'ConfirmationLevel')
    $preflightVerification = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'PreflightVerification')
    $postOperationVerification = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'PostOperationVerification')
    $timeoutBehavior = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'TimeoutBehavior')
    $retryBehavior = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'RetryBehavior')
    $rollbackRecoveryFeasibility = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'RollbackRecoveryFeasibility')
    $actionPlanText = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'ActionPlanTextRequirement')
    $activityLogText = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'ActivityLogTextRequirement')
    $riskLevel = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'RiskLevel')
    $approvalStatus = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'ApprovalStatus')
    $denialReason = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'DenialReason')
    $identityValidationMode = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'IdentityValidationMode')
    $MatchCardinality = [string](Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'MatchCardinality')
    $requiresGracefulPath = Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'RequiresGracefulPath'
    $requiresTrustedInstaller = Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'RequiresTrustedInstaller'
    $requiresSafeMode = Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'RequiresSafeMode'
    $requiresReboot = Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'RequiresReboot'
    $requiresDownloadOrInstaller = Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'RequiresDownloadOrInstaller'
    $requiresServiceMutation = Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'RequiresServiceMutation'
    $requiresDriverMutation = Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'RequiresDriverMutation'
    $targetPresentInDesign = Get-BoostLabProcessHandlingPropertyValue -InputObject $Proposal -Name 'TargetPresentInDesignDocument'

    foreach ($textPair in @(
        @{ Name = 'ToolId'; Value = $toolId }
        @{ Name = 'ToolName'; Value = $toolName }
        @{ Name = 'SourcePath'; Value = $sourcePath }
        @{ Name = 'DesignReviewDocument'; Value = $designReviewDocument }
        @{ Name = 'SourceBehaviorGroup'; Value = $sourceBehaviorGroup }
        @{ Name = 'ExactProcessName'; Value = $processName }
        @{ Name = 'UserSessionScope'; Value = $userSessionScope }
        @{ Name = 'OwnershipModel'; Value = $ownershipModel }
        @{ Name = 'PreflightVerification'; Value = $preflightVerification }
        @{ Name = 'PostOperationVerification'; Value = $postOperationVerification }
        @{ Name = 'TimeoutBehavior'; Value = $timeoutBehavior }
        @{ Name = 'RetryBehavior'; Value = $retryBehavior }
        @{ Name = 'RollbackRecoveryFeasibility'; Value = $rollbackRecoveryFeasibility }
        @{ Name = 'ActionPlanTextRequirement'; Value = $actionPlanText }
        @{ Name = 'ActivityLogTextRequirement'; Value = $activityLogText }
    )) {
        if ([string]::IsNullOrWhiteSpace([string]$textPair.Value)) {
            $errors.Add("$($textPair.Name) cannot be empty.")
        }
    }

    if ($sourceChecksum -notmatch '^[A-Fa-f0-9]{64}$') {
        $errors.Add('SourceChecksum must be a complete SHA-256 hash.')
    }
    if ($operationType -notin @($Policy['ProcessOperationTypes'])) {
        $errors.Add("Unsupported process operation type: $operationType")
    }
    if ($approvalStatus -notin @($Policy['ApprovalStates'])) {
        $errors.Add("ApprovalStatus is not supported by process policy: $approvalStatus")
    }
    if ($riskLevel -notin @($Policy['RiskLevels'])) {
        $errors.Add("RiskLevel is not supported by process policy: $riskLevel")
    }
    if ($confirmationLevel -notin @($Policy['ConfirmationLevels'])) {
        $errors.Add("ConfirmationLevel is not supported by process policy: $confirmationLevel")
    }
    foreach ($booleanPair in @(
        @{ Name = 'IsToolOwnedProcess'; Value = $isToolOwned }
        @{ Name = 'UnsavedUserDataRisk'; Value = $unsavedRisk }
        @{ Name = 'TargetPresentInDesignDocument'; Value = $targetPresentInDesign }
    )) {
        if ($booleanPair.Value -isnot [bool]) {
            $errors.Add("$($booleanPair.Name) must be Boolean.")
        }
    }

    $processNameValidation = Test-BoostLabProcessNameDenied -ProcessName $processName -Policy $Policy
    foreach ($processNameError in @($processNameValidation.Errors)) {
        $errors.Add($processNameError)
    }

    if ($processName -in @($Policy['SecurityProcessNames']) -and $approvalStatus -ne 'Approved') {
        $errors.Add("Security process handling requires explicit security-sensitive approval: $processName")
    }
    if ($processName -in @($Policy['ShellProcessNames']) -and $operationType -ne 'ExplorerRestart') {
        $errors.Add('Shell or Explorer process handling requires exact ExplorerRestart policy.')
    }
    if (
        $processName -in @($Policy['BrowserProcessNames']) -and
        $operationType -in @('StopProcess', 'RestartProcess', 'GracefulClose') -and
        $approvalStatus -ne 'Approved'
    ) {
        $errors.Add('Broad browser process handling requires exact tool-specific design and confirmation.')
    }
    if ($identityValidationMode -eq 'PidOnly') {
        $errors.Add('Killing processes by PID only without identity validation is denied.')
    }
    if ([string]::IsNullOrWhiteSpace($userSessionScope) -or $userSessionScope -eq 'Unknown') {
        $errors.Add('Process handling requires user/session validation.')
    }
    if ($requiresGracefulPath -eq $true -and $operationType -eq 'StopProcess') {
        $errors.Add('Force-kill before graceful path is denied when graceful close is required.')
    }
    if ($operationType -eq 'RestartProcess' -and [string]::IsNullOrWhiteSpace($executablePathRequirement)) {
        $errors.Add('Restarting processes requires exact executable path approval.')
    }
    if ($operationType -eq 'LaunchHandoff' -and [string]::IsNullOrWhiteSpace($publisherSignatureRequirement)) {
        $errors.Add('Launch handoff requires provenance or execution descriptor for external executable use.')
    }
    if ($requiresTrustedInstaller -eq $true) {
        $errors.Add('TrustedInstaller-dependent process handling requires TrustedInstaller foundation approval.')
    }
    if ($requiresSafeMode -eq $true) {
        $errors.Add('Safe Mode process handling requires Safe Mode workflow approval.')
    }
    if ($requiresReboot -eq $true) {
        $errors.Add('Reboot-adjacent process handling requires reboot/recovery workflow approval.')
    }
    if ($requiresDownloadOrInstaller -eq $true) {
        $errors.Add('Download or installer process handling requires provenance and installer execution approval.')
    }
    if ($requiresServiceMutation -eq $true) {
        $errors.Add('Service-adjacent process handling requires service mutation approval.')
    }
    if ($requiresDriverMutation -eq $true) {
        $errors.Add('Driver-adjacent process handling requires driver mutation approval.')
    }
    if ($toolId -in @($Policy['DeferredProcessToolIds']) -and $approvalStatus -ne 'Approved') {
        $errors.Add("Deferred tool process handling is denied without production allowlist approval: $toolId")
    }
    if ($unsavedRisk -eq $true -and (-not $Confirmed -or $confirmationLevel -notin @('Explicit', 'HighRiskExplicit'))) {
        $errors.Add('Unsaved user data risk requires explicit warning and confirmation.')
    }
    if ($MatchCardinality -eq 'Ambiguous') {
        $errors.Add('Ambiguous process matches are denied.')
    }
    if ($targetPresentInDesign -ne $true) {
        $errors.Add('Process target is not present in the tool design document.')
    }
    if ($approvalStatus -eq 'Approved') {
        $errors.Add('Phase 68 helper cannot approve production process handling.')
    }
    if ($approvalStatus -eq 'Rejected' -and [string]::IsNullOrWhiteSpace($denialReason)) {
        $errors.Add('Rejected process proposals must include DenialReason.')
    }

    $isNonMutating = $operationType -in @($Policy['NonMutatingOperationTypes'])
    $isMockApproved = $AllowMockApproval.IsPresent -and $processName -in @($ApprovedTestProcessNames)
    if (-not $isNonMutating -and -not $isMockApproved) {
        $errors.Add('Production process mutation is not approved in Phase 68.')
    }

    if ($isNonMutating -and $errors.Count -eq 0) {
        $warnings.Add('DetectOnly proposal is eligible for mock validation only and does not permit runtime process access.')
    }
    if ($isMockApproved -and $errors.Count -eq 0) {
        $warnings.Add('Mock-approved process proposal is test-only and does not permit production runtime execution.')
    }

    $status = if ($errors.Count -eq 0) {
        if ($isNonMutating) { 'Eligible' } else { 'Reviewed' }
    }
    elseif ($operationType -notin @($Policy['ProcessOperationTypes'])) {
        'Invalid'
    }
    else {
        'Denied'
    }

    return [pscustomobject]@{
        IsEligible       = $errors.Count -eq 0
        Status           = $status
        ToolId           = $toolId
        ToolName         = $toolName
        ProcessName      = $processName
        OperationType    = $operationType
        RuntimeAllowed   = $false
        ProcessStarted   = $false
        ProcessStopped   = $false
        CommandExecuted  = $false
        Errors           = $errors.ToArray()
        Warnings         = $warnings.ToArray()
        Timestamp        = Get-Date
    }
}

function New-BoostLabProcessHandlingPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$ProposalEvaluation
    )

    return [pscustomobject]@{
        Success         = $false
        Status          = if ($ProposalEvaluation.IsEligible) { 'NotImplemented' } else { 'Denied' }
        RuntimeAllowed  = $false
        ProcessStarted  = $false
        ProcessStopped  = $false
        CommandExecuted = $false
        ToolId          = $ProposalEvaluation.ToolId
        ProcessName     = $ProposalEvaluation.ProcessName
        OperationType   = $ProposalEvaluation.OperationType
        Message         = if ($ProposalEvaluation.IsEligible) {
            'Process handling validation is available, but production process execution is not implemented in Phase 68.'
        }
        else {
            'Process handling proposal was denied by policy validation.'
        }
        Errors          = @($ProposalEvaluation.Errors)
        Warnings        = @($ProposalEvaluation.Warnings)
        Timestamp       = Get-Date
    }
}

Export-ModuleMember -Function @(
    'Get-BoostLabProcessHandlingPolicy'
    'Test-BoostLabProcessHandlingPolicy'
    'Test-BoostLabProcessNameDenied'
    'Test-BoostLabProcessHandlingProposal'
    'New-BoostLabProcessHandlingPlan'
)
