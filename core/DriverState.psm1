Set-StrictMode -Version Latest

$script:BoostLabDriverSchemaVersion = '1.0'
$script:BoostLabDriverPolicyPath = Join-Path `
    (Split-Path -Parent $PSScriptRoot) `
    'config\DriverStatePolicy.psd1'
$script:BoostLabDriverMutations = @(
    'Install'
    'Update'
    'Uninstall'
    'Rollback'
    'Disable'
    'Enable'
    'RemovePackage'
    'ProfileImport'
    'DebloatComponentRemoval'
)
$script:BoostLabNvidiaVendorIds = @('10DE')
$script:BoostLabNvidiaVendorNames = @('NVIDIA')

function Get-BoostLabDriverPropertyValue {
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

function ConvertTo-BoostLabDriverStringArray {
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

function Test-BoostLabDriverExactIdentifier {
    param(
        [AllowNull()]
        [object]$Value,

        [switch]$AllowDeviceCharacters
    )

    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $false
    }
    if ($text.IndexOfAny([char[]]'*?[]') -ge 0) {
        return $false
    }

    if ($AllowDeviceCharacters) {
        return $text -match '^[A-Za-z0-9][A-Za-z0-9._&+(){}\\/-]+$'
    }

    return $text -match '^[A-Za-z0-9][A-Za-z0-9._-]+$'
}

function Get-BoostLabDriverStatePolicy {
    [CmdletBinding()]
    [OutputType([System.Collections.IDictionary])]
    param(
        [string]$PolicyPath = $script:BoostLabDriverPolicyPath
    )

    if (-not (Test-Path -LiteralPath $PolicyPath -PathType Leaf)) {
        throw "Driver state policy was not found: $PolicyPath"
    }

    return Import-PowerShellDataFile -LiteralPath $PolicyPath
}

function Get-BoostLabDriverStateRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ([string]::IsNullOrWhiteSpace($env:ProgramData)) {
        throw 'The ProgramData environment variable is not available.'
    }

    return Join-Path $env:ProgramData 'BoostLab\State\Drivers'
}

