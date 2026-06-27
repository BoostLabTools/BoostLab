Set-StrictMode -Version Latest

$script:BoostLabRuntimeSourceIntentManifestPath = Join-Path `
    (Split-Path -Parent $PSScriptRoot) `
    'config\RuntimeSourceIntentManifest.psd1'
$script:BoostLabRuntimePackageModeEnvironmentVariable = 'BOOSTLAB_RUNTIME_PACKAGE_MODE'
$script:BoostLabExternalRuntimeBlockerStates = @(
    'ExternalRuntimeBlockedUntilDecoupled'
    'GeneratedRuntimePayloadRequired'
)

function Get-BoostLabRuntimeSourceIntentPropertyValue {
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

function ConvertTo-BoostLabRuntimePackageModeName {
    param(
        [AllowNull()]
        [string]$Mode
    )

    if ([string]::IsNullOrWhiteSpace($Mode)) {
        return ''
    }

    $normalized = $Mode.Trim().Replace('-', '').Replace('_', '').ToLowerInvariant()
    switch ($normalized) {
        'internal' { return 'InternalDevelopment' }
        'internaldevelopment' { return 'InternalDevelopment' }
        'development' { return 'InternalDevelopment' }
        'external' { return 'ExternalRuntime' }
        'externalruntime' { return 'ExternalRuntime' }
        'runtime' { return 'ExternalRuntime' }
        default {
            throw "Unsupported BoostLab runtime package mode: $Mode"
        }
    }
}

function Get-BoostLabRuntimeSourceIntentManifest {
    [CmdletBinding()]
    [OutputType([System.Collections.IDictionary])]
    param(
        [string]$ManifestPath = $script:BoostLabRuntimeSourceIntentManifestPath
    )

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        throw "Runtime source intent manifest was not found: $ManifestPath"
    }

    $manifest = Import-PowerShellDataFile -LiteralPath $ManifestPath
    if (-not ($manifest -is [System.Collections.IDictionary])) {
        throw "Runtime source intent manifest did not load as a dictionary: $ManifestPath"
    }
    if (-not $manifest.Contains('Entries')) {
        throw 'Runtime source intent manifest is missing Entries.'
    }

    return $manifest
}

