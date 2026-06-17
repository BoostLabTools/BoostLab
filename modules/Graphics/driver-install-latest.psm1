Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'driver-install-latest'
    Title = 'Driver Install Latest'
    Stage = 'Graphics'
    Order = 2
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Manual handoff only. Path B step 1 of 5. Prepare NVIDIA driver install guidance without automated download, installer execution, external process launch, driver mutation, or reboot.'
    Actions = @('Analyze', 'Open', 'Apply')
    Capabilities = [ordered]@{
        RequiresAdmin = $false
        RequiresInternet = $false
        CanReboot = $false
        CanModifyRegistry = $false
        CanModifyServices = $false
        CanInstallSoftware = $false
        CanDownload = $false
        CanModifyDrivers = $false
        CanModifySecurity = $false
        CanDeleteFiles = $false
        UsesTrustedInstaller = $false
        UsesSafeMode = $false
        SupportsDefault = $false
        SupportsRestore = $false
        NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Analyze', 'Open', 'Apply')
$script:BoostLabExpectedSourceHash = '41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F'
$script:BoostLabSourceRelativePath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1'

function Get-BoostLabDriverInstallLatestSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $projectRoot ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabDriverInstallLatestSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabDriverInstallLatestSourcePath
    $exists = Test-Path -LiteralPath $sourcePath -PathType Leaf
    $detectedHash = if ($exists) {
        (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
    }
    else {
        ''
    }

    [pscustomobject]@{
        SourcePath = $sourcePath
        SourceRelativePath = $script:BoostLabSourceRelativePath
        Exists = $exists
        ExpectedSha256 = $script:BoostLabExpectedSourceHash
        DetectedSha256 = $detectedHash
        ChecksumStatus = if ($exists -and $detectedHash -eq $script:BoostLabExpectedSourceHash) {
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

function New-BoostLabDriverInstallLatestResult {
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
        ChangesExecuted = $false
        Timestamp = Get-Date
        Data = $Data
        Warnings = @($Warnings)
        Errors = @($Errors)
    }
}

function Get-BoostLabDriverInstallLatestBlockedApprovals {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'NVIDIA driver artifact/download approval'
        'NVIDIA installer execution descriptor approval'
        'Driver state capture/rollback approval'
        'Process handoff approval'
        'Reboot/session handling approval'
        'Recovery handling approval'
    )
}

function Get-BoostLabDriverInstallLatestRiskWarnings {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'Original Ultimate source downloads the latest NVIDIA driver and launches the installer.'
        'AMD and Intel source branches are outside the NVIDIA-only product scope and remain unsupported.'
        'This BoostLab implementation prepares manual handoff instructions only.'
        'No NVIDIA driver is downloaded, no installer is executed, and no external process is started.'
        'Driver installation can interrupt display output, fail, require network access, or require a reboot/session recovery plan.'
        'Default and Restore are unavailable because no captured driver state exists.'
    )
}

function Get-BoostLabDriverInstallLatestAnalysis {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabDriverInstallLatestSourceStatus
    [pscustomobject]@{
        Mode = 'ManualHandoffOnly'
        AutoMode = 'AutoBlockedUntilArtifactApproval'
        Source = $sourceStatus
        PathBWorkflow = 'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
        PathBStepNumber = 1
        PathBStepTotal = 5
        PathBStep = '1 of 5'
        MissingApprovals = @(Get-BoostLabDriverInstallLatestBlockedApprovals)
        Warnings = @(Get-BoostLabDriverInstallLatestRiskWarnings)
        NoAutomatedExecution = $true
        NoNvidiaDriverDownloaded = $true
        NoNvidiaInstallerExecuted = $true
        NoSevenZipDownloaded = $true
        NoExternalProcessStarted = $true
        NoBrowserOpened = $true
        NoRegistryDriverRebootOrSessionChange = $true
        PathASeparation = 'Driver Install Latest is separate from Driver Install Debloat & Settings.'
        PathBSeparation = 'Path B steps remain separate: Driver Install Latest, Nvidia Settings, Hdcp, P0 State, and Msi Mode.'
    }
}

function New-BoostLabDriverInstallLatestManualHandoffPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $analysis = Get-BoostLabDriverInstallLatestAnalysis
    [pscustomobject]@{
        PlanType = 'ManualHandoffOnly'
        SourceChecksumStatus = [string]$analysis.Source.ChecksumStatus
        PathBStep = [string]$analysis.PathBStep
        PathBWorkflow = [string]$analysis.PathBWorkflow
        Steps = @(
            'Review source checksum and blocked approvals.'
            'Prepare manual handoff instructions only.'
            'Do not open a browser, external tool, NVIDIA installer, or any external process.'
            'Do not download an NVIDIA driver or 7-Zip.'
            'Do not execute an NVIDIA installer.'
            'Do not modify registry, drivers, services, files, sessions, or reboot state.'
            'Tell the user that any NVIDIA driver download and installation remains manual outside BoostLab unless future approval exists.'
            'Record Latest Result and Activity Log with no automated execution.'
        )
        BlockedActions = @(
            'Apply Auto'
            'NVIDIA driver download'
            'NVIDIA installer execution'
            '7-Zip download'
            'external process launch'
            'driver mutation'
            'registry mutation'
            'reboot'
            'session change'
            'Default'
            'Restore'
        )
        Warnings = @($analysis.Warnings)
        MissingApprovals = @($analysis.MissingApprovals)
        NoNvidiaDriverDownloadOccurred = $true
        NoNvidiaInstallerExecutionOccurred = $true
        NoExternalProcessStarted = $true
        NoRebootOrSessionChangeOccurred = $true
    }
}

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
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
        ConfirmationRequiredActions = @('Open', 'Apply')
        ConfirmationText = 'Driver Install Latest manual handoff prepares instructions only. BoostLab will not download an NVIDIA driver, execute an installer, open a browser or external process, modify drivers or registry, change the session, or reboot. Continue preparing the manual handoff result?'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabDriverInstallLatestSourceStatus
    [pscustomobject]@{
        Supported = $true
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason = 'Driver Install Latest manual handoff is available. Auto mode remains blocked.'
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
        Status = 'ManualHandoffOnly'
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

        [bool]$Confirmed = $false
    )

    $canonicalActionName = switch ($ActionName) {
        'Prepare Manual Handoff' { 'Open' }
        'Manual Handoff' { 'Open' }
        'Apply Auto' { 'Apply' }
        default { $ActionName }
    }

    if ($canonicalActionName -eq 'Analyze') {
        $analysis = Get-BoostLabDriverInstallLatestAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        $status = if ($sourceOk) { 'Analyzed' } else { 'SourceVerificationFailed' }
        $message = if ($sourceOk) {
            'Driver Install Latest analyzed. Manual handoff only; Auto remains blocked. Path B step 1 of 5.'
        }
        else {
            'Driver Install Latest source checksum verification failed or source mirror is missing.'
        }
        $errors = if ($sourceOk) {
            @()
        }
        else {
            @('Driver Install Latest source mirror checksum did not match the expected value or the source mirror is missing.')
        }

        return New-BoostLabDriverInstallLatestResult `
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
            return New-BoostLabDriverInstallLatestResult `
                -Success $false `
                -Action 'Open' `
                -Status 'Cancelled' `
                -CommandStatus 'Cancelled before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'Driver Install Latest manual handoff cancelled by user. No NVIDIA driver download, installer execution, browser opening, external process start, registry/system/driver mutation, reboot, or session change occurred.' `
                -Cancelled $true
        }

        $analysis = Get-BoostLabDriverInstallLatestAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        if (-not $sourceOk) {
            return New-BoostLabDriverInstallLatestResult `
                -Success $false `
                -Action 'Open' `
                -Status 'SourceVerificationFailed' `
                -CommandStatus 'Blocked before handoff' `
                -VerificationStatus ([string]$analysis.Source.ChecksumStatus) `
                -Message 'Driver Install Latest manual handoff blocked because source checksum verification failed or the source mirror is missing.' `
                -Data $analysis `
                -Errors @('Driver Install Latest source mirror checksum did not match the expected value or the source mirror is missing.')
        }

        $plan = New-BoostLabDriverInstallLatestManualHandoffPlan
        return New-BoostLabDriverInstallLatestResult `
            -Success $true `
            -Action 'Open' `
            -Status 'ManualHandoffPrepared' `
            -CommandStatus 'No execution performed' `
            -VerificationStatus 'Passed' `
            -Message 'Manual handoff prepared. No NVIDIA driver downloaded, no installer executed, no browser opened, no external process started, no registry/system/driver mutation occurred, and no reboot or session change occurred. Path B step 1 remains separate from the remaining Path B steps.' `
            -Data $plan
    }

    if ($canonicalActionName -eq 'Apply') {
        $analysis = Get-BoostLabDriverInstallLatestAnalysis
        return New-BoostLabDriverInstallLatestResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'AutoBlockedUntilArtifactApproval' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Blocked' `
            -Message 'AutoBlockedUntilArtifactApproval. Auto mode is blocked until NVIDIA driver artifact/download approval, installer execution descriptor approval, driver state capture/rollback approval, process handoff approval, reboot/session handling approval, and recovery handling approval exist. No automated NVIDIA driver download, installer execution, external process launch, registry/system/driver mutation, reboot, or session change occurred.' `
            -Data $analysis
    }

    if ($canonicalActionName -in @('Default', 'Restore')) {
        return New-BoostLabDriverInstallLatestResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'Unavailable' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message "$canonicalActionName is unavailable for Driver Install Latest manual handoff. Default is not Restore, and Restore requires real captured driver state that does not exist."
    }

    return New-BoostLabDriverInstallLatestResult `
        -Success $false `
        -Action $canonicalActionName `
        -Status 'Unsupported' `
        -CommandStatus 'Refused before execution' `
        -VerificationStatus 'NotApplicable' `
        -Message 'Unsupported Driver Install Latest action. Only Analyze, Open (Manual Handoff), and Apply (Apply Auto blocked) are exposed.'
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
