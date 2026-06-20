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
        throw 'Unable to determine the BitLocker ordered parity validator path.'
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

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$orderPath = Join-Path $ProjectRoot 'config\UltimateParityExecutionOrder.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Setup\bitlocker.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate\3 Setup\1 BitLocker.ps1'
$intakePath = Join-Path $ProjectRoot 'intake\missing-ultimate-scripts\Ultimate\3 Setup\1 BitLocker.ps1'
$migrationPath = Join-Path $ProjectRoot 'docs\migrations\bitlocker.md'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'

foreach ($path in @($configPath, $orderPath, $modulePath, $sourcePath, $intakePath, $migrationPath, $artifactPath, $productionAllowlistPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required BitLocker parity file was not found: $path"
}

$expectedSourceHash = '1678E97FB5AFF851F1491A2D96C82A5716B1FA07CB4E3A4A5E0F3FB1B086FBA1'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "BitLocker source mirror hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."
Assert-BoostLabCondition ((Get-FileHash -Algorithm SHA256 -LiteralPath $intakePath).Hash -eq $expectedSourceHash) 'BitLocker intake source hash changed.'

$sourceText = Get-Content -Raw -LiteralPath $sourcePath
foreach ($needle in @(
    'Write-Host "1. BitLocker: Off (Recommended)"',
    'Write-Host "2. BitLocker: On`n"',
    'Get-BitLockerVolume',
    '$_.ProtectionStatus -eq "On" -or $_.VolumeStatus -ne "FullyDecrypted"',
    'Disable-BitLocker -MountPoint $_.MountPoint -ErrorAction SilentlyContinue',
    'Start-Process control.exe -ArgumentList "/name microsoft.bitlockerdriveencryption"',
    'manage-bde -status'
)) {
    Assert-BoostLabTextContains -Text $sourceText -Needle $needle -Description 'BitLocker Ultimate source behavior'
}

$config = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })
$setupOrder = @($executionOrder.Stages | Where-Object { [string]$_.Name -eq 'Setup' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $setupOrder) 'Setup stage was not found in ordered parity execution baseline.'
Assert-BoostLabCondition ([string]$executionOrder.Rule -match 'final canonical') 'Execution order rule must document the Phase 116 canonical Yazan order.'
Assert-BoostLabCondition ([string]@($setupOrder.Tools)[0].ToolId -eq 'bitlocker') 'BitLocker must be first in Setup ordered parity execution.'

$bitLockerRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'bitlocker' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $bitLockerRecord) 'BitLocker parity record was not found.'
Assert-BoostLabCondition ([string]$bitLockerRecord.RuntimeStatus -eq 'RuntimeImplemented') 'BitLocker runtime status mismatch.'
Assert-BoostLabCondition ([string]$bitLockerRecord.ImplementationLevel -eq 'NearParityControlled') 'BitLocker must be NearParityControlled after Phase 115 Yazan approval.'
Assert-BoostLabCondition ([string]$bitLockerRecord.UltimateParity -eq 'Partial') 'BitLocker accepted near parity must remain Partial by current convention.'
Assert-BoostLabCondition (-not [bool]$bitLockerRecord.YazanFinalException) 'BitLocker must not use a Yazan final exception.'
Assert-BoostLabCondition ([bool]$bitLockerRecord.YazanAcceptedNearParity) 'BitLocker must be marked accepted near-parity.'
Assert-BoostLabCondition ([string]$bitLockerRecord.FinalProgressStatus -eq 'DoneYazanAcceptedNearParity') 'BitLocker final progress status mismatch.'
Assert-BoostLabTextContains -Text ([string]$bitLockerRecord.GapSummary) -Needle 'source-equivalent BitLocker Off and On/status behavior' -Description 'BitLocker parity gap summary'
Assert-BoostLabTextContains -Text ([string]$bitLockerRecord.NextParityAction) -Needle 'Skip; accepted near-parity.' -Description 'BitLocker next parity action'
Assert-BoostLabCondition (Test-BoostLabParityRecordFinal -Record $bitLockerRecord) 'BitLocker accepted near-parity record must be treated as final.'

$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ($null -ne $nextTarget) 'Next ordered parity target was not found.'
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq 'msi-mode') 'Next ordered parity target must advance past P0 State near-parity acceptance.'

$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
Assert-BoostLabCondition ([int]$categoryCounts['ParityImplemented'] -eq 16) 'Ultimate parity implemented count changed unexpectedly.'
Assert-BoostLabCondition ([int]$categoryCounts['NearParityControlled'] -eq 23) 'NearParityControlled count mismatch.'
Assert-BoostLabCondition ([int]$categoryCounts['SecurityAssistantOnly'] -eq 0) 'SecurityAssistantOnly count must be zero after BitLocker upgrade.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.UltimateParityImplemented -eq 16) 'Ultimate parity implemented count changed.'

