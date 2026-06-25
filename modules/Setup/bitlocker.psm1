Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'bitlocker'
    Title = 'BitLocker'
    Stage = 'Setup'
    Order = 1
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Analyze BitLocker state, run source-equivalent Off behavior, or open source-equivalent On/status behavior with explicit confirmation.'
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
$script:BoostLabExpectedCanonicalSourceHash = '1678E97FB5AFF851F1491A2D96C82A5716B1FA07CB4E3A4A5E0F3FB1B086FBA1'
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
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $sourceVerificationModulePath = Join-Path $projectRoot 'core\SourceVerification.psm1'
    if (-not (Get-Command -Name 'Test-BoostLabSourceChecksum' -ErrorAction SilentlyContinue)) {
        Import-Module -Name $sourceVerificationModulePath -Scope Local -Force -ErrorAction Stop
    }

    $verification = Test-BoostLabSourceChecksum -LiteralPath $sourcePath -ExpectedSha256 $script:BoostLabExpectedSourceHash -ExpectedCanonicalSha256 $script:BoostLabExpectedCanonicalSourceHash

    [pscustomobject]@{
        SourcePath                = $sourcePath
        SourceRelativePath        = $script:BoostLabSourceRelativePath
        Exists                    = [bool]$verification.Exists
        ExpectedSha256            = $script:BoostLabExpectedSourceHash
        DetectedSha256            = [string]$verification.DetectedSha256
        ExpectedCanonicalSha256   = $script:BoostLabExpectedCanonicalSourceHash
        DetectedCanonicalSha256   = [string]$verification.DetectedCanonicalSha256
        ChecksumStatus            = [string]$verification.ChecksumStatus
        RawChecksumStatus         = [string]$verification.RawChecksumStatus
        CanonicalChecksumStatus   = [string]$verification.CanonicalChecksumStatus
        VerificationMode          = [string]$verification.VerificationMode
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
        ApplyMapping = 'Apply corresponds to the source Off branch and disables BitLocker for matched volumes after explicit confirmation.'
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
        'DefaultUnavailable'
        'RestoreUnavailableWithoutCapturedBitLockerState'
    )
}

function Get-BoostLabBitLockerRiskWarnings {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    @(
        'Original Ultimate Off branch disables BitLocker on every matched protected or not fully decrypted volume.'
        'BoostLab does not silently enable BitLocker, suspend protection, resume protection, or remove protectors.'
        'BoostLab does not collect, display, or store recovery keys.'
        'Default is not Restore, and Restore is unavailable without valid captured BitLocker state.'
        'Open maps to the source On/status branch and does not enable BitLocker automatically.'
    )
}

function New-BoostLabBitLockerCommandResult {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [bool]$Success = $true,

        [string]$CommandStatus = 'Completed',

        [AllowNull()]
        [string]$Target = $null,

        [AllowNull()]
        [object]$ExitCode = $null,

        [string]$Message = '',

        [int]$OutputLineCount = 0
    )

    [pscustomobject]@{
        Name            = $Name
        Success         = $Success
        CommandStatus   = $CommandStatus
        Target          = $Target
        ExitCode        = $ExitCode
        Message         = $Message
        OutputLineCount = $OutputLineCount
        Timestamp       = Get-Date
    }
}

