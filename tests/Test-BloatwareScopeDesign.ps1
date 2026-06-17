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
        throw 'Unable to determine the Bloatware scope design validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$designPath = Join-Path $ProjectRoot 'docs\tool-designs\bloatware-scope-design.md'
$readinessPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\11 Bloatware.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\bloatware.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$appxPolicyPath = Join-Path $ProjectRoot 'config\AppxPackagePolicy.psd1'
$cleanupPolicyPath = Join-Path $ProjectRoot 'config\CleanupPolicy.psd1'
$rollbackPolicyPath = Join-Path $ProjectRoot 'config\RollbackPolicy.psd1'
$servicePolicyPath = Join-Path $ProjectRoot 'config\ServiceRollbackPolicy.psd1'
$artifactPolicyPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

foreach ($path in @(
    $designPath,
    $readinessPath,
    $planPath,
    $sourcePath,
    $modulePath,
    $configPath,
    $appxPolicyPath,
    $cleanupPolicyPath,
    $rollbackPolicyPath,
    $servicePolicyPath,
    $artifactPolicyPath
)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file was not found: $path"
    }
}

$designText = Get-Content -LiteralPath $designPath -Raw
$readinessText = Get-Content -LiteralPath $readinessPath -Raw
$planText = Get-Content -LiteralPath $planPath -Raw
$moduleText = Get-Content -LiteralPath $modulePath -Raw
$config = Import-PowerShellDataFile -LiteralPath $configPath
$appxPolicy = Import-PowerShellDataFile -LiteralPath $appxPolicyPath
$cleanupPolicy = Import-PowerShellDataFile -LiteralPath $cleanupPolicyPath
$rollbackPolicy = Import-PowerShellDataFile -LiteralPath $rollbackPolicyPath
$servicePolicy = Import-PowerShellDataFile -LiteralPath $servicePolicyPath
$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPolicyPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })

$expectedSourceHash = '36677A334B37025A7234F4320EE54EF50E9528D1814E2B3A463EEB564C5814F5'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
if ($actualSourceHash -ne $expectedSourceHash) {
    throw "Bloatware source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."
}

foreach ($requiredSection in @(
    '# Bloatware Scope Design',
    '## Purpose',
    '## Source Reference',
    '## Source Behavior Summary',
    '## Current Decision',
    '## Behavior Groups',
    '### 1. AppX Current-User Package Removals',
    '### 2. AppX All-Users Package Removals',
    '### 3. Provisioned Package Removals',
    '### 4. Windows Capabilities',
    '### 5. Optional Features',
    '### 6. Services If Present',
    '### 7. Scheduled Tasks If Present',
    '### 8. Files/Directories If Present',
    '### 9. Registry Paths If Present',
    '### 10. MSI/Uninstaller Calls If Present',
    '### 11. AppX Re-Registration or Restore Behavior If Present',
    '### 12. Default/Restore Behavior If Present',
    '### 13. Unsupported Package/Framework/System-Critical Targets',
    '## Product Scope Notes',
    '## Future Safe Apply Requirements',
    '## Default and Restore Boundary',
    '## Production Approval State'
)) {
    if (-not $designText.Contains($requiredSection)) {
        throw "Bloatware scope design is missing section: $requiredSection"
    }
}

foreach ($requiredPhrase in @(
    'Source SHA-256: `36677A334B37025A7234F4320EE54EF50E9528D1814E2B3A463EEB564C5814F5`',
    'Bloatware remains a refused placeholder',
    'No production AppX/package/cleanup/file/registry/service/task/capability/',
    'unknown packages remain denied',
    'wildcard queries into broad production allowlists',
    'RemoveAllUsers',
    'RemoveCurrentUser',
    'RemoveProvisioned',
    'ReRegister',
    'RepairRegistration',
    'Windows 10-only',
    'Restore must remain unavailable',
    'No broad wildcard package, feature, capability, task, or file selection.'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "Bloatware scope design is missing phrase: $requiredPhrase"
    }
}

