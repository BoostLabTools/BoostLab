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
        throw 'Unable to determine the GameBar scope design validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$designPath = Join-Path $ProjectRoot 'docs\tool-designs\gamebar-scope-design.md'
$readinessPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\12 Gamebar.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\game-bar.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$artifactPolicyPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$appxPolicyPath = Join-Path $ProjectRoot 'config\AppxPackagePolicy.psd1'
$cleanupPolicyPath = Join-Path $ProjectRoot 'config\CleanupPolicy.psd1'
$rollbackPolicyPath = Join-Path $ProjectRoot 'config\RollbackPolicy.psd1'
$servicePolicyPath = Join-Path $ProjectRoot 'config\ServiceRollbackPolicy.psd1'
$rebootPolicyPath = Join-Path $ProjectRoot 'config\RebootRecoveryPolicy.psd1'
$trustedPolicyPath = Join-Path $ProjectRoot 'config\TrustedInstallerPolicy.psd1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

foreach ($path in @(
    $designPath,
    $readinessPath,
    $planPath,
    $sourcePath,
    $modulePath,
    $configPath,
    $artifactPolicyPath,
    $appxPolicyPath,
    $cleanupPolicyPath,
    $rollbackPolicyPath,
    $servicePolicyPath,
    $rebootPolicyPath,
    $trustedPolicyPath
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
$appxPolicy = Import-PowerShellDataFile -LiteralPath $appxPolicyPath
$cleanupPolicy = Import-PowerShellDataFile -LiteralPath $cleanupPolicyPath
$rollbackPolicy = Import-PowerShellDataFile -LiteralPath $rollbackPolicyPath
$servicePolicy = Import-PowerShellDataFile -LiteralPath $servicePolicyPath
$rebootPolicy = Import-PowerShellDataFile -LiteralPath $rebootPolicyPath
$trustedPolicy = Import-PowerShellDataFile -LiteralPath $trustedPolicyPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })

$expectedSourceHash = '8C6703E68C251D63ADD81A87B7CB6C1F572A4CE55A1E092C33B9B444A9884E59'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
if ($actualSourceHash -ne $expectedSourceHash) {
    throw "GameBar source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."
}

foreach ($requiredSection in @(
    '# GameBar Scope Design',
    '## Purpose',
    '## Source Reference',
    '## Product Scope Decision',
    '## Source Behavior Summary',
    '## Current Decision',
    '## Behavior Groups',
    '### 1. Xbox Game Bar AppX/Package Behavior',
    '### 2. Xbox-Related AppX/Package Behavior',
    '### 3. GameInput Behavior',
    '### 4. Service Behavior If Present',
    '### 5. Process Stop Behavior If Present',
    '### 6. Registry Policy/Settings Behavior',
    '### 7. File/Directory Cleanup Behavior If Present',
    '### 8. AppX Re-Registration or Repair Behavior If Present',
    '### 9. Downloads/Installers or Repair Installer Behavior If Present',
    '### 10. Default/Restore Behavior',
    '### 11. Unsupported Broad Package/Service/File/Registry Targets',
    '### 12. Unsupported Windows 10-Only Branches/Options If Present',
    '## Exact Source Target Inventory',
    '## Future Safe Apply Requirements',
    '## Default and Restore Boundary',
    '## Production Approval State'
)) {
    if (-not $designText.Contains($requiredSection)) {
        throw "GameBar scope design is missing section: $requiredSection"
    }
}

foreach ($requiredPhrase in @(
    'Source SHA-256: `8C6703E68C251D63ADD81A87B7CB6C1F572A4CE55A1E092C33B9B444A9884E59`',
    'GameBar remains a refused placeholder',
    'No production AppX/package/service/registry/file/cleanup/download/installer/reboot scopes',
    'The current catalog metadata understates source risk',
    'unknown packages remain denied',
    'wildcard AppX package matching remains refused',
    'No Windows 10-only branch was found',
    'Current Default/Restore must remain unavailable',
    'mutable GitHub raw URLs',
    'TrustedInstaller',
    'edgewebview.exe',
    'gamingrepairtool.exe',
    'Microsoft GameInput'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "GameBar scope design is missing phrase: $requiredPhrase"
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
    'Whether it can be implemented later:',
    'Whether it must remain refused:'
)) {
    if (-not $designText.Contains($requiredField)) {
        throw "GameBar scope design is missing per-group field: $requiredField"
    }
}

foreach ($requiredSourceTarget in @(
    'Get-AppXPackage -AllUsers | Where-Object',
    'Remove-AppxPackage',
    'Add-AppxPackage -DisableDevelopmentMode -Register',
    '*Gaming*',
    '*Xbox*',
    '*Store*',
    'GameInputSvc',
    'gamingservices',
    'gamingservicesnet',
    'GameInputRedistService',
    'Stop-Process -Force -Name GameBar',
    'HKCU\System\GameConfigStore',
    'HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR',
    'HKCU\Software\Microsoft\GameBar',
    'HKEY_CLASSES_ROOT\ms-gamebar',
    'HKEY_CLASSES_ROOT\ms-gamebarservices',
    'HKEY_CLASSES_ROOT\ms-gamingoverlay',
    'HKLM\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter',
    '$env:SystemRoot\Temp\gamebaroff.reg',
    '$env:SystemRoot\Temp\gamebaron.reg',
    '$env:SystemRoot\Temp\edgewebview.exe',
    '$env:SystemRoot\Temp\gamingrepairtool.exe',
    'Run-Trusted -command',
    'sc.exe config TrustedInstaller binPath=',
    'sc.exe start TrustedInstaller'
)) {
    if (-not $designText.Contains($requiredSourceTarget)) {
        throw "GameBar scope design is missing source target: $requiredSourceTarget"
    }
}

