Set-StrictMode -Version Latest

$script:BoostLabLogEntries = [System.Collections.Generic.List[object]]::new()
$script:BoostLabLogSinks = [System.Collections.Generic.List[scriptblock]]::new()
$script:BoostLabLogDirectory = $null
$script:BoostLabLogFilePath = $null
$script:BoostLabFileLoggingEnabled = $true

function Get-BoostLabLogDirectory {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ([string]::IsNullOrWhiteSpace($env:ProgramData)) {
        throw 'The ProgramData environment variable is not available.'
    }

    return Join-Path $env:ProgramData 'BoostLab\Logs'
}

function Protect-BoostLabLogMessage {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    $protectedMessage = $Message
    $sensitivePatterns = @(
        '(?i)(password\s*[:=]\s*)[^\s;,]+'
        '(?i)(token\s*[:=]\s*)[^\s;,]+'
        '(?i)(api[_ -]?key\s*[:=]\s*)[^\s;,]+'
        '(?i)(secret\s*[:=]\s*)[^\s;,]+'
    )

    foreach ($pattern in $sensitivePatterns) {
        $protectedMessage = [regex]::Replace($protectedMessage, $pattern, '$1[REDACTED]')
    }

    return $protectedMessage
}

function ConvertTo-BoostLabSafeLogData {
    param(
        [AllowNull()]
        [System.Collections.IDictionary]$Data
    )

    if ($null -eq $Data) {
        return $null
    }

    $safeData = [ordered]@{}
    foreach ($key in $Data.Keys) {
        $keyName = [string]$key
        if ($keyName -match '(?i)password|token|secret|credential|api[_ -]?key') {
            $safeData[$keyName] = '[REDACTED]'
            continue
        }

        $value = $Data[$key]
        if ($value -is [string]) {
            $safeData[$keyName] = Protect-BoostLabLogMessage -Message $value
        }
        elseif ($null -eq $value -or $value -is [ValueType]) {
            $safeData[$keyName] = $value
        }
        else {
            $safeData[$keyName] = [string]$value
        }
    }

    return $safeData
}

function Initialize-BoostLabLogging {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [switch]$DisableFileLogging
    )

    $script:BoostLabLogEntries.Clear()
    $script:BoostLabLogSinks.Clear()
    $script:BoostLabFileLoggingEnabled = -not $DisableFileLogging
    $script:BoostLabLogDirectory = Get-BoostLabLogDirectory
    $script:BoostLabLogFilePath = Join-Path $script:BoostLabLogDirectory ('BoostLab-{0:yyyyMMdd}.jsonl' -f (Get-Date))

    if ($script:BoostLabFileLoggingEnabled -and -not (Test-Path -LiteralPath $script:BoostLabLogDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $script:BoostLabLogDirectory -Force -ErrorAction Stop | Out-Null
    }

    return [pscustomobject]@{
        FileLoggingEnabled = $script:BoostLabFileLoggingEnabled
        LogDirectory       = $script:BoostLabLogDirectory
        LogFilePath        = $script:BoostLabLogFilePath
        InitializedAt      = Get-Date
    }
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

        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Debug')]
        [string]$Level = 'Info',

        [string]$Source = 'BoostLab',

        [string]$EventId = 'General',

        [AllowNull()]
        [System.Collections.IDictionary]$Data
    )

    $entry = [pscustomobject]@{
        Timestamp = Get-Date
        Level     = $Level
        Source    = $Source
        EventId   = $EventId
        Message   = Protect-BoostLabLogMessage -Message $Message
        Data      = ConvertTo-BoostLabSafeLogData -Data $Data
    }

    $script:BoostLabLogEntries.Add($entry)

    if ($script:BoostLabFileLoggingEnabled -and -not [string]::IsNullOrWhiteSpace($script:BoostLabLogFilePath)) {
        try {
            $serializedEntry = $entry | ConvertTo-Json -Compress -Depth 6
            Add-Content -LiteralPath $script:BoostLabLogFilePath -Value $serializedEntry -Encoding UTF8 -ErrorAction Stop
        }
        catch {
            Write-Verbose "BoostLab could not write to the log file: $($_.Exception.Message)"
        }
    }

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

function Write-BoostLabInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [string]$Source = 'BoostLab',

        [string]$EventId = 'General',

        [AllowNull()]
        [System.Collections.IDictionary]$Data
    )

    return Write-BoostLabLog -Message $Message -Level Info -Source $Source -EventId $EventId -Data $Data
}

function Write-BoostLabWarning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [string]$Source = 'BoostLab',

        [string]$EventId = 'General',

        [AllowNull()]
        [System.Collections.IDictionary]$Data
    )

    return Write-BoostLabLog -Message $Message -Level Warning -Source $Source -EventId $EventId -Data $Data
}

function Write-BoostLabError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [string]$Source = 'BoostLab',

        [string]$EventId = 'General',

        [AllowNull()]
        [System.Collections.IDictionary]$Data
    )

    return Write-BoostLabLog -Message $Message -Level Error -Source $Source -EventId $EventId -Data $Data
}

function Write-BoostLabSuccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [string]$Source = 'BoostLab',

        [string]$EventId = 'General',

        [AllowNull()]
        [System.Collections.IDictionary]$Data
    )

    return Write-BoostLabLog -Message $Message -Level Success -Source $Source -EventId $EventId -Data $Data
}

function Write-BoostLabDebug {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [string]$Source = 'BoostLab',

        [string]$EventId = 'General',

        [AllowNull()]
        [System.Collections.IDictionary]$Data
    )

    return Write-BoostLabLog -Message $Message -Level Debug -Source $Source -EventId $EventId -Data $Data
}

function Get-BoostLabLog {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Debug')]
        [string]$Level,

        [ValidateRange(1, 10000)]
        [int]$Latest
    )

    $entries = @($script:BoostLabLogEntries.ToArray())
    if ($PSBoundParameters.ContainsKey('Level')) {
        $entries = @($entries | Where-Object { $_.Level -eq $Level })
    }

    if ($PSBoundParameters.ContainsKey('Latest')) {
        $entries = @($entries | Select-Object -Last $Latest)
    }

    return $entries
}

function Get-BoostLabLoggingStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        FileLoggingEnabled = $script:BoostLabFileLoggingEnabled
        LogDirectory       = $script:BoostLabLogDirectory
        LogFilePath        = $script:BoostLabLogFilePath
        MemoryEntryCount   = $script:BoostLabLogEntries.Count
        SinkCount          = $script:BoostLabLogSinks.Count
    }
}

Export-ModuleMember -Function @(
    'Initialize-BoostLabLogging'
    'Register-BoostLabLogSink'
    'Write-BoostLabLog'
    'Write-BoostLabInfo'
    'Write-BoostLabWarning'
    'Write-BoostLabError'
    'Write-BoostLabSuccess'
    'Write-BoostLabDebug'
    'Get-BoostLabLog'
    'Get-BoostLabLoggingStatus'
)
