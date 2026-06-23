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
        throw 'Unable to determine the canonical Yazan tool order validator path.'
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

function Get-BoostLabCanonicalYazanOrder {
    return @(
        @{
            Name = 'Check'
            Tools = @(
                @{ Id = 'bios-information'; Title = 'BIOS Information' }
                @{ Id = 'bios-settings'; Title = 'BIOS Settings' }
            )
        }
        @{
            Name = 'Refresh'
            Tools = @(
                @{ Id = 'reinstall'; Title = 'Reinstall' }
                @{ Id = 'unattended'; Title = 'Unattended' }
                @{ Id = 'updates-drivers-block'; Title = 'Updates Drivers Block' }
                @{ Id = 'to-bios'; Title = 'To BIOS' }
            )
        }
        @{
            Name = 'Setup'
            Tools = @(
                @{ Id = 'bitlocker'; Title = 'BitLocker' }
                @{ Id = 'convert-home-to-pro'; Title = 'Convert Home To Pro' }
                @{ Id = 'memory-compression'; Title = 'Memory Compression' }
                @{ Id = 'date-language-region-time'; Title = 'Date Language Region Time' }
                @{ Id = 'startup-apps-settings'; Title = 'Startup Apps (Settings)' }
                @{ Id = 'startup-apps-task-manager'; Title = 'Startup Apps (Task Manager)' }
                @{ Id = 'background-apps'; Title = 'Background Apps' }
                @{ Id = 'edge-settings'; Title = 'Edge Settings' }
                @{ Id = 'store-settings'; Title = 'Store Settings' }
                @{ Id = 'updates-pause'; Title = 'Updates Pause' }
            )
        }
        @{
            Name = 'Installers'
            Tools = @(
                @{ Id = 'installers'; Title = 'Installers' }
            )
        }
        @{
            Name = 'Graphics'
            Tools = @(
                @{ Id = 'driver-clean'; Title = 'Driver Clean' }
                @{ Id = 'driver-install-debloat-settings'; Title = 'Driver Install Debloat & Settings' }
                @{ Id = 'driver-install-latest'; Title = 'Driver Install Latest' }
                @{ Id = 'nvidia-settings'; Title = 'Nvidia Settings' }
                @{ Id = 'hdcp'; Title = 'HDCP' }
                @{ Id = 'p0-state'; Title = 'P0 State' }
                @{ Id = 'msi-mode'; Title = 'Msi Mode' }
                @{ Id = 'directx'; Title = 'DirectX' }
                @{ Id = 'visual-cpp'; Title = 'Visual C++' }
                @{ Id = 'graphics-configuration-center'; Title = 'Graphics Configuration Center' }
            )
        }
        @{
            Name = 'Windows'
            Tools = @(
                @{ Id = 'start-menu-taskbar'; Title = 'Start Menu Taskbar' }
                @{ Id = 'start-menu-layout'; Title = 'Start Menu Layout' }
                @{ Id = 'context-menu'; Title = 'Context Menu' }
                @{ Id = 'theme-black'; Title = 'Theme Black' }
                @{ Id = 'signout-lockscreen-wallpaper-black'; Title = 'Signout LockScreen Wallpaper Black' }
                @{ Id = 'user-account-pictures-black'; Title = 'User Account Pictures Black' }
                @{ Id = 'widgets'; Title = 'Widgets' }
                @{ Id = 'copilot'; Title = 'Copilot' }
                @{ Id = 'game-mode'; Title = 'GameMode' }
                @{ Id = 'pointer-precision'; Title = 'Pointer Precision' }
                @{ Id = 'bloatware'; Title = 'Bloatware' }
                @{ Id = 'game-bar'; Title = 'GameBar' }
                @{ Id = 'edge-webview'; Title = 'Edge & WebView' }
                @{ Id = 'notepad-settings'; Title = 'Notepad Settings' }
                @{ Id = 'control-panel-settings'; Title = 'Control Panel Settings' }
                @{ Id = 'sound'; Title = 'Sound' }
                @{ Id = 'device-manager-power-savings-wake'; Title = 'Device Manager Power Savings & Wake' }
                @{ Id = 'network-adapter-power-savings-wake'; Title = 'Network Adapter Power Savings & Wake' }
                @{ Id = 'write-cache-buffer-flushing'; Title = 'Write Cache Buffer Flushing' }
                @{ Id = 'power-plan'; Title = 'Power Plan' }
                @{ Id = 'cleanup'; Title = 'Cleanup' }
                @{ Id = 'restore-point'; Title = 'Restore Point' }
            )
        }
        @{
            Name = 'Advanced'
            Tools = @(
                @{ Id = 'spectre-meltdown-assistant'; Title = 'Spectre / Meltdown Assistant' }
                @{ Id = 'mmagent-assistant'; Title = 'MMAgent Assistant' }
                @{ Id = 'services-optimizer'; Title = 'Services Optimizer' }
                @{ Id = 'timer-resolution-assistant'; Title = 'Timer Resolution Assistant' }
                @{ Id = 'defender-optimize-assistant'; Title = 'Defender Optimize Assistant' }
            )
        }
    )
}

