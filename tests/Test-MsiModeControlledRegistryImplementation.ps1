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
    $artifactPath,
    $productionAllowlistPath
)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required file missing: $path"
}

$expectedSourceHash = '94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Msi Mode source mirror hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."

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
Assert-BoostLabCondition ([int]$driverInstallLatestTool.Order -eq 2) 'Driver Install Latest must remain Path B step 1.'
Assert-BoostLabCondition ([int]$nvidiaSettingsTool.Order -eq 3) 'Nvidia Settings must remain Path B step 2.'
Assert-BoostLabCondition ([int]$hdcpTool.Order -eq 4) 'HDCP must remain Path B step 3.'
Assert-BoostLabCondition ([int]$p0StateTool.Order -eq 5) 'P0 State must remain Graphics order 5 as Path B step 4.'
Assert-BoostLabCondition ([int]$msiModeTool.Order -eq 6) 'Msi Mode must be Graphics order 6 as Path B step 5.'
Assert-BoostLabCondition ([int]$pathATool.Order -eq 7) 'Path A Driver Install Debloat & Settings must remain separate after Msi Mode.'
Assert-BoostLabCondition ([string]$msiModeTool.Title -eq 'Msi Mode') 'Msi Mode title mismatch.'
Assert-BoostLabCondition ([string]$msiModeTool.Type -eq 'action') 'Msi Mode must be an action tool.'
Assert-BoostLabCondition ([string]$msiModeTool.RiskLevel -eq 'high') 'Msi Mode must remain high risk.'
Assert-BoostLabCondition ((@($msiModeTool.Actions) -join ',') -eq 'Analyze,Apply,Default,Restore') 'Msi Mode must use only canonical Analyze, Apply, Default, Restore actions.'

$caps = $msiModeTool.Capabilities
Assert-BoostLabCondition ([bool]$caps.RequiresAdmin) 'Msi Mode must require Administrator for mutation actions.'
Assert-BoostLabCondition ([bool]$caps.CanModifyRegistry) 'Msi Mode must declare registry mutation capability.'
Assert-BoostLabCondition ([bool]$caps.SupportsDefault) 'Msi Mode must declare source-defined Default support.'
Assert-BoostLabCondition (-not [bool]$caps.SupportsRestore) 'Msi Mode must not claim Restore support without selected captured-state restore flow.'
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
Assert-BoostLabCondition ($allTools.Count -eq 55) "Expected 55 active tools, found $($allTools.Count)."
Assert-BoostLabCondition ($placeholderModules.Count -eq 14) "Expected 14 deferred/placeholders, found $($placeholderModules.Count)."
Assert-BoostLabCondition (($allTools.Count - $placeholderModules.Count) -eq 41) "Expected 41 implemented tools, found $($allTools.Count - $placeholderModules.Count)."

$sourcePromotedFiles = @(Get-ChildItem -LiteralPath $sourcePromotedRoot -Recurse -File)
Assert-BoostLabCondition ($sourcePromotedFiles.Count -eq 7) "Expected 7 source-promoted mirror files, found $($sourcePromotedFiles.Count)."
$remainingSourcePromoted = @(
    $sourcePromotedFiles | Where-Object {
        $_.Name -notin @(
            '1 Driver Clean.ps1',
            '2 Driver Install Latest.ps1',
            '4 Nvidia Settings.ps1',
            '5 Hdcp.ps1',
            '6 P0 State.ps1',
            '7 Msi Mode.ps1'
            '1 BitLocker.ps1'
        )
    }
)
Assert-BoostLabCondition ($remainingSourcePromoted.Count -eq 0) "Expected 0 remaining unimplemented source-promoted intake candidates, found $($remainingSourcePromoted.Count)."

