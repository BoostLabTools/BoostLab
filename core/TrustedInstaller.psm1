Set-StrictMode -Version Latest

$script:BoostLabTrustedInstallerSchemaVersion = '1.0'
$script:BoostLabTrustedInstallerIdentity = 'NT SERVICE\TrustedInstaller'
$script:BoostLabTrustedInstallerPolicyPath = Join-Path `
    (Split-Path -Parent $PSScriptRoot) `
    'config\TrustedInstallerPolicy.psd1'
$script:BoostLabTrustedInstallerRawProperties = @(
    'Command'
    'CommandLine'
    'RawCommand'
    'ShellCommand'
    'Script'
    'ScriptBlock'
)

function Get-BoostLabTrustedInstallerPropertyValue {
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

function Test-BoostLabTrustedInstallerPropertyExists {
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

function ConvertTo-BoostLabTrustedInstallerStringArray {
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

function Test-BoostLabTrustedInstallerExactIdentifier {
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

function Test-BoostLabTrustedInstallerRawCommand {
    param(
        [AllowNull()]
        [object]$InputObject
    )

    if ($null -eq $InputObject) {
        return $false
    }
    foreach ($name in $script:BoostLabTrustedInstallerRawProperties) {
        if (Test-BoostLabTrustedInstallerPropertyExists $InputObject $name) {
            return $true
        }
    }
    return $false
}

function ConvertTo-BoostLabTrustedInstallerFullPath {
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

function ConvertTo-BoostLabTrustedInstallerRegistryPath {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (
        [string]::IsNullOrWhiteSpace($Path) -or
        $Path.IndexOfAny([char[]]'*?[]') -ge 0
    ) {
        throw 'An exact registry path is required.'
    }
    $normalized = $Path.Trim().TrimEnd('\')
    $normalized = $normalized -replace '^HKEY_CURRENT_USER\\', 'HKCU:\'
    $normalized = $normalized -replace '^HKEY_LOCAL_MACHINE\\', 'HKLM:\'
    $normalized = $normalized -replace '^Registry::HKEY_CURRENT_USER\\', 'HKCU:\'
    $normalized = $normalized -replace '^Registry::HKEY_LOCAL_MACHINE\\', 'HKLM:\'
    if ($normalized -notmatch '^HK(CU|LM):\\.+') {
        throw 'Only exact HKCU or HKLM subkeys are supported.'
    }
    return $normalized
}

function Get-BoostLabTrustedInstallerPolicy {
    [CmdletBinding()]
    [OutputType([System.Collections.IDictionary])]
    param(
        [string]$PolicyPath = $script:BoostLabTrustedInstallerPolicyPath
    )

    if (-not (Test-Path -LiteralPath $PolicyPath -PathType Leaf)) {
        throw "TrustedInstaller policy was not found: $PolicyPath"
    }
    return Import-PowerShellDataFile -LiteralPath $PolicyPath
}

function Test-BoostLabTrustedInstallerSupported {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        Supported = $false
        Status    = 'NotImplemented'
        Identity  = $script:BoostLabTrustedInstallerIdentity
        Message   = 'TrustedInstaller process execution is not implemented.'
        Timestamp = Get-Date
    }
}

function Test-BoostLabTrustedInstallerPolicy {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabTrustedInstallerPolicy
    }
    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($field in @(
        'SchemaVersion'
        'MaxRequestAgeMinutes'
        'RequestedIdentity'
        'TrustedInstallerScopes'
        'BlockedExternalElevationTools'
        'ProtectedRegistryPrefixes'
        'ProtectedServiceNames'
        'ProtectedPackagePrefixes'
    )) {
        if (-not $Policy.Contains($field)) {
            $errors.Add("TrustedInstaller policy is missing field: $field")
        }
    }
    if (
        $Policy.Contains('SchemaVersion') -and
        [string]$Policy['SchemaVersion'] -ne
            $script:BoostLabTrustedInstallerSchemaVersion
    ) {
        $errors.Add('TrustedInstaller policy schema is unsupported.')
    }
    if (
        $Policy.Contains('RequestedIdentity') -and
        [string]$Policy['RequestedIdentity'] -ne
            $script:BoostLabTrustedInstallerIdentity
    ) {
        $errors.Add('Only NT SERVICE\TrustedInstaller identity is supported.')
    }
    $maxAge = 0
    if (
        $Policy.Contains('MaxRequestAgeMinutes') -and
        (
            -not [int]::TryParse(
                [string]$Policy['MaxRequestAgeMinutes'],
                [ref]$maxAge
            ) -or
            $maxAge -le 0
        )
    ) {
        $errors.Add('MaxRequestAgeMinutes must be positive.')
    }

    $scopeIds = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $scopes = @(
        if ($Policy.Contains('TrustedInstallerScopes')) {
            @($Policy['TrustedInstallerScopes'])
        }
    )
    foreach ($scope in $scopes) {
        $scopeId = [string](
            Get-BoostLabTrustedInstallerPropertyValue $scope 'ScopeId'
        )
        foreach ($field in @(
            'ScopeId'
            'ToolIds'
            'ActionIds'
            'RequestedIdentity'
            'Commands'
            'AllowedTargetFiles'
            'AllowedRegistryPaths'
            'AllowedServiceNames'
            'AllowedPackageIdentities'
            'RequiredFoundations'
            'RequiresActionPlanConfirmation'
            'RequiresAdministratorHost'
            'RequiresStateCapture'
            'RequiresVerificationPlan'
            'AllowProtectedTargets'
            'RiskClassification'
            'TimeoutSeconds'
            'LoggingRequirements'
            'AllowCancellation'
            'RecoveryBehavior'
        )) {
            if (
                -not (
                    Test-BoostLabTrustedInstallerPropertyExists $scope $field
                )
            ) {
                $errors.Add("TrustedInstaller scope is missing field: $field")
            }
        }
        if (-not (Test-BoostLabTrustedInstallerExactIdentifier $scopeId)) {
            $errors.Add('TrustedInstaller scope ids must be exact identifiers.')
        }
        elseif (-not $scopeIds.Add($scopeId)) {
            $errors.Add("Duplicate TrustedInstaller scope id: $scopeId")
        }
        foreach ($identityField in @('ToolIds', 'ActionIds')) {
            $identities = @(
                ConvertTo-BoostLabTrustedInstallerStringArray (
                    Get-BoostLabTrustedInstallerPropertyValue `
                        $scope `
                        $identityField
                )
            )
            if ($identities.Count -eq 0) {
                $errors.Add("Scope '$scopeId' requires $identityField.")
            }
            foreach ($identity in $identities) {
                if (-not (Test-BoostLabTrustedInstallerExactIdentifier $identity)) {
                    $errors.Add("Scope '$scopeId' has invalid $identityField.")
                }
            }
        }
        if (
            [string](
                Get-BoostLabTrustedInstallerPropertyValue `
                    $scope `
                    'RequestedIdentity'
            ) -ne $script:BoostLabTrustedInstallerIdentity
        ) {
            $errors.Add("Scope '$scopeId' requests an unsupported identity.")
        }

        $commands = @(
            Get-BoostLabTrustedInstallerPropertyValue $scope 'Commands'
        )
        if ($commands.Count -eq 0) {
            $errors.Add("Scope '$scopeId' requires exact command descriptors.")
        }
        foreach ($command in $commands) {
            foreach ($field in @(
                'CommandId'
                'AllowedExecutablePaths'
                'AllowedHelperIds'
                'AllowedArguments'
                'AllowedWorkingDirectories'
            )) {
                if (
                    -not (
                        Test-BoostLabTrustedInstallerPropertyExists `
                            $command `
                            $field
                    )
                ) {
                    $errors.Add("Command descriptor is missing field: $field")
                }
            }
            $commandId = [string](
                Get-BoostLabTrustedInstallerPropertyValue $command 'CommandId'
            )
            if (-not (Test-BoostLabTrustedInstallerExactIdentifier $commandId)) {
                $errors.Add("Scope '$scopeId' has an invalid command id.")
            }
            if (Test-BoostLabTrustedInstallerRawCommand $command) {
                $errors.Add("Command '$commandId' contains raw command text.")
            }
            $executables = @(
                ConvertTo-BoostLabTrustedInstallerStringArray (
                    Get-BoostLabTrustedInstallerPropertyValue `
                        $command `
                        'AllowedExecutablePaths'
                )
            )
            $helpers = @(
                ConvertTo-BoostLabTrustedInstallerStringArray (
                    Get-BoostLabTrustedInstallerPropertyValue `
                        $command `
                        'AllowedHelperIds'
                )
            )
            if ($executables.Count -eq 0 -and $helpers.Count -eq 0) {
                $errors.Add(
                    "Command '$commandId' requires an executable or helper."
                )
            }
            foreach ($executable in $executables) {
                try {
                    $fullPath = ConvertTo-BoostLabTrustedInstallerFullPath `
                        $executable
                    if (
                        [IO.Path]::GetFileName($fullPath) -in
                        @($Policy['BlockedExternalElevationTools'])
                    ) {
                        $errors.Add(
                            'External elevation executable is denied: ' +
                            [IO.Path]::GetFileName($fullPath)
                        )
                    }
                }
                catch {
                    $errors.Add("Command '$commandId' has an untrusted path.")
                }
            }
            foreach ($helperId in $helpers) {
                if (-not (Test-BoostLabTrustedInstallerExactIdentifier $helperId)) {
                    $errors.Add("Command '$commandId' has an invalid helper id.")
                }
            }
            foreach ($argument in @(
                Get-BoostLabTrustedInstallerPropertyValue `
                    $command `
                    'AllowedArguments'
            )) {
                $name = [string](
                    Get-BoostLabTrustedInstallerPropertyValue $argument 'Name'
                )
                $value = [string](
                    Get-BoostLabTrustedInstallerPropertyValue $argument 'Value'
                )
                if (
                    -not (Test-BoostLabTrustedInstallerExactIdentifier $name) -or
                    [string]::IsNullOrWhiteSpace($value) -or
                    $value.Contains("`r") -or
                    $value.Contains("`n") -or
                    (Test-BoostLabTrustedInstallerRawCommand $argument)
                ) {
                    $errors.Add(
                        "Command '$commandId' has an invalid argument token."
                    )
                }
            }
            foreach ($workingDirectory in ConvertTo-BoostLabTrustedInstallerStringArray (
                Get-BoostLabTrustedInstallerPropertyValue `
                    $command `
                    'AllowedWorkingDirectories'
            )) {
                try {
                    ConvertTo-BoostLabTrustedInstallerFullPath `
                        $workingDirectory | Out-Null
                }
                catch {
                    $errors.Add(
                        "Command '$commandId' has an untrusted working directory."
                    )
                }
            }
        }

        foreach ($booleanField in @(
            'RequiresActionPlanConfirmation'
            'RequiresAdministratorHost'
            'RequiresStateCapture'
            'RequiresVerificationPlan'
            'AllowProtectedTargets'
            'AllowCancellation'
        )) {
            if (
                (
                    Get-BoostLabTrustedInstallerPropertyValue `
                        $scope `
                        $booleanField
                ) -isnot [bool]
            ) {
                $errors.Add("Scope '$scopeId' $booleanField must be Boolean.")
            }
        }
        foreach ($requiredTrue in @(
            'RequiresActionPlanConfirmation'
            'RequiresAdministratorHost'
            'RequiresStateCapture'
            'RequiresVerificationPlan'
        )) {
            if (-not [bool](
                Get-BoostLabTrustedInstallerPropertyValue $scope $requiredTrue
            )) {
                $errors.Add("Scope '$scopeId' must set $requiredTrue.")
            }
        }
        if (
            [string](
                Get-BoostLabTrustedInstallerPropertyValue `
                    $scope `
                    'RiskClassification'
            ) -ne 'High'
        ) {
            $errors.Add("Scope '$scopeId' must be High risk.")
        }
        $timeout = 0
        if (
            -not [int]::TryParse(
                [string](
                    Get-BoostLabTrustedInstallerPropertyValue `
                        $scope `
                        'TimeoutSeconds'
                ),
                [ref]$timeout
            ) -or
            $timeout -le 0
        ) {
            $errors.Add("Scope '$scopeId' requires a positive timeout.")
        }
        if (
            @(
                ConvertTo-BoostLabTrustedInstallerStringArray (
                    Get-BoostLabTrustedInstallerPropertyValue `
                        $scope `
                        'LoggingRequirements'
                )
            ).Count -eq 0
        ) {
            $errors.Add("Scope '$scopeId' requires logging requirements.")
        }
        if (
            [string]::IsNullOrWhiteSpace(
                [string](
                    Get-BoostLabTrustedInstallerPropertyValue `
                        $scope `
                        'RecoveryBehavior'
                )
            )
        ) {
            $errors.Add("Scope '$scopeId' requires recovery behavior.")
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

function Find-BoostLabTrustedInstallerScope {
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

    foreach ($scope in @($Policy['TrustedInstallerScopes'])) {
        if (
            [string](
                Get-BoostLabTrustedInstallerPropertyValue $scope 'ScopeId'
            ) -eq $ScopeId -and
            $ToolId -in (ConvertTo-BoostLabTrustedInstallerStringArray (
                Get-BoostLabTrustedInstallerPropertyValue $scope 'ToolIds'
            )) -and
            $ActionId -in (ConvertTo-BoostLabTrustedInstallerStringArray (
                Get-BoostLabTrustedInstallerPropertyValue $scope 'ActionIds'
            ))
        ) {
            return $scope
        }
    }
    return $null
}

function Find-BoostLabTrustedInstallerCommand {
    param(
        [Parameter(Mandatory)]
        [object]$Scope,

        [Parameter(Mandatory)]
        [string]$CommandId
    )

    return @(
        Get-BoostLabTrustedInstallerPropertyValue $Scope 'Commands'
    ) |
        Where-Object {
            [string](
                Get-BoostLabTrustedInstallerPropertyValue $_ 'CommandId'
            ) -eq $CommandId
        } |
        Select-Object -First 1
}

function Test-BoostLabTrustedInstallerArguments {
    param(
        [AllowNull()]
        [object]$Arguments,

        [Parameter(Mandatory)]
        [object]$CommandPolicy
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $requested = @($Arguments)
    $allowed = @(
        Get-BoostLabTrustedInstallerPropertyValue `
            $CommandPolicy `
            'AllowedArguments'
    )
    if ($requested.Count -ne $allowed.Count) {
        $errors.Add('Argument token count does not match policy.')
    }
    foreach ($argument in $requested) {
        if (
            $argument -is [string] -or
            (Test-BoostLabTrustedInstallerRawCommand $argument)
        ) {
            $errors.Add('Raw shell argument strings are denied.')
            continue
        }
        $name = [string](
            Get-BoostLabTrustedInstallerPropertyValue $argument 'Name'
        )
        $value = [string](
            Get-BoostLabTrustedInstallerPropertyValue $argument 'Value'
        )
        $match = $allowed |
            Where-Object {
                [string](
                    Get-BoostLabTrustedInstallerPropertyValue $_ 'Name'
                ) -eq $name -and
                [string](
                    Get-BoostLabTrustedInstallerPropertyValue $_ 'Value'
                ) -eq $value
            } |
            Select-Object -First 1
        if ($null -eq $match) {
            $errors.Add("Argument token is not approved: $name")
        }
    }
    return [pscustomobject]@{
        IsValid = $errors.Count -eq 0
        Errors  = $errors.ToArray()
    }
}

function Test-BoostLabTrustedInstallerTargets {
    param(
        [AllowNull()]
        [object]$Targets,

        [Parameter(Mandatory)]
        [object]$Scope,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Policy
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    if ($null -eq $Targets) {
        $errors.Add('TrustedInstaller targets are missing.')
        return [pscustomobject]@{
            IsValid = $false
            Errors  = $errors.ToArray()
        }
    }
    $allowProtected = [bool](
        Get-BoostLabTrustedInstallerPropertyValue `
            $Scope `
            'AllowProtectedTargets'
    )
    $targetCount = 0

    foreach ($filePath in ConvertTo-BoostLabTrustedInstallerStringArray (
        Get-BoostLabTrustedInstallerPropertyValue $Targets 'Files'
    )) {
        $targetCount++
        try {
            $fullPath = ConvertTo-BoostLabTrustedInstallerFullPath $filePath
            $allowed = @(
                ConvertTo-BoostLabTrustedInstallerStringArray (
                    Get-BoostLabTrustedInstallerPropertyValue `
                        $Scope `
                        'AllowedTargetFiles'
                )
            ) | ForEach-Object {
                ConvertTo-BoostLabTrustedInstallerFullPath $_
            }
            if ($fullPath -notin $allowed) {
                $errors.Add("File target is outside the exact scope: $fullPath")
            }
            $root = [IO.Path]::GetPathRoot($fullPath).TrimEnd('\', '/')
            if ($fullPath -eq $root) {
                $errors.Add('Drive-root file targets are denied.')
            }
            foreach ($protectedRoot in @(
                $env:SystemRoot
                $env:ProgramFiles
                ${env:ProgramFiles(x86)}
            ) | Where-Object { $_ }) {
                $fullProtectedRoot = ConvertTo-BoostLabTrustedInstallerFullPath `
                    $protectedRoot
                if (
                    (
                        $fullPath.Equals(
                            $fullProtectedRoot,
                            [StringComparison]::OrdinalIgnoreCase
                        ) -or
                        $fullPath.StartsWith(
                            $fullProtectedRoot + '\',
                            [StringComparison]::OrdinalIgnoreCase
                        )
                    ) -and
                    -not $allowProtected
                ) {
                    $errors.Add(
                        "Protected file target requires explicit approval: $fullPath"
                    )
                }
            }
        }
        catch {
            $errors.Add("Invalid or untrusted file target: $filePath")
        }
    }

    foreach ($registryPath in ConvertTo-BoostLabTrustedInstallerStringArray (
        Get-BoostLabTrustedInstallerPropertyValue $Targets 'RegistryPaths'
    )) {
        $targetCount++
        try {
            $normalized = ConvertTo-BoostLabTrustedInstallerRegistryPath `
                $registryPath
            $allowed = @(
                ConvertTo-BoostLabTrustedInstallerStringArray (
                    Get-BoostLabTrustedInstallerPropertyValue `
                        $Scope `
                        'AllowedRegistryPaths'
                )
            ) | ForEach-Object {
                ConvertTo-BoostLabTrustedInstallerRegistryPath $_
            }
            if ($normalized -notin $allowed) {
                $errors.Add("Registry target is outside the exact scope.")
            }
            foreach ($prefix in @($Policy['ProtectedRegistryPrefixes'])) {
                $normalizedPrefix = ConvertTo-BoostLabTrustedInstallerRegistryPath `
                    $prefix
                if (
                    (
                        $normalized.Equals(
                            $normalizedPrefix,
                            [StringComparison]::OrdinalIgnoreCase
                        ) -or
                        $normalized.StartsWith(
                            $normalizedPrefix + '\',
                            [StringComparison]::OrdinalIgnoreCase
                        )
                    ) -and
                    -not $allowProtected
                ) {
                    $errors.Add(
                        "Protected registry target requires explicit approval."
                    )
                }
            }
        }
        catch {
            $errors.Add("Invalid registry target: $registryPath")
        }
    }

    foreach ($serviceName in ConvertTo-BoostLabTrustedInstallerStringArray (
        Get-BoostLabTrustedInstallerPropertyValue $Targets 'Services'
    )) {
        $targetCount++
        if (-not (Test-BoostLabTrustedInstallerExactIdentifier $serviceName)) {
            $errors.Add('Service targets must use exact names.')
            continue
        }
        if (
            $serviceName -notin (
                ConvertTo-BoostLabTrustedInstallerStringArray (
                    Get-BoostLabTrustedInstallerPropertyValue `
                        $Scope `
                        'AllowedServiceNames'
                )
            )
        ) {
            $errors.Add("Service target is outside the exact scope.")
        }
        if (
            $serviceName -in @($Policy['ProtectedServiceNames']) -and
            -not $allowProtected
        ) {
            $errors.Add("Protected service requires explicit approval.")
        }
    }

    foreach ($packageIdentity in ConvertTo-BoostLabTrustedInstallerStringArray (
        Get-BoostLabTrustedInstallerPropertyValue $Targets 'Packages'
    )) {
        $targetCount++
        if (-not (Test-BoostLabTrustedInstallerExactIdentifier $packageIdentity)) {
            $errors.Add('Package targets must use exact identities.')
            continue
        }
        if (
            $packageIdentity -notin (
                ConvertTo-BoostLabTrustedInstallerStringArray (
                    Get-BoostLabTrustedInstallerPropertyValue `
                        $Scope `
                        'AllowedPackageIdentities'
                )
            )
        ) {
            $errors.Add("Package target is outside the exact scope.")
        }
        foreach ($prefix in @($Policy['ProtectedPackagePrefixes'])) {
            if (
                $packageIdentity.StartsWith(
                    [string]$prefix,
                    [StringComparison]::OrdinalIgnoreCase
                ) -and
                -not $allowProtected
            ) {
                $errors.Add("Protected package requires explicit approval.")
            }
        }
    }
    if ($targetCount -eq 0) {
        $errors.Add('At least one exact target is required.')
    }
    return [pscustomobject]@{
        IsValid = $errors.Count -eq 0
        Errors  = $errors.ToArray()
    }
}

function Test-BoostLabTrustedInstallerStateReferences {
    param(
        [AllowNull()]
        [object]$References,

        [Parameter(Mandatory)]
        [object]$Scope
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $referenceArray = @($References)
    $requiredFoundations = @(
        ConvertTo-BoostLabTrustedInstallerStringArray (
            Get-BoostLabTrustedInstallerPropertyValue `
                $Scope `
                'RequiredFoundations'
        )
    )
    if (
        [bool](
            Get-BoostLabTrustedInstallerPropertyValue `
                $Scope `
                'RequiresStateCapture'
        ) -and
        $referenceArray.Count -eq 0
    ) {
        $errors.Add('Required state-capture references are missing.')
    }
    foreach ($foundation in $requiredFoundations) {
        $match = $referenceArray |
            Where-Object {
                [string](
                    Get-BoostLabTrustedInstallerPropertyValue $_ 'Foundation'
                ) -eq $foundation -and
                [bool](
                    Get-BoostLabTrustedInstallerPropertyValue $_ 'Verified'
                ) -and
                -not [string]::IsNullOrWhiteSpace(
                    [string](
                        Get-BoostLabTrustedInstallerPropertyValue $_ 'ReferenceId'
                    )
                ) -and
                -not [string]::IsNullOrWhiteSpace(
                    [string](
                        Get-BoostLabTrustedInstallerPropertyValue $_ 'RecordPath'
                    )
                ) -and
                -not [string]::IsNullOrWhiteSpace(
                    [string](
                        Get-BoostLabTrustedInstallerPropertyValue $_ 'RecordHash'
                    )
                )
            } |
            Select-Object -First 1
        if ($null -eq $match) {
            $errors.Add(
                "Required verified foundation reference is missing: $foundation"
            )
        }
    }
    return [pscustomobject]@{
        IsValid = $errors.Count -eq 0
        Errors  = $errors.ToArray()
    }
}

function Test-BoostLabTrustedInstallerVerificationPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [object]$VerificationPlan
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    if ($null -eq $VerificationPlan) {
        $errors.Add('Structured verification plan is missing.')
    }
    elseif (Test-BoostLabTrustedInstallerRawCommand $VerificationPlan) {
        $errors.Add('Verification plans cannot contain raw command text.')
    }
    else {
        $checks = @(
            Get-BoostLabTrustedInstallerPropertyValue `
                $VerificationPlan `
                'Checks'
        )
        if ($checks.Count -eq 0) {
            $errors.Add('Verification plan requires at least one check.')
        }
        foreach ($check in $checks) {
            foreach ($field in @(
                'Name'
                'MethodId'
                'TargetReference'
                'Expected'
            )) {
                if (
                    [string]::IsNullOrWhiteSpace(
                        [string](
                            Get-BoostLabTrustedInstallerPropertyValue `
                                $check `
                                $field
                        )
                    )
                ) {
                    $errors.Add("Verification check is missing field: $field")
                }
            }
            if (Test-BoostLabTrustedInstallerRawCommand $check) {
                $errors.Add('Verification checks cannot contain raw commands.')
            }
        }
    }
    return [pscustomobject]@{
        IsValid = $errors.Count -eq 0
        Status  = if ($errors.Count -eq 0) { 'Valid' } else { 'Blocked' }
        Errors  = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function Test-BoostLabTrustedInstallerRequest {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [object]$Request,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabTrustedInstallerPolicy
    }
    $errors = [System.Collections.Generic.List[string]]::new()
    $scope = $null
    $commandPolicy = $null
    $policyValidation = Test-BoostLabTrustedInstallerPolicy -Policy $Policy
    if (-not $policyValidation.IsValid) {
        $errors.AddRange([string[]]@($policyValidation.Errors))
    }
    if ($null -eq $Request) {
        $errors.Add('TrustedInstaller request is missing.')
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
            'RequestedExecutionIdentity'
            'RequestedCommandId'
            'CommandDescriptor'
            'WorkingDirectory'
            'Targets'
            'RequiredFoundations'
            'ActionPlan'
            'Confirmed'
            'AdministratorHostVerified'
            'StateCaptureReferences'
            'VerificationPlan'
            'RiskClassification'
            'TimeoutSeconds'
            'LoggingRequirements'
            'CancellationEligible'
            'RecoveryBehavior'
            'IsTestRequest'
        )) {
            if (-not (Test-BoostLabTrustedInstallerPropertyExists $Request $field)) {
                $errors.Add("TrustedInstaller request is missing field: $field")
            }
        }
        if (
            [string]$Request.SchemaVersion -ne
            $script:BoostLabTrustedInstallerSchemaVersion
        ) {
            $errors.Add('TrustedInstaller request schema is unsupported.')
        }
        if (
            [string]$Request.RequestedExecutionIdentity -ne
            $script:BoostLabTrustedInstallerIdentity
        ) {
            $errors.Add('Requested execution identity is not TrustedInstaller.')
        }
        if (
            (Test-BoostLabTrustedInstallerRawCommand $Request) -or
            (
                Test-BoostLabTrustedInstallerRawCommand `
                    $Request.CommandDescriptor
            )
        ) {
            $errors.Add('Raw shell command strings are denied.')
        }

        $scope = Find-BoostLabTrustedInstallerScope `
            -ToolId ([string]$Request.ToolId) `
            -ActionId ([string]$Request.ActionId) `
            -ScopeId ([string]$Request.ScopeId) `
            -Policy $Policy
        if ($null -eq $scope) {
            $errors.Add(
                'Tool, action, and TrustedInstaller scope are not approved.'
            )
        }
        else {
            $commandPolicy = Find-BoostLabTrustedInstallerCommand `
                -Scope $scope `
                -CommandId ([string]$Request.RequestedCommandId)
            if ($null -eq $commandPolicy) {
                $errors.Add('Requested TrustedInstaller command id is unknown.')
            }
            else {
                $descriptor = $Request.CommandDescriptor
                $executablePath = [string](
                    Get-BoostLabTrustedInstallerPropertyValue `
                        $descriptor `
                        'ExecutablePath'
                )
                $helperId = [string](
                    Get-BoostLabTrustedInstallerPropertyValue `
                        $descriptor `
                        'HelperId'
                )
                if (
                    [string]::IsNullOrWhiteSpace($executablePath) -eq
                    [string]::IsNullOrWhiteSpace($helperId)
                ) {
                    $errors.Add(
                        'Command descriptor requires exactly one executable ' +
                        'path or approved helper id.'
                    )
                }
                if (-not [string]::IsNullOrWhiteSpace($executablePath)) {
                    try {
                        $fullPath = ConvertTo-BoostLabTrustedInstallerFullPath `
                            $executablePath
                        $allowed = @(
                            ConvertTo-BoostLabTrustedInstallerStringArray (
                                Get-BoostLabTrustedInstallerPropertyValue `
                                    $commandPolicy `
                                    'AllowedExecutablePaths'
                            )
                        ) | ForEach-Object {
                            ConvertTo-BoostLabTrustedInstallerFullPath $_
                        }
                        if ($fullPath -notin $allowed) {
                            $errors.Add(
                                'Executable path is outside the exact allowlist.'
                            )
                        }
                        if (
                            [IO.Path]::GetFileName($fullPath) -in
                            @($Policy['BlockedExternalElevationTools'])
                        ) {
                            $errors.Add('External elevation executables are denied.')
                        }
                    }
                    catch {
                        $errors.Add('Executable path is untrusted or invalid.')
                    }
                }
                if (
                    -not [string]::IsNullOrWhiteSpace($helperId) -and
                    $helperId -notin (
                        ConvertTo-BoostLabTrustedInstallerStringArray (
                            Get-BoostLabTrustedInstallerPropertyValue `
                                $commandPolicy `
                                'AllowedHelperIds'
                        )
                    )
                ) {
                    $errors.Add('Helper id is outside the exact allowlist.')
                }
                $argumentValidation = Test-BoostLabTrustedInstallerArguments `
                    -Arguments (
                        Get-BoostLabTrustedInstallerPropertyValue `
                            $descriptor `
                            'Arguments'
                    ) `
                    -CommandPolicy $commandPolicy
                if (-not $argumentValidation.IsValid) {
                    $errors.AddRange([string[]]@($argumentValidation.Errors))
                }
                try {
                    $workingDirectory = ConvertTo-BoostLabTrustedInstallerFullPath `
                        ([string]$Request.WorkingDirectory)
                    $allowedDirectories = @(
                        ConvertTo-BoostLabTrustedInstallerStringArray (
                            Get-BoostLabTrustedInstallerPropertyValue `
                                $commandPolicy `
                                'AllowedWorkingDirectories'
                        )
                    ) | ForEach-Object {
                        ConvertTo-BoostLabTrustedInstallerFullPath $_
                    }
                    if ($workingDirectory -notin $allowedDirectories) {
                        $errors.Add(
                            'Working directory is outside the exact allowlist.'
                        )
                    }
                }
                catch {
                    $errors.Add('Working directory is untrusted or invalid.')
                }
            }

            $targetValidation = Test-BoostLabTrustedInstallerTargets `
                -Targets $Request.Targets `
                -Scope $scope `
                -Policy $Policy
            if (-not $targetValidation.IsValid) {
                $errors.AddRange([string[]]@($targetValidation.Errors))
            }
            $stateValidation = Test-BoostLabTrustedInstallerStateReferences `
                -References @($Request.StateCaptureReferences) `
                -Scope $scope
            if (-not $stateValidation.IsValid) {
                $errors.AddRange([string[]]@($stateValidation.Errors))
            }
            $verificationValidation = Test-BoostLabTrustedInstallerVerificationPlan `
                -VerificationPlan $Request.VerificationPlan
            if (-not $verificationValidation.IsValid) {
                $errors.AddRange([string[]]@($verificationValidation.Errors))
            }
        }

        if ($null -eq $Request.ActionPlan) {
            $errors.Add('A matching Action Plan is required.')
        }
        else {
            if ([string]$Request.ActionPlan.ToolId -ne [string]$Request.ToolId) {
                $errors.Add('Action Plan tool identity does not match.')
            }
            if ([string]$Request.ActionPlan.Action -ne [string]$Request.ActionId) {
                $errors.Add('Action Plan action identity does not match.')
            }
            if (
                -not [bool]$Request.ActionPlan.NeedsExplicitConfirmation -or
                -not [bool]$Request.ActionPlan.UsesTrustedInstaller
            ) {
                $errors.Add(
                    'Action Plan must declare TrustedInstaller and confirmation.'
                )
            }
        }
        if (-not [bool]$Request.Confirmed) {
            $errors.Add('Explicit TrustedInstaller confirmation is required.')
        }
        if (-not [bool]$Request.AdministratorHostVerified) {
            $errors.Add('A verified Administrator host process is required.')
        }
        if ([string]$Request.RiskClassification -ne 'High') {
            $errors.Add('TrustedInstaller requests must be High risk.')
        }
        $timestamp = [datetime]::MinValue
        if (-not [datetime]::TryParse(
            [string]$Request.Timestamp,
            [ref]$timestamp
        )) {
            $errors.Add('TrustedInstaller request timestamp is invalid.')
        }
        elseif ($Policy.Contains('MaxRequestAgeMinutes')) {
            $age = (Get-Date).ToUniversalTime() - $timestamp.ToUniversalTime()
            if ($age.TotalMinutes -gt [int]$Policy['MaxRequestAgeMinutes']) {
                $errors.Add('TrustedInstaller request is stale.')
            }
        }
    }
    return [pscustomobject]@{
        IsAllowed = $errors.Count -eq 0
        Status    = if ($errors.Count -eq 0) { 'Allowed' } else { 'Blocked' }
        Scope     = $scope
        Command   = $commandPolicy
        Errors    = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function New-BoostLabTrustedInstallerRequest {
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
        [string]$CommandId,

        [Parameter(Mandatory)]
        [object]$CommandDescriptor,

        [Parameter(Mandatory)]
        [string]$WorkingDirectory,

        [Parameter(Mandatory)]
        [object]$Targets,

        [Parameter(Mandatory)]
        [object]$ActionPlan,

        [bool]$Confirmed,

        [bool]$AdministratorHostVerified,

        [AllowNull()]
        [object[]]$StateCaptureReferences,

        [AllowNull()]
        [object]$VerificationPlan,

        [bool]$IsTestRequest = $false,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($null -eq $Policy) {
        $Policy = Get-BoostLabTrustedInstallerPolicy
    }
    $scope = Find-BoostLabTrustedInstallerScope `
        -ToolId $ToolId `
        -ActionId $ActionId `
        -ScopeId $ScopeId `
        -Policy $Policy
    $operationId = [guid]::NewGuid().ToString()
    $request = [pscustomobject][ordered]@{
        OperationId                = $operationId
        ToolId                     = $ToolId
        ActionId                   = $ActionId
        Timestamp                  = (Get-Date).ToUniversalTime().ToString('o')
        SchemaVersion              = $script:BoostLabTrustedInstallerSchemaVersion
        BoostLabVersion            = 'Foundation'
        ScopeId                    = $ScopeId
        RequestedExecutionIdentity = $script:BoostLabTrustedInstallerIdentity
        RequestedCommandId         = $CommandId
        CommandDescriptor          = $CommandDescriptor
        WorkingDirectory           = $WorkingDirectory
        Targets                    = $Targets
        RequiredFoundations        = if ($null -ne $scope) {
            @(
                Get-BoostLabTrustedInstallerPropertyValue `
                    $scope `
                    'RequiredFoundations'
            )
        }
        else {
            @()
        }
        ActionPlan                 = $ActionPlan
        Confirmed                  = $Confirmed
        AdministratorHostVerified  = $AdministratorHostVerified
        StateCaptureReferences     = @($StateCaptureReferences)
        VerificationPlan           = $VerificationPlan
        RiskClassification         = if ($null -ne $scope) {
            [string](
                Get-BoostLabTrustedInstallerPropertyValue `
                    $scope `
                    'RiskClassification'
            )
        }
        else {
            'High'
        }
        TimeoutSeconds             = if ($null -ne $scope) {
            [int](
                Get-BoostLabTrustedInstallerPropertyValue `
                    $scope `
                    'TimeoutSeconds'
            )
        }
        else {
            0
        }
        LoggingRequirements        = if ($null -ne $scope) {
            @(
                Get-BoostLabTrustedInstallerPropertyValue `
                    $scope `
                    'LoggingRequirements'
            )
        }
        else {
            @()
        }
        CancellationEligible       = if ($null -ne $scope) {
            [bool](
                Get-BoostLabTrustedInstallerPropertyValue `
                    $scope `
                    'AllowCancellation'
            )
        }
        else {
            $false
        }
        RecoveryBehavior           = if ($null -ne $scope) {
            [string](
                Get-BoostLabTrustedInstallerPropertyValue `
                    $scope `
                    'RecoveryBehavior'
            )
        }
        else {
            ''
        }
        IsTestRequest              = $IsTestRequest
    }
    $validation = Test-BoostLabTrustedInstallerRequest `
        -Request $request `
        -Policy $Policy
    return [pscustomobject]@{
        Success     = $validation.IsAllowed
        Status      = $validation.Status
        OperationId = $operationId
        Request     = $request
        Message     = if ($validation.IsAllowed) {
            'TrustedInstaller request passed structural validation.'
        }
        else {
            'TrustedInstaller request was blocked by policy.'
        }
        Errors      = @($validation.Errors)
        Timestamp   = Get-Date
    }
}

function New-BoostLabTrustedInstallerPlan {
    [CmdletBinding(DefaultParameterSetName = 'Legacy')]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Legacy')]
        [System.Collections.IDictionary]$ToolMetadata,

        [Parameter(Mandatory, ParameterSetName = 'Legacy')]
        [string]$ActionName,

        [Parameter(Mandatory, ParameterSetName = 'Request')]
        [object]$Request,

        [Parameter(ParameterSetName = 'Request')]
        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    if ($PSCmdlet.ParameterSetName -eq 'Legacy') {
        $capabilities = if (
            $ToolMetadata.Contains('Capabilities') -and
            $ToolMetadata['Capabilities'] -is [System.Collections.IDictionary]
        ) {
            $ToolMetadata['Capabilities']
        }
        else {
            @{}
        }
        return [pscustomobject]@{
            ToolId                    = [string]$ToolMetadata['Id']
            ToolTitle                 = [string]$ToolMetadata['Title']
            Action                    = $ActionName
            Status                    = 'NotImplemented'
            UsesTrustedInstaller      = (
                $capabilities.Contains('UsesTrustedInstaller') -and
                [bool]$capabilities['UsesTrustedInstaller']
            )
            RequiresAdmin             = $true
            NeedsExplicitConfirmation = $true
            Summary                   = 'Describe a future approved TrustedInstaller request without executing it.'
            PlannedChanges            = @('No command will execute in Phase 42.')
            Message                   = 'TrustedInstaller execution remains unavailable.'
            Timestamp                 = Get-Date
        }
    }

    $validation = Test-BoostLabTrustedInstallerRequest `
        -Request $Request `
        -Policy $Policy
    return [pscustomobject][ordered]@{
        OperationId               = [string]$Request.OperationId
        ToolId                    = [string]$Request.ToolId
        ActionId                  = [string]$Request.ActionId
        RequestedIdentity         = [string]$Request.RequestedExecutionIdentity
        CommandId                 = [string]$Request.RequestedCommandId
        Targets                   = $Request.Targets
        RequiredFoundations       = @($Request.RequiredFoundations)
        StateCaptureReferences    = @($Request.StateCaptureReferences)
        VerificationPlan          = $Request.VerificationPlan
        RiskClassification        = [string]$Request.RiskClassification
        TimeoutSeconds            = [int]$Request.TimeoutSeconds
        LoggingRequirements       = @($Request.LoggingRequirements)
        CancellationEligible      = [bool]$Request.CancellationEligible
        RecoveryBehavior          = [string]$Request.RecoveryBehavior
        RequiresAdmin             = $true
        NeedsExplicitConfirmation = $true
        IsDryRun                  = $true
        IsAllowed                 = $validation.IsAllowed
        Status                    = $validation.Status
        Message                   = if ($validation.IsAllowed) {
            'TrustedInstaller dry-run plan passed structural validation.'
        }
        else {
            'TrustedInstaller planning was blocked.'
        }
        Errors                    = @($validation.Errors)
        Timestamp                 = Get-Date
    }
}

function Invoke-BoostLabTrustedInstallerCommand {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$ToolMetadata,

        [Parameter(Mandatory)]
        [string]$ActionName,

        [string]$CommandDescription = ''
    )

    return [pscustomobject]@{
        Success         = $false
        Status          = 'NotImplemented'
        ToolId          = [string]$ToolMetadata['Id']
        ToolTitle       = [string]$ToolMetadata['Title']
        Action          = $ActionName
        Message         = 'TrustedInstaller command execution is not implemented yet.'
        CommandExecuted = $false
        ProcessStarted  = $false
        RestartRequired = $false
        Timestamp       = Get-Date
    }
}

Export-ModuleMember -Function @(
    'Get-BoostLabTrustedInstallerPolicy'
    'Test-BoostLabTrustedInstallerSupported'
    'Test-BoostLabTrustedInstallerPolicy'
    'Test-BoostLabTrustedInstallerVerificationPlan'
    'Test-BoostLabTrustedInstallerRequest'
    'New-BoostLabTrustedInstallerRequest'
    'New-BoostLabTrustedInstallerPlan'
    'Invoke-BoostLabTrustedInstallerCommand'
)
