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
        throw 'Unable to determine the Driver Clean controlled intake readiness validator path.'
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

function Test-BoostLabTextContains {
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [string]$Needle,

        [Parameter(Mandatory)]
        [string]$Description
    )

    if (-not $Text.Contains($Needle)) {
        throw "$Description is missing: $Needle"
    }
}

function Get-BoostLabItemCount {
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return 0
    }

    return @($Value).Count
}

$readinessPath = Join-Path $ProjectRoot 'docs\tool-designs\driver-clean-controlled-intake-implementation-readiness.md'
$driverCleanMirrorPath = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate\5 Graphics\1 Driver Clean.ps1'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$intakeRoot = Join-Path $ProjectRoot 'intake\missing-ultimate-scripts\Ultimate'

foreach ($path in @($readinessPath, $driverCleanMirrorPath, $stagesPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file was not found: $path"
    }
}
foreach ($path in @($modulesRoot, $sourceRoot, $intakeRoot)) {
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        throw "Required folder was not found: $path"
    }
}

$expectedDriverCleanHash = 'CF9E1C55ACAFD8A52D2200AC3E6C3AFDF9823837C7B68101C2D4B83E074D325A'
$actualDriverCleanHash = (Get-FileHash -LiteralPath $driverCleanMirrorPath -Algorithm SHA256).Hash
if ($actualDriverCleanHash -ne $expectedDriverCleanHash) {
    throw "Driver Clean mirror hash mismatch. Expected $expectedDriverCleanHash, found $actualDriverCleanHash."
}

$readinessText = Get-Content -LiteralPath $readinessPath -Raw

foreach ($section in @(
    '# Driver Clean Controlled Intake Implementation Readiness',
    '## Scope',
    '## Source Review',
    '## Controlled Exception Boundary',
    '## Implementation Readiness Decision',
    '## Minimum Safe Future Implementation Contract',
    '## Recommended Next Phase',
    '## Roadmap Compression Note',
    '## Relationship To Existing Documents',
    '## Explicit Non-Actions'
)) {
    Test-BoostLabTextContains -Text $readinessText -Needle $section -Description 'Driver Clean readiness section'
}

foreach ($phrase in @(
    'Driver Clean is separate from NVIDIA Path B',
    'one of the seven source-promoted intake scripts',
    'implementation-readiness only',
    'No execution is approved by this document',
    'source-ultimate/_intake-promoted/Ultimate/5 Graphics/1 Driver Clean.ps1',
    $expectedDriverCleanHash,
    'Status: **NeedsArtifactDecision**',
    'Recommended next phase: **Phase 91: Driver Clean Controlled Implementation',
    'Driver Clean first, separate from NVIDIA Path B',
    'Driver Install Latest second',
    'Nvidia Settings third',
    'Hdcp, P0 State, and Msi Mode can be grouped later',
    'BitLocker last or separate',
    'return to the',
    '18 existing deferred/placeholders'
)) {
    Test-BoostLabTextContains -Text $readinessText -Needle $phrase -Description 'Driver Clean readiness required phrase'
}

foreach ($sourceBehavior in @(
    'Requires Administrator',
    'Requires internet',
    '`DDU: Auto`',
    '`DDU: Manual`',
    'Downloads `7zip.exe`',
    'Installs 7-Zip silently',
    'Downloads `ddu.exe`',
    'Extracts `ddu.exe`',
    'Writes a DDU `Settings.xml`',
    'Writes `HKLM\Software\Microsoft\Windows\CurrentVersion\DriverSearching`',
    'Creates a temporary PowerShell script',
    'Writes a RunOnce entry',
    'Uses `bcdedit /set {current} safeboot minimal`',
    'Restarts the system',
    '-CleanSoundBlaster -CleanRealtek -CleanAllGpus -Restart',
    'opens DDU interactively'
)) {
    Test-BoostLabTextContains -Text $readinessText -Needle $sourceBehavior -Description 'Driver Clean source behavior summary'
}

foreach ($boundary in @(
    'Yazan approved Driver Clean intake despite DDU usage',
    'It does not approve standalone DDU',
    'It does not approve DDU downloads',
    'It does not approve DDU artifacts',
    'It does not approve uncontrolled DDU execution',
    'It does not approve reusing DDU elsewhere',
    'Driver Clean-specific and bounded'
)) {
    Test-BoostLabTextContains -Text $readinessText -Needle $boundary -Description 'Driver Clean controlled exception boundary'
}

