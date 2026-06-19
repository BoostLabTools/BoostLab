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
        throw 'Unable to determine the Installers ordered parity validator path.'
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
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-BoostLabContains {
    param(
        [AllowNull()][string]$Text,
        [Parameter(Mandatory)][string]$Needle,
        [Parameter(Mandatory)][string]$Description
    )

    if ([string]::IsNullOrEmpty($Text) -or -not $Text.Contains($Needle)) {
        throw "$Description missing expected text: $Needle"
    }
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Installers\installers.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\4 Installers\1 Installers.ps1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$allowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

foreach ($path in @($configPath, $modulePath, $sourcePath, $actionPlanPath, $executionPath, $uiPath, $artifactPath, $allowlistPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required Installers Phase 119 file missing: $path"
}

$expectedSourceHash = '1065D64183457D4E7B28EA78DDE41525EC8F7C4A4BCA12D29B70D991141C0C67'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Installers source hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."

$sourceText = Get-Content -LiteralPath $sourcePath -Raw
$expectedRemovedMenu = [ordered]@{
    11 = 'Frame View'
    12 = 'GOG launcher'
    15 = 'Notepad ++'
    16 = 'Nvidia App'
    18 = 'Onboard Memory Manager'
    19 = 'Pot Player'
}
foreach ($entry in $expectedRemovedMenu.GetEnumerator()) {
    $number = [int]$entry.Key
    $name = [string]$entry.Value
    Assert-BoostLabContains -Text $sourceText -Needle ('{0}. {1}' -f $number, $name) -Description "Installers source menu entry $number"
}
foreach ($retainedName in @('Google Chrome', 'OBS Studio', 'Rockstar Games')) {
    Assert-BoostLabContains -Text $sourceText -Needle $retainedName -Description 'Installers retained source app'
}

$sourceDownloadUrls = @(
    Select-String -LiteralPath $sourcePath -Pattern 'IWR "([^"]+)"' |
        ForEach-Object { $_.Matches[0].Groups[1].Value } |
        Sort-Object -Unique
)
Assert-BoostLabCondition ($sourceDownloadUrls.Count -eq 24) "Expected 24 unique source download URLs, found $($sourceDownloadUrls.Count)."

$config = Import-PowerShellDataFile -LiteralPath $configPath
$installersStage = @($config.Stages | Where-Object { [string]$_['Name'] -eq 'Installers' })[0]
$installersTool = @($installersStage.Tools | Where-Object { [string]$_['Id'] -eq 'installers' })[0]
Assert-BoostLabCondition ($null -ne $installersTool) 'Installers tool metadata is missing.'
Assert-BoostLabCondition ((@($installersTool.Actions) -join ',') -eq 'Analyze,Open,Apply,Default,Restore') 'Installers must expose canonical actions only.'
Assert-BoostLabCondition ([string]$installersTool.SelectionMode -eq 'MultiSelect') 'Installers must declare checkbox multi-select mode.'
Assert-BoostLabCondition ('Apply' -in @($installersTool.SelectionRequiredActions)) 'Installers Apply must require selected app IDs.'

$selectionItems = @($installersTool.SelectionItems)
$expectedRetainedIds = @(
    'discord'
    'roblox'
    'seven-zip'
    'battle-net'
    'brave'
    'electronic-arts'
    'epic-games'
    'escape-from-tarkov'
    'firefox'
    'google-chrome'
    'league-of-legends'
    'obs-studio'
    'rockstar-games'
    'spotify'
    'steam'
    'ubisoft-connect'
    'valorant'
)
Assert-BoostLabCondition ($selectionItems.Count -eq 17) "Expected 17 retained visible selection items, found $($selectionItems.Count)."
Assert-BoostLabCondition (((@($selectionItems | ForEach-Object { [string]$_['Id'] }) -join ',') -eq ($expectedRetainedIds -join ','))) 'Retained Installers selection order must match source order after Yazan exclusions.'
foreach ($removedId in @('frame-view', 'gog-launcher', 'notepad-plus-plus', 'nvidia-app', 'onboard-memory-manager', 'pot-player')) {
    Assert-BoostLabCondition ($removedId -notin @($selectionItems | ForEach-Object { [string]$_['Id'] })) "Removed app must not be selectable: $removedId"
}
foreach ($retainedId in @('google-chrome', 'obs-studio', 'rockstar-games')) {
    Assert-BoostLabCondition ($retainedId -in @($selectionItems | ForEach-Object { [string]$_['Id'] })) "Yazan-retained app is missing: $retainedId"
}

$capabilities = $installersTool.Capabilities
foreach ($trueCapability in @('RequiresAdmin', 'RequiresInternet', 'CanModifyRegistry', 'CanModifyServices', 'CanInstallSoftware', 'CanDownload', 'CanDeleteFiles', 'NeedsExplicitConfirmation')) {
    Assert-BoostLabCondition ([bool]$capabilities[$trueCapability]) "Installers capability should be true: $trueCapability"
}
foreach ($falseCapability in @('CanReboot', 'CanModifyDrivers', 'CanModifySecurity', 'UsesTrustedInstaller', 'UsesSafeMode', 'SupportsDefault', 'SupportsRestore')) {
    Assert-BoostLabCondition (-not [bool]$capabilities[$falseCapability]) "Installers capability should be false: $falseCapability"
}

$module = Import-Module -Name $modulePath -Force -PassThru -Scope Local
try {
    $info = & $module { Get-BoostLabToolInfo }
    Assert-BoostLabCondition ([string]$info.SelectionMode -eq 'MultiSelect') 'Module info must expose MultiSelect selection mode.'
    Assert-BoostLabCondition (@($info.SelectionItems).Count -eq 17) 'Module info must expose 17 retained selection items.'

    $analyze = & $module { Invoke-BoostLabToolAction -ActionName 'Analyze' }
    Assert-BoostLabCondition ([bool]$analyze.Success) 'Installers Analyze should succeed.'
    Assert-BoostLabCondition ([string]$analyze.Data.Mode -eq 'SelectedAppSequentialQueue') 'Analyze mode mismatch.'
    Assert-BoostLabCondition ([int]$analyze.Data.RetainedAppCount -eq 17) 'Analyze retained app count mismatch.'
    Assert-BoostLabCondition ([int]$analyze.Data.RetainedArtifactCount -eq 18) 'Analyze retained artifact count mismatch.'
    Assert-BoostLabCondition ([bool]$analyze.Data.NoMutationOccurred) 'Analyze must be read-only.'
    Assert-BoostLabCondition ([bool]$analyze.Data.RemovedMenuMappingValid) 'Removed menu mapping must be valid.'

    $catalog = @(& $module { Get-BoostLabInstallersCatalog })
    Assert-BoostLabCondition ($catalog.Count -eq 17) 'Module catalog must include every retained app and no removed apps.'
    Assert-BoostLabCondition (((@($catalog | ForEach-Object { [string]$_.AppId }) -join ',') -eq ($expectedRetainedIds -join ','))) 'Module catalog source order mismatch.'
    foreach ($app in $catalog) {
        Assert-BoostLabCondition (@($app.Artifacts).Count -ge 1) "Retained app missing artifact descriptor: $($app.AppId)"
        Assert-BoostLabCondition (@($app.InstallerCommands).Count -ge 1) "Retained app missing installer/helper descriptor: $($app.AppId)"
        Assert-BoostLabCondition (@($app.Operations).Count -ge 2) "Retained app missing operation plan: $($app.AppId)"
        Assert-BoostLabCondition (@($app.SideEffectFamilies).Count -ge 1) "Retained app missing side-effect families: $($app.AppId)"
    }

    $firefox = @($catalog | Where-Object { [string]$_.AppId -eq 'firefox' })[0]
    Assert-BoostLabCondition (@($firefox.Artifacts).Count -eq 2) 'Firefox must retain source installer plus uBlock XPI artifacts.'
    foreach ($representative in @('discord', 'google-chrome', 'obs-studio', 'rockstar-games')) {
        $app = @($catalog | Where-Object { [string]$_.AppId -eq $representative })[0]
        $artifactText = (@($app.Artifacts | ForEach-Object { '{0}|{1}' -f $_.Url, $_.DestinationPath }) -join "`n")
        $commandText = (@($app.InstallerCommands | ForEach-Object { '{0}|{1}' -f $_.FilePath, $_.Arguments }) -join "`n")
        Assert-BoostLabContains -Text $artifactText -Needle 'https://' -Description "$representative artifact URL"
        Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace($commandText)) "$representative command descriptor is empty."
    }

    $seen = [System.Collections.Generic.List[object]]::new()
    $mockExecutor = {
        param($Operation, $App)
        $seen.Add([pscustomobject]@{
            AppId = [string]$App.AppId
            Operation = [string]$Operation.Label
        })
        [pscustomobject]@{
            Success = $true
            Message = 'mock operation completed'
            Operation = $Operation
            AppId = [string]$App.AppId
        }
    }
    $apply = & $module { Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed $true -SelectedAppIds @('steam', 'discord', 'google-chrome') -OperationExecutor $args[0] -SkipEnvironmentChecks } $mockExecutor
    Assert-BoostLabCondition ([bool]$apply.Success) 'Mocked Installers Apply should complete.'
    Assert-BoostLabCondition ([bool]$apply.ChangesExecuted) 'Mocked Apply should report changes executed.'
    Assert-BoostLabCondition (((@($apply.Data.Queue | ForEach-Object { [string]$_.AppId }) -join ',') -eq 'discord,google-chrome,steam')) 'Apply queue must follow source order, not selection order.'
    Assert-BoostLabCondition ([string]$apply.VerificationResult.Status -eq 'Passed') 'Apply verification should pass in mocked success path.'

    $seenAppOrder = @($seen | ForEach-Object { [string]$_.AppId })
    $firstSteamIndex = [Array]::IndexOf($seenAppOrder, 'steam')
    $lastDiscordIndex = [Array]::LastIndexOf($seenAppOrder, 'discord')
    $firstChromeIndex = [Array]::IndexOf($seenAppOrder, 'google-chrome')
    $lastChromeIndex = [Array]::LastIndexOf($seenAppOrder, 'google-chrome')
    Assert-BoostLabCondition ($lastDiscordIndex -lt $firstChromeIndex) 'Google Chrome must not start until Discord operations finish.'
    Assert-BoostLabCondition ($lastChromeIndex -lt $firstSteamIndex) 'Steam must not start until Google Chrome operations finish.'

    $failureSeen = [System.Collections.Generic.List[string]]::new()
    $failingExecutor = {
        param($Operation, $App)
        $failureSeen.Add([string]$App.AppId)
        if ([string]$App.AppId -eq 'google-chrome') {
            [pscustomobject]@{
                Success = $false
                Message = 'mock google chrome failure'
                Operation = $Operation
                AppId = [string]$App.AppId
            }
        }
        else {
            [pscustomobject]@{
                Success = $true
                Message = 'mock operation completed'
                Operation = $Operation
                AppId = [string]$App.AppId
            }
        }
    }
    $failedApply = & $module { Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed $true -SelectedAppIds @('discord', 'google-chrome', 'steam') -OperationExecutor $args[0] -SkipEnvironmentChecks } $failingExecutor
    Assert-BoostLabCondition (-not [bool]$failedApply.Success) 'Mocked failed Apply should fail closed.'
    Assert-BoostLabCondition ([string]$failedApply.Status -eq 'QueueStoppedAfterFailure') 'Failed Apply status mismatch.'
    Assert-BoostLabCondition ([string]$failedApply.Data.FailedApp.AppId -eq 'google-chrome') 'Failed app should be Google Chrome.'
    Assert-BoostLabCondition ('steam' -in @($failedApply.Data.RemainingApps | ForEach-Object { [string]$_.AppId })) 'Steam should remain not-started after Google Chrome failure.'
    Assert-BoostLabCondition ('steam' -notin @($failureSeen)) 'Failure path must not start remaining apps.'

    $invalid = & $module { Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed $true -SelectedAppIds @('nvidia-app') -OperationExecutor { throw 'should not execute' } -SkipEnvironmentChecks }
    Assert-BoostLabCondition (-not [bool]$invalid.Success) 'Removed app selection should fail closed.'
    Assert-BoostLabCondition ([string]$invalid.Status -eq 'InvalidSelection') 'Removed app selection should be invalid.'
    Assert-BoostLabCondition (-not [bool]$invalid.ChangesExecuted) 'Removed app selection must execute no changes.'

    $selectionRequired = & $module { Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed $true -SelectedAppIds @() -OperationExecutor { throw 'should not execute' } -SkipEnvironmentChecks }
    Assert-BoostLabCondition (-not [bool]$selectionRequired.Success) 'Apply without selection should not proceed.'
    Assert-BoostLabCondition ([string]$selectionRequired.Status -eq 'SelectionRequired') 'Apply without selection should request selection.'

    $default = & $module { Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed $true }
    Assert-BoostLabCondition (-not [bool]$default.Success) 'Default must remain unavailable.'
    Assert-BoostLabCondition ([string]$default.Status -eq 'DefaultUnavailable') 'Default status mismatch.'
    Assert-BoostLabContains -Text ([string]$default.Message) -Needle 'Default is not Restore' -Description 'Default message'

    $restore = & $module { Invoke-BoostLabToolAction -ActionName 'Restore' -Confirmed $true }
    Assert-BoostLabCondition (-not [bool]$restore.Success) 'Restore must remain unavailable.'
    Assert-BoostLabCondition ([string]$restore.Status -eq 'RestoreUnavailable') 'Restore status mismatch.'
    Assert-BoostLabContains -Text ([string]$restore.Message) -Needle 'without selected captured' -Description 'Restore message'
}
finally {
    Remove-Module $module -Force -ErrorAction SilentlyContinue
}

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
foreach ($needle in @(
    'checkbox multi-select queue model',
    'Run the selected retained Installers app queue one app at a time',
    'Process selected apps sequentially in retained source order',
    'Removed app choices are hidden and cannot be selected'
)) {
    Assert-BoostLabContains -Text $actionPlanText -Needle $needle -Description 'Installers Action Plan'
}
Assert-BoostLabCondition (-not $actionPlanText.Contains('Auto mode is blocked for Installers because per-app artifact provenance')) 'Installers Apply Action Plan must not remain ManualHandoffOnly blocked wording.'
Assert-BoostLabCondition (-not $actionPlanText.Contains("'Manual Handoff'")) 'Action Plan ValidateSet must not include display labels.'
Assert-BoostLabCondition (-not $actionPlanText.Contains("'Apply Auto'")) 'Action Plan ValidateSet must not include display labels.'

$executionText = Get-Content -LiteralPath $executionPath -Raw
Assert-BoostLabContains -Text $executionText -Needle 'ActionOptions' -Description 'Execution selected action options bridge'
Assert-BoostLabContains -Text $executionText -Needle '$actionCommand.Parameters.ContainsKey([string]$optionName)' -Description 'Execution generic action-options bridge'

$uiText = Get-Content -LiteralPath $uiPath -Raw
foreach ($needle in @(
    'SelectionMode',
    'System.Windows.Controls.CheckBox',
    'SelectedAppIds',
    'Get-BoostLabToolCardActionOptions'
)) {
    Assert-BoostLabContains -Text $uiText -Needle $needle -Description 'Installers UI multi-select support'
}

$artifactText = Get-Content -LiteralPath $artifactPath -Raw
$allowlistText = Get-Content -LiteralPath $allowlistPath -Raw
Assert-BoostLabCondition (-not $artifactText.Contains('installers')) 'Artifact provenance config must not approve Installers artifacts in Phase 119.'
Assert-BoostLabCondition (-not $allowlistText.Contains('installers')) 'Production allowlist config must not approve Installers scopes in Phase 119.'

$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$installersRecord = @($parityBaseline.Tools | Where-Object { [string]$_['ToolId'] -eq 'installers' })[0]
Assert-BoostLabCondition ([string]$installersRecord['ImplementationLevel'] -eq 'ControlledSubset') 'Installers parity implementation level must be ControlledSubset.'
Assert-BoostLabCondition ([string]$installersRecord['UltimateParity'] -eq 'Partial') 'Installers UltimateParity must be Partial.'
Assert-BoostLabCondition ([bool]$installersRecord['YazanFinalException']) 'Installers must record Yazan final app-list exception.'
Assert-BoostLabCondition ([bool]$installersRecord['YazanAcceptedNearParity']) 'Installers must record Yazan-accepted retained-app near parity.'
Assert-BoostLabCondition ([string]$installersRecord['FinalProgressStatus'] -eq 'YazanFinalException') 'Installers final progress status mismatch.'
Assert-BoostLabContains -Text ([string]$installersRecord['GapSummary']) -Needle '11 Frame View' -Description 'Installers parity gap summary'

$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ([string]$nextTarget['ToolId'] -eq 'driver-install-latest') 'First pending ordered parity target should advance past Driver Install Debloat & Settings near-parity acceptance.'

$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
Assert-BoostLabCondition ([int]$categoryCounts['ControlledSubset'] -eq [int]$parityBaseline.Counts.ControlledSubset) 'ControlledSubset count mismatch.'
Assert-BoostLabCondition ([int]$categoryCounts['ManualHandoffOnly'] -eq [int]$parityBaseline.Counts.ManualHandoffOnly) 'ManualHandoffOnly count mismatch.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.ControlledSubset -eq 3) 'ControlledSubset baseline count should be 3 after Installers.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.ManualHandoffOnly -eq 5) 'ManualHandoffOnly baseline count should be 5 after Driver Install Debloat & Settings.'
Assert-BoostLabCondition (-not [bool]$parityBaseline.DesignSystemReady) 'Design System readiness must remain false.'

