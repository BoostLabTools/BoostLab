Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
Import-Module -Name $verificationModulePath -Scope Local -ErrorAction Stop

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'unattended'; Title = 'Unattended'; Stage = 'Refresh'; Order = 2
    Type = 'action'; RiskLevel = 'high'
    Description = 'Create the approved Windows 11 autounattend.xml on selected removable installation media.'
    Actions = @('Analyze', 'Apply')
    Capabilities = [ordered]@{
        RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false
        CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $true
        CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $true
        CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false
        SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Analyze', 'Apply')
$script:BoostLabUnattendedFileName = 'autounattend.xml'
$script:BoostLabUnattendedTemplateFileName = 'autounattendtemplate.xml'
$script:BoostLabUnattendedSourceHash = '0974CFCC4FFC4B21BF4EB62172C0C1C31FF32AB147878A4610FC19C95DF74338'
$script:BoostLabUnattendedTemplate = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
            xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>0409:00000409</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UILanguageFallback>en-US</UILanguageFallback>
            <UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
            xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <TimeZone>Central Standard Time</TimeZone>
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Home</NetworkLocation>
                <ProtectYourPC>3</ProtectYourPC>
                <SkipMachineOOBE>true</SkipMachineOOBE>
                <SkipUserOOBE>true</SkipUserOOBE>
            </OOBE>
            <UserAccounts>
                <AdministratorPassword>
                    <PlainText>true</PlainText>
                    <Value></Value>
                </AdministratorPassword>
                <LocalAccounts>
                    <LocalAccount wcm:action="add">
                        <Group>Administrators</Group>
                        <Name>@</Name>
                        <Password>
                            <PlainText>true</PlainText>
                            <Value></Value>
                        </Password>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
            xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <Path>net accounts /maxpwage:unlimited</Path>
                    <WillReboot>Never</WillReboot>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>2</Order>
                    <Path>net user @ /active:Yes</Path>
                    <WillReboot>Never</WillReboot>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>3</Order>
                    <Path>net user @ /passwordreq:no</Path>
                    <WillReboot>Never</WillReboot>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
        <component name="Microsoft-Windows-Security-SPP-UX" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
            xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SkipAutoActivation>true</SkipAutoActivation>
        </component>
        <component name="Microsoft-Windows-UnattendedJoin" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
            xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <Identification>
                <JoinWorkgroup>WORKGROUP</JoinWorkgroup>
            </Identification>
        </component>
    </settings>
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
            xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>0409:00000409</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UILanguageFallback>en-US</UILanguageFallback>
            <UserLocale>en-US</UserLocale>
            <SetupUILanguage>
                <UILanguage>en-US</UILanguage>
            </SetupUILanguage>
        </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
            xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <Path>reg add "HKLM\SYSTEM\Setup\LabConfig" /v "BypassTPMCheck" /t REG_DWORD /d 1 /f</Path>
                    <Description>Add BypassTPMCheck</Description>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>2</Order>
                    <Path>reg add "HKLM\SYSTEM\Setup\LabConfig" /v "BypassRAMCheck" /t REG_DWORD /d 1 /f</Path>
                    <Description>Add BypassRAMCheck</Description>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>3</Order>
                    <Path>reg add "HKLM\SYSTEM\Setup\LabConfig" /v "BypassSecureBootCheck" /t REG_DWORD /d 1 /f</Path>
                    <Description>Add BypassSecureBootCheck</Description>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>4</Order>
                    <Path>reg add "HKLM\SYSTEM\Setup\LabConfig" /v "BypassCPUCheck" /t REG_DWORD /d 1 /f</Path>
                    <Description>Add BypassCPUCheck</Description>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>5</Order>
                    <Path>reg add "HKLM\SYSTEM\Setup\LabConfig" /v "BypassStorageCheck" /t REG_DWORD /d 1 /f</Path>
                    <Description>Add BypassStorageCheck</Description>
                </RunSynchronousCommand>
            </RunSynchronous>
            <Diagnostics>
                <OptIn>false</OptIn>
            </Diagnostics>
            <DynamicUpdate>
                <Enable>false</Enable>
                <WillShowUI>OnError</WillShowUI>
            </DynamicUpdate>
            <UserData>
                <AcceptEula>true</AcceptEula>
                <ProductKey>
                    <Key></Key>
                </ProductKey>
            </UserData>
        </component>
    </settings>
</unattend>
'@

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

function Get-BoostLabUnattendedWindowsInfo {
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        return [pscustomobject]@{
            Caption = [string]$os.Caption
            Build = [int]$os.BuildNumber
        }
    }
    catch {
        return [pscustomobject]@{
            Caption = [Environment]::OSVersion.VersionString
            Build = [int][Environment]::OSVersion.Version.Build
        }
    }
}

