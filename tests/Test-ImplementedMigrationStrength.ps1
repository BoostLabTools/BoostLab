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
        throw 'Unable to determine the migration strength test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$implementedTools = [ordered]@{
    'BIOS Information' = @{
        LegacyPath = 'source-ultimate\1 Check\1 BIOS Information.ps1'
        ModulePath = 'modules\Check\BIOSInformation.psm1'
        LegacyHash = 'A4C4CD8835C05C0FC880142420F41FE9633CB44E9FD102B9368D30EFD6B12B42'
    }
    'BIOS Settings' = @{
        LegacyPath = 'source-ultimate\1 Check\2 BIOS Settings.ps1'
        ModulePath = 'modules\Check\BIOSSettings.psm1'
        LegacyHash = 'C68BDADC7EEAC77A0FE8ECE999CEB5A28C51D819D69107AFD471739BA36E2737'
    }
    'Startup Apps (Settings)' = @{
        LegacyPath = 'source-ultimate\3 Setup\3 Startup Apps (Settings).ps1'
        ModulePath = 'modules\Setup\StartupAppsSettings.psm1'
        LegacyHash = '15895826F14392D72F54BDDEB3D21F3E482289E0A6CAC057366C0E6E34D45DF7'
        Launcher   = 'Start-Process "ms-settings:startupapps"'
    }
    'Startup Apps (Task Manager)' = @{
        LegacyPath = 'source-ultimate\3 Setup\4 Startup Apps (Task Manager).ps1'
        ModulePath = 'modules\Setup\StartupAppsTaskManager.psm1'
        LegacyHash = 'EB648780E90F95A7A65CD25EDF21CCDFC1BFEA92705AEF0AC88C97B41989ABF6'
        Launcher   = 'Start-Process "taskmgr" -ArgumentList " /0 /startup"'
    }
    'Graphics Configuration Center' = @{
        LegacyPath = 'source-ultimate\5 Graphics\4 Graphics Configuration Center.ps1'
        ModulePath = 'modules\Graphics\GraphicsConfigurationCenter.psm1'
        LegacyHash = '5D8438C6E6CBB7AA87111518F24689095382F72F76DD72E64CBBF3019B9B13CA'
        Launcher   = 'Start-Process "ms-settings:display-advancedgraphics"'
    }
    'Date Language Region Time' = @{
        LegacyPath = 'source-ultimate\3 Setup\2 Date Language Region Time.ps1'
        ModulePath = 'modules\Setup\date-language-region-time.psm1'
        LegacyHash = '77F4B88F2FBB43F7EACA5F3AD850268210685F41E659DF02EB09279422EA0EE9'
        Launcher   = 'Start-Process "ms-settings:dateandtime"'
    }
    'GameMode' = @{
        LegacyPath = 'source-ultimate\6 Windows\9 Gamemode.ps1'
        ModulePath = 'modules\Windows\game-mode.psm1'
        LegacyHash = 'F83275C0B3CE135679C2F1D98A1F0BD6B101936E0B2BC17B542DE288EF6A0B82'
        Launcher   = 'Start-Process "ms-settings:gaming-gamemode"'
    }
    'Pointer Precision' = @{
        LegacyPath = 'source-ultimate\6 Windows\10 Pointer Precision.ps1'
        ModulePath = 'modules\Windows\pointer-precision.psm1'
        LegacyHash = 'ED66BB1C068DF13FC2D58617E49C2274CEA9609C689FE34F9A0B138AC22F618C'
        Launcher   = 'Start-Process "control.exe" -ArgumentList "main.cpl ,2"'
    }
    'Sound' = @{
        LegacyPath = 'source-ultimate\6 Windows\16 Sound.ps1'
        ModulePath = 'modules\Windows\sound.psm1'
        LegacyHash = '08FDB346A40595C68FF01D8F0882AC82D8BE27F66D83B400FD5691388B35929B'
        Launcher   = 'Start-Process "mmsys.cpl"'
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

$auditResults = [System.Collections.Generic.List[object]]::new()

foreach ($toolName in $implementedTools.Keys) {
    $definition = $implementedTools[$toolName]
    $legacyPath = Join-Path $ProjectRoot $definition.LegacyPath
    $modulePath = Join-Path $ProjectRoot $definition.ModulePath

    if (-not (Test-Path -LiteralPath $legacyPath -PathType Leaf)) {
        throw "$toolName legacy source is missing: $legacyPath"
    }
    if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
        throw "$toolName module is missing: $modulePath"
    }

    $legacyHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $legacyPath).Hash
    if ($legacyHash -ne $definition.LegacyHash) {
        throw "$toolName legacy source hash changed."
    }

    $legacySource = Get-Content -Raw -LiteralPath $legacyPath
    $moduleSource = Get-Content -Raw -LiteralPath $modulePath

    if ($definition.ContainsKey('Launcher')) {
        if (-not $legacySource.Contains([string]$definition.Launcher)) {
            throw "$toolName legacy launcher no longer matches the approved command."
        }
        if (-not $moduleSource.Contains([string]$definition.Launcher)) {
            throw "$toolName module weakened or changed the approved launcher."
        }
    }

    switch ($toolName) {
        'BIOS Information' {
            foreach ($requiredText in @(
                'Get-CimInstance'
                '[System.Uri]::EscapeDataString'
                'https://www.google.com/search?q='
                'Start-Process $searchUrl'
                '''BIOS update'''
            )) {
                if (-not $moduleSource.Contains($requiredText)) {
                    throw "BIOS Information redesigned assistant behavior is missing: $requiredText"
                }
            }
        }
        'BIOS Settings' {
            foreach ($requiredText in @(
                'INTEL CPU'
                'ENABLE ram profile (XMP DOCP EXPO)'
                'AMD CPU'
                'ENABLE precision boost overdrive (PBO)'
                'MAX pump and set fans to performance'
                '[bool]$Confirmed = $false'
                '/r /fw /t 0'
                '& $commandProcessorPath @firmwareRestartArguments'
            )) {
                if (-not $moduleSource.Contains($requiredText)) {
                    throw "BIOS Settings preserved behavior is missing: $requiredText"
                }
            }
            foreach ($forbiddenText in @(
                'https://www.google.com/search?q='
                'Start-Process $searchUrl'
            )) {
                if ($moduleSource.Contains($forbiddenText)) {
                    throw "BIOS Settings incorrectly contains search behavior: $forbiddenText"
                }
            }
        }
    }

    $auditResults.Add([pscustomobject]@{
        Tool         = $toolName
        LegacySource = $definition.LegacyPath
        Module       = $definition.ModulePath
        Result       = 'Preserved'
    })
}

