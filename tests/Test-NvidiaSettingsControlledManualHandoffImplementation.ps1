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
        throw 'Unable to determine validator path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

function Assert-BoostLabCondition {
    param(
        [Parameter(Mandatory)]
        [bool]$Condition,

        [Parameter(Mandatory)]
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-BoostLabTextContains {
    param(
        [AllowNull()]
        [string]$Text,

        [Parameter(Mandatory)]
        [string]$Needle,

        [Parameter(Mandatory)]
        [string]$Description
    )

    if ([string]::IsNullOrEmpty($Text) -or -not $Text.Contains($Needle)) {
        throw "$Description missing expected text: $Needle"
    }
}

function Assert-BoostLabNoDuplicateWarnings {
    param(
        [Parameter(Mandatory)]
        [object]$Result,

        [Parameter(Mandatory)]
        [string]$Description
    )

    $resultWarnings = @($Result.Warnings | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    $dataWarnings = if ($null -ne $Result.Data -and $Result.Data.PSObject.Properties.Name -contains 'Warnings') {
        @($Result.Data.Warnings | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    }
    else {
        @()
    }

    foreach ($warning in $resultWarnings) {
        Assert-BoostLabCondition ($warning -notin $dataWarnings) "$Description duplicates warning at result and data level: $warning"
    }
    Assert-BoostLabCondition ((@($resultWarnings + $dataWarnings | Select-Object -Unique)).Count -eq @($resultWarnings + $dataWarnings).Count) "$Description contains duplicate warning entries."
}

function Get-BoostLabItemCount {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return 0
    }
    return @($Value).Count
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Graphics\nvidia-settings.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate\5 Graphics\4 Nvidia Settings.ps1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'

foreach ($path in @($configPath, $modulePath, $sourcePath, $executionPath, $actionPlanPath, $uiPath, $artifactPath, $productionAllowlistPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path) "Required file missing: $path"
}

$expectedSourceHash = '903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Nvidia Settings source hash mismatch: $actualSourceHash"

$config = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })
$graphicsStage = @($config.Stages | Where-Object { $_.Name -eq 'Graphics' })[0]
$driverCleanTool = @($graphicsStage.Tools | Where-Object { $_.Id -eq 'driver-clean' })[0]
$driverInstallLatestTool = @($graphicsStage.Tools | Where-Object { $_.Id -eq 'driver-install-latest' })[0]
$nvidiaSettingsTool = @($graphicsStage.Tools | Where-Object { $_.Id -eq 'nvidia-settings' })[0]
$pathATool = @($graphicsStage.Tools | Where-Object { $_.Id -eq 'driver-install-debloat-settings' })[0]

Assert-BoostLabCondition ($null -ne $nvidiaSettingsTool) 'Nvidia Settings is missing from Graphics stage.'
Assert-BoostLabCondition ([int]$driverCleanTool.Order -eq 1) 'Driver Clean must remain Graphics order 1.'
Assert-BoostLabCondition ([int]$driverInstallLatestTool.Order -eq 2) 'Driver Install Latest must remain Graphics order 2.'
Assert-BoostLabCondition ([int]$nvidiaSettingsTool.Order -eq 3) 'Nvidia Settings must be Graphics order 3 as Path B step 2.'
Assert-BoostLabCondition ([int]$pathATool.Order -eq 7) 'Path A Driver Install Debloat & Settings must remain separate after Msi Mode.'
Assert-BoostLabCondition ([string]$nvidiaSettingsTool.Type -eq 'assistant') 'Nvidia Settings must be an assistant.'
Assert-BoostLabCondition ([string]$nvidiaSettingsTool.RiskLevel -eq 'high') 'Nvidia Settings must remain high risk.'
Assert-BoostLabCondition ((@($nvidiaSettingsTool.Actions) -join ',') -eq 'Analyze,Open,Apply') 'Nvidia Settings actions must stay canonical Analyze/Open/Apply.'
Assert-BoostLabCondition ([bool]$nvidiaSettingsTool.Capabilities.NeedsExplicitConfirmation) 'Nvidia Settings must require explicit confirmation.'

foreach ($falseCapability in @(
    'RequiresAdmin',
    'RequiresInternet',
    'CanReboot',
    'CanModifyRegistry',
    'CanModifyServices',
    'CanInstallSoftware',
    'CanDownload',
    'CanModifyDrivers',
    'CanModifySecurity',
    'CanDeleteFiles',
    'UsesTrustedInstaller',
    'UsesSafeMode',
    'SupportsDefault',
    'SupportsRestore'
)) {
    Assert-BoostLabCondition (-not [bool]$nvidiaSettingsTool.Capabilities[$falseCapability]) "Nvidia Settings capability should be false: $falseCapability"
}

Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Id -eq 'hdcp' })) -eq 1) 'HDCP must remain active as its own separate controlled registry Path B step.'
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Id -eq 'p0-state' })) -eq 1) 'P0 State must remain active as its own separate controlled registry Path B step.'
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Id -eq 'msi-mode' })) -eq 1) 'Msi Mode must remain active as its own separate controlled registry Path B step.'
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Id -eq 'ddu' -or $_.Title -eq 'DDU' })) -eq 0) 'Standalone DDU was reintroduced.'

