Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PSScriptRoot) {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}
else {
    $scriptPath = $PSCommandPath
    if (-not $scriptPath -and $MyInvocation.MyCommand.Path) {
        $scriptPath = $MyInvocation.MyCommand.Path
    }
    if (-not $scriptPath) {
        throw 'Unable to determine the NVIDIA Graphics simplification validator path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
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

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
. (Join-Path $ProjectRoot 'tests\BoostLab.ParityStatusBaseline.ps1')

$removedToolIds = @(
    'driver-install-latest'
    'nvidia-settings'
    'hdcp'
    'p0-state'
    'msi-mode'
)
$removedToolTitles = @(
    'Driver Install Latest'
    'Nvidia Settings'
    'HDCP'
    'P0 State'
    'Msi Mode'
)
$expectedGraphicsOrder = @(
    'driver-clean'
    'driver-install-debloat-settings'
    'nvidia-app-download'
    'directx'
    'visual-cpp'
    'graphics-configuration-center'
)
$nvidiaAppUrl = 'https://www.nvidia.com/en-us/software/nvidia-app/'

$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$externalSourcesPath = Join-Path $ProjectRoot 'config\ExternalArtifactSources.psd1'
$artifactProvenancePath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$nvidiaAppModulePath = Join-Path $ProjectRoot 'modules\Graphics\nvidia-app-download.psm1'

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })
$graphicsStage = @($stages.Stages | Where-Object { [string]$_.Name -eq 'Graphics' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $graphicsStage) 'Graphics stage is missing.'

$actualGraphicsOrder = @($graphicsStage.Tools | Sort-Object { [int]$_.Order } | ForEach-Object { [string]$_.Id })
Assert-BoostLabCondition ((@($actualGraphicsOrder) -join '|') -eq (@($expectedGraphicsOrder) -join '|')) "Graphics stage order mismatch. Expected $($expectedGraphicsOrder -join ' -> '), found $($actualGraphicsOrder -join ' -> ')."

foreach ($removedToolId in $removedToolIds) {
    Assert-BoostLabCondition ((@($allTools | Where-Object { [string]$_.Id -eq $removedToolId }).Count) -eq 0) "Retired tool remains in active stage catalog: $removedToolId"
    Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot "modules\Graphics\$removedToolId.psm1"))) "Retired module still exists: modules\Graphics\$removedToolId.psm1"
}

