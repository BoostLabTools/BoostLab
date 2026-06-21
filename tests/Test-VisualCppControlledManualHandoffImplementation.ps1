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
        throw 'Unable to determine the Visual C++ validator path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
. (Join-Path $ProjectRoot 'tests\BoostLab.ParityStatusBaseline.ps1')

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

function New-BoostLabMockVisualCppOperationResult {
    param(
        [Parameter(Mandatory)]
        [object]$Operation,

        [bool]$Success = $true,

        [string]$Message = 'mock ok'
    )

    [pscustomobject]@{
        Success   = $Success
        Status    = if ($Success) { 'Completed' } else { 'Failed' }
        Order     = [int]$Operation.Order
        Type      = [string]$Operation.Type
        Label     = [string]$Operation.Label
        Required  = [bool]$Operation.Required
        Message   = $Message
        Data      = $null
        Timestamp = Get-Date
    }
}

$expectedSourceHash = '7ACB1F25ECFEEAD83FA389E2D0C1FEEF12232C4E9A740CB5DE64A326FFD38C09'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\5 Graphics\3 C++.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Graphics\visual-cpp.psm1'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$mainWindowPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$externalSourcesPath = Join-Path $ProjectRoot 'config\ExternalArtifactSources.psd1'
$artifactProvenancePath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$allowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$migrationPath = Join-Path $ProjectRoot 'docs\migrations\visual-cpp.md'
$provenanceReviewPath = Join-Path $ProjectRoot 'docs\visual-cpp-provenance-review.md'

foreach ($requiredPath in @($sourcePath, $modulePath, $stagesPath, $executionPath, $actionPlanPath, $mainWindowPath, $externalSourcesPath, $artifactProvenancePath, $migrationPath, $provenanceReviewPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $requiredPath -PathType Leaf) "Required Visual C++ file is missing: $requiredPath"
}

$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Visual C++ source hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."

$expectedDownloads = @(
    'vcredist2005_x64.exe'
    'vcredist2005_x86.exe'
    'vcredist2008_x64.exe'
    'vcredist2008_x86.exe'
    'vcredist2010_x64.exe'
    'vcredist2010_x86.exe'
    'vcredist2012_x64.exe'
    'vcredist2012_x86.exe'
    'vcredist2013_x64.exe'
    'vcredist2013_x86.exe'
    'vcredist2015_2017_2019_2022_x64.exe'
    'vcredist2015_2017_2019_2022_x86.exe'
)
$expectedInstallers = @(
    @{ FileName = 'vcredist2005_x86.exe'; Arguments = '/q' }
    @{ FileName = 'vcredist2005_x64.exe'; Arguments = '/q' }
    @{ FileName = 'vcredist2008_x86.exe'; Arguments = '/qb' }
    @{ FileName = 'vcredist2008_x64.exe'; Arguments = '/qb' }
    @{ FileName = 'vcredist2010_x86.exe'; Arguments = '/passive /norestart' }
    @{ FileName = 'vcredist2010_x64.exe'; Arguments = '/passive /norestart' }
    @{ FileName = 'vcredist2012_x86.exe'; Arguments = '/passive /norestart' }
    @{ FileName = 'vcredist2012_x64.exe'; Arguments = '/passive /norestart' }
    @{ FileName = 'vcredist2013_x86.exe'; Arguments = '/passive /norestart' }
    @{ FileName = 'vcredist2013_x64.exe'; Arguments = '/passive /norestart' }
    @{ FileName = 'vcredist2015_2017_2019_2022_x86.exe'; Arguments = '/passive /norestart' }
    @{ FileName = 'vcredist2015_2017_2019_2022_x64.exe'; Arguments = '/passive /norestart' }
)

