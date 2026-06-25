Set-StrictMode -Version Latest

function Test-BoostLabAdministrator {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function Test-BoostLabInternet {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [ValidateRange(500, 15000)]
        [int]$TimeoutMilliseconds = 2500
    )

    try {
        if (-not [System.Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable()) {
            return $false
        }

        $request = [System.Net.HttpWebRequest]::Create('https://www.msftconnecttest.com/connecttest.txt')
        $request.Method = 'GET'
        $request.Timeout = $TimeoutMilliseconds
        $request.ReadWriteTimeout = $TimeoutMilliseconds
        $request.AllowAutoRedirect = $true
        $request.UserAgent = 'BoostLab-Connectivity-Check'

        $response = $request.GetResponse()
        try {
            return ([int]$response.StatusCode -ge 200 -and [int]$response.StatusCode -lt 400)
        }
        finally {
            $response.Dispose()
        }
    }
    catch {
        try {
            $client = [System.Net.Sockets.TcpClient]::new()
            try {
                $connectTask = $client.ConnectAsync('www.microsoft.com', 443)
                if (-not $connectTask.Wait($TimeoutMilliseconds)) {
                    return $false
                }

                return $client.Connected
            }
            finally {
                $client.Dispose()
            }
        }
        catch {
            return $false
        }
    }
}

function Get-BoostLabWindowsVersion {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $productName = 'Windows'
    $editionId = ''
    $displayVersion = ''
    $build = [Environment]::OSVersion.Version.Build
    $revision = [Environment]::OSVersion.Version.Revision

    try {
        $currentVersion = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
        $productName = [string]$currentVersion.ProductName
        $editionId = [string]$currentVersion.EditionID
        $displayVersion = [string]$currentVersion.DisplayVersion
        $build = [int]$currentVersion.CurrentBuildNumber
        $revision = [int]$currentVersion.UBR

        if ($build -ge 22000 -and $productName -like 'Windows 10*') {
            $productName = $productName -replace '^Windows 10', 'Windows 11'
        }
    }
    catch {
        # Environment.OSVersion remains the safe fallback.
    }

    $buildText = if ($revision -ge 0) { "$build.$revision" } else { [string]$build }
    $displayName = @($productName, $displayVersion, "(Build $buildText)") |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    return [pscustomobject]@{
        ProductName    = $productName
        Edition        = $editionId
        DisplayVersion = $displayVersion
        Build           = $build
        Revision        = $revision
        BuildText       = $buildText
        DisplayName     = $displayName -join ' '
    }
}

function Get-BoostLabWindowsEdition {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return [string](Get-BoostLabWindowsVersion).Edition
}

function Get-BoostLabObjectPropertyValue {
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$Name,

        [AllowNull()]
        [object]$Default = $null
    )

    if ($null -eq $InputObject) {
        return $Default
    }
    if ($InputObject -is [System.Collections.IDictionary]) {
        if ($InputObject.Contains($Name)) {
            return $InputObject[$Name]
        }
        return $Default
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $Default
    }

    return $property.Value
}

