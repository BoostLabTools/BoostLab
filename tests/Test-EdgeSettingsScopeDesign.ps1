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
        throw 'Unable to determine the Edge Settings scope design validator script path.'
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

    Assert-BoostLabCondition ($Text.Contains($Needle)) "$Description is missing expected text: $Needle"
}

$designPath = Join-Path $ProjectRoot 'docs\tool-designs\edge-settings-scope-design.md'
$readinessPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\3 Setup\6 Edge Settings.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Setup\edge-settings.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$artifactPolicyPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$cleanupPolicyPath = Join-Path $ProjectRoot 'config\CleanupPolicy.psd1'
$rollbackPolicyPath = Join-Path $ProjectRoot 'config\RollbackPolicy.psd1'
$servicePolicyPath = Join-Path $ProjectRoot 'config\ServiceRollbackPolicy.psd1'
$rebootPolicyPath = Join-Path $ProjectRoot 'config\RebootRecoveryPolicy.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

foreach ($path in @(
    $designPath,
    $readinessPath,
    $planPath,
    $sourcePath,
    $modulePath,
    $configPath,
    $artifactPolicyPath,
    $cleanupPolicyPath,
    $rollbackPolicyPath,
    $servicePolicyPath,
    $rebootPolicyPath,
    $productionAllowlistPath
)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required file was not found: $path"
}

$designText = Get-Content -LiteralPath $designPath -Raw
$readinessText = Get-Content -LiteralPath $readinessPath -Raw
$planText = Get-Content -LiteralPath $planPath -Raw
$sourceText = Get-Content -LiteralPath $sourcePath -Raw
$moduleText = Get-Content -LiteralPath $modulePath -Raw
$config = Import-PowerShellDataFile -LiteralPath $configPath
$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPolicyPath
$cleanupPolicy = Import-PowerShellDataFile -LiteralPath $cleanupPolicyPath
$rollbackPolicy = Import-PowerShellDataFile -LiteralPath $rollbackPolicyPath
$servicePolicy = Import-PowerShellDataFile -LiteralPath $servicePolicyPath
$rebootPolicy = Import-PowerShellDataFile -LiteralPath $rebootPolicyPath
$productionAllowlist = Import-PowerShellDataFile -LiteralPath $productionAllowlistPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })

$expectedSourceHash = '342869157930ECF0869A07B4254CB8F174C63648CD329DB3914BAD291CD5FF28'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Edge Settings source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."

foreach ($requiredSection in @(
    '# Edge Settings Scope Design',
    '## Purpose',
    '## Source Reference',
    '## Product Scope Decision',
    '## Source Behavior Summary',
    '## Current Decision',
    '## Behavior Groups',
    '### 1. Edge Policy Registry Behavior',
    '### 2. Edge Extension Force-Install Behavior',
    '### 3. Edge Services Behavior',
    '### 4. Edge Scheduled Tasks Behavior',
    '### 5. Active Setup Behavior',
    '### 6. RunOnce Behavior',
    '### 7. BHO / Browser Helper Object Behavior',
    '### 8. Edge Process Stop Behavior',
    '### 9. External Edge Executable Download Behavior',
    '### 10. File/Directory Cleanup Behavior If Present',
    '### 11. Default/Restore Behavior',
    '### 12. Unsupported Broad Edge Policy/Service/Task/File/Registry Targets',
    '### 13. Unsupported Windows 10-Only Branches/Options If Present',
    '## Exact Source Target Inventory',
    '## Future Safe Apply Requirements',
    '## Default and Restore Boundary',
    '## Production Approval State'
)) {
    Assert-BoostLabTextContains -Text $designText -Needle $requiredSection -Description 'Edge Settings scope design'
}

foreach ($requiredPhrase in @(
    'Source SHA-256: `342869157930ECF0869A07B4254CB8F174C63648CD329DB3914BAD291CD5FF28`',
    'Phase 118 implements Yazan''s option 1',
    'source-equivalent Edge Settings behavior',
    'not policy-only and is not Open-only',
    'Restore remains unavailable',
    'No Windows 10-only branch was found',
    'Do not implement a policy-only subset',
    'Any policy-only implementation would weaken Ultimate behavior',
    'No broad production Edge policy',
    'does not create a reusable'
)) {
    Assert-BoostLabTextContains -Text $designText -Needle $requiredPhrase -Description 'Edge Settings scope design'
}

foreach ($requiredSourceTarget in @(
    'HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist',
    'odfafepnkmbhccpbejgmiehpchacaeak;https://edge.microsoft.com/extensionwebstorebase/v1/crx',
    'HardwareAccelerationModeEnabled',
    'BackgroundModeEnabled',
    'StartupBoostEnabled',
    'HKLM:\Software\Microsoft\Active Setup\Installed Components',
    'Default value match `*Edge*`',
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
    'Value name match `*msedge*`',
    'Get-Service | Where-Object { $_.Name -match ''Edge'' }',
    'sc stop',
    'sc delete',
    'Get-ScheduledTask | Where-Object { $_.TaskName -like ''*Edge*'' }',
    'Unregister-ScheduledTask -Confirm:$false',
    'Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}',
    'Stop-Process -Name "msedge" -Force -ErrorAction SilentlyContinue',
    'Start-Process "msedge.exe" -ArgumentList "--restore-last-session --disable-extensions"',
    'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe',
    '$env:SystemRoot\Temp\edge.exe',
    'IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe" -OutFile "$env:SystemRoot\Temp\edge.exe"',
    'Start-Process "$env:SystemRoot\Temp\edge.exe"'
)) {
    Assert-BoostLabTextContains -Text $designText -Needle $requiredSourceTarget -Description 'Edge Settings scope design source target inventory'
}