foreach ($contractItem in @(
    'No silent DDU execution',
    'No automatic DDU download unless separately approved',
    'No bundled DDU artifact unless separately approved',
    'No 7-Zip download or installer execution unless separately approved',
    'Explicit Action Plan',
    'Explicit user confirmation',
    'Source checksum verification',
    'Download provenance and installer execution policy integration',
    'Process handling policy integration',
    'Driver state and recovery warning',
    'Reboot, Safe Mode, RunOnce, and recovery handling',
    'File and registry state capture',
    'Activity Log and Latest Result reporting',
    'No Default or Restore promise unless real captured state exists',
    'Fail closed',
    'No standalone DDU module, card, helper, artifact approval, or reusable DDU'
)) {
    Test-BoostLabTextContains -Text $readinessText -Needle $contractItem -Description 'Minimum future implementation contract'
}

foreach ($nonAction in @(
    'No Driver Clean execution',
    'No DDU execution',
    'No DDU download',
    'No DDU artifact approval',
    'No standalone DDU approval',
    'No uncontrolled DDU execution approval',
    'No 7-Zip artifact approval',
    'No installer execution approval',
    'No generated-script approval',
    'No RunOnce approval',
    'No Safe Mode approval',
    'No reboot approval',
    'No driver-cleaning operation approval',
    'No runtime/tool behavior changed',
    'No tool card or placeholder enabled',
    'No production allowlist config created or changed',
    'No runtime module/helper/tool module created',
    'No WPF/UI runtime file modified',
    'No source mirror files changed',
    'No intake files changed',
    'No legacy source-ultimate files changed',
    'Standalone DDU not introduced',
    'Loudness EQ and NVME Faster Driver remain deleted',
    'Counts unchanged: 48 active tools, 30 implemented tools, 18'
)) {
    Test-BoostLabTextContains -Text $readinessText -Needle $nonAction -Description 'Driver Clean non-action boundary'
}

foreach ($linkedPath in @(
    'docs\final-deferred-tools-readiness-matrix.md',
    'docs\deferred-tools-execution-plan.md',
    'docs\deferred-tool-readiness-review.md'
)) {
    $docText = Get-Content -LiteralPath (Join-Path $ProjectRoot $linkedPath) -Raw
    if (-not $docText.Contains('docs/tool-designs/driver-clean-controlled-intake-implementation-readiness.md')) {
        throw "Expected deferred/readiness document does not link to Driver Clean readiness: $linkedPath"
    }
}

foreach ($forbiddenPath in @(
    'config\DriverCleanPolicy.psd1',
    'config\DriverCleanAllowlist.psd1',
    'config\DduPolicy.psd1',
    'config\DduArtifacts.psd1',
    'config\DriverCleanArtifacts.psd1',
    'config\DriverCleanWorkflow.psd1',
    'config\DriverCleanRuntime.psd1'
)) {
    if (Test-Path -LiteralPath (Join-Path $ProjectRoot $forbiddenPath)) {
        throw "Driver Clean/DDU production config or runtime config was unexpectedly created: $forbiddenPath"
    }
}

if (Get-BoostLabItemCount -Value (Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'core') -Filter '*DriverClean*.psm1' -ErrorAction SilentlyContinue) -ne 0) {
    throw 'Runtime module or executable helper was unexpectedly created for Driver Clean.'
}
if (Get-BoostLabItemCount -Value (Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'core') -Filter '*Ddu*.psm1' -ErrorAction SilentlyContinue) -ne 0) {
    throw 'Runtime module or executable helper was unexpectedly created for DDU.'
}

$uiFilesWithDriverClean = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'ui') -Recurse -File |
        Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw) -match 'Driver Clean|DDU|Display Driver Uninstaller|ddu'
        }
)
if ($uiFilesWithDriverClean.Count -ne 0) {
    throw 'WPF/UI runtime files were unexpectedly modified for Driver Clean or DDU.'
}

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })
$driverCleanTools = @($allTools).Where({ [string]$_['Title'] -eq 'Driver Clean' -or [string]$_['Id'] -eq 'driver-clean' })
if ($driverCleanTools.Count -ne 1) {
    throw 'Driver Clean should be present as the Phase 92 controlled manual-handoff active tool.'
}
$dduTools = @($allTools).Where({ [string]$_['Title'] -eq 'DDU' -or [string]$_['Id'] -eq 'ddu' })
if ($dduTools.Count -ne 0) {
    throw 'Standalone DDU was reintroduced into active config.'
}

