Set-StrictMode -Version Latest

$script:BoostLabSafeModeSchemaVersion = '1.0'
$script:BoostLabSafeModePolicyPath = Join-Path `
    (Split-Path -Parent $PSScriptRoot) `
    'config\SafeModeRecoveryPolicy.psd1'
$script:BoostLabSafeModeTypes = @(
    'Minimal'
    'Networking'
    'CommandShell'
)
$script:BoostLabSafeModeStatuses = @(
    'Prepared'
    'PendingEntry'
    'PendingResume'
    'Cancelled'
    'Completed'
    'Failed'
)
$script:BoostLabSafeModeForbiddenProperties = @(
    'Command'
    'CommandLine'
    'Arguments'
    'Executable'
    'Script'
    'ScriptBlock'
    'ScriptPath'
    'Uri'
    'Url'
)

function Get-BoostLabSafeModePropertyValue {
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

function Test-BoostLabSafeModePropertyExists {
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$Name
    )

    if ($null -eq $InputObject) {
        return $false
    }
    if ($InputObject -is [System.Collections.IDictionary]) {
        return $InputObject.Contains($Name)
    }
    return $null -ne $InputObject.PSObject.Properties[$Name]
}

function ConvertTo-BoostLabSafeModeStringArray {
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return @()
    }
    return @(
        @($Value) |
            ForEach-Object { [string]$_ } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
}

function Test-BoostLabSafeModeExactIdentifier {
    param(
        [AllowNull()]
        [object]$Value
    )

    $text = [string]$Value
    if (
        [string]::IsNullOrWhiteSpace($text) -or
        $text.IndexOfAny([char[]]'*?[]') -ge 0
    ) {
        return $false
    }
    return $text -match '^[A-Za-z0-9][A-Za-z0-9._-]+$'
}

function Test-BoostLabSafeModeRawCommand {
    param(
        [AllowNull()]
        [object]$InputObject
    )

    foreach ($name in $script:BoostLabSafeModeForbiddenProperties) {
        if (Test-BoostLabSafeModePropertyExists $InputObject $name) {
            return $true
        }
    }
    return $false
}

function ConvertTo-BoostLabSafeModeFullPath {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'A non-empty local absolute path is required.'
    }
    if (
        $Path.StartsWith('\\') -or
        $Path -match '^[A-Za-z][A-Za-z0-9+.-]*://'
    ) {
        throw 'Network and URI paths are denied.'
    }
    if (
        $Path.IndexOfAny([char[]]'*?[]') -ge 0 -or
        -not [IO.Path]::IsPathRooted($Path)
    ) {
        throw 'Only exact local absolute paths are allowed.'
    }
    if ('..' -in @($Path -split '[\\/]' | Where-Object { $_ })) {
        throw 'Path traversal is denied.'
    }
    return [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
}

