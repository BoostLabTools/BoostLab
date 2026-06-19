Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $verificationModulePath -Scope Local -ErrorAction Stop
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
        ToolId    = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason    = if ($OperatingSystem -ne 'Windows_NT') {
            'Network Adapter Power Savings & Wake requires Windows.'
        }
        elseif ([string]::IsNullOrWhiteSpace($commandProcessorPath)) {
            'The Windows system directory is unavailable.'
        }
        elseif (-not $supported) {
            'Network adapter registry commands are unavailable because cmd.exe was not found.'
        }
        else {
            'Windows network adapter class registry support is available.'
        }
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

function New-BoostLabNetworkAdapterRegistryOperations {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [Parameter(Mandatory)]
        [object]$Adapter
    )

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
        }
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
        foreach ($adapter in @($inventory.Adapters)) {
            foreach ($definition in $uniqueDefinitions) {
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

function Invoke-BoostLabNetworkAdapterRegistryCommand {
    param(
        [Parameter(Mandatory)]
        [string]$CommandText
    )

    if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        throw 'The Windows system directory is unavailable.'
    }
    $commandProcessorPath = Join-Path $env:SystemRoot 'System32\cmd.exe'
    if (-not (Test-Path -LiteralPath $commandProcessorPath -PathType Leaf)) {
        throw 'cmd.exe was not found.'
    }

    $output = & $commandProcessorPath /c $CommandText 2>&1
    if ($LASTEXITCODE -ne 0) {
        $detail = (@($output) -join ' ').Trim()
        if ([string]::IsNullOrWhiteSpace($detail)) {
            $detail = "reg.exe returned exit code $LASTEXITCODE."
        }

        throw $detail
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
            param($CommandText)
            Invoke-BoostLabNetworkAdapterRegistryCommand -CommandText $CommandText
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
    $registryOperationsCompleted = [System.Collections.Generic.List[string]]::new()
    $registryOperationsSkipped = [System.Collections.Generic.List[string]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()

    foreach ($adapter in @($inventory.Adapters)) {
        foreach ($operation in @(New-BoostLabNetworkAdapterRegistryOperations -ActionName $ActionName -Adapter $adapter)) {
            if ($ActionName -eq 'Default') {
                try {
                    $stateResults = @(& $RegistryReader ([string]$operation.RegistrySubPath) ([string]$operation.Name))
                    $state = if ($stateResults.Count -gt 0) { $stateResults[0] } else { $null }
                }
                catch {
                    $state = $null
                }
                if (
                    $null -ne $state -and
                    $null -ne $state.PSObject.Properties['ReadSucceeded'] -and
                    [bool]$state.ReadSucceeded -and
                    $null -ne $state.PSObject.Properties['Exists'] -and
                    -not [bool]$state.Exists
                ) {
                    $registryOperationsSkipped.Add(
                        (
                            '{0}: {1} already absent' -f `
                                [string]$operation.AdapterName, `
                                [string]$operation.Name
                        )
                    )
                    continue
                }
            }

            $operationDescription = '{0}: {1}' -f `
                [string]$operation.AdapterName, `
                [string]$operation.Name
            $registryOperationsAttempted.Add($operationDescription)
            try {
                & $RegistryCommandInvoker ([string]$operation.Command) | Out-Null
                $registryOperationsCompleted.Add($operationDescription)
            }
            catch {
                $errors.Add(
                    (
                        '{0} failed: {1}' -f `
                            $operationDescription, `
                            $_.Exception.Message
                    )
                )
            }
        }
    }

    $verificationResult = Test-BoostLabNetworkAdapterPowerWakeState `
        -ActionName $ActionName `
        -AdapterInventory $inventory `
        -RegistryReader $RegistryReader
    $completedAt = Get-Date
    $expectedState = [string]$verificationResult.ExpectedState.AdapterPowerWake
    $detectedState = [string]$verificationResult.DetectedState.AdapterPowerWake
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
    elseif ($errors.Count -gt 0) {
        'Completed with errors'
    }
    elseif ($registryOperationsAttempted.Count -eq 0 -and $ActionName -eq 'Default') {
        'Already default'
    }
    else {
        'Completed'
    }
    $data = [pscustomobject]@{
        AdapterEnumerationStatus          = [string]$inventory.EnumerationStatus
        CommandStatus                    = $commandStatus
        VerificationStatus               = [string]$verificationResult.Status
        ExpectedAdapterPowerWakeState    = $expectedState
        DetectedAdapterPowerWakeState    = $detectedState
        AdapterNamesTargeted              = $adapterNames
        InaccessibleAdapterTargets        = $inaccessibleTargets
        RegistryValuesChecked             = $registryValuesChecked
        PropertiesAppliedOrDefaulted      = $registryOperationsCompleted.ToArray()
        InaccessibleOrUnsupportedProperties = @(
            $verificationResult.Checks |
                Where-Object { $_.Status -eq 'Warning' } |
                ForEach-Object { $_.Name }
        )
        RegistryOperationsAttempted       = $registryOperationsAttempted.ToArray()
        RegistryOperationsCompleted       = $registryOperationsCompleted.ToArray()
        RegistryOperationsSkipped         = $registryOperationsSkipped.ToArray()
        CompletedAt                       = $completedAt
    }

    if (-not [bool]$inventory.Succeeded -or @($inventory.Adapters).Count -eq 0) {
        return New-BoostLabNetworkAdapterPowerWakeResult `
            -Success $false `
            -Action $ActionName `
            -Message ([string]$inventory.Message) `
            -Data $data `
            -VerificationResult $verificationResult
    }
    if ($errors.Count -gt 0) {
        return New-BoostLabNetworkAdapterPowerWakeResult `
            -Success $false `
            -Action $ActionName `
            -Message ('Network adapter power and wake action completed with errors: {0}' -f ($errors -join '; ')) `
            -Data $data `
            -VerificationResult $verificationResult
    }
    if ($verificationResult.Status -eq 'Failed') {
        return New-BoostLabNetworkAdapterPowerWakeResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Network adapter power and wake commands completed, but verification detected an unexpected state.' `
            -Data $data `
            -VerificationResult $verificationResult
    }

    $message = if ($verificationResult.Status -eq 'Warning') {
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
