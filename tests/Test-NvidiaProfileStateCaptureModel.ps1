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
        throw 'Unable to determine the NVIDIA profile state capture model validator path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

function Get-BoostLabManifestHash {
    param(
        [Parameter(Mandatory)]
        [string[]]$Lines
    )

    [BitConverter]::ToString(
        [Security.Cryptography.SHA256]::Create().ComputeHash(
            [Text.Encoding]::UTF8.GetBytes(($Lines -join "`n"))
        )
    ).Replace('-', '')
}

$modelPath = Join-Path $ProjectRoot 'docs\nvidia-profile-state-capture-model.md'
$policyPath = Join-Path $ProjectRoot 'config\NvidiaProfileStatePolicy.psd1'
$planningPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-production-allowlist-planning.md'
$scopeDesignPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-scope-design.md'
$artifactReviewPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-artifact-provenance-review.md'
$catalogPath = Join-Path $ProjectRoot 'docs\nvidia-path-b-catalog-design.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$reviewPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$matrixPath = Join-Path $ProjectRoot 'docs\final-deferred-tools-readiness-matrix.md'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$intakeRoot = Join-Path $ProjectRoot 'intake\missing-ultimate-scripts\Ultimate'

foreach ($path in @($modelPath, $policyPath, $planningPath, $scopeDesignPath, $artifactReviewPath, $catalogPath, $planPath, $reviewPath, $matrixPath, $stagesPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file was not found: $path"
    }
}
foreach ($path in @($modulesRoot, $sourceRoot, $intakeRoot)) {
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        throw "Required folder was not found: $path"
    }
}

$pathB = @(
    @{
        Title = 'Driver Install Latest'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
        Hash = '41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F'
    }
    @{
        Title = 'Nvidia Settings'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
        Hash = '903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5'
    }
    @{
        Title = 'Hdcp'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/5 Hdcp.ps1'
        Hash = '5C350D28F795D678051E6088F34968DF8D90B3D9024F558C5FAFB2899D1A906A'
    }
    @{
        Title = 'P0 State'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/6 P0 State.ps1'
        Hash = '382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC'
    }
    @{
        Title = 'Msi Mode'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/7 Msi Mode.ps1'
        Hash = '94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7'
    }
)

$modelText = Get-Content -LiteralPath $modelPath -Raw
$planningText = Get-Content -LiteralPath $planningPath -Raw
$scopeText = Get-Content -LiteralPath $scopeDesignPath -Raw
$artifactText = Get-Content -LiteralPath $artifactReviewPath -Raw
$catalogText = Get-Content -LiteralPath $catalogPath -Raw
$planText = Get-Content -LiteralPath $planPath -Raw
$reviewText = Get-Content -LiteralPath $reviewPath -Raw
$matrixText = Get-Content -LiteralPath $matrixPath -Raw

foreach ($section in @(
    '# NVIDIA Profile State Capture Model',
    '## Purpose And Status',
    '## Profile State Concepts',
    '## Required Profile State Metadata',
    '## Capture Model',
    '## Restore Model',
    '## Generated And Imported `.nip` Model',
    '## NVIDIA Profile Inspector Model',
    '## Relationship To Existing Foundations',
    '## Future UI And Runtime Expectations',
    '## Explicit Non-Actions',
    '## Recommended Next Phase'
)) {
    if (-not $modelText.Contains($section)) {
        throw "NVIDIA profile state capture model doc is missing section: $section"
    }
}

foreach ($requiredPhrase in @(
    'This model is documentation and policy only',
    'No NVIDIA profile capture is performed in this phase',
    'No NVIDIA profile restore is performed in this phase',
    'No NVIDIA Profile Inspector execution is approved',
    'No `.nip` import or export is approved',
    'No production profile operation is approved',
    'No runtime behavior changed',
    'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode',
    'Path A: `Driver Install Debloat & Settings`',
    'Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`',
    'prevent accidental mixing'
)) {
    if (-not $modelText.Contains($requiredPhrase)) {
        throw "Model/foundation-only or Path A/B phrase is missing: $requiredPhrase"
    }
}

