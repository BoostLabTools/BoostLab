Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'bloatware'
    Title = 'Bloatware'
    Stage = 'Windows'
    Order = 11
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Run one approved source-equivalent Bloatware branch after explicit confirmation.'
    Actions = @('Analyze', 'Apply')
    SelectionMode = 'SingleSelect'
    SelectionRequiredActions = @('Apply')
    SelectionLabel = 'Select exactly one Bloatware source branch'
    SelectionItems = @(
        @{ Id = 'RemoveAllBloatware'; Title = 'Remove : All Bloatware (Recommended)'; SourceMenuNumber = 2 }
        @{ Id = 'InstallStore'; Title = 'Install: Store'; SourceMenuNumber = 3 }
        @{ Id = 'InstallAllUwpApps'; Title = 'Install: All UWP Apps'; SourceMenuNumber = 4 }
        @{ Id = 'OpenUwpFeatures'; Title = 'Install: UWP Features'; SourceMenuNumber = 5 }
        @{ Id = 'OpenLegacyFeatures'; Title = 'Install: Legacy Features'; SourceMenuNumber = 6 }
        @{ Id = 'InstallOneDrive'; Title = 'Install: One Drive'; SourceMenuNumber = 7 }
        @{ Id = 'InstallRemoteDesktopConnection'; Title = 'Install: Remote Desktop Connection'; SourceMenuNumber = 8 }
        @{ Id = 'InstallSnippingTool'; Title = 'Install: Snipping Tool'; SourceMenuNumber = 9 }
    )
    Capabilities = [ordered]@{
        RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $false
        CanModifyRegistry = $true; CanModifyServices = $true; CanInstallSoftware = $true
        CanDownload = $true; CanModifyDrivers = $false; CanModifySecurity = $true
        CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false
        SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Analyze', 'Apply')
$script:BoostLabExpectedSourceHash = '36677A334B37025A7234F4320EE54EF50E9528D1814E2B3A463EEB564C5814F5'
$script:BoostLabExpectedCanonicalSourceHash = 'EBCE09158AB61ADE2C181DD5DB64C94B962BAF133DB4DB6122CEE642B9A48C9F'
$script:BoostLabSourceRelativePath = 'source-ultimate\6 Windows\11 Bloatware.ps1'
$script:BoostLabBranchOrder = @(
    'RemoveAllBloatware'
    'InstallStore'
    'InstallAllUwpApps'
    'OpenUwpFeatures'
    'OpenLegacyFeatures'
    'InstallOneDrive'
    'InstallRemoteDesktopConnection'
    'InstallSnippingTool'
)
$script:BoostLabBranchTitles = [ordered]@{
    RemoveAllBloatware = 'Remove : All Bloatware (Recommended)'
    InstallStore = 'Install: Store'
    InstallAllUwpApps = 'Install: All UWP Apps'
    OpenUwpFeatures = 'Install: UWP Features'
    OpenLegacyFeatures = 'Install: Legacy Features'
    InstallOneDrive = 'Install: One Drive'
    InstallRemoteDesktopConnection = 'Install: Remote Desktop Connection'
    InstallSnippingTool = 'Install: Snipping Tool'
}

function Invoke-BoostLabBloatwareVerifiedArtifactDownload {
    param(
        [Parameter(Mandatory)]
        [string]$ArtifactId,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    $downloadModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\DownloadProvenance.psm1'
    if (-not (Get-Command -Name 'Invoke-BoostLabVerifiedArtifactDownload' -ErrorAction SilentlyContinue)) {
        Import-Module -Name $downloadModulePath -Scope Local -Force -ErrorAction Stop
    }

    Invoke-BoostLabVerifiedArtifactDownload -ArtifactId $ArtifactId -Destination $Destination
}
$script:BoostLabRemoteDesktopConnectionUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/remotedesktopconnection.exe'
$script:BoostLabSnippingToolUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/snippingtool.exe'
$script:BoostLabUwpFeatureListWindows11 = @(
    'Extended Theme Content'
    'Facial Recognition (Windows Hello)'
    'Internet Explorer mode'
    'Math Recognizer'
    'Notepad (system)'
    'OpenSSH Client'
    'Print Management'
    'Steps Recorder'
    'WMIC'
    'Windows Media Player Legacy (App)'
    'Windows PowerShell ISE'
    'WordPad'
)
$script:BoostLabUwpFeatureListWindows10 = @(
    'Internet Explorer 11'
    'Math Recognizer'
    'Microsoft Quick Assist (App)'
    'Notepad (system)'
    'OpenSSH Client'
    'Print Management Console'
    'Steps Recorder'
    'Windows Fax and Scan'
    'Windows Hello Face'
    'Windows Media Player Legacy (App)'
    'Windows PowerShell Integrated Scripting Environment'
    'WordPad'
)
$script:BoostLabLegacyFeatureListWindows11 = @(
    '.Net Framework 4.8 Advanced Services +'
    'WCF Services +'
    'TCP Port Sharing'
    'Media Features +'
    'Windows Media Player Legacy (App)'
    'Microsoft Print to PDF'
    'Print and Document Services +'
    'Internet Printing Client'
    'Remote Differential Compression API Support'
    'SMB Direct'
    'Windows PowerShell 2.0 +'
    'Windows PowerShell 2.0 Engine'
    'Work Folders Client'
)
$script:BoostLabLegacyFeatureListWindows10 = @(
    '.Net Framework 4.8 Advanced Services +'
    'WCF Services +'
    'TCP Port Sharing'
    'Internet Explorer 11'
    'Media Features +'
    'Windows Media Player'
    'Microsoft Print to PDF'
    'Microsoft XPS Document Writer'
    'Print and Document Services +'
    'Internet Printing Client'
    'Remote Differential Compression API Support'
    'SMB 1.0/CIFS File Sharing Support +'
    'SMB 1.0/CIFS Automatic Removal'
    'SMB 1.0/CIFS Client'
    'SMB Direct'
    'Windows PowerShell 2.0 +'
    'Windows PowerShell 2.0 Engine'
    'Work Folders Client'
)

function Get-BoostLabBloatwareProjectRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

function Get-BoostLabBloatwareSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Join-Path (Get-BoostLabBloatwareProjectRoot) $script:BoostLabSourceRelativePath
}

function Get-BoostLabBloatwareSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabBloatwareSourcePath
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

function Test-BoostLabBloatwareAdministrator {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function Test-BoostLabBloatwareInternet {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return [bool](Test-Connection -ComputerName '8.8.8.8' -Count 1 -Quiet -ErrorAction SilentlyContinue)
}

function ConvertTo-BoostLabBloatwareBranch {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [AllowNull()]
        [string]$Branch,

        [AllowNull()]
        [string[]]$SelectedAppIds = @()
    )

    if ([string]::IsNullOrWhiteSpace($Branch) -and @($SelectedAppIds).Count -eq 1) {
        $Branch = [string]@($SelectedAppIds)[0]
    }
    if ([string]::IsNullOrWhiteSpace($Branch)) {
        return ''
    }

    $normalized = ($Branch -replace '[^A-Za-z0-9]', '').Trim()
    switch -Regex ($normalized.ToUpperInvariant()) {
        '^2$|^REMOVEALLBLOATWARE$|^REMOVE$|^REMOVEBLOATWARE$' { return 'RemoveAllBloatware' }
        '^3$|^INSTALLSTORE$|^STORE$' { return 'InstallStore' }
        '^4$|^INSTALLALLUWPAPPS$|^ALLUWPAPPS$' { return 'InstallAllUwpApps' }
        '^5$|^OPENUWPFEATURES$|^UWPFEATURES$' { return 'OpenUwpFeatures' }
        '^6$|^OPENLEGACYFEATURES$|^LEGACYFEATURES$' { return 'OpenLegacyFeatures' }
        '^7$|^INSTALLONEDRIVE$|^ONEDRIVE$' { return 'InstallOneDrive' }
        '^8$|^INSTALLREMOTEDESKTOPCONNECTION$|^REMOTEDESKTOPCONNECTION$|^RDC$' { return 'InstallRemoteDesktopConnection' }
        '^9$|^INSTALLSNIPPINGTOOL$|^SNIPPINGTOOL$' { return 'InstallSnippingTool' }
        default { return $Branch.Trim() }
    }
}

function New-BoostLabBloatwareResult {
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

        [bool]$ChangesExecuted = $false
    )

    [pscustomobject]@{
        Success = $Success
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Action = $Action
        Status = $Status
        CommandStatus = $CommandStatus
        VerificationStatus = $VerificationStatus
        Message = $Message
        RestartRequired = $false
        Cancelled = $Cancelled
        ChangesExecuted = $ChangesExecuted
        Timestamp = Get-Date
        Data = $Data
        Warnings = @($Warnings | Select-Object -Unique)
        Errors = @($Errors)
    }
}

