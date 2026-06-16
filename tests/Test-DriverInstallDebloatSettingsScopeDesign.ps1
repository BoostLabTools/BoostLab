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
        throw 'Unable to determine the Driver Install Debloat & Settings scope/provenance design validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$designPath = Join-Path $ProjectRoot 'docs\tool-designs\driver-install-debloat-settings-scope-provenance-design.md'
$readinessPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\5 Graphics\1 Driver Install Debloat & Settings.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Graphics\driver-install-debloat-settings.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$artifactPolicyPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$driverPolicyPath = Join-Path $ProjectRoot 'config\DriverStatePolicy.psd1'
$appxPolicyPath = Join-Path $ProjectRoot 'config\AppxPackagePolicy.psd1'
$rollbackPolicyPath = Join-Path $ProjectRoot 'config\RollbackPolicy.psd1'
$servicePolicyPath = Join-Path $ProjectRoot 'config\ServiceRollbackPolicy.psd1'
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
    $artifactPolicyPath,
    $driverPolicyPath,
    $appxPolicyPath,
    $rollbackPolicyPath,
    $servicePolicyPath,
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
$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPolicyPath
$driverPolicy = Import-PowerShellDataFile -LiteralPath $driverPolicyPath
$appxPolicy = Import-PowerShellDataFile -LiteralPath $appxPolicyPath
$rollbackPolicy = Import-PowerShellDataFile -LiteralPath $rollbackPolicyPath
$servicePolicy = Import-PowerShellDataFile -LiteralPath $servicePolicyPath
$cleanupPolicy = Import-PowerShellDataFile -LiteralPath $cleanupPolicyPath
$rebootPolicy = Import-PowerShellDataFile -LiteralPath $rebootPolicyPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })

$expectedSourceHash = 'E69EFF538E7CE6108233C525A2BB88BA2D549CE6954AE751BE7BED778271C26F'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
if ($actualSourceHash -ne $expectedSourceHash) {
    throw "Driver Install Debloat & Settings source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."
}

foreach ($requiredSection in @(
    '# Driver Install Debloat and Settings Scope Provenance Design',
    '## Purpose',
    '## Source Reference',
    '## Product Scope Decision',
    '## Source Behavior Summary',
    '## Current Decision',
    '## Behavior Groups',
    '### 1. GPU/Vendor Detection Behavior',
    '### 2. NVIDIA-Supported Branch Behavior',
    '### 3. Unsupported AMD Branch Behavior If Present',
    '### 4. Unsupported Intel Branch Behavior If Present',
    '### 5. NVIDIA Driver Download Behavior',
    '### 6. External Helper/Tool Download Behavior',
    '### 7. Driver Extraction Behavior',
    '### 8. Driver Install Behavior',
    '### 9. Driver Debloat/Removal Behavior',
    '### 10. NVIDIA App / FrameView / GeForce Experience Behavior If Present',
    '### 11. NVIDIA Control Panel / AppX Behavior If Present',
    '### 12. NVIDIA Profile Import or Driver-Profile Settings Behavior If Present',
    '### 13. Registry Settings Behavior',
    '### 14. File/Directory Cleanup or Deletion Behavior',
    '### 15. Service or Scheduled Task Behavior If Present',
    '### 16. Process Stop Behavior If Present',
    '### 17. Reboot/Restart Behavior',
    '### 18. Default/Restore Behavior',
    '### 19. Unsupported Broad Driver/File/Registry/Package Targets',
    '## Exact Source Target Inventory',
    '## Future Safe Apply/Open/Install Requirements',
    '## Default and Restore Boundary',
    '## Production Approval State'
)) {
    if (-not $designText.Contains($requiredSection)) {
        throw "Driver Install Debloat & Settings scope/provenance design is missing section: $requiredSection"
    }
}

foreach ($requiredPhrase in @(
    'Source SHA-256: `E69EFF538E7CE6108233C525A2BB88BA2D549CE6954AE751BE7BED778271C26F`',
    'Driver Install Debloat & Settings remains a refused placeholder',
    'No production download/installer/executable/driver/profile/AppX/registry/file/service/task/cleanup/reboot scopes',
    'The NVIDIA branch is the only branch that may be considered',
    'The AMD branch is unsupported',
    'The Intel branch is unsupported',
    'Unique URL count: `5`',
    'Non-elevation `Start-Process` command count: `15`',
    '`Remove-Item` command count: `41`',
    '`reg add` command count: `33`',
    '`sc stop` command count: `11`',
    'NVIDIA profile setting count in `inspector.nip`: `31`',
    'display loss',
    'black screen',
    'Safe Mode recovery',
    'Current Default/Restore must remain unavailable',
    'Artifact approvals: none.',
    'Driver scopes: none.',
    'AppX package scopes: none.'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "Driver Install Debloat & Settings scope/provenance design is missing phrase: $requiredPhrase"
    }
}

