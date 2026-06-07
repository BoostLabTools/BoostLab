Set-StrictMode -Version Latest

$script:BoostLabState = [ordered]@{}
$script:BoostLabStateDirectory = $null
$script:BoostLabStateFilePath = $null

function Get-BoostLabStateDirectory {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ([string]::IsNullOrWhiteSpace($env:ProgramData)) {
        throw 'The ProgramData environment variable is not available.'
    }

    return Join-Path $env:ProgramData 'BoostLab\State'
}

function New-BoostLabDefaultState {
    return [ordered]@{
        Version         = 1
        CurrentStage    = 'Check'
        CurrentStatus   = 'Ready'
        ToolStates      = @{}
        LastAction      = $null
        LastResult      = $null
        RestartRequired = $false
        PendingRestart  = $false
        UpdatedAt       = Get-Date
    }
}

function ConvertTo-BoostLabStateHashtable {
    param(
        [AllowNull()]
        [object]$InputObject
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        $result = @{}
        foreach ($key in $InputObject.Keys) {
            $result[[string]$key] = ConvertTo-BoostLabStateHashtable -InputObject $InputObject[$key]
        }
        return $result
    }

    if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
        $result = @{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $result[$property.Name] = ConvertTo-BoostLabStateHashtable -InputObject $property.Value
        }
        return $result
    }

    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        return @($InputObject | ForEach-Object { ConvertTo-BoostLabStateHashtable -InputObject $_ })
    }

    return $InputObject
}

function Save-BoostLabState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    if ([string]::IsNullOrWhiteSpace($script:BoostLabStateDirectory)) {
        $script:BoostLabStateDirectory = Get-BoostLabStateDirectory
        $script:BoostLabStateFilePath = Join-Path $script:BoostLabStateDirectory 'runtime-state.json'
    }

    if (-not (Test-Path -LiteralPath $script:BoostLabStateDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $script:BoostLabStateDirectory -Force -ErrorAction Stop | Out-Null
    }

    $script:BoostLabState['UpdatedAt'] = Get-Date
    $json = $script:BoostLabState | ConvertTo-Json -Depth 10
    Set-Content -LiteralPath $script:BoostLabStateFilePath -Value $json -Encoding UTF8 -ErrorAction Stop

    return [pscustomobject]@{
        Success   = $true
        FilePath  = $script:BoostLabStateFilePath
        Timestamp = Get-Date
    }
}

function Initialize-BoostLabState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $script:BoostLabStateDirectory = Get-BoostLabStateDirectory
    $script:BoostLabStateFilePath = Join-Path $script:BoostLabStateDirectory 'runtime-state.json'

    if (-not (Test-Path -LiteralPath $script:BoostLabStateDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $script:BoostLabStateDirectory -Force -ErrorAction Stop | Out-Null
    }

    $state = New-BoostLabDefaultState
    if (Test-Path -LiteralPath $script:BoostLabStateFilePath -PathType Leaf) {
        try {
            $storedState = Get-Content -Raw -LiteralPath $script:BoostLabStateFilePath -ErrorAction Stop |
                ConvertFrom-Json -ErrorAction Stop
            $storedStateTable = ConvertTo-BoostLabStateHashtable -InputObject $storedState
            foreach ($key in $storedStateTable.Keys) {
                $state[$key] = $storedStateTable[$key]
            }
        }
        catch {
            $state = New-BoostLabDefaultState
        }
    }

    if ($state['ToolStates'] -isnot [System.Collections.IDictionary]) {
        $state['ToolStates'] = @{}
    }

    $script:BoostLabState = $state
    Save-BoostLabState | Out-Null

    return [pscustomobject]@{
        StateDirectory = $script:BoostLabStateDirectory
        StateFilePath  = $script:BoostLabStateFilePath
        Loaded         = $true
        Timestamp      = Get-Date
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
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [AllowNull()]
        [object]$Value,

        [switch]$NoSave
    )

    $script:BoostLabState[$Name] = $Value
    if ($Name -eq 'RestartRequired') {
        $script:BoostLabState['PendingRestart'] = [bool]$Value
    }
    elseif ($Name -eq 'PendingRestart') {
        $script:BoostLabState['RestartRequired'] = [bool]$Value
    }

    if (-not $NoSave) {
        Save-BoostLabState | Out-Null
    }

    return [pscustomobject]@{
        Name      = $Name
        Value     = $Value
        Saved     = -not $NoSave
        Timestamp = Get-Date
    }
}

function Set-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$Status,

        [AllowNull()]
        [object]$LastAction,

        [AllowNull()]
        [object]$LastResult,

        [switch]$NoSave
    )

    $toolState = [ordered]@{
        Status     = $Status
        LastAction = $LastAction
        LastResult = $LastResult
        UpdatedAt  = Get-Date
    }
    $script:BoostLabState['ToolStates'][$ToolId] = $toolState
    $script:BoostLabState['LastAction'] = $LastAction
    $script:BoostLabState['LastResult'] = $LastResult

    if (-not $NoSave) {
        Save-BoostLabState | Out-Null
    }

    return [pscustomobject]$toolState
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolId
    )

    if (-not $script:BoostLabState['ToolStates'].Contains($ToolId)) {
        return $null
    }

    return [pscustomobject]$script:BoostLabState['ToolStates'][$ToolId]
}

function Set-BoostLabLastAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Action
    )

    return Set-BoostLabStateValue -Name 'LastAction' -Value $Action
}

function Set-BoostLabLastResult {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Result
    )

    return Set-BoostLabStateValue -Name 'LastResult' -Value $Result
}

function Set-BoostLabRestartRequired {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [bool]$Required,

        [string]$Reason = ''
    )

    $script:BoostLabState['RestartRequired'] = $Required
    $script:BoostLabState['PendingRestart'] = $Required
    $script:BoostLabState['RestartReason'] = $Reason
    Save-BoostLabState | Out-Null

    return [pscustomobject]@{
        RestartRequired = $Required
        Reason          = $Reason
        Saved           = $true
        Timestamp       = Get-Date
    }
}

function Get-BoostLabStateStorageStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        StateDirectory = $script:BoostLabStateDirectory
        StateFilePath  = $script:BoostLabStateFilePath
        Initialized    = -not [string]::IsNullOrWhiteSpace($script:BoostLabStateFilePath)
    }
}

Export-ModuleMember -Function @(
    'Initialize-BoostLabState'
    'Get-BoostLabState'
    'Set-BoostLabStateValue'
    'Save-BoostLabState'
    'Set-BoostLabToolState'
    'Get-BoostLabToolState'
    'Set-BoostLabLastAction'
    'Set-BoostLabLastResult'
    'Set-BoostLabRestartRequired'
    'Get-BoostLabStateStorageStatus'
)
