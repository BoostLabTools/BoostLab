Set-StrictMode -Version Latest

if (-not (Get-Command -Name 'New-BoostLabVerificationCheck' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1') -Scope Local -Force -ErrorAction Stop
}

function Invoke-BoostLabVisualCppVerifiedArtifactDownload {
    param(
        [Parameter(Mandatory)]
        [string]$ArtifactId,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    $downloadModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\DownloadProvenance.psm1'
    if (-not (Get-Command -Name 'Invoke-BoostLabVerifiedArtifactDownload' -ErrorAction SilentlyContinue)) {
        Import-Module -Name $downloadModulePath -Scope Local -Force -ErrorAction Stop
    }

    Invoke-BoostLabVerifiedArtifactDownload -ArtifactId $ArtifactId -Destination $Destination
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'visual-cpp'
    Title = 'Visual C++'
    Stage = 'Graphics'
    Order = 9
    Type = 'action'
    RiskLevel = 'high'
    Description = 'Source-equivalent controlled runtime. Download all twelve source-defined Visual C++ redistributable installers and run them sequentially with exact source arguments after explicit confirmation.'
    Actions = @('Analyze', 'Apply')
    Capabilities = [ordered]@{
        RequiresAdmin              = $true
        RequiresInternet           = $true
        CanReboot                  = $false
        CanModifyRegistry          = $false
        CanModifyServices          = $false
        CanInstallSoftware         = $true
        CanDownload                = $true
        CanModifyDrivers           = $false
        CanModifySecurity          = $false
        CanDeleteFiles             = $false
        UsesTrustedInstaller       = $false
        UsesSafeMode               = $false
        SupportsDefault            = $false
        SupportsRestore            = $false
        NeedsExplicitConfirmation  = $true
    }
}

$script:BoostLabImplementedActions = @('Analyze', 'Apply')
$script:BoostLabExpectedSourceHash = '7ACB1F25ECFEEAD83FA389E2D0C1FEEF12232C4E9A740CB5DE64A326FFD38C09'
$script:BoostLabSourceRelativePath = 'source-ultimate/5 Graphics/3 C++.ps1'
$script:BoostLabArtifactMirrorStatus = 'NeedsBoostLabMirror'
$script:BoostLabArtifactSourceClassification = 'UltimateAuthorHostedArtifact'
$script:BoostLabUltimateFilesBaseUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main'

$script:BoostLabVisualCppDownloadFiles = @(
    'vcredist2005_x64.exe',
    'vcredist2005_x86.exe',
    'vcredist2008_x64.exe',
    'vcredist2008_x86.exe',
    'vcredist2010_x64.exe',
    'vcredist2010_x86.exe',
    'vcredist2012_x64.exe',
    'vcredist2012_x86.exe',
    'vcredist2013_x64.exe',
    'vcredist2013_x86.exe',
    'vcredist2015_2017_2019_2022_x64.exe',
    'vcredist2015_2017_2019_2022_x86.exe'
)

function Get-BoostLabVisualCppArtifactId {
    param(
        [Parameter(Mandatory)]
        [string]$FileName
    )

    'visual-cpp-{0}' -f (($FileName -replace '\.exe$', '') -replace '_', '-')
}

$script:BoostLabVisualCppInstallerPlan = @(
    @{ FileName = 'vcredist2005_x86.exe'; Arguments = '/q' },
    @{ FileName = 'vcredist2005_x64.exe'; Arguments = '/q' },
    @{ FileName = 'vcredist2008_x86.exe'; Arguments = '/qb' },
    @{ FileName = 'vcredist2008_x64.exe'; Arguments = '/qb' },
    @{ FileName = 'vcredist2010_x86.exe'; Arguments = '/passive /norestart' },
    @{ FileName = 'vcredist2010_x64.exe'; Arguments = '/passive /norestart' },
    @{ FileName = 'vcredist2012_x86.exe'; Arguments = '/passive /norestart' },
    @{ FileName = 'vcredist2012_x64.exe'; Arguments = '/passive /norestart' },
    @{ FileName = 'vcredist2013_x86.exe'; Arguments = '/passive /norestart' },
    @{ FileName = 'vcredist2013_x64.exe'; Arguments = '/passive /norestart' },
    @{ FileName = 'vcredist2015_2017_2019_2022_x86.exe'; Arguments = '/passive /norestart' },
    @{ FileName = 'vcredist2015_2017_2019_2022_x64.exe'; Arguments = '/passive /norestart' }
)

function Get-BoostLabVisualCppProjectRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

function Get-BoostLabVisualCppSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    Join-Path (Get-BoostLabVisualCppProjectRoot) ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabVisualCppSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabVisualCppSourcePath
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

function Get-BoostLabVisualCppRuntimePaths {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    @{
        WindowsTemp = Join-Path $env:SystemRoot 'Temp'
    }
}

function Get-BoostLabVisualCppPackageDefinitions {
    [CmdletBinding()]
    [OutputType([object[]])]
    param()

    foreach ($fileName in $script:BoostLabVisualCppDownloadFiles) {
        $installer = @($script:BoostLabVisualCppInstallerPlan | Where-Object { [string]$_['FileName'] -eq $fileName }) | Select-Object -First 1
        [pscustomobject]@{
            FileName = $fileName
            Url = ('{0}/{1}' -f $script:BoostLabUltimateFilesBaseUrl, $fileName)
            TempPath = ('%SystemRoot%\Temp\{0}' -f $fileName)
            InstallArguments = if ($null -ne $installer) { [string]$installer['Arguments'] } else { '' }
            SourceClassification = $script:BoostLabArtifactSourceClassification
            MirrorStatus = $script:BoostLabArtifactMirrorStatus
        }
    }
}

function Get-BoostLabVisualCppArtifactSources {
    [CmdletBinding()]
    [OutputType([object[]])]
    param()

    foreach ($package in Get-BoostLabVisualCppPackageDefinitions) {
        $artifactIdSuffix = ((([string]$package.FileName) -replace '\.exe$', '') -replace '_', '-').ToLowerInvariant()
        [pscustomobject]@{
            Id = "visual-cpp-$artifactIdSuffix"
            FileName = [string]$package.FileName
            Url = [string]$package.Url
            SourceClassification = [string]$package.SourceClassification
            MirrorStatus = [string]$package.MirrorStatus
            ExpectedSha256 = $null
            IntendedBoostLabMirrorUrl = $null
            RuntimeUrlUnchanged = $true
        }
    }
}

function Get-BoostLabVisualCppSourceBehaviorSummary {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'Requires Administrator rights.'
        'Requires internet connectivity using Test-Connection 8.8.8.8.'
        'Sets progress preference to silentlycontinue.'
        'Prints Downloading: C++... before downloads.'
        'Downloads twelve source-defined Visual C++ redistributable installers from the Ultimate author mirror to %SystemRoot%\Temp.'
        'Prints Installing: C++... before installer execution.'
        'Runs all twelve installers sequentially with Start-Process -Wait in source-defined order.'
        'Uses /q for Visual C++ 2005, /qb for Visual C++ 2008, and /passive /norestart for Visual C++ 2010 through 2015/2017/2019/2022.'
        'Defines no standalone Open, Default, Restore, cleanup, or reboot behavior.'
    )
}

function New-BoostLabVisualCppOperation {
    param(
        [Parameter(Mandatory)]
        [int]$Order,

        [Parameter(Mandatory)]
        [string]$Type,

        [Parameter(Mandatory)]
        [string]$Label,

        [hashtable]$Parameters = @{},

        [bool]$Required = $true
    )

    [pscustomobject]@{
        Order      = $Order
        Type       = $Type
        Label      = $Label
        Parameters = $Parameters
        Required   = $Required
    }
}

function Get-BoostLabVisualCppOperationPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $paths = Get-BoostLabVisualCppRuntimePaths
    $operations = New-Object System.Collections.Generic.List[object]
    $order = 1

    $operations.Add((New-BoostLabVisualCppOperation -Order ($order++) -Type 'RequireAdministrator' -Label 'Verify Administrator rights')) | Out-Null
    $operations.Add((New-BoostLabVisualCppOperation -Order ($order++) -Type 'RequireInternet' -Label 'Verify internet connectivity to 8.8.8.8')) | Out-Null
    $operations.Add((New-BoostLabVisualCppOperation -Order ($order++) -Type 'SetProgressPreference' -Label 'Set progress preference to silentlycontinue' -Parameters @{ Value = 'silentlycontinue' })) | Out-Null

    foreach ($fileName in $script:BoostLabVisualCppDownloadFiles) {
        $operations.Add(
            (New-BoostLabVisualCppOperation `
                -Order ($order++) `
                -Type 'DownloadFile' `
                -Label ('Download {0}' -f $fileName) `
                -Parameters @{
                    Url = ('{0}/{1}' -f $script:BoostLabUltimateFilesBaseUrl, $fileName)
                    OutFile = Join-Path ([string]$paths.WindowsTemp) $fileName
                    ExpectedFileName = $fileName
                    ArtifactId = Get-BoostLabVisualCppArtifactId -FileName $fileName
                    SourceTempPath = ('%SystemRoot%\Temp\{0}' -f $fileName)
                    MirrorStatus = $script:BoostLabArtifactMirrorStatus
                    SourceClassification = $script:BoostLabArtifactSourceClassification
                })
        ) | Out-Null
    }

    foreach ($installer in $script:BoostLabVisualCppInstallerPlan) {
        $fileName = [string]$installer['FileName']
        $arguments = [string]$installer['Arguments']
        $operations.Add(
            (New-BoostLabVisualCppOperation `
                -Order ($order++) `
                -Type 'StartInstallerWait' `
                -Label ('Run {0} {1}' -f $fileName, $arguments) `
                -Parameters @{
                    FilePath = Join-Path ([string]$paths.WindowsTemp) $fileName
                    SourcePath = ('%SystemRoot%\Temp\{0}' -f $fileName)
                    Arguments = $arguments
                    Wait = $true
                })
        ) | Out-Null
    }

    [pscustomobject]@{
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Mode = 'SourceEquivalentVisualCppInstall'
        DownloadCount = @($script:BoostLabVisualCppDownloadFiles).Count
        InstallerCount = @($script:BoostLabVisualCppInstallerPlan).Count
        Operations = $operations.ToArray()
        NoRebootRequested = $true
        RuntimeUrlUnchanged = $false
        RuntimeSourceSelection = 'VerifiedBoostLabMirror'
        BoostLabMirrorRequired = $true
    }
}

