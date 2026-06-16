@{
    SchemaVersion = '1.0'

    ProcessOperationTypes = @(
        'DetectOnly'
        'WaitForExit'
        'GracefulClose'
        'StopProcess'
        'RestartProcess'
        'LaunchHandoff'
        'ExplorerRestart'
        'ToolOwnedProcessCleanup'
    )

    NonMutatingOperationTypes = @(
        'DetectOnly'
    )

    MutatingOperationTypes = @(
        'WaitForExit'
        'GracefulClose'
        'StopProcess'
        'RestartProcess'
        'LaunchHandoff'
        'ExplorerRestart'
        'ToolOwnedProcessCleanup'
    )

    ApprovalStates = @(
        'Draft'
        'Reviewed'
        'Approved'
        'Rejected'
        'NotApproved'
        'TestOnly'
    )

    EligibilityStates = @(
        'Eligible'
        'Reviewed'
        'Denied'
        'NotApproved'
        'Invalid'
        'NotApplicable'
    )

    RequiredMetadataFields = @(
        'ToolId'
        'ToolName'
        'SourcePath'
        'SourceChecksum'
        'DesignReviewDocument'
        'SourceBehaviorGroup'
        'ProcessOperationType'
        'ExactProcessName'
        'ExactExecutablePathRequirement'
        'PublisherSignatureRequirement'
        'UserSessionScope'
        'OwnershipModel'
        'IsToolOwnedProcess'
        'UnsavedUserDataRisk'
        'ConfirmationLevel'
        'PreflightVerification'
        'PostOperationVerification'
        'TimeoutBehavior'
        'RetryBehavior'
        'RollbackRecoveryFeasibility'
        'ActionPlanTextRequirement'
        'ActivityLogTextRequirement'
        'RiskLevel'
        'ApprovalStatus'
        'DenialReason'
    )

    RiskLevels = @(
        'low'
        'medium'
        'high'
    )

    ConfirmationLevels = @(
        'None'
        'Informational'
        'Explicit'
        'HighRiskExplicit'
    )

    SystemCriticalProcessNames = @(
        'csrss'
        'dwm'
        'init'
        'lsass'
        'services'
        'smss'
        'svchost'
        'System'
        'wininit'
        'winlogon'
    )

    SecurityProcessNames = @(
        'MsMpEng'
        'NisSrv'
        'SecurityHealthService'
        'SecurityHealthSystray'
        'Sense'
        'TrustedInstaller'
    )

    ShellProcessNames = @(
        'explorer'
    )

    BrowserProcessNames = @(
        'chrome'
        'firefox'
        'msedge'
        'msedgewebview2'
        'brave'
        'opera'
    )

    DeferredProcessToolIds = @(
        'copilot'
        'start-menu-taskbar'
        'game-bar'
        'edge-settings'
        'edge-webview'
        'control-panel-settings'
        'defender-optimize-assistant'
        'services-optimizer'
        'driver-install-debloat-settings'
    )

    HardDenialRules = @(
        'WildcardProcessNames'
        'BroadProcessStopPatterns'
        'VendorWideProcessStop'
        'SystemCriticalProcessStop'
        'SecurityProcessStopWithoutSecurityApproval'
        'ExplorerStopWithoutExplorerRestartPolicy'
        'BroadBrowserProcessStop'
        'PidOnlyWithoutIdentityValidation'
        'MissingUserSessionValidation'
        'ForceKillBeforeGracefulPath'
        'RestartWithoutExactExecutablePath'
        'LaunchHandoffWithoutProvenanceOrExecutionDescriptor'
        'AdjacentFoundationMissing'
        'DeferredToolWithoutProductionAllowlist'
        'UnsavedUserDataRiskWithoutWarningAndConfirmation'
        'AmbiguousProcessMatches'
        'TargetNotInDesignDocument'
    )

    # Phase 68 approves no production process scopes or process targets.
    ProcessHandlingScopes = @()

    # Tests may inject mock names into the helper. Production policy remains
    # empty and deny-by-default.
    ApprovedProcessTargets = @()
}
