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

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
. (Join-Path $ProjectRoot 'tests\BoostLab.ParityStatusBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot
$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot

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

function Get-BoostLabItemCount {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return 0
    }
    return @($Value).Count
}

function Get-BoostLabTextBetween {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$Start,
        [Parameter(Mandatory)][string]$End
    )

    $startIndex = $Text.IndexOf($Start, [System.StringComparison]::Ordinal)
    Assert-BoostLabCondition ($startIndex -ge 0) "Start marker not found: $Start"
    $endIndex = $Text.IndexOf($End, $startIndex + $Start.Length, [System.StringComparison]::Ordinal)
    Assert-BoostLabCondition ($endIndex -gt $startIndex) "End marker not found after: $Start"
    return $Text.Substring($startIndex, $endIndex - $startIndex)
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Graphics\nvidia-settings.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate\5 Graphics\4 Nvidia Settings.ps1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$externalArtifactSourcePath = Join-Path $ProjectRoot 'config\ExternalArtifactSources.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'

foreach ($path in @($configPath, $modulePath, $sourcePath, $executionPath, $actionPlanPath, $uiPath, $artifactPath, $externalArtifactSourcePath, $productionAllowlistPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path) "Required file missing: $path"
}

$expectedSourceHash = '903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Nvidia Settings source hash mismatch: $actualSourceHash"

$sourceText = Get-Content -LiteralPath $sourcePath -Raw
$sourceNipPayloads = [regex]::Matches(
    $sourceText,
    '\$nipfile\s*=\s*@''\r?\n(?<Payload>.*?)\r?\n''@',
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)
Assert-BoostLabCondition ($sourceNipPayloads.Count -eq 2) 'Nvidia Settings source must contain exactly two source-defined .nip payloads.'
$sourceOnNip = [string]$sourceNipPayloads[0].Groups['Payload'].Value
$sourceDefaultNip = [string]$sourceNipPayloads[1].Groups['Payload'].Value
Assert-BoostLabTextContains -Text $sourceOnNip -Needle '<Executables/>' -Description 'On .nip payload'
Assert-BoostLabTextContains -Text $sourceDefaultNip -Needle '<Executeables/>' -Description 'Default .nip payload source spelling'

$config = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })
$graphicsStage = @($config.Stages | Where-Object { $_.Name -eq 'Graphics' })[0]
$driverCleanTool = @($graphicsStage.Tools | Where-Object { $_.Id -eq 'driver-clean' })[0]
$driverInstallLatestTool = @($graphicsStage.Tools | Where-Object { $_.Id -eq 'driver-install-latest' })[0]
$driverInstallDebloatSettingsTool = @($graphicsStage.Tools | Where-Object { $_.Id -eq 'driver-install-debloat-settings' })[0]
$nvidiaSettingsTool = @($graphicsStage.Tools | Where-Object { $_.Id -eq 'nvidia-settings' })[0]

Assert-BoostLabCondition ($null -ne $nvidiaSettingsTool) 'Nvidia Settings is missing from Graphics stage.'
Assert-BoostLabCondition ([int]$driverCleanTool.Order -eq 1) 'Driver Clean must remain Graphics order 1.'
Assert-BoostLabCondition ([int]$driverInstallDebloatSettingsTool.Order -eq 2) 'Driver Install Debloat & Settings must remain Graphics order 2.'
Assert-BoostLabCondition ([int]$driverInstallLatestTool.Order -eq 3) 'Driver Install Latest must remain Graphics order 3.'
Assert-BoostLabCondition ([int]$nvidiaSettingsTool.Order -eq 4) 'Nvidia Settings must remain Path B step 2 and Graphics order 4.'
Assert-BoostLabCondition ([string]$nvidiaSettingsTool.Type -eq 'assistant') 'Nvidia Settings must remain an assistant.'
Assert-BoostLabCondition ([string]$nvidiaSettingsTool.RiskLevel -eq 'high') 'Nvidia Settings must remain high risk.'
Assert-BoostLabCondition ((@($nvidiaSettingsTool.Actions) -join ',') -eq 'Analyze,Apply,Default') 'Nvidia Settings actions must be Analyze,Apply,Default only.'

