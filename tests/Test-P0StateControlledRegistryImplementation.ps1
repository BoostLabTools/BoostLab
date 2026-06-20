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
        throw 'Unable to determine the P0 State validator path.'
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

function Get-BoostLabItemCount {
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return 0
    }

    return @($Value).Count
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Graphics\p0-state.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate\5 Graphics\6 P0 State.ps1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$parityPath = Join-Path $ProjectRoot 'config\ParityStatusBaseline.psd1'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourcePromotedRoot = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate'

foreach ($path in @(
    $configPath,
    $modulePath,
    $sourcePath,
    $executionPath,
    $actionPlanPath,
    $uiPath,
    $parityPath,
    $artifactPath,
    $productionAllowlistPath
)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required file missing: $path"
}

$expectedSourceHash = '382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "P0 State source mirror hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."

$config = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })
$graphicsStage = @($config.Stages | Where-Object { $_.Name -eq 'Graphics' })[0]
Assert-BoostLabCondition ($null -ne $graphicsStage) 'Graphics stage was not found.'

$driverCleanTool = @($graphicsStage.Tools | Where-Object { $_.Id -eq 'driver-clean' })[0]
$driverInstallLatestTool = @($graphicsStage.Tools | Where-Object { $_.Id -eq 'driver-install-latest' })[0]
$nvidiaSettingsTool = @($graphicsStage.Tools | Where-Object { $_.Id -eq 'nvidia-settings' })[0]
$hdcpTool = @($graphicsStage.Tools | Where-Object { $_.Id -eq 'hdcp' })[0]
$p0StateTool = @($graphicsStage.Tools | Where-Object { $_.Id -eq 'p0-state' })[0]
$msiModeTool = @($graphicsStage.Tools | Where-Object { $_.Id -eq 'msi-mode' })[0]
$pathATool = @($graphicsStage.Tools | Where-Object { $_.Id -eq 'driver-install-debloat-settings' })[0]

Assert-BoostLabCondition ($null -ne $p0StateTool) 'P0 State must exist as an active Graphics tool.'
Assert-BoostLabCondition ([int]$driverCleanTool.Order -eq 1) 'Driver Clean must remain Graphics order 1 and outside Path B.'
Assert-BoostLabCondition ([int]$pathATool.Order -eq 2) 'Driver Install Debloat & Settings must remain separate at canonical Graphics order 2.'
Assert-BoostLabCondition ([int]$driverInstallLatestTool.Order -eq 3) 'Driver Install Latest must remain Path B step 1 and Graphics order 3.'
Assert-BoostLabCondition ([int]$nvidiaSettingsTool.Order -eq 4) 'Nvidia Settings must remain Path B step 2 and Graphics order 4.'
Assert-BoostLabCondition ([int]$hdcpTool.Order -eq 5) 'HDCP must remain Path B step 3 and Graphics order 5.'
Assert-BoostLabCondition ([int]$p0StateTool.Order -eq 6) 'P0 State must be Graphics order 6 as Path B step 4.'
Assert-BoostLabCondition ([int]$msiModeTool.Order -eq 7) 'Msi Mode must be Graphics order 7 as Path B step 5.'
Assert-BoostLabCondition ([string]$p0StateTool.Title -eq 'P0 State') 'P0 State title mismatch.'
Assert-BoostLabCondition ([string]$p0StateTool.Type -eq 'action') 'P0 State must be an action tool.'
Assert-BoostLabCondition ([string]$p0StateTool.RiskLevel -eq 'high') 'P0 State must remain high risk.'
Assert-BoostLabCondition ((@($p0StateTool.Actions) -join ',') -eq 'Analyze,Apply,Default') 'P0 State must expose only Analyze, Apply, and source-defined Default actions.'

