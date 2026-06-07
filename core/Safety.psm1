Set-StrictMode -Version Latest

function Get-BoostLabRiskLevels {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    return @('Low', 'Medium', 'High', 'Critical')
}

function New-BoostLabSafetyAssessment {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolName
    )

    [pscustomobject]@{
        ToolName      = $ToolName
        IsImplemented = $false
        IsAllowed     = $false
        RiskLevel     = 'Unassigned'
        Reason        = 'Phase 1 provides interface placeholders only.'
    }
}

Export-ModuleMember -Function @(
    'Get-BoostLabRiskLevels'
    'New-BoostLabSafetyAssessment'
)
