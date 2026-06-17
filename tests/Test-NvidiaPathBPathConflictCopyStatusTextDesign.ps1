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
        throw 'Unable to determine the NVIDIA Path B path conflict copy/status text design validator path.'
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

$copyDesignPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-path-conflict-copy-status-text-design.md'
$badgeDesignPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-readiness-badge-design.md'
$runtimeGatingPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-runtime-gating-design.md'
$schemaDesignPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-non-executing-workflow-registry-schema-design.md'
$uiDesignPath = Join-Path $ProjectRoot 'docs\nvidia-path-b-ui-workflow-design.md'
$catalogPath = Join-Path $ProjectRoot 'docs\nvidia-path-b-catalog-design.md'
$matrixPath = Join-Path $ProjectRoot 'docs\final-deferred-tools-readiness-matrix.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$reviewPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$intakeRoot = Join-Path $ProjectRoot 'intake\missing-ultimate-scripts\Ultimate'

foreach ($path in @($copyDesignPath, $badgeDesignPath, $runtimeGatingPath, $schemaDesignPath, $uiDesignPath, $catalogPath, $matrixPath, $planPath, $reviewPath, $stagesPath)) {
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
        ModuleName = 'DriverInstallLatest'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
        Hash = '41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F'
    }
    @{
        Title = 'Nvidia Settings'
        ModuleName = 'NvidiaSettings'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
        Hash = '903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5'
    }
    @{
        Title = 'Hdcp'
        ModuleName = 'Hdcp'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/5 Hdcp.ps1'
        Hash = '5C350D28F795D678051E6088F34968DF8D90B3D9024F558C5FAFB2899D1A906A'
    }
    @{
        Title = 'P0 State'
        ModuleName = 'P0State'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/6 P0 State.ps1'
        Hash = '382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC'
    }
    @{
        Title = 'Msi Mode'
        ModuleName = 'MsiMode'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/7 Msi Mode.ps1'
        Hash = '94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7'
    }
)

$copyText = Get-Content -LiteralPath $copyDesignPath -Raw

foreach ($section in @(
    '# NVIDIA Path B Path Conflict Copy And Status Text Design',
    '## Purpose And Status',
    '## Copy Principles',
    '## Path A Vs Path B Explanatory Copy',
    '## Path Conflict Messages',
    '## Path B Step Status Text',
    '## Disabled Action Text',
    '## Action Plan Precondition Text',
    '## Latest Result And Activity Log Text',
    '## Beginner And Advanced Text Variants',
    '## Localization And Arabic Support Note',
    '## Relationship To Readiness Badges And Runtime Gates',
    '## Explicit Non-Actions',
    '## Recommended Next Phase'
)) {
    if (-not $copyText.Contains($section)) {
        throw "Path conflict copy/status text design is missing section: $section"
    }
}

foreach ($phrase in @(
    'copy means future user-facing UI wording',
    'It does not mean file copying',
    'This is path conflict copy and status text design only',
    'No live UI copy implementation is added',
    'No WPF/UI runtime files are modified',
    'No runtime behavior changes',
    'No tool card or placeholder is enabled',
    'No executable workflow is created',
    'No production approval is granted',
    'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode',
    'Path A: `Driver Install Debloat & Settings`',
    'Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`'
)) {
    if (-not $copyText.Contains($phrase)) {
        throw "Required copy/status design status or path phrase is missing: $phrase"
    }
}

foreach ($principle in @(
    'User-facing text must be clear and non-technical by default',
    'Advanced details may be available in expanded sections',
    'Text must distinguish Path A from Path B',
    'Text must explain that Path B is for NVIDIA App compatibility',
    'Text must not imply execution is available while `NotImplemented`',
    'Text must not hide blockers silently',
    'Text must not use "Ready" unless approvals really exist in a future phase',
    'Restore and Default must be explained separately',
    'Disabled actions must explain why they are disabled',
    'Conflicts must show the selected path and the blocked path',
    'Text must avoid implying AMD/Intel support for NVIDIA-only operations'
)) {
    if (-not $copyText.Contains($principle)) {
        throw "Copy principle is missing: $principle"
    }
}

