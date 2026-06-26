Set-StrictMode -Version Latest

$script:BoostLabAllowedWarningCategories = @(
    'ManualConfirmationPending'
    'VerificationPartial'
    'UserAttentionRequired'
    'WorkflowIncomplete'
    'MeaningfulCompatibilityCaveat'
    'FailedVerification'
    'UnexpectedFailure'
)

$script:BoostLabIntentionalWarningCatalog = @(
    [pscustomobject]@{ ToolId = 'background-apps'; ReasonCode = 'VerificationPartial'; Category = 'VerificationPartial'; AppliesWhen = 'Registry/provider state cannot be fully read after the source-defined operation.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'bitlocker'; ReasonCode = 'EditionOrProtectionStateUserAttention'; Category = 'UserAttentionRequired'; AppliesWhen = 'The host edition or BitLocker protection state prevents a completed verified security transition.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'cleanup'; ReasonCode = 'VerificationUnavailable'; Category = 'VerificationPartial'; AppliesWhen = 'Cleanup verification is unavailable or incomplete; volatile tolerated leftovers use informational outcomes instead.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'context-menu'; ReasonCode = 'VerificationPartial'; Category = 'VerificationPartial'; AppliesWhen = 'Registry verification includes unreadable or partial checks after the source-defined operation.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'control-panel-settings'; ReasonCode = 'NativeRunnerWarning'; Category = 'MeaningfulCompatibilityCaveat'; AppliesWhen = 'The source-backed native runner completed but returned diagnostic warning text that should remain visible.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'copilot'; ReasonCode = 'ProtectedPackageStillPresent'; Category = 'MeaningfulCompatibilityCaveat'; AppliesWhen = 'A protected Copilot package remains present, so the removal outcome is partial and user-visible.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'device-manager-power-savings-wake'; ReasonCode = 'NoApplicableTargetsPartialEnumeration'; Category = 'VerificationPartial'; AppliesWhen = 'No applicable device registry targets are available because class enumeration was partial or missing.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'device-manager-power-savings-wake'; ReasonCode = 'SourceToleratedAccessDeniedUnverified'; Category = 'VerificationPartial'; AppliesWhen = 'Source-approved device registry paths are inaccessible and the final target state cannot be verified as achieved.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'directx'; ReasonCode = 'OptionalOperationWarning'; Category = 'MeaningfulCompatibilityCaveat'; AppliesWhen = 'A non-required DirectX source operation or verification check produced a visible compatibility warning.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'driver-install-debloat-settings'; ReasonCode = 'RefreshConfirmationPending'; Category = 'ManualConfirmationPending'; AppliesWhen = 'NVIDIA refresh-rate confirmation is unavailable, declined, failed, or still pending; restart must not continue silently.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'edge-settings'; ReasonCode = 'VerificationPartialOrServiceCaveat'; Category = 'MeaningfulCompatibilityCaveat'; AppliesWhen = 'The source-equivalent Edge operation completed with a service, process, or verification caveat requiring review.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'memory-compression'; ReasonCode = 'DelayedOrReassertedConvergence'; Category = 'MeaningfulCompatibilityCaveat'; AppliesWhen = 'Memory Compression converged only after bounded reassertion or delayed polling, preserving the existing warning convention.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'network-adapter-power-savings-wake'; ReasonCode = 'NoAccessibleAdapters'; Category = 'WorkflowIncomplete'; AppliesWhen = 'No accessible adapter targets exist, so the source-defined adapter policy cannot be applied or verified.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'network-adapter-power-savings-wake'; ReasonCode = 'SourceToleratedAccessDeniedUnverified'; Category = 'VerificationPartial'; AppliesWhen = 'Adapter registry properties are inaccessible and the final adapter state cannot be verified as achieved.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'notepad-settings'; ReasonCode = 'FileStateReadUnavailableAfterApply'; Category = 'VerificationPartial'; AppliesWhen = 'Notepad hive values verified but the post-operation settings.dat file state could not be read.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'nvidia-app-install'; ReasonCode = 'OptionalOperationWarning'; Category = 'MeaningfulCompatibilityCaveat'; AppliesWhen = 'A non-required NVIDIA App install operation completed with visible diagnostic warning text.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'power-plan'; ReasonCode = 'PowerOptionsUiLaunchWarning'; Category = 'MeaningfulCompatibilityCaveat'; AppliesWhen = 'The power plan state is handled separately from a failed optional power options UI launch.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'signout-lockscreen-wallpaper-black'; ReasonCode = 'VerificationPartial'; Category = 'VerificationPartial'; AppliesWhen = 'Wallpaper or DWM verification is partial after the source-defined operation.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'start-menu-layout'; ReasonCode = 'VerificationPartial'; Category = 'VerificationPartial'; AppliesWhen = 'Start Menu layout verification includes unreadable or partial file/registry checks.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'store-settings'; ReasonCode = 'VerificationPartial'; Category = 'VerificationPartial'; AppliesWhen = 'Store settings verification is incomplete; process-stop best-effort after passed verification is informational instead.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'theme-black'; ReasonCode = 'DwmNormalizationCaveat'; Category = 'MeaningfulCompatibilityCaveat'; AppliesWhen = 'DWM color normalization or verification caveats remain meaningful to the user.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'updates-pause'; ReasonCode = 'VerificationPartial'; Category = 'VerificationPartial'; AppliesWhen = 'Windows Update pause registry/policy verification is partial or unreadable.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'user-account-pictures-black'; ReasonCode = 'VerificationPartial'; Category = 'VerificationPartial'; AppliesWhen = 'User account picture file verification is partial after the source-defined operation.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'visual-cpp'; ReasonCode = 'OptionalOperationWarning'; Category = 'MeaningfulCompatibilityCaveat'; AppliesWhen = 'A non-required Visual C++ source operation completed with visible diagnostic warning text.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'widgets'; ReasonCode = 'VerificationPartial'; Category = 'VerificationPartial'; AppliesWhen = 'Widgets registry/policy verification is partial or unreadable.'; BlanketSuppression = $false }
    [pscustomobject]@{ ToolId = 'write-cache-buffer-flushing'; ReasonCode = 'DiscoveryOrVerificationPartial'; Category = 'VerificationPartial'; AppliesWhen = 'Disk target discovery or verification is partial after the source-defined write-cache operation.'; BlanketSuppression = $false }
)

