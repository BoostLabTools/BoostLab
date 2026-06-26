Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $verificationModulePath -Scope Local -ErrorAction Stop
}
$sourceToleratedOutcomeModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\SourceToleratedOutcomes.psm1'
if (-not (Get-Command -Name 'New-BoostLabSourceToleratedOutcomeNote' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $sourceToleratedOutcomeModulePath -Scope Local -Force -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'network-adapter-power-savings-wake'; Title = 'Network Adapter Power Savings & Wake'; Stage = 'Windows'; Order = 18
    Type = 'action'; RiskLevel = 'medium'
    Description = 'Disable approved network adapter power-saving and wake values or restore their default absent state.'
    Actions = @('Apply', 'Default')
    Capabilities = [ordered]@{
        RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false
        CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false
        CanDownload = $false; CanModifyDrivers = $true; CanModifySecurity = $false
        CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false
        SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Apply', 'Default')
$script:BoostLabAdapterClassPath = 'HKLM:\System\ControlSet001\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}'
$script:BoostLabAdapterClassSubPath = 'System\ControlSet001\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}'
$script:BoostLabAdapterClassRegistryPath = 'HKEY_LOCAL_MACHINE\System\ControlSet001\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}'
$script:BoostLabAdapterValueDefinitions = @(
    [pscustomobject]@{ Name = 'PnPCapabilities'; Type = 'REG_DWORD'; Data = '24' }
    [pscustomobject]@{ Name = 'AdvancedEEE'; Type = 'REG_SZ'; Data = '0' }
    [pscustomobject]@{ Name = '*EEE'; Type = 'REG_SZ'; Data = '0' }
    [pscustomobject]@{ Name = 'EEELinkAdvertisement'; Type = 'REG_SZ'; Data = '0' }
    [pscustomobject]@{ Name = 'SipsEnabled'; Type = 'REG_SZ'; Data = '0' }
    [pscustomobject]@{ Name = 'ULPMode'; Type = 'REG_SZ'; Data = '0' }
    [pscustomobject]@{ Name = 'GigaLite'; Type = 'REG_SZ'; Data = '0' }
    [pscustomobject]@{ Name = 'EnableGreenEthernet'; Type = 'REG_SZ'; Data = '0' }
    [pscustomobject]@{ Name = 'PowerSavingMode'; Type = 'REG_SZ'; Data = '0' }
    [pscustomobject]@{ Name = 'S5WakeOnLan'; Type = 'REG_SZ'; Data = '0' }
    [pscustomobject]@{ Name = '*WakeOnMagicPacket'; Type = 'REG_SZ'; Data = '0' }
    [pscustomobject]@{ Name = '*ModernStandbyWoLMagicPacket'; Type = 'REG_SZ'; Data = '0' }
    [pscustomobject]@{ Name = '*WakeOnPattern'; Type = 'REG_SZ'; Data = '0' }
    [pscustomobject]@{ Name = 'WakeOnLink'; Type = 'REG_SZ'; Data = '0' }
    # Ultimate repeats this exact command; preserve its execution order.
    [pscustomobject]@{ Name = '*ModernStandbyWoLMagicPacket'; Type = 'REG_SZ'; Data = '0' }
)

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

function New-BoostLabNetworkAdapterPowerWakeResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$Message,

        [bool]$Cancelled = $false,

        [AllowNull()]
        [object]$Data = $null,

        [AllowNull()]
        [object]$VerificationResult = $null
    )

    return [pscustomobject]@{
        Success            = $Success
        ToolId             = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle          = [string]$script:BoostLabToolMetadata['Title']
        Action             = $Action
        Message            = $Message
        RestartRequired    = $false
        Cancelled          = $Cancelled
        Timestamp          = Get-Date
        Data               = $Data
        VerificationResult = $VerificationResult
    }
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
        [string]$OperatingSystem = $env:OS,

        [string]$SystemRoot = $env:SystemRoot
    )

    $supported = ($OperatingSystem -eq 'Windows_NT')

    return [pscustomobject]@{
        Supported = $supported
        ToolId    = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason    = if ($OperatingSystem -ne 'Windows_NT') {
            'Network Adapter Power Savings & Wake requires Windows.'
        }
        else { 'Windows network adapter class registry support is available.' }
        Timestamp = Get-Date
    }
}

