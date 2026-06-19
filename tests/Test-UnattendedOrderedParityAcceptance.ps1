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
        throw 'Unable to determine the Unattended ordered parity validator path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
. (Join-Path $ProjectRoot 'tests\BoostLab.ParityStatusBaseline.ps1')

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

function Assert-BoostLabTextContains {
    param(
        [AllowNull()]
        [string]$Text,

        [Parameter(Mandatory)]
        [string]$Needle,

        [Parameter(Mandatory)]
        [string]$Description
    )

    if ([string]::IsNullOrEmpty($Text) -or -not $Text.Contains($Needle)) {
        throw "$Description missing expected text: $Needle"
    }
}

function Get-BoostLabPhaseStartOrderedTarget {
    param(
        [Parameter(Mandatory)]
        [hashtable]$ParityBaseline,

        [Parameter(Mandatory)]
        [hashtable]$ExecutionOrder
    )

    foreach ($stage in @($ExecutionOrder.Stages)) {
        foreach ($tool in @($stage.Tools)) {
            $toolId = [string]$tool.ToolId
            $record = @($ParityBaseline.Tools | Where-Object { [string]$_.ToolId -eq $toolId }) | Select-Object -First 1
            if ($null -eq $record) {
                throw "Missing parity baseline record for ordered tool: $toolId"
            }

            $isFinal = if ($toolId -eq 'unattended') {
                $false
            }
            else {
                Test-BoostLabParityRecordFinal -Record $record
            }
            if (-not $isFinal) {
                return $record
            }
        }
    }

    return $null
}

$inventoryAssertion = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
$inventoryBaseline = $inventoryAssertion.Baseline
$inventorySnapshot = $inventoryAssertion.Snapshot
$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Refresh\unattended.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\2 Refresh\2 Unattended.ps1'
$migrationPath = Join-Path $ProjectRoot 'docs\migrations\unattended.md'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'

foreach ($path in @($configPath, $modulePath, $sourcePath, $migrationPath, $actionPlanPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required Unattended parity file was not found: $path"
}

$phaseStartTarget = Get-BoostLabPhaseStartOrderedTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ($null -ne $phaseStartTarget) 'Could not determine Phase 111 starting ordered target.'
Assert-BoostLabCondition ([string]$phaseStartTarget.ToolId -eq 'unattended') 'Unattended must be the ordered parity target resolved by this phase.'

$expectedSourceHash = '0974CFCC4FFC4B21BF4EB62172C0C1C31FF32AB147878A4610FC19C95DF74338'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Unattended source hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."

$sourceText = Get-Content -Raw -LiteralPath $sourcePath
foreach ($needle in @(
    'Set-Content -Path "$env:SystemRoot\Temp\autounattendtemplate.xml" -Value $AutoUnattend -Force',
    '$username = Read-Host -Prompt "Enter Account Name (No Spaces/Spacebar)"',
    '(Get-Content $path) -replace "@",$username | out-file $path',
    'Get-Content "$env:SystemRoot\Temp\autounattendtemplate.xml" | Set-Content -Encoding utf8 "$env:SystemRoot\Temp\autounattend.xml" -Force',
    'Remove-Item -Path "$env:SystemRoot\Temp\autounattendtemplate.xml" -Force | Out-Null',
    'Move-Item -Path $file -Destination $destination -Force',
    'Start-Process $destination',
    'BypassTPMCheck',
    'BypassRAMCheck',
    'BypassSecureBootCheck',
    'BypassCPUCheck',
    'BypassStorageCheck'
)) {
    Assert-BoostLabTextContains -Text $sourceText -Needle $needle -Description 'Unattended Ultimate source behavior'
}
foreach ($forbiddenSourceNeedle in @('Invoke-WebRequest', 'Restart-Computer', 'shutdown.exe', 'setup.exe', 'mediacreationtool')) {
    Assert-BoostLabCondition (-not $sourceText.Contains($forbiddenSourceNeedle)) "Unattended source unexpectedly contains unrelated behavior: $forbiddenSourceNeedle"
}

$stages = Import-PowerShellDataFile -LiteralPath $configPath
$refreshStage = @($stages.Stages | Where-Object { $_.Name -eq 'Refresh' })[0]
$unattendedTool = @($refreshStage.Tools | Where-Object { $_.Id -eq 'unattended' })[0]
Assert-BoostLabCondition ($null -ne $unattendedTool) 'Unattended stage metadata is missing.'
Assert-BoostLabCondition ([int]$unattendedTool.Order -eq 2) 'Unattended must remain Refresh order 2.'
Assert-BoostLabCondition ((@($unattendedTool.Actions) -join ',') -eq 'Analyze,Apply') 'Unattended must expose only Analyze and Apply.'
Assert-BoostLabCondition (-not ('Default' -in @($unattendedTool.Actions))) 'Unattended must not expose Default.'
Assert-BoostLabCondition (-not ('Restore' -in @($unattendedTool.Actions))) 'Unattended must not expose Restore.'
Assert-BoostLabCondition (-not [bool]$unattendedTool.Capabilities.SupportsDefault) 'Unattended SupportsDefault must remain false.'
Assert-BoostLabCondition (-not [bool]$unattendedTool.Capabilities.SupportsRestore) 'Unattended SupportsRestore must remain false.'

$moduleText = Get-Content -Raw -LiteralPath $modulePath
foreach ($needle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'')',
    '$script:BoostLabUnattendedSourceHash',
    'Show-BoostLabUnattendedSelectionDialog',
    'Copy-BoostLabUnattendedBackup',
    'Save-BoostLabUnattendedState',
    'New-BoostLabUnattendedVerificationResult',
    'Get-BoostLabUnattendedHostScope',
    'SupportedForWindows11Preparation',
    'DriveType = 2',
    'Move-Item -LiteralPath $SourcePath -Destination $DestinationPath -Force',
    'Start-Process -FilePath $Path -ErrorAction Stop',
    'Windows 10 optimization branches remain unsupported'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'Unattended BoostLab module'
}
foreach ($forbiddenModuleNeedle in @('Invoke-WebRequest', 'Invoke-RestMethod', 'Start-BitsTransfer', 'Restart-Computer', 'Stop-Computer', 'diskpart', 'format.com', 'setup.exe', 'mediacreationtool')) {
    Assert-BoostLabCondition (-not $moduleText.Contains($forbiddenModuleNeedle)) "Unattended module contains unapproved behavior: $forbiddenModuleNeedle"
}

