Set-StrictMode -Version Latest

$script:BoostLabServiceRollbackSchemaVersion = '1.0'
$script:BoostLabServicePolicyPath = Join-Path `
    (Split-Path -Parent $PSScriptRoot) `
    'config\ServiceRollbackPolicy.psd1'
$script:BoostLabServiceMutations = @(
    'Start'
    'Stop'
    'Disable'
    'Enable'
    'SetStartupType'
    'Delete'
    'Create'
    'ChangeConfig'
)

function Get-BoostLabServicePropertyValue {
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

function ConvertTo-BoostLabServiceArray {
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

function Get-BoostLabServiceRollbackPolicy {
    [CmdletBinding()]
    [OutputType([System.Collections.IDictionary])]
    param(
        [string]$PolicyPath = $script:BoostLabServicePolicyPath
    )

    if (-not (Test-Path -LiteralPath $PolicyPath -PathType Leaf)) {
        throw "Service rollback policy was not found: $PolicyPath"
    }

    return Import-PowerShellDataFile -LiteralPath $PolicyPath
}

function Get-BoostLabServiceRollbackStateRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ([string]::IsNullOrWhiteSpace($env:ProgramData)) {
        throw 'The ProgramData environment variable is not available.'
    }

    return Join-Path $env:ProgramData 'BoostLab\State\ServiceRollback'
}

function Test-BoostLabServiceName {
    param(
        [AllowNull()]
        [string]$ServiceName
    )

    if ([string]::IsNullOrWhiteSpace($ServiceName)) {
        return $false
    }
    if ($ServiceName.IndexOfAny([char[]]'*?[]') -ge 0) {
        return $false
    }
    if ($ServiceName -notmatch '^[A-Za-z0-9_.-]+$') {
        return $false
    }
    if ($ServiceName -in @('all', 'service', 'services', 'windows')) {
        return $false
    }

    return $true
}

function Test-BoostLabServiceRollbackPolicy {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabServiceRollbackPolicy
    }

    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($field in @(
        'SchemaVersion'
        'MaxRecordAgeDays'
        'ServiceScopes'
        'ProtectedServiceNames'
    )) {
        if (-not $Policy.Contains($field)) {
            $errors.Add("Service rollback policy is missing field: $field")
        }
    }
    if (
        $Policy.Contains('SchemaVersion') -and
        [string]$Policy['SchemaVersion'] -ne $script:BoostLabServiceRollbackSchemaVersion
    ) {
        $errors.Add(
            "Service rollback policy SchemaVersion must be $script:BoostLabServiceRollbackSchemaVersion."
        )
    }

    $maxAge = 0
    if (
        $Policy.Contains('MaxRecordAgeDays') -and
        (
            -not [int]::TryParse([string]$Policy['MaxRecordAgeDays'], [ref]$maxAge) -or
            $maxAge -le 0
        )
    ) {
        $errors.Add('Service rollback policy MaxRecordAgeDays must be a positive integer.')
    }

    $protectedNames = @(
        if ($Policy.Contains('ProtectedServiceNames')) {
            ConvertTo-BoostLabServiceArray -Value $Policy['ProtectedServiceNames']
        }
    )
    foreach ($protectedName in $protectedNames) {
        if (-not (Test-BoostLabServiceName -ServiceName $protectedName)) {
            $errors.Add("Protected service name is invalid or broad: $protectedName")
        }
    }

    $scopeIds = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $scopes = @(
        if ($Policy.Contains('ServiceScopes')) {
            @($Policy['ServiceScopes'])
        }
    )
    foreach ($scope in $scopes) {
        foreach ($field in @(
            'ScopeId'
            'ToolIds'
            'ServiceNames'
            'AllowedMutations'
            'AllowProtectedServices'
            'AllowCreateService'
            'AllowDeleteService'
            'AllowRecreateMissingService'
            'RestoreStartupType'
            'RestoreDelayedAutoStart'
            'RestoreStatus'
        )) {
            if ($null -eq (Get-BoostLabServicePropertyValue -InputObject $scope -Name $field)) {
                $errors.Add("Service scope is missing field: $field")
            }
        }

        $scopeId = [string](
            Get-BoostLabServicePropertyValue -InputObject $scope -Name 'ScopeId'
        )
        if ([string]::IsNullOrWhiteSpace($scopeId)) {
            $errors.Add('Service scope ScopeId cannot be empty.')
        }
        elseif (-not $scopeIds.Add($scopeId)) {
            $errors.Add("Service scope id is duplicated: $scopeId")
        }

        $toolIds = @(
            ConvertTo-BoostLabServiceArray -Value (
                Get-BoostLabServicePropertyValue -InputObject $scope -Name 'ToolIds'
            )
        )
        if ($toolIds.Count -eq 0) {
            $errors.Add("Service scope '$scopeId' must declare at least one exact tool id.")
        }
        foreach ($toolId in $toolIds) {
            if ($toolId.IndexOfAny([char[]]'*?[]') -ge 0) {
                $errors.Add("Service scope '$scopeId' contains a wildcard tool id.")
            }
        }

        $serviceNames = @(
            ConvertTo-BoostLabServiceArray -Value (
                Get-BoostLabServicePropertyValue -InputObject $scope -Name 'ServiceNames'
            )
        )
        if ($serviceNames.Count -eq 0) {
            $errors.Add("Service scope '$scopeId' must declare at least one exact service name.")
        }
        foreach ($serviceName in $serviceNames) {
            if (-not (Test-BoostLabServiceName -ServiceName $serviceName)) {
                $errors.Add(
                    "Service scope '$scopeId' contains an invalid or broad service name: $serviceName"
                )
            }
        }

        $allowedMutations = @(
            ConvertTo-BoostLabServiceArray -Value (
                Get-BoostLabServicePropertyValue -InputObject $scope -Name 'AllowedMutations'
            )
        )
        if ($allowedMutations.Count -eq 0) {
            $errors.Add("Service scope '$scopeId' must declare approved mutation types.")
        }
        foreach ($mutation in $allowedMutations) {
            if ($mutation -notin $script:BoostLabServiceMutations) {
                $errors.Add(
                    "Service scope '$scopeId' contains unsupported mutation type: $mutation"
                )
            }
        }

        foreach ($booleanField in @(
            'AllowProtectedServices'
            'AllowCreateService'
            'AllowDeleteService'
            'AllowRecreateMissingService'
            'RestoreStartupType'
            'RestoreDelayedAutoStart'
            'RestoreStatus'
        )) {
            if (
                (Get-BoostLabServicePropertyValue -InputObject $scope -Name $booleanField) -isnot [bool]
            ) {
                $errors.Add("Service scope '$scopeId' $booleanField must be Boolean.")
            }
        }
    }

    return [pscustomobject]@{
        IsValid           = $errors.Count -eq 0
        ServiceScopeCount = $scopes.Count
        Errors            = $errors.ToArray()
        Timestamp         = Get-Date
    }
}

