@{
    SchemaVersion    = '1.0'
    MaxRecordAgeDays = 7

    # Phase 40 establishes governance only. Future tool phases must add exact
    # tool/action scopes, checkpoint requirements, state roots, resume handlers,
    # and trusted artifacts before any reboot or resume request is permitted.
    WorkflowScopes = @()
}
