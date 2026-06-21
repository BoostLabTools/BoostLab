Set-StrictMode -Version Latest

function Get-BoostLabParityStatusBaseline {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot
    )

    $baselinePath = Join-Path $ProjectRoot 'config\ParityStatusBaseline.psd1'
    if (-not (Test-Path -LiteralPath $baselinePath -PathType Leaf)) {
        throw "Parity status baseline file is missing: $baselinePath"
    }

    return Import-PowerShellDataFile -LiteralPath $baselinePath
}

function Get-BoostLabUltimateParityExecutionOrder {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot
    )

    $orderPath = Join-Path $ProjectRoot 'config\UltimateParityExecutionOrder.psd1'
    if (-not (Test-Path -LiteralPath $orderPath -PathType Leaf)) {
        throw "Ultimate parity execution order file is missing: $orderPath"
    }

    return Import-PowerShellDataFile -LiteralPath $orderPath
}

function Get-BoostLabParityCategoryCounts {
    param(
        [Parameter(Mandatory)]
        [hashtable]$ParityBaseline
    )

    $counts = @{}
    foreach ($tool in @($ParityBaseline.Tools)) {
        $level = [string]$tool.ImplementationLevel
        if (-not $counts.ContainsKey($level)) {
            $counts[$level] = 0
        }
        $counts[$level]++
    }

    return $counts
}

function Test-BoostLabParityRecordFinal {
    param(
        [Parameter(Mandatory)]
        [object]$Record
    )

    $implementationLevel = [string]$Record.ImplementationLevel
    if ($implementationLevel -eq 'ParityImplemented') {
        return $true
    }

    if (
        $Record -is [System.Collections.IDictionary] -and
        $Record.Contains('YazanFinalException') -and
        [bool]$Record['YazanFinalException']
    ) {
        return $true
    }
    if (
        $Record -isnot [System.Collections.IDictionary] -and
        $Record.PSObject.Properties['YazanFinalException'] -and
        [bool]$Record.YazanFinalException
    ) {
        return $true
    }

    $finalProgressStatus = if ($Record -is [System.Collections.IDictionary] -and $Record.Contains('FinalProgressStatus')) {
        [string]$Record['FinalProgressStatus']
    }
    elseif ($Record -isnot [System.Collections.IDictionary] -and $Record.PSObject.Properties['FinalProgressStatus']) {
        [string]$Record.FinalProgressStatus
    }
    else {
        ''
    }
    $acceptedNearParity = if ($Record -is [System.Collections.IDictionary] -and $Record.Contains('YazanAcceptedNearParity')) {
        [bool]$Record['YazanAcceptedNearParity']
    }
    elseif ($Record -isnot [System.Collections.IDictionary] -and $Record.PSObject.Properties['YazanAcceptedNearParity']) {
        [bool]$Record.YazanAcceptedNearParity
    }
    else {
        $false
    }

    return ($finalProgressStatus -eq 'DoneYazanAcceptedNearParity' -and $acceptedNearParity)
}

function Get-BoostLabNextOrderedParityTarget {
    param(
        [Parameter(Mandatory)]
        [hashtable]$ParityBaseline,

        [Parameter(Mandatory)]
        [hashtable]$ExecutionOrder
    )

    foreach ($stage in @($ExecutionOrder.Stages)) {
        foreach ($tool in @($stage.Tools)) {
            $toolId = [string]$tool.ToolId
            $record = @($ParityBaseline.Tools | Where-Object { [string]$_.ToolId -eq $toolId }) | Select-Object -First 1
            if ($null -eq $record) {
                throw "Missing parity baseline record for ordered tool: $toolId"
            }

            if (-not (Test-BoostLabParityRecordFinal -Record $record)) {
                return $record
            }
        }
    }

    $declaresComplete = (
        $ParityBaseline.ContainsKey('OrderedParityComplete') -and
        [bool]$ParityBaseline.OrderedParityComplete
    )
    if ($declaresComplete -and $null -eq $ParityBaseline.CurrentOrderedParityTarget) {
        return @{
            ToolId = $null
            DisplayName = 'Ordered Ultimate parity complete'
            Stage = $null
            RuntimeStatus = 'Complete'
            ImplementationLevel = 'Complete'
            UltimateParity = 'Yes'
            FinalProgressStatus = 'DoneParity'
            IsOrderedParityComplete = $true
        }
    }

    return $null
}
