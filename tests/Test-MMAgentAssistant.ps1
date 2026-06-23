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
        throw 'Unable to determine the MMAgent Assistant test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
. (Join-Path $ProjectRoot 'tests\BoostLab.ParityStatusBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot
$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Advanced\mmagent-assistant.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\8 Advanced\2 MMAgent Assistant.ps1'
$recordPath = Join-Path $ProjectRoot 'docs\migrations\mmagent-assistant.md'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration['Stages'] | ForEach-Object { $_['Tools'] })
$tool = $tools | Where-Object { $_['Id'] -eq 'mmagent-assistant' } | Select-Object -First 1
if ($null -eq $tool) {
    throw 'MMAgent Assistant metadata is missing.'
}
if (
    [string]$tool['Stage'] -ne 'Advanced' -or
    [int]$tool['Order'] -ne 2 -or
    [string]$tool['Type'] -ne 'assistant' -or
    [string]$tool['RiskLevel'] -ne 'high' -or
    (@($tool['Actions']) -join ',') -ne 'Analyze,Apply,Default' -or
    [string]$tool['Description'] -match '\b[Rr]estore\b'
) {
    throw 'MMAgent Assistant metadata is incorrect.'
}

$allActiveToolIds = @($tools | ForEach-Object { [string]$_['Id'] })
foreach ($deletedToolId in @('resizable-bar-assistant', 'smt-ht-assistant')) {
    if ($allActiveToolIds -contains $deletedToolId) {
        throw "Deleted tool returned to active product scope: $deletedToolId"
    }
}

$parityRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'mmagent-assistant' }) | Select-Object -First 1
if ($null -eq $parityRecord) {
    throw 'MMAgent Assistant parity baseline record is missing.'
}
if (
    [string]$parityRecord.RuntimeStatus -ne 'RuntimeImplemented' -or
    [string]$parityRecord.ImplementationLevel -ne 'ParityImplemented' -or
    [string]$parityRecord.UltimateParity -ne 'Yes' -or
    [bool]$parityRecord.YazanFinalException
) {
    throw 'MMAgent Assistant parity baseline was not finalized as exact Ultimate parity.'
}

$nextOrderedTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
if ($null -eq $nextOrderedTarget) {
    throw 'Ordered parity cursor did not identify the next Advanced target after MMAgent Assistant.'
}
$isOrderedParityComplete = ($parityBaseline.ContainsKey('OrderedParityComplete') -and [bool]$parityBaseline.OrderedParityComplete)
if ($isOrderedParityComplete) {
    if ($null -ne $parityBaseline.CurrentOrderedParityTarget -or -not [bool]$nextOrderedTarget.IsOrderedParityComplete) {
        throw 'Ordered parity completion state is inconsistent after MMAgent Assistant.'
    }
}
elseif ([string]$parityBaseline.CurrentOrderedParityTarget -ne [string]$nextOrderedTarget.ToolId) {
    throw 'Central ordered parity cursor does not match the derived first non-final target.'
}
$advancedOrder = @($executionOrder.Stages | Where-Object { [string]$_.Name -eq 'Advanced' } | Select-Object -First 1)
$advancedTools = @($advancedOrder.Tools)
$mmaIndex = -1
for ($index = 0; $index -lt $advancedTools.Count; $index++) {
    if ([string]$advancedTools[$index].ToolId -eq 'mmagent-assistant') {
        $mmaIndex = $index
        break
    }
}
if ($mmaIndex -lt 0 -or $mmaIndex -ge ($advancedTools.Count - 1)) {
    throw 'MMAgent Assistant is not followed by another ordered Advanced target.'
}
$nextAdvancedIndex = -1
for ($index = 0; $index -lt $advancedTools.Count; $index++) {
    if ([string]$advancedTools[$index].ToolId -eq [string]$nextOrderedTarget.ToolId) {
        $nextAdvancedIndex = $index
        break
    }
}
if ($isOrderedParityComplete) {
    $nextAdvancedIndex = $advancedTools.Count
}
if ($nextAdvancedIndex -le $mmaIndex) {
    throw 'MMAgent acceptance did not advance to a later ordered Advanced tool.'
}

