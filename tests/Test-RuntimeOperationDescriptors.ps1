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
        throw 'Unable to determine the runtime operation descriptor validator path.'
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

function Get-BoostLabGitExecutable {
    $gitCommand = Get-Command -Name 'git' -ErrorAction SilentlyContinue
    if ($null -ne $gitCommand) {
        return [string]$gitCommand.Source
    }

    $githubDesktopRoot = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'GitHubDesktop'
    if (Test-Path -LiteralPath $githubDesktopRoot -PathType Container) {
        $githubDesktopGit = @(
            Get-ChildItem -LiteralPath $githubDesktopRoot -Directory -Filter 'app-*' -ErrorAction SilentlyContinue |
                Sort-Object -Property Name -Descending |
                ForEach-Object { Join-Path $_.FullName 'resources\app\git\cmd\git.exe' } |
                Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }
        ) | Select-Object -First 1

        if (-not [string]::IsNullOrWhiteSpace($githubDesktopGit)) {
            return [string]$githubDesktopGit
        }
    }

    return ''
}

function Get-BoostLabStageToolIndex {
    param(
        [Parameter(Mandatory)]
        [object]$Stages
    )

    $index = @{}
    foreach ($stage in @($Stages)) {
        foreach ($tool in @($stage.Tools)) {
            $index[[string]$tool.Id] = [pscustomobject]@{
                Stage = [string]$stage.Name
                Title = [string]$tool.Title
                Actions = @($tool.Actions | ForEach-Object { [string]$_ })
                Capabilities = $tool.Capabilities
            }
        }
    }

    return $index
}

$descriptorManifestPath = Join-Path $ProjectRoot 'config\RuntimeOperationDescriptors.psd1'
$descriptorHelperPath = Join-Path $ProjectRoot 'core\RuntimeOperationDescriptors.psm1'
$sourceIntentManifestPath = Join-Path $ProjectRoot 'config\RuntimeSourceIntentManifest.psd1'
$sourceIntentHelperPath = Join-Path $ProjectRoot 'core\RuntimeSourceIntent.psm1'
$runtimePayloadManifestPath = Join-Path $ProjectRoot 'config\RuntimePayloadManifest.psd1'
$runtimePayloadHelperPath = Join-Path $ProjectRoot 'core\RuntimePayloads.psm1'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
foreach ($path in @(
    $descriptorManifestPath
    $descriptorHelperPath
    $sourceIntentManifestPath
    $sourceIntentHelperPath
    $runtimePayloadManifestPath
    $runtimePayloadHelperPath
    $stagesPath
)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required runtime operation descriptor file is missing: $path"
}

Import-Module -Name $descriptorHelperPath -Force -ErrorAction Stop
Import-Module -Name $sourceIntentHelperPath -Force -ErrorAction Stop
Import-Module -Name $runtimePayloadHelperPath -Force -ErrorAction Stop

$manifest = Get-BoostLabRuntimeOperationDescriptorManifest -ManifestPath $descriptorManifestPath
$sourceIntentManifest = Get-BoostLabRuntimeSourceIntentManifest -ManifestPath $sourceIntentManifestPath
$runtimePayloadManifest = Get-BoostLabRuntimePayloadManifest -ManifestPath $runtimePayloadManifestPath
$stagesConfig = Import-PowerShellDataFile -LiteralPath $stagesPath
$stageToolIndex = Get-BoostLabStageToolIndex -Stages $stagesConfig.Stages

Assert-BoostLabCondition ([string]$manifest.SchemaVersion -eq '1.0') 'Runtime operation descriptor manifest schema version mismatch.'
Assert-BoostLabCondition ([string]$manifest.ManifestKind -eq 'RuntimeOperationDescriptors') 'Runtime operation descriptor manifest kind mismatch.'
Assert-BoostLabCondition ([string]$manifest.CustomerVisible -eq 'False') 'Runtime operation descriptor manifest must not be customer-visible.'
Assert-BoostLabCondition ([string]$manifest.DefaultMode -eq 'InternalDevelopment') 'Runtime operation descriptor manifest default mode mismatch.'
Assert-BoostLabCondition ([string]$manifest.ExternalRuntimeStatus -eq 'DescriptorCoverageAvailableModuleDecouplingStillBlocked') 'Runtime operation descriptor external status mismatch.'
Assert-BoostLabCondition ($manifest.Contains('Entries')) 'Runtime operation descriptor manifest must contain Entries.'
Assert-BoostLabCondition ($manifest.Entries -is [System.Collections.IDictionary]) 'Runtime operation descriptor Entries must be a dictionary.'
Assert-BoostLabCondition (@($manifest.RequiredSourceIntentBlockers).Count -eq 16) 'Runtime operation descriptor manifest must list the sixteen source-intent blockers.'

