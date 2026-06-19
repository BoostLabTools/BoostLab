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
        throw 'Unable to determine the DirectX controlled manual handoff validator path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

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

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Graphics\directx.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\5 Graphics\2 DirectX.ps1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$migrationPath = Join-Path $ProjectRoot 'docs\migrations\directx.md'
$provenanceReviewPath = Join-Path $ProjectRoot 'docs\directx-provenance-review.md'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

foreach ($path in @($configPath, $modulePath, $sourcePath, $executionPath, $actionPlanPath, $artifactPath, $productionAllowlistPath, $migrationPath, $provenanceReviewPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required Phase 100 file was not found: $path"
}

$expectedSourceHash = '17051A2F0F7A0CF16BE525121720406E8F1630C94E5977A7CD4C18652A87EE05'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "DirectX source hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."

$sourceText = Get-Content -LiteralPath $sourcePath -Raw
foreach ($needle in @(
    'refs/heads/main/7zip.exe'
    'refs/heads/main/directx.exe'
    'DXSETUP.exe'
    'HKEY_CURRENT_USER\Software\7-Zip\Options'
)) {
    Assert-BoostLabTextContains -Text $sourceText -Needle $needle -Description 'DirectX Ultimate source behavior'
}

$config = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })
$graphicsStage = @($config.Stages | Where-Object { $_.Name -eq 'Graphics' })[0]
$directXTool = @($graphicsStage.Tools | Where-Object { $_.Id -eq 'directx' })[0]
Assert-BoostLabCondition ($null -ne $directXTool) 'DirectX is missing from Graphics stage.'
Assert-BoostLabCondition ([string]$directXTool.Title -eq 'DirectX') 'DirectX title mismatch.'
Assert-BoostLabCondition ([int]$directXTool.Order -eq 8) 'DirectX must remain Graphics order 8.'
Assert-BoostLabCondition ([string]$directXTool.Type -eq 'assistant') 'DirectX must be an assistant.'
Assert-BoostLabCondition ([string]$directXTool.RiskLevel -eq 'high') 'DirectX must remain high risk.'
Assert-BoostLabCondition ((@($directXTool.Actions) -join ',') -eq 'Analyze,Open,Apply,Default,Restore') 'DirectX must expose canonical Analyze/Open/Apply/Default/Restore actions.'
Assert-BoostLabTextContains -Text ([string]$directXTool.Description) -Needle 'Controlled manual handoff only' -Description 'DirectX description'

$capabilities = $directXTool.Capabilities
Assert-BoostLabCondition ([bool]$capabilities['NeedsExplicitConfirmation']) 'DirectX manual handoff should require explicit confirmation.'
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
    Assert-BoostLabCondition (-not [bool]$capabilities[$falseCapability]) "DirectX capability should be false: $falseCapability"
}

