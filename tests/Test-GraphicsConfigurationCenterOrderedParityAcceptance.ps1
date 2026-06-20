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
        throw 'Unable to determine the Graphics Configuration Center parity validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}

. (Join-Path $ProjectRoot 'tests\BoostLab.ParityStatusBaseline.ps1')
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

$sourcePath = Join-Path $ProjectRoot 'source-ultimate\5 Graphics\4 Graphics Configuration Center.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Graphics\GraphicsConfigurationCenter.psm1'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$artifactSourcesPath = Join-Path $ProjectRoot 'config\ExternalArtifactSources.psd1'

$expectedHash = '5D8438C6E6CBB7AA87111518F24689095382F72F76DD72E64CBBF3019B9B13CA'
$actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
Assert-BoostLabCondition ($actualHash -eq $expectedHash) "Graphics Configuration Center source checksum mismatch. Expected $expectedHash, found $actualHash."

$sourceText = Get-Content -Raw -LiteralPath $sourcePath
$moduleText = Get-Content -Raw -LiteralPath $modulePath
$executionText = Get-Content -Raw -LiteralPath $executionPath

Assert-BoostLabCondition ($sourceText.Trim() -eq 'Start-Process "ms-settings:display-advancedgraphics"') 'Ultimate Graphics Configuration Center source command changed.'
Assert-BoostLabCondition ($moduleText.Contains('Start-Process "ms-settings:display-advancedgraphics"')) 'BoostLab module must launch the exact source Settings URI.'
Assert-BoostLabCondition (-not ($moduleText -match 'Set-ItemProperty|New-ItemProperty|Remove-ItemProperty|Remove-Item|Invoke-WebRequest|curl|winget|Start-BitsTransfer|Restart-Computer|bcdedit|schtasks|New-ScheduledTask|Get-AppxPackage|Remove-AppxPackage|pnputil|dism')) 'Graphics Configuration Center module must remain an Open-only launcher without mutation/download commands.'
Assert-BoostLabCondition ($executionText.Contains("'graphics-configuration-center' = @{")) 'Execution registry must include Graphics Configuration Center.'
Assert-BoostLabCondition ($executionText.Contains("Actions = @('Open')")) 'Execution registry must expose only Open for Graphics Configuration Center.'

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$tool = @($stages.Stages | ForEach-Object { $_.Tools } | Where-Object { [string]$_.Id -eq 'graphics-configuration-center' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $tool) 'Graphics Configuration Center stage entry is missing.'
Assert-BoostLabCondition ([string]$tool.Type -eq 'assistant') 'Graphics Configuration Center type changed unexpectedly.'
Assert-BoostLabCondition (@($tool.Actions).Count -eq 1 -and [string]@($tool.Actions)[0] -eq 'Open') 'Graphics Configuration Center must expose only Open.'
Assert-BoostLabCondition ([string]$tool.RiskLevel -eq 'low') 'Graphics Configuration Center risk level must remain low.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.RequiresAdmin) 'Graphics Configuration Center must not require admin.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.RequiresInternet) 'Graphics Configuration Center must not require internet.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.CanDownload) 'Graphics Configuration Center must not download.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.CanInstallSoftware) 'Graphics Configuration Center must not install software.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.CanModifyRegistry) 'Graphics Configuration Center must not modify registry.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.CanModifyServices) 'Graphics Configuration Center must not modify services.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.CanModifyDrivers) 'Graphics Configuration Center must not modify drivers.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.CanModifySecurity) 'Graphics Configuration Center must not modify security.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.CanDeleteFiles) 'Graphics Configuration Center must not delete files.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.CanReboot) 'Graphics Configuration Center must not reboot.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.SupportsDefault) 'Graphics Configuration Center must not expose Default.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.SupportsRestore) 'Graphics Configuration Center must not expose Restore.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.NeedsExplicitConfirmation) 'Graphics Configuration Center must not require confirmation for the source launcher.'

Import-Module -Force -Name $modulePath
try {
    $toolInfo = Get-BoostLabToolInfo
    Assert-BoostLabCondition (@($toolInfo.Actions).Count -eq 1 -and [string]@($toolInfo.Actions)[0] -eq 'Open') 'Tool info must expose only Open.'
    Assert-BoostLabCondition (@($toolInfo.ImplementedActions).Count -eq 1 -and [string]@($toolInfo.ImplementedActions)[0] -eq 'Open') 'Implemented actions must expose only Open.'
    Assert-BoostLabCondition (-not [bool]$toolInfo.Capabilities.RequiresAdmin) 'Tool info must not require admin.'
    Assert-BoostLabCondition (-not [bool]$toolInfo.Capabilities.RequiresInternet) 'Tool info must not require internet.'
    Assert-BoostLabCondition (-not [bool]$toolInfo.Capabilities.CanDownload) 'Tool info must not download.'
    Assert-BoostLabCondition (-not [bool]$toolInfo.Capabilities.CanInstallSoftware) 'Tool info must not install software.'
    Assert-BoostLabCondition (-not [bool]$toolInfo.Capabilities.CanModifyRegistry) 'Tool info must not modify registry.'
    Assert-BoostLabCondition (-not [bool]$toolInfo.Capabilities.CanReboot) 'Tool info must not reboot.'
    Assert-BoostLabCondition (-not [bool]$toolInfo.Capabilities.SupportsDefault) 'Tool info must not expose Default.'
    Assert-BoostLabCondition (-not [bool]$toolInfo.Capabilities.SupportsRestore) 'Tool info must not expose Restore.'
}
finally {
    Remove-Module -Name GraphicsConfigurationCenter -Force -ErrorAction SilentlyContinue
}

