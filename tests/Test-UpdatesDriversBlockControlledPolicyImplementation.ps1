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
        throw 'Unable to determine the Updates Drivers Block legacy policy validator path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

function Assert-BoostLabCondition {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Refresh\updates-drivers-block.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\2 Refresh\3 Updates Drivers Block.ps1'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$sourcePromotedRoot = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate'

foreach ($path in @($configPath, $modulePath, $sourcePath, $artifactPath, $productionAllowlistPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required file missing: $path"
}

$expectedSourceHash = '4D4EC652C5A7F78824F53B7DC7FD46DDA948F3716A7CD6FD102D6C678EE11991'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Updates Drivers Block source hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."

$config = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })
$tool = @($allTools | Where-Object { $_.Id -eq 'updates-drivers-block' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $tool) 'Updates Drivers Block must exist as an active Refresh tool.'
Assert-BoostLabCondition ([int]$tool.Order -eq 3) 'Updates Drivers Block must remain Refresh order 3.'
Assert-BoostLabCondition ((@($tool.Actions) -join ',') -eq 'Analyze,Apply,Default,Restore') 'Updates Drivers Block must expose canonical actions only.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.CanModifyRegistry) 'Updates Drivers Block must not expose host registry mutation as final behavior.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.SupportsDefault) 'Updates Drivers Block must not support Default/Unblock.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.SupportsRestore) 'Updates Drivers Block Restore must be selected captured USB file state only.'

$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($requiredText in @(
    'Driver Updates Block (Bootable USB) only',
    'sources\$OEM$\$$\Setup\Scripts\setupcomplete.cmd',
    'New-BoostLabFileStateCapture',
    'Invoke-BoostLabFileRollback',
    'DefaultUnavailable',
    'RestoreRequiresCapturedUsbFileState',
    'HostRegistryWrites = $false',
    'SetupCompleteExecuted = $false'
)) {
    Assert-BoostLabCondition ($moduleText.Contains($requiredText)) "Updates Drivers Block module missing required USB-only text: $requiredText"
}

foreach ($forbiddenText in @(
    'New-BoostLabRegistryStateCapture',
    'Invoke-BoostLabRegistryRollback',
    'New-ItemProperty',
    'Remove-ItemProperty',
    'Default removes only the source-defined Driver Updates policy values',
    'write only the nine source-defined live Driver Updates policy values'
)) {
    Assert-BoostLabCondition (-not $moduleText.Contains($forbiddenText)) "Superseded live registry behavior must not remain in module: $forbiddenText"
}

$moduleAst = [Management.Automation.Language.Parser]::ParseFile($modulePath, [ref]$null, [ref]$null)
$commandNames = @(
    $moduleAst.FindAll({ param($node) $node -is [Management.Automation.Language.CommandAst] }, $true) |
        ForEach-Object { $_.GetCommandName() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Sort-Object -Unique
)
foreach ($forbiddenCommand in @(
    'Start-Process',
    'Invoke-WebRequest',
    'Invoke-RestMethod',
    'Start-BitsTransfer',
    'Restart-Computer',
    'Stop-Service',
    'Set-Service',
    'pnputil',
    'dism',
    'wusa',
    'UsoClient',
    'wuauclt'
)) {
    Assert-BoostLabCondition ($forbiddenCommand -notin $commandNames) "Module contains forbidden runtime command: $forbiddenCommand"
}

$artifactText = Get-Content -LiteralPath $artifactPath -Raw
$allowlistText = Get-Content -LiteralPath $productionAllowlistPath -Raw
Assert-BoostLabCondition (-not $artifactText.Contains('updates-drivers-block')) 'Updates Drivers Block must not add artifact provenance entries.'
Assert-BoostLabCondition (-not $allowlistText.Contains('updates-drivers-block')) 'Updates Drivers Block must not add production allowlist entries.'

$placeholderModules = @(
    Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
Assert-BoostLabCondition ($allTools.Count -eq $inventoryBaseline.ActiveTools) "Expected $($inventoryBaseline.ActiveTools) active tools, found $($allTools.Count)."
Assert-BoostLabCondition ($placeholderModules.Count -eq $inventoryBaseline.DeferredPlaceholders) "Expected $($inventoryBaseline.DeferredPlaceholders) deferred/placeholders, found $($placeholderModules.Count)."
Assert-BoostLabCondition (($allTools.Count - $placeholderModules.Count) -eq $inventoryBaseline.ImplementedTools) "Expected $($inventoryBaseline.ImplementedTools) implemented tools, found $($allTools.Count - $placeholderModules.Count)."
$sourcePromotedFiles = @(Get-ChildItem -LiteralPath $sourcePromotedRoot -Recurse -File)
Assert-BoostLabCondition ($sourcePromotedFiles.Count -eq $inventoryBaseline.SourcePromotedMirrorFiles) "Expected $($inventoryBaseline.SourcePromotedMirrorFiles) source-promoted mirror files, found $($sourcePromotedFiles.Count)."

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceManifestLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
    Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
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
Assert-BoostLabCondition (@($sourceManifestLines).Count -eq 49) 'source-ultimate file count changed.'
Assert-BoostLabCondition ($manifestHash -eq '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') 'source-ultimate content or paths changed.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }).Count -eq 0) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    Success = $true
    ToolId = 'updates-drivers-block'
    SourceHash = $actualSourceHash
    ActiveToolCount = $allTools.Count
    ImplementedToolCount = $allTools.Count - $placeholderModules.Count
    PlaceholderToolCount = $placeholderModules.Count
    SourceUltimateUnchanged = $true
    DeletedToolsRemainDeleted = $true
    Message = 'Superseded live registry Updates Drivers Block behavior is not exposed as final behavior; USB-only validator covers active behavior.'
    Timestamp = Get-Date
}
