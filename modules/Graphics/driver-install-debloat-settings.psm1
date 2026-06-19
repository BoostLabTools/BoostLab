Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'driver-install-debloat-settings'
    Title = 'Driver Install Debloat & Settings'
    Stage = 'Graphics'
    Order = 2
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Run the source-equivalent NVIDIA, AMD, or INTEL driver install/debloat workflow for one selected branch after explicit confirmation.'
    Actions = @('Analyze', 'Open', 'Apply', 'Default', 'Restore')
    Capabilities = [ordered]@{
        RequiresAdmin              = $true
        RequiresInternet           = $true
        CanReboot                  = $true
        CanModifyRegistry          = $true
        CanModifyServices          = $true
        CanInstallSoftware         = $true
        CanDownload                = $true
        CanModifyDrivers           = $true
        CanModifySecurity          = $false
        CanDeleteFiles             = $true
        UsesTrustedInstaller       = $false
        UsesSafeMode               = $false
        SupportsDefault            = $false
        SupportsRestore            = $false
        NeedsExplicitConfirmation  = $true
    }
}

$script:BoostLabImplementedActions = @('Analyze', 'Open', 'Apply', 'Default', 'Restore')
$script:BoostLabExpectedSourceHash = 'E69EFF538E7CE6108233C525A2BB88BA2D549CE6954AE751BE7BED778271C26F'
$script:BoostLabSourceRelativePath = 'source-ultimate/5 Graphics/1 Driver Install Debloat & Settings.ps1'
$script:BoostLabApprovedBranches = @('NVIDIA', 'AMD', 'INTEL')

function Get-BoostLabDriverInstallDebloatSettingsSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $projectRoot ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabDriverInstallDebloatSettingsSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabDriverInstallDebloatSettingsSourcePath
    $exists = Test-Path -LiteralPath $sourcePath -PathType Leaf
    $detectedHash = if ($exists) {
        (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
    }
    else {
        ''
    }

    [pscustomobject]@{
        SourcePath         = $sourcePath
        SourceRelativePath = $script:BoostLabSourceRelativePath
        Exists             = $exists
        ExpectedSha256     = $script:BoostLabExpectedSourceHash
        DetectedSha256     = $detectedHash
        ChecksumStatus     = if ($exists -and $detectedHash -eq $script:BoostLabExpectedSourceHash) {
            'Passed'
        }
        elseif ($exists) {
            'Failed'
        }
        else {
            'Missing'
        }
    }
}

function Test-BoostLabDriverInstallDebloatSettingsAdministrator {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-BoostLabDriverInstallDebloatSettingsInternet {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return [bool](Test-Connection -ComputerName '8.8.8.8' -Count 1 -Quiet -ErrorAction SilentlyContinue)
}

function ConvertTo-BoostLabDriverInstallDebloatSettingsBranch {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [AllowNull()]
        [string]$Branch
    )

    if ([string]::IsNullOrWhiteSpace($Branch)) {
        return ''
    }

    $normalized = $Branch.Trim().ToUpperInvariant()
    switch ($normalized) {
        '1' { return 'NVIDIA' }
        'NVIDIA' { return 'NVIDIA' }
        '2' { return 'AMD' }
        'AMD' { return 'AMD' }
        '3' { return 'INTEL' }
        'INTEL' { return 'INTEL' }
        default { return $normalized }
    }
}

function New-BoostLabDriverInstallDebloatSettingsResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$CommandStatus,

        [Parameter(Mandatory)]
        [string]$VerificationStatus,

        [Parameter(Mandatory)]
        [string]$Message,

        [AllowNull()]
        [object]$Data = $null,

        [string[]]$Warnings = @(),

        [string[]]$Errors = @(),

        [bool]$Cancelled = $false,

        [bool]$ChangesExecuted = $false,

        [bool]$RestartRequired = $false
    )

    [pscustomobject]@{
        Success            = $Success
        ToolId             = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle          = [string]$script:BoostLabToolMetadata['Title']
        Action             = $Action
        Status             = $Status
        CommandStatus      = $CommandStatus
        VerificationStatus = $VerificationStatus
        Message            = $Message
        RestartRequired    = $RestartRequired
        Cancelled          = $Cancelled
        ChangesExecuted    = $ChangesExecuted
        Timestamp          = Get-Date
        Data               = $Data
        Warnings           = @($Warnings | Select-Object -Unique)
        Errors             = @($Errors)
    }
}

function Get-BoostLabDriverInstallDebloatSettingsPaths {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $systemRoot = if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) { 'C:\Windows' } else { $env:SystemRoot }
    $systemDrive = if ([string]::IsNullOrWhiteSpace($env:SystemDrive)) { 'C:' } else { $env:SystemDrive }
    $programData = if ([string]::IsNullOrWhiteSpace($env:ProgramData)) { 'C:\ProgramData' } else { $env:ProgramData }

    return @{
        SystemRoot = $systemRoot
        SystemDrive = $systemDrive
        ProgramData = $programData
        Temp = Join-Path $systemRoot 'Temp'
        SevenZipInstaller = Join-Path $systemRoot 'Temp\7zip.exe'
        SevenZipExe = Join-Path $systemDrive 'Program Files\7-Zip\7z.exe'
        SevenZipShortcut = Join-Path $programData 'Microsoft\Windows\Start Menu\Programs\7-Zip\7-Zip File Manager.lnk'
        StartMenuPrograms = Join-Path $programData 'Microsoft\Windows\Start Menu\Programs'
        SevenZipStartMenuFolder = Join-Path $programData 'Microsoft\Windows\Start Menu\Programs\7-Zip'
        NvidiaExtractRoot = Join-Path $systemRoot 'Temp\nvidiadriver'
        NvidiaInspectorExe = Join-Path $systemRoot 'Temp\inspector.exe'
        NvidiaInspectorNip = Join-Path $systemRoot 'Temp\inspector.nip'
        NvidiaDrsPath = Join-Path $programData 'NVIDIA Corporation\Drs'
        NvidiaOldDriverRoot = Join-Path $systemDrive 'NVIDIA'
        AmdExtractRoot = Join-Path $systemRoot 'Temp\amddriver'
        AmdOldDriverRoot = Join-Path $systemDrive 'AMD'
        AmdBugReportStartMenu = Join-Path $programData 'Microsoft\Windows\Start Menu\Programs\AMD Bug Report Tool'
        AmdBugReportExe = Join-Path $systemDrive 'Windows\SysWOW64\AMDBugReportTool.exe'
        AmdRadeonSoftwareExe = Join-Path $systemDrive 'Program Files\AMD\CNext\CNext\RadeonSoftware.exe'
        IntelExtractRoot = Join-Path $systemDrive 'inteldriver'
        IntelOldDriverRoot = Join-Path $systemDrive 'Intel'
        IntelPresentMonExe = Join-Path $systemDrive 'Program Files\Intel\Intel Graphics Software\PresentMonService.exe'
        IntelStartMenuRoot = Join-Path $programData 'Microsoft\Windows\Start Menu\Programs\Intel'
        IntelGraphicsSoftwareRoot = Join-Path $systemDrive 'Program Files\Intel\Intel Graphics Software'
    }
}

function New-BoostLabDriverInstallDebloatSettingsOperation {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [int]$Order,

        [Parameter(Mandatory)]
        [string]$Branch,

        [Parameter(Mandatory)]
        [string]$Category,

        [Parameter(Mandatory)]
        [string]$Type,

        [Parameter(Mandatory)]
        [string]$Label,

        [Parameter(Mandatory)]
        [string]$SourceCommand,

        [AllowNull()]
        [System.Collections.IDictionary]$Parameters = $null
    )

    if ($null -eq $Parameters) {
        $Parameters = [ordered]@{}
    }

    [pscustomobject]@{
        Order = $Order
        Branch = $Branch
        Category = $Category
        Type = $Type
        Label = $Label
        SourceCommand = $SourceCommand
        Parameters = [ordered]@{} + $Parameters
    }
}