function Test-BoostLabDriverStatePolicy {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabDriverStatePolicy
    }

    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($field in @(
        'SchemaVersion'
        'MaxRecordAgeDays'
        'DriverScopes'
    )) {
        if (-not $Policy.Contains($field)) {
            $errors.Add("Driver state policy is missing field: $field")
        }
    }
    if (
        $Policy.Contains('SchemaVersion') -and
        [string]$Policy['SchemaVersion'] -ne $script:BoostLabDriverSchemaVersion
    ) {
        $errors.Add(
            "Driver state policy SchemaVersion must be " +
            "$script:BoostLabDriverSchemaVersion."
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
        $errors.Add('Driver state policy MaxRecordAgeDays must be positive.')
    }

    $scopeIds = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $scopes = @(
        if ($Policy.Contains('DriverScopes')) {
            @($Policy['DriverScopes'])
        }
    )
    foreach ($scope in $scopes) {
        $scopeId = [string](
            Get-BoostLabDriverPropertyValue $scope 'ScopeId'
        )
        foreach ($field in @(
            'ScopeId'
            'ToolIds'
            'ActionIds'
            'DeviceClasses'
            'DeviceInstanceIds'
            'HardwareIds'
            'VendorIds'
            'VendorNames'
            'DriverPackageIdentities'
            'AllowedMutations'
            'ArtifactIds'
            'RebootCapableMutations'
            'RequiredStateFoundations'
            'RequireArtifactProvenance'
            'RequireRebootWorkflow'
            'AllowGpuSpecific'
            'AllowNvidiaGpuOnly'
            'AllowPackageRemoval'
            'AllowProfileImport'
            'AllowComponentRemoval'
            'NeedsExplicitConfirmation'
        )) {
            if ($null -eq (Get-BoostLabDriverPropertyValue $scope $field)) {
                $errors.Add("Driver scope is missing field: $field")
            }
        }
        if (-not (Test-BoostLabDriverExactIdentifier $scopeId)) {
            $errors.Add('Driver scope ids must be exact identifiers.')
        }
        elseif (-not $scopeIds.Add($scopeId)) {
            $errors.Add("Duplicate driver scope id: $scopeId")
        }

        foreach ($identityField in @('ToolIds', 'ActionIds')) {
            $identities = @(
                ConvertTo-BoostLabDriverStringArray (
                    Get-BoostLabDriverPropertyValue $scope $identityField
                )
            )
            if ($identities.Count -eq 0) {
                $errors.Add("Driver scope '$scopeId' requires $identityField.")
            }
            foreach ($identity in $identities) {
                if (-not (Test-BoostLabDriverExactIdentifier $identity)) {
                    $errors.Add(
                        "Driver scope '$scopeId' has a non-exact " +
                        "$identityField value."
                    )
                }
            }
        }

        foreach ($identityField in @(
            'DeviceClasses'
            'DeviceInstanceIds'
            'HardwareIds'
            'VendorIds'
            'VendorNames'
            'DriverPackageIdentities'
            'ArtifactIds'
            'RequiredStateFoundations'
        )) {
            $identities = @(
                ConvertTo-BoostLabDriverStringArray (
                    Get-BoostLabDriverPropertyValue $scope $identityField
                )
            )
            foreach ($identity in $identities) {
                if (
                    -not (
                        Test-BoostLabDriverExactIdentifier `
                            $identity `
                            -AllowDeviceCharacters
                    )
                ) {
                    $errors.Add(
                        "Driver scope '$scopeId' contains a wildcard, broad, " +
                        "or invalid $identityField value."
                    )
                }
            }
        }

        $deviceIds = @(
            ConvertTo-BoostLabDriverStringArray (
                Get-BoostLabDriverPropertyValue $scope 'DeviceInstanceIds'
            )
        )
        $hardwareIds = @(
            ConvertTo-BoostLabDriverStringArray (
                Get-BoostLabDriverPropertyValue $scope 'HardwareIds'
            )
        )
        if ($deviceIds.Count -eq 0 -or $hardwareIds.Count -eq 0) {
            $errors.Add(
                "Driver scope '$scopeId' must target exact device and " +
                'hardware identities; class-only scopes are denied.'
            )
        }

        $mutations = @(
            ConvertTo-BoostLabDriverStringArray (
                Get-BoostLabDriverPropertyValue $scope 'AllowedMutations'
            )
        )
        if ($mutations.Count -eq 0) {
            $errors.Add("Driver scope '$scopeId' requires allowed mutations.")
        }
        foreach ($mutation in $mutations) {
            if ($mutation -notin $script:BoostLabDriverMutations) {
                $errors.Add(
                    "Driver scope '$scopeId' has unsupported mutation " +
                    "'$mutation'."
                )
            }
        }
        foreach ($mutation in ConvertTo-BoostLabDriverStringArray (
            Get-BoostLabDriverPropertyValue $scope 'RebootCapableMutations'
        )) {
            if ($mutation -notin $mutations) {
                $errors.Add(
                    "Driver scope '$scopeId' lists an unapproved reboot-capable " +
                    "mutation '$mutation'."
                )
            }
        }

        foreach ($booleanField in @(
            'RequireArtifactProvenance'
            'RequireRebootWorkflow'
            'AllowGpuSpecific'
            'AllowNvidiaGpuOnly'
            'AllowPackageRemoval'
            'AllowProfileImport'
            'AllowComponentRemoval'
            'NeedsExplicitConfirmation'
        )) {
            if (
                (
                    Get-BoostLabDriverPropertyValue $scope $booleanField
                ) -isnot [bool]
            ) {
                $errors.Add(
                    "Driver scope '$scopeId' $booleanField must be Boolean."
                )
            }
        }
        if (-not [bool](
            Get-BoostLabDriverPropertyValue $scope 'NeedsExplicitConfirmation'
        )) {
            $errors.Add(
                "Driver scope '$scopeId' must require explicit confirmation."
            )
        }
        if (
            [bool](Get-BoostLabDriverPropertyValue $scope 'AllowGpuSpecific') -and
            -not [bool](
                Get-BoostLabDriverPropertyValue $scope 'AllowNvidiaGpuOnly'
            )
        ) {
            $errors.Add(
                "GPU scope '$scopeId' must remain NVIDIA-only."
            )
        }
        if (
            [bool](
                Get-BoostLabDriverPropertyValue $scope 'AllowNvidiaGpuOnly'
            ) -and
            @(
                ConvertTo-BoostLabDriverStringArray (
                    Get-BoostLabDriverPropertyValue $scope 'VendorIds'
                )
            ).Count -eq 0
        ) {
            $errors.Add(
                "NVIDIA scope '$scopeId' requires an exact NVIDIA vendor id."
            )
        }
    }

    return [pscustomobject]@{
        IsValid         = $errors.Count -eq 0
        Status          = if ($errors.Count -eq 0) { 'Valid' } else { 'Invalid' }
        DriverScopeCount = @($scopes).Count
        Errors          = $errors.ToArray()
        Timestamp       = Get-Date
    }
}

function Find-BoostLabDriverScope {
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

    foreach ($scope in @($Policy['DriverScopes'])) {
        if (
            [string](Get-BoostLabDriverPropertyValue $scope 'ScopeId') -eq
                $ScopeId -and
            $ToolId -in (ConvertTo-BoostLabDriverStringArray (
                Get-BoostLabDriverPropertyValue $scope 'ToolIds'
            )) -and
            $ActionId -in (ConvertTo-BoostLabDriverStringArray (
                Get-BoostLabDriverPropertyValue $scope 'ActionIds'
            ))
        ) {
            return $scope
        }
    }

    return $null
}

