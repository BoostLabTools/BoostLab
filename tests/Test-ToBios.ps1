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
        throw 'Unable to determine the To BIOS test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Refresh\to-bios.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\2 Refresh\4 To Bios.ps1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$safetyPath = Join-Path $ProjectRoot 'core\Safety.psm1'
$migrationPath = Join-Path $ProjectRoot 'docs\migrations\to-bios.md'

if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne 'A8371B42B235A6AC1F9661D96B430BEC0E4CAB6D9DE3CBD1461A02572220CA0C') {
    throw 'The Ultimate To BIOS source file was modified.'
}

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration['Stages'] | ForEach-Object { @($_['Tools']) })
$tool = $tools | Where-Object { $_['Id'] -eq 'to-bios' } | Select-Object -First 1
if ($null -eq $tool) {
    throw 'To BIOS metadata was not found.'
}
if (
    @($tool['Actions']) -join ',' -ne 'Analyze,Open' -or
    $tool['Type'] -ne 'assistant' -or
    $tool['RiskLevel'] -ne 'high'
) {
    throw 'To BIOS action, type, or risk metadata is incorrect.'
}
$capabilities = $tool['Capabilities']
if (
    -not [bool]$capabilities['RequiresAdmin'] -or
    -not [bool]$capabilities['CanReboot'] -or
    -not [bool]$capabilities['NeedsExplicitConfirmation']
) {
    throw 'To BIOS does not declare its Administrator, reboot, and confirmation requirements.'
}
foreach ($field in @(
    'RequiresInternet'
    'CanModifyRegistry'
    'CanModifyServices'
    'CanInstallSoftware'
    'CanDownload'
    'CanModifyDrivers'
    'CanModifySecurity'
    'CanDeleteFiles'
    'UsesTrustedInstaller'
    'UsesSafeMode'
    'SupportsDefault'
    'SupportsRestore'
)) {
    if ([bool]$capabilities[$field]) {
        throw "To BIOS declares an unrelated capability: $field"
    }
}

$module = Import-Module -Name $modulePath -Force -PassThru -Prefix 'ToBiosTool' -Scope Local -ErrorAction Stop
try {
    $toolInfo = Get-ToBiosToolBoostLabToolInfo
    $analysisResult = Invoke-ToBiosToolBoostLabToolAction -ActionName 'Analyze'
    $cancelledResult = Invoke-ToBiosToolBoostLabToolAction -ActionName 'Open'
    $unsupportedResult = Invoke-ToBiosToolBoostLabToolAction -ActionName 'Apply'

    if (@($toolInfo.ImplementedActions) -join ',' -ne 'Analyze,Open') {
        throw 'To BIOS implemented actions are incorrect.'
    }
    if (@($toolInfo.ConfirmationRequiredActions) -notcontains 'Open') {
        throw 'To BIOS Open is not marked confirmation-required.'
    }
    if (
        $toolInfo.ConfirmationText -notmatch 'restart immediately' -or
        $toolInfo.ConfirmationText -notmatch 'BIOS/UEFI'
    ) {
        throw 'To BIOS confirmation text is not explicit.'
    }
    if (-not $analysisResult.Success -or $analysisResult.RestartRequired) {
        throw 'To BIOS Analyze must succeed without requesting a restart.'
    }
    if (
        $analysisResult.Data.ApprovedCommand -ne 'cmd /c C:\Windows\System32\shutdown.exe /r /fw /t 0' -or
        -not [bool]$analysisResult.Data.ConfirmationRequired
    ) {
        throw 'To BIOS Analyze does not report the approved command and confirmation requirement.'
    }
    if ($cancelledResult.Success -or -not $cancelledResult.Cancelled -or $cancelledResult.RestartRequired) {
        throw 'To BIOS Open did not cancel safely without confirmation.'
    }
    if ($cancelledResult.Message -ne 'Cancelled by user') {
        throw 'To BIOS cancellation message is incorrect.'
    }
    if ($unsupportedResult.Success) {
        throw 'To BIOS accepted an unsupported action.'
    }
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
}

