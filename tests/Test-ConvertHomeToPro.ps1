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
        throw 'Unable to determine the Convert Home To Pro validator path.'
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
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [string]$Needle,

        [Parameter(Mandatory)]
        [string]$Description
    )

    Assert-BoostLabCondition ($Text.Contains($Needle)) "$Description is missing expected text: $Needle"
}

$sourcePath = Join-Path $ProjectRoot 'source-extra\forgotten-scripts\3 Convert Home To Pro.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Setup\convert-home-to-pro.psm1'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$artifactProvenancePath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$externalSourcesPath = Join-Path $ProjectRoot 'config\ExternalArtifactSources.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'

foreach ($path in @($sourcePath, $modulePath, $stagesPath, $executionPath, $actionPlanPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required Convert Home To Pro file is missing: $path"
}

$expectedSourceSha = '3B779A75960FB724A2F5FF756FCEDD1CF6897D0021FD6DBE1D671189CBA57924'
$sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
Assert-BoostLabCondition ($sourceHash -eq $expectedSourceSha) "Convert Home To Pro source-extra checksum mismatch. Expected $expectedSourceSha, found $sourceHash."

$sourceText = Get-Content -Raw -LiteralPath $sourcePath
foreach ($requiredSourceText in @(
    'Set-Clipboard -Value "VK7JG-NPHTM-C97JM-9MPGT-3V66T"',
    'Start-Process ms-settings:activation',
    '& "$env:windir\System32\SystemSettingsAdminFlows.exe" ''EnterProductKey''',
    'Disable Internet First'
)) {
    Assert-BoostLabTextContains -Text $sourceText -Needle $requiredSourceText -Description 'Yazan-provided source-extra script'
}
foreach ($forbiddenSourceText in @(
    'kms',
    'crack',
    'slmgr',
    'changepk',
    'dism',
    'Invoke-WebRequest',
    'Invoke-RestMethod',
    'Start-BitsTransfer'
)) {
    Assert-BoostLabCondition (-not $sourceText.ToLowerInvariant().Contains($forbiddenSourceText.ToLowerInvariant())) "Convert Home To Pro source-extra includes forbidden activation/download behavior: $forbiddenSourceText"
}

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$setupStage = @($stages.Stages | Where-Object { [string]$_.Name -eq 'Setup' })[0]
$setupTools = @($setupStage.Tools)
$convertTool = @($setupTools | Where-Object { [string]$_.Id -eq 'convert-home-to-pro' })[0]
Assert-BoostLabCondition ($null -ne $convertTool) 'Convert Home To Pro stage metadata is missing.'
Assert-BoostLabCondition ([int]$convertTool.Order -eq 2) 'Convert Home To Pro must be immediately after BitLocker in Setup order.'
Assert-BoostLabCondition ([string]$setupTools[0].Id -eq 'bitlocker') 'BitLocker must remain first in Setup.'
Assert-BoostLabCondition ([string]$setupTools[1].Id -eq 'convert-home-to-pro') 'Convert Home To Pro must be second in Setup.'
Assert-BoostLabCondition ((@($convertTool.Actions) -join ',') -eq 'Apply') 'Convert Home To Pro must expose only Apply.'
Assert-BoostLabCondition ([string]$convertTool.SourceType -eq 'YazanProvidedForgottenScript') 'Convert Home To Pro must record the source-extra source type.'

$capabilities = $convertTool.Capabilities
foreach ($field in $capabilities.Keys) {
    $expected = $field -in @('RequiresAdmin', 'CanModifySecurity', 'NeedsExplicitConfirmation')
    Assert-BoostLabCondition ([bool]$capabilities[$field] -eq $expected) "Convert Home To Pro capability '$field' is incorrect."
}

$moduleText = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredModuleText in @(
    '$script:BoostLabImplementedActions = @(''Apply'')',
    '$script:BoostLabSourceRelativePath = ''source-extra/forgotten-scripts/3 Convert Home To Pro.ps1''',
    '$script:BoostLabExpectedSourceHash = ''3B779A75960FB724A2F5FF756FCEDD1CF6897D0021FD6DBE1D671189CBA57924''',
    '$script:BoostLabExpectedCanonicalSourceHash = ''3B779A75960FB724A2F5FF756FCEDD1CF6897D0021FD6DBE1D671189CBA57924''',
    'Test-BoostLabSourceChecksum',
    'Set-Clipboard -Value $Value -ErrorAction Stop',
    'Start-Process ''ms-settings:activation'' -ErrorAction Stop',
    '& $flowPath ''EnterProductKey''',
    'function New-BoostLabConvertHomeToProKeyDialog',
    'Disable Internet First',
    'Enter: {0} (Or Paste From Clipboard)',
    'CopyFriendlyText',
    'DialogPresenter',
    'YazanProvidedForgottenScript',
    'valid Windows Pro license is required',
    'digital entitlement'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $requiredModuleText -Description 'Convert Home To Pro module'
}
foreach ($forbiddenModuleText in @(
    'Invoke-WebRequest',
    'Invoke-RestMethod',
    'Start-BitsTransfer',
    'Restart-Computer',
    'Stop-Computer',
    'Set-ItemProperty',
    'New-ItemProperty',
    'Remove-ItemProperty',
    'Remove-Item',
    'Disable-BitLocker',
    'bcdedit'
)) {
    Assert-BoostLabCondition (-not $moduleText.ToLowerInvariant().Contains($forbiddenModuleText.ToLowerInvariant())) "Convert Home To Pro module includes forbidden behavior: $forbiddenModuleText"
}

$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($modulePath, [ref]$tokens, [ref]$parseErrors)
if (@($parseErrors).Count -gt 0) {
    throw "Convert Home To Pro module syntax error: $($parseErrors[0].Message)"
}
$commands = @(
    $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
        $true
    ) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }
)
Assert-BoostLabCondition (@($commands | Where-Object { $_ -eq 'Set-Clipboard' }).Count -eq 1) 'Convert Home To Pro must contain exactly one Set-Clipboard command.'
Assert-BoostLabCondition (@($commands | Where-Object { $_ -eq 'Start-Process' }).Count -eq 1) 'Convert Home To Pro must contain exactly one Start-Process command.'
foreach ($forbiddenCommand in @('changepk', 'slmgr', 'dism', 'Invoke-WebRequest', 'Invoke-RestMethod', 'Start-BitsTransfer')) {
    Assert-BoostLabCondition ($forbiddenCommand -notin @($commands)) "Convert Home To Pro module contains forbidden executable command: $forbiddenCommand"
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -DisableNameChecking -ErrorAction Stop
try {
    $plan = New-BoostLabActionPlan -ToolMetadata $convertTool -ActionName 'Apply'
    Assert-BoostLabCondition ([bool]$plan.RequiresAdmin) 'Convert Home To Pro Action Plan must require Administrator.'
    Assert-BoostLabCondition ([bool]$plan.NeedsExplicitConfirmation) 'Convert Home To Pro Action Plan must require explicit confirmation.'
    $planText = (@($plan.PlannedChanges) + @($plan.SideEffects) + @($plan.ConfirmationMessage)) -join ' '
    foreach ($requiredPlanText in @(
        'Disable Internet First',
        'generic Windows Pro setup key',
        'VK7JG-NPHTM-C97JM-9MPGT-3V66T',
        'ms-settings:activation',
        'SystemSettingsAdminFlows.exe EnterProductKey',
        'valid Windows Pro license or digital entitlement',
        'No changepk, slmgr, DISM, KMS, crack, activation bypass'
    )) {
        Assert-BoostLabTextContains -Text $planText -Needle $requiredPlanText -Description 'Convert Home To Pro Action Plan'
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$module = Import-Module -Name $modulePath -Force -PassThru -Prefix 'ConvertTest' -Scope Local -DisableNameChecking -ErrorAction Stop
try {
    $info = Get-ConvertTestBoostLabToolInfo
    Assert-BoostLabCondition ([string]$info.Id -eq 'convert-home-to-pro') 'Convert Home To Pro module reported the wrong id.'
    Assert-BoostLabCondition ((@($info.Actions) -join ',') -eq 'Apply') 'Convert Home To Pro module must expose only Apply.'
    Assert-BoostLabCondition ([string]$info.SourceType -eq 'YazanProvidedForgottenScript') 'Convert Home To Pro module reported the wrong source type.'

    $sourceStatus = Get-ConvertTestBoostLabConvertHomeToProSourceStatus
    Assert-BoostLabCondition ([string]$sourceStatus.ChecksumStatus -eq 'Passed') 'Convert Home To Pro source verification must pass.'
    Assert-BoostLabCondition ([string]$sourceStatus.SourceType -eq 'YazanProvidedForgottenScript') 'Convert Home To Pro source status must report source-extra type.'

    $events = [System.Collections.ArrayList]::new()
    $clipboardWriter = {
        param($Value)
        [void]$events.Add("Clipboard:$Value")
        [pscustomobject]@{ Success = $true; CommandStatus = 'Completed'; Message = 'Mock clipboard write completed.' }
    }
    $settingsLauncher = {
        [void]$events.Add('Settings:ms-settings:activation')
        [pscustomobject]@{ Success = $true; CommandStatus = 'Completed'; Message = 'Mock Activation Settings launch completed.' }
    }
    $productKeyFlowLauncher = {
        [void]$events.Add('ProductKeyFlow:EnterProductKey')
        [pscustomobject]@{ Success = $true; CommandStatus = 'Completed'; Message = 'Mock product-key flow launch completed.' }
    }
    $dialogPresenter = {
        param($Dialog)
        [void]$events.Add(('Dialog:{0}:{1}' -f [string]$Dialog.GenericProSetupKey, (@($Dialog.SourceInstructions) -join ';')))
        [pscustomobject]@{ Success = $true; CommandStatus = 'Completed'; Message = 'Mock Convert Home To Pro key dialog prepared.' }
    }

    $cancelled = Invoke-ConvertTestBoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$false `
        -AdministratorDetector { $true } `
        -ClipboardWriter $clipboardWriter `
        -SettingsLauncher $settingsLauncher `
        -ProductKeyFlowLauncher $productKeyFlowLauncher `
        -DialogPresenter $dialogPresenter
    Assert-BoostLabCondition (-not [bool]$cancelled.Success) 'Unconfirmed Convert Home To Pro Apply must not succeed.'
    Assert-BoostLabCondition ([string]$cancelled.Status -eq 'Cancelled') 'Unconfirmed Convert Home To Pro Apply must return Cancelled.'
    Assert-BoostLabCondition ($events.Count -eq 0) 'Unconfirmed Convert Home To Pro Apply must run no mocked operations.'

    $needsAdmin = Invoke-ConvertTestBoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -AdministratorDetector { $false } `
        -ClipboardWriter $clipboardWriter `
        -SettingsLauncher $settingsLauncher `
        -ProductKeyFlowLauncher $productKeyFlowLauncher `
        -DialogPresenter $dialogPresenter
    Assert-BoostLabCondition (-not [bool]$needsAdmin.Success) 'Non-admin Convert Home To Pro Apply must not succeed.'
    Assert-BoostLabCondition ([string]$needsAdmin.Status -eq 'NeedsAdministrator') 'Non-admin Convert Home To Pro Apply must return NeedsAdministrator.'
    Assert-BoostLabCondition ($events.Count -eq 0) 'Non-admin Convert Home To Pro Apply must run no mocked operations.'

    $result = Invoke-ConvertTestBoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -AdministratorDetector { $true } `
        -ClipboardWriter $clipboardWriter `
        -SettingsLauncher $settingsLauncher `
        -ProductKeyFlowLauncher $productKeyFlowLauncher `
        -DialogPresenter $dialogPresenter
    Assert-BoostLabCondition ([bool]$result.Success) "Mocked Convert Home To Pro Apply failed: $($result.Message)"
    Assert-BoostLabCondition ([string]$result.Status -eq 'Completed') 'Mocked Convert Home To Pro Apply must return Completed.'
    Assert-BoostLabCondition ([string]$result.VerificationResult.Status -eq 'Passed') 'Mocked Convert Home To Pro verification must pass.'
    Assert-BoostLabCondition ([bool]$result.Data.RequiresValidProLicense) 'Convert Home To Pro result must state that a valid Pro license is required.'
    Assert-BoostLabCondition ($null -ne $result.Data.UserDialog) 'Convert Home To Pro Apply must include a user-facing key dialog payload.'
    Assert-BoostLabCondition ([string]$result.Data.UserDialog.GenericProSetupKey -eq 'VK7JG-NPHTM-C97JM-9MPGT-3V66T') 'Convert Home To Pro dialog must include the generic Pro setup key.'
    Assert-BoostLabCondition ([string]$result.Data.UserDialog.CopyFriendlyText -eq 'VK7JG-NPHTM-C97JM-9MPGT-3V66T') 'Convert Home To Pro dialog must expose copy-friendly key text.'
    Assert-BoostLabCondition ([bool]$result.Data.UserDialog.ClipboardPrepopulated) 'Convert Home To Pro dialog must state the clipboard is prepopulated.'
    Assert-BoostLabCondition ([bool]$result.Data.UserDialog.RequiresValidProLicense) 'Convert Home To Pro dialog must state that a valid Pro license is required.'
    Assert-BoostLabCondition ([bool]$result.Data.UserDialog.DigitalEntitlementApplies) 'Convert Home To Pro dialog must state that digital entitlement may apply.'
    Assert-BoostLabTextContains -Text ([string]$result.Message) -Needle 'Disable Internet first' -Description 'Convert Home To Pro result message'
    Assert-BoostLabTextContains -Text ([string]$result.Message) -Needle 'VK7JG-NPHTM-C97JM-9MPGT-3V66T' -Description 'Convert Home To Pro result message'
    Assert-BoostLabTextContains -Text ([string]$result.Data.UserDialog.LegalBoundary) -Needle 'valid Windows Pro license or digital entitlement' -Description 'Convert Home To Pro dialog legal boundary'
    Assert-BoostLabCondition ((@($result.Data.UserDialog.SourceInstructions) -join '|') -eq 'Disable Internet First|Enter: VK7JG-NPHTM-C97JM-9MPGT-3V66T (Or Paste From Clipboard)') 'Convert Home To Pro dialog must mirror the source instructions exactly.'
    Assert-BoostLabCondition ([bool]$result.Data.DialogAttempted) 'Convert Home To Pro Apply must attempt the user-facing key dialog before clipboard/settings flow.'
    Assert-BoostLabCondition (($events -join '|') -eq 'Dialog:VK7JG-NPHTM-C97JM-9MPGT-3V66T:Disable Internet First;Enter: VK7JG-NPHTM-C97JM-9MPGT-3V66T (Or Paste From Clipboard)|Clipboard:VK7JG-NPHTM-C97JM-9MPGT-3V66T|Settings:ms-settings:activation|ProductKeyFlow:EnterProductKey') 'Mocked Convert Home To Pro Apply did not preserve source instruction, clipboard, settings, and product-key operation order.'
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
}

$executionText = Get-Content -Raw -LiteralPath $executionPath
Assert-BoostLabTextContains -Text $executionText -Needle "'convert-home-to-pro' = @{" -Description 'Execution routing'
Assert-BoostLabTextContains -Text $executionText -Needle "Setup\convert-home-to-pro.psm1" -Description 'Execution routing'
Assert-BoostLabTextContains -Text $executionText -Needle "Actions = @('Apply')" -Description 'Execution routing'

$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$convertRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'convert-home-to-pro' })[0]
Assert-BoostLabCondition ($null -ne $convertRecord) 'Convert Home To Pro parity/status record is missing.'
Assert-BoostLabCondition ([string]$convertRecord.SourceType -eq 'YazanProvidedForgottenScript') 'Convert Home To Pro parity/status record must identify source-extra type.'
Assert-BoostLabCondition ([string]$convertRecord.RuntimeStatus -eq 'RuntimeImplemented') 'Convert Home To Pro must be runtime implemented.'
Assert-BoostLabCondition ([string]$convertRecord.ImplementationLevel -eq 'ParityImplemented') 'Convert Home To Pro must be implemented to its Yazan-provided source behavior.'
Assert-BoostLabCondition ([int]$convertRecord.ToolOrder -eq 2) 'Convert Home To Pro parity/status order must be immediately after BitLocker.'
Assert-BoostLabCondition ([bool]$parityBaseline.OrderedParityComplete) 'Ordered parity must remain complete after importing source-extra Convert Home To Pro.'
Assert-BoostLabCondition ($null -eq $parityBaseline.CurrentOrderedParityTarget) 'Current ordered parity target must remain null.'

$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$setupOrder = @($executionOrder.Stages | Where-Object { [string]$_.Name -eq 'Setup' })[0]
Assert-BoostLabCondition ([string]@($setupOrder.Tools)[1].ToolId -eq 'convert-home-to-pro') 'Convert Home To Pro must be second in the ordered Setup list.'

$inventoryAssertion = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
Assert-BoostLabCondition ([int]$inventoryAssertion.Snapshot.ActiveTools -eq [int]$inventoryAssertion.Baseline.ActiveTools) 'Active tool baseline must match live inventory.'
Assert-BoostLabCondition ([int]$inventoryAssertion.Snapshot.ImplementedTools -eq [int]$inventoryAssertion.Baseline.ImplementedTools) 'Implemented tool baseline must match live inventory.'
Assert-BoostLabCondition ([int]$inventoryAssertion.Snapshot.DeferredPlaceholders -eq 0) 'Deferred placeholder count must remain zero.'

foreach ($path in @($artifactProvenancePath, $externalSourcesPath, $productionAllowlistPath)) {
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        $text = Get-Content -Raw -LiteralPath $path
        Assert-BoostLabCondition (-not $text.Contains('convert-home-to-pro')) "Convert Home To Pro must not add artifact/provenance/allowlist entries: $path"
    }
}

$sourceUltimateRoot = Join-Path $ProjectRoot 'source-ultimate'
Assert-BoostLabCondition (Test-Path -LiteralPath $sourceUltimateRoot -PathType Container) 'source-ultimate directory must remain present.'
Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourceUltimateRoot -Recurse -File | Where-Object { $_.Name -like '*Loudness EQ*' -or $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }).Count -eq 0) 'Deleted tools must not be reintroduced.'

[pscustomobject]@{
    Test = 'ConvertHomeToPro'
    ToolId = 'convert-home-to-pro'
    SourceSha256 = $expectedSourceSha
    SourceType = 'YazanProvidedForgottenScript'
    Actions = 'Apply'
    ActiveTools = $inventoryAssertion.Snapshot.ActiveTools
    ImplementedTools = $inventoryAssertion.Snapshot.ImplementedTools
    DeferredPlaceholders = $inventoryAssertion.Snapshot.DeferredPlaceholders
    OrderedParityComplete = [bool]$parityBaseline.OrderedParityComplete
    Message = 'Convert Home To Pro source-extra Apply-only import passed mocked validation.'
    Timestamp = Get-Date
}
