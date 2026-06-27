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
        throw 'Unable to determine the external runtime readiness validator path.'
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

function Copy-BoostLabDataObject {
    param(
        [AllowNull()]
        [object]$InputObject
    )

    if ($null -eq $InputObject) {
        return $null
    }
    if ($InputObject -is [System.Collections.IDictionary]) {
        $copy = @{}
        foreach ($key in @($InputObject.Keys)) {
            $copy[$key] = Copy-BoostLabDataObject -InputObject $InputObject[$key]
        }

        return $copy
    }
    if ($InputObject -is [System.Collections.IEnumerable] -and -not ($InputObject -is [string])) {
        $items = @()
        foreach ($item in $InputObject) {
            $items += ,(Copy-BoostLabDataObject -InputObject $item)
        }

        return $items
    }

    return $InputObject
}

$sourceIntentManifestPath = Join-Path $ProjectRoot 'config\RuntimeSourceIntentManifest.psd1'
$sourceIntentHelperPath = Join-Path $ProjectRoot 'core\RuntimeSourceIntent.psm1'
$runtimePayloadManifestPath = Join-Path $ProjectRoot 'config\RuntimePayloadManifest.psd1'
$runtimePayloadHelperPath = Join-Path $ProjectRoot 'core\RuntimePayloads.psm1'
$operationDescriptorManifestPath = Join-Path $ProjectRoot 'config\RuntimeOperationDescriptors.psd1'
$operationDescriptorHelperPath = Join-Path $ProjectRoot 'core\RuntimeOperationDescriptors.psm1'
foreach ($path in @(
    $sourceIntentManifestPath
    $sourceIntentHelperPath
    $runtimePayloadManifestPath
    $runtimePayloadHelperPath
    $operationDescriptorManifestPath
    $operationDescriptorHelperPath
)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required external runtime readiness file is missing: $path"
}

Import-Module -Name $runtimePayloadHelperPath -Force -ErrorAction Stop
Import-Module -Name $operationDescriptorHelperPath -Force -ErrorAction Stop
Import-Module -Name $sourceIntentHelperPath -Force -ErrorAction Stop

$sourceIntentManifest = Get-BoostLabRuntimeSourceIntentManifest -ManifestPath $sourceIntentManifestPath
$runtimePayloadManifest = Get-BoostLabRuntimePayloadManifest -ManifestPath $runtimePayloadManifestPath
$operationDescriptorManifest = Get-BoostLabRuntimeOperationDescriptorManifest -ManifestPath $operationDescriptorManifestPath

