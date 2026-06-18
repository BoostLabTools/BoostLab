Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'directx'
    Title = 'DirectX'
    Stage = 'Graphics'
    Order = 8
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Controlled manual handoff only. Analyze the source-defined DirectX runtime workflow without automated downloads, extraction, installer execution, shortcut cleanup, registry changes, or system mutation.'
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
$script:BoostLabExpectedSourceHash = '17051A2F0F7A0CF16BE525121720406E8F1630C94E5977A7CD4C18652A87EE05'
$script:BoostLabSourceRelativePath = 'source-ultimate/5 Graphics/2 DirectX.ps1'

function Get-BoostLabDirectXSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $projectRoot ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabDirectXSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabDirectXSourcePath
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

function Get-BoostLabDirectXBlockedApprovals {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'Immutable 7-Zip artifact source approval'
        '7-Zip artifact SHA-256, size, signer, and redistributability approval'
        '7-Zip installer execution descriptor approval'
        '7-Zip shortcut and configuration side-effect scope approval'
        'Immutable DirectX runtime artifact source approval'
        'DirectX artifact SHA-256, size, signer, and redistributability approval'
        'DirectX extraction inventory and generated-temp-path approval'
        'Extracted DXSETUP executable provenance approval'
        'DirectX setup execution descriptor approval'
        'File, shortcut, registry, and cleanup scope approval'
    )
}

function Get-BoostLabDirectXRiskWarnings {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'Original Ultimate source requires Administrator and internet access.'
        'Original Ultimate source downloads 7-Zip from a mutable branch URL and installs it silently.'
        'Original Ultimate source writes 7-Zip HKCU configuration values and moves/removes 7-Zip Start Menu shortcuts.'
        'Original Ultimate source downloads a DirectX runtime package from a mutable branch URL.'
        'Original Ultimate source extracts the DirectX package with 7-Zip and launches the extracted DirectX setup executable.'
        'No SHA-256, size, signer, extraction inventory, installer exit-code, cleanup, or rollback approval exists for these artifacts.'
        'This BoostLab implementation prepares manual handoff instructions only and performs no automated download, extraction, installer launch, shortcut cleanup, registry change, or system mutation.'
    )
}

function Get-BoostLabDirectXAnalysis {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabDirectXSourceStatus
    [pscustomobject]@{
        Mode                              = 'ManualHandoffOnly'
        AutoMode                          = 'AutoBlockedUntilArtifactApproval'
        Source                            = $sourceStatus
        SourceBehaviorSummary             = @(
            'Checks for Administrator rights and internet connectivity.'
            'Downloads 7zip.exe from the Ultimate-Files mirror and installs it silently.'
            'Writes 7-Zip HKCU options and adjusts the 7-Zip Start Menu shortcut folder.'
            'Downloads directx.exe from the Ultimate-Files mirror.'
            'Extracts directx.exe into the Windows Temp DirectX folder with 7-Zip.'
            'Launches the extracted DirectX setup executable.'
        )
        MissingApprovals                  = @(Get-BoostLabDirectXBlockedApprovals)
        Warnings                          = @(Get-BoostLabDirectXRiskWarnings)
        NoAutomatedExecution              = $true
        NoDownloadOccurred                = $true
        NoInstallerExecutionOccurred      = $true
        NoExternalProcessStarted          = $true
        NoExtractionOccurred              = $true
        NoRegistryMutationOccurred        = $true
        NoShortcutMutationOccurred        = $true
        NoFileCleanupOccurred             = $true
        NoSystemMutationOccurred          = $true
    }
}

function New-BoostLabDirectXManualHandoffPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $analysis = Get-BoostLabDirectXAnalysis
    [pscustomobject]@{
        PlanType                     = 'ManualHandoffOnly'
        SourceChecksumStatus         = [string]$analysis.Source.ChecksumStatus
        Steps                        = @(
            'Review source checksum and blocked artifact approvals.'
            'Prepare manual handoff instructions inside BoostLab only.'
            'Do not open a browser, external tool, 7-Zip installer, DirectX runtime package, extraction tool, or DirectX setup executable.'
            'Do not download 7-Zip or DirectX artifacts.'
            'Do not install 7-Zip, write 7-Zip registry options, move or remove 7-Zip Start Menu shortcuts, extract DirectX files, or launch DirectX setup.'
            'Explain that Auto remains blocked until immutable artifact provenance, installer descriptors, extraction inventory, side-effect scopes, and cleanup/rollback approvals exist.'
            'Record Latest Result and Activity Log with no automated execution.'
        )
        BlockedActions               = @(
            'Apply Auto'
            '7-Zip download'
            '7-Zip installation'
            '7-Zip registry configuration'
            '7-Zip Start Menu shortcut movement or cleanup'
            'DirectX runtime download'
            'DirectX extraction'
            'DirectX setup execution'
            'generated temp path cleanup'
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
        ConfirmationText            = 'DirectX manual handoff prepares instructions only. BoostLab will not open external tools, download 7-Zip or DirectX, run installers, extract files, mutate registry/shortcuts/files, or change system state. Continue preparing the manual handoff result?'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabDirectXSourceStatus
    [pscustomobject]@{
        Supported            = $true
        ToolId               = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle            = [string]$script:BoostLabToolMetadata['Title']
        Reason               = 'DirectX manual handoff is available. Auto mode remains blocked.'
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
        return New-BoostLabDirectXResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'Unsupported' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Unsupported DirectX action. Only Analyze, Open, Apply, Default, and Restore are exposed.'
    }

    if ($canonicalActionName -eq 'Analyze') {
        $analysis = Get-BoostLabDirectXAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        $status = if ($sourceOk) { 'Analyzed' } else { 'SourceVerificationFailed' }
        $message = if ($sourceOk) {
            'DirectX analyzed. Manual handoff only; Auto remains blocked until exact 7-Zip, DirectX artifact, extraction, installer, side-effect, cleanup, and rollback approvals exist.'
        }
        else {
            'DirectX source checksum verification failed or source file is missing.'
        }
        $errors = if ($sourceOk) {
            @()
        }
        else {
            @('DirectX source checksum did not match the expected value or the source file is missing.')
        }

        return New-BoostLabDirectXResult `
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
            return New-BoostLabDirectXResult `
                -Success $false `
                -Action 'Open' `
                -Status 'Cancelled' `
                -CommandStatus 'Cancelled before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'DirectX manual handoff cancelled by user. No browser, external tool, download, extraction, installer launch, registry change, shortcut cleanup, file cleanup, or system mutation occurred.' `
                -Cancelled $true
        }

        $analysis = Get-BoostLabDirectXAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        if (-not $sourceOk) {
            return New-BoostLabDirectXResult `
                -Success $false `
                -Action 'Open' `
                -Status 'SourceVerificationFailed' `
                -CommandStatus 'Blocked before handoff' `
                -VerificationStatus ([string]$analysis.Source.ChecksumStatus) `
                -Message 'DirectX manual handoff blocked because source checksum verification failed or the source file is missing.' `
                -Data $analysis `
                -Errors @('DirectX source checksum did not match the expected value or the source file is missing.')
        }

        $plan = New-BoostLabDirectXManualHandoffPlan
        return New-BoostLabDirectXResult `
            -Success $true `
            -Action 'Open' `
            -Status 'ManualHandoffPrepared' `
            -CommandStatus 'No execution performed' `
            -VerificationStatus 'Passed' `
            -Message 'Manual handoff prepared. No browser, external tool, 7-Zip download/install, DirectX download, extraction, setup launch, registry change, shortcut cleanup, file cleanup, or system mutation occurred.' `
            -Data $plan
    }

    if ($canonicalActionName -eq 'Apply') {
        $analysis = Get-BoostLabDirectXAnalysis
        return New-BoostLabDirectXResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'AutoBlockedUntilArtifactApproval' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Blocked' `
            -Message 'AutoBlockedUntilArtifactApproval. Auto mode is blocked until exact 7-Zip artifact, DirectX artifact, extraction inventory, installer execution, side-effect scope, cleanup, and rollback approvals exist. No download, extraction, installer launch, registry change, shortcut cleanup, file cleanup, or system mutation occurred.' `
            -Data $analysis
    }

    if ($canonicalActionName -eq 'Default') {
        return New-BoostLabDirectXResult `
            -Success $false `
            -Action 'Default' `
            -Status 'DefaultUnavailable' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Default is unavailable for DirectX manual handoff. The source does not define a safe Default branch; Default is not Restore, and no artifact, registry, shortcut, file, installer, or system state is changed.'
    }

    if ($canonicalActionName -eq 'Restore') {
        return New-BoostLabDirectXResult `
            -Success $false `
            -Action 'Restore' `
            -Status 'RestoreUnavailable' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Restore is unavailable without approved captured artifact, registry, shortcut, file, installer, and cleanup state plus a Restore contract. Default is not Restore, and no system-changing operation is planned.'
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
