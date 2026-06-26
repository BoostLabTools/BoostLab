Set-StrictMode -Version Latest

$script:BoostLabSourceToleratedOutcomeCatalog = @(
    [pscustomobject]@{
        ToolId            = 'store-settings'
        ReasonCode        = 'BestEffortVerified'
        SourceTolerance   = 'Ultimate stops Store processes best-effort and continues when settings verification passes.'
        SourcePatterns    = @('Stop-Process', '-ErrorAction SilentlyContinue')
        DefaultSeverity   = 'Info'
        AppliesWhen       = 'Store process stop reports a non-fatal result, command execution has no errors, and Store registry/settings verification passed.'
        BlanketSuppression = $false
    }
    [pscustomobject]@{
        ToolId            = 'cleanup'
        ReasonCode        = 'VolatileLeftoverIgnored'
        SourceTolerance   = 'Ultimate cleanup uses suppressed recursive deletion where locked, recreated, or access-denied volatile Temp items can remain.'
        SourcePatterns    = @('Remove-Item', '-ErrorAction SilentlyContinue')
        DefaultSeverity   = 'Info'
        AppliesWhen       = 'Only volatile Temp wildcard contents remain with lock, recreation, or access-denied evidence and non-volatile cleanup targets verify absent.'
        BlanketSuppression = $false
    }
    [pscustomobject]@{
        ToolId            = 'bloatware'
        ReasonCode        = 'SourceToleratedProtectedAppx'
        SourceTolerance   = 'Modern Windows can protect source-matched AppX packages from removal.'
        SourcePatterns    = @('Remove-AppxPackage', 'SystemApps')
        DefaultSeverity   = 'Info'
        AppliesWhen       = 'A known protected Windows/AppX package is skipped and UnexpectedFailureCount remains 0.'
        BlanketSuppression = $false
    }
    [pscustomobject]@{
        ToolId            = 'bloatware'
        ReasonCode        = 'SourceToleratedDependencyFramework'
        SourceTolerance   = 'Dependency/framework AppX packages can be non-removable while the source bloatware branch still continues.'
        SourcePatterns    = @('Remove-AppxPackage', 'framework')
        DefaultSeverity   = 'Info'
        AppliesWhen       = 'A dependency or framework package removal is skipped and no unexpected AppX failure is recorded.'
        BlanketSuppression = $false
    }
    [pscustomobject]@{
        ToolId            = 'bloatware'
        ReasonCode        = 'SourceToleratedInUseFrameworkRuntime'
        SourceTolerance   = 'Windows App Runtime framework packages may be in use and non-removable on a live system.'
        SourcePatterns    = @('Remove-AppxPackage', 'currently in use')
        DefaultSeverity   = 'Info'
        AppliesWhen       = 'Only known in-use framework/runtime packages are skipped and ordinary consumer AppX failures still fail closed.'
        BlanketSuppression = $false
    }
    [pscustomobject]@{
        ToolId            = 'bloatware'
        ReasonCode        = 'SourceToleratedMissingTarget'
        SourceTolerance   = 'Legacy source targets such as SnippingTool.exe may already be absent on modern Windows.'
        SourcePatterns    = @('SnippingTool.exe', 'Start-Process')
        DefaultSeverity   = 'Info'
        AppliesWhen       = 'The legacy Snipping Tool executable is absent, so the uninstall process is skipped without attempting Start-Process.'
        BlanketSuppression = $false
    }
    [pscustomobject]@{
        ToolId            = 'bloatware'
        ReasonCode        = 'ExpectedNoOp'
        SourceTolerance   = 'MSI uninstall lookups are uninstall-if-present operations.'
        SourcePatterns    = @('DisplayName', 'msiexec.exe')
        DefaultSeverity   = 'Info'
        AppliesWhen       = 'Missing DisplayName or no matching DisplayName produces no uninstall attempt and no failure count.'
        BlanketSuppression = $false
    }
    [pscustomobject]@{
        ToolId            = 'installers'
        ReasonCode        = 'ExpectedNoOp'
        SourceTolerance   = 'Installer cleanup by DisplayName is a lookup/uninstall-if-present operation.'
        SourcePatterns    = @('DisplayName', 'msiexec.exe')
        DefaultSeverity   = 'Info'
        AppliesWhen       = 'No matching DisplayName exists, so no uninstall command is attempted.'
        BlanketSuppression = $false
    }
    [pscustomobject]@{
        ToolId            = 'power-plan'
        ReasonCode        = 'HardwareSpecificUnsupportedSetting'
        SourceTolerance   = 'Ultimate applies GPU and battery-specific power settings that may not exist on every machine.'
        SourcePatterns    = @('powercfg', 'setting specified does not exist')
        DefaultSeverity   = 'Info'
        AppliesWhen       = 'The active target plan is verified, no unexpected failures occurred, and only hardware-specific or unreadable optional power settings were unavailable.'
        BlanketSuppression = $false
    }
    [pscustomobject]@{
        ToolId            = 'power-plan'
        ReasonCode        = 'ActiveSchemeDeleteAttemptExpected'
        SourceTolerance   = 'Ultimate enumerates and deletes schemes even when the active target scheme cannot be deleted.'
        SourcePatterns    = @('powercfg /delete', 'active power scheme cannot be deleted')
        DefaultSeverity   = 'Info'
        AppliesWhen       = 'The active target scheme remains verified and the delete failure is only the expected active-scheme protection.'
        BlanketSuppression = $false
    }
    [pscustomobject]@{
        ToolId            = 'power-plan'
        ReasonCode        = 'ExistingTargetSchemeReuse'
        SourceTolerance   = 'The BoostLab fixed GUID can already exist from a previous Ultimate power-plan run.'
        SourcePatterns    = @('powercfg /duplicatescheme', 'specified GUID already exists')
        DefaultSeverity   = 'Info'
        AppliesWhen       = 'The duplicate-scheme command reports an existing target GUID and the target scheme is detected and activated.'
        BlanketSuppression = $false
    }
    [pscustomobject]@{
        ToolId            = 'network-adapter-power-savings-wake'
        ReasonCode        = 'HardwareSpecificUnsupportedSetting'
        SourceTolerance   = 'Network adapter driver properties are hardware and driver specific.'
        SourcePatterns    = @('adapter registry value', 'driver does not expose this property')
        DefaultSeverity   = 'Info'
        AppliesWhen       = 'Only unsupported or absent optional adapter properties are reported while all accessible required values verify.'
        BlanketSuppression = $false
    }
    [pscustomobject]@{
        ToolId            = 'notepad-settings'
        ReasonCode        = 'NativeExitCodeMissingRecoveredByVerification'
        SourceTolerance   = 'Native reg.exe wrappers can lose an exit code while still producing success output; BoostLab accepts this only after mounted hive value verification passes.'
        SourcePatterns    = @('reg import', 'The operation completed successfully.')
        DefaultSeverity   = 'Info'
        AppliesWhen       = 'The import reports successful native output without a captured exit code, all required Notepad hive values match, and no import or verification error remains.'
        BlanketSuppression = $false
    }
    [pscustomobject]@{
        ToolId            = 'notepad-settings'
        ReasonCode        = 'PreExistingHiveMountRecovered'
        SourceTolerance   = 'BoostLab may safely unload an owned/stale HKLM:\Settings mount before running the source-defined Notepad hive import.'
        SourcePatterns    = @('reg unload', 'HKLM\Settings')
        DefaultSeverity   = 'Info'
        AppliesWhen       = 'The pre-existing mount is unloadable, the import continues, all required Notepad hive values match, and no user action is needed.'
        BlanketSuppression = $false
    }
    [pscustomobject]@{
        ToolId            = 'notepad-settings'
        ReasonCode        = 'HiveLoadAccessDeniedRecovered'
        SourceTolerance   = 'A transient reg load access-denied result can be recovered by the source-equivalent Notepad stop/delay retry before hive verification.'
        SourcePatterns    = @('reg load', 'access denied')
        DefaultSeverity   = 'Info'
        AppliesWhen       = 'The first hive load reports access denied, the bounded retry succeeds, all required Notepad hive values match, and no user action is needed.'
        BlanketSuppression = $false
    }
    [pscustomobject]@{
        ToolId            = 'device-manager-power-savings-wake'
        ReasonCode        = 'SourceToleratedAccessDenied'
        SourceTolerance   = 'Some source-approved device registry paths may be protected or inaccessible on a live system.'
        SourcePatterns    = @('Requested registry access is not allowed', 'UnauthorizedAccessException')
        DefaultSeverity   = 'Warning'
        AppliesWhen       = 'Access-denied device paths are bounded diagnostics; they remain Warning unless the final target state is otherwise verified.'
        BlanketSuppression = $false
    }
)