$sourceText = Get-Content -LiteralPath $sourcePath -Raw
foreach ($packageFile in $expectedDownloads) {
    Assert-BoostLabTextContains -Text $sourceText -Needle "refs/heads/main/$packageFile" -Description 'Visual C++ Ultimate source package URL'
    Assert-BoostLabTextContains -Text $sourceText -Needle "Temp\$packageFile" -Description 'Visual C++ Ultimate source temp target'
}
foreach ($installer in $expectedInstallers) {
    Assert-BoostLabTextContains -Text $sourceText -Needle $installer.FileName -Description 'Visual C++ Ultimate installer file'
    Assert-BoostLabTextContains -Text $sourceText -Needle $installer.Arguments -Description 'Visual C++ Ultimate installer arguments'
}
Assert-BoostLabTextContains -Text $sourceText -Needle 'Test-Connection -ComputerName "8.8.8.8"' -Description 'Visual C++ Ultimate internet check'
Assert-BoostLabTextContains -Text $sourceText -Needle '$progresspreference = ''silentlycontinue''' -Description 'Visual C++ Ultimate progress preference'

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$graphicsStage = @($stages.Stages | Where-Object { [string]$_.Name -eq 'Graphics' })[0]
$visualCppTool = @($graphicsStage.Tools | Where-Object { [string]$_.Id -eq 'visual-cpp' })[0]
Assert-BoostLabCondition ($null -ne $visualCppTool) 'Visual C++ is missing from Graphics stage.'
Assert-BoostLabCondition ([string]$visualCppTool.Title -eq 'Visual C++') 'Visual C++ title mismatch.'
Assert-BoostLabCondition ([int]$visualCppTool.Order -eq 9) 'Visual C++ must remain Graphics order 9.'
Assert-BoostLabCondition ([string]$visualCppTool.Type -eq 'action') 'Visual C++ must be an action tool after Phase 130.'
Assert-BoostLabCondition ([string]$visualCppTool.RiskLevel -eq 'high') 'Visual C++ must remain high risk.'
Assert-BoostLabCondition ((@($visualCppTool.Actions) -join ',') -eq 'Analyze,Apply') 'Visual C++ must expose only Analyze and Apply.'
Assert-BoostLabTextContains -Text ([string]$visualCppTool.Description) -Needle 'Source-equivalent controlled runtime' -Description 'Visual C++ stage description'

$capabilities = $visualCppTool.Capabilities
foreach ($trueCapability in @('RequiresAdmin', 'RequiresInternet', 'CanInstallSoftware', 'CanDownload', 'NeedsExplicitConfirmation')) {
    Assert-BoostLabCondition ([bool]$capabilities[$trueCapability]) "Visual C++ capability should be true: $trueCapability"
}
foreach ($falseCapability in @('CanReboot', 'CanModifyRegistry', 'CanModifyServices', 'CanModifyDrivers', 'CanModifySecurity', 'CanDeleteFiles', 'UsesTrustedInstaller', 'UsesSafeMode', 'SupportsDefault', 'SupportsRestore')) {
    Assert-BoostLabCondition (-not [bool]$capabilities[$falseCapability]) "Visual C++ capability should be false: $falseCapability"
}

$executionText = Get-Content -LiteralPath $executionPath -Raw
Assert-BoostLabTextContains -Text $executionText -Needle "'visual-cpp'" -Description 'Execution module Visual C++ registration'
Assert-BoostLabTextContains -Text $executionText -Needle "Graphics\visual-cpp.psm1" -Description 'Execution module Visual C++ path'
Assert-BoostLabTextContains -Text $executionText -Needle "Actions = @('Analyze', 'Apply')" -Description 'Execution module Visual C++ actions'

$uiText = Get-Content -LiteralPath $mainWindowPath -Raw
Assert-BoostLabTextContains -Text $uiText -Needle "if (`$toolId -eq 'visual-cpp')" -Description 'Visual C++ UI action label branch'
Assert-BoostLabTextContains -Text $uiText -Needle "'Apply' { return 'Install Visual C++' }" -Description 'Visual C++ Apply label'
Assert-BoostLabTextContains -Text $uiText -Needle "'visual-cpp'" -Description 'Visual C++ async scope'
Assert-BoostLabCondition (-not $uiText.Contains("'Open' { return 'Manual Handoff' }")) 'Visual C++ must not reintroduce a manual handoff label.'

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
foreach ($needle in @(
    'Install Visual C++ using the source-equivalent controlled workflow'
    'Download all twelve source-defined Visual C++ redistributable installers'
    'Run all twelve installers sequentially with `Start-Process -Wait`'
    'UltimateAuthorHostedArtifact'
    'NeedsBoostLabMirror'
    'Visual C++ Open is unavailable because the source defines an install workflow'
    'Visual C++ Default is unavailable. The source does not define a safe Default branch'
    'Visual C++ Restore requires selected captured artifact'
)) {
    Assert-BoostLabTextContains -Text $actionPlanText -Needle $needle -Description 'Visual C++ Action Plan wording'
}
Assert-BoostLabCondition (-not $actionPlanText.Contains('Visual C++ Auto mode is blocked. BoostLab will not execute Auto behavior')) 'Visual C++ Apply must not be worded as Auto blocked after Phase 130.'
Assert-BoostLabCondition (-not $actionPlanText.Contains('Prepare Visual C++ manual handoff instructions only')) 'Visual C++ must not keep manual handoff Action Plan wording.'

