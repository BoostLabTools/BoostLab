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
    'nvidia-app-install'
    'directx'
    'visual-cpp'
    'graphics-configuration-center'
)
$nvidiaAppUrl = 'https://us.download.nvidia.com/nvapp/client/11.0.6.383/NVIDIA_app_v11.0.6.383.exe'
$nvidiaAppArtifactId = 'nvidia-app-installer'
$nvidiaAppDestinationFileName = 'NvidiaApp.exe'
$nvidiaAppSourceFileName = 'NVIDIA_app_v11.0.6.383.exe'
$nvidiaAppInstallerArguments = '/s'

$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$externalSourcesPath = Join-Path $ProjectRoot 'config\ExternalArtifactSources.psd1'
$artifactProvenancePath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$nvidiaAppModulePath = Join-Path $ProjectRoot 'modules\Graphics\nvidia-app-install.psm1'

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

$nvidiaAppTool = @($allTools | Where-Object { [string]$_.Id -eq 'nvidia-app-install' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $nvidiaAppTool) 'NVIDIA App Graphics installer tool is missing.'
Assert-BoostLabCondition ([string]$nvidiaAppTool.Title -eq 'Install NVIDIA App') 'NVIDIA App installer title mismatch.'
Assert-BoostLabCondition ([int]$nvidiaAppTool.Order -eq 3) 'NVIDIA App installer must be Graphics order 3.'
Assert-BoostLabCondition ((@($nvidiaAppTool.Actions) -join '|') -eq 'Analyze|Apply') 'NVIDIA App installer must expose Analyze and Apply.'
Assert-BoostLabCondition ([string]$nvidiaAppTool.RiskLevel -eq 'high') 'NVIDIA App installer must use installer-grade risk.'
Assert-BoostLabCondition ([bool]$nvidiaAppTool.Capabilities.RequiresAdmin) 'NVIDIA App installer must require admin.'
Assert-BoostLabCondition ([bool]$nvidiaAppTool.Capabilities.RequiresInternet) 'NVIDIA App installer must require internet.'
Assert-BoostLabCondition ([bool]$nvidiaAppTool.Capabilities.CanDownload) 'NVIDIA App installer must declare download capability.'
Assert-BoostLabCondition ([bool]$nvidiaAppTool.Capabilities.CanInstallSoftware) 'NVIDIA App installer must declare install capability.'
Assert-BoostLabCondition ([bool]$nvidiaAppTool.Capabilities.CanDeleteFiles) 'NVIDIA App installer must declare source cleanup file capability.'
Assert-BoostLabCondition ([bool]$nvidiaAppTool.Capabilities.NeedsExplicitConfirmation) 'NVIDIA App installer must require explicit confirmation.'
foreach ($capability in @('CanModifyRegistry', 'CanModifyServices', 'CanModifyDrivers', 'CanModifySecurity', 'CanReboot', 'UsesTrustedInstaller', 'UsesSafeMode', 'SupportsDefault', 'SupportsRestore')) {
    Assert-BoostLabCondition (-not [bool]$nvidiaAppTool.Capabilities[$capability]) "NVIDIA App installer capability must be false: $capability"
}

$executionText = Get-Content -Raw -LiteralPath $executionPath
$uiText = Get-Content -Raw -LiteralPath $uiPath
$actionPlanText = Get-Content -Raw -LiteralPath $actionPlanPath
foreach ($removedToolId in $removedToolIds) {
    Assert-BoostLabCondition (-not $executionText.Contains("'$removedToolId'")) "Execution still registers retired tool id: $removedToolId"
    Assert-BoostLabCondition (-not $uiText.Contains("'$removedToolId'")) "UI still has production label/async routing for retired tool id: $removedToolId"
    Assert-BoostLabCondition (-not $actionPlanText.Contains("'$removedToolId'")) "ActionPlan still has production routing for retired tool id: $removedToolId"
}
Assert-BoostLabCondition ($executionText.Contains("'nvidia-app-install'")) 'Execution registry must include nvidia-app-install.'
Assert-BoostLabCondition ($uiText.Contains("if (`$toolId -eq 'nvidia-app-install')")) 'UI must include NVIDIA App installer label mapping.'
Assert-BoostLabCondition ($uiText.Contains("'Apply' { return 'Install NVIDIA App' }")) 'UI must label the NVIDIA App installer truthfully.'
Assert-BoostLabCondition ($actionPlanText.Contains($nvidiaAppUrl)) 'ActionPlan must name the exact NVIDIA App URL.'

Import-Module -Force -Name $actionPlanPath
try {
    $plan = New-BoostLabActionPlan -ToolMetadata $nvidiaAppTool -ActionName 'Apply'
    Assert-BoostLabCondition ([bool]$plan.NeedsExplicitConfirmation) 'NVIDIA App installer must require explicit confirmation.'
    Assert-BoostLabCondition ([bool]$plan.RequiresAdmin) 'NVIDIA App installer action plan must require admin.'
    Assert-BoostLabCondition ([bool]$plan.RequiresInternet) 'NVIDIA App installer action plan must require internet.'
    Assert-BoostLabCondition ([bool]$plan.Capabilities.CanDownload) 'NVIDIA App installer action plan must declare download capability.'
    Assert-BoostLabCondition ([bool]$plan.Capabilities.CanInstallSoftware) 'NVIDIA App installer action plan must declare install capability.'
    Assert-BoostLabCondition ((@($plan.PlannedChanges) -join "`n").Contains($nvidiaAppUrl)) 'NVIDIA App action plan must use the exact source URL.'
    Assert-BoostLabCondition ((@($plan.PlannedChanges) -join "`n").Contains($nvidiaAppInstallerArguments)) 'NVIDIA App action plan must use the exact source installer argument.'
    Assert-BoostLabCondition ((@($plan.PlannedChanges) -join "`n") -match 'Start Menu shortcut cleanup') 'NVIDIA App action plan must include source-defined shortcut cleanup.'
}
finally {
    Remove-Module -Name ActionPlan -Force -ErrorAction SilentlyContinue
}

Assert-BoostLabCondition (Test-Path -LiteralPath $nvidiaAppModulePath) 'NVIDIA App installer module is missing.'
Import-Module -Force -Name $nvidiaAppModulePath
$mockRoot = $null
$previousSystemRoot = $env:SystemRoot
try {
    $moduleInfo = Get-BoostLabToolInfo
    Assert-BoostLabCondition ([string]$moduleInfo.Id -eq 'nvidia-app-install') 'NVIDIA App module info id mismatch.'
    Assert-BoostLabCondition ([string]$moduleInfo.SourceUrl -eq $nvidiaAppUrl) 'NVIDIA App module must expose the exact source URL.'
    Assert-BoostLabCondition ([string]$moduleInfo.ArtifactId -eq $nvidiaAppArtifactId) 'NVIDIA App module artifact id mismatch.'
    Assert-BoostLabCondition ((@($moduleInfo.Actions) -join '|') -eq 'Analyze|Apply') 'NVIDIA App module must expose Analyze and Apply.'
    Assert-BoostLabCondition ([bool]$moduleInfo.Capabilities.CanDownload) 'NVIDIA App module must download through policy.'
    Assert-BoostLabCondition ([bool]$moduleInfo.Capabilities.CanInstallSoftware) 'NVIDIA App module must install.'

    $analysis = Invoke-BoostLabToolAction -ActionName 'Analyze'
    Assert-BoostLabCondition ([bool]$analysis.Success) 'NVIDIA App Analyze should succeed.'
    Assert-BoostLabCondition ([string]$analysis.Status -eq 'Analyzed') 'NVIDIA App Analyze status mismatch.'
    Assert-BoostLabCondition ([bool]$analysis.Data.NoMutationOccurred) 'NVIDIA App Analyze must be read-only.'
    Assert-BoostLabCondition ([string]$analysis.Data.ArtifactSources[0].SourceUrl -eq $nvidiaAppUrl) 'NVIDIA App Analyze source URL mismatch.'
    Assert-BoostLabCondition ((@($analysis.Data.OperationPlan | ForEach-Object { [string]$_.Type }) -join '|') -eq 'Download|StartProcess|MoveItem|RemoveItem') 'NVIDIA App operation plan must preserve the four source operations.'

    $mockRoot = Join-Path ([IO.Path]::GetTempPath()) ('BoostLab-NvidiaApp-Mock-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $mockRoot -Force -ErrorAction Stop | Out-Null
    $env:SystemRoot = $mockRoot
    $downloadOnly = Invoke-BoostLabNvidiaAppInstallOperationPlan `
        -Plan @(@($analysis.Data.OperationPlan | Where-Object { [string]$_.Type -eq 'Download' })[0]) `
        -Downloader {
            param([string]$Url, [string]$Destination)
            Assert-BoostLabCondition ([string]$Url -eq $nvidiaAppUrl) 'NVIDIA App downloader URL mismatch.'
            Assert-BoostLabCondition ([IO.Path]::GetFileName($Destination) -eq $nvidiaAppDestinationFileName) 'NVIDIA App download destination filename mismatch.'
            Set-Content -LiteralPath $Destination -Value 'mock NVIDIA App installer' -Force -ErrorAction Stop
        } `
        -SignatureInspector {
            param([string]$Path)
            [pscustomobject]@{ Status = 'Valid'; Publisher = 'NVIDIA Corporation' }
        }
    Assert-BoostLabCondition ([bool]$downloadOnly.Success) 'NVIDIA App official vendor download helper path should pass with mocked downloader/signature.'
    Assert-BoostLabCondition ([string]$downloadOnly.Operations[0].Data.ArtifactId -eq $nvidiaAppArtifactId) 'NVIDIA App official download artifact id mismatch.'

    $script:mockOperations = @()
    $result = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed $true -OperationExecutor {
        param($Operation)
        $script:mockOperations += [string]$Operation.Type
        [pscustomobject]@{
            Success = $true
            Order = [int]$Operation.Order
            Type = [string]$Operation.Type
            Label = [string]$Operation.Label
            Required = [bool]$Operation.Required
            Status = 'Completed'
            Message = 'Mocked NVIDIA App operation; no host mutation.'
            SourceCommand = [string]$Operation.SourceCommand
            Timestamp = Get-Date
        }
    }
    Assert-BoostLabCondition ([bool]$result.Success) 'Mocked NVIDIA App Apply should succeed.'
    Assert-BoostLabCondition ([string]$result.Action -eq 'Apply') 'NVIDIA App Apply action mismatch.'
    Assert-BoostLabCondition ([bool]$result.ChangesExecuted) 'NVIDIA App Apply must report changes requested.'
    Assert-BoostLabCondition ((@($script:mockOperations) -join '|') -eq 'Download|StartProcess|MoveItem|RemoveItem') 'NVIDIA App Apply must request exactly the source operations in order.'
    Assert-BoostLabCondition ((@($result.Data.Operations | ForEach-Object { [string]$_.Type }) -join '|') -eq 'Download|StartProcess|MoveItem|RemoveItem') 'NVIDIA App Apply result operation list mismatch.'
}
finally {
    $env:SystemRoot = $previousSystemRoot
    if (-not [string]::IsNullOrWhiteSpace($mockRoot) -and (Test-Path -LiteralPath $mockRoot)) {
        Remove-Item -LiteralPath $mockRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    Remove-Module -Name nvidia-app-install -Force -ErrorAction SilentlyContinue
}

$externalSources = Import-PowerShellDataFile -LiteralPath $externalSourcesPath
$provenance = Import-PowerShellDataFile -LiteralPath $artifactProvenancePath
foreach ($removedToolId in $removedToolIds) {
    Assert-BoostLabCondition ((@($externalSources.ExternalSources | Where-Object { [string]$_.ToolId -eq $removedToolId }).Count) -eq 0) "External artifact source remains for retired tool: $removedToolId"
    Assert-BoostLabCondition ((@($externalSources.OfficialVendorDirectRuntimePolicy.Entries | Where-Object { [string]$_.Id -like "$removedToolId*" }).Count) -eq 0) "Official vendor runtime policy remains for retired tool: $removedToolId"
    Assert-BoostLabCondition ((@($provenance.ProvenanceOnlyApprovals | Where-Object { [string]$_.SourceToolId -eq $removedToolId }).Count) -eq 0) "Artifact provenance remains for retired tool: $removedToolId"
}
$nvidiaAppExternal = @($externalSources.ExternalSources | Where-Object { [string]$_.Id -eq $nvidiaAppArtifactId }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $nvidiaAppExternal) 'NVIDIA App official installer external source entry is missing.'
Assert-BoostLabCondition ([string]$nvidiaAppExternal.ToolId -eq 'nvidia-app-install') 'NVIDIA App external source ToolId mismatch.'
Assert-BoostLabCondition ([string]$nvidiaAppExternal.OriginalDownloadUrl -eq $nvidiaAppUrl) 'NVIDIA App external source URL mismatch.'
Assert-BoostLabCondition ([string]$nvidiaAppExternal.SourceScriptPath -eq 'source-ultimate/4 Installers/1 Installers.ps1') 'NVIDIA App installer source script path mismatch.'
Assert-BoostLabCondition ([string]$nvidiaAppExternal.OperationKind -eq 'DownloadInstaller') 'NVIDIA App external source must be a download installer operation.'
Assert-BoostLabCondition ([string]$nvidiaAppExternal.SourceClassification -eq 'OfficialVendorDirect') 'NVIDIA App installer must be OfficialVendorDirect.'
Assert-BoostLabCondition ([string]$nvidiaAppExternal.MirrorStatus -eq 'NotRequiredOfficial') 'NVIDIA App installer must not require a BoostLab mirror.'

$nvidiaAppOfficialPolicy = @($externalSources.OfficialVendorDirectRuntimePolicy.Entries | Where-Object { [string]$_.Id -eq $nvidiaAppArtifactId }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $nvidiaAppOfficialPolicy) 'NVIDIA App official-source runtime policy entry is missing.'
Assert-BoostLabCondition ([string]$nvidiaAppOfficialPolicy.OfficialSourceKind -eq 'StaticOfficialInstaller') 'NVIDIA App source kind must be static official installer.'
Assert-BoostLabCondition ((@($nvidiaAppOfficialPolicy.OfficialHostAllowlist) -join '|') -eq 'us.download.nvidia.com') 'NVIDIA App host allowlist mismatch.'
Assert-BoostLabCondition (-not [bool]$nvidiaAppOfficialPolicy.LookupExecutionApproved) 'NVIDIA App installer must not be lookup-only.'
Assert-BoostLabCondition ([bool]$nvidiaAppOfficialPolicy.DownloadExecutionApproved) 'NVIDIA App installer must be direct-download approved.'
Assert-BoostLabCondition ([bool]$nvidiaAppOfficialPolicy.InstallerExecutionApproved) 'NVIDIA App installer must be installer-approved.'
Assert-BoostLabCondition ([bool]$nvidiaAppOfficialPolicy.RequiresVerifiedLocalPath) 'NVIDIA App installer must require verified local path.'
Assert-BoostLabCondition ([bool]$nvidiaAppOfficialPolicy.SignatureVerificationRequired) 'NVIDIA App installer must require executable signature verification.'
Assert-BoostLabCondition ([string]$nvidiaAppOfficialPolicy.ExpectedSourceFileName -eq $nvidiaAppSourceFileName) 'NVIDIA App source filename mismatch.'
Assert-BoostLabCondition ([string]$nvidiaAppOfficialPolicy.ExpectedFileName -eq $nvidiaAppDestinationFileName) 'NVIDIA App local filename mismatch.'

$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$parityRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'nvidia-app-install' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $parityRecord) 'NVIDIA App installer parity record is missing.'
Assert-BoostLabCondition ([string]$parityRecord.ImplementationLevel -eq 'ParityImplemented') 'NVIDIA App installer must be marked implemented.'
Assert-BoostLabCondition ([string]$parityRecord.UltimateParity -eq 'Yes') 'NVIDIA App installer must be closed as source-equivalent.'
Assert-BoostLabCondition ([string]$parityRecord.SourceType -eq 'UltimateInstallerOptionPromotedToGraphics') 'NVIDIA App installer source type mismatch.'
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
