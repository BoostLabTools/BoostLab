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
        throw 'Unable to determine the To BIOS ordered parity validator path.'
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
$modulePath = Join-Path $ProjectRoot 'modules\Refresh\to-bios.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\2 Refresh\4 To Bios.ps1'
$migrationPath = Join-Path $ProjectRoot 'docs\migrations\to-bios.md'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'

foreach ($path in @($configPath, $modulePath, $sourcePath, $migrationPath, $actionPlanPath, $artifactPath, $productionAllowlistPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required To BIOS parity file was not found: $path"
}

$expectedSourceHash = 'A8371B42B235A6AC1F9661D96B430BEC0E4CAB6D9DE3CBD1461A02572220CA0C'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "To BIOS Ultimate source hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."

$sourceText = Get-Content -Raw -LiteralPath $sourcePath
foreach ($needle in @(
    '# SCRIPT RUN AS ADMIN',
    'Write-Host "Press Enter to Restart to BIOS"',
    'Pause',
    'cmd /c C:\Windows\System32\shutdown.exe /r /fw /t 0'
)) {
    Assert-BoostLabTextContains -Text $sourceText -Needle $needle -Description 'To BIOS Ultimate source behavior'
}

$orderedToolIdsBeforeToBios = @()
$foundToBiosInOrder = $false
foreach ($stage in @($executionOrder.Stages)) {
    foreach ($tool in @($stage.Tools)) {
        $toolId = [string]$tool.ToolId
        if ($toolId -eq 'to-bios') {
            $foundToBiosInOrder = $true
            break
        }

        $orderedToolIdsBeforeToBios += $toolId
    }

    if ($foundToBiosInOrder) {
        break
    }
}
Assert-BoostLabCondition $foundToBiosInOrder 'To BIOS was not found in the ordered parity execution baseline.'
foreach ($priorToolId in $orderedToolIdsBeforeToBios) {
    $priorRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq $priorToolId }) | Select-Object -First 1
    Assert-BoostLabCondition ($null -ne $priorRecord) "Missing prior parity record: $priorToolId"
    Assert-BoostLabCondition (Test-BoostLabParityRecordFinal -Record $priorRecord) "Prior ordered parity target must already be final before To BIOS: $priorToolId"
}

$toBiosRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'to-bios' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $toBiosRecord) 'To BIOS parity record was not found.'
Assert-BoostLabCondition ([string]$toBiosRecord.ImplementationLevel -eq 'NearParityControlled') 'To BIOS must remain NearParityControlled.'
Assert-BoostLabCondition ([string]$toBiosRecord.UltimateParity -eq 'Partial') 'To BIOS accepted near parity must not be counted as full parity.'
Assert-BoostLabCondition (-not [bool]$toBiosRecord.YazanFinalException) 'To BIOS must not use a YazanFinalException.'
Assert-BoostLabCondition ([bool]$toBiosRecord.YazanAcceptedNearParity) 'To BIOS must be marked YazanAcceptedNearParity.'
Assert-BoostLabCondition ([string]$toBiosRecord.FinalProgressStatus -eq 'DoneYazanAcceptedNearParity') 'To BIOS final progress status mismatch.'
Assert-BoostLabTextContains -Text ([string]$toBiosRecord.GapSummary) -Needle 'GUI confirmation' -Description 'To BIOS parity gap summary'
Assert-BoostLabTextContains -Text ([string]$toBiosRecord.GapSummary) -Needle 'restart-to-firmware' -Description 'To BIOS parity gap summary'
Assert-BoostLabCondition (Test-BoostLabParityRecordFinal -Record $toBiosRecord) 'To BIOS accepted near-parity record must be treated as final by ordered parity calculation.'

$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ($null -ne $nextTarget) 'Next ordered parity target was not found.'
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq 'graphics-configuration-center') 'First ordered pending parity target must advance past Visual C++ near-parity acceptance.'

