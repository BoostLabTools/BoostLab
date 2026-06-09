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
        throw 'Unable to determine the Restore Point test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\RestorePoint.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\23 Restore Point.ps1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$recordPath = Join-Path $ProjectRoot 'docs\migrations\restore-point.md'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration['Stages'] | ForEach-Object { $_['Tools'] })
$tool = $tools | Where-Object { $_['Id'] -eq 'restore-point' } | Select-Object -First 1
if ($null -eq $tool) {
    throw 'Restore Point metadata is missing.'
}
if (
    [string]$tool['Stage'] -ne 'Windows' -or
    [string]$tool['RiskLevel'] -ne 'medium' -or
    (@($tool['Actions']) -join ',') -ne 'Apply,Open'
) {
    throw 'Restore Point stage, risk, or actions are incorrect.'
}

$capabilities = $tool['Capabilities']
$expectedTrueCapabilities = @('RequiresAdmin', 'CanModifyRegistry', 'NeedsExplicitConfirmation')
foreach ($field in $capabilities.Keys) {
    $expected = $field -in $expectedTrueCapabilities
    if ([bool]$capabilities[$field] -ne $expected) {
        throw "Restore Point capability '$field' is incorrect."
    }
}

if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne 'E9164E079DB76112A59D686B9C0C77B1A9B26E69CA4326B3B4FF46BF63C03C34') {
    throw 'Restore Point Ultimate source hash changed.'
}

$source = Get-Content -Raw -LiteralPath $sourcePath
$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredText in @(
    'SystemRestorePointCreationFrequency'
    'Enable-ComputerRestore -Drive $script:BoostLabRestoreDrive -ErrorAction Stop'
    'Checkpoint-Computer'
    '$script:BoostLabRestorePointName = ''backup'''
    '$script:BoostLabRestorePointType = ''MODIFY_SETTINGS'''
    'Start-Process "$env:SystemRoot\system32\control.exe" -ArgumentList "sysdm.cpl,,4"'
    'Start-Process "rstrui"'
    '$script:BoostLabImplementedActions = @(''Apply'', ''Open'')'
    '[bool]$Confirmed = $false'
    'if (-not $Confirmed)'
    'Restore point created.'
    'finally'
)) {
    if (-not $moduleSource.Contains($requiredText)) {
        throw "Restore Point module is missing: $requiredText"
    }
}
foreach ($sourceText in @(
    'Enable-ComputerRestore -Drive "C:\"'
    'Checkpoint-Computer -Description "backup" -RestorePointType "MODIFY_SETTINGS"'
    'Start-Process "$env:SystemRoot\system32\control.exe" -ArgumentList "sysdm.cpl,,4"'
    'Start-Process "rstrui"'
)) {
    if (-not $source.Contains($sourceText)) {
        throw "Restore Point source no longer contains: $sourceText"
    }
}
foreach ($forbiddenText in @(
    'Disable-ComputerRestore'
    'Restart-Computer'
    'Stop-Computer'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
)) {
    if ($moduleSource.Contains($forbiddenText)) {
        throw "Restore Point module contains forbidden behavior: $forbiddenText"
    }
}