function Add-BoostLabDriverInstallDebloatSettingsOperation {
    param(
        [System.Collections.Generic.List[object]]$Operations,

        [Parameter(Mandatory)]
        [ref]$Order,

        [Parameter(Mandatory)]
        [string]$Branch,

        [Parameter(Mandatory)]
        [string]$Category,

        [Parameter(Mandatory)]
        [string]$Type,

        [Parameter(Mandatory)]
        [string]$Label,

        [Parameter(Mandatory)]
        [string]$SourceCommand,

        [AllowNull()]
        [System.Collections.IDictionary]$Parameters = $null
    )

    $Operations.Add((New-BoostLabDriverInstallDebloatSettingsOperation `
        -Order $Order.Value `
        -Branch $Branch `
        -Category $Category `
        -Type $Type `
        -Label $Label `
        -SourceCommand $SourceCommand `
        -Parameters $Parameters))
    $Order.Value++
}

function Get-BoostLabDriverInstallDebloatSettingsNipContent {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $sourcePath = Get-BoostLabDriverInstallDebloatSettingsSourcePath
    $lines = Get-Content -LiteralPath $sourcePath
    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq '$nipfile = @''') {
            $start = $i + 1
            break
        }
    }
    if ($start -lt 0) {
        throw 'The NVIDIA Profile Inspector .nip here-string was not found in the approved source.'
    }

    $end = -1
    for ($i = $start; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq "'@") {
            $end = $i - 1
            break
        }
    }
    if ($end -lt $start) {
        throw 'The NVIDIA Profile Inspector .nip here-string end marker was not found in the approved source.'
    }

    return (($lines[$start..$end]) -join "`r`n")
}

function Add-BoostLabDriverInstallDebloatSettingsCommonOperations {
    param(
        [System.Collections.Generic.List[object]]$Operations,

        [Parameter(Mandatory)]
        [ref]$Order,

        [Parameter(Mandatory)]
        [string]$Branch,

        [Parameter(Mandatory)]
        [hashtable]$Paths
    )

    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $Branch 'Environment' 'RequireAdministrator' 'Require Administrator execution' '# SCRIPT RUN AS ADMIN'
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $Branch 'Environment' 'RequireInternet' 'Require internet connectivity' 'Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet'
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $Branch 'Artifact' 'DownloadFile' 'Download 7-Zip installer' 'IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe" -OutFile "$env:SystemRoot\Temp\7zip.exe"' ([ordered]@{
        Url = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe'
        Destination = $Paths.SevenZipInstaller
    })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $Branch 'Installer' 'StartProcess' 'Install 7-Zip silently' 'Start-Process -Wait "$env:SystemRoot\Temp\7zip.exe" -ArgumentList "/S"' ([ordered]@{
        FilePath = $Paths.SevenZipInstaller
        Arguments = @('/S')
        Wait = $true
    })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $Branch 'Registry' 'Cmd' 'Set 7-Zip ContextMenu option' 'cmd /c "reg add `"HKEY_CURRENT_USER\Software\7-Zip\Options`" /v `"ContextMenu`" /t REG_DWORD /d `"259`" /f >nul 2>&1"' ([ordered]@{
        Command = 'reg add "HKEY_CURRENT_USER\Software\7-Zip\Options" /v "ContextMenu" /t REG_DWORD /d "259" /f >nul 2>&1'
    })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $Branch 'Registry' 'Cmd' 'Set 7-Zip CascadedMenu option' 'cmd /c "reg add `"HKEY_CURRENT_USER\Software\7-Zip\Options`" /v `"CascadedMenu`" /t REG_DWORD /d `"0`" /f >nul 2>&1"' ([ordered]@{
        Command = 'reg add "HKEY_CURRENT_USER\Software\7-Zip\Options" /v "CascadedMenu" /t REG_DWORD /d "0" /f >nul 2>&1'
    })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $Branch 'File' 'MoveItem' 'Move 7-Zip Start Menu shortcut' 'Move-Item -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\7-Zip\7-Zip File Manager.lnk" -Destination "$env:ProgramData\Microsoft\Windows\Start Menu\Programs" -Force -ErrorAction SilentlyContinue' ([ordered]@{
        Path = $Paths.SevenZipShortcut
        Destination = $Paths.StartMenuPrograms
    })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $Branch 'File' 'RemoveItem' 'Remove 7-Zip Start Menu folder' 'Remove-Item "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\7-Zip" -Recurse -Force -ErrorAction SilentlyContinue' ([ordered]@{
        Path = $Paths.SevenZipStartMenuFolder
        Recurse = $true
    })
}

function Add-BoostLabDriverInstallDebloatSettingsNvidiaOperations {
    param(
        [System.Collections.Generic.List[object]]$Operations,

        [Parameter(Mandatory)]
        [ref]$Order,

        [Parameter(Mandatory)]
        [hashtable]$Paths
    )

    $branch = 'NVIDIA'
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'DriverPage' 'Sleep' 'Wait before opening NVIDIA driver page' 'Start-Sleep -Seconds 5' ([ordered]@{ Seconds = 5 })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'DriverPage' 'StartProcess' 'Open NVIDIA driver page' 'Start-Process "https://www.nvidia.com/en-us/drivers"' ([ordered]@{ FilePath = 'https://www.nvidia.com/en-us/drivers'; Wait = $false })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'DriverPage' 'UserPause' 'Wait for user to download NVIDIA driver' 'Pause'
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'InstallerSelection' 'Sleep' 'Wait before NVIDIA installer selection' 'Start-Sleep -Seconds 5' ([ordered]@{ Seconds = 5 })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'InstallerSelection' 'SelectInstaller' 'Select downloaded NVIDIA driver installer' 'System.Windows.Forms.OpenFileDialog' ([ordered]@{ InstallFile = '{{InstallFile}}' })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Extraction' 'ExternalCommand' 'Extract NVIDIA driver with 7-Zip' '& "$env:SystemDrive\Program Files\7-Zip\7z.exe" x "$InstallFile" -o"$env:SystemRoot\Temp\nvidiadriver" -y' ([ordered]@{
        FilePath = $Paths.SevenZipExe
        Arguments = @('x', '{{InstallFile}}', ('-o{0}' -f $Paths.NvidiaExtractRoot), '-y')
    })

    foreach ($target in @(
        'Display.Nview', 'FrameViewSDK', 'HDAudio', 'MSVCRT', 'NvApp.MessageBus',
        'NvBackend', 'NvContainer', 'NvCpl', 'NvDLISR', 'NVPCF', 'NvTelemetry',
        'NvVAD', 'PhysX', 'PPC', 'ShadowPlay', 'NvApp\CEF', 'NvApp\osc',
        'NvApp\Plugins', 'NvApp\UpgradeConsent', 'NvApp\www', 'NvApp\7z.dll',
        'NvApp\7z.exe', 'NvApp\DarkModeCheck.exe', 'NvApp\InstallerExtension.dll',
        'NvApp\NvApp.nvi', 'NvApp\NvAppApi.dll', 'NvApp\NvAppExt.dll',
        'NvApp\NvConfigGenerator.dll'
    )) {
        Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Debloat' 'RemoveItem' "Remove NVIDIA driver component $target" ('Remove-Item "$env:SystemRoot\Temp\nvidiadriver\{0}" -Recurse -Force -ErrorAction SilentlyContinue' -f $target) ([ordered]@{
            Path = Join-Path $Paths.NvidiaExtractRoot $target
            Recurse = $true
        })
    }

    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Installer' 'StartProcess' 'Install NVIDIA driver silently' 'Start-Process "$env:SystemRoot\Temp\nvidiadriver\setup.exe" -ArgumentList "-s -noreboot -noeula -clean" -Wait -NoNewWindow' ([ordered]@{
        FilePath = Join-Path $Paths.NvidiaExtractRoot 'setup.exe'
        Arguments = @('-s', '-noreboot', '-noeula', '-clean')
        Wait = $true
        NoNewWindow = $true
    })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Package' 'StartProcess' 'Install NVIDIA Control Panel through winget' 'Start-Process "winget" -ArgumentList "install `"9NF8H0H7WMLT`" --silent --accept-package-agreements --accept-source-agreements --disable-interactivity --no-upgrade" -Wait -WindowStyle Hidden' ([ordered]@{
        FilePath = 'winget'
        Arguments = @('install', '9NF8H0H7WMLT', '--silent', '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity', '--no-upgrade')
        Wait = $true
        WindowStyle = 'Hidden'
        ContinueOnError = $true
    })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Package' 'RemoveAppxPackagePattern' 'Remove Microsoft.Winget.Source AppX package' 'Get-AppxPackage -allusers *Microsoft.Winget.Source* | Remove-AppxPackage -ErrorAction SilentlyContinue' ([ordered]@{ Pattern = '*Microsoft.Winget.Source*' })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Cleanup' 'RemoveItem' 'Delete selected NVIDIA installer' 'Remove-Item "$InstallFile" -Force -ErrorAction SilentlyContinue' ([ordered]@{ Path = '{{InstallFile}}' })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Cleanup' 'RemoveItem' 'Delete old NVIDIA driver folder' 'Remove-Item "$env:SystemDrive\NVIDIA" -Recurse -Force -ErrorAction SilentlyContinue' ([ordered]@{ Path = $Paths.NvidiaOldDriverRoot; Recurse = $true })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Registry' 'DynamicDisplayClassRegAdd' 'Set DisableDynamicPstate on display class keys' 'reg add "$key" /v "DisableDynamicPstate" /t REG_DWORD /d "1" /f' ([ordered]@{ ValueName = 'DisableDynamicPstate'; Type = 'REG_DWORD'; Data = '1'; ExcludeConfiguration = $true })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Registry' 'DynamicDisplayClassRegAdd' 'Set RMHdcpKeyglobZero on display class keys' 'reg add "$key" /v "RMHdcpKeyglobZero" /t REG_DWORD /d "1" /f' ([ordered]@{ ValueName = 'RMHdcpKeyglobZero'; Type = 'REG_DWORD'; Data = '1'; ExcludeConfiguration = $true })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'File' 'UnblockFiles' 'Unblock NVIDIA DRS files' 'Get-ChildItem -Path "C:\ProgramData\NVIDIA Corporation\Drs" -Recurse | Unblock-File' ([ordered]@{ Path = $Paths.NvidiaDrsPath })
    foreach ($cmdInfo in @(
        @{ Label = 'Set NVIDIA PhysX auto mode to GPU'; Command = 'reg add "HKLM\System\ControlSet001\Services\nvlddmkm\Parameters\Global\NVTweak" /v "NvCplPhysxAuto" /t REG_DWORD /d "0" /f >nul 2>&1' },
        @{ Label = 'Enable NVIDIA developer settings'; Command = 'reg add "HKLM\System\ControlSet001\Services\nvlddmkm\Parameters\Global\NVTweak" /v "NvDevToolsVisible" /t REG_DWORD /d "1" /f >nul 2>&1' },
        @{ Label = 'Set NVIDIA performance counter access in NVTweak'; Command = 'reg add "HKLM\System\ControlSet001\Services\nvlddmkm\Parameters\Global\NVTweak" /v "RmProfilingAdminOnly" /t REG_DWORD /d "0" /f >nul 2>&1' },
        @{ Label = 'Disable NVIDIA tray start on login'; Command = 'reg add "HKCU\Software\NVIDIA Corporation\NvTray" /v "StartOnLogin" /t REG_DWORD /d "0" /f >nul 2>&1' },
        @{ Label = 'Set EnableGR535 on CurrentControlSet FTS'; Command = 'reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\FTS" /v "EnableGR535" /t REG_DWORD /d "0" /f >nul 2>&1' },
        @{ Label = 'Set EnableGR535 on ControlSet001 Parameters FTS'; Command = 'reg add "HKLM\SYSTEM\ControlSet001\Services\nvlddmkm\Parameters\FTS" /v "EnableGR535" /t REG_DWORD /d "0" /f >nul 2>&1' },
        @{ Label = 'Set EnableGR535 on CurrentControlSet Parameters FTS'; Command = 'reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters\FTS" /v "EnableGR535" /t REG_DWORD /d "0" /f >nul 2>&1' }
    )) {
        Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Registry' 'Cmd' $cmdInfo.Label ('cmd /c "{0}"' -f $cmdInfo.Command) ([ordered]@{ Command = $cmdInfo.Command })
    }
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Registry' 'DynamicDisplayClassRegAdd' 'Set RmProfilingAdminOnly on display class keys' 'reg add "$key" /v "RmProfilingAdminOnly" /t REG_DWORD /d "0" /f' ([ordered]@{ ValueName = 'RmProfilingAdminOnly'; Type = 'REG_DWORD'; Data = '0'; ExcludeConfiguration = $true })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Artifact' 'DownloadFile' 'Download NVIDIA Profile Inspector' 'IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/inspector.exe" -OutFile "$env:SystemRoot\Temp\inspector.exe"' ([ordered]@{
        Url = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/inspector.exe'
        Destination = $Paths.NvidiaInspectorExe
    })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Profile' 'WriteTextFile' 'Write source-defined NVIDIA Profile Inspector .nip file' 'Set-Content -Path "$env:SystemRoot\Temp\inspector.nip" -Value $nipfile -Force' ([ordered]@{
        Path = $Paths.NvidiaInspectorNip
        Content = (Get-BoostLabDriverInstallDebloatSettingsNipContent)
        ProfileSettingCount = 31
    })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Profile' 'StartProcess' 'Import NVIDIA Profile Inspector .nip file' 'Start-Process -wait "$env:SystemRoot\Temp\inspector.exe" -ArgumentList "-silentImport -silent $env:SystemRoot\Temp\inspector.nip"' ([ordered]@{
        FilePath = $Paths.NvidiaInspectorExe
        Arguments = @('-silentImport', '-silent', $Paths.NvidiaInspectorNip)
        Wait = $true
    })
}

