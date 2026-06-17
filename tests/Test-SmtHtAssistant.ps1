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
        throw 'Unable to determine the SMT / HT Assistant test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Advanced\smt-ht-assistant.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\8 Advanced\4 SMT  HT Assistant.ps1'
$recordPath = Join-Path $ProjectRoot 'docs\migrations\smt-ht-assistant.md'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration['Stages'] | ForEach-Object { $_['Tools'] })
$tool = $tools | Where-Object { $_['Id'] -eq 'smt-ht-assistant' } | Select-Object -First 1
if ($null -eq $tool) {
    throw 'SMT / HT Assistant metadata is missing.'
}
if (
    [string]$tool['Stage'] -ne 'Advanced' -or
    [int]$tool['Order'] -ne 4 -or
    [string]$tool['Type'] -ne 'assistant' -or
    [string]$tool['RiskLevel'] -ne 'high' -or
    (@($tool['Actions']) -join ',') -ne 'Analyze,Apply,Open'
) {
    throw 'SMT / HT Assistant metadata is incorrect.'
}

$capabilities = $tool['Capabilities']
foreach ($field in @('RequiresAdmin', 'NeedsExplicitConfirmation')) {
    if (-not [bool]$capabilities[$field]) {
        throw "SMT / HT Assistant capability '$field' must be true."
    }
}
foreach ($field in @('RequiresInternet', 'CanReboot', 'CanModifyRegistry', 'CanModifyServices', 'CanInstallSoftware', 'CanDownload', 'CanModifyDrivers', 'CanModifySecurity', 'CanDeleteFiles', 'UsesTrustedInstaller', 'UsesSafeMode', 'SupportsDefault', 'SupportsRestore')) {
    if ([bool]$capabilities[$field]) {
        throw "SMT / HT Assistant capability '$field' must be false."
    }
}

if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne '5D53BF2A9A589ECB14D9F8F9048FF4830D2E6F4DEE7E4B54BA6B6B6F77F004FE') {
    throw 'SMT / HT Assistant Ultimate source hash changed.'
}

$source = Get-Content -Raw -LiteralPath $sourcePath
$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredSourceText in @(
    'NumberOfLogicalProcessors'
    'WorkingSet64 -gt 500MB'
    'ProcessorAffinity = $hexadecimal'
    '$stop = "Battle.net", "BsgLauncher", "EADesktop", "EpicGamesLauncher", "GalaxyClient", "RobloxPlayerBeta", "RiotClientServices", "Launcher", "steam", "upc"'
    'cmd /c "start `"`" /affinity $hexadecimal `"$gamelauncher`""'
    'Start-Sleep -Seconds 10'
)) {
    if (-not $source.Contains($requiredSourceText)) {
        throw "SMT / HT Assistant source no longer contains: $requiredSourceText"
    }
}

foreach ($requiredModuleText in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Open'')'
    'function Get-BoostLabSmtHtAffinityProfile'
    'WorkingSet64 -gt 500MB'
    '$script:BoostLabLauncherStopList = @('
    'ProcessorAffinity = [int]$affinityProfile.IntegerMask'
    'Show-BoostLabSmtHtProcessSelectionDialog'
    'Show-BoostLabSmtHtExecutableSelectionDialog'
    'Start-Sleep -Seconds $Seconds'
    '[bool]$Confirmed = $false'
)) {
    if (-not $moduleSource.Contains($requiredModuleText)) {
        throw "SMT / HT Assistant module is missing: $requiredModuleText"
    }
}

foreach ($forbiddenText in @(
    'Restart-Computer'
    'Stop-Computer'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'Set-ItemProperty'
    'New-ItemProperty'
    'Remove-ItemProperty'
    'UsesTrustedInstaller = $true'
    'safeboot'
)) {
    if ($moduleSource.Contains($forbiddenText)) {
        throw "SMT / HT Assistant module contains unrelated behavior: $forbiddenText"
    }
}

