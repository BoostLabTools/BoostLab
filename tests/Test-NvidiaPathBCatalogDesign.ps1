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
        throw 'Unable to determine the NVIDIA Path B catalog design validator path.'
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

$designPath = Join-Path $ProjectRoot 'docs\nvidia-path-b-catalog-design.md'
$decisionPath = Join-Path $ProjectRoot 'docs\missing-scripts-source-promotion-decision.md'
$intakeReviewPath = Join-Path $ProjectRoot 'docs\missing-ultimate-scripts-intake-review.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$reviewPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$matrixPath = Join-Path $ProjectRoot 'docs\final-deferred-tools-readiness-matrix.md'
$optionalConfigPath = Join-Path $ProjectRoot 'config\NvidiaPathBWorkflow.psd1'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$intakeRoot = Join-Path $ProjectRoot 'intake\missing-ultimate-scripts\Ultimate'

foreach ($path in @($designPath, $decisionPath, $intakeReviewPath, $planPath, $reviewPath, $matrixPath, $stagesPath)) {
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
        Step = 1
        Title = 'Driver Install Latest'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
        Hash = '41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F'
        FutureWork = 'scope plus provenance design'
    }
    @{
        Step = 2
        Title = 'Nvidia Settings'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
        Hash = '903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5'
        FutureWork = 'driver/profile/settings design'
    }
    @{
        Step = 3
        Title = 'Hdcp'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/5 Hdcp.ps1'
        Hash = '5C350D28F795D678051E6088F34968DF8D90B3D9024F558C5FAFB2899D1A906A'
        FutureWork = 'NVIDIA display-class registry design'
    }
    @{
        Step = 4
        Title = 'P0 State'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/6 P0 State.ps1'
        Hash = '382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC'
        FutureWork = 'NVIDIA display-class registry design'
    }
    @{
        Step = 5
        Title = 'Msi Mode'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/7 Msi Mode.ps1'
        Hash = '94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7'
        FutureWork = 'NVIDIA-only targeting decision'
    }
)

$designText = Get-Content -LiteralPath $designPath -Raw
$decisionText = Get-Content -LiteralPath $decisionPath -Raw
$intakeReviewText = Get-Content -LiteralPath $intakeReviewPath -Raw
$planText = Get-Content -LiteralPath $planPath -Raw
$reviewText = Get-Content -LiteralPath $reviewPath -Raw
$matrixText = Get-Content -LiteralPath $matrixPath -Raw

foreach ($section in @(
    '# NVIDIA Path B Catalog Design',
    '## Purpose',
    '## Path A vs Path B',
    '## Ordered Path B Catalog',
    '## Required Future Design Work',
    '## Catalog Metadata Design',
    '## UI/UX Guidance',
    '## Related Source-Promoted Scripts Outside Path B',
    '## Non-Actions',
    '## Recommended Next Phase'
)) {
    if (-not $designText.Contains($section)) {
        throw "NVIDIA Path B catalog design is missing section: $section"
    }
}

$requiredOrder = 'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
foreach ($requiredPhrase in @(
    $requiredOrder,
    'Path A: `Driver Install Debloat & Settings`',
    'Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`',
    'mutually guided workflows',
    'warn against and prevent accidental mixing',
    'NVIDIA App features',
    'Not implemented / design pending'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "NVIDIA Path B catalog design is missing required guidance: $requiredPhrase"
    }
}

