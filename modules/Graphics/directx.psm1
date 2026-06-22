Set-StrictMode -Version Latest

if (-not (Get-Command -Name 'New-BoostLabVerificationCheck' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1') -Scope Local -Force -ErrorAction Stop
}

function Invoke-BoostLabDirectXVerifiedArtifactDownload {
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
    Id = 'directx'
    Title = 'DirectX'
    Stage = 'Graphics'
    Order = 8
    Type = 'action'
    RiskLevel = 'high'
    Description = 'Source-equivalent controlled runtime. Install 7-Zip, configure its source-defined options, download/extract DirectX, and launch DXSETUP after explicit confirmation.'
    Actions = @('Analyze', 'Apply')
    Capabilities = [ordered]@{
        RequiresAdmin              = $true
        RequiresInternet           = $true
        CanReboot                  = $false
        CanModifyRegistry          = $true
        CanModifyServices          = $false
        CanInstallSoftware         = $true
        CanDownload                = $true
        CanModifyDrivers           = $false
        CanModifySecurity          = $false
        CanDeleteFiles             = $true
        UsesTrustedInstaller       = $false
        UsesSafeMode               = $false
        SupportsDefault            = $false
        SupportsRestore            = $false
        NeedsExplicitConfirmation  = $true
    }
}

$script:BoostLabImplementedActions = @('Analyze', 'Apply')
$script:BoostLabExpectedSourceHash = '17051A2F0F7A0CF16BE525121720406E8F1630C94E5977A7CD4C18652A87EE05'
$script:BoostLabExpectedCanonicalSourceHash = 'B944AE03DE0AFDD7329B84BBF53FF5624739465CBB7130A021E097A6723B1B27'
$script:BoostLabSourceRelativePath = 'source-ultimate/5 Graphics/2 DirectX.ps1'

$script:BoostLabDirectX7ZipUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe'
$script:BoostLabDirectXPackageUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/directx.exe'
$script:BoostLabDirectXArtifactPolicyStatus = 'BoostLabMirrorAvailable'
$script:BoostLabDirectXArtifactClassification = 'UltimateAuthorHostedArtifact'

function Get-BoostLabDirectXProjectRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

function Get-BoostLabDirectXSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Join-Path (Get-BoostLabDirectXProjectRoot) ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabDirectXSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabDirectXSourcePath
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

function Get-BoostLabDirectXRuntimePaths {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $systemRoot = if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) { 'C:\Windows' } else { $env:SystemRoot }
    $systemDrive = if ([string]::IsNullOrWhiteSpace($env:SystemDrive)) { 'C:' } else { $env:SystemDrive }
    $programData = if ([string]::IsNullOrWhiteSpace($env:ProgramData)) { Join-Path $systemDrive 'ProgramData' } else { $env:ProgramData }

    $startMenuPrograms = Join-Path $programData 'Microsoft\Windows\Start Menu\Programs'
    $sevenZipFolder = Join-Path $startMenuPrograms '7-Zip'
    [pscustomobject]@{
        SystemRoot                 = $systemRoot
        SystemDrive                = $systemDrive
        ProgramData                = $programData
        SevenZipInstaller          = Join-Path $systemRoot 'Temp\7zip.exe'
        SevenZipExecutable         = Join-Path $systemDrive 'Program Files\7-Zip\7z.exe'
        SevenZipRegistryPath       = 'HKCU:\Software\7-Zip\Options'
        SevenZipShortcutSource     = Join-Path $sevenZipFolder '7-Zip File Manager.lnk'
        SevenZipShortcutTarget     = Join-Path $startMenuPrograms '7-Zip File Manager.lnk'
        SevenZipStartMenuDirectory = $sevenZipFolder
        DirectXPackage             = Join-Path $systemRoot 'Temp\directx.exe'
        DirectXExtractDirectory    = Join-Path $systemRoot 'Temp\directx'
        DirectXSetupExecutable     = Join-Path $systemRoot 'Temp\directx\DXSETUP.exe'
    }
}