$module = Import-Module -Name $modulePath -Force -PassThru -Prefix 'SmtHtTest' -Scope Local -DisableNameChecking -ErrorAction Stop
try {
    $infoCommand = Get-Command -Name 'Get-SmtHtTestBoostLabToolInfo' -Module $module.Name -ErrorAction Stop
    $compatibilityCommand = Get-Command -Name 'Test-SmtHtTestBoostLabToolCompatibility' -Module $module.Name -ErrorAction Stop

    $toolInfo = & $infoCommand
    if (
        [string]$toolInfo.Id -ne 'smt-ht-assistant' -or
        (@($toolInfo.Actions) -join ',') -ne 'Analyze,Apply,Open' -or
        (@($toolInfo.ImplementedActions) -join ',') -ne 'Analyze,Apply,Open'
    ) {
        throw 'SMT / HT Assistant exported metadata or implemented actions are incorrect.'
    }

    $scalarCommandResolver = {
        param($CommandName)
        [pscustomobject]@{ Name = $CommandName }
    }
    $compatibility = & $compatibilityCommand -CommandResolver $scalarCommandResolver
    if (-not $compatibility.Supported) {
        throw 'SMT / HT Assistant compatibility failed when required commands were available.'
    }

    $analysis = & $module {
        Get-BoostLabSmtHtAnalyzeData `
            -LogicalProcessorReader { 8 } `
            -CandidateReader {
                @(
                    [pscustomobject]@{ Name = 'GameA'; Id = 101; WorkingSetMB = 1200.50 }
                    [pscustomobject]@{ Name = 'GameB'; Id = 202; WorkingSetMB = 900.25 }
                )
            }
    }
    if (
        [int]$analysis.LogicalProcessorCount -ne 8 -or
        [string]$analysis.GeneratedBinaryMask -ne '01010101' -or
        [string]$analysis.GeneratedHexMask -ne '55' -or
        [int]$analysis.CandidateProcessCount -ne 2
    ) {
        throw 'SMT / HT Assistant Analyze data did not return the expected structured result.'
    }

    $cancelledApply = & $module {
        Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$false
    }
    if (-not $cancelledApply.Cancelled -or $cancelledApply.Message -ne 'Cancelled by user') {
        throw 'SMT / HT Assistant Apply confirmation handling is incorrect.'
    }

    $applyResult = & $module {
        $process = [pscustomobject]@{
            Id = 4242
            ProcessName = 'GameX'
            ProcessorAffinity = 0
        }
        Invoke-BoostLabSmtHtApplyAction `
            -AdministratorChecker { return $true } `
            -LogicalProcessorReader { 8 } `
            -CandidateReader {
                @([pscustomobject]@{ Name = 'GameX'; Id = 4242; WorkingSetMB = 1500.00 })
            } `
            -ProcessSelector {
                param($Candidates)
                $Candidates[0]
            } `
            -ProcessReaderById {
                param($ProcessId)
                $process
            }
    }
    if (
        -not $applyResult.Success -or
        $applyResult.Action -ne 'Apply' -or
        $applyResult.VerificationResult.Status -ne 'Passed' -or
        [int]$applyResult.Data.IntegerMask -ne 85 -or
        [string]$applyResult.VerificationResult.DetectedState.BinaryMask -ne '01010101'
    ) {
        throw 'Mocked SMT / HT Assistant Apply path did not return the expected structured result.'
    }

    $stoppedLaunchers = [System.Collections.Generic.List[string]]::new()
    $launchInvocations = [System.Collections.Generic.List[string]]::new()
    $sleepCalls = [System.Collections.Generic.List[int]]::new()
    $openResult = & $module {
        param($StoppedLaunchers, $LaunchInvocations, $SleepCalls)
        $process = [pscustomobject]@{
            Id = 5151
            ProcessName = 'MyGame'
            ProcessorAffinity = 85
        }
        Invoke-BoostLabSmtHtOpenAction `
            -AdministratorChecker { return $true } `
            -LogicalProcessorReader { 8 } `
            -LauncherStopper {
                param($ProcessName)
                $StoppedLaunchers.Add($ProcessName) | Out-Null
            } `
            -ExecutableSelector { 'C:\Games\MyGame.exe' } `
            -LauncherInvoker {
                param($HexMask, $TargetPath)
                $LaunchInvocations.Add("$HexMask|$TargetPath") | Out-Null
            } `
            -ProcessReaderByName {
                param($ProcessName)
                $process
            } `
            -Sleeper {
                param($Seconds)
                $SleepCalls.Add([int]$Seconds) | Out-Null
            }
    } $stoppedLaunchers $launchInvocations $sleepCalls
    if (
        -not $openResult.Success -or
        $openResult.Action -ne 'Open' -or
        $openResult.VerificationResult.Status -ne 'Passed' -or
        $stoppedLaunchers.Count -ne 10 -or
        $launchInvocations.Count -ne 1 -or
        $launchInvocations[0] -ne '55|C:\Games\MyGame.exe' -or
        $sleepCalls.Count -ne 1 -or
        $sleepCalls[0] -ne 10
    ) {
        throw 'Mocked SMT / HT Assistant Open path did not preserve the expected launcher-stop and affinity-launch behavior.'
    }
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    $analyzePlan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Analyze' -IsDryRun $false
    if (
        -not $analyzePlan.RequiresAdmin -or
        $analyzePlan.Summary -notmatch 'processor topology'
    ) {
        throw 'SMT / HT Assistant Analyze action plan is incorrect.'
    }

    foreach ($actionName in @('Apply', 'Open')) {
        $plan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName $actionName -IsDryRun $false
        if (
            -not $plan.NeedsExplicitConfirmation -or
            -not $plan.RequiresAdmin -or
            $plan.CanReboot
        ) {
            throw "SMT / HT Assistant $actionName action plan is incorrect."
        }
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredText in @(
    '''smt-ht-assistant'' = @{'
    '''Advanced\smt-ht-assistant.psm1'''
    'Actions = @(''Analyze'', ''Apply'', ''Open'')'
)) {
    if (-not $executionSource.Contains($requiredText)) {
        throw "SMT / HT Assistant runtime mapping is missing: $requiredText"
    }
}

$record = Get-Content -Raw -LiteralPath $recordPath
foreach ($requiredText in @(
    'source-ultimate/8 Advanced/4 SMT  HT Assistant.ps1'
    '5D53BF2A9A589ECB14D9F8F9048FF4830D2E6F4DEE7E4B54BA6B6B6F77F004FE'
    'Off: Already Running'
    'Off: Startup'
    'Automated tests must be static or mocked only and must not modify the affinity of real user processes.'
)) {
    if (-not $record.Contains($requiredText)) {
        throw "SMT / HT Assistant migration record is missing: $requiredText"
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
if ($implementedCount -ne 33 -or $placeholderCount -ne 18) {
    throw "Unexpected module counts: $implementedCount implemented, $placeholderCount placeholders."
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
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
    ToolId                  = 'smt-ht-assistant'
    ImplementedActions      = @('Analyze', 'Apply', 'Open')
    MockedApplyPassed       = $true
    MockedOpenPassed        = $true
    ImplementedModuleCount  = $implementedCount
    PlaceholderModuleCount  = $placeholderCount
    SourceUltimateUnchanged = $true
    Message                 = 'SMT / HT Assistant behavior and mocked verification were validated without changing live process affinity.'
    Timestamp               = Get-Date
}

