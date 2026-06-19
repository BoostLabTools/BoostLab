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
        throw 'Unable to determine the BitLocker ordered parity upgrade validator path.'
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

$inventoryAssertion = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
$inventorySnapshot = $inventoryAssertion.Snapshot
$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot

$modulePath = Join-Path $ProjectRoot 'modules\Setup\bitlocker.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate\3 Setup\1 BitLocker.ps1'
$intakePath = Join-Path $ProjectRoot 'intake\missing-ultimate-scripts\Ultimate\3 Setup\1 BitLocker.ps1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'

$expectedSourceHash = '1678E97FB5AFF851F1491A2D96C82A5716B1FA07CB4E3A4A5E0F3FB1B086FBA1'
Assert-BoostLabCondition ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -eq $expectedSourceHash) 'BitLocker promoted source hash changed.'
Assert-BoostLabCondition ((Get-FileHash -Algorithm SHA256 -LiteralPath $intakePath).Hash -eq $expectedSourceHash) 'BitLocker intake source hash changed.'

$setupOrder = @($executionOrder.Stages | Where-Object { [string]$_.Name -eq 'Setup' }) | Select-Object -First 1
Assert-BoostLabCondition ([string]@($setupOrder.Tools)[0].ToolId -eq 'bitlocker') 'BitLocker must remain first in the ordered Setup parity stage.'

$bitLockerRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'bitlocker' }) | Select-Object -First 1
Assert-BoostLabCondition ([string]$bitLockerRecord.ImplementationLevel -eq 'NearParityControlled') 'BitLocker implementation level must be NearParityControlled.'
Assert-BoostLabCondition ([string]$bitLockerRecord.UltimateParity -eq 'Partial') 'BitLocker UltimateParity should remain Partial by convention.'
Assert-BoostLabCondition ([string]$bitLockerRecord.FinalProgressStatus -eq 'DoneYazanAcceptedNearParity') 'BitLocker final progress status mismatch.'
Assert-BoostLabCondition ([bool]$bitLockerRecord.YazanAcceptedNearParity) 'BitLocker must be YazanAcceptedNearParity.'
Assert-BoostLabCondition (-not [bool]$bitLockerRecord.YazanFinalException) 'BitLocker must not use YazanFinalException.'
Assert-BoostLabCondition (Test-BoostLabParityRecordFinal -Record $bitLockerRecord) 'BitLocker accepted near-parity must be final for ordered target calculation.'

$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq 'driver-install-debloat-settings') 'Next ordered pending parity target must advance past Driver Clean near-parity acceptance.'

