@{
    SchemaVersion = '1.0'

    # Phase 77 defines a profile state capture model only. It approves no
    # production NVIDIA profile capture, restore, import, export, profile write,
    # Profile Inspector execution, artifact, workflow, or runtime behavior.
    ApprovalStates = @(
        'ModelOnly'
        'NotImplemented'
        'NotApproved'
        'Denied'
        'Invalid'
    )

    ProfileOperationCategories = @(
        'Capture'
        'Compare'
        'Validate'
        'Import'
        'Export'
        'Restore'
        'Verify'
    )

    RequiredMetadataFields = @(
        'CaptureId'
        'ToolId'
        'WorkflowId'
        'WorkflowPathLabel'
        'StepId'
        'StepNumber'
        'SourceScriptPath'
        'SourceChecksum'
        'CaptureTimestamp'
        'CaptureReason'
        'NvidiaDriverVersion'
        'NvidiaGpuVendorDeviceIdentification'
        'ProfileInspectorArtifactIdentity'
        'ProfileInspectorVersion'
        'ProfileInspectorHash'
        'ProfileInspectorSigner'
        'ProfileExportFilePath'
        'ProfileExportSha256'
        'ProfileExportSize'
        'GeneratedImportedNipFilePath'
        'GeneratedImportedNipSha256'
        'ProfileScope'
        'ProfileTarget'
        'SettingIdsOrNames'
        'BeforeStateReference'
        'AfterStateReference'
        'RestoreEligibility'
        'VerificationMethod'
        'RollbackRestoreMethod'
        'FailureBehavior'
        'ActionPlanText'
        'ActivityLogText'
        'LatestResultFields'
        'UserConfirmationLevel'
        'RiskLevel'
        'ApprovalStatus'
    )

    DenialCategories = @(
        'ArtifactNotApproved'
        'ProfileInspectorNotApproved'
        'NipImportNotApproved'
        'CaptureToolNotApproved'
        'MissingCapture'
        'CaptureHashMismatch'
        'DriverIdentityMismatch'
        'GpuIdentityMismatch'
        'WorkflowMismatch'
        'PathMixingNotApproved'
        'UnboundedOutputPath'
        'UntrackedTempPath'
        'UnsupportedProfileSetting'
        'AmbiguousProfileTarget'
        'RestoreWithoutValidatedCapture'
    )

    # Production scopes intentionally remain empty and deny-by-default.
    ProductionProfileScopes = @()
    ApprovedProfileOperations = @()
    ApprovedProfileInspectorArtifacts = @()
    ApprovedNipImports = @()
    ApprovedNipExports = @()
}