function Get-BoostLabDirectXArtifactSources {
    [CmdletBinding()]
    [OutputType([object[]])]
    param()

    @(
        [pscustomobject]@{
            Id = 'directx-seven-zip'
            DisplayName = '7-Zip installer used by DirectX source workflow'
            FileName = '7zip.exe'
            SourceUrl = $script:BoostLabDirectX7ZipUrl
            Classification = $script:BoostLabDirectXArtifactClassification
            MirrorStatus = $script:BoostLabDirectXArtifactPolicyStatus
            RuntimeUrlUnchanged = $false
            BinaryIncluded = $false
            ArtifactApproved = $true
        }
        [pscustomobject]@{
            Id = 'directx-runtime-package'
            DisplayName = 'DirectX runtime package used by DirectX source workflow'
            FileName = 'directx.exe'
            SourceUrl = $script:BoostLabDirectXPackageUrl
            Classification = $script:BoostLabDirectXArtifactClassification
            MirrorStatus = $script:BoostLabDirectXArtifactPolicyStatus
            RuntimeUrlUnchanged = $false
            BinaryIncluded = $false
            ArtifactApproved = $true
        }
    )
}

function Get-BoostLabDirectXSourceBehaviorSummary {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'Checks Administrator rights.'
        'Checks internet connectivity by pinging 8.8.8.8.'
        'Sets progress preference to silentlycontinue.'
        'Downloads 7zip.exe to %SystemRoot%\Temp\7zip.exe from the Ultimate author-hosted source URL.'
        'Runs the 7-Zip installer with /S and waits for it to finish.'
        'Writes HKCU\Software\7-Zip\Options ContextMenu=259 and CascadedMenu=0.'
        'Moves the 7-Zip File Manager Start Menu shortcut up one level and removes the 7-Zip Start Menu folder.'
        'Downloads directx.exe to %SystemRoot%\Temp\directx.exe from the Ultimate author-hosted source URL.'
        'Extracts directx.exe to %SystemRoot%\Temp\directx using %SystemDrive%\Program Files\7-Zip\7z.exe.'
        'Launches %SystemRoot%\Temp\directx\DXSETUP.exe without waiting.'
    )
}

function New-BoostLabDirectXOperation {
    param(
        [Parameter(Mandatory)]
        [int]$Order,

        [Parameter(Mandatory)]
        [string]$Type,

        [Parameter(Mandatory)]
        [string]$Label,

        [Parameter(Mandatory)]
        [hashtable]$Parameters,

        [bool]$Required = $true
    )

    [pscustomobject]@{
        Order = $Order
        Type = $Type
        Label = $Label
        Parameters = $Parameters
        Required = $Required
    }
}

function Get-BoostLabDirectXOperationPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $paths = Get-BoostLabDirectXRuntimePaths
    [pscustomobject]@{
        PlanType = 'SourceEquivalentDirectXInstall'
        ArtifactPolicyStatus = $script:BoostLabDirectXArtifactPolicyStatus
        ArtifactClassification = $script:BoostLabDirectXArtifactClassification
        Paths = $paths
        Operations = @(
            New-BoostLabDirectXOperation -Order 1 -Type 'RequireAdministrator' -Label 'Verify Administrator rights' -Parameters @{}
            New-BoostLabDirectXOperation -Order 2 -Type 'RequireInternet' -Label 'Verify internet connectivity with 8.8.8.8' -Parameters @{ ComputerName = '8.8.8.8' }
            New-BoostLabDirectXOperation -Order 3 -Type 'SetProgressPreference' -Label 'Set progress preference to silentlycontinue' -Parameters @{ Value = 'silentlycontinue' }
            New-BoostLabDirectXOperation -Order 4 -Type 'DownloadFile' -Label 'Download 7-Zip installer' -Parameters @{ Uri = $script:BoostLabDirectX7ZipUrl; Destination = $paths.SevenZipInstaller; FileName = '7zip.exe'; ArtifactId = 'directx-seven-zip'; MirrorStatus = $script:BoostLabDirectXArtifactPolicyStatus }
            New-BoostLabDirectXOperation -Order 5 -Type 'StartProcessWait' -Label 'Install 7-Zip silently' -Parameters @{ FilePath = $paths.SevenZipInstaller; Arguments = @('/S') }
            New-BoostLabDirectXOperation -Order 6 -Type 'SetRegistryDword' -Label 'Set 7-Zip ContextMenu option' -Parameters @{ Path = $paths.SevenZipRegistryPath; Name = 'ContextMenu'; Value = 259 }
            New-BoostLabDirectXOperation -Order 7 -Type 'SetRegistryDword' -Label 'Set 7-Zip CascadedMenu option' -Parameters @{ Path = $paths.SevenZipRegistryPath; Name = 'CascadedMenu'; Value = 0 }
            New-BoostLabDirectXOperation -Order 8 -Type 'MoveItemSilently' -Label 'Move 7-Zip Start Menu shortcut' -Parameters @{ Source = $paths.SevenZipShortcutSource; Destination = $paths.SevenZipShortcutTarget } -Required:$false
            New-BoostLabDirectXOperation -Order 9 -Type 'RemoveDirectorySilently' -Label 'Remove 7-Zip Start Menu folder' -Parameters @{ Path = $paths.SevenZipStartMenuDirectory } -Required:$false
            New-BoostLabDirectXOperation -Order 10 -Type 'DownloadFile' -Label 'Download DirectX runtime package' -Parameters @{ Uri = $script:BoostLabDirectXPackageUrl; Destination = $paths.DirectXPackage; FileName = 'directx.exe'; ArtifactId = 'directx-runtime-package'; MirrorStatus = $script:BoostLabDirectXArtifactPolicyStatus }
            New-BoostLabDirectXOperation -Order 11 -Type 'ExtractDirectX' -Label 'Extract DirectX package with 7-Zip' -Parameters @{ FilePath = $paths.SevenZipExecutable; Arguments = @('x', $paths.DirectXPackage, "-o$($paths.DirectXExtractDirectory)", '-y'); ExpectedOutput = $paths.DirectXSetupExecutable }
            New-BoostLabDirectXOperation -Order 12 -Type 'StartProcessNoWait' -Label 'Launch DirectX setup' -Parameters @{ FilePath = $paths.DirectXSetupExecutable }
        )
    }
}

function New-BoostLabDirectXOperationResult {
    param(
        [Parameter(Mandatory)]
        [object]$Operation,

        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Message,

        [AllowNull()]
        [object]$Data = $null,

        [string]$Status = 'Completed'
    )

    [pscustomobject]@{
        Success = $Success
        Status = $Status
        Order = [int]$Operation.Order
        Type = [string]$Operation.Type
        Label = [string]$Operation.Label
        Required = [bool]$Operation.Required
        Message = $Message
        Data = $Data
        Timestamp = Get-Date
    }
}

