Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'reinstall'
    Title = 'Reinstall'
    Stage = 'Refresh'
    Order = 1
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Controlled manual handoff only. Analyze the source-defined Windows reinstall workflow without automated downloads, Media Creation Tool launch, setup execution, file mutation, reboot, recovery, or external process behavior.'
    Actions = @('Analyze', 'Open', 'Apply', 'Default', 'Restore')
    Capabilities = [ordered]@{
        RequiresAdmin             = $false
        RequiresInternet          = $false
        CanReboot                 = $false
        CanModifyRegistry         = $false
        CanModifyServices         = $false
        CanInstallSoftware        = $false
        CanDownload               = $false
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
$script:BoostLabSourceRelativePath = 'source-ultimate/2 Refresh/1 Reinstall.ps1'

function Get-BoostLabReinstallSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $projectRoot ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabReinstallSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabReinstallSourcePath
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

        [bool]$Cancelled = $false
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
        ChangesExecuted    = $false
        Timestamp          = Get-Date
        Data               = $Data
        Warnings           = @($Warnings)
        Errors             = @($Errors)
    }
}

function Get-BoostLabReinstallBlockedApprovals {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'Windows 11 Media Creation Tool artifact provenance approval'
        'Media Creation Tool SHA-256, size, signer, version, and redistributability approval'
        'Media Creation Tool executable launch descriptor approval'
        'Generated Windows Temp executable path ownership and cleanup approval'
        'Reinstall, refresh, setup, reboot/session, and recovery workflow approval'
        'Windows 10 Media Creation Tool branch product-scope approval'
    )
}

function Get-BoostLabReinstallRiskWarnings {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'Original Ultimate source requires Administrator and internet access.'
        'Original Ultimate source offers a Windows 10 Media Creation Tool branch, which remains unsupported by BoostLab product scope.'
        'Original Ultimate source downloads Windows 10 and Windows 11 Media Creation Tool executables from mutable branch URLs.'
        'Original Ultimate source launches the downloaded executable from the Windows Temp directory.'
        'No SHA-256, size, signer, version, redistributability, executable launch, generated-file ownership, reboot/session, recovery, or support approval exists for automated Reinstall behavior.'
        'This BoostLab implementation prepares manual handoff instructions only and performs no automated download, installer launch, setup execution, file mutation, reboot, recovery, or system mutation.'
    )
}

function Get-BoostLabReinstallAnalysis {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabReinstallSourceStatus
    [pscustomobject]@{
        Mode                         = 'ManualHandoffOnly'
        AutoMode                     = 'AutoBlockedUntilArtifactApproval'
        SupportedTarget              = 'Windows 11 reinstall/refresh outcome only'
        UnsupportedBranches          = @('Windows 10 Media Creation Tool branch')
        Source                       = $sourceStatus
        SourceBehaviorSummary        = @(
            'Checks for Administrator rights and internet connectivity.'
            'Presents Windows 10 and Windows 11 reinstall menu choices.'
            'Windows 10 branch downloads mediacreationtoolw10.exe from the Ultimate-Files mirror into Windows Temp and launches it.'
            'Windows 11 branch downloads mediacreationtoolw11.exe from the Ultimate-Files mirror into Windows Temp and launches it.'
            'The source does not directly run setup.exe, mount an ISO, write registry values, delete files, call shutdown, or pass installer switches.'
            'The downloaded Media Creation Tool can hand off to Windows setup, media creation, refresh, or reinstall behavior outside current BoostLab approvals.'
        )
        SupportedManualHandoffScope  = @(
            'Display source identity, checksum status, source behavior, missing approvals, and Windows 11 target scope.'
            'Prepare guidance inside BoostLab only.'
            'Do not open browser, Explorer, Settings, Media Creation Tool, setup, external apps, or external tools.'
            'Do not download, create, delete, mutate, reboot, or launch anything.'
        )
        MissingApprovals             = @(Get-BoostLabReinstallBlockedApprovals)
        Warnings                     = @(Get-BoostLabReinstallRiskWarnings)
        NoAutomatedExecution         = $true
        NoDownloadOccurred           = $true
        NoInstallerExecutionOccurred = $true
        NoSetupExecutionOccurred     = $true
        NoExternalProcessStarted     = $true
        NoFileMutationOccurred       = $true
        NoRegistryMutationOccurred   = $true
        NoServiceMutationOccurred    = $true
        NoPackageMutationOccurred    = $true
        NoDeviceMutationOccurred     = $true
        NoDriverMutationOccurred     = $true
        NoRecoveryWorkflowStarted    = $true
        NoRebootOccurred             = $true
        NoSystemMutationOccurred     = $true
    }
}

function New-BoostLabReinstallManualHandoffPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $analysis = Get-BoostLabReinstallAnalysis
    [pscustomobject]@{
        PlanType                     = 'ManualHandoffOnly'
        SourceChecksumStatus         = [string]$analysis.Source.ChecksumStatus
        SupportedTarget              = [string]$analysis.SupportedTarget
        UnsupportedBranches          = @($analysis.UnsupportedBranches)
        Steps                        = @(
            'Review source checksum and blocked reinstall/media approvals.'
            'Prepare manual handoff instructions inside BoostLab only.'
            'Do not open a browser, Explorer, Settings, Media Creation Tool, setup executable, installer, recovery tool, or any external tool.'
            'Do not download Windows media, Media Creation Tool executables, installers, setup files, ISOs, scripts, or artifacts.'
            'Do not create, delete, or mutate setup files, media folders, temp files, boot files, recovery files, partitions, registry, services, scheduled tasks, packages, devices, or drivers.'
            'Do not start setup, media creation, repair, refresh, recovery, or reinstall workflows.'
            'Do not reboot or change session state.'
            'Explain that Auto remains blocked until Windows 11 artifact provenance, executable launch descriptors, generated-file ownership, reboot/session, recovery, and support approvals exist.'
            'Record Latest Result and Activity Log with no automated execution.'
        )
        BlockedActions               = @(
            'Apply Auto'
            'Windows 10 Media Creation Tool branch'
            'Windows 11 Media Creation Tool download'
            'Media Creation Tool executable launch'
            'setup execution'
            'media creation workflow'
            'refresh or reinstall workflow'
            'generated Windows Temp executable file mutation'
            'reboot or session handoff'
            'Default'
            'Restore'
        )
        Warnings                     = @($analysis.Warnings)
        MissingApprovals             = @($analysis.MissingApprovals)
        NoDownloadOccurred           = $true
        NoInstallerExecutionOccurred = $true
        NoSetupExecutionOccurred     = $true
        NoExternalProcessStarted     = $true
        NoFileMutationOccurred       = $true
        NoRegistryMutationOccurred   = $true
        NoRecoveryWorkflowStarted    = $true
        NoRebootOccurred             = $true
        NoSystemMutationOccurred     = $true
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
        ConfirmationRequiredActions = @('Open', 'Apply')
        ConfirmationText            = 'Reinstall manual handoff prepares instructions only. BoostLab will not open external tools, download Media Creation Tool artifacts, run setup, mutate files, registry, services, packages, devices, or drivers, start recovery, or reboot. Continue preparing the manual handoff result?'
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
        Reason               = 'Reinstall manual handoff is available for the Windows 11 target outcome. Auto mode remains blocked.'
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
        Status          = 'ManualHandoffOnly'
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
            'Reinstall analyzed. Manual handoff only; Auto remains blocked until exact Windows 11 artifact provenance, executable launch, generated-file ownership, reboot/session, recovery, and support approvals exist.'
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
            -Errors $errors
    }

    if ($canonicalActionName -eq 'Open') {
        if (-not $Confirmed) {
            return New-BoostLabReinstallResult `
                -Success $false `
                -Action 'Open' `
                -Status 'Cancelled' `
                -CommandStatus 'Cancelled before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'Reinstall manual handoff cancelled by user. No browser, Explorer, Settings, external tool, download, setup, file mutation, registry/service/package/device/driver mutation, recovery workflow, reboot, or system mutation occurred.' `
                -Cancelled $true
        }

        $analysis = Get-BoostLabReinstallAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        if (-not $sourceOk) {
            return New-BoostLabReinstallResult `
                -Success $false `
                -Action 'Open' `
                -Status 'SourceVerificationFailed' `
                -CommandStatus 'Blocked before handoff' `
                -VerificationStatus ([string]$analysis.Source.ChecksumStatus) `
                -Message 'Reinstall manual handoff blocked because source checksum verification failed or the source file is missing.' `
                -Data $analysis `
                -Errors @('Reinstall source checksum did not match the expected value or the source file is missing.')
        }

        $plan = New-BoostLabReinstallManualHandoffPlan
        return New-BoostLabReinstallResult `
            -Success $true `
            -Action 'Open' `
            -Status 'ManualHandoffPrepared' `
            -CommandStatus 'No execution performed' `
            -VerificationStatus 'Passed' `
            -Message 'Manual handoff prepared. No browser, Explorer, Settings, external tool, Windows media download, Media Creation Tool launch, setup command, file mutation, registry/service/package/device/driver mutation, recovery workflow, reboot, or system mutation occurred.' `
            -Data $plan
    }

    if ($canonicalActionName -eq 'Apply') {
        $analysis = Get-BoostLabReinstallAnalysis
        return New-BoostLabReinstallResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'AutoBlockedUntilArtifactApproval' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Blocked' `
            -Message 'AutoBlockedUntilArtifactApproval. Auto mode is blocked until exact Windows 11 Media Creation Tool artifact provenance, executable launch descriptor, generated-file ownership, reboot/session, recovery, and support approvals exist. No download, setup, executable launch, file mutation, registry/service/package/device/driver mutation, recovery workflow, reboot, or system mutation occurred.' `
            -Data $analysis
    }

    if ($canonicalActionName -eq 'Default') {
        return New-BoostLabReinstallResult `
            -Success $false `
            -Action 'Default' `
            -Status 'DefaultUnavailable' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Default is unavailable for Reinstall manual handoff. The source does not define a safe Default branch; Default is not Restore, and no download, setup, file, registry, service, package, device, driver, reboot, recovery, or system state is changed.'
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
)
