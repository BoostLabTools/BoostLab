Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'bitlocker'
    Title = 'BitLocker'
    Stage = 'Setup'
    Order = 9
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Analyze BitLocker state and prepare security-sensitive manual handoff only. Apply, Default, and Restore remain blocked until recovery-key and encryption-state policy is approved.'
    Actions = @('Analyze', 'Apply', 'Default', 'Restore', 'Open')
    Capabilities = [ordered]@{
        RequiresAdmin = $true
        RequiresInternet = $false
        CanReboot = $false
        CanModifyRegistry = $false
        CanModifyServices = $false
        CanInstallSoftware = $false
        CanDownload = $false
        CanModifyDrivers = $false
        CanModifySecurity = $true
        CanDeleteFiles = $false
        UsesTrustedInstaller = $false
        UsesSafeMode = $false
        SupportsDefault = $false
        SupportsRestore = $false
        NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Analyze', 'Apply', 'Default', 'Restore', 'Open')
$script:BoostLabExpectedSourceHash = '1678E97FB5AFF851F1491A2D96C82A5716B1FA07CB4E3A4A5E0F3FB1B086FBA1'
$script:BoostLabSourceRelativePath = 'source-ultimate/_intake-promoted/Ultimate/3 Setup/1 BitLocker.ps1'

function Get-BoostLabBitLockerSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $projectRoot ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabBitLockerSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabBitLockerSourcePath
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

function Get-BoostLabBitLockerPropertyValue {
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$Name,

        [AllowNull()]
        [object]$Default = $null
    )

    if ($null -eq $InputObject) {
        return $Default
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $Default
    }

    return $property.Value
}

function Get-BoostLabBitLockerSourceBehavior {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        SourceMenu = @(
            '1. BitLocker: Off (Recommended)'
            '2. BitLocker: On'
        )
        ApplyMapping = 'Apply would correspond to the source Off branch, but BoostLab blocks it because it disables BitLocker volumes.'
        SourceOffBehavior = @(
            'Queries Get-BitLockerVolume.'
            'Filters volumes where ProtectionStatus is On or VolumeStatus is not FullyDecrypted.'
            'Calls Disable-BitLocker for each matched MountPoint with ErrorAction SilentlyContinue.'
            'Opens the BitLocker Drive Encryption Control Panel.'
            'Runs manage-bde status output.'
        )
        SourceOnBehavior = @(
            'Opens the BitLocker Drive Encryption Control Panel.'
            'Runs manage-bde status output.'
            'Does not enable BitLocker directly in the source script.'
        )
        SourceTargetVolumes = 'All volumes returned by Get-BitLockerVolume that match the Off branch filter.'
        SourceCommandsRepresented = @(
            'Get-BitLockerVolume'
            'Disable-BitLocker'
            'control.exe /name microsoft.bitlockerdriveencryption'
            'manage-bde -status'
        )
        SecurityImplications = @(
            'The source Off branch can start decryption or disable protection on one or more volumes.'
            'The source does not verify recovery-key backup before disabling protection.'
            'The source suppresses Disable-BitLocker errors.'
            'The source has no captured-state Restore behavior.'
        )
        RebootImplications = 'The source has no explicit reboot command, but BitLocker state changes can affect recovery and support workflows.'
    }
}

function Get-BoostLabBitLockerBlockers {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'NeedsSecurityDecision'
        'NeedsRecoveryKeyPolicy'
        'NeedsEncryptionStateContract'
        'NeedsProtectorStateContract'
        'NeedsExplicitVolumeSelectionPolicy'
        'NeedsApprovedDisableBitLockerBehavior'
        'NeedsVerificationAndSupportBoundary'
    )
}

function Get-BoostLabBitLockerRiskWarnings {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'Original Ultimate Off branch disables BitLocker on every matched protected or not fully decrypted volume.'
        'BoostLab does not silently enable BitLocker, disable BitLocker, decrypt a drive, suspend protection, or remove protectors.'
        'BoostLab does not assume recovery keys are backed up.'
        'Default is not Restore, and Restore is unavailable without valid captured BitLocker state.'
        'Manual handoff provides instructions and warnings only; it does not open external tools or change system state.'
    )
}