foreach ($requiredField in @(
    'Exact source targets:',
    'Intended mutation or launch type:',
    'Required foundation:',
    'Required future production allowlist:',
    'Required artifact provenance before download/launch:',
    'Required driver inventory/capture before mutation:',
    'Required file/registry/AppX/service capture before mutation:',
    'Required confirmation level:',
    'Required verification:',
    'Rollback/restore feasibility:',
    'Risk level:',
    'Later implementation decision:'
)) {
    if (-not $designText.Contains($requiredField)) {
        throw "Driver Install Debloat & Settings scope/provenance design is missing per-group field: $requiredField"
    }
}

$urls = @(
    Select-String -LiteralPath $sourcePath -Pattern 'https?://[^"\s]+' |
        ForEach-Object { $_.Matches.Value } |
        Sort-Object -Unique
)
if ($urls.Count -ne 5) {
    throw "Expected 5 unique source URLs, found $($urls.Count)."
}
foreach ($url in $urls) {
    if (-not $designText.Contains($url)) {
        throw "Driver Install Debloat & Settings design is missing source URL: $url"
    }
}

$launchLines = @(
    Select-String -LiteralPath $sourcePath -Pattern 'Start-Process[^\r\n]+' |
        ForEach-Object { $_.Matches[0].Value } |
        Where-Object { $_ -notmatch 'PowerShell\.exe' }
)
if ($launchLines.Count -ne 15) {
    throw "Expected 15 non-elevation source launch lines, found $($launchLines.Count)."
}
foreach ($line in @(
    'Start-Process "$env:SystemRoot\Temp\nvidiadriver\setup.exe" -ArgumentList "-s -noreboot -noeula -clean" -Wait -NoNewWindow',
    'Start-Process "winget" -ArgumentList "install `"9NF8H0H7WMLT`" --silent --accept-package-agreements --accept-source-agreements --disable-interactivity --no-upgrade" -Wait -WindowStyle Hidden',
    'Start-Process -wait "$env:SystemRoot\Temp\inspector.exe" -ArgumentList "-silentImport -silent $env:SystemRoot\Temp\inspector.nip"',
    'Start-Process -Wait "$env:SystemRoot\Temp\amddriver\Bin64\ATISetup.exe" -ArgumentList "-INSTALL -VIEW:2" -WindowStyle Hidden',
    'Start-Process "cmd.exe" -ArgumentList "/c `"$env:SystemDrive\inteldriver\Installer.exe`" -f --noExtras --terminateProcesses -s" -WindowStyle Hidden -Wait',
    'Start-Process "ms-settings:display"',
    'Start-Process shell:appsFolder\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj!NVIDIACorp.NVIDIAControlPanel',
    'Start-Process mmsys.cpl'
)) {
    if (-not $designText.Contains($line)) {
        throw "Driver Install Debloat & Settings design is missing source launch command: $line"
    }
}

$removeItemCount = @(
    Select-String -LiteralPath $sourcePath -Pattern 'Remove-Item\s+"'
).Count
if ($removeItemCount -ne 41) {
    throw "Expected 41 Remove-Item source commands, found $removeItemCount."
}

$profileSettingCount = @(
    Select-String -LiteralPath $sourcePath -Pattern '<ProfileSetting>'
).Count
if ($profileSettingCount -ne 31) {
    throw "Expected 31 NVIDIA profile settings, found $profileSettingCount."
}

foreach ($requiredSourceTarget in @(
    'Write-Host " 1.  NVIDIA"',
    'Write-Host " 2.  AMD"',
    'Write-Host " 3.  INTEL`n"',
    '$env:SystemRoot\Temp\nvidiadriver\Display.Nview',
    '$env:SystemRoot\Temp\nvidiadriver\NvApp\NvConfigGenerator.dll',
    '$env:SystemRoot\Temp\nvidiadriver\setup.exe',
    '$env:SystemRoot\Temp\inspector.exe',
    '$env:SystemRoot\Temp\inspector.nip',
    'C:\ProgramData\NVIDIA Corporation\Drs',
    'Get-AppxPackage -allusers *Microsoft.Winget.Source* | Remove-AppxPackage',
    'HKLM\System\ControlSet001\Services\nvlddmkm\Parameters\Global\NVTweak',
    'HKCU\Software\NVIDIA Corporation\NvTray',
    'HKLM\SYSTEM\ControlSet001\Services\nvlddmkm\Parameters\FTS',
    'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\MonitorDataStore',
    'HKLM\SYSTEM\ControlSet001\Enum\$instanceID\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties',
    'registry::HKEY_CURRENT_USER\Control Panel\NotifyIconSettings',
    'AMD Crash Defender Service',
    'amdfendr',
    'IntelGFXFWupdateTool',
    'PresentMonService',
    'Unregister-ScheduledTask -TaskName "StartCN" -Confirm:$false',
    'shutdown -r -t 00'
)) {
    if (-not $designText.Contains($requiredSourceTarget)) {
        throw "Driver Install Debloat & Settings design is missing source target: $requiredSourceTarget"
    }
}

