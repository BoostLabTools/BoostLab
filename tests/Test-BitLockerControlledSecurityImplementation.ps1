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
        throw 'Unable to determine the BitLocker validator path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')

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

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Setup\bitlocker.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate\3 Setup\1 BitLocker.ps1'
$intakePath = Join-Path $ProjectRoot 'intake\missing-ultimate-scripts\Ultimate\3 Setup\1 BitLocker.ps1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$migrationRecordPath = Join-Path $ProjectRoot 'docs\migrations\bitlocker.md'

foreach ($path in @(
    $configPath,
    $modulePath,
    $sourcePath,
    $intakePath,
    $executionPath,
    $actionPlanPath,
    $artifactPath,
    $productionAllowlistPath,
    $migrationRecordPath
)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required BitLocker file is missing: $path"
}

$expectedSourceHash = '1678E97FB5AFF851F1491A2D96C82A5716B1FA07CB4E3A4A5E0F3FB1B086FBA1'
Assert-BoostLabCondition ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -eq $expectedSourceHash) 'BitLocker source mirror hash changed.'
Assert-BoostLabCondition ((Get-FileHash -Algorithm SHA256 -LiteralPath $intakePath).Hash -eq $expectedSourceHash) 'BitLocker intake source hash changed.'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($configuration.Stages | ForEach-Object { $_.Tools })
$setupTools = @($configuration.Stages | Where-Object { $_.Name -eq 'Setup' } | ForEach-Object { $_.Tools })
$bitLockerTool = $allTools | Where-Object { $_.Id -eq 'bitlocker' } | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $bitLockerTool) 'BitLocker must be active in config.'
Assert-BoostLabCondition ([string]$bitLockerTool.Stage -eq 'Setup') 'BitLocker must be a Setup tool, not a Graphics Path B tool.'
Assert-BoostLabCondition ([int]$bitLockerTool.Order -eq 1) 'BitLocker must use the canonical Setup order.'
Assert-BoostLabCondition ([string]$bitLockerTool.Type -eq 'assistant') 'BitLocker must remain an assistant.'
Assert-BoostLabCondition ([string]$bitLockerTool.RiskLevel -eq 'high') 'BitLocker must remain high risk.'
Assert-BoostLabCondition ((@($bitLockerTool.Actions) -join '|') -eq 'Analyze|Apply|Default|Restore|Open') 'BitLocker must expose only canonical Analyze, Apply, Default, Restore, and Open actions.'
Assert-BoostLabCondition (@($setupTools | Where-Object { $_.Id -eq 'bitlocker' }).Count -eq 1) 'BitLocker must appear exactly once in Setup.'
Assert-BoostLabCondition (@($allTools | Where-Object { $_.Stage -eq 'Graphics' -and $_.Id -eq 'bitlocker' }).Count -eq 0) 'BitLocker must not be merged into NVIDIA Path B.'

$caps = $bitLockerTool.Capabilities
Assert-BoostLabCondition ([bool]$caps.RequiresAdmin) 'BitLocker must preserve Administrator capability.'
Assert-BoostLabCondition ([bool]$caps.CanModifySecurity) 'BitLocker must declare security-sensitive capability.'
Assert-BoostLabCondition ([bool]$caps.NeedsExplicitConfirmation) 'BitLocker must require explicit confirmation.'
Assert-BoostLabCondition (-not [bool]$caps.SupportsDefault) 'BitLocker must not claim supported Default mutation.'
Assert-BoostLabCondition (-not [bool]$caps.SupportsRestore) 'BitLocker must not claim captured-state Restore support.'
foreach ($falseCapability in @(
    'RequiresInternet',
    'CanReboot',
    'CanModifyRegistry',
    'CanModifyServices',
    'CanInstallSoftware',
    'CanDownload',
    'CanModifyDrivers',
    'CanDeleteFiles',
    'UsesTrustedInstaller',
    'UsesSafeMode'
)) {
    Assert-BoostLabCondition (-not [bool]$caps[$falseCapability]) "BitLocker capability should be false: $falseCapability"
}