$placeholderModules = @(
    Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
Assert-BoostLabCondition ($allTools.Count -eq $inventoryBaseline.ActiveTools) "Expected $($inventoryBaseline.ActiveTools) active tools, found $($allTools.Count)."
Assert-BoostLabCondition ($placeholderModules.Count -eq $inventoryBaseline.DeferredPlaceholders) "Expected $($inventoryBaseline.DeferredPlaceholders) deferred/placeholders, found $($placeholderModules.Count)."
Assert-BoostLabCondition (($allTools.Count - $placeholderModules.Count) -eq $inventoryBaseline.ImplementedTools) "Expected $($inventoryBaseline.ImplementedTools) implemented tools, found $($allTools.Count - $placeholderModules.Count)."

$sourcePromotedFiles = @(Get-ChildItem -LiteralPath (Join-Path $sourceRoot '_intake-promoted\Ultimate') -Recurse -File)
Assert-BoostLabCondition ($sourcePromotedFiles.Count -eq $inventoryBaseline.SourcePromotedMirrorFiles) "Expected $($inventoryBaseline.SourcePromotedMirrorFiles) source-promoted mirror files, found $($sourcePromotedFiles.Count)."
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

$executionText = Get-Content -LiteralPath $executionPath -Raw
foreach ($needle in @(
    "'directx'"
    "Graphics\directx.psm1"
    "'Analyze', 'Open', 'Apply', 'Default', 'Restore'"
)) {
    Assert-BoostLabTextContains -Text $executionText -Needle $needle -Description 'Execution registry'
}

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
Assert-BoostLabTextContains -Text $actionPlanText -Needle "[ValidateSet('Apply', 'Default', 'Open', 'Analyze', 'Restore')]" -Description 'Action plan canonical ValidateSet'
Assert-BoostLabCondition (-not $actionPlanText.Contains("'Manual Handoff'")) 'Action plan ValidateSet must not include display label Manual Handoff.'
Assert-BoostLabCondition (-not $actionPlanText.Contains("'Apply Auto'")) 'Action plan ValidateSet must not include display label Apply Auto.'
foreach ($needle in @(
    'Prepare DirectX manual handoff instructions only'
    'Auto mode is blocked for DirectX'
    'Do not open a browser, external tool, 7-Zip installer, DirectX runtime package, extraction tool, or DirectX setup executable.'
    'Do not download 7-Zip or DirectX artifacts.'
    'No browser, external tool, 7-Zip download/install, DirectX download, extraction, setup launch, registry change, shortcut cleanup, file cleanup, or system mutation occurs.'
    'DirectX Restore requires selected captured artifact, registry, shortcut, file, installer, and cleanup state plus an approved restore contract.'
)) {
    Assert-BoostLabTextContains -Text $actionPlanText -Needle $needle -Description 'DirectX action plan wording'
}

$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($needle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Open'', ''Apply'', ''Default'', ''Restore'')'
    $expectedSourceHash
    'ManualHandoffPrepared'
    'AutoBlockedUntilArtifactApproval'
    'DefaultUnavailable'
    'RestoreUnavailable'
    'NoAutomatedExecution'
    'NoDownloadOccurred'
    'NoInstallerExecutionOccurred'
    'NoExternalProcessStarted'
    'NoRegistryMutationOccurred'
    'NoShortcutMutationOccurred'
    'NoFileCleanupOccurred'
    'NoSystemMutationOccurred'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'DirectX module text'
}

foreach ($commandPattern in @(
    '(?im)^\s*Start-Process\b',
    '(?im)^\s*Invoke-WebRequest\b',
    '(?im)^\s*iwr\b',
    '(?im)^\s*Invoke-RestMethod\b',
    '(?im)^\s*Set-ItemProperty\b',
    '(?im)^\s*reg\b',
    '(?im)^\s*New-Item\b',
    '(?im)^\s*Remove-Item\b',
    '(?im)^\s*Move-Item\b',
    '(?im)^\s*Remove-ItemProperty\b',
    '(?im)^\s*cmd\b',
    '(?im)^\s*shutdown\b',
    '(?im)^\s*Restart-Computer\b'
)) {
    Assert-BoostLabCondition (-not [regex]::IsMatch($moduleText, $commandPattern)) "DirectX module contains prohibited executable command pattern: $commandPattern"
}

