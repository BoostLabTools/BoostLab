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
        throw 'Unable to determine the NVIDIA Path B UI workflow design validator path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

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

$designPath = Join-Path $ProjectRoot 'docs\nvidia-path-b-ui-workflow-design.md'
$profileModelPath = Join-Path $ProjectRoot 'docs\nvidia-profile-state-capture-model.md'
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
$uiRoot = Join-Path $ProjectRoot 'ui'

foreach ($path in @($designPath, $profileModelPath, $planningPath, $scopeDesignPath, $artifactReviewPath, $catalogPath, $planPath, $reviewPath, $matrixPath, $stagesPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file was not found: $path"
    }
}
foreach ($path in @($modulesRoot, $sourceRoot, $intakeRoot, $uiRoot)) {
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        throw "Required folder was not found: $path"
    }
}

$pathB = @(
    @{
        Title = 'Driver Install Latest'
        Section = '### Step 1 - Driver Install Latest'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
        Hash = '41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F'
        Purpose = 'source-defined latest'
    }
    @{
        Title = 'Nvidia Settings'
        Section = '### Step 2 - Nvidia Settings'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
        Hash = '903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5'
        Purpose = 'source-defined NVIDIA settings'
    }
    @{
        Title = 'Hdcp'
        Section = '### Step 3 - Hdcp'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/5 Hdcp.ps1'
        Hash = '5C350D28F795D678051E6088F34968DF8D90B3D9024F558C5FAFB2899D1A906A'
        Purpose = 'HDCP/content-protection'
    }
    @{
        Title = 'P0 State'
        Section = '### Step 4 - P0 State'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/6 P0 State.ps1'
        Hash = '382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC'
        Purpose = 'P0/performance-state'
    }
    @{
        Title = 'Msi Mode'
        Section = '### Step 5 - Msi Mode'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/7 Msi Mode.ps1'
        Hash = '94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7'
        Purpose = 'MSI interrupt registry'
    }
)

$designText = Get-Content -LiteralPath $designPath -Raw
$profileText = Get-Content -LiteralPath $profileModelPath -Raw
$planningText = Get-Content -LiteralPath $planningPath -Raw
$scopeText = Get-Content -LiteralPath $scopeDesignPath -Raw
$artifactText = Get-Content -LiteralPath $artifactReviewPath -Raw
$catalogText = Get-Content -LiteralPath $catalogPath -Raw
$planText = Get-Content -LiteralPath $planPath -Raw
$reviewText = Get-Content -LiteralPath $reviewPath -Raw
$matrixText = Get-Content -LiteralPath $matrixPath -Raw

foreach ($section in @(
    '# NVIDIA Path B UI Workflow Design',
    '## Purpose And Status',
    '## User-Facing Workflow Model',
    '## Path A Vs Path B Decision UX',
    '## Path B Ordered Stepper Design',
    '## Gating And Sequencing Rules',
    '## UI Safety Messaging',
    '## Action Plan / Latest Result / Activity Log Design',
    '## Restore And Default UI Model',
    '## Future Visual And Layout Recommendations',
    '## Relationship To Existing Foundations',
    '## Related Source-Promoted Scripts Outside This Workflow',
    '## Explicit Non-Actions',
    '## Recommended Next Phase'
)) {
    if (-not $designText.Contains($section)) {
        throw "NVIDIA Path B UI workflow design doc is missing section: $section"
    }
}

foreach ($requiredPhrase in @(
    'This is UI workflow design only',
    'No UI implementation was added',
    'No live WPF or runtime behavior changed',
    'No Path B tool cards or placeholders were enabled',
    'Path B remains `NotImplemented` / `DesignPending`',
    'No production approval was added',
    'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode',
    'Path A: `Driver Install Debloat & Settings`',
    'Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`',
    'prevent accidental mixing'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "Design-only or Path A/B phrase is missing: $requiredPhrase"
    }
}

foreach ($workflowConcept in @(
    'NVIDIA Workflow Choice screen/section',
    'Path A card: `Driver Install Debloat & Settings`',
    'Path B card: NVIDIA App compatible path',
    'Path B ordered stepper',
    'Step status states',
    'Prerequisites',
    'Blocked / not implemented state',
    'Warning state',
    'Ready state',
    'Completed state',
    'Failed / refused state',
    'Restore available / restore denied state',
    'Artifact provenance missing state',
    'Profile capture missing state',
    'Reboot required / pending state',
    'Path A / Path B mutual guidance'
)) {
    if (-not $designText.Contains($workflowConcept)) {
        throw "User-facing workflow concept is missing: $workflowConcept"
    }
}

foreach ($decisionPhrase in @(
    'Future UI copy should describe Path A as',
    'Future UI copy should describe Path B as',
    'NVIDIA App compatible workflow',
    'User must intentionally choose Path A or Path B',
    'UI must prevent accidental mixing',
    'Until mixing is approved, Path A and Path B should be mutually guided',
    'an explicit warning and require',
    'explicit confirmation',
    'Path B must not silently call Path A behavior'
)) {
    if (-not $designText.Contains($decisionPhrase)) {
        throw "Path A vs Path B decision UX requirement is missing: $decisionPhrase"
    }
}

