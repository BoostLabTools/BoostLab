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
        throw 'Unable to determine the NVIDIA Path B artifact provenance review validator path.'
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

$provenancePath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-artifact-provenance-review.md'
$planningPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-production-allowlist-planning.md'
$scopeDesignPath = Join-Path $ProjectRoot 'docs\tool-designs\nvidia-path-b-scope-design.md'
$catalogPath = Join-Path $ProjectRoot 'docs\nvidia-path-b-catalog-design.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$reviewPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$matrixPath = Join-Path $ProjectRoot 'docs\final-deferred-tools-readiness-matrix.md'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$intakeRoot = Join-Path $ProjectRoot 'intake\missing-ultimate-scripts\Ultimate'

foreach ($path in @($provenancePath, $planningPath, $scopeDesignPath, $catalogPath, $planPath, $reviewPath, $matrixPath, $stagesPath)) {
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
        Section = '## Driver Install Latest Provenance Review'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
        Hash = '41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F'
        RequiredPhrase = 'Dynamic NVIDIA driver installer URL'
    }
    @{
        Title = 'Nvidia Settings'
        Section = '## Nvidia Settings Provenance Review'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
        Hash = '903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5'
        RequiredPhrase = 'NVIDIA Profile Inspector executable'
    }
    @{
        Title = 'Hdcp'
        Section = '## Hdcp Provenance Review'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/5 Hdcp.ps1'
        Hash = '5C350D28F795D678051E6088F34968DF8D90B3D9024F558C5FAFB2899D1A906A'
        RequiredPhrase = 'No external artifact dependency detected from source text.'
    }
    @{
        Title = 'P0 State'
        Section = '## P0 State Provenance Review'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/6 P0 State.ps1'
        Hash = '382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC'
        RequiredPhrase = 'No external artifact dependency detected from source text.'
    }
    @{
        Title = 'Msi Mode'
        Section = '## Msi Mode Provenance Review'
        Mirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/7 Msi Mode.ps1'
        Hash = '94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7'
        RequiredPhrase = 'No external artifact dependency detected from source text.'
    }
)

$provenanceText = Get-Content -LiteralPath $provenancePath -Raw
$planningText = Get-Content -LiteralPath $planningPath -Raw
$scopeText = Get-Content -LiteralPath $scopeDesignPath -Raw
$catalogText = Get-Content -LiteralPath $catalogPath -Raw
$planText = Get-Content -LiteralPath $planPath -Raw
$reviewText = Get-Content -LiteralPath $reviewPath -Raw
$matrixText = Get-Content -LiteralPath $matrixPath -Raw

foreach ($section in @(
    '# NVIDIA Path B Artifact Provenance Review',
    '## Purpose And Status',
    '## Provenance Status Values',
    '## Source Artifact Inventory',
    '## Driver Install Latest Provenance Review',
    '## Nvidia Settings Provenance Review',
    '## Hdcp Provenance Review',
    '## P0 State Provenance Review',
    '## Msi Mode Provenance Review',
    '## Artifact Approval Requirements',
    '## NVIDIA Profile Inspector And `.nip` Model Requirements',
    '## Generated Artifact And Temporary File Requirements',
    '## Relationship To Existing Foundations',
    '## Explicit Non-Actions',
    '## Recommended Next Phase'
)) {
    if (-not $provenanceText.Contains($section)) {
        throw "NVIDIA Path B artifact provenance review doc is missing section: $section"
    }
}

foreach ($requiredPhrase in @(
    'This is provenance review only',
    'No artifact is approved',
    'No download is approved',
    'No installer execution is approved',
    'No production provenance config was changed',
    'No implementation',
    'placeholder',
    'tool card',
    'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode',
    'Path A: `Driver Install Debloat & Settings`',
    'Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`'
)) {
    if (-not $provenanceText.Contains($requiredPhrase)) {
        throw "Review-only or Path A/B phrase is missing: $requiredPhrase"
    }
}

foreach ($status in @(
    'NotApproved',
    'NeedsOfficialSource',
    'NeedsPinnedVersion',
    'NeedsImmutableURL',
    'NeedsSHA256',
    'NeedsSignerValidation',
    'NeedsSizeBounds',
    'NeedsDestinationBounds',
    'NeedsExtractionPolicy',
    'NeedsInstallerDescriptor',
    'NeedsProfileImportModel',
    'NeedsGeneratedArtifactPolicy',
    'RejectedMutableSource',
    'RejectedUnknownSource'
)) {
    if (-not $provenanceText.Contains($status)) {
        throw "Non-approved provenance status is missing: $status"
    }
}
if ($provenanceText -match '\|\s*Approved\s*\|') {
    throw 'Source artifact inventory contains an Approved status.'
}

foreach ($inventoryPhrase in @(
    '| Step | Script name | Artifact label | Source evidence |',
    'NVIDIA driver lookup API',
    'NVIDIA driver installer',
    'AMD driver web installer branch',
    'Intel driver page branch',
    '7-Zip installer',
    'NVIDIA Profile Inspector executable',
    'Generated NVIDIA Profile Inspector profile',
    'NVIDIA Control Panel launch'
)) {
    if (-not $provenanceText.Contains($inventoryPhrase)) {
        throw "Source artifact inventory is missing: $inventoryPhrase"
    }
}