function Test-BoostLabDirectXAdministrator {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if (Get-Command -Name 'Test-BoostLabAdministrator' -ErrorAction SilentlyContinue) {
        return [bool](Test-BoostLabAdministrator)
    }

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-BoostLabDirectXInternet {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return [bool](Test-Connection -ComputerName '8.8.8.8' -Count 1 -Quiet -ErrorAction SilentlyContinue)
}

function Invoke-BoostLabDirectXRealOperation {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Operation
    )

    $parameters = $Operation.Parameters
    try {
        switch ([string]$Operation.Type) {
            'RequireAdministrator' {
                if (-not (Test-BoostLabDirectXAdministrator)) {
                    return New-BoostLabDirectXOperationResult -Operation $Operation -Success $false -Message 'Administrator execution is required.'
                }
                return New-BoostLabDirectXOperationResult -Operation $Operation -Success $true -Message 'Administrator execution confirmed.'
            }
            'RequireInternet' {
                if (-not (Test-BoostLabDirectXInternet)) {
                    return New-BoostLabDirectXOperationResult -Operation $Operation -Success $false -Message 'Internet connectivity to 8.8.8.8 is required.'
                }
                return New-BoostLabDirectXOperationResult -Operation $Operation -Success $true -Message 'Internet connectivity confirmed.'
            }
            'SetProgressPreference' {
                $global:ProgressPreference = [string]$parameters['Value']
                return New-BoostLabDirectXOperationResult -Operation $Operation -Success $true -Message "ProgressPreference set to $($parameters['Value'])."
            }
            'DownloadFile' {
                $download = Invoke-BoostLabDirectXVerifiedArtifactDownload `
                    -ArtifactId ([string]$parameters['ArtifactId']) `
                    -Destination ([string]$parameters['Destination'])
                return New-BoostLabDirectXOperationResult `
                    -Operation $Operation `
                    -Success $true `
                    -Message "Downloaded $($parameters['FileName']) from verified BoostLab mirror to $($parameters['Destination'])." `
                    -Data ([pscustomobject]@{ ArtifactId = [string]$download.ArtifactId; SourceUrl = [string]$download.SourceUrl })
            }
            'StartProcessWait' {
                $process = Start-Process -FilePath ([string]$parameters['FilePath']) -ArgumentList @($parameters['Arguments']) -Wait -PassThru -ErrorAction Stop
                $exitCode = if ($null -ne $process) { [int]$process.ExitCode } else { 0 }
                if ($exitCode -ne 0) {
                    return New-BoostLabDirectXOperationResult -Operation $Operation -Success $false -Message "Process exited with code $exitCode." -Data ([pscustomobject]@{ ExitCode = $exitCode })
                }
                return New-BoostLabDirectXOperationResult -Operation $Operation -Success $true -Message 'Process completed successfully.' -Data ([pscustomobject]@{ ExitCode = $exitCode })
            }
            'SetRegistryDword' {
                New-Item -Path ([string]$parameters['Path']) -Force -ErrorAction Stop | Out-Null
                New-ItemProperty -Path ([string]$parameters['Path']) -Name ([string]$parameters['Name']) -Value ([int]$parameters['Value']) -PropertyType DWord -Force -ErrorAction Stop | Out-Null
                return New-BoostLabDirectXOperationResult -Operation $Operation -Success $true -Message "Set $($parameters['Name']) to DWORD $($parameters['Value'])."
            }
            'MoveItemSilently' {
                Move-Item -Path ([string]$parameters['Source']) -Destination ([string]$parameters['Destination']) -Force -ErrorAction SilentlyContinue
                return New-BoostLabDirectXOperationResult -Operation $Operation -Success $true -Status 'Warning' -Message 'Source uses silent shortcut move; missing shortcut is tolerated.'
            }
            'RemoveDirectorySilently' {
                Remove-Item -Path ([string]$parameters['Path']) -Recurse -Force -ErrorAction SilentlyContinue
                return New-BoostLabDirectXOperationResult -Operation $Operation -Success $true -Status 'Warning' -Message 'Source uses silent Start Menu folder cleanup; missing folder is tolerated.'
            }
            'ExtractDirectX' {
                $process = Start-Process -FilePath ([string]$parameters['FilePath']) -ArgumentList @($parameters['Arguments']) -Wait -PassThru -ErrorAction Stop
                $exitCode = if ($null -ne $process) { [int]$process.ExitCode } else { 0 }
                if ($exitCode -ne 0) {
                    return New-BoostLabDirectXOperationResult -Operation $Operation -Success $false -Message "7-Zip extraction exited with code $exitCode." -Data ([pscustomobject]@{ ExitCode = $exitCode })
                }
                if (-not (Test-Path -LiteralPath ([string]$parameters['ExpectedOutput']) -PathType Leaf)) {
                    return New-BoostLabDirectXOperationResult -Operation $Operation -Success $false -Message "Expected DXSETUP output was not found: $($parameters['ExpectedOutput'])." -Data ([pscustomobject]@{ ExitCode = $exitCode })
                }
                return New-BoostLabDirectXOperationResult -Operation $Operation -Success $true -Message 'DirectX package extracted and DXSETUP was found.' -Data ([pscustomobject]@{ ExitCode = $exitCode; ExpectedOutput = [string]$parameters['ExpectedOutput'] })
            }
            'StartProcessNoWait' {
                if (-not (Test-Path -LiteralPath ([string]$parameters['FilePath']) -PathType Leaf)) {
                    return New-BoostLabDirectXOperationResult -Operation $Operation -Success $false -Message "DXSETUP executable was not found: $($parameters['FilePath'])."
                }
                Start-Process -FilePath ([string]$parameters['FilePath']) -ErrorAction Stop
                return New-BoostLabDirectXOperationResult -Operation $Operation -Success $true -Message "Started DirectX setup: $($parameters['FilePath'])."
            }
            default {
                return New-BoostLabDirectXOperationResult -Operation $Operation -Success $false -Message "Unsupported operation type '$($Operation.Type)'."
            }
        }
    }
    catch {
        return New-BoostLabDirectXOperationResult -Operation $Operation -Success $false -Message $_.Exception.Message
    }
}

