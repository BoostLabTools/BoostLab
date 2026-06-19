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
        throw 'Unable to determine the production allowlist governance validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

$docPath = Join-Path $ProjectRoot 'docs\production-allowlist-governance.md'
$configPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$helperPath = Join-Path $ProjectRoot 'core\ProductionAllowlistGovernance.psm1'
$matrixPath = Join-Path $ProjectRoot 'docs\final-deferred-tools-readiness-matrix.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$reviewPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$policyPaths = @{
    Artifact          = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
    Appx              = Join-Path $ProjectRoot 'config\AppxPackagePolicy.psd1'
    Cleanup           = Join-Path $ProjectRoot 'config\CleanupPolicy.psd1'
    DriverState       = Join-Path $ProjectRoot 'config\DriverStatePolicy.psd1'
    RebootRecovery    = Join-Path $ProjectRoot 'config\RebootRecoveryPolicy.psd1'
    Rollback          = Join-Path $ProjectRoot 'config\RollbackPolicy.psd1'
    SafeModeRecovery  = Join-Path $ProjectRoot 'config\SafeModeRecoveryPolicy.psd1'
    ServiceRollback   = Join-Path $ProjectRoot 'config\ServiceRollbackPolicy.psd1'
    TrustedInstaller  = Join-Path $ProjectRoot 'config\TrustedInstallerPolicy.psd1'
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
$governancePolicy = Import-PowerShellDataFile -LiteralPath $configPath
$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })

foreach ($requiredSection in @(
    '# Production Allowlist Governance',
    '## Purpose',
    '## Relationship To Phase 65',
    '## Approval Lifecycle',
    '## Required Metadata Fields',
    '## Scope Types',
    '## Review Gates',
    '## Per-Scope-Type Rules',
    '## Hard Denial Rules',
    '## Scope Drift Validation',
    '## Preserving Ultimate Execution Strength',
    '## Preventing Unsafe Partial Implementation',
    '## Future Approval Workflow',
    '## Phase 66 Production State',
    '## Recommended Next Phases'
)) {
    if (-not $docText.Contains($requiredSection)) {
        throw "Production allowlist governance doc is missing section: $requiredSection"
    }
}

foreach ($state in @('Draft', 'Reviewed', 'Approved', 'Rejected', 'Deprecated')) {
    $stateCode = '``{0}``' -f $state
    if (-not $docText.Contains($stateCode) -and -not $docText.Contains($state)) {
        throw "Production allowlist governance doc is missing approval state: $state"
    }
    if ($state -notin @($governancePolicy.ApprovalStates)) {
        throw "Production allowlist governance config is missing approval state: $state"
    }
}