$capabilities = $tool['Capabilities']
foreach ($field in @('RequiresAdmin', 'CanModifyRegistry', 'SupportsDefault', 'NeedsExplicitConfirmation')) {
    if (-not [bool]$capabilities[$field]) {
        throw "MMAgent Assistant capability '$field' must be true."
    }
}
foreach ($field in @('RequiresInternet', 'CanReboot', 'CanModifyServices', 'CanInstallSoftware', 'CanDownload', 'CanModifyDrivers', 'CanModifySecurity', 'CanDeleteFiles', 'UsesTrustedInstaller', 'UsesSafeMode', 'SupportsRestore')) {
    if ([bool]$capabilities[$field]) {
        throw "MMAgent Assistant capability '$field' must be false."
    }
}

if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne 'C7E6E7879B7B32E548607A5D30124CC327622E09E7BEF817D36E8BC095B64A79') {
    throw 'MMAgent Assistant Ultimate source hash changed.'
}

$source = Get-Content -Raw -LiteralPath $sourcePath
$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredSourceText in @(
    '1. Off'
    '2. Default'
    '3. Check'
    'Disable-MMAgent -ApplicationLaunchPrefetching'
    'Disable-MMAgent -ApplicationPreLaunch'
    'Set-MMAgent -MaxOperationAPIFiles 1'
    'Disable-MMAgent -MemoryCompression'
    'Disable-MMAgent -OperationAPI'
    'Disable-MMAgent -PageCombining'
    'Enable-MMAgent -ApplicationLaunchPrefetching'
    'Enable-MMAgent -ApplicationPreLaunch'
    'Set-MMAgent -MaxOperationAPIFiles 512'
    'Enable-MMAgent -OperationAPI'
    'SETTINGS MAY TAKE A WHILE TO INITIALIZE AFTER REBOOT'
    'WAIT A SHORT PERIOD BEFORE CHECKING'
    'get-mmagent'
)) {
    if (-not $source.Contains($requiredSourceText)) {
        throw "MMAgent Assistant source no longer contains: $requiredSourceText"
    }
}

foreach ($requiredModuleText in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
    'function Test-BoostLabMMAgentAssistantState'
    'New-BoostLabVerificationResult'
    'The Ultimate Default profile still disables MemoryCompression and PageCombining.'
    'Use the dedicated Memory Compression tool when you only want to change MemoryCompression.'
    '[bool]$Confirmed = $false'
    'Get-MMAgent -ErrorAction Stop'
    'Set-MMAgent -MaxOperationAPIFiles $Operation.Value -ErrorAction SilentlyContinue'
    'function Invoke-BoostLabMMAgentCommandOperation'
    'OperationResults'
)) {
    if (-not $moduleSource.Contains($requiredModuleText)) {
        throw "MMAgent Assistant module is missing: $requiredModuleText"
    }
}

if ($moduleSource.Contains('MMAgent profile restored to the approved source Default state.')) {
    throw 'MMAgent Assistant Default result must not be worded as Restore.'
}

foreach ($forbiddenText in @(
    'Restart-Computer'
    'Stop-Computer'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'Set-Service'
    'Stop-Service'
    'Restart-Service'
    'Start-Process'
    'UsesTrustedInstaller = $true'
    'safeboot'
)) {
    if ($moduleSource.Contains($forbiddenText)) {
        throw "MMAgent Assistant module contains unrelated behavior: $forbiddenText"
    }
}