function Test-BoostLabDriverTarget {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ActionId,

        [Parameter(Mandatory)]
        [string]$ScopeId,

        [Parameter(Mandatory)]
        [ValidateSet(
            'Install',
            'Update',
            'Uninstall',
            'Rollback',
            'Disable',
            'Enable',
            'RemovePackage',
            'ProfileImport',
            'DebloatComponentRemoval'
        )]
        [string]$MutationType,

        [Parameter(Mandatory)]
        [object]$DeviceState,

        [AllowNull()]
        [object]$ProvenanceEvidence,

        [AllowNull()]
        [object]$RebootWorkflowReference,

        [AllowNull()]
        [object[]]$RelatedStateReferences,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabDriverStatePolicy
    }
    $errors = [System.Collections.Generic.List[string]]::new()
    $policyValidation = Test-BoostLabDriverStatePolicy -Policy $Policy
    if (-not $policyValidation.IsValid) {
        $errors.AddRange([string[]]@($policyValidation.Errors))
    }

    $scope = Find-BoostLabDriverScope `
        -ToolId $ToolId `
        -ActionId $ActionId `
        -ScopeId $ScopeId `
        -Policy $Policy
    if ($null -eq $scope) {
        $errors.Add(
            'Tool, action, and driver scope are not in the exact allowlist.'
        )
    }

    $deviceInstanceId = [string](
        Get-BoostLabDriverPropertyValue $DeviceState 'DeviceInstanceId'
    )
    $hardwareIds = @(
        ConvertTo-BoostLabDriverStringArray (
            Get-BoostLabDriverPropertyValue $DeviceState 'HardwareIds'
        )
    )
    $deviceClass = [string](
        Get-BoostLabDriverPropertyValue $DeviceState 'DeviceClass'
    )
    $vendorId = [string](
        Get-BoostLabDriverPropertyValue $DeviceState 'VendorId'
    )
    $vendorName = [string](
        Get-BoostLabDriverPropertyValue $DeviceState 'VendorName'
    )
    $packageIdentity = [string](
        Get-BoostLabDriverPropertyValue $DeviceState 'DriverPackageIdentity'
    )
    $isGpuDevice = [bool](
        Get-BoostLabDriverPropertyValue $DeviceState 'IsGpuDevice'
    )
    if (
        -not (
            Test-BoostLabDriverExactIdentifier `
                $deviceInstanceId `
                -AllowDeviceCharacters
        )
    ) {
        $errors.Add('An exact device instance id is required.')
    }
    if ($hardwareIds.Count -eq 0) {
        $errors.Add('At least one exact hardware id is required.')
    }
    foreach ($hardwareId in $hardwareIds) {
        if (
            -not (
                Test-BoostLabDriverExactIdentifier `
                    $hardwareId `
                    -AllowDeviceCharacters
            )
        ) {
            $errors.Add('Hardware ids must be exact and cannot use wildcards.')
        }
    }
    if ($null -ne $scope) {
        if ($MutationType -notin (ConvertTo-BoostLabDriverStringArray (
            Get-BoostLabDriverPropertyValue $scope 'AllowedMutations'
        ))) {
            $errors.Add("Driver mutation '$MutationType' is not approved.")
        }
        if ($deviceClass -notin (ConvertTo-BoostLabDriverStringArray (
            Get-BoostLabDriverPropertyValue $scope 'DeviceClasses'
        ))) {
            $errors.Add('Device class does not exactly match the driver scope.')
        }
        if ($deviceInstanceId -notin (ConvertTo-BoostLabDriverStringArray (
            Get-BoostLabDriverPropertyValue $scope 'DeviceInstanceIds'
        ))) {
            $errors.Add('Device instance id is outside the driver scope.')
        }
        foreach ($hardwareId in $hardwareIds) {
            if ($hardwareId -notin (ConvertTo-BoostLabDriverStringArray (
                Get-BoostLabDriverPropertyValue $scope 'HardwareIds'
            ))) {
                $errors.Add("Hardware id is outside the driver scope: $hardwareId")
            }
        }
        if ($vendorId -notin (ConvertTo-BoostLabDriverStringArray (
            Get-BoostLabDriverPropertyValue $scope 'VendorIds'
        ))) {
            $errors.Add('Vendor id does not exactly match the driver scope.')
        }
        if ($vendorName -notin (ConvertTo-BoostLabDriverStringArray (
            Get-BoostLabDriverPropertyValue $scope 'VendorNames'
        ))) {
            $errors.Add('Vendor name does not exactly match the driver scope.')
        }

        $isGpuScope = [bool](
            Get-BoostLabDriverPropertyValue $scope 'AllowGpuSpecific'
        )
        if ($isGpuDevice -or $isGpuScope) {
            if (-not $isGpuScope) {
                $errors.Add('GPU-specific driver work is not approved by this scope.')
            }
            if (
                $vendorId -notin $script:BoostLabNvidiaVendorIds -or
                $vendorName -notin $script:BoostLabNvidiaVendorNames -or
                -not [bool](
                    Get-BoostLabDriverPropertyValue `
                        $scope `
                        'AllowNvidiaGpuOnly'
                )
            ) {
                $errors.Add(
                    'GPU-specific driver operations are restricted to an ' +
                    'exact future NVIDIA allowlist.'
                )
            }
        }

        if ($MutationType -eq 'RemovePackage') {
            if (-not [bool](
                Get-BoostLabDriverPropertyValue $scope 'AllowPackageRemoval'
            )) {
                $errors.Add('Driver package removal is not approved.')
            }
            if (
                [string]::IsNullOrWhiteSpace($packageIdentity) -or
                $packageIdentity -notin (
                    ConvertTo-BoostLabDriverStringArray (
                        Get-BoostLabDriverPropertyValue `
                            $scope `
                            'DriverPackageIdentities'
                    )
                )
            ) {
                $errors.Add(
                    'Driver package removal requires an exact approved package identity.'
                )
            }
        }
        if (
            $MutationType -eq 'ProfileImport' -and
            -not [bool](
                Get-BoostLabDriverPropertyValue $scope 'AllowProfileImport'
            )
        ) {
            $errors.Add('Driver profile import is not approved.')
        }
        if (
            $MutationType -eq 'DebloatComponentRemoval' -and
            -not [bool](
                Get-BoostLabDriverPropertyValue $scope 'AllowComponentRemoval'
            )
        ) {
            $errors.Add('Driver component removal is not approved.')
        }

        $requiresProvenance = [bool](
            Get-BoostLabDriverPropertyValue $scope 'RequireArtifactProvenance'
        ) -or $MutationType -in @('Install', 'Update')
        if ($requiresProvenance) {
            $artifactId = [string](
                Get-BoostLabDriverPropertyValue $ProvenanceEvidence 'ArtifactId'
            )
            $verified = [bool](
                Get-BoostLabDriverPropertyValue $ProvenanceEvidence 'Verified'
            )
            if (
                -not $verified -or
                [string]::IsNullOrWhiteSpace($artifactId) -or
                $artifactId -notin (
                    ConvertTo-BoostLabDriverStringArray (
                        Get-BoostLabDriverPropertyValue $scope 'ArtifactIds'
                    )
                )
            ) {
                $errors.Add(
                    'Install and update require matching verified Phase 35 ' +
                    'artifact provenance.'
                )
            }
        }

        $rebootMutations = @(
            ConvertTo-BoostLabDriverStringArray (
                Get-BoostLabDriverPropertyValue `
                    $scope `
                    'RebootCapableMutations'
            )
        )
        if (
            [bool](
                Get-BoostLabDriverPropertyValue $scope 'RequireRebootWorkflow'
            ) -and
            $MutationType -in $rebootMutations
        ) {
            $workflowVerified = [bool](
                Get-BoostLabDriverPropertyValue `
                    $RebootWorkflowReference `
                    'Verified'
            )
            $workflowToolId = [string](
                Get-BoostLabDriverPropertyValue `
                    $RebootWorkflowReference `
                    'ToolId'
            )
            $workflowActionId = [string](
                Get-BoostLabDriverPropertyValue `
                    $RebootWorkflowReference `
                    'ActionId'
            )
            $workflowRecordPath = [string](
                Get-BoostLabDriverPropertyValue `
                    $RebootWorkflowReference `
                    'RecordPath'
            )
            $workflowRecordHash = [string](
                Get-BoostLabDriverPropertyValue `
                    $RebootWorkflowReference `
                    'RecordHash'
            )
            if (
                -not $workflowVerified -or
                $workflowToolId -ne $ToolId -or
                $workflowActionId -ne $ActionId -or
                [string]::IsNullOrWhiteSpace($workflowRecordPath) -or
                [string]::IsNullOrWhiteSpace($workflowRecordHash)
            ) {
                $errors.Add(
                    'Reboot-capable driver work requires a matching verified ' +
                    'Phase 40 workflow reference.'
                )
            }
        }

        $requiredFoundations = @(
            ConvertTo-BoostLabDriverStringArray (
                Get-BoostLabDriverPropertyValue `
                    $scope `
                    'RequiredStateFoundations'
            )
        )
        foreach ($foundation in $requiredFoundations) {
            $matchingReference = @($RelatedStateReferences) |
                Where-Object {
                    [string](
                        Get-BoostLabDriverPropertyValue $_ 'Foundation'
                    ) -eq $foundation -and
                    [bool](
                        Get-BoostLabDriverPropertyValue $_ 'Verified'
                    )
                } |
                Select-Object -First 1
            if ($null -eq $matchingReference) {
                $errors.Add(
                    "Required related state foundation is missing: $foundation"
                )
            }
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
        DeviceInstanceId             = $deviceInstanceId
        DriverPackageIdentity        = $packageIdentity
        MutationType                 = $MutationType
        RequiresExplicitConfirmation = $true
        Errors                       = $errors.ToArray()
        Timestamp                    = Get-Date
    }
}