function Get-BoostLabNetworkAdapterReadOnlyDiscovery {
    $adapters = [System.Collections.Generic.List[object]]::new()
    $inaccessibleTargets = [System.Collections.Generic.List[object]]::new()
    $localMachine = $null
    $classKey = $null

    try {
        $localMachine = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
            [Microsoft.Win32.RegistryHive]::LocalMachine,
            [Microsoft.Win32.RegistryView]::Default
        )
        $classKey = $localMachine.OpenSubKey($script:BoostLabAdapterClassSubPath, $false)
        if ($null -eq $classKey) {
            return [pscustomobject]@{
                Succeeded           = $true
                EnumerationStatus   = 'Warning'
                Adapters            = @()
                InaccessibleTargets = @()
                Message             = 'The network adapter class registry key was not found.'
            }
        }

        foreach ($subKeyName in @($classKey.GetSubKeyNames())) {
            if ($subKeyName -notmatch '^\d{4}$') {
                continue
            }

            $adapterKey = $null
            $registrySubPath = '{0}\{1}' -f $script:BoostLabAdapterClassSubPath, $subKeyName
            $registryPath = '{0}\{1}' -f $script:BoostLabAdapterClassRegistryPath, $subKeyName
            try {
                # Discovery is read-only. A protected adapter key is reported and skipped.
                $adapterKey = $classKey.OpenSubKey($subKeyName, $false)
                if ($null -eq $adapterKey) {
                    $inaccessibleTargets.Add(
                        [pscustomobject]@{
                            Target  = $registryPath
                            Message = 'The adapter registry key could not be opened read-only.'
                        }
                    )
                    continue
                }

                $adapterName = [string]$adapterKey.GetValue(
                    'DriverDesc',
                    $subKeyName,
                    [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
                )
                if ([string]::IsNullOrWhiteSpace($adapterName)) {
                    $adapterName = $subKeyName
                }

                $adapters.Add(
                    [pscustomobject]@{
                        AdapterName   = $adapterName
                        AdapterKey    = $subKeyName
                        RegistryPath  = $registryPath
                        ProviderPath  = "Registry::$registryPath"
                        RegistrySubPath = $registrySubPath
                    }
                )
            }
            catch {
                $inaccessibleTargets.Add(
                    [pscustomobject]@{
                        Target  = $registryPath
                        Message = $_.Exception.Message
                    }
                )
            }
            finally {
                if ($null -ne $adapterKey) {
                    $adapterKey.Dispose()
                }
            }
        }

        $enumerationStatus = if ($inaccessibleTargets.Count -gt 0 -or $adapters.Count -eq 0) {
            'Warning'
        }
        else {
            'Completed'
        }
        $message = if ($adapters.Count -eq 0 -and $inaccessibleTargets.Count -gt 0) {
            'No adapter keys could be safely opened; protected targets were reported.'
        }
        elseif ($adapters.Count -eq 0) {
            'No matching network adapter registry keys were found.'
        }
        elseif ($inaccessibleTargets.Count -gt 0) {
            '{0} adapter key(s) detected; {1} protected key(s) were skipped.' -f `
                $adapters.Count, `
                $inaccessibleTargets.Count
        }
        else {
            '{0} network adapter registry key(s) detected.' -f $adapters.Count
        }

        return [pscustomobject]@{
            Succeeded           = $true
            EnumerationStatus   = $enumerationStatus
            Adapters            = $adapters.ToArray()
            InaccessibleTargets = $inaccessibleTargets.ToArray()
            Message             = $message
        }
    }
    catch {
        return [pscustomobject]@{
            Succeeded           = $false
            EnumerationStatus   = 'Failed'
            Adapters            = @()
            InaccessibleTargets = @(
                [pscustomobject]@{
                    Target  = $script:BoostLabAdapterClassRegistryPath
                    Message = $_.Exception.Message
                }
            )
            Message             = "Network adapter read-only enumeration failed: $($_.Exception.Message)"
        }
    }
    finally {
        if ($null -ne $classKey) {
            $classKey.Dispose()
        }
        if ($null -ne $localMachine) {
            $localMachine.Dispose()
        }
    }
}

function Get-BoostLabNetworkAdapterInventory {
    param(
        [scriptblock]$RegistryDiscovery = {
            Get-BoostLabNetworkAdapterReadOnlyDiscovery
        }
    )

    try {
        $discoveryResults = @(& $RegistryDiscovery)
        if ($discoveryResults.Count -eq 0 -or $null -eq $discoveryResults[0]) {
            throw 'Read-only registry discovery returned no result.'
        }

        $discovery = $discoveryResults[0]
        return [pscustomobject]@{
            Succeeded           = [bool]$discovery.Succeeded
            EnumerationStatus   = [string]$discovery.EnumerationStatus
            Adapters            = @($discovery.Adapters)
            InaccessibleTargets = @($discovery.InaccessibleTargets)
            Message             = [string]$discovery.Message
        }
    }
    catch {
        return [pscustomobject]@{
            Succeeded           = $false
            EnumerationStatus   = 'Failed'
            Adapters            = @()
            InaccessibleTargets = @(
                [pscustomobject]@{
                    Target  = $script:BoostLabAdapterClassRegistryPath
                    Message = $_.Exception.Message
                }
            )
            Message             = "Network adapter read-only enumeration failed: $($_.Exception.Message)"
        }
    }
}

function Get-BoostLabNetworkAdapterRegistryValue {
    param(
        [Parameter(Mandatory)]
        [string]$RegistrySubPath,

        [Parameter(Mandatory)]
        [string]$Name
    )

    $localMachine = $null
    $adapterKey = $null
    try {
        $localMachine = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
            [Microsoft.Win32.RegistryHive]::LocalMachine,
            [Microsoft.Win32.RegistryView]::Default
        )
        # Verification is read-only and never requests write access.
        $adapterKey = $localMachine.OpenSubKey($RegistrySubPath, $false)
        if ($null -eq $adapterKey) {
            return [pscustomobject]@{
                ReadSucceeded = $true
                Exists        = $false
                Value         = $null
                DisplayValue  = 'Absent'
                Message       = 'Adapter registry key is absent.'
            }
        }

        $valueNames = @($adapterKey.GetValueNames())
        if ($Name -notin $valueNames) {
            return [pscustomobject]@{
                ReadSucceeded = $true
                Exists        = $false
                Value         = $null
                DisplayValue  = 'Absent'
                Message       = 'Adapter property is absent or unsupported.'
            }
        }

        $value = $adapterKey.GetValue(
            $Name,
            $null,
            [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
        )
        return [pscustomobject]@{
            ReadSucceeded = $true
            Exists        = $true
            Value         = $value
            DisplayValue  = [string]$value
            Message       = 'Adapter property detected through read-only registry access.'
        }
    }
    catch {
        return [pscustomobject]@{
            ReadSucceeded = $false
            Exists        = $false
            Value         = $null
            DisplayValue  = 'Unknown'
            Message       = $_.Exception.Message
        }
    }
    finally {
        if ($null -ne $adapterKey) {
            $adapterKey.Dispose()
        }
        if ($null -ne $localMachine) {
            $localMachine.Dispose()
        }
    }
}

