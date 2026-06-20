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
        throw 'Unable to determine the Msi Mode validator path.'
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
$modulePath = Join-Path $ProjectRoot 'modules\Graphics\msi-mode.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate\5 Graphics\7 Msi Mode.ps1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$parityPath = Join-Path $ProjectRoot 'config\ParityStatusBaseline.psd1'
$orderPath = Join-Path $ProjectRoot 'config\UltimateParityExecutionOrder.psd1'
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
    $orderPath,
    $artifactPath,
    $productionAllowlistPath
)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required file missing: $path"
}

$expectedSourceHash = '94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Msi Mode source mirror hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."

$sourceText = Get-Content -LiteralPath $sourcePath -Raw
foreach ($needle in @(
    'Get-PnpDevice -Class Display',
    '$gpu.InstanceId',
    'MessageSignaledInterruptProperties',
    'MSISupported',
    '/d "1"',
    '/d "0"',
    'MSISupported: Not found or error accessing the registry.'
)) {
    Assert-BoostLabTextContains -Text $sourceText -Needle $needle -Description 'Msi Mode Ultimate source behavior'
}

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

Assert-BoostLabCondition ($null -ne $msiModeTool) 'Msi Mode must exist as an active Graphics tool.'
Assert-BoostLabCondition ([int]$driverCleanTool.Order -eq 1) 'Driver Clean must remain Graphics order 1 and outside Path B.'
Assert-BoostLabCondition ([int]$pathATool.Order -eq 2) 'Driver Install Debloat & Settings must remain separate at canonical Graphics order 2.'
Assert-BoostLabCondition ([int]$driverInstallLatestTool.Order -eq 3) 'Driver Install Latest must remain Path B step 1 and Graphics order 3.'
Assert-BoostLabCondition ([int]$nvidiaSettingsTool.Order -eq 4) 'Nvidia Settings must remain Path B step 2 and Graphics order 4.'
Assert-BoostLabCondition ([int]$hdcpTool.Order -eq 5) 'HDCP must remain Path B step 3 and Graphics order 5.'
Assert-BoostLabCondition ([int]$p0StateTool.Order -eq 6) 'P0 State must remain Graphics order 6 as Path B step 4.'
Assert-BoostLabCondition ([int]$msiModeTool.Order -eq 7) 'Msi Mode must be Graphics order 7 as Path B step 5.'
Assert-BoostLabCondition ([string]$msiModeTool.Title -eq 'Msi Mode') 'Msi Mode title mismatch.'
Assert-BoostLabCondition ([string]$msiModeTool.Type -eq 'action') 'Msi Mode must be an action tool.'
Assert-BoostLabCondition ([string]$msiModeTool.RiskLevel -eq 'high') 'Msi Mode must remain high risk.'
Assert-BoostLabCondition ((@($msiModeTool.Actions) -join ',') -eq 'Analyze,Apply,Off') 'Msi Mode must expose only Analyze, Apply, and Off.'

$caps = $msiModeTool.Capabilities
Assert-BoostLabCondition ([bool]$caps.RequiresAdmin) 'Msi Mode must require Administrator for mutation actions.'
Assert-BoostLabCondition ([bool]$caps.CanModifyRegistry) 'Msi Mode must declare registry mutation capability.'
Assert-BoostLabCondition (-not [bool]$caps.SupportsDefault) 'Msi Mode must not declare Default support because the source option is Off.'
Assert-BoostLabCondition (-not [bool]$caps.SupportsRestore) 'Msi Mode must not claim Restore support without source-defined captured-state restore flow.'
Assert-BoostLabCondition ([bool]$caps.NeedsExplicitConfirmation) 'Msi Mode must require explicit confirmation.'
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
    Assert-BoostLabCondition (-not [bool]$caps[$falseCapability]) "Msi Mode capability should be false: $falseCapability"
}

Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Id -eq 'hdcp' })) -eq 1) 'HDCP must remain separate from Msi Mode.'
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Id -eq 'p0-state' })) -eq 1) 'P0 State must remain separate from Msi Mode.'
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Id -eq 'msi-mode' })) -eq 1) 'Msi Mode must be implemented as its own active tool.'
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
    "'msi-mode'",
    "Graphics\msi-mode.psm1",
    "'Analyze', 'Apply', 'Off'"
)) {
    Assert-BoostLabTextContains -Text $executionText -Needle $needle -Description 'Msi Mode execution registration'
}

