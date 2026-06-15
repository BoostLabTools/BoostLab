@{
    SchemaVersion    = '1.0'
    MaxRecordAgeDays = 30

    # These package families are protected by default. A future migration must
    # name the exact family in an exact tool scope and receive explicit approval
    # before policy may permit any mutation.
    ProtectedPackageTokens = @(
        'MicrosoftEdge'
        'Microsoft.Win32WebViewHost'
        'Microsoft.WindowsStore'
        'Microsoft.StorePurchaseApp'
        'Microsoft.Windows.ShellExperienceHost'
        'Microsoft.Windows.StartMenuExperienceHost'
        'Microsoft.DesktopAppInstaller'
        'Microsoft.VCLibs'
        'Microsoft.UI.Xaml'
        'Microsoft.NET.Native'
        'Microsoft.WindowsAppRuntime'
    )

    # Phase 39 establishes governance only. No production AppX package,
    # mutation, tool, action, user scope, or restore path is approved.
    PackageScopes = @()
}