$previousIndex = -1
foreach ($item in $pathB) {
    $index = $designText.IndexOf($item.Title, [StringComparison]::Ordinal)
    if ($index -lt 0) {
        throw "Path B step missing from design: $($item.Title)"
    }
    if ($index -le $previousIndex) {
        throw "Path B order is not preserved for: $($item.Title)"
    }
    $previousIndex = $index

    foreach ($requiredText in @(
        $item.Title,
        $item.Mirror,
        $item.Intake.Replace('intake/missing-ultimate-scripts/Ultimate/', ''),
        $item.Hash,
        $item.FutureWork,
        'No'
    )) {
        if (-not $designText.Contains($requiredText)) {
            throw "Design is missing expected Path B evidence for $($item.Title): $requiredText"
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

foreach ($metadataField in @(
    'WorkflowId',
    'WorkflowName',
    'WorkflowPathLabel',
    'Stage',
    'StepNumber',
    'StepId',
    'DisplayName',
    'SourceMirrorPath',
    'SourceChecksum',
    'SourceRelativePath',
    'PrerequisiteStep',
    'NextStep',
    'MutuallyExclusiveWorkflowId',
    'TargetGpuVendor',
    'NvidiaAppCompatibilityNote',
    'ExpectedUserIntent',
    'RiskLevel',
    'RequiredFoundationApprovals',
    'RequiredFutureDesignDocument',
    'ImplementationStatus',
    'UIWarningText',
    'ActionPlanRequirements',
    'ActivityLogRequirements',
    'LatestResultExpectations',
    'DefaultRestoreStatus',
    'ProvenanceStatus',
    'ProductionAllowlistStatus'
)) {
    if (-not $designText.Contains($metadataField)) {
        throw "Catalog metadata field is missing: $metadataField"
    }
}

foreach ($requiredPhrase in @(
    'Driver Clean',
    'not one of the five ordered NVIDIA App Path B steps',
    'does not approve standalone DDU',
    'BitLocker',
    'unrelated to NVIDIA Path B',
    'pending future security-sensitive design'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "Related-script boundary is missing: $requiredPhrase"
    }
}

foreach ($requiredPhrase in @(
    'No tools were implemented',
    'No placeholders or tool cards were enabled',
    'No executable modules were created for Path B scripts',
    'No runtime behavior changed',
    'No source mirror files were moved, renamed, or modified',
    'No intake files were moved, renamed, or modified',
    'No production approvals were added',
    'No driver, download, install, profile write',
    'No DDU execution, DDU download, or DDU artifact approval was added',
    'Standalone DDU was not introduced',
    'Loudness EQ and NVME Faster Driver remain deleted',
    'Counts remain unchanged'
)) {
    if (-not $designText.Contains($requiredPhrase)) {
        throw "Non-action boundary is missing: $requiredPhrase"
    }
}

foreach ($linkedText in @($decisionText, $intakeReviewText, $planText, $reviewText, $matrixText)) {
    if (-not $linkedText.Contains('docs/nvidia-path-b-catalog-design.md')) {
        throw 'An expected planning document does not link to the NVIDIA Path B catalog design.'
    }
}

if (Test-Path -LiteralPath $optionalConfigPath -PathType Leaf) {
    $workflow = Import-PowerShellDataFile -LiteralPath $optionalConfigPath
    $statusText = ($workflow | Out-String)
    foreach ($requiredStatus in @('CatalogOnly', 'NotImplemented')) {
        if (-not $statusText.Contains($requiredStatus)) {
            throw "Optional NVIDIA Path B workflow config is not clearly metadata-only: $requiredStatus"
        }
    }
    if ($statusText -match '(?i)Enabled\s*=\s*\$true|Implemented\s*=\s*\$true|Approved\s*=\s*\$true') {
        throw 'Optional NVIDIA Path B workflow config appears to enable runtime behavior.'
    }
}

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })
$pathBTitles = @($pathB | ForEach-Object { $_.Title })
foreach ($title in $pathBTitles) {
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
if ($allTools.Count -ne 48) {
    throw "Expected 48 active tools, found $($allTools.Count)."
}
if ($placeholderModules.Count -ne 18) {
    throw "Expected 18 deferred/placeholders, found $($placeholderModules.Count)."
}
if (($allTools.Count - $placeholderModules.Count) -ne 30) {
    throw "Expected 30 implemented tools, found $($allTools.Count - $placeholderModules.Count)."
}

$forbiddenModuleNames = @(
    'DriverInstallLatest',
    'NvidiaSettings',
    'Hdcp',
    'P0State',
    'MsiMode'
)
foreach ($name in $forbiddenModuleNames) {
    if (@(Get-ChildItem -Path $modulesRoot -Recurse -Filter "$name.psm1").Count -ne 0) {
        throw "Executable module was unexpectedly created for Path B script: $name"
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
    OptionalConfigCreated          = (Test-Path -LiteralPath $optionalConfigPath -PathType Leaf)
    ActiveToolCount               = $allTools.Count
    ImplementedToolCount          = $allTools.Count - $placeholderModules.Count
    DeferredPlaceholderCount      = $placeholderModules.Count
    SourcePromotedCandidateCount  = 7
    ProductionApprovalsAdded      = $false
    RuntimeBehaviorChanged        = $false
    Message                       = 'NVIDIA Path B catalog design is documented and remains non-executing.'
}
