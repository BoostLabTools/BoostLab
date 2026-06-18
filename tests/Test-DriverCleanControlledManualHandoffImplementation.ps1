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
        throw 'Unable to determine the Driver Clean manual handoff validator path.'
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
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [string]$Needle,

        [Parameter(Mandatory)]
        [string]$Description
    )

    if (-not $Text.Contains($Needle)) {
        throw "$Description is missing: $Needle"
    }
}

function Get-BoostLabItemCount {
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return 0
    }

    return @($Value).Count
}

function Assert-BoostLabNoDuplicateWarnings {
    param(
        [Parameter(Mandatory)]
        [object]$Result,

        [Parameter(Mandatory)]
        [string]$Description
    )

    $resultWarnings = @($Result.Warnings)
    $dataWarnings = if ($null -ne $Result.Data -and $null -ne $Result.Data.PSObject.Properties['Warnings']) {
        @($Result.Data.Warnings)
    }
    else {
        @()
    }
    $combinedWarnings = @($resultWarnings + $dataWarnings)
    $uniqueWarnings = @($combinedWarnings | Select-Object -Unique)

    Assert-BoostLabCondition ($resultWarnings.Count -eq 0) "$Description should not duplicate Data warnings at result level."
    Assert-BoostLabCondition ($combinedWarnings.Count -eq $uniqueWarnings.Count) "$Description contains duplicate warning text."
}

$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$modulePath = Join-Path $ProjectRoot 'modules\Graphics\driver-clean.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate\5 Graphics\1 Driver Clean.ps1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

