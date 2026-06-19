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
        throw 'Unable to determine the Updates Drivers Block scope design validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

$designPath = Join-Path $ProjectRoot 'docs\tool-designs\updates-drivers-block-scope-design.md'
$readinessPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\2 Refresh\3 Updates Drivers Block.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Refresh\updates-drivers-block.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$rollbackPolicyPath = Join-Path $ProjectRoot 'config\RollbackPolicy.psd1'
$cleanupPolicyPath = Join-Path $ProjectRoot 'config\CleanupPolicy.psd1'
$rebootPolicyPath = Join-Path $ProjectRoot 'config\RebootRecoveryPolicy.psd1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

foreach ($path in @(
    $designPath,
    $readinessPath,
    $planPath,
    $sourcePath,
    $modulePath,
    $configPath,
    $rollbackPolicyPath,
    $cleanupPolicyPath,
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
$rollbackPolicy = Import-PowerShellDataFile -LiteralPath $rollbackPolicyPath
$cleanupPolicy = Import-PowerShellDataFile -LiteralPath $cleanupPolicyPath
$rebootPolicy = Import-PowerShellDataFile -LiteralPath $rebootPolicyPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })

$expectedSourceHash = '4D4EC652C5A7F78824F53B7DC7FD46DDA948F3716A7CD6FD102D6C678EE11991'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
if ($actualSourceHash -ne $expectedSourceHash) {
    throw "Updates Drivers Block source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."
}

foreach ($requiredSection in @(
    '# Updates Drivers Block Scope Design',
    '## Purpose',
    '## Source Reference',
    '## Product Scope Decision',
    '## Source Behavior Summary',
    '## Current Decision',
    '## Behavior Groups',
    '### 1. Windows Update Policy Registry Behavior',
    '### 2. Driver Update Blocking Registry Behavior',
    '### 3. Custom Update Server / WSUS URL Behavior',
    '### 4. Windows Update Service-Related Behavior If Present',
    '### 5. Six-Mode Menu/Option Behavior',
    '### 6. Bootable-Media Script Behavior',
    '### 7. Temporary/Generated Script Behavior',
    '### 8. Immediate Reboot Commands',
    '### 9. Default/Restore Behavior',
    '### 10. Unsupported Broad Registry or Policy Targets',
    '### 11. Unsupported Windows 10-Only Branches/Options If Present',
    '## Exact Source Target Inventory',
    '### Live Driver-Update Policy Values',
    '### Live Windows Update Policy Values',
    '### Bootable-Media Targets',
    '## Future Safe Apply Requirements',
    '## Default and Restore Boundary',
    '## Production Approval State'
)) {
    if (-not $designText.Contains($requiredSection)) {
        throw "Updates Drivers Block scope design is missing section: $requiredSection"
    }
}

foreach ($requiredPhrase in @(
    'Source SHA-256: `4D4EC652C5A7F78824F53B7DC7FD46DDA948F3716A7CD6FD102D6C678EE11991`',
    'Phase 102 implemented only the bounded live Driver Updates policy branch',
    'Phase 112 supersedes the Phase 102 final customer scope.',
    'Yazan selected Driver Updates Block Bootable USB only as the final scope',
    'Current implemented actions: `Analyze`, `Apply`, `Default`, `Restore`',
    'host registry mutation',
    'No explicit Windows 10-only branch or option is present.',
    'WINDOWS PRO/LTSC/IOT/SERVER ONLY',
    'custom update-server URL',
    'https://fuckyoumicrosoft.com/',
    'setupcomplete.cmd',
    'shutdown /r /t 0',
    'Default is unavailable',
    'Restore is selected captured USB file state only',
    'Unknown, broad, wildcard, whole-key, or unrelated policy targets remain',
    'Deleting policy values can remove intentional existing policy.'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "Updates Drivers Block scope design is missing phrase: $requiredPhrase"
    }
}

foreach ($requiredField in @(
    'Exact source targets:',
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
        throw "Updates Drivers Block scope design is missing per-group field: $requiredField"
    }
}

