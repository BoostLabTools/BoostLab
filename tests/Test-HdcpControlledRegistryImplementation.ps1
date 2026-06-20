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
        throw 'Unable to determine the HDCP validator path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
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
$modulePath = Join-Path $ProjectRoot 'modules\Graphics\hdcp.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate\5 Graphics\5 Hdcp.ps1'
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

$expectedSourceHash = '5C350D28F795D678051E6088F34968DF8D90B3D9024F558C5FAFB2899D1A906A'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "HDCP source mirror hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."

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

Assert-BoostLabCondition ($null -ne $hdcpTool) 'HDCP must exist as an active Graphics tool.'
Assert-BoostLabCondition ([int]$driverCleanTool.Order -eq 1) 'Driver Clean must remain Graphics order 1 and outside Path B.'
Assert-BoostLabCondition ([int]$pathATool.Order -eq 2) 'Driver Install Debloat & Settings must remain separate at canonical Graphics order 2.'
Assert-BoostLabCondition ([int]$driverInstallLatestTool.Order -eq 3) 'Driver Install Latest must remain Path B step 1 and Graphics order 3.'
Assert-BoostLabCondition ([int]$nvidiaSettingsTool.Order -eq 4) 'Nvidia Settings must remain Path B step 2 and Graphics order 4.'
Assert-BoostLabCondition ([int]$hdcpTool.Order -eq 5) 'HDCP must be Graphics order 5 as Path B step 3.'
Assert-BoostLabCondition ([int]$p0StateTool.Order -eq 6) 'P0 State must remain Graphics order 6 as Path B step 4.'
Assert-BoostLabCondition ([int]$msiModeTool.Order -eq 7) 'Msi Mode must remain Graphics order 7 as Path B step 5.'
Assert-BoostLabCondition ([string]$hdcpTool.Title -eq 'HDCP') 'HDCP title mismatch.'
Assert-BoostLabCondition ([string]$hdcpTool.Type -eq 'action') 'HDCP must be an action tool.'
Assert-BoostLabCondition ([string]$hdcpTool.RiskLevel -eq 'high') 'HDCP must remain high risk.'
Assert-BoostLabCondition ((@($hdcpTool.Actions) -join ',') -eq 'Analyze,Apply,Default') 'HDCP must expose only Analyze, Apply, and source-defined Default actions.'

$caps = $hdcpTool.Capabilities
Assert-BoostLabCondition ([bool]$caps.RequiresAdmin) 'HDCP must require Administrator for mutation actions.'
Assert-BoostLabCondition ([bool]$caps.CanModifyRegistry) 'HDCP must declare registry mutation capability.'
Assert-BoostLabCondition ([bool]$caps.SupportsDefault) 'HDCP must declare source-defined Default support.'
Assert-BoostLabCondition (-not [bool]$caps.SupportsRestore) 'HDCP must not claim Restore support.'
Assert-BoostLabCondition ([bool]$caps.NeedsExplicitConfirmation) 'HDCP must require explicit confirmation.'
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
    Assert-BoostLabCondition (-not [bool]$caps[$falseCapability]) "HDCP capability should be false: $falseCapability"
}

Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Id -eq 'p0-state' })) -eq 1) 'P0 State must remain active as its own separate controlled registry Path B step.'
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Id -eq 'msi-mode' })) -eq 1) 'Msi Mode must remain active as its own separate controlled registry Path B step.'
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Id -eq 'bitlocker' })) -eq 1) 'BitLocker must remain active as a separate Setup security assistant outside NVIDIA Path B.'
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
    "'hdcp'",
    "Graphics\hdcp.psm1",
    "'Analyze', 'Apply', 'Default'"
)) {
    Assert-BoostLabTextContains -Text $executionText -Needle $needle -Description 'HDCP execution registration'
}