$sourceText = Get-Content -Raw -LiteralPath $sourcePath
foreach ($sourceNeedle in @(
    'Get-BitLockerVolume',
    '$_.ProtectionStatus -eq "On" -or $_.VolumeStatus -ne "FullyDecrypted"',
    'Disable-BitLocker -MountPoint $_.MountPoint -ErrorAction SilentlyContinue',
    'Start-Process control.exe -ArgumentList "/name microsoft.bitlockerdriveencryption"',
    'manage-bde -status'
)) {
    Assert-BoostLabTextContains -Text $sourceText -Needle $sourceNeedle -Description 'BitLocker source branch'
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
$bitLockerModule = Import-Module -Name $modulePath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    $toolInfo = Get-BoostLabToolInfo
    Assert-BoostLabCondition ((@($toolInfo.ImplementedActions) -join '|') -eq 'Analyze|Apply|Default|Restore|Open') 'BitLocker implemented actions mismatch.'
    Assert-BoostLabCondition ((@($toolInfo.ConfirmationRequiredActions) -join '|') -eq 'Open|Apply|Default|Restore') 'BitLocker confirmation-required actions mismatch.'

    $config = Import-PowerShellDataFile -LiteralPath $configPath
    $toolMetadata = @($config.Stages | ForEach-Object { $_.Tools } | Where-Object { $_.Id -eq 'bitlocker' }) | Select-Object -First 1
    Assert-BoostLabCondition ($null -ne $toolMetadata) 'BitLocker tool metadata was not found in config.'

    $actionPlanText = Get-Content -Raw -LiteralPath $actionPlanPath
    foreach ($needle in @(
        'Get-BitLockerVolume',
        'ProtectionStatus is On or VolumeStatus is not FullyDecrypted',
        'Disable-BitLocker -MountPoint <mount> -ErrorAction SilentlyContinue',
        'manage-bde -status',
        'Recovery keys are not collected',
        'BitLocker Drive Encryption Control Panel',
        'Do not enable BitLocker automatically'
    )) {
        Assert-BoostLabTextContains -Text $actionPlanText -Needle $needle -Description 'BitLocker action plan source'
    }

    $mockVolumeReader = {
        @(
            [pscustomobject]@{
                MountPoint = 'C:'
                VolumeStatus = 'FullyEncrypted'
                ProtectionStatus = 'On'
                EncryptionPercentage = 100
                LockStatus = 'Unlocked'
                KeyProtector = @(
                    [pscustomobject]@{ KeyProtectorType = 'RecoveryPassword'; RecoveryPassword = '111111-222222-333333-444444-555555-666666-777777-888888' }
                )
            }
            [pscustomobject]@{
                MountPoint = 'D:'
                VolumeStatus = 'FullyDecrypted'
                ProtectionStatus = 'Off'
                EncryptionPercentage = 0
                LockStatus = 'Unlocked'
                KeyProtector = @()
            }
            [pscustomobject]@{
                MountPoint = 'E:'
                VolumeStatus = 'EncryptionInProgress'
                ProtectionStatus = 'Off'
                EncryptionPercentage = 30
                LockStatus = 'Unlocked'
                KeyProtector = @()
            }
        )
    }

    $disableCalls = [System.Collections.Generic.List[string]]::new()
    $controlCalls = [System.Collections.Generic.List[string]]::new()
    $manageCalls = [System.Collections.Generic.List[string]]::new()
    $disableExecutor = {
        param([string]$MountPoint)
        $disableCalls.Add($MountPoint)
        [pscustomobject]@{ Success = $true; CommandStatus = 'Completed'; Message = "Mock Disable-BitLocker $MountPoint." }
    }.GetNewClosure()
    $controlLauncher = {
        param([string]$FilePath, [string]$ArgumentList)
        $controlCalls.Add("$FilePath $ArgumentList")
        [pscustomobject]@{ Success = $true; CommandStatus = 'Completed'; Message = 'Mock Control Panel.' }
    }.GetNewClosure()
    $statusExecutor = {
        param([string[]]$ArgumentList)
        $manageCalls.Add(($ArgumentList -join ' '))
        [pscustomobject]@{ Success = $true; CommandStatus = 'Completed'; ExitCode = 0; Message = 'Mock manage-bde.' }
    }.GetNewClosure()

    $analyze = Invoke-BoostLabToolAction -ActionName Analyze -VolumeReader $mockVolumeReader
    Assert-BoostLabCondition ([bool]$analyze.Success) 'BitLocker Analyze should succeed.'
    Assert-BoostLabCondition ([string]$analyze.CommandStatus -eq 'No execution performed') 'Analyze must be read-only.'
    Assert-BoostLabCondition ([int]$analyze.Data.SourceOffTargetCount -eq 2) 'Analyze must identify the two source Off target volumes.'
    Assert-BoostLabCondition ((@($analyze.Data.SourceOffOperationPlan.TargetMountPoints) -join '|') -eq 'C:|E:') 'Analyze Off operation plan target MountPoints mismatch.'

    $open = Invoke-BoostLabToolAction -ActionName Open -Confirmed:$true -VolumeReader $mockVolumeReader -ControlPanelLauncher $controlLauncher -ManageBdeStatusExecutor $statusExecutor
    Assert-BoostLabCondition ([bool]$open.Success) 'Open/status should succeed through mocks.'
    Assert-BoostLabCondition ([string]$open.Status -eq 'StatusOpened') 'Open/status result mismatch.'
    Assert-BoostLabCondition (-not [bool]$open.Data.AutomaticEnableBitLocker) 'Open/status must not enable BitLocker.'
    Assert-BoostLabCondition (-not [bool]$open.Data.BitLockerStateMutation) 'Open/status must not mutate BitLocker state.'
    Assert-BoostLabCondition ($controlCalls.Count -eq 1) 'Open/status must route one Control Panel request to the mock.'
    Assert-BoostLabCondition ($manageCalls.Count -eq 1) 'Open/status must route one manage-bde request to the mock.'

    $apply = Invoke-BoostLabToolAction -ActionName Apply -Confirmed:$true -VolumeReader $mockVolumeReader -DisableBitLockerExecutor $disableExecutor -ControlPanelLauncher $controlLauncher -ManageBdeStatusExecutor $statusExecutor
    Assert-BoostLabCondition ([bool]$apply.Success) 'Apply should succeed through mocks.'
    Assert-BoostLabCondition ([string]$apply.Status -eq 'Completed') 'Apply result status mismatch.'
    Assert-BoostLabCondition ([string]$apply.CommandStatus -eq 'Completed') 'Apply command status mismatch.'
    Assert-BoostLabCondition ([bool]$apply.ChangesExecuted) 'Apply should report changes when Disable-BitLocker targets exist.'
    Assert-BoostLabCondition (($disableCalls -join '|') -eq 'C:|E:') 'Apply must disable only source-matched MountPoints.'
    Assert-BoostLabCondition ([int]$apply.Data.TargetVolumeCount -eq 2) 'Apply target volume count mismatch.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.AutomaticEnableBitLocker) 'Apply must not enable BitLocker.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.RecoveryKeysCollectedDisplayedOrPersisted) 'Apply must not collect/display/persist recovery keys.'
    $applyJson = $apply | ConvertTo-Json -Depth 12
    Assert-BoostLabCondition (-not $applyJson.Contains('111111-222222-333333-444444-555555-666666-777777-888888')) 'Apply must not expose recovery key values.'

    $default = Invoke-BoostLabToolAction -ActionName Default -Confirmed:$true -VolumeReader $mockVolumeReader
    Assert-BoostLabCondition (-not [bool]$default.Success) 'Default must remain unavailable.'
    Assert-BoostLabCondition ([string]$default.Status -eq 'DefaultUnavailable') 'Default status mismatch.'

    $restore = Invoke-BoostLabToolAction -ActionName Restore -Confirmed:$true -VolumeReader $mockVolumeReader
    Assert-BoostLabCondition (-not [bool]$restore.Success) 'Restore must remain unavailable.'
    Assert-BoostLabCondition ([string]$restore.Status -eq 'RestoreUnavailable') 'Restore status mismatch.'
}
finally {
    if ($bitLockerModule) {
        Remove-Module $bitLockerModule -Force -ErrorAction SilentlyContinue
    }
    if ($actionPlanModule) {
        Remove-Module $actionPlanModule -Force -ErrorAction SilentlyContinue
    }
}

