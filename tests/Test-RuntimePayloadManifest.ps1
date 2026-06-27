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
        throw 'Unable to determine the runtime payload manifest validator path.'
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

function Get-BoostLabTimerPayloadTextFromSource {
    param([Parameter(Mandatory)][string]$SourcePath)

    $source = Get-Content -LiteralPath $SourcePath -Raw
    $match = [regex]::Match(
        $source,
        '(?s)\$csfile\s*=\s*@''\r?\n(?<Content>.*?)\r?\n''@\r?\nSet-Content -Path "\$env:SystemDrive\\Windows\\SetTimerResolutionService\.cs"',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    Assert-BoostLabCondition $match.Success 'Timer Resolution C# payload could not be extracted from source for parity validation.'
    return [string]$match.Groups['Content'].Value
}

function Get-BoostLabDefenderPayloadTextFromSource {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [Parameter(Mandatory)]
        [string]$SourcePath
    )

    $source = Get-Content -LiteralPath $SourcePath -Raw
    $variableName = if ($ActionName -eq 'Apply') { 'DefenderOptimize' } else { 'DefenderDefault' }
    $fileStem = if ($ActionName -eq 'Apply') { 'defenderoptimize' } else { 'defenderdefault' }
    $match = [regex]::Match(
        $source,
        ('(?s)\${0}\s*=\s*@''\r?\n(?<Content>.*?)\r?\n''@\r?\nSet-Content -Path "\$env:SystemRoot\\Temp\\{1}\.ps1"' -f $variableName, $fileStem),
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    Assert-BoostLabCondition $match.Success "Defender $ActionName generated script payload could not be extracted from source for parity validation."
    return [string]$match.Groups['Content'].Value
}

function Get-BoostLabDriverNipTextFromSource {
    param([Parameter(Mandatory)][string]$SourcePath)

    $lines = Get-Content -LiteralPath $SourcePath
    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq '$nipfile = @''') {
            $start = $i + 1
            break
        }
    }
    Assert-BoostLabCondition ($start -ge 0) 'Driver Install Debloat & Settings .nip payload start marker was not found.'

    $end = -1
    for ($i = $start; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq "'@") {
            $end = $i - 1
            break
        }
    }
    Assert-BoostLabCondition ($end -ge $start) 'Driver Install Debloat & Settings .nip payload end marker was not found.'
    return (($lines[$start..$end]) -join "`r`n")
}

function Get-BoostLabStart2BytesFromSource {
    param([Parameter(Mandatory)][string]$SourcePath)

    $source = Get-Content -LiteralPath $SourcePath -Raw
    $match = [regex]::Match(
        $source,
        '-----BEGIN CERTIFICATE-----\s*(?<payload>.*?)\s*-----END CERTIFICATE-----',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    Assert-BoostLabCondition $match.Success 'Start Menu Taskbar start2.bin payload could not be extracted from source for parity validation.'
    return ,[byte[]][Convert]::FromBase64String(([string]$match.Groups['payload'].Value -replace '\s+', ''))
}

$manifestPath = Join-Path $ProjectRoot 'config\RuntimePayloadManifest.psd1'
$helperPath = Join-Path $ProjectRoot 'core\RuntimePayloads.psm1'
$sourceIntentManifestPath = Join-Path $ProjectRoot 'config\RuntimeSourceIntentManifest.psd1'
$sourceIntentHelperPath = Join-Path $ProjectRoot 'core\RuntimeSourceIntent.psm1'
$sourceVerificationPath = Join-Path $ProjectRoot 'core\SourceVerification.psm1'
foreach ($path in @($manifestPath, $helperPath, $sourceIntentManifestPath, $sourceIntentHelperPath, $sourceVerificationPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required runtime payload file is missing: $path"
}

Import-Module -Name $helperPath -Force -ErrorAction Stop
Import-Module -Name $sourceIntentHelperPath -Force -ErrorAction Stop
Import-Module -Name $sourceVerificationPath -Force -ErrorAction Stop

$manifest = Get-BoostLabRuntimePayloadManifest -ManifestPath $manifestPath
Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$manifest.SchemaVersion)) 'Runtime payload manifest must declare SchemaVersion.'
Assert-BoostLabCondition ([string]$manifest.CustomerVisible -eq 'False') 'Runtime payload manifest must not be customer-visible.'
Assert-BoostLabCondition ([string]$manifest.PayloadRoot -eq 'runtime-payloads') 'Runtime payload manifest must declare the runtime-payloads root.'
Assert-BoostLabCondition ($manifest.Contains('Entries')) 'Runtime payload manifest must contain Entries.'
Assert-BoostLabCondition ($manifest.Entries -is [System.Collections.IDictionary]) 'Runtime payload Entries must be a dictionary.'

