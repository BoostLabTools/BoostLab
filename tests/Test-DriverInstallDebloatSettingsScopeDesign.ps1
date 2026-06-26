[CmdletBinding()]
param(
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'BoostLab.Hashing.ps1')
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $scriptPath = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $PSCommandPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $MyInvocation.MyCommand.Path
    }
    else {
        throw 'Unable to determine the Driver Install Debloat & Settings scope/provenance design validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

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

    if (-not $Text.Contains($Needle)) {
        throw "$Description is missing: $Needle"
    }
}

$designPath = Join-Path $ProjectRoot 'docs\tool-designs\driver-install-debloat-settings-scope-provenance-design.md'
$readinessPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$migrationPath = Join-Path $ProjectRoot 'docs\migrations\driver-install-debloat-settings.md'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\5 Graphics\1 Driver Install Debloat & Settings.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Graphics\driver-install-debloat-settings.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$artifactPolicyPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$driverPolicyPath = Join-Path $ProjectRoot 'config\DriverStatePolicy.psd1'
$appxPolicyPath = Join-Path $ProjectRoot 'config\AppxPackagePolicy.psd1'
$rollbackPolicyPath = Join-Path $ProjectRoot 'config\RollbackPolicy.psd1'
$servicePolicyPath = Join-Path $ProjectRoot 'config\ServiceRollbackPolicy.psd1'
$cleanupPolicyPath = Join-Path $ProjectRoot 'config\CleanupPolicy.psd1'
$rebootPolicyPath = Join-Path $ProjectRoot 'config\RebootRecoveryPolicy.psd1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

foreach ($path in @(
    $designPath,
    $readinessPath,
    $planPath,
    $migrationPath,
    $sourcePath,
    $modulePath,
    $configPath,
    $artifactPolicyPath,
    $driverPolicyPath,
    $appxPolicyPath,
    $rollbackPolicyPath,
    $servicePolicyPath,
    $cleanupPolicyPath,
    $rebootPolicyPath
)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required file was not found: $path"
}

$expectedSourceHash = '00D7EA2C941DF776F729CD35A9386FE18D59D02717DCB3CF43282714E345A6D3'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Driver Install Debloat & Settings source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."

$designText = Get-Content -LiteralPath $designPath -Raw
$readinessText = Get-Content -LiteralPath $readinessPath -Raw
$planText = Get-Content -LiteralPath $planPath -Raw
$migrationText = Get-Content -LiteralPath $migrationPath -Raw
$moduleText = Get-Content -LiteralPath $modulePath -Raw

foreach ($requiredSection in @(
    '# Driver Install Debloat and Settings Scope Provenance Design',
    '## Source Reference',
    '## Product Scope Decision',
    '## Source Behavior Summary',
    '## Current Decision',
    '## Behavior Groups',
    '## Exact Source Target Inventory',
    '## Future Safe Apply/Open/Install Requirements',
    '## Default and Restore Boundary',
    '## Production Approval State'
)) {
    Assert-BoostLabTextContains -Text $designText -Needle $requiredSection -Description 'scope/provenance design'
}

foreach ($requiredPhrase in @(
    'Phase 123 implements the source-equivalent NVIDIA, AMD, and INTEL runtime',
    'No reusable/global production download/installer/executable/driver/profile/AppX/registry/file/service/task/cleanup/reboot scopes',
    'Phase 122 records a tool-specific branch-scope decision for this tool only',
    'Yazan approved all source-defined Driver Install Debloat & Settings branches',
    'This does not expand project-wide AMD or Intel GPU support',
    'Unique URL count: `5`',
    'Non-elevation `Start-Process` command count: `15`',
    '`Remove-Item` command count: `41`',
    '`reg add` command count: `33`',
    '`sc stop` command count: `11`',
    'NVIDIA profile setting count in `inspector.nip`: `31`',
    'Current Default/Restore must remain unavailable'
)) {
    Assert-BoostLabTextContains -Text $designText -Needle $requiredPhrase -Description 'scope/provenance design'
}

foreach ($requiredSourceTarget in @(
    'Write-Host " 1.  NVIDIA"',
    'Write-Host " 2.  AMD"',
    'Write-Host " 3.  INTEL`n"',
    '$env:SystemRoot\Temp\nvidiadriver\Display.Nview',
    '$env:SystemRoot\Temp\nvidiadriver\setup.exe',
    '$env:SystemRoot\Temp\inspector.exe',
    '$env:SystemRoot\Temp\inspector.nip',
    'C:\ProgramData\NVIDIA Corporation\Drs',
    'Get-AppxPackage -allusers *Microsoft.Winget.Source* | Remove-AppxPackage',
    'AMD Crash Defender Service',
    'amdfendr',
    'IntelGFXFWupdateTool',
    'PresentMonService',
    'Unregister-ScheduledTask -TaskName "StartCN" -Confirm:$false',
    'shutdown -r -t 00'
)) {
    Assert-BoostLabTextContains -Text $designText -Needle $requiredSourceTarget -Description 'source target inventory'
}

