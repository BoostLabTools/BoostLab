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
$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder

$edgeRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'edge-settings' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $edgeRecord) 'Edge Settings parity record is missing.'
Assert-BoostLabCondition ([int]$edgeRecord.StageOrder -eq 3) 'Edge Settings must remain Setup stage order 3.'
Assert-BoostLabCondition ([int]$edgeRecord.ToolOrder -eq 7) 'Edge Settings must remain Setup tool order 7.'
Assert-BoostLabCondition ([string]$edgeRecord.RuntimeStatus -eq 'RuntimeImplemented') 'Edge Settings must be runtime implemented after Phase 118.'
Assert-BoostLabCondition ([string]$edgeRecord.ImplementationLevel -eq 'NearParityControlled') 'Edge Settings must be NearParityControlled after Phase 118.'
Assert-BoostLabCondition ([string]$edgeRecord.FinalProgressStatus -eq 'DoneYazanAcceptedNearParity') 'Edge Settings must be accepted near parity after Phase 118.'
Assert-BoostLabCondition ([bool]$edgeRecord.YazanAcceptedNearParity) 'Edge Settings must set YazanAcceptedNearParity.'
Assert-BoostLabCondition (-not [bool]$edgeRecord.YazanFinalException) 'Edge Settings must not set YazanFinalException.'
Assert-BoostLabTextContains -Text ([string]$edgeRecord.GapSummary) -Needle 'source-equivalent Edge Settings behavior' -Description 'Edge Settings GapSummary'
Assert-BoostLabTextContains -Text ([string]$edgeRecord.NextParityAction) -Needle 'Skip; accepted near-parity.' -Description 'Edge Settings NextParityAction'

Assert-BoostLabCondition ($null -ne $nextTarget) 'Ordered parity must identify a next pending target.'
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq 'directx') 'Ordered parity cursor must advance past Msi Mode near-parity acceptance.'

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

$designText = Get-Content -Raw -LiteralPath $designPath
$moduleText = Get-Content -Raw -LiteralPath $modulePath
Assert-BoostLabTextContains -Text $designText -Needle 'Phase 118 implements Yazan''s option 1' -Description 'Edge Settings design decision'
Assert-BoostLabTextContains -Text $designText -Needle 'not policy-only and is not Open-only' -Description 'Edge Settings design decision'
Assert-BoostLabTextContains -Text $designText -Needle 'Restore remains unavailable' -Description 'Edge Settings design decision'
Assert-BoostLabCondition (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) 'Edge Settings module must no longer be a placeholder after Phase 118.'
Assert-BoostLabTextContains -Text $moduleText -Needle 'Invoke-BoostLabEdgeSettingsApply' -Description 'Edge Settings module'
Assert-BoostLabTextContains -Text $moduleText -Needle 'Invoke-BoostLabEdgeSettingsDefault' -Description 'Edge Settings module'
Assert-BoostLabTextContains -Text $moduleText -Needle 'RestoreUnavailable' -Description 'Edge Settings module'

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$edgeTool = @($stages.Stages | ForEach-Object { $_.Tools } | Where-Object { [string]$_.Id -eq 'edge-settings' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $edgeTool) 'Edge Settings must remain in the active catalog.'
Assert-BoostLabCondition ([string]$edgeTool.Stage -eq 'Setup') 'Edge Settings must remain in Setup.'
Assert-BoostLabCondition ([int]$edgeTool.Order -eq 7) 'Edge Settings catalog order must remain canonical Setup order 7.'
Assert-BoostLabCondition ((@($edgeTool.Actions) -join ',') -eq 'Analyze,Apply,Default,Restore') 'Edge Settings catalog actions must match Phase 118.'

$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPath
$productionAllowlist = Import-PowerShellDataFile -LiteralPath $productionAllowlistPath
$processPolicy = Import-PowerShellDataFile -LiteralPath $processPolicyPath
Assert-BoostLabCondition (@($artifactPolicy.Artifacts).Count -eq 0) 'No Edge Settings artifact provenance approval may be added in Phase 118.'
Assert-BoostLabCondition (@($productionAllowlist.ProductionAllowlistProposals).Count -eq 0) 'No Edge Settings production allowlist proposal may be added in Phase 118.'
Assert-BoostLabCondition (@($processPolicy.ProcessHandlingScopes).Count -eq 0) 'No reusable Edge Settings production process scope may be approved in Phase 118.'
Assert-BoostLabCondition (@($processPolicy.ApprovedProcessTargets).Count -eq 0) 'No reusable Edge Settings production process target may be approved in Phase 118.'

Assert-BoostLabCondition ([int]$inventorySnapshot.ActiveTools -eq [int]$inventoryBaseline.ActiveTools) 'Active tool count changed unexpectedly.'
Assert-BoostLabCondition ([int]$inventorySnapshot.ImplementedTools -eq [int]$inventoryBaseline.ImplementedTools) 'Runtime implemented count changed unexpectedly.'
Assert-BoostLabCondition ([int]$inventorySnapshot.DeferredPlaceholders -eq [int]$inventoryBaseline.DeferredPlaceholders) 'Deferred placeholder count changed unexpectedly.'
Assert-BoostLabCondition ([int]$inventoryBaseline.ActiveTools -eq 55) 'Active tools baseline must remain 55.'
Assert-BoostLabCondition ([int]$inventoryBaseline.ImplementedTools -eq 45) 'Runtime implemented tools baseline must be 45 after Phase 118.'
Assert-BoostLabCondition ([int]$inventoryBaseline.DeferredPlaceholders -eq 10) 'Deferred placeholder baseline must be 10 after Phase 118.'

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
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }).Count -eq 0) 'NVME Faster Driver source was reintroduced.'
Assert-BoostLabCondition (-not [bool]$parityBaseline.DesignSystemReady) 'Design System readiness must remain false.'

[pscustomobject]@{
    Test                             = 'EdgeSettingsOrderedParityUpgrade'
    ToolId                           = 'edge-settings'
    SourceHash                       = $actualSourceHash
    RuntimeImplementedTools          = $inventorySnapshot.ImplementedTools
    DeferredPlaceholders             = $inventorySnapshot.DeferredPlaceholders
    FinalProgressStatus              = $edgeRecord.FinalProgressStatus
    YazanAcceptedNearParity          = [bool]$edgeRecord.YazanAcceptedNearParity
    YazanFinalException              = [bool]$edgeRecord.YazanFinalException
    NextOrderedNonFinalParityTarget  = $nextTarget.ToolId
    ProductionArtifactApprovals      = @($artifactPolicy.Artifacts).Count
    ProductionAllowlistProposals     = @($productionAllowlist.ProductionAllowlistProposals).Count
    SourceUltimateUnchanged          = $true
    DeletedToolsRemainDeleted        = $true
    Message                          = 'Edge Settings ordered parity decision gate is resolved by Phase 118 near-parity implementation.'
}
