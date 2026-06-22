Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'edge-webview'
    Title = 'Edge & WebView'
    Stage = 'Windows'
    Order = 13
    Type = 'action'
    RiskLevel = 'high'
    Description = 'Run the source-equivalent Edge and WebView uninstall branch or the source-defined Default repair branch.'
    Actions = @('Apply', 'Default')
    Capabilities = [ordered]@{
        RequiresAdmin             = $true
        RequiresInternet          = $true
        CanReboot                 = $false
        CanModifyRegistry         = $true
        CanModifyServices         = $true
        CanInstallSoftware        = $true
        CanDownload               = $true
        CanModifyDrivers          = $false
        CanModifySecurity         = $true
        CanDeleteFiles            = $true
        UsesTrustedInstaller      = $false
        UsesSafeMode              = $false
        SupportsDefault           = $true
        SupportsRestore           = $false
        NeedsExplicitConfirmation = $true
    }
}

$script:BoostLabImplementedActions = @('Apply', 'Default')
$script:BoostLabExpectedSourceHash = '161ED9C99D437E45650369CB7E15D5737DED363712E647138F134B049AC7E691'
$script:BoostLabSourceRelativePath = 'source-ultimate/6 Windows/13 Edge & WebView.ps1'
$script:BoostLabEdgeProcesses = @(
    'backgroundTaskHost',
    'Copilot',
    'CrossDeviceResume',
    'GameBar',
    'MicrosoftEdgeUpdate',
    'msedge',
    'msedgewebview2',
    'OneDrive',
    'OneDrive.Sync.Service',
    'OneDriveStandaloneUpdater',
    'Resume',
    'RuntimeBroker',
    'Search',
    'SearchHost',
    'Setup',
    'StoreDesktopExtension',
    'WidgetService',
    'Widgets'
)
$script:BoostLabEdgeUpdateRegistryKeys = @(
    'HKCU:\SOFTWARE\Microsoft\EdgeUpdate',
    'HKLM:\SOFTWARE\Microsoft\EdgeUpdate',
    'HKCU:\SOFTWARE\Policies\Microsoft\EdgeUpdate',
    'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate',
    'HKCU:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate',
    'HKCU:\SOFTWARE\WOW6432Node\Policies\Microsoft\EdgeUpdate',
    'HKLM:\SOFTWARE\WOW6432Node\Policies\Microsoft\EdgeUpdate'
)

function Get-BoostLabEdgeWebViewProjectRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

function Invoke-BoostLabEdgeWebViewVerifiedArtifactDownload {
    param(
        [Parameter(Mandatory)]
        [string]$ArtifactId,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    $downloadModulePath = Join-Path (Get-BoostLabEdgeWebViewProjectRoot) 'core\DownloadProvenance.psm1'
    if (-not (Get-Command -Name 'Invoke-BoostLabVerifiedArtifactDownload' -ErrorAction SilentlyContinue)) {
        Import-Module -Name $downloadModulePath -Scope Local -Force -ErrorAction Stop
    }

    Invoke-BoostLabVerifiedArtifactDownload -ArtifactId $ArtifactId -Destination $Destination
}

function Get-BoostLabEdgeWebViewSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Join-Path (Get-BoostLabEdgeWebViewProjectRoot) ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabEdgeWebViewSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabEdgeWebViewSourcePath
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

function New-BoostLabEdgeWebViewOperation {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter(Mandatory)]
        [string]$Kind,

        [Parameter(Mandatory)]
        [string]$Description,

        [hashtable]$Parameters = @{}
    )

    [pscustomobject]@{
        Id          = $Id
        Kind        = $Kind
        Description = $Description
        Parameters  = $Parameters
    }
}

