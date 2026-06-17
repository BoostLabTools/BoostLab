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
        throw 'Unable to determine the Reinstall scope/provenance design validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$designPath = Join-Path $ProjectRoot 'docs\tool-designs\reinstall-scope-provenance-design.md'
$readinessPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\2 Refresh\1 Reinstall.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Refresh\reinstall.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$artifactPolicyPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
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
$rollbackPolicy = Import-PowerShellDataFile -LiteralPath $rollbackPolicyPath
$rebootPolicy = Import-PowerShellDataFile -LiteralPath $rebootPolicyPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })

$expectedSourceHash = '137F519926293F37052817ACBBE20851652E5EA1B9F3B5B9F933AA1E22C2D9FB'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
if ($actualSourceHash -ne $expectedSourceHash) {
    throw "Reinstall source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."
}

foreach ($requiredSection in @(
    '# Reinstall Scope and Provenance Design',
    '## Purpose',
    '## Source Reference',
    '## Product Scope Decision',
    '## Source Behavior Summary',
    '## Current Decision',
    '## Behavior Groups',
    '### 1. Windows 10-Only Branch Behavior',
    '### 2. Windows 11 Reinstall/Refresh Branch Behavior',
    '### 3. Media Creation Tool Download Behavior',
    '### 4. Third-Party Mirror or Mutable URL Behavior',
    '### 5. Installer/Executable Launch Behavior',
    '### 6. ISO/Setup/Upgrade Workflow Behavior If Present',
    '### 7. File/Temp/Download Target Behavior If Present',
    '### 8. Reboot/Restart Behavior If Present',
    '### 9. User Confirmation and Warning Requirements',
    '### 10. Verification Before Launch',
    '### 11. Verification After Launch or Handoff',
    '### 12. Default/Restore Behavior',
    '### 13. Unsupported Reinstall/Refresh Targets',
    '## Exact Source Target Inventory',
    '## Future Safe Open/Apply/Launch Requirements',
    '## Default and Restore Boundary',
    '## Production Approval State'
)) {
    if (-not $designText.Contains($requiredSection)) {
        throw "Reinstall scope/provenance design is missing section: $requiredSection"
    }
}

foreach ($requiredPhrase in @(
    'Source SHA-256: `137F519926293F37052817ACBBE20851652E5EA1B9F3B5B9F933AA1E22C2D9FB`',
    'Reinstall remains a refused placeholder',
    'No production download/executable/installer/reinstall/reboot/file/registry scopes',
    'Windows 10 Media Creation Tool branch is unsupported',
    'Windows 11 Media Creation Tool branch',
    'mutable third-party mirror URL',
    'mediacreationtoolw10.exe',
    'mediacreationtoolw11.exe',
    'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw10.exe',
    'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw11.exe',
    '$env:SystemRoot\Temp\mediacreationtoolw11.exe',
    'Start-Process "$env:SystemRoot\Temp\mediacreationtoolw11.exe"',
    'Current Default/Restore must remain unavailable.',
    'Restore remains unavailable unless exact workflow state',
    'BitLocker/recovery key risks',
    'Microsoft account/OOBE effects'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "Reinstall scope/provenance design is missing phrase: $requiredPhrase"
    }
}

foreach ($requiredField in @(
    'Exact source targets:',
    'Intended mutation or launch type:',
    'Required foundation:',
    'Required future production allowlist:',
    'Required provenance before download/launch:',
    'Required user confirmation level:',
    'Required verification:',
    'Rollback/restore feasibility:',
    'Risk level:',
    'Later implementation decision:'
)) {
    if (-not $designText.Contains($requiredField)) {
        throw "Reinstall scope/provenance design is missing per-group field: $requiredField"
    }
}

