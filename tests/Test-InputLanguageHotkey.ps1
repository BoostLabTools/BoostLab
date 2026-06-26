[CmdletBinding()]
param(
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'BoostLab.Hashing.ps1')
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $scriptPath = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $PSCommandPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $MyInvocation.MyCommand.Path
    }
    else {
        throw 'Unable to determine the Input Language Hotkey validator path.'
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

function New-MockInputLanguageHotkeyReader {
    param(
        [Parameter(Mandatory)]
        [hashtable]$State,

        [string]$ValueKind = 'String'
    )

    return {
        param($Path, $Name)

        if ($State.ContainsKey($Name)) {
            return [pscustomobject]@{
                ReadSucceeded = $true
                KeyExists     = $true
                Exists        = $true
                Value         = [string]$State[$Name]
                ValueKind     = $ValueKind
                DisplayValue  = [string]$State[$Name]
                Message       = 'Mock registry value detected.'
            }
        }

        [pscustomobject]@{
            ReadSucceeded = $true
            KeyExists     = $true
            Exists        = $false
            Value         = $null
            ValueKind     = ''
            DisplayValue  = 'Absent'
            Message       = 'Mock registry value is absent.'
        }
    }.GetNewClosure()
}

$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\input-language-hotkey.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$ultimateOrderPath = Join-Path $ProjectRoot 'config\UltimateParityExecutionOrder.psd1'
$artifactProvenancePath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$externalSourcesPath = Join-Path $ProjectRoot 'config\ExternalArtifactSources.psd1'
$productionAllowlistPath = Join-Path $ProjectRoot 'config\ProductionAllowlistGovernance.psd1'

foreach ($path in @($stagesPath, $modulePath, $executionPath, $actionPlanPath, $ultimateOrderPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required Input Language Hotkey file is missing: $path"
}

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$windowsStage = @($stages.Stages | Where-Object { [string]$_.Name -eq 'Windows' })[0]
$setupStage = @($stages.Stages | Where-Object { [string]$_.Name -eq 'Setup' })[0]
$tool = @($windowsStage.Tools | Where-Object { [string]$_.Id -eq 'input-language-hotkey' })[0]
$controlPanelTool = @($windowsStage.Tools | Where-Object { [string]$_.Id -eq 'control-panel-settings' })[0]
$soundTool = @($windowsStage.Tools | Where-Object { [string]$_.Id -eq 'sound' })[0]

Assert-BoostLabCondition ($null -ne $tool) 'Input Language Hotkey must be present in the Windows stage.'
Assert-BoostLabCondition (@($setupStage.Tools | Where-Object { [string]$_.Id -eq 'input-language-hotkey' }).Count -eq 0) 'Input Language Hotkey must not be in the Setup stage.'
Assert-BoostLabCondition ([int]$controlPanelTool.Order -eq 15) 'Control Panel Settings must remain Windows order 15.'
Assert-BoostLabCondition ([int]$tool.Order -eq 16) 'Input Language Hotkey must be immediately after Control Panel Settings.'
Assert-BoostLabCondition ([int]$soundTool.Order -eq 17) 'Sound must remain immediately after Input Language Hotkey.'
Assert-BoostLabCondition ((@($tool.Actions) -join ',') -eq 'Apply') 'Input Language Hotkey must expose only Apply.'
Assert-BoostLabCondition ([string]$tool.SourceType -eq 'BoostLabSpecificUserApproved') 'Input Language Hotkey source type must be BoostLab-specific and user approved.'
Assert-BoostLabCondition ([string]$tool.RiskLevel -eq 'low') 'Input Language Hotkey risk level must be low.'

$capabilities = $tool.Capabilities
foreach ($field in $capabilities.Keys) {
    $expected = $field -in @('CanModifyRegistry', 'NeedsExplicitConfirmation')
    Assert-BoostLabCondition ([bool]$capabilities[$field] -eq $expected) "Input Language Hotkey capability '$field' is incorrect."
}

$moduleText = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredModuleText in @(
    '$script:BoostLabImplementedActions = @(''Apply'')',
    '$script:BoostLabRegistryProviderPath = ''HKCU:\Keyboard Layout\Toggle''',
    '$script:BoostLabRegistryRelativePath = ''Keyboard Layout\Toggle''',
    '''Hotkey'' = ''1''',
    '''Language Hotkey'' = ''1''',
    '''Layout Hotkey'' = ''3''',
    '[Microsoft.Win32.Registry]::CurrentUser',
    'CreateSubKey($script:BoostLabRegistryRelativePath)',
    '$key.SetValue($Name, [string]$Value, [Microsoft.Win32.RegistryValueKind]::String)',
    'UiAutomationUsed = $false',
    'HkcuOnly = $true',
    'HklmMutation = $false'
)) {
    Assert-BoostLabTextContains -Text $moduleText -Needle $requiredModuleText -Description 'Input Language Hotkey module'
}

foreach ($forbiddenModuleText in @(
    'SendKeys',
    'System.Windows.Automation',
    'UIAutomationClient',
    'Set-WinUserLanguageList',
    'Set-Culture',
    'Set-WinUILanguageOverride',
    'Start-Process',
    'rundll32.exe',
    'Control_RunDLL',
    'input.dll',
    'control.exe',
    'Text Services',
    'HKLM:\',
    'HKEY_LOCAL_MACHINE',
    'Set-ItemProperty',
    'New-ItemProperty',
    'Remove-ItemProperty',
    'reg.exe',
    'shutdown',
    'Restart-Computer'
)) {
    Assert-BoostLabCondition (-not $moduleText.ToLowerInvariant().Contains($forbiddenModuleText.ToLowerInvariant())) "Input Language Hotkey module includes forbidden behavior: $forbiddenModuleText"
}

$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($modulePath, [ref]$tokens, [ref]$parseErrors)
if (@($parseErrors).Count -gt 0) {
    throw "Input Language Hotkey module syntax error: $($parseErrors[0].Message)"
}
$commands = @(
    $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
        $true
    ) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }
)
Assert-BoostLabCondition (@($commands | Where-Object { $_ -eq 'Start-Process' }).Count -eq 0) 'Input Language Hotkey must not contain Start-Process.'
foreach ($forbiddenCommand in @('Start-Process', 'Set-ItemProperty', 'New-ItemProperty', 'Remove-ItemProperty', 'reg.exe', 'Set-WinUserLanguageList', 'Restart-Computer')) {
    Assert-BoostLabCondition ($forbiddenCommand -notin @($commands)) "Input Language Hotkey module contains forbidden command: $forbiddenCommand"
}