function Get-BoostLabEdgeWebViewUninstallOperations {
    [CmdletBinding()]
    [OutputType([object[]])]
    param()

    $systemRoot = $env:SystemRoot
    if ([string]::IsNullOrWhiteSpace($systemRoot)) {
        $systemRoot = 'C:\Windows'
    }
    $systemDrive = $env:SystemDrive
    if ([string]::IsNullOrWhiteSpace($systemDrive)) {
        $systemDrive = 'C:'
    }

    @(
        New-BoostLabEdgeWebViewOperation -Id 'RequireAdministrator' -Kind 'RequireAdministrator' -Description 'Require Administrator rights exactly as the source self-elevation gate requires.'
        New-BoostLabEdgeWebViewOperation -Id 'RequireInternet' -Kind 'RequireInternet' -Description 'Verify internet availability with Test-Connection 8.8.8.8 exactly as the source requires.' -Parameters @{ ComputerName = '8.8.8.8' }
        New-BoostLabEdgeWebViewOperation -Id 'CaptureDeviceRegion' -Kind 'ReadRegistryValue' -Description 'Capture HKLM Control Panel DeviceRegion before the source temporarily sets it to US.' -Parameters @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Control Panel\DeviceRegion'; Name = 'DeviceRegion'; ContextKey = 'DeviceRegion' }
        New-BoostLabEdgeWebViewOperation -Id 'CopyRegExe' -Kind 'CopyRegExe' -Description 'Copy reg.exe to .\reg1.exe exactly as the source does.' -Parameters @{ Destination = '.\reg1.exe' }
        New-BoostLabEdgeWebViewOperation -Id 'SetDeviceRegionUS' -Kind 'RegExeAdd' -Description 'Set DeviceRegion to REG_DWORD 244 before Edge/WebView removal.' -Parameters @{ Executable = '.\reg1.exe'; Key = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Control Panel\DeviceRegion'; Name = 'DeviceRegion'; Type = 'REG_DWORD'; Data = 244 }
        New-BoostLabEdgeWebViewOperation -Id 'StopNamedProcesses' -Kind 'StopNamedProcesses' -Description 'Stop the exact source-defined process list.' -Parameters @{ Names = @($script:BoostLabEdgeProcesses) }
        New-BoostLabEdgeWebViewOperation -Id 'StopWildcardEdgeProcesses' -Kind 'StopWildcardEdgeProcesses' -Description 'Stop every running process whose ProcessName matches *edge* exactly as the source does.'
        New-BoostLabEdgeWebViewOperation -Id 'FindEdgeUpdateExecutables' -Kind 'FindEdgeUpdateExecutables' -Description 'Find MicrosoftEdgeUpdate.exe under LocalApplicationData, ProgramFilesX86, and ProgramFiles.' -Parameters @{ RelativePattern = 'Microsoft\EdgeUpdate\*.*.*.*\MicrosoftEdgeUpdate.exe'; ContextKey = 'EdgeUpdateExecutables' }
        New-BoostLabEdgeWebViewOperation -Id 'RemoveEdgeUpdateRegistryKeys' -Kind 'RemoveRegistryKeys' -Description 'Remove every source-defined EdgeUpdate registry key recursively.' -Parameters @{ Paths = @($script:BoostLabEdgeUpdateRegistryKeys) }
        New-BoostLabEdgeWebViewOperation -Id 'UnregisterEdgeUpdateServices' -Kind 'RunEdgeUpdateExecutableForEachPath' -Description 'Run each discovered MicrosoftEdgeUpdate.exe with /unregsvc and wait for Edge setup/update processes to finish.' -Parameters @{ ContextKey = 'EdgeUpdateExecutables'; Arguments = '/unregsvc' }
        New-BoostLabEdgeWebViewOperation -Id 'UninstallEdgeUpdate' -Kind 'RunEdgeUpdateExecutableForEachPath' -Description 'Run each discovered MicrosoftEdgeUpdate.exe with /uninstall and wait for Edge setup/update processes to finish.' -Parameters @{ ContextKey = 'EdgeUpdateExecutables'; Arguments = '/uninstall' }
        New-BoostLabEdgeWebViewOperation -Id 'CreateEdgeSystemAppDirectory' -Kind 'NewDirectory' -Description 'Create the source Edge SystemApps directory marker.' -Parameters @{ Path = (Join-Path $systemRoot 'SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe') }
        New-BoostLabEdgeWebViewOperation -Id 'CreateMicrosoftEdgeExeMarker' -Kind 'NewFile' -Description 'Create MicrosoftEdge.exe marker file in the source SystemApps directory.' -Parameters @{ Path = (Join-Path $systemRoot 'SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\MicrosoftEdge.exe') }
        New-BoostLabEdgeWebViewOperation -Id 'ReadEdgeUninstallString' -Kind 'ReadEdgeUninstallString32' -Description 'Read Microsoft Edge uninstall string from the 32-bit HKLM uninstall registry view.' -Parameters @{ ContextKey = 'EdgeUninstallString' }
        New-BoostLabEdgeWebViewOperation -Id 'RunEdgeForceUninstall' -Kind 'RunEdgeUninstallString' -Description 'Run cmd.exe /c with the source Edge uninstall string plus --force-uninstall.' -Parameters @{ ContextKey = 'EdgeUninstallString'; ExtraArguments = '--force-uninstall' }
        New-BoostLabEdgeWebViewOperation -Id 'RemoveEdgeSystemAppDirectory' -Kind 'RemoveDirectory' -Description 'Remove the source Edge SystemApps directory recursively.' -Parameters @{ Path = (Join-Path $systemRoot 'SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe') }
        New-BoostLabEdgeWebViewOperation -Id 'DeleteEdgeWebViewUninstallKey' -Kind 'Cmd' -Description 'Delete the Microsoft EdgeWebView uninstall registry key exactly as the source does.' -Parameters @{ Command = 'reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView" /f >nul 2>&1' }
        New-BoostLabEdgeWebViewOperation -Id 'RemoveEdgeQuickLaunchShortcut' -Kind 'RemoveFile' -Description 'Remove the Microsoft Edge Quick Launch shortcut from systemprofile.' -Parameters @{ Path = (Join-Path $systemRoot 'System32\config\systemprofile\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\Microsoft Edge.lnk') }
        New-BoostLabEdgeWebViewOperation -Id 'RemoveMicrosoftProgramFilesX86Folder' -Kind 'RemoveDirectory' -Description 'Remove %SystemDrive%\Program Files (x86)\Microsoft recursively exactly as the source does.' -Parameters @{ Path = (Join-Path $systemDrive 'Program Files (x86)\Microsoft') }
        New-BoostLabEdgeWebViewOperation -Id 'DeleteEdgeServices' -Kind 'DeleteEdgeServices' -Description 'Stop and delete every service whose Name matches Edge.'
        New-BoostLabEdgeWebViewOperation -Id 'FindLegacyEdgePackage' -Kind 'FindLegacyEdgePackage' -Description 'Find the optional Windows 10 legacy Microsoft-Windows-Internet-Browser-Package CBS package.' -Parameters @{ ContextKey = 'LegacyEdgePackage' }
        New-BoostLabEdgeWebViewOperation -Id 'RemoveLegacyEdgePackageIfPresent' -Kind 'RemoveLegacyEdgePackageIfPresent' -Description 'If the legacy Edge package exists, set Visibility, delete Owners, and run DISM /Remove-Package /quiet /norestart exactly as the source does.' -Parameters @{ ContextKey = 'LegacyEdgePackage' }
        New-BoostLabEdgeWebViewOperation -Id 'RestoreDeviceRegion' -Kind 'RestoreDeviceRegion' -Description 'Restore the captured DeviceRegion through .\reg1.exe if the source captured one.' -Parameters @{ Executable = '.\reg1.exe'; ContextKey = 'DeviceRegion' }
        New-BoostLabEdgeWebViewOperation -Id 'RemoveRegExeCopy' -Kind 'RemoveFile' -Description 'Remove .\reg1.exe exactly as the source cleanup does.' -Parameters @{ Path = '.\reg1.exe' }
    )
}

function Get-BoostLabEdgeWebViewDefaultOperations {
    [CmdletBinding()]
    [OutputType([object[]])]
    param()

    $systemRoot = $env:SystemRoot
    if ([string]::IsNullOrWhiteSpace($systemRoot)) {
        $systemRoot = 'C:\Windows'
    }

    @(
        New-BoostLabEdgeWebViewOperation -Id 'RequireAdministrator' -Kind 'RequireAdministrator' -Description 'Require Administrator rights exactly as the source self-elevation gate requires.'
        New-BoostLabEdgeWebViewOperation -Id 'RequireInternet' -Kind 'RequireInternet' -Description 'Verify internet availability with Test-Connection 8.8.8.8 exactly as the source requires.' -Parameters @{ ComputerName = '8.8.8.8' }
        New-BoostLabEdgeWebViewOperation -Id 'StopNamedProcessesBeforeEdgeRepair' -Kind 'StopNamedProcesses' -Description 'Stop the exact source-defined process list before downloading Edge repair installer.' -Parameters @{ Names = @($script:BoostLabEdgeProcesses) }
        New-BoostLabEdgeWebViewOperation -Id 'StopWildcardEdgeProcessesBeforeEdgeRepair' -Kind 'StopWildcardEdgeProcesses' -Description 'Stop every running process whose ProcessName matches *edge* before downloading Edge repair installer.'
        New-BoostLabEdgeWebViewOperation -Id 'DownloadEdgeRepair' -Kind 'DownloadFile' -Description 'Download the source edge.exe repair artifact to %SystemRoot%\Temp\edge.exe.' -Parameters @{ Uri = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe'; OutFile = (Join-Path $systemRoot 'Temp\edge.exe'); ArtifactId = 'edge-webview-edge-exe'; ArtifactClassification = 'UltimateAuthorHostedArtifact'; ApprovalStatus = 'NeedsBoostLabMirror' }
        New-BoostLabEdgeWebViewOperation -Id 'RunEdgeRepair' -Kind 'StartProcess' -Description 'Launch %SystemRoot%\Temp\edge.exe and wait exactly as the source Default branch does.' -Parameters @{ FilePath = (Join-Path $systemRoot 'Temp\edge.exe'); Wait = $true }
        New-BoostLabEdgeWebViewOperation -Id 'StopNamedProcessesBeforeWebViewRepair' -Kind 'StopNamedProcesses' -Description 'Stop the exact source-defined process list before downloading WebView repair installer.' -Parameters @{ Names = @($script:BoostLabEdgeProcesses) }
        New-BoostLabEdgeWebViewOperation -Id 'StopWildcardEdgeProcessesBeforeWebViewRepair' -Kind 'StopWildcardEdgeProcesses' -Description 'Stop every running process whose ProcessName matches *edge* before downloading WebView repair installer.'
        New-BoostLabEdgeWebViewOperation -Id 'DownloadEdgeWebViewRepair' -Kind 'DownloadFile' -Description 'Download the source edgewebview.exe repair artifact to %SystemRoot%\Temp\edgewebview.exe.' -Parameters @{ Uri = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edgewebview.exe'; OutFile = (Join-Path $systemRoot 'Temp\edgewebview.exe'); ArtifactId = 'edge-webview-edge-webview'; ArtifactClassification = 'UltimateAuthorHostedArtifact'; ApprovalStatus = 'NeedsBoostLabMirror' }
        New-BoostLabEdgeWebViewOperation -Id 'RunEdgeWebViewRepair' -Kind 'StartProcess' -Description 'Launch %SystemRoot%\Temp\edgewebview.exe and wait exactly as the source Default branch does.' -Parameters @{ FilePath = (Join-Path $systemRoot 'Temp\edgewebview.exe'); Wait = $true }
        New-BoostLabEdgeWebViewOperation -Id 'StopNamedProcessesAfterRepairs' -Kind 'StopNamedProcesses' -Description 'Stop the exact source-defined process list after both repair installers.' -Parameters @{ Names = @($script:BoostLabEdgeProcesses) }
        New-BoostLabEdgeWebViewOperation -Id 'StopWildcardEdgeProcessesAfterRepairs' -Kind 'StopWildcardEdgeProcesses' -Description 'Stop every running process whose ProcessName matches *edge* after both repair installers.'
        New-BoostLabEdgeWebViewOperation -Id 'ForceInstallUblockPolicy' -Kind 'Cmd' -Description 'Import the source ExtensionInstallForcelist policy value.' -Parameters @{ Command = 'reg add HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist /v 1 /t REG_SZ /d "odfafepnkmbhccpbejgmiehpchacaeak;https://edge.microsoft.com/extensionwebstorebase/v1/crx" /f' }
        New-BoostLabEdgeWebViewOperation -Id 'DisableHardwareAccelerationPolicy' -Kind 'Cmd' -Description 'Set HardwareAccelerationModeEnabled to REG_DWORD 0.' -Parameters @{ Command = 'reg add HKLM\SOFTWARE\Policies\Microsoft\Edge /v HardwareAccelerationModeEnabled /t REG_DWORD /d 0 /f' }
        New-BoostLabEdgeWebViewOperation -Id 'DisableBackgroundModePolicy' -Kind 'Cmd' -Description 'Set BackgroundModeEnabled to REG_DWORD 0.' -Parameters @{ Command = 'reg add HKLM\SOFTWARE\Policies\Microsoft\Edge /v BackgroundModeEnabled /t REG_DWORD /d 0 /f' }
        New-BoostLabEdgeWebViewOperation -Id 'DisableStartupBoostPolicy' -Kind 'Cmd' -Description 'Set StartupBoostEnabled to REG_DWORD 0.' -Parameters @{ Command = 'reg add HKLM\SOFTWARE\Policies\Microsoft\Edge /v StartupBoostEnabled /t REG_DWORD /d 0 /f' }
        New-BoostLabEdgeWebViewOperation -Id 'RemoveEdgeActiveSetupComponents' -Kind 'RemoveEdgeActiveSetupComponents' -Description 'Remove Active Setup installed components whose default value contains Edge.'
        New-BoostLabEdgeWebViewOperation -Id 'RemoveMsedgeRunOnceValues' -Kind 'RemoveMsedgeRunOnceValues' -Description 'Remove RunOnce properties whose name matches *msedge*.'
        New-BoostLabEdgeWebViewOperation -Id 'DeleteEdgeServicesAfterRepair' -Kind 'DeleteEdgeServices' -Description 'Stop and delete every service whose Name matches Edge.'
        New-BoostLabEdgeWebViewOperation -Id 'RemoveEdgeScheduledTasks' -Kind 'UnregisterEdgeScheduledTasks' -Description 'Unregister every scheduled task whose TaskName matches *Edge*.'
        New-BoostLabEdgeWebViewOperation -Id 'DeleteWow6432Bho' -Kind 'Cmd' -Description 'Delete the WOW6432Node IE-to-Edge Browser Helper Object key.' -Parameters @{ Command = 'reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}" /f >nul 2>&1' }
        New-BoostLabEdgeWebViewOperation -Id 'DeleteNativeBho' -Kind 'Cmd' -Description 'Delete the native IE-to-Edge Browser Helper Object key.' -Parameters @{ Command = 'reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}" /f >nul 2>&1' }
    )
}

function Get-BoostLabEdgeWebViewOperationPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName
    )

    $sourceStatus = Get-BoostLabEdgeWebViewSourceStatus
    $operations = if ($ActionName -eq 'Apply') {
        @(Get-BoostLabEdgeWebViewUninstallOperations)
    }
    else {
        @(Get-BoostLabEdgeWebViewDefaultOperations)
    }

    [pscustomobject]@{
        ToolId                = [string]$script:BoostLabToolMetadata['Id']
        Action                = $ActionName
        Source                = $sourceStatus
        UltimateBranch        = if ($ActionName -eq 'Apply') { 'Edge & WebView: Uninstall (Recommended)' } else { 'Edge & WebView: Default' }
        Operations            = $operations
        OperationCount        = $operations.Count
        Downloads             = @($operations | Where-Object { $_.Kind -eq 'DownloadFile' })
        ExternalProcesses     = @($operations | Where-Object { $_.Kind -in @('StartProcess', 'RunEdgeUpdateExecutableForEachPath', 'RunEdgeUninstallString', 'Cmd', 'RemoveLegacyEdgePackageIfPresent') })
        RegistryMutations     = @($operations | Where-Object { $_.Kind -in @('RegExeAdd', 'RemoveRegistryKeys', 'Cmd', 'RemoveEdgeActiveSetupComponents', 'RemoveMsedgeRunOnceValues', 'RemoveLegacyEdgePackageIfPresent', 'RestoreDeviceRegion') })
        FileMutations         = @($operations | Where-Object { $_.Kind -in @('CopyRegExe', 'NewDirectory', 'NewFile', 'RemoveDirectory', 'RemoveFile', 'DownloadFile') })
        ServiceMutations      = @($operations | Where-Object { $_.Kind -eq 'DeleteEdgeServices' })
        ScheduledTaskMutation = @($operations | Where-Object { $_.Kind -eq 'UnregisterEdgeScheduledTasks' })
        ProcessMutations      = @($operations | Where-Object { $_.Kind -in @('StopNamedProcesses', 'StopWildcardEdgeProcesses') })
        RestoreSupported      = $false
        RequiresConfirmation  = $true
    }
}

function New-BoostLabEdgeWebViewResult {
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
        Success            = $Success
        ToolId             = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle          = [string]$script:BoostLabToolMetadata['Title']
        Action             = $Action
        Status             = $Status
        CommandStatus      = $CommandStatus
        VerificationStatus = $VerificationStatus
        Message            = $Message
        RestartRequired    = $false
        Cancelled          = $Cancelled
        ChangesExecuted    = $ChangesExecuted
        Timestamp          = Get-Date
        Data               = $Data
        Warnings           = @($Warnings)
        Errors             = @($Errors)
    }
}

