Set-StrictMode -Version Latest

$coreRoot = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path $coreRoot 'Verification.psm1') -Scope Local -ErrorAction Stop
}
if (-not (Get-Command -Name 'New-BoostLabRegistryStateCapture' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path $coreRoot 'StateCapture.psm1') -Scope Local -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'p0-state'
    Title = 'P0 State'
    Stage = 'Graphics'
    Order = 6
    Type = 'action'
    RiskLevel = 'high'
    Description = 'Path B step 4 of 5. Set the source-defined NVIDIA P0 State registry value on every non-Configuration display-class subkey after explicit confirmation.'
    Actions = @('Analyze', 'Apply', 'Default')
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
$script:BoostLabImplementedActions = @('Analyze', 'Apply', 'Default')
$script:BoostLabExpectedSourceHash = '382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC'
$script:BoostLabSourceRelativePath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1'
$script:BoostLabDisplayClassRoot = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
$script:BoostLabSourceDisplayClassRoot = 'Registry::HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
$script:BoostLabP0StateValueName = 'DisableDynamicPstate'
$script:BoostLabP0StateValueType = 'DWord'
$script:BoostLabP0StateApplyValue = 1
$script:BoostLabP0StateDefaultValue = 0

function Get-BoostLabP0StateSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Join-Path $projectRoot ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabP0StateSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabP0StateSourcePath
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
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function ConvertTo-BoostLabP0StateRegistryPath {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $normalized = $Path.Trim().TrimEnd('\')
    $normalized = $normalized -replace '^Microsoft\.PowerShell\.Core\\Registry::HKEY_LOCAL_MACHINE\\', 'HKLM:\'
    $normalized = $normalized -replace '^Microsoft\.PowerShell\.Core\\Registry::HKLM\\', 'HKLM:\'
    $normalized = $normalized -replace '^Registry::HKEY_LOCAL_MACHINE\\', 'HKLM:\'
    $normalized = $normalized -replace '^Registry::HKLM\\', 'HKLM:\'
    $normalized = $normalized -replace '^HKEY_LOCAL_MACHINE\\', 'HKLM:\'
    $normalized
}

function ConvertTo-BoostLabP0StateSourceKeyName {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $normalized = ConvertTo-BoostLabP0StateRegistryPath -Path $Path
    $normalized = $normalized -replace '^HKLM:\\', 'HKEY_LOCAL_MACHINE\'
    $normalized
}

function Test-BoostLabP0StateRegistryTarget {
    param(
        [Parameter(Mandatory)]
        [string]$RegistryPath
    )

    $normalized = ConvertTo-BoostLabP0StateRegistryPath -Path $RegistryPath
    if ($normalized.IndexOfAny([char[]]'*?[]') -ge 0) {
        return $false
    }
    if (-not $normalized.StartsWith($script:BoostLabDisplayClassRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
        return $false
    }

    $relative = $normalized.Substring(($script:BoostLabDisplayClassRoot + '\').Length)
    if ([string]::IsNullOrWhiteSpace($relative) -or $relative -match '\\') {
        return $false
    }

    return ($normalized -notlike '*Configuration*')
}

function New-BoostLabP0StateTarget {
    param(
        [Parameter(Mandatory)]
        [string]$SourceKeyName
    )

    $sourceName = ConvertTo-BoostLabP0StateSourceKeyName -Path $SourceKeyName
    $registryPath = ConvertTo-BoostLabP0StateRegistryPath -Path $sourceName
    [pscustomobject]@{
        SourceKeyName = $sourceName
        RegistryPath = $registryPath
        RegistryProviderPath = 'Registry::{0}' -f $sourceName
        ValueName = $script:BoostLabP0StateValueName
        SourceIncluded = $true
        SourceSkipReason = ''
    }
}

function New-BoostLabP0StateSkippedTarget {
    param(
        [Parameter(Mandatory)]
        [string]$SourceKeyName,

        [Parameter(Mandatory)]
        [string]$Reason
    )

    $sourceName = ConvertTo-BoostLabP0StateSourceKeyName -Path $SourceKeyName
    [pscustomobject]@{
        SourceKeyName = $sourceName
        RegistryPath = ConvertTo-BoostLabP0StateRegistryPath -Path $sourceName
        RegistryProviderPath = 'Registry::{0}' -f $sourceName
        ValueName = $script:BoostLabP0StateValueName
        SourceIncluded = $false
        SourceSkipReason = $Reason
    }
}

function Get-BoostLabP0StateRealTargets {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $warnings = [System.Collections.Generic.List[string]]::new()
    $sourceKeyNames = [System.Collections.Generic.List[string]]::new()

    try {
        if (-not (Test-Path -Path $script:BoostLabSourceDisplayClassRoot -PathType Container)) {
            return [pscustomobject]@{
                Succeeded = $true
                SourceRoot = $script:BoostLabSourceDisplayClassRoot
                SourceKeyNames = @()
                Targets = @()
                SkippedTargets = @()
                Warnings = @('The P0 State display-class registry path was not found.')
                Message = 'The P0 State display-class registry path was not found.'
            }
        }

        foreach ($key in @(Get-ChildItem -Path $script:BoostLabSourceDisplayClassRoot -Force -ErrorAction SilentlyContinue)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$key.Name)) {
                $sourceKeyNames.Add([string]$key.Name)
            }
        }
    }
    catch {
        $warnings.Add("P0 State source target enumeration failed: $($_.Exception.Message)")
    }

    [pscustomobject]@{
        Succeeded = ($warnings.Count -eq 0)
        SourceRoot = $script:BoostLabSourceDisplayClassRoot
        SourceKeyNames = $sourceKeyNames.ToArray()
        Targets = @()
        SkippedTargets = @()
        Warnings = $warnings.ToArray()
        Message = '{0} display-class subkey name(s) detected from the source query.' -f $sourceKeyNames.Count
    }
}

function Get-BoostLabP0StateDiscovery {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [scriptblock]$TargetEnumerator = $null
    )

    $rawDiscovery = if ($null -ne $TargetEnumerator) {
        & $TargetEnumerator
    }
    else {
        Get-BoostLabP0StateRealTargets
    }

    if ($null -eq $rawDiscovery) {
        return [pscustomobject]@{
            Succeeded = $false
            SourceRoot = $script:BoostLabSourceDisplayClassRoot
            SourceKeyNames = @()
            Targets = @()
            SkippedTargets = @()
            Warnings = @()
            Blockers = @('Target discovery returned null.')
            Message = 'P0 State source target discovery returned null.'
        }
    }

    $warnings = [System.Collections.Generic.List[string]]::new()
    $blockers = [System.Collections.Generic.List[string]]::new()
    $sourceNames = [System.Collections.Generic.List[string]]::new()
    $targets = [System.Collections.Generic.List[object]]::new()
    $skippedTargets = [System.Collections.Generic.List[object]]::new()

    foreach ($warning in @($rawDiscovery.Warnings)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$warning)) {
            $warnings.Add([string]$warning)
        }
    }

    if ($null -ne $rawDiscovery.PSObject.Properties['SourceKeyNames']) {
        foreach ($sourceName in @($rawDiscovery.SourceKeyNames)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$sourceName)) {
                $sourceNames.Add([string]$sourceName)
            }
        }
    }

    if ($sourceNames.Count -eq 0 -and $null -ne $rawDiscovery.PSObject.Properties['Targets']) {
        foreach ($target in @($rawDiscovery.Targets)) {
            $sourceName = if ($null -ne $target.PSObject.Properties['SourceKeyName']) {
                [string]$target.SourceKeyName
            }
            elseif ($null -ne $target.PSObject.Properties['RegistryPath']) {
                ConvertTo-BoostLabP0StateSourceKeyName -Path ([string]$target.RegistryPath)
            }
            else {
                ''
            }
            if (-not [string]::IsNullOrWhiteSpace($sourceName)) {
                $sourceNames.Add($sourceName)
            }
        }
    }

    foreach ($sourceName in @($sourceNames.ToArray() | Sort-Object -Unique)) {
        $normalized = ConvertTo-BoostLabP0StateRegistryPath -Path $sourceName
        if ($normalized -like '*Configuration*') {
            $skippedTargets.Add((New-BoostLabP0StateSkippedTarget -SourceKeyName $sourceName -Reason 'Skipped by source *Configuration* rule.'))
            continue
        }
        if (-not (Test-BoostLabP0StateRegistryTarget -RegistryPath $normalized)) {
            $blockers.Add("Target is outside the immediate source display-class subkey scope: $sourceName")
            continue
        }

        $targets.Add((New-BoostLabP0StateTarget -SourceKeyName $sourceName))
    }

    [pscustomobject]@{
        Succeeded = [bool]$rawDiscovery.Succeeded -and $blockers.Count -eq 0
        SourceRoot = if ($null -ne $rawDiscovery.PSObject.Properties['SourceRoot']) { [string]$rawDiscovery.SourceRoot } else { $script:BoostLabSourceDisplayClassRoot }
        SourceKeyNames = $sourceNames.ToArray()
        Targets = @($targets.ToArray())
        SkippedTargets = @($skippedTargets.ToArray())
        Warnings = $warnings.ToArray()
        Blockers = $blockers.ToArray()
        Message = if ($targets.Count -gt 0) {
            '{0} source-included non-Configuration display-class target(s) detected.' -f $targets.Count
        }
        elseif ($skippedTargets.Count -gt 0) {
            'Only Configuration display-class targets were detected; source-defined P0 State writes have no target.'
        }
        else {
            [string]$rawDiscovery.Message
        }
    }
}

