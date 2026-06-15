@{
    SchemaVersion = '1.0'
    MaxRecordAgeDays = 30

    # Phase 41 intentionally approves no production driver target.
    # Future phases must add exact tool, action, device, package, mutation,
    # provenance, state-capture, and reboot requirements before use.
    DriverScopes = @()
}