$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$inventory = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted

$record = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'graphics-configuration-center' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $record) 'Graphics Configuration Center parity record is missing.'
Assert-BoostLabCondition ([string]$record.RuntimeStatus -eq 'RuntimeImplemented') 'Graphics Configuration Center runtime status changed.'
Assert-BoostLabCondition ([string]$record.ImplementationLevel -eq 'ParityImplemented') 'Graphics Configuration Center must be marked ParityImplemented.'
Assert-BoostLabCondition ([string]$record.UltimateParity -eq 'Yes') 'Graphics Configuration Center must be marked UltimateParity Yes.'
Assert-BoostLabCondition (-not [bool]$record.YazanFinalException) 'Graphics Configuration Center must not need a Yazan final exception.'
Assert-BoostLabCondition ([string]$record.NextParityAction -eq 'No parity work required.') 'Graphics Configuration Center next parity action must be closed.'

$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
Assert-BoostLabCondition ([int]$categoryCounts['ParityImplemented'] -eq [int]$parityBaseline.Counts.UltimateParityImplemented) 'ParityImplemented count mismatch.'
Assert-BoostLabCondition ([int]$categoryCounts['ControlledSubset'] -eq [int]$parityBaseline.Counts.ControlledSubset) 'ControlledSubset count mismatch.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.UltimateParityImplemented -eq [int]$categoryCounts['ParityImplemented']) 'Ultimate parity implemented baseline count must match the current parity records.'
Assert-BoostLabCondition ([int]$parityBaseline.Counts.ControlledSubset -eq 3) 'ControlledSubset count must decrease to 3.'
Assert-BoostLabCondition ([int]$inventory.Snapshot.ActiveTools -eq 55) 'Active tool count changed.'
Assert-BoostLabCondition ([int]$inventory.Snapshot.ImplementedTools -eq [int]$inventory.Baseline.ImplementedTools) 'Runtime implemented tool count changed.'
Assert-BoostLabCondition ([int]$inventory.Snapshot.DeferredPlaceholders -eq [int]$inventory.Baseline.DeferredPlaceholders) 'Deferred placeholder count changed.'
Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$parityBaseline.CurrentOrderedParityTarget)) 'Central current ordered parity target must be populated.'

$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ($null -ne $nextTarget) 'Ordered parity cursor must identify the next target.'
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq [string]$parityBaseline.CurrentOrderedParityTarget) 'Next ordered parity target must match the central parity baseline cursor.'

$hardcodedCursorAssertions = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'tests') -Filter 'Test-*.ps1' |
        Where-Object {
            $text = Get-Content -LiteralPath $_.FullName -Raw
            $text -match "(nextTarget|firstNonFinal).*?-eq\s+'(graphics-configuration-center|start-menu-taskbar)'"
        }
)
$hardcodedCursorAssertionNames = @($hardcodedCursorAssertions | ForEach-Object { $_.Name })
Assert-BoostLabCondition ($hardcodedCursorAssertions.Count -eq 0) "Ordered cursor assertions must read CurrentOrderedParityTarget instead of hardcoding a current tool. Offending files: $($hardcodedCursorAssertionNames -join ', ')"

$artifactSources = Import-PowerShellDataFile -LiteralPath $artifactSourcesPath
$graphicsConfigArtifacts = @($artifactSources.ExternalSources | Where-Object { [string]$_.ToolId -eq 'graphics-configuration-center' })
Assert-BoostLabCondition ($graphicsConfigArtifacts.Count -eq 0) 'Graphics Configuration Center must not add external artifact source entries.'

foreach ($deletedPath in @(
    'source-ultimate\6 Windows\17 Loudness EQ.ps1',
    'modules\Windows\loudness-eq.psm1',
    'source-ultimate\6 Windows\20 NVME Faster Driver.ps1',
    'modules\Windows\nvme-faster-driver.psm1'
)) {
    Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $deletedPath))) "Deleted tool path was reintroduced: $deletedPath"
}

[pscustomobject]@{
    Success = $true
    ToolId = 'graphics-configuration-center'
    SourceHash = $actualHash
    RuntimeCommand = 'Start-Process "ms-settings:display-advancedgraphics"'
    ImplementationLevel = [string]$record.ImplementationLevel
    UltimateParity = [string]$record.UltimateParity
    NextOrderedPendingParityTarget = [string]$nextTarget.ToolId
    ActiveTools = $inventory.Snapshot.ActiveTools
    RuntimeImplementedTools = $inventory.Snapshot.ImplementedTools
    DeferredPlaceholders = $inventory.Snapshot.DeferredPlaceholders
    UltimateParityImplemented = $parityBaseline.Counts.UltimateParityImplemented
    ControlledSubset = $parityBaseline.Counts.ControlledSubset
    SourceUltimateUnchanged = $true
    DeletedToolsRemainDeleted = $true
    Message = 'Graphics Configuration Center is accepted as exact source-equivalent Open-only parity and advances the ordered cursor to Start Menu Taskbar.'
    Timestamp = Get-Date
}
