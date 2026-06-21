Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PSScriptRoot) {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}
else {
    $scriptPath = $PSCommandPath
    if (-not $scriptPath -and $MyInvocation.MyCommand.Path) {
        $scriptPath = $MyInvocation.MyCommand.Path
    }
    if (-not $scriptPath) {
        throw 'Unable to determine the GameMode validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}

. (Join-Path $ProjectRoot 'tests\BoostLab.ParityStatusBaseline.ps1')
. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')

function Assert-GameModeCondition {
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

$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\9 Gamemode.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\game-mode.psm1'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$artifactPolicyPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ExternalArtifactSources.psd1'

$expectedSourceHash = 'F83275C0B3CE135679C2F1D98A1F0BD6B101936E0B2BC17B542DE288EF6A0B82'
$expectedLauncher = 'Start-Process "ms-settings:gaming-gamemode"'

$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
Assert-GameModeCondition ($actualSourceHash -eq $expectedSourceHash) "GameMode source checksum mismatch. Expected $expectedSourceHash, found $actualSourceHash."

$sourceText = (Get-Content -Raw -LiteralPath $sourcePath).Trim()
$moduleText = Get-Content -Raw -LiteralPath $modulePath
$executionText = Get-Content -Raw -LiteralPath $executionPath

Assert-GameModeCondition ($sourceText -eq $expectedLauncher) 'Ultimate GameMode source must remain the approved single Settings launcher.'
Assert-GameModeCondition ($moduleText.Contains($expectedLauncher)) 'BoostLab GameMode module must preserve the exact source Settings launcher.'
Assert-GameModeCondition ($moduleText.Contains('$script:BoostLabImplementedActions = @(''Open'')')) 'GameMode must remain Open-only implemented.'
Assert-GameModeCondition (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) 'GameMode must not use placeholder behavior.'
Assert-GameModeCondition (-not ($moduleText -match 'Set-ItemProperty|New-ItemProperty|Remove-ItemProperty|Remove-Item|Set-Content|Add-Content|Out-File|Stop-Process|Stop-Service|Set-Service|New-ScheduledTask|Register-ScheduledTask|schtasks|Invoke-WebRequest|Invoke-RestMethod|Start-BitsTransfer|winget|Get-AppxPackage|Remove-AppxPackage|Restart-Computer|bcdedit')) 'GameMode module must not contain mutation, package, download, task, service, process-stop, or reboot commands.'

$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $modulePath,
    [ref]$tokens,
    [ref]$parseErrors
)
if (@($parseErrors).Count -gt 0) {
    throw "GameMode module parse failed: $(@($parseErrors)[0].Message)"
}
$commands = @(
    $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
        $true
    ) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }
)
Assert-GameModeCondition (@($commands | Where-Object { $_ -eq 'Start-Process' }).Count -eq 1) 'GameMode must contain exactly one Start-Process command.'

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$tool = @($stages.Stages | ForEach-Object { $_.Tools } | Where-Object { [string]$_.Id -eq 'game-mode' }) | Select-Object -First 1
Assert-GameModeCondition ($null -ne $tool) 'GameMode stage entry is missing.'
Assert-GameModeCondition ([string]$tool.Title -eq 'GameMode') 'GameMode title changed.'
Assert-GameModeCondition ([string]$tool.Type -eq 'assistant') 'GameMode must remain an assistant.'
Assert-GameModeCondition ([string]$tool.RiskLevel -eq 'low') 'GameMode risk level must remain low.'
Assert-GameModeCondition ((@($tool.Actions) -join ',') -eq 'Open') 'GameMode must expose only Open.'
foreach ($capability in @(
    'RequiresAdmin',
    'RequiresInternet',
    'CanReboot',
    'CanModifyRegistry',
    'CanModifyServices',
    'CanInstallSoftware',
    'CanDownload',
    'CanModifyDrivers',
    'CanModifySecurity',
    'CanDeleteFiles',
    'UsesTrustedInstaller',
    'UsesSafeMode',
    'SupportsDefault',
    'SupportsRestore',
    'NeedsExplicitConfirmation'
)) {
    Assert-GameModeCondition (-not [bool]$tool.Capabilities[$capability]) "GameMode must not enable capability: $capability"
}

Assert-GameModeCondition ($executionText.Contains("'game-mode' = @{")) 'Execution registry must include GameMode.'
Assert-GameModeCondition ($executionText.Contains("Windows\game-mode.psm1")) 'Execution registry must route to the GameMode module.'
Assert-GameModeCondition ($executionText.Contains("Actions = @('Open')")) 'Execution registry must expose Open-only actions for GameMode.'

