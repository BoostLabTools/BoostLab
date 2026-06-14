Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'user-account-pictures-black'
    Title = 'User Account Pictures Black'
    Stage = 'Windows'
    Order = 6
    Type = 'action'
    RiskLevel = 'medium'
    Description = 'Back up and replace the approved Windows account pictures with black images, or safely restore the captured originals.'
    Actions = @('Apply', 'Default')
    Capabilities = [ordered]@{
        RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false
        CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false
        CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false
        CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false
        SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Apply', 'Default')
$script:BoostLabApprovedExtensions = @('.png', '.bmp')

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
Import-Module -Name $verificationModulePath -Scope Local -ErrorAction Stop

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        Id                 = [string]$script:BoostLabToolMetadata['Id']
        Title              = [string]$script:BoostLabToolMetadata['Title']
        Stage              = [string]$script:BoostLabToolMetadata['Stage']
        Order              = [int]$script:BoostLabToolMetadata['Order']
        Type               = [string]$script:BoostLabToolMetadata['Type']
        RiskLevel          = [string]$script:BoostLabToolMetadata['RiskLevel']
        Description        = [string]$script:BoostLabToolMetadata['Description']
        Actions            = @($script:BoostLabToolMetadata['Actions'])
        Capabilities       = [pscustomobject]$script:BoostLabToolMetadata['Capabilities']
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

function Get-BoostLabAccountPicturePaths {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $systemDrive = if ([string]::IsNullOrWhiteSpace($env:SystemDrive)) {
        [IO.Path]::GetPathRoot($env:SystemRoot)
    }
    else {
        $env:SystemDrive
    }
    $programData = if ([string]::IsNullOrWhiteSpace($env:ProgramData)) {
        Join-Path $systemDrive 'ProgramData'
    }
    else {
        $env:ProgramData
    }
    $stateDirectory = Join-Path $programData 'BoostLab\State'

    [pscustomobject]@{
        TargetRoot        = Join-Path $programData 'Microsoft\User Account Pictures'
        LegacyBackupRoot  = Join-Path $programData 'User Account Pictures'
        StateDirectory    = $stateDirectory
        BackupRoot        = Join-Path $stateDirectory 'Backups\UserAccountPicturesBlack'
        ManifestPath      = Join-Path $stateDirectory 'user-account-pictures-black.json'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $paths = Get-BoostLabAccountPicturePaths
    $reasons = [System.Collections.Generic.List[string]]::new()
    if ($env:OS -ne 'Windows_NT') {
        $reasons.Add('This tool requires Windows.')
    }
    if (-not [IO.Directory]::Exists($paths.TargetRoot)) {
        $reasons.Add("The approved Ultimate account-picture directory is unavailable: $($paths.TargetRoot)")
    }
    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    }
    catch {
        $reasons.Add("System.Drawing is unavailable: $($_.Exception.Message)")
    }

    [pscustomobject]@{
        Supported = $reasons.Count -eq 0
        ToolId    = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason    = if ($reasons.Count -eq 0) {
            'The approved Windows account-picture directory and image runtime are available.'
        }
        else {
            $reasons -join ' '
        }
        Reasons   = $reasons.ToArray()
        Timestamp = Get-Date
    }
}

function Get-BoostLabAccountPictureProperty {
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$Name,

        [AllowNull()]
        [object]$DefaultValue = $null
    )

    if ($null -eq $InputObject) {
        return $DefaultValue
    }
    if ($InputObject -is [System.Collections.IDictionary]) {
        if ($InputObject.Contains($Name)) {
            return $InputObject[$Name]
        }
        return $DefaultValue
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $DefaultValue
    }
    return $property.Value
}

function Test-BoostLabAccountPicturePath {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Root,

        [switch]$RequireImage
    )

    try {
        $fullPath = [IO.Path]::GetFullPath($Path)
        $fullRoot = [IO.Path]::GetFullPath($Root).TrimEnd('\')
        if (-not $fullPath.StartsWith($fullRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
            return $false
        }
        if ($RequireImage -and [IO.Path]::GetExtension($fullPath).ToLowerInvariant() -notin $script:BoostLabApprovedExtensions) {
            return $false
        }
        return $true
    }
    catch {
        return $false
    }
}

function Get-BoostLabAccountPictureRelativePath {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Root
    )

    $fullPath = [IO.Path]::GetFullPath($Path)
    $fullRoot = [IO.Path]::GetFullPath($Root).TrimEnd('\')
    if (-not (Test-BoostLabAccountPicturePath -Path $fullPath -Root $fullRoot -RequireImage)) {
        throw "The account-picture path is outside the approved target: $Path"
    }
    return $fullPath.Substring($fullRoot.Length + 1)
}

function Get-BoostLabAccountPictureFileState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not [IO.File]::Exists($Path)) {
        return [pscustomobject]@{
            ReadSucceeded = $true
            Exists        = $false
            Path          = $Path
            Sha256        = $null
            Length        = $null
            Message       = 'File is absent.'
        }
    }

    try {
        $file = [IO.FileInfo]::new($Path)
        [pscustomobject]@{
            ReadSucceeded = $true
            Exists        = $true
            Path          = $Path
            Sha256        = (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash
            Length        = $file.Length
            Message       = 'File state detected.'
        }
    }
    catch {
        [pscustomobject]@{
            ReadSucceeded = $false
            Exists        = $true
            Path          = $Path
            Sha256        = $null
            Length        = $null
            Message       = $_.Exception.Message
        }
    }
}

