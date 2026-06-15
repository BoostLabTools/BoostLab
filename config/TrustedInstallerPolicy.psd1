@{
    SchemaVersion = '1.0'
    MaxRequestAgeMinutes = 30
    RequestedIdentity = 'NT SERVICE\TrustedInstaller'

    # Phase 42 approves no production TrustedInstaller operation.
    TrustedInstallerScopes = @()

    BlockedExternalElevationTools = @(
        'advancedrun.exe'
        'nsudo.exe'
        'nsudoc.exe'
        'nsudolg.exe'
        'psexec.exe'
        'psexec64.exe'
        'powerrun.exe'
    )

    ProtectedRegistryPrefixes = @(
        'HKLM:\SAM'
        'HKLM:\SECURITY'
        'HKLM:\SYSTEM'
    )

    ProtectedServiceNames = @(
        'BFE'
        'CryptSvc'
        'DcomLaunch'
        'EventLog'
        'MpsSvc'
        'RpcSs'
        'Schedule'
        'TrustedInstaller'
        'WinDefend'
        'Winmgmt'
    )

    ProtectedPackagePrefixes = @(
        'Microsoft.DesktopAppInstaller'
        'Microsoft.MicrosoftEdge'
        'Microsoft.StorePurchaseApp'
        'Microsoft.VCLibs'
        'Microsoft.Windows.AppRuntime'
        'Microsoft.Windows.ShellExperienceHost'
        'Microsoft.Windows.StartMenuExperienceHost'
        'Microsoft.WindowsStore'
        'Microsoft.UI.Xaml'
    )
}