if (-not $readinessText.Contains('docs/tool-designs/driver-install-debloat-settings-scope-provenance-design.md')) {
    throw 'Deferred readiness review does not link to the Driver Install Debloat & Settings scope/provenance design.'
}
if (-not $planText.Contains('docs/tool-designs/driver-install-debloat-settings-scope-provenance-design.md')) {
    throw 'Deferred tools execution plan does not link to the Driver Install Debloat & Settings scope/provenance design.'
}

if (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) {
    throw 'Driver Install Debloat & Settings module is no longer a placeholder.'
}
if ($moduleText -match 'IWR|Invoke-WebRequest|Start-BitsTransfer|Start-Process|winget|Get-AppxPackage|Remove-AppxPackage|Get-PnpDevice|7z\.exe|setup\.exe|inspector|reg add|reg delete|Remove-Item|sc stop|sc delete|shutdown') {
    throw 'Driver Install Debloat & Settings placeholder module appears to contain real download, launch, or mutation behavior.'
}

if (@($artifactPolicy.Artifacts).Count -ne 0) {
    throw "Artifact approvals were added unexpectedly: $(@($artifactPolicy.Artifacts).Count)"
}
if (@($driverPolicy.DriverScopes).Count -ne 0) {
    throw "Driver production scopes were approved unexpectedly: $(@($driverPolicy.DriverScopes).Count)"
}
if (@($appxPolicy.PackageScopes).Count -ne 0) {
    throw "AppX package production scopes were approved unexpectedly: $(@($appxPolicy.PackageScopes).Count)"
}
if (@($rollbackPolicy.FileScopes).Count -ne 0 -or @($rollbackPolicy.RegistryScopes).Count -ne 0) {
    throw 'File or registry production scopes were approved unexpectedly.'
}
if (@($servicePolicy.ServiceScopes).Count -ne 0) {
    throw "Service production scopes were approved unexpectedly: $(@($servicePolicy.ServiceScopes).Count)"
}
if (@($cleanupPolicy.CleanupScopes).Count -ne 0) {
    throw "Cleanup production scopes were approved unexpectedly: $(@($cleanupPolicy.CleanupScopes).Count)"
}
if (@($rebootPolicy.WorkflowScopes).Count -ne 0) {
    throw "Reboot workflow production scopes were approved unexpectedly: $(@($rebootPolicy.WorkflowScopes).Count)"
}

$tool = $allTools |
    Where-Object { $_.Id -eq 'driver-install-debloat-settings' -and $_.Stage -eq 'Graphics' } |
    Select-Object -First 1
if (-not $tool) {
    throw 'Driver Install Debloat & Settings catalog entry was not found.'
}
if (-not (@($tool.Actions) -contains 'Analyze') -or -not (@($tool.Actions) -contains 'Apply') -or -not (@($tool.Actions) -contains 'Restore')) {
    throw 'Driver Install Debloat & Settings catalog actions changed unexpectedly.'
}

$activeTools = @($allTools)
$placeholderModules = @(
    Get-ChildItem -Path (Join-Path $ProjectRoot 'modules') -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
if ($activeTools.Count -ne 48) {
    throw "Expected 48 active tools, found $($activeTools.Count)."
}
if ($placeholderModules.Count -ne 18) {
    throw "Expected 18 placeholder modules, found $($placeholderModules.Count)."
}
if (($activeTools.Count - $placeholderModules.Count) -ne 30) {
    throw "Expected 30 implemented tools, found $($activeTools.Count - $placeholderModules.Count)."
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
    ToolId                    = 'driver-install-debloat-settings'
    SourceHash                = $actualSourceHash
    UrlCount                  = $urls.Count
    LaunchCommandCount        = $launchLines.Count
    RemoveItemCount           = $removeItemCount
    ProfileSettingCount       = $profileSettingCount
    ActiveToolCount           = $activeTools.Count
    ImplementedToolCount      = $activeTools.Count - $placeholderModules.Count
    PlaceholderToolCount      = $placeholderModules.Count
    ArtifactApprovals         = @($artifactPolicy.Artifacts).Count
    ProductionDriverScopes    = @($driverPolicy.DriverScopes).Count
    ProductionPackageScopes   = @($appxPolicy.PackageScopes).Count
    ProductionFileScopes      = @($rollbackPolicy.FileScopes).Count
    ProductionRegistryScopes  = @($rollbackPolicy.RegistryScopes).Count
    ProductionServiceScopes   = @($servicePolicy.ServiceScopes).Count
    ProductionCleanupScopes   = @($cleanupPolicy.CleanupScopes).Count
    ProductionRebootScopes    = @($rebootPolicy.WorkflowScopes).Count
    SourceUltimateUnchanged   = $true
    DeletedToolsRemainDeleted = $true
    Message                   = 'Driver Install Debloat & Settings scope/provenance design is present, linked, NVIDIA-scoped, and non-executing.'
    Timestamp                 = Get-Date
}

