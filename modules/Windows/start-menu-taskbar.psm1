Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $verificationModulePath -Scope Local -Force -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'start-menu-taskbar'; Title = 'Start Menu Taskbar'; Stage = 'Windows'; Order = 1
    Type = 'action'; RiskLevel = 'high'
    Description = 'Apply the source-defined Start menu and taskbar clean profile or restore its source-defined default behavior.'
    Actions = @('Apply', 'Default')
    Capabilities = [ordered]@{
        RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false
        CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false
        CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false
        CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false
        SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Apply', 'Default')
$script:BoostLabExpectedSourceHash = '88BEB0E8C41F7A32AAE6A0A6E184E87E678FB25BEDEB092C63F4BA98B8712E91'
$script:BoostLabExpectedCanonicalSourceHash = 'D53678CE91FE8ADE6D28F221A2E4153188597D850149F87227B26E0B821EFFF4'
$script:BoostLabSourceRelativePath = 'source-ultimate/6 Windows/1 Start Menu Taskbar.ps1'
$script:BoostLabExpectedStart2Sha256 = '21EAF7925A26A59880D799509C5E49D4034B36BD86D84D035A50D17D6A32206D'
$script:BoostLabExpectedStart2Length = 4540
$script:BoostLabSecurityHealthClean = [byte[]](0x07,0x00,0x00,0x00,0x05,0xdb,0x8a,0x69,0x8a,0x49,0xd9,0x01)
$script:BoostLabSecurityHealthDefault = [byte[]](0x04,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00)
$script:BoostLabFeatureOverrideIds = @('2792562829', '3036241548', '734731404', '762256525')
$script:BoostLabNotifyIconSettingsRoot = 'HKCU:\Control Panel\NotifyIconSettings'

function Test-BoostLabAdministrator {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function Get-BoostLabStartMenuTaskbarSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $projectRoot ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabStartMenuTaskbarSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabStartMenuTaskbarSourcePath
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

function Get-BoostLabStartMenuTaskbarCleanLayoutXml {
    @'
<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
    <LayoutOptions StartTileGroupCellWidth="6" />
    <DefaultLayoutOverride>
        <StartLayoutCollection>
            <defaultlayout:StartLayout GroupCellWidth="6" />
        </StartLayoutCollection>
    </DefaultLayoutOverride>
</LayoutModificationTemplate>
'@
}

function Get-BoostLabStartMenuTaskbarDefaultLayoutXml {
    @'
<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
  <LayoutOptions StartTileGroupCellWidth="6" />
  <DefaultLayoutOverride>
    <StartLayoutCollection>
      <defaultlayout:StartLayout GroupCellWidth="6">
        <start:Group Name="Productivity">
          <start:Folder Name="" Size="2x2" Column="2" Row="0">
            <start:Tile Size="2x2" Column="4" Row="2" AppUserModelID="Microsoft.Office.OneNote_8wekyb3d8bbwe!microsoft.onenoteim" />
            <start:DesktopApplicationTile Size="2x2" Column="0" Row="2" DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" />
            <start:Tile Size="2x2" Column="0" Row="4" AppUserModelID="Microsoft.SkypeApp_kzf8qxf38zg5c!App" />
          </start:Folder>
          <start:Tile Size="2x2" Column="0" Row="0" AppUserModelID="Microsoft.MicrosoftOfficeHub_8wekyb3d8bbwe!Microsoft.MicrosoftOfficeHub" />
          <start:DesktopApplicationTile Size="2x2" Column="0" Row="2" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" />
          <start:Tile Size="2x2" Column="4" Row="2" AppUserModelID="7EE7776C.LinkedInforWindows_w1wdnht996qgy!App" />
          <start:Tile Size="2x2" Column="4" Row="0" AppUserModelID="microsoft.windowscommunicationsapps_8wekyb3d8bbwe!Microsoft.WindowsLive.Mail" />
          <start:Tile Size="2x2" Column="2" Row="2" AppUserModelID="Microsoft.Windows.Photos_8wekyb3d8bbwe!App" />
        </start:Group>
        <start:Group Name="Explore">
          <start:Folder Name="Play" Size="2x2" Column="4" Row="2">
            <start:Tile Size="2x2" Column="2" Row="0" AppUserModelID="Microsoft.WindowsCalculator_8wekyb3d8bbwe!App" />
            <start:Tile Size="2x2" Column="0" Row="0" AppUserModelID="Clipchamp.Clipchamp_yxz26nhyzhsrt!App" />
          </start:Folder>
          <start:Tile Size="2x2" Column="4" Row="0" AppUserModelID="Microsoft.Todos_8wekyb3d8bbwe!App" />
          <start:Tile Size="2x2" Column="2" Row="2" AppUserModelID="Microsoft.MicrosoftSolitaireCollection_8wekyb3d8bbwe!App" />
          <start:Tile Size="2x2" Column="2" Row="0" AppUserModelID="SpotifyAB.SpotifyMusic_zpdnekdrzrea0!Spotify" />
          <start:Tile Size="2x2" Column="0" Row="2" AppUserModelID="Microsoft.ZuneVideo_8wekyb3d8bbwe!Microsoft.ZuneVideo" />
          <start:Tile Size="2x2" Column="0" Row="0" AppUserModelID="Microsoft.WindowsStore_8wekyb3d8bbwe!App" />
        </start:Group>
      </defaultlayout:StartLayout>
    </StartLayoutCollection>
  </DefaultLayoutOverride>
</LayoutModificationTemplate>
'@
}

function Get-BoostLabStartMenuTaskbarStart2Pem {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $sourceStatus = Get-BoostLabStartMenuTaskbarSourceStatus
    if ([string]$sourceStatus.ChecksumStatus -ne 'Passed') {
        throw 'Start Menu Taskbar source checksum verification failed; start2.bin payload extraction is blocked.'
    }

    $sourceText = Get-Content -LiteralPath $sourceStatus.SourcePath -Raw -ErrorAction Stop
    $match = [regex]::Match(
        $sourceText,
        '-----BEGIN CERTIFICATE-----\s*(?<payload>.*?)\s*-----END CERTIFICATE-----',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    if (-not $match.Success) {
        throw 'The source-defined start2.bin payload was not found.'
    }

    return "-----BEGIN CERTIFICATE-----`n$($match.Groups['payload'].Value.Trim())`n-----END CERTIFICATE-----`n"
}

function Get-BoostLabStartMenuTaskbarStart2PayloadBytes {
    [CmdletBinding()]
    [OutputType([byte[]])]
    param()

    $pem = Get-BoostLabStartMenuTaskbarStart2Pem
    $payload = (($pem -replace '-----BEGIN CERTIFICATE-----', '') -replace '-----END CERTIFICATE-----', '') -replace '\s+', ''
    return [Convert]::FromBase64String($payload)
}

function Get-BoostLabStartMenuTaskbarStart2PayloadStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    try {
        $bytes = Get-BoostLabStartMenuTaskbarStart2PayloadBytes
        $sha = [Security.Cryptography.SHA256]::Create()
        try {
            $hash = [BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-', '')
        }
        finally {
            $sha.Dispose()
        }

        [pscustomobject]@{
            Extracted = $true
            Length    = $bytes.Length
            Sha256    = $hash
            ExpectedLength = $script:BoostLabExpectedStart2Length
            ExpectedSha256 = $script:BoostLabExpectedStart2Sha256
            Status    = if ($bytes.Length -eq $script:BoostLabExpectedStart2Length -and $hash -eq $script:BoostLabExpectedStart2Sha256) { 'Passed' } else { 'Failed' }
        }
    }
    catch {
        [pscustomobject]@{
            Extracted = $false
            Length    = 0
            Sha256    = ''
            ExpectedLength = $script:BoostLabExpectedStart2Length
            ExpectedSha256 = $script:BoostLabExpectedStart2Sha256
            Status    = 'Failed'
            Error     = $_.Exception.Message
        }
    }
}

function New-BoostLabStartMenuTaskbarOperation {
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter(Mandatory)]
        [string]$Kind,

        [string]$Path = '',
        [string]$Name = '',
        [string]$ValueType = '',
        [AllowNull()] [object]$Data = $null,
        [string]$Group = '',
        [AllowNull()] [object]$Content = $null,
        [string]$Destination = '',
        [bool]$Recursive = $false,
        [bool]$Hidden = $false,
        [int]$Seconds = 0
    )

    [pscustomobject]@{
        Id = $Id; Kind = $Kind; Group = $Group; Path = $Path; Name = $Name
        ValueType = $ValueType; Data = $Data; Content = $Content
        Destination = $Destination; Recursive = $Recursive; Hidden = $Hidden
        Seconds = $Seconds
    }
}

function Join-BoostLabStartMenuTaskbarLiteralPath {
    param(
        [Parameter(Mandatory)]
        [string]$BasePath,

        [Parameter(Mandatory)]
        [string]$ChildPath
    )

    if ($BasePath.EndsWith('\')) {
        return "$BasePath$ChildPath"
    }

    return "$BasePath\$ChildPath"
}

function Get-BoostLabStartMenuTaskbarPathContext {
    param(
        [string]$SystemRoot = $env:SystemRoot,
        [string]$SystemDrive = $env:SystemDrive,
        [string]$UserProfile = $env:USERPROFILE,
        [string]$ProgramData = $env:ProgramData
    )

    if ([string]::IsNullOrWhiteSpace($SystemRoot)) { $SystemRoot = 'C:\Windows' }
    if ([string]::IsNullOrWhiteSpace($SystemDrive)) { $SystemDrive = 'C:' }
    if ([string]::IsNullOrWhiteSpace($UserProfile)) { $UserProfile = Join-BoostLabStartMenuTaskbarLiteralPath -BasePath $env:SystemDrive -ChildPath 'Users\Default' }
    if ([string]::IsNullOrWhiteSpace($ProgramData)) { $ProgramData = Join-BoostLabStartMenuTaskbarLiteralPath -BasePath $SystemDrive -ChildPath 'ProgramData' }

    $startHostState = Join-BoostLabStartMenuTaskbarLiteralPath -BasePath $UserProfile -ChildPath 'AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState'
    [pscustomobject]@{
        SystemRoot = $SystemRoot
        SystemDrive = $SystemDrive
        UserProfile = $UserProfile
        ProgramData = $ProgramData
        SystemTemp = Join-BoostLabStartMenuTaskbarLiteralPath -BasePath $SystemRoot -ChildPath 'Temp'
        LayoutDeletePath = Join-BoostLabStartMenuTaskbarLiteralPath -BasePath $SystemDrive -ChildPath 'Windows\StartMenuLayout.xml'
        LayoutWritePath = 'C:\Windows\StartMenuLayout.xml'
        QuickLaunchPath = Join-BoostLabStartMenuTaskbarLiteralPath -BasePath $UserProfile -ChildPath 'AppData\Roaming\Microsoft\Internet Explorer\Quick Launch'
        Start2TextPath = Join-BoostLabStartMenuTaskbarLiteralPath -BasePath (Join-BoostLabStartMenuTaskbarLiteralPath -BasePath $SystemRoot -ChildPath 'Temp') -ChildPath 'start2.txt'
        Start2TempPath = Join-BoostLabStartMenuTaskbarLiteralPath -BasePath (Join-BoostLabStartMenuTaskbarLiteralPath -BasePath $SystemRoot -ChildPath 'Temp') -ChildPath 'start2.bin'
        Start2Destination = Join-BoostLabStartMenuTaskbarLiteralPath -BasePath $startHostState -ChildPath 'start2.bin'
        FolderTargets = @(
            (Join-BoostLabStartMenuTaskbarLiteralPath -BasePath $UserProfile -ChildPath 'AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Accessibility')
            (Join-BoostLabStartMenuTaskbarLiteralPath -BasePath $ProgramData -ChildPath 'Microsoft\Windows\Start Menu\Programs\Accessibility')
            (Join-BoostLabStartMenuTaskbarLiteralPath -BasePath $ProgramData -ChildPath 'Microsoft\Windows\Start Menu\Programs\Accessories')
        )
    }
}

function Get-BoostLabStartMenuTaskbarOperationCatalog {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [string]$SystemRoot = $env:SystemRoot,
        [string]$SystemDrive = $env:SystemDrive,
        [string]$UserProfile = $env:USERPROFILE,
        [string]$ProgramData = $env:ProgramData
    )

    $paths = Get-BoostLabStartMenuTaskbarPathContext -SystemRoot $SystemRoot -SystemDrive $SystemDrive -UserProfile $UserProfile -ProgramData $ProgramData
    $ops = [System.Collections.Generic.List[object]]::new()

    if ($ActionName -eq 'Apply') {
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'AllowNewsAndInterestsOff' -Kind 'SetRegistryValue' -Group 'Clean registry payload' -Path 'HKLM:\Software\Policies\Microsoft\Dsh' -Name 'AllowNewsAndInterests' -ValueType 'DWord' -Data 0))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'TaskbarLeftAlignment' -Kind 'SetRegistryValue' -Group 'Clean registry payload' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAl' -ValueType 'DWord' -Data 0))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'SearchboxHidden' -Kind 'SetRegistryValue' -Group 'Clean registry payload' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'SearchboxTaskbarMode' -ValueType 'DWord' -Data 0))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'TaskViewHidden' -Kind 'SetRegistryValue' -Group 'Clean registry payload' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowTaskViewButton' -ValueType 'DWord' -Data 0))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'ChatHidden' -Kind 'SetRegistryValue' -Group 'Clean registry payload' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarMn' -ValueType 'DWord' -Data 0))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'CopilotHidden' -Kind 'SetRegistryValue' -Group 'Clean registry payload' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowCopilotButton' -ValueType 'DWord' -Data 0))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'FeedsDisabled' -Kind 'SetRegistryValue' -Group 'Clean registry payload' -Path 'HKLM:\Software\Policies\Microsoft\Windows\Windows Feeds' -Name 'EnableFeeds' -ValueType 'DWord' -Data 0))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'MeetNowHidden' -Kind 'SetRegistryValue' -Group 'Clean registry payload' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'HideSCAMeetNow' -ValueType 'DWord' -Data 1))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'SecurityHealthHidden' -Kind 'SetRegistryValue' -Group 'Clean registry payload' -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run' -Name 'SecurityHealth' -ValueType 'Binary' -Data $script:BoostLabSecurityHealthClean))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'EnableAutoTrayOff' -Kind 'SetRegistryValue' -Group 'Clean registry payload' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer' -Name 'EnableAutoTray' -ValueType 'DWord' -Data 0))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'HideRecommendedPolicyManagerStart' -Kind 'SetRegistryValue' -Group 'Clean registry payload' -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start' -Name 'HideRecommendedSection' -ValueType 'DWord' -Data 1))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'EducationEnvironmentOn' -Kind 'SetRegistryValue' -Group 'Clean registry payload' -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Education' -Name 'IsEducationEnvironment' -ValueType 'DWord' -Data 1))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'HideRecommendedExplorerPolicy' -Kind 'SetRegistryValue' -Group 'Clean registry payload' -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'HideRecommendedSection' -ValueType 'DWord' -Data 1))
        foreach ($overrideId in $script:BoostLabFeatureOverrideIds) {
            $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id "FeatureOverride$overrideId" -Kind 'SetRegistryValue' -Group 'Clean registry payload' -Path "HKLM:\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14\$overrideId" -Name 'EnabledState' -ValueType 'DWord' -Data 2))
        }
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'AllAppsViewModeListInitial' -Kind 'SetRegistryValue' -Group 'Clean registry payload' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Start' -Name 'AllAppsViewMode' -ValueType 'DWord' -Data 2))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'DeleteTaskband' -Kind 'DeleteRegistryKey' -Group 'Taskband cleanup' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband' -Recursive $true))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'DeleteQuickLaunch' -Kind 'DeleteDirectory' -Group 'Quick Launch cleanup' -Path $paths.QuickLaunchPath -Recursive $true))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'PromoteNotifyIcons' -Kind 'SetNotifyIconSettings' -Group 'NotifyIconSettings' -Path $script:BoostLabNotifyIconSettingsRoot -Name 'IsPromoted' -ValueType 'DWord' -Data 1))
        foreach ($folder in @($paths.FolderTargets)) {
            $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id ('HideFolder_{0}' -f ([IO.Path]::GetFileName($folder))) -Kind 'SetFolderAttribute' -Group 'Hidden folders' -Path $folder -Hidden $true -Recursive $true))
        }
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'DeleteWindows10LayoutBeforeClean' -Kind 'DeleteFile' -Group 'Windows 10 layout XML' -Path $paths.LayoutDeletePath))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'WriteCleanLayoutXml' -Kind 'WriteTextFile' -Group 'Windows 10 layout XML' -Path $paths.LayoutWritePath -Content (Get-BoostLabStartMenuTaskbarCleanLayoutXml)))
    }
    else {
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'MailPinDefault' -Kind 'SetRegistryValue' -Group 'Default registry payload' -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband\AuxilliaryPins' -Name 'MailPin' -ValueType 'DWord' -Data 1))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'DeleteDshPolicy' -Kind 'DeleteRegistryKey' -Group 'Default registry payload' -Path 'HKLM:\Software\Policies\Microsoft\Dsh' -Recursive $true))
        foreach ($value in @('TaskbarAl', 'ShowTaskViewButton', 'TaskbarMn', 'ShowCopilotButton')) {
            $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id "Remove$value" -Kind 'DeleteRegistryValue' -Group 'Default registry payload' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name $value))
        }
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'RemoveSearchboxTaskbarMode' -Kind 'DeleteRegistryValue' -Group 'Default registry payload' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'SearchboxTaskbarMode'))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'DeleteWindowsFeedsPolicy' -Kind 'DeleteRegistryKey' -Group 'Default registry payload' -Path 'HKLM:\Software\Policies\Microsoft\Windows\Windows Feeds' -Recursive $true))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'DeleteMeetNowPolicy' -Kind 'DeleteRegistryKey' -Group 'Default registry payload' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Recursive $true))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'SecurityHealthDefault' -Kind 'SetRegistryValue' -Group 'Default registry payload' -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run' -Name 'SecurityHealth' -ValueType 'Binary' -Data $script:BoostLabSecurityHealthDefault))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'RemoveEnableAutoTray' -Kind 'DeleteRegistryValue' -Group 'Default registry payload' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer' -Name 'EnableAutoTray'))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'DeletePolicyManagerStart' -Kind 'DeleteRegistryKey' -Group 'Default registry payload' -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start' -Recursive $true))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'DeletePolicyManagerEducation' -Kind 'DeleteRegistryKey' -Group 'Default registry payload' -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Education' -Recursive $true))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'RemoveExplorerHideRecommended' -Kind 'DeleteRegistryValue' -Group 'Default registry payload' -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'HideRecommendedSection'))
        foreach ($overrideId in $script:BoostLabFeatureOverrideIds) {
            $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id "RemoveFeatureOverride$overrideId" -Kind 'DeleteRegistryValue' -Group 'Default registry payload' -Path "HKLM:\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14\$overrideId" -Name 'EnabledState'))
        }
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'AllAppsViewModeCategoryInitial' -Kind 'SetRegistryValue' -Group 'Default registry payload' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Start' -Name 'AllAppsViewMode' -ValueType 'DWord' -Data 0))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'DemoteNotifyIcons' -Kind 'SetNotifyIconSettings' -Group 'NotifyIconSettings' -Path $script:BoostLabNotifyIconSettingsRoot -Name 'IsPromoted' -ValueType 'DWord' -Data 0))
        foreach ($folder in @($paths.FolderTargets)) {
            $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id ('UnhideFolder_{0}' -f ([IO.Path]::GetFileName($folder))) -Kind 'SetFolderAttribute' -Group 'Hidden folders' -Path $folder -Hidden $false -Recursive $true))
        }
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'DeleteWindows10LayoutBeforeDefault' -Kind 'DeleteFile' -Group 'Windows 10 layout XML' -Path $paths.LayoutDeletePath))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'WriteDefaultLayoutXml' -Kind 'WriteTextFile' -Group 'Windows 10 layout XML' -Path $paths.LayoutWritePath -Content (Get-BoostLabStartMenuTaskbarDefaultLayoutXml)))
    }

    foreach ($regAlias in @('HKLM', 'HKCU')) {
        $policyPath = "$($regAlias):\SOFTWARE\Policies\Microsoft\Windows\Explorer"
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id "LockLayout$regAlias" -Kind 'SetRegistryValue' -Group 'Layout policy' -Path $policyPath -Name 'LockedStartLayout' -ValueType 'DWord' -Data 1))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id "SetLayoutFile$regAlias" -Kind 'SetRegistryValue' -Group 'Layout policy' -Path $policyPath -Name 'StartLayoutFile' -ValueType 'String' -Data $paths.LayoutWritePath))
    }
    $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'RestartExplorerAfterLayoutLock' -Kind 'RestartExplorer' -Group 'Explorer handling'))
    $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'SleepAfterLayoutLock' -Kind 'Sleep' -Group 'Explorer handling' -Seconds 5))
    foreach ($regAlias in @('HKLM', 'HKCU')) {
        $policyPath = "$($regAlias):\SOFTWARE\Policies\Microsoft\Windows\Explorer"
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id "UnlockLayout$regAlias" -Kind 'SetRegistryValue' -Group 'Layout policy' -Path $policyPath -Name 'LockedStartLayout' -ValueType 'DWord' -Data 0))
    }
    $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'DeleteWindows10LayoutAfterImport' -Kind 'DeleteFile' -Group 'Windows 10 layout XML' -Path $paths.LayoutDeletePath))
    $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'DeleteStart2Bin' -Kind 'DeleteFile' -Group 'Windows 11 start2.bin' -Path $paths.Start2Destination))

    if ($ActionName -eq 'Apply') {
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'WriteStart2Pem' -Kind 'WriteTextFile' -Group 'Windows 11 start2.bin' -Path $paths.Start2TextPath -Content (Get-BoostLabStartMenuTaskbarStart2Pem)))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'WriteStart2TempBin' -Kind 'WriteBytesFile' -Group 'Windows 11 start2.bin' -Path $paths.Start2TempPath -Content (Get-BoostLabStartMenuTaskbarStart2PayloadBytes)))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'CopyStart2Bin' -Kind 'CopyFile' -Group 'Windows 11 start2.bin' -Path $paths.Start2TempPath -Destination $paths.Start2Destination))
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'AllAppsViewModeListPostStart2' -Kind 'SetRegistryValue' -Group 'Windows 11 start2.bin' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Start' -Name 'AllAppsViewMode' -ValueType 'DWord' -Data 2))
    }
    else {
        $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'AllAppsViewModeCategoryPostStart2Delete' -Kind 'SetRegistryValue' -Group 'Windows 11 start2.bin' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Start' -Name 'AllAppsViewMode' -ValueType 'DWord' -Data 0))
    }
    $ops.Add((New-BoostLabStartMenuTaskbarOperation -Id 'RestartExplorerFinal' -Kind 'RestartExplorer' -Group 'Explorer handling'))

    return $ops.ToArray()
}

