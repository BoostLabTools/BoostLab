Set-StrictMode -Version Latest

$script:BoostLabRuntimeSourceIntentManifestPath = Join-Path `
    (Split-Path -Parent $PSScriptRoot) `
    'config\RuntimeSourceIntentManifest.psd1'
$script:BoostLabRuntimePayloadManifestPath = Join-Path `
    (Split-Path -Parent $PSScriptRoot) `
    'config\RuntimePayloadManifest.psd1'
$script:BoostLabRuntimeOperationDescriptorManifestPath = Join-Path `
    (Split-Path -Parent $PSScriptRoot) `
    'config\RuntimeOperationDescriptors.psd1'
$script:BoostLabRuntimePackageModeEnvironmentVariable = 'BOOSTLAB_RUNTIME_PACKAGE_MODE'
$script:BoostLabExternalRuntimeBlockerStates = @(
    'ExternalRuntimeBlockedUntilDecoupled'
    'GeneratedRuntimePayloadRequired'
)

$script:BoostLabRuntimePayloadHelperPath = Join-Path $PSScriptRoot 'RuntimePayloads.psm1'
$script:BoostLabRuntimeOperationDescriptorHelperPath = Join-Path $PSScriptRoot 'RuntimeOperationDescriptors.psm1'
$script:BoostLabRuntimeSourceIntentHelperImports = @(
    @{
        Path = $script:BoostLabRuntimePayloadHelperPath
        ProbeCommand = 'Get-BoostLabRuntimePayloadManifest'
    }
    @{
        Path = $script:BoostLabRuntimeOperationDescriptorHelperPath
        ProbeCommand = 'Get-BoostLabRuntimeOperationDescriptorManifest'
    }
)
foreach ($helperImport in $script:BoostLabRuntimeSourceIntentHelperImports) {
    if (
        (Test-Path -LiteralPath ([string]$helperImport.Path) -PathType Leaf) -and
        -not (Get-Command -Name ([string]$helperImport.ProbeCommand) -ErrorAction SilentlyContinue)
    ) {
        Import-Module -Name ([string]$helperImport.Path) -Global -ErrorAction Stop
    }
}

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

