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
        throw 'Unable to determine the NVIDIA Path B scope design validator path.'
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

$designPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-scope-design.md'
$catalogPath = Join-Path $ProjectRoot 'docs\nvidia-path-b-catalog-design.md'
$decisionPath = Join-Path $ProjectRoot 'docs\missing-scripts-source-promotion-decision.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$reviewPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$matrixPath = Join-Path $ProjectRoot 'docs\final-deferred-tools-readiness-matrix.md'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$intakeRoot = Join-Path $ProjectRoot 'intake\missing-ultimate-scripts\Ultimate'

foreach ($path in @($designPath, $catalogPath, $decisionPath, $planPath, $reviewPath, $matrixPath, $stagesPath)) {
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
        Section = '## Driver Install Latest Scope Design'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
        Hash = '41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F'
        Requirement = 'Scope + provenance design'
    }
    @{
        Title = 'Nvidia Settings'
        Section = '## Nvidia Settings Scope Design'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
        Hash = '903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5'
        Requirement = 'Driver/profile/settings design'
    }
    @{
        Title = 'Hdcp'
        Section = '## Hdcp Scope Design'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/5 Hdcp.ps1'
        Hash = '5C350D28F795D678051E6088F34968DF8D90B3D9024F558C5FAFB2899D1A906A'
        Requirement = 'Driver/profile/settings design'
    }
    @{
        Title = 'P0 State'
        Section = '## P0 State Scope Design'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/6 P0 State.ps1'
        Hash = '382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC'
        Requirement = 'Driver/profile/settings design'
    }
    @{
        Title = 'Msi Mode'
        Section = '## Msi Mode Scope Design'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/7 Msi Mode.ps1'
        Hash = '94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7'
        Requirement = 'Driver/profile/settings design and NVIDIA-only targeting decision'
    }
)

$designText = Get-Content -LiteralPath $designPath -Raw
$catalogText = Get-Content -LiteralPath $catalogPath -Raw
$decisionText = Get-Content -LiteralPath $decisionPath -Raw
$planText = Get-Content -LiteralPath $planPath -Raw
$reviewText = Get-Content -LiteralPath $reviewPath -Raw
$matrixText = Get-Content -LiteralPath $matrixPath -Raw

foreach ($section in @(
    '# NVIDIA Path B Scope Design',
    '## Purpose And Status',
    '## Source Summary Table',
    '## Driver Install Latest Scope Design',
    '## Nvidia Settings Scope Design',
    '## Hdcp Scope Design',
    '## P0 State Scope Design',
    '## Msi Mode Scope Design',
    '## Workflow-Level Constraints',
    '## Required Future Metadata',
    '## Required Future Foundations And Approvals',
    '## Related Source-Promoted Scripts Outside This Scope',
    '## Non-Actions',
    '## Recommended Next Phase'
)) {
    if (-not $designText.Contains($section)) {
        throw "NVIDIA Path B scope design is missing section: $section"
    }
}

$requiredOrder = 'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
foreach ($requiredPhrase in @(
    $requiredOrder,
    'Path A: `Driver Install Debloat & Settings`',
    'Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`',
    'Path A and Path B must be mutually guided workflows',
    'prevent accidental mixing',
    'Failure, refusal, NotApplicable, or cancellation at one Path B step should stop or clearly gate later steps'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "Workflow-level constraint is missing: $requiredPhrase"
    }
}