$entries = $manifest.Entries
Assert-BoostLabCondition ($entries.Count -eq 5) "Expected 5 generated runtime payload entries, found $($entries.Count)."

$requiredEntryFields = @(
    'PayloadId'
    'PayloadGroupId'
    'ToolId'
    'SourceIntentId'
    'ModuleRelativePath'
    'SourceRelativePath'
    'GeneratedFromSourceRawSha256'
    'GeneratedFromSourceCanonicalSha256'
    'PayloadKind'
    'RuntimePayloadRelativePath'
    'HashMode'
    'RawSha256'
    'CanonicalTextSha256'
    'ExpectedLengthBytes'
    'ExtractionMode'
    'ExternalHandling'
    'RuntimeWiringStatus'
    'CustomerVisible'
    'HighRiskBlocker'
    'SourceExecutionRequired'
    'RuntimeActionExecuted'
    'ChangesExecuted'
)
$allowedPayloadKinds = @('Text', 'Binary')
$allowedHashModes = @('CanonicalText', 'RawBytes')
$allowedExternalHandling = @('GeneratedRuntimePayloadAvailable', 'GeneratedRuntimePayloadBlocked', 'ManifestOnly')
$allowedRuntimeWiringStatus = @('InternalRuntimeStillUsesSource', 'ReadyForExternalRuntime')

foreach ($entryId in @($entries.Keys | Sort-Object)) {
    $entry = $entries[$entryId]
    Assert-BoostLabCondition ($entry -is [System.Collections.IDictionary]) "Runtime payload entry must be a dictionary: $entryId"
    foreach ($field in $requiredEntryFields) {
        Assert-BoostLabCondition ($entry.Contains($field)) "Runtime payload entry is missing $field`: $entryId"
    }

    Assert-BoostLabCondition ([string]$entry.PayloadId -eq [string]$entryId) "PayloadId must match entry id: $entryId"
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$entry.ToolId)) "ToolId must not be blank: $entryId"
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$entry.SourceIntentId)) "SourceIntentId must not be blank: $entryId"
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$entry.ModuleRelativePath)) "ModuleRelativePath must not be blank: $entryId"
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$entry.SourceRelativePath)) "SourceRelativePath must not be blank: $entryId"
    Assert-BoostLabCondition ([string]$entry.PayloadKind -in $allowedPayloadKinds) "Invalid PayloadKind for $entryId`: $($entry.PayloadKind)"
    Assert-BoostLabCondition ([string]$entry.HashMode -in $allowedHashModes) "Invalid HashMode for $entryId`: $($entry.HashMode)"
    Assert-BoostLabCondition ([string]$entry.ExternalHandling -in $allowedExternalHandling) "Invalid ExternalHandling for $entryId`: $($entry.ExternalHandling)"
    Assert-BoostLabCondition ([string]$entry.RuntimeWiringStatus -in $allowedRuntimeWiringStatus) "Invalid RuntimeWiringStatus for $entryId`: $($entry.RuntimeWiringStatus)"
    Assert-BoostLabCondition ([string]$entry.GeneratedFromSourceRawSha256 -match '^[A-Fa-f0-9]{64}$') "GeneratedFromSourceRawSha256 must be a full SHA-256 hash: $entryId"
    Assert-BoostLabCondition ([string]$entry.GeneratedFromSourceCanonicalSha256 -match '^[A-Fa-f0-9]{64}$') "GeneratedFromSourceCanonicalSha256 must be a full SHA-256 hash: $entryId"
    Assert-BoostLabCondition ([string]$entry.RawSha256 -match '^[A-Fa-f0-9]{64}$') "RawSha256 must be a full SHA-256 hash: $entryId"
    if ([string]$entry.HashMode -eq 'CanonicalText') {
        Assert-BoostLabCondition ([string]$entry.CanonicalTextSha256 -match '^[A-Fa-f0-9]{64}$') "CanonicalTextSha256 must be a full SHA-256 hash: $entryId"
    }
    else {
        Assert-BoostLabCondition ([string]::IsNullOrWhiteSpace([string]$entry.CanonicalTextSha256)) "Raw-byte payload must not declare a canonical text hash: $entryId"
    }
    Assert-BoostLabCondition ([string]$entry.CustomerVisible -eq 'False') "Entry must not be customer-visible: $entryId"
    Assert-BoostLabCondition ([string]$entry.SourceExecutionRequired -eq 'False') "Static payload extraction must not require source execution: $entryId"
    Assert-BoostLabCondition ([string]$entry.RuntimeActionExecuted -eq 'False') "Payload manifest must not record runtime action execution: $entryId"
    Assert-BoostLabCondition ([string]$entry.ChangesExecuted -eq 'False') "Payload manifest must not record state mutation: $entryId"
    Assert-BoostLabCondition ([int]$entry.ExpectedLengthBytes -gt 0) "ExpectedLengthBytes must be positive: $entryId"
}