$entries = $manifest.Entries
Assert-BoostLabCondition ($entries.Count -eq 16) "Expected 16 runtime operation descriptors, found $($entries.Count)."

$requiredEntryFields = @(
    'DescriptorId'
    'ToolId'
    'ToolTitle'
    'Stage'
    'SourceIntentId'
    'ModuleRelativePath'
    'SourceRawSha256'
    'SourceCanonicalTextSha256'
    'DescriptorKind'
    'Actions'
    'Branches'
    'OperationCategories'
    'OperationCount'
    'OperationSummary'
    'Capabilities'
    'RuntimeUse'
    'ExternalHandling'
    'ExternalModeTreatment'
    'RuntimeWiringStatus'
    'ModuleRuntimeWiringStatus'
    'CustomerVisible'
    'RuntimeActionExecuted'
    'ChangesExecuted'
)
$expectedCapabilityNames = @(
    'CanDeleteFiles'
    'CanDownload'
    'CanInstallSoftware'
    'CanModifyDrivers'
    'CanModifyRegistry'
    'CanModifySecurity'
    'CanModifyServices'
    'CanReboot'
    'NeedsExplicitConfirmation'
    'RequiresAdmin'
    'RequiresInternet'
    'SupportsDefault'
    'SupportsRestore'
    'UsesSafeMode'
    'UsesTrustedInstaller'
)
$allowedExternalModeTreatments = @(
    'DescriptorOnly'
    'ExternalRuntimeCanExcludeRawSource'
    'ExternalRuntimeStillNeedsModuleDecoupling'
    'DevelopmentOnlySourceParity'
)

$manifestText = Get-Content -LiteralPath $descriptorManifestPath -Raw
foreach ($forbiddenText in @('Codex', 'OpenAI', 'ChatGPT', 'prompt', 'scaffold', 'pasted-text', 'Ultimate', 'source-defined', 'source-equivalent', 'source-ultimate', 'source-extra', '-----BEGIN CERTIFICATE-----', "@'", '@"')) {
    Assert-BoostLabCondition (-not $manifestText.Contains($forbiddenText)) "Runtime operation descriptor manifest contains forbidden embedded/internal text: $forbiddenText"
}
$longBase64LikeRuns = @([regex]::Matches($manifestText, '[A-Za-z0-9+/]{160,}={0,2}'))
Assert-BoostLabCondition ($longBase64LikeRuns.Count -eq 0) 'Runtime operation descriptor manifest appears to contain embedded payload or source body text.'