foreach ($item in $pathB) {
    foreach ($requiredText in @($item.Title, $item.Section, $item.Mirror, $item.Hash, $item.RequiredPhrase)) {
        if ($item.Hash -and -not $provenanceText.Contains($item.Hash)) {
            throw "Provenance document is missing source checksum for $($item.Title): $($item.Hash)"
        }
        if ($requiredText -and $requiredText -ne $item.Hash -and -not $provenanceText.Contains($requiredText)) {
            throw "Provenance document is missing expected text for $($item.Title): $requiredText"
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

foreach ($requiredPhrase in @(
    'https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php',
    'https://international.download.nvidia.com/Windows/$version/$version-desktop-$windowsVersion-$windowsArchitecture-international-dch-whql.exe',
    '%SystemRoot%\Temp\nvidiadriver.exe',
    'dynamic latest-driver flow',
    'pinned driver version or an approved dynamic-provenance policy'
)) {
    if (-not $provenanceText.Contains($requiredPhrase)) {
        throw "Driver Install Latest provenance detail is missing: $requiredPhrase"
    }
}

foreach ($requiredPhrase in @(
    'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe',
    'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/inspector.exe',
    '%SystemRoot%\Temp\inspector.nip',
    'mutable branch URLs',
    'generated artifact ownership',
    'profile state capture before import',
    'rollback/restoration design'
)) {
    if (-not $provenanceText.Contains($requiredPhrase)) {
        throw "Nvidia Settings provenance detail is missing: $requiredPhrase"
    }
}

foreach ($requiredPhrase in @(
    'immutable source URL or official source mechanism',
    'pinned version',
    'SHA-256',
    'signer/publisher validation',
    'file size bounds',
    'destination path bounds',
    'extraction destination bounds',
    'installer descriptor',
    'expected exit codes',
    'rollback/recovery/handoff plan'
)) {
    if (-not $provenanceText.Contains($requiredPhrase)) {
        throw "Artifact approval requirement is missing: $requiredPhrase"
    }
}

foreach ($requiredPhrase in @(
    'approved Inspector provenance',
    'approved profile file provenance or generated profile ownership',
    'profile state capture before import',
    'verification after profile import',
    'The generated `.nip` content must be treated as a generated artifact'
)) {
    if (-not $provenanceText.Contains($requiredPhrase)) {
        throw "NVIDIA Profile Inspector/.nip requirement is missing: $requiredPhrase"
    }
}

foreach ($requiredPhrase in @(
    'generated ownership metadata',
    'bounded temporary directory',
    'cleanup policy',
    'quarantine/retention rule',
    'no broad temp cleanup',
    'no execution from untracked paths'
)) {
    if (-not $provenanceText.Contains($requiredPhrase)) {
        throw "Generated artifact/temp file requirement is missing: $requiredPhrase"
    }
}

foreach ($foundation in @(
    'Download Provenance and Installer Execution Policy',
    'Production Allowlist Governance',
    'Driver State Capture and Rollback',
    'File/Registry State Capture and Rollback',
    'Process Handling Policy',
    'Reboot/Recovery Workflow',
    'Restore Selection UI / Runtime',
    'NVIDIA Path B Production Allowlist Planning'
)) {
    if (-not $provenanceText.Contains($foundation)) {
        throw "Related foundation is missing: $foundation"
    }
}

foreach ($requiredPhrase in @(
    'No source mirror files were changed',
    'No intake files were changed',
    'No legacy source-ultimate files were changed',
    'No executable module was created',
    'No tool or placeholder was enabled',
    'No runtime behavior changed',
    'No production provenance config was changed',
    'No production allowlist, scope, artifact, download, installer',
    'No production config or artifact approval config was created for Path B',
    'No DDU execution, DDU download, or DDU artifact approval was added',
    'Standalone DDU was not introduced',
    'Loudness EQ and NVME Faster Driver remain deleted',
    'Counts remain unchanged'
)) {
    if (-not $provenanceText.Contains($requiredPhrase)) {
        throw "Explicit non-action boundary is missing: $requiredPhrase"
    }
}

if (-not $provenanceText.Contains('Recommended next phase: **NVIDIA Profile State Capture Model**')) {
    throw 'Recommended next phase is missing or incorrect.'
}

foreach ($linkedText in @($planningText, $scopeText, $catalogText, $planText, $reviewText, $matrixText)) {
    if (-not $linkedText.Contains('docs/tool-designs/nvidia-path-b-artifact-provenance-review.md')) {
        throw 'An expected planning document does not link to the NVIDIA Path B artifact provenance review doc.'
    }
}

foreach ($forbiddenPath in @(
    'config\NvidiaPathBWorkflow.psd1',
    'config\NvidiaPathBProductionAllowlist.psd1',
    'config\NvidiaPathBAllowlist.psd1',
    'config\NvidiaPathBScopes.psd1',
    'config\NvidiaPathBArtifactProvenance.psd1',
    'config\NvidiaPathBArtifacts.psd1'
)) {
    if (Test-Path -LiteralPath (Join-Path $ProjectRoot $forbiddenPath)) {
        throw "Path B production/runtime/provenance config was unexpectedly created: $forbiddenPath"
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
if ($placeholderModules.Count -ne 16) {
    throw "Expected 16 deferred/placeholders, found $($placeholderModules.Count)."
}
if (($allTools.Count - $placeholderModules.Count) -ne 39) {
    throw "Expected 39 implemented tools, found $($allTools.Count - $placeholderModules.Count)."
}

foreach ($moduleName in @('DriverInstallLatest', 'NvidiaSettings', 'P0State', 'MsiMode')) {
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
    PathBOrder                    = 'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
    ActiveToolCount               = $allTools.Count
    ImplementedToolCount          = $allTools.Count - $placeholderModules.Count
    DeferredPlaceholderCount      = $placeholderModules.Count
    SourcePromotedCandidateCount  = 7
    ProductionApprovalsAdded      = $false
    RuntimeBehaviorChanged        = $false
    Message                       = 'NVIDIA Path B artifact provenance review is documented and remains non-executing.'
}




