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
        throw 'Unable to determine the Reinstall ordered parity validator path.'
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
$modulePath = Join-Path $ProjectRoot 'modules\Refresh\reinstall.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\2 Refresh\1 Reinstall.ps1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$migrationPath = Join-Path $ProjectRoot 'docs\migrations\reinstall.md'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'

foreach ($path in @($configPath, $modulePath, $sourcePath, $actionPlanPath, $migrationPath, $artifactPath, $productionAllowlistPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required Reinstall parity file was not found: $path"
}

$expectedSourceHash = '137F519926293F37052817ACBBE20851652E5EA1B9F3B5B9F933AA1E22C2D9FB'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Reinstall source hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."

$sourceText = Get-Content -Raw -LiteralPath $sourcePath
foreach ($needle in @(
    'Write-Host "1. Reinstall: W10"',
    'Write-Host "2. Reinstall: W11`n"',
    'refs/heads/main/mediacreationtoolw10.exe',
    'refs/heads/main/mediacreationtoolw11.exe',
    'Start-Process "$env:SystemRoot\Temp\mediacreationtoolw10.exe"',
    'Start-Process "$env:SystemRoot\Temp\mediacreationtoolw11.exe"',
    'Test-Connection -ComputerName "8.8.8.8"'
)) {
    Assert-BoostLabTextContains -Text $sourceText -Needle $needle -Description 'Reinstall Ultimate source behavior'
}

$stages = Import-PowerShellDataFile -LiteralPath $configPath
$refreshStage = @($stages.Stages | Where-Object { $_.Name -eq 'Refresh' })[0]
$reinstallTool = @($refreshStage.Tools | Where-Object { $_.Id -eq 'reinstall' })[0]
Assert-BoostLabCondition ($null -ne $reinstallTool) 'Reinstall is missing from Refresh stage.'
Assert-BoostLabCondition ([int]$reinstallTool.Order -eq 1) 'Reinstall must remain Refresh order 1.'
Assert-BoostLabCondition ([string]$reinstallTool.Type -eq 'action') 'Reinstall must be an action after the ordered parity upgrade.'
Assert-BoostLabCondition ((@($reinstallTool.Actions) -join ',') -eq 'Analyze,Open,Apply,Default,Restore') 'Reinstall must expose canonical Analyze/Open/Apply/Default/Restore actions.'

$capabilities = $reinstallTool.Capabilities
foreach ($trueCapability in @('RequiresAdmin', 'RequiresInternet', 'CanReboot', 'CanInstallSoftware', 'CanDownload', 'NeedsExplicitConfirmation')) {
    Assert-BoostLabCondition ([bool]$capabilities[$trueCapability]) "Reinstall capability should be true: $trueCapability"
}
foreach ($falseCapability in @('CanModifyRegistry', 'CanModifyServices', 'CanModifyDrivers', 'CanModifySecurity', 'CanDeleteFiles', 'UsesTrustedInstaller', 'UsesSafeMode', 'SupportsDefault', 'SupportsRestore')) {
    Assert-BoostLabCondition (-not [bool]$capabilities[$falseCapability]) "Reinstall capability should be false: $falseCapability"
}

$moduleText = Get-Content -Raw -LiteralPath $modulePath
foreach ($needle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Open'', ''Apply'', ''Default'', ''Restore'')',
    'ControlledSourceEquivalent',
    'Windows11MediaCreationToolApplyAvailable',
    'mediacreationtoolw11.exe',
    'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw11.exe',
    'SourceDownloadCommand',
    'SourceLaunchCommand',
    'Invoke-WebRequest',
    'Start-Process',
    'Windows10BranchUnsupported',
    'DefaultUnavailable',
    'RestoreUnavailable'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'Reinstall module'
}
foreach ($forbiddenText in @(
    'bcdedit',
    'Restart-Computer',
    'shutdown.exe',
    'Mount-DiskImage',
    'Set-ItemProperty',
    'Remove-ItemProperty'
)) {
    Assert-BoostLabCondition (-not $moduleText.Contains($forbiddenText)) "Reinstall module contains forbidden behavior: $forbiddenText"
}

