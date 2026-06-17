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
        throw 'Unable to determine the missing scripts source-promotion decision validator path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$decisionPath = Join-Path $ProjectRoot 'docs\missing-scripts-source-promotion-decision.md'
$intakeReviewPath = Join-Path $ProjectRoot 'docs\missing-ultimate-scripts-intake-review.md'
$planPath = Join-Path $ProjectRoot 'docs\deferred-tools-execution-plan.md'
$reviewPath = Join-Path $ProjectRoot 'docs\deferred-tool-readiness-review.md'
$matrixPath = Join-Path $ProjectRoot 'docs\final-deferred-tools-readiness-matrix.md'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$intakeRoot = Join-Path $ProjectRoot 'intake\missing-ultimate-scripts\Ultimate'

foreach ($path in @($decisionPath, $intakeReviewPath, $planPath, $reviewPath, $matrixPath, $stagesPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file was not found: $path"
    }
}
if (-not (Test-Path -LiteralPath $intakeRoot -PathType Container)) {
    throw "Intake root was not found: $intakeRoot"
}

$expectedScripts = @(
    @{
        Title = 'Driver Clean'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/1 Driver Clean.ps1'
        SourceMirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/1 Driver Clean.ps1'
        Hash = 'CF9E1C55ACAFD8A52D2200AC3E6C3AFDF9823837C7B68101C2D4B83E074D325A'
    }
    @{
        Title = 'Driver Install Latest'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
        SourceMirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
        Hash = '41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F'
    }
    @{
        Title = 'Nvidia Settings'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
        SourceMirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
        Hash = '903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5'
    }
    @{
        Title = 'Hdcp'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/5 Hdcp.ps1'
        SourceMirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1'
        Hash = '5C350D28F795D678051E6088F34968DF8D90B3D9024F558C5FAFB2899D1A906A'
    }
    @{
        Title = 'P0 State'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/6 P0 State.ps1'
        SourceMirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1'
        Hash = '382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC'
    }
    @{
        Title = 'Msi Mode'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/5 Graphics/7 Msi Mode.ps1'
        SourceMirror = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1'
        Hash = '94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7'
    }
    @{
        Title = 'BitLocker'
        Intake = 'intake/missing-ultimate-scripts/Ultimate/3 Setup/1 BitLocker.ps1'
        SourceMirror = 'source-ultimate/_intake-promoted/Ultimate/3 Setup/1 BitLocker.ps1'
        Hash = '1678E97FB5AFF851F1491A2D96C82A5716B1FA07CB4E3A4A5E0F3FB1B086FBA1'
    }
)

$decisionText = Get-Content -LiteralPath $decisionPath -Raw
$intakeReviewText = Get-Content -LiteralPath $intakeReviewPath -Raw
$planText = Get-Content -LiteralPath $planPath -Raw
$reviewText = Get-Content -LiteralPath $reviewPath -Raw
$matrixText = Get-Content -LiteralPath $matrixPath -Raw
$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })

foreach ($section in @(
    '# Missing Scripts Source Promotion Decision',
    '## Purpose',
    '## Counts',
    '## Phase 72 Mirror Promotion Status',
    '## Promotion Decision Table',
    '## Driver Clean Decision',
    '## NVIDIA App Path B Decision',
    '## BitLocker Decision',
    '## Source-Order Reconciliation Strategy',
    '## Future Promotion Mechanics',
    '## Explicit Non-Actions',
    '## Recommended Next Phase'
)) {
    if (-not $decisionText.Contains($section)) {
        throw "Source-promotion decision is missing section: $section"
    }
}

