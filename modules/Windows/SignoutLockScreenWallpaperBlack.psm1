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

    $supported = $reasons.Count -eq 0
    [pscustomobject]@{
        Supported = $supported
        Reason    = if ($supported) { 'Windows image, registry, file-delete, and wallpaper refresh support are available.' } else { $reasons -join ' ' }
        Reasons   = @($reasons)
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

function Get-BoostLabSignoutWallpaperOperations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string] $ActionName
    )

    if ($ActionName -eq 'Apply') {
        return @(
            [pscustomobject]@{ Operation = 'GenerateImage'; Path = $script:TargetPath }
            [pscustomobject]@{ Operation = 'Add'; Key = $script:PersonalizationCspKey; Name = 'LockScreenImagePath'; Type = 'REG_SZ'; Value = $script:TargetPath }
            [pscustomobject]@{ Operation = 'Add'; Key = $script:PersonalizationCspKey; Name = 'LockScreenImageStatus'; Type = 'REG_DWORD'; Value = 1 }
            [pscustomobject]@{ Operation = 'Add'; Key = $script:DesktopKey; Name = 'Wallpaper'; Type = 'REG_SZ'; Value = $script:TargetPath }
            [pscustomobject]@{ Operation = 'RefreshWallpaper' }
        )
    }

    return @(
        [pscustomobject]@{ Operation = 'DeleteKey'; Key = $script:PersonalizationCspKey }
        [pscustomobject]@{ Operation = 'Add'; Key = $script:DesktopKey; Name = 'Wallpaper'; Type = 'REG_SZ'; Value = $script:DefaultWallpaperPath }
        [pscustomobject]@{ Operation = 'RefreshWallpaper' }
        [pscustomobject]@{ Operation = 'RemoveFile'; Path = $script:TargetPath }
    )
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

    try {
        $bitmap = New-Object System.Drawing.Bitmap $primaryMonitorSize.Width, $primaryMonitorSize.Height
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $color = [System.Drawing.Brushes]::Black
        $graphics.FillRectangle($color, 0, 0, $bitmap.Width, $bitmap.Height)
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

    $commandText = switch ([string]$Operation.Operation) {
        'Add' {
            'reg add "{0}" /v "{1}" /t {2} /d "{3}" /f' -f `
                $Operation.Key, `
                $Operation.Name, `
                $Operation.Type, `
                [string]$Operation.Value
        }
        'DeleteKey' {
            'reg delete "{0}" /f' -f $Operation.Key
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
        Operation = [string]$Operation.Operation
        Key       = Get-BoostLabStateProperty $Operation 'Key'
        Name      = Get-BoostLabStateProperty $Operation 'Name'
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

function Remove-BoostLabBlackWallpaperFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    Remove-Item -Recurse -Force $Path -ErrorAction SilentlyContinue | Out-Null

    [pscustomobject]@{
        Success = $true
        Path    = $Path
        Message = 'Source-defined Black.jpg delete requested.'
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
            ErrorMessage = $null
        }
    }

    try {
        $file = [IO.FileInfo]::new($Path)
        [pscustomobject]@{
            Exists       = $true
            Path         = $Path
            Length       = $file.Length
            ErrorMessage = $null
        }
    }
    catch {
        [pscustomobject]@{
            Exists       = $true
            Path         = $Path
            Length       = $null
            ErrorMessage = $_.Exception.Message
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

function Get-BoostLabRegistryKeyState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Key
    )

    $normalizedKey = $Key -replace '^HKLM\\', 'HKLM:\' -replace '^HKCU\\', 'HKCU:\'
    try {
        $null = Get-Item -LiteralPath $normalizedKey -ErrorAction Stop
        [pscustomobject]@{
            Detected     = $true
            Exists       = $true
            ErrorMessage = $null
        }
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        [pscustomobject]@{
            Detected     = $true
            Exists       = $false
            ErrorMessage = $null
        }
    }
    catch {
        [pscustomobject]@{
            Detected     = $false
            Exists       = $false
            ErrorMessage = $_.Exception.Message
        }
    }
}

function Test-BoostLabSignoutWallpaperState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string] $ActionName,

        [scriptblock] $RegistryReader = {
            param($Key, $Name)
            Get-BoostLabRegistryValueState -Key $Key -Name $Name
        },

        [scriptblock] $RegistryKeyReader = {
            param($Key)
            Get-BoostLabRegistryKeyState -Key $Key
        },

        [scriptblock] $FileReader = {
            param($Path)
            Get-BoostLabWallpaperFileState -Path $Path
        }
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    if ($ActionName -eq 'Apply') {
        $definitions = @(
            [pscustomobject]@{ Name = 'LockScreenImagePath'; Key = $script:PersonalizationCspKey; Value = $script:TargetPath }
            [pscustomobject]@{ Name = 'LockScreenImageStatus'; Key = $script:PersonalizationCspKey; Value = 1 }
            [pscustomobject]@{ Name = 'Wallpaper'; Key = $script:DesktopKey; Value = $script:TargetPath }
        )
    }
    else {
        $keyState = & $RegistryKeyReader $script:PersonalizationCspKey
        $keyDetected = [bool](Get-BoostLabStateProperty $keyState 'Detected' $false)
        $keyExists = [bool](Get-BoostLabStateProperty $keyState 'Exists' $false)
        $keyStatus = if (-not $keyDetected) {
            'Warning'
        }
        elseif ($keyExists) {
            'Failed'
        }
        else {
            'Passed'
        }
        $checks.Add((New-BoostLabVerificationCheck `
            -Name "Registry key: $script:PersonalizationCspKey" `
            -Expected 'Absent' `
            -Actual $(if (-not $keyDetected) { 'Unknown' } elseif ($keyExists) { 'Present' } else { 'Absent' }) `
            -Status $keyStatus `
            -Message $(if ($keyStatus -eq 'Passed') { 'The complete PersonalizationCSP key is absent as Ultimate Default defines.' } elseif ($keyStatus -eq 'Failed') { 'The PersonalizationCSP key still exists.' } else { 'The PersonalizationCSP key state could not be detected.' })))

        $definitions = @(
            [pscustomobject]@{ Name = 'Wallpaper'; Key = $script:DesktopKey; Value = $script:DefaultWallpaperPath }
        )
    }

    foreach ($definition in $definitions) {
        $detected = & $RegistryReader $definition.Key $definition.Name
        $status = 'Warning'
        $message = 'Registry state could not be detected.'

        if ([bool](Get-BoostLabStateProperty $detected 'Detected' $false)) {
            $exists = [bool](Get-BoostLabStateProperty $detected 'Exists' $false)
            if (-not $exists) {
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
            -Expected ([string]$definition.Value) `
            -Actual $(if ($null -eq $detected) { 'Unknown' } elseif ([bool](Get-BoostLabStateProperty $detected 'Exists' $false)) { [string](Get-BoostLabStateProperty $detected 'Value') } else { 'Absent' }) `
            -Message $message))
    }

    $fileState = & $FileReader $script:TargetPath
    $fileExists = [bool](Get-BoostLabStateProperty $fileState 'Exists' $false)
    $fileExpected = if ($ActionName -eq 'Apply') { 'Present' } else { 'Absent' }
    $fileStatus = if ($ActionName -eq 'Apply') {
        if ($fileExists) { 'Passed' } else { 'Failed' }
    }
    else {
        if ($fileExists) { 'Failed' } else { 'Passed' }
    }
    $checks.Add((New-BoostLabVerificationCheck `
        -Name "File: $script:TargetPath" `
        -Status $fileStatus `
        -Expected $fileExpected `
        -Actual $(if ($fileExists) { 'Present' } else { 'Absent' }) `
        -Message $(if ($fileStatus -eq 'Passed') { 'Black.jpg matches the requested source state.' } else { 'Black.jpg does not match the requested source state.' })))

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
        'Source default wallpaper restored'
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
            FileDisposition = if ($ActionName -eq 'Apply') { 'Generated' } else { 'Deleted' }
        }) `
        -Checks @($checks) `
        -Message $(if ($status -eq 'Passed') { 'All source-defined wallpaper, registry, and file checks passed.' } elseif ($status -eq 'Warning') { 'Source-defined state matched with one or more detection warnings.' } else { 'One or more detected states contradict the requested source action.' })
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    param()

    [pscustomobject]@{
        Status      = 'Runtime ready; Apply/Default require confirmation.'
        Implemented = $true
        Active      = $false
        TargetPath  = $script:TargetPath
        DefaultPath = $script:DefaultWallpaperPath
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
            Summary        = 'Generate and apply the source-defined black sign-out, lock screen, and desktop wallpaper.'
            PlannedChanges = @(
                'Generate C:\Windows\Black.jpg as a black bitmap at the primary monitor resolution.'
                'Set HKLM PersonalizationCSP LockScreenImagePath to C:\Windows\Black.jpg.'
                'Set HKLM PersonalizationCSP LockScreenImageStatus to REG_DWORD 1.'
                'Set the current user desktop Wallpaper value to C:\Windows\Black.jpg.'
                'Request Windows to refresh per-user wallpaper parameters.'
            )
            SideEffects     = @(
                'The desktop, sign-out, and lock screen wallpaper may become black.'
                'Any existing C:\Windows\Black.jpg is overwritten by the source-defined generated image.'
                'No download, installer, service, driver, Explorer restart, sign-out, or reboot occurs.'
            )
            ConfirmationMessage = 'Apply the exact source-defined black sign-out, lock screen, and desktop wallpaper configuration?'
        }
    }

    [pscustomobject]@{
        Summary        = 'Restore the exact source-defined default wallpaper state.'
        PlannedChanges = @(
            'Delete the complete HKLM PersonalizationCSP key exactly as the Ultimate source defines.'
            'Set the current user desktop Wallpaper value to C:\Windows\Web\Wallpaper\Windows\img0.jpg.'
            'Request Windows to refresh per-user wallpaper parameters.'
            'Delete C:\Windows\Black.jpg exactly as the Ultimate source defines.'
        )
        SideEffects     = @(
            'The desktop and lock screen wallpaper may return to the approved Windows default.'
            'Any values under the PersonalizationCSP key are removed by the source-defined key deletion.'
            'No download, installer, service, driver, Explorer restart, sign-out, or reboot occurs.'
        )
        ConfirmationMessage = 'Run the exact source-defined Default action, including complete PersonalizationCSP key deletion and C:\Windows\Black.jpg deletion?'
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

        [scriptblock] $RegistryKeyReader = {
            param($Key)
            Get-BoostLabRegistryKeyState -Key $Key
        },

        [scriptblock] $FileReader = {
            param($Path)
            Get-BoostLabWallpaperFileState -Path $Path
        },

        [scriptblock] $ImageGenerator = {
            param($Path)
            New-BoostLabBlackWallpaperImage -Path $Path
        },

        [scriptblock] $WallpaperRefresher = {
            Invoke-BoostLabWallpaperRefresh
        },

        [scriptblock] $FileRemover = {
            param($Path)
            Remove-BoostLabBlackWallpaperFile -Path $Path
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
    $refreshResult = $null
    $fileRemoveResult = $null
    $fileDisposition = if ($ActionName -eq 'Apply') { 'Generated' } else { 'Deleted' }

    try {
        if ($ActionName -eq 'Apply') {
            $imageResult = & $ImageGenerator $script:TargetPath
            if (-not [bool](Get-BoostLabStateProperty $imageResult 'Success' $false)) {
                throw "Black wallpaper generation failed: $(Get-BoostLabStateProperty $imageResult 'Message' 'Unknown image error.')"
            }

            $registryOperations = @(
                [pscustomobject]@{ Operation = 'Add'; Key = $script:PersonalizationCspKey; Name = 'LockScreenImagePath'; Type = 'REG_SZ'; Value = $script:TargetPath }
                [pscustomobject]@{ Operation = 'Add'; Key = $script:PersonalizationCspKey; Name = 'LockScreenImageStatus'; Type = 'REG_DWORD'; Value = 1 }
                [pscustomobject]@{ Operation = 'Add'; Key = $script:DesktopKey; Name = 'Wallpaper'; Type = 'REG_SZ'; Value = $script:TargetPath }
            )
        }
        else {
            $registryOperations = @(
                [pscustomobject]@{ Operation = 'DeleteKey'; Key = $script:PersonalizationCspKey; Name = $null; Type = $null; Value = $null }
                [pscustomobject]@{ Operation = 'Add'; Key = $script:DesktopKey; Name = 'Wallpaper'; Type = 'REG_SZ'; Value = $script:DefaultWallpaperPath }
            )
        }

        foreach ($operation in $registryOperations) {
            $registryResult = & $RegistryCommandRunner $operation
            $registryResults.Add($registryResult)
        }

        $refreshResult = & $WallpaperRefresher
        if (-not [bool](Get-BoostLabStateProperty $refreshResult 'Success' $false)) {
            $warnings.Add("Wallpaper refresh request failed: $(Get-BoostLabStateProperty $refreshResult 'Message' 'Unknown refresh error.')")
        }

        if ($ActionName -eq 'Default') {
            $fileRemoveResult = & $FileRemover $script:TargetPath
            if (-not [bool](Get-BoostLabStateProperty $fileRemoveResult 'Success' $false)) {
                $warnings.Add("Source-defined Black.jpg delete request reported a warning: $(Get-BoostLabStateProperty $fileRemoveResult 'Message' 'Unknown delete warning.')")
            }
        }

        $verification = Test-BoostLabSignoutWallpaperState `
            -ActionName $ActionName `
            -RegistryReader $RegistryReader `
            -RegistryKeyReader $RegistryKeyReader `
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
                -Message $(if ($verification.Status -eq 'Failed') { $verification.Message } else { 'Source-defined state checks completed, but the wallpaper refresh request returned a warning.' })
        }

        $failedRegistryCommands = @($registryResults | Where-Object { -not [bool](Get-BoostLabStateProperty $_ 'Success' $false) })
        if ($failedRegistryCommands.Count -gt 0) {
            $warnings.Add("$($failedRegistryCommands.Count) registry command(s) returned a non-zero exit code; verification determined the final state.")
        }

        $success = $verification.Status -ne 'Failed'
        $commandStatus = if (-not $success) {
            'Failed verification'
        }
        elseif ($warnings.Count -gt 0) {
            'Completed with warnings'
        }
        else {
            'Completed'
        }
        $message = if ($ActionName -eq 'Apply') {
            if ($success) { 'Black sign-out, lock screen, and desktop wallpaper applied.' } else { 'Wallpaper commands completed, but verification failed.' }
        }
        else {
            if ($success) { 'Source-defined wallpaper Default completed.' } else { 'Wallpaper Default commands completed, but verification failed.' }
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
            FilePathsChecked       = @($script:TargetPath)
            BackupOwnershipStatus  = 'Not used; exact Ultimate parity performs no backup or ownership tracking.'
            BackupPath             = $null
            FileDisposition        = $fileDisposition
            RegistryOperations     = @($registryResults)
            WallpaperRefreshStatus = if ([bool](Get-BoostLabStateProperty $refreshResult 'Success' $false)) { 'Requested' } else { 'Warning' }
            Warnings               = @($warnings)
            CompletedAt            = Get-Date
        }

        [pscustomobject]@{
            Success            = $success
            ToolId             = $script:ToolInfo['Id']
            ToolTitle          = $script:ToolInfo['Title']
            Action             = $ActionName
            Message            = $message
            RestartRequired    = $false
            Cancelled          = $false
            Timestamp          = Get-Date
            Data               = $data
            VerificationResult = $verification
        }
    }
    catch {
        $failedData = [pscustomobject]@{
            CommandStatus          = 'Failed'
            ExpectedWallpaperState = if ($ActionName -eq 'Apply') { 'Black wallpaper active' } else { 'Source default wallpaper restored' }
            DetectedWallpaperState = 'Unknown'
            RegistryValuesChecked  = @(
                "$($script:PersonalizationCspKey)\LockScreenImagePath"
                "$($script:PersonalizationCspKey)\LockScreenImageStatus"
                "$($script:DesktopKey)\Wallpaper"
            )
            FilePathsChecked       = @($script:TargetPath)
            BackupOwnershipStatus  = 'Not used; exact Ultimate parity performs no backup or ownership tracking.'
            BackupPath             = $null
            FileDisposition        = $fileDisposition
            RegistryOperations     = @($registryResults)
            WallpaperRefreshStatus = if ($null -eq $refreshResult) { 'Not attempted' } else { 'Failed' }
            Warnings               = @($warnings)
            CompletedAt            = Get-Date
        }

        [pscustomobject]@{
            Success            = $false
            ToolId             = $script:ToolInfo['Id']
            ToolTitle          = $script:ToolInfo['Title']
            Action             = $ActionName
            Message            = $_.Exception.Message
            RestartRequired    = $false
            Cancelled          = $false
            Timestamp          = Get-Date
            Data               = $failedData
            VerificationResult = $null
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
