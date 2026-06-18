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
$modulePath = Join-Path $ProjectRoot 'modules\Setup\bitlocker.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate\3 Setup\1 BitLocker.ps1'
$intakePath = Join-Path $ProjectRoot 'intake\missing-ultimate-scripts\Ultimate\3 Setup\1 BitLocker.ps1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$migrationRecordPath = Join-Path $ProjectRoot 'docs\migrations\bitlocker.md'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourcePromotedRoot = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate'

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
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required Phase 98 file is missing: $path"
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
Assert-BoostLabCondition ([int]$bitLockerTool.Order -eq 9) 'BitLocker must use the approved Setup order.'
Assert-BoostLabCondition ([string]$bitLockerTool.Type -eq 'assistant') 'BitLocker must remain an assistant.'
Assert-BoostLabCondition ([string]$bitLockerTool.RiskLevel -eq 'high') 'BitLocker must remain high risk.'
Assert-BoostLabCondition ((@($bitLockerTool.Actions) -join '|') -eq 'Analyze|Apply|Default|Restore|Open') 'BitLocker must expose only canonical Analyze, Apply, Default, Restore, and Open actions.'
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($setupTools | Where-Object { $_.Id -eq 'bitlocker' })) -eq 1) 'BitLocker must appear exactly once in Setup.'
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Stage -eq 'Graphics' -and $_.Id -eq 'bitlocker' })) -eq 0) 'BitLocker must not be merged into NVIDIA Path B.'

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
            '1 Driver Clean.ps1'
            '2 Driver Install Latest.ps1'
            '4 Nvidia Settings.ps1'
            '5 Hdcp.ps1'
            '6 P0 State.ps1'
            '7 Msi Mode.ps1'
            '1 BitLocker.ps1'
        )
    }
)
Assert-BoostLabCondition ($remainingSourcePromoted.Count -eq 0) "Expected 0 remaining unimplemented source-promoted intake candidates, found $($remainingSourcePromoted.Count)."
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Id -eq 'ddu' -or $_.Title -eq 'DDU' })) -eq 0) 'Standalone DDU must not be introduced.'
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Title -eq 'Loudness EQ' -or $_.Id -eq 'loudness-eq' })) -eq 0) 'Loudness EQ must remain deleted.'
Assert-BoostLabCondition ((Get-BoostLabItemCount -Value ($allTools | Where-Object { $_.Title -eq 'NVME Faster Driver' -or $_.Id -eq 'nvme-faster-driver' })) -eq 0) 'NVME Faster Driver must remain deleted.'

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
    'Analyze BitLocker volume state read-only',
    'Prepare BitLocker manual handoff guidance only',
    'Block the source Off branch because it disables BitLocker',
    'Block Default because the source On branch is UI/status-only',
    'Block Restore because no captured BitLocker state restore contract exists',
    'Do not open BitLocker Control Panel, a browser, manage-bde, PowerShell BitLocker commands, or any external tool.',
    'No Disable-BitLocker, Enable-BitLocker, manage-bde, decrypt, suspend/resume, protector, recovery-key, external process, registry, or reboot operation occurs.'
)) {
    Assert-BoostLabTextContains -Text $actionPlanText -Needle $needle -Description 'BitLocker action plan'
}

$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($needle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'', ''Restore'', ''Open'')',
    $expectedSourceHash,
    'Get-BitLockerVolume',
    'NeedsSecurityDecision',
    'NeedsRecoveryKeyPolicy',
    'NeedsEncryptionStateContract',
    'ManualHandoffOnly',
    'DefaultUnavailable',
    'RestoreUnavailable',
    'NoSilentEnableDisableDecryptSuspendOrProtectorMutation',
    'BitLocker remains separate from Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode.'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'BitLocker module'
}

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
    'Disable-BitLocker',
    'Enable-BitLocker',
    'Suspend-BitLocker',
    'Resume-BitLocker',
    'Unlock-BitLocker',
    'Remove-BitLockerKeyProtector',
    'Add-BitLockerKeyProtector',
    'manage-bde',
    'Start-Process',
    'Set-ItemProperty',
    'New-ItemProperty',
    'Remove-ItemProperty',
    'Restart-Computer',
    'bcdedit'
)) {
    Assert-BoostLabCondition ($forbiddenCommand -notin $commands) "BitLocker module must not execute command: $forbiddenCommand"
}

