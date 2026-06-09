Set-StrictMode -Version Latest

$script:ToolInfo = [ordered]@{
    Id = 'signout-lockscreen-wallpaper-black'
    Title = 'Signout LockScreen Wallpaper Black'
    Stage = 'Windows'
    Order = 5
    Type = 'action'
    RiskLevel = 'medium'
    Description = 'Apply a generated black sign-out, lock screen, and desktop wallpaper or safely restore the approved default.'
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

$script:TargetPath = 'C:\Windows\Black.jpg'
$script:DefaultWallpaperPath = 'C:\Windows\Web\Wallpaper\Windows\img0.jpg'
$script:PersonalizationCspKey = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP'
$script:DesktopKey = 'HKCU\Control Panel\Desktop'

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
Import-Module `
    -Name $verificationModulePath `
    -Scope Local `
    -ErrorAction Stop

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    param()

    return [pscustomobject]@{
        Id                 = [string]$script:ToolInfo['Id']
        Title              = [string]$script:ToolInfo['Title']
        Stage              = [string]$script:ToolInfo['Stage']
        Order              = [int]$script:ToolInfo['Order']
        Type               = [string]$script:ToolInfo['Type']
        RiskLevel          = [string]$script:ToolInfo['RiskLevel']
        Description        = [string]$script:ToolInfo['Description']
        Actions            = @($script:ToolInfo['Actions'])
        Capabilities       = [pscustomobject]$script:ToolInfo['Capabilities']
        ImplementedActions = @($script:BoostLabImplementedActions)
    }
}

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

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    param()

    $reasons = [System.Collections.Generic.List[string]]::new()
    if ($env:OS -ne 'Windows_NT') {
        $reasons.Add('This tool requires Windows.')
    }

    if (-not (Test-Path -LiteralPath 'C:\Windows')) {
        $reasons.Add('The original Ultimate target path C:\Windows is unavailable.')
    }
    if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        $reasons.Add('The Windows system directory is unavailable.')
    }
    else {
        foreach ($requiredPath in @(
            (Join-Path $env:SystemRoot 'System32\cmd.exe')
            (Join-Path $env:SystemRoot 'System32\rundll32.exe')
        )) {
            if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
                $reasons.Add("Required Windows command was not found: $requiredPath")
            }
        }
    }
    if ([string]::IsNullOrWhiteSpace($env:ProgramData)) {
        $reasons.Add('ProgramData is unavailable for ownership and backup metadata.')
    }

    $supported = $reasons.Count -eq 0
    [pscustomobject]@{
        Supported = $supported
        Reason    = if ($supported) { 'Windows image, registry, and wallpaper refresh support are available.' } else { $reasons -join ' ' }
        Reasons   = @($reasons)
    }
}

function Get-BoostLabWallpaperStatePaths {
    [CmdletBinding()]
    param()

    $programData = if ([string]::IsNullOrWhiteSpace($env:ProgramData)) {
        [Environment]::GetFolderPath([Environment+SpecialFolder]::CommonApplicationData)
    }
    else {
        $env:ProgramData
    }

    $stateDirectory = Join-Path $programData 'BoostLab\State'
    $backupDirectory = Join-Path $stateDirectory 'Backups\SignoutLockScreenWallpaperBlack'

    [pscustomobject]@{
        StateDirectory  = $stateDirectory
        BackupDirectory = $backupDirectory
        MetadataPath    = Join-Path $stateDirectory 'signout-lockscreen-wallpaper-black.json'
    }
}

function Get-BoostLabWallpaperOwnershipState {
    [CmdletBinding()]
    param()

    $paths = Get-BoostLabWallpaperStatePaths
    if (-not [IO.File]::Exists($paths.MetadataPath)) {
        return [pscustomobject]@{
            ReadSucceeded      = $true
            Exists             = $false
            Active             = $false
            CreatedByBoostLab  = $false
            PendingApply       = $false
            BackupCreated      = $false
            BackupPath         = $null
            OriginalFileSha256 = $null
            GeneratedFileSha256 = $null
            OwnershipUncertain = $false
            FileDisposition    = 'NoState'
            MetadataPath       = $paths.MetadataPath
            ErrorMessage       = $null
        }
    }

    try {
        $state = [IO.File]::ReadAllText($paths.MetadataPath) | ConvertFrom-Json -ErrorAction Stop
        $state | Add-Member -NotePropertyName ReadSucceeded -NotePropertyValue $true -Force
        $state | Add-Member -NotePropertyName Exists -NotePropertyValue $true -Force
        $state | Add-Member -NotePropertyName MetadataPath -NotePropertyValue $paths.MetadataPath -Force
        $state | Add-Member -NotePropertyName ErrorMessage -NotePropertyValue $null -Force
        return $state
    }
    catch {
        return [pscustomobject]@{
            ReadSucceeded      = $false
            Exists             = $true
            Active             = $false
            CreatedByBoostLab  = $false
            PendingApply       = $false
            BackupCreated      = $false
            BackupPath         = $null
            OriginalFileSha256 = $null
            GeneratedFileSha256 = $null
            OwnershipUncertain = $true
            FileDisposition    = 'StateReadFailed'
            MetadataPath       = $paths.MetadataPath
            ErrorMessage       = $_.Exception.Message
        }
    }
}

function Save-BoostLabWallpaperOwnershipState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State
    )

    try {
        $paths = Get-BoostLabWallpaperStatePaths
        [void][IO.Directory]::CreateDirectory($paths.StateDirectory)
        $json = $State | ConvertTo-Json -Depth 8
        [IO.File]::WriteAllText($paths.MetadataPath, $json, [Text.UTF8Encoding]::new($false))

        [pscustomobject]@{
            Success      = $true
            MetadataPath = $paths.MetadataPath
            Message      = 'Ownership metadata saved.'
        }
    }
    catch {
        [pscustomobject]@{
            Success      = $false
            MetadataPath = (Get-BoostLabWallpaperStatePaths).MetadataPath
            Message      = $_.Exception.Message
        }
    }
}

function Get-BoostLabWallpaperFileState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    if (-not [IO.File]::Exists($Path)) {
        return [pscustomobject]@{
            Exists       = $false
            Path         = $Path
            Length       = $null
            Sha256       = $null
            HashDetected = $false
            ErrorMessage = $null
        }
    }

    try {
        $file = [IO.FileInfo]::new($Path)
        $hash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash
        [pscustomobject]@{
            Exists       = $true
            Path         = $Path
            Length       = $file.Length
            Sha256       = $hash
            HashDetected = $true
            ErrorMessage = $null
        }
    }
    catch {
        [pscustomobject]@{
            Exists       = $true
            Path         = $Path
            Length       = $null
            Sha256       = $null
            HashDetected = $false
            ErrorMessage = $_.Exception.Message
        }
    }
}

function Backup-BoostLabWallpaperFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $SourcePath
    )

    try {
        $paths = Get-BoostLabWallpaperStatePaths
        [void][IO.Directory]::CreateDirectory($paths.BackupDirectory)
        $stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
        $backupPath = Join-Path $paths.BackupDirectory "Black.jpg.$stamp.backup"
        [IO.File]::Copy($SourcePath, $backupPath, $false)
        $backupState = Get-BoostLabWallpaperFileState -Path $backupPath

        [pscustomobject]@{
            Success    = $true
            BackupPath = $backupPath
            Sha256     = $backupState.Sha256
            Message    = 'Pre-existing Black.jpg backed up.'
        }
    }
    catch {
        [pscustomobject]@{
            Success    = $false
            BackupPath = $null
            Sha256     = $null
            Message    = $_.Exception.Message
        }
    }
}

function Restore-BoostLabWallpaperBackup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $BackupPath,

        [Parameter(Mandatory)]
        [string] $TargetPath
    )

    try {
        if (-not [IO.File]::Exists($BackupPath)) {
            throw "The recorded backup does not exist: $BackupPath"
        }

        [IO.File]::Copy($BackupPath, $TargetPath, $true)
        [pscustomobject]@{
            Success = $true
            Message = 'Pre-existing Black.jpg restored from the BoostLab backup.'
        }
    }
    catch {
        [pscustomobject]@{
            Success = $false
            Message = $_.Exception.Message
        }
    }
}

function Remove-BoostLabOwnedWallpaperFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    try {
        if ([IO.File]::Exists($Path)) {
            [IO.File]::Delete($Path)
        }

        [pscustomobject]@{
            Success = $true
            Message = 'BoostLab-owned Black.jpg removed.'
        }
    }
    catch {
        [pscustomobject]@{
            Success = $false
            Message = $_.Exception.Message
        }
    }
}

function New-BoostLabBlackWallpaperImage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop

    $primaryMonitorSize = [System.Windows.Forms.SystemInformation]::PrimaryMonitorSize
    $bitmap = $null
    $graphics = $null
    $brush = $null

    try {
        $bitmap = New-Object System.Drawing.Bitmap $primaryMonitorSize.Width, $primaryMonitorSize.Height
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $brush = [System.Drawing.Brushes]::Black
        $graphics.FillRectangle($brush, 0, 0, $bitmap.Width, $bitmap.Height)
        $graphics.Dispose()
        $graphics = $null
        $bitmap.Save($Path)

        [pscustomobject]@{
            Success = $true
            Width   = $primaryMonitorSize.Width
            Height  = $primaryMonitorSize.Height
            Message = 'Generated a black wallpaper at {0}x{1}.' -f $primaryMonitorSize.Width, $primaryMonitorSize.Height
        }
    }
    catch {
        [pscustomobject]@{
            Success = $false
            Width   = $primaryMonitorSize.Width
            Height  = $primaryMonitorSize.Height
            Message = $_.Exception.Message
        }
    }
    finally {
        if ($graphics) { $graphics.Dispose() }
        if ($bitmap) { $bitmap.Dispose() }
    }
}

function Invoke-BoostLabSignoutWallpaperRegistryCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Operation
    )

    $commandText = switch ($Operation.Operation) {
        'Add' {
            'reg add "{0}" /v "{1}" /t {2} /d "{3}" /f' -f `
                $Operation.Key, `
                $Operation.Name, `
                $Operation.Type, `
                [string]$Operation.Value
        }
        'DeleteValue' {
            'reg delete "{0}" /v "{1}" /f' -f $Operation.Key, $Operation.Name
        }
        default {
            throw "Unsupported registry operation '$($Operation.Operation)'."
        }
    }

    $commandProcessorPath = Join-Path $env:SystemRoot 'System32\cmd.exe'
    $output = & $commandProcessorPath /d /c $commandText 2>&1
    $exitCode = $LASTEXITCODE
    $message = (@($output) | ForEach-Object { [string]$_ }) -join [Environment]::NewLine

    [pscustomobject]@{
        Success   = ($exitCode -eq 0)
        ExitCode  = $exitCode
        Operation = $Operation.Operation
        Key       = $Operation.Key
        Name      = $Operation.Name
        Message   = $message
    }
}

function Invoke-BoostLabWallpaperRefresh {
    [CmdletBinding()]
    param()

    try {
        $rundll32Path = Join-Path $env:SystemRoot 'System32\rundll32.exe'
        & $rundll32Path 'user32.dll,' 'UpdatePerUserSystemParameters'
        $exitCode = $LASTEXITCODE

        [pscustomobject]@{
            Success  = ($null -eq $exitCode -or $exitCode -eq 0)
            ExitCode = $exitCode
            Message  = if ($null -eq $exitCode -or $exitCode -eq 0) {
                'Wallpaper refresh requested.'
            }
            else {
                "Wallpaper refresh exited with code $exitCode."
            }
        }
    }
    catch {
        [pscustomobject]@{
            Success  = $false
            ExitCode = $null
            Message  = $_.Exception.Message
        }
    }
}

function Get-BoostLabRegistryValueState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Key,

        [Parameter(Mandatory)]
        [string] $Name
    )

    $normalizedKey = $Key -replace '^HKLM\\', 'HKLM:\' -replace '^HKCU\\', 'HKCU:\'
    try {
        $item = Get-ItemProperty -LiteralPath $normalizedKey -Name $Name -ErrorAction Stop
        [pscustomobject]@{
            Detected     = $true
            Exists       = $true
            Value        = $item.$Name
            ErrorMessage = $null
        }
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        [pscustomobject]@{
            Detected     = $true
            Exists       = $false
            Value        = $null
            ErrorMessage = $null
        }
    }
    catch [System.Management.Automation.PSArgumentException] {
        [pscustomobject]@{
            Detected     = $true
            Exists       = $false
            Value        = $null
            ErrorMessage = $null
        }
    }
    catch {
        [pscustomobject]@{
            Detected     = $false
            Exists       = $false
            Value        = $null
            ErrorMessage = $_.Exception.Message
        }
    }
}

function Get-BoostLabStateProperty {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $InputObject,

        [Parameter(Mandatory)]
        [string] $Name,

        [AllowNull()]
        [object] $DefaultValue = $null
    )

    if ($null -eq $InputObject) {
        return $DefaultValue
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $DefaultValue
    }

    return $property.Value
}

function Test-BoostLabSignoutWallpaperState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string] $ActionName,

        [AllowNull()]
        [object] $OwnershipState,

        [scriptblock] $RegistryReader = {
            param($Key, $Name)
            Get-BoostLabRegistryValueState -Key $Key -Name $Name
        },

        [scriptblock] $FileReader = {
            param($Path)
            Get-BoostLabWallpaperFileState -Path $Path
        }
    )

    $definitions = if ($ActionName -eq 'Apply') {
        @(
            [pscustomobject]@{
                Name     = 'LockScreenImagePath'
                Key      = $script:PersonalizationCspKey
                Value    = $script:TargetPath
                MustExist = $true
            }
            [pscustomobject]@{
                Name     = 'LockScreenImageStatus'
                Key      = $script:PersonalizationCspKey
                Value    = 1
                MustExist = $true
            }
            [pscustomobject]@{
                Name     = 'Wallpaper'
                Key      = $script:DesktopKey
                Value    = $script:TargetPath
                MustExist = $true
            }
        )
    }
    else {
        @(
            [pscustomobject]@{
                Name     = 'LockScreenImagePath'
                Key      = $script:PersonalizationCspKey
                Value    = $null
                MustExist = $false
            }
            [pscustomobject]@{
                Name     = 'LockScreenImageStatus'
                Key      = $script:PersonalizationCspKey
                Value    = $null
                MustExist = $false
            }
            [pscustomobject]@{
                Name     = 'Wallpaper'
                Key      = $script:DesktopKey
                Value    = $script:DefaultWallpaperPath
                MustExist = $true
            }
        )
    }

    $checks = [System.Collections.Generic.List[object]]::new()
    foreach ($definition in $definitions) {
        $detected = & $RegistryReader $definition.Key $definition.Name
        $status = 'Warning'
        $message = 'Registry state could not be detected.'

        if ([bool](Get-BoostLabStateProperty $detected 'Detected' $false)) {
            $exists = [bool](Get-BoostLabStateProperty $detected 'Exists' $false)
            if (-not $definition.MustExist) {
                $status = if ($exists) { 'Failed' } else { 'Passed' }
                $message = if ($exists) {
                    "$($definition.Name) still exists."
                }
                else {
                    "$($definition.Name) is absent as expected."
                }
            }
            elseif (-not $exists) {
                $status = 'Failed'
                $message = "$($definition.Name) is missing."
            }
            else {
                $actual = Get-BoostLabStateProperty $detected 'Value'
                $matches = [string]$actual -eq [string]$definition.Value
                $status = if ($matches) { 'Passed' } else { 'Failed' }
                $message = if ($matches) {
                    "$($definition.Name) matches the expected value."
                }
                else {
                    "$($definition.Name) detected '$actual'; expected '$($definition.Value)'."
                }
            }
        }

        $checks.Add((New-BoostLabVerificationCheck `
            -Name "Registry: $($definition.Key)\$($definition.Name)" `
            -Status $status `
            -Expected $(if ($definition.MustExist) { [string]$definition.Value } else { 'Absent' }) `
            -Actual $(if ($null -eq $detected) { 'Unknown' } elseif ([bool](Get-BoostLabStateProperty $detected 'Exists' $false)) { [string](Get-BoostLabStateProperty $detected 'Value') } else { 'Absent' }) `
            -Message $message))
    }

    $fileState = & $FileReader $script:TargetPath
    $fileStatus = 'Warning'
    $fileExpected = if ($ActionName -eq 'Apply') { 'BoostLab-owned generated file' } else { 'Restored backup, absent owned file, or preserved unknown file' }
    $fileDetected = if ([bool](Get-BoostLabStateProperty $fileState 'Exists' $false)) { 'Present' } else { 'Absent' }
    $fileMessage = 'File ownership state could not be verified.'

    if ($ActionName -eq 'Apply') {
        $generatedHash = [string](Get-BoostLabStateProperty $OwnershipState 'GeneratedFileSha256' '')
        if (-not [bool](Get-BoostLabStateProperty $fileState 'Exists' $false)) {
            $fileStatus = 'Failed'
            $fileMessage = 'Black.jpg is missing after Apply.'
        }
        elseif ([string]::IsNullOrWhiteSpace($generatedHash) -or -not [bool](Get-BoostLabStateProperty $fileState 'HashDetected' $false)) {
            $fileStatus = 'Warning'
            $fileMessage = 'Black.jpg exists, but its ownership hash could not be verified.'
        }
        elseif ([string](Get-BoostLabStateProperty $fileState 'Sha256' '') -eq $generatedHash) {
            $fileStatus = 'Passed'
            $fileMessage = 'Black.jpg matches the generated BoostLab-owned file.'
        }
        else {
            $fileStatus = 'Failed'
            $fileMessage = 'Black.jpg does not match the generated ownership hash.'
        }
    }
    else {
        $disposition = [string](Get-BoostLabStateProperty $OwnershipState 'FileDisposition' 'Unknown')
        switch ($disposition) {
            'Restored' {
                $originalHash = [string](Get-BoostLabStateProperty $OwnershipState 'OriginalFileSha256' '')
                if (-not [bool](Get-BoostLabStateProperty $fileState 'Exists' $false)) {
                    $fileStatus = 'Failed'
                    $fileMessage = 'The recorded pre-existing Black.jpg was not restored.'
                }
                elseif ([string]::IsNullOrWhiteSpace($originalHash) -or -not [bool](Get-BoostLabStateProperty $fileState 'HashDetected' $false)) {
                    $fileStatus = 'Warning'
                    $fileMessage = 'The backup was restored, but its hash could not be verified.'
                }
                elseif ([string](Get-BoostLabStateProperty $fileState 'Sha256' '') -eq $originalHash) {
                    $fileStatus = 'Passed'
                    $fileMessage = 'The pre-existing Black.jpg backup was restored.'
                }
                else {
                    $fileStatus = 'Failed'
                    $fileMessage = 'The restored Black.jpg does not match the recorded backup hash.'
                }
            }
            'Removed' {
                $fileStatus = if ([bool](Get-BoostLabStateProperty $fileState 'Exists' $false)) { 'Failed' } else { 'Passed' }
                $fileMessage = if ($fileStatus -eq 'Passed') { 'The BoostLab-owned Black.jpg was removed.' } else { 'The BoostLab-owned Black.jpg is still present.' }
            }
            'AlreadyAbsent' {
                $fileStatus = if ([bool](Get-BoostLabStateProperty $fileState 'Exists' $false)) { 'Failed' } else { 'Passed' }
                $fileMessage = if ($fileStatus -eq 'Passed') { 'Black.jpg was already absent.' } else { 'Black.jpg unexpectedly exists.' }
            }
            'AlreadyDefault' {
                $fileStatus = 'Passed'
                $fileMessage = 'No active BoostLab file ownership remained to undo.'
            }
            'LeftIntactUnknownOwnership' {
                $fileStatus = 'Warning'
                $fileMessage = 'Black.jpg was left intact because BoostLab could not prove ownership.'
            }
            'BackupMissing' {
                $fileStatus = 'Warning'
                $fileMessage = 'The recorded backup was missing, so Black.jpg was left intact.'
            }
            default {
                $fileStatus = 'Warning'
                $fileMessage = 'The file disposition is unknown.'
            }
        }
    }

    $checks.Add((New-BoostLabVerificationCheck `
        -Name 'File ownership and disposition' `
        -Status $fileStatus `
        -Expected $fileExpected `
        -Actual $fileDetected `
        -Message $fileMessage))

    $ownershipActive = [bool](Get-BoostLabStateProperty $OwnershipState 'Active' $false)
    $expectedOwnership = ($ActionName -eq 'Apply')
    $ownershipStatus = if ($ownershipActive -eq $expectedOwnership) { 'Passed' } else { 'Failed' }
    $checks.Add((New-BoostLabVerificationCheck `
        -Name 'Ownership metadata' `
        -Status $ownershipStatus `
        -Expected $(if ($expectedOwnership) { 'Active' } else { 'Inactive' }) `
        -Actual $(if ($ownershipActive) { 'Active' } else { 'Inactive' }) `
        -Message $(if ($ownershipStatus -eq 'Passed') { 'Ownership metadata matches the requested action.' } else { 'Ownership metadata does not match the requested action.' })))

    $failedChecks = @($checks | Where-Object Status -eq 'Failed')
    $warningChecks = @($checks | Where-Object Status -eq 'Warning')
    $status = if ($failedChecks.Count -gt 0) {
        'Failed'
    }
    elseif ($warningChecks.Count -gt 0) {
        'Warning'
    }
    else {
        'Passed'
    }
    $expectedDescription = if ($ActionName -eq 'Apply') {
        'Black wallpaper active'
    }
    else {
        'Approved default restored'
    }
    $detectedDescription = if ($status -eq 'Failed') {
        'Mismatch detected'
    }
    elseif ($status -eq 'Warning') {
        "$expectedDescription with warning"
    }
    else {
        $expectedDescription
    }

    New-BoostLabVerificationResult `
        -ToolId $script:ToolInfo['Id'] `
        -ToolTitle $script:ToolInfo['Title'] `
        -Action $ActionName `
        -Status $status `
        -ExpectedState ([pscustomobject]@{ Wallpaper = $expectedDescription }) `
        -DetectedState ([pscustomobject]@{
            Wallpaper = $detectedDescription
            FileDisposition = [string](Get-BoostLabStateProperty $OwnershipState 'FileDisposition' 'Unknown')
        }) `
        -Checks @($checks) `
        -Message $(if ($status -eq 'Passed') { 'All wallpaper, registry, and ownership checks passed.' } elseif ($status -eq 'Warning') { 'Registry state matched, but file ownership or detection requires attention.' } else { 'One or more detected states contradict the requested action.' })
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    param()

    $ownership = Get-BoostLabWallpaperOwnershipState
    $detected = if ([bool](Get-BoostLabStateProperty $ownership 'Active' $false)) {
        'Black wallpaper active'
    }
    elseif ([bool](Get-BoostLabStateProperty $ownership 'OwnershipUncertain' $false)) {
        'Default state with ownership warning'
    }
    else {
        'Default or not managed by BoostLab'
    }

    [pscustomobject]@{
        Status         = $detected
        Implemented    = $true
        Active         = [bool](Get-BoostLabStateProperty $ownership 'Active' $false)
        BackupPath     = Get-BoostLabStateProperty $ownership 'BackupPath'
        MetadataPath   = Get-BoostLabStateProperty $ownership 'MetadataPath'
        LastDisposition = Get-BoostLabStateProperty $ownership 'FileDisposition' 'Unknown'
    }
}

function New-BoostLabSignoutWallpaperActionPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string] $ActionName
    )

    if ($ActionName -eq 'Apply') {
        return [pscustomobject]@{
            Summary        = 'Generate and apply a black wallpaper for the desktop, sign-out, and lock screen.'
            PlannedChanges = @(
                'Back up any pre-existing C:\Windows\Black.jpg not already proven to be BoostLab-owned.'
                'Generate a black bitmap at the primary monitor resolution and save it as C:\Windows\Black.jpg.'
                'Set LockScreenImagePath and LockScreenImageStatus under PersonalizationCSP.'
                'Set the current user desktop Wallpaper value to C:\Windows\Black.jpg.'
                'Request Windows to refresh per-user wallpaper parameters.'
                'Record backup and generated-file ownership metadata under ProgramData\BoostLab\State.'
            )
            SideEffects     = @(
                'The desktop, sign-out, and lock screen wallpaper may become black.'
                'An existing C:\Windows\Black.jpg may be copied into BoostLab state storage before replacement.'
                'The wallpaper refresh request may not be immediately visible in every Windows session.'
            )
            ConfirmationMessage = 'Apply the approved black sign-out, lock screen, and desktop wallpaper configuration?'
        }
    }

    [pscustomobject]@{
        Summary        = 'Restore the approved default wallpaper registry state and safely undo BoostLab-owned Black.jpg changes.'
        PlannedChanges = @(
            'Remove only LockScreenImagePath and LockScreenImageStatus from PersonalizationCSP.'
            'Leave the PersonalizationCSP key and all unrelated values intact.'
            'Set the current user desktop Wallpaper value to C:\Windows\Web\Wallpaper\Windows\img0.jpg.'
            'Request Windows to refresh per-user wallpaper parameters.'
            'Restore a BoostLab backup of a pre-existing Black.jpg when recorded.'
            'Otherwise remove Black.jpg only when BoostLab ownership is proven by state and hash.'
        )
        SideEffects     = @(
            'The desktop and lock screen wallpaper may return to the approved Windows default.'
            'If Black.jpg ownership cannot be proven, the file is left intact and a warning is returned.'
        )
        ConfirmationMessage = 'Restore the approved default wallpaper state and safely undo the BoostLab-owned file?'
    }
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ActionName,

        [bool] $Confirmed = $false,

        [scriptblock] $AdministratorChecker = {
            Test-BoostLabAdministrator
        },

        [scriptblock] $RegistryCommandRunner = {
            param($Operation)
            Invoke-BoostLabSignoutWallpaperRegistryCommand -Operation $Operation
        },

        [scriptblock] $RegistryReader = {
            param($Key, $Name)
            Get-BoostLabRegistryValueState -Key $Key -Name $Name
        },

        [scriptblock] $FileReader = {
            param($Path)
            Get-BoostLabWallpaperFileState -Path $Path
        },

        [scriptblock] $StateReader = {
            Get-BoostLabWallpaperOwnershipState
        },

        [scriptblock] $StateWriter = {
            param($State)
            Save-BoostLabWallpaperOwnershipState -State $State
        },

        [scriptblock] $BackupWriter = {
            param($Path)
            Backup-BoostLabWallpaperFile -SourcePath $Path
        },

        [scriptblock] $BackupRestorer = {
            param($BackupPath, $TargetPath)
            Restore-BoostLabWallpaperBackup -BackupPath $BackupPath -TargetPath $TargetPath
        },

        [scriptblock] $OwnedFileRemover = {
            param($Path)
            Remove-BoostLabOwnedWallpaperFile -Path $Path
        },

        [scriptblock] $ImageGenerator = {
            param($Path)
            New-BoostLabBlackWallpaperImage -Path $Path
        },

        [scriptblock] $WallpaperRefresher = {
            Invoke-BoostLabWallpaperRefresh
        }
    )

    if ($ActionName -notin @($script:BoostLabImplementedActions)) {
        return [pscustomobject]@{
            Success = $false; ToolId = $script:ToolInfo['Id']; ToolTitle = $script:ToolInfo['Title']
            Action = $ActionName; Message = 'Unsupported action. Only Apply and Default are allowed.'
            RestartRequired = $false; Cancelled = $false; Timestamp = Get-Date
            Data = $null; VerificationResult = $null
        }
    }
    if (-not $Confirmed) {
        return [pscustomobject]@{
            Success = $false; ToolId = $script:ToolInfo['Id']; ToolTitle = $script:ToolInfo['Title']
            Action = $ActionName; Message = 'Cancelled by user'
            RestartRequired = $false; Cancelled = $true; Timestamp = Get-Date
            Data = $null; VerificationResult = $null
        }
    }
    if (-not [bool](& $AdministratorChecker)) {
        return [pscustomobject]@{
            Success = $false; ToolId = $script:ToolInfo['Id']; ToolTitle = $script:ToolInfo['Title']
            Action = $ActionName; Message = 'Administrator rights are required to change HKLM wallpaper policy and C:\Windows\Black.jpg.'
            RestartRequired = $false; Cancelled = $false; Timestamp = Get-Date
            Data = $null; VerificationResult = $null
        }
    }

    $registryResults = [System.Collections.Generic.List[object]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    $backupPath = $null
    $backupStatus = 'Not required'
    $fileDisposition = if ($ActionName -eq 'Apply') { 'Generated' } else { 'Unknown' }
    $ownershipState = $null
    $refreshResult = $null

    try {
        $ownershipState = & $StateReader
        if (-not [bool](Get-BoostLabStateProperty $ownershipState 'ReadSucceeded' $true)) {
            throw "Ownership metadata could not be read: $(Get-BoostLabStateProperty $ownershipState 'ErrorMessage' 'Unknown state error.')"
        }

        if ($ActionName -eq 'Apply') {
            $currentFile = & $FileReader $script:TargetPath
            $currentHash = [string](Get-BoostLabStateProperty $currentFile 'Sha256' '')
            $recordedGeneratedHash = [string](Get-BoostLabStateProperty $ownershipState 'GeneratedFileSha256' '')
            $knownOwned = (
                [bool](Get-BoostLabStateProperty $ownershipState 'Exists' $false) -and
                [bool](Get-BoostLabStateProperty $ownershipState 'Active' $false) -and
                [bool](Get-BoostLabStateProperty $ownershipState 'CreatedByBoostLab' $false) -and
                -not [string]::IsNullOrWhiteSpace($currentHash) -and
                $currentHash -eq $recordedGeneratedHash
            )

            $backupCreated = $false
            $originalHash = $null
            if ([bool](Get-BoostLabStateProperty $currentFile 'Exists' $false) -and -not $knownOwned) {
                $backupResult = & $BackupWriter $script:TargetPath
                if (-not [bool](Get-BoostLabStateProperty $backupResult 'Success' $false)) {
                    throw "The pre-existing Black.jpg could not be backed up: $(Get-BoostLabStateProperty $backupResult 'Message' 'Unknown backup error.')"
                }

                $backupCreated = $true
                $backupPath = [string](Get-BoostLabStateProperty $backupResult 'BackupPath' '')
                $originalHash = [string](Get-BoostLabStateProperty $backupResult 'Sha256' $currentHash)
                $backupStatus = 'Created'
            }
            elseif ($knownOwned) {
                $backupCreated = [bool](Get-BoostLabStateProperty $ownershipState 'BackupCreated' $false)
                $backupPath = Get-BoostLabStateProperty $ownershipState 'BackupPath'
                $originalHash = Get-BoostLabStateProperty $ownershipState 'OriginalFileSha256'
                $backupStatus = if ($backupCreated) { 'Existing backup retained' } else { 'Not required; file already BoostLab-owned' }
            }

            $pendingState = [pscustomobject]@{
                Version              = 1
                ToolId               = $script:ToolInfo.Id
                TargetPath           = $script:TargetPath
                Active               = $false
                PendingApply         = $true
                CreatedByBoostLab    = $true
                TargetPreviouslyExisted = [bool](Get-BoostLabStateProperty $currentFile 'Exists' $false)
                BackupCreated        = $backupCreated
                BackupPath           = $backupPath
                OriginalFileSha256   = $originalHash
                GeneratedFileSha256  = $null
                GeneratedWidth       = $null
                GeneratedHeight      = $null
                OwnershipUncertain   = $false
                FileDisposition      = 'PendingApply'
                UpdatedAt            = [DateTime]::UtcNow
            }
            $pendingWrite = & $StateWriter $pendingState
            if (-not [bool](Get-BoostLabStateProperty $pendingWrite 'Success' $false)) {
                throw "Ownership metadata could not be recorded before overwrite: $(Get-BoostLabStateProperty $pendingWrite 'Message' 'Unknown state error.')"
            }

            $imageResult = & $ImageGenerator $script:TargetPath
            if (-not [bool](Get-BoostLabStateProperty $imageResult 'Success' $false)) {
                throw "Black wallpaper generation failed: $(Get-BoostLabStateProperty $imageResult 'Message' 'Unknown image error.')"
            }

            $generatedFile = & $FileReader $script:TargetPath
            if (-not [bool](Get-BoostLabStateProperty $generatedFile 'Exists' $false)) {
                throw 'Black wallpaper generation reported success, but C:\Windows\Black.jpg was not found.'
            }

            $ownershipState = [pscustomobject]@{
                Version              = 1
                ToolId               = $script:ToolInfo.Id
                TargetPath           = $script:TargetPath
                Active               = $true
                PendingApply         = $false
                CreatedByBoostLab    = $true
                TargetPreviouslyExisted = [bool](Get-BoostLabStateProperty $currentFile 'Exists' $false)
                BackupCreated        = $backupCreated
                BackupPath           = $backupPath
                OriginalFileSha256   = $originalHash
                GeneratedFileSha256  = Get-BoostLabStateProperty $generatedFile 'Sha256'
                GeneratedWidth       = Get-BoostLabStateProperty $imageResult 'Width'
                GeneratedHeight      = Get-BoostLabStateProperty $imageResult 'Height'
                OwnershipUncertain   = $false
                FileDisposition      = 'Generated'
                AppliedAt            = [DateTime]::UtcNow
                UpdatedAt            = [DateTime]::UtcNow
            }
            $ownershipWrite = & $StateWriter $ownershipState
            if (-not [bool](Get-BoostLabStateProperty $ownershipWrite 'Success' $false)) {
                throw "Generated file ownership metadata could not be recorded: $(Get-BoostLabStateProperty $ownershipWrite 'Message' 'Unknown state error.')"
            }

            $operations = @(
                [pscustomobject]@{ Operation = 'Add'; Key = $script:PersonalizationCspKey; Name = 'LockScreenImagePath'; Type = 'REG_SZ'; Value = $script:TargetPath }
                [pscustomobject]@{ Operation = 'Add'; Key = $script:PersonalizationCspKey; Name = 'LockScreenImageStatus'; Type = 'REG_DWORD'; Value = 1 }
                [pscustomobject]@{ Operation = 'Add'; Key = $script:DesktopKey; Name = 'Wallpaper'; Type = 'REG_SZ'; Value = $script:TargetPath }
            )
        }
        else {
            $operations = @(
                [pscustomobject]@{ Operation = 'DeleteValue'; Key = $script:PersonalizationCspKey; Name = 'LockScreenImagePath'; Type = $null; Value = $null }
                [pscustomobject]@{ Operation = 'DeleteValue'; Key = $script:PersonalizationCspKey; Name = 'LockScreenImageStatus'; Type = $null; Value = $null }
                [pscustomobject]@{ Operation = 'Add'; Key = $script:DesktopKey; Name = 'Wallpaper'; Type = 'REG_SZ'; Value = $script:DefaultWallpaperPath }
            )
        }

        foreach ($operation in $operations) {
            $registryResult = & $RegistryCommandRunner $operation
            $registryResults.Add($registryResult)
        }

        $refreshResult = & $WallpaperRefresher
        if (-not [bool](Get-BoostLabStateProperty $refreshResult 'Success' $false)) {
            $warnings.Add("Wallpaper refresh request failed: $(Get-BoostLabStateProperty $refreshResult 'Message' 'Unknown refresh error.')")
        }

        if ($ActionName -eq 'Default') {
            $fileState = & $FileReader $script:TargetPath
            $stateExists = [bool](Get-BoostLabStateProperty $ownershipState 'Exists' $false)
            $active = [bool](Get-BoostLabStateProperty $ownershipState 'Active' $false)
            $ownershipUncertain = [bool](Get-BoostLabStateProperty $ownershipState 'OwnershipUncertain' $false)
            $recordedBackupPath = [string](Get-BoostLabStateProperty $ownershipState 'BackupPath' '')
            $backupCreated = [bool](Get-BoostLabStateProperty $ownershipState 'BackupCreated' $false)
            $pendingApply = [bool](Get-BoostLabStateProperty $ownershipState 'PendingApply' $false)
            $generatedHash = [string](Get-BoostLabStateProperty $ownershipState 'GeneratedFileSha256' '')
            $currentHash = [string](Get-BoostLabStateProperty $fileState 'Sha256' '')

            if ($pendingApply -and $backupCreated) {
                $recordedBackupState = if ([string]::IsNullOrWhiteSpace($recordedBackupPath)) {
                    $null
                }
                else {
                    & $FileReader $recordedBackupPath
                }
                if (
                    [string]::IsNullOrWhiteSpace($recordedBackupPath) -or
                    -not [bool](Get-BoostLabStateProperty $recordedBackupState 'Exists' $false)
                ) {
                    $fileDisposition = 'BackupMissing'
                    $backupStatus = 'Recorded interrupted-Apply backup missing'
                    $warnings.Add('Apply was interrupted and its recorded Black.jpg backup is missing. The current file was left intact.')
                }
                else {
                    $restoreResult = & $BackupRestorer $recordedBackupPath $script:TargetPath
                    if (-not [bool](Get-BoostLabStateProperty $restoreResult 'Success' $false)) {
                        throw "The interrupted Apply backup could not be restored: $(Get-BoostLabStateProperty $restoreResult 'Message' 'Unknown restore error.')"
                    }
                    $fileDisposition = 'Restored'
                    $backupPath = $recordedBackupPath
                    $backupStatus = 'Interrupted Apply backup restored'
                }
            }
            elseif ($pendingApply) {
                $fileDisposition = 'LeftIntactUnknownOwnership'
                $backupStatus = 'Interrupted Apply ownership incomplete'
                $warnings.Add('Apply was interrupted before ownership hashing completed. Black.jpg was left intact.')
            }
            elseif ($stateExists -and -not $active -and -not $ownershipUncertain) {
                $fileDisposition = 'AlreadyDefault'
                $backupStatus = 'No active ownership'
            }
            elseif ($active -and $backupCreated) {
                $recordedBackupState = if ([string]::IsNullOrWhiteSpace($recordedBackupPath)) {
                    $null
                }
                else {
                    & $FileReader $recordedBackupPath
                }
                if (
                    [string]::IsNullOrWhiteSpace($recordedBackupPath) -or
                    -not [bool](Get-BoostLabStateProperty $recordedBackupState 'Exists' $false)
                ) {
                    $fileDisposition = 'BackupMissing'
                    $backupStatus = 'Recorded backup missing'
                    $warnings.Add('The recorded pre-existing Black.jpg backup is missing. The current file was left intact.')
                }
                else {
                    $restoreResult = & $BackupRestorer $recordedBackupPath $script:TargetPath
                    if (-not [bool](Get-BoostLabStateProperty $restoreResult 'Success' $false)) {
                        throw "The pre-existing Black.jpg backup could not be restored: $(Get-BoostLabStateProperty $restoreResult 'Message' 'Unknown restore error.')"
                    }
                    $fileDisposition = 'Restored'
                    $backupPath = $recordedBackupPath
                    $backupStatus = 'Restored'
                }
            }
            elseif ($active -and [bool](Get-BoostLabStateProperty $ownershipState 'CreatedByBoostLab' $false)) {
                if (-not [bool](Get-BoostLabStateProperty $fileState 'Exists' $false)) {
                    $fileDisposition = 'AlreadyAbsent'
                    $backupStatus = 'No backup required'
                }
                elseif (-not [string]::IsNullOrWhiteSpace($generatedHash) -and $currentHash -eq $generatedHash) {
                    $removeResult = & $OwnedFileRemover $script:TargetPath
                    if (-not [bool](Get-BoostLabStateProperty $removeResult 'Success' $false)) {
                        throw "The BoostLab-owned Black.jpg could not be removed: $(Get-BoostLabStateProperty $removeResult 'Message' 'Unknown delete error.')"
                    }
                    $fileDisposition = 'Removed'
                    $backupStatus = 'No backup required'
                }
                else {
                    $fileDisposition = 'LeftIntactUnknownOwnership'
                    $backupStatus = 'Ownership hash mismatch'
                    $warnings.Add('Black.jpg was left intact because its current hash does not prove BoostLab ownership.')
                }
            }
            elseif (-not [bool](Get-BoostLabStateProperty $fileState 'Exists' $false)) {
                $fileDisposition = 'AlreadyAbsent'
                $backupStatus = 'No backup required'
            }
            else {
                $fileDisposition = 'LeftIntactUnknownOwnership'
                $backupStatus = 'Ownership unknown'
                $warnings.Add('Black.jpg was left intact because BoostLab ownership could not be proven.')
            }

            $ownershipState = [pscustomobject]@{
                Version              = 1
                ToolId               = $script:ToolInfo.Id
                TargetPath           = $script:TargetPath
                Active               = $false
                PendingApply         = $false
                CreatedByBoostLab    = $false
                TargetPreviouslyExisted = Get-BoostLabStateProperty $ownershipState 'TargetPreviouslyExisted' $false
                BackupCreated        = Get-BoostLabStateProperty $ownershipState 'BackupCreated' $false
                BackupPath           = Get-BoostLabStateProperty $ownershipState 'BackupPath'
                OriginalFileSha256   = Get-BoostLabStateProperty $ownershipState 'OriginalFileSha256'
                GeneratedFileSha256  = Get-BoostLabStateProperty $ownershipState 'GeneratedFileSha256'
                GeneratedWidth       = Get-BoostLabStateProperty $ownershipState 'GeneratedWidth'
                GeneratedHeight      = Get-BoostLabStateProperty $ownershipState 'GeneratedHeight'
                OwnershipUncertain   = ($fileDisposition -in @('LeftIntactUnknownOwnership', 'BackupMissing'))
                FileDisposition      = $fileDisposition
                DefaultCompletedAt   = [DateTime]::UtcNow
                UpdatedAt            = [DateTime]::UtcNow
            }
            $ownershipWrite = & $StateWriter $ownershipState
            if (-not [bool](Get-BoostLabStateProperty $ownershipWrite 'Success' $false)) {
                throw "Default ownership metadata could not be recorded: $(Get-BoostLabStateProperty $ownershipWrite 'Message' 'Unknown state error.')"
            }
        }

        $verification = Test-BoostLabSignoutWallpaperState `
            -ActionName $ActionName `
            -OwnershipState $ownershipState `
            -RegistryReader $RegistryReader `
            -FileReader $FileReader
        if (-not [bool](Get-BoostLabStateProperty $refreshResult 'Success' $false)) {
            $refreshCheck = New-BoostLabVerificationCheck `
                -Name 'Wallpaper refresh request' `
                -Expected 'UpdatePerUserSystemParameters requested successfully' `
                -Actual (Get-BoostLabStateProperty $refreshResult 'Message' 'Refresh failed') `
                -Status 'Warning' `
                -Message 'The registry and file state may be correct, but Windows did not confirm the wallpaper refresh request.'
            $verification = New-BoostLabVerificationResult `
                -ToolId $verification.ToolId `
                -ToolTitle $verification.ToolTitle `
                -Action $verification.Action `
                -Status $(if ($verification.Status -eq 'Failed') { 'Failed' } else { 'Warning' }) `
                -ExpectedState $verification.ExpectedState `
                -DetectedState $verification.DetectedState `
                -Checks (@($verification.Checks) + @($refreshCheck)) `
                -Message $(if ($verification.Status -eq 'Failed') { $verification.Message } else { 'Registry and file checks completed, but the wallpaper refresh request failed.' })
        }

        $failedRegistryCommands = @($registryResults | Where-Object { -not [bool](Get-BoostLabStateProperty $_ 'Success' $false) })
        $commandStatus = if ($failedRegistryCommands.Count -eq 0) { 'Completed' } else { 'Completed with registry command warnings' }
        if ($failedRegistryCommands.Count -gt 0) {
            $warnings.Add("$($failedRegistryCommands.Count) registry command(s) returned a non-zero exit code; verification determined the final state.")
        }

        $success = $verification.Status -ne 'Failed'
        $message = if ($ActionName -eq 'Apply') {
            if ($success) { 'Black sign-out, lock screen, and desktop wallpaper applied.' } else { 'Wallpaper commands completed, but verification failed.' }
        }
        elseif ($fileDisposition -eq 'Restored') {
            'Wallpaper settings restored to default and the pre-existing Black.jpg backup was restored.'
        }
        elseif ($fileDisposition -eq 'Removed') {
            'Wallpaper settings restored to default and the BoostLab-owned Black.jpg was removed.'
        }
        elseif ($fileDisposition -eq 'AlreadyDefault' -or $fileDisposition -eq 'AlreadyAbsent') {
            'Wallpaper settings are already in the approved default state.'
        }
        elseif ($fileDisposition -eq 'LeftIntactUnknownOwnership') {
            'Wallpaper registry settings restored to default; Black.jpg was left intact because ownership could not be proven.'
        }
        elseif ($fileDisposition -eq 'BackupMissing') {
            'Wallpaper registry settings restored to default; Black.jpg was left intact because the recorded backup was unavailable.'
        }
        else {
            'Wallpaper default operation completed.'
        }

        $data = [pscustomobject]@{
            CommandStatus          = $commandStatus
            ExpectedWallpaperState = [string]$verification.ExpectedState.Wallpaper
            DetectedWallpaperState = [string]$verification.DetectedState.Wallpaper
            RegistryValuesChecked  = @(
                "$($script:PersonalizationCspKey)\LockScreenImagePath"
                "$($script:PersonalizationCspKey)\LockScreenImageStatus"
                "$($script:DesktopKey)\Wallpaper"
            )
            FilePathsChecked       = @(
                $script:TargetPath
                (Get-BoostLabWallpaperStatePaths).MetadataPath
                $backupPath
            ) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }
            BackupOwnershipStatus  = $backupStatus
            BackupPath             = $backupPath
            FileDisposition        = $fileDisposition
            RegistryOperations     = @($registryResults)
            WallpaperRefreshStatus = if ([bool](Get-BoostLabStateProperty $refreshResult 'Success' $false)) { 'Requested' } else { 'Warning' }
            Warnings                = @($warnings)
            CompletedAt             = Get-Date
        }

        [pscustomobject]@{
            Success              = $success
            ToolId               = $script:ToolInfo.Id
            ToolTitle            = $script:ToolInfo.Title
            Action               = $ActionName
            Message              = $message
            RestartRequired      = $false
            Cancelled            = $false
            Timestamp            = Get-Date
            Data                 = $data
            VerificationResult   = $verification
        }
    }
    catch {
        $failedData = [pscustomobject]@{
            CommandStatus          = 'Failed'
            ExpectedWallpaperState = if ($ActionName -eq 'Apply') { 'Black wallpaper active' } else { 'Approved default restored' }
            DetectedWallpaperState = 'Unknown'
            RegistryValuesChecked  = @(
                "$($script:PersonalizationCspKey)\LockScreenImagePath"
                "$($script:PersonalizationCspKey)\LockScreenImageStatus"
                "$($script:DesktopKey)\Wallpaper"
            )
            FilePathsChecked       = @($script:TargetPath)
            BackupOwnershipStatus  = $backupStatus
            BackupPath             = $backupPath
            FileDisposition        = $fileDisposition
            RegistryOperations     = @($registryResults)
            WallpaperRefreshStatus = if ($null -eq $refreshResult) { 'Not attempted' } else { 'Failed' }
            Warnings                = @($warnings)
            CompletedAt             = Get-Date
        }

        [pscustomobject]@{
            Success              = $false
            ToolId               = $script:ToolInfo.Id
            ToolTitle            = $script:ToolInfo.Title
            Action               = $ActionName
            Message              = $_.Exception.Message
            RestartRequired      = $false
            Cancelled            = $false
            Timestamp            = Get-Date
            Data                 = $failedData
            VerificationResult   = $null
        }
    }
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    param(
        [bool] $Confirmed = $false
    )

    Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed:$Confirmed
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
