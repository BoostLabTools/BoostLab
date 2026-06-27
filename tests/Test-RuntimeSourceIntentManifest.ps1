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
        throw 'Unable to determine the runtime source intent manifest validator path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

function Assert-BoostLabCondition {
    param(
        [Parameter(Mandatory)]
        [bool]$Condition,

        [Parameter(Mandatory)]
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

$manifestPath = Join-Path $ProjectRoot 'config\RuntimeSourceIntentManifest.psd1'
$helperPath = Join-Path $ProjectRoot 'core\RuntimeSourceIntent.psm1'
$sourceVerificationPath = Join-Path $ProjectRoot 'core\SourceVerification.psm1'
$runtimePayloadManifestPath = Join-Path $ProjectRoot 'config\RuntimePayloadManifest.psd1'
$runtimePayloadHelperPath = Join-Path $ProjectRoot 'core\RuntimePayloads.psm1'
foreach ($path in @($manifestPath, $helperPath, $sourceVerificationPath, $runtimePayloadManifestPath, $runtimePayloadHelperPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required runtime source intent file is missing: $path"
}

Import-Module -Name $helperPath -Force -ErrorAction Stop
Import-Module -Name $runtimePayloadHelperPath -Force -ErrorAction Stop
Import-Module -Name $sourceVerificationPath -Force -ErrorAction Stop

$manifest = Get-BoostLabRuntimeSourceIntentManifest -ManifestPath $manifestPath
$runtimePayloadManifest = Get-BoostLabRuntimePayloadManifest -ManifestPath $runtimePayloadManifestPath
Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$manifest.SchemaVersion)) 'Runtime source intent manifest must declare SchemaVersion.'
Assert-BoostLabCondition ([string]$manifest.CustomerVisible -eq 'False') 'Runtime source intent manifest must not be customer-visible.'
Assert-BoostLabCondition ($manifest.Contains('Entries')) 'Runtime source intent manifest must contain Entries.'
Assert-BoostLabCondition ($manifest.Entries -is [System.Collections.IDictionary]) 'Runtime source intent Entries must be a dictionary.'

$entries = $manifest.Entries
Assert-BoostLabCondition ($entries.Count -eq 20) "Expected 20 runtime source intent entries, found $($entries.Count)."

$requiredEntryFields = @(
    'SourceId'
    'ToolId'
    'ModuleRelativePath'
    'SourceRelativePath'
    'SourceRole'
    'RawSha256'
    'CanonicalTextSha256'
    'HashMode'
    'RuntimeUse'
    'ExternalHandling'
    'ExternalModeTreatment'
    'CustomerVisible'
    'CurrentInternalSourceRequired'
    'HighRiskBlocker'
    'PayloadBlockers'
)
$allowedSourceRoles = @('ProtectedUltimateSource', 'SourcePromotedIntake', 'SourceExtra')
$allowedHashModes = @('CanonicalText', 'RawBytes', 'ManifestOnly')
$allowedExternalHandling = @(
    'ManifestOnly'
    'GeneratedRuntimePayloadRequired'
    'ExternalRuntimeBlockedUntilDecoupled'
    'NotRequiredExternally'
)
$allowedExternalModeTreatments = @(
    'ManifestOnly'
    'RuntimePayloadReady'
    'DevelopmentOnlySourceParity'
    'DiagnosticsOnly'
    'ExternalRuntimeCanExcludeSource'
    'ExternalRuntimeStillBlocked'
    'NeedsModuleDecoupling'
    'NeedsCustomerFacingTextCleanup'
)

foreach ($entryId in @($entries.Keys | Sort-Object)) {
    $entry = $entries[$entryId]
    Assert-BoostLabCondition ($entry -is [System.Collections.IDictionary]) "Runtime source intent entry must be a dictionary: $entryId"
    foreach ($field in $requiredEntryFields) {
        Assert-BoostLabCondition ($entry.Contains($field)) "Runtime source intent entry is missing $field`: $entryId"
    }

    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$entry.SourceId)) "SourceId must not be blank: $entryId"
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$entry.ToolId)) "ToolId must not be blank: $entryId"
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$entry.ModuleRelativePath)) "ModuleRelativePath must not be blank: $entryId"
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$entry.SourceRelativePath)) "SourceRelativePath must not be blank: $entryId"
    Assert-BoostLabCondition ([string]$entry.SourceRole -in $allowedSourceRoles) "Invalid SourceRole for $entryId`: $($entry.SourceRole)"
    Assert-BoostLabCondition ([string]$entry.HashMode -in $allowedHashModes) "Invalid HashMode for $entryId`: $($entry.HashMode)"
    Assert-BoostLabCondition ([string]$entry.ExternalHandling -in $allowedExternalHandling) "Invalid ExternalHandling for $entryId`: $($entry.ExternalHandling)"
    Assert-BoostLabCondition (@($entry.ExternalModeTreatment).Count -gt 0) "Entry must declare ExternalModeTreatment: $entryId"
    foreach ($treatment in @($entry.ExternalModeTreatment)) {
        Assert-BoostLabCondition ([string]$treatment -in $allowedExternalModeTreatments) "Invalid ExternalModeTreatment for $entryId`: $treatment"
    }
    Assert-BoostLabCondition ([string]$entry.RawSha256 -match '^[A-Fa-f0-9]{64}$') "RawSha256 must be a full SHA-256 hash: $entryId"
    Assert-BoostLabCondition ([string]$entry.CanonicalTextSha256 -match '^[A-Fa-f0-9]{64}$') "CanonicalTextSha256 must be a full SHA-256 hash: $entryId"
    Assert-BoostLabCondition ([string]$entry.CustomerVisible -eq 'False') "Entry must not be customer-visible: $entryId"
    Assert-BoostLabCondition ([string]$entry.CurrentInternalSourceRequired -eq 'True') "Entry must record current internal source dependency: $entryId"
    Assert-BoostLabCondition (@($entry.RuntimeUse).Count -gt 0) "Entry must declare RuntimeUse: $entryId"
}

