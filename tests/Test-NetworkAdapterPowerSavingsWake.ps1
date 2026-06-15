[CmdletBinding()]
param(
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $scriptPath = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $PSCommandPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $MyInvocation.MyCommand.Path
    }
    else {
        throw 'Unable to determine the Network Adapter Power Savings & Wake test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\NetworkAdapterPowerSavingsWake.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\19 Network Adapter Power Savings & Wake.ps1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$recordPath = Join-Path $ProjectRoot 'docs\migrations\network-adapter-power-savings-wake.md'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$sourceHash = '1DAAC872ECB1C601FD165FD471BFA9B9137D895333FBFBC5ADE5427561D4BCEB'
$adapterClassPath = 'HKLM:\System\ControlSet001\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}'
$valueDefinitions = @(
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
    [pscustomobject]@{ Name = '*ModernStandbyWoLMagicPacket'; Type = 'REG_SZ'; Data = '0' }
)

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration['Stages'] | ForEach-Object { @($_['Tools']) })
$tool = $tools |
    Where-Object { $_['Id'] -eq 'network-adapter-power-savings-wake' } |
    Select-Object -First 1
if ($null -eq $tool) {
    throw 'Network Adapter Power Savings & Wake metadata is missing.'
}
if (
    [string]$tool['Stage'] -ne 'Windows' -or
    [int]$tool['Order'] -ne 19 -or
    [string]$tool['Type'] -ne 'action' -or
    [string]$tool['RiskLevel'] -ne 'medium' -or
    (@($tool['Actions']) -join ',') -ne 'Apply,Default'
) {
    throw 'Network Adapter Power Savings & Wake stage, order, type, risk, or actions are incorrect.'
}

$capabilities = $tool['Capabilities']
$expectedTrueCapabilities = @(
    'RequiresAdmin'
    'CanModifyRegistry'
    'CanModifyDrivers'
    'SupportsDefault'
    'NeedsExplicitConfirmation'
)
foreach ($field in $capabilities.Keys) {
    $expected = $field -in $expectedTrueCapabilities
    if ([bool]$capabilities[$field] -ne $expected) {
        throw "Network Adapter Power Savings & Wake capability '$field' is incorrect."
    }
}

if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne $sourceHash) {
    throw 'Network Adapter Power Savings & Wake Ultimate source hash changed.'
}
$source = Get-Content -Raw -LiteralPath $sourcePath
foreach ($requiredText in @(
    $adapterClassPath
    '$key.PSChildName -match ''^\d{4}$'''
    'PnPCapabilities'
    'AdvancedEEE'
    '*EEE'
    'EEELinkAdvertisement'
    'SipsEnabled'
    'ULPMode'
    'GigaLite'
    'EnableGreenEthernet'
    'PowerSavingMode'
    'S5WakeOnLan'
    '*WakeOnMagicPacket'
    '*ModernStandbyWoLMagicPacket'
    '*WakeOnPattern'
    'WakeOnLink'
)) {
    if (-not $source.Contains($requiredText)) {
        throw "Ultimate source no longer contains: $requiredText"
    }
}
foreach ($forbiddenSourceText in @(
    'Disable-NetAdapter'
    'Disable-PnpDevice'
    'Uninstall-PnpDevice'
    'pnputil'
    'devcon'
    'netsh winsock reset'
    'netsh int ip reset'
    'Set-NetFirewall'
    'Invoke-WebRequest'
    'Start-BitsTransfer'
    'Restart-Computer'
    'shutdown.exe'
    'TrustedInstaller'
    'safeboot'
    'Set-Service'
    'Stop-Service'
    'Remove-AppxPackage'
)) {
    if ($source.Contains($forbiddenSourceText)) {
        throw "Ultimate source failed the Phase 23 safety gate: $forbiddenSourceText"
    }
}

$sourceValueNames = @(
    [regex]::Matches($source, '/v\s+`"(?<Name>[^`"]+)`"') |
        ForEach-Object { $_.Groups['Name'].Value } |
        Sort-Object -Unique
)
$approvedValueNames = @($valueDefinitions.Name | Sort-Object -Unique)
if (($sourceValueNames -join '|') -ne ($approvedValueNames -join '|')) {
    throw 'The approved module registry value set no longer matches the Ultimate source.'
}