$module = Import-Module -Name $modulePath -Force -PassThru -ErrorAction Stop
try {
    $info = Get-BoostLabToolInfo
    Assert-BoostLabCondition ([string]$info.Id -eq 'directx') 'Module info Id mismatch.'
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
        'NoRegistryMutationOccurred',
        'NoShortcutMutationOccurred',
        'NoFileCleanupOccurred',
        'NoSystemMutationOccurred'
    )) {
        Assert-BoostLabCondition ([bool]$analysis.Data.$flag) "Analyze flag should be true: $flag"
    }
    Assert-BoostLabNoDuplicateWarnings -Result $analysis -Description 'Analyze'

    foreach ($approval in @(
        '7-Zip artifact SHA-256, size, signer, and redistributability approval',
        '7-Zip installer execution descriptor approval',
        'Immutable DirectX runtime artifact source approval',
        'DirectX artifact SHA-256, size, signer, and redistributability approval',
        'DirectX extraction inventory and generated-temp-path approval',
        'Extracted DXSETUP executable provenance approval',
        'DirectX setup execution descriptor approval',
        'File, shortcut, registry, and cleanup scope approval'
    )) {
        Assert-BoostLabCondition ($approval -in @($analysis.Data.MissingApprovals)) "Missing approval was not reported: $approval"
    }

    $cancelled = Invoke-BoostLabToolAction -ActionName 'Open'
    Assert-BoostLabCondition (-not [bool]$cancelled.Success) 'Unconfirmed Open should not proceed.'
    Assert-BoostLabCondition ([bool]$cancelled.Cancelled) 'Unconfirmed Open should be cancelled.'
    Assert-BoostLabTextContains -Text ([string]$cancelled.Message) -Needle 'No browser' -Description 'Cancelled Open message'

    $open = Invoke-BoostLabToolAction -ActionName 'Open' -Confirmed:$true
    Assert-BoostLabCondition ([bool]$open.Success) 'Confirmed Open should prepare manual handoff.'
    Assert-BoostLabCondition ([string]$open.Status -eq 'ManualHandoffPrepared') 'Open status mismatch.'
    Assert-BoostLabCondition ([string]$open.CommandStatus -eq 'No execution performed') 'Open must not execute.'
    Assert-BoostLabCondition (-not [bool]$open.ChangesExecuted) 'Open must not report changes.'
    foreach ($messagePart in @(
        'No browser',
        'external tool',
        '7-Zip download/install',
        'DirectX download',
        'extraction',
        'setup launch',
        'registry change',
        'shortcut cleanup',
        'file cleanup',
        'system mutation'
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
    Assert-BoostLabTextContains -Text ([string]$restore.Message) -Needle 'approved captured artifact, registry, shortcut, file, installer, and cleanup state' -Description 'Restore message'
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
    $runtimeAnalyze = Invoke-BoostLabToolAction -ToolMetadata $directXTool -ActionName 'Analyze'
    Assert-BoostLabCondition ([bool]$runtimeAnalyze.Success) 'Runtime Analyze should succeed.'
    Assert-BoostLabTextContains -Text ([string]$runtimeAnalyze.ActionPlan.Summary) -Needle 'without running any DirectX or 7-Zip workflow' -Description 'Runtime Analyze Action Plan summary'
    Assert-BoostLabNoDuplicateWarnings -Result $runtimeAnalyze -Description 'Runtime Analyze'

    $runtimeOpen = Invoke-BoostLabToolAction -ToolMetadata $directXTool -ActionName 'Open'
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
        'manual handoff instructions only',
        'Do not open a browser',
        'Do not download 7-Zip or DirectX artifacts',
        'Do not install 7-Zip',
        'No browser, external tool',
        'system mutation occurs'
    )) {
        Assert-BoostLabTextContains -Text $runtimeOpenPlanText -Needle $needle -Description 'Runtime Open Action Plan'
    }
    Assert-BoostLabCondition (-not $runtimeOpenPlanText.Contains('approved external resource may be opened')) 'Runtime Open Action Plan must not use generic external resource wording.'

    $runtimeApply = Invoke-BoostLabToolAction -ToolMetadata $directXTool -ActionName 'Apply' -RiskConfirmed
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
        'will not execute Auto behavior',
        'Report missing 7-Zip artifact',
        'No approved Auto behavior'
    )) {
        Assert-BoostLabTextContains -Text $runtimeApplyPlanText -Needle $needle -Description 'Runtime Apply Action Plan'
    }
    Assert-BoostLabCondition (-not $runtimeApplyPlanText.Contains('Apply the approved DirectX behavior')) 'Runtime Apply plan must not use generic Apply wording.'
}
finally {
    Remove-Module -ModuleInfo $executionModule -Force -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $stateModule -Force -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $loggingModule -Force -ErrorAction SilentlyContinue
    $env:ProgramData = $originalProgramData
}

$artifactConfig = Import-PowerShellDataFile -LiteralPath $artifactPath
$artifactText = Get-Content -LiteralPath $artifactPath -Raw
foreach ($forbiddenArtifactText in @('directx.exe', 'DXSETUP.exe', '7zip.exe', '7-Zip', 'FR33THYFR33THY')) {
    Assert-BoostLabCondition (-not $artifactText.Contains($forbiddenArtifactText)) "Unexpected artifact approval related to DirectX: $forbiddenArtifactText"
}
if ($artifactConfig.ContainsKey('Artifacts')) {
    Assert-BoostLabCondition (@($artifactConfig.Artifacts).Count -eq 0) 'Production artifact approvals should remain empty.'
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
    TestName                                     = 'DirectX controlled manual handoff implementation'
    ActiveTools                                  = $allTools.Count
    ImplementedTools                             = $allTools.Count - $placeholderModules.Count
    DeferredPlaceholders                         = $placeholderModules.Count
    SourcePromotedMirrorFiles                    = $sourcePromotedFiles.Count
    RemainingUnimplementedSourcePromotedCandidates = $remainingSourcePromoted.Count
    SourceHash                                   = $actualSourceHash
    DirectXActions                               = @($directXTool.Actions)
    AutoMode                                     = 'AutoBlockedUntilArtifactApproval'
}
