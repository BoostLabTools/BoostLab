@{
    SchemaVersion = '1.0'

    SupportedRecordSchemaVersions = @(
        '1.0'
    )

    MaxRecordAgeDays = 30

    RecordTypes = @(
        'FileRegistryRollback'
        'ServiceRollback'
        'CleanupQuarantine'
        'AppxPackage'
        'DriverState'
        'RebootWorkflow'
        'Mock'
    )

    ScopeTypes = @(
        'Registry'
        'File'
        'Cleanup'
        'Service'
        'AppX'
        'Driver'
        'RebootWorkflow'
        'Mock'
    )

    RequiredMetadataFields = @(
        'RestoreRecordId'
        'ToolId'
        'ToolName'
        'SourcePath'
        'SourceChecksum'
        'SourceAction'
        'ScopeType'
        'RecordType'
        'CapturedTargetIdentities'
        'Timestamp'
        'MachineContext'
        'UserContext'
        'OperatingSystemContext'
        'ProductScopeContext'
        'PreMutationStateSummary'
        'PostMutationStateRequirement'
        'PostMutationStatePresent'
        'RestoreHandlerType'
        'IntegrityHash'
        'SchemaVersion'
        'ApprovalPolicyVersion'
        'RiskLevel'
        'RestoreEligibilityState'
        'DenialReason'
    )

    EligibilityStates = @(
        'Eligible'
        'Denied'
        'Invalid'
        'NotApplicable'
    )

    RiskLevels = @(
        'low'
        'medium'
        'high'
    )

    # Production restore handlers are intentionally empty in Phase 67. Tests may
    # inject mock handler names into the helper for validation only.
    ApprovedRestoreHandlers = @()

    # Phase 67 approves no production restore scopes.
    RestoreSelectionScopes = @()
}
