Set-StrictMode -Version Latest

$script:BoostLabRuntimeOperationDescriptorManifestPath = Join-Path `
    (Split-Path -Parent $PSScriptRoot) `
    'config\RuntimeOperationDescriptors.psd1'
$script:BoostLabRuntimeOperationDescriptorReadyState = 'ReadyForFutureExternalMode'
$script:BoostLabRuntimeOperationDescriptorWiredState = 'Wired'

function Get-BoostLabRuntimeOperationDescriptorPropertyValue {
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

function Get-BoostLabRuntimeOperationDescriptorManifest {
    [CmdletBinding()]
    [OutputType([System.Collections.IDictionary])]
    param(
        [string]$ManifestPath = $script:BoostLabRuntimeOperationDescriptorManifestPath
    )

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        throw "Runtime operation descriptor manifest was not found: $ManifestPath"
    }

    $manifest = Import-PowerShellDataFile -LiteralPath $ManifestPath
    if (-not ($manifest -is [System.Collections.IDictionary])) {
        throw "Runtime operation descriptor manifest did not load as a dictionary: $ManifestPath"
    }
    if (-not $manifest.Contains('Entries')) {
        throw 'Runtime operation descriptor manifest is missing Entries.'
    }

    return $manifest
}

function Get-BoostLabRuntimeOperationDescriptorEntries {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [AllowNull()]
        [object]$Manifest = $null,

        [string]$ManifestPath = $script:BoostLabRuntimeOperationDescriptorManifestPath
    )

    if ($null -eq $Manifest) {
        $Manifest = Get-BoostLabRuntimeOperationDescriptorManifest -ManifestPath $ManifestPath
    }

    $entryTable = Get-BoostLabRuntimeOperationDescriptorPropertyValue -InputObject $Manifest -Name 'Entries'
    if (-not ($entryTable -is [System.Collections.IDictionary])) {
        throw 'Runtime operation descriptor Entries must be a dictionary.'
    }

    $entries = [System.Collections.Generic.List[object]]::new()
    foreach ($entryId in @($entryTable.Keys | Sort-Object)) {
        $entry = $entryTable[$entryId]
        if (-not ($entry -is [System.Collections.IDictionary])) {
            throw "Runtime operation descriptor entry must be a dictionary: $entryId"
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

function Resolve-BoostLabRuntimeOperationDescriptor {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [string]$DescriptorId = '',

        [string]$ToolId = '',

        [string]$SourceIntentId = '',

        [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),

        [AllowNull()]
        [object]$Manifest = $null,

        [string]$ManifestPath = $script:BoostLabRuntimeOperationDescriptorManifestPath
    )

    if ($null -eq $Manifest) {
        $Manifest = Get-BoostLabRuntimeOperationDescriptorManifest -ManifestPath $ManifestPath
    }

    $entries = @(Get-BoostLabRuntimeOperationDescriptorEntries -Manifest $Manifest)
    if (-not [string]::IsNullOrWhiteSpace($DescriptorId)) {
        $entries = @($entries | Where-Object { [string]$_.DescriptorId -eq $DescriptorId })
    }
    if (-not [string]::IsNullOrWhiteSpace($ToolId)) {
        $entries = @($entries | Where-Object { [string]$_.ToolId -eq $ToolId })
    }
    if (-not [string]::IsNullOrWhiteSpace($SourceIntentId)) {
        $entries = @($entries | Where-Object { [string]$_.SourceIntentId -eq $SourceIntentId })
    }

    $resolved = [System.Collections.Generic.List[object]]::new()
    foreach ($entry in $entries) {
        $moduleRelativePath = [string](Get-BoostLabRuntimeOperationDescriptorPropertyValue -InputObject $entry -Name 'ModuleRelativePath' -DefaultValue '')
        $modulePath = if ([string]::IsNullOrWhiteSpace($moduleRelativePath)) {
            ''
        }
        else {
            Join-Path $ProjectRoot ($moduleRelativePath.Replace('/', '\'))
        }
        $moduleStatus = [string](Get-BoostLabRuntimeOperationDescriptorPropertyValue -InputObject $entry -Name 'ModuleRuntimeWiringStatus' -DefaultValue '')
        $externalRuntimeBlocked = ($moduleStatus -ne $script:BoostLabRuntimeOperationDescriptorWiredState)

        $record = [ordered]@{}
        foreach ($property in $entry.PSObject.Properties) {
            $record[$property.Name] = $property.Value
        }

        $record['ModulePath'] = $modulePath
        $record['ModuleExists'] = (-not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath -PathType Leaf))
        $record['ExternalRuntimeBlocked'] = [bool]$externalRuntimeBlocked
        $record['BlockerReason'] = if ($externalRuntimeBlocked) { 'ModuleRuntimeWiringStatus' } else { '' }
        $record['RuntimeActionExecuted'] = $false
        $record['ChangesExecuted'] = $false
        $resolved.Add([pscustomobject]$record)
    }

    return $resolved.ToArray()
}

function Test-BoostLabRuntimeOperationDescriptorEntry {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Entry,

        [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $requiredFields = @(
        'DescriptorId'
        'ToolId'
        'ToolTitle'
        'Stage'
        'SourceIntentId'
        'ModuleRelativePath'
        'SourceRawSha256'
        'SourceCanonicalTextSha256'
        'DescriptorKind'
        'Actions'
        'Branches'
        'OperationCategories'
        'OperationCount'
        'OperationSummary'
        'Capabilities'
        'RuntimeUse'
        'ExternalHandling'
        'ExternalModeTreatment'
        'RuntimeWiringStatus'
        'ModuleRuntimeWiringStatus'
        'CustomerVisible'
        'RuntimeActionExecuted'
        'ChangesExecuted'
    )

    foreach ($field in $requiredFields) {
        $value = Get-BoostLabRuntimeOperationDescriptorPropertyValue -InputObject $Entry -Name $field
        if ($null -eq $value) {
            $errors.Add("Missing field: $field")
            continue
        }
        if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) {
            $errors.Add("Blank field: $field")
        }
    }

    $descriptorId = [string](Get-BoostLabRuntimeOperationDescriptorPropertyValue -InputObject $Entry -Name 'DescriptorId' -DefaultValue '')
    $toolId = [string](Get-BoostLabRuntimeOperationDescriptorPropertyValue -InputObject $Entry -Name 'ToolId' -DefaultValue '')
    $sourceIntentId = [string](Get-BoostLabRuntimeOperationDescriptorPropertyValue -InputObject $Entry -Name 'SourceIntentId' -DefaultValue '')
    $moduleRelativePath = [string](Get-BoostLabRuntimeOperationDescriptorPropertyValue -InputObject $Entry -Name 'ModuleRelativePath' -DefaultValue '')
    $runtimeWiringStatus = [string](Get-BoostLabRuntimeOperationDescriptorPropertyValue -InputObject $Entry -Name 'RuntimeWiringStatus' -DefaultValue '')
    $moduleRuntimeWiringStatus = [string](Get-BoostLabRuntimeOperationDescriptorPropertyValue -InputObject $Entry -Name 'ModuleRuntimeWiringStatus' -DefaultValue '')
    $sourceRawSha256 = [string](Get-BoostLabRuntimeOperationDescriptorPropertyValue -InputObject $Entry -Name 'SourceRawSha256' -DefaultValue '')
    $sourceCanonicalTextSha256 = [string](Get-BoostLabRuntimeOperationDescriptorPropertyValue -InputObject $Entry -Name 'SourceCanonicalTextSha256' -DefaultValue '')
    $modulePath = if ([string]::IsNullOrWhiteSpace($moduleRelativePath)) {
        ''
    }
    else {
        Join-Path $ProjectRoot ($moduleRelativePath.Replace('/', '\'))
    }
    $moduleExists = (-not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath -PathType Leaf))

    if ($descriptorId -and $descriptorId -ne [string](Get-BoostLabRuntimeOperationDescriptorPropertyValue -InputObject $Entry -Name 'EntryId' -DefaultValue $descriptorId)) {
        $errors.Add("DescriptorId does not match entry id: $descriptorId")
    }
    if ($sourceRawSha256 -notmatch '^[A-Fa-f0-9]{64}$') {
        $errors.Add("Invalid SourceRawSha256: $descriptorId")
    }
    if ($sourceCanonicalTextSha256 -notmatch '^[A-Fa-f0-9]{64}$') {
        $errors.Add("Invalid SourceCanonicalTextSha256: $descriptorId")
    }
    if (-not $moduleExists) {
        $errors.Add("Module path does not exist: $moduleRelativePath")
    }

    $descriptorReady = ($errors.Count -eq 0 -and $runtimeWiringStatus -eq $script:BoostLabRuntimeOperationDescriptorReadyState)
    $moduleRuntimeWired = ($moduleRuntimeWiringStatus -eq $script:BoostLabRuntimeOperationDescriptorWiredState)

    [pscustomobject]@{
        DescriptorId = $descriptorId
        ToolId = $toolId
        SourceIntentId = $sourceIntentId
        ModuleRelativePath = $moduleRelativePath
        ModulePath = $modulePath
        ModuleExists = [bool]$moduleExists
        DescriptorStatus = if ($errors.Count -eq 0) { 'Passed' } else { 'Failed' }
        RuntimeWiringStatus = $runtimeWiringStatus
        ModuleRuntimeWiringStatus = $moduleRuntimeWiringStatus
        DescriptorReadyForFutureExternalMode = [bool]$descriptorReady
        ModuleRuntimeWired = [bool]$moduleRuntimeWired
        ExternalRuntimeBlocked = [bool](-not $moduleRuntimeWired)
        BlockerReason = if ($moduleRuntimeWired) { '' } else { 'ModuleRuntimeWiringStatus' }
        RuntimeActionExecuted = $false
        ChangesExecuted = $false
        Errors = $errors.ToArray()
    }
}

function Test-BoostLabRuntimeOperationDescriptor {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [string]$DescriptorId = '',

        [string]$ToolId = '',

        [string]$SourceIntentId = '',

        [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),

        [AllowNull()]
        [object]$Manifest = $null,

        [string]$ManifestPath = $script:BoostLabRuntimeOperationDescriptorManifestPath
    )

    if ($null -eq $Manifest) {
        $Manifest = Get-BoostLabRuntimeOperationDescriptorManifest -ManifestPath $ManifestPath
    }

    $entries = @(Get-BoostLabRuntimeOperationDescriptorEntries -Manifest $Manifest)
    if (-not [string]::IsNullOrWhiteSpace($DescriptorId)) {
        $entries = @($entries | Where-Object { [string]$_.DescriptorId -eq $DescriptorId })
    }
    if (-not [string]::IsNullOrWhiteSpace($ToolId)) {
        $entries = @($entries | Where-Object { [string]$_.ToolId -eq $ToolId })
    }
    if (-not [string]::IsNullOrWhiteSpace($SourceIntentId)) {
        $entries = @($entries | Where-Object { [string]$_.SourceIntentId -eq $SourceIntentId })
    }

    return @(
        $entries | ForEach-Object {
            Test-BoostLabRuntimeOperationDescriptorEntry -Entry $_ -ProjectRoot $ProjectRoot
        }
    )
}

function Get-BoostLabRuntimeOperationDescriptorReadiness {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),

        [AllowNull()]
        [object]$Manifest = $null,

        [string]$ManifestPath = $script:BoostLabRuntimeOperationDescriptorManifestPath
    )

    if ($null -eq $Manifest) {
        $Manifest = Get-BoostLabRuntimeOperationDescriptorManifest -ManifestPath $ManifestPath
    }

    $entries = @(Get-BoostLabRuntimeOperationDescriptorEntries -Manifest $Manifest)
    $statuses = @(Test-BoostLabRuntimeOperationDescriptor -ProjectRoot $ProjectRoot -Manifest $Manifest)
    $requiredSourceIntentBlockers = @(
        Get-BoostLabRuntimeOperationDescriptorPropertyValue -InputObject $Manifest -Name 'RequiredSourceIntentBlockers' -DefaultValue @()
    )
    $coveredSourceIntentBlockers = @(
        $entries |
            Where-Object { [string]$_.SourceIntentId -in $requiredSourceIntentBlockers } |
            ForEach-Object { [string]$_.SourceIntentId } |
            Sort-Object -Unique
    )
    $missingSourceIntentBlockers = @(
        $requiredSourceIntentBlockers |
            Where-Object { [string]$_ -notin $coveredSourceIntentBlockers } |
            Sort-Object
    )
    $failed = @($statuses | Where-Object { [string]$_.DescriptorStatus -ne 'Passed' })
    $readyForFuture = @($statuses | Where-Object { [bool]$_.DescriptorReadyForFutureExternalMode })
    $notWired = @($statuses | Where-Object { -not [bool]$_.ModuleRuntimeWired })
    $blockers = @($statuses | Where-Object { [bool]$_.ExternalRuntimeBlocked })
    $descriptorCoverageReady = (
        $entries.Count -gt 0 -and
        $failed.Count -eq 0 -and
        $missingSourceIntentBlockers.Count -eq 0 -and
        $coveredSourceIntentBlockers.Count -eq $requiredSourceIntentBlockers.Count
    )

    [pscustomobject]@{
        TotalDescriptors = [int]$entries.Count
        RequiredSourceIntentBlockers = [int]$requiredSourceIntentBlockers.Count
        CoveredSourceIntentBlockers = [int]$coveredSourceIntentBlockers.Count
        MissingSourceIntentBlockers = $missingSourceIntentBlockers
        FailedDescriptors = [int]$failed.Count
        ReadyForFutureExternalModeDescriptors = [int]$readyForFuture.Count
        NotWiredDescriptors = [int]$notWired.Count
        ExternalRuntimeBlockerDescriptors = [int]$blockers.Count
        DescriptorCoverageReady = [bool]$descriptorCoverageReady
        ExternalRuntimeReady = [bool]($descriptorCoverageReady -and $blockers.Count -eq 0)
        RuntimeActionExecuted = $false
        ChangesExecuted = $false
        Message = if ($descriptorCoverageReady -and $blockers.Count -gt 0) {
            'Runtime operation descriptor coverage is available, but modules are not wired for external runtime descriptor use.'
        }
        elseif ($descriptorCoverageReady) {
            'Runtime operation descriptors are covered and wired for external runtime.'
        }
        else {
            'Runtime operation descriptor coverage is incomplete or failed validation.'
        }
    }
}

function Get-BoostLabExternalOperationDescriptorBlockers {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),

        [AllowNull()]
        [object]$Manifest = $null,

        [string]$ManifestPath = $script:BoostLabRuntimeOperationDescriptorManifestPath
    )

    if ($null -eq $Manifest) {
        $Manifest = Get-BoostLabRuntimeOperationDescriptorManifest -ManifestPath $ManifestPath
    }

    return @(
        Test-BoostLabRuntimeOperationDescriptor -ProjectRoot $ProjectRoot -Manifest $Manifest |
            Where-Object { [bool]$_.ExternalRuntimeBlocked -or [string]$_.DescriptorStatus -ne 'Passed' } |
            Sort-Object -Property SourceIntentId
    )
}

Export-ModuleMember -Function @(
    'Get-BoostLabRuntimeOperationDescriptorManifest'
    'Get-BoostLabRuntimeOperationDescriptorEntries'
    'Resolve-BoostLabRuntimeOperationDescriptor'
    'Test-BoostLabRuntimeOperationDescriptor'
    'Get-BoostLabRuntimeOperationDescriptorReadiness'
    'Get-BoostLabExternalOperationDescriptorBlockers'
)
