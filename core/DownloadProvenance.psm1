Set-StrictMode -Version Latest

$script:BoostLabArtifactManifestPath = Join-Path `
    (Split-Path -Parent $PSScriptRoot) `
    'config\ArtifactProvenance.psd1'

function Get-BoostLabProvenancePropertyValue {
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

function Get-BoostLabArtifactProvenanceManifest {
    [CmdletBinding()]
    [OutputType([System.Collections.IDictionary])]
    param(
        [string]$ManifestPath = $script:BoostLabArtifactManifestPath
    )

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        throw "Artifact provenance manifest was not found: $ManifestPath"
    }

    return Import-PowerShellDataFile -LiteralPath $ManifestPath
}

function Test-BoostLabArtifactDefinition {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Artifact
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $requiredFields = @(
        'Id'
        'DisplayName'
        'SourceUrl'
        'ExpectedSha256'
        'ExpectedFileName'
        'ExpectedSizeBytes'
        'MinimumSizeBytes'
        'MaximumSizeBytes'
        'ArtifactType'
        'ExpectedPublisher'
        'SourceToolIds'
        'LicenseNote'
        'AllowExecution'
        'RequiresAdmin'
        'CanReboot'
        'VerificationRequirements'
        'ApprovalStatus'
    )

    foreach ($field in $requiredFields) {
        $value = Get-BoostLabProvenancePropertyValue -InputObject $Artifact -Name $field
        if ($null -eq $value) {
            $errors.Add("Artifact definition is missing field: $field")
        }
    }

    $id = [string](Get-BoostLabProvenancePropertyValue -InputObject $Artifact -Name 'Id')
    $displayName = [string](Get-BoostLabProvenancePropertyValue -InputObject $Artifact -Name 'DisplayName')
    $sourceUrl = [string](Get-BoostLabProvenancePropertyValue -InputObject $Artifact -Name 'SourceUrl')
    $expectedHash = [string](Get-BoostLabProvenancePropertyValue -InputObject $Artifact -Name 'ExpectedSha256')
    $expectedFileName = [string](Get-BoostLabProvenancePropertyValue -InputObject $Artifact -Name 'ExpectedFileName')
    $artifactType = [string](Get-BoostLabProvenancePropertyValue -InputObject $Artifact -Name 'ArtifactType')
    $expectedPublisher = [string](Get-BoostLabProvenancePropertyValue -InputObject $Artifact -Name 'ExpectedPublisher')
    $approvalStatus = [string](Get-BoostLabProvenancePropertyValue -InputObject $Artifact -Name 'ApprovalStatus')
    $allowExecution = [bool](Get-BoostLabProvenancePropertyValue -InputObject $Artifact -Name 'AllowExecution')
    $requirements = @(
        Get-BoostLabProvenancePropertyValue -InputObject $Artifact -Name 'VerificationRequirements'
    )
    $sourceToolIds = @(
        Get-BoostLabProvenancePropertyValue -InputObject $Artifact -Name 'SourceToolIds'
    )

    if ([string]::IsNullOrWhiteSpace($id)) {
        $errors.Add('Artifact Id cannot be empty.')
    }
    if ([string]::IsNullOrWhiteSpace($displayName)) {
        $errors.Add('Artifact DisplayName cannot be empty.')
    }
    $sourceUri = $null
    if (
        -not [Uri]::TryCreate($sourceUrl, [UriKind]::Absolute, [ref]$sourceUri) -or
        $sourceUri.Scheme -ne [Uri]::UriSchemeHttps -or
        [string]::IsNullOrWhiteSpace($sourceUri.Host)
    ) {
        $errors.Add('Artifact SourceUrl must be an HTTPS URL.')
    }
    if ($expectedHash -notmatch '^[A-Fa-f0-9]{64}$') {
        $errors.Add('Artifact ExpectedSha256 must be a complete SHA-256 hash.')
    }
    if (
        [string]::IsNullOrWhiteSpace($expectedFileName) -or
        [IO.Path]::GetFileName($expectedFileName) -ne $expectedFileName
    ) {
        $errors.Add('Artifact ExpectedFileName must be a file name without a path.')
    }
    if ($artifactType -notin @('NonExecutable', 'Archive', 'Executable', 'Installer')) {
        $errors.Add('Artifact ArtifactType must be NonExecutable, Archive, Executable, or Installer.')
    }
    if ($approvalStatus -notin @('Proposed', 'Approved', 'Revoked')) {
        $errors.Add('Artifact ApprovalStatus must be Proposed, Approved, or Revoked.')
    }
    if ($sourceToolIds.Count -eq 0) {
        $errors.Add('Artifact SourceToolIds must identify at least one future consumer.')
    }
    if ('SHA256' -notin $requirements) {
        $errors.Add('Artifact VerificationRequirements must include SHA256.')
    }
    if ('FileName' -notin $requirements) {
        $errors.Add('Artifact VerificationRequirements must include FileName.')
    }

    foreach ($booleanField in @('AllowExecution', 'RequiresAdmin', 'CanReboot')) {
        $value = Get-BoostLabProvenancePropertyValue -InputObject $Artifact -Name $booleanField
        if ($value -isnot [bool]) {
            $errors.Add("Artifact $booleanField must be Boolean.")
        }
    }

    foreach ($sizeField in @('ExpectedSizeBytes', 'MinimumSizeBytes', 'MaximumSizeBytes')) {
        $value = Get-BoostLabProvenancePropertyValue -InputObject $Artifact -Name $sizeField
        $parsedValue = 0L
        if (-not [long]::TryParse([string]$value, [ref]$parsedValue) -or $parsedValue -lt 0) {
            $errors.Add("Artifact $sizeField must be a non-negative integer.")
        }
    }

    $minimumSize = [long](Get-BoostLabProvenancePropertyValue -InputObject $Artifact -Name 'MinimumSizeBytes')
    $maximumSize = [long](Get-BoostLabProvenancePropertyValue -InputObject $Artifact -Name 'MaximumSizeBytes')
    if ($minimumSize -gt 0 -and $maximumSize -gt 0 -and $minimumSize -gt $maximumSize) {
        $errors.Add('Artifact MinimumSizeBytes cannot exceed MaximumSizeBytes.')
    }

    $isExecutableType = $artifactType -in @('Executable', 'Installer')
    if ($isExecutableType -and $allowExecution) {
        if ([string]::IsNullOrWhiteSpace($expectedPublisher)) {
            $errors.Add('Executable artifacts allowed to run must declare ExpectedPublisher.')
        }
        if ('AuthenticodeSigner' -notin $requirements) {
            $errors.Add('Executable artifacts allowed to run must require AuthenticodeSigner verification.')
        }
        if ('FileSize' -notin $requirements) {
            $errors.Add('Executable artifacts allowed to run must require FileSize verification.')
        }
        if (
            [long](Get-BoostLabProvenancePropertyValue -InputObject $Artifact -Name 'ExpectedSizeBytes') -le 0 -and
            $minimumSize -le 0 -and
            $maximumSize -le 0
        ) {
            $errors.Add('Executable artifacts allowed to run must declare an expected size or size bounds.')
        }
    }

    return [pscustomobject]@{
        IsValid   = $errors.Count -eq 0
        ArtifactId = $id
        Errors    = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function Test-BoostLabArtifactProvenanceManifest {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [System.Collections.IDictionary]$Manifest
    )

    if ($null -eq $Manifest) {
        $Manifest = Get-BoostLabArtifactProvenanceManifest
    }

    $errors = [System.Collections.Generic.List[string]]::new()
    if (-not $Manifest.Contains('SchemaVersion') -or [string]$Manifest['SchemaVersion'] -ne '1.0') {
        $errors.Add('Artifact manifest SchemaVersion must be 1.0.')
    }
    if (-not $Manifest.Contains('Artifacts')) {
        $errors.Add('Artifact manifest must contain an Artifacts collection.')
    }

    $artifactIds = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $artifacts = @(
        if ($Manifest.Contains('Artifacts')) {
            @($Manifest['Artifacts'])
        }
    )
    foreach ($artifact in $artifacts) {
        $validation = Test-BoostLabArtifactDefinition -Artifact $artifact
        foreach ($validationError in @($validation.Errors)) {
            $errors.Add($validationError)
        }
        if (
            -not [string]::IsNullOrWhiteSpace([string]$validation.ArtifactId) -and
            -not $artifactIds.Add([string]$validation.ArtifactId)
        ) {
            $errors.Add("Artifact id is duplicated: $($validation.ArtifactId)")
        }
    }

    return [pscustomobject]@{
        IsValid      = $errors.Count -eq 0
        ArtifactCount = $artifacts.Count
        Errors       = $errors.ToArray()
        Timestamp    = Get-Date
    }
}

function Get-BoostLabArtifactDefinition {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ArtifactId,

        [AllowNull()]
        [System.Collections.IDictionary]$Manifest
    )

    if ($null -eq $Manifest) {
        $Manifest = Get-BoostLabArtifactProvenanceManifest
    }

    $manifestValidation = Test-BoostLabArtifactProvenanceManifest -Manifest $Manifest
    if (-not $manifestValidation.IsValid) {
        return [pscustomobject]@{
            Found      = $false
            ArtifactId = $ArtifactId
            Artifact   = $null
            Status     = 'Blocked'
            Message    = 'Artifact manifest validation failed.'
            Errors     = @($manifestValidation.Errors)
            Timestamp  = Get-Date
        }
    }

    $artifact = @($Manifest['Artifacts']) |
        Where-Object {
            [string](Get-BoostLabProvenancePropertyValue -InputObject $_ -Name 'Id') -eq $ArtifactId
        } |
        Select-Object -First 1

    if ($null -eq $artifact) {
        return [pscustomobject]@{
            Found      = $false
            ArtifactId = $ArtifactId
            Artifact   = $null
            Status     = 'Blocked'
            Message    = 'Unknown artifact is blocked because it is not listed in the provenance manifest.'
            Errors     = @('Artifact is not listed in the provenance manifest.')
            Timestamp  = Get-Date
        }
    }

    return [pscustomobject]@{
        Found      = $true
        ArtifactId = $ArtifactId
        Artifact   = $artifact
        Status     = 'Found'
        Message    = 'Artifact definition found.'
        Errors     = @()
        Timestamp  = Get-Date
    }
}