$manifestText = Get-Content -LiteralPath $manifestPath -Raw
foreach ($forbiddenText in @('Codex', 'OpenAI', 'ChatGPT', 'prompt', 'scaffold', 'pasted-text', '-----BEGIN CERTIFICATE-----', "@'", '@"')) {
    Assert-BoostLabCondition (-not $manifestText.Contains($forbiddenText)) "Runtime payload manifest contains forbidden embedded/internal text: $forbiddenText"
}
$longBase64LikeRuns = @([regex]::Matches($manifestText, '[A-Za-z0-9+/]{160,}={0,2}'))
Assert-BoostLabCondition ($longBase64LikeRuns.Count -eq 0) 'Runtime payload manifest appears to contain embedded payload body text.'

$sourceIntentManifest = Import-PowerShellDataFile -LiteralPath $sourceIntentManifestPath
foreach ($entryId in @($entries.Keys | Sort-Object)) {
    $entry = $entries[$entryId]
    Assert-BoostLabCondition ($sourceIntentManifest.Entries.Contains([string]$entry.SourceIntentId)) "Runtime payload entry references unknown source intent: $entryId"
    $sourceIntent = $sourceIntentManifest.Entries[[string]$entry.SourceIntentId]
    Assert-BoostLabCondition ([string]$sourceIntent.ToolId -eq [string]$entry.ToolId) "Runtime payload source intent tool mismatch: $entryId"
}

$payloadStatuses = @(Test-BoostLabRuntimePayload -ProjectRoot $ProjectRoot -Manifest $manifest)
Assert-BoostLabCondition ($payloadStatuses.Count -eq 5) 'Runtime payload verification should report five payload entries.'
$readyRuntimePayloadIds = @(
    'defender-optimize-apply-script'
    'defender-optimize-default-script'
    'driver-install-debloat-settings-nvidia-profile'
    'start-menu-taskbar-start2-bin'
    'timer-resolution-csharp-service'
)
$blockedRuntimePayloadIds = @()
foreach ($payloadStatus in $payloadStatuses) {
    Assert-BoostLabCondition ([bool]$payloadStatus.Exists) "Generated runtime payload file is missing: $($payloadStatus.PayloadId)"
    Assert-BoostLabCondition ([string]$payloadStatus.ChecksumStatus -eq 'Passed') "Generated runtime payload hash mismatch: $($payloadStatus.PayloadId)"
    Assert-BoostLabCondition ([string]$payloadStatus.LengthStatus -eq 'Passed') "Generated runtime payload length mismatch: $($payloadStatus.PayloadId)"
    Assert-BoostLabCondition ([bool]$payloadStatus.PayloadArtifactReady) "Generated runtime payload should be artifact-ready: $($payloadStatus.PayloadId)"
    if ([string]$payloadStatus.PayloadId -in $readyRuntimePayloadIds) {
        Assert-BoostLabCondition (-not [bool]$payloadStatus.ExternalRuntimeBlocked) "Runtime-wired payload should be ready for external runtime: $($payloadStatus.PayloadId)"
        Assert-BoostLabCondition ([string]$payloadStatus.RuntimeWiringStatus -eq 'ReadyForExternalRuntime') "Runtime-wired payload wiring status mismatch: $($payloadStatus.PayloadId)"
        Assert-BoostLabCondition ([string]$payloadStatus.BlockerReason -eq '') "Runtime-wired payload must not report a blocker reason: $($payloadStatus.PayloadId)"
    }
    else {
        Assert-BoostLabCondition ([string]$payloadStatus.PayloadId -in $blockedRuntimePayloadIds) "Unexpected externally blocked payload id: $($payloadStatus.PayloadId)"
        Assert-BoostLabCondition ([bool]$payloadStatus.ExternalRuntimeBlocked) "Payload should remain externally blocked until module rewiring: $($payloadStatus.PayloadId)"
        Assert-BoostLabCondition ([string]$payloadStatus.BlockerReason -eq 'InternalRuntimeStillUsesSource') "Payload blocker reason mismatch: $($payloadStatus.PayloadId)"
    }
    Assert-BoostLabCondition (-not [bool]$payloadStatus.RuntimeActionExecuted) "Runtime payload verification must not execute runtime actions: $($payloadStatus.PayloadId)"
    Assert-BoostLabCondition (-not [bool]$payloadStatus.ChangesExecuted) "Runtime payload verification must not mutate state: $($payloadStatus.PayloadId)"
}

