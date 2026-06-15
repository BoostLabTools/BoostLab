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
        throw 'Unable to determine the Spectre / Meltdown Assistant test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Advanced\spectre-meltdown-assistant.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\8 Advanced\1 Spectre  Meltdown Assistant.ps1'
$recordPath = Join-Path $ProjectRoot 'docs\migrations\spectre-meltdown-assistant.md'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration['Stages'] | ForEach-Object { $_['Tools'] })
$tool = $tools | Where-Object { $_['Id'] -eq 'spectre-meltdown-assistant' } | Select-Object -First 1
if ($null -eq $tool) {
    throw 'Spectre / Meltdown Assistant metadata is missing.'
}
if (
    [string]$tool['Stage'] -ne 'Advanced' -or
    [int]$tool['Order'] -ne 1 -or
    [string]$tool['Type'] -ne 'assistant' -or
    [string]$tool['RiskLevel'] -ne 'high' -or
    (@($tool['Actions']) -join ',') -ne 'Analyze,Apply,Default'
) {
    throw 'Spectre / Meltdown Assistant metadata is incorrect.'
}

$capabilities = $tool['Capabilities']
foreach ($field in @('RequiresAdmin', 'CanModifyRegistry', 'CanModifySecurity', 'SupportsDefault', 'NeedsExplicitConfirmation')) {
    if (-not [bool]$capabilities[$field]) {
        throw "Spectre / Meltdown Assistant capability '$field' must be true."
    }
}
foreach ($field in @('RequiresInternet', 'CanReboot', 'CanModifyServices', 'CanInstallSoftware', 'CanDownload', 'CanModifyDrivers', 'CanDeleteFiles', 'UsesTrustedInstaller', 'UsesSafeMode', 'SupportsRestore')) {
    if ([bool]$capabilities[$field]) {
        throw "Spectre / Meltdown Assistant capability '$field' must be false."
    }
}

$approvedSourceHash = '3989B93BC4B3367B1ED0CF831C93DA6C2E87C556D945854FEE4ECA5D4C66AB50'
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne $approvedSourceHash) {
    throw 'Spectre / Meltdown Assistant Ultimate source hash changed.'
}

$source = Get-Content -Raw -LiteralPath $sourcePath
$normalizedSource = $source.Replace('`"', '"')
$moduleSource = Get-Content -Raw -LiteralPath $modulePath
$applyMaskCommand = 'reg add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /t REG_DWORD /d "3" /f'
$applyOverrideCommand = 'reg add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /t REG_DWORD /d "3" /f'
$defaultMaskCommand = 'reg delete "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /f'
$defaultOverrideCommand = 'reg delete "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /f'
foreach ($requiredText in @(
    $applyMaskCommand
    $applyOverrideCommand
    $defaultMaskCommand
    $defaultOverrideCommand
)) {
    if (-not $normalizedSource.Contains($requiredText)) {
        throw "Spectre / Meltdown source no longer contains: $requiredText"
    }
    if (-not $moduleSource.Contains($requiredText)) {
        throw "Spectre / Meltdown module does not preserve: $requiredText"
    }
}

if (
    $moduleSource.IndexOf($applyMaskCommand) -gt $moduleSource.IndexOf($applyOverrideCommand) -or
    $moduleSource.IndexOf($defaultMaskCommand) -gt $moduleSource.IndexOf($defaultOverrideCommand)
) {
    throw 'Spectre / Meltdown module changed the approved command order.'
}

foreach ($requiredModuleText in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
    'function Get-BoostLabSpectreMeltdownAnalyzeData'
    'function Test-BoostLabSpectreMeltdownState'
    'function New-BoostLabSpectreVerificationCheck'
    'function New-BoostLabSpectreVerificationResult'
    'VerificationScope'
    '[bool]$Confirmed = $false'
    'Keep the approved Default mitigation policy'
)) {
    if (-not $moduleSource.Contains($requiredModuleText)) {
        throw "Spectre / Meltdown module is missing: $requiredModuleText"
    }
}
if ($moduleSource.Contains('Verification.psm1')) {
    throw 'Spectre / Meltdown must not import or unload the runtime-owned verification module.'
}

