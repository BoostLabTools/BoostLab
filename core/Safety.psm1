Set-StrictMode -Version Latest

function Get-BoostLabRiskLevels {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    return @('Low', 'Medium', 'High')
}

function Request-BoostLabRiskConfirmation {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ToolTitle,

        [Parameter(Mandatory)]
        [ValidateSet('Low', 'Medium', 'High')]
        [string]$RiskLevel,

        [Parameter(Mandatory)]
        [string]$Action,

        [bool]$Confirmed = $false
    )

    $requiresConfirmation = $RiskLevel -in @('Medium', 'High')
    return [pscustomobject]@{
        ToolId               = $ToolId
        ToolTitle            = $ToolTitle
        Action               = $Action
        RiskLevel            = $RiskLevel
        ConfirmationRequired = $requiresConfirmation
        Confirmed            = ($Confirmed -or -not $requiresConfirmation)
        RequestedAt          = Get-Date
        Message              = if ($requiresConfirmation) {
            'User confirmation is required before an implemented action may continue.'
        }
        else {
            'No additional risk confirmation is required.'
        }
    }
}

function Request-BoostLabRestorePoint {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ToolTitle,

        [string]$Reason = 'Safety checkpoint requested'
    )

    return [pscustomobject]@{
        ToolId      = $ToolId
        ToolTitle   = $ToolTitle
        Requested   = $true
        Created     = $false
        Reason      = $Reason
        Message     = 'Restore point creation is not implemented yet.'
        Timestamp   = Get-Date
    }
}

function Test-BoostLabHighRiskActionGate {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ToolTitle,

        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [ValidateSet('Low', 'Medium', 'High')]
        [string]$RiskLevel,

        [bool]$Confirmed = $false
    )

    $isHighRisk = $RiskLevel -eq 'High'
    $isAllowed = -not $isHighRisk -or $Confirmed

    return [pscustomobject]@{
        ToolId              = $ToolId
        ToolTitle           = $ToolTitle
        Action              = $Action
        RiskLevel           = $RiskLevel
        IsHighRisk          = $isHighRisk
        ConfirmationRequired = $isHighRisk
        Confirmed           = ($Confirmed -or -not $isHighRisk)
        IsAllowed           = $isAllowed
        Message             = if ($isAllowed) {
            'Safety gate passed.'
        }
        else {
            'High-risk action requires explicit confirmation.'
        }
        EvaluatedAt         = Get-Date
    }
}

function Test-BoostLabActionPlanExecutionGate {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$ActionPlan,

        [bool]$Confirmed = $false,

        [AllowNull()]
        [scriptblock]$ConfirmationCallback
    )

    $requiresConfirmation = [bool]$ActionPlan.NeedsExplicitConfirmation
    $callbackUsed = $false
    $callbackError = ''
    $isConfirmed = $Confirmed -or -not $requiresConfirmation

    if ($requiresConfirmation -and -not $isConfirmed -and $null -ne $ConfirmationCallback) {
        $callbackUsed = $true
        try {
            $isConfirmed = [bool](& $ConfirmationCallback $ActionPlan)
        }
        catch {
            $callbackError = $_.Exception.Message
            $isConfirmed = $false
        }
    }

    return [pscustomobject]@{
        ToolId               = [string]$ActionPlan.ToolId
        ToolTitle            = [string]$ActionPlan.ToolTitle
        Action               = [string]$ActionPlan.Action
        RiskLevel            = [string]$ActionPlan.RiskLevel
        ConfirmationRequired = $requiresConfirmation
        Confirmed            = $isConfirmed
        CallbackUsed         = $callbackUsed
        CallbackError        = $callbackError
        IsAllowed            = (-not $requiresConfirmation -or $isConfirmed)
        Message              = if (-not [string]::IsNullOrWhiteSpace($callbackError)) {
            "Confirmation callback failed: $callbackError"
        }
        elseif (-not $requiresConfirmation) {
            'The action plan does not require explicit confirmation.'
        }
        elseif ($isConfirmed) {
            'The action plan was explicitly confirmed.'
        }
        else {
            'The action plan requires explicit confirmation.'
        }
        EvaluatedAt          = Get-Date
    }
}

function New-BoostLabRestartRequirement {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [bool]$Required,

        [string]$Reason = ''
    )

    return [pscustomobject]@{
        RestartRequired = $Required
        Reason          = $Reason
        RebootInitiated = $false
        Timestamp       = Get-Date
    }
}

function New-BoostLabSafetyAssessment {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolName,

        [ValidateSet('Low', 'Medium', 'High', 'Unassigned')]
        [string]$RiskLevel = 'Unassigned'
    )

    return [pscustomobject]@{
        ToolName      = $ToolName
        IsImplemented = $false
        IsAllowed     = $false
        RiskLevel     = $RiskLevel
        Reason        = 'Tool actions are not implemented yet.'
        EvaluatedAt   = Get-Date
    }
}

Export-ModuleMember -Function @(
    'Get-BoostLabRiskLevels'
    'Request-BoostLabRiskConfirmation'
    'Request-BoostLabRestorePoint'
    'Test-BoostLabHighRiskActionGate'
    'Test-BoostLabActionPlanExecutionGate'
    'New-BoostLabRestartRequirement'
    'New-BoostLabSafetyAssessment'
)
