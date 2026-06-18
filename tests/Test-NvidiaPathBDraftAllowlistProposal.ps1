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
        throw 'Unable to determine the NVIDIA Path B draft allowlist proposal validator path.'
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

$proposalPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-draft-allowlist-proposal.md'
$planningPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-production-allowlist-planning.md'
$scopeDesignPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-scope-design.md'
$artifactReviewPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-artifact-provenance-review.md'
$profileModelPath = Join-Path $ProjectRoot 'docs\nvidia-profile-state-capture-model.md'
$uiDesignPath = Join-Path $ProjectRoot 'docs\nvidia-path-b-ui-workflow-design.md'
$catalogPath = Join-Path $ProjectRoot 'docs\nvidia-path-b-catalog-design.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$reviewPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$matrixPath = Join-Path $ProjectRoot 'docs\final-deferred-tools-readiness-matrix.md'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$intakeRoot = Join-Path $ProjectRoot 'intake\missing-ultimate-scripts\Ultimate'

foreach ($path in @($proposalPath, $planningPath, $scopeDesignPath, $artifactReviewPath, $profileModelPath, $uiDesignPath, $catalogPath, $planPath, $reviewPath, $matrixPath, $stagesPath)) {
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

$proposalText = Get-Content -LiteralPath $proposalPath -Raw
$planningText = Get-Content -LiteralPath $planningPath -Raw
$scopeText = Get-Content -LiteralPath $scopeDesignPath -Raw
$artifactText = Get-Content -LiteralPath $artifactReviewPath -Raw
$profileText = Get-Content -LiteralPath $profileModelPath -Raw
$uiText = Get-Content -LiteralPath $uiDesignPath -Raw
$catalogText = Get-Content -LiteralPath $catalogPath -Raw
$planText = Get-Content -LiteralPath $planPath -Raw
$reviewText = Get-Content -LiteralPath $reviewPath -Raw
$matrixText = Get-Content -LiteralPath $matrixPath -Raw

foreach ($section in @(
    '# NVIDIA Path B Draft Allowlist Proposal',
    '## Purpose And Status',
    '## Draft Proposal Rules',
    '## Consolidated Draft Allowlist Table',
    '## Driver Install Latest Draft Proposal',
    '## Nvidia Settings Draft Proposal',
    '## Hdcp Draft Proposal',
    '## P0 State Draft Proposal',
    '## Msi Mode Draft Proposal',
    '## Rejected Draft Examples',
    '## Future Promotion Path',
    '## Relationship To Existing Documents',
    '## Explicit Non-Actions',
    '## Recommended Next Phase'
)) {
    if (-not $proposalText.Contains($section)) {
        throw "NVIDIA Path B draft allowlist proposal is missing section: $section"
    }
}

foreach ($requiredPhrase in @(
    'This is a draft allowlist proposal only',
    'No production allowlist is approved',
    'No production scope is approved',
    'No artifact, download, installer, driver/profile write, registry write, file mutation, process, reboot, Default, or Restore',
    'No implementation, placeholder, tool card, or runtime behavior change was added',
    'Every proposed entry',
    'non-production',
    'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode',
    'Path A: `Driver Install Debloat & Settings`',
    'Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`'
)) {
    if (-not $proposalText.Contains($requiredPhrase)) {
        throw "Draft-only or Path A/B phrase is missing: $requiredPhrase"
    }
}

foreach ($status in @(
    'DraftOnly',
    'NotApproved',
    'NeedsApproval',
    'NeedsProvenance',
    'NeedsInstallerDescriptor',
    'NeedsDriverRollback',
    'NeedsProfileStateModel',
    'NeedsRegistryRollback',
    'NeedsProcessPolicy',
    'NeedsRebootPolicy',
    'NeedsSecurityReview',
    'NeedsNvidiaOnlyTargeting',
    'RejectedBroadScope',
    'RejectedMutableSource',
    'RejectedUnknownTarget'
)) {
    if (-not $proposalText.Contains($status)) {
        throw "Allowed draft status is missing: $status"
    }
}
if ($proposalText -match '\|\s*Approved\s*\|') {
    throw 'Consolidated draft allowlist table contains an Approved status.'
}

foreach ($tablePhrase in @(
    '| Draft id | Path B step number | Script name | Scope type | Candidate target |',
    'NPB-DRAFT-001',
    'NPB-DRAFT-030',
    'Candidate target',
    'Candidate operation',
    'Source evidence',
    'Required foundation',
    'Required future approval',
    'Reason not approved now',
    'Future validation requirement',
    'Implementation dependency'
)) {
    if (-not $proposalText.Contains($tablePhrase)) {
        throw "Consolidated draft allowlist table content is missing: $tablePhrase"
    }
}

foreach ($driverPhrase in @(
    'NVIDIA driver source/provenance mechanism',
    'Downloaded driver artifact path and metadata',
    'Installer execution descriptor',
    'Driver state capture/rollback dependency',
    'Process handoff dependency',
    'Reboot/session dependency',
    'Verification checks',
    'NPB-DRAFT-001',
    'NPB-DRAFT-007'
)) {
    if (-not $proposalText.Contains($driverPhrase)) {
        throw "Driver Install Latest draft proposal is missing: $driverPhrase"
    }
}

foreach ($settingsPhrase in @(
    '7-Zip/archive handling',
    'NVIDIA Profile Inspector artifact and execution descriptor',
    'Generated `.nip` ownership and bounded path',
    'Profile import operation',
    'NVIDIA registry/file settings',
    'NVIDIA Control Panel launch',
    'Profile state capture dependency',
    'NPB-DRAFT-008',
    'NPB-DRAFT-021'
)) {
    if (-not $proposalText.Contains($settingsPhrase)) {
        throw "Nvidia Settings draft proposal is missing: $settingsPhrase"
    }
}

foreach ($registryPhrase in @(
    'RMHdcpKeyglobZero',
    'DisableDynamicPstate',
    'MSISupported',
    'NVIDIA-only target constraint',
    'Registry capture/rollback dependency',
    'Content-protection/security review dependency',
    'Power/thermal/stability warning dependency',
    'Display device instance discovery constraint',
    'Reboot/device restart disclosure dependency'
)) {
    if (-not $proposalText.Contains($registryPhrase)) {
        throw "Registry/device draft proposal is missing: $registryPhrase"
    }
}

foreach ($rejectedPhrase in @(
    'Wildcard registry paths',
    'All display devices without NVIDIA identity validation',
    'Mutable branch URLs',
    'Versionless external executable downloads',
    'Executing tools from untracked temp paths',
    'Broad process termination',
    'Broad installer execution',
    'Profile import without pre-capture',
    'Registry write without rollback capture',
    'Path A/Path B mixed execution without explicit design approval'
)) {
    if (-not $proposalText.Contains($rejectedPhrase)) {
        throw "Rejected broad/unsafe example is missing: $rejectedPhrase"
    }
}

foreach ($promotionPhrase in @(
    'Source evidence confirmed',
    'Exact target approved under Production Allowlist Governance',
    'Artifact provenance approved if applicable',
    'Installer descriptor approved if applicable',
    'Profile state capture/restore approved if applicable',
    'Registry/driver rollback approved if applicable',
    'Process/reboot policy approved if applicable',
    'UI Action Plan and confirmation text approved',
    'Verification validator added',
    'Production config updated in a separate phase only'
)) {
    if (-not $proposalText.Contains($promotionPhrase)) {
        throw "Future promotion path requirement is missing: $promotionPhrase"
    }
}

foreach ($foundation in @(
    'NVIDIA Path B Catalog Design',
    'NVIDIA Path B Scope Design',
    'NVIDIA Path B Production Allowlist Planning',
    'NVIDIA Path B Artifact Provenance Review',
    'NVIDIA Profile State Capture Model',
    'NVIDIA Path B UI Workflow Design',
    'Production Allowlist Governance',
    'Download Provenance and Installer Execution Policy',
    'Driver State Capture and Rollback',
    'File/Registry State Capture and Rollback',
    'Process Handling Policy',
    'Reboot/Recovery Workflow',
    'Restore Selection UI / Runtime'
)) {
    if (-not $proposalText.Contains($foundation)) {
        throw "Related document/foundation is missing: $foundation"
    }
}

foreach ($nonAction in @(
    'No production allowlist config was created or changed',
    'No production scope was approved',
    'No artifact, download, installer, driver, profile write',
    'No source mirror files changed',
    'No intake files changed',
    'No legacy source-ultimate files changed',
    'No executable module created',
    'No tool or placeholder enabled',
    'No runtime behavior changed',
    'No DDU execution, DDU download, or DDU artifact approval was added',
    'Standalone DDU was not introduced',
    'Loudness EQ and NVME Faster Driver remain deleted',
    'Counts remain unchanged'
)) {
    if (-not $proposalText.Contains($nonAction)) {
        throw "Explicit non-action boundary is missing: $nonAction"
    }
}

foreach ($linkedText in @($planningText, $scopeText, $artifactText, $profileText, $uiText, $catalogText, $planText, $reviewText, $matrixText)) {
    if (-not $linkedText.Contains('docs/tool-designs/nvidia-path-b-draft-allowlist-proposal.md')) {
        throw 'An expected planning document does not link to the NVIDIA Path B draft allowlist proposal.'
    }
}

foreach ($forbiddenPath in @(
    'config\NvidiaPathBWorkflow.psd1',
    'config\NvidiaPathBProductionAllowlist.psd1',
    'config\NvidiaPathBAllowlist.psd1',
    'config\NvidiaPathBScopes.psd1',
    'config\NvidiaPathBArtifactProvenance.psd1',
    'config\NvidiaPathBArtifacts.psd1',
    'config\NvidiaPathBDraftAllowlist.psd1',
    'config\NvidiaProfileProductionAllowlist.psd1',
    'config\NvidiaProfileScopes.psd1',
    'config\NvidiaProfileImportPolicy.psd1',
    'config\NvidiaProfileExportPolicy.psd1',
    'config\NvidiaProfileInspectorArtifacts.psd1'
)) {
    if (Test-Path -LiteralPath (Join-Path $ProjectRoot $forbiddenPath)) {
        throw "Production/Path B allowlist config was unexpectedly created: $forbiddenPath"
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
    throw 'Driver Install Latest must be active exactly once as the Phase 93 controlled manual-handoff tool.'
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
if ($allTools.Count -ne 55) {
    throw "Expected 55 active tools, found $($allTools.Count)."
}
if ($placeholderModules.Count -ne 18) {
    throw "Expected 18 deferred/placeholders, found $($placeholderModules.Count)."
}
if (($allTools.Count - $placeholderModules.Count) -ne 37) {
    throw "Expected 37 implemented tools, found $($allTools.Count - $placeholderModules.Count)."
}

foreach ($moduleName in @('DriverInstallLatest', 'NvidiaSettings', 'P0State', 'MsiMode')) {
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
    Message                       = 'NVIDIA Path B draft allowlist proposal is documented and remains non-executing.'
}