$manifestText = Get-Content -LiteralPath $manifestPath -Raw
foreach ($forbiddenText in @('Codex', 'OpenAI', 'ChatGPT', 'prompt', 'scaffold', 'pasted-text', '-----BEGIN CERTIFICATE-----', "@'", '@"')) {
    Assert-BoostLabCondition (-not $manifestText.Contains($forbiddenText)) "Runtime source intent manifest contains forbidden embedded/internal text: $forbiddenText"
}
$longBase64LikeRuns = @([regex]::Matches($manifestText, '[A-Za-z0-9+/]{160,}={0,2}'))
Assert-BoostLabCondition ($longBase64LikeRuns.Count -eq 0) 'Runtime source intent manifest appears to contain embedded payload or source body text.'

$defaultMode = Get-BoostLabRuntimePackageMode -ProjectRoot $ProjectRoot -EnvironmentMode ''
Assert-BoostLabCondition ([string]$defaultMode.Mode -eq 'InternalDevelopment') 'Runtime package mode must default to InternalDevelopment.'
Assert-BoostLabCondition ([bool]$defaultMode.SourceUltimatePresent) 'Internal development mode expects source-ultimate to be present.'
Assert-BoostLabCondition ([bool]$defaultMode.SourceExtraPresent) 'Internal development mode expects source-extra to be present.'
Assert-BoostLabCondition ([bool]$defaultMode.IntakePresent) 'Internal development mode expects intake to be present.'