function Get-BoostLabAccountPictureImages {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)]
        [string]$TargetRoot
    )

    if (-not [IO.Directory]::Exists($TargetRoot)) {
        return @()
    }

    return @(
        Get-ChildItem -LiteralPath $TargetRoot -Recurse -File -ErrorAction Stop |
            Where-Object { $_.Extension.ToLowerInvariant() -in $script:BoostLabApprovedExtensions } |
            Sort-Object FullName |
            ForEach-Object {
                [pscustomobject]@{
                    FullName     = $_.FullName
                    RelativePath = Get-BoostLabAccountPictureRelativePath -Path $_.FullName -Root $TargetRoot
                }
            }
    )
}

function Get-BoostLabAccountPictureManifest {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ManifestPath
    )

    if (-not [IO.File]::Exists($ManifestPath)) {
        return [pscustomobject]@{
            ReadSucceeded = $true
            Exists        = $false
            Manifest      = $null
            Message       = 'No BoostLab account-picture manifest exists.'
        }
    }

    try {
        [pscustomobject]@{
            ReadSucceeded = $true
            Exists        = $true
            Manifest      = ([IO.File]::ReadAllText($ManifestPath) | ConvertFrom-Json -ErrorAction Stop)
            Message       = 'BoostLab account-picture manifest loaded.'
        }
    }
    catch {
        [pscustomobject]@{
            ReadSucceeded = $false
            Exists        = $true
            Manifest      = $null
            Message       = $_.Exception.Message
        }
    }
}

function Save-BoostLabAccountPictureManifest {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Manifest,

        [Parameter(Mandatory)]
        [string]$ManifestPath
    )

    try {
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $ManifestPath))
        [IO.File]::WriteAllText(
            $ManifestPath,
            ($Manifest | ConvertTo-Json -Depth 10),
            [Text.UTF8Encoding]::new($false)
        )
        [pscustomobject]@{ Success = $true; Message = 'Ownership manifest saved.' }
    }
    catch {
        [pscustomobject]@{ Success = $false; Message = $_.Exception.Message }
    }
}

function Copy-BoostLabAccountPictureBackup {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [string]$BackupPath
    )

    try {
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $BackupPath))
        [IO.File]::Copy($SourcePath, $BackupPath, $false)
        $sourceState = Get-BoostLabAccountPictureFileState -Path $SourcePath
        $backupState = Get-BoostLabAccountPictureFileState -Path $BackupPath
        if (
            -not $sourceState.ReadSucceeded -or
            -not $backupState.ReadSucceeded -or
            -not $backupState.Exists -or
            [string]$sourceState.Sha256 -ne [string]$backupState.Sha256
        ) {
            throw 'Backup verification did not match the source image.'
        }

        [pscustomobject]@{
            Success = $true
            Sha256  = [string]$backupState.Sha256
            Message = 'Original account picture backed up and verified.'
        }
    }
    catch {
        [pscustomobject]@{ Success = $false; Sha256 = $null; Message = $_.Exception.Message }
    }
}

function Set-BoostLabAccountPictureBlack {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $sourceBitmap = $null
    $blackBitmap = $null
    $graphics = $null
    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        $sourceBitmap = [System.Drawing.Bitmap]::FromFile($Path)
        $width = $sourceBitmap.Width
        $height = $sourceBitmap.Height
        $sourceBitmap.Dispose()
        $sourceBitmap = $null

        $blackBitmap = New-Object System.Drawing.Bitmap($width, $height)
        $graphics = [System.Drawing.Graphics]::FromImage($blackBitmap)
        $graphics.Clear([System.Drawing.Color]::Black)
        $graphics.Dispose()
        $graphics = $null

        # Preserve Ultimate's format selection behavior by saving back to the original filename.
        $blackBitmap.Save($Path)
        $blackBitmap.Dispose()
        $blackBitmap = $null
        $state = Get-BoostLabAccountPictureFileState -Path $Path
        if (-not $state.ReadSucceeded -or -not $state.Exists) {
            throw 'The black account picture could not be verified after writing.'
        }

        [pscustomobject]@{
            Success = $true
            Width   = $width
            Height  = $height
            Sha256  = [string]$state.Sha256
            Message = "Black image written at ${width}x${height}."
        }
    }
    catch {
        [pscustomobject]@{
            Success = $false
            Width   = $null
            Height  = $null
            Sha256  = $null
            Message = $_.Exception.Message
        }
    }
    finally {
        if ($graphics) { $graphics.Dispose() }
        if ($blackBitmap) { $blackBitmap.Dispose() }
        if ($sourceBitmap) { $sourceBitmap.Dispose() }
    }
}