$inventory = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
Assert-BoostLabCondition ([int]$inventory.Baseline.ActiveTools -eq 55) 'Active tool count must remain 55.'
Assert-BoostLabCondition ([int]$inventory.Baseline.ImplementedTools -eq 45) 'Runtime implemented tool count must remain 45.'
Assert-BoostLabCondition ([int]$inventory.Baseline.DeferredPlaceholders -eq 10) 'Deferred/placeholders count must remain 10.'

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceManifestLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
    Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
    Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
    ForEach-Object {
        '{0}|{1}' -f $_.FullName.Substring($root.Length + 1).Replace('\', '/'), (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    }
$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $sourceManifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceManifestLines -join "`n")))
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}
Assert-BoostLabCondition (@($sourceManifestLines).Count -eq 49) "source-ultimate file count changed: $(@($sourceManifestLines).Count)"
Assert-BoostLabCondition ($sourceManifestHash -eq '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') 'source-ultimate content or paths changed.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }).Count -eq 0) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    TestName              = 'Installers ordered parity upgrade with Yazan multi-select scope'
    SourceHash            = $actualSourceHash
    RetainedAppCount      = 17
    RetainedArtifactCount = 18
    ImplementationLevel   = [string]$installersRecord['ImplementationLevel']
    FinalProgressStatus   = [string]$installersRecord['FinalProgressStatus']
    NextOrderedTarget     = [string]$nextTarget['ToolId']
}