function Test-BoostLabRuntimeSourceIntentPayloadEvidence {
    param(
        [Parameter(Mandatory)]
        [object]$Entry,

        [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),

        [AllowNull()]
        [object]$RuntimePayloadManifest = $null,

        [string]$RuntimePayloadManifestPath = $script:BoostLabRuntimePayloadManifestPath
    )

    $payloadBlockers = @(Get-BoostLabRuntimeSourceIntentPropertyValue -InputObject $Entry -Name 'PayloadBlockers' -DefaultValue @())
    $blockers = [System.Collections.Generic.List[object]]::new()
    $payloadStatuses = [System.Collections.Generic.List[object]]::new()

    if ($payloadBlockers.Count -eq 0) {
        $blockers.Add([pscustomobject]@{
            BlockerType = 'MissingPayloadReference'
            Detail = 'Payload-backed source intent does not list runtime payload records.'
        })
    }

    if ($null -eq $RuntimePayloadManifest) {
        try {
            $RuntimePayloadManifest = Get-BoostLabRuntimePayloadManifest -ManifestPath $RuntimePayloadManifestPath
        }
        catch {
            $blockers.Add([pscustomobject]@{
                BlockerType = 'RuntimePayloadManifestUnavailable'
                Detail = $_.Exception.Message
            })
        }
    }

    foreach ($payloadBlocker in $payloadBlockers) {
        $payloadId = [string](Get-BoostLabRuntimeSourceIntentPropertyValue -InputObject $payloadBlocker -Name 'PayloadId' -DefaultValue '')
        if ([string]::IsNullOrWhiteSpace($payloadId)) {
            $blockers.Add([pscustomobject]@{
                BlockerType = 'MissingPayloadId'
                Detail = 'Payload blocker record does not declare PayloadId.'
            })
            continue
        }

        $payloadStatus = @()
        if ($null -ne $RuntimePayloadManifest) {
            $payloadStatus = @(Test-BoostLabRuntimePayload `
                -PayloadId $payloadId `
                -ProjectRoot $ProjectRoot `
                -Manifest $RuntimePayloadManifest)
        }
        if ($payloadStatus.Count -ne 1) {
            $blockers.Add([pscustomobject]@{
                BlockerType = 'MissingRuntimePayload'
                Detail = $payloadId
            })
            continue
        }

        $payloadStatuses.Add($payloadStatus[0])
        if (-not [bool]$payloadStatus[0].PayloadArtifactReady -or [bool]$payloadStatus[0].ExternalRuntimeBlocked) {
            $blockers.Add([pscustomobject]@{
                BlockerType = 'RuntimePayloadNotReady'
                Detail = $payloadId
            })
        }
    }

    [pscustomobject]@{
        EvidenceMode = 'RuntimePayload'
        SourceEvidenceSatisfied = [bool]($payloadBlockers.Count -gt 0 -and $blockers.Count -eq 0)
        BlockerReason = if ($blockers.Count -eq 0) { '' } else { ($blockers | ForEach-Object { [string]$_.BlockerType } | Select-Object -First 1) }
        EvidenceRecords = $payloadStatuses.ToArray()
        Blockers = $blockers.ToArray()
        RuntimeActionExecuted = $false
        ChangesExecuted = $false
    }
}

function Test-BoostLabRuntimeSourceIntentDescriptorEvidence {
    param(
        [Parameter(Mandatory)]
        [object]$Entry,

        [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),

        [AllowNull()]
        [object]$OperationDescriptorManifest = $null,

        [string]$OperationDescriptorManifestPath = $script:BoostLabRuntimeOperationDescriptorManifestPath
    )

    $blockers = [System.Collections.Generic.List[object]]::new()
    $descriptorId = [string](Get-BoostLabRuntimeSourceIntentPropertyValue -InputObject $Entry -Name 'OperationDescriptorId' -DefaultValue '')
    if ([string]::IsNullOrWhiteSpace($descriptorId)) {
        $blockers.Add([pscustomobject]@{
            BlockerType = 'MissingOperationDescriptorId'
            Detail = [string](Get-BoostLabRuntimeSourceIntentPropertyValue -InputObject $Entry -Name 'EntryId' -DefaultValue '')
        })
    }

    if ($null -eq $OperationDescriptorManifest) {
        try {
            $OperationDescriptorManifest = Get-BoostLabRuntimeOperationDescriptorManifest -ManifestPath $OperationDescriptorManifestPath
        }
        catch {
            $blockers.Add([pscustomobject]@{
                BlockerType = 'RuntimeOperationDescriptorManifestUnavailable'
                Detail = $_.Exception.Message
            })
        }
    }

    $descriptorStatus = @()
    if (-not [string]::IsNullOrWhiteSpace($descriptorId) -and $null -ne $OperationDescriptorManifest) {
        $descriptorStatus = @(Test-BoostLabRuntimeOperationDescriptor `
            -DescriptorId $descriptorId `
            -ProjectRoot $ProjectRoot `
            -Manifest $OperationDescriptorManifest)
    }

    if (-not [string]::IsNullOrWhiteSpace($descriptorId) -and $descriptorStatus.Count -ne 1) {
        $blockers.Add([pscustomobject]@{
            BlockerType = 'MissingOperationDescriptor'
            Detail = $descriptorId
        })
    }
    elseif ($descriptorStatus.Count -eq 1) {
        if ([string]$descriptorStatus[0].DescriptorStatus -ne 'Passed' -or -not [bool]$descriptorStatus[0].DescriptorReadyForFutureExternalMode) {
            $blockers.Add([pscustomobject]@{
                BlockerType = 'InvalidOperationDescriptor'
                Detail = $descriptorId
            })
        }
        if ([string]$descriptorStatus[0].SourceIntentId -ne [string](Get-BoostLabRuntimeSourceIntentPropertyValue -InputObject $Entry -Name 'EntryId' -DefaultValue '')) {
            $blockers.Add([pscustomobject]@{
                BlockerType = 'OperationDescriptorSourceIntentMismatch'
                Detail = $descriptorId
            })
        }
    }

    [pscustomobject]@{
        EvidenceMode = 'OperationDescriptor'
        SourceEvidenceSatisfied = [bool](-not [string]::IsNullOrWhiteSpace($descriptorId) -and $blockers.Count -eq 0)
        BlockerReason = if ($blockers.Count -eq 0) { '' } else { ($blockers | ForEach-Object { [string]$_.BlockerType } | Select-Object -First 1) }
        EvidenceRecords = $descriptorStatus
        Blockers = $blockers.ToArray()
        RuntimeActionExecuted = $false
        ChangesExecuted = $false
    }
}

function Test-BoostLabRuntimeSourceIntentExternalEvidence {
    param(
        [Parameter(Mandatory)]
        [object]$Entry,

        [Parameter(Mandatory)]
        [object]$Mode,

        [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),

        [AllowNull()]
        [object]$RuntimePayloadManifest = $null,

        [AllowNull()]
        [object]$OperationDescriptorManifest = $null,

        [string]$RuntimePayloadManifestPath = $script:BoostLabRuntimePayloadManifestPath,

        [string]$OperationDescriptorManifestPath = $script:BoostLabRuntimeOperationDescriptorManifestPath
    )

    if (-not [bool]$Mode.IsExternalRuntime) {
        return [pscustomobject]@{
            EvidenceMode = 'InternalDevelopmentSourceParity'
            SourceEvidenceSatisfied = $true
            ExternalRuntimeBlocked = $false
            BlockerReason = ''
            EvidenceRecords = @()
            Blockers = @()
            RawSourceVerificationClaimed = $true
            RuntimeActionExecuted = $false
            ChangesExecuted = $false
        }
    }

    $externalHandling = [string](Get-BoostLabRuntimeSourceIntentPropertyValue -InputObject $Entry -Name 'ExternalHandling' -DefaultValue '')
    $externalModeTreatment = @(Get-BoostLabRuntimeSourceIntentPropertyValue -InputObject $Entry -Name 'ExternalModeTreatment' -DefaultValue @())
    $operationDescriptorId = [string](Get-BoostLabRuntimeSourceIntentPropertyValue -InputObject $Entry -Name 'OperationDescriptorId' -DefaultValue '')

    $evidence = if ($externalHandling -eq 'ManifestOnly' -and 'RuntimePayloadReady' -in $externalModeTreatment) {
        Test-BoostLabRuntimeSourceIntentPayloadEvidence `
            -Entry $Entry `
            -ProjectRoot $ProjectRoot `
            -RuntimePayloadManifest $RuntimePayloadManifest `
            -RuntimePayloadManifestPath $RuntimePayloadManifestPath
    }
    elseif ($externalHandling -eq 'OperationDescriptorAvailable' -or -not [string]::IsNullOrWhiteSpace($operationDescriptorId)) {
        Test-BoostLabRuntimeSourceIntentDescriptorEvidence `
            -Entry $Entry `
            -ProjectRoot $ProjectRoot `
            -OperationDescriptorManifest $OperationDescriptorManifest `
            -OperationDescriptorManifestPath $OperationDescriptorManifestPath
    }
    elseif ($externalHandling -in @('ManifestOnly', 'NotRequiredExternally')) {
        [pscustomobject]@{
            EvidenceMode = 'ManifestOnly'
            SourceEvidenceSatisfied = $true
            BlockerReason = ''
            EvidenceRecords = @()
            Blockers = @()
            RuntimeActionExecuted = $false
            ChangesExecuted = $false
        }
    }
    else {
        [pscustomobject]@{
            EvidenceMode = 'BlockedSourceIntent'
            SourceEvidenceSatisfied = $false
            BlockerReason = if ([string]::IsNullOrWhiteSpace($externalHandling)) { 'ExternalHandlingMissing' } else { $externalHandling }
            EvidenceRecords = @()
            Blockers = @([pscustomobject]@{
                BlockerType = if ([string]::IsNullOrWhiteSpace($externalHandling)) { 'ExternalHandlingMissing' } else { $externalHandling }
                Detail = [string](Get-BoostLabRuntimeSourceIntentPropertyValue -InputObject $Entry -Name 'EntryId' -DefaultValue '')
            })
            RuntimeActionExecuted = $false
            ChangesExecuted = $false
        }
    }

    [pscustomobject]@{
        EvidenceMode = [string]$evidence.EvidenceMode
        SourceEvidenceSatisfied = [bool]$evidence.SourceEvidenceSatisfied
        ExternalRuntimeBlocked = [bool](-not [bool]$evidence.SourceEvidenceSatisfied)
        BlockerReason = [string]$evidence.BlockerReason
        EvidenceRecords = @($evidence.EvidenceRecords)
        Blockers = @($evidence.Blockers)
        RawSourceVerificationClaimed = $false
        RuntimeActionExecuted = $false
        ChangesExecuted = $false
    }
}

function Get-BoostLabExternalPackageSourceReferenceScan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),

        [string[]]$ScanRelativePaths = @('modules', 'core')
    )

    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
    $references = [System.Collections.Generic.List[object]]::new()
    $sourcePattern = 'source-ultimate|source-extra|_intake-promoted|\bintake\b'
    foreach ($relativeRoot in $ScanRelativePaths) {
        $rootPath = Join-Path $ProjectRoot $relativeRoot
        if (-not (Test-Path -LiteralPath $rootPath -PathType Container)) {
            continue
        }

        $files = @(
            Get-ChildItem -LiteralPath $rootPath -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { [string]$_.Extension -in @('.ps1', '.psm1', '.psd1') }
        )
        foreach ($file in $files) {
            $relativePath = $file.FullName.Substring($ProjectRoot.Length).TrimStart('\', '/') -replace '\\', '/'
            $lines = @(Get-Content -LiteralPath $file.FullName)
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = [string]$lines[$i]
                if ($line -notmatch $sourcePattern) {
                    continue
                }

                $classification = if ($relativePath -like 'modules/*') {
                    'SourceFreePackageBlocker'
                }
                elseif ($relativePath -eq 'core/RuntimeSourceIntent.psm1') {
                    'InternalDevelopmentOnly'
                }
                elseif ($relativePath -eq 'core/ActionPlan.psm1') {
                    'DiagnosticsDeveloperEvidenceOnly'
                }
                else {
                    'SafeDescriptorBackedFallbackCandidate'
                }

                $references.Add([pscustomobject]@{
                    RelativePath = $relativePath
                    LineNumber = [int]($i + 1)
                    Classification = $classification
                    SourceFreePackageBlocker = [bool]($classification -eq 'SourceFreePackageBlocker')
                    Text = $line.Trim()
                })
            }
        }
    }

    $blockers = @($references | Where-Object { [bool]$_.SourceFreePackageBlocker })
    [pscustomobject]@{
        TotalReferences = [int]$references.Count
        SourceFreePackageBlockerCount = [int]$blockers.Count
        InternalDevelopmentOnlyCount = [int]@($references | Where-Object { [string]$_.Classification -eq 'InternalDevelopmentOnly' }).Count
        DiagnosticsDeveloperEvidenceOnlyCount = [int]@($references | Where-Object { [string]$_.Classification -eq 'DiagnosticsDeveloperEvidenceOnly' }).Count
        SafeDescriptorBackedFallbackCandidateCount = [int]@($references | Where-Object { [string]$_.Classification -eq 'SafeDescriptorBackedFallbackCandidate' }).Count
        TestOnlyCount = 0
        DocsOnlyCount = 0
        ExternalPackageBuildReady = [bool]($blockers.Count -eq 0)
        ExternalPackageSourceFreeLaunchBlocked = [bool]($blockers.Count -gt 0)
        SourceFreePackageBlockers = @($blockers | Sort-Object -Property RelativePath, LineNumber)
        References = @($references | Sort-Object -Property RelativePath, LineNumber)
        RuntimeActionExecuted = $false
        ChangesExecuted = $false
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

        [string]$ManifestPath = $script:BoostLabRuntimeSourceIntentManifestPath,

        [AllowNull()]
        [object]$RuntimePayloadManifest = $null,

        [AllowNull()]
        [object]$OperationDescriptorManifest = $null,

        [string]$RuntimePayloadManifestPath = $script:BoostLabRuntimePayloadManifestPath,

        [string]$OperationDescriptorManifestPath = $script:BoostLabRuntimeOperationDescriptorManifestPath
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
        $evidence = Test-BoostLabRuntimeSourceIntentExternalEvidence `
            -Entry $entry `
            -Mode $mode `
            -ProjectRoot $ProjectRoot `
            -RuntimePayloadManifest $RuntimePayloadManifest `
            -OperationDescriptorManifest $OperationDescriptorManifest `
            -RuntimePayloadManifestPath $RuntimePayloadManifestPath `
            -OperationDescriptorManifestPath $OperationDescriptorManifestPath
        $record = [ordered]@{}
        foreach ($property in $entry.PSObject.Properties) {
            $record[$property.Name] = $property.Value
        }

        $record['Mode'] = [string]$mode.Mode
        $record['SourceEvidenceMode'] = [string]$evidence.EvidenceMode
        $record['SourceEvidenceSatisfied'] = [bool]$evidence.SourceEvidenceSatisfied
        $record['ExternalRuntimeBlocked'] = [bool]$evidence.ExternalRuntimeBlocked
        $record['BlockerReason'] = [string]$evidence.BlockerReason
        $record['EvidenceRecords'] = @($evidence.EvidenceRecords)
        $record['EvidenceBlockers'] = @($evidence.Blockers)
        $record['RawSourceVerificationClaimed'] = [bool]$evidence.RawSourceVerificationClaimed
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

        [string]$ManifestPath = $script:BoostLabRuntimeSourceIntentManifestPath,

        [AllowNull()]
        [object]$RuntimePayloadManifest = $null,

        [AllowNull()]
        [object]$OperationDescriptorManifest = $null,

        [string]$RuntimePayloadManifestPath = $script:BoostLabRuntimePayloadManifestPath,

        [string]$OperationDescriptorManifestPath = $script:BoostLabRuntimeOperationDescriptorManifestPath
    )

    if ($null -eq $Manifest) {
        $Manifest = Get-BoostLabRuntimeSourceIntentManifest -ManifestPath $ManifestPath
    }

    if ($null -eq $RuntimePayloadManifest -and (Get-Command -Name 'Get-BoostLabRuntimePayloadManifest' -ErrorAction SilentlyContinue)) {
        $RuntimePayloadManifest = Get-BoostLabRuntimePayloadManifest -ManifestPath $RuntimePayloadManifestPath
    }
    if ($null -eq $OperationDescriptorManifest -and (Get-Command -Name 'Get-BoostLabRuntimeOperationDescriptorManifest' -ErrorAction SilentlyContinue)) {
        $OperationDescriptorManifest = Get-BoostLabRuntimeOperationDescriptorManifest -ManifestPath $OperationDescriptorManifestPath
    }

    $mode = Get-BoostLabRuntimePackageMode -RequestedMode $RequestedMode -ProjectRoot $ProjectRoot
    $entries = @(Get-BoostLabRuntimeSourceIntentEntries -Manifest $Manifest)
    $resolvedEntries = @(Resolve-BoostLabRuntimeSourceIntent `
        -RequestedMode $RequestedMode `
        -ProjectRoot $ProjectRoot `
        -Manifest $Manifest `
        -RuntimePayloadManifest $RuntimePayloadManifest `
        -OperationDescriptorManifest $OperationDescriptorManifest `
        -RuntimePayloadManifestPath $RuntimePayloadManifestPath `
        -OperationDescriptorManifestPath $OperationDescriptorManifestPath)
    $blockedEntries = @($resolvedEntries | Where-Object { [bool]$_.ExternalRuntimeBlocked })
    $generatedPayloadRequired = @($entries | Where-Object { [string]$_.ExternalHandling -eq 'GeneratedRuntimePayloadRequired' })
    $rawSourceRequired = @($entries | Where-Object { [bool](Get-BoostLabRuntimeSourceIntentPropertyValue -InputObject $_ -Name 'CurrentInternalSourceRequired' -DefaultValue $false) })
    $externalReady = @($resolvedEntries | Where-Object { -not [bool]$_.ExternalRuntimeBlocked })
    $payloadBackedReady = @($resolvedEntries | Where-Object { [string]$_.SourceEvidenceMode -eq 'RuntimePayload' -and [bool]$_.SourceEvidenceSatisfied })
    $descriptorBackedReady = @($resolvedEntries | Where-Object { [string]$_.SourceEvidenceMode -eq 'OperationDescriptor' -and [bool]$_.SourceEvidenceSatisfied })
    $highRisk = @($entries | Where-Object { [bool](Get-BoostLabRuntimeSourceIntentPropertyValue -InputObject $_ -Name 'HighRiskBlocker' -DefaultValue $false) })
    $runtimePayloadReadiness = if ($null -ne $RuntimePayloadManifest -and (Get-Command -Name 'Get-BoostLabRuntimePayloadReadiness' -ErrorAction SilentlyContinue)) {
        Get-BoostLabRuntimePayloadReadiness -ProjectRoot $ProjectRoot -Manifest $RuntimePayloadManifest
    }
    else {
        $null
    }
    $operationDescriptorReadiness = if ($null -ne $OperationDescriptorManifest -and (Get-Command -Name 'Get-BoostLabRuntimeOperationDescriptorReadiness' -ErrorAction SilentlyContinue)) {
        Get-BoostLabRuntimeOperationDescriptorReadiness -ProjectRoot $ProjectRoot -Manifest $OperationDescriptorManifest
    }
    else {
        $null
    }
    $sourceReferenceScan = Get-BoostLabExternalPackageSourceReferenceScan -ProjectRoot $ProjectRoot

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

    $sourceIntentBlockers = @(
        $blockedEntries | ForEach-Object {
            [pscustomobject]@{
                EntryId = [string]$_.EntryId
                ToolId = [string]$_.ToolId
                SourceEvidenceMode = [string]$_.SourceEvidenceMode
                BlockerReason = [string]$_.BlockerReason
            }
        }
    )

    $externalRuntimeReady = ([bool]$mode.IsExternalRuntime -and $blockedEntries.Count -eq 0 -and $generatedPayloadRequired.Count -eq 0)
    $externalPackageBuildReady = ($externalRuntimeReady -and -not [bool]$sourceReferenceScan.ExternalPackageSourceFreeLaunchBlocked)
    [pscustomobject]@{
        Mode = [string]$mode.Mode
        ExternalRuntimeReady = [bool]$externalRuntimeReady
        ExternalPackageBuildReady = [bool]$externalPackageBuildReady
        ExternalPackageSourceFreeLaunchBlocked = [bool]$sourceReferenceScan.ExternalPackageSourceFreeLaunchBlocked
        TotalSourceIntentEntries = [int]$entries.Count
        ExternalReadyEntries = [int]$externalReady.Count
        BlockedEntries = [int]$blockedEntries.Count
        RemainingBlockedEntries = [int]$blockedEntries.Count
        PayloadBackedReadyEntries = [int]$payloadBackedReady.Count
        DescriptorBackedReadyEntries = [int]$descriptorBackedReady.Count
        GeneratedPayloadRequiredEntries = [int]$generatedPayloadRequired.Count
        RawSourceRequiredEntries = [int]$rawSourceRequired.Count
        InternalRawSourceReferenceEntries = [int]$rawSourceRequired.Count
        ExternalRawSourceVerificationEntries = if ([bool]$mode.IsExternalRuntime) { 0 } else { [int]$rawSourceRequired.Count }
        TotalPayloads = if ($null -ne $runtimePayloadReadiness) { [int]$runtimePayloadReadiness.TotalPayloadEntries } else { 0 }
        ReadyPayloads = if ($null -ne $runtimePayloadReadiness) { [int]$runtimePayloadReadiness.GeneratedRuntimePayloadAvailableEntries } else { 0 }
        BlockedPayloads = if ($null -ne $runtimePayloadReadiness) { [int]$runtimePayloadReadiness.BlockedPayloadEntries + [int]$runtimePayloadReadiness.MissingPayloadEntries + [int]$runtimePayloadReadiness.FailedPayloadEntries } else { 0 }
        TotalOperationDescriptors = if ($null -ne $operationDescriptorReadiness) { [int]$operationDescriptorReadiness.TotalDescriptors } else { 0 }
        ValidOperationDescriptors = if ($null -ne $operationDescriptorReadiness) { [int]$operationDescriptorReadiness.ReadyForFutureExternalModeDescriptors } else { 0 }
        MissingOrInvalidOperationDescriptors = if ($null -ne $operationDescriptorReadiness) { [int]$operationDescriptorReadiness.FailedDescriptors + @($operationDescriptorReadiness.MissingSourceIntentBlockers).Count } else { 0 }
        SourceFreePackageBlockerCount = [int]$sourceReferenceScan.SourceFreePackageBlockerCount
        SourceFreePackageBlockers = @($sourceReferenceScan.SourceFreePackageBlockers)
        SourceReferenceScan = $sourceReferenceScan
        SourceIntentBlockers = $sourceIntentBlockers
        HighRiskBlockerCount = [int]$highRiskRecords.Count
        HighRiskBlockers = $highRiskRecords
        RuntimeActionExecuted = $false
        ChangesExecuted = $false
        Message = if ($externalRuntimeReady) {
            if ([bool]$sourceReferenceScan.ExternalPackageSourceFreeLaunchBlocked) {
                'External runtime source intent entries are payload-backed or descriptor-backed; source-free package launch remains blocked by direct module source references.'
            }
            else {
                'External runtime source intent entries are payload-backed or descriptor-backed.'
            }
        }
        else {
            'External runtime source intent readiness remains blocked by missing or invalid payload/descriptor evidence.'
        }
    }
}

Export-ModuleMember -Function @(
    'Get-BoostLabRuntimeSourceIntentManifest'
    'Resolve-BoostLabRuntimeSourceIntent'
    'Get-BoostLabRuntimePackageMode'
    'Get-BoostLabExternalPackageSourceReferenceScan'
    'Test-BoostLabExternalRuntimeReadiness'
)