function New-BoostLabBloatwareOperation {
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

        [hashtable]$Parameters = @{}
    )

    [pscustomobject]@{
        Order = $Order
        Branch = $Branch
        BranchTitle = [string]$script:BoostLabBranchTitles[$Branch]
        Category = $Category
        Type = $Type
        Label = $Label
        SourceCommand = $SourceCommand
        Parameters = $Parameters
    }
}

function Get-BoostLabBloatwarePaths {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $systemRoot = if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) { 'C:\Windows' } else { $env:SystemRoot }
    $systemDrive = if ([string]::IsNullOrWhiteSpace($env:SystemDrive)) { 'C:' } else { $env:SystemDrive }
    $localAppData = if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) { Join-Path $env:USERPROFILE 'AppData\Local' } else { $env:LOCALAPPDATA }

    [ordered]@{
        SystemRoot = $systemRoot
        SystemDrive = $systemDrive
        LocalAppData = $localAppData
        SystemTemp = Join-Path $systemRoot 'Temp'
        BrlttyRoot = Join-Path $systemRoot 'brltty'
        WindowsStoreRegFile = Join-Path $systemRoot 'Temp\windowsstore.reg'
        WindowsStoreSettingsDat = Join-Path $localAppData 'Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\Settings\settings.dat'
        System32OneDriveSetup = Join-Path $systemRoot 'System32\OneDriveSetup.exe'
        SysWow64OneDriveSetup = Join-Path $systemRoot 'SysWOW64\OneDriveSetup.exe'
        RemoteDesktopInstaller = Join-Path $systemRoot 'Temp\remotedesktopconnection.exe'
        SnippingToolInstaller = Join-Path $systemRoot 'Temp\snippingtool.exe'
        SnippingToolExe = Join-Path $systemRoot 'System32\SnippingTool.exe'
        OptionalFeaturesExe = Join-Path $systemRoot 'System32\OptionalFeatures.exe'
    }
}

function Get-BoostLabBloatwareExcludedAppxPatterns {
    @(
        '*CBS*'
        '*Microsoft.AV1VideoExtension*'
        '*Microsoft.AVCEncoderVideoExtension*'
        '*Microsoft.HEIFImageExtension*'
        '*Microsoft.HEVCVideoExtension*'
        '*Microsoft.MPEG2VideoExtension*'
        '*Microsoft.Paint*'
        '*Microsoft.RawImageExtension*'
        '*Microsoft.SecHealthUI*'
        '*Microsoft.VP9VideoExtensions*'
        '*Microsoft.WebMediaExtensions*'
        '*Microsoft.WebpImageExtension*'
        '*Microsoft.Windows.Photos*'
        '*Microsoft.Windows.ShellExperienceHost*'
        '*Microsoft.Windows.StartMenuExperienceHost*'
        '*Microsoft.WindowsNotepad*'
        '*NVIDIACorp.NVIDIAControlPanel*'
        '*windows.immersivecontrolpanel*'
    )
}

function Get-BoostLabBloatwareObjectProperty {
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$Name
    )

    if ($null -eq $InputObject) {
        return $null
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function ConvertTo-BoostLabBloatwareAppxPackageRecord {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [object]$Package
    )

    if ($null -eq $Package) {
        return [pscustomobject]@{
            Name              = ''
            PackageFullName   = ''
            PackageFamilyName = ''
            User              = ''
            InstallLocation   = ''
        }
    }

    [pscustomobject]@{
        Name              = [string](Get-BoostLabBloatwareObjectProperty -InputObject $Package -Name 'Name')
        PackageFullName   = [string](Get-BoostLabBloatwareObjectProperty -InputObject $Package -Name 'PackageFullName')
        PackageFamilyName = [string](Get-BoostLabBloatwareObjectProperty -InputObject $Package -Name 'PackageFamilyName')
        User              = [string](Get-BoostLabBloatwareObjectProperty -InputObject $Package -Name 'User')
        InstallLocation   = [string](Get-BoostLabBloatwareObjectProperty -InputObject $Package -Name 'InstallLocation')
    }
}

function Test-BoostLabBloatwareAppxPackageExcluded {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [AllowNull()]
        [string]$Name,

        [string[]]$ExcludeLike = @()
    )

    foreach ($pattern in @($ExcludeLike)) {
        if ([string]$Name -like [string]$pattern) {
            return $true
        }
    }

    return $false
}