foreach ($textAndName in @(
    @{ Text = $readinessText; Name = 'deferred readiness review' },
    @{ Text = $planText; Name = 'deferred tools execution plan' },
    @{ Text = $migrationText; Name = 'migration record' }
)) {
    Assert-BoostLabTextContains -Text $textAndName.Text -Needle 'Phase 123' -Description $textAndName.Name
    Assert-BoostLabTextContains -Text $textAndName.Text -Needle 'NVIDIA' -Description $textAndName.Name
    Assert-BoostLabTextContains -Text $textAndName.Text -Needle 'AMD' -Description $textAndName.Name
    Assert-BoostLabTextContains -Text $textAndName.Text -Needle 'INTEL' -Description $textAndName.Name
}

Assert-BoostLabTextContains -Text $moduleText -Needle 'SourceEquivalentThreeBranchRuntime' -Description 'runtime module'
Assert-BoostLabTextContains -Text $moduleText -Needle 'OperationExecutor' -Description 'runtime module mock seam'
Assert-BoostLabTextContains -Text $moduleText -Needle 'Get-BoostLabDriverInstallDebloatSettingsOperationPlan' -Description 'runtime module'

$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPolicyPath
$driverPolicy = Import-PowerShellDataFile -LiteralPath $driverPolicyPath
$appxPolicy = Import-PowerShellDataFile -LiteralPath $appxPolicyPath
$rollbackPolicy = Import-PowerShellDataFile -LiteralPath $rollbackPolicyPath
$servicePolicy = Import-PowerShellDataFile -LiteralPath $servicePolicyPath
$cleanupPolicy = Import-PowerShellDataFile -LiteralPath $cleanupPolicyPath
$rebootPolicy = Import-PowerShellDataFile -LiteralPath $rebootPolicyPath

Assert-BoostLabCondition (@($artifactPolicy.Artifacts).Count -eq 0) "Artifact approvals were added unexpectedly: $(@($artifactPolicy.Artifacts).Count)"
Assert-BoostLabCondition (@($driverPolicy.DriverScopes).Count -eq 0) "Driver production scopes were approved unexpectedly: $(@($driverPolicy.DriverScopes).Count)"
Assert-BoostLabCondition (@($appxPolicy.PackageScopes).Count -eq 0) "AppX package production scopes were approved unexpectedly: $(@($appxPolicy.PackageScopes).Count)"
Assert-BoostLabCondition (@($rollbackPolicy.FileScopes).Count -eq 0 -and @($rollbackPolicy.RegistryScopes).Count -eq 0) 'File or registry production scopes were approved unexpectedly.'
Assert-BoostLabCondition (@($servicePolicy.ServiceScopes).Count -eq 0) "Service production scopes were approved unexpectedly: $(@($servicePolicy.ServiceScopes).Count)"
Assert-BoostLabCondition (@($cleanupPolicy.CleanupScopes).Count -eq 0) "Cleanup production scopes were approved unexpectedly: $(@($cleanupPolicy.CleanupScopes).Count)"
Assert-BoostLabCondition (@($rebootPolicy.WorkflowScopes).Count -eq 0) "Reboot workflow production scopes were approved unexpectedly: $(@($rebootPolicy.WorkflowScopes).Count)"

$config = Import-PowerShellDataFile -LiteralPath $configPath
$activeTools = @($config.Stages | ForEach-Object { $_.Tools })
$placeholderModules = @(
    Get-ChildItem -Path (Join-Path $ProjectRoot 'modules') -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
Assert-BoostLabCondition ($activeTools.Count -eq $inventoryBaseline.ActiveTools) "Expected $($inventoryBaseline.ActiveTools) active tools, found $($activeTools.Count)."
Assert-BoostLabCondition ($placeholderModules.Count -eq $inventoryBaseline.DeferredPlaceholders) "Expected $($inventoryBaseline.DeferredPlaceholders) placeholder modules, found $($placeholderModules.Count)."
Assert-BoostLabCondition (($activeTools.Count - $placeholderModules.Count) -eq $inventoryBaseline.ImplementedTools) "Expected $($inventoryBaseline.ImplementedTools) implemented tools, found $($activeTools.Count - $placeholderModules.Count)."

Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }).Count -eq 0) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    Success = $true
    ToolId = 'driver-install-debloat-settings'
    SourceHash = $actualSourceHash
    ActiveToolCount = $activeTools.Count
    ImplementedToolCount = $activeTools.Count - $placeholderModules.Count
    PlaceholderToolCount = $placeholderModules.Count
    ArtifactApprovals = @($artifactPolicy.Artifacts).Count
    ProductionDriverScopes = @($driverPolicy.DriverScopes).Count
    ProductionPackageScopes = @($appxPolicy.PackageScopes).Count
    ProductionFileScopes = @($rollbackPolicy.FileScopes).Count
    ProductionRegistryScopes = @($rollbackPolicy.RegistryScopes).Count
    ProductionServiceScopes = @($servicePolicy.ServiceScopes).Count
    ProductionCleanupScopes = @($cleanupPolicy.CleanupScopes).Count
    ProductionRebootScopes = @($rebootPolicy.WorkflowScopes).Count
    SourceUltimateUnchanged = $true
    DeletedToolsRemainDeleted = $true
    Message = 'Driver Install Debloat & Settings scope/provenance design is linked to the Phase 123 three-branch runtime and keeps reusable production scopes denied.'
    Timestamp = Get-Date
}