$readiness = Get-BoostLabRuntimePayloadReadiness -ProjectRoot $ProjectRoot -Manifest $manifest
Assert-BoostLabCondition ([int]$readiness.TotalPayloadEntries -eq 5) 'Runtime payload readiness must report five entries.'
Assert-BoostLabCondition ([int]$readiness.GeneratedRuntimePayloadAvailableEntries -eq 5) 'All generated runtime payload artifacts should be available.'
Assert-BoostLabCondition ([int]$readiness.MissingPayloadEntries -eq 0) 'Generated runtime payload readiness must not report missing payloads.'
Assert-BoostLabCondition ([int]$readiness.FailedPayloadEntries -eq 0) 'Generated runtime payload readiness must not report failed payloads.'
Assert-BoostLabCondition ([int]$readiness.NotWiredPayloadEntries -eq 0) 'All generated runtime payload entries should be runtime-wired after the Timer Resolution payload rewire.'
Assert-BoostLabCondition ([int]$readiness.RuntimeWiredPayloadEntries -eq 5) 'Exactly five generated payload entries should be runtime-wired.'
Assert-BoostLabCondition ([int]$readiness.BlockedPayloadEntries -eq 0) 'No generated payload entry should remain an external runtime blocker.'
Assert-BoostLabCondition ('defender-optimize-apply-script' -in @($readiness.ReadyForExternalRuntimePayloadIds)) 'Defender Optimize Apply payload should be listed as ready for external runtime.'
Assert-BoostLabCondition ('defender-optimize-default-script' -in @($readiness.ReadyForExternalRuntimePayloadIds)) 'Defender Optimize Default payload should be listed as ready for external runtime.'
Assert-BoostLabCondition ('driver-install-debloat-settings-nvidia-profile' -in @($readiness.ReadyForExternalRuntimePayloadIds)) 'DIDS .nip payload should be listed as ready for external runtime.'
Assert-BoostLabCondition ('start-menu-taskbar-start2-bin' -in @($readiness.ReadyForExternalRuntimePayloadIds)) 'Start Menu Taskbar start2.bin payload should be listed as ready for external runtime.'
Assert-BoostLabCondition ('timer-resolution-csharp-service' -in @($readiness.ReadyForExternalRuntimePayloadIds)) 'Timer Resolution C# service payload should be listed as ready for external runtime.'
Assert-BoostLabCondition ('defender-optimize-apply-script' -notin @($readiness.RuntimePayloadBlockerIds)) 'Defender Optimize Apply payload must not remain in the runtime payload blocker list.'
Assert-BoostLabCondition ('defender-optimize-default-script' -notin @($readiness.RuntimePayloadBlockerIds)) 'Defender Optimize Default payload must not remain in the runtime payload blocker list.'
Assert-BoostLabCondition ('driver-install-debloat-settings-nvidia-profile' -notin @($readiness.RuntimePayloadBlockerIds)) 'DIDS .nip payload must not remain in the runtime payload blocker list.'
Assert-BoostLabCondition ('start-menu-taskbar-start2-bin' -notin @($readiness.RuntimePayloadBlockerIds)) 'Start Menu Taskbar start2.bin payload must not remain in the runtime payload blocker list.'
Assert-BoostLabCondition ('timer-resolution-csharp-service' -notin @($readiness.RuntimePayloadBlockerIds)) 'Timer Resolution must not remain in the generated runtime payload blocker list.'
Assert-BoostLabCondition ([bool]$readiness.ExternalRuntimeReady) 'Generated runtime payload readiness should be true after all payload entries are runtime-wired.'
Assert-BoostLabCondition (-not [bool]$readiness.RuntimeActionExecuted) 'Readiness reporting must not execute runtime actions.'
Assert-BoostLabCondition (-not [bool]$readiness.ChangesExecuted) 'Readiness reporting must not mutate state.'