function Test-BoostLabNetworkAdapterRegistryTarget {
    param(
        [Parameter(Mandatory)]
        [object]$Target
    )

    $registryPath = [string]$Target.RegistryPath
    $registrySubPath = [string]$Target.RegistrySubPath
    $adapterKey = [string]$Target.AdapterKey
    $expectedRegistryPrefix = '{0}\' -f $script:BoostLabAdapterClassRegistryPath
    $expectedSubPathPrefix = '{0}\' -f $script:BoostLabAdapterClassSubPath

    return (
        $adapterKey -match '^\d{4}$' -and
        $registryPath.StartsWith($expectedRegistryPrefix, [StringComparison]::OrdinalIgnoreCase) -and
        $registrySubPath.StartsWith($expectedSubPathPrefix, [StringComparison]::OrdinalIgnoreCase) -and
        $registryPath.EndsWith("\$adapterKey", [StringComparison]::OrdinalIgnoreCase) -and
        $registrySubPath.EndsWith("\$adapterKey", [StringComparison]::OrdinalIgnoreCase)
    )
}

function ConvertTo-BoostLabNetworkAdapterExpectedRegistryValue {
    param(
        [Parameter(Mandatory)]
        [object]$Operation
    )

    switch ([string]$Operation.Type) {
        'REG_DWORD' {
            return [int]([string]$Operation.Data)
        }
        'REG_SZ' {
            return [string]$Operation.Data
        }
        default {
            throw "Unsupported registry value type: $([string]$Operation.Type)"
        }
    }
}

function Test-BoostLabNetworkAdapterRegistryValueMatches {
    param(
        [AllowNull()]
        [object]$ActualValue,

        [AllowNull()]
        [object]$ExpectedValue
    )

    return ([string]$ActualValue -eq [string]$ExpectedValue)
}

function Test-BoostLabNetworkAdapterInaccessibleRegistryError {
    param(
        [AllowNull()]
        [object]$Exception
    )

    $cursor = $Exception
    while ($null -ne $cursor) {
        if (
            $cursor -is [UnauthorizedAccessException] -or
            $cursor -is [System.Security.SecurityException]
        ) {
            return $true
        }

        $message = [string]$cursor.Message
        if (
            $message -match 'access is denied' -or
            $message -match 'Requested registry access is not allowed' -or
            $message -match 'UnauthorizedAccessException'
        ) {
            return $true
        }

        $cursor = $cursor.InnerException
    }

    return $false
}

function New-BoostLabNetworkAdapterRegistryOperationResult {
    param(
        [Parameter(Mandatory)]
        [object]$Operation,

        [Parameter(Mandatory)]
        [ValidateSet('Changed', 'AlreadyCorrect', 'Unsupported', 'Inaccessible', 'Failed')]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Message
    )

    $description = '{0} | {1}\{2}' -f `
        [string]$Operation.AdapterName, `
        [string]$Operation.RegistryPath, `
        [string]$Operation.Name

    return [pscustomobject]@{
        AdapterName = [string]$Operation.AdapterName
        AdapterKey = [string]$Operation.AdapterKey
        RegistryPath = [string]$Operation.RegistryPath
        RegistrySubPath = [string]$Operation.RegistrySubPath
        Name = [string]$Operation.Name
        Type = [string]$Operation.Type
        Data = [string]$Operation.Data
        Status = $Status
        Description = $description
        Message = $Message
    }
}

function Invoke-BoostLabNetworkAdapterRegistryOperation {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [Parameter(Mandatory)]
        [object]$Operation,

        [scriptblock]$RegistryReader = {
            param($RegistrySubPath, $Name)
            Get-BoostLabNetworkAdapterRegistryValue -RegistrySubPath $RegistrySubPath -Name $Name
        }
    )

    if (-not (Test-BoostLabNetworkAdapterRegistryTarget -Target $Operation)) {
        return New-BoostLabNetworkAdapterRegistryOperationResult `
            -Operation $Operation `
            -Status 'Failed' `
            -Message "Rejected out-of-scope adapter registry target: $([string]$Operation.RegistryPath)"
    }

    $existingState = $null
    try {
        $stateResults = @(& $RegistryReader ([string]$Operation.RegistrySubPath) ([string]$Operation.Name))
        if ($stateResults.Count -gt 0) {
            $existingState = $stateResults[0]
        }
    }
    catch {
        $existingState = [pscustomobject]@{
            ReadSucceeded = $false
            Exists = $false
            Value = $null
            DisplayValue = 'Unknown'
            Message = $_.Exception.Message
        }
    }

    $readSucceeded = (
        $null -ne $existingState -and
        $null -ne $existingState.PSObject.Properties['ReadSucceeded'] -and
        [bool]$existingState.ReadSucceeded
    )
    $exists = (
        $readSucceeded -and
        $null -ne $existingState.PSObject.Properties['Exists'] -and
        [bool]$existingState.Exists
    )

    if ($ActionName -eq 'Apply') {
        $expectedValue = ConvertTo-BoostLabNetworkAdapterExpectedRegistryValue -Operation $Operation
        if (
            $exists -and
            (Test-BoostLabNetworkAdapterRegistryValueMatches -ActualValue $existingState.Value -ExpectedValue $expectedValue)
        ) {
            return New-BoostLabNetworkAdapterRegistryOperationResult `
                -Operation $Operation `
                -Status 'AlreadyCorrect' `
                -Message 'Adapter registry value was already source-correct.'
        }
    }
    elseif ($readSucceeded -and -not $exists) {
        return New-BoostLabNetworkAdapterRegistryOperationResult `
            -Operation $Operation `
            -Status 'AlreadyCorrect' `
            -Message 'Adapter registry value was already absent.'
    }

    $localMachine = $null
    $adapterKey = $null
    try {
        $localMachine = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
            [Microsoft.Win32.RegistryHive]::LocalMachine,
            [Microsoft.Win32.RegistryView]::Default
        )
        $adapterKey = $localMachine.OpenSubKey([string]$Operation.RegistrySubPath, $true)
        if ($null -eq $adapterKey) {
            $status = if ($ActionName -eq 'Default') { 'AlreadyCorrect' } else { 'Inaccessible' }
            $message = if ($ActionName -eq 'Default') {
                'Adapter registry key was absent before Default value removal.'
            }
            else {
                'Adapter registry key was not available for write access.'
            }
            return New-BoostLabNetworkAdapterRegistryOperationResult `
                -Operation $Operation `
                -Status $status `
                -Message $message
        }

        if ($ActionName -eq 'Apply') {
            $valueKind = switch ([string]$Operation.Type) {
                'REG_DWORD' { [Microsoft.Win32.RegistryValueKind]::DWord }
                'REG_SZ' { [Microsoft.Win32.RegistryValueKind]::String }
                default { throw "Unsupported registry value type: $([string]$Operation.Type)" }
            }
            $adapterKey.SetValue(
                [string]$Operation.Name,
                (ConvertTo-BoostLabNetworkAdapterExpectedRegistryValue -Operation $Operation),
                $valueKind
            )
            return New-BoostLabNetworkAdapterRegistryOperationResult `
                -Operation $Operation `
                -Status 'Changed' `
                -Message 'Adapter registry value was written with native registry access.'
        }

        $adapterKey.DeleteValue([string]$Operation.Name, $false)
        return New-BoostLabNetworkAdapterRegistryOperationResult `
            -Operation $Operation `
            -Status 'Changed' `
            -Message 'Adapter registry value was removed with native registry access.'
    }
    catch {
        $status = if (Test-BoostLabNetworkAdapterInaccessibleRegistryError -Exception $_.Exception) {
            'Inaccessible'
        }
        else {
            'Failed'
        }
        return New-BoostLabNetworkAdapterRegistryOperationResult `
            -Operation $Operation `
            -Status $status `
            -Message $_.Exception.Message
    }
    finally {
        if ($null -ne $adapterKey) {
            $adapterKey.Dispose()
        }
        if ($null -ne $localMachine) {
            $localMachine.Dispose()
        }
    }
}