$config = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })
$tool = @($allTools | Where-Object { $_.Id -eq 'to-bios' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $tool) 'To BIOS tool metadata was not found.'
Assert-BoostLabCondition ((@($tool.Actions) -join ',') -eq 'Analyze,Open') 'To BIOS must expose only Analyze and Open.'
Assert-BoostLabCondition ([string]$tool.Type -eq 'assistant') 'To BIOS type must remain assistant.'
Assert-BoostLabCondition ([string]$tool.RiskLevel -eq 'high') 'To BIOS risk level must remain high.'
$capabilities = $tool.Capabilities
foreach ($trueCapability in @('RequiresAdmin', 'CanReboot', 'NeedsExplicitConfirmation')) {
    Assert-BoostLabCondition ([bool]$capabilities[$trueCapability]) "To BIOS capability must be true: $trueCapability"
}
foreach ($falseCapability in @(
    'RequiresInternet',
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
    'SupportsRestore'
)) {
    Assert-BoostLabCondition (-not [bool]$capabilities[$falseCapability]) "To BIOS capability must remain false: $falseCapability"
}

$moduleText = Get-Content -Raw -LiteralPath $modulePath
foreach ($needle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Open'')',
    '$script:BoostLabFirmwareConfirmationText',
    '$commandProcessorPath = Join-Path $env:SystemRoot ''System32\cmd.exe''',
    '$shutdownPath = Join-Path $env:SystemRoot ''System32\shutdown.exe''',
    '$firmwareRestartCommand = "`"$shutdownPath`" /r /fw /t 0"',
    '& $commandProcessorPath @firmwareRestartArguments',
    'Windows accepted the source-defined restart-to-firmware command.'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'To BIOS module behavior'
}
foreach ($forbiddenText in @(
    'Invoke-WebRequest',
    'Invoke-RestMethod',
    'Start-BitsTransfer',
    'Set-ItemProperty',
    'New-ItemProperty',
    'Remove-ItemProperty',
    'bcdedit',
    'Restart-Computer',
    'pnputil',
    'source-ultimate'
)) {
    Assert-BoostLabCondition (-not $moduleText.Contains($forbiddenText)) "To BIOS module contains forbidden behavior: $forbiddenText"
}

$module = Import-Module -Name $modulePath -Force -PassThru -Prefix 'ToBiosParity' -Scope Local -ErrorAction Stop
try {
    $toolInfo = Get-ToBiosParityBoostLabToolInfo
    Assert-BoostLabCondition ([string]$toolInfo.Id -eq 'to-bios') 'To BIOS module info Id mismatch.'
    Assert-BoostLabCondition ((@($toolInfo.ImplementedActions) -join '|') -eq 'Analyze|Open') 'To BIOS implemented actions mismatch.'
    Assert-BoostLabCondition ((@($toolInfo.ConfirmationRequiredActions) -join '|') -eq 'Open') 'To BIOS Open must remain confirmation-gated.'
    Assert-BoostLabCondition ([string]$toolInfo.ConfirmationText -match 'restart immediately') 'To BIOS confirmation text must warn about immediate restart.'
    Assert-BoostLabCondition ([string]$toolInfo.ConfirmationText -match 'BIOS/UEFI') 'To BIOS confirmation text must mention BIOS/UEFI.'

    $analysis = Invoke-ToBiosParityBoostLabToolAction -ActionName 'Analyze'
    Assert-BoostLabCondition ([bool]$analysis.Success) 'To BIOS Analyze should succeed.'
    Assert-BoostLabCondition (-not [bool]$analysis.RestartRequired) 'To BIOS Analyze must not request a restart.'
    Assert-BoostLabCondition ([string]$analysis.CommandStatus -eq 'Read only') 'To BIOS Analyze must be read-only.'
    Assert-BoostLabCondition ([string]$analysis.Data.ApprovedCommand -eq 'cmd /c C:\Windows\System32\shutdown.exe /r /fw /t 0') 'To BIOS Analyze must report the source-equivalent approved command.'

    $cancelledOpen = Invoke-ToBiosParityBoostLabToolAction -ActionName 'Open'
    Assert-BoostLabCondition (-not [bool]$cancelledOpen.Success) 'To BIOS declined Open must not succeed.'
    Assert-BoostLabCondition ([bool]$cancelledOpen.Cancelled) 'To BIOS declined Open must be marked cancelled.'
    Assert-BoostLabCondition (-not [bool]$cancelledOpen.RestartRequired) 'To BIOS declined Open must not request a restart.'

    $default = Restore-ToBiosParityBoostLabToolDefault
    Assert-BoostLabCondition (-not [bool]$default.Success) 'To BIOS Default must remain unavailable.'
    Assert-BoostLabCondition ([string]$default.Action -eq 'Default') 'To BIOS Default unavailable result must be truthful.'
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
}