function New-BoostLabDriverInventoryRecord {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ActionId,

        [Parameter(Mandatory)]
        [string]$ScopeId,

        [Parameter(Mandatory)]
        [ValidateSet(
            'Install',
            'Update',
            'Uninstall',
            'Rollback',
            'Disable',
            'Enable',
            'RemovePackage',
            'ProfileImport',
            'DebloatComponentRemoval'
        )]
        [string]$IntendedMutation,

        [Parameter(Mandatory)]
        [string]$DeviceInstanceId,

        [Parameter(Mandatory)]
        [scriptblock]$DeviceInspector,

        [AllowNull()]
        [object]$ProvenanceEvidence,

        [AllowNull()]
        [object]$RebootWorkflowReference,

        [AllowNull()]
        [object[]]$RelatedStateReferences,

        [bool]$RollbackEligible = $true,

        [ValidateSet('Low', 'Medium', 'High')]
        [string]$RiskClassification = 'High',

        [string[]]$VerificationRequirements = @(
            'Verify exact device identity and intended driver state.'
        ),

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $snapshot = $null
    try {
        $snapshot = & $DeviceInspector $DeviceInstanceId
    }
    catch {
        $errors.Add("Driver inventory failed: $($_.Exception.Message)")
    }
    if ($null -eq $snapshot) {
        $errors.Add('Driver inventory returned no device state.')
    }
    else {
        foreach ($field in @(
            'DeviceClass'
            'DeviceInstanceId'
            'HardwareIds'
            'VendorId'
            'VendorName'
            'DriverProvider'
            'DriverVersion'
            'DriverDate'
            'InfName'
            'PublishedName'
            'DriverPackageIdentity'
            'DeviceStatus'
            'ProblemCode'
            'AssociatedServices'
            'AssociatedFiles'
            'SourceStoreLocation'
            'IsGpuDevice'
        )) {
            if ($null -eq $snapshot.PSObject.Properties[$field]) {
                $errors.Add("Driver inventory is missing field: $field")
            }
        }
        if (
            [string](
                Get-BoostLabDriverPropertyValue `
                    $snapshot `
                    'DeviceInstanceId'
            ) -ne $DeviceInstanceId
        ) {
            $errors.Add('Driver inventory device identity does not match request.')
        }
    }

    $target = $null
    if ($errors.Count -eq 0) {
        $target = Test-BoostLabDriverTarget `
            -ToolId $ToolId `
            -ActionId $ActionId `
            -ScopeId $ScopeId `
            -MutationType $IntendedMutation `
            -DeviceState $snapshot `
            -ProvenanceEvidence $ProvenanceEvidence `
            -RebootWorkflowReference $RebootWorkflowReference `
            -RelatedStateReferences $RelatedStateReferences `
            -Policy $Policy
        if (-not $target.IsAllowed) {
            $errors.AddRange([string[]]@($target.Errors))
        }
    }

    if ($errors.Count -gt 0) {
        return [pscustomobject]@{
            Success      = $false
            Status       = 'Blocked'
            OperationId  = ''
            Record       = $null
            Message      = 'Driver inventory capture was blocked.'
            Errors       = $errors.ToArray()
            Timestamp    = Get-Date
        }
    }

    $operationId = [guid]::NewGuid().ToString()
    return [pscustomobject][ordered]@{
        Success      = $true
        Status       = 'Captured'
        OperationId  = $operationId
        Record       = [pscustomobject][ordered]@{
            OperationId                 = $operationId
            ToolId                      = $ToolId
            ActionId                    = $ActionId
            Timestamp                   = (Get-Date).ToUniversalTime().ToString('o')
            SchemaVersion               = $script:BoostLabDriverSchemaVersion
            BoostLabVersion             = 'Foundation'
            ScopeId                     = $ScopeId
            DeviceClass                 = [string]$snapshot.DeviceClass
            DeviceInstanceId            = [string]$snapshot.DeviceInstanceId
            HardwareIds                 = @($snapshot.HardwareIds)
            VendorId                    = [string]$snapshot.VendorId
            VendorName                  = [string]$snapshot.VendorName
            DriverProvider              = [string]$snapshot.DriverProvider
            DriverVersion               = [string]$snapshot.DriverVersion
            DriverDate                  = [string]$snapshot.DriverDate
            InfName                     = [string]$snapshot.InfName
            PublishedName               = [string]$snapshot.PublishedName
            DriverPackageIdentity       = [string]$snapshot.DriverPackageIdentity
            DeviceStatus                = [string]$snapshot.DeviceStatus
            ProblemCode                 = [string]$snapshot.ProblemCode
            AssociatedServices          = @($snapshot.AssociatedServices)
            AssociatedFiles             = @($snapshot.AssociatedFiles)
            SourceStoreLocation          = [string]$snapshot.SourceStoreLocation
            IsGpuDevice                 = [bool]$snapshot.IsGpuDevice
            IntendedMutation            = $IntendedMutation
            RollbackEligible            = $RollbackEligible
            ProvenanceEvidence          = $ProvenanceEvidence
            RebootWorkflowReference      = $RebootWorkflowReference
            RelatedStateReferences       = @($RelatedStateReferences)
            VerificationRequirements     = @($VerificationRequirements)
            RiskClassification           = $RiskClassification
            MutationRecorded             = $false
            PostMutationState            = $null
            MutationVerification          = $null
            RollbackRecorded             = $false
            PostRollbackState             = $null
            RollbackVerification          = $null
        }
        Message      = 'Exact driver and package state was captured before mutation.'
        Errors       = @()
        Timestamp    = Get-Date
    }
}

function Get-BoostLabDriverSha256 {
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

function Save-BoostLabDriverStateRecord {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Record,

        [Parameter(Mandatory)]
        [string]$StateRoot
    )

    $operationId = [string](
        Get-BoostLabDriverPropertyValue $Record 'OperationId'
    )
    $parsedOperationId = [guid]::Empty
    if (-not [guid]::TryParse($operationId, [ref]$parsedOperationId)) {
        throw 'Driver state record OperationId must be a GUID.'
    }

    $recordsRoot = Join-Path $StateRoot 'Records'
    [IO.Directory]::CreateDirectory($recordsRoot) | Out-Null
    $recordJson = $Record | ConvertTo-Json -Compress -Depth 60
    $recordHash = Get-BoostLabDriverSha256 -Text $recordJson
    $envelope = [pscustomobject][ordered]@{
        SchemaVersion = $script:BoostLabDriverSchemaVersion
        RecordSha256  = $recordHash
        Record        = $Record
    }
    $recordPath = Join-Path $recordsRoot "$operationId.json"
    $envelope |
        ConvertTo-Json -Depth 70 |
        Set-Content -LiteralPath $recordPath -Encoding UTF8

    return [pscustomobject]@{
        Success      = $true
        RecordPath   = $recordPath
        RecordSha256 = $recordHash
        Timestamp    = Get-Date
    }
}

function Import-BoostLabDriverStateRecord {
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
        $recordsRoot = [IO.Path]::GetFullPath(
            (Join-Path $StateRoot 'Records')
        ).TrimEnd('\', '/')
        $fullRecordPath = [IO.Path]::GetFullPath($RecordPath)
        $insideRoot = $fullRecordPath.StartsWith(
            $recordsRoot + [IO.Path]::DirectorySeparatorChar,
            [StringComparison]::OrdinalIgnoreCase
        )
        if (-not $insideRoot) {
            $errors.Add('Driver state record is outside the BoostLab records root.')
        }
        elseif (-not (Test-Path -LiteralPath $fullRecordPath -PathType Leaf)) {
            $errors.Add('Driver state record does not exist.')
        }
        else {
            $envelope = Get-Content -LiteralPath $fullRecordPath -Raw |
                ConvertFrom-Json
            if (
                [string]$envelope.SchemaVersion -ne
                $script:BoostLabDriverSchemaVersion
            ) {
                $errors.Add('Driver state envelope schema is unsupported.')
            }
            $record = $envelope.Record
            $actualHash = Get-BoostLabDriverSha256 -Text (
                $record | ConvertTo-Json -Compress -Depth 60
            )
            if ($actualHash -ne [string]$envelope.RecordSha256) {
                $errors.Add('Driver state record integrity check failed.')
            }
            if (
                [IO.Path]::GetFileNameWithoutExtension($fullRecordPath) -ne
                [string]$record.OperationId
            ) {
                $errors.Add('Driver state filename does not match OperationId.')
            }
        }
    }
    catch {
        $errors.Add("Driver state record could not be read: $($_.Exception.Message)")
    }

    return [pscustomobject]@{
        IsValid   = $errors.Count -eq 0
        Status    = if ($errors.Count -eq 0) { 'Valid' } else { 'Blocked' }
        Record    = if ($errors.Count -eq 0) { $record } else { $null }
        Errors    = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function Test-BoostLabDriverStateRecord {
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
        $Policy = Get-BoostLabDriverStatePolicy
    }
    $errors = [System.Collections.Generic.List[string]]::new()
    if ($null -eq $Record) {
        $errors.Add('Driver state record is missing.')
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
            'DeviceClass'
            'DeviceInstanceId'
            'HardwareIds'
            'VendorId'
            'VendorName'
            'DriverProvider'
            'DriverVersion'
            'DriverDate'
            'InfName'
            'PublishedName'
            'DriverPackageIdentity'
            'DeviceStatus'
            'ProblemCode'
            'AssociatedServices'
            'AssociatedFiles'
            'SourceStoreLocation'
            'IsGpuDevice'
            'IntendedMutation'
            'RollbackEligible'
            'ProvenanceEvidence'
            'RebootWorkflowReference'
            'RelatedStateReferences'
            'VerificationRequirements'
            'RiskClassification'
            'MutationRecorded'
            'PostMutationState'
            'MutationVerification'
            'RollbackRecorded'
            'PostRollbackState'
            'RollbackVerification'
        )) {
            if ($null -eq $Record.PSObject.Properties[$field]) {
                $errors.Add("Driver state record is missing field: $field")
            }
        }
        if ([string]$Record.SchemaVersion -ne $script:BoostLabDriverSchemaVersion) {
            $errors.Add('Driver state record schema is unsupported.')
        }
        if (
            -not [string]::IsNullOrWhiteSpace($ExpectedToolId) -and
            [string]$Record.ToolId -ne $ExpectedToolId
        ) {
            $errors.Add('Driver state record tool identity mismatch.')
        }
        if (
            -not [string]::IsNullOrWhiteSpace($ExpectedActionId) -and
            [string]$Record.ActionId -ne $ExpectedActionId
        ) {
            $errors.Add('Driver state record action identity mismatch.')
        }

        $timestamp = [datetime]::MinValue
        if (-not [datetime]::TryParse(
            [string]$Record.Timestamp,
            [ref]$timestamp
        )) {
            $errors.Add('Driver state timestamp is invalid.')
        }
        elseif ($Policy.Contains('MaxRecordAgeDays')) {
            $age = (Get-Date).ToUniversalTime() - $timestamp.ToUniversalTime()
            if ($age.TotalDays -gt [int]$Policy['MaxRecordAgeDays']) {
                $errors.Add('Driver state record is stale.')
            }
        }

        if ($errors.Count -eq 0) {
            $target = Test-BoostLabDriverTarget `
                -ToolId ([string]$Record.ToolId) `
                -ActionId ([string]$Record.ActionId) `
                -ScopeId ([string]$Record.ScopeId) `
                -MutationType ([string]$Record.IntendedMutation) `
                -DeviceState $Record `
                -ProvenanceEvidence $Record.ProvenanceEvidence `
                -RebootWorkflowReference $Record.RebootWorkflowReference `
                -RelatedStateReferences @($Record.RelatedStateReferences) `
                -Policy $Policy
            if (-not $target.IsAllowed) {
                $errors.AddRange([string[]]@($target.Errors))
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

function ConvertTo-BoostLabDriverRecordTable {
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

function New-BoostLabDriverMutationPlan {
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

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $record = $null
    $imported = Import-BoostLabDriverStateRecord `
        -RecordPath $RecordPath `
        -StateRoot $StateRoot
    if (-not $imported.IsValid) {
        $errors.AddRange([string[]]@($imported.Errors))
    }
    else {
        $record = $imported.Record
        $recordValidation = Test-BoostLabDriverStateRecord `
            -Record $record `
            -ExpectedToolId $ToolId `
            -ExpectedActionId $ActionId `
            -Policy $Policy
        if (-not $recordValidation.IsValid) {
            $errors.AddRange([string[]]@($recordValidation.Errors))
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
        if (-not [bool]$ActionPlan.NeedsExplicitConfirmation) {
            $errors.Add('Driver work requires explicit Action Plan confirmation.')
        }
    }
    if (-not $Confirmed) {
        $errors.Add('Driver mutation requires explicit user confirmation.')
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
        ScopeId              = if ($null -ne $record) {
            [string]$record.ScopeId
        }
        else {
            ''
        }
        DeviceInstanceId     = if ($null -ne $record) {
            [string]$record.DeviceInstanceId
        }
        else {
            ''
        }
        DriverPackageIdentity = if ($null -ne $record) {
            [string]$record.DriverPackageIdentity
        }
        else {
            ''
        }
        MutationType         = if ($null -ne $record) {
            [string]$record.IntendedMutation
        }
        else {
            ''
        }
        ActionPlan           = $ActionPlan
        IsDryRun             = $true
        IsAllowed            = $errors.Count -eq 0
        Status               = if ($errors.Count -eq 0) { 'Allowed' } else { 'Blocked' }
        Message              = if ($errors.Count -eq 0) {
            'Driver mutation plan passed exact inventory and policy validation.'
        }
        else {
            'Driver mutation planning was blocked.'
        }
        Errors               = $errors.ToArray()
        Timestamp            = Get-Date
    }
}

function Set-BoostLabDriverMutationState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$RecordPath,

        [Parameter(Mandatory)]
        [string]$StateRoot,

        [Parameter(Mandatory)]
        [object]$PostMutationState,

        [Parameter(Mandatory)]
        [object]$VerificationResult
    )

    $imported = Import-BoostLabDriverStateRecord `
        -RecordPath $RecordPath `
        -StateRoot $StateRoot
    if (-not $imported.IsValid) {
        return [pscustomobject]@{
            Success    = $false
            Status     = 'Blocked'
            RecordPath = $RecordPath
            Message    = 'Driver mutation state could not be persisted.'
            Errors     = @($imported.Errors)
            Timestamp  = Get-Date
        }
    }
    if (
        [string](
            Get-BoostLabDriverPropertyValue $VerificationResult 'Status'
        ) -notin @('Passed', 'Warning')
    ) {
        return [pscustomobject]@{
            Success    = $false
            Status     = 'Failed'
            RecordPath = $RecordPath
            Message    = 'Driver mutation verification did not pass.'
            Errors     = @('Mutation verification must be Passed or Warning.')
            Timestamp  = Get-Date
        }
    }

    $table = ConvertTo-BoostLabDriverRecordTable $imported.Record
    $table['MutationRecorded'] = $true
    $table['PostMutationState'] = $PostMutationState
    $table['MutationVerification'] = $VerificationResult
    $saved = Save-BoostLabDriverStateRecord `
        -Record ([pscustomobject]$table) `
        -StateRoot $StateRoot

    return [pscustomobject]@{
        Success    = $true
        Status     = 'Recorded'
        RecordPath = $saved.RecordPath
        Message    = 'Verified post-mutation driver state was persisted.'
        Errors     = @()
        Timestamp  = Get-Date
    }
}

function Test-BoostLabDriverIdentityMatch {
    param(
        [Parameter(Mandatory)]
        [object]$Expected,

        [Parameter(Mandatory)]
        [object]$Actual
    )

    $expectedHardwareIds = @(
        ConvertTo-BoostLabDriverStringArray (
            Get-BoostLabDriverPropertyValue $Expected 'HardwareIds'
        )
    ) | Sort-Object
    $actualHardwareIds = @(
        ConvertTo-BoostLabDriverStringArray (
            Get-BoostLabDriverPropertyValue $Actual 'HardwareIds'
        )
    ) | Sort-Object
    return (
        [string](
            Get-BoostLabDriverPropertyValue $Expected 'DeviceInstanceId'
        ) -eq
        [string](
            Get-BoostLabDriverPropertyValue $Actual 'DeviceInstanceId'
        ) -and
        [string](Get-BoostLabDriverPropertyValue $Expected 'VendorId') -eq
        [string](Get-BoostLabDriverPropertyValue $Actual 'VendorId') -and
        ($expectedHardwareIds -join '|') -eq ($actualHardwareIds -join '|')
    )
}

function New-BoostLabDriverRollbackPlan {
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
        [scriptblock]$DeviceInspector,

        [Parameter(Mandatory)]
        [object]$ActionPlan,

        [bool]$Confirmed,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $record = $null
    $currentState = $null
    $imported = Import-BoostLabDriverStateRecord `
        -RecordPath $RecordPath `
        -StateRoot $StateRoot
    if (-not $imported.IsValid) {
        $errors.AddRange([string[]]@($imported.Errors))
    }
    else {
        $record = $imported.Record
        $validation = Test-BoostLabDriverStateRecord `
            -Record $record `
            -ExpectedToolId $ToolId `
            -ExpectedActionId $ActionId `
            -Policy $Policy
        if (-not $validation.IsValid) {
            $errors.AddRange([string[]]@($validation.Errors))
        }
        if (-not [bool]$record.RollbackEligible) {
            $errors.Add('Driver state record is not rollback eligible.')
        }
        if (-not [bool]$record.MutationRecorded) {
            $errors.Add('Rollback requires a recorded verified mutation.')
        }
        if ([bool]$record.RollbackRecorded) {
            $errors.Add('Driver rollback was already recorded.')
        }
        if (
            [string]::IsNullOrWhiteSpace([string]$record.DriverPackageIdentity) -or
            [string]::IsNullOrWhiteSpace([string]$record.SourceStoreLocation) -or
            [string]::IsNullOrWhiteSpace([string]$record.InfName)
        ) {
            $errors.Add(
                'Captured driver package identity or source-store information is missing.'
            )
        }
        try {
            $currentState = & $DeviceInspector ([string]$record.DeviceInstanceId)
            if (
                $null -eq $currentState -or
                -not (Test-BoostLabDriverIdentityMatch $record $currentState)
            ) {
                $errors.Add(
                    'Current device identity drifted from the captured target.'
                )
            }
        }
        catch {
            $errors.Add(
                "Current driver identity inspection failed: $($_.Exception.Message)"
            )
        }
    }

    if ($null -eq $ActionPlan) {
        $errors.Add('A matching Action Plan is required for driver rollback.')
    }
    else {
        if ([string]$ActionPlan.ToolId -ne $ToolId) {
            $errors.Add('Rollback Action Plan tool identity does not match.')
        }
        if ([string]$ActionPlan.Action -ne $ActionId) {
            $errors.Add('Rollback Action Plan action identity does not match.')
        }
        if (-not [bool]$ActionPlan.NeedsExplicitConfirmation) {
            $errors.Add('Driver rollback requires explicit confirmation.')
        }
    }
    if (-not $Confirmed) {
        $errors.Add('Driver rollback requires explicit user confirmation.')
    }

    return [pscustomobject][ordered]@{
        OperationId              = if ($null -ne $record) {
            [string]$record.OperationId
        }
        else {
            ''
        }
        ToolId                   = $ToolId
        ActionId                 = $ActionId
        ScopeId                  = if ($null -ne $record) {
            [string]$record.ScopeId
        }
        else {
            ''
        }
        DeviceInstanceId         = if ($null -ne $record) {
            [string]$record.DeviceInstanceId
        }
        else {
            ''
        }
        OriginalDriverPackage    = if ($null -ne $record) {
            [string]$record.DriverPackageIdentity
        }
        else {
            ''
        }
        DriverPackageIdentity    = if ($null -ne $record) {
            [string]$record.DriverPackageIdentity
        }
        else {
            ''
        }
        MutationType             = 'Rollback'
        OriginalSourceStore      = if ($null -ne $record) {
            [string]$record.SourceStoreLocation
        }
        else {
            ''
        }
        CurrentState             = $currentState
        ActionPlan               = $ActionPlan
        IsDryRun                 = $true
        IsAllowed                = $errors.Count -eq 0
        Status                   = if ($errors.Count -eq 0) {
            'Allowed'
        }
        else {
            'Blocked'
        }
        Message                  = if ($errors.Count -eq 0) {
            'Driver rollback plan passed record, package, and identity validation.'
        }
        else {
            'Driver rollback was refused.'
        }
        Errors                   = $errors.ToArray()
        Timestamp                = Get-Date
    }
}

function Set-BoostLabDriverRollbackState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$RecordPath,

        [Parameter(Mandatory)]
        [string]$StateRoot,

        [Parameter(Mandatory)]
        [object]$PostRollbackState,

        [Parameter(Mandatory)]
        [object]$VerificationResult
    )

    $imported = Import-BoostLabDriverStateRecord `
        -RecordPath $RecordPath `
        -StateRoot $StateRoot
    if (-not $imported.IsValid) {
        return [pscustomobject]@{
            Success    = $false
            Status     = 'Blocked'
            RecordPath = $RecordPath
            Message    = 'Driver rollback state could not be persisted.'
            Errors     = @($imported.Errors)
            Timestamp  = Get-Date
        }
    }
    if (
        [string](
            Get-BoostLabDriverPropertyValue $VerificationResult 'Status'
        ) -notin @('Passed', 'Warning')
    ) {
        return [pscustomobject]@{
            Success    = $false
            Status     = 'Failed'
            RecordPath = $RecordPath
            Message    = 'Driver rollback verification did not pass.'
            Errors     = @('Rollback verification must be Passed or Warning.')
            Timestamp  = Get-Date
        }
    }

    $table = ConvertTo-BoostLabDriverRecordTable $imported.Record
    $table['RollbackRecorded'] = $true
    $table['PostRollbackState'] = $PostRollbackState
    $table['RollbackVerification'] = $VerificationResult
    $saved = Save-BoostLabDriverStateRecord `
        -Record ([pscustomobject]$table) `
        -StateRoot $StateRoot

    return [pscustomobject]@{
        Success    = $true
        Status     = 'Recorded'
        RecordPath = $saved.RecordPath
        Message    = 'Verified post-rollback driver state was persisted.'
        Errors     = @()
        Timestamp  = Get-Date
    }
}

Export-ModuleMember -Function @(
    'Get-BoostLabDriverStatePolicy'
    'Get-BoostLabDriverStateRoot'
    'Test-BoostLabDriverStatePolicy'
    'Test-BoostLabDriverTarget'
    'New-BoostLabDriverInventoryRecord'
    'Save-BoostLabDriverStateRecord'
    'Import-BoostLabDriverStateRecord'
    'Test-BoostLabDriverStateRecord'
    'New-BoostLabDriverMutationPlan'
    'Set-BoostLabDriverMutationState'
    'New-BoostLabDriverRollbackPlan'
    'Set-BoostLabDriverRollbackState'
)