foreach ($path in @($stagesPath, $executionPath, $actionPlanPath, $modulePath, $uiPath, $sourcePath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required file was not found: $path"
}

$expectedSourceHash = 'CF9E1C55ACAFD8A52D2200AC3E6C3AFDF9823837C7B68101C2D4B83E074D325A'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Driver Clean source mirror hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."

$config = Import-PowerShellDataFile -LiteralPath $stagesPath
$graphicsStage = @($config.Stages | Where-Object { $_.Name -eq 'Graphics' })[0]
Assert-BoostLabCondition ($null -ne $graphicsStage) 'Graphics stage was not found.'

$driverCleanTool = @($graphicsStage.Tools | Where-Object { $_.Id -eq 'driver-clean' })[0]
Assert-BoostLabCondition ($null -ne $driverCleanTool) 'Driver Clean was not added as an active Graphics tool.'
Assert-BoostLabCondition ([string]$driverCleanTool.Title -eq 'Driver Clean') 'Driver Clean title mismatch.'
Assert-BoostLabCondition ([int]$driverCleanTool.Order -eq 1) 'Driver Clean must remain a separate first Graphics tool.'
Assert-BoostLabCondition ([string]$driverCleanTool.Type -eq 'assistant') 'Driver Clean must be an assistant tool.'
Assert-BoostLabCondition ([string]$driverCleanTool.RiskLevel -eq 'high') 'Driver Clean must remain high risk.'
Assert-BoostLabCondition ((@($driverCleanTool.Actions) -join '|') -eq 'Analyze|Open|Apply') 'Driver Clean actions must be canonical Analyze, Open, Apply.'
Assert-BoostLabTextContains -Text ([string]$driverCleanTool.Description) -Needle 'Manual handoff only' -Description 'Driver Clean description'
Assert-BoostLabTextContains -Text ([string]$driverCleanTool.Description) -Needle 'No automated DDU download' -Description 'Driver Clean description'
Assert-BoostLabTextContains -Text ([string]$driverCleanTool.Description) -Needle 'DDU execution' -Description 'Driver Clean description'

$capabilities = $driverCleanTool.Capabilities
foreach ($falseCapability in @(
    'RequiresAdmin'
    'RequiresInternet'
    'CanReboot'
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
    Assert-BoostLabCondition (-not [bool]$capabilities[$falseCapability]) "Driver Clean capability should be false: $falseCapability"
}
Assert-BoostLabCondition ([bool]$capabilities['NeedsExplicitConfirmation']) 'Driver Clean manual handoff should require explicit confirmation.'

$allTools = @($config.Stages | ForEach-Object { $_.Tools })
$placeholderModules = @(
    Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
Assert-BoostLabCondition ($allTools.Count -eq 55) "Expected 55 active tools, found $($allTools.Count)."
Assert-BoostLabCondition ($placeholderModules.Count -eq 17) "Expected 17 deferred/placeholders, found $($placeholderModules.Count)."
Assert-BoostLabCondition (($allTools.Count - $placeholderModules.Count) -eq 38) "Expected 38 implemented tools, found $($allTools.Count - $placeholderModules.Count)."

$sourcePromotedFiles = @(Get-ChildItem -LiteralPath (Join-Path $sourceRoot '_intake-promoted\Ultimate') -Recurse -File)
Assert-BoostLabCondition ($sourcePromotedFiles.Count -eq 7) "Expected 7 source-promoted mirror files, found $($sourcePromotedFiles.Count)."
$remainingSourcePromoted = @(
    $sourcePromotedFiles | Where-Object {
        $_.FullName -ne $sourcePath -and
        $_.Name -ne '2 Driver Install Latest.ps1' -and
        $_.Name -ne '4 Nvidia Settings.ps1' -and
        $_.Name -ne '5 Hdcp.ps1' -and
        $_.Name -ne '6 P0 State.ps1' -and
        $_.Name -ne '7 Msi Mode.ps1' -and
        $_.Name -ne '1 BitLocker.ps1'
    }
)
Assert-BoostLabCondition ($remainingSourcePromoted.Count -eq 0) "Expected 0 remaining unimplemented source-promoted intake candidates, found $($remainingSourcePromoted.Count)."

Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Id -eq 'hdcp' })) -eq 1) 'HDCP must remain active as its own separate controlled registry Path B step.'
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Id -eq 'p0-state' })) -eq 1) 'P0 State must remain active as its own separate controlled registry Path B step.'
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Id -eq 'msi-mode' })) -eq 1) 'Msi Mode must remain active as its own separate controlled registry Path B step.'
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Id -eq 'nvidia-settings' })) -eq 1) 'Nvidia Settings must remain active as its own separate controlled manual-handoff tool.'
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Id -eq 'driver-install-debloat-settings' })) -eq 1) 'Path A Driver Install Debloat & Settings must remain active and separate.'
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Title -eq 'DDU' -or $_.Id -eq 'ddu' })) -eq 0) 'Standalone DDU was reintroduced into active config.'

$executionText = Get-Content -LiteralPath $executionPath -Raw
foreach ($needle in @(
    "'driver-clean'",
    "Graphics\driver-clean.psm1",
    "'Analyze', 'Open', 'Apply'"
)) {
    Assert-BoostLabTextContains -Text $executionText -Needle $needle -Description 'Execution registry'
}

$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($needle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Open'', ''Apply'')',
    'ManualHandoffOnly',
    'AutoBlockedUntilArtifactApproval',
    'NoAutomatedDduExecutionOccurred',
    'NoAutomatedDduDownloadOccurred',
    'NoAutomatedRebootOccurred',
    'Default is not Restore',
    $expectedSourceHash
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'Driver Clean module'
}

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
Assert-BoostLabTextContains -Text $actionPlanText -Needle "[ValidateSet('Apply', 'Default', 'Open', 'Analyze', 'Restore')]" -Description 'Action plan canonical ValidateSet'
Assert-BoostLabCondition (-not $actionPlanText.Contains('Prepare Manual Handoff')) 'Action plan ValidateSet must not be widened for Driver Clean display labels.'
Assert-BoostLabCondition (-not $actionPlanText.Contains('Apply Auto')) 'Action plan ValidateSet must not be widened for Driver Clean display labels.'