function Test-BoostLabServiceCaptureTarget {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ScopeId,

        [Parameter(Mandatory)]
        [string]$ServiceName,

        [Parameter(Mandatory)]
        [string]$IntendedMutation,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabServiceRollbackPolicy
    }

    $errors = [System.Collections.Generic.List[string]]::new()
    $policyValidation = Test-BoostLabServiceRollbackPolicy -Policy $Policy
    if (-not $policyValidation.IsValid) {
        $errors.AddRange([string[]]@($policyValidation.Errors))
    }
    if (-not (Test-BoostLabServiceName -ServiceName $ServiceName)) {
        $errors.Add('Service capture requires one exact non-wildcard service name.')
    }
    if ($IntendedMutation -notin $script:BoostLabServiceMutations) {
        $errors.Add("Service mutation type is not supported: $IntendedMutation")
    }

    $scope = @(
        if ($Policy.Contains('ServiceScopes')) {
            @($Policy['ServiceScopes'])
        }
    ) |
        Where-Object {
            [string](Get-BoostLabServicePropertyValue -InputObject $_ -Name 'ScopeId') -eq $ScopeId
        } |
        Select-Object -First 1
    if ($null -eq $scope) {
        $errors.Add("Service scope '$ScopeId' is not approved.")
    }
    else {
        $toolIds = @(
            ConvertTo-BoostLabServiceArray -Value (
                Get-BoostLabServicePropertyValue -InputObject $scope -Name 'ToolIds'
            )
        )
        if ($ToolId -notin $toolIds) {
            $errors.Add("Service scope '$ScopeId' is not approved for tool '$ToolId'.")
        }

        $serviceNames = @(
            ConvertTo-BoostLabServiceArray -Value (
                Get-BoostLabServicePropertyValue -InputObject $scope -Name 'ServiceNames'
            )
        )
        if ($ServiceName -notin $serviceNames) {
            $errors.Add(
                "Service '$ServiceName' is not explicitly approved by scope '$ScopeId'."
            )
        }

        $allowedMutations = @(
            ConvertTo-BoostLabServiceArray -Value (
                Get-BoostLabServicePropertyValue -InputObject $scope -Name 'AllowedMutations'
            )
        )
        if ($IntendedMutation -notin $allowedMutations) {
            $errors.Add(
                "Mutation '$IntendedMutation' is not approved by service scope '$ScopeId'."
            )
        }

        $allowProtected = [bool](
            Get-BoostLabServicePropertyValue `
                -InputObject $scope `
                -Name 'AllowProtectedServices'
        )
        $protectedNames = @(
            ConvertTo-BoostLabServiceArray -Value $Policy['ProtectedServiceNames']
        )
        if ($ServiceName -in $protectedNames -and -not $allowProtected) {
            $errors.Add("Protected/core Windows service is denied: $ServiceName")
        }
        if (
            $IntendedMutation -eq 'Create' -and
            -not [bool](
                Get-BoostLabServicePropertyValue -InputObject $scope -Name 'AllowCreateService'
            )
        ) {
            $errors.Add("Service creation is not approved by scope '$ScopeId'.")
        }
        if (
            $IntendedMutation -eq 'Delete' -and
            -not [bool](
                Get-BoostLabServicePropertyValue -InputObject $scope -Name 'AllowDeleteService'
            )
        ) {
            $errors.Add("Service deletion is not approved by scope '$ScopeId'.")
        }
    }

    return [pscustomobject]@{
        IsAllowed         = $errors.Count -eq 0
        Status            = if ($errors.Count -eq 0) { 'Allowed' } else { 'Blocked' }
        ToolId            = $ToolId
        ScopeId           = $ScopeId
        ServiceName       = $ServiceName
        IntendedMutation  = $IntendedMutation
        Scope             = $scope
        Errors            = $errors.ToArray()
        Timestamp         = Get-Date
    }
}