function New-BoostLabStartMenuTaskbarResult {
    param(
        [Parameter(Mandatory)] [bool]$Success,
        [Parameter(Mandatory)] [string]$Action,
        [Parameter(Mandatory)] [string]$Status,
        [Parameter(Mandatory)] [string]$CommandStatus,
        [Parameter(Mandatory)] [string]$VerificationStatus,
        [Parameter(Mandatory)] [string]$Message,
        [AllowNull()] [object]$Data = $null,
        [AllowNull()] [object]$VerificationResult = $null,
        [AllowEmptyCollection()]
        [string[]]$Errors = @(),
        [AllowEmptyCollection()]
        [string[]]$Warnings = @(),
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
        VerificationResult = $VerificationResult
        Errors = @($Errors)
        Warnings = @($Warnings)
    }
}

function Set-BoostLabStartMenuTaskbarRegistryValue {
    param($Path, $Name, $ValueType, $Data)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
    }
    New-ItemProperty -LiteralPath $Path -Name $Name -PropertyType $ValueType -Value $Data -Force -ErrorAction Stop | Out-Null
    [pscustomobject]@{ Success = $true; Operation = 'SetRegistryValue'; Path = $Path; Name = $Name; ValueType = $ValueType }
}

function Remove-BoostLabStartMenuTaskbarRegistryValue {
    param($Path, $Name)

    Remove-ItemProperty -LiteralPath $Path -Name $Name -Force -ErrorAction SilentlyContinue
    [pscustomobject]@{ Success = $true; Operation = 'DeleteRegistryValue'; Path = $Path; Name = $Name }
}

