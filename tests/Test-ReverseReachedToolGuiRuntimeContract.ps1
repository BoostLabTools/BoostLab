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
        throw 'Unable to determine the reverse reached-tool GUI/runtime contract validator path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')

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

function Invoke-BoostLabRuntimeActionSimulation {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$ToolMetadata,

        [Parameter(Mandatory)]
        [string]$ActionName,

        [AllowNull()]
        [hashtable]$ActionOptions = @{}
    )

    $tempProgramData = Join-Path ([System.IO.Path]::GetTempPath()) ('BoostLabReverseSmoke_' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tempProgramData -Force -ErrorAction Stop | Out-Null

    try {
        $workerScript = {
            param(
                [Parameter(Mandatory)]
                [string]$ProjectRoot,

                [Parameter(Mandatory)]
                [string]$ProgramDataRoot,

                [Parameter(Mandatory)]
                [System.Collections.IDictionary]$ToolMetadata,

                [Parameter(Mandatory)]
                [string]$ActionName,

                [AllowNull()]
                [hashtable]$ActionOptions = @{}
            )

            Set-StrictMode -Version Latest
            $ErrorActionPreference = 'Stop'
            $env:ProgramData = $ProgramDataRoot

            if ($null -eq $ActionOptions) {
                $ActionOptions = @{}
            }

            foreach ($relativeModulePath in @(
                'core\Environment.psm1'
                'core\Logging.psm1'
                'core\ActionPlan.psm1'
                'core\Safety.psm1'
                'core\State.psm1'
                'core\Verification.psm1'
                'core\Execution.psm1'
            )) {
                $modulePath = Join-Path $ProjectRoot $relativeModulePath
                if (Test-Path -LiteralPath $modulePath -PathType Leaf) {
                    Import-Module -Name $modulePath -Force -ErrorAction Stop
                }
            }

            function global:Test-BoostLabAdministrator {
                return $true
            }

            if (Get-Command -Name 'Initialize-BoostLabLogging' -ErrorAction SilentlyContinue) {
                Initialize-BoostLabLogging | Out-Null
            }
            if (Get-Command -Name 'Initialize-BoostLabState' -ErrorAction SilentlyContinue) {
                Initialize-BoostLabState | Out-Null
            }

            Invoke-BoostLabToolAction `
                -ToolMetadata $ToolMetadata `
                -ActionName $ActionName `
                -ActionOptions $ActionOptions `
                -RiskConfirmed
        }

        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.ApartmentState = [System.Threading.ApartmentState]::STA
        $runspace.ThreadOptions = [System.Management.Automation.Runspaces.PSThreadOptions]::ReuseThread
        $runspace.Open()

        $powerShell = [powershell]::Create()
        $powerShell.Runspace = $runspace
        [void]$powerShell.AddScript($workerScript)
        [void]$powerShell.AddArgument($ProjectRoot)
        [void]$powerShell.AddArgument($tempProgramData)
        [void]$powerShell.AddArgument($ToolMetadata)
        [void]$powerShell.AddArgument($ActionName)
        [void]$powerShell.AddArgument($ActionOptions)

        $asyncResult = $powerShell.BeginInvoke()
        try {
            $output = @($powerShell.EndInvoke($asyncResult))
        }
        catch {
            $messageParts = [System.Collections.Generic.List[string]]::new()
            $messageParts.Add($_.Exception.Message)
            $innerException = $_.Exception.InnerException
            while ($null -ne $innerException) {
                $messageParts.Add($innerException.Message)
                $innerException = $innerException.InnerException
            }
            throw ('Runtime simulation failed for {0}:{1}: {2}' -f [string]$ToolMetadata['Id'], $ActionName, ($messageParts -join ' | '))
        }

        [pscustomobject]@{
            Result       = if ($output.Count -gt 0) { $output[$output.Count - 1] } else { $null }
            OutputCount  = $output.Count
            ErrorCount   = $powerShell.Streams.Error.Count
            StateCreated = Test-Path -LiteralPath (Join-Path $tempProgramData 'BoostLab\State\runtime-state.json') -PathType Leaf
        }
    }
    finally {
        if ($null -ne $powerShell) {
            $powerShell.Dispose()
        }
        if ($null -ne $runspace) {
            $runspace.Dispose()
        }
        Remove-Item -LiteralPath $tempProgramData -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Get-BoostLabToolById {
    param(
        [Parameter(Mandatory)]
        [object[]]$Tools,

        [Parameter(Mandatory)]
        [string]$ToolId
    )

    @($Tools | Where-Object { [string]$_.Id -eq $ToolId }) | Select-Object -First 1
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$allowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$driverInstallDebloatSettingsModulePath = Join-Path $ProjectRoot 'modules\Graphics\driver-install-debloat-settings.psm1'
$nvidiaAppModulePath = Join-Path $ProjectRoot 'modules\Graphics\nvidia-app-download.psm1'
$driverCleanModulePath = Join-Path $ProjectRoot 'modules\Graphics\driver-clean.psm1'
$installersModulePath = Join-Path $ProjectRoot 'modules\Installers\installers.psm1'
$directXModulePath = Join-Path $ProjectRoot 'modules\Graphics\directx.psm1'

foreach ($path in @(
    $configPath
    $uiPath
    $executionPath
    $artifactPath
    $allowlistPath
    $driverInstallDebloatSettingsModulePath
    $nvidiaAppModulePath
    $driverCleanModulePath
    $installersModulePath
    $directXModulePath
)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required reverse smoke file missing: $path"
}

$inventoryAssertion = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
$inventoryBaseline = $inventoryAssertion.Baseline
$inventorySnapshot = $inventoryAssertion.Snapshot
Assert-BoostLabCondition ([int]$inventorySnapshot.ActiveTools -eq [int]$inventoryBaseline.ActiveTools) 'Active tool baseline changed unexpectedly.'
Assert-BoostLabCondition ([int]$inventorySnapshot.ImplementedTools -eq [int]$inventoryBaseline.ImplementedTools) 'Implemented tool baseline changed unexpectedly.'
Assert-BoostLabCondition ([int]$inventorySnapshot.DeferredPlaceholders -eq [int]$inventoryBaseline.DeferredPlaceholders) 'Deferred placeholder baseline changed unexpectedly.'

$stages = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })
$uiText = Get-Content -LiteralPath $uiPath -Raw
$executionText = Get-Content -LiteralPath $executionPath -Raw

$reachedToolsForward = @(
    'bios-information',
    'bios-settings',
    'reinstall',
    'unattended',
    'updates-drivers-block',
    'to-bios',
    'bitlocker',
    'memory-compression',
    'date-language-region-time',
    'startup-apps-settings',
    'startup-apps-task-manager',
    'background-apps',
    'edge-settings',
    'store-settings',
    'updates-pause',
    'installers',
    'driver-clean',
    'driver-install-debloat-settings',
    'nvidia-app-download',
    'directx',
    'visual-cpp'
)
$reachedToolsReverse = @($reachedToolsForward)
[array]::Reverse($reachedToolsReverse)
Assert-BoostLabCondition (($reachedToolsReverse[0] -eq 'visual-cpp') -and ($reachedToolsReverse[-1] -eq 'bios-information')) 'Reverse audit scope must run from Visual C++ back to BIOS Information.'

foreach ($toolId in $reachedToolsForward) {
    Assert-BoostLabCondition ($null -ne (Get-BoostLabToolById -Tools $allTools -ToolId $toolId)) "Reached tool missing from active registry: $toolId"
}
foreach ($retiredToolId in @('driver-install-latest', 'nvidia-settings', 'hdcp', 'p0-state', 'msi-mode')) {
    Assert-BoostLabCondition ($null -eq (Get-BoostLabToolById -Tools $allTools -ToolId $retiredToolId)) "Retired NVIDIA tool remained in active registry: $retiredToolId"
}
foreach ($outOfScope in @('graphics-configuration-center')) {
    Assert-BoostLabCondition ($reachedToolsForward -notcontains $outOfScope) "Out-of-scope tool entered reverse audit scope: $outOfScope"
}

$driverInstallDebloatSettingsTool = Get-BoostLabToolById -Tools $allTools -ToolId 'driver-install-debloat-settings'
$nvidiaAppTool = Get-BoostLabToolById -Tools $allTools -ToolId 'nvidia-app-download'
$installersTool = Get-BoostLabToolById -Tools $allTools -ToolId 'installers'
$driverCleanTool = Get-BoostLabToolById -Tools $allTools -ToolId 'driver-clean'
$updatesDriversBlockTool = Get-BoostLabToolById -Tools $allTools -ToolId 'updates-drivers-block'

Assert-BoostLabCondition ([string]$driverInstallDebloatSettingsTool.SelectionMode -eq 'SingleSelect') 'Driver Install Debloat & Settings must expose a single-select branch selector.'
Assert-BoostLabCondition ((@($driverInstallDebloatSettingsTool.SelectionItems | ForEach-Object { [string]$_.Id }) -join '|') -eq 'NVIDIA|AMD|INTEL') 'Driver Install Debloat & Settings branch choices must be exactly NVIDIA, AMD, INTEL.'
Assert-BoostLabCondition ((@($driverInstallDebloatSettingsTool.SelectionRequiredActions) -join '|') -eq 'Open|Apply') 'Driver Install Debloat & Settings must require a selected branch for Open and Apply.'
Assert-BoostLabCondition ([string]$driverInstallDebloatSettingsTool.SelectionLabel -eq 'Select exactly one GPU branch for Open or Apply') 'Driver Install Debloat & Settings selection label must make the required branch obvious.'
Assert-BoostLabCondition ((@($nvidiaAppTool.Actions) -join '|') -eq 'Open') 'NVIDIA App shortcut must expose only Open.'
Assert-BoostLabCondition (-not $nvidiaAppTool.Contains('SelectionMode')) 'NVIDIA App shortcut must not expose branch/app selection.'
Assert-BoostLabCondition ([string]$installersTool.SelectionMode -eq 'SingleSelect') 'Installers must expose single-app selection.'
Assert-BoostLabCondition ([string]$installersTool.SelectionLabel -eq 'Select exactly one app to install') 'Installers selection label must require exactly one app.'
Assert-BoostLabCondition ('Apply' -in @($installersTool.SelectionRequiredActions)) 'Installers Apply must require one selected app ID.'
Assert-BoostLabCondition (@($installersTool.SelectionItems).Count -eq 16) 'Installers selected app list must reflect the Tarkov removal only.'
$installerSelectionIds = @($installersTool.SelectionItems | ForEach-Object { [string]$_['Id'] })
Assert-BoostLabCondition ('valorant' -in $installerSelectionIds) 'Valorant must remain visible/selectable in Installers.'
Assert-BoostLabCondition ('ubisoft-connect' -in $installerSelectionIds) 'Ubisoft Connect must remain visible/selectable in Installers.'
Assert-BoostLabCondition ('escape-from-tarkov' -notin $installerSelectionIds) 'Escape From Tarkov must remain absent from active Installers.'
Assert-BoostLabCondition (-not $driverCleanTool.Contains('SelectionMode')) 'Driver Clean must use Auto/Manual actions, not a branch selector.'
Assert-BoostLabCondition ((@($driverCleanTool.Actions) -join '|') -eq 'Analyze|Open|Apply') 'Driver Clean actions must remain Analyze/Open/Apply.'

foreach ($needle in @(
    "if (`$toolId -eq 'driver-clean')",
    "'Open' { return 'Manual' }",
    "'Apply' { return 'Auto' }",
    "if (`$toolId -eq 'nvidia-app-download')",
    "'Open' { return 'Open NVIDIA App Page' }",
    "if (`$toolId -eq 'directx')",
    "'Apply' { return 'Install DirectX' }",
    "if (`$toolId -eq 'visual-cpp')",
    "'Apply' { return 'Install Visual C++' }",
    "Select exactly one GPU branch: NVIDIA, AMD, or INTEL. No branch is selected automatically."
)) {
    Assert-BoostLabTextContains -Text $uiText -Needle $needle -Description 'Reached action label/tooltip contract'
}

foreach ($needle in @(
    "if (`$toolId -eq 'installers')",
    '$card.Height = 686',
    'Choose one installer to run. Only the selected installer will be downloaded/launched. No installer runs until you press Apply.',
    'Selected installer: none yet.',
    'Only this installer will run after Apply.',
    'Source menu {0} - single installer run',
    '$selectionScroll.Height = 320',
    '$selectionScroll.MinHeight = 320',
    '$selectionScroll.MaxHeight = 320',
    '$selectionPanel.Margin = [System.Windows.Thickness]::new(0, 0, 6, 18)'
)) {
    Assert-BoostLabTextContains -Text $uiText -Needle $needle -Description 'Installers readable single-select UI contract'
}

foreach ($needle in @(
    '$selectionMode -eq ''MultiSelect''',
    '$options[''SelectedAppIds''] = @($selectedIds)',
    '$selectionMode -eq ''SingleSelect''',
    '$options[''Branch'']',
    'System.Windows.Controls.RadioButton',
    'System.Windows.Controls.CheckBox',
    '$selectionControl.GroupName = "BoostLab_$($toolId)_Selection"'
)) {
    Assert-BoostLabTextContains -Text $uiText -Needle $needle -Description 'Shared UI selection option passing'
}

foreach ($needle in @(
    "if (`$explicitStatus -in @('NeedsBranchSelection', 'SelectionRequired'))",
    "'Warning' { 'Warning' }",
    "'Not applicable' { 'Info' }"
)) {
    Assert-BoostLabTextContains -Text $uiText -Needle $needle -Description 'Missing-selection non-error UI severity'
}
foreach ($needle in @(
    '$isSelectionPreconditionMissing = $moduleStatus -in @(''NeedsBranchSelection'', ''SelectionRequired'')',
    'Write-BoostLabWarning',
    "-EventId 'ToolAction.SelectionRequired'",
    "'Selection required'"
)) {
    Assert-BoostLabTextContains -Text $executionText -Needle $needle -Description 'Missing-selection non-error runtime severity'
}

Assert-BoostLabTextContains -Text ([string]$updatesDriversBlockTool.Description) -Needle 'USB media only' -Description 'Updates Drivers Block USB-only final scope'
Assert-BoostLabCondition (-not ((@($updatesDriversBlockTool.Actions) -join '|') -match 'Unblock')) 'Updates Drivers Block must not expose Unblock.'

$toolsWithDefaultAndRestore = @(
    $reachedToolsForward | Where-Object {
        $tool = Get-BoostLabToolById -Tools $allTools -ToolId $_
        $actions = @($tool.Actions)
        ($actions -contains 'Default') -and ($actions -contains 'Restore')
    }
)
foreach ($toolId in $toolsWithDefaultAndRestore) {
    $actions = @((Get-BoostLabToolById -Tools $allTools -ToolId $toolId).Actions)
    Assert-BoostLabCondition ([Array]::IndexOf($actions, 'Default') -ne [Array]::IndexOf($actions, 'Restore')) "Default and Restore must remain distinct for $toolId."
}

$amdIntelSelectionOwners = @(
    $allTools | Where-Object {
        $_.Contains('SelectionItems') -and
        (@($_.SelectionItems | ForEach-Object { [string]$_.Id }) -contains 'AMD' -or
         @($_.SelectionItems | ForEach-Object { [string]$_.Id }) -contains 'INTEL')
    } | ForEach-Object { [string]$_.Id }
)
Assert-BoostLabCondition ((@($amdIntelSelectionOwners | Sort-Object) -join '|') -eq 'driver-install-debloat-settings') 'AMD/INTEL branch selectors must remain scoped to Driver Install Debloat & Settings only.'

$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPath
$allowlistText = Get-Content -LiteralPath $allowlistPath -Raw
$runtimeArtifactText = (@($artifactPolicy.Artifacts) | Out-String)
Assert-BoostLabCondition (-not ($runtimeArtifactText -match '(?i)DDU|Display Driver Uninstaller|7zip|7-Zip')) 'DDU/7-Zip runtime artifact approval was added unexpectedly.'
$driverCleanProvenanceOnlyApprovals = @(
    $artifactPolicy.ProvenanceOnlyApprovals |
        Where-Object { [string]$_.SourceToolId -eq 'driver-clean' }
)
Assert-BoostLabCondition ($driverCleanProvenanceOnlyApprovals.Count -eq 2) 'Driver Clean must have exactly two Phase 164G provenance-only records.'
foreach ($approval in $driverCleanProvenanceOnlyApprovals) {
    Assert-BoostLabCondition ([string]$approval.ApprovalStatus -eq 'ApprovedForProvenanceOnly') "Driver Clean artifact record must be provenance-only: $($approval.ArtifactId)"
    Assert-BoostLabCondition ($approval.AllowExecution -eq $false) "Driver Clean provenance-only record must not allow execution: $($approval.ArtifactId)"
    Assert-BoostLabCondition ($approval.DownloadExecutionApproved -eq $false) "Driver Clean provenance-only record must not approve download execution: $($approval.ArtifactId)"
    Assert-BoostLabCondition ($approval.ProductionAllowlistApproved -eq $false) "Driver Clean provenance-only record must not approve production allowlist: $($approval.ArtifactId)"
}
Assert-BoostLabCondition (-not $allowlistText.Contains('driver-install-debloat-settings')) 'Production allowlist unexpectedly approved Driver Install Debloat & Settings.'

$analyzeTools = @($reachedToolsForward | Where-Object {
    @((Get-BoostLabToolById -Tools $allTools -ToolId $_).Actions) -contains 'Analyze'
})
foreach ($toolId in $analyzeTools) {
    $tool = Get-BoostLabToolById -Tools $allTools -ToolId $toolId
    $simulation = Invoke-BoostLabRuntimeActionSimulation -ProjectRoot $ProjectRoot -ToolMetadata $tool -ActionName 'Analyze'
    Assert-BoostLabCondition ($simulation.OutputCount -gt 0) "Analyze produced no result for $toolId."
    Assert-BoostLabCondition ($simulation.ErrorCount -eq 0) "Analyze emitted unexpected error stream records for $toolId."
    Assert-BoostLabCondition ($null -ne $simulation.Result) "Analyze returned null result for $toolId."
    Assert-BoostLabCondition ([string]$simulation.Result.Action -eq 'Analyze') "Analyze returned wrong action for $toolId."
    Assert-BoostLabCondition ($null -ne $simulation.Result.PSObject.Properties['ActionPlan']) "Analyze did not attach an ActionPlan for $toolId."
    Assert-BoostLabCondition ([string]$simulation.Result.ActionPlan.Action -eq 'Analyze') "Analyze ActionPlan action mismatch for $toolId."
    Assert-BoostLabCondition ($simulation.StateCreated) "Analyze did not initialize isolated runtime state for $toolId."
    if ($null -ne $simulation.Result.PSObject.Properties['Data'] -and $null -ne $simulation.Result.Data -and $null -ne $simulation.Result.Data.PSObject.Properties['NoMutationOccurred']) {
        Assert-BoostLabCondition ([bool]$simulation.Result.Data.NoMutationOccurred) "Analyze must report no mutation for $toolId."
    }
}

$mockOperationExecutor = {
    param($Operation, $SelectedBranch, $Context)
    [pscustomobject]@{
        Success = $true
        Order = [int]$Operation.Order
        Branch = [string]$Operation.Branch
        Category = [string]$Operation.Category
        Type = [string]$Operation.Type
        Label = [string]$Operation.Label
        SourceCommand = [string]$Operation.SourceCommand
        Message = 'Mocked operation; no host mutation.'
        Data = if ([string]$Operation.Type -eq 'SelectInstaller') {
            [pscustomobject]@{ SelectedInstaller = "C:\BoostLabMock\$SelectedBranch-driver.exe" }
        }
        else {
            $null
        }
        Timestamp = Get-Date
    }
}

$didsMissing = Invoke-BoostLabRuntimeActionSimulation -ProjectRoot $ProjectRoot -ToolMetadata $driverInstallDebloatSettingsTool -ActionName 'Apply' -ActionOptions @{}
Assert-BoostLabCondition (-not [bool]$didsMissing.Result.Success) 'Driver Install Debloat & Settings Apply without branch must fail closed.'
Assert-BoostLabCondition ([string]$didsMissing.Result.Status -eq 'NeedsBranchSelection') 'Driver Install Debloat & Settings missing branch status mismatch.'
Assert-BoostLabCondition (-not [bool]$didsMissing.Result.ChangesExecuted) 'Driver Install Debloat & Settings missing branch must execute nothing.'

$didsSelected = Invoke-BoostLabRuntimeActionSimulation -ProjectRoot $ProjectRoot -ToolMetadata $driverInstallDebloatSettingsTool -ActionName 'Open' -ActionOptions @{
    Branch = 'AMD'
    OperationExecutor = $mockOperationExecutor
}
Assert-BoostLabCondition ([bool]$didsSelected.Result.Success) 'Driver Install Debloat & Settings Open must receive selected branch through action options.'
Assert-BoostLabCondition ([string]$didsSelected.Result.Status -eq 'SourceDriverPageOpened') 'Driver Install Debloat & Settings selected Open status mismatch.'
Assert-BoostLabCondition ([string]$didsSelected.Result.Data.Branch -eq 'AMD') 'Driver Install Debloat & Settings selected Open did not use AMD branch.'
Assert-BoostLabCondition (@($didsSelected.Result.Data.Operations | Where-Object { [string]$_.Branch -ne 'AMD' }).Count -eq 0) 'Driver Install Debloat & Settings selected Open must not include other branch operations.'

$openedNvidiaAppUrls = [System.Collections.Generic.List[string]]::new()
$nvidiaAppOpen = Invoke-BoostLabRuntimeActionSimulation -ProjectRoot $ProjectRoot -ToolMetadata $nvidiaAppTool -ActionName 'Open' -ActionOptions @{
    UrlOpener = {
        param([string]$Url)
        $openedNvidiaAppUrls.Add($Url)
    }.GetNewClosure()
}
Assert-BoostLabCondition ([bool]$nvidiaAppOpen.Result.Success) 'NVIDIA App shortcut Open should succeed with mocked URL opener.'
Assert-BoostLabCondition ([string]$nvidiaAppOpen.Result.Url -eq 'https://www.nvidia.com/en-us/software/nvidia-app/') 'NVIDIA App shortcut Open URL mismatch.'
Assert-BoostLabCondition ($openedNvidiaAppUrls.Count -eq 1) 'NVIDIA App shortcut should open exactly one URL in the mocked opener.'
Assert-BoostLabCondition ([string]$openedNvidiaAppUrls[0] -eq 'https://www.nvidia.com/en-us/software/nvidia-app/') 'NVIDIA App shortcut mocked URL mismatch.'
Assert-BoostLabCondition (-not [bool]$nvidiaAppOpen.Result.ChangesExecuted) 'NVIDIA App shortcut must not report system changes.'

$installersMissing = Invoke-BoostLabRuntimeActionSimulation -ProjectRoot $ProjectRoot -ToolMetadata $installersTool -ActionName 'Apply' -ActionOptions @{}
Assert-BoostLabCondition (-not [bool]$installersMissing.Result.Success) 'Installers Apply without selected apps must fail closed.'
Assert-BoostLabCondition ([string]$installersMissing.Result.Status -eq 'SelectionRequired') 'Installers missing app selection status mismatch.'
Assert-BoostLabCondition (-not [bool]$installersMissing.Result.ChangesExecuted) 'Installers missing selection must execute nothing.'

$installerMock = {
    param($Operation, $App)
    [pscustomobject]@{
        Success = $true
        Message = 'Mocked installer queue operation; no host mutation.'
        Operation = $Operation
        AppId = [string]$App.AppId
    }
}
$installersSelected = Invoke-BoostLabRuntimeActionSimulation -ProjectRoot $ProjectRoot -ToolMetadata $installersTool -ActionName 'Apply' -ActionOptions @{
    Branch = 'discord'
    OperationExecutor = $installerMock
    SkipEnvironmentChecks = $true
}
Assert-BoostLabCondition ([bool]$installersSelected.Result.Success) 'Installers Apply must receive the single selected app through action options.'
Assert-BoostLabCondition ([string]$installersSelected.Result.Data.SelectedApp.AppId -eq 'discord') 'Installers selected app option propagation mismatch.'
Assert-BoostLabCondition (((@($installersSelected.Result.Data.Queue | ForEach-Object { [string]$_.AppId }) -join '|') -eq 'discord')) 'Installers diagnostic queue must contain only the selected app.'

$installersMultiSelected = Invoke-BoostLabRuntimeActionSimulation -ProjectRoot $ProjectRoot -ToolMetadata $installersTool -ActionName 'Apply' -ActionOptions @{
    SelectedAppIds = @('discord', 'steam')
    OperationExecutor = { throw 'side effects should not start for stale multi-select input' }
    SkipEnvironmentChecks = $true
}
Assert-BoostLabCondition (-not [bool]$installersMultiSelected.Result.Success) 'Installers stale multi-select input must fail closed.'
Assert-BoostLabCondition ([string]$installersMultiSelected.Result.Status -eq 'SelectionRequired') 'Installers stale multi-select status mismatch.'
Assert-BoostLabCondition (-not [bool]$installersMultiSelected.Result.ChangesExecuted) 'Installers stale multi-select input must execute nothing.'

foreach ($needle in @(
    'function Invoke-BoostLabToolCardActionAsync',
    '$script:BoostLabAsyncActionState = @{',
    '$script:BoostLabActionInProgressKey = $actionKey',
    '$script:BoostLabActionInProgressKey = ''''',
    '$Context.ActionButton.IsEnabled = $false',
    '$Context.ActionButton.IsEnabled = $true',
    'function Get-BoostLabAsyncStreamDiagnostics',
    'function New-BoostLabAsyncRuntimeFailureResult',
    'function Complete-BoostLabToolCardAction',
    'Add-BoostLabToolActionActivityEntry `',
    'Show-BoostLabActionResult `',
    'Tool async completion failed',
    'Another BoostLab action is already running'
)) {
    Assert-BoostLabTextContains -Text $uiText -Needle $needle -Description 'Async/latest-result/activity-log contract'
}

foreach ($protectedPath in @('source-ultimate', 'source-ultimate\_intake-promoted', 'intake')) {
    $fullPath = Join-Path $ProjectRoot $protectedPath
    if (Test-Path -LiteralPath $fullPath) {
        $recent = @(Get-ChildItem -LiteralPath $fullPath -Recurse -File | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-6) })
        Assert-BoostLabCondition ($recent.Count -eq 0) "Protected path has recent modifications during reverse reached-tool audit: $protectedPath"
    }
}

Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'modules\Graphics\ddu.psm1'))) 'Standalone DDU module was reintroduced.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\23 NVME Faster Driver.ps1'))) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    TestName = 'ReverseReachedToolGuiRuntimeContract'
    ReachedToolCount = $reachedToolsForward.Count
    AnalyzeToolsChecked = $analyzeTools.Count
    SelectionToolsChecked = @('driver-install-debloat-settings', 'installers')
    MissingSelectionSeverity = 'Warning'
    AsyncBusyCleanup = 'Static contract present'
    RealHostMutationDuringTest = $false
    SourceUltimateUnchanged = $true
    Message = 'Reverse reached-tools GUI/runtime smoke contract is valid through Visual C++ with mock-safe action option propagation.'
}