$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredText in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Open'')'
    '[bool]$Confirmed = $false'
    '$commandProcessorPath = Join-Path $env:SystemRoot ''System32\cmd.exe'''
    '$shutdownPath = Join-Path $env:SystemRoot ''System32\shutdown.exe'''
    '$firmwareRestartCommand = "`"$shutdownPath`" /r /fw /t 0"'
    '& $commandProcessorPath @firmwareRestartArguments'
    '$exitCode -ne 0'
    'VerificationResult'
)) {
    if (-not $moduleSource.Contains($requiredText)) {
        throw "To BIOS is missing approved behavior: $requiredText"
    }
}
foreach ($forbiddenText in @(
    'ToolModule.Placeholder.ps1'
    'Set-ItemProperty'
    'New-ItemProperty'
    'Remove-ItemProperty'
    'bcdedit'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'Set-Service'
    'Stop-Service'
    'pnputil'
    'devcon'
    'source-ultimate'
)) {
    if ($moduleSource.Contains($forbiddenText)) {
        throw "To BIOS contains unrelated behavior: $forbiddenText"
    }
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredText in @(
    '''to-bios'' = @{'
    'Refresh\to-bios.psm1'
    '$toolId -in @(''bios-settings'', ''to-bios'')'
    '[To BIOS] [Open] cancelled by user'
    '[To BIOS] [Open] restart to BIOS/UEFI requested'
    '-Confirmed:([bool]$safetyGate.Confirmed)'
)) {
    if (-not $executionSource.Contains($requiredText)) {
        throw "To BIOS runtime integration is missing: $requiredText"
    }
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
$safetyModule = Import-Module -Name $safetyPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    $analysisPlan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Analyze' -IsDryRun $false
    $openPlan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Open' -IsDryRun $false
    if (-not $analysisPlan.NeedsExplicitConfirmation) {
        throw 'To BIOS high-risk Analyze plan lost its conservative confirmation metadata.'
    }
    if (
        -not $openPlan.NeedsExplicitConfirmation -or
        -not $openPlan.CanReboot -or
        $openPlan.ConfirmationMessage -notmatch 'restart immediately' -or
        $openPlan.ConfirmationMessage -notmatch 'BIOS/UEFI'
    ) {
        throw 'To BIOS Open action plan is not confirmation-gated.'
    }

    $declinedGate = Test-BoostLabActionPlanExecutionGate `
        -ActionPlan $openPlan `
        -ConfirmationCallback { param($Plan) return $false }
    if ($declinedGate.IsAllowed -or $declinedGate.Confirmed -or -not $declinedGate.CallbackUsed) {
        throw 'The To BIOS Action Plan gate did not block declined confirmation.'
    }
}
finally {
    Remove-Module -ModuleInfo $safetyModule -Force -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$migrationSource = Get-Content -Raw -LiteralPath $migrationPath
foreach ($requiredText in @(
    'A8371B42B235A6AC1F9661D96B430BEC0E4CAB6D9DE3CBD1461A02572220CA0C'
    'cmd /c C:\Windows\System32\shutdown.exe /r /fw /t 0'
    'NeedsExplicitConfirmation = true'
    'never call `Open` with confirmation'
)) {
    if (-not $migrationSource.Contains($requiredText)) {
        throw "To BIOS migration record is missing: $requiredText"
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
if ($tools.Count -ne 55 -or $implementedCount -ne 40 -or $placeholderCount -ne 15) {
    throw "Unexpected To BIOS inventory: $($tools.Count) tools, $implementedCount implemented, $placeholderCount placeholders."
}

[pscustomobject]@{
    Success                 = $true
    ToolId                  = $toolInfo.Id
    ImplementedActions      = @($toolInfo.ImplementedActions)
    ImplementedModules      = $implementedCount
    PlaceholderModules      = $placeholderCount
    ConfirmedOpenExecuted   = $false
    CancelledOpenValidated  = $true
    SourceUltimateUnchanged = $true
    Message                 = 'To BIOS Analyze and confirmation guard validated without executing a restart.'
    Timestamp               = Get-Date
}