$uiText = Get-Content -LiteralPath $uiPath -Raw
foreach ($needle in @(
    'Get-BoostLabToolActionDisplayLabel',
    "'driver-clean', 'driver-install-latest', 'nvidia-settings'",
    "'Open' { return 'Manual Handoff' }",
    "'Apply' { return 'Apply Auto' }",
    'ActionName   = $actionName',
    'ActionLabel  = $actionDisplayLabel'
)) {
    Assert-BoostLabTextContains -Text $uiText -Needle $needle -Description 'Driver Clean UI display label mapping'
}

foreach ($commandPattern in @(
    '(?im)^\s*Start-Process\b',
    '(?im)^\s*Invoke-WebRequest\b',
    '(?im)^\s*iwr\b',
    '(?im)^\s*Invoke-RestMethod\b',
    '(?im)^\s*Set-ItemProperty\b',
    '(?im)^\s*New-ItemProperty\b',
    '(?im)^\s*Remove-ItemProperty\b',
    '(?im)^\s*Set-Content\b',
    '(?im)^\s*New-Item\b',
    '(?im)^\s*Remove-Item\b',
    '(?im)^\s*Move-Item\b',
    '(?im)^\s*bcdedit\b',
    '(?im)^\s*shutdown\b',
    '(?im)^\s*Restart-Computer\b'
)) {
    Assert-BoostLabCondition (-not [regex]::IsMatch($moduleText, $commandPattern)) "Driver Clean module contains prohibited executable command pattern: $commandPattern"
}