$module = Import-Module -Name $modulePath -Force -PassThru -Prefix 'MMAgentTest' -Scope Local -DisableNameChecking -ErrorAction Stop
try {
    $infoCommand = Get-Command -Name 'Get-MMAgentTestBoostLabToolInfo' -Module $module.Name -ErrorAction Stop
    $compatibilityCommand = Get-Command -Name 'Test-MMAgentTestBoostLabToolCompatibility' -Module $module.Name -ErrorAction Stop

    $toolInfo = & $infoCommand
    if (
        [string]$toolInfo.Id -ne 'mmagent-assistant' -or
        (@($toolInfo.Actions) -join ',') -ne 'Analyze,Apply,Default' -or
        (@($toolInfo.ImplementedActions) -join ',') -ne 'Analyze,Apply,Default'
    ) {
        throw 'MMAgent Assistant exported metadata or implemented actions are incorrect.'
    }

    $scalarCommandResolver = {
        param($CommandName)
        [pscustomobject]@{ Name = $CommandName }
    }
    $compatibility = & $compatibilityCommand -CommandResolver $scalarCommandResolver
    if (-not $compatibility.Supported) {
        throw 'MMAgent Assistant compatibility failed when required commands were available.'
    }

    $analyzeResult = & $module {
        Get-BoostLabMMAgentAnalyzeData -StateReader {
            [pscustomobject]@{
                ReadSucceeded = $true
                EnablePrefetcher = 3
                ApplicationLaunchPrefetching = $true
                ApplicationPreLaunch = $true
                MaxOperationAPIFiles = 512
                MemoryCompression = $false
                OperationAPI = $true
                PageCombining = $false
                Warnings = @()
                Message = 'Mocked state.'
            }
        }
    }
    if (
        $null -eq $analyzeResult -or
        @($analyzeResult.Notes).Count -lt 3 -or
        $analyzeResult.CurrentMemoryCompression -ne 'False'
    ) {
        throw 'MMAgent Assistant Analyze data did not return the expected structured result.'
    }

    $cancelledResult = & $module {
        Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$false
    }
    if (-not $cancelledResult.Cancelled -or $cancelledResult.Message -ne 'Cancelled by user') {
        throw 'MMAgent Assistant Apply confirmation handling is incorrect.'
    }

    foreach ($case in @(
        [pscustomobject]@{
            Action = 'Apply'
            ExpectedPrefetch = 0
            ExpectedLaunchPrefetching = $false
            ExpectedPreLaunch = $false
            ExpectedMaxApi = 1
            ExpectedMemoryCompression = $false
            ExpectedOperationApi = $false
            ExpectedPageCombining = $false
            ExpectedStatus = 'MMAgent profile set to Off.'
        }
        [pscustomobject]@{
            Action = 'Default'
            ExpectedPrefetch = 3
            ExpectedLaunchPrefetching = $true
            ExpectedPreLaunch = $true
            ExpectedMaxApi = 512
            ExpectedMemoryCompression = $false
            ExpectedOperationApi = $true
            ExpectedPageCombining = $false
            ExpectedStatus = 'MMAgent profile set to the approved source Default state.'
        }
    )) {
        $invocations = [System.Collections.Generic.List[string]]::new()
        $registryInvoker = {
            param($Value)
            $invocations.Add("Registry:$Value")
            [pscustomobject]@{ Success = $true; Output = '' }
        }.GetNewClosure()
        $mmaInvoker = {
            param($Operation)
            $suffix = if ($null -ne $Operation.PSObject.Properties['Value']) { ":$($Operation.Value)" } else { '' }
            $invocations.Add("$($Operation.Type):$($Operation.Name)$suffix")
        }.GetNewClosure()
        $stateReader = {
            [pscustomobject]@{
                ReadSucceeded = $true
                MMAgentReadSucceeded = $true
                RegistryReadSucceeded = $true
                EnablePrefetcher = $case.ExpectedPrefetch
                ApplicationLaunchPrefetching = $case.ExpectedLaunchPrefetching
                ApplicationPreLaunch = $case.ExpectedPreLaunch
                MaxOperationAPIFiles = $case.ExpectedMaxApi
                MemoryCompression = $case.ExpectedMemoryCompression
                OperationAPI = $case.ExpectedOperationApi
                PageCombining = $case.ExpectedPageCombining
                Warnings = @()
                Message = 'Mocked state.'
            }
        }.GetNewClosure()

        $result = & $module {
            param($ActionName, $CommandResolver, $RegistryInvoker, $MMAgentCommandInvoker, $StateReader)
            Invoke-BoostLabMMAgentAssistantAction `
                -ActionName $ActionName `
                -AdministratorChecker { return $true } `
                -CommandResolver $CommandResolver `
                -RegistryInvoker $RegistryInvoker `
                -MMAgentCommandInvoker $MMAgentCommandInvoker `
                -StateReader $StateReader
        } $case.Action $scalarCommandResolver $registryInvoker $mmaInvoker $stateReader

        if (
            -not $result.Success -or
            $result.Action -ne $case.Action -or
            $result.Message -ne $case.ExpectedStatus -or
            $result.Data.CommandStatus -ne 'Completed' -or
            $result.VerificationResult.Status -ne 'Passed' -or
            [int]$result.VerificationResult.ExpectedState.EnablePrefetcher -ne $case.ExpectedPrefetch -or
            [bool]$result.VerificationResult.ExpectedState.MemoryCompression -ne [bool]$case.ExpectedMemoryCompression -or
            [bool]$result.VerificationResult.ExpectedState.PageCombining -ne [bool]$case.ExpectedPageCombining
        ) {
            throw "Mocked MMAgent Assistant $($case.Action) path did not return the expected structured result."
        }
        if ($invocations.Count -ne 7) {
            throw "Mocked MMAgent Assistant $($case.Action) path did not execute the expected number of operations."
        }
        if (@($result.Data.OperationResults).Count -ne 7) {
            throw "Mocked MMAgent Assistant $($case.Action) path did not report all operation results."
        }
    }

    $applyPassedStateReader = {
        [pscustomobject]@{
            ReadSucceeded = $true
            MMAgentReadSucceeded = $true
            RegistryReadSucceeded = $true
            EnablePrefetcher = 0
            ApplicationLaunchPrefetching = $false
            ApplicationPreLaunch = $false
            MaxOperationAPIFiles = 1
            MemoryCompression = $false
            OperationAPI = $false
            PageCombining = $false
            Warnings = @()
            Message = 'Mocked Apply state.'
        }
    }
    $applyPrefetchStillDefaultStateReader = {
        [pscustomobject]@{
            ReadSucceeded = $true
            MMAgentReadSucceeded = $true
            RegistryReadSucceeded = $true
            EnablePrefetcher = 3
            ApplicationLaunchPrefetching = $false
            ApplicationPreLaunch = $false
            MaxOperationAPIFiles = 1
            MemoryCompression = $false
            OperationAPI = $false
            PageCombining = $false
            Warnings = @()
            Message = 'Mocked Apply state with prefetcher unchanged.'
        }
    }

    $emptyRegistryFailureInvoker = {
        param($Value)
        [pscustomobject]@{ Success = $false; Output = ''; Reason = ''; Command = 'mock reg add'; Expected = $Value }
    }
    $successfulMMAgentInvoker = {
        param($Operation)
        [pscustomobject]@{
            Success = $true
            Classification = 'Changed'
            Reason = "$($Operation.Type) $($Operation.Name) mocked complete."
            Command = "$($Operation.Type) $($Operation.Name)"
        }
    }
    $registryFailureResult = & $module {
        param($CommandResolver, $RegistryInvoker, $MMAgentCommandInvoker, $StateReader)
        Invoke-BoostLabMMAgentAssistantAction `
            -ActionName 'Apply' `
            -AdministratorChecker { return $true } `
            -CommandResolver $CommandResolver `
            -RegistryInvoker $RegistryInvoker `
            -MMAgentCommandInvoker $MMAgentCommandInvoker `
            -StateReader $StateReader
    } $scalarCommandResolver $emptyRegistryFailureInvoker $successfulMMAgentInvoker $applyPrefetchStillDefaultStateReader
    if (
        $registryFailureResult.Success -or
        $registryFailureResult.Data.CommandStatus -ne 'Completed with warnings' -or
        $registryFailureResult.VerificationResult.Status -ne 'Failed' -or
        (@($registryFailureResult.Data.Warnings) -join ' ') -notmatch 'EnablePrefetcher write failed: EnablePrefetcher registry write returned no diagnostic text' -or
        [string]::IsNullOrWhiteSpace([string]$registryFailureResult.Data.OperationResults[0].Reason)
    ) {
        throw 'MMAgent Assistant did not report a non-empty EnablePrefetcher write failure reason.'
    }

    $mixedWarningInvoker = {
        param($Operation)
        if ([string]$Operation.Name -eq 'ApplicationPreLaunch') {
            return [pscustomobject]@{
                Success = $true
                Classification = 'HostOutputSuppressed'
                Reason = 'EndProcessing pipe/console error.'
                Command = "$($Operation.Type) $($Operation.Name)"
            }
        }
        if ([string]$Operation.Name -eq 'OperationAPI') {
            return [pscustomobject]@{
                Success = $true
                Classification = 'Unsupported'
                Reason = 'The request is not supported.'
                Command = "$($Operation.Type) $($Operation.Name)"
            }
        }
        [pscustomobject]@{
            Success = $true
            Classification = 'Changed'
            Reason = "$($Operation.Type) $($Operation.Name) mocked complete."
            Command = "$($Operation.Type) $($Operation.Name)"
        }
    }
    $warningRegistryInvoker = {
        param($Value)
        [pscustomobject]@{ Success = $true; Output = 'Registry write complete.'; Reason = 'Registry write complete.'; Command = 'mock reg add'; Expected = $Value }
    }
    $warningResult = & $module {
        param($CommandResolver, $RegistryInvoker, $MMAgentCommandInvoker, $StateReader)
        Invoke-BoostLabMMAgentAssistantAction `
            -ActionName 'Apply' `
            -AdministratorChecker { return $true } `
            -CommandResolver $CommandResolver `
            -RegistryInvoker $RegistryInvoker `
            -MMAgentCommandInvoker $MMAgentCommandInvoker `
            -StateReader $StateReader
    } $scalarCommandResolver $warningRegistryInvoker $mixedWarningInvoker $applyPassedStateReader
    if (
        -not $warningResult.Success -or
        $warningResult.Data.CommandStatus -ne 'Completed with warnings' -or
        $warningResult.VerificationResult.Status -ne 'Passed' -or
        (@($warningResult.Data.Warnings) -join ' ') -notmatch 'HostOutputSuppressed' -or
        (@($warningResult.Data.Warnings) -join ' ') -notmatch 'Unsupported'
    ) {
        throw 'MMAgent Assistant did not classify host pipe and unsupported feature results as source-equivalent warnings.'
    }

    $realFailureInvoker = {
        param($Operation)
        if ([string]$Operation.Name -eq 'MemoryCompression') {
            return [pscustomobject]@{
                Success = $false
                Classification = 'Failed'
                Reason = 'MMAgent subsystem failed.'
                Command = "$($Operation.Type) $($Operation.Name)"
            }
        }
        [pscustomobject]@{
            Success = $true
            Classification = 'Changed'
            Reason = "$($Operation.Type) $($Operation.Name) mocked complete."
            Command = "$($Operation.Type) $($Operation.Name)"
        }
    }
    $realFailureResult = & $module {
        param($CommandResolver, $RegistryInvoker, $MMAgentCommandInvoker, $StateReader)
        Invoke-BoostLabMMAgentAssistantAction `
            -ActionName 'Apply' `
            -AdministratorChecker { return $true } `
            -CommandResolver $CommandResolver `
            -RegistryInvoker $RegistryInvoker `
            -MMAgentCommandInvoker $MMAgentCommandInvoker `
            -StateReader $StateReader
    } $scalarCommandResolver $warningRegistryInvoker $realFailureInvoker $applyPassedStateReader
    if (
        $realFailureResult.Success -or
        $realFailureResult.Data.CommandStatus -ne 'Failed' -or
        (@($realFailureResult.Data.Errors) -join ' ') -notmatch 'MemoryCompression failed: MMAgent subsystem failed.'
    ) {
        throw 'MMAgent Assistant did not preserve a real MMAgent command failure.'
    }

    $hostPipeState = & $module {
        param($CommandResolver)
        Get-BoostLabMMAgentAssistantState `
            -CommandResolver $CommandResolver `
            -MMAgentReader { throw 'EndProcessing pipe/console error.' } `
            -RegistryReader {
                param($Path, $Name)
                [pscustomobject]@{ EnablePrefetcher = 0 }
            }
    } $scalarCommandResolver
    if (
        -not $hostPipeState.ReadSucceeded -or
        $hostPipeState.MMAgentReadSucceeded -or
        -not $hostPipeState.RegistryReadSucceeded -or
        (@($hostPipeState.Warnings) -join ' ') -notmatch 'host output channel failed'
    ) {
        throw 'MMAgent Assistant did not convert Get-MMAgent host pipe failure into clear NotAvailable diagnostics.'
    }

    $prefetchFailureVerification = & $module {
        param($StateReader)
        Test-BoostLabMMAgentAssistantState -ActionName 'Apply' -StateReader $StateReader
    } $applyPrefetchStillDefaultStateReader
    if (
        $prefetchFailureVerification.Status -ne 'Failed' -or
        [int]$prefetchFailureVerification.DetectedState.EnablePrefetcher -ne 3
    ) {
        throw 'MMAgent Assistant verification did not fail clearly when EnablePrefetcher remained 3.'
    }
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    foreach ($actionName in @('Apply', 'Default')) {
        $plan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName $actionName -IsDryRun $false
        if (
            -not $plan.NeedsExplicitConfirmation -or
            -not $plan.RequiresAdmin -or
            $plan.CanReboot -or
            $plan.ConfirmationMessage -notmatch 'No restart is performed'
        ) {
            throw "MMAgent Assistant $actionName action plan is incorrect."
        }
    }
    $defaultPlan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Default' -IsDryRun $false
    if (
        (@($defaultPlan.PlannedChanges) -join ' ') -notmatch 'MemoryCompression' -or
        (@($defaultPlan.PlannedChanges) -join ' ') -notmatch 'PageCombining' -or
        [string]$defaultPlan.Summary -match '\b[Rr]estore\b' -or
        [string]$defaultPlan.ConfirmationMessage -match '\b[Rr]estore\b'
    ) {
        throw 'MMAgent Assistant Default action plan does not preserve the source-defined disabled features.'
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredText in @(
    '''mmagent-assistant'' = @{'
    '''Advanced\mmagent-assistant.psm1'''
    'Actions = @(''Analyze'', ''Apply'', ''Default'')'
)) {
    if (-not $executionSource.Contains($requiredText)) {
        throw "MMAgent Assistant runtime mapping is missing: $requiredText"
    }
}

$record = Get-Content -Raw -LiteralPath $recordPath
foreach ($requiredText in @(
    'source-ultimate/8 Advanced/2 MMAgent Assistant.ps1'
    'C7E6E7879B7B32E548607A5D30124CC327622E09E7BEF817D36E8BC095B64A79'
    'MemoryCompression remains disabled in `Default`.'
    'PageCombining remains disabled in `Default`.'
    'Automated tests must be static or mocked only and must not change the real MMAgent state.'
)) {
    if (-not $record.Contains($requiredText)) {
        throw "MMAgent Assistant migration record is missing: $requiredText"
    }
}

$allModules = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'modules') -Recurse -File -Filter '*.psm1' |
        Where-Object { $_.Directory.Parent.FullName -eq (Join-Path $ProjectRoot 'modules') }
)
$implementedCount = @(
    $allModules | Where-Object {
        (Get-Content -Raw -LiteralPath $_.FullName).Contains('$script:BoostLabImplementedActions')
    }
).Count
$placeholderCount = @(
    $allModules | Where-Object {
        (Get-Content -Raw -LiteralPath $_.FullName).Contains('ToolModule.Placeholder.ps1')
    }
).Count
if ($implementedCount -ne $inventoryBaseline.ImplementedTools -or $placeholderCount -ne $inventoryBaseline.DeferredPlaceholders) {
    throw "Unexpected module counts: $implementedCount implemented, $placeholderCount placeholders."
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
    Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
    ForEach-Object {
        '{0}|{1}' -f `
            $_.FullName.Substring($root.Length + 1).Replace('\', '/'), `
            (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    }
$sha256 = [System.Security.Cryptography.SHA256]::Create()
try {
    $sourceManifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n")))
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}
if (
    @($sourceLines).Count -ne 49 -or
    $sourceManifestHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477'
) {
    throw 'source-ultimate content or paths changed.'
}

[pscustomobject]@{
    Success                 = $true
    ToolId                  = 'mmagent-assistant'
    ImplementedActions      = @('Analyze', 'Apply', 'Default')
    MockedApplyPassed       = $true
    MockedDefaultPassed     = $true
    ImplementedModuleCount  = $implementedCount
    PlaceholderModuleCount  = $placeholderCount
    SourceUltimateUnchanged = $true
    Message                 = 'MMAgent Assistant behavior and mocked verification were validated without changing the real MMAgent state.'
    Timestamp               = Get-Date
}