$inventoryAssertion = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
$inventoryBaseline = $inventoryAssertion.Baseline
$inventorySnapshot = $inventoryAssertion.Snapshot

$stages = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\Stages.psd1')
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$canonical = @(Get-BoostLabCanonicalYazanOrder)

Assert-BoostLabCondition (-not [bool]$parityBaseline.DesignSystemReady) 'Design System readiness must remain false.'

$actualStageNames = @($stages.Stages | ForEach-Object { [string]$_.Name })
$canonicalStageNames = @($canonical | ForEach-Object { [string]$_.Name })
Assert-BoostLabCondition (($actualStageNames -join '|') -eq ($canonicalStageNames -join '|')) 'config/Stages.psd1 stage order must match Yazan canonical order.'
Assert-BoostLabCondition ((@($executionOrder.StageOrder) -join '|') -eq ($canonicalStageNames -join '|')) 'UltimateParityExecutionOrder stage order must match Yazan canonical order.'

$parityById = @{}
foreach ($record in @($parityBaseline.Tools)) {
    $parityById[[string]$record.ToolId] = $record
}

$stagesFlat = @()
$orderFlat = @()
for ($stageIndex = 0; $stageIndex -lt $canonical.Count; $stageIndex++) {
    $canonicalStage = $canonical[$stageIndex]
    $stageOrder = $stageIndex + 1
    $stage = $stages.Stages[$stageIndex]
    $orderStage = $executionOrder.Stages[$stageIndex]

    Assert-BoostLabCondition ([int]$stage.Order -eq $stageOrder) "Stage order mismatch for $($canonicalStage.Name)."
    Assert-BoostLabCondition ([string]$stage.Name -eq [string]$canonicalStage.Name) "Stage name mismatch for $($canonicalStage.Name)."
    Assert-BoostLabCondition ([int]$orderStage.Order -eq $stageOrder) "Ordered parity stage order mismatch for $($canonicalStage.Name)."
    Assert-BoostLabCondition ([string]$orderStage.Name -eq [string]$canonicalStage.Name) "Ordered parity stage name mismatch for $($canonicalStage.Name)."

    $canonicalTools = @($canonicalStage.Tools)
    $stageTools = @($stage.Tools)
    $orderTools = @($orderStage.Tools)
    Assert-BoostLabCondition ($stageTools.Count -eq $canonicalTools.Count) "Tool count mismatch in runtime stage $($canonicalStage.Name)."
    Assert-BoostLabCondition ($orderTools.Count -eq $canonicalTools.Count) "Tool count mismatch in ordered parity stage $($canonicalStage.Name)."

    for ($toolIndex = 0; $toolIndex -lt $canonicalTools.Count; $toolIndex++) {
        $toolOrder = $toolIndex + 1
        $expected = $canonicalTools[$toolIndex]
        $runtimeTool = $stageTools[$toolIndex]
        $orderedTool = $orderTools[$toolIndex]

        Assert-BoostLabCondition ([string]$runtimeTool.Id -eq [string]$expected.Id) "Runtime tool order mismatch at $($canonicalStage.Name) #$toolOrder."
        Assert-BoostLabCondition ([string]$runtimeTool.Title -eq [string]$expected.Title) "Runtime tool title mismatch for $($expected.Id)."
        Assert-BoostLabCondition ([int]$runtimeTool.Order -eq $toolOrder) "Runtime tool order field mismatch for $($expected.Id)."

        Assert-BoostLabCondition ([string]$orderedTool.ToolId -eq [string]$expected.Id) "Ordered parity tool mismatch at $($canonicalStage.Name) #$toolOrder."
        Assert-BoostLabCondition ([string]$orderedTool.DisplayName -eq [string]$expected.Title) "Ordered parity display name mismatch for $($expected.Id)."
        Assert-BoostLabCondition ([int]$orderedTool.Order -eq $toolOrder) "Ordered parity tool order field mismatch for $($expected.Id)."

        $record = $parityById[[string]$expected.Id]
        Assert-BoostLabCondition ($null -ne $record) "Missing parity status record for $($expected.Id)."
        Assert-BoostLabCondition ([int]$record.StageOrder -eq $stageOrder) "Parity StageOrder mismatch for $($expected.Id)."
        Assert-BoostLabCondition ([int]$record.ToolOrder -eq $toolOrder) "Parity ToolOrder mismatch for $($expected.Id)."

        $stagesFlat += [string]$runtimeTool.Id
        $orderFlat += [string]$orderedTool.ToolId
    }
}

