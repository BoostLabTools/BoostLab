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
    9 = 'Escape From Tarkov'
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
Assert-BoostLabCondition ([string]$installersTool.SelectionMode -eq 'SingleSelect') 'Installers must declare single-select mode.'
Assert-BoostLabCondition ([string]$installersTool.SelectionLabel -eq 'Select exactly one app to install') 'Installers selection label must require one app.'
Assert-BoostLabCondition ('Apply' -in @($installersTool.SelectionRequiredActions)) 'Installers Apply must require one selected app ID.'

$selectionItems = @($installersTool.SelectionItems)
$expectedRetainedIds = @(
    'discord'
    'roblox'
    'seven-zip'
    'battle-net'
    'brave'
    'electronic-arts'
    'epic-games'
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
Assert-BoostLabCondition ($selectionItems.Count -eq 16) "Expected 16 retained visible selection items after Tarkov removal, found $($selectionItems.Count)."
Assert-BoostLabCondition (((@($selectionItems | ForEach-Object { [string]$_['Id'] }) -join ',') -eq ($expectedRetainedIds -join ','))) 'Retained Installers selection order must match source order after Yazan exclusions.'
foreach ($removedId in @('escape-from-tarkov', 'frame-view', 'gog-launcher', 'notepad-plus-plus', 'nvidia-app', 'onboard-memory-manager', 'pot-player')) {
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
    Assert-BoostLabCondition ([string]$info.SelectionMode -eq 'SingleSelect') 'Module info must expose SingleSelect selection mode.'
    Assert-BoostLabCondition ([string]$info.SelectionLabel -eq 'Select exactly one app to install') 'Module info selection label mismatch.'
    Assert-BoostLabCondition (@($info.SelectionItems).Count -eq 16) 'Module info must expose 16 retained selection items after Tarkov removal.'

    $analyze = & $module { Invoke-BoostLabToolAction -ActionName 'Analyze' }
    Assert-BoostLabCondition ([bool]$analyze.Success) 'Installers Analyze should succeed.'
    Assert-BoostLabCondition ([string]$analyze.Data.Mode -eq 'SingleSelectedAppInstall') 'Analyze mode mismatch.'
    Assert-BoostLabCondition ([string]$analyze.Data.SelectionModel -eq 'SingleSelect') 'Analyze selection model mismatch.'
    Assert-BoostLabCondition ([int]$analyze.Data.RetainedAppCount -eq 16) 'Analyze retained app count mismatch after Tarkov removal.'
    Assert-BoostLabCondition ([int]$analyze.Data.RetainedArtifactCount -eq 17) 'Analyze retained artifact count mismatch after Tarkov removal.'
    Assert-BoostLabCondition ([bool]$analyze.Data.NoMutationOccurred) 'Analyze must be read-only.'
    Assert-BoostLabCondition ([bool]$analyze.Data.RemovedMenuMappingValid) 'Removed menu mapping must be valid.'

    $catalog = @(& $module { Get-BoostLabInstallersCatalog })
    Assert-BoostLabCondition ($catalog.Count -eq 16) 'Module catalog must include every retained app and no removed apps after Tarkov removal.'
    Assert-BoostLabCondition (((@($catalog | ForEach-Object { [string]$_.AppId }) -join ',') -eq ($expectedRetainedIds -join ','))) 'Module catalog source order mismatch.'
    Assert-BoostLabCondition ('escape-from-tarkov' -notin @($catalog | ForEach-Object { [string]$_.AppId })) 'Escape From Tarkov must not remain in the retained Installers catalog.'
    Assert-BoostLabCondition (@($catalog | ForEach-Object { $_.Artifacts } | Where-Object { [string]$_.Url -like '*escapefromtarkov*' }).Count -eq 0) 'Escape From Tarkov download URL must not remain in retained Installers artifacts.'
    foreach ($app in $catalog) {
        Assert-BoostLabCondition (@($app.Artifacts).Count -ge 1) "Retained app missing artifact descriptor: $($app.AppId)"
        Assert-BoostLabCondition (@($app.InstallerCommands).Count -ge 1) "Retained app missing installer/helper descriptor: $($app.AppId)"
        Assert-BoostLabCondition (@($app.Operations).Count -ge 2) "Retained app missing operation plan: $($app.AppId)"
        Assert-BoostLabCondition (@($app.SideEffectFamilies).Count -ge 1) "Retained app missing side-effect families: $($app.AppId)"

        foreach ($artifact in @($app.Artifacts)) {
            $artifactId = & $module { Get-BoostLabInstallersOfficialArtifactIdForUrl -Url $args[0] } ([string]$artifact.Url)
            Assert-BoostLabCondition ([string]$artifactId -like 'installers-*') "Installers artifact URL is not mapped to an OfficialVendorDirect policy id: $($artifact.Url)"
        }
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

    $discordSeen = [System.Collections.Generic.List[object]]::new()
    $mockExecutor = {
        param($Operation, $App)
        $discordSeen.Add([pscustomobject]@{
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
    $apply = & $module { Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed $true -SelectedAppIds @('discord') -OperationExecutor $args[0] -SkipEnvironmentChecks } $mockExecutor
    Assert-BoostLabCondition ([bool]$apply.Success) 'Mocked Installers Apply should complete for exactly one selected app.'
    Assert-BoostLabCondition ([bool]$apply.ChangesExecuted) 'Mocked single-app Apply should report changes executed.'
    Assert-BoostLabCondition ([string]$apply.Data.SelectedApp.AppId -eq 'discord') 'Apply should record Discord as the selected app.'
    Assert-BoostLabCondition ([string]$apply.Data.CompletedApp.AppId -eq 'discord') 'Apply should record Discord as the completed app.'
    Assert-BoostLabCondition ($null -eq $apply.Data.FailedApp) 'Successful single-app Apply must not report a failed app.'
    Assert-BoostLabCondition (((@($apply.Data.OperationResults | ForEach-Object { [string]$_.AppId }) | Sort-Object -Unique) -join ',') -eq 'discord') 'Discord-only run must not execute other apps.'
    Assert-BoostLabCondition (((@($apply.Data.Queue | ForEach-Object { [string]$_.AppId }) -join ',') -eq 'discord')) 'Legacy diagnostic queue must contain only the selected app.'
    Assert-BoostLabCondition (@($apply.Data.RemainingApps).Count -eq 0) 'Single-app mode must not report remaining queued apps.'
    Assert-BoostLabCondition ([string]$apply.VerificationResult.Status -eq 'Passed') 'Apply verification should pass in mocked success path.'

    $branchSelectionSeen = [System.Collections.Generic.List[string]]::new()
    $branchSelectionExecutor = {
        param($Operation, $App)
        $branchSelectionSeen.Add([string]$App.AppId)
        [pscustomobject]@{
            Success = $true
            Message = 'mock operation completed'
            Operation = $Operation
            AppId = [string]$App.AppId
        }
    }
    $branchSelectionApply = & $module { Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed $true -Branch 'seven-zip' -OperationExecutor $args[0] -SkipEnvironmentChecks } $branchSelectionExecutor
    Assert-BoostLabCondition ([bool]$branchSelectionApply.Success) 'SingleSelect Branch option should run the selected Installers app.'
    Assert-BoostLabCondition ([string]$branchSelectionApply.Data.SelectedApp.AppId -eq 'seven-zip') 'Branch-selected Installers Apply should select 7-Zip.'
    Assert-BoostLabCondition (((@($branchSelectionSeen) | Sort-Object -Unique) -join ',') -eq 'seven-zip') 'Branch-selected Installers Apply must not execute unrelated apps.'

    $multiSelection = & $module { Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed $true -SelectedAppIds @('discord', 'seven-zip') -OperationExecutor { throw 'side effects should not start for multi-select' } -SkipEnvironmentChecks }
    Assert-BoostLabCondition (-not [bool]$multiSelection.Success) 'Selecting more than one installer app must fail closed.'
    Assert-BoostLabCondition ([string]$multiSelection.Status -eq 'SelectionRequired') 'Multi-selection should be blocked as a selection precondition.'
    Assert-BoostLabCondition (-not [bool]$multiSelection.ChangesExecuted) 'Multi-selection must execute no side effects.'
    Assert-BoostLabContains -Text ([string]$multiSelection.Message) -Needle 'exactly one' -Description 'Installers multi-selection validation message'

    $activeSetupProbe = & $module {
        $removedKeys = [System.Collections.Generic.List[string]]::new()
        $successKeys = @(
            [pscustomobject]@{ PSPath = 'Registry::HKLM\Mock\ActiveSetup\BraveMatch'; Name = 'BraveMatch'; MockDefaultValue = 'Brave Browser' }
            [pscustomobject]@{ PSPath = 'Registry::HKLM\Mock\ActiveSetup\ChromeNoMatch'; Name = 'ChromeNoMatch'; MockDefaultValue = 'Chrome Browser' }
            [pscustomobject]@{ PSPath = 'Registry::HKLM\Mock\ActiveSetup\MissingDefault'; Name = 'MissingDefault' }
        )
        $failureKeys = @(
            [pscustomobject]@{ PSPath = 'Registry::HKLM\Mock\ActiveSetup\BraveRemoveFailure'; Name = 'BraveRemoveFailure'; MockDefaultValue = 'Brave Browser' }
        )

        $reader = {
            param($Key)
            if ($null -ne $Key.PSObject.Properties['MockDefaultValue']) {
                return [string]$Key.MockDefaultValue
            }
            return $null
        }
        $remover = {
            param($Key)
            if ([string]$Key.PSPath -like '*RemoveFailure') {
                throw 'Mock Active Setup removal failure.'
            }
            $removedKeys.Add([string]$Key.PSPath)
        }.GetNewClosure()

        $success = Invoke-BoostLabInstallersActiveSetupDefaultMatchRemoval `
            -Path 'HKLM:\Mock\ActiveSetup' `
            -Pattern '*Brave*' `
            -KeyEnumerator { param($Path) $successKeys }.GetNewClosure() `
            -DefaultValueReader $reader `
            -KeyRemover $remover
        $failure = Invoke-BoostLabInstallersActiveSetupDefaultMatchRemoval `
            -Path 'HKLM:\Mock\ActiveSetup' `
            -Pattern '*Brave*' `
            -KeyEnumerator { param($Path) $failureKeys }.GetNewClosure() `
            -DefaultValueReader $reader `
            -KeyRemover $remover

        [pscustomobject]@{
            Success = $success
            Failure = $failure
            RemovedKeys = $removedKeys.ToArray()
        }
    }
    Assert-BoostLabCondition ([bool]$activeSetupProbe.Success.Success) 'Active Setup cleanup should succeed when matching, non-matching, and missing-default keys are inspected.'
    Assert-BoostLabCondition ([int]$activeSetupProbe.Success.InspectedCount -eq 3) 'Active Setup cleanup inspected count mismatch.'
    Assert-BoostLabCondition ([int]$activeSetupProbe.Success.MatchedCount -eq 1) 'Active Setup cleanup should match only Brave default values.'
    Assert-BoostLabCondition ([int]$activeSetupProbe.Success.RemovedCount -eq 1) 'Active Setup cleanup should remove matching Brave key.'
    Assert-BoostLabCondition ([int]$activeSetupProbe.Success.NoMatchCount -eq 1) 'Active Setup cleanup should keep non-matching default values.'
    Assert-BoostLabCondition ([int]$activeSetupProbe.Success.MissingDefaultCount -eq 1) 'Active Setup cleanup should treat missing default values as no-match/absent.'
    Assert-BoostLabCondition ('Registry::HKLM\Mock\ActiveSetup\BraveMatch' -in @($activeSetupProbe.RemovedKeys)) 'Active Setup cleanup did not remove the matching Brave key.'
    Assert-BoostLabCondition (-not [bool]$activeSetupProbe.Failure.Success) 'Active Setup removal failure must fail closed.'
    Assert-BoostLabCondition ([int]$activeSetupProbe.Failure.FailureCount -eq 1) 'Active Setup removal failure count mismatch.'
    Assert-BoostLabContains -Text ((@($activeSetupProbe.Failure.Failures) -join '; ')) -Needle 'Mock Active Setup removal failure.' -Description 'Active Setup removal failure'

    $displayNameUninstallProbe = & $module {
        $uninstallArguments = [System.Collections.Generic.List[string]]::new()
        $mixedEntries = @(
            [pscustomobject]@{ PSPath = 'Registry::HKLM\Mock\Uninstall\NoDisplayName'; PSChildName = '{NO-DISPLAY}' }
            [pscustomobject]@{ PSPath = 'Registry::HKLM\Mock\Uninstall\NullDisplayName'; PSChildName = '{NULL-DISPLAY}'; DisplayName = $null }
            [pscustomobject]@{ PSPath = 'Registry::HKLM\Mock\Uninstall\EmptyDisplayName'; PSChildName = '{EMPTY-DISPLAY}'; DisplayName = '' }
            [pscustomobject]@{ PSPath = 'Registry::HKLM\Mock\Uninstall\EpicLauncher'; PSChildName = '{EPIC-LAUNCHER}'; DisplayName = 'Epic Games Launcher' }
            [pscustomobject]@{ PSPath = 'Registry::HKLM\Mock\Uninstall\EpicOnlineServices'; PSChildName = '{EPIC-ONLINE-SERVICES}'; DisplayName = 'Epic Online Services' }
        )
        $noMatchEntries = @(
            [pscustomobject]@{ PSPath = 'Registry::HKLM\Mock\Uninstall\NoDisplayName'; PSChildName = '{NO-DISPLAY}' }
            [pscustomobject]@{ PSPath = 'Registry::HKLM\Mock\Uninstall\EpicLauncher'; PSChildName = '{EPIC-LAUNCHER}'; DisplayName = 'Epic Games Launcher' }
        )
        $failureEntries = @(
            [pscustomobject]@{ PSPath = 'Registry::HKLM\Mock\Uninstall\EpicOnlineServices'; PSChildName = '{EPIC-ONLINE-SERVICES}'; DisplayName = 'Epic Online Services' }
        )
        $uninstaller = {
            param($Entry, $ArgumentList)
            $uninstallArguments.Add([string]$ArgumentList)
        }.GetNewClosure()
        $failingUninstaller = {
            param($Entry, $ArgumentList)
            throw 'Mock Epic Online Services uninstall failure.'
        }

        $success = Invoke-BoostLabInstallersDisplayNameUninstall `
            -RegistryPath 'HKLM:\Mock\Uninstall\*' `
            -DisplayNameLike '*Epic Online Services*' `
            -Arguments '/x {0} /qn' `
            -EntryEnumerator { param($Path) $mixedEntries }.GetNewClosure() `
            -Uninstaller $uninstaller
        $noMatch = Invoke-BoostLabInstallersDisplayNameUninstall `
            -RegistryPath 'HKLM:\Mock\Uninstall\*' `
            -DisplayNameLike '*Epic Online Services*' `
            -Arguments '/x {0} /qn' `
            -EntryEnumerator { param($Path) $noMatchEntries }.GetNewClosure() `
            -Uninstaller $uninstaller
        $failure = Invoke-BoostLabInstallersDisplayNameUninstall `
            -RegistryPath 'HKLM:\Mock\Uninstall\*' `
            -DisplayNameLike '*Epic Online Services*' `
            -Arguments '/x {0} /qn' `
            -EntryEnumerator { param($Path) $failureEntries }.GetNewClosure() `
            -Uninstaller $failingUninstaller

        [pscustomobject]@{
            Success = $success
            NoMatch = $noMatch
            Failure = $failure
            UninstallArguments = $uninstallArguments.ToArray()
        }
    }
    Assert-BoostLabCondition ([bool]$displayNameUninstallProbe.Success.Success) 'Display-name uninstall should succeed with missing, null, empty, non-matching, and one matching entry.'
    Assert-BoostLabCondition ([int]$displayNameUninstallProbe.Success.InspectedCount -eq 5) 'Display-name uninstall inspected count mismatch.'
    Assert-BoostLabCondition ([int]$displayNameUninstallProbe.Success.MissingDisplayNameCount -eq 3) 'Missing/null/empty DisplayName entries should be counted as missing display names.'
    Assert-BoostLabCondition ([int]$displayNameUninstallProbe.Success.NoMatchCount -eq 1) 'Non-matching DisplayName entries should be counted as no-match.'
    Assert-BoostLabCondition ([int]$displayNameUninstallProbe.Success.MatchedCount -eq 1) 'Epic Online Services should be the only display-name match.'
    Assert-BoostLabCondition ([int]$displayNameUninstallProbe.Success.UninstallAttemptedCount -eq 1) 'One matching uninstall should be attempted.'
    Assert-BoostLabCondition ([int]$displayNameUninstallProbe.Success.UninstallSucceededCount -eq 1) 'One matching uninstall should succeed.'
    Assert-BoostLabCondition ('/x {EPIC-ONLINE-SERVICES} /qn' -in @($displayNameUninstallProbe.UninstallArguments)) 'Epic Online Services uninstall arguments should use the matched PSChildName.'
    Assert-BoostLabCondition ([bool]$displayNameUninstallProbe.NoMatch.Success) 'No matching uninstall entries should be a no-op success, not a crash.'
    Assert-BoostLabCondition ([int]$displayNameUninstallProbe.NoMatch.UninstallAttemptedCount -eq 0) 'No-match display-name cleanup must not attempt an uninstall.'
    Assert-BoostLabCondition (-not [bool]$displayNameUninstallProbe.Failure.Success) 'Matching display-name uninstall failure must fail closed.'
    Assert-BoostLabCondition ([int]$displayNameUninstallProbe.Failure.FailureCount -eq 1) 'Display-name uninstall failure count mismatch.'
    Assert-BoostLabContains -Text ((@($displayNameUninstallProbe.Failure.FailureEntries) -join '; ')) -Needle 'Mock Epic Online Services uninstall failure.' -Description 'Display-name uninstall failure'

    $braveObsSeen = [System.Collections.Generic.List[string]]::new()
    $braveObsExecutor = {
        param($Operation, $App)
        $braveObsSeen.Add(('{0}|{1}' -f [string]$App.AppId, [string]$Operation.Type))
        $details = $null
        if ([string]$App.AppId -eq 'brave' -and [string]$Operation.Type -eq 'RemoveActiveSetupByDefaultMatch') {
            $details = [pscustomobject]@{
                Success = $true
                InspectedCount = 1
                MatchedCount = 0
                RemovedCount = 0
                MissingDefaultCount = 1
                NoMatchCount = 0
                FailureCount = 0
                MissingDefaultKeys = @('Registry::HKLM\Mock\ActiveSetup\MissingDefault')
            }
        }
        [pscustomobject]@{
            Success = $true
            Message = 'mock operation completed'
            Operation = $Operation
            AppId = [string]$App.AppId
            Details = $details
        }
    }
    $braveObsApply = & $module { Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed $true -SelectedAppIds @('brave') -OperationExecutor $args[0] -SkipEnvironmentChecks } $braveObsExecutor
    Assert-BoostLabCondition ([bool]$braveObsApply.Success) 'Installers should complete a Brave-only run after Active Setup cleanup with missing default values.'
    Assert-BoostLabCondition (((@($braveObsSeen | ForEach-Object { ([string]$_).Split('|')[0] }) | Sort-Object -Unique) -join ',') -eq 'brave') 'Brave-only run must not execute another installer app.'
    $braveActiveSetupResult = @($braveObsApply.Data.OperationResults | Where-Object { [string]$_.AppId -eq 'brave' -and [string]$_.Operation.Type -eq 'RemoveActiveSetupByDefaultMatch' })[0]
    Assert-BoostLabCondition ([int]$braveActiveSetupResult.Details.MissingDefaultCount -eq 1) 'Brave Active Setup result should report missing default values as non-fatal details.'

    $epicObsSeen = [System.Collections.Generic.List[string]]::new()
    $epicObsExecutor = {
        param($Operation, $App)
        $epicObsSeen.Add(('{0}|{1}' -f [string]$App.AppId, [string]$Operation.Type))
        $details = $null
        if ([string]$App.AppId -eq 'epic-games' -and [string]$Operation.Type -eq 'UninstallByDisplayName') {
            $details = [pscustomobject]@{
                Success = $true
                RegistryPath = 'HKLM:\Mock\Uninstall\*'
                DisplayNameLike = '*Epic Online Services*'
                InspectedCount = 3
                MissingDisplayNameCount = 2
                NoMatchCount = 1
                MatchedCount = 0
                UninstallAttemptedCount = 0
                UninstallSucceededCount = 0
                FailureCount = 0
                MissingDisplayNameSamples = @('Registry::HKLM\Mock\Uninstall\NoDisplayName', 'Registry::HKLM\Mock\Uninstall\EmptyDisplayName')
            }
        }
        [pscustomobject]@{
            Success = $true
            Message = 'mock operation completed'
            Operation = $Operation
            AppId = [string]$App.AppId
            Details = $details
        }
    }
    $epicObsApply = & $module { Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed $true -SelectedAppIds @('epic-games') -OperationExecutor $args[0] -SkipEnvironmentChecks } $epicObsExecutor
    Assert-BoostLabCondition ([bool]$epicObsApply.Success) 'Installers should complete an Epic Games-only run after Epic Online Services cleanup when uninstall entries have no DisplayName but no real failure occurs.'
    Assert-BoostLabCondition (((@($epicObsSeen | ForEach-Object { ([string]$_).Split('|')[0] }) | Sort-Object -Unique) -join ',') -eq 'epic-games') 'Epic Games-only run must not execute another installer app.'
    $epicUninstallResult = @($epicObsApply.Data.OperationResults | Where-Object { [string]$_.AppId -eq 'epic-games' -and [string]$_.Operation.Type -eq 'UninstallByDisplayName' })[0]
    Assert-BoostLabCondition ([int]$epicUninstallResult.Details.MissingDisplayNameCount -eq 2) 'Epic Online Services cleanup should report missing DisplayName entries as non-fatal details.'
    Assert-BoostLabCondition ([int]$epicUninstallResult.Details.UninstallAttemptedCount -eq 0) 'Epic Online Services cleanup should not attempt uninstall when no matching DisplayName exists.'

    $epicFailureSeen = [System.Collections.Generic.List[string]]::new()
    $epicFailingExecutor = {
        param($Operation, $App)
        $epicFailureSeen.Add(('{0}|{1}' -f [string]$App.AppId, [string]$Operation.Type))
        if ([string]$App.AppId -eq 'epic-games' -and [string]$Operation.Type -eq 'UninstallByDisplayName') {
            return [pscustomobject]@{
                Success = $false
                Message = 'mock Epic Online Services uninstall failure'
                Operation = $Operation
                AppId = [string]$App.AppId
            }
        }
        [pscustomobject]@{
            Success = $true
            Message = 'mock operation completed'
            Operation = $Operation
            AppId = [string]$App.AppId
        }
    }
    $epicFailedApply = & $module { Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed $true -SelectedAppIds @('epic-games') -OperationExecutor $args[0] -SkipEnvironmentChecks } $epicFailingExecutor
    Assert-BoostLabCondition (-not [bool]$epicFailedApply.Success) 'Epic Online Services real uninstall failure should fail closed.'
    Assert-BoostLabCondition ([string]$epicFailedApply.Status -eq 'SelectedAppFailed') 'Epic Online Services failure status mismatch.'
    Assert-BoostLabCondition ([string]$epicFailedApply.Data.FailedApp.AppId -eq 'epic-games') 'Failed app should be Epic Games.'
    Assert-BoostLabCondition (((@($epicFailureSeen | ForEach-Object { ([string]$_).Split('|')[0] }) | Sort-Object -Unique) -join ',') -eq 'epic-games') 'Epic Games failure path must not execute another installer app.'

    $sevenZipFailureSeen = [System.Collections.Generic.List[string]]::new()
    $sevenZipFailingExecutor = {
        param($Operation, $App)
        $sevenZipFailureSeen.Add([string]$App.AppId)
        if ([string]$App.AppId -eq 'seven-zip') {
            [pscustomobject]@{
                Success = $false
                Message = 'mock seven zip verification failure'
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
    $sevenZipFailedApply = & $module { Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed $true -SelectedAppIds @('seven-zip') -OperationExecutor $args[0] -SkipEnvironmentChecks } $sevenZipFailingExecutor
    Assert-BoostLabCondition (-not [bool]$sevenZipFailedApply.Success) 'Mocked 7-Zip failure should fail closed.'
    Assert-BoostLabCondition ([string]$sevenZipFailedApply.Status -eq 'SelectedAppFailed') '7-Zip failure status mismatch.'
    Assert-BoostLabCondition ([string]$sevenZipFailedApply.Data.FailedApp.AppId -eq 'seven-zip') 'Failed app should be 7-Zip.'
    Assert-BoostLabCondition (((@($sevenZipFailureSeen) | Sort-Object -Unique) -join ',') -eq 'seven-zip') '7-Zip failure path must not execute another installer app.'

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
    $failedApply = & $module { Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed $true -SelectedAppIds @('google-chrome') -OperationExecutor $args[0] -SkipEnvironmentChecks } $failingExecutor
    Assert-BoostLabCondition (-not [bool]$failedApply.Success) 'Mocked failed Apply should fail closed.'
    Assert-BoostLabCondition ([string]$failedApply.Status -eq 'SelectedAppFailed') 'Failed Apply status mismatch.'
    Assert-BoostLabCondition ([string]$failedApply.Data.FailedApp.AppId -eq 'google-chrome') 'Failed app should be Google Chrome.'
    Assert-BoostLabCondition (@($failedApply.Data.RemainingApps).Count -eq 0) 'Single-app failure must not report queued remaining apps.'
    Assert-BoostLabCondition (((@($failureSeen) | Sort-Object -Unique) -join ',') -eq 'google-chrome') 'Failure path must only start the selected app.'

    $invalid = & $module { Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed $true -SelectedAppIds @('escape-from-tarkov') -OperationExecutor { throw 'should not execute' } -SkipEnvironmentChecks }
    Assert-BoostLabCondition (-not [bool]$invalid.Success) 'Removed app selection should fail closed.'
    Assert-BoostLabCondition ([string]$invalid.Status -eq 'InvalidSelection') 'Removed app selection should be invalid.'
    Assert-BoostLabCondition (-not [bool]$invalid.ChangesExecuted) 'Removed app selection must execute no changes.'

    $selectionRequired = & $module { Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed $true -SelectedAppIds @() -OperationExecutor { throw 'should not execute' } -SkipEnvironmentChecks }
    Assert-BoostLabCondition (-not [bool]$selectionRequired.Success) 'Apply without selection should not proceed.'
    Assert-BoostLabCondition ([string]$selectionRequired.Status -eq 'SelectionRequired') 'Apply without selection should request selection.'
    Assert-BoostLabContains -Text ([string]$selectionRequired.Message) -Needle 'exactly one' -Description 'Installers zero-selection validation message'

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
    'single-app Apply model',
    'Run exactly one selected retained Installers app',
    'Run only the selected app; do not process a multi-app queue',
    'Removed app choices are hidden and cannot be selected'
)) {
    Assert-BoostLabContains -Text $actionPlanText -Needle $needle -Description 'Installers Action Plan'
}
Assert-BoostLabCondition (-not $actionPlanText.Contains('checkbox multi-select queue model')) 'Installers Action Plan must not describe the old checkbox multi-select queue model.'

$moduleText = Get-Content -LiteralPath $modulePath -Raw
Assert-BoostLabContains -Text $moduleText -Needle 'Invoke-BoostLabOfficialVendorDownload' -Description 'Installers official source runtime verification'
Assert-BoostLabContains -Text $moduleText -Needle 'Get-BoostLabInstallersOfficialArtifactIdForUrl' -Description 'Installers official artifact id mapping'
Assert-BoostLabContains -Text $moduleText -Needle 'Installers download URL is not in the official vendor runtime policy map' -Description 'Installers unknown official source fail-closed handling'
Assert-BoostLabCondition (-not $actionPlanText.Contains('Auto mode is blocked for Installers because per-app artifact provenance')) 'Installers Apply Action Plan must not remain ManualHandoffOnly blocked wording.'
Assert-BoostLabCondition (-not $actionPlanText.Contains("'Manual Handoff'")) 'Action Plan ValidateSet must not include display labels.'
Assert-BoostLabCondition (-not $actionPlanText.Contains("'Apply Auto'")) 'Action Plan ValidateSet must not include display labels.'

$executionText = Get-Content -LiteralPath $executionPath -Raw
Assert-BoostLabContains -Text $executionText -Needle 'ActionOptions' -Description 'Execution selected action options bridge'
Assert-BoostLabContains -Text $executionText -Needle '$actionCommand.Parameters.ContainsKey([string]$optionName)' -Description 'Execution generic action-options bridge'

$uiText = Get-Content -LiteralPath $uiPath -Raw
foreach ($needle in @(
    'SelectionMode',
    'System.Windows.Controls.RadioButton',
    '$options[''Branch'']',
    'Get-BoostLabToolCardActionOptions'
)) {
    Assert-BoostLabContains -Text $uiText -Needle $needle -Description 'Installers UI single-select support'
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
Assert-BoostLabCondition ([string]$nextTarget['ToolId'] -eq [string]$parityBaseline.CurrentOrderedParityTarget) 'Next ordered parity target must match the central parity baseline cursor.'

$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
Assert-BoostLabCondition ([int]$categoryCounts['ControlledSubset'] -eq [int]$parityBaseline.Counts.ControlledSubset) 'ControlledSubset count mismatch.'
Assert-BoostLabCondition ([int]$categoryCounts['ManualHandoffOnly'] -eq [int]$parityBaseline.Counts.ManualHandoffOnly) 'ManualHandoffOnly count mismatch.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.ControlledSubset -eq [int]$parityBaseline.Counts.ControlledSubset) 'ControlledSubset baseline count should be 3 after Graphics Configuration Center parity acceptance.'
Assert-BoostLabCondition (-not [bool]$parityBaseline.DesignSystemReady) 'Design System readiness must remain false.'

$inventory = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
Assert-BoostLabCondition ([int]$inventory.Snapshot.ActiveTools -eq [int]$inventory.Baseline.ActiveTools) 'Active tool count must match the central baseline.'
Assert-BoostLabCondition ([int]$inventory.Snapshot.ImplementedTools -eq [int]$inventory.Baseline.ImplementedTools) 'Runtime implemented tool count must match the central baseline.'
Assert-BoostLabCondition ([int]$inventory.Snapshot.DeferredPlaceholders -eq [int]$inventory.Baseline.DeferredPlaceholders) 'Deferred/placeholders count must match the central baseline.'

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
    TestName              = 'Installers single-app Apply contract'
    SourceHash            = $actualSourceHash
    RetainedAppCount      = 16
    RetainedArtifactCount = 17
    ImplementationLevel   = [string]$installersRecord['ImplementationLevel']
    FinalProgressStatus   = [string]$installersRecord['FinalProgressStatus']
    NextOrderedTarget     = [string]$nextTarget['ToolId']
}