foreach ($requiredSourceTarget in @(
    'Write-Host "1. Reinstall: W10"',
    'Write-Host "2. Reinstall: W11`n"',
    'IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw10.exe"',
    'OutFile "$env:SystemRoot\Temp\mediacreationtoolw10.exe"',
    'Start-Process "$env:SystemRoot\Temp\mediacreationtoolw10.exe"',
    'IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw11.exe"',
    'OutFile "$env:SystemRoot\Temp\mediacreationtoolw11.exe"',
    'Start-Process "$env:SystemRoot\Temp\mediacreationtoolw11.exe"',
    'Test-Connection -ComputerName "8.8.8.8"'
)) {
    if (-not $sourceText.Contains($requiredSourceTarget)) {
        throw "Reinstall source no longer contains expected target: $requiredSourceTarget"
    }
    if (-not $designText.Contains($requiredSourceTarget)) {
        throw "Reinstall scope/provenance design is missing source target: $requiredSourceTarget"
    }
}

if ($sourceText -match 'shutdown|Restart-Computer|setup\.exe|Mount-DiskImage|reg add|reg delete|Remove-Item|msiexec') {
    throw 'Reinstall source unexpectedly contains direct setup, reboot, registry, deletion, or installer command behavior.'
}

if (-not $readinessText.Contains('docs/tool-designs/reinstall-scope-provenance-design.md')) {
    throw 'Deferred readiness review does not link to the Reinstall scope/provenance design.'
}
if (-not $planText.Contains('docs/tool-designs/reinstall-scope-provenance-design.md')) {
    throw 'Deferred tools execution plan does not link to the Reinstall scope/provenance design.'
}

if (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) {
    throw 'Reinstall module is no longer a placeholder.'
}
if ($moduleText -match 'IWR|Invoke-WebRequest|Start-BitsTransfer|mediacreationtool|Start-Process|setup|shutdown|Mount-DiskImage|msiexec') {
    throw 'Reinstall placeholder module appears to contain real download, launch, or setup behavior.'
}

if (@($artifactPolicy.Artifacts).Count -ne 0) {
    throw "Artifact approvals were added unexpectedly: $(@($artifactPolicy.Artifacts).Count)"
}
if (@($rollbackPolicy.FileScopes).Count -ne 0 -or @($rollbackPolicy.RegistryScopes).Count -ne 0) {
    throw 'File or registry production scopes were approved unexpectedly.'
}
if (@($rebootPolicy.WorkflowScopes).Count -ne 0) {
    throw "Reboot workflow production scopes were approved unexpectedly: $(@($rebootPolicy.WorkflowScopes).Count)"
}

$tool = $allTools |
    Where-Object { $_.Id -eq 'reinstall' -and $_.Stage -eq 'Refresh' } |
    Select-Object -First 1
if (-not $tool) {
    throw 'Reinstall catalog entry was not found.'
}
if (-not (@($tool.Actions) -contains 'Analyze') -or -not (@($tool.Actions) -contains 'Apply')) {
    throw 'Reinstall catalog actions changed unexpectedly.'
}

$activeTools = @($allTools)
$placeholderModules = @(
    Get-ChildItem -Path (Join-Path $ProjectRoot 'modules') -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
if ($activeTools.Count -ne 50) {
    throw "Expected 50 active tools, found $($activeTools.Count)."
}
if ($placeholderModules.Count -ne 18) {
    throw "Expected 18 placeholder modules, found $($placeholderModules.Count)."
}
if (($activeTools.Count - $placeholderModules.Count) -ne 32) {
    throw "Expected 32 implemented tools, found $($activeTools.Count - $placeholderModules.Count)."
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
    ToolId                     = 'reinstall'
    SourceHash                 = $actualSourceHash
    ActiveToolCount            = $activeTools.Count
    ImplementedToolCount       = $activeTools.Count - $placeholderModules.Count
    PlaceholderToolCount       = $placeholderModules.Count
    ArtifactApprovals          = @($artifactPolicy.Artifacts).Count
    ProductionFileScopes       = @($rollbackPolicy.FileScopes).Count
    ProductionRegistryScopes   = @($rollbackPolicy.RegistryScopes).Count
    ProductionRebootScopes     = @($rebootPolicy.WorkflowScopes).Count
    SourceUltimateUnchanged    = $true
    DeletedToolsRemainDeleted  = $true
    Message                    = 'Reinstall scope/provenance design is present, linked, and non-executing.'
    Timestamp                  = Get-Date
}

