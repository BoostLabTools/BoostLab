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
        throw 'Unable to determine the DirectX source-equivalent validator path.'
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

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Graphics\directx.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\5 Graphics\2 DirectX.ps1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$artifactProvenancePath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$externalSourcesPath = Join-Path $ProjectRoot 'config\ExternalArtifactSources.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$migrationPath = Join-Path $ProjectRoot 'docs\migrations\directx.md'
$reviewPath = Join-Path $ProjectRoot 'docs\directx-provenance-review.md'
$parityPath = Join-Path $ProjectRoot 'config\ParityStatusBaseline.psd1'
$orderPath = Join-Path $ProjectRoot 'config\UltimateParityExecutionOrder.psd1'

foreach ($path in @(
    $configPath
    $modulePath
    $sourcePath
    $executionPath
    $actionPlanPath
    $artifactProvenancePath
    $externalSourcesPath
    $productionAllowlistPath
    $migrationPath
    $reviewPath
    $parityPath
    $orderPath
)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required DirectX Phase 129 file missing: $path"
}

$expectedSourceHash = '17051A2F0F7A0CF16BE525121720406E8F1630C94E5977A7CD4C18652A87EE05'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "DirectX source hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."

$sourceText = Get-Content -LiteralPath $sourcePath -Raw
foreach ($needle in @(
    'refs/heads/main/7zip.exe',
    'Start-Process -Wait "$env:SystemRoot\Temp\7zip.exe" -ArgumentList "/S"',
    'HKEY_CURRENT_USER\Software\7-Zip\Options',
    'refs/heads/main/directx.exe',
    'Program Files\7-Zip\7z.exe',
    'DXSETUP.exe'
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
Assert-BoostLabCondition ([string]$directXTool.Type -eq 'action') 'DirectX must be an action tool after Phase 129.'
Assert-BoostLabCondition ((@($directXTool.Actions) -join '|') -eq 'Analyze|Apply') 'DirectX must expose only Analyze and Apply.'
Assert-BoostLabTextContains -Text ([string]$directXTool.Description) -Needle 'Source-equivalent controlled runtime' -Description 'DirectX description'

$capabilities = $directXTool.Capabilities
foreach ($trueCapability in @(
    'RequiresAdmin'
    'RequiresInternet'
    'CanModifyRegistry'
    'CanInstallSoftware'
    'CanDownload'
    'CanDeleteFiles'
    'NeedsExplicitConfirmation'
)) {
    Assert-BoostLabCondition ([bool]$capabilities[$trueCapability]) "DirectX capability should be true: $trueCapability"
}
foreach ($falseCapability in @(
    'CanReboot'
    'CanModifyServices'
    'CanModifyDrivers'
    'CanModifySecurity'
    'UsesTrustedInstaller'
    'UsesSafeMode'
    'SupportsDefault'
    'SupportsRestore'
)) {
    Assert-BoostLabCondition (-not [bool]$capabilities[$falseCapability]) "DirectX capability should be false: $falseCapability"
}

$executionText = Get-Content -LiteralPath $executionPath -Raw
Assert-BoostLabTextContains -Text $executionText -Needle "'directx'" -Description 'Execution registry'
Assert-BoostLabTextContains -Text $executionText -Needle "Graphics\directx.psm1" -Description 'Execution registry'
Assert-BoostLabTextContains -Text $executionText -Needle "Actions = @('Analyze', 'Apply')" -Description 'DirectX execution actions'

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
foreach ($needle in @(
    'Install DirectX using the source-equivalent controlled workflow',
    'Download source-defined 7zip.exe',
    'Run the 7-Zip installer with /S',
    'Write the source-defined 7-Zip HKCU options',
    'Download source-defined directx.exe',
    'Launch %SystemRoot%\Temp\directx\DXSETUP.exe without waiting',
    'Both downloads are Ultimate-author-hosted artifacts marked NeedsBoostLabMirror'
)) {
    Assert-BoostLabTextContains -Text $actionPlanText -Needle $needle -Description 'DirectX Action Plan wording'
}
Assert-BoostLabCondition (-not $actionPlanText.Contains('Auto mode is blocked for DirectX')) 'DirectX Apply Action Plan must not remain blocked Auto wording.'
Assert-BoostLabCondition (-not $actionPlanText.Contains('Prepare DirectX manual handoff instructions only')) 'DirectX Action Plan must not remain manual-handoff wording.'

$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($needle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'')',
    'SourceEquivalentControlledRuntime',
    'SourceEquivalentDirectXInstall',
    'Invoke-BoostLabDirectXOperationPlan',
    'OperationExecutor',
    'RequireAdministrator',
    'RequireInternet',
    'DownloadFile',
    'StartProcessWait',
    'SetRegistryDword',
    'MoveItemSilently',
    'RemoveDirectorySilently',
    'ExtractDirectX',
    'StartProcessNoWait',
    'NeedsBoostLabMirror',
    $expectedSourceHash
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'DirectX module source-equivalent text'
}
Assert-BoostLabCondition (-not $moduleText.Contains('ManualHandoffPrepared')) 'DirectX module must no longer expose ManualHandoffPrepared.'
Assert-BoostLabCondition (-not $moduleText.Contains('AutoBlockedUntilArtifactApproval')) 'DirectX module must no longer block Apply as AutoBlockedUntilArtifactApproval.'

$externalSources = Import-PowerShellDataFile -LiteralPath $externalSourcesPath
$directXExternalSources = @($externalSources.ExternalSources | Where-Object { [string]$_.ToolId -eq 'directx' })
Assert-BoostLabCondition ($directXExternalSources.Count -eq 2) 'DirectX must classify exactly 7zip.exe and directx.exe external sources.'
foreach ($entry in $directXExternalSources) {
    Assert-BoostLabCondition ([string]$entry.SourceClassification -eq 'UltimateAuthorHostedArtifact') "DirectX source classification mismatch for $($entry.Id)."
    Assert-BoostLabCondition ([string]$entry.MirrorStatus -eq 'NeedsBoostLabMirror') "DirectX mirror status mismatch for $($entry.Id)."
    Assert-BoostLabCondition ([string]::IsNullOrWhiteSpace([string]$entry.ExpectedSha256)) "DirectX must not invent artifact hashes for $($entry.Id)."
    Assert-BoostLabCondition ([string]::IsNullOrWhiteSpace([string]$entry.IntendedBoostLabMirrorUrl)) "DirectX must not approve a BoostLab mirror for $($entry.Id)."
}
Assert-BoostLabCondition (@($directXExternalSources | Where-Object { [string]$_.OriginalDownloadUrl -eq 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe' }).Count -eq 1) 'DirectX 7-Zip source URL classification missing.'
Assert-BoostLabCondition (@($directXExternalSources | Where-Object { [string]$_.OriginalDownloadUrl -eq 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/directx.exe' }).Count -eq 1) 'DirectX runtime source URL classification missing.'

$artifactProvenance = Import-PowerShellDataFile -LiteralPath $artifactProvenancePath
Assert-BoostLabCondition (@($artifactProvenance.Artifacts).Count -eq 0) 'Artifact provenance config must remain empty.'
$allowlistText = Get-Content -LiteralPath $productionAllowlistPath -Raw
Assert-BoostLabCondition (-not $allowlistText.Contains('directx')) 'Production allowlist must not approve DirectX.'

$module = Import-Module -Name $modulePath -Force -PassThru -ErrorAction Stop
try {
    $info = Get-BoostLabToolInfo
    Assert-BoostLabCondition ([string]$info.Id -eq 'directx') 'Module info Id mismatch.'
    Assert-BoostLabCondition ((@($info.ImplementedActions) -join '|') -eq 'Analyze|Apply') 'Implemented actions mismatch.'
    Assert-BoostLabCondition ((@($info.ConfirmationRequiredActions) -join '|') -eq 'Apply') 'Confirmation actions mismatch.'

    $analysis = Invoke-BoostLabToolAction -ActionName 'Analyze'
    Assert-BoostLabCondition ([bool]$analysis.Success) 'Analyze should succeed when source checksum matches.'
    Assert-BoostLabCondition ([string]$analysis.Status -eq 'Analyzed') 'Analyze status mismatch.'
    Assert-BoostLabCondition ([string]$analysis.CommandStatus -eq 'No execution performed') 'Analyze must not execute.'
    Assert-BoostLabCondition ([string]$analysis.Data.Mode -eq 'SourceEquivalentControlledRuntime') 'Analyze mode mismatch.'
    Assert-BoostLabCondition ([string]$analysis.Data.Source.ChecksumStatus -eq 'Passed') 'Analyze source checksum mismatch.'
    Assert-BoostLabCondition (@($analysis.Data.OperationPlan.Operations).Count -eq 12) 'Analyze must expose all 12 source-equivalent operations.'
    foreach ($flag in @(
        'NoMutationOccurred',
        'NoDownloadOccurred',
        'NoInstallerExecutionOccurred',
        'NoExternalProcessStarted',
        'NoRegistryMutationOccurred',
        'NoShortcutMutationOccurred',
        'NoFileCleanupOccurred',
        'NoRebootOccurred'
    )) {
        Assert-BoostLabCondition ([bool]$analysis.Data.$flag) "Analyze flag should be true: $flag"
    }

    $cancelled = Invoke-BoostLabToolAction -ActionName 'Apply'
    Assert-BoostLabCondition (-not [bool]$cancelled.Success) 'Unconfirmed Apply should not proceed.'
    Assert-BoostLabCondition ([bool]$cancelled.Cancelled) 'Unconfirmed Apply should be cancelled.'
    Assert-BoostLabCondition (-not [bool]$cancelled.ChangesExecuted) 'Unconfirmed Apply must not execute changes.'

    $seenOperations = New-Object System.Collections.Generic.List[object]
    $mockExecutor = {
        param($Operation, $Plan)
        $seenOperations.Add($Operation) | Out-Null
        $status = if ([string]$Operation.Type -in @('MoveItemSilently', 'RemoveDirectorySilently')) { 'Warning' } else { 'Completed' }
        [pscustomobject]@{
            Success = $true
            Status = $status
            Order = [int]$Operation.Order
            Type = [string]$Operation.Type
            Label = [string]$Operation.Label
            Required = [bool]$Operation.Required
            Message = 'Mocked DirectX operation; no host mutation.'
            Data = $null
            Timestamp = Get-Date
        }
    }.GetNewClosure()

    $apply = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true -OperationExecutor $mockExecutor
    Assert-BoostLabCondition ([bool]$apply.Success) 'Mocked Apply should succeed.'
    Assert-BoostLabCondition ([string]$apply.Status -eq 'CompletedWithWarnings') 'Mocked Apply should surface tolerated source cleanup warnings.'
    Assert-BoostLabCondition ([string]$apply.CommandStatus -eq 'Completed with warnings') 'Mocked Apply command status mismatch.'
    Assert-BoostLabCondition ([string]$apply.VerificationStatus -eq 'Warning') 'Mocked Apply verification status mismatch.'
    Assert-BoostLabCondition ([bool]$apply.ChangesExecuted) 'Mocked Apply should report changes requested.'
    $seenOperationArray = @($seenOperations.ToArray())
    Assert-BoostLabCondition ($seenOperationArray.Count -eq 12) 'Mocked Apply must execute all 12 operation descriptors.'
    Assert-BoostLabCondition (((@($seenOperationArray | ForEach-Object { [int]$_.Order }) -join '|') -eq '1|2|3|4|5|6|7|8|9|10|11|12')) 'DirectX operation order mismatch.'
    Assert-BoostLabCondition (@($seenOperationArray | Where-Object { [string]$_.Type -eq 'DownloadFile' }).Count -eq 2) 'DirectX must have exactly two download operations.'
    Assert-BoostLabCondition (@($seenOperationArray | Where-Object { [string]$_.Type -eq 'SetRegistryDword' }).Count -eq 2) 'DirectX must have exactly two registry DWORD operations.'
    Assert-BoostLabCondition (@($apply.Data.ArtifactSources | Where-Object { [string]$_.MirrorStatus -eq 'NeedsBoostLabMirror' }).Count -eq 2) 'Apply data must report both artifact sources as NeedsBoostLabMirror.'

    $failingExecutor = {
        param($Operation, $Plan)
        [pscustomobject]@{
            Success = [int]$Operation.Order -ne 10
            Status = if ([int]$Operation.Order -eq 10) { 'Failed' } else { 'Completed' }
            Order = [int]$Operation.Order
            Type = [string]$Operation.Type
            Label = [string]$Operation.Label
            Required = [bool]$Operation.Required
            Message = if ([int]$Operation.Order -eq 10) { 'Mock DirectX download failure.' } else { 'Mocked operation.' }
            Data = $null
            Timestamp = Get-Date
        }
    }
    $failedApply = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true -OperationExecutor $failingExecutor
    Assert-BoostLabCondition (-not [bool]$failedApply.Success) 'Apply must fail closed when a required operation fails.'
    Assert-BoostLabCondition ([string]$failedApply.Status -eq 'Failed') 'Failed Apply status mismatch.'
    Assert-BoostLabTextContains -Text ([string]$failedApply.Message) -Needle 'Mock DirectX download failure' -Description 'Failed Apply message'

    $open = Invoke-BoostLabToolAction -ActionName 'Open' -Confirmed:$true
    Assert-BoostLabCondition (-not [bool]$open.Success) 'Open must remain unsupported.'
    Assert-BoostLabCondition ([string]$open.Status -eq 'Unsupported') 'Open unsupported status mismatch.'
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
}

$originalProgramData = $env:ProgramData
$env:ProgramData = Join-Path ([System.IO.Path]::GetTempPath()) 'BoostLabTestProgramData'
$loggingModule = Import-Module -Name (Join-Path $ProjectRoot 'core\Logging.psm1') -Force -PassThru -ErrorAction Stop
$stateModule = Import-Module -Name (Join-Path $ProjectRoot 'core\State.psm1') -Force -PassThru -ErrorAction Stop
Initialize-BoostLabState | Out-Null
function global:Test-BoostLabAdministrator {
    return $true
}
$executionModule = Import-Module -Name $executionPath -Force -PassThru -ErrorAction Stop
try {
    $runtimeAnalyze = Invoke-BoostLabToolAction -ToolMetadata $directXTool -ActionName 'Analyze'
    Assert-BoostLabCondition ([bool]$runtimeAnalyze.Success) 'Runtime Analyze should succeed.'
    Assert-BoostLabTextContains -Text ([string]$runtimeAnalyze.ActionPlan.Summary) -Needle 'source-equivalent install plan' -Description 'Runtime Analyze Action Plan summary'
    Assert-BoostLabCondition (-not [bool]$runtimeAnalyze.ChangesExecuted) 'Runtime Analyze must not execute changes.'

    $runtimeApply = Invoke-BoostLabToolAction -ToolMetadata $directXTool -ActionName 'Apply' -RiskConfirmed -ActionOptions @{
        OperationExecutor = {
            param($Operation, $Plan)
            [pscustomobject]@{
                Success = $true
                Status = 'Completed'
                Order = [int]$Operation.Order
                Type = [string]$Operation.Type
                Label = [string]$Operation.Label
                Required = [bool]$Operation.Required
                Message = 'Runtime mock operation; no host mutation.'
                Data = $null
                Timestamp = Get-Date
            }
        }
        SkipEnvironmentChecks = $true
    }
    Assert-BoostLabCondition ([bool]$runtimeApply.Success) 'Runtime Apply should succeed with mocked executor.'
    Assert-BoostLabCondition ($null -ne $runtimeApply.ActionPlan) 'Runtime Apply should include an Action Plan.'
    Assert-BoostLabTextContains -Text ([string]$runtimeApply.ActionPlan.ConfirmationMessage) -Needle 'install/configure 7-Zip' -Description 'Runtime Apply confirmation'
    Assert-BoostLabCondition (@($runtimeApply.Data.Operations).Count -eq 12) 'Runtime Apply must carry operation results.'
}
finally {
    Remove-Item -Path 'Function:\global:Test-BoostLabAdministrator' -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $executionModule -Force -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $stateModule -Force -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $loggingModule -Force -ErrorAction SilentlyContinue
    $env:ProgramData = $originalProgramData
}

$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$directXRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'directx' })[0]
Assert-BoostLabCondition ([string]$directXRecord.ImplementationLevel -eq 'NearParityControlled') 'DirectX parity level must be NearParityControlled after Phase 129.'
Assert-BoostLabCondition ([string]$directXRecord.FinalProgressStatus -eq 'DoneYazanAcceptedNearParity') 'DirectX final progress status mismatch.'
Assert-BoostLabCondition ([bool]$directXRecord.YazanAcceptedNearParity) 'DirectX must be marked YazanAcceptedNearParity.'
$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq 'graphics-configuration-center') 'Next ordered parity target must advance to Graphics Configuration Center after Visual C++.'
$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
Assert-BoostLabCondition ([int]$categoryCounts['NearParityControlled'] -eq [int]$parityBaseline.Counts.NearParityControlled) 'NearParityControlled count mismatch.'
Assert-BoostLabCondition ([int]$categoryCounts['ManualHandoffOnly'] -eq [int]$parityBaseline.Counts.ManualHandoffOnly) 'ManualHandoffOnly count mismatch.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.NearParityControlled -eq 25) 'NearParityControlled count should be 25 after Visual C++.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.ManualHandoffOnly -eq 1) 'ManualHandoffOnly count should be 1 after Visual C++.'

$inventoryAssertion = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
Assert-BoostLabCondition ([int]$inventoryAssertion.Baseline.ActiveTools -eq 55) 'Active tool count changed unexpectedly.'
Assert-BoostLabCondition ([int]$inventoryAssertion.Baseline.ImplementedTools -eq 45) 'Implemented tool count changed unexpectedly.'
Assert-BoostLabCondition ([int]$inventoryAssertion.Baseline.DeferredPlaceholders -eq 10) 'Deferred placeholder count changed unexpectedly.'

foreach ($deletedPath in @(
    'source-ultimate\6 Windows\17 Loudness EQ.ps1',
    'source-ultimate\6 Windows\30 NVME Faster Driver.ps1'
)) {
    Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $deletedPath))) "Deleted source was reintroduced: $deletedPath"
}

[pscustomobject]@{
    TestName = 'DirectX source-equivalent controlled runtime implementation'
    ActiveTools = $inventoryAssertion.Baseline.ActiveTools
    RuntimeImplementedTools = $inventoryAssertion.Baseline.ImplementedTools
    DeferredPlaceholders = $inventoryAssertion.Baseline.DeferredPlaceholders
    SourceHash = $actualSourceHash
    DirectXActions = @($directXTool.Actions)
    OperationCount = 12
    NextOrderedParityTarget = [string]$nextTarget.ToolId
    RealHostMutationDuringTest = $false
}