$actionPlanText = Get-Content -Raw -LiteralPath $actionPlanPath
Assert-BoostLabTextContains -Text $actionPlanText -Needle 'This PC will restart immediately and attempt to enter BIOS/UEFI firmware settings.' -Description 'To BIOS action plan confirmation'

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    $openPlan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Open'
    Assert-BoostLabCondition ([bool]$openPlan.NeedsExplicitConfirmation) 'To BIOS Open plan must require explicit confirmation.'
    Assert-BoostLabCondition ([bool]$openPlan.CanReboot) 'To BIOS Open plan must report reboot capability.'
    Assert-BoostLabCondition ([string]$openPlan.ConfirmationMessage -match 'restart immediately') 'To BIOS Open plan must warn about immediate restart.'
    Assert-BoostLabCondition ([string]$openPlan.ConfirmationMessage -match 'BIOS/UEFI') 'To BIOS Open plan must mention BIOS/UEFI.'
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$migrationText = Get-Content -Raw -LiteralPath $migrationPath
foreach ($needle in @(
    'source-ultimate/2 Refresh/4 To Bios.ps1',
    $expectedSourceHash,
    'cmd /c C:\Windows\System32\shutdown.exe /r /fw /t 0',
    'Ultimate''s console `Pause` is replaced by an explicit GUI confirmation',
    'No Default or Restore action exists.'
)) {
    Assert-BoostLabTextContains -Text $migrationText -Needle $needle -Description 'To BIOS migration record'
}

$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
Assert-BoostLabCondition ([int]$categoryCounts['ParityImplemented'] -eq 15) 'Ultimate parity implemented count changed unexpectedly.'
Assert-BoostLabCondition ([int]$categoryCounts['NearParityControlled'] -eq 25) 'NearParityControlled count changed unexpectedly.'
Assert-BoostLabCondition ([int]$categoryCounts['ControlledSubset'] -eq 4) 'ControlledSubset count changed unexpectedly.'
Assert-BoostLabCondition ([int]$categoryCounts['ManualHandoffOnly'] -eq 1) 'ManualHandoffOnly count should match the current parity baseline.'
Assert-BoostLabCondition ([int]$inventorySnapshot.ActiveTools -eq 55) 'Active tool count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.ImplementedTools -eq 45) 'Runtime implemented tool count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.DeferredPlaceholders -eq 10) 'Deferred placeholder count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.SourcePromotedMirrorFiles -eq 7) 'Source-promoted mirror file count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.RemainingSourcePromotedIntakeCandidates -eq 0) 'Remaining source-promoted intake count changed.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.RuntimeImplementedTools -ne [int]$parityBaseline.Counts.UltimateParityImplemented) 'Runtime implemented and Ultimate parity counts must remain separate.'

$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPath
$productionPolicy = Import-PowerShellDataFile -LiteralPath $productionAllowlistPath
if ($artifactPolicy.ContainsKey('Artifacts')) {
    Assert-BoostLabCondition (@($artifactPolicy.Artifacts).Count -eq 0) 'Artifact provenance approvals must remain empty.'
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
    Test = 'ToBiosOrderedParityAcceptance'
    SourcePath = 'source-ultimate/2 Refresh/4 To Bios.ps1'
    SourceHash = $actualSourceHash
    RuntimeImplementedTools = $inventorySnapshot.ImplementedTools
    UltimateParityImplemented = $parityBaseline.Counts.UltimateParityImplemented
    NearParityControlled = $parityBaseline.Counts.NearParityControlled
    ToBiosFinalProgressStatus = $toBiosRecord.FinalProgressStatus
    YazanAcceptedNearParity = [bool]$toBiosRecord.YazanAcceptedNearParity
    RestartCommandExecuted = $false
    NextOrderedPendingTarget = $nextTarget.ToolId
    SourceUltimateUnchanged = $true
    Message = 'To BIOS source-equivalent firmware restart capability is accepted as near parity with safer GUI confirmation.'
}

