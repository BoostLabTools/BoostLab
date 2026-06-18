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
Assert-BoostLabCondition ([int]$driverInstallLatestTool.Order -eq 2) 'Driver Install Latest must remain Path B step 1.'
Assert-BoostLabCondition ([int]$nvidiaSettingsTool.Order -eq 3) 'Nvidia Settings must remain Path B step 2.'
Assert-BoostLabCondition ([int]$hdcpTool.Order -eq 4) 'HDCP must be Graphics order 4 as Path B step 3.'
Assert-BoostLabCondition ([int]$p0StateTool.Order -eq 5) 'P0 State must be Graphics order 5 as Path B step 4.'
Assert-BoostLabCondition ([int]$msiModeTool.Order -eq 6) 'Msi Mode must be Graphics order 6 as Path B step 5.'
Assert-BoostLabCondition ([int]$pathATool.Order -eq 7) 'Path A Driver Install Debloat & Settings must remain separate after Msi Mode.'
Assert-BoostLabCondition ([string]$hdcpTool.Title -eq 'HDCP') 'HDCP title mismatch.'
Assert-BoostLabCondition ([string]$hdcpTool.Type -eq 'action') 'HDCP must be an action tool.'
Assert-BoostLabCondition ([string]$hdcpTool.RiskLevel -eq 'high') 'HDCP must remain high risk.'
Assert-BoostLabCondition ((@($hdcpTool.Actions) -join ',') -eq 'Analyze,Apply,Default,Restore') 'HDCP must use only canonical Analyze, Apply, Default, Restore actions.'

$caps = $hdcpTool.Capabilities
Assert-BoostLabCondition ([bool]$caps.RequiresAdmin) 'HDCP must require Administrator for mutation actions.'
Assert-BoostLabCondition ([bool]$caps.CanModifyRegistry) 'HDCP must declare registry mutation capability.'
Assert-BoostLabCondition ([bool]$caps.SupportsDefault) 'HDCP must declare source-defined Default support.'
Assert-BoostLabCondition (-not [bool]$caps.SupportsRestore) 'HDCP must not claim Restore support without selected captured-state restore flow.'
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
Assert-BoostLabCondition ($allTools.Count -eq 55) "Expected 55 active tools, found $($allTools.Count)."
Assert-BoostLabCondition ($placeholderModules.Count -eq 18) "Expected 18 deferred/placeholders, found $($placeholderModules.Count)."
Assert-BoostLabCondition (($allTools.Count - $placeholderModules.Count) -eq 37) "Expected 37 implemented tools, found $($allTools.Count - $placeholderModules.Count)."

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
    "'hdcp'",
    "Graphics\hdcp.psm1",
    "'Analyze', 'Apply', 'Default', 'Restore'"
)) {
    Assert-BoostLabTextContains -Text $executionText -Needle $needle -Description 'HDCP execution registration'
}

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
Assert-BoostLabTextContains -Text $actionPlanText -Needle "[ValidateSet('Apply', 'Default', 'Open', 'Analyze', 'Restore')]" -Description 'Action Plan canonical ValidateSet'
Assert-BoostLabCondition (-not $actionPlanText.Contains("'Manual Handoff', 'Apply Auto'")) 'Action Plan ValidateSet must not be widened for HDCP.'
foreach ($needle in @(
    'Apply the source-defined HDCP Off value only to eligible NVIDIA display-class registry targets',
    'Apply the source-defined HDCP Default value only to eligible NVIDIA display-class registry targets',
    'No registry mutation is planned without selected captured state',
    'RMHdcpKeyglobZero as REG_DWORD 1',
    'RMHdcpKeyglobZero to DWORD 0',
    'excluded Microsoft/RDP/non-NVIDIA targets are skipped',
    'No external process, download, Control Panel launch, profile import, driver install, reboot, service change, or non-NVIDIA registry write occurs.'
)) {
    Assert-BoostLabTextContains -Text $actionPlanText -Needle $needle -Description 'HDCP action plan'
}

$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($needle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'', ''Restore'')',
    $expectedSourceHash,
    'source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1',
    'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}',
    'RMHdcpKeyglobZero',
    '$script:BoostLabHdcpApplyValue = 1',
    '$script:BoostLabHdcpDefaultValue = 0',
    'New-BoostLabRegistryStateCapture',
    'Set-BoostLabRollbackMutationState',
    'NeedsNvidiaTargeting',
    'EligibleTargets',
    'ExcludedTargets',
    'ExcludedNonNvidia',
    'Microsoft/RDP/non-NVIDIA display adapter',
    'VEN_10DE',
    'Default is source-defined DWORD 0 and is not Restore',
    'Restore requires a selected captured rollback record'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'HDCP module'
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
$approvedTargetPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000'
$nonNvidiaTargetPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001'
$script:HdcpMockRegistryState = @{}
$script:HdcpMockWriteCount = 0

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