$executionText = Get-Content -Raw -LiteralPath $executionPath
Assert-BoostLabTextContains -Text $executionText -Needle "'input-language-hotkey' = @{" -Description 'Execution registry'
Assert-BoostLabTextContains -Text $executionText -Needle "Windows\input-language-hotkey.psm1" -Description 'Execution registry'
Assert-BoostLabTextContains -Text $executionText -Needle "Actions = @('Apply')" -Description 'Execution registry'

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -DisableNameChecking -ErrorAction Stop
try {
    $plan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Apply'
    Assert-BoostLabCondition (-not [bool]$plan.RequiresAdmin) 'Input Language Hotkey must not require Administrator.'
    Assert-BoostLabCondition ([bool]$plan.NeedsExplicitConfirmation) 'Input Language Hotkey must require explicit confirmation.'
    Assert-BoostLabCondition (-not [bool]$plan.RequiresInternet) 'Input Language Hotkey must not require internet.'
    Assert-BoostLabCondition (-not [bool]$plan.CanReboot) 'Input Language Hotkey must not be able to reboot.'
    Assert-BoostLabCondition (-not [bool]$plan.SupportsDefault) 'Input Language Hotkey must not support Default.'
    Assert-BoostLabCondition (-not [bool]$plan.SupportsRestore) 'Input Language Hotkey must not support Restore.'
    $planText = (@($plan.Summary) + @($plan.PlannedChanges) + @($plan.SideEffects) + @($plan.ConfirmationMessage)) -join ' '
    foreach ($requiredPlanText in @(
        'Left Alt + Shift',
        'Not Assigned',
        'HKCU:\Keyboard Layout\Toggle',
        'Hotkey',
        'Language Hotkey',
        'Layout Hotkey',
        'will not open Text Services',
        'Control Panel',
        'Settings',
        'replacement window',
        'no UI automation',
        'No HKLM'
    )) {
        Assert-BoostLabTextContains -Text $planText -Needle $requiredPlanText -Description 'Input Language Hotkey Action Plan'
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$module = Import-Module -Name $modulePath -Force -PassThru -Prefix 'InputHotkeyTest' -Scope Local -DisableNameChecking -ErrorAction Stop
try {
    $info = Get-InputHotkeyTestBoostLabToolInfo
    Assert-BoostLabCondition ([string]$info.Id -eq 'input-language-hotkey') 'Input Language Hotkey module reported the wrong id.'
    Assert-BoostLabCondition ([string]$info.Stage -eq 'Windows') 'Input Language Hotkey module must report Windows stage.'
    Assert-BoostLabCondition ([int]$info.Order -eq 16) 'Input Language Hotkey module must report order 16.'
    Assert-BoostLabCondition ((@($info.Actions) -join ',') -eq 'Apply') 'Input Language Hotkey module must expose only Apply.'
    Assert-BoostLabCondition ([string]$info.SourceType -eq 'BoostLabSpecificUserApproved') 'Input Language Hotkey module reported wrong source type.'

    $compatibility = Test-InputHotkeyTestBoostLabToolCompatibility -OperatingSystem 'Windows_NT'
    Assert-BoostLabCondition ([bool]$compatibility.Supported) 'Input Language Hotkey compatibility must support Windows_NT.'

    $registryState = @{}
    $writeCalls = [System.Collections.ArrayList]::new()
    $writer = {
        param($Path, $Name, $Value)
        [void]$writeCalls.Add([pscustomobject]@{ Path = $Path; Name = $Name; Value = $Value })
        $registryState[$Name] = [string]$Value
        [pscustomobject]@{ Success = $true; Message = "Mock set $Name." }
    }.GetNewClosure()
    $reader = New-MockInputLanguageHotkeyReader -State $registryState

    $result = Invoke-InputHotkeyTestBoostLabToolAction -ActionName 'Apply' -Confirmed:$true -RegistryWriter $writer -RegistryReader $reader
    Assert-BoostLabCondition ([bool]$result.Success) 'Input Language Hotkey Apply should succeed when all values verify.'
    Assert-BoostLabCondition ([string]$result.Status -eq 'Completed') 'Successful Input Language Hotkey Apply status mismatch.'
    Assert-BoostLabCondition ([string]$result.VerificationStatus -eq 'Passed') 'Successful Input Language Hotkey verification status mismatch.'
    Assert-BoostLabCondition ($writeCalls.Count -eq 3) 'Input Language Hotkey Apply must write exactly three values.'
    Assert-BoostLabCondition ([string]$registryState['Hotkey'] -eq '1') 'Hotkey value was not written as 1.'
    Assert-BoostLabCondition ([string]$registryState['Language Hotkey'] -eq '1') 'Language Hotkey value was not written as 1.'
    Assert-BoostLabCondition ([string]$registryState['Layout Hotkey'] -eq '3') 'Layout Hotkey value was not written as 3.'
    Assert-BoostLabCondition ([bool]$result.Data.HkcuOnly) 'Result data must report HKCU-only behavior.'
    Assert-BoostLabCondition (-not [bool]$result.Data.HklmMutation) 'Result data must report no HKLM mutation.'
    Assert-BoostLabCondition (-not [bool]$result.Data.UiAutomationUsed) 'Result data must report no UI automation.'
    foreach ($dialogField in @('DialogOpenAttempted', 'DialogOpenCommand', 'DialogOpenSucceeded', 'DialogOpenWarning')) {
        Assert-BoostLabCondition ($null -eq $result.Data.PSObject.Properties[$dialogField]) "Input Language Hotkey result data must not expose obsolete dialog diagnostic field: $dialogField"
    }

    $failedWriteCalls = [System.Collections.ArrayList]::new()
    $failingWriter = {
        param($Path, $Name, $Value)
        [void]$failedWriteCalls.Add($Name)
        if ($Name -eq 'Language Hotkey') {
            throw 'Mock write failure.'
        }
        [pscustomobject]@{ Success = $true; Message = "Mock set $Name." }
    }.GetNewClosure()
    $emptyReader = New-MockInputLanguageHotkeyReader -State @{}
    $failureResult = Invoke-InputHotkeyTestBoostLabToolAction -ActionName 'Apply' -Confirmed:$true -RegistryWriter $failingWriter -RegistryReader $emptyReader
    Assert-BoostLabCondition (-not [bool]$failureResult.Success) 'Write failure must fail closed.'
    Assert-BoostLabCondition ([string]$failureResult.Status -eq 'Error') 'Write failure status must be Error.'
    Assert-BoostLabCondition ((@($failureResult.Errors) -join ' ').Contains('Language Hotkey write failed')) 'Write failure must report the failed value name.'

    $mismatchState = @{
        'Hotkey' = '1'
        'Language Hotkey' = '2'
        'Layout Hotkey' = '3'
    }
    $mismatchReader = New-MockInputLanguageHotkeyReader -State $mismatchState
    $mismatchVerification = & $module {
        param($Reader)
        Test-BoostLabInputLanguageHotkeyState -RegistryReader $Reader
    } $mismatchReader
    Assert-BoostLabCondition ([string]$mismatchVerification.Status -eq 'Failed') 'Mismatched Language Hotkey must fail verification.'

    $wrongKindState = @{
        'Hotkey' = '1'
        'Language Hotkey' = '1'
        'Layout Hotkey' = '3'
    }
    $wrongKindReader = New-MockInputLanguageHotkeyReader -State $wrongKindState -ValueKind 'DWord'
    $wrongKindVerification = & $module {
        param($Reader)
        Test-BoostLabInputLanguageHotkeyState -RegistryReader $Reader
    } $wrongKindReader
    Assert-BoostLabCondition ([string]$wrongKindVerification.Status -eq 'Failed') 'Non-string value kinds must fail verification.'

    $cancelledResult = Invoke-InputHotkeyTestBoostLabToolAction -ActionName 'Apply' -Confirmed:$false -RegistryWriter $writer -RegistryReader $reader
    Assert-BoostLabCondition (-not [bool]$cancelledResult.Success) 'Unconfirmed Apply must not succeed.'
    Assert-BoostLabCondition ([bool]$cancelledResult.Cancelled) 'Unconfirmed Apply must return Cancelled.'

    $unsupportedResult = Invoke-InputHotkeyTestBoostLabToolAction -ActionName 'Default' -Confirmed:$true
    Assert-BoostLabCondition (-not [bool]$unsupportedResult.Success) 'Default must remain unsupported.'
    Assert-BoostLabCondition ([string]$unsupportedResult.Status -eq 'UnsupportedAction') 'Default should return UnsupportedAction.'
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
}

$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$inventoryAssertion = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$record = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'input-language-hotkey' })[0]
Assert-BoostLabCondition ($null -ne $record) 'Input Language Hotkey parity/status record is missing.'
Assert-BoostLabCondition ([string]$record.RuntimeStatus -eq 'RuntimeImplemented') 'Input Language Hotkey runtime status must be implemented.'
Assert-BoostLabCondition ([string]$record.ImplementationLevel -eq 'ParityImplemented') 'Input Language Hotkey implementation level must follow existing implemented-tool conventions.'
Assert-BoostLabCondition ([string]$record.UltimateParity -eq 'Yes') 'Input Language Hotkey accepted status must count as implemented for central baselines.'
Assert-BoostLabCondition ([int]$record.ToolOrder -eq 16) 'Input Language Hotkey parity order must be 16.'
Assert-BoostLabCondition ([string]$record.GapSummary -like '*not sourced from source-ultimate*') 'Input Language Hotkey parity record must state it is not source-ultimate.'
Assert-BoostLabCondition ([int]$inventoryAssertion.Baseline.ActiveTools -eq 47) 'Inventory baseline active tool count must include Input Language Hotkey.'
Assert-BoostLabCondition ([int]$inventoryAssertion.Baseline.ImplementedTools -eq 47) 'Inventory baseline implemented tool count must include Input Language Hotkey.'
Assert-BoostLabCondition ([int]$inventoryAssertion.Snapshot.ActiveTools -eq [int]$inventoryAssertion.Baseline.ActiveTools) 'Inventory snapshot active count mismatch.'
Assert-BoostLabCondition ([int]$inventoryAssertion.Snapshot.ImplementedTools -eq [int]$inventoryAssertion.Baseline.ImplementedTools) 'Inventory snapshot implemented count mismatch.'
Assert-BoostLabCondition ([bool]$parityBaseline.OrderedParityComplete) 'Ordered parity must remain complete.'
Assert-BoostLabCondition ($null -eq $parityBaseline.CurrentOrderedParityTarget) 'Current ordered parity target must remain null.'