function ConvertTo-BoostLabServiceSnapshot {
    param(
        [Parameter(Mandatory)]
        [string]$RequestedServiceName,

        [Parameter(Mandatory)]
        [object]$Snapshot
    )

    $existsValue = Get-BoostLabServicePropertyValue -InputObject $Snapshot -Name 'Exists'
    if ($null -eq $existsValue -or $existsValue -isnot [bool]) {
        throw 'Service reader must return a Boolean Exists field.'
    }

    $reportedName = [string](
        Get-BoostLabServicePropertyValue -InputObject $Snapshot -Name 'ServiceName'
    )
    if ([string]::IsNullOrWhiteSpace($reportedName)) {
        $reportedName = $RequestedServiceName
    }
    if (
        [bool]$existsValue -and
        -not $reportedName.Equals(
            $RequestedServiceName,
            [StringComparison]::OrdinalIgnoreCase
        )
    ) {
        throw (
            "Service reader identity mismatch. Requested '$RequestedServiceName', " +
            "received '$reportedName'."
        )
    }

    return [pscustomobject][ordered]@{
        Exists           = [bool]$existsValue
        ServiceName      = $reportedName
        DisplayName      = [string](
            Get-BoostLabServicePropertyValue -InputObject $Snapshot -Name 'DisplayName'
        )
        Status           = [string](
            Get-BoostLabServicePropertyValue -InputObject $Snapshot -Name 'Status'
        )
        StartupType      = [string](
            Get-BoostLabServicePropertyValue -InputObject $Snapshot -Name 'StartupType'
        )
        DelayedAutoStart = Get-BoostLabServicePropertyValue `
            -InputObject $Snapshot `
            -Name 'DelayedAutoStart'
        BinaryPath       = [string](
            Get-BoostLabServicePropertyValue -InputObject $Snapshot -Name 'BinaryPath'
        )
        ServiceAccount   = [string](
            Get-BoostLabServicePropertyValue -InputObject $Snapshot -Name 'ServiceAccount'
        )
        Dependencies     = @(
            ConvertTo-BoostLabServiceArray -Value (
                Get-BoostLabServicePropertyValue -InputObject $Snapshot -Name 'Dependencies'
            )
        )
        Description      = [string](
            Get-BoostLabServicePropertyValue -InputObject $Snapshot -Name 'Description'
        )
        FailureActions   = Get-BoostLabServicePropertyValue `
            -InputObject $Snapshot `
            -Name 'FailureActions'
    }
}