if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
    throw 'The canonical Network Adapter Power Savings & Wake module is missing.'
}
$legacyPlaceholderPath = Join-Path $ProjectRoot 'modules\Windows\network-adapter-power-savings-wake.psm1'
if (
    $legacyPlaceholderPath -cne $modulePath -and
    (Test-Path -LiteralPath $legacyPlaceholderPath -PathType Leaf)
) {
    throw 'The old Network Adapter Power Savings & Wake placeholder path still exists.'
}
$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredText in @(
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    $adapterClassPath
    '$script:BoostLabAdapterValueDefinitions'
    'REG_DWORD'
    'REG_SZ'
    'function New-BoostLabNetworkAdapterRegistryOperations'
    'function Get-BoostLabNetworkAdapterReadOnlyDiscovery'
    'function Test-BoostLabNetworkAdapterPowerWakeState'
    'function Invoke-BoostLabNetworkAdapterPowerWakeAction'
    '[Microsoft.Win32.RegistryKey]::OpenBaseKey'
    '$classKey.OpenSubKey($subKeyName, $false)'
    '$localMachine.OpenSubKey($RegistrySubPath, $false)'
    'InaccessibleTargets'
    'AdapterEnumerationStatus'
    'PropertiesAppliedOrDefaulted'
    'New-BoostLabVerificationResult'
    '-VerificationResult $verificationResult'
    '[bool]$Confirmed = $false'
    'Network adapter power savings and wake disabled.'
    'Network adapter power savings and wake restored to default.'
    'No matching network adapter registry keys were found.'
)) {
    if (-not $moduleSource.Contains($requiredText)) {
        throw "Network Adapter Power Savings & Wake module is missing: $requiredText"
    }
}
foreach ($forbiddenModuleText in @(
    'Disable-NetAdapter'
    'Disable-PnpDevice'
    'Uninstall-PnpDevice'
    'pnputil'
    'devcon'
    'netsh winsock reset'
    'netsh int ip reset'
    'Set-NetFirewall'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'Restart-Computer'
    'Stop-Computer'
    'Set-Service'
    'Stop-Service'
    'Restart-Service'
    'Stop-Process'
    'Remove-AppxPackage'
    'UsesTrustedInstaller = $true'
    'UsesSafeMode = $true'
    'Remove-Item '
    'Get-ChildItem -Path $script:BoostLabAdapterClassPath'
    'Get-ItemProperty'
)) {
    if ($moduleSource.Contains($forbiddenModuleText)) {
        throw "Network Adapter Power Savings & Wake module contains forbidden behavior: $forbiddenModuleText"
    }
}

$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $modulePath,
    [ref]$tokens,
    [ref]$parseErrors
)
if (@($parseErrors).Count -gt 0) {
    throw "Network Adapter Power Savings & Wake module syntax error: $($parseErrors[0].Message)"
}
$commands = @(
    $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
        $true
    ) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }
)
foreach ($forbiddenCommand in @(
    'Disable-NetAdapter'
    'Disable-PnpDevice'
    'Uninstall-PnpDevice'
    'Update-Driver'
    'Remove-AppxPackage'
    'Set-Service'
    'Stop-Service'
    'Restart-Service'
    'Restart-Computer'
    'Stop-Computer'
    'Invoke-WebRequest'
    'Start-BitsTransfer'
)) {
    if ($forbiddenCommand -in $commands) {
        throw "Network Adapter Power Savings & Wake contains forbidden command: $forbiddenCommand"
    }
}

