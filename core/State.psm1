Set-StrictMode -Version Latest

$script:BoostLabState = [ordered]@{}

function Initialize-BoostLabState {
    [CmdletBinding()]
    param()

    $script:BoostLabState = [ordered]@{
        CurrentStage   = 'Check'
        CurrentStatus  = 'Ready'
        PendingRestart = $false
        ToolStates     = @{}
    }
}

function Get-BoostLabState {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return $script:BoostLabState
}

function Set-BoostLabStateValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [AllowNull()]
        [object]$Value
    )

    $script:BoostLabState[$Name] = $Value
}

Export-ModuleMember -Function @(
    'Initialize-BoostLabState'
    'Get-BoostLabState'
    'Set-BoostLabStateValue'
)
