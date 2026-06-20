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
    Description = 'Path B step 5 of 5. Run the source-defined Msi Mode On or Off branch for every display device returned by Get-PnpDevice -Class Display after explicit confirmation.'
    Actions = @('Analyze', 'Apply', 'Off')
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
        SupportsDefault = $false
        SupportsRestore = $false
        NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Analyze', 'Apply', 'Off')
$script:BoostLabExpectedSourceHash = '94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7'
$script:BoostLabSourceRelativePath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1'
$script:BoostLabMsiModeEnumRoot = 'HKLM:\SYSTEM\ControlSet001\Enum'
$script:BoostLabMsiModeProviderRoot = 'Registry::HKLM\SYSTEM\ControlSet001\Enum'
$script:BoostLabMsiModeRegistrySuffix = 'Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'
$script:BoostLabMsiModeValueName = 'MSISupported'
$script:BoostLabMsiModeValueType = 'DWord'
$script:BoostLabMsiModeSourceOnRecommendedValue = 1
$script:BoostLabMsiModeSourceOffValue = 0
$script:BoostLabMsiModeMissingReadbackText = 'MSISupported: Not found or error accessing the registry.'

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

    [pscustomobject]@{
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
    [CmdletBinding()]
    [OutputType([bool])]
    param()

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
    $normalized = $normalized -replace '^Registry::HKLM\\', 'HKLM:\'
    $normalized = $normalized -replace '^HKEY_LOCAL_MACHINE\\', 'HKLM:\'
    return $normalized
}

