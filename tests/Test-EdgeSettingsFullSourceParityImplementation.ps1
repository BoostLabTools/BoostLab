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
        throw 'Unable to determine the Edge Settings full-source parity validator path.'
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
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [string]$Needle,

        [Parameter(Mandatory)]
        [string]$Description
    )

    Assert-BoostLabCondition ($Text.Contains($Needle)) "$Description is missing expected text: $Needle"
}

$inventoryAssertion = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
$inventoryBaseline = $inventoryAssertion.Baseline
$inventorySnapshot = $inventoryAssertion.Snapshot

$sourcePath = Join-Path $ProjectRoot 'source-ultimate\3 Setup\6 Edge Settings.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Setup\edge-settings.psm1'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$startPath = Join-Path $ProjectRoot 'Start-BoostLab.ps1'
$parityPath = Join-Path $ProjectRoot 'config\ParityStatusBaseline.psd1'
$migrationPath = Join-Path $ProjectRoot 'docs\migrations\edge-settings.md'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'

foreach ($path in @($sourcePath, $modulePath, $stagesPath, $executionPath, $actionPlanPath, $startPath, $parityPath, $migrationPath, $artifactPath, $productionAllowlistPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required Edge Settings file is missing: $path"
}

$expectedSourceHash = '3EE9E6F586D71E74F7400379E8D5DA079D52208D5B2DFA0E4AB035FCB08096A8'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Edge Settings source hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."

$sourceText = Get-Content -Raw -LiteralPath $sourcePath
$moduleText = Get-Content -Raw -LiteralPath $modulePath
$executionText = Get-Content -Raw -LiteralPath $executionPath
$actionPlanText = Get-Content -Raw -LiteralPath $actionPlanPath
$startText = Get-Content -Raw -LiteralPath $startPath
$migrationText = Get-Content -Raw -LiteralPath $migrationPath
$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPath
$productionAllowlist = Import-PowerShellDataFile -LiteralPath $productionAllowlistPath
$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot

foreach ($sourceNeedle in @(
    'HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist',
    'odfafepnkmbhccpbejgmiehpchacaeak;https://edge.microsoft.com/extensionwebstorebase/v1/crx',
    'HardwareAccelerationModeEnabled',
    'BackgroundModeEnabled',
    'StartupBoostEnabled',
    'HKLM:\Software\Microsoft\Active Setup\Installed Components',
    '$val -like "*Edge*"',
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
    '$_ -like "*msedge*"',
    "Get-Service | Where-Object { `$_.Name -match 'Edge' }",
    'sc stop',
    'sc delete',
    "Get-ScheduledTask | Where-Object { `$_.TaskName -like '*Edge*' }",
    'Unregister-ScheduledTask',
    'Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}',
    'Stop-Process -Name "msedge"',
    'Start-Process "msedge.exe"',
    'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe',
    'Start-Process "$env:SystemRoot\Temp\edge.exe"'
)) {
    Assert-BoostLabTextContains -Text $sourceText -Needle $sourceNeedle -Description 'Edge Settings Ultimate source'
}

Assert-BoostLabCondition (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) 'Edge Settings module must no longer use the placeholder contract.'
foreach ($moduleNeedle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'', ''Restore'')',
    'Invoke-BoostLabEdgeSettingsApply',
    'Invoke-BoostLabEdgeSettingsDefault',
    'Get-BoostLabEdgeSettingsOperationPlan',
    'Get-BoostLabEdgeSettingsActiveSetupTargets',
    'Get-BoostLabEdgeSettingsRunOnceTargets',
    'Get-BoostLabEdgeSettingsServiceTargets',
    'Get-BoostLabEdgeSettingsScheduledTaskTargets',
    'Invoke-BoostLabEdgeSettingsDownload',
    'Start-BoostLabEdgeSettingsProcess',
    'RestoreUnavailable'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $moduleNeedle -Description 'Edge Settings module'
}