function Invoke-BoostLabDirectXOperationPlan {
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
            $result = New-BoostLabDirectXOperationResult -Operation $operation -Success $true -Message 'Skipped by test-safe executor option.'
        }
        elseif ($null -ne $OperationExecutor) {
            $result = & $OperationExecutor $operation $Plan
        }
        else {
            $result = Invoke-BoostLabDirectXRealOperation -Operation $operation
        }

        if ($null -eq $result) {
            $result = New-BoostLabDirectXOperationResult -Operation $operation -Success $false -Message 'Operation executor returned no result.'
        }

        $operationResults.Add($result)
        if ([string]$operation.Type -notin @('RequireAdministrator', 'RequireInternet', 'SetProgressPreference')) {
            $changesStarted = $true
        }

        if ([string]$result.Status -eq 'Warning' -or (-not [bool]$operation.Required -and -not [bool]$result.Success)) {
            $warnings.Add("$($operation.Label): $($result.Message)")
        }
        if (-not [bool]$result.Success -and [bool]$operation.Required) {
            $errors.Add("$($operation.Label): $($result.Message)")
            break
        }
    }

    $failedRequired = @($operationResults | Where-Object { -not [bool]$_.Success -and [bool]$_.Required })
    $completedRequired = @($operationResults | Where-Object { [bool]$_.Required })
    $requiredOperationCount = @($Plan.Operations | Where-Object { [bool]$_.Required }).Count
    $failedRequiredCount = @($failedRequired).Count
    $completedRequiredCount = @($completedRequired).Count
    [pscustomobject]@{
        Success = ($failedRequiredCount -eq 0 -and $completedRequiredCount -eq $requiredOperationCount)
        Operations = $operationResults.ToArray()
        FailedRequiredOperations = @($failedRequired)
        Warnings = $warnings.ToArray()
        Errors = $errors.ToArray()
        ChangesStarted = $changesStarted
    }
}

