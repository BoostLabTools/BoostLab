Set-StrictMode -Version Latest

if (-not (Get-Command -Name 'New-BoostLabVerificationCheck' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1') -Scope Local -Force -ErrorAction Stop
}
if (-not (Get-Command -Name 'Invoke-BoostLabOfficialVendorDownload' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\DownloadProvenance.psm1') -Scope Local -Force -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'nvidia-app-install'
    Title = 'Install NVIDIA App'
    Stage = 'Graphics'
    Order = 3
    Type = 'action'
    RiskLevel = 'high'
    Description = 'Download and run the source-defined official NVIDIA App installer, then perform the source-defined Start Menu shortcut cleanup after explicit confirmation.'
    Actions = @('Analyze', 'Apply')
    Capabilities = [ordered]@{
        RequiresAdmin = $true
        RequiresInternet = $true
        CanReboot = $false
        CanModifyRegistry = $false
        CanModifyServices = $false
        CanInstallSoftware = $true
        CanDownload = $true
        CanModifyDrivers = $false
        CanModifySecurity = $false
        CanDeleteFiles = $true
        UsesTrustedInstaller = $false
        UsesSafeMode = $false
        SupportsDefault = $false
        SupportsRestore = $false
        NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Analyze', 'Apply')

$script:BoostLabExpectedSourceHash = '1065D64183457D4E7B28EA78DDE41525EC8F7C4A4BCA12D29B70D991141C0C67'
$script:BoostLabExpectedCanonicalSourceHash = '268C1EFE627FADDA17892223D4C35E4845833506C22AADD3240C894ED046A6F8'
$script:BoostLabSourceRelativePath = 'source-ultimate/4 Installers/1 Installers.ps1'
$script:BoostLabNvidiaAppArtifactId = 'nvidia-app-installer'
$script:BoostLabNvidiaAppInstallerUrl = 'https://us.download.nvidia.com/nvapp/client/11.0.6.383/NVIDIA_app_v11.0.6.383.exe'
$script:BoostLabNvidiaAppInstallerArguments = '/s'

function Get-BoostLabNvidiaAppInstallProjectRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

function Get-BoostLabNvidiaAppInstallSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Join-Path (Get-BoostLabNvidiaAppInstallProjectRoot) ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabNvidiaAppInstallSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabNvidiaAppInstallSourcePath
    $sourceVerificationModulePath = Join-Path (Get-BoostLabNvidiaAppInstallProjectRoot) 'core\SourceVerification.psm1'
    if (-not (Get-Command -Name 'Test-BoostLabSourceChecksum' -ErrorAction SilentlyContinue)) {
        Import-Module -Name $sourceVerificationModulePath -Scope Local -Force -ErrorAction Stop
    }

    $verification = Test-BoostLabSourceChecksum `
        -LiteralPath $sourcePath `
        -ExpectedSha256 $script:BoostLabExpectedSourceHash `
        -ExpectedCanonicalSha256 $script:BoostLabExpectedCanonicalSourceHash

    [pscustomobject]@{
        SourcePath               = $sourcePath
        SourceRelativePath       = $script:BoostLabSourceRelativePath
        Exists                   = [bool]$verification.Exists
        ExpectedSha256           = $script:BoostLabExpectedSourceHash
        DetectedSha256           = [string]$verification.DetectedSha256
        ExpectedCanonicalSha256  = $script:BoostLabExpectedCanonicalSourceHash
        DetectedCanonicalSha256  = [string]$verification.DetectedCanonicalSha256
        ChecksumStatus           = [string]$verification.ChecksumStatus
        RawChecksumStatus        = [string]$verification.RawChecksumStatus
        CanonicalChecksumStatus  = [string]$verification.CanonicalChecksumStatus
        VerificationMode         = [string]$verification.VerificationMode
    }
}

function Get-BoostLabNvidiaAppInstallRuntimePaths {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $systemRoot = if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) { 'C:\Windows' } else { $env:SystemRoot }
    $programData = if ([string]::IsNullOrWhiteSpace($env:ProgramData)) { 'C:\ProgramData' } else { $env:ProgramData }
    $startMenuPrograms = Join-Path $programData 'Microsoft\Windows\Start Menu\Programs'
    $nvidiaStartMenuFolder = Join-Path $startMenuPrograms 'NVIDIA Corporation'

    [pscustomobject]@{
        SystemRoot                  = $systemRoot
        ProgramData                 = $programData
        InstallerPath               = Join-Path $systemRoot 'Temp\NvidiaApp.exe'
        InstallerArguments          = $script:BoostLabNvidiaAppInstallerArguments
        StartMenuPrograms           = $startMenuPrograms
        NvidiaStartMenuFolder       = $nvidiaStartMenuFolder
        NvidiaAppShortcutSource     = Join-Path $nvidiaStartMenuFolder 'NVIDIA App.lnk'
        NvidiaAppShortcutTarget     = Join-Path $startMenuPrograms 'NVIDIA App.lnk'
    }
}

function Resolve-BoostLabNvidiaAppInstallPathExpression {
    param(
        [AllowNull()]
        [string]$Value
    )

    if ($null -eq $Value) {
        return ''
    }

    $paths = Get-BoostLabNvidiaAppInstallRuntimePaths
    $resolved = [string]$Value
    $resolved = $resolved.Replace('$env:SystemRoot', [string]$paths.SystemRoot)
    $resolved = $resolved.Replace('$env:ProgramData', [string]$paths.ProgramData)
    return $resolved
}

function Get-BoostLabNvidiaAppInstallOperationPlan {
    [CmdletBinding()]
    [OutputType([object[]])]
    param()

    @(
        [pscustomobject]@{
            Order = 1
            Type = 'Download'
            Label = 'Download NVIDIA App installer'
            Required = $true
            SourceCommand = 'IWR "https://us.download.nvidia.com/nvapp/client/11.0.6.383/NVIDIA_app_v11.0.6.383.exe" -OutFile "$env:SystemRoot\Temp\NvidiaApp.exe"'
            Parameters = [ordered]@{
                ArtifactId = $script:BoostLabNvidiaAppArtifactId
                Url = $script:BoostLabNvidiaAppInstallerUrl
                DestinationPath = '$env:SystemRoot\Temp\NvidiaApp.exe'
            }
        }
        [pscustomobject]@{
            Order = 2
            Type = 'StartProcess'
            Label = 'Install NVIDIA App silently'
            Required = $true
            SourceCommand = 'Start-Process -Wait "$env:SystemRoot\Temp\NvidiaApp.exe" -ArgumentList "/s"'
            Parameters = [ordered]@{
                FilePath = '$env:SystemRoot\Temp\NvidiaApp.exe'
                Arguments = $script:BoostLabNvidiaAppInstallerArguments
                Wait = $true
            }
        }
        [pscustomobject]@{
            Order = 3
            Type = 'MoveItem'
            Label = 'Move NVIDIA App Start Menu shortcut'
            Required = $false
            SourceCommand = 'Move-Item -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\NVIDIA Corporation\NVIDIA App.lnk" -Destination "$env:ProgramData\Microsoft\Windows\Start Menu\Programs" -Force -ErrorAction SilentlyContinue | Out-Null'
            Parameters = [ordered]@{
                Path = '$env:ProgramData\Microsoft\Windows\Start Menu\Programs\NVIDIA Corporation\NVIDIA App.lnk'
                Destination = '$env:ProgramData\Microsoft\Windows\Start Menu\Programs'
                IgnoreMissing = $true
            }
        }
        [pscustomobject]@{
            Order = 4
            Type = 'RemoveItem'
            Label = 'Remove NVIDIA Corporation Start Menu folder'
            Required = $false
            SourceCommand = 'Remove-Item "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\NVIDIA Corporation" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null'
            Parameters = [ordered]@{
                Path = '$env:ProgramData\Microsoft\Windows\Start Menu\Programs\NVIDIA Corporation'
                Recurse = $true
                IgnoreMissing = $true
            }
        }
    )
}

function Get-BoostLabNvidiaAppInstallArtifactSources {
    [CmdletBinding()]
    [OutputType([object[]])]
    param()

    @(
        [pscustomobject]@{
            Id = $script:BoostLabNvidiaAppArtifactId
            DisplayName = 'NVIDIA App installer'
            FileName = 'NvidiaApp.exe'
            SourceFileName = 'NVIDIA_app_v11.0.6.383.exe'
            SourceUrl = $script:BoostLabNvidiaAppInstallerUrl
            Classification = 'OfficialVendorDirect'
            MirrorStatus = 'NotRequiredOfficial'
            OfficialSourceKind = 'StaticOfficialInstaller'
            RuntimeUrlUnchanged = $true
            BinaryIncluded = $false
            DownloadExecutionApproved = $true
            InstallerExecutionApproved = $true
        }
    )
}

function Get-BoostLabNvidiaAppInstallSourceBehaviorSummary {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'Downloads NVIDIA_app_v11.0.6.383.exe from the source-defined NVIDIA URL to %SystemRoot%\Temp\NvidiaApp.exe.'
        'Runs %SystemRoot%\Temp\NvidiaApp.exe with /s and waits for completion.'
        'Moves the NVIDIA App Start Menu shortcut up one level if it exists.'
        'Removes the NVIDIA Corporation Start Menu folder if it exists.'
        'Returns to the Installers menu in the original console script; BoostLab represents this as one confirmed Graphics Apply action.'
    )
}

function New-BoostLabNvidiaAppInstallOperationResult {
    param(
        [Parameter(Mandatory)]
        [object]$Operation,

        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Message,

        [AllowNull()]
        [object]$Data = $null
    )

    [pscustomobject]@{
        Success = $Success
        Order = [int]$Operation.Order
        Type = [string]$Operation.Type
        Label = [string]$Operation.Label
        Required = [bool]$Operation.Required
        Status = $Status
        Message = $Message
        SourceCommand = [string]$Operation.SourceCommand
        Data = $Data
        Timestamp = Get-Date
    }
}

function Invoke-BoostLabNvidiaAppInstallOperation {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Operation,

        [AllowNull()]
        [scriptblock]$Downloader,

        [AllowNull()]
        [scriptblock]$SignatureInspector
    )

    $parameters = $Operation.Parameters
    switch ([string]$Operation.Type) {
        'Download' {
            $destination = Resolve-BoostLabNvidiaAppInstallPathExpression ([string]$parameters['DestinationPath'])
            $parent = Split-Path -Parent $destination
            if (-not [string]::IsNullOrWhiteSpace($parent)) {
                New-Item -Path $parent -ItemType Directory -Force -ErrorAction Stop | Out-Null
            }

            $download = Invoke-BoostLabOfficialVendorDownload `
                -ArtifactId ([string]$parameters['ArtifactId']) `
                -SourceUrl ([string]$parameters['Url']) `
                -Destination $destination `
                -Downloader $Downloader `
                -SignatureInspector $SignatureInspector

            return New-BoostLabNvidiaAppInstallOperationResult `
                -Operation $Operation `
                -Success $true `
                -Status 'Completed' `
                -Message 'Downloaded and verified the official NVIDIA App installer to the source-defined local path.' `
                -Data $download
        }
        'StartProcess' {
            $filePath = Resolve-BoostLabNvidiaAppInstallPathExpression ([string]$parameters['FilePath'])
            $arguments = Resolve-BoostLabNvidiaAppInstallPathExpression ([string]$parameters['Arguments'])
            $startParameters = @{
                FilePath = $filePath
                ErrorAction = 'Stop'
            }
            if (-not [string]::IsNullOrWhiteSpace($arguments)) {
                $startParameters['ArgumentList'] = $arguments
            }
            if ([bool]$parameters['Wait']) {
                $startParameters['Wait'] = $true
            }
            Start-Process @startParameters

            return New-BoostLabNvidiaAppInstallOperationResult `
                -Operation $Operation `
                -Success $true `
                -Status 'Completed' `
                -Message 'Started the source-defined NVIDIA App installer command.'
        }
        'MoveItem' {
            $path = Resolve-BoostLabNvidiaAppInstallPathExpression ([string]$parameters['Path'])
            $destination = Resolve-BoostLabNvidiaAppInstallPathExpression ([string]$parameters['Destination'])
            if ([bool]$parameters['IgnoreMissing'] -and -not (Test-Path -LiteralPath $path)) {
                return New-BoostLabNvidiaAppInstallOperationResult `
                    -Operation $Operation `
                    -Success $true `
                    -Status 'SkippedMissing' `
                    -Message 'Source-equivalent shortcut cleanup skipped because the source shortcut was not present.'
            }
            Move-Item -Path $path -Destination $destination -Force -ErrorAction Stop | Out-Null

            return New-BoostLabNvidiaAppInstallOperationResult `
                -Operation $Operation `
                -Success $true `
                -Status 'Completed' `
                -Message 'Moved the NVIDIA App Start Menu shortcut according to the source command.'
        }
        'RemoveItem' {
            $path = Resolve-BoostLabNvidiaAppInstallPathExpression ([string]$parameters['Path'])
            if ([bool]$parameters['IgnoreMissing'] -and -not (Test-Path -LiteralPath $path)) {
                return New-BoostLabNvidiaAppInstallOperationResult `
                    -Operation $Operation `
                    -Success $true `
                    -Status 'SkippedMissing' `
                    -Message 'Source-equivalent folder cleanup skipped because the NVIDIA Corporation Start Menu folder was not present.'
            }
            Remove-Item -Path $path -Recurse:([bool]$parameters['Recurse']) -Force -ErrorAction Stop | Out-Null

            return New-BoostLabNvidiaAppInstallOperationResult `
                -Operation $Operation `
                -Success $true `
                -Status 'Completed' `
                -Message 'Removed the NVIDIA Corporation Start Menu folder according to the source command.'
        }
        default {
            throw "Unsupported NVIDIA App install operation type: $($Operation.Type)"
        }
    }
}

function Invoke-BoostLabNvidiaAppInstallOperationPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object[]]$Plan,

        [AllowNull()]
        [scriptblock]$OperationExecutor,

        [AllowNull()]
        [scriptblock]$Downloader,

        [AllowNull()]
        [scriptblock]$SignatureInspector
    )

    $results = [System.Collections.Generic.List[object]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    $changesStarted = $false

    foreach ($operation in @($Plan | Sort-Object { [int]$_.Order })) {
        try {
            if ($null -ne $OperationExecutor) {
                $result = & $OperationExecutor $operation
            }
            else {
                $result = Invoke-BoostLabNvidiaAppInstallOperation `
                    -Operation $operation `
                    -Downloader $Downloader `
                    -SignatureInspector $SignatureInspector
            }
        }
        catch {
            $result = New-BoostLabNvidiaAppInstallOperationResult `
                -Operation $operation `
                -Success $false `
                -Status 'Failed' `
                -Message $_.Exception.Message
        }

        if ($null -eq $result) {
            $result = New-BoostLabNvidiaAppInstallOperationResult `
                -Operation $operation `
                -Success $false `
                -Status 'Failed' `
                -Message 'The operation returned no result.'
        }

        $results.Add($result)
        if ([string]$operation.Type -in @('Download', 'StartProcess', 'MoveItem', 'RemoveItem')) {
            $changesStarted = $true
        }

        if (-not [bool]$result.Success) {
            $message = '{0}: {1}' -f [string]$operation.Label, [string]$result.Message
            if ([bool]$operation.Required) {
                $errors.Add($message)
                break
            }
            $warnings.Add($message)
        }
        elseif ([string]$result.Status -eq 'SkippedMissing') {
            $warnings.Add('{0}: {1}' -f [string]$operation.Label, [string]$result.Message)
        }
    }

    [pscustomobject]@{
        Success = $errors.Count -eq 0
        Operations = $results.ToArray()
        Warnings = $warnings.ToArray()
        Errors = $errors.ToArray()
        FailedRequiredOperations = @($results.ToArray() | Where-Object { -not [bool]$_.Success -and [bool]$_.Required })
        ChangesStarted = $changesStarted
        Timestamp = Get-Date
    }
}

