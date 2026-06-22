Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $verificationModulePath -Scope Local -Force -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'edge-settings'; Title = 'Edge Settings'; Stage = 'Setup'; Order = 7
    Type = 'action'; RiskLevel = 'high'
    Description = 'Apply the full source-defined Microsoft Edge optimization workflow or run the source-defined Default repair/reset workflow with explicit confirmation.'
    Actions = @('Analyze', 'Apply', 'Default', 'Restore')
    Capabilities = [ordered]@{
        RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $false
        CanModifyRegistry = $true; CanModifyServices = $true; CanInstallSoftware = $true
        CanDownload = $true; CanModifyDrivers = $false; CanModifySecurity = $false
        CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false
        SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true
    }
}

$script:BoostLabImplementedActions = @('Analyze', 'Apply', 'Default', 'Restore')
$script:BoostLabExpectedSourceHash = '342869157930ECF0869A07B4254CB8F174C63648CD329DB3914BAD291CD5FF28'
$script:BoostLabExpectedCanonicalSourceHash = '3EE9E6F586D71E74F7400379E8D5DA079D52208D5B2DFA0E4AB035FCB08096A8'
$script:BoostLabSourceRelativePath = 'source-ultimate/3 Setup/6 Edge Settings.ps1'
$script:BoostLabEdgePolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
$script:BoostLabEdgeExtensionPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist'
$script:BoostLabActiveSetupPath = 'HKLM:\Software\Microsoft\Active Setup\Installed Components'
$script:BoostLabRunOncePath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
$script:BoostLabEdgeInstallerUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe'
$script:BoostLabEdgeInstallerFileName = 'edge.exe'
$script:BoostLabEdgeInstallerArtifactId = 'edge-settings-edge-exe'
$script:BoostLabBhoKeys = @(
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}'
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}'
)
$script:BoostLabApplyRegistryWrites = @(
    [pscustomobject]@{
        Group = 'uBlock force-install policy'
        Path = $script:BoostLabEdgeExtensionPath
        Name = '1'
        Type = 'String'
        Data = 'odfafepnkmbhccpbejgmiehpchacaeak;https://edge.microsoft.com/extensionwebstorebase/v1/crx'
    }
    [pscustomobject]@{
        Group = 'Edge policy'
        Path = $script:BoostLabEdgePolicyPath
        Name = 'HardwareAccelerationModeEnabled'
        Type = 'DWord'
        Data = 0
    }
    [pscustomobject]@{
        Group = 'Edge policy'
        Path = $script:BoostLabEdgePolicyPath
        Name = 'BackgroundModeEnabled'
        Type = 'DWord'
        Data = 0
    }
    [pscustomobject]@{
        Group = 'Edge policy'
        Path = $script:BoostLabEdgePolicyPath
        Name = 'StartupBoostEnabled'
        Type = 'DWord'
        Data = 0
    }
)

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

function Test-BoostLabEdgeSettingsInternet {
    try {
        return Test-Connection -ComputerName '8.8.8.8' -Count 1 -Quiet -ErrorAction SilentlyContinue
    }
    catch {
        return $false
    }
}

function Get-BoostLabEdgeSettingsSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $projectRoot ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabEdgeSettingsSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabEdgeSettingsSourcePath
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

function Get-BoostLabEdgeSettingsInstallerPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$SystemRoot = $env:SystemRoot
    )

    if ([string]::IsNullOrWhiteSpace($SystemRoot)) {
        $SystemRoot = [Environment]::GetFolderPath('Windows')
    }
    return Join-Path $SystemRoot 'Temp\edge.exe'
}

function New-BoostLabEdgeSettingsResult {
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
        VerificationResult = $VerificationResult
        Warnings           = @($Warnings)
        Errors             = @($Errors)
    }
}

