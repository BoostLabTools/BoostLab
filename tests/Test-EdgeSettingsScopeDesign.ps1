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
    $rebootPolicyPath
)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file was not found: $path"
    }
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
$allTools = @($config.Stages | ForEach-Object { $_.Tools })

$expectedSourceHash = '342869157930ECF0869A07B4254CB8F174C63648CD329DB3914BAD291CD5FF28'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
if ($actualSourceHash -ne $expectedSourceHash) {
    throw "Edge Settings source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."
}

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
    if (-not $designText.Contains($requiredSection)) {
        throw "Edge Settings scope design is missing section: $requiredSection"
    }
}

foreach ($requiredPhrase in @(
    'Source SHA-256: `342869157930ECF0869A07B4254CB8F174C63648CD329DB3914BAD291CD5FF28`',
    'Edge Settings remains a refused placeholder',
    'No production Edge policy',
    'No Windows 10-only branch was found',
    'Do not implement a policy-only subset',
    'policy-only implementation would weaken Ultimate behavior',
    'Broad policy-key deletion remains refused',
    'service changes or deletions require exact future allowlist',
    'no scheduled task mutation is approved in this phase',
    'mutable GitHub raw URL remains refused',
    'Current Default/Restore must remain unavailable'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "Edge Settings scope design is missing phrase: $requiredPhrase"
    }
}

foreach ($requiredField in @(
    'Intended mutation or launch type:',
    'Required foundation:',
    'Required future production allowlist:',
    'Required inventory/capture before mutation:',
    'Required confirmation level:',
    'Required verification:',
    'Rollback/restore feasibility:',
    'Risk level:',
    'Whether it can be implemented later:',
    'Whether it must remain refused:'
)) {
    if (-not $designText.Contains($requiredField)) {
        throw "Edge Settings scope design is missing per-group field: $requiredField"
    }
}

foreach ($requiredSourceTarget in @(
    'HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist',
    'odfafepnkmbhccpbejgmiehpchacaeak;https://edge.microsoft.com/extensionwebstorebase/v1/crx',
    'HKLM\SOFTWARE\Policies\Microsoft\Edge',
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
    'HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}',
    'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}',
    'msedge',
    'Stop-Process -Name "msedge" -Force -ErrorAction SilentlyContinue',
    'Start-Process "msedge.exe" -ArgumentList "--restore-last-session --disable-extensions"',
    'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe',
    '$env:SystemRoot\Temp\edge.exe',
    'IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe" -OutFile "$env:SystemRoot\Temp\edge.exe"',
    'Start-Process "$env:SystemRoot\Temp\edge.exe"'
)) {
    if (-not $designText.Contains($requiredSourceTarget)) {
        throw "Edge Settings scope design is missing source target: $requiredSourceTarget"
    }
}

$urls = [regex]::Matches($sourceText, 'https?://[^\s"`]+') |
    ForEach-Object { $_.Value } |
    Sort-Object -Unique
if (@($urls).Count -ne 2) {
    throw "Expected 2 Edge Settings source URLs, found $(@($urls).Count)."
}
foreach ($url in $urls) {
    if (-not $designText.Contains($url)) {
        throw "Edge Settings scope design is missing source URL: $url"
    }
}

$nonElevationStartProcess = @(
    [regex]::Matches($sourceText, 'Start-Process') |
        ForEach-Object { $_.Value }
).Count - 1
if ($nonElevationStartProcess -ne 2) {
    throw "Expected 2 non-elevation Start-Process calls, found $nonElevationStartProcess."
}
foreach ($commandSnippet in @(
    'Start-Process "msedge.exe"',
    'Start-Process "$env:SystemRoot\Temp\edge.exe"'
)) {
    if (-not $designText.Contains($commandSnippet)) {
        throw "Edge Settings scope design is missing Start-Process snippet: $commandSnippet"
    }
}

if ($sourceText -match 'Restart-Computer|shutdown\s|bcdedit') {
    throw 'Edge Settings source unexpectedly contains direct reboot or BCD behavior.'
}

