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
        throw 'Unable to determine the Driver Install Debloat & Settings validator path.'
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
$modulePath = Join-Path $ProjectRoot 'modules\Graphics\driver-install-debloat-settings.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\5 Graphics\1 Driver Install Debloat & Settings.ps1'
$designPath = Join-Path $ProjectRoot 'docs\tool-designs\driver-install-debloat-settings-scope-provenance-design.md'
$migrationPath = Join-Path $ProjectRoot 'docs\migrations\driver-install-debloat-settings.md'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

foreach ($path in @($stagesPath, $executionPath, $actionPlanPath, $modulePath, $sourcePath, $designPath, $migrationPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required Phase 99 file was not found: $path"
}

$expectedSourceHash = 'E69EFF538E7CE6108233C525A2BB88BA2D549CE6954AE751BE7BED778271C26F'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Driver Install Debloat & Settings source hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."

$config = Import-PowerShellDataFile -LiteralPath $stagesPath
$graphicsStage = @($config.Stages | Where-Object { $_.Name -eq 'Graphics' })[0]
Assert-BoostLabCondition ($null -ne $graphicsStage) 'Graphics stage was not found.'

$tool = @($graphicsStage.Tools | Where-Object { $_.Id -eq 'driver-install-debloat-settings' })[0]
Assert-BoostLabCondition ($null -ne $tool) 'Driver Install Debloat & Settings was not found as an active Graphics tool.'
Assert-BoostLabCondition ([string]$tool.Title -eq 'Driver Install Debloat & Settings') 'Driver Install Debloat & Settings title mismatch.'
Assert-BoostLabCondition ([int]$tool.Order -eq 7) 'Driver Install Debloat & Settings must remain after NVIDIA Path B step 5.'
Assert-BoostLabCondition ([string]$tool.Type -eq 'assistant') 'Driver Install Debloat & Settings must be an assistant.'
Assert-BoostLabCondition ([string]$tool.RiskLevel -eq 'high') 'Driver Install Debloat & Settings must remain high risk.'
Assert-BoostLabCondition ((@($tool.Actions) -join '|') -eq 'Analyze|Open|Apply|Default|Restore') 'Driver Install Debloat & Settings must expose canonical Analyze, Open, Apply, Default, Restore actions.'
Assert-BoostLabTextContains -Text ([string]$tool.Description) -Needle 'Manual handoff only' -Description 'Driver Install Debloat & Settings description'
Assert-BoostLabTextContains -Text ([string]$tool.Description) -Needle 'without automated downloads' -Description 'Driver Install Debloat & Settings description'

$capabilities = $tool.Capabilities
foreach ($falseCapability in @(
    'RequiresAdmin',
    'RequiresInternet',
    'CanReboot',
    'CanModifyRegistry',
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
    Assert-BoostLabCondition (-not [bool]$capabilities[$falseCapability]) "Current manual-handoff capability should be false: $falseCapability"
}
Assert-BoostLabCondition ([bool]$capabilities['CanModifyServices']) 'Source-proven service capability should be declared while Auto remains blocked.'
Assert-BoostLabCondition ([bool]$capabilities['NeedsExplicitConfirmation']) 'Manual handoff should require explicit confirmation.'

$allTools = @($config.Stages | ForEach-Object { $_.Tools })
$placeholderModules = @(
    Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
Assert-BoostLabCondition ($allTools.Count -eq 55) "Expected 55 active tools, found $($allTools.Count)."
Assert-BoostLabCondition ($placeholderModules.Count -eq 15) "Expected 15 deferred/placeholders, found $($placeholderModules.Count)."
Assert-BoostLabCondition (($allTools.Count - $placeholderModules.Count) -eq 40) "Expected 40 implemented tools, found $($allTools.Count - $placeholderModules.Count)."

$sourcePromotedFiles = @(Get-ChildItem -LiteralPath (Join-Path $sourceRoot '_intake-promoted\Ultimate') -Recurse -File)
Assert-BoostLabCondition ($sourcePromotedFiles.Count -eq 7) "Expected 7 source-promoted mirror files, found $($sourcePromotedFiles.Count)."
$remainingSourcePromoted = @(
    $sourcePromotedFiles | Where-Object {
        $_.Name -notin @(
            '1 Driver Clean.ps1',
            '2 Driver Install Latest.ps1',
            '4 Nvidia Settings.ps1',
            '5 Hdcp.ps1',
            '6 P0 State.ps1',
            '7 Msi Mode.ps1',
            '1 BitLocker.ps1'
        )
    }
)
Assert-BoostLabCondition ($remainingSourcePromoted.Count -eq 0) "Expected 0 remaining unimplemented source-promoted intake candidates, found $($remainingSourcePromoted.Count)."

foreach ($pathB in @(
    @{ Id = 'driver-install-latest'; Order = 2 },
    @{ Id = 'nvidia-settings'; Order = 3 },
    @{ Id = 'hdcp'; Order = 4 },
    @{ Id = 'p0-state'; Order = 5 },
    @{ Id = 'msi-mode'; Order = 6 }
)) {
    $pathBTool = @($graphicsStage.Tools | Where-Object { $_.Id -eq $pathB.Id })[0]
    Assert-BoostLabCondition ($null -ne $pathBTool) "NVIDIA Path B tool missing: $($pathB.Id)"
    Assert-BoostLabCondition ([int]$pathBTool.Order -eq [int]$pathB.Order) "NVIDIA Path B order changed for $($pathB.Id)."
}

$executionText = Get-Content -LiteralPath $executionPath -Raw
foreach ($needle in @(
    "'driver-install-debloat-settings'",
    "Graphics\driver-install-debloat-settings.psm1",
    "'Analyze', 'Open', 'Apply', 'Default', 'Restore'"
)) {
    Assert-BoostLabTextContains -Text $executionText -Needle $needle -Description 'Execution registry'
}

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
Assert-BoostLabTextContains -Text $actionPlanText -Needle "[ValidateSet('Apply', 'Default', 'Open', 'Analyze', 'Restore')]" -Description 'Action plan canonical ValidateSet'
Assert-BoostLabCondition (-not $actionPlanText.Contains("'Manual Handoff', 'Apply Auto'")) 'Action Plan ValidateSet must not be widened for display labels.'
foreach ($needle in @(
    'Analyze the Driver Install Debloat & Settings source',
    'Prepare Driver Install Debloat & Settings manual handoff instructions only',
    'Auto mode is blocked for Driver Install Debloat & Settings',
    'Default is unavailable because the source does not define a safe overall default mutation',
    'Restore is unavailable because no captured driver/profile/package/registry/file/reboot state restore contract exists'
)) {
    Assert-BoostLabTextContains -Text $actionPlanText -Needle $needle -Description 'Driver Install Debloat & Settings action plan'
}

$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($needle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Open'', ''Apply'', ''Default'', ''Restore'')',
    'ManualHandoffOnly',
    'AutoBlockedUntilArtifactApproval',
    'NoInstallerExecutionOccurred',
    'NoDriverMutationOccurred',
    'NoRegistryMutationOccurred',
    'NoRebootOrSessionChangeOccurred',
    'Default is not Restore',
    $expectedSourceHash
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'Driver Install Debloat & Settings module'
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
    '(?im)^\s*Stop-Service\b',
    '(?im)^\s*Set-Service\b',
    '(?im)^\s*bcdedit\b',
    '(?im)^\s*shutdown\b',
    '(?im)^\s*Restart-Computer\b',
    '(?im)^\s*winget\b'
)) {
    Assert-BoostLabCondition (-not [regex]::IsMatch($moduleText, $commandPattern)) "Module contains prohibited executable command pattern: $commandPattern"
}

$module = Import-Module -Name $modulePath -Force -PassThru -ErrorAction Stop
try {
    $info = Get-BoostLabToolInfo
    Assert-BoostLabCondition ([string]$info.Id -eq 'driver-install-debloat-settings') 'Module info Id mismatch.'
    Assert-BoostLabCondition ((@($info.ImplementedActions) -join '|') -eq 'Analyze|Open|Apply|Default|Restore') 'Implemented actions mismatch.'
    Assert-BoostLabCondition ((@($info.ConfirmationRequiredActions) -join '|') -eq 'Open|Apply') 'Confirmation actions mismatch.'

    $analysis = Invoke-BoostLabToolAction -ActionName 'Analyze'
    Assert-BoostLabCondition ([bool]$analysis.Success) 'Analyze should succeed when source checksum matches.'
    Assert-BoostLabCondition ([string]$analysis.Status -eq 'Analyzed') 'Analyze status mismatch.'
    Assert-BoostLabCondition ([string]$analysis.CommandStatus -eq 'No execution performed') 'Analyze must not execute.'
    Assert-BoostLabCondition ([string]$analysis.Data.Mode -eq 'ManualHandoffOnly') 'Analyze must report ManualHandoffOnly.'
    Assert-BoostLabCondition ([string]$analysis.Data.AutoMode -eq 'AutoBlockedUntilArtifactApproval') 'Analyze must report Auto blocked.'
    Assert-BoostLabCondition ([string]$analysis.Data.Source.ChecksumStatus -eq 'Passed') 'Analyze source checksum mismatch.'
    foreach ($flag in @(
        'NoAutomatedExecution',
        'NoDownloadOccurred',
        'NoInstallerExecutionOccurred',
        'NoExternalProcessStarted',
        'NoDriverMutationOccurred',
        'NoRegistryMutationOccurred',
        'NoFileCleanupOccurred',
        'NoServiceMutationOccurred',
        'NoProfileImportOccurred',
        'NoAppxOrWingetMutationOccurred',
        'NoRebootOrSessionChangeOccurred'
    )) {
        Assert-BoostLabCondition ([bool]$analysis.Data.$flag) "Analyze flag should be true: $flag"
    }
    Assert-BoostLabNoDuplicateWarnings -Result $analysis -Description 'Analyze'

    foreach ($approval in @(
        '7-Zip artifact/download/installer approval',
        'NVIDIA driver artifact or user-selected installer validation approval',
        'NVIDIA installer execution descriptor approval',
        'NVIDIA driver component deletion/debloat cleanup scope approval',
        'NVIDIA Profile Inspector artifact/execution/profile-import approval',
        'Driver state capture/rollback approval',
        'Reboot/session handling approval'
    )) {
        Assert-BoostLabCondition ($approval -in @($analysis.Data.MissingApprovals)) "Missing approval was not reported: $approval"
    }

    $cancelled = Invoke-BoostLabToolAction -ActionName 'Open'
    Assert-BoostLabCondition (-not [bool]$cancelled.Success) 'Unconfirmed Open should not proceed.'
    Assert-BoostLabCondition ([bool]$cancelled.Cancelled) 'Unconfirmed Open should be cancelled.'
    Assert-BoostLabTextContains -Text ([string]$cancelled.Message) -Needle 'No download' -Description 'Cancelled Open message'

    $open = Invoke-BoostLabToolAction -ActionName 'Open' -Confirmed:$true
    Assert-BoostLabCondition ([bool]$open.Success) 'Confirmed Open should prepare manual handoff.'
    Assert-BoostLabCondition ([string]$open.Status -eq 'ManualHandoffPrepared') 'Open status mismatch.'
    Assert-BoostLabCondition ([string]$open.CommandStatus -eq 'No execution performed') 'Open must not execute.'
    Assert-BoostLabCondition (-not [bool]$open.ChangesExecuted) 'Open must not report changes.'
    foreach ($messagePart in @(
        'No browser',
        'external tool',
        '7-Zip download/install',
        'driver download',
        'installer execution',
        'driver extraction/debloat',
        'Profile Inspector execution',
        '.nip import',
        'winget/AppX action',
        'registry/service/driver mutation',
        'reboot'
    )) {
        Assert-BoostLabTextContains -Text ([string]$open.Message) -Needle $messagePart -Description 'Open result message'
    }
    Assert-BoostLabCondition ([bool]$open.Data.NoDownloadOccurred) 'Open must report no download.'
    Assert-BoostLabCondition ([bool]$open.Data.NoInstallerExecutionOccurred) 'Open must report no installer execution.'
    Assert-BoostLabCondition ([bool]$open.Data.NoExternalProcessStarted) 'Open must report no external process.'
    Assert-BoostLabNoDuplicateWarnings -Result $open -Description 'Open'

    $apply = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true
    Assert-BoostLabCondition (-not [bool]$apply.Success) 'Apply Auto must fail closed.'
    Assert-BoostLabCondition ([string]$apply.Status -eq 'AutoBlockedUntilArtifactApproval') 'Apply Auto status mismatch.'
    Assert-BoostLabCondition ([string]$apply.CommandStatus -eq 'Blocked before execution') 'Apply Auto must block before execution.'
    Assert-BoostLabTextContains -Text ([string]$apply.Message) -Needle 'AutoBlockedUntilArtifactApproval' -Description 'Apply Auto message'
    Assert-BoostLabNoDuplicateWarnings -Result $apply -Description 'Apply'

    $default = Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed:$true
    Assert-BoostLabCondition (-not [bool]$default.Success) 'Default must fail closed.'
    Assert-BoostLabCondition ([string]$default.Status -eq 'DefaultUnavailable') 'Default status mismatch.'
    Assert-BoostLabTextContains -Text ([string]$default.Message) -Needle 'Default is not Restore' -Description 'Default message'

    $restore = Invoke-BoostLabToolAction -ActionName 'Restore' -Confirmed:$true
    Assert-BoostLabCondition (-not [bool]$restore.Success) 'Restore must fail closed.'
    Assert-BoostLabCondition ([string]$restore.Status -eq 'RestoreUnavailable') 'Restore status mismatch.'
    Assert-BoostLabTextContains -Text ([string]$restore.Message) -Needle 'approved captured driver/profile/package/registry/file/reboot state' -Description 'Restore message'
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
    $runtimeAnalyze = Invoke-BoostLabToolAction -ToolMetadata $tool -ActionName 'Analyze'
    Assert-BoostLabCondition ([bool]$runtimeAnalyze.Success) 'Runtime Analyze should succeed.'
    Assert-BoostLabTextContains -Text ([string]$runtimeAnalyze.ActionPlan.Summary) -Needle 'report blocked approvals without running any driver install' -Description 'Runtime Analyze Action Plan summary'
    Assert-BoostLabNoDuplicateWarnings -Result $runtimeAnalyze -Description 'Runtime Analyze'

    $runtimeOpen = Invoke-BoostLabToolAction -ToolMetadata $tool -ActionName 'Open'
    Assert-BoostLabCondition (-not [bool]$runtimeOpen.Success) 'Runtime Open without confirmation should be gated.'
    Assert-BoostLabCondition ([bool]$runtimeOpen.Cancelled) 'Runtime Open should be cancelled when confirmation is missing.'
    Assert-BoostLabCondition ($null -ne $runtimeOpen.ActionPlan) 'Runtime Open should include an Action Plan.'
    $runtimeOpenPlanText = @(
        @($runtimeOpen.ActionPlan.Summary)
        @($runtimeOpen.ActionPlan.PlannedChanges)
        @($runtimeOpen.ActionPlan.SideEffects)
        @($runtimeOpen.ActionPlan.ConfirmationMessage)
    ) -join "`n"
    foreach ($needle in @(
        'manual handoff instructions',
        'Do not open a browser',
        'Do not download 7-Zip',
        'Do not extract driver packages',
        'Perform no system-changing operation'
    )) {
        Assert-BoostLabTextContains -Text $runtimeOpenPlanText -Needle $needle -Description 'Runtime Open Action Plan'
    }
    Assert-BoostLabCondition (-not $runtimeOpenPlanText.Contains('approved external resource may be opened')) 'Runtime Open Action Plan must not use generic external resource wording.'

    $runtimeApply = Invoke-BoostLabToolAction -ToolMetadata $tool -ActionName 'Apply' -RiskConfirmed
    Assert-BoostLabCondition (-not [bool]$runtimeApply.Success) 'Runtime Apply should fail closed.'
    Assert-BoostLabCondition ([string]$runtimeApply.Status -eq 'AutoBlockedUntilArtifactApproval') 'Runtime Apply status mismatch.'
    $runtimeApplyPlanText = @(
        @($runtimeApply.ActionPlan.Summary)
        @($runtimeApply.ActionPlan.PlannedChanges)
        @($runtimeApply.ActionPlan.SideEffects)
        @($runtimeApply.ActionPlan.ConfirmationMessage)
    ) -join "`n"
    foreach ($needle in @(
        'Auto mode is blocked',
        'Do not execute any approved Auto behavior',
        'Report missing 7-Zip',
        'No approved Auto behavior'
    )) {
        Assert-BoostLabTextContains -Text $runtimeApplyPlanText -Needle $needle -Description 'Runtime Apply Action Plan'
    }
    Assert-BoostLabCondition (-not $runtimeApplyPlanText.Contains('Apply the approved Driver Install Debloat & Settings behavior')) 'Runtime Apply plan must not use generic Apply wording.'
}
finally {
    Remove-Module -ModuleInfo $executionModule -Force -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $stateModule -Force -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $loggingModule -Force -ErrorAction SilentlyContinue
    $env:ProgramData = $originalProgramData
}

$artifactText = Get-Content -LiteralPath (Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1') -Raw
$allowlistText = Get-Content -LiteralPath (Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1') -Raw
Assert-BoostLabCondition (-not ($artifactText -match '(?i)driver-install-debloat|nvidia driver|profile inspector|7-zip|7zip')) 'Unexpected artifact approval was added for Driver Install Debloat & Settings.'
Assert-BoostLabCondition (-not ($allowlistText -match '(?i)driver-install-debloat|nvidia driver|profile inspector|7-zip|7zip')) 'Unexpected production allowlist approval was added for Driver Install Debloat & Settings.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'modules\Graphics\ddu.psm1'))) 'Standalone DDU module was reintroduced.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\23 NVME Faster Driver.ps1'))) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    Passed                          = $true
    ActiveTools                     = $allTools.Count
    ImplementedTools                = $allTools.Count - $placeholderModules.Count
    DeferredPlaceholders            = $placeholderModules.Count
    SourcePromotedMirrorFiles       = $sourcePromotedFiles.Count
    RemainingSourcePromotedIntake   = $remainingSourcePromoted.Count
    Mode                            = 'ManualHandoffOnly'
    AutoMode                        = 'AutoBlockedUntilArtifactApproval'
    Message                         = 'Driver Install Debloat & Settings controlled manual handoff implementation is active, inert, and fail-closed for Auto.'
}
