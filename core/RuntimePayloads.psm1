Set-StrictMode -Version Latest

$script:BoostLabRuntimePayloadManifestPath = Join-Path `
    (Split-Path -Parent $PSScriptRoot) `
    'config\RuntimePayloadManifest.psd1'
$script:BoostLabRuntimePayloadExternalReadyState = 'ReadyForExternalRuntime'

$script:BoostLabSourceVerificationPath = Join-Path $PSScriptRoot 'SourceVerification.psm1'
if (Test-Path -LiteralPath $script:BoostLabSourceVerificationPath -PathType Leaf) {
    Import-Module -Name $script:BoostLabSourceVerificationPath -Force -ErrorAction Stop
}

function Get-BoostLabRuntimePayloadPropertyValue {
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$Name,

        [AllowNull()]
        [object]$DefaultValue = $null
    )

    if ($null -eq $InputObject) {
        return $DefaultValue
    }
    if ($InputObject -is [System.Collections.IDictionary]) {
        if ($InputObject.Contains($Name)) {
            return $InputObject[$Name]
        }

        return $DefaultValue
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $DefaultValue
    }

    return $property.Value
}

function ConvertTo-BoostLabRuntimePayloadFullPath {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot,

        [Parameter(Mandatory)]
        [string]$RelativePath
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        return ''
    }

    return Join-Path $ProjectRoot ($RelativePath.Replace('/', '\'))
}

function Get-BoostLabRuntimePayloadManifest {
    [CmdletBinding()]
    [OutputType([System.Collections.IDictionary])]
    param(
        [string]$ManifestPath = $script:BoostLabRuntimePayloadManifestPath
    )

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        throw "Runtime payload manifest was not found: $ManifestPath"
    }

    $manifest = Import-PowerShellDataFile -LiteralPath $ManifestPath
    if (-not ($manifest -is [System.Collections.IDictionary])) {
        throw "Runtime payload manifest did not load as a dictionary: $ManifestPath"
    }
    if (-not $manifest.Contains('Entries')) {
        throw 'Runtime payload manifest is missing Entries.'
    }

    return $manifest
}

function Get-BoostLabRuntimePayloadEntries {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [AllowNull()]
        [object]$Manifest = $null,

        [string]$ManifestPath = $script:BoostLabRuntimePayloadManifestPath
    )

    if ($null -eq $Manifest) {
        $Manifest = Get-BoostLabRuntimePayloadManifest -ManifestPath $ManifestPath
    }

    $entryTable = Get-BoostLabRuntimePayloadPropertyValue -InputObject $Manifest -Name 'Entries'
    if (-not ($entryTable -is [System.Collections.IDictionary])) {
        throw 'Runtime payload manifest Entries must be a dictionary.'
    }

    $entries = [System.Collections.Generic.List[object]]::new()
    foreach ($entryId in @($entryTable.Keys | Sort-Object)) {
        $entry = $entryTable[$entryId]
        if (-not ($entry -is [System.Collections.IDictionary])) {
            throw "Runtime payload entry must be a dictionary: $entryId"
        }

        $record = [ordered]@{
            EntryId = [string]$entryId
        }
        foreach ($key in @($entry.Keys | Sort-Object)) {
            $record[[string]$key] = $entry[$key]
        }

        $entries.Add([pscustomobject]$record)
    }

    return $entries.ToArray()
}

