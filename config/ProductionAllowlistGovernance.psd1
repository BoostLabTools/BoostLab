@{
    SchemaVersion = '1.0'

    ApprovalStates = @(
        'Draft'
        'Reviewed'
        'Approved'
        'Rejected'
        'Deprecated'
    )

    ScopeTypes = @(
        'Registry'
        'File'
        'Cleanup'
        'Service'
        'AppX'
        'Driver'
        'ScheduledTask'
        'Process'
        'DownloadArtifact'
        'InstallerExecution'
        'RebootWorkflow'
        'TrustedInstaller'
        'SafeMode'
        'RunOnce'
        'ActiveSetup'
        'BHO'
        'GeneratedScript'
    )

    SupportedActions = @(
        'Analyze'
        'Apply'
        'Default'
        'Restore'
        'Open'
        'Launch'
    )

    RequiredMetadataFields = @(
        'ToolId'
        'ToolName'
        'SourcePath'
        'SourceChecksum'
        'DesignReviewDocument'
        'SourceBehaviorGroup'
        'ScopeType'
        'ExactTargetIdentity'
        'MutationType'
        'SupportedAction'
        'RequiredFoundationDependency'
        'RequiredCaptureBeforeMutation'
        'RequiredConfirmationLevel'
        'RequiredPreMutationVerification'
        'RequiredPostMutationVerification'
        'RollbackFeasibility'
        'DefaultRestoreStatus'
        'ProductScopeImpact'
        'RiskLevel'
        'OwnerApprovalNote'
        'ApprovalStatus'
        'ApprovalDateOrVersion'
        'TestsRequired'
        'ValidatorRequired'
        'DenialReason'
    )

    HardDenialRules = @(
        'WildcardOnlyTargets'
        'BroadRegistryHives'
        'BroadFileRoots'
        'UnknownAppxPackages'
        'FrameworkDependencySystemCriticalPackagesWithoutException'
        'UnknownServices'
        'WildcardServices'
        'DynamicScheduledTaskMutation'
        'BroadProcessStop'
        'UnverifiedDownloads'
        'MutableUrlsWithoutHashSignerProvenance'
        'InstallerExecutionWithoutExactDescriptor'
        'RebootOrFirmwareWithoutWorkflowPolicy'
        'TrustedInstallerWithoutTargetSpecificDescriptor'
        'SafeModeWithoutRecoveryExitPlan'
        'RunOnceActiveSetupBhoWithoutExactAllowlistAndCapture'
        'GeneratedScriptsWithoutOwnershipHashPathPolicy'
        'BroadDefaultDeletion'
        'RestoreWithoutCapturedStateSelection'
    )

    # Phase 66 defines governance only. No production allowlist proposal,
    # production scope, artifact, installer, reboot workflow, Safe Mode flow,
    # TrustedInstaller target, process, scheduled task, service, AppX, driver,
    # cleanup, file, or registry target is approved here.
    ProductionAllowlistProposals = @()
}