function Test-BoostLabBloatwareConsolePipeException {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [AllowNull()]
        [object]$ErrorRecord
    )

    if ($null -eq $ErrorRecord) {
        return $false
    }

    $messages = [System.Collections.Generic.List[string]]::new()
    if ($ErrorRecord -is [System.Management.Automation.ErrorRecord]) {
        $messages.Add([string]$ErrorRecord.Exception.Message)
        if ($null -ne $ErrorRecord.Exception.InnerException) {
            $messages.Add([string]$ErrorRecord.Exception.InnerException.Message)
        }
    }
    elseif ($ErrorRecord -is [System.Exception]) {
        $messages.Add([string]$ErrorRecord.Message)
        if ($null -ne $ErrorRecord.InnerException) {
            $messages.Add([string]$ErrorRecord.InnerException.Message)
        }
    }
    else {
        $messages.Add([string]$ErrorRecord)
    }

    $messageText = ($messages.ToArray() -join "`n")
    return (
        $messageText -like '*No process is on the other end of the pipe*' -or
        $messageText -like '*getting console output buffer information*' -or
        $messageText -like '*0xE9*'
    )
}

function Invoke-BoostLabBloatwareRemoveAppxExcept {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string[]]$ExcludeLike = @(),

        [scriptblock]$AppxGetter = $null,

        [scriptblock]$AppxRemover = $null
    )

    if ($null -eq $AppxGetter) {
        $AppxGetter = { Get-AppXPackage -AllUsers -ErrorAction Stop }
    }
    if ($null -eq $AppxRemover) {
        $AppxRemover = {
            param(
                [Parameter(Mandatory)]
                [object]$Package
            )

            $Package | Remove-AppxPackage -ErrorAction Stop -WarningAction SilentlyContinue -InformationAction SilentlyContinue | Out-Null
        }
    }

    $excluded = [System.Collections.Generic.List[object]]::new()
    $attempted = [System.Collections.Generic.List[object]]::new()
    $removed = [System.Collections.Generic.List[object]]::new()
    $failed = [System.Collections.Generic.List[object]]::new()
    $pipeWarnings = [System.Collections.Generic.List[object]]::new()
    $allPackages = @()

    $previousProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
        try {
            $allPackages = @(& $AppxGetter)
        }
        catch {
            if (Test-BoostLabBloatwareConsolePipeException -ErrorRecord $_) {
                $pipeWarnings.Add([pscustomobject]@{
                    Stage = 'EnumeratePackages'
                    Reason = [string]$_.Exception.Message
                    Package = $null
                })
                $allPackages = @()
            }
            else {
                throw
            }
        }

        foreach ($package in @($allPackages)) {
            $record = ConvertTo-BoostLabBloatwareAppxPackageRecord -Package $package
            if (Test-BoostLabBloatwareAppxPackageExcluded -Name ([string]$record.Name) -ExcludeLike $ExcludeLike) {
                $excluded.Add($record)
                continue
            }

            $attempted.Add($record)
            try {
                & $AppxRemover $package | Out-Null
                $removed.Add($record)
            }
            catch {
                if (Test-BoostLabBloatwareConsolePipeException -ErrorRecord $_) {
                    $pipeWarnings.Add([pscustomobject]@{
                        Stage = 'RemovePackage'
                        Reason = [string]$_.Exception.Message
                        Package = $record
                    })
                    continue
                }

                $failed.Add([pscustomobject]@{
                    Package = $record
                    Reason = [string]$_.Exception.Message
                })
            }
        }
    }
    finally {
        $ProgressPreference = $previousProgressPreference
    }

    $success = ($failed.Count -eq 0)
    $message = if ($success) {
        "Processed $($attempted.Count) non-excluded AppX package(s); $($excluded.Count) package(s) matched the source exclusion list."
    }
    else {
        "Failed to remove $($failed.Count) non-excluded AppX package(s)."
    }

    if ($pipeWarnings.Count -gt 0) {
        $message = "$message Console/progress output warning(s): $($pipeWarnings.Count)."
    }

    [pscustomobject]@{
        Success = $success
        Message = $message
        TotalPackages = @($allPackages).Count
        AttemptedPackages = $attempted.ToArray()
        RemovedPackages = $removed.ToArray()
        ExcludedPackages = $excluded.ToArray()
        FailedPackages = $failed.ToArray()
        ConsolePipeWarnings = $pipeWarnings.ToArray()
    }
}

function Get-BoostLabBloatwareExcludedCapabilityPatterns {
    @(
        '*Microsoft.Windows.Ethernet*'
        '*Microsoft.Windows.MSPaint*'
        '*Microsoft.Windows.Notepad*'
        '*Microsoft.Windows.Notepad.System*'
        '*Microsoft.Windows.Wifi*'
        '*NetFX3*'
        '*VBSCRIPT*'
        '*WMIC*'
        '*Windows.Client.ShellComponents*'
    )
}

function Get-BoostLabBloatwareExcludedOptionalFeaturePatterns {
    @(
        '*DirectPlay*'
        '*LegacyComponents*'
        '*NetFx3*'
        '*NetFx4*'
        '*NetFx4-AdvSrvs*'
        '*NetFx4ServerFeatures*'
        '*SearchEngine-Client-Package*'
        '*Server-Shell*'
        '*Windows-Defender*'
        '*Server-Drivers-General*'
        '*ServerCore-Drivers-General*'
        '*ServerCore-Drivers-General-WOW64*'
        '*Server-Gui-Mgmt*'
        '*WirelessNetworking*'
    )
}

function Get-BoostLabBloatwareWindowsStoreRegContent {
    @'
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\Settings\LocalState]
; disable video autoplay
"VideoAutoplay"=hex(5f5e10b):00,96,9d,69,8d,cd,93,dc,01
; disable notifications for app installations
"EnableAppInstallNotifications"=hex(5f5e10b):00,36,d0,88,8e,cd,93,dc,01

[HKEY_LOCAL_MACHINE\Settings\LocalState\PersistentSettings]
; disable personalized experiences
"PersonalizationEnabled"=hex(5f5e10b):00,0d,56,a1,8a,cd,93,dc,01
'@
}

function Get-BoostLabBloatwarePreflightOperations {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Branch,

        [Parameter(Mandatory)]
        [int]$StartOrder
    )

    @(
        New-BoostLabBloatwareOperation -Order $StartOrder -Branch $Branch -Category 'Preflight' -Type 'RequireAdministrator' -Label 'Require Administrator' -SourceCommand 'Administrator self-elevation block'
        New-BoostLabBloatwareOperation -Order ($StartOrder + 1) -Branch $Branch -Category 'Preflight' -Type 'RequireInternet' -Label 'Require internet connection' -SourceCommand 'Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet'
        New-BoostLabBloatwareOperation -Order ($StartOrder + 2) -Branch $Branch -Category 'Registry' -Type 'RegistryCommand' -Label 'Allow password sign in' -SourceCommand 'cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device`" /v `"DevicePasswordLessBuildVersion`" /t REG_DWORD /d `"0`" /f >nul 2>&1"' -Parameters @{
            Command = 'reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device" /v "DevicePasswordLessBuildVersion" /t REG_DWORD /d "0" /f'
        }
    )
}

function Get-BoostLabBloatwareOperationPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('RemoveAllBloatware', 'InstallStore', 'InstallAllUwpApps', 'OpenUwpFeatures', 'OpenLegacyFeatures', 'InstallOneDrive', 'InstallRemoteDesktopConnection', 'InstallSnippingTool')]
        [string]$Branch
    )

    $paths = Get-BoostLabBloatwarePaths
    $operations = [System.Collections.Generic.List[object]]::new()
    foreach ($operation in Get-BoostLabBloatwarePreflightOperations -Branch $Branch -StartOrder 1) {
        $operations.Add($operation)
    }
    $order = 4

    switch ($Branch) {
        'RemoveAllBloatware' {
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'AppX' -Type 'RemoveAppxExcept' -Label 'Remove all non-excluded UWP apps for all users' -SourceCommand 'Get-AppXPackage -AllUsers | Where-Object { source exclusions } | Remove-AppxPackage -ErrorAction SilentlyContinue' -Parameters @{ ExcludeLike = @(Get-BoostLabBloatwareExcludedAppxPatterns) }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Capability' -Type 'RemoveWindowsCapabilityExcept' -Label 'Remove non-excluded Windows capabilities' -SourceCommand 'Get-WindowsCapability -Online | Where-Object { source exclusions } | Remove-WindowsCapability -Online -Name $_.Name' -Parameters @{ ExcludeLike = @(Get-BoostLabBloatwareExcludedCapabilityPatterns) }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Feature' -Type 'DisableOptionalFeatureExcept' -Label 'Disable non-excluded optional features' -SourceCommand 'Get-WindowsOptionalFeature -Online | Where-Object { source exclusions } | Disable-WindowsOptionalFeature -Online -FeatureName $_.FeatureName -NoRestart' -Parameters @{ ExcludeLike = @(Get-BoostLabBloatwareExcludedOptionalFeaturePatterns) }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Service' -Type 'Cmd' -Label 'Stop brlapi service' -SourceCommand 'cmd /c "sc stop `"brlapi`" >nul 2>&1"' -Parameters @{ Command = 'sc stop "brlapi"' }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Service' -Type 'Cmd' -Label 'Delete brlapi service' -SourceCommand 'cmd /c "sc delete `"brlapi`" >nul 2>&1"' -Parameters @{ Command = 'sc delete "brlapi"' }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'File' -Type 'Cmd' -Label 'Take ownership of brltty directory' -SourceCommand 'cmd /c "takeown /f `"$env:SystemRoot\brltty`" /r /d y >nul 2>&1"' -Parameters @{ Command = 'takeown /f "{BrlttyRoot}" /r /d y' }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'File' -Type 'Cmd' -Label 'Grant administrators full control of brltty directory' -SourceCommand 'cmd /c "icacls `"$env:SystemRoot\brltty`" /grant *S-1-5-32-544:F /t >nul 2>&1"' -Parameters @{ Command = 'icacls "{BrlttyRoot}" /grant *S-1-5-32-544:F /t' }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'File' -Type 'RemoveItem' -Label 'Delete brltty directory' -SourceCommand 'Remove-Item "$env:SystemRoot\brltty" -Recurse -Force -ErrorAction SilentlyContinue' -Parameters @{ Path = $paths.BrlttyRoot; Recurse = $true }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Installer' -Type 'MsiUninstallByDisplayName' -Label 'Uninstall Microsoft GameInput' -SourceCommand 'Start-Process "msiexec.exe" -ArgumentList "/x $guid /qn /norestart" -Wait -NoNewWindow' -Parameters @{ DisplayNameLike = '*Microsoft GameInput*' }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Process' -Type 'StopProcess' -Label 'Stop OneDrive process' -SourceCommand 'Stop-Process -Force -Name OneDrive -ErrorAction SilentlyContinue' -Parameters @{ Name = 'OneDrive' }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Installer' -Type 'Cmd' -Label 'Uninstall System32 OneDrive' -SourceCommand 'cmd /c "C:\Windows\System32\OneDriveSetup.exe -uninstall >nul 2>&1"' -Parameters @{ Command = '"{System32OneDriveSetup}" -uninstall' }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Installer' -Type 'UninstallOneDriveAllUsers' -Label 'Uninstall Office 365 OneDrive installers' -SourceCommand 'Get-ChildItem -Path "C:\Program Files*\Microsoft OneDrive", "$env:LOCALAPPDATA\Microsoft\OneDrive" -Filter "OneDriveSetup.exe" -Recurse | Start-Process /uninstall /allusers'))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Installer' -Type 'Cmd' -Label 'Uninstall SysWOW64 OneDrive' -SourceCommand 'cmd /c "C:\Windows\SysWOW64\OneDriveSetup.exe -uninstall >nul 2>&1"' -Parameters @{ Command = '"{SysWow64OneDriveSetup}" -uninstall' }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'ScheduledTask' -Type 'UnregisterScheduledTasksLike' -Label 'Remove OneDrive scheduled tasks' -SourceCommand 'Get-ScheduledTask | Where-Object {$_.Taskname -match ''OneDrive''} | Unregister-ScheduledTask -Confirm:$false' -Parameters @{ TaskNameMatch = 'OneDrive' }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Installer' -Type 'StartProcess' -Label 'Uninstall Remote Desktop Connection' -SourceCommand 'Start-Process "mstsc" -ArgumentList "/Uninstall"' -Parameters @{ FilePath = 'mstsc'; ArgumentList = '/Uninstall' }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Process' -Type 'StopProcessWindow' -Label 'Close Remote Desktop Connection uninstall window' -SourceCommand 'Stop-Process -Force -Name mstsc when uninstall window appears' -Parameters @{ Name = 'mstsc'; TimeoutTicks = 100 }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Installer' -Type 'StartProcess' -Label 'Uninstall legacy Snipping Tool' -SourceCommand 'Start-Process "C:\Windows\System32\SnippingTool.exe" -ArgumentList "/Uninstall"' -Parameters @{ FilePath = $paths.SnippingToolExe; ArgumentList = '/Uninstall' }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Process' -Type 'StopProcessWindow' -Label 'Close Snipping Tool uninstall window' -SourceCommand 'Stop-Process -Force -Name SnippingTool when uninstall window appears' -Parameters @{ Name = 'SnippingTool'; TimeoutTicks = 100 }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Installer' -Type 'MsiUninstallByDisplayName' -Label 'Uninstall Windows 10 Update for x64-based systems' -SourceCommand 'Start-Process "msiexec.exe" -ArgumentList "/x $guid /qn /norestart" -Wait -NoNewWindow' -Parameters @{ DisplayNameLike = '*Update for x64-based Windows Systems*' }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Installer' -Type 'MsiUninstallByDisplayName' -Label 'Uninstall Microsoft Update Health Tools' -SourceCommand 'Start-Process "msiexec.exe" -ArgumentList "/x $guid /qn /norestart" -Wait -NoNewWindow' -Parameters @{ DisplayNameLike = '*Microsoft Update Health Tools*' }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Registry' -Type 'RegistryCommand' -Label 'Delete uhssvc service registry key' -SourceCommand 'cmd /c "reg delete `"HKLM\SYSTEM\ControlSet001\Services\uhssvc`" /f >nul 2>&1"' -Parameters @{ Command = 'reg delete "HKLM\SYSTEM\ControlSet001\Services\uhssvc" /f' }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'ScheduledTask' -Type 'UnregisterScheduledTaskName' -Label 'Remove PLUGScheduler task' -SourceCommand 'Unregister-ScheduledTask -TaskName PLUGScheduler -Confirm:$false -ErrorAction SilentlyContinue' -Parameters @{ TaskName = 'PLUGScheduler' }))
        }
        'InstallStore' {
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'AppX' -Type 'AppxRegisterLike' -Label 'Re-register Microsoft Store packages' -SourceCommand 'Get-AppXPackage -AllUsers | Where-Object { $_.Name -like ''*Store*'' } | Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"' -Parameters @{ NameLike = '*Store*' }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'ExternalProcess' -Type 'StartProcess' -Label 'Open Store settings page' -SourceCommand 'Start-Process "ms-windows-store:settings"' -Parameters @{ FilePath = 'ms-windows-store:settings' }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Process' -Type 'StopProcesses' -Label 'Stop Store processes' -SourceCommand '$stop = "WinStore.App", "backgroundTaskHost", "StoreDesktopExtension"; $stop | Stop-Process -Force' -Parameters @{ Names = @('WinStore.App', 'backgroundTaskHost', 'StoreDesktopExtension') }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Registry' -Type 'RegistryCommand' -Label 'Disable Microsoft Store app updates' -SourceCommand 'cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate`" /v `"AutoDownload`" /t REG_DWORD /d `"2`" /f >nul 2>&1"' -Parameters @{ Command = 'reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" /v "AutoDownload" /t REG_DWORD /d "2" /f' }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'RegistryHive' -Type 'StoreSettingsHiveImport' -Label 'Import source Store settings.dat registry payload' -SourceCommand 'Set-Content windowsstore.reg; reg load HKLM\Settings settings.dat; reg import windowsstore.reg; reg unload HKLM\Settings' -Parameters @{ RegFile = $paths.WindowsStoreRegFile; SettingsDat = $paths.WindowsStoreSettingsDat; RegContent = Get-BoostLabBloatwareWindowsStoreRegContent }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'ExternalProcess' -Type 'StartProcess' -Label 'Open Store settings page after import' -SourceCommand 'Start-Process "ms-windows-store:settings"' -Parameters @{ FilePath = 'ms-windows-store:settings' }))
        }
        'InstallAllUwpApps' {
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'AppX' -Type 'AppxRegisterAll' -Label 'Re-register all UWP apps for all users' -SourceCommand 'Get-AppxPackage -AllUsers | Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"'))
        }
        'OpenUwpFeatures' {
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'ExternalProcess' -Type 'StartProcess' -Label 'Open UWP optional features settings' -SourceCommand 'Start-Process "ms-settings:optionalfeatures"' -Parameters @{ FilePath = 'ms-settings:optionalfeatures' }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Information' -Type 'DisplayList' -Label 'Show source Windows 11 UWP feature list' -SourceCommand 'Write-Host source Windows 11 UWP feature list' -Parameters @{ ListName = 'Default Windows Install List W11'; Items = @($script:BoostLabUwpFeatureListWindows11) }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Information' -Type 'DisplayList' -Label 'Show source Windows 10 UWP feature list' -SourceCommand 'Write-Host source Windows 10 UWP feature list' -Parameters @{ ListName = 'Default Windows Install List W10'; Items = @($script:BoostLabUwpFeatureListWindows10) }))
        }
        'OpenLegacyFeatures' {
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'ExternalProcess' -Type 'StartProcess' -Label 'Open legacy optional features' -SourceCommand 'Start-Process "C:\Windows\System32\OptionalFeatures.exe"' -Parameters @{ FilePath = $paths.OptionalFeaturesExe }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Information' -Type 'DisplayList' -Label 'Show source Windows 11 legacy feature list' -SourceCommand 'Write-Host source Windows 11 legacy feature list' -Parameters @{ ListName = 'Default Windows Install List W11'; Items = @($script:BoostLabLegacyFeatureListWindows11) }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Information' -Type 'DisplayList' -Label 'Show source Windows 10 legacy feature list' -SourceCommand 'Write-Host source Windows 10 legacy feature list' -Parameters @{ ListName = 'Default Windows Install List W10'; Items = @($script:BoostLabLegacyFeatureListWindows10) }))
        }
        'InstallOneDrive' {
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Installer' -Type 'Cmd' -Label 'Install Windows 10 OneDrive setup' -SourceCommand 'cmd /c "C:\Windows\SysWOW64\OneDriveSetup.exe >nul 2>&1"' -Parameters @{ Command = '"{SysWow64OneDriveSetup}"' }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Installer' -Type 'Cmd' -Label 'Install Windows 11 OneDrive setup' -SourceCommand 'cmd /c "C:\Windows\System32\OneDriveSetup.exe >nul 2>&1"' -Parameters @{ Command = '"{System32OneDriveSetup}"' }))
        }
        'InstallRemoteDesktopConnection' {
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Download' -Type 'DownloadFile' -Label 'Download Remote Desktop Connection installer' -SourceCommand 'IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/remotedesktopconnection.exe" -OutFile "$env:SystemRoot\Temp\remotedesktopconnection.exe"' -Parameters @{ Url = $script:BoostLabRemoteDesktopConnectionUrl; Destination = $paths.RemoteDesktopInstaller; ArtifactName = 'remotedesktopconnection.exe'; ArtifactId = 'bloatware-remote-desktop-connection'; Classification = 'UltimateAuthorHostedArtifact'; NeedsBoostLabMirror = $true }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Installer' -Type 'Cmd' -Label 'Install Remote Desktop Connection' -SourceCommand 'cmd /c "%SystemRoot%\Temp\remotedesktopconnection.exe >nul 2>&1"' -Parameters @{ Command = '"{RemoteDesktopInstaller}"' }))
        }
        'InstallSnippingTool' {
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Download' -Type 'DownloadFile' -Label 'Download Windows 10 Snipping Tool installer' -SourceCommand 'IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/snippingtool.exe" -OutFile "$env:SystemRoot\Temp\snippingtool.exe"' -Parameters @{ Url = $script:BoostLabSnippingToolUrl; Destination = $paths.SnippingToolInstaller; ArtifactName = 'snippingtool.exe'; ArtifactId = 'bloatware-snipping-tool'; Classification = 'UltimateAuthorHostedArtifact'; NeedsBoostLabMirror = $true }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'Installer' -Type 'Cmd' -Label 'Install Windows 10 Snipping Tool' -SourceCommand 'cmd /c "%SystemRoot%\Temp\snippingtool.exe >nul 2>&1"' -Parameters @{ Command = '"{SnippingToolInstaller}"' }))
            $operations.Add((New-BoostLabBloatwareOperation -Order ($order++) -Branch $Branch -Category 'AppX' -Type 'AppxRegisterLike' -Label 'Register Windows 11 Snipping Tool package' -SourceCommand 'Get-AppXPackage -AllUsers *Microsoft.ScreenSketch* | Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"' -Parameters @{ NameLike = '*Microsoft.ScreenSketch*' }))
        }
    }

    [pscustomobject]@{
        Branch = $Branch
        BranchTitle = [string]$script:BoostLabBranchTitles[$Branch]
        SourceMenuNumber = [int](@($script:BoostLabToolMetadata.SelectionItems | Where-Object { [string]$_.Id -eq $Branch })[0].SourceMenuNumber)
        Operations = $operations.ToArray()
        OperationCount = $operations.Count
        DownloadArtifacts = @($operations | Where-Object { [string]$_.Type -eq 'DownloadFile' } | ForEach-Object { $_.Parameters })
    }
}

