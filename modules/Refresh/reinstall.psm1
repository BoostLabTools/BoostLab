Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'reinstall'
    Title = 'Reinstall'
    Stage = 'Refresh'
    Order = 1
    Type = 'action'
    RiskLevel = 'high'
    Description = 'Analyze or run the controlled source-defined Windows 11 Media Creation Tool reinstall handoff after explicit confirmation.'
    Actions = @('Analyze', 'Open', 'Apply', 'Default', 'Restore')
    Capabilities = [ordered]@{
        RequiresAdmin             = $true
        RequiresInternet          = $true
        CanReboot                 = $true
        CanModifyRegistry         = $false
        CanModifyServices         = $false
        CanInstallSoftware        = $true
        CanDownload               = $true
        CanModifyDrivers          = $false
        CanModifySecurity         = $false
        CanDeleteFiles            = $false
        UsesTrustedInstaller      = $false
        UsesSafeMode              = $false
        SupportsDefault           = $false
        SupportsRestore           = $false
        NeedsExplicitConfirmation = $true
    }
}

$script:BoostLabImplementedActions = @('Analyze', 'Open', 'Apply', 'Default', 'Restore')
$script:BoostLabExpectedSourceHash = '137F519926293F37052817ACBBE20851652E5EA1B9F3B5B9F933AA1E22C2D9FB'
$script:BoostLabExpectedCanonicalSourceHash = '64F76A856E4CC57BEE34C6DEA86F2B7ADC432B01A3FA4AEB5C2A650B9AE9A477'
$script:BoostLabSourceRelativePath = 'source-ultimate/2 Refresh/1 Reinstall.ps1'
$script:BoostLabWindows11MediaCreationToolUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw11.exe'
$script:BoostLabWindows11MediaCreationToolFileName = 'mediacreationtoolw11.exe'
$script:BoostLabWindows11MediaCreationToolArtifactId = 'reinstall-windows11-media-creation-tool'

function Get-BoostLabReinstallSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $projectRoot ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Invoke-BoostLabReinstallVerifiedArtifactDownload {
    param(
        [Parameter(Mandatory)]
        [string]$Destination
    )

    $downloadModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\DownloadProvenance.psm1'
    if (-not (Get-Command -Name 'Invoke-BoostLabVerifiedArtifactDownload' -ErrorAction SilentlyContinue)) {
        Import-Module -Name $downloadModulePath -Scope Local -Force -ErrorAction Stop
    }

    Invoke-BoostLabVerifiedArtifactDownload `
        -ArtifactId $script:BoostLabWindows11MediaCreationToolArtifactId `
        -Destination $Destination
}

function Get-BoostLabReinstallSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabReinstallSourcePath
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $sourceVerificationModulePath = Join-Path $projectRoot 'core\SourceVerification.psm1'
    if (-not (Get-Command -Name 'Test-BoostLabSourceChecksum' -ErrorAction SilentlyContinue)) {
        Import-Module -Name $sourceVerificationModulePath -Scope Local -Force -ErrorAction Stop
    }
    $verification = Test-BoostLabSourceChecksum `
        -LiteralPath $sourcePath `
        -ExpectedSha256 $script:BoostLabExpectedSourceHash `
        -ExpectedCanonicalSha256 $script:BoostLabExpectedCanonicalSourceHash `
        -TextNormalizationEnabled $true

    [pscustomobject]@{
        SourcePath              = $sourcePath
        SourceRelativePath      = $script:BoostLabSourceRelativePath
        Exists                  = [bool]$verification.Exists
        ExpectedSha256          = $script:BoostLabExpectedSourceHash
        DetectedSha256          = [string]$verification.DetectedSha256
        ExpectedCanonicalSha256 = $script:BoostLabExpectedCanonicalSourceHash
        DetectedCanonicalSha256 = [string]$verification.DetectedCanonicalSha256
        ChecksumStatus          = [string]$verification.ChecksumStatus
        RawChecksumStatus       = [string]$verification.RawChecksumStatus
        CanonicalChecksumStatus = [string]$verification.CanonicalChecksumStatus
        VerificationMode        = [string]$verification.VerificationMode
        VerificationErrors      = @($verification.Errors)
    }
}

function Test-BoostLabReinstallAdministrator {
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

function Test-BoostLabReinstallInternet {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        return [bool](Test-Connection -ComputerName '8.8.8.8' -Count 1 -Quiet -ErrorAction SilentlyContinue)
    }
    catch {
        return $false
    }
}