function New-BoostLabNvidiaAppInstallVerificationResult {
    param(
        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [object]$SourceStatus,

        [AllowNull()]
        [object]$Execution = $null
    )

    $sourceOk = [string]$SourceStatus.ChecksumStatus -eq 'Passed'
    $checks = [System.Collections.Generic.List[object]]::new()
    $checks.Add((New-BoostLabVerificationCheck `
        -Name 'Source checksum' `
        -Expected $script:BoostLabExpectedSourceHash `
        -Actual ([string]$SourceStatus.DetectedSha256) `
        -Status $(if ($sourceOk) { 'Passed' } else { 'Failed' }) `
        -Message 'NVIDIA App install uses the approved Installers source script option.'))

    $checks.Add((New-BoostLabVerificationCheck `
        -Name 'Source-defined URL' `
        -Expected $script:BoostLabNvidiaAppInstallerUrl `
        -Actual $script:BoostLabNvidiaAppInstallerUrl `
        -Status 'Passed' `
        -Message 'The Graphics installer flow uses the exact Ultimate Installers NVIDIA App URL.'))

    $checks.Add((New-BoostLabVerificationCheck `
        -Name 'Source-defined installer arguments' `
        -Expected '/s' `
        -Actual $script:BoostLabNvidiaAppInstallerArguments `
        -Status 'Passed' `
        -Message 'The installer is launched with the exact source-defined silent argument.'))

    if ($null -ne $Execution) {
        $checks.Add((New-BoostLabVerificationCheck `
            -Name 'Operation execution' `
            -Expected 'All required operations completed' `
            -Actual ([string]$Execution.Success) `
            -Status $(if ([bool]$Execution.Success) { 'Passed' } else { 'Failed' }) `
            -Message $(if ([bool]$Execution.Success) { 'All required NVIDIA App install operations completed or source-silenced cleanup was skipped.' } else { 'One or more required NVIDIA App install operations failed.' })))
    }

    $status = if (-not $sourceOk -or ($null -ne $Execution -and -not [bool]$Execution.Success)) {
        'Failed'
    }
    elseif ($null -ne $Execution -and @($Execution.Warnings).Count -gt 0) {
        'Warning'
    }
    else {
        'Passed'
    }

    New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $Action `
        -Status $status `
        -ExpectedState 'Source-defined NVIDIA App installer flow represented and gated.' `
        -DetectedState ([pscustomobject]@{ Source = $SourceStatus; Execution = $Execution }) `
        -Checks $checks.ToArray() `
        -Message $(if ($status -eq 'Passed') { 'NVIDIA App install verification passed.' } elseif ($status -eq 'Warning') { 'NVIDIA App install completed with source-silenced cleanup warnings.' } else { 'NVIDIA App install verification failed.' })
}

function New-BoostLabNvidiaAppInstallResult {
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

function Get-BoostLabNvidiaAppInstallAnalysis {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        Mode = 'SourceEquivalentNvidiaAppInstaller'
        Source = Get-BoostLabNvidiaAppInstallSourceStatus
        SourceBehaviorSummary = @(Get-BoostLabNvidiaAppInstallSourceBehaviorSummary)
        ArtifactSources = @(Get-BoostLabNvidiaAppInstallArtifactSources)
        OperationPlan = @(Get-BoostLabNvidiaAppInstallOperationPlan)
        NoMutationOccurred = $true
        NoDownloadOccurred = $true
        NoInstallerExecutionOccurred = $true
        NoExternalProcessStarted = $true
        NoRegistryMutationOccurred = $true
        NoServiceMutationOccurred = $true
        NoDriverMutationOccurred = $true
        NoShortcutMutationOccurred = $true
        NoFileCleanupOccurred = $true
        NoRebootOccurred = $true
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
        Capabilities = $script:BoostLabToolMetadata['Capabilities']
        ImplementedActions = @($script:BoostLabImplementedActions)
        ConfirmationRequiredActions = @('Apply')
        ConfirmationText = 'BoostLab will download the source-defined official NVIDIA App installer to Windows Temp, run it with /s, and perform the source-defined Start Menu shortcut cleanup. Continue?'
        SourceUrl = $script:BoostLabNvidiaAppInstallerUrl
        ArtifactId = $script:BoostLabNvidiaAppArtifactId
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabNvidiaAppInstallSourceStatus
    [pscustomobject]@{
        Supported = [string]$sourceStatus.ChecksumStatus -eq 'Passed'
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason = if ([string]$sourceStatus.ChecksumStatus -eq 'Passed') {
            'Source-defined NVIDIA App installer flow is available after explicit confirmation.'
        }
        else {
            'NVIDIA App installer source identity is missing or checksum verification failed.'
        }
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
        Status = 'SourceEquivalentNvidiaAppInstaller'
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

        [AllowNull()]
        [scriptblock]$OperationExecutor = $null,

        [AllowNull()]
        [scriptblock]$Downloader = $null,

        [AllowNull()]
        [scriptblock]$SignatureInspector = $null
    )

    $canonicalActionName = switch ($ActionName) {
        'Install NVIDIA App' { 'Apply' }
        'Apply Source Workflow' { 'Apply' }
        default { $ActionName }
    }

    if ($canonicalActionName -notin @($script:BoostLabImplementedActions)) {
        return New-BoostLabNvidiaAppInstallResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'Unsupported' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Unsupported NVIDIA App action. Only Analyze and Apply are exposed.'
    }

    if ($canonicalActionName -eq 'Analyze') {
        $analysis = Get-BoostLabNvidiaAppInstallAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        $verification = New-BoostLabNvidiaAppInstallVerificationResult -Action 'Analyze' -SourceStatus $analysis.Source
        return New-BoostLabNvidiaAppInstallResult `
            -Success $sourceOk `
            -Action 'Analyze' `
            -Status $(if ($sourceOk) { 'Analyzed' } else { 'SourceIdentityFailed' }) `
            -CommandStatus 'No execution performed' `
            -VerificationStatus $(if ($sourceOk) { 'Passed' } else { 'Failed' }) `
            -Message $(if ($sourceOk) { 'NVIDIA App source identity and source-defined installer flow were analyzed. No download, installer launch, browser launch, file cleanup, registry, service, driver, package, security, or reboot operation occurred.' } else { 'NVIDIA App installer source identity could not be verified. No operation was executed.' }) `
            -Data $analysis `
            -VerificationResult $verification `
            -Errors $(if ($sourceOk) { @() } else { @('NVIDIA App installer source checksum did not match the expected value or the source file is missing.') })
    }

    if (-not $Confirmed) {
        return New-BoostLabNvidiaAppInstallResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'Cancelled' `
            -CommandStatus 'Cancelled before execution' `
            -VerificationStatus 'NotRun' `
            -Message 'NVIDIA App install requires explicit Action Plan confirmation before any download, installer launch, Start Menu shortcut cleanup, file mutation, or software installation can start.' `
            -Cancelled $true
    }

    $sourceStatus = Get-BoostLabNvidiaAppInstallSourceStatus
    if ([string]$sourceStatus.ChecksumStatus -ne 'Passed') {
        $verification = New-BoostLabNvidiaAppInstallVerificationResult -Action 'Apply' -SourceStatus $sourceStatus
        return New-BoostLabNvidiaAppInstallResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'SourceIdentityFailed' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Failed' `
            -Message 'NVIDIA App install blocked because the Installers source checksum verification failed or the source file is missing. No operation was executed.' `
            -Data ([pscustomobject]@{ Source = $sourceStatus; ArtifactSources = @(Get-BoostLabNvidiaAppInstallArtifactSources) }) `
            -VerificationResult $verification `
            -Errors @('NVIDIA App installer source checksum did not match the expected value or the source file is missing.')
    }

    $plan = @(Get-BoostLabNvidiaAppInstallOperationPlan)
    $execution = Invoke-BoostLabNvidiaAppInstallOperationPlan `
        -Plan $plan `
        -OperationExecutor $OperationExecutor `
        -Downloader $Downloader `
        -SignatureInspector $SignatureInspector

    $verificationResult = New-BoostLabNvidiaAppInstallVerificationResult -Action 'Apply' -SourceStatus $sourceStatus -Execution $execution
    $warnings = @($execution.Warnings)
    $errors = @($execution.Errors)
    $data = [pscustomobject]@{
        Source = $sourceStatus
        Plan = $plan
        ArtifactSources = @(Get-BoostLabNvidiaAppInstallArtifactSources)
        Operations = @($execution.Operations)
        FailedRequiredOperations = @($execution.FailedRequiredOperations)
        RuntimeUrlUnchanged = $true
        OfficialVendorDirect = $true
        NoBrowserLaunch = $true
        NoDriverOperation = $true
        NoRebootRequested = $true
    }

    if ([bool]$execution.Success) {
        $hasWarnings = @($warnings).Count -gt 0
        return New-BoostLabNvidiaAppInstallResult `
            -Success $true `
            -Action 'Apply' `
            -Status $(if ($hasWarnings) { 'CompletedWithWarnings' } else { 'Completed' }) `
            -CommandStatus $(if ($hasWarnings) { 'Completed with warnings' } else { 'Completed' }) `
            -VerificationStatus $(if ($hasWarnings) { 'Warning' } else { 'Passed' }) `
            -Message 'NVIDIA App source-defined installer flow completed: official installer download, /s installer launch, and source-defined Start Menu shortcut cleanup were requested in order. No driver operation or reboot was requested by the source.' `
            -Data $data `
            -VerificationResult $verificationResult `
            -Warnings $warnings `
            -ChangesExecuted:$execution.ChangesStarted
    }

    return New-BoostLabNvidiaAppInstallResult `
        -Success $false `
        -Action 'Apply' `
        -Status 'Failed' `
        -CommandStatus 'Completed with errors' `
        -VerificationStatus 'Failed' `
        -Message "NVIDIA App source-defined installer flow failed closed. Failed operation(s): $($errors -join '; ')" `
        -Data $data `
        -VerificationResult $verificationResult `
        -Warnings $warnings `
        -Errors $errors `
        -ChangesExecuted:$execution.ChangesStarted
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    New-BoostLabNvidiaAppInstallResult `
        -Success $false `
        -Action 'Default' `
        -Status 'DefaultUnavailable' `
        -CommandStatus 'Unavailable' `
        -VerificationStatus 'NotApplicable' `
        -Message 'Default is unavailable for NVIDIA App because the source defines only an install workflow. Default is not Restore.'
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo',
    'Test-BoostLabToolCompatibility',
    'Get-BoostLabToolState',
    'Invoke-BoostLabToolAction',
    'Restore-BoostLabToolDefault',
    'Get-BoostLabNvidiaAppInstallSourceStatus',
    'Get-BoostLabNvidiaAppInstallAnalysis',
    'Get-BoostLabNvidiaAppInstallOperationPlan',
    'Invoke-BoostLabNvidiaAppInstallOperationPlan'
)
