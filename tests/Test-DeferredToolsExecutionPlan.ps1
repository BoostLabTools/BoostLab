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
        throw 'Unable to determine the deferred-plan validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$triagePath = Join-Path $ProjectRoot 'docs\remaining-tool-migration-triage.md'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

if (-not (Test-Path -LiteralPath $planPath -PathType Leaf)) {
    throw "Deferred tools execution plan was not found: $planPath"
}
if (-not (Test-Path -LiteralPath $triagePath -PathType Leaf)) {
    throw "Remaining migration triage was not found: $triagePath"
}

$planText = Get-Content -LiteralPath $planPath -Raw
$triageText = Get-Content -LiteralPath $triagePath -Raw
$config = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })

$placeholderModules = @(
    Get-ChildItem -Path (Join-Path $ProjectRoot 'modules') -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)

$placeholderTools = foreach ($module in $placeholderModules) {
    $stageName = Split-Path -Path (Split-Path -Path $module.FullName -Parent) -Leaf
    $toolId = [IO.Path]::GetFileNameWithoutExtension($module.Name)
    $tool = $allTools | Where-Object { $_.Stage -eq $stageName -and $_.Id -eq $toolId } | Select-Object -First 1
    if (-not $tool) {
        throw "Unable to map placeholder module to config metadata: $($module.FullName)"
    }
    $tool
}

if ($placeholderTools.Count -ne 19) {
    throw "Expected 19 remaining placeholder tools, found $($placeholderTools.Count)."
}

foreach ($requiredSection in @(
    '# Deferred Tools Execution Plan'
    '## Deferred / Refused Tools'
    '## Foundation Groups'
    '## Recommended Foundation Roadmap'
    '## What This Means for Future Phases'
)) {
    if (-not $planText.Contains($requiredSection)) {
        throw "Deferred execution plan is missing section: $requiredSection"
    }
}

foreach ($requiredFoundation in @(
    'Download provenance and checksum/signature policy'
    'Installer execution policy'
    'AppX/package inventory and restore framework'
    'TrustedInstaller execution framework'
    'Safe Mode recovery/resume framework'
    'Service state capture and rollback'
    'Driver state capture and rollback'
    'File/registry state capture and rollback'
    'Destructive cleanup policy'
    'Reboot/recovery workflow'
)) {
    if (-not $planText.Contains($requiredFoundation)) {
        throw "Deferred execution plan is missing foundation group: $requiredFoundation"
    }
}

foreach ($requiredPhrase in @(
    'Refused tools are blocked, not abandoned.'
    'Visual-only or disabled cards are the correct state for these tools until their prerequisites exist.'
    'Windows 11 is BoostLab'
    'NVIDIA'
)) {
    if (-not $planText.Contains($requiredPhrase)) {
        throw "Deferred execution plan is missing phrase: $requiredPhrase"
    }
}

foreach ($tool in $placeholderTools) {
    if (-not $planText.Contains([string]$tool.Title)) {
        throw "Deferred execution plan is missing placeholder tool title '$($tool.Title)'."
    }
    $sourcePathFragment = "source-ultimate/"
    if (-not $planText.Contains($sourcePathFragment)) {
        throw "Deferred execution plan must include Ultimate source paths for deferred tools."
    }
}

foreach ($forbiddenTitle in @('Loudness EQ', 'NVME Faster Driver')) {
    if ($planText.Contains("| $forbiddenTitle |")) {
        throw "Deferred execution plan must not list deleted tool '$forbiddenTitle' as active."
    }
}

if (-not $triageText.Contains('docs/deferred-tools-execution-plan.md')) {
    throw 'Remaining migration triage does not link to the deferred execution plan.'
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
    Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
    ForEach-Object {
        '{0}|{1}' -f `
            $_.FullName.Substring($root.Length + 1).Replace('\', '/'), `
            (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    }
$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $manifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n")))
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}

if (@($sourceLines).Count -ne 49 -or $manifestHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') {
    throw 'source-ultimate content or paths changed.'
}

[pscustomobject]@{
    Success                = $true
    DeferredToolCount      = $placeholderTools.Count
    FoundationGroupCount   = 10
    RoadmapStepCount       = 10
    SourceUltimateUnchanged = $true
    Message                = 'Deferred tools execution plan documents all remaining placeholders and their required foundations.'
    Timestamp              = Get-Date
}