Assert-BoostLabCondition ([int]$inventorySnapshot.ActiveTools -eq [int]$inventoryBaseline.ActiveTools) 'Active tool count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.ImplementedTools -eq [int]$inventoryBaseline.ImplementedTools) 'Runtime implemented tool count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.DeferredPlaceholders -eq [int]$inventoryBaseline.DeferredPlaceholders) 'Deferred placeholder count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.SourcePromotedMirrorFiles -eq [int]$inventoryBaseline.SourcePromotedMirrorFiles) 'Source-promoted mirror count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.RemainingSourcePromotedIntakeCandidates -eq [int]$inventoryBaseline.RemainingSourcePromotedIntakeCandidates) 'Remaining source-promoted intake count changed.'
Assert-BoostLabCondition (@($allTools | Where-Object { $_.Id -eq 'ddu' -or $_.Title -eq 'DDU' }).Count -eq 0) 'Standalone DDU must not be introduced.'
Assert-BoostLabCondition (@($allTools | Where-Object { $_.Title -eq 'Loudness EQ' -or $_.Id -eq 'loudness-eq' }).Count -eq 0) 'Loudness EQ must remain deleted.'
Assert-BoostLabCondition (@($allTools | Where-Object { $_.Title -eq 'NVME Faster Driver' -or $_.Id -eq 'nvme-faster-driver' }).Count -eq 0) 'NVME Faster Driver must remain deleted.'