function Get-BoostLabSourceToleratedOutcomeCatalog {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [string]$ToolId = '',
        [string]$ReasonCode = ''
    )

    $entries = @($script:BoostLabSourceToleratedOutcomeCatalog)
    if (-not [string]::IsNullOrWhiteSpace($ToolId)) {
        $entries = @($entries | Where-Object { [string]$_.ToolId -eq $ToolId })
    }
    if (-not [string]::IsNullOrWhiteSpace($ReasonCode)) {
        $entries = @($entries | Where-Object { [string]$_.ReasonCode -eq $ReasonCode })
    }

    return $entries
}

function Test-BoostLabSourceToleratedOutcome {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ReasonCode
    )

    return @(
        Get-BoostLabSourceToleratedOutcomeCatalog -ToolId $ToolId -ReasonCode $ReasonCode
    ).Count -gt 0
}

function New-BoostLabSourceToleratedOutcomeNote {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ReasonCode,

        [Parameter(Mandatory)]
        [string]$Message,

        [AllowNull()]
        [object]$Details = $null
    )

    $entry = @(Get-BoostLabSourceToleratedOutcomeCatalog -ToolId $ToolId -ReasonCode $ReasonCode) | Select-Object -First 1
    if ($null -eq $entry) {
        throw "Unknown source-tolerated outcome: $ToolId/$ReasonCode."
    }

    return [pscustomobject]@{
        ToolId          = $ToolId
        ReasonCode      = $ReasonCode
        Severity        = [string]$entry.DefaultSeverity
        Message         = $Message
        SourceTolerance = [string]$entry.SourceTolerance
        AppliesWhen     = [string]$entry.AppliesWhen
        Details         = $Details
        Timestamp       = Get-Date
    }
}

Export-ModuleMember -Function @(
    'Get-BoostLabSourceToleratedOutcomeCatalog'
    'Test-BoostLabSourceToleratedOutcome'
    'New-BoostLabSourceToleratedOutcomeNote'
)
