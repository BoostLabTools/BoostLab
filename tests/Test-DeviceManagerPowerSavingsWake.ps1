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
        throw 'Unable to determine the Device Manager Power Savings & Wake test path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\device-manager-power-savings-wake.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\18 Device Manager Power Savings & Wake.ps1'
$recordPath = Join-Path $ProjectRoot 'docs\migrations\device-manager-power-savings-wake.md'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$sourceHash = 'FB543A5C6BD8F2FBEA5CD3069FD72DCDCCAB847D9E4753FD33BB0909843D209F'
$deviceClasses = @('ACPI', 'HID', 'PCI', 'USB')

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration['Stages'] | ForEach-Object { @($_['Tools']) })
$tool = $tools |
    Where-Object { $_['Id'] -eq 'device-manager-power-savings-wake' } |
    Select-Object -First 1
if ($null -eq $tool) {
    throw 'Device Manager Power Savings & Wake metadata is missing.'
}
if (
    [string]$tool['Stage'] -ne 'Windows' -or
    [int]$tool['Order'] -ne 18 -or
    [string]$tool['Type'] -ne 'action' -or
    [string]$tool['RiskLevel'] -ne 'medium' -or
    (@($tool['Actions']) -join ',') -ne 'Apply,Default'
) {
    throw 'Device Manager Power Savings & Wake metadata does not match Phase 26.'
}

$trueCapabilities = @(
    'RequiresAdmin'
    'CanModifyRegistry'
    'SupportsDefault'
    'NeedsExplicitConfirmation'
)
foreach ($field in $tool['Capabilities'].Keys) {
    if ([bool]$tool['Capabilities'][$field] -ne ($field -in $trueCapabilities)) {
        throw "Device Manager Power Savings & Wake capability is incorrect: $field"
    }
}

if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne $sourceHash) {
    throw 'Device Manager Power Savings & Wake Ultimate source hash changed.'
}
$source = Get-Content -Raw -LiteralPath $sourcePath
foreach ($requiredSourceText in @(
    'HKLM:\SYSTEM\ControlSet001\Enum\ACPI'
    'HKLM:\SYSTEM\ControlSet001\Enum\HID'
    'HKLM:\SYSTEM\ControlSet001\Enum\PCI'
    'HKLM:\SYSTEM\ControlSet001\Enum\USB'
    'EnhancedPowerManagementEnabled'
    'SeleactiveSuspendEnabled'
    'SelectiveSuspendEnabled'
    'SelectiveSuspendOn'
    'IdleInWorkingState'
    'WaitWakeEnabled'
)) {
    if (-not $source.Contains($requiredSourceText)) {
        throw "Ultimate source mapping text is missing: $requiredSourceText"
    }
}
if (
    ([regex]::Matches($source, '(?im)^\s*cmd /c "reg add ')).Count -ne 20 -or
    ([regex]::Matches($source, '(?im)^\s*cmd /c "reg delete ')).Count -ne 20
) {
    throw 'Ultimate source no longer contains the approved 20 Apply and 20 Default operations.'
}
foreach ($forbiddenText in @(
    'Disable-PnpDevice'
    'Enable-PnpDevice'
    'Uninstall-PnpDevice'
    'pnputil'
    'devcon'
    'dism /'
    'Remove-Item'
    'Remove-AppxPackage'
    'Invoke-WebRequest'
    'Start-BitsTransfer'
    'Stop-Service'
    'Set-Service'
    'Restart-Computer'
    'shutdown.exe'
    'TrustedInstaller'
    'safeboot'
)) {
    if ($source.Contains($forbiddenText)) {
        throw "Ultimate source failed the Phase 26 safety gate: $forbiddenText"
    }
}