$externalReadiness = Test-BoostLabExternalRuntimeReadiness -RequestedMode 'ExternalRuntime' -ProjectRoot $ProjectRoot -Manifest $manifest
Assert-BoostLabCondition ([string]$externalReadiness.Mode -eq 'ExternalRuntime') 'External readiness check must run in ExternalRuntime mode.'
Assert-BoostLabCondition (-not [bool]$externalReadiness.ExternalRuntimeReady) 'External runtime must not claim readiness while source dependencies remain blocked.'
Assert-BoostLabCondition ([int]$externalReadiness.TotalSourceIntentEntries -eq 20) 'External readiness must report all runtime source intent entries.'
Assert-BoostLabCondition ([int]$externalReadiness.ExternalReadyEntries -eq 4) 'Exactly four source-intent entries should be external-ready after generated payload rewiring.'
Assert-BoostLabCondition ([int]$externalReadiness.BlockedEntries -eq 16) 'Sixteen source-intent entries should remain blocked until future source decoupling.'
Assert-BoostLabCondition ([int]$externalReadiness.GeneratedPayloadRequiredEntries -eq 0) 'Generated payload requirements should no longer block source intent readiness after the payload rewires.'
Assert-BoostLabCondition ([int]$externalReadiness.RawSourceRequiredEntries -eq 20) 'All current entries still require internal raw source validation.'
Assert-BoostLabCondition ([int]$externalReadiness.HighRiskBlockerCount -eq 0) 'No high-risk generated payload blockers should remain after Phase 175H.'
Assert-BoostLabCondition (-not [bool]$externalReadiness.RuntimeActionExecuted) 'External readiness reporting must not execute runtime actions.'
Assert-BoostLabCondition (-not [bool]$externalReadiness.ChangesExecuted) 'External readiness reporting must not mutate state.'

$expectedPayloadReadyTools = @(
    'defender-optimize-assistant'
    'driver-install-debloat-settings'
    'start-menu-taskbar'
    'timer-resolution-assistant'
)
$actualHighRiskTools = @($externalReadiness.HighRiskBlockers | ForEach-Object { [string]$_.ToolId } | Sort-Object)
Assert-BoostLabCondition ($actualHighRiskTools.Count -eq 0) "High-risk blocker list should be empty after payload rewiring: $($actualHighRiskTools -join ', ')"
$actualPayloadReadyTools = @(
    $entries.Values |
        Where-Object { 'RuntimePayloadReady' -in @($_.ExternalModeTreatment) } |
        ForEach-Object { [string]$_.ToolId } |
        Sort-Object
)
Assert-BoostLabCondition (($actualPayloadReadyTools -join '|') -eq (($expectedPayloadReadyTools | Sort-Object) -join '|')) "Runtime-payload-ready source intent list mismatch: $($actualPayloadReadyTools -join ', ')"

$timerIntent = @(Resolve-BoostLabRuntimeSourceIntent -RequestedMode 'ExternalRuntime' -ProjectRoot $ProjectRoot -ToolId 'timer-resolution-assistant' -Manifest $manifest)
Assert-BoostLabCondition ($timerIntent.Count -eq 1) 'Timer Resolution source intent should resolve exactly once.'
Assert-BoostLabCondition (-not [bool]$timerIntent[0].ExternalRuntimeBlocked) 'Timer Resolution source intent should no longer be externally blocked by generated payload decoupling.'
Assert-BoostLabCondition ([string]$timerIntent[0].BlockerReason -eq '') 'Timer Resolution source intent should not report a generated-payload blocker reason.'
Assert-BoostLabCondition (-not [bool]$timerIntent[0].RuntimeActionExecuted) 'Timer Resolution source intent resolution must not execute runtime actions.'

$directXIntent = @(Resolve-BoostLabRuntimeSourceIntent -RequestedMode 'ExternalRuntime' -ProjectRoot $ProjectRoot -ToolId 'directx' -Manifest $manifest)
Assert-BoostLabCondition ($directXIntent.Count -eq 1) 'DirectX source intent should resolve exactly once.'
Assert-BoostLabCondition ([bool]$directXIntent[0].ExternalRuntimeBlocked) 'DirectX should remain externally blocked until source verification is decoupled.'
Assert-BoostLabCondition ([string]$directXIntent[0].BlockerReason -eq 'ExternalRuntimeBlockedUntilDecoupled') 'DirectX blocker reason mismatch.'