function Resolve-BoostLabWindowsEditionCapability {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [object]$WindowsVersion = $null,

        [scriptblock]$WindowsVersionReader = { Get-BoostLabWindowsVersion }
    )

    $version = $WindowsVersion
    $detectionStatus = 'Detected'
    $detectionMessage = 'Windows edition detected.'
    if ($null -eq $version) {
        try {
            $results = @(& $WindowsVersionReader)
            if ($results.Count -gt 0) {
                $version = $results[0]
            }
            else {
                $detectionStatus = 'Unknown'
                $detectionMessage = 'Windows edition reader returned no result.'
            }
        }
        catch {
            $detectionStatus = 'Unknown'
            $detectionMessage = "Windows edition detection failed: $($_.Exception.Message)"
        }
    }

    $edition = [string](Get-BoostLabObjectPropertyValue -InputObject $version -Name 'Edition' -Default '')
    $productName = [string](Get-BoostLabObjectPropertyValue -InputObject $version -Name 'ProductName' -Default '')
    if ([string]::IsNullOrWhiteSpace($edition) -and $version -is [string]) {
        $edition = [string]$version
    }
    $editionText = $edition.Trim()
    $productText = $productName.Trim()
    $normalizedEdition = ($editionText -replace '[^A-Za-z0-9]', '').ToLowerInvariant()
    $normalizedProduct = ($productText -replace '[^A-Za-z0-9]', '').ToLowerInvariant()

    $homeEditions = @(
        'core',
        'coren',
        'coresinglelanguage',
        'corecountryspecific',
        'home',
        'homen',
        'homesinglelanguage',
        'homecountryspecific'
    )
    $proOrHigherEditions = @(
        'professional',
        'professionaln',
        'professionalworkstation',
        'professionalworkstationn',
        'professionaleducation',
        'professionaleducationn',
        'enterprise',
        'enterprisen',
        'enterprises',
        'enterprisesn',
        'education',
        'educationn'
    )

    $isHomeOrCore = $normalizedEdition -in $homeEditions
    $isProOrHigher = $normalizedEdition -in $proOrHigherEditions
    if (-not $isHomeOrCore -and -not $isProOrHigher -and -not [string]::IsNullOrWhiteSpace($normalizedProduct)) {
        $isHomeOrCore = (
            $normalizedProduct -match 'windows(10|11)?home' -and
            $normalizedProduct -notmatch 'pro|professional|enterprise|education|workstation'
        )
        $isProOrHigher = (
            $normalizedProduct -match 'professional|pro|enterprise|education|workstation'
        )
    }

    $editionFamily = if ($isHomeOrCore) {
        'HomeCore'
    }
    elseif ($isProOrHigher) {
        'ProOrHigher'
    }
    else {
        'Unknown'
    }
    $editionCapability = if ($isHomeOrCore) {
        'HomeCore'
    }
    elseif ($isProOrHigher) {
        'BitLockerCapable'
    }
    else {
        'Unknown'
    }
    $currentEdition = if (-not [string]::IsNullOrWhiteSpace($editionText)) {
        $editionText
    }
    elseif (-not [string]::IsNullOrWhiteSpace($productText)) {
        $productText
    }
    else {
        'Unknown'
    }

    if ($editionFamily -eq 'Unknown') {
        $detectionStatus = 'Unknown'
        if ($detectionMessage -eq 'Windows edition detected.') {
            $detectionMessage = 'Windows edition is unknown or not classified for BoostLab edition-dependent Setup tools.'
        }
    }

    [pscustomobject]@{
        DetectionStatus             = $detectionStatus
        DetectionMessage            = $detectionMessage
        ProductName                 = $productText
        Edition                     = $editionText
        CurrentEdition              = $currentEdition
        DetectedWindowsEdition      = $currentEdition
        NormalizedEdition           = $normalizedEdition
        EditionFamily               = $editionFamily
        EditionCapability           = $editionCapability
        IsHomeOrCore                = $isHomeOrCore
        IsProOrHigher               = $isProOrHigher
        SupportsBitLocker           = $isProOrHigher
        BitLockerSupported          = $isProOrHigher
        SupportsConvertHomeToPro    = $isHomeOrCore
        ConvertHomeToProApplicable  = $isHomeOrCore
        AvailabilityReason          = if ($isHomeOrCore) {
            'Windows Home/Core edition detected; Convert Home To Pro is applicable and BitLocker requires Pro or higher.'
        }
        elseif ($isProOrHigher) {
            'Windows Pro or higher edition detected; BitLocker is applicable and Convert Home To Pro is no longer applicable.'
        }
        else {
            $detectionMessage
        }
        RequiredForBitLocker        = 'Windows Pro or higher'
        RequiredForConvertHomeToPro = 'Windows Home/Core'
        DetectedAt                  = Get-Date
    }
}

