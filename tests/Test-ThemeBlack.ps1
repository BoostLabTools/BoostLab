[CmdletBinding()]
param(
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'BoostLab.Hashing.ps1')
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $scriptPath = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $PSCommandPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $MyInvocation.MyCommand.Path
    }
    else {
        throw 'Unable to determine the Theme Black test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
. (Join-Path $ProjectRoot 'tests\BoostLab.ParityStatusBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\ThemeBlack.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\4 Theme Black.ps1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$recordPath = Join-Path $ProjectRoot 'docs\migrations\theme-black.md'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$modulesRoot = Join-Path $ProjectRoot 'modules'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration['Stages'] | ForEach-Object { $_['Tools'] })
$tool = $tools | Where-Object { $_['Id'] -eq 'theme-black' } | Select-Object -First 1
if ($null -eq $tool) {
    throw 'Theme Black metadata is missing.'
}
if (
    [string]$tool['Stage'] -ne 'Windows' -or
    [int]$tool['Order'] -ne 4 -or
    [string]$tool['Type'] -ne 'action' -or
    [string]$tool['RiskLevel'] -ne 'low' -or
    (@($tool['Actions']) -join ',') -ne 'Apply,Default'
) {
    throw 'Theme Black stage, order, type, risk, or actions are incorrect.'
}

$capabilities = $tool['Capabilities']
$expectedTrueCapabilities = @(
    'RequiresAdmin'
    'CanModifyRegistry'
    'SupportsDefault'
    'NeedsExplicitConfirmation'
)
foreach ($field in $capabilities.Keys) {
    $expected = $field -in $expectedTrueCapabilities
    if ([bool]$capabilities[$field] -ne $expected) {
        throw "Theme Black capability '$field' is incorrect."
    }
}

if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne '3E5C58E1128B20041828BD3BDDA07033D84B2C540CAE18DDC82C989BDEECE31A') {
    throw 'Theme Black Ultimate source hash changed.'
}
$source = Get-Content -Raw -LiteralPath $sourcePath
foreach ($requiredText in @(
    '$env:SystemRoot\Temp\blacktheme.reg'
    '$env:SystemRoot\Temp\defaulttheme.reg'
    '"AppsUseLightTheme"=dword:00000000'
    '"ColorPrevalence"=dword:00000001'
    '"EnableTransparency"=dword:00000000'
    '"SystemUsesLightTheme"=dword:00000000'
    '"AccentColor"=dword:ff191919'
    '"ColorizationColor"=dword:c4191919'
    '"AppsUseLightTheme"=dword:00000001'
    '[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize]'
    '"StartColorMenu"=dword:ffc06700'
    '"AccentColorMenu"=dword:ffd47800'
    '"ColorizationColor"=dword:c40078d4'
    'Set-Content -Path "$env:SystemRoot\Temp\blacktheme.reg" -Value $BlackTheme -Force'
    'Set-Content -Path "$env:SystemRoot\Temp\defaulttheme.reg" -Value $DefaultTheme -Force'
    'Start-Process -Wait "regedit.exe" -ArgumentList "/S `"$env:SystemRoot\Temp\blacktheme.reg`"" -WindowStyle Hidden'
    'Start-Process -Wait "regedit.exe" -ArgumentList "/S `"$env:SystemRoot\Temp\defaulttheme.reg`"" -WindowStyle Hidden'
)) {
    if (-not $source.Contains($requiredText)) {
        throw "Theme Black source no longer contains: $requiredText"
    }
}
foreach ($forbiddenSourceText in @(
    'Remove-AppxPackage'
    'Add-AppxPackage'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'msiexec'
    'TrustedInstaller'
    'safeboot'
    'Set-Service'
    'Stop-Service'
    'Restart-Service'
    'Set-MpPreference'
    'Restart-Computer'
    'Stop-Computer'
    'shutdown.exe'
    'bcdedit'
    'Stop-Process'
)) {
    if ($source.Contains($forbiddenSourceText)) {
        throw "Theme Black source failed the Phase 19 safety gate: $forbiddenSourceText"
    }
}

$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredText in @(
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    'blacktheme.reg'
    'defaulttheme.reg'
    '"AppsUseLightTheme"=dword:00000000'
    '"ColorPrevalence"=dword:00000001'
    '"EnableTransparency"=dword:00000000'
    '"SystemUsesLightTheme"=dword:00000000'
    '"AccentColor"=dword:ff191919'
    '"ColorizationColor"=dword:c4191919'
    '"AppsUseLightTheme"=dword:00000001'
    '[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize]'
    '"StartColorMenu"=dword:ffc06700'
    '"AccentColorMenu"=dword:ffd47800'
    '"ColorizationColor"=dword:c40078d4'
    'Set-Content -Path $Path -Value $Content -Force -ErrorAction Stop'
    '"regedit.exe"'
    '-ArgumentList "/S `"$Path`""'
    'function Test-BoostLabThemeBlackState'
    'function Invoke-BoostLabThemeBlackDwmReassertion'
    'New-BoostLabVerificationResult'
    '-VerificationResult $verificationResult'
    '[bool]$Confirmed = $false'
    'Black theme applied.'
    'Theme restored to default.'
    'DwmNormalizationRejected'
    'DwmReassertionAttempted'
    'DwmColorizationNonBlackAfterReassertion'
)) {
    if (-not $moduleSource.Contains($requiredText)) {
        throw "Theme Black module is missing: $requiredText"
    }
}
foreach ($forbiddenModuleText in @(
    'Remove-AppxPackage'
    'Add-AppxPackage'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'Set-Service'
    'Stop-Service'
    'Restart-Service'
    'Set-MpPreference'
    'Restart-Computer'
    'Stop-Computer'
    'shutdown.exe'
    'bcdedit'
    'Stop-Process'
    'UsesTrustedInstaller = $true'
    'safeboot'
)) {
    if ($moduleSource.Contains($forbiddenModuleText)) {
        throw "Theme Black module contains unrelated behavior: $forbiddenModuleText"
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
    throw "Theme Black module syntax error: $($parseErrors[0].Message)"
}
$commands = @(
    $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
        $true
    ) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }
)
if (@($commands | Where-Object { $_ -eq 'Start-Process' }).Count -ne 1) {
    throw 'Theme Black must contain exactly one approved regedit Start-Process call.'
}
if (@($commands | Where-Object { $_ -eq 'Set-Content' }).Count -ne 1) {
    throw 'Theme Black must contain exactly one approved registry-file write helper.'
}

