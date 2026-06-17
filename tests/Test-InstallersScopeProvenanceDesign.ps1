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
        throw 'Unable to determine the Installers scope/provenance design validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$designPath = Join-Path $ProjectRoot 'docs\tool-designs\installers-scope-provenance-design.md'
$readinessPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\4 Installers\1 Installers.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Installers\installers.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$artifactPolicyPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$rollbackPolicyPath = Join-Path $ProjectRoot 'config\RollbackPolicy.psd1'
$servicePolicyPath = Join-Path $ProjectRoot 'config\ServiceRollbackPolicy.psd1'
$cleanupPolicyPath = Join-Path $ProjectRoot 'config\CleanupPolicy.psd1'
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
    $rollbackPolicyPath,
    $servicePolicyPath,
    $cleanupPolicyPath,
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
$rollbackPolicy = Import-PowerShellDataFile -LiteralPath $rollbackPolicyPath
$servicePolicy = Import-PowerShellDataFile -LiteralPath $servicePolicyPath
$cleanupPolicy = Import-PowerShellDataFile -LiteralPath $cleanupPolicyPath
$rebootPolicy = Import-PowerShellDataFile -LiteralPath $rebootPolicyPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })

$expectedSourceHash = '1065D64183457D4E7B28EA78DDE41525EC8F7C4A4BCA12D29B70D991141C0C67'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
if ($actualSourceHash -ne $expectedSourceHash) {
    throw "Installers source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."
}

foreach ($requiredSection in @(
    '# Installers Scope and Provenance Design',
    '## Purpose',
    '## Source Reference',
    '## Product Scope Decision',
    '## Source Behavior Summary',
    '## Current Decision',
    '## Behavior Groups',
    '### 1. Downloaded Installer Artifacts',
    '### 2. Portable Tool Downloads If Present',
    '### 3. Installer Executable Launches',
    '### 4. Silent Install Arguments',
    '### 5. Registry Policy/Settings Changes',
    '### 6. Service Changes If Present',
    '### 7. Scheduled Task Changes If Present',
    '### 8. Shortcut Creation/Deletion Behavior',
    '### 9. Config File Creation/Modification Behavior',
    '### 10. Uninstall/Removal Behavior If Present',
    '### 11. NVIDIA App / FrameView Behavior If Present',
    '### 12. Reboot/Restart Behavior If Present',
    '### 13. Default/Restore Behavior If Present',
    '### 14. Unsupported Unverified Artifacts or Broad Installer Targets',
    '## Exact Source Target Inventory',
    '## Future Safe Apply/Open/Install Requirements',
    '## Default and Restore Boundary',
    '## Production Approval State'
)) {
    if (-not $designText.Contains($requiredSection)) {
        throw "Installers scope/provenance design is missing section: $requiredSection"
    }
}

foreach ($requiredPhrase in @(
    'Source SHA-256: `1065D64183457D4E7B28EA78DDE41525EC8F7C4A4BCA12D29B70D991141C0C67`',
    'Installers remains a refused placeholder',
    'No production download/installer/executable/registry/file/service/task/shortcut/config/uninstall/reboot scopes',
    'Download URL count: `24`',
    'Explicit AMD/Intel GPU-specific behavior is not present',
    'Frame View',
    'Nvidia App',
    'silent arguments',
    'EULAs',
    'bundled components',
    'network dependency',
    'uninstall limitations',
    'scheduled task governance',
    'Current Default/Restore must remain unavailable',
    'Artifact approvals: none.'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "Installers scope/provenance design is missing phrase: $requiredPhrase"
    }
}

foreach ($requiredField in @(
    'Exact source targets:',
    'Intended mutation or launch type:',
    'Required foundation:',
    'Required future production allowlist:',
    'Required provenance before download/launch:',
    'Required inventory/capture before mutation:',
    'Required confirmation level:',
    'Required verification:',
    'Rollback/restore feasibility:',
    'Risk level:',
    'Later implementation decision:'
)) {
    if (-not $designText.Contains($requiredField)) {
        throw "Installers scope/provenance design is missing per-group field: $requiredField"
    }
}

$downloadUrls = @(
    Select-String -LiteralPath $sourcePath -Pattern 'IWR "([^"]+)"' |
        ForEach-Object { $_.Matches[0].Groups[1].Value } |
        Sort-Object -Unique
)
if ($downloadUrls.Count -ne 24) {
    throw "Expected 24 unique Installers download URLs, found $($downloadUrls.Count)."
}
foreach ($url in $downloadUrls) {
    if (-not $designText.Contains($url)) {
        throw "Installers scope/provenance design is missing source URL: $url"
    }
}

$launchLines = @(
    Select-String -LiteralPath $sourcePath -Pattern 'Start-Process[^\r\n]+' |
        ForEach-Object { $_.Matches[0].Value } |
        Where-Object { $_ -notmatch 'PowerShell\.exe' }
)
if ($launchLines.Count -ne 26) {
    throw "Expected 26 source installer/helper launch lines, found $($launchLines.Count)."
}
foreach ($line in $launchLines) {
    if (-not $designText.Contains($line)) {
        throw "Installers scope/provenance design is missing source launch command: $line"
    }
}

