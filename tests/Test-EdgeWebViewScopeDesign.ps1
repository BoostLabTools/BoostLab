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
        throw 'Unable to determine the Edge & WebView scope design validator script path.'
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

$designPath = Join-Path $ProjectRoot 'docs\tool-designs\edge-webview-scope-design.md'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\13 Edge & WebView.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\edge-webview.psm1'
$migrationPath = Join-Path $ProjectRoot 'docs\migrations\edge-webview.md'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$parityPath = Join-Path $ProjectRoot 'config\ParityStatusBaseline.psd1'
$appxPolicyPath = Join-Path $ProjectRoot 'config\AppxPackagePolicy.psd1'
$cleanupPolicyPath = Join-Path $ProjectRoot 'config\CleanupPolicy.psd1'
$rollbackPolicyPath = Join-Path $ProjectRoot 'config\RollbackPolicy.psd1'
$servicePolicyPath = Join-Path $ProjectRoot 'config\ServiceRollbackPolicy.psd1'
$artifactPolicyPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

foreach ($path in @(
    $designPath,
    $sourcePath,
    $modulePath,
    $migrationPath,
    $configPath,
    $parityPath,
    $appxPolicyPath,
    $cleanupPolicyPath,
    $rollbackPolicyPath,
    $servicePolicyPath,
    $artifactPolicyPath
)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required file was not found: $path"
}

$expectedSourceHash = '161ED9C99D437E45650369CB7E15D5737DED363712E647138F134B049AC7E691'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Edge & WebView source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."

$designText = Get-Content -LiteralPath $designPath -Raw
$moduleText = Get-Content -LiteralPath $modulePath -Raw
$migrationText = Get-Content -LiteralPath $migrationPath -Raw

foreach ($requiredSection in @(
    '# Edge and WebView Scope Design',
    '## Purpose',
    '## Source Reference',
    '## Source Behavior Summary',
    '## Current Decision',
    '## Behavior Groups',
    '## Default and Restore Boundary',
    '## Production Approval State'
)) {
    Assert-BoostLabTextContains -Text $designText -Needle $requiredSection -Description 'Edge & WebView scope design'
}

foreach ($requiredPhrase in @(
    'Phase 147 supersedes the manual-handoff status',
    'exact source-equivalent controlled runtime',
    'Current implemented actions: `Apply`, `Default`',
    'Apply runs the source `Edge & WebView: Uninstall (Recommended)`',
    'Default runs the source `Edge & WebView: Default`',
    'Open and Restore remain unavailable because',
    'the source does not define those branches',
    'No reusable production AppX/package/download/installer/cleanup/file/registry/',
    'Restore remains blocked until a future phase explicitly approves',
    'captured-state restore contract'
)) {
    Assert-BoostLabTextContains -Text $designText -Needle $requiredPhrase -Description 'Edge & WebView scope design current status'
}

foreach ($requiredSourceTarget in @(
    'Microsoft.MicrosoftEdge_8wekyb3d8bbwe',
    'MicrosoftEdge.exe',
    'Microsoft EdgeWebView',
    'MicrosoftEdgeUpdate.exe',
    'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Control Panel\DeviceRegion',
    'HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView',
    'HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist',
    'HKLM\Software\Microsoft\Active Setup\Installed Components',
    'HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce',
    'Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}',
    'Microsoft-Windows-Internet-Browser-Package',
    'dism /online /Remove-Package',
    'edge.exe',
    'edgewebview.exe'
)) {
    Assert-BoostLabTextContains -Text $designText -Needle $requiredSourceTarget -Description 'Edge & WebView scope design source target'
}

foreach ($requiredMigrationText in @(
    'Migration status: Exact Ultimate parity implemented',
    'Approved for Phase 147 exact source-equivalent Apply/Default behavior',
    '`Apply`: source-equivalent `Edge & WebView: Uninstall (Recommended)`',
    '`Default`: source-defined `Edge & WebView: Default` repair branch',
    'No `Open` or `Restore` action is exposed',
    'Default is available as the source repair/reinstall plus policy and cleanup',
    'branch. Restore is unavailable because the Ultimate source does not define a',
    'captured Edge/WebView package, installer, file, registry, service,'
)) {
    Assert-BoostLabTextContains -Text $migrationText -Needle $requiredMigrationText -Description 'Edge & WebView migration record'
}