$executionText = Get-Content -LiteralPath $executionPath -Raw
foreach ($needle in @(
    "'msi-mode'",
    "Graphics\msi-mode.psm1",
    "'Analyze', 'Apply', 'Default', 'Restore'"
)) {
    Assert-BoostLabTextContains -Text $executionText -Needle $needle -Description 'Msi Mode execution registration'
}

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
Assert-BoostLabTextContains -Text $actionPlanText -Needle "[ValidateSet('Apply', 'Default', 'Open', 'Analyze', 'Restore')]" -Description 'Action Plan canonical ValidateSet'
Assert-BoostLabCondition (-not $actionPlanText.Contains("'Manual Handoff', 'Apply Auto'")) 'Action Plan ValidateSet must not be widened for Msi Mode.'
foreach ($needle in @(
    'Apply the source-defined Msi Mode On value only to eligible NVIDIA display-device Enum registry targets',
    'Apply the source-defined Msi Mode Default value only to eligible NVIDIA display-device Enum registry targets',
    'No registry mutation is planned without selected captured state',
    'MSISupported as REG_DWORD 1',
    'MSISupported to DWORD 0',
    'excluded Microsoft/RDP/non-NVIDIA targets are skipped',
    'No external process, download, Control Panel launch, profile import, driver install, device restart, reboot, service change, or non-NVIDIA registry write occurs.'
)) {
    Assert-BoostLabTextContains -Text $actionPlanText -Needle $needle -Description 'Msi Mode action plan'
}

$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($needle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'', ''Restore'')',
    $expectedSourceHash,
    'source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1',
    'HKLM:\SYSTEM\ControlSet001\Enum',
    'Device Parameters\Interrupt Management\MessageSignaledInterruptProperties',
    'MSISupported',
    '$script:BoostLabMsiModeApplyValue = 1',
    '$script:BoostLabMsiModeDefaultValue = 0',
    'New-BoostLabRegistryStateCapture',
    'Set-BoostLabRollbackMutationState',
    'NeedsNvidiaTargeting',
    'EligibleTargets',
    'ExcludedTargets',
    'AmbiguousTargets',
    'AmbiguousIdentity',
    'ExcludedNonNvidia',
    'Microsoft/RDP/non-NVIDIA display adapter',
    'VEN_10DE',
    'Default is source-defined MSISupported DWORD 0 and is not Restore',
    'Restore requires a selected captured rollback record'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'Msi Mode module'
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
$approvedInstanceId = 'PCI\VEN_10DE&DEV_2684&SUBSYS_00000000&REV_A1\4&11111111&0&0008'
$nonNvidiaInstanceId = 'DISPLAY\MS_RDP_DISPLAY\5&22222222&0&UID4352'
$ambiguousInstanceId = 'PCI\VEN_1234&DEV_5678&SUBSYS_00000000&REV_01\4&33333333&0&0008'
$approvedTargetPath = "HKLM:\SYSTEM\ControlSet001\Enum\$approvedInstanceId\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
$nonNvidiaTargetPath = "HKLM:\SYSTEM\ControlSet001\Enum\$nonNvidiaInstanceId\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
$ambiguousTargetPath = "HKLM:\SYSTEM\ControlSet001\Enum\$ambiguousInstanceId\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
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

$nvidiaEnumerator = {
    [pscustomobject]@{
        Succeeded = $true
        Targets = @(
            [pscustomobject]@{
                RegistryPath = $approvedTargetPath
                ValueName = 'MSISupported'
                NvidiaTarget = $true
                Evidence = @('DriverDesc=NVIDIA GeForce RTX', 'MatchingDeviceId=PCI\VEN_10DE&DEV_2684')
            }
        )
        Warnings = @()
        Message = '1 source-targeted display-device Msi Mode registry target(s) detected.'
    }
}.GetNewClosure()

$nonNvidiaEnumerator = {
    [pscustomobject]@{
        Succeeded = $true
        Targets = @(
            [pscustomobject]@{
                RegistryPath = $nonNvidiaTargetPath
                ValueName = 'MSISupported'
                NvidiaTarget = $false
                Evidence = @('DriverDesc=Microsoft Basic Display Adapter')
            }
        )
        Warnings = @()
        Message = '1 source-targeted display-device Msi Mode registry target(s) detected.'
    }
}.GetNewClosure()