foreach ($item in $pathB) {
    foreach ($requiredText in @(
        $item.Title,
        $item.Section,
        $item.Mirror,
        $item.Hash,
        $item.Purpose,
        'DesignPending',
        'Required Action Plan information',
        'Required confirmation level',
        'Expected Latest Result fields',
        'Expected Activity Log fields',
        'Failure behavior',
        'Skip behavior recommendation',
        'Restore/default visibility recommendation'
    )) {
        if (-not $designText.Contains($requiredText)) {
            throw "Path B stepper design is missing expected text for $($item.Title): $requiredText"
        }
    }

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

foreach ($gatingPhrase in @(
    'Step order must be preserved',
    'Later steps should be gated until earlier required steps are completed',
    'If Driver Install Latest fails or is refused',
    'Nvidia Settings must not be enabled until artifact provenance, profile capture',
    'Hdcp, P0 State, and Msi Mode must not be enabled until exact registry',
    'Msi Mode must require NVIDIA-only device targeting',
    'restart disclosure',
    'Path B must not silently call Path A behavior',
    'Path B must not be exposed as five random unordered Graphics tools'
)) {
    if (-not $designText.Contains($gatingPhrase)) {
        throw "Gating/sequencing rule is missing: $gatingPhrase"
    }
}

foreach ($safetyPhrase in @(
    'Downloads/installers',
    'NVIDIA driver mutation',
    'NVIDIA Profile Inspector',
    '`.nip` profile import',
    'HDCP/content protection implications',
    'P0 power/thermal/stability implications',
    'MSI interrupt/device registry implications',
    'Reboot/device restart implications',
    'Default vs Restore distinction',
    'Missing restore capture',
    'Unsupported AMD/Intel GPU-specific behavior'
)) {
    if (-not $designText.Contains($safetyPhrase)) {
        throw "UI safety messaging requirement is missing: $safetyPhrase"
    }
}

foreach ($field in @(
    'WorkflowId',
    'SelectedPath',
    'StepId',
    'StepNumber',
    'SourceChecksum',
    'ApprovalsPresent',
    'ApprovalsMissing',
    'ArtifactProvenanceStatus',
    'DriverProfileCaptureStatus',
    'RegistryFileCaptureStatus',
    'ProcessRebootGatingStatus',
    'UserConfirmationStatus',
    'OperationResult',
    'VerificationResult',
    'RestoreEligibility',
    'RefusalReason',
    'SkipReason',
    'NextRecommendedStep'
)) {
    if (-not $designText.Contains($field)) {
        throw "Action Plan / Latest Result / Activity Log field is missing: $field"
    }
}

foreach ($restorePhrase in @(
    'Default is not Restore',
    'Default means the approved source-defined default behavior',
    'Restore means returning to a captured previous state',
    'Restore requires captured prior state',
    'Restore Selection UI / Runtime',
    'If no capture exists, Restore must be shown as unavailable/denied',
    'For profile operations, Restore depends on NVIDIA Profile State Capture Model',
    'For registry/device settings, Restore depends on File/Registry State Capture',
    'No Restore behavior is approved in this phase'
)) {
    if (-not $designText.Contains($restorePhrase)) {
        throw "Restore vs Default UI model requirement is missing: $restorePhrase"
    }
}

foreach ($visualPhrase in @(
    'Graphics stage could have a NVIDIA workflow selector area',
    'Path A and Path B could be shown as two workflow cards',
    'Path B steps could be shown as an ordered vertical or horizontal stepper',
    '`NotImplemented`',
    '`NeedsProvenance`',
    '`NeedsProfileCapture`',
    '`NeedsRegistryRollback`',
    '`NeedsRebootPolicy`',
    '`Ready`',
    '`Blocked`',
    'Advanced users may later see source/risk details',
    'Beginner users should see clear workflow guidance'
)) {
    if (-not $designText.Contains($visualPhrase)) {
        throw "Future visual/layout recommendation is missing: $visualPhrase"
    }
}

foreach ($foundation in @(
    'NVIDIA Path B Catalog Design',
    'NVIDIA Path B Scope Design',
    'NVIDIA Path B Production Allowlist Planning',
    'NVIDIA Path B Artifact Provenance Review',
    'NVIDIA Profile State Capture Model',
    'Production Allowlist Governance',
    'Download Provenance and Installer Execution Policy',
    'Driver State Capture and Rollback',
    'File/Registry State Capture and Rollback',
    'Restore Selection UI / Runtime',
    'Process Handling Policy',
    'Reboot/Recovery Workflow'
)) {
    if (-not $designText.Contains($foundation)) {
        throw "Related foundation is missing: $foundation"
    }
}

foreach ($outOfScopePhrase in @(
    '`Driver Clean` remains outside the five-step NVIDIA Path B UI workflow',
    'Yazan-approved intake exception despite DDU usage',
    '`BitLocker` is outside NVIDIA Path B',
    'security-sensitive design'
)) {
    if (-not $designText.Contains($outOfScopePhrase)) {
        throw "Out-of-scope boundary is missing: $outOfScopePhrase"
    }
}

foreach ($nonAction in @(
    'No UI implementation was added',
    'No WPF/runtime files were changed for execution',
    'No source mirror files changed',
    'No intake files changed',
    'No legacy source-ultimate files changed',
    'No executable module created',
    'No tool or placeholder enabled',
    'No runtime behavior changed',
    'No production scope, allowlist, artifact, download, installer',
    'No DDU execution, DDU download, or DDU artifact approval was added',
    'Standalone DDU was not introduced',
    'Loudness EQ and NVME Faster Driver remain deleted',
    'Counts remain unchanged'
)) {
    if (-not $designText.Contains($nonAction)) {
        throw "Explicit non-action boundary is missing: $nonAction"
    }
}

foreach ($linkedText in @($profileText, $planningText, $scopeText, $artifactText, $catalogText, $planText, $reviewText, $matrixText)) {
    if (-not $linkedText.Contains('docs/nvidia-path-b-ui-workflow-design.md')) {
        throw 'An expected planning document does not link to the NVIDIA Path B UI workflow design.'
    }
}

foreach ($uiFile in Get-ChildItem -LiteralPath $uiRoot -Recurse -File) {
    $uiText = Get-Content -LiteralPath $uiFile.FullName -Raw
    foreach ($forbiddenUiPhrase in @(
        'Driver Install Latest',
        'Nvidia Settings',
        'Hdcp',
        'P0 State',
        'Msi Mode',
        'NVIDIA App compatible path',
        'nvidia-path-b-ui-workflow'
    )) {
        if ($uiText.Contains($forbiddenUiPhrase)) {
            throw "UI implementation file contains Path B design phrase '$forbiddenUiPhrase': $($uiFile.FullName)"
        }
    }
}

foreach ($forbiddenPath in @(
    'config\NvidiaPathBWorkflow.psd1',
    'config\NvidiaPathBProductionAllowlist.psd1',
    'config\NvidiaPathBAllowlist.psd1',
    'config\NvidiaPathBScopes.psd1',
    'config\NvidiaPathBArtifactProvenance.psd1',
    'config\NvidiaPathBArtifacts.psd1',
    'config\NvidiaPathBUIWorkflow.psd1',
    'config\NvidiaProfileProductionAllowlist.psd1',
    'config\NvidiaProfileScopes.psd1',
    'config\NvidiaProfileImportPolicy.psd1',
    'config\NvidiaProfileExportPolicy.psd1',
    'config\NvidiaProfileInspectorArtifacts.psd1'
)) {
    if (Test-Path -LiteralPath (Join-Path $ProjectRoot $forbiddenPath)) {
        throw "Production profile/Path B runtime config was unexpectedly created: $forbiddenPath"
    }
}
if (@(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'core') -Filter '*NvidiaPathB*.psm1' -ErrorAction SilentlyContinue).Count -ne 0) {
    throw 'Runtime module was unexpectedly created for NVIDIA Path B.'
}

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })
foreach ($title in @($pathB | ForEach-Object { $_.Title })) {
    if (@($allTools | Where-Object { $_.Title -eq $title }).Count -ne 0) {
        throw "Path B source-promoted script was unexpectedly added as an active tool: $title"
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
if ($allTools.Count -ne 49) {
    throw "Expected 49 active tools, found $($allTools.Count)."
}
if ($placeholderModules.Count -ne 18) {
    throw "Expected 18 deferred/placeholders, found $($placeholderModules.Count)."
}
if (($allTools.Count - $placeholderModules.Count) -ne 31) {
    throw "Expected 31 implemented tools, found $($allTools.Count - $placeholderModules.Count)."
}

foreach ($moduleName in @('DriverInstallLatest', 'NvidiaSettings', 'Hdcp', 'P0State', 'MsiMode')) {
    if (@(Get-ChildItem -Path $modulesRoot -Recurse -Filter "$moduleName.psm1").Count -ne 0) {
        throw "Executable module was unexpectedly created for Path B script: $moduleName"
    }
}

$sourcePromotedFiles = @(
    Get-ChildItem -LiteralPath (Join-Path $sourceRoot '_intake-promoted\Ultimate') -Recurse -File
)
if ($sourcePromotedFiles.Count -ne 7) {
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
$profilePolicy = Import-PowerShellDataFile -LiteralPath (Join-Path $ProjectRoot 'config\NvidiaProfileStatePolicy.psd1')
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
    Message                       = 'NVIDIA Path B UI workflow design is documented and remains non-executing.'
}