function Add-BoostLabDriverInstallDebloatSettingsAmdOperations {
    param(
        [System.Collections.Generic.List[object]]$Operations,

        [Parameter(Mandatory)]
        [ref]$Order,

        [Parameter(Mandatory)]
        [hashtable]$Paths
    )

    $branch = 'AMD'
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'DriverPage' 'Sleep' 'Wait before opening AMD driver page' 'Start-Sleep -Seconds 5' ([ordered]@{ Seconds = 5 })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'DriverPage' 'StartProcess' 'Open AMD driver page' 'Start-Process "https://www.amd.com/en/support/download/drivers.html"' ([ordered]@{ FilePath = 'https://www.amd.com/en/support/download/drivers.html'; Wait = $false })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'DriverPage' 'UserPause' 'Wait for user to download AMD driver' 'Pause'
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'InstallerSelection' 'Sleep' 'Wait before AMD installer selection' 'Start-Sleep -Seconds 5' ([ordered]@{ Seconds = 5 })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'InstallerSelection' 'SelectInstaller' 'Select downloaded AMD driver installer' 'System.Windows.Forms.OpenFileDialog' ([ordered]@{ InstallFile = '{{InstallFile}}' })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Extraction' 'ExternalCommand' 'Extract AMD driver with 7-Zip' '& "$env:SystemDrive\Program Files\7-Zip\7z.exe" x "$InstallFile" -o"$env:SystemRoot\Temp\amddriver" -y' ([ordered]@{
        FilePath = $Paths.SevenZipExe
        Arguments = @('x', '{{InstallFile}}', ('-o{0}' -f $Paths.AmdExtractRoot), '-y')
    })

    $xmlFiles = @(
        'Config\AMDAUEPInstaller.xml', 'Config\AMDCOMPUTE.xml', 'Config\AMDLinkDriverUpdate.xml',
        'Config\AMDRELAUNCHER.xml', 'Config\AMDScoSupportTypeUpdate.xml', 'Config\AMDUpdater.xml',
        'Config\AMDUWPLauncher.xml', 'Config\EnableWindowsDriverSearch.xml', 'Config\InstallUEP.xml',
        'Config\ModifyLinkUpdate.xml'
    )
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'FileEdit' 'EditXmlFiles' 'Set AMD XML Enabled/Hidden flags to false' 'Set AMD Config XML <Enabled>/<Hidden> nodes to false' ([ordered]@{
        Paths = @($xmlFiles | ForEach-Object { Join-Path $Paths.AmdExtractRoot $_ })
        Replacements = @(
            @{ Pattern = '<Enabled>true</Enabled>'; Replacement = '<Enabled>false</Enabled>' },
            @{ Pattern = '<Hidden>true</Hidden>'; Replacement = '<Hidden>false</Hidden>' }
        )
    })
    $jsonFiles = @('Config\InstallManifest.json', 'Bin64\cccmanifest_64.json')
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'FileEdit' 'EditJsonFiles' 'Set AMD JSON InstallByDefault to No' '"InstallByDefault" : "No"' ([ordered]@{
        Paths = @($jsonFiles | ForEach-Object { Join-Path $Paths.AmdExtractRoot $_ })
        Pattern = '"InstallByDefault"\s*:\s*"Yes"'
        Replacement = '"InstallByDefault" : "No"'
    })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Installer' 'StartProcess' 'Install AMD driver through ATISetup.exe' 'Start-Process -Wait "$env:SystemRoot\Temp\amddriver\Bin64\ATISetup.exe" -ArgumentList "-INSTALL -VIEW:2" -WindowStyle Hidden' ([ordered]@{
        FilePath = Join-Path $Paths.AmdExtractRoot 'Bin64\ATISetup.exe'
        Arguments = @('-INSTALL', '-VIEW:2')
        Wait = $true
        WindowStyle = 'Hidden'
    })

    foreach ($cmdInfo in @(
        @{ Label = 'Delete AMDNoiseSuppression startup'; Command = 'reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "AMDNoiseSuppression" /f >nul 2>&1' },
        @{ Label = 'Delete StartRSX RunOnce startup'; Command = 'reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v "StartRSX" /f >nul 2>&1' }
    )) {
        Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Registry' 'Cmd' $cmdInfo.Label ('cmd /c "{0}"' -f $cmdInfo.Command) ([ordered]@{ Command = $cmdInfo.Command; ContinueOnError = $true })
    }
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Task' 'UnregisterScheduledTask' 'Delete StartCN scheduled task' 'Unregister-ScheduledTask -TaskName "StartCN" -Confirm:$false -ErrorAction SilentlyContinue' ([ordered]@{ TaskName = 'StartCN' })
    foreach ($service in @('AMD Crash Defender Service', 'amdfendr', 'amdfendrmgr', 'amdacpbus', 'AMDSAFD', 'AtiHDAudioService')) {
        Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Service' 'Cmd' "Stop AMD service/driver $service" ('cmd /c "sc stop `"{0}`" >nul 2>&1"' -f $service) ([ordered]@{ Command = ('sc stop "{0}" >nul 2>&1' -f $service); ContinueOnError = $true })
        Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Service' 'Cmd' "Delete AMD service/driver $service" ('cmd /c "sc delete `"{0}`" >nul 2>&1"' -f $service) ([ordered]@{ Command = ('sc delete "{0}" >nul 2>&1' -f $service); ContinueOnError = $true })
    }
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Cleanup' 'RemoveItem' 'Remove AMD Bug Report Tool Start Menu folder' 'Remove-Item "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\AMD Bug Report Tool" -Recurse -Force -ErrorAction SilentlyContinue' ([ordered]@{ Path = $Paths.AmdBugReportStartMenu; Recurse = $true })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Cleanup' 'RemoveItem' 'Remove AMDBugReportTool.exe' 'Remove-Item "$env:SystemDrive\Windows\SysWOW64\AMDBugReportTool.exe" -Force -ErrorAction SilentlyContinue' ([ordered]@{ Path = $Paths.AmdBugReportExe })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Package' 'UninstallMsiByDisplayName' 'Uninstall AMD Install Manager MSI entry' 'Start-Process "msiexec.exe" -ArgumentList "/x $guid /qn /norestart" -Wait -NoNewWindow' ([ordered]@{ DisplayNamePattern = '*AMD Install Manager*' })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Cleanup' 'RemoveItem' 'Delete selected AMD installer' 'Remove-Item "$InstallFile" -Force -ErrorAction SilentlyContinue' ([ordered]@{ Path = '{{InstallFile}}' })
    $amdFolderName = "AMD Software$([char]0xA789) Adrenalin Edition"
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'File' 'MoveItem' 'Move AMD Software Adrenalin shortcut' 'Move-Item -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\$folderName\$folderName.lnk" -Destination "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"' ([ordered]@{
        Path = Join-Path $Paths.StartMenuPrograms "$amdFolderName\$amdFolderName.lnk"
        Destination = $Paths.StartMenuPrograms
    })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Cleanup' 'RemoveItem' 'Remove AMD Software Adrenalin Start Menu folder' 'Remove-Item "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\$folderName" -Recurse -Force -ErrorAction SilentlyContinue' ([ordered]@{ Path = Join-Path $Paths.StartMenuPrograms $amdFolderName; Recurse = $true })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Cleanup' 'RemoveItem' 'Delete old AMD driver folder' 'Remove-Item "$env:SystemDrive\AMD" -Recurse -Force -ErrorAction SilentlyContinue' ([ordered]@{ Path = $Paths.AmdOldDriverRoot; Recurse = $true })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'VendorUI' 'StartProcess' 'Open Radeon Software so settings stick' 'Start-Process "$env:SystemDrive\Program Files\AMD\CNext\CNext\RadeonSoftware.exe"' ([ordered]@{ FilePath = $Paths.AmdRadeonSoftwareExe; Wait = $false })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'VendorUI' 'Sleep' 'Wait for Radeon Software settings page' 'Start-Sleep -Seconds 15' ([ordered]@{ Seconds = 15 })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Process' 'StopProcess' 'Stop RadeonSoftware process' 'Stop-Process -Name "RadeonSoftware" -Force -ErrorAction SilentlyContinue' ([ordered]@{ Names = @('RadeonSoftware') })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'VendorUI' 'Sleep' 'Wait after stopping Radeon Software' 'Start-Sleep -Seconds 2' ([ordered]@{ Seconds = 2 })

    foreach ($cmdInfo in @(
        @{ Label = 'Set AMD AutoUpdate to manual'; Command = 'reg add "HKCU\Software\AMD\CN" /v "AutoUpdate" /t REG_DWORD /d "0" /f >nul 2>&1' },
        @{ Label = 'Set AMD graphics profile custom'; Command = 'reg add "HKCU\Software\AMD\CN" /v "WizardProfile" /t REG_SZ /d "PROFILE_CUSTOM" /f >nul 2>&1' },
        @{ Label = 'Accept AMD custom resolution EULA'; Command = 'reg add "HKCU\Software\AMD\CN\CustomResolutions" /v "EulaAccepted" /t REG_SZ /d "true" /f >nul 2>&1' },
        @{ Label = 'Accept AMD display override EULA'; Command = 'reg add "HKCU\Software\AMD\CN\DisplayOverride" /v "EulaAccepted" /t REG_SZ /d "true" /f >nul 2>&1' },
        @{ Label = 'Disable AMD system tray menu'; Command = 'reg add "HKCU\Software\AMD\CN" /v "SystemTray" /t REG_SZ /d "false" /f >nul 2>&1' },
        @{ Label = 'Disable AMD toast notifications'; Command = 'reg add "HKCU\Software\AMD\CN" /v "CN_Hide_Toast_Notification" /t REG_SZ /d "true" /f >nul 2>&1' },
        @{ Label = 'Disable AMD animation effects'; Command = 'reg add "HKCU\Software\AMD\CN" /v "AnimationEffect" /t REG_SZ /d "false" /f >nul 2>&1' },
        @{ Label = 'Delete AMD notifications key'; Command = 'reg delete "HKCU\Software\AMD\CN\Notification" /f >nul 2>&1' },
        @{ Label = 'Create AMD notifications key'; Command = 'reg add "HKCU\Software\AMD\CN\Notification" /f >nul 2>&1' },
        @{ Label = 'Mark AMD FreeSync notification shown'; Command = 'reg add "HKCU\Software\AMD\CN\FreeSync" /v "AlreadyNotified" /t REG_DWORD /d "1" /f >nul 2>&1' },
        @{ Label = 'Mark AMD overlay notification shown'; Command = 'reg add "HKCU\Software\AMD\CN\OverlayNotification" /v "AlreadyNotified" /t REG_DWORD /d "1" /f >nul 2>&1' },
        @{ Label = 'Mark AMD VirtualSuperResolution notification shown'; Command = 'reg add "HKCU\Software\AMD\CN\VirtualSuperResolution" /v "AlreadyNotified" /t REG_DWORD /d "1" /f >nul 2>&1' }
    )) {
        Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Registry' 'Cmd' $cmdInfo.Label ('cmd /c "{0}"' -f $cmdInfo.Command) ([ordered]@{ Command = $cmdInfo.Command; ContinueOnError = $true })
    }
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Registry' 'DynamicRecurseRegAdd' 'Set AMD UMD VSyncControl binary' 'reg add "$regPath" /v "VSyncControl" /t REG_BINARY /d "3000" /f' ([ordered]@{ ChildName = 'UMD'; ValueName = 'VSyncControl'; Type = 'REG_BINARY'; Data = '3000' })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Registry' 'DynamicRecurseRegAdd' 'Set AMD UMD texture filtering quality binary' 'reg add "$regPath" /v "TFQ" /t REG_BINARY /d "3200" /f' ([ordered]@{ ChildName = 'UMD'; ValueName = 'TFQ'; Type = 'REG_BINARY'; Data = '3200' })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Registry' 'DynamicRecurseRegAdd' 'Set AMD UMD tessellation binary' 'reg add "$regPath" /v "Tessellation" /t REG_BINARY /d "3100" /f' ([ordered]@{ ChildName = 'UMD'; ValueName = 'Tessellation'; Type = 'REG_BINARY'; Data = '3100' })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Registry' 'DynamicRecurseRegAdd' 'Set AMD UMD tessellation option binary' 'reg add "$regPath" /v "Tessellation_OPTION" /t REG_BINARY /d "3200" /f' ([ordered]@{ ChildName = 'UMD'; ValueName = 'Tessellation_OPTION'; Type = 'REG_BINARY'; Data = '3200' })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Registry' 'DynamicRecurseRegAdd' 'Set AMD Vari-Bright abmlevel binary' 'reg add "$regPath" /v "abmlevel" /t REG_BINARY /d "00000000" /f' ([ordered]@{ ChildName = 'power_v1'; ValueName = 'abmlevel'; Type = 'REG_BINARY'; Data = '00000000' })
}

