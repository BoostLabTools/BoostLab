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
$inventoryBaseline = $inventoryAssertion.Baseline
$inventorySnapshot = $inventoryAssertion.Snapshot
$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$orderPath = Join-Path $ProjectRoot 'config\UltimateParityExecutionOrder.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Setup\bitlocker.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate\3 Setup\1 BitLocker.ps1'
$intakePath = Join-Path $ProjectRoot 'intake\missing-ultimate-scripts\Ultimate\3 Setup\1 BitLocker.ps1'
$migrationPath = Join-Path $ProjectRoot 'docs\migrations\bitlocker.md'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'

foreach ($path in @($configPath, $orderPath, $modulePath, $sourcePath, $intakePath, $migrationPath, $actionPlanPath, $artifactPath, $productionAllowlistPath)) {
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
Assert-BoostLabCondition ([string]$executionOrder.Rule -match 'Setup starts with BitLocker') 'Execution order rule must document the Phase 114 Setup correction.'
Assert-BoostLabCondition ([string]@($setupOrder.Tools)[0].ToolId -eq 'bitlocker') 'BitLocker must be first in Setup ordered parity execution.'
Assert-BoostLabCondition (@($setupOrder.Tools | Where-Object { [string]$_.ToolId -eq 'edge-settings' }).Count -eq 1) 'Edge Settings must remain in Setup order but not ahead of BitLocker.'

$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ($null -ne $nextTarget) 'Next ordered parity target was not found.'
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq 'bitlocker') 'Current ordered parity target must be BitLocker, not Edge Settings.'

$bitLockerRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'bitlocker' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $bitLockerRecord) 'BitLocker parity record was not found.'
Assert-BoostLabCondition ([string]$bitLockerRecord.RuntimeStatus -eq 'RuntimeImplemented') 'BitLocker runtime status mismatch.'
Assert-BoostLabCondition ([string]$bitLockerRecord.ImplementationLevel -eq 'SecurityAssistantOnly') 'BitLocker must remain SecurityAssistantOnly until Yazan approves final mutation policy.'
Assert-BoostLabCondition ([string]$bitLockerRecord.UltimateParity -eq 'No') 'BitLocker must not be marked as Ultimate parity.'
Assert-BoostLabCondition (-not [bool]$bitLockerRecord.YazanFinalException) 'BitLocker must not use a Yazan final exception.'
Assert-BoostLabCondition (-not [bool]$bitLockerRecord.YazanAcceptedNearParity) 'BitLocker must not be marked accepted near-parity.'
Assert-BoostLabCondition ([string]$bitLockerRecord.FinalProgressStatus -eq 'DeferredNeedsYazanDecision') 'BitLocker must be deferred for a Yazan decision.'
Assert-BoostLabTextContains -Text ([string]$bitLockerRecord.GapSummary) -Needle 'recovery-key' -Description 'BitLocker parity gap summary'
Assert-BoostLabTextContains -Text ([string]$bitLockerRecord.GapSummary) -Needle 'decryption' -Description 'BitLocker parity gap summary'
Assert-BoostLabTextContains -Text ([string]$bitLockerRecord.NextParityAction) -Needle 'Ask Yazan' -Description 'BitLocker next parity action'
Assert-BoostLabCondition (-not (Test-BoostLabParityRecordFinal -Record $bitLockerRecord)) 'BitLocker must not be treated as final without Yazan decision.'