$sourceIntentReadiness = Test-BoostLabExternalRuntimeReadiness -RequestedMode 'ExternalRuntime' -ProjectRoot $ProjectRoot
Assert-BoostLabCondition ([int]$sourceIntentReadiness.TotalPayloads -eq 5) 'Combined external readiness should report five runtime payloads.'
Assert-BoostLabCondition ([int]$sourceIntentReadiness.ReadyPayloads -eq 5) 'Combined external readiness should report five ready runtime payloads.'
Assert-BoostLabCondition ([int]$sourceIntentReadiness.BlockedPayloads -eq 0) 'Combined external readiness should not report runtime payload blockers.'
Assert-BoostLabCondition ([int]$sourceIntentReadiness.PayloadBackedReadyEntries -eq 4) 'Combined external readiness should retain four payload-backed source intents.'

$expectedHighRiskTools = @(
    'defender-optimize-assistant'
    'driver-install-debloat-settings'
    'start-menu-taskbar'
    'timer-resolution-assistant'
)
$actualHighRiskTools = @($readiness.HighRiskBlockerTools | ForEach-Object { [string]$_ } | Sort-Object)
Assert-BoostLabCondition (($actualHighRiskTools -join '|') -eq (($expectedHighRiskTools | Sort-Object) -join '|')) "Runtime payload high-risk tool list mismatch: $($actualHighRiskTools -join ', ')"

$timerPayload = @(Resolve-BoostLabRuntimePayload -ProjectRoot $ProjectRoot -PayloadId 'timer-resolution-csharp-service' -Manifest $manifest)
Assert-BoostLabCondition ($timerPayload.Count -eq 1) 'Timer Resolution runtime payload should resolve exactly once.'
Assert-BoostLabCondition ([bool]$timerPayload[0].PayloadExists) 'Timer Resolution runtime payload should exist.'
Assert-BoostLabCondition (-not [bool]$timerPayload[0].ExternalRuntimeBlocked) 'Timer Resolution runtime payload should no longer be an external runtime blocker.'
Assert-BoostLabCondition (-not [bool]$timerPayload[0].RuntimeActionExecuted) 'Runtime payload resolution must not execute runtime actions.'

$timerEntry = $entries['timer-resolution-csharp-service']
Assert-BoostLabCondition ([string]$timerEntry.RuntimePayloadRelativePath -eq 'runtime-payloads/timer-resolution-assistant/SetTimerResolutionService.cs') 'Timer Resolution runtime payload path mismatch.'
Assert-BoostLabCondition ([string]$timerEntry.RuntimePayloadRelativePath -notmatch '^(source-ultimate|source-extra|intake)(/|\\)') 'Timer Resolution runtime payload must not point at protected source or intake paths.'
Assert-BoostLabCondition ([string]$timerEntry.PayloadKind -eq 'Text') 'Timer Resolution runtime payload must be declared text.'
Assert-BoostLabCondition ([string]$timerEntry.HashMode -eq 'CanonicalText') 'Timer Resolution runtime payload must use canonical text hash mode.'
Assert-BoostLabCondition ([string]$timerEntry.CanonicalTextSha256 -match '^[A-Fa-f0-9]{64}$') 'Timer Resolution runtime payload must declare a canonical text hash.'
$timerPayloadStatus = $payloadStatuses | Where-Object { [string]$_.PayloadId -eq 'timer-resolution-csharp-service' } | Select-Object -First 1
Assert-BoostLabCondition ([string]$timerPayloadStatus.VerificationMode -in @('ExactRawSha256', 'CanonicalTextSha256')) 'Timer Resolution runtime payload must verify by raw or canonical text SHA-256.'
Assert-BoostLabCondition ([string]$timerPayloadStatus.RuntimeWiringStatus -eq 'ReadyForExternalRuntime') 'Timer Resolution runtime payload status mismatch.'

