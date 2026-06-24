Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $verificationModulePath -Scope Local -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'cleanup'
    Title = 'Cleanup'
    Stage = 'Windows'
    Order = 21
    Type = 'action'
    RiskLevel = 'high'
    Description = 'Run the exact Ultimate cleanup branch after explicit confirmation.'
    Actions = @('Apply')
    Capabilities = [ordered]@{
        RequiresAdmin             = $true
        RequiresInternet          = $false
        CanReboot                 = $false
        CanModifyRegistry         = $false
        CanModifyServices         = $false
        CanInstallSoftware        = $false
        CanDownload               = $false
        CanModifyDrivers          = $false
        CanModifySecurity         = $false
        CanDeleteFiles            = $true
        UsesTrustedInstaller      = $false
        UsesSafeMode              = $false
        SupportsDefault           = $false
        SupportsRestore           = $false
        NeedsExplicitConfirmation = $true
    }
}

$script:BoostLabImplementedActions = @('Apply')
$script:BoostLabExpectedSourceHash = '3419A995AD4483A145999B659268302F02BE982733DE831554ADA1C40F07CCAA'
$script:BoostLabExpectedCanonicalSourceHash = '13C3933AC95A9817E48C0FFA4971FB2CC2234F9783831C34675F9F529F2D507E'
$script:BoostLabSourceRelativePath = 'source-ultimate\6 Windows\22 Cleanup.ps1'

function Get-BoostLabCleanupProjectRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

function Get-BoostLabCleanupSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Join-Path (Get-BoostLabCleanupProjectRoot) $script:BoostLabSourceRelativePath
}

function Get-BoostLabCleanupSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabCleanupSourcePath
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

function Test-BoostLabCleanupAdministrator {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function New-BoostLabCleanupTarget {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter(Mandatory)]
        [string]$SourceExpression,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateSet('WildcardContents', 'Directory', 'File')]
        [string]$TargetType,

        [bool]$Recurse = $false
    )

    [pscustomobject]@{
        Id               = $Id
        SourceExpression = $SourceExpression
        Path             = $Path
        TargetType       = $TargetType
        UsesWildcard     = $TargetType -eq 'WildcardContents'
        Recurse          = $Recurse
        Force            = $true
    }
}