foreach ($copyItem in @(
    'Future Path A card title',
    'Future Path A card subtitle',
    'Future Path A purpose text',
    'Future Path A warning text',
    'Future Path B card title',
    'Future Path B card subtitle',
    'Future Path B purpose text',
    'Future Path B NVIDIA App compatibility note',
    'Future Path B order explanation',
    'Future Path A/Path B mutual guidance text',
    'Future mixing-prevention text',
    'Future explicit mixing warning text if ever allowed',
    'Current NotImplemented explanation'
)) {
    if (-not $copyText.Contains($copyItem)) {
        throw "Path A vs Path B explanatory copy item is missing: $copyItem"
    }
}

foreach ($case in @(
    'User selected Path A and tries Path B',
    'User selected Path B and tries Path A',
    'Path A appears already applied and Path B is blocked',
    'Path B appears partially applied and Path A is blocked/warned',
    'Path conflict state is unknown or cannot be verified',
    'Mixing is not approved',
    'Mixing is approved in a future phase but requires explicit confirmation',
    'Selected path can be changed only after review',
    'User wants to continue manually despite blocked state'
)) {
    if (-not $copyText.Contains($case)) {
        throw "Path conflict message case is missing: $case"
    }
}
if (-not $copyText.Contains('| Case | Short title | Plain-language body text | Advanced/admin note | Recommended next action | Severity | Blocks execution | Related gate/badge |')) {
    throw 'Path conflict messages table header is missing.'
}

$statusNames = @(
    'NotImplemented',
    'SourcePromoted',
    'DesignOnly',
    'NeedsProvenance',
    'NeedsAllowlist',
    'NeedsApprovalGate',
    'NeedsRuntimeGate',
    'NeedsProfileCapture',
    'NeedsRegistryRollback',
    'NeedsDriverRollback',
    'NeedsProcessPolicy',
    'NeedsRebootPolicy',
    'NeedsNvidiaTargeting',
    'NeedsSecurityReview',
    'PathConflict',
    'RestoreUnavailable',
    'RestoreDenied',
    'DefaultUnavailable',
    'ReadyForReview',
    'ReadyInFuturePhase'
)

foreach ($step in @('Driver Install Latest', 'Nvidia Settings', 'Hdcp', 'P0 State', 'Msi Mode')) {
    $heading = "### $step"
    if (-not $copyText.Contains($heading)) {
        throw "Path B step status text section is missing: $heading"
    }
    $start = $copyText.IndexOf($heading)
    $nextHeading = $copyText.IndexOf('### ', $start + $heading.Length)
    $sectionText = if ($nextHeading -ge 0) {
        $copyText.Substring($start, $nextHeading - $start)
    }
    else {
        $copyText.Substring($start)
    }
    foreach ($statusName in $statusNames) {
        if (-not $sectionText.Contains(('`' + $statusName + '`'))) {
            throw "$heading is missing status text for: $statusName"
        }
    }
}

foreach ($stepSpecific in @(
    'NVIDIA driver download provenance is missing',
    'Installer process handoff is not approved',
    'Driver install may require reboot/session disclosure',
    'NVIDIA Profile Inspector, 7-Zip, `.nip`, and related artifact provenance are missing',
    'NVIDIA profile capture is required before any future profile import',
    'HDCP/content-protection changes require security-sensitive review',
    'P0 behavior can affect power, thermal, fan, battery, and stability',
    'MSI interrupt-mode changes require reboot/device restart disclosure'
)) {
    if (-not $copyText.Contains($stepSpecific)) {
        throw "Step-specific status copy is missing: $stepSpecific"
    }
}

foreach ($disabledAction in @(
    'Analyze disabled',
    'Apply disabled',
    'Default disabled',
    'Restore disabled',
    'Continue disabled',
    'Skip disabled',
    'Open details disabled',
    'Download disabled',
    'Install disabled',
    'Import profile disabled',
    'Restart required but unavailable',
    'Confirmation unavailable'
)) {
    if (-not $copyText.Contains($disabledAction)) {
        throw "Disabled action text is missing: $disabledAction"
    }
}
foreach ($disabledRequirement in @(
    'why disabled',
    'what approval/capture/provenance is missing',
    'what future phase or requirement would unlock it',
    'that no action was performed'
)) {
    if (-not $copyText.Contains($disabledRequirement)) {
        throw "Disabled action requirement is missing: $disabledRequirement"
    }
}