$didsPayload = @(Resolve-BoostLabRuntimePayload -ProjectRoot $ProjectRoot -PayloadId 'driver-install-debloat-settings-nvidia-profile' -Manifest $manifest)
Assert-BoostLabCondition ($didsPayload.Count -eq 1) 'Driver Install Debloat & Settings runtime payload should resolve exactly once.'
Assert-BoostLabCondition ([bool]$didsPayload[0].PayloadExists) 'Driver Install Debloat & Settings runtime payload should exist.'
Assert-BoostLabCondition (-not [bool]$didsPayload[0].ExternalRuntimeBlocked) 'Driver Install Debloat & Settings .nip payload should no longer be an external runtime blocker.'
Assert-BoostLabCondition (-not [bool]$didsPayload[0].RuntimeActionExecuted) 'Runtime payload resolution must not execute runtime actions.'

$start2Payload = @(Resolve-BoostLabRuntimePayload -ProjectRoot $ProjectRoot -PayloadId 'start-menu-taskbar-start2-bin' -Manifest $manifest)
Assert-BoostLabCondition ($start2Payload.Count -eq 1) 'Start Menu Taskbar start2.bin runtime payload should resolve exactly once.'
Assert-BoostLabCondition ([bool]$start2Payload[0].PayloadExists) 'Start Menu Taskbar start2.bin runtime payload should exist.'
Assert-BoostLabCondition (-not [bool]$start2Payload[0].ExternalRuntimeBlocked) 'Start Menu Taskbar start2.bin payload should no longer be an external runtime blocker.'
Assert-BoostLabCondition (-not [bool]$start2Payload[0].RuntimeActionExecuted) 'Runtime payload resolution must not execute runtime actions.'

$start2Entry = $entries['start-menu-taskbar-start2-bin']
Assert-BoostLabCondition ([string]$start2Entry.RuntimePayloadRelativePath -eq 'runtime-payloads/start-menu-taskbar/start2.bin') 'Start Menu Taskbar start2.bin runtime payload path mismatch.'
Assert-BoostLabCondition ([string]$start2Entry.RuntimePayloadRelativePath -notmatch '^(source-ultimate|source-extra|intake)(/|\\)') 'Start Menu Taskbar start2.bin runtime payload must not point at protected source or intake paths.'
Assert-BoostLabCondition ([string]$start2Entry.PayloadKind -eq 'Binary') 'Start Menu Taskbar start2.bin runtime payload must be declared binary.'
Assert-BoostLabCondition ([string]$start2Entry.HashMode -eq 'RawBytes') 'Start Menu Taskbar start2.bin runtime payload must use raw-byte hash mode.'
Assert-BoostLabCondition ([string]$start2Entry.CanonicalTextSha256 -eq '') 'Start Menu Taskbar start2.bin runtime payload must not declare a canonical text hash.'
$start2PayloadStatus = $payloadStatuses | Where-Object { [string]$_.PayloadId -eq 'start-menu-taskbar-start2-bin' } | Select-Object -First 1
Assert-BoostLabCondition ([string]$start2PayloadStatus.VerificationMode -eq 'RawBytesSha256') 'Start Menu Taskbar start2.bin runtime payload must verify by raw-byte SHA-256.'

$defenderPayloads = @(Resolve-BoostLabRuntimePayload -ProjectRoot $ProjectRoot -ToolId 'defender-optimize-assistant' -Manifest $manifest)
Assert-BoostLabCondition ($defenderPayloads.Count -eq 2) 'Defender Optimize Assistant should have two generated script payload entries.'
foreach ($defenderPayload in $defenderPayloads) {
    Assert-BoostLabCondition ([bool]$defenderPayload.PayloadExists) "Defender Optimize Assistant runtime payload should exist: $($defenderPayload.PayloadId)"
    Assert-BoostLabCondition (-not [bool]$defenderPayload.ExternalRuntimeBlocked) "Defender Optimize Assistant runtime payload should no longer be an external runtime blocker: $($defenderPayload.PayloadId)"
    Assert-BoostLabCondition (-not [bool]$defenderPayload.RuntimeActionExecuted) 'Runtime payload resolution must not execute runtime actions.'
}