function Get-BoostLabBloatwareAllOperationPlans {
    [CmdletBinding()]
    [OutputType([object[]])]
    param()

    foreach ($branch in $script:BoostLabBranchOrder) {
        Get-BoostLabBloatwareOperationPlan -Branch $branch
    }
}

function Resolve-BoostLabBloatwareCommandText {
    param(
        [Parameter(Mandatory)]
        [string]$CommandText,

        [Parameter(Mandatory)]
        [hashtable]$Paths
    )

    $resolved = $CommandText
    foreach ($key in @($Paths.Keys)) {
        $resolved = $resolved.Replace("{$key}", [string]$Paths[$key])
    }
    return $resolved
}

function New-BoostLabBloatwareOperationResult {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Operation,

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
        Message = $Message
        Data = $Data
    }
}

function Invoke-BoostLabBloatwareRealOperation {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Operation
    )

    $paths = Get-BoostLabBloatwarePaths
    $p = $Operation.Parameters
    try {
        switch ([string]$Operation.Type) {
            'RequireAdministrator' {
                if (-not (Test-BoostLabBloatwareAdministrator)) {
                    return New-BoostLabBloatwareOperationResult -Operation $Operation -Success $false -Message 'Administrator rights are required.'
                }
                return New-BoostLabBloatwareOperationResult -Operation $Operation -Success $true -Message 'Administrator rights confirmed.'
            }
            'RequireInternet' {
                if (-not (Test-BoostLabBloatwareInternet)) {
                    return New-BoostLabBloatwareOperationResult -Operation $Operation -Success $false -Message 'Internet connectivity is required.'
                }
                return New-BoostLabBloatwareOperationResult -Operation $Operation -Success $true -Message 'Internet connectivity confirmed.'
            }
            'RegistryCommand' { & cmd.exe /c (Resolve-BoostLabBloatwareCommandText -CommandText ([string]$p.Command) -Paths $paths) | Out-Null }
            'Cmd' { & cmd.exe /c (Resolve-BoostLabBloatwareCommandText -CommandText ([string]$p.Command) -Paths $paths) | Out-Null }
            'RemoveAppxExcept' {
                $appxResult = Invoke-BoostLabBloatwareRemoveAppxExcept -ExcludeLike @($p.ExcludeLike)
                return New-BoostLabBloatwareOperationResult `
                    -Operation $Operation `
                    -Success ([bool]$appxResult.Success) `
                    -Message ([string]$appxResult.Message) `
                    -Data $appxResult
            }
            'RemoveWindowsCapabilityExcept' {
                Get-WindowsCapability -Online | Where-Object {
                    $name = [string]$_.Name
                    $keep = $false
                    foreach ($pattern in @($p.ExcludeLike)) {
                        if ($name -like [string]$pattern) { $keep = $true; break }
                    }
                    -not $keep
                } | ForEach-Object {
                    try { Remove-WindowsCapability -Online -Name $_.Name | Out-Null } catch { }
                }
            }
            'DisableOptionalFeatureExcept' {
                Get-WindowsOptionalFeature -Online | Where-Object {
                    $name = [string]$_.FeatureName
                    $keep = $false
                    foreach ($pattern in @($p.ExcludeLike)) {
                        if ($name -like [string]$pattern) { $keep = $true; break }
                    }
                    -not $keep
                } | ForEach-Object {
                    try { Disable-WindowsOptionalFeature -Online -FeatureName $_.FeatureName -NoRestart -WarningAction SilentlyContinue | Out-Null } catch { }
                }
            }
            'RemoveItem' { Remove-Item -LiteralPath ([string]$p.Path) -Recurse:([bool]$p.Recurse) -Force -ErrorAction SilentlyContinue | Out-Null }
            'MsiUninstallByDisplayName' {
                $item = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like [string]$p.DisplayNameLike } | Select-Object -First 1
                if ($item) { Start-Process 'msiexec.exe' -ArgumentList "/x $($item.PSChildName) /qn /norestart" -Wait -NoNewWindow }
            }
            'StopProcess' { Stop-Process -Force -Name ([string]$p.Name) -ErrorAction SilentlyContinue | Out-Null }
            'StopProcesses' { foreach ($name in @($p.Names)) { Stop-Process -Name ([string]$name) -Force -ErrorAction SilentlyContinue } }
            'UninstallOneDriveAllUsers' {
                Get-ChildItem -Path 'C:\Program Files*\Microsoft OneDrive', (Join-Path $paths.LocalAppData 'Microsoft\OneDrive') -Filter 'OneDriveSetup.exe' -Recurse -ErrorAction SilentlyContinue |
                    ForEach-Object { Start-Process -Wait $_.FullName -ArgumentList '/uninstall /allusers' -WindowStyle Hidden -ErrorAction SilentlyContinue }
            }
            'UnregisterScheduledTasksLike' { Get-ScheduledTask | Where-Object { $_.TaskName -match [string]$p.TaskNameMatch } | Unregister-ScheduledTask -Confirm:$false }
            'UnregisterScheduledTaskName' { Unregister-ScheduledTask -TaskName ([string]$p.TaskName) -Confirm:$false -ErrorAction SilentlyContinue | Out-Null }
            'StartProcess' {
                $args = @{}
                $args['FilePath'] = [string]$p.FilePath
                if ($p.Contains('ArgumentList')) { $args['ArgumentList'] = [string]$p.ArgumentList }
                Start-Process @args
            }
            'StopProcessWindow' {
                $running = $true
                $timeout = 0
                do {
                    $process = Get-Process -Name ([string]$p.Name) -ErrorAction SilentlyContinue
                    if ($process -and $process.MainWindowHandle -ne 0) {
                        Stop-Process -Force -Name ([string]$p.Name) -ErrorAction SilentlyContinue | Out-Null
                        $running = $false
                    }
                    Start-Sleep -Milliseconds 100
                    $timeout++
                    if ($timeout -gt [int]$p.TimeoutTicks) {
                        Stop-Process -Name ([string]$p.Name) -Force -ErrorAction SilentlyContinue
                        $running = $false
                    }
                } while ($running)
            }
            'AppxRegisterLike' {
                Get-AppXPackage -AllUsers | Where-Object { $_.Name -like [string]$p.NameLike } | ForEach-Object {
                    Add-AppxPackage -DisableDevelopmentMode -Register -ErrorAction SilentlyContinue "$($_.InstallLocation)\AppXManifest.xml"
                }
            }
            'AppxRegisterAll' {
                Get-AppxPackage -AllUsers | ForEach-Object {
                    Add-AppxPackage -DisableDevelopmentMode -Register -ErrorAction SilentlyContinue "$($_.InstallLocation)\AppXManifest.xml"
                } 2>$null
            }
            'StoreSettingsHiveImport' {
                Set-Content -Path ([string]$p.RegFile) -Value ([string]$p.RegContent) -Force
                reg load 'HKLM\Settings' ([string]$p.SettingsDat) >$null 2>&1
                if ($LASTEXITCODE -eq 0) {
                    reg import ([string]$p.RegFile) >$null 2>&1
                    [gc]::Collect()
                    Start-Sleep -Seconds 2
                    reg unload 'HKLM\Settings' >$null 2>&1
                }
            }
            'DisplayList' { }
            'DownloadFile' {
                Invoke-BoostLabBloatwareVerifiedArtifactDownload `
                    -ArtifactId ([string]$p.ArtifactId) `
                    -Destination ([string]$p.Destination) | Out-Null
            }
            default {
                return New-BoostLabBloatwareOperationResult -Operation $Operation -Success $false -Message "Unsupported operation type '$($Operation.Type)'."
            }
        }
        return New-BoostLabBloatwareOperationResult -Operation $Operation -Success $true -Message 'Operation completed.'
    }
    catch {
        return New-BoostLabBloatwareOperationResult -Operation $Operation -Success $false -Message $_.Exception.Message
    }
}