function New-BoostLabNetworkAdapterRegistryOperations {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [Parameter(Mandatory)]
        [object]$Adapter
    )

    if (-not (Test-BoostLabNetworkAdapterRegistryTarget -Target $Adapter)) {
        throw "Rejected out-of-scope network adapter registry target: $([string]$Adapter.RegistryPath)"
    }

    return @(
        foreach ($definition in $script:BoostLabAdapterValueDefinitions) {
            $command = if ($ActionName -eq 'Apply') {
                'reg add "{0}" /v "{1}" /t {2} /d "{3}" /f' -f `
                    [string]$Adapter.RegistryPath, `
                    [string]$definition.Name, `
                    [string]$definition.Type, `
                    [string]$definition.Data
            }
            else {
                'reg delete "{0}" /v "{1}" /f' -f `
                    [string]$Adapter.RegistryPath, `
                    [string]$definition.Name
            }

            [pscustomobject]@{
                AdapterName = [string]$Adapter.AdapterName
                AdapterKey  = [string]$Adapter.AdapterKey
                RegistryPath = [string]$Adapter.RegistryPath
                ProviderPath = [string]$Adapter.ProviderPath
                RegistrySubPath = [string]$Adapter.RegistrySubPath
                Name         = [string]$definition.Name
                Type         = [string]$definition.Type
                Data         = [string]$definition.Data
                Command      = $command
            }
        }
    )
}