foreach ($entryId in @($entries.Keys | Sort-Object)) {
    $entry = $entries[$entryId]
    Assert-BoostLabCondition ($entry -is [System.Collections.IDictionary]) "Runtime operation descriptor entry must be a dictionary: $entryId"
    foreach ($field in $requiredEntryFields) {
        Assert-BoostLabCondition ($entry.Contains($field)) "Runtime operation descriptor entry is missing $field`: $entryId"
    }

    Assert-BoostLabCondition ([string]$entry.DescriptorId -eq [string]$entryId) "DescriptorId must match entry id: $entryId"
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$entry.ToolId)) "ToolId must not be blank: $entryId"
    Assert-BoostLabCondition ($stageToolIndex.ContainsKey([string]$entry.ToolId)) "Descriptor references unknown tool id: $entryId -> $($entry.ToolId)"

    $toolInfo = $stageToolIndex[[string]$entry.ToolId]
    Assert-BoostLabCondition ([string]$entry.ToolTitle -eq [string]$toolInfo.Title) "Descriptor title mismatch: $entryId"
    Assert-BoostLabCondition ([string]$entry.Stage -eq [string]$toolInfo.Stage) "Descriptor stage mismatch: $entryId"
    Assert-BoostLabCondition ([string]$entry.DescriptorKind -eq 'OperationSummary') "DescriptorKind mismatch: $entryId"
    Assert-BoostLabCondition ([string]$entry.SourceRawSha256 -match '^[A-Fa-f0-9]{64}$') "SourceRawSha256 must be a full SHA-256 hash: $entryId"
    Assert-BoostLabCondition ([string]$entry.SourceCanonicalTextSha256 -match '^[A-Fa-f0-9]{64}$') "SourceCanonicalTextSha256 must be a full SHA-256 hash: $entryId"
    Assert-BoostLabCondition (@($entry.Actions).Count -gt 0) "Descriptor must declare Actions: $entryId"
    foreach ($action in @($entry.Actions)) {
        Assert-BoostLabCondition ([string]$action -in @($toolInfo.Actions)) "Descriptor action is not in Stages.psd1 for $entryId`: $action"
    }
    Assert-BoostLabCondition (@($entry.Branches).Count -gt 0) "Descriptor must declare branch summaries: $entryId"
    Assert-BoostLabCondition (@($entry.OperationCategories).Count -gt 0) "Descriptor must declare operation categories: $entryId"
    Assert-BoostLabCondition ([int]$entry.OperationCount -gt 0) "Descriptor must declare positive OperationCount: $entryId"

    Assert-BoostLabCondition ($entry.Capabilities -is [System.Collections.IDictionary]) "Descriptor Capabilities must be a dictionary: $entryId"
    foreach ($capabilityName in $expectedCapabilityNames) {
        Assert-BoostLabCondition ($entry.Capabilities.Contains($capabilityName)) "Descriptor capability missing for $entryId`: $capabilityName"
        Assert-BoostLabCondition ([bool]$entry.Capabilities[$capabilityName] -eq [bool]$toolInfo.Capabilities[$capabilityName]) "Descriptor capability mismatch for $entryId`: $capabilityName"
    }

    Assert-BoostLabCondition ([string]$entry.ExternalHandling -eq 'OperationDescriptorAvailable') "Descriptor ExternalHandling mismatch: $entryId"
    foreach ($treatment in @($entry.ExternalModeTreatment)) {
        Assert-BoostLabCondition ([string]$treatment -in $allowedExternalModeTreatments) "Descriptor ExternalModeTreatment invalid for $entryId`: $treatment"
    }
    foreach ($requiredTreatment in @('DescriptorOnly', 'ExternalRuntimeCanExcludeRawSource', 'ExternalRuntimeStillNeedsModuleDecoupling')) {
        Assert-BoostLabCondition ($requiredTreatment -in @($entry.ExternalModeTreatment)) "Descriptor missing required external treatment for $entryId`: $requiredTreatment"
    }
    Assert-BoostLabCondition ([string]$entry.RuntimeWiringStatus -eq 'ReadyForFutureExternalMode') "Descriptor RuntimeWiringStatus mismatch: $entryId"
    Assert-BoostLabCondition ([string]$entry.ModuleRuntimeWiringStatus -eq 'NotWired') "Descriptor ModuleRuntimeWiringStatus mismatch: $entryId"
    Assert-BoostLabCondition ([string]$entry.CustomerVisible -eq 'False') "Descriptor must not be customer-visible: $entryId"
    Assert-BoostLabCondition ([string]$entry.RuntimeActionExecuted -eq 'False') "Descriptor must not record runtime action execution: $entryId"
    Assert-BoostLabCondition ([string]$entry.ChangesExecuted -eq 'False') "Descriptor must not record state mutation: $entryId"
}

$sourceIntentEntries = $sourceIntentManifest.Entries
Assert-BoostLabCondition ($sourceIntentEntries -is [System.Collections.IDictionary]) 'Runtime source intent Entries must be a dictionary.'
$descriptorBackedSourceIntentRecords = @(
    $sourceIntentEntries.GetEnumerator() |
        Where-Object { [string]$_.Value['ExternalHandling'] -eq 'OperationDescriptorAvailable' } |
        Sort-Object -Property Name
)
Assert-BoostLabCondition ($descriptorBackedSourceIntentRecords.Count -eq 16) 'Source-intent manifest must report sixteen descriptor-backed entries.'

$blockedSourceIntentIds = @($descriptorBackedSourceIntentRecords | ForEach-Object { [string]$_.Name } | Sort-Object)
$requiredSourceIntentIds = @($manifest.RequiredSourceIntentBlockers | ForEach-Object { [string]$_ } | Sort-Object)
Assert-BoostLabCondition (($blockedSourceIntentIds -join '|') -eq ($requiredSourceIntentIds -join '|')) 'Runtime operation descriptor required source intents must match descriptor-backed source-intent entries.'

