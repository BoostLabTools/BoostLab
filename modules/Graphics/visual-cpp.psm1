Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'visual-cpp'
    Title = 'Visual C++'
    Stage = 'Graphics'
    Order = 9
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Controlled manual handoff only. Analyze the source-defined Visual C++ redistributable workflow without automated downloads, installer execution, temp-file changes, package changes, registry changes, or system mutation.'
    Actions = @('Analyze', 'Open', 'Apply', 'Default', 'Restore')
    Capabilities = [ordered]@{
        RequiresAdmin              = $false
        RequiresInternet           = $false
        CanReboot                  = $false
        CanModifyRegistry          = $false
        CanModifyServices          = $false
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
$script:BoostLabExpectedSourceHash = '7ACB1F25ECFEEAD83FA389E2D0C1FEEF12232C4E9A740CB5DE64A326FFD38C09'
$script:BoostLabSourceRelativePath = 'source-ultimate/5 Graphics/3 C++.ps1'

function Get-BoostLabVisualCppSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $projectRoot ($script:BoostLabSourceRelativePath -replace '/', '\')
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

function Get-BoostLabVisualCppBlockedApprovals {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'Immutable Visual C++ redistributable artifact source approval for all twelve packages'
        'Visual C++ package SHA-256, size, version, architecture, signer, and redistributability approval for every package'
        'Visual C++ installer execution descriptor approval for every source-defined switch'
        'Visual C++ installer exit-code interpretation approval'
        'Generated temp-file ownership, verification, and cleanup scope approval'
        'Artifact provenance records tied to visual-cpp'
        'Installer timeout, logging, and rollback/support approval'
    )
}

function Get-BoostLabVisualCppRiskWarnings {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'Original Ultimate source requires Administrator and internet access.'
        'Original Ultimate source downloads twelve Visual C++ redistributable executables from mutable branch URLs.'
        'Original Ultimate source launches every downloaded redistributable with source-defined quiet or passive switches.'
        'Original Ultimate source leaves downloaded executables in the Windows Temp directory.'
        'No SHA-256, size, version, signer, authoritative source, installer exit-code, temp ownership, cleanup, or rollback approval exists for these artifacts.'
        'This BoostLab implementation prepares manual handoff instructions only and performs no automated download, installer launch, package change, temp-file change, registry change, or system mutation.'
    )
}

function Get-BoostLabVisualCppAnalysis {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabVisualCppSourceStatus
    [pscustomobject]@{
        Mode                              = 'ManualHandoffOnly'
        AutoMode                          = 'AutoBlockedUntilArtifactApproval'
        Source                            = $sourceStatus
        SourceBehaviorSummary             = @(
            'Checks for Administrator rights and internet connectivity.'
            'Downloads twelve Visual C++ redistributable executables from the Ultimate-Files mirror into the Windows Temp directory.'
            'Downloads x86 and x64 packages for Visual C++ 2005, 2008, 2010, 2012, 2013, and 2015/2017/2019/2022.'
            'Launches Visual C++ 2005 packages with /q.'
            'Launches Visual C++ 2008 packages with /qb.'
            'Launches Visual C++ 2010, 2012, 2013, and 2015/2017/2019/2022 packages with /passive /norestart.'
            'Does not remove the downloaded redistributable executables afterward.'
        )
        MissingApprovals                  = @(Get-BoostLabVisualCppBlockedApprovals)
        Warnings                          = @(Get-BoostLabVisualCppRiskWarnings)
        NoAutomatedExecution              = $true
        NoDownloadOccurred                = $true
        NoInstallerExecutionOccurred      = $true
        NoExternalProcessStarted          = $true
        NoPackageMutationOccurred         = $true
        NoTempFileMutationOccurred        = $true
        NoRegistryMutationOccurred        = $true
        NoFileCleanupOccurred             = $true
        NoSystemMutationOccurred          = $true
    }
}

function New-BoostLabVisualCppManualHandoffPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $analysis = Get-BoostLabVisualCppAnalysis
    [pscustomobject]@{
        PlanType                     = 'ManualHandoffOnly'
        SourceChecksumStatus         = [string]$analysis.Source.ChecksumStatus
        Steps                        = @(
            'Review source checksum and blocked artifact approvals.'
            'Prepare manual handoff instructions inside BoostLab only.'
            'Do not open a browser, external tool, Visual C++ redistributable package, or Visual C++ installer executable.'
            'Do not download Visual C++ artifacts.'
            'Do not launch Visual C++ installers, change package state, write registry, change temp files, or perform cleanup.'
            'Explain that Auto remains blocked until immutable artifact provenance, installer descriptors, exit-code rules, temp-file ownership, cleanup, and rollback/support approvals exist.'
            'Record Latest Result and Activity Log with no automated execution.'
        )
        BlockedActions               = @(
            'Apply Auto'
            'Visual C++ redistributable download'
            'Visual C++ installer execution'
            'Visual C++ package state mutation'
            'generated temp file write'
            'generated temp file cleanup'
            'Default'
            'Restore'
        )
        Warnings                     = @($analysis.Warnings)
        MissingApprovals             = @($analysis.MissingApprovals)
        NoDownloadOccurred           = $true
        NoInstallerExecutionOccurred = $true
        NoExternalProcessStarted     = $true
        NoRegistryMutationOccurred   = $true
        NoFileCleanupOccurred        = $true
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
        ConfirmationText            = 'Visual C++ manual handoff prepares instructions only. BoostLab will not open external tools, download Visual C++ redistributables, run installers, mutate registry/packages/temp files, or change system state. Continue preparing the manual handoff result?'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabVisualCppSourceStatus
    [pscustomobject]@{
        Supported            = $true
        ToolId               = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle            = [string]$script:BoostLabToolMetadata['Title']
        Reason               = 'Visual C++ manual handoff is available. Auto mode remains blocked.'
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
        return New-BoostLabVisualCppResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'Unsupported' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Unsupported Visual C++ action. Only Analyze, Open, Apply, Default, and Restore are exposed.'
    }

    if ($canonicalActionName -eq 'Analyze') {
        $analysis = Get-BoostLabVisualCppAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        $status = if ($sourceOk) { 'Analyzed' } else { 'SourceVerificationFailed' }
        $message = if ($sourceOk) {
            'Visual C++ analyzed. Manual handoff only; Auto remains blocked until exact twelve-package artifact, installer, exit-code, temp-file, cleanup, and rollback/support approvals exist.'
        }
        else {
            'Visual C++ source checksum verification failed or source file is missing.'
        }
        $errors = if ($sourceOk) {
            @()
        }
        else {
            @('Visual C++ source checksum did not match the expected value or the source file is missing.')
        }

        return New-BoostLabVisualCppResult `
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
            return New-BoostLabVisualCppResult `
                -Success $false `
                -Action 'Open' `
                -Status 'Cancelled' `
                -CommandStatus 'Cancelled before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'Visual C++ manual handoff cancelled by user. No browser, external tool, download, installer launch, package change, registry change, temp-file change, file cleanup, or system mutation occurred.' `
                -Cancelled $true
        }

        $analysis = Get-BoostLabVisualCppAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        if (-not $sourceOk) {
            return New-BoostLabVisualCppResult `
                -Success $false `
                -Action 'Open' `
                -Status 'SourceVerificationFailed' `
                -CommandStatus 'Blocked before handoff' `
                -VerificationStatus ([string]$analysis.Source.ChecksumStatus) `
                -Message 'Visual C++ manual handoff blocked because source checksum verification failed or the source file is missing.' `
                -Data $analysis `
                -Errors @('Visual C++ source checksum did not match the expected value or the source file is missing.')
        }

        $plan = New-BoostLabVisualCppManualHandoffPlan
        return New-BoostLabVisualCppResult `
            -Success $true `
            -Action 'Open' `
            -Status 'ManualHandoffPrepared' `
            -CommandStatus 'No execution performed' `
            -VerificationStatus 'Passed' `
            -Message 'Manual handoff prepared. No browser, external tool, Visual C++ download, installer launch, package change, registry change, temp-file change, file cleanup, or system mutation occurred.' `
            -Data $plan
    }

    if ($canonicalActionName -eq 'Apply') {
        $analysis = Get-BoostLabVisualCppAnalysis
        return New-BoostLabVisualCppResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'AutoBlockedUntilArtifactApproval' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Blocked' `
            -Message 'AutoBlockedUntilArtifactApproval. Auto mode is blocked until exact twelve-package Visual C++ artifact provenance, installer execution, exit-code, temp-file ownership, cleanup, and rollback/support approvals exist. No download, installer launch, package change, registry change, temp-file change, file cleanup, or system mutation occurred.' `
            -Data $analysis
    }

    if ($canonicalActionName -eq 'Default') {
        return New-BoostLabVisualCppResult `
            -Success $false `
            -Action 'Default' `
            -Status 'DefaultUnavailable' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Default is unavailable for Visual C++ manual handoff. The source does not define a safe Default branch; Default is not Restore, and no artifact, package, registry, temp file, installer, or system state is changed.'
    }

    if ($canonicalActionName -eq 'Restore') {
        return New-BoostLabVisualCppResult `
            -Success $false `
            -Action 'Restore' `
            -Status 'RestoreUnavailable' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Restore is unavailable without approved captured artifact, package, registry, temp-file, installer, and cleanup state plus a Restore contract. Default is not Restore, and no system-changing operation is planned.'
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
