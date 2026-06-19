Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'edge-webview'
    Title = 'Edge & WebView'
    Stage = 'Windows'
    Order = 13
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Controlled manual handoff only. Analyze the source-defined Edge and WebView removal/repair workflow without automated downloads, repair, installer execution, package actions, process handling, registry/service/file mutation, cleanup, or system mutation.'
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
$script:BoostLabExpectedSourceHash = '161ED9C99D437E45650369CB7E15D5737DED363712E647138F134B049AC7E691'
$script:BoostLabSourceRelativePath = 'source-ultimate/6 Windows/13 Edge & WebView.ps1'

function Get-BoostLabEdgeWebViewSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $projectRoot ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabEdgeWebViewSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabEdgeWebViewSourcePath
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

function New-BoostLabEdgeWebViewResult {
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

function Get-BoostLabEdgeWebViewBlockedApprovals {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'Exact Edge and WebView repair artifact provenance approval'
        'Repair installer SHA-256, size, signer, version, publisher, and redistributability approval'
        'Exact Edge/WebView installer or repair execution descriptor approval'
        'Package/AppX inventory, removal, repair, and restore scope approval'
        'Process handling approval for every source-targeted process'
        'Service state capture and rollback approval for every Edge-related service target'
        'Scheduled task governance and rollback approval for every Edge-related task target'
        'File cleanup ownership map for every Edge/WebView path'
        'Registry, RunOnce, Active Setup, BHO, and policy scope approval'
        'Cleanup, rollback, support, and Restore contract approval'
    )
}

function Get-BoostLabEdgeWebViewRiskWarnings {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'Original Ultimate source requires Administrator and internet access.'
        'Original Ultimate source stops many Edge, WebView, Store, Widgets, Search, OneDrive, and related processes.'
        'Original Ultimate source changes DeviceRegion, removes EdgeUpdate registry keys, launches Edge uninstall/update executables, deletes Edge/WebView uninstall and policy state, deletes Edge services and scheduled tasks, and removes Edge folders and shortcuts.'
        'Original Ultimate source contains a Windows 10 legacy Edge package branch using CBS package registry changes and DISM package removal.'
        'Original Ultimate source Default downloads Edge and Edge WebView repair installers from mutable mirror URLs and launches them.'
        'Original Ultimate source imports Edge policies, removes Active Setup and RunOnce entries, deletes services/tasks, and deletes Browser Helper Object registry keys.'
        'No artifact provenance, package scope, process handling, service rollback, scheduled-task rollback, cleanup ownership, registry rollback, or support approval exists for automated Edge & WebView behavior.'
        'This BoostLab implementation prepares manual handoff instructions only and performs no automated download, repair, installer launch, package action, process handling, registry/service/file mutation, cleanup, or system mutation.'
    )
}