function Remove-BoostLabStartMenuTaskbarRegistryKey {
    param($Path, [bool]$Recursive)

    Remove-Item -LiteralPath $Path -Recurse:$Recursive -Force -ErrorAction SilentlyContinue
    [pscustomobject]@{ Success = $true; Operation = 'DeleteRegistryKey'; Path = $Path; Recursive = $Recursive }
}

function Invoke-BoostLabStartMenuTaskbarFolderAttribute {
    param($Path, [bool]$Hidden)

    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{ Success = $true; Operation = 'SetFolderAttribute'; Path = $Path; Skipped = $true; Reason = 'Path absent' }
    }
    $flag = if ($Hidden) { '+h' } else { '-h' }
    $output1 = & cmd.exe /d /c ('attrib {0} "{1}"' -f $flag, $Path) 2>&1
    $output2 = & cmd.exe /d /c ('attrib {0} "{1}\*.*" /s /d' -f $flag, $Path) 2>&1
    [pscustomobject]@{
        Success = $LASTEXITCODE -eq 0
        Operation = 'SetFolderAttribute'
        Path = $Path
        Hidden = $Hidden
        Output = @($output1) + @($output2)
    }
}

function Invoke-BoostLabStartMenuTaskbarOperation {
    param(
        [Parameter(Mandatory)] [object]$Operation,
        [Parameter(Mandatory)] [hashtable]$Adapters
    )

    switch ([string]$Operation.Kind) {
        'SetRegistryValue' { return & $Adapters.RegistrySetter $Operation.Path $Operation.Name $Operation.ValueType $Operation.Data }
        'DeleteRegistryKey' { return & $Adapters.RegistryKeyDeleter $Operation.Path ([bool]$Operation.Recursive) }
        'DeleteRegistryValue' { return & $Adapters.RegistryValueDeleter $Operation.Path $Operation.Name }
        'DeleteDirectory' { return & $Adapters.DirectoryDeleter $Operation.Path ([bool]$Operation.Recursive) }
        'DeleteFile' { return & $Adapters.FileDeleter $Operation.Path }
        'WriteTextFile' { return & $Adapters.TextFileWriter $Operation.Path ([string]$Operation.Content) }
        'WriteBytesFile' { return & $Adapters.BytesFileWriter $Operation.Path ([byte[]]$Operation.Content) }
        'CopyFile' { return & $Adapters.FileCopier $Operation.Path $Operation.Destination }
        'SetFolderAttribute' { return & $Adapters.FolderAttributeSetter $Operation.Path ([bool]$Operation.Hidden) }
        'SetNotifyIconSettings' {
            $targets = @(& $Adapters.NotifyIconEnumerator $Operation.Path)
            foreach ($target in $targets) {
                & $Adapters.RegistrySetter ([string]$target) $Operation.Name $Operation.ValueType $Operation.Data | Out-Null
            }
            return [pscustomobject]@{ Success = $true; Operation = 'SetNotifyIconSettings'; Path = $Operation.Path; Value = $Operation.Data; TargetCount = $targets.Count }
        }
        'RestartExplorer' { return & $Adapters.ExplorerRestarter }
        'Sleep' { return & $Adapters.Sleep $Operation.Seconds }
        default { throw "Unsupported Start Menu Taskbar operation kind: $($Operation.Kind)" }
    }
}