function Invoke-BoostLabBloatwareBranchWorkflow {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('RemoveAllBloatware', 'InstallStore', 'InstallAllUwpApps', 'OpenUwpFeatures', 'OpenLegacyFeatures', 'InstallOneDrive', 'InstallRemoteDesktopConnection', 'InstallSnippingTool')]
        [string]$Branch,

        [scriptblock]$OperationExecutor = $null,

        [bool]$SkipEnvironmentChecks = $false
    )

    $plan = Get-BoostLabBloatwareOperationPlan -Branch $Branch
    $operationResults = [System.Collections.Generic.List[object]]::new()
    $changesStarted = $false

    foreach ($operation in @($plan.Operations)) {
        if ($SkipEnvironmentChecks -and [string]$operation.Type -in @('RequireAdministrator', 'RequireInternet')) {
            $result = New-BoostLabBloatwareOperationResult -Operation $operation -Success $true -Message 'Skipped by test-safe executor option.'
        }
        elseif ($null -ne $OperationExecutor) {
            $result = & $OperationExecutor $operation $Branch $plan
        }
        else {
            $result = Invoke-BoostLabBloatwareRealOperation -Operation $operation
        }
        if ($null -eq $result) {
            $result = New-BoostLabBloatwareOperationResult -Operation $operation -Success $false -Message 'Operation executor returned no result.'
        }

        $operationResults.Add($result)
        if ([string]$operation.Type -notin @('RequireAdministrator', 'RequireInternet')) {
            $changesStarted = $true
        }

        if (-not [bool]$result.Success) {
            return [pscustomobject]@{
                Success = $false
                Branch = $Branch
                Plan = $plan
                OperationResults = $operationResults.ToArray()
                FailedOperation = $operation
                ChangesStarted = $changesStarted
                Message = "Operation failed: $($operation.Label). $($result.Message)"
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
        Message = "Bloatware branch '$($plan.BranchTitle)' completed."
    }
}

function Get-BoostLabBloatwareAnalysis {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabBloatwareSourceStatus
    $plans = Get-BoostLabBloatwareAllOperationPlans
    $downloadArtifacts = @($plans | ForEach-Object { $_.DownloadArtifacts } | Where-Object { $null -ne $_ })

    [pscustomobject]@{
        Mode = 'SourceEquivalentBranchRuntime'
        Source = $sourceStatus
        ApprovedSourceBranches = @($script:BoostLabBranchOrder)
        SourceMenuBranches = @($script:BoostLabToolMetadata.SelectionItems)
        OperationPlans = $plans
        DownloadArtifacts = $downloadArtifacts
        ArtifactPolicy = 'Downloaded EXEs are source-defined UltimateAuthorHostedArtifact entries and NeedsBoostLabMirror; no binaries, artifact provenance approvals, or production allowlist entries are added by this module.'
        SourceBehaviorSummary = @(
            'Preserves the source admin, internet, and password-sign-in registry preflight before every non-Exit branch.'
            'Preserves Remove all bloatware AppX, capability, optional feature, service, task, process, file, registry, MSI, OneDrive, Remote Desktop, Snipping Tool, and Windows 10 cleanup behavior.'
            'Preserves Install Store AppX re-registration, Store settings launch/stop, Store AutoDownload registry write, settings.dat hive import, and final Store settings launch.'
            'Preserves Install all UWP apps package re-registration.'
            'Preserves UWP optional features and legacy optional features page launch/list behavior for Windows 11 and Windows 10 lists.'
            'Preserves OneDrive, Remote Desktop Connection, and Snipping Tool install branches including source-defined downloads and installers.'
        )
        NoMutationOccurred = $true
        NoDownloadOccurred = $true
        NoInstallerExecutionOccurred = $true
        NoRegistryMutationOccurred = $true
        NoPackageMutationOccurred = $true
        NoFeatureMutationOccurred = $true
        NoServiceMutationOccurred = $true
        NoTaskMutationOccurred = $true
        NoProcessMutationOccurred = $true
        NoFileMutationOccurred = $true
        NoRebootOrSessionChangeOccurred = $true
    }
}

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        Id = [string]$script:BoostLabToolMetadata['Id']
        Title = [string]$script:BoostLabToolMetadata['Title']
        Stage = [string]$script:BoostLabToolMetadata['Stage']
        Order = [int]$script:BoostLabToolMetadata['Order']
        Type = [string]$script:BoostLabToolMetadata['Type']
        RiskLevel = [string]$script:BoostLabToolMetadata['RiskLevel']
        Description = [string]$script:BoostLabToolMetadata['Description']
        Actions = @($script:BoostLabToolMetadata['Actions'])
        SelectionMode = [string]$script:BoostLabToolMetadata['SelectionMode']
        SelectionRequiredActions = @($script:BoostLabToolMetadata['SelectionRequiredActions'])
        SelectionLabel = [string]$script:BoostLabToolMetadata['SelectionLabel']
        SelectionItems = @($script:BoostLabToolMetadata['SelectionItems'])
        Capabilities = $script:BoostLabToolMetadata['Capabilities']
        ImplementedActions = @($script:BoostLabImplementedActions)
        ConfirmationRequiredActions = @('Apply')
        ConfirmationText = 'Bloatware executes one selected source-equivalent high-risk branch after confirmation. It can remove packages/capabilities/features, alter registry/hives, stop services/tasks/processes, change ownership/ACLs, delete protected files, download source-defined EXEs, and run installers/uninstallers.'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabBloatwareSourceStatus
    [pscustomobject]@{
        Supported = $true
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason = 'Bloatware exact source-equivalent branch runtime is available after explicit confirmation and branch selection.'
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
        Status = 'SourceEquivalentBranchRuntime'
        LastAction = $null
        LastResult = $null
        RestartRequired = $false
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

        [string]$Branch = '',

        [string[]]$SelectedAppIds = @(),

        [scriptblock]$OperationExecutor = $null,

        [bool]$SkipEnvironmentChecks = $false
    )

    $canonicalAction = switch ($ActionName) {
        'Apply Source Branch' { 'Apply' }
        default { $ActionName }
    }

    if ($canonicalAction -notin @('Analyze', 'Apply')) {
        return New-BoostLabBloatwareResult `
            -Success $false `
            -Action $ActionName `
            -Status 'UnsupportedAction' `
            -CommandStatus 'Blocked' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Unsupported action. Bloatware exposes only Analyze and Apply; the Ultimate source has no Open, Default, or Restore branch.'
    }

    $sourceStatus = Get-BoostLabBloatwareSourceStatus
    if ([string]$sourceStatus.ChecksumStatus -ne 'Passed') {
        return New-BoostLabBloatwareResult `
            -Success $false `
            -Action $canonicalAction `
            -Status 'SourceMismatch' `
            -CommandStatus 'Blocked' `
            -VerificationStatus 'Failed' `
            -Message 'Bloatware source checksum verification failed; no operation executed.' `
            -Data ([pscustomobject]@{ Source = $sourceStatus }) `
            -Errors @('Approved Bloatware Ultimate source checksum verification failed.')
    }

    if ($canonicalAction -eq 'Analyze') {
        $analysis = Get-BoostLabBloatwareAnalysis
        return New-BoostLabBloatwareResult `
            -Success $true `
            -Action 'Analyze' `
            -Status 'Success' `
            -CommandStatus 'ReadOnly' `
            -VerificationStatus 'Passed' `
            -Message 'Bloatware source-equivalent branch analysis completed without executing package, registry, service, task, file, download, installer, or process operations.' `
            -Data $analysis
    }

    $normalizedBranch = ConvertTo-BoostLabBloatwareBranch -Branch $Branch -SelectedAppIds $SelectedAppIds
    if ($normalizedBranch -notin $script:BoostLabBranchOrder) {
        return New-BoostLabBloatwareResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'NeedsBranchSelection' `
            -CommandStatus 'Blocked' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Apply requires selecting exactly one Bloatware source branch. No package, registry, service, task, file, download, installer, process, or system operation executed.' `
            -Data ([pscustomobject]@{ AllowedBranches = @($script:BoostLabBranchOrder); SelectedBranch = $Branch; SelectedAppIds = @($SelectedAppIds) })
    }

    if (-not $Confirmed) {
        return New-BoostLabBloatwareResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'Cancelled' `
            -CommandStatus 'Cancelled before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message "Bloatware Apply for '$($script:BoostLabBranchTitles[$normalizedBranch])' was cancelled before execution." `
            -Cancelled $true `
            -Data ([pscustomobject]@{ Branch = $normalizedBranch })
    }

    $workflow = Invoke-BoostLabBloatwareBranchWorkflow `
        -Branch $normalizedBranch `
        -OperationExecutor $OperationExecutor `
        -SkipEnvironmentChecks:$SkipEnvironmentChecks

    if (-not [bool]$workflow.Success) {
        return New-BoostLabBloatwareResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'OperationFailed' `
            -CommandStatus 'Completed with errors' `
            -VerificationStatus 'Failed' `
            -Message $workflow.Message `
            -Data $workflow `
            -Errors @($workflow.Message) `
            -ChangesExecuted ([bool]$workflow.ChangesStarted)
    }

    return New-BoostLabBloatwareResult `
        -Success $true `
        -Action 'Apply' `
        -Status 'Success' `
        -CommandStatus 'Completed' `
        -VerificationStatus 'Passed' `
        -Message $workflow.Message `
        -Data $workflow `
        -ChangesExecuted ([bool]$workflow.ChangesStarted)
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    Invoke-BoostLabToolAction -ActionName 'Restore'
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
    'Get-BoostLabBloatwareSourceStatus'
    'Get-BoostLabBloatwareAnalysis'
    'Get-BoostLabBloatwareOperationPlan'
    'Get-BoostLabBloatwareAllOperationPlans'
    'Invoke-BoostLabBloatwareBranchWorkflow'
    'Invoke-BoostLabBloatwareRemoveAppxExcept'
)