function Get-BoostLabServiceSnapshot {
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,

        [Parameter(Mandatory)]
        [scriptblock]$ServiceReader
    )

    $snapshot = & $ServiceReader $ServiceName
    if ($null -eq $snapshot) {
        throw 'Service reader returned no snapshot.'
    }

    return ConvertTo-BoostLabServiceSnapshot `
        -RequestedServiceName $ServiceName `
        -Snapshot $snapshot
}

function ConvertTo-BoostLabServiceFullPath {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'A non-empty path is required.'
    }
    if ($Path.IndexOfAny([char[]]'*?[]') -ge 0) {
        throw 'Wildcard paths are not allowed.'
    }
    if (-not [IO.Path]::IsPathRooted($Path)) {
        throw 'An absolute path is required.'
    }

    return [IO.Path]::GetFullPath($Path).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
}

function Test-BoostLabServicePathWithinRoot {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Root
    )

    $fullPath = ConvertTo-BoostLabServiceFullPath -Path $Path
    $fullRoot = ConvertTo-BoostLabServiceFullPath -Path $Root
    if ($fullPath.Equals($fullRoot, [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    return $fullPath.StartsWith(
        $fullRoot + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase
    )
}

function New-BoostLabServiceRollbackRecordObject {
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ActionId,

        [Parameter(Mandatory)]
        [string]$ScopeId,

        [Parameter(Mandatory)]
        [string]$ServiceName,

        [Parameter(Mandatory)]
        [string]$IntendedMutation,

        [Parameter(Mandatory)]
        [object]$OriginalState,

        [Parameter(Mandatory)]
        [bool]$RollbackEligible,

        [ValidateSet('Low', 'Medium', 'High')]
        [string]$RiskClassification = 'High',

        [string]$BoostLabVersion = 'Foundation'
    )

    return [pscustomobject][ordered]@{
        OperationId              = [guid]::NewGuid().ToString()
        ToolId                   = $ToolId
        ActionId                 = $ActionId
        Timestamp                = (Get-Date).ToUniversalTime().ToString('o')
        SchemaVersion            = $script:BoostLabServiceRollbackSchemaVersion
        BoostLabVersion          = $BoostLabVersion
        ScopeId                  = $ScopeId
        ServiceName              = $ServiceName
        DisplayName              = $OriginalState.DisplayName
        OriginalExists           = [bool]$OriginalState.Exists
        OriginalStatus           = $OriginalState.Status
        OriginalStartupType      = $OriginalState.StartupType
        OriginalDelayedAutoStart = $OriginalState.DelayedAutoStart
        OriginalBinaryPath       = $OriginalState.BinaryPath
        OriginalServiceAccount   = $OriginalState.ServiceAccount
        OriginalDependencies     = @($OriginalState.Dependencies)
        OriginalDescription      = $OriginalState.Description
        OriginalFailureActions   = $OriginalState.FailureActions
        IntendedMutation         = $IntendedMutation
        RollbackEligible         = $RollbackEligible
        VerificationRequirement  = 'Verify exact service identity and captured state before and after rollback.'
        RiskClassification       = $RiskClassification
        MutationRecorded         = $false
        PostMutationState        = $null
        RollbackCompleted        = $false
        RollbackCompletedAt      = $null
    }
}

function ConvertTo-BoostLabServiceRecordTable {
    param(
        [Parameter(Mandatory)]
        [object]$Record
    )

    $table = [ordered]@{}
    if ($Record -is [System.Collections.IDictionary]) {
        foreach ($key in $Record.Keys) {
            $table[[string]$key] = $Record[$key]
        }
    }
    else {
        foreach ($property in $Record.PSObject.Properties) {
            $table[$property.Name] = $property.Value
        }
    }

    return $table
}

function Save-BoostLabServiceRollbackRecord {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Record,

        [Parameter(Mandatory)]
        [string]$StateRoot
    )

    $operationId = [string](
        Get-BoostLabServicePropertyValue -InputObject $Record -Name 'OperationId'
    )
    if ([string]::IsNullOrWhiteSpace($operationId)) {
        throw 'Service rollback record requires an OperationId.'
    }

    $fullStateRoot = ConvertTo-BoostLabServiceFullPath -Path $StateRoot
    $recordsRoot = Join-Path $fullStateRoot 'Records'
    [IO.Directory]::CreateDirectory($recordsRoot) | Out-Null

    $recordJson = $Record | ConvertTo-Json -Compress -Depth 40
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $recordHash = [BitConverter]::ToString(
            $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($recordJson))
        ).Replace('-', '')
    }
    finally {
        $sha256.Dispose()
    }

    $recordPath = Join-Path $recordsRoot "$operationId.service.json"
    $envelope = [ordered]@{
        EnvelopeVersion = '1.0'
        RecordSha256    = $recordHash
        RecordJson      = $recordJson
    }
    [IO.File]::WriteAllText(
        $recordPath,
        ($envelope | ConvertTo-Json -Depth 5),
        [Text.Encoding]::UTF8
    )

    return [pscustomobject]@{
        Success      = $true
        RecordPath   = $recordPath
        RecordSha256 = $recordHash
        Timestamp    = Get-Date
    }
}

