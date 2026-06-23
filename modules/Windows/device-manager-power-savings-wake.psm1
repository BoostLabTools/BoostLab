Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $verificationModulePath -Scope Local -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'device-manager-power-savings-wake'
    Title = 'Device Manager Power Savings & Wake'
    Stage = 'Windows'
    Order = 17
    Type = 'action'
    RiskLevel = 'medium'
    Description = 'Disable source-approved device power-saving and wake values or restore the Ultimate default value removals.'
    Actions = @('Apply', 'Default')
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
$script:BoostLabImplementedActions = @('Apply', 'Default')
$script:BoostLabDeviceClasses = @('ACPI', 'HID', 'PCI', 'USB')
$script:BoostLabEnumSubPath = 'SYSTEM\ControlSet001\Enum'
$script:BoostLabEnumRegistryPath = 'HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Enum'
$script:BoostLabDeviceParameterLeaf = 'Device Parameters'
$script:BoostLabWdfLeaf = 'WDF'

$script:BoostLabCommonPowerValues = @(
    [pscustomobject]@{ Name = 'EnhancedPowerManagementEnabled'; Type = 'REG_DWORD'; Data = '0' }
    [pscustomobject]@{ Name = 'SelectiveSuspendOn'; Type = 'REG_DWORD'; Data = '0' }
)
$script:BoostLabAcpiSelectiveSuspendValue = [pscustomobject]@{
    Name = 'SeleactiveSuspendEnabled'
    Type = 'REG_BINARY'
    Data = '00'
}
$script:BoostLabSelectiveSuspendValue = [pscustomobject]@{
    Name = 'SelectiveSuspendEnabled'
    Type = 'REG_BINARY'
    Data = '00'
}
$script:BoostLabIdleValue = [pscustomobject]@{
    Name = 'IdleInWorkingState'
    Type = 'REG_DWORD'
    Data = '0'
}
$script:BoostLabWakeValue = [pscustomobject]@{
    Name = 'WaitWakeEnabled'
    Type = 'REG_DWORD'
    Data = '0'
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

function New-BoostLabDeviceManagerPowerWakeResult {
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
        Success = $Success
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Action = $Action
        Message = $Message
        RestartRequired = $false
        Cancelled = $Cancelled
        Timestamp = Get-Date
        Data = $Data
        VerificationResult = $VerificationResult
    }
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
        Capabilities = [pscustomobject]$script:BoostLabToolMetadata['Capabilities']
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

    $commandProcessorPath = if ([string]::IsNullOrWhiteSpace($SystemRoot)) {
        ''
    }
    else {
        Join-Path $SystemRoot 'System32\cmd.exe'
    }
    $supported = (
        $OperatingSystem -eq 'Windows_NT' -and
        -not [string]::IsNullOrWhiteSpace($commandProcessorPath) -and
        (Test-Path -LiteralPath $commandProcessorPath -PathType Leaf)
    )

    return [pscustomobject]@{
        Supported = $supported
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason = if ($OperatingSystem -ne 'Windows_NT') {
            'Device Manager Power Savings & Wake requires Windows.'
        }
        elseif ([string]::IsNullOrWhiteSpace($commandProcessorPath)) {
            'The Windows system directory is unavailable.'
        }
        elseif (-not $supported) {
            'Device registry commands are unavailable because cmd.exe was not found.'
        }
        else {
            'Windows device enumeration registry support is available.'
        }
        Timestamp = Get-Date
    }
}

function Get-BoostLabDeviceManagerOperationBlueprint {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName
    )

    $blueprint = [System.Collections.Generic.List[object]]::new()
    foreach ($className in $script:BoostLabDeviceClasses) {
        $selectiveSuspendDefinition = if (
            $ActionName -eq 'Apply' -and
            $className -ne 'ACPI'
        ) {
            $script:BoostLabSelectiveSuspendValue
        }
        else {
            $script:BoostLabAcpiSelectiveSuspendValue
        }

        foreach ($definition in @(
            $script:BoostLabCommonPowerValues[0]
            $selectiveSuspendDefinition
            $script:BoostLabCommonPowerValues[1]
        )) {
            $blueprint.Add(
                [pscustomobject]@{
                    ClassName = $className
                    LeafName = $script:BoostLabDeviceParameterLeaf
                    Name = [string]$definition.Name
                    Type = [string]$definition.Type
                    Data = [string]$definition.Data
                }
            )
        }

        $blueprint.Add(
            [pscustomobject]@{
                ClassName = $className
                LeafName = $script:BoostLabWdfLeaf
                Name = [string]$script:BoostLabIdleValue.Name
                Type = [string]$script:BoostLabIdleValue.Type
                Data = [string]$script:BoostLabIdleValue.Data
            }
        )
    }

    foreach ($className in $script:BoostLabDeviceClasses) {
        $blueprint.Add(
            [pscustomobject]@{
                ClassName = $className
                LeafName = $script:BoostLabDeviceParameterLeaf
                Name = [string]$script:BoostLabWakeValue.Name
                Type = [string]$script:BoostLabWakeValue.Type
                Data = [string]$script:BoostLabWakeValue.Data
            }
        )
    }

    return $blueprint.ToArray()
}

