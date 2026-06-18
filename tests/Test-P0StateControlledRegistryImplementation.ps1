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
Assert-BoostLabCondition ([int]$driverInstallLatestTool.Order -eq 2) 'Driver Install Latest must remain Path B step 1.'
Assert-BoostLabCondition ([int]$nvidiaSettingsTool.Order -eq 3) 'Nvidia Settings must remain Path B step 2.'
Assert-BoostLabCondition ([int]$hdcpTool.Order -eq 4) 'HDCP must remain Path B step 3.'
Assert-BoostLabCondition ([int]$p0StateTool.Order -eq 5) 'P0 State must be Graphics order 5 as Path B step 4.'
Assert-BoostLabCondition ([int]$msiModeTool.Order -eq 6) 'Msi Mode must be Graphics order 6 as Path B step 5.'
Assert-BoostLabCondition ([int]$pathATool.Order -eq 7) 'Path A Driver Install Debloat & Settings must remain separate after Msi Mode.'
Assert-BoostLabCondition ([string]$p0StateTool.Title -eq 'P0 State') 'P0 State title mismatch.'
Assert-BoostLabCondition ([string]$p0StateTool.Type -eq 'action') 'P0 State must be an action tool.'
Assert-BoostLabCondition ([string]$p0StateTool.RiskLevel -eq 'high') 'P0 State must remain high risk.'
Assert-BoostLabCondition ((@($p0StateTool.Actions) -join ',') -eq 'Analyze,Apply,Default,Restore') 'P0 State must use only canonical Analyze, Apply, Default, Restore actions.'

$caps = $p0StateTool.Capabilities
Assert-BoostLabCondition ([bool]$caps.RequiresAdmin) 'P0 State must require Administrator for mutation actions.'
Assert-BoostLabCondition ([bool]$caps.CanModifyRegistry) 'P0 State must declare registry mutation capability.'
Assert-BoostLabCondition ([bool]$caps.SupportsDefault) 'P0 State must declare source-defined Default support.'
Assert-BoostLabCondition (-not [bool]$caps.SupportsRestore) 'P0 State must not claim Restore support without selected captured-state restore flow.'
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
    "'p0-state'",
    "Graphics\p0-state.psm1",
    "'Analyze', 'Apply', 'Default', 'Restore'"
)) {
    Assert-BoostLabTextContains -Text $executionText -Needle $needle -Description 'P0 State execution registration'
}

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
Assert-BoostLabTextContains -Text $actionPlanText -Needle "[ValidateSet('Apply', 'Default', 'Open', 'Analyze', 'Restore')]" -Description 'Action Plan canonical ValidateSet'
Assert-BoostLabCondition (-not $actionPlanText.Contains("'Manual Handoff', 'Apply Auto'")) 'Action Plan ValidateSet must not be widened for P0 State.'
foreach ($needle in @(
    'Apply the source-defined P0 State On value only to eligible NVIDIA display-class registry targets',
    'Apply the source-defined P0 State Default value only to eligible NVIDIA display-class registry targets',
    'No registry mutation is planned without selected captured state',
    'DisableDynamicPstate as REG_DWORD 1',
    'DisableDynamicPstate to DWORD 0',
    'excluded Microsoft/RDP/non-NVIDIA targets are skipped',
    'No external process, download, Control Panel launch, profile import, driver install, reboot, service change, or non-NVIDIA registry write occurs.'
)) {
    Assert-BoostLabTextContains -Text $actionPlanText -Needle $needle -Description 'P0 State action plan'
}

$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($needle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'', ''Restore'')',
    $expectedSourceHash,
    'source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1',
    'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}',
    'DisableDynamicPstate',
    '$script:BoostLabP0StateApplyValue = 1',
    '$script:BoostLabP0StateDefaultValue = 0',
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
    'Default is source-defined DisableDynamicPstate DWORD 0 and is not Restore',
    'Restore requires a selected captured rollback record'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'P0 State module'
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
$approvedTargetPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000'
$nonNvidiaTargetPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001'
$ambiguousTargetPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002'
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