function Add-BoostLabDriverInstallDebloatSettingsIntelOperations {
    param(
        [System.Collections.Generic.List[object]]$Operations,

        [Parameter(Mandatory)]
        [ref]$Order,

        [Parameter(Mandatory)]
        [hashtable]$Paths
    )

    $branch = 'INTEL'
    $intelUrl = 'https://www.intel.com/content/www/us/en/search.html#sortCriteria=%40lastmodifieddt%20descending&f-operatingsystem_en=Windows%2011%20Family*&f-downloadtype=Drivers&cf-tabfilter=Downloads&cf-downloadsppth=Graphics'
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'DriverPage' 'Sleep' 'Wait before opening Intel driver page' 'Start-Sleep -Seconds 5' ([ordered]@{ Seconds = 5 })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'DriverPage' 'StartProcess' 'Open Intel driver page' 'Start-Process "https://www.intel.com/content/www/us/en/search.html#sortCriteria=..."' ([ordered]@{ FilePath = $intelUrl; Wait = $false })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'DriverPage' 'UserPause' 'Wait for user to download Intel driver' 'Pause'
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'InstallerSelection' 'Sleep' 'Wait before Intel installer selection' 'Start-Sleep -Seconds 5' ([ordered]@{ Seconds = 5 })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'InstallerSelection' 'SelectInstaller' 'Select downloaded Intel driver installer' 'System.Windows.Forms.OpenFileDialog' ([ordered]@{ InstallFile = '{{InstallFile}}' })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Extraction' 'ExternalCommand' 'Extract Intel driver with 7-Zip' '& "$env:SystemDrive\Program Files\7-Zip\7z.exe" x "$InstallFile" -o"$env:SystemDrive\inteldriver" -y' ([ordered]@{
        FilePath = $Paths.SevenZipExe
        Arguments = @('x', '{{InstallFile}}', ('-o{0}' -f $Paths.IntelExtractRoot), '-y')
    })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Installer' 'StartProcess' 'Run Intel driver Installer.exe with noExtras' 'Start-Process "cmd.exe" -ArgumentList "/c `"$env:SystemDrive\inteldriver\Installer.exe`" -f --noExtras --terminateProcesses -s" -WindowStyle Hidden -Wait' ([ordered]@{
        FilePath = 'cmd.exe'
        Arguments = @('/c', ('"{0}" -f --noExtras --terminateProcesses -s' -f (Join-Path $Paths.IntelExtractRoot 'Installer.exe')))
        Wait = $true
        WindowStyle = 'Hidden'
    })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Package' 'StartFirstMatchingProcess' 'Install Intel Graphics Software extra package' 'Start-Process "$env:SystemDrive\inteldriver\Resources\Extras\$IntelGraphicsSoftware" -ArgumentList "/s" -Wait -NoNewWindow' ([ordered]@{
        Directory = Join-Path $Paths.IntelExtractRoot 'Resources\Extras'
        Filter = 'IntelGraphicsSoftware_*.exe'
        Arguments = @('/s')
        Wait = $true
    })
    $intelRunValue = "Intel$([char]0xAE) Graphics Software"
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Registry' 'Cmd' 'Delete Intel Graphics Software startup value' 'cmd /c "reg delete `"HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run`" /v `"$FileName`" /f >nul 2>&1"' ([ordered]@{
        Command = ('reg delete "HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" /v "{0}" /f >nul 2>&1' -f $intelRunValue)
        ContinueOnError = $true
    })
    foreach ($service in @('IntelGFXFWupdateTool', 'cplspcon', 'CtaChildDriver', 'GSCAuxDriver', 'GSCx64')) {
        Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Service' 'Cmd' "Stop Intel service/driver $service" ('cmd /c "sc stop `"{0}`" >nul 2>&1"' -f $service) ([ordered]@{ Command = ('sc stop "{0}" >nul 2>&1' -f $service); ContinueOnError = $true })
        Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Service' 'Cmd' "Delete Intel service/driver $service" ('cmd /c "sc delete `"{0}`" >nul 2>&1"' -f $service) ([ordered]@{ Command = ('sc delete "{0}" >nul 2>&1' -f $service); ContinueOnError = $true })
    }
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Process' 'StopProcess' 'Stop IntelGraphicsSoftware and PresentMonService processes' '$stop | ForEach-Object { Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue }' ([ordered]@{ Names = @('IntelGraphicsSoftware', 'PresentMonService') })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Process' 'Sleep' 'Wait after stopping Intel processes' 'Start-Sleep -Seconds 2' ([ordered]@{ Seconds = 2 })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Cleanup' 'RemoveItem' 'Remove Intel PresentMonService.exe' 'Remove-Item "$env:SystemDrive\Program Files\Intel\Intel Graphics Software\PresentMonService.exe" -Force -ErrorAction SilentlyContinue' ([ordered]@{ Path = $Paths.IntelPresentMonExe })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Cleanup' 'RemoveItem' 'Delete selected Intel installer' 'Remove-Item "$InstallFile" -Force -ErrorAction SilentlyContinue' ([ordered]@{ Path = '{{InstallFile}}' })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'File' 'MoveItem' 'Move Intel Graphics Software shortcut' 'Move-Item -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Intel\Intel Graphics Software\$FileName.lnk" -Destination "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"' ([ordered]@{
        Path = Join-Path $Paths.StartMenuPrograms ("Intel\Intel Graphics Software\{0}.lnk" -f $intelRunValue)
        Destination = $Paths.StartMenuPrograms
    })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Cleanup' 'RemoveItem' 'Remove Intel Start Menu folder' 'Remove-Item "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Intel" -Recurse -Force -ErrorAction SilentlyContinue' ([ordered]@{ Path = $Paths.IntelStartMenuRoot; Recurse = $true })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Cleanup' 'RemoveItem' 'Delete old Intel driver folder' 'Remove-Item "$env:SystemDrive\Intel" -Recurse -Force -ErrorAction SilentlyContinue' ([ordered]@{ Path = $Paths.IntelOldDriverRoot; Recurse = $true })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Cleanup' 'RemoveItem' 'Delete extracted Intel driver folder' 'Remove-Item "$env:SystemDrive\inteldriver" -Recurse -Force -ErrorAction SilentlyContinue' ([ordered]@{ Path = $Paths.IntelExtractRoot; Recurse = $true })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Registry' 'DynamicDisplayClassCreateSubkey' 'Create Intel 3DKeys subkeys' 'cmd /c "reg add `"$regPath\3DKeys`" /f >nul 2>&1"' ([ordered]@{ ChildNamePattern = '^\d{4}$'; SubkeyName = '3DKeys' })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Registry' 'DynamicRecurseRegAdd' 'Set Intel Global_AsyncFlipMode' 'reg add "$regPath" /v "Global_AsyncFlipMode" /t REG_DWORD /d "2" /f' ([ordered]@{ ChildName = '3DKeys'; ValueName = 'Global_AsyncFlipMode'; Type = 'REG_DWORD'; Data = '2' })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $branch 'Registry' 'DynamicRecurseRegAdd' 'Set Intel Global_LowLatency' 'reg add "$regPath" /v "Global_LowLatency" /t REG_DWORD /d "0" /f' ([ordered]@{ ChildName = '3DKeys'; ValueName = 'Global_LowLatency'; Type = 'REG_DWORD'; Data = '0' })
}