$executionText = Get-Content -LiteralPath $executionPath -Raw
foreach ($needle in @(
    "'bitlocker'",
    "Setup\bitlocker.psm1",
    "'Analyze', 'Apply', 'Default', 'Restore', 'Open'"
)) {
    Assert-BoostLabTextContains -Text $executionText -Needle $needle -Description 'BitLocker execution registration'
}

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
Assert-BoostLabTextContains -Text $actionPlanText -Needle "[ValidateSet('Apply', 'Default', 'Open', 'Analyze', 'Restore')]" -Description 'Action Plan canonical ValidateSet'
Assert-BoostLabCondition (-not $actionPlanText.Contains("'Manual Handoff', 'Apply Auto'")) 'Action Plan ValidateSet must not be widened for BitLocker.'
foreach ($needle in @(
    'Run the source-equivalent BitLocker On/status branch',
    'Open BitLocker Drive Encryption Control Panel with control.exe /name microsoft.bitlockerdriveencryption.',
    'Run manage-bde -status for source-equivalent status output.',
    'Run the source-equivalent BitLocker Off branch',
    'Query Get-BitLockerVolume and filter volumes where ProtectionStatus is On or VolumeStatus is not FullyDecrypted.',
    'Run Disable-BitLocker -MountPoint <mount> -ErrorAction SilentlyContinue only for the filtered target MountPoints.',
    'Block Default before any operational step.',
    'Block Restore before any operational step.'
)) {
    Assert-BoostLabTextContains -Text $actionPlanText -Needle $needle -Description 'BitLocker action plan'
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
$bitLockerModule = Import-Module -Name $modulePath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    foreach ($blockedAction in @('Default', 'Restore')) {
        $plan = New-BoostLabActionPlan -ToolMetadata $bitLockerTool -ActionName $blockedAction
        $planText = @(@($plan.PlannedChanges), @($plan.SideEffects), $plan.ConfirmationMessage) -join ' '
        Assert-BoostLabCondition (-not $planText.Contains('Modify approved Windows security configuration.')) "BitLocker $blockedAction plan must not claim planned security mutation."
    }

    $moduleText = Get-Content -LiteralPath $modulePath -Raw
    foreach ($needle in @(
        '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'', ''Restore'', ''Open'')',
        $expectedSourceHash,
        'Get-BitLockerVolume',
        'Disable-BitLocker -MountPoint $MountPoint -ErrorAction SilentlyContinue',
        'Start-Process -FilePath ''control.exe'' -ArgumentList ''/name microsoft.bitlockerdriveencryption''',
        'manage-bde -status',
        'SourceEquivalentControlled',
        'SourceEquivalentOffAvailable',
        'SourceEquivalentOnStatusAvailable',
        'DefaultUnavailable',
        'RestoreUnavailable',
        'BitLocker remains separate from Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode.'
    )) {
        Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'BitLocker module'
    }
    Assert-BoostLabCondition (-not $moduleText.Contains('NeedsRecoveryKeyPolicy')) 'BitLocker Apply must no longer be blocked on recovery-key policy.'

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($modulePath, [ref]$tokens, [ref]$parseErrors)
    $actualParseErrors = @($parseErrors | Where-Object { $null -ne $_ })
    Assert-BoostLabCondition ($actualParseErrors.Count -eq 0) "BitLocker module parse errors: $(@($actualParseErrors | ForEach-Object { $_.Message }) -join '; ')"
    $commands = @(
        $ast.FindAll(
            { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
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

    $artifactText = Get-Content -LiteralPath $artifactPath -Raw
    $allowlistText = Get-Content -LiteralPath $productionAllowlistPath -Raw
    Assert-BoostLabCondition (-not $artifactText.Contains('bitlocker')) 'BitLocker must not add artifact provenance approvals.'
    Assert-BoostLabCondition (-not $allowlistText.Contains('bitlocker')) 'BitLocker must not add production allowlist approvals.'

    $mockVolumeReader = {
        @(
            [pscustomobject]@{
                MountPoint           = 'C:'
                VolumeStatus         = 'FullyEncrypted'
                ProtectionStatus     = 'On'
                EncryptionPercentage = 100
                LockStatus           = 'Unlocked'
                KeyProtector         = @(
                    [pscustomobject]@{ KeyProtectorType = 'Tpm'; KeyProtectorId = '{TPM-SECRET-ID}' }
                    [pscustomobject]@{ KeyProtectorType = 'RecoveryPassword'; RecoveryPassword = '000000-111111-222222-333333-444444-555555-666666-777777' }
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
            [pscustomobject]@{
                MountPoint           = 'E:'
                VolumeStatus         = 'EncryptionInProgress'
                ProtectionStatus     = 'Off'
                EncryptionPercentage = 20
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
        [pscustomobject]@{
            Success = $true
            CommandStatus = 'Completed'
            Message = "Mock Disable-BitLocker for $MountPoint."
        }
    }.GetNewClosure()
    $controlPanelLauncher = {
        param([string]$FilePath, [string]$ArgumentList)
        $controlCalls.Add("$FilePath $ArgumentList")
        [pscustomobject]@{
            Success = $true
            CommandStatus = 'Completed'
            Message = 'Mock Control Panel launch.'
        }
    }.GetNewClosure()
    $manageBdeStatusExecutor = {
        param([string[]]$ArgumentList)
        $manageBdeCalls.Add(($ArgumentList -join ' '))
        [pscustomobject]@{
            Success = $true
            CommandStatus = 'Completed'
            ExitCode = 0
            Message = 'Mock manage-bde status.'
            OutputLineCount = 0
        }
    }.GetNewClosure()

    $analyzeResult = Invoke-BoostLabToolAction -ActionName 'Analyze' -VolumeReader $mockVolumeReader
    Assert-BoostLabCondition ([bool]$analyzeResult.Success) 'BitLocker Analyze should succeed with mocked read-only volume data.'
    Assert-BoostLabCondition ([string]$analyzeResult.Status -eq 'Analyzed') 'BitLocker Analyze status must be Analyzed.'
    Assert-BoostLabCondition ([string]$analyzeResult.CommandStatus -eq 'No execution performed') 'BitLocker Analyze must not execute a command.'
    Assert-BoostLabCondition (-not [bool]$analyzeResult.ChangesExecuted) 'BitLocker Analyze must not execute changes.'
    Assert-BoostLabCondition ([string]$analyzeResult.Data.Mode -eq 'SourceEquivalentControlled') 'BitLocker Analyze mode mismatch.'
    Assert-BoostLabCondition ([bool]$analyzeResult.Data.ApplyAvailable) 'BitLocker Apply must be available after Phase 115 Yazan approval.'
    Assert-BoostLabCondition ([bool]$analyzeResult.Data.OpenAvailable) 'BitLocker Open/status must be available.'
    Assert-BoostLabCondition ([int]$analyzeResult.Data.VolumeDiscovery.SourceOffMatchedVolumeCount -eq 2) 'BitLocker Analyze must report source Off matched volume count.'
    Assert-BoostLabCondition ((@($analyzeResult.Data.SourceOffTargetMountPoints) -join '|') -eq 'C:|E:') 'BitLocker Analyze must expose exact source Off target MountPoints.'
    Assert-BoostLabCondition (@($analyzeResult.Warnings).Count -eq 0) 'BitLocker Analyze top-level warnings must not duplicate structured warning details.'
    $structuredAnalyzeWarnings = @($analyzeResult.Data.Warnings)
    Assert-BoostLabCondition ($structuredAnalyzeWarnings.Count -gt 0) 'BitLocker Analyze must keep warning details in structured data.'
    Assert-BoostLabCondition (($structuredAnalyzeWarnings | Select-Object -Unique).Count -eq $structuredAnalyzeWarnings.Count) 'BitLocker Analyze structured warnings must not be duplicated.'
    Assert-BoostLabCondition ((($analyzeResult | ConvertTo-Json -Depth 12) -notmatch '(?i)recoverypassword\\s*[0-9]{2,}|[0-9]{6}-[0-9]{6}-[0-9]{6}|TPM-SECRET-ID') ) 'BitLocker Analyze must not expose recovery key values or protector ids.'

    $openCancelled = Invoke-BoostLabToolAction -ActionName 'Open' -Confirmed:$false -VolumeReader $mockVolumeReader
    Assert-BoostLabCondition (-not [bool]$openCancelled.Success) 'BitLocker Open without confirmation must not succeed.'
    Assert-BoostLabCondition ([bool]$openCancelled.Cancelled) 'BitLocker Open without confirmation must be cancelled.'
    Assert-BoostLabCondition (-not [bool]$openCancelled.ChangesExecuted) 'Cancelled BitLocker Open must not execute changes.'

    $openResult = Invoke-BoostLabToolAction `
        -ActionName 'Open' `
        -Confirmed:$true `
        -VolumeReader $mockVolumeReader `
        -ControlPanelLauncher $controlPanelLauncher `
        -ManageBdeStatusExecutor $manageBdeStatusExecutor
    Assert-BoostLabCondition ([bool]$openResult.Success) 'BitLocker Open/status should succeed with mocked executors.'
    Assert-BoostLabCondition ([string]$openResult.Status -eq 'StatusOpened') 'BitLocker Open must report source-equivalent status branch.'
    Assert-BoostLabCondition ([string]$openResult.CommandStatus -eq 'Completed') 'BitLocker Open command status mismatch.'
    Assert-BoostLabCondition (-not [bool]$openResult.ChangesExecuted) 'BitLocker Open/status must not mutate BitLocker state.'
    Assert-BoostLabCondition (-not [bool]$openResult.Data.AutomaticEnableBitLocker) 'BitLocker Open must not enable BitLocker automatically.'
    Assert-BoostLabCondition (-not [bool]$openResult.Data.BitLockerStateMutation) 'BitLocker Open must not mutate BitLocker state.'
    Assert-BoostLabCondition ([bool]$openResult.Data.ExternalProcessRequested) 'BitLocker Open should request source-equivalent status UI/process.'
    Assert-BoostLabCondition ($controlCalls.Count -eq 1) 'BitLocker Open must route one mocked Control Panel launch.'
    Assert-BoostLabCondition ($manageBdeCalls.Count -eq 1) 'BitLocker Open must route one mocked manage-bde status request.'
    Assert-BoostLabCondition ($disableCalls.Count -eq 0) 'BitLocker Open must not call Disable-BitLocker.'

    $applyResult = Invoke-BoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -VolumeReader $mockVolumeReader `
        -DisableBitLockerExecutor $disableExecutor `
        -ControlPanelLauncher $controlPanelLauncher `
        -ManageBdeStatusExecutor $manageBdeStatusExecutor
    Assert-BoostLabCondition ([bool]$applyResult.Success) 'BitLocker Apply should route source-equivalent Off behavior through mocks.'
    Assert-BoostLabCondition ([string]$applyResult.Status -eq 'Completed') 'BitLocker Apply status mismatch.'
    Assert-BoostLabCondition ([string]$applyResult.CommandStatus -eq 'Completed') 'BitLocker Apply command status mismatch.'
    Assert-BoostLabCondition ([bool]$applyResult.ChangesExecuted) 'BitLocker Apply should report changes when source-matched targets exist.'
    Assert-BoostLabCondition ([int]$applyResult.Data.TargetVolumeCount -eq 2) 'BitLocker Apply target count mismatch.'
    Assert-BoostLabCondition ((@($applyResult.Data.TargetMountPoints) -join '|') -eq 'C:|E:') 'BitLocker Apply must target only source-matched MountPoints.'
    Assert-BoostLabCondition (($disableCalls -join '|') -eq 'C:|E:') 'BitLocker Apply must call Disable-BitLocker only for source-matched MountPoints.'
    Assert-BoostLabCondition ($controlCalls.Count -eq 2) 'BitLocker Apply must request the post-action Control Panel launch through the mock.'
    Assert-BoostLabCondition ($manageBdeCalls.Count -eq 2) 'BitLocker Apply must request the post-action manage-bde status through the mock.'
    Assert-BoostLabCondition (-not [bool]$applyResult.Data.AutomaticEnableBitLocker) 'BitLocker Apply must not enable BitLocker automatically.'
    Assert-BoostLabCondition (-not [bool]$applyResult.Data.RecoveryKeysCollectedDisplayedOrPersisted) 'BitLocker Apply must not collect or expose recovery keys.'
    Assert-BoostLabCondition ((($applyResult | ConvertTo-Json -Depth 12) -notmatch '(?i)000000-111111|TPM-SECRET-ID') ) 'BitLocker Apply result must not expose recovery secrets.'

    $defaultResult = Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed:$true -VolumeReader $mockVolumeReader
    Assert-BoostLabCondition (-not [bool]$defaultResult.Success) 'BitLocker Default must fail closed.'
    Assert-BoostLabCondition ([string]$defaultResult.Status -eq 'DefaultUnavailable') 'BitLocker Default must report unavailable default.'
    Assert-BoostLabCondition (-not [bool]$defaultResult.ChangesExecuted) 'BitLocker Default must not execute changes.'

    $restoreResult = Invoke-BoostLabToolAction -ActionName 'Restore' -Confirmed:$true -VolumeReader $mockVolumeReader
    Assert-BoostLabCondition (-not [bool]$restoreResult.Success) 'BitLocker Restore must fail closed.'
    Assert-BoostLabCondition ([string]$restoreResult.Status -eq 'RestoreUnavailable') 'BitLocker Restore must report unavailable restore.'
    Assert-BoostLabCondition (-not [bool]$restoreResult.ChangesExecuted) 'BitLocker Restore must not execute changes.'
}
finally {
    if ($bitLockerModule) {
        Remove-Module $bitLockerModule -Force -ErrorAction SilentlyContinue
    }
    if ($actionPlanModule) {
        Remove-Module $actionPlanModule -Force -ErrorAction SilentlyContinue
    }
}

$migrationText = Get-Content -LiteralPath $migrationRecordPath -Raw
foreach ($needle in @(
    'BitLocker Migration Record',
    $expectedSourceHash,
    'Phase 115 Yazan-approved source-equivalent BitLocker Off and On/status behavior',
    'Disable-BitLocker -MountPoint <mount> -ErrorAction SilentlyContinue',
    'Start-Process control.exe -ArgumentList "/name microsoft.bitlockerdriveencryption"',
    'manage-bde -status',
    'Default is not Restore'
)) {
    Assert-BoostLabTextContains -Text $migrationText -Needle $needle -Description 'BitLocker migration record'
}

[pscustomobject]@{
    Success                                      = $true
    ActiveToolCount                              = $inventorySnapshot.ActiveTools
    ImplementedToolCount                         = $inventorySnapshot.ImplementedTools
    PlaceholderToolCount                         = $inventorySnapshot.DeferredPlaceholders
    SourcePromotedMirrorFileCount                = $inventorySnapshot.SourcePromotedMirrorFiles
    RemainingUnimplementedSourcePromotedIntake   = $inventorySnapshot.RemainingSourcePromotedIntakeCandidates
    Message                                      = 'BitLocker controlled implementation preserves source-equivalent Off and On/status behavior through mockable execution seams.'
    Timestamp                                    = Get-Date
}