$defenderApplyEntry = $entries['defender-optimize-apply-script']
$defenderDefaultEntry = $entries['defender-optimize-default-script']
Assert-BoostLabCondition ([string]$defenderApplyEntry.RuntimePayloadRelativePath -eq 'runtime-payloads/defender-optimize-assistant/defenderoptimize.ps1') 'Defender Optimize Apply runtime payload path mismatch.'
Assert-BoostLabCondition ([string]$defenderDefaultEntry.RuntimePayloadRelativePath -eq 'runtime-payloads/defender-optimize-assistant/defenderdefault.ps1') 'Defender Optimize Default runtime payload path mismatch.'
foreach ($defenderEntry in @($defenderApplyEntry, $defenderDefaultEntry)) {
    Assert-BoostLabCondition ([string]$defenderEntry.RuntimePayloadRelativePath -notmatch '^(source-ultimate|source-extra|intake)(/|\\)') "Defender Optimize runtime payload must not point at protected source or intake paths: $($defenderEntry.PayloadId)"
    Assert-BoostLabCondition ([string]$defenderEntry.PayloadKind -eq 'Text') "Defender Optimize runtime payload must be declared text: $($defenderEntry.PayloadId)"
    Assert-BoostLabCondition ([string]$defenderEntry.HashMode -eq 'CanonicalText') "Defender Optimize runtime payload must use canonical text hash mode: $($defenderEntry.PayloadId)"
    Assert-BoostLabCondition ([string]$defenderEntry.CanonicalTextSha256 -match '^[A-Fa-f0-9]{64}$') "Defender Optimize runtime payload must declare a canonical text hash: $($defenderEntry.PayloadId)"
}
$defenderPayloadStatuses = @($payloadStatuses | Where-Object { [string]$_.ToolId -eq 'defender-optimize-assistant' })
Assert-BoostLabCondition ($defenderPayloadStatuses.Count -eq 2) 'Defender Optimize Assistant should have two verified runtime payload statuses.'
foreach ($defenderPayloadStatus in $defenderPayloadStatuses) {
    Assert-BoostLabCondition ([string]$defenderPayloadStatus.ChecksumStatus -eq 'Passed') "Defender Optimize runtime payload hash must pass: $($defenderPayloadStatus.PayloadId)"
    Assert-BoostLabCondition ([string]$defenderPayloadStatus.VerificationMode -in @('ExactRawSha256', 'CanonicalTextSha256')) "Defender Optimize runtime payload must verify by raw or canonical text SHA-256: $($defenderPayloadStatus.PayloadId)"
    Assert-BoostLabCondition ([string]$defenderPayloadStatus.RuntimeWiringStatus -eq 'ReadyForExternalRuntime') "Defender Optimize runtime payload status mismatch: $($defenderPayloadStatus.PayloadId)"
}