function Test-BoostLabSafeModePathWithinRoot {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Root
    )

    $fullPath = ConvertTo-BoostLabSafeModeFullPath -Path $Path
    $fullRoot = ConvertTo-BoostLabSafeModeFullPath -Path $Root
    if ($fullPath.Equals($fullRoot, [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    return $fullPath.StartsWith(
        $fullRoot + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase
    )
}

function Get-BoostLabSafeModeRecoveryPolicy {
    [CmdletBinding()]
    [OutputType([System.Collections.IDictionary])]
    param(
        [string]$PolicyPath = $script:BoostLabSafeModePolicyPath
    )

    if (-not (Test-Path -LiteralPath $PolicyPath -PathType Leaf)) {
        throw "Safe Mode recovery policy was not found: $PolicyPath"
    }
    return Import-PowerShellDataFile -LiteralPath $PolicyPath
}

function Get-BoostLabSafeModeRecoveryStateRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ([string]::IsNullOrWhiteSpace($env:ProgramData)) {
        throw 'The ProgramData environment variable is not available.'
    }
    return Join-Path $env:ProgramData 'BoostLab\State\SafeModeRecovery'
}

function Test-BoostLabSafeModeRecoveryPolicy {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabSafeModeRecoveryPolicy
    }
    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($field in @('SchemaVersion', 'MaxRecordAgeDays', 'SafeModeScopes')) {
        if (-not $Policy.Contains($field)) {
            $errors.Add("Safe Mode recovery policy is missing field: $field")
        }
    }
    if (
        $Policy.Contains('SchemaVersion') -and
        [string]$Policy['SchemaVersion'] -ne
            $script:BoostLabSafeModeSchemaVersion
    ) {
        $errors.Add('Safe Mode recovery policy schema is unsupported.')
    }
    $maxAge = 0
    if (
        $Policy.Contains('MaxRecordAgeDays') -and
        (
            -not [int]::TryParse(
                [string]$Policy['MaxRecordAgeDays'],
                [ref]$maxAge
            ) -or
            $maxAge -le 0
        )
    ) {
        $errors.Add('MaxRecordAgeDays must be positive.')
    }

    $scopeIds = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $scopes = @(
        if ($Policy.Contains('SafeModeScopes')) {
            @($Policy['SafeModeScopes'])
        }
    )
    foreach ($scope in $scopes) {
        $scopeId = [string](
            Get-BoostLabSafeModePropertyValue $scope 'ScopeId'
        )
        foreach ($field in @(
            'ScopeId'
            'ToolIds'
            'ActionIds'
            'AllowedSafeModeTypes'
            'RequiredCheckpointNames'
            'RequiredFoundations'
            'AllowedStateReferenceRoots'
            'AllowedRebootWorkflowScopeIds'
            'AllowedRebootRecordRoots'
            'AllowedResumeHandlerIds'
            'AllowedResumeArtifactPaths'
            'AllowedExitHandlerIds'
            'AllowedExitArtifactPaths'
            'RequiresStateCapture'
            'RequiresRebootWorkflowReference'
            'RequiresExitPlan'
            'RequiresPostResumeVerification'
            'AllowCommandShell'
            'MaxResumeSteps'
            'MaxExitSteps'
            'MaxDurationMinutes'
            'AllowCancellation'
            'RequiredConfirmationLevel'
            'NeedsExplicitConfirmation'
        )) {
            if (-not (Test-BoostLabSafeModePropertyExists $scope $field)) {
                $errors.Add("Safe Mode scope is missing field: $field")
            }
        }
        if (-not (Test-BoostLabSafeModeExactIdentifier $scopeId)) {
            $errors.Add('Safe Mode scope ids must be exact identifiers.')
        }
        elseif (-not $scopeIds.Add($scopeId)) {
            $errors.Add("Duplicate Safe Mode scope id: $scopeId")
        }

        foreach ($identityField in @(
            'ToolIds'
            'ActionIds'
            'AllowedSafeModeTypes'
            'RequiredCheckpointNames'
            'RequiredFoundations'
            'AllowedRebootWorkflowScopeIds'
            'AllowedResumeHandlerIds'
            'AllowedExitHandlerIds'
        )) {
            $identities = @(
                ConvertTo-BoostLabSafeModeStringArray (
                    Get-BoostLabSafeModePropertyValue $scope $identityField
                )
            )
            if ($identities.Count -eq 0) {
                $errors.Add("Scope '$scopeId' requires $identityField.")
            }
            foreach ($identity in $identities) {
                if (-not (Test-BoostLabSafeModeExactIdentifier $identity)) {
                    $errors.Add("Scope '$scopeId' has invalid $identityField.")
                }
            }
        }
        $safeModeTypes = @(
            ConvertTo-BoostLabSafeModeStringArray (
                Get-BoostLabSafeModePropertyValue `
                    $scope `
                    'AllowedSafeModeTypes'
            )
        )
        foreach ($safeModeType in $safeModeTypes) {
            if ($safeModeType -notin $script:BoostLabSafeModeTypes) {
                $errors.Add(
                    "Scope '$scopeId' has unsupported Safe Mode type " +
                    "'$safeModeType'."
                )
            }
        }
        if (
            'CommandShell' -in $safeModeTypes -and
            -not [bool](
                Get-BoostLabSafeModePropertyValue $scope 'AllowCommandShell'
            )
        ) {
            $errors.Add(
                "Scope '$scopeId' lists CommandShell without separate approval."
            )
        }

        foreach ($pathField in @(
            'AllowedStateReferenceRoots'
            'AllowedRebootRecordRoots'
            'AllowedResumeArtifactPaths'
            'AllowedExitArtifactPaths'
        )) {
            foreach ($path in ConvertTo-BoostLabSafeModeStringArray (
                Get-BoostLabSafeModePropertyValue $scope $pathField
            )) {
                try {
                    ConvertTo-BoostLabSafeModeFullPath -Path $path | Out-Null
                }
                catch {
                    $errors.Add("Scope '$scopeId' has invalid $pathField.")
                }
            }
        }

        foreach ($booleanField in @(
            'RequiresStateCapture'
            'RequiresRebootWorkflowReference'
            'RequiresExitPlan'
            'RequiresPostResumeVerification'
            'AllowCommandShell'
            'AllowCancellation'
            'NeedsExplicitConfirmation'
        )) {
            if (
                (
                    Get-BoostLabSafeModePropertyValue $scope $booleanField
                ) -isnot [bool]
            ) {
                $errors.Add("Scope '$scopeId' $booleanField must be Boolean.")
            }
        }
        foreach ($requiredTrue in @(
            'RequiresStateCapture'
            'RequiresRebootWorkflowReference'
            'RequiresExitPlan'
            'RequiresPostResumeVerification'
            'NeedsExplicitConfirmation'
        )) {
            if (-not [bool](
                Get-BoostLabSafeModePropertyValue $scope $requiredTrue
            )) {
                $errors.Add("Scope '$scopeId' must set $requiredTrue.")
            }
        }
        if (
            [string](
                Get-BoostLabSafeModePropertyValue `
                    $scope `
                    'RequiredConfirmationLevel'
            ) -ne 'Explicit'
        ) {
            $errors.Add("Scope '$scopeId' must require Explicit confirmation.")
        }
        foreach ($limitField in @(
            'MaxResumeSteps'
            'MaxExitSteps'
            'MaxDurationMinutes'
        )) {
            $limit = 0
            if (
                -not [int]::TryParse(
                    [string](
                        Get-BoostLabSafeModePropertyValue $scope $limitField
                    ),
                    [ref]$limit
                ) -or
                $limit -le 0
            ) {
                $errors.Add("Scope '$scopeId' $limitField must be positive.")
            }
        }
    }

    return [pscustomobject]@{
        IsValid    = $errors.Count -eq 0
        Status     = if ($errors.Count -eq 0) { 'Valid' } else { 'Invalid' }
        ScopeCount = @($scopes).Count
        Errors     = $errors.ToArray()
        Timestamp  = Get-Date
    }
}

function Find-BoostLabSafeModeScope {
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ActionId,

        [Parameter(Mandatory)]
        [string]$ScopeId,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Policy
    )

    foreach ($scope in @($Policy['SafeModeScopes'])) {
        if (
            [string](
                Get-BoostLabSafeModePropertyValue $scope 'ScopeId'
            ) -eq $ScopeId -and
            $ToolId -in (ConvertTo-BoostLabSafeModeStringArray (
                Get-BoostLabSafeModePropertyValue $scope 'ToolIds'
            )) -and
            $ActionId -in (ConvertTo-BoostLabSafeModeStringArray (
                Get-BoostLabSafeModePropertyValue $scope 'ActionIds'
            ))
        ) {
            return $scope
        }
    }
    return $null
}