foreach ($precondition in @(
    'Source checksum must match',
    'Production approval must exist',
    'Artifact provenance must exist',
    'Driver/profile/registry capture must exist',
    'NVIDIA-only targeting must be verified',
    'Path A/Path B conflict must be resolved',
    'User confirmation must be explicit',
    'Restore availability must be known',
    'Reboot/session behavior must be disclosed'
)) {
    if (-not $copyText.Contains($precondition)) {
        throw "Action Plan precondition text is missing: $precondition"
    }
}

foreach ($template in @(
    'Gate blocked',
    'Missing approval',
    'Missing provenance',
    'Source checksum mismatch',
    'Path conflict',
    'Not implemented',
    'Skipped by approved design',
    'User refused confirmation',
    'Restore unavailable',
    'Default unavailable',
    'Verification failed',
    'Future completed state',
    'Future failed state'
)) {
    if (-not $copyText.Contains($template)) {
        throw "Latest Result / Activity Log template is missing: $template"
    }
}
if (-not $copyText.Contains('| Event | Status label | Summary | Details | Recommended next action | Structured fields |')) {
    throw 'Latest Result / Activity Log template table header is missing.'
}

foreach ($variant in @(
    '### Path A Vs Path B Choice',
    '### Path Conflict',
    '### Missing Provenance',
    '### Missing Profile Capture',
    '### Missing Registry Rollback',
    '### Missing NVIDIA Targeting',
    '### Restore Unavailable',
    '### NotImplemented',
    'Beginner-friendly variant',
    'Advanced/admin variant'
)) {
    if (-not $copyText.Contains($variant)) {
        throw "Beginner/advanced text variant is missing: $variant"
    }
}

foreach ($localizationPhrase in @(
    'Future UI copy should support localization',
    'Arabic UI text can be added later',
    'this phase does not implement localization files',
    'localization runtime behavior'
)) {
    if (-not $copyText.Contains($localizationPhrase)) {
        throw "Localization / Arabic support note is missing: $localizationPhrase"
    }
}

foreach ($documentPath in @(
    'docs/tool-designs/nvidia-path-b-readiness-badge-design.md',
    'docs/tool-designs/nvidia-path-b-runtime-gating-design.md',
    'docs/nvidia-path-b-ui-workflow-design.md',
    'docs/tool-designs/nvidia-path-b-non-executing-workflow-registry-schema-design.md',
    'docs/tool-designs/nvidia-path-b-production-approval-gate-design.md',
    'docs/tool-designs/nvidia-path-b-draft-allowlist-proposal.md'
)) {
    if (-not $copyText.Contains($documentPath)) {
        throw "Relationship to readiness badges/runtime gates/UI workflow docs is missing: $documentPath"
    }
}

foreach ($nonAction in @(
    'No live UI text implementation added',
    'No localization files added',
    'No active UI config created',
    'No runtime config created',
    'No production config or allowlist config created or changed',
    'No production approval granted',
    'No executable handler/module/action created',
    'No tool or placeholder enabled',
    'No runtime behavior changed',
    'No source mirror files changed',
    'No intake files changed',
    'No legacy source-ultimate files changed',
    'No artifact, download, installer, Profile Inspector, `.nip`, driver',
    'No AppX, service, task, cleanup, TrustedInstaller, or Safe Mode approval',
    'No DDU execution/download/artifact approval added',
    'Standalone DDU not introduced',
    'Loudness EQ and NVME Faster Driver remain deleted',
    'Counts unchanged'
)) {
    if (-not $copyText.Contains($nonAction)) {
        throw "Explicit non-action boundary is missing: $nonAction"
    }
}

foreach ($linkedPath in @($badgeDesignPath, $runtimeGatingPath, $schemaDesignPath, $uiDesignPath, $catalogPath, $matrixPath, $planPath, $reviewPath)) {
    $linkedText = Get-Content -LiteralPath $linkedPath -Raw
    if (-not $linkedText.Contains('docs/tool-designs/nvidia-path-b-path-conflict-copy-status-text-design.md')) {
        throw "Expected document does not link to the NVIDIA Path B path conflict copy/status text design: $linkedPath"
    }
}