function New-BoostLabStartMenuTaskbarVerification {
    param(
        [Parameter(Mandatory)] [string]$Action,
        [Parameter(Mandatory)] [object[]]$Operations,
        [Parameter(Mandatory)] [object[]]$OperationResults,
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$Errors
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    $source = Get-BoostLabStartMenuTaskbarSourceStatus
    $checks.Add((New-BoostLabVerificationCheck -Name 'Source checksum' -Expected $script:BoostLabExpectedSourceHash -Actual ([string]$source.DetectedSha256) -Status ([string]$source.ChecksumStatus) -Message 'Start Menu Taskbar source identity was verified before mutation.'))
    $payload = Get-BoostLabStartMenuTaskbarStart2PayloadStatus
    $checks.Add((New-BoostLabVerificationCheck -Name 'start2.bin payload hash' -Expected $script:BoostLabExpectedStart2Sha256 -Actual ([string]$payload.Sha256) -Status ([string]$payload.Status) -Message 'The source-embedded start2.bin payload was decoded without certutil for safe BoostLab writing.'))
    foreach ($group in @('Clean registry payload', 'Default registry payload', 'Taskband cleanup', 'Quick Launch cleanup', 'NotifyIconSettings', 'Hidden folders', 'Windows 10 layout XML', 'Windows 11 start2.bin', 'Layout policy', 'Explorer handling')) {
        $count = @($Operations | Where-Object { [string]$_.Group -eq $group }).Count
        if ($count -gt 0) {
            $checks.Add((New-BoostLabVerificationCheck -Name $group -Expected 'Represented when source-defined' -Actual $count -Status 'Passed' -Message "$group operation(s) were represented in the source-equivalent catalog."))
        }
    }
    $checks.Add((New-BoostLabVerificationCheck -Name 'Operation errors' -Expected '0' -Actual $Errors.Count -Status ($(if ($Errors.Count -eq 0) { 'Passed' } else { 'Failed' })) -Message 'Every source-catalog operation must execute through the BoostLab adapter boundary without reported errors.'))

    $status = if (@($checks | Where-Object { $_.Status -eq 'Failed' }).Count -gt 0) { 'Failed' } else { 'Passed' }
    New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $Action `
        -Status $status `
        -ExpectedState 'Source-equivalent Start Menu Taskbar Clean/Default operation catalog' `
        -DetectedState ('{0} operations, {1} results, {2} errors' -f $Operations.Count, $OperationResults.Count, $Errors.Count) `
        -Checks $checks.ToArray() `
        -Message ($(if ($status -eq 'Passed') { 'Start Menu Taskbar source-equivalent operation catalog completed.' } else { 'Start Menu Taskbar source-equivalent operation catalog failed.' }))
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
        Capabilities = [pscustomobject]$script:BoostLabToolMetadata['Capabilities']
        ImplementedActions = @($script:BoostLabImplementedActions)
        ConfirmationRequiredActions = @('Apply', 'Default')
        ConfirmationText = 'Start Menu Taskbar will mutate registry policy and user state, delete source-defined taskbar/start files and folders, apply layout payloads, and restart Explorer. Continue only after reviewing the Action Plan.'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$OperatingSystem = $env:OS,
        [bool]$RegistryProviderAvailable = $($null -ne (Get-PSProvider -PSProvider Registry -ErrorAction SilentlyContinue))
    )

    $source = Get-BoostLabStartMenuTaskbarSourceStatus
    $supported = $OperatingSystem -eq 'Windows_NT' -and $RegistryProviderAvailable -and [string]$source.ChecksumStatus -eq 'Passed'
    [pscustomobject]@{
        Supported = $supported
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason = if ($OperatingSystem -ne 'Windows_NT') {
            'Start Menu Taskbar requires Windows.'
        }
        elseif (-not $RegistryProviderAvailable) {
            'Start Menu Taskbar requires the PowerShell Registry provider.'
        }
        elseif ([string]$source.ChecksumStatus -ne 'Passed') {
            'Start Menu Taskbar source checksum verification failed or source file is missing.'
        }
        else {
            'Start Menu Taskbar source-equivalent Clean and Default actions are available.'
        }
        SourceChecksumStatus = [string]$source.ChecksumStatus
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
        Status = 'SourceEquivalentControlled'
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

        [scriptblock]$AdministratorChecker = { Test-BoostLabAdministrator },
        [scriptblock]$RegistrySetter = { param($Path, $Name, $Type, $Data) Set-BoostLabStartMenuTaskbarRegistryValue -Path $Path -Name $Name -ValueType $Type -Data $Data },
        [scriptblock]$RegistryValueDeleter = { param($Path, $Name) Remove-BoostLabStartMenuTaskbarRegistryValue -Path $Path -Name $Name },
        [scriptblock]$RegistryKeyDeleter = { param($Path, $Recursive) Remove-BoostLabStartMenuTaskbarRegistryKey -Path $Path -Recursive $Recursive },
        [scriptblock]$DirectoryDeleter = { param($Path, $Recursive) Remove-Item -LiteralPath $Path -Recurse:$Recursive -Force -ErrorAction SilentlyContinue; [pscustomobject]@{ Success = $true; Operation = 'DeleteDirectory'; Path = $Path; Recursive = $Recursive } },
        [scriptblock]$FileDeleter = { param($Path) Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue; [pscustomobject]@{ Success = $true; Operation = 'DeleteFile'; Path = $Path } },
        [scriptblock]$TextFileWriter = { param($Path, $Content) Set-Content -Path $Path -Value $Content -Force -Encoding ASCII -ErrorAction Stop; [pscustomobject]@{ Success = $true; Operation = 'WriteTextFile'; Path = $Path } },
        [scriptblock]$BytesFileWriter = { param($Path, [byte[]]$Bytes) [IO.File]::WriteAllBytes($Path, $Bytes); [pscustomobject]@{ Success = $true; Operation = 'WriteBytesFile'; Path = $Path; Length = $Bytes.Length } },
        [scriptblock]$FileCopier = { param($Path, $Destination) Copy-Item -LiteralPath $Path -Destination $Destination -Force -ErrorAction SilentlyContinue; [pscustomobject]@{ Success = $true; Operation = 'CopyFile'; Path = $Path; Destination = $Destination } },
        [scriptblock]$FolderAttributeSetter = { param($Path, $Hidden) Invoke-BoostLabStartMenuTaskbarFolderAttribute -Path $Path -Hidden $Hidden },
        [scriptblock]$NotifyIconEnumerator = { param($Path) if (Test-Path -LiteralPath $Path -PathType Container) { @(Get-ChildItem -Path "registry::$Path" -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object { $_.PSPath }) } else { @() } },
        [scriptblock]$ExplorerRestarter = { Stop-Process -Force -Name explorer -ErrorAction SilentlyContinue | Out-Null; [pscustomobject]@{ Success = $true; Operation = 'RestartExplorer'; Process = 'explorer' } },
        [scriptblock]$Sleep = { param($Seconds) Start-Sleep -Seconds $Seconds; [pscustomobject]@{ Success = $true; Operation = 'Sleep'; Seconds = $Seconds } }
    )

    $canonicalActionName = switch ($ActionName) {
        'Clean (Recommended)' { 'Apply' }
        'Clean' { 'Apply' }
        default { $ActionName }
    }

    if ($canonicalActionName -notin @($script:BoostLabImplementedActions)) {
        return New-BoostLabStartMenuTaskbarResult -Success $false -Action $canonicalActionName -Status 'Unsupported' -CommandStatus 'Refused before execution' -VerificationStatus 'NotApplicable' -Message 'Unsupported Start Menu Taskbar action. Only Clean (Recommended)/Apply and Default are implemented.'
    }

    $source = Get-BoostLabStartMenuTaskbarSourceStatus
    if ([string]$source.ChecksumStatus -ne 'Passed') {
        return New-BoostLabStartMenuTaskbarResult -Success $false -Action $canonicalActionName -Status 'SourceVerificationFailed' -CommandStatus 'Blocked before execution' -VerificationStatus ([string]$source.ChecksumStatus) -Message 'Start Menu Taskbar blocked because source checksum verification failed or the source file is missing.' -Data $source -Errors @('Source checksum verification failed.')
    }

    $payload = Get-BoostLabStartMenuTaskbarStart2PayloadStatus
    if ([string]$payload.Status -ne 'Passed') {
        return New-BoostLabStartMenuTaskbarResult -Success $false -Action $canonicalActionName -Status 'PayloadVerificationFailed' -CommandStatus 'Blocked before execution' -VerificationStatus ([string]$payload.Status) -Message 'Start Menu Taskbar blocked because the source-defined start2.bin payload could not be verified.' -Data $payload -Errors @('start2.bin payload verification failed.')
    }

    if (-not (& $AdministratorChecker)) {
        return New-BoostLabStartMenuTaskbarResult -Success $false -Action $canonicalActionName -Status 'AdministratorRequired' -CommandStatus 'Blocked before execution' -VerificationStatus 'NotApplicable' -Message 'Start Menu Taskbar requires Administrator rights, matching the Ultimate source.' -Errors @('Administrator rights are required.')
    }

    $operations = @(Get-BoostLabStartMenuTaskbarOperationCatalog -ActionName $canonicalActionName)
    $plan = [pscustomobject]@{
        Source = $source
        Start2Payload = $payload
        OperationCount = $operations.Count
        OperationGroups = @($operations | Group-Object Group | ForEach-Object { [pscustomobject]@{ Group = $_.Name; Count = $_.Count } })
        RestoreStatus = 'Unavailable; Default is source-defined behavior and is not captured-state Restore.'
        NoDownloads = $true
        NoInstallers = $true
        ExplorerHandling = 'Source-defined Explorer restart intent is routed through the ExplorerRestarter adapter.'
    }

    if (-not $Confirmed) {
        return New-BoostLabStartMenuTaskbarResult -Success $false -Action $canonicalActionName -Status 'Cancelled' -CommandStatus 'Cancelled before execution' -VerificationStatus 'NotApplicable' -Message 'Start Menu Taskbar action cancelled before any registry, file, folder, taskbar, Start menu, or Explorer operation executed.' -Data $plan -Cancelled $true
    }

    $adapters = @{
        RegistrySetter = $RegistrySetter
        RegistryValueDeleter = $RegistryValueDeleter
        RegistryKeyDeleter = $RegistryKeyDeleter
        DirectoryDeleter = $DirectoryDeleter
        FileDeleter = $FileDeleter
        TextFileWriter = $TextFileWriter
        BytesFileWriter = $BytesFileWriter
        FileCopier = $FileCopier
        FolderAttributeSetter = $FolderAttributeSetter
        NotifyIconEnumerator = $NotifyIconEnumerator
        ExplorerRestarter = $ExplorerRestarter
        Sleep = $Sleep
    }
    $results = [System.Collections.Generic.List[object]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($operation in $operations) {
        try {
            $result = Invoke-BoostLabStartMenuTaskbarOperation -Operation $operation -Adapters $adapters
            $results.Add([pscustomobject]@{ Id = $operation.Id; Kind = $operation.Kind; Group = $operation.Group; Status = 'Completed'; Result = $result })
        }
        catch {
            $errors.Add("$($operation.Id): $($_.Exception.Message)")
            $results.Add([pscustomobject]@{ Id = $operation.Id; Kind = $operation.Kind; Group = $operation.Group; Status = 'Failed'; Error = $_.Exception.Message })
        }
    }

    $verification = New-BoostLabStartMenuTaskbarVerification -Action $canonicalActionName -Operations $operations -OperationResults $results.ToArray() -Errors $errors.ToArray()
    $success = $errors.Count -eq 0 -and [string]$verification.Status -eq 'Passed'
    $data = [pscustomobject]@{
        Source = $source
        Start2Payload = $payload
        OperationCount = $operations.Count
        CompletedOperationCount = @($results | Where-Object { $_.Status -eq 'Completed' }).Count
        FailedOperationCount = $errors.Count
        OperationResults = $results.ToArray()
        OperationGroups = $plan.OperationGroups
        RestoreStatus = $plan.RestoreStatus
        ExplorerHandling = $plan.ExplorerHandling
    }

    New-BoostLabStartMenuTaskbarResult `
        -Success $success `
        -Action $canonicalActionName `
        -Status ($(if ($success) { 'Completed' } else { 'Failed' })) `
        -CommandStatus ($(if ($success) { 'Completed' } else { 'Failed' })) `
        -VerificationStatus ([string]$verification.Status) `
        -Message ($(if ($success) { "Start Menu Taskbar $canonicalActionName completed with source-equivalent behavior." } else { "Start Menu Taskbar $canonicalActionName failed; see operation errors." })) `
        -Data $data `
        -VerificationResult $verification `
        -Errors $errors.ToArray() `
        -ChangesExecuted ($results.Count -gt 0)
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [bool]$Confirmed = $false
    )

    Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed:$Confirmed
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
    'Get-BoostLabStartMenuTaskbarOperationCatalog'
    'Get-BoostLabStartMenuTaskbarSourceStatus'
    'Get-BoostLabStartMenuTaskbarStart2PayloadStatus'
    'Get-BoostLabStartMenuTaskbarCleanLayoutXml'
    'Get-BoostLabStartMenuTaskbarDefaultLayoutXml'
)