function Get-BoostLabRuntimeSourceIntentEntries {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [AllowNull()]
        [object]$Manifest = $null,

        [string]$ManifestPath = $script:BoostLabRuntimeSourceIntentManifestPath
    )

    if ($null -eq $Manifest) {
        $Manifest = Get-BoostLabRuntimeSourceIntentManifest -ManifestPath $ManifestPath
    }

    $entryTable = Get-BoostLabRuntimeSourceIntentPropertyValue -InputObject $Manifest -Name 'Entries'
    if (-not ($entryTable -is [System.Collections.IDictionary])) {
        throw 'Runtime source intent manifest Entries must be a dictionary.'
    }

    $entries = [System.Collections.Generic.List[object]]::new()
    foreach ($entryId in @($entryTable.Keys | Sort-Object)) {
        $entry = $entryTable[$entryId]
        if (-not ($entry -is [System.Collections.IDictionary])) {
            throw "Runtime source intent entry must be a dictionary: $entryId"
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

function Get-BoostLabRuntimePackageMode {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$RequestedMode = '',

        [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),

        [string]$EnvironmentVariableName = $script:BoostLabRuntimePackageModeEnvironmentVariable,

        [AllowEmptyString()]
        [string]$EnvironmentMode = $null
    )

    if ($null -eq $EnvironmentMode -and -not [string]::IsNullOrWhiteSpace($EnvironmentVariableName)) {
        $EnvironmentMode = [Environment]::GetEnvironmentVariable($EnvironmentVariableName, 'Process')
    }

    $requested = ConvertTo-BoostLabRuntimePackageModeName -Mode $RequestedMode
    $environmentRequested = ConvertTo-BoostLabRuntimePackageModeName -Mode $EnvironmentMode
    $mode = if (-not [string]::IsNullOrWhiteSpace($requested)) {
        $requested
    }
    elseif (-not [string]::IsNullOrWhiteSpace($environmentRequested)) {
        $environmentRequested
    }
    else {
        'InternalDevelopment'
    }

    $sourceUltimatePath = Join-Path $ProjectRoot 'source-ultimate'
    $sourceExtraPath = Join-Path $ProjectRoot 'source-extra'
    $intakePath = Join-Path $ProjectRoot 'intake'

    [pscustomobject]@{
        Mode = $mode
        RequestedMode = $requested
        EnvironmentMode = $environmentRequested
        ProjectRoot = $ProjectRoot
        SourceUltimatePresent = (Test-Path -LiteralPath $sourceUltimatePath -PathType Container)
        SourceExtraPresent = (Test-Path -LiteralPath $sourceExtraPath -PathType Container)
        IntakePresent = (Test-Path -LiteralPath $intakePath -PathType Container)
        IsInternalDevelopment = ($mode -eq 'InternalDevelopment')
        IsExternalRuntime = ($mode -eq 'ExternalRuntime')
        SourceFoldersExpected = ($mode -eq 'InternalDevelopment')
    }
}

function Resolve-BoostLabRuntimeSourceIntent {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [string]$EntryId = '',

        [string]$ToolId = '',

        [string]$SourceRelativePath = '',

        [string]$RequestedMode = '',

        [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),

        [AllowNull()]
        [object]$Manifest = $null,

        [string]$ManifestPath = $script:BoostLabRuntimeSourceIntentManifestPath
    )

    if ($null -eq $Manifest) {
        $Manifest = Get-BoostLabRuntimeSourceIntentManifest -ManifestPath $ManifestPath
    }

    $mode = Get-BoostLabRuntimePackageMode -RequestedMode $RequestedMode -ProjectRoot $ProjectRoot
    $entries = @(Get-BoostLabRuntimeSourceIntentEntries -Manifest $Manifest)
    if (-not [string]::IsNullOrWhiteSpace($EntryId)) {
        $entries = @($entries | Where-Object { [string]$_.EntryId -eq $EntryId })
    }
    if (-not [string]::IsNullOrWhiteSpace($ToolId)) {
        $entries = @($entries | Where-Object { [string]$_.ToolId -eq $ToolId })
    }
    if (-not [string]::IsNullOrWhiteSpace($SourceRelativePath)) {
        $normalizedSource = $SourceRelativePath.Replace('\', '/')
        $entries = @($entries | Where-Object { ([string]$_.SourceRelativePath).Replace('\', '/') -eq $normalizedSource })
    }

    $resolved = [System.Collections.Generic.List[object]]::new()
    foreach ($entry in $entries) {
        $externalHandling = [string](Get-BoostLabRuntimeSourceIntentPropertyValue -InputObject $entry -Name 'ExternalHandling' -DefaultValue '')
        $isBlocked = ($mode.Mode -eq 'ExternalRuntime' -and $externalHandling -in $script:BoostLabExternalRuntimeBlockerStates)
        $record = [ordered]@{}
        foreach ($property in $entry.PSObject.Properties) {
            $record[$property.Name] = $property.Value
        }

        $record['Mode'] = [string]$mode.Mode
        $record['ExternalRuntimeBlocked'] = [bool]$isBlocked
        $record['BlockerReason'] = if ($isBlocked) { $externalHandling } else { '' }
        $record['RuntimeActionExecuted'] = $false
        $record['ChangesExecuted'] = $false
        $resolved.Add([pscustomobject]$record)
    }

    return $resolved.ToArray()
}

function Test-BoostLabExternalRuntimeReadiness {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$RequestedMode = 'ExternalRuntime',

        [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),

        [AllowNull()]
        [object]$Manifest = $null,

        [string]$ManifestPath = $script:BoostLabRuntimeSourceIntentManifestPath
    )

    if ($null -eq $Manifest) {
        $Manifest = Get-BoostLabRuntimeSourceIntentManifest -ManifestPath $ManifestPath
    }

    $mode = Get-BoostLabRuntimePackageMode -RequestedMode $RequestedMode -ProjectRoot $ProjectRoot
    $entries = @(Get-BoostLabRuntimeSourceIntentEntries -Manifest $Manifest)
    $blockedEntries = @($entries | Where-Object { [string]$_.ExternalHandling -in $script:BoostLabExternalRuntimeBlockerStates })
    $generatedPayloadRequired = @($entries | Where-Object { [string]$_.ExternalHandling -eq 'GeneratedRuntimePayloadRequired' })
    $rawSourceRequired = @($entries | Where-Object { [bool](Get-BoostLabRuntimeSourceIntentPropertyValue -InputObject $_ -Name 'CurrentInternalSourceRequired' -DefaultValue $false) })
    $externalReady = @($entries | Where-Object { [string]$_.ExternalHandling -in @('ManifestOnly', 'NotRequiredExternally') })
    $highRisk = @($entries | Where-Object { [bool](Get-BoostLabRuntimeSourceIntentPropertyValue -InputObject $_ -Name 'HighRiskBlocker' -DefaultValue $false) })

    $highRiskRecords = @(
        $highRisk | ForEach-Object {
            $payloadBlockers = @(Get-BoostLabRuntimeSourceIntentPropertyValue -InputObject $_ -Name 'PayloadBlockers' -DefaultValue @())
            [pscustomobject]@{
                EntryId = [string]$_.EntryId
                ToolId = [string]$_.ToolId
                ExternalHandling = [string]$_.ExternalHandling
                PayloadBlockerCount = $payloadBlockers.Count
            }
        }
    )

    $externalRuntimeReady = ($blockedEntries.Count -eq 0 -and $generatedPayloadRequired.Count -eq 0)
    [pscustomobject]@{
        Mode = [string]$mode.Mode
        ExternalRuntimeReady = [bool]$externalRuntimeReady
        TotalSourceIntentEntries = [int]$entries.Count
        ExternalReadyEntries = [int]$externalReady.Count
        BlockedEntries = [int]$blockedEntries.Count
        GeneratedPayloadRequiredEntries = [int]$generatedPayloadRequired.Count
        RawSourceRequiredEntries = [int]$rawSourceRequired.Count
        HighRiskBlockerCount = [int]$highRiskRecords.Count
        HighRiskBlockers = $highRiskRecords
        RuntimeActionExecuted = $false
        ChangesExecuted = $false
        Message = if ($externalRuntimeReady) {
            'External runtime source intent entries are ready.'
        }
        else {
            'External runtime remains blocked until source dependencies and generated payloads are decoupled.'
        }
    }
}

Export-ModuleMember -Function @(
    'Get-BoostLabRuntimeSourceIntentManifest'
    'Resolve-BoostLabRuntimeSourceIntent'
    'Get-BoostLabRuntimePackageMode'
    'Test-BoostLabExternalRuntimeReadiness'
)