Assert-BoostLabTextContains -Text $executionText -Needle "'edge-settings'" -Description 'Execution module map'
Assert-BoostLabTextContains -Text $executionText -Needle 'Get-BoostLabVerificationValidation' -Description 'Execution production verification runtime'
Assert-BoostLabTextContains -Text $startText -Needle 'Get-BoostLabVerificationValidation' -Description 'Start-BoostLab production verification startup guard'
Assert-BoostLabCondition (-not $executionText.Contains('Test-BoostLabVerificationResult')) 'Execution runtime must not call the legacy Test-BoostLabVerificationResult helper.'
Assert-BoostLabCondition (-not $startText.Contains('Test-BoostLabVerificationResult')) 'Start-BoostLab must not require the legacy Test-BoostLabVerificationResult helper.'
Assert-BoostLabTextContains -Text $actionPlanText -Needle 'Run the source-equivalent Edge Settings Optimize branch' -Description 'Action Plan Apply text'
Assert-BoostLabTextContains -Text $actionPlanText -Needle 'Run the source-equivalent Edge Settings Default branch' -Description 'Action Plan Default text'
Assert-BoostLabTextContains -Text $actionPlanText -Needle 'approved captured Edge Settings restore contract' -Description 'Action Plan Restore text'

foreach ($migrationNeedle in @(
    'source-ultimate/3 Setup/6 Edge Settings.ps1',
    '3EE9E6F586D71E74F7400379E8D5DA079D52208D5B2DFA0E4AB035FCB08096A8',
    'Edge Settings: Optimize (Recommended)',
    'Edge Settings: Default',
    'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe',
    'SupportsRestore: false',
    'Restore is unavailable',
    'Approved in Phase 118'
)) {
    Assert-BoostLabTextContains -Text $migrationText -Needle $migrationNeedle -Description 'Edge Settings migration record'
}

