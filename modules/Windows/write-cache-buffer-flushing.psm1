Set-StrictMode -Version Latest

$coreRoot = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path $coreRoot 'Verification.psm1') -Scope Local -ErrorAction Stop
}
if (-not (Get-Command -Name 'New-BoostLabRegistryStateCapture' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path $coreRoot 'StateCapture.psm1') -Scope Local -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'write-cache-buffer-flushing'
    Title = 'Write Cache Buffer Flushing'
    Stage = 'Windows'
    Order = 19
    Type = 'action'
    RiskLevel = 'high'
    Description = 'Analyze and apply the approved storage write-cache buffer flushing registry value with captured prior state.'
    Actions = @('Analyze', 'Apply')
    Capabilities = [ordered]@{
        RequiresAdmin             = $true
        RequiresInternet          = $false
        CanReboot                 = $false
        CanModifyRegistry         = $true
        CanModifyServices         = $false
        CanInstallSoftware        = $false
        CanDownload               = $false
        CanModifyDrivers          = $false
        CanModifySecurity         = $false
        CanDeleteFiles            = $false
        UsesTrustedInstaller      = $false
        UsesSafeMode              = $false
        SupportsDefault           = $false
        SupportsRestore           = $false
        NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Analyze', 'Apply')
$script:BoostLabStorageClasses = @('SCSI', 'NVME')
$script:BoostLabEnumRoot = 'HKLM:\SYSTEM\ControlSet001\Enum'
$script:BoostLabCacheValueName = 'CacheIsPowerProtected'
$script:BoostLabCacheValueType = 'DWord'
$script:BoostLabCacheExpectedValue = 1

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

function ConvertTo-BoostLabWriteCacheRegistryPath {
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

function Test-BoostLabWriteCacheRegistryTarget {
    param(
        [Parameter(Mandatory)]
        [string]$RegistryPath
    )

    $normalized = ConvertTo-BoostLabWriteCacheRegistryPath -Path $RegistryPath
    if ($normalized.IndexOfAny([char[]]'*?[]') -ge 0) {
        return $false
    }

    foreach ($className in $script:BoostLabStorageClasses) {
        $prefix = '{0}\{1}\' -f $script:BoostLabEnumRoot, $className
        if (
            $normalized.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
            $normalized.EndsWith('\Device Parameters\Disk', [StringComparison]::OrdinalIgnoreCase)
        ) {
            return $true
        }
    }

    return $false
}

function New-BoostLabWriteCacheResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$Message,

        [string]$Status = '',

        [bool]$Cancelled = $false,

        [AllowNull()]
        [object]$Data = $null,

        [AllowNull()]
        [object]$VerificationResult = $null
    )

    return [pscustomobject]@{
        Success            = $Success
        Status             = $Status
        ToolId             = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle          = [string]$script:BoostLabToolMetadata['Title']
        Action             = $Action
        Message            = $Message
        RestartRequired    = $false
        Cancelled          = $Cancelled
        Timestamp          = Get-Date
        Errors             = @()
        Data               = $Data
        VerificationResult = $VerificationResult
    }
}

function Get-BoostLabWriteCacheWindowsInfo {
    param(
        [AllowNull()]
        [scriptblock]$WindowsInfoReader = $null
    )

    try {
        if ($null -ne $WindowsInfoReader) {
            return & $WindowsInfoReader
        }

        $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        return [pscustomobject]@{
            OperatingSystem = $env:OS
            Caption         = [string]$operatingSystem.Caption
            BuildNumber     = [string]$operatingSystem.BuildNumber
            Version         = [string]$operatingSystem.Version
        }
    }
    catch {
        return [pscustomobject]@{
            OperatingSystem = $env:OS
            Caption         = 'Unknown'
            BuildNumber     = ''
            Version         = ''
            Error           = $_.Exception.Message
        }
    }
}

function Test-BoostLabWriteCacheProductScope {
    param(
        [AllowNull()]
        [scriptblock]$WindowsInfoReader = $null
    )

    $windowsInfo = Get-BoostLabWriteCacheWindowsInfo -WindowsInfoReader $WindowsInfoReader
    $operatingSystem = if (
        $null -ne $windowsInfo -and
        $null -ne $windowsInfo.PSObject.Properties['OperatingSystem'] -and
        -not [string]::IsNullOrWhiteSpace([string]$windowsInfo.OperatingSystem)
    ) {
        [string]$windowsInfo.OperatingSystem
    }
    else {
        [string]$env:OS
    }
    $caption = if ($null -ne $windowsInfo -and $null -ne $windowsInfo.PSObject.Properties['Caption']) {
        [string]$windowsInfo.Caption
    }
    else {
        'Unknown'
    }
    $buildText = if ($null -ne $windowsInfo -and $null -ne $windowsInfo.PSObject.Properties['BuildNumber']) {
        [string]$windowsInfo.BuildNumber
    }
    elseif ($null -ne $windowsInfo -and $null -ne $windowsInfo.PSObject.Properties['Build']) {
        [string]$windowsInfo.Build
    }
    else {
        ''
    }
    $buildNumber = 0
    [void][int]::TryParse($buildText, [ref]$buildNumber)
    $isWindows = $operatingSystem -eq 'Windows_NT' -or $caption -match 'Windows'
    $isWindows10 = $caption -match 'Windows 10' -or ($buildNumber -ge 10240 -and $buildNumber -lt 22000)
    $isWindows11 = $caption -match 'Windows 11' -or ($buildNumber -ge 22000 -and $caption -notmatch 'Server')
    $supported = $isWindows
    $reason = if ($supported) {
        'Write Cache Buffer Flushing uses shared Windows storage registry behavior; the Ultimate source has no Windows 10-only branch.'
    }
    else {
        'Write Cache Buffer Flushing requires a Windows host.'
    }

    return [pscustomobject]@{
        Supported       = $supported
        OperatingSystem = $operatingSystem
        Caption         = $caption
        BuildNumber     = $buildText
        IsWindows10     = $isWindows10
        IsWindows11     = $isWindows11
        Reason          = $reason
    }
}

function New-BoostLabWriteCacheProductScopeResult {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Analyze', 'Apply')]
        [string]$ActionName,

        [Parameter(Mandatory)]
        [object]$Scope
    )

    $verification = New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $ActionName `
        -Status 'NotApplicable' `
        -ExpectedState 'Windows host for shared storage optimization behavior' `
        -DetectedState ('{0} build {1}' -f [string]$Scope.Caption, [string]$Scope.BuildNumber) `
        -Checks @(
            (New-BoostLabVerificationCheck `
                -Name 'Product scope' `
                -Expected 'Windows host for shared source behavior' `
                -Actual ('{0} build {1}' -f [string]$Scope.Caption, [string]$Scope.BuildNumber) `
                -Status 'NotApplicable' `
                -Message ([string]$Scope.Reason))
        ) `
        -Message ([string]$Scope.Reason)

    return New-BoostLabWriteCacheResult `
        -Success $true `
        -Status 'NotApplicable' `
        -Action $ActionName `
        -Message ([string]$Scope.Reason) `
        -Data ([pscustomobject]@{
            SupportedProductScope = $false
            HostCaption           = [string]$Scope.Caption
            HostBuild             = [string]$Scope.BuildNumber
            Windows10Optimization = [bool]$Scope.IsWindows10
            Windows11Target       = $false
            CommandStatus         = 'Not applicable'
            VerificationStatus    = 'NotApplicable'
            ChangesExecuted       = $false
            TargetDiscoveryRun    = $false
            CaptureAttempted      = $false
            RegistryWriteAttempted = $false
            Errors                = @()
        }) `
        -VerificationResult $verification
}

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        Id                 = [string]$script:BoostLabToolMetadata['Id']
        Title              = [string]$script:BoostLabToolMetadata['Title']
        Stage              = [string]$script:BoostLabToolMetadata['Stage']
        Order              = [int]$script:BoostLabToolMetadata['Order']
        Type               = [string]$script:BoostLabToolMetadata['Type']
        RiskLevel          = [string]$script:BoostLabToolMetadata['RiskLevel']
        Description        = [string]$script:BoostLabToolMetadata['Description']
        Actions            = @($script:BoostLabToolMetadata['Actions'])
        Capabilities       = [pscustomobject]$script:BoostLabToolMetadata['Capabilities']
        ImplementedActions = @($script:BoostLabImplementedActions)
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$OperatingSystem = '',

        [AllowNull()]
        [scriptblock]$WindowsInfoReader = $null
    )

    $scope = if ($null -ne $WindowsInfoReader) {
        Test-BoostLabWriteCacheProductScope -WindowsInfoReader $WindowsInfoReader
    }
    elseif ([string]::IsNullOrWhiteSpace($OperatingSystem)) {
        Test-BoostLabWriteCacheProductScope
    }
    else {
        Test-BoostLabWriteCacheProductScope -WindowsInfoReader {
            [pscustomobject]@{
                OperatingSystem = $OperatingSystem
                Caption         = if ($OperatingSystem -eq 'Windows_NT') { 'Unknown Windows' } else { $OperatingSystem }
                BuildNumber     = ''
            }
        }
    }
    return [pscustomobject]@{
        Supported = [bool]$scope.Supported
        ToolId    = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason    = [string]$scope.Reason
        HostCaption = [string]$scope.Caption
        HostBuild = [string]$scope.BuildNumber
        Timestamp = Get-Date
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        Status          = 'Ready'
        LastAction      = $null
        LastResult      = $null
        RestartRequired = $false
        Timestamp       = Get-Date
    }
}