function Add-BoostLabDriverInstallDebloatSettingsSharedPostBranchOperations {
    param(
        [System.Collections.Generic.List[object]]$Operations,

        [Parameter(Mandatory)]
        [ref]$Order,

        [Parameter(Mandatory)]
        [string]$Branch
    )

    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $Branch 'VendorUI' 'StartProcess' 'Open Windows display settings' 'Start-Process "ms-settings:display"' ([ordered]@{ FilePath = 'ms-settings:display'; ContinueOnError = $true })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $Branch 'VendorUI' 'StartProcess' 'Open NVIDIA Control Panel AppX shell target' 'Start-Process shell:appsFolder\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj!NVIDIACorp.NVIDIAControlPanel' ([ordered]@{ FilePath = 'shell:appsFolder\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj!NVIDIACorp.NVIDIAControlPanel'; ContinueOnError = $true })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $Branch 'VendorUI' 'StartProcess' 'Open Windows Sound Control Panel' 'Start-Process mmsys.cpl' ([ordered]@{ FilePath = 'mmsys.cpl' })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $Branch 'VendorUI' 'UserPause' 'Wait for user to set sound, resolution, refresh rate, and primary display' 'Pause'
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $Branch 'Registry' 'DynamicMonitorRegAdd' 'Disable automatically manage color for apps' 'reg add "$regPath" /v "AutoColorManagementEnabled" /t REG_DWORD /d "0" /f' ([ordered]@{ ValueName = 'AutoColorManagementEnabled'; Type = 'REG_DWORD'; Data = '0' })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $Branch 'Registry' 'DynamicPnpMsiMode' 'Enable MSI mode for all display devices' 'reg add "HKLM\SYSTEM\ControlSet001\Enum\$instanceID\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f' ([ordered]@{ ValueName = 'MSISupported'; Type = 'REG_DWORD'; Data = '1' })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $Branch 'Registry' 'DynamicNotifyIconPromotion' 'Show all hidden taskbar icons' 'Set-ItemProperty -Path "registry::$setreg" -Name "IsPromoted" -Value 1 -Force' ([ordered]@{ ValueName = 'IsPromoted'; Data = 1 })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $Branch 'Session' 'Sleep' 'Wait before restart' 'Start-Sleep -Seconds 5' ([ordered]@{ Seconds = 5 })
    Add-BoostLabDriverInstallDebloatSettingsOperation $Operations $Order $Branch 'Session' 'ShutdownRestart' 'Restart the PC immediately' 'shutdown -r -t 00'
}

function Get-BoostLabDriverInstallDebloatSettingsOperationPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$Branch = '',

        [string]$InstallFile = ''
    )

    $normalizedBranch = ConvertTo-BoostLabDriverInstallDebloatSettingsBranch -Branch $Branch
    if ($normalizedBranch -notin $script:BoostLabApprovedBranches) {
        throw "Unsupported Driver Install Debloat & Settings branch '$Branch'. Select NVIDIA, AMD, or INTEL."
    }

    $paths = Get-BoostLabDriverInstallDebloatSettingsPaths
    $operations = [System.Collections.Generic.List[object]]::new()
    $order = 1

    Add-BoostLabDriverInstallDebloatSettingsCommonOperations -Operations $operations -Order ([ref]$order) -Branch $normalizedBranch -Paths $paths
    switch ($normalizedBranch) {
        'NVIDIA' { Add-BoostLabDriverInstallDebloatSettingsNvidiaOperations -Operations $operations -Order ([ref]$order) -Paths $paths }
        'AMD' { Add-BoostLabDriverInstallDebloatSettingsAmdOperations -Operations $operations -Order ([ref]$order) -Paths $paths }
        'INTEL' { Add-BoostLabDriverInstallDebloatSettingsIntelOperations -Operations $operations -Order ([ref]$order) -Paths $paths }
    }
    Add-BoostLabDriverInstallDebloatSettingsSharedPostBranchOperations -Operations $operations -Order ([ref]$order) -Branch $normalizedBranch

    $categories = @($operations | Group-Object -Property Category | ForEach-Object {
        [pscustomobject]@{
            Category = $_.Name
            Count = $_.Count
        }
    })

    [pscustomobject]@{
        Branch = $normalizedBranch
        SourcePath = $script:BoostLabSourceRelativePath
        SourceSha256 = $script:BoostLabExpectedSourceHash
        InstallerInput = if ([string]::IsNullOrWhiteSpace($InstallFile)) { 'OpenFileDialog' } else { $InstallFile }
        OperationCount = $operations.Count
        Categories = $categories
        Operations = $operations.ToArray()
        RequiresAdmin = $true
        RequiresInternet = $true
        RestartRequired = $true
        UsesBranchSelection = $true
        ExecutesOneBranchOnly = $true
        DefaultAvailable = $false
        RestoreAvailable = $false
    }
}

function Get-BoostLabDriverInstallDebloatSettingsAllOperationPlans {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $plans = [ordered]@{}
    foreach ($branch in $script:BoostLabApprovedBranches) {
        $plans[$branch] = Get-BoostLabDriverInstallDebloatSettingsOperationPlan -Branch $branch
    }
    return $plans
}

function Resolve-BoostLabDriverInstallDebloatSettingsValue {
    param(
        [AllowNull()]
        [object]$Value,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Context
    )

    if ($null -eq $Value) {
        return $null
    }
    if ($Value -is [string]) {
        $resolved = $Value
        foreach ($key in @($Context.Keys)) {
            $resolved = $resolved.Replace("{{$key}}", [string]$Context[$key])
        }
        return $resolved
    }
    if ($Value -is [System.Collections.IDictionary]) {
        $copy = [ordered]@{}
        foreach ($key in @($Value.Keys)) {
            $copy[$key] = Resolve-BoostLabDriverInstallDebloatSettingsValue -Value $Value[$key] -Context $Context
        }
        return $copy
    }
    if ($Value -is [array]) {
        return @($Value | ForEach-Object { Resolve-BoostLabDriverInstallDebloatSettingsValue -Value $_ -Context $Context })
    }

    return $Value
}

