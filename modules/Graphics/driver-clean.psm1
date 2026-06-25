Set-StrictMode -Version Latest

$coreRoot = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core'
if (-not (Get-Command -Name 'New-BoostLabRegistryStateCapture' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path $coreRoot 'StateCapture.psm1') -Scope Local -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'driver-clean'
    Title = 'Driver Clean'
    Stage = 'Graphics'
    Order = 1
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Source-equivalent Driver Clean workflow. Analyze is read-only; Apply runs the Ultimate DDU Auto branch after confirmation; Open runs the Ultimate DDU Manual branch after confirmation.'
    Actions = @('Analyze', 'Open', 'Apply')
    Capabilities = [ordered]@{
        RequiresAdmin = $true
        RequiresInternet = $true
        CanReboot = $true
        CanModifyRegistry = $true
        CanModifyServices = $false
        CanInstallSoftware = $true
        CanDownload = $true
        CanModifyDrivers = $true
        CanModifySecurity = $false
        CanDeleteFiles = $true
        UsesTrustedInstaller = $false
        UsesSafeMode = $true
        SupportsDefault = $false
        SupportsRestore = $false
        NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Analyze', 'Open', 'Apply')
$script:BoostLabExpectedSourceHash = 'CF9E1C55ACAFD8A52D2200AC3E6C3AFDF9823837C7B68101C2D4B83E074D325A'
$script:BoostLabExpectedCanonicalSourceHash = 'CF9E1C55ACAFD8A52D2200AC3E6C3AFDF9823837C7B68101C2D4B83E074D325A'
$script:BoostLabSourceRelativePath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/1 Driver Clean.ps1'

$script:BoostLabSevenZipUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe'
$script:BoostLabDduUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/ddu.exe'
$script:BoostLabDriverSearchRegistryPath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\DriverSearching'
$script:BoostLabDriverSearchValueName = 'SearchOrderConfig'
$script:BoostLabDriverSearchValue = 0

function Invoke-BoostLabDriverCleanVerifiedArtifactDownload {
    param(
        [Parameter(Mandatory)]
        [string]$ArtifactId,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    if (-not (Get-Command -Name 'Invoke-BoostLabVerifiedArtifactDownload' -ErrorAction SilentlyContinue)) {
        Import-Module -Name (Join-Path $coreRoot 'DownloadProvenance.psm1') -Scope Local -Force -ErrorAction Stop
    }

    Invoke-BoostLabVerifiedArtifactDownload -ArtifactId $ArtifactId -Destination $Destination
}

function Get-BoostLabDriverCleanSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $projectRoot ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabDriverCleanSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabDriverCleanSourcePath
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $sourceVerificationModulePath = Join-Path $projectRoot 'core\SourceVerification.psm1'
    if (-not (Get-Command -Name 'Test-BoostLabSourceChecksum' -ErrorAction SilentlyContinue)) {
        Import-Module -Name $sourceVerificationModulePath -Scope Local -Force -ErrorAction Stop
    }

    $verification = Test-BoostLabSourceChecksum -LiteralPath $sourcePath -ExpectedSha256 $script:BoostLabExpectedSourceHash -ExpectedCanonicalSha256 $script:BoostLabExpectedCanonicalSourceHash

    [pscustomobject]@{
        SourcePath                = $sourcePath
        SourceRelativePath        = $script:BoostLabSourceRelativePath
        Exists                    = [bool]$verification.Exists
        ExpectedSha256            = $script:BoostLabExpectedSourceHash
        DetectedSha256            = [string]$verification.DetectedSha256
        ExpectedCanonicalSha256   = $script:BoostLabExpectedCanonicalSourceHash
        DetectedCanonicalSha256   = [string]$verification.DetectedCanonicalSha256
        ChecksumStatus            = [string]$verification.ChecksumStatus
        RawChecksumStatus         = [string]$verification.RawChecksumStatus
        CanonicalChecksumStatus   = [string]$verification.CanonicalChecksumStatus
        VerificationMode          = [string]$verification.VerificationMode
    }
}

function Test-BoostLabDriverCleanAdministrator {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function Test-BoostLabDriverCleanInternet {
    try {
        return [bool](Test-Connection -ComputerName '8.8.8.8' -Count 1 -Quiet -ErrorAction SilentlyContinue)
    }
    catch {
        return $false
    }
}

function Get-BoostLabDriverCleanResolvedPaths {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $systemRoot = if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) { 'C:\Windows' } else { [string]$env:SystemRoot }
    $systemDrive = if ([string]::IsNullOrWhiteSpace($env:SystemDrive)) { 'C:' } else { [string]$env:SystemDrive }
    $programData = if ([string]::IsNullOrWhiteSpace($env:ProgramData)) { 'C:\ProgramData' } else { [string]$env:ProgramData }

    return [pscustomobject]@{
        SystemRoot = $systemRoot
        SystemDrive = $systemDrive
        ProgramData = $programData
        SevenZipInstaller = Join-Path $systemRoot 'Temp\7zip.exe'
        DduArchive = Join-Path $systemRoot 'Temp\ddu.exe'
        DduExtractRoot = Join-Path $systemRoot 'Temp\ddu'
        DduSettingsXml = Join-Path $systemRoot 'Temp\ddu\Settings\Settings.xml'
        DduAutoScript = Join-Path $systemRoot 'Temp\ddu.ps1'
        DduManualScript = Join-Path $systemRoot 'Temp\ddumanual.ps1'
        DduExecutable = Join-Path $systemRoot 'Temp\ddu\Display Driver Uninstaller.exe'
        SevenZipExecutable = Join-Path $systemDrive 'Program Files\7-Zip\7z.exe'
        SevenZipShortcut = Join-Path $programData 'Microsoft\Windows\Start Menu\Programs\7-Zip\7-Zip File Manager.lnk'
        StartMenuPrograms = Join-Path $programData 'Microsoft\Windows\Start Menu\Programs'
        SevenZipStartMenuFolder = Join-Path $programData 'Microsoft\Windows\Start Menu\Programs\7-Zip'
    }
}

function Get-BoostLabDriverCleanDduConfigXml {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return @'
<?xml version="1.0" encoding="utf-8"?>
<DisplayDriverUninstaller Version="18.1.4.2">
	<Settings>
		<SelectedLanguage>en-US</SelectedLanguage>
		<RemoveMonitors>True</RemoveMonitors>
		<RemoveCrimsonCache>True</RemoveCrimsonCache>
		<RemoveAMDDirs>True</RemoveAMDDirs>
		<RemoveAudioBus>True</RemoveAudioBus>
		<RemoveAMDKMPFD>True</RemoveAMDKMPFD>
		<RemoveNvidiaDirs>True</RemoveNvidiaDirs>
		<RemovePhysX>True</RemovePhysX>
		<Remove3DTVPlay>True</Remove3DTVPlay>
		<RemoveGFE>True</RemoveGFE>
		<RemoveNVBROADCAST>True</RemoveNVBROADCAST>
		<RemoveNVCP>True</RemoveNVCP>
		<RemoveINTELCP>True</RemoveINTELCP>
		<RemoveINTELIGS>True</RemoveINTELIGS>
		<RemoveOneAPI>True</RemoveOneAPI>
		<RemoveEnduranceGaming>True</RemoveEnduranceGaming>
		<RemoveIntelNpu>True</RemoveIntelNpu>
		<RemoveAMDCP>True</RemoveAMDCP>
		<UseRoamingConfig>False</UseRoamingConfig>
		<CheckUpdates>False</CheckUpdates>
		<CreateRestorePoint>False</CreateRestorePoint>
		<SaveLogs>False</SaveLogs>
		<RemoveVulkan>True</RemoveVulkan>
		<ShowOffer>False</ShowOffer>
		<EnableSafeModeDialog>False</EnableSafeModeDialog>
		<PreventWinUpdate>True</PreventWinUpdate>
		<UsedBCD>False</UsedBCD>
		<KeepNVCPopt>False</KeepNVCPopt>
		<RememberLastChoice>False</RememberLastChoice>
		<LastSelectedGPUIndex>0</LastSelectedGPUIndex>
		<LastSelectedTypeIndex>0</LastSelectedTypeIndex>
	</Settings>
</DisplayDriverUninstaller>
'@
}

function Get-BoostLabDriverCleanSafeModeScriptContent {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Auto', 'Manual')]
        [string]$Mode
    )

    if ($Mode -eq 'Auto') {
        return @'
        # SCRIPT RUN AS ADMIN
        If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
        {Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
        Exit}
        $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + " (Administrator)"
        $Host.UI.RawUI.BackgroundColor = "Black"
        $Host.PrivateData.ProgressBackgroundColor = "Black"
        $Host.PrivateData.ProgressForegroundColor = "White"
        Clear-Host

# remove safe mode boot
cmd /c "bcdedit /deletevalue {current} safeboot >nul 2>&1"

Write-Host "DDU & RESTARTING`n" -ForegroundColor Red

# uninstall soundblaster realtek intel amd nvidia drivers & restart
Start-Process "$env:SystemRoot\Temp\ddu\Display Driver Uninstaller.exe" -ArgumentList "-CleanSoundBlaster -CleanRealtek -CleanAllGpus -Restart" -Wait
'@
    }

    return @'
        # SCRIPT RUN AS ADMIN
        If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
        {Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
        Exit}
        $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + " (Administrator)"
        $Host.UI.RawUI.BackgroundColor = "Black"
        $Host.PrivateData.ProgressBackgroundColor = "Black"
        $Host.PrivateData.ProgressForegroundColor = "White"
        Clear-Host

# remove safe mode boot
cmd /c "bcdedit /deletevalue {current} safeboot >nul 2>&1"

Write-Host "DDU MANUAL`n"

# open ddu
Start-Process -Wait "$env:SystemRoot\Temp\ddu\Display Driver Uninstaller.exe"
'@
}

function New-BoostLabDriverCleanOperation {
    param(
        [Parameter(Mandatory)]
        [int]$Order,

        [Parameter(Mandatory)]
        [ValidateSet('DownloadFile', 'StartProcess', 'Cmd', 'MoveItem', 'RemoveItem', 'ExternalCommand', 'WriteTextFile', 'SetFileReadOnly', 'SetDriverSearchPolicy', 'Sleep', 'ShutdownRestart')]
        [string]$Type,

        [Parameter(Mandatory)]
        [string]$Label,

        [Parameter(Mandatory)]
        [string]$SourceCommand,

        [hashtable]$Parameters = @{}
    )

    return [pscustomobject]@{
        Order = $Order
        Type = $Type
        Label = $Label
        SourceCommand = $SourceCommand
        Parameters = [ordered]@{} + $Parameters
    }
}

function Get-BoostLabDriverCleanOperationPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Auto', 'Manual')]
        [string]$Mode
    )

    $paths = Get-BoostLabDriverCleanResolvedPaths
    $operations = [System.Collections.Generic.List[object]]::new()
    $order = 0

    $operations.Add((New-BoostLabDriverCleanOperation -Order (++$order) -Type DownloadFile -Label 'Download 7-Zip source artifact' -SourceCommand 'IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe" -OutFile "$env:SystemRoot\Temp\7zip.exe"' -Parameters @{
        Uri = $script:BoostLabSevenZipUrl
        OutFile = $paths.SevenZipInstaller
        ArtifactId = 'driver-clean-seven-zip'
    }))
    $operations.Add((New-BoostLabDriverCleanOperation -Order (++$order) -Type StartProcess -Label 'Install 7-Zip silently' -SourceCommand 'Start-Process -Wait "$env:SystemRoot\Temp\7zip.exe" -ArgumentList "/S"' -Parameters @{
        FilePath = $paths.SevenZipInstaller
        ArgumentList = '/S'
        Wait = $true
    }))
    $operations.Add((New-BoostLabDriverCleanOperation -Order (++$order) -Type Cmd -Label 'Configure 7-Zip context menu' -SourceCommand 'cmd /c "reg add `"HKEY_CURRENT_USER\Software\7-Zip\Options`" /v `"ContextMenu`" /t REG_DWORD /d `"259`" /f >nul 2>&1"' -Parameters @{
        CommandLine = 'reg add "HKEY_CURRENT_USER\Software\7-Zip\Options" /v "ContextMenu" /t REG_DWORD /d "259" /f >nul 2>&1'
    }))
    $operations.Add((New-BoostLabDriverCleanOperation -Order (++$order) -Type Cmd -Label 'Configure 7-Zip cascaded menu' -SourceCommand 'cmd /c "reg add `"HKEY_CURRENT_USER\Software\7-Zip\Options`" /v `"CascadedMenu`" /t REG_DWORD /d `"0`" /f >nul 2>&1"' -Parameters @{
        CommandLine = 'reg add "HKEY_CURRENT_USER\Software\7-Zip\Options" /v "CascadedMenu" /t REG_DWORD /d "0" /f >nul 2>&1'
    }))
    $operations.Add((New-BoostLabDriverCleanOperation -Order (++$order) -Type MoveItem -Label 'Move 7-Zip Start Menu shortcut' -SourceCommand 'Move-Item -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\7-Zip\7-Zip File Manager.lnk" -Destination "$env:ProgramData\Microsoft\Windows\Start Menu\Programs" -Force -ErrorAction SilentlyContinue | Out-Null' -Parameters @{
        Path = $paths.SevenZipShortcut
        Destination = $paths.StartMenuPrograms
    }))
    $operations.Add((New-BoostLabDriverCleanOperation -Order (++$order) -Type RemoveItem -Label 'Remove 7-Zip Start Menu folder' -SourceCommand 'Remove-Item "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\7-Zip" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null' -Parameters @{
        Path = $paths.SevenZipStartMenuFolder
        Recurse = $true
    }))
    $operations.Add((New-BoostLabDriverCleanOperation -Order (++$order) -Type DownloadFile -Label 'Download DDU source artifact' -SourceCommand 'IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/ddu.exe" -OutFile "$env:SystemRoot\Temp\ddu.exe"' -Parameters @{
        Uri = $script:BoostLabDduUrl
        OutFile = $paths.DduArchive
        ArtifactId = 'driver-clean-ddu'
    }))
    $operations.Add((New-BoostLabDriverCleanOperation -Order (++$order) -Type ExternalCommand -Label 'Extract DDU with 7-Zip' -SourceCommand '& "$env:SystemDrive\Program Files\7-Zip\7z.exe" x "$env:SystemRoot\Temp\ddu.exe" -o"$env:SystemRoot\Temp\ddu" -y | Out-Null' -Parameters @{
        FilePath = $paths.SevenZipExecutable
        Arguments = @('x', $paths.DduArchive, ('-o{0}' -f $paths.DduExtractRoot), '-y')
    }))
    $operations.Add((New-BoostLabDriverCleanOperation -Order (++$order) -Type WriteTextFile -Label 'Write source-defined DDU Settings.xml' -SourceCommand 'Set-Content -Path "$env:SystemRoot\Temp\ddu\Settings\Settings.xml" -Value $DduConfig -Force' -Parameters @{
        Path = $paths.DduSettingsXml
        Content = Get-BoostLabDriverCleanDduConfigXml
    }))
    $operations.Add((New-BoostLabDriverCleanOperation -Order (++$order) -Type SetFileReadOnly -Label 'Set DDU Settings.xml read-only' -SourceCommand 'Set-ItemProperty -Path "$env:SystemRoot\Temp\ddu\Settings\Settings.xml" -Name IsReadOnly -Value $true' -Parameters @{
        Path = $paths.DduSettingsXml
        Name = 'IsReadOnly'
        Value = $true
    }))
    $operations.Add((New-BoostLabDriverCleanOperation -Order (++$order) -Type SetDriverSearchPolicy -Label 'Prevent Windows Update driver downloads' -SourceCommand 'cmd /c "reg add `"HKLM\Software\Microsoft\Windows\CurrentVersion\DriverSearching`" /v `"SearchOrderConfig`" /t REG_DWORD /d `"0`" /f >nul 2>&1"' -Parameters @{
        RegistryPath = $script:BoostLabDriverSearchRegistryPath
        ValueName = $script:BoostLabDriverSearchValueName
        ValueType = 'REG_DWORD'
        ValueData = $script:BoostLabDriverSearchValue
        CommandLine = 'reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d "0" /f >nul 2>&1'
        ScopeId = 'driver-clean-driver-search-policy'
    }))

    if ($Mode -eq 'Auto') {
        $operations.Add((New-BoostLabDriverCleanOperation -Order (++$order) -Type WriteTextFile -Label 'Create source-defined Auto DDU Safe Mode script' -SourceCommand 'Set-Content -Path "$env:SystemRoot\Temp\ddu.ps1" -Value $DDU -Force' -Parameters @{
            Path = $paths.DduAutoScript
            Content = Get-BoostLabDriverCleanSafeModeScriptContent -Mode Auto
        }))
        $operations.Add((New-BoostLabDriverCleanOperation -Order (++$order) -Type Cmd -Label 'Create Auto DDU RunOnce entry' -SourceCommand 'cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce`" /v `"*ddu`" /t REG_SZ /d `"powershell.exe -nop -ep bypass -WindowStyle Maximized -f $env:SystemRoot\Temp\ddu.ps1`" /f >nul 2>&1"' -Parameters @{
            CommandLine = ('reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "*ddu" /t REG_SZ /d "powershell.exe -nop -ep bypass -WindowStyle Maximized -f {0}" /f >nul 2>&1' -f $paths.DduAutoScript)
            RegistryPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
            ValueName = '*ddu'
        }))
    }
    else {
        $operations.Add((New-BoostLabDriverCleanOperation -Order (++$order) -Type WriteTextFile -Label 'Create source-defined Manual DDU Safe Mode script' -SourceCommand 'Set-Content -Path "$env:SystemRoot\Temp\ddumanual.ps1" -Value $DDU -Force' -Parameters @{
            Path = $paths.DduManualScript
            Content = Get-BoostLabDriverCleanSafeModeScriptContent -Mode Manual
        }))
        $operations.Add((New-BoostLabDriverCleanOperation -Order (++$order) -Type Cmd -Label 'Create Manual DDU RunOnce entry' -SourceCommand 'cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce`" /v `"*ddumanual`" /t REG_SZ /d `"powershell.exe -nop -ep bypass -WindowStyle Maximized -f $env:SystemRoot\Temp\ddumanual.ps1`" /f >nul 2>&1"' -Parameters @{
            CommandLine = ('reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "*ddumanual" /t REG_SZ /d "powershell.exe -nop -ep bypass -WindowStyle Maximized -f {0}" /f >nul 2>&1' -f $paths.DduManualScript)
            RegistryPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
            ValueName = '*ddumanual'
        }))
    }

    $operations.Add((New-BoostLabDriverCleanOperation -Order (++$order) -Type Cmd -Label 'Enable Safe Mode minimal boot' -SourceCommand 'cmd /c "bcdedit /set {current} safeboot minimal >nul 2>&1"' -Parameters @{
        CommandLine = 'bcdedit /set {current} safeboot minimal >nul 2>&1'
    }))
    $operations.Add((New-BoostLabDriverCleanOperation -Order (++$order) -Type Sleep -Label 'Wait before source-defined restart' -SourceCommand 'Start-Sleep -Seconds 5' -Parameters @{
        Seconds = 5
    }))
    $operations.Add((New-BoostLabDriverCleanOperation -Order (++$order) -Type ShutdownRestart -Label 'Restart into Safe Mode for DDU workflow' -SourceCommand 'shutdown -r -t 00' -Parameters @{
        Arguments = @('-r', '-t', '00')
    }))

    return [pscustomobject]@{
        Mode = $Mode
        OperationCount = $operations.Count
        Operations = $operations.ToArray()
        Downloads = @(
            [pscustomobject]@{ DisplayName = '7-Zip File Manager'; Uri = $script:BoostLabSevenZipUrl; OutFile = $paths.SevenZipInstaller }
            [pscustomobject]@{ DisplayName = 'Display Driver Uninstaller'; Uri = $script:BoostLabDduUrl; OutFile = $paths.DduArchive }
        )
        DduConfigPath = $paths.DduSettingsXml
        DriverSearchPolicy = [pscustomobject]@{
            RegistryPath = $script:BoostLabDriverSearchRegistryPath
            ValueName = $script:BoostLabDriverSearchValueName
            ValueType = 'REG_DWORD'
            ValueData = $script:BoostLabDriverSearchValue
        }
        AutoDduArguments = '-CleanSoundBlaster -CleanRealtek -CleanAllGpus -Restart'
        ManualDduLaunch = $paths.DduExecutable
        RestartRequired = $true
    }
}

