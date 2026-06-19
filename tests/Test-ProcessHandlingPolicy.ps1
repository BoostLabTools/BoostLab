[CmdletBinding()]
param(
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $scriptPath = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $PSCommandPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $MyInvocation.MyCommand.Path
    }
    else {
        throw 'Unable to determine the process handling validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

$docPath = Join-Path $ProjectRoot 'docs\process-handling-policy.md'
$configPath = Join-Path $ProjectRoot 'config\ProcessHandlingPolicy.psd1'
$helperPath = Join-Path $ProjectRoot 'core\ProcessHandlingPolicy.psm1'
$matrixPath = Join-Path $ProjectRoot 'docs\final-deferred-tools-readiness-matrix.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$reviewPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$policyPaths = @{
    Artifact            = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
    Appx                = Join-Path $ProjectRoot 'config\AppxPackagePolicy.psd1'
    Cleanup             = Join-Path $ProjectRoot 'config\CleanupPolicy.psd1'
    DriverState         = Join-Path $ProjectRoot 'config\DriverStatePolicy.psd1'
    ProductionAllowlist = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
    RebootRecovery      = Join-Path $ProjectRoot 'config\RebootRecoveryPolicy.psd1'
    Rollback            = Join-Path $ProjectRoot 'config\RollbackPolicy.psd1'
    RestoreSelection    = Join-Path $ProjectRoot 'config\RestoreSelectionPolicy.psd1'
    SafeModeRecovery    = Join-Path $ProjectRoot 'config\SafeModeRecoveryPolicy.psd1'
    ServiceRollback     = Join-Path $ProjectRoot 'config\ServiceRollbackPolicy.psd1'
    TrustedInstaller    = Join-Path $ProjectRoot 'config\TrustedInstallerPolicy.psd1'
}

foreach ($path in @(
    $docPath,
    $configPath,
    $helperPath,
    $matrixPath,
    $planPath,
    $reviewPath,
    $stagesPath
) + $policyPaths.Values) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file was not found: $path"
    }
}

$docText = Get-Content -LiteralPath $docPath -Raw
$matrixText = Get-Content -LiteralPath $matrixPath -Raw
$planText = Get-Content -LiteralPath $planPath -Raw
$reviewText = Get-Content -LiteralPath $reviewPath -Raw
$processPolicy = Import-PowerShellDataFile -LiteralPath $configPath
$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })

foreach ($requiredSection in @(
    '# Process Handling Policy Foundation',
    '## Purpose',
    '## Relationship To Existing Foundations',
    '## Process Operation Types',
    '## Required Process Metadata',
    '## Hard Denial Rules',
    '## ExplorerRestart Handling',
    '## ToolOwnedProcessCleanup Handling',
    '## UI And Runtime Requirements',
    '## Runtime Helper Behavior',
    '## Deferred Tool Impact',
    '## Phase 68 Production State',
    '## Recommended Next Phases'
)) {
    if (-not $docText.Contains($requiredSection)) {
        throw "Process handling documentation is missing section: $requiredSection"
    }
}

foreach ($operationType in @(
    'DetectOnly'
    'WaitForExit'
    'GracefulClose'
    'StopProcess'
    'RestartProcess'
    'LaunchHandoff'
    'ExplorerRestart'
    'ToolOwnedProcessCleanup'
)) {
    if (-not $docText.Contains($operationType)) {
        throw "Process handling documentation is missing operation type: $operationType"
    }
    if ($operationType -notin @($processPolicy.ProcessOperationTypes)) {
        throw "Process handling policy is missing operation type: $operationType"
    }
}