foreach ($requiredSourceTarget in @(
    'Write-Host "WINDOWS PRO/LTSC/IOT/SERVER ONLY`n"',
    'Write-Host " 1. Block"',
    'Write-Host " 2. Block (Bootable USB)"',
    'Write-Host " 3. Unblock`n"',
    'Write-Host " 4. Block"',
    'Write-Host " 5. Block (Bootable USB)"',
    'Write-Host " 6. Unblock`n"',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\Device Metadata" /v "PreventDeviceMetadataFromNetwork"',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\DeviceInstall\Settings" /v "DisableSendGenericDriverNotFoundToWER"',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\DeviceInstall\Settings" /v "DisableSendRequestAdditionalSoftwareToWER"',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\DriverSearching" /v "SearchOrderConfig"',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "SetAllowOptionalContent"',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "AllowTemporaryEnterpriseFeatureControl"',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate"',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "IncludeRecommendedUpdates"',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "EnableFeaturedSoftware"',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DoNotConnectToWindowsUpdateInternetLocations"',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "UpdateServiceUrlAlternate"',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "WUStatusServer"',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "WUServer"',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "SetDisableUXWUAccess"',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate"',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "UseWUServer"',
    'reg delete "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "WUServer"',
    'Set-Content -Path "$env:SystemRoot\Temp\setupcomplete.cmd"',
    'Move-Item -Path "$env:SystemRoot\Temp\setupcomplete.cmd"',
    'New-Item -Path "$destination\sources\`$OEM`$\`$`$\Setup\Scripts"',
    'Start-Process "$destination\sources\`$OEM`$\`$`$\Setup\Scripts"',
    'shutdown /r /t 0'
)) {
    if (-not $sourceText.Contains($requiredSourceTarget)) {
        throw "Updates Drivers Block source is missing expected target: $requiredSourceTarget"
    }
}

foreach ($requiredDocTarget in @(
    'PreventDeviceMetadataFromNetwork',
    'DisableSendGenericDriverNotFoundToWER',
    'DisableSendRequestAdditionalSoftwareToWER',
    'SearchOrderConfig',
    'SetAllowOptionalContent',
    'AllowTemporaryEnterpriseFeatureControl',
    'ExcludeWUDriversInQualityUpdate',
    'IncludeRecommendedUpdates',
    'EnableFeaturedSoftware',
    'DoNotConnectToWindowsUpdateInternetLocations',
    'UpdateServiceUrlAlternate',
    'WUStatusServer',
    'WUServer',
    'SetDisableUXWUAccess',
    'NoAutoUpdate',
    'UseWUServer',
    '%SystemRoot%\Temp\setupcomplete.cmd',
    '<DriveLetter>:\sources\$OEM$\$$\Setup\Scripts',
    '<DriveLetter>:\sources\$OEM$\$$\Setup\Scripts\setupcomplete.cmd'
)) {
    if (-not $designText.Contains($requiredDocTarget)) {
        throw "Updates Drivers Block scope design is missing documented source target: $requiredDocTarget"
    }
}

if ($sourceText -match 'Stop-Service|Set-Service|New-Service|sc\.exe') {
    throw 'Updates Drivers Block source unexpectedly contains service manipulation behavior.'
}
if ($sourceText -match 'Invoke-WebRequest|IWR|https://(?!fuckyoumicrosoft\.com/)') {
    throw 'Updates Drivers Block source unexpectedly contains download behavior.'
}
if ($sourceText -match 'Windows 10|Win10') {
    throw 'Updates Drivers Block source unexpectedly contains explicit Windows 10 branch text.'
}

if (-not $readinessText.Contains('docs/tool-designs/updates-drivers-block-scope-design.md')) {
    throw 'Deferred readiness review does not link to the Updates Drivers Block scope design.'
}
if (-not $planText.Contains('docs/tool-designs/updates-drivers-block-scope-design.md')) {
    throw 'Deferred tools execution plan does not link to the Updates Drivers Block scope design.'
}