foreach ($forbiddenText in @(
    'bcdedit'
    'Restart-Computer'
    'Stop-Computer'
    'shutdown.exe'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'New-Service'
    'Set-Service'
    'Stop-Service'
    'Start-Service'
    'Register-ScheduledTask'
    'UsesTrustedInstaller = $true'
    'safeboot'
)) {
    if ($moduleSource.Contains($forbiddenText)) {
        throw "Spectre / Meltdown module contains unrelated behavior: $forbiddenText"
    }
}

$module = Import-Module -Name $modulePath -Force -PassThru -Prefix 'SpectreTest' -Scope Local -DisableNameChecking -ErrorAction Stop
try {
    $infoCommand = Get-Command -Name 'Get-SpectreTestBoostLabToolInfo' -Module $module.Name -ErrorAction Stop
    $compatibilityCommand = Get-Command -Name 'Test-SpectreTestBoostLabToolCompatibility' -Module $module.Name -ErrorAction Stop

    $toolInfo = & $infoCommand
    if (
        [string]$toolInfo.Id -ne 'spectre-meltdown-assistant' -or
        (@($toolInfo.Actions) -join ',') -ne 'Analyze,Apply,Default' -or
        (@($toolInfo.ImplementedActions) -join ',') -ne 'Analyze,Apply,Default'
    ) {
        throw 'Spectre / Meltdown exported metadata or implemented actions are incorrect.'
    }

    $compatibility = & $compatibilityCommand `
        -OperatingSystem 'Windows_NT' `
        -SystemRoot 'C:\Windows' `
        -RegistryProviderAvailable $true `
        -PathChecker { param($Path) return $true }
    if (-not $compatibility.Supported) {
        throw 'Spectre / Meltdown compatibility failed with mocked Windows support.'
    }

    $analysis = & $module {
        Get-BoostLabSpectreMeltdownAnalyzeData -StateReader {
            [pscustomobject]@{
                Profile = 'Default mitigation policy'
                FeatureSettingsOverrideMask = [pscustomobject]@{ DisplayValue = 'Absent' }
                FeatureSettingsOverride = [pscustomobject]@{ DisplayValue = 'Absent' }
                Warnings = @()
            }
        }
    }
    if (
        $analysis.CurrentProfile -ne 'Default mitigation policy' -or
        $analysis.FeatureSettingsOverrideMask -ne 'Absent' -or
        $analysis.FeatureSettingsOverride -ne 'Absent' -or
        $analysis.SecurityWarning -notmatch 'reduces CPU vulnerability protection' -or
        $analysis.Recommendation -notmatch 'Default mitigation policy'
    ) {
        throw 'Spectre / Meltdown Analyze did not return the expected structured security guidance.'
    }

    foreach ($actionName in @('Apply', 'Default')) {
        $cancelledResult = & $module {
            param($Action)
            Invoke-BoostLabToolAction -ActionName $Action -Confirmed:$false
        } $actionName
        if (-not $cancelledResult.Cancelled -or $cancelledResult.Message -ne 'Cancelled by user') {
            throw "Spectre / Meltdown $actionName confirmation handling is incorrect."
        }
    }

    $registryState = @{
        FeatureSettingsOverrideMask = $null
        FeatureSettingsOverride = $null
    }
    $invocations = [System.Collections.Generic.List[string]]::new()
    $reader = {
        param($Path, $ValueName)
        $value = $registryState[$ValueName]
        [pscustomobject]@{
            ReadSucceeded = $true
            Exists = ($null -ne $value)
            Value = $value
            DisplayValue = if ($null -eq $value) { 'Absent' } else { [string]$value }
            Message = 'Mocked registry state.'
        }
    }.GetNewClosure()
    $invoker = {
        param($CommandText)
        $invocations.Add($CommandText) | Out-Null
        $valueName = if ($CommandText -match 'FeatureSettingsOverrideMask') {
            'FeatureSettingsOverrideMask'
        }
        else {
            'FeatureSettingsOverride'
        }
        if ($CommandText.StartsWith('reg add')) {
            $registryState[$valueName] = 3
        }
        else {
            $registryState[$valueName] = $null
        }
        [pscustomobject]@{ Success = $true; Output = '' }
    }.GetNewClosure()

    $applyResult = & $module {
        param($RegistryInvoker, $RegistryReader)
        Invoke-BoostLabSpectreMeltdownAction `
            -ActionName 'Apply' `
            -AdministratorChecker { return $true } `
            -RegistryInvoker $RegistryInvoker `
            -RegistryReader $RegistryReader
    } $invoker $reader
    if (
        -not $applyResult.Success -or
        $applyResult.Action -ne 'Apply' -or
        $applyResult.Data.CommandStatus -ne 'Completed' -or
        $applyResult.VerificationResult.Status -ne 'Passed' -or
        $invocations.Count -ne 2 -or
        $invocations[0] -ne $applyMaskCommand -or
        $invocations[1] -ne $applyOverrideCommand
    ) {
        throw 'Mocked Spectre / Meltdown Apply path did not preserve the approved behavior.'
    }

    $invocations.Clear()
    $defaultResult = & $module {
        param($RegistryInvoker, $RegistryReader)
        Invoke-BoostLabSpectreMeltdownAction `
            -ActionName 'Default' `
            -AdministratorChecker { return $true } `
            -RegistryInvoker $RegistryInvoker `
            -RegistryReader $RegistryReader
    } $invoker $reader
    if (
        -not $defaultResult.Success -or
        $defaultResult.Action -ne 'Default' -or
        $defaultResult.Data.CommandStatus -ne 'Completed' -or
        $defaultResult.VerificationResult.Status -ne 'Passed' -or
        $invocations.Count -ne 2 -or
        $invocations[0] -ne $defaultMaskCommand -or
        $invocations[1] -ne $defaultOverrideCommand
    ) {
        throw 'Mocked Spectre / Meltdown Default path did not preserve the approved behavior.'
    }

    $invocations.Clear()
    $alreadyDefaultResult = & $module {
        param($RegistryInvoker, $RegistryReader)
        Invoke-BoostLabSpectreMeltdownAction `
            -ActionName 'Default' `
            -AdministratorChecker { return $true } `
            -RegistryInvoker $RegistryInvoker `
            -RegistryReader $RegistryReader
    } $invoker $reader
    if (
        -not $alreadyDefaultResult.Success -or
        $alreadyDefaultResult.Data.CommandStatus -ne 'Already default' -or
        $alreadyDefaultResult.VerificationResult.Status -ne 'Passed' -or
        $invocations.Count -ne 0 -or
        $alreadyDefaultResult.Message -notmatch 'already at the approved default'
    ) {
        throw 'Spectre / Meltdown Default is not idempotent when both values are already absent.'
    }
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
}

