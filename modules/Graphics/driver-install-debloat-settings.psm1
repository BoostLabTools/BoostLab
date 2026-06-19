Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'driver-install-debloat-settings'
    Title = 'Driver Install Debloat & Settings'
    Stage = 'Graphics'
    Order = 2
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Manual handoff only. Analyze the source-defined NVIDIA/AMD/Intel driver install/debloat workflow without automated downloads, installer execution, external process launch, driver mutation, cleanup, profile import, registry changes, or reboot.'
    Actions = @('Analyze', 'Open', 'Apply', 'Default', 'Restore')
    Capabilities = [ordered]@{
        RequiresAdmin              = $false
        RequiresInternet           = $false
        CanReboot                  = $false
        CanModifyRegistry          = $false
        CanModifyServices          = $true
        CanInstallSoftware         = $false
        CanDownload                = $false
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

$script:BoostLabImplementedActions = @('Analyze', 'Open', 'Apply', 'Default', 'Restore')
$script:BoostLabExpectedSourceHash = 'E69EFF538E7CE6108233C525A2BB88BA2D549CE6954AE751BE7BED778271C26F'
$script:BoostLabSourceRelativePath = 'source-ultimate/5 Graphics/1 Driver Install Debloat & Settings.ps1'

function Get-BoostLabDriverInstallDebloatSettingsSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $projectRoot ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabDriverInstallDebloatSettingsSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabDriverInstallDebloatSettingsSourcePath
    $exists = Test-Path -LiteralPath $sourcePath -PathType Leaf
    $detectedHash = if ($exists) {
        (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
    }
    else {
        ''
    }

    [pscustomobject]@{
        SourcePath       = $sourcePath
        SourceRelativePath = $script:BoostLabSourceRelativePath
        Exists           = $exists
        ExpectedSha256   = $script:BoostLabExpectedSourceHash
        DetectedSha256   = $detectedHash
        ChecksumStatus   = if ($exists -and $detectedHash -eq $script:BoostLabExpectedSourceHash) {
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

function New-BoostLabDriverInstallDebloatSettingsResult {
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

function Get-BoostLabDriverInstallDebloatSettingsBlockedApprovals {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        '7-Zip artifact/download/installer approval'
        'NVIDIA driver artifact or user-selected installer validation approval'
        'NVIDIA installer execution descriptor approval'
        'NVIDIA driver extraction and generated-temp-path approval'
        'NVIDIA driver component deletion/debloat cleanup scope approval'
        'NVIDIA Control Panel winget/AppX/package approval'
        'NVIDIA Profile Inspector artifact/execution/profile-import approval'
        'NVIDIA driver registry/profile scope approval'
        'AMD driver artifact or user-selected installer validation approval'
        'AMD installer execution descriptor approval'
        'AMD XML/JSON edit, service/task/process, cleanup, registry, and driver-state approval'
        'Intel driver artifact or user-selected installer validation approval'
        'Intel installer execution descriptor approval'
        'Intel service/process, cleanup, registry, and driver-state approval'
        'Driver state capture/rollback approval'
        'Process handling approval'
        'Reboot/session handling approval'
        'Recovery handling approval'
    )
}

function Get-BoostLabDriverInstallDebloatSettingsRiskWarnings {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'Original Ultimate source downloads and installs 7-Zip.'
        'Original Ultimate source opens vendor driver pages and expects a downloaded installer selection.'
        'Original Ultimate source extracts NVIDIA driver files, removes many driver components, and launches setup.exe with silent install switches.'
        'Original Ultimate source uses winget/AppX behavior for NVIDIA Control Panel and removes a Winget source package.'
        'Original Ultimate source writes NVIDIA registry/profile settings, imports a Profile Inspector .nip file, changes MSI mode, and restarts the PC.'
        'Phase 122 approves NVIDIA, AMD, and Intel source branches for this tool only; project-wide AMD/Intel GPU scope remains unchanged.'
        'This BoostLab implementation prepares manual handoff instructions only and performs no automated driver, file, registry, service, profile, process, download, installer, or reboot operation.'
        'Default and Restore are unavailable because no captured driver/profile/package/registry/file/reboot state exists.'
    )
}

function Get-BoostLabDriverInstallDebloatSettingsAnalysis {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabDriverInstallDebloatSettingsSourceStatus
    [pscustomobject]@{
        Mode                               = 'ManualHandoffOnly'
        AutoMode                           = 'AutoBlockedUntilArtifactApproval'
        Source                             = $sourceStatus
        SourceBehaviorSummary              = @(
            'Installs/configures 7-Zip from the Ultimate-Files mirror.'
            'Offers NVIDIA, AMD, and Intel source branches; Phase 122 approves all three branches for this tool only.'
            'NVIDIA branch opens the NVIDIA driver page, requires user-selected installer input, extracts with 7-Zip, removes source-defined driver components, runs setup.exe silently, installs NVIDIA Control Panel through winget, removes Winget source package, writes NVIDIA registry/profile settings, imports Profile Inspector .nip data, adjusts MSI mode, opens display/NVIDIA/sound interfaces, and restarts.'
            'AMD branch opens the AMD driver page, requires user-selected installer input, extracts with 7-Zip, edits AMD XML/JSON files, runs ATISetup.exe, removes source-defined AMD startup/task/service/driver/file targets, writes AMD registry settings, opens/closes Radeon Software, and participates in shared post-branch restart behavior.'
            'Intel branch opens the Intel driver page, requires user-selected installer input, extracts with 7-Zip, runs the Intel installer and optional Intel Graphics Software installer, removes source-defined Intel startup/service/driver/process/file targets, writes Intel registry settings, and participates in shared post-branch restart behavior.'
        )
        SupportedScope                     = 'NVIDIA/AMD/Intel branch scope approved for this tool only; current runtime remains manual handoff only'
        ApprovedSourceBranches             = @('NVIDIA', 'AMD', 'INTEL')
        UnsupportedBranches                = @()
        ToolSpecificBranchScopeDecision    = 'Phase 122: Yazan approved all source-defined NVIDIA, AMD, and INTEL branches for Driver Install Debloat & Settings only. This does not expand project-wide AMD/Intel GPU scope.'
        MissingApprovals                   = @(Get-BoostLabDriverInstallDebloatSettingsBlockedApprovals)
        Warnings                           = @(Get-BoostLabDriverInstallDebloatSettingsRiskWarnings)
        NoAutomatedExecution               = $true
        NoDownloadOccurred                 = $true
        NoInstallerExecutionOccurred       = $true
        NoExternalProcessStarted           = $true
        NoDriverMutationOccurred           = $true
        NoRegistryMutationOccurred         = $true
        NoFileCleanupOccurred              = $true
        NoServiceMutationOccurred          = $true
        NoProfileImportOccurred            = $true
        NoAppxOrWingetMutationOccurred     = $true
        NoRebootOrSessionChangeOccurred    = $true
        PathASeparation                    = 'Driver Install Debloat & Settings is separate from Driver Clean and NVIDIA Path B.'
        PathBSeparation                    = 'NVIDIA Path B remains separate and ordered: Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode.'
    }
}

function New-BoostLabDriverInstallDebloatSettingsManualHandoffPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $analysis = Get-BoostLabDriverInstallDebloatSettingsAnalysis
    [pscustomobject]@{
        PlanType                         = 'ManualHandoffOnly'
        SourceChecksumStatus             = [string]$analysis.Source.ChecksumStatus
        SupportedScope                   = [string]$analysis.SupportedScope
        UnsupportedBranches              = @($analysis.UnsupportedBranches)
        Steps                            = @(
            'Review source checksum and blocked approvals.'
            'Prepare manual handoff instructions inside BoostLab only.'
            'Do not open browser, vendor driver pages, vendor control panels, winget, 7-Zip installer, Profile Inspector, setup.exe, ATISetup.exe, Intel Installer.exe, or any external tool.'
            'Do not download 7-Zip, NVIDIA/AMD/Intel driver artifacts, Profile Inspector, .nip files, or package content.'
            'Do not extract driver packages, delete driver components, edit AMD XML/JSON files, run setup.exe/ATISetup.exe/Intel Installer.exe, import profiles, install vendor control panels, remove AppX/winget packages, stop/delete services or drivers, unregister tasks, or stop vendor processes.'
            'Do not modify registry, services, drivers, files, profiles, display settings, sound settings, sessions, or reboot state.'
            'Explain that NVIDIA, AMD, and INTEL branches are approved for this tool only but remain manual outside BoostLab until exact artifact, installer, driver-state, process, cleanup, AppX/package, profile, registry, service/task, reboot, and recovery approvals/descriptors exist.'
            'Record Latest Result and Activity Log with no automated execution.'
        )
        BlockedActions                   = @(
            'Apply Auto'
            '7-Zip download'
            '7-Zip installation'
            'vendor driver page/browser launch'
            'NVIDIA/AMD/Intel driver download'
            'driver installer selection automation'
            'driver extraction'
            'driver component deletion/debloat'
            'NVIDIA setup.exe execution'
            'AMD ATISetup.exe execution'
            'Intel installer execution'
            'winget execution'
            'AppX/package removal'
            'service/driver deletion'
            'scheduled task deletion'
            'process stop'
            'Profile Inspector execution'
            '.nip profile import'
            'registry mutation'
            'service mutation'
            'driver mutation'
            'display or sound panel launch'
            'reboot/session change'
            'Default'
            'Restore'
        )
        Warnings                         = @($analysis.Warnings)
        MissingApprovals                 = @($analysis.MissingApprovals)
        NoDownloadOccurred               = $true
        NoInstallerExecutionOccurred     = $true
        NoExternalProcessStarted         = $true
        NoDriverMutationOccurred         = $true
        NoRegistryMutationOccurred       = $true
        NoFileCleanupOccurred            = $true
        NoRebootOrSessionChangeOccurred  = $true
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
        ConfirmationText            = 'Driver Install Debloat & Settings manual handoff prepares instructions only. BoostLab will not open external tools, download 7-Zip or drivers, run installers, debloat files, import profiles, mutate drivers/registry/services/packages, change sessions, or reboot. Continue preparing the manual handoff result?'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabDriverInstallDebloatSettingsSourceStatus
    [pscustomobject]@{
        Supported            = $true
        ToolId               = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle            = [string]$script:BoostLabToolMetadata['Title']
        Reason               = 'Driver Install Debloat & Settings manual handoff is available. Auto mode remains blocked.'
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
        return New-BoostLabDriverInstallDebloatSettingsResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'Unsupported' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Unsupported Driver Install Debloat & Settings action. Only Analyze, Open, Apply, Default, and Restore are exposed.'
    }

    if ($canonicalActionName -eq 'Analyze') {
        $analysis = Get-BoostLabDriverInstallDebloatSettingsAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        $status = if ($sourceOk) { 'Analyzed' } else { 'SourceVerificationFailed' }
        $message = if ($sourceOk) {
            'Driver Install Debloat & Settings analyzed. Phase 122 approves NVIDIA, AMD, and INTEL source branches for this tool only; runtime remains manual handoff only and Auto remains blocked until exact three-branch artifact, installer, driver-state, process, cleanup, AppX/package, profile, registry, service/task, reboot, and recovery approvals/descriptors exist.'
        }
        else {
            'Driver Install Debloat & Settings source checksum verification failed or source file is missing.'
        }
        $errors = if ($sourceOk) {
            @()
        }
        else {
            @('Driver Install Debloat & Settings source checksum did not match the expected value or the source file is missing.')
        }

        return New-BoostLabDriverInstallDebloatSettingsResult `
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
            return New-BoostLabDriverInstallDebloatSettingsResult `
                -Success $false `
                -Action 'Open' `
                -Status 'Cancelled' `
                -CommandStatus 'Cancelled before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'Driver Install Debloat & Settings manual handoff cancelled by user. No download, installer execution, external process, file cleanup, profile import, package action, registry/service/driver mutation, reboot, or session change occurred.' `
                -Cancelled $true
        }

        $analysis = Get-BoostLabDriverInstallDebloatSettingsAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        if (-not $sourceOk) {
            return New-BoostLabDriverInstallDebloatSettingsResult `
                -Success $false `
                -Action 'Open' `
                -Status 'SourceVerificationFailed' `
                -CommandStatus 'Blocked before handoff' `
                -VerificationStatus ([string]$analysis.Source.ChecksumStatus) `
                -Message 'Driver Install Debloat & Settings manual handoff blocked because source checksum verification failed or the source file is missing.' `
                -Data $analysis `
                -Errors @('Driver Install Debloat & Settings source checksum did not match the expected value or the source file is missing.')
        }

        $plan = New-BoostLabDriverInstallDebloatSettingsManualHandoffPlan
        return New-BoostLabDriverInstallDebloatSettingsResult `
            -Success $true `
            -Action 'Open' `
            -Status 'ManualHandoffPrepared' `
            -CommandStatus 'No execution performed' `
            -VerificationStatus 'Passed' `
            -Message 'Manual handoff prepared. No browser, external tool, 7-Zip download/install, driver download, installer execution, driver extraction/debloat, Profile Inspector execution, .nip import, winget/AppX action, registry/service/driver mutation, display/sound launch, reboot, or session change occurred.' `
            -Data $plan
    }

    if ($canonicalActionName -eq 'Apply') {
        $analysis = Get-BoostLabDriverInstallDebloatSettingsAnalysis
        return New-BoostLabDriverInstallDebloatSettingsResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'AutoBlockedUntilArtifactApproval' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Blocked' `
            -Message 'AutoBlockedUntilArtifactApproval. Auto mode is blocked until exact 7-Zip, NVIDIA/AMD/Intel driver, installer, extraction, cleanup/debloat, winget/AppX/package, service/task/process, Profile Inspector/.nip, registry/profile, driver-state, reboot/session, and recovery approvals/descriptors exist. No automated download, installer execution, external process, file cleanup, profile import, package action, registry/service/driver mutation, reboot, or session change occurred.' `
            -Data $analysis
    }

    if ($canonicalActionName -eq 'Default') {
        return New-BoostLabDriverInstallDebloatSettingsResult `
            -Success $false `
            -Action 'Default' `
            -Status 'DefaultUnavailable' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Default is unavailable for Driver Install Debloat & Settings manual handoff. The source does not define a safe overall Default; Default is not Restore, and no driver/profile/package/registry/file state is mutated.'
    }

    if ($canonicalActionName -eq 'Restore') {
        return New-BoostLabDriverInstallDebloatSettingsResult `
            -Success $false `
            -Action 'Restore' `
            -Status 'RestoreUnavailable' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Restore is unavailable without approved captured driver/profile/package/registry/file/reboot state and a Restore contract. Default is not Restore, and no system-changing operation is planned.'
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
