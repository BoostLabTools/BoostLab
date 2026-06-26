[CmdletBinding()]
param(
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'BoostLab.Hashing.ps1')
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $scriptPath = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $PSCommandPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $MyInvocation.MyCommand.Path
    }
    else {
        throw 'Unable to determine the Edge & WebView exact parity validator path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
. (Join-Path $ProjectRoot 'tests\BoostLab.ParityStatusBaseline.ps1')
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

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\edge-webview.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\13 Edge & WebView.ps1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$parityPath = Join-Path $ProjectRoot 'config\ParityStatusBaseline.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$sourcePromotedRoot = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate'
$intakeRoot = Join-Path $ProjectRoot 'intake'

foreach ($path in @($configPath, $modulePath, $sourcePath, $executionPath, $actionPlanPath, $artifactPath, $productionAllowlistPath, $parityPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required Phase 147 file was not found: $path"
}

$expectedSourceHash = '3AB92D76307B1CB4C6988DB2201631C14D3B91B32CFFA4F1177B3E1F4F0D7966'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Edge & WebView source hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."

$sourceText = Get-Content -LiteralPath $sourcePath -Raw
foreach ($needle in @(
    'Write-Host "1. Edge & WebView: Uninstall (Recommended)"',
    'Write-Host "2. Edge & WebView: Default`n"',
    'Test-Connection -ComputerName "8.8.8.8"',
    'MicrosoftEdgeUpdate.exe',
    'Microsoft.MicrosoftEdge_8wekyb3d8bbwe',
    'Microsoft EdgeWebView',
    'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe',
    'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edgewebview.exe',
    'HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist',
    'HKLM:\Software\Microsoft\Active Setup\Installed Components',
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
    'Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}',
    'dism /online /Remove-Package'
)) {
    Assert-BoostLabTextContains -Text $sourceText -Needle $needle -Description 'Edge & WebView Ultimate source behavior'
}

$downloadUrls = @(
    Select-String -LiteralPath $sourcePath -Pattern 'IWR "([^"]+)"' |
        ForEach-Object { $_.Matches[0].Groups[1].Value } |
        Sort-Object -Unique
)
Assert-BoostLabCondition ($downloadUrls.Count -eq 2) "Expected 2 source download URLs, found $($downloadUrls.Count)."

$config = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })
$windowsStage = @($config.Stages | Where-Object { $_.Name -eq 'Windows' })[0]
$edgeTool = @($windowsStage.Tools | Where-Object { $_.Id -eq 'edge-webview' })[0]
Assert-BoostLabCondition ($null -ne $edgeTool) 'Edge & WebView is missing from Windows stage.'
Assert-BoostLabCondition ([string]$edgeTool.Title -eq 'Edge & WebView') 'Edge & WebView title mismatch.'
Assert-BoostLabCondition ([int]$edgeTool.Order -eq 13) 'Edge & WebView must remain Windows order 13.'
Assert-BoostLabCondition ([string]$edgeTool.Type -eq 'action') 'Edge & WebView must be an action tool.'
Assert-BoostLabCondition ([string]$edgeTool.RiskLevel -eq 'high') 'Edge & WebView must be high risk.'
Assert-BoostLabCondition ((@($edgeTool.Actions) -join ',') -eq 'Apply,Default') 'Edge & WebView must expose only source-backed Apply and Default actions.'
Assert-BoostLabTextContains -Text ([string]$edgeTool.Description) -Needle 'source-equivalent Edge and WebView uninstall branch' -Description 'Edge & WebView description'

$capabilities = $edgeTool.Capabilities
foreach ($trueCapability in @(
    'RequiresAdmin',
    'RequiresInternet',
    'CanModifyRegistry',
    'CanModifyServices',
    'CanInstallSoftware',
    'CanDownload',
    'CanModifySecurity',
    'CanDeleteFiles',
    'SupportsDefault',
    'NeedsExplicitConfirmation'
)) {
    Assert-BoostLabCondition ([bool]$capabilities[$trueCapability]) "Edge & WebView exact parity capability should be true: $trueCapability"
}
foreach ($falseCapability in @('CanReboot', 'CanModifyDrivers', 'UsesTrustedInstaller', 'UsesSafeMode', 'SupportsRestore')) {
    Assert-BoostLabCondition (-not [bool]$capabilities[$falseCapability]) "Edge & WebView exact parity capability should be false: $falseCapability"
}