$caps = $p0StateTool.Capabilities
Assert-BoostLabCondition ([bool]$caps.RequiresAdmin) 'P0 State must require Administrator for mutation actions.'
Assert-BoostLabCondition ([bool]$caps.CanModifyRegistry) 'P0 State must declare registry mutation capability.'
Assert-BoostLabCondition ([bool]$caps.SupportsDefault) 'P0 State must declare source-defined Default support.'
Assert-BoostLabCondition (-not [bool]$caps.SupportsRestore) 'P0 State must not claim Restore support.'
Assert-BoostLabCondition ([bool]$caps.NeedsExplicitConfirmation) 'P0 State must require explicit confirmation.'
foreach ($falseCapability in @(
    'RequiresInternet',
    'CanReboot',
    'CanModifyServices',
    'CanInstallSoftware',
    'CanDownload',
    'CanModifyDrivers',
    'CanModifySecurity',
    'CanDeleteFiles',
    'UsesTrustedInstaller',
    'UsesSafeMode'
)) {
    Assert-BoostLabCondition (-not [bool]$caps[$falseCapability]) "P0 State capability should be false: $falseCapability"
}

Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Id -eq 'hdcp' })) -eq 1) 'HDCP must remain separate from P0 State.'
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Id -eq 'p0-state' })) -eq 1) 'P0 State must be implemented as its own active tool.'
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Id -eq 'msi-mode' })) -eq 1) 'Msi Mode must remain active as its own separate controlled registry Path B step.'
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Id -eq 'ddu' -or $_.Title -eq 'DDU' })) -eq 0) 'Standalone DDU must not be introduced.'
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Title -eq 'Loudness EQ' -or $_.Id -eq 'loudness-eq' })) -eq 0) 'Loudness EQ must remain deleted.'
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Title -eq 'NVME Faster Driver' -or $_.Id -eq 'nvme-faster-driver' })) -eq 0) 'NVME Faster Driver must remain deleted.'