foreach ($record in $descriptorBackedSourceIntentRecords) {
    $sourceIntentId = [string]$record.Name
    $sourceEntry = $record.Value
    Assert-BoostLabCondition ($sourceEntry.Contains('OperationDescriptorId')) "Descriptor-backed source-intent entry must reference an operation descriptor: $sourceIntentId"
    Assert-BoostLabCondition ($sourceEntry.Contains('OperationDescriptorStatus')) "Descriptor-backed source-intent entry must declare operation descriptor status: $sourceIntentId"
    Assert-BoostLabCondition ([string]$sourceEntry['OperationDescriptorStatus'] -eq 'Available') "Descriptor-backed source-intent operation descriptor status mismatch: $sourceIntentId"
    Assert-BoostLabCondition ([string]$sourceEntry['RuntimeWiringStatus'] -eq 'DescriptorBackedEvidenceReady') "Descriptor-backed source-intent runtime evidence status mismatch: $sourceIntentId"
    Assert-BoostLabCondition ([string]$sourceEntry['ModuleRuntimeWiringStatus'] -eq 'NotWired') "Descriptor-backed source-intent entry must not claim module wiring: $sourceIntentId"
    Assert-BoostLabCondition ([string]$sourceEntry['ExternalPackageStatus'] -eq 'SourceFreeLaunchBlockedByDirectModuleReferences') "Descriptor-backed source-intent package status mismatch: $sourceIntentId"

    $descriptorId = [string]$sourceEntry['OperationDescriptorId']
    Assert-BoostLabCondition ($entries.Contains($descriptorId)) "Blocked source-intent entry references unknown descriptor: $sourceIntentId -> $descriptorId"
    $descriptor = $entries[$descriptorId]
    Assert-BoostLabCondition ([string]$descriptor.SourceIntentId -eq $sourceIntentId) "Descriptor source-intent link mismatch: $descriptorId"
    Assert-BoostLabCondition ([string]$descriptor.ToolId -eq [string]$sourceEntry['ToolId']) "Descriptor tool link mismatch: $descriptorId"
    Assert-BoostLabCondition ([string]$descriptor.SourceRawSha256 -eq [string]$sourceEntry['RawSha256']) "Descriptor raw source hash mismatch: $descriptorId"
    Assert-BoostLabCondition ([string]$descriptor.SourceCanonicalTextSha256 -eq [string]$sourceEntry['CanonicalTextSha256']) "Descriptor canonical source hash mismatch: $descriptorId"
}

$payloadReadySourceIntentRecords = @(
    $sourceIntentEntries.GetEnumerator() |
        Where-Object { [string]$_.Value['ExternalHandling'] -eq 'ManifestOnly' } |
        Sort-Object -Property Name
)
Assert-BoostLabCondition ($payloadReadySourceIntentRecords.Count -eq 4) 'Source-intent manifest must still report four payload-ready entries.'
foreach ($record in $payloadReadySourceIntentRecords) {
    Assert-BoostLabCondition (-not $record.Value.Contains('OperationDescriptorId')) "Payload-ready source-intent entry must not be marked as operation-descriptor blocked: $($record.Name)"
    Assert-BoostLabCondition ('RuntimePayloadReady' -in @($record.Value['ExternalModeTreatment'])) "Payload-ready source-intent entry lost RuntimePayloadReady treatment: $($record.Name)"
}

$descriptorEntries = @(Get-BoostLabRuntimeOperationDescriptorEntries -Manifest $manifest)
Assert-BoostLabCondition ($descriptorEntries.Count -eq 16) 'Runtime operation descriptor helper must return sixteen entries.'

$directXDescriptor = @(Resolve-BoostLabRuntimeOperationDescriptor -ToolId 'directx' -ProjectRoot $ProjectRoot -Manifest $manifest)
Assert-BoostLabCondition ($directXDescriptor.Count -eq 1) 'DirectX descriptor should resolve exactly once.'
Assert-BoostLabCondition ([bool]$directXDescriptor[0].ExternalRuntimeBlocked) 'DirectX descriptor should report external runtime blocked until module wiring.'
Assert-BoostLabCondition ([string]$directXDescriptor[0].BlockerReason -eq 'ModuleRuntimeWiringStatus') 'DirectX descriptor blocker reason mismatch.'
Assert-BoostLabCondition (-not [bool]$directXDescriptor[0].RuntimeActionExecuted) 'Descriptor resolution must not execute runtime actions.'
Assert-BoostLabCondition (-not [bool]$directXDescriptor[0].ChangesExecuted) 'Descriptor resolution must not mutate state.'