function Get-BoostLabReinstallOperationDescriptor {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $tempRoot = if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        ''
    }
    else {
        Join-Path $env:SystemRoot 'Temp'
    }
    $outputPath = if ([string]::IsNullOrWhiteSpace($tempRoot)) {
        ''
    }
    else {
        Join-Path $tempRoot $script:BoostLabWindows11MediaCreationToolFileName
    }

    [pscustomobject]@{
        Branch                         = 'Windows11'
        SourceBranchLabel              = 'Reinstall: W11'
        ProductScope                   = 'Windows 11 reinstall/refresh/media creation target'
        UnsupportedBranches            = @('Windows 10 Media Creation Tool branch')
        SourceDownloadCommand          = 'IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/mediacreationtoolw11.exe" -OutFile "$env:SystemRoot\Temp\mediacreationtoolw11.exe"'
        SourceLaunchCommand            = 'Start-Process "$env:SystemRoot\Temp\mediacreationtoolw11.exe"'
        RuntimeArtifactId              = $script:BoostLabWindows11MediaCreationToolArtifactId
        RuntimeSourceSelection         = 'VerifiedBoostLabMirror'
        DownloadUrl                    = $script:BoostLabWindows11MediaCreationToolUrl
        ExpectedFileName               = $script:BoostLabWindows11MediaCreationToolFileName
        OutputDirectory                = $tempRoot
        OutputPath                     = $outputPath
        DownloadMethod                 = 'Invoke-WebRequest'
        LaunchMethod                   = 'Start-Process'
        RequiresAdmin                  = $true
        RequiresInternet               = $true
        NeedsExplicitConfirmation      = $true
        CanLaunchExternalExecutable    = $true
        CanHandOffToWindowsSetup       = $true
        CanRebootAfterUserContinues    = $true
        DoesNotRunSetupDirectly        = $true
        DoesNotPassInstallerSwitches   = $true
        DoesNotModifyRegistryDirectly  = $true
        DoesNotModifyServicesDirectly  = $true
        DoesNotModifyDriversDirectly   = $true
        SourceEquivalent               = $true
    }
}

function New-BoostLabReinstallResult {
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

        [string[]]$Warnings = @(),

        [string[]]$Errors = @(),

        [bool]$Cancelled = $false,

        [bool]$ChangesExecuted = $false,

        [bool]$RestartRequired = $false
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
        RestartRequired    = $RestartRequired
        Cancelled          = $Cancelled
        ChangesExecuted    = $ChangesExecuted
        Timestamp          = Get-Date
        Data               = $Data
        Warnings           = @($Warnings)
        Errors             = @($Errors)
    }
}

function Get-BoostLabReinstallRiskWarnings {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'Original Ultimate source requires Administrator and internet access.'
        'Original Ultimate source offers a Windows 10 Media Creation Tool branch; BoostLab product scope keeps that branch unsupported.'
        'BoostLab Apply preserves the supported Windows 11 branch only.'
        'Apply downloads the source-defined Windows 11 Media Creation Tool executable into Windows Temp and launches it after explicit confirmation.'
        'The Media Creation Tool can hand off to Windows setup, media creation, refresh, reinstall, session changes, or reboot behavior after the user continues inside Microsoft tooling.'
        'BoostLab does not run setup.exe directly, pass installer switches, partition disks, format media, or reboot by itself.'
    )
}