function Get-BoostLabBitLockerVolumeSnapshot {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [scriptblock]$VolumeReader
    )

    $readerAvailable = $null -ne $VolumeReader
    if (-not $readerAvailable) {
        $readerAvailable = $null -ne (Get-Command -Name 'Get-BitLockerVolume' -ErrorAction SilentlyContinue)
    }

    if (-not $readerAvailable) {
        return [pscustomobject]@{
            QuerySucceeded = $false
            QueryStatus = 'Unavailable'
            Message = 'Get-BitLockerVolume is not available on this system or PowerShell edition.'
            Volumes = @()
            VolumeCount = 0
            SourceOffMatchedVolumeCount = 0
            AmbiguousVolumeCount = 0
        }
    }

    try {
        $rawVolumes = if ($null -ne $VolumeReader) {
            @(& $VolumeReader)
        }
        else {
            @(Get-BitLockerVolume -ErrorAction Stop)
        }

        $volumes = foreach ($volume in $rawVolumes) {
            $mountPoint = [string](Get-BoostLabBitLockerPropertyValue -InputObject $volume -Name 'MountPoint' -Default 'Unknown')
            $volumeStatus = [string](Get-BoostLabBitLockerPropertyValue -InputObject $volume -Name 'VolumeStatus' -Default 'Unknown')
            $protectionStatus = [string](Get-BoostLabBitLockerPropertyValue -InputObject $volume -Name 'ProtectionStatus' -Default 'Unknown')
            $encryptionPercentage = Get-BoostLabBitLockerPropertyValue -InputObject $volume -Name 'EncryptionPercentage' -Default $null
            $lockStatus = [string](Get-BoostLabBitLockerPropertyValue -InputObject $volume -Name 'LockStatus' -Default 'Unknown')
            $keyProtectors = @(Get-BoostLabBitLockerPropertyValue -InputObject $volume -Name 'KeyProtector' -Default @())
            $protectorTypes = @(
                $keyProtectors |
                    ForEach-Object {
                        $type = Get-BoostLabBitLockerPropertyValue -InputObject $_ -Name 'KeyProtectorType' -Default $null
                        if ($null -ne $type -and -not [string]::IsNullOrWhiteSpace([string]$type)) {
                            [string]$type
                        }
                    } |
                    Select-Object -Unique
            )

            [pscustomobject]@{
                MountPoint = $mountPoint
                VolumeStatus = $volumeStatus
                ProtectionStatus = $protectionStatus
                EncryptionPercentage = $encryptionPercentage
                LockStatus = $lockStatus
                KeyProtectorCount = $keyProtectors.Count
                KeyProtectorTypes = @($protectorTypes)
                HasRecoveryPasswordProtector = 'RecoveryPassword' -in $protectorTypes
                WouldMatchSourceOffFilter = ($protectionStatus -eq 'On' -or $volumeStatus -ne 'FullyDecrypted')
                Ambiguous = [string]::IsNullOrWhiteSpace($mountPoint) -or $mountPoint -eq 'Unknown'
            }
        }

        return [pscustomobject]@{
            QuerySucceeded = $true
            QueryStatus = 'Passed'
            Message = 'BitLocker state queried read-only.'
            Volumes = @($volumes)
            VolumeCount = @($volumes).Count
            SourceOffMatchedVolumeCount = @($volumes | Where-Object { [bool]$_.WouldMatchSourceOffFilter }).Count
            AmbiguousVolumeCount = @($volumes | Where-Object { [bool]$_.Ambiguous }).Count
        }
    }
    catch {
        return [pscustomobject]@{
            QuerySucceeded = $false
            QueryStatus = 'Failed'
            Message = "BitLocker state query failed: $($_.Exception.Message)"
            Volumes = @()
            VolumeCount = 0
            SourceOffMatchedVolumeCount = 0
            AmbiguousVolumeCount = 0
        }
    }
}