foreach ($item in $pathB) {
    foreach ($requiredText in @(
        $item.Title,
        $item.Section,
        $item.Mirror,
        $item.Hash,
        $item.Requirement,
        'NotImplemented / ScopeDesignOnly'
    )) {
        if (-not $designText.Contains($requiredText)) {
            throw "Scope design is missing expected text for $($item.Title): $requiredText"
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

foreach ($inventoryPhrase in @(
    'high-level source behavior',
    'Detected command families',
    'Detected registry paths or values',
    'Detected file paths or mutations',
    'Detected downloads/artifacts/installers',
    'Detected external executables/tools',
    'Detected services/tasks/process actions',
    'Detected driver/profile/NVIDIA settings operations',
    'Reboot/session/sign-out implications',
    'Default/Restore implications',
    'Major risk groups',
    'Required future foundations'
)) {
    if (-not $designText.Contains($inventoryPhrase)) {
        throw "Source behavior inventory category is missing: $inventoryPhrase"
    }
}

foreach ($metadataField in @(
    'WorkflowId',
    'StepId',
    'StepNumber',
    'SourceMirrorPath',
    'SourceChecksum',
    'DesignDocumentPath',
    'SourceBehaviorInventory',
    'ProductionScopeReferences',
    'ProvenanceReferences',
    'DriverRollbackReferences',
    'RegistryRollbackReferences',
    'FileRollbackReferences',
    'ProcessPolicyReferences',
    'RebootPolicyReferences',
    'NvidiaOnlyTargetingRule',
    'Prerequisites',
    'MutualExclusionWithPathA',
    'ConfirmationLevel',
    'RiskLevel',
    'DefaultStatus',
    'RestoreStatus',
    'VerificationCommandsOrChecks',
    'FailurePolicy',
    'UIWarningText',
    'ImplementationStatus'
)) {
    if (-not $designText.Contains($metadataField)) {
        throw "Required future metadata field is missing: $metadataField"
    }
}

foreach ($foundation in @(
    'Production Allowlist Governance',
    'Download Provenance and Installer Execution Policy',
    'Driver State Capture and Rollback',
    'File/Registry State Capture and Rollback',
    'Process Handling Policy',
    'Reboot/Recovery Workflow',
    'Restore Selection UI / Runtime',
    'Security-Sensitive Change Approval',
    'future NVIDIA profile/state capture model'
)) {
    if (-not $designText.Contains($foundation)) {
        throw "Required future foundation is missing: $foundation"
    }
}

foreach ($requiredPhrase in @(
    'Driver Clean',
    'not part of the five-step NVIDIA Path B scope design',
    'Yazan-approved intake exception despite DDU usage',
    'BitLocker',
    'not related to NVIDIA Path B',
    'pending future security-sensitive design'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "Out-of-scope boundary is missing: $requiredPhrase"
    }
}

foreach ($requiredPhrase in @(
    'No source mirror files were changed',
    'No intake files were changed',
    'No source-ultimate legacy files were changed',
    'No implementation was added',
    'No executable modules were created for Path B scripts',
    'No placeholders or tool cards were enabled',
    'No runtime behavior changed',
    'No production scopes, allowlists, artifacts, downloads, installers, drivers',
    'No DDU execution, DDU download, or DDU artifact approval was added',
    'Standalone DDU was not introduced',
    'Loudness EQ and NVME Faster Driver remain deleted',
    'Counts remain unchanged'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "Non-action boundary is missing: $requiredPhrase"
    }
}

foreach ($linkedText in @($catalogText, $decisionText, $planText, $reviewText, $matrixText)) {
    if (-not $linkedText.Contains('docs/tool-designs/nvidia-path-b-scope-design.md')) {
        throw 'An expected planning document does not link to the NVIDIA Path B scope design.'
    }
}

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })
foreach ($title in @($pathB | Where-Object { $_.Title -notin @('Driver Install Latest', 'Nvidia Settings') } | ForEach-Object { $_.Title })) {
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
if ($allTools.Count -ne 51) {
    throw "Expected 51 active tools, found $($allTools.Count)."
}
if ($placeholderModules.Count -ne 18) {
    throw "Expected 18 deferred/placeholders, found $($placeholderModules.Count)."
}
if (($allTools.Count - $placeholderModules.Count) -ne 33) {
    throw "Expected 33 implemented tools, found $($allTools.Count - $placeholderModules.Count)."
}

foreach ($moduleName in @('DriverInstallLatest', 'NvidiaSettings', 'Hdcp', 'P0State', 'MsiMode')) {
    if (@(Get-ChildItem -Path $modulesRoot -Recurse -Filter "$moduleName.psm1").Count -ne 0) {
        throw "Executable module was unexpectedly created for Path B script: $moduleName"
    }
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
    throw 'A production scope, allowlist, artifact, workflow, or process target was unexpectedly approved.'
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
    PathBOrder                    = $requiredOrder
    ActiveToolCount               = $allTools.Count
    ImplementedToolCount          = $allTools.Count - $placeholderModules.Count
    DeferredPlaceholderCount      = $placeholderModules.Count
    SourcePromotedCandidateCount  = 7
    ProductionApprovalsAdded      = $false
    RuntimeBehaviorChanged        = $false
    Message                       = 'NVIDIA Path B scope design is documented and remains non-executing.'
}
