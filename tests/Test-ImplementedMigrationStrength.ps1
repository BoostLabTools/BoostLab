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
    'To BIOS' = @{
        LegacyPath = 'source-ultimate\2 Refresh\4 To Bios.ps1'
        ModulePath = 'modules\Refresh\to-bios.psm1'
        LegacyHash = 'A8371B42B235A6AC1F9661D96B430BEC0E4CAB6D9DE3CBD1461A02572220CA0C'
    }
    'Unattended' = @{
        LegacyPath = 'source-ultimate\2 Refresh\2 Unattended.ps1'
        ModulePath = 'modules\Refresh\unattended.psm1'
        LegacyHash = '0974CFCC4FFC4B21BF4EB62172C0C1C31FF32AB147878A4610FC19C95DF74338'
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
    'Memory Compression' = @{
        LegacyPath = 'source-ultimate\3 Setup\1 Memory Compression.ps1'
        ModulePath = 'modules\Setup\MemoryCompression.psm1'
        LegacyHash = 'CCBABB01D249C1206F4762579665DCE6F95F12A8D221D9A65A6310A0393C2352'
    }
    'Background Apps' = @{
        LegacyPath = 'source-ultimate\3 Setup\5 Background Apps.ps1'
        ModulePath = 'modules\Setup\BackgroundApps.psm1'
        LegacyHash = '2DF15DE03306CCAF19180940F215972E943EA94E7B2C52B7D6EC2B6403E79445'
    }
    'Store Settings' = @{
        LegacyPath = 'source-ultimate\3 Setup\7 Store Settings.ps1'
        ModulePath = 'modules\Setup\StoreSettings.psm1'
        LegacyHash = 'D6B2AF6B399E2E9A34198578472FCCAFB924E2E8B15D1A38B85091BE3DDF3167'
    }
    'Updates Pause' = @{
        LegacyPath = 'source-ultimate\3 Setup\8 Updates Pause.ps1'
        ModulePath = 'modules\Setup\UpdatesPause.psm1'
        LegacyHash = '4BBEF16C51FBEBAFAECB58307F8C619A37CD10BB3DC489BD4DF9A59DDBD1A0BD'
        Launcher   = 'Start-Process ms-settings:windowsupdate'
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
    'Widgets' = @{
        LegacyPath = 'source-ultimate\6 Windows\7 Widgets.ps1'
        ModulePath = 'modules\Windows\Widgets.psm1'
        LegacyHash = '7A530557AA503EE038BDF910007D6A496DABFE61FA0D8818C189774E33892A73'
    }
    'Theme Black' = @{
        LegacyPath = 'source-ultimate\6 Windows\4 Theme Black.ps1'
        ModulePath = 'modules\Windows\ThemeBlack.psm1'
        LegacyHash = 'C7FAEA241747065A9B752D989C5D0EA740E1525F442ABDDFFF3320766A005B2F'
    }
    'Start Menu Layout' = @{
        LegacyPath = 'source-ultimate\6 Windows\2 Start Menu Layout.ps1'
        ModulePath = 'modules\Windows\StartMenuLayout.psm1'
        LegacyHash = '81C1298D7C9E112DB910C4398CD94E4B70ECD97ED3B185CF2FD2B8A380E069E8'
    }
    'Context Menu' = @{
        LegacyPath = 'source-ultimate\6 Windows\3 Context Menu.ps1'
        ModulePath = 'modules\Windows\ContextMenu.psm1'
        LegacyHash = '33DA36782CF6416A2FAE98829ADF0913B0E54DC53DE454AB0C5210A79754B6F2'
    }
    'Signout LockScreen Wallpaper Black' = @{
        LegacyPath = 'source-ultimate\6 Windows\5 Signout Lockscreen Wallpaper Black.ps1'
        ModulePath = 'modules\Windows\SignoutLockScreenWallpaperBlack.psm1'
        LegacyHash = 'C5A3E791BB85EE166397748D95B0BD4725063B55DC50CAEA805DC212E485C64C'
    }
    'User Account Pictures Black' = @{
        LegacyPath = 'source-ultimate\6 Windows\6 User Account Pictures Black.ps1'
        ModulePath = 'modules\Windows\user-account-pictures-black.psm1'
        LegacyHash = '8B978374BC9D5AE51858FC71BE02D0DFFAE29AADFEFAF8662D8654D735443710'
    }
    'Device Manager Power Savings & Wake' = @{
        LegacyPath = 'source-ultimate\6 Windows\18 Device Manager Power Savings & Wake.ps1'
        ModulePath = 'modules\Windows\device-manager-power-savings-wake.psm1'
        LegacyHash = 'FB543A5C6BD8F2FBEA5CD3069FD72DCDCCAB847D9E4753FD33BB0909843D209F'
    }
    'Network Adapter Power Savings & Wake' = @{
        LegacyPath = 'source-ultimate\6 Windows\19 Network Adapter Power Savings & Wake.ps1'
        ModulePath = 'modules\Windows\NetworkAdapterPowerSavingsWake.psm1'
        LegacyHash = '1DAAC872ECB1C601FD165FD471BFA9B9137D895333FBFBC5ADE5427561D4BCEB'
    }
    'Write Cache Buffer Flushing' = @{
        LegacyPath = 'source-ultimate\6 Windows\20 Write Cache Buffer Flushing.ps1'
        ModulePath = 'modules\Windows\write-cache-buffer-flushing.psm1'
        LegacyHash = '67D8CA0FECBFD9FCE7D2C81CE1713F1B08E83B729DC8FEC7B8C2E33806F9AD5D'
    }
    'Power Plan' = @{
        LegacyPath = 'source-ultimate\6 Windows\21 Power Plan.ps1'
        ModulePath = 'modules\Windows\PowerPlan.psm1'
        LegacyHash = '97CD584B1713809466E372B70434F06FFABC10DE0C4C4F67AF4212B5892DAC56'
    }
    'Notepad Settings' = @{
        LegacyPath = 'source-ultimate\6 Windows\14 Notepad Settings.ps1'
        ModulePath = 'modules\Windows\notepad-settings.psm1'
        LegacyHash = '2086D75FAA560C9746B1FA2EDB29AE9A8364633FD6268DEEDBE7FB4720EA39FB'
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
    'Loudness EQ'
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
                'Get-BoostLabBiosInformationSearchQuery'
                'MotherboardModelUnavailable'
            )) {
                if (-not $moduleSource.Contains($requiredText)) {
                    throw "BIOS Information redesigned assistant behavior is missing: $requiredText"
                }
            }
            foreach ($forbiddenText in @(
                '$analysis.MotherboardManufacturer'
                '$analysis.BiosVersion'
                '''BIOS update'''
            )) {
                if ($moduleSource.Contains($forbiddenText)) {
                    throw "BIOS Information Open query includes widened source behavior: $forbiddenText"
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
        'To BIOS' {
            foreach ($requiredLegacyText in @(
                'cmd /c C:\Windows\System32\shutdown.exe /r /fw /t 0'
                'Press Enter to Restart to BIOS'
            )) {
                if (-not $legacySource.Contains($requiredLegacyText)) {
                    throw "To BIOS legacy behavior is missing: $requiredLegacyText"
                }
            }
            foreach ($requiredModuleText in @(
                '[bool]$Confirmed = $false'
                '$commandProcessorPath = Join-Path $env:SystemRoot ''System32\cmd.exe'''
                '$shutdownPath = Join-Path $env:SystemRoot ''System32\shutdown.exe'''
                '$firmwareRestartCommand = "`"$shutdownPath`" /r /fw /t 0"'
                '& $commandProcessorPath @firmwareRestartArguments'
            )) {
                if (-not $moduleSource.Contains($requiredModuleText)) {
                    throw "To BIOS module behavior is missing: $requiredModuleText"
                }
            }
        }
        'Widgets' {
            foreach ($requiredText in @(
                'reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" /v "value" /t REG_DWORD /d "0" /f'
                'reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d "0" /f'
                'reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" /v "value" /t REG_DWORD /d "1" /f'
                'reg delete "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /f'
                '$script:BoostLabWidgetProcessNames = @(''Widgets'', ''WidgetService'')'
                'Stop-Process -Force -Name $processName -ErrorAction Stop'
            )) {
                if (-not $moduleSource.Contains($requiredText)) {
                    throw "Widgets preserved behavior is missing: $requiredText"
                }
            }
            foreach ($forbiddenText in @(
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
            )) {
                if ($moduleSource.Contains($forbiddenText)) {
                    throw "Widgets contains unrelated behavior: $forbiddenText"
                }
            }
        }
        'Memory Compression' {
            foreach ($requiredText in @(
                'Disable-MMAgent -MemoryCompression -ErrorAction Stop'
                'Enable-MMAgent -MemoryCompression -ErrorAction Stop'
                'Get-MMAgent -ErrorAction Stop'
                '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
            )) {
                if (-not $moduleSource.Contains($requiredText)) {
                    throw "Memory Compression preserved behavior is missing: $requiredText"
                }
            }
            foreach ($forbiddenText in @(
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Set-MMAgent'
                '-PageCombining'
                '-ApplicationPreLaunch'
            )) {
                if ($moduleSource.Contains($forbiddenText)) {
                    throw "Memory Compression contains unrelated behavior: $forbiddenText"
                }
            }
        }
        'Background Apps' {
            foreach ($requiredText in @(
                'reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /t REG_DWORD /d "2" /f'
                'reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /f'
                'Start-Process ms-settings:privacy-backgroundapps -ErrorAction Stop'
                '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
            )) {
                if (-not $moduleSource.Contains($requiredText)) {
                    throw "Background Apps preserved behavior is missing: $requiredText"
                }
            }
            foreach ($forbiddenText in @(
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Stop-Process'
                'UsesTrustedInstaller = $true'
            )) {
                if ($moduleSource.Contains($forbiddenText)) {
                    throw "Background Apps contains unrelated behavior: $forbiddenText"
                }
            }
        }
        'Store Settings' {
            foreach ($requiredText in @(
                'reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" /v "AutoDownload" /t REG_DWORD /d "2" /f'
                'reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore" /f'
                'Start-Process "ms-windows-store:settings" -ErrorAction Stop'
                'Start-Process "wsreset.exe" -WindowStyle Hidden -ErrorAction Stop'
                '$script:BoostLabStoreProcessNames = @(''WinStore.App'', ''backgroundTaskHost'', ''StoreDesktopExtension'')'
                '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
            )) {
                if (-not $moduleSource.Contains($requiredText)) {
                    throw "Store Settings preserved behavior is missing: $requiredText"
                }
            }
            foreach ($forbiddenText in @(
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'UsesTrustedInstaller = $true'
            )) {
                if ($moduleSource.Contains($forbiddenText)) {
                    throw "Store Settings contains unrelated behavior: $forbiddenText"
                }
            }
        }
        'Notepad Settings' {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
                '$script:BoostLabNotepadProcessName = ''Notepad'''
                'Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings\settings.dat'
                '"OpenFile"=hex(5f5e104):01,00,00,00,d1,55,24,57,d1,84,db,01'
                '"GhostFile"=hex(5f5e10b):00,42,60,f1,5a,d1,84,db,01'
                '"RewriteEnabled"=hex(5f5e10b):00,12,4a,7f,5f,d1,84,db,01'
                'Stop-Process -Name $script:BoostLabNotepadProcessName -Force -ErrorAction SilentlyContinue'
                'if ($null -ne $loadResult -and [bool]$loadResult.Success)'
                'Remove-Item -LiteralPath $Path -Force -ErrorAction Stop'
                'Invoke-BoostLabNotepadRegistryCommand'
            )) {
                if (-not $moduleSource.Contains($requiredText)) {
                    throw "Notepad Settings preserved behavior is missing: $requiredText"
                }
            }
            foreach ($forbiddenText in @(
                'Remove-AppxPackage'
                'Get-AppxPackage'
                'Invoke-WebRequest'
                'Set-Service'
                'Restart-Computer'
                'UsesTrustedInstaller = $true'
                'New-BoostLabNotepadNotApplicableResult'
                'safeboot'
            )) {
                if ($moduleSource.Contains($forbiddenText)) {
                    throw "Notepad Settings contains unrelated behavior: $forbiddenText"
                }
            }
        }
        'Updates Pause' {
            foreach ($requiredText in @(
                '$script:BoostLabUpdatesPauseRegistryPath = ''HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'''
                'PauseUpdatesExpiryTime'
                'PauseFeatureUpdatesEndTime'
                'PauseFeatureUpdatesStartTime'
                'PauseQualityUpdatesEndTime'
                'PauseQualityUpdatesStartTime'
                'PauseUpdatesStartTime'
                '.AddDays(365).ToUniversalTime().ToString(''yyyy-MM-ddTHH:mm:ssZ'')'
                'Set-ItemProperty'
                'Remove-ItemProperty'
                'Start-Process ms-settings:windowsupdate -ErrorAction Stop'
                '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
            )) {
                if (-not $moduleSource.Contains($requiredText)) {
                    throw "Updates Pause preserved behavior is missing: $requiredText"
                }
            }
            foreach ($forbiddenText in @(
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Restart-Service'
                'Stop-Process'
                'UsesTrustedInstaller = $true'
                'safeboot'
            )) {
                if ($moduleSource.Contains($forbiddenText)) {
                    throw "Updates Pause contains unrelated behavior: $forbiddenText"
                }
            }
        }
        'Theme Black' {
            foreach ($requiredText in @(
                'blacktheme.reg'
                'defaulttheme.reg'
                '"AppsUseLightTheme"=dword:00000000'
                '"AppsUseLightTheme"=dword:00000001'
                '[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize]'
                '"AccentColor"=dword:ff191919'
                '"AccentColor"=dword:ffd47800'
                'Set-Content -Path $Path -Value $Content -Force -ErrorAction Stop'
                '"regedit.exe"'
                '-ArgumentList "/S `"$Path`""'
                '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
            )) {
                if (-not $moduleSource.Contains($requiredText)) {
                    throw "Theme Black preserved behavior is missing: $requiredText"
                }
            }
            foreach ($forbiddenText in @(
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Restart-Service'
                'Stop-Process'
                'Remove-AppxPackage'
                'UsesTrustedInstaller = $true'
                'safeboot'
            )) {
                if ($moduleSource.Contains($forbiddenText)) {
                    throw "Theme Black contains unrelated behavior: $forbiddenText"
                }
            }
        }
        'Start Menu Layout' {
            foreach ($requiredText in @(
                'newstartmenu.reg'
                'oldstartmenu.reg'
                '"EnabledState"=dword:00000002'
                '"EnabledState"=-'
                '"AllAppsViewMode"=dword:00000002'
                '"AllAppsViewMode"=dword:00000000'
                'Set-Content -Path $Path -Value $Content -Force -ErrorAction Stop'
                '"regedit.exe"'
                '-ArgumentList "/S `"$Path`""'
                '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
            )) {
                if (-not $moduleSource.Contains($requiredText)) {
                    throw "Start Menu Layout preserved behavior is missing: $requiredText"
                }
            }
            foreach ($forbiddenText in @(
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Restart-Service'
                'Stop-Process'
                'Remove-AppxPackage'
                'Remove-Item'
                'UsesTrustedInstaller = $true'
                'safeboot'
            )) {
                if ($moduleSource.Contains($forbiddenText)) {
                    throw "Start Menu Layout contains unrelated behavior: $forbiddenText"
                }
            }
        }
        'Context Menu' {
            foreach ($requiredText in @(
                '$script:BoostLabOwnedBlockedGuids'
                '{9F156763-7844-4DC4-B2B1-901F640F5155}'
                '{09A47860-11B0-4DA5-AFA5-26D86198A780}'
                '{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}'
                'contextmenudefault.reg'
                'PinAndFavoritesDefaults'
                'NoCustomizeThisFolder'
                'NoPreviousVersionsPage'
                'ScanWithDefender'
                '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
            )) {
                if (-not $moduleSource.Contains($requiredText)) {
                    throw "Context Menu preserved behavior is missing: $requiredText"
                }
            }
            if (
                $moduleSource -match
                    'reg delete\s+["'']?HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Shell Extensions\\Blocked["'']?\s+/f'
            ) {
                throw 'Context Menu module contains the disallowed broad Blocked key deletion.'
            }
            foreach ($forbiddenText in @(
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Restart-Service'
                'Stop-Process'
                'Remove-AppxPackage'
                'UsesTrustedInstaller = $true'
                'safeboot'
            )) {
                if ($moduleSource.Contains($forbiddenText)) {
                    throw "Context Menu contains unrelated behavior: $forbiddenText"
                }
            }
        }
        'Signout LockScreen Wallpaper Black' {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
                'System.Windows.Forms.SystemInformation'
                'System.Drawing.Bitmap'
                'FillRectangle'
                'C:\Windows\Black.jpg'
                'C:\Windows\Web\Wallpaper\Windows\img0.jpg'
                'LockScreenImagePath'
                'LockScreenImageStatus'
                'HKCU\Control Panel\Desktop'
                'UpdatePerUserSystemParameters'
                'reg add'
                'reg delete'
                'DeleteKey'
                'Remove-Item -Recurse -Force $Path'
                'New-BoostLabVerificationResult'
            )) {
                if (-not $moduleSource.Contains($requiredText)) {
                    throw "Signout LockScreen Wallpaper Black preserved behavior is missing: $requiredText"
                }
            }
            if (
                $moduleSource -notmatch
                    'reg delete\s+["'']\{0\}["'']\s+/f'
            ) {
                throw 'Signout LockScreen Wallpaper Black is missing the source-defined complete PersonalizationCSP key deletion.'
            }
            foreach ($forbiddenText in @(
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Restart-Service'
                'Stop-Process'
                'Remove-AppxPackage'
                'UsesTrustedInstaller = $true'
                'safeboot'
                'Backup-BoostLabWallpaperFile'
                'Restore-BoostLabWallpaperBackup'
                'Remove-BoostLabOwnedWallpaperFile'
                'signout-lockscreen-wallpaper-black.json'
            )) {
                if ($moduleSource.Contains($forbiddenText)) {
                    throw "Signout LockScreen Wallpaper Black contains unrelated behavior: $forbiddenText"
                }
            }
        }
        'Network Adapter Power Savings & Wake' {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
                'HKLM:\System\ControlSet001\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}'
                'PnPCapabilities'
                'AdvancedEEE'
                '*EEE'
                'EEELinkAdvertisement'
                'SipsEnabled'
                'ULPMode'
                'GigaLite'
                'EnableGreenEthernet'
                'PowerSavingMode'
                'S5WakeOnLan'
                '*WakeOnMagicPacket'
                '*ModernStandbyWoLMagicPacket'
                '*WakeOnPattern'
                'WakeOnLink'
                'New-BoostLabVerificationResult'
            )) {
                if (-not $moduleSource.Contains($requiredText)) {
                    throw "Network Adapter Power Savings & Wake preserved behavior is missing: $requiredText"
                }
            }
            foreach ($forbiddenText in @(
                'Disable-NetAdapter'
                'Disable-PnpDevice'
                'Uninstall-PnpDevice'
                'pnputil'
                'devcon'
                'netsh winsock reset'
                'netsh int ip reset'
                'Set-NetFirewall'
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Restart-Service'
                'Stop-Process'
                'Remove-AppxPackage'
                'UsesTrustedInstaller = $true'
                'safeboot'
            )) {
                if ($moduleSource.Contains($forbiddenText)) {
                    throw "Network Adapter Power Savings & Wake contains unrelated behavior: $forbiddenText"
                }
            }
        }
        'Write Cache Buffer Flushing' {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
                'HKLM:\SYSTEM\ControlSet001\Enum'
                'SCSI'
                'NVME'
                'Device Parameters'
                'Disk'
                'CacheIsPowerProtected'
                '$script:BoostLabCacheExpectedValue = 1'
                'New-BoostLabRegistryStateCapture'
                'Set-BoostLabRollbackMutationState'
                'SupportsDefault           = $true'
                'SupportsRestore           = $false'
                'function Test-BoostLabWriteCacheState'
                'function Remove-BoostLabWriteCacheRegistryKey'
                'reg delete "{0}" /f'
                'RegistryKeysDeleteAttempted'
            )) {
                if (-not $moduleSource.Contains($requiredText)) {
                    throw "Write Cache Buffer Flushing preserved behavior is missing: $requiredText"
                }
            }
            foreach ($forbiddenText in @(
                'Remove-ItemProperty'
                'Remove-Item -LiteralPath'
                'Disable-PnpDevice'
                'Uninstall-PnpDevice'
                'pnputil'
                'devcon'
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Restart-Service'
                'Stop-Process'
                'Remove-AppxPackage'
                'UsesTrustedInstaller      = $true'
                'UsesSafeMode              = $true'
            )) {
                if ($moduleSource.Contains($forbiddenText)) {
                    throw "Write Cache Buffer Flushing contains unrelated or unsafe behavior: $forbiddenText"
                }
            }
        }
        'User Account Pictures Black' {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
                'Microsoft\User Account Pictures'
                '$script:BoostLabApprovedExtensions = @(''.png'', ''.bmp'')'
                'System.Drawing.Bitmap'
                'System.Drawing.Graphics'
                'System.Drawing.Color]::Black'
                'Copy-BoostLabUltimateAccountPictureBackup'
                'Copy-BoostLabUltimateAccountPictureDefault'
                'Get-ChildItem -Path $TargetRoot -Include *.png,*.bmp -Recurse'
                'New-BoostLabVerificationResult'
            )) {
                if (-not $moduleSource.Contains($requiredText)) {
                    throw "User Account Pictures Black preserved behavior is missing: $requiredText"
                }
            }
            foreach ($forbiddenText in @(
                'Restart-Computer'
                'Stop-Computer'
                'Invoke-WebRequest'
                'Invoke-RestMethod'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Stop-Process'
                'Remove-AppxPackage'
                'UsesTrustedInstaller = $true'
                'safeboot'
                'source-ultimate'
                'user-account-pictures-black.json'
                'LeftIntactUnknownOwnership'
                'Restore-BoostLabAccountPictureBackup'
            )) {
                if ($moduleSource.Contains($forbiddenText)) {
                    throw "User Account Pictures Black contains unrelated behavior: $forbiddenText"
                }
            }
        }
        'Device Manager Power Savings & Wake' {
            foreach ($requiredText in @(
                '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
                '$script:BoostLabDeviceClasses = @(''ACPI'', ''HID'', ''PCI'', ''USB'')'
                'EnhancedPowerManagementEnabled'
                'SeleactiveSuspendEnabled'
                'SelectiveSuspendEnabled'
                'SelectiveSuspendOn'
                'IdleInWorkingState'
                'WaitWakeEnabled'
                'Test-BoostLabDeviceManagerRegistryTarget'
                'New-BoostLabVerificationResult'
            )) {
                if (-not $moduleSource.Contains($requiredText)) {
                    throw "Device Manager Power Savings & Wake preserved behavior is missing: $requiredText"
                }
            }
            foreach ($forbiddenText in @(
                'Disable-PnpDevice'
                'Enable-PnpDevice'
                'Uninstall-PnpDevice'
                'pnputil'
                'devcon'
                'Remove-Item'
                'Remove-AppxPackage'
                'Invoke-WebRequest'
                'Start-BitsTransfer'
                'Set-Service'
                'Stop-Service'
                'Restart-Computer'
                'UsesTrustedInstaller = $true'
                'safeboot'
            )) {
                if ($moduleSource.Contains($forbiddenText)) {
                    throw "Device Manager Power Savings & Wake contains unrelated behavior: $forbiddenText"
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