$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($needle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'')'
    'SourceEquivalentControlledRuntime'
    'SourceEquivalentVisualCppInstall'
    'Invoke-WebRequest'
    'Start-Process'
    'Test-Connection -ComputerName ''8.8.8.8'''
    'NeedsBoostLabMirror'
    'UltimateAuthorHostedArtifact'
    'Visual C++ source-equivalent workflow completed'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'Visual C++ module text'
}
foreach ($forbiddenText in @(
    'ToolModule.Placeholder.ps1'
    'ManualHandoffOnly'
    'AutoBlockedUntilArtifactApproval'
    'winget'
    '7z.exe'
    'bcdedit'
    'RunOnce'
    'DDU'
)) {
    Assert-BoostLabCondition (-not $moduleText.Contains($forbiddenText)) "Visual C++ module contains forbidden text after Phase 130: $forbiddenText"
}

Import-Module -Name (Join-Path $ProjectRoot 'modules\Graphics\visual-cpp.psm1') -Force

$info = Get-BoostLabToolInfo
Assert-BoostLabCondition ([string]$info.Id -eq 'visual-cpp') 'Module info Id mismatch.'
Assert-BoostLabCondition ((@($info.Actions) -join ',') -eq 'Analyze,Apply') 'Module info must expose only Analyze and Apply.'
Assert-BoostLabCondition ((@($info.ImplementedActions) -join ',') -eq 'Analyze,Apply') 'Implemented actions mismatch.'
Assert-BoostLabCondition ((@($info.ConfirmationRequiredActions) -join ',') -eq 'Apply') 'Only Apply should require confirmation.'

$analysis = Invoke-BoostLabToolAction -ActionName 'Analyze'
Assert-BoostLabCondition ([bool]$analysis.Success) 'Analyze should succeed.'
Assert-BoostLabCondition ([string]$analysis.Status -eq 'Analyzed') 'Analyze status mismatch.'
Assert-BoostLabCondition ([string]$analysis.CommandStatus -eq 'No execution performed') 'Analyze command status mismatch.'
Assert-BoostLabCondition (-not [bool]$analysis.ChangesExecuted) 'Analyze must not execute changes.'
Assert-BoostLabCondition ([string]$analysis.Data.Mode -eq 'SourceEquivalentControlledRuntime') 'Analyze must report source-equivalent controlled runtime.'
Assert-BoostLabCondition (@($analysis.Data.ArtifactSources).Count -eq 12) 'Analyze must report all twelve artifact sources.'
Assert-BoostLabCondition (@($analysis.Data.Packages).Count -eq 12) 'Analyze must report all twelve packages.'
Assert-BoostLabCondition (@($analysis.Data.OperationPlan.Operations).Count -eq 27) 'Analyze operation plan must contain 27 operations.'
Assert-BoostLabCondition (@($analysis.Data.OperationPlan.Operations | Where-Object { [string]$_.Type -eq 'DownloadFile' }).Count -eq 12) 'Analyze operation plan must contain twelve downloads.'
Assert-BoostLabCondition (@($analysis.Data.OperationPlan.Operations | Where-Object { [string]$_.Type -eq 'StartInstallerWait' }).Count -eq 12) 'Analyze operation plan must contain twelve installer launches.'
Assert-BoostLabCondition ([bool]$analysis.Data.NoMutationOccurred) 'Analyze must be read-only.'
Assert-BoostLabCondition ([bool]$analysis.Data.NoDownloadOccurred) 'Analyze must not download.'
Assert-BoostLabCondition ([bool]$analysis.Data.NoInstallerExecutionOccurred) 'Analyze must not run installers.'