$bitLockerTool = @($allTools | Where-Object { $_.Id -eq 'bitlocker' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $bitLockerTool) 'BitLocker tool metadata was not found.'
Assert-BoostLabCondition ([string]$bitLockerTool.Stage -eq 'Setup') 'BitLocker must remain a Setup tool.'
Assert-BoostLabCondition ([int]$bitLockerTool.Order -eq 1) 'BitLocker UI/catalog order must follow the canonical Setup order.'
Assert-BoostLabCondition ((@($bitLockerTool.Actions) -join ',') -eq 'Analyze,Apply,Default,Restore,Open') 'BitLocker must expose canonical actions only.'
$capabilities = $bitLockerTool.Capabilities
Assert-BoostLabCondition ([bool]$capabilities.RequiresAdmin) 'BitLocker must preserve Administrator requirement.'
Assert-BoostLabCondition ([bool]$capabilities.CanModifySecurity) 'BitLocker must preserve security-sensitive metadata.'
Assert-BoostLabCondition ([bool]$capabilities.NeedsExplicitConfirmation) 'BitLocker must preserve explicit confirmation metadata.'
Assert-BoostLabCondition (-not [bool]$capabilities.SupportsDefault) 'BitLocker must not claim Default support.'
Assert-BoostLabCondition (-not [bool]$capabilities.SupportsRestore) 'BitLocker must not claim Restore support.'

$moduleText = Get-Content -Raw -LiteralPath $modulePath
foreach ($needle in @(
    'SourceEquivalentControlled',
    'SourceEquivalentOffAvailable',
    'SourceEquivalentOnStatusAvailable',
    'Disable-BitLocker -MountPoint $MountPoint -ErrorAction SilentlyContinue',
    'Start-Process -FilePath ''control.exe'' -ArgumentList ''/name microsoft.bitlockerdriveencryption''',
    'manage-bde -status',
    'DefaultUnavailable',
    'RestoreUnavailable'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'BitLocker source-equivalent controlled module'
}
Assert-BoostLabCondition (-not $moduleText.Contains('NeedsRecoveryKeyPolicy')) 'BitLocker must not keep the old NeedsRecoveryKeyPolicy Apply blocker.'

$tokens = $null
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($modulePath, [ref]$tokens, [ref]$parseErrors)
Assert-BoostLabCondition (@($parseErrors).Count -eq 0) "BitLocker module parse errors: $(@($parseErrors | ForEach-Object { $_.Message }) -join '; ')"
$commands = @(
    $ast.FindAll(
        { param($node) $node -is [Management.Automation.Language.CommandAst] },
        $true
    ) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }
)
foreach ($forbiddenCommand in @(
    'Enable-BitLocker',
    'Suspend-BitLocker',
    'Resume-BitLocker',
    'Unlock-BitLocker',
    'Remove-BitLockerKeyProtector',
    'Add-BitLockerKeyProtector',
    'Set-ItemProperty',
    'New-ItemProperty',
    'Remove-ItemProperty',
    'Restart-Computer',
    'bcdedit'
)) {
    Assert-BoostLabCondition ($forbiddenCommand -notin $commands) "BitLocker module must not execute unrelated command: $forbiddenCommand"
}

$moduleInfo = Import-Module -Name $modulePath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    $mockVolumeReader = {
        @(
            [pscustomobject]@{
                MountPoint           = 'C:'
                VolumeStatus         = 'FullyEncrypted'
                ProtectionStatus     = 'On'
                EncryptionPercentage = 100
                LockStatus           = 'Unlocked'
                KeyProtector         = @(
                    [pscustomobject]@{
                        KeyProtectorType = 'Tpm'
                        KeyProtectorId = '{TPM-SECRET-ID}'
                    }
                    [pscustomobject]@{
                        KeyProtectorType = 'RecoveryPassword'
                        RecoveryPassword = '000000-111111-222222-333333-444444-555555-666666-777777'
                    }
                )
            }
            [pscustomobject]@{
                MountPoint           = 'D:'
                VolumeStatus         = 'FullyDecrypted'
                ProtectionStatus     = 'Off'
                EncryptionPercentage = 0
                LockStatus           = 'Unlocked'
                KeyProtector         = @()
            }
        )
    }

    $disableCalls = [System.Collections.Generic.List[string]]::new()
    $controlCalls = [System.Collections.Generic.List[string]]::new()
    $manageBdeCalls = [System.Collections.Generic.List[string]]::new()
    $disableExecutor = {
        param([string]$MountPoint)
        $disableCalls.Add($MountPoint)
        [pscustomobject]@{ Success = $true; CommandStatus = 'Completed'; Message = "Mock disabled $MountPoint." }
    }.GetNewClosure()
    $controlPanelLauncher = {
        param([string]$FilePath, [string]$ArgumentList)
        $controlCalls.Add("$FilePath $ArgumentList")
        [pscustomobject]@{ Success = $true; CommandStatus = 'Completed'; Message = 'Mock Control Panel launch.' }
    }.GetNewClosure()
    $manageBdeStatusExecutor = {
        param([string[]]$ArgumentList)
        $manageBdeCalls.Add(($ArgumentList -join ' '))
        [pscustomobject]@{ Success = $true; CommandStatus = 'Completed'; ExitCode = 0; Message = 'Mock manage-bde status.' }
    }.GetNewClosure()

    $analyze = & $moduleInfo {
        param($Reader)
        Invoke-BoostLabToolAction -ActionName Analyze -VolumeReader $Reader
    } $mockVolumeReader
    Assert-BoostLabCondition ([bool]$analyze.Success) 'BitLocker Analyze must remain available.'
    Assert-BoostLabCondition ([string]$analyze.CommandStatus -eq 'No execution performed') 'BitLocker Analyze must not execute commands.'
    Assert-BoostLabCondition (-not [bool]$analyze.ChangesExecuted) 'BitLocker Analyze must not mutate state.'
    Assert-BoostLabCondition ([string]$analyze.Data.Mode -eq 'SourceEquivalentControlled') 'BitLocker Analyze must report source-equivalent controlled mode.'
    Assert-BoostLabCondition ([bool]$analyze.Data.ApplyAvailable) 'BitLocker Apply must be available after Yazan approval.'
    Assert-BoostLabCondition ([int]$analyze.Data.VolumeDiscovery.SourceOffMatchedVolumeCount -eq 1) 'BitLocker Analyze must report source Off matched volumes read-only.'
    $analyzeJson = $analyze | ConvertTo-Json -Depth 12
    Assert-BoostLabCondition (-not $analyzeJson.Contains('000000-111111-222222-333333-444444-555555-666666-777777')) 'BitLocker Analyze must not expose recovery password values.'
    Assert-BoostLabCondition (-not $analyzeJson.Contains('{TPM-SECRET-ID}')) 'BitLocker Analyze must not expose key protector ids.'

    $open = & $moduleInfo {
        param($Reader, $ControlLauncher, $StatusExecutor)
        Invoke-BoostLabToolAction -ActionName Open -Confirmed:$true -VolumeReader $Reader -ControlPanelLauncher $ControlLauncher -ManageBdeStatusExecutor $StatusExecutor
    } $mockVolumeReader $controlPanelLauncher $manageBdeStatusExecutor
    Assert-BoostLabCondition ([bool]$open.Success) 'BitLocker Open should route source On/status behavior through mocks.'
    Assert-BoostLabCondition ([string]$open.Status -eq 'StatusOpened') 'BitLocker Open status mismatch.'
    Assert-BoostLabCondition ([string]$open.CommandStatus -eq 'Completed') 'BitLocker Open command status mismatch.'
    Assert-BoostLabCondition (-not [bool]$open.ChangesExecuted) 'BitLocker Open must not mutate BitLocker state.'
    Assert-BoostLabCondition (-not [bool]$open.Data.AutomaticEnableBitLocker) 'BitLocker Open must not enable BitLocker automatically.'

    $apply = & $moduleInfo {
        param($Reader, $DisableExecutor, $ControlLauncher, $StatusExecutor)
        Invoke-BoostLabToolAction -ActionName Apply -Confirmed:$true -VolumeReader $Reader -DisableBitLockerExecutor $DisableExecutor -ControlPanelLauncher $ControlLauncher -ManageBdeStatusExecutor $StatusExecutor
    } $mockVolumeReader $disableExecutor $controlPanelLauncher $manageBdeStatusExecutor
    Assert-BoostLabCondition ([bool]$apply.Success) 'BitLocker Apply should route source Off behavior through mocks.'
    Assert-BoostLabCondition ([string]$apply.Status -eq 'Completed') 'BitLocker Apply status mismatch.'
    Assert-BoostLabCondition ([bool]$apply.ChangesExecuted) 'BitLocker Apply must report source Off mutation request when targets exist.'
    Assert-BoostLabCondition (($disableCalls -join '|') -eq 'C:') 'BitLocker Apply must call Disable-BitLocker only for source-matched MountPoints.'
    Assert-BoostLabCondition ($controlCalls.Count -eq 2) 'BitLocker Open plus Apply must request two mocked Control Panel launches.'
    Assert-BoostLabCondition ($manageBdeCalls.Count -eq 2) 'BitLocker Open plus Apply must request two mocked manage-bde status calls.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.RecoveryKeysCollectedDisplayedOrPersisted) 'BitLocker Apply must not collect or expose recovery keys.'

    $default = & $moduleInfo {
        param($Reader)
        Invoke-BoostLabToolAction -ActionName Default -Confirmed:$true -VolumeReader $Reader
    } $mockVolumeReader
    Assert-BoostLabCondition (-not [bool]$default.Success) 'BitLocker Default must remain unavailable.'
    Assert-BoostLabCondition ([string]$default.Status -eq 'DefaultUnavailable') 'BitLocker Default status mismatch.'
    Assert-BoostLabCondition (-not [bool]$default.ChangesExecuted) 'BitLocker Default must execute no changes.'

    $restore = & $moduleInfo {
        param($Reader)
        Invoke-BoostLabToolAction -ActionName Restore -Confirmed:$true -VolumeReader $Reader
    } $mockVolumeReader
    Assert-BoostLabCondition (-not [bool]$restore.Success) 'BitLocker Restore must remain unavailable.'
    Assert-BoostLabCondition ([string]$restore.Status -eq 'RestoreUnavailable') 'BitLocker Restore status mismatch.'
    Assert-BoostLabCondition (-not [bool]$restore.ChangesExecuted) 'BitLocker Restore must execute no changes.'
}
finally {
    Remove-Module -ModuleInfo $moduleInfo -Force -ErrorAction SilentlyContinue
}