function Get-BoostLabReinstallAnalysis {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabReinstallSourceStatus
    $descriptor = Get-BoostLabReinstallOperationDescriptor
    [pscustomobject]@{
        Mode                         = 'ControlledSourceEquivalent'
        AutoMode                     = 'Windows11MediaCreationToolApplyAvailable'
        SupportedTarget              = 'Windows 11 reinstall/refresh/media creation outcome'
        UnsupportedBranches          = @($descriptor.UnsupportedBranches)
        Source                       = $sourceStatus
        OperationDescriptor          = $descriptor
        SourceBehaviorSummary        = @(
            'Checks for Administrator rights and internet connectivity.'
            'Presents Windows 10 and Windows 11 reinstall menu choices.'
            'Windows 10 branch downloads mediacreationtoolw10.exe from the Ultimate-Files mirror into Windows Temp and launches it.'
            'Windows 11 branch downloads mediacreationtoolw11.exe from the Ultimate-Files mirror into Windows Temp and launches it.'
            'The source does not directly run setup.exe, mount an ISO, write registry values, delete files, call shutdown, or pass installer switches.'
            'BoostLab preserves the supported Windows 11 branch and keeps the Windows 10 branch unsupported by product scope.'
        )
        ApplyBehavior                = @(
            'Verify source checksum.'
            'Require explicit Action Plan confirmation.'
            'Require Administrator and internet connectivity.'
            'Download the source-defined Windows 11 Media Creation Tool URL to the source-defined Windows Temp file path.'
            'Launch the downloaded Windows 11 Media Creation Tool executable with Start-Process.'
            'Return structured command status without directly running Windows Setup or rebooting.'
        )
        Warnings                     = @(Get-BoostLabReinstallRiskWarnings)
        SourceEquivalentWindows11    = $true
        Windows10BranchUnsupported   = $true
        NoSetupExecutionByBoostLab   = $true
        NoDirectRebootByBoostLab     = $true
        NoRegistryMutationByBoostLab = $true
        NoServiceMutationByBoostLab  = $true
        NoDriverMutationByBoostLab   = $true
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
        ConfirmationText            = 'BoostLab will download the source-defined Windows 11 Media Creation Tool to Windows Temp and launch it. The Microsoft tool can continue into media creation, refresh, reinstall, session changes, or reboot after you proceed inside it. Continue?'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabReinstallSourceStatus
    [pscustomobject]@{
        Supported            = $true
        ToolId               = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle            = [string]$script:BoostLabToolMetadata['Title']
        Reason               = 'Reinstall Windows 11 source-equivalent Apply is available behind explicit confirmation.'
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
        Status          = 'ControlledSourceEquivalent'
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

        [bool]$Confirmed = $false
    )

    $canonicalActionName = switch ($ActionName) {
        'Prepare Manual Handoff' { 'Open' }
        'Manual Handoff' { 'Open' }
        'Apply Auto' { 'Apply' }
        default { $ActionName }
    }

    if ($canonicalActionName -notin @($script:BoostLabImplementedActions)) {
        return New-BoostLabReinstallResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'Unsupported' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Unsupported Reinstall action. Only Analyze, Open, Apply, Default, and Restore are exposed.'
    }

    if ($canonicalActionName -eq 'Analyze') {
        $analysis = Get-BoostLabReinstallAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        $status = if ($sourceOk) { 'Analyzed' } else { 'SourceVerificationFailed' }
        $message = if ($sourceOk) {
            'Reinstall analyzed. Windows 11 source-equivalent Apply is available behind explicit confirmation; Windows 10 branch remains unsupported by product scope.'
        }
        else {
            'Reinstall source checksum verification failed or source file is missing.'
        }
        $errors = if ($sourceOk) {
            @()
        }
        else {
            @('Reinstall source checksum did not match the expected value or the source file is missing.')
        }

        return New-BoostLabReinstallResult `
            -Success $sourceOk `
            -Action 'Analyze' `
            -Status $status `
            -CommandStatus 'No execution performed' `
            -VerificationStatus ([string]$analysis.Source.ChecksumStatus) `
            -Message $message `
            -Data $analysis `
            -Warnings @($analysis.Warnings) `
            -Errors $errors
    }

    if ($canonicalActionName -eq 'Open') {
        $analysis = Get-BoostLabReinstallAnalysis
        return New-BoostLabReinstallResult `
            -Success $true `
            -Action 'Open' `
            -Status 'GuidancePrepared' `
            -CommandStatus 'No execution performed' `
            -VerificationStatus ([string]$analysis.Source.ChecksumStatus) `
            -Message 'Reinstall guidance prepared. Open does not download, launch, mutate, start setup, or reboot. Use Apply for the controlled Windows 11 source-equivalent operation.' `
            -Data $analysis `
            -Warnings @($analysis.Warnings)
    }

    if ($canonicalActionName -eq 'Apply') {
        $analysis = Get-BoostLabReinstallAnalysis
        $descriptor = $analysis.OperationDescriptor
        if (-not $Confirmed) {
            return New-BoostLabReinstallResult `
                -Success $false `
                -Action 'Apply' `
                -Status 'ConfirmationRequired' `
                -CommandStatus 'Cancelled before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'Reinstall Apply requires explicit confirmation before downloading or launching the Windows 11 Media Creation Tool. No operation was executed.' `
                -Data $analysis `
                -Cancelled $true `
                -Warnings @($analysis.Warnings)
        }

        if ([string]$analysis.Source.ChecksumStatus -ne 'Passed') {
            return New-BoostLabReinstallResult `
                -Success $false `
                -Action 'Apply' `
                -Status 'SourceVerificationFailed' `
                -CommandStatus 'Blocked before execution' `
                -VerificationStatus ([string]$analysis.Source.ChecksumStatus) `
                -Message 'Reinstall Apply blocked because the Ultimate source checksum failed verification.' `
                -Data $analysis `
                -Errors @('Reinstall source checksum did not match the expected value or the source file is missing.') `
                -Warnings @($analysis.Warnings)
        }

        if (-not (Test-BoostLabReinstallAdministrator)) {
            return New-BoostLabReinstallResult `
                -Success $false `
                -Action 'Apply' `
                -Status 'AdministratorRequired' `
                -CommandStatus 'Blocked before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'Reinstall Apply requires BoostLab to run as Administrator before downloading or launching the Windows 11 Media Creation Tool.' `
                -Data $analysis `
                -Errors @('Administrator elevation is required.') `
                -Warnings @($analysis.Warnings)
        }

        if (-not (Test-BoostLabReinstallInternet)) {
            return New-BoostLabReinstallResult `
                -Success $false `
                -Action 'Apply' `
                -Status 'InternetRequired' `
                -CommandStatus 'Blocked before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'Reinstall Apply requires internet connectivity before downloading the Windows 11 Media Creation Tool.' `
                -Data $analysis `
                -Errors @('Internet connectivity is required.') `
                -Warnings @($analysis.Warnings)
        }

        if (
            [string]::IsNullOrWhiteSpace([string]$descriptor.OutputDirectory) -or
            -not (Test-Path -LiteralPath ([string]$descriptor.OutputDirectory) -PathType Container)
        ) {
            return New-BoostLabReinstallResult `
                -Success $false `
                -Action 'Apply' `
                -Status 'OutputPathUnavailable' `
                -CommandStatus 'Blocked before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'Reinstall Apply could not find the source-defined Windows Temp output directory.' `
                -Data $analysis `
                -Errors @('The source-defined Windows Temp output directory is unavailable.') `
                -Warnings @($analysis.Warnings)
        }

        try {
            $download = Invoke-BoostLabReinstallVerifiedArtifactDownload `
                -Destination ([string]$descriptor.OutputPath)

            $process = Start-Process `
                -FilePath ([string]$descriptor.OutputPath) `
                -PassThru `
                -ErrorAction Stop

            return New-BoostLabReinstallResult `
                -Success $true `
                -Action 'Apply' `
                -Status 'Windows11MediaCreationToolLaunched' `
                -CommandStatus 'Downloaded and launched' `
                -VerificationStatus 'SourceEquivalentOperationStarted' `
                -Message 'Windows 11 Media Creation Tool downloaded to the source-defined Windows Temp path and launched. Continue inside Microsoft tooling only when ready for media creation, refresh, reinstall, session changes, or reboot.' `
                -Data ([pscustomobject]@{
                    OperationDescriptor = $descriptor
                    DownloadedPath      = [string]$descriptor.OutputPath
                    DownloadSourceUrl   = [string]$download.SourceUrl
                    ArtifactId          = [string]$download.ArtifactId
                    ProcessId           = $process.Id
                    ProcessName         = $process.ProcessName
                }) `
                -Warnings @($analysis.Warnings) `
                -ChangesExecuted $true `
                -RestartRequired $true
        }
        catch {
            return New-BoostLabReinstallResult `
                -Success $false `
                -Action 'Apply' `
                -Status 'ExecutionFailed' `
                -CommandStatus 'Failed' `
                -VerificationStatus 'Failed' `
                -Message "Reinstall Apply failed while downloading or launching the Windows 11 Media Creation Tool: $($_.Exception.Message)" `
                -Data $analysis `
                -Errors @($_.Exception.Message) `
                -Warnings @($analysis.Warnings)
        }
    }

    if ($canonicalActionName -eq 'Default') {
        return New-BoostLabReinstallResult `
            -Success $false `
            -Action 'Default' `
            -Status 'DefaultUnavailable' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Default is unavailable for Reinstall. The source defines no Default branch; Default is not Restore, and no reinstall, setup, generated-file, recovery, reboot, or system state is changed.'
    }

    if ($canonicalActionName -eq 'Restore') {
        return New-BoostLabReinstallResult `
            -Success $false `
            -Action 'Restore' `
            -Status 'RestoreUnavailable' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Restore is unavailable without approved captured reinstall, setup, generated-file, reboot/session, recovery, and support state plus a Restore contract. Default is not Restore, and no system-changing operation is planned.'
    }
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
    'Get-BoostLabReinstallOperationDescriptor'
)