$executionModule = Import-Module `
    -Name $executionPath `
    -Force `
    -PassThru `
    -Scope Local `
    -ErrorAction Stop
try {
    $validatorBeforeDispatch = & $executionModule {
        [bool](Get-Command -Name 'Test-BoostLabVerificationResult' -ErrorAction SilentlyContinue)
    }
    if (-not $validatorBeforeDispatch) {
        throw 'Execution did not import Test-BoostLabVerificationResult before Spectre dispatch.'
    }

    $runtimeAnalyzeResult = & $executionModule {
        param($ToolMetadata)
        Invoke-BoostLabImplementedModuleAction `
            -ToolMetadata $ToolMetadata `
            -ActionName 'Analyze' `
            -Confirmed:$false
    } $tool
    if (-not $runtimeAnalyzeResult.Success) {
        throw "Spectre runtime Analyze dispatch failed: $($runtimeAnalyzeResult.Message)"
    }

    $validatorAfterDispatch = & $executionModule {
        [bool](Get-Command -Name 'Test-BoostLabVerificationResult' -ErrorAction SilentlyContinue)
    }
    if (-not $validatorAfterDispatch) {
        throw 'Spectre module unload removed Test-BoostLabVerificationResult from the production runtime.'
    }

    $runtimeValidation = & $executionModule {
        param($VerificationResult)
        Test-BoostLabVerificationResult `
            -VerificationResult $VerificationResult `
            -ExpectedToolId 'spectre-meltdown-assistant' `
            -ExpectedToolTitle 'Spectre / Meltdown Assistant' `
            -ExpectedAction 'Default'
    } $alreadyDefaultResult.VerificationResult
    if (-not $runtimeValidation.IsValid) {
        throw "Execution could not validate the mocked already-default result: $($runtimeValidation.Errors -join '; ')"
    }
}
finally {
    Remove-Module -ModuleInfo $executionModule -Force -ErrorAction SilentlyContinue
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    $analyzePlan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Analyze' -IsDryRun $false
    if (
        $analyzePlan.Summary -notmatch 'mitigation override values' -or
        (@($analyzePlan.SideEffects) -join ' ') -notmatch 'No system changes'
    ) {
        throw 'Spectre / Meltdown Analyze action plan is incomplete.'
    }

    $applyPlan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Apply' -IsDryRun $false
    if (
        -not $applyPlan.NeedsExplicitConfirmation -or
        -not $applyPlan.RequiresAdmin -or
        $applyPlan.CanReboot -or
        $applyPlan.ConfirmationMessage -notmatch 'reduces CPU vulnerability protection' -or
        (@($applyPlan.PlannedChanges) -join ' ') -notmatch 'FeatureSettingsOverrideMask'
    ) {
        throw 'Spectre / Meltdown Apply action plan does not show the required security warning.'
    }

    $defaultPlan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Default' -IsDryRun $false
    if (
        -not $defaultPlan.NeedsExplicitConfirmation -or
        $defaultPlan.ConfirmationMessage -notmatch 'remove only FeatureSettingsOverrideMask' -or
        (@($defaultPlan.PlannedChanges) -join ' ') -notmatch 'already-absent'
    ) {
        throw 'Spectre / Meltdown Default action plan is incomplete.'
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredText in @(
    '''spectre-meltdown-assistant'' = @{'
    '''Advanced\spectre-meltdown-assistant.psm1'''
    'Actions = @(''Analyze'', ''Apply'', ''Default'')'
)) {
    if (-not $executionSource.Contains($requiredText)) {
        throw "Spectre / Meltdown runtime mapping is missing: $requiredText"
    }
}

$record = Get-Content -Raw -LiteralPath $recordPath
foreach ($requiredText in @(
    'source-ultimate/8 Advanced/1 Spectre  Meltdown Assistant.ps1'
    $approvedSourceHash
    'FeatureSettingsOverrideMask'
    'FeatureSettingsOverride'
    'reduces CPU vulnerability protection'
    'Automated tests must be static or mocked only and must not modify real mitigation policy.'
)) {
    if (-not $record.Contains($requiredText)) {
        throw "Spectre / Meltdown migration record is missing: $requiredText"
    }
}

$allModules = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'modules') -Recurse -File -Filter '*.psm1' |
        Where-Object { $_.Directory.Parent.FullName -eq (Join-Path $ProjectRoot 'modules') }
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
$sourceLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
    Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
    ForEach-Object {
        '{0}|{1}' -f `
            $_.FullName.Substring($root.Length + 1).Replace('\', '/'), `
            (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    }
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
    @($sourceLines).Count -ne 49 -or
    $sourceManifestHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477'
) {
    throw 'source-ultimate content or paths changed.'
}

[pscustomobject]@{
    Success                 = $true
    ToolId                  = 'spectre-meltdown-assistant'
    ImplementedActions      = @('Analyze', 'Apply', 'Default')
    MockedApplyPassed       = $true
    MockedDefaultPassed     = $true
    IdempotentDefaultPassed = $true
    ImplementedModuleCount  = $implementedCount
    PlaceholderModuleCount  = $placeholderCount
    SourceUltimateUnchanged = $true
    Message                 = 'Spectre / Meltdown Assistant behavior was validated with mocked registry operations only.'
    Timestamp               = Get-Date
}