$nvidiaEnumerator = {
    [pscustomobject]@{
        Succeeded = $true
        Targets = @(
            [pscustomobject]@{
                RegistryPath = $approvedTargetPath
                ValueName = 'RMHdcpKeyglobZero'
                NvidiaTarget = $true
                Evidence = @('DriverDesc=NVIDIA GeForce RTX', 'MatchingDeviceId=PCI\VEN_10DE&DEV_2684')
            }
        )
        Warnings = @()
        Message = '1 source-targeted display-class registry target(s) detected.'
    }
}.GetNewClosure()

$nonNvidiaEnumerator = {
    [pscustomobject]@{
        Succeeded = $true
        Targets = @(
            [pscustomobject]@{
                RegistryPath = $nonNvidiaTargetPath
                ValueName = 'RMHdcpKeyglobZero'
                NvidiaTarget = $false
                Evidence = @('DriverDesc=Microsoft Basic Display Adapter')
            }
        )
        Warnings = @()
        Message = '1 source-targeted display-class registry target(s) detected.'
    }
}.GetNewClosure()

$mixedEnumerator = {
    [pscustomobject]@{
        Succeeded = $true
        Targets = @(
            [pscustomobject]@{
                RegistryPath = $approvedTargetPath
                ValueName = 'RMHdcpKeyglobZero'
                NvidiaTarget = $true
                Evidence = @('DriverDesc=NVIDIA GeForce RTX', 'MatchingDeviceId=PCI\VEN_10DE&DEV_2684')
            },
            [pscustomobject]@{
                RegistryPath = $nonNvidiaTargetPath
                ValueName = 'RMHdcpKeyglobZero'
                NvidiaTarget = $false
                Evidence = @('DriverDesc=Microsoft Remote Display Adapter', 'ProviderName=Microsoft')
            }
        )
        Warnings = @()
        Message = '2 source-targeted display-class registry target(s) detected.'
    }
}.GetNewClosure()