function Get-BoostLabEdgeWebViewAnalysis {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabEdgeWebViewSourceStatus
    [pscustomobject]@{
        Mode                         = 'ManualHandoffOnly'
        AutoMode                     = 'AutoBlockedUntilArtifactApproval'
        Source                       = $sourceStatus
        SourceBehaviorSummary        = @(
            'Checks for Administrator rights and internet connectivity.'
            'Uninstall branch changes DeviceRegion, stops broad process targets, removes EdgeUpdate registry state, runs Edge update/uninstall executables, creates and removes an Edge system-app marker path, removes Edge WebView uninstall registry state, deletes an Edge shortcut, deletes Microsoft Edge folders, deletes Edge services, and may remove a Windows 10 legacy Edge package.'
            'Default branch stops broad process targets, downloads Edge and Edge WebView repair installers from the Ultimate-Files mirror, launches those repair installers, then applies Edge policies and removes Edge Active Setup, RunOnce, services, scheduled tasks, and Browser Helper Object state.'
            'The source has destructive file, registry, service, scheduled-task, process, download, installer, package, and repair behavior that cannot be safely automated without exact approvals.'
            'The source does not define a safe captured-state Restore model for Edge/WebView package, file, registry, service, task, process, repair, and cleanup side effects.'
        )
        SupportedManualHandoffScope  = @(
            'Display source identity, checksum status, source behavior, missing approvals, and manual-handoff status.'
            'Prepare guidance inside BoostLab only.'
            'Do not open a browser, Explorer, Settings, Store, Edge, WebView, repair installer, package manager, script, or external tool.'
            'Do not download, run, create, delete, mutate, install, uninstall, repair, update, reset, configure, clean up, stop/start processes or services, or launch anything.'
        )
        MissingApprovals             = @(Get-BoostLabEdgeWebViewBlockedApprovals)
        Warnings                     = @(Get-BoostLabEdgeWebViewRiskWarnings)
        SourceDownloadArtifactCount  = 2
        SourceMenuActionCount        = 2
        NoAutomatedExecution         = $true
        NoDownloadOccurred           = $true
        NoRepairOccurred             = $true
        NoInstallerExecutionOccurred = $true
        NoExternalProcessStarted     = $true
        NoPackageMutationOccurred    = $true
        NoAppxMutationOccurred       = $true
        NoFileMutationOccurred       = $true
        NoRegistryMutationOccurred   = $true
        NoServiceMutationOccurred    = $true
        NoScheduledTaskMutation      = $true
        NoProcessMutationOccurred    = $true
        NoCleanupOccurred            = $true
        NoDeviceMutationOccurred     = $true
        NoDriverMutationOccurred     = $true
        NoRebootOccurred             = $true
        NoSystemMutationOccurred     = $true
    }
}

