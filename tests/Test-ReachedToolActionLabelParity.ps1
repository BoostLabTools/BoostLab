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
        throw 'Unable to determine the reached-tool action label parity validator path.'
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

function Assert-BoostLabTextContains {
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [string]$Needle,

        [Parameter(Mandatory)]
        [string]$Description
    )

    if (-not $Text.Contains($Needle)) {
        throw "$Description missing expected text: $Needle"
    }
}

function Get-BoostLabTextBetween {
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [string]$Start,

        [Parameter(Mandatory)]
        [string]$End
    )

    $startIndex = $Text.IndexOf($Start, [StringComparison]::Ordinal)
    Assert-BoostLabCondition ($startIndex -ge 0) "Unable to find block start: $Start"

    $endIndex = $Text.IndexOf($End, $startIndex + $Start.Length, [StringComparison]::Ordinal)
    Assert-BoostLabCondition ($endIndex -gt $startIndex) "Unable to find block end: $End"

    return $Text.Substring($startIndex, $endIndex - $startIndex)
}

$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$driverCleanModulePath = Join-Path $ProjectRoot 'modules\Graphics\driver-clean.psm1'
$driverCleanSourcePath = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate\5 Graphics\1 Driver Clean.ps1'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$allowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'

foreach ($path in @($stagesPath, $uiPath, $driverCleanModulePath, $driverCleanSourcePath, $artifactPath, $allowlistPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required label parity file missing: $path"
}

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })
$toolById = @{}
foreach ($tool in $allTools) {
    $toolById[[string]$tool.Id] = $tool
}

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
    'driver-install-latest',
    'nvidia-settings',
    'hdcp',
    'p0-state',
    'msi-mode',
    'directx'
)
$reachedToolsReverse = @($reachedToolsForward)
[array]::Reverse($reachedToolsReverse)

Assert-BoostLabCondition (($reachedToolsReverse[0] -eq 'directx') -and ($reachedToolsReverse[-1] -eq 'bios-information')) 'Reached label audit reverse scope must run from DirectX back to BIOS Information.'
foreach ($toolId in $reachedToolsForward) {
    Assert-BoostLabCondition ($toolById.ContainsKey($toolId)) "Reached tool missing from active catalog: $toolId"
}
foreach ($outOfScope in @('visual-cpp', 'graphics-configuration-center')) {
    Assert-BoostLabCondition ($reachedToolsForward -notcontains $outOfScope) "Out-of-scope tool was included in reached label audit scope: $outOfScope"
}

$uiText = Get-Content -LiteralPath $uiPath -Raw
Assert-BoostLabTextContains -Text $uiText -Needle 'function Get-BoostLabToolActionDisplayLabel' -Description 'UI action display label helper'

$driverInstallLatestBlock = Get-BoostLabTextBetween -Text $uiText -Start 'if ($toolId -eq ''driver-install-latest'')' -End 'if ($toolId -eq ''driver-clean'')'
Assert-BoostLabTextContains -Text $driverInstallLatestBlock -Needle "'Open' { return 'Open Intel Driver Page' }" -Description 'Driver Install Latest Open label'
Assert-BoostLabTextContains -Text $driverInstallLatestBlock -Needle "'Apply' { return 'Apply Source Workflow' }" -Description 'Driver Install Latest Apply label'
Assert-BoostLabCondition (-not $driverInstallLatestBlock.Contains('Manual Handoff')) 'Driver Install Latest must not show Manual Handoff.'
Assert-BoostLabCondition (-not $driverInstallLatestBlock.Contains('Apply Auto')) 'Driver Install Latest must not show Apply Auto.'

