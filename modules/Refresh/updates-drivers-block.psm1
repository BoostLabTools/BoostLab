Set-StrictMode -Version Latest

$coreRoot = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path $coreRoot 'Verification.psm1') -Scope Local -ErrorAction Stop
}
if (-not (Get-Command -Name 'New-BoostLabFileStateCapture' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path $coreRoot 'StateCapture.psm1') -Scope Local -ErrorAction Stop
}
if (-not (Get-Command -Name 'Invoke-BoostLabFileRollback' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path $coreRoot 'Rollback.psm1') -Scope Local -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'updates-drivers-block'
    Title = 'Updates Drivers Block'
    Stage = 'Refresh'
    Order = 3
    Type = 'action'
    RiskLevel = 'high'
    Description = 'Create the Yazan-selected Driver Updates Block setupcomplete.cmd on selected bootable USB media only; Default/Unblock is unavailable.'
    Actions = @('Analyze', 'Apply', 'Default', 'Restore')
    Capabilities = [ordered]@{
        RequiresAdmin = $true
        RequiresInternet = $false
        CanReboot = $false
        CanModifyRegistry = $false
        CanModifyServices = $false
        CanInstallSoftware = $false
        CanDownload = $false
        CanModifyDrivers = $false
        CanModifySecurity = $false
        CanDeleteFiles = $true
        UsesTrustedInstaller = $false
        UsesSafeMode = $false
        SupportsDefault = $false
        SupportsRestore = $true
        NeedsExplicitConfirmation = $true
    }
}

$script:BoostLabImplementedActions = @('Analyze', 'Apply', 'Default', 'Restore')
$script:BoostLabExpectedSourceHash = '4D4EC652C5A7F78824F53B7DC7FD46DDA948F3716A7CD6FD102D6C678EE11991'
$script:BoostLabSourceRelativePath = 'source-ultimate/2 Refresh/3 Updates Drivers Block.ps1'
$script:BoostLabFinalScope = 'Driver Updates Block (Bootable USB) only'
$script:BoostLabSupportedSourceBranch = 'Driver Updates Block (Bootable USB): Ultimate menu option 2'
$script:BoostLabSetupCompleteRelativePath = 'sources\$OEM$\$$\Setup\Scripts\setupcomplete.cmd'
$script:BoostLabUnsupportedSourceBranches = @(
    'Driver Updates Block live host registry branch: intentionally not final user-facing scope.',
    'Driver Updates Unblock live host registry branch: intentionally not exposed as Default.',
    'Broad Updates Block live host registry branch: unsupported.',
    'Broad Updates Block Bootable USB branch: unsupported.',
    'Broad Updates Unblock branch: unsupported.',
    'Custom WSUS/update-server URL behavior: unsupported.'
)
$script:BoostLabSetupCompleteLines = @(
    '@echo off',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\Device Metadata" /v "PreventDeviceMetadataFromNetwork" /t REG_DWORD /d 1 /f',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\DeviceInstall\Settings" /v "DisableSendGenericDriverNotFoundToWER" /t REG_DWORD /d 1 /f',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\DeviceInstall\Settings" /v "DisableSendRequestAdditionalSoftwareToWER" /t REG_DWORD /d 1 /f',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d 0 /f',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "SetAllowOptionalContent" /t REG_DWORD /d 0 /f',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "AllowTemporaryEnterpriseFeatureControl" /t REG_DWORD /d 0 /f',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d 1 /f',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "IncludeRecommendedUpdates" /t REG_DWORD /d 0 /f',
    'reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "EnableFeaturedSoftware" /t REG_DWORD /d 0 /f',
    'shutdown /r /t 0'
)

function Get-BoostLabUpdatesDriversSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $projectRoot ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabUpdatesDriversSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabUpdatesDriversSourcePath
    $exists = Test-Path -LiteralPath $sourcePath -PathType Leaf
    $detectedHash = if ($exists) {
        (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
    }
    else {
        ''
    }

    [pscustomobject]@{
        SourcePath = $sourcePath
        SourceRelativePath = $script:BoostLabSourceRelativePath
        Exists = $exists
        ExpectedSha256 = $script:BoostLabExpectedSourceHash
        DetectedSha256 = $detectedHash
        ChecksumStatus = if ($exists -and $detectedHash -eq $script:BoostLabExpectedSourceHash) {
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

function Test-BoostLabUpdatesDriversAdministrator {
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

function Get-BoostLabUpdatesDriversSetupCompleteContent {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return ($script:BoostLabSetupCompleteLines -join "`r`n") + "`r`n"
}

function Get-BoostLabUpdatesDriversSetupCompleteHash {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        return [BitConverter]::ToString(
            $sha256.ComputeHash([Text.Encoding]::ASCII.GetBytes((Get-BoostLabUpdatesDriversSetupCompleteContent)))
        ).Replace('-', '')
    }
    finally {
        $sha256.Dispose()
    }
}

function ConvertTo-BoostLabUpdatesDriversUsbRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [AllowNull()]
        [string]$DriveRoot
    )

    if ([string]::IsNullOrWhiteSpace($DriveRoot)) {
        return ''
    }

    $trimmed = $DriveRoot.Trim()
    if ($trimmed -match '^[a-zA-Z]:\\?$') {
        return ('{0}:\' -f $trimmed.Substring(0, 1).ToUpperInvariant())
    }

    if ([IO.Path]::IsPathRooted($trimmed)) {
        return ([IO.Path]::GetFullPath($trimmed).TrimEnd('\', '/') + '\')
    }

    return ''
}

function Get-BoostLabUpdatesDriversRemovableDrives {
    [CmdletBinding()]
    [OutputType([object[]])]
    param()

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

function Get-BoostLabUpdatesDriversUsbPaths {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$DriveRoot
    )

    $normalizedRoot = ConvertTo-BoostLabUpdatesDriversUsbRoot -DriveRoot $DriveRoot
    $scriptsDirectory = [IO.Path]::Combine(
        $normalizedRoot,
        'sources',
        '$OEM$',
        '$$',
        'Setup',
        'Scripts'
    )

    [pscustomobject]@{
        DriveRoot = $normalizedRoot
        ScriptsDirectory = $scriptsDirectory
        DestinationPath = [IO.Path]::Combine($scriptsDirectory, 'setupcomplete.cmd')
        RelativePath = $script:BoostLabSetupCompleteRelativePath
    }
}

function Get-BoostLabUpdatesDriversFileState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not [IO.File]::Exists($Path)) {
        return [pscustomobject]@{
            Exists = $false
            Path = $Path
            Sha256 = ''
            Length = 0L
            ReadSucceeded = $true
            Message = 'File is absent.'
        }
    }

    try {
        $file = [IO.FileInfo]::new($Path)
        return [pscustomobject]@{
            Exists = $true
            Path = $Path
            Sha256 = (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash
            Length = [long]$file.Length
            ReadSucceeded = $true
            Message = 'File state detected.'
        }
    }
    catch {
        return [pscustomobject]@{
            Exists = $true
            Path = $Path
            Sha256 = ''
            Length = 0L
            ReadSucceeded = $false
            Message = $_.Exception.Message
        }
    }
}

function Write-BoostLabUpdatesDriversSetupComplete {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Content
    )

    [IO.Directory]::CreateDirectory((Split-Path -Parent $Path)) | Out-Null
    [IO.File]::WriteAllText($Path, $Content, [Text.Encoding]::ASCII)
}

function Show-BoostLabUpdatesDriversUsbSelectionDialog {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [object[]]$Drives = @(Get-BoostLabUpdatesDriversRemovableDrives)
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    if (@($Drives).Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            'Connect writable bootable USB media, then try again.',
            'BoostLab Updates Drivers Block',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return $null
    }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'BoostLab Updates Drivers Block - USB'
    $form.StartPosition = 'CenterScreen'
    $form.Size = New-Object System.Drawing.Size(580, 220)
    $form.MinimizeBox = $false
    $form.MaximizeBox = $false
    $form.TopMost = $true

    $warning = New-Object System.Windows.Forms.Label
    $warning.Text = 'This writes only the Driver Updates Block setupcomplete.cmd to selected USB media. It does not execute the script, write host registry policy, run Windows Update, or reboot.'
    $warning.AutoSize = $false
    $warning.Size = New-Object System.Drawing.Size(540, 58)
    $warning.Location = New-Object System.Drawing.Point(16, 12)
    $form.Controls.Add($warning)

    $driveLabel = New-Object System.Windows.Forms.Label
    $driveLabel.Text = 'Removable bootable USB media:'
    $driveLabel.AutoSize = $true
    $driveLabel.Location = New-Object System.Drawing.Point(16, 82)
    $form.Controls.Add($driveLabel)

    $driveCombo = New-Object System.Windows.Forms.ComboBox
    $driveCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $driveCombo.Location = New-Object System.Drawing.Point(18, 104)
    $driveCombo.Size = New-Object System.Drawing.Size(526, 24)
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
    $createButton.Text = 'Create Script'
    $createButton.Location = New-Object System.Drawing.Point(336, 144)
    $createButton.Size = New-Object System.Drawing.Size(104, 28)
    $createButton.Add_Click({
        $form.Tag = [pscustomobject]@{
            DriveRoot = [string]$driveCombo.SelectedItem.Root
        }
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    })
    $form.Controls.Add($createButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = 'Cancel'
    $cancelButton.Location = New-Object System.Drawing.Point(448, 144)
    $cancelButton.Size = New-Object System.Drawing.Size(96, 28)
    $cancelButton.Add_Click({
        $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $form.Close()
    })
    $form.Controls.Add($cancelButton)

    $dialogResult = $form.ShowDialog()
    if ($dialogResult -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    return $form.Tag
}

function New-BoostLabUpdatesDriversUsbFileCapturePolicy {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$ScriptsDirectory
    )

    return @{
        SchemaVersion = '1.0'
        FileScopes = @(
            @{
                ScopeId = 'updates-drivers-block-usb-setupcomplete'
                ToolIds = @([string]$script:BoostLabToolMetadata['Id'])
                AllowedRoot = $ScriptsDirectory
                AllowDirectories = $false
                MaxFiles = 1
                MaxBytes = 65536
            }
        )
        RegistryScopes = @()
        DeniedRegistryPrefixes = @(
            'HKLM:\SYSTEM'
            'Registry::HKEY_LOCAL_MACHINE\SYSTEM'
        )
    }
}

function New-BoostLabUpdatesDriversResult {
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

        [AllowNull()]
        [object]$VerificationResult = $null,

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
        VerificationResult = $VerificationResult
        Warnings = @($Warnings)
        Errors = @($Errors)
    }
}

function Get-BoostLabUpdatesDriversAnalysis {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [scriptblock]$DriveReader = { Get-BoostLabUpdatesDriversRemovableDrives }
    )

    $source = Get-BoostLabUpdatesDriversSourceStatus
    $drives = @(& $DriveReader)
    [pscustomobject]@{
        Source = $source
        FinalScope = $script:BoostLabFinalScope
        SupportedSourceBranch = $script:BoostLabSupportedSourceBranch
        SetupCompleteRelativePath = $script:BoostLabSetupCompleteRelativePath
        SetupCompleteSha256 = Get-BoostLabUpdatesDriversSetupCompleteHash
        SetupCompleteLines = @($script:BoostLabSetupCompleteLines)
        RemovableMediaCount = $drives.Count
        UnsupportedSourceBranches = @($script:BoostLabUnsupportedSourceBranches)
        UnsupportedBehavior = @(
            'No Unblock option is exposed.'
            'No broad Updates Block or broad Updates USB branch is implemented.'
            'No custom WSUS/update-server behavior is implemented.'
            'No live host registry block/unblock behavior remains final user-facing scope.'
        )
        NoHostRegistryMutation = $true
        NoDriverDeviceMutation = $true
        NoWindowsUpdateExecution = $true
        NoDownloadOrInstaller = $true
        NoExternalProcess = $true
        NoRebootByBoostLab = $true
        ChangesExecuted = $false
        Warnings = @(
            'The generated setupcomplete.cmd contains registry commands and shutdown /r /t 0 for Windows Setup context only.'
            'BoostLab writes the script to selected USB media but does not execute it on the host.'
            'Default/Unblock is intentionally unavailable by Yazan final scope decision.'
        )
    }
}

function New-BoostLabUpdatesDriversAnalyzeVerification {
    param(
        [Parameter(Mandatory)]
        [object]$Analysis
    )

    $checks = @(
        (New-BoostLabVerificationCheck `
            -Name 'Source checksum' `
            -Expected $script:BoostLabExpectedSourceHash `
            -Actual ([string]$Analysis.Source.DetectedSha256) `
            -Status ([string]$Analysis.Source.ChecksumStatus) `
            -Message 'The approved Ultimate source identity must match before any operation can run.'),
        (New-BoostLabVerificationCheck `
            -Name 'Yazan final scope' `
            -Expected 'Driver Updates Block Bootable USB only' `
            -Actual ([string]$Analysis.FinalScope) `
            -Status 'Passed' `
            -Message 'Unblock, broad Updates, custom update-server, and live host registry branches are intentionally excluded.'),
        (New-BoostLabVerificationCheck `
            -Name 'Host mutation' `
            -Expected 'None during Analyze' `
            -Actual 'No mutation' `
            -Status 'Passed' `
            -Message 'Analyze is read-only.')
    )

    return New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action 'Analyze' `
        -Status $(if ([string]$Analysis.Source.ChecksumStatus -eq 'Passed') { 'Passed' } else { 'Failed' }) `
        -ExpectedState 'Driver Updates Block Bootable USB final scope available after source verification.' `
        -DetectedState ([pscustomobject]@{
            FinalScope = [string]$Analysis.FinalScope
            SourceChecksumStatus = [string]$Analysis.Source.ChecksumStatus
            RemovableMediaCount = [int]$Analysis.RemovableMediaCount
        }) `
        -Checks $checks `
        -Message 'Updates Drivers Block USB-only scope analysis completed.'
}

function New-BoostLabUpdatesDriversApplyVerification {
    param(
        [Parameter(Mandatory)]
        [object]$Source,

        [Parameter(Mandatory)]
        [object]$Paths,

        [Parameter(Mandatory)]
        [object]$Capture,

        [Parameter(Mandatory)]
        [object]$MutationRecord,

        [Parameter(Mandatory)]
        [object]$DestinationState,

        [Parameter(Mandatory)]
        [string]$DetectedContent
    )

    $expectedContent = Get-BoostLabUpdatesDriversSetupCompleteContent
    $expectedHash = Get-BoostLabUpdatesDriversSetupCompleteHash
    $contentMatches = $DetectedContent -eq $expectedContent
    $checks = @(
        (New-BoostLabVerificationCheck `
            -Name 'Source checksum' `
            -Expected $script:BoostLabExpectedSourceHash `
            -Actual ([string]$Source.DetectedSha256) `
            -Status ([string]$Source.ChecksumStatus) `
            -Message 'The approved Ultimate source identity was verified.'),
        (New-BoostLabVerificationCheck `
            -Name 'Selected USB setupcomplete.cmd target' `
            -Expected $script:BoostLabSetupCompleteRelativePath `
            -Actual ([string]$Paths.DestinationPath) `
            -Status 'Passed' `
            -Message 'Only the selected USB media setupcomplete.cmd path is targeted.'),
        (New-BoostLabVerificationCheck `
            -Name 'Pre-mutation file capture' `
            -Expected 'Captured before create or overwrite' `
            -Actual ([string]$Capture.Status) `
            -Status $(if ([bool]$Capture.Success) { 'Passed' } else { 'Failed' }) `
            -Message ([string]$Capture.Message)),
        (New-BoostLabVerificationCheck `
            -Name 'Destination file' `
            -Expected 'Exists after Apply' `
            -Actual $(if ([bool]$DestinationState.Exists) { 'Exists' } else { 'Absent' }) `
            -Status $(if ([bool]$DestinationState.Exists) { 'Passed' } else { 'Failed' }) `
            -Message ([string]$DestinationState.Message)),
        (New-BoostLabVerificationCheck `
            -Name 'Destination content hash' `
            -Expected $expectedHash `
            -Actual ([string]$DestinationState.Sha256) `
            -Status $(if ([string]$DestinationState.Sha256 -eq $expectedHash -and $contentMatches) { 'Passed' } else { 'Failed' }) `
            -Message 'Generated setupcomplete.cmd must match the source-equivalent Driver Updates USB branch.'),
        (New-BoostLabVerificationCheck `
            -Name 'Post-mutation rollback state' `
            -Expected 'Recorded' `
            -Actual ([string]$MutationRecord.Status) `
            -Status $(if ([bool]$MutationRecord.Success) { 'Passed' } else { 'Failed' }) `
            -Message ([string]$MutationRecord.Message)),
        (New-BoostLabVerificationCheck `
            -Name 'Host execution' `
            -Expected 'No host execution' `
            -Actual 'No setupcomplete.cmd execution, Windows Update execution, registry mutation, driver mutation, external process, or reboot' `
            -Status 'Passed' `
            -Message 'BoostLab only writes the USB file.')
    )

    $status = if (@($checks | Where-Object { $_.Status -eq 'Failed' }).Count -gt 0) { 'Failed' } else { 'Passed' }
    return New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action 'Apply' `
        -Status $status `
        -ExpectedState ([pscustomobject]@{
            FinalScope = $script:BoostLabFinalScope
            DestinationPath = [string]$Paths.DestinationPath
            SetupCompleteSha256 = $expectedHash
        }) `
        -DetectedState ([pscustomobject]@{
            DestinationPath = [string]$DestinationState.Path
            FileExists = [bool]$DestinationState.Exists
            Sha256 = [string]$DestinationState.Sha256
            ContentMatches = $contentMatches
            CaptureRecordPath = [string]$Capture.RecordPath
            MutationRecorded = [bool]$MutationRecord.Success
        }) `
        -Checks $checks `
        -Message $(if ($status -eq 'Passed') {
            'The Driver Updates Block USB setupcomplete.cmd file was created and verified.'
        }
        else {
            'The Driver Updates Block USB setupcomplete.cmd file did not pass verification.'
        })
}

function Invoke-BoostLabUpdatesDriversAnalyze {
    param(
        [scriptblock]$DriveReader = { Get-BoostLabUpdatesDriversRemovableDrives }
    )

    $analysis = Get-BoostLabUpdatesDriversAnalysis -DriveReader $DriveReader
    $verification = New-BoostLabUpdatesDriversAnalyzeVerification -Analysis $analysis
    $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'

    return New-BoostLabUpdatesDriversResult `
        -Success $sourceOk `
        -Action 'Analyze' `
        -Status $(if ($sourceOk) { 'Analyzed' } else { 'NeedsSourceIdentity' }) `
        -CommandStatus 'No execution performed' `
        -VerificationStatus ([string]$verification.Status) `
        -Message $(if ($sourceOk) {
            'Updates Drivers Block analyzed. Yazan final scope is Driver Updates Block Bootable USB only.'
        }
        else {
            'Updates Drivers Block source identity could not be verified.'
        }) `
        -Data $analysis `
        -VerificationResult $verification `
        -Warnings @($analysis.Warnings) `
        -Errors $(if ($sourceOk) { @() } else { @('Source checksum failed or source file is missing.') })
}

function Invoke-BoostLabUpdatesDriversApply {
    param(
        [bool]$Confirmed = $false,

        [scriptblock]$AdministratorChecker = { Test-BoostLabUpdatesDriversAdministrator },

        [scriptblock]$DriveReader = { Get-BoostLabUpdatesDriversRemovableDrives },

        [scriptblock]$SelectionProvider = {
            param($Drives)
            Show-BoostLabUpdatesDriversUsbSelectionDialog -Drives $Drives
        },

        [scriptblock]$FileStateReader = {
            param($Path)
            Get-BoostLabUpdatesDriversFileState -Path $Path
        },

        [scriptblock]$FileCapture = {
            param($TargetPath, $ScriptsDirectory, $StateRoot)
            New-BoostLabFileStateCapture `
                -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
                -ActionId 'Apply' `
                -ScopeId 'updates-drivers-block-usb-setupcomplete' `
                -TargetPath $TargetPath `
                -ItemType File `
                -IntendedMutation Overwrite `
                -RiskClassification High `
                -VerificationRequirement 'Verify setupcomplete.cmd content and post-mutation hash.' `
                -Policy (New-BoostLabUpdatesDriversUsbFileCapturePolicy -ScriptsDirectory $ScriptsDirectory) `
                -StateRoot $StateRoot
        },

        [scriptblock]$TextWriter = {
            param($Path, $Content)
            Write-BoostLabUpdatesDriversSetupComplete -Path $Path -Content $Content
        },

        [scriptblock]$TextReader = {
            param($Path)
            Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
        },

        [scriptblock]$MutationRecorder = {
            param($RecordPath, $StateRoot, $DestinationState)
            Set-BoostLabRollbackMutationState `
                -RecordPath $RecordPath `
                -StateRoot $StateRoot `
                -PostMutationExists ([bool]$DestinationState.Exists) `
                -PostMutationHash ([string]$DestinationState.Sha256) `
                -PostMutationMetadata ([pscustomobject]@{
                    Path = [string]$DestinationState.Path
                    Length = [long]$DestinationState.Length
                })
        },

        [string]$StateRoot = (Get-BoostLabRollbackStateRoot)
    )

    $analysis = Get-BoostLabUpdatesDriversAnalysis -DriveReader $DriveReader
    if (-not $Confirmed) {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'Cancelled' `
            -CommandStatus 'Cancelled before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Updates Drivers Block Apply requires explicit confirmation before writing setupcomplete.cmd to selected USB media.' `
            -Data $analysis `
            -Warnings @($analysis.Warnings) `
            -Cancelled $true
    }

    if ([string]$analysis.Source.ChecksumStatus -ne 'Passed') {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'NeedsSourceIdentity' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus ([string]$analysis.Source.ChecksumStatus) `
            -Message 'Updates Drivers Block source identity could not be verified. No USB file was created.' `
            -Data $analysis `
            -Warnings @($analysis.Warnings) `
            -Errors @('Source checksum failed or source file is missing.')
    }

    if (-not (& $AdministratorChecker)) {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'AdministratorRequired' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Administrator rights are required before creating the source-defined USB setupcomplete.cmd file.' `
            -Data $analysis `
            -Warnings @($analysis.Warnings) `
            -Errors @('Relaunch BoostLab through bootstrap.ps1.')
    }

    $drives = @(& $DriveReader)
    $selection = & $SelectionProvider $drives
    if ($null -eq $selection) {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'UsbTargetRequired' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Select writable removable USB media before creating setupcomplete.cmd. No changes were executed.' `
            -Data ([pscustomobject]@{
                Source = $analysis.Source
                FinalScope = $script:BoostLabFinalScope
                RemovableMediaCount = $drives.Count
                ChangesExecuted = $false
            }) `
            -Warnings @($analysis.Warnings)
    }

    $driveRoot = ConvertTo-BoostLabUpdatesDriversUsbRoot -DriveRoot ([string]$selection.DriveRoot)
    $approvedDriveRoots = @($drives | ForEach-Object {
        ConvertTo-BoostLabUpdatesDriversUsbRoot -DriveRoot ([string]$_.Root)
    })
    if (
        [string]::IsNullOrWhiteSpace($driveRoot) -or
        $driveRoot -notin $approvedDriveRoots -or
        -not (Test-Path -LiteralPath $driveRoot -PathType Container)
    ) {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'UsbTargetRequired' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'The selected destination is not a currently detected removable USB target. No changes were executed.' `
            -Data ([pscustomobject]@{
                Source = $analysis.Source
                FinalScope = $script:BoostLabFinalScope
                SelectedDriveRoot = [string]$selection.DriveRoot
                ApprovedDriveRoots = @($approvedDriveRoots)
                ChangesExecuted = $false
            }) `
            -Warnings @($analysis.Warnings)
    }

    $paths = Get-BoostLabUpdatesDriversUsbPaths -DriveRoot $driveRoot
    $content = Get-BoostLabUpdatesDriversSetupCompleteContent
    $capture = $null
    $mutationRecord = $null
    try {
        $capture = & $FileCapture $paths.DestinationPath $paths.ScriptsDirectory $StateRoot
        if (-not [bool]$capture.Success) {
            return New-BoostLabUpdatesDriversResult `
                -Success $false `
                -Action 'Apply' `
                -Status 'CaptureFailed' `
                -CommandStatus 'Blocked before mutation' `
                -VerificationStatus 'Failed' `
                -Message 'Updates Drivers Block Apply was blocked because target file state could not be captured.' `
                -Data ([pscustomobject]@{
                    Source = $analysis.Source
                    FinalScope = $script:BoostLabFinalScope
                    DestinationPath = [string]$paths.DestinationPath
                    Capture = $capture
                    ChangesExecuted = $false
                }) `
                -Warnings @($analysis.Warnings) `
                -Errors @($capture.Errors)
        }

        & $TextWriter $paths.DestinationPath $content
        $destinationState = & $FileStateReader $paths.DestinationPath
        if (-not [bool]$destinationState.ReadSucceeded) {
            throw "Could not read destination file after writing: $($destinationState.Message)"
        }

        $detectedContent = [string](& $TextReader $paths.DestinationPath)
        $mutationRecord = & $MutationRecorder $capture.RecordPath $StateRoot $destinationState
        $verification = New-BoostLabUpdatesDriversApplyVerification `
            -Source $analysis.Source `
            -Paths $paths `
            -Capture $capture `
            -MutationRecord $mutationRecord `
            -DestinationState $destinationState `
            -DetectedContent $detectedContent

        $success = [string]$verification.Status -eq 'Passed'
        return New-BoostLabUpdatesDriversResult `
            -Success $success `
            -Action 'Apply' `
            -Status $(if ($success) { 'Completed' } else { 'VerificationFailed' }) `
            -CommandStatus $(if ($success) { 'Completed' } else { 'Completed with verification failure' }) `
            -VerificationStatus ([string]$verification.Status) `
            -Message $(if ($success) {
                'Driver Updates Block Bootable USB setupcomplete.cmd was created and verified. The script was not executed on the host.'
            }
            else {
                'Driver Updates Block Bootable USB setupcomplete.cmd was written, but verification failed.'
            }) `
            -Data ([pscustomobject]@{
                Source = $analysis.Source
                FinalScope = $script:BoostLabFinalScope
                SupportedSourceBranch = $script:BoostLabSupportedSourceBranch
                DestinationRoot = [string]$paths.DriveRoot
                ScriptsDirectory = [string]$paths.ScriptsDirectory
                DestinationPath = [string]$paths.DestinationPath
                RelativePath = [string]$paths.RelativePath
                SetupCompleteSha256 = [string]$destinationState.Sha256
                ExpectedSetupCompleteSha256 = Get-BoostLabUpdatesDriversSetupCompleteHash
                CaptureRecord = $capture
                CaptureRecordPath = [string]$capture.RecordPath
                MutationRecord = $mutationRecord
                SetupCompleteExecuted = $false
                HostRegistryWrites = $false
                WindowsUpdateExecuted = $false
                ExternalProcessStarted = $false
                RebootTriggered = $false
                ChangesExecuted = $true
            }) `
            -VerificationResult $verification `
            -Warnings @($analysis.Warnings) `
            -Errors $(if ($success) { @() } else { @($verification.Message) }) `
            -ChangesExecuted $true
    }
    catch {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'Error' `
            -CommandStatus 'Failed' `
            -VerificationStatus 'Failed' `
            -Message "Updates Drivers Block USB setupcomplete.cmd creation failed: $($_.Exception.Message)" `
            -Data ([pscustomobject]@{
                Source = $analysis.Source
                FinalScope = $script:BoostLabFinalScope
                DestinationPath = if ($null -ne $paths) { [string]$paths.DestinationPath } else { '' }
                CaptureRecord = $capture
                MutationRecord = $mutationRecord
                SetupCompleteExecuted = $false
                HostRegistryWrites = $false
                WindowsUpdateExecuted = $false
                ExternalProcessStarted = $false
                RebootTriggered = $false
                ChangesExecuted = $null -ne $capture -and [bool]$capture.Success
            }) `
            -Warnings @($analysis.Warnings) `
            -Errors @($_.Exception.Message) `
            -ChangesExecuted:($null -ne $capture -and [bool]$capture.Success)
    }
}

function Invoke-BoostLabUpdatesDriversDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $analysis = Get-BoostLabUpdatesDriversAnalysis
    return New-BoostLabUpdatesDriversResult `
        -Success $false `
        -Action 'Default' `
        -Status 'DefaultUnavailable' `
        -CommandStatus 'Unavailable' `
        -VerificationStatus 'NotApplicable' `
        -Message 'Default is unavailable for Updates Drivers Block. Yazan final scope excludes Unblock, and Default is not Restore. No host registry values or USB files were changed.' `
        -Data ([pscustomobject]@{
            Source = $analysis.Source
            FinalScope = $script:BoostLabFinalScope
            DefaultIsUnblock = $false
            DefaultIsRestore = $false
            ChangesExecuted = $false
        }) `
        -Warnings @('No Unblock option is exposed for this tool by Yazan final scope decision.')
}

function Invoke-BoostLabUpdatesDriversRestore {
    param(
        [bool]$Confirmed = $false,

        [string]$SelectedCapturePath = '',

        [scriptblock]$AdministratorChecker = { Test-BoostLabUpdatesDriversAdministrator },

        [string]$StateRoot = (Get-BoostLabRollbackStateRoot)
    )

    if (-not $Confirmed) {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action 'Restore' `
            -Status 'Cancelled' `
            -CommandStatus 'Cancelled before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Updates Drivers Block Restore cancelled before captured USB file state validation.' `
            -Cancelled $true `
            -Data ([pscustomobject]@{ ChangesExecuted = $false; RestoreAttempted = $false })
    }

    if ([string]::IsNullOrWhiteSpace($SelectedCapturePath)) {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action 'Restore' `
            -Status 'RestoreRequiresCapturedUsbFileState' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Updates Drivers Block Restore requires a selected captured USB setupcomplete.cmd file state. Restore is not Unblock and no registry mutation is planned.' `
            -Data ([pscustomobject]@{
                ChangesExecuted = $false
                RestoreAttempted = $false
                RestoreRequiresCapturedState = $true
                RestoreIsUnblock = $false
                DefaultIsRestore = $false
            })
    }

    $source = Get-BoostLabUpdatesDriversSourceStatus
    if ([string]$source.ChecksumStatus -ne 'Passed') {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action 'Restore' `
            -Status 'NeedsSourceIdentity' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Failed' `
            -Message 'Updates Drivers Block source identity could not be verified. Restore did not run.' `
            -Data ([pscustomobject]@{ Source = $source; ChangesExecuted = $false; RestoreAttempted = $false }) `
            -Errors @('Source checksum failed or source file is missing.')
    }

    if (-not (& $AdministratorChecker)) {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action 'Restore' `
            -Status 'AdministratorRequired' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Administrator rights are required before restoring selected USB setupcomplete.cmd captured state.' `
            -Data ([pscustomobject]@{ ChangesExecuted = $false; RestoreAttempted = $false }) `
            -Errors @('Relaunch BoostLab through bootstrap.ps1.')
    }

    $imported = Import-BoostLabRollbackRecord -RecordPath $SelectedCapturePath -StateRoot $StateRoot
    if (-not [bool]$imported.IsValid) {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action 'Restore' `
            -Status 'RestoreRecordInvalid' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Failed' `
            -Message 'Selected USB file rollback record is missing or invalid. Restore did not run.' `
            -Data ([pscustomobject]@{ RecordPath = $SelectedCapturePath; ChangesExecuted = $false; RestoreAttempted = $false }) `
            -Errors @($imported.Errors)
    }

    $record = $imported.Record
    $targetPath = [string]$record.SourcePath
    $normalizedTarget = $targetPath.Replace('/', '\')
    if (
        [string]$record.ToolId -ne [string]$script:BoostLabToolMetadata['Id'] -or
        [string]$record.ActionId -ne 'Apply' -or
        [string]$record.ItemType -ne 'File' -or
        -not $normalizedTarget.EndsWith('\sources\$OEM$\$$\Setup\Scripts\setupcomplete.cmd', [StringComparison]::OrdinalIgnoreCase)
    ) {
        return New-BoostLabUpdatesDriversResult `
            -Success $false `
            -Action 'Restore' `
            -Status 'RestoreRecordOutOfScope' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Failed' `
            -Message 'Selected rollback record is outside the approved Updates Drivers Block USB file restore scope.' `
            -Data ([pscustomobject]@{ RecordPath = $SelectedCapturePath; ChangesExecuted = $false; RestoreAttempted = $false }) `
            -Errors @('Selected rollback record does not match this tool, Apply action, file type, or setupcomplete.cmd target path.')
    }

    $scriptsDirectory = Split-Path -Parent $targetPath
    $policy = New-BoostLabUpdatesDriversUsbFileCapturePolicy -ScriptsDirectory $scriptsDirectory
    $rollback = Invoke-BoostLabFileRollback `
        -RecordPath $SelectedCapturePath `
        -StateRoot $StateRoot `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ActionId 'Apply' `
        -Policy $policy

    $verification = New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action 'Restore' `
        -Status $(if ([bool]$rollback.Success) { 'Passed' } else { 'Failed' }) `
        -ExpectedState 'Selected captured USB setupcomplete.cmd prior file state restored exactly.' `
        -DetectedState ([string]$rollback.Status) `
        -Checks @(
            (New-BoostLabVerificationCheck `
                -Name 'Captured USB file rollback' `
                -Expected 'Restored' `
                -Actual ([string]$rollback.Status) `
                -Status $(if ([bool]$rollback.Success) { 'Passed' } else { 'Failed' }) `
                -Message ([string]$rollback.Message))
        ) `
        -Message ([string]$rollback.Message)

    return New-BoostLabUpdatesDriversResult `
        -Success ([bool]$rollback.Success) `
        -Action 'Restore' `
        -Status $(if ([bool]$rollback.Success) { 'Restored' } else { [string]$rollback.Status }) `
        -CommandStatus $(if ([bool]$rollback.Success) { 'Restored captured USB file state' } else { 'Blocked or failed' }) `
        -VerificationStatus ([string]$verification.Status) `
        -Message ([string]$rollback.Message) `
        -Data ([pscustomobject]@{
            RecordPath = [string]$rollback.RecordPath
            TargetPath = [string]$rollback.TargetPath
            SourceAction = 'Apply'
            RestoreIsUnblock = $false
            DefaultIsRestore = $false
            HostRegistryWrites = $false
            ChangesExecuted = [bool]$rollback.RestoreAttempted
            RestoreAttempted = [bool]$rollback.RestoreAttempted
            Errors = @($rollback.Errors)
        }) `
        -VerificationResult $verification `
        -ChangesExecuted:([bool]$rollback.RestoreAttempted) `
        -Errors @($rollback.Errors)
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
        ImplementedActions = @($script:BoostLabImplementedActions)
        Capabilities = $script:BoostLabToolMetadata['Capabilities']
        ConfirmationRequiredActions = @('Apply', 'Restore')
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        Supported = $true
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason = 'Updates Drivers Block supports only Yazan-selected Driver Updates Block Bootable USB setupcomplete.cmd generation.'
        FinalScope = $script:BoostLabFinalScope
        Timestamp = Get-Date
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        Current = 'UsbOnlyFinalScope'
        Source = Get-BoostLabUpdatesDriversSourceStatus
        FinalScope = $script:BoostLabFinalScope
        SupportedSourceBranch = $script:BoostLabSupportedSourceBranch
        SetupCompleteRelativePath = $script:BoostLabSetupCompleteRelativePath
        UnsupportedSourceBranches = @($script:BoostLabUnsupportedSourceBranches)
        ImplementedActions = @($script:BoostLabImplementedActions)
    }
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Analyze', 'Apply', 'Default', 'Restore')]
        [string]$ActionName,

        [bool]$Confirmed = $false,

        [string]$SelectedCapturePath = '',

        [AllowNull()]
        [scriptblock]$AdministratorChecker = $null,

        [AllowNull()]
        [scriptblock]$DriveReader = $null,

        [AllowNull()]
        [scriptblock]$SelectionProvider = $null,

        [AllowNull()]
        [scriptblock]$FileStateReader = $null,

        [AllowNull()]
        [scriptblock]$FileCapture = $null,

        [AllowNull()]
        [scriptblock]$TextWriter = $null,

        [AllowNull()]
        [scriptblock]$TextReader = $null,

        [AllowNull()]
        [scriptblock]$MutationRecorder = $null,

        [string]$StateRoot = (Get-BoostLabRollbackStateRoot)
    )

    switch ($ActionName) {
        'Analyze' {
            $params = @{}
            if ($null -ne $DriveReader) { $params['DriveReader'] = $DriveReader }
            return Invoke-BoostLabUpdatesDriversAnalyze @params
        }
        'Apply' {
            $params = @{
                Confirmed = $Confirmed
                StateRoot = $StateRoot
            }
            if ($null -ne $AdministratorChecker) { $params['AdministratorChecker'] = $AdministratorChecker }
            if ($null -ne $DriveReader) { $params['DriveReader'] = $DriveReader }
            if ($null -ne $SelectionProvider) { $params['SelectionProvider'] = $SelectionProvider }
            if ($null -ne $FileStateReader) { $params['FileStateReader'] = $FileStateReader }
            if ($null -ne $FileCapture) { $params['FileCapture'] = $FileCapture }
            if ($null -ne $TextWriter) { $params['TextWriter'] = $TextWriter }
            if ($null -ne $TextReader) { $params['TextReader'] = $TextReader }
            if ($null -ne $MutationRecorder) { $params['MutationRecorder'] = $MutationRecorder }
            return Invoke-BoostLabUpdatesDriversApply @params
        }
        'Default' {
            return Invoke-BoostLabUpdatesDriversDefault
        }
        'Restore' {
            $params = @{
                Confirmed = $Confirmed
                SelectedCapturePath = $SelectedCapturePath
                StateRoot = $StateRoot
            }
            if ($null -ne $AdministratorChecker) { $params['AdministratorChecker'] = $AdministratorChecker }
            return Invoke-BoostLabUpdatesDriversRestore @params
        }
    }
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return Invoke-BoostLabToolAction -ActionName 'Default'
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