function New-BoostLabDirectXVerificationResult {
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
            -Name 'DirectX source checksum' `
            -Expected $script:BoostLabExpectedSourceHash `
            -Actual ([string]$SourceStatus.DetectedSha256) `
            -Status ([string]$SourceStatus.ChecksumStatus) `
            -Message 'DirectX must verify the exact Ultimate source script before any install workflow can run.')
    )

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
                    -Expected 'Source-equivalent operation completed or tolerated per source' `
                    -Actual ([string]$operation.Message) `
                    -Status $status `
                    -Message ('DirectX source-equivalent operation {0} reported {1}.' -f [int]$operation.Order, $status))
            )
        }
    }

    $summary = if (@($checks | Where-Object { [string]$_.Status -eq 'Failed' }).Count -gt 0) {
        'DirectX source-equivalent workflow verification failed.'
    }
    elseif (@($checks | Where-Object { [string]$_.Status -eq 'Warning' }).Count -gt 0) {
        'DirectX source-equivalent workflow completed with tolerated source-equivalent warnings.'
    }
    else {
        'DirectX source-equivalent workflow verification passed.'
    }

    $status = if (@($checks | Where-Object { [string]$_.Status -eq 'Failed' }).Count -gt 0) {
        'Failed'
    }
    elseif (@($checks | Where-Object { [string]$_.Status -eq 'Warning' }).Count -gt 0) {
        'Warning'
    }
    else {
        'Passed'
    }

    $expectedState = if ($Action -eq 'Apply') {
        'DirectX source-equivalent 7-Zip and DirectX install workflow runs in source order after confirmation.'
    }
    else {
        'DirectX source identity, artifact source classifications, and operation plan are readable without mutation.'
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
            @(Get-BoostLabDirectXArtifactSources).Count,
            @((Get-BoostLabDirectXOperationPlan).Operations).Count
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
        -Message $summary
}

function New-BoostLabDirectXResult {
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

function Get-BoostLabDirectXAnalysis {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabDirectXSourceStatus
    [pscustomobject]@{
        Mode                         = 'SourceEquivalentControlledRuntime'
        Source                       = $sourceStatus
        SourceBehaviorSummary        = @(Get-BoostLabDirectXSourceBehaviorSummary)
        ArtifactSources              = @(Get-BoostLabDirectXArtifactSources)
        OperationPlan                = Get-BoostLabDirectXOperationPlan
        NoMutationOccurred           = $true
        NoDownloadOccurred           = $true
        NoInstallerExecutionOccurred = $true
        NoExternalProcessStarted     = $true
        NoRegistryMutationOccurred   = $true
        NoShortcutMutationOccurred   = $true
        NoFileCleanupOccurred        = $true
        NoRebootOccurred             = $true
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
        ConfirmationText            = 'DirectX will run the source-equivalent workflow: verify Administrator and internet access, download verified BoostLab mirror copies of the source-defined 7-Zip and DirectX artifacts, install/configure 7-Zip, extract DirectX, and launch DXSETUP. Artifact sources are production/runtime approved with SHA and size verification; no reboot is requested by the source. Continue?'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabDirectXSourceStatus
    [pscustomobject]@{
        Supported            = [string]$sourceStatus.ChecksumStatus -eq 'Passed'
        ToolId               = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle            = [string]$script:BoostLabToolMetadata['Title']
        Reason               = if ([string]$sourceStatus.ChecksumStatus -eq 'Passed') {
            'DirectX source-equivalent install workflow is available after explicit confirmation.'
        }
        else {
            'DirectX source identity is missing or checksum verification failed.'
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
        'Install DirectX' { 'Apply' }
        'Apply Source Workflow' { 'Apply' }
        'Apply Auto' { 'Apply' }
        default { $ActionName }
    }

    if ($canonicalActionName -notin @($script:BoostLabImplementedActions)) {
        return New-BoostLabDirectXResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'Unsupported' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Unsupported DirectX action. Only Analyze and Apply are exposed.'
    }

    if ($canonicalActionName -eq 'Analyze') {
        $analysis = Get-BoostLabDirectXAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        $verification = New-BoostLabDirectXVerificationResult -Action 'Analyze' -SourceStatus $analysis.Source
        return New-BoostLabDirectXResult `
            -Success $sourceOk `
            -Action 'Analyze' `
            -Status $(if ($sourceOk) { 'Analyzed' } else { 'SourceIdentityFailed' }) `
            -CommandStatus 'No execution performed' `
            -VerificationStatus $(if ($sourceOk) { 'Passed' } else { 'Failed' }) `
            -Message $(if ($sourceOk) { 'DirectX source identity and source-equivalent 7-Zip/DirectX install workflow were analyzed. No download, installer, extraction, registry, file, shortcut, external process, or reboot operation occurred.' } else { 'DirectX source identity could not be verified. No operation was executed.' }) `
            -Data $analysis `
            -VerificationResult $verification `
            -Errors $(if ($sourceOk) { @() } else { @('DirectX source checksum did not match the expected value or the source file is missing.') })
    }

    if (-not $Confirmed) {
        return New-BoostLabDirectXResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'Cancelled' `
            -CommandStatus 'Cancelled before execution' `
            -VerificationStatus 'NotRun' `
            -Message 'DirectX install requires explicit Action Plan confirmation before any Administrator check, internet check, download, installer launch, extraction, registry write, Start Menu shortcut cleanup, DirectX setup launch, or system mutation.' `
            -Cancelled $true
    }

    $sourceStatus = Get-BoostLabDirectXSourceStatus
    if ([string]$sourceStatus.ChecksumStatus -ne 'Passed') {
        $verification = New-BoostLabDirectXVerificationResult -Action 'Apply' -SourceStatus $sourceStatus
        return New-BoostLabDirectXResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'SourceIdentityFailed' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Failed' `
            -Message 'DirectX install blocked because source checksum verification failed or the source file is missing. No operation was executed.' `
            -Data ([pscustomobject]@{ Source = $sourceStatus; ArtifactSources = @(Get-BoostLabDirectXArtifactSources) }) `
            -VerificationResult $verification `
            -Errors @('DirectX source checksum did not match the expected value or the source file is missing.')
    }

    $plan = Get-BoostLabDirectXOperationPlan
    $execution = Invoke-BoostLabDirectXOperationPlan -Plan $plan -OperationExecutor $OperationExecutor -SkipEnvironmentChecks:$SkipEnvironmentChecks
    $verificationResult = New-BoostLabDirectXVerificationResult -Action 'Apply' -SourceStatus $sourceStatus -Execution $execution
    $warnings = @($execution.Warnings)
    $errors = @($execution.Errors)
    $data = [pscustomobject]@{
        Source                  = $sourceStatus
        Plan                    = $plan
        ArtifactSources         = @(Get-BoostLabDirectXArtifactSources)
        Operations              = @($execution.Operations)
        FailedRequiredOperations = @($execution.FailedRequiredOperations)
        NoRebootRequested       = $true
        RuntimeUrlUnchanged     = $true
        BoostLabMirrorRequired  = $true
    }

    if ([bool]$execution.Success) {
        $hasWarnings = @($warnings).Count -gt 0
        return New-BoostLabDirectXResult `
            -Success $true `
            -Action 'Apply' `
            -Status $(if ($hasWarnings) { 'CompletedWithWarnings' } else { 'Completed' }) `
            -CommandStatus $(if ($hasWarnings) { 'Completed with warnings' } else { 'Completed' }) `
            -VerificationStatus $(if ($hasWarnings) { 'Warning' } else { 'Passed' }) `
            -Message 'DirectX source-equivalent workflow completed: 7-Zip download/install/configuration, source-defined Start Menu adjustment, DirectX download/extraction, and DXSETUP launch were requested in source order. No reboot was requested by the source.' `
            -Data $data `
            -VerificationResult $verificationResult `
            -Warnings $warnings `
            -ChangesExecuted:$execution.ChangesStarted
    }

    return New-BoostLabDirectXResult `
        -Success $false `
        -Action 'Apply' `
        -Status 'Failed' `
        -CommandStatus 'Completed with errors' `
        -VerificationStatus 'Failed' `
        -Message "DirectX source-equivalent workflow failed closed. Failed operation(s): $($errors -join '; ')" `
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

    New-BoostLabDirectXResult `
        -Success $false `
        -Action 'Default' `
        -Status 'DefaultUnavailable' `
        -CommandStatus 'Unavailable' `
        -VerificationStatus 'NotApplicable' `
        -Message 'Default is unavailable for DirectX because the source defines only an install workflow. Default is not Restore.'
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
    'Get-BoostLabDirectXSourceStatus'
    'Get-BoostLabDirectXAnalysis'
    'Get-BoostLabDirectXOperationPlan'
    'Invoke-BoostLabDirectXOperationPlan'
)