function New-BoostLabDriverCleanCapturePolicy {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        SchemaVersion = '1.0'
        FileScopes = @()
        RegistryScopes = @(
            @{
                ScopeId = 'driver-clean-driver-search-policy'
                ToolIds = @('driver-clean')
                AllowedPath = $script:BoostLabDriverSearchRegistryPath
                AllowedValueNames = @($script:BoostLabDriverSearchValueName)
                AllowKeyCapture = $false
                AllowProtectedSystem = $true
            }
        )
        DeniedRegistryPrefixes = @()
    }
}

function New-BoostLabDriverCleanResult {
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

    return [pscustomobject]@{
        Success = $Success
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Action = $Action
        Status = $Status
        CommandStatus = $CommandStatus
        VerificationStatus = $VerificationStatus
        Message = $Message
        RestartRequired = $RestartRequired
        Cancelled = $Cancelled
        ChangesExecuted = $ChangesExecuted
        Timestamp = Get-Date
        Data = $Data
        Warnings = @($Warnings)
        Errors = @($Errors)
    }
}

function Get-BoostLabDriverCleanRiskWarnings {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    return @(
        'Driver Clean uses a Yazan-approved Driver Clean-specific DDU intake exception; standalone DDU remains deleted and unapproved.'
        'Apply and Open download source-defined 7-Zip and DDU artifacts, install/configure 7-Zip, configure DDU, create RunOnce, enable Safe Mode, and restart only after explicit confirmation.'
        'Default is unavailable because the source does not define a default branch; Restore remains unavailable without a selected captured-state restore contract.'
        'Driver Clean remains separate from NVIDIA Path B.'
    )
}

