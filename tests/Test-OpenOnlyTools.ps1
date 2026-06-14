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
        throw 'Unable to determine the Open-only test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$definitions = [ordered]@{
    'date-language-region-time' = @{
        Source = 'source-ultimate\3 Setup\2 Date Language Region Time.ps1'
        Module = 'modules\Setup\date-language-region-time.psm1'
        Record = 'docs\migrations\date-language-region-time.md'
        Hash = '77F4B88F2FBB43F7EACA5F3AD850268210685F41E659DF02EB09279422EA0EE9'
        Launcher = 'Start-Process "ms-settings:dateandtime"'
    }
    'game-mode' = @{
        Source = 'source-ultimate\6 Windows\9 Gamemode.ps1'
        Module = 'modules\Windows\game-mode.psm1'
        Record = 'docs\migrations\game-mode.md'
        Hash = 'F83275C0B3CE135679C2F1D98A1F0BD6B101936E0B2BC17B542DE288EF6A0B82'
        Launcher = 'Start-Process "ms-settings:gaming-gamemode"'
    }
    'pointer-precision' = @{
        Source = 'source-ultimate\6 Windows\10 Pointer Precision.ps1'
        Module = 'modules\Windows\pointer-precision.psm1'
        Record = 'docs\migrations\pointer-precision.md'
        Hash = 'ED66BB1C068DF13FC2D58617E49C2274CEA9609C689FE34F9A0B138AC22F618C'
        Launcher = 'Start-Process "control.exe" -ArgumentList "main.cpl ,2"'
    }
    'sound' = @{
        Source = 'source-ultimate\6 Windows\16 Sound.ps1'
        Module = 'modules\Windows\sound.psm1'
        Record = 'docs\migrations\sound.md'
        Hash = '08FDB346A40595C68FF01D8F0882AC82D8BE27F66D83B400FD5691388B35929B'
        Launcher = 'Start-Process "mmsys.cpl"'
    }
}
$prohibitedCommands = @(
    'Set-ItemProperty'
    'New-ItemProperty'
    'Remove-ItemProperty'
    'Remove-Item'
    'Set-Content'
    'Add-Content'
    'Out-File'
    'Stop-Process'
    'Stop-Service'
    'Set-Service'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'Restart-Computer'
    'Stop-Computer'
    'Checkpoint-Computer'
    'Enable-ComputerRestore'
    'Disable-ComputerRestore'
    'Invoke-Expression'
)

$configuration = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\Stages.psd1')
$tools = @($configuration['Stages'] | ForEach-Object { $_['Tools'] })
$runtimeSource = Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot 'core\Execution.psm1')

foreach ($toolId in $definitions.Keys) {
    $definition = $definitions[$toolId]
    $sourcePath = Join-Path $ProjectRoot $definition.Source
    $modulePath = Join-Path $ProjectRoot $definition.Module
    $recordPath = Join-Path $ProjectRoot $definition.Record

    foreach ($path in @($sourcePath, $modulePath, $recordPath)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Required Phase 10 file is missing: $path"
        }
    }

    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne $definition.Hash) {
        throw "$toolId source-ultimate checksum changed."
    }
    if ((Get-Content -Raw -LiteralPath $sourcePath).Trim() -ne $definition.Launcher) {
        throw "$toolId Ultimate source is not the approved single launcher."
    }

    $tool = $tools | Where-Object { $_['Id'] -eq $toolId } | Select-Object -First 1
    if ($null -eq $tool) {
        throw "$toolId is missing from the catalog."
    }
    if ((@($tool['Actions']) -join ',') -ne 'Open') {
        throw "$toolId must expose Open only."
    }
    if ($tool['Type'] -ne 'assistant' -or $tool['RiskLevel'] -ne 'low') {
        throw "$toolId must be a low-risk assistant."
    }

    $capabilities = $tool['Capabilities']
    if ([bool]$capabilities['RequiresAdmin']) {
        throw "$toolId should not require Administrator for its approved launcher."
    }
    foreach ($field in @(
        'RequiresInternet'
        'CanReboot'
        'CanModifyRegistry'
        'CanModifyServices'
        'CanInstallSoftware'
        'CanDownload'
        'CanModifyDrivers'
        'CanModifySecurity'
        'CanDeleteFiles'
        'UsesTrustedInstaller'
        'UsesSafeMode'
        'SupportsDefault'
        'SupportsRestore'
        'NeedsExplicitConfirmation'
    )) {
        if ([bool]$capabilities[$field]) {
            throw "$toolId has unsafe capability enabled: $field"
        }
    }

    $source = Get-Content -Raw -LiteralPath $modulePath
    if (-not $source.Contains([string]$definition.Launcher)) {
        throw "$toolId module does not preserve its exact launcher."
    }
    if (-not $source.Contains('$script:BoostLabImplementedActions = @(''Open'')')) {
        throw "$toolId is not marked as Open-only implemented."
    }
    if ($source.Contains('ToolModule.Placeholder.ps1')) {
        throw "$toolId still uses the placeholder implementation."
    }

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $modulePath,
        [ref]$tokens,
        [ref]$parseErrors
    )
    if (@($parseErrors).Count -gt 0) {
        throw "$toolId module has a syntax error: $($parseErrors[0].Message)"
    }
    $commands = @(
        $ast.FindAll(
            { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
            $true
        ) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }
    )
    if (@($commands | Where-Object { $_ -eq 'Start-Process' }).Count -ne 1) {
        throw "$toolId must contain exactly one Start-Process call."
    }
    foreach ($command in $commands) {
        if ($command -in $prohibitedCommands) {
            throw "$toolId contains prohibited command: $command"
        }
    }

    $record = Get-Content -Raw -LiteralPath $recordPath
    foreach ($requiredText in @($definition.Source.Replace('\', '/'), $definition.Hash, $definition.Launcher, 'Approved by Yazan')) {
        if (-not $record.Contains([string]$requiredText)) {
            throw "$toolId migration record is missing: $requiredText"
        }
    }

    $runtimeRelativePath = [string]$definition.Module
    $runtimeRelativePath = $runtimeRelativePath.Substring('modules\'.Length)
    if (
        -not $runtimeSource.Contains("'$toolId' = @{") -or
        -not $runtimeSource.Contains("'$runtimeRelativePath'") -or
        -not $runtimeSource.Contains("Actions = @('Open')")
    ) {
        throw "$toolId is not present in the approved runtime Open-only mapping."
    }
}

$allModules = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'modules') -Recurse -File -Filter '*.psm1' |
        Where-Object { $_.Directory.Parent.FullName -eq (Join-Path $ProjectRoot 'modules') }
)
$implementedModules = @(
    $allModules | Where-Object {
        (Get-Content -Raw -LiteralPath $_.FullName).Contains('$script:BoostLabImplementedActions')
    }
)
$placeholderModules = @(
    $allModules | Where-Object {
        (Get-Content -Raw -LiteralPath $_.FullName).Contains('ToolModule.Placeholder.ps1')
    }
)
if ($implementedModules.Count -ne 24 -or $placeholderModules.Count -ne 24) {
    throw "Unexpected module counts: $($implementedModules.Count) implemented, $($placeholderModules.Count) placeholders."
}

[pscustomobject]@{
    Success                  = $true
    Phase10ImplementedCount  = $definitions.Count
    TotalImplementedCount    = $implementedModules.Count
    PlaceholderModuleCount   = $placeholderModules.Count
    OpenActionsExecuted      = $false
    Message                  = 'Phase 10 Open-only modules preserve their exact launchers and were validated statically.'
    Timestamp                = Get-Date
}