function Resolve-BoostLabRuntimePayload {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [string]$PayloadId = '',

        [string]$ToolId = '',

        [string]$SourceIntentId = '',

        [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),

        [AllowNull()]
        [object]$Manifest = $null,

        [string]$ManifestPath = $script:BoostLabRuntimePayloadManifestPath
    )

    if ($null -eq $Manifest) {
        $Manifest = Get-BoostLabRuntimePayloadManifest -ManifestPath $ManifestPath
    }

    $entries = @(Get-BoostLabRuntimePayloadEntries -Manifest $Manifest)
    if (-not [string]::IsNullOrWhiteSpace($PayloadId)) {
        $entries = @($entries | Where-Object { [string]$_.PayloadId -eq $PayloadId })
    }
    if (-not [string]::IsNullOrWhiteSpace($ToolId)) {
        $entries = @($entries | Where-Object { [string]$_.ToolId -eq $ToolId })
    }
    if (-not [string]::IsNullOrWhiteSpace($SourceIntentId)) {
        $entries = @($entries | Where-Object { [string]$_.SourceIntentId -eq $SourceIntentId })
    }

    $resolved = [System.Collections.Generic.List[object]]::new()
    foreach ($entry in $entries) {
        $payloadPath = ConvertTo-BoostLabRuntimePayloadFullPath `
            -ProjectRoot $ProjectRoot `
            -RelativePath ([string]$entry.RuntimePayloadRelativePath)
        $runtimeWiringStatus = [string](Get-BoostLabRuntimePayloadPropertyValue `
            -InputObject $entry `
            -Name 'RuntimeWiringStatus' `
            -DefaultValue '')
        $externalRuntimeBlocked = ($runtimeWiringStatus -ne $script:BoostLabRuntimePayloadExternalReadyState)

        $record = [ordered]@{}
        foreach ($property in $entry.PSObject.Properties) {
            $record[$property.Name] = $property.Value
        }

        $record['PayloadPath'] = $payloadPath
        $record['PayloadExists'] = (-not [string]::IsNullOrWhiteSpace($payloadPath) -and (Test-Path -LiteralPath $payloadPath -PathType Leaf))
        $record['ExternalRuntimeBlocked'] = [bool]$externalRuntimeBlocked
        $record['BlockerReason'] = if ($externalRuntimeBlocked) { $runtimeWiringStatus } else { '' }
        $record['RuntimeActionExecuted'] = $false
        $record['ChangesExecuted'] = $false
        $resolved.Add([pscustomobject]$record)
    }

    return $resolved.ToArray()
}

function Test-BoostLabRuntimePayloadEntry {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Entry,

        [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
    )

    $payloadPath = ConvertTo-BoostLabRuntimePayloadFullPath `
        -ProjectRoot $ProjectRoot `
        -RelativePath ([string]$Entry.RuntimePayloadRelativePath)
    $hashMode = [string](Get-BoostLabRuntimePayloadPropertyValue -InputObject $Entry -Name 'HashMode' -DefaultValue '')
    $expectedRawSha256 = [string](Get-BoostLabRuntimePayloadPropertyValue -InputObject $Entry -Name 'RawSha256' -DefaultValue '')
    $expectedCanonicalSha256 = [string](Get-BoostLabRuntimePayloadPropertyValue -InputObject $Entry -Name 'CanonicalTextSha256' -DefaultValue '')
    $expectedLength = [int](Get-BoostLabRuntimePayloadPropertyValue -InputObject $Entry -Name 'ExpectedLengthBytes' -DefaultValue 0)
    $exists = (-not [string]::IsNullOrWhiteSpace($payloadPath) -and (Test-Path -LiteralPath $payloadPath -PathType Leaf))
    $rawSha256 = ''
    $canonicalSha256 = ''
    $length = 0
    $errors = [System.Collections.Generic.List[string]]::new()

    if ($exists) {
        try {
            $bytes = [IO.File]::ReadAllBytes($payloadPath)
            $length = $bytes.Length
            $rawSha256 = Get-BoostLabSha256Hex -Bytes $bytes
            if ($hashMode -eq 'CanonicalText' -and -not [string]::IsNullOrWhiteSpace($expectedCanonicalSha256)) {
                $canonicalSha256 = Get-BoostLabSha256Hex -Bytes (ConvertTo-BoostLabCanonicalSourceTextBytes -Bytes $bytes)
            }
        }
        catch {
            $errors.Add($_.Exception.Message)
        }
    }

    $lengthStatus = if (-not $exists) {
        'Missing'
    }
    elseif ($expectedLength -le 0) {
        'NotConfigured'
    }
    elseif ($length -eq $expectedLength) {
        'Passed'
    }
    else {
        'Failed'
    }

    $rawStatus = if (-not $exists) {
        'Missing'
    }
    elseif ([string]::IsNullOrWhiteSpace($expectedRawSha256)) {
        'NotConfigured'
    }
    elseif ($rawSha256 -eq $expectedRawSha256) {
        'Passed'
    }
    else {
        'Failed'
    }

    $canonicalStatus = if (-not $exists) {
        'Missing'
    }
    elseif ($hashMode -ne 'CanonicalText') {
        'NotConfigured'
    }
    elseif ([string]::IsNullOrWhiteSpace($expectedCanonicalSha256)) {
        'NotConfigured'
    }
    elseif ($canonicalSha256 -eq $expectedCanonicalSha256) {
        'Passed'
    }
    else {
        'Failed'
    }

    $hashPassed = if ($hashMode -eq 'RawBytes') {
        $rawStatus -eq 'Passed'
    }
    elseif ($hashMode -eq 'CanonicalText') {
        ($rawStatus -eq 'Passed' -or $canonicalStatus -eq 'Passed')
    }
    else {
        $false
    }

    $checksumStatus = if (-not $exists) {
        'Missing'
    }
    elseif ($hashPassed -and $lengthStatus -in @('Passed', 'NotConfigured')) {
        'Passed'
    }
    else {
        'Failed'
    }

    $verificationMode = if (-not $exists) {
        'Missing'
    }
    elseif ($hashMode -eq 'RawBytes' -and $rawStatus -eq 'Passed') {
        'RawBytesSha256'
    }
    elseif ($rawStatus -eq 'Passed') {
        'ExactRawSha256'
    }
    elseif ($canonicalStatus -eq 'Passed') {
        'CanonicalTextSha256'
    }
    else {
        'Failed'
    }

    $runtimeWiringStatus = [string](Get-BoostLabRuntimePayloadPropertyValue `
        -InputObject $Entry `
        -Name 'RuntimeWiringStatus' `
        -DefaultValue '')
    $externalRuntimeBlocked = ($runtimeWiringStatus -ne $script:BoostLabRuntimePayloadExternalReadyState)

    [pscustomobject]@{
        EntryId = [string]$Entry.EntryId
        PayloadId = [string]$Entry.PayloadId
        ToolId = [string]$Entry.ToolId
        SourceIntentId = [string]$Entry.SourceIntentId
        RuntimePayloadRelativePath = [string]$Entry.RuntimePayloadRelativePath
        PayloadPath = $payloadPath
        PayloadKind = [string]$Entry.PayloadKind
        HashMode = $hashMode
        Exists = [bool]$exists
        ExpectedLengthBytes = $expectedLength
        DetectedLengthBytes = $length
        LengthStatus = $lengthStatus
        ExpectedSha256 = $expectedRawSha256
        DetectedSha256 = $rawSha256
        ExpectedCanonicalTextSha256 = $expectedCanonicalSha256
        DetectedCanonicalTextSha256 = $canonicalSha256
        RawChecksumStatus = $rawStatus
        CanonicalTextChecksumStatus = $canonicalStatus
        ChecksumStatus = $checksumStatus
        VerificationMode = $verificationMode
        ExternalHandling = [string]$Entry.ExternalHandling
        RuntimeWiringStatus = $runtimeWiringStatus
        PayloadArtifactReady = [bool]($checksumStatus -eq 'Passed' -and [string]$Entry.ExternalHandling -eq 'GeneratedRuntimePayloadAvailable')
        ExternalRuntimeBlocked = [bool]$externalRuntimeBlocked
        BlockerReason = if ($externalRuntimeBlocked) { $runtimeWiringStatus } else { '' }
        RuntimeActionExecuted = $false
        ChangesExecuted = $false
        Errors = $errors.ToArray()
    }
}