function Restore-BoostLabAccountPictureBackup {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$BackupPath,

        [Parameter(Mandatory)]
        [string]$TargetPath
    )

    try {
        if (-not [IO.File]::Exists($BackupPath)) {
            throw "The recorded backup is missing: $BackupPath"
        }
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $TargetPath))
        [IO.File]::Copy($BackupPath, $TargetPath, $true)
        [pscustomobject]@{ Success = $true; Message = 'Original account picture restored.' }
    }
    catch {
        [pscustomobject]@{ Success = $false; Message = $_.Exception.Message }
    }
}

function Remove-BoostLabAccountPictureBackupSet {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$BackupPath,

        [Parameter(Mandatory)]
        [string]$ApprovedBackupRoot
    )

    try {
        if (-not (Test-BoostLabAccountPicturePath -Path (Join-Path $BackupPath 'ownership.marker') -Root $ApprovedBackupRoot)) {
            throw 'Backup cleanup path is outside the BoostLab-owned backup root.'
        }
        if ([IO.Directory]::Exists($BackupPath)) {
            [IO.Directory]::Delete($BackupPath, $true)
        }
        [pscustomobject]@{ Success = $true; Message = 'Tool-owned backup files removed after verified restoration.' }
    }
    catch {
        [pscustomobject]@{ Success = $false; Message = $_.Exception.Message }
    }
}

function Test-BoostLabAccountPictureManifest {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Manifest,

        [Parameter(Mandatory)]
        [object]$Paths
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    if (-not [bool](Get-BoostLabAccountPictureProperty $Manifest 'CreatedByBoostLab' $false)) {
        $errors.Add('Manifest is not marked as BoostLab-owned.')
    }
    if ([string](Get-BoostLabAccountPictureProperty $Manifest 'ToolId' '') -ne $script:BoostLabToolMetadata['Id']) {
        $errors.Add('Manifest tool identity does not match.')
    }
    if ([string](Get-BoostLabAccountPictureProperty $Manifest 'TargetRoot' '') -ne [string]$Paths.TargetRoot) {
        $errors.Add('Manifest target root does not match the approved Ultimate directory.')
    }
    $backupPath = [string](Get-BoostLabAccountPictureProperty $Manifest 'BackupPath' '')
    if ([string]::IsNullOrWhiteSpace($backupPath) -or -not (Test-BoostLabAccountPicturePath -Path (Join-Path $backupPath 'ownership.marker') -Root $Paths.BackupRoot)) {
        $errors.Add('Manifest backup path is outside the BoostLab-owned backup root.')
    }

    foreach ($entry in @(Get-BoostLabAccountPictureProperty $Manifest 'Files' @())) {
        $targetPath = [string](Get-BoostLabAccountPictureProperty $entry 'TargetPath' '')
        $entryBackupPath = [string](Get-BoostLabAccountPictureProperty $entry 'BackupPath' '')
        if (-not (Test-BoostLabAccountPicturePath -Path $targetPath -Root $Paths.TargetRoot -RequireImage)) {
            $errors.Add("Manifest target is outside the approved image scope: $targetPath")
        }
        if (-not (Test-BoostLabAccountPicturePath -Path $entryBackupPath -Root $backupPath -RequireImage)) {
            $errors.Add("Manifest backup is outside the owned backup set: $entryBackupPath")
        }
    }

    [pscustomobject]@{
        IsValid = $errors.Count -eq 0
        Errors  = $errors.ToArray()
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $paths = Get-BoostLabAccountPicturePaths
    $manifestResult = Get-BoostLabAccountPictureManifest -ManifestPath $paths.ManifestPath
    $status = if (-not $manifestResult.ReadSucceeded) {
        'Ownership state unavailable'
    }
    elseif (-not $manifestResult.Exists) {
        'Ready'
    }
    elseif ([bool](Get-BoostLabAccountPictureProperty $manifestResult.Manifest 'Active' $false)) {
        'Black account pictures active'
    }
    else {
        'Default restored'
    }

    [pscustomobject]@{
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        Status          = $status
        LastAction      = $null
        LastResult      = $null
        RestartRequired = $false
        Timestamp       = Get-Date
    }
}

function New-BoostLabAccountPictureResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$Message,

        [bool]$Cancelled = $false,

        [AllowNull()]
        [object]$Data = $null,

        [AllowNull()]
        [object]$VerificationResult = $null
    )

    [pscustomobject]@{
        Success            = $Success
        ToolId             = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle          = [string]$script:BoostLabToolMetadata['Title']
        Action             = $Action
        Message            = $Message
        RestartRequired    = $false
        Cancelled          = $Cancelled
        Timestamp          = Get-Date
        Data               = $Data
        VerificationResult = $VerificationResult
    }
}

