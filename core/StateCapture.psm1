Set-StrictMode -Version Latest

$script:BoostLabRollbackSchemaVersion = '1.0'
$script:BoostLabRollbackPolicyPath = Join-Path `
    (Split-Path -Parent $PSScriptRoot) `
    'config\RollbackPolicy.psd1'

function Get-BoostLabCapturePropertyValue {
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

function Get-BoostLabRollbackPolicy {
    [CmdletBinding()]
    [OutputType([System.Collections.IDictionary])]
    param(
        [string]$PolicyPath = $script:BoostLabRollbackPolicyPath
    )

    if (-not (Test-Path -LiteralPath $PolicyPath -PathType Leaf)) {
        throw "Rollback policy was not found: $PolicyPath"
    }

    return Import-PowerShellDataFile -LiteralPath $PolicyPath
}

function Get-BoostLabRollbackStateRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ([string]::IsNullOrWhiteSpace($env:ProgramData)) {
        throw 'The ProgramData environment variable is not available.'
    }

    return Join-Path $env:ProgramData 'BoostLab\State\Rollback'
}

function Test-BoostLabRollbackPolicy {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabRollbackPolicy
    }

    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($field in @(
        'SchemaVersion'
        'FileScopes'
        'RegistryScopes'
        'DeniedRegistryPrefixes'
    )) {
        if (-not $Policy.Contains($field)) {
            $errors.Add("Rollback policy is missing field: $field")
        }
    }
    if (
        $Policy.Contains('SchemaVersion') -and
        [string]$Policy['SchemaVersion'] -ne $script:BoostLabRollbackSchemaVersion
    ) {
        $errors.Add("Rollback policy SchemaVersion must be $script:BoostLabRollbackSchemaVersion.")
    }

    $scopeIds = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $fileScopes = @(
        if ($Policy.Contains('FileScopes')) {
            @($Policy['FileScopes'])
        }
    )
    foreach ($scope in $fileScopes) {
        foreach ($field in @(
            'ScopeId'
            'ToolIds'
            'AllowedRoot'
            'AllowDirectories'
            'MaxFiles'
            'MaxBytes'
        )) {
            if ($null -eq (Get-BoostLabCapturePropertyValue -InputObject $scope -Name $field)) {
                $errors.Add("File scope is missing field: $field")
            }
        }
        $scopeId = [string](
            Get-BoostLabCapturePropertyValue -InputObject $scope -Name 'ScopeId'
        )
        if ([string]::IsNullOrWhiteSpace($scopeId)) {
            $errors.Add('File scope ScopeId cannot be empty.')
        }
        elseif (-not $scopeIds.Add($scopeId)) {
            $errors.Add("Rollback scope id is duplicated: $scopeId")
        }
        if (
            (Get-BoostLabCapturePropertyValue -InputObject $scope -Name 'AllowDirectories') -isnot [bool]
        ) {
            $errors.Add("File scope '$scopeId' AllowDirectories must be Boolean.")
        }
        foreach ($limitField in @('MaxFiles', 'MaxBytes')) {
            $limit = 0L
            $value = Get-BoostLabCapturePropertyValue -InputObject $scope -Name $limitField
            if (-not [long]::TryParse([string]$value, [ref]$limit) -or $limit -lt 0) {
                $errors.Add("File scope '$scopeId' $limitField must be a non-negative integer.")
            }
        }
    }

    $registryScopes = @(
        if ($Policy.Contains('RegistryScopes')) {
            @($Policy['RegistryScopes'])
        }
    )
    foreach ($scope in $registryScopes) {
        foreach ($field in @(
            'ScopeId'
            'ToolIds'
            'AllowedPath'
            'AllowedValueNames'
            'AllowKeyCapture'
            'AllowProtectedSystem'
        )) {
            if ($null -eq (Get-BoostLabCapturePropertyValue -InputObject $scope -Name $field)) {
                $errors.Add("Registry scope is missing field: $field")
            }
        }
        $scopeId = [string](
            Get-BoostLabCapturePropertyValue -InputObject $scope -Name 'ScopeId'
        )
        if ([string]::IsNullOrWhiteSpace($scopeId)) {
            $errors.Add('Registry scope ScopeId cannot be empty.')
        }
        elseif (-not $scopeIds.Add($scopeId)) {
            $errors.Add("Rollback scope id is duplicated: $scopeId")
        }
        foreach ($booleanField in @('AllowKeyCapture', 'AllowProtectedSystem')) {
            if (
                (Get-BoostLabCapturePropertyValue -InputObject $scope -Name $booleanField) -isnot [bool]
            ) {
                $errors.Add("Registry scope '$scopeId' $booleanField must be Boolean.")
            }
        }
    }

    return [pscustomobject]@{
        IsValid            = $errors.Count -eq 0
        FileScopeCount      = $fileScopes.Count
        RegistryScopeCount  = $registryScopes.Count
        Errors             = $errors.ToArray()
        Timestamp          = Get-Date
    }
}

