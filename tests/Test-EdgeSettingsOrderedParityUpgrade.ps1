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
        throw 'Unable to determine the Edge Settings ordered parity validator path.'
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
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [string]$Needle,

        [Parameter(Mandatory)]
        [string]$Description
    )

    Assert-BoostLabCondition ($Text.Contains($Needle)) "$Description is missing expected text: $Needle"
}

$inventoryAssertion = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
$inventoryBaseline = $inventoryAssertion.Baseline
$inventorySnapshot = $inventoryAssertion.Snapshot

$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$firstTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder

Assert-BoostLabCondition ($null -ne $firstTarget) 'Ordered parity must identify a first pending target.'
Assert-BoostLabCondition ([string]$firstTarget.ToolId -eq 'edge-settings') 'Edge Settings must be the current ordered parity target.'

$edgeRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'edge-settings' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $edgeRecord) 'Edge Settings parity record is missing.'
Assert-BoostLabCondition ([int]$edgeRecord.StageOrder -eq 3) 'Edge Settings must remain Setup stage order 3.'
Assert-BoostLabCondition ([int]$edgeRecord.ToolOrder -eq 7) 'Edge Settings must remain Setup tool order 7.'
Assert-BoostLabCondition ([string]$edgeRecord.RuntimeStatus -eq 'DeferredPlaceholder') 'Edge Settings must remain a deferred placeholder until Yazan decides the full source scope.'
Assert-BoostLabCondition ([string]$edgeRecord.ImplementationLevel -eq 'DeferredForParityWork') 'Edge Settings must not be falsely marked implemented.'
Assert-BoostLabCondition ([string]$edgeRecord.UltimateParity -eq 'No') 'Edge Settings must not claim Ultimate parity.'
Assert-BoostLabCondition ([string]$edgeRecord.FinalProgressStatus -eq 'DeferredNeedsYazanDecision') 'Edge Settings must record the Phase 117 Yazan decision gate.'
Assert-BoostLabCondition (-not [bool]$edgeRecord.YazanAcceptedNearParity) 'Edge Settings must not be accepted near parity.'
Assert-BoostLabCondition (-not [bool]$edgeRecord.YazanFinalException) 'Edge Settings must not be recorded as a final exception.'

foreach ($requiredBlocker in @(
    'dynamic Active Setup',
    'RunOnce',
    'Edge service',
    'scheduled task',
    'BHO',
    'broad Edge policy deletion',
    'msedge launch/stop',
    'mutable GitHub edge.exe repair download/installer',
    'policy-only or Open-only behavior would weaken Ultimate'
)) {
    Assert-BoostLabTextContains -Text ([string]$edgeRecord.GapSummary) -Needle $requiredBlocker -Description 'Edge Settings GapSummary'
}
Assert-BoostLabTextContains -Text ([string]$edgeRecord.NextParityAction) -Needle 'Ask Yazan' -Description 'Edge Settings NextParityAction'
Assert-BoostLabTextContains -Text ([string]$edgeRecord.NextParityAction) -Needle 'full source workflow' -Description 'Edge Settings NextParityAction'

$sourcePath = Join-Path $ProjectRoot 'source-ultimate\3 Setup\6 Edge Settings.ps1'
$designPath = Join-Path $ProjectRoot 'docs\tool-designs\edge-settings-scope-design.md'
$modulePath = Join-Path $ProjectRoot 'modules\Setup\edge-settings.psm1'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$processPolicyPath = Join-Path $ProjectRoot 'config\ProcessHandlingPolicy.psd1'