function Import-BoostLabServiceRollbackRecord {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$RecordPath,

        [Parameter(Mandatory)]
        [string]$StateRoot
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $fullRecordPath = ''
    $recordsRoot = ''
    try {
        $fullRecordPath = ConvertTo-BoostLabServiceFullPath -Path $RecordPath
        $recordsRoot = Join-Path `
            (ConvertTo-BoostLabServiceFullPath -Path $StateRoot) `
            'Records'
        if (
            -not (Test-BoostLabServicePathWithinRoot -Path $fullRecordPath -Root $recordsRoot)
        ) {
            $errors.Add('Service rollback record is outside the BoostLab records directory.')
        }
    }
    catch {
        $errors.Add($_.Exception.Message)
    }

    if (
        $errors.Count -eq 0 -and
        -not (Test-Path -LiteralPath $fullRecordPath -PathType Leaf)
    ) {
        $errors.Add('Service rollback record does not exist.')
    }

    $record = $null
    if ($errors.Count -eq 0) {
        try {
            $envelope = Get-Content -LiteralPath $fullRecordPath -Raw |
                ConvertFrom-Json -ErrorAction Stop
            if (
                [string]$envelope.EnvelopeVersion -ne '1.0' -or
                [string]::IsNullOrWhiteSpace([string]$envelope.RecordJson) -or
                [string]::IsNullOrWhiteSpace([string]$envelope.RecordSha256)
            ) {
                throw 'Service rollback record envelope is incomplete.'
            }

            $sha256 = [Security.Cryptography.SHA256]::Create()
            try {
                $actualHash = [BitConverter]::ToString(
                    $sha256.ComputeHash(
                        [Text.Encoding]::UTF8.GetBytes([string]$envelope.RecordJson)
                    )
                ).Replace('-', '')
            }
            finally {
                $sha256.Dispose()
            }
            if ($actualHash -ne [string]$envelope.RecordSha256) {
                throw 'Service rollback record integrity hash does not match.'
            }

            $record = [string]$envelope.RecordJson |
                ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            $errors.Add($_.Exception.Message)
        }
    }

    return [pscustomobject]@{
        IsValid    = $errors.Count -eq 0
        Status     = if ($errors.Count -eq 0) { 'Loaded' } else { 'Blocked' }
        RecordPath = $fullRecordPath
        Record     = $record
        Errors     = $errors.ToArray()
        Timestamp  = Get-Date
    }
}

