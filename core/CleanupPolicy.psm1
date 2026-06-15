Set-StrictMode -Version Latest

$script:BoostLabCleanupSchemaVersion = '1.0'
$script:BoostLabCleanupPolicyPath = Join-Path `
    (Split-Path -Parent $PSScriptRoot) `
    'config\CleanupPolicy.psd1'
$script:BoostLabCleanupTypes = @(
    'Delete'
    'Quarantine'
    'EmptyDirectory'
    'RemoveGeneratedArtifact'
)
$script:BoostLabCleanupTargetTypes = @('File', 'Directory')

function Get-BoostLabCleanupPropertyValue {
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

function ConvertTo-BoostLabCleanupArray {
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

function Get-BoostLabCleanupPolicy {
    [CmdletBinding()]
    [OutputType([System.Collections.IDictionary])]
    param(
        [string]$PolicyPath = $script:BoostLabCleanupPolicyPath
    )

    if (-not (Test-Path -LiteralPath $PolicyPath -PathType Leaf)) {
        throw "Cleanup policy was not found: $PolicyPath"
    }

    return Import-PowerShellDataFile -LiteralPath $PolicyPath
}

function Get-BoostLabCleanupStateRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ([string]::IsNullOrWhiteSpace($env:ProgramData)) {
        throw 'The ProgramData environment variable is not available.'
    }

    return Join-Path $env:ProgramData 'BoostLab\State\Cleanup'
}

function ConvertTo-BoostLabCleanupFullPath {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'A non-empty cleanup path is required.'
    }
    if ($Path.IndexOfAny([char[]]'*?[]') -ge 0) {
        throw 'Wildcard cleanup paths are not allowed.'
    }
    if ($Path -match '(?i)\$(\{)?env:' -or $Path -match '%[^%]+%') {
        $expanded = [Environment]::ExpandEnvironmentVariables($Path)
        if (
            $expanded -eq $Path -or
            $expanded -match '(?i)\$(\{)?env:' -or
            $expanded -match '%[^%]+%'
        ) {
            throw 'Unresolved environment-variable cleanup paths are not allowed.'
        }
        $Path = $expanded
    }

    $segments = @(
        $Path -split '[\\/]' |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
    if ('..' -in $segments) {
        throw 'Path traversal is not allowed in cleanup targets.'
    }
    if (-not [IO.Path]::IsPathRooted($Path)) {
        throw 'Cleanup targets must use an absolute path.'
    }

    return [IO.Path]::GetFullPath($Path).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
}

function Test-BoostLabCleanupPathWithinRoot {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Root
    )

    $fullPath = ConvertTo-BoostLabCleanupFullPath -Path $Path
    $fullRoot = ConvertTo-BoostLabCleanupFullPath -Path $Root
    if ($fullPath.Equals($fullRoot, [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    return $fullPath.StartsWith(
        $fullRoot + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase
    )
}

function Get-BoostLabCleanupBroadRoots {
    $roots = [System.Collections.Generic.List[string]]::new()
    foreach ($path in @(
        [IO.Path]::GetPathRoot($env:SystemRoot)
        $env:SystemRoot
        (Join-Path $env:SystemRoot 'System32')
        $env:ProgramFiles
        ${env:ProgramFiles(x86)}
        $env:ProgramData
        $env:USERPROFILE
        [Environment]::GetFolderPath('Desktop')
        [Environment]::GetFolderPath('MyDocuments')
        (Join-Path $env:USERPROFILE 'Downloads')
        $env:APPDATA
        $env:LOCALAPPDATA
        [IO.Path]::GetTempPath()
        $env:TEMP
        $env:TMP
    )) {
        if (-not [string]::IsNullOrWhiteSpace([string]$path)) {
            try {
                $roots.Add((ConvertTo-BoostLabCleanupFullPath -Path ([string]$path)))
            }
            catch {
                # Invalid environment values are ignored.
            }
        }
    }

    return @($roots | Select-Object -Unique)
}

function Get-BoostLabCleanupUserDocumentRoots {
    $roots = [System.Collections.Generic.List[string]]::new()
    foreach ($path in @(
        [Environment]::GetFolderPath('Desktop')
        [Environment]::GetFolderPath('MyDocuments')
        (Join-Path $env:USERPROFILE 'Downloads')
    )) {
        if (-not [string]::IsNullOrWhiteSpace([string]$path)) {
            try {
                $roots.Add((ConvertTo-BoostLabCleanupFullPath -Path ([string]$path)))
            }
            catch {
                # Invalid environment values are ignored.
            }
        }
    }

    return @($roots | Select-Object -Unique)
}

function Test-BoostLabCleanupPolicy {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabCleanupPolicy
    }

    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($field in @('SchemaVersion', 'MaxRecordAgeDays', 'CleanupScopes')) {
        if (-not $Policy.Contains($field)) {
            $errors.Add("Cleanup policy is missing field: $field")
        }
    }
    if (
        $Policy.Contains('SchemaVersion') -and
        [string]$Policy['SchemaVersion'] -ne $script:BoostLabCleanupSchemaVersion
    ) {
        $errors.Add(
            "Cleanup policy SchemaVersion must be $script:BoostLabCleanupSchemaVersion."
        )
    }

    $maxRecordAgeDays = 0
    if (
        $Policy.Contains('MaxRecordAgeDays') -and
        (
            -not [int]::TryParse(
                [string]$Policy['MaxRecordAgeDays'],
                [ref]$maxRecordAgeDays
            ) -or
            $maxRecordAgeDays -le 0
        )
    ) {
        $errors.Add('Cleanup policy MaxRecordAgeDays must be a positive integer.')
    }

    $scopeIds = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $scopes = @(
        if ($Policy.Contains('CleanupScopes')) {
            @($Policy['CleanupScopes'])
        }
    )
    foreach ($scope in $scopes) {
        foreach ($field in @(
            'ScopeId'
            'ToolIds'
            'AllowedRoot'
            'AllowedTargets'
            'AllowedTargetTypes'
            'AllowedCleanupTypes'
            'AllowRecursive'
            'MaxFiles'
            'MaxBytes'
            'AllowReparsePoints'
            'AllowUserDocuments'
            'RequireStateCapture'
            'AllowPermanentDelete'
            'AllowQuarantine'
        )) {
            if ($null -eq (Get-BoostLabCleanupPropertyValue -InputObject $scope -Name $field)) {
                $errors.Add("Cleanup scope is missing field: $field")
            }
        }

        $scopeId = [string](
            Get-BoostLabCleanupPropertyValue -InputObject $scope -Name 'ScopeId'
        )
        if ([string]::IsNullOrWhiteSpace($scopeId)) {
            $errors.Add('Cleanup scope ScopeId cannot be empty.')
        }
        elseif (-not $scopeIds.Add($scopeId)) {
            $errors.Add("Cleanup scope id is duplicated: $scopeId")
        }

        $toolIds = @(
            ConvertTo-BoostLabCleanupArray -Value (
                Get-BoostLabCleanupPropertyValue -InputObject $scope -Name 'ToolIds'
            )
        )
        if ($toolIds.Count -eq 0) {
            $errors.Add("Cleanup scope '$scopeId' must declare exact tool ids.")
        }
        foreach ($toolId in $toolIds) {
            if ($toolId.IndexOfAny([char[]]'*?[]') -ge 0) {
                $errors.Add("Cleanup scope '$scopeId' contains a wildcard tool id.")
            }
        }

        $allowedRoot = ''
        try {
            $allowedRoot = ConvertTo-BoostLabCleanupFullPath -Path (
                [string](
                    Get-BoostLabCleanupPropertyValue `
                        -InputObject $scope `
                        -Name 'AllowedRoot'
                )
            )
        }
        catch {
            $errors.Add("Cleanup scope '$scopeId' AllowedRoot is invalid: $($_.Exception.Message)")
        }
        if (
            -not [string]::IsNullOrWhiteSpace($allowedRoot) -and
            $allowedRoot -in @(Get-BoostLabCleanupBroadRoots)
        ) {
            $errors.Add("Cleanup scope '$scopeId' uses a denied broad root: $allowedRoot")
        }

        $allowedTargets = @(
            ConvertTo-BoostLabCleanupArray -Value (
                Get-BoostLabCleanupPropertyValue -InputObject $scope -Name 'AllowedTargets'
            )
        )
        if ($allowedTargets.Count -eq 0) {
            $errors.Add("Cleanup scope '$scopeId' must declare exact target paths.")
        }
        foreach ($target in $allowedTargets) {
            try {
                $fullTarget = ConvertTo-BoostLabCleanupFullPath -Path $target
                if (
                    -not [string]::IsNullOrWhiteSpace($allowedRoot) -and
                    -not (Test-BoostLabCleanupPathWithinRoot `
                        -Path $fullTarget `
                        -Root $allowedRoot)
                ) {
                    $errors.Add(
                        "Cleanup scope '$scopeId' target is outside AllowedRoot: $fullTarget"
                    )
                }
                if ($fullTarget -in @(Get-BoostLabCleanupBroadRoots)) {
                    $errors.Add(
                        "Cleanup scope '$scopeId' target is a denied broad root: $fullTarget"
                    )
                }
            }
            catch {
                $errors.Add(
                    "Cleanup scope '$scopeId' target is invalid: $($_.Exception.Message)"
                )
            }
        }

        $allowedTargetTypes = @(
            ConvertTo-BoostLabCleanupArray -Value (
                Get-BoostLabCleanupPropertyValue `
                    -InputObject $scope `
                    -Name 'AllowedTargetTypes'
            )
        )
        foreach ($targetType in $allowedTargetTypes) {
            if ($targetType -notin $script:BoostLabCleanupTargetTypes) {
                $errors.Add(
                    "Cleanup scope '$scopeId' has unsupported target type: $targetType"
                )
            }
        }
        if ($allowedTargetTypes.Count -eq 0) {
            $errors.Add("Cleanup scope '$scopeId' must declare target types.")
        }

        $allowedCleanupTypes = @(
            ConvertTo-BoostLabCleanupArray -Value (
                Get-BoostLabCleanupPropertyValue `
                    -InputObject $scope `
                    -Name 'AllowedCleanupTypes'
            )
        )
        foreach ($cleanupType in $allowedCleanupTypes) {
            if ($cleanupType -notin $script:BoostLabCleanupTypes) {
                $errors.Add(
                    "Cleanup scope '$scopeId' has unsupported cleanup type: $cleanupType"
                )
            }
        }
        if ($allowedCleanupTypes.Count -eq 0) {
            $errors.Add("Cleanup scope '$scopeId' must declare cleanup types.")
        }

        foreach ($booleanField in @(
            'AllowRecursive'
            'AllowReparsePoints'
            'AllowUserDocuments'
            'RequireStateCapture'
            'AllowPermanentDelete'
            'AllowQuarantine'
        )) {
            if (
                (Get-BoostLabCleanupPropertyValue `
                    -InputObject $scope `
                    -Name $booleanField) -isnot [bool]
            ) {
                $errors.Add("Cleanup scope '$scopeId' $booleanField must be Boolean.")
            }
        }
        foreach ($limitField in @('MaxFiles', 'MaxBytes')) {
            $limit = 0L
            $value = Get-BoostLabCleanupPropertyValue `
                -InputObject $scope `
                -Name $limitField
            if (-not [long]::TryParse([string]$value, [ref]$limit) -or $limit -lt 0) {
                $errors.Add(
                    "Cleanup scope '$scopeId' $limitField must be a non-negative integer."
                )
            }
        }
        if (
            [bool](
                Get-BoostLabCleanupPropertyValue `
                    -InputObject $scope `
                    -Name 'AllowRecursive'
            ) -and
            (
                [long](
                    Get-BoostLabCleanupPropertyValue `
                        -InputObject $scope `
                        -Name 'MaxFiles'
                ) -le 0 -or
                [long](
                    Get-BoostLabCleanupPropertyValue `
                        -InputObject $scope `
                        -Name 'MaxBytes'
                ) -le 0
            )
        ) {
            $errors.Add(
                "Recursive cleanup scope '$scopeId' requires positive MaxFiles and MaxBytes."
            )
        }
    }

    return [pscustomobject]@{
        IsValid           = $errors.Count -eq 0
        CleanupScopeCount = $scopes.Count
        Errors            = $errors.ToArray()
        Timestamp         = Get-Date
    }
}

function Get-BoostLabCleanupSnapshot {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$TargetType
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{
            Exists               = $false
            TargetType           = $TargetType
            ResolvedPath         = $Path
            IsReparsePoint       = $false
            ContainsReparsePoint = $false
            FileCount            = 0
            TotalBytes           = 0L
            Hash                 = ''
            Metadata             = $null
        }
    }

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    $actualType = if ($item.PSIsContainer) { 'Directory' } else { 'File' }
    if ($actualType -ne $TargetType) {
        throw "Cleanup target type is '$actualType', not '$TargetType'."
    }
    $isReparsePoint = (
        ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
    )
    if ($TargetType -eq 'File') {
        return [pscustomobject]@{
            Exists               = $true
            TargetType           = 'File'
            ResolvedPath         = $item.FullName
            IsReparsePoint       = $isReparsePoint
            ContainsReparsePoint = $isReparsePoint
            FileCount            = 1
            TotalBytes           = [long]$item.Length
            Hash                 = (
                Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256
            ).Hash
            Metadata             = [ordered]@{
                Attributes       = [string]$item.Attributes
                CreationTimeUtc  = $item.CreationTimeUtc
                LastWriteTimeUtc = $item.LastWriteTimeUtc
                Length           = [long]$item.Length
            }
        }
    }

    $entries = [System.Collections.Generic.List[object]]::new()
    $directories = [System.Collections.Generic.Stack[string]]::new()
    $directories.Push($item.FullName)
    $containsReparsePoint = $isReparsePoint
    while ($directories.Count -gt 0 -and -not $containsReparsePoint) {
        $currentDirectory = $directories.Pop()
        foreach ($child in @(
            Get-ChildItem -LiteralPath $currentDirectory -Force -ErrorAction Stop
        )) {
            $childIsReparsePoint = (
                ($child.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
            )
            if ($childIsReparsePoint) {
                $containsReparsePoint = $true
                break
            }
            if ($child.PSIsContainer) {
                $directories.Push($child.FullName)
            }
            else {
                $relativePath = $child.FullName.Substring(
                    $item.FullName.Length
                ).TrimStart('\', '/')
                $entries.Add([pscustomobject]@{
                    RelativePath = $relativePath
                    Length       = [long]$child.Length
                    Hash         = (
                        Get-FileHash `
                            -LiteralPath $child.FullName `
                            -Algorithm SHA256
                    ).Hash
                })
            }
        }
    }

    $manifestText = @(
        $entries |
            Sort-Object RelativePath |
            ForEach-Object {
                '{0}|{1}|{2}' -f $_.RelativePath, $_.Length, $_.Hash
            }
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
        Exists               = $true
        TargetType           = 'Directory'
        ResolvedPath         = $item.FullName
        IsReparsePoint       = $isReparsePoint
        ContainsReparsePoint = $containsReparsePoint
        FileCount            = $entries.Count
        TotalBytes           = [long](($entries | Measure-Object Length -Sum).Sum)
        Hash                 = $manifestHash
        Metadata             = [ordered]@{
            Attributes       = [string]$item.Attributes
            CreationTimeUtc  = $item.CreationTimeUtc
            LastWriteTimeUtc = $item.LastWriteTimeUtc
            Manifest         = $entries.ToArray()
        }
    }
}

function Test-BoostLabCleanupTarget {
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
        [string]$TargetType,

        [ValidateSet(
            'Delete',
            'Quarantine',
            'EmptyDirectory',
            'RemoveGeneratedArtifact'
        )]
        [string]$CleanupType,

        [bool]$Recursive = $false,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy,

        [AllowNull()]
        [scriptblock]$PathInspector
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabCleanupPolicy
    }

    $errors = [System.Collections.Generic.List[string]]::new()
    $policyValidation = Test-BoostLabCleanupPolicy -Policy $Policy
    if (-not $policyValidation.IsValid) {
        $errors.AddRange([string[]]@($policyValidation.Errors))
    }

    $normalizedPath = ''
    try {
        $normalizedPath = ConvertTo-BoostLabCleanupFullPath -Path $TargetPath
    }
    catch {
        $errors.Add($_.Exception.Message)
    }

    $scope = @(
        if ($Policy.Contains('CleanupScopes')) {
            @($Policy['CleanupScopes'])
        }
    ) |
        Where-Object {
            [string](Get-BoostLabCleanupPropertyValue -InputObject $_ -Name 'ScopeId') -eq
                $ScopeId
        } |
        Select-Object -First 1
    if ($null -eq $scope) {
        $errors.Add("Cleanup scope '$ScopeId' is not approved.")
    }

    $allowedRoot = ''
    $allowedTargets = @()
    if ($null -ne $scope) {
        $toolIds = @(
            ConvertTo-BoostLabCleanupArray -Value (
                Get-BoostLabCleanupPropertyValue -InputObject $scope -Name 'ToolIds'
            )
        )
        if ($ToolId -notin $toolIds) {
            $errors.Add("Cleanup scope '$ScopeId' is not approved for tool '$ToolId'.")
        }

        try {
            $allowedRoot = ConvertTo-BoostLabCleanupFullPath -Path (
                [string](
                    Get-BoostLabCleanupPropertyValue `
                        -InputObject $scope `
                        -Name 'AllowedRoot'
                )
            )
        }
        catch {
            $errors.Add("Cleanup scope AllowedRoot is invalid: $($_.Exception.Message)")
        }
        $allowedTargets = @(
            ConvertTo-BoostLabCleanupArray -Value (
                Get-BoostLabCleanupPropertyValue `
                    -InputObject $scope `
                    -Name 'AllowedTargets'
            ) |
                ForEach-Object {
                    try {
                        ConvertTo-BoostLabCleanupFullPath -Path $_
                    }
                    catch {
                        ''
                    }
                } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )
        if ($normalizedPath -notin $allowedTargets) {
            $errors.Add(
                'Cleanup target does not exactly match an approved target path.'
            )
        }
        if (
            -not [string]::IsNullOrWhiteSpace($normalizedPath) -and
            -not [string]::IsNullOrWhiteSpace($allowedRoot) -and
            -not (Test-BoostLabCleanupPathWithinRoot `
                -Path $normalizedPath `
                -Root $allowedRoot)
        ) {
            $errors.Add('Cleanup target is outside the approved bounded scope.')
        }

        $allowedTargetTypes = @(
            ConvertTo-BoostLabCleanupArray -Value (
                Get-BoostLabCleanupPropertyValue `
                    -InputObject $scope `
                    -Name 'AllowedTargetTypes'
            )
        )
        if ($TargetType -notin $allowedTargetTypes) {
            $errors.Add("Target type '$TargetType' is not approved by scope '$ScopeId'.")
        }
        $allowedCleanupTypes = @(
            ConvertTo-BoostLabCleanupArray -Value (
                Get-BoostLabCleanupPropertyValue `
                    -InputObject $scope `
                    -Name 'AllowedCleanupTypes'
            )
        )
        if ($CleanupType -notin $allowedCleanupTypes) {
            $errors.Add("Cleanup type '$CleanupType' is not approved by scope '$ScopeId'.")
        }
        if (
            $CleanupType -eq 'Delete' -and
            -not [bool](
                Get-BoostLabCleanupPropertyValue `
                    -InputObject $scope `
                    -Name 'AllowPermanentDelete'
            )
        ) {
            $errors.Add("Permanent deletion is not approved by scope '$ScopeId'.")
        }
        if (
            $CleanupType -eq 'Quarantine' -and
            -not [bool](
                Get-BoostLabCleanupPropertyValue `
                    -InputObject $scope `
                    -Name 'AllowQuarantine'
            )
        ) {
            $errors.Add("Quarantine is not approved by scope '$ScopeId'.")
        }
        if (
            $Recursive -and
            -not [bool](
                Get-BoostLabCleanupPropertyValue `
                    -InputObject $scope `
                    -Name 'AllowRecursive'
            )
        ) {
            $errors.Add("Recursive cleanup is not approved by scope '$ScopeId'.")
        }
        if (
            $TargetType -eq 'Directory' -and
            $CleanupType -in @(
                'Delete',
                'Quarantine',
                'EmptyDirectory',
                'RemoveGeneratedArtifact'
            ) -and
            -not $Recursive
        ) {
            $errors.Add('Directory cleanup requires an explicit recursive request.')
        }
    }

    $broadRoots = @(Get-BoostLabCleanupBroadRoots)
    if (
        -not [string]::IsNullOrWhiteSpace($normalizedPath) -and
        $normalizedPath -in $broadRoots
    ) {
        $errors.Add("Broad cleanup root is denied: $normalizedPath")
    }
    if (
        -not [string]::IsNullOrWhiteSpace($allowedRoot) -and
        $allowedRoot -in $broadRoots
    ) {
        $errors.Add("Broad cleanup scope root is denied: $allowedRoot")
    }

    if ($null -ne $scope -and -not [string]::IsNullOrWhiteSpace($normalizedPath)) {
        $allowUserDocuments = [bool](
            Get-BoostLabCleanupPropertyValue `
                -InputObject $scope `
                -Name 'AllowUserDocuments'
        )
        foreach ($documentRoot in @(Get-BoostLabCleanupUserDocumentRoots)) {
            if (
                (Test-BoostLabCleanupPathWithinRoot `
                    -Path $normalizedPath `
                    -Root $documentRoot) -and
                -not $allowUserDocuments
            ) {
                $errors.Add(
                    'Cleanup of user Desktop, Documents, or Downloads content is not approved.'
                )
            }
        }
    }

    $snapshot = $null
    if ($errors.Count -eq 0) {
        try {
            $snapshot = if ($null -ne $PathInspector) {
                & $PathInspector $normalizedPath $TargetType
            }
            else {
                Get-BoostLabCleanupSnapshot `
                    -Path $normalizedPath `
                    -TargetType $TargetType
            }
            if (
                $null -eq $snapshot -or
                $null -eq $snapshot.PSObject.Properties['Exists'] -or
                $null -eq $snapshot.PSObject.Properties['TargetType'] -or
                $null -eq $snapshot.PSObject.Properties['ResolvedPath']
            ) {
                throw 'Cleanup path inspector returned an invalid snapshot.'
            }

            $resolvedPath = ConvertTo-BoostLabCleanupFullPath -Path (
                [string]$snapshot.ResolvedPath
            )
            if (-not $resolvedPath.Equals(
                $normalizedPath,
                [StringComparison]::OrdinalIgnoreCase
            )) {
                $errors.Add(
                    'Resolved cleanup path does not match the approved target path.'
                )
            }
            if (
                -not (Test-BoostLabCleanupPathWithinRoot `
                    -Path $resolvedPath `
                    -Root $allowedRoot)
            ) {
                $errors.Add(
                    'Resolved cleanup path is outside the approved bounded scope.'
                )
            }
            if ([string]$snapshot.TargetType -ne $TargetType) {
                $errors.Add('Detected cleanup target type does not match the plan.')
            }

            $allowReparsePoints = [bool](
                Get-BoostLabCleanupPropertyValue `
                    -InputObject $scope `
                    -Name 'AllowReparsePoints'
            )
            if (
                (
                    [bool](
                        Get-BoostLabCleanupPropertyValue `
                            -InputObject $snapshot `
                            -Name 'IsReparsePoint'
                    ) -or
                    [bool](
                        Get-BoostLabCleanupPropertyValue `
                            -InputObject $snapshot `
                            -Name 'ContainsReparsePoint'
                    )
                ) -and
                -not $allowReparsePoints
            ) {
                $errors.Add(
                    'Symlink, junction, or reparse-point cleanup targets are denied.'
                )
            }

            if ($Recursive) {
                $fileCount = [long](
                    Get-BoostLabCleanupPropertyValue `
                        -InputObject $snapshot `
                        -Name 'FileCount'
                )
                $totalBytes = [long](
                    Get-BoostLabCleanupPropertyValue `
                        -InputObject $snapshot `
                        -Name 'TotalBytes'
                )
                $maxFiles = [long](
                    Get-BoostLabCleanupPropertyValue `
                        -InputObject $scope `
                        -Name 'MaxFiles'
                )
                $maxBytes = [long](
                    Get-BoostLabCleanupPropertyValue `
                        -InputObject $scope `
                        -Name 'MaxBytes'
                )
                if ($maxFiles -le 0 -or $maxBytes -le 0) {
                    $errors.Add(
                        'Recursive cleanup requires explicit positive file and byte limits.'
                    )
                }
                if ($fileCount -gt $maxFiles) {
                    $errors.Add(
                        "Cleanup target exceeds the approved file limit of $maxFiles."
                    )
                }
                if ($totalBytes -gt $maxBytes) {
                    $errors.Add(
                        "Cleanup target exceeds the approved byte limit of $maxBytes."
                    )
                }
            }
        }
        catch {
            $errors.Add("Cleanup target inspection failed: $($_.Exception.Message)")
        }
    }

    return [pscustomobject]@{
        IsAllowed      = $errors.Count -eq 0
        Status         = if ($errors.Count -eq 0) { 'Allowed' } else { 'Blocked' }
        ToolId         = $ToolId
        ScopeId        = $ScopeId
        TargetPath     = $TargetPath
        ResolvedPath   = $normalizedPath
        TargetType     = $TargetType
        CleanupType    = $CleanupType
        Recursive      = $Recursive
        Scope          = $scope
        Snapshot       = $snapshot
        Errors         = $errors.ToArray()
        Timestamp      = Get-Date
    }
}

function Test-BoostLabCleanupStateCaptureEvidence {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Plan,

        [AllowNull()]
        [object]$StateCaptureEvidence
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $required = [bool](
        Get-BoostLabCleanupPropertyValue `
            -InputObject $Plan `
            -Name 'StateCaptureRequired'
    )
    if (-not $required) {
        return [pscustomobject]@{
            IsValid   = $true
            Required  = $false
            Status    = 'NotRequired'
            Errors    = @()
            Timestamp = Get-Date
        }
    }
    if ($null -eq $StateCaptureEvidence) {
        $errors.Add('Required pre-mutation state capture evidence is missing.')
    }
    else {
        $success = Get-BoostLabCleanupPropertyValue `
            -InputObject $StateCaptureEvidence `
            -Name 'Success'
        $recordPath = [string](
            Get-BoostLabCleanupPropertyValue `
                -InputObject $StateCaptureEvidence `
                -Name 'RecordPath'
        )
        $record = Get-BoostLabCleanupPropertyValue `
            -InputObject $StateCaptureEvidence `
            -Name 'Record'
        if ($success -isnot [bool] -or -not [bool]$success) {
            $errors.Add('State capture evidence does not report success.')
        }
        if ([string]::IsNullOrWhiteSpace($recordPath)) {
            $errors.Add('State capture evidence has no record path.')
        }
        if ($null -eq $record) {
            $errors.Add('State capture evidence has no record object.')
        }
        else {
            foreach ($identity in @(
                @{ Plan = 'ToolId'; Record = 'ToolId' }
                @{ Plan = 'ActionId'; Record = 'ActionId' }
                @{ Plan = 'ResolvedPath'; Record = 'SourcePath' }
                @{ Plan = 'TargetType'; Record = 'ItemType' }
            )) {
                $expected = [string](
                    Get-BoostLabCleanupPropertyValue `
                        -InputObject $Plan `
                        -Name $identity.Plan
                )
                $actual = [string](
                    Get-BoostLabCleanupPropertyValue `
                        -InputObject $record `
                        -Name $identity.Record
                )
                if (-not $expected.Equals(
                    $actual,
                    [StringComparison]::OrdinalIgnoreCase
                )) {
                    $errors.Add(
                        "State capture identity mismatch for $($identity.Record)."
                    )
                }
            }
            if (
                -not [bool](
                    Get-BoostLabCleanupPropertyValue `
                        -InputObject $record `
                        -Name 'RollbackEligible'
                )
            ) {
                $errors.Add('State capture record is not rollback eligible.')
            }
        }
    }

    return [pscustomobject]@{
        IsValid   = $errors.Count -eq 0
        Required  = $true
        Status    = if ($errors.Count -eq 0) { 'Verified' } else { 'Blocked' }
        Errors    = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function New-BoostLabCleanupPlan {
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
        [string]$TargetType,

        [ValidateSet(
            'Delete',
            'Quarantine',
            'EmptyDirectory',
            'RemoveGeneratedArtifact'
        )]
        [string]$CleanupType,

        [Parameter(Mandatory)]
        [string]$Reason,

        [ValidateSet('Low', 'Medium', 'High')]
        [string]$RiskClassification = 'High',

        [ValidateSet('Explicit', 'HighRisk')]
        [string]$RequiredConfirmationLevel = 'Explicit',

        [bool]$RollbackEligible = $false,

        [bool]$Recursive = $false,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy,

        [AllowNull()]
        [scriptblock]$PathInspector,

        [string]$StateRoot = ''
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabCleanupPolicy
    }
    if ([string]::IsNullOrWhiteSpace($StateRoot)) {
        $StateRoot = Get-BoostLabCleanupStateRoot
    }

    $targetValidation = Test-BoostLabCleanupTarget `
        -ToolId $ToolId `
        -ScopeId $ScopeId `
        -TargetPath $TargetPath `
        -TargetType $TargetType `
        -CleanupType $CleanupType `
        -Recursive:$Recursive `
        -Policy $Policy `
        -PathInspector $PathInspector
    $scope = $targetValidation.Scope
    $stateCaptureRequired = $RollbackEligible
    if ($null -ne $scope) {
        $stateCaptureRequired = $stateCaptureRequired -or [bool](
            Get-BoostLabCleanupPropertyValue `
                -InputObject $scope `
                -Name 'RequireStateCapture'
        )
    }
    if ([string]::IsNullOrWhiteSpace($Reason)) {
        $targetValidation.Errors = @($targetValidation.Errors) +
            'Cleanup reason must be explicit.'
        $targetValidation.IsAllowed = $false
        $targetValidation.Status = 'Blocked'
    }

    $operationId = [guid]::NewGuid().ToString()
    $quarantinePath = ''
    if ($CleanupType -eq 'Quarantine') {
        $leafName = Split-Path -Leaf $targetValidation.ResolvedPath
        $quarantinePath = Join-Path `
            (Join-Path $StateRoot "Quarantine\$operationId") `
            $leafName
    }

    return [pscustomobject][ordered]@{
        OperationId              = $operationId
        ToolId                   = $ToolId
        ActionId                 = $ActionId
        Timestamp                = (Get-Date).ToUniversalTime().ToString('o')
        SchemaVersion            = $script:BoostLabCleanupSchemaVersion
        BoostLabVersion          = 'Foundation'
        TargetPath               = $TargetPath
        ResolvedPath             = $targetValidation.ResolvedPath
        TargetType               = $TargetType
        CleanupType              = $CleanupType
        Reason                   = $Reason
        RiskClassification       = $RiskClassification
        RequiredConfirmationLevel = $RequiredConfirmationLevel
        RequiresExplicitConfirmation = $true
        RollbackEligible         = $RollbackEligible
        StateCaptureRequired     = $stateCaptureRequired
        VerificationRequirement = 'Verify the exact approved target state after cleanup.'
        ScopeId                  = $ScopeId
        Recursive                = $Recursive
        MaxFiles                 = if ($null -ne $scope) {
            [long](
                Get-BoostLabCleanupPropertyValue -InputObject $scope -Name 'MaxFiles'
            )
        }
        else {
            0L
        }
        MaxBytes                 = if ($null -ne $scope) {
            [long](
                Get-BoostLabCleanupPropertyValue -InputObject $scope -Name 'MaxBytes'
            )
        }
        else {
            0L
        }
        OriginalSnapshot         = $targetValidation.Snapshot
        QuarantinePath           = $quarantinePath
        IsAllowed                = $targetValidation.IsAllowed
        Status                   = $targetValidation.Status
        Errors                   = @($targetValidation.Errors)
        IsDryRun                 = $true
    }
}

function New-BoostLabQuarantineRecord {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Plan,

        [Parameter(Mandatory)]
        [string]$QuarantinePath,

        [Parameter(Mandatory)]
        [string]$QuarantineHash,

        [AllowNull()]
        [object]$QuarantineMetadata,

        [bool]$RestoreEligible = $true
    )

    if ([string]$Plan.CleanupType -ne 'Quarantine') {
        throw 'Quarantine records require a Quarantine cleanup plan.'
    }
    if (-not [bool]$Plan.IsAllowed) {
        throw 'Quarantine records require an allowed cleanup plan.'
    }
    $snapshot = $Plan.OriginalSnapshot
    if ($null -eq $snapshot -or -not [bool]$snapshot.Exists) {
        throw 'Quarantine records require an existing original target snapshot.'
    }
    if ([string]::IsNullOrWhiteSpace([string]$snapshot.Hash)) {
        throw 'Quarantine records require the original target hash.'
    }
    if ($null -eq $snapshot.Metadata) {
        throw 'Quarantine records require original target metadata.'
    }
    if ([string]::IsNullOrWhiteSpace($QuarantineHash)) {
        throw 'Quarantine records require the quarantined target hash.'
    }
    if (-not $QuarantinePath.Equals(
        [string]$Plan.QuarantinePath,
        [StringComparison]::OrdinalIgnoreCase
    )) {
        throw 'Quarantine record path does not match the approved cleanup plan.'
    }
    if (-not $QuarantineHash.Equals(
        [string]$snapshot.Hash,
        [StringComparison]::OrdinalIgnoreCase
    )) {
        throw 'Quarantine hash must match the captured original hash.'
    }

    return [pscustomobject][ordered]@{
        OperationId            = [string]$Plan.OperationId
        ToolId                 = [string]$Plan.ToolId
        ActionId               = [string]$Plan.ActionId
        Timestamp              = (Get-Date).ToUniversalTime().ToString('o')
        SchemaVersion          = $script:BoostLabCleanupSchemaVersion
        BoostLabVersion        = [string]$Plan.BoostLabVersion
        ScopeId                = [string]$Plan.ScopeId
        OriginalPath           = [string]$Plan.TargetPath
        OriginalResolvedPath   = [string]$Plan.ResolvedPath
        TargetType             = [string]$Plan.TargetType
        OriginalHash           = [string]$snapshot.Hash
        OriginalMetadata       = $snapshot.Metadata
        OriginalFileCount      = [long]$snapshot.FileCount
        OriginalTotalBytes     = [long]$snapshot.TotalBytes
        QuarantinePath         = $QuarantinePath
        QuarantineHash         = $QuarantineHash
        QuarantineMetadata     = $QuarantineMetadata
        Reason                 = [string]$Plan.Reason
        RiskClassification     = [string]$Plan.RiskClassification
        RestoreEligible        = $RestoreEligible
        VerificationRequirement = 'Verify quarantine identity before restore and original identity after restore.'
        Restored               = $false
        RestoredAt             = $null
    }
}

function ConvertTo-BoostLabCleanupRecordTable {
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

function Save-BoostLabQuarantineRecord {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Record,

        [Parameter(Mandatory)]
        [string]$StateRoot
    )

    $operationId = [string](
        Get-BoostLabCleanupPropertyValue -InputObject $Record -Name 'OperationId'
    )
    if ([string]::IsNullOrWhiteSpace($operationId)) {
        throw 'Quarantine record requires an OperationId.'
    }

    $fullStateRoot = ConvertTo-BoostLabCleanupFullPath -Path $StateRoot
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

    $recordPath = Join-Path $recordsRoot "$operationId.quarantine.json"
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

function Import-BoostLabQuarantineRecord {
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
    try {
        $fullRecordPath = ConvertTo-BoostLabCleanupFullPath -Path $RecordPath
        $recordsRoot = Join-Path `
            (ConvertTo-BoostLabCleanupFullPath -Path $StateRoot) `
            'Records'
        if (-not (Test-BoostLabCleanupPathWithinRoot `
            -Path $fullRecordPath `
            -Root $recordsRoot)
        ) {
            $errors.Add('Quarantine record is outside the BoostLab records directory.')
        }
    }
    catch {
        $errors.Add($_.Exception.Message)
    }
    if (
        $errors.Count -eq 0 -and
        -not (Test-Path -LiteralPath $fullRecordPath -PathType Leaf)
    ) {
        $errors.Add('Quarantine record does not exist.')
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
                throw 'Quarantine record envelope is incomplete.'
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
                throw 'Quarantine record integrity hash does not match.'
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

function Test-BoostLabQuarantineRecord {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [object]$Record,

        [string]$ExpectedToolId = '',

        [string]$ExpectedActionId = '',

        [string]$StateRoot = '',

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabCleanupPolicy
    }
    $errors = [System.Collections.Generic.List[string]]::new()
    $policyValidation = Test-BoostLabCleanupPolicy -Policy $Policy
    if (-not $policyValidation.IsValid) {
        $errors.AddRange([string[]]@($policyValidation.Errors))
    }
    if ($null -eq $Record) {
        $errors.Add('Quarantine record is missing.')
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
            'OriginalPath'
            'OriginalResolvedPath'
            'TargetType'
            'OriginalHash'
            'OriginalMetadata'
            'QuarantinePath'
            'QuarantineHash'
            'QuarantineMetadata'
            'Reason'
            'RiskClassification'
            'RestoreEligible'
            'VerificationRequirement'
            'Restored'
        )) {
            if ($null -eq $Record.PSObject.Properties[$field]) {
                $errors.Add("Quarantine record is missing field: $field")
            }
        }
    }

    if ($errors.Count -eq 0) {
        if ([string]$Record.SchemaVersion -ne $script:BoostLabCleanupSchemaVersion) {
            $errors.Add('Quarantine record schema version is unsupported.')
        }
        $operationId = [guid]::Empty
        if (-not [guid]::TryParse([string]$Record.OperationId, [ref]$operationId)) {
            $errors.Add('Quarantine record OperationId is invalid.')
        }
        $timestamp = [datetime]::MinValue
        if (-not [datetime]::TryParse([string]$Record.Timestamp, [ref]$timestamp)) {
            $errors.Add('Quarantine record Timestamp is invalid.')
        }
        else {
            $maxAgeDays = [int]$Policy['MaxRecordAgeDays']
            if (
                $timestamp.ToUniversalTime() -lt
                (Get-Date).ToUniversalTime().AddDays(-$maxAgeDays)
            ) {
                $errors.Add('Quarantine record is stale.')
            }
        }
        if (
            -not [string]::IsNullOrWhiteSpace($ExpectedToolId) -and
            [string]$Record.ToolId -ne $ExpectedToolId
        ) {
            $errors.Add('Quarantine record tool identity does not match the caller.')
        }
        if (
            -not [string]::IsNullOrWhiteSpace($ExpectedActionId) -and
            [string]$Record.ActionId -ne $ExpectedActionId
        ) {
            $errors.Add('Quarantine record action identity does not match the caller.')
        }
        if ([string]::IsNullOrWhiteSpace([string]$Record.OriginalHash)) {
            $errors.Add('Quarantine record original hash is missing.')
        }
        if ($null -eq $Record.OriginalMetadata) {
            $errors.Add('Quarantine record original metadata is missing.')
        }
        if ([string]::IsNullOrWhiteSpace([string]$Record.QuarantineHash)) {
            $errors.Add('Quarantine record quarantine hash is missing.')
        }
        elseif (-not ([string]$Record.QuarantineHash).Equals(
            [string]$Record.OriginalHash,
            [StringComparison]::OrdinalIgnoreCase
        )) {
            $errors.Add('Quarantine record hashes do not match.')
        }
        if (-not [string]::IsNullOrWhiteSpace($StateRoot)) {
            try {
                $expectedQuarantineRoot = Join-Path `
                    (ConvertTo-BoostLabCleanupFullPath -Path $StateRoot) `
                    "Quarantine\$($Record.OperationId)"
                if (-not (Test-BoostLabCleanupPathWithinRoot `
                    -Path ([string]$Record.QuarantinePath) `
                    -Root $expectedQuarantineRoot)
                ) {
                    $errors.Add(
                        'Quarantine record path is outside its BoostLab operation directory.'
                    )
                }
            }
            catch {
                $errors.Add("Quarantine record path is invalid: $($_.Exception.Message)")
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

Export-ModuleMember -Function @(
    'Get-BoostLabCleanupPolicy'
    'Get-BoostLabCleanupStateRoot'
    'Test-BoostLabCleanupPolicy'
    'Test-BoostLabCleanupTarget'
    'Test-BoostLabCleanupStateCaptureEvidence'
    'New-BoostLabCleanupPlan'
    'New-BoostLabQuarantineRecord'
    'Save-BoostLabQuarantineRecord'
    'Import-BoostLabQuarantineRecord'
    'Test-BoostLabQuarantineRecord'
)