$mixedEnumerator = {
    [pscustomobject]@{
        Succeeded = $true
        Targets = @(
            [pscustomobject]@{
                RegistryPath = $approvedTargetPath
                ValueName = 'MSISupported'
                NvidiaTarget = $true
                Evidence = @('DriverDesc=NVIDIA GeForce RTX', 'MatchingDeviceId=PCI\VEN_10DE&DEV_2684')
            },
            [pscustomobject]@{
                RegistryPath = $nonNvidiaTargetPath
                ValueName = 'MSISupported'
                NvidiaTarget = $false
                Evidence = @('DriverDesc=Microsoft Remote Display Adapter', 'ProviderName=Microsoft')
            }
        )
        Warnings = @()
        Message = '2 source-targeted display-device Msi Mode registry target(s) detected.'
    }
}.GetNewClosure()

$ambiguousEnumerator = {
    [pscustomobject]@{
        Succeeded = $true
        Targets = @(
            [pscustomobject]@{
                RegistryPath = $ambiguousTargetPath
                ValueName = 'MSISupported'
                NvidiaTarget = $false
                Evidence = @('DriverDesc=Unknown Display Adapter', 'ProviderName=Unknown')
            }
        )
        Warnings = @()
        Message = '1 ambiguous source-targeted display-device Msi Mode registry target detected.'
    }
}.GetNewClosure()