$gameModeModule = Import-Module -Force -PassThru -Prefix GameModeTest -Name $modulePath
try {
    $toolInfo = Get-GameModeTestBoostLabToolInfo
    Assert-GameModeCondition ((@($toolInfo.Actions) -join ',') -eq 'Open') 'GameMode tool info must expose Open only.'
    Assert-GameModeCondition ((@($toolInfo.ImplementedActions) -join ',') -eq 'Open') 'GameMode implemented actions must expose Open only.'
    Assert-GameModeCondition (-not [bool]$toolInfo.Capabilities.SupportsDefault) 'GameMode must not support Default.'
    Assert-GameModeCondition (-not [bool]$toolInfo.Capabilities.SupportsRestore) 'GameMode must not support Restore.'

    $unsupportedDefault = Invoke-GameModeTestBoostLabToolAction -ActionName 'Default'
    Assert-GameModeCondition (-not [bool]$unsupportedDefault.Success) 'GameMode Default must not be implemented.'
    Assert-GameModeCondition ([string]$unsupportedDefault.Message -match 'Only Open') 'GameMode unsupported action message must describe Open-only behavior.'

    $restoreResult = Restore-GameModeTestBoostLabToolDefault
    Assert-GameModeCondition (-not [bool]$restoreResult.Success) 'GameMode Restore/Default helper must not expose a real Default.'
}
finally {
    if ($gameModeModule) {
        Remove-Module -ModuleInfo $gameModeModule -Force -ErrorAction SilentlyContinue
    }
}

$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPolicyPath
Assert-GameModeCondition (@($artifactPolicy.Artifacts).Count -eq 0) 'GameMode must not approve artifact provenance entries.'
$externalSources = Import-PowerShellDataFile -LiteralPath $productionAllowlistPath
$gameModeExternalSources = @($externalSources.ExternalSources | Where-Object { [string]$_.ToolId -eq 'game-mode' })
Assert-GameModeCondition ($gameModeExternalSources.Count -eq 0) 'GameMode must not add external artifact source entries.'

$inventory = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
$gameModeRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'game-mode' }) | Select-Object -First 1
Assert-GameModeCondition ($null -ne $gameModeRecord) 'GameMode parity record is missing.'
Assert-GameModeCondition ([string]$gameModeRecord.RuntimeStatus -eq 'RuntimeImplemented') 'GameMode runtime status must remain RuntimeImplemented.'
Assert-GameModeCondition ([string]$gameModeRecord.ImplementationLevel -eq 'ParityImplemented') 'GameMode must be marked ParityImplemented.'
Assert-GameModeCondition ([string]$gameModeRecord.UltimateParity -eq 'Yes') 'GameMode UltimateParity must be Yes.'
Assert-GameModeCondition (-not [bool]$gameModeRecord.YazanFinalException) 'GameMode must not use a Yazan final exception.'
Assert-GameModeCondition ([string]$gameModeRecord.NextParityAction -match 'pointer-precision') 'GameMode parity action must document advancing to Pointer Precision.'
Assert-GameModeCondition ([string]$parityBaseline.CurrentOrderedParityTarget -eq [string]$nextTarget.ToolId) 'Current ordered parity target must match the derived first non-final target.'
Assert-GameModeCondition ([string]$parityBaseline.CurrentOrderedParityTarget -ne 'game-mode') 'Current ordered parity cursor must advance beyond GameMode.'

$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
foreach ($level in @('ParityImplemented', 'NearParityControlled', 'ControlledSubset', 'ManualHandoffOnly', 'DeferredForParityWork')) {
    $actual = if ($categoryCounts.ContainsKey($level)) { [int]$categoryCounts[$level] } else { 0 }
    $expected = switch ($level) {
        'ParityImplemented' { [int]$parityBaseline.Counts.UltimateParityImplemented }
        'NearParityControlled' { [int]$parityBaseline.Counts.NearParityControlled }
        'ControlledSubset' { [int]$parityBaseline.Counts.ControlledSubset }
        'ManualHandoffOnly' { [int]$parityBaseline.Counts.ManualHandoffOnly }
        'DeferredForParityWork' { [int]$parityBaseline.Counts.DeferredForParityWork }
    }
    Assert-GameModeCondition ($actual -eq $expected) "Unexpected parity category count for $level."
}

foreach ($deletedPath in @(
    'source-ultimate\6 Windows\17 Loudness EQ.ps1',
    'modules\Windows\loudness-eq.psm1',
    'source-ultimate\6 Windows\20 NVME Faster Driver.ps1',
    'modules\Windows\nvme-faster-driver.psm1'
)) {
    Assert-GameModeCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $deletedPath))) "Deleted tool path was reintroduced: $deletedPath"
}

[pscustomobject]@{
    Success                    = $true
    ToolId                     = 'game-mode'
    SourceHash                 = $actualSourceHash
    RuntimeCommand             = $expectedLauncher
    ImplementationLevel        = [string]$gameModeRecord.ImplementationLevel
    UltimateParity             = [string]$gameModeRecord.UltimateParity
    CurrentOrderedParityTarget = [string]$parityBaseline.CurrentOrderedParityTarget
    ActiveTools                = [int]$inventory.Snapshot.ActiveTools
    RuntimeImplementedTools    = [int]$inventory.Snapshot.ImplementedTools
    DeferredPlaceholders       = [int]$inventory.Snapshot.DeferredPlaceholders
    OpenActionExecuted         = $false
    SourceUltimateUnchanged    = $true
    DeletedToolsRemainDeleted  = $true
    Message                    = 'GameMode is exact source-equivalent Open-only parity and the ordered cursor advances to Pointer Precision.'
    Timestamp                  = Get-Date
}