$driverCleanBlock = Get-BoostLabTextBetween -Text $uiText -Start 'if ($toolId -eq ''driver-clean'')' -End 'if ($toolId -eq ''nvidia-settings'')'
Assert-BoostLabTextContains -Text $driverCleanBlock -Needle "'Open' { return 'Manual' }" -Description 'Driver Clean Manual visible label'
Assert-BoostLabTextContains -Text $driverCleanBlock -Needle "'Apply' { return 'Auto' }" -Description 'Driver Clean Auto visible label'
Assert-BoostLabCondition (-not $driverCleanBlock.Contains('Manual Handoff')) 'Driver Clean must not show Manual Handoff after source-equivalent implementation.'
Assert-BoostLabCondition (-not $driverCleanBlock.Contains('Apply Auto')) 'Driver Clean must not show Apply Auto after source-equivalent implementation.'
Assert-BoostLabCondition (-not $uiText.Contains("'driver-clean', 'nvidia-settings'")) 'Driver Clean must not share Nvidia Settings display-label mapping.'

$nvidiaSettingsBlock = Get-BoostLabTextBetween -Text $uiText -Start 'if ($toolId -eq ''nvidia-settings'')' -End 'if ($toolId -eq ''hdcp'')'
Assert-BoostLabTextContains -Text $nvidiaSettingsBlock -Needle "'Apply' { return 'On (Recommended)' }" -Description 'Nvidia Settings On visible label'
Assert-BoostLabTextContains -Text $nvidiaSettingsBlock -Needle "'Default' { return 'Default' }" -Description 'Nvidia Settings Default visible label'
Assert-BoostLabCondition (-not $nvidiaSettingsBlock.Contains('Manual Handoff')) 'Nvidia Settings must not show Manual Handoff after source-equivalent implementation.'
Assert-BoostLabCondition (-not $nvidiaSettingsBlock.Contains('Apply Auto')) 'Nvidia Settings must not show Apply Auto after source-equivalent implementation.'
Assert-BoostLabCondition (-not $nvidiaSettingsBlock.Contains("'Open'")) 'Nvidia Settings must not expose a fake Open label.'

$hdcpBlock = Get-BoostLabTextBetween -Text $uiText -Start 'if ($toolId -eq ''hdcp'')' -End 'if ($toolId -eq ''p0-state'')'
Assert-BoostLabTextContains -Text $hdcpBlock -Needle "'Apply' { return 'Off (Recommended)' }" -Description 'HDCP Off visible label'
Assert-BoostLabTextContains -Text $hdcpBlock -Needle "'Default' { return 'Default' }" -Description 'HDCP Default visible label'
Assert-BoostLabCondition (-not $hdcpBlock.Contains('Manual Handoff')) 'HDCP must not show Manual Handoff after source-equivalent implementation.'
Assert-BoostLabCondition (-not $hdcpBlock.Contains('Apply Auto')) 'HDCP must not show Apply Auto after source-equivalent implementation.'
Assert-BoostLabCondition (-not $hdcpBlock.Contains("'Open'")) 'HDCP must not expose a fake Open label.'

$p0StateBlock = Get-BoostLabTextBetween -Text $uiText -Start 'if ($toolId -eq ''p0-state'')' -End 'if ($toolId -eq ''msi-mode'')'
Assert-BoostLabTextContains -Text $p0StateBlock -Needle "'Apply' { return 'On (Recommended)' }" -Description 'P0 State On visible label'
Assert-BoostLabTextContains -Text $p0StateBlock -Needle "'Default' { return 'Default' }" -Description 'P0 State Default visible label'
Assert-BoostLabCondition (-not $p0StateBlock.Contains('Manual Handoff')) 'P0 State must not show Manual Handoff after source-equivalent implementation.'
Assert-BoostLabCondition (-not $p0StateBlock.Contains('Apply Auto')) 'P0 State must not show Apply Auto after source-equivalent implementation.'
Assert-BoostLabCondition (-not $p0StateBlock.Contains("'Open'")) 'P0 State must not expose a fake Open label.'