$edgeTool = @($stages.Stages | ForEach-Object { $_.Tools } | Where-Object { [string]$_.Id -eq 'edge-settings' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $edgeTool) 'Edge Settings tool metadata is missing from Stages.'
Assert-BoostLabCondition ([string]$edgeTool.Type -eq 'action') 'Edge Settings must be an action tool.'
Assert-BoostLabCondition ([string]$edgeTool.RiskLevel -eq 'high') 'Edge Settings must be high risk.'
Assert-BoostLabCondition ((@($edgeTool.Actions) -join ',') -eq 'Analyze,Apply,Default,Restore') 'Edge Settings actions must be Analyze, Apply, Default, Restore.'
Assert-BoostLabCondition ([bool]$edgeTool.Capabilities.RequiresAdmin) 'Edge Settings must require Administrator.'
Assert-BoostLabCondition ([bool]$edgeTool.Capabilities.RequiresInternet) 'Edge Settings must require internet like the source.'
Assert-BoostLabCondition ([bool]$edgeTool.Capabilities.CanModifyRegistry) 'Edge Settings must declare registry mutation.'
Assert-BoostLabCondition ([bool]$edgeTool.Capabilities.CanModifyServices) 'Edge Settings must declare service mutation.'
Assert-BoostLabCondition ([bool]$edgeTool.Capabilities.CanDownload) 'Edge Settings must declare download capability.'
Assert-BoostLabCondition ([bool]$edgeTool.Capabilities.CanInstallSoftware) 'Edge Settings must declare installer capability.'
Assert-BoostLabCondition ([bool]$edgeTool.Capabilities.CanDeleteFiles) 'Edge Settings must declare deletion capability.'
Assert-BoostLabCondition (-not [bool]$edgeTool.Capabilities.CanReboot) 'Edge Settings must not declare reboot capability.'
Assert-BoostLabCondition ([bool]$edgeTool.Capabilities.NeedsExplicitConfirmation) 'Edge Settings must require explicit confirmation.'

Import-Module $actionPlanPath -Force
$toolMetadata = [ordered]@{
    Id           = [string]$edgeTool.Id
    Title        = [string]$edgeTool.Title
    Stage        = [string]$edgeTool.Stage
    Order        = [int]$edgeTool.Order
    Type         = [string]$edgeTool.Type
    RiskLevel    = [string]$edgeTool.RiskLevel
    Description  = [string]$edgeTool.Description
    Actions      = @($edgeTool.Actions)
    Capabilities = $edgeTool.Capabilities
}
$applyPlan = New-BoostLabActionPlan -ToolMetadata $toolMetadata -ActionName Apply
$defaultPlan = New-BoostLabActionPlan -ToolMetadata $toolMetadata -ActionName Default
$restorePlan = New-BoostLabActionPlan -ToolMetadata $toolMetadata -ActionName Restore
Assert-BoostLabTextContains -Text ((@($applyPlan.PlannedChanges) -join ' | ')) -Needle 'Active Setup' -Description 'Apply Action Plan'
Assert-BoostLabTextContains -Text ((@($applyPlan.PlannedChanges) -join ' | ')) -Needle 'scheduled tasks' -Description 'Apply Action Plan'
Assert-BoostLabTextContains -Text ((@($defaultPlan.PlannedChanges) -join ' | ')) -Needle 'Download the source-defined edge.exe' -Description 'Default Action Plan'
Assert-BoostLabTextContains -Text ((@($restorePlan.PlannedChanges) -join ' | ')) -Needle 'No Edge Settings registry, service, scheduled-task, process, download, installer, Edge, or system mutation is planned.' -Description 'Restore Action Plan'

foreach ($runtimeDependency in @(
    'core\Environment.psm1'
    'core\Logging.psm1'
    'core\Safety.psm1'
    'core\State.psm1'
    'core\TrustedInstaller.psm1'
)) {
    Import-Module -Name (Join-Path $ProjectRoot $runtimeDependency) -Force -ErrorAction Stop
}
$runtimeCapabilities = @{}
foreach ($capabilityName in $toolMetadata.Capabilities.Keys) {
    $runtimeCapabilities[$capabilityName] = $toolMetadata.Capabilities[$capabilityName]
}
$runtimeCapabilities['RequiresAdmin'] = $false
$runtimeToolMetadata = [ordered]@{
    Id           = $toolMetadata.Id
    Title        = $toolMetadata.Title
    Stage        = $toolMetadata.Stage
    Order        = $toolMetadata.Order
    Type         = $toolMetadata.Type
    RiskLevel    = $toolMetadata.RiskLevel
    Description  = $toolMetadata.Description
    Actions      = @($toolMetadata.Actions)
    Capabilities = $runtimeCapabilities
}
$previousProgramData = $env:ProgramData
$testProgramData = Join-Path ([IO.Path]::GetTempPath()) 'BoostLabEdgeSettingsRuntimeState'
New-Item -ItemType Directory -Path $testProgramData -Force -ErrorAction Stop | Out-Null
$env:ProgramData = $testProgramData
$executionModule = $null
try {
    Initialize-BoostLabState | Out-Null
    $executionModule = Import-Module -Name $executionPath -Force -PassThru -Scope Local -ErrorAction Stop
    $runtimeAnalyzeResult = & $executionModule {
        param($Metadata)
        Invoke-BoostLabToolAction -ToolMetadata $Metadata -ActionName Analyze
    } $runtimeToolMetadata
    Assert-BoostLabCondition ([bool]$runtimeAnalyzeResult.Success) "Runtime Edge Settings Analyze failed: $($runtimeAnalyzeResult.Message)"
    Assert-BoostLabCondition ([string]$runtimeAnalyzeResult.Status -eq 'Analyzed') 'Runtime Edge Settings Analyze must return Analyzed.'
    Assert-BoostLabCondition ([string]$runtimeAnalyzeResult.CommandStatus -eq 'No execution performed') 'Runtime Edge Settings Analyze must remain read-only.'
    Assert-BoostLabCondition ([string]$runtimeAnalyzeResult.VerificationStatus -eq 'Passed') 'Runtime Edge Settings Analyze verification must pass.'
    Assert-BoostLabCondition (-not ([string]$runtimeAnalyzeResult.Message).Contains('Test-BoostLabVerificationResult')) 'Runtime Edge Settings Analyze must not mention the legacy Test-BoostLabVerificationResult helper.'
    Assert-BoostLabCondition ([bool]$runtimeAnalyzeResult.Data.NoMutationOccurred) 'Runtime Edge Settings Analyze must report NoMutationOccurred.'
    Assert-BoostLabCondition ([bool]$runtimeAnalyzeResult.Data.NoDownloadOccurred) 'Runtime Edge Settings Analyze must report NoDownloadOccurred.'
    Assert-BoostLabCondition ([bool]$runtimeAnalyzeResult.Data.NoExternalProcessStarted) 'Runtime Edge Settings Analyze must report NoExternalProcessStarted.'
}
finally {
    if ($null -ne $executionModule) {
        Remove-Module -ModuleInfo $executionModule -Force -ErrorAction SilentlyContinue
    }
    $env:ProgramData = $previousProgramData
}

Import-Module $modulePath -Force
$info = Get-BoostLabToolInfo
Assert-BoostLabCondition ([string]$info.Id -eq 'edge-settings') 'Imported Edge Settings module reported the wrong id.'
Assert-BoostLabCondition ((@($info.Actions) -join ',') -eq 'Analyze,Apply,Default,Restore') 'Imported Edge Settings module reported wrong actions.'

$analysisResult = Invoke-BoostLabToolAction -ActionName Analyze
Assert-BoostLabCondition ([string]$analysisResult.Status -eq 'Analyzed') 'Analyze must be read-only and successful.'
Assert-BoostLabCondition ([string]$analysisResult.CommandStatus -eq 'No execution performed') 'Analyze must perform no execution.'
Assert-BoostLabCondition ([string]$analysisResult.Data.Source.ChecksumStatus -eq 'Passed') 'Analyze must verify source identity.'
Assert-BoostLabCondition ([string]$analysisResult.Data.Readiness -eq 'Ready for confirmed Apply or Default.') 'Analyze must report Apply/Default readiness after source verification.'
Assert-BoostLabCondition ([string]$analysisResult.Data.RestoreStatus -eq 'UnavailableWithoutApprovedCapturedState') 'Analyze must not claim Restore availability.'

$blockedCalls = [System.Collections.Generic.List[string]]::new()
$blockedApply = Invoke-BoostLabToolAction `
    -ActionName Apply `
    -AdministratorChecker { $true } `
    -InternetChecker { $true } `
    -RegistryWriter { param($Path, $Name, $Type, $Data) $blockedCalls.Add("write:$Path|$Name") } `
    -RegistryKeyRemover { param($Path) $blockedCalls.Add("key-remove:$Path") } `
    -RegistryValueRemover { param($Path, $Name) $blockedCalls.Add("value-remove:$Path|$Name") }
Assert-BoostLabCondition ([string]$blockedApply.Status -eq 'Cancelled') 'Apply without confirmation must be blocked.'
Assert-BoostLabCondition ([string]$blockedApply.CommandStatus -eq 'Cancelled before execution') 'Apply without confirmation must be cancelled before execution.'
Assert-BoostLabCondition ($blockedCalls.Count -eq 0) 'Apply without confirmation must not mutate.'

$applyCalls = [System.Collections.Generic.List[string]]::new()
$applyResult = Invoke-BoostLabToolAction `
    -ActionName Apply `
    -Confirmed $true `
    -AdministratorChecker { $true } `
    -InternetChecker { $true } `
    -RegistryCapture { param($Path, $Name) [pscustomobject]@{ Captured = $true; TargetType = 'RegistryValue'; Path = $Path; Name = $Name } } `
    -RegistryKeyCapture { param($Path) [pscustomobject]@{ Captured = $true; TargetType = 'RegistryKey'; Path = $Path } } `
    -RegistryWriter { param($Path, $Name, $Type, $Data) $applyCalls.Add("write:$Path|$Name|$Type|$Data"); [pscustomobject]@{ Success = $true; Operation = 'SetRegistryValue'; Path = $Path; Name = $Name; Type = $Type; Data = $Data } } `
    -RegistryKeyRemover { param($Path) $applyCalls.Add("key-remove:$Path"); [pscustomobject]@{ Success = $true; Operation = 'RemoveRegistryKey'; Path = $Path } } `
    -RegistryValueRemover { param($Path, $Name) $applyCalls.Add("value-remove:$Path|$Name"); [pscustomobject]@{ Success = $true; Operation = 'RemoveRegistryValue'; Path = $Path; Name = $Name } } `
    -ActiveSetupEnumerator { @([pscustomobject]@{ Path = 'HKLM:\Software\Microsoft\Active Setup\Installed Components\EdgeMock'; DefaultValue = 'Microsoft Edge' }) } `
    -RunOnceEnumerator { @([pscustomobject]@{ Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce'; Name = 'msedgeupdate'; Value = 'msedge.exe' }) } `
    -ServiceEnumerator { @([pscustomobject]@{ Name = 'edgeupdate' }, [pscustomobject]@{ Name = 'MicrosoftEdgeElevationService' }) } `
    -ServiceStopper { param($Name) $applyCalls.Add("service-stop:$Name"); [pscustomobject]@{ Success = $true; Operation = 'StopService'; Name = $Name } } `
    -ServiceDeleter { param($Name) $applyCalls.Add("service-delete:$Name"); [pscustomobject]@{ Success = $true; Operation = 'DeleteService'; Name = $Name } } `
    -ScheduledTaskEnumerator { @([pscustomobject]@{ TaskName = 'MicrosoftEdgeUpdateTaskMachineCore'; TaskPath = '\' }) } `
    -ScheduledTaskUnregister { param($Task) $applyCalls.Add("task-remove:$($Task.TaskPath)$($Task.TaskName)"); [pscustomobject]@{ Success = $true; Operation = 'UnregisterScheduledTask'; TaskName = $Task.TaskName; TaskPath = $Task.TaskPath } }

Assert-BoostLabCondition ([bool]$applyResult.Success) "Apply failed in mocked validation: $($applyResult.Message)"
Assert-BoostLabCondition ([string]$applyResult.Status -eq 'Completed') "Apply returned unexpected status: $($applyResult.Status)"
Assert-BoostLabCondition ([string]$applyResult.CommandStatus -eq 'Completed') 'Apply command status must be Completed in mocked success path.'
Assert-BoostLabCondition ([string]$applyResult.VerificationStatus -eq 'Passed') 'Apply verification must pass in mocked success path.'
foreach ($expectedCall in @(
    'write:HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist|1|String|odfafepnkmbhccpbejgmiehpchacaeak;https://edge.microsoft.com/extensionwebstorebase/v1/crx',
    'write:HKLM:\SOFTWARE\Policies\Microsoft\Edge|HardwareAccelerationModeEnabled|DWord|0',
    'write:HKLM:\SOFTWARE\Policies\Microsoft\Edge|BackgroundModeEnabled|DWord|0',
    'write:HKLM:\SOFTWARE\Policies\Microsoft\Edge|StartupBoostEnabled|DWord|0',
    'key-remove:HKLM:\Software\Microsoft\Active Setup\Installed Components\EdgeMock',
    'value-remove:HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce|msedgeupdate',
    'service-stop:edgeupdate',
    'service-delete:edgeupdate',
    'service-stop:MicrosoftEdgeElevationService',
    'service-delete:MicrosoftEdgeElevationService',
    'task-remove:\MicrosoftEdgeUpdateTaskMachineCore',
    'key-remove:HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}',
    'key-remove:HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}'
)) {
    Assert-BoostLabCondition ($applyCalls.Contains($expectedCall)) "Apply did not represent expected source operation: $expectedCall"
}
Assert-BoostLabCondition (-not (($applyCalls -join "`n") -match 'Download|StartProcess|msedge.exe')) 'Apply must not run Default download/process behavior.'

$defaultCalls = [System.Collections.Generic.List[string]]::new()
$defaultResult = Invoke-BoostLabToolAction `
    -ActionName Default `
    -Confirmed $true `
    -AdministratorChecker { $true } `
    -InternetChecker { $true } `
    -RegistryKeyCapture { param($Path) [pscustomobject]@{ Captured = $true; TargetType = 'RegistryKey'; Path = $Path } } `
    -RegistryKeyRemover { param($Path) $defaultCalls.Add("key-remove:$Path"); [pscustomobject]@{ Success = $true; Operation = 'RemoveRegistryKey'; Path = $Path } } `
    -ProcessStopper { param($Name) $defaultCalls.Add("process-stop:$Name"); [pscustomobject]@{ Success = $true; Operation = 'StopProcess'; Name = $Name } } `
    -ProcessStarter { param($FilePath, $ArgumentList) $defaultCalls.Add("process-start:$FilePath|$(@($ArgumentList) -join ' ')"); [pscustomobject]@{ Success = $true; Operation = 'StartProcess'; FilePath = $FilePath; Arguments = @($ArgumentList) } } `
    -Downloader { param($Uri, $OutFile) $defaultCalls.Add("download:$Uri|$OutFile"); [pscustomobject]@{ Success = $true; Operation = 'Download'; Uri = $Uri; OutFile = $OutFile } } `
    -Sleep { param($Seconds) $defaultCalls.Add("sleep:$Seconds"); [pscustomobject]@{ Success = $true; Operation = 'Sleep'; Seconds = $Seconds } }

Assert-BoostLabCondition ([bool]$defaultResult.Success) "Default failed in mocked validation: $($defaultResult.Message)"
Assert-BoostLabCondition ([string]$defaultResult.Status -eq 'Completed') "Default returned unexpected status: $($defaultResult.Status)"
Assert-BoostLabCondition ([string]$defaultResult.CommandStatus -eq 'Completed') 'Default command status must be Completed in mocked success path.'
Assert-BoostLabCondition ([string]$defaultResult.VerificationStatus -eq 'Passed') 'Default verification must pass in mocked success path.'
Assert-BoostLabCondition ($defaultCalls.Contains('key-remove:HKLM:\SOFTWARE\Policies\Microsoft\Edge')) 'Default must delete the source-defined Edge policy key.'
Assert-BoostLabCondition ($defaultCalls.Contains('process-stop:msedge')) 'Default must stop msedge.'
Assert-BoostLabCondition ($defaultCalls.Contains('process-start:msedge.exe|--restore-last-session --disable-extensions')) 'Default must launch msedge with source-defined arguments.'
Assert-BoostLabCondition (($defaultCalls -join "`n") -match 'download:https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe') 'Default must download the source-defined edge.exe URL in mocked path.'
Assert-BoostLabCondition (($defaultCalls -join "`n") -match 'process-start:.*edge\.exe\|$') 'Default must start the downloaded edge.exe in mocked path.'

$restoreResult = Invoke-BoostLabToolAction -ActionName Restore
Assert-BoostLabCondition ([string]$restoreResult.Status -eq 'RestoreUnavailable') 'Restore must remain unavailable.'
Assert-BoostLabCondition ([string]$restoreResult.CommandStatus -eq 'Refused before execution') 'Restore must fail closed before execution.'
Assert-BoostLabCondition ([string]$restoreResult.Message -match 'No Edge mutation is planned') 'Restore wording must not imply mutation without selected state.'

$edgeRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'edge-settings' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $edgeRecord) 'Edge Settings parity record is missing.'
Assert-BoostLabCondition ([string]$edgeRecord.RuntimeStatus -eq 'RuntimeImplemented') 'Edge Settings must be runtime implemented.'
Assert-BoostLabCondition ([string]$edgeRecord.ImplementationLevel -eq 'NearParityControlled') 'Edge Settings must be NearParityControlled.'
Assert-BoostLabCondition ([string]$edgeRecord.FinalProgressStatus -eq 'DoneYazanAcceptedNearParity') 'Edge Settings must be accepted near parity.'
Assert-BoostLabCondition ([bool]$edgeRecord.YazanAcceptedNearParity) 'Edge Settings must set YazanAcceptedNearParity.'
Assert-BoostLabCondition (-not [bool]$edgeRecord.YazanFinalException) 'Edge Settings must not set YazanFinalException.'
Assert-BoostLabTextContains -Text ([string]$edgeRecord.GapSummary) -Needle 'source-equivalent Edge Settings behavior' -Description 'Edge Settings parity GapSummary'