$nvidiaEnumerator = {
    [pscustomobject]@{
        Succeeded = $true
        Targets = @(
            [pscustomobject]@{
                RegistryPath = $approvedTargetPath
                ValueName = 'DisableDynamicPstate'
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
                ValueName = 'DisableDynamicPstate'
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
                ValueName = 'DisableDynamicPstate'
                NvidiaTarget = $true
                Evidence = @('DriverDesc=NVIDIA GeForce RTX', 'MatchingDeviceId=PCI\VEN_10DE&DEV_2684')
            },
            [pscustomobject]@{
                RegistryPath = $nonNvidiaTargetPath
                ValueName = 'DisableDynamicPstate'
                NvidiaTarget = $false
                Evidence = @('DriverDesc=Microsoft Remote Display Adapter', 'ProviderName=Microsoft')
            }
        )
        Warnings = @()
        Message = '2 source-targeted display-class registry target(s) detected.'
    }
}.GetNewClosure()

$ambiguousEnumerator = {
    [pscustomobject]@{
        Succeeded = $true
        Targets = @(
            [pscustomobject]@{
                RegistryPath = $ambiguousTargetPath
                ValueName = 'DisableDynamicPstate'
                NvidiaTarget = $false
                Evidence = @('DriverDesc=Unknown Display Adapter', 'ProviderName=Unknown')
            }
        )
        Warnings = @()
        Message = '1 ambiguous source-targeted display-class registry target detected.'
    }
}.GetNewClosure()