$migrationText = Get-Content -Raw -LiteralPath $migrationPath
foreach ($needle in @(
    'BitLocker: Off (Recommended)',
    'Disable-BitLocker -MountPoint <mount> -ErrorAction SilentlyContinue',
    'Start-Process control.exe -ArgumentList "/name microsoft.bitlockerdriveencryption"',
    'manage-bde -status',
    'Phase 115 Yazan-approved source-equivalent BitLocker Off and On/status behavior'
)) {
    Assert-BoostLabTextContains -Text $migrationText -Needle $needle -Description 'BitLocker migration record'
}

$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPath
$productionPolicy = Import-PowerShellDataFile -LiteralPath $productionAllowlistPath
if ($artifactPolicy.ContainsKey('Artifacts')) {
    Assert-BoostLabCondition (@($artifactPolicy.Artifacts).Count -eq 0) 'Artifact provenance approvals must remain empty.'
}
if ($productionPolicy.ContainsKey('ProductionAllowlistProposals')) {
    Assert-BoostLabCondition (@($productionPolicy.ProductionAllowlistProposals).Count -eq 0) 'Production allowlist proposals must remain empty.'
}
Assert-BoostLabCondition (-not [bool]$parityBaseline.DesignSystemReady) 'Design System readiness must remain false.'