$uiText = Get-Content -LiteralPath $uiPath -Raw
foreach ($needle in @(
    "if (`$toolId -eq 'msi-mode')",
    "'Apply' { return 'On (Recommended)' }",
    "'Off' { return 'Off' }",
    "'msi-mode'"
)) {
    Assert-BoostLabTextContains -Text $uiText -Needle $needle -Description 'Msi Mode UI/action label behavior'
}
Assert-BoostLabCondition (-not [regex]::IsMatch($uiText, "(?s)if \(\`$toolId -eq 'msi-mode'\).*Manual Handoff")) 'Msi Mode UI must not expose Manual Handoff wording.'
Assert-BoostLabCondition ('Open' -notin @($msiModeTool.Actions)) 'Msi Mode must not expose a fake Open action.'

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
Assert-BoostLabTextContains -Text $actionPlanText -Needle "[ValidateSet('Apply', 'Default', 'Open', 'Analyze', 'Restore', 'Off')]" -Description 'Action Plan canonical ValidateSet with Msi Mode Off'
Assert-BoostLabCondition (-not $actionPlanText.Contains("'Manual Handoff', 'Apply Auto'")) 'Action Plan ValidateSet must not be widened with display labels.'
foreach ($needle in @(
    'Run the source-defined Msi Mode On (Recommended) branch',
    'Run the source-defined Msi Mode Off branch',
    'Get-PnpDevice -Class Display',
    'Do not apply source-undefined NVIDIA/RDP/status/vendor filtering',
    'MSISupported as REG_DWORD 1',
    'MSISupported as REG_DWORD 0',
    'Off is not Default or Restore',
    'No external process, download, Control Panel launch, profile import, driver install, device restart, reboot, service change, or source-undefined registry write occurs.'
)) {
    Assert-BoostLabTextContains -Text $actionPlanText -Needle $needle -Description 'Msi Mode action plan'
}
Assert-BoostLabCondition (-not [regex]::IsMatch($actionPlanText, "(?s)msi-mode.*eligible NVIDIA")) 'Msi Mode Action Plan must not retain NVIDIA-only target filtering.'
Assert-BoostLabCondition (-not [regex]::IsMatch($actionPlanText, "(?s)msi-mode.*Microsoft/RDP/non-NVIDIA targets are skipped")) 'Msi Mode Action Plan must not skip non-NVIDIA source display devices.'

$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($needle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Off'')',
    $expectedSourceHash,
    'source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1',
    'Get-PnpDevice -Class Display',
    'HKLM:\SYSTEM\ControlSet001\Enum',
    'Device Parameters\Interrupt Management\MessageSignaledInterruptProperties',
    'MSISupported',
    '$script:BoostLabMsiModeSourceOnRecommendedValue = 1',
    '$script:BoostLabMsiModeSourceOffValue = 0',
    'MSISupported: Not found or error accessing the registry.',
    'New-BoostLabRegistryStateCapture',
    'Set-BoostLabRollbackMutationState',
    'DefaultAvailable = $false',
    'RestoreAvailable = $false',
    'The Ultimate source exposes Off as a separate visible option'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'Msi Mode module'
}

foreach ($forbiddenText in @(
    'NeedsNvidiaTargeting',
    'EligibleTargets',
    'ExcludedTargets',
    'AmbiguousTargets',
    'AmbiguousIdentity',
    'ExcludedNonNvidia',
    'VEN_10DE',
    'NvidiaTarget',
    'Microsoft/RDP/non-NVIDIA display adapter',
    '$script:BoostLabMsiModeDefaultValue',
    'Invoke-BoostLabMsiModeRestore'
)) {
    Assert-BoostLabCondition (-not $moduleText.Contains($forbiddenText)) "Msi Mode module must not retain source-undefined target filtering/default/restore text: $forbiddenText"
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
    Assert-BoostLabCondition (-not [regex]::IsMatch($moduleText, $forbiddenPattern)) "Msi Mode module contains prohibited executable command pattern: $forbiddenPattern"
}

$artifactText = Get-Content -LiteralPath $artifactPath -Raw
$allowlistText = Get-Content -LiteralPath $productionAllowlistPath -Raw
Assert-BoostLabCondition (-not $artifactText.Contains('msi-mode')) 'Msi Mode must not add artifact provenance entries.'
Assert-BoostLabCondition (-not $artifactText.Contains('MSISupported')) 'Msi Mode must not add artifact provenance for registry behavior.'
Assert-BoostLabCondition (-not $allowlistText.Contains('msi-mode')) 'Msi Mode must not add production allowlist scopes.'
Assert-BoostLabCondition (-not $allowlistText.Contains('MSISupported')) 'Msi Mode must not add production registry allowlist scopes.'

$stateRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('BoostLab-MsiModeTest-{0}' -f ([guid]::NewGuid().ToString('N')))
$nvidiaInstanceId = 'PCI\VEN_10DE&DEV_2684&SUBSYS_00000000&REV_A1\4&11111111&0&0008'
$remoteInstanceId = 'DISPLAY\MS_RDP_DISPLAY\5&22222222&0&UID4352'
$amdInstanceId = 'PCI\VEN_1002&DEV_744C&SUBSYS_00000000&REV_C8\4&33333333&0&0008'
$nvidiaTargetPath = "HKLM:\SYSTEM\ControlSet001\Enum\$nvidiaInstanceId\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
$remoteTargetPath = "HKLM:\SYSTEM\ControlSet001\Enum\$remoteInstanceId\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
$amdTargetPath = "HKLM:\SYSTEM\ControlSet001\Enum\$amdInstanceId\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
$script:MsiModeMockRegistryState = @{}
$script:MsiModeMockWriteCount = 0

function New-MockRegistryState {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$ValueName
    )

    $key = '{0}|{1}' -f $Path, $ValueName
    if ($script:MsiModeMockRegistryState.ContainsKey($key)) {
        $record = $script:MsiModeMockRegistryState[$key]
        return [pscustomobject]@{
            ReadSucceeded = $true
            KeyExists = $true
            Exists = $true
            Metadata = [ordered]@{
                ValueName = $ValueName
                ValueType = 'DWord'
                ValueData = [int]$record
            }
            DisplayValue = '{0}: {1}' -f $ValueName, [int]$record
            Message = 'Mock registry value detected.'
        }
    }

    return [pscustomobject]@{
        ReadSucceeded = $true
        KeyExists = $false
        Exists = $false
        Metadata = $null
        DisplayValue = 'MSISupported: Not found or error accessing the registry.'
        Message = 'Mock registry value is absent.'
    }
}

$mixedDeviceEnumerator = {
    [pscustomobject]@{
        Succeeded = $true
        Devices = @(
            [pscustomobject]@{
                InstanceId = $nvidiaInstanceId
                FriendlyName = 'NVIDIA GeForce RTX'
            },
            [pscustomobject]@{
                InstanceId = $remoteInstanceId
                FriendlyName = 'Microsoft Remote Display Adapter'
            },
            [pscustomobject]@{
                InstanceId = $amdInstanceId
                FriendlyName = 'AMD Radeon RX'
            },
            [pscustomobject]@{
                FriendlyName = 'Display device without InstanceId'
            }
        )
        Warnings = @()
        Message = '4 display devices returned by Get-PnpDevice -Class Display.'
    }
}.GetNewClosure()

$noDeviceEnumerator = {
    [pscustomobject]@{
        Succeeded = $true
        Devices = @()
        Warnings = @()
        Message = 'No display devices returned.'
    }
}.GetNewClosure()