function Get-BoostLabWriteCacheRealTargets {
    $targets = [System.Collections.Generic.List[object]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()

    foreach ($className in $script:BoostLabStorageClasses) {
        $basePath = '{0}\{1}' -f $script:BoostLabEnumRoot, $className
        try {
            if (-not (Test-Path -LiteralPath $basePath -PathType Container)) {
                continue
            }

            $deviceParameterKeys = @(
                Get-ChildItem -Path $basePath -Recurse -ErrorAction SilentlyContinue |
                    Where-Object { $_.PSChildName -eq 'Device Parameters' }
            )
            foreach ($key in $deviceParameterKeys) {
                $diskPath = ConvertTo-BoostLabWriteCacheRegistryPath -Path (
                    Join-Path ([string]$key.PSPath) 'Disk'
                )
                if (-not (Test-BoostLabWriteCacheRegistryTarget -RegistryPath $diskPath)) {
                    $warnings.Add("Skipped unexpected $className target: $diskPath")
                    continue
                }

                $targets.Add(
                    [pscustomobject]@{
                        ClassName    = $className
                        RegistryPath = $diskPath
                        ValueName    = $script:BoostLabCacheValueName
                    }
                )
            }
        }
        catch {
            $warnings.Add("Discovery under $basePath failed: $($_.Exception.Message)")
        }
    }

    return [pscustomobject]@{
        Succeeded = $true
        Targets   = @($targets | Sort-Object ClassName, RegistryPath -Unique)
        Warnings  = $warnings.ToArray()
        Message   = if ($targets.Count -eq 0) {
            'No SCSI or NVME Device Parameters registry targets were found.'
        }
        else {
            '{0} storage Device Parameters target(s) detected.' -f $targets.Count
        }
    }
}

function Get-BoostLabWriteCacheDiscovery {
    param(
        [AllowNull()]
        [scriptblock]$TargetEnumerator = $null
    )

    $discovery = if ($null -ne $TargetEnumerator) {
        & $TargetEnumerator
    }
    else {
        Get-BoostLabWriteCacheRealTargets
    }

    if ($null -eq $discovery -or $null -eq $discovery.PSObject.Properties['Targets']) {
        return [pscustomobject]@{
            Succeeded = $false
            Targets   = @()
            Warnings  = @()
            Message   = 'Storage target discovery returned an invalid result.'
        }
    }

    $validTargets = [System.Collections.Generic.List[object]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    foreach ($warning in @($discovery.Warnings)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$warning)) {
            $warnings.Add([string]$warning)
        }
    }

    foreach ($target in @($discovery.Targets)) {
        $path = ConvertTo-BoostLabWriteCacheRegistryPath -Path ([string]$target.RegistryPath)
        if (-not (Test-BoostLabWriteCacheRegistryTarget -RegistryPath $path)) {
            $warnings.Add("Skipped unexpected target outside SCSI/NVME Device Parameters Disk scope: $path")
            continue
        }

        $className = if ($null -ne $target.PSObject.Properties['ClassName']) {
            [string]$target.ClassName
        }
        else {
            if ($path -like '*\Enum\NVME\*') { 'NVME' } else { 'SCSI' }
        }
        $validTargets.Add(
            [pscustomobject]@{
                ClassName    = $className
                RegistryPath = $path
                ValueName    = $script:BoostLabCacheValueName
            }
        )
    }

    return [pscustomobject]@{
        Succeeded = [bool]$discovery.Succeeded
        Targets   = @($validTargets | Sort-Object ClassName, RegistryPath -Unique)
        Warnings  = $warnings.ToArray()
        Message   = [string]$discovery.Message
    }
}

