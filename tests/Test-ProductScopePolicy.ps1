[CmdletBinding()]
param(
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'BoostLab.Hashing.ps1')
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $scriptPath = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $PSCommandPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $MyInvocation.MyCommand.Path
    }
    else {
        throw 'Unable to determine the product-scope validator script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$filesToCheck = @(
    Join-Path $ProjectRoot 'AGENTS.md'
    Join-Path $ProjectRoot 'CODEX_INSTRUCTIONS.md'
    Join-Path $ProjectRoot 'BOOSTLAB_BLUEPRINT.md'
    Join-Path $ProjectRoot 'docs\remaining-tool-migration-triage.md'
)

$errors = [System.Collections.Generic.List[string]]::new()

foreach ($path in $filesToCheck) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $errors.Add("Required governance file was not found: $path")
        continue
    }

    $text = Get-Content -LiteralPath $path -Raw
    if (-not ($text.Contains('NVIDIA only') -or $text.Contains('NVIDIA-only'))) {
        $errors.Add("Missing NVIDIA-only scope text in $path")
    }
    foreach ($phrase in @(
        'Windows 11'
        'Windows 10'
        'Windows 10 host'
        'Windows 10 optimization'
        'branch-level scope'
        'shared Windows behavior'
        'preparation'
        'AMD'
        'Intel'
        'GPU-neutral'
        'NVIDIA'
        'disabled, visual-only, or not implemented'
    )) {
        if (-not $text.Contains($phrase)) {
            $errors.Add("Missing scope phrase '$phrase' in $path")
        }
    }
}

if ($errors.Count -gt 0) {
    throw "Product scope policy validation failed:`r`n- $($errors -join "`r`n- ")"
}

[pscustomobject]@{
    Success        = $true
    FileCount      = $filesToCheck.Count
    PhraseCount    = 12
    Message        = 'Branch-level Windows and GPU product scope is documented.'
    Timestamp      = Get-Date
}