$placeholderModules = @(
    Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
Assert-BoostLabCondition ($allTools.Count -eq 55) "Expected 55 active tools, found $($allTools.Count)."
Assert-BoostLabCondition ($placeholderModules.Count -eq 17) "Expected 17 deferred/placeholders, found $($placeholderModules.Count)."
Assert-BoostLabCondition (($allTools.Count - $placeholderModules.Count) -eq 38) "Expected 38 implemented tools, found $($allTools.Count - $placeholderModules.Count)."

$sourcePromotedFiles = @(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate') -Recurse -File)
Assert-BoostLabCondition ($sourcePromotedFiles.Count -eq 7) "Expected 7 source-promoted mirror files, found $($sourcePromotedFiles.Count)."
$remainingSourcePromoted = @(
    $sourcePromotedFiles | Where-Object {
        $_.Name -notin @('1 Driver Clean.ps1', '2 Driver Install Latest.ps1', '4 Nvidia Settings.ps1', '5 Hdcp.ps1', '6 P0 State.ps1', '7 Msi Mode.ps1', '1 BitLocker.ps1')
    }
)
Assert-BoostLabCondition ($remainingSourcePromoted.Count -eq 0) "Expected 0 remaining unimplemented source-promoted intake candidates, found $($remainingSourcePromoted.Count)."

$executionText = Get-Content -LiteralPath $executionPath -Raw
foreach ($needle in @(
    "'nvidia-settings'",
    "Graphics\nvidia-settings.psm1",
    "'Analyze', 'Open', 'Apply'"
)) {
    Assert-BoostLabTextContains -Text $executionText -Needle $needle -Description 'Execution registration'
}

$uiText = Get-Content -LiteralPath $uiPath -Raw
foreach ($needle in @(
    "'driver-clean', 'driver-install-latest', 'nvidia-settings'",
    "'Open' { return 'Manual Handoff' }",
    "'Apply' { return 'Apply Auto' }"
)) {
    Assert-BoostLabTextContains -Text $uiText -Needle $needle -Description 'UI display label mapping'
}

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
Assert-BoostLabTextContains -Text $actionPlanText -Needle "[ValidateSet('Apply', 'Default', 'Open', 'Analyze', 'Restore')]" -Description 'Action plan canonical ValidateSet'
Assert-BoostLabCondition (-not $actionPlanText.Contains("'Manual Handoff'")) 'Action plan ValidateSet must not include display label Manual Handoff.'
Assert-BoostLabCondition (-not $actionPlanText.Contains("'Apply Auto'")) 'Action plan ValidateSet must not include display label Apply Auto.'
foreach ($needle in @(
    'Prepare Nvidia Settings manual handoff instructions only',
    'Auto mode is blocked for Nvidia Settings',
    'Do not download or install 7-Zip.',
    'Do not download or run NVIDIA Profile Inspector.',
    'Do not import, export, or generate a .nip file for execution.',
    'Do not open NVIDIA Control Panel, a browser, external tool, or approved external resource.',
    'No approved Auto behavior, 7-Zip download/install, Profile Inspector execution, .nip import/export, external process, Control Panel launch, registry/profile mutation, or system-changing operation occurs.'
)) {
    Assert-BoostLabTextContains -Text $actionPlanText -Needle $needle -Description 'Nvidia Settings action plan wording'
}

$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($needle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Open'', ''Apply'')',
    $expectedSourceHash,
    'ManualHandoffOnly',
    'AutoBlockedUntilArtifactApproval',
    'PathBStep = ''2 of 5'''
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'Nvidia Settings module text'
}

foreach ($forbiddenPattern in @(
    '^\s*Start-Process\b',
    '^\s*Invoke-WebRequest\b',
    '^\s*IWR\b',
    '^\s*Set-ItemProperty\b',
    '^\s*New-Item\b',
    '^\s*Set-Content\b',
    '^\s*Move-Item\b',
    '^\s*Remove-Item\b',
    '^\s*Unblock-File\b',
    '^\s*reg\.exe\b',
    '^\s*cmd\b',
    '^\s*bcdedit\b',
    '^\s*shutdown\b',
    '^\s*Restart-Computer\b'
)) {
    Assert-BoostLabCondition (-not [regex]::IsMatch($moduleText, $forbiddenPattern, [System.Text.RegularExpressions.RegexOptions]::Multiline -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) "Nvidia Settings module contains forbidden side-effect command pattern: $forbiddenPattern"
}

Import-Module -Name $modulePath -Force -ErrorAction Stop
try {
    $info = Get-BoostLabToolInfo
    Assert-BoostLabCondition ([string]$info.Id -eq 'nvidia-settings') 'Module info Id mismatch.'
    Assert-BoostLabCondition ((@($info.ImplementedActions) -join ',') -eq 'Analyze,Open,Apply') 'Implemented action list mismatch.'

    $analyzeResult = Invoke-BoostLabToolAction -ActionName 'Analyze'
    Assert-BoostLabCondition ([bool]$analyzeResult.Success) 'Analyze should succeed when source checksum is valid.'
    Assert-BoostLabCondition ([string]$analyzeResult.Status -eq 'Analyzed') 'Analyze status mismatch.'
    Assert-BoostLabCondition ([string]$analyzeResult.CommandStatus -eq 'No execution performed') 'Analyze must not execute anything.'
    Assert-BoostLabCondition ([string]$analyzeResult.Data.Mode -eq 'ManualHandoffOnly') 'Analyze mode mismatch.'
    Assert-BoostLabCondition ([string]$analyzeResult.Data.AutoMode -eq 'AutoBlockedUntilArtifactApproval') 'Analyze Auto mode mismatch.'
    Assert-BoostLabCondition ([int]$analyzeResult.Data.PathBStepNumber -eq 2 -and [int]$analyzeResult.Data.PathBStepTotal -eq 5) 'Analyze Path B step mismatch.'
    foreach ($flag in @('NoAutomatedExecution', 'NoSevenZipDownloadedOrInstalled', 'NoProfileInspectorDownloadedOrExecuted', 'NoNipImportedExportedOrGeneratedForExecution', 'NoNvidiaProfileChanged', 'NoRegistrySettingChanged', 'NoExternalProcessStarted', 'NoBrowserOpened', 'NoNvidiaControlPanelLaunched', 'NoSystemMutation')) {
        Assert-BoostLabCondition ([bool]$analyzeResult.Data.$flag) "Analyze expected flag true: $flag"
    }
    foreach ($approval in @(
        '7-Zip artifact/download/install approval',
        'NVIDIA Profile Inspector artifact/download/execution approval',
        '.nip import/export approval',
        'NVIDIA profile state capture/restore approval',
        'NVIDIA registry/file rollback capture approval',
        'process handling approval',
        'verification approval'
    )) {
        Assert-BoostLabCondition ($approval -in @($analyzeResult.Data.MissingApprovals)) "Analyze missing approval not reported: $approval"
    }
    Assert-BoostLabNoDuplicateWarnings -Result $analyzeResult -Description 'Nvidia Settings Analyze'

    $cancelledResult = Invoke-BoostLabToolAction -ActionName 'Manual Handoff'
    Assert-BoostLabCondition (-not [bool]$cancelledResult.Success) 'Unconfirmed Manual Handoff should not proceed.'
    Assert-BoostLabCondition ([bool]$cancelledResult.Cancelled) 'Unconfirmed Manual Handoff should be cancelled.'
    Assert-BoostLabCondition ([string]$cancelledResult.Action -eq 'Open') 'Manual Handoff should route through canonical Open.'

    $handoffResult = Invoke-BoostLabToolAction -ActionName 'Manual Handoff' -Confirmed:$true
    Assert-BoostLabCondition ([bool]$handoffResult.Success) 'Confirmed Manual Handoff should succeed.'
    Assert-BoostLabCondition ([string]$handoffResult.Action -eq 'Open') 'Confirmed Manual Handoff should return canonical Open action.'
    Assert-BoostLabCondition ([string]$handoffResult.Status -eq 'ManualHandoffPrepared') 'Manual Handoff status mismatch.'
    Assert-BoostLabCondition ([string]$handoffResult.CommandStatus -eq 'No execution performed') 'Manual Handoff must not execute anything.'
    foreach ($needle in @(
        'No 7-Zip downloaded or installed',
        'no NVIDIA Profile Inspector downloaded or executed',
        'no .nip imported or exported',
        'no NVIDIA Control Panel launched',
        'no external process started',
        'no NVIDIA profile or registry setting changed',
        'no system mutation occurred'
    )) {
        Assert-BoostLabTextContains -Text ([string]$handoffResult.Message) -Needle $needle -Description 'Manual Handoff result message'
    }
    Assert-BoostLabNoDuplicateWarnings -Result $handoffResult -Description 'Nvidia Settings Manual Handoff'

    $autoResult = Invoke-BoostLabToolAction -ActionName 'Apply Auto' -Confirmed:$true
    Assert-BoostLabCondition (-not [bool]$autoResult.Success) 'Apply Auto must fail closed.'
    Assert-BoostLabCondition ([string]$autoResult.Action -eq 'Apply') 'Apply Auto should route through canonical Apply.'
    Assert-BoostLabCondition ([string]$autoResult.Status -eq 'AutoBlockedUntilArtifactApproval') 'Apply Auto status mismatch.'
    Assert-BoostLabCondition ([string]$autoResult.CommandStatus -eq 'Blocked before execution') 'Apply Auto must block before execution.'
    Assert-BoostLabTextContains -Text ([string]$autoResult.Message) -Needle 'AutoBlockedUntilArtifactApproval' -Description 'Apply Auto blocked message'
    Assert-BoostLabTextContains -Text ([string]$autoResult.Message) -Needle 'No 7-Zip download/install' -Description 'Apply Auto no-action message'
    Assert-BoostLabTextContains -Text ([string]$autoResult.Message) -Needle 'Profile Inspector execution' -Description 'Apply Auto Profile Inspector blocked message'
    Assert-BoostLabNoDuplicateWarnings -Result $autoResult -Description 'Nvidia Settings Apply Auto'

    foreach ($unsupportedAction in @('Default', 'Restore')) {
        $unsupportedResult = Invoke-BoostLabToolAction -ActionName $unsupportedAction
        Assert-BoostLabCondition (-not [bool]$unsupportedResult.Success) "$unsupportedAction should be unavailable."
        Assert-BoostLabCondition ([string]$unsupportedResult.Status -eq 'Unavailable') "$unsupportedAction status mismatch."
    }
}
finally {
    Remove-Module -Name 'nvidia-settings' -Force -ErrorAction SilentlyContinue
}

$previousProgramData = $env:ProgramData
$tempProgramData = Join-Path ([System.IO.Path]::GetTempPath()) ('BoostLab-NvidiaSettings-' + [guid]::NewGuid().ToString('N'))
New-Item -Path $tempProgramData -ItemType Directory -Force | Out-Null
$env:ProgramData = $tempProgramData
try {
    Import-Module -Name (Join-Path $ProjectRoot 'core\Logging.psm1') -Force -ErrorAction Stop
    Import-Module -Name (Join-Path $ProjectRoot 'core\State.psm1') -Force -ErrorAction Stop
    Initialize-BoostLabLogging -DisableFileLogging | Out-Null
    Initialize-BoostLabState | Out-Null
    Import-Module -Name $executionPath -Force -ErrorAction Stop

    $runtimeAnalyze = Invoke-BoostLabToolAction -ToolMetadata $nvidiaSettingsTool -ActionName 'Analyze'
    Assert-BoostLabCondition ([bool]$runtimeAnalyze.Success) 'Runtime Analyze should succeed.'
    Assert-BoostLabCondition ($null -ne $runtimeAnalyze.ActionPlan) 'Runtime Analyze should include ActionPlan.'
    Assert-BoostLabTextContains -Text ([string]$runtimeAnalyze.ActionPlan.Summary) -Needle 'without changing settings' -Description 'Runtime Analyze Action Plan summary'

    $runtimeHandoff = Invoke-BoostLabToolAction -ToolMetadata $nvidiaSettingsTool -ActionName 'Open'
    Assert-BoostLabCondition (-not [bool]$runtimeHandoff.Success) 'Runtime unconfirmed Manual Handoff should be blocked/cancelled.'
    Assert-BoostLabCondition ($null -ne $runtimeHandoff.ActionPlan) 'Runtime Manual Handoff should include ActionPlan.'
    $runtimeHandoffPlanText = @(
        $runtimeHandoff.ActionPlan.Summary
        @($runtimeHandoff.ActionPlan.PlannedChanges)
        @($runtimeHandoff.ActionPlan.SideEffects)
        $runtimeHandoff.ActionPlan.ConfirmationMessage
    ) -join "`n"
    foreach ($needle in @(
        'manual handoff instructions only',
        'Do not download or install 7-Zip.',
        'Do not download or run NVIDIA Profile Inspector.',
        'Do not import, export, or generate a .nip file for execution.',
        'Do not open NVIDIA Control Panel',
        'No 7-Zip download/install, NVIDIA Profile Inspector download/execution, .nip import/export, browser, Control Panel launch, external process, or system-changing operation occurs'
    )) {
        Assert-BoostLabTextContains -Text $runtimeHandoffPlanText -Needle $needle -Description 'Manual Handoff runtime plan text'
    }
    Assert-BoostLabCondition (-not $runtimeHandoffPlanText.Contains('approved external resource may be opened')) 'Manual Handoff Action Plan must not use generic Open resource wording.'

    $runtimeAuto = Invoke-BoostLabToolAction -ToolMetadata $nvidiaSettingsTool -ActionName 'Apply' -RiskConfirmed
    Assert-BoostLabCondition (-not [bool]$runtimeAuto.Success) 'Runtime Apply Auto should fail closed.'
    Assert-BoostLabCondition ([string]$runtimeAuto.Status -eq 'AutoBlockedUntilArtifactApproval') 'Runtime Apply Auto status mismatch.'
    $runtimeAutoPlanText = @(
        $runtimeAuto.ActionPlan.Summary
        @($runtimeAuto.ActionPlan.PlannedChanges)
        @($runtimeAuto.ActionPlan.SideEffects)
        $runtimeAuto.ActionPlan.ConfirmationMessage
    ) -join "`n"
    foreach ($needle in @(
        'Auto mode is blocked',
        'Do not execute any approved Auto behavior because none is approved.',
        '7-Zip artifact/download/install approval',
        'NVIDIA Profile Inspector artifact/download/execution approval',
        '.nip import/export approval',
        'No approved Auto behavior, 7-Zip download/install, Profile Inspector execution, .nip import/export, external process, Control Panel launch, registry/profile mutation, or system-changing operation occurs.'
    )) {
        Assert-BoostLabTextContains -Text $runtimeAutoPlanText -Needle $needle -Description 'Apply Auto runtime plan text'
    }
    Assert-BoostLabCondition (-not $runtimeAutoPlanText.Contains('Apply the approved Nvidia Settings behavior')) 'Apply Auto Action Plan must not use generic Apply wording.'
}
finally {
    $env:ProgramData = $previousProgramData
    Remove-Item -LiteralPath $tempProgramData -Recurse -Force -ErrorAction SilentlyContinue
}

$artifactConfig = Import-PowerShellDataFile -LiteralPath $artifactPath
$artifactText = Get-Content -LiteralPath $artifactPath -Raw
foreach ($forbiddenArtifactText in @('7zip.exe', 'inspector.exe', 'NVIDIA Profile Inspector', 'inspector.nip', 'FR33THYFR33THY')) {
    Assert-BoostLabCondition (-not $artifactText.Contains($forbiddenArtifactText)) "Unexpected artifact approval related to Nvidia Settings: $forbiddenArtifactText"
}
if ($artifactConfig.ContainsKey('Artifacts')) {
    foreach ($artifact in @($artifactConfig.Artifacts)) {
        $artifactTextLine = (($artifact.GetEnumerator() | ForEach-Object { '{0}={1}' -f $_.Key, $_.Value }) -join ';')
        Assert-BoostLabCondition ($artifactTextLine -notmatch '(?i)7-zip|7zip|inspector|nvidia profile|\.nip') "Unexpected artifact approval related to Nvidia Settings: $artifactTextLine"
    }
}

$productionPolicy = Import-PowerShellDataFile -LiteralPath $productionAllowlistPath
if ($productionPolicy.ContainsKey('ProductionAllowlistProposals')) {
    Assert-BoostLabCondition (@($productionPolicy.ProductionAllowlistProposals).Count -eq 0) 'Production allowlist proposals should remain empty.'
}

foreach ($deletedPath in @(
    'source-ultimate\6 Windows\17 Loudness EQ.ps1',
    'source-ultimate\6 Windows\30 NVME Faster Driver.ps1'
)) {
    Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $deletedPath))) "Deleted source was reintroduced: $deletedPath"
}

[pscustomobject]@{
    TestName = 'Nvidia Settings controlled manual handoff implementation'
    ActiveTools = $allTools.Count
    ImplementedTools = $allTools.Count - $placeholderModules.Count
    DeferredPlaceholders = $placeholderModules.Count
    SourcePromotedMirrorFiles = $sourcePromotedFiles.Count
    RemainingUnimplementedSourcePromotedCandidates = $remainingSourcePromoted.Count
    SourceHash = $actualSourceHash
    NvidiaSettingsActions = @($nvidiaSettingsTool.Actions)
    AutoMode = 'AutoBlockedUntilArtifactApproval'
}