function Get-BoostLabUnattendedHostScope {
    param(
        [Parameter(Mandatory)][object]$WindowsInfo
    )

    $caption = [string]$WindowsInfo.Caption
    $build = [int]$WindowsInfo.Build
    $isServer = $caption -match '(?i)server'
    $isWindows11 = -not $isServer -and $build -ge 22000
    $isWindows10 = -not $isServer -and $build -ge 10240 -and $build -lt 22000
    $supported = $isWindows10 -or $isWindows11
    $hostLabel = if ($isWindows11) {
        'Windows 11'
    }
    elseif ($isWindows10) {
        'Windows 10'
    }
    else {
        if ([string]::IsNullOrWhiteSpace($caption)) { 'Unknown Windows host' } else { $caption }
    }

    [pscustomobject]@{
        CurrentHostOS = $hostLabel
        DetectedWindows = '{0} (build {1})' -f $caption, $build
        HostBuild = $build
        HostIsWindows10 = $isWindows10
        HostIsWindows11 = $isWindows11
        SupportedForWindows11Preparation = $supported
        PayloadTarget = 'Windows 11'
        HostUsage = if ($isWindows10) {
            'Allowed only for creating the approved Windows 11 unattended preparation payload.'
        }
        elseif ($isWindows11) {
            'Allowed for creating the approved Windows 11 unattended preparation payload.'
        }
        else {
            'Unsupported host for this Windows 11 preparation workflow.'
        }
        Windows10OptimizationBranches = 'Unsupported, disabled, and not implemented.'
    }
}

function Get-BoostLabUnattendedRemovableDrives {
    try {
        return @(
            Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 2' -ErrorAction Stop |
                Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.DeviceID) } |
                ForEach-Object {
                    [pscustomobject]@{
                        Root = ('{0}\' -f ([string]$_.DeviceID).TrimEnd('\'))
                        Label = [string]$_.VolumeName
                        FreeSpace = [long]$_.FreeSpace
                    }
                }
        )
    }
    catch {
        return @()
    }
}

function Test-BoostLabUnattendedAccountName {
    param([AllowNull()][string]$AccountName)

    return (
        -not [string]::IsNullOrWhiteSpace($AccountName) -and
        $AccountName -match '^[^\\/"\[\]:;|=,+*?<>@\s]{1,20}$'
    )
}

function ConvertTo-BoostLabUnattendedDriveRoot {
    param([AllowNull()][string]$DriveRoot)

    if ([string]::IsNullOrWhiteSpace($DriveRoot)) {
        return ''
    }
    if ($DriveRoot -notmatch '^[a-zA-Z]:\\?$') {
        return ''
    }
    return ('{0}:\' -f $DriveRoot.Substring(0, 1).ToUpperInvariant())
}

function Get-BoostLabUnattendedPaths {
    param(
        [Parameter(Mandatory)][string]$DriveRoot,
        [string]$SystemRoot = $env:SystemRoot,
        [string]$ProgramData = $env:ProgramData,
        [string]$BackupId = ('{0}-{1}' -f (Get-Date -Format 'yyyyMMdd-HHmmssfff'), [guid]::NewGuid().ToString('N'))
    )

    $stateDirectory = Join-Path $ProgramData 'BoostLab\State'
    $backupDirectory = Join-Path $stateDirectory "Backups\Unattended\$BackupId"
    [pscustomobject]@{
        TemplatePath = Join-Path $SystemRoot "Temp\$($script:BoostLabUnattendedTemplateFileName)"
        TempUnattendPath = Join-Path $SystemRoot "Temp\$($script:BoostLabUnattendedFileName)"
        DestinationPath = [IO.Path]::Combine($DriveRoot, $script:BoostLabUnattendedFileName)
        DestinationRoot = $DriveRoot
        StateDirectory = $stateDirectory
        ManifestPath = Join-Path $stateDirectory 'unattended.json'
        BackupDirectory = $backupDirectory
    }
}

function Get-BoostLabUnattendedFileState {
    param([Parameter(Mandatory)][string]$Path)

    if (-not [IO.File]::Exists($Path)) {
        return [pscustomobject]@{
            Exists = $false; Path = $Path; Sha256 = $null; Length = $null
            ReadSucceeded = $true; Message = 'File is absent.'
        }
    }

    try {
        $file = [IO.FileInfo]::new($Path)
        return [pscustomobject]@{
            Exists = $true; Path = $Path
            Sha256 = (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash
            Length = $file.Length; ReadSucceeded = $true; Message = 'File state detected.'
        }
    }
    catch {
        return [pscustomobject]@{
            Exists = $true; Path = $Path; Sha256 = $null; Length = $null
            ReadSucceeded = $false; Message = $_.Exception.Message
        }
    }
}

function Copy-BoostLabUnattendedBackup {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$BackupPath
    )

    try {
        [IO.Directory]::CreateDirectory((Split-Path -Parent $BackupPath)) | Out-Null
        Copy-Item -LiteralPath $SourcePath -Destination $BackupPath -Force -ErrorAction Stop
        $sourceHash = (Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256 -ErrorAction Stop).Hash
        $backupHash = (Get-FileHash -LiteralPath $BackupPath -Algorithm SHA256 -ErrorAction Stop).Hash
        if ($sourceHash -ne $backupHash) {
            throw 'Backup hash does not match the source file.'
        }
        return [pscustomobject]@{
            Success = $true; BackupPath = $BackupPath; Sha256 = $backupHash
            Message = 'Verified backup created.'
        }
    }
    catch {
        return [pscustomobject]@{
            Success = $false; BackupPath = $BackupPath; Sha256 = $null
            Message = $_.Exception.Message
        }
    }
}

function Save-BoostLabUnattendedState {
    param(
        [Parameter(Mandatory)][object]$State,
        [Parameter(Mandatory)][string]$ManifestPath
    )

    [IO.Directory]::CreateDirectory((Split-Path -Parent $ManifestPath)) | Out-Null
    $State | ConvertTo-Json -Depth 10 |
        Set-Content -LiteralPath $ManifestPath -Encoding UTF8 -Force -ErrorAction Stop
}

function Write-BoostLabUnattendedText {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content,
        [ValidateSet('Default', 'Utf8')][string]$Encoding = 'Default'
    )

    if ($Encoding -eq 'Utf8') {
        $utf8WithBom = [Text.UTF8Encoding]::new($true)
        [IO.File]::WriteAllText($Path, $Content, $utf8WithBom)
    }
    else {
        Set-Content -LiteralPath $Path -Value $Content -Force -ErrorAction Stop
    }
}