function Test-BoostLabServiceRollbackRecord {
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
        $Policy = Get-BoostLabServiceRollbackPolicy
    }

    $errors = [System.Collections.Generic.List[string]]::new()
    $policyValidation = Test-BoostLabServiceRollbackPolicy -Policy $Policy
    if (-not $policyValidation.IsValid) {
        $errors.AddRange([string[]]@($policyValidation.Errors))
    }
    if ($null -eq $Record) {
        $errors.Add('Service rollback record is missing.')
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
            'ServiceName'
            'DisplayName'
            'OriginalExists'
            'OriginalStatus'
            'OriginalStartupType'
            'OriginalDelayedAutoStart'
            'OriginalBinaryPath'
            'OriginalServiceAccount'
            'OriginalDependencies'
            'OriginalDescription'
            'OriginalFailureActions'
            'IntendedMutation'
            'RollbackEligible'
            'VerificationRequirement'
            'RiskClassification'
            'MutationRecorded'
            'PostMutationState'
            'RollbackCompleted'
        )) {
            if ($null -eq $Record.PSObject.Properties[$field]) {
                $errors.Add("Service rollback record is missing field: $field")
            }
        }
    }

    if ($errors.Count -eq 0) {
        if (
            [string](
                Get-BoostLabServicePropertyValue -InputObject $Record -Name 'SchemaVersion'
            ) -ne $script:BoostLabServiceRollbackSchemaVersion
        ) {
            $errors.Add('Service rollback record schema version is unsupported.')
        }

        $operationId = [guid]::Empty
        if (
            -not [guid]::TryParse(
                [string](
                    Get-BoostLabServicePropertyValue -InputObject $Record -Name 'OperationId'
                ),
                [ref]$operationId
            )
        ) {
            $errors.Add('Service rollback record OperationId is invalid.')
        }
        if (
            -not (Test-BoostLabServiceName -ServiceName (
                [string](
                    Get-BoostLabServicePropertyValue -InputObject $Record -Name 'ServiceName'
                )
            ))
        ) {
            $errors.Add('Service rollback record ServiceName is invalid or broad.')
        }

        $recordTimestamp = [datetime]::MinValue
        if (
            -not [datetime]::TryParse(
                [string](
                    Get-BoostLabServicePropertyValue -InputObject $Record -Name 'Timestamp'
                ),
                [ref]$recordTimestamp
            )
        ) {
            $errors.Add('Service rollback record Timestamp is invalid.')
        }
        else {
            $maxAgeDays = if ($Policy.Contains('MaxRecordAgeDays')) {
                [int]$Policy['MaxRecordAgeDays']
            }
            else {
                0
            }
            if ($recordTimestamp.ToUniversalTime() -gt (Get-Date).ToUniversalTime().AddMinutes(5)) {
                $errors.Add('Service rollback record timestamp is unexpectedly in the future.')
            }
            elseif (
                $maxAgeDays -gt 0 -and
                $recordTimestamp.ToUniversalTime() -lt
                (Get-Date).ToUniversalTime().AddDays(-$maxAgeDays)
            ) {
                $errors.Add("Service rollback record is stale (older than $maxAgeDays days).")
            }
        }

        if (
            -not [string]::IsNullOrWhiteSpace($ExpectedToolId) -and
            [string](
                Get-BoostLabServicePropertyValue -InputObject $Record -Name 'ToolId'
            ) -ne $ExpectedToolId
        ) {
            $errors.Add('Service rollback record tool identity does not match the caller.')
        }
        if (
            -not [string]::IsNullOrWhiteSpace($ExpectedActionId) -and
            [string](
                Get-BoostLabServicePropertyValue -InputObject $Record -Name 'ActionId'
            ) -ne $ExpectedActionId
        ) {
            $errors.Add('Service rollback record action identity does not match the caller.')
        }
        if (
            [string](
                Get-BoostLabServicePropertyValue -InputObject $Record -Name 'IntendedMutation'
            ) -notin $script:BoostLabServiceMutations
        ) {
            $errors.Add('Service rollback record mutation type is unsupported.')
        }
    }

    return [pscustomobject]@{
        IsValid  = $errors.Count -eq 0
        Status   = if ($errors.Count -eq 0) { 'Valid' } else { 'Blocked' }
        Errors   = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function New-BoostLabServiceStateCapture {
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
        [string]$ServiceName,

        [Parameter(Mandatory)]
        [string]$IntendedMutation,

        [Parameter(Mandatory)]
        [scriptblock]$ServiceReader,

        [ValidateSet('Low', 'Medium', 'High')]
        [string]$RiskClassification = 'High',

        [AllowNull()]
        [System.Collections.IDictionary]$Policy,

        [string]$StateRoot = ''
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabServiceRollbackPolicy
    }
    if ([string]::IsNullOrWhiteSpace($StateRoot)) {
        $StateRoot = Get-BoostLabServiceRollbackStateRoot
    }

    $targetValidation = Test-BoostLabServiceCaptureTarget `
        -ToolId $ToolId `
        -ScopeId $ScopeId `
        -ServiceName $ServiceName `
        -IntendedMutation $IntendedMutation `
        -Policy $Policy
    if (-not $targetValidation.IsAllowed) {
        return [pscustomobject]@{
            Success     = $false
            Status      = 'Blocked'
            OperationId = ''
            RecordPath  = ''
            Record      = $null
            Message     = 'Service state capture was blocked by policy.'
            Errors      = @($targetValidation.Errors)
            Timestamp   = Get-Date
        }
    }

    try {
        $originalState = Get-BoostLabServiceSnapshot `
            -ServiceName $ServiceName `
            -ServiceReader $ServiceReader
        $scope = $targetValidation.Scope
        $rollbackEligible = [bool]$originalState.Exists -and
            $IntendedMutation -in @(
                'Start'
                'Stop'
                'Disable'
                'Enable'
                'SetStartupType'
            ) -and
            (
                [bool](
                    Get-BoostLabServicePropertyValue `
                        -InputObject $scope `
                        -Name 'RestoreStartupType'
                ) -or
                [bool](
                    Get-BoostLabServicePropertyValue `
                        -InputObject $scope `
                        -Name 'RestoreDelayedAutoStart'
                ) -or
                [bool](
                    Get-BoostLabServicePropertyValue `
                        -InputObject $scope `
                        -Name 'RestoreStatus'
                )
            )
        $record = New-BoostLabServiceRollbackRecordObject `
            -ToolId $ToolId `
            -ActionId $ActionId `
            -ScopeId $ScopeId `
            -ServiceName $ServiceName `
            -IntendedMutation $IntendedMutation `
            -OriginalState $originalState `
            -RollbackEligible:$rollbackEligible `
            -RiskClassification $RiskClassification
        $saved = Save-BoostLabServiceRollbackRecord `
            -Record $record `
            -StateRoot $StateRoot

        return [pscustomobject]@{
            Success     = $true
            Status      = 'Captured'
            OperationId = $record.OperationId
            RecordPath  = $saved.RecordPath
            Record      = $record
            Message     = 'Service state was captured before mutation.'
            Errors      = @()
            Timestamp   = Get-Date
        }
    }
    catch {
        return [pscustomobject]@{
            Success     = $false
            Status      = 'Failed'
            OperationId = ''
            RecordPath  = ''
            Record      = $null
            Message     = 'Service state capture failed before mutation.'
            Errors      = @($_.Exception.Message)
            Timestamp   = Get-Date
        }
    }
}

function Set-BoostLabServiceRollbackMutationState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$RecordPath,

        [Parameter(Mandatory)]
        [string]$StateRoot,

        [Parameter(Mandatory)]
        [object]$PostMutationState
    )

    $imported = Import-BoostLabServiceRollbackRecord `
        -RecordPath $RecordPath `
        -StateRoot $StateRoot
    if (-not $imported.IsValid) {
        return [pscustomobject]@{
            Success    = $false
            Status     = 'Blocked'
            RecordPath = $RecordPath
            Message    = 'Service post-mutation state was not recorded.'
            Errors     = @($imported.Errors)
            Timestamp  = Get-Date
        }
    }

    try {
        $serviceName = [string](
            Get-BoostLabServicePropertyValue `
                -InputObject $imported.Record `
                -Name 'ServiceName'
        )
        $normalizedState = ConvertTo-BoostLabServiceSnapshot `
            -RequestedServiceName $serviceName `
            -Snapshot $PostMutationState
        $record = ConvertTo-BoostLabServiceRecordTable -Record $imported.Record
        $record['MutationRecorded'] = $true
        $record['PostMutationState'] = $normalizedState
        $saved = Save-BoostLabServiceRollbackRecord `
            -Record $record `
            -StateRoot $StateRoot

        return [pscustomobject]@{
            Success    = $true
            Status     = 'Recorded'
            RecordPath = $saved.RecordPath
            Message    = 'Service post-mutation state was recorded for guarded rollback.'
            Errors     = @()
            Timestamp  = Get-Date
        }
    }
    catch {
        return [pscustomobject]@{
            Success    = $false
            Status     = 'Failed'
            RecordPath = $RecordPath
            Message    = 'Service post-mutation state could not be recorded.'
            Errors     = @($_.Exception.Message)
            Timestamp  = Get-Date
        }
    }
}

function ConvertTo-BoostLabServiceComparableJson {
    param(
        [AllowNull()]
        [object]$Value
    )

    return $Value | ConvertTo-Json -Compress -Depth 30
}

function Test-BoostLabServiceState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,

        [Parameter(Mandatory)]
        [object]$ExpectedState,

        [Parameter(Mandatory)]
        [scriptblock]$ServiceReader
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    $detectedState = $null
    try {
        $detectedState = Get-BoostLabServiceSnapshot `
            -ServiceName $ServiceName `
            -ServiceReader $ServiceReader
        $expected = ConvertTo-BoostLabServiceSnapshot `
            -RequestedServiceName $ServiceName `
            -Snapshot $ExpectedState

        $checkDefinitions = @(
            @{ Name = 'Existence'; Property = 'Exists'; Optional = $false }
            @{ Name = 'Service name'; Property = 'ServiceName'; Optional = $false }
            @{ Name = 'Display name'; Property = 'DisplayName'; Optional = $true }
            @{ Name = 'Status'; Property = 'Status'; Optional = $false }
            @{ Name = 'Startup type'; Property = 'StartupType'; Optional = $false }
            @{ Name = 'Delayed auto-start'; Property = 'DelayedAutoStart'; Optional = $true }
            @{ Name = 'Binary path'; Property = 'BinaryPath'; Optional = $true }
            @{ Name = 'Service account'; Property = 'ServiceAccount'; Optional = $true }
            @{ Name = 'Dependencies'; Property = 'Dependencies'; Optional = $true }
            @{ Name = 'Description'; Property = 'Description'; Optional = $true }
            @{ Name = 'Failure actions'; Property = 'FailureActions'; Optional = $true }
        )
        foreach ($definition in $checkDefinitions) {
            $propertyName = [string]$definition.Property
            $expectedValue = Get-BoostLabServicePropertyValue `
                -InputObject $expected `
                -Name $propertyName
            $actualValue = Get-BoostLabServicePropertyValue `
                -InputObject $detectedState `
                -Name $propertyName

            $expectedJson = ConvertTo-BoostLabServiceComparableJson -Value $expectedValue
            $actualJson = ConvertTo-BoostLabServiceComparableJson -Value $actualValue
            $status = 'Passed'
            $message = 'Detected value matches the expected captured value.'
            if (
                [bool]$definition.Optional -and
                $null -eq $actualValue -and
                $null -ne $expectedValue
            ) {
                $status = 'Warning'
                $message = 'The service property was not available for read-only verification.'
            }
            elseif ($expectedJson -ne $actualJson) {
                $status = 'Failed'
                $message = 'Detected value contradicts the expected captured value.'
            }

            $checks.Add([pscustomobject]@{
                Name     = [string]$definition.Name
                Expected = $expectedValue
                Actual   = $actualValue
                Status   = $status
                Message  = $message
            })
        }
    }
    catch {
        $errors.Add($_.Exception.Message)
    }

    $failedCount = @($checks | Where-Object { $_.Status -eq 'Failed' }).Count
    $warningCount = @($checks | Where-Object { $_.Status -eq 'Warning' }).Count
    $status = if ($errors.Count -gt 0 -or $failedCount -gt 0) {
        'Failed'
    }
    elseif ($warningCount -gt 0) {
        'Warning'
    }
    else {
        'Passed'
    }

    return [pscustomobject]@{
        Success       = $status -ne 'Failed'
        Status        = $status
        ServiceName   = $ServiceName
        ExpectedState = $ExpectedState
        DetectedState = $detectedState
        Checks        = $checks.ToArray()
        Message       = if ($status -eq 'Passed') {
            'Service state matches the expected state.'
        }
        elseif ($status -eq 'Warning') {
            'Service state matched, but one or more properties were unavailable.'
        }
        else {
            'Service state verification failed.'
        }
        Errors        = $errors.ToArray()
        Timestamp     = Get-Date
    }
}

Export-ModuleMember -Function @(
    'Get-BoostLabServiceRollbackPolicy'
    'Get-BoostLabServiceRollbackStateRoot'
    'Test-BoostLabServiceRollbackPolicy'
    'Test-BoostLabServiceCaptureTarget'
    'Test-BoostLabServiceRollbackRecord'
    'Save-BoostLabServiceRollbackRecord'
    'Import-BoostLabServiceRollbackRecord'
    'New-BoostLabServiceStateCapture'
    'Set-BoostLabServiceRollbackMutationState'
    'Test-BoostLabServiceState'
)