function Get-BoostLabDriverCleanAnalysis {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabDriverCleanSourceStatus
    return [pscustomobject]@{
        Mode = 'SourceEquivalentDriverClean'
        AutoMode = 'SourceEquivalentAutoAvailable'
        ManualMode = 'SourceEquivalentManualAvailable'
        Source = $sourceStatus
        SourceBehaviorSummary = 'Ultimate Driver Clean downloads and installs 7-Zip, downloads/extracts/configures DDU, sets Windows driver-search policy, writes a temp DDU script, creates a RunOnce entry, enables Safe Mode with bcdedit, waits five seconds, and restarts. Auto runs DDU with -CleanSoundBlaster -CleanRealtek -CleanAllGpus -Restart; Manual opens DDU interactively in Safe Mode.'
        ApplyPlan = Get-BoostLabDriverCleanOperationPlan -Mode Auto
        OpenPlan = Get-BoostLabDriverCleanOperationPlan -Mode Manual
        DriverSearchPolicy = [pscustomobject]@{
            RegistryPath = $script:BoostLabDriverSearchRegistryPath
            ValueName = $script:BoostLabDriverSearchValueName
            ValueType = 'REG_DWORD'
            ValueData = $script:BoostLabDriverSearchValue
        }
        NoMutationOccurred = $true
        NoDownloadOccurred = $true
        NoExternalProcessStarted = $true
        Warnings = @(Get-BoostLabDriverCleanRiskWarnings)
        GraphicsWorkflowRelationship = 'Driver Clean remains separate from Driver Install Debloat & Settings and the optional NVIDIA App download shortcut.'
    }
}