foreach ($requiredSourceTarget in @(
    'Get-AppXPackage -AllUsers',
    'Remove-AppxPackage',
    'Get-WindowsCapability -Online',
    'Remove-WindowsCapability',
    'Get-WindowsOptionalFeature -Online',
    'Disable-WindowsOptionalFeature',
    'brlapi',
    'uhssvc',
    'PLUGScheduler',
    'OneDrive',
    'Microsoft GameInput',
    'Microsoft Update Health Tools',
    'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device',
    'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate',
    'HKLM\Settings',
    'remotedesktopconnection.exe',
    'snippingtool.exe',
    'Microsoft.ScreenSketch',
    'Microsoft.Windows.StartMenuExperienceHost',
    'NVIDIACorp.NVIDIAControlPanel'
)) {
    if (-not $designText.Contains($requiredSourceTarget)) {
        throw "Bloatware scope design is missing source target: $requiredSourceTarget"
    }
}

foreach ($requiredField in @(
    'Intended mutation type:',
    'Required foundation:',
    'Required production allowlist:',
    'Required inventory/capture before mutation:',
    'Required verification:',
    'Rollback/restore feasibility:',
    'Risk level:',
    'Later implementation decision:'
)) {
    if (-not $designText.Contains($requiredField)) {
        throw "Bloatware scope design is missing per-group field: $requiredField"
    }
}

if (-not $readinessText.Contains('docs/tool-designs/bloatware-scope-design.md')) {
    throw 'Deferred readiness review does not link to the Bloatware scope design.'
}
if (-not $planText.Contains('docs/tool-designs/bloatware-scope-design.md')) {
    throw 'Deferred tools execution plan does not link to the Bloatware scope design.'
}

if (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) {
    throw 'Bloatware module is no longer a placeholder.'
}
if ($moduleText -match 'Remove-AppxPackage|Remove-WindowsCapability|Disable-WindowsOptionalFeature|Remove-Item|Start-Process|Stop-Process|Unregister-ScheduledTask|Add-AppxPackage|IWR|Invoke-WebRequest|reg ') {
    throw 'Bloatware placeholder module appears to contain real mutation behavior.'
}

if ($appxPolicy.PackageScopes.Count -ne 0) {
    throw "AppX package production scopes were approved unexpectedly: $($appxPolicy.PackageScopes.Count)"
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
if ($artifactPolicy.Artifacts.Count -ne 0) {
    throw "Artifact approvals were added unexpectedly: $($artifactPolicy.Artifacts.Count)"
}

$bloatwareTool = $allTools |
    Where-Object { $_.Id -eq 'bloatware' -and $_.Stage -eq 'Windows' } |
    Select-Object -First 1
if (-not $bloatwareTool) {
    throw 'Bloatware catalog entry was not found.'
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
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Where-Object { $_.Name -like '*NVME Faster Driver*' }
)
if ($nvmeSource.Count -ne 0) {
    throw 'NVME Faster Driver source was reintroduced.'
}

[pscustomobject]@{
    Success                   = $true
    ToolId                    = 'bloatware'
    SourceHash                = $actualSourceHash
    ActiveToolCount           = $activeTools.Count
    ImplementedToolCount      = $activeTools.Count - $placeholderModules.Count
    PlaceholderToolCount      = $placeholderModules.Count
    ProductionPackageScopes   = $appxPolicy.PackageScopes.Count
    ProductionCleanupScopes   = $cleanupPolicy.CleanupScopes.Count
    ProductionFileScopes      = $rollbackPolicy.FileScopes.Count
    ProductionRegistryScopes  = $rollbackPolicy.RegistryScopes.Count
    ProductionServiceScopes   = $servicePolicy.ServiceScopes.Count
    ArtifactApprovals         = $artifactPolicy.Artifacts.Count
    SourceUltimateUnchanged   = $true
    DeletedToolsRemainDeleted = $true
    Message                   = 'Bloatware scope design is present, linked, and non-executing.'
    Timestamp                 = Get-Date
}


