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

    try {
        if ([bool]$Target.UsesWildcard) {
            Remove-Item -Path ([string]$Target.Path) -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        }
        elseif ([bool]$Target.Recurse) {
            Remove-Item -LiteralPath ([string]$Target.Path) -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        }
        else {
            Remove-Item -LiteralPath ([string]$Target.Path) -Force -ErrorAction SilentlyContinue | Out-Null
        }

        return [pscustomobject]@{
            Succeeded = $true
            Message   = 'Remove-Item completed or the target was already absent.'
        }
    }
    catch {
        return [pscustomobject]@{
            Succeeded = $false
            Message   = $_.Exception.Message
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
            return [pscustomobject]@{
                ReadSucceeded = $true
                Exists        = $items.Count -gt 0
                ItemCount     = $items.Count
                DisplayValue  = if ($items.Count -gt 0) { "$($items.Count) matching item(s)" } else { 'No matching items' }
                Message       = 'Wildcard contents inspected.'
            }
        }

        $exists = Test-Path -LiteralPath ([string]$Target.Path)
        return [pscustomobject]@{
            ReadSucceeded = $true
            Exists        = $exists
            ItemCount     = if ($exists) { 1 } else { 0 }
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

function Test-BoostLabCleanupState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [object[]]$Targets = @(Get-BoostLabCleanupTargets),
        [scriptblock]$TargetStateReader = {
            param($Target)
            Get-BoostLabCleanupTargetState -Target $Target
        },
        [string]$CleanMgrStatus = 'Not launched'
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    foreach ($target in @($Targets)) {
        $raw = @(& $TargetStateReader $target)
        $state = if ($raw.Count -gt 0) { $raw[0] } else { $null }
        $readable = $null -ne $state -and [bool]$state.ReadSucceeded
        $exists = $readable -and [bool]$state.Exists
        $status = if (-not $readable) {
            'Warning'
        }
        elseif ($exists) {
            'Failed'
        }
        else {
            'Passed'
        }

        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name ("Cleanup target | {0}" -f $target.Id) `
                -Expected 'Absent or no matching wildcard contents' `
                -Actual $(if ($null -ne $state) { [string]$state.DisplayValue } else { 'Unknown' }) `
                -Status $status `
                -Message $(if ($null -ne $state) { [string]$state.Message } else { 'Target state reader returned no result.' }))
        )
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
    $attempted = [System.Collections.Generic.List[string]]::new()
    $completed = [System.Collections.Generic.List[string]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($target in $targets) {
        $attempted.Add([string]$target.Id)
        $raw = @(& $TargetRemover $target)
        $result = if ($raw.Count -gt 0) { $raw[0] } else { $null }
        if ($null -eq $result -or -not [bool]$result.Succeeded) {
            $message = if ($null -ne $result) { [string]$result.Message } else { 'Target remover returned no result.' }
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

    $verification = Test-BoostLabCleanupState -Targets $targets -TargetStateReader $TargetStateReader -CleanMgrStatus $cleanMgrStatus
    $data = [pscustomobject]@{
        CommandStatus      = if ($errors.Count -gt 0) { 'Completed with errors' } elseif ($warnings.Count -gt 0) { 'Completed with warnings' } else { 'Completed' }
        VerificationStatus = [string]$verification.Status
        ChangesExecuted    = $attempted.Count -gt 0 -or $cleanMgrStatus -ne 'Not launched'
        SourceStatus       = $source
        CleanupTargets     = @($targets | ForEach-Object { [pscustomobject]@{ Id = $_.Id; SourceExpression = $_.SourceExpression; Path = $_.Path; TargetType = $_.TargetType } })
        TargetsAttempted   = $attempted.ToArray()
        TargetsRemoved     = $completed.ToArray()
        CleanMgrStatus     = $cleanMgrStatus
        Warnings           = $warnings.ToArray()
        Errors             = $errors.ToArray()
        CompletedAt        = Get-Date
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
