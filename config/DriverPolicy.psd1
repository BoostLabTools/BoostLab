@{
    SchemaVersion    = '1.0'
    MaxRecordAgeDays = 30

    # GPU-specific production behavior is NVIDIA-only. This does not approve
    # any NVIDIA device, package, artifact, mutation, or tool by itself.
    SupportedGpuVendors = @(
        @{
            VendorId   = '10DE'
            VendorName = 'NVIDIA'
        }
    )

    # Phase 41 establishes governance only. Future phases must add exact
    # tool/action/device/package scopes before driver inventory or mutation use.
    DriverScopes = @()
}