$moduleAst = [Management.Automation.Language.Parser]::ParseFile($modulePath, [ref]$null, [ref]$null)
$moduleCommands = @(
    $moduleAst.FindAll({ param($node) $node -is [Management.Automation.Language.CommandAst] }, $true) |
        ForEach-Object { $_.GetCommandName() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Sort-Object -Unique
)

if ($moduleText.Contains('ToolModule.Placeholder.ps1')) {
    throw 'Updates Drivers Block module is still a placeholder.'
}
foreach ($requiredImplementationText in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'', ''Restore'')',
    '$script:BoostLabExpectedSourceHash = ''4D4EC652C5A7F78824F53B7DC7FD46DDA948F3716A7CD6FD102D6C678EE11991''',
    '$script:BoostLabFinalScope = ''Driver Updates Block (Bootable USB) only''',
    '$script:BoostLabSetupCompleteRelativePath = ''sources\$OEM$\$$\Setup\Scripts\setupcomplete.cmd''',
    'New-BoostLabFileStateCapture',
    'Set-BoostLabRollbackMutationState',
    'Invoke-BoostLabFileRollback',
    'DefaultUnavailable',
    'RestoreRequiresCapturedUsbFileState'
)) {
    if (-not $moduleText.Contains($requiredImplementationText)) {
        throw "Updates Drivers Block module is missing implementation text: $requiredImplementationText"
    }
}
foreach ($forbiddenCommand in @(
    'Start-Process',
    'Invoke-WebRequest',
    'Invoke-RestMethod',
    'Set-Content',
    'Move-Item',
    'Restart-Computer',
    'Stop-Service',
    'Set-Service',
    'Start-Service',
    'pnputil',
    'dism',
    'wusa',
    'UsoClient',
    'wuauclt'
)) {
    if ($forbiddenCommand -in $moduleCommands) {
        throw "Updates Drivers Block module contains forbidden command: $forbiddenCommand"
    }
}
foreach ($forbiddenSourceBranchText in @(
    'fuckyoumicrosoft.com',
    'WUServer',
    'WUStatusServer',
    'UpdateServiceUrlAlternate',
    'DoNotConnectToWindowsUpdateInternetLocations',
    'NoAutoUpdate',
    'UseWUServer',
    'SetDisableUXWUAccess'
)) {
    if ($moduleText.Contains($forbiddenSourceBranchText)) {
        throw "Updates Drivers Block module contains blocked broad Windows Update branch text: $forbiddenSourceBranchText"
    }
}

if ($rollbackPolicy.FileScopes.Count -ne 0 -or $rollbackPolicy.RegistryScopes.Count -ne 0) {
    throw 'File or registry production scopes were approved unexpectedly.'
}
if ($cleanupPolicy.CleanupScopes.Count -ne 0) {
    throw "Cleanup production scopes were approved unexpectedly: $($cleanupPolicy.CleanupScopes.Count)"
}
if ($rebootPolicy.WorkflowScopes.Count -ne 0) {
    throw "Reboot workflow production scopes were approved unexpectedly: $($rebootPolicy.WorkflowScopes.Count)"
}

$tool = $allTools |
    Where-Object { $_.Id -eq 'updates-drivers-block' -and $_.Stage -eq 'Refresh' } |
    Select-Object -First 1
if (-not $tool) {
    throw 'Updates Drivers Block catalog entry was not found.'
}

$activeTools = @($allTools)
$placeholderModules = @(
    Get-ChildItem -Path (Join-Path $ProjectRoot 'modules') -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
if ($activeTools.Count -ne $inventoryBaseline.ActiveTools) {
    throw "Expected $($inventoryBaseline.ActiveTools) active tools, found $($activeTools.Count)."
}
if ($placeholderModules.Count -ne $inventoryBaseline.DeferredPlaceholders) {
    throw "Expected $($inventoryBaseline.DeferredPlaceholders) placeholder modules, found $($placeholderModules.Count)."
}
if (($activeTools.Count - $placeholderModules.Count) -ne $inventoryBaseline.ImplementedTools) {
    throw "Expected $($inventoryBaseline.ImplementedTools) implemented tools, found $($activeTools.Count - $placeholderModules.Count)."
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
    Success                   = $true
    ToolId                    = 'updates-drivers-block'
    SourceHash                = $actualSourceHash
    ActiveToolCount           = $activeTools.Count
    ImplementedToolCount      = $activeTools.Count - $placeholderModules.Count
    PlaceholderToolCount      = $placeholderModules.Count
    ProductionFileScopes      = $rollbackPolicy.FileScopes.Count
    ProductionRegistryScopes  = $rollbackPolicy.RegistryScopes.Count
    ProductionCleanupScopes   = $cleanupPolicy.CleanupScopes.Count
    ProductionRebootScopes    = $rebootPolicy.WorkflowScopes.Count
    SourceUltimateUnchanged   = $true
    DeletedToolsRemainDeleted = $true
    Message                   = 'Updates Drivers Block scope design is present, linked, branch-scoped, and non-executing.'
    Timestamp                 = Get-Date
}