foreach ($requiredModuleNeedle in @(
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')',
    'Get-BoostLabEdgeWebViewUninstallOperations',
    'Get-BoostLabEdgeWebViewDefaultOperations',
    'Invoke-BoostLabEdgeWebViewWorkflow',
    'DownloadFile',
    'DeleteEdgeServices',
    'UnregisterEdgeScheduledTasks',
    'RemoveLegacyEdgePackageIfPresent'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $requiredModuleNeedle -Description 'Edge & WebView exact parity module'
}
foreach ($forbiddenModuleText in @('ToolModule.Placeholder.ps1', 'ManualHandoffOnly', 'AutoBlockedUntilArtifactApproval', 'DefaultUnavailable', 'RestoreUnavailable')) {
    Assert-BoostLabCondition (-not $moduleText.Contains($forbiddenModuleText)) "Edge & WebView module contains stale text: $forbiddenModuleText"
}

$config = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })
$edgeTool = @($allTools | Where-Object { $_.Id -eq 'edge-webview' })[0]
Assert-BoostLabCondition ((@($edgeTool.Actions) -join ',') -eq 'Apply,Default') 'Edge & WebView catalog actions must be Apply,Default.'
Assert-BoostLabCondition ([string]$edgeTool.Type -eq 'action') 'Edge & WebView catalog type must be action.'

$parity = Import-PowerShellDataFile -LiteralPath $parityPath
$edgeParity = @($parity.Tools | Where-Object { $_.ToolId -eq 'edge-webview' })[0]
Assert-BoostLabCondition ([string]$edgeParity.ImplementationLevel -eq 'ParityImplemented') 'Edge & WebView parity implementation level mismatch.'
Assert-BoostLabCondition ([string]$edgeParity.UltimateParity -eq 'Yes') 'Edge & WebView UltimateParity mismatch.'

$appxPolicy = Import-PowerShellDataFile -LiteralPath $appxPolicyPath
$cleanupPolicy = Import-PowerShellDataFile -LiteralPath $cleanupPolicyPath
$rollbackPolicy = Import-PowerShellDataFile -LiteralPath $rollbackPolicyPath
$servicePolicy = Import-PowerShellDataFile -LiteralPath $servicePolicyPath
$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPolicyPath
Assert-BoostLabCondition ($appxPolicy.PackageScopes.Count -eq 0) "AppX package production scopes were approved unexpectedly: $($appxPolicy.PackageScopes.Count)"
Assert-BoostLabCondition ($cleanupPolicy.CleanupScopes.Count -eq 0) "Cleanup production scopes were approved unexpectedly: $($cleanupPolicy.CleanupScopes.Count)"
Assert-BoostLabCondition ($rollbackPolicy.FileScopes.Count -eq 0 -and $rollbackPolicy.RegistryScopes.Count -eq 0) 'File or registry production scopes were approved unexpectedly.'
Assert-BoostLabCondition ($servicePolicy.ServiceScopes.Count -eq 0) "Service production scopes were approved unexpectedly: $($servicePolicy.ServiceScopes.Count)"
Assert-BoostLabCondition ($artifactPolicy.Artifacts.Count -eq 0) "Artifact approvals were added unexpectedly: $($artifactPolicy.Artifacts.Count)"

$placeholderModules = @(
    Get-ChildItem -Path (Join-Path $ProjectRoot 'modules') -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
Assert-BoostLabCondition ($allTools.Count -eq $inventoryBaseline.ActiveTools) "Expected $($inventoryBaseline.ActiveTools) active tools, found $($allTools.Count)."
Assert-BoostLabCondition ($placeholderModules.Count -eq $inventoryBaseline.DeferredPlaceholders) "Expected $($inventoryBaseline.DeferredPlaceholders) placeholder modules, found $($placeholderModules.Count)."
Assert-BoostLabCondition (($allTools.Count - $placeholderModules.Count) -eq $inventoryBaseline.ImplementedTools) "Expected $($inventoryBaseline.ImplementedTools) implemented tools, found $($allTools.Count - $placeholderModules.Count)."

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
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
            [Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n"))
        )
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}

Assert-BoostLabCondition (@($sourceLines).Count -eq 49) "source-ultimate file count changed: $(@($sourceLines).Count)"
Assert-BoostLabCondition ($manifestHash -eq '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') 'source-ultimate content or paths changed.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }).Count -eq 0) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    Success                   = $true
    ToolId                    = 'edge-webview'
    SourceHash                = $actualSourceHash
    ActiveToolCount           = $allTools.Count
    ImplementedToolCount      = $allTools.Count - $placeholderModules.Count
    PlaceholderToolCount      = $placeholderModules.Count
    ProductionPackageScopes   = $appxPolicy.PackageScopes.Count
    ProductionCleanupScopes   = $cleanupPolicy.CleanupScopes.Count
    ProductionFileScopes      = $rollbackPolicy.FileScopes.Count
    ProductionRegistryScopes  = $rollbackPolicy.RegistryScopes.Count
    ProductionServiceScopes   = $servicePolicy.ServiceScopes.Count
    ArtifactApprovals         = $artifactPolicy.Artifacts.Count
    SourceUltimateUnchanged   = $true
    DeletedToolsRemainDeleted = $true
    Message                   = 'Edge & WebView scope design reflects exact source-equivalent Apply/Default with no global production approvals.'
    Timestamp                 = Get-Date
}