function Get-BoostLabP0StateRegistryValueState {
    param(
        [Parameter(Mandatory)]
        [string]$RegistryPath,

        [string]$ItemType = 'RegistryValue',

        [string]$ValueName = $script:BoostLabP0StateValueName
    )

    $path = ConvertTo-BoostLabP0StateRegistryPath -Path $RegistryPath
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

function Set-BoostLabP0StateRegistryValue {
    param(
        [Parameter(Mandatory)]
        [string]$RegistryPath,

        [Parameter(Mandatory)]
        [ValidateSet(0, 1)]
        [int]$Value
    )

    $path = ConvertTo-BoostLabP0StateRegistryPath -Path $RegistryPath
    if (-not (Test-BoostLabP0StateRegistryTarget -RegistryPath $path)) {
        throw "Registry target is outside the source P0 State display-class scope: $path"
    }
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        throw "Registry target does not exist: $path"
    }

    New-ItemProperty `
        -LiteralPath $path `
        -Name $script:BoostLabP0StateValueName `
        -PropertyType $script:BoostLabP0StateValueType `
        -Value $Value `
        -Force `
        -ErrorAction Stop | Out-Null
}

function New-BoostLabP0StateCapturePolicy {
    param(
        [Parameter(Mandatory)]
        [object]$Target,

        [Parameter(Mandatory)]
        [string]$ScopeId
    )

    @{
        SchemaVersion = '1.0'
        FileScopes = @()
        RegistryScopes = @(
            @{
                ScopeId = $ScopeId
                ToolIds = @([string]$script:BoostLabToolMetadata['Id'])
                AllowedPath = [string]$Target.RegistryPath
                AllowedValueNames = @($script:BoostLabP0StateValueName)
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

function New-BoostLabP0StateResult {
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
        Warnings = @($Warnings | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Unique)
        Errors = @($Errors | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Unique)
    }
}

function Get-BoostLabP0StateReadbackResults {
    param(
        [Parameter(Mandatory)]
        [object[]]$Targets,

        [AllowNull()]
        [Nullable[int]]$ExpectedValue = $null,

        [AllowNull()]
        [scriptblock]$RegistryReader = $null
    )

    $reader = if ($null -ne $RegistryReader) {
        $RegistryReader
    }
    else {
        { param($Path, $ItemType, $ValueName) Get-BoostLabP0StateRegistryValueState -RegistryPath $Path -ItemType $ItemType -ValueName $ValueName }
    }

    foreach ($target in @($Targets)) {
        $state = & $reader ([string]$target.RegistryPath) 'RegistryValue' $script:BoostLabP0StateValueName
        $actualValue = if ($null -ne $state -and $null -ne $state.Metadata) {
            $state.Metadata.ValueData
        }
        else {
            $null
        }
        $actualType = if ($null -ne $state -and $null -ne $state.Metadata) {
            [string]$state.Metadata.ValueType
        }
        else {
            ''
        }
        $status = if ($null -eq $state -or -not [bool]$state.ReadSucceeded) {
            'Failed'
        }
        elseif ($null -eq $ExpectedValue) {
            'Read'
        }
        elseif ([bool]$state.Exists -and $actualType -eq 'DWord' -and [int]$actualValue -eq [int]$ExpectedValue) {
            'Passed'
        }
        else {
            'Failed'
        }

        [pscustomobject]@{
            RegistryPath = [string]$target.RegistryPath
            SourceKeyName = [string]$target.SourceKeyName
            ValueName = $script:BoostLabP0StateValueName
            ExpectedValue = if ($null -eq $ExpectedValue) { $null } else { [int]$ExpectedValue }
            ActualValue = $actualValue
            ActualType = $actualType
            Exists = if ($null -ne $state) { [bool]$state.Exists } else { $false }
            ReadSucceeded = if ($null -ne $state) { [bool]$state.ReadSucceeded } else { $false }
            DisplayValue = if ($null -ne $state) { [string]$state.DisplayValue } else { 'Unknown' }
            Status = $status
            Message = if ($null -ne $state) { [string]$state.Message } else { 'No readback state returned.' }
        }
    }
}

function Test-BoostLabP0StateState {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Analyze', 'Apply', 'Default')]
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
    $expectedValue = if ($ActionName -eq 'Default') {
        $script:BoostLabP0StateDefaultValue
    }
    else {
        $script:BoostLabP0StateApplyValue
    }

    $checks.Add(
        (New-BoostLabVerificationCheck `
            -Name 'Source display-class target discovery' `
            -Expected 'At least one immediate non-Configuration display-class subkey for Apply or Default' `
            -Actual ("$targetCount target(s)") `
            -Status $(if ($targetCount -gt 0) { 'Passed' } elseif ($ActionName -eq 'Analyze') { 'Warning' } else { 'Failed' }) `
            -Message $(if ($targetCount -gt 0) { 'Source-targeted display-class registry subkeys were discovered.' } else { 'No source-targeted non-Configuration display-class registry subkeys were discovered.' }))
    )

    if ($ActionName -ne 'Analyze') {
        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name 'Pre-mutation capture records' `
                -Expected "$targetCount capture record(s)" `
                -Actual "$captureCount capture record(s)" `
                -Status $(if ($targetCount -gt 0 -and $captureCount -eq $targetCount) { 'Passed' } elseif ($targetCount -eq 0) { 'Failed' } else { 'Failed' }) `
                -Message 'Each source-targeted P0 State registry value must have a successful capture before mutation.'))
    }

    foreach ($target in @($Targets)) {
        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name ('Source target scope | {0}' -f [string]$target.RegistryPath) `
                -Expected 'Immediate display-class subkey whose path/name does not match *Configuration*' `
                -Actual ([string]$target.SourceKeyName) `
                -Status $(if (Test-BoostLabP0StateRegistryTarget -RegistryPath ([string]$target.RegistryPath)) { 'Passed' } else { 'Failed' }) `
                -Message 'P0 State target follows the exact source enumeration scope.'))
    }

    foreach ($readback in @($Readbacks)) {
        if ($ActionName -eq 'Analyze') {
            $checks.Add(
                (New-BoostLabVerificationCheck `
                    -Name ('Readback | {0}' -f [string]$readback.RegistryPath) `
                    -Expected 'Readable current P0 State value state' `
                    -Actual ([string]$readback.DisplayValue) `
                    -Status $(if ([bool]$readback.ReadSucceeded) { 'Passed' } else { 'Warning' }) `
                    -Message 'Analyze read the current P0 State value state without mutation.'))
            continue
        }

        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name ('Readback | {0}' -f [string]$readback.RegistryPath) `
                -Expected ('REG_DWORD {0}' -f $expectedValue) `
                -Actual ([string]$readback.DisplayValue) `
                -Status ([string]$readback.Status) `
                -Message ('P0 State source readback for {0} after {1}.' -f $script:BoostLabP0StateValueName, $ActionName))
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
        -ExpectedState $(if ($ActionName -eq 'Default') { 'DisableDynamicPstate is REG_DWORD 0 on every source-included non-Configuration display-class subkey.' } elseif ($ActionName -eq 'Apply') { 'DisableDynamicPstate is REG_DWORD 1 on every source-included non-Configuration display-class subkey.' } else { 'P0 State source scope is readable without mutation.' }) `
        -DetectedState ('{0} target(s), {1} readback(s)' -f $targetCount, @($Readbacks).Count) `
        -Checks $checks.ToArray() `
        -Message $(if ($status -eq 'Passed') { 'P0 State source-equivalent verification passed.' } elseif ($status -eq 'Warning') { 'P0 State source-equivalent verification completed with warnings.' } else { 'P0 State source-equivalent verification failed.' })
}

function Invoke-BoostLabP0StateAnalyze {
    param(
        [AllowNull()]
        [scriptblock]$TargetEnumerator = $null,

        [AllowNull()]
        [scriptblock]$RegistryReader = $null
    )

    $source = Get-BoostLabP0StateSourceStatus
    $discovery = Get-BoostLabP0StateDiscovery -TargetEnumerator $TargetEnumerator
    $readbacks = @(Get-BoostLabP0StateReadbackResults -Targets @($discovery.Targets) -RegistryReader $RegistryReader)
    $verification = Test-BoostLabP0StateState -ActionName Analyze -Targets @($discovery.Targets) -Readbacks $readbacks

    $data = [pscustomobject]@{
        Source = $source
        Header = 'NVIDIA Highest Performance Power State'
        PathBWorkflow = 'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
        PathBStepNumber = 4
        PathBStepTotal = 5
        PathBStep = '4 of 5'
        SourceBehaviorSummary = 'Ultimate enumerates display-class subkey .Name values, skips paths/names matching *Configuration*, writes DisableDynamicPstate as REG_DWORD 1 for On (Recommended) or REG_DWORD 0 for Default, then reads each written value back.'
        SourceRegistryRoot = $script:BoostLabDisplayClassRoot
        SourceRegistryQuery = $script:BoostLabSourceDisplayClassRoot
        SourceRegistryValueName = $script:BoostLabP0StateValueName
        SourceRegistryValueType = 'REG_DWORD'
        SourceOnRecommendedValue = $script:BoostLabP0StateApplyValue
        SourceDefaultValue = $script:BoostLabP0StateDefaultValue
        SourceSkipRule = '*Configuration*'
        SourceKeyNameCount = @($discovery.SourceKeyNames).Count
        SourceKeyNames = @($discovery.SourceKeyNames)
        TargetCount = @($discovery.Targets).Count
        Targets = @($discovery.Targets)
        SkippedTargetCount = @($discovery.SkippedTargets).Count
        SkippedTargets = @($discovery.SkippedTargets)
        ApplyAvailable = @($discovery.Targets).Count -gt 0 -and @($discovery.Blockers).Count -eq 0
        DefaultAvailable = @($discovery.Targets).Count -gt 0 -and @($discovery.Blockers).Count -eq 0
        RestoreAvailable = $false
        RestoreAvailability = 'No Restore action is source-defined or exposed for P0 State; Default is the source-defined DWORD 0 branch.'
        ChangesExecuted = $false
        CaptureAttempted = $false
        RegistryWriteAttempted = $false
        Readbacks = $readbacks
        ExternalProcessStarted = $false
        DownloadStarted = $false
        RebootRequested = $false
        DiscoveryWarnings = @($discovery.Warnings)
        Blockers = @($discovery.Blockers)
    }

    New-BoostLabP0StateResult `
        -Success ([string]$source.ChecksumStatus -eq 'Passed' -and @($discovery.Blockers).Count -eq 0) `
        -Action 'Analyze' `
        -Status $(if ([string]$source.ChecksumStatus -eq 'Passed' -and @($discovery.Blockers).Count -eq 0) { 'Analyzed' } else { 'SourceScopeBlocked' }) `
        -CommandStatus 'No execution performed' `
        -VerificationStatus ([string]$verification.Status) `
        -Message 'P0 State source scope, non-Configuration display-class targets, and current readback state were analyzed. No registry capture, registry write, download, external process, or reboot occurred.' `
        -Data $data `
        -VerificationResult $verification `
        -Warnings @($discovery.Warnings) `
        -Errors $(if ([string]$source.ChecksumStatus -eq 'Passed') { @($discovery.Blockers) } else { @("Source checksum status: $($source.ChecksumStatus)") + @($discovery.Blockers) })
}

function Invoke-BoostLabP0StateRegistrySet {
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

    $source = Get-BoostLabP0StateSourceStatus
    if ([string]$source.ChecksumStatus -ne 'Passed') {
        return New-BoostLabP0StateResult `
            -Success $false `
            -Action $ActionName `
            -Status 'SourceChecksumMismatch' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'P0 State source checksum did not match the approved mirror. No registry discovery, capture, write, or readback was performed.' `
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
        return New-BoostLabP0StateResult `
            -Success $false `
            -Action $ActionName `
            -Status 'AdministratorRequired' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Administrator rights are required before P0 State registry values can be changed.' `
            -Data ([pscustomobject]@{
                Source = $source
                ChangesExecuted = $false
                CaptureAttempted = $false
                RegistryWriteAttempted = $false
            })
    }

    $discovery = Get-BoostLabP0StateDiscovery -TargetEnumerator $TargetEnumerator
    $targets = @($discovery.Targets)
    if (@($discovery.Blockers).Count -gt 0) {
        return New-BoostLabP0StateResult `
            -Success $false `
            -Action $ActionName `
            -Status 'SourceScopeBlocked' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'P0 State registry mutation was blocked because target discovery included out-of-scope registry paths. No capture or write was performed.' `
            -Data ([pscustomObject]@{
                Source = $source
                TargetCount = $targets.Count
                Targets = $targets
                SkippedTargetCount = @($discovery.SkippedTargets).Count
                SkippedTargets = @($discovery.SkippedTargets)
                ChangesExecuted = $false
                CaptureAttempted = $false
                RegistryWriteAttempted = $false
                Blockers = @($discovery.Blockers)
            }) `
            -Warnings @($discovery.Warnings) `
            -Errors @($discovery.Blockers)
    }
    if ($targets.Count -eq 0) {
        $verification = Test-BoostLabP0StateState -ActionName $ActionName -Targets @()
        return New-BoostLabP0StateResult `
            -Success $false `
            -Action $ActionName `
            -Status 'NoSourceTargets' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus ([string]$verification.Status) `
            -Message 'No source-included non-Configuration P0 State display-class registry targets were found. No capture or registry write was performed.' `
            -Data ([pscustomobject]@{
                Source = $source
                SourceKeyNameCount = @($discovery.SourceKeyNames).Count
                SourceKeyNames = @($discovery.SourceKeyNames)
                TargetCount = 0
                Targets = @()
                SkippedTargetCount = @($discovery.SkippedTargets).Count
                SkippedTargets = @($discovery.SkippedTargets)
                ChangesExecuted = $false
                CaptureAttempted = $false
                RegistryWriteAttempted = $false
                DiscoveryWarnings = @($discovery.Warnings)
            }) `
            -VerificationResult $verification `
            -Warnings @($discovery.Warnings) `
            -Errors @('No source-included non-Configuration P0 State display-class registry targets were found.')
    }

    $reader = if ($null -ne $RegistryReader) {
        $RegistryReader
    }
    else {
        { param($Path, $ItemType, $ValueName) Get-BoostLabP0StateRegistryValueState -RegistryPath $Path -ItemType $ItemType -ValueName $ValueName }
    }
    $writer = if ($null -ne $RegistryWriter) {
        $RegistryWriter
    }
    else {
        { param($Target, $Value) Set-BoostLabP0StateRegistryValue -RegistryPath ([string]$Target.RegistryPath) -Value $Value }
    }
    $expectedValue = if ($ActionName -eq 'Default') {
        $script:BoostLabP0StateDefaultValue
    }
    else {
        $script:BoostLabP0StateApplyValue
    }

    $captureRecords = [System.Collections.Generic.List[object]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    $changesAttempted = [System.Collections.Generic.List[string]]::new()
    $changesCompleted = [System.Collections.Generic.List[string]]::new()

    for ($i = 0; $i -lt $targets.Count; $i++) {
        $target = $targets[$i]
        $scopeId = 'p0-state-{0}-{1}' -f $ActionName.ToLowerInvariant(), ($i + 1)
        $policy = New-BoostLabP0StateCapturePolicy -Target $target -ScopeId $scopeId
        $capture = New-BoostLabRegistryStateCapture `
            -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
            -ActionId $ActionName `
            -ScopeId $scopeId `
            -RegistryPath ([string]$target.RegistryPath) `
            -ItemType RegistryValue `
            -ValueName $script:BoostLabP0StateValueName `
            -IntendedMutation RegistrySet `
            -RiskClassification High `
            -VerificationRequirement ('Verify {0} is DWORD {1} after {2}.' -f $script:BoostLabP0StateValueName, $expectedValue, $ActionName) `
            -Policy $policy `
            -RegistryReader $reader `
            -StateRoot $StateRoot
        if (-not [bool]$capture.Success) {
            $errors.Add(('State capture failed for {0}: {1}' -f ([string]$target.RegistryPath), (@($capture.Errors) -join '; ')))
            continue
        }

        $captureRecords.Add(
            [pscustomobject]@{
                TargetPath = [string]$target.RegistryPath
                SourceKeyName = [string]$target.SourceKeyName
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
        return New-BoostLabP0StateResult `
            -Success $false `
            -Action $ActionName `
            -Status 'CaptureFailed' `
            -CommandStatus 'Blocked before mutation' `
            -VerificationStatus 'NotApplicable' `
            -Message 'P0 State registry state capture failed before mutation. No registry write was executed.' `
            -Data ([pscustomobject]@{
                Source = $source
                TargetCount = $targets.Count
                Targets = $targets
                SkippedTargetCount = @($discovery.SkippedTargets).Count
                SkippedTargets = @($discovery.SkippedTargets)
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
            $errors.Add(('Writing {0} failed for {1}: {2}' -f $script:BoostLabP0StateValueName, ([string]$target.RegistryPath), $_.Exception.Message))
        }
    }

    $readbacks = @(Get-BoostLabP0StateReadbackResults -Targets $targets -ExpectedValue $expectedValue -RegistryReader $reader)

    foreach ($captureRecord in $captureRecords) {
        $postState = & $reader ([string]$captureRecord.TargetPath) 'RegistryValue' $script:BoostLabP0StateValueName
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
            $errors.Add(('Recording post-mutation state failed for {0}: {1}' -f ([string]$captureRecord.TargetPath), (@($recordResult.Errors) -join '; ')))
        }
    }

    $verification = Test-BoostLabP0StateState `
        -ActionName $ActionName `
        -Targets $targets `
        -CaptureRecords $captureRecords.ToArray() `
        -Readbacks $readbacks

    $data = [pscustomobject]@{
        Source = $source
        Header = 'NVIDIA Highest Performance Power State'
        PathBStep = '4 of 5'
        SourceRegistryRoot = $script:BoostLabDisplayClassRoot
        SourceRegistryQuery = $script:BoostLabSourceDisplayClassRoot
        SourceSkipRule = '*Configuration*'
        SourceKeyNameCount = @($discovery.SourceKeyNames).Count
        SourceKeyNames = @($discovery.SourceKeyNames)
        TargetCount = $targets.Count
        Targets = $targets
        SkippedTargetCount = @($discovery.SkippedTargets).Count
        SkippedTargets = @($discovery.SkippedTargets)
        WrittenTargetCount = $changesCompleted.Count
        WrittenTargets = $changesCompleted.ToArray()
        Readbacks = $readbacks
        ChangesExecuted = $changesCompleted.Count -gt 0
        RegistryChangesAttempted = $changesAttempted.ToArray()
        RegistryChangesCompleted = $changesCompleted.ToArray()
        CaptureAttempted = $true
        CaptureRecords = $captureRecords.ToArray()
        RegistryWriteAttempted = $changesAttempted.Count -gt 0
        ExpectedValueName = $script:BoostLabP0StateValueName
        ExpectedValueType = 'REG_DWORD'
        ExpectedValueData = $expectedValue
        DefaultImplemented = $true
        RestoreImplemented = $false
        RestoreUnavailableReason = 'No Restore action is source-defined or exposed for P0 State; Default is source-defined DWORD 0 and is not Restore.'
        ExternalProcessStarted = $false
        DownloadStarted = $false
        RebootRequested = $false
        VerificationStatus = [string]$verification.Status
        Errors = $errors.ToArray()
    }

    if ($errors.Count -gt 0) {
        return New-BoostLabP0StateResult `
            -Success $false `
            -Action $ActionName `
            -Status 'Error' `
            -CommandStatus 'Completed with errors' `
            -VerificationStatus ([string]$verification.Status) `
            -Message ('P0 State {0} completed with errors: {1}' -f $ActionName, ($errors -join '; ')) `
            -Data $data `
            -VerificationResult $verification `
            -Errors $errors.ToArray() `
            -ChangesExecuted ($changesCompleted.Count -gt 0)
    }
    if ($verification.Status -eq 'Failed') {
        return New-BoostLabP0StateResult `
            -Success $false `
            -Action $ActionName `
            -Status 'Error' `
            -CommandStatus 'Completed' `
            -VerificationStatus ([string]$verification.Status) `
            -Message ('P0 State {0} completed, but source-equivalent readback verification failed.' -f $ActionName) `
            -Data $data `
            -VerificationResult $verification `
            -ChangesExecuted ($changesCompleted.Count -gt 0)
    }

    New-BoostLabP0StateResult `
        -Success $true `
        -Action $ActionName `
        -Status $(if ($verification.Status -eq 'Warning') { 'Warning' } else { 'Completed' }) `
        -CommandStatus $(if ($verification.Status -eq 'Warning') { 'Completed with warnings' } else { 'Completed' }) `
        -VerificationStatus ([string]$verification.Status) `
        -Message $(if ($ActionName -eq 'Default') { 'P0 State Default set source-defined DisableDynamicPstate DWORD 0 on every source-included non-Configuration display-class target and read the values back.' } else { 'P0 State On (Recommended) set source-defined DisableDynamicPstate DWORD 1 on every source-included non-Configuration display-class target and read the values back.' }) `
        -Data $data `
        -VerificationResult $verification `
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
        ConfirmationRequiredActions = @('Apply', 'Default')
        ConfirmationText = 'P0 State will set DisableDynamicPstate on every source-included non-Configuration display-class registry subkey and read it back. Continue?'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $source = Get-BoostLabP0StateSourceStatus
    [pscustomobject]@{
        Supported = [bool]($source.ChecksumStatus -eq 'Passed')
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason = if ($source.ChecksumStatus -eq 'Passed') {
            'The approved P0 State source mirror is present and checksum verified.'
        }
        else {
            'The approved P0 State source mirror is missing or checksum validation failed.'
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
        [ValidateSet('Analyze', 'Apply', 'Default', 'On (Recommended)')]
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

    $canonicalAction = if ($ActionName -eq 'On (Recommended)') { 'Apply' } else { $ActionName }

    if ($canonicalAction -eq 'Analyze') {
        return Invoke-BoostLabP0StateAnalyze -TargetEnumerator $TargetEnumerator -RegistryReader $RegistryReader
    }

    if (-not $Confirmed) {
        return New-BoostLabP0StateResult `
            -Success $false `
            -Action $canonicalAction `
            -Status 'Cancelled' `
            -CommandStatus 'Cancelled' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    Invoke-BoostLabP0StateRegistrySet `
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

    Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed:$Confirmed
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