function ConvertTo-BoostLabBitLockerCommandResult {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [AllowNull()]
        [object]$RawResult = $null,

        [AllowNull()]
        [string]$Target = $null,

        [string]$DefaultMessage = ''
    )

    if ($null -eq $RawResult) {
        return New-BoostLabBitLockerCommandResult -Name $Name -Target $Target -Message $DefaultMessage
    }

    $success = Get-BoostLabBitLockerPropertyValue -InputObject $RawResult -Name 'Success' -Default $true
    $commandStatus = [string](Get-BoostLabBitLockerPropertyValue -InputObject $RawResult -Name 'CommandStatus' -Default $(if ([bool]$success) { 'Completed' } else { 'Failed' }))
    $exitCode = Get-BoostLabBitLockerPropertyValue -InputObject $RawResult -Name 'ExitCode' -Default $null
    $message = [string](Get-BoostLabBitLockerPropertyValue -InputObject $RawResult -Name 'Message' -Default $DefaultMessage)
    $output = @(Get-BoostLabBitLockerPropertyValue -InputObject $RawResult -Name 'Output' -Default @())
    $outputLineCount = [int](Get-BoostLabBitLockerPropertyValue -InputObject $RawResult -Name 'OutputLineCount' -Default $output.Count)

    return New-BoostLabBitLockerCommandResult `
        -Name $Name `
        -Success:([bool]$success) `
        -CommandStatus $commandStatus `
        -Target $Target `
        -ExitCode $exitCode `
        -Message $message `
        -OutputLineCount $outputLineCount
}

function Invoke-BoostLabBitLockerDisableForMountPoint {
    param(
        [Parameter(Mandatory)]
        [string]$MountPoint,

        [scriptblock]$DisableBitLockerExecutor
    )

    try {
        if ($null -ne $DisableBitLockerExecutor) {
            $rawResult = & $DisableBitLockerExecutor -MountPoint $MountPoint
            return ConvertTo-BoostLabBitLockerCommandResult `
                -Name 'Disable-BitLocker' `
                -RawResult $rawResult `
                -Target $MountPoint `
                -DefaultMessage "Disable-BitLocker invoked for $MountPoint."
        }

        Disable-BitLocker -MountPoint $MountPoint -ErrorAction SilentlyContinue | Out-Null
        return New-BoostLabBitLockerCommandResult `
            -Name 'Disable-BitLocker' `
            -Target $MountPoint `
            -Message "Disable-BitLocker invoked for $MountPoint with ErrorAction SilentlyContinue."
    }
    catch {
        return New-BoostLabBitLockerCommandResult `
            -Name 'Disable-BitLocker' `
            -Success $false `
            -CommandStatus 'Failed' `
            -Target $MountPoint `
            -Message "Disable-BitLocker failed for ${MountPoint}: $($_.Exception.Message)"
    }
}

function Invoke-BoostLabBitLockerControlPanel {
    param(
        [scriptblock]$ControlPanelLauncher
    )

    try {
        if ($null -ne $ControlPanelLauncher) {
            $rawResult = & $ControlPanelLauncher -FilePath 'control.exe' -ArgumentList '/name microsoft.bitlockerdriveencryption'
            return ConvertTo-BoostLabBitLockerCommandResult `
                -Name 'Start-Process control.exe' `
                -RawResult $rawResult `
                -DefaultMessage 'BitLocker Drive Encryption Control Panel launch requested.'
        }

        Start-Process -FilePath 'control.exe' -ArgumentList '/name microsoft.bitlockerdriveencryption' -ErrorAction Stop
        return New-BoostLabBitLockerCommandResult `
            -Name 'Start-Process control.exe' `
            -Message 'BitLocker Drive Encryption Control Panel launch requested.'
    }
    catch {
        return New-BoostLabBitLockerCommandResult `
            -Name 'Start-Process control.exe' `
            -Success $false `
            -CommandStatus 'Failed' `
            -Message "BitLocker Drive Encryption Control Panel launch failed: $($_.Exception.Message)"
    }
}

