Set-StrictMode -Version Latest

$coreRoot = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path $coreRoot 'Verification.psm1') -Scope Local -ErrorAction Stop
}
if (-not (Get-Command -Name 'New-BoostLabRegistryStateCapture' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path $coreRoot 'StateCapture.psm1') -Scope Local -ErrorAction Stop
}
if (-not (Get-Command -Name 'Invoke-BoostLabRegistryRollback' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path $coreRoot 'Rollback.psm1') -Scope Local -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'updates-drivers-block'
    Title = 'Updates Drivers Block'
    Stage = 'Refresh'
    Order = 3
    Type = 'action'
    RiskLevel = 'high'
    Description = 'Apply or default the source-defined live Driver Updates policy registry values after captured prior state.'
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
        SupportsRestore = $true
        NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Analyze', 'Apply', 'Default', 'Restore')
$script:BoostLabExpectedSourceHash = '4D4EC652C5A7F78824F53B7DC7FD46DDA948F3716A7CD6FD102D6C678EE11991'
$script:BoostLabSourceRelativePath = 'source-ultimate/2 Refresh/3 Updates Drivers Block.ps1'
$script:BoostLabSupportedSourceBranch = 'Driver Updates live policy branch: menu option 1 Block and menu option 3 Unblock'
$script:BoostLabUnsupportedSourceBranches = @(
    'Driver Updates Block (Bootable USB): generates setupcomplete.cmd and embeds shutdown /r /t 0.',
    'Updates Block: writes broad Windows Update blocking values and custom WSUS URL values.',
    'Updates Block (Bootable USB): generates setupcomplete.cmd and embeds shutdown /r /t 0.',
    'Updates Unblock: deletes broad Windows Update blocking values outside the approved driver-delivery scope.'
)
$script:BoostLabDriverPolicyEntries = @(
    [pscustomobject]@{ RegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\Device Metadata'; ValueName = 'PreventDeviceMetadataFromNetwork'; ValueType = 'DWord'; ApplyValue = 1 },
    [pscustomobject]@{ RegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\DeviceInstall\Settings'; ValueName = 'DisableSendGenericDriverNotFoundToWER'; ValueType = 'DWord'; ApplyValue = 1 },
    [pscustomobject]@{ RegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\DeviceInstall\Settings'; ValueName = 'DisableSendRequestAdditionalSoftwareToWER'; ValueType = 'DWord'; ApplyValue = 1 },
    [pscustomobject]@{ RegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\DriverSearching'; ValueName = 'SearchOrderConfig'; ValueType = 'DWord'; ApplyValue = 0 },
    [pscustomobject]@{ RegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate'; ValueName = 'SetAllowOptionalContent'; ValueType = 'DWord'; ApplyValue = 0 },
    [pscustomobject]@{ RegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate'; ValueName = 'AllowTemporaryEnterpriseFeatureControl'; ValueType = 'DWord'; ApplyValue = 0 },
    [pscustomobject]@{ RegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate'; ValueName = 'ExcludeWUDriversInQualityUpdate'; ValueType = 'DWord'; ApplyValue = 1 },
    [pscustomobject]@{ RegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'; ValueName = 'IncludeRecommendedUpdates'; ValueType = 'DWord'; ApplyValue = 0 },
    [pscustomobject]@{ RegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'; ValueName = 'EnableFeaturedSoftware'; ValueType = 'DWord'; ApplyValue = 0 }
)

function Get-BoostLabUpdatesDriversSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $projectRoot ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabUpdatesDriversSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabUpdatesDriversSourcePath
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

function ConvertTo-BoostLabUpdatesDriversRegistryPath {
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

function Get-BoostLabUpdatesDriversPolicyEntries {
    [CmdletBinding()]
    [OutputType([object[]])]
    param()

    return @($script:BoostLabDriverPolicyEntries)
}

function Test-BoostLabUpdatesDriversRegistryTarget {
    param(
        [Parameter(Mandatory)]
        [string]$RegistryPath,

        [Parameter(Mandatory)]
        [string]$ValueName
    )

    $normalized = ConvertTo-BoostLabUpdatesDriversRegistryPath -Path $RegistryPath
    if ($normalized.IndexOfAny([char[]]'*?[]') -ge 0) {
        return $false
    }

    foreach ($entry in Get-BoostLabUpdatesDriversPolicyEntries) {
        if (
            $normalized.Equals([string]$entry.RegistryPath, [StringComparison]::OrdinalIgnoreCase) -and
            [string]$ValueName -eq [string]$entry.ValueName
        ) {
            return $true
        }
    }

    return $false
}

function Get-BoostLabUpdatesDriversRegistryValueState {
    param(
        [Parameter(Mandatory)]
        [string]$RegistryPath,

        [string]$ItemType = 'RegistryValue',

        [Parameter(Mandatory)]
        [string]$ValueName
    )

    $path = ConvertTo-BoostLabUpdatesDriversRegistryPath -Path $RegistryPath
    if (-not (Test-BoostLabUpdatesDriversRegistryTarget -RegistryPath $path -ValueName $ValueName)) {
        return [pscustomobject]@{
            ReadSucceeded = $false
            KeyExists = $null
            Exists = $false
            Metadata = $null
            DisplayValue = 'Blocked'
            Message = 'Registry path/value is outside the approved Updates Drivers Block driver-policy scope.'
        }
    }

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

function ConvertTo-BoostLabUpdatesDriversRegistryState {
    param(
        [AllowNull()]
        [object]$State
    )

    if ($null -eq $State) {
        return [pscustomobject]@{
            ReadSucceeded = $false
            KeyExists = $null
            Exists = $false
            Metadata = $null
            DisplayValue = 'Unknown'
            Message = 'Registry reader returned no state.'
        }
    }
    if ($null -ne $State.PSObject.Properties['ReadSucceeded']) {
        return $State
    }

    $exists = if ($null -ne $State.PSObject.Properties['Exists']) {
        [bool]$State.Exists
    }
    else {
        $false
    }
    $metadata = if ($null -ne $State.PSObject.Properties['Metadata']) {
        $State.Metadata
    }
    else {
        $null
    }
    $displayValue = if ($exists -and $null -ne $metadata) {
        '{0} {1}' -f [string]$metadata.ValueType, [string]$metadata.ValueData
    }
    else {
        'Absent'
    }

    return [pscustomobject]@{
        ReadSucceeded = $true
        KeyExists = $null
        Exists = $exists
        Metadata = $metadata
        DisplayValue = $displayValue
        Message = if ($exists) { 'Registry value detected.' } else { 'Registry value is absent.' }
    }
}

function Set-BoostLabUpdatesDriversRegistryValue {
    param(
        [Parameter(Mandatory)]
        [object]$Entry
    )

    $path = ConvertTo-BoostLabUpdatesDriversRegistryPath -Path ([string]$Entry.RegistryPath)
    $valueName = [string]$Entry.ValueName
    if (-not (Test-BoostLabUpdatesDriversRegistryTarget -RegistryPath $path -ValueName $valueName)) {
        throw "Registry target is outside the approved Updates Drivers Block scope: $path | $valueName"
    }

    if ([string]$Entry.ValueType -ne 'DWord') {
        throw "Unsupported registry value type for Updates Drivers Block: $($Entry.ValueType)"
    }

    $subKeyPath = if ($path.StartsWith('HKLM:\', [StringComparison]::OrdinalIgnoreCase)) {
        $path.Substring('HKLM:\'.Length)
    }
    elseif ($path.StartsWith('HKEY_LOCAL_MACHINE\', [StringComparison]::OrdinalIgnoreCase)) {
        $path.Substring('HKEY_LOCAL_MACHINE\'.Length)
    }
    else {
        throw "Unsupported registry hive for Updates Drivers Block: $path"
    }

    $baseKey = $null
    $key = $null
    try {
        $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
            [Microsoft.Win32.RegistryHive]::LocalMachine,
            [Microsoft.Win32.RegistryView]::Default
        )
        $key = $baseKey.CreateSubKey($subKeyPath, $true)
        if ($null -eq $key) {
            throw "Could not create or open registry key: $path"
        }
        $key.SetValue($valueName, [int]$Entry.ApplyValue, [Microsoft.Win32.RegistryValueKind]::DWord)
        $key.Flush()
    }
    finally {
        if ($null -ne $key) {
            $key.Dispose()
        }
        if ($null -ne $baseKey) {
            $baseKey.Dispose()
        }
    }
}

function Remove-BoostLabUpdatesDriversRegistryValue {
    param(
        [Parameter(Mandatory)]
        [object]$Entry
    )

    $path = ConvertTo-BoostLabUpdatesDriversRegistryPath -Path ([string]$Entry.RegistryPath)
    $valueName = [string]$Entry.ValueName
    if (-not (Test-BoostLabUpdatesDriversRegistryTarget -RegistryPath $path -ValueName $valueName)) {
        throw "Registry target is outside the approved Updates Drivers Block scope: $path | $valueName"
    }
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        return
    }

    $key = Get-Item -LiteralPath $path -ErrorAction Stop
    if ($valueName -in @($key.GetValueNames())) {
        Remove-ItemProperty -LiteralPath $path -Name $valueName -Force -ErrorAction Stop
    }
}

function New-BoostLabUpdatesDriversCapturePolicy {
    param(
        [Parameter(Mandatory)]
        [object]$Entry,

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
                AllowedPath = [string]$Entry.RegistryPath
                AllowedValueNames = @([string]$Entry.ValueName)
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

function New-BoostLabUpdatesDriversResult {
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
        ChangesExecuted = $ChangesExecuted
        Timestamp = Get-Date
        Data = $Data
        VerificationResult = $VerificationResult
        Warnings = @($Warnings)
        Errors = @($Errors)
    }
}

function Test-BoostLabUpdatesDriversPolicyState {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Analyze', 'Apply', 'Default')]
        [string]$ActionName,

        [AllowNull()]
        [object[]]$Entries = @(),

        [AllowNull()]
        [object[]]$CaptureRecords = @(),

        [AllowNull()]
        [scriptblock]$RegistryReader = $null
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    $reader = if ($null -ne $RegistryReader) {
        $RegistryReader
    }
    else {
        { param($Path, $ItemType, $ValueName) Get-BoostLabUpdatesDriversRegistryValueState -RegistryPath $Path -ItemType $ItemType -ValueName $ValueName }
    }

    $entryCount = @($Entries).Count
    $captureCount = @($CaptureRecords).Count
    $checks.Add(
        (New-BoostLabVerificationCheck `
            -Name 'Source-defined driver policy scope' `
            -Expected 'Exactly 9 Driver Updates policy registry values from Ultimate menu options 1 and 3' `
            -Actual "$entryCount value(s)" `
            -Status $(if ($entryCount -eq 9) { 'Passed' } else { 'Failed' }) `
            -Message 'BoostLab only supports the bounded live Driver Updates policy branch in this phase.')
    )

    if ($ActionName -ne 'Analyze') {
        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name 'Pre-mutation capture records' `
                -Expected "$entryCount capture record(s)" `
                -Actual "$captureCount capture record(s)" `
                -Status $(if ($entryCount -gt 0 -and $captureCount -eq $entryCount) { 'Passed' } else { 'Failed' }) `
                -Message 'Each source-defined policy value must be captured before mutation.')
        )
    }

    foreach ($entry in @($Entries)) {
        $state = ConvertTo-BoostLabUpdatesDriversRegistryState -State (& $reader ([string]$entry.RegistryPath) 'RegistryValue' ([string]$entry.ValueName))
        if ($ActionName -eq 'Analyze') {
            $status = if ($null -eq $state -or -not [bool]$state.ReadSucceeded) { 'Warning' } else { 'Passed' }
            $expected = 'Readable current registry policy state'
        }
        elseif ($ActionName -eq 'Apply') {
            $valueType = if ($null -ne $state -and $null -ne $state.Metadata) { [string]$state.Metadata.ValueType } else { '' }
            $valueData = if ($null -ne $state -and $null -ne $state.Metadata) { $state.Metadata.ValueData } else { $null }
            $status = if ($null -eq $state -or -not [bool]$state.ReadSucceeded) {
                'Warning'
            }
            elseif (-not [bool]$state.Exists) {
                'Failed'
            }
            elseif ($valueType -notin @('DWord', 'REG_DWORD') -or [string]$valueData -ne [string]$entry.ApplyValue) {
                'Failed'
            }
            else {
                'Passed'
            }
            $expected = '{0} DWORD {1}' -f [string]$entry.ValueName, [int]$entry.ApplyValue
        }
        else {
            $status = if ($null -eq $state -or -not [bool]$state.ReadSucceeded) {
                'Warning'
            }
            elseif ([bool]$state.Exists) {
                'Failed'
            }
            else {
                'Passed'
            }
            $expected = '{0} absent' -f [string]$entry.ValueName
        }

        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name ('{0} | {1}' -f [string]$entry.ValueName, [string]$entry.RegistryPath) `
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
    else {
        'Passed'
    }

    return New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $ActionName `
        -Status $overallStatus `
        -ExpectedState ([pscustomobject]@{
            SupportedSourceBranch = $script:BoostLabSupportedSourceBranch
            ValueCount = $entryCount
            ExpectedState = if ($ActionName -eq 'Default') { 'Absent' } elseif ($ActionName -eq 'Apply') { 'Source-defined DWORD values' } else { 'Read-only analysis' }
        }) `
        -DetectedState ([pscustomobject]@{
            ValueCount = $entryCount
            CaptureRecordCount = $captureCount
            FailedChecks = @($checks | Where-Object { $_.Status -eq 'Failed' }).Count
            WarningChecks = @($checks | Where-Object { $_.Status -eq 'Warning' }).Count
        }) `
        -Checks $checks.ToArray() `
        -Message $(switch ($overallStatus) {
            'Passed' { if ($ActionName -eq 'Apply') { 'All source-defined driver update block policy values are set.' } elseif ($ActionName -eq 'Default') { 'All source-defined driver update block policy values are absent.' } else { 'Driver update policy state was analyzed.' } }
            'Warning' { 'Driver update policy state was analyzed with warnings.' }
            default { 'One or more source-defined driver update policy values did not match the expected state.' }
        })
}

function Get-BoostLabUpdatesDriversCurrentState {
    param(
        [AllowNull()]
        [scriptblock]$RegistryReader = $null
    )

    $reader = if ($null -ne $RegistryReader) {
        $RegistryReader
    }
    else {
        { param($Path, $ItemType, $ValueName) Get-BoostLabUpdatesDriversRegistryValueState -RegistryPath $Path -ItemType $ItemType -ValueName $ValueName }
    }

    foreach ($entry in Get-BoostLabUpdatesDriversPolicyEntries) {
        $state = ConvertTo-BoostLabUpdatesDriversRegistryState -State (& $reader ([string]$entry.RegistryPath) 'RegistryValue' ([string]$entry.ValueName))
        [pscustomobject]@{
            RegistryPath = [string]$entry.RegistryPath
            ValueName = [string]$entry.ValueName
            SourceApplyValue = [int]$entry.ApplyValue
            CurrentState = if ($null -ne $state) { [string]$state.DisplayValue } else { 'Unknown' }
            Exists = if ($null -ne $state) { [bool]$state.Exists } else { $false }
            ReadSucceeded = if ($null -ne $state) { [bool]$state.ReadSucceeded } else { $false }
            Message = if ($null -ne $state) { [string]$state.Message } else { 'Registry reader returned no state.' }
        }
    }
}

function Invoke-BoostLabUpdatesDriversAnalyze {
    param(
        [AllowNull()]
        [scriptblock]$RegistryReader = $null
    )

    $source = Get-BoostLabUpdatesDriversSourceStatus
    $entries = @(Get-BoostLabUpdatesDriversPolicyEntries)
    $verification = Test-BoostLabUpdatesDriversPolicyState -ActionName 'Analyze' -Entries $entries -RegistryReader $RegistryReader
    $data = [pscustomobject]@{
        Source = $source
        SupportedSourceBranch = $script:BoostLabSupportedSourceBranch
        UnsupportedSourceBranches = @($script:BoostLabUnsupportedSourceBranches)
        SupportedRegistryValues = $entries
        SupportedValueCount = @($entries).Count
        CurrentPolicyState = @(Get-BoostLabUpdatesDriversCurrentState -RegistryReader $RegistryReader)
        ApplyAvailable = [string]$source.ChecksumStatus -eq 'Passed'
        DefaultAvailable = [string]$source.ChecksumStatus -eq 'Passed'
        RestoreAvailable = 'Requires selected captured rollback record from Apply or Default.'
        ChangesExecuted = $false
        NoDriverDeviceMutation = $true
        NoWindowsUpdateExecution = $true
        NoDownloadOrInstaller = $true
    }

    if ([string]$source.ChecksumStatus -ne 'Passed') {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action 'Analyze' `
            -Status 'NeedsSourceIdentity' `
            -CommandStatus 'No execution performed' `
            -VerificationStatus 'Failed' `
            -Message 'Updates Drivers Block source identity could not be verified. No mutation is available.' `
            -Data $data `
            -VerificationResult $verification `
            -Errors @('Source checksum failed or source file is missing.')
    }

    return New-BoostLabUpdatesDriversResult `
        -Success $true `
        -Action 'Analyze' `
        -Status 'Analyzed' `
        -CommandStatus 'No execution performed' `
        -VerificationStatus ([string]$verification.Status) `
        -Message 'Updates Drivers Block analyzed the source-defined live Driver Updates policy registry scope. No mutation occurred.' `
        -Data $data `
        -VerificationResult $verification `
        -Warnings @($script:BoostLabUnsupportedSourceBranches)
}

function Invoke-BoostLabUpdatesDriversPolicyMutation {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [bool]$Confirmed = $false,

        [AllowNull()]
        [scriptblock]$AdministratorChecker = $null,

        [AllowNull()]
        [scriptblock]$RegistryReader = $null,

        [AllowNull()]
        [scriptblock]$RegistryWriter = $null,

        [AllowNull()]
        [scriptblock]$RegistryRemover = $null,

        [string]$StateRoot = (Get-BoostLabRollbackStateRoot)
    )

    if (-not $Confirmed) {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action $ActionName `
            -Status 'Cancelled' `
            -CommandStatus 'Cancelled before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message "Updates Drivers Block $ActionName cancelled before registry capture or mutation." `
            -Cancelled:$true `
            -Data ([pscustomobject]@{ ChangesExecuted = $false; CaptureAttempted = $false; RegistryWriteAttempted = $false })
    }

    $source = Get-BoostLabUpdatesDriversSourceStatus
    if ([string]$source.ChecksumStatus -ne 'Passed') {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action $ActionName `
            -Status 'NeedsSourceIdentity' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Failed' `
            -Message 'Updates Drivers Block source identity could not be verified. No mutation occurred.' `
            -Data ([pscustomobject]@{ Source = $source; ChangesExecuted = $false; CaptureAttempted = $false; RegistryWriteAttempted = $false }) `
            -Errors @('Source checksum failed or source file is missing.')
    }

    $isAdmin = if ($null -ne $AdministratorChecker) {
        [bool](& $AdministratorChecker)
    }
    else {
        Test-BoostLabAdministrator
    }
    if (-not $isAdmin) {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action $ActionName `
            -Status 'Error' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Administrator rights are required to modify HKLM Windows Update driver policy values.' `
            -Data ([pscustomobject]@{ ChangesExecuted = $false; CaptureAttempted = $false; RegistryWriteAttempted = $false }) `
            -Errors @('Administrator rights are required.')
    }

    $entries = @(Get-BoostLabUpdatesDriversPolicyEntries)
    $reader = if ($null -ne $RegistryReader) {
        $RegistryReader
    }
    else {
        { param($Path, $ItemType, $ValueName) Get-BoostLabUpdatesDriversRegistryValueState -RegistryPath $Path -ItemType $ItemType -ValueName $ValueName }
    }
    $writer = if ($null -ne $RegistryWriter) {
        $RegistryWriter
    }
    else {
        { param($Entry) Set-BoostLabUpdatesDriversRegistryValue -Entry $Entry }
    }
    $remover = if ($null -ne $RegistryRemover) {
        $RegistryRemover
    }
    else {
        { param($Entry) Remove-BoostLabUpdatesDriversRegistryValue -Entry $Entry }
    }

    $captureRecords = [System.Collections.Generic.List[object]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    $changesAttempted = [System.Collections.Generic.List[string]]::new()
    $changesCompleted = [System.Collections.Generic.List[string]]::new()

    for ($i = 0; $i -lt $entries.Count; $i++) {
        $entry = $entries[$i]
        $scopeId = 'updates-drivers-block-{0}-{1}' -f $ActionName.ToLowerInvariant(), ($i + 1)
        $capture = New-BoostLabRegistryStateCapture `
            -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
            -ActionId $ActionName `
            -ScopeId $scopeId `
            -RegistryPath ([string]$entry.RegistryPath) `
            -ItemType RegistryValue `
            -ValueName ([string]$entry.ValueName) `
            -IntendedMutation $(if ($ActionName -eq 'Apply') { 'RegistrySet' } else { 'RegistryDelete' }) `
            -RiskClassification High `
            -VerificationRequirement $(if ($ActionName -eq 'Apply') { 'Verify exact source-defined DWORD value after Apply.' } else { 'Verify exact source-defined policy value is absent after Default.' }) `
            -Policy (New-BoostLabUpdatesDriversCapturePolicy -Entry $entry -ScopeId $scopeId) `
            -RegistryReader $reader `
            -StateRoot $StateRoot
        if (-not [bool]$capture.Success) {
            $errors.Add(('State capture failed for {0} | {1}: {2}' -f [string]$entry.RegistryPath, [string]$entry.ValueName, (@($capture.Errors) -join '; ')))
            continue
        }

        $captureRecords.Add([pscustomobject]@{
            RegistryPath = [string]$entry.RegistryPath
            ValueName = [string]$entry.ValueName
            ScopeId = $scopeId
            OperationId = [string]$capture.OperationId
            RecordPath = [string]$capture.RecordPath
            OriginalExists = [bool]$capture.Record.OriginalExists
            OriginalMetadata = $capture.Record.OriginalMetadata
        })
    }

    if ($errors.Count -gt 0) {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action $ActionName `
            -Status 'Error' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Failed' `
            -Message 'Registry state capture failed before mutation. No changes were executed.' `
            -Data ([pscustomobject]@{ Source = $source; ChangesExecuted = $false; CaptureRecords = $captureRecords.ToArray(); Errors = $errors.ToArray() }) `
            -Errors $errors.ToArray()
    }

    foreach ($entry in $entries) {
        $targetText = '{0} | {1}' -f [string]$entry.RegistryPath, [string]$entry.ValueName
        $changesAttempted.Add($targetText)
        try {
            if ($ActionName -eq 'Apply') {
                & $writer $entry
            }
            else {
                & $remover $entry
            }

            $postWriteState = ConvertTo-BoostLabUpdatesDriversRegistryState -State (& $reader ([string]$entry.RegistryPath) 'RegistryValue' ([string]$entry.ValueName))
            if ($null -eq $postWriteState -or -not [bool]$postWriteState.ReadSucceeded) {
                throw "Post-$ActionName verification could not read $targetText."
            }
            if ($ActionName -eq 'Apply') {
                $postValueType = if ($null -ne $postWriteState.Metadata) { [string]$postWriteState.Metadata.ValueType } else { '' }
                $postValueData = if ($null -ne $postWriteState.Metadata) { $postWriteState.Metadata.ValueData } else { $null }
                if (
                    -not [bool]$postWriteState.Exists -or
                    $postValueType -notin @('DWord', 'REG_DWORD') -or
                    [int]$postValueData -ne [int]$entry.ApplyValue
                ) {
                    throw ('Post-Apply verification failed for {0}. Expected REG_DWORD {1}; detected {2}.' -f $targetText, [int]$entry.ApplyValue, [string]$postWriteState.DisplayValue)
                }
            }
            elseif ([bool]$postWriteState.Exists) {
                throw ('Post-Default verification failed for {0}. Expected Absent; detected {1}.' -f $targetText, [string]$postWriteState.DisplayValue)
            }
            $changesCompleted.Add($targetText)
        }
        catch {
            $errors.Add(('{0} failed for {1}: {2}' -f $ActionName, $targetText, $_.Exception.Message))
        }
    }

    foreach ($captureRecord in $captureRecords) {
        $postState = ConvertTo-BoostLabUpdatesDriversRegistryState -State (& $reader ([string]$captureRecord.RegistryPath) 'RegistryValue' ([string]$captureRecord.ValueName))
        if ($null -eq $postState -or -not [bool]$postState.ReadSucceeded) {
            $errors.Add("Post-mutation state could not be read for $($captureRecord.RegistryPath) | $($captureRecord.ValueName).")
            continue
        }

        $recordResult = Set-BoostLabRollbackMutationState `
            -RecordPath ([string]$captureRecord.RecordPath) `
            -StateRoot $StateRoot `
            -PostMutationExists ([bool]$postState.Exists) `
            -PostMutationMetadata $postState.Metadata
        if (-not [bool]$recordResult.Success) {
            $errors.Add(('Recording post-mutation state failed for {0} | {1}: {2}' -f [string]$captureRecord.RegistryPath, [string]$captureRecord.ValueName, (@($recordResult.Errors) -join '; ')))
        }
    }

    $verification = Test-BoostLabUpdatesDriversPolicyState `
        -ActionName $ActionName `
        -Entries $entries `
        -CaptureRecords $captureRecords.ToArray() `
        -RegistryReader $reader

    $data = [pscustomobject]@{
        Source = $source
        SupportedSourceBranch = $script:BoostLabSupportedSourceBranch
        UnsupportedSourceBranches = @($script:BoostLabUnsupportedSourceBranches)
        SupportedValueCount = @($entries).Count
        ChangesExecuted = $changesCompleted.Count -gt 0
        RegistryChangesAttempted = $changesAttempted.ToArray()
        RegistryChangesCompleted = $changesCompleted.ToArray()
        CaptureRecords = $captureRecords.ToArray()
        VerificationStatus = [string]$verification.Status
        DefaultIsRestore = $false
        RestoreRequiresCapturedState = $true
        NoDriverDeviceMutation = $true
        NoWindowsUpdateExecution = $true
        NoDownloadOrInstaller = $true
        Errors = $errors.ToArray()
    }

    if ($errors.Count -gt 0) {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action $ActionName `
            -Status 'Error' `
            -CommandStatus 'Failed with errors' `
            -VerificationStatus ([string]$verification.Status) `
            -Message ("Updates Drivers Block $ActionName completed with errors: {0}" -f ($errors -join '; ')) `
            -Data $data `
            -VerificationResult $verification `
            -ChangesExecuted:($changesCompleted.Count -gt 0) `
            -Errors $errors.ToArray()
    }

    if ([string]$verification.Status -eq 'Failed') {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action $ActionName `
            -Status 'Error' `
            -CommandStatus 'Failed verification' `
            -VerificationStatus ([string]$verification.Status) `
            -Message "Updates Drivers Block $ActionName completed, but verification failed." `
            -Data $data `
            -VerificationResult $verification `
            -ChangesExecuted:($changesCompleted.Count -gt 0) `
            -Errors @("Updates Drivers Block $ActionName verification failed.")
    }

    $message = if ($ActionName -eq 'Apply') {
        'Updates Drivers Block Apply wrote only the nine source-defined Driver Updates policy values after captured prior state.'
    }
    else {
        'Updates Drivers Block Default removed only the nine source-defined Driver Updates policy values after captured prior state.'
    }
    return New-BoostLabUpdatesDriversResult `
        -Success $true `
        -Action $ActionName `
        -Status $(if ([string]$verification.Status -eq 'Warning') { 'Warning' } else { 'Completed' }) `
        -CommandStatus $(if ([string]$verification.Status -eq 'Warning') { 'Completed with warnings' } else { 'Completed' }) `
        -VerificationStatus ([string]$verification.Status) `
        -Message $message `
        -Data $data `
        -VerificationResult $verification `
        -ChangesExecuted:($changesCompleted.Count -gt 0)
}

function Invoke-BoostLabUpdatesDriversRestore {
    param(
        [bool]$Confirmed = $false,

        [string]$SelectedCapturePath = '',

        [AllowNull()]
        [scriptblock]$AdministratorChecker = $null,

        [AllowNull()]
        [scriptblock]$RegistryReader = $null,

        [AllowNull()]
        [scriptblock]$RegistryWriter = $null,

        [AllowNull()]
        [scriptblock]$RegistryRemover = $null,

        [string]$StateRoot = (Get-BoostLabRollbackStateRoot)
    )

    if (-not $Confirmed) {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action 'Restore' `
            -Status 'Cancelled' `
            -CommandStatus 'Cancelled before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Updates Drivers Block Restore cancelled before captured-state validation.' `
            -Cancelled:$true `
            -Data ([pscustomobject]@{ ChangesExecuted = $false; RestoreAttempted = $false })
    }

    if ([string]::IsNullOrWhiteSpace($SelectedCapturePath)) {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action 'Restore' `
            -Status 'RestoreRequiresCapturedState' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Updates Drivers Block Restore requires a selected captured rollback record from this tool. Default is source-defined value deletion and is not Restore.' `
            -Data ([pscustomobject]@{
                ChangesExecuted = $false
                RestoreAttempted = $false
                RestoreRequiresCapturedState = $true
                DefaultIsRestore = $false
            })
    }

    $source = Get-BoostLabUpdatesDriversSourceStatus
    if ([string]$source.ChecksumStatus -ne 'Passed') {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action 'Restore' `
            -Status 'NeedsSourceIdentity' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Failed' `
            -Message 'Updates Drivers Block source identity could not be verified. Restore did not run.' `
            -Data ([pscustomobject]@{ Source = $source; ChangesExecuted = $false; RestoreAttempted = $false }) `
            -Errors @('Source checksum failed or source file is missing.')
    }

    $isAdmin = if ($null -ne $AdministratorChecker) {
        [bool](& $AdministratorChecker)
    }
    else {
        Test-BoostLabAdministrator
    }
    if (-not $isAdmin) {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action 'Restore' `
            -Status 'Error' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Administrator rights are required to restore HKLM Windows Update driver policy values.' `
            -Data ([pscustomobject]@{ ChangesExecuted = $false; RestoreAttempted = $false }) `
            -Errors @('Administrator rights are required.')
    }

    $restoreTargets = @{}
    foreach ($entry in Get-BoostLabUpdatesDriversPolicyEntries) {
        $restoreTargets[('{0}|{1}' -f [string]$entry.RegistryPath, [string]$entry.ValueName)] = $true
    }
    $normalizeRestorePath = {
        param([string]$Path)
        if ($Path.StartsWith('HKEY_LOCAL_MACHINE\', [StringComparison]::OrdinalIgnoreCase)) {
            return 'HKLM:\' + $Path.Substring('HKEY_LOCAL_MACHINE\'.Length)
        }
        if ($Path.StartsWith('HKLM\', [StringComparison]::OrdinalIgnoreCase)) {
            return 'HKLM:\' + $Path.Substring('HKLM\'.Length)
        }
        return $Path
    }
    $reader = if ($null -ne $RegistryReader) {
        $RegistryReader
    }
    else {
        {
            param($Path, $ItemType, $ValueName)
            $normalizedPath = & $normalizeRestorePath ([string]$Path)
            if (-not $restoreTargets.ContainsKey(('{0}|{1}' -f $normalizedPath, [string]$ValueName))) {
                throw "Registry restore read target is outside the approved Updates Drivers Block scope: $normalizedPath | $ValueName"
            }
            try {
                if (-not (Test-Path -LiteralPath $normalizedPath)) {
                    return [pscustomobject]@{
                        ReadSucceeded = $true
                        KeyExists = $false
                        Exists = $false
                        Metadata = $null
                        DisplayValue = 'Absent'
                        Message = 'Registry key is absent.'
                    }
                }
                $key = Get-Item -LiteralPath $normalizedPath -ErrorAction Stop
                $names = @($key.GetValueNames())
                if ($ValueName -notin $names) {
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
        }.GetNewClosure()
    }
    $writer = if ($null -ne $RegistryWriter) {
        {
            param($RegistryPath, $ItemType, $ValueName, $Metadata)
            $path = & $normalizeRestorePath ([string]$RegistryPath)
            if (-not $restoreTargets.ContainsKey(('{0}|{1}' -f $path, [string]$ValueName))) {
                throw "Registry restore target is outside the approved Updates Drivers Block scope: $path | $ValueName"
            }
            & $RegistryWriter ([pscustomobject]@{
                RegistryPath = $path
                ValueName = $ValueName
                ValueType = [string]$Metadata.ValueType
                ApplyValue = $Metadata.ValueData
            })
        }.GetNewClosure()
    }
    else {
        {
            param($RegistryPath, $ItemType, $ValueName, $Metadata)
            $path = & $normalizeRestorePath ([string]$RegistryPath)
            if (-not $restoreTargets.ContainsKey(('{0}|{1}' -f $path, [string]$ValueName))) {
                throw "Registry restore target is outside the approved Updates Drivers Block scope: $path | $ValueName"
            }
            $valueType = [string]$Metadata.ValueType
            $valueData = $Metadata.ValueData
            New-Item -Path $path -Force -ErrorAction Stop | Out-Null
            New-ItemProperty -LiteralPath $path -Name $ValueName -PropertyType $valueType -Value $valueData -Force -ErrorAction Stop | Out-Null
        }.GetNewClosure()
    }
    $remover = if ($null -ne $RegistryRemover) {
        {
            param($RegistryPath, $ItemType, $ValueName)
            $path = & $normalizeRestorePath ([string]$RegistryPath)
            if (-not $restoreTargets.ContainsKey(('{0}|{1}' -f $path, [string]$ValueName))) {
                throw "Registry restore target is outside the approved Updates Drivers Block scope: $path | $ValueName"
            }
            & $RegistryRemover ([pscustomobject]@{
                RegistryPath = $path
                ValueName = $ValueName
                ValueType = 'DWord'
                ApplyValue = 0
            })
        }.GetNewClosure()
    }
    else {
        {
            param($RegistryPath, $ItemType, $ValueName)
            $path = & $normalizeRestorePath ([string]$RegistryPath)
            if (-not $restoreTargets.ContainsKey(('{0}|{1}' -f $path, [string]$ValueName))) {
                throw "Registry restore target is outside the approved Updates Drivers Block scope: $path | $ValueName"
            }
            if (Test-Path -LiteralPath $path) {
                Remove-ItemProperty -LiteralPath $path -Name $ValueName -ErrorAction SilentlyContinue
            }
        }.GetNewClosure()
    }

    $imported = Import-BoostLabRollbackRecord -RecordPath $SelectedCapturePath -StateRoot $StateRoot
    if (-not [bool]$imported.IsValid) {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action 'Restore' `
            -Status 'Error' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Failed' `
            -Message 'Selected rollback record is missing or invalid. Restore did not run.' `
            -Data ([pscustomobject]@{ RecordPath = $SelectedCapturePath; ChangesExecuted = $false; RestoreAttempted = $false }) `
            -Errors @($imported.Errors)
    }

    $record = $imported.Record
    $recordAction = [string]$record.ActionId
    $recordPath = [string]$record.RegistryPath
    $recordValue = [string]$record.ValueName
    $entry = @(Get-BoostLabUpdatesDriversPolicyEntries | Where-Object {
        [string]$_.ValueName -eq $recordValue -and
        [string]$_.RegistryPath -eq $recordPath
    }) | Select-Object -First 1
    if (
        [string]$record.ToolId -ne [string]$script:BoostLabToolMetadata['Id'] -or
        $recordAction -notin @('Apply', 'Default') -or
        $null -eq $entry -or
        [string]$record.ItemType -ne 'RegistryValue'
    ) {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action 'Restore' `
            -Status 'Error' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Failed' `
            -Message 'Selected rollback record is outside the approved Updates Drivers Block restore scope.' `
            -Data ([pscustomobject]@{ RecordPath = $SelectedCapturePath; ChangesExecuted = $false; RestoreAttempted = $false }) `
            -Errors @('Selected rollback record does not match this tool, source action, registry value, or item type.')
    }

    $policy = New-BoostLabUpdatesDriversCapturePolicy -Entry $entry -ScopeId ([string]$record.ScopeId)
    $rollback = Invoke-BoostLabRegistryRollback `
        -RecordPath $SelectedCapturePath `
        -StateRoot $StateRoot `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ActionId $recordAction `
        -RegistryReader $reader `
        -RegistryWriter $writer `
        -RegistryRemover $remover `
        -Policy $policy

    $verification = New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action 'Restore' `
        -Status $(if ([bool]$rollback.Success) { 'Passed' } else { 'Failed' }) `
        -ExpectedState 'Selected captured registry value prior state restored exactly.' `
        -DetectedState ([string]$rollback.Status) `
        -Checks @(
            (New-BoostLabVerificationCheck `
                -Name 'Captured-state rollback' `
                -Expected 'Restored' `
                -Actual ([string]$rollback.Status) `
                -Status $(if ([bool]$rollback.Success) { 'Passed' } else { 'Failed' }) `
                -Message ([string]$rollback.Message))
        ) `
        -Message ([string]$rollback.Message)

    return New-BoostLabUpdatesDriversResult `
        -Success ([bool]$rollback.Success) `
        -Action 'Restore' `
        -Status $(if ([bool]$rollback.Success) { 'Restored' } else { [string]$rollback.Status }) `
        -CommandStatus $(if ([bool]$rollback.Success) { 'Restored captured state' } else { 'Blocked or failed' }) `
        -VerificationStatus ([string]$verification.Status) `
        -Message ([string]$rollback.Message) `
        -Data ([pscustomobject]@{
            RecordPath = [string]$rollback.RecordPath
            RegistryPath = [string]$rollback.RegistryPath
            ValueName = $recordValue
            SourceAction = $recordAction
            ChangesExecuted = [bool]$rollback.RestoreAttempted
            RestoreAttempted = [bool]$rollback.RestoreAttempted
            DefaultIsRestore = $false
            Errors = @($rollback.Errors)
        }) `
        -VerificationResult $verification `
        -ChangesExecuted:([bool]$rollback.RestoreAttempted) `
        -Errors @($rollback.Errors)
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
        ImplementedActions = @($script:BoostLabImplementedActions)
        Capabilities = $script:BoostLabToolMetadata['Capabilities']
        ConfirmationRequiredActions = @('Apply', 'Default', 'Restore')
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        Supported = $true
        Reason = 'Updates Drivers Block supports the shared Windows live Driver Updates policy branch. Bootable-media and broad Updates branches remain unsupported.'
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        Current = 'ControlledPolicy'
        Source = Get-BoostLabUpdatesDriversSourceStatus
        SupportedRegistryValues = @(Get-BoostLabUpdatesDriversPolicyEntries)
        UnsupportedSourceBranches = @($script:BoostLabUnsupportedSourceBranches)
        ImplementedActions = @($script:BoostLabImplementedActions)
    }
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Analyze', 'Apply', 'Default', 'Restore')]
        [string]$ActionName,

        [bool]$Confirmed = $false,

        [string]$SelectedCapturePath = '',

        [AllowNull()]
        [scriptblock]$AdministratorChecker = $null,

        [AllowNull()]
        [scriptblock]$RegistryReader = $null,

        [AllowNull()]
        [scriptblock]$RegistryWriter = $null,

        [AllowNull()]
        [scriptblock]$RegistryRemover = $null,

        [string]$StateRoot = (Get-BoostLabRollbackStateRoot)
    )

    switch ($ActionName) {
        'Analyze' {
            return Invoke-BoostLabUpdatesDriversAnalyze -RegistryReader $RegistryReader
        }
        'Apply' {
            return Invoke-BoostLabUpdatesDriversPolicyMutation `
                -ActionName 'Apply' `
                -Confirmed:$Confirmed `
                -AdministratorChecker $AdministratorChecker `
                -RegistryReader $RegistryReader `
                -RegistryWriter $RegistryWriter `
                -StateRoot $StateRoot
        }
        'Default' {
            return Invoke-BoostLabUpdatesDriversPolicyMutation `
                -ActionName 'Default' `
                -Confirmed:$Confirmed `
                -AdministratorChecker $AdministratorChecker `
                -RegistryReader $RegistryReader `
                -RegistryRemover $RegistryRemover `
                -StateRoot $StateRoot
        }
        'Restore' {
            return Invoke-BoostLabUpdatesDriversRestore `
                -Confirmed:$Confirmed `
                -SelectedCapturePath $SelectedCapturePath `
                -AdministratorChecker $AdministratorChecker `
                -RegistryReader $RegistryReader `
                -RegistryWriter $RegistryWriter `
                -RegistryRemover $RegistryRemover `
                -StateRoot $StateRoot
        }
    }
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed:$true
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