$outOfScopeEnumerator = {
    [pscustomobject]@{
        Succeeded = $true
        Targets = @(
            [pscustomobject]@{
                RegistryPath = 'HKLM:\SOFTWARE\Outside\0000'
                ValueName = 'DisableDynamicPstate'
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

    $script:P0StateMockWriteCount++
    $key = '{0}|{1}' -f ([string]$Target.RegistryPath), 'DisableDynamicPstate'
    $script:P0StateMockRegistryState[$key] = [int]$Value
}.GetNewClosure()

Import-Module -Name $modulePath -Force -ErrorAction Stop
try {
    $info = Get-BoostLabToolInfo
    Assert-BoostLabCondition ([string]$info.Id -eq 'p0-state') 'Imported P0 State module info Id mismatch.'
    Assert-BoostLabCondition ((@($info.ImplementedActions) -join ',') -eq 'Analyze,Apply,Default,Restore') 'P0 State implemented action list mismatch.'

    $analyze = Invoke-BoostLabToolAction -ActionName 'Analyze' -TargetEnumerator $mixedEnumerator -RegistryReader $registryReader
    Assert-BoostLabCondition ([bool]$analyze.Success) 'P0 State Analyze should succeed.'
    Assert-BoostLabCondition ([string]$analyze.Status -eq 'Analyzed') 'P0 State Analyze status mismatch.'
    Assert-BoostLabCondition ([string]$analyze.CommandStatus -eq 'No execution performed') 'P0 State Analyze must be read-only.'
    Assert-BoostLabCondition ([string]$analyze.VerificationStatus -ne 'Failed') 'P0 State Analyze must not fail verification solely because excluded non-NVIDIA targets exist.'
    Assert-BoostLabCondition (-not [bool]$analyze.ChangesExecuted) 'P0 State Analyze must not execute changes.'
    Assert-BoostLabCondition ([int]$analyze.Data.PathBStepNumber -eq 4 -and [int]$analyze.Data.PathBStepTotal -eq 5) 'P0 State Analyze must report Path B step 4 of 5.'
    Assert-BoostLabCondition ([string]$analyze.Data.SourceRegistryValueName -eq 'DisableDynamicPstate') 'P0 State Analyze must report source value name.'
    Assert-BoostLabCondition ([int]$analyze.Data.SourceApplyValue -eq 1 -and [int]$analyze.Data.SourceDefaultValue -eq 0) 'P0 State Analyze must report source Apply/Default values.'
    Assert-BoostLabCondition ([bool]$analyze.Data.ApplyAvailable) 'P0 State Analyze should report Apply available for mocked NVIDIA target.'
    Assert-BoostLabCondition ([bool]$analyze.Data.DefaultAvailable) 'P0 State Analyze should report source-defined Default available for mocked NVIDIA target.'
    Assert-BoostLabCondition ([int]$analyze.Data.TargetCount -eq 2) 'P0 State Analyze must report all immediate display-class targets.'
    Assert-BoostLabCondition ([int]$analyze.Data.EligibleTargetCount -eq 1) 'P0 State Analyze must report one eligible NVIDIA target.'
    Assert-BoostLabCondition ([int]$analyze.Data.ExcludedTargetCount -eq 1) 'P0 State Analyze must report one excluded target.'
    Assert-BoostLabCondition ([int]$analyze.Data.AmbiguousTargetCount -eq 0) 'P0 State Analyze must report zero ambiguous targets for the mixed NVIDIA/Microsoft case.'
    $excludedTarget = @($analyze.Data.ExcludedTargets)[0]
    Assert-BoostLabTextContains -Text ((@($excludedTarget.Evidence) -join '; ')) -Needle 'Microsoft Remote Display Adapter' -Description 'P0 State excluded Microsoft Remote Display Adapter evidence'
    Assert-BoostLabCondition ([string]$excludedTarget.TargetingStatus -eq 'ExcludedNonNvidia') 'P0 State excluded target status mismatch.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.RestoreAvailable) 'P0 State Analyze must not report Restore available without selected captured state.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.CaptureAttempted) 'P0 State Analyze must not capture registry state.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.RegistryWriteAttempted) 'P0 State Analyze must not write registry state.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.ExternalProcessStarted) 'P0 State Analyze must not start external processes.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.DownloadStarted) 'P0 State Analyze must not download anything.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.RebootRequested) 'P0 State Analyze must not request reboot.'

    $cancelledApply = Invoke-BoostLabToolAction -ActionName 'Apply' -TargetEnumerator $nvidiaEnumerator -RegistryReader $registryReader -RegistryWriter $registryWriter -StateRoot $stateRoot
    Assert-BoostLabCondition (-not [bool]$cancelledApply.Success) 'Unconfirmed P0 State Apply should not proceed.'
    Assert-BoostLabCondition ([bool]$cancelledApply.Cancelled) 'Unconfirmed P0 State Apply should be cancelled.'
    Assert-BoostLabCondition ($script:P0StateMockWriteCount -eq 0) 'Unconfirmed P0 State Apply must not write registry.'

    $apply = Invoke-BoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -TargetEnumerator $mixedEnumerator `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -StateRoot $stateRoot

    Assert-BoostLabCondition ([bool]$apply.Success) "P0 State Apply should succeed with mocked NVIDIA target: $($apply.Message)"
    Assert-BoostLabCondition ([string]$apply.Action -eq 'Apply') 'P0 State Apply action mismatch.'
    Assert-BoostLabCondition ([string]$apply.CommandStatus -eq 'Completed') 'P0 State Apply command status mismatch.'
    Assert-BoostLabCondition ([string]$apply.VerificationStatus -eq 'Passed') 'P0 State Apply verification should pass.'
    Assert-BoostLabCondition ([bool]$apply.Data.ChangesExecuted) 'P0 State Apply should report changes executed.'
    Assert-BoostLabCondition ([bool]$apply.Data.CaptureAttempted) 'P0 State Apply should capture before mutation.'
    Assert-BoostLabCondition ([bool]$apply.Data.RegistryWriteAttempted) 'P0 State Apply should attempt registry write after capture.'
    Assert-BoostLabCondition (@($apply.Data.CaptureRecords).Count -eq 1) 'P0 State Apply must record one capture record.'
    Assert-BoostLabCondition ([int]$apply.Data.TargetCount -eq 2) 'P0 State Apply must report all discovered targets.'
    Assert-BoostLabCondition ([int]$apply.Data.EligibleTargetCount -eq 1) 'P0 State Apply must report one eligible target.'
    Assert-BoostLabCondition ([int]$apply.Data.ExcludedTargetCount -eq 1) 'P0 State Apply must report one skipped excluded target.'
    Assert-BoostLabCondition ([int]$apply.Data.WrittenTargetCount -eq 1) 'P0 State Apply must write only one eligible target.'
    Assert-BoostLabCondition ([int]$script:P0StateMockRegistryState["$approvedTargetPath|DisableDynamicPstate"] -eq 1) 'P0 State Apply must set DisableDynamicPstate to DWORD 1.'
    Assert-BoostLabCondition (-not $script:P0StateMockRegistryState.ContainsKey("$nonNvidiaTargetPath|DisableDynamicPstate")) 'P0 State Apply must not write excluded Microsoft/RDP/non-NVIDIA targets.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.ExternalProcessStarted) 'P0 State Apply must not start external processes.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.DownloadStarted) 'P0 State Apply must not download anything.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.RebootRequested) 'P0 State Apply must not request reboot.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.RestoreImplemented) 'P0 State Apply must not claim Restore implementation.'
    Assert-BoostLabCondition ([bool]$apply.Data.DefaultImplemented) 'P0 State Apply should acknowledge separate source-defined Default implementation.'

    $default = Invoke-BoostLabToolAction `
        -ActionName 'Default' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -TargetEnumerator $mixedEnumerator `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -StateRoot $stateRoot

    Assert-BoostLabCondition ([bool]$default.Success) "P0 State Default should succeed with mocked NVIDIA target: $($default.Message)"
    Assert-BoostLabCondition ([string]$default.Action -eq 'Default') 'P0 State Default action mismatch.'
    Assert-BoostLabCondition ([string]$default.VerificationStatus -eq 'Passed') 'P0 State Default verification should pass.'
    Assert-BoostLabCondition ([int]$script:P0StateMockRegistryState["$approvedTargetPath|DisableDynamicPstate"] -eq 0) 'P0 State Default must set DisableDynamicPstate to DWORD 0.'
    Assert-BoostLabCondition (-not $script:P0StateMockRegistryState.ContainsKey("$nonNvidiaTargetPath|DisableDynamicPstate")) 'P0 State Default must not write excluded Microsoft/RDP/non-NVIDIA targets.'
    Assert-BoostLabCondition (@($default.Data.CaptureRecords).Count -eq 1) 'P0 State Default must capture before mutation.'
    Assert-BoostLabCondition ([int]$default.Data.WrittenTargetCount -eq 1) 'P0 State Default must write only one eligible target.'
    Assert-BoostLabTextContains -Text ([string]$default.Message) -Needle 'DWORD 0' -Description 'P0 State Default message'
    Assert-BoostLabTextContains -Text ([string]$default.Data.RestoreUnavailableReason) -Needle 'Default is source-defined DisableDynamicPstate DWORD 0 and is not Restore' -Description 'P0 State Default/Restore separation'

    $script:P0StateMockWriteCount = 0
    $nonNvidiaApply = Invoke-BoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -TargetEnumerator $nonNvidiaEnumerator `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -StateRoot $stateRoot
    Assert-BoostLabCondition (-not [bool]$nonNvidiaApply.Success) 'P0 State Apply must fail closed for non-NVIDIA targets.'
    Assert-BoostLabCondition ([string]$nonNvidiaApply.Status -eq 'NeedsNvidiaTargeting') 'P0 State non-NVIDIA block status mismatch.'
    Assert-BoostLabCondition (-not [bool]$nonNvidiaApply.Data.CaptureAttempted) 'P0 State non-NVIDIA block must occur before capture.'
    Assert-BoostLabCondition (-not [bool]$nonNvidiaApply.Data.RegistryWriteAttempted) 'P0 State non-NVIDIA block must occur before registry write.'
    Assert-BoostLabCondition ($script:P0StateMockWriteCount -eq 0) 'P0 State non-NVIDIA block must not call writer.'

    $ambiguousAnalyze = Invoke-BoostLabToolAction -ActionName 'Analyze' -TargetEnumerator $ambiguousEnumerator -RegistryReader $registryReader
    Assert-BoostLabCondition ([bool]$ambiguousAnalyze.Success) 'P0 State Analyze should return structured output for ambiguous targets.'
    Assert-BoostLabCondition (-not [bool]$ambiguousAnalyze.Data.ApplyAvailable) 'P0 State Analyze must not report Apply available for ambiguous targets.'
    Assert-BoostLabCondition ([int]$ambiguousAnalyze.Data.AmbiguousTargetCount -eq 1) 'P0 State Analyze must report one ambiguous target.'
    $ambiguousTarget = @($ambiguousAnalyze.Data.AmbiguousTargets)[0]
    Assert-BoostLabCondition ([string]$ambiguousTarget.TargetingStatus -eq 'AmbiguousIdentity') 'P0 State ambiguous target status mismatch.'

    $ambiguousApply = Invoke-BoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -TargetEnumerator $ambiguousEnumerator `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -StateRoot $stateRoot
    Assert-BoostLabCondition (-not [bool]$ambiguousApply.Success) 'P0 State Apply must fail closed for ambiguous targets.'
    Assert-BoostLabCondition ([string]$ambiguousApply.Status -eq 'NeedsNvidiaTargeting') 'P0 State ambiguous block status mismatch.'
    Assert-BoostLabCondition (-not [bool]$ambiguousApply.Data.CaptureAttempted) 'P0 State ambiguous block must occur before capture.'
    Assert-BoostLabCondition (-not [bool]$ambiguousApply.Data.RegistryWriteAttempted) 'P0 State ambiguous block must occur before write.'
    Assert-BoostLabCondition (-not $script:P0StateMockRegistryState.ContainsKey("$ambiguousTargetPath|DisableDynamicPstate")) 'P0 State ambiguous targets must never be written.'

    $outOfScopeApply = Invoke-BoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -TargetEnumerator $outOfScopeEnumerator `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -StateRoot $stateRoot
    Assert-BoostLabCondition (-not [bool]$outOfScopeApply.Success) 'P0 State Apply must fail closed for out-of-scope registry paths.'
    Assert-BoostLabCondition ([string]$outOfScopeApply.Status -eq 'NeedsNvidiaTargeting') 'P0 State out-of-scope block status mismatch.'
    Assert-BoostLabCondition (-not [bool]$outOfScopeApply.Data.CaptureAttempted) 'P0 State out-of-scope block must occur before capture.'
    Assert-BoostLabCondition (-not [bool]$outOfScopeApply.Data.RegistryWriteAttempted) 'P0 State out-of-scope block must occur before write.'

    $restore = Invoke-BoostLabToolAction -ActionName 'Restore' -Confirmed:$true
    Assert-BoostLabCondition (-not [bool]$restore.Success) 'P0 State Restore must remain unavailable without selected captured state.'
    Assert-BoostLabCondition ([string]$restore.Status -eq 'RestoreUnavailable') 'P0 State Restore status mismatch.'
    Assert-BoostLabCondition (-not [bool]$restore.Data.RestoreExecuted) 'P0 State Restore must not execute.'
    Assert-BoostLabCondition (-not [bool]$restore.Data.DefaultIsRestore) 'P0 State Restore must not be treated as Default.'
}
finally {
    Remove-Module -Name p0-state -Force -ErrorAction SilentlyContinue
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
    Message = 'P0 State controlled registry implementation is registered, scoped, captured before mutation, verified, and fail-closed for non-NVIDIA or out-of-scope targets.'
    Timestamp = Get-Date
}