$internalTimerIntent = @(Resolve-BoostLabRuntimeSourceIntent -RequestedMode 'InternalDevelopment' -ProjectRoot $ProjectRoot -ToolId 'timer-resolution-assistant' -Manifest $manifest)
Assert-BoostLabCondition ($internalTimerIntent.Count -eq 1) 'Timer Resolution internal source intent should resolve exactly once.'
Assert-BoostLabCondition (-not [bool]$internalTimerIntent[0].ExternalRuntimeBlocked) 'InternalDevelopment mode must not mark Timer Resolution as externally blocked.'

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('BoostLabRuntimeSourceIntent-' + [guid]::NewGuid().ToString('N'))
New-Item -Path $tempRoot -ItemType Directory -Force | Out-Null
try {
    $utf8NoBom = [Text.UTF8Encoding]::new($false)
    foreach ($entryId in @($entries.Keys | Sort-Object)) {
        $entry = $entries[$entryId]
        $relativeSource = ([string]$entry.SourceRelativePath).Replace('/', '\')
        $sourcePath = Join-Path $ProjectRoot $relativeSource
        Assert-BoostLabCondition (Test-Path -LiteralPath $sourcePath -PathType Leaf) "Runtime source intent path is missing: $entryId -> $relativeSource"

        $sourceStatus = Test-BoostLabSourceChecksum `
            -LiteralPath $sourcePath `
            -ExpectedSha256 ([string]$entry.RawSha256) `
            -ExpectedCanonicalSha256 ([string]$entry.CanonicalTextSha256) `
            -TextNormalizationEnabled $true
        Assert-BoostLabCondition ([string]$sourceStatus.ChecksumStatus -eq 'Passed') "Runtime source intent hash mismatch: $entryId"

        if ([string]$entry.HashMode -eq 'CanonicalText') {
            $sourceBytes = [IO.File]::ReadAllBytes($sourcePath)
            $sourceText = [Text.Encoding]::UTF8.GetString($sourceBytes)
            $sourceText = $sourceText -replace "`r`n", "`n"
            $sourceText = $sourceText -replace "`r", "`n"
            $lfPath = Join-Path $tempRoot (($entryId -replace '[^A-Za-z0-9_.-]', '_') + '.ps1')
            [IO.File]::WriteAllBytes($lfPath, $utf8NoBom.GetBytes($sourceText))

            $lfStatus = Test-BoostLabSourceChecksum `
                -LiteralPath $lfPath `
                -ExpectedSha256 ([string]$entry.RawSha256) `
                -ExpectedCanonicalSha256 ([string]$entry.CanonicalTextSha256) `
                -TextNormalizationEnabled $true
            Assert-BoostLabCondition ([string]$lfStatus.ChecksumStatus -eq 'Passed') "Runtime source intent canonical LF hash mismatch: $entryId"
        }
    }
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

$startMenuPayloads = @($entries['start-menu-taskbar.source'].PayloadBlockers)
Assert-BoostLabCondition ($startMenuPayloads.Count -eq 1) 'Start Menu Taskbar must record one generated payload blocker.'
Assert-BoostLabCondition ([string]$startMenuPayloads[0].PayloadKind -eq 'Binary') 'Start Menu Taskbar payload blocker must identify the binary payload.'
Assert-BoostLabCondition ([string]$startMenuPayloads[0].HashMode -eq 'RawBytes') 'Start Menu Taskbar binary payload must remain raw-byte hashed.'
Assert-BoostLabCondition ([string]$startMenuPayloads[0].ExternalHandling -eq 'GeneratedRuntimePayloadAvailable') 'Start Menu Taskbar payload blocker must be classified as generated-runtime-payload available.'
Assert-BoostLabCondition ([string]$startMenuPayloads[0].RuntimeWiringStatus -eq 'ReadyForExternalRuntime') 'Start Menu Taskbar payload blocker must be runtime-wired.'
Assert-BoostLabCondition ([string]$startMenuPayloads[0].ExpectedSha256 -match '^[A-Fa-f0-9]{64}$') 'Start Menu Taskbar binary payload must record its raw SHA-256.'
Assert-BoostLabCondition ([int]$startMenuPayloads[0].ExpectedLength -eq 4540) 'Start Menu Taskbar binary payload length mismatch.'

foreach ($payloadReadyTool in $expectedPayloadReadyTools) {
    $entry = @($entries.Values | Where-Object { [string]$_['ToolId'] -eq $payloadReadyTool } | Select-Object -First 1)
    Assert-BoostLabCondition ($entry.Count -eq 1) "Runtime-payload-ready manifest entry missing: $payloadReadyTool"
    Assert-BoostLabCondition ([string]$entry[0].ExternalHandling -eq 'ManifestOnly') "Payload-ready source intent must become ManifestOnly externally: $payloadReadyTool"
    Assert-BoostLabCondition ('RuntimePayloadReady' -in @($entry[0].ExternalModeTreatment)) "Payload-ready source intent must declare RuntimePayloadReady: $payloadReadyTool"
    Assert-BoostLabCondition ('ExternalRuntimeCanExcludeSource' -in @($entry[0].ExternalModeTreatment)) "Payload-ready source intent must allow external source exclusion: $payloadReadyTool"
    Assert-BoostLabCondition (-not [bool]$entry[0].HighRiskBlocker) "Payload-ready source intent must not remain a high-risk generated payload blocker: $payloadReadyTool"
    Assert-BoostLabCondition (@($entry[0].PayloadBlockers).Count -gt 0) "Payload-ready source intent must list generated payload records: $payloadReadyTool"
    foreach ($payloadBlocker in @($entry[0].PayloadBlockers)) {
        $payloadId = [string]$payloadBlocker.PayloadId
        Assert-BoostLabCondition ($runtimePayloadManifest.Entries.Contains($payloadId)) "Payload-ready source intent references unknown runtime payload: $payloadReadyTool -> $payloadId"
        $runtimePayloadEntry = $runtimePayloadManifest.Entries[$payloadId]
        Assert-BoostLabCondition ([string]$runtimePayloadEntry.RuntimeWiringStatus -eq 'ReadyForExternalRuntime') "Runtime payload is not ready for external runtime: $payloadReadyTool -> $payloadId"
        Assert-BoostLabCondition ([string]$payloadBlocker.RuntimeWiringStatus -eq 'ReadyForExternalRuntime') "Source intent payload blocker status mismatch: $payloadReadyTool -> $payloadId"
        Assert-BoostLabCondition ([string]$payloadBlocker.ExternalHandling -eq 'GeneratedRuntimePayloadAvailable') "Source intent payload blocker handling mismatch: $payloadReadyTool -> $payloadId"
    }
}

$modulesWithRuntimeSourceIntent = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'modules') -Recurse -File -Filter '*.psm1' |
        Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw).Contains('RuntimeSourceIntent')
        }
)
Assert-BoostLabCondition ($modulesWithRuntimeSourceIntent.Count -eq 0) 'This phase must not wire runtime source intent into tool modules.'

foreach ($requiredFolder in @('source-ultimate', 'source-extra', 'intake')) {
    Assert-BoostLabCondition (Test-Path -LiteralPath (Join-Path $ProjectRoot $requiredFolder) -PathType Container) "Required protected/internal folder is missing: $requiredFolder"
}

[pscustomobject]@{
    Test = 'RuntimeSourceIntentManifest'
    Passed = $true
    ManifestEntries = $entries.Count
    ExternalRuntimeReady = [bool]$externalReadiness.ExternalRuntimeReady
    ExternalReadyEntries = [int]$externalReadiness.ExternalReadyEntries
    BlockedEntries = [int]$externalReadiness.BlockedEntries
    GeneratedPayloadRequiredEntries = [int]$externalReadiness.GeneratedPayloadRequiredEntries
    RuntimePayloadReadyTools = $actualPayloadReadyTools
    HighRiskBlockers = $actualHighRiskTools
    RuntimeActionExecuted = $false
    SourceUltimateUntouched = $true
    SourceExtraUntouched = $true
    IntakeUntouched = $true
    Message = 'Runtime source intent manifest is schema-valid, records payload-ready source intents, preserves internal source parity, and keeps remaining external blockers structured.'
}
