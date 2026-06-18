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
        throw 'Unable to determine the Start Menu Taskbar scope design validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$designPath = Join-Path $ProjectRoot 'docs\tool-designs\start-menu-taskbar-scope-design.md'
$readinessPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\1 Start Menu Taskbar.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\start-menu-taskbar.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$configRoot = Join-Path $ProjectRoot 'config'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

foreach ($path in @($designPath, $readinessPath, $planPath, $sourcePath, $modulePath, $configPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file was not found: $path"
    }
}

$designText = Get-Content -LiteralPath $designPath -Raw
$readinessText = Get-Content -LiteralPath $readinessPath -Raw
$planText = Get-Content -LiteralPath $planPath -Raw
$moduleText = Get-Content -LiteralPath $modulePath -Raw
$config = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })

$expectedSourceHash = '88BEB0E8C41F7A32AAE6A0A6E184E87E678FB25BEDEB092C63F4BA98B8712E91'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
if ($actualSourceHash -ne $expectedSourceHash) {
    throw "Start Menu Taskbar source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."
}

foreach ($requiredSection in @(
    '# Start Menu Taskbar Scope Design',
    '## Purpose',
    '## Source Reference',
    '## Product Scope Decision',
    '## Current Decision',
    '## Behavior Groups',
    '### 1. Start Layout Files',
    '### 2. start2.bin Behavior',
    '### 3. Taskband Registry Behavior',
    '### 4. Quick Launch Directory Behavior',
    '### 5. Layout XML Behavior',
    '### 6. Policy Registry Behavior',
    '### 7. NotifyIconSettings Behavior',
    '### 8. Hidden-Folder Attribute Behavior',
    '### 9. Explorer Process Handling',
    '### 10. Default Behavior',
    '### 11. Unsupported Windows 10-Only Branches',
    '## Future Safe Apply Requirements',
    '## Default and Restore Boundary',
    '## Explorer Handling Requirements',
    '## Production Approval State'
)) {
    if (-not $designText.Contains($requiredSection)) {
        throw "Start Menu Taskbar scope design is missing section: $requiredSection"
    }
}

foreach ($requiredPhrase in @(
    'Source SHA-256: `88BEB0E8C41F7A32AAE6A0A6E184E87E678FB25BEDEB092C63F4BA98B8712E91`',
    'Start Menu Taskbar remains refused',
    'No production allowlists or scopes are approved by this document.',
    'Windows 10-only branches/options must remain unsupported',
    'Phase 36',
    'Phase 38',
    'Phase 40',
    'file and registry state capture',
    'destructive cleanup policy',
    'reboot/recovery workflow',
    'Current Default/Restore must remain unavailable',
    'No `Stop-Process -Force -Name explorer` without explicit confirmation.'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "Start Menu Taskbar scope design is missing phrase: $requiredPhrase"
    }
}

foreach ($requiredSourceTarget in @(
    'Taskband',
    'Quick Launch',
    'StartMenuLayout.xml',
    'start2.bin',
    'NotifyIconSettings',
    'Stop-Process -Force -Name explorer',
    'LockedStartLayout',
    'StartLayoutFile',
    'EnableAutoTray',
    'HKLM\Software\Policies\Microsoft\Dsh',
    'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarAl',
    'HKLM\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14\2792562829\EnabledState'
)) {
    if (-not $designText.Contains($requiredSourceTarget)) {
        throw "Start Menu Taskbar scope design is missing source target: $requiredSourceTarget"
    }
}

foreach ($requiredField in @(
    'Target type:',
    'Intended mutation type:',
    'Required foundation:',
    'Required production allowlist:',
    'Required state capture:',
    'Required verification:',
    'Rollback feasibility:',
    'Risk level:',
    'Later implementation decision:'
)) {
    if (-not $designText.Contains($requiredField)) {
        throw "Start Menu Taskbar scope design is missing per-group field: $requiredField"
    }
}

if (-not $readinessText.Contains('docs/tool-designs/start-menu-taskbar-scope-design.md')) {
    throw 'Deferred readiness review does not link to the Start Menu Taskbar scope design.'
}
if (-not $planText.Contains('docs/tool-designs/start-menu-taskbar-scope-design.md')) {
    throw 'Deferred tools execution plan does not link to the Start Menu Taskbar scope design.'
}

if (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) {
    throw 'Start Menu Taskbar module is no longer a placeholder.'
}
if ($moduleText -match 'Stop-Process|regedit|Remove-Item|Set-ItemProperty|Copy-Item|certutil|attrib') {
    throw 'Start Menu Taskbar placeholder module appears to contain real mutation behavior.'
}

$startMenuTool = $allTools |
    Where-Object { $_.Id -eq 'start-menu-taskbar' -and $_.Stage -eq 'Windows' } |
    Select-Object -First 1
if (-not $startMenuTool) {
    throw 'Start Menu Taskbar catalog entry was not found.'
}

$activeTools = @($allTools)
$placeholderModules = @(
    Get-ChildItem -Path (Join-Path $ProjectRoot 'modules') -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
if ($activeTools.Count -ne 55) {
    throw "Expected 55 active tools, found $($activeTools.Count)."
}
if ($placeholderModules.Count -ne 18) {
    throw "Expected 18 placeholder modules, found $($placeholderModules.Count)."
}
if (($activeTools.Count - $placeholderModules.Count) -ne 37) {
    throw "Expected 37 implemented tools, found $($activeTools.Count - $placeholderModules.Count)."
}

$policyMentions = @(
    Get-ChildItem -LiteralPath $configRoot -Filter '*.psd1' -File |
        Where-Object { $_.Name -notin @('Stages.psd1', 'ProcessHandlingPolicy.psd1') } |
        Where-Object {
            $text = Get-Content -LiteralPath $_.FullName -Raw
            $text.Contains('start-menu-taskbar') -or $text.Contains('Start Menu Taskbar')
        }
)
if ($policyMentions.Count -ne 0) {
    throw "Start Menu Taskbar was found in production policy config: $($policyMentions.FullName -join ', ')"
}

$processPolicyPath = Join-Path $configRoot 'ProcessHandlingPolicy.psd1'
if (Test-Path -LiteralPath $processPolicyPath -PathType Leaf) {
    $processPolicy = Import-PowerShellDataFile -LiteralPath $processPolicyPath
    if (
        $processPolicy.ProcessHandlingScopes.Count -ne 0 -or
        $processPolicy.ApprovedProcessTargets.Count -ne 0
    ) {
        throw 'Process handling policy unexpectedly approved a production process scope or target.'
    }
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
    ToolId                     = 'start-menu-taskbar'
    SourceHash                 = $actualSourceHash
    ActiveToolCount            = $activeTools.Count
    ImplementedToolCount       = $activeTools.Count - $placeholderModules.Count
    PlaceholderToolCount       = $placeholderModules.Count
    ProductionScopesApproved   = $false
    SourceUltimateUnchanged    = $true
    DeletedToolsRemainDeleted  = $true
    Message                    = 'Start Menu Taskbar scope design is present, linked, and non-executing.'
    Timestamp                  = Get-Date
}