foreach ($path in @($sourcePath, $designPath, $modulePath, $stagesPath, $artifactPath, $productionAllowlistPath, $processPolicyPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required Edge Settings parity file is missing: $path"
}

$expectedSourceHash = '342869157930ECF0869A07B4254CB8F174C63648CD329DB3914BAD291CD5FF28'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Edge Settings source hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."

$sourceText = Get-Content -Raw -LiteralPath $sourcePath
$designText = Get-Content -Raw -LiteralPath $designPath
$moduleText = Get-Content -Raw -LiteralPath $modulePath

foreach ($sourceNeedle in @(
    'Write-Host "1. Edge Settings: Optimize (Recommended)"',
    'Write-Host "2. Edge Settings: Default`n"',
    'HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist',
    'HardwareAccelerationModeEnabled',
    'BackgroundModeEnabled',
    'StartupBoostEnabled',
    'HKLM:\Software\Microsoft\Active Setup\Installed Components',
    '$val -like "*Edge*"',
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
    '$_ -like "*msedge*"',
    "Get-Service | Where-Object { `$_.Name -match 'Edge' }",
    'sc stop',
    'sc delete',
    "Get-ScheduledTask | Where-Object { `$_.TaskName -like '*Edge*' }",
    'Unregister-ScheduledTask',
    'Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}',
    'Stop-Process -Name "msedge"',
    'Start-Process "msedge.exe"',
    'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe',
    'Start-Process "$env:SystemRoot\Temp\edge.exe"'
)) {
    Assert-BoostLabTextContains -Text $sourceText -Needle $sourceNeedle -Description 'Edge Settings Ultimate source behavior'
}

foreach ($designNeedle in @(
    'Phase 117 ordered parity review keeps Edge Settings blocked as',
    '`DeferredNeedsYazanDecision`',
    'The exact Yazan decision required before ordered parity can continue',
    'full source workflow',
    'final Edge Settings scope exception',
    'Do not implement a policy-only subset',
    'policy-only implementation would weaken Ultimate behavior',
    'mutable GitHub raw URL remains refused'
)) {
    Assert-BoostLabTextContains -Text $designText -Needle $designNeedle -Description 'Edge Settings design decision'
}

Assert-BoostLabCondition ($moduleText.Contains('ToolModule.Placeholder.ps1')) 'Edge Settings module must remain a placeholder for the Phase 117 decision gate.'
Assert-BoostLabCondition (-not ($moduleText -match 'reg add|reg delete|Start-Process|IWR|Invoke-WebRequest|Stop-Process|Get-Service|sc stop|sc delete|Get-ScheduledTask|Unregister-ScheduledTask|Remove-Item|Remove-ItemProperty')) 'Edge Settings placeholder must not contain host-mutating source commands.'

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$edgeTool = @($stages.Stages | ForEach-Object { $_.Tools } | Where-Object { [string]$_.Id -eq 'edge-settings' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $edgeTool) 'Edge Settings must remain in the active catalog.'
Assert-BoostLabCondition ([string]$edgeTool.Stage -eq 'Setup') 'Edge Settings must remain in Setup.'
Assert-BoostLabCondition ([int]$edgeTool.Order -eq 7) 'Edge Settings catalog order must remain canonical Setup order 7.'

$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPath
$productionAllowlist = Import-PowerShellDataFile -LiteralPath $productionAllowlistPath
$processPolicy = Import-PowerShellDataFile -LiteralPath $processPolicyPath
Assert-BoostLabCondition (@($artifactPolicy.Artifacts).Count -eq 0) 'No Edge Settings artifact provenance approval may be added in this decision phase.'
Assert-BoostLabCondition (@($productionAllowlist.ProductionAllowlistProposals).Count -eq 0) 'No Edge Settings production allowlist proposal may be added in this decision phase.'
Assert-BoostLabCondition (@($processPolicy.ProcessHandlingScopes).Count -eq 0) 'No Edge Settings production process scope may be approved in this decision phase.'
Assert-BoostLabCondition (@($processPolicy.ApprovedProcessTargets).Count -eq 0) 'No Edge Settings production process target may be approved in this decision phase.'

Assert-BoostLabCondition ([int]$inventorySnapshot.ActiveTools -eq [int]$inventoryBaseline.ActiveTools) 'Active tool count changed unexpectedly.'
Assert-BoostLabCondition ([int]$inventorySnapshot.ImplementedTools -eq [int]$inventoryBaseline.ImplementedTools) 'Runtime implemented count changed unexpectedly.'
Assert-BoostLabCondition ([int]$inventorySnapshot.DeferredPlaceholders -eq [int]$inventoryBaseline.DeferredPlaceholders) 'Deferred placeholder count changed unexpectedly.'
Assert-BoostLabCondition ([int]$inventoryBaseline.ActiveTools -eq 55) 'Active tools baseline must remain 55.'
Assert-BoostLabCondition ([int]$inventoryBaseline.ImplementedTools -eq 44) 'Runtime implemented tools baseline must remain 44.'
Assert-BoostLabCondition ([int]$inventoryBaseline.DeferredPlaceholders -eq 11) 'Deferred placeholder baseline must remain 11.'

$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
        Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
        ForEach-Object {
            $relativePath = $_.FullName.Substring($root.Length + 1).Replace('\', '/')
            $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
            "$relativePath|$hash"
        }
)
$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $sourceManifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n")))
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}
Assert-BoostLabCondition (@($sourceLines).Count -eq 49) 'Legacy source file count changed.'
Assert-BoostLabCondition ($sourceManifestHash -eq '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') 'Legacy source manifest changed.'

foreach ($deletedName in @('Loudness EQ', 'NVME Faster Driver')) {
    $normalizedDeleted = ($deletedName -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()
    $catalogHit = @(
        $stages.Stages |
            ForEach-Object { $_.Tools } |
            Where-Object { (([string]$_.Title -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()) -eq $normalizedDeleted }
    )
    Assert-BoostLabCondition ($catalogHit.Count -eq 0) "Deleted tool returned to active catalog: $deletedName"
}
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }).Count -eq 0) 'NVME Faster Driver source was reintroduced.'
Assert-BoostLabCondition (-not [bool]$parityBaseline.DesignSystemReady) 'Design System readiness must remain false.'

$targetAfterDecision = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ([string]$targetAfterDecision.ToolId -eq 'edge-settings') 'Ordered parity cursor must remain on Edge Settings until Yazan decides the blocker.'

[pscustomobject]@{
    Test                              = 'EdgeSettingsOrderedParityUpgrade'
    ToolId                            = 'edge-settings'
    SourceHash                        = $actualSourceHash
    RuntimeImplementedTools           = $inventorySnapshot.ImplementedTools
    DeferredPlaceholders              = $inventorySnapshot.DeferredPlaceholders
    FinalProgressStatus               = $edgeRecord.FinalProgressStatus
    YazanAcceptedNearParity           = [bool]$edgeRecord.YazanAcceptedNearParity
    YazanFinalException               = [bool]$edgeRecord.YazanFinalException
    FirstOrderedNonFinalParityTarget  = $targetAfterDecision.ToolId
    ProductionArtifactApprovals       = @($artifactPolicy.Artifacts).Count
    ProductionAllowlistProposals      = @($productionAllowlist.ProductionAllowlistProposals).Count
    SourceUltimateUnchanged           = $true
    DeletedToolsRemainDeleted         = $true
    Message                           = 'Edge Settings ordered parity review records a concrete Yazan decision gate without implementing a weakened subset.'
}