$uiText = Get-Content -LiteralPath $uiPath -Raw
foreach ($needle in @(
    'if ($toolId -eq ''hdcp'')',
    "'Apply' { return 'Off (Recommended)' }",
    "'Default' { return 'Default' }",
    "'hdcp'"
)) {
    Assert-BoostLabTextContains -Text $uiText -Needle $needle -Description 'HDCP UI action surface'
}

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
Assert-BoostLabTextContains -Text $actionPlanText -Needle "[ValidateSet('Apply', 'Default', 'Open', 'Analyze', 'Restore', 'Off')]" -Description 'Action Plan canonical ValidateSet'
Assert-BoostLabCondition (-not $actionPlanText.Contains("'Off (Recommended)'")) 'Action Plan ValidateSet must not be widened for HDCP source labels.'
foreach ($needle in @(
    'Read the HDCP source mirror and report source-defined display-class registry scope, non-Configuration target discovery, and readback state without changing the system.',
    'Run the source-defined HDCP Off (Recommended) branch after confirmation: set RMHdcpKeyglobZero DWORD 1 on every non-Configuration display-class subkey and read the values back.',
    'Run the source-defined HDCP Default branch after confirmation: set RMHdcpKeyglobZero DWORD 0 on every non-Configuration display-class subkey and read the values back. Default is not Restore.',
    'Discover only immediate source display-class registry subkeys under HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}, excluding Configuration.',
    'Set RMHdcpKeyglobZero as REG_DWORD 1 on every captured source-included target.',
    'Set RMHdcpKeyglobZero as REG_DWORD 0 on every captured source-included target, matching the Ultimate Default branch.',
    'Default is source-defined behavior and is not captured-state Restore.'
)) {
    Assert-BoostLabTextContains -Text $actionPlanText -Needle $needle -Description 'HDCP action plan'
}
foreach ($forbiddenActionPlanText in @(
    'HDCP Restore',
    'Apply the source-defined HDCP Off value only to eligible NVIDIA',
    'Apply the source-defined HDCP Default value only to eligible NVIDIA'
)) {
    Assert-BoostLabCondition (-not $actionPlanText.Contains($forbiddenActionPlanText)) "HDCP action plan retained stale non-source wording: $forbiddenActionPlanText"
}

$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($needle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')',
    $expectedSourceHash,
    'source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1',
    'NVIDIA High Bandwidth Digital Content Protection',
    'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}',
    'Registry::HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}',
    'RMHdcpKeyglobZero',
    '$script:BoostLabHdcpApplyValue = 1',
    '$script:BoostLabHdcpDefaultValue = 0',
    'SourceSkipRule = ''*Configuration*''',
    'SourceKeyNames',
    'SkippedTargets',
    'New-BoostLabRegistryStateCapture',
    'Set-BoostLabRollbackMutationState',
    'Off (Recommended)',
    'No Restore action is source-defined or exposed for HDCP',
    'SupportsDefault = $true',
    'SupportsRestore = $false',
    'CanModifyDrivers = $false',
    'function Test-BoostLabHdcpState'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'HDCP module'
}
foreach ($forbiddenModuleText in @(
    'NeedsNvidiaTargeting',
    'VEN_10DE',
    'EligibleTargets',
    'ExcludedTargets',
    'ExcludedNonNvidia',
    'Microsoft/RDP/non-NVIDIA display adapter',
    'Restore requires a selected captured rollback record'
)) {
    Assert-BoostLabCondition (-not $moduleText.Contains($forbiddenModuleText)) "HDCP module retained stale NVIDIA filtering or Restore wording: $forbiddenModuleText"
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
    Assert-BoostLabCondition (-not [regex]::IsMatch($moduleText, $forbiddenPattern)) "HDCP module contains prohibited executable command pattern: $forbiddenPattern"
}

$artifactText = Get-Content -LiteralPath $artifactPath -Raw
$allowlistText = Get-Content -LiteralPath $productionAllowlistPath -Raw
Assert-BoostLabCondition (-not $artifactText.Contains('hdcp')) 'HDCP must not add artifact provenance entries.'
Assert-BoostLabCondition (-not $artifactText.Contains('RMHdcpKeyglobZero')) 'HDCP must not add artifact provenance for registry behavior.'
Assert-BoostLabCondition (-not $allowlistText.Contains('hdcp')) 'HDCP must not add production allowlist scopes.'
Assert-BoostLabCondition (-not $allowlistText.Contains('RMHdcpKeyglobZero')) 'HDCP must not add production registry allowlist scopes.'

$stateRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('BoostLab-HdcpTest-{0}' -f ([guid]::NewGuid().ToString('N')))
$displayRoot = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
$sourceDisplayRoot = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
$targetPath0 = "$displayRoot\0000"
$targetPath1 = "$displayRoot\0001"
$configurationPath = "$displayRoot\Configuration"
$sourceTarget0 = "$sourceDisplayRoot\0000"
$sourceTarget1 = "$sourceDisplayRoot\0001"
$sourceConfiguration = "$sourceDisplayRoot\Configuration"
$script:HdcpMockRegistryState = @{}
$script:HdcpMockWriteCount = 0
$script:HdcpMockWrites = [System.Collections.Generic.List[object]]::new()

function New-MockRegistryState {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$ValueName
    )

    $key = '{0}|{1}' -f $Path, $ValueName
    if ($script:HdcpMockRegistryState.ContainsKey($key)) {
        $record = $script:HdcpMockRegistryState[$key]
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

$sourceEquivalentEnumerator = {
    [pscustomobject]@{
        Succeeded = $true
        SourceRoot = 'Registry::HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
        SourceKeyNames = @($sourceTarget0, $sourceTarget1, $sourceConfiguration)
        Warnings = @()
        Message = '3 display-class subkey name(s) detected from the source query.'
    }
}.GetNewClosure()

$configurationOnlyEnumerator = {
    [pscustomobject]@{
        Succeeded = $true
        SourceRoot = 'Registry::HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
        SourceKeyNames = @($sourceConfiguration)
        Warnings = @()
        Message = '1 display-class subkey name detected from the source query.'
    }
}.GetNewClosure()

$outOfScopeEnumerator = {
    [pscustomobject]@{
        Succeeded = $true
        SourceRoot = 'Registry::HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
        SourceKeyNames = @('HKEY_LOCAL_MACHINE\SOFTWARE\Outside\0000')
        Warnings = @()
        Message = '1 invalid target supplied.'
    }
}.GetNewClosure()

$registryReader = {
    param(
        [string]$Path,
        [string]$ItemType,
        [string]$ValueName
    )

    New-MockRegistryState -Path $Path -ValueName $ValueName
}.GetNewClosure()

$registryWriter = {
    param(
        [object]$Target,
        [int]$Value
    )

    $script:HdcpMockWriteCount++
    $script:HdcpMockWrites.Add([pscustomobject]@{
        RegistryPath = [string]$Target.RegistryPath
        SourceKeyName = [string]$Target.SourceKeyName
        Value = [int]$Value
    })
    $key = '{0}|{1}' -f ([string]$Target.RegistryPath), 'RMHdcpKeyglobZero'
    $script:HdcpMockRegistryState[$key] = [int]$Value
}.GetNewClosure()

Import-Module -Name $modulePath -Force -ErrorAction Stop
try {
    $info = Get-BoostLabToolInfo
    Assert-BoostLabCondition ([string]$info.Id -eq 'hdcp') 'Imported HDCP module info Id mismatch.'
    Assert-BoostLabCondition ((@($info.ImplementedActions) -join ',') -eq 'Analyze,Apply,Default') 'HDCP implemented action list mismatch.'
    Assert-BoostLabCondition ((@($info.ConfirmationRequiredActions) -join ',') -eq 'Apply,Default') 'HDCP confirmation action list mismatch.'
    Assert-BoostLabCondition (-not (@($info.Actions) -contains 'Restore')) 'HDCP must not expose Restore as a tool action.'

    $analyze = Invoke-BoostLabToolAction -ActionName 'Analyze' -TargetEnumerator $sourceEquivalentEnumerator -RegistryReader $registryReader
    Assert-BoostLabCondition ([bool]$analyze.Success) 'HDCP Analyze should succeed.'
    Assert-BoostLabCondition ([string]$analyze.Status -eq 'Analyzed') 'HDCP Analyze status mismatch.'
    Assert-BoostLabCondition ([string]$analyze.CommandStatus -eq 'No execution performed') 'HDCP Analyze must be read-only.'
    Assert-BoostLabCondition ([string]$analyze.VerificationStatus -ne 'Failed') 'HDCP Analyze verification should not fail with valid source targets.'
    Assert-BoostLabCondition (-not [bool]$analyze.ChangesExecuted) 'HDCP Analyze must not execute changes.'
    Assert-BoostLabCondition ([string]$analyze.Data.PathBStep -eq '3 of 5') 'HDCP Analyze must report Path B step 3 of 5.'
    Assert-BoostLabCondition ([string]$analyze.Data.Header -eq 'NVIDIA High Bandwidth Digital Content Protection') 'HDCP Analyze must report source header.'
    Assert-BoostLabCondition ([string]$analyze.Data.SourceRegistryValueName -eq 'RMHdcpKeyglobZero') 'HDCP Analyze must report source value name.'
    Assert-BoostLabCondition ([int]$analyze.Data.SourceOffRecommendedValue -eq 1 -and [int]$analyze.Data.SourceDefaultValue -eq 0) 'HDCP Analyze must report source Off/Default values.'
    Assert-BoostLabCondition ([string]$analyze.Data.SourceSkipRule -eq '*Configuration*') 'HDCP Analyze must report source Configuration skip rule.'
    Assert-BoostLabCondition ([bool]$analyze.Data.ApplyAvailable) 'HDCP Analyze should report Apply available for mocked source targets.'
    Assert-BoostLabCondition ([bool]$analyze.Data.DefaultAvailable) 'HDCP Analyze should report source-defined Default available for mocked source targets.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.RestoreAvailable) 'HDCP Analyze must not report Restore available.'
    Assert-BoostLabCondition ([int]$analyze.Data.SourceKeyNameCount -eq 3) 'HDCP Analyze must report all source key names.'
    Assert-BoostLabCondition ([int]$analyze.Data.TargetCount -eq 2) 'HDCP Analyze must include every non-Configuration source target.'
    Assert-BoostLabCondition ([int]$analyze.Data.SkippedTargetCount -eq 1) 'HDCP Analyze must skip only the Configuration target.'
    Assert-BoostLabTextContains -Text ([string]$analyze.Data.SkippedTargets[0].SourceSkipReason) -Needle '*Configuration*' -Description 'HDCP source skip reason'
    Assert-BoostLabCondition ((@($analyze.Data.Targets | ForEach-Object { [string]$_.RegistryPath }) -join '|') -eq "$targetPath0|$targetPath1") 'HDCP Analyze target list must contain 0000 and 0001 only.'
    Assert-BoostLabCondition (-not ($analyze.Data.PSObject.Properties.Name -contains 'EligibleTargets')) 'HDCP Analyze must not retain stale eligible-target data.'
    Assert-BoostLabCondition (-not ($analyze.Data.PSObject.Properties.Name -contains 'ExcludedTargets')) 'HDCP Analyze must not retain stale excluded-target data.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.CaptureAttempted) 'HDCP Analyze must not capture registry state.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.RegistryWriteAttempted) 'HDCP Analyze must not write registry state.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.ExternalProcessStarted) 'HDCP Analyze must not start external processes.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.DownloadStarted) 'HDCP Analyze must not download anything.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.RebootRequested) 'HDCP Analyze must not request reboot.'

    $cancelledApply = Invoke-BoostLabToolAction -ActionName 'Apply' -TargetEnumerator $sourceEquivalentEnumerator -RegistryReader $registryReader -RegistryWriter $registryWriter -StateRoot $stateRoot
    Assert-BoostLabCondition (-not [bool]$cancelledApply.Success) 'Unconfirmed HDCP Apply should not proceed.'
    Assert-BoostLabCondition ([bool]$cancelledApply.Cancelled) 'Unconfirmed HDCP Apply should be cancelled.'
    Assert-BoostLabCondition ($script:HdcpMockWriteCount -eq 0) 'Unconfirmed HDCP Apply must not write registry.'

    $apply = Invoke-BoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -TargetEnumerator $sourceEquivalentEnumerator `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -StateRoot $stateRoot

    Assert-BoostLabCondition ([bool]$apply.Success) "HDCP Apply should succeed with mocked source targets: $($apply.Message)"
    Assert-BoostLabCondition ([string]$apply.Action -eq 'Apply') 'HDCP Apply action mismatch.'
    Assert-BoostLabCondition ([string]$apply.CommandStatus -eq 'Completed') 'HDCP Apply command status mismatch.'
    Assert-BoostLabCondition ([string]$apply.VerificationStatus -eq 'Passed') 'HDCP Apply verification should pass.'
    Assert-BoostLabCondition ([bool]$apply.Data.ChangesExecuted) 'HDCP Apply should report changes executed.'
    Assert-BoostLabCondition ([bool]$apply.Data.CaptureAttempted) 'HDCP Apply should capture before mutation.'
    Assert-BoostLabCondition ([bool]$apply.Data.RegistryWriteAttempted) 'HDCP Apply should attempt registry write after capture.'
    Assert-BoostLabCondition (@($apply.Data.CaptureRecords).Count -eq 2) 'HDCP Apply must record capture records for both non-Configuration targets.'
    Assert-BoostLabCondition ([int]$apply.Data.TargetCount -eq 2) 'HDCP Apply must report both source-included targets.'
    Assert-BoostLabCondition ([int]$apply.Data.SkippedTargetCount -eq 1) 'HDCP Apply must report skipped Configuration target.'
    Assert-BoostLabCondition ([int]$apply.Data.WrittenTargetCount -eq 2) 'HDCP Apply must write every non-Configuration source target.'
    Assert-BoostLabCondition ([int]$script:HdcpMockRegistryState["$targetPath0|RMHdcpKeyglobZero"] -eq 1) 'HDCP Apply must set 0000 RMHdcpKeyglobZero to DWORD 1.'
    Assert-BoostLabCondition ([int]$script:HdcpMockRegistryState["$targetPath1|RMHdcpKeyglobZero"] -eq 1) 'HDCP Apply must set 0001 RMHdcpKeyglobZero to DWORD 1.'
    Assert-BoostLabCondition (-not $script:HdcpMockRegistryState.ContainsKey("$configurationPath|RMHdcpKeyglobZero")) 'HDCP Apply must skip Configuration targets.'
    Assert-BoostLabCondition (@($apply.Data.Readbacks | Where-Object { $_.Status -eq 'Passed' }).Count -eq 2) 'HDCP Apply must read back every written target.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.ExternalProcessStarted) 'HDCP Apply must not start external processes.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.DownloadStarted) 'HDCP Apply must not download anything.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.RebootRequested) 'HDCP Apply must not request reboot.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.RestoreImplemented) 'HDCP Apply must not claim Restore implementation.'
    Assert-BoostLabCondition ([bool]$apply.Data.DefaultImplemented) 'HDCP Apply should acknowledge separate source-defined Default implementation.'

    $default = Invoke-BoostLabToolAction `
        -ActionName 'Default' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -TargetEnumerator $sourceEquivalentEnumerator `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -StateRoot $stateRoot

    Assert-BoostLabCondition ([bool]$default.Success) "HDCP Default should succeed with mocked source targets: $($default.Message)"
    Assert-BoostLabCondition ([string]$default.Action -eq 'Default') 'HDCP Default action mismatch.'
    Assert-BoostLabCondition ([string]$default.VerificationStatus -eq 'Passed') 'HDCP Default verification should pass.'
    Assert-BoostLabCondition ([int]$script:HdcpMockRegistryState["$targetPath0|RMHdcpKeyglobZero"] -eq 0) 'HDCP Default must set 0000 RMHdcpKeyglobZero to DWORD 0.'
    Assert-BoostLabCondition ([int]$script:HdcpMockRegistryState["$targetPath1|RMHdcpKeyglobZero"] -eq 0) 'HDCP Default must set 0001 RMHdcpKeyglobZero to DWORD 0.'
    Assert-BoostLabCondition (-not $script:HdcpMockRegistryState.ContainsKey("$configurationPath|RMHdcpKeyglobZero")) 'HDCP Default must skip Configuration targets.'
    Assert-BoostLabCondition (@($default.Data.CaptureRecords).Count -eq 2) 'HDCP Default must capture before mutation for both targets.'
    Assert-BoostLabCondition ([int]$default.Data.WrittenTargetCount -eq 2) 'HDCP Default must write both source-included targets.'
    Assert-BoostLabTextContains -Text ([string]$default.Message) -Needle 'DWORD 0' -Description 'HDCP Default message'
    Assert-BoostLabTextContains -Text ([string]$default.Data.RestoreUnavailableReason) -Needle 'Default is source-defined DWORD 0 and is not Restore' -Description 'HDCP Default/Restore separation'

    $script:HdcpMockWriteCount = 0
    $configurationOnlyApply = Invoke-BoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -TargetEnumerator $configurationOnlyEnumerator `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -StateRoot $stateRoot
    Assert-BoostLabCondition (-not [bool]$configurationOnlyApply.Success) 'HDCP Apply must fail closed when only Configuration targets exist.'
    Assert-BoostLabCondition ([string]$configurationOnlyApply.Status -eq 'NoSourceTargets') 'HDCP Configuration-only block status mismatch.'
    Assert-BoostLabCondition (-not [bool]$configurationOnlyApply.Data.CaptureAttempted) 'HDCP Configuration-only block must occur before capture.'
    Assert-BoostLabCondition (-not [bool]$configurationOnlyApply.Data.RegistryWriteAttempted) 'HDCP Configuration-only block must occur before registry write.'
    Assert-BoostLabCondition ($script:HdcpMockWriteCount -eq 0) 'HDCP Configuration-only block must not call writer.'

    $outOfScopeApply = Invoke-BoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -TargetEnumerator $outOfScopeEnumerator `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -StateRoot $stateRoot
    Assert-BoostLabCondition (-not [bool]$outOfScopeApply.Success) 'HDCP Apply must fail closed for out-of-scope registry paths.'
    Assert-BoostLabCondition ([string]$outOfScopeApply.Status -eq 'SourceScopeBlocked') 'HDCP out-of-scope block status mismatch.'
    Assert-BoostLabCondition (-not [bool]$outOfScopeApply.Data.CaptureAttempted) 'HDCP out-of-scope block must occur before capture.'
    Assert-BoostLabCondition (-not [bool]$outOfScopeApply.Data.RegistryWriteAttempted) 'HDCP out-of-scope block must occur before write.'

    $restoreBlocked = $false
    try {
        Invoke-BoostLabToolAction -ActionName 'Restore' -Confirmed:$true | Out-Null
    }
    catch {
        $restoreBlocked = $true
    }
    Assert-BoostLabCondition $restoreBlocked 'HDCP Restore must not be invokable because the source defines only Off and Default.'
}
finally {
    Remove-Module -Name hdcp -Force -ErrorAction SilentlyContinue
    if (
        (Test-Path -LiteralPath $stateRoot) -and
        $stateRoot.StartsWith([System.IO.Path]::GetTempPath(), [StringComparison]::OrdinalIgnoreCase)
    ) {
        Remove-Item -LiteralPath $stateRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$parity = Import-PowerShellDataFile -LiteralPath $parityPath
$hdcpParity = @($parity.Tools | Where-Object { $_.ToolId -eq 'hdcp' })[0]
$p0Parity = @($parity.Tools | Where-Object { $_.ToolId -eq 'p0-state' })[0]
Assert-BoostLabCondition ([string]$hdcpParity.FinalProgressStatus -eq 'DoneYazanAcceptedNearParity') 'HDCP parity status must be accepted near-parity after source-equivalent implementation with GUI confirmation.'
Assert-BoostLabCondition ([bool]$hdcpParity.YazanAcceptedNearParity) 'HDCP Yazan accepted near-parity flag must be set.'
Assert-BoostLabCondition ([string]$p0Parity.FinalProgressStatus -eq 'DoneYazanAcceptedNearParity') 'P0 State parity status must now be accepted near-parity after source-equivalent implementation with GUI confirmation.'
Assert-BoostLabCondition ([bool]$p0Parity.YazanAcceptedNearParity) 'P0 State Yazan accepted near-parity flag must be set.'

[pscustomobject]@{
    Success = $true
    ActiveToolCount = $inventoryBaseline.ActiveTools
    ImplementedToolCount = $inventoryBaseline.ImplementedTools
    PlaceholderToolCount = $inventoryBaseline.DeferredPlaceholders
    SourcePromotedMirrorFileCount = $inventoryBaseline.SourcePromotedMirrorFiles
    RemainingUnimplementedSourcePromotedIntakeCandidates = $inventoryBaseline.RemainingSourcePromotedIntakeCandidates
    Message = 'HDCP exact source-equivalent registry implementation is registered, captures before mutation, writes every non-Configuration display-class target, reads back every write, and exposes no Restore or external-operation behavior.'
    Timestamp = Get-Date
}