$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq [string]$parityBaseline.CurrentOrderedParityTarget) 'Next ordered parity target must match the central parity baseline cursor.'

Assert-BoostLabCondition ([int]$inventorySnapshot.ActiveTools -eq [int]$inventoryBaseline.ActiveTools) 'Active tool baseline must match live inventory after Edge Settings.'
Assert-BoostLabCondition ([int]$inventoryBaseline.ImplementedTools -eq [int]$inventorySnapshot.ImplementedTools) 'Implemented tool baseline must match live inventory after Edge Settings.'
Assert-BoostLabCondition ([int]$inventoryBaseline.DeferredPlaceholders -eq [int]$inventorySnapshot.DeferredPlaceholders) 'Deferred placeholder baseline must match live inventory after Edge Settings.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.ActiveTools -eq [int]$inventoryBaseline.ActiveTools) 'Parity active count must match the central inventory baseline.'
Assert-BoostLabCondition ([int]$inventorySnapshot.ImplementedTools -eq [int]$inventoryBaseline.ImplementedTools) 'Live implemented tool count changed unexpectedly.'
Assert-BoostLabCondition ([int]$inventorySnapshot.DeferredPlaceholders -eq [int]$inventoryBaseline.DeferredPlaceholders) 'Live deferred placeholder count changed unexpectedly.'

