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
        throw 'Unable to determine the Timer Resolution Assistant scope design validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$designPath = Join-Path $ProjectRoot 'docs\tool-designs\timer-resolution-assistant-scope-design.md'
$readinessPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\8 Advanced\6 Timer Resolution Assistant.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Advanced\timer-resolution-assistant.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$servicePolicyPath = Join-Path $ProjectRoot 'config\ServiceRollbackPolicy.psd1'
$rollbackPolicyPath = Join-Path $ProjectRoot 'config\RollbackPolicy.psd1'
$trustedPolicyPath = Join-Path $ProjectRoot 'config\TrustedInstallerPolicy.psd1'
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
$moduleText = Get-Content -LiteralPath $modulePath -Raw
$config = Import-PowerShellDataFile -LiteralPath $configPath
$servicePolicy = Import-PowerShellDataFile -LiteralPath $servicePolicyPath
$rollbackPolicy = Import-PowerShellDataFile -LiteralPath $rollbackPolicyPath
$trustedPolicy = Import-PowerShellDataFile -LiteralPath $trustedPolicyPath
$rebootPolicy = Import-PowerShellDataFile -LiteralPath $rebootPolicyPath
$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPolicyPath
$cleanupPolicy = Import-PowerShellDataFile -LiteralPath $cleanupPolicyPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })

$expectedSourceHash = '883F7CF4E6179383DE02E44B94FFC8DAFD380246751F1B1D81CAB8800B1E8621'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
if ($actualSourceHash -ne $expectedSourceHash) {
    throw "Timer Resolution Assistant source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."
}

foreach ($requiredSection in @(
    '# Timer Resolution Assistant Scope Design',
    '## Purpose',
    '## Source Reference',
    '## Source Behavior Summary',
    '## Current Decision',
    '## Behavior Groups',
    '### 1. Timer Service Identity and Naming',
    '### 2. Service Install/Configuration/Start/Stop/Delete Behavior',
    '### 3. LocalSystem Service Behavior',
    '### 4. C# Source Generation / Compilation Behavior',
    '### 5. Files Created Under Windows or Protected Paths',
    '### 6. Registry Timer Policy/Settings',
    '### 7. Task Manager / Process Verification Behavior',
    '### 8. Cleanup/Default Behavior',
    '### 9. Restore Behavior',
    '### 10. Service Identity Mismatch From Previous Refusal Notes',
    '### 11. Unsupported Compiler/Service/Protected-Path Targets',
    '## Exact Source Target Inventory',
    '## Future Safe Apply Requirements',
    '## Default and Restore Boundary',
    '## Production Approval State'
)) {
    if (-not $designText.Contains($requiredSection)) {
        throw "Timer Resolution Assistant scope design is missing section: $requiredSection"
    }
}

foreach ($requiredPhrase in @(
    'Source SHA-256: `883F7CF4E6179383DE02E44B94FFC8DAFD380246751F1B1D81CAB8800B1E8621`',
    'Timer Resolution Assistant remains a refused placeholder',
    'No production service/file/registry/compiler/LocalSystem/download/installer scopes',
    'The source contains no external download URL and no installer launch.',
    'LocalSystem service creation and C# compilation are high risk',
    'Unknown compiler, service, protected-path, and registry targets remain denied.',
    'Current Default/Restore must remain unavailable.',
    'Restore remains unavailable unless exact service rollback',
    'Set Timer Resolution Service',
    'STR',
    'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe',
    'C:\Windows\SetTimerResolutionService.cs',
    'C:\Windows\SetTimerResolutionService.exe',
    'GlobalTimerResolutionRequests',
    'NtSetTimerResolution',
    'NtQueryTimerResolution',
    'taskmgr.exe'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "Timer Resolution Assistant scope design is missing phrase: $requiredPhrase"
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
        throw "Timer Resolution Assistant scope design is missing per-group field: $requiredField"
    }
}