function Get-BoostLabEditionAwareToolAvailability {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [AllowNull()]
        [object]$EditionCapability = $null,

        [scriptblock]$EditionCapabilityReader = { Resolve-BoostLabWindowsEditionCapability }
    )

    $capability = $EditionCapability
    if ($null -eq $capability) {
        try {
            $results = @(& $EditionCapabilityReader)
            if ($results.Count -gt 0) {
                $capability = $results[0]
            }
        }
        catch {
            $capability = [pscustomobject]@{
                DetectionStatus = 'Unknown'
                CurrentEdition = 'Unknown'
                DetectedWindowsEdition = 'Unknown'
                EditionFamily = 'Unknown'
                EditionCapability = 'Unknown'
                SupportsBitLocker = $false
                SupportsConvertHomeToPro = $false
                AvailabilityReason = "Windows edition detection failed: $($_.Exception.Message)"
            }
        }
    }
    if ($null -eq $capability) {
        $capability = Resolve-BoostLabWindowsEditionCapability -WindowsVersion ([pscustomobject]@{})
    }

    $toolKey = $ToolId.ToLowerInvariant()
    $isBitLocker = $toolKey -eq 'bitlocker'
    $isConvert = $toolKey -eq 'convert-home-to-pro'
    $available = if ($isBitLocker) {
        [bool](Get-BoostLabObjectPropertyValue -InputObject $capability -Name 'SupportsBitLocker' -Default $false)
    }
    elseif ($isConvert) {
        [bool](Get-BoostLabObjectPropertyValue -InputObject $capability -Name 'SupportsConvertHomeToPro' -Default $false)
    }
    else {
        $true
    }

    $runtimeGuardResult = if ($isBitLocker -and -not $available) {
        if ([string](Get-BoostLabObjectPropertyValue -InputObject $capability -Name 'EditionFamily' -Default 'Unknown') -eq 'Unknown') { 'EditionUnknown' } else { 'BitLockerRequiresProOrHigher' }
    }
    elseif ($isConvert -and -not $available) {
        if ([string](Get-BoostLabObjectPropertyValue -InputObject $capability -Name 'EditionFamily' -Default 'Unknown') -eq 'Unknown') { 'EditionUnknown' } else { 'AlreadyProOrHigher' }
    }
    else {
        'Available'
    }

    [pscustomobject]@{
        ToolId                  = $ToolId
        IsEditionDependent     = ($isBitLocker -or $isConvert)
        IsAvailable            = $available
        IsRunnable             = $available
        AvailabilityStatus      = if ($available) { 'Available' } else { 'Unavailable' }
        AvailabilityReason      = if ($available) {
            [string](Get-BoostLabObjectPropertyValue -InputObject $capability -Name 'AvailabilityReason' -Default 'Tool is available for the detected Windows edition.')
        }
        elseif ($isBitLocker) {
            'BitLocker unavailable on Windows Home/Core or unknown edition. BitLocker requires Windows Pro or higher.'
        }
        elseif ($isConvert) {
            'Convert Home To Pro unavailable because this Windows edition is already Pro or higher, or the edition is unknown.'
        }
        else {
            'Tool availability is not edition-dependent.'
        }
        RuntimeGuardResult      = $runtimeGuardResult
        RequiredEdition         = if ($isBitLocker) { 'Windows Pro or higher' } elseif ($isConvert) { 'Windows Home/Core' } else { '' }
        CurrentEdition          = [string](Get-BoostLabObjectPropertyValue -InputObject $capability -Name 'CurrentEdition' -Default 'Unknown')
        DetectedWindowsEdition  = [string](Get-BoostLabObjectPropertyValue -InputObject $capability -Name 'DetectedWindowsEdition' -Default 'Unknown')
        EditionFamily           = [string](Get-BoostLabObjectPropertyValue -InputObject $capability -Name 'EditionFamily' -Default 'Unknown')
        EditionCapability       = [string](Get-BoostLabObjectPropertyValue -InputObject $capability -Name 'EditionCapability' -Default 'Unknown')
        EditionDetection        = $capability
    }
}