$placeholderModules = @(
    Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
Assert-BoostLabCondition ($allTools.Count -eq $inventoryBaseline.ActiveTools) "Expected $($inventoryBaseline.ActiveTools) active tools, found $($allTools.Count)."
Assert-BoostLabCondition ($placeholderModules.Count -eq $inventoryBaseline.DeferredPlaceholders) "Expected $($inventoryBaseline.DeferredPlaceholders) deferred/placeholders, found $($placeholderModules.Count)."
Assert-BoostLabCondition (($allTools.Count - $placeholderModules.Count) -eq $inventoryBaseline.ImplementedTools) "Expected $($inventoryBaseline.ImplementedTools) implemented tools, found $($allTools.Count - $placeholderModules.Count)."
Assert-BoostLabCondition (-not (@($placeholderModules | ForEach-Object { $_.FullName }) -contains $modulePath)) 'Edge & WebView must no longer be a placeholder module.'

$sourcePromotedFiles = @(Get-ChildItem -LiteralPath $sourcePromotedRoot -Recurse -File)
Assert-BoostLabCondition ($sourcePromotedFiles.Count -eq $inventoryBaseline.SourcePromotedMirrorFiles) "Expected $($inventoryBaseline.SourcePromotedMirrorFiles) source-promoted mirror files, found $($sourcePromotedFiles.Count)."
Assert-BoostLabCondition ($inventoryBaseline.RemainingSourcePromotedIntakeCandidates -eq 0) 'Source-promoted intake candidates should remain resolved.'

$executionText = Get-Content -LiteralPath $executionPath -Raw
foreach ($needle in @(
    "'edge-webview'",
    "Windows\edge-webview.psm1",
    "Actions = @('Apply', 'Default')"
)) {
    Assert-BoostLabTextContains -Text $executionText -Needle $needle -Description 'Execution registry'
}
Assert-BoostLabCondition (-not $executionText.Contains("'edge-webview' = @{`r`n        Path    = Join-Path `$script:BoostLabModulesRoot 'Windows\edge-webview.psm1'`r`n        Actions = @('Analyze', 'Open', 'Apply', 'Default', 'Restore')")) 'Execution registry must not keep the old manual-handoff action list.'

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
Assert-BoostLabTextContains -Text $actionPlanText -Needle "[ValidateSet('Apply', 'Default', 'Open', 'Analyze', 'Restore', 'Off')]" -Description 'Action plan canonical ValidateSet'
Assert-BoostLabCondition (-not $actionPlanText.Contains("'Manual Handoff'")) 'Action plan ValidateSet must not include display label Manual Handoff.'
Assert-BoostLabCondition (-not $actionPlanText.Contains("'Apply Auto'")) 'Action plan ValidateSet must not include display label Apply Auto.'
foreach ($needle in @(
    'Run the source-equivalent Edge & WebView Uninstall (Recommended) branch after explicit confirmation.',
    'Run the source-defined Edge & WebView Default repair branch after explicit confirmation.',
    'Temporarily set DeviceRegion to REG_DWORD 244',
    'Download the source edge.exe and edgewebview.exe Ultimate-author-hosted artifacts',
    'Default is the source repair branch, not captured-state Restore.',
    'Edge & WebView will run the source-equivalent Uninstall (Recommended) branch',
    'Edge & WebView will run the source-defined Default branch'
)) {
    Assert-BoostLabTextContains -Text $actionPlanText -Needle $needle -Description 'Edge & WebView action plan wording'
}
foreach ($forbiddenText in @(
    'Edge & WebView manual handoff',
    'AutoBlockedUntilArtifactApproval',
    'Auto mode is blocked for Edge & WebView',
    'Default is unavailable because the source Default branch',
    'Restore is unavailable because no captured Edge/WebView'
)) {
    Assert-BoostLabCondition (-not $actionPlanText.Contains($forbiddenText)) "Edge & WebView action plan must not retain old blocked/manual wording: $forbiddenText"
}

$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($needle in @(
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')',
    $expectedSourceHash,
    'Get-BoostLabEdgeWebViewUninstallOperations',
    'Get-BoostLabEdgeWebViewDefaultOperations',
    'Invoke-BoostLabEdgeWebViewWorkflow',
    'Microsoft.MicrosoftEdge_8wekyb3d8bbwe',
    'Microsoft EdgeWebView',
    'MicrosoftEdgeUpdate.exe',
    'HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist',
    'dism.exe /online /Remove-Package',
    'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe',
    'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edgewebview.exe'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'Edge & WebView module text'
}
Assert-BoostLabCondition (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) 'Edge & WebView module must not use placeholder contract.'
foreach ($forbiddenText in @('ManualHandoffOnly', 'ManualHandoffPrepared', 'Apply Auto')) {
    Assert-BoostLabCondition (-not $moduleText.Contains($forbiddenText)) "Edge & WebView module must not retain old manual handoff text: $forbiddenText"
}

$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPath
$allowlistPolicy = Import-PowerShellDataFile -LiteralPath $productionAllowlistPath
Assert-BoostLabCondition (@($artifactPolicy.Artifacts).Count -eq 0) 'Artifact provenance config must not approve Edge & WebView artifacts.'
Assert-BoostLabCondition (@($allowlistPolicy.ProductionAllowlistProposals).Count -eq 0) 'Production allowlist config must not approve Edge & WebView scopes.'

$parity = Import-PowerShellDataFile -LiteralPath $parityPath
$edgeParity = @($parity.Tools | Where-Object { $_.ToolId -eq 'edge-webview' })[0]
$nextParityTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parity -ExecutionOrder (Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot)
Assert-BoostLabCondition ([string]$parity.CurrentOrderedParityTarget -eq [string]$nextParityTarget.ToolId) 'Ordered parity cursor should match the derived first non-final target.'
Assert-BoostLabCondition ([string]$parity.CurrentOrderedParityTarget -ne 'edge-webview') 'Ordered parity cursor should remain advanced beyond Edge & WebView.'
Assert-BoostLabCondition ([string]$edgeParity.ImplementationLevel -eq 'ParityImplemented') 'Edge & WebView should be marked ParityImplemented.'
Assert-BoostLabCondition ([string]$edgeParity.UltimateParity -eq 'Yes') 'Edge & WebView UltimateParity should be Yes.'
Assert-BoostLabCondition ([string]$edgeParity.FinalProgressStatus -eq 'DoneParity') 'Edge & WebView FinalProgressStatus should be DoneParity.'
Assert-BoostLabCondition ([string]$edgeParity.NextParityAction -eq 'DoneParity') 'Edge & WebView NextParityAction should be DoneParity.'

$module = Import-Module -Name $modulePath -Force -PassThru -Scope Local
try {
    $info = & $module { Get-BoostLabToolInfo }
    Assert-BoostLabCondition ([string]$info.Id -eq 'edge-webview') 'Module info Id mismatch.'
    Assert-BoostLabCondition ((@($info.Actions) -join ',') -eq 'Apply,Default') 'Module info actions mismatch.'
    Assert-BoostLabCondition ('Apply' -in @($info.ConfirmationRequiredActions)) 'Apply should require confirmation.'
    Assert-BoostLabCondition ('Default' -in @($info.ConfirmationRequiredActions)) 'Default should require confirmation.'

    $state = & $module { Get-BoostLabToolState }
    Assert-BoostLabCondition ([string]$state.Status -eq 'SourceEquivalentControlled') 'Tool state should report source-equivalent controlled status.'

    $compat = & $module { Test-BoostLabToolCompatibility }
    Assert-BoostLabCondition ([bool]$compat.Supported) 'Compatibility should pass when source checksum matches.'
    Assert-BoostLabCondition ([string]$compat.SourceChecksumStatus -eq 'Passed') 'Compatibility source checksum should pass.'

    $sourceStatus = & $module { Get-BoostLabEdgeWebViewSourceStatus }
    Assert-BoostLabCondition ([string]$sourceStatus.ChecksumStatus -eq 'Passed') 'Source status should accept raw or canonical Edge & WebView checksum verification.'
    Assert-BoostLabCondition ([string]$sourceStatus.ExpectedCanonicalSha256 -eq '3AB92D76307B1CB4C6988DB2201631C14D3B91B32CFFA4F1177B3E1F4F0D7966') 'Edge & WebView canonical source SHA should remain configured.'
    Assert-BoostLabCondition ([string]$sourceStatus.VerificationMode -in @('ExactRawSha256', 'CanonicalTextSha256')) 'Edge & WebView source verification should report a supported raw or canonical mode.'

    $applyPlan = & $module { Get-BoostLabEdgeWebViewOperationPlan -ActionName 'Apply' }
    Assert-BoostLabCondition ([string]$applyPlan.UltimateBranch -eq 'Edge & WebView: Uninstall (Recommended)') 'Apply should map to the source Uninstall branch.'
    Assert-BoostLabCondition ($applyPlan.OperationCount -ge 20) 'Apply operation plan should preserve the full high-risk source sequence.'
    foreach ($operationKind in @('RequireAdministrator', 'RequireInternet', 'ReadRegistryValue', 'CopyRegExe', 'RegExeAdd', 'StopNamedProcesses', 'StopWildcardEdgeProcesses', 'FindEdgeUpdateExecutables', 'RemoveRegistryKeys', 'RunEdgeUpdateExecutableForEachPath', 'NewDirectory', 'NewFile', 'ReadEdgeUninstallString32', 'RunEdgeUninstallString', 'RemoveDirectory', 'RemoveFile', 'DeleteEdgeServices', 'FindLegacyEdgePackage', 'RemoveLegacyEdgePackageIfPresent', 'RestoreDeviceRegion')) {
        Assert-BoostLabCondition ($operationKind -in @($applyPlan.Operations.Kind)) "Apply operation plan missing kind: $operationKind"
    }

    $defaultPlan = & $module { Get-BoostLabEdgeWebViewOperationPlan -ActionName 'Default' }
    Assert-BoostLabCondition ([string]$defaultPlan.UltimateBranch -eq 'Edge & WebView: Default') 'Default should map to the source Default branch.'
    Assert-BoostLabCondition (@($defaultPlan.Downloads).Count -eq 2) 'Default should preserve the two source downloads.'
    Assert-BoostLabCondition (@($defaultPlan.Operations | Where-Object { $_.Kind -eq 'StartProcess' }).Count -eq 2) 'Default should launch two source repair executables.'
    foreach ($uri in @(
        'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe',
        'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edgewebview.exe'
    )) {
        Assert-BoostLabCondition ($uri -in @($defaultPlan.Downloads.Parameters.Uri)) "Default download missing source URL: $uri"
    }

    $mockExecutor = {
        param($Operation, $Context)

        if ([string]$Operation.Id -eq 'CaptureDeviceRegion') {
            $Context['DeviceRegion'] = 244
        }
        elseif ([string]$Operation.Id -eq 'FindEdgeUpdateExecutables') {
            $Context['EdgeUpdateExecutables'] = @([pscustomobject]@{ FullName = 'C:\Mock\Microsoft\EdgeUpdate\1.2.3.4\MicrosoftEdgeUpdate.exe' })
        }
        elseif ([string]$Operation.Id -eq 'ReadEdgeUninstallString') {
            $Context['EdgeUninstallString'] = '"C:\Mock\Microsoft\Edge\Application\setup.exe"'
        }
        elseif ([string]$Operation.Id -eq 'FindLegacyEdgePackage') {
            $Context['LegacyEdgePackage'] = [pscustomobject]@{
                Name = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\Microsoft-Windows-Internet-Browser-Package~mock'
                PSChildName = 'Microsoft-Windows-Internet-Browser-Package~mock'
            }
        }
    }

    $applyCancelled = & $module { Invoke-BoostLabToolAction -ActionName 'Apply' }
    Assert-BoostLabCondition (-not [bool]$applyCancelled.Success) 'Unconfirmed Apply should not succeed.'
    Assert-BoostLabCondition ([bool]$applyCancelled.Cancelled) 'Unconfirmed Apply should be cancelled.'
    Assert-BoostLabCondition (-not [bool]$applyCancelled.ChangesExecuted) 'Unconfirmed Apply must not execute changes.'

    $apply = & $module { param($Executor) Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed $true -OperationExecutor $Executor } $mockExecutor
    Assert-BoostLabCondition ([bool]$apply.Success) 'Mocked Apply should succeed.'
    Assert-BoostLabCondition ([string]$apply.Status -eq 'Completed') 'Apply status mismatch.'
    Assert-BoostLabCondition ([bool]$apply.ChangesExecuted) 'Apply should report changes executed after mocked source workflow.'
    Assert-BoostLabCondition ($null -ne $apply.Plan) 'Apply result must expose the Edge & WebView plan contract at top level.'
    Assert-BoostLabCondition ($null -ne $apply.Data.Plan) 'Apply result data must include the Edge & WebView workflow plan.'
    Assert-BoostLabCondition (@($apply.Data.ExecutedOperations).Count -eq [int]$apply.Data.Plan.OperationCount) 'Apply must execute every planned source operation.'
    Assert-BoostLabCondition (@($apply.Data.OperationOutcomes).Count -eq [int]$apply.Data.Plan.OperationCount) 'Apply must report one operation outcome per planned source operation.'
    Assert-BoostLabCondition ('DeviceRegion' -in @($apply.Data.ContextKeys)) 'Apply should preserve DeviceRegion capture/restore context.'

    $noisyExecutor = {
        param($Operation, $Context)

        [pscustomobject]@{
            OperationId = [string]$Operation.Id
            Diagnostic  = 'mock operation pipeline output'
        }
    }
    $noisyApply = & $module { param($Executor) Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed $true -OperationExecutor $Executor } $noisyExecutor
    Assert-BoostLabCondition ([bool]$noisyApply.Success) 'Mocked Apply should succeed when operation helpers emit pipeline output.'
    Assert-BoostLabCondition ($null -ne $noisyApply.Plan) 'Noisy Apply result must still expose the top-level plan contract.'
    Assert-BoostLabCondition ($null -ne $noisyApply.Data.Plan) 'Noisy Apply result data must still be a workflow object with a Plan property.'
    Assert-BoostLabCondition (@($noisyApply.Data.OperationOutcomes | Where-Object { $_.OutputCount -gt 0 }).Count -eq [int]$noisyApply.Data.Plan.OperationCount) 'Noisy operation output should be captured as operation diagnostics instead of replacing the workflow object.'
    Assert-BoostLabCondition (-not ([string]$noisyApply.Message).Contains("The property 'Plan' cannot be found")) 'Noisy Apply must not fail with a missing Plan property.'

    $failingExecutor = {
        param($Operation, $Context)

        throw 'Mock Edge & WebView operation failure'
    }
    $failedApply = & $module { param($Executor) Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed $true -OperationExecutor $Executor } $failingExecutor
    Assert-BoostLabCondition (-not [bool]$failedApply.Success) 'A real mocked operation failure must still fail.'
    Assert-BoostLabCondition ([string]$failedApply.Status -eq 'Error') 'Operation failure should return Error status.'
    Assert-BoostLabTextContains -Text ([string]$failedApply.Message) -Needle 'Mock Edge & WebView operation failure' -Description 'Operation failure result'
    Assert-BoostLabCondition ($null -ne $failedApply.Plan) 'Failed Apply should still expose the planned operation contract for diagnostics.'

    $default = & $module { param($Executor) Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed $true -OperationExecutor $Executor } $mockExecutor
    Assert-BoostLabCondition ([bool]$default.Success) 'Mocked Default should succeed.'
    Assert-BoostLabCondition ([string]$default.Status -eq 'Completed') 'Default status mismatch.'
    Assert-BoostLabCondition ([bool]$default.ChangesExecuted) 'Default should report changes executed after mocked source workflow.'
    Assert-BoostLabCondition ($null -ne $default.Plan) 'Default result must expose the Edge & WebView plan contract at top level.'
    Assert-BoostLabCondition (@($default.Data.ExecutedOperations).Count -eq [int]$default.Data.Plan.OperationCount) 'Default must execute every planned source operation.'

    $open = & $module { Invoke-BoostLabToolAction -ActionName 'Open' -Confirmed $true }
    Assert-BoostLabCondition (-not [bool]$open.Success) 'Open should not be supported because the source has no Open branch.'
    Assert-BoostLabCondition ([string]$open.Status -eq 'Unsupported') 'Open unsupported status mismatch.'

    $restore = & $module { Invoke-BoostLabToolAction -ActionName 'Restore' -Confirmed $true }
    Assert-BoostLabCondition (-not [bool]$restore.Success) 'Restore should not be supported because the source has no captured-state Restore branch.'
    Assert-BoostLabCondition ([string]$restore.Status -eq 'Unsupported') 'Restore unsupported status mismatch.'
}
finally {
    Remove-Module $module -Force -ErrorAction SilentlyContinue
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local
try {
    $runtimeApply = & $actionPlanModule { New-BoostLabActionPlan -ToolMetadata $args[0] -ActionName 'Apply' } $edgeTool
    $runtimeApplyText = (@($runtimeApply.PlannedChanges) + @($runtimeApply.SideEffects) + @($runtimeApply.ConfirmationMessage) -join "`n")
    foreach ($needle in @(
        'Verify the Edge & WebView source checksum before execution.',
        'Temporarily set DeviceRegion to REG_DWORD 244',
        'Stop the exact source-defined named process list',
        'Remove the exact source EdgeUpdate registry keys',
        'If the Windows 10 legacy Edge CBS package exists',
        'Require BoostLab to be running in an elevated Administrator process.',
        'The requested action may fail when internet access is unavailable.'
    )) {
        Assert-BoostLabTextContains -Text $runtimeApplyText -Needle $needle -Description 'Runtime Apply Action Plan'
    }
    Assert-BoostLabCondition (-not $runtimeApplyText.Contains('Auto mode is blocked')) 'Runtime Apply plan must not use old blocked wording.'

    $runtimeDefault = & $actionPlanModule { New-BoostLabActionPlan -ToolMetadata $args[0] -ActionName 'Default' } $edgeTool
    $runtimeDefaultText = (@($runtimeDefault.PlannedChanges) + @($runtimeDefault.SideEffects) + @($runtimeDefault.ConfirmationMessage) -join "`n")
    foreach ($needle in @(
        'Download the source edge.exe and edgewebview.exe Ultimate-author-hosted artifacts',
        'Write the source Edge policies',
        'Remove source-matched Edge Active Setup components',
        'Default is the source repair branch, not captured-state Restore.',
        'Default is not captured-state Restore.'
    )) {
        Assert-BoostLabTextContains -Text $runtimeDefaultText -Needle $needle -Description 'Runtime Default Action Plan'
    }
    Assert-BoostLabCondition (-not $runtimeDefaultText.Contains('Default is unavailable')) 'Runtime Default plan must not use old unavailable wording.'
}
finally {
    Remove-Module $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$intakeFiles = @(Get-ChildItem -LiteralPath $intakeRoot -Recurse -File -ErrorAction SilentlyContinue)
Assert-BoostLabCondition ($intakeFiles.Count -ge $inventoryBaseline.SourcePromotedMirrorFiles) 'Intake files unexpectedly changed or disappeared.'

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceManifestLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
    Sort-Object {
        $_.FullName.Substring($root.Length + 1).Replace('\', '/')
    } |
    ForEach-Object {
        '{0}|{1}' -f `
            $_.FullName.Substring($root.Length + 1).Replace('\', '/'), `
            (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    }
$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $sourceManifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash(
            [Text.Encoding]::UTF8.GetBytes(($sourceManifestLines -join "`n"))
        )
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}
Assert-BoostLabCondition (@($sourceManifestLines).Count -eq 49) "source-ultimate file count changed: $(@($sourceManifestLines).Count)"
Assert-BoostLabCondition ($sourceManifestHash -eq 'B07E015D5BA32E9CF4DBC1804597311D8A41CE7FA537C0091914056BEF06FFF4') 'source-ultimate content or paths changed.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }).Count -eq 0) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    TestName                                       = 'Edge & WebView exact Ultimate parity implementation'
    ActiveTools                                    = $inventoryBaseline.ActiveTools
    ImplementedTools                               = $inventoryBaseline.ImplementedTools
    DeferredPlaceholders                           = $inventoryBaseline.DeferredPlaceholders
    SourcePromotedMirrorFiles                      = $inventoryBaseline.SourcePromotedMirrorFiles
    RemainingUnimplementedSourcePromotedCandidates = $inventoryBaseline.RemainingSourcePromotedIntakeCandidates
    SourceHash                                     = $actualSourceHash
    EdgeWebViewActions                             = @($edgeTool.Actions)
    ApplyOperationCount                            = $applyPlan.OperationCount
    DefaultOperationCount                          = $defaultPlan.OperationCount
}
