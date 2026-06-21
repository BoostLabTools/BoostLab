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
        throw 'Unable to determine the Loudness EQ removal test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$removedModulePath = Join-Path $ProjectRoot 'modules\Windows\loudness-eq.psm1'
$removedSourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$stages = @($configuration['Stages'] | Sort-Object { [int]$_['Order'] })
$tools = @($stages | ForEach-Object { $_['Tools'] })

if ($tools.Count -ne $inventoryBaseline.ActiveTools) {
    throw "Expected $($inventoryBaseline.ActiveTools) active tools after Phase 96, found $($tools.Count)."
}

$loudnessTools = @(
    $tools | Where-Object {
        [string]$_['Id'] -eq 'loudness-eq' -or
        [string]$_['Title'] -eq 'Loudness EQ'
    }
)
if ($loudnessTools.Count -ne 0) {
    throw 'Loudness EQ remains present in config/Stages.psd1.'
}

if (Test-Path -LiteralPath $removedModulePath) {
    throw 'The Loudness EQ module still exists.'
}
if (Test-Path -LiteralPath $removedSourcePath) {
    throw 'The authorized Loudness EQ legacy source deletion did not occur.'
}

$moduleFiles = @(
    Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1' |
        Where-Object { $_.Directory.Parent.FullName -eq $modulesRoot }
)
$implementedModules = @(
    $moduleFiles | Where-Object {
        (Get-Content -Raw -LiteralPath $_.FullName).Contains('$script:BoostLabImplementedActions')
    }
)
$placeholderModules = @(
    $moduleFiles | Where-Object {
        (Get-Content -Raw -LiteralPath $_.FullName).Contains('ToolModule.Placeholder.ps1')
    }
)
if (
    $moduleFiles.Count -ne 55 -or
    $implementedModules.Count -ne $inventoryBaseline.ImplementedTools -or
    $placeholderModules.Count -ne $inventoryBaseline.DeferredPlaceholders
) {
    throw "Unexpected Phase 95 inventory: $($moduleFiles.Count) modules, $($implementedModules.Count) implemented, $($placeholderModules.Count) placeholders."
}

$expectedPlaceholderPaths = @(
    'modules\Windows\game-bar.psm1'
    'modules\Windows\control-panel-settings.psm1'
)
foreach ($relativePath in $expectedPlaceholderPaths) {
    $path = Join-Path $ProjectRoot $relativePath
    if (
        -not (Test-Path -LiteralPath $path -PathType Leaf) -or
        -not (Get-Content -Raw -LiteralPath $path).Contains('ToolModule.Placeholder.ps1')
    ) {
        throw "Protected placeholder changed: $relativePath"
    }
}

$protectedHashes = [ordered]@{
    'modules\Windows\NetworkAdapterPowerSavingsWake.psm1' = '4A0A213032E31B3D4F5A676F0706B8FB354CC0EA3EA6498D6FB51A81B24B3C77'
    'modules\Windows\SignoutLockScreenWallpaperBlack.psm1' = '216CE7CA8E3EDCD29B126BD6EB167CE8B43EEB2B5E15C984D9E066CA254B24B2'
    'modules\Windows\ContextMenu.psm1' = '1F875028B1C730323E44F59CE80C9A7F8B5DE1407BB2425BD58C5924BACCA3C2'
    'modules\Windows\StartMenuLayout.psm1' = 'D93019267A3D566146F713DF69C86F41CDAD93A2B0786D5CB8DDF9F2878E103A'
    'modules\Windows\ThemeBlack.psm1' = '29F3474D93061B01E3CF9F23EADA88E932E90E4984EBB39F7DB2BEB24732230F'
    'modules\Windows\game-bar.psm1' = 'E301B2AA588537B81CAB577DA51342FAFFFB7B452C2C36054BD269C51F10CC24'
    'modules\Windows\copilot.psm1' = 'FB1277012C4A537E1C3F335AAB862DC00A4A5F665EF42A8FC81BDFE1CDDAE162'
    'modules\Windows\game-mode.psm1' = 'CADEC6B0E4262990BF9D9BBDBD8DBA55EE910EEFC1FF72B78912800AD04624E9'
    'modules\Windows\sound.psm1' = 'B20CBF149CDAA562011AABD05D5828100D0B3810A565A4B7E305EBD50C91FDE3'
    'modules\Windows\control-panel-settings.psm1' = '6B02392A74AEF177C3249F0A686E48D418693A683F36A7F4C3E9C7BF764941BE'
    'modules\Setup\edge-settings.psm1' = '00F32DC6FDB0FCB796EF4083ADDF20478ED5C003122606FEFC85746231A6EF0A'
    'modules\Windows\PowerPlan.psm1' = '785A352F3453C71F33A8F4BFE0A381D02CB3A70C7307C77EDADACE98F7FFCF25'
}
foreach ($relativePath in $protectedHashes.Keys) {
    $path = Join-Path $ProjectRoot $relativePath
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash -ne $protectedHashes[$relativePath]) {
        throw "Protected file changed during Phase 25: $relativePath"
    }
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
        ForEach-Object {
            '{0}|{1}' -f `
                $_.FullName.Substring($root.Length + 1).Replace('\', '/'), `
                (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
        }
)
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
    $sourceLines.Count -ne 49 -or
    $sourceManifestHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477'
) {
    throw 'source-ultimate changed outside the one authorized Loudness EQ deletion.'
}

$instructionText = Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot 'CODEX_INSTRUCTIONS.md')
$blueprintText = Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot 'BOOSTLAB_BLUEPRINT.md')
$triageText = Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot 'docs\remaining-tool-migration-triage.md')
$requiredRemovalText = @(
    'Loudness EQ'
    'permanently removed'
    '2F11A145B3E035372AB023614662524159BDDFA122A3778D6FEE9824782416AE'
)
foreach ($requiredText in $requiredRemovalText) {
    if (
        -not $instructionText.Contains($requiredText) -or
        -not $blueprintText.Contains($requiredText) -or
        -not $triageText.Contains($requiredText)
    ) {
        throw "Phase 25 deletion governance is missing: $requiredText"
    }
}

[pscustomobject]@{
    Success                  = $true
    ActiveToolCount          = $tools.Count
    ImplementedModuleCount   = $implementedModules.Count
    PlaceholderModuleCount   = $placeholderModules.Count
    SourceFileCount          = $sourceLines.Count
    SourceManifestSHA256     = $sourceManifestHash
    RemovedSourceSHA256      = '2F11A145B3E035372AB023614662524159BDDFA122A3778D6FEE9824782416AE'
    ProtectedFileCount       = $protectedHashes.Count
}



