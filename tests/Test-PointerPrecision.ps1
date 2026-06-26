Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'BoostLab.Hashing.ps1')
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
        throw 'Unable to determine the Pointer Precision validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}

. (Join-Path $ProjectRoot 'tests\BoostLab.ParityStatusBaseline.ps1')
. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')

function Assert-PointerPrecisionCondition {
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

$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\10 Pointer Precision.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\pointer-precision.psm1'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$artifactPolicyPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ExternalArtifactSources.psd1'

$expectedSourceHash = 'ED66BB1C068DF13FC2D58617E49C2274CEA9609C689FE34F9A0B138AC22F618C'
$expectedLauncher = 'Start-Process "control.exe" -ArgumentList "main.cpl ,2"'

$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
Assert-PointerPrecisionCondition ($actualSourceHash -eq $expectedSourceHash) "Pointer Precision source checksum mismatch. Expected $expectedSourceHash, found $actualSourceHash."

$sourceText = (Get-Content -Raw -LiteralPath $sourcePath).Trim()
$moduleText = Get-Content -Raw -LiteralPath $modulePath
$executionText = Get-Content -Raw -LiteralPath $executionPath

Assert-PointerPrecisionCondition ($sourceText -eq $expectedLauncher) 'Ultimate Pointer Precision source must remain the approved single Control Panel launcher.'
Assert-PointerPrecisionCondition ($moduleText.Contains($expectedLauncher)) 'BoostLab Pointer Precision module must preserve the exact source launcher.'
Assert-PointerPrecisionCondition ($moduleText.Contains('$script:BoostLabImplementedActions = @(''Open'')')) 'Pointer Precision must remain Open-only implemented.'
Assert-PointerPrecisionCondition (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) 'Pointer Precision must not use placeholder behavior.'
Assert-PointerPrecisionCondition (-not ($moduleText -match 'Set-ItemProperty|New-ItemProperty|Remove-ItemProperty|Remove-Item|Set-Content|Add-Content|Out-File|Stop-Process|Stop-Service|Set-Service|New-ScheduledTask|Register-ScheduledTask|schtasks|Invoke-WebRequest|Invoke-RestMethod|Start-BitsTransfer|winget|Get-AppxPackage|Remove-AppxPackage|Restart-Computer|bcdedit')) 'Pointer Precision module must not contain mutation, package, download, task, service, process-stop, or reboot commands.'

$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $modulePath,
    [ref]$tokens,
    [ref]$parseErrors
)
if (@($parseErrors).Count -gt 0) {
    throw "Pointer Precision module parse failed: $(@($parseErrors)[0].Message)"
}
$commands = @(
    $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
        $true
    ) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }
)
Assert-PointerPrecisionCondition (@($commands | Where-Object { $_ -eq 'Start-Process' }).Count -eq 1) 'Pointer Precision must contain exactly one Start-Process command.'

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$tool = @($stages.Stages | ForEach-Object { $_.Tools } | Where-Object { [string]$_.Id -eq 'pointer-precision' }) | Select-Object -First 1
Assert-PointerPrecisionCondition ($null -ne $tool) 'Pointer Precision stage entry is missing.'
Assert-PointerPrecisionCondition ([string]$tool.Title -eq 'Pointer Precision') 'Pointer Precision title changed.'
Assert-PointerPrecisionCondition ([string]$tool.Type -eq 'assistant') 'Pointer Precision must remain an assistant.'
Assert-PointerPrecisionCondition ([string]$tool.RiskLevel -eq 'low') 'Pointer Precision risk level must remain low.'
Assert-PointerPrecisionCondition ((@($tool.Actions) -join ',') -eq 'Open') 'Pointer Precision must expose only Open.'
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
    Assert-PointerPrecisionCondition (-not [bool]$tool.Capabilities[$capability]) "Pointer Precision must not enable capability: $capability"
}

Assert-PointerPrecisionCondition ($executionText.Contains("'pointer-precision' = @{")) 'Execution registry must include Pointer Precision.'
Assert-PointerPrecisionCondition ($executionText.Contains("Windows\pointer-precision.psm1")) 'Execution registry must route to the Pointer Precision module.'
Assert-PointerPrecisionCondition ($executionText.Contains("Actions = @('Open')")) 'Execution registry must expose Open-only actions for Pointer Precision.'