Assert-BoostLabCondition (@($artifactPolicy.Artifacts).Count -eq 0) 'No artifact provenance entries may be added in Phase 118.'
Assert-BoostLabCondition (@($productionAllowlist.ProductionAllowlistProposals).Count -eq 0) 'No production allowlist proposals may be added in Phase 118.'

$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
        Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
        ForEach-Object {
            $relativePath = $_.FullName.Substring($root.Length + 1).Replace('\', '/')
            $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
            "$relativePath|$hash"
        }
)
$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $sourceManifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n")))
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}
Assert-BoostLabCondition (@($sourceLines).Count -eq 49) 'Legacy source file count changed.'
Assert-BoostLabCondition ($sourceManifestHash -eq 'B07E015D5BA32E9CF4DBC1804597311D8A41CE7FA537C0091914056BEF06FFF4') 'Legacy source manifest changed.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }).Count -eq 0) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    Test                            = 'EdgeSettingsFullSourceParityImplementation'
    ToolId                          = 'edge-settings'
    SourceHash                      = $actualSourceHash
    AnalyzeStatus                   = $analysisResult.Status
    ApplyStatus                     = $applyResult.Status
    DefaultStatus                   = $defaultResult.Status
    RestoreStatus                   = $restoreResult.Status
    NextOrderedPendingParityTarget  = $nextTarget.ToolId
    ActiveTools                     = $inventorySnapshot.ActiveTools
    ImplementedTools                = $inventorySnapshot.ImplementedTools
    DeferredPlaceholders            = $inventorySnapshot.DeferredPlaceholders
    ProductionArtifacts             = @($artifactPolicy.Artifacts).Count
    ProductionAllowlistProposals    = @($productionAllowlist.ProductionAllowlistProposals).Count
    SourceUltimateUnchanged         = $true
    DeletedToolsRemainDeleted       = $true
    Message                         = 'Edge Settings full source-equivalent controlled near-parity implementation passed mocked validation.'
}