function Test-BoostLabSafeModeWorkflowTarget {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ActionId,

        [Parameter(Mandatory)]
        [string]$ScopeId,

        [ValidateSet('Minimal', 'Networking', 'CommandShell')]
        [string]$SafeModeType,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabSafeModeRecoveryPolicy
    }
    $errors = [System.Collections.Generic.List[string]]::new()
    $policyValidation = Test-BoostLabSafeModeRecoveryPolicy -Policy $Policy
    if (-not $policyValidation.IsValid) {
        $errors.AddRange([string[]]@($policyValidation.Errors))
    }
    $scope = Find-BoostLabSafeModeScope `
        -ToolId $ToolId `
        -ActionId $ActionId `
        -ScopeId $ScopeId `
        -Policy $Policy
    if ($null -eq $scope) {
        $errors.Add(
            'Tool, action, and Safe Mode scope are not in the exact allowlist.'
        )
    }
    elseif ($SafeModeType -notin (ConvertTo-BoostLabSafeModeStringArray (
        Get-BoostLabSafeModePropertyValue $scope 'AllowedSafeModeTypes'
    ))) {
        $errors.Add("Safe Mode type '$SafeModeType' is not approved.")
    }

    return [pscustomobject]@{
        IsAllowed = $errors.Count -eq 0
        Status    = if ($errors.Count -eq 0) { 'Allowed' } else { 'Blocked' }
        Scope     = $scope
        Errors    = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function Test-BoostLabSafeModeCheckpointSet {
    param(
        [AllowNull()]
        [object]$Checkpoints,

        [Parameter(Mandatory)]
        [object]$Scope
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    foreach ($checkpoint in @($Checkpoints)) {
        $name = [string](
            Get-BoostLabSafeModePropertyValue $checkpoint 'Name'
        )
        $status = [string](
            Get-BoostLabSafeModePropertyValue $checkpoint 'Status'
        )
        $evidence = [string](
            Get-BoostLabSafeModePropertyValue $checkpoint 'Evidence'
        )
        if (
            -not (Test-BoostLabSafeModeExactIdentifier $name) -or
            -not $seen.Add($name)
        ) {
            $errors.Add('Checkpoint names must be exact and unique.')
        }
        if ($status -ne 'Passed') {
            $errors.Add("Pre-Safe-Mode checkpoint '$name' has not passed.")
        }
        if ([string]::IsNullOrWhiteSpace($evidence)) {
            $errors.Add("Pre-Safe-Mode checkpoint '$name' lacks evidence.")
        }
    }
    foreach ($required in ConvertTo-BoostLabSafeModeStringArray (
        Get-BoostLabSafeModePropertyValue $Scope 'RequiredCheckpointNames'
    )) {
        if (-not $seen.Contains($required)) {
            $errors.Add("Required pre-Safe-Mode checkpoint is missing: $required")
        }
    }
    return [pscustomobject]@{
        IsValid = $errors.Count -eq 0
        Errors  = $errors.ToArray()
    }
}

function Test-BoostLabSafeModeStateReferences {
    param(
        [AllowNull()]
        [object]$References,

        [Parameter(Mandatory)]
        [object]$Scope
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $items = @($References)
    if (
        [bool](
            Get-BoostLabSafeModePropertyValue $Scope 'RequiresStateCapture'
        ) -and
        $items.Count -eq 0
    ) {
        $errors.Add('Required state-capture references are missing.')
    }
    $allowedRoots = @(
        ConvertTo-BoostLabSafeModeStringArray (
            Get-BoostLabSafeModePropertyValue `
                $Scope `
                'AllowedStateReferenceRoots'
        )
    )
    $requiredFoundations = @(
        ConvertTo-BoostLabSafeModeStringArray (
            Get-BoostLabSafeModePropertyValue $Scope 'RequiredFoundations'
        )
    )
    $foundFoundations = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    foreach ($reference in $items) {
        $referenceId = [string](
            Get-BoostLabSafeModePropertyValue $reference 'ReferenceId'
        )
        $foundation = [string](
            Get-BoostLabSafeModePropertyValue $reference 'Foundation'
        )
        $recordPath = [string](
            Get-BoostLabSafeModePropertyValue $reference 'RecordPath'
        )
        $recordHash = [string](
            Get-BoostLabSafeModePropertyValue $reference 'RecordHash'
        )
        if (
            -not (Test-BoostLabSafeModeExactIdentifier $referenceId) -or
            -not (Test-BoostLabSafeModeExactIdentifier $foundation)
        ) {
            $errors.Add('State references require exact identities.')
        }
        else {
            $foundFoundations.Add($foundation) | Out-Null
        }
        if (-not [bool](
            Get-BoostLabSafeModePropertyValue $reference 'Verified'
        )) {
            $errors.Add("State reference '$referenceId' is not verified.")
        }
        if ([string]::IsNullOrWhiteSpace($recordHash)) {
            $errors.Add("State reference '$referenceId' lacks an integrity hash.")
        }
        try {
            $trusted = $false
            foreach ($root in $allowedRoots) {
                if (Test-BoostLabSafeModePathWithinRoot $recordPath $root) {
                    $trusted = $true
                    break
                }
            }
            if (-not $trusted) {
                $errors.Add(
                    "State reference '$referenceId' is outside trusted roots."
                )
            }
        }
        catch {
            $errors.Add("State reference '$referenceId' has an invalid path.")
        }
    }
    foreach ($foundation in $requiredFoundations) {
        if (-not $foundFoundations.Contains($foundation)) {
            $errors.Add("Required foundation reference is missing: $foundation")
        }
    }
    return [pscustomobject]@{
        IsValid = $errors.Count -eq 0
        Errors  = $errors.ToArray()
    }
}

function Test-BoostLabSafeModeRebootReference {
    param(
        [AllowNull()]
        [object]$Reference,

        [Parameter(Mandatory)]
        [object]$Scope,

        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ActionId
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    if ($null -eq $Reference) {
        $errors.Add('A verified Phase 40 reboot workflow reference is required.')
    }
    else {
        foreach ($field in @(
            'ReferenceId'
            'ScopeId'
            'RecordPath'
            'RecordHash'
            'Verified'
            'ToolId'
            'ActionId'
            'RequestedRebootType'
        )) {
            if (-not (Test-BoostLabSafeModePropertyExists $Reference $field)) {
                $errors.Add("Reboot workflow reference is missing field: $field")
            }
        }
        if (-not [bool](
            Get-BoostLabSafeModePropertyValue $Reference 'Verified'
        )) {
            $errors.Add('Phase 40 reboot workflow reference is not verified.')
        }
        if (
            [string](
                Get-BoostLabSafeModePropertyValue $Reference 'ToolId'
            ) -ne $ToolId -or
            [string](
                Get-BoostLabSafeModePropertyValue $Reference 'ActionId'
            ) -ne $ActionId
        ) {
            $errors.Add('Phase 40 reboot workflow identity does not match.')
        }
        if (
            [string](
                Get-BoostLabSafeModePropertyValue `
                    $Reference `
                    'RequestedRebootType'
            ) -ne 'SafeModeReboot'
        ) {
            $errors.Add('Phase 40 reference is not a SafeModeReboot workflow.')
        }
        $rebootScopeId = [string](
            Get-BoostLabSafeModePropertyValue $Reference 'ScopeId'
        )
        if ($rebootScopeId -notin (ConvertTo-BoostLabSafeModeStringArray (
            Get-BoostLabSafeModePropertyValue `
                $Scope `
                'AllowedRebootWorkflowScopeIds'
        ))) {
            $errors.Add('Phase 40 reboot workflow scope is not approved.')
        }
        if ([string]::IsNullOrWhiteSpace([string](
            Get-BoostLabSafeModePropertyValue $Reference 'RecordHash'
        ))) {
            $errors.Add('Phase 40 reboot workflow reference lacks a hash.')
        }
        try {
            $recordPath = [string](
                Get-BoostLabSafeModePropertyValue $Reference 'RecordPath'
            )
            $trusted = $false
            foreach ($root in ConvertTo-BoostLabSafeModeStringArray (
                Get-BoostLabSafeModePropertyValue `
                    $Scope `
                    'AllowedRebootRecordRoots'
            )) {
                if (Test-BoostLabSafeModePathWithinRoot $recordPath $root) {
                    $trusted = $true
                    break
                }
            }
            if (-not $trusted) {
                $errors.Add(
                    'Phase 40 reboot workflow record is outside trusted roots.'
                )
            }
        }
        catch {
            $errors.Add('Phase 40 reboot workflow record path is invalid.')
        }
    }
    return [pscustomobject]@{
        IsValid = $errors.Count -eq 0
        Errors  = $errors.ToArray()
    }
}

function Test-BoostLabSafeModeSteps {
    param(
        [AllowNull()]
        [object]$Steps,

        [Parameter(Mandatory)]
        [object]$Scope,

        [ValidateSet('Resume', 'Exit')]
        [string]$Kind
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $items = @($Steps)
    $maxField = if ($Kind -eq 'Resume') {
        'MaxResumeSteps'
    }
    else {
        'MaxExitSteps'
    }
    $handlerField = if ($Kind -eq 'Resume') {
        'AllowedResumeHandlerIds'
    }
    else {
        'AllowedExitHandlerIds'
    }
    $pathField = if ($Kind -eq 'Resume') {
        'AllowedResumeArtifactPaths'
    }
    else {
        'AllowedExitArtifactPaths'
    }
    $artifactProperty = if ($Kind -eq 'Resume') {
        'ResumeArtifactPath'
    }
    else {
        'ExitArtifactPath'
    }
    $maxSteps = [int](
        Get-BoostLabSafeModePropertyValue $Scope $maxField
    )
    if ($items.Count -eq 0) {
        $errors.Add("$Kind step list is required.")
    }
    if ($items.Count -gt $maxSteps) {
        $errors.Add("$Kind step count exceeds the limit of $maxSteps.")
    }
    $allowedHandlers = @(
        ConvertTo-BoostLabSafeModeStringArray (
            Get-BoostLabSafeModePropertyValue $Scope $handlerField
        )
    )
    $allowedPaths = @(
        ConvertTo-BoostLabSafeModeStringArray (
            Get-BoostLabSafeModePropertyValue $Scope $pathField
        )
    )
    $ids = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $orders = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($step in $items) {
        if (Test-BoostLabSafeModeRawCommand $step) {
            $errors.Add("$Kind steps must not contain arbitrary command data.")
        }
        $stepId = [string](
            Get-BoostLabSafeModePropertyValue $step 'StepId'
        )
        $handlerId = [string](
            Get-BoostLabSafeModePropertyValue $step 'HandlerId'
        )
        $order = 0
        if (
            -not [int]::TryParse(
                [string](
                    Get-BoostLabSafeModePropertyValue $step 'Order'
                ),
                [ref]$order
            ) -or
            $order -le 0 -or
            -not $orders.Add($order)
        ) {
            $errors.Add("$Kind step order must be positive and unique.")
        }
        if (
            -not (Test-BoostLabSafeModeExactIdentifier $stepId) -or
            -not $ids.Add($stepId)
        ) {
            $errors.Add("$Kind step ids must be exact and unique.")
        }
        if (
            -not (Test-BoostLabSafeModeExactIdentifier $handlerId) -or
            $handlerId -notin $allowedHandlers
        ) {
            $errors.Add("$Kind handler '$handlerId' is not approved.")
        }
        if ([string]::IsNullOrWhiteSpace([string](
            Get-BoostLabSafeModePropertyValue $step 'Description'
        ))) {
            $errors.Add("$Kind step '$stepId' requires a description.")
        }
        if (@(
            Get-BoostLabSafeModePropertyValue $step 'ExpectedConditions'
        ).Count -eq 0) {
            $errors.Add("$Kind step '$stepId' requires expected conditions.")
        }
        if (@(
            Get-BoostLabSafeModePropertyValue $step 'VerificationRequirements'
        ).Count -eq 0) {
            $errors.Add("$Kind step '$stepId' requires verification.")
        }
        if ($Kind -eq 'Exit' -and [string]::IsNullOrWhiteSpace([string](
            Get-BoostLabSafeModePropertyValue $step 'RecoveryInstructions'
        ))) {
            $errors.Add("Exit step '$stepId' requires recovery instructions.")
        }
        $artifactPath = [string](
            Get-BoostLabSafeModePropertyValue $step $artifactProperty
        )
        if (-not [string]::IsNullOrWhiteSpace($artifactPath)) {
            try {
                $fullPath = ConvertTo-BoostLabSafeModeFullPath $artifactPath
                $approved = $false
                foreach ($allowedPath in $allowedPaths) {
                    if ($fullPath.Equals(
                        (ConvertTo-BoostLabSafeModeFullPath $allowedPath),
                        [StringComparison]::OrdinalIgnoreCase
                    )) {
                        $approved = $true
                        break
                    }
                }
                if (-not $approved) {
                    $errors.Add("$Kind step '$stepId' uses an untrusted path.")
                }
            }
            catch {
                $errors.Add("$Kind step '$stepId' has an invalid path.")
            }
        }
    }
    return [pscustomobject]@{
        IsValid = $errors.Count -eq 0
        Errors  = $errors.ToArray()
    }
}

function New-BoostLabSafeModeWorkflowPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ActionId,

        [Parameter(Mandatory)]
        [string]$ScopeId,

        [ValidateSet('Minimal', 'Networking', 'CommandShell')]
        [string]$SafeModeType,

        [Parameter(Mandatory)]
        [string]$Reason,

        [string]$RiskClassification = 'High',

        [string]$ConfirmationLevel = 'Explicit',

        [AllowNull()]
        [object[]]$PreSafeModeCheckpoints,

        [AllowNull()]
        [object[]]$StateCaptureReferences,

        [AllowNull()]
        [object]$RebootWorkflowReference,

        [AllowNull()]
        [object[]]$PlannedResumeSteps,

        [AllowNull()]
        [object[]]$PlannedExitStrategy,

        [AllowNull()]
        [object[]]$PostResumeVerificationRequirements,

        [int]$ExpirationMinutes,

        [bool]$CancellationEligible,

        [Parameter(Mandatory)]
        [string]$RecoveryInstructions,

        [Parameter(Mandatory)]
        [string]$UserWarningText,

        [AllowNull()]
        [object]$ActionPlan,

        [bool]$Confirmed,

        [string]$BoostLabVersion = 'Foundation',

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabSafeModeRecoveryPolicy
    }
    $errors = [System.Collections.Generic.List[string]]::new()
    $target = Test-BoostLabSafeModeWorkflowTarget `
        -ToolId $ToolId `
        -ActionId $ActionId `
        -ScopeId $ScopeId `
        -SafeModeType $SafeModeType `
        -Policy $Policy
    if (-not $target.IsAllowed) {
        $errors.AddRange([string[]]@($target.Errors))
    }
    if ($null -ne $target.Scope) {
        $checkpointValidation = Test-BoostLabSafeModeCheckpointSet `
            -Checkpoints $PreSafeModeCheckpoints `
            -Scope $target.Scope
        if (-not $checkpointValidation.IsValid) {
            $errors.AddRange([string[]]@($checkpointValidation.Errors))
        }
        $stateValidation = Test-BoostLabSafeModeStateReferences `
            -References $StateCaptureReferences `
            -Scope $target.Scope
        if (-not $stateValidation.IsValid) {
            $errors.AddRange([string[]]@($stateValidation.Errors))
        }
        $rebootValidation = Test-BoostLabSafeModeRebootReference `
            -Reference $RebootWorkflowReference `
            -Scope $target.Scope `
            -ToolId $ToolId `
            -ActionId $ActionId
        if (-not $rebootValidation.IsValid) {
            $errors.AddRange([string[]]@($rebootValidation.Errors))
        }
        $resumeValidation = Test-BoostLabSafeModeSteps `
            -Steps $PlannedResumeSteps `
            -Scope $target.Scope `
            -Kind Resume
        if (-not $resumeValidation.IsValid) {
            $errors.AddRange([string[]]@($resumeValidation.Errors))
        }
        $exitValidation = Test-BoostLabSafeModeSteps `
            -Steps $PlannedExitStrategy `
            -Scope $target.Scope `
            -Kind Exit
        if (-not $exitValidation.IsValid) {
            $errors.AddRange([string[]]@($exitValidation.Errors))
        }
        if (
            $ExpirationMinutes -le 0 -or
            $ExpirationMinutes -gt [int](
                Get-BoostLabSafeModePropertyValue `
                    $target.Scope `
                    'MaxDurationMinutes'
            )
        ) {
            $errors.Add('Safe Mode workflow expiration exceeds policy.')
        }
        if (
            $CancellationEligible -and
            -not [bool](
                Get-BoostLabSafeModePropertyValue `
                    $target.Scope `
                    'AllowCancellation'
            )
        ) {
            $errors.Add('Cancellation is not approved by this scope.')
        }
    }
    if ($null -eq $ActionPlan) {
        $errors.Add('A matching Action Plan is required.')
    }
    else {
        if ([string]$ActionPlan.ToolId -ne $ToolId) {
            $errors.Add('Action Plan tool identity does not match.')
        }
        if ([string]$ActionPlan.Action -ne $ActionId) {
            $errors.Add('Action Plan action identity does not match.')
        }
        if (
            -not [bool]$ActionPlan.NeedsExplicitConfirmation -or
            -not [bool]$ActionPlan.UsesSafeMode
        ) {
            $errors.Add(
                'Action Plan must declare Safe Mode and explicit confirmation.'
            )
        }
    }
    if (-not $Confirmed) {
        $errors.Add('Explicit Safe Mode confirmation is required.')
    }
    if ($RiskClassification -ne 'High') {
        $errors.Add('Safe Mode workflows must be High risk.')
    }
    if ($ConfirmationLevel -ne 'Explicit') {
        $errors.Add('Safe Mode workflows require Explicit confirmation.')
    }
    if ([string]::IsNullOrWhiteSpace($Reason)) {
        $errors.Add('Safe Mode reason is required.')
    }
    if ([string]::IsNullOrWhiteSpace($RecoveryInstructions)) {
        $errors.Add('Readable recovery instructions are required.')
    }
    if ([string]::IsNullOrWhiteSpace($UserWarningText)) {
        $errors.Add('User-visible Safe Mode warning text is required.')
    }
    if (@($PostResumeVerificationRequirements).Count -eq 0) {
        $errors.Add('Post-resume verification requirements are required.')
    }

    $now = (Get-Date).ToUniversalTime()
    return [pscustomobject][ordered]@{
        OperationId                      = [guid]::NewGuid().ToString()
        ToolId                           = $ToolId
        ActionId                         = $ActionId
        Timestamp                        = $now.ToString('o')
        SchemaVersion                    = $script:BoostLabSafeModeSchemaVersion
        BoostLabVersion                  = $BoostLabVersion
        ScopeId                          = $ScopeId
        RequestedSafeModeType             = $SafeModeType
        Reason                           = $Reason
        RiskClassification               = $RiskClassification
        RequiredConfirmationLevel        = $ConfirmationLevel
        PreSafeModeCheckpoints            = @($PreSafeModeCheckpoints)
        RequiredStateCaptureReferences   = @($StateCaptureReferences)
        RebootWorkflowReference          = $RebootWorkflowReference
        PlannedResumeSteps               = @($PlannedResumeSteps)
        PlannedExitStrategy              = @($PlannedExitStrategy)
        PostResumeVerificationRequirements = @(
            $PostResumeVerificationRequirements
        )
        ExpiresAt                        = $now.AddMinutes(
            $ExpirationMinutes
        ).ToString('o')
        CancellationEligible             = $CancellationEligible
        RecoveryInstructions             = $RecoveryInstructions
        UserVisibleWarningText            = $UserWarningText
        ActionPlan                       = $ActionPlan
        RequiresExplicitConfirmation     = $true
        EntrySchedulingRequested         = $true
        IsDryRun                         = $true
        IsAllowed                        = $errors.Count -eq 0
        Status                           = if ($errors.Count -eq 0) {
            'Allowed'
        }
        else {
            'Blocked'
        }
        Message                          = if ($errors.Count -eq 0) {
            'Safe Mode workflow plan passed structural validation.'
        }
        else {
            'Safe Mode workflow planning was blocked.'
        }
        Errors                           = $errors.ToArray()
    }
}

function New-BoostLabSafeModeWorkflowRecord {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Plan
    )

    if (-not [bool]$Plan.IsAllowed -or [string]$Plan.Status -ne 'Allowed') {
        throw 'Cannot create a Safe Mode record from a blocked plan.'
    }
    return [pscustomobject][ordered]@{
        OperationId                      = [string]$Plan.OperationId
        ToolId                           = [string]$Plan.ToolId
        ActionId                         = [string]$Plan.ActionId
        Timestamp                        = [string]$Plan.Timestamp
        SchemaVersion                    = [string]$Plan.SchemaVersion
        BoostLabVersion                  = [string]$Plan.BoostLabVersion
        ScopeId                          = [string]$Plan.ScopeId
        RequestedSafeModeType             = [string]$Plan.RequestedSafeModeType
        Reason                           = [string]$Plan.Reason
        RiskClassification               = [string]$Plan.RiskClassification
        RequiredConfirmationLevel        = [string]$Plan.RequiredConfirmationLevel
        PreSafeModeCheckpoints            = @($Plan.PreSafeModeCheckpoints)
        RequiredStateCaptureReferences   = @(
            $Plan.RequiredStateCaptureReferences
        )
        RebootWorkflowReference          = $Plan.RebootWorkflowReference
        PlannedResumeSteps               = @($Plan.PlannedResumeSteps)
        PlannedExitStrategy              = @($Plan.PlannedExitStrategy)
        PostResumeVerificationRequirements = @(
            $Plan.PostResumeVerificationRequirements
        )
        ExpiresAt                        = [string]$Plan.ExpiresAt
        CancellationEligible             = [bool]$Plan.CancellationEligible
        RecoveryInstructions             = [string]$Plan.RecoveryInstructions
        UserVisibleWarningText            = [string]$Plan.UserVisibleWarningText
        WorkflowStatus                   = 'PendingResume'
        Cancelled                        = $false
        CancelledAt                      = ''
        CancellationReason               = ''
        EntryRequested                   = $false
        ResumeAttempted                  = $false
        ResumeCompleted                  = $false
        ExitAttempted                    = $false
        ExitCompleted                    = $false
        PostResumeVerification           = $null
        LastResult                       = $null
    }
}

function Get-BoostLabSafeModeSha256 {
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        return [BitConverter]::ToString(
            $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))
        ).Replace('-', '')
    }
    finally {
        $sha256.Dispose()
    }
}

function ConvertTo-BoostLabSafeModeRecordTable {
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

function Save-BoostLabSafeModeWorkflowRecord {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Record,

        [string]$StateRoot = (Get-BoostLabSafeModeRecoveryStateRoot)
    )

    $operationId = [string](
        Get-BoostLabSafeModePropertyValue $Record 'OperationId'
    )
    if (-not (Test-BoostLabSafeModeExactIdentifier $operationId)) {
        throw 'Safe Mode workflow record requires a valid OperationId.'
    }
    $recordsRoot = Join-Path $StateRoot 'Records'
    [IO.Directory]::CreateDirectory($recordsRoot) | Out-Null
    $recordJson = $Record | ConvertTo-Json -Compress -Depth 60
    $recordHash = Get-BoostLabSafeModeSha256 -Text $recordJson
    $envelope = [pscustomobject][ordered]@{
        SchemaVersion = $script:BoostLabSafeModeSchemaVersion
        RecordSha256  = $recordHash
        Record        = $Record
    }
    $recordPath = Join-Path $recordsRoot "$operationId.json"
    [IO.File]::WriteAllText(
        $recordPath,
        ($envelope | ConvertTo-Json -Depth 70),
        [Text.Encoding]::UTF8
    )
    return [pscustomobject]@{
        Success      = $true
        RecordPath   = $recordPath
        RecordSha256 = $recordHash
        Timestamp    = Get-Date
    }
}

function Import-BoostLabSafeModeWorkflowRecord {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$RecordPath,

        [string]$StateRoot = (Get-BoostLabSafeModeRecoveryStateRoot)
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $record = $null
    try {
        $recordsRoot = ConvertTo-BoostLabSafeModeFullPath (
            Join-Path $StateRoot 'Records'
        )
        $fullPath = ConvertTo-BoostLabSafeModeFullPath $RecordPath
        if (-not (Test-BoostLabSafeModePathWithinRoot $fullPath $recordsRoot)) {
            $errors.Add('Safe Mode record is outside the records root.')
        }
        elseif (-not [IO.File]::Exists($fullPath)) {
            $errors.Add('Safe Mode workflow record does not exist.')
        }
        else {
            $envelope = [IO.File]::ReadAllText($fullPath) | ConvertFrom-Json
            if (
                [string]$envelope.SchemaVersion -ne
                    $script:BoostLabSafeModeSchemaVersion
            ) {
                $errors.Add('Safe Mode record envelope schema is unsupported.')
            }
            $record = $envelope.Record
            $actualHash = Get-BoostLabSafeModeSha256 -Text (
                $record | ConvertTo-Json -Compress -Depth 60
            )
            if ($actualHash -ne [string]$envelope.RecordSha256) {
                $errors.Add('Safe Mode workflow record integrity check failed.')
            }
        }
    }
    catch {
        $errors.Add(
            "Safe Mode workflow record could not be read: " +
            $_.Exception.Message
        )
    }
    return [pscustomobject]@{
        IsValid   = $errors.Count -eq 0
        Status    = if ($errors.Count -eq 0) { 'Valid' } else { 'Blocked' }
        Record    = if ($errors.Count -eq 0) { $record } else { $null }
        Errors    = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function Test-BoostLabSafeModeWorkflowRecord {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [object]$Record,

        [string]$ExpectedToolId = '',

        [string]$ExpectedActionId = '',

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabSafeModeRecoveryPolicy
    }
    $errors = [System.Collections.Generic.List[string]]::new()
    if ($null -eq $Record) {
        $errors.Add('Safe Mode workflow record is missing.')
    }
    else {
        foreach ($field in @(
            'OperationId'
            'ToolId'
            'ActionId'
            'Timestamp'
            'SchemaVersion'
            'BoostLabVersion'
            'ScopeId'
            'RequestedSafeModeType'
            'Reason'
            'RiskClassification'
            'RequiredConfirmationLevel'
            'PreSafeModeCheckpoints'
            'RequiredStateCaptureReferences'
            'RebootWorkflowReference'
            'PlannedResumeSteps'
            'PlannedExitStrategy'
            'PostResumeVerificationRequirements'
            'ExpiresAt'
            'CancellationEligible'
            'RecoveryInstructions'
            'UserVisibleWarningText'
            'WorkflowStatus'
            'Cancelled'
            'CancelledAt'
            'CancellationReason'
            'EntryRequested'
            'ResumeAttempted'
            'ResumeCompleted'
            'ExitAttempted'
            'ExitCompleted'
            'PostResumeVerification'
            'LastResult'
        )) {
            if (-not (Test-BoostLabSafeModePropertyExists $Record $field)) {
                $errors.Add("Safe Mode record is missing field: $field")
            }
        }
        if (
            [string]$Record.SchemaVersion -ne
                $script:BoostLabSafeModeSchemaVersion
        ) {
            $errors.Add('Safe Mode workflow record schema is unsupported.')
        }
        if (
            -not [string]::IsNullOrWhiteSpace($ExpectedToolId) -and
            [string]$Record.ToolId -ne $ExpectedToolId
        ) {
            $errors.Add('Safe Mode workflow tool identity mismatch.')
        }
        if (
            -not [string]::IsNullOrWhiteSpace($ExpectedActionId) -and
            [string]$Record.ActionId -ne $ExpectedActionId
        ) {
            $errors.Add('Safe Mode workflow action identity mismatch.')
        }
        if ([string]$Record.WorkflowStatus -notin $script:BoostLabSafeModeStatuses) {
            $errors.Add('Safe Mode workflow status is unsupported.')
        }
        $expiresAt = [datetime]::MinValue
        if (-not [datetime]::TryParse(
            [string]$Record.ExpiresAt,
            [ref]$expiresAt
        )) {
            $errors.Add('Safe Mode workflow expiration is invalid.')
        }
        elseif ((Get-Date).ToUniversalTime() -gt $expiresAt.ToUniversalTime()) {
            $errors.Add('Safe Mode workflow record is expired.')
        }
        $timestamp = [datetime]::MinValue
        if (-not [datetime]::TryParse(
            [string]$Record.Timestamp,
            [ref]$timestamp
        )) {
            $errors.Add('Safe Mode workflow timestamp is invalid.')
        }
        elseif ($Policy.Contains('MaxRecordAgeDays')) {
            $age = (Get-Date).ToUniversalTime() - $timestamp.ToUniversalTime()
            if ($age.TotalDays -gt [int]$Policy['MaxRecordAgeDays']) {
                $errors.Add('Safe Mode workflow record is stale.')
            }
        }

        $target = Test-BoostLabSafeModeWorkflowTarget `
            -ToolId ([string]$Record.ToolId) `
            -ActionId ([string]$Record.ActionId) `
            -ScopeId ([string]$Record.ScopeId) `
            -SafeModeType ([string]$Record.RequestedSafeModeType) `
            -Policy $Policy
        if (-not $target.IsAllowed) {
            $errors.AddRange([string[]]@($target.Errors))
        }
        elseif ($null -ne $target.Scope) {
            $checks = Test-BoostLabSafeModeCheckpointSet `
                -Checkpoints @($Record.PreSafeModeCheckpoints) `
                -Scope $target.Scope
            $state = Test-BoostLabSafeModeStateReferences `
                -References @($Record.RequiredStateCaptureReferences) `
                -Scope $target.Scope
            $reboot = Test-BoostLabSafeModeRebootReference `
                -Reference $Record.RebootWorkflowReference `
                -Scope $target.Scope `
                -ToolId ([string]$Record.ToolId) `
                -ActionId ([string]$Record.ActionId)
            $resume = Test-BoostLabSafeModeSteps `
                -Steps @($Record.PlannedResumeSteps) `
                -Scope $target.Scope `
                -Kind Resume
            $exit = Test-BoostLabSafeModeSteps `
                -Steps @($Record.PlannedExitStrategy) `
                -Scope $target.Scope `
                -Kind Exit
            foreach ($validation in @($checks, $state, $reboot, $resume, $exit)) {
                if (-not $validation.IsValid) {
                    $errors.AddRange([string[]]@($validation.Errors))
                }
            }
        }
    }
    return [pscustomobject]@{
        IsValid   = $errors.Count -eq 0
        Status    = if ($errors.Count -eq 0) { 'Valid' } else { 'Blocked' }
        Errors    = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function Stop-BoostLabSafeModeWorkflow {
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
        [string]$Reason,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    $imported = Import-BoostLabSafeModeWorkflowRecord `
        -RecordPath $RecordPath `
        -StateRoot $StateRoot
    if (-not $imported.IsValid) {
        return [pscustomobject]@{
            Success = $false
            Status = 'Blocked'
            Cancelled = $false
            RecoveryInstructions = ''
            Message = 'Safe Mode cancellation was blocked by an invalid record.'
            Errors = @($imported.Errors)
            Timestamp = Get-Date
        }
    }
    $record = $imported.Record
    $validation = Test-BoostLabSafeModeWorkflowRecord `
        -Record $record `
        -ExpectedToolId $ToolId `
        -ExpectedActionId $ActionId `
        -Policy $Policy
    $errors = [System.Collections.Generic.List[string]]::new()
    if (-not $validation.IsValid) {
        $errors.AddRange([string[]]@($validation.Errors))
    }
    if (-not [bool]$record.CancellationEligible) {
        $errors.Add('This Safe Mode workflow cannot be cancelled.')
    }
    if ([bool]$record.Cancelled) {
        $errors.Add('This Safe Mode workflow is already cancelled.')
    }
    if ([string]::IsNullOrWhiteSpace($Reason)) {
        $errors.Add('Cancellation reason is required.')
    }
    if ($errors.Count -gt 0) {
        return [pscustomobject]@{
            Success = $false
            Status = 'Blocked'
            Cancelled = $false
            RecoveryInstructions = [string]$record.RecoveryInstructions
            Message = 'Safe Mode workflow cancellation was blocked.'
            Errors = $errors.ToArray()
            Timestamp = Get-Date
        }
    }

    $table = ConvertTo-BoostLabSafeModeRecordTable $record
    $table['WorkflowStatus'] = 'Cancelled'
    $table['Cancelled'] = $true
    $table['CancelledAt'] = (Get-Date).ToUniversalTime().ToString('o')
    $table['CancellationReason'] = $Reason
    $table['LastResult'] = [pscustomobject]@{
        Status = 'Cancelled'
        Message = $Reason
    }
    $saved = Save-BoostLabSafeModeWorkflowRecord `
        -Record ([pscustomobject]$table) `
        -StateRoot $StateRoot
    return [pscustomobject]@{
        Success = $true
        Status = 'Cancelled'
        Cancelled = $true
        RecordPath = $saved.RecordPath
        RecoveryInstructions = [string]$record.RecoveryInstructions
        Message = 'Safe Mode workflow was cancelled; future resume is blocked.'
        Errors = @()
        Timestamp = Get-Date
    }
}

function New-BoostLabSafeModeResumePlan {
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
        [scriptblock]$MachineStateValidator,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $record = $null
    $machineState = $null
    $imported = Import-BoostLabSafeModeWorkflowRecord `
        -RecordPath $RecordPath `
        -StateRoot $StateRoot
    if (-not $imported.IsValid) {
        $errors.AddRange([string[]]@($imported.Errors))
    }
    else {
        $record = $imported.Record
        $validation = Test-BoostLabSafeModeWorkflowRecord `
            -Record $record `
            -ExpectedToolId $ToolId `
            -ExpectedActionId $ActionId `
            -Policy $Policy
        if (-not $validation.IsValid) {
            $errors.AddRange([string[]]@($validation.Errors))
        }
        if ([bool]$record.Cancelled) {
            $errors.Add('Cancelled Safe Mode workflows cannot resume.')
        }
        if ([string]$record.WorkflowStatus -ne 'PendingResume') {
            $errors.Add('Safe Mode workflow is not pending resume.')
        }
        try {
            $machineState = & $MachineStateValidator $record
            if (
                $null -eq $machineState -or
                -not [bool](
                    Get-BoostLabSafeModePropertyValue $machineState 'IsMatch'
                )
            ) {
                $errors.Add(
                    'Current machine state does not match resume expectations.'
                )
            }
        }
        catch {
            $errors.Add(
                "Safe Mode machine-state validation failed: " +
                $_.Exception.Message
            )
        }
    }
    return [pscustomobject][ordered]@{
        OperationId = if ($null -ne $record) {
            [string]$record.OperationId
        }
        else {
            ''
        }
        ToolId = $ToolId
        ActionId = $ActionId
        RecordPath = $RecordPath
        PlannedResumeSteps = if ($null -ne $record) {
            @($record.PlannedResumeSteps)
        }
        else {
            @()
        }
        PlannedExitStrategy = if ($null -ne $record) {
            @($record.PlannedExitStrategy)
        }
        else {
            @()
        }
        MachineState = $machineState
        RecoveryInstructions = if ($null -ne $record) {
            [string]$record.RecoveryInstructions
        }
        else {
            ''
        }
        IsDryRun = $true
        IsAllowed = $errors.Count -eq 0
        Status = if ($errors.Count -eq 0) { 'Allowed' } else { 'Blocked' }
        Message = if ($errors.Count -eq 0) {
            'Safe Mode resume plan passed record and machine-state validation.'
        }
        else {
            'Safe Mode resume was refused. Follow recovery instructions.'
        }
        Errors = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function New-BoostLabSafeModeExitPlan {
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
        [scriptblock]$MachineStateValidator,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    $resume = New-BoostLabSafeModeResumePlan `
        -RecordPath $RecordPath `
        -StateRoot $StateRoot `
        -ToolId $ToolId `
        -ActionId $ActionId `
        -MachineStateValidator $MachineStateValidator `
        -Policy $Policy
    return [pscustomobject][ordered]@{
        OperationId = [string]$resume.OperationId
        ToolId = $ToolId
        ActionId = $ActionId
        RecordPath = $RecordPath
        PlannedExitStrategy = @($resume.PlannedExitStrategy)
        MachineState = $resume.MachineState
        RecoveryInstructions = [string]$resume.RecoveryInstructions
        IsDryRun = $true
        IsAllowed = [bool]$resume.IsAllowed -and
            @($resume.PlannedExitStrategy).Count -gt 0
        Status = if (
            [bool]$resume.IsAllowed -and
            @($resume.PlannedExitStrategy).Count -gt 0
        ) {
            'Allowed'
        }
        else {
            'Blocked'
        }
        Message = if (
            [bool]$resume.IsAllowed -and
            @($resume.PlannedExitStrategy).Count -gt 0
        ) {
            'Safe Mode exit plan passed structural validation.'
        }
        else {
            'Safe Mode exit was refused. Follow recovery instructions.'
        }
        Errors = @($resume.Errors)
        Timestamp = Get-Date
    }
}

function Set-BoostLabSafeModeWorkflowVerification {
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
        [object]$VerificationResult,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    $imported = Import-BoostLabSafeModeWorkflowRecord `
        -RecordPath $RecordPath `
        -StateRoot $StateRoot
    if (-not $imported.IsValid) {
        return [pscustomobject]@{
            Success = $false
            Status = 'Failed'
            Message = 'Safe Mode verification record is invalid.'
            RecoveryInstructions = ''
            Verification = $VerificationResult
            Errors = @($imported.Errors)
            Timestamp = Get-Date
        }
    }
    $record = $imported.Record
    $recordValidation = Test-BoostLabSafeModeWorkflowRecord `
        -Record $record `
        -ExpectedToolId $ToolId `
        -ExpectedActionId $ActionId `
        -Policy $Policy
    $verificationStatus = [string](
        Get-BoostLabSafeModePropertyValue $VerificationResult 'Status'
    )
    $errors = [System.Collections.Generic.List[string]]::new()
    if (-not $recordValidation.IsValid) {
        $errors.AddRange([string[]]@($recordValidation.Errors))
    }
    if ($verificationStatus -notin @('Passed', 'Warning', 'Failed')) {
        $errors.Add('Safe Mode verification status is unsupported.')
    }
    $successful = $errors.Count -eq 0 -and
        $verificationStatus -in @('Passed', 'Warning')
    $table = ConvertTo-BoostLabSafeModeRecordTable $record
    $table['WorkflowStatus'] = if ($successful) { 'Completed' } else { 'Failed' }
    $table['ResumeAttempted'] = $true
    $table['ResumeCompleted'] = $successful
    $table['ExitAttempted'] = $true
    $table['ExitCompleted'] = $successful
    $table['PostResumeVerification'] = $VerificationResult
    $table['LastResult'] = [pscustomobject]@{
        Status = if ($successful) { $verificationStatus } else { 'Failed' }
        Message = if ($successful) {
            'Safe Mode post-resume verification completed.'
        }
        else {
            'Safe Mode verification failed. Follow recovery instructions.'
        }
    }
    Save-BoostLabSafeModeWorkflowRecord `
        -Record ([pscustomobject]$table) `
        -StateRoot $StateRoot | Out-Null
    return [pscustomobject]@{
        Success = $successful
        Status = if ($successful) { $verificationStatus } else { 'Failed' }
        ToolId = $ToolId
        ActionId = $ActionId
        Verification = $VerificationResult
        RecoveryInstructions = [string]$record.RecoveryInstructions
        Message = if ($successful) {
            'Safe Mode workflow verification completed.'
        }
        else {
            'Safe Mode verification failed; the workflow did not continue silently.'
        }
        Errors = $errors.ToArray()
        Timestamp = Get-Date
    }
}

Export-ModuleMember -Function @(
    'Get-BoostLabSafeModeRecoveryPolicy'
    'Get-BoostLabSafeModeRecoveryStateRoot'
    'Test-BoostLabSafeModeRecoveryPolicy'
    'Test-BoostLabSafeModeWorkflowTarget'
    'New-BoostLabSafeModeWorkflowPlan'
    'New-BoostLabSafeModeWorkflowRecord'
    'Save-BoostLabSafeModeWorkflowRecord'
    'Import-BoostLabSafeModeWorkflowRecord'
    'Test-BoostLabSafeModeWorkflowRecord'
    'Stop-BoostLabSafeModeWorkflow'
    'New-BoostLabSafeModeResumePlan'
    'New-BoostLabSafeModeExitPlan'
    'Set-BoostLabSafeModeWorkflowVerification'
)