function Test-BoostLabNetworkAdapterPowerWakeState {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [AllowNull()]
        [object]$AdapterInventory = $null,

        [scriptblock]$AdapterEnumerator = {
            Get-BoostLabNetworkAdapterInventory
        },

        [scriptblock]$RegistryReader = {
            param($RegistrySubPath, $Name)
            Get-BoostLabNetworkAdapterRegistryValue -RegistrySubPath $RegistrySubPath -Name $Name
        },

        [AllowNull()]
        [object[]]$RegistryOperationResults = @()
    )

    $inventory = if ($null -ne $AdapterInventory) {
        $AdapterInventory
    }
    else {
        $inventoryResults = @(& $AdapterEnumerator)
        if ($inventoryResults.Count -gt 0) { $inventoryResults[0] } else { $null }
    }
    $checks = [System.Collections.Generic.List[object]]::new()
    $expectedSummary = if ($ActionName -eq 'Apply') {
        '14 source-defined adapter power and wake values set to the approved recommended state'
    }
    else {
        '14 source-defined adapter power and wake values absent'
    }

    if (
        $null -eq $inventory -or
        $null -eq $inventory.PSObject.Properties['Succeeded'] -or
        -not [bool]$inventory.Succeeded
    ) {
        $message = if ($null -ne $inventory -and $null -ne $inventory.PSObject.Properties['Message']) {
            [string]$inventory.Message
        }
        else {
            'Network adapter inventory was unavailable.'
        }
        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name 'Network adapter enumeration' `
                -Expected 'One or more network adapter class keys' `
                -Actual 'Unavailable' `
                -Status 'Warning' `
                -Message $message)
        )
    }
    elseif (@($inventory.Adapters).Count -eq 0) {
        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name 'Network adapter enumeration' `
                -Expected 'One or more network adapter class keys' `
                -Actual 'None found' `
                -Status 'Warning' `
                -Message ([string]$inventory.Message))
        )
        foreach ($inaccessibleTarget in @($inventory.InaccessibleTargets)) {
            $checks.Add(
                (New-BoostLabVerificationCheck `
                    -Name ('Adapter enumeration access | {0}' -f [string]$inaccessibleTarget.Target) `
                    -Expected 'Read-only access' `
                    -Actual 'Inaccessible' `
                    -Status 'Warning' `
                    -Message ([string]$inaccessibleTarget.Message))
            )
        }
    }
    else {
        foreach ($inaccessibleTarget in @($inventory.InaccessibleTargets)) {
            $checks.Add(
                (New-BoostLabVerificationCheck `
                    -Name ('Adapter enumeration access | {0}' -f [string]$inaccessibleTarget.Target) `
                    -Expected 'Read-only access' `
                    -Actual 'Inaccessible' `
                    -Status 'Warning' `
                    -Message ([string]$inaccessibleTarget.Message))
            )
        }

        $uniqueDefinitions = @(
            $script:BoostLabAdapterValueDefinitions |
                Group-Object -Property Name |
                ForEach-Object { $_.Group[0] }
        )
        $operationResultMap = @{}
        foreach ($operationResult in @($RegistryOperationResults)) {
            if ($null -eq $operationResult) {
                continue
            }
            $key = '{0}|{1}|{2}' -f `
                [string]$operationResult.AdapterKey, `
                [string]$operationResult.RegistrySubPath, `
                [string]$operationResult.Name
            $operationResultMap[$key.ToLowerInvariant()] = $operationResult
        }

        foreach ($adapter in @($inventory.Adapters)) {
            foreach ($definition in $uniqueDefinitions) {
                $operationKey = ('{0}|{1}|{2}' -f `
                    [string]$adapter.AdapterKey, `
                    [string]$adapter.RegistrySubPath, `
                    [string]$definition.Name).ToLowerInvariant()
                $operationResult = if ($operationResultMap.ContainsKey($operationKey)) {
                    $operationResultMap[$operationKey]
                }
                else {
                    $null
                }
                if (
                    $null -ne $operationResult -and
                    [string]$operationResult.Status -eq 'AlreadyCorrect'
                ) {
                    $checks.Add(
                        (New-BoostLabVerificationCheck `
                            -Name ('{0} | {1}\{2}' -f `
                                [string]$adapter.AdapterName, `
                                [string]$adapter.RegistryPath, `
                                [string]$definition.Name) `
                            -Expected $(if ($ActionName -eq 'Apply') {
                                '{0} ({1})' -f [string]$definition.Data, [string]$definition.Type
                            } else {
                                'Absent'
                            }) `
                            -Actual $(if ($ActionName -eq 'Apply') {
                                '{0} ({1})' -f [string]$definition.Data, [string]$definition.Type
                            } else {
                                'Absent'
                            }) `
                            -Status 'Passed' `
                            -Message ([string]$operationResult.Message))
                    )
                    continue
                }
                if (
                    $null -ne $operationResult -and
                    [string]$operationResult.Status -in @('Unsupported', 'Inaccessible', 'Failed')
                ) {
                    $checks.Add(
                        (New-BoostLabVerificationCheck `
                            -Name ('{0} | {1}\{2}' -f `
                                [string]$adapter.AdapterName, `
                                [string]$adapter.RegistryPath, `
                                [string]$definition.Name) `
                            -Expected $(if ($ActionName -eq 'Apply') {
                                '{0} ({1})' -f [string]$definition.Data, [string]$definition.Type
                            } else {
                                'Absent'
                            }) `
                            -Actual ([string]$operationResult.Status) `
                            -Status $(if ([string]$operationResult.Status -eq 'Failed') { 'Failed' } else { 'Warning' }) `
                            -Message ([string]$operationResult.Message))
                    )
                    continue
                }

                try {
                    $stateResults = @(& $RegistryReader ([string]$adapter.RegistrySubPath) ([string]$definition.Name))
                    $state = if ($stateResults.Count -gt 0) { $stateResults[0] } else { $null }
                }
                catch {
                    $state = $null
                }

                $readSucceeded = (
                    $null -ne $state -and
                    $null -ne $state.PSObject.Properties['ReadSucceeded'] -and
                    [bool]$state.ReadSucceeded
                )
                $exists = (
                    $readSucceeded -and
                    $null -ne $state.PSObject.Properties['Exists'] -and
                    [bool]$state.Exists
                )
                $actual = if (
                    $null -ne $state -and
                    $null -ne $state.PSObject.Properties['DisplayValue']
                ) {
                    [string]$state.DisplayValue
                }
                else {
                    'Unknown'
                }
                $stateMessage = if (
                    $null -ne $state -and
                    $null -ne $state.PSObject.Properties['Message']
                ) {
                    [string]$state.Message
                }
                else {
                    'Adapter property could not be read.'
                }
                $status = if (-not $readSucceeded) {
                    'Warning'
                }
                elseif ($ActionName -eq 'Apply' -and -not $exists) {
                    'Warning'
                }
                elseif (
                    $ActionName -eq 'Apply' -and
                    [string]$state.Value -eq [string]$definition.Data
                ) {
                    'Passed'
                }
                elseif ($ActionName -eq 'Default' -and -not $exists) {
                    'Passed'
                }
                else {
                    'Failed'
                }
                $expected = if ($ActionName -eq 'Apply') {
                    '{0} ({1})' -f [string]$definition.Data, [string]$definition.Type
                }
                else {
                    'Absent'
                }

                $checks.Add(
                    (New-BoostLabVerificationCheck `
                        -Name ('{0} | {1}\{2}' -f `
                            [string]$adapter.AdapterName, `
                            [string]$adapter.RegistryPath, `
                            [string]$definition.Name) `
                        -Expected $expected `
                        -Actual $actual `
                        -Status $status `
                        -Message $stateMessage)
                )
            }
        }
    }

    $failedCount = @($checks | Where-Object { $_.Status -eq 'Failed' }).Count
    $warningCount = @($checks | Where-Object { $_.Status -eq 'Warning' }).Count
    $passedCount = @($checks | Where-Object { $_.Status -eq 'Passed' }).Count
    $overallStatus = if ($failedCount -gt 0) {
        'Failed'
    }
    elseif ($warningCount -gt 0) {
        'Warning'
    }
    else {
        'Passed'
    }
    $inaccessibleCount = if (
        $null -ne $inventory -and
        $null -ne $inventory.PSObject.Properties['InaccessibleTargets']
    ) {
        @($inventory.InaccessibleTargets).Count
    }
    else {
        0
    }
    $detectedSummary = '{0} passed, {1} warning, {2} failed across {3} accessible adapter(s); {4} inaccessible target(s)' -f `
        $passedCount, `
        $warningCount, `
        $failedCount, `
        $(if ($null -ne $inventory) { @($inventory.Adapters).Count } else { 0 }), `
        $inaccessibleCount
    $message = switch ($overallStatus) {
        'Passed' { 'The expected network adapter power and wake state was detected.' }
        'Warning' { 'The command completed, but one or more adapter values were unavailable, unsupported, or require device refresh.' }
        default { 'One or more detected adapter values contradict the expected network adapter power and wake state.' }
    }

    return New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $ActionName `
        -Status $overallStatus `
        -ExpectedState ([pscustomobject]@{ AdapterPowerWake = $expectedSummary }) `
        -DetectedState ([pscustomobject]@{ AdapterPowerWake = $detectedSummary }) `
        -Checks $checks.ToArray() `
        -Message $message
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $inventory = Get-BoostLabNetworkAdapterInventory
    return [pscustomobject]@{
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        Status          = if ($inventory.Succeeded) {
            '{0} adapter registry key(s) detected' -f @($inventory.Adapters).Count
        }
        else {
            'Adapter inventory unavailable'
        }
        AdapterNames    = @($inventory.Adapters | ForEach-Object { $_.AdapterName })
        InaccessibleTargets = @($inventory.InaccessibleTargets | ForEach-Object { $_.Target })
        LastAction      = $null
        LastResult      = $null
        RestartRequired = $false
        Timestamp       = Get-Date
    }
}