function New-BoostLabVisualCppOperationResult {
    param(
        [Parameter(Mandatory)]
        [object]$Operation,

        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Message,

        [string]$Status = '',

        [AllowNull()]
        [object]$Data = $null
    )

    [pscustomobject]@{
        Success = $Success
        Status = if ([string]::IsNullOrWhiteSpace($Status)) { if ($Success) { 'Completed' } else { 'Failed' } } else { $Status }
        Order = [int]$Operation.Order
        Type = [string]$Operation.Type
        Label = [string]$Operation.Label
        Required = [bool]$Operation.Required
        Message = $Message
        Data = $Data
        Timestamp = Get-Date
    }
}

function Test-BoostLabVisualCppAdministrator {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-BoostLabVisualCppInternet {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    Test-Connection -ComputerName '8.8.8.8' -Count 1 -Quiet -ErrorAction SilentlyContinue
}

function Invoke-BoostLabVisualCppRealOperation {
    param(
        [Parameter(Mandatory)]
        [object]$Operation
    )

    $parameters = if ($Operation.Parameters -is [System.Collections.IDictionary]) {
        $Operation.Parameters
    }
    else {
        @{}
    }

    try {
        switch ([string]$Operation.Type) {
            'RequireAdministrator' {
                if (Test-BoostLabVisualCppAdministrator) {
                    return New-BoostLabVisualCppOperationResult -Operation $Operation -Success $true -Message 'Administrator rights verified.'
                }
                return New-BoostLabVisualCppOperationResult -Operation $Operation -Success $false -Message 'Administrator rights are required before Visual C++ installation can run.'
            }
            'RequireInternet' {
                if (Test-BoostLabVisualCppInternet) {
                    return New-BoostLabVisualCppOperationResult -Operation $Operation -Success $true -Message 'Internet connectivity to 8.8.8.8 verified.'
                }
                return New-BoostLabVisualCppOperationResult -Operation $Operation -Success $false -Message 'Internet connectivity to 8.8.8.8 is required before Visual C++ downloads can run.'
            }
            'SetProgressPreference' {
                $global:ProgressPreference = [string]$parameters['Value']
                return New-BoostLabVisualCppOperationResult -Operation $Operation -Success $true -Message ('ProgressPreference set to {0}.' -f [string]$parameters['Value'])
            }
            'DownloadFile' {
                $download = Invoke-BoostLabVisualCppVerifiedArtifactDownload `
                    -ArtifactId ([string]$parameters['ArtifactId']) `
                    -Destination ([string]$parameters['OutFile'])
                if (-not (Test-Path -LiteralPath ([string]$parameters['OutFile']) -PathType Leaf)) {
                    return New-BoostLabVisualCppOperationResult -Operation $Operation -Success $false -Message ('Download did not create expected file: {0}' -f [string]$parameters['OutFile'])
                }
                return New-BoostLabVisualCppOperationResult -Operation $Operation -Success $true -Message ('Downloaded {0} from verified BoostLab mirror to {1}.' -f [string]$parameters['ExpectedFileName'], [string]$parameters['SourceTempPath']) -Data ([pscustomobject]@{ Url = [string]$download.SourceUrl; SourceDefinedUrl = [string]$parameters['Url']; ArtifactId = [string]$download.ArtifactId; OutFile = [string]$parameters['OutFile'] })
            }
            'StartInstallerWait' {
                $filePath = [string]$parameters['FilePath']
                if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
                    return New-BoostLabVisualCppOperationResult -Operation $Operation -Success $false -Message ('Installer file is missing before launch: {0}' -f [string]$parameters['SourcePath'])
                }
                $process = Start-Process -FilePath $filePath -ArgumentList @([string]$parameters['Arguments']) -Wait -PassThru -ErrorAction Stop
                $exitCode = if ($null -ne $process) { $process.ExitCode } else { $null }
                if ($null -eq $exitCode -or [int]$exitCode -eq 0) {
                    return New-BoostLabVisualCppOperationResult -Operation $Operation -Success $true -Message ('Installer completed with exit code {0}: {1} {2}' -f $(if ($null -eq $exitCode) { '<not reported>' } else { [string]$exitCode }), [string]$parameters['SourcePath'], [string]$parameters['Arguments']) -Data ([pscustomobject]@{ ExitCode = $exitCode; FilePath = $filePath; Arguments = [string]$parameters['Arguments'] })
                }
                return New-BoostLabVisualCppOperationResult -Operation $Operation -Success $false -Message ('Installer reported non-zero exit code {0}: {1} {2}' -f [string]$exitCode, [string]$parameters['SourcePath'], [string]$parameters['Arguments']) -Data ([pscustomobject]@{ ExitCode = $exitCode; FilePath = $filePath; Arguments = [string]$parameters['Arguments'] })
            }
            default {
                return New-BoostLabVisualCppOperationResult -Operation $Operation -Success $false -Message ('Unsupported Visual C++ operation type: {0}' -f [string]$Operation.Type)
            }
        }
    }
    catch {
        return New-BoostLabVisualCppOperationResult -Operation $Operation -Success $false -Message $_.Exception.Message -Data $_
    }
}

function Invoke-BoostLabVisualCppOperationPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Plan,

        [scriptblock]$OperationExecutor = $null,

        [bool]$SkipEnvironmentChecks = $false
    )

    $operationResults = New-Object System.Collections.Generic.List[object]
    $warnings = New-Object System.Collections.Generic.List[string]
    $errors = New-Object System.Collections.Generic.List[string]
    $changesStarted = $false

    foreach ($operation in @($Plan.Operations)) {
        if ($SkipEnvironmentChecks -and [string]$operation.Type -in @('RequireAdministrator', 'RequireInternet')) {
            $result = New-BoostLabVisualCppOperationResult -Operation $operation -Success $true -Message 'Skipped by test-safe executor option.'
        }
        elseif ($null -ne $OperationExecutor) {
            $result = & $OperationExecutor $operation $Plan
        }
        else {
            $result = Invoke-BoostLabVisualCppRealOperation -Operation $operation
        }

        if ($null -eq $result) {
            $result = New-BoostLabVisualCppOperationResult -Operation $operation -Success $false -Message 'Operation executor returned no result.'
        }

        $operationResults.Add($result) | Out-Null
        if ([string]$operation.Type -notin @('RequireAdministrator', 'RequireInternet', 'SetProgressPreference')) {
            $changesStarted = $true
        }

        if ([string]$result.Status -eq 'Warning') {
            $warnings.Add("$($operation.Label): $($result.Message)") | Out-Null
        }
        if (-not [bool]$result.Success -and [bool]$operation.Required) {
            $errors.Add("$($operation.Label): $($result.Message)") | Out-Null
            break
        }
    }

    $failedRequired = @($operationResults.ToArray() | Where-Object { -not [bool]$_.Success -and [bool]$_.Required })
    $completedRequired = @($operationResults.ToArray() | Where-Object { [bool]$_.Required })
    $requiredOperationCount = @($Plan.Operations | Where-Object { [bool]$_.Required }).Count

    [pscustomobject]@{
        Success = (@($failedRequired).Count -eq 0 -and @($completedRequired).Count -eq $requiredOperationCount)
        Operations = $operationResults.ToArray()
        FailedRequiredOperations = @($failedRequired)
        Warnings = $warnings.ToArray()
        Errors = $errors.ToArray()
        ChangesStarted = $changesStarted
    }
}