function Get-BoostLabWriteCacheRegistryValueState {
    param(
        [Parameter(Mandatory)]
        [string]$RegistryPath,

        [string]$ItemType = 'RegistryValue',

        [string]$ValueName = $script:BoostLabCacheValueName
    )

    $path = ConvertTo-BoostLabWriteCacheRegistryPath -Path $RegistryPath
    try {
        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            return [pscustomobject]@{
                ReadSucceeded = $true
                KeyExists     = $false
                Exists        = $false
                Metadata      = $null
                DisplayValue  = 'Absent'
                Message       = 'Registry key is absent.'
            }
        }

        $key = Get-Item -LiteralPath $path -ErrorAction Stop
        $valueExists = $ValueName -in @($key.GetValueNames())
        if (-not $valueExists) {
            return [pscustomobject]@{
                ReadSucceeded = $true
                KeyExists     = $true
                Exists        = $false
                Metadata      = $null
                DisplayValue  = 'Absent'
                Message       = 'Registry value is absent.'
            }
        }

        $valueType = [string]$key.GetValueKind($ValueName)
        $valueData = $key.GetValue($ValueName, $null, 'DoNotExpandEnvironmentNames')
        return [pscustomobject]@{
            ReadSucceeded = $true
            KeyExists     = $true
            Exists        = $true
            Metadata      = [ordered]@{
                ValueName = $ValueName
                ValueType = $valueType
                ValueData = $valueData
            }
            DisplayValue  = '{0} {1}' -f $valueType, $valueData
            Message       = 'Registry value detected.'
        }
    }
    catch {
        return [pscustomobject]@{
            ReadSucceeded = $false
            KeyExists     = $null
            Exists        = $false
            Metadata      = $null
            DisplayValue  = 'Unknown'
            Message       = $_.Exception.Message
        }
    }
}

