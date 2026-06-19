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
        throw 'Unable to determine the Edge & WebView controlled manual handoff validator path.'
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

function Assert-BoostLabNoDuplicateWarnings {
    param(
        [Parameter(Mandatory)]
        [object]$Result,

        [Parameter(Mandatory)]
        [string]$Description
    )

    $resultWarnings = @($Result.Warnings | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    $dataWarnings = if ($null -ne $Result.Data -and $Result.Data.PSObject.Properties.Name -contains 'Warnings') {
        @($Result.Data.Warnings | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    }
    else {
        @()
    }

    foreach ($warning in $resultWarnings) {
        Assert-BoostLabCondition ($warning -notin $dataWarnings) "$Description duplicates warning at result and data level: $warning"
    }
    Assert-BoostLabCondition ((@($resultWarnings + $dataWarnings | Select-Object -Unique)).Count -eq @($resultWarnings + $dataWarnings).Count) "$Description contains duplicate warning entries."
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\edge-webview.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\13 Edge & WebView.ps1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$artifactPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$migrationPath = Join-Path $ProjectRoot 'docs\migrations\edge-webview.md'
$designPath = Join-Path $ProjectRoot 'docs\tool-designs\edge-webview-scope-design.md'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$sourcePromotedRoot = Join-Path $ProjectRoot 'source-ultimate\_intake-promoted\Ultimate'
$intakeRoot = Join-Path $ProjectRoot 'intake'

foreach ($path in @($configPath, $modulePath, $sourcePath, $executionPath, $actionPlanPath, $artifactPath, $productionAllowlistPath, $migrationPath, $designPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required Phase 106 file was not found: $path"
}

$expectedSourceHash = '161ED9C99D437E45650369CB7E15D5737DED363712E647138F134B049AC7E691'
$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) "Edge & WebView source hash mismatch. Expected $expectedSourceHash, found $actualSourceHash."

$sourceText = Get-Content -LiteralPath $sourcePath -Raw
foreach ($needle in @(
    'Write-Host "1. Edge & WebView: Uninstall (Recommended)"',
    'Write-Host "2. Edge & WebView: Default`n"',
    'Test-Connection -ComputerName "8.8.8.8"',
    'MicrosoftEdgeUpdate.exe',
    'Microsoft.MicrosoftEdge_8wekyb3d8bbwe',
    'Microsoft EdgeWebView',
    'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edge.exe',
    'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edgewebview.exe',
    'HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist',
    'HKLM:\Software\Microsoft\Active Setup\Installed Components',
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
    'Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}',
    'dism /online /Remove-Package'
)) {
    Assert-BoostLabTextContains -Text $sourceText -Needle $needle -Description 'Edge & WebView Ultimate source behavior'
}

$downloadUrls = @(
    Select-String -LiteralPath $sourcePath -Pattern 'IWR "([^"]+)"' |
        ForEach-Object { $_.Matches[0].Groups[1].Value } |
        Sort-Object -Unique
)
Assert-BoostLabCondition ($downloadUrls.Count -eq 2) "Expected 2 source download URLs, found $($downloadUrls.Count)."

$config = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })
$windowsStage = @($config.Stages | Where-Object { $_.Name -eq 'Windows' })[0]
$edgeTool = @($windowsStage.Tools | Where-Object { $_.Id -eq 'edge-webview' })[0]
Assert-BoostLabCondition ($null -ne $edgeTool) 'Edge & WebView is missing from Windows stage.'
Assert-BoostLabCondition ([string]$edgeTool.Title -eq 'Edge & WebView') 'Edge & WebView title mismatch.'
Assert-BoostLabCondition ([int]$edgeTool.Order -eq 13) 'Edge & WebView must remain Windows order 13.'
Assert-BoostLabCondition ([string]$edgeTool.Type -eq 'assistant') 'Edge & WebView must be an assistant.'
Assert-BoostLabCondition ([string]$edgeTool.RiskLevel -eq 'high') 'Edge & WebView must be high risk.'
Assert-BoostLabCondition ((@($edgeTool.Actions) -join ',') -eq 'Analyze,Open,Apply,Default,Restore') 'Edge & WebView must expose canonical Analyze/Open/Apply/Default/Restore actions.'
Assert-BoostLabTextContains -Text ([string]$edgeTool.Description) -Needle 'Controlled manual handoff only' -Description 'Edge & WebView description'

$capabilities = $edgeTool.Capabilities
Assert-BoostLabCondition ([bool]$capabilities['NeedsExplicitConfirmation']) 'Edge & WebView manual handoff should require explicit confirmation.'
foreach ($falseCapability in @(
    'RequiresAdmin',
    'RequiresInternet',
    'CanReboot',
    'CanModifyRegistry',
    'CanModifyServices',
    'CanInstallSoftware',
    'CanDownload',
    'CanModifyDrivers',
    'CanModifySecurity',
    'CanDeleteFiles',
    'UsesTrustedInstaller',
    'UsesSafeMode',
    'SupportsDefault',
    'SupportsRestore'
)) {
    Assert-BoostLabCondition (-not [bool]$capabilities[$falseCapability]) "Edge & WebView implemented manual-handoff capability should be false: $falseCapability"
}

$placeholderModules = @(
    Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
Assert-BoostLabCondition ($allTools.Count -eq $inventoryBaseline.ActiveTools) "Expected $($inventoryBaseline.ActiveTools) active tools, found $($allTools.Count)."
Assert-BoostLabCondition ($placeholderModules.Count -eq $inventoryBaseline.DeferredPlaceholders) "Expected $($inventoryBaseline.DeferredPlaceholders) deferred/placeholders, found $($placeholderModules.Count)."
Assert-BoostLabCondition (($allTools.Count - $placeholderModules.Count) -eq $inventoryBaseline.ImplementedTools) "Expected $($inventoryBaseline.ImplementedTools) implemented tools, found $($allTools.Count - $placeholderModules.Count)."
Assert-BoostLabCondition (-not (@($placeholderModules | ForEach-Object { $_.FullName }) -contains $modulePath)) 'Edge & WebView must no longer be a placeholder module.'

$sourcePromotedFiles = @(Get-ChildItem -LiteralPath $sourcePromotedRoot -Recurse -File)
Assert-BoostLabCondition ($sourcePromotedFiles.Count -eq $inventoryBaseline.SourcePromotedMirrorFiles) "Expected $($inventoryBaseline.SourcePromotedMirrorFiles) source-promoted mirror files, found $($sourcePromotedFiles.Count)."
$remainingSourcePromoted = @(
    $sourcePromotedFiles | Where-Object {
        $_.Name -notin @(
            '1 Driver Clean.ps1',
            '2 Driver Install Latest.ps1',
            '4 Nvidia Settings.ps1',
            '5 Hdcp.ps1',
            '6 P0 State.ps1',
            '7 Msi Mode.ps1',
            '1 BitLocker.ps1'
        )
    }
)
Assert-BoostLabCondition ($remainingSourcePromoted.Count -eq $inventoryBaseline.RemainingSourcePromotedIntakeCandidates) "Expected $($inventoryBaseline.RemainingSourcePromotedIntakeCandidates) remaining source-promoted intake candidates, found $($remainingSourcePromoted.Count)."

$executionText = Get-Content -LiteralPath $executionPath -Raw
foreach ($needle in @(
    "'edge-webview'",
    "Windows\edge-webview.psm1",
    "'Analyze', 'Open', 'Apply', 'Default', 'Restore'"
)) {
    Assert-BoostLabTextContains -Text $executionText -Needle $needle -Description 'Execution registry'
}

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
Assert-BoostLabTextContains -Text $actionPlanText -Needle "[ValidateSet('Apply', 'Default', 'Open', 'Analyze', 'Restore')]" -Description 'Action plan canonical ValidateSet'
Assert-BoostLabCondition (-not $actionPlanText.Contains("'Manual Handoff'")) 'Action plan ValidateSet must not include display label Manual Handoff.'
Assert-BoostLabCondition (-not $actionPlanText.Contains("'Apply Auto'")) 'Action plan ValidateSet must not include display label Apply Auto.'
foreach ($needle in @(
    'Prepare Edge & WebView manual handoff instructions only',
    'Auto mode is blocked for Edge & WebView',
    'Do not open a browser, Explorer, Settings, Store, Edge, WebView, repair installer, package manager, script, or external tool.',
    'Do not download Edge, WebView, installer, repair, script, package, archive, or artifact content.',
    'No browser, Explorer, Settings, Store, Edge, WebView, external tool, download, repair, installer execution, package action',
    'Edge & WebView Restore requires selected captured package, installer, file, registry, service, scheduled-task, process, cleanup, and support state plus an approved restore contract.'
)) {
    Assert-BoostLabTextContains -Text $actionPlanText -Needle $needle -Description 'Edge & WebView action plan wording'
}
Assert-BoostLabCondition (-not $actionPlanText.Contains('Edge & WebView`nDownload approved external content.')) 'Blocked Edge & WebView Action Plan must not claim approved downloads.'

$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($needle in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Open'', ''Apply'', ''Default'', ''Restore'')',
    $expectedSourceHash,
    'ManualHandoffOnly',
    'ManualHandoffPrepared',
    'AutoBlockedUntilArtifactApproval',
    'DefaultUnavailable',
    'RestoreUnavailable',
    'NoAutomatedExecution',
    'NoDownloadOccurred',
    'NoRepairOccurred',
    'NoInstallerExecutionOccurred',
    'NoExternalProcessStarted',
    'NoPackageMutationOccurred',
    'NoAppxMutationOccurred',
    'NoFileMutationOccurred',
    'NoRegistryMutationOccurred',
    'NoServiceMutationOccurred',
    'NoScheduledTaskMutation',
    'NoProcessMutationOccurred',
    'NoCleanupOccurred',
    'NoDeviceMutationOccurred',
    'NoDriverMutationOccurred',
    'NoRebootOccurred',
    'NoSystemMutationOccurred'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $needle -Description 'Edge & WebView module text'
}
Assert-BoostLabCondition (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) 'Edge & WebView module must not use placeholder contract.'
foreach ($commandPattern in @(
    '(?m)^\s*IWR\b',
    '(?m)^\s*Invoke-WebRequest\b',
    '(?m)^\s*Start-BitsTransfer\b',
    '(?m)^\s*Start-Process\b',
    '(?m)^\s*Stop-Process\b',
    '(?m)^\s*Get-Process\b',
    '(?m)^\s*Get-Service\b',
    '(?m)^\s*Get-ScheduledTask\b',
    '(?m)^\s*Unregister-ScheduledTask\b',
    '(?m)^\s*Remove-Item\b',
    '(?m)^\s*New-Item\b',
    '(?m)^\s*Copy-Item\b',
    '(?m)^\s*cmd\b',
    '(?m)^\s*dism\b',
    '(?m)^\s*reg\s+(add|delete)\b',
    '(?m)^\s*Remove-AppxPackage\b',
    '(?m)^\s*Add-AppxPackage\b'
)) {
    Assert-BoostLabCondition (-not [regex]::IsMatch($moduleText, $commandPattern)) "Edge & WebView module contains prohibited executable command pattern: $commandPattern"
}

$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPath
$allowlistPolicy = Import-PowerShellDataFile -LiteralPath $productionAllowlistPath
Assert-BoostLabCondition (@($artifactPolicy.Artifacts).Count -eq 0) 'Artifact provenance config must not approve Edge & WebView artifacts.'
Assert-BoostLabCondition (@($allowlistPolicy.ProductionAllowlistProposals).Count -eq 0) 'Production allowlist config must not approve Edge & WebView scopes.'

$module = Import-Module -Name $modulePath -Force -PassThru -Scope Local
try {
    $info = & $module { Get-BoostLabToolInfo }
    Assert-BoostLabCondition ([string]$info.Id -eq 'edge-webview') 'Module info Id mismatch.'
    Assert-BoostLabCondition ((@($info.Actions) -join ',') -eq 'Analyze,Open,Apply,Default,Restore') 'Module info actions mismatch.'
    Assert-BoostLabCondition ('Open' -in @($info.ConfirmationRequiredActions)) 'Open should require confirmation.'
    Assert-BoostLabCondition ('Apply' -in @($info.ConfirmationRequiredActions)) 'Apply should require confirmation.'

    $analyze = & $module { Invoke-BoostLabToolAction -ActionName 'Analyze' }
    Assert-BoostLabCondition ([bool]$analyze.Success) 'Analyze should succeed when source checksum matches.'
    Assert-BoostLabCondition ([string]$analyze.Status -eq 'Analyzed') 'Analyze status mismatch.'
    Assert-BoostLabCondition ([string]$analyze.CommandStatus -eq 'No execution performed') 'Analyze must be read-only.'
    Assert-BoostLabCondition (-not [bool]$analyze.ChangesExecuted) 'Analyze must not execute changes.'
    Assert-BoostLabCondition ([int]$analyze.Data.SourceDownloadArtifactCount -eq 2) 'Analyze should report 2 source download artifacts.'
    Assert-BoostLabNoDuplicateWarnings -Result $analyze -Description 'Analyze'

    $openCancelled = & $module { Invoke-BoostLabToolAction -ActionName 'Open' }
    Assert-BoostLabCondition (-not [bool]$openCancelled.Success) 'Unconfirmed Open should not succeed.'
    Assert-BoostLabCondition ([bool]$openCancelled.Cancelled) 'Unconfirmed Open should be cancelled.'
    Assert-BoostLabCondition (-not [bool]$openCancelled.ChangesExecuted) 'Unconfirmed Open must not execute changes.'

    $open = & $module { Invoke-BoostLabToolAction -ActionName 'Manual Handoff' -Confirmed $true }
    Assert-BoostLabCondition ([bool]$open.Success) 'Confirmed manual handoff should succeed.'
    Assert-BoostLabCondition ([string]$open.Action -eq 'Open') 'Manual Handoff display label should route to Open.'
    Assert-BoostLabCondition ([string]$open.Status -eq 'ManualHandoffPrepared') 'Open should prepare manual handoff.'
    Assert-BoostLabCondition (-not [bool]$open.ChangesExecuted) 'Open must not execute changes.'
    foreach ($property in @('NoDownloadOccurred', 'NoRepairOccurred', 'NoInstallerExecutionOccurred', 'NoExternalProcessStarted', 'NoPackageMutationOccurred', 'NoRegistryMutationOccurred', 'NoFileMutationOccurred', 'NoServiceMutationOccurred', 'NoSystemMutationOccurred')) {
        Assert-BoostLabCondition ([bool]$open.Data.$property) "Open should report $property."
    }

    $apply = & $module { Invoke-BoostLabToolAction -ActionName 'Apply Auto' -Confirmed $true }
    Assert-BoostLabCondition (-not [bool]$apply.Success) 'Apply Auto should fail closed.'
    Assert-BoostLabCondition ([string]$apply.Action -eq 'Apply') 'Apply Auto display label should route to Apply.'
    Assert-BoostLabCondition ([string]$apply.Status -eq 'AutoBlockedUntilArtifactApproval') 'Apply should be blocked until artifact approval.'
    Assert-BoostLabCondition (-not [bool]$apply.ChangesExecuted) 'Apply must not execute changes.'
    Assert-BoostLabTextContains -Text ([string]$apply.Message) -Needle 'No download, repair, installer launch, package action' -Description 'Apply blocked message'

    $default = & $module { Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed $true }
    Assert-BoostLabCondition (-not [bool]$default.Success) 'Default should fail closed.'
    Assert-BoostLabCondition ([string]$default.Status -eq 'DefaultUnavailable') 'Default status mismatch.'
    Assert-BoostLabTextContains -Text ([string]$default.Message) -Needle 'Default is not Restore' -Description 'Default message'

    $restore = & $module { Invoke-BoostLabToolAction -ActionName 'Restore' -Confirmed $true }
    Assert-BoostLabCondition (-not [bool]$restore.Success) 'Restore should fail closed.'
    Assert-BoostLabCondition ([string]$restore.Status -eq 'RestoreUnavailable') 'Restore status mismatch.'
    Assert-BoostLabTextContains -Text ([string]$restore.Message) -Needle 'without approved captured Edge/WebView package' -Description 'Restore message'
}
finally {
    Remove-Module $module -Force -ErrorAction SilentlyContinue
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local
try {
    $runtimeAnalyze = & $actionPlanModule { New-BoostLabActionPlan -ToolMetadata $args[0] -ActionName 'Analyze' } $edgeTool
    Assert-BoostLabTextContains -Text ([string]$runtimeAnalyze.Summary) -Needle 'without running any Edge/WebView workflow' -Description 'Runtime Analyze Action Plan summary'
    Assert-BoostLabCondition (-not ((@($runtimeAnalyze.PlannedChanges) -join "`n").Contains('Install or repair approved software.'))) 'Runtime Analyze plan must not claim software repair.'

    $runtimeOpen = & $actionPlanModule { New-BoostLabActionPlan -ToolMetadata $args[0] -ActionName 'Open' } $edgeTool
    $runtimeOpenText = (@($runtimeOpen.PlannedChanges) + @($runtimeOpen.SideEffects) + @($runtimeOpen.ConfirmationMessage) -join "`n")
    foreach ($needle in @(
        'Prepare manual handoff instructions inside BoostLab only.',
        'Do not open a browser, Explorer, Settings, Store, Edge, WebView, repair installer, package manager, script, or external tool.',
        'Do not download Edge, WebView, installer, repair, script, package, archive, or artifact content.',
        'Do not stop or start Edge/WebView processes or services.',
        'No browser, Explorer, Settings, Store, Edge, WebView, external tool, download, repair, installer execution, package action'
    )) {
        Assert-BoostLabTextContains -Text $runtimeOpenText -Needle $needle -Description 'Runtime Open Action Plan'
    }

    $runtimeApply = & $actionPlanModule { New-BoostLabActionPlan -ToolMetadata $args[0] -ActionName 'Apply' } $edgeTool
    $runtimeApplyText = (@($runtimeApply.PlannedChanges) + @($runtimeApply.SideEffects) + @($runtimeApply.ConfirmationMessage) -join "`n")
    foreach ($needle in @(
        'Block Auto mode before any operational step.',
        'Do not execute any approved Auto behavior because none is approved.',
        'Report missing Edge/WebView artifact provenance',
        'No approved Auto behavior, download, repair, installer execution, package action'
    )) {
        Assert-BoostLabTextContains -Text $runtimeApplyText -Needle $needle -Description 'Runtime Apply Action Plan'
    }
    Assert-BoostLabCondition (-not $runtimeApplyText.Contains('Install or repair approved software.')) 'Runtime Apply plan must not claim approved software repair.'
    Assert-BoostLabCondition (-not $runtimeApplyText.Contains('Download approved external content.')) 'Runtime Apply plan must not claim approved downloads.'
}
finally {
    Remove-Module $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$sourceMirrorManifestLines = Get-ChildItem -LiteralPath $sourcePromotedRoot -Recurse -File |
    Sort-Object FullName |
    ForEach-Object { '{0}|{1}' -f $_.FullName.Substring($ProjectRoot.Length + 1).Replace('\', '/'), (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
Assert-BoostLabCondition (@($sourceMirrorManifestLines).Count -eq $inventoryBaseline.SourcePromotedMirrorFiles) 'Source-promoted mirror file count changed.'

$intakeFiles = @(Get-ChildItem -LiteralPath $intakeRoot -Recurse -File -ErrorAction SilentlyContinue)
Assert-BoostLabCondition ($intakeFiles.Count -ge $inventoryBaseline.SourcePromotedMirrorFiles) 'Intake files unexpectedly changed or disappeared.'

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
    $sourceManifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash(
            [Text.Encoding]::UTF8.GetBytes(($sourceManifestLines -join "`n"))
        )
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}
Assert-BoostLabCondition (@($sourceManifestLines).Count -eq 49) "source-ultimate file count changed: $(@($sourceManifestLines).Count)"
Assert-BoostLabCondition ($sourceManifestHash -eq '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') 'source-ultimate content or paths changed.'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }).Count -eq 0) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    TestName                                       = 'Edge & WebView controlled manual handoff implementation'
    ActiveTools                                    = $inventoryBaseline.ActiveTools
    ImplementedTools                               = $inventoryBaseline.ImplementedTools
    DeferredPlaceholders                           = $inventoryBaseline.DeferredPlaceholders
    SourcePromotedMirrorFiles                      = $inventoryBaseline.SourcePromotedMirrorFiles
    RemainingUnimplementedSourcePromotedCandidates = $inventoryBaseline.RemainingSourcePromotedIntakeCandidates
    SourceHash                                     = $actualSourceHash
    EdgeWebViewActions                             = @($edgeTool.Actions)
    AutoMode                                       = 'AutoBlockedUntilArtifactApproval'
}