function Show-BoostLabUnattendedSelectionDialog {
    param([object[]]$Drives = @(Get-BoostLabUnattendedRemovableDrives))

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    if (@($Drives).Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            'Connect writable removable Windows installation media, then try again.',
            'BoostLab Unattended',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return $null
    }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'BoostLab Unattended - Windows 11'
    $form.StartPosition = 'CenterScreen'
    $form.Size = New-Object System.Drawing.Size(560, 270)
    $form.MinimizeBox = $false
    $form.MaximizeBox = $false
    $form.TopMost = $true

    $warning = New-Object System.Windows.Forms.Label
    $warning.Text = 'This creates autounattend.xml with the approved hardware-check bypasses and a blank-password local administrator. Existing source-targeted files are backed up before replacement.'
    $warning.AutoSize = $false
    $warning.Size = New-Object System.Drawing.Size(520, 58)
    $warning.Location = New-Object System.Drawing.Point(16, 12)
    $form.Controls.Add($warning)

    $accountLabel = New-Object System.Windows.Forms.Label
    $accountLabel.Text = 'Local administrator account name (no spaces):'
    $accountLabel.AutoSize = $true
    $accountLabel.Location = New-Object System.Drawing.Point(16, 82)
    $form.Controls.Add($accountLabel)

    $accountText = New-Object System.Windows.Forms.TextBox
    $accountText.Location = New-Object System.Drawing.Point(18, 104)
    $accountText.Size = New-Object System.Drawing.Size(500, 24)
    $form.Controls.Add($accountText)

    $driveLabel = New-Object System.Windows.Forms.Label
    $driveLabel.Text = 'Removable installation media:'
    $driveLabel.AutoSize = $true
    $driveLabel.Location = New-Object System.Drawing.Point(16, 140)
    $form.Controls.Add($driveLabel)

    $driveCombo = New-Object System.Windows.Forms.ComboBox
    $driveCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $driveCombo.Location = New-Object System.Drawing.Point(18, 162)
    $driveCombo.Size = New-Object System.Drawing.Size(500, 24)
    foreach ($drive in @($Drives)) {
        $display = if ([string]::IsNullOrWhiteSpace([string]$drive.Label)) {
            [string]$drive.Root
        }
        else {
            '{0} ({1})' -f [string]$drive.Root, [string]$drive.Label
        }
        [void]$driveCombo.Items.Add([pscustomobject]@{
            Display = $display
            Root = [string]$drive.Root
        })
    }
    $driveCombo.DisplayMember = 'Display'
    $driveCombo.SelectedIndex = 0
    $form.Controls.Add($driveCombo)

    $createButton = New-Object System.Windows.Forms.Button
    $createButton.Text = 'Create File'
    $createButton.Location = New-Object System.Drawing.Point(326, 198)
    $createButton.Size = New-Object System.Drawing.Size(94, 28)
    $createButton.Add_Click({
        if (-not (Test-BoostLabUnattendedAccountName -AccountName $accountText.Text)) {
            [System.Windows.Forms.MessageBox]::Show(
                'Enter a valid local account name of 1-20 characters with no spaces or reserved Windows account-name characters.',
                'BoostLab Unattended',
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
            return
        }
        $form.Tag = [pscustomobject]@{
            AccountName = $accountText.Text
            DriveRoot = [string]$driveCombo.SelectedItem.Root
        }
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    })
    $form.Controls.Add($createButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = 'Cancel'
    $cancelButton.Location = New-Object System.Drawing.Point(426, 198)
    $cancelButton.Size = New-Object System.Drawing.Size(92, 28)
    $cancelButton.Add_Click({
        $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $form.Close()
    })
    $form.Controls.Add($cancelButton)

    if ($form.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }
    return [pscustomobject]$form.Tag
}

function New-BoostLabUnattendedResult {
    param(
        [Parameter(Mandatory)][bool]$Success,
        [Parameter(Mandatory)][string]$Action,
        [Parameter(Mandatory)][string]$Message,
        [string]$Status = $(if ($Success) { 'Success' } else { 'Failed' }),
        [string]$CommandStatus = $(if ($Success) { 'Completed' } else { 'Failed' }),
        [bool]$Cancelled = $false,
        [AllowNull()][object]$Data = $null,
        [AllowNull()][object]$VerificationResult = $null,
        [string[]]$Warnings = @(),
        [string[]]$Errors = @()
    )

    [pscustomobject]@{
        Success = $Success
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Action = $Action
        Status = $Status
        CommandStatus = $CommandStatus
        VerificationStatus = if ($null -ne $VerificationResult) { [string]$VerificationResult.Status } else { 'NotApplicable' }
        Message = $Message
        RestartRequired = $false
        Cancelled = $Cancelled
        Warnings = @($Warnings)
        Errors = @($Errors)
        Data = $Data
        VerificationResult = $VerificationResult
        Timestamp = Get-Date
    }
}

function New-BoostLabUnattendedVerificationResult {
    param(
        [Parameter(Mandatory)][string]$DestinationPath,
        [Parameter(Mandatory)][string]$AccountName,
        [Parameter(Mandatory)][string]$ExpectedContent,
        [Parameter(Mandatory)][object]$DestinationState,
        [Parameter(Mandatory)][object]$TemplateState,
        [Parameter(Mandatory)][object]$TempUnattendState,
        [Parameter(Mandatory)][string]$DetectedContent,
        [int]$BackupCount = 0
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    $checks.Add((New-BoostLabVerificationCheck `
        -Name 'Destination file' `
        -Expected 'autounattend.xml exists on the selected removable-media root' `
        -Actual $(if ($DestinationState.Exists) { $DestinationPath } else { 'Absent' }) `
        -Status $(if ($DestinationState.Exists) { 'Passed' } else { 'Failed' }) `
        -Message 'The final source-defined artifact must exist at the selected drive root.'))

    $checks.Add((New-BoostLabVerificationCheck `
        -Name 'Temporary template cleanup' `
        -Expected 'Absent after account substitution and final artifact creation' `
        -Actual $(if ($TemplateState.Exists) { $TemplateState.Path } else { 'Absent' }) `
        -Status $(if ($TemplateState.Exists) { 'Failed' } else { 'Passed' }) `
        -Message 'The source-defined temporary template must be deleted after it is consumed.'))

    $checks.Add((New-BoostLabVerificationCheck `
        -Name 'Temporary unattended move' `
        -Expected 'Absent after moving the file to removable media' `
        -Actual $(if ($TempUnattendState.Exists) { $TempUnattendState.Path } else { 'Absent' }) `
        -Status $(if ($TempUnattendState.Exists) { 'Failed' } else { 'Passed' }) `
        -Message 'The temporary autounattend.xml must no longer remain in Windows Temp after the move.'))

    $checks.Add((New-BoostLabVerificationCheck `
        -Name 'Pre-existing file backups' `
        -Expected 'Every detected pre-existing source-targeted file was backed up before mutation' `
        -Actual "$BackupCount verified backup(s)" `
        -Status 'Passed' `
        -Message 'A backup failure blocks execution before any source-targeted file is changed.'))

    $contentMatches = $DetectedContent -eq $ExpectedContent
    $checks.Add((New-BoostLabVerificationCheck `
        -Name 'Generated content' `
        -Expected 'Exact approved Ultimate payload with the selected account name' `
        -Actual $(if ($contentMatches) { 'Exact match' } else { 'Content differs' }) `
        -Status $(if ($contentMatches) { 'Passed' } else { 'Failed' }) `
        -Message 'The final XML content is compared with the generated source payload.'))

    $xmlValid = $false
    try {
        [xml]$DetectedContent | Out-Null
        $xmlValid = $true
    }
    catch {
        $xmlValid = $false
    }
    $checks.Add((New-BoostLabVerificationCheck `
        -Name 'XML structure' `
        -Expected 'Valid XML' `
        -Actual $(if ($xmlValid) { 'Valid XML' } else { 'Invalid XML' }) `
        -Status $(if ($xmlValid) { 'Passed' } else { 'Failed' }) `
        -Message 'Windows Setup requires a readable autounattend.xml document.'))

    $accountPresent = (
        $DetectedContent.Contains("<Name>$AccountName</Name>") -and
        $DetectedContent.Contains("net user $AccountName /active:Yes") -and
        $DetectedContent.Contains("net user $AccountName /passwordreq:no")
    )
    $checks.Add((New-BoostLabVerificationCheck `
        -Name 'Account substitution' `
        -Expected $AccountName `
        -Actual $(if ($accountPresent) { $AccountName } else { 'Missing or incomplete' }) `
        -Status $(if ($accountPresent) { 'Passed' } else { 'Failed' }) `
        -Message 'All three source account placeholders must use the selected account name.'))

    $bypassNames = @(
        'BypassTPMCheck'
        'BypassRAMCheck'
        'BypassSecureBootCheck'
        'BypassCPUCheck'
        'BypassStorageCheck'
    )
    foreach ($bypassName in $bypassNames) {
        $present = $DetectedContent.Contains("/v `"$bypassName`" /t REG_DWORD /d 1 /f")
        $checks.Add((New-BoostLabVerificationCheck `
            -Name $bypassName `
            -Expected 'DWORD 1 command present in Windows Setup payload' `
            -Actual $(if ($present) { 'Present' } else { 'Missing' }) `
            -Status $(if ($present) { 'Passed' } else { 'Failed' }) `
            -Message 'This is one of the five source-defined Windows 11 hardware requirement bypasses.'))
    }

    $status = if (@($checks | Where-Object Status -eq 'Failed').Count -gt 0) { 'Failed' } else { 'Passed' }
    return New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action 'Apply' `
        -Status $status `
        -ExpectedState ([pscustomobject]@{
            DestinationPath = $DestinationPath
            AccountName = $AccountName
            HardwareBypasses = $bypassNames
        }) `
        -DetectedState ([pscustomobject]@{
            DestinationPath = $DestinationPath
            FileExists = [bool]$DestinationState.Exists
            Sha256 = $DestinationState.Sha256
            TemplateExistsAfterApply = [bool]$TemplateState.Exists
            TempUnattendExistsAfterApply = [bool]$TempUnattendState.Exists
            AccountName = $AccountName
            BackupCount = $BackupCount
            XmlValid = $xmlValid
        }) `
        -Checks $checks.ToArray() `
        -Message $(if ($status -eq 'Passed') {
            'The Windows 11 autounattend.xml artifact was created and verified.'
        }
        else {
            'The generated autounattend.xml did not pass all verification checks.'
        })
}

function Get-BoostLabUnattendedAnalyzeData {
    param(
        [scriptblock]$WindowsInfoReader = { Get-BoostLabUnattendedWindowsInfo },
        [scriptblock]$DriveReader = { Get-BoostLabUnattendedRemovableDrives }
    )

    $windows = & $WindowsInfoReader
    $hostScope = Get-BoostLabUnattendedHostScope -WindowsInfo $windows
    $drives = @(& $DriveReader)
    [pscustomobject]@{
        CurrentHostOS = $hostScope.CurrentHostOS
        DetectedWindows = $hostScope.DetectedWindows
        HostBuild = $hostScope.HostBuild
        HostIsWindows10 = $hostScope.HostIsWindows10
        HostIsWindows11 = $hostScope.HostIsWindows11
        HostSupportedForWindows11Preparation = $hostScope.SupportedForWindows11Preparation
        HostUsage = $hostScope.HostUsage
        PayloadTarget = $hostScope.PayloadTarget
        Windows10OptimizationBranches = $hostScope.Windows10OptimizationBranches
        RemovableMediaCount = $drives.Count
        OutputFile = 'autounattend.xml at the root of selected removable media'
        LocalAccountBehavior = 'Creates a local Administrators-group account with a blank password and password-required disabled.'
        SetupBehavior = 'Skips OOBE pages, disables Dynamic Update, accepts the EULA, and uses WORKGROUP.'
        HardwareRequirementBypasses = @(
            'TPM'
            'RAM'
            'Secure Boot'
            'CPU'
            'Storage'
        )
        ChangesExecuted = $false
        Warnings = @(
            'The generated file changes Windows Setup behavior when used during installation.'
            'The generated local administrator account has a blank password.'
            'The file bypasses five Windows 11 hardware requirement checks.'
            'Apply overwrites the destination autounattend.xml only after a verified backup.'
            'Windows 10 optimization branches remain unsupported; this tool only prepares the Windows 11 payload.'
        )
    }
}

function Invoke-BoostLabUnattendedApplyAction {
    param(
        [scriptblock]$AdministratorChecker = { Test-BoostLabAdministrator },
        [scriptblock]$WindowsInfoReader = { Get-BoostLabUnattendedWindowsInfo },
        [scriptblock]$DriveReader = { Get-BoostLabUnattendedRemovableDrives },
        [scriptblock]$SelectionProvider = {
            param($Drives)
            Show-BoostLabUnattendedSelectionDialog -Drives $Drives
        },
        [scriptblock]$FileStateReader = {
            param($Path)
            Get-BoostLabUnattendedFileState -Path $Path
        },
        [scriptblock]$BackupWriter = {
            param($SourcePath, $BackupPath)
            Copy-BoostLabUnattendedBackup -SourcePath $SourcePath -BackupPath $BackupPath
        },
        [scriptblock]$StateWriter = {
            param($State, $ManifestPath)
            Save-BoostLabUnattendedState -State $State -ManifestPath $ManifestPath
        },
        [scriptblock]$TextWriter = {
            param($Path, $Content, $Encoding)
            Write-BoostLabUnattendedText -Path $Path -Content $Content -Encoding $Encoding
        },
        [scriptblock]$TextReader = {
            param($Path)
            Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
        },
        [scriptblock]$FileRemover = {
            param($Path)
            Remove-Item -LiteralPath $Path -Force -ErrorAction Stop
        },
        [scriptblock]$FileMover = {
            param($SourcePath, $DestinationPath)
            Move-Item -LiteralPath $SourcePath -Destination $DestinationPath -Force -ErrorAction Stop
        },
        [scriptblock]$DirectoryOpener = {
            param($Path)
            Start-Process -FilePath $Path -ErrorAction Stop
        },
        [string]$SystemRoot = $env:SystemRoot,
        [string]$ProgramData = $env:ProgramData
    )

    if (-not (& $AdministratorChecker)) {
        return New-BoostLabUnattendedResult `
            -Success $false -Action 'Apply' `
            -Message 'Administrator rights are required.' `
            -Errors @('Relaunch BoostLab through bootstrap.ps1.')
    }

    $windows = & $WindowsInfoReader
    $hostScope = Get-BoostLabUnattendedHostScope -WindowsInfo $windows
    if (-not $hostScope.SupportedForWindows11Preparation) {
        return New-BoostLabUnattendedResult `
            -Success $false -Action 'Apply' -Status 'Not applicable' `
            -CommandStatus 'Not applicable' `
            -Message 'This host is not supported for Windows 11 unattended preparation. No changes were executed.' `
            -Data ([pscustomobject]@{
                CurrentHostOS = $hostScope.CurrentHostOS
                DetectedWindows = $hostScope.DetectedWindows
                HostSupportedForWindows11Preparation = $false
                PayloadTarget = $hostScope.PayloadTarget
                Windows10OptimizationBranches = $hostScope.Windows10OptimizationBranches
                ChangesExecuted = $false
            })
    }

    $drives = @(& $DriveReader)
    $selection = & $SelectionProvider $drives
    if ($null -eq $selection) {
        return New-BoostLabUnattendedResult `
            -Success $false -Action 'Apply' -Status 'Cancelled' `
            -CommandStatus 'Cancelled' -Message 'Cancelled by user' -Cancelled $true
    }

    $accountName = [string]$selection.AccountName
    $driveRoot = ConvertTo-BoostLabUnattendedDriveRoot -DriveRoot ([string]$selection.DriveRoot)
    if (-not (Test-BoostLabUnattendedAccountName -AccountName $accountName)) {
        return New-BoostLabUnattendedResult `
            -Success $false -Action 'Apply' `
            -Message 'The selected local account name is invalid.' `
            -Errors @('Use 1-20 characters with no spaces or reserved Windows account-name characters.')
    }
    $approvedDriveRoots = @($drives | ForEach-Object {
        ConvertTo-BoostLabUnattendedDriveRoot -DriveRoot ([string]$_.Root)
    })
    if ([string]::IsNullOrWhiteSpace($driveRoot) -or $driveRoot -notin $approvedDriveRoots) {
        return New-BoostLabUnattendedResult `
            -Success $false -Action 'Apply' `
            -Message 'The selected destination is not currently detected as removable media.' `
            -Errors @('No file changes were executed.')
    }

    $paths = Get-BoostLabUnattendedPaths `
        -DriveRoot $driveRoot -SystemRoot $SystemRoot -ProgramData $ProgramData
    $targetDefinitions = @(
        [pscustomobject]@{ Name = 'Temporary template'; Path = $paths.TemplatePath; BackupName = 'autounattendtemplate.xml' }
        [pscustomobject]@{ Name = 'Temporary unattended file'; Path = $paths.TempUnattendPath; BackupName = 'temp-autounattend.xml' }
        [pscustomobject]@{ Name = 'Destination unattended file'; Path = $paths.DestinationPath; BackupName = 'destination-autounattend.xml' }
    )
    $backups = [System.Collections.Generic.List[object]]::new()
    $changesExecuted = $false

    try {
        foreach ($target in $targetDefinitions) {
            $state = & $FileStateReader $target.Path
            if (-not [bool]$state.ReadSucceeded) {
                throw "Could not inspect $($target.Path): $($state.Message)"
            }
            if ([bool]$state.Exists) {
                $backupPath = Join-Path $paths.BackupDirectory $target.BackupName
                $backup = & $BackupWriter $target.Path $backupPath
                if (-not [bool]$backup.Success) {
                    throw "Backup failed for $($target.Path): $($backup.Message)"
                }
                $backups.Add([pscustomobject]@{
                    Name = $target.Name
                    SourcePath = $target.Path
                    SourceSha256 = $state.Sha256
                    BackupPath = $backup.BackupPath
                    BackupSha256 = $backup.Sha256
                })
            }
        }

        $manifest = [pscustomobject]@{
            ToolId = [string]$script:BoostLabToolMetadata['Id']
            Action = 'Apply'
            Status = 'PendingApply'
            AccountName = $accountName
            DestinationRoot = $paths.DestinationRoot
            DestinationPath = $paths.DestinationPath
            TemplatePath = $paths.TemplatePath
            TempUnattendPath = $paths.TempUnattendPath
            Backups = $backups.ToArray()
            SourceSha256 = $script:BoostLabUnattendedSourceHash
            CurrentHostOS = $hostScope.CurrentHostOS
            HostBuild = $hostScope.HostBuild
            PayloadTarget = $hostScope.PayloadTarget
            StartedAt = Get-Date
        }
        & $StateWriter $manifest $paths.ManifestPath

        & $TextWriter $paths.TemplatePath $script:BoostLabUnattendedTemplate 'Default'
        $changesExecuted = $true
        $accountPayload = $script:BoostLabUnattendedTemplate.Replace('@', $accountName)
        & $TextWriter $paths.TemplatePath $accountPayload 'Default'
        $templateContent = [string](& $TextReader $paths.TemplatePath)
        & $TextWriter $paths.TempUnattendPath $templateContent 'Utf8'
        & $FileRemover $paths.TemplatePath
        & $FileMover $paths.TempUnattendPath $paths.DestinationPath

        $destinationState = & $FileStateReader $paths.DestinationPath
        $templateStateAfterApply = & $FileStateReader $paths.TemplatePath
        $tempUnattendStateAfterApply = & $FileStateReader $paths.TempUnattendPath
        $detectedContent = [string](& $TextReader $paths.DestinationPath)
        $verification = New-BoostLabUnattendedVerificationResult `
            -DestinationPath $paths.DestinationPath `
            -AccountName $accountName `
            -ExpectedContent $templateContent `
            -DestinationState $destinationState `
            -TemplateState $templateStateAfterApply `
            -TempUnattendState $tempUnattendStateAfterApply `
            -DetectedContent $detectedContent `
            -BackupCount $backups.Count

        $manifest.Status = if ($verification.Status -eq 'Passed') { 'Completed' } else { 'VerificationFailed' }
        $manifest | Add-Member -NotePropertyName 'DestinationSha256' -NotePropertyValue $destinationState.Sha256 -Force
        $manifest | Add-Member -NotePropertyName 'CompletedAt' -NotePropertyValue (Get-Date) -Force
        & $StateWriter $manifest $paths.ManifestPath

        $openWarning = $null
        try {
            & $DirectoryOpener $paths.DestinationRoot
        }
        catch {
            $openWarning = "The file was created, but the destination directory could not be opened: $($_.Exception.Message)"
        }

        $success = $verification.Status -eq 'Passed'
        $warnings = @($openWarning | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        return New-BoostLabUnattendedResult `
            -Success $success -Action 'Apply' `
            -Status $(if ($success -and $warnings.Count -gt 0) { 'Warning' } elseif ($success) { 'Success' } else { 'Failed' }) `
            -CommandStatus $(if ($success) { 'Completed' } else { 'Completed with verification failure' }) `
            -Message $(if ($success) { "Windows 11 autounattend.xml created from a $($hostScope.CurrentHostOS) host." } else { $verification.Message }) `
            -Warnings $warnings `
            -Errors $(if ($success) { @() } else { @($verification.Message) }) `
            -Data ([pscustomobject]@{
                CurrentHostOS = $hostScope.CurrentHostOS
                DetectedWindows = $hostScope.DetectedWindows
                HostUsage = $hostScope.HostUsage
                PayloadTarget = $hostScope.PayloadTarget
                Windows10OptimizationBranches = $hostScope.Windows10OptimizationBranches
                DestinationPath = $paths.DestinationPath
                DestinationRoot = $paths.DestinationRoot
                AccountName = $accountName
                BackupCount = $backups.Count
                Backups = $backups.ToArray()
                BackupDirectory = $paths.BackupDirectory
                StatePath = $paths.ManifestPath
                ChangesExecuted = $true
                CompletedAt = Get-Date
            }) `
            -VerificationResult $verification
    }
    catch {
        return New-BoostLabUnattendedResult `
            -Success $false -Action 'Apply' `
            -Message "Unattended file creation failed: $($_.Exception.Message)" `
            -Errors @($_.Exception.Message) `
            -Data ([pscustomobject]@{
                CurrentHostOS = $hostScope.CurrentHostOS
                DetectedWindows = $hostScope.DetectedWindows
                PayloadTarget = $hostScope.PayloadTarget
                Windows10OptimizationBranches = $hostScope.Windows10OptimizationBranches
                DestinationPath = $paths.DestinationPath
                AccountName = $accountName
                BackupCount = $backups.Count
                BackupDirectory = $paths.BackupDirectory
                StatePath = $paths.ManifestPath
                ChangesExecuted = $changesExecuted
            })
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
        Capabilities = [pscustomobject]$script:BoostLabToolMetadata['Capabilities']
        ImplementedActions = @($script:BoostLabImplementedActions)
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [scriptblock]$WindowsInfoReader = { Get-BoostLabUnattendedWindowsInfo }
    )

    $windows = & $WindowsInfoReader
    $hostScope = Get-BoostLabUnattendedHostScope -WindowsInfo $windows
    $supported = [bool]$hostScope.SupportedForWindows11Preparation
    [pscustomobject]@{
        Supported = $supported
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        CurrentHostOS = $hostScope.CurrentHostOS
        PayloadTarget = $hostScope.PayloadTarget
        Windows10OptimizationBranches = $hostScope.Windows10OptimizationBranches
        Reason = if ($supported) {
            if ($hostScope.HostIsWindows10) {
                'Windows 10 may host this Windows 11 preparation workflow. Apply additionally requires writable removable installation media.'
            }
            else {
                'Windows 11 detected. Apply additionally requires writable removable installation media.'
            }
        }
        else {
            'This host is unsupported for the Windows 11 unattended preparation workflow.'
        }
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
        Status = 'Ready'
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
        [Parameter(Mandatory)][string]$ActionName,
        [bool]$Confirmed = $false
    )

    if ($ActionName -notin @($script:BoostLabImplementedActions)) {
        return New-BoostLabUnattendedResult `
            -Success $false -Action $ActionName `
            -Message 'Unsupported action. Only Analyze and Apply are allowed.'
    }

    if ($ActionName -eq 'Analyze') {
        $analysisData = Get-BoostLabUnattendedAnalyzeData
        return New-BoostLabUnattendedResult `
            -Success $true -Action 'Analyze' -CommandStatus 'Read only' `
            -Message "Windows 11 unattended preparation analyzed on a $($analysisData.CurrentHostOS) host. Windows 10 optimization branches remain unsupported." `
            -Data $analysisData
    }

    if (-not $Confirmed) {
        return New-BoostLabUnattendedResult `
            -Success $false -Action 'Apply' -Status 'Cancelled' `
            -CommandStatus 'Cancelled' -Message 'Cancelled by user' -Cancelled $true
    }

    return Invoke-BoostLabUnattendedApplyAction
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return New-BoostLabUnattendedResult `
        -Success $false -Action 'Restore' `
        -Message 'No Default or Restore action exists in the approved Ultimate Unattended source.'
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