$urls = [regex]::Matches(
    $sourceText,
    'https://github\.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/[A-Za-z0-9_.-]+'
) | ForEach-Object { $_.Value } | Sort-Object -Unique
if (@($urls).Count -ne 2) {
    throw "Expected 2 GameBar source URLs, found $(@($urls).Count)."
}
foreach ($url in $urls) {
    if (-not $designText.Contains($url)) {
        throw "GameBar scope design is missing source URL: $url"
    }
}

$nonElevationStartProcess = @(
    [regex]::Matches($sourceText, 'Start-Process') |
        ForEach-Object { $_.Value }
).Count - 1
if ($nonElevationStartProcess -ne 5) {
    throw "Expected 5 non-elevation Start-Process calls, found $nonElevationStartProcess."
}
foreach ($commandSnippet in @(
    'Start-Process "msiexec.exe"',
    'Start-Process -Wait "regedit.exe"',
    'Start-Process -Wait "$env:SystemRoot\Temp\edgewebview.exe"',
    'Start-Process "$env:SystemRoot\Temp\gamingrepairtool.exe"'
)) {
    if (-not $designText.Contains($commandSnippet)) {
        throw "GameBar scope design is missing Start-Process snippet: $commandSnippet"
    }
}

if ($sourceText -match 'Restart-Computer|shutdown\s|bcdedit') {
    throw 'GameBar source unexpectedly contains direct reboot or BCD behavior.'
}

if (-not $readinessText.Contains('docs/tool-designs/gamebar-scope-design.md')) {
    throw 'Deferred readiness review does not link to the GameBar scope design.'
}
if (-not $planText.Contains('docs/tool-designs/gamebar-scope-design.md')) {
    throw 'Deferred tools execution plan does not link to the GameBar scope design.'
}

if (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) {
    throw 'GameBar module is no longer a placeholder.'
}
if ($moduleText -match 'Get-AppXPackage|Remove-AppxPackage|Add-AppxPackage|Start-Process|IWR|Invoke-WebRequest|Run-Trusted|TrustedInstaller|regedit|msiexec|Stop-Process|sc stop') {
    throw 'GameBar placeholder module appears to contain real mutation behavior.'
}

if ($artifactPolicy.Artifacts.Count -ne 0) {
    throw "Artifact approvals were added unexpectedly: $($artifactPolicy.Artifacts.Count)"
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
if ($rebootPolicy.WorkflowScopes.Count -ne 0) {
    throw "Reboot workflow production scopes were approved unexpectedly: $($rebootPolicy.WorkflowScopes.Count)"
}
if ($trustedPolicy.TrustedInstallerScopes.Count -ne 0) {
    throw "TrustedInstaller production scopes were approved unexpectedly: $($trustedPolicy.TrustedInstallerScopes.Count)"
}

$gameBarTool = $allTools |
    Where-Object { $_.Id -eq 'game-bar' -and $_.Stage -eq 'Windows' } |
    Select-Object -First 1
if (-not $gameBarTool) {
    throw 'GameBar catalog entry was not found.'
}

$activeTools = @($allTools)
$placeholderModules = @(
    Get-ChildItem -Path (Join-Path $ProjectRoot 'modules') -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
if ($activeTools.Count -ne 51) {
    throw "Expected 51 active tools, found $($activeTools.Count)."
}
if ($placeholderModules.Count -ne 18) {
    throw "Expected 18 placeholder modules, found $($placeholderModules.Count)."
}
if (($activeTools.Count - $placeholderModules.Count) -ne 33) {
    throw "Expected 33 implemented tools, found $($activeTools.Count - $placeholderModules.Count)."
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
    Success                       = $true
    ToolId                        = 'game-bar'
    SourceHash                    = $actualSourceHash
    ActiveToolCount               = $activeTools.Count
    ImplementedToolCount          = $activeTools.Count - $placeholderModules.Count
    PlaceholderToolCount          = $placeholderModules.Count
    ProductionArtifactApprovals   = $artifactPolicy.Artifacts.Count
    ProductionPackageScopes       = $appxPolicy.PackageScopes.Count
    ProductionCleanupScopes       = $cleanupPolicy.CleanupScopes.Count
    ProductionFileScopes          = $rollbackPolicy.FileScopes.Count
    ProductionRegistryScopes      = $rollbackPolicy.RegistryScopes.Count
    ProductionServiceScopes       = $servicePolicy.ServiceScopes.Count
    ProductionRebootScopes        = $rebootPolicy.WorkflowScopes.Count
    ProductionTrustedScopes       = $trustedPolicy.TrustedInstallerScopes.Count
    SourceUltimateUnchanged       = $true
    DeletedToolsRemainDeleted     = $true
    Message                       = 'GameBar scope design is present, linked, and non-executing.'
    Timestamp                     = Get-Date
}