foreach ($concept in @(
    'NVIDIA profile database/state',
    'Global driver profile',
    'Application-specific profiles',
    'DRS/Profile Inspector managed settings',
    'Generated `.nip` profile files',
    'Imported `.nip` profile files',
    'Exported baseline profile files',
    'Pre-change capture',
    'Post-change verification',
    'Restore candidate',
    'Profile drift',
    'Profile merge conflict',
    'Unsupported profile setting',
    'NVIDIA App compatibility note',
    'Path A / Path B workflow boundary'
)) {
    if (-not $modelText.Contains($concept)) {
        throw "Profile state concept is missing: $concept"
    }
}

foreach ($field in @(
    'CaptureId',
    'ToolId',
    'WorkflowId',
    'WorkflowPathLabel',
    'StepId',
    'StepNumber',
    'SourceScriptPath',
    'SourceChecksum',
    'CaptureTimestamp',
    'CaptureReason',
    'NvidiaDriverVersion',
    'NvidiaGpuVendorDeviceIdentification',
    'ProfileInspectorArtifactIdentity',
    'ProfileInspectorVersion',
    'ProfileInspectorHash',
    'ProfileInspectorSigner',
    'ProfileExportFilePath',
    'ProfileExportSha256',
    'ProfileExportSize',
    'GeneratedImportedNipFilePath',
    'GeneratedImportedNipSha256',
    'ProfileScope',
    'GlobalProfileOrApplicationProfileTarget',
    'SettingIdsOrNames',
    'BeforeStateReference',
    'AfterStateReference',
    'RestoreEligibility',
    'VerificationMethod',
    'RollbackRestoreMethod',
    'FailureBehavior',
    'ActionPlanText',
    'ActivityLogText',
    'LatestResultFields',
    'UserConfirmationLevel',
    'RiskLevel',
    'ApprovalStatus'
)) {
    if (-not $modelText.Contains($field)) {
        throw "Required profile metadata field is missing: $field"
    }
}

foreach ($capturePhrase in @(
    'Capture must happen before any profile import or profile write',
    'Capture must use an approved and verified external tool',
    'API/model',
    'bounded BoostLab state paths',
    'Capture output must be hashed',
    'linked to the exact workflow step and source checksum',
    'driver version and NVIDIA device identity',
    'fail closed if tool/provenance is not approved',
    'must not run from untracked temp paths',
    'must not be mixed across Path A and Path B'
)) {
    if (-not $modelText.Contains($capturePhrase)) {
        throw "Capture model requirement is missing: $capturePhrase"
    }
}

foreach ($restorePhrase in @(
    'Restore must only use a validated prior capture',
    'matching ToolId, WorkflowId, StepId, SourceChecksum',
    'Restore must require explicit user confirmation',
    'Restore must not be confused with Default',
    'Restore Selection UI / Runtime',
    'verify post-restore profile state',
    'log every attempted, skipped, denied, or completed restore',
    'fail closed on missing capture, hash mismatch, identity mismatch'
)) {
    if (-not $modelText.Contains($restorePhrase)) {
        throw "Restore model requirement is missing: $restorePhrase"
    }
}

foreach ($nipPhrase in @(
    'Bounded generated file path',
    'Generated artifact ownership metadata',
    'Source script and step linkage',
    'Content hash',
    'Profile scope',
    'Import target',
    'Provenance of input template if any',
    'Generation method',
    'Cleanup or quarantine policy',
    'Validation before import',
    'Verification after import',
    'Rollback capture before import',
    'No approval in this phase'
)) {
    if (-not $modelText.Contains($nipPhrase)) {
        throw "Generated/imported .nip model requirement is missing: $nipPhrase"
    }
}

foreach ($inspectorPhrase in @(
    'Approved artifact provenance',
    'Immutable source or official/trusted source decision',
    'Pinned version',
    'SHA-256',
    'Signer/publisher validation if available',
    'File size bounds',
    'Bounded install or extraction path',
    'Execution descriptor',
    'Allowed arguments',
    'Expected exit codes',
    'No execution from untracked paths',
    'Preflight checks',
    'Post-operation verification',
    'No approval in this phase'
)) {
    if (-not $modelText.Contains($inspectorPhrase)) {
        throw "NVIDIA Profile Inspector model requirement is missing: $inspectorPhrase"
    }
}

foreach ($foundation in @(
    'Download Provenance and Installer Execution Policy',
    'Production Allowlist Governance',
    'Driver State Capture and Rollback',
    'File/Registry State Capture and Rollback',
    'Restore Selection UI / Runtime',
    'Process Handling Policy',
    'Reboot/Recovery Workflow',
    'NVIDIA Path B Artifact Provenance Review',
    'NVIDIA Path B Production Allowlist Planning',
    'NVIDIA Path B Scope Design'
)) {
    if (-not $modelText.Contains($foundation)) {
        throw "Related foundation is missing: $foundation"
    }
}