$readiness = Test-BoostLabExternalRuntimeReadiness `
    -RequestedMode 'ExternalRuntime' `
    -ProjectRoot $ProjectRoot `
    -Manifest $sourceIntentManifest `
    -RuntimePayloadManifest $runtimePayloadManifest `
    -OperationDescriptorManifest $operationDescriptorManifest

Assert-BoostLabCondition ([bool]$readiness.ExternalRuntimeReady) 'ExternalRuntime source-intent readiness should be true when payload and descriptor evidence is valid.'
Assert-BoostLabCondition (-not [bool]$readiness.ExternalPackageBuildReady) 'External package build readiness must remain false while direct module source references remain.'
Assert-BoostLabCondition ([bool]$readiness.ExternalPackageSourceFreeLaunchBlocked) 'External package source-free launch should report direct module source-reference blockers.'
Assert-BoostLabCondition ([int]$readiness.TotalSourceIntentEntries -eq 20) 'External readiness must report twenty source-intent entries.'
Assert-BoostLabCondition ([int]$readiness.PayloadBackedReadyEntries -eq 4) 'External readiness must report four payload-backed source-intent entries.'
Assert-BoostLabCondition ([int]$readiness.DescriptorBackedReadyEntries -eq 16) 'External readiness must report sixteen descriptor-backed source-intent entries.'
Assert-BoostLabCondition ([int]$readiness.BlockedEntries -eq 0) 'External readiness should not report source-intent blockers when evidence is valid.'
Assert-BoostLabCondition ([int]$readiness.TotalPayloads -eq 5) 'External readiness must report five runtime payloads.'
Assert-BoostLabCondition ([int]$readiness.ReadyPayloads -eq 5) 'External readiness must report five ready runtime payloads.'
Assert-BoostLabCondition ([int]$readiness.TotalOperationDescriptors -eq 16) 'External readiness must report sixteen operation descriptors.'
Assert-BoostLabCondition ([int]$readiness.ValidOperationDescriptors -eq 16) 'External readiness must report sixteen valid operation descriptors.'
Assert-BoostLabCondition ([int]$readiness.ExternalRawSourceVerificationEntries -eq 0) 'ExternalRuntime readiness must not claim raw source verification.'
Assert-BoostLabCondition ([int]$readiness.InternalRawSourceReferenceEntries -eq 20) 'Internal source parity references must remain recorded.'
Assert-BoostLabCondition ([int]$readiness.SourceFreePackageBlockerCount -gt 0) 'Direct module source references should remain visible as package blockers.'
Assert-BoostLabCondition (@($readiness.SourceIntentBlockers).Count -eq 0) 'Valid external readiness should not emit source-intent blockers.'

$resolvedExternal = @(Resolve-BoostLabRuntimeSourceIntent `
    -RequestedMode 'ExternalRuntime' `
    -ProjectRoot $ProjectRoot `
    -Manifest $sourceIntentManifest `
    -RuntimePayloadManifest $runtimePayloadManifest `
    -OperationDescriptorManifest $operationDescriptorManifest)
Assert-BoostLabCondition ($resolvedExternal.Count -eq 20) 'ExternalRuntime should resolve all source-intent entries.'
Assert-BoostLabCondition (@($resolvedExternal | Where-Object { [bool]$_.RawSourceVerificationClaimed }).Count -eq 0) 'ExternalRuntime source-intent resolution must not claim raw source verification.'
Assert-BoostLabCondition (@($resolvedExternal | Where-Object { [string]$_.SourceEvidenceMode -eq 'RuntimePayload' }).Count -eq 4) 'ExternalRuntime should resolve four source intents through runtime payloads.'
Assert-BoostLabCondition (@($resolvedExternal | Where-Object { [string]$_.SourceEvidenceMode -eq 'OperationDescriptor' }).Count -eq 16) 'ExternalRuntime should resolve sixteen source intents through operation descriptors.'

$internalMode = Get-BoostLabRuntimePackageMode -ProjectRoot $ProjectRoot -EnvironmentMode ''
Assert-BoostLabCondition ([string]$internalMode.Mode -eq 'InternalDevelopment') 'Runtime package mode should default to InternalDevelopment.'
Assert-BoostLabCondition ([bool]$internalMode.SourceFoldersExpected) 'InternalDevelopment mode must expect protected source folders.'
Assert-BoostLabCondition ([bool]$internalMode.SourceUltimatePresent) 'InternalDevelopment mode should see source-ultimate.'
Assert-BoostLabCondition ([bool]$internalMode.SourceExtraPresent) 'InternalDevelopment mode should see source-extra.'
Assert-BoostLabCondition ([bool]$internalMode.IntakePresent) 'InternalDevelopment mode should see intake.'

$resolvedInternalDirectX = @(Resolve-BoostLabRuntimeSourceIntent `
    -RequestedMode 'InternalDevelopment' `
    -ProjectRoot $ProjectRoot `
    -ToolId 'directx' `
    -Manifest $sourceIntentManifest `
    -RuntimePayloadManifest $runtimePayloadManifest `
    -OperationDescriptorManifest $operationDescriptorManifest)
Assert-BoostLabCondition ($resolvedInternalDirectX.Count -eq 1) 'InternalDevelopment DirectX source intent should resolve exactly once.'
Assert-BoostLabCondition ([string]$resolvedInternalDirectX[0].SourceEvidenceMode -eq 'InternalDevelopmentSourceParity') 'InternalDevelopment source intent must continue to use source parity evidence.'
Assert-BoostLabCondition ([bool]$resolvedInternalDirectX[0].RawSourceVerificationClaimed) 'InternalDevelopment source intent should continue to claim raw source verification.'

