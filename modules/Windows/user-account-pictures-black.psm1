Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'user-account-pictures-black'
    Title = 'User Account Pictures Black'
    Stage = 'Windows'
    Order = 6
    Type = 'action'
    RiskLevel = 'medium'
    Description = 'Replace Windows account pictures with black images, or copy the source-defined legacy account-picture backup back to the Microsoft account-picture directory.'
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
    $programData = Join-Path $systemDrive 'ProgramData'

    [pscustomobject]@{
        ProgramDataRoot  = $programData
        TargetRoot       = Join-Path $programData 'Microsoft\User Account Pictures'
        LegacyBackupRoot = Join-Path $programData 'User Account Pictures'
        DefaultTarget    = Join-Path $programData 'Microsoft'
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
        $reasons.Add("The source-defined account-picture directory is unavailable: $($paths.TargetRoot)")
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
            'The source-defined account-picture directory and image runtime are available.'
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
        Get-ChildItem -Path $TargetRoot -Include *.png,*.bmp -Recurse -ErrorAction SilentlyContinue |
            Sort-Object FullName |
            ForEach-Object {
                [pscustomobject]@{
                    FullName = $_.FullName
                    Name     = $_.Name
                }
            }
    )
}

function Initialize-BoostLabAccountPictureImageRuntime {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        [pscustomobject]@{ Success = $true; Message = 'System.Drawing loaded.' }
    }
    catch {
        [pscustomobject]@{ Success = $false; Message = $_.Exception.Message }
    }
}

function Copy-BoostLabUltimateAccountPictureBackup {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Paths
    )

    try {
        if (-not [IO.Directory]::Exists($Paths.LegacyBackupRoot)) {
            Copy-Item $Paths.TargetRoot -Destination $Paths.ProgramDataRoot -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
            return [pscustomobject]@{
                Success     = $true
                Attempted   = $true
                Skipped     = $false
                Source      = $Paths.TargetRoot
                Destination = $Paths.ProgramDataRoot
                Message     = 'Source-defined legacy account-picture backup copy was requested.'
            }
        }

        [pscustomobject]@{
            Success     = $true
            Attempted   = $false
            Skipped     = $true
            Source      = $Paths.TargetRoot
            Destination = $Paths.ProgramDataRoot
            Message     = 'Source-defined legacy account-picture backup already exists.'
        }
    }
    catch {
        [pscustomobject]@{
            Success     = $false
            Attempted   = $true
            Skipped     = $false
            Source      = $Paths.TargetRoot
            Destination = $Paths.ProgramDataRoot
            Message     = $_.Exception.Message
        }
    }
}

function Set-BoostLabAccountPictureBlack {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $bitmap = $null
    $newBitmap = $null
    $graphics = $null
    try {
        $bitmap = [System.Drawing.Bitmap]::FromFile($Path)
        $width = $bitmap.Width
        $height = $bitmap.Height
        $bitmap.Dispose()
        $bitmap = $null

        $newBitmap = New-Object System.Drawing.Bitmap($width, $height)
        $graphics = [System.Drawing.Graphics]::FromImage($newBitmap)
        $graphics.Clear([System.Drawing.Color]::Black)
        $graphics.Dispose()
        $graphics = $null
        $newBitmap.Save($Path)
        $newBitmap.Dispose()
        $newBitmap = $null

        [pscustomobject]@{
            Success = $true
            Path    = $Path
            Width   = $width
            Height  = $height
            Message = "Black image written at ${width}x${height}."
        }
    }
    catch {
        [pscustomobject]@{
            Success = $false
            Path    = $Path
            Width   = $null
            Height  = $null
            Message = $_.Exception.Message
        }
    }
    finally {
        if ($graphics) { $graphics.Dispose() }
        if ($newBitmap) { $newBitmap.Dispose() }
        if ($bitmap) { $bitmap.Dispose() }
    }
}

function Copy-BoostLabUltimateAccountPictureDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Paths
    )

    try {
        Copy-Item $Paths.LegacyBackupRoot -Destination $Paths.DefaultTarget -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        [pscustomobject]@{
            Success     = $true
            Attempted   = $true
            Source      = $Paths.LegacyBackupRoot
            Destination = $Paths.DefaultTarget
            Message     = 'Source-defined legacy account-picture default copy was requested.'
        }
    }
    catch {
        [pscustomobject]@{
            Success     = $false
            Attempted   = $true
            Source      = $Paths.LegacyBackupRoot
            Destination = $Paths.DefaultTarget
            Message     = $_.Exception.Message
        }
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $paths = Get-BoostLabAccountPicturePaths
    $targetExists = [IO.Directory]::Exists($paths.TargetRoot)
    $legacyBackupExists = [IO.Directory]::Exists($paths.LegacyBackupRoot)
    $status = if (-not $targetExists) {
        'Source target unavailable'
    }
    elseif ($legacyBackupExists) {
        'Source legacy backup available'
    }
    else {
        'Ready'
    }

    [pscustomobject]@{
        ToolId             = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle          = [string]$script:BoostLabToolMetadata['Title']
        Status             = $status
        TargetRoot         = $paths.TargetRoot
        LegacyBackupRoot   = $paths.LegacyBackupRoot
        TargetRootExists   = $targetExists
        LegacyBackupExists = $legacyBackupExists
        LastAction         = $null
        LastResult         = $null
        RestartRequired    = $false
        Timestamp          = Get-Date
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

function New-BoostLabAccountPictureVerification {
    param(
        [Parameter(Mandatory)]
        [string]$ActionName,

        [Parameter(Mandatory)]
        [string]$Status,

        [Parameter(Mandatory)]
        [object]$ExpectedState,

        [Parameter(Mandatory)]
        [object]$DetectedState,

        [object[]]$Checks = @(),

        [Parameter(Mandatory)]
        [string]$Message
    )

    New-BoostLabVerificationResult `
        -ToolId $script:BoostLabToolMetadata['Id'] `
        -ToolTitle $script:BoostLabToolMetadata['Title'] `
        -Action $ActionName `
        -Status $Status `
        -ExpectedState $ExpectedState `
        -DetectedState $DetectedState `
        -Checks $Checks `
        -Message $Message
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [bool]$Confirmed = $false,

        [scriptblock]$AdministratorChecker = {
            Test-BoostLabAdministrator
        },

        [scriptblock]$PathProvider = {
            Get-BoostLabAccountPicturePaths
        },

        [scriptblock]$DirectoryExistsChecker = {
            param($Path)
            [IO.Directory]::Exists($Path)
        },

        [scriptblock]$LegacyBackupRunner = {
            param($Paths)
            Copy-BoostLabUltimateAccountPictureBackup -Paths $Paths
        },

        [scriptblock]$ImageEnumerator = {
            param($TargetRoot)
            Get-BoostLabAccountPictureImages -TargetRoot $TargetRoot
        },

        [scriptblock]$ImageRuntimeLoader = {
            Initialize-BoostLabAccountPictureImageRuntime
        },

        [scriptblock]$BlackImageWriter = {
            param($Path)
            Set-BoostLabAccountPictureBlack -Path $Path
        },

        [scriptblock]$DefaultCopyRunner = {
            param($Paths)
            Copy-BoostLabUltimateAccountPictureDefault -Paths $Paths
        }
    )

    if (-not $Confirmed) {
        return New-BoostLabAccountPictureResult `
            -Success $false `
            -Action $ActionName `
            -Cancelled $true `
            -Message 'Action Plan confirmation is required before changing User Account Pictures Black files.' `
            -Data ([pscustomobject]@{
                CommandStatus      = 'Cancelled'
                VerificationStatus = 'NotApplicable'
                ChangesExecuted    = $false
                Errors             = @()
                Warnings           = @('Action Plan confirmation was not provided.')
            })
    }

    if (-not (& $AdministratorChecker)) {
        return New-BoostLabAccountPictureResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Administrator execution is required before changing source-defined account-picture files.' `
            -Data ([pscustomobject]@{
                CommandStatus      = 'NeedsAdministrator'
                VerificationStatus = 'NotApplicable'
                ChangesExecuted    = $false
                Errors             = @()
                Warnings           = @('No file operation was executed because Administrator rights were not confirmed.')
            })
    }

    $warnings = [System.Collections.Generic.List[string]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    $checks = [System.Collections.Generic.List[object]]::new()
    $events = [System.Collections.Generic.List[string]]::new()

    try {
        $paths = & $PathProvider
        if ($ActionName -eq 'Apply') {
            $backupResult = $null
            if (-not (& $DirectoryExistsChecker $paths.LegacyBackupRoot)) {
                $events.Add('CopyLegacyBackup')
                $backupResult = & $LegacyBackupRunner $paths
                if (-not [bool](Get-BoostLabAccountPictureProperty $backupResult 'Success' $false)) {
                    $warnings.Add("Source-defined legacy backup copy returned a warning: $([string](Get-BoostLabAccountPictureProperty $backupResult 'Message' 'Unknown backup warning.'))")
                }
            }
            else {
                $backupResult = [pscustomobject]@{
                    Success = $true
                    Skipped = $true
                    Message = 'Source-defined legacy account-picture backup already exists.'
                }
                $events.Add('LegacyBackupAlreadyExists')
            }

            $events.Add('EnumerateImages')
            $images = @(& $ImageEnumerator $paths.TargetRoot)
            $events.Add('LoadSystemDrawing')
            $runtimeResult = & $ImageRuntimeLoader
            if (-not [bool](Get-BoostLabAccountPictureProperty $runtimeResult 'Success' $false)) {
                $warnings.Add("System.Drawing load returned a warning: $([string](Get-BoostLabAccountPictureProperty $runtimeResult 'Message' 'Unknown image runtime warning.'))")
            }

            $writtenImages = [System.Collections.Generic.List[object]]::new()
            $failedImages = [System.Collections.Generic.List[object]]::new()
            foreach ($image in $images) {
                $imagePath = [string](Get-BoostLabAccountPictureProperty $image 'FullName' '')
                if ([string]::IsNullOrWhiteSpace($imagePath)) {
                    $warnings.Add('A discovered account-picture image did not expose a FullName path and was skipped.')
                    continue
                }

                $events.Add("WriteBlackImage:$imagePath")
                $writeResult = & $BlackImageWriter $imagePath
                if ([bool](Get-BoostLabAccountPictureProperty $writeResult 'Success' $false)) {
                    $writtenImages.Add($writeResult)
                }
                else {
                    $failedImages.Add($writeResult)
                    $warnings.Add("Source-defined image overwrite returned a warning for ${imagePath}: $([string](Get-BoostLabAccountPictureProperty $writeResult 'Message' 'Unknown image write warning.'))")
                }
            }

            $status = if ($warnings.Count -eq 0) { 'Passed' } else { 'Warning' }
            $checks.Add((New-BoostLabVerificationCheck `
                -Name 'Legacy account-picture backup branch' `
                -Expected 'Copy Microsoft\User Account Pictures to ProgramData when ProgramData\User Account Pictures is absent' `
                -Actual ([string](Get-BoostLabAccountPictureProperty $backupResult 'Message' 'No backup result')) `
                -Status $(if ([bool](Get-BoostLabAccountPictureProperty $backupResult 'Success' $false)) { 'Passed' } else { 'Warning' }) `
                -Message 'Apply executed the source-defined legacy backup branch before image overwrite.'))
            $checks.Add((New-BoostLabVerificationCheck `
                -Name 'Account picture image overwrite scope' `
                -Expected 'Recursive *.png and *.bmp files under Microsoft\User Account Pictures' `
                -Actual ("{0} discovered; {1} written; {2} warning(s)" -f $images.Count, $writtenImages.Count, $failedImages.Count) `
                -Status $status `
                -Message 'Apply attempted the source-defined black-image overwrite for discovered account pictures.'))

            $verification = New-BoostLabAccountPictureVerification `
                -ActionName $ActionName `
                -Status $status `
                -ExpectedState ([pscustomobject]@{
                    TargetRoot = $paths.TargetRoot
                    LegacyBackupRoot = $paths.LegacyBackupRoot
                    IncludedExtensions = @($script:BoostLabApprovedExtensions)
                    ImageFill = 'Black'
                }) `
                -DetectedState ([pscustomobject]@{
                    TargetRoot = $paths.TargetRoot
                    LegacyBackupRoot = $paths.LegacyBackupRoot
                    ImagesDiscovered = $images.Count
                    ImagesWritten = $writtenImages.Count
                    ImagesWithWarnings = $failedImages.Count
                }) `
                -Checks $checks.ToArray() `
                -Message $(if ($status -eq 'Passed') { 'Source-defined Black branch completed.' } else { 'Source-defined Black branch completed with warnings.' })

            return New-BoostLabAccountPictureResult `
                -Success $true `
                -Action $ActionName `
                -Message $verification.Message `
                -VerificationResult $verification `
                -Data ([pscustomobject]@{
                    CommandStatus      = if ($warnings.Count -eq 0) { 'Completed' } else { 'CompletedWithWarnings' }
                    VerificationStatus = $verification.Status
                    ChangesExecuted    = $true
                    TargetRoot         = $paths.TargetRoot
                    LegacyBackupRoot   = $paths.LegacyBackupRoot
                    BackupResult       = $backupResult
                    TargetedFiles      = @($images)
                    ChangedFiles       = @($writtenImages)
                    WarningFiles       = @($failedImages)
                    OperationOrder     = $events.ToArray()
                    Warnings           = $warnings.ToArray()
                    Errors             = $errors.ToArray()
                    CompletedAt        = Get-Date
                })
        }

        $events.Add('CopyLegacyBackupToMicrosoft')
        $copyResult = & $DefaultCopyRunner $paths
        if (-not [bool](Get-BoostLabAccountPictureProperty $copyResult 'Success' $false)) {
            $warnings.Add("Source-defined Default copy returned a warning: $([string](Get-BoostLabAccountPictureProperty $copyResult 'Message' 'Unknown default copy warning.'))")
        }

        $status = if ($warnings.Count -eq 0) { 'Passed' } else { 'Warning' }
        $checks.Add((New-BoostLabVerificationCheck `
            -Name 'Legacy account-picture default branch' `
            -Expected 'Copy ProgramData\User Account Pictures to ProgramData\Microsoft' `
            -Actual ([string](Get-BoostLabAccountPictureProperty $copyResult 'Message' 'No default copy result')) `
            -Status $status `
            -Message 'Default executed the source-defined legacy backup copy-back branch.'))

        $verification = New-BoostLabAccountPictureVerification `
            -ActionName $ActionName `
            -Status $status `
            -ExpectedState ([pscustomobject]@{
                Source = $paths.LegacyBackupRoot
                Destination = $paths.DefaultTarget
            }) `
            -DetectedState ([pscustomobject]@{
                Source = [string](Get-BoostLabAccountPictureProperty $copyResult 'Source' $paths.LegacyBackupRoot)
                Destination = [string](Get-BoostLabAccountPictureProperty $copyResult 'Destination' $paths.DefaultTarget)
                CopyRequested = [bool](Get-BoostLabAccountPictureProperty $copyResult 'Attempted' $true)
            }) `
            -Checks $checks.ToArray() `
            -Message $(if ($status -eq 'Passed') { 'Source-defined Default branch completed.' } else { 'Source-defined Default branch completed with warnings.' })

        return New-BoostLabAccountPictureResult `
            -Success $true `
            -Action $ActionName `
            -Message $verification.Message `
            -VerificationResult $verification `
            -Data ([pscustomobject]@{
                CommandStatus      = if ($warnings.Count -eq 0) { 'Completed' } else { 'CompletedWithWarnings' }
                VerificationStatus = $verification.Status
                ChangesExecuted    = $true
                TargetRoot         = $paths.TargetRoot
                LegacyBackupRoot   = $paths.LegacyBackupRoot
                DefaultTarget      = $paths.DefaultTarget
                CopyResult         = $copyResult
                OperationOrder     = $events.ToArray()
                Warnings           = $warnings.ToArray()
                Errors             = $errors.ToArray()
                CompletedAt        = Get-Date
            })
    }
    catch {
        $errors.Add($_.Exception.Message)
        $verification = New-BoostLabAccountPictureVerification `
            -ActionName $ActionName `
            -Status 'Failed' `
            -ExpectedState ([pscustomobject]@{ SourceDefinedAction = $ActionName }) `
            -DetectedState ([pscustomobject]@{ Error = $_.Exception.Message }) `
            -Checks @() `
            -Message 'Source-defined User Account Pictures Black action failed before completion.'

        return New-BoostLabAccountPictureResult `
            -Success $false `
            -Action $ActionName `
            -Message $verification.Message `
            -VerificationResult $verification `
            -Data ([pscustomobject]@{
                CommandStatus      = 'Error'
                VerificationStatus = 'Failed'
                ChangesExecuted    = $false
                OperationOrder     = $events.ToArray()
                Warnings           = $warnings.ToArray()
                Errors             = $errors.ToArray()
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