function New-BoostLabEdgeWebViewManualHandoffPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $analysis = Get-BoostLabEdgeWebViewAnalysis
    [pscustomobject]@{
        PlanType                     = 'ManualHandoffOnly'
        SourceChecksumStatus         = [string]$analysis.Source.ChecksumStatus
        Steps                        = @(
            'Review source checksum and blocked Edge/WebView approvals.'
            'Prepare manual handoff instructions inside BoostLab only.'
            'Do not open a browser, Explorer, Settings, Store, Edge, WebView, repair installer, package manager, script, or external tool.'
            'Do not download Edge, WebView, installer, repair, script, package, archive, or artifact content.'
            'Do not run setup, repair, installer, winget, Store, AppX, MSI, EXE, script, package, or helper behavior.'
            'Do not install, uninstall, repair, update, reset, remove, or configure Edge, WebView, packages, services, tasks, policies, BHO, Active Setup, or RunOnce state.'
            'Do not stop or start Edge/WebView processes or services.'
            'Do not create, delete, or mutate files, temp folders, shortcuts, registry, services, scheduled tasks, firewall, devices, drivers, reboot/session state, or app configuration.'
            'Explain that Auto remains blocked until artifact provenance, repair/installer descriptors, package/process/service/task/file/registry scopes, cleanup ownership, rollback, and support approvals exist.'
            'Record Latest Result and Activity Log with no automated execution.'
        )
        BlockedActions               = @(
            'Apply Auto'
            'Edge or WebView download'
            'Edge or WebView repair'
            'installer launch'
            'package, AppX, Store, or winget action'
            'process stop or start'
            'service stop, delete, or create'
            'scheduled task removal'
            'file, folder, or shortcut deletion'
            'registry, RunOnce, Active Setup, BHO, or policy mutation'
            'cleanup'
            'Default'
            'Restore'
        )
        Warnings                     = @($analysis.Warnings)
        MissingApprovals             = @($analysis.MissingApprovals)
        NoDownloadOccurred           = $true
        NoRepairOccurred             = $true
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
        ConfirmationText            = 'Edge & WebView manual handoff prepares instructions only. BoostLab will not open external tools, download repair artifacts, run installers, modify packages, stop processes, mutate files, registry, services, tasks, shortcuts, devices, or drivers, perform cleanup, or reboot. Continue preparing the manual handoff result?'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabEdgeWebViewSourceStatus
    [pscustomobject]@{
        Supported            = $true
        ToolId               = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle            = [string]$script:BoostLabToolMetadata['Title']
        Reason               = 'Edge & WebView manual handoff is available. Auto mode remains blocked.'
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
        return New-BoostLabEdgeWebViewResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'Unsupported' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Unsupported Edge & WebView action. Only Analyze, Open, Apply, Default, and Restore are exposed.'
    }

    if ($canonicalActionName -eq 'Analyze') {
        $analysis = Get-BoostLabEdgeWebViewAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        $status = if ($sourceOk) { 'Analyzed' } else { 'SourceVerificationFailed' }
        $message = if ($sourceOk) {
            'Edge & WebView analyzed. Manual handoff only; Auto remains blocked until exact artifact, repair, installer, package, process, service, task, file, registry, cleanup, rollback, and support approvals exist.'
        }
        else {
            'Edge & WebView source checksum verification failed or source file is missing.'
        }
        $errors = if ($sourceOk) {
            @()
        }
        else {
            @('Edge & WebView source checksum did not match the expected value or the source file is missing.')
        }

        return New-BoostLabEdgeWebViewResult `
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
            return New-BoostLabEdgeWebViewResult `
                -Success $false `
                -Action 'Open' `
                -Status 'Cancelled' `
                -CommandStatus 'Cancelled before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'Edge & WebView manual handoff cancelled by user. No browser, Explorer, Settings, Store, Edge, WebView, external tool, download, repair, installer launch, package action, process handling, file mutation, registry/service/task/shortcut mutation, cleanup, reboot, or system mutation occurred.' `
                -Cancelled $true
        }

        $analysis = Get-BoostLabEdgeWebViewAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        if (-not $sourceOk) {
            return New-BoostLabEdgeWebViewResult `
                -Success $false `
                -Action 'Open' `
                -Status 'SourceVerificationFailed' `
                -CommandStatus 'Blocked before handoff' `
                -VerificationStatus ([string]$analysis.Source.ChecksumStatus) `
                -Message 'Edge & WebView manual handoff blocked because source checksum verification failed or the source file is missing.' `
                -Data $analysis `
                -Errors @('Edge & WebView source checksum did not match the expected value or the source file is missing.')
        }

        $plan = New-BoostLabEdgeWebViewManualHandoffPlan
        return New-BoostLabEdgeWebViewResult `
            -Success $true `
            -Action 'Open' `
            -Status 'ManualHandoffPrepared' `
            -CommandStatus 'No execution performed' `
            -VerificationStatus 'Passed' `
            -Message 'Manual handoff prepared. No browser, Explorer, Settings, Store, Edge, WebView, external tool, download, repair, installer launch, package action, process handling, file mutation, registry/service/task/shortcut mutation, cleanup, reboot, or system mutation occurred.' `
            -Data $plan
    }

    if ($canonicalActionName -eq 'Apply') {
        $analysis = Get-BoostLabEdgeWebViewAnalysis
        return New-BoostLabEdgeWebViewResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'AutoBlockedUntilArtifactApproval' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Blocked' `
            -Message 'AutoBlockedUntilArtifactApproval. Auto mode is blocked until exact Edge/WebView artifact provenance, repair and installer descriptors, package scopes, process handling, service/task/file/registry cleanup scopes, rollback, and support approvals exist. No download, repair, installer launch, package action, process handling, file mutation, registry/service/task/shortcut mutation, cleanup, reboot, or system mutation occurred.' `
            -Data $analysis
    }

    if ($canonicalActionName -eq 'Default') {
        return New-BoostLabEdgeWebViewResult `
            -Success $false `
            -Action 'Default' `
            -Status 'DefaultUnavailable' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Default is unavailable for Edge & WebView manual handoff. The source Default branch downloads and runs repair installers plus policy, service, task, Active Setup, RunOnce, and BHO mutations. Default is not Restore, and no package, repair, file, registry, service, task, cleanup, reboot, or system state is changed.'
    }

    if ($canonicalActionName -eq 'Restore') {
        return New-BoostLabEdgeWebViewResult `
            -Success $false `
            -Action 'Restore' `
            -Status 'RestoreUnavailable' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Restore is unavailable without approved captured Edge/WebView package, installer, file, registry, service, scheduled-task, process, cleanup, and support state plus a Restore contract. Default is not Restore, and no system-changing operation is planned.'
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
