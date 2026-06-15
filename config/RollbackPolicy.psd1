@{
    SchemaVersion = '1.0'

    # Phase 36 establishes the contract only. Future tool phases must add exact,
    # reviewed scopes before production file or registry capture is allowed.
    FileScopes = @()
    RegistryScopes = @()

    DeniedRegistryPrefixes = @(
        'HKLM:\SYSTEM'
        'Registry::HKEY_LOCAL_MACHINE\SYSTEM'
    )
}
