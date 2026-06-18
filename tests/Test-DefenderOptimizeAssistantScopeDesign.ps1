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
        throw 'Unable to determine the Defender Optimize Assistant scope design validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$designPath = Join-Path $ProjectRoot 'docs\tool-designs\defender-optimize-assistant-scope-design.md'
$readinessPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\8 Advanced\7 Defender Optimize Assistant.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Advanced\defender-optimize-assistant.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$servicePolicyPath = Join-Path $ProjectRoot 'config\ServiceRollbackPolicy.psd1'
$rollbackPolicyPath = Join-Path $ProjectRoot 'config\RollbackPolicy.psd1'
$trustedPolicyPath = Join-Path $ProjectRoot 'config\TrustedInstallerPolicy.psd1'
$safeModePolicyPath = Join-Path $ProjectRoot 'config\SafeModeRecoveryPolicy.psd1'
$rebootPolicyPath = Join-Path $ProjectRoot 'config\RebootRecoveryPolicy.psd1'
$artifactPolicyPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$cleanupPolicyPath = Join-Path $ProjectRoot 'config\CleanupPolicy.psd1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

foreach ($path in @(
    $designPath,
    $readinessPath,
    $planPath,
    $sourcePath,
    $modulePath,
    $configPath,
    $servicePolicyPath,
    $rollbackPolicyPath,
    $trustedPolicyPath,
    $safeModePolicyPath,
    $rebootPolicyPath,
    $artifactPolicyPath,
    $cleanupPolicyPath
)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file was not found: $path"
    }
}

$designText = Get-Content -LiteralPath $designPath -Raw
$readinessText = Get-Content -LiteralPath $readinessPath -Raw
$planText = Get-Content -LiteralPath $planPath -Raw
$sourceText = Get-Content -LiteralPath $sourcePath -Raw
$sourceLines = Get-Content -LiteralPath $sourcePath
$moduleText = Get-Content -LiteralPath $modulePath -Raw
$config = Import-PowerShellDataFile -LiteralPath $configPath
$servicePolicy = Import-PowerShellDataFile -LiteralPath $servicePolicyPath
$rollbackPolicy = Import-PowerShellDataFile -LiteralPath $rollbackPolicyPath
$trustedPolicy = Import-PowerShellDataFile -LiteralPath $trustedPolicyPath
$safeModePolicy = Import-PowerShellDataFile -LiteralPath $safeModePolicyPath
$rebootPolicy = Import-PowerShellDataFile -LiteralPath $rebootPolicyPath
$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPolicyPath
$cleanupPolicy = Import-PowerShellDataFile -LiteralPath $cleanupPolicyPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })

$expectedSourceHash = '512F12D805715E9232304ABE5BA400BE6B3965D63F77D3B39E4C304507BFB9B6'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
if ($actualSourceHash -ne $expectedSourceHash) {
    throw "Defender Optimize Assistant source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."
}

foreach ($requiredSection in @(
    '# Defender Optimize Assistant Scope Design',
    '## Purpose',
    '## Source Reference',
    '## Source Behavior Summary',
    '## Current Decision',
    '## Behavior Groups',
    '### 1. Defender Service Configuration',
    '### 2. Defender Process Handling',
    '### 3. Defender Registry Policy/Settings',
    '### 4. Tamper Protection or Protected Setting Boundaries',
    '### 5. Scheduled Task Behavior',
    '### 6. TrustedInstaller-Required Operations',
    '### 7. Safe Mode Entry/Resume Behavior',
    '### 8. RunOnce Behavior',
    '### 9. BCD Behavior',
    '### 10. Temporary Script or REG File Behavior',
    '### 11. Restore Point Behavior',
    '### 12. Reboot Sequencing',
    '### 13. Downloads/Installers If Present',
    '### 14. Default/Restore Behavior',
    '### 15. Unsupported Broad or Security-Sensitive Targets',
    '## Exact Registry Path Inventory',
    '## Future Safe Apply Requirements',
    '## Default and Restore Boundary',
    '## Production Approval State'
)) {
    if (-not $designText.Contains($requiredSection)) {
        throw "Defender Optimize Assistant scope design is missing section: $requiredSection"
    }
}

