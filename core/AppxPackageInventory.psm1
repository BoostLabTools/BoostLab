Set-StrictMode -Version Latest

$script:BoostLabAppxSchemaVersion = '1.0'
$script:BoostLabAppxPolicyPath = Join-Path `
    (Split-Path -Parent $PSScriptRoot) `
    'config\AppxPackagePolicy.psd1'
$script:BoostLabAppxMutations = @(
    'RemoveCurrentUser'
    'RemoveAllUsers'
    'RemoveProvisioned'
    'ReRegister'
    'RestoreProvisioned'
    'RepairRegistration'
)
$script:BoostLabAppxUserScopes = @(
    'CurrentUser'
    'AllUsers'
    'ProvisionedImage'
    'SystemPackage'
)

function Get-BoostLabAppxPropertyValue {
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

function ConvertTo-BoostLabAppxStringArray {
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

function Get-BoostLabAppxPackagePolicy {
    [CmdletBinding()]
    [OutputType([System.Collections.IDictionary])]
    param(
        [string]$PolicyPath = $script:BoostLabAppxPolicyPath
    )

    if (-not (Test-Path -LiteralPath $PolicyPath -PathType Leaf)) {
        throw "AppX package policy was not found: $PolicyPath"
    }

    return Import-PowerShellDataFile -LiteralPath $PolicyPath
}

function Get-BoostLabAppxPackageStateRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ([string]::IsNullOrWhiteSpace($env:ProgramData)) {
        throw 'The ProgramData environment variable is not available.'
    }

    return Join-Path $env:ProgramData 'BoostLab\State\AppxPackages'
}

function Test-BoostLabAppxExactIdentifier {
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

function Test-BoostLabAppxBroadFamily {
    param(
        [Parameter(Mandatory)]
        [string]$PackageFamilyName
    )

    $broadFamilies = @(
        'Microsoft'
        'Microsoft.Windows'
        'Windows'
        'Appx'
        'Package'
        'All'
    )

    return $broadFamilies -contains $PackageFamilyName
}

function Test-BoostLabAppxProtectedFamily {
    param(
        [Parameter(Mandatory)]
        [string]$PackageFamilyName,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Policy
    )

    foreach ($token in @($Policy['ProtectedPackageTokens'])) {
        if (
            -not [string]::IsNullOrWhiteSpace([string]$token) -and
            $PackageFamilyName.IndexOf(
                [string]$token,
                [StringComparison]::OrdinalIgnoreCase
            ) -ge 0
        ) {
            return $true
        }
    }

    return $false
}

function Test-BoostLabAppxPackagePolicy {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabAppxPackagePolicy
    }

    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($field in @(
        'SchemaVersion'
        'MaxRecordAgeDays'
        'ProtectedPackageTokens'
        'PackageScopes'
    )) {
        if (-not $Policy.Contains($field)) {
            $errors.Add("AppX package policy is missing field: $field")
        }
    }
    if (
        $Policy.Contains('SchemaVersion') -and
        [string]$Policy['SchemaVersion'] -ne $script:BoostLabAppxSchemaVersion
    ) {
        $errors.Add(
            "AppX package policy SchemaVersion must be " +
            "$script:BoostLabAppxSchemaVersion."
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
        $errors.Add(
            'AppX package policy MaxRecordAgeDays must be a positive integer.'
        )
    }

    $protectedTokens = if ($Policy.Contains('ProtectedPackageTokens')) {
        ConvertTo-BoostLabAppxStringArray $Policy['ProtectedPackageTokens']
    }
    else {
        @()
    }
    foreach ($requiredToken in @(
        'MicrosoftEdge'
        'Microsoft.Win32WebViewHost'
        'Microsoft.WindowsStore'
        'Microsoft.Windows.ShellExperienceHost'
        'Microsoft.Windows.StartMenuExperienceHost'
        'Microsoft.DesktopAppInstaller'
        'Microsoft.VCLibs'
        'Microsoft.UI.Xaml'
    )) {
        if ($requiredToken -notin $protectedTokens) {
            $errors.Add(
                "AppX protected-package defaults are missing: $requiredToken"
            )
        }
    }

    $scopeIds = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $scopes = @(
        if ($Policy.Contains('PackageScopes')) {
            @($Policy['PackageScopes'])
        }
    )
    foreach ($scope in $scopes) {
        foreach ($field in @(
            'ScopeId'
            'ToolIds'
            'ActionIds'
            'PackageFamilyNames'
            'AllowedUserScopes'
            'AllowedMutations'
            'AllowProtectedPackages'
            'AllowSystemPackages'
            'AllowFrameworkPackages'
            'AllowDependencyPackages'
            'AllowAllUsersRemoval'
            'AllowProvisionedRemoval'
            'AllowRestore'
            'NeedsExplicitConfirmation'
        )) {
            if ($null -eq (Get-BoostLabAppxPropertyValue $scope $field)) {
                $errors.Add("AppX package scope is missing field: $field")
            }
        }

        $scopeId = [string](Get-BoostLabAppxPropertyValue $scope 'ScopeId')
        if (-not (Test-BoostLabAppxExactIdentifier $scopeId)) {
            $errors.Add('AppX package scope ids must be exact identifiers.')
        }
        elseif (-not $scopeIds.Add($scopeId)) {
            $errors.Add("Duplicate AppX package scope id: $scopeId")
        }

        foreach ($toolId in ConvertTo-BoostLabAppxStringArray (
            Get-BoostLabAppxPropertyValue $scope 'ToolIds'
        )) {
            if (-not (Test-BoostLabAppxExactIdentifier $toolId)) {
                $errors.Add("AppX package scope '$scopeId' has invalid tool id.")
            }
        }
        foreach ($actionId in ConvertTo-BoostLabAppxStringArray (
            Get-BoostLabAppxPropertyValue $scope 'ActionIds'
        )) {
            if (-not (Test-BoostLabAppxExactIdentifier $actionId)) {
                $errors.Add("AppX package scope '$scopeId' has invalid action id.")
            }
        }
        foreach ($family in ConvertTo-BoostLabAppxStringArray (
            Get-BoostLabAppxPropertyValue $scope 'PackageFamilyNames'
        )) {
            if (-not (Test-BoostLabAppxExactIdentifier $family)) {
                $errors.Add(
                    "AppX package scope '$scopeId' has a non-exact family."
                )
            }
            elseif (Test-BoostLabAppxBroadFamily $family) {
                $errors.Add(
                    "AppX package scope '$scopeId' uses broad family '$family'."
                )
            }
        }
        foreach ($userScope in ConvertTo-BoostLabAppxStringArray (
            Get-BoostLabAppxPropertyValue $scope 'AllowedUserScopes'
        )) {
            if ($userScope -notin $script:BoostLabAppxUserScopes) {
                $errors.Add(
                    "AppX package scope '$scopeId' has invalid user scope " +
                    "'$userScope'."
                )
            }
        }
        foreach ($mutation in ConvertTo-BoostLabAppxStringArray (
            Get-BoostLabAppxPropertyValue $scope 'AllowedMutations'
        )) {
            if ($mutation -notin $script:BoostLabAppxMutations) {
                $errors.Add(
                    "AppX package scope '$scopeId' has invalid mutation " +
                    "'$mutation'."
                )
            }
        }

        if (-not [bool](
            Get-BoostLabAppxPropertyValue $scope 'NeedsExplicitConfirmation'
        )) {
            $errors.Add(
                "AppX package scope '$scopeId' must require confirmation."
            )
        }
        if (
            [bool](Get-BoostLabAppxPropertyValue $scope 'AllowAllUsersRemoval') -and
            'AllUsers' -notin (ConvertTo-BoostLabAppxStringArray (
                Get-BoostLabAppxPropertyValue $scope 'AllowedUserScopes'
            ))
        ) {
            $errors.Add(
                "AppX package scope '$scopeId' permits all-user removal " +
                'without the AllUsers scope.'
            )
        }
        if (
            [bool](Get-BoostLabAppxPropertyValue $scope 'AllowProvisionedRemoval') -and
            'ProvisionedImage' -notin (ConvertTo-BoostLabAppxStringArray (
                Get-BoostLabAppxPropertyValue $scope 'AllowedUserScopes'
            ))
        ) {
            $errors.Add(
                "AppX package scope '$scopeId' permits provisioned removal " +
                'without the ProvisionedImage scope.'
            )
        }
    }

    return [pscustomobject]@{
        IsValid           = $errors.Count -eq 0
        Status            = if ($errors.Count -eq 0) { 'Valid' } else { 'Invalid' }
        PackageScopeCount = @($scopes).Count
        Errors            = $errors.ToArray()
        Timestamp         = Get-Date
    }
}

function Find-BoostLabAppxPackageScope {
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ActionId,

        [Parameter(Mandatory)]
        [string]$ScopeId,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$PackageFamilyName,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Policy
    )

    foreach ($scope in @($Policy['PackageScopes'])) {
        if (
            [string](Get-BoostLabAppxPropertyValue $scope 'ScopeId') -eq $ScopeId -and
            $ToolId -in (ConvertTo-BoostLabAppxStringArray (
                Get-BoostLabAppxPropertyValue $scope 'ToolIds'
            )) -and
            $ActionId -in (ConvertTo-BoostLabAppxStringArray (
                Get-BoostLabAppxPropertyValue $scope 'ActionIds'
            )) -and
            $PackageFamilyName -in (ConvertTo-BoostLabAppxStringArray (
                Get-BoostLabAppxPropertyValue $scope 'PackageFamilyNames'
            ))
        ) {
            return $scope
        }
    }

    return $null
}

function Test-BoostLabAppxPackageTarget {
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
        [AllowEmptyString()]
        [string]$PackageFamilyName,

        [ValidateSet(
            'CurrentUser',
            'AllUsers',
            'ProvisionedImage',
            'SystemPackage'
        )]
        [string]$UserScope,

        [ValidateSet(
            'RemoveCurrentUser',
            'RemoveAllUsers',
            'RemoveProvisioned',
            'ReRegister',
            'RestoreProvisioned',
            'RepairRegistration'
        )]
        [string]$IntendedMutation,

        [AllowNull()]
        [object]$PackageSnapshot,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabAppxPackagePolicy
    }
    $errors = [System.Collections.Generic.List[string]]::new()
    $policyValidation = Test-BoostLabAppxPackagePolicy -Policy $Policy
    if (-not $policyValidation.IsValid) {
        $errors.AddRange([string[]]@($policyValidation.Errors))
    }
    if (-not (Test-BoostLabAppxExactIdentifier $PackageFamilyName)) {
        $errors.Add('Package family name must be exact and contain no wildcard.')
    }
    elseif (Test-BoostLabAppxBroadFamily $PackageFamilyName) {
        $errors.Add('Broad package-family targets are not allowed.')
    }

    $scope = Find-BoostLabAppxPackageScope `
        -ToolId $ToolId `
        -ActionId $ActionId `
        -ScopeId $ScopeId `
        -PackageFamilyName $PackageFamilyName `
        -Policy $Policy
    if ($null -eq $scope) {
        $errors.Add(
            'Package, tool, action, and scope are not present in the exact allowlist.'
        )
    }
    else {
        if ($UserScope -notin (ConvertTo-BoostLabAppxStringArray (
            Get-BoostLabAppxPropertyValue $scope 'AllowedUserScopes'
        ))) {
            $errors.Add("User scope '$UserScope' is not approved.")
        }
        if ($IntendedMutation -notin (ConvertTo-BoostLabAppxStringArray (
            Get-BoostLabAppxPropertyValue $scope 'AllowedMutations'
        ))) {
            $errors.Add("Mutation '$IntendedMutation' is not approved.")
        }
        if (
            (Test-BoostLabAppxProtectedFamily $PackageFamilyName $Policy) -and
            -not [bool](
                Get-BoostLabAppxPropertyValue $scope 'AllowProtectedPackages'
            )
        ) {
            $errors.Add('Protected Windows packages are denied by default.')
        }

        $isSystem = [bool](
            Get-BoostLabAppxPropertyValue $PackageSnapshot 'IsSystemCritical'
        )
        $isFramework = [bool](
            Get-BoostLabAppxPropertyValue $PackageSnapshot 'IsFramework'
        )
        $isDependency = [bool](
            Get-BoostLabAppxPropertyValue $PackageSnapshot 'IsDependency'
        )
        if (
            $isSystem -and
            -not [bool](
                Get-BoostLabAppxPropertyValue $scope 'AllowSystemPackages'
            )
        ) {
            $errors.Add('System-critical packages are denied by default.')
        }
        if (
            $isFramework -and
            -not [bool](
                Get-BoostLabAppxPropertyValue $scope 'AllowFrameworkPackages'
            )
        ) {
            $errors.Add('Framework packages are denied by default.')
        }
        if (
            $isDependency -and
            -not [bool](
                Get-BoostLabAppxPropertyValue $scope 'AllowDependencyPackages'
            )
        ) {
            $errors.Add('Dependency packages are denied by default.')
        }
        if (
            $IntendedMutation -eq 'RemoveAllUsers' -and
            -not [bool](
                Get-BoostLabAppxPropertyValue $scope 'AllowAllUsersRemoval'
            )
        ) {
            $errors.Add('All-user package removal requires separate approval.')
        }
        if (
            $IntendedMutation -eq 'RemoveProvisioned' -and
            -not [bool](
                Get-BoostLabAppxPropertyValue $scope 'AllowProvisionedRemoval'
            )
        ) {
            $errors.Add(
                'Provisioned-image package removal requires separate approval.'
            )
        }
        if (
            $IntendedMutation -in @(
                'ReRegister',
                'RestoreProvisioned',
                'RepairRegistration'
            ) -and
            -not [bool](Get-BoostLabAppxPropertyValue $scope 'AllowRestore')
        ) {
            $errors.Add('Package restore or repair is not approved by this scope.')
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
        ScopeId                      = $ScopeId
        PackageFamilyName            = $PackageFamilyName
        UserScope                    = $UserScope
        IntendedMutation             = $IntendedMutation
        RequiresExplicitConfirmation = $true
        Errors                       = $errors.ToArray()
        Timestamp                    = Get-Date
    }
}

function New-BoostLabAppxInventoryRecord {
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
        [string]$PackageFamilyName,

        [ValidateSet(
            'CurrentUser',
            'AllUsers',
            'ProvisionedImage',
            'SystemPackage'
        )]
        [string]$UserScope,

        [ValidateSet(
            'RemoveCurrentUser',
            'RemoveAllUsers',
            'RemoveProvisioned',
            'ReRegister',
            'RestoreProvisioned',
            'RepairRegistration'
        )]
        [string]$IntendedMutation,

        [Parameter(Mandatory)]
        [scriptblock]$PackageInspector,

        [bool]$RollbackEligible = $false,

        [string]$RiskClassification = 'High',

        [string]$BoostLabVersion = 'Foundation',

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabAppxPackagePolicy
    }
    $snapshot = & $PackageInspector $PackageFamilyName $UserScope
    if ($null -eq $snapshot) {
        throw 'Package inspector did not return an inventory snapshot.'
    }

    $target = Test-BoostLabAppxPackageTarget `
        -ToolId $ToolId `
        -ActionId $ActionId `
        -ScopeId $ScopeId `
        -PackageFamilyName $PackageFamilyName `
        -UserScope $UserScope `
        -IntendedMutation $IntendedMutation `
        -PackageSnapshot $snapshot `
        -Policy $Policy
    if (-not $target.IsAllowed) {
        return [pscustomobject]@{
            Success         = $false
            Status          = 'Blocked'
            InventoryRecord = $null
            Message         = 'AppX inventory capture was blocked by policy.'
            Errors          = @($target.Errors)
            Timestamp       = Get-Date
        }
    }

    $detectedFamily = [string](
        Get-BoostLabAppxPropertyValue $snapshot 'PackageFamilyName'
    )
    if (
        [string]::IsNullOrWhiteSpace($detectedFamily) -or
        -not $detectedFamily.Equals(
            $PackageFamilyName,
            [StringComparison]::OrdinalIgnoreCase
        )
    ) {
        return [pscustomobject]@{
            Success         = $false
            Status          = 'Blocked'
            InventoryRecord = $null
            Message         = 'Detected package identity does not match the request.'
            Errors          = @('Package inspector returned a mismatched family name.')
            Timestamp       = Get-Date
        }
    }

    $exists = [bool](Get-BoostLabAppxPropertyValue $snapshot 'Exists')
    $isInstalled = [bool](
        Get-BoostLabAppxPropertyValue $snapshot 'IsInstalled'
    )
    $isProvisioned = [bool](
        Get-BoostLabAppxPropertyValue $snapshot 'IsProvisioned'
    )
    $manifestPath = [string](
        Get-BoostLabAppxPropertyValue $snapshot 'RegistrationManifestPath'
    )
    $installLocation = [string](
        Get-BoostLabAppxPropertyValue $snapshot 'InstallLocation'
    )
    if ($RollbackEligible) {
        if (-not $exists) {
            throw 'Rollback eligibility requires an originally existing package.'
        }
        if (
            $IntendedMutation -in @(
                'RemoveCurrentUser',
                'RemoveAllUsers',
                'ReRegister',
                'RepairRegistration'
            ) -and
            (
                [string]::IsNullOrWhiteSpace($installLocation) -or
                [string]::IsNullOrWhiteSpace($manifestPath)
            )
        ) {
            throw (
                'Rollback eligibility requires the captured install location ' +
                'and registration manifest path.'
            )
        }
        if (
            $IntendedMutation -eq 'RemoveProvisioned' -and
            [string]::IsNullOrWhiteSpace([string](
                Get-BoostLabAppxPropertyValue `
                    $snapshot `
                    'ProvisionedPackageIdentity'
            ))
        ) {
            throw (
                'Provisioned rollback eligibility requires an exact provisioned ' +
                'package identity.'
            )
        }
    }

    $record = [pscustomobject][ordered]@{
        OperationId                 = [guid]::NewGuid().ToString()
        ToolId                      = $ToolId
        ActionId                    = $ActionId
        Timestamp                   = (Get-Date).ToUniversalTime().ToString('o')
        SchemaVersion               = $script:BoostLabAppxSchemaVersion
        BoostLabVersion             = $BoostLabVersion
        ScopeId                     = $ScopeId
        PackageFamilyName           = $detectedFamily
        PackageFullName             = [string](
            Get-BoostLabAppxPropertyValue $snapshot 'PackageFullName'
        )
        DisplayName                 = [string](
            Get-BoostLabAppxPropertyValue $snapshot 'DisplayName'
        )
        Publisher                   = [string](
            Get-BoostLabAppxPropertyValue $snapshot 'Publisher'
        )
        Version                     = [string](
            Get-BoostLabAppxPropertyValue $snapshot 'Version'
        )
        Architecture                = [string](
            Get-BoostLabAppxPropertyValue $snapshot 'Architecture'
        )
        InstallLocation             = $installLocation
        PackageStatus               = [string](
            Get-BoostLabAppxPropertyValue $snapshot 'PackageStatus'
        )
        ProvisionedPackageIdentity  = [string](
            Get-BoostLabAppxPropertyValue `
                $snapshot `
                'ProvisionedPackageIdentity'
        )
        UserScope                   = $UserScope
        OriginalExists              = $exists
        OriginalInstalled           = $isInstalled
        OriginalProvisioned         = $isProvisioned
        RegistrationManifestPath    = $manifestPath
        Dependencies                = @(
            ConvertTo-BoostLabAppxStringArray (
                Get-BoostLabAppxPropertyValue $snapshot 'Dependencies'
            )
        )
        IsFramework                 = [bool](
            Get-BoostLabAppxPropertyValue $snapshot 'IsFramework'
        )
        IsDependency                = [bool](
            Get-BoostLabAppxPropertyValue $snapshot 'IsDependency'
        )
        IsSystemCritical            = [bool](
            Get-BoostLabAppxPropertyValue $snapshot 'IsSystemCritical'
        )
        IntendedMutation            = $IntendedMutation
        RollbackEligible            = $RollbackEligible
        VerificationRequired        = $true
        RiskClassification          = $RiskClassification
        MutationRecorded            = $false
        PostMutationState           = $null
        RestoreRecorded             = $false
        PostRestoreState            = $null
    }

    return [pscustomobject]@{
        Success         = $true
        Status          = 'Captured'
        InventoryRecord = $record
        Message         = 'AppX package inventory was captured without mutation.'
        Errors          = @()
        Timestamp       = Get-Date
    }
}

function ConvertTo-BoostLabAppxRecordTable {
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

function Get-BoostLabAppxSha256 {
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

function Save-BoostLabAppxInventoryRecord {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Record,

        [Parameter(Mandatory)]
        [string]$StateRoot
    )

    $operationId = [string](
        Get-BoostLabAppxPropertyValue $Record 'OperationId'
    )
    if (-not (Test-BoostLabAppxExactIdentifier $operationId)) {
        throw 'AppX inventory record requires a valid OperationId.'
    }

    $recordsRoot = Join-Path $StateRoot 'Records'
    [IO.Directory]::CreateDirectory($recordsRoot) | Out-Null
    $recordJson = $Record | ConvertTo-Json -Compress -Depth 40
    $recordHash = Get-BoostLabAppxSha256 -Text $recordJson
    $envelope = [pscustomobject][ordered]@{
        SchemaVersion = $script:BoostLabAppxSchemaVersion
        RecordSha256  = $recordHash
        Record        = $Record
    }
    $recordPath = Join-Path $recordsRoot "$operationId.json"
    $envelope |
        ConvertTo-Json -Depth 50 |
        Set-Content -LiteralPath $recordPath -Encoding UTF8

    return [pscustomobject]@{
        Success      = $true
        RecordPath   = $recordPath
        RecordSha256 = $recordHash
        Timestamp    = Get-Date
    }
}

function Import-BoostLabAppxInventoryRecord {
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
    $recordsRoot = [IO.Path]::GetFullPath((Join-Path $StateRoot 'Records'))
    try {
        $fullRecordPath = [IO.Path]::GetFullPath($RecordPath)
        if (-not $fullRecordPath.StartsWith(
            $recordsRoot + [IO.Path]::DirectorySeparatorChar,
            [StringComparison]::OrdinalIgnoreCase
        )) {
            $errors.Add('AppX inventory record is outside the records directory.')
        }
        elseif (-not (Test-Path -LiteralPath $fullRecordPath -PathType Leaf)) {
            $errors.Add('AppX inventory record does not exist.')
        }
        else {
            $envelope = Get-Content -LiteralPath $fullRecordPath -Raw |
                ConvertFrom-Json
            if (
                [string]$envelope.SchemaVersion -ne
                $script:BoostLabAppxSchemaVersion
            ) {
                $errors.Add('AppX inventory envelope schema is unsupported.')
            }
            $record = $envelope.Record
            $recordJson = $record | ConvertTo-Json -Compress -Depth 40
            $actualHash = Get-BoostLabAppxSha256 -Text $recordJson
            if ($actualHash -ne [string]$envelope.RecordSha256) {
                $errors.Add('AppX inventory record integrity check failed.')
            }
        }
    }
    catch {
        $errors.Add("AppX inventory record could not be read: $($_.Exception.Message)")
    }

    return [pscustomobject]@{
        IsValid   = $errors.Count -eq 0
        Status    = if ($errors.Count -eq 0) { 'Valid' } else { 'Blocked' }
        Record    = if ($errors.Count -eq 0) { $record } else { $null }
        Errors    = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function Test-BoostLabAppxInventoryRecord {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [object]$Record,

        [string]$ExpectedToolId = '',

        [string]$ExpectedActionId = '',

        [string]$ExpectedPackageFamilyName = '',

        [string]$ExpectedMutation = '',

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabAppxPackagePolicy
    }
    $errors = [System.Collections.Generic.List[string]]::new()
    if ($null -eq $Record) {
        $errors.Add('AppX inventory record is missing.')
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
            'PackageFamilyName'
            'PackageFullName'
            'DisplayName'
            'Publisher'
            'Version'
            'Architecture'
            'InstallLocation'
            'PackageStatus'
            'ProvisionedPackageIdentity'
            'UserScope'
            'OriginalExists'
            'OriginalInstalled'
            'OriginalProvisioned'
            'RegistrationManifestPath'
            'Dependencies'
            'IsFramework'
            'IsDependency'
            'IsSystemCritical'
            'IntendedMutation'
            'RollbackEligible'
            'VerificationRequired'
            'RiskClassification'
            'MutationRecorded'
            'PostMutationState'
            'RestoreRecorded'
            'PostRestoreState'
        )) {
            if ($null -eq $Record.PSObject.Properties[$field]) {
                $errors.Add("AppX inventory record is missing field: $field")
            }
        }
        if (
            [string](Get-BoostLabAppxPropertyValue $Record 'SchemaVersion') -ne
            $script:BoostLabAppxSchemaVersion
        ) {
            $errors.Add('AppX inventory record schema is unsupported.')
        }

        $timestamp = [datetime]::MinValue
        if (-not [datetime]::TryParse(
            [string](Get-BoostLabAppxPropertyValue $Record 'Timestamp'),
            [ref]$timestamp
        )) {
            $errors.Add('AppX inventory record timestamp is invalid.')
        }
        elseif ($Policy.Contains('MaxRecordAgeDays')) {
            $age = (Get-Date).ToUniversalTime() - $timestamp.ToUniversalTime()
            if ($age.TotalDays -gt [int]$Policy['MaxRecordAgeDays']) {
                $errors.Add('AppX inventory record is stale.')
            }
            if ($age.TotalMinutes -lt -5) {
                $errors.Add('AppX inventory record timestamp is in the future.')
            }
        }

        foreach ($identity in @(
            @{ Expected = $ExpectedToolId; Actual = 'ToolId'; Label = 'tool' }
            @{
                Expected = $ExpectedActionId
                Actual   = 'ActionId'
                Label    = 'action'
            }
            @{
                Expected = $ExpectedPackageFamilyName
                Actual   = 'PackageFamilyName'
                Label    = 'package'
            }
            @{
                Expected = $ExpectedMutation
                Actual   = 'IntendedMutation'
                Label    = 'mutation'
            }
        )) {
            if (
                -not [string]::IsNullOrWhiteSpace([string]$identity.Expected) -and
                [string](
                    Get-BoostLabAppxPropertyValue $Record $identity.Actual
                ) -ne [string]$identity.Expected
            ) {
                $errors.Add("AppX inventory record $($identity.Label) mismatch.")
            }
        }

        $target = Test-BoostLabAppxPackageTarget `
            -ToolId ([string](Get-BoostLabAppxPropertyValue $Record 'ToolId')) `
            -ActionId ([string](Get-BoostLabAppxPropertyValue $Record 'ActionId')) `
            -ScopeId ([string](Get-BoostLabAppxPropertyValue $Record 'ScopeId')) `
            -PackageFamilyName ([string](
                Get-BoostLabAppxPropertyValue $Record 'PackageFamilyName'
            )) `
            -UserScope ([string](
                Get-BoostLabAppxPropertyValue $Record 'UserScope'
            )) `
            -IntendedMutation ([string](
                Get-BoostLabAppxPropertyValue $Record 'IntendedMutation'
            )) `
            -PackageSnapshot $Record `
            -Policy $Policy
        if (-not $target.IsAllowed) {
            $errors.AddRange([string[]]@($target.Errors))
        }
    }

    return [pscustomobject]@{
        IsValid   = $errors.Count -eq 0
        Status    = if ($errors.Count -eq 0) { 'Valid' } else { 'Blocked' }
        Errors    = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function New-BoostLabAppxMutationPlan {
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
        [string]$PackageFamilyName,

        [ValidateSet(
            'RemoveCurrentUser',
            'RemoveAllUsers',
            'RemoveProvisioned',
            'ReRegister',
            'RestoreProvisioned',
            'RepairRegistration'
        )]
        [string]$IntendedMutation,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabAppxPackagePolicy
    }
    $errors = [System.Collections.Generic.List[string]]::new()
    $imported = Import-BoostLabAppxInventoryRecord `
        -RecordPath $RecordPath `
        -StateRoot $StateRoot
    $record = $imported.Record
    if (-not $imported.IsValid) {
        $errors.AddRange([string[]]@($imported.Errors))
    }
    else {
        $validated = Test-BoostLabAppxInventoryRecord `
            -Record $record `
            -ExpectedToolId $ToolId `
            -ExpectedActionId $ActionId `
            -ExpectedPackageFamilyName $PackageFamilyName `
            -ExpectedMutation $IntendedMutation `
            -Policy $Policy
        if (-not $validated.IsValid) {
            $errors.AddRange([string[]]@($validated.Errors))
        }
    }

    return [pscustomobject][ordered]@{
        OperationId                 = if ($null -ne $record) {
            [string]$record.OperationId
        }
        else {
            ''
        }
        ToolId                      = $ToolId
        ActionId                    = $ActionId
        Timestamp                   = Get-Date
        SchemaVersion               = $script:BoostLabAppxSchemaVersion
        PackageFamilyName            = $PackageFamilyName
        UserScope                    = if ($null -ne $record) {
            [string]$record.UserScope
        }
        else {
            ''
        }
        IntendedMutation             = $IntendedMutation
        InventoryRecordPath          = $RecordPath
        InventoryVerified            = $errors.Count -eq 0
        RequiresExplicitConfirmation = $true
        VerificationRequired         = $true
        RollbackEligible             = if ($null -ne $record) {
            [bool]$record.RollbackEligible
        }
        else {
            $false
        }
        RiskClassification           = if ($null -ne $record) {
            [string]$record.RiskClassification
        }
        else {
            'High'
        }
        IsDryRun                     = $true
        IsAllowed                    = $errors.Count -eq 0
        Status                       = if ($errors.Count -eq 0) {
            'Allowed'
        }
        else {
            'Blocked'
        }
        Message                      = if ($errors.Count -eq 0) {
            'AppX mutation plan is ready for explicit confirmation.'
        }
        else {
            'AppX mutation plan was blocked.'
        }
        Errors                       = $errors.ToArray()
    }
}

function Set-BoostLabAppxInventoryMutationState {
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

    $imported = Import-BoostLabAppxInventoryRecord `
        -RecordPath $RecordPath `
        -StateRoot $StateRoot
    if (-not $imported.IsValid) {
        throw ($imported.Errors -join '; ')
    }
    $table = ConvertTo-BoostLabAppxRecordTable $imported.Record
    $table['MutationRecorded'] = $true
    $table['PostMutationState'] = $PostMutationState
    return Save-BoostLabAppxInventoryRecord `
        -Record ([pscustomobject]$table) `
        -StateRoot $StateRoot
}

function Set-BoostLabAppxInventoryRestoreState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$RecordPath,

        [Parameter(Mandatory)]
        [string]$StateRoot,

        [Parameter(Mandatory)]
        [object]$PostRestoreState
    )

    $imported = Import-BoostLabAppxInventoryRecord `
        -RecordPath $RecordPath `
        -StateRoot $StateRoot
    if (-not $imported.IsValid) {
        throw ($imported.Errors -join '; ')
    }
    $table = ConvertTo-BoostLabAppxRecordTable $imported.Record
    $table['RestoreRecorded'] = $true
    $table['PostRestoreState'] = $PostRestoreState
    return Save-BoostLabAppxInventoryRecord `
        -Record ([pscustomobject]$table) `
        -StateRoot $StateRoot
}

function New-BoostLabAppxRestorePlan {
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

        [string]$SourceActionId = '',

        [ValidateSet(
            'ReRegister',
            'RestoreProvisioned',
            'RepairRegistration'
        )]
        [string]$RestoreMutation,

        [Parameter(Mandatory)]
        [scriptblock]$ManifestInspector,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabAppxPackagePolicy
    }
    $errors = [System.Collections.Generic.List[string]]::new()
    $manifest = $null
    $imported = Import-BoostLabAppxInventoryRecord `
        -RecordPath $RecordPath `
        -StateRoot $StateRoot
    $record = $imported.Record
    if (-not $imported.IsValid) {
        $errors.AddRange([string[]]@($imported.Errors))
    }
    else {
        $validated = Test-BoostLabAppxInventoryRecord `
            -Record $record `
            -ExpectedToolId $ToolId `
            -ExpectedActionId $SourceActionId `
            -Policy $Policy
        if (-not $validated.IsValid) {
            $errors.AddRange([string[]]@($validated.Errors))
        }
        if (-not [bool]$record.RollbackEligible) {
            $errors.Add('AppX inventory record is not rollback eligible.')
        }
        if (-not [bool]$record.MutationRecorded) {
            $errors.Add('AppX restore requires a recorded completed mutation.')
        }

        $restoreTarget = Test-BoostLabAppxPackageTarget `
            -ToolId $ToolId `
            -ActionId $ActionId `
            -ScopeId ([string]$record.ScopeId) `
            -PackageFamilyName ([string]$record.PackageFamilyName) `
            -UserScope ([string]$record.UserScope) `
            -IntendedMutation $RestoreMutation `
            -PackageSnapshot $record `
            -Policy $Policy
        if (-not $restoreTarget.IsAllowed) {
            $errors.AddRange([string[]]@($restoreTarget.Errors))
        }

        $manifestPath = [string]$record.RegistrationManifestPath
        if ([string]::IsNullOrWhiteSpace($manifestPath)) {
            $errors.Add('Captured registration manifest path is missing.')
        }
        else {
            try {
                $manifest = & $ManifestInspector $manifestPath
                if (
                    $null -eq $manifest -or
                    -not [bool](
                        Get-BoostLabAppxPropertyValue $manifest 'Exists'
                    )
                ) {
                    $errors.Add(
                        'Captured registration manifest is not available. ' +
                        'Restore cannot download or repair it in this phase.'
                    )
                }
                elseif (
                    -not [string](
                        Get-BoostLabAppxPropertyValue $manifest 'Path'
                    ).Equals(
                        $manifestPath,
                        [StringComparison]::OrdinalIgnoreCase
                    )
                ) {
                    $errors.Add('Registration manifest path identity mismatch.')
                }
            }
            catch {
                $errors.Add(
                    "Registration manifest inspection failed: " +
                    $_.Exception.Message
                )
            }
        }

        if (
            $RestoreMutation -in @('ReRegister', 'RepairRegistration') -and
            [string]::IsNullOrWhiteSpace([string]$record.InstallLocation)
        ) {
            $errors.Add('Captured install location is missing.')
        }
        if (
            $RestoreMutation -eq 'RestoreProvisioned' -and
            [string]::IsNullOrWhiteSpace(
                [string]$record.ProvisionedPackageIdentity
            )
        ) {
            $errors.Add('Captured provisioned package identity is missing.')
        }
    }

    return [pscustomobject][ordered]@{
        OperationId                 = if ($null -ne $record) {
            [string]$record.OperationId
        }
        else {
            ''
        }
        ToolId                      = $ToolId
        ActionId                    = $ActionId
        SourceActionId              = $SourceActionId
        Timestamp                   = Get-Date
        SchemaVersion               = $script:BoostLabAppxSchemaVersion
        PackageFamilyName            = if ($null -ne $record) {
            [string]$record.PackageFamilyName
        }
        else {
            ''
        }
        UserScope                    = if ($null -ne $record) {
            [string]$record.UserScope
        }
        else {
            ''
        }
        RestoreMutation              = $RestoreMutation
        InventoryRecordPath          = $RecordPath
        RegistrationManifestPath     = if ($null -ne $record) {
            [string]$record.RegistrationManifestPath
        }
        else {
            ''
        }
        ProvisionedPackageIdentity   = if ($null -ne $record) {
            [string]$record.ProvisionedPackageIdentity
        }
        else {
            ''
        }
        RequiresExplicitConfirmation = $true
        VerificationRequired         = $true
        IsDryRun                     = $true
        IsAllowed                    = $errors.Count -eq 0
        Status                       = if ($errors.Count -eq 0) {
            'Allowed'
        }
        else {
            'Blocked'
        }
        Message                      = if ($errors.Count -eq 0) {
            'AppX restore plan is ready for explicit confirmation.'
        }
        else {
            'AppX restore plan was blocked.'
        }
        Errors                       = $errors.ToArray()
    }
}

Export-ModuleMember -Function @(
    'Get-BoostLabAppxPackagePolicy'
    'Get-BoostLabAppxPackageStateRoot'
    'Test-BoostLabAppxPackagePolicy'
    'Test-BoostLabAppxPackageTarget'
    'New-BoostLabAppxInventoryRecord'
    'Save-BoostLabAppxInventoryRecord'
    'Import-BoostLabAppxInventoryRecord'
    'Test-BoostLabAppxInventoryRecord'
    'New-BoostLabAppxMutationPlan'
    'Set-BoostLabAppxInventoryMutationState'
    'Set-BoostLabAppxInventoryRestoreState'
    'New-BoostLabAppxRestorePlan'
)