$plannedDownloadFiles = @($analysis.Data.OperationPlan.Operations | Where-Object { [string]$_.Type -eq 'DownloadFile' } | ForEach-Object { [string]$_.Parameters.ExpectedFileName })
Assert-BoostLabCondition ((@($plannedDownloadFiles) -join '|') -eq (@($expectedDownloads) -join '|')) 'Visual C++ download order mismatch.'
$plannedInstallerFiles = @($analysis.Data.OperationPlan.Operations | Where-Object { [string]$_.Type -eq 'StartInstallerWait' } | ForEach-Object { [string]$_.Parameters.SourcePath })
$expectedInstallerSourcePaths = @($expectedInstallers | ForEach-Object { '%SystemRoot%\Temp\{0}' -f [string]$_.FileName })
Assert-BoostLabCondition ((@($plannedInstallerFiles) -join '|') -eq (@($expectedInstallerSourcePaths) -join '|')) 'Visual C++ installer order mismatch.'
for ($i = 0; $i -lt $expectedInstallers.Count; $i++) {
    $operation = @($analysis.Data.OperationPlan.Operations | Where-Object { [string]$_.Type -eq 'StartInstallerWait' })[$i]
    Assert-BoostLabCondition ([string]$operation.Parameters.Arguments -eq [string]$expectedInstallers[$i].Arguments) "Visual C++ installer arguments mismatch at index $i."
}

$unconfirmed = Invoke-BoostLabToolAction -ActionName 'Apply'
Assert-BoostLabCondition (-not [bool]$unconfirmed.Success) 'Unconfirmed Apply should not succeed.'
Assert-BoostLabCondition ([string]$unconfirmed.Status -eq 'Cancelled') 'Unconfirmed Apply should be cancelled.'
Assert-BoostLabCondition (-not [bool]$unconfirmed.ChangesExecuted) 'Unconfirmed Apply must not execute changes.'

$operationLog = [System.Collections.Generic.List[object]]::new()
$successExecutor = {
    param($operation, $plan)

    $operationLog.Add([pscustomobject]@{
        Order      = [int]$operation.Order
        Type       = [string]$operation.Type
        Label      = [string]$operation.Label
        Parameters = $operation.Parameters
    }) | Out-Null

    New-BoostLabMockVisualCppOperationResult -Operation $operation -Success $true -Message 'mock ok'
}
$mockedApply = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true -OperationExecutor $successExecutor -SkipEnvironmentChecks:$true
Assert-BoostLabCondition ([bool]$mockedApply.Success) 'Mocked Apply should succeed.'
Assert-BoostLabCondition ([string]$mockedApply.Status -eq 'Completed') 'Mocked Apply status mismatch.'
Assert-BoostLabCondition ([bool]$mockedApply.ChangesExecuted) 'Mocked Apply should report attempted source-equivalent operations.'
Assert-BoostLabCondition (@($mockedApply.Data.Operations).Count -eq 27) 'Mocked Apply should report all 27 operations.'
Assert-BoostLabCondition (@($mockedApply.Data.Operations | Where-Object { [string]$_.Type -eq 'DownloadFile' }).Count -eq 12) 'Mocked Apply should report twelve downloads.'
Assert-BoostLabCondition (@($mockedApply.Data.Operations | Where-Object { [string]$_.Type -eq 'StartInstallerWait' }).Count -eq 12) 'Mocked Apply should report twelve installer launches.'
Assert-BoostLabCondition (@($mockedApply.Errors).Count -eq 0) 'Mocked Apply should not report errors.'
Assert-BoostLabCondition ([string]$mockedApply.VerificationStatus -eq 'Passed') 'Mocked Apply verification should pass.'

$failureExecutor = {
    param($operation, $plan)

    if ([string]$operation.Type -eq 'DownloadFile' -and [string]$operation.Parameters.ExpectedFileName -eq 'vcredist2008_x64.exe') {
        return New-BoostLabMockVisualCppOperationResult -Operation $operation -Success $false -Message 'mock download failure'
    }

    New-BoostLabMockVisualCppOperationResult -Operation $operation -Success $true -Message 'mock ok'
}
$failedApply = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true -OperationExecutor $failureExecutor -SkipEnvironmentChecks:$true
Assert-BoostLabCondition (-not [bool]$failedApply.Success) 'Failed mocked Apply should fail closed.'
Assert-BoostLabCondition ([string]$failedApply.Status -eq 'Failed') 'Failed mocked Apply status mismatch.'
Assert-BoostLabCondition ([string]$failedApply.VerificationStatus -eq 'Failed') 'Failed mocked Apply verification mismatch.'
Assert-BoostLabCondition (@($failedApply.Errors).Count -ge 1) 'Failed mocked Apply must report failed operation errors.'
Assert-BoostLabTextContains -Text ([string]$failedApply.Message) -Needle 'failed closed' -Description 'Failed mocked Apply message'