foreach ($uiPhrase in @(
    'Action Plan must show profile capture and restore intent',
    'The user must see whether a profile capture exists',
    'The user must see whether Restore is available or denied',
    'Path A and Path B profile state must be separated',
    'Latest Result must include capture id, status, verification, and restore',
    'Activity Log must include profile operation decisions and refusal reasons',
    'UI must show `NotImplemented` / foundation-only status'
)) {
    if (-not $modelText.Contains($uiPhrase)) {
        throw "Future UI/runtime expectation is missing: $uiPhrase"
    }
}

foreach ($nonAction in @(
    'No NVIDIA profile capture was performed',
    'No NVIDIA profile restore was performed',
    'No NVIDIA Profile Inspector execution was approved',
    'No `.nip` import or export was approved',
    'No profile write was approved',
    'No production config, allowlist, artifact, download, installer',
    'No source mirror files were changed',
    'No intake files were changed',
    'No legacy source-ultimate files were changed',
    'No executable module was created',
    'No tool or placeholder was enabled',
    'No runtime behavior changed',
    'No DDU execution, DDU download, or DDU artifact approval was added',
    'Standalone DDU was not introduced',
    'Loudness EQ and NVME Faster Driver remain deleted',
    'Counts remain unchanged'
)) {
    if (-not $modelText.Contains($nonAction)) {
        throw "Explicit non-action boundary is missing: $nonAction"
    }
}

foreach ($linkedText in @($planningText, $scopeText, $artifactText, $catalogText, $planText, $reviewText, $matrixText)) {
    if (-not $linkedText.Contains('docs/nvidia-profile-state-capture-model.md')) {
        throw 'An expected planning document does not link to the NVIDIA profile state capture model.'
    }
}

$profilePolicy = Import-PowerShellDataFile -LiteralPath $policyPath
foreach ($requiredStatus in @('ModelOnly', 'NotImplemented', 'NotApproved', 'Denied', 'Invalid')) {
    if ($profilePolicy.ApprovalStates -notcontains $requiredStatus) {
        throw "NVIDIA profile state policy is missing status: $requiredStatus"
    }
}
foreach ($requiredCollection in @(
    'ProductionProfileScopes',
    'ApprovedProfileOperations',
    'ApprovedProfileInspectorArtifacts',
    'ApprovedNipImports',
    'ApprovedNipExports'
)) {
    if (-not $profilePolicy.ContainsKey($requiredCollection)) {
        throw "NVIDIA profile state policy is missing collection: $requiredCollection"
    }
    if ($profilePolicy[$requiredCollection].Count -ne 0) {
        throw "NVIDIA profile state policy unexpectedly approves entries in: $requiredCollection"
    }
}
foreach ($field in @('CaptureId', 'WorkflowId', 'SourceChecksum', 'ProfileExportSha256', 'RestoreEligibility', 'ApprovalStatus')) {
    if ($profilePolicy.RequiredMetadataFields -notcontains $field) {
        throw "NVIDIA profile state policy is missing required metadata field: $field"
    }
}

$helperPath = Join-Path $ProjectRoot 'core\NvidiaProfileState.psm1'
if (Test-Path -LiteralPath $helperPath -PathType Leaf) {
    $helperText = Get-Content -LiteralPath $helperPath -Raw
    foreach ($forbiddenToken in @(
        'Start-Process',
        'Invoke-WebRequest',
        'iwr ',
        'New-ItemProperty',
        'Set-ItemProperty',
        'Remove-ItemProperty',
        'Get-ItemProperty',
        'Set-Content',
        'Add-Content',
        'Remove-Item',
        'Restart-Computer',
        'Get-Service',
        'Set-Service',
        'Stop-Service',
        'Start-Service'
    )) {
        if ($helperText -match [regex]::Escape($forbiddenToken)) {
            throw "Optional NVIDIA profile state helper contains forbidden operation: $forbiddenToken"
        }
    }
}

