Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'driver-clean'
    Title = 'Driver Clean'
    Stage = 'Graphics'
    Order = 1
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Manual handoff only. Prepare a controlled manual handoff for driver cleanup. No automated DDU download, DDU execution, Safe Mode, RunOnce, reboot, or driver cleanup is performed.'
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
$script:BoostLabExpectedSourceHash = 'CF9E1C55ACAFD8A52D2200AC3E6C3AFDF9823837C7B68101C2D4B83E074D325A'
$script:BoostLabSourceRelativePath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/1 Driver Clean.ps1'

function Get-BoostLabDriverCleanSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $projectRoot ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabDriverCleanSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabDriverCleanSourcePath
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

function New-BoostLabDriverCleanResult {
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

function Get-BoostLabDriverCleanBlockedApprovals {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'DDU artifact/download approval'
        '7-Zip artifact/download approval'
        'Process handling approval for DDU'
        'Safe Mode/RunOnce/reboot approval'
        'Recovery handling approval'
    )
}

function Get-BoostLabDriverCleanRiskWarnings {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'Original Ultimate source contains DDU download and execution behavior.'
        'Original Ultimate source contains 7-Zip download and installer behavior.'
        'Original Ultimate source contains Safe Mode, RunOnce, bcdedit, reboot, and driver cleanup behavior.'
        'This BoostLab implementation does not perform those operations.'
        'External driver-cleaning must remain manual unless a future explicit approval exists.'
        'Default and Restore are unavailable because no captured driver state exists.'
    )
}

function Get-BoostLabDriverCleanAnalysis {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabDriverCleanSourceStatus
    [pscustomobject]@{
        Mode = 'ManualHandoffOnly'
        AutoMode = 'AutoBlockedUntilArtifactApproval'
        Source = $sourceStatus
        MissingApprovals = @(Get-BoostLabDriverCleanBlockedApprovals)
        Warnings = @(Get-BoostLabDriverCleanRiskWarnings)
        NoAutomatedExecution = $true
        NoDduDownloaded = $true
        NoDduExecuted = $true
        NoSevenZipDownloaded = $true
        NoExternalProcessStarted = $true
        NoRegistryBootRunOnceOrRebootChange = $true
        PathBRelationship = 'Driver Clean remains separate from Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode.'
    }
}

function New-BoostLabDriverCleanManualHandoffPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $analysis = Get-BoostLabDriverCleanAnalysis
    [pscustomobject]@{
        PlanType = 'ManualHandoffOnly'
        SourceChecksumStatus = [string]$analysis.Source.ChecksumStatus
        Steps = @(
            'Review source checksum and blocked approvals.'
            'Prepare manual handoff instructions only.'
            'Warn that BoostLab will not download DDU or 7-Zip.'
            'Warn that BoostLab will not run DDU or start external processes.'
            'Warn that BoostLab will not create RunOnce, change Safe Mode, call bcdedit, or reboot.'
            'Tell the user any external driver-cleaning process must be handled manually outside BoostLab unless future approval exists.'
            'Record Latest Result and Activity Log with no automated execution.'
        )
        BlockedActions = @(
            'Apply Auto'
            'DDU download'
            'DDU execution'
            '7-Zip download'
            '7-Zip installation'
            'RunOnce creation'
            'Safe Mode switch'
            'bcdedit call'
            'reboot'
            'registry mutation'
            'driver cleanup execution'
            'Default'
            'Restore'
        )
        Warnings = @($analysis.Warnings)
        MissingApprovals = @($analysis.MissingApprovals)
        NoAutomatedDduExecutionOccurred = $true
        NoAutomatedDduDownloadOccurred = $true
        NoAutomatedRebootOccurred = $true
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
        ConfirmationText = 'Driver Clean manual handoff does not run DDU, download DDU or 7-Zip, modify registry, create RunOnce, enter Safe Mode, call bcdedit, reboot, or clean drivers. Continue preparing the manual handoff result?'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabDriverCleanSourceStatus
    [pscustomobject]@{
        Supported = $true
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason = 'Driver Clean manual handoff is available. Auto mode remains blocked.'
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
        $analysis = Get-BoostLabDriverCleanAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        $status = if ($sourceOk) { 'Analyzed' } else { 'SourceVerificationFailed' }
        $message = if ($sourceOk) {
            'Driver Clean analyzed. Manual handoff only; Auto remains blocked.'
        }
        else {
            'Driver Clean source checksum verification failed or source mirror is missing.'
        }
        $errors = if ($sourceOk) {
            @()
        }
        else {
            @('Driver Clean source mirror checksum did not match the expected value or the source mirror is missing.')
        }

        return New-BoostLabDriverCleanResult `
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
            return New-BoostLabDriverCleanResult `
                -Success $false `
                -Action 'Open' `
                -Status 'Cancelled' `
                -CommandStatus 'Cancelled before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'Driver Clean manual handoff cancelled by user. No automated DDU execution, download, RunOnce, Safe Mode, bcdedit, reboot, registry change, or driver cleanup occurred.' `
                -Cancelled $true
        }

        $analysis = Get-BoostLabDriverCleanAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        if (-not $sourceOk) {
            return New-BoostLabDriverCleanResult `
                -Success $false `
                -Action 'Open' `
                -Status 'SourceVerificationFailed' `
                -CommandStatus 'Blocked before handoff' `
                -VerificationStatus ([string]$analysis.Source.ChecksumStatus) `
                -Message 'Driver Clean manual handoff blocked because source checksum verification failed or the source mirror is missing.' `
                -Data $analysis `
                -Errors @('Driver Clean source mirror checksum did not match the expected value or the source mirror is missing.')
        }

        $plan = New-BoostLabDriverCleanManualHandoffPlan
        return New-BoostLabDriverCleanResult `
            -Success $true `
            -Action 'Open' `
            -Status 'ManualHandoffPrepared' `
            -CommandStatus 'No execution performed' `
            -VerificationStatus 'Passed' `
            -Message 'Manual handoff prepared. No automated DDU execution, DDU download, 7-Zip download, external process start, registry change, RunOnce creation, bcdedit call, Safe Mode switch, reboot, or driver cleanup occurred.' `
            -Data $plan
    }

    if ($canonicalActionName -eq 'Apply') {
        $analysis = Get-BoostLabDriverCleanAnalysis
        return New-BoostLabDriverCleanResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'AutoBlockedUntilArtifactApproval' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Blocked' `
            -Message 'AutoBlockedUntilArtifactApproval. Auto DDU remains blocked until DDU/7-Zip artifact, download, process, Safe Mode, RunOnce, bcdedit, reboot/recovery, generated-script, and driver-state approvals exist.' `
            -Data $analysis
    }

    if ($canonicalActionName -in @('Default', 'Restore')) {
        return New-BoostLabDriverCleanResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'Unavailable' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message "$canonicalActionName is unavailable for Driver Clean manual handoff. Default is not Restore, and Restore requires real captured state that does not exist for external DDU actions."
    }

    return New-BoostLabDriverCleanResult `
        -Success $false `
        -Action $canonicalActionName `
        -Status 'Unsupported' `
        -CommandStatus 'Refused before execution' `
        -VerificationStatus 'NotApplicable' `
        -Message 'Unsupported Driver Clean action. Only Analyze, Open (Manual Handoff), and Apply (Apply Auto blocked) are exposed.'
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