$descriptorStatuses = @(Test-BoostLabRuntimeOperationDescriptor -ProjectRoot $ProjectRoot -Manifest $manifest)
Assert-BoostLabCondition ($descriptorStatuses.Count -eq 16) 'Descriptor validation must inspect sixteen descriptors.'
Assert-BoostLabCondition (@($descriptorStatuses | Where-Object { [string]$_.DescriptorStatus -ne 'Passed' }).Count -eq 0) 'All runtime operation descriptors should pass helper validation.'
Assert-BoostLabCondition (@($descriptorStatuses | Where-Object { -not [bool]$_.DescriptorReadyForFutureExternalMode }).Count -eq 0) 'All descriptors should be ready for future external mode metadata use.'
Assert-BoostLabCondition (@($descriptorStatuses | Where-Object { [bool]$_.ModuleRuntimeWired }).Count -eq 0) 'No module should be wired to runtime operation descriptors in this phase.'

$descriptorReadiness = Get-BoostLabRuntimeOperationDescriptorReadiness -ProjectRoot $ProjectRoot -Manifest $manifest
Assert-BoostLabCondition ([int]$descriptorReadiness.TotalDescriptors -eq 16) 'Descriptor readiness total mismatch.'
Assert-BoostLabCondition ([int]$descriptorReadiness.RequiredSourceIntentBlockers -eq 16) 'Descriptor readiness required blocker mismatch.'
Assert-BoostLabCondition ([int]$descriptorReadiness.CoveredSourceIntentBlockers -eq 16) 'Descriptor readiness coverage mismatch.'
Assert-BoostLabCondition (@($descriptorReadiness.MissingSourceIntentBlockers).Count -eq 0) 'Descriptor readiness must not report missing source-intent blockers.'
Assert-BoostLabCondition ([int]$descriptorReadiness.FailedDescriptors -eq 0) 'Descriptor readiness must not report failed descriptors.'
Assert-BoostLabCondition ([int]$descriptorReadiness.ReadyForFutureExternalModeDescriptors -eq 16) 'Descriptor readiness future-mode count mismatch.'
Assert-BoostLabCondition ([int]$descriptorReadiness.NotWiredDescriptors -eq 16) 'Descriptor readiness not-wired count mismatch.'
Assert-BoostLabCondition ([bool]$descriptorReadiness.DescriptorCoverageReady) 'Descriptor coverage should be ready.'
Assert-BoostLabCondition (-not [bool]$descriptorReadiness.ExternalRuntimeReady) 'External runtime must remain blocked until modules are wired.'
Assert-BoostLabCondition (-not [bool]$descriptorReadiness.RuntimeActionExecuted) 'Descriptor readiness must not execute runtime actions.'
Assert-BoostLabCondition (-not [bool]$descriptorReadiness.ChangesExecuted) 'Descriptor readiness must not mutate state.'

$descriptorBlockers = @(Get-BoostLabExternalOperationDescriptorBlockers -ProjectRoot $ProjectRoot -Manifest $manifest)
Assert-BoostLabCondition ($descriptorBlockers.Count -eq 16) 'All descriptors should remain external blockers until module wiring is implemented.'

$runtimePayloadReadiness = Get-BoostLabRuntimePayloadReadiness -ProjectRoot $ProjectRoot -Manifest $runtimePayloadManifest
Assert-BoostLabCondition ([int]$runtimePayloadReadiness.TotalPayloadEntries -eq 5) 'Runtime payload readiness total mismatch.'
Assert-BoostLabCondition ([int]$runtimePayloadReadiness.RuntimeWiredPayloadEntries -eq 5) 'Runtime payload readiness wired count mismatch.'
Assert-BoostLabCondition ([int]$runtimePayloadReadiness.BlockedPayloadEntries -eq 0) 'Runtime payload readiness must not regress payload blockers.'
Assert-BoostLabCondition ([bool]$runtimePayloadReadiness.ExternalRuntimeReady) 'Runtime payload readiness should remain true.'