$artifactText = Get-Content -LiteralPath $artifactPath -Raw
$allowlistText = Get-Content -LiteralPath $productionAllowlistPath -Raw
Assert-BoostLabCondition (-not $artifactText.Contains('bitlocker')) 'BitLocker must not add artifact provenance approvals.'
Assert-BoostLabCondition (-not $allowlistText.Contains('bitlocker')) 'BitLocker must not add production allowlist approvals.'

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
$bitLockerModule = Import-Module -Name $modulePath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    $analysisPlan = New-BoostLabActionPlan -ToolMetadata $bitLockerTool -ActionName 'Analyze'
    Assert-BoostLabCondition ([bool]$analysisPlan.NeedsExplicitConfirmation) 'BitLocker Analyze plan must preserve high-risk confirmation metadata.'
    Assert-BoostLabCondition ((@($analysisPlan.PlannedChanges) -join ' ') -match 'no external process|Perform no external process') 'BitLocker Analyze plan must be read-only.'

    $openPlan = New-BoostLabActionPlan -ToolMetadata $bitLockerTool -ActionName 'Open'
    $openPlanText = @(
        @($openPlan.PlannedChanges)
        @($openPlan.SideEffects)
        $openPlan.ConfirmationMessage
    ) -join ' '
    foreach ($needle in @(
        'manual BitLocker handoff instructions only',
        'Do not open BitLocker Control Panel',
        'do not open BitLocker Control Panel',
        'no BitLocker state',
        'run manage-bde'
    )) {
        Assert-BoostLabCondition ($openPlanText -match [regex]::Escape($needle)) "BitLocker Open plan missing: $needle"
    }
    foreach ($forbiddenOpenText in @(
        'approved external resource may be opened',
        'A Windows interface or approved external resource may be opened.'
    )) {
        Assert-BoostLabCondition (-not $openPlanText.Contains($forbiddenOpenText)) "BitLocker Open plan must not claim external resource behavior: $forbiddenOpenText"
    }

    $applyPlan = New-BoostLabActionPlan -ToolMetadata $bitLockerTool -ActionName 'Apply'
    $applyPlanText = @(
        @($applyPlan.PlannedChanges)
        @($applyPlan.SideEffects)
        $applyPlan.ConfirmationMessage
    ) -join ' '
    foreach ($needle in @(
        'Block Apply before any operational step',
        'Do not execute the source Off branch',
        'recovery-key',
        'No Disable-BitLocker'
    )) {
        Assert-BoostLabCondition ($applyPlanText -match [regex]::Escape($needle)) "BitLocker Apply plan missing: $needle"
    }
    foreach ($forbiddenBlockedText in @(
        'Modify approved Windows security configuration.',
        'Security changes may alter system protection or compatibility.'
    )) {
        Assert-BoostLabCondition (-not $applyPlanText.Contains($forbiddenBlockedText)) "BitLocker Apply plan must not claim planned security mutation: $forbiddenBlockedText"
    }

    $defaultPlan = New-BoostLabActionPlan -ToolMetadata $bitLockerTool -ActionName 'Default'
    $defaultPlanText = @(
        @($defaultPlan.PlannedChanges)
        @($defaultPlan.SideEffects)
        $defaultPlan.ConfirmationMessage
    ) -join ' '
    foreach ($needle in @(
        'Block Default before any operational step',
        'source On branch',
        'Default is not Restore',
        'No BitLocker state'
    )) {
        Assert-BoostLabCondition ($defaultPlanText -match [regex]::Escape($needle)) "BitLocker Default plan missing: $needle"
    }
    foreach ($forbiddenBlockedText in @(
        'Modify approved Windows security configuration.',
        'Security changes may alter system protection or compatibility.'
    )) {
        Assert-BoostLabCondition (-not $defaultPlanText.Contains($forbiddenBlockedText)) "BitLocker Default plan must not claim planned security mutation: $forbiddenBlockedText"
    }

    $restorePlan = New-BoostLabActionPlan -ToolMetadata $bitLockerTool -ActionName 'Restore'
    $restorePlanText = @(
        @($restorePlan.PlannedChanges)
        @($restorePlan.SideEffects)
        $restorePlan.ConfirmationMessage
    ) -join ' '
    foreach ($needle in @(
        'Block Restore before any operational step',
        'selected captured BitLocker state',
        'approved restore contract',
        'No BitLocker state'
    )) {
        Assert-BoostLabCondition ($restorePlanText -match [regex]::Escape($needle)) "BitLocker Restore plan missing: $needle"
    }
    foreach ($forbiddenBlockedText in @(
        'Modify approved Windows security configuration.',
        'Security changes may alter system protection or compatibility.'
    )) {
        Assert-BoostLabCondition (-not $restorePlanText.Contains($forbiddenBlockedText)) "BitLocker Restore plan must not claim planned security mutation: $forbiddenBlockedText"
    }

    $mockVolumeReader = {
        @(
            [pscustomobject]@{
                MountPoint           = 'C:'
                VolumeStatus         = 'FullyEncrypted'
                ProtectionStatus     = 'On'
                EncryptionPercentage = 100
                LockStatus           = 'Unlocked'
                KeyProtector         = @(
                    [pscustomobject]@{ KeyProtectorType = 'Tpm' }
                    [pscustomobject]@{ KeyProtectorType = 'RecoveryPassword' }
                )
            }
        )
    }

    $analyzeResult = Invoke-BoostLabToolAction -ActionName 'Analyze' -VolumeReader $mockVolumeReader
    Assert-BoostLabCondition ([bool]$analyzeResult.Success) 'BitLocker Analyze should succeed with mocked read-only volume data.'
    Assert-BoostLabCondition ([string]$analyzeResult.Status -eq 'Analyzed') 'BitLocker Analyze status must be Analyzed.'
    Assert-BoostLabCondition ([string]$analyzeResult.CommandStatus -eq 'No execution performed') 'BitLocker Analyze must not execute a command.'
    Assert-BoostLabCondition (-not [bool]$analyzeResult.ChangesExecuted) 'BitLocker Analyze must not execute changes.'
    Assert-BoostLabCondition (-not [bool]$analyzeResult.Data.ApplyAvailable) 'BitLocker Apply must not be available after Analyze.'
    Assert-BoostLabCondition ([int]$analyzeResult.Data.VolumeDiscovery.SourceOffMatchedVolumeCount -eq 1) 'BitLocker Analyze must report source Off matched volume count.'
    Assert-BoostLabCondition ([bool]@($analyzeResult.Data.VolumeDiscovery.Volumes)[0].HasRecoveryPasswordProtector) 'BitLocker Analyze must report recovery protector type without exposing key values.'
    Assert-BoostLabCondition (@($analyzeResult.Warnings).Count -eq 0) 'BitLocker Analyze top-level warnings must not duplicate structured warning details.'
    $structuredAnalyzeWarnings = @($analyzeResult.Data.Warnings)
    Assert-BoostLabCondition ($structuredAnalyzeWarnings.Count -gt 0) 'BitLocker Analyze must keep warning details in structured data.'
    Assert-BoostLabCondition (($structuredAnalyzeWarnings | Select-Object -Unique).Count -eq $structuredAnalyzeWarnings.Count) 'BitLocker Analyze structured warnings must not be duplicated.'
    Assert-BoostLabCondition ((($analyzeResult | ConvertTo-Json -Depth 12) -notmatch '(?i)recoverypassword\\s*[0-9]{2,}|[0-9]{6}-[0-9]{6}-[0-9]{6}') ) 'BitLocker Analyze must not expose recovery key values.'

    $openCancelled = Invoke-BoostLabToolAction -ActionName 'Open' -Confirmed:$false -VolumeReader $mockVolumeReader
    Assert-BoostLabCondition (-not [bool]$openCancelled.Success) 'BitLocker Open without confirmation must not succeed.'
    Assert-BoostLabCondition ([bool]$openCancelled.Cancelled) 'BitLocker Open without confirmation must be cancelled.'
    Assert-BoostLabCondition (-not [bool]$openCancelled.ChangesExecuted) 'Cancelled BitLocker Open must not execute changes.'

    $openResult = Invoke-BoostLabToolAction -ActionName 'Open' -Confirmed:$true -VolumeReader $mockVolumeReader
    Assert-BoostLabCondition ([bool]$openResult.Success) 'BitLocker Open manual handoff should succeed when confirmed.'
    Assert-BoostLabCondition ([string]$openResult.Status -eq 'ManualHandoffPrepared') 'BitLocker Open must prepare manual handoff only.'
    Assert-BoostLabCondition ([string]$openResult.CommandStatus -eq 'No execution performed') 'BitLocker Open command status must show no execution.'
    Assert-BoostLabCondition (-not [bool]$openResult.ChangesExecuted) 'BitLocker Open must not execute changes.'
    Assert-BoostLabCondition ([bool]$openResult.Data.NoExternalToolOpened) 'BitLocker Open must not open an external tool.'
    Assert-BoostLabCondition ([bool]$openResult.Data.NoBitLockerMutation) 'BitLocker Open must not mutate BitLocker.'

    $applyResult = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true -VolumeReader $mockVolumeReader
    Assert-BoostLabCondition (-not [bool]$applyResult.Success) 'BitLocker Apply must fail closed.'
    Assert-BoostLabCondition ([string]$applyResult.Status -eq 'NeedsRecoveryKeyPolicy') 'BitLocker Apply must report recovery-key policy blocker.'
    Assert-BoostLabCondition ([string]$applyResult.CommandStatus -eq 'Blocked before execution') 'BitLocker Apply command status must be blocked before execution.'
    Assert-BoostLabCondition (-not [bool]$applyResult.ChangesExecuted) 'BitLocker Apply must not execute changes.'
    Assert-BoostLabCondition ('NeedsEncryptionStateContract' -in @($applyResult.Data.Blockers)) 'BitLocker Apply must report encryption-state blocker.'

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
    'Analyze',
    'Open',
    'Apply',
    'Default',
    'Restore',
    'Disable-BitLocker',
    'manual handoff',
    'Default is not Restore'
)) {
    Assert-BoostLabTextContains -Text $migrationText -Needle $needle -Description 'BitLocker migration record'
}

[pscustomobject]@{
    Success                                      = $true
    ActiveToolCount                              = $allTools.Count
    ImplementedToolCount                         = $allTools.Count - $placeholderModules.Count
    PlaceholderToolCount                         = $placeholderModules.Count
    SourcePromotedMirrorFileCount                = $sourcePromotedFiles.Count
    RemainingUnimplementedSourcePromotedIntake   = $remainingSourcePromoted.Count
    Message                                      = 'BitLocker controlled security implementation is fail-closed and non-mutating.'
    Timestamp                                    = Get-Date
}