Assert-BoostLabCondition (($stagesFlat -join '|') -eq ($orderFlat -join '|')) 'Runtime and ordered parity tool order must agree exactly for ordered parity stages.'
Assert-BoostLabCondition ($stagesFlat.Count -eq [int]$inventoryBaseline.ActiveTools) 'Runtime order must include every active tool.'
Assert-BoostLabCondition ([int]$inventorySnapshot.ActiveTools -eq [int]$inventoryBaseline.ActiveTools) 'Active tool count must match the central inventory baseline.'
Assert-BoostLabCondition ([int]$inventorySnapshot.ImplementedTools -eq [int]$inventoryBaseline.ImplementedTools) 'Runtime implemented tool count must remain unchanged.'
Assert-BoostLabCondition ([int]$inventorySnapshot.DeferredPlaceholders -eq [int]$inventoryBaseline.DeferredPlaceholders) 'Deferred placeholder count must remain unchanged.'
Assert-BoostLabCondition ([int]$inventorySnapshot.SourcePromotedMirrorFiles -eq 7) 'Source-promoted mirror count must remain unchanged.'

$windowsStage = @($stages.Stages | Where-Object { $_.Name -eq 'Windows' })[0]
$devicePowerTool = @($windowsStage.Tools | Where-Object { $_.Id -eq 'device-manager-power-savings-wake' })[0]
Assert-BoostLabCondition ([int]$devicePowerTool.Order -eq 17) 'Windows active order must be compressed around deleted Loudness EQ.'
Assert-BoostLabCondition (@($windowsStage.Tools | Where-Object { $_.Title -eq 'Loudness EQ' -or $_.Id -eq 'loudness-eq' }).Count -eq 0) 'Loudness EQ must not return to Windows order.'

$advancedStage = @($stages.Stages | Where-Object { $_.Name -eq 'Advanced' })[0]
Assert-BoostLabCondition ([int]$advancedStage.Order -eq 7) 'Advanced must remain BoostLab Stage 7.'
Assert-BoostLabCondition (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\8 Advanced') -PathType Container) 'Legacy source folder 8 Advanced should remain only as source reference.'

$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ($null -ne $nextTarget) 'Canonical order must produce a next ordered parity target.'
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq [string]$parityBaseline.CurrentOrderedParityTarget) 'Next ordered parity target must match the central parity baseline cursor.'

$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
        Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
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

$sourcePromotedRoot = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate'
Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourcePromotedRoot -Recurse -File).Count -eq 7) 'Source-promoted mirror count changed.'

foreach ($deletedName in @('Loudness EQ', 'NVME Faster Driver', 'Resizable BAR Assistant', 'SMT / HT Assistant')) {
    $normalizedDeleted = ($deletedName -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()
    $catalogHit = @(
        $stagesFlat | Where-Object {
            (($_ -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()) -eq $normalizedDeleted
        }
    )
    Assert-BoostLabCondition ($catalogHit.Count -eq 0) "Deleted tool returned to active order: $deletedName"
}
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }).Count -eq 0) 'NVME Faster Driver source was reintroduced.'

$artifactPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1')
$productionPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1')
if ($artifactPolicy.ContainsKey('Artifacts')) {
    Assert-BoostLabCondition (@($artifactPolicy.Artifacts).Count -eq 0) 'Artifact provenance approvals must remain empty.'
}
if ($productionPolicy.ContainsKey('ProductionAllowlistProposals')) {
    Assert-BoostLabCondition (@($productionPolicy.ProductionAllowlistProposals).Count -eq 0) 'Production allowlist proposals must remain empty.'
}

[pscustomobject]@{
    Test = 'CanonicalYazanToolOrder'
    ActiveTools = $inventorySnapshot.ActiveTools
    RuntimeImplementedTools = $inventorySnapshot.ImplementedTools
    DeferredPlaceholders = $inventorySnapshot.DeferredPlaceholders
    SourcePromotedMirrorFiles = $inventorySnapshot.SourcePromotedMirrorFiles
    FirstOrderedNonFinalParityTarget = $nextTarget.ToolId
    RuntimeOrderSource = 'config/Stages.psd1'
    OrderedParityOrderSource = 'config/UltimateParityExecutionOrder.psd1'
    ParityOrderFieldsValidated = $true
    SourceUltimateUnchanged = $true
    DeletedToolsRemainDeleted = $true
    Message = 'Yazan canonical stage/tool order is applied across runtime order, ordered parity order, and parity baseline order fields.'
}