$unsupportedOpen = Invoke-BoostLabToolAction -ActionName 'Open'
Assert-BoostLabCondition (-not [bool]$unsupportedOpen.Success) 'Open should not succeed for Visual C++.'
Assert-BoostLabCondition ([string]$unsupportedOpen.Status -eq 'Unsupported') 'Open should be unsupported for Visual C++.'

$restoreDefault = Restore-BoostLabToolDefault
Assert-BoostLabCondition (-not [bool]$restoreDefault.Success) 'Default restore helper should not succeed.'
Assert-BoostLabCondition ([string]$restoreDefault.Status -eq 'DefaultUnavailable') 'Default helper status mismatch.'

$externalSources = Import-PowerShellDataFile -LiteralPath $externalSourcesPath
$visualCppExternalEntries = @($externalSources.ExternalSources | Where-Object { [string]$_.ToolId -eq 'visual-cpp' })
Assert-BoostLabCondition ($visualCppExternalEntries.Count -eq 12) 'External artifact source manifest must classify all twelve Visual C++ source URLs.'
Assert-BoostLabCondition ('visual-cpp' -in @($externalSources.AuditScope.ReachedToolIds | ForEach-Object { [string]$_ })) 'Visual C++ must be in reached artifact-source scope.'
Assert-BoostLabCondition ('visual-cpp' -notin @($externalSources.AuditScope.PrepOnlyToolIds | ForEach-Object { [string]$_ })) 'Visual C++ must no longer be prep-only.'
Assert-BoostLabCondition ('visual-cpp' -notin @($externalSources.AuditScope.ExplicitlyOutOfScopeToolIds | ForEach-Object { [string]$_ })) 'Visual C++ must not be out-of-scope after Phase 130.'
for ($i = 0; $i -lt $expectedDownloads.Count; $i++) {
    $fileName = $expectedDownloads[$i]
    $entry = @($visualCppExternalEntries | Where-Object { [string]$_.OriginalDownloadUrl -eq "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/$fileName" })[0]
    Assert-BoostLabCondition ($null -ne $entry) "Missing Visual C++ external source entry for $fileName."
    Assert-BoostLabCondition ([string]$entry.SourceClassification -eq 'UltimateAuthorHostedArtifact') "Visual C++ external source classification mismatch for $fileName."
    Assert-BoostLabCondition ([string]$entry.MirrorStatus -eq 'NeedsBoostLabMirror') "Visual C++ mirror status mismatch for $fileName."
    Assert-BoostLabCondition ([string]$entry.ExpectedSha256 -match '^[A-Fa-f0-9]{64}$') "Visual C++ SHA evidence missing or malformed for $fileName."
    Assert-BoostLabCondition ([int64]$entry.ExpectedSizeBytes -gt 0) "Visual C++ size evidence missing for $fileName."
    Assert-BoostLabCondition ([string]::IsNullOrWhiteSpace([string]$entry.IntendedBoostLabMirrorUrl)) "Visual C++ must not add mirror URL for $fileName."
    Assert-BoostLabCondition ($entry.ContainsKey('BoostLabMirrorAvailable') -and $entry.BoostLabMirrorAvailable -eq $false) "Visual C++ SHA evidence must not mark mirror available for $fileName."
    Assert-BoostLabCondition ($entry.ContainsKey('ArtifactProvenanceApproved') -and $entry.ArtifactProvenanceApproved -eq $false) "Visual C++ SHA evidence must not approve artifact provenance for $fileName."
    Assert-BoostLabCondition ($entry.ContainsKey('ProductionAllowlistApproved') -and $entry.ProductionAllowlistApproved -eq $false) "Visual C++ SHA evidence must not approve production allowlist for $fileName."
    Assert-BoostLabCondition ([string]$entry.ReleaseReadiness -eq 'BlockedPendingBoostLabMirrorProvenanceAndRuntimeVerification') "Visual C++ SHA evidence must remain release-blocked for $fileName."
}

$artifactProvenance = Import-PowerShellDataFile -LiteralPath $artifactProvenancePath
Assert-BoostLabCondition (@($artifactProvenance.Artifacts).Count -eq 0) 'Artifact provenance config must remain empty.'
if (Test-Path -LiteralPath $allowlistPath -PathType Leaf) {
    $allowlistText = Get-Content -LiteralPath $allowlistPath -Raw
    Assert-BoostLabCondition (-not $allowlistText.Contains('visual-cpp')) 'Production allowlist must not approve Visual C++.'
}

