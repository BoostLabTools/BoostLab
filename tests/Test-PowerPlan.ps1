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
        throw 'Unable to determine the Power Plan test script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\PowerPlan.psm1'
$legacyModulePath = Join-Path $ProjectRoot 'modules\Windows\power-plan.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\21 Power Plan.ps1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$recordPath = Join-Path $ProjectRoot 'docs\migrations\power-plan.md'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$sourceHash = '97CD584B1713809466E372B70434F06FFABC10DE0C4C4F67AF4212B5892DAC56'
$ultimateGuid = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
$boostLabGuid = '99999999-9999-9999-9999-999999999999'
$balancedGuid = '381b4222-f694-41f0-9685-ff5bb260df2e'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration['Stages'] | ForEach-Object { @($_['Tools']) })
$tool = $tools | Where-Object { $_['Id'] -eq 'power-plan' } | Select-Object -First 1
if ($null -eq $tool) {
    throw 'Power Plan metadata is missing.'
}
if (
    [string]$tool['Stage'] -ne 'Windows' -or
    [int]$tool['Order'] -ne 21 -or
    [string]$tool['Type'] -ne 'action' -or
    [string]$tool['RiskLevel'] -ne 'medium' -or
    (@($tool['Actions']) -join ',') -ne 'Apply,Default'
) {
    throw 'Power Plan stage, order, type, risk, or actions are incorrect.'
}
$expectedTrueCapabilities = @(
    'RequiresAdmin'
    'CanModifyRegistry'
    'SupportsDefault'
    'NeedsExplicitConfirmation'
)
foreach ($field in $tool['Capabilities'].Keys) {
    if ([bool]$tool['Capabilities'][$field] -ne ($field -in $expectedTrueCapabilities)) {
        throw "Power Plan capability '$field' is incorrect."
    }
}

if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne $sourceHash) {
    throw 'Power Plan Ultimate source hash changed.'
}
$source = Get-Content -Raw -LiteralPath $sourcePath
foreach ($requiredText in @(
    "powercfg /duplicatescheme $ultimateGuid $boostLabGuid"
    "powercfg /SETACTIVE $boostLabGuid"
    'powercfg /L'
    'powercfg /delete $plan'
    'powercfg /hibernate off'
    'powercfg -restoredefaultschemes'
    'powercfg /hibernate on'
    'Start-Process powercfg.cpl'
    'HibernateEnabled'
    'HibernateEnabledDefault'
    'ShowLockOption'
    'ShowSleepOption'
    'HiberbootEnabled'
    'PowerThrottlingOff'
)) {
    if (-not $source.Contains($requiredText)) {
        throw "Power Plan source no longer contains: $requiredText"
    }
}
foreach ($forbiddenSourceText in @(
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'Disable-PnpDevice'
    'Uninstall-PnpDevice'
    'pnputil'
    'devcon'
    'TrustedInstaller'
    'safeboot'
    'Restart-Computer'
    'shutdown.exe'
    'Set-Service'
    'Stop-Service'
    'Remove-AppxPackage'
    'Set-MpPreference'
)) {
    if ($source.Contains($forbiddenSourceText)) {
        throw "Power Plan source failed the Phase 24 safety gate: $forbiddenSourceText"
    }
}

if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
    throw 'The canonical Power Plan module is missing.'
}
if ($legacyModulePath -cne $modulePath -and (Test-Path -LiteralPath $legacyModulePath -PathType Leaf)) {
    throw 'The old Power Plan placeholder path still exists.'
}
$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredText in @(
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    "`$script:BoostLabUltimateSchemeGuid = '$ultimateGuid'"
    "`$script:BoostLabPowerSchemeGuid = '$boostLabGuid'"
    "`$script:BoostLabBalancedSchemeGuid = '$balancedGuid'"
    '$script:BoostLabPowerSettingDefinitions'
    '$script:BoostLabApplyRegistryOperations'
    '$script:BoostLabDefaultRegistryOperations'
    'function Test-BoostLabPowerPlanState'
    'function Invoke-BoostLabPowerPlanAction'
    '/duplicatescheme'
    '/setactive'
    '/delete'
    '-restoredefaultschemes'
    '/hibernate'
    'Start-Process ''powercfg.cpl'''
    'New-BoostLabVerificationResult'
    '-VerificationResult $verification'
    '[bool]$Confirmed = $false'
)) {
    if (-not $moduleSource.Contains($requiredText)) {
        throw "Power Plan module is missing: $requiredText"
    }
}
foreach ($forbiddenModuleText in @(
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'Disable-PnpDevice'
    'Uninstall-PnpDevice'
    'pnputil'
    'devcon'
    'Restart-Computer'
    'Stop-Computer'
    'shutdown.exe'
    'Set-Service'
    'Stop-Service'
    'Restart-Service'
    'Remove-AppxPackage'
    'UsesTrustedInstaller = $true'
    'UsesSafeMode = $true'
)) {
    if ($moduleSource.Contains($forbiddenModuleText)) {
        throw "Power Plan module contains forbidden behavior: $forbiddenModuleText"
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
    throw "Power Plan module syntax error: $($parseErrors[0].Message)"
}
$commands = @(
    $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
        $true
    ) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }
)
foreach ($forbiddenCommand in @(
    'Invoke-WebRequest'
    'Start-BitsTransfer'
    'Disable-PnpDevice'
    'Uninstall-PnpDevice'
    'Restart-Computer'
    'Stop-Computer'
    'Set-Service'
    'Stop-Service'
    'Restart-Service'
    'Remove-AppxPackage'
)) {
    if ($forbiddenCommand -in $commands) {
        throw "Power Plan contains forbidden command: $forbiddenCommand"
    }
}

$sourceSettingCommands = [System.Collections.Generic.List[object]]::new()
foreach ($line in Get-Content -LiteralPath $sourcePath) {
    if ($line -match '^powercfg /set(?<Mode>ac|dc)valueindex\s+(?<Scheme>\S+)\s+(?<Subgroup>\S+)\s+(?<Setting>\S+)\s+(?<Value>\S+)') {
        $sourceSettingCommands.Add([pscustomobject]@{
            Mode = $Matches.Mode.ToLowerInvariant()
            Scheme = $Matches.Scheme.ToLowerInvariant()
            Subgroup = $Matches.Subgroup.ToLowerInvariant()
            Setting = $Matches.Setting.ToLowerInvariant()
            Value = $Matches.Value
        })
    }
}
if ($sourceSettingCommands.Count -ne 72) {
    throw "Ultimate Power Plan no longer contains 72 setting commands: $($sourceSettingCommands.Count)"
}

