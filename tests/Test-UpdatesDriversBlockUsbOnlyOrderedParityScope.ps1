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
        throw 'Unable to determine the Updates Drivers Block USB-only validator path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
. (Join-Path $ProjectRoot 'tests\BoostLab.ParityStatusBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

function Assert-BoostLabCondition {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-BoostLabTextContains {
    param(
        [AllowNull()][string]$Text,
        [Parameter(Mandatory)][string]$Needle,
        [Parameter(Mandatory)][string]$Description
    )

    if ([string]::IsNullOrEmpty($Text) -or -not $Text.Contains($Needle)) {
        throw "$Description missing expected text: $Needle"
    }
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Refresh\updates-drivers-block.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\2 Refresh\3 Updates Drivers Block.ps1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$parityPath = Join-Path $ProjectRoot 'config\ParityStatusBaseline.psd1'
$orderPath = Join-Path $ProjectRoot 'config\UltimateParityExecutionOrder.psd1'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$migrationPath = Join-Path $ProjectRoot 'docs\migrations\updates-drivers-block.md'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$sourcePromotedRoot = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate'
$modulesRoot = Join-Path $ProjectRoot 'modules'

foreach ($path in @(
    $configPath,
    $modulePath,
    $sourcePath,
    $actionPlanPath,
    $parityPath,
    $orderPath,
    $artifactPath,
    $productionAllowlistPath,
    $migrationPath
)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required file missing: $path"
}

$expectedSourceHash = '4D4EC652C5A7F78824F53B7DC7FD46DDA948F3716A7CD6FD102D6C678EE11991'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Updates Drivers Block source hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."

$sourceText = Get-Content -LiteralPath $sourcePath -Raw
foreach ($needle in @(
    'Write-Host " 2. Block (Bootable USB)"',
    'Write-Host "Blocked: Driver Updates (Bootable USB)"',
    'Set-Content -Path "$env:SystemRoot\Temp\setupcomplete.cmd"',
    'Move-Item -Path "$env:SystemRoot\Temp\setupcomplete.cmd"',
    'shutdown /r /t 0'
)) {
    Assert-BoostLabTextContains -Text $sourceText -Needle $needle -Description 'Ultimate USB Driver Updates branch'
}

$config = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })
$tool = @($allTools | Where-Object { $_.Id -eq 'updates-drivers-block' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $tool) 'Updates Drivers Block must exist as an active tool.'
Assert-BoostLabCondition ([string]$tool.Stage -eq 'Refresh') 'Updates Drivers Block must remain in Refresh.'
Assert-BoostLabCondition ([int]$tool.Order -eq 3) 'Updates Drivers Block must remain Refresh order 3.'
Assert-BoostLabCondition ((@($tool.Actions) -join ',') -eq 'Analyze,Apply,Default,Restore') 'Updates Drivers Block must expose canonical Analyze, Apply, Default, Restore only.'
$caps = $tool.Capabilities
Assert-BoostLabCondition ([bool]$caps.RequiresAdmin) 'Updates Drivers Block must preserve the source Administrator requirement.'
Assert-BoostLabCondition (-not [bool]$caps.CanModifyRegistry) 'Updates Drivers Block must no longer declare host registry mutation as final behavior.'
Assert-BoostLabCondition ([bool]$caps.CanDeleteFiles) 'Updates Drivers Block must declare file-changing capability for USB setupcomplete.cmd overwrite/restore handling.'
Assert-BoostLabCondition (-not [bool]$caps.SupportsDefault) 'Updates Drivers Block must not claim Default/Unblock support.'
Assert-BoostLabCondition ([bool]$caps.SupportsRestore) 'Updates Drivers Block must support selected captured USB file Restore.'
Assert-BoostLabCondition ([bool]$caps.NeedsExplicitConfirmation) 'Updates Drivers Block Apply/Restore must require explicit confirmation.'
foreach ($falseCapability in @(
    'RequiresInternet',
    'CanReboot',
    'CanModifyServices',
    'CanInstallSoftware',
    'CanDownload',
    'CanModifyDrivers',
    'CanModifySecurity',
    'UsesTrustedInstaller',
    'UsesSafeMode'
)) {
    Assert-BoostLabCondition (-not [bool]$caps[$falseCapability]) "Capability must remain false: $falseCapability"
}

$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$updatesRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'updates-drivers-block' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $updatesRecord) 'Updates Drivers Block parity record must exist.'
Assert-BoostLabCondition ([string]$updatesRecord.ImplementationLevel -eq 'ControlledSubset') 'Updates Drivers Block must remain ControlledSubset.'
Assert-BoostLabCondition ([string]$updatesRecord.UltimateParity -eq 'Partial') 'Updates Drivers Block must not be counted as full parity.'
Assert-BoostLabCondition ([bool]$updatesRecord.YazanFinalException) 'Updates Drivers Block must be marked as a Yazan final exception.'
Assert-BoostLabCondition (-not [bool]$updatesRecord.YazanAcceptedNearParity) 'Updates Drivers Block must not be marked accepted near-parity.'
Assert-BoostLabCondition ([string]$updatesRecord.FinalProgressStatus -eq 'YazanFinalException') 'Updates Drivers Block final progress status mismatch.'
Assert-BoostLabTextContains -Text ([string]$updatesRecord.GapSummary) -Needle 'Driver Updates Block Bootable USB only' -Description 'Parity gap summary'

$refreshOrder = @($executionOrder.Stages | Where-Object { $_.Name -eq 'Refresh' }) | Select-Object -First 1
$refreshToolIds = @($refreshOrder.Tools | ForEach-Object { [string]$_.ToolId })
Assert-BoostLabCondition ($refreshToolIds[2] -eq 'updates-drivers-block') 'Updates Drivers Block must remain the third ordered Refresh target.'
$priorToolIds = @($refreshToolIds | Select-Object -First 2)
foreach ($priorToolId in $priorToolIds) {
    $priorRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq $priorToolId }) | Select-Object -First 1
    Assert-BoostLabCondition (Test-BoostLabParityRecordFinal -Record $priorRecord) "Prior ordered target must already be final: $priorToolId"
}
$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq 'nvidia-settings') 'Next ordered pending parity target must advance past Driver Install Latest near-parity acceptance.'

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
foreach ($needle in @(
    'Report Yazan final scope: Driver Updates Block Bootable USB only.',
    'Require an explicit selected removable USB/root target before any file operation.',
    'Create or update only sources\$OEM$\$$\Setup\Scripts\setupcomplete.cmd',
    'Do not execute setupcomplete.cmd, write host registry policy values',
    'Default is unavailable because Yazan final scope excludes Unblock.',
    'Restore is blocked without a selected captured USB setupcomplete.cmd file rollback record'
)) {
    Assert-BoostLabTextContains -Text $actionPlanText -Needle $needle -Description 'Updates Drivers Block action plan'
}
$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru
try {
    $applyPlan = & $actionPlanModule {
        param($ToolMetadata)
        New-BoostLabActionPlan -ToolMetadata $ToolMetadata -ActionName Apply
    } $tool
    $defaultPlan = & $actionPlanModule {
        param($ToolMetadata)
        New-BoostLabActionPlan -ToolMetadata $ToolMetadata -ActionName Default
    } $tool
    $restorePlan = & $actionPlanModule {
        param($ToolMetadata)
        New-BoostLabActionPlan -ToolMetadata $ToolMetadata -ActionName Restore
    } $tool
    $applyPlanText = (@($applyPlan.PlannedChanges) + @($applyPlan.SideEffects) + @($applyPlan.ConfirmationMessage)) -join "`n"
    $defaultPlanText = (@($defaultPlan.PlannedChanges) + @($defaultPlan.SideEffects) + @($defaultPlan.ConfirmationMessage)) -join "`n"
    $restorePlanText = (@($restorePlan.PlannedChanges) + @($restorePlan.SideEffects) + @($restorePlan.ConfirmationMessage)) -join "`n"
    Assert-BoostLabTextContains -Text $applyPlanText -Needle 'selected removable USB' -Description 'Apply action plan'
    Assert-BoostLabTextContains -Text $applyPlanText -Needle 'It will not execute the script, write host registry values' -Description 'Apply confirmation'
    Assert-BoostLabTextContains -Text $defaultPlanText -Needle 'Default is unavailable because Yazan final scope excludes Unblock' -Description 'Default action plan'
    Assert-BoostLabTextContains -Text $restorePlanText -Needle 'captured USB setupcomplete.cmd file' -Description 'Restore action plan'
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($needle in @(
    '$script:BoostLabFinalScope = ''Driver Updates Block (Bootable USB) only''',
    '$script:BoostLabSupportedSourceBranch = ''Driver Updates Block (Bootable USB): Ultimate menu option 2''',
    '$script:BoostLabSetupCompleteRelativePath = ''sources\$OEM$\$$\Setup\Scripts\setupcomplete.cmd''',
    'New-BoostLabFileStateCapture',
    'Set-BoostLabRollbackMutationState',
    'Invoke-BoostLabFileRollback',
    'DefaultUnavailable',
    'RestoreRequiresCapturedUsbFileState',
    'HostRegistryWrites = $false',
    'SetupCompleteExecuted = $false',
    'ExternalProcessStarted = $false',
    'RebootTriggered = $false'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'Updates Drivers Block module'
}
foreach ($forbiddenText in @(
    'New-ItemProperty',
    'Remove-ItemProperty',
    'Invoke-BoostLabRegistryRollback',
    'New-BoostLabRegistryStateCapture',
    'WUServer',
    'WUStatusServer',
    'UpdateServiceUrlAlternate',
    'DoNotConnectToWindowsUpdateInternetLocations',
    'NoAutoUpdate',
    'UseWUServer',
    'SetDisableUXWUAccess',
    'fuckyoumicrosoft.com'
)) {
    Assert-BoostLabCondition (-not $moduleText.Contains($forbiddenText)) "Module must not implement blocked live/broad registry behavior: $forbiddenText"
}

$moduleAst = [Management.Automation.Language.Parser]::ParseFile($modulePath, [ref]$null, [ref]$null)
$commandNames = @(
    $moduleAst.FindAll({ param($node) $node -is [Management.Automation.Language.CommandAst] }, $true) |
        ForEach-Object { $_.GetCommandName() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Sort-Object -Unique
)
foreach ($forbiddenCommand in @(
    'Start-Process',
    'Invoke-WebRequest',
    'Invoke-RestMethod',
    'Start-BitsTransfer',
    'Restart-Computer',
    'Stop-Service',
    'Set-Service',
    'pnputil',
    'dism',
    'wusa',
    'UsoClient',
    'wuauclt'
)) {
    Assert-BoostLabCondition ($forbiddenCommand -notin $commandNames) "Module contains forbidden runtime command: $forbiddenCommand"
}

$artifactText = Get-Content -LiteralPath $artifactPath -Raw
$allowlistText = Get-Content -LiteralPath $productionAllowlistPath -Raw
Assert-BoostLabCondition (-not $artifactText.Contains('updates-drivers-block')) 'Updates Drivers Block must not add artifact provenance entries.'
Assert-BoostLabCondition (-not $allowlistText.Contains('updates-drivers-block')) 'Updates Drivers Block must not add production allowlist entries.'

$stateRoot = Join-Path ([IO.Path]::GetTempPath()) ('BoostLab-UdbUsb-Test-State-{0}' -f ([guid]::NewGuid().ToString('N')))
$usbRoot = Join-Path ([IO.Path]::GetTempPath()) ('BoostLab-UdbUsb-Test-Usb-{0}' -f ([guid]::NewGuid().ToString('N')))
$scriptPath = [IO.Path]::Combine($usbRoot, 'sources', '$OEM$', '$$', 'Setup', 'Scripts', 'setupcomplete.cmd')
try {
    [IO.Directory]::CreateDirectory($stateRoot) | Out-Null
    [IO.Directory]::CreateDirectory($usbRoot) | Out-Null
    $moduleInfo = Import-Module -Name $modulePath -Force -PassThru
    $driveReader = {
        @(
            [pscustomobject]@{
                Root = $usbRoot
                Label = 'Mock USB'
                FreeSpace = 104857600
            }
        )
    }
    $selectionProvider = {
        param($Drives)
        [pscustomobject]@{
            DriveRoot = [string]@($Drives)[0].Root
        }
    }

    $analyze = & $moduleInfo {
        param($DriveReader)
        Invoke-BoostLabToolAction -ActionName Analyze -DriveReader $DriveReader
    } $driveReader
    Assert-BoostLabCondition ([bool]$analyze.Success) "Analyze should succeed: $($analyze.Message)"
    Assert-BoostLabCondition ([string]$analyze.Status -eq 'Analyzed') "Analyze status mismatch: $($analyze.Status)"
    Assert-BoostLabCondition (-not [bool]$analyze.ChangesExecuted) 'Analyze must be read-only.'
    Assert-BoostLabCondition ([string]$analyze.Data.FinalScope -eq 'Driver Updates Block (Bootable USB) only') 'Analyze must report Yazan final USB-only scope.'
    Assert-BoostLabCondition ([int]$analyze.Data.RemovableMediaCount -eq 1) 'Analyze must report mocked removable target count.'
    Assert-BoostLabCondition ([bool]$analyze.Data.NoHostRegistryMutation) 'Analyze must report no host registry mutation.'

    $blockedApply = & $moduleInfo {
        param($StateRoot)
        Invoke-BoostLabToolAction `
            -ActionName Apply `
            -Confirmed:$true `
            -AdministratorChecker { $true } `
            -DriveReader { @() } `
            -SelectionProvider { param($Drives) $null } `
            -StateRoot $StateRoot
    } $stateRoot
    Assert-BoostLabCondition ([string]$blockedApply.Status -eq 'UsbTargetRequired') 'Apply must fail closed without a selected removable USB target.'
    Assert-BoostLabCondition (-not [bool]$blockedApply.ChangesExecuted) 'Apply without USB target must execute no changes.'
    Assert-BoostLabCondition (-not (Test-Path -LiteralPath $scriptPath)) 'Apply without USB target must not create setupcomplete.cmd.'

    $apply = & $moduleInfo {
        param($DriveReader, $SelectionProvider, $StateRoot)
        Invoke-BoostLabToolAction `
            -ActionName Apply `
            -Confirmed:$true `
            -AdministratorChecker { $true } `
            -DriveReader $DriveReader `
            -SelectionProvider $SelectionProvider `
            -StateRoot $StateRoot
    } $driveReader $selectionProvider $stateRoot
    Assert-BoostLabCondition ([bool]$apply.Success) "Apply should succeed: $($apply.Message); Errors: $(@($apply.Errors) -join '; ')"
    Assert-BoostLabCondition ([string]$apply.Status -eq 'Completed') "Apply status mismatch: $($apply.Status)"
    Assert-BoostLabCondition ([string]$apply.VerificationStatus -eq 'Passed') "Apply verification mismatch: $($apply.VerificationStatus)"
    Assert-BoostLabCondition ([bool]$apply.ChangesExecuted) 'Apply should report ChangesExecuted after writing setupcomplete.cmd.'
    Assert-BoostLabCondition (Test-Path -LiteralPath $scriptPath -PathType Leaf) 'Apply must create setupcomplete.cmd at the source-equivalent USB path.'
    $detectedContent = Get-Content -LiteralPath $scriptPath -Raw
    foreach ($requiredLine in @(
        '@echo off',
        'reg add "HKLM\Software\Policies\Microsoft\Windows\Device Metadata" /v "PreventDeviceMetadataFromNetwork" /t REG_DWORD /d 1 /f',
        'reg add "HKLM\Software\Policies\Microsoft\Windows\DeviceInstall\Settings" /v "DisableSendGenericDriverNotFoundToWER" /t REG_DWORD /d 1 /f',
        'reg add "HKLM\Software\Policies\Microsoft\Windows\DeviceInstall\Settings" /v "DisableSendRequestAdditionalSoftwareToWER" /t REG_DWORD /d 1 /f',
        'reg add "HKLM\Software\Policies\Microsoft\Windows\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d 0 /f',
        'reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "SetAllowOptionalContent" /t REG_DWORD /d 0 /f',
        'reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "AllowTemporaryEnterpriseFeatureControl" /t REG_DWORD /d 0 /f',
        'reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d 1 /f',
        'reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "IncludeRecommendedUpdates" /t REG_DWORD /d 0 /f',
        'reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "EnableFeaturedSoftware" /t REG_DWORD /d 0 /f',
        'shutdown /r /t 0'
    )) {
        Assert-BoostLabTextContains -Text $detectedContent -Needle $requiredLine -Description 'Generated setupcomplete.cmd'
    }
    foreach ($forbiddenLine in @(
        'WUServer',
        'WUStatusServer',
        'UpdateServiceUrlAlternate',
        'DoNotConnectToWindowsUpdateInternetLocations',
        'NoAutoUpdate',
        'UseWUServer',
        'fuckyoumicrosoft.com'
    )) {
        Assert-BoostLabCondition (-not $detectedContent.Contains($forbiddenLine)) "Generated Driver Updates USB script must not contain broad Updates branch text: $forbiddenLine"
    }
    Assert-BoostLabCondition (-not [bool]$apply.Data.SetupCompleteExecuted) 'Apply must not execute generated setupcomplete.cmd on the host.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.HostRegistryWrites) 'Apply must not write host registry values.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.WindowsUpdateExecuted) 'Apply must not run Windows Update.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.ExternalProcessStarted) 'Apply must not start external processes.'
    Assert-BoostLabCondition (-not [bool]$apply.Data.RebootTriggered) 'Apply must not reboot.'
    Assert-BoostLabCondition (Test-Path -LiteralPath ([string]$apply.Data.CaptureRecordPath) -PathType Leaf) 'Apply must create a file rollback capture record.'

    $default = & $moduleInfo {
        Invoke-BoostLabToolAction -ActionName Default -Confirmed:$true
    }
    Assert-BoostLabCondition ([string]$default.Status -eq 'DefaultUnavailable') 'Default must be unavailable.'
    Assert-BoostLabCondition (-not [bool]$default.ChangesExecuted) 'Default must execute no changes.'
    Assert-BoostLabCondition (-not [bool]$default.Data.DefaultIsUnblock) 'Default must not be treated as Unblock.'
    Assert-BoostLabCondition (Test-Path -LiteralPath $scriptPath -PathType Leaf) 'Default must not delete the USB setupcomplete.cmd file.'

    $restoreBlocked = & $moduleInfo {
        Invoke-BoostLabToolAction -ActionName Restore -Confirmed:$true -AdministratorChecker { $true }
    }
    Assert-BoostLabCondition ([string]$restoreBlocked.Status -eq 'RestoreRequiresCapturedUsbFileState') 'Restore without selected captured USB file state must fail closed.'
    Assert-BoostLabCondition (-not [bool]$restoreBlocked.ChangesExecuted) 'Restore without selected capture must not execute changes.'
    Assert-BoostLabCondition (-not [bool]$restoreBlocked.Data.RestoreIsUnblock) 'Restore must not be treated as Unblock.'

    $restore = & $moduleInfo {
        param($StateRoot, $RecordPath)
        Invoke-BoostLabToolAction `
            -ActionName Restore `
            -Confirmed:$true `
            -SelectedCapturePath $RecordPath `
            -AdministratorChecker { $true } `
            -StateRoot $StateRoot
    } $stateRoot ([string]$apply.Data.CaptureRecordPath)
    Assert-BoostLabCondition ([bool]$restore.Success) "Restore should succeed with selected captured USB file state: $($restore.Message); Errors: $(@($restore.Errors) -join '; ')"
    Assert-BoostLabCondition ([string]$restore.Status -eq 'Restored') "Restore status mismatch: $($restore.Status)"
    Assert-BoostLabCondition ([bool]$restore.ChangesExecuted) 'Restore should report ChangesExecuted after selected captured-state rollback.'
    Assert-BoostLabCondition (-not [bool]$restore.Data.RestoreIsUnblock) 'Restore result must not be Unblock.'
    Assert-BoostLabCondition (-not (Test-Path -LiteralPath $scriptPath)) 'Restore should restore the captured absent USB setupcomplete.cmd state.'
}
finally {
    Remove-Module updates-drivers-block -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $stateRoot) {
        Remove-Item -LiteralPath $stateRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path -LiteralPath $usbRoot) {
        Remove-Item -LiteralPath $usbRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$placeholderModules = @(
    Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
Assert-BoostLabCondition ($allTools.Count -eq $inventoryBaseline.ActiveTools) "Expected $($inventoryBaseline.ActiveTools) active tools, found $($allTools.Count)."
Assert-BoostLabCondition ($placeholderModules.Count -eq $inventoryBaseline.DeferredPlaceholders) "Expected $($inventoryBaseline.DeferredPlaceholders) deferred/placeholders, found $($placeholderModules.Count)."
Assert-BoostLabCondition (($allTools.Count - $placeholderModules.Count) -eq $inventoryBaseline.ImplementedTools) "Expected $($inventoryBaseline.ImplementedTools) implemented tools, found $($allTools.Count - $placeholderModules.Count)."
$sourcePromotedFiles = @(Get-ChildItem -LiteralPath $sourcePromotedRoot -Recurse -File)
Assert-BoostLabCondition ($sourcePromotedFiles.Count -eq $inventoryBaseline.SourcePromotedMirrorFiles) "Expected $($inventoryBaseline.SourcePromotedMirrorFiles) source-promoted mirror files, found $($sourcePromotedFiles.Count)."
Assert-BoostLabCondition ([int]$inventoryBaseline.RemainingSourcePromotedIntakeCandidates -eq 0) 'Remaining source-promoted intake candidates must stay zero.'

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceManifestLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
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
Assert-BoostLabCondition (@($sourceManifestLines).Count -eq 49) 'source-ultimate file count changed.'
Assert-BoostLabCondition ($manifestHash -eq '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') 'source-ultimate content or paths changed.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }).Count -eq 0) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    Success = $true
    ToolId = 'updates-drivers-block'
    SourceHash = $actualSourceHash
    FinalScope = 'Driver Updates Block Bootable USB only'
    ActiveToolCount = $allTools.Count
    ImplementedToolCount = $allTools.Count - $placeholderModules.Count
    PlaceholderToolCount = $placeholderModules.Count
    NextOrderedPendingTarget = $nextTarget.ToolId
    SourceUltimateUnchanged = $true
    DeletedToolsRemainDeleted = $true
    Message = 'Updates Drivers Block USB-only ordered parity scope is implemented, bounded, captured, verified, and mocked without host registry mutation.'
    Timestamp = Get-Date
}