function Invoke-BoostLabEdgeWebViewCommandLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Command
    )

    $cmd = $env:ComSpec
    if ([string]::IsNullOrWhiteSpace($cmd)) {
        $cmd = 'cmd.exe'
    }
    & $cmd /c $Command
}

function Wait-BoostLabEdgeWebViewSourceSetupProcesses {
    [CmdletBinding()]
    param()

    do {
        Start-Sleep -Seconds 3
        $running = @(Get-Process -Name 'setup', 'MicrosoftEdge*' -ErrorAction SilentlyContinue | Where-Object { $_.Path -like '*\Microsoft\Edge*' })
    } while ($running.Count -gt 0)
}

function Invoke-BoostLabEdgeWebViewOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Operation,

        [Parameter(Mandatory)]
        [hashtable]$Context
    )

    switch ([string]$Operation.Kind) {
        'RequireAdministrator' {
            $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
            if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
                throw 'Edge & WebView requires BoostLab to run as Administrator.'
            }
        }
        'RequireInternet' {
            if (-not (Test-Connection -ComputerName ([string]$Operation.Parameters.ComputerName) -Count 1 -Quiet)) {
                throw 'Edge & WebView requires internet connectivity.'
            }
        }
        'ReadRegistryValue' {
            $Context[[string]$Operation.Parameters.ContextKey] = Get-ItemPropertyValue -Path ([string]$Operation.Parameters.Path) -Name ([string]$Operation.Parameters.Name) -ErrorAction SilentlyContinue
        }
        'CopyRegExe' {
            Copy-Item -LiteralPath (Get-Command reg.exe -ErrorAction Stop).Source -Destination ([string]$Operation.Parameters.Destination) -Force -ErrorAction Stop
        }
        'RegExeAdd' {
            & ([string]$Operation.Parameters.Executable) add ([string]$Operation.Parameters.Key) /v ([string]$Operation.Parameters.Name) /t ([string]$Operation.Parameters.Type) /d ([string]$Operation.Parameters.Data) /f
        }
        'StopNamedProcesses' {
            Get-Process -Name @($Operation.Parameters.Names) -ErrorAction SilentlyContinue | Stop-Process -Force
        }
        'StopWildcardEdgeProcesses' {
            Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like '*edge*' } | Stop-Process -Force
        }
        'FindEdgeUpdateExecutables' {
            $roots = @($env:LocalApplicationData, $env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }
            $Context[[string]$Operation.Parameters.ContextKey] = @(
                foreach ($root in $roots) {
                    Get-ChildItem -Path (Join-Path $root ([string]$Operation.Parameters.RelativePattern)) -ErrorAction SilentlyContinue
                }
            )
        }
        'RemoveRegistryKeys' {
            foreach ($path in @($Operation.Parameters.Paths)) {
                Remove-Item -Path ([string]$path) -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        'RunEdgeUpdateExecutableForEachPath' {
            foreach ($edgeUpdatePath in @($Context[[string]$Operation.Parameters.ContextKey])) {
                if ($edgeUpdatePath -and (Test-Path -LiteralPath $edgeUpdatePath.FullName -PathType Leaf)) {
                    Start-Process -FilePath $edgeUpdatePath.FullName -ArgumentList ([string]$Operation.Parameters.Arguments) -Wait
                    Wait-BoostLabEdgeWebViewSourceSetupProcesses
                }
            }
        }
        'NewDirectory' {
            New-Item -Path ([string]$Operation.Parameters.Path) -ItemType Directory -Force | Out-Null
        }
        'NewFile' {
            New-Item -Path ([string]$Operation.Parameters.Path) -ItemType File -Force | Out-Null
        }
        'ReadEdgeUninstallString32' {
            $registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry32)
            try {
                $key = $registry.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge')
                if ($null -ne $key) {
                    try {
                        $Context[[string]$Operation.Parameters.ContextKey] = [string]$key.GetValue('UninstallString')
                    }
                    finally {
                        $key.Dispose()
                    }
                }
            }
            finally {
                $registry.Dispose()
            }
        }
        'RunEdgeUninstallString' {
            $uninstallString = [string]$Context[[string]$Operation.Parameters.ContextKey]
            if (-not [string]::IsNullOrWhiteSpace($uninstallString)) {
                Start-Process -FilePath 'cmd.exe' -ArgumentList ('/c {0} {1}' -f $uninstallString, [string]$Operation.Parameters.ExtraArguments) -WindowStyle Hidden -Wait
            }
        }
        'RemoveDirectory' {
            Remove-Item -Path ([string]$Operation.Parameters.Path) -Recurse -Force -ErrorAction SilentlyContinue
        }
        'RemoveFile' {
            Remove-Item -Path ([string]$Operation.Parameters.Path) -Force -ErrorAction SilentlyContinue
        }
        'Cmd' {
            Invoke-BoostLabEdgeWebViewCommandLine -Command ([string]$Operation.Parameters.Command)
        }
        'DeleteEdgeServices' {
            foreach ($service in @(Get-Service | Where-Object { $_.Name -match 'Edge' })) {
                Invoke-BoostLabEdgeWebViewCommandLine -Command ('sc stop "{0}" >nul 2>&1' -f $service.Name)
                Invoke-BoostLabEdgeWebViewCommandLine -Command ('sc delete "{0}" >nul 2>&1' -f $service.Name)
            }
        }
        'FindLegacyEdgePackage' {
            $Context[[string]$Operation.Parameters.ContextKey] = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages' -ErrorAction SilentlyContinue |
                Where-Object { $_.PSChildName -like '*Microsoft-Windows-Internet-Browser-Package*~~*' } |
                Select-Object -First 1
        }
        'RemoveLegacyEdgePackageIfPresent' {
            $legacyPackage = $Context[[string]$Operation.Parameters.ContextKey]
            if ($legacyPackage) {
                $packagePath = ($legacyPackage.Name -replace '^HKEY_LOCAL_MACHINE', 'HKLM')
                & reg.exe add $packagePath /v Visibility /t REG_DWORD /d 1 /f
                & reg.exe delete "$packagePath\Owners" /va /f
                & dism.exe /online /Remove-Package "/PackageName:$($legacyPackage.PSChildName)" /quiet /norestart
            }
        }
        'RestoreDeviceRegion' {
            if ($Context.ContainsKey([string]$Operation.Parameters.ContextKey) -and $null -ne $Context[[string]$Operation.Parameters.ContextKey]) {
                & ([string]$Operation.Parameters.Executable) add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Control Panel\DeviceRegion' /v DeviceRegion /t REG_DWORD /d ([string]$Context[[string]$Operation.Parameters.ContextKey]) /f
            }
        }
        'DownloadFile' {
            Invoke-BoostLabEdgeWebViewVerifiedArtifactDownload `
                -ArtifactId ([string]$Operation.Parameters.ArtifactId) `
                -Destination ([string]$Operation.Parameters.OutFile) | Out-Null
        }
        'StartProcess' {
            if ([bool]$Operation.Parameters.Wait) {
                Start-Process -FilePath ([string]$Operation.Parameters.FilePath) -Wait
            }
            else {
                Start-Process -FilePath ([string]$Operation.Parameters.FilePath)
            }
        }
        'RemoveEdgeActiveSetupComponents' {
            Get-ChildItem -Path 'HKLM:\Software\Microsoft\Active Setup\Installed Components' -ErrorAction SilentlyContinue |
                Where-Object { $_.GetValue('') -like '*Edge*' } |
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        }
        'RemoveMsedgeRunOnceValues' {
            $runOncePath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
            $item = Get-ItemProperty -Path $runOncePath -ErrorAction SilentlyContinue
            if ($item) {
                foreach ($property in @($item.PSObject.Properties | Where-Object { $_.Name -like '*msedge*' })) {
                    Remove-ItemProperty -Path $runOncePath -Name $property.Name -Force -ErrorAction SilentlyContinue
                }
            }
        }
        'UnregisterEdgeScheduledTasks' {
            Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like '*Edge*' } | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
        }
        default {
            throw "Unsupported Edge & WebView operation kind: $($Operation.Kind)"
        }
    }
}