$missingDescriptorManifest = Copy-BoostLabDataObject -InputObject $operationDescriptorManifest
$missingDescriptorManifest.Entries.Remove('directx-operation-summary')
$missingDescriptorReadiness = Test-BoostLabExternalRuntimeReadiness `
    -RequestedMode 'ExternalRuntime' `
    -ProjectRoot $ProjectRoot `
    -Manifest $sourceIntentManifest `
    -RuntimePayloadManifest $runtimePayloadManifest `
    -OperationDescriptorManifest $missingDescriptorManifest
Assert-BoostLabCondition (-not [bool]$missingDescriptorReadiness.ExternalRuntimeReady) 'Missing descriptor should block ExternalRuntime source-intent readiness.'
Assert-BoostLabCondition ([int]$missingDescriptorReadiness.BlockedEntries -eq 1) 'Missing descriptor should create one source-intent blocker.'
Assert-BoostLabCondition ([string]$missingDescriptorReadiness.SourceIntentBlockers[0].EntryId -eq 'directx.source') 'Missing descriptor blocker should identify DirectX source intent.'
Assert-BoostLabCondition ([string]$missingDescriptorReadiness.SourceIntentBlockers[0].BlockerReason -eq 'MissingOperationDescriptor') 'Missing descriptor blocker reason mismatch.'

$invalidDescriptorManifest = Copy-BoostLabDataObject -InputObject $operationDescriptorManifest
$invalidDescriptorManifest.Entries['directx-operation-summary'].SourceRawSha256 = 'invalid'
$invalidDescriptorReadiness = Test-BoostLabExternalRuntimeReadiness `
    -RequestedMode 'ExternalRuntime' `
    -ProjectRoot $ProjectRoot `
    -Manifest $sourceIntentManifest `
    -RuntimePayloadManifest $runtimePayloadManifest `
    -OperationDescriptorManifest $invalidDescriptorManifest
Assert-BoostLabCondition (-not [bool]$invalidDescriptorReadiness.ExternalRuntimeReady) 'Invalid descriptor should block ExternalRuntime source-intent readiness.'
Assert-BoostLabCondition ([int]$invalidDescriptorReadiness.BlockedEntries -eq 1) 'Invalid descriptor should create one source-intent blocker.'
Assert-BoostLabCondition ([string]$invalidDescriptorReadiness.SourceIntentBlockers[0].EntryId -eq 'directx.source') 'Invalid descriptor blocker should identify DirectX source intent.'
Assert-BoostLabCondition ([string]$invalidDescriptorReadiness.SourceIntentBlockers[0].BlockerReason -eq 'InvalidOperationDescriptor') 'Invalid descriptor blocker reason mismatch.'

