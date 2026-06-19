Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'nvidia-settings'
    Title = 'Nvidia Settings'
    Stage = 'Graphics'
    Order = 4
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Manual handoff only. Path B step 2 of 5. Prepare NVIDIA settings/profile guidance without 7-Zip download, Profile Inspector execution, .nip import/export, registry/profile mutation, external process launch, or Control Panel launch.'
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
$script:BoostLabExpectedSourceHash = '903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5'
$script:BoostLabSourceRelativePath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1'

function Get-BoostLabNvidiaSettingsSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $projectRoot ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabNvidiaSettingsSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabNvidiaSettingsSourcePath
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

function New-BoostLabNvidiaSettingsResult {
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

function Get-BoostLabNvidiaSettingsBlockedApprovals {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        '7-Zip artifact/download/install approval'
        'NVIDIA Profile Inspector artifact/download/execution approval'
        '.nip import/export approval'
        'NVIDIA profile state capture/restore approval'
        'NVIDIA registry/file rollback capture approval'
        'process handling approval'
        'verification approval'
    )
}

function Get-BoostLabNvidiaSettingsRiskWarnings {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'Original Ultimate source downloads and installs 7-Zip, downloads NVIDIA Profile Inspector, creates and imports a .nip profile, writes NVIDIA registry/profile settings, and opens NVIDIA Control Panel.'
        'This BoostLab implementation prepares manual handoff instructions only.'
        'No 7-Zip is downloaded or installed, no NVIDIA Profile Inspector is downloaded or executed, and no .nip is imported or exported.'
        'No NVIDIA profile, NVIDIA registry setting, Windows Registry value, file, external process, browser, Control Panel page, driver, reboot, or session state is changed.'
        'External manual NVIDIA profile/settings work can affect display behavior, game/app profiles, registry/profile state, and recovery options.'
        'Default and Restore are unavailable because BoostLab has no captured NVIDIA profile or registry state for this tool.'
    )
}

function Get-BoostLabNvidiaSettingsAnalysis {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabNvidiaSettingsSourceStatus
    [pscustomobject]@{
        Mode = 'ManualHandoffOnly'
        AutoMode = 'AutoBlockedUntilArtifactApproval'
        Source = $sourceStatus
        PathBWorkflow = 'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
        PathBStepNumber = 2
        PathBStepTotal = 5
        PathBStep = '2 of 5'
        MissingApprovals = @(Get-BoostLabNvidiaSettingsBlockedApprovals)
        Warnings = @(Get-BoostLabNvidiaSettingsRiskWarnings)
        NoAutomatedExecution = $true
        NoSevenZipDownloadedOrInstalled = $true
        NoProfileInspectorDownloadedOrExecuted = $true
        NoNipImportedExportedOrGeneratedForExecution = $true
        NoNvidiaProfileChanged = $true
        NoRegistrySettingChanged = $true
        NoExternalProcessStarted = $true
        NoBrowserOpened = $true
        NoNvidiaControlPanelLaunched = $true
        NoSystemMutation = $true
        PathASeparation = 'Nvidia Settings is separate from Driver Install Debloat & Settings.'
        PathBSeparation = 'Path B steps remain separate: Driver Install Latest, Nvidia Settings, Hdcp, P0 State, and Msi Mode.'
    }
}