function Test-BoostLabRuntimePayload {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [string]$PayloadId = '',

        [string]$ToolId = '',

        [string]$SourceIntentId = '',

        [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),

        [AllowNull()]
        [object]$Manifest = $null,

        [string]$ManifestPath = $script:BoostLabRuntimePayloadManifestPath
    )

    if ($null -eq $Manifest) {
        $Manifest = Get-BoostLabRuntimePayloadManifest -ManifestPath $ManifestPath
    }

    $entries = @(Get-BoostLabRuntimePayloadEntries -Manifest $Manifest)
    if (-not [string]::IsNullOrWhiteSpace($PayloadId)) {
        $entries = @($entries | Where-Object { [string]$_.PayloadId -eq $PayloadId })
    }
    if (-not [string]::IsNullOrWhiteSpace($ToolId)) {
        $entries = @($entries | Where-Object { [string]$_.ToolId -eq $ToolId })
    }
    if (-not [string]::IsNullOrWhiteSpace($SourceIntentId)) {
        $entries = @($entries | Where-Object { [string]$_.SourceIntentId -eq $SourceIntentId })
    }

    return @(
        $entries | ForEach-Object {
            Test-BoostLabRuntimePayloadEntry -Entry $_ -ProjectRoot $ProjectRoot
        }
    )
}