$requiredMetadataFields = @(
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
foreach ($field in $requiredMetadataFields) {
    $fieldCode = '``{0}``' -f $field
    if (-not $docText.Contains($fieldCode) -and -not $docText.Contains($field)) {
        throw "Production allowlist governance doc is missing required metadata field: $field"
    }
    if ($field -notin @($governancePolicy.RequiredMetadataFields)) {
        throw "Production allowlist governance config is missing required metadata field: $field"
    }
}

foreach ($scopeType in @(
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
)) {
    $scopeTypeCode = '``{0}``' -f $scopeType
    if (-not $docText.Contains($scopeTypeCode) -and -not $docText.Contains($scopeType)) {
        throw "Production allowlist governance doc is missing scope type: $scopeType"
    }
    if ($scopeType -notin @($governancePolicy.ScopeTypes)) {
        throw "Production allowlist governance config is missing scope type: $scopeType"
    }
}

foreach ($denialPhrase in @(
    'Wildcard-only targets',
    'Broad registry hives',
    'Broad file roots',
    'Unknown AppX packages',
    'Framework, dependency, or system-critical packages',
    'Unknown services',
    'Wildcard services',
    'Dynamic scheduled task mutation',
    'Broad process stop',
    'Unverified downloads',
    'Mutable URLs without approved hash, signer, and provenance',
    'Installer execution without an exact descriptor',
    'Reboot or firmware restart without workflow policy',
    'TrustedInstaller use without a target-specific descriptor',
    'Safe Mode flow without a recovery and exit plan',
    'RunOnce, Active Setup, or BHO mutation without exact key allowlist and capture',
    'Generated scripts without ownership, hash, and path policy',
    'Default behavior that deletes broad keys or paths',
    'Restore behavior without exact captured-state selection and verification'
)) {
    if (-not $docText.Contains($denialPhrase)) {
        throw "Production allowlist governance doc is missing hard denial phrase: $denialPhrase"
    }
}

foreach ($requiredPhrase in @(
    'docs/final-deferred-tools-readiness-matrix.md',
    'prevents weakening Ultimate behavior',
    'prevents unsafe partial implementation',
    'Production allowlist proposals: **0**',
    'Approved production scopes: **0**',
    'Deferred tools enabled: **0**',
    'Restore Selection UI / Runtime Foundation',
    'Process Handling Policy Foundation',
    'Scheduled Task State Capture / Rollback Foundation',
    'Generated Script / Temp Artifact Ownership Policy',
    'RunOnce / Active Setup Governance'
)) {
    if (-not $docText.Contains($requiredPhrase)) {
        throw "Production allowlist governance doc is missing phrase: $requiredPhrase"
    }
}

if (-not $matrixText.Contains('docs/production-allowlist-governance.md')) {
    throw 'Final deferred readiness matrix does not reference production allowlist governance.'
}
if (-not $planText.Contains('docs/production-allowlist-governance.md')) {
    throw 'Deferred tools execution plan does not reference production allowlist governance.'
}
if (-not $reviewText.Contains('docs/production-allowlist-governance.md')) {
    throw 'Deferred tool readiness review does not reference production allowlist governance.'
}

if ($governancePolicy.ProductionAllowlistProposals.Count -ne 0) {
    throw "Phase 66 must not add production allowlist proposals: $($governancePolicy.ProductionAllowlistProposals.Count)"
}

$module = Import-Module -Name $helperPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    foreach ($commandName in @(
        'Get-BoostLabProductionAllowlistGovernancePolicy',
        'Test-BoostLabProductionAllowlistPolicy',
        'Test-BoostLabProductionAllowlistProposal',
        'New-BoostLabProductionAllowlistDecision'
    )) {
        if (-not (Get-Command -Name $commandName -ErrorAction SilentlyContinue)) {
            throw "Production allowlist governance helper is not exported: $commandName"
        }
    }

    $policyValidation = Test-BoostLabProductionAllowlistPolicy -Policy $governancePolicy
    if (-not $policyValidation.IsValid -or $policyValidation.ProposalCount -ne 0) {
        throw "Production allowlist governance policy did not validate: $($policyValidation.Errors -join '; ')"
    }

    $baseProposal = [ordered]@{
        ToolId                           = 'mock-tool'
        ToolName                         = 'Mock Tool'
        SourcePath                       = 'source-ultimate/Mock/Mock Tool.ps1'
        SourceChecksum                   = 'A' * 64
        DesignReviewDocument             = 'docs/tool-designs/mock-tool-scope-design.md'
        SourceBehaviorGroup              = 'Mock exact registry value'
        ScopeType                        = 'Registry'
        ExactTargetIdentity              = 'HKCU:\Software\BoostLab\MockTool\Setting'
        MutationType                     = 'SetValue'
        SupportedAction                  = 'Apply'
        RequiredFoundationDependency     = 'File and Registry State Capture and Rollback'
        RequiredCaptureBeforeMutation    = $true
        RequiredConfirmationLevel        = 'Explicit'
        RequiredPreMutationVerification  = $true
        RequiredPostMutationVerification = $true
        RollbackFeasibility              = 'Restore requires captured state'
        DefaultRestoreStatus             = 'Default refused; Restore requires captured-state selection'
        ProductScopeImpact               = 'No product-scope exception'
        RiskLevel                        = 'high'
        OwnerApprovalNote                = 'Mock proposal for validator only'
        ApprovalStatus                   = 'Draft'
        ApprovalDateOrVersion            = ''
        TestsRequired                    = @('Test-MockProductionAllowlist.ps1')
        ValidatorRequired                = 'Test-MockProductionAllowlist.ps1'
        DenialReason                     = ''
    }

    $draftValidation = Test-BoostLabProductionAllowlistProposal -Proposal $baseProposal -Policy $governancePolicy
    if (-not $draftValidation.IsValid -or $draftValidation.RuntimeAllowed) {
        throw "Valid fake Draft proposal did not validate as non-executing: $($draftValidation.Errors -join '; ')"
    }

    $decision = New-BoostLabProductionAllowlistDecision -Proposal $baseProposal -Policy $governancePolicy
    if (
        $decision.Success -or
        $decision.RuntimeAllowed -or
        $decision.ProcessStarted -or
        $decision.CommandExecuted -or
        $decision.Status -ne 'NotImplemented'
    ) {
        throw 'Production allowlist governance decision helper is not inert.'
    }

    $approvedProposal = [ordered]@{}
    foreach ($key in $baseProposal.Keys) {
        $approvedProposal[$key] = $baseProposal[$key]
    }
    $approvedProposal['ApprovalStatus'] = 'Approved'
    $approvedProposal['ApprovalDateOrVersion'] = '2026-06-16'
    $approvedValidation = Test-BoostLabProductionAllowlistProposal -Proposal $approvedProposal -Policy $governancePolicy
    if ($approvedValidation.IsValid -or (@($approvedValidation.Errors) -join ' ') -notmatch 'cannot approve') {
        throw 'Phase 66 helper allowed an Approved production proposal.'
    }

    $missingFieldProposal = [ordered]@{}
    foreach ($key in $baseProposal.Keys) {
        if ($key -ne 'SourceChecksum') {
            $missingFieldProposal[$key] = $baseProposal[$key]
        }
    }
    $missingFieldValidation = Test-BoostLabProductionAllowlistProposal -Proposal $missingFieldProposal -Policy $governancePolicy
    if ($missingFieldValidation.IsValid -or (@($missingFieldValidation.Errors) -join ' ') -notmatch 'SourceChecksum') {
        throw 'Proposal missing SourceChecksum was not blocked.'
    }

    $wildcardProposal = [ordered]@{}
    foreach ($key in $baseProposal.Keys) {
        $wildcardProposal[$key] = $baseProposal[$key]
    }
    $wildcardProposal['ExactTargetIdentity'] = 'HKCU:\Software\Microsoft\Windows\*'
    $wildcardValidation = Test-BoostLabProductionAllowlistProposal -Proposal $wildcardProposal -Policy $governancePolicy
    if ($wildcardValidation.IsValid -or (@($wildcardValidation.Errors) -join ' ') -notmatch 'Wildcard') {
        throw 'Wildcard target proposal was not blocked.'
    }

    $broadFileProposal = [ordered]@{}
    foreach ($key in $baseProposal.Keys) {
        $broadFileProposal[$key] = $baseProposal[$key]
    }
    $broadFileProposal['ScopeType'] = 'File'
    $broadFileProposal['ExactTargetIdentity'] = 'C:\Windows'
    $broadFileValidation = Test-BoostLabProductionAllowlistProposal -Proposal $broadFileProposal -Policy $governancePolicy
    if ($broadFileValidation.IsValid -or (@($broadFileValidation.Errors) -join ' ') -notmatch 'Broad file roots') {
        throw 'Broad file root proposal was not blocked.'
    }

    $processProposal = [ordered]@{}
    foreach ($key in $baseProposal.Keys) {
        $processProposal[$key] = $baseProposal[$key]
    }
    $processProposal['ScopeType'] = 'Process'
    $processProposal['ExactTargetIdentity'] = '*'
    $processValidation = Test-BoostLabProductionAllowlistProposal -Proposal $processProposal -Policy $governancePolicy
    if ($processValidation.IsValid -or (@($processValidation.Errors) -join ' ') -notmatch 'Broad process stop|Wildcard') {
        throw 'Broad process proposal was not blocked.'
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
    throw "Production allowlist helper has a syntax error: $($parseErrors[0].Message)"
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
    'Start-Process'
    'Invoke-Expression'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Remove-Item'
    'Set-ItemProperty'
    'New-ItemProperty'
    'Stop-Process'
    'Stop-Service'
    'Set-Service'
    'schtasks'
    'bcdedit'
)) {
    if ($forbiddenCommand -in $commands) {
        throw "Production allowlist helper contains prohibited command: $forbiddenCommand"
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
$rebootPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.RebootRecovery
$rollbackPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.Rollback
$safeModePolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.SafeModeRecovery
$servicePolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.ServiceRollback
$trustedPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.TrustedInstaller

if (
    $artifactPolicy.Artifacts.Count -ne 0 -or
    $appxPolicy.PackageScopes.Count -ne 0 -or
    $cleanupPolicy.CleanupScopes.Count -ne 0 -or
    $driverPolicy.DriverScopes.Count -ne 0 -or
    $rebootPolicy.WorkflowScopes.Count -ne 0 -or
    $rollbackPolicy.FileScopes.Count -ne 0 -or
    $rollbackPolicy.RegistryScopes.Count -ne 0 -or
    $safeModePolicy.SafeModeScopes.Count -ne 0 -or
    $servicePolicy.ServiceScopes.Count -ne 0 -or
    $trustedPolicy.TrustedInstallerScopes.Count -ne 0
) {
    throw 'A production scope, allowlist, artifact, or workflow was unexpectedly approved.'
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
    Success                   = $true
    GovernanceDoc             = $docPath
    ConfigPath                = $configPath
    HelperPath                = $helperPath
    ApprovalStateCount        = @($governancePolicy.ApprovalStates).Count
    RequiredMetadataFieldCount = @($governancePolicy.RequiredMetadataFields).Count
    HardDenialRuleCount       = @($governancePolicy.HardDenialRules).Count
    ProductionProposalCount   = $governancePolicy.ProductionAllowlistProposals.Count
    ImplementedToolCount      = $allTools.Count - $placeholderModules.Count
    PlaceholderToolCount      = $placeholderModules.Count
    ActiveToolCount           = $allTools.Count
    SourceUltimateUnchanged   = $true
    DeletedToolsRemainDeleted = $true
    Message                   = 'Production allowlist governance is documented, empty, inert, and deny-by-default.'
    Timestamp                 = Get-Date
}



