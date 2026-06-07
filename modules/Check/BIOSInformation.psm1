Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'bios-information'; Title = 'BIOS Information'; Stage = 'Check'; Order = 1
    Type = 'assistant'; RiskLevel = 'low'
    Description = 'Review detected BIOS, firmware, and motherboard information.'
    Actions = @('Analyze', 'Open')
}
$script:BoostLabImplementedActions = @('Analyze', 'Open')

function Get-BoostLabKnownValue {
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
        return 'Unknown'
    }

    return ([string]$Value).Trim()
}

function Get-BoostLabObjectPropertyValue {
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$PropertyName
    )

    if ($null -eq $InputObject) {
        return $null
    }

    $property = $InputObject.PSObject.Properties[$PropertyName]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function ConvertTo-BoostLabBiosDate {
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return 'Unknown'
    }

    try {
        $date = if ($Value -is [datetime]) {
            [datetime]$Value
        }
        else {
            [System.Management.ManagementDateTimeConverter]::ToDateTime([string]$Value)
        }

        return $date.ToString('yyyy-MM-dd')
    }
    catch {
        return Get-BoostLabKnownValue -Value $Value
    }
}

function Get-BoostLabSecureBootStatus {
    try {
        if (-not (Get-Command -Name 'Confirm-SecureBootUEFI' -ErrorAction SilentlyContinue)) {
            return 'Unknown'
        }

        return if (Confirm-SecureBootUEFI -ErrorAction Stop) {
            'Enabled'
        }
        else {
            'Disabled'
        }
    }
    catch {
        return 'Unknown'
    }
}