$sourceIntentReadiness = Test-BoostLabExternalRuntimeReadiness -RequestedMode 'ExternalRuntime' -ProjectRoot $ProjectRoot -Manifest $sourceIntentManifest
Assert-BoostLabCondition ([int]$sourceIntentReadiness.TotalSourceIntentEntries -eq 20) 'Source-intent readiness total mismatch.'
Assert-BoostLabCondition ([int]$sourceIntentReadiness.ExternalReadyEntries -eq 20) 'Source-intent external-ready count mismatch.'
Assert-BoostLabCondition ([int]$sourceIntentReadiness.PayloadBackedReadyEntries -eq 4) 'Source-intent payload-backed count mismatch.'
Assert-BoostLabCondition ([int]$sourceIntentReadiness.DescriptorBackedReadyEntries -eq 16) 'Source-intent descriptor-backed count mismatch.'
Assert-BoostLabCondition ([int]$sourceIntentReadiness.BlockedEntries -eq 0) 'Source-intent blocked count mismatch.'
Assert-BoostLabCondition ([int]$sourceIntentReadiness.GeneratedPayloadRequiredEntries -eq 0) 'Generated payload requirements should remain solved.'
Assert-BoostLabCondition ([bool]$sourceIntentReadiness.ExternalRuntimeReady) 'Source-intent readiness should be satisfied by descriptor-backed evidence.'
Assert-BoostLabCondition (-not [bool]$sourceIntentReadiness.ExternalPackageBuildReady) 'External package build readiness must remain false while direct module references remain.'
Assert-BoostLabCondition ([bool]$sourceIntentReadiness.ExternalPackageSourceFreeLaunchBlocked) 'External package source-free launch must report direct module references.'

$modulesWithRuntimeOperationDescriptors = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'modules') -Recurse -File -Filter '*.psm1' |
        Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw).Contains('RuntimeOperationDescriptors')
        }
)
Assert-BoostLabCondition ($modulesWithRuntimeOperationDescriptors.Count -eq 0) 'This phase must not wire runtime operation descriptors into tool modules.'

foreach ($requiredFolder in @('source-ultimate', 'source-extra', 'intake')) {
    Assert-BoostLabCondition (Test-Path -LiteralPath (Join-Path $ProjectRoot $requiredFolder) -PathType Container) "Required protected/internal folder is missing: $requiredFolder"
}

$git = Get-BoostLabGitExecutable
Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace($git)) 'Git executable was not found for protected path status validation.'
$protectedPathStatus = @(& $git -C $ProjectRoot status --short -- source-ultimate source-extra intake 2>&1)
Assert-BoostLabCondition ($LASTEXITCODE -eq 0) "Git protected path status check failed: $($protectedPathStatus -join '; ')"
Assert-BoostLabCondition ($protectedPathStatus.Count -eq 0) "Protected/internal source folders must remain clean: $($protectedPathStatus -join '; ')"

[pscustomobject]@{
    Test = 'RuntimeOperationDescriptors'
    Passed = $true
    ManifestEntries = $entries.Count
    CoveredSourceIntentBlockers = [int]$descriptorReadiness.CoveredSourceIntentBlockers
    ReadyForFutureExternalModeDescriptors = [int]$descriptorReadiness.ReadyForFutureExternalModeDescriptors
    NotWiredDescriptors = [int]$descriptorReadiness.NotWiredDescriptors
    DescriptorCoverageReady = [bool]$descriptorReadiness.DescriptorCoverageReady
    ExternalRuntimeReady = [bool]$descriptorReadiness.ExternalRuntimeReady
    RuntimePayloadReady = [bool]$runtimePayloadReadiness.ExternalRuntimeReady
    SourceIntentBlockedEntries = [int]$sourceIntentReadiness.BlockedEntries
    SourceIntentDescriptorBackedEntries = [int]$sourceIntentReadiness.DescriptorBackedReadyEntries
    ExternalPackageBuildReady = [bool]$sourceIntentReadiness.ExternalPackageBuildReady
    RuntimeActionExecuted = $false
    SourceUltimateUntouched = $true
    SourceExtraUntouched = $true
    IntakeUntouched = $true
    Message = 'Runtime operation descriptors cover the sixteen remaining source-intent blockers without wiring modules or executing runtime actions.'
}