function Invoke-BoostLabBitLockerManageBdeStatus {
    param(
        [scriptblock]$ManageBdeStatusExecutor
    )

    try {
        if ($null -ne $ManageBdeStatusExecutor) {
            $rawResult = & $ManageBdeStatusExecutor -ArgumentList @('-status')
            return ConvertTo-BoostLabBitLockerCommandResult `
                -Name 'manage-bde -status' `
                -RawResult $rawResult `
                -DefaultMessage 'manage-bde status requested.'
        }

        $manageBdePath = Join-Path $env:SystemRoot 'System32\manage-bde.exe'
        $output = if (Test-Path -LiteralPath $manageBdePath -PathType Leaf) {
            @(& $manageBdePath -status 2>&1)
        }
        else {
            @(& manage-bde -status 2>&1)
        }
        $exitCode = $LASTEXITCODE

        return New-BoostLabBitLockerCommandResult `
            -Name 'manage-bde -status' `
            -Success:($exitCode -eq 0) `
            -CommandStatus $(if ($exitCode -eq 0) { 'Completed' } else { 'Completed with errors' }) `
            -ExitCode $exitCode `
            -Message $(if ($exitCode -eq 0) { 'manage-bde status completed.' } else { "manage-bde status returned exit code $exitCode." }) `
            -OutputLineCount @($output).Count
    }
    catch {
        return New-BoostLabBitLockerCommandResult `
            -Name 'manage-bde -status' `
            -Success $false `
            -CommandStatus 'Failed' `
            -Message "manage-bde status failed: $($_.Exception.Message)"
    }
}

function Get-BoostLabBitLockerSourceOffTargetVolumes {
    param(
        [Parameter(Mandatory)]
        [object]$VolumeSnapshot
    )

    @(
        @($VolumeSnapshot.Volumes) |
            Where-Object { [bool]$_.WouldMatchSourceOffFilter }
    )
}

function New-BoostLabBitLockerOperationPlan {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Off', 'OnStatus')]
        [string]$Branch,

        [object[]]$TargetVolumes = @()
    )

    $targetMountPoints = @(
        @($TargetVolumes) |
            ForEach-Object { [string]$_.MountPoint } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and $_ -ne 'Unknown' }
    )

    [pscustomobject]@{
        Branch = $Branch
        SourceEquivalent = $true
        TargetMountPoints = @($targetMountPoints)
        TargetVolumeCount = @($targetMountPoints).Count
        Commands = if ($Branch -eq 'Off') {
            @(
                'Get-BitLockerVolume'
                'Disable-BitLocker -MountPoint <mount> -ErrorAction SilentlyContinue'
                'Start-Process control.exe -ArgumentList "/name microsoft.bitlockerdriveencryption"'
                'manage-bde -status'
            )
        }
        else {
            @(
                'Start-Process control.exe -ArgumentList "/name microsoft.bitlockerdriveencryption"'
                'manage-bde -status'
            )
        }
        RecoveryKeysCollected = $false
        RecoveryKeysDisplayed = $false
        RecoveryKeysPersisted = $false
        AutomaticEnableBitLocker = $false
        DefaultIsRestore = $false
        RestoreAvailable = $false
    }
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

        [bool]$Cancelled = $false,

        [bool]$ChangesExecuted = $false
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
        ChangesExecuted = $ChangesExecuted
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
    $offTargetVolumes = @(Get-BoostLabBitLockerSourceOffTargetVolumes -VolumeSnapshot $volumeSnapshot)

    [pscustomobject]@{
        Mode = 'SourceEquivalentControlled'
        ApplyStatus = 'SourceEquivalentOffAvailable'
        OpenStatus = 'SourceEquivalentOnStatusAvailable'
        DefaultStatus = 'DefaultUnavailable'
        RestoreStatus = 'RestoreUnavailable'
        Source = $source
        SourceBehavior = Get-BoostLabBitLockerSourceBehavior
        VolumeDiscovery = $volumeSnapshot
        SourceOffTargetMountPoints = @(
            $offTargetVolumes |
                ForEach-Object { [string]$_.MountPoint } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and $_ -ne 'Unknown' }
        )
        SourceOffTargetCount = @($offTargetVolumes).Count
        SourceOffOperationPlan = New-BoostLabBitLockerOperationPlan -Branch 'Off' -TargetVolumes $offTargetVolumes
        SourceOnStatusOperationPlan = New-BoostLabBitLockerOperationPlan -Branch 'OnStatus'
        Blockers = @($blockers)
        Warnings = @(Get-BoostLabBitLockerRiskWarnings)
        ApplyAvailable = $true
        OpenAvailable = $true
        DefaultAvailable = $false
        RestoreAvailable = $false
        NoMutationOccurred = $true
        NoRecoveryKeysCollectedDisplayedOrPersisted = $true
        NoAutomaticEnableBitLocker = $true
        GraphicsWorkflowRelationship = 'BitLocker remains separate from the Graphics workflow.'
    }
}

function New-BoostLabBitLockerStatusPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [scriptblock]$VolumeReader
    )

    $analysis = Get-BoostLabBitLockerAnalysis -VolumeReader $VolumeReader
    [pscustomobject]@{
        PlanType = 'SourceEquivalentOnStatus'
        SourceChecksumStatus = [string]$analysis.Source.ChecksumStatus
        Instructions = @(
            'Open the BitLocker Drive Encryption Control Panel.'
            'Run manage-bde -status.'
            'Do not enable BitLocker automatically; the Ultimate On branch is UI/status-only.'
            'Do not treat Default as Restore; no captured BitLocker restore state exists.'
            'Do not collect, display, or store recovery keys.'
        )
        BlockedActions = @(
            'Enable-BitLocker'
            'Suspend-BitLocker'
            'Resume-BitLocker'
            'protector add/remove'
            'Default'
            'Restore'
        )
        Blockers = @($analysis.Blockers)
        Warnings = @($analysis.Warnings)
        VolumeDiscovery = $analysis.VolumeDiscovery
        OperationPlan = $analysis.SourceOnStatusOperationPlan
        NoAutomaticEnableBitLocker = $true
        NoBitLockerMutation = $true
        NoRecoveryKeysCollectedDisplayedOrPersisted = $true
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
        ConfirmationText = 'BitLocker is security-sensitive. Apply may disable or decrypt matched BitLocker volumes. Open launches the BitLocker status UI and manage-bde status. Recovery keys are not collected or stored. Continue?'
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
        Reason = 'BitLocker Analyze, source-equivalent Off, and source-equivalent On/status actions are available with explicit confirmation.'
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
        Status = 'SourceEquivalentControlled'
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

        [scriptblock]$VolumeReader,

        [scriptblock]$DisableBitLockerExecutor,

        [scriptblock]$ControlPanelLauncher,

        [scriptblock]$ManageBdeStatusExecutor
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
            -Message $(if ($sourceOk) { 'BitLocker analyzed read-only. Apply maps to the source Off branch, Open maps to the source On/status branch, and Default/Restore remain unavailable.' } else { 'BitLocker source checksum verification failed or source mirror is missing.' }) `
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
                -Message 'BitLocker On/status action cancelled. No Control Panel launch, manage-bde status command, or BitLocker state mutation occurred.' `
                -Cancelled $true
        }

        $plan = New-BoostLabBitLockerStatusPlan -VolumeReader $VolumeReader
        $sourceOk = [string]$plan.SourceChecksumStatus -eq 'Passed'
        if (-not $sourceOk) {
            return New-BoostLabBitLockerResult `
                -Success $false `
                -Action 'Open' `
                -Status 'SourceVerificationFailed' `
                -CommandStatus 'Blocked before execution' `
                -VerificationStatus ([string]$plan.SourceChecksumStatus) `
                -Message 'BitLocker On/status action blocked because source checksum verification failed or the source mirror is missing.' `
                -Data $plan `
                -Errors @('BitLocker source mirror checksum did not match the expected value or the source mirror is missing.')
        }

        $controlPanelResult = Invoke-BoostLabBitLockerControlPanel -ControlPanelLauncher $ControlPanelLauncher
        $manageBdeResult = Invoke-BoostLabBitLockerManageBdeStatus -ManageBdeStatusExecutor $ManageBdeStatusExecutor
        $warnings = @(
            @($controlPanelResult, $manageBdeResult) |
                Where-Object { -not [bool]$_.Success } |
                ForEach-Object { [string]$_.Message }
        )
        $success = @($warnings).Count -eq 0

        return New-BoostLabBitLockerResult `
            -Success:$success `
            -Action 'Open' `
            -Status $(if ($success) { 'StatusOpened' } else { 'StatusOpenedWithWarnings' }) `
            -CommandStatus $(if ($success) { 'Completed' } else { 'Completed with warnings' }) `
            -VerificationStatus $(if ($success) { 'Passed' } else { 'Warning' }) `
            -Message $(if ($success) { 'BitLocker On/status branch completed. Control Panel launch and manage-bde status were requested; no automatic enable occurred.' } else { 'BitLocker On/status branch completed with warnings. No automatic enable occurred.' }) `
            -Data ([pscustomobject]@{
                Plan                                      = $plan
                ControlPanelResult                        = $controlPanelResult
                ManageBdeStatusResult                     = $manageBdeResult
                AutomaticEnableBitLocker                  = $false
                RecoveryKeysCollectedDisplayedOrPersisted = $false
                BitLockerStateMutation                    = $false
                ExternalProcessRequested                  = $true
            }) `
            -Warnings $warnings
    }

    if ($canonicalActionName -eq 'Apply') {
        if (-not $Confirmed) {
            return New-BoostLabBitLockerResult `
                -Success $false `
                -Action 'Apply' `
                -Status 'Cancelled' `
                -CommandStatus 'Cancelled before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'BitLocker Off action cancelled. No Disable-BitLocker, Control Panel launch, manage-bde status command, or BitLocker state mutation occurred.' `
                -Cancelled $true
        }

        $analysis = Get-BoostLabBitLockerAnalysis -VolumeReader $VolumeReader
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        if (-not $sourceOk) {
            return New-BoostLabBitLockerResult `
                -Success $false `
                -Action 'Apply' `
                -Status 'SourceVerificationFailed' `
                -CommandStatus 'Blocked before execution' `
                -VerificationStatus ([string]$analysis.Source.ChecksumStatus) `
                -Message 'BitLocker Off action blocked because source checksum verification failed or the source mirror is missing.' `
                -Data $analysis `
                -Errors @('BitLocker source mirror checksum did not match the expected value or the source mirror is missing.')
        }

        $targetVolumes = @(Get-BoostLabBitLockerSourceOffTargetVolumes -VolumeSnapshot $analysis.VolumeDiscovery)
        $ambiguousTargets = @(
            $targetVolumes |
                Where-Object {
                    [string]::IsNullOrWhiteSpace([string]$_.MountPoint) -or [string]$_.MountPoint -eq 'Unknown'
                }
        )
        if (@($ambiguousTargets).Count -gt 0) {
            return New-BoostLabBitLockerResult `
                -Success $false `
                -Action 'Apply' `
                -Status 'TargetVolumeAmbiguous' `
                -CommandStatus 'Blocked before execution' `
                -VerificationStatus 'Failed' `
                -Message 'BitLocker Off action blocked because one or more source-matched volumes has no reliable MountPoint.' `
                -Data $analysis `
                -Errors @('A source-matched BitLocker volume had no reliable MountPoint for Disable-BitLocker.')
        }

        $operationPlan = New-BoostLabBitLockerOperationPlan -Branch 'Off' -TargetVolumes $targetVolumes
        $disableResults = @(
            foreach ($mountPoint in @($operationPlan.TargetMountPoints)) {
                Invoke-BoostLabBitLockerDisableForMountPoint `
                    -MountPoint $mountPoint `
                    -DisableBitLockerExecutor $DisableBitLockerExecutor
            }
        )
        $controlPanelResult = Invoke-BoostLabBitLockerControlPanel -ControlPanelLauncher $ControlPanelLauncher
        $manageBdeResult = Invoke-BoostLabBitLockerManageBdeStatus -ManageBdeStatusExecutor $ManageBdeStatusExecutor
        $commandResults = @($disableResults) + @($controlPanelResult, $manageBdeResult)
        $warnings = @(
            $commandResults |
                Where-Object { -not [bool]$_.Success } |
                ForEach-Object { [string]$_.Message }
        )
        $success = @($warnings).Count -eq 0
        $changesExecuted = @($disableResults).Count -gt 0

        return New-BoostLabBitLockerResult `
            -Success:$success `
            -Action 'Apply' `
            -Status $(if ($success) { 'Completed' } else { 'CompletedWithWarnings' }) `
            -CommandStatus $(if ($success) { 'Completed' } else { 'Completed with warnings' }) `
            -VerificationStatus $(if ($success) { 'Passed' } else { 'Warning' }) `
            -Message $(if ($success) { 'BitLocker Off branch completed. Disable-BitLocker was invoked for each source-matched target MountPoint, then Control Panel launch and manage-bde status were requested.' } else { 'BitLocker Off branch completed with warnings. Review command outcomes for individual targets.' }) `
            -Data ([pscustomobject]@{
                Analysis                                  = $analysis
                OperationPlan                             = $operationPlan
                DisableResults                            = @($disableResults)
                ControlPanelResult                        = $controlPanelResult
                ManageBdeStatusResult                     = $manageBdeResult
                TargetMountPoints                         = @($operationPlan.TargetMountPoints)
                TargetVolumeCount                         = [int]$operationPlan.TargetVolumeCount
                RecoveryKeysCollectedDisplayedOrPersisted = $false
                AutomaticEnableBitLocker                  = $false
                DisableBitLockerInvoked                   = @($disableResults).Count -gt 0
            }) `
            -Warnings $warnings `
            -ChangesExecuted:$changesExecuted
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