function Test-BoostLabUserAccountPicturesState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [AllowNull()]
        [object]$Manifest,

        [scriptblock]$FileStateReader = {
            param($Path)
            Get-BoostLabAccountPictureFileState -Path $Path
        }
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    $files = @(Get-BoostLabAccountPictureProperty $Manifest 'Files' @())
    foreach ($entry in $files) {
        $targetPath = [string](Get-BoostLabAccountPictureProperty $entry 'TargetPath' '')
        $relativePath = [string](Get-BoostLabAccountPictureProperty $entry 'RelativePath' $targetPath)
        $originalHash = [string](Get-BoostLabAccountPictureProperty $entry 'OriginalSha256' '')
        $appliedHash = [string](Get-BoostLabAccountPictureProperty $entry 'AppliedSha256' '')
        $disposition = [string](Get-BoostLabAccountPictureProperty $entry 'LastDisposition' '')
        try {
            $states = @(& $FileStateReader $targetPath)
            $state = if ($states.Count -gt 0) { $states[0] } else { $null }
        }
        catch {
            $state = $null
        }

        $readSucceeded = [bool](Get-BoostLabAccountPictureProperty $state 'ReadSucceeded' $false)
        $exists = [bool](Get-BoostLabAccountPictureProperty $state 'Exists' $false)
        $actualHash = [string](Get-BoostLabAccountPictureProperty $state 'Sha256' '')
        $expectedHash = if ($ActionName -eq 'Apply') { $appliedHash } else { $originalHash }
        $status = 'Warning'
        $message = 'Image state could not be read.'

        if ($disposition -eq 'LeftIntactUnknownOwnership') {
            $status = 'Warning'
            $message = 'The image was left intact because its current content was not owned by BoostLab.'
        }
        elseif (-not $readSucceeded) {
            $status = 'Warning'
        }
        elseif (-not $exists) {
            $status = 'Failed'
            $message = 'The expected account-picture file is missing.'
        }
        elseif (-not [string]::IsNullOrWhiteSpace($expectedHash) -and $actualHash -eq $expectedHash) {
            $status = 'Passed'
            $message = if ($ActionName -eq 'Apply') {
                'The BoostLab-generated black image was detected.'
            }
            else {
                'The captured original image was detected.'
            }
        }
        else {
            $status = 'Failed'
            $message = 'The detected image hash contradicts the expected state.'
        }

        $checks.Add((New-BoostLabVerificationCheck `
            -Name $relativePath `
            -Expected $(if ([string]::IsNullOrWhiteSpace($expectedHash)) { 'Known tracked image hash' } else { $expectedHash }) `
            -Actual $(if ($exists) { $actualHash } else { 'Absent' }) `
            -Status $status `
            -Message $message))
    }

    $failedCount = @($checks | Where-Object Status -eq 'Failed').Count
    $warningCount = @($checks | Where-Object Status -eq 'Warning').Count
    $status = if ($failedCount -gt 0) {
        'Failed'
    }
    elseif ($warningCount -gt 0 -or $checks.Count -eq 0) {
        'Warning'
    }
    else {
        'Passed'
    }
    $expectedDescription = if ($ActionName -eq 'Apply') {
        'All tracked account pictures replaced with verified black images'
    }
    else {
        'All safely owned account pictures restored to captured originals'
    }
    $detectedDescription = '{0} passed, {1} warning, {2} failed' -f `
        @($checks | Where-Object Status -eq 'Passed').Count, `
        $warningCount, `
        $failedCount

    New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $ActionName `
        -Status $status `
        -ExpectedState ([pscustomobject]@{ AccountPictures = $expectedDescription }) `
        -DetectedState ([pscustomobject]@{ AccountPictures = $detectedDescription }) `
        -Checks $checks.ToArray() `
        -Message $(if ($status -eq 'Passed') {
            'The expected account-picture state was verified.'
        } elseif ($status -eq 'Warning') {
            'Account-picture verification completed with ownership or detection warnings.'
        } else {
            'One or more account pictures contradict the expected state.'
        })
}

function Invoke-BoostLabUserAccountPicturesBlackAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [Parameter(Mandatory)]
        [object]$Paths,

        [scriptblock]$ImageEnumerator = {
            param($TargetRoot)
            Get-BoostLabAccountPictureImages -TargetRoot $TargetRoot
        },

        [scriptblock]$FileStateReader = {
            param($Path)
            Get-BoostLabAccountPictureFileState -Path $Path
        },

        [scriptblock]$ManifestReader = {
            param($ManifestPath)
            Get-BoostLabAccountPictureManifest -ManifestPath $ManifestPath
        },

        [scriptblock]$ManifestWriter = {
            param($Manifest, $ManifestPath)
            Save-BoostLabAccountPictureManifest -Manifest $Manifest -ManifestPath $ManifestPath
        },

        [scriptblock]$BackupWriter = {
            param($SourcePath, $BackupPath)
            Copy-BoostLabAccountPictureBackup -SourcePath $SourcePath -BackupPath $BackupPath
        },

        [scriptblock]$BlackImageWriter = {
            param($Path)
            Set-BoostLabAccountPictureBlack -Path $Path
        },

        [scriptblock]$BackupRestorer = {
            param($BackupPath, $TargetPath)
            Restore-BoostLabAccountPictureBackup -BackupPath $BackupPath -TargetPath $TargetPath
        },

        [scriptblock]$BackupCleaner = {
            param($BackupPath, $ApprovedBackupRoot)
            Remove-BoostLabAccountPictureBackupSet -BackupPath $BackupPath -ApprovedBackupRoot $ApprovedBackupRoot
        }
    )

    $warnings = [System.Collections.Generic.List[string]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    $filesChanged = [System.Collections.Generic.List[string]]::new()
    $filesRestored = [System.Collections.Generic.List[string]]::new()
    $filesBackedUp = [System.Collections.Generic.List[string]]::new()
    $filesSkipped = [System.Collections.Generic.List[string]]::new()
    $unknownFiles = [System.Collections.Generic.List[string]]::new()
    $manifestResult = & $ManifestReader $Paths.ManifestPath
    if (-not [bool](Get-BoostLabAccountPictureProperty $manifestResult 'ReadSucceeded' $false)) {
        return New-BoostLabAccountPictureResult `
            -Success $false `
            -Action $ActionName `
            -Message ("Ownership manifest could not be read: {0}" -f (Get-BoostLabAccountPictureProperty $manifestResult 'Message' 'Unknown error'))
    }

    $manifest = Get-BoostLabAccountPictureProperty $manifestResult 'Manifest'
    if ($ActionName -eq 'Apply') {
        if ($null -ne $manifest -and [bool](Get-BoostLabAccountPictureProperty $manifest 'Active' $false)) {
            $manifestValidation = Test-BoostLabAccountPictureManifest -Manifest $manifest -Paths $Paths
            if (-not $manifestValidation.IsValid) {
                return New-BoostLabAccountPictureResult `
                    -Success $false `
                    -Action $ActionName `
                    -Message ("Existing ownership manifest is invalid: {0}" -f ($manifestValidation.Errors -join '; '))
            }
        }
        else {
            $snapshotId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
            $snapshotPath = Join-Path $Paths.BackupRoot $snapshotId
            $manifest = [pscustomobject]@{
                Version            = 1
                ToolId             = [string]$script:BoostLabToolMetadata['Id']
                CreatedByBoostLab  = $true
                Active             = $false
                PendingApply       = $true
                BackupsCleaned     = $false
                TargetRoot         = [string]$Paths.TargetRoot
                BackupPath         = $snapshotPath
                CreatedAt          = Get-Date
                UpdatedAt          = Get-Date
                Files              = @()
            }
        }

        $entries = [System.Collections.Generic.List[object]]::new()
        foreach ($entry in @(Get-BoostLabAccountPictureProperty $manifest 'Files' @())) {
            $entries.Add($entry)
        }
        $knownRelativePaths = @{}
        foreach ($entry in $entries) {
            $knownRelativePaths[[string](Get-BoostLabAccountPictureProperty $entry 'RelativePath' '')] = $true
        }

        $images = @(& $ImageEnumerator $Paths.TargetRoot)
        if ($images.Count -eq 0 -and $entries.Count -eq 0) {
            return New-BoostLabAccountPictureResult `
                -Success $false `
                -Action $ActionName `
                -Message 'No PNG or BMP account pictures were found beneath the approved Ultimate directory.'
        }

        foreach ($image in $images) {
            $targetPath = [string](Get-BoostLabAccountPictureProperty $image 'FullName' '')
            $relativePath = [string](Get-BoostLabAccountPictureProperty $image 'RelativePath' '')
            if (
                -not (Test-BoostLabAccountPicturePath -Path $targetPath -Root $Paths.TargetRoot -RequireImage) -or
                [string]::IsNullOrWhiteSpace($relativePath)
            ) {
                $errors.Add("Rejected out-of-scope account-picture path: $targetPath")
                continue
            }
            if ($knownRelativePaths.ContainsKey($relativePath)) {
                continue
            }

            $sourceState = & $FileStateReader $targetPath
            if (
                -not [bool](Get-BoostLabAccountPictureProperty $sourceState 'ReadSucceeded' $false) -or
                -not [bool](Get-BoostLabAccountPictureProperty $sourceState 'Exists' $false)
            ) {
                $errors.Add("Could not read account picture before backup: $relativePath")
                continue
            }
            $backupPath = Join-Path ([string]$manifest.BackupPath) $relativePath
            if (-not (Test-BoostLabAccountPicturePath -Path $backupPath -Root ([string]$manifest.BackupPath) -RequireImage)) {
                $errors.Add("Rejected out-of-scope backup path: $backupPath")
                continue
            }
            $backupResult = & $BackupWriter $targetPath $backupPath
            if (-not [bool](Get-BoostLabAccountPictureProperty $backupResult 'Success' $false)) {
                $errors.Add("Backup failed for ${relativePath}: $(Get-BoostLabAccountPictureProperty $backupResult 'Message' 'Unknown error')")
                continue
            }

            $entries.Add([pscustomobject]@{
                RelativePath     = $relativePath
                TargetPath       = $targetPath
                BackupPath       = $backupPath
                OriginalSha256   = [string](Get-BoostLabAccountPictureProperty $sourceState 'Sha256' '')
                BackupSha256     = [string](Get-BoostLabAccountPictureProperty $backupResult 'Sha256' '')
                AppliedSha256    = $null
                Width            = $null
                Height           = $null
                LastDisposition  = 'BackedUp'
            })
            $knownRelativePaths[$relativePath] = $true
            $filesBackedUp.Add($relativePath)
        }

        $manifest.Files = $entries.ToArray()
        $manifest.UpdatedAt = Get-Date
        $saved = & $ManifestWriter $manifest $Paths.ManifestPath
        if (-not [bool](Get-BoostLabAccountPictureProperty $saved 'Success' $false)) {
            return New-BoostLabAccountPictureResult `
                -Success $false `
                -Action $ActionName `
                -Message ("No account picture was changed because the ownership manifest could not be saved: {0}" -f (Get-BoostLabAccountPictureProperty $saved 'Message' 'Unknown error'))
        }
        if ($errors.Count -gt 0) {
            return New-BoostLabAccountPictureResult `
                -Success $false `
                -Action $ActionName `
                -Message ("No account picture was changed because backup preparation failed: {0}" -f ($errors -join '; '))
        }

        foreach ($entry in @($manifest.Files)) {
            $targetPath = [string]$entry.TargetPath
            $relativePath = [string]$entry.RelativePath
            $currentState = & $FileStateReader $targetPath
            $currentHash = [string](Get-BoostLabAccountPictureProperty $currentState 'Sha256' '')
            if (-not [bool](Get-BoostLabAccountPictureProperty $currentState 'ReadSucceeded' $false)) {
                $warnings.Add("Could not read current image; left intact: $relativePath")
                $entry.LastDisposition = 'LeftIntactUnknownOwnership'
                $filesSkipped.Add($relativePath)
                continue
            }
            if (-not [bool](Get-BoostLabAccountPictureProperty $currentState 'Exists' $false)) {
                $warnings.Add("Tracked image is missing; no file was created: $relativePath")
                $entry.LastDisposition = 'Missing'
                $filesSkipped.Add($relativePath)
                continue
            }
            if (
                -not [string]::IsNullOrWhiteSpace([string]$entry.AppliedSha256) -and
                $currentHash -eq [string]$entry.AppliedSha256
            ) {
                $entry.LastDisposition = 'AlreadyBlack'
                $filesSkipped.Add($relativePath)
                continue
            }
            if ($currentHash -ne [string]$entry.OriginalSha256) {
                $warnings.Add("Image changed outside BoostLab after backup; left intact: $relativePath")
                $entry.LastDisposition = 'LeftIntactUnknownOwnership'
                $unknownFiles.Add($relativePath)
                $filesSkipped.Add($relativePath)
                continue
            }

            $blackResult = & $BlackImageWriter $targetPath
            if (-not [bool](Get-BoostLabAccountPictureProperty $blackResult 'Success' $false)) {
                $errors.Add("Black image write failed for ${relativePath}: $(Get-BoostLabAccountPictureProperty $blackResult 'Message' 'Unknown error')")
                $entry.LastDisposition = 'WriteFailed'
                continue
            }
            $entry.AppliedSha256 = [string](Get-BoostLabAccountPictureProperty $blackResult 'Sha256' '')
            $entry.Width = Get-BoostLabAccountPictureProperty $blackResult 'Width'
            $entry.Height = Get-BoostLabAccountPictureProperty $blackResult 'Height'
            $entry.LastDisposition = 'BlackApplied'
            $filesChanged.Add($relativePath)
        }

        $manifest.Active = $true
        $manifest.PendingApply = $false
        $manifest.UpdatedAt = Get-Date
        $saved = & $ManifestWriter $manifest $Paths.ManifestPath
        if (-not [bool](Get-BoostLabAccountPictureProperty $saved 'Success' $false)) {
            $errors.Add("Updated ownership manifest could not be saved: $(Get-BoostLabAccountPictureProperty $saved 'Message' 'Unknown error')")
        }
    }
    else {
        if ($null -eq $manifest) {
            $warnings.Add('No BoostLab-owned backup manifest exists. Unknown account-picture files were left intact.')
            $manifest = [pscustomobject]@{ Files = @(); Active = $false }
        }
        else {
            $manifestValidation = Test-BoostLabAccountPictureManifest -Manifest $manifest -Paths $Paths
            if (-not $manifestValidation.IsValid) {
                return New-BoostLabAccountPictureResult `
                    -Success $false `
                    -Action $ActionName `
                    -Message ("Ownership manifest is invalid; no files were changed: {0}" -f ($manifestValidation.Errors -join '; '))
            }

            $knownRelativePaths = @{}
            foreach ($entry in @($manifest.Files)) {
                $relativePath = [string]$entry.RelativePath
                $knownRelativePaths[$relativePath] = $true
                $backupState = & $FileStateReader ([string]$entry.BackupPath)
                $targetState = & $FileStateReader ([string]$entry.TargetPath)
                $backupHash = [string](Get-BoostLabAccountPictureProperty $backupState 'Sha256' '')
                $targetHash = [string](Get-BoostLabAccountPictureProperty $targetState 'Sha256' '')

                if (
                    [bool](Get-BoostLabAccountPictureProperty $targetState 'ReadSucceeded' $false) -and
                    [bool](Get-BoostLabAccountPictureProperty $targetState 'Exists' $false) -and
                    $targetHash -eq [string]$entry.OriginalSha256
                ) {
                    $entry.LastDisposition = 'AlreadyDefault'
                    $filesSkipped.Add($relativePath)
                    continue
                }
                if (
                    -not [bool](Get-BoostLabAccountPictureProperty $backupState 'ReadSucceeded' $false) -or
                    -not [bool](Get-BoostLabAccountPictureProperty $backupState 'Exists' $false) -or
                    $backupHash -ne [string]$entry.OriginalSha256
                ) {
                    $warnings.Add("Verified backup unavailable; target left intact: $relativePath")
                    $entry.LastDisposition = 'BackupUnavailable'
                    $filesSkipped.Add($relativePath)
                    continue
                }
                if (
                    [bool](Get-BoostLabAccountPictureProperty $targetState 'Exists' $false) -and
                    (
                        -not [bool](Get-BoostLabAccountPictureProperty $targetState 'ReadSucceeded' $false) -or
                        [string]::IsNullOrWhiteSpace([string]$entry.AppliedSha256) -or
                        $targetHash -ne [string]$entry.AppliedSha256
                    )
                ) {
                    $warnings.Add("Current image is not the BoostLab-owned black file; left intact: $relativePath")
                    $entry.LastDisposition = 'LeftIntactUnknownOwnership'
                    $unknownFiles.Add($relativePath)
                    $filesSkipped.Add($relativePath)
                    continue
                }

                $restoreResult = & $BackupRestorer ([string]$entry.BackupPath) ([string]$entry.TargetPath)
                if (-not [bool](Get-BoostLabAccountPictureProperty $restoreResult 'Success' $false)) {
                    $errors.Add("Restore failed for ${relativePath}: $(Get-BoostLabAccountPictureProperty $restoreResult 'Message' 'Unknown error')")
                    $entry.LastDisposition = 'RestoreFailed'
                    continue
                }
                $entry.LastDisposition = 'Restored'
                $filesRestored.Add($relativePath)
            }

            foreach ($image in @(& $ImageEnumerator $Paths.TargetRoot)) {
                $relativePath = [string](Get-BoostLabAccountPictureProperty $image 'RelativePath' '')
                if (-not $knownRelativePaths.ContainsKey($relativePath)) {
                    $unknownFiles.Add($relativePath)
                    $warnings.Add("Untracked account-picture file left intact: $relativePath")
                }
            }

            $manifest.Active = $false
            $manifest.PendingApply = $false
            $manifest.UpdatedAt = Get-Date
        }
    }

    $verification = Test-BoostLabUserAccountPicturesState `
        -ActionName $ActionName `
        -Manifest $manifest `
        -FileStateReader $FileStateReader

    if (
        $ActionName -eq 'Default' -and
        $null -ne (Get-BoostLabAccountPictureProperty $manifest 'ToolId')
    ) {
        $savedBeforeCleanup = & $ManifestWriter $manifest $Paths.ManifestPath
        if (-not [bool](Get-BoostLabAccountPictureProperty $savedBeforeCleanup 'Success' $false)) {
            $errors.Add("Restored ownership state could not be saved before backup cleanup: $(Get-BoostLabAccountPictureProperty $savedBeforeCleanup 'Message' 'Unknown error')")
        }
    }

    if (
        $ActionName -eq 'Default' -and
        $null -ne (Get-BoostLabAccountPictureProperty $manifest 'BackupPath') -and
        $errors.Count -eq 0 -and
        $verification.Status -eq 'Passed'
    ) {
        $cleanupResult = & $BackupCleaner ([string]$manifest.BackupPath) ([string]$Paths.BackupRoot)
        if ([bool](Get-BoostLabAccountPictureProperty $cleanupResult 'Success' $false)) {
            $manifest.BackupsCleaned = $true
        }
        else {
            $warnings.Add("Restoration succeeded, but tool-owned backup cleanup failed: $(Get-BoostLabAccountPictureProperty $cleanupResult 'Message' 'Unknown error')")
        }
    }

    if ($null -ne (Get-BoostLabAccountPictureProperty $manifest 'ToolId')) {
        $saved = & $ManifestWriter $manifest $Paths.ManifestPath
        if (-not [bool](Get-BoostLabAccountPictureProperty $saved 'Success' $false)) {
            $errors.Add("Final ownership manifest could not be saved: $(Get-BoostLabAccountPictureProperty $saved 'Message' 'Unknown error')")
        }
    }

    $commandStatus = if ($errors.Count -gt 0) {
        'Completed with errors'
    }
    elseif ($warnings.Count -gt 0) {
        'Completed with warnings'
    }
    else {
        'Completed'
    }
    $data = [pscustomobject]@{
        CommandStatus       = $commandStatus
        VerificationStatus  = [string]$verification.Status
        ExpectedState       = $verification.ExpectedState
        DetectedState       = $verification.DetectedState
        TargetRoot          = [string]$Paths.TargetRoot
        BackupPath          = Get-BoostLabAccountPictureProperty $manifest 'BackupPath'
        ManifestPath        = [string]$Paths.ManifestPath
        FilesTargeted       = @((Get-BoostLabAccountPictureProperty $manifest 'Files' @()) | ForEach-Object { [string]$_.RelativePath })
        FilesBackedUp       = $filesBackedUp.ToArray()
        FilesChanged        = $filesChanged.ToArray()
        FilesRestored       = $filesRestored.ToArray()
        FilesSkipped        = $filesSkipped.ToArray()
        UnknownFiles        = $unknownFiles.ToArray()
        Warnings            = $warnings.ToArray()
        Errors              = $errors.ToArray()
        CompletedAt         = Get-Date
    }
    $success = $errors.Count -eq 0 -and $verification.Status -ne 'Failed'
    $message = if (-not $success) {
        "User account picture action failed: $($errors -join '; ')"
    }
    elseif ($ActionName -eq 'Apply' -and $warnings.Count -gt 0) {
        'Black account pictures applied with warnings; unknown files were left intact.'
    }
    elseif ($ActionName -eq 'Apply') {
        'Black account pictures applied.'
    }
    elseif ($warnings.Count -gt 0) {
        'User account pictures restored where safely owned; unknown files were left intact.'
    }
    else {
        'User account pictures restored to the captured defaults.'
    }

    New-BoostLabAccountPictureResult `
        -Success $success `
        -Action $ActionName `
        -Message $message `
        -Data $data `
        -VerificationResult $verification
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ActionName,

        [bool]$Confirmed = $false
    )

    if ($ActionName -notin $script:BoostLabImplementedActions) {
        return New-BoostLabAccountPictureResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Unsupported action. Only Apply and Default are allowed.'
    }
    if (-not $Confirmed) {
        return New-BoostLabAccountPictureResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }
    if (-not (Test-BoostLabAdministrator)) {
        return New-BoostLabAccountPictureResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Administrator rights are required to modify Windows account-picture files.'
    }

    try {
        return Invoke-BoostLabUserAccountPicturesBlackAction `
            -ActionName $ActionName `
            -Paths (Get-BoostLabAccountPicturePaths)
    }
    catch {
        return New-BoostLabAccountPictureResult `
            -Success $false `
            -Action $ActionName `
            -Message ("User account picture action failed: {0}" -f $_.Exception.Message) `
            -Data ([pscustomobject]@{
                CommandStatus      = 'Failed'
                VerificationStatus = 'Not available'
                Warnings           = @()
                Errors             = @($_.Exception.Message)
                CompletedAt        = Get-Date
            })
    }
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
)