$msiModeBlock = Get-BoostLabTextBetween -Text $uiText -Start 'if ($toolId -eq ''msi-mode'')' -End 'if ($toolId -eq ''directx'')'
Assert-BoostLabTextContains -Text $msiModeBlock -Needle "'Apply' { return 'On (Recommended)' }" -Description 'Msi Mode On visible label'
Assert-BoostLabTextContains -Text $msiModeBlock -Needle "'Off' { return 'Off' }" -Description 'Msi Mode Off visible label'
Assert-BoostLabCondition (-not $msiModeBlock.Contains('Manual Handoff')) 'Msi Mode must not show Manual Handoff after source-equivalent implementation.'
Assert-BoostLabCondition (-not $msiModeBlock.Contains('Apply Auto')) 'Msi Mode must not show Apply Auto after source-equivalent implementation.'
Assert-BoostLabCondition (-not $msiModeBlock.Contains("'Open'")) 'Msi Mode must not expose a fake Open label.'

$directXBlock = Get-BoostLabTextBetween -Text $uiText -Start 'if ($toolId -eq ''directx'')' -End 'return $ActionName'
Assert-BoostLabTextContains -Text $directXBlock -Needle "'Apply' { return 'Install DirectX' }" -Description 'DirectX Install visible label'
Assert-BoostLabCondition (-not $directXBlock.Contains('Manual Handoff')) 'DirectX must not show Manual Handoff after source-equivalent implementation.'
Assert-BoostLabCondition (-not $directXBlock.Contains('Apply Auto')) 'DirectX must not show Apply Auto after source-equivalent implementation.'
Assert-BoostLabCondition (-not $directXBlock.Contains("'Open'")) 'DirectX must not expose a fake Open label.'

$driverCleanSourceText = Get-Content -LiteralPath $driverCleanSourcePath -Raw
$expectedDriverCleanHash = 'CF9E1C55ACAFD8A52D2200AC3E6C3AFDF9823837C7B68101C2D4B83E074D325A'
$actualDriverCleanHash = (Get-FileHash -LiteralPath $driverCleanSourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualDriverCleanHash -eq $expectedDriverCleanHash) "Driver Clean source mirror hash mismatch. Expected $expectedDriverCleanHash, found $actualDriverCleanHash."
Assert-BoostLabTextContains -Text $driverCleanSourceText -Needle 'DDU: Auto' -Description 'Driver Clean Ultimate source Auto label'
Assert-BoostLabTextContains -Text $driverCleanSourceText -Needle 'DDU: Manual' -Description 'Driver Clean Ultimate source Manual label'

$driverCleanModuleText = Get-Content -LiteralPath $driverCleanModulePath -Raw
foreach ($needle in @(
    'Get-BoostLabDriverCleanOperationPlan -Mode Auto',
    'Get-BoostLabDriverCleanOperationPlan -Mode Manual',
    '$mode = if ($canonicalActionName -eq ''Apply'') { ''Auto'' } else { ''Manual'' }',
    '''Manual Handoff'' { ''Open'' }',
    '''Apply Auto'' { ''Apply'' }'
)) {
    Assert-BoostLabTextContains -Text $driverCleanModuleText -Needle $needle -Description 'Driver Clean canonical routing compatibility'
}

$driverCleanTool = $toolById['driver-clean']
Assert-BoostLabCondition ((@($driverCleanTool.Actions) -join '|') -eq 'Analyze|Open|Apply') 'Driver Clean must keep canonical internal actions.'

$driverInstallDebloatSettingsTool = $toolById['driver-install-debloat-settings']
Assert-BoostLabCondition ([string]$driverInstallDebloatSettingsTool.SelectionMode -eq 'SingleSelect') 'Driver Install Debloat & Settings must expose a single-select branch UI.'
Assert-BoostLabCondition ((@($driverInstallDebloatSettingsTool.SelectionItems | ForEach-Object { [string]$_.Id }) -join '|') -eq 'NVIDIA|AMD|INTEL') 'Driver Install Debloat & Settings branch labels must remain NVIDIA, AMD, INTEL.'
Assert-BoostLabCondition ((@($driverInstallDebloatSettingsTool.SelectionRequiredActions) -join '|') -eq 'Open|Apply') 'Driver Install Debloat & Settings must require one branch for Open and Apply.'