$expectedCapabilities = @{
    RequiresAdmin = $true
    RequiresInternet = $true
    CanReboot = $false
    CanModifyRegistry = $true
    CanModifyServices = $false
    CanInstallSoftware = $true
    CanDownload = $true
    CanModifyDrivers = $false
    CanModifySecurity = $false
    CanDeleteFiles = $true
    UsesTrustedInstaller = $false
    UsesSafeMode = $false
    SupportsDefault = $true
    SupportsRestore = $false
    NeedsExplicitConfirmation = $true
}
foreach ($capabilityName in $expectedCapabilities.Keys) {
    Assert-BoostLabCondition ([bool]$nvidiaSettingsTool.Capabilities[$capabilityName] -eq [bool]$expectedCapabilities[$capabilityName]) "Nvidia Settings capability mismatch: $capabilityName"
}

foreach ($pathBToolId in @('driver-install-latest', 'nvidia-settings', 'hdcp', 'p0-state', 'msi-mode')) {
    Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Id -eq $pathBToolId })) -eq 1) "Path B tool missing or duplicated: $pathBToolId"
}
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Id -eq 'ddu' -or $_.Title -eq 'DDU' })) -eq 0) 'Standalone DDU was reintroduced.'

$placeholderModules = @(
    Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
Assert-BoostLabCondition ($allTools.Count -eq $inventoryBaseline.ActiveTools) "Expected $($inventoryBaseline.ActiveTools) active tools, found $($allTools.Count)."
Assert-BoostLabCondition ($placeholderModules.Count -eq $inventoryBaseline.DeferredPlaceholders) "Expected $($inventoryBaseline.DeferredPlaceholders) deferred/placeholders, found $($placeholderModules.Count)."
Assert-BoostLabCondition (($allTools.Count - $placeholderModules.Count) -eq $inventoryBaseline.ImplementedTools) "Expected $($inventoryBaseline.ImplementedTools) implemented tools, found $($allTools.Count - $placeholderModules.Count)."

$sourcePromotedFiles = @(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate') -Recurse -File)
Assert-BoostLabCondition ($sourcePromotedFiles.Count -eq $inventoryBaseline.SourcePromotedMirrorFiles) "Expected $($inventoryBaseline.SourcePromotedMirrorFiles) source-promoted mirror files, found $($sourcePromotedFiles.Count)."
$remainingSourcePromoted = @(
    $sourcePromotedFiles | Where-Object {
        $_.Name -notin @('1 Driver Clean.ps1', '2 Driver Install Latest.ps1', '4 Nvidia Settings.ps1', '5 Hdcp.ps1', '6 P0 State.ps1', '7 Msi Mode.ps1', '1 BitLocker.ps1')
    }
)
Assert-BoostLabCondition ($remainingSourcePromoted.Count -eq $inventoryBaseline.RemainingSourcePromotedIntakeCandidates) "Remaining source-promoted intake candidate count mismatch."

$executionText = Get-Content -LiteralPath $executionPath -Raw
foreach ($needle in @(
    "'nvidia-settings'",
    "Graphics\nvidia-settings.psm1",
    "'Analyze', 'Apply', 'Default'"
)) {
    Assert-BoostLabTextContains -Text $executionText -Needle $needle -Description 'Execution registration'
}

$uiText = Get-Content -LiteralPath $uiPath -Raw
$driverCleanBlock = Get-BoostLabTextBetween -Text $uiText -Start 'if ($toolId -eq ''driver-clean'')' -End 'if ($toolId -eq ''nvidia-settings'')'
Assert-BoostLabTextContains -Text $driverCleanBlock -Needle "'Open' { return 'Manual' }" -Description 'Driver Clean label preservation'
Assert-BoostLabTextContains -Text $driverCleanBlock -Needle "'Apply' { return 'Auto' }" -Description 'Driver Clean label preservation'
$nvidiaSettingsBlock = Get-BoostLabTextBetween -Text $uiText -Start 'if ($toolId -eq ''nvidia-settings'')' -End 'return $ActionName'
Assert-BoostLabTextContains -Text $nvidiaSettingsBlock -Needle "'Apply' { return 'On (Recommended)' }" -Description 'Nvidia Settings On label'
Assert-BoostLabTextContains -Text $nvidiaSettingsBlock -Needle "'Default' { return 'Default' }" -Description 'Nvidia Settings Default label'
Assert-BoostLabCondition (-not $nvidiaSettingsBlock.Contains('Manual Handoff')) 'Nvidia Settings must not expose Manual Handoff.'
Assert-BoostLabCondition (-not $nvidiaSettingsBlock.Contains('Apply Auto')) 'Nvidia Settings must not expose Apply Auto.'
Assert-BoostLabCondition (-not $nvidiaSettingsBlock.Contains("'Open'")) 'Nvidia Settings must not expose a fake Open label.'

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
Assert-BoostLabTextContains -Text $actionPlanText -Needle "[ValidateSet('Apply', 'Default', 'Open', 'Analyze', 'Restore', 'Off')]" -Description 'Action plan canonical ValidateSet'
foreach ($needle in @(
    'Run the source-defined Nvidia Settings On (Recommended) branch',
    'Run the source-defined Nvidia Settings Default branch',
    'Run the source-defined common prelude: download 7zip.exe',
    'write the exact source On inspector.nip payload',
    'write the exact source Default inspector.nip payload',
    'Default is source-defined behavior, not captured-state Restore.',
    'Do not reboot, use Safe Mode, use TrustedInstaller, create RunOnce, modify services, or modify drivers.'
)) {
    Assert-BoostLabTextContains -Text $actionPlanText -Needle $needle -Description 'Nvidia Settings action plan wording'
}
Assert-BoostLabCondition (-not $actionPlanText.Contains('Prepare Nvidia Settings manual handoff instructions only')) 'Nvidia Settings Action Plan must not use old manual handoff wording.'
Assert-BoostLabCondition (-not $actionPlanText.Contains('Auto mode is blocked for Nvidia Settings')) 'Nvidia Settings Action Plan must not use old Auto blocked wording.'

$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($needle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')',
    $expectedSourceHash,
    'SourceEquivalentOnDefaultRuntime',
    'On (Recommended)',
    'Get-BoostLabNvidiaSettingsSourceNipPayloads',
    'Start-Process inspector.exe -silentImport -silent inspector.nip -Wait',
    'RestoreUnavailable'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'Nvidia Settings module text'
}
Assert-BoostLabCondition (-not $moduleText.Contains('ManualHandoffOnly')) 'Nvidia Settings module must not remain ManualHandoffOnly.'
Assert-BoostLabCondition (-not $moduleText.Contains('AutoBlockedUntilArtifactApproval')) 'Nvidia Settings module must not keep old AutoBlocked status.'
Assert-BoostLabCondition (-not $moduleText.Contains('$script:BoostLabImplementedActions = @(''Analyze'', ''Open'', ''Apply'')')) 'Nvidia Settings must not keep old action list.'

Import-Module -Name $modulePath -Force -ErrorAction Stop
try {
    $info = Get-BoostLabToolInfo
    Assert-BoostLabCondition ([string]$info.Id -eq 'nvidia-settings') 'Module info Id mismatch.'
    Assert-BoostLabCondition ((@($info.ImplementedActions) -join ',') -eq 'Analyze,Apply,Default') 'Implemented action list mismatch.'
    Assert-BoostLabCondition ((@($info.Actions) -join ',') -eq 'Analyze,Apply,Default') 'Module action list mismatch.'

    $analyzeResult = Invoke-BoostLabToolAction -ActionName 'Analyze'
    Assert-BoostLabCondition ([bool]$analyzeResult.Success) 'Analyze should succeed when source checksum is valid.'
    Assert-BoostLabCondition ([string]$analyzeResult.Status -eq 'Analyzed') 'Analyze status mismatch.'
    Assert-BoostLabCondition ([string]$analyzeResult.CommandStatus -eq 'No execution performed') 'Analyze must not execute anything.'
    Assert-BoostLabCondition ([string]$analyzeResult.Data.Mode -eq 'SourceEquivalentOnDefaultRuntime') 'Analyze mode mismatch.'
    foreach ($flag in @('NoMutationOccurred', 'NoDownloadOccurred', 'NoExternalProcessStarted', 'NoRegistryMutationOccurred', 'NoRebootOccurred')) {
        Assert-BoostLabCondition ([bool]$analyzeResult.Data.$flag) "Analyze expected flag true: $flag"
    }
    Assert-BoostLabCondition ([int]$analyzeResult.Data.ApplyPlan.CommonOperationCount -eq 8) 'Apply plan common prelude count mismatch.'
    Assert-BoostLabCondition ([int]$analyzeResult.Data.DefaultPlan.CommonOperationCount -eq 8) 'Default plan common prelude count mismatch.'
    Assert-BoostLabCondition ([int]$analyzeResult.Data.ApplyPlan.TotalOperationCount -eq 19) 'Apply plan total operation count mismatch.'
    Assert-BoostLabCondition ([int]$analyzeResult.Data.DefaultPlan.TotalOperationCount -eq 19) 'Default plan total operation count mismatch.'
    Assert-BoostLabCondition ([string]$analyzeResult.Data.ApplyPlan.NipPayload -eq $sourceOnNip) 'Apply plan .nip payload must match source exactly.'
    Assert-BoostLabCondition ([string]$analyzeResult.Data.DefaultPlan.NipPayload -eq $sourceDefaultNip) 'Default plan .nip payload must match source exactly.'

    $openResult = Invoke-BoostLabToolAction -ActionName 'Open'
    Assert-BoostLabCondition (-not [bool]$openResult.Success) 'Open must be unavailable for Nvidia Settings.'
    Assert-BoostLabCondition ([string]$openResult.Status -eq 'OpenUnavailable') 'Open unavailable status mismatch.'
    Assert-BoostLabCondition ([bool]$openResult.Data.NoExternalProcessStarted) 'Open unavailable must not start external process.'

    $restoreResult = Invoke-BoostLabToolAction -ActionName 'Restore'
    Assert-BoostLabCondition (-not [bool]$restoreResult.Success) 'Restore must be unavailable for Nvidia Settings.'
    Assert-BoostLabCondition ([string]$restoreResult.Status -eq 'RestoreUnavailable') 'Restore unavailable status mismatch.'

    $unconfirmedOn = Invoke-BoostLabToolAction -ActionName 'On (Recommended)'
    Assert-BoostLabCondition (-not [bool]$unconfirmedOn.Success) 'Unconfirmed On must be cancelled.'
    Assert-BoostLabCondition ([bool]$unconfirmedOn.Cancelled) 'Unconfirmed On should report Cancelled.'
    Assert-BoostLabCondition ([string]$unconfirmedOn.Action -eq 'Apply') 'On display label must route to Apply.'

    $script:MockedOperations = New-Object System.Collections.Generic.List[object]
    $mockExecutor = {
        param([Parameter(Mandatory)][object]$Operation)
        $script:MockedOperations.Add($Operation)
        [pscustomobject]@{
            Success = $true
            Operation = $Operation
            Status = 'Mocked'
            Message = "Mocked: $($Operation.Label)"
        }
    }

    $onResult = Invoke-BoostLabToolAction -ActionName 'On (Recommended)' -Confirmed:$true -OperationExecutor $mockExecutor
    Assert-BoostLabCondition ([bool]$onResult.Success) 'Mocked On should succeed.'
    Assert-BoostLabCondition ([string]$onResult.Action -eq 'Apply') 'On should return canonical Apply.'
    Assert-BoostLabCondition ([string]$onResult.Status -eq 'Completed') 'On status mismatch.'
    Assert-BoostLabCondition ([bool]$onResult.ChangesExecuted) 'On should report changes executed when mocked operations complete.'
    $onOperations = @($script:MockedOperations.ToArray())
    Assert-BoostLabCondition ($onOperations.Count -eq 19) 'On should execute all source-defined operation descriptors with the mock executor.'
    Assert-BoostLabCondition (@($onOperations | Where-Object { [string]$_.Type -eq 'DownloadFile' }).Count -eq 2) 'On must represent both source downloads.'
    Assert-BoostLabCondition (@($onOperations | Where-Object { [string]$_.Type -eq 'StartProcess' }).Count -eq 3) 'On must represent 7-Zip, Profile Inspector, and Control Panel process starts.'
    Assert-BoostLabCondition (@($onOperations | Where-Object { [string]$_.Type -eq 'WriteTextFile' -and [string]$_.Parameters.Content -eq $sourceOnNip }).Count -eq 1) 'On must write the exact source On .nip payload.'
    Assert-BoostLabCondition (@($onOperations | Where-Object { [string]$_.Type -eq 'SetRegistryValueCollection' -and [int]$_.Parameters.Data -eq 0 }).Count -eq 1) 'On must set EnableGR535 to DWORD 0 on the source FTS paths.'

    $script:MockedOperations = New-Object System.Collections.Generic.List[object]
    $defaultResult = Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed:$true -OperationExecutor $mockExecutor
    Assert-BoostLabCondition ([bool]$defaultResult.Success) 'Mocked Default should succeed.'
    Assert-BoostLabCondition ([string]$defaultResult.Action -eq 'Default') 'Default action mismatch.'
    Assert-BoostLabCondition ([bool]$defaultResult.ChangesExecuted) 'Default should report changes executed when mocked operations complete.'
    $defaultOperations = @($script:MockedOperations.ToArray())
    Assert-BoostLabCondition ($defaultOperations.Count -eq 19) 'Default should execute all source-defined operation descriptors with the mock executor.'
    Assert-BoostLabCondition (@($defaultOperations | Where-Object { [string]$_.Type -eq 'RemoveRegistryKey' -and [string]$_.Parameters.Path -eq 'HKCU:\Software\NVIDIA Corporation\NvTray' }).Count -eq 1) 'Default must delete the source-defined NvTray key.'
    Assert-BoostLabCondition (@($defaultOperations | Where-Object { [string]$_.Type -eq 'SetRegistryValueCollection' -and [int]$_.Parameters.Data -eq 1 }).Count -eq 1) 'Default must set EnableGR535 to DWORD 1 on the source FTS paths.'
    Assert-BoostLabCondition (@($defaultOperations | Where-Object { [string]$_.Type -eq 'WriteTextFile' -and [string]$_.Parameters.Content -eq $sourceDefaultNip }).Count -eq 1) 'Default must write the exact source Default .nip payload.'
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
    Assert-BoostLabTextContains -Text ([string]$runtimeAnalyze.ActionPlan.Summary) -Needle 'source-equivalent On (Recommended) and Default operation plans' -Description 'Runtime Analyze Action Plan summary'

    $runtimeDefault = Invoke-BoostLabToolAction -ToolMetadata $nvidiaSettingsTool -ActionName 'Default'
    Assert-BoostLabCondition (-not [bool]$runtimeDefault.Success) 'Runtime unconfirmed Default should not execute in the validator.'
    Assert-BoostLabTextContains -Text ([string]$runtimeDefault.ActionPlan.Summary) -Needle 'Default branch' -Description 'Runtime Default Action Plan summary'
}
finally {
    $env:ProgramData = $previousProgramData
    Remove-Item -LiteralPath $tempProgramData -Recurse -Force -ErrorAction SilentlyContinue
}

$artifactText = Get-Content -LiteralPath $artifactPath -Raw
foreach ($forbiddenArtifactText in @('7zip.exe', 'inspector.exe', 'NVIDIA Profile Inspector', 'inspector.nip', 'FR33THYFR33THY')) {
    Assert-BoostLabCondition (-not $artifactText.Contains($forbiddenArtifactText)) "Unexpected artifact approval related to HDCP: $forbiddenArtifactText"
}
$externalArtifactSource = Import-PowerShellDataFile -LiteralPath $externalArtifactSourcePath
$nvidiaExternalEntries = @($externalArtifactSource.ExternalSources | Where-Object { [string]$_.ToolId -eq 'nvidia-settings' })
Assert-BoostLabCondition ($nvidiaExternalEntries.Count -eq 2) 'Nvidia Settings must keep exactly two external artifact source policy records.'
foreach ($entry in $nvidiaExternalEntries) {
    Assert-BoostLabCondition ([string]$entry.SourceClassification -eq 'UltimateAuthorHostedArtifact') 'Nvidia Settings external artifact source classification changed.'
    Assert-BoostLabCondition ([string]$entry.MirrorStatus -eq 'NeedsBoostLabMirror') 'Nvidia Settings external artifact mirror status changed.'
}

$productionPolicy = Import-PowerShellDataFile -LiteralPath $productionAllowlistPath
if ($productionPolicy.ContainsKey('ProductionAllowlistProposals')) {
    Assert-BoostLabCondition (@($productionPolicy.ProductionAllowlistProposals).Count -eq 0) 'Production allowlist proposals should remain empty.'
}

$nvidiaParityRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'nvidia-settings' })[0]
Assert-BoostLabCondition ([string]$nvidiaParityRecord.ImplementationLevel -eq 'NearParityControlled') 'Nvidia Settings parity level must be NearParityControlled.'
Assert-BoostLabCondition ([string]$nvidiaParityRecord.FinalProgressStatus -eq 'DoneYazanAcceptedNearParity') 'Nvidia Settings final progress status mismatch.'
Assert-BoostLabCondition ([bool]$nvidiaParityRecord.YazanAcceptedNearParity) 'Nvidia Settings near-parity acceptance flag must be set.'
$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq 'graphics-configuration-center') 'Next ordered pending parity target should advance to Graphics Configuration Center after Visual C++.'
$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
Assert-BoostLabCondition ([int]$categoryCounts['NearParityControlled'] -eq [int]$parityBaseline.Counts.NearParityControlled) 'NearParityControlled count mismatch.'
Assert-BoostLabCondition ([int]$categoryCounts['ManualHandoffOnly'] -eq [int]$parityBaseline.Counts.ManualHandoffOnly) 'ManualHandoffOnly count mismatch.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.NearParityControlled -eq 25) 'NearParityControlled count should be 25 after Visual C++.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.ManualHandoffOnly -eq 1) 'ManualHandoffOnly count should be 1 after Visual C++.'

foreach ($deletedPath in @(
    'source-ultimate\6 Windows\17 Loudness EQ.ps1',
    'source-ultimate\6 Windows\30 NVME Faster Driver.ps1'
)) {
    Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $deletedPath))) "Deleted source was reintroduced: $deletedPath"
}

[pscustomobject]@{
    TestName = 'Nvidia Settings exact Ultimate parity implementation'
    ActiveTools = $allTools.Count
    ImplementedTools = $allTools.Count - $placeholderModules.Count
    DeferredPlaceholders = $placeholderModules.Count
    SourcePromotedMirrorFiles = $sourcePromotedFiles.Count
    RemainingUnimplementedSourcePromotedCandidates = $remainingSourcePromoted.Count
    SourceHash = $actualSourceHash
    NvidiaSettingsActions = @($nvidiaSettingsTool.Actions)
    NextOrderedParityTarget = [string]$nextTarget.ToolId
}