$outOfScopeEnumerator = {
    [pscustomobject]@{
        Succeeded = $true
        Targets = @(
            [pscustomobject]@{
                RegistryPath = 'HKLM:\SOFTWARE\Outside\0000'
                ValueName = 'RMHdcpKeyglobZero'
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

    $script:HdcpMockWriteCount++
    $key = '{0}|{1}' -f ([string]$Target.RegistryPath), 'RMHdcpKeyglobZero'
    $script:HdcpMockRegistryState[$key] = [int]$Value
}.GetNewClosure()

Import-Module -Name $modulePath -Force -ErrorAction Stop
try {
    $info = Get-BoostLabToolInfo
    Assert-BoostLabCondition ([string]$info.Id -eq 'hdcp') 'Imported HDCP module info Id mismatch.'
    Assert-BoostLabCondition ((@($info.ImplementedActions) -join ',') -eq 'Analyze,Apply,Default,Restore') 'HDCP implemented action list mismatch.'

    $analyze = Invoke-BoostLabToolAction -ActionName 'Analyze' -TargetEnumerator $mixedEnumerator -RegistryReader $registryReader
    Assert-BoostLabCondition ([bool]$analyze.Success) 'HDCP Analyze should succeed.'
    Assert-BoostLabCondition ([string]$analyze.Status -eq 'Analyzed') 'HDCP Analyze status mismatch.'
    Assert-BoostLabCondition ([string]$analyze.CommandStatus -eq 'No execution performed') 'HDCP Analyze must be read-only.'
    Assert-BoostLabCondition ([string]$analyze.VerificationStatus -ne 'Failed') 'HDCP Analyze must not fail verification solely because excluded non-NVIDIA targets exist.'
    Assert-BoostLabCondition (-not [bool]$analyze.ChangesExecuted) 'HDCP Analyze must not execute changes.'
    Assert-BoostLabCondition ([int]$analyze.Data.PathBStepNumber -eq 3 -and [int]$analyze.Data.PathBStepTotal -eq 5) 'HDCP Analyze must report Path B step 3 of 5.'
    Assert-BoostLabCondition ([string]$analyze.Data.SourceRegistryValueName -eq 'RMHdcpKeyglobZero') 'HDCP Analyze must report source value name.'
    Assert-BoostLabCondition ([int]$analyze.Data.SourceApplyValue -eq 1 -and [int]$analyze.Data.SourceDefaultValue -eq 0) 'HDCP Analyze must report source Apply/Default values.'
    Assert-BoostLabCondition ([bool]$analyze.Data.ApplyAvailable) 'HDCP Analyze should report Apply available for mocked NVIDIA target.'
    Assert-BoostLabCondition ([bool]$analyze.Data.DefaultAvailable) 'HDCP Analyze should report source-defined Default available for mocked NVIDIA target.'
    Assert-BoostLabCondition ([int]$analyze.Data.TargetCount -eq 2) 'HDCP Analyze must report all immediate display-class targets.'
    Assert-BoostLabCondition ([int]$analyze.Data.EligibleTargetCount -eq 1) 'HDCP Analyze must report one eligible NVIDIA target.'
    Assert-BoostLabCondition ([int]$analyze.Data.ExcludedTargetCount -eq 1) 'HDCP Analyze must report one excluded target.'
    Assert-BoostLabTextContains -Text ((@($analyze.Data.ExcludedTargets[0].Evidence) -join '; ')) -Needle 'Microsoft Remote Display Adapter' -Description 'HDCP excluded Microsoft Remote Display Adapter evidence'
    Assert-BoostLabCondition ([string]$analyze.Data.ExcludedTargets[0].TargetingStatus -eq 'ExcludedNonNvidia') 'HDCP excluded target status mismatch.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.RestoreAvailable) 'HDCP Analyze must not report Restore available without selected captured state.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.CaptureAttempted) 'HDCP Analyze must not capture registry state.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.RegistryWriteAttempted) 'HDCP Analyze must not write registry state.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.ExternalProcessStarted) 'HDCP Analyze must not start external processes.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.DownloadStarted) 'HDCP Analyze must not download anything.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.RebootRequested) 'HDCP Analyze must not request reboot.'

    $cancelledApply = Invoke-BoostLabToolAction -ActionName 'Apply' -TargetEnumerator $nvidiaEnumerator -RegistryReader $registryReader -RegistryWriter $registryWriter -StateRoot $stateRoot
    Assert-BoostLabCondition (-not [bool]$cancelledApply.Success) 'Unconfirmed HDCP Apply should not proceed.'
    Assert-BoostLabCondition ([bool]$cancelledApply.Cancelled) 'Unconfirmed HDCP Apply should be cancelled.'
    Assert-BoostLabCondition ($script:HdcpMockWriteCount -eq 0) 'Unconfirmed HDCP Apply must not write registry.'

    $apply = Invoke-BoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -TargetEnumerator $mixedEnumerator `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -StateRoot $stateRoot

    Assert-BoostLabCondition ([bool]$apply.Success) "HDCP Apply should succeed with mocked NVIDIA target: $($apply.Message)"
    Assert-BoostLabCondition ([string]$apply.Action -eq 'Apply') 'HDCP Apply action mismatch.'
    Assert-BoostLabCondition ([string]$apply.CommandStatus -eq 'Completed') 'HDCP Apply command status mismatch.'
    Assert-BoostLabCondition ([string]$apply.VerificationStatus -eq 'Passed') 'HDCP Apply verification should pass.'
    Assert-BoostLabCondition ([bool]$apply.Data.ChangesExecuted) 'HDCP Apply should report changes executed.'
    Assert-BoostLabCondition ([bool]$apply.Data.CaptureAttempted) 'HDCP Apply should capture before mutation.'
    Assert-BoostLabCondition ([bool]$apply.Data.RegistryWriteAttempted) 'HDCP Apply should attempt registry write after capture.'
    Assert-BoostLabCondition (@($apply.Data.CaptureRecords).Count -eq 1) 'HDCP Apply must record one capture record.'
    Assert-BoostLabCondition ([int]$apply.Data.TargetCount -eq 2) 'HDCP Apply must report all discovered targets.'
    Assert-BoostLabCondition ([int]$apply.Data.EligibleTargetCount -eq 1) 'HDCP Apply must report one eligible target.'
    Assert-BoostLabCondition ([int]$apply.Data.ExcludedTargetCount -eq 1) 'HDCP Apply must report one skipped excluded target.'
    Assert-BoostLabCondition ([int]$apply.Data.WrittenTargetCount -eq 1) 'HDCP Apply must write only one eligible target.'
    Assert-BoostLabCondition ([int]$script:HdcpMockRegistryState["$approvedTargetPath|RMHdcpKeyglobZero"] -eq 1) 'HDCP Apply must set RMHdcpKeyglobZero to DWORD 1.'
    Assert-BoostLabCondition (-not $script:HdcpMockRegistryState.ContainsKey("$nonNvidiaTargetPath|RMHdcpKeyglobZero")) 'HDCP Apply must not write excluded Microsoft/RDP/non-NVIDIA targets.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.ExternalProcessStarted) 'HDCP Apply must not start external processes.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.DownloadStarted) 'HDCP Apply must not download anything.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.RebootRequested) 'HDCP Apply must not request reboot.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.RestoreImplemented) 'HDCP Apply must not claim Restore implementation.'
    Assert-BoostLabCondition ([bool]$apply.Data.DefaultImplemented) 'HDCP Apply should acknowledge separate source-defined Default implementation.'

    $default = Invoke-BoostLabToolAction `
        -ActionName 'Default' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -TargetEnumerator $mixedEnumerator `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -StateRoot $stateRoot

    Assert-BoostLabCondition ([bool]$default.Success) "HDCP Default should succeed with mocked NVIDIA target: $($default.Message)"
    Assert-BoostLabCondition ([string]$default.Action -eq 'Default') 'HDCP Default action mismatch.'
    Assert-BoostLabCondition ([string]$default.VerificationStatus -eq 'Passed') 'HDCP Default verification should pass.'
    Assert-BoostLabCondition ([int]$script:HdcpMockRegistryState["$approvedTargetPath|RMHdcpKeyglobZero"] -eq 0) 'HDCP Default must set RMHdcpKeyglobZero to DWORD 0.'
    Assert-BoostLabCondition (-not $script:HdcpMockRegistryState.ContainsKey("$nonNvidiaTargetPath|RMHdcpKeyglobZero")) 'HDCP Default must not write excluded Microsoft/RDP/non-NVIDIA targets.'
    Assert-BoostLabCondition (@($default.Data.CaptureRecords).Count -eq 1) 'HDCP Default must capture before mutation.'
    Assert-BoostLabCondition ([int]$default.Data.WrittenTargetCount -eq 1) 'HDCP Default must write only one eligible target.'
    Assert-BoostLabTextContains -Text ([string]$default.Message) -Needle 'DWORD 0' -Description 'HDCP Default message'
    Assert-BoostLabTextContains -Text ([string]$default.Data.RestoreUnavailableReason) -Needle 'Default is source-defined DWORD 0 and is not Restore' -Description 'HDCP Default/Restore separation'

    $script:HdcpMockWriteCount = 0
    $nonNvidiaApply = Invoke-BoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -TargetEnumerator $nonNvidiaEnumerator `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -StateRoot $stateRoot
    Assert-BoostLabCondition (-not [bool]$nonNvidiaApply.Success) 'HDCP Apply must fail closed for non-NVIDIA targets.'
    Assert-BoostLabCondition ([string]$nonNvidiaApply.Status -eq 'NeedsNvidiaTargeting') 'HDCP non-NVIDIA block status mismatch.'
    Assert-BoostLabCondition (-not [bool]$nonNvidiaApply.Data.CaptureAttempted) 'HDCP non-NVIDIA block must occur before capture.'
    Assert-BoostLabCondition (-not [bool]$nonNvidiaApply.Data.RegistryWriteAttempted) 'HDCP non-NVIDIA block must occur before registry write.'
    Assert-BoostLabCondition ($script:HdcpMockWriteCount -eq 0) 'HDCP non-NVIDIA block must not call writer.'

    $outOfScopeApply = Invoke-BoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -TargetEnumerator $outOfScopeEnumerator `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -StateRoot $stateRoot
    Assert-BoostLabCondition (-not [bool]$outOfScopeApply.Success) 'HDCP Apply must fail closed for out-of-scope registry paths.'
    Assert-BoostLabCondition ([string]$outOfScopeApply.Status -eq 'NeedsNvidiaTargeting') 'HDCP out-of-scope block status mismatch.'
    Assert-BoostLabCondition (-not [bool]$outOfScopeApply.Data.CaptureAttempted) 'HDCP out-of-scope block must occur before capture.'
    Assert-BoostLabCondition (-not [bool]$outOfScopeApply.Data.RegistryWriteAttempted) 'HDCP out-of-scope block must occur before write.'

    $restore = Invoke-BoostLabToolAction -ActionName 'Restore' -Confirmed:$true
    Assert-BoostLabCondition (-not [bool]$restore.Success) 'HDCP Restore must remain unavailable without selected captured state.'
    Assert-BoostLabCondition ([string]$restore.Status -eq 'RestoreUnavailable') 'HDCP Restore status mismatch.'
    Assert-BoostLabCondition (-not [bool]$restore.Data.RestoreExecuted) 'HDCP Restore must not execute.'
    Assert-BoostLabCondition (-not [bool]$restore.Data.DefaultIsRestore) 'HDCP Restore must not be treated as Default.'
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

[pscustomobject]@{
    Success = $true
    ActiveToolCount = 55
    ImplementedToolCount = 37
    PlaceholderToolCount = 18
    SourcePromotedMirrorFileCount = 7
    RemainingUnimplementedSourcePromotedIntakeCandidates = 0
    Message = 'HDCP controlled registry implementation is registered, scoped, captured before mutation, verified, and fail-closed for non-NVIDIA or out-of-scope targets.'
    Timestamp = Get-Date
}
