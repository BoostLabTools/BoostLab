[CmdletBinding()]
param(
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-BloatwareCondition {
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

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $scriptPath = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $PSCommandPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $MyInvocation.MyCommand.Path
    }
    else {
        throw 'Unable to determine the Bloatware validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
. (Join-Path $ProjectRoot 'tests\BoostLab.ParityStatusBaseline.ps1')

$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\11 Bloatware.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\bloatware.psm1'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$artifactPolicyPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

foreach ($requiredPath in @($sourcePath, $modulePath, $stagesPath, $executionPath, $actionPlanPath, $artifactPolicyPath, $productionAllowlistPath)) {
    Assert-BloatwareCondition (Test-Path -LiteralPath $requiredPath -PathType Leaf) "Required file missing: $requiredPath"
}

$expectedSourceHash = '36677A334B37025A7234F4320EE54EF50E9528D1814E2B3A463EEB564C5814F5'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
Assert-BloatwareCondition ($actualSourceHash -eq $expectedSourceHash) "Bloatware source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$bloatwareTool = @($stages.Stages | ForEach-Object { $_.Tools } | Where-Object { [string]$_.Id -eq 'bloatware' }) | Select-Object -First 1
Assert-BloatwareCondition ($null -ne $bloatwareTool) 'Bloatware stage metadata is missing.'
Assert-BloatwareCondition ([string]$bloatwareTool.Stage -eq 'Windows') 'Bloatware must remain in the Windows stage.'
Assert-BloatwareCondition ([string]$bloatwareTool.RiskLevel -eq 'high') 'Bloatware must remain high risk.'
Assert-BloatwareCondition (($bloatwareTool.Actions -join ',') -eq 'Analyze,Apply') 'Bloatware must expose only Analyze and Apply.'
Assert-BloatwareCondition ([string]$bloatwareTool.SelectionMode -eq 'SingleSelect') 'Bloatware must use single-select source branch selection.'
Assert-BloatwareCondition (($bloatwareTool.SelectionRequiredActions -join ',') -eq 'Apply') 'Only Apply should require branch selection.'
Assert-BloatwareCondition (-not [bool]$bloatwareTool.Capabilities.SupportsDefault) 'Bloatware must not expose Default.'
Assert-BloatwareCondition (-not [bool]$bloatwareTool.Capabilities.SupportsRestore) 'Bloatware must not expose Restore.'
foreach ($capability in @('RequiresAdmin', 'RequiresInternet', 'CanModifyRegistry', 'CanModifyServices', 'CanInstallSoftware', 'CanDownload', 'CanModifySecurity', 'CanDeleteFiles', 'NeedsExplicitConfirmation')) {
    Assert-BloatwareCondition ([bool]$bloatwareTool.Capabilities[$capability]) "Bloatware capability '$capability' must remain enabled for the approved source-equivalent branch runtime."
}

$expectedBranches = @(
    @{ Id = 'RemoveAllBloatware'; Title = 'Remove : All Bloatware (Recommended)'; SourceMenuNumber = 2; Count = 25 }
    @{ Id = 'InstallStore'; Title = 'Install: Store'; SourceMenuNumber = 3; Count = 9 }
    @{ Id = 'InstallAllUwpApps'; Title = 'Install: All UWP Apps'; SourceMenuNumber = 4; Count = 4 }
    @{ Id = 'OpenUwpFeatures'; Title = 'Install: UWP Features'; SourceMenuNumber = 5; Count = 6 }
    @{ Id = 'OpenLegacyFeatures'; Title = 'Install: Legacy Features'; SourceMenuNumber = 6; Count = 6 }
    @{ Id = 'InstallOneDrive'; Title = 'Install: One Drive'; SourceMenuNumber = 7; Count = 5 }
    @{ Id = 'InstallRemoteDesktopConnection'; Title = 'Install: Remote Desktop Connection'; SourceMenuNumber = 8; Count = 5 }
    @{ Id = 'InstallSnippingTool'; Title = 'Install: Snipping Tool'; SourceMenuNumber = 9; Count = 6 }
)
$expectedParityBranchTitles = @(
    'Remove : All Bloatware (Recommended)'
    'Install: Store'
    'Install: All UWP Apps'
    'Install: UWP Features'
    'Install: Legacy Features'
    'Install: One Drive'
    'Install: Remote Desktop Connection'
    'Install: Snipping Tool'
)
$stageBranchIds = @($bloatwareTool.SelectionItems | ForEach-Object { [string]$_.Id })
Assert-BloatwareCondition (($stageBranchIds -join ',') -eq (($expectedBranches.Id) -join ',')) 'Bloatware stage branch order does not match the approved Ultimate branches.'
foreach ($expected in $expectedBranches) {
    $actual = @($bloatwareTool.SelectionItems | Where-Object { [string]$_.Id -eq [string]$expected.Id }) | Select-Object -First 1
    Assert-BloatwareCondition ($null -ne $actual) "Missing Bloatware branch metadata: $($expected.Id)"
    Assert-BloatwareCondition ([string]$actual.Title -eq [string]$expected.Title) "Unexpected title for Bloatware branch $($expected.Id)."
    Assert-BloatwareCondition ([int]$actual.SourceMenuNumber -eq [int]$expected.SourceMenuNumber) "Unexpected source menu number for Bloatware branch $($expected.Id)."
}

$executionText = Get-Content -LiteralPath $executionPath -Raw
Assert-BloatwareCondition ($executionText.Contains("'bloatware' = @{")) 'Execution map must include Bloatware.'
Assert-BloatwareCondition ($executionText.Contains("Windows\bloatware.psm1")) 'Execution map must point Bloatware to the Windows module.'

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    $analyzePlan = New-BoostLabActionPlan -ToolMetadata $bloatwareTool -ActionName 'Analyze' -IsDryRun:$false
    $applyPlan = New-BoostLabActionPlan -ToolMetadata $bloatwareTool -ActionName 'Apply' -IsDryRun:$false
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}
Assert-BloatwareCondition (($analyzePlan.PlannedChanges -join "`n").Contains('Perform no package, capability, feature, registry, hive, service, task, process, file, ownership, ACL, download, installer, uninstaller, external process, reboot, or system mutation during Analyze.')) 'Analyze action plan must be read-only.'
Assert-BloatwareCondition (($applyPlan.PlannedChanges -join "`n").Contains('Require explicit confirmation and exactly one selected Bloatware source branch.')) 'Apply action plan must require confirmation and exactly one branch.'
Assert-BloatwareCondition (($applyPlan.PlannedChanges -join "`n").Contains('Do not expose Exit, Default, Restore, or unrelated repair behavior for Bloatware.')) 'Apply action plan must keep Exit, Default, and Restore unavailable.'
Assert-BloatwareCondition (($applyPlan.SideEffects -join "`n").Contains('UltimateAuthorHostedArtifact / NeedsBoostLabMirror')) 'Apply action plan must report source-hosted artifact classification.'
Assert-BloatwareCondition ([string]$applyPlan.ConfirmationMessage -like '*No Default or Restore branch exists*') 'Apply confirmation must warn that Default and Restore do not exist.'

$module = Import-Module -Name $modulePath -Force -PassThru -Scope Local -DisableNameChecking -ErrorAction Stop
try {
    $info = Get-BoostLabToolInfo
    Assert-BloatwareCondition ([string]$info.Id -eq 'bloatware') 'Bloatware tool info returned the wrong id.'
    Assert-BloatwareCondition (($info.Actions -join ',') -eq 'Analyze,Apply') 'Bloatware module must expose only Analyze and Apply.'
    Assert-BloatwareCondition ([string]$info.SelectionMode -eq 'SingleSelect') 'Bloatware module must expose single-select branch selection.'
    Assert-BloatwareCondition (($info.SelectionItems.Id -join ',') -eq (($expectedBranches.Id) -join ',')) 'Bloatware module branch order does not match the approved Ultimate branch order.'

    $sourceStatus = Get-BoostLabBloatwareSourceStatus
    Assert-BloatwareCondition ([string]$sourceStatus.ChecksumStatus -eq 'Passed') 'Bloatware source status must pass checksum verification.'
    Assert-BloatwareCondition ([string]$sourceStatus.ExpectedSha256 -eq $expectedSourceHash) 'Bloatware source status expected hash mismatch.'

    $analysisResult = Invoke-BoostLabToolAction -ActionName 'Analyze'
    Assert-BloatwareCondition ([bool]$analysisResult.Success) 'Bloatware Analyze should succeed.'
    Assert-BloatwareCondition ([string]$analysisResult.CommandStatus -eq 'ReadOnly') 'Bloatware Analyze must be read-only.'
    Assert-BloatwareCondition (-not [bool]$analysisResult.ChangesExecuted) 'Bloatware Analyze must execute no changes.'
    foreach ($noMutationField in @('NoMutationOccurred', 'NoDownloadOccurred', 'NoInstallerExecutionOccurred', 'NoRegistryMutationOccurred', 'NoPackageMutationOccurred', 'NoFeatureMutationOccurred', 'NoServiceMutationOccurred', 'NoTaskMutationOccurred', 'NoProcessMutationOccurred', 'NoFileMutationOccurred', 'NoRebootOrSessionChangeOccurred')) {
        Assert-BloatwareCondition ([bool]$analysisResult.Data.$noMutationField) "Bloatware Analyze must report $noMutationField."
    }
    Assert-BloatwareCondition (@($analysisResult.Data.OperationPlans).Count -eq 8) 'Bloatware Analyze must report all eight approved non-Exit branches.'

    foreach ($expected in $expectedBranches) {
        $plan = Get-BoostLabBloatwareOperationPlan -Branch ([string]$expected.Id)
        Assert-BloatwareCondition ([int]$plan.SourceMenuNumber -eq [int]$expected.SourceMenuNumber) "Unexpected source menu number in plan $($expected.Id)."
        Assert-BloatwareCondition ([int]$plan.OperationCount -eq [int]$expected['Count']) "Unexpected operation count in plan $($expected.Id)."
        Assert-BloatwareCondition (@($plan.Operations | Where-Object { [string]$_.Branch -ne [string]$expected.Id }).Count -eq 0) "Plan $($expected.Id) contains operations from another branch."
    }

    $removePlan = Get-BoostLabBloatwareOperationPlan -Branch 'RemoveAllBloatware'
    foreach ($requiredType in @('RemoveAppxExcept', 'RemoveWindowsCapabilityExcept', 'DisableOptionalFeatureExcept', 'Cmd', 'RemoveItem', 'MsiUninstallByDisplayName', 'StopProcess', 'UninstallOneDriveAllUsers', 'UnregisterScheduledTasksLike', 'StartProcess', 'StopProcessWindow', 'UnregisterScheduledTaskName')) {
        Assert-BloatwareCondition (($removePlan.Operations.Type -contains $requiredType) -or ($removePlan.Operations.Type -join ',' -like "*$requiredType*")) "Remove all bloatware plan is missing operation type $requiredType."
    }
    Assert-BloatwareCondition (-not ($removePlan.Operations.Type -join ',' -like '*Provisioned*')) 'Bloatware must not invent provisioned package removal absent from the source.'
    Assert-BloatwareCondition ((Get-Content -Raw -LiteralPath $modulePath).Contains('Invoke-BoostLabBloatwareMsiUninstallByDisplayName')) 'Bloatware must route MSI DisplayName uninstall through the StrictMode-safe helper.'
    $removeAppxOperation = @($removePlan.Operations | Where-Object { [string]$_.Type -eq 'RemoveAppxExcept' }) | Select-Object -First 1
    Assert-BloatwareCondition ($null -ne $removeAppxOperation) 'Remove all bloatware plan must include RemoveAppxExcept.'
    $excludePatterns = @($removeAppxOperation.Parameters.ExcludeLike)
    Assert-BloatwareCondition (($excludePatterns -join ',') -eq '*CBS*,*Microsoft.AV1VideoExtension*,*Microsoft.AVCEncoderVideoExtension*,*Microsoft.HEIFImageExtension*,*Microsoft.HEVCVideoExtension*,*Microsoft.MPEG2VideoExtension*,*Microsoft.Paint*,*Microsoft.RawImageExtension*,*Microsoft.SecHealthUI*,*Microsoft.VP9VideoExtensions*,*Microsoft.WebMediaExtensions*,*Microsoft.WebpImageExtension*,*Microsoft.Windows.Photos*,*Microsoft.Windows.ShellExperienceHost*,*Microsoft.Windows.StartMenuExperienceHost*,*Microsoft.WindowsNotepad*,*NVIDIACorp.NVIDIAControlPanel*,*windows.immersivecontrolpanel*') 'RemoveAppxExcept exclusion patterns must preserve the Ultimate source list exactly.'
    $snippingUninstallOperation = @($removePlan.Operations | Where-Object { [string]$_.Label -eq 'Uninstall legacy Snipping Tool' }) | Select-Object -First 1
    $snippingCloseWindowOperation = @($removePlan.Operations | Where-Object { [string]$_.Label -eq 'Close Snipping Tool uninstall window' }) | Select-Object -First 1
    Assert-BloatwareCondition ($null -ne $snippingUninstallOperation) 'RemoveAllBloatware plan must preserve the legacy Snipping Tool uninstall operation.'
    Assert-BloatwareCondition ($null -ne $snippingCloseWindowOperation) 'RemoveAllBloatware plan must preserve the Snipping Tool close-window operation.'
    Assert-BloatwareCondition ([int]$snippingCloseWindowOperation.Order -eq ([int]$snippingUninstallOperation.Order + 1)) 'Snipping Tool close-window operation must remain immediately after the uninstall operation.'
    Assert-BloatwareCondition ([string]$snippingUninstallOperation.Type -eq 'StartProcess') 'Legacy Snipping Tool uninstall must remain a source-equivalent StartProcess operation.'
    Assert-BloatwareCondition ([string]$snippingUninstallOperation.Parameters.FilePath -like '*\System32\SnippingTool.exe') 'Legacy Snipping Tool uninstall path must remain System32\SnippingTool.exe.'
    Assert-BloatwareCondition ([string]$snippingUninstallOperation.Parameters.ArgumentList -eq '/Uninstall') 'Legacy Snipping Tool uninstall argument must remain /Uninstall.'

    $snippingStartProcessProbe = & $module {
        param($Operation)

        $started = [System.Collections.Generic.List[string]]::new()
        $existsResult = Invoke-BoostLabBloatwareStartProcessOperation `
            -Operation $Operation `
            -PathTester { param($Path) $true } `
            -ProcessStarter {
                param($FilePath, $ArgumentList)
                $started.Add("$FilePath|$ArgumentList")
            }.GetNewClosure()

        $missingStartAttempts = [System.Collections.Generic.List[string]]::new()
        $missingResult = Invoke-BoostLabBloatwareStartProcessOperation `
            -Operation $Operation `
            -PathTester { param($Path) $false } `
            -ProcessStarter {
                param($FilePath, $ArgumentList)
                $missingStartAttempts.Add("$FilePath|$ArgumentList")
            }.GetNewClosure()

        $failureResult = Invoke-BoostLabBloatwareStartProcessOperation `
            -Operation $Operation `
            -PathTester { param($Path) $true } `
            -ProcessStarter {
                param($FilePath, $ArgumentList)
                throw 'Mock Snipping Tool launch failure.'
            }

        [pscustomobject]@{
            ExistsResult = $existsResult
            Started = $started.ToArray()
            MissingResult = $missingResult
            MissingStartAttemptCount = $missingStartAttempts.Count
            FailureResult = $failureResult
        }
    } $snippingUninstallOperation
    Assert-BloatwareCondition ([bool]$snippingStartProcessProbe.ExistsResult.Success) 'Existing legacy Snipping Tool executable should run the source-defined StartProcess operation.'
    Assert-BloatwareCondition (($snippingStartProcessProbe.Started -join ',') -like '*SnippingTool.exe|/Uninstall') 'Existing legacy Snipping Tool executable must launch with /Uninstall.'
    Assert-BloatwareCondition ([bool]$snippingStartProcessProbe.MissingResult.Success) 'Missing legacy Snipping Tool executable should be an expected skip, not a failure.'
    Assert-BloatwareCondition ([string]$snippingStartProcessProbe.MissingResult.Data.Outcome -eq 'SkippedMissingLegacySnippingTool') 'Missing legacy Snipping Tool outcome mismatch.'
    Assert-BloatwareCondition ([string]$snippingStartProcessProbe.MissingResult.Data.CheckedPath -like '*\System32\SnippingTool.exe') 'Missing legacy Snipping Tool diagnostic must include checked path.'
    Assert-BloatwareCondition (-not [bool]$snippingStartProcessProbe.MissingResult.Data.Exists) 'Missing legacy Snipping Tool diagnostic must report Exists=false.'
    Assert-BloatwareCondition ([int]$snippingStartProcessProbe.MissingStartAttemptCount -eq 0) 'Missing legacy Snipping Tool must not call StartProcess.'
    Assert-BloatwareCondition ([string]$snippingStartProcessProbe.MissingResult.Message -eq 'Legacy Snipping Tool executable was not present; uninstall step skipped.') 'Missing legacy Snipping Tool diagnostic message mismatch.'
    Assert-BloatwareCondition (-not [bool]$snippingStartProcessProbe.FailureResult.Success) 'Existing legacy Snipping Tool launch failures must still fail closed.'
    Assert-BloatwareCondition ([string]$snippingStartProcessProbe.FailureResult.Data.Outcome -eq 'StartProcessFailed') 'Legacy Snipping Tool non-missing launch failure must report StartProcessFailed.'
    Assert-BloatwareCondition ([string]$snippingStartProcessProbe.FailureResult.Message -like '*Mock Snipping Tool launch failure*') 'Legacy Snipping Tool launch failure must preserve the real error.'

    $gameInputMsiEntries = @(
        [pscustomobject]@{ PSChildName = '{NO-DISPLAYNAME-GUID}'; PSPath = 'HKLM:\Mock\NoDisplayName' }
        [pscustomobject]@{ PSChildName = '{NULL-DISPLAYNAME-GUID}'; PSPath = 'HKLM:\Mock\NullDisplayName'; DisplayName = $null }
        [pscustomobject]@{ PSChildName = '{EMPTY-DISPLAYNAME-GUID}'; PSPath = 'HKLM:\Mock\EmptyDisplayName'; DisplayName = '' }
        [pscustomobject]@{ PSChildName = '{OTHER-GUID}'; PSPath = 'HKLM:\Mock\Other'; DisplayName = 'Contoso Input Runtime' }
        [pscustomobject]@{ PSChildName = '{GAMEINPUT-GUID}'; PSPath = 'HKLM:\Mock\GameInput'; DisplayName = 'Microsoft GameInput' }
    )
    $gameInputMsiArguments = [System.Collections.Generic.List[string]]::new()
    $gameInputMsiResult = & $module {
        param($Entries, $Arguments)
        $entryEnumerator = { param($Path) $Entries }.GetNewClosure()
        $uninstaller = { param($Entry, $ArgumentList) $Arguments.Add($ArgumentList) }.GetNewClosure()
        Invoke-BoostLabBloatwareMsiUninstallByDisplayName `
            -DisplayNameLike '*Microsoft GameInput*' `
            -EntryEnumerator $entryEnumerator `
            -Uninstaller $uninstaller
    } $gameInputMsiEntries $gameInputMsiArguments
    Assert-BloatwareCondition ([bool]$gameInputMsiResult.Success) 'Bloatware MSI uninstall helper must succeed when missing/no-match entries exist and the matching uninstall succeeds.'
    Assert-BloatwareCondition ([int]$gameInputMsiResult.ScannedUninstallEntryCount -eq 5) 'Bloatware MSI uninstall helper scanned count mismatch.'
    Assert-BloatwareCondition ([int]$gameInputMsiResult.MissingDisplayNameEntryCount -eq 3) 'Bloatware MSI uninstall helper must count missing/null/empty DisplayName entries as non-match.'
    Assert-BloatwareCondition ([int]$gameInputMsiResult.NoMatchCount -eq 1) 'Bloatware MSI uninstall helper must count non-matching DisplayName entries.'
    Assert-BloatwareCondition ([int]$gameInputMsiResult.MatchingEntryCount -eq 1) 'Bloatware MSI uninstall helper must count matching DisplayName entries.'
    Assert-BloatwareCondition ([int]$gameInputMsiResult.UninstallAttemptedCount -eq 1) 'Bloatware MSI uninstall helper must attempt uninstall only for matching entries.'
    Assert-BloatwareCondition (($gameInputMsiArguments.ToArray() -join ',') -eq '/x {GAMEINPUT-GUID} /qn /norestart') 'Bloatware Microsoft GameInput uninstall must preserve the approved msiexec argument flow.'
    Assert-BloatwareCondition (($gameInputMsiResult.ProductCodesAttempted -join ',') -eq '{GAMEINPUT-GUID}') 'Bloatware MSI uninstall helper must report attempted product codes.'
    Assert-BloatwareCondition (($gameInputMsiResult.UninstallCommandsAttempted -join ',') -eq 'msiexec.exe /x {GAMEINPUT-GUID} /qn /norestart') 'Bloatware MSI uninstall helper must report attempted msiexec command text.'
    Assert-BloatwareCondition (($gameInputMsiResult.MatchedDisplayNames -join ',') -eq 'Microsoft GameInput') 'Bloatware MSI uninstall helper must report matched display names.'
    Assert-BloatwareCondition ([int]$gameInputMsiResult.FailureCount -eq 0) 'Bloatware MSI uninstall helper must not fail on missing/no-match DisplayName entries.'
    Assert-BloatwareCondition (@($gameInputMsiResult.MissingDisplayNameSamples).Count -gt 0) 'Bloatware MSI uninstall helper must include bounded missing DisplayName samples.'

    foreach ($msiCase in @(
        @{ DisplayNameLike = '*Update for x64-based Windows Systems*'; DisplayName = 'Update for x64-based Windows Systems'; ProductCode = '{WINDOWS-UPDATE-X64-GUID}' }
        @{ DisplayNameLike = '*Microsoft Update Health Tools*'; DisplayName = 'Microsoft Update Health Tools'; ProductCode = '{UPDATE-HEALTH-TOOLS-GUID}' }
    )) {
        $caseArguments = [System.Collections.Generic.List[string]]::new()
        $caseResult = & $module {
            param($Case, $Arguments)
            $entryEnumerator = {
                @([pscustomobject]@{
                    PSChildName = [string]$Case.ProductCode
                    PSPath = "HKLM:\Mock\$($Case.ProductCode)"
                    DisplayName = [string]$Case.DisplayName
                })
            }.GetNewClosure()
            $uninstaller = { param($Entry, $ArgumentList) $Arguments.Add($ArgumentList) }.GetNewClosure()
            Invoke-BoostLabBloatwareMsiUninstallByDisplayName `
                -DisplayNameLike ([string]$Case.DisplayNameLike) `
                -EntryEnumerator $entryEnumerator `
                -Uninstaller $uninstaller
        } $msiCase $caseArguments
        Assert-BloatwareCondition ([bool]$caseResult.Success) "Bloatware MSI uninstall helper must succeed for $($msiCase.DisplayName)."
        Assert-BloatwareCondition ([int]$caseResult.MatchingEntryCount -eq 1) "Bloatware MSI uninstall helper must match $($msiCase.DisplayName)."
        Assert-BloatwareCondition (($caseArguments.ToArray() -join ',') -eq "/x $($msiCase.ProductCode) /qn /norestart") "Bloatware MSI uninstall helper must use the approved msiexec flow for $($msiCase.DisplayName)."
    }

    $noMatchMsiResult = & $module {
        Invoke-BoostLabBloatwareMsiUninstallByDisplayName `
            -DisplayNameLike '*Microsoft GameInput*' `
            -EntryEnumerator {
                @(
                    [pscustomobject]@{ PSChildName = '{NO-DISPLAYNAME-GUID}'; PSPath = 'HKLM:\Mock\NoDisplayName' }
                    [pscustomobject]@{ PSChildName = '{OTHER-GUID}'; PSPath = 'HKLM:\Mock\Other'; DisplayName = 'Contoso Input Runtime' }
                )
            } `
            -Uninstaller { throw 'Uninstaller should not run when no DisplayName matches.' }
    }
    Assert-BloatwareCondition ([bool]$noMatchMsiResult.Success) 'Bloatware MSI uninstall helper must treat no matching DisplayName as completed/no-op.'
    Assert-BloatwareCondition ([int]$noMatchMsiResult.MatchingEntryCount -eq 0) 'Bloatware MSI uninstall no-match result should report zero matches.'
    Assert-BloatwareCondition ([int]$noMatchMsiResult.UninstallAttemptedCount -eq 0) 'Bloatware MSI uninstall no-match result must not attempt msiexec.'
    Assert-BloatwareCondition ([string]$noMatchMsiResult.FinalOutcomeReason -eq 'CompletedOrNoMatch') 'Bloatware MSI uninstall no-match result must report completed/no-match outcome.'

    $failingMsiResult = & $module {
        Invoke-BoostLabBloatwareMsiUninstallByDisplayName `
            -DisplayNameLike '*Microsoft GameInput*' `
            -EntryEnumerator {
                @([pscustomobject]@{ PSChildName = '{GAMEINPUT-GUID}'; PSPath = 'HKLM:\Mock\GameInput'; DisplayName = 'Microsoft GameInput' })
            } `
            -Uninstaller { throw 'Mock msiexec failure.' }
    }
    Assert-BloatwareCondition (-not [bool]$failingMsiResult.Success) 'Bloatware MSI uninstall helper must fail closed when matched msiexec uninstall fails.'
    Assert-BloatwareCondition ([int]$failingMsiResult.FailureCount -eq 1) 'Bloatware MSI uninstall helper must count matched uninstall failures.'
    Assert-BloatwareCondition ([string]$failingMsiResult.FailureEntries[0] -like '*Mock msiexec failure*') 'Bloatware MSI uninstall helper must include the msiexec failure reason.'

    $emptyRemoveResult = Invoke-BoostLabBloatwareRemoveAppxExcept `
        -ExcludeLike $excludePatterns `
        -AppxGetter { @() } `
        -AppxRemover { throw 'Remover should not be called for an empty package list.' }
    Assert-BloatwareCondition ([bool]$emptyRemoveResult.Success) 'RemoveAppxExcept must succeed for a null/empty mock package list.'
    Assert-BloatwareCondition ([int]$emptyRemoveResult.TotalPackages -eq 0) 'RemoveAppxExcept empty package list should report zero total packages.'
    Assert-BloatwareCondition (@($emptyRemoveResult.AttemptedPackages).Count -eq 0) 'RemoveAppxExcept empty package list should attempt no removals.'

    $mockPackages = @(
        [pscustomobject]@{ Name = 'Microsoft.Paint'; PackageFullName = 'Microsoft.Paint_1'; PackageFamilyName = 'Microsoft.Paint_family'; User = 'S-1-1'; InstallLocation = 'C:\Mock\Paint' }
        [pscustomobject]@{ Name = 'Contoso.Bloatware'; PackageFullName = 'Contoso.Bloatware_1'; PackageFamilyName = 'Contoso.Bloatware_family'; User = 'S-1-2'; InstallLocation = 'C:\Mock\Contoso' }
        [pscustomobject]@{ Name = 'Fabrikam.Noise'; PackageFullName = 'Fabrikam.Noise_1'; PackageFamilyName = 'Fabrikam.Noise_family'; User = 'S-1-3'; InstallLocation = 'C:\Mock\Fabrikam' }
    )
    $removedPackages = [System.Collections.Generic.List[string]]::new()
    $mockRemoveResult = Invoke-BoostLabBloatwareRemoveAppxExcept `
        -ExcludeLike $excludePatterns `
        -AppxGetter { $mockPackages }.GetNewClosure() `
        -AppxRemover { param($Package) $removedPackages.Add([string]$Package.PackageFullName) }.GetNewClosure()
    Assert-BloatwareCondition ([bool]$mockRemoveResult.Success) 'RemoveAppxExcept must succeed when all non-excluded mock packages are removed.'
    Assert-BloatwareCondition (@($mockRemoveResult.ExcludedPackages).Count -eq 1) 'RemoveAppxExcept must preserve excluded package patterns.'
    Assert-BloatwareCondition (@($mockRemoveResult.AttemptedPackages).Count -eq 2) 'RemoveAppxExcept must attempt each non-excluded package individually.'
    Assert-BloatwareCondition (($removedPackages.ToArray() -join ',') -eq 'Contoso.Bloatware_1,Fabrikam.Noise_1') 'RemoveAppxExcept must remove mock packages one-by-one without touching excluded packages.'
    Assert-BloatwareCondition (($mockRemoveResult.PackageOutcomes.Outcome -join ',') -eq 'SkippedExcluded,Removed,Removed') 'RemoveAppxExcept must report excluded and removed outcome categories.'

    $nvidiaControlPanelResult = Invoke-BoostLabBloatwareRemoveAppxExcept `
        -ExcludeLike $excludePatterns `
        -AppxGetter { @([pscustomobject]@{ Name = 'NVIDIACorp.NVIDIAControlPanel'; PackageFullName = 'NVIDIACorp.NVIDIAControlPanel_1'; PackageFamilyName = 'NVIDIACorp.NVIDIAControlPanel_family'; User = 'S-1-6'; InstallLocation = 'C:\Mock\NvidiaControlPanel' }) } `
        -AppxRemover { throw 'NVIDIA Control Panel must remain excluded and must not be removed.' }
    Assert-BloatwareCondition ([bool]$nvidiaControlPanelResult.Success) 'NVIDIA Control Panel must remain protected by the source exclusion list.'
    Assert-BloatwareCondition (@($nvidiaControlPanelResult.ExcludedPackages).Count -eq 1) 'NVIDIA Control Panel must be reported as excluded.'
    Assert-BloatwareCondition (@($nvidiaControlPanelResult.AttemptedPackages).Count -eq 0) 'NVIDIA Control Panel exclusion must prevent removal attempts.'

    $pipeWarningResult = Invoke-BoostLabBloatwareRemoveAppxExcept `
        -ExcludeLike $excludePatterns `
        -AppxGetter { @([pscustomobject]@{ Name = 'Contoso.Pipe'; PackageFullName = 'Contoso.Pipe_1'; PackageFamilyName = 'Contoso.Pipe_family'; User = 'S-1-4'; InstallLocation = 'C:\Mock\Pipe' }) } `
        -AppxRemover { throw 'The Win32 internal error "No process is on the other end of the pipe" 0xE9 occurred while getting console output buffer information.' }
    Assert-BloatwareCondition ([bool]$pipeWarningResult.Success) 'RemoveAppxExcept must not hard-fail on console/progress pipe output warnings alone.'
    Assert-BloatwareCondition (@($pipeWarningResult.ConsolePipeWarnings).Count -eq 1) 'RemoveAppxExcept must report console/progress pipe warnings in result data.'
    Assert-BloatwareCondition (@($pipeWarningResult.FailedPackages).Count -eq 0) 'RemoveAppxExcept must not classify console/progress pipe warnings as real package failures.'

    $protectedSystemAppResult = Invoke-BoostLabBloatwareRemoveAppxExcept `
        -ExcludeLike $excludePatterns `
        -AppxGetter { @([pscustomobject]@{ Name = 'Microsoft.Windows.SystemApp'; PackageFullName = 'Microsoft.Windows.SystemApp_1'; PackageFamilyName = 'Microsoft.Windows.SystemApp_family'; User = 'S-1-7'; InstallLocation = 'C:\Windows\SystemApps\SystemApp' }) } `
        -AppxRemover { throw 'Remove-AppxPackage failed with HRESULT 0x80073CFA, error 0x80070032: This app is part of Windows and cannot be uninstalled on a per-user basis.' }
    Assert-BloatwareCondition ([bool]$protectedSystemAppResult.Success) 'Protected Windows SystemApp AppX failures must be reported as skips, not hard errors.'
    Assert-BloatwareCondition (@($protectedSystemAppResult.ProtectedSystemAppSkippedPackages).Count -eq 1) 'Protected Windows SystemApp skip must be counted.'
    Assert-BloatwareCondition (@($protectedSystemAppResult.FailedPackages).Count -eq 0) 'Protected Windows SystemApp skip must not be counted as an unexpected failure.'
    Assert-BloatwareCondition ([string]$protectedSystemAppResult.ProtectedSystemAppSkippedPackages[0].Outcome -eq 'SkippedProtectedSystemApp') 'Protected Windows SystemApp skip must use the SkippedProtectedSystemApp outcome.'

    $dependencyFrameworkResult = Invoke-BoostLabBloatwareRemoveAppxExcept `
        -ExcludeLike $excludePatterns `
        -AppxGetter { @([pscustomobject]@{ Name = 'Microsoft.Framework.Dependency'; PackageFullName = 'Microsoft.Framework.Dependency_1'; PackageFamilyName = 'Microsoft.Framework.Dependency_family'; User = 'S-1-8'; InstallLocation = 'C:\Windows\SystemApps\Framework' }) } `
        -AppxRemover { throw 'Remove-AppxPackage failed with HRESULT 0x80073CF3: package dependency/conflict validation failed because dependent packages remain installed.' }
    Assert-BloatwareCondition ([bool]$dependencyFrameworkResult.Success) 'Dependency/framework AppX failures must be reported as skips, not hard errors.'
    Assert-BloatwareCondition (@($dependencyFrameworkResult.DependencyFrameworkSkippedPackages).Count -eq 1) 'Dependency/framework skip must be counted.'
    Assert-BloatwareCondition (@($dependencyFrameworkResult.FailedPackages).Count -eq 0) 'Dependency/framework skip must not be counted as an unexpected failure.'
    Assert-BloatwareCondition ([string]$dependencyFrameworkResult.DependencyFrameworkSkippedPackages[0].Outcome -eq 'SkippedDependencyFramework') 'Dependency/framework skip must use the SkippedDependencyFramework outcome.'

    $windowsAppRuntimeInUseResult = Invoke-BoostLabBloatwareRemoveAppxExcept `
        -ExcludeLike $excludePatterns `
        -AppxGetter {
            @(
                [pscustomobject]@{ Name = 'Microsoft.WindowsAppRuntime.1.8'; PackageFullName = 'Microsoft.WindowsAppRuntime.1.8_8000.879.2017.0_x86__8wekyb3d8bbwe'; PackageFamilyName = 'Microsoft.WindowsAppRuntime.1.8_8wekyb3d8bbwe'; User = 'S-1-9'; InstallLocation = 'C:\Program Files\WindowsApps\Microsoft.WindowsAppRuntime.1.8_x86'; IsFramework = $true }
                [pscustomobject]@{ Name = 'Microsoft.WindowsAppRuntime.1.8'; PackageFullName = 'Microsoft.WindowsAppRuntime.1.8_8000.879.2017.0_x64__8wekyb3d8bbwe'; PackageFamilyName = 'Microsoft.WindowsAppRuntime.1.8_8wekyb3d8bbwe'; User = 'S-1-10'; InstallLocation = 'C:\Program Files\WindowsApps\Microsoft.WindowsAppRuntime.1.8_x64'; IsFramework = $true }
            )
        } `
        -AppxRemover { throw 'Remove-AppxPackage failed with HRESULT 0x80073D02: The package could not be installed because resources it modifies are currently in use. The request cannot be processed because package Microsoft.WindowsAppRuntime.1.8 is in use.' }
    Assert-BloatwareCondition ([bool]$windowsAppRuntimeInUseResult.Success) 'WindowsAppRuntime in-use framework/runtime failures must be reported as skips, not hard errors.'
    Assert-BloatwareCondition (@($windowsAppRuntimeInUseResult.InUseFrameworkRuntimeSkippedPackages).Count -eq 2) 'WindowsAppRuntime x86/x64 in-use skips must be counted.'
    Assert-BloatwareCondition ([int]$windowsAppRuntimeInUseResult.InUseFrameworkRuntimeSkippedCount -eq 2) 'WindowsAppRuntime in-use skipped count mismatch.'
    Assert-BloatwareCondition (@($windowsAppRuntimeInUseResult.FailedPackages).Count -eq 0) 'WindowsAppRuntime in-use framework/runtime skips must not be counted as unexpected failures.'
    Assert-BloatwareCondition (($windowsAppRuntimeInUseResult.InUseFrameworkRuntimeSkippedPackages.Outcome -join ',') -eq 'SkippedInUseFrameworkRuntime,SkippedInUseFrameworkRuntime') 'WindowsAppRuntime in-use skips must use the SkippedInUseFrameworkRuntime outcome.'
    Assert-BloatwareCondition ([string]$windowsAppRuntimeInUseResult.Message -like '*in-use framework/runtime skipped 2*') 'WindowsAppRuntime in-use result message must include the in-use framework/runtime count.'

    $ordinaryInUseFailureResult = Invoke-BoostLabBloatwareRemoveAppxExcept `
        -ExcludeLike $excludePatterns `
        -AppxGetter { @([pscustomobject]@{ Name = 'Contoso.ConsumerApp'; PackageFullName = 'Contoso.ConsumerApp_1'; PackageFamilyName = 'Contoso.ConsumerApp_family'; User = 'S-1-11'; InstallLocation = 'C:\Mock\ConsumerApp'; IsFramework = $false }) } `
        -AppxRemover { throw 'Remove-AppxPackage failed with HRESULT 0x80073D02: The package could not be installed because resources it modifies are currently in use.' }
    Assert-BloatwareCondition (-not [bool]$ordinaryInUseFailureResult.Success) 'Ordinary consumer AppX in-use failures must remain fail-closed.'
    Assert-BloatwareCondition (@($ordinaryInUseFailureResult.FailedPackages).Count -eq 1) 'Ordinary consumer AppX in-use failure must be counted as an unexpected failure.'
    Assert-BloatwareCondition ([string]$ordinaryInUseFailureResult.FailedPackages[0].Outcome -eq 'FailedUnexpected') 'Ordinary consumer AppX in-use failure must remain FailedUnexpected.'

    $realFailureResult = Invoke-BoostLabBloatwareRemoveAppxExcept `
        -ExcludeLike $excludePatterns `
        -AppxGetter { @([pscustomobject]@{ Name = 'Contoso.Protected'; PackageFullName = 'Contoso.Protected_1'; PackageFamilyName = 'Contoso.Protected_family'; User = 'S-1-5'; InstallLocation = 'C:\Mock\Protected' }) } `
        -AppxRemover { throw 'Access is denied.' }
    Assert-BloatwareCondition (-not [bool]$realFailureResult.Success) 'RemoveAppxExcept must fail when a real package removal error occurs.'
    Assert-BloatwareCondition (@($realFailureResult.FailedPackages).Count -eq 1) 'RemoveAppxExcept must report real failed package removals.'
    Assert-BloatwareCondition ([string]$realFailureResult.FailedPackages[0].Package.PackageFullName -eq 'Contoso.Protected_1') 'RemoveAppxExcept real failure must include PackageFullName.'
    Assert-BloatwareCondition ([string]$realFailureResult.FailedPackages[0].Package.PackageFamilyName -eq 'Contoso.Protected_family') 'RemoveAppxExcept real failure must include PackageFamilyName.'
    Assert-BloatwareCondition ([string]$realFailureResult.FailedPackages[0].Outcome -eq 'FailedUnexpected') 'Unexpected AppX removal failure must remain a hard FailedUnexpected outcome.'

    $stopAfterFailureSeen = [System.Collections.Generic.List[string]]::new()
    $stopAfterFailureExecutor = {
        param($Operation, $Branch, $Plan)
        $stopAfterFailureSeen.Add([string]$Operation.Type)
        [pscustomobject]@{
            Success = ([string]$Operation.Type -ne 'RemoveAppxExcept')
            Order = [int]$Operation.Order
            Branch = [string]$Branch
            Category = [string]$Operation.Category
            Type = [string]$Operation.Type
            Label = [string]$Operation.Label
            Message = if ([string]$Operation.Type -eq 'RemoveAppxExcept') { 'Mocked AppX package failure.' } else { 'Mocked operation completed.' }
            Data = [pscustomobject]@{ PlanBranch = [string]$Plan.Branch }
        }
    }.GetNewClosure()
    $failedRemoveAppxWorkflow = Invoke-BoostLabBloatwareBranchWorkflow -Branch 'RemoveAllBloatware' -SkipEnvironmentChecks $true -OperationExecutor $stopAfterFailureExecutor
    Assert-BloatwareCondition (-not [bool]$failedRemoveAppxWorkflow.Success) 'Bloatware branch must stop on a real RemoveAppxExcept failure.'
    Assert-BloatwareCondition ([string]$failedRemoveAppxWorkflow.FailedOperation.Type -eq 'RemoveAppxExcept') 'Bloatware branch must identify RemoveAppxExcept as the failed operation.'
    Assert-BloatwareCondition (($stopAfterFailureSeen.ToArray() -join ',') -eq 'RegistryCommand,RemoveAppxExcept') 'Bloatware branch must not continue after a real RemoveAppxExcept failure.'

    $continueAfterInUseSeen = [System.Collections.Generic.List[string]]::new()
    $continueAfterInUseExecutor = {
        param($Operation, $Branch, $Plan)
        $continueAfterInUseSeen.Add([string]$Operation.Type)
        [pscustomobject]@{
            Success = $true
            Order = [int]$Operation.Order
            Branch = [string]$Branch
            Category = [string]$Operation.Category
            Type = [string]$Operation.Type
            Label = [string]$Operation.Label
            Message = if ([string]$Operation.Type -eq 'RemoveAppxExcept') { [string]$windowsAppRuntimeInUseResult.Message } else { 'Mocked operation completed.' }
            Data = if ([string]$Operation.Type -eq 'RemoveAppxExcept') { $windowsAppRuntimeInUseResult } else { [pscustomobject]@{ PlanBranch = [string]$Plan.Branch } }
        }
    }.GetNewClosure()
    $continueAfterInUseWorkflow = Invoke-BoostLabBloatwareBranchWorkflow -Branch 'RemoveAllBloatware' -SkipEnvironmentChecks $true -OperationExecutor $continueAfterInUseExecutor
    Assert-BloatwareCondition ([bool]$continueAfterInUseWorkflow.Success) 'Bloatware branch must continue when RemoveAppxExcept only skipped known Windows protected/dependency/in-use framework runtime packages.'
    Assert-BloatwareCondition ('RemoveWindowsCapabilityExcept' -in @($continueAfterInUseSeen)) 'Bloatware branch must not stop after only in-use framework/runtime AppX skips.'

    $continueAfterMissingSnippingSeen = [System.Collections.Generic.List[string]]::new()
    $continueAfterMissingSnippingExecutor = {
        param($Operation, $Branch, $Plan)
        $continueAfterMissingSnippingSeen.Add([string]$Operation.Label)
        if ([string]$Operation.Label -eq 'Uninstall legacy Snipping Tool') {
            return & $module {
                param($SnippingOperation)
                Invoke-BoostLabBloatwareStartProcessOperation `
                    -Operation $SnippingOperation `
                    -PathTester { param($Path) $false } `
                    -ProcessStarter { throw 'StartProcess must not run for a missing legacy Snipping Tool executable.' }
            } $Operation
        }

        [pscustomobject]@{
            Success = $true
            Order = [int]$Operation.Order
            Branch = [string]$Branch
            Category = [string]$Operation.Category
            Type = [string]$Operation.Type
            Label = [string]$Operation.Label
            Message = 'Mocked operation completed.'
            Data = [pscustomobject]@{ PlanBranch = [string]$Plan.Branch }
        }
    }.GetNewClosure()
    $continueAfterMissingSnippingWorkflow = Invoke-BoostLabBloatwareBranchWorkflow -Branch 'RemoveAllBloatware' -SkipEnvironmentChecks $true -OperationExecutor $continueAfterMissingSnippingExecutor
    Assert-BloatwareCondition ([bool]$continueAfterMissingSnippingWorkflow.Success) 'Bloatware RemoveAllBloatware must not fail solely because legacy SnippingTool.exe is absent.'
    $missingSnippingWorkflowResult = @($continueAfterMissingSnippingWorkflow.OperationResults | Where-Object { [string]$_.Label -eq 'Uninstall legacy Snipping Tool' }) | Select-Object -First 1
    Assert-BloatwareCondition ($null -ne $missingSnippingWorkflowResult) 'Bloatware missing Snipping Tool workflow result must include the uninstall operation.'
    Assert-BloatwareCondition ([string]$missingSnippingWorkflowResult.Data.Outcome -eq 'SkippedMissingLegacySnippingTool') 'Bloatware missing Snipping Tool workflow result must preserve the expected skip diagnostic.'
    Assert-BloatwareCondition ('Close Snipping Tool uninstall window' -in @($continueAfterMissingSnippingSeen)) 'Bloatware branch must continue to the Snipping Tool close-window operation after the missing executable skip.'
    Assert-BloatwareCondition ('Uninstall Windows 10 Update for x64-based systems' -in @($continueAfterMissingSnippingSeen)) 'Bloatware branch must continue to later operations after the missing legacy Snipping Tool skip.'

    $storePlan = Get-BoostLabBloatwareOperationPlan -Branch 'InstallStore'
    foreach ($requiredType in @('AppxRegisterLike', 'StartProcess', 'StopProcesses', 'RegistryCommand', 'StoreSettingsHiveImport')) {
        Assert-BloatwareCondition ($storePlan.Operations.Type -contains $requiredType) "Install Store plan is missing operation type $requiredType."
    }

    $expectedStoreHiveValues = @{
        'HKLM:\Settings\LocalState|VideoAutoplay' = '00,96,9d,69,8d,cd,93,dc,01'
        'HKLM:\Settings\LocalState|EnableAppInstallNotifications' = '00,36,d0,88,8e,cd,93,dc,01'
        'HKLM:\Settings\LocalState\PersistentSettings|PersonalizationEnabled' = '00,0d,56,a1,8a,cd,93,dc,01'
    }
    $newStoreHiveState = {
        param(
            [string]$Path,
            [string]$Name,
            [bool]$Exists,
            [string]$DisplayValue,
            [string]$Message
        )

        [pscustomobject]@{
            ReadSucceeded = $true
            KeyExists = $true
            Exists = $Exists
            Value = $DisplayValue
            ValueType = if ($Exists) { 'REG_5F5E10B' } else { $null }
            DisplayValue = if ($Exists) { $DisplayValue } else { 'Absent' }
            Message = $Message
            ReadMethod = 'Mock registry provider'
        }
    }

    $regQueryOutput = @'
HKEY_LOCAL_MACHINE\Settings\LocalState
    VideoAutoplay    REG_5F5E10B    00 96 9d 69 8d cd
        93 dc 01
'@
    $fallbackHiveState = & $module {
        param($Output)
        ConvertFrom-BoostLabBloatwareStoreRegQueryOutput `
            -Output $Output `
            -Path 'HKLM:\Settings\LocalState' `
            -Name 'VideoAutoplay'
    } $regQueryOutput
    Assert-BloatwareCondition ([string]$fallbackHiveState.ReadMethod -eq 'reg query') 'Bloatware Store hive custom value reader must support reg query fallback.'
    Assert-BloatwareCondition ([string]$fallbackHiveState.ValueType -eq 'REG_5F5E10B') 'Bloatware Store hive fallback must preserve the custom REG_5F5E10B type.'
    Assert-BloatwareCondition ([string]$fallbackHiveState.DisplayValue -eq $expectedStoreHiveValues['HKLM:\Settings\LocalState|VideoAutoplay']) 'Bloatware Store hive fallback must normalize custom value bytes.'
    $bloatwareContiguousComparison = & $module {
        Compare-BoostLabBloatwareStoreByteDisplay `
            -Expected '00,96,9d,69,8d,cd,93,dc,01' `
            -Actual '00969D698DCD93DC01'
    }
    Assert-BloatwareCondition ([bool]$bloatwareContiguousComparison.ByteComparisonSucceeded) 'Bloatware Store hive byte comparison must pass contiguous uppercase reg query bytes.'

    $successfulHiveEvents = [System.Collections.Generic.List[string]]::new()
    $successfulHiveCommandInvoker = {
        param($CommandText)
        $successfulHiveEvents.Add("COMMAND:$CommandText")
        [pscustomobject]@{
            ExitCode = 0
            StandardOutput = 'The operation completed successfully.'
            StandardError = ''
        }
    }.GetNewClosure()
    $successfulHiveFileWriter = {
        param($Path, $Content)
        $successfulHiveEvents.Add("FILE:$Path")
        if ($Content -notmatch 'hex\(5f5e10b\)' -or $Content -notmatch 'PersonalizationEnabled') {
            throw 'Mock Bloatware Store settings registry payload did not preserve source custom values.'
        }
    }.GetNewClosure()
    $successfulHivePathTester = {
        param($Path)
        $successfulHiveEvents.Add("PATH:$Path")
        return $true
    }.GetNewClosure()
    $successfulHiveReader = {
        param($Path, $Name)
        $successfulHiveEvents.Add("READ:$Path|$Name")
        $expected = $expectedStoreHiveValues["$Path|$Name"]
        $actual = ([string]$expected -replace ',', '').ToUpperInvariant()
        & $newStoreHiveState $Path $Name $true $actual 'Mock Store hive value detected before unload as contiguous bytes.'
    }.GetNewClosure()
    $successfulHiveDelay = {
        param($Seconds)
        $successfulHiveEvents.Add("DELAY:$Seconds")
    }.GetNewClosure()
    $successfulHiveImport = & $module {
        param($CommandInvoker, $FileWriter, $PathTester, $Reader, $Delay)
        Invoke-BoostLabBloatwareStoreSettingsHiveImport `
            -RegFile 'C:\Windows\Temp\windowsstore.reg' `
            -SettingsDat 'C:\Users\Tester\AppData\Local\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\Settings\settings.dat' `
            -RegContent (Get-BoostLabBloatwareWindowsStoreRegContent) `
            -RegistryCommandInvoker $CommandInvoker `
            -RegistryFileWriter $FileWriter `
            -PathTester $PathTester `
            -RegistryReader $Reader `
            -DelayInvoker $Delay
    } $successfulHiveCommandInvoker $successfulHiveFileWriter $successfulHivePathTester $successfulHiveReader $successfulHiveDelay
    Assert-BloatwareCondition ([bool]$successfulHiveImport.Success) 'Bloatware StoreSettingsHiveImport must succeed when native reg commands return exit code 0 with success text.'
    Assert-BloatwareCondition ([string]$successfulHiveImport.RegistryImportWriteEncoding -eq 'Unicode') 'Bloatware StoreSettingsHiveImport must write the .reg payload as Unicode.'
    Assert-BloatwareCondition (@($successfulHiveImport.StoreHiveValuesCaptured).Count -eq 3) 'Bloatware StoreSettingsHiveImport must capture all source-defined Store hive values before unload.'
    Assert-BloatwareCondition ([string]$successfulHiveImport.VerificationStatus -eq 'Passed') 'Bloatware StoreSettingsHiveImport verification status must pass when all custom values match.'
    foreach ($state in @($successfulHiveImport.StoreHiveValuesCaptured)) {
        Assert-BloatwareCondition ([bool]$state.ByteComparisonSucceeded) 'Bloatware StoreSettingsHiveImport must mark byte-equivalent Store hive values as matching.'
        Assert-BloatwareCondition ([string]$state.ExpectedBytesNormalized -eq [string]$state.ActualBytesNormalized) 'Bloatware StoreSettingsHiveImport must report matching normalized byte data.'
    }
    Assert-BloatwareCondition ([string]$successfulHiveImport.StoreReRegistrationRuntimeNote -like '*separate from settings.dat hive import verification*') 'Bloatware Store re-registration note must not masquerade as a hive import failure.'
    $successfulHiveEventText = $successfulHiveEvents -join '|'
    foreach ($requiredEventText in @(
        'FILE:C:\Windows\Temp\windowsstore.reg'
        'PATH:C:\Users\Tester\AppData\Local\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\Settings\settings.dat'
        'COMMAND:reg load "HKLM\Settings" "C:\Users\Tester\AppData\Local\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\Settings\settings.dat"'
        'COMMAND:reg import "C:\Windows\Temp\windowsstore.reg"'
        'COMMAND:reg unload "HKLM\Settings"'
    )) {
        Assert-BloatwareCondition ($successfulHiveEventText.Contains($requiredEventText)) "Bloatware StoreSettingsHiveImport did not record: $requiredEventText"
    }
    $importEventIndex = $successfulHiveEventText.IndexOf('COMMAND:reg import "C:\Windows\Temp\windowsstore.reg"')
    $unloadEventIndex = $successfulHiveEventText.IndexOf('COMMAND:reg unload "HKLM\Settings"')
    foreach ($hiveValueRead in @(
        'READ:HKLM:\Settings\LocalState|VideoAutoplay'
        'READ:HKLM:\Settings\LocalState|EnableAppInstallNotifications'
        'READ:HKLM:\Settings\LocalState\PersistentSettings|PersonalizationEnabled'
    )) {
        $readIndex = $successfulHiveEventText.IndexOf($hiveValueRead)
        Assert-BloatwareCondition ($readIndex -gt $importEventIndex -and $readIndex -lt $unloadEventIndex) "Bloatware StoreSettingsHiveImport must read $hiveValueRead after import and before unload."
    }

    $missingSettingsDatEvents = [System.Collections.Generic.List[string]]::new()
    $missingSettingsDatImport = & $module {
        param($Events)
        Invoke-BoostLabBloatwareStoreSettingsHiveImport `
            -RegFile 'C:\Windows\Temp\windowsstore.reg' `
            -SettingsDat 'C:\Missing\settings.dat' `
            -RegContent (Get-BoostLabBloatwareWindowsStoreRegContent) `
            -RegistryFileWriter { param($Path, $Content) $Events.Add("FILE:$Path") } `
            -PathTester { param($Path) $Events.Add("PATH:$Path"); return $false } `
            -RegistryCommandInvoker { throw 'Registry commands must not run when settings.dat is missing.' } `
            -DelayInvoker { }
    } $missingSettingsDatEvents
    Assert-BloatwareCondition (-not [bool]$missingSettingsDatImport.Success) 'Bloatware StoreSettingsHiveImport must fail closed when settings.dat is missing.'
    Assert-BloatwareCondition (($missingSettingsDatEvents.ToArray() -join '|') -eq 'FILE:C:\Windows\Temp\windowsstore.reg|PATH:C:\Missing\settings.dat') 'Bloatware StoreSettingsHiveImport must not load/import/unload when settings.dat is missing.'

    $loadFailureEvents = [System.Collections.Generic.List[string]]::new()
    $loadFailureImport = & $module {
        param($Events)
        Invoke-BoostLabBloatwareStoreSettingsHiveImport `
            -RegFile 'C:\Windows\Temp\windowsstore.reg' `
            -SettingsDat 'C:\Mock\settings.dat' `
            -RegContent (Get-BoostLabBloatwareWindowsStoreRegContent) `
            -RegistryFileWriter { } `
            -PathTester { return $true } `
            -RegistryCommandInvoker {
                param($CommandText)
                $Events.Add("COMMAND:$CommandText")
                [pscustomobject]@{ ExitCode = 5; StandardOutput = ''; StandardError = '' }
            } `
            -DelayInvoker { }
    } $loadFailureEvents
    Assert-BloatwareCondition (-not [bool]$loadFailureImport.Success) 'Bloatware StoreSettingsHiveImport must fail closed when reg load fails.'
    Assert-BloatwareCondition ([string]$loadFailureImport.Message -like '*LoadStoreSettingsHive returned exit code 5*') 'Bloatware StoreSettingsHiveImport must report a non-empty reg load diagnostic.'
    Assert-BloatwareCondition (($loadFailureEvents.ToArray() -join '|') -eq 'COMMAND:reg load "HKLM\Settings" "C:\Mock\settings.dat"') 'Bloatware StoreSettingsHiveImport must not import or unload after a failed hive load.'

    $missingValueEvents = [System.Collections.Generic.List[string]]::new()
    $missingValueReader = {
        param($Path, $Name)
        $missingValueEvents.Add("READ:$Path|$Name")
        if ($Name -eq 'EnableAppInstallNotifications') {
            return (& $newStoreHiveState $Path $Name $false '' 'Mock value absent after import.')
        }
        & $newStoreHiveState $Path $Name $true $expectedStoreHiveValues["$Path|$Name"] 'Mock Store hive value detected.'
    }.GetNewClosure()
    $missingValueCommandInvoker = {
        param($CommandText)
        $missingValueEvents.Add("COMMAND:$CommandText")
        [pscustomobject]@{ ExitCode = 0; StandardOutput = ''; StandardError = '' }
    }.GetNewClosure()
    $missingValueImport = & $module {
        param($CommandInvoker, $Reader)
        Invoke-BoostLabBloatwareStoreSettingsHiveImport `
            -RegFile 'C:\Windows\Temp\windowsstore.reg' `
            -SettingsDat 'C:\Mock\settings.dat' `
            -RegContent (Get-BoostLabBloatwareWindowsStoreRegContent) `
            -RegistryFileWriter { } `
            -PathTester { return $true } `
            -RegistryCommandInvoker $CommandInvoker `
            -RegistryReader $Reader `
            -DelayInvoker { }
    } $missingValueCommandInvoker $missingValueReader
    Assert-BloatwareCondition (-not [bool]$missingValueImport.Success) 'Bloatware StoreSettingsHiveImport must fail when a source-required Store hive value is absent.'
    Assert-BloatwareCondition ([string]$missingValueImport.Message -like '*EnableAppInstallNotifications was absent*') 'Bloatware StoreSettingsHiveImport must identify the absent Store hive value.'
    Assert-BloatwareCondition (($missingValueEvents.ToArray() -join '|').Contains('COMMAND:reg unload "HKLM\Settings"')) 'Bloatware StoreSettingsHiveImport must unload the hive after verification failure.'

    $mismatchValueReader = {
        param($Path, $Name)
        if ($Name -eq 'PersonalizationEnabled') {
            return (& $newStoreHiveState $Path $Name $true '00,00,00,00,00,00,00,00,00' 'Mock value mismatch.')
        }
        & $newStoreHiveState $Path $Name $true $expectedStoreHiveValues["$Path|$Name"] 'Mock Store hive value detected.'
    }.GetNewClosure()
    $mismatchValueImport = & $module {
        param($Reader)
        Invoke-BoostLabBloatwareStoreSettingsHiveImport `
            -RegFile 'C:\Windows\Temp\windowsstore.reg' `
            -SettingsDat 'C:\Mock\settings.dat' `
            -RegContent (Get-BoostLabBloatwareWindowsStoreRegContent) `
            -RegistryFileWriter { } `
            -PathTester { return $true } `
            -RegistryCommandInvoker { [pscustomobject]@{ ExitCode = 0; StandardOutput = ''; StandardError = '' } } `
            -RegistryReader $Reader `
            -DelayInvoker { }
    } $mismatchValueReader
    Assert-BloatwareCondition (-not [bool]$mismatchValueImport.Success) 'Bloatware StoreSettingsHiveImport must fail when a source-required Store hive value has wrong bytes.'
    Assert-BloatwareCondition ([string]$mismatchValueImport.Message -like '*PersonalizationEnabled mismatch*') 'Bloatware StoreSettingsHiveImport must report expected and actual bytes for mismatched Store hive values.'

    $malformedValueReader = {
        param($Path, $Name)
        if ($Name -eq 'VideoAutoplay') {
            return (& $newStoreHiveState $Path $Name $true '00,zz' 'Mock malformed Store hive bytes.')
        }
        & $newStoreHiveState $Path $Name $true $expectedStoreHiveValues["$Path|$Name"] 'Mock Store hive value detected.'
    }.GetNewClosure()
    $malformedValueImport = & $module {
        param($Reader)
        Invoke-BoostLabBloatwareStoreSettingsHiveImport `
            -RegFile 'C:\Windows\Temp\windowsstore.reg' `
            -SettingsDat 'C:\Mock\settings.dat' `
            -RegContent (Get-BoostLabBloatwareWindowsStoreRegContent) `
            -RegistryFileWriter { } `
            -PathTester { return $true } `
            -RegistryCommandInvoker { [pscustomobject]@{ ExitCode = 0; StandardOutput = ''; StandardError = '' } } `
            -RegistryReader $Reader `
            -DelayInvoker { }
    } $malformedValueReader
    Assert-BloatwareCondition (-not [bool]$malformedValueImport.Success) 'Bloatware StoreSettingsHiveImport must fail closed when Store hive bytes are malformed.'
    Assert-BloatwareCondition ([string]$malformedValueImport.Message -like '*Actual bytes could not be parsed*') 'Bloatware StoreSettingsHiveImport must report malformed byte diagnostics.'

    $unloadFailureReader = {
        param($Path, $Name)
        [pscustomobject]@{
            ReadSucceeded = $true
            KeyExists = $true
            Exists = $true
            ValueType = 'REG_5F5E10B'
            DisplayValue = $expectedStoreHiveValues["$Path|$Name"]
            Message = 'Mock Store hive value detected.'
        }
    }.GetNewClosure()
    $unloadFailureImport = & $module {
        param($Reader)
        Invoke-BoostLabBloatwareStoreSettingsHiveImport `
            -RegFile 'C:\Windows\Temp\windowsstore.reg' `
            -SettingsDat 'C:\Mock\settings.dat' `
            -RegContent (Get-BoostLabBloatwareWindowsStoreRegContent) `
            -RegistryFileWriter { } `
            -PathTester { return $true } `
            -RegistryCommandInvoker {
                param($CommandText)
                if ($CommandText -eq 'reg unload "HKLM\Settings"') {
                    return [pscustomobject]@{ ExitCode = 6; StandardOutput = ''; StandardError = 'Mock unload failure.' }
                }
                [pscustomobject]@{ ExitCode = 0; StandardOutput = ''; StandardError = '' }
            } `
            -RegistryReader $Reader `
            -DelayInvoker { }
    } $unloadFailureReader
    Assert-BloatwareCondition (-not [bool]$unloadFailureImport.Success) 'Bloatware StoreSettingsHiveImport must fail closed when hive unload fails.'
    Assert-BloatwareCondition ([string]$unloadFailureImport.Message -like '*UnloadStoreSettingsHive failed*Mock unload failure*') 'Bloatware StoreSettingsHiveImport must report hive unload failure details.'

    $uwpPlan = Get-BoostLabBloatwareOperationPlan -Branch 'InstallAllUwpApps'
    Assert-BloatwareCondition ($uwpPlan.Operations.Type -contains 'AppxRegisterAll') 'Install all UWP apps plan must re-register all AppX packages.'

    foreach ($featureBranch in @('OpenUwpFeatures', 'OpenLegacyFeatures')) {
        $featurePlan = Get-BoostLabBloatwareOperationPlan -Branch $featureBranch
        Assert-BloatwareCondition ($featurePlan.Operations.Type -contains 'StartProcess') "$featureBranch must preserve the source settings/control-panel open behavior."
        Assert-BloatwareCondition ($featurePlan.Operations.Type -contains 'DisplayList') "$featureBranch must preserve the source optional feature list behavior."
    }

    $oneDrivePlan = Get-BoostLabBloatwareOperationPlan -Branch 'InstallOneDrive'
    $oneDriveCommands = @(
        $oneDrivePlan.Operations | ForEach-Object {
            if ($_.Parameters -is [System.Collections.IDictionary] -and $_.Parameters.Contains('Command')) {
                [string]$_.Parameters['Command']
            }
        }
    )
    Assert-BloatwareCondition (($oneDriveCommands -join "`n").Contains('{SysWow64OneDriveSetup}')) 'Install OneDrive must preserve the SysWOW64 setup branch.'
    Assert-BloatwareCondition (($oneDriveCommands -join "`n").Contains('{System32OneDriveSetup}')) 'Install OneDrive must preserve the System32 setup branch.'

    $rdpPlan = Get-BoostLabBloatwareOperationPlan -Branch 'InstallRemoteDesktopConnection'
    $rdpDownload = @($rdpPlan.DownloadArtifacts) | Select-Object -First 1
    Assert-BloatwareCondition ([string]$rdpDownload.Url -eq 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/remotedesktopconnection.exe') 'Remote Desktop Connection source URL mismatch.'
    Assert-BloatwareCondition ([string]$rdpDownload.Classification -eq 'UltimateAuthorHostedArtifact') 'Remote Desktop Connection must be classified as UltimateAuthorHostedArtifact.'
    Assert-BloatwareCondition ([bool]$rdpDownload.NeedsBoostLabMirror) 'Remote Desktop Connection must remain NeedsBoostLabMirror.'

    $snipPlan = Get-BoostLabBloatwareOperationPlan -Branch 'InstallSnippingTool'
    $snipDownload = @($snipPlan.DownloadArtifacts) | Select-Object -First 1
    Assert-BloatwareCondition ([string]$snipDownload.Url -eq 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/snippingtool.exe') 'Snipping Tool source URL mismatch.'
    Assert-BloatwareCondition ([string]$snipDownload.Classification -eq 'UltimateAuthorHostedArtifact') 'Snipping Tool must be classified as UltimateAuthorHostedArtifact.'
    Assert-BloatwareCondition ([bool]$snipDownload.NeedsBoostLabMirror) 'Snipping Tool must remain NeedsBoostLabMirror.'
    Assert-BloatwareCondition ($snipPlan.Operations.Type -contains 'AppxRegisterLike') 'Snipping Tool branch must re-register Microsoft.ScreenSketch.'

    foreach ($unsupportedAction in @('Open', 'Default', 'Restore')) {
        $unsupportedResult = Invoke-BoostLabToolAction -ActionName $unsupportedAction
        Assert-BloatwareCondition (-not [bool]$unsupportedResult.Success) "$unsupportedAction must remain unsupported for Bloatware."
        Assert-BloatwareCondition ([string]$unsupportedResult.Status -eq 'UnsupportedAction') "$unsupportedAction must return UnsupportedAction."
        Assert-BloatwareCondition (-not [bool]$unsupportedResult.ChangesExecuted) "$unsupportedAction must execute no changes."
    }

    $noBranchResult = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed $true -SkipEnvironmentChecks $true
    Assert-BloatwareCondition (-not [bool]$noBranchResult.Success) 'Apply without branch should fail closed.'
    Assert-BloatwareCondition ([string]$noBranchResult.Status -eq 'NeedsBranchSelection') 'Apply without branch must return NeedsBranchSelection.'
    Assert-BloatwareCondition (-not [bool]$noBranchResult.ChangesExecuted) 'Apply without branch must execute no changes.'

    $multiBranchResult = Invoke-BoostLabToolAction -ActionName 'Apply' -SelectedAppIds @('InstallStore', 'InstallAllUwpApps') -Confirmed $true -SkipEnvironmentChecks $true
    Assert-BloatwareCondition (-not [bool]$multiBranchResult.Success) 'Apply with multiple branches should fail closed.'
    Assert-BloatwareCondition ([string]$multiBranchResult.Status -eq 'NeedsBranchSelection') 'Apply with multiple branches must return NeedsBranchSelection.'
    Assert-BloatwareCondition (-not [bool]$multiBranchResult.ChangesExecuted) 'Apply with multiple branches must execute no changes.'

    foreach ($expected in $expectedBranches) {
        $mockedBloatwareOperations = [System.Collections.Generic.List[object]]::new()
        $mockExecutor = {
            param($Operation, $Branch, $Plan)
            $mockedBloatwareOperations.Add($Operation)
            [pscustomobject]@{
                Success = $true
                Order = [int]$Operation.Order
                Branch = [string]$Branch
                Category = [string]$Operation.Category
                Type = [string]$Operation.Type
                Label = [string]$Operation.Label
                Message = 'Mocked operation completed.'
                Data = [pscustomobject]@{ PlanBranch = [string]$Plan.Branch }
            }
        }.GetNewClosure()

        $applyResult = Invoke-BoostLabToolAction -ActionName 'Apply' -Branch ([string]$expected.Id) -Confirmed $true -SkipEnvironmentChecks $true -OperationExecutor $mockExecutor
        Assert-BloatwareCondition ([bool]$applyResult.Success) "Mocked Apply should succeed for branch $($expected.Id)."
        Assert-BloatwareCondition ([string]$applyResult.CommandStatus -eq 'Completed') "Mocked Apply must report completed for branch $($expected.Id)."
        Assert-BloatwareCondition ([bool]$applyResult.ChangesExecuted) "Mocked Apply must report changes executed for branch $($expected.Id)."
        $expectedMockCount = [int]$expected['Count'] - 2
        Assert-BloatwareCondition ($mockedBloatwareOperations.Count -eq $expectedMockCount) "Mocked Apply executed the wrong number of operations for branch $($expected.Id)."
        Assert-BloatwareCondition (@($mockedBloatwareOperations | Where-Object { [string]$_.Branch -ne [string]$expected.Id }).Count -eq 0) "Mocked Apply executed a wrong-branch operation for $($expected.Id)."
    }

    $mockedBloatwareOperations = [System.Collections.Generic.List[object]]::new()
    $failingExecutor = {
        param($Operation, $Branch, $Plan)
        $mockedBloatwareOperations.Add($Operation)
        [pscustomobject]@{
            Success = $false
            Order = [int]$Operation.Order
            Branch = [string]$Branch
            Category = [string]$Operation.Category
            Type = [string]$Operation.Type
            Label = [string]$Operation.Label
            Message = 'Mocked operation failed.'
            Data = [pscustomobject]@{ PlanBranch = [string]$Plan.Branch }
        }
    }.GetNewClosure()
    $failedApply = Invoke-BoostLabToolAction -ActionName 'Apply' -Branch 'InstallStore' -Confirmed $true -SkipEnvironmentChecks $true -OperationExecutor $failingExecutor
    Assert-BloatwareCondition (-not [bool]$failedApply.Success) 'Apply must fail closed when a branch operation fails.'
    Assert-BloatwareCondition ([string]$failedApply.Status -eq 'OperationFailed') 'Failed Apply must report OperationFailed.'
    Assert-BloatwareCondition ([string]$failedApply.VerificationStatus -eq 'Failed') 'Failed Apply must report failed verification.'
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
}

$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPolicyPath
Assert-BloatwareCondition (@($artifactPolicy.Artifacts).Count -eq 0) 'Bloatware must not approve artifact provenance entries.'
$productionAllowlist = Import-PowerShellDataFile -LiteralPath $productionAllowlistPath
Assert-BloatwareCondition (@($productionAllowlist.ProductionAllowlistProposals).Count -eq 0) 'Bloatware must not add production allowlist proposals.'

$inventory = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
$bloatwareRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'bloatware' }) | Select-Object -First 1
Assert-BloatwareCondition ($null -ne $bloatwareRecord) 'Bloatware parity record is missing.'
Assert-BloatwareCondition ([string]$bloatwareRecord.RuntimeStatus -eq 'RuntimeImplemented') 'Bloatware must be runtime implemented.'
Assert-BloatwareCondition ([string]$bloatwareRecord.ImplementationLevel -eq 'ParityImplemented') 'Bloatware must be marked ParityImplemented.'
Assert-BloatwareCondition ([string]$bloatwareRecord.UltimateParity -eq 'Yes') 'Bloatware UltimateParity must be Yes.'
Assert-BloatwareCondition ([string]$bloatwareRecord.FinalProgressStatus -eq 'DoneParity') 'Bloatware final progress must be DoneParity.'
Assert-BloatwareCondition (-not [bool]$bloatwareRecord.YazanFinalException) 'Bloatware must not use a Yazan final exception.'
Assert-BloatwareCondition (($bloatwareRecord.ApprovedSourceBranches -join ',') -eq ($expectedParityBranchTitles -join ',')) 'Bloatware parity record must list every approved non-Exit source branch.'
Assert-BloatwareCondition ([string]$parityBaseline.CurrentOrderedParityTarget -eq [string]$nextTarget.ToolId) 'Current ordered parity target must match the derived first non-final target.'
Assert-BloatwareCondition ([string]$bloatwareRecord.FinalProgressStatus -eq 'DoneParity') 'Bloatware must remain accepted before the ordered cursor advances past it.'

$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
foreach ($level in @('ParityImplemented', 'NearParityControlled', 'ControlledSubset', 'ManualHandoffOnly', 'DeferredForParityWork')) {
    $actual = if ($categoryCounts.ContainsKey($level)) { [int]$categoryCounts[$level] } else { 0 }
    $expected = switch ($level) {
        'ParityImplemented' { [int]$parityBaseline.Counts.UltimateParityImplemented }
        'NearParityControlled' { [int]$parityBaseline.Counts.NearParityControlled }
        'ControlledSubset' { [int]$parityBaseline.Counts.ControlledSubset }
        'ManualHandoffOnly' { [int]$parityBaseline.Counts.ManualHandoffOnly }
        'DeferredForParityWork' { [int]$parityBaseline.Counts.DeferredForParityWork }
    }
    Assert-BloatwareCondition ($actual -eq $expected) "Unexpected parity category count for $level."
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
    Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
    Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
    ForEach-Object {
        '{0}|{1}' -f $_.FullName.Substring($root.Length + 1).Replace('\', '/'), (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    }
$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $manifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n")))
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}
Assert-BloatwareCondition (@($sourceLines).Count -eq 49) 'source-ultimate file count changed.'
Assert-BloatwareCondition ($manifestHash -eq '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477') 'source-ultimate manifest hash changed.'

foreach ($deletedPath in @(
    'source-ultimate\6 Windows\17 Loudness EQ.ps1',
    'modules\Windows\loudness-eq.psm1',
    'source-ultimate\6 Windows\20 NVME Faster Driver.ps1',
    'modules\Windows\nvme-faster-driver.psm1'
)) {
    Assert-BloatwareCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $deletedPath))) "Deleted tool path was reintroduced: $deletedPath"
}

[pscustomobject]@{
    Success                    = $true
    ToolId                     = 'bloatware'
    SourceHash                 = $actualSourceHash
    BranchCount                = $expectedBranches.Count
    ActiveTools                = [int]$inventory.Snapshot.ActiveTools
    RuntimeImplementedTools    = [int]$inventory.Snapshot.ImplementedTools
    DeferredPlaceholders       = [int]$inventory.Snapshot.DeferredPlaceholders
    CurrentOrderedParityTarget = [string]$parityBaseline.CurrentOrderedParityTarget
    NextOrderedTarget          = [string]$nextTarget.ToolId
    ArtifactApprovals          = @($artifactPolicy.Artifacts).Count
    ProductionAllowlistEntries = @($productionAllowlist.ProductionAllowlistProposals).Count
    SourceUltimateUnchanged    = $true
    DeletedToolsRemainDeleted  = $true
    Message                    = 'Bloatware exact Ultimate parity is implemented through a branch-selected, confirmed, source-equivalent runtime with mocked validator execution.'
    Timestamp                  = Get-Date
}