function ConvertTo-BoostLabFullPath {
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

function Test-BoostLabPathWithinRoot {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Root
    )

    $fullPath = ConvertTo-BoostLabFullPath -Path $Path
    $fullRoot = ConvertTo-BoostLabFullPath -Path $Root
    if ($fullPath.Equals($fullRoot, [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    $rootPrefix = $fullRoot + [IO.Path]::DirectorySeparatorChar
    return $fullPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
}

function Get-BoostLabBroadFileRoots {
    $roots = [System.Collections.Generic.List[string]]::new()
    foreach ($path in @(
        [IO.Path]::GetPathRoot($env:SystemRoot)
        $env:SystemRoot
        $env:ProgramFiles
        ${env:ProgramFiles(x86)}
        $env:USERPROFILE
        (Join-Path $env:SystemRoot 'System32')
    )) {
        if (-not [string]::IsNullOrWhiteSpace([string]$path)) {
            try {
                $roots.Add((ConvertTo-BoostLabFullPath -Path ([string]$path)))
            }
            catch {
                # Environment values that cannot be normalized are omitted.
            }
        }
    }

    return @($roots | Select-Object -Unique)
}

function Test-BoostLabFileCaptureTarget {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ScopeId,

        [Parameter(Mandatory)]
        [string]$TargetPath,

        [ValidateSet('File', 'Directory')]
        [string]$ItemType = 'File',

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabRollbackPolicy
    }

    $errors = [System.Collections.Generic.List[string]]::new()
    $policyValidation = Test-BoostLabRollbackPolicy -Policy $Policy
    if (-not $policyValidation.IsValid) {
        $errors.AddRange([string[]]@($policyValidation.Errors))
    }
    $fullTarget = ''
    try {
        $fullTarget = ConvertTo-BoostLabFullPath -Path $TargetPath
    }
    catch {
        $errors.Add($_.Exception.Message)
    }

    $scope = @(
        if ($Policy.Contains('FileScopes')) {
            @($Policy['FileScopes'])
        }
    ) |
        Where-Object {
            [string](Get-BoostLabCapturePropertyValue -InputObject $_ -Name 'ScopeId') -eq $ScopeId
        } |
        Select-Object -First 1
    if ($null -eq $scope) {
        $errors.Add("File scope '$ScopeId' is not approved.")
    }

    $allowedRoot = if ($null -ne $scope) {
        [string](Get-BoostLabCapturePropertyValue -InputObject $scope -Name 'AllowedRoot')
    }
    else {
        ''
    }
    $fullAllowedRoot = ''
    if (-not [string]::IsNullOrWhiteSpace($allowedRoot)) {
        try {
            $fullAllowedRoot = ConvertTo-BoostLabFullPath -Path $allowedRoot
        }
        catch {
            $errors.Add("File scope AllowedRoot is invalid: $($_.Exception.Message)")
        }
    }
    elseif ($null -ne $scope) {
        $errors.Add('File scope must declare an explicit AllowedRoot.')
    }

    if ($null -ne $scope) {
        $toolIds = @(Get-BoostLabCapturePropertyValue -InputObject $scope -Name 'ToolIds')
        if ($ToolId -notin $toolIds) {
            $errors.Add("File scope '$ScopeId' is not approved for tool '$ToolId'.")
        }
        if (
            $ItemType -eq 'Directory' -and
            -not [bool](Get-BoostLabCapturePropertyValue -InputObject $scope -Name 'AllowDirectories')
        ) {
            $errors.Add("File scope '$ScopeId' does not allow directory capture.")
        }
    }

    $broadRoots = @(Get-BoostLabBroadFileRoots)
    if (
        -not [string]::IsNullOrWhiteSpace($fullTarget) -and
        $fullTarget -in $broadRoots
    ) {
        $errors.Add("Broad file target is denied: $fullTarget")
    }
    if (
        -not [string]::IsNullOrWhiteSpace($fullAllowedRoot) -and
        $fullAllowedRoot -in $broadRoots
    ) {
        $errors.Add("Broad file scope root is denied: $fullAllowedRoot")
    }
    if (
        -not [string]::IsNullOrWhiteSpace($fullTarget) -and
        -not [string]::IsNullOrWhiteSpace($fullAllowedRoot) -and
        -not (Test-BoostLabPathWithinRoot -Path $fullTarget -Root $fullAllowedRoot)
    ) {
        $errors.Add('Target path is outside the approved bounded file scope.')
    }

    return [pscustomobject]@{
        IsAllowed   = $errors.Count -eq 0
        Status      = if ($errors.Count -eq 0) { 'Allowed' } else { 'Blocked' }
        ToolId      = $ToolId
        ScopeId     = $ScopeId
        TargetPath  = $fullTarget
        AllowedRoot = $fullAllowedRoot
        ItemType    = $ItemType
        Scope       = $scope
        Errors      = $errors.ToArray()
        Timestamp   = Get-Date
    }
}

function ConvertTo-BoostLabRegistryPath {
    param(
        [Parameter(Mandatory)]
        [string]$RegistryPath
    )

    if ([string]::IsNullOrWhiteSpace($RegistryPath)) {
        throw 'A non-empty registry path is required.'
    }
    if ($RegistryPath.IndexOfAny([char[]]'*?[]') -ge 0) {
        throw 'Wildcard registry paths are not allowed.'
    }

    $normalized = $RegistryPath.Trim().TrimEnd('\')
    $normalized = $normalized -replace '^HKEY_CURRENT_USER\\', 'HKCU:\'
    $normalized = $normalized -replace '^HKEY_LOCAL_MACHINE\\', 'HKLM:\'
    $normalized = $normalized -replace '^Registry::HKEY_CURRENT_USER\\', 'HKCU:\'
    $normalized = $normalized -replace '^Registry::HKEY_LOCAL_MACHINE\\', 'HKLM:\'
    if ($normalized -notmatch '^HK(CU|LM):\\') {
        throw 'Only explicit HKCU or HKLM registry paths are supported.'
    }

    return $normalized
}

function Test-BoostLabRegistryCaptureTarget {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ScopeId,

        [Parameter(Mandatory)]
        [string]$RegistryPath,

        [ValidateSet('RegistryKey', 'RegistryValue')]
        [string]$ItemType = 'RegistryValue',

        [string]$ValueName = '',

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabRollbackPolicy
    }

    $errors = [System.Collections.Generic.List[string]]::new()
    $policyValidation = Test-BoostLabRollbackPolicy -Policy $Policy
    if (-not $policyValidation.IsValid) {
        $errors.AddRange([string[]]@($policyValidation.Errors))
    }
    $normalizedPath = ''
    try {
        $normalizedPath = ConvertTo-BoostLabRegistryPath -RegistryPath $RegistryPath
    }
    catch {
        $errors.Add($_.Exception.Message)
    }

    $scope = @(
        if ($Policy.Contains('RegistryScopes')) {
            @($Policy['RegistryScopes'])
        }
    ) |
        Where-Object {
            [string](Get-BoostLabCapturePropertyValue -InputObject $_ -Name 'ScopeId') -eq $ScopeId
        } |
        Select-Object -First 1
    if ($null -eq $scope) {
        $errors.Add("Registry scope '$ScopeId' is not approved.")
    }

    $allowedPath = ''
    if ($null -ne $scope) {
        $toolIds = @(Get-BoostLabCapturePropertyValue -InputObject $scope -Name 'ToolIds')
        if ($ToolId -notin $toolIds) {
            $errors.Add("Registry scope '$ScopeId' is not approved for tool '$ToolId'.")
        }
        try {
            $allowedPath = ConvertTo-BoostLabRegistryPath -RegistryPath (
                [string](Get-BoostLabCapturePropertyValue -InputObject $scope -Name 'AllowedPath')
            )
        }
        catch {
            $errors.Add("Registry scope AllowedPath is invalid: $($_.Exception.Message)")
        }
        if (
            $ItemType -eq 'RegistryKey' -and
            -not [bool](Get-BoostLabCapturePropertyValue -InputObject $scope -Name 'AllowKeyCapture')
        ) {
            $errors.Add("Registry scope '$ScopeId' does not allow key capture.")
        }
        if ($ItemType -eq 'RegistryValue') {
            if ([string]::IsNullOrWhiteSpace($ValueName)) {
                $errors.Add('Registry value capture requires an explicit ValueName.')
            }
            $allowedValueNames = @(
                Get-BoostLabCapturePropertyValue -InputObject $scope -Name 'AllowedValueNames'
            )
            if ($ValueName -notin $allowedValueNames) {
                $errors.Add("Registry value '$ValueName' is not approved by scope '$ScopeId'.")
            }
        }
    }

    if ($normalizedPath -in @('HKCU:', 'HKLM:')) {
        $errors.Add("Broad registry hive is denied: $normalizedPath")
    }
    if (
        -not [string]::IsNullOrWhiteSpace($normalizedPath) -and
        -not [string]::IsNullOrWhiteSpace($allowedPath) -and
        -not $normalizedPath.Equals($allowedPath, [StringComparison]::OrdinalIgnoreCase)
    ) {
        $errors.Add('Registry path does not exactly match the approved bounded scope.')
    }

    $deniedPrefixes = @(
        if ($Policy.Contains('DeniedRegistryPrefixes')) {
            @($Policy['DeniedRegistryPrefixes'])
        }
    )
    foreach ($prefix in $deniedPrefixes) {
        $normalizedPrefix = try {
            ConvertTo-BoostLabRegistryPath -RegistryPath ([string]$prefix)
        }
        catch {
            [string]$prefix
        }
        if (
            -not [string]::IsNullOrWhiteSpace($normalizedPath) -and
            (
                $normalizedPath.Equals($normalizedPrefix, [StringComparison]::OrdinalIgnoreCase) -or
                $normalizedPath.StartsWith(
                    $normalizedPrefix + '\',
                    [StringComparison]::OrdinalIgnoreCase
                )
            ) -and
            -not [bool](
                Get-BoostLabCapturePropertyValue `
                    -InputObject $scope `
                    -Name 'AllowProtectedSystem'
            )
        ) {
            $errors.Add("Protected registry area is denied: $normalizedPath")
        }
    }

    return [pscustomobject]@{
        IsAllowed    = $errors.Count -eq 0
        Status       = if ($errors.Count -eq 0) { 'Allowed' } else { 'Blocked' }
        ToolId       = $ToolId
        ScopeId      = $ScopeId
        RegistryPath = $normalizedPath
        ValueName    = $ValueName
        ItemType     = $ItemType
        Scope        = $scope
        Errors       = $errors.ToArray()
        Timestamp    = Get-Date
    }
}

function Get-BoostLabFileSnapshot {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [ValidateSet('File', 'Directory')]
        [string]$ItemType,

        [Parameter(Mandatory)]
        [object]$Scope
    )

    $exists = Test-Path -LiteralPath $Path
    if (-not $exists) {
        return [pscustomobject]@{
            Exists       = $false
            Hash         = ''
            Metadata     = $null
            Manifest     = @()
            FileCount    = 0
            TotalBytes   = 0L
            ReparsePoint = $false
        }
    }

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    $isDirectory = $item.PSIsContainer
    if (($ItemType -eq 'Directory') -ne $isDirectory) {
        throw "Target item type does not match requested type '$ItemType'."
    }
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'Reparse-point targets are not eligible for capture.'
    }

    if ($ItemType -eq 'File') {
        return [pscustomobject]@{
            Exists       = $true
            Hash         = (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash
            Metadata     = [ordered]@{
                Attributes      = [string]$item.Attributes
                CreationTimeUtc = $item.CreationTimeUtc
                LastWriteTimeUtc = $item.LastWriteTimeUtc
                Length          = [long]$item.Length
            }
            Manifest     = @()
            FileCount    = 1
            TotalBytes   = [long]$item.Length
            ReparsePoint = $false
        }
    }

    $entries = [System.Collections.Generic.List[object]]::new()
    $children = @(
        Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction Stop
    )
    foreach ($child in $children) {
        if (($child.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Directory capture contains a reparse point: $($child.FullName)"
        }
        if (-not $child.PSIsContainer) {
            $relativePath = $child.FullName.Substring($Path.Length).TrimStart('\', '/')
            $entries.Add([pscustomobject]@{
                RelativePath     = $relativePath
                Hash             = (Get-FileHash -LiteralPath $child.FullName -Algorithm SHA256).Hash
                Length           = [long]$child.Length
                Attributes       = [string]$child.Attributes
                CreationTimeUtc  = $child.CreationTimeUtc
                LastWriteTimeUtc = $child.LastWriteTimeUtc
            })
        }
    }

    $maxFiles = [int](Get-BoostLabCapturePropertyValue -InputObject $Scope -Name 'MaxFiles')
    $maxBytes = [long](Get-BoostLabCapturePropertyValue -InputObject $Scope -Name 'MaxBytes')
    $totalBytes = [long](($entries | Measure-Object -Property Length -Sum).Sum)
    if ($maxFiles -gt 0 -and $entries.Count -gt $maxFiles) {
        throw "Directory capture exceeds approved file count limit of $maxFiles."
    }
    if ($maxBytes -gt 0 -and $totalBytes -gt $maxBytes) {
        throw "Directory capture exceeds approved byte limit of $maxBytes."
    }

    $manifestText = @(
        $entries |
            Sort-Object RelativePath |
            ForEach-Object { '{0}|{1}|{2}' -f $_.RelativePath, $_.Hash, $_.Length }
    ) -join "`n"
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $manifestHash = [BitConverter]::ToString(
            $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($manifestText))
        ).Replace('-', '')
    }
    finally {
        $sha256.Dispose()
    }

    return [pscustomobject]@{
        Exists       = $true
        Hash         = $manifestHash
        Metadata     = [ordered]@{
            Attributes       = [string]$item.Attributes
            CreationTimeUtc  = $item.CreationTimeUtc
            LastWriteTimeUtc = $item.LastWriteTimeUtc
        }
        Manifest     = $entries.ToArray()
        FileCount    = $entries.Count
        TotalBytes   = $totalBytes
        ReparsePoint = $false
    }
}

function Copy-BoostLabBoundedDirectory {
    param(
        [Parameter(Mandatory)]
        [string]$Source,

        [Parameter(Mandatory)]
        [string]$Destination,

        [Parameter(Mandatory)]
        [object[]]$Manifest
    )

    [IO.Directory]::CreateDirectory($Destination) | Out-Null
    foreach ($entry in @($Manifest)) {
        $sourcePath = Join-Path $Source ([string]$entry.RelativePath)
        $destinationPath = Join-Path $Destination ([string]$entry.RelativePath)
        [IO.Directory]::CreateDirectory((Split-Path -Parent $destinationPath)) | Out-Null
        Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force -ErrorAction Stop
    }
}

function New-BoostLabRollbackRecordObject {
    param(
        [Parameter(Mandatory)]
        [string]$OperationId,

        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ActionId,

        [Parameter(Mandatory)]
        [string]$ScopeId,

        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [ValidateSet('File', 'Directory', 'RegistryKey', 'RegistryValue')]
        [string]$ItemType,

        [string]$ValueName = '',

        [Parameter(Mandatory)]
        [bool]$OriginalExists,

        [AllowNull()]
        [object]$OriginalMetadata,

        [string]$OriginalHash = '',

        [string]$BackupLocation = '',

        [string]$BackupHash = '',

        [Parameter(Mandatory)]
        [ValidateSet(
            'Create',
            'Overwrite',
            'Delete',
            'Rename',
            'RegistrySet',
            'RegistryDelete'
        )]
        [string]$IntendedMutation,

        [Parameter(Mandatory)]
        [bool]$RollbackEligible,

        [Parameter(Mandatory)]
        [string]$VerificationRequirement,

        [Parameter(Mandatory)]
        [ValidateSet('Low', 'Medium', 'High')]
        [string]$RiskClassification
    )

    return [ordered]@{
        OperationId            = $OperationId
        ToolId                 = $ToolId
        ActionId               = $ActionId
        Timestamp              = Get-Date
        SchemaVersion          = $script:BoostLabRollbackSchemaVersion
        BoostLabVersion        = 'Foundation-Phase36'
        ScopeId                = $ScopeId
        SourcePath             = $SourcePath
        RegistryPath           = if ($ItemType -like 'Registry*') { $SourcePath } else { '' }
        ValueName              = $ValueName
        ItemType               = $ItemType
        OriginalExists         = $OriginalExists
        OriginalMetadata       = $OriginalMetadata
        OriginalHash           = $OriginalHash
        BackupLocation         = $BackupLocation
        BackupHash             = $BackupHash
        IntendedMutation       = $IntendedMutation
        RollbackEligible       = $RollbackEligible
        VerificationRequirement = $VerificationRequirement
        RiskClassification     = $RiskClassification
        MutationRecorded       = $false
        PostMutationExists     = $null
        PostMutationHash       = ''
        PostMutationMetadata   = $null
        RollbackCompleted      = $false
    }
}

function Save-BoostLabRollbackRecord {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Record,

        [Parameter(Mandatory)]
        [string]$StateRoot
    )

    $operationId = [string]$Record['OperationId']
    if ($operationId -notmatch '^[A-Fa-f0-9-]{36}$') {
        throw 'Rollback record OperationId must be a GUID.'
    }

    $fullStateRoot = ConvertTo-BoostLabFullPath -Path $StateRoot
    $recordsRoot = Join-Path $fullStateRoot 'Records'
    [IO.Directory]::CreateDirectory($recordsRoot) | Out-Null
    $recordPath = Join-Path $recordsRoot "$operationId.json"
    $recordJson = $Record | ConvertTo-Json -Compress -Depth 30
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $recordHash = [BitConverter]::ToString(
            $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($recordJson))
        ).Replace('-', '')
    }
    finally {
        $sha256.Dispose()
    }

    $envelope = [ordered]@{
        SchemaVersion = $script:BoostLabRollbackSchemaVersion
        RecordSha256  = $recordHash
        RecordJson    = $recordJson
    }
    Set-Content `
        -LiteralPath $recordPath `
        -Value ($envelope | ConvertTo-Json -Depth 5) `
        -Encoding UTF8 `
        -ErrorAction Stop

    return [pscustomobject]@{
        Success      = $true
        RecordPath   = $recordPath
        RecordSha256 = $recordHash
        Timestamp    = Get-Date
    }
}