foreach ($requiredPhrase in @(
    'Source SHA-256: `512F12D805715E9232304ABE5BA400BE6B3965D63F77D3B39E4C304507BFB9B6`',
    'Defender Optimize Assistant remains a refused placeholder',
    'No production Defender/service/registry/file/reboot/Safe Mode/TrustedInstaller/download/installer scopes',
    'The source contains no external download URL and no installer launch.',
    'Optimize is security-reducing',
    'Unknown or wildcard Defender/security targets remain denied.',
    'Current Default/Restore must remain unavailable.',
    'Restore remains unavailable unless exact service rollback',
    'RunOnce',
    'bcdedit /set {current} safeboot minimal',
    'shutdown -r -t 00',
    'Run-Trusted',
    'TamperProtection',
    'VulnerableDriverBlocklistEnable'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "Defender Optimize Assistant scope design is missing phrase: $requiredPhrase"
    }
}

foreach ($requiredField in @(
    'Intended mutation type:',
    'Required foundation:',
    'Required future production allowlist:',
    'Required inventory/capture before mutation:',
    'Required confirmation level:',
    'Required verification:',
    'Rollback/restore feasibility:',
    'Risk level:',
    'Later implementation decision:'
)) {
    if (-not $designText.Contains($requiredField)) {
        throw "Defender Optimize Assistant scope design is missing per-group field: $requiredField"
    }
}

foreach ($requiredSourceTarget in @(
    'HKLM\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection',
    'HKLM\SOFTWARE\Microsoft\Windows Defender\Spynet',
    'HKLM\SOFTWARE\Microsoft\Windows Defender\Features',
    'HKLM\SOFTWARE\Microsoft\Windows Defender\Windows Defender Exploit Guard\Controlled Folder Access',
    'HKLM\SOFTWARE\Microsoft\Windows Defender Security Center\Notifications',
    'HKCU\SOFTWARE\Microsoft\Windows Defender Security Center\Account protection',
    'HKLM\System\ControlSet001\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity',
    'HKLM\SYSTEM\CurrentControlSet\Control\Lsa',
    'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
    'HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard',
    'Microsoft\Windows\ExploitGuard\ExploitGuard MDM policy Refresh',
    'Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan',
    '%SystemRoot%\Temp\defenderoptimize.ps1',
    '%SystemRoot%\Temp\defenderdefault.ps1',
    '*defenderoptimize',
    '*defenderdefault',
    'allowedinmemorysettings',
    'isolatedcontext',
    'hypervisorlaunchtype'
)) {
    if (-not $designText.Contains($requiredSourceTarget)) {
        throw "Defender Optimize Assistant scope design is missing source target: $requiredSourceTarget"
    }
}

$registryLines = @($sourceLines | Where-Object { $_ -match 'reg (add|delete) `"' })
if ($registryLines.Count -ne 85) {
    throw "Expected 85 registry command lines, found $($registryLines.Count)."
}

$registryPaths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($line in $registryLines) {
    $match = [regex]::Match($line, 'reg (?:add|delete) `\"(?<path>[^`]+?)`\"')
    if ($match.Success) {
        [void]$registryPaths.Add($match.Groups['path'].Value)
    }
}
if ($registryPaths.Count -ne 25) {
    throw "Expected 25 unique registry paths, found $($registryPaths.Count)."
}
foreach ($registryPath in $registryPaths) {
    $canonical = $registryPath `
        -replace '^HKEY_LOCAL_MACHINE', 'HKLM' `
        -replace '^HKEY_CURRENT_USER', 'HKCU'
    if (-not $designText.Contains($canonical) -and -not $designText.Contains($registryPath)) {
        throw "Defender Optimize Assistant scope design is missing registry path: $registryPath"
    }
}

$taskMatches = @(
    Select-String -Path $sourcePath -Pattern 'schtasks /Change /TN "([^"]+)" /(Disable|Enable)' |
        ForEach-Object { $_.Matches[0].Groups[1].Value } |
        Sort-Object -Unique
)
if ($taskMatches.Count -ne 5) {
    throw "Expected 5 unique scheduled task targets, found $($taskMatches.Count)."
}
foreach ($taskName in $taskMatches) {
    if (-not $designText.Contains($taskName)) {
        throw "Defender Optimize Assistant scope design is missing scheduled task: $taskName"
    }
}

if ($sourceText -match 'https?://|Invoke-WebRequest|Start-BitsTransfer|curl\.exe|msiexec') {
    throw 'Defender Optimize Assistant source unexpectedly contains download or installer behavior.'
}

if (-not $sourceText.Contains('sc.exe config TrustedInstaller binPath=')) {
    throw 'Defender Optimize Assistant source no longer contains expected TrustedInstaller binPath behavior.'
}
if (-not $sourceText.Contains('bcdedit /set {current} safeboot minimal')) {
    throw 'Defender Optimize Assistant source no longer contains expected Safe Mode BCD behavior.'
}