$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPath
$productionPolicy = Import-PowerShellDataFile -LiteralPath $productionAllowlistPath
if ($artifactPolicy.ContainsKey('Artifacts')) {
    Assert-BoostLabCondition (@($artifactPolicy.Artifacts).Count -eq 0) 'Artifact provenance approvals must remain empty.'
}
if ($productionPolicy.ContainsKey('ProductionAllowlistProposals')) {
    Assert-BoostLabCondition (@($productionPolicy.ProductionAllowlistProposals).Count -eq 0) 'Production allowlist proposals must remain empty.'
}

Assert-BoostLabCondition ([int]$inventorySnapshot.ActiveTools -eq 55) 'Active tool count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.ImplementedTools -eq 45) 'Runtime implemented count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.DeferredPlaceholders -eq 10) 'Deferred placeholder count changed.'

foreach ($deletedPath in @(
    'source-ultimate\6 Windows\17 Loudness EQ.ps1',
    'source-ultimate\6 Windows\30 NVME Faster Driver.ps1'
)) {
    Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $deletedPath))) "Deleted source was reintroduced: $deletedPath"
}

[pscustomobject]@{
    Test = 'BitLockerOrderedParityUpgrade'
    SourcePath = 'source-ultimate/_intake-promoted/Ultimate/3 Setup/1 BitLocker.ps1'
    SourceHash = $expectedSourceHash
    ApplyRoutesDisableBitLockerThroughMock = $true
    OpenRoutesStatusThroughMock = $true
    RealBitLockerMutationExecuted = $false
    RealManageBdeExecuted = $false
    RealControlPanelLaunched = $false
    NextOrderedPendingTarget = $nextTarget.ToolId
    Message = 'BitLocker ordered parity upgrade preserves source-equivalent Off and On/status behavior through test-safe mocks.'
}