if (-not $readinessText.Contains('docs/tool-designs/edge-settings-scope-design.md')) {
    throw 'Deferred readiness review does not link to the Edge Settings scope design.'
}
if (-not $planText.Contains('docs/tool-designs/edge-settings-scope-design.md')) {
    throw 'Deferred tools execution plan does not link to the Edge Settings scope design.'
}

if (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) {
    throw 'Edge Settings module is no longer a placeholder.'
}
if ($moduleText -match 'reg add|reg delete|Start-Process|IWR|Invoke-WebRequest|Stop-Process|Get-Service|sc stop|sc delete|Get-ScheduledTask|Unregister-ScheduledTask|Remove-Item|Remove-ItemProperty') {
    throw 'Edge Settings placeholder module appears to contain real mutation behavior.'
}

if ($artifactPolicy.Artifacts.Count -ne 0) {
    throw "Artifact approvals were added unexpectedly: $($artifactPolicy.Artifacts.Count)"
}
if ($cleanupPolicy.CleanupScopes.Count -ne 0) {
    throw "Cleanup production scopes were approved unexpectedly: $($cleanupPolicy.CleanupScopes.Count)"
}
if ($rollbackPolicy.FileScopes.Count -ne 0 -or $rollbackPolicy.RegistryScopes.Count -ne 0) {
    throw 'File or registry production scopes were approved unexpectedly.'
}
if ($servicePolicy.ServiceScopes.Count -ne 0) {
    throw "Service production scopes were approved unexpectedly: $($servicePolicy.ServiceScopes.Count)"
}
if ($rebootPolicy.WorkflowScopes.Count -ne 0) {
    throw "Reboot workflow production scopes were approved unexpectedly: $($rebootPolicy.WorkflowScopes.Count)"
}

$edgeSettingsTool = $allTools |
    Where-Object { $_.Id -eq 'edge-settings' -and $_.Stage -eq 'Setup' } |
    Select-Object -First 1
if (-not $edgeSettingsTool) {
    throw 'Edge Settings catalog entry was not found.'
}

$activeTools = @($allTools)
$placeholderModules = @(
    Get-ChildItem -Path (Join-Path $ProjectRoot 'modules') -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
if ($activeTools.Count -ne 48) {
    throw "Expected 48 active tools, found $($activeTools.Count)."
}
if ($placeholderModules.Count -ne 18) {
    throw "Expected 18 placeholder modules, found $($placeholderModules.Count)."
}
if (($activeTools.Count - $placeholderModules.Count) -ne 30) {
    throw "Expected 30 implemented tools, found $($activeTools.Count - $placeholderModules.Count)."
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
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

if (
    @($sourceLines).Count -ne 49 -or
    $manifestHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477'
) {
    throw 'source-ultimate content or paths changed.'
}

$loudnessPath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'
if (Test-Path -LiteralPath $loudnessPath) {
    throw 'Loudness EQ source was reintroduced.'
}
$nvmeSource = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
        Where-Object { $_.Name -like '*NVME Faster Driver*' }
)
if ($nvmeSource.Count -ne 0) {
    throw 'NVME Faster Driver source was reintroduced.'
}

[pscustomobject]@{
    Success                       = $true
    ToolId                        = 'edge-settings'
    SourceHash                    = $actualSourceHash
    ActiveToolCount               = $activeTools.Count
    ImplementedToolCount          = $activeTools.Count - $placeholderModules.Count
    PlaceholderToolCount          = $placeholderModules.Count
    ProductionArtifactApprovals   = $artifactPolicy.Artifacts.Count
    ProductionCleanupScopes       = $cleanupPolicy.CleanupScopes.Count
    ProductionFileScopes          = $rollbackPolicy.FileScopes.Count
    ProductionRegistryScopes      = $rollbackPolicy.RegistryScopes.Count
    ProductionServiceScopes       = $servicePolicy.ServiceScopes.Count
    ProductionRebootScopes        = $rebootPolicy.WorkflowScopes.Count
    SourceUltimateUnchanged       = $true
    DeletedToolsRemainDeleted     = $true
    Message                       = 'Edge Settings scope design is present, linked, and non-executing.'
    Timestamp                     = Get-Date
}