function Import-BoostLabRollbackRecord {
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
    $recordsRoot = Join-Path (ConvertTo-BoostLabFullPath -Path $StateRoot) 'Records'
    try {
        $fullRecordPath = ConvertTo-BoostLabFullPath -Path $RecordPath
    }
    catch {
        $errors.Add($_.Exception.Message)
    }
    if (
        -not [string]::IsNullOrWhiteSpace($fullRecordPath) -and
        -not (Test-BoostLabPathWithinRoot -Path $fullRecordPath -Root $recordsRoot)
    ) {
        $errors.Add('Rollback record is outside the BoostLab records directory.')
    }
    if (
        -not [string]::IsNullOrWhiteSpace($fullRecordPath) -and
        -not (Test-Path -LiteralPath $fullRecordPath -PathType Leaf)
    ) {
        $errors.Add('Rollback record file does not exist.')
    }

    $record = $null
    if ($errors.Count -eq 0) {
        try {
            $envelope = Get-Content -LiteralPath $fullRecordPath -Raw -ErrorAction Stop |
                ConvertFrom-Json -ErrorAction Stop
            if ([string]$envelope.SchemaVersion -ne $script:BoostLabRollbackSchemaVersion) {
                $errors.Add('Rollback record envelope schema is unsupported.')
            }
            $recordJson = [string]$envelope.RecordJson
            $sha256 = [Security.Cryptography.SHA256]::Create()
            try {
                $actualHash = [BitConverter]::ToString(
                    $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($recordJson))
                ).Replace('-', '')
            }
            finally {
                $sha256.Dispose()
            }
            if ($actualHash -ne [string]$envelope.RecordSha256) {
                $errors.Add('Rollback record integrity hash mismatch.')
            }
            else {
                $record = $recordJson | ConvertFrom-Json -ErrorAction Stop
                $recordOperationId = [string](
                    Get-BoostLabCapturePropertyValue `
                        -InputObject $record `
                        -Name 'OperationId'
                )
                $recordFileName = [IO.Path]::GetFileNameWithoutExtension($fullRecordPath)
                if (
                    -not $recordFileName.Equals(
                        $recordOperationId,
                        [StringComparison]::OrdinalIgnoreCase
                    )
                ) {
                    $errors.Add('Rollback record filename does not match its OperationId.')
                    $record = $null
                }
            }
        }
        catch {
            $errors.Add("Rollback record is corrupt: $($_.Exception.Message)")
        }
    }

    return [pscustomobject]@{
        IsValid    = $errors.Count -eq 0
        Status     = if ($errors.Count -eq 0) { 'Valid' } else { 'Blocked' }
        RecordPath = $fullRecordPath
        Record     = $record
        Errors     = $errors.ToArray()
        Timestamp  = Get-Date
    }
}