function Invoke-BoostLabDriverCleanOperation {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Operation,

        [Parameter(Mandatory)]
        [ValidateSet('Auto', 'Manual')]
        [string]$Mode,

        [string]$StateRoot = ''
    )

    $captures = @()
    try {
        switch ([string]$Operation.Type) {
            'DownloadFile' {
                Invoke-BoostLabDriverCleanVerifiedArtifactDownload `
                    -ArtifactId ([string]$Operation.Parameters.ArtifactId) `
                    -Destination ([string]$Operation.Parameters.OutFile) | Out-Null
            }
            'StartProcess' {
                Start-Process -FilePath ([string]$Operation.Parameters.FilePath) -ArgumentList ([string]$Operation.Parameters.ArgumentList) -Wait:([bool]$Operation.Parameters.Wait) -ErrorAction Stop
            }
            'Cmd' {
                & (Join-Path $env:SystemRoot 'System32\cmd.exe') /c ([string]$Operation.Parameters.CommandLine)
                if ($LASTEXITCODE -ne 0) {
                    throw "cmd.exe exited with code $LASTEXITCODE."
                }
            }
            'MoveItem' {
                Move-Item -Path ([string]$Operation.Parameters.Path) -Destination ([string]$Operation.Parameters.Destination) -Force -ErrorAction SilentlyContinue | Out-Null
            }
            'RemoveItem' {
                Remove-Item ([string]$Operation.Parameters.Path) -Recurse:([bool]$Operation.Parameters.Recurse) -Force -ErrorAction SilentlyContinue | Out-Null
            }
            'ExternalCommand' {
                & ([string]$Operation.Parameters.FilePath) @($Operation.Parameters.Arguments) | Out-Null
                if ($LASTEXITCODE -ne 0) {
                    throw "External command exited with code $LASTEXITCODE."
                }
            }
            'WriteTextFile' {
                Set-Content -Path ([string]$Operation.Parameters.Path) -Value ([string]$Operation.Parameters.Content) -Force -ErrorAction Stop
            }
            'SetFileReadOnly' {
                Set-ItemProperty -Path ([string]$Operation.Parameters.Path) -Name ([string]$Operation.Parameters.Name) -Value ([bool]$Operation.Parameters.Value) -ErrorAction Stop
            }
            'SetDriverSearchPolicy' {
                $captureStateRoot = if ([string]::IsNullOrWhiteSpace($StateRoot)) {
                    Get-BoostLabRollbackStateRoot
                }
                else {
                    $StateRoot
                }
                $capture = New-BoostLabRegistryStateCapture `
                    -ToolId 'driver-clean' `
                    -ActionId $Mode `
                    -ScopeId ([string]$Operation.Parameters.ScopeId) `
                    -RegistryPath ([string]$Operation.Parameters.RegistryPath) `
                    -ItemType RegistryValue `
                    -ValueName ([string]$Operation.Parameters.ValueName) `
                    -IntendedMutation RegistrySet `
                    -RiskClassification High `
                    -VerificationRequirement 'Verify SearchOrderConfig exists as REG_DWORD 0 after Driver Clean preparation.' `
                    -Policy (New-BoostLabDriverCleanCapturePolicy) `
                    -StateRoot $captureStateRoot
                if (-not [bool]$capture.Success) {
                    throw (($capture.Errors + @($capture.Message)) -join '; ')
                }
                $captures += $capture

                & (Join-Path $env:SystemRoot 'System32\cmd.exe') /c ([string]$Operation.Parameters.CommandLine)
                if ($LASTEXITCODE -ne 0) {
                    throw "cmd.exe exited with code $LASTEXITCODE."
                }

                $mutation = Set-BoostLabRollbackMutationState `
                    -RecordPath ([string]$capture.RecordPath) `
                    -StateRoot $captureStateRoot `
                    -PostMutationExists $true `
                    -PostMutationMetadata ([ordered]@{
                        ValueName = [string]$Operation.Parameters.ValueName
                        ValueType = 'DWord'
                        ValueData = [int]$Operation.Parameters.ValueData
                    })
                if (-not [bool]$mutation.Success) {
                    throw (($mutation.Errors + @($mutation.Message)) -join '; ')
                }
            }
            'Sleep' {
                Start-Sleep -Seconds ([int]$Operation.Parameters.Seconds)
            }
            'ShutdownRestart' {
                shutdown -r -t 00
                if ($LASTEXITCODE -ne 0) {
                    throw "shutdown exited with code $LASTEXITCODE."
                }
            }
            default {
                throw "Unsupported Driver Clean operation type: $($Operation.Type)"
            }
        }

        return [pscustomobject]@{
            Success = $true
            Operation = $Operation
            Message = "Completed: $($Operation.Label)"
            Captures = @($captures)
            Errors = @()
        }
    }
    catch {
        return [pscustomobject]@{
            Success = $false
            Operation = $Operation
            Message = "Failed: $($Operation.Label)"
            Captures = @($captures)
            Errors = @($_.Exception.Message)
        }
    }
}

function Invoke-BoostLabDriverCleanWorkflow {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Auto', 'Manual')]
        [string]$Mode,

        [AllowNull()]
        [scriptblock]$OperationExecutor = $null,

        [bool]$SkipEnvironmentChecks = $false,

        [string]$StateRoot = ''
    )

    $plan = Get-BoostLabDriverCleanOperationPlan -Mode $Mode
    $results = [System.Collections.Generic.List[object]]::new()
    $captures = [System.Collections.Generic.List[object]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()

    if (-not $SkipEnvironmentChecks) {
        if (-not (Test-BoostLabDriverCleanAdministrator)) {
            $errors.Add('Administrator rights are required before Driver Clean can run the source-equivalent workflow.')
        }
        if (-not (Test-BoostLabDriverCleanInternet)) {
            $errors.Add('Internet connection is required before Driver Clean can download the source-defined artifacts.')
        }
        if ($errors.Count -gt 0) {
            return [pscustomobject]@{
                Success = $false
                Status = 'EnvironmentCheckFailed'
                Mode = $Mode
                Plan = $plan
                OperationResults = @()
                Captures = @()
                Errors = $errors.ToArray()
                CompletedOperationCount = 0
                ExpectedOperationCount = [int]$plan.OperationCount
            }
        }
    }

    foreach ($operation in @($plan.Operations)) {
        $result = if ($null -ne $OperationExecutor) {
            & $OperationExecutor $operation $Mode
        }
        else {
            Invoke-BoostLabDriverCleanOperation -Operation $operation -Mode $Mode -StateRoot $StateRoot
        }

        if ($null -eq $result -or $null -eq $result.PSObject.Properties['Success']) {
            $result = [pscustomobject]@{
                Success = $false
                Operation = $operation
                Message = "Operation executor returned an invalid result for: $($operation.Label)"
                Captures = @()
                Errors = @('Invalid operation executor result.')
            }
        }

        $results.Add($result)
        foreach ($capture in @($result.Captures)) {
            $captures.Add($capture)
        }
        if (-not [bool]$result.Success) {
            foreach ($errorText in @($result.Errors)) {
                if (-not [string]::IsNullOrWhiteSpace([string]$errorText)) {
                    $errors.Add([string]$errorText)
                }
            }
            return [pscustomobject]@{
                Success = $false
                Status = 'OperationFailed'
                Mode = $Mode
                Plan = $plan
                OperationResults = $results.ToArray()
                Captures = $captures.ToArray()
                Errors = $errors.ToArray()
                FailedOperation = $operation
                CompletedOperationCount = $results.Count
                ExpectedOperationCount = [int]$plan.OperationCount
            }
        }
    }

    return [pscustomobject]@{
        Success = $true
        Status = if ($Mode -eq 'Auto') { 'AutoWorkflowScheduled' } else { 'ManualWorkflowScheduled' }
        Mode = $Mode
        Plan = $plan
        OperationResults = $results.ToArray()
        Captures = $captures.ToArray()
        Errors = @()
        FailedOperation = $null
        CompletedOperationCount = $results.Count
        ExpectedOperationCount = [int]$plan.OperationCount
    }
}

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        Id = [string]$script:BoostLabToolMetadata['Id']
        Title = [string]$script:BoostLabToolMetadata['Title']
        Stage = [string]$script:BoostLabToolMetadata['Stage']
        Order = [int]$script:BoostLabToolMetadata['Order']
        Type = [string]$script:BoostLabToolMetadata['Type']
        RiskLevel = [string]$script:BoostLabToolMetadata['RiskLevel']
        Description = [string]$script:BoostLabToolMetadata['Description']
        Actions = @($script:BoostLabToolMetadata['Actions'])
        Capabilities = $script:BoostLabToolMetadata['Capabilities']
        ImplementedActions = @($script:BoostLabImplementedActions)
        ConfirmationRequiredActions = @('Open', 'Apply')
        ConfirmationText = 'Driver Clean will run the source-equivalent DDU workflow: download 7-Zip and DDU, install/configure 7-Zip, configure DDU, set driver-search policy, create RunOnce, enable Safe Mode, and restart. Continue?'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabDriverCleanSourceStatus
    [pscustomobject]@{
        Supported = $true
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason = 'Driver Clean source-equivalent Auto and Manual workflows are available after explicit confirmation.'
        SourceChecksumStatus = [string]$sourceStatus.ChecksumStatus
        Timestamp = Get-Date
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Status = 'SourceEquivalentDriverClean'
        LastAction = $null
        LastResult = $null
        RestartRequired = $true
        Timestamp = Get-Date
    }
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ActionName,

        [bool]$Confirmed = $false,

        [AllowNull()]
        [scriptblock]$OperationExecutor = $null,

        [bool]$SkipEnvironmentChecks = $false,

        [string]$StateRoot = ''
    )

    $canonicalActionName = switch ($ActionName) {
        'Prepare Manual Handoff' { 'Open' }
        'Manual Handoff' { 'Open' }
        'Apply Auto' { 'Apply' }
        default { $ActionName }
    }

    if ($canonicalActionName -eq 'Analyze') {
        $analysis = Get-BoostLabDriverCleanAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        $status = if ($sourceOk) { 'Analyzed' } else { 'SourceVerificationFailed' }
        $message = if ($sourceOk) {
            'Driver Clean analyzed. Source-equivalent Auto and Manual DDU workflows are available only after explicit confirmation.'
        }
        else {
            'Driver Clean source checksum verification failed or source mirror is missing.'
        }
        $errors = if ($sourceOk) {
            @()
        }
        else {
            @('Driver Clean source mirror checksum did not match the expected value or the source mirror is missing.')
        }
        return New-BoostLabDriverCleanResult `
            -Success $sourceOk `
            -Action 'Analyze' `
            -Status $status `
            -CommandStatus 'No execution performed' `
            -VerificationStatus ([string]$analysis.Source.ChecksumStatus) `
            -Message $message `
            -Data $analysis `
            -Errors $errors
    }

    if ($canonicalActionName -in @('Open', 'Apply')) {
        if (-not $Confirmed) {
            return New-BoostLabDriverCleanResult `
                -Success $false `
                -Action $canonicalActionName `
                -Status 'Cancelled' `
                -CommandStatus 'Cancelled before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'Driver Clean was cancelled before the source-equivalent workflow started. No download, installer, registry change, RunOnce entry, Safe Mode change, bcdedit call, reboot, DDU launch, or driver cleanup occurred.' `
                -Cancelled $true
        }

        $analysis = Get-BoostLabDriverCleanAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        if (-not $sourceOk) {
            return New-BoostLabDriverCleanResult `
                -Success $false `
                -Action $canonicalActionName `
                -Status 'SourceVerificationFailed' `
                -CommandStatus 'Blocked before execution' `
                -VerificationStatus ([string]$analysis.Source.ChecksumStatus) `
                -Message 'Driver Clean source-equivalent workflow blocked because source checksum verification failed or the source mirror is missing.' `
                -Data $analysis `
                -Errors @('Driver Clean source mirror checksum did not match the expected value or the source mirror is missing.')
        }

        $mode = if ($canonicalActionName -eq 'Apply') { 'Auto' } else { 'Manual' }
        $workflow = Invoke-BoostLabDriverCleanWorkflow `
            -Mode $mode `
            -OperationExecutor $OperationExecutor `
            -SkipEnvironmentChecks:$SkipEnvironmentChecks `
            -StateRoot $StateRoot

        $commandStatus = if ([bool]$workflow.Success) {
            'Completed source-equivalent Driver Clean preparation; reboot requested'
        }
        else {
            'Completed with errors'
        }
        $verificationStatus = if ([bool]$workflow.Success) { 'Passed' } else { 'Failed' }
        $message = if ([bool]$workflow.Success -and $mode -eq 'Auto') {
            'Driver Clean Auto prepared the source-equivalent DDU workflow and requested restart into Safe Mode. RunOnce will launch DDU with -CleanSoundBlaster -CleanRealtek -CleanAllGpus -Restart.'
        }
        elseif ([bool]$workflow.Success) {
            'Driver Clean Manual prepared the source-equivalent DDU workflow and requested restart into Safe Mode. RunOnce will launch DDU manually.'
        }
        else {
            'Driver Clean source-equivalent workflow failed before completing all source-defined operations.'
        }
        $changesExecuted = [bool]$workflow.Success -or @($workflow.OperationResults).Count -gt 0

        return New-BoostLabDriverCleanResult `
            -Success ([bool]$workflow.Success) `
            -Action $canonicalActionName `
            -Status ([string]$workflow.Status) `
            -CommandStatus $commandStatus `
            -VerificationStatus $verificationStatus `
            -Message $message `
            -Data $workflow `
            -Errors @($workflow.Errors) `
            -ChangesExecuted $changesExecuted `
            -RestartRequired ([bool]$workflow.Success)
    }

    if ($canonicalActionName -in @('Default', 'Restore')) {
        return New-BoostLabDriverCleanResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'Unavailable' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message "$canonicalActionName is unavailable for Driver Clean. The source does not define Default, Default is not Restore, and Restore requires selected captured state and a dedicated restore contract."
    }

    return New-BoostLabDriverCleanResult `
        -Success $false `
        -Action $canonicalActionName `
        -Status 'Unsupported' `
        -CommandStatus 'Refused before execution' `
        -VerificationStatus 'NotApplicable' `
        -Message 'Unsupported Driver Clean action. Only Analyze, Open (DDU Manual), and Apply (DDU Auto) are exposed.'
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
    'Get-BoostLabDriverCleanSourceStatus'
    'Get-BoostLabDriverCleanOperationPlan'
    'Invoke-BoostLabDriverCleanWorkflow'
)