$payloadParityChecks = @(
    @{
        PayloadId = 'timer-resolution-csharp-service'
        RelativePath = 'runtime-payloads/timer-resolution-assistant/SetTimerResolutionService.cs'
        ExpectedText = Get-BoostLabTimerPayloadTextFromSource -SourcePath (Join-Path $ProjectRoot 'source-ultimate\8 Advanced\6 Timer Resolution Assistant.ps1')
    }
    @{
        PayloadId = 'defender-optimize-apply-script'
        RelativePath = 'runtime-payloads/defender-optimize-assistant/defenderoptimize.ps1'
        ExpectedText = Get-BoostLabDefenderPayloadTextFromSource -ActionName 'Apply' -SourcePath (Join-Path $ProjectRoot 'source-ultimate\8 Advanced\7 Defender Optimize Assistant.ps1')
    }
    @{
        PayloadId = 'defender-optimize-default-script'
        RelativePath = 'runtime-payloads/defender-optimize-assistant/defenderdefault.ps1'
        ExpectedText = Get-BoostLabDefenderPayloadTextFromSource -ActionName 'Default' -SourcePath (Join-Path $ProjectRoot 'source-ultimate\8 Advanced\7 Defender Optimize Assistant.ps1')
    }
    @{
        PayloadId = 'driver-install-debloat-settings-nvidia-profile'
        RelativePath = 'runtime-payloads/driver-install-debloat-settings/inspector.nip'
        ExpectedText = Get-BoostLabDriverNipTextFromSource -SourcePath (Join-Path $ProjectRoot 'source-ultimate\5 Graphics\1 Driver Install Debloat & Settings.ps1')
    }
)
foreach ($check in $payloadParityChecks) {
    $payloadPath = Join-Path $ProjectRoot ([string]$check.RelativePath).Replace('/', '\')
    $payloadText = Get-Content -LiteralPath $payloadPath -Raw
    $expectedText = [string]$check.ExpectedText
    $payloadCanonical = Get-BoostLabSha256Hex -Bytes (ConvertTo-BoostLabCanonicalSourceTextBytes -Bytes ([Text.UTF8Encoding]::new($false).GetBytes($payloadText)))
    $expectedCanonical = Get-BoostLabSha256Hex -Bytes (ConvertTo-BoostLabCanonicalSourceTextBytes -Bytes ([Text.UTF8Encoding]::new($false).GetBytes($expectedText)))
    Assert-BoostLabCondition ($payloadCanonical -eq $expectedCanonical) "Generated runtime text payload does not match static source extraction: $($check.PayloadId)"
}

$startBytesFromSource = Get-BoostLabStart2BytesFromSource -SourcePath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\1 Start Menu Taskbar.ps1')
$startPayloadPath = Join-Path $ProjectRoot 'runtime-payloads\start-menu-taskbar\start2.bin'
$startPayloadBytes = [IO.File]::ReadAllBytes($startPayloadPath)
Assert-BoostLabCondition ($startPayloadBytes.Length -eq $startBytesFromSource.Length) 'Generated start2.bin length does not match static source extraction.'
Assert-BoostLabCondition ((Get-BoostLabSha256Hex -Bytes $startPayloadBytes) -eq (Get-BoostLabSha256Hex -Bytes $startBytesFromSource)) 'Generated start2.bin hash does not match static source extraction.'
Assert-BoostLabCondition ((Get-BoostLabSha256Hex -Bytes $startPayloadBytes) -eq '21EAF7925A26A59880D799509C5E49D4034B36BD86D84D035A50D17D6A32206D') 'Generated start2.bin hash does not match the protected module expectation.'
Assert-BoostLabCondition ($startPayloadBytes.Length -eq 4540) 'Generated start2.bin length does not match the protected module expectation.'

$modulesWithRuntimePayloads = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'modules') -Recurse -File -Filter '*.psm1' |
        Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw).Contains('RuntimePayload')
        }
)
$moduleRelativePathsWithRuntimePayloads = @($modulesWithRuntimePayloads | ForEach-Object { $_.FullName.Substring($ProjectRoot.Length + 1).Replace('\', '/') } | Sort-Object)
Assert-BoostLabCondition (($moduleRelativePathsWithRuntimePayloads -join '|') -eq 'modules/Advanced/defender-optimize-assistant.psm1|modules/Advanced/timer-resolution-assistant.psm1|modules/Graphics/driver-install-debloat-settings.psm1|modules/Windows/start-menu-taskbar.psm1') "Only Defender Optimize Assistant, Timer Resolution Assistant, Driver Install Debloat & Settings, and Start Menu Taskbar may be wired to runtime payloads in this phase: $($moduleRelativePathsWithRuntimePayloads -join ', ')"

$gitPath = Get-BoostLabGitExecutable
Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace($gitPath)) 'Git executable was not found for protected source/intake working-tree guard.'
$protectedSourceChanges = @(
    & $gitPath -C $ProjectRoot status --short -- 'source-ultimate' 'source-extra' 'intake'
)
Assert-BoostLabCondition ($LASTEXITCODE -eq 0) 'Unable to inspect protected source/intake working-tree status.'
Assert-BoostLabCondition ($protectedSourceChanges.Count -eq 0) "Protected source/internal paths have working-tree modifications: $($protectedSourceChanges -join '; ')"

[pscustomobject]@{
    Test = 'RuntimePayloadManifest'
    Passed = $true
    ManifestEntries = $entries.Count
    PayloadArtifactsVerified = $payloadStatuses.Count
    HighRiskBlockerTools = $actualHighRiskTools
    ExternalRuntimeReady = [bool]$readiness.ExternalRuntimeReady
    NotWiredPayloadEntries = [int]$readiness.NotWiredPayloadEntries
    RuntimeWiredPayloadEntries = [int]$readiness.RuntimeWiredPayloadEntries
    RuntimeActionExecuted = $false
    SourceUltimateUntouched = $true
    SourceExtraUntouched = $true
    IntakeUntouched = $true
    Message = 'Generated runtime payload artifacts are present and hash-verified; Defender Optimize Apply/Default, DIDS .nip, Start Menu Taskbar start2.bin, and Timer Resolution C# service payload are runtime-wired.'
}
