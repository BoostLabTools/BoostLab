Set-StrictMode -Version Latest

$script:BoostLabRebootSchemaVersion = '1.0'
$script:BoostLabRebootPolicyPath = Join-Path `
    (Split-Path -Parent $PSScriptRoot) `
    'config\RebootRecoveryPolicy.psd1'
$script:BoostLabRebootTypes = @(
    'NormalReboot'
    'FirmwareReboot'
    'SafeModeReboot'
    'PostRebootResume'
    'ManualRebootRequired'
)
$script:BoostLabWorkflowStatuses = @(
    'Prepared'
    'PendingReboot'
    'PendingResume'
    'Cancelled'
    'Completed'
    'Failed'
)
$script:BoostLabForbiddenResumeProperties = @(
    'Command'
    'CommandLine'
    'Arguments'
    'Executable'
    'Script'
    'ScriptPath'
    'Uri'
    'Url'
)

function Get-BoostLabRebootPropertyValue {
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

function ConvertTo-BoostLabRebootStringArray {
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

function Test-BoostLabRebootExactIdentifier {
    param(
        [AllowNull()]
        [object]$Value
    )

    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $false
    }
    if ($text.IndexOfAny([char[]]'*?[]') -ge 0) {
        return $false
    }

    return $text -match '^[A-Za-z0-9][A-Za-z0-9._-]+$'
}

function ConvertTo-BoostLabRebootFullPath {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'A non-empty absolute path is required.'
    }
    if ($Path.IndexOfAny([char[]]'*?[]') -ge 0) {
        throw 'Wildcard paths are not allowed in reboot workflows.'
    }
    if (-not [IO.Path]::IsPathRooted($Path)) {
        throw 'Reboot workflow paths must be absolute.'
    }
    $segments = @(
        $Path -split '[\\/]' |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
    if ('..' -in $segments) {
        throw 'Path traversal is not allowed in reboot workflows.'
    }

    return [IO.Path]::GetFullPath($Path).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
}

function Test-BoostLabRebootPathWithinRoot {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Root
    )

    $fullPath = ConvertTo-BoostLabRebootFullPath -Path $Path
    $fullRoot = ConvertTo-BoostLabRebootFullPath -Path $Root
    if ($fullPath.Equals($fullRoot, [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    return $fullPath.StartsWith(
        $fullRoot + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase
    )
}

function Get-BoostLabRebootRecoveryPolicy {
    [CmdletBinding()]
    [OutputType([System.Collections.IDictionary])]
    param(
        [string]$PolicyPath = $script:BoostLabRebootPolicyPath
    )

    if (-not (Test-Path -LiteralPath $PolicyPath -PathType Leaf)) {
        throw "Reboot recovery policy was not found: $PolicyPath"
    }

    return Import-PowerShellDataFile -LiteralPath $PolicyPath
}

function Get-BoostLabRebootRecoveryStateRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ([string]::IsNullOrWhiteSpace($env:ProgramData)) {
        throw 'The ProgramData environment variable is not available.'
    }

    return Join-Path $env:ProgramData 'BoostLab\State\RebootRecovery'
}

function Test-BoostLabRebootRecoveryPolicy {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabRebootRecoveryPolicy
    }

    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($field in @(
        'SchemaVersion'
        'MaxRecordAgeDays'
        'WorkflowScopes'
    )) {
        if (-not $Policy.Contains($field)) {
            $errors.Add("Reboot recovery policy is missing field: $field")
        }
    }
    if (
        $Policy.Contains('SchemaVersion') -and
        [string]$Policy['SchemaVersion'] -ne $script:BoostLabRebootSchemaVersion
    ) {
        $errors.Add(
            "Reboot recovery policy SchemaVersion must be " +
            "$script:BoostLabRebootSchemaVersion."
        )
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
        $errors.Add(
            'Reboot recovery policy MaxRecordAgeDays must be positive.'
        )
    }

    $scopeIds = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $scopes = @(
        if ($Policy.Contains('WorkflowScopes')) {
            @($Policy['WorkflowScopes'])
        }
    )
    foreach ($scope in $scopes) {
        foreach ($field in @(
            'ScopeId'
            'ToolIds'
            'ActionIds'
            'AllowedRebootTypes'
            'RequiredCheckpointNames'
            'AllowedStateReferenceRoots'
            'AllowedResumeHandlerIds'
            'AllowedResumeArtifactPaths'
            'RequiresStateCapture'
            'AllowImmediateReboot'
            'AllowResumeScheduling'
            'AllowFirmwareReboot'
            'AllowSafeModeReboot'
            'MaxResumeSteps'
            'MaxDurationMinutes'
            'AllowCancellation'
            'RequiredConfirmationLevel'
            'NeedsExplicitConfirmation'
        )) {
            if ($null -eq (Get-BoostLabRebootPropertyValue $scope $field)) {
                $errors.Add("Reboot workflow scope is missing field: $field")
            }
        }

        $scopeId = [string](
            Get-BoostLabRebootPropertyValue $scope 'ScopeId'
        )
        if (-not (Test-BoostLabRebootExactIdentifier $scopeId)) {
            $errors.Add('Reboot workflow scope ids must be exact identifiers.')
        }
        elseif (-not $scopeIds.Add($scopeId)) {
            $errors.Add("Duplicate reboot workflow scope id: $scopeId")
        }

        foreach ($identityField in @('ToolIds', 'ActionIds')) {
            $identities = @(
                ConvertTo-BoostLabRebootStringArray (
                    Get-BoostLabRebootPropertyValue $scope $identityField
                )
            )
            if ($identities.Count -eq 0) {
                $errors.Add(
                    "Reboot workflow scope '$scopeId' requires $identityField."
                )
            }
            foreach ($identity in $identities) {
                if (-not (Test-BoostLabRebootExactIdentifier $identity)) {
                    $errors.Add(
                        "Reboot workflow scope '$scopeId' has a non-exact " +
                        "$identityField value."
                    )
                }
            }
        }

        $rebootTypes = @(
            ConvertTo-BoostLabRebootStringArray (
                Get-BoostLabRebootPropertyValue $scope 'AllowedRebootTypes'
            )
        )
        if ($rebootTypes.Count -eq 0) {
            $errors.Add(
                "Reboot workflow scope '$scopeId' requires reboot types."
            )
        }
        foreach ($rebootType in $rebootTypes) {
            if ($rebootType -notin $script:BoostLabRebootTypes) {
                $errors.Add(
                    "Reboot workflow scope '$scopeId' has unsupported type " +
                    "'$rebootType'."
                )
            }
        }

        foreach ($handlerId in ConvertTo-BoostLabRebootStringArray (
            Get-BoostLabRebootPropertyValue $scope 'AllowedResumeHandlerIds'
        )) {
            if (-not (Test-BoostLabRebootExactIdentifier $handlerId)) {
                $errors.Add(
                    "Reboot workflow scope '$scopeId' has a non-exact handler."
                )
            }
        }
        foreach ($path in ConvertTo-BoostLabRebootStringArray (
            Get-BoostLabRebootPropertyValue $scope 'AllowedStateReferenceRoots'
        )) {
            try {
                ConvertTo-BoostLabRebootFullPath -Path $path | Out-Null
            }
            catch {
                $errors.Add(
                    "Reboot workflow scope '$scopeId' has an invalid state root."
                )
            }
        }
        foreach ($path in ConvertTo-BoostLabRebootStringArray (
            Get-BoostLabRebootPropertyValue $scope 'AllowedResumeArtifactPaths'
        )) {
            try {
                ConvertTo-BoostLabRebootFullPath -Path $path | Out-Null
            }
            catch {
                $errors.Add(
                    "Reboot workflow scope '$scopeId' has an invalid resume path."
                )
            }
        }

        foreach ($booleanField in @(
            'RequiresStateCapture'
            'AllowImmediateReboot'
            'AllowResumeScheduling'
            'AllowFirmwareReboot'
            'AllowSafeModeReboot'
            'AllowCancellation'
            'NeedsExplicitConfirmation'
        )) {
            if (
                (
                    Get-BoostLabRebootPropertyValue $scope $booleanField
                ) -isnot [bool]
            ) {
                $errors.Add(
                    "Reboot workflow scope '$scopeId' $booleanField must be Boolean."
                )
            }
        }
        if (-not [bool](
            Get-BoostLabRebootPropertyValue $scope 'NeedsExplicitConfirmation'
        )) {
            $errors.Add(
                "Reboot workflow scope '$scopeId' must require confirmation."
            )
        }

        $maxSteps = 0
        if (
            -not [int]::TryParse(
                [string](
                    Get-BoostLabRebootPropertyValue $scope 'MaxResumeSteps'
                ),
                [ref]$maxSteps
            ) -or
            $maxSteps -lt 0
        ) {
            $errors.Add(
                "Reboot workflow scope '$scopeId' MaxResumeSteps is invalid."
            )
        }
        $maxMinutes = 0
        if (
            -not [int]::TryParse(
                [string](
                    Get-BoostLabRebootPropertyValue $scope 'MaxDurationMinutes'
                ),
                [ref]$maxMinutes
            ) -or
            $maxMinutes -le 0
        ) {
            $errors.Add(
                "Reboot workflow scope '$scopeId' MaxDurationMinutes is invalid."
            )
        }

        if (
            'FirmwareReboot' -in $rebootTypes -and
            -not [bool](
                Get-BoostLabRebootPropertyValue $scope 'AllowFirmwareReboot'
            )
        ) {
            $errors.Add(
                "Reboot workflow scope '$scopeId' lists firmware reboot " +
                'without separate permission.'
            )
        }
        if (
            'SafeModeReboot' -in $rebootTypes -and
            -not [bool](
                Get-BoostLabRebootPropertyValue $scope 'AllowSafeModeReboot'
            )
        ) {
            $errors.Add(
                "Reboot workflow scope '$scopeId' lists Safe Mode reboot " +
                'without separate permission.'
            )
        }
        if (
            'PostRebootResume' -in $rebootTypes -and
            -not [bool](
                Get-BoostLabRebootPropertyValue $scope 'AllowResumeScheduling'
            )
        ) {
            $errors.Add(
                "Reboot workflow scope '$scopeId' lists resume without " +
                'separate scheduling permission.'
            )
        }
    }

    return [pscustomobject]@{
        IsValid           = $errors.Count -eq 0
        Status            = if ($errors.Count -eq 0) { 'Valid' } else { 'Invalid' }
        WorkflowScopeCount = @($scopes).Count
        Errors            = $errors.ToArray()
        Timestamp         = Get-Date
    }
}

function Find-BoostLabRebootWorkflowScope {
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

    foreach ($scope in @($Policy['WorkflowScopes'])) {
        if (
            [string](Get-BoostLabRebootPropertyValue $scope 'ScopeId') -eq
                $ScopeId -and
            $ToolId -in (ConvertTo-BoostLabRebootStringArray (
                Get-BoostLabRebootPropertyValue $scope 'ToolIds'
            )) -and
            $ActionId -in (ConvertTo-BoostLabRebootStringArray (
                Get-BoostLabRebootPropertyValue $scope 'ActionIds'
            ))
        ) {
            return $scope
        }
    }

    return $null
}

function Test-BoostLabRebootWorkflowTarget {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ActionId,

        [Parameter(Mandatory)]
        [string]$ScopeId,

        [ValidateSet(
            'NormalReboot',
            'FirmwareReboot',
            'SafeModeReboot',
            'PostRebootResume',
            'ManualRebootRequired'
        )]
        [string]$RebootType,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabRebootRecoveryPolicy
    }
    $errors = [System.Collections.Generic.List[string]]::new()
    $policyValidation = Test-BoostLabRebootRecoveryPolicy -Policy $Policy
    if (-not $policyValidation.IsValid) {
        $errors.AddRange([string[]]@($policyValidation.Errors))
    }

    $scope = Find-BoostLabRebootWorkflowScope `
        -ToolId $ToolId `
        -ActionId $ActionId `
        -ScopeId $ScopeId `
        -Policy $Policy
    if ($null -eq $scope) {
        $errors.Add(
            'Tool, action, and workflow scope are not in the exact allowlist.'
        )
    }
    else {
        if ($RebootType -notin (ConvertTo-BoostLabRebootStringArray (
            Get-BoostLabRebootPropertyValue $scope 'AllowedRebootTypes'
        ))) {
            $errors.Add("Reboot type '$RebootType' is not approved.")
        }
        if (
            $RebootType -in @(
                'NormalReboot',
                'FirmwareReboot',
                'SafeModeReboot'
            ) -and
            -not [bool](
                Get-BoostLabRebootPropertyValue $scope 'AllowImmediateReboot'
            )
        ) {
            $errors.Add('Immediate reboot is not approved by this scope.')
        }
        if (
            $RebootType -eq 'FirmwareReboot' -and
            -not [bool](
                Get-BoostLabRebootPropertyValue $scope 'AllowFirmwareReboot'
            )
        ) {
            $errors.Add('Firmware reboot requires separate approval.')
        }
        if (
            $RebootType -eq 'SafeModeReboot' -and
            -not [bool](
                Get-BoostLabRebootPropertyValue $scope 'AllowSafeModeReboot'
            )
        ) {
            $errors.Add('Safe Mode reboot requires separate approval.')
        }
        if (
            $RebootType -eq 'PostRebootResume' -and
            -not [bool](
                Get-BoostLabRebootPropertyValue $scope 'AllowResumeScheduling'
            )
        ) {
            $errors.Add('Post-reboot resume scheduling is not approved.')
        }
    }

    return [pscustomobject]@{
        IsAllowed                    = $errors.Count -eq 0
        Status                       = if ($errors.Count -eq 0) {
            'Allowed'
        }
        else {
            'Blocked'
        }
        Scope                        = $scope
        RequiresExplicitConfirmation = $true
        Errors                       = $errors.ToArray()
        Timestamp                    = Get-Date
    }
}