$module = Import-Module -Name $modulePath -Force -PassThru -ErrorAction Stop
try {
    $info = Get-BoostLabToolInfo
    Assert-BoostLabCondition ([string]$info.Id -eq 'driver-clean') 'Driver Clean module info Id mismatch.'
    Assert-BoostLabCondition ((@($info.ImplementedActions) -join '|') -eq 'Analyze|Open|Apply') 'Driver Clean implemented actions mismatch.'
    Assert-BoostLabCondition ((@($info.ConfirmationRequiredActions) -join '|') -eq 'Open|Apply') 'Driver Clean confirmation-required actions must be canonical.'

    $analysisResult = Invoke-BoostLabToolAction -ActionName 'Analyze'
    Assert-BoostLabCondition ([bool]$analysisResult.Success) 'Driver Clean Analyze should succeed when source checksum matches.'
    Assert-BoostLabCondition ([string]$analysisResult.Status -eq 'Analyzed') 'Driver Clean Analyze status mismatch.'
    Assert-BoostLabCondition ([string]$analysisResult.CommandStatus -eq 'No execution performed') 'Analyze must not execute.'
    Assert-BoostLabCondition ([string]$analysisResult.Data.Mode -eq 'ManualHandoffOnly') 'Analyze must report ManualHandoffOnly.'
    Assert-BoostLabCondition ([string]$analysisResult.Data.AutoMode -eq 'AutoBlockedUntilArtifactApproval') 'Analyze must report Auto blocked.'
    Assert-BoostLabCondition ([string]$analysisResult.Data.Source.ChecksumStatus -eq 'Passed') 'Analyze source checksum status mismatch.'
    Assert-BoostLabCondition ([bool]$analysisResult.Data.NoDduDownloaded) 'Analyze must report no DDU download.'
    Assert-BoostLabCondition ([bool]$analysisResult.Data.NoDduExecuted) 'Analyze must report no DDU execution.'
    Assert-BoostLabCondition ([bool]$analysisResult.Data.NoSevenZipDownloaded) 'Analyze must report no 7-Zip download.'
    Assert-BoostLabCondition ([bool]$analysisResult.Data.NoExternalProcessStarted) 'Analyze must report no external process.'
    Assert-BoostLabCondition ([bool]$analysisResult.Data.NoRegistryBootRunOnceOrRebootChange) 'Analyze must report no registry/boot/RunOnce/reboot change.'
    Assert-BoostLabNoDuplicateWarnings -Result $analysisResult -Description 'Driver Clean Analyze'
    foreach ($approval in @(
        'DDU artifact/download approval'
        '7-Zip artifact/download approval'
        'Process handling approval for DDU'
        'Safe Mode/RunOnce/reboot approval'
        'Recovery handling approval'
    )) {
        Assert-BoostLabCondition ($approval -in @($analysisResult.Data.MissingApprovals)) "Analyze missing approval was not reported: $approval"
    }

    $handoffCancelled = Invoke-BoostLabToolAction -ActionName 'Open'
    Assert-BoostLabCondition (-not [bool]$handoffCancelled.Success) 'Unconfirmed manual handoff should not proceed.'
    Assert-BoostLabCondition ([bool]$handoffCancelled.Cancelled) 'Unconfirmed manual handoff should be marked cancelled.'
    Assert-BoostLabCondition ([string]$handoffCancelled.Action -eq 'Open') 'Manual handoff cancellation should report canonical Open action.'
    Assert-BoostLabTextContains -Text ([string]$handoffCancelled.Message) -Needle 'No automated DDU execution' -Description 'Cancelled handoff message'

    $handoffResult = Invoke-BoostLabToolAction -ActionName 'Open' -Confirmed:$true
    Assert-BoostLabCondition ([bool]$handoffResult.Success) 'Confirmed manual handoff should succeed.'
    Assert-BoostLabCondition ([string]$handoffResult.Action -eq 'Open') 'Manual handoff should report canonical Open action.'
    Assert-BoostLabCondition ([string]$handoffResult.Status -eq 'ManualHandoffPrepared') 'Manual handoff status mismatch.'
    Assert-BoostLabCondition ([string]$handoffResult.CommandStatus -eq 'No execution performed') 'Manual handoff must not execute.'
    Assert-BoostLabCondition (-not [bool]$handoffResult.ChangesExecuted) 'Manual handoff must not report changes executed.'
    foreach ($messagePart in @(
        'No automated DDU execution'
        'DDU download'
        '7-Zip download'
        'external process start'
        'registry change'
        'RunOnce creation'
        'bcdedit call'
        'Safe Mode switch'
        'reboot'
        'driver cleanup'
    )) {
        Assert-BoostLabTextContains -Text ([string]$handoffResult.Message) -Needle $messagePart -Description 'Manual handoff result message'
    }
    Assert-BoostLabCondition ([bool]$handoffResult.Data.NoAutomatedDduExecutionOccurred) 'Manual handoff must report no DDU execution.'
    Assert-BoostLabCondition ([bool]$handoffResult.Data.NoAutomatedDduDownloadOccurred) 'Manual handoff must report no DDU download.'
    Assert-BoostLabCondition ([bool]$handoffResult.Data.NoAutomatedRebootOccurred) 'Manual handoff must report no reboot.'
    Assert-BoostLabNoDuplicateWarnings -Result $handoffResult -Description 'Driver Clean Manual Handoff'

    $autoResult = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true
    Assert-BoostLabCondition (-not [bool]$autoResult.Success) 'Apply Auto must fail closed.'
    Assert-BoostLabCondition ([string]$autoResult.Action -eq 'Apply') 'Apply Auto should route through canonical Apply action.'
    Assert-BoostLabCondition ([string]$autoResult.Status -eq 'AutoBlockedUntilArtifactApproval') 'Apply Auto must report AutoBlockedUntilArtifactApproval.'
    Assert-BoostLabCondition ([string]$autoResult.CommandStatus -eq 'Blocked before execution') 'Apply Auto must block before execution.'
    Assert-BoostLabTextContains -Text ([string]$autoResult.Message) -Needle 'AutoBlockedUntilArtifactApproval' -Description 'Apply Auto blocked message'
    Assert-BoostLabNoDuplicateWarnings -Result $autoResult -Description 'Driver Clean Apply Auto'

    foreach ($refusedAction in @('Default', 'Restore')) {
        $refused = Invoke-BoostLabToolAction -ActionName $refusedAction
        Assert-BoostLabCondition (-not [bool]$refused.Success) "$refusedAction must be unavailable."
        Assert-BoostLabCondition ([string]$refused.Status -eq 'Unavailable') "$refusedAction status mismatch."
        Assert-BoostLabTextContains -Text ([string]$refused.Message) -Needle 'Default is not Restore' -Description "$refusedAction refusal"
        Assert-BoostLabTextContains -Text ([string]$refused.Message) -Needle 'real captured state' -Description "$refusedAction refusal"
    }
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
}

