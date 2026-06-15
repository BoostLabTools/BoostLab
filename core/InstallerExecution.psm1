Set-StrictMode -Version Latest

function Get-BoostLabInstallerPropertyValue {
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$Name
    )

    if ($null -eq $InputObject) {
        return $null
    }
    if ($InputObject -is [System.Collections.IDictionary]) {
        if ($InputObject.Contains($Name)) {
            return $InputObject[$Name]
        }

        return $null
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function New-BoostLabInstallerExecutionPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Artifact,

        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ActionId,

        [Parameter(Mandatory)]
        [string]$ExactCommandLine,

        [ValidateRange(1, 86400)]
        [int]$TimeoutSeconds = 1800
    )

    return [pscustomobject]@{
        ArtifactId               = [string](
            Get-BoostLabInstallerPropertyValue -InputObject $Artifact -Name 'Id'
        )
        DisplayName              = [string](
            Get-BoostLabInstallerPropertyValue -InputObject $Artifact -Name 'DisplayName'
        )
        ToolId                   = $ToolId
        ActionId                 = $ActionId
        ExactCommandLine         = $ExactCommandLine
        TimeoutSeconds           = $TimeoutSeconds
        RequiresVerifiedArtifact = $true
        RequiresActionPlan       = $true
        NeedsExplicitConfirmation = $true
        CaptureExitCode          = $true
        LogProcessStart          = $true
        LogProcessFinish         = $true
        AllowNetworkExecution    = $false
        AllowUnverifiedTempPath  = $false
        AllowUnrelatedCleanup    = $false
        IsDryRun                 = $true
        Summary                  = 'Validate an approved, locally verified installer request without executing it.'
        Timestamp                = Get-Date
    }
}