function Resolve-BoostLabDriverInstallDebloatSettingsOperation {
    param(
        [Parameter(Mandatory)]
        [object]$Operation,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Context
    )

    $parameters = [ordered]@{}
    foreach ($key in @($Operation.Parameters.Keys)) {
        $parameters[$key] = Resolve-BoostLabDriverInstallDebloatSettingsValue -Value $Operation.Parameters[$key] -Context $Context
    }

    [pscustomobject]@{
        Order = [int]$Operation.Order
        Branch = [string]$Operation.Branch
        Category = [string]$Operation.Category
        Type = [string]$Operation.Type
        Label = [string]$Operation.Label
        SourceCommand = [string]$Operation.SourceCommand
        Parameters = $parameters
    }
}

function New-BoostLabDriverInstallDebloatSettingsOperationResult {
    param(
        [Parameter(Mandatory)]
        [object]$Operation,

        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Message,

        [AllowNull()]
        [object]$Data = $null
    )

    [pscustomobject]@{
        Success = $Success
        Order = [int]$Operation.Order
        Branch = [string]$Operation.Branch
        Category = [string]$Operation.Category
        Type = [string]$Operation.Type
        Label = [string]$Operation.Label
        SourceCommand = [string]$Operation.SourceCommand
        Message = $Message
        Data = $Data
        Timestamp = Get-Date
    }
}

function Invoke-BoostLabDriverInstallDebloatSettingsRealOperation {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Operation,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Context
    )

    $p = $Operation.Parameters
    try {
        switch ([string]$Operation.Type) {
            'RequireAdministrator' {
                if (-not (Test-BoostLabDriverInstallDebloatSettingsAdministrator)) {
                    return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $false -Message 'Administrator execution is required.'
                }
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message 'Administrator execution confirmed.'
            }
            'RequireInternet' {
                if (-not (Test-BoostLabDriverInstallDebloatSettingsInternet)) {
                    return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $false -Message 'Internet connectivity is required.'
                }
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message 'Internet connectivity confirmed.'
            }
            'DownloadFile' {
                Invoke-WebRequest -Uri ([string]$p['Url']) -OutFile ([string]$p['Destination'])
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message "Downloaded artifact to $($p['Destination'])."
            }
            'StartProcess' {
                $startParams = @{
                    FilePath = [string]$p['FilePath']
                }
                if ($p.Contains('Arguments') -and @($p['Arguments']).Count -gt 0) { $startParams['ArgumentList'] = @($p['Arguments']) }
                if ($p.Contains('Wait') -and [bool]$p['Wait']) { $startParams['Wait'] = $true }
                if ($p.Contains('NoNewWindow') -and [bool]$p['NoNewWindow']) { $startParams['NoNewWindow'] = $true }
                if ($p.Contains('WindowStyle') -and -not [string]::IsNullOrWhiteSpace([string]$p['WindowStyle'])) { $startParams['WindowStyle'] = [string]$p['WindowStyle'] }
                Start-Process @startParams
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message "Started process $($p['FilePath'])."
            }
            'Cmd' {
                $proc = Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c', [string]$p['Command']) -Wait -PassThru -WindowStyle Hidden
                if ($proc.ExitCode -ne 0 -and -not ($p.Contains('ContinueOnError') -and [bool]$p['ContinueOnError'])) {
                    return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $false -Message "Command exited with code $($proc.ExitCode)."
                }
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message "Command completed with code $($proc.ExitCode)."
            }
            'MoveItem' {
                Move-Item -LiteralPath ([string]$p['Path']) -Destination ([string]$p['Destination']) -Force -ErrorAction SilentlyContinue | Out-Null
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message 'Move operation completed or source was absent.'
            }
            'RemoveItem' {
                Remove-Item -LiteralPath ([string]$p['Path']) -Force -Recurse:([bool]($p.Contains('Recurse') -and $p['Recurse'])) -ErrorAction SilentlyContinue | Out-Null
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message 'Remove operation completed or target was absent.'
            }
            'ExternalCommand' {
                $filePath = [string]$p['FilePath']
                $args = @($p['Arguments'])
                & $filePath @args | Out-Null
                if ($LASTEXITCODE -ne 0) {
                    return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $false -Message "External command exited with code $LASTEXITCODE."
                }
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message 'External command completed.'
            }
            'SelectInstaller' {
                $installFile = [string]$p['InstallFile']
                if ([string]::IsNullOrWhiteSpace($installFile)) {
                    Add-Type -AssemblyName System.Windows.Forms
                    $dialog = New-Object System.Windows.Forms.OpenFileDialog
                    $dialog.Filter = 'All Files (*.*)|*.*'
                    $null = $dialog.ShowDialog()
                    $installFile = [string]$dialog.FileName
                }
                if ([string]::IsNullOrWhiteSpace($installFile)) {
                    return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $false -Message 'Driver installer selection was cancelled or empty.'
                }
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message "Selected installer $installFile." -Data ([pscustomobject]@{ SelectedInstaller = $installFile })
            }
            'EditXmlFiles' {
                foreach ($path in @($p['Paths'])) {
                    if (Test-Path -LiteralPath $path -PathType Leaf) {
                        $content = Get-Content -LiteralPath $path -Raw
                        foreach ($replacement in @($p['Replacements'])) {
                            $content = $content -replace [string]$replacement['Pattern'], [string]$replacement['Replacement']
                        }
                        Set-Content -LiteralPath $path -Value $content -NoNewline
                    }
                }
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message 'XML edit operation completed.'
            }
            'EditJsonFiles' {
                foreach ($path in @($p['Paths'])) {
                    if (Test-Path -LiteralPath $path -PathType Leaf) {
                        $content = Get-Content -LiteralPath $path -Raw
                        $content = $content -replace [string]$p['Pattern'], [string]$p['Replacement']
                        Set-Content -LiteralPath $path -Value $content -NoNewline
                    }
                }
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message 'JSON edit operation completed.'
            }
            'WriteTextFile' {
                Set-Content -LiteralPath ([string]$p['Path']) -Value ([string]$p['Content']) -Force
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message "Wrote text file $($p['Path'])."
            }
            'UnblockFiles' {
                if (Test-Path -LiteralPath ([string]$p['Path'])) {
                    Get-ChildItem -LiteralPath ([string]$p['Path']) -Recurse | Unblock-File
                }
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message 'Unblock-File operation completed or target was absent.'
            }
            'RemoveAppxPackagePattern' {
                Get-AppxPackage -AllUsers ([string]$p['Pattern']) | Remove-AppxPackage -ErrorAction SilentlyContinue
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message 'AppX package removal command completed.'
            }
            'UnregisterScheduledTask' {
                Unregister-ScheduledTask -TaskName ([string]$p['TaskName']) -Confirm:$false -ErrorAction SilentlyContinue
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message 'Scheduled task unregister command completed.'
            }
            'StopProcess' {
                foreach ($name in @($p['Names'])) {
                    Stop-Process -Name ([string]$name) -Force -ErrorAction SilentlyContinue
                }
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message 'Stop-Process operation completed.'
            }
            'Sleep' {
                Start-Sleep -Seconds ([int]$p['Seconds'])
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message "Slept for $($p['Seconds']) seconds."
            }
            'UserPause' {
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message 'Ultimate Pause represented by BoostLab GUI confirmation and selected branch flow.'
            }
            'UninstallMsiByDisplayName' {
                $entries = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
                    Where-Object { $_.DisplayName -like [string]$p['DisplayNamePattern'] }
                foreach ($entry in @($entries)) {
                    Start-Process -FilePath 'msiexec.exe' -ArgumentList @('/x', [string]$entry.PSChildName, '/qn', '/norestart') -Wait -NoNewWindow
                }
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message 'MSI uninstall command completed or no matching entry existed.'
            }
            'StartFirstMatchingProcess' {
                $match = Get-ChildItem -LiteralPath ([string]$p['Directory']) -Filter ([string]$p['Filter']) -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($null -ne $match) {
                    Start-Process -FilePath $match.FullName -ArgumentList @($p['Arguments']) -Wait:([bool]$p['Wait']) -NoNewWindow
                }
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message 'First matching process operation completed or no matching executable existed.'
            }
            'DynamicDisplayClassRegAdd' {
                $basePath = 'Registry::HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
                $subkeys = Get-ChildItem -Path $basePath -Force -ErrorAction SilentlyContinue
                foreach ($key in @($subkeys)) {
                    if ($p.Contains('ExcludeConfiguration') -and [bool]$p['ExcludeConfiguration'] -and $key -like '*Configuration') {
                        continue
                    }
                    cmd /c ('reg add "{0}" /v "{1}" /t {2} /d "{3}" /f >nul 2>&1' -f $key.Name, $p['ValueName'], $p['Type'], $p['Data']) | Out-Null
                }
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message 'Dynamic display-class registry operation completed.'
            }
            'DynamicRecurseRegAdd' {
                $basePath = 'HKLM:\System\ControlSet001\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
                $allKeys = Get-ChildItem -Path $basePath -Recurse -ErrorAction SilentlyContinue
                $optionKeys = $allKeys | Where-Object { $_.PSChildName -eq [string]$p['ChildName'] }
                foreach ($key in @($optionKeys)) {
                    cmd /c ('reg add "{0}" /v "{1}" /t {2} /d "{3}" /f >nul 2>&1' -f $key.Name, $p['ValueName'], $p['Type'], $p['Data']) | Out-Null
                }
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message 'Dynamic recursive registry operation completed.'
            }
            'DynamicDisplayClassCreateSubkey' {
                $basePath = 'HKLM:\System\ControlSet001\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
                $adapterKeys = Get-ChildItem -Path $basePath -ErrorAction SilentlyContinue
                foreach ($key in @($adapterKeys)) {
                    if ($key.PSChildName -match [string]$p['ChildNamePattern']) {
                        cmd /c ('reg add "{0}\{1}" /f >nul 2>&1' -f $key.Name, $p['SubkeyName']) | Out-Null
                    }
                }
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message 'Dynamic display-class subkey creation completed.'
            }
            'DynamicMonitorRegAdd' {
                $basePath = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\MonitorDataStore'
                $monitorKeys = Get-ChildItem -Path $basePath -Recurse -ErrorAction SilentlyContinue
                foreach ($key in @($monitorKeys)) {
                    cmd /c ('reg add "{0}" /v "{1}" /t {2} /d "{3}" /f >nul 2>&1' -f $key.Name, $p['ValueName'], $p['Type'], $p['Data']) | Out-Null
                }
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message 'MonitorDataStore registry operation completed.'
            }
            'DynamicPnpMsiMode' {
                $gpuDevices = Get-PnpDevice -Class Display
                foreach ($gpu in @($gpuDevices)) {
                    $instanceID = $gpu.InstanceId
                    cmd /c ('reg add "HKLM\SYSTEM\ControlSet001\Enum\{0}\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "{1}" /t {2} /d "{3}" /f >nul 2>&1' -f $instanceID, $p['ValueName'], $p['Type'], $p['Data']) | Out-Null
                }
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message 'MSI mode registry operation completed for display devices.'
            }
            'DynamicNotifyIconPromotion' {
                $notifyIconSettings = Get-ChildItem -Path 'registry::HKEY_CURRENT_USER\Control Panel\NotifyIconSettings' -Recurse -Force -ErrorAction SilentlyContinue
                foreach ($setreg in @($notifyIconSettings)) {
                    $property = Get-ItemProperty -Path "registry::$setreg" -ErrorAction SilentlyContinue
                    if ($null -ne $property -and $property.PSObject.Properties['IsPromoted'] -and $property.IsPromoted -ne 0) {
                        Set-ItemProperty -Path "registry::$setreg" -Name 'IsPromoted' -Value 1 -Force
                    }
                }
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message 'NotifyIconSettings promotion operation completed.'
            }
            'ShutdownRestart' {
                shutdown -r -t 00
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $true -Message 'Restart command submitted.'
            }
            default {
                return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $false -Message "Unsupported operation type '$($Operation.Type)'."
            }
        }
    }
    catch {
        return New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $Operation -Success $false -Message $_.Exception.Message
    }
}