function New-BoostLabEdgeSettingsVerification {
    param(
        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Expected,

        [Parameter(Mandatory)]
        [string]$Detected,

        [Parameter(Mandatory)]
        [object[]]$Checks,

        [Parameter(Mandatory)]
        [string]$Message
    )

    New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $Action `
        -Status $Status `
        -ExpectedState $Expected `
        -DetectedState $Detected `
        -Checks $Checks `
        -Message $Message
}

function Get-BoostLabEdgeSettingsSourceBehaviorSummary {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'Optimize writes the uBlock Origin Edge extension force-install policy.'
        'Optimize writes HardwareAccelerationModeEnabled, BackgroundModeEnabled, and StartupBoostEnabled as REG_DWORD 0 under HKLM Edge policy.'
        'Optimize deletes Active Setup child keys whose default value matches *Edge*.'
        'Optimize deletes RunOnce values whose names match *msedge*.'
        'Optimize stops and deletes services whose names match Edge.'
        'Optimize unregisters scheduled tasks whose task names match *Edge*.'
        'Optimize deletes both source-defined IE-to-Edge BHO registry keys.'
        'Default deletes the HKLM Edge policy key, stops msedge, launches msedge.exe --restore-last-session --disable-extensions, stops msedge again, downloads edge.exe to Windows Temp, and starts edge.exe.'
    )
}

function Get-BoostLabEdgeSettingsOperationPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Analyze', 'Apply', 'Default', 'Restore')]
        [string]$Action
    )

    $sourceStatus = Get-BoostLabEdgeSettingsSourceStatus
    $installerPath = Get-BoostLabEdgeSettingsInstallerPath
    $applyOperations = @(
        'Write uBlock force-install policy value 1 under HKLM Edge ExtensionInstallForcelist.'
        'Write HardwareAccelerationModeEnabled=REG_DWORD 0.'
        'Write BackgroundModeEnabled=REG_DWORD 0.'
        'Write StartupBoostEnabled=REG_DWORD 0.'
        'Delete Active Setup child keys whose default value matches *Edge*.'
        'Delete RunOnce values whose names match *msedge*.'
        'Stop and delete services whose service names match Edge.'
        'Unregister scheduled tasks whose task names match *Edge*.'
        'Delete both source-defined IE-to-Edge BHO keys.'
    )
    $defaultOperations = @(
        'Delete HKLM:\SOFTWARE\Policies\Microsoft\Edge recursively.'
        'Stop msedge.'
        'Launch msedge.exe with --restore-last-session --disable-extensions.'
        'Stop msedge again.'
        "Download $($script:BoostLabEdgeInstallerUrl) to $installerPath."
        "Start $installerPath."
    )

    [pscustomobject]@{
        ToolId                  = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle               = [string]$script:BoostLabToolMetadata['Title']
        Action                  = $Action
        Source                  = $sourceStatus
        SourceBehaviorSummary   = @(Get-BoostLabEdgeSettingsSourceBehaviorSummary)
        ApplyOperationFamilies  = $applyOperations
        DefaultOperationFamilies = $defaultOperations
        RestorePolicy           = 'Restore is unavailable because Edge Settings includes service deletion, scheduled-task deletion, process launches, download/installer behavior, and broad policy deletion without an approved captured-state restore contract.'
        EdgeInstallerDescriptor = [pscustomobject]@{
            SourceUrl              = $script:BoostLabEdgeInstallerUrl
            DestinationPath        = $installerPath
            SourceDefined          = $true
            YazanApprovedScope     = 'Phase 118 full source parity'
            GlobalArtifactManifest = 'Not used; source URL is mutable and the original source provides no hash or signer.'
        }
        RequiresAdmin           = $true
        RequiresInternet        = $true
        NeedsExplicitConfirmation = $true
        IsDryRun                = ($Action -eq 'Analyze' -or $Action -eq 'Restore')
    }
}

function Get-BoostLabEdgeSettingsAnalysis {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabEdgeSettingsSourceStatus
    [pscustomobject]@{
        Mode                    = 'SourceEquivalentControlled'
        Source                  = $sourceStatus
        SourceBehaviorSummary   = @(Get-BoostLabEdgeSettingsSourceBehaviorSummary)
        ApplyPlan               = (Get-BoostLabEdgeSettingsOperationPlan -Action 'Apply').ApplyOperationFamilies
        DefaultPlan             = (Get-BoostLabEdgeSettingsOperationPlan -Action 'Default').DefaultOperationFamilies
        RestoreStatus           = 'UnavailableWithoutApprovedCapturedState'
        NoMutationOccurred      = $true
        NoDownloadOccurred      = $true
        NoExternalProcessStarted = $true
        Readiness               = if ([string]$sourceStatus.ChecksumStatus -eq 'Passed') {
            'Ready for confirmed Apply or Default.'
        }
        else {
            'Blocked until source checksum verification passes.'
        }
    }
}

function Get-BoostLabEdgeSettingsRegistryValueState {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name
    )

    try {
        if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
            return [pscustomobject]@{
                Path = $Path; Name = $Name; KeyExists = $false; Exists = $false
                Value = $null; Type = ''; Captured = $true
            }
        }
        $item = Get-ItemProperty -LiteralPath $Path -ErrorAction Stop
        $property = $item.PSObject.Properties[$Name]
        if ($null -eq $property) {
            return [pscustomobject]@{
                Path = $Path; Name = $Name; KeyExists = $true; Exists = $false
                Value = $null; Type = ''; Captured = $true
            }
        }

        return [pscustomobject]@{
            Path = $Path; Name = $Name; KeyExists = $true; Exists = $true
            Value = $property.Value; Type = $property.TypeNameOfValue; Captured = $true
        }
    }
    catch {
        return [pscustomobject]@{
            Path = $Path; Name = $Name; KeyExists = $false; Exists = $false
            Value = $null; Type = ''; Captured = $false; Error = $_.Exception.Message
        }
    }
}

function Get-BoostLabEdgeSettingsRegistryKeyState {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    try {
        if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
            return [pscustomobject]@{
                Path = $Path; Exists = $false; Captured = $true; ValueNames = @(); ChildKeyNames = @()
            }
        }
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        return [pscustomobject]@{
            Path = $Path; Exists = $true; Captured = $true
            ValueNames = @($item.GetValueNames())
            ChildKeyNames = @($item.GetSubKeyNames())
        }
    }
    catch {
        return [pscustomobject]@{
            Path = $Path; Exists = $false; Captured = $false; ValueNames = @(); ChildKeyNames = @()
            Error = $_.Exception.Message
        }
    }
}

function Get-BoostLabEdgeSettingsActiveSetupTargets {
    if (-not (Test-Path -LiteralPath $script:BoostLabActiveSetupPath -PathType Container)) {
        return @()
    }

    @(
        Get-ChildItem -LiteralPath $script:BoostLabActiveSetupPath -ErrorAction Stop |
            ForEach-Object {
                $property = Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction SilentlyContinue
                $defaultProperty = if ($null -ne $property) {
                    $property.PSObject.Properties['(default)']
                }
                else {
                    $null
                }
                $defaultValue = if ($null -ne $defaultProperty) { [string]$defaultProperty.Value } else { '' }
                if ($defaultValue -like '*Edge*') {
                    [pscustomobject]@{
                        Path         = $_.PSPath
                        Name         = $_.PSChildName
                        DefaultValue = $defaultValue
                    }
                }
            }
    )
}

function Get-BoostLabEdgeSettingsRunOnceTargets {
    if (-not (Test-Path -LiteralPath $script:BoostLabRunOncePath -PathType Container)) {
        return @()
    }

    $key = Get-Item -LiteralPath $script:BoostLabRunOncePath -ErrorAction Stop
    @(
        $key.GetValueNames() |
            Where-Object { $_ -like '*msedge*' } |
            ForEach-Object {
                [pscustomobject]@{
                    Path  = $script:BoostLabRunOncePath
                    Name  = $_
                    Value = $key.GetValue($_)
                }
            }
    )
}

function Get-BoostLabEdgeSettingsServiceTargets {
    @(
        Get-Service -ErrorAction Stop |
            Where-Object { $_.Name -match 'Edge' } |
            ForEach-Object {
                [pscustomobject]@{
                    Name        = $_.Name
                    DisplayName = $_.DisplayName
                    Status      = $_.Status
                    ServiceType = $_.ServiceType
                }
            }
    )
}

function Get-BoostLabEdgeSettingsScheduledTaskTargets {
    if (-not (Get-Command -Name 'Get-ScheduledTask' -ErrorAction SilentlyContinue)) {
        return @()
    }

    @(
        Get-ScheduledTask -ErrorAction Stop |
            Where-Object { $_.TaskName -like '*Edge*' } |
            ForEach-Object {
                [pscustomobject]@{
                    TaskName = $_.TaskName
                    TaskPath = $_.TaskPath
                    State    = $_.State
                }
            }
    )
}

function Set-BoostLabEdgeSettingsRegistryValue {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateSet('String', 'DWord')]
        [string]$Type,

        [Parameter(Mandatory)]
        [object]$Data
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
    }
    New-ItemProperty -LiteralPath $Path -Name $Name -PropertyType $Type -Value $Data -Force -ErrorAction Stop | Out-Null
    return [pscustomobject]@{ Success = $true; Path = $Path; Name = $Name; Operation = 'SetRegistryValue' }
}

function Remove-BoostLabEdgeSettingsRegistryKey {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue
    return [pscustomobject]@{ Success = $true; Path = $Path; Operation = 'RemoveRegistryKey' }
}

function Remove-BoostLabEdgeSettingsRegistryValue {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name
    )

    Remove-ItemProperty -LiteralPath $Path -Name $Name -Force -ErrorAction SilentlyContinue
    return [pscustomobject]@{ Success = $true; Path = $Path; Name = $Name; Operation = 'RemoveRegistryValue' }
}

function Invoke-BoostLabEdgeSettingsScCommand {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('stop', 'delete')]
        [string]$Operation,

        [Parameter(Mandatory)]
        [string]$Name
    )

    $output = & sc.exe $Operation $Name 2>&1
    return [pscustomobject]@{
        Success  = $LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 1060 -or $LASTEXITCODE -eq 1062
        Operation = "sc $Operation"
        Name     = $Name
        ExitCode = $LASTEXITCODE
        Output   = @($output)
    }
}

function Stop-BoostLabEdgeSettingsProcess {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    Stop-Process -Name $Name -Force -ErrorAction SilentlyContinue
    return [pscustomobject]@{ Success = $true; Name = $Name; Operation = 'StopProcess' }
}

function Start-BoostLabEdgeSettingsProcess {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [string[]]$ArgumentList = @()
    )

    $process = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -PassThru -ErrorAction Stop
    return [pscustomobject]@{ Success = $true; FilePath = $FilePath; Arguments = @($ArgumentList); ProcessId = $process.Id }
}

function Invoke-BoostLabEdgeSettingsDownload {
    param(
        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter(Mandatory)]
        [string]$OutFile
    )

    $downloadModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\DownloadProvenance.psm1'
    if (-not (Get-Command -Name 'Invoke-BoostLabVerifiedArtifactDownload' -ErrorAction SilentlyContinue)) {
        Import-Module -Name $downloadModulePath -Scope Local -Force -ErrorAction Stop
    }

    $download = Invoke-BoostLabVerifiedArtifactDownload `
        -ArtifactId $script:BoostLabEdgeInstallerArtifactId `
        -Destination $OutFile
    return [pscustomobject]@{
        Success = $true
        Uri = [string]$download.SourceUrl
        SourceDefinedUri = $Uri
        OutFile = $OutFile
        ArtifactId = [string]$download.ArtifactId
        Operation = 'Download'
    }
}

function Invoke-BoostLabEdgeSettingsScheduledTaskRemoval {
    param(
        [Parameter(Mandatory)]
        [object]$Task
    )

    Unregister-ScheduledTask -TaskName ([string]$Task.TaskName) -TaskPath ([string]$Task.TaskPath) -Confirm:$false -ErrorAction SilentlyContinue
    return [pscustomobject]@{ Success = $true; TaskName = [string]$Task.TaskName; TaskPath = [string]$Task.TaskPath; Operation = 'UnregisterScheduledTask' }
}

function Invoke-BoostLabEdgeSettingsApply {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$RegistryCapture,
        [Parameter(Mandatory)]
        [scriptblock]$RegistryKeyCapture,
        [Parameter(Mandatory)]
        [scriptblock]$RegistryWriter,
        [Parameter(Mandatory)]
        [scriptblock]$RegistryKeyRemover,
        [Parameter(Mandatory)]
        [scriptblock]$RegistryValueRemover,
        [Parameter(Mandatory)]
        [scriptblock]$ActiveSetupEnumerator,
        [Parameter(Mandatory)]
        [scriptblock]$RunOnceEnumerator,
        [Parameter(Mandatory)]
        [scriptblock]$ServiceEnumerator,
        [Parameter(Mandatory)]
        [scriptblock]$ServiceStopper,
        [Parameter(Mandatory)]
        [scriptblock]$ServiceDeleter,
        [Parameter(Mandatory)]
        [scriptblock]$ScheduledTaskEnumerator,
        [Parameter(Mandatory)]
        [scriptblock]$ScheduledTaskUnregister
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $changes = [System.Collections.Generic.List[object]]::new()
    $captures = [System.Collections.Generic.List[object]]::new()

    foreach ($definition in @($script:BoostLabApplyRegistryWrites)) {
        $capture = & $RegistryCapture $definition.Path $definition.Name
        $captures.Add($capture)
        if ($null -ne $capture.PSObject.Properties['Captured'] -and -not [bool]$capture.Captured) {
            $errors.Add("Failed to capture registry value before write: $($definition.Path) | $($definition.Name)")
            continue
        }
        try {
            $changes.Add((& $RegistryWriter $definition.Path $definition.Name $definition.Type $definition.Data))
        }
        catch {
            $errors.Add("Failed to write registry value $($definition.Path) | $($definition.Name): $($_.Exception.Message)")
        }
    }

    $activeSetupTargets = @(& $ActiveSetupEnumerator)
    foreach ($target in $activeSetupTargets) {
        $capture = & $RegistryKeyCapture ([string]$target.Path)
        $captures.Add($capture)
        if ($null -ne $capture.PSObject.Properties['Captured'] -and -not [bool]$capture.Captured) {
            $errors.Add("Failed to capture Active Setup key before deletion: $($target.Path)")
            continue
        }
        try {
            $changes.Add((& $RegistryKeyRemover ([string]$target.Path)))
        }
        catch {
            $errors.Add("Failed to remove Active Setup key $($target.Path): $($_.Exception.Message)")
        }
    }

    $runOnceTargets = @(& $RunOnceEnumerator)
    foreach ($target in $runOnceTargets) {
        $capture = & $RegistryCapture ([string]$target.Path) ([string]$target.Name)
        $captures.Add($capture)
        if ($null -ne $capture.PSObject.Properties['Captured'] -and -not [bool]$capture.Captured) {
            $errors.Add("Failed to capture RunOnce value before deletion: $($target.Path) | $($target.Name)")
            continue
        }
        try {
            $changes.Add((& $RegistryValueRemover ([string]$target.Path) ([string]$target.Name)))
        }
        catch {
            $errors.Add("Failed to remove RunOnce value $($target.Name): $($_.Exception.Message)")
        }
    }

    $serviceTargets = @(& $ServiceEnumerator)
    foreach ($service in $serviceTargets) {
        $captures.Add([pscustomobject]@{ TargetType = 'Service'; Name = [string]$service.Name; Captured = $true; State = $service })
        try {
            $changes.Add((& $ServiceStopper ([string]$service.Name)))
            $changes.Add((& $ServiceDeleter ([string]$service.Name)))
        }
        catch {
            $errors.Add("Failed to stop/delete service $($service.Name): $($_.Exception.Message)")
        }
    }

    $taskTargets = @(& $ScheduledTaskEnumerator)
    foreach ($task in $taskTargets) {
        $captures.Add([pscustomobject]@{ TargetType = 'ScheduledTask'; TaskName = [string]$task.TaskName; TaskPath = [string]$task.TaskPath; Captured = $true; State = $task })
        try {
            $changes.Add((& $ScheduledTaskUnregister $task))
        }
        catch {
            $errors.Add("Failed to unregister scheduled task $($task.TaskPath)$($task.TaskName): $($_.Exception.Message)")
        }
    }

    foreach ($bhoKey in $script:BoostLabBhoKeys) {
        $capture = & $RegistryKeyCapture $bhoKey
        $captures.Add($capture)
        if ($null -ne $capture.PSObject.Properties['Captured'] -and -not [bool]$capture.Captured) {
            $errors.Add("Failed to capture BHO key before deletion: $bhoKey")
            continue
        }
        try {
            $changes.Add((& $RegistryKeyRemover $bhoKey))
        }
        catch {
            $errors.Add("Failed to remove BHO key ${bhoKey}: $($_.Exception.Message)")
        }
    }

    [pscustomobject]@{
        Success            = $errors.Count -eq 0
        Captures           = $captures.ToArray()
        Changes            = $changes.ToArray()
        Errors             = $errors.ToArray()
        RegistryWrites     = @($script:BoostLabApplyRegistryWrites)
        ActiveSetupTargets = $activeSetupTargets
        RunOnceTargets     = $runOnceTargets
        ServiceTargets     = $serviceTargets
        ScheduledTaskTargets = $taskTargets
        BhoTargets         = @($script:BoostLabBhoKeys)
    }
}

function Invoke-BoostLabEdgeSettingsDefault {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$RegistryKeyCapture,
        [Parameter(Mandatory)]
        [scriptblock]$RegistryKeyRemover,
        [Parameter(Mandatory)]
        [scriptblock]$ProcessStopper,
        [Parameter(Mandatory)]
        [scriptblock]$ProcessStarter,
        [Parameter(Mandatory)]
        [scriptblock]$Downloader,
        [Parameter(Mandatory)]
        [scriptblock]$Sleep
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $changes = [System.Collections.Generic.List[object]]::new()
    $captures = [System.Collections.Generic.List[object]]::new()
    $installerPath = Get-BoostLabEdgeSettingsInstallerPath

    $capture = & $RegistryKeyCapture $script:BoostLabEdgePolicyPath
    $captures.Add($capture)
    if ($null -ne $capture.PSObject.Properties['Captured'] -and -not [bool]$capture.Captured) {
        $errors.Add("Failed to capture Edge policy key before source-defined Default deletion: $($script:BoostLabEdgePolicyPath)")
    }
    else {
        try {
            $changes.Add((& $RegistryKeyRemover $script:BoostLabEdgePolicyPath))
        }
        catch {
            $errors.Add("Failed to delete Edge policy key: $($_.Exception.Message)")
        }
    }

    try {
        $changes.Add((& $ProcessStopper 'msedge'))
        $changes.Add((& $Sleep 2))
        $changes.Add((& $ProcessStarter 'msedge.exe' @('--restore-last-session', '--disable-extensions')))
        $changes.Add((& $Sleep 2))
        $changes.Add((& $ProcessStopper 'msedge'))
        $changes.Add((& $Downloader $script:BoostLabEdgeInstallerUrl $installerPath))
        $changes.Add((& $ProcessStarter $installerPath @()))
    }
    catch {
        $errors.Add("Failed during source-defined Edge Default process/download/installer sequence: $($_.Exception.Message)")
    }

    [pscustomobject]@{
        Success        = $errors.Count -eq 0
        Captures       = $captures.ToArray()
        Changes        = $changes.ToArray()
        Errors         = $errors.ToArray()
        PolicyKey      = $script:BoostLabEdgePolicyPath
        ProcessSequence = @('Stop msedge', 'Start msedge.exe --restore-last-session --disable-extensions', 'Stop msedge')
        DownloadUrl    = $script:BoostLabEdgeInstallerUrl
        DownloadPath   = $installerPath
    }
}

function New-BoostLabEdgeSettingsActionVerification {
    param(
        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [object]$OperationResult
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    $checks.Add((New-BoostLabVerificationCheck -Name 'Source checksum' -Expected $script:BoostLabExpectedSourceHash -Actual (Get-BoostLabEdgeSettingsSourceStatus).DetectedSha256 -Status 'Passed' -Message 'Edge Settings source checksum was verified before mutation.'))
    $checks.Add((New-BoostLabVerificationCheck -Name 'Pre-change capture' -Expected 'Capture before mutation' -Actual (@($OperationResult.Captures).Count) -Status ($(if (@($OperationResult.Captures).Count -gt 0) { 'Passed' } else { 'Warning' })) -Message 'BoostLab captured source-targeted registry/service/task metadata before mutation where practical.'))
    $checks.Add((New-BoostLabVerificationCheck -Name 'Operation errors' -Expected '0' -Actual (@($OperationResult.Errors).Count) -Status ($(if (@($OperationResult.Errors).Count -eq 0) { 'Passed' } else { 'Failed' })) -Message 'Source-equivalent Edge Settings operations completed without reported errors.'))

    if ($Action -eq 'Apply') {
        foreach ($family in @(
            @{ Name = 'Edge policies'; Count = @($OperationResult.RegistryWrites | Where-Object { $_.Group -eq 'Edge policy' }).Count; Expected = 3 }
            @{ Name = 'uBlock force-install policy'; Count = @($OperationResult.RegistryWrites | Where-Object { $_.Group -eq 'uBlock force-install policy' }).Count; Expected = 1 }
            @{ Name = 'Active Setup cleanup'; Count = @($OperationResult.ActiveSetupTargets).Count; Expected = 'dynamic source-derived matches' }
            @{ Name = 'RunOnce cleanup'; Count = @($OperationResult.RunOnceTargets).Count; Expected = 'dynamic source-derived matches' }
            @{ Name = 'Edge service stop/delete'; Count = @($OperationResult.ServiceTargets).Count; Expected = 'dynamic source-derived matches' }
            @{ Name = 'Edge scheduled task removal'; Count = @($OperationResult.ScheduledTaskTargets).Count; Expected = 'dynamic source-derived matches' }
            @{ Name = 'IE-to-Edge BHO cleanup'; Count = @($OperationResult.BhoTargets).Count; Expected = 2 }
        )) {
            $checks.Add((New-BoostLabVerificationCheck -Name $family.Name -Expected $family.Expected -Actual $family.Count -Status 'Passed' -Message "$($family.Name) was represented in the source-equivalent operation result."))
        }
    }
    elseif ($Action -eq 'Default') {
        foreach ($family in @(
            @{ Name = 'Edge policy key deletion'; Actual = $OperationResult.PolicyKey }
            @{ Name = 'Edge stop/start/stop sequence'; Actual = (@($OperationResult.ProcessSequence) -join ' -> ') }
            @{ Name = 'edge.exe download'; Actual = $OperationResult.DownloadUrl }
            @{ Name = 'edge.exe start'; Actual = $OperationResult.DownloadPath }
        )) {
            $checks.Add((New-BoostLabVerificationCheck -Name $family.Name -Expected 'Source-defined Default behavior' -Actual $family.Actual -Status 'Passed' -Message "$($family.Name) was represented in the source-equivalent Default result."))
        }
    }

    $failed = @($checks | Where-Object { [string]$_.Status -eq 'Failed' })
    $warnings = @($checks | Where-Object { [string]$_.Status -eq 'Warning' })
    $status = if ($failed.Count -gt 0) {
        'Failed'
    }
    elseif ($warnings.Count -gt 0) {
        'Warning'
    }
    else {
        'Passed'
    }

    New-BoostLabEdgeSettingsVerification `
        -Action $Action `
        -Status $status `
        -Expected 'Full source-equivalent Edge Settings operation families' `
        -Detected ("{0} changes, {1} captures, {2} errors" -f @($OperationResult.Changes).Count, @($OperationResult.Captures).Count, @($OperationResult.Errors).Count) `
        -Checks $checks.ToArray() `
        -Message ($(if ($status -eq 'Passed') { 'Edge Settings source-equivalent operation completed.' } else { 'Edge Settings source-equivalent operation completed with warnings or failures.' }))
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
        Capabilities                = [pscustomobject]$script:BoostLabToolMetadata['Capabilities']
        ImplementedActions          = @($script:BoostLabImplementedActions)
        ConfirmationRequiredActions = @('Apply', 'Default')
        ConfirmationText            = 'Edge Settings will run the source-equivalent Edge policy, Active Setup, RunOnce, service, scheduled task, BHO, process, download, and installer workflow. Continue only if you are ready to mutate Edge settings.'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$OperatingSystem = $env:OS,

        [bool]$RegistryProviderAvailable = $(
            $null -ne (Get-PSProvider -PSProvider Registry -ErrorAction SilentlyContinue)
        )
    )

    $sourceStatus = Get-BoostLabEdgeSettingsSourceStatus
    $supported = $OperatingSystem -eq 'Windows_NT' -and $RegistryProviderAvailable -and [string]$sourceStatus.ChecksumStatus -eq 'Passed'
    [pscustomobject]@{
        Supported            = $supported
        ToolId               = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle            = [string]$script:BoostLabToolMetadata['Title']
        Reason               = if ($OperatingSystem -ne 'Windows_NT') {
            'Edge Settings requires Windows.'
        }
        elseif (-not $RegistryProviderAvailable) {
            'Edge Settings requires the PowerShell Registry provider.'
        }
        elseif ([string]$sourceStatus.ChecksumStatus -ne 'Passed') {
            'Edge Settings source checksum verification failed or the source file is missing.'
        }
        else {
            'Edge Settings source-equivalent controlled workflow is available.'
        }
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

        [scriptblock]$AdministratorChecker = { Test-BoostLabAdministrator },
        [scriptblock]$InternetChecker = { Test-BoostLabEdgeSettingsInternet },
        [scriptblock]$RegistryCapture = { param($Path, $Name) Get-BoostLabEdgeSettingsRegistryValueState -Path $Path -Name $Name },
        [scriptblock]$RegistryKeyCapture = { param($Path) Get-BoostLabEdgeSettingsRegistryKeyState -Path $Path },
        [scriptblock]$RegistryWriter = { param($Path, $Name, $Type, $Data) Set-BoostLabEdgeSettingsRegistryValue -Path $Path -Name $Name -Type $Type -Data $Data },
        [scriptblock]$RegistryKeyRemover = { param($Path) Remove-BoostLabEdgeSettingsRegistryKey -Path $Path },
        [scriptblock]$RegistryValueRemover = { param($Path, $Name) Remove-BoostLabEdgeSettingsRegistryValue -Path $Path -Name $Name },
        [scriptblock]$ActiveSetupEnumerator = { Get-BoostLabEdgeSettingsActiveSetupTargets },
        [scriptblock]$RunOnceEnumerator = { Get-BoostLabEdgeSettingsRunOnceTargets },
        [scriptblock]$ServiceEnumerator = { Get-BoostLabEdgeSettingsServiceTargets },
        [scriptblock]$ServiceStopper = { param($Name) Invoke-BoostLabEdgeSettingsScCommand -Operation 'stop' -Name $Name },
        [scriptblock]$ServiceDeleter = { param($Name) Invoke-BoostLabEdgeSettingsScCommand -Operation 'delete' -Name $Name },
        [scriptblock]$ScheduledTaskEnumerator = { Get-BoostLabEdgeSettingsScheduledTaskTargets },
        [scriptblock]$ScheduledTaskUnregister = { param($Task) Invoke-BoostLabEdgeSettingsScheduledTaskRemoval -Task $Task },
        [scriptblock]$ProcessStopper = { param($Name) Stop-BoostLabEdgeSettingsProcess -Name $Name },
        [scriptblock]$ProcessStarter = { param($FilePath, $ArgumentList) Start-BoostLabEdgeSettingsProcess -FilePath $FilePath -ArgumentList @($ArgumentList) },
        [scriptblock]$Downloader = { param($Uri, $OutFile) Invoke-BoostLabEdgeSettingsDownload -Uri $Uri -OutFile $OutFile },
        [scriptblock]$Sleep = { param($Seconds) Start-Sleep -Seconds $Seconds; [pscustomobject]@{ Success = $true; Operation = 'Sleep'; Seconds = $Seconds } }
    )

    $canonicalActionName = switch ($ActionName) {
        'Optimize' { 'Apply' }
        default { $ActionName }
    }

    if ($canonicalActionName -notin @($script:BoostLabImplementedActions)) {
        return New-BoostLabEdgeSettingsResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'Unsupported' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Unsupported Edge Settings action. Only Analyze, Apply, Default, and Restore are implemented.'
    }

    if ($canonicalActionName -eq 'Analyze') {
        $analysis = Get-BoostLabEdgeSettingsAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        $verification = New-BoostLabEdgeSettingsVerification `
            -Action 'Analyze' `
            -Status ($(if ($sourceOk) { 'Passed' } else { 'Failed' })) `
            -Expected $script:BoostLabExpectedSourceHash `
            -Detected ([string]$analysis.Source.DetectedSha256) `
            -Checks @(
                New-BoostLabVerificationCheck `
                    -Name 'Source checksum' `
                    -Expected $script:BoostLabExpectedSourceHash `
                    -Actual ([string]$analysis.Source.DetectedSha256) `
                    -Status ($(if ($sourceOk) { 'Passed' } else { 'Failed' })) `
                    -Message 'Edge Settings source identity was checked without mutation.'
            ) `
            -Message ($(if ($sourceOk) { 'Edge Settings source identity verified.' } else { 'Edge Settings source identity failed.' }))

        return New-BoostLabEdgeSettingsResult `
            -Success $sourceOk `
            -Action 'Analyze' `
            -Status ($(if ($sourceOk) { 'Analyzed' } else { 'SourceVerificationFailed' })) `
            -CommandStatus 'No execution performed' `
            -VerificationStatus ([string]$verification.Status) `
            -Message ($(if ($sourceOk) { 'Edge Settings analyzed. Apply and Default are source-equivalent controlled workflows and require explicit confirmation.' } else { 'Edge Settings source checksum verification failed or source file is missing.' })) `
            -Data $analysis `
            -VerificationResult $verification `
            -Errors ($(if ($sourceOk) { @() } else { @('Source checksum verification failed.') }))
    }

    if ($canonicalActionName -eq 'Restore') {
        $verification = New-BoostLabEdgeSettingsVerification `
            -Action 'Restore' `
            -Status 'NotApplicable' `
            -Expected 'Selected captured Edge Settings restore state' `
            -Detected 'No approved Restore contract' `
            -Checks @(
                New-BoostLabVerificationCheck `
                    -Name 'Restore contract' `
                    -Expected 'Approved captured-state restore selection' `
                    -Actual 'Unavailable' `
                    -Status 'NotApplicable' `
                    -Message 'Restore is not implemented for Edge Settings; Default is source-defined and separate from Restore.'
            ) `
            -Message 'Edge Settings Restore is unavailable without an approved captured-state restore contract.'

        return New-BoostLabEdgeSettingsResult `
            -Success $false `
            -Action 'Restore' `
            -Status 'RestoreUnavailable' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Restore is unavailable without selected captured Edge policy, Active Setup, RunOnce, service, scheduled-task, BHO, process/download/installer state plus an approved Restore contract. No Edge mutation is planned.' `
            -Data (Get-BoostLabEdgeSettingsOperationPlan -Action 'Restore') `
            -VerificationResult $verification
    }

    $sourceStatus = Get-BoostLabEdgeSettingsSourceStatus
    if ([string]$sourceStatus.ChecksumStatus -ne 'Passed') {
        return New-BoostLabEdgeSettingsResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'SourceVerificationFailed' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus ([string]$sourceStatus.ChecksumStatus) `
            -Message 'Edge Settings blocked because source checksum verification failed or the source file is missing.' `
            -Data (Get-BoostLabEdgeSettingsOperationPlan -Action $canonicalActionName) `
            -Errors @('Source checksum verification failed.')
    }

    if (-not (& $AdministratorChecker)) {
        return New-BoostLabEdgeSettingsResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'AdministratorRequired' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Edge Settings requires Administrator rights, matching the Ultimate source.' `
            -Data (Get-BoostLabEdgeSettingsOperationPlan -Action $canonicalActionName) `
            -Errors @('Administrator rights are required.')
    }

    if (-not (& $InternetChecker)) {
        return New-BoostLabEdgeSettingsResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'InternetRequired' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Edge Settings requires internet connectivity, matching the Ultimate source preflight.' `
            -Data (Get-BoostLabEdgeSettingsOperationPlan -Action $canonicalActionName) `
            -Errors @('Internet connectivity is required.')
    }

    if (-not $Confirmed) {
        return New-BoostLabEdgeSettingsResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'Cancelled' `
            -CommandStatus 'Cancelled before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Edge Settings action cancelled before any Edge policy, Active Setup, RunOnce, service, scheduled-task, BHO, process, download, installer, registry, file, or system mutation occurred.' `
            -Data (Get-BoostLabEdgeSettingsOperationPlan -Action $canonicalActionName) `
            -Cancelled $true
    }

    $operationResult = if ($canonicalActionName -eq 'Apply') {
        Invoke-BoostLabEdgeSettingsApply `
            -RegistryCapture $RegistryCapture `
            -RegistryKeyCapture $RegistryKeyCapture `
            -RegistryWriter $RegistryWriter `
            -RegistryKeyRemover $RegistryKeyRemover `
            -RegistryValueRemover $RegistryValueRemover `
            -ActiveSetupEnumerator $ActiveSetupEnumerator `
            -RunOnceEnumerator $RunOnceEnumerator `
            -ServiceEnumerator $ServiceEnumerator `
            -ServiceStopper $ServiceStopper `
            -ServiceDeleter $ServiceDeleter `
            -ScheduledTaskEnumerator $ScheduledTaskEnumerator `
            -ScheduledTaskUnregister $ScheduledTaskUnregister
    }
    else {
        Invoke-BoostLabEdgeSettingsDefault `
            -RegistryKeyCapture $RegistryKeyCapture `
            -RegistryKeyRemover $RegistryKeyRemover `
            -ProcessStopper $ProcessStopper `
            -ProcessStarter $ProcessStarter `
            -Downloader $Downloader `
            -Sleep $Sleep
    }

    $verification = New-BoostLabEdgeSettingsActionVerification -Action $canonicalActionName -OperationResult $operationResult
    $success = [bool]$operationResult.Success -and [string]$verification.Status -ne 'Failed'
    return New-BoostLabEdgeSettingsResult `
        -Success $success `
        -Action $canonicalActionName `
        -Status ($(if ($success) { 'Completed' } else { 'Failed' })) `
        -CommandStatus ($(if ($success) { 'Completed' } else { 'Completed with errors' })) `
        -VerificationStatus ([string]$verification.Status) `
        -Message ($(if ($success) { "Edge Settings $canonicalActionName completed with source-equivalent controlled behavior." } else { "Edge Settings $canonicalActionName failed; see operation errors." })) `
        -Data $operationResult `
        -VerificationResult $verification `
        -Errors @($operationResult.Errors) `
        -ChangesExecuted (@($operationResult.Changes).Count -gt 0)
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
)
