@{
    SchemaVersion    = '1.0'
    MaxRecordAgeDays = 30

    # Phase 38 establishes the contract only. Future tool phases must add exact,
    # reviewed targets and bounded limits before cleanup is permitted.
    CleanupScopes = @()
}