function Test-BoostLabRebootCheckpointSet {
    param(
        [AllowNull()]
        [object]$Checkpoints,

        [Parameter(Mandatory)]
        [object]$Scope
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $checkpointArray = @($Checkpoints)
    $requiredNames = @(
        ConvertTo-BoostLabRebootStringArray (
            Get-BoostLabRebootPropertyValue $Scope 'RequiredCheckpointNames'
        )
    )
    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    foreach ($checkpoint in $checkpointArray) {
        $name = [string](
            Get-BoostLabRebootPropertyValue $checkpoint 'Name'
        )
        $status = [string](
            Get-BoostLabRebootPropertyValue $checkpoint 'Status'
        )
        $evidence = [string](
            Get-BoostLabRebootPropertyValue $checkpoint 'Evidence'
        )
        if (-not (Test-BoostLabRebootExactIdentifier $name)) {
            $errors.Add('Checkpoint names must be exact identifiers.')
            continue
        }
        if (-not $seen.Add($name)) {
            $errors.Add("Duplicate pre-reboot checkpoint: $name")
        }
        if ($status -ne 'Passed') {
            $errors.Add("Pre-reboot checkpoint '$name' has not passed.")
        }
        if ([string]::IsNullOrWhiteSpace($evidence)) {
            $errors.Add("Pre-reboot checkpoint '$name' lacks evidence.")
        }
    }
    foreach ($requiredName in $requiredNames) {
        if (-not $seen.Contains($requiredName)) {
            $errors.Add("Required pre-reboot checkpoint is missing: $requiredName")
        }
    }

    return [pscustomobject]@{
        IsValid = $errors.Count -eq 0
        Errors  = $errors.ToArray()
    }
}

function Test-BoostLabRebootStateReferences {
    param(
        [AllowNull()]
        [object]$StateReferences,

        [Parameter(Mandatory)]
        [object]$Scope
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $references = @($StateReferences)
    $required = [bool](
        Get-BoostLabRebootPropertyValue $Scope 'RequiresStateCapture'
    )
    if ($required -and $references.Count -eq 0) {
        $errors.Add('Required state-capture references are missing.')
    }

    $allowedRoots = @(
        ConvertTo-BoostLabRebootStringArray (
            Get-BoostLabRebootPropertyValue $Scope 'AllowedStateReferenceRoots'
        )
    )
    foreach ($reference in $references) {
        $referenceId = [string](
            Get-BoostLabRebootPropertyValue $reference 'ReferenceId'
        )
        $foundation = [string](
            Get-BoostLabRebootPropertyValue $reference 'Foundation'
        )
        $recordPath = [string](
            Get-BoostLabRebootPropertyValue $reference 'RecordPath'
        )
        $recordHash = [string](
            Get-BoostLabRebootPropertyValue $reference 'RecordHash'
        )
        $verified = [bool](
            Get-BoostLabRebootPropertyValue $reference 'Verified'
        )
        if (
            -not (Test-BoostLabRebootExactIdentifier $referenceId) -or
            -not (Test-BoostLabRebootExactIdentifier $foundation)
        ) {
            $errors.Add('State references require exact identities.')
        }
        if (-not $verified) {
            $errors.Add("State reference '$referenceId' is not verified.")
        }
        if ([string]::IsNullOrWhiteSpace($recordHash)) {
            $errors.Add("State reference '$referenceId' has no integrity hash.")
        }
        try {
            $trusted = $false
            foreach ($root in $allowedRoots) {
                if (Test-BoostLabRebootPathWithinRoot $recordPath $root) {
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

    return [pscustomobject]@{
        IsValid = $errors.Count -eq 0
        Errors  = $errors.ToArray()
    }
}

function Test-BoostLabRebootResumeSteps {
    param(
        [AllowNull()]
        [object]$ResumeSteps,

        [Parameter(Mandatory)]
        [object]$Scope
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $steps = @($ResumeSteps)
    $maxSteps = [int](
        Get-BoostLabRebootPropertyValue $Scope 'MaxResumeSteps'
    )
    if ($steps.Count -gt $maxSteps) {
        $errors.Add("Resume step count exceeds the approved limit of $maxSteps.")
    }

    $allowedHandlers = @(
        ConvertTo-BoostLabRebootStringArray (
            Get-BoostLabRebootPropertyValue $Scope 'AllowedResumeHandlerIds'
        )
    )
    $allowedPaths = @(
        ConvertTo-BoostLabRebootStringArray (
            Get-BoostLabRebootPropertyValue $Scope 'AllowedResumeArtifactPaths'
        )
    )
    $stepIds = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $orders = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($step in $steps) {
        foreach ($forbidden in $script:BoostLabForbiddenResumeProperties) {
            $value = Get-BoostLabRebootPropertyValue $step $forbidden
            if (
                $null -ne $value -and
                -not [string]::IsNullOrWhiteSpace([string]$value)
            ) {
                $errors.Add(
                    "Resume steps must not contain arbitrary $forbidden values."
                )
            }
        }

        $stepId = [string](
            Get-BoostLabRebootPropertyValue $step 'StepId'
        )
        $handlerId = [string](
            Get-BoostLabRebootPropertyValue $step 'HandlerId'
        )
        $description = [string](
            Get-BoostLabRebootPropertyValue $step 'Description'
        )
        $artifactPath = [string](
            Get-BoostLabRebootPropertyValue $step 'ResumeArtifactPath'
        )
        $expectedConditions = @(
            Get-BoostLabRebootPropertyValue $step 'ExpectedConditions'
        )
        $verification = @(
            Get-BoostLabRebootPropertyValue $step 'VerificationRequirements'
        )
        $order = 0
        if (
            -not [int]::TryParse(
                [string](Get-BoostLabRebootPropertyValue $step 'Order'),
                [ref]$order
            ) -or
            $order -le 0
        ) {
            $errors.Add('Resume step order must be a positive integer.')
        }
        elseif (-not $orders.Add($order)) {
            $errors.Add("Duplicate resume step order: $order")
        }
        if (
            -not (Test-BoostLabRebootExactIdentifier $stepId) -or
            -not $stepIds.Add($stepId)
        ) {
            $errors.Add('Resume step ids must be exact and unique.')
        }
        if (
            -not (Test-BoostLabRebootExactIdentifier $handlerId) -or
            $handlerId -notin $allowedHandlers
        ) {
            $errors.Add("Resume handler '$handlerId' is not approved.")
        }
        if ([string]::IsNullOrWhiteSpace($description)) {
            $errors.Add("Resume step '$stepId' requires a description.")
        }
        if ($expectedConditions.Count -eq 0) {
            $errors.Add("Resume step '$stepId' requires expected conditions.")
        }
        if ($verification.Count -eq 0) {
            $errors.Add("Resume step '$stepId' requires verification.")
        }

        if (-not [string]::IsNullOrWhiteSpace($artifactPath)) {
            try {
                $fullArtifact = ConvertTo-BoostLabRebootFullPath $artifactPath
                $approved = $false
                foreach ($allowedPath in $allowedPaths) {
                    if ($fullArtifact.Equals(
                        (ConvertTo-BoostLabRebootFullPath $allowedPath),
                        [StringComparison]::OrdinalIgnoreCase
                    )) {
                        $approved = $true
                        break
                    }
                }
                if (-not $approved) {
                    $errors.Add(
                        "Resume step '$stepId' uses an untrusted artifact path."
                    )
                }
            }
            catch {
                $errors.Add("Resume step '$stepId' has an invalid artifact path.")
            }
        }
    }

    return [pscustomobject]@{
        IsValid = $errors.Count -eq 0
        Errors  = $errors.ToArray()
    }
}

function New-BoostLabRebootWorkflowPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ActionId,

        [Parameter(Mandatory)]
        [string]$ScopeId,

        [ValidateSet(
            'NormalReboot',
            'FirmwareReboot',
            'SafeModeReboot',
            'PostRebootResume',
            'ManualRebootRequired'
        )]
        [string]$RebootType,

        [Parameter(Mandatory)]
        [string]$Reason,

        [Parameter(Mandatory)]
        [string]$RiskClassification,

        [Parameter(Mandatory)]
        [string]$ConfirmationLevel,

        [AllowNull()]
        [object[]]$PreRebootCheckpoints,

        [AllowNull()]
        [object[]]$StateCaptureReferences,

        [AllowNull()]
        [object[]]$PendingResumeSteps,

        [AllowNull()]
        [object[]]$PostRebootVerificationRequirements,

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
        $Policy = Get-BoostLabRebootRecoveryPolicy
    }
    $errors = [System.Collections.Generic.List[string]]::new()
    $target = Test-BoostLabRebootWorkflowTarget `
        -ToolId $ToolId `
        -ActionId $ActionId `
        -ScopeId $ScopeId `
        -RebootType $RebootType `
        -Policy $Policy
    if (-not $target.IsAllowed) {
        $errors.AddRange([string[]]@($target.Errors))
    }
    $scope = $target.Scope

    if ($null -eq $ActionPlan) {
        $errors.Add('Reboot planning requires a matching Action Plan.')
    }
    else {
        if ([string]$ActionPlan.ToolId -ne $ToolId) {
            $errors.Add('Action Plan tool identity does not match.')
        }
        if ([string]$ActionPlan.Action -ne $ActionId) {
            $errors.Add('Action Plan action identity does not match.')
        }
        if (-not [bool]$ActionPlan.NeedsExplicitConfirmation) {
            $errors.Add('Action Plan must require explicit confirmation.')
        }
    }
    if (-not $Confirmed) {
        $errors.Add('Reboot workflow planning requires explicit confirmation.')
    }
    if ([string]::IsNullOrWhiteSpace($Reason)) {
        $errors.Add('Reboot reason is required.')
    }
    if ([string]::IsNullOrWhiteSpace($RecoveryInstructions)) {
        $errors.Add('Readable recovery instructions are required.')
    }
    if ([string]::IsNullOrWhiteSpace($UserWarningText)) {
        $errors.Add('User-visible reboot warning text is required.')
    }

    if ($null -ne $scope) {
        $requiredLevel = [string](
            Get-BoostLabRebootPropertyValue $scope 'RequiredConfirmationLevel'
        )
        if ($ConfirmationLevel -ne $requiredLevel) {
            $errors.Add(
                "Confirmation level must be '$requiredLevel' for this scope."
            )
        }

        $checkpointValidation = Test-BoostLabRebootCheckpointSet `
            -Checkpoints $PreRebootCheckpoints `
            -Scope $scope
        if (-not $checkpointValidation.IsValid) {
            $errors.AddRange([string[]]@($checkpointValidation.Errors))
        }

        $stateValidation = Test-BoostLabRebootStateReferences `
            -StateReferences $StateCaptureReferences `
            -Scope $scope
        if (-not $stateValidation.IsValid) {
            $errors.AddRange([string[]]@($stateValidation.Errors))
        }

        $stepValidation = Test-BoostLabRebootResumeSteps `
            -ResumeSteps $PendingResumeSteps `
            -Scope $scope
        if (-not $stepValidation.IsValid) {
            $errors.AddRange([string[]]@($stepValidation.Errors))
        }

        $maxDuration = [int](
            Get-BoostLabRebootPropertyValue $scope 'MaxDurationMinutes'
        )
        if (
            $ExpirationMinutes -le 0 -or
            $ExpirationMinutes -gt $maxDuration
        ) {
            $errors.Add(
                "Expiration must be between 1 and $maxDuration minutes."
            )
        }
        if (
            $CancellationEligible -and
            -not [bool](
                Get-BoostLabRebootPropertyValue $scope 'AllowCancellation'
            )
        ) {
            $errors.Add('Cancellation is not approved by this scope.')
        }
        if (
            @($PendingResumeSteps).Count -gt 0 -and
            -not [bool](
                Get-BoostLabRebootPropertyValue $scope 'AllowResumeScheduling'
            )
        ) {
            $errors.Add('Resume steps require separate scheduling approval.')
        }
    }
    if (@($PostRebootVerificationRequirements).Count -eq 0) {
        $errors.Add('Post-reboot verification requirements are mandatory.')
    }

    $created = (Get-Date).ToUniversalTime()
    return [pscustomobject][ordered]@{
        OperationId                       = [guid]::NewGuid().ToString()
        ToolId                            = $ToolId
        ActionId                          = $ActionId
        Timestamp                         = $created.ToString('o')
        SchemaVersion                     = $script:BoostLabRebootSchemaVersion
        BoostLabVersion                   = $BoostLabVersion
        ScopeId                           = $ScopeId
        RequestedRebootType               = $RebootType
        Reason                            = $Reason
        RiskClassification                = $RiskClassification
        RequiredConfirmationLevel         = $ConfirmationLevel
        PreRebootCheckpoints              = @($PreRebootCheckpoints)
        RequiredStateCaptureReferences    = @($StateCaptureReferences)
        PendingResumeSteps                = @(
            @($PendingResumeSteps) | Sort-Object Order
        )
        PostRebootVerificationRequirements = @(
            $PostRebootVerificationRequirements
        )
        ExpiresAt                         = $created.AddMinutes(
            [Math]::Max(1, $ExpirationMinutes)
        ).ToString('o')
        CancellationEligible              = $CancellationEligible
        RecoveryInstructions              = $RecoveryInstructions
        UserVisibleWarningText             = $UserWarningText
        ImmediateRebootRequested           = $RebootType -in @(
            'NormalReboot',
            'FirmwareReboot',
            'SafeModeReboot'
        )
        ManualRebootRequired               = $RebootType -eq
            'ManualRebootRequired'
        PostRebootContinuationRequired     = @($PendingResumeSteps).Count -gt 0
        RequiresExplicitConfirmation       = $true
        IsDryRun                           = $true
        IsAllowed                          = $errors.Count -eq 0
        Status                             = if ($errors.Count -eq 0) {
            'Allowed'
        }
        else {
            'Blocked'
        }
        Message                            = if ($errors.Count -eq 0) {
            'Reboot workflow plan is ready to be recorded.'
        }
        else {
            'Reboot workflow plan was blocked.'
        }
        Errors                             = $errors.ToArray()
    }
}

function New-BoostLabRebootWorkflowRecord {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Plan
    )

    if (-not [bool]$Plan.IsAllowed -or [string]$Plan.Status -ne 'Allowed') {
        throw 'A workflow record requires an allowed reboot plan.'
    }

    return [pscustomobject][ordered]@{
        OperationId                       = [string]$Plan.OperationId
        ToolId                            = [string]$Plan.ToolId
        ActionId                          = [string]$Plan.ActionId
        Timestamp                         = [string]$Plan.Timestamp
        SchemaVersion                     = [string]$Plan.SchemaVersion
        BoostLabVersion                   = [string]$Plan.BoostLabVersion
        ScopeId                           = [string]$Plan.ScopeId
        RequestedRebootType               = [string]$Plan.RequestedRebootType
        Reason                            = [string]$Plan.Reason
        RiskClassification                = [string]$Plan.RiskClassification
        RequiredConfirmationLevel         = [string](
            $Plan.RequiredConfirmationLevel
        )
        PreRebootCheckpoints              = @($Plan.PreRebootCheckpoints)
        RequiredStateCaptureReferences    = @(
            $Plan.RequiredStateCaptureReferences
        )
        PendingResumeSteps                = @($Plan.PendingResumeSteps)
        PostRebootVerificationRequirements = @(
            $Plan.PostRebootVerificationRequirements
        )
        ExpiresAt                         = [string]$Plan.ExpiresAt
        CancellationEligible              = [bool]$Plan.CancellationEligible
        RecoveryInstructions              = [string]$Plan.RecoveryInstructions
        UserVisibleWarningText             = [string]$Plan.UserVisibleWarningText
        WorkflowStatus                    = if (
            [bool]$Plan.PostRebootContinuationRequired
        ) {
            'PendingResume'
        }
        else {
            'PendingReboot'
        }
        Cancelled                         = $false
        CancelledAt                       = ''
        CancellationReason                = ''
        RebootRequested                   = $false
        ResumeScheduled                   = $false
        ResumeAttempted                   = $false
        ResumeCompleted                   = $false
        PostRebootVerification            = $null
        LastResult                        = $null
    }
}

function Get-BoostLabRebootSha256 {
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

function ConvertTo-BoostLabRebootRecordTable {
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

function Save-BoostLabRebootWorkflowRecord {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Record,

        [Parameter(Mandatory)]
        [string]$StateRoot
    )

    $operationId = [string](
        Get-BoostLabRebootPropertyValue $Record 'OperationId'
    )
    if (-not (Test-BoostLabRebootExactIdentifier $operationId)) {
        throw 'Reboot workflow record requires a valid OperationId.'
    }

    $recordsRoot = Join-Path $StateRoot 'Records'
    [IO.Directory]::CreateDirectory($recordsRoot) | Out-Null
    $recordJson = $Record | ConvertTo-Json -Compress -Depth 50
    $recordHash = Get-BoostLabRebootSha256 -Text $recordJson
    $envelope = [pscustomobject][ordered]@{
        SchemaVersion = $script:BoostLabRebootSchemaVersion
        RecordSha256  = $recordHash
        Record        = $Record
    }
    $recordPath = Join-Path $recordsRoot "$operationId.json"
    $envelope |
        ConvertTo-Json -Depth 60 |
        Set-Content -LiteralPath $recordPath -Encoding UTF8

    return [pscustomobject]@{
        Success      = $true
        RecordPath   = $recordPath
        RecordSha256 = $recordHash
        Timestamp    = Get-Date
    }
}

function Import-BoostLabRebootWorkflowRecord {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$RecordPath,

        [Parameter(Mandatory)]
        [string]$StateRoot
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $record = $null
    try {
        $recordsRoot = ConvertTo-BoostLabRebootFullPath (
            Join-Path $StateRoot 'Records'
        )
        $fullRecordPath = ConvertTo-BoostLabRebootFullPath $RecordPath
        if (-not (Test-BoostLabRebootPathWithinRoot $fullRecordPath $recordsRoot)) {
            $errors.Add('Workflow record is outside the BoostLab records root.')
        }
        elseif (-not (Test-Path -LiteralPath $fullRecordPath -PathType Leaf)) {
            $errors.Add('Workflow record does not exist.')
        }
        else {
            $envelope = Get-Content -LiteralPath $fullRecordPath -Raw |
                ConvertFrom-Json
            if (
                [string]$envelope.SchemaVersion -ne
                $script:BoostLabRebootSchemaVersion
            ) {
                $errors.Add('Workflow record envelope schema is unsupported.')
            }
            $record = $envelope.Record
            $recordJson = $record | ConvertTo-Json -Compress -Depth 50
            $actualHash = Get-BoostLabRebootSha256 -Text $recordJson
            if ($actualHash -ne [string]$envelope.RecordSha256) {
                $errors.Add('Workflow record integrity check failed.')
            }
        }
    }
    catch {
        $errors.Add(
            "Workflow record could not be read: $($_.Exception.Message)"
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

function Test-BoostLabRebootWorkflowRecord {
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
        $Policy = Get-BoostLabRebootRecoveryPolicy
    }
    $errors = [System.Collections.Generic.List[string]]::new()
    if ($null -eq $Record) {
        $errors.Add('Reboot workflow record is missing.')
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
            'RequestedRebootType'
            'Reason'
            'RiskClassification'
            'RequiredConfirmationLevel'
            'PreRebootCheckpoints'
            'RequiredStateCaptureReferences'
            'PendingResumeSteps'
            'PostRebootVerificationRequirements'
            'ExpiresAt'
            'CancellationEligible'
            'RecoveryInstructions'
            'UserVisibleWarningText'
            'WorkflowStatus'
            'Cancelled'
            'CancelledAt'
            'CancellationReason'
            'RebootRequested'
            'ResumeScheduled'
            'ResumeAttempted'
            'ResumeCompleted'
            'PostRebootVerification'
            'LastResult'
        )) {
            if ($null -eq $Record.PSObject.Properties[$field]) {
                $errors.Add("Reboot workflow record is missing field: $field")
            }
        }
        if (
            [string]$Record.SchemaVersion -ne
            $script:BoostLabRebootSchemaVersion
        ) {
            $errors.Add('Reboot workflow record schema is unsupported.')
        }
        if (
            -not [string]::IsNullOrWhiteSpace($ExpectedToolId) -and
            [string]$Record.ToolId -ne $ExpectedToolId
        ) {
            $errors.Add('Reboot workflow record tool identity mismatch.')
        }
        if (
            -not [string]::IsNullOrWhiteSpace($ExpectedActionId) -and
            [string]$Record.ActionId -ne $ExpectedActionId
        ) {
            $errors.Add('Reboot workflow record action identity mismatch.')
        }
        if ([string]$Record.WorkflowStatus -notin $script:BoostLabWorkflowStatuses) {
            $errors.Add('Reboot workflow record status is unsupported.')
        }

        $expiresAt = [datetime]::MinValue
        if (-not [datetime]::TryParse([string]$Record.ExpiresAt, [ref]$expiresAt)) {
            $errors.Add('Reboot workflow expiration is invalid.')
        }
        elseif ((Get-Date).ToUniversalTime() -gt $expiresAt.ToUniversalTime()) {
            $errors.Add('Reboot workflow record is expired.')
        }

        $timestamp = [datetime]::MinValue
        if (-not [datetime]::TryParse(
            [string]$Record.Timestamp,
            [ref]$timestamp
        )) {
            $errors.Add('Reboot workflow timestamp is invalid.')
        }
        elseif ($Policy.Contains('MaxRecordAgeDays')) {
            $age = (Get-Date).ToUniversalTime() - $timestamp.ToUniversalTime()
            if ($age.TotalDays -gt [int]$Policy['MaxRecordAgeDays']) {
                $errors.Add('Reboot workflow record is stale.')
            }
        }

        $target = Test-BoostLabRebootWorkflowTarget `
            -ToolId ([string]$Record.ToolId) `
            -ActionId ([string]$Record.ActionId) `
            -ScopeId ([string]$Record.ScopeId) `
            -RebootType ([string]$Record.RequestedRebootType) `
            -Policy $Policy
        if (-not $target.IsAllowed) {
            $errors.AddRange([string[]]@($target.Errors))
        }
        elseif ($null -ne $target.Scope) {
            $checkpointValidation = Test-BoostLabRebootCheckpointSet `
                -Checkpoints @($Record.PreRebootCheckpoints) `
                -Scope $target.Scope
            if (-not $checkpointValidation.IsValid) {
                $errors.AddRange([string[]]@($checkpointValidation.Errors))
            }
            $stateValidation = Test-BoostLabRebootStateReferences `
                -StateReferences @($Record.RequiredStateCaptureReferences) `
                -Scope $target.Scope
            if (-not $stateValidation.IsValid) {
                $errors.AddRange([string[]]@($stateValidation.Errors))
            }
            $stepValidation = Test-BoostLabRebootResumeSteps `
                -ResumeSteps @($Record.PendingResumeSteps) `
                -Scope $target.Scope
            if (-not $stepValidation.IsValid) {
                $errors.AddRange([string[]]@($stepValidation.Errors))
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

function Stop-BoostLabRebootWorkflow {
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

    $imported = Import-BoostLabRebootWorkflowRecord `
        -RecordPath $RecordPath `
        -StateRoot $StateRoot
    if (-not $imported.IsValid) {
        return [pscustomobject]@{
            Success        = $false
            Status         = 'Blocked'
            Cancelled      = $false
            RecoveryInstructions = ''
            Message        = 'Cancellation was blocked because the record is invalid.'
            Errors         = @($imported.Errors)
            Timestamp      = Get-Date
        }
    }
    $record = $imported.Record
    $validation = Test-BoostLabRebootWorkflowRecord `
        -Record $record `
        -ExpectedToolId $ToolId `
        -ExpectedActionId $ActionId `
        -Policy $Policy
    $errors = [System.Collections.Generic.List[string]]::new()
    if (-not $validation.IsValid) {
        $errors.AddRange([string[]]@($validation.Errors))
    }
    if (-not [bool]$record.CancellationEligible) {
        $errors.Add('This reboot workflow is not cancellation eligible.')
    }
    if ([bool]$record.Cancelled) {
        $errors.Add('This reboot workflow is already cancelled.')
    }
    if ([string]::IsNullOrWhiteSpace($Reason)) {
        $errors.Add('Cancellation reason is required.')
    }
    if ($errors.Count -gt 0) {
        return [pscustomobject]@{
            Success        = $false
            Status         = 'Blocked'
            Cancelled      = $false
            RecoveryInstructions = [string]$record.RecoveryInstructions
            Message        = 'Reboot workflow cancellation was blocked.'
            Errors         = $errors.ToArray()
            Timestamp      = Get-Date
        }
    }

    $table = ConvertTo-BoostLabRebootRecordTable $record
    $table['WorkflowStatus'] = 'Cancelled'
    $table['Cancelled'] = $true
    $table['CancelledAt'] = (Get-Date).ToUniversalTime().ToString('o')
    $table['CancellationReason'] = $Reason
    $table['LastResult'] = [pscustomobject]@{
        Status  = 'Cancelled'
        Message = $Reason
    }
    $saved = Save-BoostLabRebootWorkflowRecord `
        -Record ([pscustomobject]$table) `
        -StateRoot $StateRoot

    return [pscustomobject]@{
        Success              = $true
        Status               = 'Cancelled'
        Cancelled            = $true
        RecordPath           = $saved.RecordPath
        RecoveryInstructions = [string]$record.RecoveryInstructions
        Message              = 'Pending reboot and resume workflow was cancelled.'
        Errors               = @()
        Timestamp            = Get-Date
    }
}

function New-BoostLabRebootResumePlan {
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
    $imported = Import-BoostLabRebootWorkflowRecord `
        -RecordPath $RecordPath `
        -StateRoot $StateRoot
    if (-not $imported.IsValid) {
        $errors.AddRange([string[]]@($imported.Errors))
    }
    else {
        $record = $imported.Record
        $validation = Test-BoostLabRebootWorkflowRecord `
            -Record $record `
            -ExpectedToolId $ToolId `
            -ExpectedActionId $ActionId `
            -Policy $Policy
        if (-not $validation.IsValid) {
            $errors.AddRange([string[]]@($validation.Errors))
        }
        if ([bool]$record.Cancelled) {
            $errors.Add('Cancelled reboot workflows cannot resume.')
        }
        if ([string]$record.WorkflowStatus -ne 'PendingResume') {
            $errors.Add('Workflow is not in the PendingResume state.')
        }
        if (@($record.PendingResumeSteps).Count -eq 0) {
            $errors.Add('Workflow has no bounded pending resume steps.')
        }
        try {
            $machineState = & $MachineStateValidator $record
            if (
                $null -eq $machineState -or
                -not [bool](
                    Get-BoostLabRebootPropertyValue $machineState 'IsMatch'
                )
            ) {
                $errors.Add(
                    'Current machine state does not match resume expectations.'
                )
            }
        }
        catch {
            $errors.Add(
                "Machine-state validation failed: $($_.Exception.Message)"
            )
        }
    }

    return [pscustomobject][ordered]@{
        OperationId          = if ($null -ne $record) {
            [string]$record.OperationId
        }
        else {
            ''
        }
        ToolId               = $ToolId
        ActionId             = $ActionId
        Timestamp            = Get-Date
        SchemaVersion        = $script:BoostLabRebootSchemaVersion
        RecordPath           = $RecordPath
        PendingResumeSteps   = if ($null -ne $record) {
            @($record.PendingResumeSteps)
        }
        else {
            @()
        }
        MachineState         = $machineState
        RecoveryInstructions = if ($null -ne $record) {
            [string]$record.RecoveryInstructions
        }
        else {
            ''
        }
        IsDryRun             = $true
        IsAllowed            = $errors.Count -eq 0
        Status               = if ($errors.Count -eq 0) {
            'Allowed'
        }
        else {
            'Blocked'
        }
        Message              = if ($errors.Count -eq 0) {
            'Post-reboot resume plan passed record and machine-state validation.'
        }
        else {
            'Post-reboot resume was refused. Follow the recovery instructions.'
        }
        Errors               = $errors.ToArray()
    }
}

function Set-BoostLabRebootWorkflowVerification {
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

    $imported = Import-BoostLabRebootWorkflowRecord `
        -RecordPath $RecordPath `
        -StateRoot $StateRoot
    if (-not $imported.IsValid) {
        return [pscustomobject]@{
            Success = $false
            Status = 'Failed'
            Message = 'Post-reboot verification record is invalid.'
            RecoveryInstructions = ''
            Verification = $VerificationResult
            Errors = @($imported.Errors)
            Timestamp = Get-Date
        }
    }
    $record = $imported.Record
    $validation = Test-BoostLabRebootWorkflowRecord `
        -Record $record `
        -ExpectedToolId $ToolId `
        -ExpectedActionId $ActionId `
        -Policy $Policy
    $verificationStatus = [string](
        Get-BoostLabRebootPropertyValue $VerificationResult 'Status'
    )
    $errors = [System.Collections.Generic.List[string]]::new()
    if (-not $validation.IsValid) {
        $errors.AddRange([string[]]@($validation.Errors))
    }
    if ($verificationStatus -notin @('Passed', 'Warning', 'Failed')) {
        $errors.Add('Post-reboot verification status is unsupported.')
    }

    $successful = $errors.Count -eq 0 -and
        $verificationStatus -in @('Passed', 'Warning')
    $table = ConvertTo-BoostLabRebootRecordTable $record
    $table['WorkflowStatus'] = if ($successful) { 'Completed' } else { 'Failed' }
    $table['ResumeAttempted'] = $true
    $table['ResumeCompleted'] = $successful
    $table['PostRebootVerification'] = $VerificationResult
    $table['LastResult'] = [pscustomobject]@{
        Status = if ($successful) { $verificationStatus } else { 'Failed' }
        Message = if ($successful) {
            'Post-reboot verification completed.'
        }
        else {
            'Post-reboot verification failed. Follow recovery instructions.'
        }
    }
    Save-BoostLabRebootWorkflowRecord `
        -Record ([pscustomobject]$table) `
        -StateRoot $StateRoot | Out-Null

    return [pscustomobject]@{
        Success              = $successful
        Status               = if ($successful) {
            $verificationStatus
        }
        else {
            'Failed'
        }
        ToolId               = $ToolId
        ActionId             = $ActionId
        Verification         = $VerificationResult
        RecoveryInstructions = [string]$record.RecoveryInstructions
        Message              = if ($successful) {
            'Post-reboot workflow verification completed.'
        }
        else {
            'Post-reboot verification failed. Workflow did not continue silently.'
        }
        Errors               = $errors.ToArray()
        Timestamp            = Get-Date
    }
}

Export-ModuleMember -Function @(
    'Get-BoostLabRebootRecoveryPolicy'
    'Get-BoostLabRebootRecoveryStateRoot'
    'Test-BoostLabRebootRecoveryPolicy'
    'Test-BoostLabRebootWorkflowTarget'
    'New-BoostLabRebootWorkflowPlan'
    'New-BoostLabRebootWorkflowRecord'
    'Save-BoostLabRebootWorkflowRecord'
    'Import-BoostLabRebootWorkflowRecord'
    'Test-BoostLabRebootWorkflowRecord'
    'Stop-BoostLabRebootWorkflow'
    'New-BoostLabRebootResumePlan'
    'Set-BoostLabRebootWorkflowVerification'
)