$windowsOrder = @($executionOrder.Stages | Where-Object { [string]$_.Name -eq 'Windows' })[0]
$orderedControlPanel = @($windowsOrder.Tools | Where-Object { [string]$_.ToolId -eq 'control-panel-settings' })[0]
$orderedInputHotkey = @($windowsOrder.Tools | Where-Object { [string]$_.ToolId -eq 'input-language-hotkey' })[0]
$orderedSound = @($windowsOrder.Tools | Where-Object { [string]$_.ToolId -eq 'sound' })[0]
Assert-BoostLabCondition ([int]$orderedInputHotkey.Order -eq ([int]$orderedControlPanel.Order + 1)) 'Ordered parity must place Input Language Hotkey immediately after Control Panel Settings.'
Assert-BoostLabCondition ([int]$orderedSound.Order -eq ([int]$orderedInputHotkey.Order + 1)) 'Ordered parity must keep Sound after Input Language Hotkey.'

foreach ($path in @($artifactProvenancePath, $externalSourcesPath, $productionAllowlistPath)) {
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        $text = Get-Content -Raw -LiteralPath $path
        Assert-BoostLabCondition (-not $text.Contains('input-language-hotkey')) "Input Language Hotkey must not add artifact, provenance, or production allowlist entries: $path"
    }
}

$sourceUltimateRoot = Join-Path $ProjectRoot 'source-ultimate'
Assert-BoostLabCondition (Test-Path -LiteralPath $sourceUltimateRoot -PathType Container) 'source-ultimate must remain present and untouched.'

[pscustomobject]@{
    Success = $true
    ToolId = 'input-language-hotkey'
    Stage = 'Windows'
    Order = 16
    VerifiedValues = @('Hotkey=1', 'Language Hotkey=1', 'Layout Hotkey=3')
    Message = 'Input Language Hotkey Windows-stage placement, mocked runtime, action plan, verification, and protected-path guard passed.'
}