$networkModule = Import-Module `
    -Name $modulePath `
    -Force `
    -PassThru `
    -Prefix 'NetworkPowerTest' `
    -Scope Local `
    -DisableNameChecking `
    -ErrorAction Stop
try {
    $infoCommand = Get-Command `
        -Name 'Get-NetworkPowerTestBoostLabToolInfo' `
        -Module $networkModule.Name `
        -ErrorAction Stop
    $toolInfo = & $infoCommand
    if (
        [string]$toolInfo.Id -ne 'network-adapter-power-savings-wake' -or
        (@($toolInfo.Actions) -join ',') -ne 'Apply,Default' -or
        (@($toolInfo.ImplementedActions) -join ',') -ne 'Apply,Default'
    ) {
        throw 'Network Adapter Power Savings & Wake exported metadata is incorrect.'
    }

    $adapter = [pscustomobject]@{
        AdapterName    = 'Mock Ethernet'
        AdapterKey     = '0001'
        RegistryPath   = 'HKEY_LOCAL_MACHINE\System\ControlSet001\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0001'
        ProviderPath   = 'HKLM:\System\ControlSet001\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0001'
        RegistrySubPath = 'System\ControlSet001\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0001'
    }
    $inventory = [pscustomobject]@{
        Succeeded           = $true
        EnumerationStatus   = 'Completed'
        Adapters            = @($adapter)
        InaccessibleTargets = @()
        Message             = 'One mock adapter detected.'
    }
    $protectedTarget = [pscustomobject]@{
        Target  = 'HKEY_LOCAL_MACHINE\System\ControlSet001\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0002'
        Message = 'Requested registry access is not allowed.'
    }
    $readOnlyDiscovery = {
        return [pscustomobject]@{
            Succeeded           = $true
            EnumerationStatus   = 'Warning'
            Adapters            = @($adapter)
            InaccessibleTargets = @($protectedTarget)
            Message             = 'One adapter key detected; one protected key was skipped.'
        }
    }.GetNewClosure()
    $partialInventory = & $networkModule {
        param($Discovery)
        Get-BoostLabNetworkAdapterInventory -RegistryDiscovery $Discovery
    } $readOnlyDiscovery
    if (
        -not $partialInventory.Succeeded -or
        $partialInventory.EnumerationStatus -ne 'Warning' -or
        @($partialInventory.Adapters).Count -ne 1 -or
        @($partialInventory.InaccessibleTargets).Count -ne 1 -or
        $partialInventory.InaccessibleTargets[0].Target -ne $protectedTarget.Target
    ) {
        throw 'Read-only adapter discovery did not preserve accessible and protected targets.'
    }
    $applyOperations = @(
        & $networkModule {
            param($Adapter)
            New-BoostLabNetworkAdapterRegistryOperations -ActionName 'Apply' -Adapter $Adapter
        } $adapter
    )
    $defaultOperations = @(
        & $networkModule {
            param($Adapter)
            New-BoostLabNetworkAdapterRegistryOperations -ActionName 'Default' -Adapter $Adapter
        } $adapter
    )
    if ($applyOperations.Count -ne 15 -or $defaultOperations.Count -ne 15) {
        throw 'The source operation sequence must contain 15 entries, including the repeated Modern Standby value.'
    }
    for ($index = 0; $index -lt $valueDefinitions.Count; $index++) {
        $expected = $valueDefinitions[$index]
        $apply = $applyOperations[$index]
        $default = $defaultOperations[$index]
        if (
            $apply.Name -ne $expected.Name -or
            $apply.Type -ne $expected.Type -or
            [string]$apply.Data -ne [string]$expected.Data -or
            $apply.Command -ne (
                'reg add "{0}" /v "{1}" /t {2} /d "{3}" /f' -f `
                    $adapter.RegistryPath, $expected.Name, $expected.Type, $expected.Data
            ) -or
            $default.Name -ne $expected.Name -or
            $default.Command -ne (
                'reg delete "{0}" /v "{1}" /f' -f $adapter.RegistryPath, $expected.Name
            )
        ) {
            throw "Registry operation $index no longer matches Ultimate."
        }
    }

    $newStateReader = {
        param([hashtable]$States)
        return {
            param($Path, $Name)
            $state = $States[$Name]
            if ($null -eq $state) {
                return [pscustomobject]@{
                    ReadSucceeded = $true
                    Exists        = $false
                    Value         = $null
                    DisplayValue  = 'Absent'
                    Message       = 'Mock adapter property is absent.'
                }
            }

            return $state
        }.GetNewClosure()
    }
    $applyStates = @{}
    foreach ($definition in $valueDefinitions) {
        $applyStates[$definition.Name] = [pscustomobject]@{
            ReadSucceeded = $true
            Exists        = $true
            Value         = if ($definition.Name -eq 'PnPCapabilities') { 24 } else { '0' }
            DisplayValue  = [string]$(if ($definition.Name -eq 'PnPCapabilities') { 24 } else { '0' })
            Message       = 'Mock expected adapter property detected.'
        }
    }
    $applyReader = & $newStateReader $applyStates
    $applyVerification = & $networkModule {
        param($Inventory, $Reader)
        Test-BoostLabNetworkAdapterPowerWakeState `
            -ActionName 'Apply' `
            -AdapterInventory $Inventory `
            -RegistryReader $Reader
    } $inventory $applyReader
    if (
        $applyVerification.Status -ne 'Passed' -or
        @($applyVerification.Checks).Count -ne 14
    ) {
        throw 'Mocked Apply verification did not pass all 14 unique values.'
    }

    $defaultReader = & $newStateReader @{}
    $defaultVerification = & $networkModule {
        param($Inventory, $Reader)
        Test-BoostLabNetworkAdapterPowerWakeState `
            -ActionName 'Default' `
            -AdapterInventory $Inventory `
            -RegistryReader $Reader
    } $inventory $defaultReader
    if (
        $defaultVerification.Status -ne 'Passed' -or
        @($defaultVerification.Checks).Count -ne 14
    ) {
        throw 'Mocked Default verification did not accept absent values.'
    }

    $warningStates = @{}
    foreach ($name in $applyStates.Keys) {
        $warningStates[$name] = $applyStates[$name]
    }
    $warningStates['AdvancedEEE'] = [pscustomobject]@{
        ReadSucceeded = $true
        Exists        = $false
        Value         = $null
        DisplayValue  = 'Absent'
        Message       = 'Mock driver does not expose this property.'
    }
    $warningReader = & $newStateReader $warningStates
    $warningVerification = & $networkModule {
        param($Inventory, $Reader)
        Test-BoostLabNetworkAdapterPowerWakeState `
            -ActionName 'Apply' `
            -AdapterInventory $Inventory `
            -RegistryReader $Reader
    } $inventory $warningReader
    if ($warningVerification.Status -ne 'Warning') {
        throw 'An unsupported adapter property was not reported as Warning.'
    }

    $unreadableStates = @{}
    foreach ($name in $applyStates.Keys) {
        $unreadableStates[$name] = $applyStates[$name]
    }
    $unreadableStates['SipsEnabled'] = [pscustomobject]@{
        ReadSucceeded = $false
        Exists        = $false
        Value         = $null
        DisplayValue  = 'Unknown'
        Message       = 'Requested registry access is not allowed.'
    }
    $unreadableReader = & $newStateReader $unreadableStates
    $unreadableVerification = & $networkModule {
        param($Inventory, $Reader)
        Test-BoostLabNetworkAdapterPowerWakeState `
            -ActionName 'Apply' `
            -AdapterInventory $Inventory `
            -RegistryReader $Reader
    } $inventory $unreadableReader
    if ($unreadableVerification.Status -ne 'Warning') {
        throw 'An inaccessible adapter property was not reported as Warning.'
    }

    $partialVerification = & $networkModule {
        param($Inventory, $Reader)
        Test-BoostLabNetworkAdapterPowerWakeState `
            -ActionName 'Apply' `
            -AdapterInventory $Inventory `
            -RegistryReader $Reader
    } $partialInventory $applyReader
    if (
        $partialVerification.Status -ne 'Warning' -or
        @(
            $partialVerification.Checks |
                Where-Object { $_.Name -like 'Adapter enumeration access*' }
        ).Count -ne 1
    ) {
        throw 'Protected adapter discovery was not preserved as a verification warning.'
    }

    $failedStates = @{}
    foreach ($name in $applyStates.Keys) {
        $failedStates[$name] = $applyStates[$name]
    }
    $failedStates['WakeOnLink'] = [pscustomobject]@{
        ReadSucceeded = $true
        Exists        = $true
        Value         = '1'
        DisplayValue  = '1'
        Message       = 'Mock contradictory adapter property detected.'
    }
    $failedReader = & $newStateReader $failedStates
    $failedVerification = & $networkModule {
        param($Inventory, $Reader)
        Test-BoostLabNetworkAdapterPowerWakeState `
            -ActionName 'Apply' `
            -AdapterInventory $Inventory `
            -RegistryReader $Reader
    } $inventory $failedReader
    if ($failedVerification.Status -ne 'Failed') {
        throw 'A contradictory adapter value was not reported as Failed.'
    }

    $emptyInventory = [pscustomobject]@{
        Succeeded           = $true
        EnumerationStatus   = 'Warning'
        Adapters            = @()
        InaccessibleTargets = @($protectedTarget)
        Message             = 'No accessible mock adapters.'
    }
    $emptyVerification = & $networkModule {
        param($Inventory, $Reader)
        Test-BoostLabNetworkAdapterPowerWakeState `
            -ActionName 'Apply' `
            -AdapterInventory $Inventory `
            -RegistryReader $Reader
    } $emptyInventory $defaultReader
    if ($emptyVerification.Status -ne 'Warning') {
        throw 'No matching adapters was not reported as Warning.'
    }
    $emptyInventoryReader = { return $emptyInventory }.GetNewClosure()
    $unexpectedCommandInvoker = {
        param($CommandText)
        throw "A registry command must not run without an accessible adapter: $CommandText"
    }
    $emptyResult = & $networkModule {
        param($InventoryReader, $Reader, $CommandInvoker)
        Invoke-BoostLabNetworkAdapterPowerWakeAction `
            -ActionName 'Apply' `
            -AdministratorChecker { return $true } `
            -AdapterEnumerator $InventoryReader `
            -RegistryReader $Reader `
            -RegistryCommandInvoker $CommandInvoker
    } $emptyInventoryReader $defaultReader $unexpectedCommandInvoker
    if (
        $emptyResult.Success -or
        $emptyResult.Data.CommandStatus -ne 'Not executed: no accessible adapters' -or
        $emptyResult.Data.VerificationStatus -ne 'Warning' -or
        @($emptyResult.Data.InaccessibleAdapterTargets).Count -ne 1
    ) {
        throw 'A fully inaccessible adapter inventory did not return a structured non-executing result.'
    }

    $applyCommands = [System.Collections.Generic.List[string]]::new()
    $applyCommandInvoker = {
        param($CommandText)
        $applyCommands.Add($CommandText)
    }.GetNewClosure()
    $inventoryReader = { return $inventory }.GetNewClosure()
    $applyResult = & $networkModule {
        param($InventoryReader, $Reader, $CommandInvoker)
        Invoke-BoostLabNetworkAdapterPowerWakeAction `
            -ActionName 'Apply' `
            -AdministratorChecker { return $true } `
            -AdapterEnumerator $InventoryReader `
            -RegistryReader $Reader `
            -RegistryCommandInvoker $CommandInvoker
    } $inventoryReader $applyReader $applyCommandInvoker
    if (
        -not $applyResult.Success -or
        $applyResult.Message -ne 'Network adapter power savings and wake disabled.' -or
        $applyResult.Data.CommandStatus -ne 'Completed' -or
        $applyResult.VerificationResult.Status -ne 'Passed' -or
        $applyCommands.Count -ne 15
    ) {
        throw 'Mocked Apply did not execute and verify the complete Ultimate sequence.'
    }

    $partialCommands = [System.Collections.Generic.List[string]]::new()
    $partialCommandInvoker = {
        param($CommandText)
        $partialCommands.Add($CommandText)
    }.GetNewClosure()
    $partialInventoryReader = { return $partialInventory }.GetNewClosure()
    $partialResult = & $networkModule {
        param($InventoryReader, $Reader, $CommandInvoker)
        Invoke-BoostLabNetworkAdapterPowerWakeAction `
            -ActionName 'Apply' `
            -AdministratorChecker { return $true } `
            -AdapterEnumerator $InventoryReader `
            -RegistryReader $Reader `
            -RegistryCommandInvoker $CommandInvoker
    } $partialInventoryReader $applyReader $partialCommandInvoker
    if (
        -not $partialResult.Success -or
        $partialResult.Data.AdapterEnumerationStatus -ne 'Warning' -or
        $partialResult.VerificationResult.Status -ne 'Warning' -or
        @($partialResult.Data.InaccessibleAdapterTargets).Count -ne 1 -or
        $partialCommands.Count -ne 15 -or
        $partialResult.Message -notmatch 'accessible adapters'
    ) {
        throw 'Partial adapter access did not continue safely with structured warnings.'
    }

    $defaultStates = @{}
    foreach ($definition in $valueDefinitions) {
        $defaultStates[$definition.Name] = [pscustomobject]@{
            ReadSucceeded = $true
            Exists        = $true
            Value         = if ($definition.Name -eq 'PnPCapabilities') { 24 } else { '0' }
            DisplayValue  = [string]$(if ($definition.Name -eq 'PnPCapabilities') { 24 } else { '0' })
            Message       = 'Mock adapter property exists before Default.'
        }
    }
    $mutableDefaultReader = {
        param($Path, $Name)
        $state = $defaultStates[$Name]
        if ($null -eq $state) {
            return [pscustomobject]@{
                ReadSucceeded = $true
                Exists        = $false
                Value         = $null
                DisplayValue  = 'Absent'
                Message       = 'Mock adapter property is absent.'
            }
        }

        return $state
    }.GetNewClosure()
    $defaultCommands = [System.Collections.Generic.List[string]]::new()
    $defaultCommandInvoker = {
        param($CommandText)
        $defaultCommands.Add($CommandText)
        if ($CommandText -match '/v "([^"]+)"') {
            $defaultStates.Remove($Matches[1])
        }
    }.GetNewClosure()
    $defaultResult = & $networkModule {
        param($InventoryReader, $Reader, $CommandInvoker)
        Invoke-BoostLabNetworkAdapterPowerWakeAction `
            -ActionName 'Default' `
            -AdministratorChecker { return $true } `
            -AdapterEnumerator $InventoryReader `
            -RegistryReader $Reader `
            -RegistryCommandInvoker $CommandInvoker
    } $inventoryReader $mutableDefaultReader $defaultCommandInvoker
    if (
        -not $defaultResult.Success -or
        $defaultResult.Message -ne 'Network adapter power savings and wake restored to default.' -or
        $defaultResult.Data.CommandStatus -ne 'Completed' -or
        $defaultResult.VerificationResult.Status -ne 'Passed' -or
        $defaultCommands.Count -ne 14 -or
        @($defaultResult.Data.RegistryOperationsSkipped).Count -ne 1
    ) {
        throw 'Mocked Default did not remove the 14 unique values and skip the repeated absent value.'
    }

    foreach ($result in @($applyResult, $defaultResult, $partialResult, $emptyResult)) {
        foreach ($field in @(
            'Success'
            'ToolId'
            'ToolTitle'
            'Action'
            'Message'
            'RestartRequired'
            'Cancelled'
            'Timestamp'
            'Data'
            'VerificationResult'
        )) {
            if ($null -eq $result.PSObject.Properties[$field]) {
                throw "Network Adapter Power Savings & Wake result is missing field: $field"
            }
        }
        foreach ($dataField in @(
            'AdapterEnumerationStatus'
            'CommandStatus'
            'VerificationStatus'
            'ExpectedAdapterPowerWakeState'
            'DetectedAdapterPowerWakeState'
            'AdapterNamesTargeted'
            'InaccessibleAdapterTargets'
            'RegistryValuesChecked'
            'PropertiesAppliedOrDefaulted'
            'InaccessibleOrUnsupportedProperties'
            'RegistryOperationsAttempted'
            'RegistryOperationsCompleted'
            'RegistryOperationsSkipped'
            'CompletedAt'
        )) {
            if ($null -eq $result.Data.PSObject.Properties[$dataField]) {
                throw "Network Adapter Power Savings & Wake result data is missing field: $dataField"
            }
        }
    }
}
finally {
    Remove-Module -ModuleInfo $networkModule -Force -ErrorAction SilentlyContinue
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    foreach ($actionName in @('Apply', 'Default')) {
        $plan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName $actionName -IsDryRun $false
        if (
            -not $plan.RequiresAdmin -or
            -not $plan.NeedsExplicitConfirmation -or
            -not $plan.Capabilities.CanModifyRegistry -or
            -not $plan.Capabilities.CanModifyDrivers -or
            $plan.CanReboot -or
            $plan.RequiresInternet -or
            $plan.UsesTrustedInstaller -or
            $plan.ConfirmationMessage -notmatch '14 approved' -or
            $plan.ConfirmationMessage -notmatch 'No adapter will be disabled' -or
            $plan.ConfirmationMessage -notmatch 'No restart is required'
        ) {
            throw "Network Adapter Power Savings & Wake $actionName Action Plan is incorrect."
        }
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredText in @(
    '''network-adapter-power-savings-wake'' = @{'
    '''Windows\NetworkAdapterPowerSavingsWake.psm1'''
    'Actions = @(''Apply'', ''Default'')'
    '$actionCommand.Parameters.ContainsKey(''Confirmed'')'
    'Test-BoostLabVerificationResult'
)) {
    if (-not $executionSource.Contains($requiredText)) {
        throw "Network Adapter Power Savings & Wake runtime mapping is missing: $requiredText"
    }
}

$uiSource = Get-Content -Raw -LiteralPath $uiPath
foreach ($requiredText in @(
    '$toolId -eq ''network-adapter-power-savings-wake'''
    '-Label ''Adapter enumeration status'''
    '-Label ''Command Status'''
    '-Label ''Verification Status'''
    '-Label ''Expected adapter power/wake state'''
    '-Label ''Detected adapter power/wake state'''
    '-Label ''Adapter names targeted'''
    '-Label ''Properties applied / defaulted'''
    '-Label ''Inaccessible adapter targets'''
    '-Label ''Inaccessible / unsupported properties'''
    '-Label ''Registry values / properties checked'''
    '-Label ''Timestamp'''
)) {
    if (-not $uiSource.Contains($requiredText)) {
        throw "Network Adapter Power Savings & Wake Latest Result rendering is missing: $requiredText"
    }
}

$record = Get-Content -Raw -LiteralPath $recordPath
foreach ($requiredText in @(
    'source-ultimate/6 Windows/19 Network Adapter Power Savings & Wake.ps1'
    $sourceHash
    'Approved by Yazan for Phase 23'
    $adapterClassPath
    'PnPCapabilities = 24'
    '*ModernStandbyWoLMagicPacket'
    'Default is idempotent'
    'CanModifyDrivers = true'
    '## Source-to-BoostLab Mapping Audit'
    '| Ultimate source | Ultimate registry value |'
    'Get-BoostLabNetworkAdapterReadOnlyDiscovery'
    'OpenSubKey(..., $false)'
    'No additional adapter property, DNS, TCP/IP, firewall, service'
    'Verification Strategy'
    'Automated tests must use static inspection and injected mocks only.'
)) {
    if (-not $record.Contains($requiredText)) {
        throw "Network Adapter Power Savings & Wake migration record is missing: $requiredText"
    }
}

$protectedModules = [ordered]@{
    'Signout LockScreen Wallpaper Black' = @{
        Path = Join-Path $modulesRoot 'Windows\SignoutLockScreenWallpaperBlack.psm1'
        Hash = 'FAE90C7491B3B72936D1D293D6435BF6893C8082DCEF4C6F6FDE5E1817F55D74'
        Required = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    'Context Menu' = @{
        Path = Join-Path $modulesRoot 'Windows\ContextMenu.psm1'
        Hash = '93325E76B02F80B1A105C83F6E268EA3652B4AB9F74582E759A4490CF30D1082'
        Required = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    'Start Menu Layout' = @{
        Path = Join-Path $modulesRoot 'Windows\StartMenuLayout.psm1'
        Hash = 'D93019267A3D566146F713DF69C86F41CDAD93A2B0786D5CB8DDF9F2878E103A'
        Required = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    'Theme Black' = @{
        Path = Join-Path $modulesRoot 'Windows\ThemeBlack.psm1'
        Hash = '29F3474D93061B01E3CF9F23EADA88E932E90E4984EBB39F7DB2BEB24732230F'
        Required = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    'GameBar' = @{
        Path = Join-Path $modulesRoot 'Windows\game-bar.psm1'
        Hash = 'E301B2AA588537B81CAB577DA51342FAFFFB7B452C2C36054BD269C51F10CC24'
        Required = 'ToolModule.Placeholder.ps1'
    }
    'Copilot' = @{
        Path = Join-Path $modulesRoot 'Windows\copilot.psm1'
        Hash = '740FEDE65972C413A7BF0938F3409AB683B45C914281BDDD6C25222FD39E617D'
        Required = 'ToolModule.Placeholder.ps1'
    }
    'GameMode' = @{
        Path = Join-Path $modulesRoot 'Windows\game-mode.psm1'
        Hash = 'CADEC6B0E4262990BF9D9BBDBD8DBA55EE910EEFC1FF72B78912800AD04624E9'
        Required = '$script:BoostLabImplementedActions = @(''Open'')'
    }
}
foreach ($name in $protectedModules.Keys) {
    $definition = $protectedModules[$name]
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $definition.Path).Hash -ne $definition.Hash) {
        throw "$name changed during Phase 23."
    }
    if (-not (Get-Content -Raw -LiteralPath $definition.Path).Contains([string]$definition.Required)) {
        throw "$name implementation status changed during Phase 23."
    }
}

$deletedToolNames = @(
    'Windows Activation Helper'
    'Firewall'
    'DEP'
    'File Download Security Warning'
    'MPO'
    'FSO'
    'FSE'
    'Hardware Flip'
    'AMD ULPS'
    'WHQL Secure Boot Bypass'
    'Keyboard Shortcuts'
    'Search Shell Mobsync'
    'NVME Faster Driver'
    'Core 1 Thread 1'
    'DDU'
    'UAC'
    'Scaling'
    'Start Menu Shortcuts'
    'Loudness EQ'
)
$normalizedDeletedNames = @(
    $deletedToolNames | ForEach-Object {
        ($_ -replace '[^a-zA-Z0-9]+', '-').Trim('-').ToLowerInvariant()
    }
)
$deletedModules = @(
    Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1' |
        Where-Object {
            [System.IO.Path]::GetFileNameWithoutExtension($_.Name).ToLowerInvariant() -in $normalizedDeletedNames
        }
)
if ($deletedModules.Count -gt 0) {
    throw "Deleted tool modules were found: $($deletedModules.FullName -join ', ')"
}

$allModules = @(
    Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1' |
        Where-Object { $_.Directory.Parent.FullName -eq $modulesRoot }
)
$implementedCount = @(
    $allModules | Where-Object {
        (Get-Content -Raw -LiteralPath $_.FullName).Contains('$script:BoostLabImplementedActions')
    }
).Count
$placeholderCount = @(
    $allModules | Where-Object {
        (Get-Content -Raw -LiteralPath $_.FullName).Contains('ToolModule.Placeholder.ps1')
    }
).Count
if ($implementedCount -ne 29 -or $placeholderCount -ne 19) {
    throw "Unexpected module counts: $implementedCount implemented, $placeholderCount placeholders."
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
        Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
        ForEach-Object {
            '{0}|{1}' -f `
                $_.FullName.Substring($root.Length + 1).Replace('\', '/'), `
                (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
        }
)
$sha256 = [System.Security.Cryptography.SHA256]::Create()
try {
    $sourceManifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n")))
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}
if (
    $sourceLines.Count -ne 49 -or
    $sourceManifestHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477'
) {
    throw 'source-ultimate content or paths changed.'
}

[pscustomobject]@{
    Success                  = $true
    ToolId                   = 'network-adapter-power-savings-wake'
    ImplementedActions       = @('Apply', 'Default')
    ApplyExecuted            = $false
    DefaultExecuted          = $false
    MockedApplyPassed        = $true
    MockedDefaultPassed      = $true
    VerificationCheckCount   = 14
    ImplementedModuleCount   = $implementedCount
    PlaceholderModuleCount   = $placeholderCount
    SourceUltimateUnchanged  = $true
    ProtectedModulesUnchanged = $true
    Message                  = 'Network Adapter Power Savings & Wake was validated with static inspection and mocks only.'
    Timestamp                = Get-Date
}