$migrationText = Get-Content -LiteralPath $migrationPath -Raw
$provenanceText = Get-Content -LiteralPath $provenanceReviewPath -Raw
foreach ($needle in @(
    'Phase 130 replaces the earlier manual-handoff implementation with a'
    'source-equivalent controlled runtime'
    'No `config/ArtifactProvenance.psd1`'
    'DoneYazanAcceptedNearParity'
)) {
    Assert-BoostLabTextContains -Text $migrationText -Needle $needle -Description 'Visual C++ migration record'
}
foreach ($needle in @(
    'Phase 130 supersedes the manual-handoff-only runtime'
    'source-equivalent controlled behavior accepted by Yazan as near parity'
    'No real Visual C++ redistributable is approved as a reusable BoostLab'
)) {
    Assert-BoostLabTextContains -Text $provenanceText -Needle $needle -Description 'Visual C++ provenance review'
}

$inventoryAssertion = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
$baseline = $inventoryAssertion.Baseline
$snapshot = $inventoryAssertion.Snapshot
Assert-BoostLabCondition ([int]$snapshot.ActiveTools -eq [int]$baseline.ActiveTools) 'Active tool count changed unexpectedly.'
Assert-BoostLabCondition ([int]$snapshot.ImplementedTools -eq [int]$baseline.ImplementedTools) 'Runtime implemented count changed unexpectedly.'
Assert-BoostLabCondition ([int]$snapshot.DeferredPlaceholders -eq [int]$baseline.DeferredPlaceholders) 'Deferred placeholder count changed unexpectedly.'

$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$visualRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'visual-cpp' })[0]
Assert-BoostLabCondition ([string]$visualRecord.ImplementationLevel -eq 'NearParityControlled') 'Visual C++ must be NearParityControlled after Phase 130.'
Assert-BoostLabCondition ([string]$visualRecord.FinalProgressStatus -eq 'DoneYazanAcceptedNearParity') 'Visual C++ final progress status mismatch.'
Assert-BoostLabCondition ([bool]$visualRecord.YazanAcceptedNearParity) 'Visual C++ must be Yazan-accepted near parity.'
Assert-BoostLabCondition ([bool]$visualRecord.YazanFinalException -eq $false) 'Visual C++ should not require YazanFinalException.'
$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq [string]$parityBaseline.CurrentOrderedParityTarget) 'Next ordered parity target must match the central parity baseline cursor.'
$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
Assert-BoostLabCondition ([int]$categoryCounts['NearParityControlled'] -eq [int]$parityBaseline.Counts.NearParityControlled) 'NearParityControlled count mismatch after Visual C++.'
Assert-BoostLabCondition ([int]$categoryCounts['ManualHandoffOnly'] -eq [int]$parityBaseline.Counts.ManualHandoffOnly) 'ManualHandoffOnly count mismatch after Visual C++.'

foreach ($protectedPath in @('source-ultimate', 'source-ultimate\_intake-promoted', 'intake')) {
    $fullPath = Join-Path $ProjectRoot $protectedPath
    if (Test-Path -LiteralPath $fullPath) {
        $recent = @(Get-ChildItem -LiteralPath $fullPath -Recurse -File | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-6) })
        Assert-BoostLabCondition ($recent.Count -eq 0) "Protected source/intake path has recent modifications during Visual C++ Phase 130: $protectedPath"
    }
}
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\23 NVME Faster Driver.ps1'))) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    TestName                  = 'VisualCppExactUltimateParityImplementation'
    SourcePath                = $sourcePath
    SourceSha256              = $actualSourceHash
    Actions                   = @($visualCppTool.Actions)
    DownloadCount             = $expectedDownloads.Count
    InstallerCount            = $expectedInstallers.Count
    MockedApplyStatus         = $mockedApply.Status
    ExternalSourceEntries     = $visualCppExternalEntries.Count
    ArtifactApprovals         = @($artifactProvenance.Artifacts).Count
    RuntimeUrlChanged         = $false
    NextOrderedParityTarget   = [string]$nextTarget.ToolId
    SourceUltimateUnchanged   = $true
    DeletedToolsRemainDeleted = $true
    Message                   = 'Visual C++ Phase 130 source-equivalent controlled runtime preserves the twelve download and twelve installer source workflow behind confirmation with no artifact/provenance approval.'
}