$driverInstallLatestTool = $toolById['driver-install-latest']
Assert-BoostLabCondition ([string]$driverInstallLatestTool.SelectionMode -eq 'SingleSelect') 'Driver Install Latest must keep single-select branch UI.'
Assert-BoostLabCondition ((@($driverInstallLatestTool.SelectionItems | ForEach-Object { [string]$_.Id }) -join '|') -eq 'NVIDIA|AMD|INTEL') 'Driver Install Latest branch labels must remain NVIDIA, AMD, INTEL.'
Assert-BoostLabCondition ((@($driverInstallLatestTool.SelectionRequiredActions) -join '|') -eq 'Open|Apply') 'Driver Install Latest must still require one branch for Open and Apply.'

$installersTool = $toolById['installers']
Assert-BoostLabCondition ([string]$installersTool.SelectionMode -eq 'MultiSelect') 'Installers must preserve checkbox multi-select behavior.'
Assert-BoostLabCondition ('Apply' -in @($installersTool.SelectionRequiredActions)) 'Installers Apply must still require selected apps.'
Assert-BoostLabCondition (@($installersTool.SelectionItems).Count -eq 17) 'Installers selected app list must remain unchanged.'
Assert-BoostLabTextContains -Text $uiText -Needle 'System.Windows.Controls.CheckBox' -Description 'Installers checkbox multi-select UI'

$updatesDriversBlockTool = $toolById['updates-drivers-block']
Assert-BoostLabTextContains -Text ([string]$updatesDriversBlockTool.Description) -Needle 'USB media only' -Description 'Updates Drivers Block USB-only scope'
Assert-BoostLabCondition (-not ((@($updatesDriversBlockTool.Actions) -join '|') -match 'Unblock')) 'Updates Drivers Block must not expose an Unblock action.'

$toolsWithDefaultAndRestore = @(
    $reachedToolsForward |
        Where-Object {
            $actions = @($toolById[$_].Actions)
            ($actions -contains 'Default') -and ($actions -contains 'Restore')
        }
)
foreach ($toolId in $toolsWithDefaultAndRestore) {
    $actions = @($toolById[$toolId].Actions)
    Assert-BoostLabCondition (($actions -contains 'Default') -and ($actions -contains 'Restore')) "Default and Restore must remain distinct for $toolId."
    Assert-BoostLabCondition ([Array]::IndexOf($actions, 'Default') -ne [Array]::IndexOf($actions, 'Restore')) "Default and Restore cannot collapse to the same action for $toolId."
}

$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPath
$productionPolicy = Import-PowerShellDataFile -LiteralPath $allowlistPath
if ($artifactPolicy.ContainsKey('Artifacts')) {
    Assert-BoostLabCondition (@($artifactPolicy.Artifacts).Count -eq 0) 'Artifact provenance approvals must remain empty.'
}
if ($productionPolicy.ContainsKey('ProductionAllowlistProposals')) {
    Assert-BoostLabCondition (@($productionPolicy.ProductionAllowlistProposals).Count -eq 0) 'Production allowlist proposals must remain empty.'
}

Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'modules\Graphics\ddu.psm1'))) 'Standalone DDU module was reintroduced.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\23 NVME Faster Driver.ps1'))) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    Passed = $true
    ReachedToolCount = $reachedToolsForward.Count
    DriverCleanVisibleLabels = @('Manual', 'Auto')
    DriverCleanRouting = 'Open maps to Ultimate Manual; Apply maps to Ultimate Auto'
    DriverInstallLatestLabels = @('Open Intel Driver Page', 'Apply Source Workflow')
    InstallersSelectionMode = [string]$installersTool.SelectionMode
    Message = 'Reached-tool action labels preserve source-truthful UI wording without changing runtime behavior.'
}
