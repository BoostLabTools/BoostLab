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
        throw 'Unable to determine the Cleanup scope design validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$designPath = Join-Path $ProjectRoot 'docs\tool-designs\cleanup-scope-design.md'
$readinessPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\22 Cleanup.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\cleanup.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$cleanupPolicyPath = Join-Path $ProjectRoot 'config\CleanupPolicy.psd1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

foreach ($path in @($designPath, $readinessPath, $planPath, $sourcePath, $modulePath, $configPath, $cleanupPolicyPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file was not found: $path"
    }
}

$designText = Get-Content -LiteralPath $designPath -Raw
$readinessText = Get-Content -LiteralPath $readinessPath -Raw
$planText = Get-Content -LiteralPath $planPath -Raw
$moduleText = Get-Content -LiteralPath $modulePath -Raw
$cleanupPolicy = Import-PowerShellDataFile -LiteralPath $cleanupPolicyPath
$config = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })

$expectedSourceHash = '3419A995AD4483A145999B659268302F02BE982733DE831554ADA1C40F07CCAA'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
if ($actualSourceHash -ne $expectedSourceHash) {
    throw "Cleanup source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."
}

foreach ($requiredSection in @(
    '# Cleanup Scope Design',
    '## Purpose',
    '## Source Reference',
    '## Source Behavior Summary',
    '## Current Decision',
    '## Behavior Groups',
    '### 1. User Temp Paths',
    '### 2. System Temp Paths',
    '### 3. Windows.old Behavior',
    '### 4. Dump/Log Artifacts',
    '### 5. Prefetch/Cache Targets If Present',
    '### 6. Browser/Cache Targets If Present',
    '### 7. Recycle Bin or cleanmgr Behavior If Present',
    '### 8. Broad Recursive Deletion Behavior',
    '### 9. Windows/System/Root Path Behavior',
    '### 10. Default/Restore Behavior If Present',
    '## Phase 38 Policy Application',
    '## Future Safe Apply Requirements',
    '## Default and Restore Boundary',
    '## Production Approval State'
)) {
    if (-not $designText.Contains($requiredSection)) {
        throw "Cleanup scope design is missing section: $requiredSection"
    }
}

foreach ($requiredPhrase in @(
    'Source SHA-256: `3419A995AD4483A145999B659268302F02BE982733DE831554ADA1C40F07CCAA`',
    'Cleanup remains a refused placeholder',
    'No production cleanup allowlists or scopes are approved by this document.',
    'Broad roots remain refused.',
    'Wildcard-only targets remain refused.',
    'User documents remain refused',
    'Recursive deletion requires exact bounded allowlists and limits.',
    'Reparse points, junctions, and symlinks remain refused',
    'Permanent deletion should be avoided where quarantine is practical.',
    'No Default option.',
    'No Restore option.',
    'Default and Restore must remain unavailable'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "Cleanup scope design is missing phrase: $requiredPhrase"
    }
}

foreach ($requiredSourceTarget in @(
    '%USERPROFILE%\AppData\Local\Temp\*',
    '%SystemDrive%\Windows\Temp\*',
    '%SystemDrive%\inetpub',
    '%SystemDrive%\PerfLogs',
    '%SystemDrive%\Windows.old',
    '%SystemDrive%\DumpStack.log',
    'Start-Process cleanmgr.exe',
    'Remove-Item -Path "$env:USERPROFILE\AppData\Local\Temp\*" -Recurse -Force',
    'Remove-Item -Path "$env:SystemDrive\Windows\Temp\*" -Recurse -Force'
)) {
    if (-not $designText.Contains($requiredSourceTarget)) {
        throw "Cleanup scope design is missing source target: $requiredSourceTarget"
    }
}

foreach ($requiredField in @(
    'Target type:',
    'Intended cleanup type:',
    'Required foundation:',
    'Required production cleanup allowlist:',
    'State capture or quarantine requirement:',
    'Required file-count/size limits:',
    'Required confirmation level:',
    'Required verification:',
    'Rollback feasibility:',
    'Risk level:',
    'Later implementation decision:'
)) {
    if (-not $designText.Contains($requiredField)) {
        throw "Cleanup scope design is missing per-group field: $requiredField"
    }
}

if (-not $readinessText.Contains('docs/tool-designs/cleanup-scope-design.md')) {
    throw 'Deferred readiness review does not link to the Cleanup scope design.'
}
if (-not $planText.Contains('docs/tool-designs/cleanup-scope-design.md')) {
    throw 'Deferred tools execution plan does not link to the Cleanup scope design.'
}

if (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) {
    throw 'Cleanup module is no longer a placeholder.'
}
if ($moduleText -match 'Remove-Item|Start-Process|cleanmgr|Clear-RecycleBin|Compress-Archive|Move-Item') {
    throw 'Cleanup placeholder module appears to contain real cleanup behavior.'
}

if ($cleanupPolicy.CleanupScopes.Count -ne 0) {
    throw "Cleanup production scopes were approved unexpectedly: $($cleanupPolicy.CleanupScopes.Count)"
}

$cleanupTool = $allTools |
    Where-Object { $_.Id -eq 'cleanup' -and $_.Stage -eq 'Windows' } |
    Select-Object -First 1
if (-not $cleanupTool) {
    throw 'Cleanup catalog entry was not found.'
}

$activeTools = @($allTools)
$placeholderModules = @(
    Get-ChildItem -Path (Join-Path $ProjectRoot 'modules') -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
if ($activeTools.Count -ne 55) {
    throw "Expected 55 active tools, found $($activeTools.Count)."
}
if ($placeholderModules.Count -ne 15) {
    throw "Expected 15 placeholder modules, found $($placeholderModules.Count)."
}
if (($activeTools.Count - $placeholderModules.Count) -ne 40) {
    throw "Expected 40 implemented tools, found $($activeTools.Count - $placeholderModules.Count)."
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
    Success                    = $true
    ToolId                     = 'cleanup'
    SourceHash                 = $actualSourceHash
    ActiveToolCount            = $activeTools.Count
    ImplementedToolCount       = $activeTools.Count - $placeholderModules.Count
    PlaceholderToolCount       = $placeholderModules.Count
    ProductionCleanupScopes    = $cleanupPolicy.CleanupScopes.Count
    SourceUltimateUnchanged    = $true
    DeletedToolsRemainDeleted  = $true
    Message                    = 'Cleanup scope design is present, linked, and non-executing.'
    Timestamp                  = Get-Date
}