function Set-BoostLabWriteCacheRegistryValue {
    param(
        [Parameter(Mandatory)]
        [string]$RegistryPath,

        [int]$Value = $script:BoostLabCacheExpectedValue
    )

    $path = ConvertTo-BoostLabWriteCacheRegistryPath -Path $RegistryPath
    if (-not (Test-BoostLabWriteCacheRegistryTarget -RegistryPath $path)) {
        throw "Registry target is outside the approved storage Disk scope: $path"
    }

    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        New-Item -Path $path -Force -ErrorAction Stop | Out-Null
    }
    New-ItemProperty `
        -LiteralPath $path `
        -Name $script:BoostLabCacheValueName `
        -PropertyType $script:BoostLabCacheValueType `
        -Value $Value `
        -Force `
        -ErrorAction Stop | Out-Null
}

function New-BoostLabWriteCacheCapturePolicy {
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
                ScopeId              = $ScopeId
                ToolIds              = @([string]$script:BoostLabToolMetadata['Id'])
                AllowedPath          = [string]$Target.RegistryPath
                AllowedValueNames    = @($script:BoostLabCacheValueName)
                AllowKeyCapture      = $false
                AllowProtectedSystem = $true
            }
        )
        DeniedRegistryPrefixes = @(
            'HKLM:\SYSTEM'
            'Registry::HKEY_LOCAL_MACHINE\SYSTEM'
        )
    }
}