$themeModule = Import-Module `
    -Name $modulePath `
    -Force `
    -PassThru `
    -Prefix 'ThemeTest' `
    -Scope Local `
    -DisableNameChecking `
    -ErrorAction Stop
try {
    $infoCommand = Get-Command `
        -Name 'Get-ThemeTestBoostLabToolInfo' `
        -Module $themeModule.Name `
        -ErrorAction Stop
    $toolInfo = & $infoCommand
    if (
        [string]$toolInfo.Id -ne 'theme-black' -or
        (@($toolInfo.Actions) -join ',') -ne 'Apply,Default' -or
        (@($toolInfo.ImplementedActions) -join ',') -ne 'Apply,Default'
    ) {
        throw 'Theme Black exported metadata or implemented actions are incorrect.'
    }

    $applyDefinitions = @(
        & $themeModule {
            Get-BoostLabThemeBlackDefinitions -ActionName 'Apply'
        }
    )
    $defaultDefinitions = @(
        & $themeModule {
            Get-BoostLabThemeBlackDefinitions -ActionName 'Default'
        }
    )
    if ($applyDefinitions.Count -ne 13 -or $defaultDefinitions.Count -ne 13) {
        throw 'Theme Black must verify 13 source-defined states for both actions.'
    }

    $signedAccentColor = [BitConverter]::ToInt32([byte[]](0x19, 0x19, 0x19, 0xff), 0)
    $normalizedValues = & $themeModule {
        param($SignedAccentColor)
        [pscustomobject]@{
            SignedDWord = ConvertTo-BoostLabThemeBlackDisplayValue `
                -Value $SignedAccentColor `
                -ValueType 'DWord'
            Binary = ConvertTo-BoostLabThemeBlackDisplayValue `
                -Value ([byte[]](0x64, 0x6b, 0x00, 0xff)) `
                -ValueType 'Binary'
        }
    } $signedAccentColor
    if (
        $normalizedValues.SignedDWord -ne '0xff191919' -or
        $normalizedValues.Binary -ne '64,6b,00,ff'
    ) {
        throw 'Theme Black registry value normalization is incorrect.'
    }

    $expectedApply = [ordered]@{
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize|AppsUseLightTheme' = '0x00000000'
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize|ColorPrevalence' = '0x00000001'
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize|EnableTransparency' = '0x00000000'
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize|SystemUsesLightTheme' = '0x00000000'
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize|AppsUseLightTheme' = '0x00000000'
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent|AccentPalette' = '64,64,64,00,6b,6b,6b,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00'
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent|StartColorMenu' = '0x00000000'
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent|AccentColorMenu' = '0x00000000'
        'HKCU:\Software\Microsoft\Windows\DWM|EnableWindowColorization' = '0x00000001'
        'HKCU:\Software\Microsoft\Windows\DWM|AccentColor' = '0xff191919'
        'HKCU:\Software\Microsoft\Windows\DWM|ColorizationColor' = '0xc4191919'
        'HKCU:\Software\Microsoft\Windows\DWM|ColorizationAfterglow' = '0xc4191919'
        'HKCU:\Control Panel\Colors|Background' = '0 0 0'
    }
    $expectedDefault = [ordered]@{
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize|AppsUseLightTheme' = '0x00000001'
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize|ColorPrevalence' = '0x00000000'
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize|EnableTransparency' = '0x00000001'
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize|SystemUsesLightTheme' = '0x00000001'
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize|(key)' = 'Absent'
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent|AccentPalette' = '99,eb,ff,00,4c,c2,ff,00,00,91,f8,00,00,78,d4,00,00,67,c0,00,00,3e,92,00,00,1a,68,00,f7,63,0c,00'
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent|StartColorMenu' = '0xffc06700'
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent|AccentColorMenu' = '0xffd47800'
        'HKCU:\Software\Microsoft\Windows\DWM|EnableWindowColorization' = '0x00000000'
        'HKCU:\Software\Microsoft\Windows\DWM|AccentColor' = '0xffd47800'
        'HKCU:\Software\Microsoft\Windows\DWM|ColorizationColor' = '0xc40078d4'
        'HKCU:\Software\Microsoft\Windows\DWM|ColorizationAfterglow' = '0xc40078d4'
        'HKCU:\Control Panel\Colors|Background' = '0 0 0'
    }
    foreach ($definition in $applyDefinitions) {
        $key = '{0}|{1}' -f $definition.Path, $definition.Name
        if (-not $expectedApply.Contains($key) -or $expectedApply[$key] -ne $definition.Expected) {
            throw "Unexpected Theme Black Apply definition: $key = $($definition.Expected)"
        }
    }
    foreach ($definition in $defaultDefinitions) {
        $key = '{0}|{1}' -f $definition.Path, $definition.Name
        if (-not $expectedDefault.Contains($key) -or $expectedDefault[$key] -ne $definition.Expected) {
            throw "Unexpected Theme Black Default definition: $key = $($definition.Expected)"
        }
    }

    $newRegistryState = {
        param(
            [bool]$ReadSucceeded,
            [bool]$Exists,
            [string]$DisplayValue,
            [string]$Message
        )

        return [pscustomobject]@{
            ReadSucceeded = $ReadSucceeded
            KeyExists     = if ($ReadSucceeded) { $Exists } else { $null }
            Exists        = $Exists
            Value         = $null
            DisplayValue  = $DisplayValue
            Message       = $Message
        }
    }

    $applyState = [ordered]@{}
    foreach ($definition in $applyDefinitions) {
        $key = '{0}|{1}' -f $definition.Path, $definition.Name
        $applyState[$key] = & $newRegistryState $true $true ([string]$definition.Expected) 'Mock registry state detected.'
    }
    $applyReader = {
        param($Path, $Name, $ValueType)
        $key = '{0}|{1}' -f $Path, $Name
        return $applyState[$key]
    }.GetNewClosure()
    $applyVerification = & $themeModule {
        param($RegistryReader)
        Test-BoostLabThemeBlackState -ActionName 'Apply' -RegistryReader $RegistryReader
    } $applyReader
    if ($applyVerification.Status -ne 'Passed' -or @($applyVerification.Checks).Count -ne 13) {
        throw 'Theme Black Apply verification did not pass all 13 states.'
    }
    if (@($applyVerification.Checks | Where-Object { [bool]$_.NormalizedEquivalentApplied }).Count -ne 0) {
        throw 'Theme Black exact DWM values must not be reported as normalized equivalents.'
    }

    $normalizedApplyState = [ordered]@{}
    foreach ($key in $applyState.Keys) {
        $normalizedApplyState[$key] = $applyState[$key]
    }
    $normalizedApplyState['HKCU:\Software\Microsoft\Windows\DWM|AccentColor'] = & $newRegistryState $true $true '0x00000000' 'Mock Windows-normalized DWM black value.'
    $normalizedApplyState['HKCU:\Software\Microsoft\Windows\DWM|ColorizationColor'] = & $newRegistryState $true $true '0xc4000000' 'Mock Windows-normalized DWM black value.'
    $normalizedApplyState['HKCU:\Software\Microsoft\Windows\DWM|ColorizationAfterglow'] = & $newRegistryState $true $true '0xc4000000' 'Mock Windows-normalized DWM black value.'
    $normalizedReader = {
        param($Path, $Name, $ValueType)
        $key = '{0}|{1}' -f $Path, $Name
        return $normalizedApplyState[$key]
    }.GetNewClosure()
    $normalizedVerification = & $themeModule {
        param($RegistryReader)
        Test-BoostLabThemeBlackState -ActionName 'Apply' -RegistryReader $RegistryReader
    } $normalizedReader
    $normalizedChecks = @($normalizedVerification.Checks | Where-Object { [bool]$_.NormalizedEquivalentApplied })
    if ($normalizedVerification.Status -ne 'Passed' -or $normalizedChecks.Count -ne 3) {
        throw 'Theme Black Apply must accept only the three exact Windows-normalized black DWM equivalents.'
    }
    foreach ($check in $normalizedChecks) {
        if (
            [string]$check.Message -notmatch 'normalized' -or
            [string]$check.Expected -notin @('0xff191919', '0xc4191919') -or
            [string]$check.Actual -notin @('0x00000000', '0xc4000000')
        ) {
            throw 'Theme Black normalized DWM check does not include the expected narrow detail.'
        }
    }

    $nonBlackApplyState = [ordered]@{}
    foreach ($key in $applyState.Keys) {
        $nonBlackApplyState[$key] = $applyState[$key]
    }
    $nonBlackApplyState['HKCU:\Software\Microsoft\Windows\DWM|AccentColor'] = & $newRegistryState $true $true '0xff202020' 'Mock non-black DWM mismatch.'
    $nonBlackApplyState['HKCU:\Software\Microsoft\Windows\DWM|ColorizationColor'] = & $newRegistryState $true $true '0xc40078d4' 'Mock non-black Windows accent remnant.'
    $nonBlackApplyState['HKCU:\Software\Microsoft\Windows\DWM|ColorizationAfterglow'] = & $newRegistryState $true $true '0xc40078d4' 'Mock non-black Windows accent remnant.'
    $nonBlackReader = {
        param($Path, $Name, $ValueType)
        $key = '{0}|{1}' -f $Path, $Name
        return $nonBlackApplyState[$key]
    }.GetNewClosure()
    $nonBlackVerification = & $themeModule {
        param($RegistryReader)
        Test-BoostLabThemeBlackState -ActionName 'Apply' -RegistryReader $RegistryReader
    } $nonBlackReader
    if ($nonBlackVerification.Status -ne 'Failed') {
        throw 'Theme Black Apply must still fail verification for non-black DWM mismatches.'
    }
    $nonBlackNormalized = @($nonBlackVerification.Checks | Where-Object { [bool]$_.NormalizedEquivalentApplied })
    if ($nonBlackNormalized.Count -ne 0) {
        throw 'Theme Black must not accept non-black DWM accent remnants as normalized black.'
    }

    $defaultState = [ordered]@{}
    foreach ($definition in $defaultDefinitions) {
        $key = '{0}|{1}' -f $definition.Path, $definition.Name
        $exists = $definition.ValueType -ne 'KeyAbsent'
        $defaultState[$key] = & $newRegistryState $true $exists ([string]$definition.Expected) 'Mock registry state detected.'
    }
    $defaultReader = {
        param($Path, $Name, $ValueType)
        $key = '{0}|{1}' -f $Path, $Name
        return $defaultState[$key]
    }.GetNewClosure()
    $defaultVerification = & $themeModule {
        param($RegistryReader)
        Test-BoostLabThemeBlackState -ActionName 'Default' -RegistryReader $RegistryReader
    } $defaultReader
    if ($defaultVerification.Status -ne 'Passed' -or @($defaultVerification.Checks).Count -ne 13) {
        throw 'Theme Black Default verification did not pass all 13 states.'
    }

    $warningReader = {
        param($Path, $Name, $ValueType)
        if ($Name -eq 'AccentColor') {
            return (& $newRegistryState $false $false 'Unknown' 'Mock read failure.')
        }

        $key = '{0}|{1}' -f $Path, $Name
        return $applyState[$key]
    }.GetNewClosure()
    $warningVerification = & $themeModule {
        param($RegistryReader)
        Test-BoostLabThemeBlackState -ActionName 'Apply' -RegistryReader $RegistryReader
    } $warningReader
    if ($warningVerification.Status -ne 'Warning') {
        throw "Theme Black expected Warning, found $($warningVerification.Status)."
    }

    $failedReader = {
        param($Path, $Name, $ValueType)
        if ($Name -eq 'EnableTransparency') {
            return (& $newRegistryState $true $true '0x00000001' 'Mock contradictory value.')
        }

        $key = '{0}|{1}' -f $Path, $Name
        return $applyState[$key]
    }.GetNewClosure()
    $failedVerification = & $themeModule {
        param($RegistryReader)
        Test-BoostLabThemeBlackState -ActionName 'Apply' -RegistryReader $RegistryReader
    } $failedReader
    if ($failedVerification.Status -ne 'Failed') {
        throw "Theme Black expected Failed, found $($failedVerification.Status)."
    }

    $applyEvents = [System.Collections.Generic.List[string]]::new()
    $mockApplyState = [ordered]@{}
    $applyCapture = [pscustomobject]@{ Content = '' }
    $fileWriter = {
        param($Path, $Content)
        $applyCapture.Content = [string]$Content
        $applyEvents.Add("WRITE:$([IO.Path]::GetFileName($Path))")
    }.GetNewClosure()
    $registryImporter = {
        param($Path)
        $applyEvents.Add("IMPORT:$([IO.Path]::GetFileName($Path))")
        foreach ($definition in $applyDefinitions) {
            $key = '{0}|{1}' -f $definition.Path, $definition.Name
            $mockApplyState[$key] = & $newRegistryState $true $true ([string]$definition.Expected) 'Mock imported state.'
        }
    }.GetNewClosure()
    $mockApplyReader = {
        param($Path, $Name, $ValueType)
        $key = '{0}|{1}' -f $Path, $Name
        if ($mockApplyState.Contains($key)) {
            return $mockApplyState[$key]
        }

        return (& $newRegistryState $true $false 'Absent' 'Mock state absent.')
    }.GetNewClosure()
    $applyResult = & $themeModule {
        param($FileWriter, $RegistryImporter, $RegistryReader)
        Invoke-BoostLabThemeBlackAction `
            -ActionName 'Apply' `
            -AdministratorChecker { return $true } `
            -FileWriter $FileWriter `
            -RegistryImporter $RegistryImporter `
            -RegistryReader $RegistryReader
    } $fileWriter $registryImporter $mockApplyReader
    if (
        -not $applyResult.Success -or
        [string]$applyResult.Status -ne 'Success' -or
        $applyResult.Message -ne 'Black theme applied.' -or
        $applyResult.Data.CommandStatus -ne 'Completed' -or
        $applyResult.Data.ThemeImportStatus -ne 'Completed' -or
        $applyResult.VerificationResult.Status -ne 'Passed' -or
        @($applyResult.Data.RegistryValuesChecked).Count -ne 13
    ) {
        throw 'Mocked Theme Black Apply did not return the expected structured result.'
    }
    if (($applyEvents -join '|') -ne 'WRITE:blacktheme.reg|IMPORT:blacktheme.reg') {
        throw "Theme Black Apply execution order changed: $($applyEvents -join '|')"
    }
    if (
        -not $applyCapture.Content.Contains('"AccentColor"=dword:ff191919') -or
        -not $applyCapture.Content.Contains('"Background"="0 0 0"')
    ) {
        throw 'Theme Black Apply did not write the approved blacktheme.reg payload.'
    }

    $normalizedEvents = [System.Collections.Generic.List[string]]::new()
    $mockNormalizedState = [ordered]@{}
    $normalizedFileWriter = {
        param($Path, $Content)
        $normalizedEvents.Add("WRITE:$([IO.Path]::GetFileName($Path))")
    }.GetNewClosure()
    $normalizedRegistryImporter = {
        param($Path)
        $normalizedEvents.Add("IMPORT:$([IO.Path]::GetFileName($Path))")
        foreach ($definition in $applyDefinitions) {
            $key = '{0}|{1}' -f $definition.Path, $definition.Name
            $mockNormalizedState[$key] = & $newRegistryState $true $true ([string]$definition.Expected) 'Mock imported state.'
        }
        $mockNormalizedState['HKCU:\Software\Microsoft\Windows\DWM|AccentColor'] = & $newRegistryState $true $true '0x00000000' 'Mock Windows-normalized DWM black value.'
        $mockNormalizedState['HKCU:\Software\Microsoft\Windows\DWM|ColorizationColor'] = & $newRegistryState $true $true '0xc4000000' 'Mock Windows-normalized DWM black value.'
        $mockNormalizedState['HKCU:\Software\Microsoft\Windows\DWM|ColorizationAfterglow'] = & $newRegistryState $true $true '0xc4000000' 'Mock Windows-normalized DWM black value.'
    }.GetNewClosure()
    $mockNormalizedReader = {
        param($Path, $Name, $ValueType)
        $key = '{0}|{1}' -f $Path, $Name
        if ($mockNormalizedState.Contains($key)) {
            return $mockNormalizedState[$key]
        }

        return (& $newRegistryState $true $false 'Absent' 'Mock state absent.')
    }.GetNewClosure()
    $normalizedResult = & $themeModule {
        param($FileWriter, $RegistryImporter, $RegistryReader)
        Invoke-BoostLabThemeBlackAction `
            -ActionName 'Apply' `
            -AdministratorChecker { return $true } `
            -FileWriter $FileWriter `
            -RegistryImporter $RegistryImporter `
            -RegistryReader $RegistryReader
    } $normalizedFileWriter $normalizedRegistryImporter $mockNormalizedReader
    if (
        -not $normalizedResult.Success -or
        [string]$normalizedResult.Status -ne 'Success' -or
        $normalizedResult.VerificationResult.Status -ne 'Passed' -or
        @($normalizedResult.Data.DwmNormalizationAccepted).Count -ne 3 -or
        [string]$normalizedResult.Data.FinalStatusReason -ne 'PassedWithDwmNormalization' -or
        [string]$normalizedResult.Message -notmatch 'normalized by Windows'
    ) {
        throw 'Theme Black Apply must report a successful normalized DWM black verification with clear result details.'
    }

    $reassertExactEvents = [System.Collections.Generic.List[string]]::new()
    $mockReassertExactState = [ordered]@{}
    $reassertExactFileWriter = {
        param($Path, $Content)
        $reassertExactEvents.Add("WRITE:$([IO.Path]::GetFileName($Path))")
    }.GetNewClosure()
    $reassertExactImporter = {
        param($Path)
        $reassertExactEvents.Add("IMPORT:$([IO.Path]::GetFileName($Path))")
        foreach ($definition in $applyDefinitions) {
            $key = '{0}|{1}' -f $definition.Path, $definition.Name
            $mockReassertExactState[$key] = & $newRegistryState $true $true ([string]$definition.Expected) 'Mock imported state.'
        }
        $mockReassertExactState['HKCU:\Software\Microsoft\Windows\DWM|AccentColor'] = & $newRegistryState $true $true '0x00000000' 'Mock accepted DWM black normalization.'
        $mockReassertExactState['HKCU:\Software\Microsoft\Windows\DWM|ColorizationColor'] = & $newRegistryState $true $true '0xc40078d4' 'Mock non-black Windows accent remnant.'
        $mockReassertExactState['HKCU:\Software\Microsoft\Windows\DWM|ColorizationAfterglow'] = & $newRegistryState $true $true '0xc40078d4' 'Mock non-black Windows accent remnant.'
    }.GetNewClosure()
    $reassertExactReader = {
        param($Path, $Name, $ValueType)
        $key = '{0}|{1}' -f $Path, $Name
        if ($mockReassertExactState.Contains($key)) {
            return $mockReassertExactState[$key]
        }

        return (& $newRegistryState $true $false 'Absent' 'Mock state absent.')
    }.GetNewClosure()
    $reassertExactWriter = {
        param($Path, $Name, $ValueType, $Value, $ExpectedDisplay)
        if ($ValueType -ne 'DWord') {
            throw "Unexpected value type for mocked DWM reassertion: $ValueType"
        }

        $reassertExactEvents.Add("REASSERT:$Name=$ExpectedDisplay")
        $key = '{0}|{1}' -f $Path, $Name
        $mockReassertExactState[$key] = & $newRegistryState $true $true ([string]$ExpectedDisplay) 'Mock source DWM value reasserted.'
    }.GetNewClosure()
    $reassertExactResult = & $themeModule {
        param($FileWriter, $RegistryImporter, $RegistryReader, $RegistryValueWriter)
        Invoke-BoostLabThemeBlackAction `
            -ActionName 'Apply' `
            -AdministratorChecker { return $true } `
            -FileWriter $FileWriter `
            -RegistryImporter $RegistryImporter `
            -RegistryReader $RegistryReader `
            -RegistryValueWriter $RegistryValueWriter
    } $reassertExactFileWriter $reassertExactImporter $reassertExactReader $reassertExactWriter
    if (
        -not $reassertExactResult.Success -or
        [string]$reassertExactResult.Status -ne 'Success' -or
        [string]$reassertExactResult.VerificationResult.Status -ne 'Passed' -or
        -not [bool]$reassertExactResult.Data.DwmReassertionAttempted -or
        @($reassertExactResult.Data.DwmReassertionResults).Count -ne 3 -or
        @($reassertExactResult.Data.DwmNormalizationRejected).Count -ne 0 -or
        [string]$reassertExactResult.Data.FinalStatusReason -ne 'CompletedVerified'
    ) {
        throw 'Theme Black Apply must reassert source-defined DWM black values and succeed when they verify exactly.'
    }
    $colorizationExactReassertion = @($reassertExactResult.Data.DwmReassertionResults | Where-Object { [string]$_.Name -eq 'ColorizationColor' }) | Select-Object -First 1
    if (
        $null -eq $colorizationExactReassertion -or
        [string]$colorizationExactReassertion.ActualBeforeReassertion -ne '0xc40078d4' -or
        [string]$colorizationExactReassertion.ActualAfterReassertion -ne '0xc4191919'
    ) {
        throw 'Theme Black DWM reassertion details must preserve before/after ColorizationColor evidence.'
    }

    $reassertNormalizedEvents = [System.Collections.Generic.List[string]]::new()
    $mockReassertNormalizedState = [ordered]@{}
    $reassertNormalizedFileWriter = {
        param($Path, $Content)
        $reassertNormalizedEvents.Add("WRITE:$([IO.Path]::GetFileName($Path))")
    }.GetNewClosure()
    $reassertNormalizedImporter = {
        param($Path)
        $reassertNormalizedEvents.Add("IMPORT:$([IO.Path]::GetFileName($Path))")
        foreach ($definition in $applyDefinitions) {
            $key = '{0}|{1}' -f $definition.Path, $definition.Name
            $mockReassertNormalizedState[$key] = & $newRegistryState $true $true ([string]$definition.Expected) 'Mock imported state.'
        }
        $mockReassertNormalizedState['HKCU:\Software\Microsoft\Windows\DWM|AccentColor'] = & $newRegistryState $true $true '0x00000000' 'Mock accepted DWM black normalization.'
        $mockReassertNormalizedState['HKCU:\Software\Microsoft\Windows\DWM|ColorizationColor'] = & $newRegistryState $true $true '0xc40078d4' 'Mock non-black Windows accent remnant.'
        $mockReassertNormalizedState['HKCU:\Software\Microsoft\Windows\DWM|ColorizationAfterglow'] = & $newRegistryState $true $true '0xc40078d4' 'Mock non-black Windows accent remnant.'
    }.GetNewClosure()
    $reassertNormalizedReader = {
        param($Path, $Name, $ValueType)
        $key = '{0}|{1}' -f $Path, $Name
        if ($mockReassertNormalizedState.Contains($key)) {
            return $mockReassertNormalizedState[$key]
        }

        return (& $newRegistryState $true $false 'Absent' 'Mock state absent.')
    }.GetNewClosure()
    $reassertNormalizedWriter = {
        param($Path, $Name, $ValueType, $Value, $ExpectedDisplay)
        if ($ValueType -ne 'DWord') {
            throw "Unexpected value type for mocked DWM reassertion: $ValueType"
        }

        $reassertNormalizedEvents.Add("REASSERT:$Name=$ExpectedDisplay")
        $actualDisplay = if ($Name -eq 'AccentColor') {
            '0x00000000'
        }
        else {
            '0xc4000000'
        }
        $key = '{0}|{1}' -f $Path, $Name
        $mockReassertNormalizedState[$key] = & $newRegistryState $true $true $actualDisplay 'Mock Windows-normalized DWM black value after reassertion.'
    }.GetNewClosure()
    $reassertNormalizedResult = & $themeModule {
        param($FileWriter, $RegistryImporter, $RegistryReader, $RegistryValueWriter)
        Invoke-BoostLabThemeBlackAction `
            -ActionName 'Apply' `
            -AdministratorChecker { return $true } `
            -FileWriter $FileWriter `
            -RegistryImporter $RegistryImporter `
            -RegistryReader $RegistryReader `
            -RegistryValueWriter $RegistryValueWriter
    } $reassertNormalizedFileWriter $reassertNormalizedImporter $reassertNormalizedReader $reassertNormalizedWriter
    if (
        -not $reassertNormalizedResult.Success -or
        [string]$reassertNormalizedResult.Status -ne 'Success' -or
        [string]$reassertNormalizedResult.VerificationResult.Status -ne 'Passed' -or
        -not [bool]$reassertNormalizedResult.Data.DwmReassertionAttempted -or
        @($reassertNormalizedResult.Data.DwmNormalizationAccepted).Count -ne 3 -or
        @($reassertNormalizedResult.Data.DwmNormalizationRejected).Count -ne 0 -or
        [string]$reassertNormalizedResult.Data.FinalStatusReason -ne 'PassedWithDwmNormalization'
    ) {
        throw 'Theme Black Apply must pass when source DWM reassertion is normalized to true black equivalents.'
    }

    $verificationFailureEvents = [System.Collections.Generic.List[string]]::new()
    $mockVerificationFailureState = [ordered]@{}
    $verificationFailureFileWriter = {
        param($Path, $Content)
        $verificationFailureEvents.Add("WRITE:$([IO.Path]::GetFileName($Path))")
    }.GetNewClosure()
    $verificationFailureImporter = {
        param($Path)
        $verificationFailureEvents.Add("IMPORT:$([IO.Path]::GetFileName($Path))")
        foreach ($definition in $applyDefinitions) {
            $key = '{0}|{1}' -f $definition.Path, $definition.Name
            $mockVerificationFailureState[$key] = & $newRegistryState $true $true ([string]$definition.Expected) 'Mock imported state.'
        }
        $mockVerificationFailureState['HKCU:\Software\Microsoft\Windows\DWM|AccentColor'] = & $newRegistryState $true $true '0x00000000' 'Mock accepted DWM black normalization.'
        $mockVerificationFailureState['HKCU:\Software\Microsoft\Windows\DWM|ColorizationColor'] = & $newRegistryState $true $true '0xc40078d4' 'Mock non-black Windows accent remnant.'
        $mockVerificationFailureState['HKCU:\Software\Microsoft\Windows\DWM|ColorizationAfterglow'] = & $newRegistryState $true $true '0xc40078d4' 'Mock non-black Windows accent remnant.'
    }.GetNewClosure()
    $verificationFailureReader = {
        param($Path, $Name, $ValueType)
        $key = '{0}|{1}' -f $Path, $Name
        if ($mockVerificationFailureState.Contains($key)) {
            return $mockVerificationFailureState[$key]
        }

        return (& $newRegistryState $true $false 'Absent' 'Mock state absent.')
    }.GetNewClosure()
    $verificationFailureWriter = {
        param($Path, $Name, $ValueType, $Value, $ExpectedDisplay)
        $verificationFailureEvents.Add("REASSERT:$Name=$ExpectedDisplay")
        # Simulate Windows leaving ColorizationColor/Afterglow on non-black accent remnants after reassertion.
    }.GetNewClosure()
    $verificationFailureResult = & $themeModule {
        param($FileWriter, $RegistryImporter, $RegistryReader, $RegistryValueWriter)
        Invoke-BoostLabThemeBlackAction `
            -ActionName 'Apply' `
            -AdministratorChecker { return $true } `
            -FileWriter $FileWriter `
            -RegistryImporter $RegistryImporter `
            -RegistryReader $RegistryReader `
            -RegistryValueWriter $RegistryValueWriter
    } $verificationFailureFileWriter $verificationFailureImporter $verificationFailureReader $verificationFailureWriter
    if (
        [bool]$verificationFailureResult.Success -or
        [string]$verificationFailureResult.Status -ne 'Error' -or
        [string]$verificationFailureResult.Data.CommandStatus -ne 'Completed' -or
        [string]$verificationFailureResult.Data.VerificationStatus -ne 'Failed' -or
        [string]$verificationFailureResult.Data.FinalStatusReason -ne 'DwmColorizationNonBlackAfterReassertion' -or
        -not [bool]$verificationFailureResult.Data.DwmReassertionAttempted -or
        @($verificationFailureResult.Data.DwmNormalizationAccepted).Count -ne 1 -or
        @($verificationFailureResult.Data.DwmNormalizationRejected).Count -ne 2 -or
        [string]$verificationFailureResult.Message -match 'DWM color values were normalized by Windows to equivalent black values and accepted' -or
        [string]$verificationFailureResult.Message -notmatch 'Rejected non-black DWM value'
    ) {
        throw 'Theme Black Apply must report rejected non-black DWM remnants after reassertion without misleading normalization text.'
    }

    $importFailureResult = & $themeModule {
        param($FileWriter, $RegistryReader)
        Invoke-BoostLabThemeBlackAction `
            -ActionName 'Apply' `
            -AdministratorChecker { return $true } `
            -FileWriter $FileWriter `
            -RegistryImporter { param($Path) throw 'Mock import failure.' } `
            -RegistryReader $RegistryReader
    } $fileWriter $applyReader
    if (
        [bool]$importFailureResult.Success -or
        [string]$importFailureResult.Status -ne 'Error' -or
        [string]$importFailureResult.Data.ThemeImportStatus -ne 'Failed' -or
        [string]$importFailureResult.Data.FinalStatusReason -ne 'CommandError' -or
        [string]$importFailureResult.Message -notmatch 'Mock import failure'
    ) {
        throw 'Theme Black Apply must fail closed when the registry import fails.'
    }

    $defaultEvents = [System.Collections.Generic.List[string]]::new()
    $mockDefaultState = [ordered]@{}
    $defaultCapture = [pscustomobject]@{ Content = '' }
    $defaultFileWriter = {
        param($Path, $Content)
        $defaultCapture.Content = [string]$Content
        $defaultEvents.Add("WRITE:$([IO.Path]::GetFileName($Path))")
    }.GetNewClosure()
    $defaultRegistryImporter = {
        param($Path)
        $defaultEvents.Add("IMPORT:$([IO.Path]::GetFileName($Path))")
        foreach ($definition in $defaultDefinitions) {
            $key = '{0}|{1}' -f $definition.Path, $definition.Name
            $exists = $definition.ValueType -ne 'KeyAbsent'
            $mockDefaultState[$key] = & $newRegistryState $true $exists ([string]$definition.Expected) 'Mock imported state.'
        }
    }.GetNewClosure()
    $mockDefaultReader = {
        param($Path, $Name, $ValueType)
        $key = '{0}|{1}' -f $Path, $Name
        if ($mockDefaultState.Contains($key)) {
            return $mockDefaultState[$key]
        }

        return (& $newRegistryState $true $false 'Absent' 'Mock state absent.')
    }.GetNewClosure()
    $defaultResult = & $themeModule {
        param($FileWriter, $RegistryImporter, $RegistryReader)
        Invoke-BoostLabThemeBlackAction `
            -ActionName 'Default' `
            -AdministratorChecker { return $true } `
            -FileWriter $FileWriter `
            -RegistryImporter $RegistryImporter `
            -RegistryReader $RegistryReader
    } $defaultFileWriter $defaultRegistryImporter $mockDefaultReader
    if (
        -not $defaultResult.Success -or
        [string]$defaultResult.Status -ne 'Success' -or
        $defaultResult.Message -ne 'Theme restored to default.' -or
        $defaultResult.Data.CommandStatus -ne 'Completed' -or
        $defaultResult.Data.ThemeImportStatus -ne 'Completed' -or
        $defaultResult.VerificationResult.Status -ne 'Passed' -or
        @($defaultResult.Data.RegistryValuesChecked).Count -ne 13
    ) {
        throw 'Mocked Theme Black Default did not return the expected structured result.'
    }
    if (($defaultEvents -join '|') -ne 'WRITE:defaulttheme.reg|IMPORT:defaulttheme.reg') {
        throw "Theme Black Default execution order changed: $($defaultEvents -join '|')"
    }
    if (
        -not $defaultCapture.Content.Contains('[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize]') -or
        -not $defaultCapture.Content.Contains('"AccentColor"=dword:ffd47800')
    ) {
        throw 'Theme Black Default did not write the approved defaulttheme.reg payload.'
    }

    foreach ($result in @($applyResult, $defaultResult)) {
        foreach ($field in @(
            'Success'
            'Status'
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
                throw "Theme Black result is missing field: $field"
            }
        }
        foreach ($dataField in @(
            'CommandStatus'
            'VerificationStatus'
            'ExpectedThemeState'
            'DetectedThemeState'
            'RegistryValuesChecked'
            'DwmNormalizationAccepted'
            'DwmNormalizationRejected'
            'DwmReassertionAttempted'
            'DwmReassertionResults'
            'RegistryFilePath'
            'RegistryFileStatus'
            'ThemeImportStatus'
            'UiRefreshStatus'
            'FinalStatusReason'
            'CompletedAt'
        )) {
            if ($null -eq $result.Data.PSObject.Properties[$dataField]) {
                throw "Theme Black result data is missing field: $dataField"
            }
        }
    }
}
finally {
    Remove-Module -ModuleInfo $themeModule -Force -ErrorAction SilentlyContinue
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    foreach ($actionName in @('Apply', 'Default')) {
        $plan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName $actionName -IsDryRun $false
        $planText = @(
            $plan.Summary
            @($plan.PlannedChanges)
            @($plan.SideEffects)
            $plan.ConfirmationMessage
        ) -join ' '
        if (
            -not $plan.RequiresAdmin -or
            -not $plan.NeedsExplicitConfirmation -or
            $plan.CanReboot -or
            $plan.RequiresInternet -or
            $plan.UsesTrustedInstaller -or
            $planText -notmatch 'theme|Theme' -or
            $plan.ConfirmationMessage -notmatch 'No restart is required'
        ) {
            throw "Theme Black $actionName Action Plan is incorrect."
        }
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredText in @(
    '''theme-black'' = @{'
    '''Windows\ThemeBlack.psm1'''
    'Actions = @(''Apply'', ''Default'')'
    '$actionCommand.Parameters.ContainsKey(''Confirmed'')'
    'Get-BoostLabVerificationValidation'
)) {
    if (-not $executionSource.Contains($requiredText)) {
        throw "Theme Black runtime mapping is missing: $requiredText"
    }
}

$uiSource = Get-Content -Raw -LiteralPath $uiPath
foreach ($requiredText in @(
    '$toolId -eq ''theme-black'''
    '-Label ''Command Status'''
    '-Label ''Verification Status'''
    '-Label ''Expected Theme state'''
    '-Label ''Detected Theme state'''
    '-Label ''Registry values checked'''
    '-Label ''UI refresh / Settings launch'''
)) {
    if (-not $uiSource.Contains($requiredText)) {
        throw "Theme Black UI rendering is missing: $requiredText"
    }
}

$record = Get-Content -Raw -LiteralPath $recordPath
foreach ($requiredText in @(
    'source-ultimate/6 Windows/4 Theme Black.ps1'
    '3E5C58E1128B20041828BD3BDDA07033D84B2C540CAE18DDC82C989BDEECE31A'
    'Approved by Yazan'
    'blacktheme.reg'
    'defaulttheme.reg'
    'NeedsExplicitConfirmation = true'
    'Automated tests must use mocks'
)) {
    if (-not $record.Contains($requiredText)) {
        throw "Theme Black migration record is missing: $requiredText"
    }
}

$unchangedModules = [ordered]@{
    GameMode = @{
        Path = Join-Path $modulesRoot 'Windows\game-mode.psm1'
        Hash = 'CADEC6B0E4262990BF9D9BBDBD8DBA55EE910EEFC1FF72B78912800AD04624E9'
        Required = 'Start-Process "ms-settings:gaming-gamemode"'
    }
    GameBar = @{
        Path = Join-Path $modulesRoot 'Windows\game-bar.psm1'
        Hash = '2EABB62D41AFCAB0E29B126442364844E2300DD8253E01DF9FBEA3525CACE2AD'
        Required = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    Copilot = @{
        Path = Join-Path $modulesRoot 'Windows\copilot.psm1'
        Hash = 'C77E3A3B2A8543BE1AB12477F69A8EBAC84B38618B77A0740FC400E184CFD6AB'
        Required = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
}
foreach ($name in $unchangedModules.Keys) {
    $definition = $unchangedModules[$name]
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $definition.Path).Hash -ne $definition.Hash) {
        throw "$name module changed during Phase 19."
    }
    $content = Get-Content -Raw -LiteralPath $definition.Path
    if (-not $content.Contains([string]$definition.Required)) {
        throw "$name expected behavior or placeholder marker is missing."
    }
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
    if ($implementedCount -ne $inventoryBaseline.ImplementedTools -or $placeholderCount -ne $inventoryBaseline.DeferredPlaceholders) {
        throw "Unexpected module counts: $implementedCount implemented, $placeholderCount placeholders."
    }

    $parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
    $executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
    $themeRecord = @(
        $parityBaseline.Tools |
            Where-Object { [string]$_.ToolId -eq 'theme-black' }
    ) | Select-Object -First 1
    if ($null -eq $themeRecord) {
        throw 'Theme Black parity record is missing.'
    }
    if (
        [string]$themeRecord.RuntimeStatus -ne 'RuntimeImplemented' -or
        [string]$themeRecord.ImplementationLevel -ne 'ParityImplemented' -or
        [string]$themeRecord.UltimateParity -ne 'Yes' -or
        [bool]$themeRecord.YazanFinalException
    ) {
        throw 'Theme Black must be final exact Ultimate parity after Phase 138.'
    }
    if (-not (Test-BoostLabParityRecordFinal -Record $themeRecord)) {
        throw 'Theme Black must be treated as final in the ordered parity flow.'
    }

    $nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
    if ($null -eq $nextTarget) {
        throw 'Ordered parity cursor must identify the next target after Theme Black.'
    }
    if ([string]$nextTarget.ToolId -ne [string]$parityBaseline.CurrentOrderedParityTarget) {
        throw 'Next ordered parity target must match the central parity baseline cursor.'
    }
    $categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
    if ([int]$categoryCounts['ParityImplemented'] -ne [int]$parityBaseline.Counts.UltimateParityImplemented) {
        throw 'ParityImplemented count mismatch.'
    }
    if ([int]$categoryCounts['NearParityControlled'] -ne [int]$parityBaseline.Counts.NearParityControlled) {
        throw 'NearParityControlled count mismatch.'
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
function ConvertTo-NormalizedToolName {
    param([Parameter(Mandatory)][string]$Name)

    return ($Name -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()
}
$approvedNames = @(
    $tools | ForEach-Object {
        ConvertTo-NormalizedToolName -Name ([string]$_['Title'])
        ConvertTo-NormalizedToolName -Name ([string]$_['Id'])
    }
)
foreach ($deletedName in $deletedToolNames) {
    if ((ConvertTo-NormalizedToolName -Name $deletedName) -in $approvedNames) {
        throw "Deleted tool is present in the catalog: $deletedName"
    }
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
    $sourceManifestHash -ne 'B07E015D5BA32E9CF4DBC1804597311D8A41CE7FA537C0091914056BEF06FFF4'
) {
    throw 'source-ultimate content or paths changed.'
}

[pscustomobject]@{
    Success                  = $true
    ToolId                   = 'theme-black'
    ImplementedActions       = @('Apply', 'Default')
    VerificationCheckCount   = 13
    ApplyExecuted            = $false
    DefaultExecuted          = $false
    MockedApplyPassed        = $true
    MockedDefaultPassed      = $true
    CurrentOrderedParityTarget = [string]$parityBaseline.CurrentOrderedParityTarget
    FinalProgressStatus      = [string]$themeRecord.ImplementationLevel
    ImplementedModuleCount   = $implementedCount
    PlaceholderModuleCount   = $placeholderCount
    SourceUltimateUnchanged  = $true
    GameBarUnchanged         = $true
    CopilotImplemented       = $true
    GameModeUnchanged        = $true
    Message                  = 'Theme Black Apply/Default and verification were validated with mocks only.'
    Timestamp                = Get-Date
}