function Get-BoostLabTpmStatus {
    try {
        if (Get-Command -Name 'Get-Tpm' -ErrorAction SilentlyContinue) {
            $tpm = Get-Tpm -ErrorAction Stop
            $tpmPresent = [bool](Get-BoostLabObjectPropertyValue -InputObject $tpm -PropertyName 'TpmPresent')
            if (-not $tpmPresent) {
                return 'Not present'
            }

            $ready = if ([bool](Get-BoostLabObjectPropertyValue -InputObject $tpm -PropertyName 'TpmReady')) { 'Yes' } else { 'No' }
            $enabled = if ([bool](Get-BoostLabObjectPropertyValue -InputObject $tpm -PropertyName 'TpmEnabled')) { 'Yes' } else { 'No' }
            $activated = if ([bool](Get-BoostLabObjectPropertyValue -InputObject $tpm -PropertyName 'TpmActivated')) { 'Yes' } else { 'No' }
            return "Present; Ready: $ready; Enabled: $enabled; Activated: $activated"
        }
    }
    catch {
        # Fall back to the TPM CIM provider.
    }

    try {
        $tpm = Get-CimInstance `
            -Namespace 'root\CIMV2\Security\MicrosoftTpm' `
            -ClassName 'Win32_Tpm' `
            -ErrorAction Stop |
            Select-Object -First 1
        if ($null -eq $tpm) {
            return 'Not present'
        }

        $specVersion = Get-BoostLabKnownValue -Value (
            Get-BoostLabObjectPropertyValue -InputObject $tpm -PropertyName 'SpecVersion'
        )
        return "Present; Specification: $specVersion"
    }
    catch {
        return 'Unknown'
    }
}

function Get-BoostLabWindowsSummary {
    try {
        $environmentCommand = Get-Command -Name 'Get-BoostLabWindowsVersion' -ErrorAction SilentlyContinue
        if ($null -eq $environmentCommand) {
            return [pscustomobject]@{
                Version = 'Unknown'
                Build   = 'Unknown'
            }
        }

        $windows = & $environmentCommand
        return [pscustomobject]@{
            Version = Get-BoostLabKnownValue -Value $windows.DisplayName
            Build   = Get-BoostLabKnownValue -Value $windows.BuildText
        }
    }
    catch {
        return [pscustomobject]@{
            Version = 'Unknown'
            Build   = 'Unknown'
        }
    }
}

function Get-BoostLabBiosAnalysis {
    $baseBoard = $null
    $bios = $null
    $computerSystem = $null
    $processor = $null

    try {
        $baseBoard = Get-CimInstance -ClassName 'Win32_BaseBoard' -ErrorAction Stop |
            Select-Object -First 1
    }
    catch {
        $baseBoard = $null
    }

    try {
        $bios = Get-CimInstance -ClassName 'Win32_BIOS' -ErrorAction Stop |
            Select-Object -First 1
    }
    catch {
        $bios = $null
    }

    try {
        $computerSystem = Get-CimInstance -ClassName 'Win32_ComputerSystem' -ErrorAction Stop |
            Select-Object -First 1
    }
    catch {
        $computerSystem = $null
    }

    try {
        $processor = Get-CimInstance -ClassName 'Win32_Processor' -ErrorAction Stop |
            Select-Object -First 1
    }
    catch {
        $processor = $null
    }

    $windows = Get-BoostLabWindowsSummary
    return [pscustomobject]@{
        MotherboardManufacturer = Get-BoostLabKnownValue -Value (
            Get-BoostLabObjectPropertyValue -InputObject $baseBoard -PropertyName 'Manufacturer'
        )
        MotherboardModel        = Get-BoostLabKnownValue -Value (
            Get-BoostLabObjectPropertyValue -InputObject $baseBoard -PropertyName 'Product'
        )
        BiosManufacturer        = Get-BoostLabKnownValue -Value (
            Get-BoostLabObjectPropertyValue -InputObject $bios -PropertyName 'Manufacturer'
        )
        BiosVersion             = Get-BoostLabKnownValue -Value (
            Get-BoostLabObjectPropertyValue -InputObject $bios -PropertyName 'SMBIOSBIOSVersion'
        )
        BiosReleaseDate         = ConvertTo-BoostLabBiosDate -Value (
            Get-BoostLabObjectPropertyValue -InputObject $bios -PropertyName 'ReleaseDate'
        )
        SystemManufacturer      = Get-BoostLabKnownValue -Value (
            Get-BoostLabObjectPropertyValue -InputObject $computerSystem -PropertyName 'Manufacturer'
        )
        SystemModel             = Get-BoostLabKnownValue -Value (
            Get-BoostLabObjectPropertyValue -InputObject $computerSystem -PropertyName 'Model'
        )
        SecureBootStatus        = Get-BoostLabSecureBootStatus
        TpmStatus               = Get-BoostLabTpmStatus
        CpuName                 = Get-BoostLabKnownValue -Value (
            Get-BoostLabObjectPropertyValue -InputObject $processor -PropertyName 'Name'
        )
        WindowsVersion          = [string]$windows.Version
        WindowsBuild            = [string]$windows.Build
        Timestamp               = Get-Date
    }
}

function Test-BoostLabBiosInternet {
    try {
        $internetCommand = Get-Command -Name 'Test-BoostLabInternet' -ErrorAction SilentlyContinue
        if ($null -eq $internetCommand) {
            return $false
        }

        return [bool](& $internetCommand)
    }
    catch {
        return $false
    }
}

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        Id                 = [string]$script:BoostLabToolMetadata['Id']
        Title              = [string]$script:BoostLabToolMetadata['Title']
        Stage              = [string]$script:BoostLabToolMetadata['Stage']
        Order              = [int]$script:BoostLabToolMetadata['Order']
        Type               = [string]$script:BoostLabToolMetadata['Type']
        RiskLevel          = [string]$script:BoostLabToolMetadata['RiskLevel']
        Description        = [string]$script:BoostLabToolMetadata['Description']
        Actions            = @($script:BoostLabToolMetadata['Actions'])
        ImplementedActions = @($script:BoostLabImplementedActions)
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        Supported = $true
        ToolId    = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason    = 'BIOS information uses read-only Windows hardware and security queries.'
        Timestamp = Get-Date
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        Status          = 'Ready'
        LastAction      = $null
        LastResult      = $null
        RestartRequired = $false
        Timestamp       = Get-Date
    }
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ActionName
    )

    if ($ActionName -notin @($script:BoostLabImplementedActions)) {
        return [pscustomobject]@{
            Success         = $false
            ToolId          = [string]$script:BoostLabToolMetadata['Id']
            ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
            Action          = $ActionName
            Message         = 'Unsupported action. Only Analyze and Open are allowed.'
            RestartRequired = $false
            Timestamp       = Get-Date
            Data            = $null
        }
    }

    if ($ActionName -eq 'Analyze') {
        $analysis = Get-BoostLabBiosAnalysis
        return [pscustomobject]@{
            Success         = $true
            ToolId          = [string]$script:BoostLabToolMetadata['Id']
            ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
            Action          = 'Analyze'
            Message         = 'Analysis complete'
            RestartRequired = $false
            Timestamp       = Get-Date
            Data            = $analysis
        }
    }

    if (-not (Test-BoostLabBiosInternet)) {
        return [pscustomobject]@{
            Success         = $false
            ToolId          = [string]$script:BoostLabToolMetadata['Id']
            ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
            Action          = 'Open'
            Message         = 'Internet connection is required to open the BIOS information search.'
            RestartRequired = $false
            Timestamp       = Get-Date
            Data            = $null
        }
    }

    $analysis = Get-BoostLabBiosAnalysis
    $queryParts = @(
        $analysis.MotherboardManufacturer
        $analysis.MotherboardModel
        $analysis.BiosVersion
        'BIOS update'
    ) | Where-Object { $_ -ne 'Unknown' -and -not [string]::IsNullOrWhiteSpace($_) }
    $searchQuery = $queryParts -join ' '
    $escapedQuery = [System.Uri]::EscapeDataString($searchQuery)
    $searchUrl = "https://www.google.com/search?q=$escapedQuery"

    try {
        Start-Process $searchUrl
        return [pscustomobject]@{
            Success         = $true
            ToolId          = [string]$script:BoostLabToolMetadata['Id']
            ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
            Action          = 'Open'
            Message         = 'Launched'
            RestartRequired = $false
            Timestamp       = Get-Date
            Data            = [pscustomobject]@{
                SearchQuery = $searchQuery
                SearchUrl   = $searchUrl
            }
        }
    }
    catch {
        return [pscustomobject]@{
            Success         = $false
            ToolId          = [string]$script:BoostLabToolMetadata['Id']
            ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
            Action          = 'Open'
            Message         = "Launch failed: $($_.Exception.Message)"
            RestartRequired = $false
            Timestamp       = Get-Date
            Data            = $null
        }
    }
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        Success         = $false
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        Action          = 'Default'
        Message         = 'Action is not declared for this tool.'
        RestartRequired = $false
        Timestamp       = Get-Date
        Data            = $null
    }
}

Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