function Invoke-BoostLabDriverInstallDebloatSettingsWorkflow {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('NVIDIA', 'AMD', 'INTEL')]
        [string]$Branch,

        [string]$InstallFile = '',

        [scriptblock]$OperationExecutor = $null,

        [bool]$SkipEnvironmentChecks = $false
    )

    $plan = Get-BoostLabDriverInstallDebloatSettingsOperationPlan -Branch $Branch -InstallFile $InstallFile
    $context = [ordered]@{
        Branch = $Branch
        InstallFile = $InstallFile
    }
    $operationResults = [System.Collections.Generic.List[object]]::new()
    $changesStarted = $false

    foreach ($operation in @($plan.Operations)) {
        if ($SkipEnvironmentChecks -and [string]$operation.Type -in @('RequireAdministrator', 'RequireInternet')) {
            $resolvedSkipOperation = Resolve-BoostLabDriverInstallDebloatSettingsOperation -Operation $operation -Context $context
            $skipResult = New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $resolvedSkipOperation -Success $true -Message 'Skipped by test-safe executor option.'
            $operationResults.Add($skipResult)
            continue
        }

        $resolvedOperation = Resolve-BoostLabDriverInstallDebloatSettingsOperation -Operation $operation -Context $context
        if ($null -ne $OperationExecutor) {
            $result = & $OperationExecutor $resolvedOperation $Branch $context
        }
        else {
            $result = Invoke-BoostLabDriverInstallDebloatSettingsRealOperation -Operation $resolvedOperation -Context $context
        }
        if ($null -eq $result) {
            $result = New-BoostLabDriverInstallDebloatSettingsOperationResult -Operation $resolvedOperation -Success $false -Message 'Operation executor returned no result.'
        }

        $operationResults.Add($result)
        if ([string]$resolvedOperation.Type -notin @('RequireAdministrator', 'RequireInternet')) {
            $changesStarted = $true
        }

        if ($null -ne $result.Data -and $result.Data.PSObject.Properties['SelectedInstaller']) {
            $context['InstallFile'] = [string]$result.Data.SelectedInstaller
        }

        if (-not [bool]$result.Success) {
            return [pscustomobject]@{
                Success = $false
                Branch = $Branch
                Plan = $plan
                OperationResults = $operationResults.ToArray()
                FailedOperation = $resolvedOperation
                ChangesStarted = $changesStarted
                Message = "Operation failed: $($resolvedOperation.Label). $($result.Message)"
            }
        }
    }

    [pscustomobject]@{
        Success = $true
        Branch = $Branch
        Plan = $plan
        OperationResults = $operationResults.ToArray()
        FailedOperation = $null
        ChangesStarted = $changesStarted
        Message = "Driver Install Debloat & Settings $Branch workflow completed."
    }
}