$module = Import-Module -Name $modulePath -Force -PassThru -Prefix 'ParityUnattendedTest' -Scope Local -DisableNameChecking -ErrorAction Stop
try {
    $template = & $module { $script:BoostLabUnattendedTemplate }
    $sha256Template = [Security.Cryptography.SHA256]::Create()
    try {
        $templateHash = [BitConverter]::ToString(
            $sha256Template.ComputeHash([Text.Encoding]::UTF8.GetBytes($template))
        ).Replace('-', '')
    }
    finally {
        $sha256Template.Dispose()
    }
    $expectedPayloadHash = '6293F4C6121B44A297B67BAF83BA165FB1330FF0749EEEE3601CEE941AA06F65'
    Assert-BoostLabCondition ($templateHash -eq $expectedPayloadHash) "Unattended payload hash mismatch. Expected $expectedPayloadHash, found $templateHash."

    $generated = $template.Replace('@', 'Yazan')
    foreach ($requiredGeneratedText in @(
        '<Name>Yazan</Name>',
        'net user Yazan /active:Yes',
        'net user Yazan /passwordreq:no',
        'BypassTPMCheck',
        'BypassRAMCheck',
        'BypassSecureBootCheck',
        'BypassCPUCheck',
        'BypassStorageCheck',
        '<DynamicUpdate>',
        '<Enable>false</Enable>'
    )) {
        Assert-BoostLabTextContains -Text $generated -Needle $requiredGeneratedText -Description 'Generated Unattended payload'
    }

    $analysis = & $module {
        Get-BoostLabUnattendedAnalyzeData `
            -WindowsInfoReader { [pscustomobject]@{ Caption = 'Windows 10 Pro'; Build = 19045 } } `
            -DriveReader { @([pscustomobject]@{ Root = 'E:\'; Label = 'INSTALL'; FreeSpace = 100GB }) }
    }
    Assert-BoostLabCondition ([bool]$analysis.HostSupportedForWindows11Preparation) 'Analyze must allow Windows 10 host usage for Windows 11 preparation.'
    Assert-BoostLabCondition ([string]$analysis.PayloadTarget -eq 'Windows 11') 'Analyze must identify the payload target as Windows 11.'
    Assert-BoostLabCondition ([string]$analysis.Windows10OptimizationBranches -match 'Unsupported') 'Analyze must keep Windows 10 optimization branches unsupported.'
    Assert-BoostLabCondition (-not [bool]$analysis.ChangesExecuted) 'Analyze must be read-only.'

    $actionCommand = Get-Command -Name 'Invoke-ParityUnattendedTestBoostLabToolAction' -Module $module.Name -ErrorAction Stop
    $cancelled = & $actionCommand -ActionName 'Apply' -Confirmed:$false
    Assert-BoostLabCondition ([bool]$cancelled.Cancelled) 'Unconfirmed Apply must be cancelled before file generation.'
    Assert-BoostLabCondition ([string]$cancelled.CommandStatus -eq 'Cancelled') 'Unconfirmed Apply must not execute changes.'
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    $applyPlan = New-BoostLabActionPlan -ToolMetadata $unattendedTool -ActionName 'Apply' -IsDryRun:$false
    Assert-BoostLabCondition ([bool]$applyPlan.NeedsExplicitConfirmation) 'Unattended Apply must require explicit confirmation.'
    Assert-BoostLabCondition (-not [bool]$applyPlan.CanReboot) 'Unattended Apply must not claim it reboots.'
    $planText = @(
        $applyPlan.Summary
        @($applyPlan.PlannedChanges)
        @($applyPlan.SideEffects)
        $applyPlan.ConfirmationMessage
    ) -join "`n"
    foreach ($needle in @(
        'Create the approved Windows 11 autounattend.xml',
        'blank-password local administrator',
        'TPM, RAM, Secure Boot, CPU, and storage',
        'No installation or reboot starts now'
    )) {
        Assert-BoostLabTextContains -Text $planText -Needle $needle -Description 'Unattended Action Plan'
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$unattendedRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'unattended' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $unattendedRecord) 'Unattended parity record was not found.'
Assert-BoostLabCondition ([string]$unattendedRecord.ImplementationLevel -eq 'NearParityControlled') 'Unattended must be NearParityControlled.'
Assert-BoostLabCondition ([string]$unattendedRecord.UltimateParity -eq 'Partial') 'Unattended accepted near parity must not be counted as full parity.'
Assert-BoostLabCondition (-not [bool]$unattendedRecord.YazanFinalException) 'Unattended must not use YazanFinalException.'
Assert-BoostLabCondition ([bool]$unattendedRecord.YazanAcceptedNearParity) 'Unattended must be marked YazanAcceptedNearParity.'
Assert-BoostLabCondition ([string]$unattendedRecord.FinalProgressStatus -eq 'DoneYazanAcceptedNearParity') 'Unattended final progress status mismatch.'
Assert-BoostLabTextContains -Text ([string]$unattendedRecord.GapSummary) -Needle 'no source branch is omitted' -Description 'Unattended parity gap summary'

$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ($null -ne $nextTarget) 'Next ordered parity target was not found.'
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq 'to-bios') 'First pending ordered target must advance to To BIOS after Updates Drivers Block Yazan final exception.'

$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
Assert-BoostLabCondition ([int]$categoryCounts['ParityImplemented'] -eq 16) 'Ultimate parity implemented count changed unexpectedly.'
Assert-BoostLabCondition ([int]$categoryCounts['NearParityControlled'] -eq 17) 'NearParityControlled count changed unexpectedly.'
Assert-BoostLabCondition ([int]$categoryCounts['ManualHandoffOnly'] -eq 8) 'ManualHandoffOnly count changed unexpectedly.'
Assert-BoostLabCondition ([int]$inventorySnapshot.ActiveTools -eq 55) 'Active tool count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.ImplementedTools -eq 44) 'Runtime implemented count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.DeferredPlaceholders -eq 11) 'Deferred placeholder count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.SourcePromotedMirrorFiles -eq 7) 'Source-promoted mirror file count changed.'
Assert-BoostLabCondition ([int]$inventorySnapshot.RemainingSourcePromotedIntakeCandidates -eq 0) 'Remaining source-promoted intake count changed.'

$migrationText = Get-Content -Raw -LiteralPath $migrationPath
foreach ($needle in @(
    'Phase 111 outcome: `DoneYazanAcceptedNearParity`',
    'source-ultimate/2 Refresh/2 Unattended.ps1',
    $expectedSourceHash,
    'The source has no Default or Restore branch',
    'removable-media selection instead of raw drive-letter input',
    'No Restore action is claimed'
)) {
    Assert-BoostLabTextContains -Text $migrationText -Needle $needle -Description 'Unattended migration record'
}

$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceManifestLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
    Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
    Sort-Object {
        $_.FullName.Substring($root.Length + 1).Replace('\', '/')
    } |
    ForEach-Object {
        '{0}|{1}' -f `
            $_.FullName.Substring($root.Length + 1).Replace('\', '/'), `
            (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    }
$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $manifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash(
            [Text.Encoding]::UTF8.GetBytes(($sourceManifestLines -join "`n"))
        )
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}
Assert-BoostLabCondition (@($sourceManifestLines).Count -eq 49) "source-ultimate file count changed: $(@($sourceManifestLines).Count)"
Assert-BoostLabCondition ($manifestHash -eq '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') 'source-ultimate content or paths changed.'

foreach ($deletedPath in @(
    'source-ultimate\6 Windows\17 Loudness EQ.ps1',
    'source-ultimate\6 Windows\30 NVME Faster Driver.ps1'
)) {
    Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $deletedPath))) "Deleted source was reintroduced: $deletedPath"
}

[pscustomobject]@{
    Test = 'UnattendedOrderedParityAcceptance'
    SourcePath = 'source-ultimate/2 Refresh/2 Unattended.ps1'
    SourceHash = $actualSourceHash
    PayloadHash = '6293F4C6121B44A297B67BAF83BA165FB1330FF0749EEEE3601CEE941AA06F65'
    RuntimeImplementedTools = $inventorySnapshot.ImplementedTools
    UltimateParityImplemented = $parityBaseline.Counts.UltimateParityImplemented
    NearParityControlled = $parityBaseline.Counts.NearParityControlled
    UnattendedFinalProgressStatus = $unattendedRecord.FinalProgressStatus
    NextOrderedPendingTarget = $nextTarget.ToolId
    SourceUltimateUnchanged = $true
    Message = 'Unattended source-equivalent Windows 11 payload generation is accepted as near parity.'
}