$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredModuleText in @(
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    '$script:BoostLabDeviceClasses = @(''ACPI'', ''HID'', ''PCI'', ''USB'')'
    'function Test-BoostLabDeviceManagerRegistryTarget'
    'function Get-BoostLabDeviceManagerOperationBlueprint'
    'function Get-BoostLabDeviceManagerReadOnlyDiscovery'
    'function New-BoostLabDeviceManagerRegistryOperations'
    'function Test-BoostLabDeviceManagerPowerWakeState'
    'function Invoke-BoostLabDeviceManagerPowerWakeAction'
    'New-BoostLabVerificationResult'
    'NeedsExplicitConfirmation = $true'
    'CanModifyDrivers = $false'
)) {
    if (-not $moduleSource.Contains($requiredModuleText)) {
        throw "Device Manager module is missing: $requiredModuleText"
    }
}
foreach ($forbiddenModuleText in @(
    'Disable-PnpDevice'
    'Enable-PnpDevice'
    'Uninstall-PnpDevice'
    'pnputil'
    'devcon'
    'Remove-Item'
    'Remove-AppxPackage'
    'Invoke-WebRequest'
    'Start-BitsTransfer'
    'Stop-Service'
    'Set-Service'
    'Restart-Computer'
    'shutdown.exe'
    'UsesTrustedInstaller = $true'
    'safeboot'
    'ToolModule.Placeholder.ps1'
)) {
    if ($moduleSource.Contains($forbiddenModuleText)) {
        throw "Device Manager module contains prohibited behavior: $forbiddenModuleText"
    }
}
if ([regex]::IsMatch($moduleSource, 'reg delete "[^"]+"\s*/f')) {
    throw 'Device Manager module contains a registry-key delete without a value name.'
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredRuntimeText in @(
    "'device-manager-power-savings-wake' = @{"
    "Windows\device-manager-power-savings-wake.psm1"
    "Actions = @('Apply', 'Default')"
)) {
    if (-not $executionSource.Contains($requiredRuntimeText)) {
        throw "Execution runtime mapping is missing: $requiredRuntimeText"
    }
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
$toolModule = Import-Module -Name $modulePath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    $info = Get-BoostLabToolInfo
    if (
        $info.Id -ne 'device-manager-power-savings-wake' -or
        (@($info.Actions) -join ',') -ne 'Apply,Default' -or
        (@($info.ImplementedActions) -join ',') -ne 'Apply,Default'
    ) {
        throw 'Implemented module metadata is incorrect.'
    }

    foreach ($actionName in @('Apply', 'Default')) {
        $plan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName $actionName -IsDryRun $false
        if (
            -not [bool]$plan.RequiresAdmin -or
            -not [bool]$plan.NeedsExplicitConfirmation -or
            -not [bool]$plan.Capabilities.CanModifyRegistry
        ) {
            throw "$actionName Action Plan is missing Administrator, registry, or confirmation requirements."
        }
    }

    $applyBlueprint = @(& $toolModule {
        Get-BoostLabDeviceManagerOperationBlueprint -ActionName Apply
    })
    $defaultBlueprint = @(& $toolModule {
        Get-BoostLabDeviceManagerOperationBlueprint -ActionName Default
    })
    if ($applyBlueprint.Count -ne 20 -or $defaultBlueprint.Count -ne 20) {
        throw 'Apply or Default blueprint does not preserve the 20 source operations.'
    }

    $expectedApplyNames = @(
        'ACPI|Device Parameters|EnhancedPowerManagementEnabled'
        'ACPI|Device Parameters|SeleactiveSuspendEnabled'
        'ACPI|Device Parameters|SelectiveSuspendOn'
        'ACPI|WDF|IdleInWorkingState'
        'HID|Device Parameters|EnhancedPowerManagementEnabled'
        'HID|Device Parameters|SelectiveSuspendEnabled'
        'HID|Device Parameters|SelectiveSuspendOn'
        'HID|WDF|IdleInWorkingState'
        'PCI|Device Parameters|EnhancedPowerManagementEnabled'
        'PCI|Device Parameters|SelectiveSuspendEnabled'
        'PCI|Device Parameters|SelectiveSuspendOn'
        'PCI|WDF|IdleInWorkingState'
        'USB|Device Parameters|EnhancedPowerManagementEnabled'
        'USB|Device Parameters|SelectiveSuspendEnabled'
        'USB|Device Parameters|SelectiveSuspendOn'
        'USB|WDF|IdleInWorkingState'
        'ACPI|Device Parameters|WaitWakeEnabled'
        'HID|Device Parameters|WaitWakeEnabled'
        'PCI|Device Parameters|WaitWakeEnabled'
        'USB|Device Parameters|WaitWakeEnabled'
    )
    $expectedDefaultNames = @(
        $expectedApplyNames | ForEach-Object {
            if ($_ -match '^(HID|PCI|USB)\|Device Parameters\|SelectiveSuspendEnabled$') {
                $_ -replace 'SelectiveSuspendEnabled$', 'SeleactiveSuspendEnabled'
            }
            else {
                $_
            }
        }
    )
    $actualApplyNames = @($applyBlueprint | ForEach-Object { "$($_.ClassName)|$($_.LeafName)|$($_.Name)" })
    $actualDefaultNames = @($defaultBlueprint | ForEach-Object { "$($_.ClassName)|$($_.LeafName)|$($_.Name)" })
    if (($actualApplyNames -join "`n") -ne ($expectedApplyNames -join "`n")) {
        throw 'Apply operation order or source mapping changed.'
    }
    if (($actualDefaultNames -join "`n") -ne ($expectedDefaultNames -join "`n")) {
        throw 'Default operation order or source spelling behavior changed.'
    }

    $targets = @(
        foreach ($className in $deviceClasses) {
            foreach ($leafName in @('Device Parameters', 'WDF')) {
                $subPath = "SYSTEM\ControlSet001\Enum\$className\MOCK0001\$leafName"
                [pscustomobject]@{
                    ClassName = $className
                    LeafName = $leafName
                    RegistryPath = "HKEY_LOCAL_MACHINE\$subPath"
                    ProviderPath = "Registry::HKEY_LOCAL_MACHINE\$subPath"
                    RegistrySubPath = $subPath
                }
            }
        }
    )
    $inventory = [pscustomobject]@{
        Succeeded = $true
        EnumerationStatus = 'Completed'
        Targets = $targets
        Warnings = @()
        Message = 'Eight mocked device registry targets detected.'
    }

    $state = @{}
    $commands = [System.Collections.Generic.List[string]]::new()
    $enumerator = { $inventory }.GetNewClosure()
    $reader = {
        param($RegistrySubPath, $Name)
        $key = ('{0}|{1}' -f $RegistrySubPath, $Name).ToLowerInvariant()
        if ($state.ContainsKey($key)) {
            $value = $state[$key]
            [pscustomobject]@{
                ReadSucceeded = $true
                Exists = $true
                Value = $value
                DisplayValue = if ($value -is [byte[]]) {
                    ($value | ForEach-Object { $_.ToString('X2') }) -join ''
                }
                else {
                    [string]$value
                }
                Message = 'Mock value detected.'
            }
        }
        else {
            [pscustomobject]@{
                ReadSucceeded = $true
                Exists = $false
                Value = $null
                DisplayValue = 'Absent'
                Message = 'Mock value is absent.'
            }
        }
    }.GetNewClosure()
    $invoker = {
        param($CommandText)
        $commands.Add($CommandText)
        $addMatch = [regex]::Match(
            $CommandText,
            '^reg add "(?<Path>[^"]+)" /v "(?<Name>[^"]+)" /t (?<Type>\S+) /d "(?<Data>[^"]*)" /f$'
        )
        if ($addMatch.Success) {
            $subPath = $addMatch.Groups['Path'].Value.Substring('HKEY_LOCAL_MACHINE\'.Length)
            $key = ('{0}|{1}' -f $subPath, $addMatch.Groups['Name'].Value).ToLowerInvariant()
            if ($addMatch.Groups['Type'].Value -eq 'REG_BINARY') {
                $binaryValue = [byte[]]::new(1)
                $binaryValue[0] = 0
                $state[$key] = $binaryValue
            }
            else {
                $state[$key] = [int]$addMatch.Groups['Data'].Value
            }
            return
        }

        $deleteMatch = [regex]::Match(
            $CommandText,
            '^reg delete "(?<Path>[^"]+)" /v "(?<Name>[^"]+)" /f$'
        )
        if ($deleteMatch.Success) {
            $subPath = $deleteMatch.Groups['Path'].Value.Substring('HKEY_LOCAL_MACHINE\'.Length)
            $key = ('{0}|{1}' -f $subPath, $deleteMatch.Groups['Name'].Value).ToLowerInvariant()
            [void]$state.Remove($key)
            return
        }

        throw "Unexpected mocked command: $CommandText"
    }.GetNewClosure()

    $applyResult = & $toolModule {
        param($Enumerator, $Reader, $Invoker)
        Invoke-BoostLabDeviceManagerPowerWakeAction `
            -ActionName Apply `
            -AdministratorChecker { $true } `
            -DeviceEnumerator $Enumerator `
            -RegistryReader $Reader `
            -RegistryCommandInvoker $Invoker
    } $enumerator $reader $invoker
    if (
        -not $applyResult.Success -or
        $applyResult.VerificationResult.Status -ne 'Passed' -or
        $applyResult.Data.CommandStatus -ne 'Completed' -or
        $commands.Count -ne 20
    ) {
        throw (
            'Mocked Apply failed: Success={0}; CommandStatus={1}; VerificationStatus={2}; Commands={3}; Message={4}' -f `
                $applyResult.Success, `
                $applyResult.Data.CommandStatus, `
                $applyResult.VerificationResult.Status, `
                $commands.Count, `
                (
                    '{0}; Checks={1}' -f `
                        $applyResult.Message, `
                        (
                            @(
                                $applyResult.VerificationResult.Checks |
                                    Where-Object { $_.Status -ne 'Passed' } |
                                    ForEach-Object {
                                        '{0} expected={1} actual={2} status={3}' -f `
                                            $_.Name, $_.Expected, $_.Actual, $_.Status
                                    }
                            ) -join ' | '
                        )
                )
        )
    }

    $acpiTypoKey = 'system\controlset001\enum\acpi\mock0001\device parameters|seleactivesuspendenabled'
    $hidCorrectKey = 'system\controlset001\enum\hid\mock0001\device parameters|selectivesuspendenabled'
    $hidTypoKey = 'system\controlset001\enum\hid\mock0001\device parameters|seleactivesuspendenabled'
    if (
        -not $state.ContainsKey($acpiTypoKey) -or
        -not $state.ContainsKey($hidCorrectKey) -or
        $state.ContainsKey($hidTypoKey)
    ) {
        throw 'Mocked Apply did not preserve the Ultimate selective-suspend spelling behavior.'
    }

    $commands.Clear()
    $defaultResult = & $toolModule {
        param($Enumerator, $Reader, $Invoker)
        Invoke-BoostLabDeviceManagerPowerWakeAction `
            -ActionName Default `
            -AdministratorChecker { $true } `
            -DeviceEnumerator $Enumerator `
            -RegistryReader $Reader `
            -RegistryCommandInvoker $Invoker
    } $enumerator $reader $invoker
    if (
        -not $defaultResult.Success -or
        $defaultResult.VerificationResult.Status -ne 'Passed' -or
        $commands.Count -ne 17 -or
        @($defaultResult.Data.SkippedItems).Count -ne 3
    ) {
        throw 'Mocked Default did not preserve the source removals and spelling asymmetry.'
    }
    foreach ($className in @('hid', 'pci', 'usb')) {
        $correctKey = "system\controlset001\enum\$className\mock0001\device parameters|selectivesuspendenabled"
        if (-not $state.ContainsKey($correctKey)) {
            throw "Default incorrectly removed the source-untargeted correctly spelled value for $className."
        }
    }

    $commands.Clear()
    $idempotentDefault = & $toolModule {
        param($Enumerator, $Reader, $Invoker)
        Invoke-BoostLabDeviceManagerPowerWakeAction `
            -ActionName Default `
            -AdministratorChecker { $true } `
            -DeviceEnumerator $Enumerator `
            -RegistryReader $Reader `
            -RegistryCommandInvoker $Invoker
    } $enumerator $reader $invoker
    if (
        -not $idempotentDefault.Success -or
        $idempotentDefault.Data.CommandStatus -ne 'Already default' -or
        $commands.Count -ne 0 -or
        @($idempotentDefault.Data.SkippedItems).Count -ne 20
    ) {
        throw 'Repeated Default is not idempotent.'
    }

    $warningInventory = [pscustomobject]@{
        Succeeded = $true
        EnumerationStatus = 'Warning'
        Targets = @()
        Warnings = @('USB device class root was not found.')
        Message = 'No matching device power-management registry targets were found.'
    }
    $warningEnumerator = { $warningInventory }.GetNewClosure()
    $warningResult = & $toolModule {
        param($Enumerator, $Reader, $Invoker)
        Invoke-BoostLabDeviceManagerPowerWakeAction `
            -ActionName Apply `
            -AdministratorChecker { $true } `
            -DeviceEnumerator $Enumerator `
            -RegistryReader $Reader `
            -RegistryCommandInvoker $Invoker
    } $warningEnumerator $reader $invoker
    if (
        -not $warningResult.Success -or
        $warningResult.VerificationResult.Status -ne 'Warning' -or
        $warningResult.Data.CommandStatus -notmatch '^Not applicable'
    ) {
        throw 'Missing optional device classes were not handled as Warning/NotApplicable.'
    }

    $failingInvoker = { param($CommandText) throw 'Mock registry command failed.' }
    $failedResult = & $toolModule {
        param($Enumerator, $Reader, $Invoker)
        Invoke-BoostLabDeviceManagerPowerWakeAction `
            -ActionName Apply `
            -AdministratorChecker { $true } `
            -DeviceEnumerator $Enumerator `
            -RegistryReader $Reader `
            -RegistryCommandInvoker $Invoker
    } $enumerator $reader $failingInvoker
    if (
        $failedResult.Success -or
        $failedResult.Data.CommandStatus -ne 'Completed with errors' -or
        @($failedResult.Data.Errors).Count -eq 0
    ) {
        throw 'Unexpected registry command errors were hidden or not structured.'
    }

    $maliciousInventory = [pscustomobject]@{
        Targets = @(
            [pscustomobject]@{
                ClassName = 'USB'
                LeafName = 'Device Parameters'
                RegistryPath = 'HKEY_LOCAL_MACHINE\SOFTWARE\OutOfScope\Device Parameters'
                RegistrySubPath = 'SOFTWARE\OutOfScope\Device Parameters'
            }
        )
    }
    $rejected = $false
    try {
        & $toolModule {
            param($Inventory)
            New-BoostLabDeviceManagerRegistryOperations -ActionName Apply -Inventory $Inventory
        } $maliciousInventory | Out-Null
    }
    catch {
        $rejected = $true
    }
    if (-not $rejected) {
        throw 'Out-of-scope registry target was not rejected.'
    }
}
finally {
    Remove-Module -ModuleInfo $toolModule -Force -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$record = Get-Content -Raw -LiteralPath $recordPath
foreach ($requiredRecordText in @(
    $sourceHash
    'Source-to-BoostLab Mapping'
    'Device Registry Safety Policy'
    'Exact source asymmetry preserved'
    'Default is idempotent'
    'No additional class, leaf name, registry value, driver command'
    'Automated tests must use static inspection and injected mocks only.'
)) {
    if (-not $record.Contains($requiredRecordText)) {
        throw "Device Manager migration record is missing: $requiredRecordText"
    }
}

$protectedHashes = [ordered]@{
    'modules\Windows\PowerPlan.psm1' = '74437292978C6C0B7EEBFC60099A1361F79C8EBC72E14256990169A1B73DE028'
    'modules\Windows\NetworkAdapterPowerSavingsWake.psm1' = '74844D91EC7E03817FB9D9D440CDBC2798DE19D68DDAB74C351E8A354F21E163'
    'modules\Windows\SignoutLockScreenWallpaperBlack.psm1' = 'FAE90C7491B3B72936D1D293D6435BF6893C8082DCEF4C6F6FDE5E1817F55D74'
    'modules\Windows\ContextMenu.psm1' = '93325E76B02F80B1A105C83F6E268EA3652B4AB9F74582E759A4490CF30D1082'
    'modules\Windows\StartMenuLayout.psm1' = 'D93019267A3D566146F713DF69C86F41CDAD93A2B0786D5CB8DDF9F2878E103A'
    'modules\Windows\ThemeBlack.psm1' = '29F3474D93061B01E3CF9F23EADA88E932E90E4984EBB39F7DB2BEB24732230F'
    'modules\Windows\sound.psm1' = 'B20CBF149CDAA562011AABD05D5828100D0B3810A565A4B7E305EBD50C91FDE3'
    'modules\Windows\game-bar.psm1' = 'E301B2AA588537B81CAB577DA51342FAFFFB7B452C2C36054BD269C51F10CC24'
    'modules\Windows\copilot.psm1' = '740FEDE65972C413A7BF0938F3409AB683B45C914281BDDD6C25222FD39E617D'
    'modules\Windows\game-mode.psm1' = 'CADEC6B0E4262990BF9D9BBDBD8DBA55EE910EEFC1FF72B78912800AD04624E9'
    'modules\Windows\control-panel-settings.psm1' = '6B02392A74AEF177C3249F0A686E48D418693A683F36A7F4C3E9C7BF764941BE'
    'modules\Setup\edge-settings.psm1' = '6EE32C25D17D797AAC2BF79D5941BADE098F0D15A2C2927A1E093F4F047DC878'
    'modules\Windows\cleanup.psm1' = '4E5F8DD0068E4291B1BA813B98B2E6C6D593DC0500B62F57D7C77BB1A1F973DF'
}
foreach ($relativePath in $protectedHashes.Keys) {
    $path = Join-Path $ProjectRoot $relativePath
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash -ne $protectedHashes[$relativePath]) {
        throw "Protected file changed during Phase 26: $relativePath"
    }
}

foreach ($placeholderPath in @(
    'modules\Windows\game-bar.psm1'
    'modules\Windows\copilot.psm1'
    'modules\Windows\control-panel-settings.psm1'
    'modules\Setup\edge-settings.psm1'
    'modules\Windows\cleanup.psm1'
)) {
    if (-not (Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot $placeholderPath)).Contains('ToolModule.Placeholder.ps1')) {
        throw "Protected placeholder changed: $placeholderPath"
    }
}

$moduleFiles = @(
    Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1' |
        Where-Object { $_.Directory.Parent.FullName -eq $modulesRoot }
)
$implementedCount = @(
    $moduleFiles | Where-Object {
        (Get-Content -Raw -LiteralPath $_.FullName).Contains('$script:BoostLabImplementedActions')
    }
).Count
$placeholderCount = @(
    $moduleFiles | Where-Object {
        (Get-Content -Raw -LiteralPath $_.FullName).Contains('ToolModule.Placeholder.ps1')
    }
).Count
if ($tools.Count -ne 48 -or $implementedCount -ne 30 -or $placeholderCount -ne 18) {
    throw "Unexpected Phase 26 inventory: $($tools.Count) tools, $implementedCount implemented, $placeholderCount placeholders."
}

if (
    @($tools | Where-Object { $_['Id'] -eq 'loudness-eq' }).Count -ne 0 -or
    (Test-Path -LiteralPath (Join-Path $ProjectRoot 'modules\Windows\loudness-eq.psm1')) -or
    (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'))
) {
    throw 'Loudness EQ was reintroduced.'
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
        ForEach-Object {
            '{0}|{1}' -f `
                $_.FullName.Substring($root.Length + 1).Replace('\', '/'), `
                (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
        }
)
$sha256 = [Security.Cryptography.SHA256]::Create()
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
    throw 'source-ultimate changed during Phase 26.'
}

[pscustomobject]@{
    Success = $true
    SourceSHA256 = $sourceHash
    ApplyOperationCount = 20
    DefaultOperationCount = 20
    MockedApplyPassed = $true
    MockedDefaultPassed = $true
    IdempotentDefaultPassed = $true
    ImplementedModuleCount = $implementedCount
    PlaceholderModuleCount = $placeholderCount
    ActiveToolCount = $tools.Count
    ProtectedFilesUnchanged = $true
    Message = 'Device Manager Power Savings & Wake passed static and mocked Phase 26 validation.'
}