function Test-BoostLabInstallerExecutionRequest {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$ProvenanceResult,

        [Parameter(Mandatory)]
        [object]$ActionPlan,

        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ActionId,

        [Parameter(Mandatory)]
        [string]$ExactCommandLine,

        [bool]$Confirmed = $false,

        [ValidateRange(1, 86400)]
        [int]$TimeoutSeconds = 1800
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $verified = [bool](
        Get-BoostLabInstallerPropertyValue -InputObject $ProvenanceResult -Name 'Verified'
    )
    $verifiedPath = [string](
        Get-BoostLabInstallerPropertyValue -InputObject $ProvenanceResult -Name 'VerifiedPath'
    )
    $artifact = Get-BoostLabInstallerPropertyValue -InputObject $ProvenanceResult -Name 'Artifact'

    if (-not $verified) {
        $errors.Add('Installer artifact has not passed provenance verification.')
    }
    if ($null -eq $artifact) {
        $errors.Add('Installer request is missing its artifact definition.')
    }
    else {
        $approvalStatus = [string](
            Get-BoostLabInstallerPropertyValue -InputObject $artifact -Name 'ApprovalStatus'
        )
        $artifactType = [string](
            Get-BoostLabInstallerPropertyValue -InputObject $artifact -Name 'ArtifactType'
        )
        $allowExecution = [bool](
            Get-BoostLabInstallerPropertyValue -InputObject $artifact -Name 'AllowExecution'
        )
        $sourceToolIds = @(
            Get-BoostLabInstallerPropertyValue -InputObject $artifact -Name 'SourceToolIds'
        )
        if ($approvalStatus -ne 'Approved') {
            $errors.Add("Installer artifact approval status is '$approvalStatus', not Approved.")
        }
        if ($artifactType -notin @('Executable', 'Installer')) {
            $errors.Add('Artifact is not classified as executable or installer content.')
        }
        if (-not $allowExecution) {
            $errors.Add('Artifact manifest does not allow execution.')
        }
        if ($ToolId -notin $sourceToolIds) {
            $errors.Add("Artifact is not approved for tool '$ToolId'.")
        }
    }

    if ([string]::IsNullOrWhiteSpace($verifiedPath)) {
        $errors.Add('Installer request does not have a verified local path.')
    }
    elseif ($verifiedPath -match '^[a-zA-Z][a-zA-Z0-9+.-]*://') {
        $errors.Add('Direct network execution is prohibited.')
    }
    if ([string]::IsNullOrWhiteSpace($ExactCommandLine)) {
        $errors.Add('Installer exact command line and switches must be documented.')
    }
    elseif (-not [string]::IsNullOrWhiteSpace($verifiedPath)) {
        $verifiedCommandPrefix = '"{0}"' -f $verifiedPath
        if (
            -not $ExactCommandLine.StartsWith(
                $verifiedCommandPrefix,
                [StringComparison]::OrdinalIgnoreCase
            )
        ) {
            $errors.Add('Installer command line must start with the verified local artifact path.')
        }
    }

    $planToolId = [string](
        Get-BoostLabInstallerPropertyValue -InputObject $ActionPlan -Name 'ToolId'
    )
    $planAction = [string](
        Get-BoostLabInstallerPropertyValue -InputObject $ActionPlan -Name 'Action'
    )
    $planConfirmationRequired = [bool](
        Get-BoostLabInstallerPropertyValue `
            -InputObject $ActionPlan `
            -Name 'NeedsExplicitConfirmation'
    )
    if ($planToolId -ne $ToolId -or $planAction -ne $ActionId) {
        $errors.Add('Action Plan identity does not match the installer request.')
    }
    if (-not $planConfirmationRequired) {
        $errors.Add('Installer Action Plan must require explicit confirmation.')
    }
    if (-not $Confirmed) {
        $errors.Add('Installer execution requires explicit confirmation.')
    }

    return [pscustomobject]@{
        IsAllowed        = $errors.Count -eq 0
        Status           = if ($errors.Count -eq 0) { 'Validated' } else { 'Blocked' }
        ArtifactId       = [string](
            Get-BoostLabInstallerPropertyValue -InputObject $artifact -Name 'Id'
        )
        ToolId           = $ToolId
        ActionId         = $ActionId
        VerifiedPath     = $verifiedPath
        ExactCommandLine = $ExactCommandLine
        TimeoutSeconds   = $TimeoutSeconds
        Confirmed        = $Confirmed
        Errors           = $errors.ToArray()
        Message          = if ($errors.Count -eq 0) {
            'Installer request passed policy validation, but execution remains disabled in Phase 35.'
        }
        else {
            'Installer request is blocked by policy.'
        }
        Timestamp        = Get-Date
    }
}

function Invoke-BoostLabInstallerExecution {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$ProvenanceResult,

        [Parameter(Mandatory)]
        [object]$ActionPlan,

        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ActionId,

        [Parameter(Mandatory)]
        [string]$ExactCommandLine,

        [bool]$Confirmed = $false,

        [ValidateRange(1, 86400)]
        [int]$TimeoutSeconds = 1800
    )

    $validation = Test-BoostLabInstallerExecutionRequest `
        -ProvenanceResult $ProvenanceResult `
        -ActionPlan $ActionPlan `
        -ToolId $ToolId `
        -ActionId $ActionId `
        -ExactCommandLine $ExactCommandLine `
        -Confirmed:$Confirmed `
        -TimeoutSeconds $TimeoutSeconds

    return [pscustomobject]@{
        Success        = $false
        Status         = if ($validation.IsAllowed) { 'NotImplemented' } else { 'Blocked' }
        ArtifactId     = $validation.ArtifactId
        ToolId         = $ToolId
        ActionId       = $ActionId
        CommandLine    = $ExactCommandLine
        ProcessStarted = $false
        ProcessId      = $null
        ExitCode       = $null
        TimedOut       = $false
        Validation     = $validation
        Message        = if ($validation.IsAllowed) {
            'Installer execution is not implemented in Phase 35.'
        }
        else {
            $validation.Message
        }
        Timestamp      = Get-Date
    }
}

Export-ModuleMember -Function @(
    'New-BoostLabInstallerExecutionPlan'
    'Test-BoostLabInstallerExecutionRequest'
    'Invoke-BoostLabInstallerExecution'
)