if (-not $readinessText.Contains('docs/tool-designs/defender-optimize-assistant-scope-design.md')) {
    throw 'Deferred readiness review does not link to the Defender Optimize Assistant scope design.'
}
if (-not $planText.Contains('docs/tool-designs/defender-optimize-assistant-scope-design.md')) {
    throw 'Deferred tools execution plan does not link to the Defender Optimize Assistant scope design.'
}

if (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) {
    throw 'Defender Optimize Assistant module is no longer a placeholder.'
}
if ($moduleText -match 'Stop-Service|sc\.exe|bcdedit|shutdown|Regedit|Set-Content|RunOnce|TrustedInstaller|schtasks|Windows Defender') {
    throw 'Defender Optimize Assistant placeholder module appears to contain real mutation behavior.'
}

if ($servicePolicy.ServiceScopes.Count -ne 0) {
    throw "Service production scopes were approved unexpectedly: $($servicePolicy.ServiceScopes.Count)"
}
if ($rollbackPolicy.FileScopes.Count -ne 0 -or $rollbackPolicy.RegistryScopes.Count -ne 0) {
    throw 'File or registry production scopes were approved unexpectedly.'
}
if ($trustedPolicy.TrustedInstallerScopes.Count -ne 0) {
    throw "TrustedInstaller production scopes were approved unexpectedly: $($trustedPolicy.TrustedInstallerScopes.Count)"
}
if ($safeModePolicy.SafeModeScopes.Count -ne 0) {
    throw "Safe Mode production scopes were approved unexpectedly: $($safeModePolicy.SafeModeScopes.Count)"
}
if ($rebootPolicy.WorkflowScopes.Count -ne 0) {
    throw "Reboot workflow production scopes were approved unexpectedly: $($rebootPolicy.WorkflowScopes.Count)"
}
if ($artifactPolicy.Artifacts.Count -ne 0) {
    throw "Artifact approvals were added unexpectedly: $($artifactPolicy.Artifacts.Count)"
}
if ($cleanupPolicy.CleanupScopes.Count -ne 0) {
    throw "Cleanup production scopes were approved unexpectedly: $($cleanupPolicy.CleanupScopes.Count)"
}

$tool = $allTools |
    Where-Object { $_.Id -eq 'defender-optimize-assistant' -and $_.Stage -eq 'Advanced' } |
    Select-Object -First 1
if (-not $tool) {
    throw 'Defender Optimize Assistant catalog entry was not found.'
}

$activeTools = @($allTools)
$placeholderModules = @(
    Get-ChildItem -Path (Join-Path $ProjectRoot 'modules') -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
if ($activeTools.Count -ne 55) {
    throw "Expected 55 active tools, found $($activeTools.Count)."
}
if ($placeholderModules.Count -ne 16) {
    throw "Expected 16 placeholder modules, found $($placeholderModules.Count)."
}
if (($activeTools.Count - $placeholderModules.Count) -ne 39) {
    throw "Expected 39 implemented tools, found $($activeTools.Count - $placeholderModules.Count)."
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
    Success                          = $true
    ToolId                           = 'defender-optimize-assistant'
    SourceHash                       = $actualSourceHash
    RegistryCommandCount             = $registryLines.Count
    RegistryPathCount                = $registryPaths.Count
    ScheduledTaskTargetCount         = $taskMatches.Count
    ActiveToolCount                  = $activeTools.Count
    ImplementedToolCount             = $activeTools.Count - $placeholderModules.Count
    PlaceholderToolCount             = $placeholderModules.Count
    ProductionServiceScopes          = $servicePolicy.ServiceScopes.Count
    ProductionFileScopes             = $rollbackPolicy.FileScopes.Count
    ProductionRegistryScopes         = $rollbackPolicy.RegistryScopes.Count
    ProductionTrustedInstallerScopes = $trustedPolicy.TrustedInstallerScopes.Count
    ProductionSafeModeScopes         = $safeModePolicy.SafeModeScopes.Count
    ProductionRebootScopes           = $rebootPolicy.WorkflowScopes.Count
    ArtifactApprovals                = $artifactPolicy.Artifacts.Count
    SourceUltimateUnchanged          = $true
    DeletedToolsRemainDeleted        = $true
    Message                          = 'Defender Optimize Assistant scope design is present, linked, and non-executing.'
    Timestamp                        = Get-Date
}




