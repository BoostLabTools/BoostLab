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
        throw 'Unable to determine the Updates Drivers Block validator path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

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

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Refresh\updates-drivers-block.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\2 Refresh\3 Updates Drivers Block.ps1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$migrationPath = Join-Path $ProjectRoot 'docs\migrations\updates-drivers-block.md'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$sourcePromotedRoot = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate'

foreach ($path in @(
    $configPath,
    $modulePath,
    $sourcePath,
    $executionPath,
    $actionPlanPath,
    $artifactPath,
    $productionAllowlistPath,
    $migrationPath
)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required file missing: $path"
}

$expectedSourceHash = '4D4EC652C5A7F78824F53B7DC7FD46DDA948F3716A7CD6FD102D6C678EE11991'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Updates Drivers Block source hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."

$expectedEntries = @(
    [pscustomobject]@{ RegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\Device Metadata'; ValueName = 'PreventDeviceMetadataFromNetwork'; ValueType = 'DWord'; ApplyValue = 1 },
    [pscustomobject]@{ RegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\DeviceInstall\Settings'; ValueName = 'DisableSendGenericDriverNotFoundToWER'; ValueType = 'DWord'; ApplyValue = 1 },
    [pscustomobject]@{ RegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\DeviceInstall\Settings'; ValueName = 'DisableSendRequestAdditionalSoftwareToWER'; ValueType = 'DWord'; ApplyValue = 1 },
    [pscustomobject]@{ RegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\DriverSearching'; ValueName = 'SearchOrderConfig'; ValueType = 'DWord'; ApplyValue = 0 },
    [pscustomobject]@{ RegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate'; ValueName = 'SetAllowOptionalContent'; ValueType = 'DWord'; ApplyValue = 0 },
    [pscustomobject]@{ RegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate'; ValueName = 'AllowTemporaryEnterpriseFeatureControl'; ValueType = 'DWord'; ApplyValue = 0 },
    [pscustomobject]@{ RegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate'; ValueName = 'ExcludeWUDriversInQualityUpdate'; ValueType = 'DWord'; ApplyValue = 1 },
    [pscustomobject]@{ RegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'; ValueName = 'IncludeRecommendedUpdates'; ValueType = 'DWord'; ApplyValue = 0 },
    [pscustomobject]@{ RegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'; ValueName = 'EnableFeaturedSoftware'; ValueType = 'DWord'; ApplyValue = 0 }
)

$global:BoostLabUdbExpectedTargets = @{}
foreach ($entry in $expectedEntries) {
    $global:BoostLabUdbExpectedTargets['{0}|{1}' -f $entry.RegistryPath, $entry.ValueName] = $entry
}

$config = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })
$refreshStage = @($config.Stages | Where-Object { $_.Name -eq 'Refresh' })[0]
$tool = @($refreshStage.Tools | Where-Object { $_.Id -eq 'updates-drivers-block' })[0]

Assert-BoostLabCondition ($null -ne $tool) 'Updates Drivers Block must exist as an active Refresh tool.'
Assert-BoostLabCondition ([int]$tool.Order -eq 3) 'Updates Drivers Block must remain Refresh order 3.'
Assert-BoostLabCondition ([string]$tool.Type -eq 'action') 'Updates Drivers Block must be an action tool.'
Assert-BoostLabCondition ([string]$tool.RiskLevel -eq 'high') 'Updates Drivers Block must be high risk.'
Assert-BoostLabCondition ((@($tool.Actions) -join ',') -eq 'Analyze,Apply,Default,Restore') 'Updates Drivers Block must expose Analyze, Apply, Default, Restore only.'

$caps = $tool.Capabilities
Assert-BoostLabCondition ([bool]$caps.RequiresAdmin) 'Updates Drivers Block must require Administrator.'
Assert-BoostLabCondition ([bool]$caps.CanModifyRegistry) 'Updates Drivers Block must declare registry mutation.'
Assert-BoostLabCondition ([bool]$caps.SupportsDefault) 'Updates Drivers Block must support source-defined Default.'
Assert-BoostLabCondition ([bool]$caps.SupportsRestore) 'Updates Drivers Block Restore must be available only for selected captured state.'
Assert-BoostLabCondition ([bool]$caps.NeedsExplicitConfirmation) 'Updates Drivers Block must require explicit confirmation.'
foreach ($falseCapability in @(
    'RequiresInternet',
    'CanReboot',
    'CanModifyServices',
    'CanInstallSoftware',
    'CanDownload',
    'CanModifyDrivers',
    'CanModifySecurity',
    'CanDeleteFiles',
    'UsesTrustedInstaller',
    'UsesSafeMode'
)) {
    Assert-BoostLabCondition (-not [bool]$caps[$falseCapability]) "Capability must remain false: $falseCapability"
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

$executionText = Get-Content -LiteralPath $executionPath -Raw
foreach ($needle in @(
    "'updates-drivers-block'",
    "Refresh\updates-drivers-block.psm1",
    "'Analyze', 'Apply', 'Default', 'Restore'"
)) {
    Assert-BoostLabTextContains -Text $executionText -Needle $needle -Description 'Updates Drivers Block execution registration'
}

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
foreach ($needle in @(
    'Apply only the nine source-defined live Driver Updates policy registry values',
    'Remove only the nine source-defined live Driver Updates policy registry values',
    'Restore only from a valid selected captured rollback record',
    'no registry mutation is planned without selected captured state',
    'No Windows Update execution, download, installer, external process, setupcomplete.cmd generation, service change, or reboot occurs.',
    'BoostLab will capture prior state and write only the nine source-defined live Driver Updates policy values.',
    'BoostLab will capture prior state and remove only the nine source-defined live Driver Updates policy values.'
)) {
    Assert-BoostLabTextContains -Text $actionPlanText -Needle $needle -Description 'Updates Drivers Block action plan'
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru
try {
    $restorePlan = & $actionPlanModule {
        param($ToolMetadata)
        New-BoostLabActionPlan -ToolMetadata $ToolMetadata -ActionName Restore
    } $tool
    $restorePlannedChangesText = @($restorePlan.PlannedChanges) -join "`n"
    Assert-BoostLabCondition (-not $restorePlannedChangesText.Contains('Modify approved Windows registry values.')) 'Blocked Restore action plan must not claim generic registry mutation.'
    Assert-BoostLabCondition ($restorePlannedChangesText.Contains('no registry mutation is planned without selected captured state')) 'Blocked Restore action plan must clearly say no registry mutation is planned without selected captured state.'
    Assert-BoostLabCondition ($restorePlannedChangesText.Contains('If a valid selected record is provided')) 'Restore action plan should still describe the valid selected-record future path.'
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($needle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'', ''Restore'')',
    $expectedSourceHash,
    'source-ultimate/2 Refresh/3 Updates Drivers Block.ps1',
    'New-BoostLabRegistryStateCapture',
    'Set-BoostLabRollbackMutationState',
    'Invoke-BoostLabRegistryRollback',
    'New-ItemProperty',
    'Remove-ItemProperty',
    'PreventDeviceMetadataFromNetwork',
    'DisableSendGenericDriverNotFoundToWER',
    'DisableSendRequestAdditionalSoftwareToWER',
    'SearchOrderConfig',
    'SetAllowOptionalContent',
    'AllowTemporaryEnterpriseFeatureControl',
    'ExcludeWUDriversInQualityUpdate',
    'IncludeRecommendedUpdates',
    'EnableFeaturedSoftware',
    'Default is source-defined value deletion and is not Restore'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'Updates Drivers Block module'
}
foreach ($forbiddenText in @(
    'fuckyoumicrosoft.com',
    'WUServer',
    'WUStatusServer',
    'UpdateServiceUrlAlternate',
    'DoNotConnectToWindowsUpdateInternetLocations',
    'NoAutoUpdate',
    'UseWUServer',
    'SetDisableUXWUAccess'
)) {
    Assert-BoostLabCondition (-not $moduleText.Contains($forbiddenText)) "Module must not implement blocked broad Windows Update branch text: $forbiddenText"
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
    'Set-Content',
    'Move-Item',
    'Restart-Computer',
    'Stop-Service',
    'Set-Service',
    'pnputil',
    'dism',
    'wusa',
    'UsoClient',
    'wuauclt'
)) {
    Assert-BoostLabCondition ($forbiddenCommand -notin $commandNames) "Module contains forbidden command: $forbiddenCommand"
}

$artifactText = Get-Content -LiteralPath $artifactPath -Raw
$allowlistText = Get-Content -LiteralPath $productionAllowlistPath -Raw
Assert-BoostLabCondition (-not $artifactText.Contains('updates-drivers-block')) 'Updates Drivers Block must not add artifact provenance entries.'
Assert-BoostLabCondition (-not $allowlistText.Contains('updates-drivers-block')) 'Updates Drivers Block must not add production allowlist entries.'

$migrationText = Get-Content -LiteralPath $migrationPath -Raw
foreach ($needle in @(
    'Source SHA-256: `4D4EC652C5A7F78824F53B7DC7FD46DDA948F3716A7CD6FD102D6C678EE11991`',
    'bounded live Driver Updates policy',
    'custom WSUS/update-server URL writes',
    '`setupcomplete.cmd` creation or movement',
    'embedded reboot commands',
    'Default removes only the source-defined Driver Updates policy values',
    'uses selected captured state and is not equivalent to Default'
)) {
    Assert-BoostLabTextContains -Text $migrationText -Needle $needle -Description 'Updates Drivers Block migration record'
}

$stateRoot = Join-Path ([IO.Path]::GetTempPath()) ('BoostLab-UpdatesDriversBlock-Test-{0}' -f ([guid]::NewGuid().ToString('N')))
$global:BoostLabUdbMockRegistry = @{}
$global:BoostLabUdbWrites = [System.Collections.Generic.List[string]]::new()
$global:BoostLabUdbRemovals = [System.Collections.Generic.List[string]]::new()

$reader = {
    param($Path, $ItemType, $ValueName)

    $key = '{0}|{1}' -f [string]$Path, [string]$ValueName
    if (-not $global:BoostLabUdbExpectedTargets.ContainsKey($key)) {
        throw "Out-of-scope registry read attempted: $key"
    }

    if ($global:BoostLabUdbMockRegistry.ContainsKey($key)) {
        $entry = $global:BoostLabUdbMockRegistry[$key]
        return [pscustomobject]@{
            ReadSucceeded = $true
            KeyExists     = $true
            Exists        = $true
            Metadata      = [ordered]@{
                ValueName = $ValueName
                ValueType = [string]$entry.ValueType
                ValueData = $entry.ValueData
            }
            DisplayValue  = ('{0} {1}' -f [string]$entry.ValueType, [string]$entry.ValueData)
            Message       = 'Mock registry value detected.'
        }
    }

    return [pscustomobject]@{
        ReadSucceeded = $true
        KeyExists     = $true
        Exists        = $false
        Metadata      = $null
        DisplayValue  = 'Absent'
        Message       = 'Mock registry value is absent.'
    }
}

$writer = {
    param($Entry)

    $key = '{0}|{1}' -f [string]$Entry.RegistryPath, [string]$Entry.ValueName
    if (-not $global:BoostLabUdbExpectedTargets.ContainsKey($key)) {
        throw "Out-of-scope registry write attempted: $key"
    }

    $global:BoostLabUdbMockRegistry[$key] = [pscustomobject]@{
        ValueType = 'DWord'
        ValueData = [int]$Entry.ApplyValue
    }
    $global:BoostLabUdbWrites.Add($key)
}

$remover = {
    param($Entry)

    $key = '{0}|{1}' -f [string]$Entry.RegistryPath, [string]$Entry.ValueName
    if (-not $global:BoostLabUdbExpectedTargets.ContainsKey($key)) {
        throw "Out-of-scope registry removal attempted: $key"
    }

    if ($global:BoostLabUdbMockRegistry.ContainsKey($key)) {
        $global:BoostLabUdbMockRegistry.Remove($key)
    }
    $global:BoostLabUdbRemovals.Add($key)
}

$regressionMissingTargets = @(
    'HKLM:\Software\Policies\Microsoft\Windows\DeviceInstall\Settings|DisableSendGenericDriverNotFoundToWER',
    'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate|SetAllowOptionalContent',
    'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate|AllowTemporaryEnterpriseFeatureControl',
    'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU|IncludeRecommendedUpdates'
)

$skippingRegressionWriter = {
    param($Entry)

    $key = '{0}|{1}' -f [string]$Entry.RegistryPath, [string]$Entry.ValueName
    if (-not $global:BoostLabUdbExpectedTargets.ContainsKey($key)) {
        throw "Out-of-scope registry write attempted: $key"
    }
    if ($key -in $global:BoostLabUdbRegressionMissingTargets) {
        return
    }

    $global:BoostLabUdbMockRegistry[$key] = [pscustomobject]@{
        ValueType = 'DWord'
        ValueData = [int]$Entry.ApplyValue
    }
    $global:BoostLabUdbWrites.Add($key)
}

try {
    New-Item -Path $stateRoot -ItemType Directory -Force | Out-Null
    $moduleInfo = Import-Module -Name $modulePath -Force -PassThru
    $global:BoostLabUdbRegressionMissingTargets = $regressionMissingTargets

    $analyze = & $moduleInfo {
        param($Reader)
        Invoke-BoostLabToolAction -ActionName Analyze -RegistryReader $Reader
    } $reader
    Assert-BoostLabCondition ([bool]$analyze.Success) 'Analyze should succeed.'
    Assert-BoostLabCondition ([string]$analyze.Status -eq 'Analyzed') "Analyze status mismatch: $($analyze.Status)"
    Assert-BoostLabCondition (-not [bool]$analyze.ChangesExecuted) 'Analyze must be read-only.'
    Assert-BoostLabCondition ([int]$analyze.Data.SupportedValueCount -eq 9) 'Analyze must report nine supported values.'
    Assert-BoostLabCondition (@($analyze.Errors).Count -eq 0) 'Analyze should not report errors.'

    $unconfirmedApply = & $moduleInfo {
        param($Reader, $Writer, $StateRoot)
        Invoke-BoostLabToolAction -ActionName Apply -RegistryReader $Reader -RegistryWriter $Writer -StateRoot $StateRoot
    } $reader $writer $stateRoot
    Assert-BoostLabCondition ([string]$unconfirmedApply.Status -eq 'Cancelled') 'Unconfirmed Apply must be cancelled before mutation.'
    Assert-BoostLabCondition ($global:BoostLabUdbWrites.Count -eq 0) 'Unconfirmed Apply must not write registry state.'

    $regressionApply = & $moduleInfo {
        param($Reader, $Writer, $StateRoot)
        Invoke-BoostLabToolAction `
            -ActionName Apply `
            -Confirmed:$true `
            -AdministratorChecker { $true } `
            -RegistryReader $Reader `
            -RegistryWriter $Writer `
            -StateRoot $StateRoot
    } $reader $skippingRegressionWriter $stateRoot
    Assert-BoostLabCondition (-not [bool]$regressionApply.Success) 'Apply must fail closed when post-write verification detects missing values.'
    Assert-BoostLabCondition ([string]$regressionApply.Status -eq 'Error') "Regression Apply status mismatch: $($regressionApply.Status)"
    Assert-BoostLabCondition ([string]$regressionApply.CommandStatus -ne 'Completed') 'Apply must not report Completed when post-write verification fails.'
    Assert-BoostLabCondition (@($regressionApply.Data.RegistryChangesCompleted).Count -eq 5) "Regression Apply should only mark five verified writes completed, marked $(@($regressionApply.Data.RegistryChangesCompleted).Count)."
    foreach ($missingTarget in $regressionMissingTargets) {
        Assert-BoostLabCondition (-not $global:BoostLabUdbMockRegistry.ContainsKey($missingTarget)) "Regression target should remain absent in mock: $missingTarget"
        $targetParts = $missingTarget.Split('|')
        $regressionErrorText = @($regressionApply.Errors) -join "`n"
        Assert-BoostLabCondition ($regressionErrorText.Contains($targetParts[0]) -and $regressionErrorText.Contains($targetParts[1])) "Regression Apply errors should name missing target: $missingTarget"
    }
    $global:BoostLabUdbMockRegistry.Clear()
    $global:BoostLabUdbWrites.Clear()

    $apply = & $moduleInfo {
        param($Reader, $Writer, $StateRoot)
        Invoke-BoostLabToolAction `
            -ActionName Apply `
            -Confirmed:$true `
            -AdministratorChecker { $true } `
            -RegistryReader $Reader `
            -RegistryWriter $Writer `
            -StateRoot $StateRoot
    } $reader $writer $stateRoot
    Assert-BoostLabCondition ([bool]$apply.Success) "Apply should succeed: $($apply.Message)"
    Assert-BoostLabCondition ([string]$apply.Status -eq 'Completed') "Apply status mismatch: $($apply.Status)"
    Assert-BoostLabCondition ([string]$apply.VerificationStatus -eq 'Passed') "Apply verification mismatch: $($apply.VerificationStatus)"
    Assert-BoostLabCondition ([bool]$apply.ChangesExecuted) 'Apply top-level ChangesExecuted should be true.'
    Assert-BoostLabCondition ($global:BoostLabUdbWrites.Count -eq 9) "Apply should write exactly nine values, wrote $($global:BoostLabUdbWrites.Count)."
    Assert-BoostLabCondition (@($apply.Data.CaptureRecords).Count -eq 9) 'Apply should capture every supported value before mutation.'
    Assert-BoostLabCondition (@($apply.Errors).Count -eq 0) 'Apply should not report errors.'
    foreach ($entry in $expectedEntries) {
        $key = '{0}|{1}' -f $entry.RegistryPath, $entry.ValueName
        Assert-BoostLabCondition ($global:BoostLabUdbMockRegistry.ContainsKey($key)) "Apply did not write expected value: $key"
        Assert-BoostLabCondition ([string]$global:BoostLabUdbMockRegistry[$key].ValueType -eq 'DWord') "Apply wrote unexpected type for $key."
        Assert-BoostLabCondition ([int]$global:BoostLabUdbMockRegistry[$key].ValueData -eq [int]$entry.ApplyValue) "Apply wrote unexpected data for $key."
    }
    foreach ($zeroEntry in @($expectedEntries | Where-Object { [int]$_.ApplyValue -eq 0 })) {
        $key = '{0}|{1}' -f $zeroEntry.RegistryPath, $zeroEntry.ValueName
        Assert-BoostLabCondition ($global:BoostLabUdbMockRegistry.ContainsKey($key)) "DWORD 0 Apply value was treated as absent: $key"
        Assert-BoostLabCondition ([int]$global:BoostLabUdbMockRegistry[$key].ValueData -eq 0) "DWORD 0 Apply value was not preserved as zero: $key"
    }

    $restoreRecordPath = [string]@($apply.Data.CaptureRecords)[0].RecordPath
    Assert-BoostLabCondition (Test-Path -LiteralPath $restoreRecordPath -PathType Leaf) 'Apply did not produce a rollback record path for Restore validation.'

    $restore = & $moduleInfo {
        param($Reader, $Writer, $Remover, $StateRoot, $RecordPath)
        Invoke-BoostLabToolAction `
            -ActionName Restore `
            -Confirmed:$true `
            -SelectedCapturePath $RecordPath `
            -AdministratorChecker { $true } `
            -RegistryReader $Reader `
            -RegistryWriter $Writer `
            -RegistryRemover $Remover `
            -StateRoot $StateRoot
    } $reader $writer $remover $stateRoot $restoreRecordPath
    Assert-BoostLabCondition ([bool]$restore.Success) "Restore should succeed with a valid selected capture: $($restore.Message); Errors: $(@($restore.Errors) -join '; ')"
    Assert-BoostLabCondition ([string]$restore.Status -eq 'Restored') "Restore status mismatch: $($restore.Status)"
    Assert-BoostLabCondition ([bool]$restore.ChangesExecuted) 'Restore should report ChangesExecuted only after selected captured-state rollback.'
    $firstKey = '{0}|{1}' -f $expectedEntries[0].RegistryPath, $expectedEntries[0].ValueName
    Assert-BoostLabCondition (-not $global:BoostLabUdbMockRegistry.ContainsKey($firstKey)) 'Restore should restore the captured absent state for the selected first value.'

    $restoreBlocked = & $moduleInfo {
        Invoke-BoostLabToolAction -ActionName Restore -Confirmed:$true -AdministratorChecker { $true }
    }
    Assert-BoostLabCondition ([string]$restoreBlocked.Status -eq 'RestoreRequiresCapturedState') 'Restore without selected capture must fail closed.'
    Assert-BoostLabCondition (-not [bool]$restoreBlocked.ChangesExecuted) 'Restore without selected capture must not execute changes.'

    foreach ($entry in $expectedEntries) {
        $global:BoostLabUdbMockRegistry['{0}|{1}' -f $entry.RegistryPath, $entry.ValueName] = [pscustomobject]@{
            ValueType = 'DWord'
            ValueData = [int]$entry.ApplyValue
        }
    }
    $global:BoostLabUdbRemovals.Clear()

    $default = & $moduleInfo {
        param($Reader, $Remover, $StateRoot)
        Invoke-BoostLabToolAction `
            -ActionName Default `
            -Confirmed:$true `
            -AdministratorChecker { $true } `
            -RegistryReader $Reader `
            -RegistryRemover $Remover `
            -StateRoot $StateRoot
    } $reader $remover $stateRoot
    Assert-BoostLabCondition ([bool]$default.Success) "Default should succeed: $($default.Message)"
    Assert-BoostLabCondition ([string]$default.Status -eq 'Completed') "Default status mismatch: $($default.Status)"
    Assert-BoostLabCondition ([string]$default.VerificationStatus -eq 'Passed') "Default verification mismatch: $($default.VerificationStatus)"
    Assert-BoostLabCondition ([bool]$default.ChangesExecuted) 'Default top-level ChangesExecuted should be true.'
    Assert-BoostLabCondition ($global:BoostLabUdbRemovals.Count -eq 9) "Default should remove exactly nine values, removed $($global:BoostLabUdbRemovals.Count)."
    Assert-BoostLabCondition ($global:BoostLabUdbMockRegistry.Count -eq 0) 'Default should remove all nine supported values in the mocked store.'
    Assert-BoostLabCondition ([bool]$default.Data.DefaultIsRestore -eq $false) 'Default must remain separate from Restore.'
}
finally {
    if (Test-Path -LiteralPath $stateRoot) {
        Remove-Item -LiteralPath $stateRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    Remove-Variable -Name BoostLabUdbMockRegistry -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable -Name BoostLabUdbExpectedTargets -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable -Name BoostLabUdbRegressionMissingTargets -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable -Name BoostLabUdbWrites -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable -Name BoostLabUdbRemovals -Scope Global -ErrorAction SilentlyContinue
}

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
Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' }).Count -eq 0) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    Success                         = $true
    ToolId                          = 'updates-drivers-block'
    SourceHash                      = $actualSourceHash
    ActiveToolCount                 = $allTools.Count
    ImplementedToolCount            = $allTools.Count - $placeholderModules.Count
    PlaceholderToolCount            = $placeholderModules.Count
    SourcePromotedMirrorFileCount   = $sourcePromotedFiles.Count
    RemainingSourcePromotedIntake   = $inventoryBaseline.RemainingSourcePromotedIntakeCandidates
    SupportedPolicyValueCount       = $expectedEntries.Count
    SourceUltimateUnchanged         = $true
    DeletedToolsRemainDeleted       = $true
    Message                         = 'Updates Drivers Block controlled live Driver Updates policy implementation is bounded, captured, verified, and mocked without real registry mutation.'
    Timestamp                       = Get-Date
}