function Test-BoostLabRollbackRecord {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Record,

        [string]$ExpectedToolId = '',

        [string]$ExpectedActionId = ''
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($field in @(
        'OperationId'
        'ToolId'
        'ActionId'
        'Timestamp'
        'SchemaVersion'
        'BoostLabVersion'
        'ScopeId'
        'SourcePath'
        'ItemType'
        'OriginalExists'
        'OriginalMetadata'
        'OriginalHash'
        'BackupLocation'
        'BackupHash'
        'IntendedMutation'
        'RollbackEligible'
        'VerificationRequirement'
        'RiskClassification'
        'MutationRecorded'
        'PostMutationExists'
        'PostMutationHash'
        'RollbackCompleted'
    )) {
        if ($null -eq $Record.PSObject.Properties[$field]) {
            $errors.Add("Rollback record is missing field: $field")
        }
    }

    $toolId = [string](Get-BoostLabCapturePropertyValue -InputObject $Record -Name 'ToolId')
    $actionId = [string](Get-BoostLabCapturePropertyValue -InputObject $Record -Name 'ActionId')
    if (-not [string]::IsNullOrWhiteSpace($ExpectedToolId) -and $toolId -ne $ExpectedToolId) {
        $errors.Add("Rollback record ToolId '$toolId' does not match '$ExpectedToolId'.")
    }
    if (-not [string]::IsNullOrWhiteSpace($ExpectedActionId) -and $actionId -ne $ExpectedActionId) {
        $errors.Add("Rollback record ActionId '$actionId' does not match '$ExpectedActionId'.")
    }
    if (
        [string](Get-BoostLabCapturePropertyValue -InputObject $Record -Name 'SchemaVersion') -ne
        $script:BoostLabRollbackSchemaVersion
    ) {
        $errors.Add('Rollback record schema is unsupported.')
    }
    if (
        -not [bool](Get-BoostLabCapturePropertyValue -InputObject $Record -Name 'RollbackEligible')
    ) {
        $errors.Add('Rollback record is not eligible for restore.')
    }

    return [pscustomobject]@{
        IsValid   = $errors.Count -eq 0
        Errors    = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function New-BoostLabFileStateCapture {
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
        [string]$TargetPath,

        [ValidateSet('File', 'Directory')]
        [string]$ItemType = 'File',

        [Parameter(Mandatory)]
        [ValidateSet('Create', 'Overwrite', 'Delete', 'Rename')]
        [string]$IntendedMutation,

        [ValidateSet('Low', 'Medium', 'High')]
        [string]$RiskClassification = 'Medium',

        [string]$VerificationRequirement = 'Verify target state and backup hash.',

        [AllowNull()]
        [System.Collections.IDictionary]$Policy,

        [string]$StateRoot = (Get-BoostLabRollbackStateRoot)
    )

    $targetValidation = Test-BoostLabFileCaptureTarget `
        -ToolId $ToolId `
        -ScopeId $ScopeId `
        -TargetPath $TargetPath `
        -ItemType $ItemType `
        -Policy $Policy
    if (-not $targetValidation.IsAllowed) {
        return [pscustomobject]@{
            Success      = $false
            Status       = 'Blocked'
            OperationId  = ''
            RecordPath   = ''
            Record       = $null
            BackupCreated = $false
            Message      = 'File state capture was blocked by policy.'
            Errors       = @($targetValidation.Errors)
            Timestamp    = Get-Date
        }
    }

    $snapshot = $null
    try {
        $snapshot = Get-BoostLabFileSnapshot `
            -Path $targetValidation.TargetPath `
            -ItemType $ItemType `
            -Scope $targetValidation.Scope
    }
    catch {
        return [pscustomobject]@{
            Success      = $false
            Status       = 'Failed'
            OperationId  = ''
            RecordPath   = ''
            Record       = $null
            BackupCreated = $false
            Message      = 'File state inspection failed.'
            Errors       = @($_.Exception.Message)
            Timestamp    = Get-Date
        }
    }

    $operationId = [guid]::NewGuid().ToString()
    $fullStateRoot = ConvertTo-BoostLabFullPath -Path $StateRoot
    $backupRoot = Join-Path $fullStateRoot "Backups\$operationId"
    $backupPath = ''
    $backupHash = ''
    $backupCreated = $false
    try {
        if ($snapshot.Exists) {
            [IO.Directory]::CreateDirectory($backupRoot) | Out-Null
            $backupPath = if ($ItemType -eq 'File') {
                Join-Path $backupRoot ([IO.Path]::GetFileName($targetValidation.TargetPath))
            }
            else {
                Join-Path $backupRoot 'Directory'
            }
            if ($ItemType -eq 'File') {
                Copy-Item `
                    -LiteralPath $targetValidation.TargetPath `
                    -Destination $backupPath `
                    -Force `
                    -ErrorAction Stop
            }
            else {
                Copy-BoostLabBoundedDirectory `
                    -Source $targetValidation.TargetPath `
                    -Destination $backupPath `
                    -Manifest @($snapshot.Manifest)
            }
            $backupSnapshot = Get-BoostLabFileSnapshot `
                -Path $backupPath `
                -ItemType $ItemType `
                -Scope $targetValidation.Scope
            if ($backupSnapshot.Hash -ne $snapshot.Hash) {
                throw 'Backup hash does not match captured original state.'
            }
            $backupHash = $backupSnapshot.Hash
            $backupCreated = $true
        }

        $record = New-BoostLabRollbackRecordObject `
            -OperationId $operationId `
            -ToolId $ToolId `
            -ActionId $ActionId `
            -ScopeId $ScopeId `
            -SourcePath $targetValidation.TargetPath `
            -ItemType $ItemType `
            -OriginalExists ([bool]$snapshot.Exists) `
            -OriginalMetadata ([pscustomobject]@{
                ItemMetadata = $snapshot.Metadata
                Manifest     = @($snapshot.Manifest)
                FileCount    = $snapshot.FileCount
                TotalBytes   = $snapshot.TotalBytes
            }) `
            -OriginalHash $snapshot.Hash `
            -BackupLocation $backupPath `
            -BackupHash $backupHash `
            -IntendedMutation $IntendedMutation `
            -RollbackEligible $true `
            -VerificationRequirement $VerificationRequirement `
            -RiskClassification $RiskClassification
        $saved = Save-BoostLabRollbackRecord -Record $record -StateRoot $fullStateRoot

        return [pscustomobject]@{
            Success       = $true
            Status        = 'Captured'
            OperationId   = $operationId
            RecordPath    = $saved.RecordPath
            Record        = [pscustomobject]$record
            BackupCreated = $backupCreated
            Message       = if ($snapshot.Exists) {
                'File state and verified backup were captured.'
            }
            else {
                'File absence was captured before the planned creation.'
            }
            Errors        = @()
            Timestamp     = Get-Date
        }
    }
    catch {
        return [pscustomobject]@{
            Success       = $false
            Status        = 'Failed'
            OperationId   = $operationId
            RecordPath    = ''
            Record        = $null
            BackupCreated = $backupCreated
            Message       = 'File state capture failed before mutation.'
            Errors        = @($_.Exception.Message)
            Timestamp     = Get-Date
        }
    }
}

function Get-BoostLabRegistrySnapshot {
    param(
        [Parameter(Mandatory)]
        [string]$RegistryPath,

        [ValidateSet('RegistryKey', 'RegistryValue')]
        [string]$ItemType,

        [string]$ValueName,

        [AllowNull()]
        [scriptblock]$RegistryReader
    )

    if ($null -ne $RegistryReader) {
        return & $RegistryReader $RegistryPath $ItemType $ValueName
    }

    if (-not (Test-Path -LiteralPath $RegistryPath)) {
        return [pscustomobject]@{
            Exists  = $false
            Metadata = $null
        }
    }

    $key = Get-Item -LiteralPath $RegistryPath -ErrorAction Stop
    if ($ItemType -eq 'RegistryValue') {
        $valueExists = $ValueName -in @($key.GetValueNames())
        return [pscustomobject]@{
            Exists  = $valueExists
            Metadata = if ($valueExists) {
                [ordered]@{
                    ValueName = $ValueName
                    ValueType = [string]$key.GetValueKind($ValueName)
                    ValueData = $key.GetValue($ValueName, $null, 'DoNotExpandEnvironmentNames')
                }
            }
            else {
                $null
            }
        }
    }

    $values = foreach ($name in @($key.GetValueNames())) {
        [ordered]@{
            ValueName = $name
            ValueType = [string]$key.GetValueKind($name)
            ValueData = $key.GetValue($name, $null, 'DoNotExpandEnvironmentNames')
        }
    }
    return [pscustomobject]@{
        Exists  = $true
        Metadata = [ordered]@{
            Values = @($values)
        }
    }
}

function New-BoostLabRegistryStateCapture {
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
        [string]$RegistryPath,

        [ValidateSet('RegistryKey', 'RegistryValue')]
        [string]$ItemType = 'RegistryValue',

        [string]$ValueName = '',

        [Parameter(Mandatory)]
        [ValidateSet('RegistrySet', 'RegistryDelete')]
        [string]$IntendedMutation,

        [ValidateSet('Low', 'Medium', 'High')]
        [string]$RiskClassification = 'Medium',

        [string]$VerificationRequirement = 'Verify exact registry value type and data.',

        [AllowNull()]
        [System.Collections.IDictionary]$Policy,

        [AllowNull()]
        [scriptblock]$RegistryReader,

        [string]$StateRoot = (Get-BoostLabRollbackStateRoot)
    )

    $targetValidation = Test-BoostLabRegistryCaptureTarget `
        -ToolId $ToolId `
        -ScopeId $ScopeId `
        -RegistryPath $RegistryPath `
        -ItemType $ItemType `
        -ValueName $ValueName `
        -Policy $Policy
    if (-not $targetValidation.IsAllowed) {
        return [pscustomobject]@{
            Success     = $false
            Status      = 'Blocked'
            OperationId = ''
            RecordPath  = ''
            Record      = $null
            Message     = 'Registry state capture was blocked by policy.'
            Errors      = @($targetValidation.Errors)
            Timestamp   = Get-Date
        }
    }

    try {
        $snapshot = Get-BoostLabRegistrySnapshot `
            -RegistryPath $targetValidation.RegistryPath `
            -ItemType $ItemType `
            -ValueName $ValueName `
            -RegistryReader $RegistryReader
        if ($null -eq $snapshot -or $null -eq $snapshot.PSObject.Properties['Exists']) {
            throw 'Registry reader returned an invalid snapshot.'
        }

        $operationId = [guid]::NewGuid().ToString()
        $record = New-BoostLabRollbackRecordObject `
            -OperationId $operationId `
            -ToolId $ToolId `
            -ActionId $ActionId `
            -ScopeId $ScopeId `
            -SourcePath $targetValidation.RegistryPath `
            -ItemType $ItemType `
            -ValueName $ValueName `
            -OriginalExists ([bool]$snapshot.Exists) `
            -OriginalMetadata $snapshot.Metadata `
            -IntendedMutation $IntendedMutation `
            -RollbackEligible $true `
            -VerificationRequirement $VerificationRequirement `
            -RiskClassification $RiskClassification
        $saved = Save-BoostLabRollbackRecord -Record $record -StateRoot $StateRoot

        return [pscustomobject]@{
            Success     = $true
            Status      = 'Captured'
            OperationId = $operationId
            RecordPath  = $saved.RecordPath
            Record      = [pscustomobject]$record
            Message     = if ([bool]$snapshot.Exists) {
                'Registry state was captured.'
            }
            else {
                'Registry absence was captured.'
            }
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
            Message     = 'Registry state capture failed before mutation.'
            Errors      = @($_.Exception.Message)
            Timestamp   = Get-Date
        }
    }
}

function Set-BoostLabRollbackMutationState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$RecordPath,

        [Parameter(Mandatory)]
        [string]$StateRoot,

        [Parameter(Mandatory)]
        [bool]$PostMutationExists,

        [string]$PostMutationHash = '',

        [AllowNull()]
        [object]$PostMutationMetadata
    )

    $imported = Import-BoostLabRollbackRecord -RecordPath $RecordPath -StateRoot $StateRoot
    if (-not $imported.IsValid) {
        return [pscustomobject]@{
            Success    = $false
            Status     = 'Blocked'
            RecordPath = $RecordPath
            Message    = 'Rollback mutation state was not recorded.'
            Errors     = @($imported.Errors)
            Timestamp  = Get-Date
        }
    }

    $record = [ordered]@{}
    foreach ($property in $imported.Record.PSObject.Properties) {
        $record[$property.Name] = $property.Value
    }
    $record['MutationRecorded'] = $true
    $record['PostMutationExists'] = $PostMutationExists
    $record['PostMutationHash'] = $PostMutationHash
    $record['PostMutationMetadata'] = $PostMutationMetadata
    $saved = Save-BoostLabRollbackRecord -Record $record -StateRoot $StateRoot

    return [pscustomobject]@{
        Success    = $true
        Status     = 'Recorded'
        RecordPath = $saved.RecordPath
        Message    = 'Post-mutation state was recorded for guarded rollback.'
        Errors     = @()
        Timestamp  = Get-Date
    }
}

Export-ModuleMember -Function @(
    'Get-BoostLabRollbackPolicy'
    'Get-BoostLabRollbackStateRoot'
    'Test-BoostLabRollbackPolicy'
    'Test-BoostLabFileCaptureTarget'
    'Test-BoostLabRegistryCaptureTarget'
    'Test-BoostLabRollbackRecord'
    'Save-BoostLabRollbackRecord'
    'Import-BoostLabRollbackRecord'
    'New-BoostLabFileStateCapture'
    'New-BoostLabRegistryStateCapture'
    'Set-BoostLabRollbackMutationState'
)