foreach ($forbiddenPath in @(
    'config\NvidiaProfileProductionAllowlist.psd1',
    'config\NvidiaProfileScopes.psd1',
    'config\NvidiaProfileImportPolicy.psd1',
    'config\NvidiaProfileExportPolicy.psd1',
    'config\NvidiaProfileInspectorArtifacts.psd1',
    'config\NvidiaPathBWorkflow.psd1',
    'config\NvidiaPathBProductionAllowlist.psd1',
    'config\NvidiaPathBAllowlist.psd1',
    'config\NvidiaPathBScopes.psd1',
    'config\NvidiaPathBArtifactProvenance.psd1',
    'config\NvidiaPathBArtifacts.psd1'
)) {
    if (Test-Path -LiteralPath (Join-Path $ProjectRoot $forbiddenPath)) {
        throw "Production profile/Path B config was unexpectedly created: $forbiddenPath"
    }
}
if (@(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'core') -Filter '*NvidiaPathB*.psm1' -ErrorAction SilentlyContinue).Count -ne 0) {
    throw 'Runtime module was unexpectedly created for NVIDIA Path B.'
}

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })
foreach ($title in @($pathB | Where-Object { $_.Title -notin @('Driver Install Latest', 'Nvidia Settings', 'Hdcp', 'P0 State', 'Msi Mode') } | ForEach-Object { $_.Title })) {
    if (@($allTools | Where-Object { $_.Title -eq $title }).Count -ne 0) {
        throw "Path B source-promoted script was unexpectedly added as an active tool: $title"
    }
}
$driverInstallLatestTool = @($allTools | Where-Object { $_.Title -eq 'Driver Install Latest' })
if ($driverInstallLatestTool.Count -ne 1) {
    throw 'Driver Install Latest must be active exactly once as the Phase 124 source-equivalent Driver Install Latest tool.'
}
$nvidiaSettingsTool = @($allTools | Where-Object { $_.Title -eq 'Nvidia Settings' })
if ($nvidiaSettingsTool.Count -ne 1) {
    throw 'Nvidia Settings must be active exactly once as the Phase 94 controlled manual-handoff tool.'
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
    throw "Expected $($inventoryBaseline.DeferredPlaceholders) deferred/placeholders, found $($placeholderModules.Count)."
}
if (($allTools.Count - $placeholderModules.Count) -ne $inventoryBaseline.ImplementedTools) {
    throw "Expected $($inventoryBaseline.ImplementedTools) implemented tools, found $($allTools.Count - $placeholderModules.Count)."
}

foreach ($moduleName in @('DriverInstallLatest', 'NvidiaSettings', 'P0State', 'MsiMode')) {
    if (@(Get-ChildItem -Path $modulesRoot -Recurse -Filter "$moduleName.psm1").Count -ne 0) {
        throw "Executable module was unexpectedly created for Path B script: $moduleName"
    }
}

foreach ($item in $pathB) {
    foreach ($relative in @($item.Mirror, $item.Intake)) {
        $diskPath = Join-Path $ProjectRoot ($relative -replace '/', '\')
        if (-not (Test-Path -LiteralPath $diskPath -PathType Leaf)) {
            throw "Expected Path B file is missing: $relative"
        }
        $hash = (Get-FileHash -LiteralPath $diskPath -Algorithm SHA256).Hash
        if ($hash -ne $item.Hash) {
            throw "Path B file hash mismatch for $relative. Expected $($item.Hash), found $hash."
        }
    }
}

$sourcePromotedFiles = @(
    Get-ChildItem -LiteralPath (Join-Path $sourceRoot '_intake-promoted\Ultimate') -Recurse -File
)
if ($sourcePromotedFiles.Count -ne $inventoryBaseline.SourcePromotedMirrorFiles) {
    throw "Expected 7 source-promoted intake candidates, found $($sourcePromotedFiles.Count)."
}

if (@($allTools | Where-Object { $_.Title -eq 'DDU' -or $_.Id -eq 'ddu' }).Count -ne 0) {
    throw 'Standalone DDU was reintroduced into active config.'
}
if (@(Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' | Where-Object { $_.BaseName -eq 'ddu' -or $_.Name -like '*DDU*' }).Count -ne 0) {
    throw 'Standalone DDU module was reintroduced.'
}
if (Test-Path -LiteralPath (Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1')) {
    throw 'Loudness EQ source was reintroduced.'
}
if (@(Get-ChildItem -Path $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }).Count -ne 0) {
    throw 'NVME Faster Driver source was reintroduced.'
}

$policyPaths = @(
    'config\ArtifactProvenance.psd1',
    'config\AppxPackagePolicy.psd1',
    'config\CleanupPolicy.psd1',
    'config\DriverStatePolicy.psd1',
    'config\NvidiaProfileStatePolicy.psd1',
    'config\ProcessHandlingPolicy.psd1',
    'config\ProductionAllowlistGovernance.psd1',
    'config\RebootRecoveryPolicy.psd1',
    'config\RollbackPolicy.psd1',
    'config\RestoreSelectionPolicy.psd1',
    'config\SafeModeRecoveryPolicy.psd1',
    'config\ServiceRollbackPolicy.psd1',
    'config\TrustedInstallerPolicy.psd1'
)
foreach ($relativePolicy in $policyPaths) {
    if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $relativePolicy) -PathType Leaf)) {
        throw "Required policy file was not found: $relativePolicy"
    }
}

$artifactPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1')
$appxPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\AppxPackagePolicy.psd1')
$cleanupPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\CleanupPolicy.psd1')
$driverPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\DriverStatePolicy.psd1')
$processPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\ProcessHandlingPolicy.psd1')
$productionPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1')
$rebootPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\RebootRecoveryPolicy.psd1')
$rollbackPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\RollbackPolicy.psd1')
$restorePolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\RestoreSelectionPolicy.psd1')
$safeModePolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\SafeModeRecoveryPolicy.psd1')
$servicePolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\ServiceRollbackPolicy.psd1')
$trustedPolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\TrustedInstallerPolicy.psd1')

if (
    $artifactPolicy.Artifacts.Count -ne 0 -or
    $appxPolicy.PackageScopes.Count -ne 0 -or
    $cleanupPolicy.CleanupScopes.Count -ne 0 -or
    $driverPolicy.DriverScopes.Count -ne 0 -or
    $profilePolicy.ProductionProfileScopes.Count -ne 0 -or
    $profilePolicy.ApprovedProfileOperations.Count -ne 0 -or
    $profilePolicy.ApprovedProfileInspectorArtifacts.Count -ne 0 -or
    $profilePolicy.ApprovedNipImports.Count -ne 0 -or
    $profilePolicy.ApprovedNipExports.Count -ne 0 -or
    $processPolicy.ProcessHandlingScopes.Count -ne 0 -or
    $processPolicy.ApprovedProcessTargets.Count -ne 0 -or
    $productionPolicy.ProductionAllowlistProposals.Count -ne 0 -or
    $rebootPolicy.WorkflowScopes.Count -ne 0 -or
    $rollbackPolicy.FileScopes.Count -ne 0 -or
    $rollbackPolicy.RegistryScopes.Count -ne 0 -or
    $restorePolicy.RestoreSelectionScopes.Count -ne 0 -or
    $restorePolicy.ApprovedRestoreHandlers.Count -ne 0 -or
    $safeModePolicy.SafeModeScopes.Count -ne 0 -or
    $servicePolicy.ServiceScopes.Count -ne 0 -or
    $trustedPolicy.TrustedInstallerScopes.Count -ne 0
) {
    throw 'A production scope, allowlist, artifact, profile operation, workflow, or process target was unexpectedly approved.'
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$legacySourceLines = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
        Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
        ForEach-Object {
            $relative = $_.FullName.Substring($root.Length + 1).Replace('\', '/')
            $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
            "$relative|$hash"
        }
)
$legacySourceHash = Get-BoostLabManifestHash -Lines $legacySourceLines
if ($legacySourceLines.Count -ne 49) {
    throw "Expected 49 legacy source files outside _intake-promoted, found $($legacySourceLines.Count)."
}
if ($legacySourceHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') {
    throw "Legacy source-ultimate manifest outside _intake-promoted changed unexpectedly: $legacySourceHash"
}

[pscustomobject]@{
    Success                       = $true
    PathBOrder                    = 'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
    ActiveToolCount               = $allTools.Count
    ImplementedToolCount          = $allTools.Count - $placeholderModules.Count
    DeferredPlaceholderCount      = $placeholderModules.Count
    SourcePromotedCandidateCount  = $sourcePromotedFiles.Count
    ProductionApprovalsAdded      = $false
    RuntimeBehaviorChanged        = $false
    Message                       = 'NVIDIA profile state capture model is documented and remains non-executing.'
}