$outOfScopeEnumerator = {
    [pscustomobject]@{
        Succeeded = $true
        Devices = @(
            [pscustomobject]@{
                InstanceId = '..\SOFTWARE\Outside'
                FriendlyName = 'Invalid display path'
            }
        )
        Warnings = @()
        Message = 'Invalid display device returned.'
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

    $script:MsiModeMockWriteCount++
    $key = '{0}|{1}' -f ([string]$Target.RegistryPath), 'MSISupported'
    $script:MsiModeMockRegistryState[$key] = [int]$Value
}.GetNewClosure()

Import-Module -Name $modulePath -Force -ErrorAction Stop
try {
    $info = Get-BoostLabToolInfo
    Assert-BoostLabCondition ([string]$info.Id -eq 'msi-mode') 'Imported Msi Mode module info Id mismatch.'
    Assert-BoostLabCondition ((@($info.ImplementedActions) -join ',') -eq 'Analyze,Apply,Off') 'Msi Mode implemented action list mismatch.'
    Assert-BoostLabCondition ((@($info.ConfirmationRequiredActions) -join ',') -eq 'Apply,Off') 'Msi Mode confirmation action list mismatch.'

    $analyze = Invoke-BoostLabToolAction -ActionName 'Analyze' -TargetEnumerator $mixedDeviceEnumerator -RegistryReader $registryReader
    Assert-BoostLabCondition ([bool]$analyze.Success) "Msi Mode Analyze should succeed: $($analyze.Message)"
    Assert-BoostLabCondition ([string]$analyze.Status -eq 'Analyzed') 'Msi Mode Analyze status mismatch.'
    Assert-BoostLabCondition ([string]$analyze.CommandStatus -eq 'No execution performed') 'Msi Mode Analyze must be read-only.'
    Assert-BoostLabCondition (-not [bool]$analyze.ChangesExecuted) 'Msi Mode Analyze must not execute changes.'
    Assert-BoostLabCondition ([int]$analyze.Data.PathBStepNumber -eq 5 -and [int]$analyze.Data.PathBStepTotal -eq 5) 'Msi Mode Analyze must report Path B step 5 of 5.'
    Assert-BoostLabCondition ([string]$analyze.Data.SourceDeviceQuery -eq 'Get-PnpDevice -Class Display') 'Msi Mode Analyze must report the exact source query.'
    Assert-BoostLabCondition ([string]$analyze.Data.SourceRegistryRoot -eq 'HKLM:\SYSTEM\ControlSet001\Enum') 'Msi Mode Analyze must report the source Enum root.'
    Assert-BoostLabCondition ([string]$analyze.Data.SourceRegistrySuffix -eq 'Device Parameters\Interrupt Management\MessageSignaledInterruptProperties') 'Msi Mode Analyze must report the source registry suffix.'
    Assert-BoostLabCondition ([string]$analyze.Data.SourceRegistryValueName -eq 'MSISupported') 'Msi Mode Analyze must report source value name.'
    Assert-BoostLabCondition ([int]$analyze.Data.SourceOnRecommendedValue -eq 1 -and [int]$analyze.Data.SourceOffValue -eq 0) 'Msi Mode Analyze must report source On/Off values.'
    Assert-BoostLabCondition ([bool]$analyze.Data.OnRecommendedAvailable) 'Msi Mode Analyze should report On available for mocked source targets.'
    Assert-BoostLabCondition ([bool]$analyze.Data.OffAvailable) 'Msi Mode Analyze should report Off available for mocked source targets.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.DefaultAvailable) 'Msi Mode Analyze must not report Default available.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.RestoreAvailable) 'Msi Mode Analyze must not report Restore available.'
    Assert-BoostLabCondition ([int]$analyze.Data.TargetCount -eq 3) 'Msi Mode Analyze must include all source display devices with usable InstanceId values.'
    Assert-BoostLabCondition ([int]$analyze.Data.SkippedDeviceCount -eq 1) 'Msi Mode Analyze must report devices skipped only because InstanceId is missing.'
    Assert-BoostLabCondition (@($analyze.Data.Readbacks).Count -eq 3) 'Msi Mode Analyze must read back every source-derived target.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.CaptureAttempted) 'Msi Mode Analyze must not capture registry state.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.RegistryWriteAttempted) 'Msi Mode Analyze must not write registry state.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.ExternalProcessStarted) 'Msi Mode Analyze must not start external processes.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.DownloadStarted) 'Msi Mode Analyze must not download anything.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.RebootRequested) 'Msi Mode Analyze must not request reboot.'

    $cancelledApply = Invoke-BoostLabToolAction -ActionName 'Apply' -TargetEnumerator $mixedDeviceEnumerator -RegistryReader $registryReader -RegistryWriter $registryWriter -StateRoot $stateRoot
    Assert-BoostLabCondition (-not [bool]$cancelledApply.Success) 'Unconfirmed Msi Mode Apply should not proceed.'
    Assert-BoostLabCondition ([bool]$cancelledApply.Cancelled) 'Unconfirmed Msi Mode Apply should be cancelled.'
    Assert-BoostLabCondition ($script:MsiModeMockWriteCount -eq 0) 'Unconfirmed Msi Mode Apply must not write registry.'

    $apply = Invoke-BoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -TargetEnumerator $mixedDeviceEnumerator `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -StateRoot $stateRoot

    Assert-BoostLabCondition ([bool]$apply.Success) "Msi Mode Apply should succeed with mocked source targets: $($apply.Message)"
    Assert-BoostLabCondition ([string]$apply.Action -eq 'Apply') 'Msi Mode Apply action mismatch.'
    Assert-BoostLabCondition ([string]$apply.CommandStatus -eq 'Completed') 'Msi Mode Apply command status mismatch.'
    Assert-BoostLabCondition ([string]$apply.VerificationStatus -eq 'Passed') 'Msi Mode Apply verification should pass.'
    Assert-BoostLabCondition ([bool]$apply.Data.ChangesExecuted) 'Msi Mode Apply should report changes executed.'
    Assert-BoostLabCondition ([bool]$apply.Data.CaptureAttempted) 'Msi Mode Apply should capture before mutation.'
    Assert-BoostLabCondition ([bool]$apply.Data.RegistryWriteAttempted) 'Msi Mode Apply should attempt registry write after capture.'
    Assert-BoostLabCondition (@($apply.Data.CaptureRecords).Count -eq 3) 'Msi Mode Apply must record one capture record per source-derived target.'
    Assert-BoostLabCondition ([int]$apply.Data.TargetCount -eq 3) 'Msi Mode Apply must report all source-derived targets.'
    Assert-BoostLabCondition ([int]$apply.Data.WrittenTargetCount -eq 3) 'Msi Mode Apply must write every source-derived target.'
    Assert-BoostLabCondition ([int]$script:MsiModeMockRegistryState["$nvidiaTargetPath|MSISupported"] -eq 1) 'Msi Mode Apply must set NVIDIA source target MSISupported to DWORD 1.'
    Assert-BoostLabCondition ([int]$script:MsiModeMockRegistryState["$remoteTargetPath|MSISupported"] -eq 1) 'Msi Mode Apply must set Remote Display Adapter source target MSISupported to DWORD 1 because the source does not filter it.'
    Assert-BoostLabCondition ([int]$script:MsiModeMockRegistryState["$amdTargetPath|MSISupported"] -eq 1) 'Msi Mode Apply must set AMD source target MSISupported to DWORD 1 because the source does not filter it.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.ExternalProcessStarted) 'Msi Mode Apply must not start external processes.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.DownloadStarted) 'Msi Mode Apply must not download anything.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.RebootRequested) 'Msi Mode Apply must not request reboot.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.DefaultImplemented) 'Msi Mode Apply must not claim Default implementation.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.RestoreImplemented) 'Msi Mode Apply must not claim Restore implementation.'

    $off = Invoke-BoostLabToolAction `
        -ActionName 'Off' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -TargetEnumerator $mixedDeviceEnumerator `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -StateRoot $stateRoot

    Assert-BoostLabCondition ([bool]$off.Success) "Msi Mode Off should succeed with mocked source targets: $($off.Message)"
    Assert-BoostLabCondition ([string]$off.Action -eq 'Off') 'Msi Mode Off action mismatch.'
    Assert-BoostLabCondition ([string]$off.VerificationStatus -eq 'Passed') 'Msi Mode Off verification should pass.'
    Assert-BoostLabCondition ([int]$script:MsiModeMockRegistryState["$nvidiaTargetPath|MSISupported"] -eq 0) 'Msi Mode Off must set NVIDIA source target MSISupported to DWORD 0.'
    Assert-BoostLabCondition ([int]$script:MsiModeMockRegistryState["$remoteTargetPath|MSISupported"] -eq 0) 'Msi Mode Off must set Remote Display Adapter source target MSISupported to DWORD 0 because the source does not filter it.'
    Assert-BoostLabCondition ([int]$script:MsiModeMockRegistryState["$amdTargetPath|MSISupported"] -eq 0) 'Msi Mode Off must set AMD source target MSISupported to DWORD 0 because the source does not filter it.'
    Assert-BoostLabCondition (@($off.Data.CaptureRecords).Count -eq 3) 'Msi Mode Off must capture before mutation.'
    Assert-BoostLabCondition ([int]$off.Data.WrittenTargetCount -eq 3) 'Msi Mode Off must write every source-derived target.'
    Assert-BoostLabTextContains -Text ([string]$off.Message) -Needle 'DWORD 0' -Description 'Msi Mode Off message'
    Assert-BoostLabTextContains -Text ([string]$off.Data.DefaultUnavailableReason) -Needle 'Off as a separate visible option' -Description 'Msi Mode Off/Default separation'

    $default = Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed:$true
    Assert-BoostLabCondition (-not [bool]$default.Success) 'Msi Mode Default must not be exposed as a mutating source branch.'
    Assert-BoostLabCondition ([string]$default.Status -eq 'UnsupportedAction') 'Msi Mode Default unsupported status mismatch.'
    Assert-BoostLabCondition (-not [bool]$default.ChangesExecuted) 'Msi Mode Default must execute no changes.'

    $restore = Invoke-BoostLabToolAction -ActionName 'Restore' -Confirmed:$true
    Assert-BoostLabCondition (-not [bool]$restore.Success) 'Msi Mode Restore must not be exposed.'
    Assert-BoostLabCondition ([string]$restore.Status -eq 'UnsupportedAction') 'Msi Mode Restore unsupported status mismatch.'
    Assert-BoostLabCondition (-not [bool]$restore.ChangesExecuted) 'Msi Mode Restore must execute no changes.'

    $noDeviceApply = Invoke-BoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -TargetEnumerator $noDeviceEnumerator `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -StateRoot $stateRoot
    Assert-BoostLabCondition (-not [bool]$noDeviceApply.Success) 'Msi Mode Apply must fail closed when the source query returns no usable display devices.'
    Assert-BoostLabCondition ([string]$noDeviceApply.Status -eq 'NoDisplayDevices') 'Msi Mode no-display block status mismatch.'
    Assert-BoostLabCondition (-not [bool]$noDeviceApply.Data.CaptureAttempted) 'Msi Mode no-display block must occur before capture.'
    Assert-BoostLabCondition (-not [bool]$noDeviceApply.Data.RegistryWriteAttempted) 'Msi Mode no-display block must occur before write.'

    $outOfScopeApply = Invoke-BoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -TargetEnumerator $outOfScopeEnumerator `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -StateRoot $stateRoot
    Assert-BoostLabCondition (-not [bool]$outOfScopeApply.Success) 'Msi Mode Apply must fail closed for out-of-scope registry paths.'
    Assert-BoostLabCondition ([string]$outOfScopeApply.Status -eq 'SourceScopeBlocked') 'Msi Mode out-of-scope block status mismatch.'
    Assert-BoostLabCondition (-not [bool]$outOfScopeApply.Data.CaptureAttempted) 'Msi Mode out-of-scope block must occur before capture.'
    Assert-BoostLabCondition (-not [bool]$outOfScopeApply.Data.RegistryWriteAttempted) 'Msi Mode out-of-scope block must occur before write.'
}
finally {
    Remove-Module -Name msi-mode -Force -ErrorAction SilentlyContinue
    if (
        (Test-Path -LiteralPath $stateRoot) -and
        $stateRoot.StartsWith([System.IO.Path]::GetTempPath(), [StringComparison]::OrdinalIgnoreCase)
    ) {
        Remove-Item -LiteralPath $stateRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$msiRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'msi-mode' })[0]
Assert-BoostLabCondition ($null -ne $msiRecord) 'Msi Mode parity record is missing.'
Assert-BoostLabCondition ([string]$msiRecord.ImplementationLevel -eq 'NearParityControlled') 'Msi Mode implementation level mismatch.'
Assert-BoostLabCondition ([string]$msiRecord.FinalProgressStatus -eq 'DoneYazanAcceptedNearParity') 'Msi Mode final progress status mismatch.'
Assert-BoostLabCondition ([bool]$msiRecord.YazanAcceptedNearParity) 'Msi Mode must be marked Yazan-accepted near parity.'
Assert-BoostLabCondition ([string]$msiRecord.NextParityAction -eq 'Skip; accepted near-parity.') 'Msi Mode next parity action mismatch.'
$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ($null -ne $nextTarget) 'Next ordered parity target should exist after Msi Mode.'
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq 'directx') 'Next ordered pending parity target must advance to DirectX after Msi Mode.'

[pscustomobject]@{
    Success = $true
    ActiveToolCount = $inventoryBaseline.ActiveTools
    ImplementedToolCount = $inventoryBaseline.ImplementedTools
    PlaceholderToolCount = $inventoryBaseline.DeferredPlaceholders
    SourcePromotedMirrorFileCount = $inventoryBaseline.SourcePromotedMirrorFiles
    RemainingUnimplementedSourcePromotedIntakeCandidates = $inventoryBaseline.RemainingSourcePromotedIntakeCandidates
    NextOrderedPendingParityTarget = [string]$nextTarget.ToolId
    Message = 'Msi Mode exact source-equivalent On/Off registry implementation is registered, captures before mutation, writes every source display-device target, and advances ordered parity to DirectX.'
    Timestamp = Get-Date
}