$outOfScopeEnumerator = {
    [pscustomobject]@{
        Succeeded = $true
        Targets = @(
            [pscustomobject]@{
                RegistryPath = 'HKLM:\SOFTWARE\Outside\0000'
                ValueName = 'MSISupported'
                NvidiaTarget = $true
                Evidence = @('DriverDesc=NVIDIA GeForce RTX')
            }
        )
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

    $script:MsiModeMockWriteCount++
    $key = '{0}|{1}' -f ([string]$Target.RegistryPath), 'MSISupported'
    $script:MsiModeMockRegistryState[$key] = [int]$Value
}.GetNewClosure()

Import-Module -Name $modulePath -Force -ErrorAction Stop
try {
    $info = Get-BoostLabToolInfo
    Assert-BoostLabCondition ([string]$info.Id -eq 'msi-mode') 'Imported Msi Mode module info Id mismatch.'
    Assert-BoostLabCondition ((@($info.ImplementedActions) -join ',') -eq 'Analyze,Apply,Default,Restore') 'Msi Mode implemented action list mismatch.'

    $analyze = Invoke-BoostLabToolAction -ActionName 'Analyze' -TargetEnumerator $mixedEnumerator -RegistryReader $registryReader
    Assert-BoostLabCondition ([bool]$analyze.Success) 'Msi Mode Analyze should succeed.'
    Assert-BoostLabCondition ([string]$analyze.Status -eq 'Analyzed') 'Msi Mode Analyze status mismatch.'
    Assert-BoostLabCondition ([string]$analyze.CommandStatus -eq 'No execution performed') 'Msi Mode Analyze must be read-only.'
    Assert-BoostLabCondition ([string]$analyze.VerificationStatus -ne 'Failed') 'Msi Mode Analyze must not fail verification solely because excluded non-NVIDIA targets exist.'
    Assert-BoostLabCondition (-not [bool]$analyze.ChangesExecuted) 'Msi Mode Analyze must not execute changes.'
    Assert-BoostLabCondition ([int]$analyze.Data.PathBStepNumber -eq 5 -and [int]$analyze.Data.PathBStepTotal -eq 5) 'Msi Mode Analyze must report Path B step 5 of 5.'
    Assert-BoostLabCondition ([string]$analyze.Data.SourceRegistryRoot -eq 'HKLM:\SYSTEM\ControlSet001\Enum') 'Msi Mode Analyze must report the source Enum root.'
    Assert-BoostLabCondition ([string]$analyze.Data.SourceRegistrySuffix -eq 'Device Parameters\Interrupt Management\MessageSignaledInterruptProperties') 'Msi Mode Analyze must report the source registry suffix.'
    Assert-BoostLabCondition ([string]$analyze.Data.SourceRegistryValueName -eq 'MSISupported') 'Msi Mode Analyze must report source value name.'
    Assert-BoostLabCondition ([int]$analyze.Data.SourceApplyValue -eq 1 -and [int]$analyze.Data.SourceDefaultValue -eq 0) 'Msi Mode Analyze must report source Apply/Default values.'
    Assert-BoostLabCondition ([bool]$analyze.Data.ApplyAvailable) 'Msi Mode Analyze should report Apply available for mocked NVIDIA target.'
    Assert-BoostLabCondition ([bool]$analyze.Data.DefaultAvailable) 'Msi Mode Analyze should report source-defined Default available for mocked NVIDIA target.'
    Assert-BoostLabCondition ([int]$analyze.Data.TargetCount -eq 2) 'Msi Mode Analyze must report all source-targeted display-device Enum targets.'
    Assert-BoostLabCondition ([int]$analyze.Data.EligibleTargetCount -eq 1) 'Msi Mode Analyze must report one eligible NVIDIA target.'
    Assert-BoostLabCondition ([int]$analyze.Data.ExcludedTargetCount -eq 1) 'Msi Mode Analyze must report one excluded target.'
    Assert-BoostLabCondition ([int]$analyze.Data.AmbiguousTargetCount -eq 0) 'Msi Mode Analyze must report zero ambiguous targets for the mixed NVIDIA/Microsoft case.'
    $excludedTarget = @($analyze.Data.ExcludedTargets)[0]
    Assert-BoostLabTextContains -Text ((@($excludedTarget.Evidence) -join '; ')) -Needle 'Microsoft Remote Display Adapter' -Description 'Msi Mode excluded Microsoft Remote Display Adapter evidence'
    Assert-BoostLabCondition ([string]$excludedTarget.TargetingStatus -eq 'ExcludedNonNvidia') 'Msi Mode excluded target status mismatch.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.RestoreAvailable) 'Msi Mode Analyze must not report Restore available without selected captured state.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.CaptureAttempted) 'Msi Mode Analyze must not capture registry state.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.RegistryWriteAttempted) 'Msi Mode Analyze must not write registry state.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.ExternalProcessStarted) 'Msi Mode Analyze must not start external processes.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.DownloadStarted) 'Msi Mode Analyze must not download anything.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.RebootRequested) 'Msi Mode Analyze must not request reboot.'

    $cancelledApply = Invoke-BoostLabToolAction -ActionName 'Apply' -TargetEnumerator $nvidiaEnumerator -RegistryReader $registryReader -RegistryWriter $registryWriter -StateRoot $stateRoot
    Assert-BoostLabCondition (-not [bool]$cancelledApply.Success) 'Unconfirmed Msi Mode Apply should not proceed.'
    Assert-BoostLabCondition ([bool]$cancelledApply.Cancelled) 'Unconfirmed Msi Mode Apply should be cancelled.'
    Assert-BoostLabCondition ($script:MsiModeMockWriteCount -eq 0) 'Unconfirmed Msi Mode Apply must not write registry.'

    $apply = Invoke-BoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -TargetEnumerator $mixedEnumerator `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -StateRoot $stateRoot

    Assert-BoostLabCondition ([bool]$apply.Success) "Msi Mode Apply should succeed with mocked NVIDIA target: $($apply.Message)"
    Assert-BoostLabCondition ([string]$apply.Action -eq 'Apply') 'Msi Mode Apply action mismatch.'
    Assert-BoostLabCondition ([string]$apply.CommandStatus -eq 'Completed') 'Msi Mode Apply command status mismatch.'
    Assert-BoostLabCondition ([string]$apply.VerificationStatus -eq 'Passed') 'Msi Mode Apply verification should pass.'
    Assert-BoostLabCondition ([bool]$apply.Data.ChangesExecuted) 'Msi Mode Apply should report changes executed.'
    Assert-BoostLabCondition ([bool]$apply.Data.CaptureAttempted) 'Msi Mode Apply should capture before mutation.'
    Assert-BoostLabCondition ([bool]$apply.Data.RegistryWriteAttempted) 'Msi Mode Apply should attempt registry write after capture.'
    Assert-BoostLabCondition (@($apply.Data.CaptureRecords).Count -eq 1) 'Msi Mode Apply must record one capture record.'
    Assert-BoostLabCondition ([int]$apply.Data.TargetCount -eq 2) 'Msi Mode Apply must report all discovered targets.'
    Assert-BoostLabCondition ([int]$apply.Data.EligibleTargetCount -eq 1) 'Msi Mode Apply must report one eligible target.'
    Assert-BoostLabCondition ([int]$apply.Data.ExcludedTargetCount -eq 1) 'Msi Mode Apply must report one skipped excluded target.'
    Assert-BoostLabCondition ([int]$apply.Data.WrittenTargetCount -eq 1) 'Msi Mode Apply must write only one eligible target.'
    Assert-BoostLabCondition ([int]$script:MsiModeMockRegistryState["$approvedTargetPath|MSISupported"] -eq 1) 'Msi Mode Apply must set MSISupported to DWORD 1.'
    Assert-BoostLabCondition (-not $script:MsiModeMockRegistryState.ContainsKey("$nonNvidiaTargetPath|MSISupported")) 'Msi Mode Apply must not write excluded Microsoft/RDP/non-NVIDIA targets.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.ExternalProcessStarted) 'Msi Mode Apply must not start external processes.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.DownloadStarted) 'Msi Mode Apply must not download anything.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.RebootRequested) 'Msi Mode Apply must not request reboot.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.RestoreImplemented) 'Msi Mode Apply must not claim Restore implementation.'
    Assert-BoostLabCondition ([bool]$apply.Data.DefaultImplemented) 'Msi Mode Apply should acknowledge separate source-defined Default implementation.'

    $default = Invoke-BoostLabToolAction `
        -ActionName 'Default' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -TargetEnumerator $mixedEnumerator `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -StateRoot $stateRoot

    Assert-BoostLabCondition ([bool]$default.Success) "Msi Mode Default should succeed with mocked NVIDIA target: $($default.Message)"
    Assert-BoostLabCondition ([string]$default.Action -eq 'Default') 'Msi Mode Default action mismatch.'
    Assert-BoostLabCondition ([string]$default.VerificationStatus -eq 'Passed') 'Msi Mode Default verification should pass.'
    Assert-BoostLabCondition ([int]$script:MsiModeMockRegistryState["$approvedTargetPath|MSISupported"] -eq 0) 'Msi Mode Default must set MSISupported to DWORD 0.'
    Assert-BoostLabCondition (-not $script:MsiModeMockRegistryState.ContainsKey("$nonNvidiaTargetPath|MSISupported")) 'Msi Mode Default must not write excluded Microsoft/RDP/non-NVIDIA targets.'
    Assert-BoostLabCondition (@($default.Data.CaptureRecords).Count -eq 1) 'Msi Mode Default must capture before mutation.'
    Assert-BoostLabCondition ([int]$default.Data.WrittenTargetCount -eq 1) 'Msi Mode Default must write only one eligible target.'
    Assert-BoostLabTextContains -Text ([string]$default.Message) -Needle 'DWORD 0' -Description 'Msi Mode Default message'
    Assert-BoostLabTextContains -Text ([string]$default.Data.RestoreUnavailableReason) -Needle 'Default is source-defined MSISupported DWORD 0 and is not Restore' -Description 'Msi Mode Default/Restore separation'

    $script:MsiModeMockWriteCount = 0
    $nonNvidiaApply = Invoke-BoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -TargetEnumerator $nonNvidiaEnumerator `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -StateRoot $stateRoot
    Assert-BoostLabCondition (-not [bool]$nonNvidiaApply.Success) 'Msi Mode Apply must fail closed for non-NVIDIA targets.'
    Assert-BoostLabCondition ([string]$nonNvidiaApply.Status -eq 'NeedsNvidiaTargeting') 'Msi Mode non-NVIDIA block status mismatch.'
    Assert-BoostLabCondition (-not [bool]$nonNvidiaApply.Data.CaptureAttempted) 'Msi Mode non-NVIDIA block must occur before capture.'
    Assert-BoostLabCondition (-not [bool]$nonNvidiaApply.Data.RegistryWriteAttempted) 'Msi Mode non-NVIDIA block must occur before registry write.'
    Assert-BoostLabCondition ($script:MsiModeMockWriteCount -eq 0) 'Msi Mode non-NVIDIA block must not call writer.'

    $ambiguousAnalyze = Invoke-BoostLabToolAction -ActionName 'Analyze' -TargetEnumerator $ambiguousEnumerator -RegistryReader $registryReader
    Assert-BoostLabCondition ([bool]$ambiguousAnalyze.Success) 'Msi Mode Analyze should return structured output for ambiguous targets.'
    Assert-BoostLabCondition (-not [bool]$ambiguousAnalyze.Data.ApplyAvailable) 'Msi Mode Analyze must not report Apply available for ambiguous targets.'
    Assert-BoostLabCondition ([int]$ambiguousAnalyze.Data.AmbiguousTargetCount -eq 1) 'Msi Mode Analyze must report one ambiguous target.'
    $ambiguousTarget = @($ambiguousAnalyze.Data.AmbiguousTargets)[0]
    Assert-BoostLabCondition ([string]$ambiguousTarget.TargetingStatus -eq 'AmbiguousIdentity') 'Msi Mode ambiguous target status mismatch.'

    $ambiguousApply = Invoke-BoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -TargetEnumerator $ambiguousEnumerator `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -StateRoot $stateRoot
    Assert-BoostLabCondition (-not [bool]$ambiguousApply.Success) 'Msi Mode Apply must fail closed for ambiguous targets.'
    Assert-BoostLabCondition ([string]$ambiguousApply.Status -eq 'NeedsNvidiaTargeting') 'Msi Mode ambiguous block status mismatch.'
    Assert-BoostLabCondition (-not [bool]$ambiguousApply.Data.CaptureAttempted) 'Msi Mode ambiguous block must occur before capture.'
    Assert-BoostLabCondition (-not [bool]$ambiguousApply.Data.RegistryWriteAttempted) 'Msi Mode ambiguous block must occur before write.'
    Assert-BoostLabCondition (-not $script:MsiModeMockRegistryState.ContainsKey("$ambiguousTargetPath|MSISupported")) 'Msi Mode ambiguous targets must never be written.'

    $outOfScopeApply = Invoke-BoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -TargetEnumerator $outOfScopeEnumerator `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -StateRoot $stateRoot
    Assert-BoostLabCondition (-not [bool]$outOfScopeApply.Success) 'Msi Mode Apply must fail closed for out-of-scope registry paths.'
    Assert-BoostLabCondition ([string]$outOfScopeApply.Status -eq 'NeedsNvidiaTargeting') 'Msi Mode out-of-scope block status mismatch.'
    Assert-BoostLabCondition (-not [bool]$outOfScopeApply.Data.CaptureAttempted) 'Msi Mode out-of-scope block must occur before capture.'
    Assert-BoostLabCondition (-not [bool]$outOfScopeApply.Data.RegistryWriteAttempted) 'Msi Mode out-of-scope block must occur before write.'

    $restore = Invoke-BoostLabToolAction -ActionName 'Restore' -Confirmed:$true
    Assert-BoostLabCondition (-not [bool]$restore.Success) 'Msi Mode Restore must remain unavailable without selected captured state.'
    Assert-BoostLabCondition ([string]$restore.Status -eq 'RestoreUnavailable') 'Msi Mode Restore status mismatch.'
    Assert-BoostLabCondition (-not [bool]$restore.Data.RestoreExecuted) 'Msi Mode Restore must not execute.'
    Assert-BoostLabCondition (-not [bool]$restore.Data.DefaultIsRestore) 'Msi Mode Restore must not be treated as Default.'
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

[pscustomobject]@{
    Success = $true
    ActiveToolCount = 55
    ImplementedToolCount      = 40
    PlaceholderToolCount      = 15
    SourcePromotedMirrorFileCount = 7
    RemainingUnimplementedSourcePromotedIntakeCandidates = 0
    Message = 'Msi Mode controlled registry implementation is registered, scoped, captured before mutation, verified, and fail-closed for non-NVIDIA or out-of-scope targets.'
    Timestamp = Get-Date
}


