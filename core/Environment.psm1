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
        [ValidateRange(250, 10000)]
        [int]$TimeoutMilliseconds = 1500
    )

    try {
        if (-not [System.Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable()) {
            return $false
        }

        $client = [System.Net.Sockets.TcpClient]::new()
        try {
            $connectTask = $client.ConnectAsync('github.com', 443)
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

function Get-BoostLabWindowsVersion {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $productName = 'Windows'
    $displayVersion = ''
    $build = [Environment]::OSVersion.Version.Build
    $revision = [Environment]::OSVersion.Version.Revision

    try {
        $currentVersion = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
        $productName = [string]$currentVersion.ProductName
        $displayVersion = [string]$currentVersion.DisplayVersion
        $build = [int]$currentVersion.CurrentBuildNumber
        $revision = [int]$currentVersion.UBR

        if ($build -ge 22000 -and $productName -like 'Windows 10*') {
            $productName = $productName -replace '^Windows 10', 'Windows 11'
        }
    }
    catch {
        # Fall back to Environment.OSVersion when registry data is unavailable.
    }

    $buildText = if ($revision -ge 0) { "$build.$revision" } else { [string]$build }
    $displayName = @($productName, $displayVersion, "(Build $buildText)") |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    [pscustomobject]@{
        ProductName    = $productName
        DisplayVersion = $displayVersion
        Build           = $build
        Revision        = $revision
        DisplayName     = $displayName -join ' '
    }
}

Export-ModuleMember -Function @(
    'Test-BoostLabAdministrator'
    'Test-BoostLabInternet'
    'Get-BoostLabWindowsVersion'
)