$bootstrapPath = Join-Path $ProjectRoot 'bootstrap.ps1'
$bootstrapSource = Get-Content -Raw -LiteralPath $bootstrapPath
foreach ($requiredText in @(
    'Test-BoostLabAdministrator'
    'Start-Process -FilePath $windowsPowerShell -ArgumentList $arguments -Verb RunAs'
    '-AdminStatus ''True'''
)) {
    if (-not $bootstrapSource.Contains($requiredText)) {
        throw "Application-level administrator enforcement is missing: $requiredText"
    }
}

$modulesRoot = Join-Path $ProjectRoot 'modules'
$normalizedDeletedNames = @(
    $deletedToolNames | ForEach-Object {
        ($_ -replace '[^a-zA-Z0-9]+', '-').Trim('-').ToLowerInvariant()
    }
)
$deletedModules = @(
    Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1' |
        Where-Object {
            [System.IO.Path]::GetFileNameWithoutExtension($_.Name).ToLowerInvariant() -in $normalizedDeletedNames
        }
)
if ($deletedModules.Count -gt 0) {
    throw "Deleted tool modules were found: $($deletedModules.FullName -join ', ')"
}

[pscustomobject]@{
    Success                  = $true
    ImplementedToolCount     = $auditResults.Count
    PreservedToolCount       = @($auditResults | Where-Object { $_.Result -eq 'Preserved' }).Count
    AdministratorEnforced    = $true
    DeletedModuleCount       = $deletedModules.Count
    SourceUltimateHashesValid = $true
    Results                  = $auditResults.ToArray()
    Message                  = 'All currently implemented tools preserve their approved Ultimate behavior or documented redesign.'
    Timestamp                = Get-Date
}