function ConvertTo-BoostLabMsiModeProviderPath {
    param(
        [Parameter(Mandatory)]
        [string]$RegistryPath
    )

    $normalized = ConvertTo-BoostLabMsiModeRegistryPath -Path $RegistryPath
    if (-not $normalized.StartsWith($script:BoostLabMsiModeEnumRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
        return $normalized
    }

    $relative = $normalized.Substring(($script:BoostLabMsiModeEnumRoot + '\').Length)
    return '{0}\{1}' -f $script:BoostLabMsiModeProviderRoot, $relative
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
    if ($relative.Length -le $suffixLength) {
        return $false
    }

    $instanceId = $relative.Substring(0, $relative.Length - $suffixLength)
    if ($instanceId -match '(^|\\)\.\.(\\|$)') {
        return $false
    }
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
    if ($cleanInstanceId -match '(^|\\)\.\.(\\|$)') {
        throw "Relative display device InstanceId traversal is not allowed: $cleanInstanceId"
    }

    return '{0}\{1}\{2}' -f $script:BoostLabMsiModeEnumRoot, $cleanInstanceId, $script:BoostLabMsiModeRegistrySuffix
}

function New-BoostLabMsiModeTarget {
    param(
        [Parameter(Mandatory)]
        [string]$InstanceId,

        [AllowNull()]
        [object]$Device = $null
    )

    $registryPath = ConvertTo-BoostLabMsiModeRegistryPath -Path (ConvertTo-BoostLabMsiModeDeviceRegistryPath -InstanceId $InstanceId)
    if (-not (Test-BoostLabMsiModeRegistryTarget -RegistryPath $registryPath)) {
        throw "Target is outside the source Msi Mode Enum registry scope: $registryPath"
    }

    [pscustomobject]@{
        RegistryPath = $registryPath
        ProviderReadbackPath = ConvertTo-BoostLabMsiModeProviderPath -RegistryPath $registryPath
        InstanceId = $InstanceId.Trim().Trim('\')
        ValueName = $script:BoostLabMsiModeValueName
        SourceQuery = 'Get-PnpDevice -Class Display'
        Device = $Device
    }
}

function Get-BoostLabMsiModeRealDevices {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    if (-not (Get-Command -Name 'Get-PnpDevice' -ErrorAction SilentlyContinue)) {
        return [pscustomobject]@{
            Succeeded = $false
            Devices = @()
            Warnings = @('Get-PnpDevice is not available, so source display-device discovery cannot run.')
            Message = 'Msi Mode display-device discovery is unavailable.'
        }
    }

    try {
        $devices = @(Get-PnpDevice -Class Display -ErrorAction Stop)
        return [pscustomobject]@{
            Succeeded = $true
            Devices = $devices
            Warnings = @()
            Message = ('{0} display device(s) returned by Get-PnpDevice -Class Display.' -f $devices.Count)
        }
    }
    catch {
        return [pscustomobject]@{
            Succeeded = $false
            Devices = @()
            Warnings = @("Msi Mode source display-device discovery failed: $($_.Exception.Message)")
            Message = 'Msi Mode source display-device discovery failed.'
        }
    }
}

function Get-BoostLabMsiModeDiscovery {
    param(
        [AllowNull()]
        [scriptblock]$TargetEnumerator = $null
    )

    $raw = if ($null -ne $TargetEnumerator) {
        & $TargetEnumerator
    }
    else {
        Get-BoostLabMsiModeRealDevices
    }

    $targets = [System.Collections.Generic.List[object]]::new()
    $skippedDevices = [System.Collections.Generic.List[object]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    $blockers = [System.Collections.Generic.List[string]]::new()

    if ($null -eq $raw) {
        return [pscustomobject]@{
            Succeeded = $false
            Devices = @()
            Targets = @()
            SkippedDevices = @()
            Warnings = @()
            Blockers = @('Display-device discovery returned no result.')
            Message = 'Msi Mode source display-device discovery returned no result.'
        }
    }

    foreach ($warning in @($raw.Warnings)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$warning)) {
            $warnings.Add([string]$warning)
        }
    }

    $devices = @()
    if ($null -ne $raw.PSObject.Properties['Devices']) {
        $devices = @($raw.Devices)
    }
    elseif ($null -ne $raw.PSObject.Properties['Targets']) {
        $devices = @($raw.Targets)
    }
    else {
        $blockers.Add('Display-device discovery returned no Devices or Targets collection.')
    }

    foreach ($device in $devices) {
        $instanceId = ''
        if ($null -ne $device -and $null -ne $device.PSObject.Properties['InstanceId']) {
            $instanceId = [string]$device.InstanceId
        }
        elseif ($null -ne $device -and $null -ne $device.PSObject.Properties['InstanceID']) {
            $instanceId = [string]$device.InstanceID
        }

        if ([string]::IsNullOrWhiteSpace($instanceId)) {
            $warnings.Add('Skipped a display device because its InstanceId was unavailable.')
            $skippedDevices.Add([pscustomobject]@{
                Reason = 'Missing InstanceId'
                Device = $device
            })
            continue
        }

        try {
            $targets.Add((New-BoostLabMsiModeTarget -InstanceId $instanceId -Device $device))
        }
        catch {
            $blockers.Add($_.Exception.Message)
        }
    }

    $sourceSucceeded = if ($null -ne $raw.PSObject.Properties['Succeeded']) {
        [bool]$raw.Succeeded
    }
    else {
        $blockers.Count -eq 0
    }

    [pscustomobject]@{
        Succeeded = $sourceSucceeded -and $blockers.Count -eq 0
        Devices = $devices
        Targets = @($targets | Sort-Object RegistryPath -Unique)
        SkippedDevices = $skippedDevices.ToArray()
        Warnings = $warnings.ToArray()
        Blockers = $blockers.ToArray()
        Message = if ($targets.Count -eq 0) {
            'No source-targeted Msi Mode display-device registry target was derived.'
        }
        else {
            '{0} source-targeted Msi Mode display-device registry target(s) derived from Get-PnpDevice -Class Display.' -f $targets.Count
        }
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
                DisplayValue = $script:BoostLabMsiModeMissingReadbackText
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
                DisplayValue = $script:BoostLabMsiModeMissingReadbackText
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
            DisplayValue = '{0}: {1}' -f $ValueName, $valueData
            Message = 'Registry value detected.'
        }
    }
    catch {
        return [pscustomobject]@{
            ReadSucceeded = $false
            KeyExists = $null
            Exists = $false
            Metadata = $null
            DisplayValue = $script:BoostLabMsiModeMissingReadbackText
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
        throw "Registry target is outside the source Msi Mode display-device Enum scope: $path"
    }

    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        New-Item -Path $path -Force -ErrorAction Stop | Out-Null
    }
    New-ItemProperty `
        -LiteralPath $path `
        -Name $script:BoostLabMsiModeValueName `
        -PropertyType $script:BoostLabMsiModeValueType `
        -Value $Value `
        -Force `
        -ErrorAction Stop | Out-Null
}

function Get-BoostLabMsiModeReadbackResults {
    param(
        [AllowNull()]
        [object[]]$Targets = @(),

        [AllowNull()]
        [scriptblock]$RegistryReader = $null,

        [AllowNull()]
        [int]$ExpectedValue = -1
    )

    $reader = if ($null -ne $RegistryReader) {
        $RegistryReader
    }
    else {
        { param($Path, $ItemType, $ValueName) Get-BoostLabMsiModeRegistryValueState -RegistryPath $Path -ItemType $ItemType -ValueName $ValueName }
    }

    $results = [System.Collections.Generic.List[object]]::new()
    foreach ($target in @($Targets)) {
        $state = & $reader ([string]$target.RegistryPath) 'RegistryValue' $script:BoostLabMsiModeValueName
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
        $status = if ($ExpectedValue -lt 0) {
            if ($null -eq $state -or -not [bool]$state.ReadSucceeded) { 'Warning' } else { 'Passed' }
        }
        elseif ($null -eq $state -or -not [bool]$state.ReadSucceeded) {
            'Failed'
        }
        elseif (-not [bool]$state.Exists) {
            'Failed'
        }
        elseif ($valueType -ne 'DWord') {
            'Failed'
        }
        elseif ([int]$valueData -ne [int]$ExpectedValue) {
            'Failed'
        }
        else {
            'Passed'
        }

        $results.Add([pscustomobject]@{
            InstanceId = [string]$target.InstanceId
            RegistryPath = [string]$target.RegistryPath
            ProviderReadbackPath = [string]$target.ProviderReadbackPath
            ValueName = $script:BoostLabMsiModeValueName
            ReadSucceeded = if ($null -eq $state) { $false } else { [bool]$state.ReadSucceeded }
            Exists = if ($null -eq $state) { $false } else { [bool]$state.Exists }
            Metadata = if ($null -eq $state) { $null } else { $state.Metadata }
            DisplayValue = if ($null -eq $state) { $script:BoostLabMsiModeMissingReadbackText } else { [string]$state.DisplayValue }
            Message = if ($null -eq $state) { 'Registry state reader returned no result.' } else { [string]$state.Message }
            Status = $status
        })
    }

    $results.ToArray()
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

        [bool]$Cancelled = $false,

        [bool]$ChangesExecuted = $false
    )

    [pscustomobject]@{
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
        ChangesExecuted = $ChangesExecuted
        Timestamp = Get-Date
        Data = $Data
        VerificationResult = $VerificationResult
        Warnings = @($Warnings)
        Errors = @($Errors)
    }
}

function Test-BoostLabMsiModeState {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Analyze', 'Apply', 'Off')]
        [string]$ActionName,

        [AllowNull()]
        [object[]]$Targets = @(),

        [AllowNull()]
        [object[]]$CaptureRecords = @(),

        [AllowNull()]
        [object[]]$Readbacks = @()
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    $targetCount = @($Targets).Count
    $captureCount = @($CaptureRecords).Count
    $expectedValue = if ($ActionName -eq 'Off') {
        $script:BoostLabMsiModeSourceOffValue
    }
    else {
        $script:BoostLabMsiModeSourceOnRecommendedValue
    }

    $checks.Add(
        (New-BoostLabVerificationCheck `
            -Name 'Source display-device target discovery' `
            -Expected 'Every display device returned by Get-PnpDevice -Class Display with a usable InstanceId' `
            -Actual ("$targetCount target(s)") `
            -Status $(if ($targetCount -gt 0) { 'Passed' } elseif ($ActionName -eq 'Analyze') { 'Warning' } else { 'Failed' }) `
            -Message $(if ($targetCount -gt 0) { 'Source display-device registry targets were derived.' } else { 'No source display-device registry targets were derived.' }))
    )

    foreach ($target in @($Targets)) {
        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name ('Source target scope | {0}' -f [string]$target.RegistryPath) `
                -Expected 'HKLM:\SYSTEM\ControlSet001\Enum\<InstanceId>\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties' `
                -Actual ([string]$target.RegistryPath) `
                -Status $(if (Test-BoostLabMsiModeRegistryTarget -RegistryPath ([string]$target.RegistryPath)) { 'Passed' } else { 'Failed' }) `
                -Message 'Msi Mode target follows the exact source-derived display-device Enum path.'))
    }

    if ($ActionName -ne 'Analyze') {
        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name 'Pre-mutation capture records' `
                -Expected "$targetCount capture record(s)" `
                -Actual "$captureCount capture record(s)" `
                -Status $(if ($targetCount -gt 0 -and $captureCount -eq $targetCount) { 'Passed' } else { 'Failed' }) `
                -Message 'Each source-derived Msi Mode target must have a successful registry value capture before mutation.'))
    }

    foreach ($readback in @($Readbacks)) {
        if ($ActionName -eq 'Analyze') {
            $checks.Add(
                (New-BoostLabVerificationCheck `
                    -Name ('Readback | {0}' -f [string]$readback.InstanceId) `
                    -Expected 'Readable current MSISupported state or source-equivalent missing/error text' `
                    -Actual ([string]$readback.DisplayValue) `
                    -Status ([string]$readback.Status) `
                    -Message 'Analyze read the current Msi Mode value state without mutation.'))
            continue
        }

        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name ('Readback | {0}' -f [string]$readback.InstanceId) `
                -Expected ('REG_DWORD {0}' -f $expectedValue) `
                -Actual ([string]$readback.DisplayValue) `
                -Status ([string]$readback.Status) `
                -Message ('Msi Mode source readback for MSISupported after {0}.' -f $ActionName))
        )
    }

    $failedChecks = @($checks | Where-Object { [string]$_.Status -eq 'Failed' })
    $warningChecks = @($checks | Where-Object { [string]$_.Status -eq 'Warning' })
    $status = if ($failedChecks.Count -gt 0) {
        'Failed'
    }
    elseif ($warningChecks.Count -gt 0) {
        'Warning'
    }
    else {
        'Passed'
    }

    New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $ActionName `
        -Status $status `
        -ExpectedState $(if ($ActionName -eq 'Off') { 'MSISupported is REG_DWORD 0 on every source-derived display-device Enum target.' } elseif ($ActionName -eq 'Apply') { 'MSISupported is REG_DWORD 1 on every source-derived display-device Enum target.' } else { 'Msi Mode source scope is readable without mutation.' }) `
        -DetectedState ('{0} target(s), {1} readback(s)' -f $targetCount, @($Readbacks).Count) `
        -Checks $checks.ToArray() `
        -Message $(if ($status -eq 'Passed') { 'Msi Mode source-equivalent verification passed.' } elseif ($status -eq 'Warning') { 'Msi Mode source-equivalent verification completed with warnings.' } else { 'Msi Mode source-equivalent verification failed.' })
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
    $targets = @($discovery.Targets)
    $readbacks = @(Get-BoostLabMsiModeReadbackResults -Targets $targets -RegistryReader $RegistryReader)
    $verification = Test-BoostLabMsiModeState -ActionName Analyze -Targets $targets -Readbacks $readbacks

    $errors = @()
    if ([string]$source.ChecksumStatus -ne 'Passed') {
        $errors += 'Approved source checksum validation failed.'
    }
    if (@($discovery.Blockers).Count -gt 0) {
        $errors += @($discovery.Blockers)
    }

    $data = [pscustomobject]@{
        Source = $source
        PathBWorkflow = 'Driver Install Latest -> Nvidia Settings -> HDCP -> P0 State -> Msi Mode'
        PathBStepNumber = 5
        PathBStepTotal = 5
        PathBStep = '5 of 5'
        SourceBehaviorSummary = 'Ultimate queries Get-PnpDevice -Class Display, derives the Device Parameters\Interrupt Management\MessageSignaledInterruptProperties path from each display device InstanceId, sets MSISupported to DWORD 1 for On or DWORD 0 for Off, then reads back MSISupported for every display device.'
        SourceDeviceQuery = 'Get-PnpDevice -Class Display'
        SourceRegistryRoot = $script:BoostLabMsiModeEnumRoot
        SourceRegistrySuffix = $script:BoostLabMsiModeRegistrySuffix
        SourceRegistryValueName = $script:BoostLabMsiModeValueName
        SourceOnRecommendedValue = $script:BoostLabMsiModeSourceOnRecommendedValue
        SourceOffValue = $script:BoostLabMsiModeSourceOffValue
        TargetCount = $targets.Count
        Targets = $targets
        SkippedDeviceCount = @($discovery.SkippedDevices).Count
        SkippedDevices = @($discovery.SkippedDevices)
        Readbacks = $readbacks
        OnRecommendedAvailable = $targets.Count -gt 0 -and [string]$source.ChecksumStatus -eq 'Passed' -and @($discovery.Blockers).Count -eq 0
        OffAvailable = $targets.Count -gt 0 -and [string]$source.ChecksumStatus -eq 'Passed' -and @($discovery.Blockers).Count -eq 0
        DefaultAvailable = $false
        RestoreAvailable = $false
        CaptureAttempted = $false
        RegistryWriteAttempted = $false
        ChangesExecuted = $false
        ExternalProcessStarted = $false
        DownloadStarted = $false
        RebootRequested = $false
        VerificationStatus = [string]$verification.Status
        Warnings = @($discovery.Warnings)
        Errors = $errors
    }

    $success = ([string]$source.ChecksumStatus -eq 'Passed' -and @($discovery.Blockers).Count -eq 0)
    return New-BoostLabMsiModeResult `
        -Success $success `
        -Action 'Analyze' `
        -Status $(if ($success) { 'Analyzed' } else { 'Error' }) `
        -CommandStatus 'No execution performed' `
        -VerificationStatus ([string]$verification.Status) `
        -Message $(if ($success) { 'Msi Mode source On/Off display-device registry scope was analyzed. No system mutation occurred.' } else { 'Msi Mode Analyze could not verify the approved source scope.' }) `
        -Data $data `
        -VerificationResult $verification `
        -Warnings @($discovery.Warnings) `
        -Errors $errors
}

function Invoke-BoostLabMsiModeRegistrySet {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Off')]
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
    $expectedValue = if ($ActionName -eq 'Off') {
        $script:BoostLabMsiModeSourceOffValue
    }
    else {
        $script:BoostLabMsiModeSourceOnRecommendedValue
    }

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
                ExpectedValueData = $expectedValue
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
            -Message 'Administrator rights are required before source-defined Msi Mode registry values can be changed.' `
            -Errors @('Administrator rights are required.')
    }

    $discovery = Get-BoostLabMsiModeDiscovery -TargetEnumerator $TargetEnumerator
    $targets = @($discovery.Targets)
    if (@($discovery.Blockers).Count -gt 0) {
        return New-BoostLabMsiModeResult `
            -Success $false `
            -Action $ActionName `
            -Status 'SourceScopeBlocked' `
            -CommandStatus 'Blocked' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Msi Mode registry mutation was blocked because source target discovery produced an invalid registry target. No capture or write was performed.' `
            -Data ([pscustomobject]@{
                TargetCount = $targets.Count
                Targets = $targets
                SkippedDeviceCount = @($discovery.SkippedDevices).Count
                SkippedDevices = @($discovery.SkippedDevices)
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
            -Status 'NoDisplayDevices' `
            -CommandStatus 'Blocked' `
            -VerificationStatus ([string]$verification.Status) `
            -Message 'No display devices with usable InstanceId values were returned by the source Get-PnpDevice -Class Display query. No changes were executed.' `
            -Data ([pscustomobject]@{
                TargetCount = 0
                Targets = @()
                SkippedDeviceCount = @($discovery.SkippedDevices).Count
                SkippedDevices = @($discovery.SkippedDevices)
                ChangesExecuted = $false
                CaptureAttempted = $false
                RegistryWriteAttempted = $false
                DiscoveryWarnings = @($discovery.Warnings)
                Blockers = @($discovery.Blockers)
            }) `
            -VerificationResult $verification `
            -Warnings @($discovery.Warnings) `
            -Errors @('No source display-device registry targets were derived.')
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
                TargetCount = $targets.Count
                Targets = $targets
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

    $readbacks = @(Get-BoostLabMsiModeReadbackResults -Targets $targets -RegistryReader $reader -ExpectedValue $expectedValue)

    foreach ($captureRecord in $captureRecords) {
        $target = @($targets | Where-Object {
            [string]$_.RegistryPath -eq [string]$captureRecord.TargetPath
        })[0]
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
        -Readbacks $readbacks

    $data = [pscustomobject]@{
        Source = $source
        PathBWorkflow = 'Driver Install Latest -> Nvidia Settings -> HDCP -> P0 State -> Msi Mode'
        PathBStepNumber = 5
        PathBStepTotal = 5
        PathBStep = '5 of 5'
        SourceDeviceQuery = 'Get-PnpDevice -Class Display'
        SourceRegistryRoot = $script:BoostLabMsiModeEnumRoot
        SourceRegistrySuffix = $script:BoostLabMsiModeRegistrySuffix
        SourceRegistryValueName = $script:BoostLabMsiModeValueName
        TargetCount = $targets.Count
        Targets = $targets
        SkippedDeviceCount = @($discovery.SkippedDevices).Count
        SkippedDevices = @($discovery.SkippedDevices)
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
        Readbacks = $readbacks
        OnRecommendedImplemented = $true
        OffImplemented = $true
        DefaultImplemented = $false
        RestoreImplemented = $false
        DefaultUnavailableReason = 'The Ultimate source exposes Msi Mode Off as a separate visible option, not a Default action.'
        RestoreUnavailableReason = 'The Ultimate source defines no captured-state Restore for Msi Mode.'
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
            -Errors $errors.ToArray() `
            -ChangesExecuted ($changesCompleted.Count -gt 0)
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
            -VerificationResult $verification `
            -ChangesExecuted ($changesCompleted.Count -gt 0)
    }

    $friendlyAction = if ($ActionName -eq 'Off') { 'Off' } else { 'On (Recommended)' }
    return New-BoostLabMsiModeResult `
        -Success $true `
        -Action $ActionName `
        -Status $(if ($verification.Status -eq 'Warning') { 'Warning' } else { 'Completed' }) `
        -CommandStatus $(if ($verification.Status -eq 'Warning') { 'Completed with warnings' } else { 'Completed' }) `
        -VerificationStatus ([string]$verification.Status) `
        -Message ('Msi Mode {0} set source-defined MSISupported DWORD {1} on every source-derived display-device target with captured pre-change registry state.' -f $friendlyAction, $expectedValue) `
        -Data $data `
        -VerificationResult $verification `
        -Warnings @($discovery.Warnings) `
        -ChangesExecuted ($changesCompleted.Count -gt 0)
}

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
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
        ConfirmationRequiredActions = @('Apply', 'Off')
        ConfirmationText = 'Msi Mode changes the source-defined display-device Enum registry value for every display device returned by Get-PnpDevice -Class Display, after source checksum validation and pre-change registry state capture. Continue?'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $source = Get-BoostLabMsiModeSourceStatus
    [pscustomobject]@{
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

    [pscustomobject]@{
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

    $canonicalAction = switch ($ActionName) {
        'On (Recommended)' { 'Apply' }
        'On' { 'Apply' }
        default { $ActionName }
    }

    if ($canonicalAction -notin @($script:BoostLabImplementedActions)) {
        return New-BoostLabMsiModeResult `
            -Success $false `
            -Action $ActionName `
            -Status 'UnsupportedAction' `
            -CommandStatus 'Blocked' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Unsupported action. Msi Mode supports only Analyze, On (Recommended), and Off. The Ultimate source defines no Default, Restore, or Open action.' `
            -Errors @('Unsupported Msi Mode action.')
    }
    if ($canonicalAction -eq 'Analyze') {
        return Invoke-BoostLabMsiModeAnalyze -TargetEnumerator $TargetEnumerator -RegistryReader $RegistryReader
    }
    if (-not $Confirmed) {
        return New-BoostLabMsiModeResult `
            -Success $false `
            -Action $canonicalAction `
            -Status 'Cancelled' `
            -CommandStatus 'Cancelled' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    Invoke-BoostLabMsiModeRegistrySet `
        -ActionName $canonicalAction `
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

    New-BoostLabMsiModeResult `
        -Success $false `
        -Action 'Default' `
        -Status 'DefaultUnavailable' `
        -CommandStatus 'Blocked' `
        -VerificationStatus 'NotApplicable' `
        -Message 'Msi Mode has no Default action. The Ultimate source exposes Off as a separate visible option, and Restore is not available without a source-defined captured-state restore contract.' `
        -Data ([pscustomobject]@{
            DefaultAvailable = $false
            OffActionAvailable = $true
            RestoreAvailable = $false
            ChangesExecuted = $false
        })
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