function Test-BoostLabWriteCacheState {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Analyze', 'Apply')]
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
    $reader = if ($null -ne $RegistryReader) {
        $RegistryReader
    }
    else {
        { param($Path, $ItemType, $ValueName) Get-BoostLabWriteCacheRegistryValueState -RegistryPath $Path -ItemType $ItemType -ValueName $ValueName }
    }

    $checks.Add(
        (New-BoostLabVerificationCheck `
            -Name 'Target discovery' `
            -Expected 'At least one SCSI or NVME Device Parameters Disk target for Apply' `
            -Actual ("$targetCount target(s)") `
            -Status $(if ($targetCount -gt 0) { 'Passed' } elseif ($ActionName -eq 'Analyze') { 'Warning' } else { 'NotApplicable' }) `
            -Message $(if ($targetCount -gt 0) { 'Storage registry targets were discovered.' } else { 'No storage registry targets were discovered.' }))
    )

    if ($ActionName -eq 'Apply') {
        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name 'Pre-mutation capture records' `
                -Expected "$targetCount capture record(s)" `
                -Actual "$captureCount capture record(s)" `
                -Status $(if ($targetCount -gt 0 -and $captureCount -eq $targetCount) { 'Passed' } elseif ($targetCount -eq 0) { 'NotApplicable' } else { 'Failed' }) `
                -Message 'Each target must have a successful registry value capture before mutation.'))
    }

    foreach ($target in @($Targets)) {
        $state = & $reader ([string]$target.RegistryPath) 'RegistryValue' $script:BoostLabCacheValueName
        if ($ActionName -eq 'Analyze') {
            $status = if ($null -eq $state -or -not [bool]$state.ReadSucceeded) {
                'Warning'
            }
            else {
                'Passed'
            }
            $expected = 'Readable target state'
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
                [string]$valueData -ne [string]$script:BoostLabCacheExpectedValue
            ) {
                'Failed'
            }
            else {
                'Passed'
            }
            $expected = 'CacheIsPowerProtected DWORD 1'
        }

        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name ('{0} | {1}' -f [string]$target.ClassName, [string]$target.RegistryPath) `
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

    $expectedState = if ($ActionName -eq 'Apply') {
        [pscustomobject]@{
            TargetValue       = 'CacheIsPowerProtected'
            ExpectedValueType = 'DWORD'
            ExpectedValueData = 1
            CaptureRequired   = $true
        }
    }
    else {
        [pscustomobject]@{
            TargetDiscoveryOnly = $true
            TargetValue         = 'CacheIsPowerProtected'
        }
    }
    $detectedState = [pscustomobject]@{
        TargetCount        = $targetCount
        CaptureRecordCount = $captureCount
        FailedChecks       = @($checks | Where-Object { $_.Status -eq 'Failed' }).Count
        WarningChecks      = @($checks | Where-Object { $_.Status -eq 'Warning' }).Count
    }
    $message = switch ($overallStatus) {
        'Passed' {
            if ($ActionName -eq 'Apply') {
                'All discovered storage registry targets have CacheIsPowerProtected set to 1.'
            }
            else {
                'Storage write-cache buffer flushing targets were analyzed.'
            }
        }
        'Warning' { 'Storage target state was analyzed with warnings.' }
        'NotApplicable' { 'No source-targeted storage registry paths were found.' }
        default { 'One or more storage registry targets did not match the expected state.' }
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

function Invoke-BoostLabWriteCacheAnalyze {
    param(
        [AllowNull()]
        [scriptblock]$WindowsInfoReader = $null,

        [AllowNull()]
        [scriptblock]$TargetEnumerator = $null,

        [AllowNull()]
        [scriptblock]$RegistryReader = $null
    )

    $scope = Test-BoostLabWriteCacheProductScope -WindowsInfoReader $WindowsInfoReader
    if (-not [bool]$scope.Supported) {
        return New-BoostLabWriteCacheProductScopeResult -ActionName 'Analyze' -Scope $scope
    }

    $discovery = Get-BoostLabWriteCacheDiscovery -TargetEnumerator $TargetEnumerator
    $verification = Test-BoostLabWriteCacheState `
        -ActionName 'Analyze' `
        -Targets @($discovery.Targets) `
        -RegistryReader $RegistryReader
    $data = [pscustomobject]@{
        TargetCount              = @($discovery.Targets).Count
        Targets                  = @($discovery.Targets)
        DiscoveryWarnings        = @($discovery.Warnings)
        ChangesExecuted          = $false
        ApplySupported           = $true
        DefaultSupported         = $false
        RestoreSupported         = $false
        DefaultUnavailableReason = 'Ultimate Default deletes entire storage Disk registry keys, so BoostLab does not expose it.'
        RestoreUnavailableReason = 'Restore is not exposed until BoostLab has a reviewed UI/runtime flow for selecting exact captured rollback records.'
    }

    return New-BoostLabWriteCacheResult `
        -Success $true `
        -Status 'Analyzed' `
        -Action 'Analyze' `
        -Message ([string]$verification.Message) `
        -Data $data `
        -VerificationResult $verification
}

function Invoke-BoostLabWriteCacheApply {
    param(
        [AllowNull()]
        [scriptblock]$WindowsInfoReader = $null,

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

    $scope = Test-BoostLabWriteCacheProductScope -WindowsInfoReader $WindowsInfoReader
    if (-not [bool]$scope.Supported) {
        return New-BoostLabWriteCacheProductScopeResult -ActionName 'Apply' -Scope $scope
    }

    $isAdmin = if ($null -ne $AdministratorChecker) {
        [bool](& $AdministratorChecker)
    }
    else {
        Test-BoostLabAdministrator
    }
    if (-not $isAdmin) {
        return New-BoostLabWriteCacheResult `
            -Success $false `
            -Status 'Error' `
            -Action 'Apply' `
            -Message 'Administrator rights are required to change storage write-cache buffer flushing registry values.'
    }

    $discovery = Get-BoostLabWriteCacheDiscovery -TargetEnumerator $TargetEnumerator
    $targets = @($discovery.Targets)
    if ($targets.Count -eq 0) {
        $verification = Test-BoostLabWriteCacheState -ActionName 'Apply' -Targets @()
        return New-BoostLabWriteCacheResult `
            -Success $true `
            -Status 'NotApplicable' `
            -Action 'Apply' `
            -Message 'No source-targeted SCSI or NVME storage registry paths were found. No changes were executed.' `
            -Data ([pscustomobject]@{
                TargetCount              = 0
                ChangesExecuted          = $false
                CaptureRecords           = @()
                DiscoveryWarnings        = @($discovery.Warnings)
                DefaultUnavailableReason = 'Ultimate Default deletes entire storage Disk registry keys, so BoostLab does not expose it.'
                RestoreUnavailableReason = 'Restore is not exposed until BoostLab has a reviewed UI/runtime flow for selecting exact captured rollback records.'
            }) `
            -VerificationResult $verification
    }

    $reader = if ($null -ne $RegistryReader) {
        $RegistryReader
    }
    else {
        { param($Path, $ItemType, $ValueName) Get-BoostLabWriteCacheRegistryValueState -RegistryPath $Path -ItemType $ItemType -ValueName $ValueName }
    }
    $writer = if ($null -ne $RegistryWriter) {
        $RegistryWriter
    }
    else {
        { param($Target, $Value) Set-BoostLabWriteCacheRegistryValue -RegistryPath ([string]$Target.RegistryPath) -Value $Value }
    }

    $captureRecords = [System.Collections.Generic.List[object]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    $changesAttempted = [System.Collections.Generic.List[string]]::new()
    $changesCompleted = [System.Collections.Generic.List[string]]::new()

    for ($i = 0; $i -lt $targets.Count; $i++) {
        $target = $targets[$i]
        $scopeId = 'write-cache-buffer-flushing-{0}' -f ($i + 1)
        $policy = New-BoostLabWriteCacheCapturePolicy -Target $target -ScopeId $scopeId
        $capture = New-BoostLabRegistryStateCapture `
            -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
            -ActionId 'Apply' `
            -ScopeId $scopeId `
            -RegistryPath ([string]$target.RegistryPath) `
            -ItemType RegistryValue `
            -ValueName $script:BoostLabCacheValueName `
            -IntendedMutation RegistrySet `
            -RiskClassification High `
            -VerificationRequirement 'Verify CacheIsPowerProtected is DWORD 1 after Apply.' `
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
                TargetPath  = [string]$target.RegistryPath
                ScopeId     = $scopeId
                OperationId = [string]$capture.OperationId
                RecordPath  = [string]$capture.RecordPath
                OriginalExists = [bool]$capture.Record.OriginalExists
            }
        )
    }

    if ($errors.Count -gt 0) {
        return New-BoostLabWriteCacheResult `
            -Success $false `
            -Status 'Error' `
            -Action 'Apply' `
            -Message 'Registry state capture failed before mutation. No changes were executed.' `
            -Data ([pscustomobject]@{
                TargetCount        = $targets.Count
                ChangesExecuted    = $false
                CaptureRecords     = $captureRecords.ToArray()
                Errors             = $errors.ToArray()
                DiscoveryWarnings  = @($discovery.Warnings)
            })
    }

    foreach ($target in $targets) {
        $changesAttempted.Add([string]$target.RegistryPath)
        try {
            & $writer $target $script:BoostLabCacheExpectedValue
            $changesCompleted.Add([string]$target.RegistryPath)
        }
        catch {
            $errors.Add(
                ('Writing CacheIsPowerProtected failed for {0}: {1}' -f `
                    ([string]$target.RegistryPath),
                    $_.Exception.Message)
            )
        }
    }

    foreach ($captureRecord in $captureRecords) {
        $target = $targets | Where-Object {
            [string]$_.RegistryPath -eq [string]$captureRecord.TargetPath
        } | Select-Object -First 1
        $postState = & $reader ([string]$target.RegistryPath) 'RegistryValue' $script:BoostLabCacheValueName
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

    $verification = Test-BoostLabWriteCacheState `
        -ActionName 'Apply' `
        -Targets $targets `
        -CaptureRecords $captureRecords.ToArray() `
        -RegistryReader $reader

    $data = [pscustomobject]@{
        TargetCount              = $targets.Count
        ChangesExecuted          = $changesCompleted.Count -gt 0
        RegistryChangesAttempted = $changesAttempted.ToArray()
        RegistryChangesCompleted = $changesCompleted.ToArray()
        CaptureRecords           = $captureRecords.ToArray()
        DiscoveryWarnings        = @($discovery.Warnings)
        DefaultImplemented       = $false
        RestoreImplemented       = $false
        DefaultUnavailableReason = 'Ultimate Default deletes entire storage Disk registry keys, so BoostLab does not expose it.'
        RestoreUnavailableReason = 'Restore is not exposed until BoostLab has a reviewed UI/runtime flow for selecting exact captured rollback records.'
        VerificationStatus       = [string]$verification.Status
        Errors                   = $errors.ToArray()
    }

    if ($errors.Count -gt 0) {
        return New-BoostLabWriteCacheResult `
            -Success $false `
            -Status 'Error' `
            -Action 'Apply' `
            -Message ('Write Cache Buffer Flushing Apply completed with errors: {0}' -f ($errors -join '; ')) `
            -Data $data `
            -VerificationResult $verification
    }

    if ($verification.Status -eq 'Failed') {
        return New-BoostLabWriteCacheResult `
            -Success $false `
            -Status 'Error' `
            -Action 'Apply' `
            -Message 'Write Cache Buffer Flushing Apply completed, but verification failed.' `
            -Data $data `
            -VerificationResult $verification
    }

    return New-BoostLabWriteCacheResult `
        -Success $true `
        -Status $(if ($verification.Status -eq 'Warning') { 'Warning' } else { 'Completed' }) `
        -Action 'Apply' `
        -Message 'Write Cache Buffer Flushing Apply completed with captured pre-change registry state.' `
        -Data $data `
        -VerificationResult $verification
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ActionName,

        [bool]$Confirmed = $false
    )

    if ($ActionName -notin @($script:BoostLabImplementedActions)) {
        return New-BoostLabWriteCacheResult `
            -Success $false `
            -Status 'Error' `
            -Action $ActionName `
            -Message 'Unsupported action. Only Analyze and Apply are allowed; Default is refused because it deletes entire storage Disk registry keys.'
    }
    if ($ActionName -eq 'Analyze') {
        return Invoke-BoostLabWriteCacheAnalyze
    }
    if (-not $Confirmed) {
        return New-BoostLabWriteCacheResult `
            -Success $false `
            -Status 'Cancelled' `
            -Action $ActionName `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    return Invoke-BoostLabWriteCacheApply
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [bool]$Confirmed = $false
    )

    return New-BoostLabWriteCacheResult `
        -Success $false `
        -Status 'NotImplemented' `
        -Action 'Restore' `
        -Message 'Restore is not exposed until BoostLab has a reviewed UI/runtime flow for selecting exact captured rollback records.'
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
