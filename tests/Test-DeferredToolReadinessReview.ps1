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
        throw 'Unable to determine the deferred readiness validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$reviewPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$modulesRoot = Join-Path $ProjectRoot 'modules'

if (-not (Test-Path -LiteralPath $reviewPath -PathType Leaf)) {
    throw "Deferred tool readiness review was not found: $reviewPath"
}
if (-not (Test-Path -LiteralPath $planPath -PathType Leaf)) {
    throw "Deferred tools execution plan was not found: $planPath"
}

$reviewText = Get-Content -LiteralPath $reviewPath -Raw
$planText = Get-Content -LiteralPath $planPath -Raw
$config = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })
$placeholderModules = @(
    Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' |
        Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw).Contains(
                'ToolModule.Placeholder.ps1'
            )
        }
)

$placeholderTools = foreach ($module in $placeholderModules) {
    $stageName = Split-Path -Path (Split-Path -Path $module.FullName -Parent) -Leaf
    $toolId = [IO.Path]::GetFileNameWithoutExtension($module.Name)
    $tool = $allTools |
        Where-Object { $_.Stage -eq $stageName -and $_.Id -eq $toolId } |
        Select-Object -First 1
    if (-not $tool) {
        throw "Unable to map placeholder module to config metadata: $($module.FullName)"
    }
    $tool
}

if ($placeholderTools.Count -ne 19) {
    throw "Expected 19 remaining placeholder tools, found $($placeholderTools.Count)."
}

foreach ($requiredSection in @(
    '# Deferred Tool Readiness Review'
    '## Review Inputs'
    '## Category Definitions'
    '## Readiness Summary'
    '## Per-Tool Review'
    '## Readiness Categories'
    '## Recommended Next Phase List'
    '## Remaining Blockers'
    '## Conclusion'
)) {
    if (-not $reviewText.Contains($requiredSection)) {
        throw "Deferred readiness review is missing section: $requiredSection"
    }
}

foreach ($requiredCategory in @(
    'Not ready: **3**'
    'Foundation-ready but needs production allowlists: **4**'
    'Foundation-ready but needs artifact provenance approvals: **7**'
    'Foundation-ready but needs tool-specific design: **4**'
    'Candidate for next implementation attempt: **1**'
)) {
    if (-not $reviewText.Contains($requiredCategory)) {
        throw "Deferred readiness review is missing category summary: $requiredCategory"
    }
}

foreach ($tool in $placeholderTools) {
    if (-not $reviewText.Contains([string]$tool.Title)) {
        throw "Deferred readiness review is missing placeholder tool title '$($tool.Title)'."
    }
    if (-not $reviewText.Contains([string]$tool.Id)) {
        throw "Deferred readiness review is missing placeholder tool id '$($tool.Id)'."
    }
}

foreach ($requiredPhrase in @(
    'all existing foundations remain deny-by-default'
    'No real third-party artifacts are approved in the provenance manifest.'
    'No real TrustedInstaller scopes are approved.'
    'No real Safe Mode scopes are approved.'
    'The next implementation phases should therefore be narrow'
)) {
    if (-not $reviewText.ToLowerInvariant().Contains($requiredPhrase.ToLowerInvariant())) {
        throw "Deferred readiness review is missing phrase: $requiredPhrase"
    }
}

if (-not $planText.Contains('docs/deferred-tool-readiness-review.md')) {
    throw 'Deferred tools execution plan does not link to the readiness review.'
}

foreach ($deletedTool in @('Loudness EQ', 'NVME Faster Driver')) {
    if ($reviewText.Contains("| $deletedTool |")) {
        throw "Deferred readiness review must not list deleted tool '$deletedTool' as active."
    }
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
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

[pscustomobject]@{
    Success                   = $true
    DeferredToolCount         = $placeholderTools.Count
    CategoryCount             = 5
    CandidateCount            = 1
    SourceUltimateUnchanged   = $true
    Message                   = 'Deferred readiness review documents all current placeholders and their post-foundation status.'
    Timestamp                 = Get-Date
}
