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
        throw 'Unable to determine the Resizable BAR Assistant scope design validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$designPath = Join-Path $ProjectRoot 'docs\tool-designs\resizable-bar-assistant-scope-design.md'
$readinessPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\8 Advanced\3 Resizable BAR Assistant.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Advanced\resizable-bar-assistant.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$artifactPolicyPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$driverPolicyPath = Join-Path $ProjectRoot 'config\DriverStatePolicy.psd1'
$rollbackPolicyPath = Join-Path $ProjectRoot 'config\RollbackPolicy.psd1'
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
    $driverPolicyPath,
    $rollbackPolicyPath,
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
$driverPolicy = Import-PowerShellDataFile -LiteralPath $driverPolicyPath
$rollbackPolicy = Import-PowerShellDataFile -LiteralPath $rollbackPolicyPath
$rebootPolicy = Import-PowerShellDataFile -LiteralPath $rebootPolicyPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })

$expectedSourceHash = 'E2E1D919B350FA5190DFD4FAF23F3AB51ED2A324155CAFF49CDE774B092FB443'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
if ($actualSourceHash -ne $expectedSourceHash) {
    throw "Resizable BAR Assistant source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."
}

foreach ($requiredSection in @(
    '# Resizable BAR Assistant Scope Design',
    '## Purpose',
    '## Source Reference',
    '## Product Scope Decision',
    '## Source Behavior Summary',
    '## Current Decision',
    '## Behavior Groups',
    '### 1. GPU/Vendor Detection Behavior',
    '### 2. NVIDIA-Specific Resizable BAR Checks',
    '### 3. NVIDIA Profile Inspector Download or Executable Behavior',
    '### 4. NVIDIA Driver Profile Mutation Behavior',
    '### 5. Registry or File Targets If Present',
    '### 6. Firmware Restart / Reboot Behavior',
    '### 7. User Confirmation and Warning Requirements',
    '### 8. Verification Behavior After Mutation',
    '### 9. Default/Restore Behavior If Present',
    '### 10. Unsupported AMD/Intel Behavior If Present',
    '### 11. Unsupported Download/Tool/Driver-Profile Targets',
    '## Exact Source Target Inventory',
    '## NVIDIA Profile Setting Inventory',
    '## Future Safe Apply Requirements',
    '## Default and Restore Boundary',
    '## Production Approval State'
)) {
    if (-not $designText.Contains($requiredSection)) {
        throw "Resizable BAR Assistant scope design is missing section: $requiredSection"
    }
}

foreach ($requiredPhrase in @(
    'Source SHA-256: `E2E1D919B350FA5190DFD4FAF23F3AB51ED2A324155CAFF49CDE774B092FB443`',
    'Resizable BAR Assistant remains a refused placeholder',
    'No production download/tool/driver-profile/registry/file/reboot/firmware scopes',
    'No AMD GPU-specific behavior is approved.',
    'No Intel GPU-specific behavior is approved.',
    'NVIDIA Profile Inspector',
    'mutable external executable',
    'driver profile mutation',
    'firmware restart',
    'rBAR - Enable',
    'SettingID `983226`',
    'DEFAULT DRIVER WHITELIST PER GAME (DEFAULT)',
    'Current Default/Restore must remain unavailable.',
    'Restore remains unavailable unless exact driver profile rollback',
    'Unknown, mutable, unverified, AMD/Intel, or out-of-scope targets remain denied.'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "Resizable BAR Assistant scope design is missing phrase: $requiredPhrase"
    }
}

foreach ($requiredField in @(
    'Exact source logic:',
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
        throw "Resizable BAR Assistant scope design is missing per-group field: $requiredField"
    }
}

foreach ($requiredSourceTarget in @(
    'IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/inspector.exe"',
    'OutFile "$env:SystemRoot\Temp\inspector.exe"',
    '$path = "C:\ProgramData\NVIDIA Corporation\Drs"',
    'Get-ChildItem -Path $path -Recurse | Unblock-File',
    'Set-Content -Path "$env:SystemRoot\Temp\default.nip"',
    'Set-Content -Path "$env:SystemRoot\Temp\forceon.nip"',
    'Set-Content -Path "$env:SystemRoot\Temp\forceoff.nip"',
    'Start-Process -wait "$env:SystemRoot\Temp\inspector.exe" -ArgumentList "-silentImport -silent $env:SystemRoot\Temp\default.nip"',
    'Start-Process -wait "$env:SystemRoot\Temp\inspector.exe" -ArgumentList "-silentImport -silent $env:SystemRoot\Temp\forceon.nip"',
    'Start-Process -wait "$env:SystemRoot\Temp\inspector.exe" -ArgumentList "-silentImport -silent $env:SystemRoot\Temp\forceoff.nip"',
    'Start-Process "$env:SystemRoot\Temp\inspector.exe"',
    'cmd /c C:\Windows\System32\shutdown.exe /r /fw /t 0',
    '<SettingNameInfo>rBAR - Enable</SettingNameInfo>',
    '<SettingID>983226</SettingID>',
    '<SettingValue>1</SettingValue>',
    '<SettingValue>0</SettingValue>'
)) {
    if (-not $sourceText.Contains($requiredSourceTarget)) {
        throw "Resizable BAR Assistant source is missing expected target: $requiredSourceTarget"
    }
}

