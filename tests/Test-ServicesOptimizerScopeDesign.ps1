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
        throw 'Unable to determine the Services Optimizer scope design validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$designPath = Join-Path $ProjectRoot 'docs\tool-designs\services-optimizer-scope-design.md'
$readinessPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\8 Advanced\5 Services Optimizer.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Advanced\services-optimizer.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$servicePolicyPath = Join-Path $ProjectRoot 'config\ServiceRollbackPolicy.psd1'
$rollbackPolicyPath = Join-Path $ProjectRoot 'config\RollbackPolicy.psd1'
$trustedPolicyPath = Join-Path $ProjectRoot 'config\TrustedInstallerPolicy.psd1'
$safeModePolicyPath = Join-Path $ProjectRoot 'config\SafeModeRecoveryPolicy.psd1'
$rebootPolicyPath = Join-Path $ProjectRoot 'config\RebootRecoveryPolicy.psd1'
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
$sourceLines = Get-Content -LiteralPath $sourcePath
$moduleText = Get-Content -LiteralPath $modulePath -Raw
$config = Import-PowerShellDataFile -LiteralPath $configPath
$servicePolicy = Import-PowerShellDataFile -LiteralPath $servicePolicyPath
$rollbackPolicy = Import-PowerShellDataFile -LiteralPath $rollbackPolicyPath
$trustedPolicy = Import-PowerShellDataFile -LiteralPath $trustedPolicyPath
$safeModePolicy = Import-PowerShellDataFile -LiteralPath $safeModePolicyPath
$rebootPolicy = Import-PowerShellDataFile -LiteralPath $rebootPolicyPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })

$expectedSourceHash = '386EEF403F48907E82C2E8E4BE5DFE509B0ED93CADBB5639B42D6326163EDB8F'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
if ($actualSourceHash -ne $expectedSourceHash) {
    throw "Services Optimizer source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."
}

foreach ($requiredSection in @(
    '# Services Optimizer Scope Design',
    '## Purpose',
    '## Source Reference',
    '## Source Behavior Summary',
    '## Current Decision',
    '## Behavior Groups',
    '### 1. Service Configuration Changes',
    '### 2. Service Stop/Start Behavior',
    '### 3. Service Deletion Behavior If Present',
    '### 4. Registry Service Key Mutations',
    '### 5. TrustedInstaller-Required Operations',
    '### 6. Safe Mode Entry/Resume Behavior',
    '### 7. RunOnce Behavior',
    '### 8. BCD Behavior',
    '### 9. Temporary Script or REG File Behavior',
    '### 10. Restore Point Behavior',
    '### 11. Reboot Sequencing',
    '### 12. Default/Restore Behavior',
    '### 13. Unsupported Broad or Dynamic Service Targets',
    '## Exact Active Service Target List',
    '## Future Safe Apply Requirements',
    '## Default and Restore Boundary',
    '## Production Approval State'
)) {
    if (-not $designText.Contains($requiredSection)) {
        throw "Services Optimizer scope design is missing section: $requiredSection"
    }
}

foreach ($requiredPhrase in @(
    'Source SHA-256: `386EEF403F48907E82C2E8E4BE5DFE509B0ED93CADBB5639B42D6326163EDB8F`',
    'Services Optimizer remains a refused placeholder',
    'No production service/registry/file/reboot/Safe Mode/TrustedInstaller scopes',
    'Active source target count: `273` services',
    'Unknown or wildcard service targets remain denied',
    'Dynamic broad service mutation remains refused',
    'No commented source entries may become active without explicit approval',
    'Current Default/Restore must remain unavailable',
    'Restore remains unavailable unless exact service rollback',
    'RunOnce',
    'bcdedit /set {current} safeboot minimal',
    'shutdown -r -t 00',
    'Run-Trusted',
    'SystemRestorePointCreationFrequency'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "Services Optimizer scope design is missing phrase: $requiredPhrase"
    }
}

foreach ($requiredField in @(
    'Target type:',
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
        throw "Services Optimizer scope design is missing per-group field: $requiredField"
    }
}

foreach ($requiredSourceTarget in @(
    'HKLM\SYSTEM\ControlSet001\Services\<ServiceName>',
    'TrustedInstaller',
    'trustedinstaller.exe',
    'Regedit.exe /S "%SystemRoot%\Temp\servicesoff.reg"',
    'Regedit.exe /S "%SystemRoot%\Temp\serviceson.reg"',
    'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
    '*servicesoff',
    '*serviceson',
    '%SystemRoot%\Temp\servicesoff.ps1',
    '%SystemRoot%\Temp\servicesoff.reg',
    '%SystemRoot%\Temp\serviceson.ps1',
    '%SystemRoot%\Temp\serviceson.reg',
    'Enable-ComputerRestore -Drive "C:\"',
    'Checkpoint-Computer -Description "beforeservices" -RestorePointType "MODIFY_SETTINGS"',
    'MDCoreSvc',
    'WinDefend',
    'wscsvc'
)) {
    if (-not $designText.Contains($requiredSourceTarget)) {
        throw "Services Optimizer scope design is missing source target: $requiredSourceTarget"
    }
}

$activeServiceNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$commentedServiceNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($line in $sourceLines) {
    if ($line -match '^(\s*;\s*)?\[HKEY_LOCAL_MACHINE\\SYSTEM\\(?:ControlSet001|CurrentControlSet)\\Services\\([^\]]+)\]') {
        if ([string]::IsNullOrWhiteSpace($matches[1])) {
            [void]$activeServiceNames.Add($matches[2])
        }
        else {
            [void]$commentedServiceNames.Add($matches[2])
        }
    }
}

if ($activeServiceNames.Count -ne 273) {
    throw "Expected 273 active source service targets, found $($activeServiceNames.Count)."
}
if ($commentedServiceNames.Count -ne 8) {
    throw "Expected 8 commented source service targets, found $($commentedServiceNames.Count)."
}

foreach ($serviceName in $activeServiceNames) {
    if (-not $designText.Contains($serviceName)) {
        throw "Services Optimizer scope design is missing active source service name: $serviceName"
    }
}
foreach ($serviceName in $commentedServiceNames) {
    if (-not $designText.Contains($serviceName)) {
        throw "Services Optimizer scope design is missing commented source service name: $serviceName"
    }
}

if (-not $sourceText.Contains('sc.exe config TrustedInstaller binPath=')) {
    throw 'Services Optimizer source no longer contains expected TrustedInstaller binPath behavior.'
}
if (-not $sourceText.Contains('bcdedit /set {current} safeboot minimal')) {
    throw 'Services Optimizer source no longer contains expected Safe Mode BCD behavior.'
}

if (-not $readinessText.Contains('docs/tool-designs/services-optimizer-scope-design.md')) {
    throw 'Deferred readiness review does not link to the Services Optimizer scope design.'
}
if (-not $planText.Contains('docs/tool-designs/services-optimizer-scope-design.md')) {
    throw 'Deferred tools execution plan does not link to the Services Optimizer scope design.'
}

if (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) {
    throw 'Services Optimizer module is no longer a placeholder.'
}
if ($moduleText -match 'Stop-Service|sc\.exe|bcdedit|shutdown|Regedit|Set-Content|RunOnce|TrustedInstaller') {
    throw 'Services Optimizer placeholder module appears to contain real mutation behavior.'
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

$tool = $allTools |
    Where-Object { $_.Id -eq 'services-optimizer' -and $_.Stage -eq 'Advanced' } |
    Select-Object -First 1
if (-not $tool) {
    throw 'Services Optimizer catalog entry was not found.'
}

$activeTools = @($allTools)
$placeholderModules = @(
    Get-ChildItem -Path (Join-Path $ProjectRoot 'modules') -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
if ($activeTools.Count -ne 55) {
    throw "Expected 55 active tools, found $($activeTools.Count)."
}
if ($placeholderModules.Count -ne 18) {
    throw "Expected 18 placeholder modules, found $($placeholderModules.Count)."
}
if (($activeTools.Count - $placeholderModules.Count) -ne 37) {
    throw "Expected 37 implemented tools, found $($activeTools.Count - $placeholderModules.Count)."
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
    Success                         = $true
    ToolId                          = 'services-optimizer'
    SourceHash                      = $actualSourceHash
    ActiveServiceTargetCount        = $activeServiceNames.Count
    CommentedServiceTargetCount     = $commentedServiceNames.Count
    ActiveToolCount                 = $activeTools.Count
    ImplementedToolCount            = $activeTools.Count - $placeholderModules.Count
    PlaceholderToolCount            = $placeholderModules.Count
    ProductionServiceScopes         = $servicePolicy.ServiceScopes.Count
    ProductionFileScopes            = $rollbackPolicy.FileScopes.Count
    ProductionRegistryScopes        = $rollbackPolicy.RegistryScopes.Count
    ProductionTrustedInstallerScopes = $trustedPolicy.TrustedInstallerScopes.Count
    ProductionSafeModeScopes        = $safeModePolicy.SafeModeScopes.Count
    ProductionRebootScopes          = $rebootPolicy.WorkflowScopes.Count
    SourceUltimateUnchanged         = $true
    DeletedToolsRemainDeleted       = $true
    Message                         = 'Services Optimizer scope design is present, linked, and non-executing.'
    Timestamp                       = Get-Date
}