$placeholderModules = @(
    Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' |
        Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw).Contains(
                'ToolModule.Placeholder.ps1'
            )
        }
)
if ($allTools.Count -ne 54) {
    throw "Expected 54 active tools, found $($allTools.Count)."
}
if ($placeholderModules.Count -ne 18) {
    throw "Expected 18 deferred/placeholders, found $($placeholderModules.Count)."
}
if (($allTools.Count - $placeholderModules.Count) -ne 36) {
    throw "Expected 36 implemented tools, found $($allTools.Count - $placeholderModules.Count)."
}

if (-not (Test-Path -LiteralPath (Join-Path $modulesRoot 'Graphics\driver-clean.psm1') -PathType Leaf)) {
    throw 'Driver Clean controlled manual-handoff module was not found.'
}
if (Get-BoostLabItemCount -Value (Get-ChildItem -Path $modulesRoot -Recurse -Filter '*DDU*.psm1' -ErrorAction SilentlyContinue) -ne 0) {
    throw 'Standalone DDU module was reintroduced.'
}

$sourcePromotedFiles = @(
    Get-ChildItem -LiteralPath (Join-Path $sourceRoot '_intake-promoted\Ultimate') -Recurse -File
)
if ($sourcePromotedFiles.Count -ne 7) {
    throw "Expected 7 source-promoted intake candidates, found $($sourcePromotedFiles.Count)."
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
    (Get-BoostLabItemCount -Value $artifactPolicy.Artifacts) -ne 0 -or
    (Get-BoostLabItemCount -Value $appxPolicy.PackageScopes) -ne 0 -or
    (Get-BoostLabItemCount -Value $cleanupPolicy.CleanupScopes) -ne 0 -or
    (Get-BoostLabItemCount -Value $driverPolicy.DriverScopes) -ne 0 -or
    (Get-BoostLabItemCount -Value $profilePolicy.ProductionProfileScopes) -ne 0 -or
    (Get-BoostLabItemCount -Value $profilePolicy.ApprovedProfileOperations) -ne 0 -or
    (Get-BoostLabItemCount -Value $profilePolicy.ApprovedProfileInspectorArtifacts) -ne 0 -or
    (Get-BoostLabItemCount -Value $profilePolicy.ApprovedNipImports) -ne 0 -or
    (Get-BoostLabItemCount -Value $profilePolicy.ApprovedNipExports) -ne 0 -or
    (Get-BoostLabItemCount -Value $processPolicy.ProcessHandlingScopes) -ne 0 -or
    (Get-BoostLabItemCount -Value $processPolicy.ApprovedProcessTargets) -ne 0 -or
    (Get-BoostLabItemCount -Value $productionPolicy.ProductionAllowlistProposals) -ne 0 -or
    (Get-BoostLabItemCount -Value $rebootPolicy.WorkflowScopes) -ne 0 -or
    (Get-BoostLabItemCount -Value $rollbackPolicy.FileScopes) -ne 0 -or
    (Get-BoostLabItemCount -Value $rollbackPolicy.RegistryScopes) -ne 0 -or
    (Get-BoostLabItemCount -Value $restorePolicy.RestoreSelectionScopes) -ne 0 -or
    (Get-BoostLabItemCount -Value $restorePolicy.ApprovedRestoreHandlers) -ne 0 -or
    (Get-BoostLabItemCount -Value $safeModePolicy.SafeModeScopes) -ne 0 -or
    (Get-BoostLabItemCount -Value $servicePolicy.ServiceScopes) -ne 0 -or
    (Get-BoostLabItemCount -Value $trustedPolicy.TrustedInstallerScopes) -ne 0
) {
    throw 'A production scope, allowlist, artifact, profile operation, workflow, restore handler, or process target was unexpectedly approved.'
}

if (Test-Path -LiteralPath (Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1')) {
    throw 'Loudness EQ source was reintroduced.'
}
if (Get-BoostLabItemCount -Value (Get-ChildItem -Path $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }) -ne 0) {
    throw 'NVME Faster Driver source was reintroduced.'
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
    ReadinessPath                = $readinessPath
    ReadinessDecision            = 'NeedsArtifactDecision'
    DriverCleanMirrorHash        = $actualDriverCleanHash
    ActiveToolCount              = $allTools.Count
    ImplementedToolCount         = $allTools.Count - $placeholderModules.Count
    DeferredPlaceholderCount     = $placeholderModules.Count
    SourcePromotedCandidateCount = $sourcePromotedFiles.Count
    RuntimeBehaviorChanged       = $false
    ProductionApprovalsAdded     = $false
    Message                      = 'Driver Clean controlled intake implementation readiness is documented and remains non-executing.'
}


