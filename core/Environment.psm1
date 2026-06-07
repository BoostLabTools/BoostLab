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
    'Get-BoostLabPowerShellVersion'
    'Get-BoostLabSystemArchitecture'
    'Get-BoostLabPendingRebootStatus'
    'Test-BoostLabPendingReboot'
    'Get-BoostLabEnvironmentInfo'
)