$pointerModule = Import-Module -Force -PassThru -Prefix PointerPrecisionTest -Name $modulePath
try {
    $toolInfo = Get-PointerPrecisionTestBoostLabToolInfo
    Assert-PointerPrecisionCondition ((@($toolInfo.Actions) -join ',') -eq 'Open') 'Pointer Precision tool info must expose Open only.'
    Assert-PointerPrecisionCondition ((@($toolInfo.ImplementedActions) -join ',') -eq 'Open') 'Pointer Precision implemented actions must expose Open only.'
    Assert-PointerPrecisionCondition (-not [bool]$toolInfo.Capabilities.SupportsDefault) 'Pointer Precision must not support Default.'
    Assert-PointerPrecisionCondition (-not [bool]$toolInfo.Capabilities.SupportsRestore) 'Pointer Precision must not support Restore.'

    $unsupportedDefault = Invoke-PointerPrecisionTestBoostLabToolAction -ActionName 'Default'
    Assert-PointerPrecisionCondition (-not [bool]$unsupportedDefault.Success) 'Pointer Precision Default must not be implemented.'
    Assert-PointerPrecisionCondition ([string]$unsupportedDefault.Message -match 'Only Open') 'Pointer Precision unsupported action message must describe Open-only behavior.'

    $restoreResult = Restore-PointerPrecisionTestBoostLabToolDefault
    Assert-PointerPrecisionCondition (-not [bool]$restoreResult.Success) 'Pointer Precision Restore/Default helper must not expose a real Default.'
}
finally {
    if ($pointerModule) {
        Remove-Module -ModuleInfo $pointerModule -Force -ErrorAction SilentlyContinue
    }
}

$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPolicyPath
Assert-PointerPrecisionCondition (@($artifactPolicy.Artifacts).Count -eq 0) 'Pointer Precision must not approve artifact provenance entries.'
$externalSources = Import-PowerShellDataFile -LiteralPath $productionAllowlistPath
$pointerExternalSources = @($externalSources.ExternalSources | Where-Object { [string]$_.ToolId -eq 'pointer-precision' })
Assert-PointerPrecisionCondition ($pointerExternalSources.Count -eq 0) 'Pointer Precision must not add external artifact source entries.'

$inventory = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
$pointerRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'pointer-precision' }) | Select-Object -First 1
Assert-PointerPrecisionCondition ($null -ne $pointerRecord) 'Pointer Precision parity record is missing.'
Assert-PointerPrecisionCondition ([string]$pointerRecord.RuntimeStatus -eq 'RuntimeImplemented') 'Pointer Precision runtime status must remain RuntimeImplemented.'
Assert-PointerPrecisionCondition ([string]$pointerRecord.ImplementationLevel -eq 'ParityImplemented') 'Pointer Precision must be marked ParityImplemented.'
Assert-PointerPrecisionCondition ([string]$pointerRecord.UltimateParity -eq 'Yes') 'Pointer Precision UltimateParity must be Yes.'
Assert-PointerPrecisionCondition (-not [bool]$pointerRecord.YazanFinalException) 'Pointer Precision must not use a Yazan final exception.'
Assert-PointerPrecisionCondition ([string]$parityBaseline.CurrentOrderedParityTarget -eq [string]$nextTarget.ToolId) 'Current ordered parity target must match the derived first non-final target.'

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
    Assert-PointerPrecisionCondition ($actual -eq $expected) "Unexpected parity category count for $level."
}

foreach ($deletedPath in @(
    'source-ultimate\6 Windows\17 Loudness EQ.ps1',
    'modules\Windows\loudness-eq.psm1',
    'source-ultimate\6 Windows\20 NVME Faster Driver.ps1',
    'modules\Windows\nvme-faster-driver.psm1'
)) {
    Assert-PointerPrecisionCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $deletedPath))) "Deleted tool path was reintroduced: $deletedPath"
}

[pscustomobject]@{
    Success                    = $true
    ToolId                     = 'pointer-precision'
    SourceHash                 = $actualSourceHash
    RuntimeCommand             = $expectedLauncher
    ImplementationLevel        = [string]$pointerRecord.ImplementationLevel
    UltimateParity             = [string]$pointerRecord.UltimateParity
    CurrentOrderedParityTarget = [string]$parityBaseline.CurrentOrderedParityTarget
    ActiveTools                = [int]$inventory.Snapshot.ActiveTools
    RuntimeImplementedTools    = [int]$inventory.Snapshot.ImplementedTools
    DeferredPlaceholders       = [int]$inventory.Snapshot.DeferredPlaceholders
    OpenActionExecuted         = $false
    SourceUltimateUnchanged    = $true
    DeletedToolsRemainDeleted  = $true
    Message                    = 'Pointer Precision is exact source-equivalent Open-only parity and the ordered cursor matches the central parity baseline.'
    Timestamp                  = Get-Date
}