$bitLockerTool = @($allTools | Where-Object { $_.Id -eq 'bitlocker' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $bitLockerTool) 'BitLocker tool metadata was not found.'
Assert-BoostLabCondition ([string]$bitLockerTool.Stage -eq 'Setup') 'BitLocker must remain a Setup tool.'
Assert-BoostLabCondition ([int]$bitLockerTool.Order -eq 9) 'BitLocker UI/catalog order must remain unchanged by the parity correction.'
Assert-BoostLabCondition ((@($bitLockerTool.Actions) -join ',') -eq 'Analyze,Apply,Default,Restore,Open') 'BitLocker must expose canonical actions only.'
$capabilities = $bitLockerTool.Capabilities
Assert-BoostLabCondition ([bool]$capabilities.RequiresAdmin) 'BitLocker must preserve Administrator requirement.'
Assert-BoostLabCondition ([bool]$capabilities.CanModifySecurity) 'BitLocker must preserve security-sensitive metadata.'
Assert-BoostLabCondition ([bool]$capabilities.NeedsExplicitConfirmation) 'BitLocker must preserve explicit confirmation metadata.'
Assert-BoostLabCondition (-not [bool]$capabilities.SupportsDefault) 'BitLocker must not claim Default support.'
Assert-BoostLabCondition (-not [bool]$capabilities.SupportsRestore) 'BitLocker must not claim Restore support.'

$moduleText = Get-Content -Raw -LiteralPath $modulePath
foreach ($needle in @(
    'ManualHandoffOnly',
    'NeedsRecoveryKeyPolicy',
    'DefaultUnavailable',
    'RestoreUnavailable',
    'NoSilentEnableDisableDecryptSuspendOrProtectorMutation',
    'No external tool is opened by BoostLab.',
    'No BitLocker state mutation is executed by BoostLab.'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'BitLocker controlled assistant module'
}

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
    'Disable-BitLocker',
    'Enable-BitLocker',
    'Suspend-BitLocker',
    'Resume-BitLocker',
    'Unlock-BitLocker',
    'Remove-BitLockerKeyProtector',
    'Add-BitLockerKeyProtector',
    'manage-bde',
    'control.exe',
    'Start-Process',
    'Set-ItemProperty',
    'New-ItemProperty',
    'Remove-ItemProperty',
    'Restart-Computer',
    'bcdedit'
)) {
    Assert-BoostLabCondition ($forbiddenCommand -notin $commands) "BitLocker module must not execute command: $forbiddenCommand"
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
        )
    }

    $analyze = & $moduleInfo {
        param($Reader)
        Invoke-BoostLabToolAction -ActionName Analyze -VolumeReader $Reader
    } $mockVolumeReader
    Assert-BoostLabCondition ([bool]$analyze.Success) 'BitLocker Analyze must remain available.'
    Assert-BoostLabCondition ([string]$analyze.CommandStatus -eq 'No execution performed') 'BitLocker Analyze must not execute commands.'
    Assert-BoostLabCondition (-not [bool]$analyze.ChangesExecuted) 'BitLocker Analyze must not mutate state.'
    Assert-BoostLabCondition ([string]$analyze.Data.Mode -eq 'ManualHandoffOnly') 'BitLocker Analyze must remain manual-handoff/security-assistant only.'
    Assert-BoostLabCondition (-not [bool]$analyze.Data.ApplyAvailable) 'BitLocker Apply must not be available.'
    Assert-BoostLabCondition ([int]$analyze.Data.VolumeDiscovery.SourceOffMatchedVolumeCount -eq 1) 'BitLocker Analyze must report source Off matched volumes read-only.'
    Assert-BoostLabCondition ([bool]@($analyze.Data.VolumeDiscovery.Volumes)[0].HasRecoveryPasswordProtector) 'BitLocker Analyze may report recovery protector presence.'
    $analyzeJson = $analyze | ConvertTo-Json -Depth 12
    Assert-BoostLabCondition (-not $analyzeJson.Contains('000000-111111-222222-333333-444444-555555-666666-777777')) 'BitLocker Analyze must not expose recovery password values.'
    Assert-BoostLabCondition (-not $analyzeJson.Contains('{TPM-SECRET-ID}')) 'BitLocker Analyze must not expose key protector ids.'

    $open = & $moduleInfo {
        param($Reader)
        Invoke-BoostLabToolAction -ActionName Open -Confirmed:$true -VolumeReader $Reader
    } $mockVolumeReader
    Assert-BoostLabCondition ([bool]$open.Success) 'BitLocker Open should prepare manual handoff.'
    Assert-BoostLabCondition ([string]$open.Status -eq 'ManualHandoffPrepared') 'BitLocker Open status mismatch.'
    Assert-BoostLabCondition ([string]$open.CommandStatus -eq 'No execution performed') 'BitLocker Open must not execute commands.'
    Assert-BoostLabCondition ([bool]$open.Data.NoExternalToolOpened) 'BitLocker Open must not open Control Panel or external UI.'
    Assert-BoostLabCondition ([bool]$open.Data.NoBitLockerMutation) 'BitLocker Open must not mutate BitLocker state.'

    $apply = & $moduleInfo {
        param($Reader)
        Invoke-BoostLabToolAction -ActionName Apply -Confirmed:$true -VolumeReader $Reader
    } $mockVolumeReader
    Assert-BoostLabCondition (-not [bool]$apply.Success) 'BitLocker Apply must remain blocked.'
    Assert-BoostLabCondition ([string]$apply.Status -eq 'NeedsRecoveryKeyPolicy') 'BitLocker Apply blocker status mismatch.'
    Assert-BoostLabCondition (-not [bool]$apply.ChangesExecuted) 'BitLocker Apply must execute no changes.'

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
    'Approved for controlled security assistant intake only'
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

$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
        Where-Object {
            $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*')
        } |
        Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
        ForEach-Object {
            $relativePath = $_.FullName.Substring($root.Length + 1).Replace('\', '/')
            $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
            "$relativePath|$hash"
        }
)
$sha = [Security.Cryptography.SHA256]::Create()
try {
    $sourceManifestHash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n"))))).Replace('-', '')
}
finally {
    $sha.Dispose()
}
Assert-BoostLabCondition (@($sourceLines).Count -eq 49) 'Legacy source file count changed.'
Assert-BoostLabCondition ($sourceManifestHash -eq '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') 'Legacy source manifest changed.'

Assert-BoostLabCondition ([int]$inventorySnapshot.ActiveTools -eq 55) 'Active tool count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.ImplementedTools -eq 44) 'Runtime implemented tool count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.DeferredPlaceholders -eq 11) 'Deferred placeholder count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.SourcePromotedMirrorFiles -eq 7) 'Source-promoted mirror count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.RemainingSourcePromotedIntakeCandidates -eq 0) 'Remaining source-promoted intake count changed.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.UltimateParityImplemented -eq 16) 'Ultimate parity implemented count changed.'

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
    RuntimeBehaviorChanged = $false
    OrderedTarget = $nextTarget.ToolId
    ImplementationLevel = $bitLockerRecord.ImplementationLevel
    FinalProgressStatus = $bitLockerRecord.FinalProgressStatus
    YazanAcceptedNearParity = [bool]$bitLockerRecord.YazanAcceptedNearParity
    YazanFinalException = [bool]$bitLockerRecord.YazanFinalException
    ManageBdeExecuted = $false
    ControlPanelLaunched = $false
    BitLockerMutationExecuted = $false
    SourceUltimateUnchanged = $true
    Message = 'BitLocker remains the ordered target and requires a Yazan security policy decision before parity can advance.'
}