$placeholderModules = @(
    Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
Assert-BoostLabCondition ($allTools.Count -eq $inventoryBaseline.ActiveTools) "Expected $($inventoryBaseline.ActiveTools) active tools, found $($allTools.Count)."
Assert-BoostLabCondition ($placeholderModules.Count -eq $inventoryBaseline.DeferredPlaceholders) "Expected $($inventoryBaseline.DeferredPlaceholders) deferred/placeholders, found $($placeholderModules.Count)."
Assert-BoostLabCondition (($allTools.Count - $placeholderModules.Count) -eq $inventoryBaseline.ImplementedTools) "Expected $($inventoryBaseline.ImplementedTools) implemented tools, found $($allTools.Count - $placeholderModules.Count)."

$sourcePromotedFiles = @(Get-ChildItem -LiteralPath $sourcePromotedRoot -Recurse -File)
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
Assert-BoostLabCondition ($remainingSourcePromoted.Count -eq $inventoryBaseline.RemainingSourcePromotedIntakeCandidates) "Expected $($inventoryBaseline.RemainingSourcePromotedIntakeCandidates) remaining unimplemented source-promoted intake candidates, found $($remainingSourcePromoted.Count)."

$executionText = Get-Content -LiteralPath $executionPath -Raw
foreach ($needle in @(
    "'p0-state'",
    "Graphics\p0-state.psm1",
    "'Analyze', 'Apply', 'Default'"
)) {
    Assert-BoostLabTextContains -Text $executionText -Needle $needle -Description 'P0 State execution registration'
}

$uiText = Get-Content -LiteralPath $uiPath -Raw
foreach ($needle in @(
    'if ($toolId -eq ''p0-state'')',
    "'Apply' { return 'On (Recommended)' }",
    "'Default' { return 'Default' }",
    "'p0-state'"
)) {
    Assert-BoostLabTextContains -Text $uiText -Needle $needle -Description 'P0 State UI action surface'
}

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
Assert-BoostLabTextContains -Text $actionPlanText -Needle "[ValidateSet('Apply', 'Default', 'Open', 'Analyze', 'Restore', 'Off')]" -Description 'Action Plan canonical ValidateSet'
Assert-BoostLabCondition (-not $actionPlanText.Contains("'On (Recommended)'")) 'Action Plan ValidateSet must not be widened for P0 State source labels.'
foreach ($needle in @(
    'Read the P0 State source mirror and report source-defined display-class registry scope, non-Configuration target discovery, Apply availability, and Default availability without changing the system.',
    'Run the source-defined P0 State On (Recommended) branch after confirmation: set DisableDynamicPstate DWORD 1 on every non-Configuration display-class subkey and read the values back.',
    'Run the source-defined P0 State Default branch after confirmation: set DisableDynamicPstate DWORD 0 on every non-Configuration display-class subkey and read the values back. Default is not Restore.',
    'Discover only immediate source display-class registry subkeys under HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}, excluding Configuration.',
    'Do not apply GPU vendor filtering; the Ultimate source writes every non-Configuration display-class subkey returned by the source query.',
    'Set DisableDynamicPstate as REG_DWORD 1 on every captured source-included target.',
    'Set DisableDynamicPstate as REG_DWORD 0 on every captured source-included target, matching the Ultimate Default branch.',
    'Default is source-defined behavior, not captured-state Restore.'
)) {
    Assert-BoostLabTextContains -Text $actionPlanText -Needle $needle -Description 'P0 State action plan'
}
foreach ($forbiddenActionPlanText in @(
    'P0 State Restore',
    'eligible NVIDIA display-class targets',
    'P0 State registry value DisableDynamicPstate to DWORD 1 on eligible',
    'P0 State Default registry value DisableDynamicPstate to DWORD 0 on eligible'
)) {
    Assert-BoostLabCondition (-not $actionPlanText.Contains($forbiddenActionPlanText)) "P0 State action plan retained stale target-filtering wording: $forbiddenActionPlanText"
}

$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($needle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')',
    $expectedSourceHash,
    'source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1',
    'Registry::HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}',
    'DisableDynamicPstate',
    '$script:BoostLabP0StateApplyValue = 1',
    '$script:BoostLabP0StateDefaultValue = 0',
    'SourceOnRecommendedValue',
    'SourceSkipRule = ''*Configuration*''',
    'SourceKeyNames',
    'SkippedTargets',
    'New-BoostLabRegistryStateCapture',
    'Set-BoostLabRollbackMutationState',
    'No Restore action is source-defined or exposed for P0 State',
    'Default is source-defined DWORD 0 and is not Restore',
    '[ValidateSet(''Analyze'', ''Apply'', ''Default'', ''On (Recommended)'')]'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'P0 State module'
}
foreach ($forbiddenText in @(
    'NeedsNvidiaTargeting',
    'EligibleTargets',
    'ExcludedTargets',
    'AmbiguousTargets',
    'AmbiguousIdentity',
    'ExcludedNonNvidia',
    'Microsoft/RDP/non-NVIDIA',
    'VEN_10DE',
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'', ''Restore'')'
)) {
    Assert-BoostLabCondition (-not $moduleText.Contains($forbiddenText)) "P0 State module retained stale filtering or Restore action text: $forbiddenText"
}

foreach ($forbiddenPattern in @(
    '(?im)^\s*Start-Process\b',
    '(?im)^\s*Invoke-WebRequest\b',
    '(?im)^\s*iwr\b',
    '(?im)^\s*Invoke-RestMethod\b',
    '(?im)^\s*Start-BitsTransfer\b',
    '(?im)^\s*Restart-Computer\b',
    '(?im)^\s*Stop-Computer\b',
    '(?im)^\s*Set-Service\b',
    '(?im)^\s*Stop-Service\b',
    '(?im)^\s*bcdedit\b',
    '(?im)^\s*reg\s+add\b',
    '(?im)^\s*reg\s+delete\b',
    '(?im)^\s*Remove-ItemProperty\b'
)) {
    Assert-BoostLabCondition (-not [regex]::IsMatch($moduleText, $forbiddenPattern)) "P0 State module contains prohibited executable command pattern: $forbiddenPattern"
}

$artifactText = Get-Content -LiteralPath $artifactPath -Raw
$allowlistText = Get-Content -LiteralPath $productionAllowlistPath -Raw
Assert-BoostLabCondition (-not $artifactText.Contains('p0-state')) 'P0 State must not add artifact provenance entries.'
Assert-BoostLabCondition (-not $artifactText.Contains('DisableDynamicPstate')) 'P0 State must not add artifact provenance for registry behavior.'
Assert-BoostLabCondition (-not $allowlistText.Contains('p0-state')) 'P0 State must not add production allowlist scopes.'
Assert-BoostLabCondition (-not $allowlistText.Contains('DisableDynamicPstate')) 'P0 State must not add production registry allowlist scopes.'

$stateRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('BoostLab-P0StateTest-{0}' -f ([guid]::NewGuid().ToString('N')))
$root = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
$target0 = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000'
$target1 = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001'
$configurationTarget = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\Configuration'
$script:P0StateMockRegistryState = @{}
$script:P0StateMockWriteCount = 0

function New-MockRegistryState {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$ValueName
    )

    $key = '{0}|{1}' -f $Path, $ValueName
    if ($script:P0StateMockRegistryState.ContainsKey($key)) {
        $record = $script:P0StateMockRegistryState[$key]
        return [pscustomobject]@{
            ReadSucceeded = $true
            KeyExists = $true
            Exists = $true
            Metadata = [ordered]@{
                ValueName = $ValueName
                ValueType = 'DWord'
                ValueData = [int]$record
            }
            DisplayValue = 'DWord {0}' -f [int]$record
            Message = 'Mock registry value detected.'
        }
    }

    return [pscustomobject]@{
        ReadSucceeded = $true
        KeyExists = $true
        Exists = $false
        Metadata = $null
        DisplayValue = 'Absent'
        Message = 'Mock registry value is absent.'
    }
}

$mockRegistryStateReader = ${function:New-MockRegistryState}

$sourceEnumerator = {
    [pscustomobject]@{
        Succeeded = $true
        SourceRoot = 'Registry::HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
        SourceKeyNames = @(
            "$root\0000",
            "$root\0001",
            "$root\Configuration"
        )
        Warnings = @()
        Message = 'Mock source key names returned.'
    }
}.GetNewClosure()

$configurationOnlyEnumerator = {
    [pscustomobject]@{
        Succeeded = $true
        SourceRoot = 'Registry::HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
        SourceKeyNames = @("$root\Configuration")
        Warnings = @()
        Message = 'Only Configuration source key returned.'
    }
}.GetNewClosure()

$outOfScopeEnumerator = {
    [pscustomobject]@{
        Succeeded = $true
        SourceRoot = 'Registry::HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
        SourceKeyNames = @('HKEY_LOCAL_MACHINE\SOFTWARE\Outside\0000')
        Warnings = @()
        Message = 'Out-of-scope source key returned.'
    }
}.GetNewClosure()

$registryReader = {
    param(
        [string]$Path,
        [string]$ItemType,
        [string]$ValueName
    )

    & $mockRegistryStateReader -Path $Path -ValueName $ValueName
}.GetNewClosure()

$registryWriter = {
    param(
        [object]$Target,
        [int]$Value
    )

    $script:P0StateMockWriteCount++
    $key = '{0}|{1}' -f ([string]$Target.RegistryPath), 'DisableDynamicPstate'
    $script:P0StateMockRegistryState[$key] = [int]$Value
}.GetNewClosure()