function Test-BoostLabArtifactProvenance {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ArtifactId,

        [Parameter(Mandatory)]
        [string]$LocalPath,

        [AllowNull()]
        [System.Collections.IDictionary]$Manifest,

        [AllowNull()]
        [scriptblock]$SignatureInspector
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    $lookup = Get-BoostLabArtifactDefinition -ArtifactId $ArtifactId -Manifest $Manifest
    if (-not $lookup.Found) {
        return [pscustomobject]@{
            Verified    = $false
            Status      = 'Blocked'
            ArtifactId  = $ArtifactId
            Artifact    = $null
            VerifiedPath = ''
            Checks      = @()
            Message     = $lookup.Message
            Errors      = @($lookup.Errors)
            Timestamp   = Get-Date
        }
    }

    $artifact = $lookup.Artifact
    $errors = [System.Collections.Generic.List[string]]::new()
    $approvalStatus = [string](Get-BoostLabProvenancePropertyValue -InputObject $artifact -Name 'ApprovalStatus')
    if ($approvalStatus -ne 'Approved') {
        $errors.Add("Artifact approval status is '$approvalStatus', not Approved.")
    }
    if ($LocalPath -match '^[a-zA-Z][a-zA-Z0-9+.-]*://') {
        $errors.Add('Artifact verification requires a local file path; direct network execution is prohibited.')
    }
    elseif (-not (Test-Path -LiteralPath $LocalPath -PathType Leaf)) {
        $errors.Add("Artifact file was not found: $LocalPath")
    }

    if ($errors.Count -eq 0) {
        $resolvedPath = (Resolve-Path -LiteralPath $LocalPath -ErrorAction Stop).Path
        $expectedFileName = [string](
            Get-BoostLabProvenancePropertyValue -InputObject $artifact -Name 'ExpectedFileName'
        )
        $actualFileName = [IO.Path]::GetFileName($resolvedPath)
        $fileNamePassed = $actualFileName -ceq $expectedFileName
        $checks.Add([pscustomobject]@{
            Name     = 'FileName'
            Expected = $expectedFileName
            Actual   = $actualFileName
            Status   = if ($fileNamePassed) { 'Passed' } else { 'Failed' }
            Message  = if ($fileNamePassed) {
                'Artifact file name matches the manifest.'
            }
            else {
                'Artifact file name does not match the manifest.'
            }
        })
        if (-not $fileNamePassed) {
            $errors.Add('Artifact file name mismatch.')
        }

        $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $resolvedPath).Hash
        $expectedHash = [string](
            Get-BoostLabProvenancePropertyValue -InputObject $artifact -Name 'ExpectedSha256'
        )
        $hashPassed = $actualHash -eq $expectedHash
        $checks.Add([pscustomobject]@{
            Name     = 'SHA256'
            Expected = $expectedHash
            Actual   = $actualHash
            Status   = if ($hashPassed) { 'Passed' } else { 'Failed' }
            Message  = if ($hashPassed) {
                'Artifact SHA-256 matches the manifest.'
            }
            else {
                'Artifact SHA-256 does not match the manifest.'
            }
        })
        if (-not $hashPassed) {
            $errors.Add('Artifact SHA-256 mismatch.')
        }

        $actualSize = (Get-Item -LiteralPath $resolvedPath -ErrorAction Stop).Length
        $expectedSize = [long](
            Get-BoostLabProvenancePropertyValue -InputObject $artifact -Name 'ExpectedSizeBytes'
        )
        $minimumSize = [long](
            Get-BoostLabProvenancePropertyValue -InputObject $artifact -Name 'MinimumSizeBytes'
        )
        $maximumSize = [long](
            Get-BoostLabProvenancePropertyValue -InputObject $artifact -Name 'MaximumSizeBytes'
        )
        $sizePassed = (
            ($expectedSize -le 0 -or $actualSize -eq $expectedSize) -and
            ($minimumSize -le 0 -or $actualSize -ge $minimumSize) -and
            ($maximumSize -le 0 -or $actualSize -le $maximumSize)
        )
        $checks.Add([pscustomobject]@{
            Name     = 'FileSize'
            Expected = if ($expectedSize -gt 0) {
                $expectedSize
            }
            else {
                "Between $minimumSize and $maximumSize bytes"
            }
            Actual   = $actualSize
            Status   = if ($sizePassed) { 'Passed' } else { 'Failed' }
            Message  = if ($sizePassed) {
                'Artifact size matches the manifest constraints.'
            }
            else {
                'Artifact size does not match the manifest constraints.'
            }
        })
        if (-not $sizePassed) {
            $errors.Add('Artifact size mismatch.')
        }

        $artifactType = [string](
            Get-BoostLabProvenancePropertyValue -InputObject $artifact -Name 'ArtifactType'
        )
        $allowExecution = [bool](
            Get-BoostLabProvenancePropertyValue -InputObject $artifact -Name 'AllowExecution'
        )
        if ($artifactType -in @('Executable', 'Installer') -and $allowExecution) {
            $signature = if ($null -ne $SignatureInspector) {
                & $SignatureInspector $resolvedPath
            }
            else {
                Get-AuthenticodeSignature -LiteralPath $resolvedPath
            }
            $signatureStatus = [string](
                Get-BoostLabProvenancePropertyValue -InputObject $signature -Name 'Status'
            )
            $actualPublisher = [string](
                Get-BoostLabProvenancePropertyValue -InputObject $signature -Name 'Publisher'
            )
            if ([string]::IsNullOrWhiteSpace($actualPublisher)) {
                $certificate = Get-BoostLabProvenancePropertyValue `
                    -InputObject $signature `
                    -Name 'SignerCertificate'
                if ($null -ne $certificate) {
                    $actualPublisher = [string](
                        Get-BoostLabProvenancePropertyValue `
                            -InputObject $certificate `
                            -Name 'Subject'
                    )
                }
            }
            $expectedPublisher = [string](
                Get-BoostLabProvenancePropertyValue -InputObject $artifact -Name 'ExpectedPublisher'
            )
            $signaturePassed = (
                $signatureStatus -eq 'Valid' -and
                $actualPublisher -like "*$expectedPublisher*"
            )
            $checks.Add([pscustomobject]@{
                Name     = 'AuthenticodeSigner'
                Expected = $expectedPublisher
                Actual   = "$signatureStatus; $actualPublisher"
                Status   = if ($signaturePassed) { 'Passed' } else { 'Failed' }
                Message  = if ($signaturePassed) {
                    'Artifact signature and publisher match the manifest.'
                }
                else {
                    'Artifact signature or publisher does not match the manifest.'
                }
            })
            if (-not $signaturePassed) {
                $errors.Add('Artifact Authenticode signer verification failed.')
            }
        }
    }

    $verified = $errors.Count -eq 0
    return [pscustomobject]@{
        Verified     = $verified
        Status       = if ($verified) { 'Verified' } else { 'Blocked' }
        ArtifactId   = $ArtifactId
        Artifact     = $artifact
        VerifiedPath = if ($verified) {
            (Resolve-Path -LiteralPath $LocalPath -ErrorAction Stop).Path
        }
        else {
            ''
        }
        Checks       = $checks.ToArray()
        Message      = if ($verified) {
            'Artifact provenance verification passed.'
        }
        else {
            'Artifact provenance verification failed; use is blocked.'
        }
        Errors       = $errors.ToArray()
        Timestamp    = Get-Date
    }
}

function New-BoostLabArtifactDownloadRequest {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ArtifactId,

        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ActionId,

        [AllowNull()]
        [System.Collections.IDictionary]$Manifest
    )

    $lookup = Get-BoostLabArtifactDefinition -ArtifactId $ArtifactId -Manifest $Manifest
    return [pscustomobject]@{
        Allowed         = $false
        Status          = if ($lookup.Found) { 'NotImplemented' } else { 'Blocked' }
        ArtifactId      = $ArtifactId
        ToolId          = $ToolId
        ActionId        = $ActionId
        DownloadStarted = $false
        Message         = if ($lookup.Found) {
            'Download execution is not implemented. A future approved downloader must verify provenance before use.'
        }
        else {
            $lookup.Message
        }
        Timestamp       = Get-Date
    }
}

Export-ModuleMember -Function @(
    'Get-BoostLabArtifactProvenanceManifest'
    'Test-BoostLabArtifactDefinition'
    'Test-BoostLabArtifactProvenanceManifest'
    'Get-BoostLabArtifactDefinition'
    'Test-BoostLabArtifactProvenance'
    'New-BoostLabArtifactDownloadRequest'
)