function New-BoostLabNvidiaSettingsManualHandoffPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $analysis = Get-BoostLabNvidiaSettingsAnalysis
    [pscustomobject]@{
        PlanType = 'ManualHandoffOnly'
        SourceChecksumStatus = [string]$analysis.Source.ChecksumStatus
        PathBStep = [string]$analysis.PathBStep
        PathBWorkflow = [string]$analysis.PathBWorkflow
        Steps = @(
            'Review source checksum and blocked approvals.'
            'Prepare manual handoff instructions only for Path B step 2.'
            'Do not download or install 7-Zip.'
            'Do not download or run NVIDIA Profile Inspector.'
            'Do not import, export, or generate a .nip file for execution.'
            'Do not modify NVIDIA profiles, NVIDIA registry settings, Windows Registry values, files, drivers, sessions, or reboot state.'
            'Do not open NVIDIA Control Panel, a browser, external tool, or any external process.'
            'Tell the user that external NVIDIA profile/settings work remains manual outside BoostLab unless future explicit approval exists.'
            'Record Latest Result and Activity Log with no automated profile/settings/registry/external process action.'
        )
        BlockedActions = @(
            'Apply Auto'
            '7-Zip download/install'
            'NVIDIA Profile Inspector download/execution'
            '.nip import/export'
            'NVIDIA profile mutation'
            'NVIDIA registry mutation'
            'NVIDIA Control Panel launch'
            'browser or external process launch'
            'Default'
            'Restore'
        )
        Warnings = @($analysis.Warnings)
        MissingApprovals = @($analysis.MissingApprovals)
        NoSevenZipDownloadOrInstallOccurred = $true
        NoProfileInspectorDownloadOrExecutionOccurred = $true
        NoNipImportExportOccurred = $true
        NoRegistryOrProfileMutationOccurred = $true
        NoExternalProcessStarted = $true
        NoControlPanelOrBrowserOpened = $true
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
        ConfirmationText = 'Nvidia Settings manual handoff prepares instructions only. BoostLab will not download or install 7-Zip, download or execute NVIDIA Profile Inspector, import or export .nip files, launch NVIDIA Control Panel, start external processes, modify registry or NVIDIA profiles, or change system state. Continue preparing the manual handoff result?'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabNvidiaSettingsSourceStatus
    [pscustomobject]@{
        Supported = $true
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason = 'Nvidia Settings manual handoff is available. Auto mode remains blocked.'
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
        $analysis = Get-BoostLabNvidiaSettingsAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        $status = if ($sourceOk) { 'Analyzed' } else { 'SourceVerificationFailed' }
        $message = if ($sourceOk) {
            'Nvidia Settings analyzed. Manual handoff only; Auto remains blocked. Path B step 2 of 5.'
        }
        else {
            'Nvidia Settings source checksum verification failed or source mirror is missing.'
        }
        $errors = if ($sourceOk) {
            @()
        }
        else {
            @('Nvidia Settings source mirror checksum did not match the expected value or the source mirror is missing.')
        }

        return New-BoostLabNvidiaSettingsResult `
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
            return New-BoostLabNvidiaSettingsResult `
                -Success $false `
                -Action 'Open' `
                -Status 'Cancelled' `
                -CommandStatus 'Cancelled before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'Nvidia Settings manual handoff cancelled by user. No 7-Zip download/install, NVIDIA Profile Inspector download/execution, .nip import/export, NVIDIA Control Panel launch, external process start, registry/profile mutation, reboot, session change, or system mutation occurred.' `
                -Cancelled $true
        }

        $analysis = Get-BoostLabNvidiaSettingsAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        if (-not $sourceOk) {
            return New-BoostLabNvidiaSettingsResult `
                -Success $false `
                -Action 'Open' `
                -Status 'SourceVerificationFailed' `
                -CommandStatus 'Blocked before handoff' `
                -VerificationStatus ([string]$analysis.Source.ChecksumStatus) `
                -Message 'Nvidia Settings manual handoff blocked because source checksum verification failed or the source mirror is missing.' `
                -Data $analysis `
                -Errors @('Nvidia Settings source mirror checksum did not match the expected value or the source mirror is missing.')
        }

        $plan = New-BoostLabNvidiaSettingsManualHandoffPlan
        return New-BoostLabNvidiaSettingsResult `
            -Success $true `
            -Action 'Open' `
            -Status 'ManualHandoffPrepared' `
            -CommandStatus 'No execution performed' `
            -VerificationStatus 'Passed' `
            -Message 'Manual handoff prepared. No 7-Zip downloaded or installed, no NVIDIA Profile Inspector downloaded or executed, no .nip imported or exported, no NVIDIA Control Panel launched, no external process started, no NVIDIA profile or registry setting changed, and no system mutation occurred. Path B step 2 remains separate from the remaining Path B steps.' `
            -Data $plan
    }

    if ($canonicalActionName -eq 'Apply') {
        $analysis = Get-BoostLabNvidiaSettingsAnalysis
        return New-BoostLabNvidiaSettingsResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'AutoBlockedUntilArtifactApproval' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Blocked' `
            -Message 'AutoBlockedUntilArtifactApproval. Auto mode is blocked until 7-Zip artifact/download/install approval, NVIDIA Profile Inspector artifact/download/execution approval, .nip import/export approval, NVIDIA profile state capture/restore approval, NVIDIA registry/file rollback capture approval, process handling approval, and verification approval exist. No 7-Zip download/install, Profile Inspector execution, .nip import/export, registry/profile mutation, external process launch, Control Panel launch, or system-changing operation occurred.' `
            -Data $analysis
    }

    if ($canonicalActionName -in @('Default', 'Restore')) {
        return New-BoostLabNvidiaSettingsResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'Unavailable' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message "$canonicalActionName is unavailable for Nvidia Settings manual handoff. Default is not Restore, and Restore requires real captured NVIDIA profile or registry state that does not exist."
    }

    return New-BoostLabNvidiaSettingsResult `
        -Success $false `
        -Action $canonicalActionName `
        -Status 'Unsupported' `
        -CommandStatus 'Refused before execution' `
        -VerificationStatus 'NotApplicable' `
        -Message 'Unsupported Nvidia Settings action. Only Analyze, Open (Manual Handoff), and Apply (Apply Auto blocked) are exposed.'
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