function Test-BoostLabDeviceManagerRegistryTarget {
    param(
        [Parameter(Mandatory)]
        [object]$Target
    )

    $className = [string]$Target.ClassName
    $leafName = [string]$Target.LeafName
    $registryPath = [string]$Target.RegistryPath
    $registrySubPath = [string]$Target.RegistrySubPath
    $expectedRegistryPrefix = '{0}\{1}\' -f $script:BoostLabEnumRegistryPath, $className
    $expectedSubPathPrefix = '{0}\{1}\' -f $script:BoostLabEnumSubPath, $className

    return (
        $className -in $script:BoostLabDeviceClasses -and
        $leafName -in @($script:BoostLabDeviceParameterLeaf, $script:BoostLabWdfLeaf) -and
        $registryPath.StartsWith($expectedRegistryPrefix, [StringComparison]::OrdinalIgnoreCase) -and
        $registrySubPath.StartsWith($expectedSubPathPrefix, [StringComparison]::OrdinalIgnoreCase) -and
        $registryPath.EndsWith("\$leafName", [StringComparison]::OrdinalIgnoreCase) -and
        $registrySubPath.EndsWith("\$leafName", [StringComparison]::OrdinalIgnoreCase)
    )
}

function Get-BoostLabDeviceManagerReadOnlyDiscovery {
    $targets = [System.Collections.Generic.List[object]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()

    foreach ($className in $script:BoostLabDeviceClasses) {
        $rootPath = 'HKLM:\{0}\{1}' -f $script:BoostLabEnumSubPath, $className
        if (-not (Test-Path -LiteralPath $rootPath -PathType Container)) {
            $warnings.Add("$className device class registry root was not found.")
            continue
        }

        $enumerationErrors = @()
        try {
            $keys = @(
                Get-ChildItem `
                    -LiteralPath $rootPath `
                    -Recurse `
                    -Force `
                    -ErrorAction SilentlyContinue `
                    -ErrorVariable enumerationErrors |
                    Where-Object {
                        $_.PSChildName -in @(
                            $script:BoostLabDeviceParameterLeaf,
                            $script:BoostLabWdfLeaf
                        )
                    }
            )
        }
        catch {
            $warnings.Add("$className device class enumeration failed: $($_.Exception.Message)")
            continue
        }

        foreach ($enumerationError in @($enumerationErrors)) {
            $warnings.Add("$className device class target was inaccessible: $($enumerationError.Exception.Message)")
        }

        foreach ($key in $keys) {
            $registryPath = [string]$key.Name
            if (-not $registryPath.StartsWith('HKEY_LOCAL_MACHINE\', [StringComparison]::OrdinalIgnoreCase)) {
                $warnings.Add("Rejected non-HKLM device target: $registryPath")
                continue
            }

            $target = [pscustomobject]@{
                ClassName = $className
                LeafName = [string]$key.PSChildName
                RegistryPath = $registryPath
                ProviderPath = "Registry::$registryPath"
                RegistrySubPath = $registryPath.Substring('HKEY_LOCAL_MACHINE\'.Length)
            }
            if (-not (Test-BoostLabDeviceManagerRegistryTarget -Target $target)) {
                $warnings.Add("Rejected out-of-scope device target: $registryPath")
                continue
            }

            $targets.Add($target)
        }

        if (@($targets | Where-Object { $_.ClassName -eq $className }).Count -eq 0) {
            $warnings.Add("$className has no accessible Device Parameters or WDF targets.")
        }
    }

    return [pscustomobject]@{
        Succeeded = $true
        EnumerationStatus = if ($warnings.Count -gt 0) { 'Warning' } else { 'Completed' }
        Targets = $targets.ToArray()
        Warnings = $warnings.ToArray()
        Message = if ($targets.Count -eq 0) {
            'No matching device power-management registry targets were found.'
        }
        elseif ($warnings.Count -gt 0) {
            '{0} device registry target(s) detected with {1} enumeration warning(s).' -f $targets.Count, $warnings.Count
        }
        else {
            '{0} device registry target(s) detected.' -f $targets.Count
        }
    }
}

function Get-BoostLabDeviceManagerInventory {
    param(
        [scriptblock]$RegistryDiscovery = {
            Get-BoostLabDeviceManagerReadOnlyDiscovery
        }
    )

    try {
        $discoveryResults = @(& $RegistryDiscovery)
        if ($discoveryResults.Count -eq 0 -or $null -eq $discoveryResults[0]) {
            throw 'Read-only device registry discovery returned no result.'
        }

        $discovery = $discoveryResults[0]
        return [pscustomobject]@{
            Succeeded = [bool]$discovery.Succeeded
            EnumerationStatus = [string]$discovery.EnumerationStatus
            Targets = @($discovery.Targets)
            Warnings = @($discovery.Warnings)
            Message = [string]$discovery.Message
        }
    }
    catch {
        return [pscustomobject]@{
            Succeeded = $false
            EnumerationStatus = 'Failed'
            Targets = @()
            Warnings = @("Device registry enumeration failed: $($_.Exception.Message)")
            Message = "Device registry enumeration failed: $($_.Exception.Message)"
        }
    }
}

function Get-BoostLabDeviceManagerRegistryValue {
    param(
        [Parameter(Mandatory)]
        [string]$RegistrySubPath,

        [Parameter(Mandatory)]
        [string]$Name
    )

    $localMachine = $null
    $registryKey = $null
    try {
        $localMachine = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
            [Microsoft.Win32.RegistryHive]::LocalMachine,
            [Microsoft.Win32.RegistryView]::Default
        )
        $registryKey = $localMachine.OpenSubKey($RegistrySubPath, $false)
        if ($null -eq $registryKey) {
            return [pscustomobject]@{
                ReadSucceeded = $true
                Exists = $false
                Value = $null
                DisplayValue = 'Absent'
                Message = 'Device registry key is absent.'
            }
        }

        if ($Name -notin @($registryKey.GetValueNames())) {
            return [pscustomobject]@{
                ReadSucceeded = $true
                Exists = $false
                Value = $null
                DisplayValue = 'Absent'
                Message = 'Device power value is absent or unsupported.'
            }
        }

        $value = $registryKey.GetValue(
            $Name,
            $null,
            [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
        )
        return [pscustomobject]@{
            ReadSucceeded = $true
            Exists = $true
            Value = $value
            DisplayValue = if ($value -is [byte[]]) {
                ($value | ForEach-Object { $_.ToString('X2') }) -join ''
            }
            else {
                [string]$value
            }
            Message = 'Device power value detected through read-only registry access.'
        }
    }
    catch {
        return [pscustomobject]@{
            ReadSucceeded = $false
            Exists = $false
            Value = $null
            DisplayValue = 'Unknown'
            Message = $_.Exception.Message
        }
    }
    finally {
        if ($null -ne $registryKey) {
            $registryKey.Dispose()
        }
        if ($null -ne $localMachine) {
            $localMachine.Dispose()
        }
    }
}

function ConvertTo-BoostLabDeviceManagerExpectedRegistryValue {
    param(
        [Parameter(Mandatory)]
        [object]$Operation
    )

    switch ([string]$Operation.Type) {
        'REG_DWORD' {
            return [int]([string]$Operation.Data)
        }
        'REG_BINARY' {
            $hex = [string]$Operation.Data
            if (($hex.Length % 2) -ne 0) {
                throw "Invalid REG_BINARY data for $([string]$Operation.Name): $hex"
            }

            $bytes = [byte[]]::new($hex.Length / 2)
            for ($index = 0; $index -lt $bytes.Length; $index++) {
                $bytes[$index] = [Convert]::ToByte($hex.Substring($index * 2, 2), 16)
            }
            return $bytes
        }
        default {
            throw "Unsupported registry value type: $([string]$Operation.Type)"
        }
    }
}

function Test-BoostLabDeviceManagerRegistryValueMatches {
    param(
        [AllowNull()]
        [object]$ActualValue,

        [AllowNull()]
        [object]$ExpectedValue
    )

    if ($ActualValue -is [byte[]] -or $ExpectedValue -is [byte[]]) {
        $actualBytes = @($ActualValue)
        $expectedBytes = @($ExpectedValue)
        if ($actualBytes.Count -ne $expectedBytes.Count) {
            return $false
        }
        for ($index = 0; $index -lt $actualBytes.Count; $index++) {
            if ([byte]$actualBytes[$index] -ne [byte]$expectedBytes[$index]) {
                return $false
            }
        }
        return $true
    }

    return ([string]$ActualValue -eq [string]$ExpectedValue)
}

function Test-BoostLabDeviceManagerInaccessibleRegistryError {
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

function New-BoostLabDeviceManagerRegistryOperationResult {
    param(
        [Parameter(Mandatory)]
        [object]$Operation,

        [Parameter(Mandatory)]
        [ValidateSet('Changed', 'AlreadyCorrect', 'Inaccessible', 'Failed')]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Message
    )

    $description = '{0} | {1}\{2}' -f `
        [string]$Operation.ClassName, `
        [string]$Operation.RegistryPath, `
        [string]$Operation.Name

    return [pscustomobject]@{
        ClassName = [string]$Operation.ClassName
        LeafName = [string]$Operation.LeafName
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

function Invoke-BoostLabDeviceManagerRegistryOperation {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [Parameter(Mandatory)]
        [object]$Operation,

        [scriptblock]$RegistryReader = {
            param($RegistrySubPath, $Name)
            Get-BoostLabDeviceManagerRegistryValue -RegistrySubPath $RegistrySubPath -Name $Name
        }
    )

    if (-not (Test-BoostLabDeviceManagerRegistryTarget -Target $Operation)) {
        return New-BoostLabDeviceManagerRegistryOperationResult `
            -Operation $Operation `
            -Status 'Failed' `
            -Message "Rejected out-of-scope device registry target: $([string]$Operation.RegistryPath)"
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
        $expectedValue = ConvertTo-BoostLabDeviceManagerExpectedRegistryValue -Operation $Operation
        if (
            $exists -and
            (Test-BoostLabDeviceManagerRegistryValueMatches -ActualValue $existingState.Value -ExpectedValue $expectedValue)
        ) {
            return New-BoostLabDeviceManagerRegistryOperationResult `
                -Operation $Operation `
                -Status 'AlreadyCorrect' `
                -Message 'Device registry value was already source-correct.'
        }
    }
    elseif ($readSucceeded -and -not $exists) {
        return New-BoostLabDeviceManagerRegistryOperationResult `
            -Operation $Operation `
            -Status 'AlreadyCorrect' `
            -Message 'Device registry value was already absent.'
    }

    $localMachine = $null
    $registryKey = $null
    try {
        $localMachine = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
            [Microsoft.Win32.RegistryHive]::LocalMachine,
            [Microsoft.Win32.RegistryView]::Default
        )
        $registryKey = $localMachine.OpenSubKey([string]$Operation.RegistrySubPath, $true)
        if ($null -eq $registryKey) {
            $status = if ($ActionName -eq 'Default') { 'AlreadyCorrect' } else { 'Inaccessible' }
            $message = if ($ActionName -eq 'Default') {
                'Device registry key was absent before Default value removal.'
            }
            else {
                'Device registry key was not available for write access.'
            }
            return New-BoostLabDeviceManagerRegistryOperationResult `
                -Operation $Operation `
                -Status $status `
                -Message $message
        }

        if ($ActionName -eq 'Apply') {
            $valueKind = switch ([string]$Operation.Type) {
                'REG_DWORD' { [Microsoft.Win32.RegistryValueKind]::DWord }
                'REG_BINARY' { [Microsoft.Win32.RegistryValueKind]::Binary }
                default { throw "Unsupported registry value type: $([string]$Operation.Type)" }
            }
            $registryKey.SetValue(
                [string]$Operation.Name,
                (ConvertTo-BoostLabDeviceManagerExpectedRegistryValue -Operation $Operation),
                $valueKind
            )
            return New-BoostLabDeviceManagerRegistryOperationResult `
                -Operation $Operation `
                -Status 'Changed' `
                -Message 'Device registry value was written with native registry access.'
        }

        $registryKey.DeleteValue([string]$Operation.Name, $false)
        return New-BoostLabDeviceManagerRegistryOperationResult `
            -Operation $Operation `
            -Status 'Changed' `
            -Message 'Device registry value was removed with native registry access.'
    }
    catch {
        $status = if (Test-BoostLabDeviceManagerInaccessibleRegistryError -Exception $_.Exception) {
            'Inaccessible'
        }
        else {
            'Failed'
        }
        return New-BoostLabDeviceManagerRegistryOperationResult `
            -Operation $Operation `
            -Status $status `
            -Message $_.Exception.Message
    }
    finally {
        if ($null -ne $registryKey) {
            $registryKey.Dispose()
        }
        if ($null -ne $localMachine) {
            $localMachine.Dispose()
        }
    }
}

function New-BoostLabDeviceManagerRegistryOperations {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [Parameter(Mandatory)]
        [object]$Inventory
    )

    $operations = [System.Collections.Generic.List[object]]::new()
    foreach ($definition in @(Get-BoostLabDeviceManagerOperationBlueprint -ActionName $ActionName)) {
        $matchingTargets = @(
            $Inventory.Targets |
                Where-Object {
                    [string]$_.ClassName -eq [string]$definition.ClassName -and
                    [string]$_.LeafName -eq [string]$definition.LeafName
                }
        )
        foreach ($target in $matchingTargets) {
            if (-not (Test-BoostLabDeviceManagerRegistryTarget -Target $target)) {
                throw "Rejected out-of-scope device registry target: $([string]$target.RegistryPath)"
            }

            $command = if ($ActionName -eq 'Apply') {
                'reg add "{0}" /v "{1}" /t {2} /d "{3}" /f' -f `
                    [string]$target.RegistryPath, `
                    [string]$definition.Name, `
                    [string]$definition.Type, `
                    [string]$definition.Data
            }
            else {
                'reg delete "{0}" /v "{1}" /f' -f `
                    [string]$target.RegistryPath, `
                    [string]$definition.Name
            }

            $operations.Add(
                [pscustomobject]@{
                    ClassName = [string]$target.ClassName
                    LeafName = [string]$target.LeafName
                    RegistryPath = [string]$target.RegistryPath
                    RegistrySubPath = [string]$target.RegistrySubPath
                    Name = [string]$definition.Name
                    Type = [string]$definition.Type
                    Data = [string]$definition.Data
                    Command = $command
                }
            )
        }
    }

    return $operations.ToArray()
}

function Test-BoostLabDeviceManagerPowerWakeState {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [AllowNull()]
        [object]$DeviceInventory = $null,

        [scriptblock]$DeviceEnumerator = {
            Get-BoostLabDeviceManagerInventory
        },

        [scriptblock]$RegistryReader = {
            param($RegistrySubPath, $Name)
            Get-BoostLabDeviceManagerRegistryValue -RegistrySubPath $RegistrySubPath -Name $Name
        },

        [AllowNull()]
        [object[]]$RegistryOperationResults = @()
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    $inventory = if ($null -ne $DeviceInventory) {
        $DeviceInventory
    }
    else {
        $inventoryResults = @(& $DeviceEnumerator)
        if ($inventoryResults.Count -gt 0) { $inventoryResults[0] } else { $null }
    }

    if ($null -eq $inventory -or -not [bool]$inventory.Succeeded) {
        $message = if ($null -ne $inventory) { [string]$inventory.Message } else { 'Device registry inventory was unavailable.' }
        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name 'Device registry enumeration' `
                -Expected 'Read-only access to source-approved device classes' `
                -Actual 'Unavailable' `
                -Status 'Warning' `
                -Message $message)
        )
    }
    else {
        foreach ($warning in @($inventory.Warnings)) {
            $checks.Add(
                (New-BoostLabVerificationCheck `
                    -Name 'Device registry enumeration warning' `
                    -Expected 'Accessible source-approved target' `
                    -Actual 'Unavailable or not applicable' `
                    -Status 'Warning' `
                    -Message ([string]$warning))
            )
        }

        if (@($inventory.Targets).Count -eq 0) {
            $checks.Add(
                (New-BoostLabVerificationCheck `
                    -Name 'Device registry targets' `
                    -Expected 'One or more Device Parameters or WDF keys' `
                    -Actual 'None found' `
                    -Status 'Warning' `
                    -Message ([string]$inventory.Message))
            )
        }

        $operations = @(
            New-BoostLabDeviceManagerRegistryOperations `
                -ActionName $ActionName `
                -Inventory $inventory
        )
        $operationResultMap = @{}
        foreach ($operationResult in @($RegistryOperationResults)) {
            if ($null -eq $operationResult) {
                continue
            }
            $key = '{0}|{1}|{2}' -f `
                [string]$operationResult.ClassName, `
                [string]$operationResult.RegistrySubPath, `
                [string]$operationResult.Name
            $operationResultMap[$key.ToLowerInvariant()] = $operationResult
        }

        foreach ($operation in $operations) {
            $operationKey = ('{0}|{1}|{2}' -f `
                [string]$operation.ClassName, `
                [string]$operation.RegistrySubPath, `
                [string]$operation.Name).ToLowerInvariant()
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
                            [string]$operation.ClassName, `
                            [string]$operation.RegistryPath, `
                            [string]$operation.Name) `
                        -Expected $(if ($ActionName -eq 'Apply') {
                            '{0} ({1})' -f [string]$operation.Data, [string]$operation.Type
                        } else {
                            'Absent'
                        }) `
                        -Actual $(if ($ActionName -eq 'Apply') {
                            '{0} ({1})' -f [string]$operation.Data, [string]$operation.Type
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
                [string]$operationResult.Status -in @('Inaccessible', 'Failed')
            ) {
                $checks.Add(
                    (New-BoostLabVerificationCheck `
                        -Name ('{0} | {1}\{2}' -f `
                            [string]$operation.ClassName, `
                            [string]$operation.RegistryPath, `
                            [string]$operation.Name) `
                        -Expected $(if ($ActionName -eq 'Apply') {
                            '{0} ({1})' -f [string]$operation.Data, [string]$operation.Type
                        } else {
                            'Absent'
                        }) `
                        -Actual ([string]$operationResult.Status) `
                        -Status $(if ([string]$operationResult.Status -eq 'Inaccessible') { 'Warning' } else { 'Failed' }) `
                        -Message ([string]$operationResult.Message))
                )
                continue
            }

            try {
                $stateResults = @(& $RegistryReader ([string]$operation.RegistrySubPath) ([string]$operation.Name))
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
            $actual = if ($null -ne $state -and $null -ne $state.PSObject.Properties['DisplayValue']) {
                [string]$state.DisplayValue
            }
            else {
                'Unknown'
            }
            $stateMessage = if ($null -ne $state -and $null -ne $state.PSObject.Properties['Message']) {
                [string]$state.Message
            }
            else {
                'Device power value could not be read.'
            }

            $expectedData = [string]$operation.Data
            $detectedData = if ($exists -and $state.Value -is [byte[]]) {
                ($state.Value | ForEach-Object { $_.ToString('X2') }) -join ''
            }
            elseif ($exists) {
                [string]$state.Value
            }
            else {
                ''
            }
            $status = if (-not $readSucceeded) {
                'Warning'
            }
            elseif ($ActionName -eq 'Apply' -and $exists -and $detectedData -eq $expectedData) {
                'Passed'
            }
            elseif ($ActionName -eq 'Default' -and -not $exists) {
                'Passed'
            }
            else {
                'Failed'
            }
            $expected = if ($ActionName -eq 'Apply') {
                '{0} ({1})' -f $expectedData, [string]$operation.Type
            }
            else {
                'Absent'
            }

            $checks.Add(
                (New-BoostLabVerificationCheck `
                    -Name ('{0} | {1}\{2}' -f `
                        [string]$operation.ClassName, `
                        [string]$operation.RegistryPath, `
                        [string]$operation.Name) `
                    -Expected $expected `
                    -Actual $actual `
                    -Status $status `
                    -Message $stateMessage)
            )
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
    $expectedSummary = if ($ActionName -eq 'Apply') {
        'Source-defined device power-saving and wake values set to 0'
    }
    else {
        'Source-defined Default value names absent'
    }
    $detectedSummary = '{0} passed, {1} warning, {2} failed across {3} accessible target(s)' -f `
        $passedCount, `
        $warningCount, `
        $failedCount, `
        $(if ($null -ne $inventory) { @($inventory.Targets).Count } else { 0 })
    $message = switch ($overallStatus) {
        'Passed' { 'The expected Device Manager power savings and wake state was detected.' }
        'Warning' { 'The command completed, but optional or inaccessible device targets produced verification warnings.' }
        default { 'One or more detected device values contradict the expected Device Manager power savings and wake state.' }
    }

    return New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $ActionName `
        -Status $overallStatus `
        -ExpectedState ([pscustomobject]@{ DevicePowerWake = $expectedSummary }) `
        -DetectedState ([pscustomobject]@{ DevicePowerWake = $detectedSummary }) `
        -Checks $checks.ToArray() `
        -Message $message
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $inventory = Get-BoostLabDeviceManagerInventory
    return [pscustomobject]@{
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Status = if ($inventory.Succeeded) {
            '{0} source-approved device registry target(s) detected' -f @($inventory.Targets).Count
        }
        else {
            'Device registry inventory unavailable'
        }
        TargetedDeviceClasses = @($script:BoostLabDeviceClasses)
        RegistryPaths = @($inventory.Targets | ForEach-Object { $_.RegistryPath })
        LastAction = $null
        LastResult = $null
        RestartRequired = $false
        Timestamp = Get-Date
    }
}

function Invoke-BoostLabDeviceManagerPowerWakeAction {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [scriptblock]$AdministratorChecker = {
            Test-BoostLabAdministrator
        },

        [scriptblock]$DeviceEnumerator = {
            Get-BoostLabDeviceManagerInventory
        },

        [scriptblock]$RegistryReader = {
            param($RegistrySubPath, $Name)
            Get-BoostLabDeviceManagerRegistryValue -RegistrySubPath $RegistrySubPath -Name $Name
        },

        [scriptblock]$RegistryCommandInvoker = {
            param($CommandText, $Operation, $Action, $Reader)
            Invoke-BoostLabDeviceManagerRegistryOperation `
                -ActionName $Action `
                -Operation $Operation `
                -RegistryReader $Reader
        }
    )

    if (-not [bool](& $AdministratorChecker)) {
        return New-BoostLabDeviceManagerPowerWakeResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Administrator rights are required to change device power savings and wake values.'
    }

    $inventoryResults = @(& $DeviceEnumerator)
    $inventory = if ($inventoryResults.Count -gt 0) { $inventoryResults[0] } else { $null }
    if ($null -eq $inventory) {
        $inventory = [pscustomobject]@{
            Succeeded = $false
            EnumerationStatus = 'Failed'
            Targets = @()
            Warnings = @('Device registry enumeration returned no result.')
            Message = 'Device registry enumeration returned no result.'
        }
    }

    $operationsAttempted = [System.Collections.Generic.List[string]]::new()
    $operationResults = [System.Collections.Generic.List[object]]::new()
    $operationsSkipped = [System.Collections.Generic.List[string]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    foreach ($warning in @($inventory.Warnings)) {
        $warnings.Add([string]$warning)
    }

    try {
        $operations = @(
            New-BoostLabDeviceManagerRegistryOperations `
                -ActionName $ActionName `
                -Inventory $inventory
        )
    }
    catch {
        $operations = @()
        $errors.Add($_.Exception.Message)
    }

    foreach ($operation in $operations) {
        $description = '{0} | {1}\{2}' -f `
            [string]$operation.ClassName, `
            [string]$operation.RegistryPath, `
            [string]$operation.Name

        $operationsAttempted.Add($description)
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
                New-BoostLabDeviceManagerRegistryOperationResult `
                    -Operation $operation `
                    -Status 'Changed' `
                    -Message 'Device registry command completed.'
            }
            $operationResults.Add($operationResult)
        }
        catch {
            $status = if (Test-BoostLabDeviceManagerInaccessibleRegistryError -Exception $_.Exception) {
                'Inaccessible'
            }
            else {
                'Failed'
            }
            $operationResults.Add(
                (New-BoostLabDeviceManagerRegistryOperationResult `
                    -Operation $operation `
                    -Status $status `
                    -Message $_.Exception.Message)
            )
        }
    }

    $verificationResult = Test-BoostLabDeviceManagerPowerWakeState `
        -ActionName $ActionName `
        -DeviceInventory $inventory `
        -RegistryReader $RegistryReader `
        -RegistryOperationResults $operationResults.ToArray()
    $changedResults = @($operationResults | Where-Object { [string]$_.Status -eq 'Changed' })
    $alreadyCorrectResults = @($operationResults | Where-Object { [string]$_.Status -eq 'AlreadyCorrect' })
    $inaccessibleResults = @($operationResults | Where-Object { [string]$_.Status -eq 'Inaccessible' })
    $failedResults = @($operationResults | Where-Object { [string]$_.Status -eq 'Failed' })
    $sampleLimit = 10
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
    foreach ($sample in $inaccessibleSamples) {
        $warnings.Add($sample)
    }
    foreach ($sample in $failedSamples) {
        $errors.Add($sample)
    }
    $commandStatus = if (-not [bool]$inventory.Succeeded) {
        'Not executed: enumeration failed'
    }
    elseif (@($inventory.Targets).Count -eq 0) {
        'Not applicable: no matching targets'
    }
    elseif ($failedResults.Count -gt 0) {
        'Completed with errors'
    }
    elseif ($operationsAttempted.Count -eq 0 -and $ActionName -eq 'Default') {
        'Already default'
    }
    elseif ($warnings.Count -gt 0 -or $inaccessibleResults.Count -gt 0) {
        'Completed with warnings'
    }
    else {
        'Completed'
    }
    $data = [pscustomobject]@{
        CommandStatus = $commandStatus
        VerificationStatus = [string]$verificationResult.Status
        ExpectedDevicePowerWakeState = [string]$verificationResult.ExpectedState.DevicePowerWake
        DetectedDevicePowerWakeState = [string]$verificationResult.DetectedState.DevicePowerWake
        TargetedDeviceClasses = @($script:BoostLabDeviceClasses)
        RegistryPathsTargeted = @($inventory.Targets | ForEach-Object { $_.RegistryPath } | Sort-Object -Unique)
        ValuesChanged = @($changedResults | ForEach-Object { [string]$_.Description })
        AlreadyCorrectItems = @($alreadyCorrectResults | ForEach-Object { [string]$_.Description })
        InaccessibleItems = $inaccessibleSamples
        FailedItems = $failedSamples
        AttemptedCount = $operationsAttempted.Count
        ChangedCount = $changedResults.Count
        AlreadyCorrectCount = $alreadyCorrectResults.Count
        InaccessibleCount = $inaccessibleResults.Count
        FailedCount = $failedResults.Count
        SkippedItems = $operationsSkipped.ToArray()
        Warnings = $warnings.ToArray()
        Errors = $errors.ToArray()
        RegistryOperationsAttempted = $operationsAttempted.ToArray()
        RegistryOperationResultSummary = [pscustomobject]@{
            Attempted = $operationsAttempted.Count
            Changed = $changedResults.Count
            AlreadyCorrect = $alreadyCorrectResults.Count
            Inaccessible = $inaccessibleResults.Count
            Failed = $failedResults.Count
            SampleLimit = $sampleLimit
        }
        CompletedAt = Get-Date
    }

    if (-not [bool]$inventory.Succeeded) {
        return New-BoostLabDeviceManagerPowerWakeResult `
            -Success $false `
            -Action $ActionName `
            -Message ([string]$inventory.Message) `
            -Data $data `
            -VerificationResult $verificationResult
    }
    if ($failedResults.Count -gt 0) {
        return New-BoostLabDeviceManagerPowerWakeResult `
            -Success $false `
            -Action $ActionName `
            -Message ('Device power savings and wake action completed with {0} failed registry operation(s). Sample: {1}' -f $failedResults.Count, ($failedSamples -join '; ')) `
            -Data $data `
            -VerificationResult $verificationResult
    }
    if ($verificationResult.Status -eq 'Failed') {
        return New-BoostLabDeviceManagerPowerWakeResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Device power savings and wake commands completed, but verification detected an unexpected state.' `
            -Data $data `
            -VerificationResult $verificationResult
    }

    $message = if (@($inventory.Targets).Count -eq 0) {
        'No applicable device power-management registry targets were found.'
    }
    elseif ($verificationResult.Status -eq 'Warning') {
        'Device power savings and wake commands completed with optional or inaccessible target warnings.'
    }
    elseif ($ActionName -eq 'Apply') {
        'Device Manager power savings and wake disabled.'
    }
    elseif ($operationsAttempted.Count -eq 0) {
        'Device Manager power savings and wake already default.'
    }
    else {
        'Device Manager power savings and wake restored to the Ultimate default value removals.'
    }

    return New-BoostLabDeviceManagerPowerWakeResult `
        -Success $true `
        -Action $ActionName `
        -Message $message `
        -Data $data `
        -VerificationResult $verificationResult
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
        return New-BoostLabDeviceManagerPowerWakeResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Unsupported action. Only Apply and Default are allowed.'
    }
    if (-not $Confirmed) {
        return New-BoostLabDeviceManagerPowerWakeResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    return Invoke-BoostLabDeviceManagerPowerWakeAction -ActionName $ActionName
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