foreach ($requiredSourceTarget in @(
    'ServiceName = "STR"',
    'DisplayName = "Set Timer Resolution Service"',
    'ServiceAccount.LocalSystem',
    'Set-Content -Path "$env:SystemDrive\Windows\SetTimerResolutionService.cs"',
    'Start-Process -Wait "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"',
    '-out:C:\Windows\SetTimerResolutionService.exe C:\Windows\SetTimerResolutionService.cs',
    'Remove-Item "$env:SystemDrive\Windows\SetTimerResolutionService.cs"',
    'New-Service -Name "Set Timer Resolution Service"',
    'Set-Service -Name "Set Timer Resolution Service" -StartupType Auto',
    'Set-Service -Name "Set Timer Resolution Service" -Status Running',
    'Set-Service -Name "Set Timer Resolution Service" -StartupType Disabled',
    'Set-Service -Name "Set Timer Resolution Service" -Status Stopped',
    'sc.exe delete "Set Timer Resolution Service"',
    'reg add `"HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel`" /v `"GlobalTimerResolutionRequests`"',
    'reg delete `"HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel`" /v `"GlobalTimerResolutionRequests`"',
    'Start-Process taskmgr.exe'
)) {
    if (-not $sourceText.Contains($requiredSourceTarget)) {
        throw "Timer Resolution source is missing expected target: $requiredSourceTarget"
    }
}

foreach ($requiredDocTarget in @(
    'PowerShell service name: `Set Timer Resolution Service`',
    'C# service name: `STR`',
    'C# display name: `Set Timer Resolution Service`',
    'Generated source file: `C:\Windows\SetTimerResolutionService.cs`',
    'Generated executable: `C:\Windows\SetTimerResolutionService.exe`',
    'Compiler: `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe`',
    'Registry value:',
    'Verification UI launcher: `taskmgr.exe`'
)) {
    if (-not $designText.Contains($requiredDocTarget)) {
        throw "Timer Resolution scope design is missing documented source target: $requiredDocTarget"
    }
}

if ($sourceText -match 'https?://|Invoke-WebRequest|Start-BitsTransfer|curl\.exe|msiexec') {
    throw 'Timer Resolution Assistant source unexpectedly contains download or installer behavior.'
}
if (-not $sourceText.Contains('ServiceProcessInstaller serviceProcessInstaller')) {
    throw 'Timer Resolution source no longer contains expected C# service installer code.'
}
if (-not $sourceText.Contains('ServiceAccount.LocalSystem')) {
    throw 'Timer Resolution source no longer contains expected LocalSystem metadata.'
}

if (-not $readinessText.Contains('docs/tool-designs/timer-resolution-assistant-scope-design.md')) {
    throw 'Deferred readiness review does not link to the Timer Resolution Assistant scope design.'
}
if (-not $planText.Contains('docs/tool-designs/timer-resolution-assistant-scope-design.md')) {
    throw 'Deferred tools execution plan does not link to the Timer Resolution Assistant scope design.'
}

if (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) {
    throw 'Timer Resolution Assistant module is no longer a placeholder.'
}
if ($moduleText -match 'New-Service|Set-Service|sc\.exe|csc\.exe|SetTimerResolutionService|GlobalTimerResolutionRequests|Start-Process|Remove-Item|Set-Content') {
    throw 'Timer Resolution Assistant placeholder module appears to contain real mutation behavior.'
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
    Where-Object { $_.Id -eq 'timer-resolution-assistant' -and $_.Stage -eq 'Advanced' } |
    Select-Object -First 1
if (-not $tool) {
    throw 'Timer Resolution Assistant catalog entry was not found.'
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
    Success                    = $true
    ToolId                     = 'timer-resolution-assistant'
    SourceHash                 = $actualSourceHash
    ServiceName                = 'Set Timer Resolution Service'
    InternalServiceName        = 'STR'
    ActiveToolCount            = $activeTools.Count
    ImplementedToolCount       = $activeTools.Count - $placeholderModules.Count
    PlaceholderToolCount       = $placeholderModules.Count
    ProductionServiceScopes    = $servicePolicy.ServiceScopes.Count
    ProductionFileScopes       = $rollbackPolicy.FileScopes.Count
    ProductionRegistryScopes   = $rollbackPolicy.RegistryScopes.Count
    ProductionTrustedScopes    = $trustedPolicy.TrustedInstallerScopes.Count
    ProductionRebootScopes     = $rebootPolicy.WorkflowScopes.Count
    ArtifactApprovals          = $artifactPolicy.Artifacts.Count
    SourceUltimateUnchanged    = $true
    DeletedToolsRemainDeleted  = $true
    Message                    = 'Timer Resolution Assistant scope design is present, linked, and non-executing.'
    Timestamp                  = Get-Date
}