$originalProgramData = $env:ProgramData
$env:ProgramData = Join-Path ([System.IO.Path]::GetTempPath()) 'BoostLabTestProgramData'
$loggingModule = Import-Module -Name (Join-Path $ProjectRoot 'core\Logging.psm1') -Force -PassThru -ErrorAction Stop
$stateModule = Import-Module -Name (Join-Path $ProjectRoot 'core\State.psm1') -Force -PassThru -ErrorAction Stop
Initialize-BoostLabState | Out-Null
$executionModule = Import-Module -Name $executionPath -Force -PassThru -ErrorAction Stop
try {
    $runtimeAnalyze = Invoke-BoostLabToolAction -ToolMetadata $driverCleanTool -ActionName 'Analyze'
    Assert-BoostLabCondition ([bool]$runtimeAnalyze.Success) 'Runtime Analyze should succeed.'
    Assert-BoostLabCondition ([string]$runtimeAnalyze.ActionPlan.Action -eq 'Analyze') 'Runtime Analyze Action Plan should use canonical Analyze action.'
    Assert-BoostLabTextContains -Text ([string]$runtimeAnalyze.ActionPlan.Summary) -Needle 'report blocked approvals without running any driver-cleaning operation' -Description 'Runtime Analyze Action Plan summary'
    Assert-BoostLabCondition (-not ((@($runtimeAnalyze.ActionPlan.PlannedChanges) -join "`n").Contains('Download'))) 'Runtime Analyze Action Plan should remain read-only.'
    Assert-BoostLabNoDuplicateWarnings -Result $runtimeAnalyze -Description 'Runtime Driver Clean Analyze'

    $runtimeHandoff = Invoke-BoostLabToolAction -ToolMetadata $driverCleanTool -ActionName 'Open'
    Assert-BoostLabCondition (-not [bool]$runtimeHandoff.Success) 'Runtime manual handoff without confirmation should be gated, not crash.'
    Assert-BoostLabCondition ([string]$runtimeHandoff.Action -eq 'Open') 'Runtime manual handoff should use canonical Open action.'
    Assert-BoostLabCondition ([bool]$runtimeHandoff.Cancelled) 'Runtime manual handoff should be cancelled when confirmation is missing.'
    Assert-BoostLabCondition ($null -ne $runtimeHandoff.ActionPlan) 'Runtime manual handoff should return an Action Plan.'
    Assert-BoostLabCondition ([string]$runtimeHandoff.ActionPlan.Action -eq 'Open') 'Runtime Action Plan should use canonical Open action.'
    Assert-BoostLabCondition ([bool]$runtimeHandoff.ActionPlan.NeedsExplicitConfirmation) 'Runtime manual handoff plan should require explicit confirmation.'
    Assert-BoostLabTextContains -Text ([string]$runtimeHandoff.ActionPlan.Summary) -Needle 'manual handoff instructions only' -Description 'Manual Handoff Action Plan summary'
    $runtimeHandoffPlanText = @(
        @($runtimeHandoff.ActionPlan.PlannedChanges)
        @($runtimeHandoff.ActionPlan.SideEffects)
        @($runtimeHandoff.ActionPlan.ConfirmationMessage)
    ) -join "`n"
    foreach ($needle in @(
        'manual handoff instructions only',
        'Do not open any external tool',
        'Do not download DDU or 7-Zip',
        'Do not execute DDU',
        'no system-changing operation occurs'
    )) {
        Assert-BoostLabTextContains -Text $runtimeHandoffPlanText -Needle $needle -Description 'Manual Handoff Action Plan text'
    }
    Assert-BoostLabCondition (-not $runtimeHandoffPlanText.Contains('approved external resource may be opened')) 'Manual Handoff Action Plan must not use generic Open resource wording.'

    $runtimeAuto = Invoke-BoostLabToolAction -ToolMetadata $driverCleanTool -ActionName 'Apply' -RiskConfirmed
    Assert-BoostLabCondition (-not [bool]$runtimeAuto.Success) 'Runtime Apply Auto should fail closed.'
    Assert-BoostLabCondition ([string]$runtimeAuto.Action -eq 'Apply') 'Runtime Apply Auto should use canonical Apply action.'
    Assert-BoostLabCondition ([string]$runtimeAuto.Status -eq 'AutoBlockedUntilArtifactApproval') 'Runtime Apply Auto status mismatch.'
    Assert-BoostLabNoDuplicateWarnings -Result $runtimeAuto -Description 'Runtime Driver Clean Apply Auto'
    $runtimeAutoPlanText = @(
        @($runtimeAuto.ActionPlan.Summary)
        @($runtimeAuto.ActionPlan.PlannedChanges)
        @($runtimeAuto.ActionPlan.SideEffects)
        @($runtimeAuto.ActionPlan.ConfirmationMessage)
    ) -join "`n"
    foreach ($needle in @(
        'Auto mode is blocked',
        'Do not execute any approved Auto behavior',
        'missing DDU artifact/provenance',
        'process handling',
        'reboot/recovery',
        'No approved Auto behavior'
    )) {
        Assert-BoostLabTextContains -Text $runtimeAutoPlanText -Needle $needle -Description 'Apply Auto Action Plan text'
    }
    Assert-BoostLabCondition (-not $runtimeAutoPlanText.Contains('Apply the approved Driver Clean behavior')) 'Apply Auto Action Plan must not use generic Apply wording.'
}
finally {
    Remove-Module -ModuleInfo $executionModule -Force -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $stateModule -Force -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $loggingModule -Force -ErrorAction SilentlyContinue
    $env:ProgramData = $originalProgramData
}