function Get-BoostLabCleanupTargets {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [string]$UserProfile = $env:USERPROFILE,
        [string]$SystemDrive = $env:SystemDrive
    )

    if ([string]::IsNullOrWhiteSpace($SystemDrive)) {
        $SystemDrive = 'C:'
    }
    if ([string]::IsNullOrWhiteSpace($UserProfile)) {
        $UserProfile = Join-Path $SystemDrive 'Users\Default'
    }

    @(
        New-BoostLabCleanupTarget `
            -Id 'UserTempContents' `
            -SourceExpression '$env:USERPROFILE\AppData\Local\Temp\*' `
            -Path (Join-Path $UserProfile 'AppData\Local\Temp\*') `
            -TargetType 'WildcardContents' `
            -Recurse $true
        New-BoostLabCleanupTarget `
            -Id 'WindowsTempContents' `
            -SourceExpression '$env:SystemDrive\Windows\Temp\*' `
            -Path (Join-Path $SystemDrive 'Windows\Temp\*') `
            -TargetType 'WildcardContents' `
            -Recurse $true
        New-BoostLabCleanupTarget `
            -Id 'InetpubDirectory' `
            -SourceExpression '$env:SystemDrive\inetpub' `
            -Path (Join-Path $SystemDrive 'inetpub') `
            -TargetType 'Directory' `
            -Recurse $true
        New-BoostLabCleanupTarget `
            -Id 'PerfLogsDirectory' `
            -SourceExpression '$env:SystemDrive\PerfLogs' `
            -Path (Join-Path $SystemDrive 'PerfLogs') `
            -TargetType 'Directory' `
            -Recurse $true
        New-BoostLabCleanupTarget `
            -Id 'WindowsOldDirectory' `
            -SourceExpression '$env:SystemDrive\Windows.old' `
            -Path (Join-Path $SystemDrive 'Windows.old') `
            -TargetType 'Directory' `
            -Recurse $true
        New-BoostLabCleanupTarget `
            -Id 'DumpStackLog' `
            -SourceExpression '$env:SystemDrive\DumpStack.log' `
            -Path (Join-Path $SystemDrive 'DumpStack.log') `
            -TargetType 'File'
    )
}

function Invoke-BoostLabCleanupRemoveTarget {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Target
    )

    $startedAt = Get-Date
    $removeErrors = @()
    try {
        if ([bool]$Target.UsesWildcard) {
            Remove-Item -Path ([string]$Target.Path) -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable +removeErrors | Out-Null
        }
        elseif ([bool]$Target.Recurse) {
            Remove-Item -LiteralPath ([string]$Target.Path) -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable +removeErrors | Out-Null
        }
        else {
            Remove-Item -LiteralPath ([string]$Target.Path) -Force -ErrorAction SilentlyContinue -ErrorVariable +removeErrors | Out-Null
        }

        return [pscustomobject]@{
            Succeeded   = $true
            StartedAt   = $startedAt
            CompletedAt = Get-Date
            ErrorRecords = @(
                foreach ($removeError in @($removeErrors)) {
                    [pscustomobject]@{
                        TargetObject          = [string]$removeError.TargetObject
                        CategoryInfo          = [string]$removeError.CategoryInfo
                        FullyQualifiedErrorId = [string]$removeError.FullyQualifiedErrorId
                        Message               = [string]$removeError.Exception.Message
                    }
                }
            )
            Message     = if (@($removeErrors).Count -gt 0) {
                'Remove-Item completed with suppressed non-terminating error(s), matching the Ultimate SilentlyContinue behavior.'
            }
            else {
                'Remove-Item completed or the target was already absent.'
            }
        }
    }
    catch {
        return [pscustomobject]@{
            Succeeded   = $false
            StartedAt   = $startedAt
            CompletedAt = Get-Date
            ErrorRecords = @(
                [pscustomobject]@{
                    TargetObject          = [string]$Target.Path
                    CategoryInfo          = ''
                    FullyQualifiedErrorId = ''
                    Message               = $_.Exception.Message
                }
            )
            Message     = $_.Exception.Message
        }
    }
}

function Get-BoostLabCleanupTargetState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Target
    )

    try {
        if ([bool]$Target.UsesWildcard) {
            $items = @(Get-ChildItem -Path ([string]$Target.Path) -Force -ErrorAction SilentlyContinue)
            $sampleItems = @(
                $items |
                    Select-Object -First 10 |
                    ForEach-Object {
                        [pscustomobject]@{
                            Path             = [string]$_.FullName
                            Name             = [string]$_.Name
                            LastWriteTimeUtc = $_.LastWriteTimeUtc
                            IsContainer      = [bool]$_.PSIsContainer
                        }
                    }
            )
            return [pscustomobject]@{
                ReadSucceeded = $true
                Exists        = $items.Count -gt 0
                ItemCount     = $items.Count
                RemainingItems = $sampleItems
                DisplayValue  = if ($items.Count -gt 0) { "$($items.Count) matching item(s)" } else { 'No matching items' }
                Message       = 'Wildcard contents inspected.'
            }
        }

        $exists = Test-Path -LiteralPath ([string]$Target.Path)
        $sampleItems = if ($exists) {
            @(
                [pscustomobject]@{
                    Path             = [string]$Target.Path
                    Name             = [IO.Path]::GetFileName([string]$Target.Path)
                    LastWriteTimeUtc = $null
                    IsContainer      = [bool]$Target.Recurse
                }
            )
        }
        else {
            @()
        }
        return [pscustomobject]@{
            ReadSucceeded = $true
            Exists        = $exists
            ItemCount     = if ($exists) { 1 } else { 0 }
            RemainingItems = $sampleItems
            DisplayValue  = if ($exists) { 'Present' } else { 'Absent' }
            Message       = 'Target path inspected.'
        }
    }
    catch {
        return [pscustomobject]@{
            ReadSucceeded = $false
            Exists        = $false
            ItemCount     = $null
            DisplayValue  = 'Unknown'
            Message       = $_.Exception.Message
        }
    }
}

function Get-BoostLabCleanupPropertyValue {
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$Name,

        [AllowNull()]
        [object]$DefaultValue = $null
    )

    if ($null -eq $InputObject) {
        return $DefaultValue
    }
    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $DefaultValue
    }

    return $property.Value
}

function Test-BoostLabCleanupVolatileWildcardTarget {
    param(
        [Parameter(Mandatory)]
        [object]$Target
    )

    return ([bool]$Target.UsesWildcard -and [string]$Target.Id -in @('UserTempContents', 'WindowsTempContents'))
}

function Get-BoostLabCleanupRemovalErrorText {
    param(
        [AllowNull()]
        [object]$RemovalResult
    )

    @(
        foreach ($errorRecord in @(
            Get-BoostLabCleanupPropertyValue -InputObject $RemovalResult -Name 'ErrorRecords' -DefaultValue @()
        )) {
            if ($null -ne $errorRecord) {
                [string](Get-BoostLabCleanupPropertyValue -InputObject $errorRecord -Name 'Message' -DefaultValue $errorRecord)
            }
        }
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }
}

function Get-BoostLabCleanupRemainingItemSamples {
    param(
        [AllowNull()]
        [object]$State,

        [int]$Maximum = 10
    )

    @(
        @(Get-BoostLabCleanupPropertyValue -InputObject $State -Name 'RemainingItems' -DefaultValue @()) |
            Select-Object -First $Maximum |
            ForEach-Object {
                if ($null -eq $_) {
                    return
                }
                [pscustomobject]@{
                    Path             = [string](Get-BoostLabCleanupPropertyValue -InputObject $_ -Name 'Path' -DefaultValue $_)
                    LastWriteTimeUtc = Get-BoostLabCleanupPropertyValue -InputObject $_ -Name 'LastWriteTimeUtc' -DefaultValue $null
                    Classification   = ''
                    Reason           = ''
                }
            }
    )
}

function Get-BoostLabCleanupRemainingClassification {
    param(
        [Parameter(Mandatory)]
        [object]$Target,

        [AllowNull()]
        [object]$State,

        [AllowNull()]
        [object]$RemovalResult,

        [AllowNull()]
        [datetime]$CleanupStartTime = [datetime]::MinValue,

        [AllowNull()]
        [datetime]$CleanupEndTime = [datetime]::MinValue
    )

    $readSucceeded = $null -ne $State -and [bool](Get-BoostLabCleanupPropertyValue -InputObject $State -Name 'ReadSucceeded' -DefaultValue $false)
    if (-not $readSucceeded) {
        return [pscustomobject]@{
            Classification = 'VerificationUnavailable'
            Status         = 'Warning'
            Reason         = if ($null -ne $State) { [string](Get-BoostLabCleanupPropertyValue -InputObject $State -Name 'Message' -DefaultValue 'Target state was unavailable.') } else { 'Target state reader returned no result.' }
        }
    }

    $exists = [bool](Get-BoostLabCleanupPropertyValue -InputObject $State -Name 'Exists' -DefaultValue $false)
    if (-not $exists) {
        return [pscustomobject]@{
            Classification = 'Removed'
            Status         = 'Passed'
            Reason         = 'Target is absent after cleanup.'
        }
    }

    if (-not (Test-BoostLabCleanupVolatileWildcardTarget -Target $Target)) {
        return [pscustomobject]@{
            Classification = 'RemainingUnexpected'
            Status         = 'Failed'
            Reason         = 'Non-volatile source cleanup target still exists after cleanup.'
        }
    }

    $explicitClassification = [string](Get-BoostLabCleanupPropertyValue -InputObject $State -Name 'Classification' -DefaultValue '')
    if ($explicitClassification -in @('RemainingLockedOrInUse', 'RemainingRecreatedAfterCleanup', 'RemainingAccessDenied', 'VerificationUnavailable')) {
        return [pscustomobject]@{
            Classification = $explicitClassification
            Status         = 'Warning'
            Reason         = [string](Get-BoostLabCleanupPropertyValue -InputObject $State -Name 'Message' -DefaultValue "Volatile Temp leftovers classified as $explicitClassification.")
        }
    }
    if ($explicitClassification -eq 'RemainingUnexpected') {
        return [pscustomobject]@{
            Classification = 'RemainingUnexpected'
            Status         = 'Failed'
            Reason         = [string](Get-BoostLabCleanupPropertyValue -InputObject $State -Name 'Message' -DefaultValue 'Volatile Temp leftovers had no expected lock/recreation/access-denied evidence.')
        }
    }

    $errorText = (Get-BoostLabCleanupRemovalErrorText -RemovalResult $RemovalResult) -join ' '
    if ($errorText -match '(?i)access.*denied|unauthorized|permission') {
        return [pscustomobject]@{
            Classification = 'RemainingAccessDenied'
            Status         = 'Warning'
            Reason         = 'Remove-Item reported access-denied/permission evidence for this volatile Temp target.'
        }
    }
    if ($errorText -match '(?i)being used|in use|cannot access.*because.*used|locked|sharing violation|process cannot access') {
        return [pscustomobject]@{
            Classification = 'RemainingLockedOrInUse'
            Status         = 'Warning'
            Reason         = 'Remove-Item reported locked/in-use evidence for this volatile Temp target.'
        }
    }

    $samples = @(Get-BoostLabCleanupRemainingItemSamples -State $State)
    foreach ($sample in $samples) {
        $lastWrite = Get-BoostLabCleanupPropertyValue -InputObject $sample -Name 'LastWriteTimeUtc' -DefaultValue $null
        if ($lastWrite -is [datetime] -and $CleanupStartTime -ne [datetime]::MinValue -and $lastWrite -ge $CleanupStartTime.ToUniversalTime()) {
            return [pscustomobject]@{
                Classification = 'RemainingRecreatedAfterCleanup'
                Status         = 'Warning'
                Reason         = 'Remaining volatile Temp sample was written during or after the cleanup window.'
            }
        }
    }

    return [pscustomobject]@{
        Classification = 'RemainingUnexpected'
        Status         = 'Failed'
        Reason         = 'Volatile Temp contents remained without lock, access-denied, or recreation evidence.'
    }
}

function Test-BoostLabCleanupState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [object[]]$Targets = @(Get-BoostLabCleanupTargets),
        [scriptblock]$TargetStateReader = {
            param($Target)
            Get-BoostLabCleanupTargetState -Target $Target
        },
        [object[]]$RemovalResults = @(),
        [datetime]$CleanupStartTime = [datetime]::MinValue,
        [datetime]$CleanupEndTime = [datetime]::MinValue,
        [string]$CleanMgrStatus = 'Not launched'
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    $removalLookup = @{}
    foreach ($removalResult in @($RemovalResults)) {
        if ($null -ne $removalResult) {
            $targetId = [string](Get-BoostLabCleanupPropertyValue -InputObject $removalResult -Name 'TargetId' -DefaultValue '')
            if (-not [string]::IsNullOrWhiteSpace($targetId)) {
                $removalLookup[$targetId] = $removalResult
            }
        }
    }

    foreach ($target in @($Targets)) {
        $raw = @(& $TargetStateReader $target)
        $state = if ($raw.Count -gt 0) { $raw[0] } else { $null }
        $classification = Get-BoostLabCleanupRemainingClassification `
            -Target $target `
            -State $state `
            -RemovalResult $removalLookup[[string]$target.Id] `
            -CleanupStartTime $CleanupStartTime `
            -CleanupEndTime $CleanupEndTime
        $samples = @(Get-BoostLabCleanupRemainingItemSamples -State $state)
        foreach ($sample in $samples) {
            $sample.Classification = [string]$classification.Classification
            $sample.Reason = [string]$classification.Reason
        }

        $check = New-BoostLabVerificationCheck `
            -Name ("Cleanup target | {0}" -f $target.Id) `
            -Expected 'Absent or no matching wildcard contents' `
            -Actual $(if ($null -ne $state) { [string]$state.DisplayValue } else { 'Unknown' }) `
            -Status ([string]$classification.Status) `
            -Message ([string]$classification.Reason)
        $check | Add-Member -NotePropertyName 'TargetId' -NotePropertyValue ([string]$target.Id) -Force
        $check | Add-Member -NotePropertyName 'TargetType' -NotePropertyValue ([string]$target.TargetType) -Force
        $check | Add-Member -NotePropertyName 'RemainingClassification' -NotePropertyValue ([string]$classification.Classification) -Force
        $check | Add-Member -NotePropertyName 'RemainingItemCount' -NotePropertyValue $(if ($null -ne $state) { [int](Get-BoostLabCleanupPropertyValue -InputObject $state -Name 'ItemCount' -DefaultValue 0) } else { 0 }) -Force
        $check | Add-Member -NotePropertyName 'RemainingSamples' -NotePropertyValue $samples -Force
        $checks.Add($check)
    }

    $checks.Add(
        (New-BoostLabVerificationCheck `
            -Name 'Disk Cleanup UI launch' `
            -Expected 'cleanmgr.exe launch attempted successfully' `
            -Actual $CleanMgrStatus `
            -Status $(if ($CleanMgrStatus -eq 'Launched') { 'Passed' } else { 'Failed' }) `
            -Message 'Ultimate opens Disk Cleanup after deleting the source targets.')
    )

    $failed = @($checks | Where-Object Status -eq 'Failed').Count
    $warnings = @($checks | Where-Object Status -eq 'Warning').Count
    $passed = @($checks | Where-Object Status -eq 'Passed').Count
    $status = if ($failed -gt 0) { 'Failed' } elseif ($warnings -gt 0) { 'Warning' } else { 'Passed' }

    return New-BoostLabVerificationResult `
        -ToolId 'cleanup' `
        -ToolTitle 'Cleanup' `
        -Action 'Apply' `
        -Status $status `
        -ExpectedState ([pscustomobject]@{ Cleanup = 'All source cleanup targets absent and Disk Cleanup launched' }) `
        -DetectedState ([pscustomobject]@{ Cleanup = ('{0} passed, {1} warning, {2} failed' -f $passed, $warnings, $failed) }) `
        -Checks $checks.ToArray() `
        -Message $(switch ($status) {
            'Passed' { 'The expected Cleanup state was detected.' }
            'Warning' { 'Cleanup completed, but one or more targets could not be inspected.' }
            default { 'One or more Cleanup targets remain or Disk Cleanup did not launch.' }
        })
}