Assert-BoostLabCondition ([int]$inventorySnapshot.ActiveTools -eq 55) 'Active tool count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.ImplementedTools -eq 45) 'Runtime implemented tool count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.DeferredPlaceholders -eq 10) 'Deferred placeholder count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.SourcePromotedMirrorFiles -eq 7) 'Source-promoted mirror count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.RemainingSourcePromotedIntakeCandidates -eq 0) 'Remaining source-promoted intake count changed.'

foreach ($deletedPath in @(
    'source-ultimate\6 Windows\17 Loudness EQ.ps1',
    'source-ultimate\6 Windows\30 NVME Faster Driver.ps1'
)) {
    Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $deletedPath))) "Deleted source was reintroduced: $deletedPath"
}

[pscustomobject]@{
    Test = 'BitLockerOrderedParityDecision'
    SourcePath = 'source-ultimate/_intake-promoted/Ultimate/3 Setup/1 BitLocker.ps1'
    SourceHash = $actualSourceHash
    RuntimeBehaviorChanged = $true
    NextOrderedTarget = $nextTarget.ToolId
    ImplementationLevel = $bitLockerRecord.ImplementationLevel
    FinalProgressStatus = $bitLockerRecord.FinalProgressStatus
    YazanAcceptedNearParity = [bool]$bitLockerRecord.YazanAcceptedNearParity
    YazanFinalException = [bool]$bitLockerRecord.YazanFinalException
    ManageBdeExecutedByTest = $false
    ControlPanelLaunchedByTest = $false
    BitLockerMutationExecutedByTest = $false
    SourceUltimateUnchanged = $true
    Message = 'BitLocker is accepted near-parity after Phase 115 Yazan approval; validators use mocks for source-equivalent command routing.'
}