function New-BoostLabBitLockerResult {
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

function Get-BoostLabBitLockerAnalysis {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [scriptblock]$VolumeReader
    )

    $source = Get-BoostLabBitLockerSourceStatus
    $volumeSnapshot = Get-BoostLabBitLockerVolumeSnapshot -VolumeReader $VolumeReader
    $blockers = @(Get-BoostLabBitLockerBlockers)

    [pscustomobject]@{
        Mode = 'ManualHandoffOnly'
        ApplyStatus = 'NeedsRecoveryKeyPolicy'
        DefaultStatus = 'DefaultUnavailable'
        RestoreStatus = 'RestoreUnavailable'
        Source = $source
        SourceBehavior = Get-BoostLabBitLockerSourceBehavior
        VolumeDiscovery = $volumeSnapshot
        Blockers = @($blockers)
        Warnings = @(Get-BoostLabBitLockerRiskWarnings)
        ApplyAvailable = $false
        DefaultAvailable = $false
        RestoreAvailable = $false
        NoMutationOccurred = $true
        NoSilentEnableDisableDecryptSuspendOrProtectorMutation = $true
        PathBRelationship = 'BitLocker remains separate from Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode.'
    }
}

function New-BoostLabBitLockerManualHandoffPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [scriptblock]$VolumeReader
    )

    $analysis = Get-BoostLabBitLockerAnalysis -VolumeReader $VolumeReader
    [pscustomobject]@{
        PlanType = 'ManualHandoffOnly'
        SourceChecksumStatus = [string]$analysis.Source.ChecksumStatus
        Instructions = @(
            'Review BitLocker state and recovery-key readiness outside automated BoostLab mutation.'
            'Use Windows BitLocker Drive Encryption settings manually if a technician intentionally chooses to continue.'
            'Confirm recovery keys are backed up before any BitLocker disable, decrypt, suspend, or protector operation.'
            'Do not treat Default as Restore; no captured BitLocker restore state exists.'
            'No external tool is opened by BoostLab.'
            'No BitLocker state mutation is executed by BoostLab.'
        )
        BlockedActions = @(
            'Disable-BitLocker'
            'Enable-BitLocker'
            'Suspend-BitLocker'
            'Resume-BitLocker'
            'manage-bde mutation'
            'protector add/remove'
            'decrypt drive'
            'silent Control Panel launch'
            'Default'
            'Restore'
        )
        Blockers = @($analysis.Blockers)
        Warnings = @($analysis.Warnings)
        VolumeDiscovery = $analysis.VolumeDiscovery
        NoExternalToolOpened = $true
        NoBitLockerMutation = $true
        NoDownload = $true
        NoReboot = $true
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
        ConfirmationRequiredActions = @('Open', 'Apply', 'Default', 'Restore')
        ConfirmationText = 'BitLocker is security-sensitive. BoostLab will not enable, disable, decrypt, suspend, resume, remove protectors, or mutate recovery-key state. Continue with the selected non-mutating result?'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabBitLockerSourceStatus
    [pscustomobject]@{
        Supported = $true
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason = 'BitLocker Analyze and manual handoff are available. BitLocker mutation actions remain blocked.'
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

        [bool]$Confirmed = $false,

        [scriptblock]$VolumeReader
    )

    $canonicalActionName = switch ($ActionName) {
        'Manual Handoff' { 'Open' }
        'Prepare Manual Handoff' { 'Open' }
        default { $ActionName }
    }

    if ($canonicalActionName -notin @($script:BoostLabImplementedActions)) {
        return New-BoostLabBitLockerResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'UnsupportedAction' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Blocked' `
            -Message "BitLocker action '$ActionName' is not supported." `
            -Errors @("Unsupported BitLocker action: $ActionName")
    }

    if ($canonicalActionName -eq 'Analyze') {
        $analysis = Get-BoostLabBitLockerAnalysis -VolumeReader $VolumeReader
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        $verificationStatus = if (-not $sourceOk) {
            [string]$analysis.Source.ChecksumStatus
        }
        elseif (-not [bool]$analysis.VolumeDiscovery.QuerySucceeded) {
            'Warning'
        }
        else {
            'Passed'
        }

        return New-BoostLabBitLockerResult `
            -Success $sourceOk `
            -Action 'Analyze' `
            -Status $(if ($sourceOk) { 'Analyzed' } else { 'SourceVerificationFailed' }) `
            -CommandStatus 'No execution performed' `
            -VerificationStatus $verificationStatus `
            -Message $(if ($sourceOk) { 'BitLocker analyzed read-only. Apply, Default, and Restore remain blocked.' } else { 'BitLocker source checksum verification failed or source mirror is missing.' }) `
            -Data $analysis `
            -Warnings @() `
            -Errors $(if ($sourceOk) { @() } else { @('BitLocker source mirror checksum did not match the expected value or the source mirror is missing.') })
    }

    if ($canonicalActionName -eq 'Open') {
        if (-not $Confirmed) {
            return New-BoostLabBitLockerResult `
                -Success $false `
                -Action 'Open' `
                -Status 'Cancelled' `
                -CommandStatus 'Cancelled before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'BitLocker manual handoff cancelled. No BitLocker state mutation occurred.' `
                -Cancelled $true
        }

        $plan = New-BoostLabBitLockerManualHandoffPlan -VolumeReader $VolumeReader
        $sourceOk = [string]$plan.SourceChecksumStatus -eq 'Passed'
        if (-not $sourceOk) {
            return New-BoostLabBitLockerResult `
                -Success $false `
                -Action 'Open' `
                -Status 'SourceVerificationFailed' `
                -CommandStatus 'Blocked before handoff' `
                -VerificationStatus ([string]$plan.SourceChecksumStatus) `
                -Message 'BitLocker manual handoff blocked because source checksum verification failed or the source mirror is missing.' `
                -Data $plan `
                -Errors @('BitLocker source mirror checksum did not match the expected value or the source mirror is missing.')
        }

        return New-BoostLabBitLockerResult `
            -Success $true `
            -Action 'Open' `
            -Status 'ManualHandoffPrepared' `
            -CommandStatus 'No execution performed' `
            -VerificationStatus 'Passed' `
            -Message 'BitLocker manual handoff prepared. No external tool was opened and no BitLocker state mutation occurred.' `
            -Data $plan
    }

    if ($canonicalActionName -eq 'Apply') {
        $analysis = Get-BoostLabBitLockerAnalysis -VolumeReader $VolumeReader
        return New-BoostLabBitLockerResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'NeedsRecoveryKeyPolicy' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Blocked' `
            -Message 'BitLocker Apply is blocked. The source Off branch disables BitLocker on matched volumes, and BoostLab has no approved recovery-key, volume-selection, encryption-state, protector-state, verification, or support contract for that mutation.' `
            -Data $analysis
    }

    if ($canonicalActionName -eq 'Default') {
        $analysis = Get-BoostLabBitLockerAnalysis -VolumeReader $VolumeReader
        return New-BoostLabBitLockerResult `
            -Success $false `
            -Action 'Default' `
            -Status 'DefaultUnavailable' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'BitLocker Default is unavailable. The source On branch opens BitLocker UI/status only and does not define a safe default mutation; Default is not Restore.' `
            -Data $analysis
    }

    $analysis = Get-BoostLabBitLockerAnalysis -VolumeReader $VolumeReader
    return New-BoostLabBitLockerResult `
        -Success $false `
        -Action 'Restore' `
        -Status 'RestoreUnavailable' `
        -CommandStatus 'Blocked before execution' `
        -VerificationStatus 'NotApplicable' `
        -Message 'BitLocker Restore is unavailable because BoostLab has no valid captured BitLocker state and no approved restore contract.' `
        -Data $analysis
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    Invoke-BoostLabToolAction -ActionName 'Default'
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo',
    'Test-BoostLabToolCompatibility',
    'Get-BoostLabToolState',
    'Invoke-BoostLabToolAction',
    'Restore-BoostLabToolDefault'
)
