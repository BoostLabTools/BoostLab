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
        throw 'Unable to determine the GameBar validator script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
. (Join-Path $ProjectRoot 'tests\BoostLab.ParityStatusBaseline.ps1')

function Assert-GameBarCondition {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\12 Gamebar.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\game-bar.psm1'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$artifactProvenancePath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'

$expectedSourceHash = '8C6703E68C251D63ADD81A87B7CB6C1F572A4CE55A1E092C33B9B444A9884E59'
Assert-GameBarCondition (Test-Path -LiteralPath $sourcePath -PathType Leaf) 'GameBar Ultimate source file is missing.'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-GameBarCondition ($actualSourceHash -eq $expectedSourceHash) "GameBar source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."

$sourceText = Get-Content -LiteralPath $sourcePath -Raw
foreach ($requiredSourceText in @(
    'Gamebar Xbox: Off (Recommended)',
    'Gamebar Xbox: Default',
    'Stop-Process -Force -Name GameBar',
    'Get-AppXPackage -AllUsers',
    'Remove-AppxPackage',
    'GameInputSvc',
    'Microsoft GameInput',
    'msiexec.exe',
    'gamebaroff.reg',
    'gamebaron.reg',
    'HKEY_CURRENT_USER\Software\Microsoft\GameBar',
    'ms-gamebar',
    'ms-gamebarservices',
    'ms-gamingoverlay',
    'PresenceServer.Internal.PresenceWriter',
    'Run-Trusted',
    'edgewebview.exe',
    'gamingrepairtool.exe'
)) {
    Assert-GameBarCondition ($sourceText.Contains($requiredSourceText)) "GameBar source is missing expected source-backed behavior: $requiredSourceText"
}
Assert-GameBarCondition (-not ($sourceText -match 'Restart-Computer|shutdown\.exe|bcdedit')) 'GameBar source unexpectedly contains direct reboot or BCD behavior.'

$moduleText = Get-Content -LiteralPath $modulePath -Raw
Assert-GameBarCondition (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) 'GameBar module must not use the placeholder implementation.'
foreach ($requiredModuleText in @(
    '$script:BoostLabExpectedSourceHash',
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')',
    'Get-BoostLabGameBarOperationPlan',
    'Invoke-BoostLabGameBarBranchWorkflow',
    'Invoke-BoostLabGameBarTrustedInstallerCommand',
    'UltimateAuthorHostedArtifact',
    'NeedsBoostLabMirror = $true',
    'RestoreSupported          = $false'
)) {
    Assert-GameBarCondition ($moduleText.Contains($requiredModuleText)) "GameBar module is missing expected implementation text: $requiredModuleText"
}

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$gameBarStageEntry = @($stages.Stages | ForEach-Object { $_.Tools } | Where-Object { $_.Id -eq 'game-bar' }) | Select-Object -First 1
Assert-GameBarCondition ($null -ne $gameBarStageEntry) 'GameBar stage entry was not found.'
Assert-GameBarCondition ([string]$gameBarStageEntry.RiskLevel -eq 'high') 'GameBar risk level must be high.'
Assert-GameBarCondition ((@($gameBarStageEntry.Actions) -join ',') -eq 'Apply,Default') 'GameBar actions must be Apply and Default only.'
Assert-GameBarCondition ([bool]$gameBarStageEntry.Capabilities.RequiresAdmin) 'GameBar must require Administrator.'
Assert-GameBarCondition ([bool]$gameBarStageEntry.Capabilities.RequiresInternet) 'GameBar must require internet.'
Assert-GameBarCondition ([bool]$gameBarStageEntry.Capabilities.CanModifyRegistry) 'GameBar must declare registry capability.'
Assert-GameBarCondition ([bool]$gameBarStageEntry.Capabilities.CanModifyServices) 'GameBar must declare service capability.'
Assert-GameBarCondition ([bool]$gameBarStageEntry.Capabilities.CanInstallSoftware) 'GameBar must declare software install/repair capability.'
Assert-GameBarCondition ([bool]$gameBarStageEntry.Capabilities.CanDownload) 'GameBar must declare download capability.'
Assert-GameBarCondition ([bool]$gameBarStageEntry.Capabilities.CanModifySecurity) 'GameBar must declare security/protected registration capability.'
Assert-GameBarCondition ([bool]$gameBarStageEntry.Capabilities.UsesTrustedInstaller) 'GameBar must declare TrustedInstaller usage.'
Assert-GameBarCondition ([bool]$gameBarStageEntry.Capabilities.SupportsDefault) 'GameBar must support source-defined Default.'
Assert-GameBarCondition (-not [bool]$gameBarStageEntry.Capabilities.SupportsRestore) 'GameBar must not claim captured-state Restore support.'
Assert-GameBarCondition ([bool]$gameBarStageEntry.Capabilities.NeedsExplicitConfirmation) 'GameBar must require explicit confirmation.'

$executionText = Get-Content -LiteralPath $executionPath -Raw
Assert-GameBarCondition ($executionText.Contains("'game-bar' = @{")) 'GameBar must be registered as an implemented runtime module.'
Assert-GameBarCondition ($executionText.Contains("Path    = Join-Path `$script:BoostLabModulesRoot 'Windows\game-bar.psm1'")) 'GameBar runtime module path is not registered.'
Assert-GameBarCondition ($executionText.Contains("Actions = @('Apply', 'Default')")) 'GameBar runtime actions are not registered as Apply/Default.'

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
foreach ($requiredPlanText in @(
    'Gamebar Xbox Off (Recommended)',
    'Gamebar Xbox Default repair',
    'all-users AppX packages where Name matches *Gaming* or *Xbox*',
    'source TrustedInstaller PresenceWriter registry command',
    'edgewebview.exe and gamingrepairtool.exe',
    'Default is not captured-state Restore'
)) {
    Assert-GameBarCondition ($actionPlanText.Contains($requiredPlanText)) "GameBar Action Plan is missing expected wording: $requiredPlanText"
}

$module = Import-Module -Name $modulePath -Force -PassThru
try {
    $info = Get-BoostLabToolInfo
    Assert-GameBarCondition ([string]$info.Id -eq 'game-bar') 'GameBar module exported the wrong tool id.'
    Assert-GameBarCondition ([string]$info.RiskLevel -eq 'high') 'GameBar module metadata risk level must be high.'
    Assert-GameBarCondition ((@($info.ImplementedActions) -join ',') -eq 'Apply,Default') 'GameBar implemented action list must be Apply/Default.'

    $compatibility = Test-BoostLabToolCompatibility
    Assert-GameBarCondition ([bool]$compatibility.Supported) 'GameBar compatibility must pass when source checksum matches.'
    Assert-GameBarCondition ([string]$compatibility.Source.ActualSHA256 -eq $expectedSourceHash) 'GameBar compatibility did not report the expected source hash.'

    $analysis = Get-BoostLabToolState
    Assert-GameBarCondition ([bool]$analysis.NoMutationOccurred) 'GameBar analysis must be read-only.'
    Assert-GameBarCondition ([bool]$analysis.NoDownloadOccurred) 'GameBar analysis must not download.'
    Assert-GameBarCondition ([bool]$analysis.NoExternalProcessStarted) 'GameBar analysis must not start external processes.'
    Assert-GameBarCondition (-not [bool]$analysis.OpenSupported) 'GameBar must not expose Open.'
    Assert-GameBarCondition (-not [bool]$analysis.RestoreSupported) 'GameBar must not expose Restore.'

    $offPlan = Get-BoostLabGameBarOperationPlan -Branch OffRecommended
    $defaultPlan = Get-BoostLabGameBarOperationPlan -Branch Default
    Assert-GameBarCondition ([string]$offPlan.SourceBranchLabel -eq 'Gamebar Xbox: Off (Recommended)') 'Apply must map to the source Off branch.'
    Assert-GameBarCondition ([string]$defaultPlan.SourceBranchLabel -eq 'Gamebar Xbox: Default') 'Default must map to the source Default branch.'
    Assert-GameBarCondition ([int]$offPlan.OperationCount -eq 13) "GameBar Off branch operation count changed: $($offPlan.OperationCount)"
    Assert-GameBarCondition ([int]$defaultPlan.OperationCount -eq 10) "GameBar Default branch operation count changed: $($defaultPlan.OperationCount)"

    foreach ($operationType in @('RequireAdministrator', 'RequireInternet', 'StopProcess', 'RemoveAppxWhereNameLike', 'Cmd', 'StopProcesses', 'Sleep', 'MsiUninstallByDisplayName', 'SetContent', 'ImportRegFile', 'TrustedInstallerCommand')) {
        Assert-GameBarCondition ($operationType -in @($offPlan.Operations.OperationType)) "GameBar Off plan is missing operation type: $operationType"
    }
    foreach ($operationType in @('RequireAdministrator', 'RequireInternet', 'SetContent', 'ImportRegFile', 'TrustedInstallerCommand', 'AppxRegisterWhereNameLike', 'DownloadFile', 'StartProcess')) {
        Assert-GameBarCondition ($operationType -in @($defaultPlan.Operations.OperationType)) "GameBar Default plan is missing operation type: $operationType"
    }

    $removeAppxOperation = @($offPlan.Operations | Where-Object { [string]$_.OperationType -eq 'RemoveAppxWhereNameLike' }) | Select-Object -First 1
    Assert-GameBarCondition ($null -ne $removeAppxOperation) 'GameBar Off plan must include RemoveAppxWhereNameLike.'
    $gameBarAppxPatterns = @($removeAppxOperation.Parameters.Patterns)
    Assert-GameBarCondition (($gameBarAppxPatterns -join ',') -eq '*Gaming*,*Xbox*') 'GameBar AppX removal patterns must preserve the Ultimate source *Gaming* and *Xbox* filters exactly.'

    $emptyAppxResult = Invoke-BoostLabGameBarRemoveAppxWhereNameLike `
        -Patterns $gameBarAppxPatterns `
        -AppxGetter { @() } `
        -AppxRemover { throw 'Remover should not be called for an empty package list.' }
    Assert-GameBarCondition ([bool]$emptyAppxResult.Success) 'GameBar AppX removal must succeed for an empty mock package list.'
    Assert-GameBarCondition ([int]$emptyAppxResult.TotalPackages -eq 0) 'GameBar empty mock package list should report zero packages.'
    Assert-GameBarCondition (@($emptyAppxResult.MatchedPackages).Count -eq 0) 'GameBar empty mock package list should match no packages.'

    $mockGameBarPackages = @(
        [pscustomobject]@{ Name = 'Microsoft.GamingApp'; PackageFullName = 'Microsoft.GamingApp_1'; PackageFamilyName = 'Microsoft.GamingApp_family'; User = 'S-1-1'; InstallLocation = 'C:\Mock\Gaming' }
        [pscustomobject]@{ Name = 'Microsoft.XboxGamingOverlay'; PackageFullName = 'Microsoft.XboxGamingOverlay_1'; PackageFamilyName = 'Microsoft.XboxGamingOverlay_family'; User = 'S-1-2'; InstallLocation = 'C:\Mock\Xbox' }
        [pscustomobject]@{ Name = 'Microsoft.Notepad'; PackageFullName = 'Microsoft.Notepad_1'; PackageFamilyName = 'Microsoft.Notepad_family'; User = 'S-1-3'; InstallLocation = 'C:\Mock\Notepad' }
    )
    $removedGameBarPackages = [System.Collections.Generic.List[string]]::new()
    $mockAppxResult = Invoke-BoostLabGameBarRemoveAppxWhereNameLike `
        -Patterns $gameBarAppxPatterns `
        -AppxGetter { $mockGameBarPackages }.GetNewClosure() `
        -AppxRemover { param($Package) $removedGameBarPackages.Add([string]$Package.PackageFullName) }.GetNewClosure()
    Assert-GameBarCondition ([bool]$mockAppxResult.Success) 'GameBar AppX removal must succeed when all matching mock packages are removed.'
    Assert-GameBarCondition (@($mockAppxResult.MatchedPackages).Count -eq 2) 'GameBar AppX removal must match only Gaming/Xbox mock packages.'
    Assert-GameBarCondition (@($mockAppxResult.SkippedPackages).Count -eq 1) 'GameBar AppX removal must skip non-matching packages.'
    Assert-GameBarCondition (($removedGameBarPackages.ToArray() -join ',') -eq 'Microsoft.GamingApp_1,Microsoft.XboxGamingOverlay_1') 'GameBar AppX removal must remove matching packages one-by-one.'
    Assert-GameBarCondition (($mockAppxResult.PackageOutcomes.Outcome -join ',') -eq 'Removed,Removed,SkippedExcluded') 'GameBar AppX removal must report removed and skipped outcome categories.'

    $pipeWarningResult = Invoke-BoostLabGameBarRemoveAppxWhereNameLike `
        -Patterns $gameBarAppxPatterns `
        -AppxGetter { @([pscustomobject]@{ Name = 'Microsoft.GamingPipe'; PackageFullName = 'Microsoft.GamingPipe_1'; PackageFamilyName = 'Microsoft.GamingPipe_family'; User = 'S-1-4'; InstallLocation = 'C:\Mock\Pipe' }) } `
        -AppxRemover { throw 'The Win32 internal error "No process is on the other end of the pipe" 0xE9 occurred while getting console output buffer information.' }
    Assert-GameBarCondition ([bool]$pipeWarningResult.Success) 'GameBar AppX removal must not hard-fail on console/progress pipe output warnings alone.'
    Assert-GameBarCondition (@($pipeWarningResult.ConsolePipeWarnings).Count -eq 1) 'GameBar AppX removal must report console/progress pipe warnings.'
    Assert-GameBarCondition (@($pipeWarningResult.FailedPackages).Count -eq 0) 'GameBar AppX removal must not classify console/progress pipe warnings as real package failures.'

    $callableUiResult = Invoke-BoostLabGameBarRemoveAppxWhereNameLike `
        -Patterns $gameBarAppxPatterns `
        -AppxGetter { @([pscustomobject]@{ Name = 'Microsoft.XboxGameCallableUI'; PackageFullName = 'Microsoft.XboxGameCallableUI_1'; PackageFamilyName = 'Microsoft.XboxGameCallableUI_family'; User = 'S-1-6'; InstallLocation = 'C:\Windows\SystemApps\Microsoft.XboxGameCallableUI' }) } `
        -AppxRemover { throw 'Remove-AppxPackage failed with HRESULT 0x80073CFA, error 0x80070032: This app is part of Windows and cannot be uninstalled on a per-user basis.' }
    Assert-GameBarCondition ([bool]$callableUiResult.Success) 'Microsoft.XboxGameCallableUI protected removal failure must be reported as a skip, not an error.'
    Assert-GameBarCondition (@($callableUiResult.MatchedPackages).Count -eq 1) 'Microsoft.XboxGameCallableUI must still be recognized as a source-matching Xbox package.'
    Assert-GameBarCondition (@($callableUiResult.RemovedPackages).Count -eq 0) 'Microsoft.XboxGameCallableUI must not be reported as removed when Windows protects it.'
    Assert-GameBarCondition (@($callableUiResult.ProtectedSystemAppSkippedPackages).Count -eq 1) 'Microsoft.XboxGameCallableUI protected skip must be counted.'
    Assert-GameBarCondition ([string]$callableUiResult.ProtectedSystemAppSkippedPackages[0].Package.PackageFullName -eq 'Microsoft.XboxGameCallableUI_1') 'Microsoft.XboxGameCallableUI protected skip must include PackageFullName.'
    Assert-GameBarCondition ([string]$callableUiResult.ProtectedSystemAppSkippedPackages[0].Outcome -eq 'SkippedProtectedSystemApp') 'Microsoft.XboxGameCallableUI protected skip must use the SkippedProtectedSystemApp outcome.'

    $dependencyGameBarResult = Invoke-BoostLabGameBarRemoveAppxWhereNameLike `
        -Patterns $gameBarAppxPatterns `
        -AppxGetter { @([pscustomobject]@{ Name = 'Microsoft.XboxFramework'; PackageFullName = 'Microsoft.XboxFramework_1'; PackageFamilyName = 'Microsoft.XboxFramework_family'; User = 'S-1-7'; InstallLocation = 'C:\Windows\SystemApps\XboxFramework' }) } `
        -AppxRemover { throw 'Remove-AppxPackage failed with HRESULT 0x80073CF3: package dependency/conflict validation failed because dependent packages remain installed.' }
    Assert-GameBarCondition ([bool]$dependencyGameBarResult.Success) 'GameBar dependency/framework AppX failures must be reported as skips, not hard errors.'
    Assert-GameBarCondition (@($dependencyGameBarResult.DependencyFrameworkSkippedPackages).Count -eq 1) 'GameBar dependency/framework skip must be counted.'
    Assert-GameBarCondition (@($dependencyGameBarResult.FailedPackages).Count -eq 0) 'GameBar dependency/framework skip must not be counted as an unexpected failure.'

    $realAppxFailureResult = Invoke-BoostLabGameBarRemoveAppxWhereNameLike `
        -Patterns $gameBarAppxPatterns `
        -AppxGetter { @([pscustomobject]@{ Name = 'Microsoft.XboxProtected'; PackageFullName = 'Microsoft.XboxProtected_1'; PackageFamilyName = 'Microsoft.XboxProtected_family'; User = 'S-1-5'; InstallLocation = 'C:\Mock\Protected' }) } `
        -AppxRemover { throw 'Access is denied.' }
    Assert-GameBarCondition (-not [bool]$realAppxFailureResult.Success) 'GameBar AppX removal must fail on real package removal errors.'
    Assert-GameBarCondition (@($realAppxFailureResult.FailedPackages).Count -eq 1) 'GameBar AppX removal must report real package failures.'
    Assert-GameBarCondition ([string]$realAppxFailureResult.FailedPackages[0].Package.PackageFullName -eq 'Microsoft.XboxProtected_1') 'GameBar AppX real failure must include PackageFullName.'
    Assert-GameBarCondition ([string]$realAppxFailureResult.FailedPackages[0].Package.PackageFamilyName -eq 'Microsoft.XboxProtected_family') 'GameBar AppX real failure must include PackageFamilyName.'
    Assert-GameBarCondition ([string]$realAppxFailureResult.FailedPackages[0].Outcome -eq 'FailedUnexpected') 'Unexpected GameBar AppX removal failure must remain a hard FailedUnexpected outcome.'

    $appxFailureSeen = [System.Collections.Generic.List[string]]::new()
    $appxFailureExecutor = {
        param($Operation)
        $appxFailureSeen.Add([string]$Operation.OperationType)
        if ([string]$Operation.OperationType -eq 'RemoveAppxWhereNameLike') {
            return $realAppxFailureResult
        }

        [pscustomobject]@{
            Success       = $true
            OperationType = [string]$Operation.OperationType
            Description   = [string]$Operation.Description
        }
    }.GetNewClosure()
    $failedAppxWorkflow = Invoke-BoostLabGameBarBranchWorkflow -Branch OffRecommended -OperationExecutor $appxFailureExecutor -SkipEnvironmentChecks
    Assert-GameBarCondition (-not [bool]$failedAppxWorkflow.Success) 'GameBar branch must stop on a real RemoveAppxWhereNameLike failure.'
    Assert-GameBarCondition ([string]$failedAppxWorkflow.CommandStatus -eq 'Failed') 'GameBar branch must report failed command status on real AppX failure.'
    Assert-GameBarCondition (($appxFailureSeen.ToArray() -join ',') -eq 'StopProcess,RemoveAppxWhereNameLike') 'GameBar branch must not continue after a real AppX operation failure.'

    Assert-GameBarCondition ($offPlan.RegistryPayloads.OffRecommended.Contains('"GameDVR_Enabled"=dword:00000000')) 'GameBar Off registry payload is missing GameDVR_Enabled.'
    Assert-GameBarCondition ($offPlan.RegistryPayloads.OffRecommended.Contains('"AppCaptureEnabled"=dword:00000000')) 'GameBar Off registry payload is missing AppCaptureEnabled.'
    Assert-GameBarCondition ($offPlan.RegistryPayloads.OffRecommended.Contains('"UseNexusForGameBarEnabled"=dword:00000000')) 'GameBar Off registry payload is missing UseNexusForGameBarEnabled.'
    Assert-GameBarCondition ($offPlan.RegistryPayloads.OffRecommended.Contains('"GamepadNexusChordEnabled"=dword:00000000')) 'GameBar Off registry payload is missing GamepadNexusChordEnabled.'
    Assert-GameBarCondition ($offPlan.RegistryPayloads.OffRecommended.Contains('[HKEY_CLASSES_ROOT\ms-gamebar]')) 'GameBar Off registry payload is missing ms-gamebar.'
    Assert-GameBarCondition ($offPlan.RegistryPayloads.OffRecommended.Contains('PresenceServer.Internal.PresenceWriter')) 'GameBar Off registry payload is missing PresenceWriter.'
    Assert-GameBarCondition ($defaultPlan.RegistryPayloads.Default.Contains('"ActivationType"=dword:00000001')) 'GameBar Default registry payload is missing ActivationType DWORD 1.'
    foreach ($serviceName in @('GameInputSvc', 'BcastDVRUserService', 'XboxGipSvc', 'XblAuthManager', 'XblGameSave', 'XboxNetApiSvc')) {
        Assert-GameBarCondition ($defaultPlan.RegistryPayloads.Default.Contains($serviceName)) "GameBar Default registry payload is missing service start value: $serviceName"
    }

    $downloadArtifacts = @($defaultPlan.DownloadArtifacts)
    Assert-GameBarCondition ($downloadArtifacts.Count -eq 2) 'GameBar Default must declare the two source download artifacts.'
    foreach ($artifact in $downloadArtifacts) {
        Assert-GameBarCondition ([string]$artifact.Classification -eq 'UltimateAuthorHostedArtifact') 'GameBar downloads must be classified as UltimateAuthorHostedArtifact.'
        Assert-GameBarCondition ([bool]$artifact.NeedsBoostLabMirror) 'GameBar downloads must be marked NeedsBoostLabMirror.'
    }
    Assert-GameBarCondition ($downloadArtifacts.Url -contains 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edgewebview.exe') 'GameBar Default is missing the source Edge WebView URL.'
    Assert-GameBarCondition ($downloadArtifacts.Url -contains 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/gamingrepairtool.exe') 'GameBar Default is missing the source gaming repair tool URL.'

    $unsupportedOpen = Invoke-BoostLabToolAction -ActionName Open
    Assert-GameBarCondition (-not [bool]$unsupportedOpen.Success) 'GameBar Open must not be supported.'
    Assert-GameBarCondition ([string]$unsupportedOpen.CommandStatus -eq 'NotSupported') 'GameBar Open should return NotSupported.'
    $unsupportedRestore = Invoke-BoostLabToolAction -ActionName Restore
    Assert-GameBarCondition (-not [bool]$unsupportedRestore.Success) 'GameBar Restore must not be supported.'
    Assert-GameBarCondition ([string]$unsupportedRestore.CommandStatus -eq 'NotSupported') 'GameBar Restore should return NotSupported.'

    $unconfirmedApply = Invoke-BoostLabToolAction -ActionName Apply
    Assert-GameBarCondition (-not [bool]$unconfirmedApply.Success) 'GameBar Apply without confirmation must not run.'
    Assert-GameBarCondition ([string]$unconfirmedApply.CommandStatus -eq 'ConfirmationRequired') 'GameBar Apply without confirmation must request confirmation.'
    Assert-GameBarCondition (-not [bool]$unconfirmedApply.ChangesExecuted) 'GameBar Apply without confirmation must not execute changes.'

    $executedOperations = [System.Collections.Generic.List[string]]::new()
    $mockExecutor = {
        param($Operation)
        $script:GameBarExecutedOperations.Add([string]$Operation.OperationType)
        [pscustomobject]@{
            Success       = $true
            OperationType = [string]$Operation.OperationType
            Description   = [string]$Operation.Description
        }
    }

    $script:GameBarExecutedOperations = $executedOperations
    $applyResult = Invoke-BoostLabToolAction -ActionName Apply -Confirmed -OperationExecutor $mockExecutor -SkipEnvironmentChecks
    Assert-GameBarCondition ([bool]$applyResult.Success) 'GameBar Apply should complete with mocked operations.'
    Assert-GameBarCondition ([string]$applyResult.CommandStatus -eq 'Completed') 'GameBar Apply mock should report Completed.'
    Assert-GameBarCondition ([bool]$applyResult.ChangesExecuted) 'GameBar Apply mock should report changes executed.'
    Assert-GameBarCondition (-not ('RequireAdministrator' -in @($script:GameBarExecutedOperations))) 'GameBar Apply mock should skip admin preflight when requested.'
    Assert-GameBarCondition (-not ('RequireInternet' -in @($script:GameBarExecutedOperations))) 'GameBar Apply mock should skip internet preflight when requested.'
    Assert-GameBarCondition ($script:GameBarExecutedOperations.Count -eq 11) "GameBar Apply mock should execute 11 non-preflight operations, found $($script:GameBarExecutedOperations.Count)."

    $script:GameBarExecutedOperations = [System.Collections.Generic.List[string]]::new()
    $defaultResult = Invoke-BoostLabToolAction -ActionName Default -Confirmed -OperationExecutor $mockExecutor -SkipEnvironmentChecks
    Assert-GameBarCondition ([bool]$defaultResult.Success) 'GameBar Default should complete with mocked operations.'
    Assert-GameBarCondition ([string]$defaultResult.CommandStatus -eq 'Completed') 'GameBar Default mock should report Completed.'
    Assert-GameBarCondition ([bool]$defaultResult.ChangesExecuted) 'GameBar Default mock should report changes executed.'
    Assert-GameBarCondition ($script:GameBarExecutedOperations.Count -eq 8) "GameBar Default mock should execute 8 non-preflight operations, found $($script:GameBarExecutedOperations.Count)."

    $failureExecutor = {
        param($Operation)
        if ([string]$Operation.OperationType -eq 'TrustedInstallerCommand') {
            throw 'mock TI failure'
        }
        [pscustomobject]@{ Success = $true; OperationType = [string]$Operation.OperationType }
    }
    $failedApply = Invoke-BoostLabToolAction -ActionName Apply -Confirmed -OperationExecutor $failureExecutor -SkipEnvironmentChecks
    Assert-GameBarCondition (-not [bool]$failedApply.Success) 'GameBar Apply must fail closed when a mocked operation fails.'
    Assert-GameBarCondition ([string]$failedApply.CommandStatus -eq 'Failed') 'GameBar Apply failure must report Failed.'
    Assert-GameBarCondition ([string]$failedApply.VerificationStatus -eq 'Failed') 'GameBar Apply failure must fail verification.'
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
    Remove-Variable -Name GameBarExecutedOperations -Scope Script -ErrorAction SilentlyContinue
}

$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$gameBarRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'game-bar' }) | Select-Object -First 1
Assert-GameBarCondition ($null -ne $gameBarRecord) 'GameBar parity baseline record is missing.'
Assert-GameBarCondition ([string]$gameBarRecord.RuntimeStatus -eq 'RuntimeImplemented') 'GameBar must be runtime implemented after Phase 146.'
Assert-GameBarCondition ([string]$gameBarRecord.ImplementationLevel -eq 'ParityImplemented') 'GameBar must be marked ParityImplemented after Phase 146.'
Assert-GameBarCondition ([string]$gameBarRecord.UltimateParity -eq 'Yes') 'GameBar UltimateParity must be Yes after Phase 146.'
Assert-GameBarCondition ([string]$gameBarRecord.FinalProgressStatus -eq 'DoneParity') 'GameBar final progress status must be DoneParity.'
Assert-GameBarCondition (-not [bool]$gameBarRecord.YazanFinalException) 'GameBar must not use a Yazan final exception.'
$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-GameBarCondition ([string]$nextTarget.ToolId -eq [string]$parityBaseline.CurrentOrderedParityTarget) 'Next ordered parity target must match the central baseline cursor.'
Assert-GameBarCondition ([string]$parityBaseline.CurrentOrderedParityTarget -ne 'game-bar') 'Current ordered parity target must have advanced beyond game-bar.'

$inventoryAssertion = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
Assert-GameBarCondition ([int]$inventoryAssertion.Baseline.ImplementedTools -eq [int]$inventoryAssertion.Snapshot.ImplementedTools) 'Inventory implemented count must remain baseline-derived.'
Assert-GameBarCondition ([int]$inventoryAssertion.Baseline.DeferredPlaceholders -eq [int]$inventoryAssertion.Snapshot.DeferredPlaceholders) 'Inventory deferred count must remain baseline-derived.'

$artifactProvenance = Import-PowerShellDataFile -LiteralPath $artifactProvenancePath
$productionAllowlist = Get-Content -LiteralPath $productionAllowlistPath -Raw
$runtimeArtifactText = (@($artifactProvenance.Artifacts) | Out-String)
Assert-GameBarCondition (-not $runtimeArtifactText.Contains('edgewebview.exe')) 'GameBar phase must not add edgewebview.exe to runtime artifact approvals.'
Assert-GameBarCondition (-not $runtimeArtifactText.Contains('gamingrepairtool.exe')) 'GameBar phase must not add gamingrepairtool.exe to runtime artifact approvals.'
$gameBarProvenanceOnlyApprovals = @(
    $artifactProvenance.ProvenanceOnlyApprovals |
        Where-Object { [string]$_.SourceToolId -eq 'game-bar' }
)
Assert-GameBarCondition ($gameBarProvenanceOnlyApprovals.Count -eq 2) 'GameBar must have exactly two Phase 164G provenance-only records.'
foreach ($approval in $gameBarProvenanceOnlyApprovals) {
    Assert-GameBarCondition ([string]$approval.ApprovalStatus -eq 'ApprovedForProvenanceOnly') "GameBar artifact record must be provenance-only: $($approval.ArtifactId)"
    Assert-GameBarCondition ($approval.AllowExecution -eq $false) "GameBar provenance-only record must not allow execution: $($approval.ArtifactId)"
    Assert-GameBarCondition ($approval.DownloadExecutionApproved -eq $false) "GameBar provenance-only record must not approve download execution: $($approval.ArtifactId)"
    Assert-GameBarCondition ($approval.ProductionAllowlistApproved -eq $false) "GameBar provenance-only record must not approve production allowlist: $($approval.ArtifactId)"
}
Assert-GameBarCondition (-not $productionAllowlist.Contains('game-bar')) 'GameBar phase must not add production allowlist entries.'

Assert-GameBarCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'modules\Windows\loudness-eq.psm1'))) 'Loudness EQ module must remain deleted.'
Assert-GameBarCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'modules\Graphics\nvme-faster-driver.psm1'))) 'NVME Faster Driver module must remain deleted.'

[pscustomobject]@{
    Test = 'GameBarExactUltimateParityImplementation'
    SourceSHA256 = $actualSourceHash
    ImplementedActions = @('Apply', 'Default')
    ApplyOperationCount = $offPlan.OperationCount
    DefaultOperationCount = $defaultPlan.OperationCount
    DownloadArtifacts = $downloadArtifacts.Count
    CurrentOrderedParityTarget = $parityBaseline.CurrentOrderedParityTarget
    InventoryImplementedTools = $inventoryAssertion.Baseline.ImplementedTools
    InventoryDeferredPlaceholders = $inventoryAssertion.Baseline.DeferredPlaceholders
    ProtectedPathsUntouched = $true
}