$module = Import-Module -Name $modulePath -Force -PassThru -ErrorAction Stop
try {
    $info = Get-BoostLabToolInfo
    Assert-BoostLabCondition ([string]$info.Id -eq 'reinstall') 'Module info Id mismatch.'
    Assert-BoostLabCondition ((@($info.ImplementedActions) -join '|') -eq 'Analyze|Open|Apply|Default|Restore') 'Implemented actions mismatch.'
    Assert-BoostLabCondition ((@($info.ConfirmationRequiredActions) -join '|') -eq 'Apply') 'Only Apply should require module-level confirmation.'

    $descriptor = Get-BoostLabReinstallOperationDescriptor
    Assert-BoostLabCondition ([string]$descriptor.Branch -eq 'Windows11') 'Descriptor branch mismatch.'
    Assert-BoostLabCondition ([string]$descriptor.DownloadUrl -eq 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw11.exe') 'Descriptor download URL mismatch.'
    Assert-BoostLabCondition ([string]$descriptor.ExpectedFileName -eq 'mediacreationtoolw11.exe') 'Descriptor file name mismatch.'
    Assert-BoostLabCondition ([string]$descriptor.SourceDownloadCommand -eq 'IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw11.exe" -OutFile "$env:SystemRoot\Temp\mediacreationtoolw11.exe"') 'Descriptor source download command mismatch.'
    Assert-BoostLabCondition ([string]$descriptor.SourceLaunchCommand -eq 'Start-Process "$env:SystemRoot\Temp\mediacreationtoolw11.exe"') 'Descriptor source launch command mismatch.'
    Assert-BoostLabCondition ('Windows 10 Media Creation Tool branch' -in @($descriptor.UnsupportedBranches)) 'Windows 10 branch must remain unsupported.'

    $analysis = Invoke-BoostLabToolAction -ActionName 'Analyze'
    Assert-BoostLabCondition ([bool]$analysis.Success) 'Analyze should succeed when source checksum matches.'
    Assert-BoostLabCondition ([string]$analysis.Status -eq 'Analyzed') 'Analyze status mismatch.'
    Assert-BoostLabCondition ([string]$analysis.CommandStatus -eq 'No execution performed') 'Analyze must be read-only.'
    Assert-BoostLabCondition ([string]$analysis.Data.Mode -eq 'ControlledSourceEquivalent') 'Analyze mode mismatch.'
    Assert-BoostLabCondition ([string]$analysis.Data.AutoMode -eq 'Windows11MediaCreationToolApplyAvailable') 'Analyze Auto mode mismatch.'
    Assert-BoostLabCondition ([bool]$analysis.Data.SourceEquivalentWindows11) 'Analyze must report Windows 11 source equivalence.'
    Assert-BoostLabCondition ([bool]$analysis.Data.Windows10BranchUnsupported) 'Analyze must report Windows 10 branch unsupported.'

    $open = Invoke-BoostLabToolAction -ActionName 'Open'
    Assert-BoostLabCondition ([bool]$open.Success) 'Open should prepare guidance.'
    Assert-BoostLabCondition ([string]$open.Status -eq 'GuidancePrepared') 'Open status mismatch.'
    Assert-BoostLabCondition ([string]$open.CommandStatus -eq 'No execution performed') 'Open must not execute.'
    Assert-BoostLabCondition (-not [bool]$open.ChangesExecuted) 'Open must not report changes.'

    $applyUnconfirmed = Invoke-BoostLabToolAction -ActionName 'Apply'
    Assert-BoostLabCondition (-not [bool]$applyUnconfirmed.Success) 'Unconfirmed Apply must not execute.'
    Assert-BoostLabCondition ([string]$applyUnconfirmed.Status -eq 'ConfirmationRequired') 'Unconfirmed Apply status mismatch.'
    Assert-BoostLabCondition ([string]$applyUnconfirmed.CommandStatus -eq 'Cancelled before execution') 'Unconfirmed Apply command status mismatch.'
    Assert-BoostLabCondition ([bool]$applyUnconfirmed.Cancelled) 'Unconfirmed Apply must be marked cancelled.'
    Assert-BoostLabCondition (-not [bool]$applyUnconfirmed.ChangesExecuted) 'Unconfirmed Apply must not report changes.'

    $default = Invoke-BoostLabToolAction -ActionName 'Default'
    Assert-BoostLabCondition (-not [bool]$default.Success) 'Default must be unavailable.'
    Assert-BoostLabCondition ([string]$default.Status -eq 'DefaultUnavailable') 'Default status mismatch.'

    $restore = Invoke-BoostLabToolAction -ActionName 'Restore'
    Assert-BoostLabCondition (-not [bool]$restore.Success) 'Restore must be unavailable.'
    Assert-BoostLabCondition ([string]$restore.Status -eq 'RestoreUnavailable') 'Restore status mismatch.'
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
}

$actionPlanText = Get-Content -Raw -LiteralPath $actionPlanPath
foreach ($needle in @(
    'Download the source-defined Windows 11 Media Creation Tool to Windows Temp and launch it after explicit confirmation.',
    'Download the source-defined Windows 11 Media Creation Tool from the Ultimate source URL to %SystemRoot%\Temp\mediacreationtoolw11.exe.',
    'Launch the downloaded Windows 11 Media Creation Tool with Start-Process.',
    'Windows 10 branch remains unsupported.'
)) {
    Assert-BoostLabTextContains -Text $actionPlanText -Needle $needle -Description 'Reinstall Action Plan'
}
Assert-BoostLabCondition (-not $actionPlanText.Contains('Auto mode is blocked for Reinstall')) 'Reinstall Apply Action Plan must no longer describe Auto as blocked.'

$migrationText = Get-Content -Raw -LiteralPath $migrationPath
foreach ($needle in @(
    'Phase 110 upgrades Reinstall',
    'IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw11.exe"',
    'Start-Process "$env:SystemRoot\Temp\mediacreationtoolw11.exe"',
    'Windows 10 branch support remains outside product scope.',
    'DoneYazanAcceptedNearParity'
)) {
    Assert-BoostLabTextContains -Text $migrationText -Needle $needle -Description 'Reinstall migration record'
}

$reinstallRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'reinstall' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $reinstallRecord) 'Reinstall parity record was not found.'
Assert-BoostLabCondition ([string]$reinstallRecord.ImplementationLevel -eq 'NearParityControlled') 'Reinstall must be NearParityControlled.'
Assert-BoostLabCondition ([string]$reinstallRecord.UltimateParity -eq 'Partial') 'Reinstall must remain partial parity because Windows 10 branch is unsupported.'
Assert-BoostLabCondition (-not [bool]$reinstallRecord.YazanFinalException) 'Reinstall must not use YazanFinalException.'
Assert-BoostLabCondition ([bool]$reinstallRecord.YazanAcceptedNearParity) 'Reinstall must be YazanAcceptedNearParity.'
Assert-BoostLabCondition ([string]$reinstallRecord.FinalProgressStatus -eq 'DoneYazanAcceptedNearParity') 'Reinstall final progress status mismatch.'