$powerModule = Import-Module -Name $modulePath -Force -PassThru -Prefix 'PowerPlanTest' -Scope Local -DisableNameChecking -ErrorAction Stop
try {
    $toolInfo = & (Get-Command -Name 'Get-PowerPlanTestBoostLabToolInfo' -Module $powerModule.Name -ErrorAction Stop)
    if (
        $toolInfo.Id -ne 'power-plan' -or
        (@($toolInfo.Actions) -join ',') -ne 'Apply,Default' -or
        (@($toolInfo.ImplementedActions) -join ',') -ne 'Apply,Default'
    ) {
        throw 'Power Plan exported metadata is incorrect.'
    }

    $definitions = @(& $powerModule { $script:BoostLabPowerSettingDefinitions })
    if ($definitions.Count -ne 36) {
        throw "Power Plan must contain 36 source setting definitions: $($definitions.Count)"
    }
    for ($index = 0; $index -lt $definitions.Count; $index++) {
        $definition = $definitions[$index]
        $sourceAC = $sourceSettingCommands[$index * 2]
        $sourceDC = $sourceSettingCommands[($index * 2) + 1]
        if (
            $sourceAC.Mode -ne 'ac' -or
            $sourceDC.Mode -ne 'dc' -or
            $sourceAC.Scheme -ne $boostLabGuid -or
            $sourceDC.Scheme -ne $boostLabGuid -or
            $definition.Subgroup -ne $sourceAC.Subgroup -or
            $definition.Subgroup -ne $sourceDC.Subgroup -or
            $definition.Setting -ne $sourceAC.Setting -or
            $definition.Setting -ne $sourceDC.Setting -or
            [string]$definition.AC -ne $sourceAC.Value -or
            [string]$definition.DC -ne $sourceDC.Value
        ) {
            throw "Power setting definition $index no longer matches Ultimate."
        }
    }

    $applyRegistryDefinitions = @(& $powerModule { $script:BoostLabApplyRegistryOperations })
    $defaultRegistryDefinitions = @(& $powerModule { $script:BoostLabDefaultRegistryOperations })
    $attributeDefinitions = @($definitions | Where-Object { $_.PSObject.Properties['AttributePath'] })
    if (
        $applyRegistryDefinitions.Count -ne 6 -or
        $defaultRegistryDefinitions.Count -ne 5 -or
        $attributeDefinitions.Count -ne 4
    ) {
        throw 'Power Plan registry definition counts no longer match Ultimate.'
    }
    foreach ($definition in $applyRegistryDefinitions) {
        if (-not $source.Contains([string]$definition.Path) -or -not $source.Contains([string]$definition.Name)) {
            throw "Power Plan contains an Apply registry write outside Ultimate: $($definition.Path)\$($definition.Name)"
        }
    }
    foreach ($definition in $defaultRegistryDefinitions) {
        if (-not $source.Contains([string]$definition.Path)) {
            throw "Power Plan contains a Default registry operation outside Ultimate: $($definition.Path)"
        }
        if (-not [string]::IsNullOrWhiteSpace([string]$definition.Name) -and -not $source.Contains([string]$definition.Name)) {
            throw "Power Plan contains a Default registry value outside Ultimate: $($definition.Name)"
        }
    }
    foreach ($definition in $attributeDefinitions) {
        if (-not $source.Contains([string]$definition.AttributePath)) {
            throw "Power Plan contains an Attributes path outside Ultimate: $($definition.AttributePath)"
        }
    }

    $newRegistryReader = {
        param([object[]]$VerificationDefinitions)
        $states = @{}
        foreach ($definition in $VerificationDefinitions) {
            $states["$($definition.SubPath)|$($definition.Name)"] = [pscustomobject]@{
                ReadSucceeded = $true
                Exists = [bool]$definition.ExpectedExists
                Value = $definition.ExpectedValue
                DisplayValue = if ($definition.ExpectedExists) { [string]$definition.ExpectedValue } else { 'Absent' }
                Message = 'Mock expected registry state.'
            }
        }
        return {
            param($SubPath, $Name)
            return $states["$SubPath|$Name"]
        }.GetNewClosure()
    }
    $newPowerSettingReader = {
        param([object[]]$SettingDefinitions, [string[]]$UnsupportedSettings = @(), [string]$FailedSetting = '')
        $states = @{}
        foreach ($definition in $SettingDefinitions) {
            $key = "$($definition.Subgroup)|$($definition.Setting)"
            $ac = & $powerModule { param($Value) ConvertTo-BoostLabPowerIndex -Value $Value } ([string]$definition.AC)
            $dc = & $powerModule { param($Value) ConvertTo-BoostLabPowerIndex -Value $Value } ([string]$definition.DC)
            $states[$key] = [pscustomobject]@{
                Succeeded = $true
                Supported = $key -notin @($UnsupportedSettings)
                ACValue = if ($key -eq $FailedSetting) { $ac + 1 } else { $ac }
                DCValue = $dc
                Message = if ($key -in @($UnsupportedSettings)) { 'Mock setting is unsupported.' } else { 'Mock setting detected.' }
            }
        }
        return {
            param($SchemeGuid, $SubgroupGuid, $SettingGuid)
            return $states["$SubgroupGuid|$SettingGuid"]
        }.GetNewClosure()
    }

    $applyRegistryVerification = @(& $powerModule { Get-BoostLabPowerPlanRegistryVerificationDefinitions -ActionName 'Apply' })
    $defaultRegistryVerification = @(& $powerModule { Get-BoostLabPowerPlanRegistryVerificationDefinitions -ActionName 'Default' })
    $applyRegistryReader = & $newRegistryReader $applyRegistryVerification
    $defaultRegistryReader = & $newRegistryReader $defaultRegistryVerification
    $applySettingReader = & $newPowerSettingReader $definitions
    $applyFinalInventory = {
        return [pscustomobject]@{
            Succeeded = $true
            ActiveGuid = $boostLabGuid
            Plans = @([pscustomobject]@{ Guid = $boostLabGuid; IsActive = $true })
            Message = 'Mock BoostLab scheme active.'
        }
    }.GetNewClosure()
    $defaultFinalInventory = {
        return [pscustomobject]@{
            Succeeded = $true
            ActiveGuid = $balancedGuid
            Plans = @([pscustomobject]@{ Guid = $balancedGuid; IsActive = $true })
            Message = 'Mock Balanced scheme active.'
        }
    }.GetNewClosure()

    $applyVerification = & $powerModule {
        param($PlanReader, $SettingReader, $RegistryReader)
        Test-BoostLabPowerPlanState -ActionName 'Apply' -PlanInventoryReader $PlanReader -PowerSettingReader $SettingReader -RegistryReader $RegistryReader
    } $applyFinalInventory $applySettingReader $applyRegistryReader
    if ($applyVerification.Status -ne 'Passed' -or @($applyVerification.Checks).Count -ne 47) {
        throw 'Mocked Power Plan Apply verification did not pass all plan, setting, and registry checks.'
    }

    $unsupportedKey = "$($definitions[0].Subgroup)|$($definitions[0].Setting)"
    $unsupportedReader = & $newPowerSettingReader $definitions $unsupportedKey
    $unsupportedVerification = & $powerModule {
        param($PlanReader, $SettingReader, $RegistryReader)
        Test-BoostLabPowerPlanState -ActionName 'Apply' -PlanInventoryReader $PlanReader -PowerSettingReader $SettingReader -RegistryReader $RegistryReader
    } $applyFinalInventory $unsupportedReader $applyRegistryReader
    if ($unsupportedVerification.Status -ne 'Warning') {
        throw 'An unsupported Power Plan setting was not reported as Warning.'
    }

    $failedKey = "$($definitions[1].Subgroup)|$($definitions[1].Setting)"
    $failedReader = & $newPowerSettingReader $definitions '' $failedKey
    $failedVerification = & $powerModule {
        param($PlanReader, $SettingReader, $RegistryReader)
        Test-BoostLabPowerPlanState -ActionName 'Apply' -PlanInventoryReader $PlanReader -PowerSettingReader $SettingReader -RegistryReader $RegistryReader
    } $applyFinalInventory $failedReader $applyRegistryReader
    if ($failedVerification.Status -ne 'Failed') {
        throw 'A contradictory Power Plan setting was not reported as Failed.'
    }

    $defaultVerification = & $powerModule {
        param($PlanReader, $RegistryReader)
        Test-BoostLabPowerPlanState -ActionName 'Default' -PlanInventoryReader $PlanReader -PowerSettingReader { throw 'Default must not invent setting indexes.' } -RegistryReader $RegistryReader
    } $defaultFinalInventory $defaultRegistryReader
    if ($defaultVerification.Status -ne 'Passed' -or @($defaultVerification.Checks).Count -ne 12) {
        throw 'Mocked Power Plan Default verification is incorrect.'
    }

    $applyEvents = [System.Collections.Generic.List[string]]::new()
    $applyPowerCommands = [System.Collections.Generic.List[string]]::new()
    $applyRegistryCommands = [System.Collections.Generic.List[string]]::new()
    $applyPowerInvoker = {
        param($Arguments)
        $command = @($Arguments) -join ' '
        $applyPowerCommands.Add($command)
        $applyEvents.Add("Power:$command")
        $isExpectedActiveDeleteFailure = (
            $Arguments[0] -eq '/delete' -and
            $Arguments[1] -eq $boostLabGuid
        )
        return [pscustomobject]@{
            Succeeded = -not $isExpectedActiveDeleteFailure
            ExitCode = if ($isExpectedActiveDeleteFailure) { 1 } else { 0 }
            Output = @()
            Message = if ($isExpectedActiveDeleteFailure) { 'The active plan cannot be deleted.' } else { 'Mock powercfg completed.' }
        }
    }.GetNewClosure()
    $applyRegistryInvoker = {
        param($Arguments)
        $command = @($Arguments) -join ' '
        $applyRegistryCommands.Add($command)
        $applyEvents.Add("Registry:$command")
        return [pscustomobject]@{ Succeeded = $true; ExitCode = 0; Output = @(); Message = 'Mock reg completed.' }
    }.GetNewClosure()
    $initialInventory = {
        return [pscustomobject]@{
            Succeeded = $true
            ActiveGuid = $boostLabGuid
            Plans = @(
                [pscustomobject]@{ Guid = $boostLabGuid; IsActive = $true }
                [pscustomobject]@{ Guid = $balancedGuid; IsActive = $false }
                [pscustomobject]@{ Guid = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'; IsActive = $false }
            )
            Message = 'Three mock plans detected.'
        }
    }.GetNewClosure()
    $applyResult = & $powerModule {
        param($PowerInvoker, $RegistryInvoker, $InitialReader, $FinalReader, $SettingReader, $RegistryReader, $Events)
        Invoke-BoostLabPowerPlanAction -ActionName 'Apply' -AdministratorChecker { return $true } -PowerCfgInvoker $PowerInvoker -RegistryInvoker $RegistryInvoker -PlanInventoryReader $InitialReader -VerificationPlanInventoryReader $FinalReader -PowerSettingReader $SettingReader -RegistryReader $RegistryReader -UiLauncher { $Events.Add('UI:powercfg.cpl') }
    } $applyPowerInvoker $applyRegistryInvoker $initialInventory $applyFinalInventory $applySettingReader $applyRegistryReader $applyEvents
    if (
        -not $applyResult.Success -or
        $applyResult.VerificationResult.Status -ne 'Passed' -or
        $applyResult.Data.CommandStatus -ne 'Completed with warnings' -or
        $applyPowerCommands.Count -ne 78 -or
        $applyRegistryCommands.Count -ne 10 -or
        @($applyResult.Data.Warnings).Count -ne 1
    ) {
        throw 'Mocked Power Plan Apply did not preserve the complete Ultimate sequence.'
    }
    if (
        $applyPowerCommands[0] -ne "/duplicatescheme $ultimateGuid $boostLabGuid" -or
        $applyPowerCommands[1] -ne "/setactive $boostLabGuid" -or
        $applyPowerCommands[2] -ne "/delete $boostLabGuid" -or
        $applyPowerCommands[3] -ne "/delete $balancedGuid" -or
        $applyPowerCommands[4] -ne '/delete 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c' -or
        $applyPowerCommands[5] -ne '/hibernate off' -or
        $applyEvents[$applyEvents.Count - 1] -ne 'UI:powercfg.cpl'
    ) {
        throw 'Power Plan Apply command ordering changed.'
    }
    $actualSettingCommands = @(
        $applyPowerCommands |
            Where-Object { $_ -match '^/set(ac|dc)valueindex ' }
    )
    if ($actualSettingCommands.Count -ne 72) {
        throw 'Power Plan Apply did not emit 72 source setting commands.'
    }
    for ($index = 0; $index -lt $sourceSettingCommands.Count; $index++) {
        $sourceCommand = $sourceSettingCommands[$index]
        $expected = '/set{0}valueindex {1} {2} {3} {4}' -f $sourceCommand.Mode, $sourceCommand.Scheme, $sourceCommand.Subgroup, $sourceCommand.Setting, $sourceCommand.Value
        if ($actualSettingCommands[$index] -ne $expected) {
            throw "Power Plan setting command $index does not match Ultimate."
        }
    }

    $idempotentPowerCommands = [System.Collections.Generic.List[string]]::new()
    $idempotentPowerInvoker = {
        param($Arguments)
        $command = @($Arguments) -join ' '
        $idempotentPowerCommands.Add($command)
        $isDuplicateTarget = $Arguments[0] -eq '/duplicatescheme'
        $isActiveDelete = $Arguments[0] -eq '/delete' -and $Arguments[1] -eq $boostLabGuid
        $message = if ($isDuplicateTarget) {
            'The scheme could not be duplicated because a power scheme with the specified GUID already exists.'
        }
        elseif ($isActiveDelete) {
            'The active power scheme cannot be deleted.'
        }
        else {
            'Mock powercfg completed.'
        }
        return [pscustomobject]@{
            Succeeded = -not ($isDuplicateTarget -or $isActiveDelete)
            ExitCode = if ($isDuplicateTarget -or $isActiveDelete) { 1 } else { 0 }
            Output = @($message)
            Message = $message
        }
    }.GetNewClosure()
    $idempotentResult = & $powerModule {
        param($PowerInvoker, $RegistryInvoker, $InitialReader, $FinalReader, $SettingReader, $RegistryReader)
        Invoke-BoostLabPowerPlanAction -ActionName 'Apply' -AdministratorChecker { return $true } -PowerCfgInvoker $PowerInvoker -RegistryInvoker $RegistryInvoker -PlanInventoryReader $InitialReader -VerificationPlanInventoryReader $FinalReader -PowerSettingReader $SettingReader -RegistryReader $RegistryReader -UiLauncher { }
    } $idempotentPowerInvoker $applyRegistryInvoker $initialInventory $applyFinalInventory $applySettingReader $applyRegistryReader
    if (
        -not $idempotentResult.Success -or
        $idempotentResult.Status -ne 'Warning' -or
        $idempotentResult.Data.CommandStatus -ne 'Completed with warnings' -or
        $idempotentResult.VerificationResult.Status -ne 'Passed' -or
        @($idempotentResult.Data.Errors).Count -ne 0 -or
        @($idempotentResult.Data.Warnings).Count -ne 2 -or
        $idempotentPowerCommands.Count -ne 78 -or
        $idempotentPowerCommands[0] -ne "/duplicatescheme $ultimateGuid $boostLabGuid" -or
        $idempotentPowerCommands[1] -ne "/setactive $boostLabGuid"
    ) {
        throw 'An existing target Power Plan scheme was not reused idempotently with mandatory activation.'
    }
    $idempotentWarnings = @($idempotentResult.Data.Warnings) -join [Environment]::NewLine
    if (
        -not $idempotentWarnings.Contains('specified GUID already exists') -or
        -not $idempotentWarnings.Contains("Delete enumerated power scheme $boostLabGuid")
    ) {
        throw 'The idempotent Power Plan result did not report target reuse and active-scheme deletion warnings.'
    }
    if (@($idempotentPowerCommands | Where-Object { $_ -match '^/set(ac|dc)valueindex ' }).Count -ne 72) {
        throw 'The idempotent Power Plan Apply path did not continue all source-defined setting commands.'
    }

    $activationFailurePowerInvoker = {
        param($Arguments)
        $isDuplicateTarget = $Arguments[0] -eq '/duplicatescheme'
        $isActivation = $Arguments[0] -eq '/setactive'
        $isActiveDelete = $Arguments[0] -eq '/delete' -and $Arguments[1] -eq $boostLabGuid
        $message = if ($isDuplicateTarget) {
            'The scheme could not be duplicated because a power scheme with the specified GUID already exists.'
        }
        elseif ($isActivation) {
            'Access is denied.'
        }
        elseif ($isActiveDelete) {
            'The active power scheme cannot be deleted.'
        }
        else {
            'Mock powercfg completed.'
        }
        return [pscustomobject]@{
            Succeeded = -not ($isDuplicateTarget -or $isActivation -or $isActiveDelete)
            ExitCode = if ($isDuplicateTarget -or $isActivation -or $isActiveDelete) { 1 } else { 0 }
            Output = @($message)
            Message = $message
        }
    }.GetNewClosure()
    $activationFailureResult = & $powerModule {
        param($PowerInvoker, $RegistryInvoker, $InitialReader, $FinalReader, $SettingReader, $RegistryReader)
        Invoke-BoostLabPowerPlanAction -ActionName 'Apply' -AdministratorChecker { return $true } -PowerCfgInvoker $PowerInvoker -RegistryInvoker $RegistryInvoker -PlanInventoryReader $InitialReader -VerificationPlanInventoryReader $FinalReader -PowerSettingReader $SettingReader -RegistryReader $RegistryReader -UiLauncher { }
    } $activationFailurePowerInvoker $applyRegistryInvoker $initialInventory $applyFinalInventory $applySettingReader $applyRegistryReader
    if (
        $activationFailureResult.Success -or
        $activationFailureResult.Status -ne 'Failed' -or
        $activationFailureResult.Data.CommandStatus -ne 'Completed with errors' -or
        @($activationFailureResult.Data.Errors).Count -ne 1 -or
        -not (@($activationFailureResult.Data.Errors)[0]).Contains('Activate BoostLab Ultimate scheme: Access is denied.')
    ) {
        throw 'Power Plan activation failure was incorrectly hidden by target-scheme reuse.'
    }

    $unexpectedDuplicatePowerInvoker = {
        param($Arguments)
        $isUnexpectedDuplicate = $Arguments[0] -eq '/duplicatescheme'
        $isActiveDelete = $Arguments[0] -eq '/delete' -and $Arguments[1] -eq $boostLabGuid
        $message = if ($isUnexpectedDuplicate) {
            'The parameter is incorrect.'
        }
        elseif ($isActiveDelete) {
            'The active power scheme cannot be deleted.'
        }
        else {
            'Mock powercfg completed.'
        }
        return [pscustomobject]@{
            Succeeded = -not ($isUnexpectedDuplicate -or $isActiveDelete)
            ExitCode = if ($isUnexpectedDuplicate -or $isActiveDelete) { 1 } else { 0 }
            Output = @($message)
            Message = $message
        }
    }.GetNewClosure()
    $unexpectedDuplicateResult = & $powerModule {
        param($PowerInvoker, $RegistryInvoker, $InitialReader, $FinalReader, $SettingReader, $RegistryReader)
        Invoke-BoostLabPowerPlanAction -ActionName 'Apply' -AdministratorChecker { return $true } -PowerCfgInvoker $PowerInvoker -RegistryInvoker $RegistryInvoker -PlanInventoryReader $InitialReader -VerificationPlanInventoryReader $FinalReader -PowerSettingReader $SettingReader -RegistryReader $RegistryReader -UiLauncher { }
    } $unexpectedDuplicatePowerInvoker $applyRegistryInvoker $initialInventory $applyFinalInventory $applySettingReader $applyRegistryReader
    if (
        $unexpectedDuplicateResult.Success -or
        $unexpectedDuplicateResult.Status -ne 'Failed' -or
        @($unexpectedDuplicateResult.Data.Errors).Count -ne 1 -or
        -not (@($unexpectedDuplicateResult.Data.Errors)[0]).Contains('Duplicate Ultimate Performance scheme: The parameter is incorrect.')
    ) {
        throw 'An unexpected duplicate-scheme failure was incorrectly downgraded to Warning.'
    }

    $missingTargetInventory = {
        return [pscustomobject]@{
            Succeeded = $true
            ActiveGuid = $balancedGuid
            Plans = @([pscustomobject]@{ Guid = $balancedGuid; IsActive = $true })
            Message = 'Mock target scheme absent after duplicate response.'
        }
    }.GetNewClosure()
    $missingTargetReuseResult = & $powerModule {
        param($PowerInvoker, $RegistryInvoker, $InitialReader, $FinalReader, $SettingReader, $RegistryReader)
        Invoke-BoostLabPowerPlanAction -ActionName 'Apply' -AdministratorChecker { return $true } -PowerCfgInvoker $PowerInvoker -RegistryInvoker $RegistryInvoker -PlanInventoryReader $InitialReader -VerificationPlanInventoryReader $FinalReader -PowerSettingReader $SettingReader -RegistryReader $RegistryReader -UiLauncher { }
    } $idempotentPowerInvoker $applyRegistryInvoker $missingTargetInventory $applyFinalInventory $applySettingReader $applyRegistryReader
    if (
        $missingTargetReuseResult.Success -or
        $missingTargetReuseResult.Status -ne 'Failed' -or
        -not ((@($missingTargetReuseResult.Data.Errors) -join ' ').Contains('target scheme was not detected for reuse'))
    ) {
        throw 'A missing target scheme after duplicate/reuse handling did not remain fatal.'
    }

    $intelGraphicsDefinition = $definitions | Where-Object Name -eq 'Intel graphics power plan' | Select-Object -First 1
    $batterySaverDefinition = $definitions | Where-Object Name -eq 'Battery saver screen brightness' | Select-Object -First 1
    $unsupportedSettingKeys = @(
        "$($intelGraphicsDefinition.Subgroup)|$($intelGraphicsDefinition.Setting)"
        "$($batterySaverDefinition.Subgroup)|$($batterySaverDefinition.Setting)"
    )
    $compatibilitySettingReader = & $newPowerSettingReader $definitions $unsupportedSettingKeys
    $compatibilityPowerCommands = [System.Collections.Generic.List[string]]::new()
    $compatibilityPowerInvoker = {
        param($Arguments)
        $command = @($Arguments) -join ' '
        $compatibilityPowerCommands.Add($command)
        $isActiveDelete = $Arguments[0] -eq '/delete' -and $Arguments[1] -eq $boostLabGuid
        $isIntelGraphics = (
            $Arguments[0] -in @('/setacvalueindex', '/setdcvalueindex') -and
            $Arguments[3] -eq [string]$intelGraphicsDefinition.Setting
        )
        $isBatterySaver = (
            $Arguments[0] -in @('/setacvalueindex', '/setdcvalueindex') -and
            $Arguments[3] -eq [string]$batterySaverDefinition.Setting
        )
        $message = if ($isActiveDelete) {
            'The active power scheme cannot be deleted.'
        }
        elseif ($isIntelGraphics) {
            'The power scheme, subgroup or setting specified does not exist.'
        }
        elseif ($isBatterySaver) {
            'The power setting is unavailable or unsupported on this hardware.'
        }
        else {
            'Mock powercfg completed.'
        }
        return [pscustomobject]@{
            Succeeded = -not ($isActiveDelete -or $isIntelGraphics -or $isBatterySaver)
            ExitCode = if ($isActiveDelete -or $isIntelGraphics -or $isBatterySaver) { 1 } else { 0 }
            Output = @($message)
            Message = $message
        }
    }.GetNewClosure()
    $compatibilityResult = & $powerModule {
        param($PowerInvoker, $RegistryInvoker, $InitialReader, $FinalReader, $SettingReader, $RegistryReader)
        Invoke-BoostLabPowerPlanAction -ActionName 'Apply' -AdministratorChecker { return $true } -PowerCfgInvoker $PowerInvoker -RegistryInvoker $RegistryInvoker -PlanInventoryReader $InitialReader -VerificationPlanInventoryReader $FinalReader -PowerSettingReader $SettingReader -RegistryReader $RegistryReader -UiLauncher { }
    } $compatibilityPowerInvoker $applyRegistryInvoker $initialInventory $applyFinalInventory $compatibilitySettingReader $applyRegistryReader
    if (
        -not $compatibilityResult.Success -or
        $compatibilityResult.Status -ne 'Warning' -or
        $compatibilityResult.Data.CommandStatus -ne 'Completed with warnings' -or
        $compatibilityResult.VerificationResult.Status -ne 'Warning' -or
        @($compatibilityResult.Data.Errors).Count -ne 0 -or
        @($compatibilityResult.Data.Warnings).Count -ne 5 -or
        $compatibilityPowerCommands.Count -ne 78
    ) {
        throw 'Unsupported GPU, battery saver, or active-scheme deletion failures were not classified as warnings.'
    }
    $compatibilityWarningText = @($compatibilityResult.Data.Warnings) -join [Environment]::NewLine
    foreach ($warningText in @(
        'Set AC Intel graphics power plan'
        'Set DC Intel graphics power plan'
        'Set AC Battery saver screen brightness'
        'Set DC Battery saver screen brightness'
        "Delete enumerated power scheme $boostLabGuid"
    )) {
        if (-not $compatibilityWarningText.Contains($warningText)) {
            throw "Power Plan compatibility warning is missing: $warningText"
        }
    }

    $unexpectedPowerInvoker = {
        param($Arguments)
        $isActiveDelete = $Arguments[0] -eq '/delete' -and $Arguments[1] -eq $boostLabGuid
        $isUnexpectedFailure = (
            $Arguments[0] -eq '/setacvalueindex' -and
            $Arguments[3] -eq [string]$definitions[0].Setting
        )
        $message = if ($isActiveDelete) {
            'The active power scheme cannot be deleted.'
        }
        elseif ($isUnexpectedFailure) {
            'Access is denied.'
        }
        else {
            'Mock powercfg completed.'
        }
        return [pscustomobject]@{
            Succeeded = -not ($isActiveDelete -or $isUnexpectedFailure)
            ExitCode = if ($isActiveDelete -or $isUnexpectedFailure) { 1 } else { 0 }
            Output = @($message)
            Message = $message
        }
    }.GetNewClosure()
    $unexpectedFailureResult = & $powerModule {
        param($PowerInvoker, $RegistryInvoker, $InitialReader, $FinalReader, $SettingReader, $RegistryReader)
        Invoke-BoostLabPowerPlanAction -ActionName 'Apply' -AdministratorChecker { return $true } -PowerCfgInvoker $PowerInvoker -RegistryInvoker $RegistryInvoker -PlanInventoryReader $InitialReader -VerificationPlanInventoryReader $FinalReader -PowerSettingReader $SettingReader -RegistryReader $RegistryReader -UiLauncher { }
    } $unexpectedPowerInvoker $applyRegistryInvoker $initialInventory $applyFinalInventory $applySettingReader $applyRegistryReader
    if (
        $unexpectedFailureResult.Success -or
        $unexpectedFailureResult.Status -ne 'Failed' -or
        $unexpectedFailureResult.Data.CommandStatus -ne 'Completed with errors' -or
        @($unexpectedFailureResult.Data.Errors).Count -ne 1 -or
        -not (@($unexpectedFailureResult.Data.Errors)[0]).Contains('Access is denied.')
    ) {
        throw 'An unexpected powercfg failure was incorrectly downgraded to Warning.'
    }

    $mismatchedFinalInventory = {
        return [pscustomobject]@{
            Succeeded = $true
            ActiveGuid = $balancedGuid
            Plans = @([pscustomobject]@{ Guid = $balancedGuid; IsActive = $true })
            Message = 'Mock unexpected active scheme.'
        }
    }.GetNewClosure()
    $activeMismatchResult = & $powerModule {
        param($PowerInvoker, $RegistryInvoker, $InitialReader, $FinalReader, $SettingReader, $RegistryReader)
        Invoke-BoostLabPowerPlanAction -ActionName 'Apply' -AdministratorChecker { return $true } -PowerCfgInvoker $PowerInvoker -RegistryInvoker $RegistryInvoker -PlanInventoryReader $InitialReader -VerificationPlanInventoryReader $FinalReader -PowerSettingReader $SettingReader -RegistryReader $RegistryReader -UiLauncher { }
    } $applyPowerInvoker $applyRegistryInvoker $initialInventory $mismatchedFinalInventory $applySettingReader $applyRegistryReader
    if (
        $activeMismatchResult.Success -or
        $activeMismatchResult.Status -ne 'Failed' -or
        $activeMismatchResult.VerificationResult.Status -ne 'Failed'
    ) {
        throw 'An active Power Plan GUID mismatch did not remain a failure.'
    }

    $contradictorySettingResult = & $powerModule {
        param($PowerInvoker, $RegistryInvoker, $InitialReader, $FinalReader, $SettingReader, $RegistryReader)
        Invoke-BoostLabPowerPlanAction -ActionName 'Apply' -AdministratorChecker { return $true } -PowerCfgInvoker $PowerInvoker -RegistryInvoker $RegistryInvoker -PlanInventoryReader $InitialReader -VerificationPlanInventoryReader $FinalReader -PowerSettingReader $SettingReader -RegistryReader $RegistryReader -UiLauncher { }
    } $applyPowerInvoker $applyRegistryInvoker $initialInventory $applyFinalInventory $failedReader $applyRegistryReader
    if (
        $contradictorySettingResult.Success -or
        $contradictorySettingResult.Status -ne 'Failed' -or
        $contradictorySettingResult.VerificationResult.Status -ne 'Failed'
    ) {
        throw 'A contradictory detected Power Plan setting did not remain a failure.'
    }

    $classificationChecks = @(
        [pscustomobject]@{
            Arguments = @('/duplicatescheme', $ultimateGuid, $boostLabGuid)
            Message = 'Access is denied.'
            ExpectedWarning = $false
        }
        [pscustomobject]@{
            Arguments = @('/duplicatescheme', $ultimateGuid, $boostLabGuid)
            Message = 'The scheme could not be duplicated because a power scheme with the specified GUID already exists.'
            ExpectedWarning = $true
        }
        [pscustomobject]@{
            Arguments = @('/duplicatescheme', $ultimateGuid, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')
            Message = 'The scheme could not be duplicated because a power scheme with the specified GUID already exists.'
            ExpectedWarning = $false
        }
        [pscustomobject]@{
            Arguments = @('/setacvalueindex', $boostLabGuid, $definitions[0].Subgroup, $definitions[0].Setting, $definitions[0].AC)
            Message = 'powercfg.exe was not found.'
            ExpectedWarning = $false
        }
    )
    foreach ($classificationCheck in $classificationChecks) {
        $classifiedAsWarning = & $powerModule {
            param($Arguments, $Message)
            Test-BoostLabPowerCfgCompatibilityWarning -Arguments $Arguments -Result ([pscustomobject]@{
                Succeeded = $false
                ExitCode = 1
                Output = @($Message)
                Message = $Message
            })
        } $classificationCheck.Arguments $classificationCheck.Message
        if ([bool]$classifiedAsWarning -ne [bool]$classificationCheck.ExpectedWarning) {
            throw "Power Plan incorrectly classified a fatal command failure as Warning: $($classificationCheck.Message)"
        }
    }

    $defaultEvents = [System.Collections.Generic.List[string]]::new()
    $defaultPowerCommands = [System.Collections.Generic.List[string]]::new()
    $defaultRegistryCommands = [System.Collections.Generic.List[string]]::new()
    $defaultPowerInvoker = {
        param($Arguments)
        $command = @($Arguments) -join ' '
        $defaultPowerCommands.Add($command)
        $defaultEvents.Add("Power:$command")
        return [pscustomobject]@{ Succeeded = $true; ExitCode = 0; Output = @(); Message = 'Mock powercfg completed.' }
    }.GetNewClosure()
    $defaultRegistryInvoker = {
        param($Arguments)
        $command = @($Arguments) -join ' '
        $defaultRegistryCommands.Add($command)
        $defaultEvents.Add("Registry:$command")
        return [pscustomobject]@{ Succeeded = $true; ExitCode = 0; Output = @(); Message = 'Mock reg completed.' }
    }.GetNewClosure()
    $defaultResult = & $powerModule {
        param($PowerInvoker, $RegistryInvoker, $FinalReader, $RegistryReader, $Events)
        Invoke-BoostLabPowerPlanAction -ActionName 'Default' -AdministratorChecker { return $true } -PowerCfgInvoker $PowerInvoker -RegistryInvoker $RegistryInvoker -PlanInventoryReader $FinalReader -VerificationPlanInventoryReader $FinalReader -PowerSettingReader { throw 'Default must not query source setting indexes.' } -RegistryReader $RegistryReader -UiLauncher { $Events.Add('UI:powercfg.cpl') }
    } $defaultPowerInvoker $defaultRegistryInvoker $defaultFinalInventory $defaultRegistryReader $defaultEvents
    if (
        -not $defaultResult.Success -or
        $defaultResult.Message -ne 'Windows default power plans restored.' -or
        $defaultResult.VerificationResult.Status -ne 'Passed' -or
        $defaultPowerCommands.Count -ne 2 -or
        $defaultRegistryCommands.Count -ne 9 -or
        $defaultPowerCommands[0] -ne '-restoredefaultschemes' -or
        $defaultPowerCommands[1] -ne '/hibernate on' -or
        'delete HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings /f' -notin $defaultRegistryCommands -or
        'delete HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling /f' -notin $defaultRegistryCommands -or
        $defaultEvents[$defaultEvents.Count - 1] -ne 'UI:powercfg.cpl'
    ) {
        throw 'Mocked Power Plan Default did not preserve the explicit Ultimate sequence.'
    }

    foreach ($result in @($applyResult, $defaultResult)) {
        foreach ($field in @('Success', 'ToolId', 'ToolTitle', 'Action', 'Message', 'RestartRequired', 'Cancelled', 'Timestamp', 'Data', 'VerificationResult')) {
            if ($null -eq $result.PSObject.Properties[$field]) {
                throw "Power Plan result is missing field: $field"
            }
        }
        foreach ($field in @(
            'CommandStatus'
            'VerificationStatus'
            'ExpectedPowerPlanState'
            'DetectedPowerPlanState'
            'PowerPlanGuidsTargeted'
            'PowerCfgCommandsOrSettingsChecked'
            'RegistryValuesOrFilesChecked'
            'Warnings'
            'Errors'
            'PowerOptionsStatus'
            'CompletedAt'
        )) {
            if ($null -eq $result.Data.PSObject.Properties[$field]) {
                throw "Power Plan result data is missing field: $field"
            }
        }
    }
}
finally {
    Remove-Module -ModuleInfo $powerModule -Force -ErrorAction SilentlyContinue
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    foreach ($actionName in @('Apply', 'Default')) {
        $plan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName $actionName -IsDryRun $false
        if (
            -not $plan.RequiresAdmin -or
            -not $plan.NeedsExplicitConfirmation -or
            -not $plan.Capabilities.CanModifyRegistry -or
            $plan.CanReboot -or
            $plan.RequiresInternet -or
            $plan.UsesTrustedInstaller -or
            $plan.ConfirmationMessage -notmatch 'custom schemes' -or
            $plan.ConfirmationMessage -notmatch 'No restart'
        ) {
            throw "Power Plan $actionName Action Plan is incorrect."
        }
    }
    $applyPlan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Apply' -IsDryRun $false
    if (
        $applyPlan.ConfirmationMessage -notmatch 'battery' -or
        (@($applyPlan.SideEffects) -join ' ') -notmatch 'Critical and low battery' -or
        (@($applyPlan.PlannedChanges) -join ' ') -notmatch '36'
    ) {
        throw 'Power Plan Apply warnings do not disclose the approved high-impact behavior.'
    }
    $defaultPlan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Default' -IsDryRun $false
    if (
        $defaultPlan.ConfirmationMessage -notmatch 'FlyoutMenuSettings' -or
        $defaultPlan.ConfirmationMessage -notmatch 'PowerThrottling' -or
        (@($defaultPlan.SideEffects) -join ' ') -notmatch 'complete FlyoutMenuSettings'
    ) {
        throw 'Power Plan Default warnings do not disclose broad source key deletion.'
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredText in @(
    '''power-plan'' = @{'
    '''Windows\PowerPlan.psm1'''
    'Actions = @(''Apply'', ''Default'')'
    '$actionCommand.Parameters.ContainsKey(''Confirmed'')'
    'Test-BoostLabVerificationResult'
)) {
    if (-not $executionSource.Contains($requiredText)) {
        throw "Power Plan runtime mapping is missing: $requiredText"
    }
}

$uiSource = Get-Content -Raw -LiteralPath $uiPath
foreach ($requiredText in @(
    '$toolId -eq ''power-plan'''
    '-Label ''Command Status'''
    '-Label ''Verification Status'''
    '-Label ''Expected Power Plan state'''
    '-Label ''Detected Power Plan state'''
    '-Label ''Power plan GUIDs targeted'''
    '-Label ''Powercfg commands / settings checked'''
    '-Label ''Registry values / files checked'''
    '-Label ''Power Options'''
    '-Label ''Timestamp'''
)) {
    if (-not $uiSource.Contains($requiredText)) {
        throw "Power Plan Latest Result rendering is missing: $requiredText"
    }
}

$record = Get-Content -Raw -LiteralPath $recordPath
foreach ($requiredText in @(
    'source-ultimate/6 Windows/21 Power Plan.ps1'
    $sourceHash
    'Approved by Yazan for Phase 24'
    '## Source-to-BoostLab Mapping Audit'
    'Every hard-coded command or write below originates in the approved Ultimate source.'
    'exactly 36 source-derived setting definitions'
    'exactly 72 ordered'
    'No registry path, value name, GUID, AC/DC index, scheme operation'
    'Default restores Windows built-in schemes. It does not restore custom power schemes'
    'complete `FlyoutMenuSettings` and `PowerThrottling` key deletions'
    'Automated tests must use static inspection and injected mocks only.'
    'Some source-defined vendor-specific graphics and battery saver power settings do not exist'
    'preserves every source-defined command attempt'
    'structured Warning instead of failing the whole action'
    'If the source-defined target scheme GUID `99999999-9999-9999-9999-999999999999` already exists'
    'reuses the detected existing target scheme'
    'making repeated Apply runs idempotent'
)) {
    if (-not $record.Contains($requiredText)) {
        throw "Power Plan migration record is missing: $requiredText"
    }
}

$protectedModules = [ordered]@{
    'Network Adapter Power Savings & Wake' = @{ Path = 'Windows\NetworkAdapterPowerSavingsWake.psm1'; Hash = '74844D91EC7E03817FB9D9D440CDBC2798DE19D68DDAB74C351E8A354F21E163'; Required = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')' }
    'Signout LockScreen Wallpaper Black' = @{ Path = 'Windows\SignoutLockScreenWallpaperBlack.psm1'; Hash = 'FAE90C7491B3B72936D1D293D6435BF6893C8082DCEF4C6F6FDE5E1817F55D74'; Required = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')' }
    'Context Menu' = @{ Path = 'Windows\ContextMenu.psm1'; Hash = '93325E76B02F80B1A105C83F6E268EA3652B4AB9F74582E759A4490CF30D1082'; Required = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')' }
    'Start Menu Layout' = @{ Path = 'Windows\StartMenuLayout.psm1'; Hash = 'D93019267A3D566146F713DF69C86F41CDAD93A2B0786D5CB8DDF9F2878E103A'; Required = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')' }
    'Theme Black' = @{ Path = 'Windows\ThemeBlack.psm1'; Hash = '29F3474D93061B01E3CF9F23EADA88E932E90E4984EBB39F7DB2BEB24732230F'; Required = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')' }
    'GameBar' = @{ Path = 'Windows\game-bar.psm1'; Hash = 'E301B2AA588537B81CAB577DA51342FAFFFB7B452C2C36054BD269C51F10CC24'; Required = 'ToolModule.Placeholder.ps1' }
    'Copilot' = @{ Path = 'Windows\copilot.psm1'; Hash = '740FEDE65972C413A7BF0938F3409AB683B45C914281BDDD6C25222FD39E617D'; Required = 'ToolModule.Placeholder.ps1' }
    'GameMode' = @{ Path = 'Windows\game-mode.psm1'; Hash = 'CADEC6B0E4262990BF9D9BBDBD8DBA55EE910EEFC1FF72B78912800AD04624E9'; Required = '$script:BoostLabImplementedActions = @(''Open'')' }
}
foreach ($name in $protectedModules.Keys) {
    $definition = $protectedModules[$name]
    $path = Join-Path $modulesRoot $definition.Path
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash -ne $definition.Hash) {
        throw "$name changed during Phase 24."
    }
    if (-not (Get-Content -Raw -LiteralPath $path).Contains([string]$definition.Required)) {
        throw "$name implementation status changed during Phase 24."
    }
}

$deletedToolNames = @(
    'Windows Activation Helper', 'Firewall', 'DEP', 'File Download Security Warning', 'MPO', 'FSO', 'FSE',
    'Hardware Flip', 'AMD ULPS', 'WHQL Secure Boot Bypass', 'Keyboard Shortcuts', 'Search Shell Mobsync',
    'NVME Faster Driver', 'Core 1 Thread 1', 'DDU', 'UAC', 'Scaling', 'Start Menu Shortcuts', 'Loudness EQ'
)
$normalizedDeletedNames = @($deletedToolNames | ForEach-Object { ($_ -replace '[^a-zA-Z0-9]+', '-').Trim('-').ToLowerInvariant() })
$deletedModules = @(
    Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1' |
        Where-Object { [IO.Path]::GetFileNameWithoutExtension($_.Name).ToLowerInvariant() -in $normalizedDeletedNames }
)
if ($deletedModules.Count -gt 0) {
    throw "Deleted tool modules were found: $($deletedModules.FullName -join ', ')"
}

$allModules = @(
    Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1' |
        Where-Object { $_.Directory.Parent.FullName -eq $modulesRoot }
)
$implementedCount = @($allModules | Where-Object { (Get-Content -Raw -LiteralPath $_.FullName).Contains('$script:BoostLabImplementedActions') }).Count
$placeholderCount = @($allModules | Where-Object { (Get-Content -Raw -LiteralPath $_.FullName).Contains('ToolModule.Placeholder.ps1') }).Count
if ($implementedCount -ne 25 -or $placeholderCount -ne 23) {
    throw "Unexpected module counts: $implementedCount implemented, $placeholderCount placeholders."
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
        Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
        ForEach-Object { '{0}|{1}' -f $_.FullName.Substring($root.Length + 1).Replace('\', '/'), (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash }
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
if ($sourceLines.Count -ne 49 -or $sourceManifestHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') {
    throw 'source-ultimate content or paths changed.'
}

[pscustomobject]@{
    Success = $true
    ToolId = 'power-plan'
    ImplementedActions = @('Apply', 'Default')
    ApplyExecuted = $false
    DefaultExecuted = $false
    MockedApplyPassed = $true
    MockedDefaultPassed = $true
    SourcePowerSettingCommandCount = $sourceSettingCommands.Count
    ImplementedModuleCount = $implementedCount
    PlaceholderModuleCount = $placeholderCount
    SourceUltimateUnchanged = $true
    ProtectedModulesUnchanged = $true
    Message = 'Power Plan was validated with static inspection and injected mocks only.'
    Timestamp = Get-Date
}