$requiredMetadataFields = @(
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
foreach ($field in $requiredMetadataFields) {
    if (-not $docText.Contains($field)) {
        throw "Process handling documentation is missing metadata field: $field"
    }
    if ($field -notin @($processPolicy.RequiredMetadataFields)) {
        throw "Process handling policy is missing metadata field: $field"
    }
}

foreach ($denialPhrase in @(
    'Wildcard process names',
    'Broad process-stop patterns',
    'Stopping all processes from a vendor',
    'Stopping system-critical processes',
    'Stopping security processes',
    'Stopping shell or Explorer',
    'Stopping browser processes broadly',
    'Killing processes by PID only',
    'Killing processes without user/session validation',
    'Force-kill before a graceful path',
    'Restarting processes without exact executable path',
    'Launch handoff without provenance',
    'TrustedInstaller, Safe Mode, reboot',
    'Process handling for deferred tools without production allowlist approval',
    'unsaved user data',
    'Ambiguous process matches',
    'process target not present in the tool'
)) {
    if (-not $docText.ToLowerInvariant().Contains($denialPhrase.ToLowerInvariant())) {
        throw "Process handling documentation is missing denial rule: $denialPhrase"
    }
}

foreach ($requiredPhrase in @(
    'Production process scopes: **0**',
    'Approved process targets: **0**',
    'Deferred tools enabled: **0**',
    'Runtime tool behavior changes: **0**',
    'Real process operations: **0**',
    'docs/final-deferred-tools-readiness-matrix.md',
    'Action Plan',
    'Activity Log',
    'Latest Result',
    'ExplorerRestart is a special future category',
    'ToolOwnedProcessCleanup is a future low-risk category'
)) {
    if (-not $docText.Contains($requiredPhrase)) {
        throw "Process handling documentation is missing phrase: $requiredPhrase"
    }
}

foreach ($linkedDoc in @($matrixText, $planText, $reviewText)) {
    if (-not $linkedDoc.Contains('docs/process-handling-policy.md')) {
        throw 'A deferred/readiness document does not reference process handling foundation.'
    }
}

if ($processPolicy.ProcessHandlingScopes.Count -ne 0) {
    throw "Phase 68 must not approve production process scopes: $($processPolicy.ProcessHandlingScopes.Count)"
}
if ($processPolicy.ApprovedProcessTargets.Count -ne 0) {
    throw "Phase 68 must not approve production process targets: $($processPolicy.ApprovedProcessTargets.Count)"
}

$module = Import-Module -Name $helperPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    foreach ($commandName in @(
        'Get-BoostLabProcessHandlingPolicy',
        'Test-BoostLabProcessHandlingPolicy',
        'Test-BoostLabProcessNameDenied',
        'Test-BoostLabProcessHandlingProposal',
        'New-BoostLabProcessHandlingPlan'
    )) {
        if (-not (Get-Command -Name $commandName -ErrorAction SilentlyContinue)) {
            throw "Process handling helper is not exported: $commandName"
        }
    }

    $policyValidation = Test-BoostLabProcessHandlingPolicy -Policy $processPolicy
    if (-not $policyValidation.IsValid -or $policyValidation.ScopeCount -ne 0 -or $policyValidation.TargetCount -ne 0) {
        throw "Process handling policy did not validate: $($policyValidation.Errors -join '; ')"
    }

    function New-MockProcessProposal {
        param(
            [string]$ToolId = 'mock-tool',
            [string]$ToolName = 'Mock Tool',
            [string]$OperationType = 'DetectOnly',
            [string]$ProcessName = 'BoostLabMockWorker',
            [string]$ExecutablePath = 'C:\BoostLabMock\BoostLabMockWorker.exe',
            [string]$Publisher = 'Mock publisher requirement',
            [string]$UserSessionScope = 'CurrentInteractiveUser',
            [string]$OwnershipModel = 'ToolOwned',
            [bool]$IsToolOwnedProcess = $true,
            [bool]$UnsavedUserDataRisk = $false,
            [string]$ConfirmationLevel = 'Informational',
            [string]$ApprovalStatus = 'Reviewed',
            [string]$RiskLevel = 'low',
            [string]$IdentityValidationMode = 'NameAndPath',
            [string]$MatchCardinality = 'Single',
            [bool]$RequiresGracefulPath = $false,
            [bool]$RequiresTrustedInstaller = $false,
            [bool]$RequiresSafeMode = $false,
            [bool]$RequiresReboot = $false,
            [bool]$RequiresDownloadOrInstaller = $false,
            [bool]$RequiresServiceMutation = $false,
            [bool]$RequiresDriverMutation = $false,
            [bool]$TargetPresentInDesignDocument = $true
        )

        return [ordered]@{
            ToolId                        = $ToolId
            ToolName                      = $ToolName
            SourcePath                    = 'source-ultimate/Mock/Mock Tool.ps1'
            SourceChecksum                = 'C' * 64
            DesignReviewDocument          = 'docs/tool-designs/mock-tool-scope-design.md'
            SourceBehaviorGroup           = 'Mock process behavior group'
            ProcessOperationType          = $OperationType
            ExactProcessName              = $ProcessName
            ExactExecutablePathRequirement = $ExecutablePath
            PublisherSignatureRequirement = $Publisher
            UserSessionScope              = $UserSessionScope
            OwnershipModel                = $OwnershipModel
            IsToolOwnedProcess            = $IsToolOwnedProcess
            UnsavedUserDataRisk           = $UnsavedUserDataRisk
            ConfirmationLevel             = $ConfirmationLevel
            PreflightVerification         = 'Verify mock process descriptor identity only.'
            PostOperationVerification     = 'Verify no real process operation occurred.'
            TimeoutBehavior               = 'Mock timeout only.'
            RetryBehavior                 = 'No retry in Phase 68.'
            RollbackRecoveryFeasibility   = 'Process state is not Restore.'
            ActionPlanTextRequirement     = 'Action Plan must show exact mock process identity.'
            ActivityLogTextRequirement    = 'Activity Log must show mock process validation only.'
            RiskLevel                     = $RiskLevel
            ApprovalStatus                = $ApprovalStatus
            DenialReason                  = ''
            IdentityValidationMode        = $IdentityValidationMode
            MatchCardinality              = $MatchCardinality
            RequiresGracefulPath          = $RequiresGracefulPath
            RequiresTrustedInstaller      = $RequiresTrustedInstaller
            RequiresSafeMode              = $RequiresSafeMode
            RequiresReboot                = $RequiresReboot
            RequiresDownloadOrInstaller   = $RequiresDownloadOrInstaller
            RequiresServiceMutation       = $RequiresServiceMutation
            RequiresDriverMutation        = $RequiresDriverMutation
            TargetPresentInDesignDocument = $TargetPresentInDesignDocument
        }
    }

    $validDetectOnly = New-MockProcessProposal
    $validDetectResult = Test-BoostLabProcessHandlingProposal `
        -Proposal $validDetectOnly `
        -Confirmed:$true `
        -Policy $processPolicy
    if (-not $validDetectResult.IsEligible -or $validDetectResult.Status -ne 'Eligible' -or $validDetectResult.RuntimeAllowed) {
        throw "Valid fake DetectOnly proposal was not classified Eligible: $($validDetectResult.Errors -join '; ')"
    }

    $mockCleanup = New-MockProcessProposal `
        -OperationType 'ToolOwnedProcessCleanup' `
        -ConfirmationLevel 'Explicit'
    $mockCleanupResult = Test-BoostLabProcessHandlingProposal `
        -Proposal $mockCleanup `
        -Confirmed:$true `
        -ApprovedTestProcessNames @('BoostLabMockWorker') `
        -AllowMockApproval `
        -Policy $processPolicy
    if (-not $mockCleanupResult.IsEligible -or $mockCleanupResult.Status -ne 'Reviewed' -or $mockCleanupResult.RuntimeAllowed) {
        throw "Mock-approved ToolOwnedProcessCleanup proposal was not classified Reviewed: $($mockCleanupResult.Errors -join '; ')"
    }

    $plan = New-BoostLabProcessHandlingPlan -ProposalEvaluation $mockCleanupResult
    if ($plan.Success -or $plan.RuntimeAllowed -or $plan.ProcessStarted -or $plan.ProcessStopped -or $plan.CommandExecuted) {
        throw 'Process handling plan unexpectedly enabled execution.'
    }

    $denialCases = @(
        @{
            Name = 'Wildcard process name'
            Proposal = New-MockProcessProposal -ProcessName 'msedge*'
            Pattern = 'Wildcard'
        }
        @{
            Name = 'Broad process stop'
            Proposal = New-MockProcessProposal -OperationType 'StopProcess' -ProcessName 'all' -ConfirmationLevel 'Explicit'
            Pattern = 'Broad process'
        }
        @{
            Name = 'System critical process'
            Proposal = New-MockProcessProposal -ProcessName 'lsass'
            Pattern = 'System-critical'
        }
        @{
            Name = 'Security process'
            Proposal = New-MockProcessProposal -ProcessName 'MsMpEng'
            Pattern = 'Security process'
        }
        @{
            Name = 'PID only'
            Proposal = New-MockProcessProposal -IdentityValidationMode 'PidOnly'
            Pattern = 'PID only'
        }
        @{
            Name = 'Missing confirmation'
            Proposal = New-MockProcessProposal -OperationType 'StopProcess' -UnsavedUserDataRisk $true -ConfirmationLevel 'Explicit'
            Pattern = 'Unsaved user data|confirmation'
            Confirmed = $false
        }
        @{
            Name = 'Ambiguous process'
            Proposal = New-MockProcessProposal -MatchCardinality 'Ambiguous'
            Pattern = 'Ambiguous'
        }
        @{
            Name = 'Unsupported operation'
            Proposal = New-MockProcessProposal -OperationType 'ForceEverything'
            Pattern = 'Unsupported process operation'
        }
        @{
            Name = 'Deferred tool without approval'
            Proposal = New-MockProcessProposal -ToolId 'copilot' -ToolName 'Copilot' -OperationType 'DetectOnly'
            Pattern = 'Deferred tool'
        }
        @{
            Name = 'Explorer without ExplorerRestart'
            Proposal = New-MockProcessProposal -ProcessName 'explorer' -OperationType 'StopProcess' -ConfirmationLevel 'Explicit'
            Pattern = 'ExplorerRestart'
        }
        @{
            Name = 'Target missing from design'
            Proposal = New-MockProcessProposal -TargetPresentInDesignDocument $false
            Pattern = 'design document'
        }
    )

    foreach ($case in $denialCases) {
        $confirmed = if ($case.ContainsKey('Confirmed')) { [bool]$case.Confirmed } else { $true }
        $result = Test-BoostLabProcessHandlingProposal `
            -Proposal $case.Proposal `
            -Confirmed:$confirmed `
            -Policy $processPolicy
        if ($result.IsEligible -or (@($result.Errors) -join ' ') -notmatch $case.Pattern) {
            throw "Process denial case failed: $($case.Name). Errors: $($result.Errors -join '; ')"
        }
    }
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
}

$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $helperPath,
    [ref]$tokens,
    [ref]$parseErrors
)
if (@($parseErrors).Count -gt 0) {
    throw "Process handling helper has a syntax error: $($parseErrors[0].Message)"
}
$commands = @(
    $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
        $true
    ) |
        ForEach-Object { $_.GetCommandName() } |
        Where-Object { $_ }
)
foreach ($forbiddenCommand in @(
    'Get-Process'
    'Wait-Process'
    'Start-Process'
    'Stop-Process'
    'Invoke-Expression'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Remove-Item'
    'Set-ItemProperty'
    'New-ItemProperty'
    'Stop-Service'
    'Set-Service'
    'Add-AppxPackage'
    'Remove-AppxPackage'
    'pnputil'
    'sc.exe'
    'taskkill'
    'bcdedit'
    'shutdown'
    'Restart-Computer'
)) {
    if ($forbiddenCommand -in $commands) {
        throw "Process handling helper contains prohibited command: $forbiddenCommand"
    }
}

$placeholderModules = @(
    Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' |
        Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw).Contains(
                'ToolModule.Placeholder.ps1'
            )
        }
)
if ($allTools.Count -ne $inventoryBaseline.ActiveTools) {
    throw "Expected $($inventoryBaseline.ActiveTools) active tools, found $($allTools.Count)."
}
if ($placeholderModules.Count -ne $inventoryBaseline.DeferredPlaceholders) {
    throw "Expected $($inventoryBaseline.DeferredPlaceholders) placeholder modules, found $($placeholderModules.Count)."
}
if (($allTools.Count - $placeholderModules.Count) -ne $inventoryBaseline.ImplementedTools) {
    throw "Expected $($inventoryBaseline.ImplementedTools) implemented tools, found $($allTools.Count - $placeholderModules.Count)."
}

$artifactPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.Artifact
$appxPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.Appx
$cleanupPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.Cleanup
$driverPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.DriverState
$productionAllowlistPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.ProductionAllowlist
$rebootPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.RebootRecovery
$rollbackPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.Rollback
$restorePolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.RestoreSelection
$safeModePolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.SafeModeRecovery
$servicePolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.ServiceRollback
$trustedPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.TrustedInstaller

if (
    $artifactPolicy.Artifacts.Count -ne 0 -or
    $appxPolicy.PackageScopes.Count -ne 0 -or
    $cleanupPolicy.CleanupScopes.Count -ne 0 -or
    $driverPolicy.DriverScopes.Count -ne 0 -or
    $productionAllowlistPolicy.ProductionAllowlistProposals.Count -ne 0 -or
    $processPolicy.ProcessHandlingScopes.Count -ne 0 -or
    $processPolicy.ApprovedProcessTargets.Count -ne 0 -or
    $rebootPolicy.WorkflowScopes.Count -ne 0 -or
    $rollbackPolicy.FileScopes.Count -ne 0 -or
    $rollbackPolicy.RegistryScopes.Count -ne 0 -or
    $restorePolicy.RestoreSelectionScopes.Count -ne 0 -or
    $restorePolicy.ApprovedRestoreHandlers.Count -ne 0 -or
    $safeModePolicy.SafeModeScopes.Count -ne 0 -or
    $servicePolicy.ServiceScopes.Count -ne 0 -or
    $trustedPolicy.TrustedInstallerScopes.Count -ne 0
) {
    throw 'A production scope, allowlist, artifact, workflow, or process target was unexpectedly approved.'
}

foreach ($deletedTool in @('Loudness EQ', 'NVME Faster Driver')) {
    if ($allTools | Where-Object { $_.Title -eq $deletedTool }) {
        throw "Deleted tool was reintroduced into config: $deletedTool"
    }
}
$loudnessPath = Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1'
if (Test-Path -LiteralPath $loudnessPath) {
    throw 'Loudness EQ source was reintroduced.'
}
$nvmeSource = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Where-Object { $_.Name -like '*NVME Faster Driver*' }
)
if ($nvmeSource.Count -ne 0) {
    throw 'NVME Faster Driver source was reintroduced.'
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
    Sort-Object {
        $_.FullName.Substring($root.Length + 1).Replace('\', '/')
    } |
    ForEach-Object {
        '{0}|{1}' -f `
            $_.FullName.Substring($root.Length + 1).Replace('\', '/'), `
            (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    }
$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $manifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash(
            [Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n"))
        )
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}
if (
    @($sourceLines).Count -ne 49 -or
    $manifestHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477'
) {
    throw 'source-ultimate content or paths changed.'
}

[pscustomobject]@{
    Success                    = $true
    DocumentationPath          = $docPath
    PolicyPath                 = $configPath
    HelperPath                 = $helperPath
    OperationTypeCount         = @($processPolicy.ProcessOperationTypes).Count
    RequiredMetadataFieldCount = @($processPolicy.RequiredMetadataFields).Count
    HardDenialRuleCount        = @($processPolicy.HardDenialRules).Count
    ProductionProcessScopes    = $processPolicy.ProcessHandlingScopes.Count
    ApprovedProcessTargets     = $processPolicy.ApprovedProcessTargets.Count
    ImplementedToolCount       = $allTools.Count - $placeholderModules.Count
    PlaceholderToolCount       = $placeholderModules.Count
    ActiveToolCount            = $allTools.Count
    SourceUltimateUnchanged    = $true
    DeletedToolsRemainDeleted  = $true
    Message                    = 'Process handling foundation is documented, inert, mock-validated, and deny-by-default.'
    Timestamp                  = Get-Date
}