foreach ($forbiddenPath in @(
    'config\DriverCleanPolicy.psd1'
    'config\DriverCleanAllowlist.psd1'
    'config\DduPolicy.psd1'
    'config\DduArtifacts.psd1'
    'config\DriverCleanArtifacts.psd1'
    'config\DriverCleanWorkflow.psd1'
    'config\DriverCleanRuntime.psd1'
)) {
    Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $forbiddenPath))) "Driver Clean/DDU production approval config was unexpectedly created: $forbiddenPath"
}

$artifactPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1')
$artifactText = Get-Content -LiteralPath (Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1') -Raw
Assert-BoostLabCondition (-not ($artifactText -match '(?i)Display Driver Uninstaller|DDU|7-Zip|7zip')) 'DDU or 7-Zip artifact approval was unexpectedly added.'
if ($artifactPolicy.Contains('Artifacts')) {
    $approvedArtifacts = @($artifactPolicy.Artifacts | Where-Object {
        ([string]$_.Id -match '(?i)ddu|7zip|7-zip') -or
        ([string]$_.DisplayName -match '(?i)Display Driver Uninstaller|DDU|7-Zip|7zip')
    })
    Assert-BoostLabCondition ($approvedArtifacts.Count -eq 0) 'DDU or 7-Zip artifact approval was unexpectedly added.'
}

Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'modules\Graphics\ddu.psm1'))) 'Standalone DDU module was reintroduced.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'modules\Graphics\DDU.psm1'))) 'Standalone DDU module was reintroduced.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\23 NVME Faster Driver.ps1'))) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    Passed                          = $true
    ActiveTools                     = $allTools.Count
    ImplementedTools                = $allTools.Count - $placeholderModules.Count
    DeferredPlaceholders            = $placeholderModules.Count
    SourcePromotedMirrorFiles       = $sourcePromotedFiles.Count
    RemainingSourcePromotedIntake   = $remainingSourcePromoted.Count
    DriverCleanMode                 = 'ManualHandoffOnly'
    AutoMode                        = 'AutoBlockedUntilArtifactApproval'
    Message                         = 'Driver Clean controlled manual handoff implementation is active, inert, and fail-closed for Auto.'
}