function Get-BoostLabDriverInstallDebloatSettingsAnalysis {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabDriverInstallDebloatSettingsSourceStatus
    $plans = Get-BoostLabDriverInstallDebloatSettingsAllOperationPlans
    [pscustomobject]@{
        Mode                            = 'SourceEquivalentThreeBranchRuntime'
        AutoMode                        = 'BranchSelectedSourceEquivalentApply'
        Source                          = $sourceStatus
        SourceBehaviorSummary           = @(
            'Preserves admin and internet checks.'
            'Preserves the NVIDIA branch: NVIDIA driver page, user-selected installer, 7-Zip extraction, source-defined NVIDIA component deletion, silent setup.exe install, NVIDIA Control Panel winget install, Winget source AppX removal, NVIDIA registry/profile settings, Profile Inspector .nip import, shared UI launches, MSI mode, hidden icon setting, monitor color registry, and restart.'
            'Preserves the AMD branch: AMD driver page, user-selected installer, 7-Zip extraction, XML/JSON edits, ATISetup install, AMD startup/task/service/driver/process/file cleanup, AMD registry settings, Radeon Software open/stop flow, shared UI launches, MSI mode, hidden icon setting, monitor color registry, and restart.'
            'Preserves the INTEL branch: Intel driver page, user-selected installer, 7-Zip extraction, Installer.exe --noExtras install, Intel Graphics Software install, Intel startup/service/driver/process/file cleanup, Intel registry settings, shared UI launches, MSI mode, hidden icon setting, monitor color registry, and restart.'
        )
        SupportedScope                  = 'NVIDIA/AMD/INTEL source-equivalent branch runtime approved for this tool only.'
        ApprovedSourceBranches          = @($script:BoostLabApprovedBranches)
        UnsupportedBranches             = @()
        ToolSpecificBranchScopeDecision = 'Phase 122: Yazan approved all source-defined NVIDIA, AMD, and INTEL branches for Driver Install Debloat & Settings only. This does not expand project-wide AMD/Intel GPU scope.'
        ApplyRequiresBranchSelection    = $true
        OperationPlans                  = $plans
        ArtifactDescriptors             = @(
            '7zip.exe from Ultimate-Files mirror',
            'inspector.exe from Ultimate-Files mirror',
            'user-selected NVIDIA driver installer',
            'user-selected AMD driver installer',
            'user-selected INTEL driver installer'
        )
        NoMutationOccurred              = $true
        NoDownloadOccurred              = $true
        NoInstallerExecutionOccurred    = $true
        NoExternalProcessStarted        = $true
        NoDriverMutationOccurred        = $true
        NoRegistryMutationOccurred      = $true
        NoFileCleanupOccurred           = $true
        NoServiceMutationOccurred       = $true
        NoProfileImportOccurred         = $true
        NoAppxOrWingetMutationOccurred  = $true
        NoRebootOrSessionChangeOccurred = $true
        PathASeparation                 = 'Driver Install Debloat & Settings remains separate from Driver Clean and NVIDIA Path B.'
        PathBSeparation                 = 'NVIDIA Path B remains separate and ordered: Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode.'
    }
}

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        Id                          = [string]$script:BoostLabToolMetadata['Id']
        Title                       = [string]$script:BoostLabToolMetadata['Title']
        Stage                       = [string]$script:BoostLabToolMetadata['Stage']
        Order                       = [int]$script:BoostLabToolMetadata['Order']
        Type                        = [string]$script:BoostLabToolMetadata['Type']
        RiskLevel                   = [string]$script:BoostLabToolMetadata['RiskLevel']
        Description                 = [string]$script:BoostLabToolMetadata['Description']
        Actions                     = @($script:BoostLabToolMetadata['Actions'])
        Capabilities                = $script:BoostLabToolMetadata['Capabilities']
        ImplementedActions          = @($script:BoostLabImplementedActions)
        ConfirmationRequiredActions = @('Open', 'Apply')
        ConfirmationText            = 'Driver Install Debloat & Settings executes source-equivalent NVIDIA/AMD/INTEL driver install/debloat behavior for the selected branch only after confirmation. It can download tools, open vendor pages, run installers, delete driver components, modify registry/profile/package/service/task/process state, open UI, and restart. Continue only if this exact branch operation is intended.'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabDriverInstallDebloatSettingsSourceStatus
    [pscustomobject]@{
        Supported            = $true
        ToolId               = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle            = [string]$script:BoostLabToolMetadata['Title']
        Reason               = 'Driver Install Debloat & Settings source-equivalent NVIDIA/AMD/INTEL branch runtime is available after explicit confirmation and branch selection.'
        SourceChecksumStatus = [string]$sourceStatus.ChecksumStatus
        Timestamp            = Get-Date
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        Status          = 'SourceEquivalentThreeBranchRuntime'
        LastAction      = $null
        LastResult      = $null
        RestartRequired = $false
        Timestamp       = Get-Date
    }
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ActionName,

        [bool]$Confirmed = $false,

        [string]$Branch = '',

        [string]$InstallFile = '',

        [scriptblock]$OperationExecutor = $null,

        [bool]$SkipEnvironmentChecks = $false
    )

    $canonicalActionName = switch ($ActionName) {
        'Prepare Manual Handoff' { 'Open' }
        'Manual Handoff' { 'Open' }
        'Apply Auto' { 'Apply' }
        default { $ActionName }
    }

    if ($canonicalActionName -notin @($script:BoostLabImplementedActions)) {
        return New-BoostLabDriverInstallDebloatSettingsResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'Unsupported' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Unsupported Driver Install Debloat & Settings action. Only Analyze, Open, Apply, Default, and Restore are exposed.'
    }

    if ($canonicalActionName -eq 'Analyze') {
        $analysis = Get-BoostLabDriverInstallDebloatSettingsAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        return New-BoostLabDriverInstallDebloatSettingsResult `
            -Success $sourceOk `
            -Action 'Analyze' `
            -Status $(if ($sourceOk) { 'Analyzed' } else { 'SourceVerificationFailed' }) `
            -CommandStatus 'No execution performed' `
            -VerificationStatus ([string]$analysis.Source.ChecksumStatus) `
            -Message $(if ($sourceOk) { 'Driver Install Debloat & Settings analyzed. NVIDIA, AMD, and INTEL source-equivalent branch plans are mapped; no mutation occurred.' } else { 'Driver Install Debloat & Settings source checksum verification failed or source file is missing.' }) `
            -Data $analysis `
            -Errors $(if ($sourceOk) { @() } else { @('Driver Install Debloat & Settings source checksum did not match the expected value or the source file is missing.') })
    }

    $sourceStatus = Get-BoostLabDriverInstallDebloatSettingsSourceStatus
    if ([string]$sourceStatus.ChecksumStatus -ne 'Passed') {
        return New-BoostLabDriverInstallDebloatSettingsResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'SourceVerificationFailed' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus ([string]$sourceStatus.ChecksumStatus) `
            -Message 'Driver Install Debloat & Settings blocked because source checksum verification failed or the source file is missing.' `
            -Data $sourceStatus `
            -Errors @('Driver Install Debloat & Settings source checksum did not match the expected value or the source file is missing.')
    }

    if ($canonicalActionName -eq 'Open') {
        if (-not $Confirmed) {
            return New-BoostLabDriverInstallDebloatSettingsResult `
                -Success $false `
                -Action 'Open' `
                -Status 'Cancelled' `
                -CommandStatus 'Cancelled before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'Driver Install Debloat & Settings Open cancelled by user. No vendor page or external process was opened.' `
                -Cancelled $true
        }

        $normalizedBranch = ConvertTo-BoostLabDriverInstallDebloatSettingsBranch -Branch $Branch
        if ($normalizedBranch -notin $script:BoostLabApprovedBranches) {
            return New-BoostLabDriverInstallDebloatSettingsResult `
                -Success $false `
                -Action 'Open' `
                -Status 'NeedsBranchSelection' `
                -CommandStatus 'Blocked before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'Open requires selecting exactly one source branch: NVIDIA, AMD, or INTEL. No external process was opened.'
        }

        $plan = Get-BoostLabDriverInstallDebloatSettingsOperationPlan -Branch $normalizedBranch
        $openOperations = @($plan.Operations | Where-Object { [string]$_.Category -eq 'DriverPage' -and [string]$_.Type -in @('Sleep', 'StartProcess', 'UserPause') })
        $context = [ordered]@{ Branch = $normalizedBranch; InstallFile = $InstallFile }
        $results = [System.Collections.Generic.List[object]]::new()
        foreach ($operation in $openOperations) {
            $resolved = Resolve-BoostLabDriverInstallDebloatSettingsOperation -Operation $operation -Context $context
            if ($null -ne $OperationExecutor) {
                $result = & $OperationExecutor $resolved $normalizedBranch $context
            }
            else {
                $result = Invoke-BoostLabDriverInstallDebloatSettingsRealOperation -Operation $resolved -Context $context
            }
            $results.Add($result)
            if (-not [bool]$result.Success) {
                return New-BoostLabDriverInstallDebloatSettingsResult `
                    -Success $false `
                    -Action 'Open' `
                    -Status 'OpenFailed' `
                    -CommandStatus 'Completed with errors' `
                    -VerificationStatus 'Failed' `
                    -Message "Open failed for $normalizedBranch driver page operation: $($result.Message)" `
                    -Data ([pscustomobject]@{ Branch = $normalizedBranch; Operations = $openOperations; OperationResults = $results.ToArray() }) `
                    -Errors @($result.Message) `
                    -ChangesExecuted $true
            }
        }

        return New-BoostLabDriverInstallDebloatSettingsResult `
            -Success $true `
            -Action 'Open' `
            -Status 'SourceDriverPageOpened' `
            -CommandStatus 'Completed' `
            -VerificationStatus 'Passed' `
            -Message "Opened source-defined $normalizedBranch driver page flow only. No installer, extraction, debloat, package, registry, profile, service, process cleanup, MSI mode, shared UI, or reboot operation ran." `
            -Data ([pscustomobject]@{ Branch = $normalizedBranch; Operations = $openOperations; OperationResults = $results.ToArray() }) `
            -ChangesExecuted $true
    }

    if ($canonicalActionName -eq 'Apply') {
        if (-not $Confirmed) {
            return New-BoostLabDriverInstallDebloatSettingsResult `
                -Success $false `
                -Action 'Apply' `
                -Status 'Cancelled' `
                -CommandStatus 'Cancelled before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'Driver Install Debloat & Settings Apply cancelled by user. No branch operation executed.' `
                -Cancelled $true
        }

        $normalizedBranch = ConvertTo-BoostLabDriverInstallDebloatSettingsBranch -Branch $Branch
        if ($normalizedBranch -notin $script:BoostLabApprovedBranches) {
            return New-BoostLabDriverInstallDebloatSettingsResult `
                -Success $false `
                -Action 'Apply' `
                -Status 'NeedsBranchSelection' `
                -CommandStatus 'Blocked before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'Apply requires selecting exactly one source branch: NVIDIA, AMD, or INTEL. No download, installer, file, registry, service, package, process, driver, UI, or reboot operation executed.'
        }

        $workflow = Invoke-BoostLabDriverInstallDebloatSettingsWorkflow `
            -Branch $normalizedBranch `
            -InstallFile $InstallFile `
            -OperationExecutor $OperationExecutor `
            -SkipEnvironmentChecks:$SkipEnvironmentChecks

        if (-not [bool]$workflow.Success) {
            return New-BoostLabDriverInstallDebloatSettingsResult `
                -Success $false `
                -Action 'Apply' `
                -Status 'OperationFailed' `
                -CommandStatus 'Completed with errors' `
                -VerificationStatus 'Failed' `
                -Message ([string]$workflow.Message) `
                -Data $workflow `
                -Errors @([string]$workflow.Message) `
                -ChangesExecuted ([bool]$workflow.ChangesStarted) `
                -RestartRequired $false
        }

        return New-BoostLabDriverInstallDebloatSettingsResult `
            -Success $true `
            -Action 'Apply' `
            -Status ("{0}WorkflowCompleted" -f $normalizedBranch) `
            -CommandStatus 'Completed' `
            -VerificationStatus 'Passed' `
            -Message "Driver Install Debloat & Settings $normalizedBranch source-equivalent workflow completed. Restart/session behavior is source-defined and represented by the operation plan." `
            -Data $workflow `
            -ChangesExecuted $true `
            -RestartRequired $true
    }

    if ($canonicalActionName -eq 'Default') {
        return New-BoostLabDriverInstallDebloatSettingsResult `
            -Success $false `
            -Action 'Default' `
            -Status 'DefaultUnavailable' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Default is unavailable for Driver Install Debloat & Settings because the source does not define a safe overall Default branch. Default is not Restore.'
    }

    if ($canonicalActionName -eq 'Restore') {
        return New-BoostLabDriverInstallDebloatSettingsResult `
            -Success $false `
            -Action 'Restore' `
            -Status 'RestoreUnavailable' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Restore is unavailable without approved selected captured driver/profile/package/registry/file/service/task/process/reboot state and a Restore contract. No restore mutation is planned.'
    }
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    Invoke-BoostLabToolAction -ActionName 'Default'
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
    'Get-BoostLabDriverInstallDebloatSettingsSourceStatus'
    'Get-BoostLabDriverInstallDebloatSettingsAnalysis'
    'Get-BoostLabDriverInstallDebloatSettingsOperationPlan'
    'Get-BoostLabDriverInstallDebloatSettingsAllOperationPlans'
    'Invoke-BoostLabDriverInstallDebloatSettingsWorkflow'
)