try {
    Import-Module -Name $modulePath -Force -ErrorAction Stop
    $info = Get-BoostLabToolInfo
    Assert-BoostLabCondition ([string]$info.Id -eq 'p0-state') 'Imported P0 State module info Id mismatch.'
    Assert-BoostLabCondition ((@($info.ImplementedActions) -join ',') -eq 'Analyze,Apply,Default') 'P0 State implemented action list mismatch.'
    Assert-BoostLabCondition ((@($info.Actions) -join ',') -eq 'Analyze,Apply,Default') 'P0 State exposed action list mismatch.'
    Assert-BoostLabCondition (-not (@($info.Actions) -contains 'Restore')) 'P0 State must not expose Restore.'

    $analyze = Invoke-BoostLabToolAction -ActionName Analyze -TargetEnumerator $sourceEnumerator -RegistryReader $registryReader -StateRoot $stateRoot
    Assert-BoostLabCondition ([bool]$analyze.Success) 'P0 State Analyze should succeed.'
    Assert-BoostLabCondition ([string]$analyze.Status -eq 'Analyzed') 'P0 State Analyze status mismatch.'
    Assert-BoostLabCondition ([string]$analyze.CommandStatus -eq 'No execution performed') 'P0 State Analyze must be read-only.'
    Assert-BoostLabCondition (-not [bool]$analyze.ChangesExecuted) 'P0 State Analyze must not execute changes.'
    Assert-BoostLabCondition ([int]$analyze.Data.PathBStepNumber -eq 4 -and [int]$analyze.Data.PathBStepTotal -eq 5) 'P0 State Analyze must report Path B step 4 of 5.'
    Assert-BoostLabCondition ([string]$analyze.Data.Header -eq 'NVIDIA Highest Performance Power State') 'P0 State Analyze must report source header.'
    Assert-BoostLabCondition ([string]$analyze.Data.SourceRegistryValueName -eq 'DisableDynamicPstate') 'P0 State Analyze must report source value name.'
    Assert-BoostLabCondition ([int]$analyze.Data.SourceOnRecommendedValue -eq 1 -and [int]$analyze.Data.SourceDefaultValue -eq 0) 'P0 State Analyze must report source On/Default values.'
    Assert-BoostLabCondition ([bool]$analyze.Data.ApplyAvailable) 'P0 State Analyze should report Apply available for source-included targets.'
    Assert-BoostLabCondition ([bool]$analyze.Data.DefaultAvailable) 'P0 State Analyze should report Default available for source-included targets.'
    Assert-BoostLabCondition ([int]$analyze.Data.SourceKeyNameCount -eq 3) 'P0 State Analyze must report all mocked source key names.'
    Assert-BoostLabCondition ([int]$analyze.Data.TargetCount -eq 2) 'P0 State Analyze must include every non-Configuration immediate display-class target.'
    Assert-BoostLabCondition ([int]$analyze.Data.SkippedTargetCount -eq 1) 'P0 State Analyze must skip Configuration by source rule.'
    Assert-BoostLabCondition ([string]$analyze.Data.SkippedTargets[0].RegistryPath -eq $configurationTarget) 'P0 State Analyze skipped target path mismatch.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.RestoreAvailable) 'P0 State Analyze must not report Restore available.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.CaptureAttempted) 'P0 State Analyze must not capture registry state.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.RegistryWriteAttempted) 'P0 State Analyze must not write registry state.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.ExternalProcessStarted) 'P0 State Analyze must not start external processes.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.DownloadStarted) 'P0 State Analyze must not download anything.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.RebootRequested) 'P0 State Analyze must not request reboot.'

    $cancelledApply = Invoke-BoostLabToolAction -ActionName 'On (Recommended)' -TargetEnumerator $sourceEnumerator -RegistryReader $registryReader -RegistryWriter $registryWriter -StateRoot $stateRoot
    Assert-BoostLabCondition (-not [bool]$cancelledApply.Success) 'Unconfirmed P0 State On (Recommended) should not proceed.'
    Assert-BoostLabCondition ([bool]$cancelledApply.Cancelled) 'Unconfirmed P0 State On (Recommended) should be cancelled.'
    Assert-BoostLabCondition ($script:P0StateMockWriteCount -eq 0) 'Unconfirmed P0 State On (Recommended) must not write registry.'

    $apply = Invoke-BoostLabToolAction -ActionName 'On (Recommended)' -Confirmed:$true -AdministratorChecker { $true } -TargetEnumerator $sourceEnumerator -RegistryReader $registryReader -RegistryWriter $registryWriter -StateRoot $stateRoot
    Assert-BoostLabCondition ([bool]$apply.Success) "P0 State On (Recommended) should succeed with mocked source targets: $($apply.Message)"
    Assert-BoostLabCondition ([string]$apply.Action -eq 'Apply') 'P0 State On (Recommended) must map to canonical Apply.'
    Assert-BoostLabCondition ([string]$apply.CommandStatus -eq 'Completed') 'P0 State Apply command status mismatch.'
    Assert-BoostLabCondition ([string]$apply.VerificationStatus -eq 'Passed') 'P0 State Apply verification should pass.'
    Assert-BoostLabCondition ([bool]$apply.Data.ChangesExecuted) 'P0 State Apply should report changes executed.'
    Assert-BoostLabCondition ([bool]$apply.Data.CaptureAttempted) 'P0 State Apply should capture before mutation.'
    Assert-BoostLabCondition ([bool]$apply.Data.RegistryWriteAttempted) 'P0 State Apply should attempt registry write after capture.'
    Assert-BoostLabCondition (@($apply.Data.CaptureRecords).Count -eq 2) 'P0 State Apply must capture every source-included target.'
    Assert-BoostLabCondition ([int]$apply.Data.TargetCount -eq 2) 'P0 State Apply target count mismatch.'
    Assert-BoostLabCondition ([int]$apply.Data.WrittenTargetCount -eq 2) 'P0 State Apply must write every source-included target.'
    Assert-BoostLabCondition ([int]$script:P0StateMockRegistryState["$target0|DisableDynamicPstate"] -eq 1) 'P0 State Apply must set first target to DWORD 1.'
    Assert-BoostLabCondition ([int]$script:P0StateMockRegistryState["$target1|DisableDynamicPstate"] -eq 1) 'P0 State Apply must set second target to DWORD 1.'
    Assert-BoostLabCondition (-not $script:P0StateMockRegistryState.ContainsKey("$configurationTarget|DisableDynamicPstate")) 'P0 State Apply must not write Configuration targets.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.ExternalProcessStarted) 'P0 State Apply must not start external processes.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.DownloadStarted) 'P0 State Apply must not download anything.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.RebootRequested) 'P0 State Apply must not request reboot.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.RestoreImplemented) 'P0 State Apply must not claim Restore implementation.'
    Assert-BoostLabCondition ([bool]$apply.Data.DefaultImplemented) 'P0 State Apply should acknowledge separate source-defined Default implementation.'

    $default = Invoke-BoostLabToolAction -ActionName Default -Confirmed:$true -AdministratorChecker { $true } -TargetEnumerator $sourceEnumerator -RegistryReader $registryReader -RegistryWriter $registryWriter -StateRoot $stateRoot
    Assert-BoostLabCondition ([bool]$default.Success) "P0 State Default should succeed with mocked source targets: $($default.Message)"
    Assert-BoostLabCondition ([string]$default.Action -eq 'Default') 'P0 State Default action mismatch.'
    Assert-BoostLabCondition ([string]$default.VerificationStatus -eq 'Passed') 'P0 State Default verification should pass.'
    Assert-BoostLabCondition ([int]$script:P0StateMockRegistryState["$target0|DisableDynamicPstate"] -eq 0) 'P0 State Default must set first target to DWORD 0.'
    Assert-BoostLabCondition ([int]$script:P0StateMockRegistryState["$target1|DisableDynamicPstate"] -eq 0) 'P0 State Default must set second target to DWORD 0.'
    Assert-BoostLabCondition (-not $script:P0StateMockRegistryState.ContainsKey("$configurationTarget|DisableDynamicPstate")) 'P0 State Default must not write Configuration targets.'
    Assert-BoostLabCondition (@($default.Data.CaptureRecords).Count -eq 2) 'P0 State Default must capture every source-included target.'
    Assert-BoostLabCondition ([int]$default.Data.WrittenTargetCount -eq 2) 'P0 State Default must write every source-included target.'
    Assert-BoostLabTextContains -Text ([string]$default.Message) -Needle 'DWORD 0' -Description 'P0 State Default message'
    Assert-BoostLabTextContains -Text ([string]$default.Data.RestoreUnavailableReason) -Needle 'Default is source-defined DWORD 0 and is not Restore' -Description 'P0 State Default/Restore separation'

    $script:P0StateMockWriteCount = 0
    $configurationOnly = Invoke-BoostLabToolAction -ActionName Apply -Confirmed:$true -AdministratorChecker { $true } -TargetEnumerator $configurationOnlyEnumerator -RegistryReader $registryReader -RegistryWriter $registryWriter -StateRoot $stateRoot
    Assert-BoostLabCondition (-not [bool]$configurationOnly.Success) 'P0 State Apply must fail closed when only Configuration targets exist.'
    Assert-BoostLabCondition ([string]$configurationOnly.Status -eq 'NoSourceTargets') 'P0 State Configuration-only status mismatch.'
    Assert-BoostLabCondition (-not [bool]$configurationOnly.Data.CaptureAttempted) 'P0 State Configuration-only block must occur before capture.'
    Assert-BoostLabCondition (-not [bool]$configurationOnly.Data.RegistryWriteAttempted) 'P0 State Configuration-only block must occur before write.'
    Assert-BoostLabCondition ($script:P0StateMockWriteCount -eq 0) 'P0 State Configuration-only block must not call writer.'

    $outOfScope = Invoke-BoostLabToolAction -ActionName Apply -Confirmed:$true -AdministratorChecker { $true } -TargetEnumerator $outOfScopeEnumerator -RegistryReader $registryReader -RegistryWriter $registryWriter -StateRoot $stateRoot
    Assert-BoostLabCondition (-not [bool]$outOfScope.Success) 'P0 State Apply must fail closed for out-of-scope registry paths.'
    Assert-BoostLabCondition ([string]$outOfScope.Status -eq 'SourceScopeBlocked') 'P0 State out-of-scope block status mismatch.'
    Assert-BoostLabCondition (-not [bool]$outOfScope.Data.CaptureAttempted) 'P0 State out-of-scope block must occur before capture.'
    Assert-BoostLabCondition (-not [bool]$outOfScope.Data.RegistryWriteAttempted) 'P0 State out-of-scope block must occur before write.'

    $restoreRejected = $false
    try {
        Invoke-BoostLabToolAction -ActionName Restore -Confirmed:$true -TargetEnumerator $sourceEnumerator -RegistryReader $registryReader -RegistryWriter $registryWriter -StateRoot $stateRoot | Out-Null
    }
    catch {
        $restoreRejected = $true
    }
    Assert-BoostLabCondition $restoreRejected 'P0 State Restore must not be an accepted runtime action.'
}
finally {
    Remove-Module -Name p0-state -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $stateRoot) {
        Remove-Item -LiteralPath $stateRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$parity = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$order = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$p0Parity = @($parity.Tools | Where-Object { $_.ToolId -eq 'p0-state' })[0]
$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parity -ExecutionOrder $order
Assert-BoostLabCondition ([string]$p0Parity.ImplementationLevel -eq 'NearParityControlled') 'P0 State must remain NearParityControlled.'
Assert-BoostLabCondition ([string]$p0Parity.UltimateParity -eq 'Partial') 'P0 State must remain partial parity with Yazan accepted GUI confirmation/test-safe mechanics.'
Assert-BoostLabCondition ([string]$p0Parity.FinalProgressStatus -eq 'DoneYazanAcceptedNearParity') 'P0 State final progress status must be accepted near-parity after source-equivalent implementation.'
Assert-BoostLabCondition ([bool]$p0Parity.YazanAcceptedNearParity) 'P0 State Yazan accepted near-parity flag must be set.'
Assert-BoostLabTextContains -Text ([string]$p0Parity.GapSummary) -Needle 'exact source-equivalent P0 State On (Recommended) and Default behavior' -Description 'P0 State parity gap summary'
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq [string]$parity.CurrentOrderedParityTarget) 'Next ordered parity target must match the central parity baseline cursor.'

[pscustomobject]@{
    Success = $true
    Validator = 'Test-P0StateControlledRegistryImplementation'
    Message = 'P0 State source-equivalent registry implementation exposes On (Recommended)/Default only, captures before mutation, writes/readbacks all non-Configuration source targets, and the current ordered parity cursor now advances to Graphics Configuration Center after Visual C++.'
    ActiveTools = $inventoryBaseline.ActiveTools
    ImplementedTools = $inventoryBaseline.ImplementedTools
    DeferredPlaceholders = $inventoryBaseline.DeferredPlaceholders
    NextOrderedPendingParityTarget = [string]$nextTarget.ToolId
}