foreach ($requiredDocTarget in @(
    'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/inspector.exe',
    '%SystemRoot%\Temp\inspector.exe',
    'C:\ProgramData\NVIDIA Corporation\Drs',
    '%SystemRoot%\Temp\default.nip',
    '%SystemRoot%\Temp\forceon.nip',
    '%SystemRoot%\Temp\forceoff.nip',
    '%SystemRoot%\Temp\inspector.exe -silentImport -silent <nip path>',
    'cmd /c C:\Windows\System32\shutdown.exe /r /fw /t 0',
    '| rBAR - Enable | 983226 | Not present | 1 | 0 | Dword |',
    '| Preferred OpenGL GPU | 550564838 | id,2.0:268410DE,00000100,GF - (400,2,161,24564) @ (0)'
)) {
    if (-not $designText.Contains($requiredDocTarget)) {
        throw "Resizable BAR Assistant scope design is missing documented source target: $requiredDocTarget"
    }
}

foreach ($unsupported in @('AMD GPU-specific behavior is approved', 'Intel GPU-specific behavior is approved')) {
    $approvalPhrase = "No $unsupported"
    if (-not $designText.Contains($approvalPhrase)) {
        throw "Resizable BAR Assistant scope design does not explicitly deny: $unsupported"
    }
}

if (-not $sourceText.Contains('NVIDIA RESIZABLE BAR FORCE')) {
    throw 'Resizable BAR Assistant source no longer contains expected NVIDIA-specific menu text.'
}
if (-not $sourceText.Contains('shutdown.exe /r /fw /t 0')) {
    throw 'Resizable BAR Assistant source no longer contains expected firmware restart behavior.'
}
if ($sourceText -match '(?i)\bAMD\b|\bIntel\b') {
    throw 'Resizable BAR Assistant source unexpectedly contains AMD or Intel branch text.'
}

if (-not $readinessText.Contains('docs/tool-designs/resizable-bar-assistant-scope-design.md')) {
    throw 'Deferred readiness review does not link to the Resizable BAR Assistant scope design.'
}
if (-not $planText.Contains('docs/tool-designs/resizable-bar-assistant-scope-design.md')) {
    throw 'Deferred tools execution plan does not link to the Resizable BAR Assistant scope design.'
}

if (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) {
    throw 'Resizable BAR Assistant module is no longer a placeholder.'
}
if ($moduleText -match 'Invoke-WebRequest|\bIWR\b|inspector\.exe|silentImport|Unblock-File|Set-Content|shutdown\.exe|Start-Process|NVIDIA Corporation\\Drs|rBAR') {
    throw 'Resizable BAR Assistant placeholder module appears to contain real mutation behavior.'
}

if ($artifactPolicy.Artifacts.Count -ne 0) {
    throw "Artifact approvals were added unexpectedly: $($artifactPolicy.Artifacts.Count)"
}
if ($driverPolicy.DriverScopes.Count -ne 0) {
    throw "Driver production scopes were approved unexpectedly: $($driverPolicy.DriverScopes.Count)"
}
if ($rollbackPolicy.FileScopes.Count -ne 0 -or $rollbackPolicy.RegistryScopes.Count -ne 0) {
    throw 'File or registry production scopes were approved unexpectedly.'
}
if ($rebootPolicy.WorkflowScopes.Count -ne 0) {
    throw "Reboot workflow production scopes were approved unexpectedly: $($rebootPolicy.WorkflowScopes.Count)"
}

$tool = $allTools |
    Where-Object { $_.Id -eq 'resizable-bar-assistant' -and $_.Stage -eq 'Advanced' } |
    Select-Object -First 1
if (-not $tool) {
    throw 'Resizable BAR Assistant catalog entry was not found.'
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
    ToolId                     = 'resizable-bar-assistant'
    SourceHash                 = $actualSourceHash
    ArtifactApprovals          = $artifactPolicy.Artifacts.Count
    ProductionDriverScopes     = $driverPolicy.DriverScopes.Count
    ProductionFileScopes       = $rollbackPolicy.FileScopes.Count
    ProductionRegistryScopes   = $rollbackPolicy.RegistryScopes.Count
    ProductionRebootScopes     = $rebootPolicy.WorkflowScopes.Count
    ActiveToolCount            = $activeTools.Count
    ImplementedToolCount       = $activeTools.Count - $placeholderModules.Count
    PlaceholderToolCount       = $placeholderModules.Count
    SourceUltimateUnchanged    = $true
    DeletedToolsRemainDeleted  = $true
    Message                    = 'Resizable BAR Assistant scope design is present, linked, NVIDIA-scoped, and non-executing.'
    Timestamp                  = Get-Date
}