$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $modulePath,
    [ref]$tokens,
    [ref]$parseErrors
)
if (@($parseErrors).Count -gt 0) {
    throw "Restore Point module syntax error: $($parseErrors[0].Message)"
}
$commands = @(
    $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
        $true
    ) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }
)
if (@($commands | Where-Object { $_ -eq 'Start-Process' }).Count -ne 2) {
    throw 'Restore Point Open must preserve exactly two Start-Process launchers.'
}
if (@($commands | Where-Object { $_ -eq 'Enable-ComputerRestore' }).Count -ne 1) {
    throw 'Restore Point Apply must enable System Restore exactly once.'
}
if (@($commands | Where-Object { $_ -eq 'Checkpoint-Computer' }).Count -ne 1) {
    throw 'Restore Point Apply must create exactly one restore point.'
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    $applyPlan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Apply' -IsDryRun $false
    if (
        -not $applyPlan.NeedsExplicitConfirmation -or
        $applyPlan.CanReboot -or
        $applyPlan.RequiresInternet -or
        $applyPlan.ConfirmationMessage -notmatch 'restore point named backup' -or
        $applyPlan.ConfirmationMessage -notmatch 'No restart is required'
    ) {
        throw 'Restore Point Apply action plan is not safely confirmation-gated.'
    }
    $openPlan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Open' -IsDryRun $false
    if ($openPlan.NeedsExplicitConfirmation -or $openPlan.CanReboot) {
        throw 'Restore Point Open received an unnecessary confirmation or reboot capability.'
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredText in @(
    '''restore-point'' = @{'
    '''Windows\RestorePoint.psm1'''
    'Actions = @(''Apply'', ''Open'')'
    '$actionCommand.Parameters.ContainsKey(''Confirmed'')'
    'ToolAction.Completed'
)) {
    if (-not $executionSource.Contains($requiredText)) {
        throw "Restore Point runtime mapping is missing: $requiredText"
    }
}

$uiSource = Get-Content -Raw -LiteralPath $uiPath
foreach ($requiredText in @(
    '$toolId -eq ''restore-point'''
    '-Label ''Restore point name'''
    '-Label ''Timestamp'''
)) {
    if (-not $uiSource.Contains($requiredText)) {
        throw "Restore Point Latest Result rendering is missing: $requiredText"
    }
}

$record = Get-Content -Raw -LiteralPath $recordPath
foreach ($requiredText in @(
    'source-ultimate/6 Windows/23 Restore Point.ps1'
    'E9164E079DB76112A59D686B9C0C77B1A9B26E69CA4326B3B4FF46BF63C03C34'
    'Approved by Yazan'
    'Automated tests must not invoke Apply or Open.'
)) {
    if (-not $record.Contains($requiredText)) {
        throw "Restore Point migration record is missing: $requiredText"
    }
}

$deletedToolNames = @(
    'Windows Activation Helper'
    'Firewall'
    'DEP'
    'File Download Security Warning'
    'MPO'
    'FSO'
    'FSE'
    'Hardware Flip'
    'AMD ULPS'
    'WHQL Secure Boot Bypass'
    'Keyboard Shortcuts'
    'Search Shell Mobsync'
    'NVME Faster Driver'
    'Core 1 Thread 1'
    'DDU'
    'UAC'
    'Scaling'
    'Start Menu Shortcuts'
)
$normalizedDeletedNames = @(
    $deletedToolNames | ForEach-Object {
        ($_ -replace '[^a-zA-Z0-9]+', '-').Trim('-').ToLowerInvariant()
    }
)
$deletedModules = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'modules') -Recurse -File -Filter '*.psm1' |
        Where-Object {
            [System.IO.Path]::GetFileNameWithoutExtension($_.Name).ToLowerInvariant() -in $normalizedDeletedNames
        }
)
if ($deletedModules.Count -gt 0) {
    throw "Deleted tool modules were found: $($deletedModules.FullName -join ', ')"
}

$allModules = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'modules') -Recurse -File -Filter '*.psm1' |
        Where-Object { $_.Directory.Parent.FullName -eq (Join-Path $ProjectRoot 'modules') }
)
$implementedCount = @(
    $allModules | Where-Object {
        (Get-Content -Raw -LiteralPath $_.FullName).Contains('$script:BoostLabImplementedActions')
    }
).Count
$placeholderCount = @(
    $allModules | Where-Object {
        (Get-Content -Raw -LiteralPath $_.FullName).Contains('ToolModule.Placeholder.ps1')
    }
).Count
if ($implementedCount -ne 18 -or $placeholderCount -ne 31) {
    throw "Unexpected module counts: $implementedCount implemented, $placeholderCount placeholders."
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
    Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
    ForEach-Object {
        '{0}|{1}' -f `
            $_.FullName.Substring($root.Length + 1).Replace('\', '/'), `
            (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    }
$sha256 = [System.Security.Cryptography.SHA256]::Create()
try {
    $sourceManifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n")))
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}
if (
    @($sourceLines).Count -ne 50 -or
    $sourceManifestHash -ne '4F96170AFF67F9EE7A2E765A8DE268570651E22D2F3EE2C02923E0654D2C8EBF'
) {
    throw 'source-ultimate content or paths changed.'
}

[pscustomobject]@{
    Success                 = $true
    ToolId                  = 'restore-point'
    ImplementedActions      = @('Apply', 'Open')
    ApplyExecuted           = $false
    OpenExecuted            = $false
    ImplementedModuleCount  = $implementedCount
    PlaceholderModuleCount  = $placeholderCount
    SourceUltimateUnchanged = $true
    Message                 = 'Restore Point Apply/Open behavior was validated statically; no tool action was executed.'
    Timestamp               = Get-Date
}