$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ($null -ne $nextTarget) 'Next ordered parity target was not found.'
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq [string]$parityBaseline.CurrentOrderedParityTarget) 'Next ordered parity target must match the central parity baseline cursor.'

$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
Assert-BoostLabCondition ([int]$categoryCounts['ParityImplemented'] -eq [int]$parityBaseline.Counts.UltimateParityImplemented) 'Ultimate parity implemented count mismatch.'
Assert-BoostLabCondition ([int]$categoryCounts['NearParityControlled'] -eq [int]$parityBaseline.Counts.NearParityControlled) 'NearParityControlled count mismatch.'
Assert-BoostLabCondition ([int]$categoryCounts['ManualHandoffOnly'] -eq 1) 'ManualHandoffOnly count mismatch.'
Assert-BoostLabCondition ([int]$inventorySnapshot.ActiveTools -eq 55) 'Active tool count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.ImplementedTools -eq [int]$inventoryBaseline.ImplementedTools) 'Runtime implemented count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.DeferredPlaceholders -eq [int]$inventoryBaseline.DeferredPlaceholders) 'Deferred placeholder count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.SourcePromotedMirrorFiles -eq 7) 'Source-promoted mirror file count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.RemainingSourcePromotedIntakeCandidates -eq 0) 'Remaining source-promoted intake count changed.'

$artifactConfig = Import-PowerShellDataFile -LiteralPath $artifactPath
$productionPolicy = Import-PowerShellDataFile -LiteralPath $productionAllowlistPath
if ($artifactConfig.ContainsKey('Artifacts')) {
    Assert-BoostLabCondition (@($artifactConfig.Artifacts).Count -eq 0) 'Artifact provenance approvals must remain empty.'
}
if ($productionPolicy.ContainsKey('ProductionAllowlistProposals')) {
    Assert-BoostLabCondition (@($productionPolicy.ProductionAllowlistProposals).Count -eq 0) 'Production allowlist proposals must remain empty.'
}

$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceManifestLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
    Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
    Sort-Object {
        $_.FullName.Substring($root.Length + 1).Replace('\', '/')
    } |
    ForEach-Object {
        '{0}|{1}' -f `
            $_.FullName.Substring($root.Length + 1).Replace('\', '/'), `
            (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    }
$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $manifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash(
            [Text.Encoding]::UTF8.GetBytes(($sourceManifestLines -join "`n"))
        )
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}
Assert-BoostLabCondition (@($sourceManifestLines).Count -eq 49) "source-ultimate file count changed: $(@($sourceManifestLines).Count)"
Assert-BoostLabCondition ($manifestHash -eq '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') 'source-ultimate content or paths changed.'

foreach ($deletedPath in @(
    'source-ultimate\6 Windows\17 Loudness EQ.ps1',
    'source-ultimate\6 Windows\30 NVME Faster Driver.ps1'
)) {
    Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $deletedPath))) "Deleted source was reintroduced: $deletedPath"
}

[pscustomobject]@{
    Test = 'ReinstallOrderedParityUpgrade'
    SourcePath = 'source-ultimate/2 Refresh/1 Reinstall.ps1'
    SourceHash = $actualSourceHash
    RuntimeImplementedTools = $inventorySnapshot.ImplementedTools
    UltimateParityImplemented = $parityBaseline.Counts.UltimateParityImplemented
    NearParityControlled = $parityBaseline.Counts.NearParityControlled
    ManualHandoffOnly = $parityBaseline.Counts.ManualHandoffOnly
    ReinstallFinalProgressStatus = $reinstallRecord.FinalProgressStatus
    NextOrderedPendingTarget = $nextTarget.ToolId
    SourceUltimateUnchanged = $true
    Message = 'Reinstall Windows 11 source branch is controlled, confirmation-gated, and accepted as near parity.'
}