function New-BoostLabVisualCppVerificationResult {
    param(
        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [object]$SourceStatus,

        [AllowNull()]
        [object]$Execution = $null
    )

    $checks = New-Object System.Collections.Generic.List[object]
    $checks.Add(
        (New-BoostLabVerificationCheck `
            -Name 'Visual C++ source checksum' `
            -Expected $script:BoostLabExpectedSourceHash `
            -Actual ([string]$SourceStatus.DetectedSha256) `
            -Status ([string]$SourceStatus.ChecksumStatus) `
            -Message 'Visual C++ must verify the exact Ultimate source script before any install workflow can run.')
    ) | Out-Null

    if ($null -ne $Execution) {
        foreach ($operation in @($Execution.Operations)) {
            $status = if ([bool]$operation.Success) {
                if ([string]$operation.Status -eq 'Warning') { 'Warning' } else { 'Passed' }
            }
            elseif ([bool]$operation.Required) {
                'Failed'
            }
            else {
                'Warning'
            }
            $checks.Add(
                (New-BoostLabVerificationCheck `
                    -Name ([string]$operation.Label) `
                    -Expected 'Source-equivalent operation completed successfully in source order' `
                    -Actual ([string]$operation.Message) `
                    -Status $status `
                    -Message ('Visual C++ source-equivalent operation {0} reported {1}.' -f [int]$operation.Order, $status))
            ) | Out-Null
        }
    }

    $failedChecks = @($checks.ToArray() | Where-Object { [string]$_.Status -eq 'Failed' })
    $warningChecks = @($checks.ToArray() | Where-Object { [string]$_.Status -eq 'Warning' })
    $status = if ($failedChecks.Count -gt 0) {
        'Failed'
    }
    elseif ($warningChecks.Count -gt 0) {
        'Warning'
    }
    else {
        'Passed'
    }
    $message = if ($status -eq 'Failed') {
        'Visual C++ source-equivalent workflow verification failed.'
    }
    elseif ($status -eq 'Warning') {
        'Visual C++ source-equivalent workflow completed with warnings.'
    }
    else {
        'Visual C++ source-equivalent workflow verification passed.'
    }

    $expectedState = if ($Action -eq 'Apply') {
        'Visual C++ source-equivalent workflow downloads twelve packages and runs twelve waited installers in source order after confirmation.'
    }
    else {
        'Visual C++ source identity, artifact source classifications, and operation plan are readable without mutation.'
    }
    $detectedState = if ($null -ne $Execution) {
        'Operations={0}; FailedRequired={1}; Warnings={2}' -f @(
            @($Execution.Operations).Count,
            @($Execution.FailedRequiredOperations).Count,
            @($Execution.Warnings).Count
        )
    }
    else {
        'SourceChecksum={0}; ArtifactSources={1}; PlannedOperations={2}' -f @(
            [string]$SourceStatus.ChecksumStatus,
            @(Get-BoostLabVisualCppArtifactSources).Count,
            @((Get-BoostLabVisualCppOperationPlan).Operations).Count
        )
    }

    New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $Action `
        -Status $status `
        -ExpectedState $expectedState `
        -DetectedState $detectedState `
        -Checks $checks.ToArray() `
        -Message $message
}

function New-BoostLabVisualCppResult {
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

function Get-BoostLabVisualCppAnalysis {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabVisualCppSourceStatus
    $plan = Get-BoostLabVisualCppOperationPlan
    [pscustomobject]@{
        Mode                              = 'SourceEquivalentControlledRuntime'
        Source                            = $sourceStatus
        SourceBehaviorSummary             = @(Get-BoostLabVisualCppSourceBehaviorSummary)
        ArtifactSources                   = @(Get-BoostLabVisualCppArtifactSources)
        Packages                          = @(Get-BoostLabVisualCppPackageDefinitions)
        DownloadPlan                      = @($script:BoostLabVisualCppDownloadFiles)
        InstallerPlan                     = @($script:BoostLabVisualCppInstallerPlan | ForEach-Object {
            [pscustomobject]@{
                FileName = [string]$_['FileName']
                Arguments = [string]$_['Arguments']
                Wait = $true
            }
        })
        OperationPlan                     = $plan
        NoMutationOccurred                = $true
        NoDownloadOccurred                = $true
        NoInstallerExecutionOccurred      = $true
        NoExternalProcessStarted          = $true
        NoRegistryMutationOccurred        = $true
        NoFileCleanupOccurred             = $true
        NoRebootOccurred                  = $true
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
        ConfirmationRequiredActions = @('Apply')
        ConfirmationText            = 'Visual C++ will run the source-equivalent workflow: verify Administrator and internet access, download twelve Ultimate-author-hosted redistributable installers to Windows Temp, and run all twelve installers sequentially with source-defined switches and Start-Process -Wait. Artifact sources remain classified as NeedsBoostLabMirror; no reboot is requested by the source. Continue?'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabVisualCppSourceStatus
    [pscustomobject]@{
        Supported            = [string]$sourceStatus.ChecksumStatus -eq 'Passed'
        ToolId               = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle            = [string]$script:BoostLabToolMetadata['Title']
        Reason               = if ([string]$sourceStatus.ChecksumStatus -eq 'Passed') {
            'Visual C++ source-equivalent install workflow is available after explicit confirmation.'
        }
        else {
            'Visual C++ source identity is missing or checksum verification failed.'
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
        Status          = 'SourceEquivalentControlledRuntime'
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

        [scriptblock]$OperationExecutor = $null,

        [bool]$SkipEnvironmentChecks = $false
    )

    $canonicalActionName = switch ($ActionName) {
        'Install Visual C++' { 'Apply' }
        'Apply Source Workflow' { 'Apply' }
        'Apply Auto' { 'Apply' }
        default { $ActionName }
    }

    if ($canonicalActionName -notin @($script:BoostLabImplementedActions)) {
        return New-BoostLabVisualCppResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'Unsupported' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Unsupported Visual C++ action. Only Analyze and Apply are exposed.'
    }

    if ($canonicalActionName -eq 'Analyze') {
        $analysis = Get-BoostLabVisualCppAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        $verification = New-BoostLabVisualCppVerificationResult -Action 'Analyze' -SourceStatus $analysis.Source
        return New-BoostLabVisualCppResult `
            -Success $sourceOk `
            -Action 'Analyze' `
            -Status $(if ($sourceOk) { 'Analyzed' } else { 'SourceIdentityFailed' }) `
            -CommandStatus 'No execution performed' `
            -VerificationStatus $(if ($sourceOk) { 'Passed' } else { 'Failed' }) `
            -Message $(if ($sourceOk) { 'Visual C++ source identity, twelve-package artifact source classifications, and source-equivalent install workflow were analyzed. No download, installer launch, external process, registry, file, cleanup, or reboot operation occurred.' } else { 'Visual C++ source identity could not be verified. No operation was executed.' }) `
            -Data $analysis `
            -VerificationResult $verification `
            -Errors $(if ($sourceOk) { @() } else { @('Visual C++ source checksum did not match the expected value or the source file is missing.') })
    }

    if (-not $Confirmed) {
        return New-BoostLabVisualCppResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'Cancelled' `
            -CommandStatus 'Cancelled before execution' `
            -VerificationStatus 'NotRun' `
            -Message 'Visual C++ install requires explicit Action Plan confirmation before any Administrator check, internet check, download, installer launch, external process, package mutation, or system mutation.' `
            -Cancelled $true
    }

    $sourceStatus = Get-BoostLabVisualCppSourceStatus
    if ([string]$sourceStatus.ChecksumStatus -ne 'Passed') {
        $verification = New-BoostLabVisualCppVerificationResult -Action 'Apply' -SourceStatus $sourceStatus
        return New-BoostLabVisualCppResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'SourceIdentityFailed' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Failed' `
            -Message 'Visual C++ install blocked because source checksum verification failed or the source file is missing. No operation was executed.' `
            -Data ([pscustomobject]@{ Source = $sourceStatus; ArtifactSources = @(Get-BoostLabVisualCppArtifactSources) }) `
            -VerificationResult $verification `
            -Errors @('Visual C++ source checksum did not match the expected value or the source file is missing.')
    }

    $plan = Get-BoostLabVisualCppOperationPlan
    $execution = Invoke-BoostLabVisualCppOperationPlan -Plan $plan -OperationExecutor $OperationExecutor -SkipEnvironmentChecks:$SkipEnvironmentChecks
    $verificationResult = New-BoostLabVisualCppVerificationResult -Action 'Apply' -SourceStatus $sourceStatus -Execution $execution
    $warnings = @($execution.Warnings)
    $errors = @($execution.Errors)
    $data = [pscustomobject]@{
        Source                   = $sourceStatus
        Plan                     = $plan
        ArtifactSources          = @(Get-BoostLabVisualCppArtifactSources)
        Packages                 = @(Get-BoostLabVisualCppPackageDefinitions)
        Operations               = @($execution.Operations)
        FailedRequiredOperations = @($execution.FailedRequiredOperations)
        NoRebootRequested        = $true
        RuntimeUrlUnchanged      = $true
        BoostLabMirrorRequired   = $true
    }

    if ([bool]$execution.Success) {
        $hasWarnings = @($warnings).Count -gt 0
        return New-BoostLabVisualCppResult `
            -Success $true `
            -Action 'Apply' `
            -Status $(if ($hasWarnings) { 'CompletedWithWarnings' } else { 'Completed' }) `
            -CommandStatus $(if ($hasWarnings) { 'Completed with warnings' } else { 'Completed' }) `
            -VerificationStatus $(if ($hasWarnings) { 'Warning' } else { 'Passed' }) `
            -Message 'Visual C++ source-equivalent workflow completed: twelve redistributable downloads and twelve waited installer launches were requested in source order with source-defined switches. No reboot was requested by the source.' `
            -Data $data `
            -VerificationResult $verificationResult `
            -Warnings $warnings `
            -ChangesExecuted:$execution.ChangesStarted
    }

    return New-BoostLabVisualCppResult `
        -Success $false `
        -Action 'Apply' `
        -Status 'Failed' `
        -CommandStatus 'Completed with errors' `
        -VerificationStatus 'Failed' `
        -Message "Visual C++ source-equivalent workflow failed closed. Failed operation(s): $($errors -join '; ')" `
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

    New-BoostLabVisualCppResult `
        -Success $false `
        -Action 'Default' `
        -Status 'DefaultUnavailable' `
        -CommandStatus 'Unavailable' `
        -VerificationStatus 'NotApplicable' `
        -Message 'Default is unavailable for Visual C++ because the source defines only an install workflow. Default is not Restore.'
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
    'Get-BoostLabVisualCppSourceStatus'
    'Get-BoostLabVisualCppAnalysis'
    'Get-BoostLabVisualCppOperationPlan'
    'Invoke-BoostLabVisualCppOperationPlan'
)
