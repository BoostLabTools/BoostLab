Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'installers'
    Title = 'Installers'
    Stage = 'Installers'
    Order = 1
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Controlled manual handoff only. Analyze the source-defined multi-app installer workflow without automated downloads, installer launches, package changes, app configuration, cleanup, or system mutation.'
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
$script:BoostLabExpectedSourceHash = '1065D64183457D4E7B28EA78DDE41525EC8F7C4A4BCA12D29B70D991141C0C67'
$script:BoostLabSourceRelativePath = 'source-ultimate/4 Installers/1 Installers.ps1'

function Get-BoostLabInstallersSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $projectRoot ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabInstallersSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabInstallersSourcePath
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

function New-BoostLabInstallersResult {
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

function Get-BoostLabInstallersBlockedApprovals {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'Per-app artifact provenance approval for every source-defined installer'
        'Artifact SHA-256, size, signer, version, publisher, and redistributability approval'
        'Exact installer execution descriptor and switch validation for every selected app'
        'Installer exit-code, timeout, process, and log handling approval'
        'Generated temp/download path ownership and cleanup approval'
        'Per-app registry, file, shortcut, service, scheduled-task, config, and uninstall side-effect scope approval'
        'Application inventory, support, rollback, and Restore contract approval'
        'NVIDIA App and FrameView vendor-specific approval where selected'
    )
}

function Get-BoostLabInstallersRiskWarnings {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'Original Ultimate source requires Administrator and internet access.'
        'Original Ultimate source offers 23 app installer choices plus Exit.'
        'Original Ultimate source downloads 24 external artifacts from vendor or mirror URLs.'
        'Original Ultimate source launches installers or helper executables and uses silent switches for some apps.'
        'Original Ultimate source writes app configuration, browser policy, and startup settings for selected apps.'
        'Original Ultimate source removes some services, scheduled tasks, shortcuts, and selected components for selected apps.'
        'No artifact provenance, installer descriptor, per-app side-effect scope, inventory, cleanup, rollback, or support approval exists for automated Installers behavior.'
        'This BoostLab implementation prepares manual handoff instructions only and performs no automated download, installer launch, package change, app configuration, cleanup, or system mutation.'
    )
}

function Get-BoostLabInstallersAnalysis {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabInstallersSourceStatus
    [pscustomobject]@{
        Mode                         = 'ManualHandoffOnly'
        AutoMode                     = 'AutoBlockedUntilArtifactApproval'
        Source                       = $sourceStatus
        SourceBehaviorSummary        = @(
            'Checks for Administrator rights and internet connectivity.'
            'Presents an interactive menu for Discord, Roblox, 7-Zip, Battle.net, Brave, Electronic Arts, Epic Games, Escape From Tarkov, Firefox, Frame View, GOG launcher, Google Chrome, League Of Legends, Notepad++, Nvidia App, OBS Studio, Onboard Memory Manager, Pot Player, Rockstar Games, Spotify, Steam, Ubisoft Connect, and Valorant.'
            'Downloads 24 external artifacts into temporary or application paths.'
            'Launches installers or helper executables, including silent switches for some source-defined apps.'
            'Writes app configuration and browser policy settings for selected apps.'
            'Creates or reshapes desktop and Start Menu shortcuts for selected apps.'
            'Removes selected services, scheduled tasks, startup entries, and components for selected apps.'
            'The source does not define one safe global Default or Restore model for installed apps and post-install side effects.'
        )
        SupportedManualHandoffScope  = @(
            'Display source identity, checksum status, source behavior, missing approvals, and manual-handoff status.'
            'Prepare guidance inside BoostLab only.'
            'Do not open a browser, Explorer, Settings, Store, app installer, package manager, script, or external tool.'
            'Do not download, run, create, delete, mutate, install, uninstall, repair, update, configure, clean up, or launch anything.'
        )
        MissingApprovals             = @(Get-BoostLabInstallersBlockedApprovals)
        Warnings                     = @(Get-BoostLabInstallersRiskWarnings)
        SourceMenuAppCount           = 23
        SourceDownloadArtifactCount  = 24
        NoAutomatedExecution         = $true
        NoDownloadOccurred           = $true
        NoInstallerExecutionOccurred = $true
        NoExternalProcessStarted     = $true
        NoPackageMutationOccurred    = $true
        NoFileMutationOccurred       = $true
        NoRegistryMutationOccurred   = $true
        NoServiceMutationOccurred    = $true
        NoScheduledTaskMutation      = $true
        NoShortcutMutationOccurred   = $true
        NoAppConfigurationMutation   = $true
        NoUninstallOccurred          = $true
        NoCleanupOccurred            = $true
        NoDeviceMutationOccurred     = $true
        NoDriverMutationOccurred     = $true
        NoRebootOccurred             = $true
        NoSystemMutationOccurred     = $true
    }
}

function New-BoostLabInstallersManualHandoffPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $analysis = Get-BoostLabInstallersAnalysis
    [pscustomobject]@{
        PlanType                     = 'ManualHandoffOnly'
        SourceChecksumStatus         = [string]$analysis.Source.ChecksumStatus
        Steps                        = @(
            'Review source checksum and blocked installer/app approvals.'
            'Prepare manual handoff instructions inside BoostLab only.'
            'Do not open a browser, Explorer, Settings, Store, app installer, package manager, script, or external tool.'
            'Do not download app installers, archives, scripts, packages, or artifacts.'
            'Do not run installers, setup executables, package managers, Store actions, AppX actions, MSI packages, scripts, or helpers.'
            'Do not install, uninstall, repair, update, remove, or configure packages or apps.'
            'Do not create, delete, or mutate files, temp folders, shortcuts, registry, services, scheduled tasks, firewall, devices, drivers, reboot/session state, or app configuration.'
            'Explain that Auto remains blocked until per-app artifact provenance, installer descriptors, side-effect scopes, inventory, cleanup, rollback, and support approvals exist.'
            'Record Latest Result and Activity Log with no automated execution.'
        )
        BlockedActions               = @(
            'Apply Auto'
            'app download'
            'installer launch'
            'package manager action'
            'Store or AppX action'
            'file, temp-folder, or shortcut mutation'
            'registry or policy mutation'
            'service or scheduled-task mutation'
            'app configuration mutation'
            'uninstall or repair action'
            'cleanup'
            'reboot or session change'
            'Default'
            'Restore'
        )
        Warnings                     = @($analysis.Warnings)
        MissingApprovals             = @($analysis.MissingApprovals)
        NoDownloadOccurred           = $true
        NoInstallerExecutionOccurred = $true
        NoExternalProcessStarted     = $true
        NoPackageMutationOccurred    = $true
        NoRegistryMutationOccurred   = $true
        NoFileMutationOccurred       = $true
        NoServiceMutationOccurred    = $true
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
        ConfirmationText            = 'Installers manual handoff prepares instructions only. BoostLab will not open external tools, download apps, run installers, change packages, mutate files, registry, services, tasks, shortcuts, devices, or drivers, perform cleanup, or reboot. Continue preparing the manual handoff result?'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabInstallersSourceStatus
    [pscustomobject]@{
        Supported            = $true
        ToolId               = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle            = [string]$script:BoostLabToolMetadata['Title']
        Reason               = 'Installers manual handoff is available. Auto mode remains blocked.'
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
        return New-BoostLabInstallersResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'Unsupported' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Unsupported Installers action. Only Analyze, Open, Apply, Default, and Restore are exposed.'
    }

    if ($canonicalActionName -eq 'Analyze') {
        $analysis = Get-BoostLabInstallersAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        $status = if ($sourceOk) { 'Analyzed' } else { 'SourceVerificationFailed' }
        $message = if ($sourceOk) {
            'Installers analyzed. Manual handoff only; Auto remains blocked until exact per-app artifact provenance, installer execution, side-effect, inventory, cleanup, rollback, and support approvals exist.'
        }
        else {
            'Installers source checksum verification failed or source file is missing.'
        }
        $errors = if ($sourceOk) {
            @()
        }
        else {
            @('Installers source checksum did not match the expected value or the source file is missing.')
        }

        return New-BoostLabInstallersResult `
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
            return New-BoostLabInstallersResult `
                -Success $false `
                -Action 'Open' `
                -Status 'Cancelled' `
                -CommandStatus 'Cancelled before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'Installers manual handoff cancelled by user. No browser, Explorer, Settings, Store, external tool, download, installer launch, package change, file mutation, registry/service/task/shortcut mutation, cleanup, reboot, or system mutation occurred.' `
                -Cancelled $true
        }

        $analysis = Get-BoostLabInstallersAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        if (-not $sourceOk) {
            return New-BoostLabInstallersResult `
                -Success $false `
                -Action 'Open' `
                -Status 'SourceVerificationFailed' `
                -CommandStatus 'Blocked before handoff' `
                -VerificationStatus ([string]$analysis.Source.ChecksumStatus) `
                -Message 'Installers manual handoff blocked because source checksum verification failed or the source file is missing.' `
                -Data $analysis `
                -Errors @('Installers source checksum did not match the expected value or the source file is missing.')
        }

        $plan = New-BoostLabInstallersManualHandoffPlan
        return New-BoostLabInstallersResult `
            -Success $true `
            -Action 'Open' `
            -Status 'ManualHandoffPrepared' `
            -CommandStatus 'No execution performed' `
            -VerificationStatus 'Passed' `
            -Message 'Manual handoff prepared. No browser, Explorer, Settings, Store, external tool, app download, installer launch, package change, file mutation, registry/service/task/shortcut mutation, cleanup, reboot, or system mutation occurred.' `
            -Data $plan
    }

    if ($canonicalActionName -eq 'Apply') {
        $analysis = Get-BoostLabInstallersAnalysis
        return New-BoostLabInstallersResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'AutoBlockedUntilArtifactApproval' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Blocked' `
            -Message 'AutoBlockedUntilArtifactApproval. Auto mode is blocked until exact per-app artifact provenance, installer descriptors, silent-switch validation, exit-code handling, generated-file ownership, cleanup, side-effect scopes, rollback, and support approvals exist. No download, installer launch, package change, file mutation, registry/service/task/shortcut mutation, cleanup, reboot, or system mutation occurred.' `
            -Data $analysis
    }

    if ($canonicalActionName -eq 'Default') {
        return New-BoostLabInstallersResult `
            -Success $false `
            -Action 'Default' `
            -Status 'DefaultUnavailable' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Default is unavailable for Installers manual handoff. The source does not define a safe global Default branch; Default is not Restore, and no app, package, file, registry, service, task, shortcut, cleanup, reboot, or system state is changed.'
    }

    if ($canonicalActionName -eq 'Restore') {
        return New-BoostLabInstallersResult `
            -Success $false `
            -Action 'Restore' `
            -Status 'RestoreUnavailable' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Restore is unavailable without approved captured package, installer, file, registry, service, scheduled-task, shortcut, app configuration, cleanup, and support state plus a Restore contract. Default is not Restore, and no system-changing operation is planned.'
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