function New-BoostLabCleanupResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$CommandStatus,

        [Parameter(Mandatory)]
        [string]$Message,

        [bool]$Cancelled = $false,

        [object]$Data = $null,

        [object]$VerificationResult = $null
    )

    [pscustomobject]@{
        Success            = $Success
        Status             = $Status
        ToolId             = 'cleanup'
        ToolTitle          = 'Cleanup'
        Action             = 'Apply'
        Message            = $Message
        RestartRequired    = $false
        Cancelled          = $Cancelled
        Data               = $Data
        VerificationResult = $VerificationResult
        Timestamp          = Get-Date
    }
}

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        Id                 = [string]$script:BoostLabToolMetadata.Id
        Title              = [string]$script:BoostLabToolMetadata.Title
        Stage              = [string]$script:BoostLabToolMetadata.Stage
        Order              = [int]$script:BoostLabToolMetadata.Order
        Type               = [string]$script:BoostLabToolMetadata.Type
        RiskLevel          = [string]$script:BoostLabToolMetadata.RiskLevel
        Description        = [string]$script:BoostLabToolMetadata.Description
        Actions            = @($script:BoostLabToolMetadata.Actions)
        Capabilities       = [pscustomobject]$script:BoostLabToolMetadata.Capabilities
        ImplementedActions = @($script:BoostLabImplementedActions)
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        Supported = $true
        ToolId = 'cleanup'
        ToolTitle = 'Cleanup'
        Reason = 'Cleanup uses shared Windows filesystem cleanup behavior with no Windows-version branch.'
        Timestamp = Get-Date
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $source = Get-BoostLabCleanupSourceStatus
    [pscustomobject]@{
        ToolId = 'cleanup'
        ToolTitle = 'Cleanup'
        Status = if ($source.ChecksumStatus -eq 'Passed') { 'Ready' } else { "Source $($source.ChecksumStatus)" }
        SourceChecksumStatus = [string]$source.ChecksumStatus
        LastAction = $null
        LastResult = $null
        RestartRequired = $false
        Timestamp = Get-Date
    }
}