foreach ($script in $expectedScripts) {
    $intakeDiskPath = Join-Path $ProjectRoot ($script.Intake -replace '/', '\')
    if (-not (Test-Path -LiteralPath $intakeDiskPath -PathType Leaf)) {
        throw "Intake file is missing: $($script.Intake)"
    }
    $actualHash = (Get-FileHash -LiteralPath $intakeDiskPath -Algorithm SHA256).Hash
    if ($actualHash -ne $script.Hash) {
        throw "Intake file hash mismatch for $($script.Intake): $actualHash"
    }

    foreach ($requiredText in @($script.Title, $script.Intake, $script.SourceMirror, $script.Hash)) {
        if (-not $decisionText.Contains($requiredText)) {
            throw "Decision document does not include '$requiredText'."
        }
    }

    $sourceMirrorDiskPath = Join-Path $ProjectRoot ($script.SourceMirror -replace '/', '\')
    if (-not (Test-Path -LiteralPath $sourceMirrorDiskPath -PathType Leaf)) {
        throw "Source-promotion mirror file is missing: $($script.SourceMirror)"
    }
    $mirrorHash = (Get-FileHash -LiteralPath $sourceMirrorDiskPath -Algorithm SHA256).Hash
    if ($mirrorHash -ne $script.Hash) {
        throw "Source-promotion mirror hash mismatch for $($script.SourceMirror): $mirrorHash"
    }
}

foreach ($requiredPhrase in @(
    'Yazan-approved intake exception for future source promotion',
    'does not approve standalone DDU',
    'DDU execution',
    'DDU download',
    'DDU artifact provenance',
    'dedicated Driver Clean scope/provenance/safety design',
    'Standalone DDU was not introduced'
)) {
    if (-not $decisionText.Contains($requiredPhrase)) {
        throw "Driver Clean/DDU decision text is missing: $requiredPhrase"
    }
}

$pathBOrder = @(
    'Driver Install Latest',
    'Nvidia Settings',
    'Hdcp',
    'P0 State',
    'Msi Mode'
)
$previousIndex = -1
foreach ($item in $pathBOrder) {
    $index = $decisionText.IndexOf($item, [StringComparison]::Ordinal)
    if ($index -lt 0) {
        throw "Path B item missing from decision: $item"
    }
    if ($index -le $previousIndex) {
        throw "Path B order is not preserved for: $item"
    }
    $previousIndex = $index
}

foreach ($requiredPhrase in @(
    'Path A: `Driver Install Debloat & Settings`',
    'Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`',
    'mutually guided workflows',
    'prevent accidental workflow mixing',
    'must not be treated as unordered graphics tools'
)) {
    if (-not $decisionText.Contains($requiredPhrase)) {
        throw "Path A / Path B decision text is missing: $requiredPhrase"
    }
}

foreach ($requiredPhrase in @(
    'BitLocker is accepted as a future source-promotion candidate',
    'requires security-sensitive design before implementation',
    'does not approve BitLocker mutation',
    'encryption/decryption',
    'suspend/resume'
)) {
    if (-not $decisionText.Contains($requiredPhrase)) {
        throw "BitLocker decision text is missing: $requiredPhrase"
    }
}

foreach ($requiredPhrase in @(
    'Strategy C',
    'Recommended strategy: **Strategy C**',
    'source-ultimate/_intake-promoted/Ultimate/',
    'minimizes breakage to existing docs/tests',
    'preserves the mandatory NVIDIA Path B order',
    'Phase 72 created that folder and copied the seven source-promoted mirror files with exact hash verification',
    'Existing approved source files outside `_intake-promoted` remain protected by the legacy source manifest validators'
)) {
    if (-not $decisionText.Contains($requiredPhrase)) {
        throw "Source-order reconciliation strategy is missing: $requiredPhrase"
    }
}

foreach ($requiredPhrase in @(
    'legacy source manifest validators continue to protect the original 49-file tree outside `_intake-promoted`',
    'tests/Test-MissingScriptsSourcePromotionMirror.ps1',
    'intake and source-promotion decision validators recognize the mirror as source-reference promotion only',
    'Count handling',
    'Rollback plan if source promotion mapping is wrong',
    'Do not implement or enable any promoted script in the same phase as source promotion',
    'No script is excluded from future source promotion by this decision'
)) {
    if (-not $decisionText.Contains($requiredPhrase)) {
        throw "Future promotion mechanics are missing: $requiredPhrase"
    }
}

foreach ($requiredPhrase in @(
    'Active tools: **53**',
    'Implemented tools: **35**',
    'Deferred/placeholders: **18**',
    'Intake files: **7**',
    'Source-promoted mirror files: **7**',
    'Remaining unimplemented source-promoted intake candidates: **2 separate from official counts**',
    'No existing `source-ultimate` files outside `_intake-promoted` were modified',
    'Seven mirror files were created under `source-ultimate/_intake-promoted/Ultimate/`',
    'No intake files were renamed or moved',
    'No production approval was added',
    'No DDU execution, DDU download, or DDU artifact approval was added',
    'Standalone DDU was not introduced',
    'Loudness EQ and NVME Faster Driver remain deleted'
)) {
    if (-not $decisionText.Contains($requiredPhrase)) {
        throw "Explicit non-action/count text is missing: $requiredPhrase"
    }
}

foreach ($linkedText in @($intakeReviewText, $planText, $reviewText, $matrixText)) {
    if (-not $linkedText.Contains('docs/missing-scripts-source-promotion-decision.md')) {
        throw 'An expected docs file does not link to the source-promotion decision document.'
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
if ($allTools.Count -ne 53) {
    throw "Expected 53 active tools, found $($allTools.Count)."
}
if ($placeholderModules.Count -ne 18) {
    throw "Expected 18 deferred/placeholders, found $($placeholderModules.Count)."
}
if (($allTools.Count - $placeholderModules.Count) -ne 35) {
    throw "Expected 35 implemented tools, found $($allTools.Count - $placeholderModules.Count)."
}

$dduTools = @($allTools | Where-Object { $_.Title -eq 'DDU' -or $_.Id -eq 'ddu' })
if ($dduTools.Count -ne 0) {
    throw 'Standalone DDU was reintroduced into active config.'
}
$dduModules = @(
    Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' |
        Where-Object { $_.BaseName -eq 'ddu' -or $_.Name -like '*DDU*' }
)
if ($dduModules.Count -ne 0) {
    throw 'Standalone DDU module was reintroduced.'
}

$loudnessPath = Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1'
if (Test-Path -LiteralPath $loudnessPath) {
    throw 'Loudness EQ source was reintroduced.'
}
$nvmeMatches = @(
    Get-ChildItem -Path $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }
)
if ($nvmeMatches.Count -ne 0) {
    throw 'NVME Faster Driver source was reintroduced.'
}

$policyPaths = @{
    Artifact            = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
    Appx                = Join-Path $ProjectRoot 'config\AppxPackagePolicy.psd1'
    Cleanup             = Join-Path $ProjectRoot 'config\CleanupPolicy.psd1'
    DriverState         = Join-Path $ProjectRoot 'config\DriverStatePolicy.psd1'
    ProcessHandling     = Join-Path $ProjectRoot 'config\ProcessHandlingPolicy.psd1'
    ProductionAllowlist = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
    RebootRecovery      = Join-Path $ProjectRoot 'config\RebootRecoveryPolicy.psd1'
    Rollback            = Join-Path $ProjectRoot 'config\RollbackPolicy.psd1'
    RestoreSelection    = Join-Path $ProjectRoot 'config\RestoreSelectionPolicy.psd1'
    SafeModeRecovery    = Join-Path $ProjectRoot 'config\SafeModeRecoveryPolicy.psd1'
    ServiceRollback     = Join-Path $ProjectRoot 'config\ServiceRollbackPolicy.psd1'
    TrustedInstaller    = Join-Path $ProjectRoot 'config\TrustedInstallerPolicy.psd1'
}
foreach ($path in $policyPaths.Values) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required policy file was not found: $path"
    }
}

$artifactPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.Artifact
$appxPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.Appx
$cleanupPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.Cleanup
$driverPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.DriverState
$processPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.ProcessHandling
$productionPolicy = Import-PowerShellDataFile -LiteralPath $policyPaths.ProductionAllowlist
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
$sourceFiles = @(
    Get-ChildItem -Path $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
        ForEach-Object {
            $relative = $_.FullName.Substring($root.Length + 1).Replace('\', '/')
            $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
            "$relative|$hash"
        }
)
$sourceManifestHash = [BitConverter]::ToString(
    [Security.Cryptography.SHA256]::Create().ComputeHash(
        [Text.Encoding]::UTF8.GetBytes(($sourceFiles -join "`n"))
    )
).Replace('-', '')

if ($sourceFiles.Count -ne 49) {
    throw "Expected 49 source-ultimate files, found $($sourceFiles.Count)."
}
if ($sourceManifestHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') {
    throw "source-ultimate manifest hash changed unexpectedly: $sourceManifestHash"
}

[pscustomobject]@{
    Success                  = $true
    IntakeCandidateCount     = $expectedScripts.Count
    ActiveToolCount          = $allTools.Count
    ImplementedToolCount     = $allTools.Count - $placeholderModules.Count
    DeferredPlaceholderCount = $placeholderModules.Count
    SourceUltimateUnchanged  = $true
    RecommendedStrategy      = 'Strategy C: source-ultimate/_intake-promoted/Ultimate/ mirror'
    Message                  = 'Missing scripts source-promotion decision is documented and remains non-executing.'
}


