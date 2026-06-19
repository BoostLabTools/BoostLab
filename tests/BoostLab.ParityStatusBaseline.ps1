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