$driverDebloatTool = @($allTools | Where-Object { [string]$_.Id -eq 'driver-install-debloat-settings' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $driverDebloatTool) 'Driver Install Debloat & Settings must remain active.'
Assert-BoostLabCondition ([string]$driverDebloatTool.SelectionMode -eq 'SingleSelect') 'Driver Install Debloat & Settings must retain single-select branch selection.'
Assert-BoostLabCondition ((@($driverDebloatTool.SelectionItems | ForEach-Object { [string]$_.Id }) -join '|') -eq 'NVIDIA|AMD|INTEL') 'Driver Install Debloat & Settings branch list changed.'

$nvidiaAppTool = @($allTools | Where-Object { [string]$_.Id -eq 'nvidia-app-download' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $nvidiaAppTool) 'NVIDIA App download shortcut is missing.'
Assert-BoostLabCondition ([string]$nvidiaAppTool.Title -eq 'Install NVIDIA App') 'NVIDIA App shortcut title mismatch.'
Assert-BoostLabCondition ([int]$nvidiaAppTool.Order -eq 3) 'NVIDIA App shortcut must be Graphics order 3.'
Assert-BoostLabCondition ((@($nvidiaAppTool.Actions) -join '|') -eq 'Open') 'NVIDIA App shortcut must expose only Open.'
Assert-BoostLabCondition ([string]$nvidiaAppTool.RiskLevel -eq 'low') 'NVIDIA App shortcut must be low risk.'
Assert-BoostLabCondition (-not [bool]$nvidiaAppTool.Capabilities.RequiresAdmin) 'NVIDIA App shortcut must not require admin.'
Assert-BoostLabCondition ([bool]$nvidiaAppTool.Capabilities.RequiresInternet) 'NVIDIA App shortcut must declare internet requirement.'
foreach ($capability in @('CanDownload', 'CanInstallSoftware', 'CanModifyRegistry', 'CanModifyServices', 'CanModifyDrivers', 'CanModifySecurity', 'CanDeleteFiles', 'CanReboot', 'UsesTrustedInstaller', 'UsesSafeMode', 'SupportsDefault', 'SupportsRestore', 'NeedsExplicitConfirmation')) {
    Assert-BoostLabCondition (-not [bool]$nvidiaAppTool.Capabilities[$capability]) "NVIDIA App shortcut capability must be false: $capability"
}

$executionText = Get-Content -Raw -LiteralPath $executionPath
$uiText = Get-Content -Raw -LiteralPath $uiPath
$actionPlanText = Get-Content -Raw -LiteralPath $actionPlanPath
foreach ($removedToolId in $removedToolIds) {
    Assert-BoostLabCondition (-not $executionText.Contains("'$removedToolId'")) "Execution still registers retired tool id: $removedToolId"
    Assert-BoostLabCondition (-not $uiText.Contains("'$removedToolId'")) "UI still has production label/async routing for retired tool id: $removedToolId"
    Assert-BoostLabCondition (-not $actionPlanText.Contains("'$removedToolId'")) "ActionPlan still has production routing for retired tool id: $removedToolId"
}
Assert-BoostLabCondition ($executionText.Contains("'nvidia-app-download'")) 'Execution registry must include nvidia-app-download.'
Assert-BoostLabCondition ($uiText.Contains("if (`$toolId -eq 'nvidia-app-download')")) 'UI must include NVIDIA App shortcut label mapping.'
Assert-BoostLabCondition ($uiText.Contains("'Open' { return 'Open NVIDIA App Page' }")) 'UI must label the NVIDIA App shortcut truthfully.'
Assert-BoostLabCondition ($actionPlanText.Contains($nvidiaAppUrl)) 'ActionPlan must name the exact NVIDIA App URL.'

Import-Module -Force -Name $actionPlanPath
try {
    $plan = New-BoostLabActionPlan -ToolMetadata $nvidiaAppTool -ActionName 'Open'
    Assert-BoostLabCondition (-not [bool]$plan.NeedsExplicitConfirmation) 'NVIDIA App shortcut must not require explicit confirmation.'
    Assert-BoostLabCondition (-not [bool]$plan.RequiresAdmin) 'NVIDIA App action plan must not require admin.'
    Assert-BoostLabCondition ([bool]$plan.RequiresInternet) 'NVIDIA App action plan must require internet.'
    Assert-BoostLabCondition (-not [bool]$plan.Capabilities.CanDownload) 'NVIDIA App action plan must not declare direct download capability.'
    Assert-BoostLabCondition (-not [bool]$plan.Capabilities.CanInstallSoftware) 'NVIDIA App action plan must not declare install capability.'
    Assert-BoostLabCondition ((@($plan.PlannedChanges) -join "`n").Contains($nvidiaAppUrl)) 'NVIDIA App action plan must open only the expected URL.'
    Assert-BoostLabCondition ((@($plan.PlannedChanges) -join "`n") -match 'Do not download, install') 'NVIDIA App action plan must state that BoostLab does not download or install.'
}
finally {
    Remove-Module -Name ActionPlan -Force -ErrorAction SilentlyContinue
}

Assert-BoostLabCondition (Test-Path -LiteralPath $nvidiaAppModulePath) 'NVIDIA App shortcut module is missing.'
Import-Module -Force -Name $nvidiaAppModulePath
try {
    $moduleInfo = Get-BoostLabToolInfo
    Assert-BoostLabCondition ([string]$moduleInfo.Id -eq 'nvidia-app-download') 'NVIDIA App module info id mismatch.'
    Assert-BoostLabCondition ([string]$moduleInfo.Url -eq $nvidiaAppUrl) 'NVIDIA App module must expose the exact URL.'
    Assert-BoostLabCondition ((@($moduleInfo.Actions) -join '|') -eq 'Open') 'NVIDIA App module must expose only Open.'
    Assert-BoostLabCondition (-not [bool]$moduleInfo.Capabilities.CanDownload) 'NVIDIA App module must not download.'
    Assert-BoostLabCondition (-not [bool]$moduleInfo.Capabilities.CanInstallSoftware) 'NVIDIA App module must not install.'

    $script:openedUrls = @()
    $result = Invoke-BoostLabNvidiaAppDownloadOpen -UrlOpener {
        param([string]$Url)
        $script:openedUrls += $Url
    }
    Assert-BoostLabCondition ([bool]$result.Success) 'Mocked NVIDIA App Open should succeed.'
    Assert-BoostLabCondition ((@($script:openedUrls) -join '|') -eq $nvidiaAppUrl) 'Mocked NVIDIA App Open must use only the expected URL.'
    Assert-BoostLabCondition (-not [bool]$result.ChangesExecuted) 'NVIDIA App Open result must not claim system changes.'
}
finally {
    Remove-Module -Name nvidia-app-download -Force -ErrorAction SilentlyContinue
}

$externalSources = Import-PowerShellDataFile -LiteralPath $externalSourcesPath
$provenance = Import-PowerShellDataFile -LiteralPath $artifactProvenancePath
foreach ($removedToolId in $removedToolIds) {
    Assert-BoostLabCondition ((@($externalSources.ExternalSources | Where-Object { [string]$_.ToolId -eq $removedToolId }).Count) -eq 0) "External artifact source remains for retired tool: $removedToolId"
    Assert-BoostLabCondition ((@($externalSources.OfficialVendorDirectRuntimePolicy.Entries | Where-Object { [string]$_.Id -like "$removedToolId*" }).Count) -eq 0) "Official vendor runtime policy remains for retired tool: $removedToolId"
    Assert-BoostLabCondition ((@($provenance.ProvenanceOnlyApprovals | Where-Object { [string]$_.SourceToolId -eq $removedToolId }).Count) -eq 0) "Artifact provenance remains for retired tool: $removedToolId"
}
$nvidiaAppExternal = @($externalSources.ExternalSources | Where-Object { [string]$_.Id -eq 'nvidia-app-download-page' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $nvidiaAppExternal) 'NVIDIA App official page external source entry is missing.'
Assert-BoostLabCondition ([string]$nvidiaAppExternal.ToolId -eq 'nvidia-app-download') 'NVIDIA App external source ToolId mismatch.'
Assert-BoostLabCondition ([string]$nvidiaAppExternal.OriginalDownloadUrl -eq $nvidiaAppUrl) 'NVIDIA App external source URL mismatch.'
Assert-BoostLabCondition ([string]$nvidiaAppExternal.SourceClassification -eq 'OfficialVendorDirect') 'NVIDIA App page must be OfficialVendorDirect.'
Assert-BoostLabCondition ([string]$nvidiaAppExternal.MirrorStatus -eq 'NotRequiredOfficial') 'NVIDIA App page must not require a BoostLab mirror.'

$nvidiaAppOfficialPolicy = @($externalSources.OfficialVendorDirectRuntimePolicy.Entries | Where-Object { [string]$_.Id -eq 'nvidia-app-download-page' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $nvidiaAppOfficialPolicy) 'NVIDIA App official-source runtime policy entry is missing.'
Assert-BoostLabCondition ([string]$nvidiaAppOfficialPolicy.OfficialSourceKind -eq 'OfficialVendorLookupPage') 'NVIDIA App source kind must be lookup page.'
Assert-BoostLabCondition ((@($nvidiaAppOfficialPolicy.OfficialHostAllowlist) -join '|') -eq 'www.nvidia.com') 'NVIDIA App host allowlist mismatch.'
Assert-BoostLabCondition ([bool]$nvidiaAppOfficialPolicy.LookupExecutionApproved) 'NVIDIA App page open must be lookup-approved.'
Assert-BoostLabCondition (-not [bool]$nvidiaAppOfficialPolicy.DownloadExecutionApproved) 'NVIDIA App page must not be direct-download approved.'
Assert-BoostLabCondition (-not [bool]$nvidiaAppOfficialPolicy.InstallerExecutionApproved) 'NVIDIA App page must not be installer-approved.'
Assert-BoostLabCondition (-not [bool]$nvidiaAppOfficialPolicy.SignatureVerificationRequired) 'NVIDIA App page must not require executable signature verification.'

$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$parityRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'nvidia-app-download' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $parityRecord) 'NVIDIA App shortcut parity record is missing.'
Assert-BoostLabCondition ([string]$parityRecord.ImplementationLevel -eq 'ParityImplemented') 'NVIDIA App shortcut must be marked implemented.'
Assert-BoostLabCondition ([string]$parityRecord.UltimateParity -eq 'Yes') 'NVIDIA App shortcut must be closed as a product shortcut.'
Assert-BoostLabCondition ([string]$parityRecord.SourceType -eq 'BoostLabProductShortcut') 'NVIDIA App shortcut source type mismatch.'
foreach ($removedToolId in $removedToolIds) {
    Assert-BoostLabCondition ((@($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq $removedToolId }).Count) -eq 0) "Parity baseline still has retired active tool record: $removedToolId"
}
foreach ($removedToolTitle in $removedToolTitles) {
    Assert-BoostLabCondition ($removedToolTitle -in @($parityBaseline.RefusedOrDeletedOutsideActiveCatalog)) "Retired tool title missing from refused/deleted catalog: $removedToolTitle"
}
$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
Assert-BoostLabCondition ([int]$categoryCounts['ParityImplemented'] -eq [int]$parityBaseline.Counts.UltimateParityImplemented) 'ParityImplemented count must be baseline-derived and consistent.'
Assert-BoostLabCondition ([int]$categoryCounts['NearParityControlled'] -eq [int]$parityBaseline.Counts.NearParityControlled) 'NearParityControlled count must be baseline-derived and consistent.'

$inventory = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
Assert-BoostLabCondition ([int]$inventory.Snapshot.ActiveTools -eq [int]$inventory.Baseline.ActiveTools) 'Inventory active tool count mismatch.'
Assert-BoostLabCondition ([int]$inventory.Snapshot.ImplementedTools -eq [int]$inventory.Baseline.ImplementedTools) 'Inventory implemented tool count mismatch.'
Assert-BoostLabCondition ([int]$inventory.Snapshot.DeferredPlaceholders -eq 0) 'Inventory deferred placeholders must remain zero.'

[pscustomobject]@{
    Success = $true
    GraphicsOrder = $actualGraphicsOrder
    RemovedToolIds = $removedToolIds
    NvidiaAppUrl = $nvidiaAppUrl
    ActiveTools = $inventory.Snapshot.ActiveTools
    ImplementedTools = $inventory.Snapshot.ImplementedTools
    DeferredPlaceholders = $inventory.Snapshot.DeferredPlaceholders
    Message = 'Phase 173A Graphics simplification contract is satisfied.'
    Timestamp = Get-Date
}
