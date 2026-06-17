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
        throw 'Unable to determine the restore selection validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$docPath = Join-Path $ProjectRoot 'docs\restore-selection-ui-runtime.md'
$configPath = Join-Path $ProjectRoot 'config\RestoreSelectionPolicy.psd1'
$helperPath = Join-Path $ProjectRoot 'core\RestoreSelection.psm1'
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
    ProductionAllowlist = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
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
$restorePolicy = Import-PowerShellDataFile -LiteralPath $configPath
$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })

foreach ($requiredSection in @(
    '# Restore Selection UI / Runtime Foundation',
    '## Purpose',
    '## Relationship To Existing Foundations',
    '## Restore Record Discovery',
    '## Restore Record Metadata',
    '## Eligibility Gates',
    '## Future Restore Selector UI',
    '## Runtime Helper Behavior',
    '## Default Versus Restore',
    '## Deferred Tool Impact',
    '## Phase 67 Production State',
    '## Recommended Next Phases'
)) {
    if (-not $docText.Contains($requiredSection)) {
        throw "Restore selection documentation is missing section: $requiredSection"
    }
}

$requiredMetadataFields = @(
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
foreach ($field in $requiredMetadataFields) {
    if (-not $docText.Contains($field)) {
        throw "Restore selection documentation is missing metadata field: $field"
    }
    if ($field -notin @($restorePolicy.RequiredMetadataFields)) {
        throw "Restore selection policy is missing metadata field: $field"
    }
}

foreach ($gatePhrase in @(
    'Integrity check fails',
    'Schema version is unsupported',
    'Tool id mismatches',
    'Source action mismatches',
    'Scope type mismatches',
    'Record type mismatches',
    'Target identity mismatches',
    'Machine context mismatches',
    'User context mismatches',
    'Product-scope context mismatches',
    'Record is stale beyond policy',
    'Source checksum mismatches',
    'Required post-mutation state is not present',
    'Target now belongs to a different owner or unknown state',
    'Target is outside current approved scopes',
    'broad registry hive restore',
    'broad file root restore',
    'cross from one tool to another',
    'reintroduce deleted tools',
    'unapproved TrustedInstaller',
    'handler not approved by policy',
    'multiple conflicting records',
    'User confirmation is missing'
)) {
    if (-not $docText.ToLowerInvariant().Contains($gatePhrase.ToLowerInvariant())) {
        throw "Restore selection documentation is missing eligibility gate: $gatePhrase"
    }
}

foreach ($requiredPhrase in @(
    'Default is not the same as Restore.',
    'Production Restore scopes: **0**',
    'Approved Restore handlers: **0**',
    'Deferred tools enabled: **0**',
    'Visible Restore buttons added: **0**',
    'Runtime tool behavior changes: **0**',
    'docs/final-deferred-tools-readiness-matrix.md',
    'Process Handling Policy Foundation',
    'Scheduled Task State Capture / Rollback Foundation',
    'Generated Script / Temp Artifact Ownership Policy'
)) {
    if (-not $docText.Contains($requiredPhrase)) {
        throw "Restore selection documentation is missing phrase: $requiredPhrase"
    }
}

foreach ($linkedDoc in @($matrixText, $planText, $reviewText)) {
    if (-not $linkedDoc.Contains('docs/restore-selection-ui-runtime.md')) {
        throw 'A deferred/readiness document does not reference restore selection foundation.'
    }
}

if ($restorePolicy.RestoreSelectionScopes.Count -ne 0) {
    throw "Phase 67 must not approve production Restore scopes: $($restorePolicy.RestoreSelectionScopes.Count)"
}
if ($restorePolicy.ApprovedRestoreHandlers.Count -ne 0) {
    throw "Phase 67 must not approve production Restore handlers: $($restorePolicy.ApprovedRestoreHandlers.Count)"
}

$module = Import-Module -Name $helperPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    foreach ($commandName in @(
        'Get-BoostLabRestoreSelectionPolicy',
        'New-BoostLabRestoreSelectionIntegrityHash',
        'Test-BoostLabRestoreSelectionPolicy',
        'Test-BoostLabRestoreSelectionCandidate',
        'Select-BoostLabRestoreSelectionCandidate',
        'New-BoostLabRestoreSelectionPlan'
    )) {
        if (-not (Get-Command -Name $commandName -ErrorAction SilentlyContinue)) {
            throw "Restore selection helper is not exported: $commandName"
        }
    }

    $policyValidation = Test-BoostLabRestoreSelectionPolicy -Policy $restorePolicy
    if (-not $policyValidation.IsValid -or $policyValidation.ScopeCount -ne 0 -or $policyValidation.HandlerCount -ne 0) {
        throw "Restore selection policy did not validate: $($policyValidation.Errors -join '; ')"
    }

    function New-MockRestoreRecord {
        param(
            [string]$RecordId = 'mock-restore-record-1',
            [string]$ToolId = 'mock-tool',
            [string]$ToolName = 'Mock Tool',
            [string]$SourceAction = 'Apply',
            [string]$ScopeType = 'File',
            [string]$RecordType = 'Mock',
            [string[]]$Targets = @('C:\BoostLabMock\owned-file.txt'),
            [datetime]$Timestamp = (Get-Date),
            [string]$Handler = 'MockRestore',
            [bool]$PostMutationStatePresent = $true,
            [string]$SchemaVersion = '1.0',
            [string]$EligibilityState = 'Eligible'
        )

        $record = [ordered]@{
            RestoreRecordId             = $RecordId
            ToolId                      = $ToolId
            ToolName                    = $ToolName
            SourcePath                  = 'source-ultimate/Mock/Mock Tool.ps1'
            SourceChecksum              = 'B' * 64
            SourceAction                = $SourceAction
            ScopeType                   = $ScopeType
            RecordType                  = $RecordType
            CapturedTargetIdentities    = $Targets
            Timestamp                   = $Timestamp.ToString('o')
            MachineContext              = 'MockMachine'
            UserContext                 = 'MockUser'
            OperatingSystemContext      = 'Windows 11 mock'
            ProductScopeContext         = 'Shared Windows behavior'
            PreMutationStateSummary     = 'Mock pre-mutation state'
            PostMutationStateRequirement = 'PostMutationMustMatch'
            PostMutationStatePresent    = $PostMutationStatePresent
            RestoreHandlerType          = $Handler
            IntegrityHash               = ''
            SchemaVersion               = $SchemaVersion
            ApprovalPolicyVersion       = 'Phase67-Mock'
            RiskLevel                   = 'high'
            RestoreEligibilityState     = $EligibilityState
            DenialReason                = ''
        }
        $record.IntegrityHash = New-BoostLabRestoreSelectionIntegrityHash -Record $record -Policy $restorePolicy
        return $record
    }

    $validRecord = New-MockRestoreRecord
    $validEvaluation = Test-BoostLabRestoreSelectionCandidate `
        -Candidate $validRecord `
        -ToolId 'mock-tool' `
        -SourceAction 'Apply' `
        -ScopeType 'File' `
        -RecordType 'Mock' `
        -TargetIdentities @('C:\BoostLabMock\owned-file.txt') `
        -Confirmed:$true `
        -ApprovedHandlerTypes @('MockRestore') `
        -Policy $restorePolicy
    if (-not $validEvaluation.IsEligible -or $validEvaluation.Status -ne 'Eligible' -or $validEvaluation.RuntimeAllowed) {
        throw "Valid fake restore record was not classified Eligible: $($validEvaluation.Errors -join '; ')"
    }

    $plan = New-BoostLabRestoreSelectionPlan -CandidateEvaluation $validEvaluation
    if ($plan.Success -or $plan.RuntimeAllowed -or $plan.Status -ne 'NotImplemented') {
        throw 'Restore selection plan unexpectedly enabled execution.'
    }

    $integrityMismatch = New-MockRestoreRecord
    $integrityMismatch.IntegrityHash = '0' * 64
    $integrityResult = Test-BoostLabRestoreSelectionCandidate `
        -Candidate $integrityMismatch `
        -ToolId 'mock-tool' `
        -SourceAction 'Apply' `
        -ScopeType 'File' `
        -RecordType 'Mock' `
        -Confirmed:$true `
        -ApprovedHandlerTypes @('MockRestore') `
        -Policy $restorePolicy
    if ($integrityResult.IsEligible -or (@($integrityResult.Errors) -join ' ') -notmatch 'Integrity') {
        throw 'Integrity mismatch was not denied.'
    }

    $toolMismatch = New-MockRestoreRecord -ToolId 'other-tool'
    $toolMismatchResult = Test-BoostLabRestoreSelectionCandidate `
        -Candidate $toolMismatch `
        -ToolId 'mock-tool' `
        -SourceAction 'Apply' `
        -ScopeType 'File' `
        -RecordType 'Mock' `
        -Confirmed:$true `
        -ApprovedHandlerTypes @('MockRestore') `
        -Policy $restorePolicy
    if ($toolMismatchResult.IsEligible -or (@($toolMismatchResult.Errors) -join ' ') -notmatch 'Tool id mismatch') {
        throw 'Tool mismatch was not denied.'
    }

    $scopeMismatch = New-MockRestoreRecord -ScopeType 'Registry' -Targets @('HKCU:\Software\BoostLab\Mock')
    $scopeMismatchResult = Test-BoostLabRestoreSelectionCandidate `
        -Candidate $scopeMismatch `
        -ToolId 'mock-tool' `
        -SourceAction 'Apply' `
        -ScopeType 'File' `
        -RecordType 'Mock' `
        -Confirmed:$true `
        -ApprovedHandlerTypes @('MockRestore') `
        -Policy $restorePolicy
    if ($scopeMismatchResult.IsEligible -or (@($scopeMismatchResult.Errors) -join ' ') -notmatch 'Scope type mismatch') {
        throw 'Scope mismatch was not denied.'
    }

    $staleRecord = New-MockRestoreRecord -Timestamp (Get-Date).AddDays(-45)
    $staleResult = Test-BoostLabRestoreSelectionCandidate `
        -Candidate $staleRecord `
        -ToolId 'mock-tool' `
        -SourceAction 'Apply' `
        -ScopeType 'File' `
        -RecordType 'Mock' `
        -Confirmed:$true `
        -ApprovedHandlerTypes @('MockRestore') `
        -Policy $restorePolicy
    if ($staleResult.IsEligible -or (@($staleResult.Errors) -join ' ') -notmatch 'stale') {
        throw 'Stale record was not denied.'
    }

    $broadTarget = New-MockRestoreRecord -Targets @('C:\Windows')
    $broadTargetResult = Test-BoostLabRestoreSelectionCandidate `
        -Candidate $broadTarget `
        -ToolId 'mock-tool' `
        -SourceAction 'Apply' `
        -ScopeType 'File' `
        -RecordType 'Mock' `
        -Confirmed:$true `
        -ApprovedHandlerTypes @('MockRestore') `
        -Policy $restorePolicy
    if ($broadTargetResult.IsEligible -or (@($broadTargetResult.Errors) -join ' ') -notmatch 'Broad file root') {
        throw 'Broad file root restore was not denied.'
    }

    $missingConfirmationResult = Test-BoostLabRestoreSelectionCandidate `
        -Candidate $validRecord `
        -ToolId 'mock-tool' `
        -SourceAction 'Apply' `
        -ScopeType 'File' `
        -RecordType 'Mock' `
        -Confirmed:$false `
        -ApprovedHandlerTypes @('MockRestore') `
        -Policy $restorePolicy
    if ($missingConfirmationResult.IsEligible -or (@($missingConfirmationResult.Errors) -join ' ') -notmatch 'confirmation') {
        throw 'Missing confirmation was not denied.'
    }

    $unsupportedHandlerResult = Test-BoostLabRestoreSelectionCandidate `
        -Candidate $validRecord `
        -ToolId 'mock-tool' `
        -SourceAction 'Apply' `
        -ScopeType 'File' `
        -RecordType 'Mock' `
        -Confirmed:$true `
        -ApprovedHandlerTypes @('DifferentMockHandler') `
        -Policy $restorePolicy
    if ($unsupportedHandlerResult.IsEligible -or (@($unsupportedHandlerResult.Errors) -join ' ') -notmatch 'handler') {
        throw 'Unsupported handler was not denied.'
    }

    $secondValidRecord = New-MockRestoreRecord -RecordId 'mock-restore-record-2'
    $ambiguousResult = Select-BoostLabRestoreSelectionCandidate `
        -Candidates @($validRecord, $secondValidRecord) `
        -ToolId 'mock-tool' `
        -SourceAction 'Apply' `
        -ScopeType 'File' `
        -RecordType 'Mock' `
        -TargetIdentities @('C:\BoostLabMock\owned-file.txt') `
        -Confirmed:$true `
        -ApprovedHandlerTypes @('MockRestore') `
        -Policy $restorePolicy
    if ($ambiguousResult.IsSelected -or (@($ambiguousResult.Errors) -join ' ') -notmatch 'ambiguous|multiple conflicting') {
        throw 'Ambiguous restore candidate set was not denied.'
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
    throw "Restore selection helper has a syntax error: $($parseErrors[0].Message)"
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
    'Add-AppxPackage'
    'Remove-AppxPackage'
    'pnputil'
    'bcdedit'
    'shutdown'
)) {
    if ($forbiddenCommand -in $commands) {
        throw "Restore selection helper contains prohibited command: $forbiddenCommand"
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
if ($allTools.Count -ne 50) {
    throw "Expected 50 active tools, found $($allTools.Count)."
}
if ($placeholderModules.Count -ne 18) {
    throw "Expected 18 placeholder modules, found $($placeholderModules.Count)."
}
if (($allTools.Count - $placeholderModules.Count) -ne 32) {
    throw "Expected 32 implemented tools, found $($allTools.Count - $placeholderModules.Count)."
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
$productionAllowlistPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.ProductionAllowlist

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
    $trustedPolicy.TrustedInstallerScopes.Count -ne 0 -or
    $productionAllowlistPolicy.ProductionAllowlistProposals.Count -ne 0
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
    Success                    = $true
    DocumentationPath          = $docPath
    PolicyPath                 = $configPath
    HelperPath                 = $helperPath
    RequiredMetadataFieldCount = @($restorePolicy.RequiredMetadataFields).Count
    ProductionRestoreScopes    = $restorePolicy.RestoreSelectionScopes.Count
    ApprovedRestoreHandlers    = $restorePolicy.ApprovedRestoreHandlers.Count
    ImplementedToolCount       = $allTools.Count - $placeholderModules.Count
    PlaceholderToolCount       = $placeholderModules.Count
    ActiveToolCount            = $allTools.Count
    SourceUltimateUnchanged    = $true
    DeletedToolsRemainDeleted  = $true
    Message                    = 'Restore selection foundation is documented, inert, mock-validated, and deny-by-default.'
    Timestamp                  = Get-Date
}