function Get-BoostLabRuntimePayloadReadiness {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),

        [AllowNull()]
        [object]$Manifest = $null,

        [string]$ManifestPath = $script:BoostLabRuntimePayloadManifestPath
    )

    if ($null -eq $Manifest) {
        $Manifest = Get-BoostLabRuntimePayloadManifest -ManifestPath $ManifestPath
    }

    $entries = @(Get-BoostLabRuntimePayloadEntries -Manifest $Manifest)
    $payloadStatuses = @(Test-BoostLabRuntimePayload -ProjectRoot $ProjectRoot -Manifest $Manifest)
    $available = @($payloadStatuses | Where-Object { [bool]$_.PayloadArtifactReady })
    $failed = @($payloadStatuses | Where-Object { [string]$_.ChecksumStatus -eq 'Failed' })
    $missing = @($payloadStatuses | Where-Object { [string]$_.ChecksumStatus -eq 'Missing' })
    $notWired = @($entries | Where-Object { [string]$_.RuntimeWiringStatus -ne $script:BoostLabRuntimePayloadExternalReadyState })
    $highRiskTools = @(
        $entries |
            Where-Object { [bool](Get-BoostLabRuntimePayloadPropertyValue -InputObject $_ -Name 'HighRiskBlocker' -DefaultValue $false) } |
            ForEach-Object { [string]$_.ToolId } |
            Sort-Object -Unique
    )

    [pscustomobject]@{
        TotalPayloadEntries = [int]$entries.Count
        GeneratedRuntimePayloadAvailableEntries = [int]$available.Count
        MissingPayloadEntries = [int]$missing.Count
        FailedPayloadEntries = [int]$failed.Count
        NotWiredPayloadEntries = [int]$notWired.Count
        RuntimeWiredPayloadEntries = [int]($entries.Count - $notWired.Count)
        HighRiskBlockerToolCount = [int]$highRiskTools.Count
        HighRiskBlockerTools = $highRiskTools
        ExternalRuntimeReady = [bool]($entries.Count -gt 0 -and $failed.Count -eq 0 -and $missing.Count -eq 0 -and $notWired.Count -eq 0)
        RuntimeActionExecuted = $false
        ChangesExecuted = $false
        Message = if ($failed.Count -eq 0 -and $missing.Count -eq 0 -and $notWired.Count -gt 0) {
            'Generated runtime payload artifacts are present and verified, but modules still use internal protected source paths.'
        }
        elseif ($failed.Count -eq 0 -and $missing.Count -eq 0) {
            'Generated runtime payload artifacts are present and verified.'
        }
        else {
            'Generated runtime payload artifacts are missing or failed verification.'
        }
    }
}

Export-ModuleMember -Function @(
    'Get-BoostLabRuntimePayloadManifest'
    'Resolve-BoostLabRuntimePayload'
    'Test-BoostLabRuntimePayload'
    'Get-BoostLabRuntimePayloadReadiness'
)