$missingPayloadManifest = Copy-BoostLabDataObject -InputObject $runtimePayloadManifest
$missingPayloadManifest.Entries.Remove('start-menu-taskbar-start2-bin')
$missingPayloadReadiness = Test-BoostLabExternalRuntimeReadiness `
    -RequestedMode 'ExternalRuntime' `
    -ProjectRoot $ProjectRoot `
    -Manifest $sourceIntentManifest `
    -RuntimePayloadManifest $missingPayloadManifest `
    -OperationDescriptorManifest $operationDescriptorManifest
Assert-BoostLabCondition (-not [bool]$missingPayloadReadiness.ExternalRuntimeReady) 'Missing payload should block ExternalRuntime source-intent readiness.'
Assert-BoostLabCondition ([int]$missingPayloadReadiness.BlockedEntries -eq 1) 'Missing payload should create one source-intent blocker.'
Assert-BoostLabCondition ([string]$missingPayloadReadiness.SourceIntentBlockers[0].EntryId -eq 'start-menu-taskbar.source') 'Missing payload blocker should identify Start Menu Taskbar source intent.'
Assert-BoostLabCondition ([string]$missingPayloadReadiness.SourceIntentBlockers[0].BlockerReason -eq 'MissingRuntimePayload') 'Missing payload blocker reason mismatch.'

$descriptorText = Get-Content -LiteralPath $operationDescriptorManifestPath -Raw
$sourceIntentText = Get-Content -LiteralPath $sourceIntentManifestPath -Raw
foreach ($forbiddenText in @('Codex', 'OpenAI', 'ChatGPT', 'prompt', 'pasted-text', '-----BEGIN CERTIFICATE-----', "@'", '@"')) {
    Assert-BoostLabCondition (-not $descriptorText.Contains($forbiddenText)) "Operation descriptor manifest contains forbidden embedded/internal text: $forbiddenText"
    Assert-BoostLabCondition (-not $sourceIntentText.Contains($forbiddenText)) "Source intent manifest contains forbidden embedded/internal text: $forbiddenText"
}
Assert-BoostLabCondition (@([regex]::Matches($descriptorText, '[A-Za-z0-9+/]{160,}={0,2}')).Count -eq 0) 'Operation descriptor manifest appears to embed source body or payload text.'

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('BoostLabExternalRuntimeReadiness-' + [guid]::NewGuid().ToString('N'))
New-Item -Path $tempRoot -ItemType Directory -Force | Out-Null
try {
    Copy-Item -LiteralPath (Join-Path $ProjectRoot 'runtime-payloads') -Destination $tempRoot -Recurse -Force
    foreach ($descriptor in @($operationDescriptorManifest.Entries.Values)) {
        $modulePath = Join-Path $tempRoot ([string]$descriptor.ModuleRelativePath)
        $moduleFolder = Split-Path -Parent $modulePath
        New-Item -Path $moduleFolder -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath $modulePath -Value "# ExternalRuntime descriptor-readiness placeholder for static validation only." -Encoding UTF8
    }

    foreach ($sourceFolder in @('source-ultimate', 'source-extra', 'intake')) {
        Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $tempRoot $sourceFolder))) "ExternalRuntime temp root must not contain $sourceFolder."
    }

    $sourceFreeReadiness = Test-BoostLabExternalRuntimeReadiness `
        -RequestedMode 'ExternalRuntime' `
        -ProjectRoot $tempRoot `
        -Manifest $sourceIntentManifest `
        -RuntimePayloadManifest $runtimePayloadManifest `
        -OperationDescriptorManifest $operationDescriptorManifest
    Assert-BoostLabCondition ([bool]$sourceFreeReadiness.ExternalRuntimeReady) 'ExternalRuntime source-intent readiness should work without source folders when payloads and descriptor module paths exist.'
    Assert-BoostLabCondition ([int]$sourceFreeReadiness.ExternalRawSourceVerificationEntries -eq 0) 'Source-free ExternalRuntime temp root must not claim raw source verification.'
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

[pscustomobject]@{
    Test = 'ExternalRuntimeReadiness'
    Passed = $true
    ExternalRuntimeReady = [bool]$readiness.ExternalRuntimeReady
    ExternalPackageBuildReady = [bool]$readiness.ExternalPackageBuildReady
    PayloadBackedReadyEntries = [int]$readiness.PayloadBackedReadyEntries
    DescriptorBackedReadyEntries = [int]$readiness.DescriptorBackedReadyEntries
    SourceFreePackageBlockerCount = [int]$readiness.SourceFreePackageBlockerCount
    MissingDescriptorBlocked = $true
    InvalidDescriptorBlocked = $true
    MissingPayloadBlocked = $true
    RuntimeActionExecuted = $false
    SourceUltimateUntouched = $true
    SourceExtraUntouched = $true
    IntakeUntouched = $true
    Message = 'ExternalRuntime source-intent readiness is payload/descriptor backed while full source-free package launch remains separately blocked by direct module source references.'
}
