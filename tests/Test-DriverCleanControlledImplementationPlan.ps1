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
        throw 'Unable to determine the Driver Clean controlled implementation plan validator path.'
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

$planPath = Join-Path $ProjectRoot 'docs\tool-designs\driver-clean-controlled-implementation-plan.md'
$driverCleanMirrorPath = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate\5 Graphics\1 Driver Clean.ps1'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$intakeRoot = Join-Path $ProjectRoot 'intake\missing-ultimate-scripts\Ultimate'

foreach ($path in @($planPath, $driverCleanMirrorPath, $stagesPath)) {
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

$planText = Get-Content -LiteralPath $planPath -Raw

foreach ($section in @(
    '# Driver Clean Controlled Implementation Plan',
    '## Purpose And Status',
    '## Source And Checksum Binding',
    '## Implementation Strategy Decision',
    '## Manual Handoff Future Plan',
    '## Auto Mode Future Blocker List',
    '## Driver Clean Future Implementation Contract',
    '## Risk And Recovery Handling Plan',
    '## Future UI/Action Model',
    '## Validation Plan For Future Implementation',
    '## Recommended Next Phase',
    '## Roadmap Compression Note',
    '## Relationship To Existing Documents',
    '## Explicit Non-Actions'
)) {
    Test-BoostLabTextContains -Text $planText -Needle $section -Description 'Driver Clean controlled implementation plan section'
}

foreach ($phrase in @(
    'Driver Clean controlled implementation plan only',
    'No Driver Clean implementation is added in this phase',
    'No execution is approved',
    'No DDU download or DDU artifact is approved',
    'No 7-Zip download or 7-Zip artifact is approved',
    'No standalone DDU is approved',
    'No runtime/tool behavior changes',
    'Driver Clean remains outside NVIDIA Path B',
    'Path B steps must not be merged into one script, one tool, or one combined',
    'Users who do not want NVIDIA App use `Driver Install Debloat & Settings`',
    'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode',
    'Driver Clean remains separate from both',
    'source-ultimate/_intake-promoted/Ultimate/5 Graphics/1 Driver Clean.ps1',
    $expectedDriverCleanHash,
    'source mirror is reference-only and must not be modified'
)) {
    Test-BoostLabTextContains -Text $planText -Needle $phrase -Description 'Driver Clean implementation plan required phrase'
}

foreach ($strategy in @(
    'Primary strategy: **ManualHandoffFirst**',
    'Auto mode status: **AutoBlockedUntilArtifactApproval**',
    'ManualHandoffFirst is the safest bounded future path',
    'Auto remains blocked',
    'This does not weaken Ultimate behavior as a final implementation'
)) {
    Test-BoostLabTextContains -Text $planText -Needle $strategy -Description 'Implementation strategy decision'
}

foreach ($manualPlan in @(
    'User sees an Action Plan',
    'User confirms understanding',
    'BoostLab verifies the Driver Clean source checksum',
    'BoostLab does not download DDU unless separately approved',
    'BoostLab does not download 7-Zip unless separately approved',
    'BoostLab does not run DDU silently',
    'BoostLab does not install 7-Zip silently',
    'BoostLab does not create RunOnce entries',
    'BoostLab does not switch into Safe Mode',
    'BoostLab does not reboot',
    'may only guide the user or open an approved location/tool',
    'logs that no automated DDU execution occurred',
    'warned about Safe Mode, reboot, driver cleanup',
    'No Default or Restore promise is made without captured state',
    'Manual handoff is still not implemented in this phase'
)) {
    Test-BoostLabTextContains -Text $planText -Needle $manualPlan -Description 'Manual handoff future plan'
}

foreach ($blocker in @(
    'DDU artifact provenance is approved',
    '7-Zip artifact provenance is approved if used',
    'Download URLs and hashes are approved',
    'Installer/extractor behavior is approved',
    'Process handling is approved',
    'Safe Mode handling is approved',
    'RunOnce handling is approved',
    '`bcdedit` handling is approved',
    'Reboot/recovery handling is approved',
    'Generated script handling is approved',
    'Driver state and rollback limitations are documented',
    'Explicit user confirmation is implemented',
    'Validators prove fail-closed behavior',
    'Until those approvals exist, Auto must remain blocked'
)) {
    Test-BoostLabTextContains -Text $planText -Needle $blocker -Description 'Auto mode blocker'
}

foreach ($contractItem in @(
    'Source checksum verification',
    'Explicit Action Plan',
    'Explicit user confirmation',
    'No silent execution',
    'No hidden download',
    'No uncontrolled process start',
    'No uncontrolled Safe Mode switch',
    'No uncontrolled RunOnce creation',
    'No uncontrolled reboot',
    'No Default or Restore unless real captured state exists',
    'Latest Result and Activity Log reporting',
    'Fail closed on missing artifact, process, reboot, or recovery approvals',
    'Driver Clean-specific DDU boundary only',
    'No standalone DDU reuse',
    'No DDU approval outside Driver Clean',
    'No 7-Zip approval outside Driver Clean',
    'No Path B merge or combined NVIDIA action'
)) {
    Test-BoostLabTextContains -Text $planText -Needle $contractItem -Description 'Future implementation contract'
}

foreach ($risk in @(
    'Safe Mode risk',
    'Reboot risk',
    'Driver removal risk',
    'Black screen/display risk',
    'Network loss risk',
    'Failed cleanup risk',
    'User cancellation',
    'Partial completion',
    'Restore point/recovery guidance',
    'Restore limits'
)) {
    Test-BoostLabTextContains -Text $planText -Needle $risk -Description 'Risk and recovery handling plan'
}

foreach ($actionState in @(
    '`Analyze`',
    '`Prepare Manual Handoff`',
    '`Apply Auto`',
    '`Open Instructions`',
    '`Cancel`',
    '`Restore`',
    '`Default`',
    '`Apply Auto` must remain blocked',
    '`Restore` must remain unavailable unless captured state exists',
    '`Default` must not be confused with Restore',
    'No live UI changes are added in this phase'
)) {
    Test-BoostLabTextContains -Text $planText -Needle $actionState -Description 'Future UI/action model'
}

foreach ($validation in @(
    'No DDU execution during tests',
    'No downloads during tests',
    'No 7-Zip execution during tests',
    'Source checksum verification',
    'Process policy dry-run or mocked behavior',
    'Reboot/Safe Mode dry-run or mocked behavior',
    'RunOnce dry-run or mocked behavior',
    'Generated-script dry-run or mocked behavior',
    'No production allowlist entry without approval',
    'No artifact provenance entry without explicit approval',
    'No standalone DDU introduced',
    'Deleted tools remain deleted',
    'Auto fails closed'
)) {
    Test-BoostLabTextContains -Text $planText -Needle $validation -Description 'Future validation plan'
}

foreach ($roadmap in @(
    'Driver Clean first and separate',
    'Driver Install Latest second',
    'Nvidia Settings third',
    'Hdcp, P0 State, and Msi Mode',
    'BitLocker remains separate and security-sensitive',
    'return to the',
    '18 existing deferred/placeholders'
)) {
    Test-BoostLabTextContains -Text $planText -Needle $roadmap -Description 'Roadmap compression note'
}

Test-BoostLabTextContains -Text $planText -Needle 'Recommended next phase: **Phase 92: Driver Clean Controlled Manual Handoff' -Description 'Recommended next phase'
Test-BoostLabTextContains -Text $planText -Needle 'If Yazan wants Auto preservation first' -Description 'Alternative artifact decision path'

foreach ($linkedPath in @(
    'docs\tool-designs\driver-clean-controlled-intake-implementation-readiness.md',
    'docs\final-deferred-tools-readiness-matrix.md',
    'docs\deferred-tools-execution-plan.md',
    'docs\deferred-tool-readiness-review.md'
)) {
    $docText = Get-Content -LiteralPath (Join-Path $ProjectRoot $linkedPath) -Raw
    if (-not $docText.Contains('docs/tool-designs/driver-clean-controlled-implementation-plan.md')) {
        throw "Expected document does not link to Driver Clean controlled implementation plan: $linkedPath"
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
if ($allTools.Count -ne 50) {
    throw "Expected 50 active tools, found $($allTools.Count)."
}
if ($placeholderModules.Count -ne 18) {
    throw "Expected 18 deferred/placeholders, found $($placeholderModules.Count)."
}
if (($allTools.Count - $placeholderModules.Count) -ne 32) {
    throw "Expected 32 implemented tools, found $($allTools.Count - $placeholderModules.Count)."
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
    PlanPath                     = $planPath
    Strategy                     = 'ManualHandoffFirst'
    AutoStatus                   = 'AutoBlockedUntilArtifactApproval'
    DriverCleanMirrorHash        = $actualDriverCleanHash
    ActiveToolCount              = $allTools.Count
    ImplementedToolCount         = $allTools.Count - $placeholderModules.Count
    DeferredPlaceholderCount     = $placeholderModules.Count
    SourcePromotedCandidateCount = $sourcePromotedFiles.Count
    RuntimeBehaviorChanged       = $false
    ProductionApprovalsAdded     = $false
    Message                      = 'Driver Clean controlled implementation plan is documented and remains non-executing.'
}