function Invoke-BoostLabEdgeWebViewWorkflow {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [scriptblock]$OperationExecutor = $null
    )

    $plan = Get-BoostLabEdgeWebViewOperationPlan -ActionName $ActionName
    $context = @{}
    $executed = [System.Collections.Generic.List[object]]::new()
    foreach ($operation in @($plan.Operations)) {
        if ($OperationExecutor) {
            & $OperationExecutor $operation $context
        }
        else {
            Invoke-BoostLabEdgeWebViewOperation -Operation $operation -Context $context
        }
        $executed.Add($operation)
    }

    [pscustomobject]@{
        Plan               = $plan
        ExecutedOperations = @($executed)
        ContextKeys        = @($context.Keys)
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
        ConfirmationRequiredActions = @('Apply', 'Default')
        ConfirmationText            = 'Edge & WebView will run the source-equivalent high-risk workflow for the selected action. Continue only if you intentionally approved Edge/WebView package, registry, service, task, process, file, download, installer, cleanup, and support impact.'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabEdgeWebViewSourceStatus
    [pscustomobject]@{
        Supported            = [string]$sourceStatus.ChecksumStatus -eq 'Passed'
        ToolId               = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle            = [string]$script:BoostLabToolMetadata['Title']
        Reason               = if ([string]$sourceStatus.ChecksumStatus -eq 'Passed') { 'Edge & WebView source-equivalent Apply and Default are available after confirmation.' } else { 'Edge & WebView source identity is missing or mismatched.' }
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
        Status          = 'SourceEquivalentControlled'
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

        [scriptblock]$OperationExecutor = $null
    )

    $canonicalActionName = switch ($ActionName) {
        'Edge & WebView: Uninstall (Recommended)' { 'Apply' }
        'Edge & WebView: Default' { 'Default' }
        default { $ActionName }
    }

    if ($canonicalActionName -notin @($script:BoostLabImplementedActions)) {
        return New-BoostLabEdgeWebViewResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'Unsupported' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Unsupported Edge & WebView action. The source exposes only Apply/Uninstall and Default behavior.'
    }

    $plan = Get-BoostLabEdgeWebViewOperationPlan -ActionName $canonicalActionName
    if ([string]$plan.Source.ChecksumStatus -ne 'Passed') {
        return New-BoostLabEdgeWebViewResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'SourceVerificationFailed' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus ([string]$plan.Source.ChecksumStatus) `
            -Message 'Edge & WebView blocked because source checksum verification failed or the source file is missing.' `
            -Data $plan `
            -Errors @('Edge & WebView source checksum did not match the expected value or the source file is missing.')
    }

    if (-not $Confirmed) {
        return New-BoostLabEdgeWebViewResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'Cancelled' `
            -CommandStatus 'Cancelled before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Edge & WebView action cancelled before execution. No download, installer, process, file, registry, service, task, package, DISM, cleanup, or system-changing operation occurred.' `
            -Data $plan `
            -Cancelled $true
    }

    try {
        $workflow = Invoke-BoostLabEdgeWebViewWorkflow -ActionName $canonicalActionName -OperationExecutor $OperationExecutor
        $expectedCount = [int]$workflow.Plan.OperationCount
        $actualCount = @($workflow.ExecutedOperations).Count
        if ($actualCount -ne $expectedCount) {
            throw "Edge & WebView operation verification failed. Expected $expectedCount operations, executed $actualCount."
        }

        $message = if ($canonicalActionName -eq 'Apply') {
            'Edge & WebView Apply completed the source-equivalent Uninstall (Recommended) branch.'
        }
        else {
            'Edge & WebView Default completed the source-defined repair/default branch.'
        }
        return New-BoostLabEdgeWebViewResult `
            -Success $true `
            -Action $canonicalActionName `
            -Status 'Completed' `
            -CommandStatus 'Completed' `
            -VerificationStatus 'Passed' `
            -Message $message `
            -Data $workflow `
            -ChangesExecuted $true
    }
    catch {
        return New-BoostLabEdgeWebViewResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'Error' `
            -CommandStatus 'Error' `
            -VerificationStatus 'Failed' `
            -Message ("Edge & WebView {0} failed: {1}" -f $canonicalActionName, $_.Exception.Message) `
            -Data $plan `
            -Errors @($_.Exception.Message)
    }
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [bool]$Confirmed = $false,

        [scriptblock]$OperationExecutor = $null
    )

    Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed:$Confirmed -OperationExecutor $OperationExecutor
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