function Get-BoostLabPowerShellVersion {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $version = $PSVersionTable.PSVersion
    return [pscustomobject]@{
        Version      = $version.ToString()
        Major        = $version.Major
        Minor        = $version.Minor
        Edition      = [string]$PSVersionTable.PSEdition
        Compatible   = ($version.Major -ge 5)
        DisplayName  = "PowerShell $($version.ToString())"
    }
}

function Get-BoostLabSystemArchitecture {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $operatingSystem = if ([Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' }
    $process = if ([Environment]::Is64BitProcess) { 'x64' } else { 'x86' }

    if ($env:PROCESSOR_ARCHITECTURE -match 'ARM64') {
        $process = 'ARM64'
    }
    if ($env:PROCESSOR_ARCHITEW6432 -match 'ARM64' -or $env:PROCESSOR_ARCHITECTURE -match 'ARM64') {
        $operatingSystem = 'ARM64'
    }

    return [pscustomobject]@{
        OperatingSystem = $operatingSystem
        Process         = $process
        Is64BitOS       = [Environment]::Is64BitOperatingSystem
        Is64BitProcess  = [Environment]::Is64BitProcess
    }
}

function Get-BoostLabPendingRebootStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $reasons = [System.Collections.Generic.List[string]]::new()

    try {
        if (Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') {
            $reasons.Add('ComponentBasedServicing')
        }
    }
    catch {
        # An unreadable indicator is treated as unknown rather than pending.
    }

    try {
        if (Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') {
            $reasons.Add('WindowsUpdate')
        }
    }
    catch {
        # An unreadable indicator is treated as unknown rather than pending.
    }

    try {
        $sessionManager = Get-ItemProperty `
            -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' `
            -Name 'PendingFileRenameOperations' `
            -ErrorAction SilentlyContinue
        if ($null -ne $sessionManager -and $null -ne $sessionManager.PendingFileRenameOperations) {
            $reasons.Add('PendingFileRenameOperations')
        }
    }
    catch {
        # An unreadable indicator is treated as unknown rather than pending.
    }

    return [pscustomobject]@{
        IsPending = ($reasons.Count -gt 0)
        Reasons   = $reasons.ToArray()
        CheckedAt = Get-Date
    }
}

function Test-BoostLabPendingReboot {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return [bool](Get-BoostLabPendingRebootStatus).IsPending
}

function Get-BoostLabEnvironmentInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [ValidateRange(500, 15000)]
        [int]$InternetTimeoutMilliseconds = 2500
    )

    return [pscustomobject]@{
        IsAdministrator = Test-BoostLabAdministrator
        HasInternet     = Test-BoostLabInternet -TimeoutMilliseconds $InternetTimeoutMilliseconds
        Windows         = Get-BoostLabWindowsVersion
        PowerShell      = Get-BoostLabPowerShellVersion
        Architecture    = Get-BoostLabSystemArchitecture
        PendingReboot   = Get-BoostLabPendingRebootStatus
        DetectedAt      = Get-Date
    }
}

Export-ModuleMember -Function @(
    'Test-BoostLabAdministrator'
    'Test-BoostLabInternet'
    'Get-BoostLabWindowsVersion'
    'Get-BoostLabWindowsEdition'
    'Resolve-BoostLabWindowsEditionCapability'
    'Get-BoostLabEditionAwareToolAvailability'
    'Get-BoostLabPowerShellVersion'
    'Get-BoostLabSystemArchitecture'
    'Get-BoostLabPendingRebootStatus'
    'Test-BoostLabPendingReboot'
    'Get-BoostLabEnvironmentInfo'
)