function Invoke-BoostLabNetworkAdapterPowerWakeAction {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [scriptblock]$AdministratorChecker = {
            Test-BoostLabAdministrator
        },

        [scriptblock]$AdapterEnumerator = {
            Get-BoostLabNetworkAdapterInventory
        },

        [scriptblock]$RegistryReader = {
            param($RegistrySubPath, $Name)
            Get-BoostLabNetworkAdapterRegistryValue -RegistrySubPath $RegistrySubPath -Name $Name
        },

        [scriptblock]$RegistryCommandInvoker = {
            param($CommandText, $Operation, $Action, $Reader)
            Invoke-BoostLabNetworkAdapterRegistryOperation `
                -ActionName $Action `
                -Operation $Operation `
                -RegistryReader $Reader
        }
    )

    if (-not [bool](& $AdministratorChecker)) {
        return New-BoostLabNetworkAdapterPowerWakeResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Administrator rights are required to change network adapter power and wake values.'
    }

    $inventoryResults = @(& $AdapterEnumerator)
    $inventory = if ($inventoryResults.Count -gt 0) { $inventoryResults[0] } else { $null }
    if ($null -eq $inventory) {
        $inventory = [pscustomobject]@{
            Succeeded           = $false
            EnumerationStatus   = 'Failed'
            Adapters            = @()
            InaccessibleTargets = @(
                [pscustomobject]@{
                    Target  = $script:BoostLabAdapterClassRegistryPath
                    Message = 'Network adapter enumeration returned no result.'
                }
            )
            Message             = 'Network adapter enumeration returned no result.'
        }
    }

    $adapterNames = @($inventory.Adapters | ForEach-Object { [string]$_.AdapterName })
    $inaccessibleTargets = @(
        $inventory.InaccessibleTargets |
            ForEach-Object {
                '{0}: {1}' -f [string]$_.Target, [string]$_.Message
            }
    )
    $registryOperationsAttempted = [System.Collections.Generic.List[string]]::new()
    $registryOperationResults = [System.Collections.Generic.List[object]]::new()
    $registryOperationsSkipped = [System.Collections.Generic.List[string]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()

    foreach ($adapter in @($inventory.Adapters)) {
        foreach ($operation in @(New-BoostLabNetworkAdapterRegistryOperations -ActionName $ActionName -Adapter $adapter)) {
            $operationDescription = '{0}: {1}' -f `
                [string]$operation.AdapterName, `
                [string]$operation.Name
            $registryOperationsAttempted.Add($operationDescription)
            try {
                $invokerResults = @(& $RegistryCommandInvoker ([string]$operation.Command) $operation $ActionName $RegistryReader)
                $operationResult = if (
                    $invokerResults.Count -gt 0 -and
                    $null -ne $invokerResults[0] -and
                    $null -ne $invokerResults[0].PSObject.Properties['Status']
                ) {
                    $invokerResults[0]
                }
                else {
                    New-BoostLabNetworkAdapterRegistryOperationResult `
                        -Operation $operation `
                        -Status 'Changed' `
                        -Message 'Adapter registry command completed.'
                }
                $registryOperationResults.Add($operationResult)
            }
            catch {
                $status = if (Test-BoostLabNetworkAdapterInaccessibleRegistryError -Exception $_.Exception) {
                    'Inaccessible'
                }
                else {
                    'Failed'
                }
                $registryOperationResults.Add(
                    (New-BoostLabNetworkAdapterRegistryOperationResult `
                        -Operation $operation `
                        -Status $status `
                        -Message $_.Exception.Message)
                )
            }
        }
    }

    $verificationResult = Test-BoostLabNetworkAdapterPowerWakeState `
        -ActionName $ActionName `
        -AdapterInventory $inventory `
        -RegistryReader $RegistryReader `
        -RegistryOperationResults $registryOperationResults.ToArray()
    $changedResults = @($registryOperationResults | Where-Object { [string]$_.Status -eq 'Changed' })
    $alreadyCorrectResults = @($registryOperationResults | Where-Object { [string]$_.Status -eq 'AlreadyCorrect' })
    $unsupportedResults = @($registryOperationResults | Where-Object { [string]$_.Status -eq 'Unsupported' })
    $inaccessibleResults = @($registryOperationResults | Where-Object { [string]$_.Status -eq 'Inaccessible' })
    $failedResults = @($registryOperationResults | Where-Object { [string]$_.Status -eq 'Failed' })
    $completedAt = Get-Date
    $expectedState = [string]$verificationResult.ExpectedState.AdapterPowerWake
    $detectedState = [string]$verificationResult.DetectedState.AdapterPowerWake
    $sampleLimit = 10
    $unsupportedSamples = @(
        $unsupportedResults |
            Select-Object -First $sampleLimit |
            ForEach-Object { '{0}: {1}' -f [string]$_.Description, [string]$_.Message }
    )
    $inaccessibleSamples = @(
        $inaccessibleResults |
            Select-Object -First $sampleLimit |
            ForEach-Object { '{0}: {1}' -f [string]$_.Description, [string]$_.Message }
    )
    $failedSamples = @(
        $failedResults |
            Select-Object -First $sampleLimit |
            ForEach-Object { '{0}: {1}' -f [string]$_.Description, [string]$_.Message }
    )
    $operationWarningNames = @(
        @($unsupportedResults + $inaccessibleResults) |
            ForEach-Object { [string]$_.Description }
    )
    $verificationWarningProperties = @(
        $verificationResult.Checks |
            Where-Object {
                [string]$_.Status -eq 'Warning' -and
                [string]$_.Name -notlike 'Adapter enumeration access*' -and
                [string]$_.Name -notin $operationWarningNames
            } |
            ForEach-Object { [string]$_.Name }
    )
    $sourceToleratedUnsupportedOnly = (
        @($inventory.Adapters).Count -gt 0 -and
        $unsupportedResults.Count + $verificationWarningProperties.Count -gt 0 -and
        $inaccessibleResults.Count -eq 0 -and
        @($inventory.InaccessibleTargets).Count -eq 0 -and
        $failedResults.Count -eq 0 -and
        $errors.Count -eq 0 -and
        [string]$verificationResult.Status -eq 'Warning'
    )
    $informationalNotes = [System.Collections.Generic.List[object]]::new()
    if ($sourceToleratedUnsupportedOnly) {
        foreach ($sample in @($unsupportedSamples + $verificationWarningProperties | Select-Object -First $sampleLimit)) {
            $informationalNotes.Add(
                (New-BoostLabSourceToleratedOutcomeNote `
                    -ToolId 'network-adapter-power-savings-wake' `
                    -ReasonCode 'HardwareSpecificUnsupportedSetting' `
                    -Message ([string]$sample) `
                    -Details ([pscustomobject]@{ Action = $ActionName }))
            )
        }
    }
    $effectiveVerification = $verificationResult
    if ($sourceToleratedUnsupportedOnly) {
        $effectiveVerification = [pscustomobject]@{
            ToolId        = [string]$verificationResult.ToolId
            ToolTitle     = [string]$verificationResult.ToolTitle
            Action        = [string]$verificationResult.Action
            Status        = 'Passed'
            ExpectedState = $verificationResult.ExpectedState
            DetectedState = $verificationResult.DetectedState
            Checks        = @($verificationResult.Checks)
            Message       = 'The expected network adapter state was detected where supported; hardware-specific unsupported properties were recorded as informational.'
            Timestamp     = $verificationResult.Timestamp
        }
    }
    foreach ($sample in @($failedSamples)) {
        $errors.Add($sample)
    }
    $registryValuesChecked = @(
        foreach ($adapter in @($inventory.Adapters)) {
            foreach ($definition in @(
                $script:BoostLabAdapterValueDefinitions |
                    Group-Object -Property Name |
                    ForEach-Object { $_.Group[0] }
            )) {
                '{0}\{1}' -f [string]$adapter.RegistryPath, [string]$definition.Name
            }
        }
    )
    $commandStatus = if (-not [bool]$inventory.Succeeded) {
        'Not executed: enumeration failed'
    }
    elseif (@($inventory.Adapters).Count -eq 0) {
        'Not executed: no accessible adapters'
    }
    elseif ($failedResults.Count -gt 0) {
        'Completed with errors'
    }
    elseif ($registryOperationsAttempted.Count -eq 0 -and $ActionName -eq 'Default') {
        'Already default'
    }
    elseif (
        $unsupportedResults.Count -gt 0 -or
        $inaccessibleResults.Count -gt 0 -or
        ([string]$effectiveVerification.Status -eq 'Warning')
    ) {
        if ($sourceToleratedUnsupportedOnly) { 'Completed' } else { 'Completed with warnings' }
    }
    else {
        'Completed'
    }
    $data = [pscustomobject]@{
        AdapterEnumerationStatus          = [string]$inventory.EnumerationStatus
        CommandStatus                    = $commandStatus
        VerificationStatus               = [string]$effectiveVerification.Status
        ExpectedAdapterPowerWakeState    = $expectedState
        DetectedAdapterPowerWakeState    = $detectedState
        AdapterNamesTargeted              = $adapterNames
        InaccessibleAdapterTargets        = $inaccessibleTargets
        RegistryValuesChecked             = $registryValuesChecked
        PropertiesAppliedOrDefaulted      = @($changedResults | ForEach-Object { [string]$_.Description })
        AlreadyCorrectProperties          = @($alreadyCorrectResults | ForEach-Object { [string]$_.Description })
        UnsupportedOrAbsentProperties     = @($unsupportedSamples + $verificationWarningProperties | Select-Object -First $sampleLimit)
        InaccessibleProperties            = $inaccessibleSamples
        FailedProperties                  = $failedSamples
        AdapterCount                      = @($inventory.Adapters).Count
        AttemptedCount                    = $registryOperationsAttempted.Count
        ChangedCount                      = $changedResults.Count
        AlreadyCorrectCount               = $alreadyCorrectResults.Count
        UnsupportedOrAbsentCount          = $unsupportedResults.Count + $verificationWarningProperties.Count
        InaccessibleCount                 = $inaccessibleResults.Count + @($inventory.InaccessibleTargets).Count
        FailedCount                       = $failedResults.Count
        InaccessibleOrUnsupportedProperties = @($unsupportedSamples + $inaccessibleSamples + $verificationWarningProperties | Select-Object -First $sampleLimit)
        Warnings                          = if ($sourceToleratedUnsupportedOnly) { @() } else { @($unsupportedSamples + $inaccessibleSamples + $verificationWarningProperties | Select-Object -First $sampleLimit) }
        InformationalNotes                = $informationalNotes.ToArray()
        ExpectedNoOpOutcomes              = $informationalNotes.ToArray()
        Errors                            = $errors.ToArray()
        RegistryOperationsAttempted       = $registryOperationsAttempted.ToArray()
        RegistryOperationsCompleted       = @($changedResults | ForEach-Object { [string]$_.Description })
        RegistryOperationsSkipped         = $registryOperationsSkipped.ToArray()
        RegistryOperationResultSummary    = [pscustomobject]@{
            AdapterCount = @($inventory.Adapters).Count
            Attempted = $registryOperationsAttempted.Count
            Changed = $changedResults.Count
            AlreadyCorrect = $alreadyCorrectResults.Count
            UnsupportedOrAbsent = $unsupportedResults.Count + $verificationWarningProperties.Count
            Inaccessible = $inaccessibleResults.Count + @($inventory.InaccessibleTargets).Count
            Failed = $failedResults.Count
            SampleLimit = $sampleLimit
        }
        CompletedAt                       = $completedAt
    }

    if (-not [bool]$inventory.Succeeded -or @($inventory.Adapters).Count -eq 0) {
        return New-BoostLabNetworkAdapterPowerWakeResult `
            -Success $false `
            -Action $ActionName `
            -Message ([string]$inventory.Message) `
            -Data $data `
            -VerificationResult $effectiveVerification
    }
    if ($failedResults.Count -gt 0) {
        return New-BoostLabNetworkAdapterPowerWakeResult `
            -Success $false `
            -Action $ActionName `
            -Message ('Network adapter power and wake action completed with {0} failed registry operation(s). Sample: {1}' -f $failedResults.Count, ($failedSamples -join '; ')) `
            -Data $data `
            -VerificationResult $effectiveVerification
    }
    if ($effectiveVerification.Status -eq 'Failed') {
        return New-BoostLabNetworkAdapterPowerWakeResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Network adapter power and wake commands completed, but verification detected an unexpected state.' `
            -Data $data `
            -VerificationResult $effectiveVerification
    }

    $message = if ($sourceToleratedUnsupportedOnly) {
        'Network adapter power savings and wake disabled where supported; unsupported hardware-specific properties were recorded in result details.'
    }
    elseif ($effectiveVerification.Status -eq 'Warning') {
        if ($inaccessibleTargets.Count -gt 0) {
            'Network adapter power and wake commands completed on accessible adapters; protected or unsupported targets were reported as warnings.'
        }
        else {
            'Network adapter power and wake commands completed with verification warnings.'
        }
    }
    elseif ($ActionName -eq 'Apply') {
        'Network adapter power savings and wake disabled.'
    }
    elseif ($registryOperationsAttempted.Count -eq 0) {
        'Network adapter power savings and wake already default.'
    }
    else {
        'Network adapter power savings and wake restored to default.'
    }

    return New-BoostLabNetworkAdapterPowerWakeResult `
        -Success $true `
        -Action $ActionName `
        -Message $message `
        -Data $data `
        -VerificationResult $effectiveVerification
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
        return New-BoostLabNetworkAdapterPowerWakeResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Unsupported action. Only Apply and Default are allowed.'
    }
    if (-not $Confirmed) {
        return New-BoostLabNetworkAdapterPowerWakeResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    return Invoke-BoostLabNetworkAdapterPowerWakeAction -ActionName $ActionName
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