function Get-BoostLabIntentionalWarningCatalog {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [string]$ToolId = '',
        [string]$ReasonCode = ''
    )

    $entries = @($script:BoostLabIntentionalWarningCatalog)
    if (-not [string]::IsNullOrWhiteSpace($ToolId)) {
        $entries = @($entries | Where-Object { [string]$_.ToolId -eq $ToolId })
    }
    if (-not [string]::IsNullOrWhiteSpace($ReasonCode)) {
        $entries = @($entries | Where-Object { [string]$_.ReasonCode -eq $ReasonCode })
    }

    return $entries
}

function Test-BoostLabIntentionalWarning {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ReasonCode
    )

    return @(Get-BoostLabIntentionalWarningCatalog -ToolId $ToolId -ReasonCode $ReasonCode).Count -gt 0
}

function Test-BoostLabResultSeverityPolicy {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Status,

        [AllowEmptyString()]
        [string]$VerificationStatus = '',

        [string[]]$WarningReasonCodes = @(),

        [bool]$HasUserFacingWarnings = $false,

        [bool]$HasFailedVerification = $false
    )

    $reasons = [System.Collections.Generic.List[string]]::new()
    $isFailedVerification = $HasFailedVerification -or [string]$VerificationStatus -eq 'Failed'
    if ($Success -and $isFailedVerification) {
        $reasons.Add('Successful results cannot contain failed verification.')
    }

    $isWarning = [string]$Status -eq 'Warning' -or [string]$VerificationStatus -eq 'Warning' -or $HasUserFacingWarnings
    if ($isWarning -and @($WarningReasonCodes).Count -eq 0) {
        $reasons.Add('Warnings require at least one explicit intentional warning reason code.')
    }

    foreach ($reasonCode in @($WarningReasonCodes)) {
        if (-not (Test-BoostLabIntentionalWarning -ToolId $ToolId -ReasonCode $reasonCode)) {
            $reasons.Add("Unknown intentional warning reason code for $ToolId`: $reasonCode.")
        }
    }

    if ([string]$Status -in @('Passed', 'Success', 'Completed') -and $HasUserFacingWarnings) {
        $reasons.Add('Passed/Success results must not retain user-facing warnings; use informational diagnostics instead.')
    }

    return [pscustomobject]@{
        Allowed = ($reasons.Count -eq 0)
        Reasons = $reasons.ToArray()
    }
}

Export-ModuleMember -Function @(
    'Get-BoostLabIntentionalWarningCatalog'
    'Test-BoostLabIntentionalWarning'
    'Test-BoostLabResultSeverityPolicy'
)