foreach ($requiredSourceTarget in @(
    'Test-Connection -ComputerName "8.8.8.8"',
    'Write-Host " 2. Discord"',
    'Write-Host "24. Valorant`n"',
    '$env:APPDATA\discord\settings.json',
    '$env:APPDATA\Spotify\prefs',
    '$env:AppData\Notepad++\config.xml',
    'C:\Program Files\Mozilla Firefox\distribution\extensions',
    'HKLM:\Software\Microsoft\Active Setup\Installed Components',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'Get-Service | Where-Object { $_.Name -match ''Brave'' }',
    'Get-Service | Where-Object { $_.Name -match ''Google'' }',
    'Get-ScheduledTask | Where-Object { $_.TaskName -like ''*Brave*'' }',
    'Get-ScheduledTask | Where-Object {$_.Taskname -match ''Firefox''}',
    'Get-ScheduledTask | Where-Object { $_.TaskName -like ''*Google*'' }',
    'sc stop',
    'sc delete',
    'msiexec.exe /x $guid /qn'
)) {
    if (-not $designText.Contains($requiredSourceTarget)) {
        throw "Installers scope/provenance design is missing source target: $requiredSourceTarget"
    }
}

if ($sourceText -match 'shutdown|Restart-Computer|bcdedit|RunOnce|schtasks') {
    throw 'Installers source unexpectedly contains direct reboot, BCD, RunOnce, or schtasks command behavior.'
}

if (-not $readinessText.Contains('docs/tool-designs/installers-scope-provenance-design.md')) {
    throw 'Deferred readiness review does not link to the Installers scope/provenance design.'
}
if (-not $planText.Contains('docs/tool-designs/installers-scope-provenance-design.md')) {
    throw 'Deferred tools execution plan does not link to the Installers scope/provenance design.'
}

if (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) {
    throw 'Installers module is no longer a placeholder.'
}
if ($moduleText -match 'IWR|Invoke-WebRequest|Start-BitsTransfer|Start-Process|msiexec|Get-Service|Get-ScheduledTask|reg add|reg delete|Remove-Item|Move-Item|Set-Content') {
    throw 'Installers placeholder module appears to contain real download, launch, or mutation behavior.'
}

if (@($artifactPolicy.Artifacts).Count -ne 0) {
    throw "Artifact approvals were added unexpectedly: $(@($artifactPolicy.Artifacts).Count)"
}
if (@($rollbackPolicy.FileScopes).Count -ne 0 -or @($rollbackPolicy.RegistryScopes).Count -ne 0) {
    throw 'File or registry production scopes were approved unexpectedly.'
}
if (@($servicePolicy.ServiceScopes).Count -ne 0) {
    throw "Service production scopes were approved unexpectedly: $(@($servicePolicy.ServiceScopes).Count)"
}
if (@($cleanupPolicy.CleanupScopes).Count -ne 0) {
    throw "Cleanup production scopes were approved unexpectedly: $(@($cleanupPolicy.CleanupScopes).Count)"
}
if (@($rebootPolicy.WorkflowScopes).Count -ne 0) {
    throw "Reboot workflow production scopes were approved unexpectedly: $(@($rebootPolicy.WorkflowScopes).Count)"
}

$tool = $allTools |
    Where-Object { $_.Id -eq 'installers' -and $_.Stage -eq 'Installers' } |
    Select-Object -First 1
if (-not $tool) {
    throw 'Installers catalog entry was not found.'
}
if (-not (@($tool.Actions) -contains 'Open') -or -not (@($tool.Actions) -contains 'Apply')) {
    throw 'Installers catalog actions changed unexpectedly.'
}

$activeTools = @($allTools)
$placeholderModules = @(
    Get-ChildItem -Path (Join-Path $ProjectRoot 'modules') -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
if ($activeTools.Count -ne 53) {
    throw "Expected 53 active tools, found $($activeTools.Count)."
}
if ($placeholderModules.Count -ne 18) {
    throw "Expected 18 placeholder modules, found $($placeholderModules.Count)."
}
if (($activeTools.Count - $placeholderModules.Count) -ne 35) {
    throw "Expected 35 implemented tools, found $($activeTools.Count - $placeholderModules.Count)."
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceManifestLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
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

if (
    @($sourceManifestLines).Count -ne 49 -or
    $manifestHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477'
) {
    throw 'source-ultimate content or paths changed.'
}

$loudnessPath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'
if (Test-Path -LiteralPath $loudnessPath) {
    throw 'Loudness EQ source was reintroduced.'
}
$nvmeSource = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Where-Object { $_.Name -like '*NVME Faster Driver*' }
)
if ($nvmeSource.Count -ne 0) {
    throw 'NVME Faster Driver source was reintroduced.'
}

[pscustomobject]@{
    Success                   = $true
    ToolId                    = 'installers'
    SourceHash                = $actualSourceHash
    DownloadUrlCount          = $downloadUrls.Count
    LaunchCommandCount        = $launchLines.Count
    ActiveToolCount           = $activeTools.Count
    ImplementedToolCount      = $activeTools.Count - $placeholderModules.Count
    PlaceholderToolCount      = $placeholderModules.Count
    ArtifactApprovals         = @($artifactPolicy.Artifacts).Count
    ProductionFileScopes      = @($rollbackPolicy.FileScopes).Count
    ProductionRegistryScopes  = @($rollbackPolicy.RegistryScopes).Count
    ProductionServiceScopes   = @($servicePolicy.ServiceScopes).Count
    ProductionCleanupScopes   = @($cleanupPolicy.CleanupScopes).Count
    ProductionRebootScopes    = @($rebootPolicy.WorkflowScopes).Count
    SourceUltimateUnchanged   = $true
    DeletedToolsRemainDeleted = $true
    Message                   = 'Installers scope/provenance design is present, linked, and non-executing.'
    Timestamp                 = Get-Date
}