$urls = [regex]::Matches($sourceText, 'https?://[^\s"`]+') |
    ForEach-Object { $_.Value } |
    Sort-Object -Unique
Assert-BoostLabCondition (@($urls).Count -eq 2) "Expected 2 Edge Settings source URLs, found $(@($urls).Count)."
foreach ($url in $urls) {
    Assert-BoostLabTextContains -Text $designText -Needle $url -Description 'Edge Settings scope design URL inventory'
}

Assert-BoostLabCondition (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) 'Edge Settings module must be implemented after Phase 118.'
foreach ($moduleNeedle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'', ''Restore'')',
    'Invoke-BoostLabEdgeSettingsApply',
    'Invoke-BoostLabEdgeSettingsDefault',
    'Get-BoostLabEdgeSettingsOperationPlan',
    'Invoke-BoostLabEdgeSettingsDownload',
    'RestoreUnavailable'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $moduleNeedle -Description 'Edge Settings module implementation'
}

Assert-BoostLabTextContains -Text $readinessText -Needle 'Edge Settings is no longer a deferred placeholder. Phase 118 implements' -Description 'Deferred readiness review'
Assert-BoostLabTextContains -Text $planText -Needle '| `edge-settings` | Edge Settings | Setup |' -Description 'Deferred tools execution plan'
Assert-BoostLabTextContains -Text $planText -Needle 'Implemented near parity in Phase 118' -Description 'Deferred tools execution plan'

Assert-BoostLabCondition (@($artifactPolicy.Artifacts).Count -eq 0) "Artifact approvals were added unexpectedly: $(@($artifactPolicy.Artifacts).Count)"
Assert-BoostLabCondition (@($cleanupPolicy.CleanupScopes).Count -eq 0) "Cleanup production scopes were approved unexpectedly: $(@($cleanupPolicy.CleanupScopes).Count)"
Assert-BoostLabCondition (@($rollbackPolicy.FileScopes).Count -eq 0 -and @($rollbackPolicy.RegistryScopes).Count -eq 0) 'File or registry production scopes were approved unexpectedly.'
Assert-BoostLabCondition (@($servicePolicy.ServiceScopes).Count -eq 0) "Service production scopes were approved unexpectedly: $(@($servicePolicy.ServiceScopes).Count)"
Assert-BoostLabCondition (@($rebootPolicy.WorkflowScopes).Count -eq 0) "Reboot workflow production scopes were approved unexpectedly: $(@($rebootPolicy.WorkflowScopes).Count)"
Assert-BoostLabCondition (@($productionAllowlist.ProductionAllowlistProposals).Count -eq 0) 'Production allowlist proposals were added unexpectedly.'

$edgeSettingsTool = $allTools |
    Where-Object { $_.Id -eq 'edge-settings' -and $_.Stage -eq 'Setup' } |
    Select-Object -First 1
Assert-BoostLabCondition ($null -ne $edgeSettingsTool) 'Edge Settings catalog entry was not found.'
Assert-BoostLabCondition ((@($edgeSettingsTool.Actions) -join ',') -eq 'Analyze,Apply,Default,Restore') 'Edge Settings catalog actions are incorrect.'

$activeTools = @($allTools)
$placeholderModules = @(
    Get-ChildItem -Path (Join-Path $ProjectRoot 'modules') -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
Assert-BoostLabCondition ($activeTools.Count -eq $inventoryBaseline.ActiveTools) "Expected $($inventoryBaseline.ActiveTools) active tools, found $($activeTools.Count)."
Assert-BoostLabCondition ($placeholderModules.Count -eq $inventoryBaseline.DeferredPlaceholders) "Expected $($inventoryBaseline.DeferredPlaceholders) placeholder modules, found $($placeholderModules.Count)."
Assert-BoostLabCondition (($activeTools.Count - $placeholderModules.Count) -eq $inventoryBaseline.ImplementedTools) "Expected $($inventoryBaseline.ImplementedTools) implemented tools, found $($activeTools.Count - $placeholderModules.Count)."

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

Assert-BoostLabCondition (@($sourceLines).Count -eq 49) 'source-ultimate file count changed.'
Assert-BoostLabCondition ($manifestHash -eq '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') 'source-ultimate content or paths changed.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }).Count -eq 0) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    Success                       = $true
    ToolId                        = 'edge-settings'
    SourceHash                    = $actualSourceHash
    ActiveToolCount               = $activeTools.Count
    ImplementedToolCount          = $activeTools.Count - $placeholderModules.Count
    PlaceholderToolCount          = $placeholderModules.Count
    ProductionArtifactApprovals   = @($artifactPolicy.Artifacts).Count
    ProductionCleanupScopes       = @($cleanupPolicy.CleanupScopes).Count
    ProductionFileScopes          = @($rollbackPolicy.FileScopes).Count
    ProductionRegistryScopes      = @($rollbackPolicy.RegistryScopes).Count
    ProductionServiceScopes       = @($servicePolicy.ServiceScopes).Count
    ProductionRebootScopes        = @($rebootPolicy.WorkflowScopes).Count
    SourceUltimateUnchanged       = $true
    DeletedToolsRemainDeleted     = $true
    Message                       = 'Edge Settings scope design reflects the Phase 118 source-equivalent near-parity implementation.'
    Timestamp                     = Get-Date
}
