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
        throw 'Unable to determine the BIOS Settings ordered parity validator path.'
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

$inventoryAssertion = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
$inventoryBaseline = $inventoryAssertion.Baseline
$inventorySnapshot = $inventoryAssertion.Snapshot
$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot

$biosRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'bios-settings' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $biosRecord) 'BIOS Settings parity record was not found.'
Assert-BoostLabCondition ([string]$biosRecord.ImplementationLevel -eq 'NearParityControlled') 'BIOS Settings must remain NearParityControlled.'
Assert-BoostLabCondition ([string]$biosRecord.UltimateParity -eq 'Partial') 'BIOS Settings accepted near parity must not be counted as full Ultimate parity.'
Assert-BoostLabCondition (-not [bool]$biosRecord.YazanFinalException) 'BIOS Settings must not use a YazanFinalException.'
$hasAcceptedNearParity = $biosRecord -is [System.Collections.IDictionary] -and $biosRecord.Contains('YazanAcceptedNearParity') -and [bool]$biosRecord['YazanAcceptedNearParity']
$hasDoneStatus = $biosRecord -is [System.Collections.IDictionary] -and $biosRecord.Contains('FinalProgressStatus') -and [string]$biosRecord['FinalProgressStatus'] -eq 'DoneYazanAcceptedNearParity'
Assert-BoostLabCondition $hasAcceptedNearParity 'BIOS Settings must be marked YazanAcceptedNearParity.'
Assert-BoostLabCondition $hasDoneStatus 'BIOS Settings final progress status is incorrect.'
Assert-BoostLabCondition ([string]$biosRecord.NextParityAction -match 'unattended') 'BIOS Settings NextParityAction must point to Unattended after Reinstall near-parity acceptance.'

$resetTarget = $null
foreach ($stage in @($executionOrder.Stages)) {
    foreach ($tool in @($stage.Tools)) {
        $record = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq [string]$tool.ToolId }) | Select-Object -First 1
        if ([string]$record.ImplementationLevel -ne 'ParityImplemented' -and -not [bool]$record.YazanFinalException) {
            $resetTarget = $record
            break
        }
    }
    if ($null -ne $resetTarget) {
        break
    }
}
Assert-BoostLabCondition ([string]$resetTarget.ToolId -eq 'bios-settings') 'BIOS Settings must be the ordered target resolved by this phase.'

$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ($null -ne $nextTarget) 'Next ordered parity target was not found.'
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq 'to-bios') 'DoneYazanAcceptedNearParity tools and Yazan final exceptions must be skipped by next ordered target calculation.'

$sourcePath = Join-Path $ProjectRoot 'source-ultimate\1 Check\2 BIOS Settings.ps1'
$migrationPath = Join-Path $ProjectRoot 'docs\migrations\bios-settings.md'
$modulePath = Join-Path $ProjectRoot 'modules\Check\BIOSSettings.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
$expectedHash = 'C68BDADC7EEAC77A0FE8ECE999CEB5A28C51D819D69107AFD471739BA36E2737'
Assert-BoostLabCondition ($sourceHash -eq $expectedHash) 'BIOS Settings Ultimate source checksum changed.'

$migrationText = Get-Content -Raw -LiteralPath $migrationPath
Assert-BoostLabCondition ($migrationText.Contains('source-ultimate/1 Check/2 BIOS Settings.ps1')) 'BIOS Settings migration record source path is missing.'
Assert-BoostLabCondition ($migrationText.Contains($expectedHash)) 'BIOS Settings migration record source hash is missing.'
Assert-BoostLabCondition ($migrationText.Contains('shutdown.exe /r /fw /t 0')) 'BIOS Settings migration record no longer documents the firmware restart command.'
Assert-BoostLabCondition ($migrationText.Contains('explicit GUI confirmation')) 'BIOS Settings migration record no longer documents the confirmation replacement for Pause.'

$moduleText = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredText in @(
    '$commandProcessorPath = Join-Path $env:SystemRoot ''System32\cmd.exe''',
    '$shutdownPath = Join-Path $env:SystemRoot ''System32\shutdown.exe''',
    '$firmwareRestartCommand = "`"$shutdownPath`" /r /fw /t 0"',
    '& $commandProcessorPath @firmwareRestartArguments',
    'This PC will restart immediately and attempt to enter BIOS/UEFI firmware settings.'
)) {
    Assert-BoostLabCondition ($moduleText.Contains($requiredText)) "BIOS Settings runtime parity behavior is missing: $requiredText"
}
foreach ($forbiddenText in @(
    'https://www.google.com/search?q=',
    'Invoke-WebRequest',
    'Invoke-RestMethod',
    'Start-BitsTransfer',
    'bcdedit',
    'source-ultimate'
)) {
    Assert-BoostLabCondition (-not $moduleText.Contains($forbiddenText)) "BIOS Settings runtime contains forbidden behavior: $forbiddenText"
}

$actionPlanText = Get-Content -Raw -LiteralPath $actionPlanPath
Assert-BoostLabCondition ($actionPlanText.Contains('This PC will restart immediately and attempt to enter BIOS/UEFI firmware settings.')) 'BIOS Settings action plan confirmation text is missing.'

Assert-BoostLabCondition ([int]$parityBaseline.Counts.RuntimeImplementedTools -eq [int]$inventoryBaseline.ImplementedTools) 'Runtime implemented count changed.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.UltimateParityImplemented -eq 16) 'Ultimate parity implemented count must remain 16 after near-parity acceptance.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.RuntimeImplementedTools -ne [int]$parityBaseline.Counts.UltimateParityImplemented) 'Runtime implemented and Ultimate parity implemented counts must remain separate.'
Assert-BoostLabCondition ([int]$inventorySnapshot.ActiveTools -eq 55) 'Active tool count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.ImplementedTools -eq 44) 'Runtime implemented tool count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.DeferredPlaceholders -eq 11) 'Deferred placeholder count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.SourcePromotedMirrorFiles -eq 7) 'Source-promoted mirror file count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.RemainingSourcePromotedIntakeCandidates -eq 0) 'Remaining source-promoted intake count changed.'

$artifactPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1')
$productionPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1')
if ($artifactPolicy.ContainsKey('Artifacts')) {
    Assert-BoostLabCondition (@($artifactPolicy.Artifacts).Count -eq 0) 'Artifact provenance approvals must remain empty.'
}
if ($productionPolicy.ContainsKey('ProductionAllowlistProposals')) {
    Assert-BoostLabCondition (@($productionPolicy.ProductionAllowlistProposals).Count -eq 0) 'Production allowlist proposals must remain empty.'
}

$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }).Count -eq 0) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    Test = 'BIOSSettingsOrderedParityAcceptance'
    OrderedTargetResolved = $resetTarget.ToolId
    FinalProgressStatus = $biosRecord['FinalProgressStatus']
    YazanAcceptedNearParity = [bool]$biosRecord['YazanAcceptedNearParity']
    SourcePath = 'source-ultimate/1 Check/2 BIOS Settings.ps1'
    SourceHash = $sourceHash
    RuntimeImplementedTools = $inventorySnapshot.ImplementedTools
    UltimateParityImplemented = $parityBaseline.Counts.UltimateParityImplemented
    NextOrderedPendingTarget = $nextTarget.ToolId
    SourceUltimateUnchanged = $true
    RuntimeBehaviorChanged = $false
    Message = 'BIOS Settings is accepted as final near parity; the firmware restart command remains confirmation-gated and available.'
}