foreach ($forbiddenPath in @(
    'config\NvidiaPathBCopyStatusText.psd1',
    'config\NvidiaPathBStatusText.psd1',
    'config\NvidiaPathBLocalization.psd1',
    'config\NvidiaPathBReadinessBadges.psd1',
    'config\NvidiaPathBBadges.psd1',
    'config\NvidiaPathBWorkflowRegistry.psd1',
    'config\NvidiaPathBWorkflow.psd1',
    'config\NvidiaPathBRuntimeGating.psd1',
    'config\NvidiaPathBGates.psd1',
    'config\NvidiaPathBProductionAllowlist.psd1',
    'config\NvidiaPathBAllowlist.psd1',
    'config\NvidiaPathBScopes.psd1',
    'config\NvidiaPathBArtifactProvenance.psd1',
    'config\NvidiaPathBArtifacts.psd1',
    'config\NvidiaPathBDraftAllowlist.psd1',
    'config\NvidiaPathBApprovalGate.psd1',
    'config\NvidiaProfileProductionAllowlist.psd1',
    'config\NvidiaProfileScopes.psd1',
    'config\NvidiaProfileImportPolicy.psd1',
    'config\NvidiaProfileExportPolicy.psd1',
    'config\NvidiaProfileInspectorArtifacts.psd1'
)) {
    if (Test-Path -LiteralPath (Join-Path $ProjectRoot $forbiddenPath)) {
        throw "Active UI, localization, runtime, production, or Path B allowlist config was unexpectedly created: $forbiddenPath"
    }
}

if (@(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'ui') -Recurse -File -Include '*.psd1','*.resx','*.resources','*.json' -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'NvidiaPathB|PathB|Localization|Strings|Arabic|ar-SA' }).Count -ne 0) {
    throw 'Localization runtime files were unexpectedly created for NVIDIA Path B.'
}

if (@(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'core') -Filter '*NvidiaPathB*.psm1' -ErrorAction SilentlyContinue).Count -ne 0) {
    throw 'Runtime module or executable helper was unexpectedly created for NVIDIA Path B.'
}

$uiFilesWithPathB = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'ui') -Recurse -File |
        Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw) -match 'Driver Install Latest|Nvidia Settings|Hdcp|P0 State|Msi Mode|nvidia-path-b|PathConflict|NVIDIA App Compatible'
        }
)
if ($uiFilesWithPathB.Count -ne 0) {
    throw 'WPF/UI runtime files were unexpectedly modified for NVIDIA Path B copy/status text.'
}

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })
foreach ($title in @($pathB | Where-Object { $_.Title -notin @('Driver Install Latest', 'Nvidia Settings', 'Hdcp', 'P0 State') } | ForEach-Object { $_.Title })) {
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
if ($allTools.Count -ne 53) {
    throw "Expected 53 active tools, found $($allTools.Count)."
}
if ($placeholderModules.Count -ne 18) {
    throw "Expected 18 deferred/placeholders, found $($placeholderModules.Count)."
}
if (($allTools.Count - $placeholderModules.Count) -ne 35) {
    throw "Expected 35 implemented tools, found $($allTools.Count - $placeholderModules.Count)."
}

foreach ($moduleName in @($pathB | Where-Object { $_.Title -notin @('Driver Install Latest', 'Nvidia Settings', 'Hdcp', 'P0 State') } | ForEach-Object { $_.ModuleName })) {
    if (@(Get-ChildItem -Path $modulesRoot -Recurse -Filter "$moduleName.psm1").Count -ne 0) {
        throw "Executable tool module was unexpectedly created for Path B script: $moduleName"
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
    throw 'A production scope, allowlist, artifact, profile operation, workflow, restore handler, or process target was unexpectedly approved.'
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
    Success                      = $true
    CopyDesignPath               = $copyDesignPath
    PathBOrder                   = 'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
    ActiveToolCount              = $allTools.Count
    ImplementedToolCount         = $allTools.Count - $placeholderModules.Count
    DeferredPlaceholderCount     = $placeholderModules.Count
    SourcePromotedCandidateCount = $sourcePromotedFiles.Count
    LiveUiCopyImplemented        = $false
    RuntimeBehaviorChanged       = $false
    ProductionApprovalsAdded     = $false
    Message                      = 'NVIDIA Path B path conflict copy/status text design is documented and remains non-executing.'
}



