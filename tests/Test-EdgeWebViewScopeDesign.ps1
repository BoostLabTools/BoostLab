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
        throw 'Unable to determine the Edge WebView scope design validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$designPath = Join-Path $ProjectRoot 'docs\tool-designs\edge-webview-scope-design.md'
$readinessPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\13 Edge & WebView.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\edge-webview.psm1'
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

$expectedSourceHash = '161ED9C99D437E45650369CB7E15D5737DED363712E647138F134B049AC7E691'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
if ($actualSourceHash -ne $expectedSourceHash) {
    throw "Edge & WebView source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."
}

foreach ($requiredSection in @(
    '# Edge and WebView Scope Design',
    '## Purpose',
    '## Source Reference',
    '## Source Behavior Summary',
    '## Current Decision',
    '## Behavior Groups',
    '### 1. Microsoft Edge Package/AppX Behavior',
    '### 2. Microsoft Edge WebView2 Behavior',
    '### 3. Edge Update Services',
    '### 4. Edge Scheduled Tasks',
    '### 5. Program Files / Program Files (x86) Microsoft Edge Directories',
    '### 6. Edge/WebView Registry Paths',
    '### 7. CBS/DISM/Package Removal Behavior If Present',
    '### 8. RunOnce / Active Setup / Task Removal Behavior If Present',
    '### 9. Process Stop Behavior',
    '### 10. Downloads or Repair Installer Behavior',
    '### 11. Default/Restore Behavior',
    '### 12. Unsupported Broad Deletion or Package Targets',
    '## Product Scope Notes',
    '## Future Safe Apply Requirements',
    '## Default and Restore Boundary',
    '## Production Approval State'
)) {
    if (-not $designText.Contains($requiredSection)) {
        throw "Edge & WebView scope design is missing section: $requiredSection"
    }
}

foreach ($requiredPhrase in @(
    'Source SHA-256: `161ED9C99D437E45650369CB7E15D5737DED363712E647138F134B049AC7E691`',
    'Edge & WebView remains a refused placeholder',
    'No production AppX/package/download/installer/cleanup/file/registry/service/',
    'mutable `refs/heads/main` artifacts',
    'unknown packages remain denied',
    'wildcard/broad packages remain denied',
    'system-critical/framework/dependency packages remain denied',
    'service deletion/recreation rollback',
    'Broad `%SystemDrive%\Program Files (x86)\Microsoft` deletion must remain',
    'Windows 10-only legacy Edge branch',
    'Restore remains unavailable'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "Edge & WebView scope design is missing phrase: $requiredPhrase"
    }
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
    'edgewebview.exe',
    'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe',
    'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edgewebview.exe',
    'backgroundTaskHost',
    'msedgewebview2',
    'WidgetService',
    'Get-ScheduledTask | Where-Object { $_.TaskName -like ''*Edge*'' }'
)) {
    if (-not $designText.Contains($requiredSourceTarget)) {
        throw "Edge & WebView scope design is missing source target: $requiredSourceTarget"
    }
}

foreach ($requiredField in @(
    'Intended mutation type:',
    'Required foundation:',
    'Required future production allowlist:',
    'Required inventory/capture before mutation:',
    'Required verification:',
    'Rollback/restore feasibility:',
    'Risk level:',
    'Later implementation decision:'
)) {
    if (-not $designText.Contains($requiredField)) {
        throw "Edge & WebView scope design is missing per-group field: $requiredField"
    }
}

if (-not $readinessText.Contains('docs/tool-designs/edge-webview-scope-design.md')) {
    throw 'Deferred readiness review does not link to the Edge & WebView scope design.'
}
if (-not $planText.Contains('docs/tool-designs/edge-webview-scope-design.md')) {
    throw 'Deferred tools execution plan does not link to the Edge & WebView scope design.'
}

if (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) {
    throw 'Edge & WebView module is no longer a placeholder.'
}
if ($moduleText -match 'Remove-Item|Start-Process|Stop-Process|Unregister-ScheduledTask|IWR|Invoke-WebRequest|dism|sc |reg |Remove-AppxPackage|Add-AppxPackage') {
    throw 'Edge & WebView placeholder module appears to contain real mutation behavior.'
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

$edgeTool = $allTools |
    Where-Object { $_.Id -eq 'edge-webview' -and $_.Stage -eq 'Windows' } |
    Select-Object -First 1
if (-not $edgeTool) {
    throw 'Edge & WebView catalog entry was not found.'
}

$activeTools = @($allTools)
$placeholderModules = @(
    Get-ChildItem -Path (Join-Path $ProjectRoot 'modules') -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
if ($activeTools.Count -ne 54) {
    throw "Expected 54 active tools, found $($activeTools.Count)."
}
if ($placeholderModules.Count -ne 18) {
    throw "Expected 18 placeholder modules, found $($placeholderModules.Count)."
}
if (($activeTools.Count - $placeholderModules.Count) -ne 36) {
    throw "Expected 36 implemented tools, found $($activeTools.Count - $placeholderModules.Count)."
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
    ToolId                    = 'edge-webview'
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
    Message                   = 'Edge & WebView scope design is present, linked, and non-executing.'
    Timestamp                 = Get-Date
}



