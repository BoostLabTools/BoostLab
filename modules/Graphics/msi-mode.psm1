Set-StrictMode -Version Latest

$coreRoot = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path $coreRoot 'Verification.psm1') -Scope Local -ErrorAction Stop
}
if (-not (Get-Command -Name 'New-BoostLabRegistryStateCapture' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path $coreRoot 'StateCapture.psm1') -Scope Local -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'msi-mode'
    Title = 'Msi Mode'
    Stage = 'Graphics'
    Order = 7
    Type = 'action'
    RiskLevel = 'high'
    Description = 'Path B step 5 of 5. Apply or default the source-defined NVIDIA MSI mode registry value only after NVIDIA-only target discovery and registry state capture.'
    Actions = @('Analyze', 'Apply', 'Default', 'Restore')
    Capabilities = [ordered]@{
        RequiresAdmin = $true
        RequiresInternet = $false
        CanReboot = $false
        CanModifyRegistry = $true
        CanModifyServices = $false
        CanInstallSoftware = $false
        CanDownload = $false
        CanModifyDrivers = $false
        CanModifySecurity = $false
        CanDeleteFiles = $false
        UsesTrustedInstaller = $false
        UsesSafeMode = $false
        SupportsDefault = $true
        SupportsRestore = $false
        NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Analyze', 'Apply', 'Default', 'Restore')
$script:BoostLabExpectedSourceHash = '94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7'
$script:BoostLabSourceRelativePath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1'
$script:BoostLabMsiModeEnumRoot = 'HKLM:\SYSTEM\ControlSet001\Enum'
$script:BoostLabMsiModeRegistrySuffix = 'Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'
$script:BoostLabMsiModeValueName = 'MSISupported'
$script:BoostLabMsiModeValueType = 'DWord'
$script:BoostLabMsiModeApplyValue = 1
$script:BoostLabMsiModeDefaultValue = 0

function Get-BoostLabMsiModeSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $projectRoot ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabMsiModeSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabMsiModeSourcePath
    $exists = Test-Path -LiteralPath $sourcePath -PathType Leaf
    $detectedHash = if ($exists) {
        (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
    }
    else {
        ''
    }

    return [pscustomobject]@{
        SourcePath = $sourcePath
        SourceRelativePath = $script:BoostLabSourceRelativePath
        Exists = $exists
        ExpectedSha256 = $script:BoostLabExpectedSourceHash
        DetectedSha256 = $detectedHash
        ChecksumStatus = if ($exists -and $detectedHash -eq $script:BoostLabExpectedSourceHash) {
            'Passed'
        }
        elseif ($exists) {
            'Failed'
        }
        else {
            'Missing'
        }
    }
}

function Test-BoostLabAdministrator {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function ConvertTo-BoostLabMsiModeRegistryPath {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $normalized = $Path.Trim().TrimEnd('\')
    $normalized = $normalized -replace '^Microsoft\.PowerShell\.Core\\Registry::HKEY_LOCAL_MACHINE\\', 'HKLM:\'
    $normalized = $normalized -replace '^Registry::HKEY_LOCAL_MACHINE\\', 'HKLM:\'
    $normalized = $normalized -replace '^HKEY_LOCAL_MACHINE\\', 'HKLM:\'
    return $normalized
}

function Test-BoostLabMsiModeRegistryTarget {
    param(
        [Parameter(Mandatory)]
        [string]$RegistryPath
    )

    $normalized = ConvertTo-BoostLabMsiModeRegistryPath -Path $RegistryPath
    if ($normalized.IndexOfAny([char[]]'*?[]') -ge 0) {
        return $false
    }
    if (-not $normalized.StartsWith($script:BoostLabMsiModeEnumRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
        return $false
    }
    if (-not $normalized.EndsWith('\' + $script:BoostLabMsiModeRegistrySuffix, [StringComparison]::OrdinalIgnoreCase)) {
        return $false
    }

    $relative = $normalized.Substring(($script:BoostLabMsiModeEnumRoot + '\').Length)
    $suffixLength = ('\' + $script:BoostLabMsiModeRegistrySuffix).Length
    $instanceId = $relative.Substring(0, $relative.Length - $suffixLength)
    return -not [string]::IsNullOrWhiteSpace($instanceId)
}

function ConvertTo-BoostLabMsiModeDeviceRegistryPath {
    param(
        [Parameter(Mandatory)]
        [string]$InstanceId
    )

    $cleanInstanceId = $InstanceId.Trim().Trim('\')
    if ([string]::IsNullOrWhiteSpace($cleanInstanceId)) {
        throw 'A display device InstanceId is required.'
    }
    if ($cleanInstanceId.IndexOfAny([char[]]'*?[]') -ge 0) {
        throw "Wildcard display device InstanceId is not allowed: $cleanInstanceId"
    }

    return '{0}\{1}\{2}' -f $script:BoostLabMsiModeEnumRoot, $cleanInstanceId, $script:BoostLabMsiModeRegistrySuffix
}

function Get-BoostLabMsiModeIdentityEvidence {
    param(
        [AllowNull()]
        [object]$InputObject
    )

    $evidence = [System.Collections.Generic.List[string]]::new()
    foreach ($name in @(
        'InstanceId',
        'DeviceID',
        'FriendlyName',
        'Name',
        'Description',
        'Manufacturer',
        'Service',
        'Class',
        'PNPClass',
        'Status',
        'HardwareID',
        'CompatibleID',
        'DriverDesc',
        'ProviderName',
        'MatchingDeviceId',
        'InfSection',
        'HardwareInformation.AdapterString',
        'HardwareInformation.ChipType',
        'ComponentId'
    )) {
        if ($null -ne $InputObject -and $null -ne $InputObject.PSObject.Properties[$name]) {
            $value = [string]$InputObject.PSObject.Properties[$name].Value
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                $evidence.Add(('{0}={1}' -f $name, $value))
            }
        }
    }

    return $evidence.ToArray()
}

function Test-BoostLabMsiModeNvidiaEvidence {
    param(
        [AllowNull()]
        [string[]]$Evidence
    )

    $combined = (@($Evidence) -join ' ')
    return (
        $combined -match '(?i)\bNVIDIA\b' -or
        $combined -match '(?i)VEN_10DE'
    )
}

function Test-BoostLabMsiModeKnownExcludedEvidence {
    param(
        [AllowNull()]
        [string[]]$Evidence
    )

    $combined = (@($Evidence) -join ' ')
    return $combined -match '(?i)(Microsoft|Remote Display|RDP|Basic Display|Intel|Advanced Micro Devices|AMD|Radeon|VMware|VirtualBox|Parallels)'
}

function New-BoostLabMsiModeResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$CommandStatus,

        [Parameter(Mandatory)]
        [string]$VerificationStatus,

        [Parameter(Mandatory)]
        [string]$Message,

        [AllowNull()]
        [object]$Data = $null,

        [AllowNull()]
        [object]$VerificationResult = $null,

        [string[]]$Warnings = @(),

        [string[]]$Errors = @(),

        [bool]$Cancelled = $false
    )

    return [pscustomobject]@{
        Success = $Success
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Action = $Action
        Status = $Status
        CommandStatus = $CommandStatus
        VerificationStatus = $VerificationStatus
        Message = $Message
        RestartRequired = $false
        Cancelled = $Cancelled
        ChangesExecuted = $false
        Timestamp = Get-Date
        Data = $Data
        VerificationResult = $VerificationResult
        Warnings = @($Warnings)
        Errors = @($Errors)
    }
}

function Get-BoostLabMsiModeRealTargets {
    $targets = [System.Collections.Generic.List[object]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()

    try {
        if (-not (Get-Command -Name 'Get-PnpDevice' -ErrorAction SilentlyContinue)) {
            return [pscustomobject]@{
                Succeeded = $false
                Targets = @()
                Warnings = @('Get-PnpDevice is not available, so display-device discovery cannot run.')
                Message = 'Msi Mode display-device discovery is unavailable.'
            }
        }

        foreach ($device in @(Get-PnpDevice -Class Display -ErrorAction Stop)) {
            $instanceId = if ($null -ne $device.PSObject.Properties['InstanceId']) {
                [string]$device.InstanceId
            }
            else {
                ''
            }
            if ([string]::IsNullOrWhiteSpace($instanceId)) {
                $warnings.Add('Skipped a display device because its InstanceId was unavailable.')
                continue
            }

            $path = ConvertTo-BoostLabMsiModeRegistryPath -Path (ConvertTo-BoostLabMsiModeDeviceRegistryPath -InstanceId $instanceId)
            if (-not (Test-BoostLabMsiModeRegistryTarget -RegistryPath $path)) {
                $warnings.Add("Skipped target outside approved Msi Mode Enum scope: $path")
                continue
            }

            $evidence = @(Get-BoostLabMsiModeIdentityEvidence -InputObject $device)
            $isNvidia = Test-BoostLabMsiModeNvidiaEvidence -Evidence $evidence
            $targets.Add(
                [pscustomobject]@{
                    RegistryPath = $path
                    InstanceId = $instanceId
                    ValueName = $script:BoostLabMsiModeValueName
                    NvidiaTarget = $isNvidia
                    TargetingStatus = if ($isNvidia) { 'NvidiaVerified' } else { 'AmbiguousOrNonNvidia' }
                    Evidence = $evidence
                }
            )
        }
    }
    catch {
        $warnings.Add("Msi Mode target discovery failed: $($_.Exception.Message)")
    }

    return [pscustomobject]@{
        Succeeded = $warnings.Count -eq 0
        Targets = @($targets | Sort-Object RegistryPath -Unique)
        Warnings = $warnings.ToArray()
        Message = if ($targets.Count -eq 0) {
            'No source-targeted display-device Msi Mode registry targets were found.'
        }
        else {
            '{0} source-targeted display-device Msi Mode registry target(s) detected.' -f $targets.Count
        }
    }
}

function Get-BoostLabMsiModeDiscovery {
    param(
        [AllowNull()]
        [scriptblock]$TargetEnumerator = $null
    )

    $discovery = if ($null -ne $TargetEnumerator) {
        & $TargetEnumerator
    }
    else {
        Get-BoostLabMsiModeRealTargets
    }

    if ($null -eq $discovery -or $null -eq $discovery.PSObject.Properties['Targets']) {
        return [pscustomobject]@{
            Succeeded = $false
            Targets = @()
            EligibleTargets = @()
            ExcludedTargets = @()
            AmbiguousTargets = @()
            Warnings = @()
            Blockers = @('Target discovery returned an invalid result.')
            NvidiaOnly = $false
            Message = 'Msi Mode target discovery returned an invalid result.'
        }
    }

    $targets = [System.Collections.Generic.List[object]]::new()
    $eligibleTargets = [System.Collections.Generic.List[object]]::new()
    $excludedTargets = [System.Collections.Generic.List[object]]::new()
    $ambiguousTargets = [System.Collections.Generic.List[object]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    $blockers = [System.Collections.Generic.List[string]]::new()
    foreach ($warning in @($discovery.Warnings)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$warning)) {
            $warnings.Add([string]$warning)
        }
    }

    foreach ($target in @($discovery.Targets)) {
        $path = if (
            $null -ne $target.PSObject.Properties['RegistryPath'] -and
            -not [string]::IsNullOrWhiteSpace([string]$target.RegistryPath)
        ) {
            ConvertTo-BoostLabMsiModeRegistryPath -Path ([string]$target.RegistryPath)
        }
        elseif (
            $null -ne $target.PSObject.Properties['InstanceId'] -and
            -not [string]::IsNullOrWhiteSpace([string]$target.InstanceId)
        ) {
            ConvertTo-BoostLabMsiModeRegistryPath -Path (ConvertTo-BoostLabMsiModeDeviceRegistryPath -InstanceId ([string]$target.InstanceId))
        }
        else {
            ''
        }
        if (-not (Test-BoostLabMsiModeRegistryTarget -RegistryPath $path)) {
            $blockers.Add("Target is outside the approved Msi Mode Enum registry scope: $path")
            continue
        }

        $evidence = if ($null -ne $target.PSObject.Properties['Evidence']) {
            @($target.Evidence)
        }
        else {
            @()
        }
        $nvidiaTarget = if ($null -ne $target.PSObject.Properties['NvidiaTarget']) {
            [bool]$target.NvidiaTarget
        }
        else {
            Test-BoostLabMsiModeNvidiaEvidence -Evidence $evidence
        }
        if (-not $nvidiaTarget) {
            $combinedEvidence = @($evidence) -join ' '
            $isKnownExcludedTarget = Test-BoostLabMsiModeKnownExcludedEvidence -Evidence $evidence
            if ($isKnownExcludedTarget) {
                $exclusionReason = 'Microsoft/RDP/non-NVIDIA display adapter'
                $excludedTarget = [pscustomobject]@{
                    RegistryPath = $path
                    InstanceId = if ($null -ne $target.PSObject.Properties['InstanceId']) { [string]$target.InstanceId } else { '' }
                    ValueName = $script:BoostLabMsiModeValueName
                    NvidiaTarget = $false
                    Eligible = $false
                    Excluded = $true
                    Ambiguous = $false
                    TargetingStatus = 'ExcludedNonNvidia'
                    ExclusionReason = $exclusionReason
                    AmbiguityReason = ''
                    Evidence = $evidence
                }
                $targets.Add($excludedTarget)
                $excludedTargets.Add($excludedTarget)
                $warnings.Add("Skipped Msi Mode target because it is not provably NVIDIA-owned: $path ($exclusionReason)")
                continue
            }

            $ambiguousReason = if ([string]::IsNullOrWhiteSpace($combinedEvidence)) {
                'missing adapter identity evidence'
            }
            else {
                'identity evidence is neither NVIDIA nor a known excluded Microsoft/RDP adapter'
            }
            $ambiguousTarget = [pscustomobject]@{
                RegistryPath = $path
                InstanceId = if ($null -ne $target.PSObject.Properties['InstanceId']) { [string]$target.InstanceId } else { '' }
                ValueName = $script:BoostLabMsiModeValueName
                NvidiaTarget = $false
                Eligible = $false
                Excluded = $false
                Ambiguous = $true
                TargetingStatus = 'AmbiguousIdentity'
                ExclusionReason = ''
                AmbiguityReason = $ambiguousReason
                Evidence = $evidence
            }
            $targets.Add($ambiguousTarget)
            $ambiguousTargets.Add($ambiguousTarget)
            $blockers.Add("Target identity is ambiguous and cannot be written safely: $path ($ambiguousReason)")
            continue
        }

        $eligibleTarget = [pscustomobject]@{
            RegistryPath = $path
            InstanceId = if ($null -ne $target.PSObject.Properties['InstanceId']) { [string]$target.InstanceId } else { '' }
            ValueName = $script:BoostLabMsiModeValueName
            NvidiaTarget = $true
            Eligible = $true
            Excluded = $false
            Ambiguous = $false
            TargetingStatus = 'NvidiaVerified'
            ExclusionReason = ''
            AmbiguityReason = ''
            Evidence = $evidence
        }
        $targets.Add($eligibleTarget)
        $eligibleTargets.Add($eligibleTarget)
    }

    return [pscustomobject]@{
        Succeeded = [bool]$discovery.Succeeded -and $blockers.Count -eq 0
        Targets = @($targets | Sort-Object RegistryPath -Unique)
        EligibleTargets = @($eligibleTargets | Sort-Object RegistryPath -Unique)
        ExcludedTargets = @($excludedTargets | Sort-Object RegistryPath -Unique)
        AmbiguousTargets = @($ambiguousTargets | Sort-Object RegistryPath -Unique)
        Warnings = $warnings.ToArray()
        Blockers = $blockers.ToArray()
        NvidiaOnly = $eligibleTargets.Count -gt 0 -and $blockers.Count -eq 0 -and $ambiguousTargets.Count -eq 0
        Message = [string]$discovery.Message
    }
}

function Get-BoostLabMsiModeRegistryValueState {
    param(
        [Parameter(Mandatory)]
        [string]$RegistryPath,

        [string]$ItemType = 'RegistryValue',

        [string]$ValueName = $script:BoostLabMsiModeValueName
    )

    $path = ConvertTo-BoostLabMsiModeRegistryPath -Path $RegistryPath
    try {
        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            return [pscustomobject]@{
                ReadSucceeded = $true
                KeyExists = $false
                Exists = $false
                Metadata = $null
                DisplayValue = 'Absent'
                Message = 'Registry key is absent.'
            }
        }

        $key = Get-Item -LiteralPath $path -ErrorAction Stop
        $valueExists = $ValueName -in @($key.GetValueNames())
        if (-not $valueExists) {
            return [pscustomobject]@{
                ReadSucceeded = $true
                KeyExists = $true
                Exists = $false
                Metadata = $null
                DisplayValue = 'Absent'
                Message = 'Registry value is absent.'
            }
        }

        $valueType = [string]$key.GetValueKind($ValueName)
        $valueData = $key.GetValue($ValueName, $null, 'DoNotExpandEnvironmentNames')
        return [pscustomobject]@{
            ReadSucceeded = $true
            KeyExists = $true
            Exists = $true
            Metadata = [ordered]@{
                ValueName = $ValueName
                ValueType = $valueType
                ValueData = $valueData
            }
            DisplayValue = '{0} {1}' -f $valueType, $valueData
            Message = 'Registry value detected.'
        }
    }
    catch {
        return [pscustomobject]@{
            ReadSucceeded = $false
            KeyExists = $null
            Exists = $false
            Metadata = $null
            DisplayValue = 'Unknown'
            Message = $_.Exception.Message
        }
    }
}

function Set-BoostLabMsiModeRegistryValue {
    param(
        [Parameter(Mandatory)]
        [string]$RegistryPath,

        [Parameter(Mandatory)]
        [ValidateSet(0, 1)]
        [int]$Value
    )

    $path = ConvertTo-BoostLabMsiModeRegistryPath -Path $RegistryPath
    if (-not (Test-BoostLabMsiModeRegistryTarget -RegistryPath $path)) {
        throw "Registry target is outside the approved Msi Mode display-device Enum scope: $path"
    }
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        throw "Registry target does not exist: $path"
    }

    New-ItemProperty `
        -LiteralPath $path `
        -Name $script:BoostLabMsiModeValueName `
        -PropertyType $script:BoostLabMsiModeValueType `
        -Value $Value `
        -Force `
        -ErrorAction Stop | Out-Null
}

function New-BoostLabMsiModeCapturePolicy {
    param(
        [Parameter(Mandatory)]
        [object]$Target,

        [Parameter(Mandatory)]
        [string]$ScopeId
    )

    return @{
        SchemaVersion = '1.0'
        FileScopes = @()
        RegistryScopes = @(
            @{
                ScopeId = $ScopeId
                ToolIds = @([string]$script:BoostLabToolMetadata['Id'])
                AllowedPath = [string]$Target.RegistryPath
                AllowedValueNames = @($script:BoostLabMsiModeValueName)
                AllowKeyCapture = $false
                AllowProtectedSystem = $true
            }
        )
        DeniedRegistryPrefixes = @(
            'HKLM:\SYSTEM'
            'Registry::HKEY_LOCAL_MACHINE\SYSTEM'
        )
    }
}

function Test-BoostLabMsiModeState {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Analyze', 'Apply', 'Default')]
        [string]$ActionName,

        [AllowNull()]
        [object[]]$Targets = @(),

        [AllowNull()]
        [object[]]$CaptureRecords = @(),

        [AllowNull()]
        [scriptblock]$RegistryReader = $null
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    $targetCount = @($Targets).Count
    $captureCount = @($CaptureRecords).Count
    $expectedValue = if ($ActionName -eq 'Default') {
        $script:BoostLabMsiModeDefaultValue
    }
    else {
        $script:BoostLabMsiModeApplyValue
    }
    $reader = if ($null -ne $RegistryReader) {
        $RegistryReader
    }
    else {
        { param($Path, $ItemType, $ValueName) Get-BoostLabMsiModeRegistryValueState -RegistryPath $Path -ItemType $ItemType -ValueName $ValueName }
    }

    $checks.Add(
        (New-BoostLabVerificationCheck `
            -Name 'NVIDIA target discovery' `
            -Expected 'At least one provably NVIDIA source-targeted display-device Enum registry target for Apply or Default' `
            -Actual ("$targetCount target(s)") `
            -Status $(if ($targetCount -gt 0) { 'Passed' } elseif ($ActionName -eq 'Analyze') { 'Warning' } else { 'NotApplicable' }) `
            -Message $(if ($targetCount -gt 0) { 'NVIDIA display-device Enum registry targets were discovered.' } else { 'No NVIDIA display-device Enum registry targets were discovered.' }))
    )

    if ($ActionName -ne 'Analyze') {
        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name 'Pre-mutation capture records' `
                -Expected "$targetCount capture record(s)" `
                -Actual "$captureCount capture record(s)" `
                -Status $(if ($targetCount -gt 0 -and $captureCount -eq $targetCount) { 'Passed' } elseif ($targetCount -eq 0) { 'NotApplicable' } else { 'Failed' }) `
                -Message 'Each Msi Mode target must have a successful registry value capture before mutation.'))
    }

    foreach ($target in @($Targets)) {
        $identityStatus = if ([bool]$target.NvidiaTarget) { 'Passed' } else { 'Failed' }
        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name ('NVIDIA identity | {0}' -f [string]$target.RegistryPath) `
                -Expected 'NVIDIA evidence such as NVIDIA provider text or VEN_10DE' `
                -Actual ((@($target.Evidence) -join '; ')) `
                -Status $identityStatus `
                -Message $(if ([bool]$target.NvidiaTarget) { 'Target identity is NVIDIA-owned.' } else { 'Target identity is ambiguous or non-NVIDIA.' }))
        )

        $state = & $reader ([string]$target.RegistryPath) 'RegistryValue' $script:BoostLabMsiModeValueName
        if ($ActionName -eq 'Analyze') {
            $status = if ($null -eq $state -or -not [bool]$state.ReadSucceeded) {
                'Warning'
            }
            else {
                'Passed'
            }
            $expected = 'Readable Msi Mode value state'
        }
        else {
            $valueData = if ($null -ne $state -and $null -ne $state.Metadata) {
                $state.Metadata.ValueData
            }
            else {
                $null
            }
            $valueType = if ($null -ne $state -and $null -ne $state.Metadata) {
                [string]$state.Metadata.ValueType
            }
            else {
                ''
            }
            $status = if ($null -eq $state -or -not [bool]$state.ReadSucceeded) {
                'Warning'
            }
            elseif (-not [bool]$state.Exists) {
                'Failed'
            }
            elseif (
                $valueType -notin @('DWord', 'REG_DWORD') -or
                [string]$valueData -ne [string]$expectedValue
            ) {
                'Failed'
            }
            else {
                'Passed'
            }
            $expected = 'MSISupported DWORD {0}' -f $expectedValue
        }

        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name ('{0} | {1}' -f $script:BoostLabMsiModeValueName, [string]$target.RegistryPath) `
                -Expected $expected `
                -Actual $(if ($null -ne $state) { [string]$state.DisplayValue } else { 'Unknown' }) `
                -Status $status `
                -Message $(if ($null -ne $state) { [string]$state.Message } else { 'Registry reader returned no state.' }))
        )
    }

    $overallStatus = if (@($checks | Where-Object { $_.Status -eq 'Failed' }).Count -gt 0) {
        'Failed'
    }
    elseif (@($checks | Where-Object { $_.Status -eq 'Warning' }).Count -gt 0) {
        'Warning'
    }
    elseif (@($checks | Where-Object { $_.Status -eq 'NotApplicable' }).Count -gt 0) {
        'NotApplicable'
    }
    else {
        'Passed'
    }
    $expectedState = if ($ActionName -eq 'Analyze') {
        [pscustomobject]@{
            TargetDiscoveryOnly = $true
            TargetValue = $script:BoostLabMsiModeValueName
            SourceApplyValue = $script:BoostLabMsiModeApplyValue
            SourceDefaultValue = $script:BoostLabMsiModeDefaultValue
        }
    }
    else {
        [pscustomobject]@{
            TargetValue = $script:BoostLabMsiModeValueName
            ExpectedValueType = 'DWORD'
            ExpectedValueData = $expectedValue
            CaptureRequired = $true
        }
    }
    $detectedState = [pscustomobject]@{
        TargetCount = $targetCount
        CaptureRecordCount = $captureCount
        FailedChecks = @($checks | Where-Object { $_.Status -eq 'Failed' }).Count
        WarningChecks = @($checks | Where-Object { $_.Status -eq 'Warning' }).Count
    }
    $message = switch ($overallStatus) {
        'Passed' {
            if ($ActionName -eq 'Apply') {
                'All discovered NVIDIA Msi Mode targets have MSISupported set to DWORD 1.'
            }
            elseif ($ActionName -eq 'Default') {
                'All discovered NVIDIA Msi Mode targets have MSISupported set to DWORD 0.'
            }
            else {
                'Msi Mode NVIDIA display-device Enum registry targets were analyzed.'
            }
        }
        'Warning' { 'Msi Mode target state was analyzed with warnings.' }
        'NotApplicable' { 'No NVIDIA Msi Mode registry targets were found.' }
        default { 'One or more Msi Mode registry targets did not match the expected state.' }
    }

    return New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $ActionName `
        -Status $overallStatus `
        -ExpectedState $expectedState `
        -DetectedState $detectedState `
        -Checks $checks.ToArray() `
        -Message $message
}

function Invoke-BoostLabMsiModeAnalyze {
    param(
        [AllowNull()]
        [scriptblock]$TargetEnumerator = $null,

        [AllowNull()]
        [scriptblock]$RegistryReader = $null
    )

    $source = Get-BoostLabMsiModeSourceStatus
    $discovery = Get-BoostLabMsiModeDiscovery -TargetEnumerator $TargetEnumerator
    $eligibleTargets = @($discovery.EligibleTargets)
    $excludedTargets = @($discovery.ExcludedTargets)
    $ambiguousTargets = @($discovery.AmbiguousTargets)
    $verification = Test-BoostLabMsiModeState `
        -ActionName 'Analyze' `
        -Targets $eligibleTargets `
        -RegistryReader $RegistryReader

    $applyAvailable = (
        [string]$source.ChecksumStatus -eq 'Passed' -and
        $eligibleTargets.Count -gt 0 -and
        @($discovery.Blockers).Count -eq 0
    )
    $data = [pscustomobject]@{
        Source = $source
        PathBWorkflow = 'Driver Install Latest -> Nvidia Settings -> HDCP -> P0 State -> Msi Mode'
        PathBStepNumber = 5
        PathBStepTotal = 5
        PathBStep = '5 of 5'
        SourceRegistryRoot = $script:BoostLabMsiModeEnumRoot
        SourceRegistrySuffix = $script:BoostLabMsiModeRegistrySuffix
        SourceRegistryValueName = $script:BoostLabMsiModeValueName
        SourceRegistryValueType = 'REG_DWORD'
        SourceApplyValue = $script:BoostLabMsiModeApplyValue
        SourceDefaultValue = $script:BoostLabMsiModeDefaultValue
        TargetCount = @($discovery.Targets).Count
        Targets = @($discovery.Targets)
        EligibleTargetCount = $eligibleTargets.Count
        EligibleTargets = $eligibleTargets
        ExcludedTargetCount = $excludedTargets.Count
        ExcludedTargets = $excludedTargets
        AmbiguousTargetCount = $ambiguousTargets.Count
        AmbiguousTargets = $ambiguousTargets
        NvidiaOnlyTargetingStatus = if ($applyAvailable) { 'Passed' } else { 'NeedsNvidiaTargeting' }
        ApplyAvailable = $applyAvailable
        ApplyBlockedStatus = if ($applyAvailable) { '' } else { 'NeedsNvidiaTargeting' }
        DefaultAvailable = $applyAvailable
        RestoreAvailable = $false
        RestoreAvailability = 'Restore requires selected captured state from this Msi Mode tool and is not exposed as Default.'
        DefaultAvailability = if ($applyAvailable) { 'Default is source-defined as MSISupported DWORD 0 and applies only to eligible NVIDIA targets.' } else { 'Default is blocked until at least one eligible NVIDIA target is proven.' }
        ChangesExecuted = $false
        CaptureAttempted = $false
        RegistryWriteAttempted = $false
        ExternalProcessStarted = $false
        DownloadStarted = $false
        RebootRequested = $false
        DiscoveryWarnings = @($discovery.Warnings)
        Blockers = @($discovery.Blockers)
    }

    return New-BoostLabMsiModeResult `
        -Success $true `
        -Action 'Analyze' `
        -Status 'Analyzed' `
        -CommandStatus 'No execution performed' `
        -VerificationStatus ([string]$verification.Status) `
        -Message 'Msi Mode source scope and NVIDIA display-device Enum registry targeting were analyzed. No system mutation occurred.' `
        -Data $data `
        -VerificationResult $verification `
        -Warnings @($discovery.Warnings)
}

function Invoke-BoostLabMsiModeRegistrySet {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [AllowNull()]
        [scriptblock]$AdministratorChecker = $null,

        [AllowNull()]
        [scriptblock]$TargetEnumerator = $null,

        [AllowNull()]
        [scriptblock]$RegistryReader = $null,

        [AllowNull()]
        [scriptblock]$RegistryWriter = $null,

        [string]$StateRoot = (Get-BoostLabRollbackStateRoot)
    )

    $source = Get-BoostLabMsiModeSourceStatus
    if ([string]$source.ChecksumStatus -ne 'Passed') {
        return New-BoostLabMsiModeResult `
            -Success $false `
            -Action $ActionName `
            -Status 'SourceChecksumMismatch' `
            -CommandStatus 'Blocked' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Msi Mode source checksum did not match the approved mirror. No registry discovery, capture, or write was performed.' `
            -Data ([pscustomobject]@{
                Source = $source
                ChangesExecuted = $false
                CaptureAttempted = $false
                RegistryWriteAttempted = $false
            }) `
            -Errors @('Approved source checksum validation failed.')
    }

    $isAdmin = if ($null -ne $AdministratorChecker) {
        [bool](& $AdministratorChecker)
    }
    else {
        Test-BoostLabAdministrator
    }
    if (-not $isAdmin) {
        return New-BoostLabMsiModeResult `
            -Success $false `
            -Action $ActionName `
            -Status 'Error' `
            -CommandStatus 'Blocked' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Administrator rights are required before Msi Mode registry values can be changed.'
    }

    $discovery = Get-BoostLabMsiModeDiscovery -TargetEnumerator $TargetEnumerator
    $targets = @($discovery.EligibleTargets)
    $excludedTargets = @($discovery.ExcludedTargets)
    $ambiguousTargets = @($discovery.AmbiguousTargets)
    if (@($discovery.Blockers).Count -gt 0) {
        return New-BoostLabMsiModeResult `
            -Success $false `
            -Action $ActionName `
            -Status 'NeedsNvidiaTargeting' `
            -CommandStatus 'Blocked' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Msi Mode registry mutation was blocked because target discovery included out-of-scope display-device Enum registry paths. No capture or write was performed.' `
            -Data ([pscustomobject]@{
                TargetCount = @($discovery.Targets).Count
                Targets = @($discovery.Targets)
                EligibleTargetCount = $targets.Count
                EligibleTargets = $targets
                ExcludedTargetCount = $excludedTargets.Count
                ExcludedTargets = $excludedTargets
                AmbiguousTargetCount = $ambiguousTargets.Count
                AmbiguousTargets = $ambiguousTargets
                ChangesExecuted = $false
                CaptureAttempted = $false
                RegistryWriteAttempted = $false
                DiscoveryWarnings = @($discovery.Warnings)
                Blockers = @($discovery.Blockers)
            }) `
            -Warnings @($discovery.Warnings) `
            -Errors @($discovery.Blockers)
    }
    if ($targets.Count -eq 0) {
        $verification = Test-BoostLabMsiModeState -ActionName $ActionName -Targets @()
        return New-BoostLabMsiModeResult `
            -Success $false `
            -Action $ActionName `
            -Status 'NeedsNvidiaTargeting' `
            -CommandStatus 'Blocked' `
            -VerificationStatus ([string]$verification.Status) `
            -Message 'No eligible NVIDIA Msi Mode display-device Enum registry targets were found. Excluded non-NVIDIA targets were skipped and no changes were executed.' `
            -Data ([pscustomobject]@{
                TargetCount = @($discovery.Targets).Count
                Targets = @($discovery.Targets)
                EligibleTargetCount = 0
                EligibleTargets = @()
                ExcludedTargetCount = $excludedTargets.Count
                ExcludedTargets = $excludedTargets
                AmbiguousTargetCount = $ambiguousTargets.Count
                AmbiguousTargets = $ambiguousTargets
                ChangesExecuted = $false
                CaptureAttempted = $false
                RegistryWriteAttempted = $false
                DiscoveryWarnings = @($discovery.Warnings)
                Blockers = @($discovery.Blockers)
            }) `
            -VerificationResult $verification `
            -Warnings @($discovery.Warnings) `
            -Errors @('No eligible NVIDIA display-device Enum registry targets were found.')
    }

    $reader = if ($null -ne $RegistryReader) {
        $RegistryReader
    }
    else {
        { param($Path, $ItemType, $ValueName) Get-BoostLabMsiModeRegistryValueState -RegistryPath $Path -ItemType $ItemType -ValueName $ValueName }
    }
    $writer = if ($null -ne $RegistryWriter) {
        $RegistryWriter
    }
    else {
        { param($Target, $Value) Set-BoostLabMsiModeRegistryValue -RegistryPath ([string]$Target.RegistryPath) -Value $Value }
    }
    $expectedValue = if ($ActionName -eq 'Default') {
        $script:BoostLabMsiModeDefaultValue
    }
    else {
        $script:BoostLabMsiModeApplyValue
    }

    $captureRecords = [System.Collections.Generic.List[object]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    $changesAttempted = [System.Collections.Generic.List[string]]::new()
    $changesCompleted = [System.Collections.Generic.List[string]]::new()

    for ($i = 0; $i -lt $targets.Count; $i++) {
        $target = $targets[$i]
        $scopeId = 'msi-mode-{0}-{1}' -f $ActionName.ToLowerInvariant(), ($i + 1)
        $policy = New-BoostLabMsiModeCapturePolicy -Target $target -ScopeId $scopeId
        $capture = New-BoostLabRegistryStateCapture `
            -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
            -ActionId $ActionName `
            -ScopeId $scopeId `
            -RegistryPath ([string]$target.RegistryPath) `
            -ItemType RegistryValue `
            -ValueName $script:BoostLabMsiModeValueName `
            -IntendedMutation RegistrySet `
            -RiskClassification High `
            -VerificationRequirement ('Verify {0} is DWORD {1} after {2}.' -f $script:BoostLabMsiModeValueName, $expectedValue, $ActionName) `
            -Policy $policy `
            -RegistryReader $reader `
            -StateRoot $StateRoot
        if (-not [bool]$capture.Success) {
            $errors.Add(
                ('State capture failed for {0}: {1}' -f `
                    ([string]$target.RegistryPath),
                    (@($capture.Errors) -join '; '))
            )
            continue
        }

        $captureRecords.Add(
            [pscustomobject]@{
                TargetPath = [string]$target.RegistryPath
                ScopeId = $scopeId
                OperationId = [string]$capture.OperationId
                RecordPath = [string]$capture.RecordPath
                OriginalExists = [bool]$capture.Record.OriginalExists
                OriginalMetadata = $capture.Record.OriginalMetadata
                SourceChecksum = $script:BoostLabExpectedSourceHash
                ToolId = [string]$script:BoostLabToolMetadata['Id']
                Action = $ActionName
            }
        )
    }

    if ($errors.Count -gt 0) {
        return New-BoostLabMsiModeResult `
            -Success $false `
            -Action $ActionName `
            -Status 'Error' `
            -CommandStatus 'Blocked' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Msi Mode registry state capture failed before mutation. No changes were executed.' `
            -Data ([pscustomobject]@{
                TargetCount = @($discovery.Targets).Count
                Targets = @($discovery.Targets)
                EligibleTargetCount = $targets.Count
                EligibleTargets = $targets
                ExcludedTargetCount = $excludedTargets.Count
                ExcludedTargets = $excludedTargets
                AmbiguousTargetCount = $ambiguousTargets.Count
                AmbiguousTargets = $ambiguousTargets
                ChangesExecuted = $false
                CaptureAttempted = $true
                RegistryWriteAttempted = $false
                CaptureRecords = $captureRecords.ToArray()
                Errors = $errors.ToArray()
            }) `
            -Errors $errors.ToArray()
    }

    foreach ($target in $targets) {
        $changesAttempted.Add([string]$target.RegistryPath)
        try {
            & $writer $target $expectedValue
            $changesCompleted.Add([string]$target.RegistryPath)
        }
        catch {
            $errors.Add(
                ('Writing {0} failed for {1}: {2}' -f `
                    $script:BoostLabMsiModeValueName,
                    ([string]$target.RegistryPath),
                    $_.Exception.Message)
            )
        }
    }

    foreach ($captureRecord in $captureRecords) {
        $target = $targets | Where-Object {
            [string]$_.RegistryPath -eq [string]$captureRecord.TargetPath
        } | Select-Object -First 1
        $postState = & $reader ([string]$target.RegistryPath) 'RegistryValue' $script:BoostLabMsiModeValueName
        if ($null -eq $postState -or -not [bool]$postState.ReadSucceeded) {
            $errors.Add("Post-mutation state could not be read for $($captureRecord.TargetPath).")
            continue
        }

        $recordResult = Set-BoostLabRollbackMutationState `
            -RecordPath ([string]$captureRecord.RecordPath) `
            -StateRoot $StateRoot `
            -PostMutationExists ([bool]$postState.Exists) `
            -PostMutationMetadata $postState.Metadata
        if (-not [bool]$recordResult.Success) {
            $errors.Add(
                ('Recording post-mutation state failed for {0}: {1}' -f `
                    ([string]$captureRecord.TargetPath),
                    (@($recordResult.Errors) -join '; '))
            )
        }
    }

    $verification = Test-BoostLabMsiModeState `
        -ActionName $ActionName `
        -Targets $targets `
        -CaptureRecords $captureRecords.ToArray() `
        -RegistryReader $reader

    $data = [pscustomobject]@{
        Source = $source
        PathBWorkflow = 'Driver Install Latest -> Nvidia Settings -> HDCP -> P0 State -> Msi Mode'
        PathBStepNumber = 5
        PathBStepTotal = 5
        PathBStep = '5 of 5'
        SourceRegistryRoot = $script:BoostLabMsiModeEnumRoot
        SourceRegistrySuffix = $script:BoostLabMsiModeRegistrySuffix
        TargetCount = @($discovery.Targets).Count
        Targets = @($discovery.Targets)
        EligibleTargetCount = $targets.Count
        EligibleTargets = $targets
        ExcludedTargetCount = $excludedTargets.Count
        ExcludedTargets = $excludedTargets
        AmbiguousTargetCount = $ambiguousTargets.Count
        AmbiguousTargets = $ambiguousTargets
        WrittenTargetCount = $changesCompleted.Count
        WrittenTargets = $changesCompleted.ToArray()
        ChangesExecuted = $changesCompleted.Count -gt 0
        RegistryChangesAttempted = $changesAttempted.ToArray()
        RegistryChangesCompleted = $changesCompleted.ToArray()
        CaptureAttempted = $true
        CaptureRecords = $captureRecords.ToArray()
        RegistryWriteAttempted = $changesAttempted.Count -gt 0
        ExpectedValueName = $script:BoostLabMsiModeValueName
        ExpectedValueType = 'REG_DWORD'
        ExpectedValueData = $expectedValue
        DefaultImplemented = $true
        RestoreImplemented = $false
        RestoreUnavailableReason = 'Restore requires a selected captured rollback record from this Msi Mode tool; Default is source-defined MSISupported DWORD 0 and is not Restore.'
        ExternalProcessStarted = $false
        DownloadStarted = $false
        RebootRequested = $false
        VerificationStatus = [string]$verification.Status
        Errors = $errors.ToArray()
    }

    if ($errors.Count -gt 0) {
        return New-BoostLabMsiModeResult `
            -Success $false `
            -Action $ActionName `
            -Status 'Error' `
            -CommandStatus 'Completed with errors' `
            -VerificationStatus ([string]$verification.Status) `
            -Message ('Msi Mode {0} completed with errors: {1}' -f $ActionName, ($errors -join '; ')) `
            -Data $data `
            -VerificationResult $verification `
            -Errors $errors.ToArray()
    }
    if ($verification.Status -eq 'Failed') {
        return New-BoostLabMsiModeResult `
            -Success $false `
            -Action $ActionName `
            -Status 'Error' `
            -CommandStatus 'Completed' `
            -VerificationStatus ([string]$verification.Status) `
            -Message ('Msi Mode {0} completed, but verification failed.' -f $ActionName) `
            -Data $data `
            -VerificationResult $verification
    }

    return New-BoostLabMsiModeResult `
        -Success $true `
        -Action $ActionName `
        -Status $(if ($verification.Status -eq 'Warning') { 'Warning' } else { 'Completed' }) `
        -CommandStatus $(if ($verification.Status -eq 'Warning') { 'Completed with warnings' } else { 'Completed' }) `
        -VerificationStatus ([string]$verification.Status) `
            -Message $(if ($ActionName -eq 'Default') { 'Msi Mode Default set source-defined MSISupported DWORD 0 on eligible NVIDIA targets with captured pre-change registry state. Excluded non-NVIDIA targets were skipped.' } else { 'Msi Mode Apply set source-defined MSISupported DWORD 1 on eligible NVIDIA targets with captured pre-change registry state. Excluded non-NVIDIA targets were skipped.' }) `
            -Data $data `
            -VerificationResult $verification
}

function Invoke-BoostLabMsiModeRestore {
    param(
        [bool]$Confirmed = $false
    )

    return New-BoostLabMsiModeResult `
        -Success $false `
        -Action 'Restore' `
        -Status 'RestoreUnavailable' `
        -CommandStatus 'Blocked' `
        -VerificationStatus 'NotApplicable' `
        -Message 'Msi Mode Restore requires a valid selected captured rollback record from this Msi Mode tool. Restore is not Default and no captured-state selector path was provided.' `
        -Data ([pscustomobject]@{
            RestoreRequiresCapturedState = $true
            RestoreExecuted = $false
            ChangesExecuted = $false
            DefaultIsRestore = $false
            Reason = 'Missing selected captured rollback record.'
        })
}

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        Id = [string]$script:BoostLabToolMetadata['Id']
        Title = [string]$script:BoostLabToolMetadata['Title']
        Stage = [string]$script:BoostLabToolMetadata['Stage']
        Order = [int]$script:BoostLabToolMetadata['Order']
        Type = [string]$script:BoostLabToolMetadata['Type']
        RiskLevel = [string]$script:BoostLabToolMetadata['RiskLevel']
        Description = [string]$script:BoostLabToolMetadata['Description']
        Actions = @($script:BoostLabToolMetadata['Actions'])
        Capabilities = $script:BoostLabToolMetadata['Capabilities']
        ImplementedActions = @($script:BoostLabImplementedActions)
        ConfirmationRequiredActions = @('Apply', 'Default', 'Restore')
        ConfirmationText = 'Msi Mode changes the source-defined NVIDIA display-device Enum registry value only after NVIDIA-only target discovery and pre-change state capture. Continue?'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $source = Get-BoostLabMsiModeSourceStatus
    return [pscustomobject]@{
        Supported = [bool]($source.ChecksumStatus -eq 'Passed')
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason = if ($source.ChecksumStatus -eq 'Passed') {
            'The approved Msi Mode source mirror is present and checksum verified.'
        }
        else {
            'The approved Msi Mode source mirror is missing or checksum validation failed.'
        }
        Source = $source
        Timestamp = Get-Date
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Status = 'Ready'
        LastAction = $null
        LastResult = $null
        RestartRequired = $false
        Timestamp = Get-Date
    }
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ActionName,

        [bool]$Confirmed = $false,

        [AllowNull()]
        [scriptblock]$AdministratorChecker = $null,

        [AllowNull()]
        [scriptblock]$TargetEnumerator = $null,

        [AllowNull()]
        [scriptblock]$RegistryReader = $null,

        [AllowNull()]
        [scriptblock]$RegistryWriter = $null,

        [string]$StateRoot = (Get-BoostLabRollbackStateRoot)
    )

    if ($ActionName -notin @($script:BoostLabImplementedActions)) {
        return New-BoostLabMsiModeResult `
            -Success $false `
            -Action $ActionName `
            -Status 'Error' `
            -CommandStatus 'Blocked' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Unsupported action. Msi Mode supports only Analyze, Apply, Default, and Restore.'
    }
    if ($ActionName -eq 'Analyze') {
        return Invoke-BoostLabMsiModeAnalyze -TargetEnumerator $TargetEnumerator -RegistryReader $RegistryReader
    }
    if (-not $Confirmed) {
        return New-BoostLabMsiModeResult `
            -Success $false `
            -Action $ActionName `
            -Status 'Cancelled' `
            -CommandStatus 'Cancelled' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }
    if ($ActionName -eq 'Restore') {
        return Invoke-BoostLabMsiModeRestore -Confirmed:$Confirmed
    }

    return Invoke-BoostLabMsiModeRegistrySet `
        -ActionName $ActionName `
        -AdministratorChecker $AdministratorChecker `
        -TargetEnumerator $TargetEnumerator `
        -RegistryReader $RegistryReader `
        -RegistryWriter $RegistryWriter `
        -StateRoot $StateRoot
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [bool]$Confirmed = $false
    )

    return Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed:$Confirmed
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)


