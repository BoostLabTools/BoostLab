Set-StrictMode -Version Latest

$script:BoostLabLogEntries = [System.Collections.Generic.List[object]]::new()
$script:BoostLabLogSinks = [System.Collections.Generic.List[scriptblock]]::new()

function Initialize-BoostLabLogging {
    [CmdletBinding()]
    param()

    $script:BoostLabLogEntries.Clear()
    $script:BoostLabLogSinks.Clear()
}

function Register-BoostLabLogSink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Sink
    )

    $script:BoostLabLogSinks.Add($Sink)
}

function Write-BoostLabLog {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Level = 'Info',

        [string]$Source = 'BoostLab'
    )

    $entry = [pscustomobject]@{
        Timestamp = Get-Date
        Level     = $Level
        Source    = $Source
        Message   = $Message
    }

    $script:BoostLabLogEntries.Add($entry)

    foreach ($sink in $script:BoostLabLogSinks) {
        try {
            & $sink $entry
        }
        catch {
            Write-Verbose "A BoostLab log sink failed: $($_.Exception.Message)"
        }
    }

    return $entry
}

function Get-BoostLabLog {
    [CmdletBinding()]
    [OutputType([object[]])]
    param()

    return $script:BoostLabLogEntries.ToArray()
}

Export-ModuleMember -Function @(
    'Initialize-BoostLabLogging'
    'Register-BoostLabLogSink'
    'Write-BoostLabLog'
    'Get-BoostLabLog'
)