function Invoke-BoostLabCleanupApply {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [scriptblock]$AdministratorChecker = { Test-BoostLabCleanupAdministrator },
        [scriptblock]$TargetProvider = { Get-BoostLabCleanupTargets },
        [scriptblock]$TargetRemover = {
            param($Target)
            Invoke-BoostLabCleanupRemoveTarget -Target $Target
        },
        [scriptblock]$TargetStateReader = {
            param($Target)
            Get-BoostLabCleanupTargetState -Target $Target
        },
        [scriptblock]$CleanMgrLauncher = { Start-Process 'cleanmgr.exe' }
    )

    $source = Get-BoostLabCleanupSourceStatus
    if ($source.ChecksumStatus -ne 'Passed') {
        $data = [pscustomobject]@{
            CommandStatus      = 'Blocked'
            VerificationStatus = 'NotAvailable'
            ChangesExecuted    = $false
            SourceStatus       = $source
            TargetsAttempted   = @()
            TargetsRemoved     = @()
            CleanMgrStatus     = 'Not launched'
            Warnings           = @()
            Errors             = @("Cleanup source checksum is $($source.ChecksumStatus).")
        }
        return New-BoostLabCleanupResult -Success $false -Status 'Failed' -CommandStatus 'Blocked' -Message 'Cleanup source identity could not be verified.' -Data $data
    }
    if (-not [bool](& $AdministratorChecker)) {
        $data = [pscustomobject]@{
            CommandStatus      = 'Blocked'
            VerificationStatus = 'NotAvailable'
            ChangesExecuted    = $false
            SourceStatus       = $source
            TargetsAttempted   = @()
            TargetsRemoved     = @()
            CleanMgrStatus     = 'Not launched'
            Warnings           = @()
            Errors             = @('Administrator rights are required.')
        }
        return New-BoostLabCleanupResult -Success $false -Status 'Failed' -CommandStatus 'Blocked' -Message 'Administrator rights are required to run Cleanup.' -Data $data
    }

    $targets = @(& $TargetProvider)
    $cleanupStartTime = Get-Date
    $attempted = [System.Collections.Generic.List[string]]::new()
    $completed = [System.Collections.Generic.List[string]]::new()
    $targetResults = [System.Collections.Generic.List[object]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($target in $targets) {
        $attempted.Add([string]$target.Id)
        $raw = @(& $TargetRemover $target)
        $result = if ($raw.Count -gt 0) { $raw[0] } else { $null }
        $targetResult = [pscustomobject]@{
            TargetId     = [string]$target.Id
            Path         = [string]$target.Path
            TargetType   = [string]$target.TargetType
            UsesWildcard = [bool]$target.UsesWildcard
            Succeeded    = ($null -ne $result -and [bool](Get-BoostLabCleanupPropertyValue -InputObject $result -Name 'Succeeded' -DefaultValue $false))
            Message      = if ($null -ne $result) { [string](Get-BoostLabCleanupPropertyValue -InputObject $result -Name 'Message' -DefaultValue '') } else { 'Target remover returned no result.' }
            StartedAt    = if ($null -ne $result) { Get-BoostLabCleanupPropertyValue -InputObject $result -Name 'StartedAt' -DefaultValue $null } else { $null }
            CompletedAt  = if ($null -ne $result) { Get-BoostLabCleanupPropertyValue -InputObject $result -Name 'CompletedAt' -DefaultValue $null } else { $null }
            ErrorRecords = if ($null -ne $result) { @(Get-BoostLabCleanupPropertyValue -InputObject $result -Name 'ErrorRecords' -DefaultValue @()) } else { @() }
        }
        $targetResults.Add($targetResult)
        if ($null -eq $result -or -not [bool](Get-BoostLabCleanupPropertyValue -InputObject $result -Name 'Succeeded' -DefaultValue $false)) {
            $message = if ($null -ne $result) { [string](Get-BoostLabCleanupPropertyValue -InputObject $result -Name 'Message' -DefaultValue 'Target remover returned no result.') } else { 'Target remover returned no result.' }
            $errors.Add("$($target.Id): $message")
        }
        else {
            $completed.Add([string]$target.Id)
        }
    }

    $cleanMgrStatus = 'Not launched'
    try {
        & $CleanMgrLauncher | Out-Null
        $cleanMgrStatus = 'Launched'
    }
    catch {
        $cleanMgrStatus = "Launch failed: $($_.Exception.Message)"
        $errors.Add("cleanmgr.exe: $($_.Exception.Message)")
    }

    $cleanupEndTime = Get-Date
    $verification = Test-BoostLabCleanupState `
        -Targets $targets `
        -TargetStateReader $TargetStateReader `
        -RemovalResults $targetResults.ToArray() `
        -CleanupStartTime $cleanupStartTime `
        -CleanupEndTime $cleanupEndTime `
        -CleanMgrStatus $cleanMgrStatus
    $remainingTargetChecks = @(
        $verification.Checks |
            Where-Object {
                $null -ne $_.PSObject.Properties['TargetId'] -and
                [string]$_.RemainingClassification -ne 'Removed'
            }
    )
    $volatileRemainingChecks = @(
        $remainingTargetChecks |
            Where-Object {
                [string]$_.TargetId -in @('UserTempContents', 'WindowsTempContents')
            }
    )
    $remainingTempSamples = @(
        $volatileRemainingChecks |
            ForEach-Object { @($_.RemainingSamples) } |
            Select-Object -First 10
    )
    $finalStatusReason = if ($errors.Count -gt 0) {
        'CommandError'
    }
    elseif ([string]$verification.Status -eq 'Failed') {
        'VerificationFailed'
    }
    elseif ($volatileRemainingChecks.Count -gt 0) {
        'VolatileTempLeftovers'
    }
    elseif ([string]$verification.Status -eq 'Warning') {
        'VerificationWarning'
    }
    else {
        'CompletedVerified'
    }
    $data = [pscustomobject]@{
        CommandStatus      = if ($errors.Count -gt 0) { 'Completed with errors' } elseif ($warnings.Count -gt 0) { 'Completed with warnings' } else { 'Completed' }
        VerificationStatus = [string]$verification.Status
        ChangesExecuted    = $attempted.Count -gt 0 -or $cleanMgrStatus -ne 'Not launched'
        SourceStatus       = $source
        CleanupStartTime   = $cleanupStartTime
        CleanupEndTime     = $cleanupEndTime
        CleanupTargets     = @($targets | ForEach-Object { [pscustomobject]@{ Id = $_.Id; SourceExpression = $_.SourceExpression; Path = $_.Path; TargetType = $_.TargetType } })
        CleanupTargetResults = $targetResults.ToArray()
        TargetsAttempted   = $attempted.ToArray()
        TargetsRemoved     = $completed.ToArray()
        RemainingTargetCount = $remainingTargetChecks.Count
        RemainingTempItemCount = @($volatileRemainingChecks | ForEach-Object { [int]$_.RemainingItemCount } | Measure-Object -Sum).Sum
        RemainingTempSamples = $remainingTempSamples
        RemainingTargetClassifications = @(
            $remainingTargetChecks |
                ForEach-Object {
                    [pscustomobject]@{
                        TargetId       = [string]$_.TargetId
                        Classification = [string]$_.RemainingClassification
                        RemainingCount = [int]$_.RemainingItemCount
                        Status         = [string]$_.Status
                        Message        = [string]$_.Message
                    }
                }
        )
        CleanMgrStatus     = $cleanMgrStatus
        Warnings           = $warnings.ToArray()
        Errors             = $errors.ToArray()
        FinalStatusReason  = $finalStatusReason
        CompletedAt        = $cleanupEndTime
    }

    if ($errors.Count -gt 0) {
        return New-BoostLabCleanupResult -Success $false -Status 'Failed' -CommandStatus $data.CommandStatus -Message ('Cleanup completed with errors: {0}' -f ($errors -join '; ')) -Data $data -VerificationResult $verification
    }
    if ($verification.Status -eq 'Failed') {
        return New-BoostLabCleanupResult -Success $false -Status 'Failed' -CommandStatus $data.CommandStatus -Message 'Cleanup commands completed, but verification detected remaining targets.' -Data $data -VerificationResult $verification
    }
    if ($verification.Status -eq 'Warning') {
        return New-BoostLabCleanupResult -Success $true -Status 'Warning' -CommandStatus $data.CommandStatus -Message 'Cleanup completed with verification warnings.' -Data $data -VerificationResult $verification
    }

    return New-BoostLabCleanupResult -Success $true -Status 'Passed' -CommandStatus $data.CommandStatus -Message 'Cleanup completed.' -Data $data -VerificationResult $verification
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ActionName,

        [bool]$Confirmed = $false
    )

    if ($ActionName -ne 'Apply') {
        return New-BoostLabCleanupResult -Success $false -Status 'Failed' -CommandStatus 'Unsupported' -Message 'Unsupported action. Only Apply is source-defined for Cleanup.'
    }
    if (-not $Confirmed) {
        $data = [pscustomobject]@{
            CommandStatus      = 'Cancelled'
            VerificationStatus = 'NotAvailable'
            ChangesExecuted    = $false
            TargetsAttempted   = @()
            TargetsRemoved     = @()
            CleanMgrStatus     = 'Not launched'
            Warnings           = @()
            Errors             = @()
        }
        return New-BoostLabCleanupResult -Success $false -Status 'Cancelled' -CommandStatus 'Cancelled' -Message 'Cancelled by user.' -Cancelled $true -Data $data
    }

    return Invoke-BoostLabCleanupApply
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([bool]$Confirmed = $false)

    return New-BoostLabCleanupResult -Success $false -Status 'Failed' -CommandStatus 'Unsupported' -Message 'Cleanup has no source-defined Default or Restore action.'
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
