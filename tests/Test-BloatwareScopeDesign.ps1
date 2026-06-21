[CmdletBinding()]
param(
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-BloatwareCondition {
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

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $scriptPath = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $PSCommandPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $MyInvocation.MyCommand.Path
    }
    else {
        throw 'Unable to determine the Bloatware validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
. (Join-Path $ProjectRoot 'tests\BoostLab.ParityStatusBaseline.ps1')

$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\11 Bloatware.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\bloatware.psm1'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$artifactPolicyPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

foreach ($requiredPath in @($sourcePath, $modulePath, $stagesPath, $executionPath, $actionPlanPath, $artifactPolicyPath, $productionAllowlistPath)) {
    Assert-BloatwareCondition (Test-Path -LiteralPath $requiredPath -PathType Leaf) "Required file missing: $requiredPath"
}

$expectedSourceHash = '36677A334B37025A7234F4320EE54EF50E9528D1814E2B3A463EEB564C5814F5'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
Assert-BloatwareCondition ($actualSourceHash -eq $expectedSourceHash) "Bloatware source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$bloatwareTool = @($stages.Stages | ForEach-Object { $_.Tools } | Where-Object { [string]$_.Id -eq 'bloatware' }) | Select-Object -First 1
Assert-BloatwareCondition ($null -ne $bloatwareTool) 'Bloatware stage metadata is missing.'
Assert-BloatwareCondition ([string]$bloatwareTool.Stage -eq 'Windows') 'Bloatware must remain in the Windows stage.'
Assert-BloatwareCondition ([string]$bloatwareTool.RiskLevel -eq 'high') 'Bloatware must remain high risk.'
Assert-BloatwareCondition (($bloatwareTool.Actions -join ',') -eq 'Analyze,Apply') 'Bloatware must expose only Analyze and Apply.'
Assert-BloatwareCondition ([string]$bloatwareTool.SelectionMode -eq 'SingleSelect') 'Bloatware must use single-select source branch selection.'
Assert-BloatwareCondition (($bloatwareTool.SelectionRequiredActions -join ',') -eq 'Apply') 'Only Apply should require branch selection.'
Assert-BloatwareCondition (-not [bool]$bloatwareTool.Capabilities.SupportsDefault) 'Bloatware must not expose Default.'
Assert-BloatwareCondition (-not [bool]$bloatwareTool.Capabilities.SupportsRestore) 'Bloatware must not expose Restore.'
foreach ($capability in @('RequiresAdmin', 'RequiresInternet', 'CanModifyRegistry', 'CanModifyServices', 'CanInstallSoftware', 'CanDownload', 'CanModifySecurity', 'CanDeleteFiles', 'NeedsExplicitConfirmation')) {
    Assert-BloatwareCondition ([bool]$bloatwareTool.Capabilities[$capability]) "Bloatware capability '$capability' must remain enabled for the approved source-equivalent branch runtime."
}

$expectedBranches = @(
    @{ Id = 'RemoveAllBloatware'; Title = 'Remove : All Bloatware (Recommended)'; SourceMenuNumber = 2; Count = 25 }
    @{ Id = 'InstallStore'; Title = 'Install: Store'; SourceMenuNumber = 3; Count = 9 }
    @{ Id = 'InstallAllUwpApps'; Title = 'Install: All UWP Apps'; SourceMenuNumber = 4; Count = 4 }
    @{ Id = 'OpenUwpFeatures'; Title = 'Install: UWP Features'; SourceMenuNumber = 5; Count = 6 }
    @{ Id = 'OpenLegacyFeatures'; Title = 'Install: Legacy Features'; SourceMenuNumber = 6; Count = 6 }
    @{ Id = 'InstallOneDrive'; Title = 'Install: One Drive'; SourceMenuNumber = 7; Count = 5 }
    @{ Id = 'InstallRemoteDesktopConnection'; Title = 'Install: Remote Desktop Connection'; SourceMenuNumber = 8; Count = 5 }
    @{ Id = 'InstallSnippingTool'; Title = 'Install: Snipping Tool'; SourceMenuNumber = 9; Count = 6 }
)
$expectedParityBranchTitles = @(
    'Remove : All Bloatware (Recommended)'
    'Install: Store'
    'Install: All UWP Apps'
    'Install: UWP Features'
    'Install: Legacy Features'
    'Install: One Drive'
    'Install: Remote Desktop Connection'
    'Install: Snipping Tool'
)
$stageBranchIds = @($bloatwareTool.SelectionItems | ForEach-Object { [string]$_.Id })
Assert-BloatwareCondition (($stageBranchIds -join ',') -eq (($expectedBranches.Id) -join ',')) 'Bloatware stage branch order does not match the approved Ultimate branches.'
foreach ($expected in $expectedBranches) {
    $actual = @($bloatwareTool.SelectionItems | Where-Object { [string]$_.Id -eq [string]$expected.Id }) | Select-Object -First 1
    Assert-BloatwareCondition ($null -ne $actual) "Missing Bloatware branch metadata: $($expected.Id)"
    Assert-BloatwareCondition ([string]$actual.Title -eq [string]$expected.Title) "Unexpected title for Bloatware branch $($expected.Id)."
    Assert-BloatwareCondition ([int]$actual.SourceMenuNumber -eq [int]$expected.SourceMenuNumber) "Unexpected source menu number for Bloatware branch $($expected.Id)."
}

$executionText = Get-Content -LiteralPath $executionPath -Raw
Assert-BloatwareCondition ($executionText.Contains("'bloatware' = @{")) 'Execution map must include Bloatware.'
Assert-BloatwareCondition ($executionText.Contains("Windows\bloatware.psm1")) 'Execution map must point Bloatware to the Windows module.'

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    $analyzePlan = New-BoostLabActionPlan -ToolMetadata $bloatwareTool -ActionName 'Analyze' -IsDryRun:$false
    $applyPlan = New-BoostLabActionPlan -ToolMetadata $bloatwareTool -ActionName 'Apply' -IsDryRun:$false
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}
Assert-BloatwareCondition (($analyzePlan.PlannedChanges -join "`n").Contains('Perform no package, capability, feature, registry, hive, service, task, process, file, ownership, ACL, download, installer, uninstaller, external process, reboot, or system mutation during Analyze.')) 'Analyze action plan must be read-only.'
Assert-BloatwareCondition (($applyPlan.PlannedChanges -join "`n").Contains('Require explicit confirmation and exactly one selected Bloatware source branch.')) 'Apply action plan must require confirmation and exactly one branch.'
Assert-BloatwareCondition (($applyPlan.PlannedChanges -join "`n").Contains('Do not expose Exit, Default, Restore, or unrelated repair behavior for Bloatware.')) 'Apply action plan must keep Exit, Default, and Restore unavailable.'
Assert-BloatwareCondition (($applyPlan.SideEffects -join "`n").Contains('UltimateAuthorHostedArtifact / NeedsBoostLabMirror')) 'Apply action plan must report source-hosted artifact classification.'
Assert-BloatwareCondition ([string]$applyPlan.ConfirmationMessage -like '*No Default or Restore branch exists*') 'Apply confirmation must warn that Default and Restore do not exist.'

$module = Import-Module -Name $modulePath -Force -PassThru -Scope Local -DisableNameChecking -ErrorAction Stop
try {
    $info = Get-BoostLabToolInfo
    Assert-BloatwareCondition ([string]$info.Id -eq 'bloatware') 'Bloatware tool info returned the wrong id.'
    Assert-BloatwareCondition (($info.Actions -join ',') -eq 'Analyze,Apply') 'Bloatware module must expose only Analyze and Apply.'
    Assert-BloatwareCondition ([string]$info.SelectionMode -eq 'SingleSelect') 'Bloatware module must expose single-select branch selection.'
    Assert-BloatwareCondition (($info.SelectionItems.Id -join ',') -eq (($expectedBranches.Id) -join ',')) 'Bloatware module branch order does not match the approved Ultimate branch order.'

    $sourceStatus = Get-BoostLabBloatwareSourceStatus
    Assert-BloatwareCondition ([string]$sourceStatus.ChecksumStatus -eq 'Passed') 'Bloatware source status must pass checksum verification.'
    Assert-BloatwareCondition ([string]$sourceStatus.ExpectedSha256 -eq $expectedSourceHash) 'Bloatware source status expected hash mismatch.'

    $analysisResult = Invoke-BoostLabToolAction -ActionName 'Analyze'
    Assert-BloatwareCondition ([bool]$analysisResult.Success) 'Bloatware Analyze should succeed.'
    Assert-BloatwareCondition ([string]$analysisResult.CommandStatus -eq 'ReadOnly') 'Bloatware Analyze must be read-only.'
    Assert-BloatwareCondition (-not [bool]$analysisResult.ChangesExecuted) 'Bloatware Analyze must execute no changes.'
    foreach ($noMutationField in @('NoMutationOccurred', 'NoDownloadOccurred', 'NoInstallerExecutionOccurred', 'NoRegistryMutationOccurred', 'NoPackageMutationOccurred', 'NoFeatureMutationOccurred', 'NoServiceMutationOccurred', 'NoTaskMutationOccurred', 'NoProcessMutationOccurred', 'NoFileMutationOccurred', 'NoRebootOrSessionChangeOccurred')) {
        Assert-BloatwareCondition ([bool]$analysisResult.Data.$noMutationField) "Bloatware Analyze must report $noMutationField."
    }
    Assert-BloatwareCondition (@($analysisResult.Data.OperationPlans).Count -eq 8) 'Bloatware Analyze must report all eight approved non-Exit branches.'

    foreach ($expected in $expectedBranches) {
        $plan = Get-BoostLabBloatwareOperationPlan -Branch ([string]$expected.Id)
        Assert-BloatwareCondition ([int]$plan.SourceMenuNumber -eq [int]$expected.SourceMenuNumber) "Unexpected source menu number in plan $($expected.Id)."
        Assert-BloatwareCondition ([int]$plan.OperationCount -eq [int]$expected['Count']) "Unexpected operation count in plan $($expected.Id)."
        Assert-BloatwareCondition (@($plan.Operations | Where-Object { [string]$_.Branch -ne [string]$expected.Id }).Count -eq 0) "Plan $($expected.Id) contains operations from another branch."
    }

    $removePlan = Get-BoostLabBloatwareOperationPlan -Branch 'RemoveAllBloatware'
    foreach ($requiredType in @('RemoveAppxExcept', 'RemoveWindowsCapabilityExcept', 'DisableOptionalFeatureExcept', 'Cmd', 'RemoveItem', 'MsiUninstallByDisplayName', 'StopProcess', 'UninstallOneDriveAllUsers', 'UnregisterScheduledTasksLike', 'StartProcess', 'StopProcessWindow', 'UnregisterScheduledTaskName')) {
        Assert-BloatwareCondition (($removePlan.Operations.Type -contains $requiredType) -or ($removePlan.Operations.Type -join ',' -like "*$requiredType*")) "Remove all bloatware plan is missing operation type $requiredType."
    }
    Assert-BloatwareCondition (-not ($removePlan.Operations.Type -join ',' -like '*Provisioned*')) 'Bloatware must not invent provisioned package removal absent from the source.'

    $storePlan = Get-BoostLabBloatwareOperationPlan -Branch 'InstallStore'
    foreach ($requiredType in @('AppxRegisterLike', 'StartProcess', 'StopProcesses', 'RegistryCommand', 'StoreSettingsHiveImport')) {
        Assert-BloatwareCondition ($storePlan.Operations.Type -contains $requiredType) "Install Store plan is missing operation type $requiredType."
    }

    $uwpPlan = Get-BoostLabBloatwareOperationPlan -Branch 'InstallAllUwpApps'
    Assert-BloatwareCondition ($uwpPlan.Operations.Type -contains 'AppxRegisterAll') 'Install all UWP apps plan must re-register all AppX packages.'

    foreach ($featureBranch in @('OpenUwpFeatures', 'OpenLegacyFeatures')) {
        $featurePlan = Get-BoostLabBloatwareOperationPlan -Branch $featureBranch
        Assert-BloatwareCondition ($featurePlan.Operations.Type -contains 'StartProcess') "$featureBranch must preserve the source settings/control-panel open behavior."
        Assert-BloatwareCondition ($featurePlan.Operations.Type -contains 'DisplayList') "$featureBranch must preserve the source optional feature list behavior."
    }

    $oneDrivePlan = Get-BoostLabBloatwareOperationPlan -Branch 'InstallOneDrive'
    $oneDriveCommands = @(
        $oneDrivePlan.Operations | ForEach-Object {
            if ($_.Parameters -is [System.Collections.IDictionary] -and $_.Parameters.Contains('Command')) {
                [string]$_.Parameters['Command']
            }
        }
    )
    Assert-BloatwareCondition (($oneDriveCommands -join "`n").Contains('{SysWow64OneDriveSetup}')) 'Install OneDrive must preserve the SysWOW64 setup branch.'
    Assert-BloatwareCondition (($oneDriveCommands -join "`n").Contains('{System32OneDriveSetup}')) 'Install OneDrive must preserve the System32 setup branch.'

    $rdpPlan = Get-BoostLabBloatwareOperationPlan -Branch 'InstallRemoteDesktopConnection'
    $rdpDownload = @($rdpPlan.DownloadArtifacts) | Select-Object -First 1
    Assert-BloatwareCondition ([string]$rdpDownload.Url -eq 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/remotedesktopconnection.exe') 'Remote Desktop Connection source URL mismatch.'
    Assert-BloatwareCondition ([string]$rdpDownload.Classification -eq 'UltimateAuthorHostedArtifact') 'Remote Desktop Connection must be classified as UltimateAuthorHostedArtifact.'
    Assert-BloatwareCondition ([bool]$rdpDownload.NeedsBoostLabMirror) 'Remote Desktop Connection must remain NeedsBoostLabMirror.'

    $snipPlan = Get-BoostLabBloatwareOperationPlan -Branch 'InstallSnippingTool'
    $snipDownload = @($snipPlan.DownloadArtifacts) | Select-Object -First 1
    Assert-BloatwareCondition ([string]$snipDownload.Url -eq 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/snippingtool.exe') 'Snipping Tool source URL mismatch.'
    Assert-BloatwareCondition ([string]$snipDownload.Classification -eq 'UltimateAuthorHostedArtifact') 'Snipping Tool must be classified as UltimateAuthorHostedArtifact.'
    Assert-BloatwareCondition ([bool]$snipDownload.NeedsBoostLabMirror) 'Snipping Tool must remain NeedsBoostLabMirror.'
    Assert-BloatwareCondition ($snipPlan.Operations.Type -contains 'AppxRegisterLike') 'Snipping Tool branch must re-register Microsoft.ScreenSketch.'

    foreach ($unsupportedAction in @('Open', 'Default', 'Restore')) {
        $unsupportedResult = Invoke-BoostLabToolAction -ActionName $unsupportedAction
        Assert-BloatwareCondition (-not [bool]$unsupportedResult.Success) "$unsupportedAction must remain unsupported for Bloatware."
        Assert-BloatwareCondition ([string]$unsupportedResult.Status -eq 'UnsupportedAction') "$unsupportedAction must return UnsupportedAction."
        Assert-BloatwareCondition (-not [bool]$unsupportedResult.ChangesExecuted) "$unsupportedAction must execute no changes."
    }

    $noBranchResult = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed $true -SkipEnvironmentChecks $true
    Assert-BloatwareCondition (-not [bool]$noBranchResult.Success) 'Apply without branch should fail closed.'
    Assert-BloatwareCondition ([string]$noBranchResult.Status -eq 'NeedsBranchSelection') 'Apply without branch must return NeedsBranchSelection.'
    Assert-BloatwareCondition (-not [bool]$noBranchResult.ChangesExecuted) 'Apply without branch must execute no changes.'

    $multiBranchResult = Invoke-BoostLabToolAction -ActionName 'Apply' -SelectedAppIds @('InstallStore', 'InstallAllUwpApps') -Confirmed $true -SkipEnvironmentChecks $true
    Assert-BloatwareCondition (-not [bool]$multiBranchResult.Success) 'Apply with multiple branches should fail closed.'
    Assert-BloatwareCondition ([string]$multiBranchResult.Status -eq 'NeedsBranchSelection') 'Apply with multiple branches must return NeedsBranchSelection.'
    Assert-BloatwareCondition (-not [bool]$multiBranchResult.ChangesExecuted) 'Apply with multiple branches must execute no changes.'

    foreach ($expected in $expectedBranches) {
        $mockedBloatwareOperations = [System.Collections.Generic.List[object]]::new()
        $mockExecutor = {
            param($Operation, $Branch, $Plan)
            $mockedBloatwareOperations.Add($Operation)
            [pscustomobject]@{
                Success = $true
                Order = [int]$Operation.Order
                Branch = [string]$Branch
                Category = [string]$Operation.Category
                Type = [string]$Operation.Type
                Label = [string]$Operation.Label
                Message = 'Mocked operation completed.'
                Data = [pscustomobject]@{ PlanBranch = [string]$Plan.Branch }
            }
        }.GetNewClosure()

        $applyResult = Invoke-BoostLabToolAction -ActionName 'Apply' -Branch ([string]$expected.Id) -Confirmed $true -SkipEnvironmentChecks $true -OperationExecutor $mockExecutor
        Assert-BloatwareCondition ([bool]$applyResult.Success) "Mocked Apply should succeed for branch $($expected.Id)."
        Assert-BloatwareCondition ([string]$applyResult.CommandStatus -eq 'Completed') "Mocked Apply must report completed for branch $($expected.Id)."
        Assert-BloatwareCondition ([bool]$applyResult.ChangesExecuted) "Mocked Apply must report changes executed for branch $($expected.Id)."
        $expectedMockCount = [int]$expected['Count'] - 2
        Assert-BloatwareCondition ($mockedBloatwareOperations.Count -eq $expectedMockCount) "Mocked Apply executed the wrong number of operations for branch $($expected.Id)."
        Assert-BloatwareCondition (@($mockedBloatwareOperations | Where-Object { [string]$_.Branch -ne [string]$expected.Id }).Count -eq 0) "Mocked Apply executed a wrong-branch operation for $($expected.Id)."
    }

    $mockedBloatwareOperations = [System.Collections.Generic.List[object]]::new()
    $failingExecutor = {
        param($Operation, $Branch, $Plan)
        $mockedBloatwareOperations.Add($Operation)
        [pscustomobject]@{
            Success = $false
            Order = [int]$Operation.Order
            Branch = [string]$Branch
            Category = [string]$Operation.Category
            Type = [string]$Operation.Type
            Label = [string]$Operation.Label
            Message = 'Mocked operation failed.'
            Data = [pscustomobject]@{ PlanBranch = [string]$Plan.Branch }
        }
    }.GetNewClosure()
    $failedApply = Invoke-BoostLabToolAction -ActionName 'Apply' -Branch 'InstallStore' -Confirmed $true -SkipEnvironmentChecks $true -OperationExecutor $failingExecutor
    Assert-BloatwareCondition (-not [bool]$failedApply.Success) 'Apply must fail closed when a branch operation fails.'
    Assert-BloatwareCondition ([string]$failedApply.Status -eq 'OperationFailed') 'Failed Apply must report OperationFailed.'
    Assert-BloatwareCondition ([string]$failedApply.VerificationStatus -eq 'Failed') 'Failed Apply must report failed verification.'
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
}

$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPolicyPath
Assert-BloatwareCondition (@($artifactPolicy.Artifacts).Count -eq 0) 'Bloatware must not approve artifact provenance entries.'
$productionAllowlist = Import-PowerShellDataFile -LiteralPath $productionAllowlistPath
Assert-BloatwareCondition (@($productionAllowlist.ProductionAllowlistProposals).Count -eq 0) 'Bloatware must not add production allowlist proposals.'

$inventory = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
$bloatwareRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'bloatware' }) | Select-Object -First 1
Assert-BloatwareCondition ($null -ne $bloatwareRecord) 'Bloatware parity record is missing.'
Assert-BloatwareCondition ([string]$bloatwareRecord.RuntimeStatus -eq 'RuntimeImplemented') 'Bloatware must be runtime implemented.'
Assert-BloatwareCondition ([string]$bloatwareRecord.ImplementationLevel -eq 'ParityImplemented') 'Bloatware must be marked ParityImplemented.'
Assert-BloatwareCondition ([string]$bloatwareRecord.UltimateParity -eq 'Yes') 'Bloatware UltimateParity must be Yes.'
Assert-BloatwareCondition ([string]$bloatwareRecord.FinalProgressStatus -eq 'DoneParity') 'Bloatware final progress must be DoneParity.'
Assert-BloatwareCondition (-not [bool]$bloatwareRecord.YazanFinalException) 'Bloatware must not use a Yazan final exception.'
Assert-BloatwareCondition (($bloatwareRecord.ApprovedSourceBranches -join ',') -eq ($expectedParityBranchTitles -join ',')) 'Bloatware parity record must list every approved non-Exit source branch.'
Assert-BloatwareCondition ([string]$parityBaseline.CurrentOrderedParityTarget -eq [string]$nextTarget.ToolId) 'Current ordered parity target must match the derived first non-final target.'
Assert-BloatwareCondition ([string]$bloatwareRecord.FinalProgressStatus -eq 'DoneParity') 'Bloatware must remain accepted before the ordered cursor advances past it.'

$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
foreach ($level in @('ParityImplemented', 'NearParityControlled', 'ControlledSubset', 'ManualHandoffOnly', 'DeferredForParityWork')) {
    $actual = if ($categoryCounts.ContainsKey($level)) { [int]$categoryCounts[$level] } else { 0 }
    $expected = switch ($level) {
        'ParityImplemented' { [int]$parityBaseline.Counts.UltimateParityImplemented }
        'NearParityControlled' { [int]$parityBaseline.Counts.NearParityControlled }
        'ControlledSubset' { [int]$parityBaseline.Counts.ControlledSubset }
        'ManualHandoffOnly' { [int]$parityBaseline.Counts.ManualHandoffOnly }
        'DeferredForParityWork' { [int]$parityBaseline.Counts.DeferredForParityWork }
    }
    Assert-BloatwareCondition ($actual -eq $expected) "Unexpected parity category count for $level."
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
    Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
    Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
    ForEach-Object {
        '{0}|{1}' -f $_.FullName.Substring($root.Length + 1).Replace('\', '/'), (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    }
$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $manifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n")))
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}
Assert-BloatwareCondition (@($sourceLines).Count -eq 49) 'source-ultimate file count changed.'
Assert-BloatwareCondition ($manifestHash -eq '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') 'source-ultimate manifest hash changed.'

foreach ($deletedPath in @(
    'source-ultimate\6 Windows\17 Loudness EQ.ps1',
    'modules\Windows\loudness-eq.psm1',
    'source-ultimate\6 Windows\20 NVME Faster Driver.ps1',
    'modules\Windows\nvme-faster-driver.psm1'
)) {
    Assert-BloatwareCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $deletedPath))) "Deleted tool path was reintroduced: $deletedPath"
}

[pscustomobject]@{
    Success                    = $true
    ToolId                     = 'bloatware'
    SourceHash                 = $actualSourceHash
    BranchCount                = $expectedBranches.Count
    ActiveTools                = [int]$inventory.Snapshot.ActiveTools
    RuntimeImplementedTools    = [int]$inventory.Snapshot.ImplementedTools
    DeferredPlaceholders       = [int]$inventory.Snapshot.DeferredPlaceholders
    CurrentOrderedParityTarget = [string]$parityBaseline.CurrentOrderedParityTarget
    NextOrderedTarget          = [string]$nextTarget.ToolId
    ArtifactApprovals          = @($artifactPolicy.Artifacts).Count
    ProductionAllowlistEntries = @($productionAllowlist.ProductionAllowlistProposals).Count
    SourceUltimateUnchanged    = $true
    DeletedToolsRemainDeleted  = $true
    Message                    = 'Bloatware exact Ultimate parity is implemented through a branch-selected, confirmed, source-equivalent runtime with mocked validator execution.'
    Timestamp                  = Get-Date
}
