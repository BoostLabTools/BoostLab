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
        throw 'Unable to determine the Context Menu test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\ContextMenu.psm1'
$oldModulePath = Join-Path $ProjectRoot 'modules\Windows\context-menu.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\3 Context Menu.ps1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$recordPath = Join-Path $ProjectRoot 'docs\migrations\context-menu.md'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$modulesRoot = Join-Path $ProjectRoot 'modules'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$stages = @($configuration['Stages'] | Sort-Object { [int]$_['Order'] })
$tools = @($stages | ForEach-Object { $_['Tools'] })
$tool = $tools | Where-Object { $_['Id'] -eq 'context-menu' } | Select-Object -First 1
if ($null -eq $tool) {
    throw 'Context Menu metadata is missing.'
}
if (
    [string]$tool['Stage'] -ne 'Windows' -or
    [int]$tool['Order'] -ne 3 -or
    [string]$tool['Type'] -ne 'action' -or
    [string]$tool['RiskLevel'] -ne 'medium' -or
    (@($tool['Actions']) -join ',') -ne 'Apply,Default'
) {
    throw 'Context Menu stage, order, type, risk, or actions are incorrect.'
}

$capabilities = $tool['Capabilities']
$expectedTrueCapabilities = @(
    'RequiresAdmin'
    'CanModifyRegistry'
    'CanModifySecurity'
    'SupportsDefault'
    'NeedsExplicitConfirmation'
)
foreach ($field in $capabilities.Keys) {
    $expected = $field -in $expectedTrueCapabilities
    if ([bool]$capabilities[$field] -ne $expected) {
        throw "Context Menu capability '$field' is incorrect."
    }
}

if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne '33DA36782CF6416A2FAE98829ADF0913B0E54DC53DE454AB0C5210A79754B6F2') {
    throw 'Context Menu Ultimate source hash changed.'
}
$source = Get-Content -Raw -LiteralPath $sourcePath
foreach ($requiredText in @(
    'Context Menu: Clean (Recommended)'
    'Context Menu: Default'
    'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
    'NoCustomizeThisFolder'
    '{9F156763-7844-4DC4-B2B1-901F640F5155}'
    '{09A47860-11B0-4DA5-AFA5-26D86198A780}'
    '{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}'
    '$env:SystemRoot\Temp\contextmenudefault.reg'
    'Regedit.exe /S "$env:SystemRoot\Temp\contextmenudefault.reg"'
    'reg delete `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked`" /f'
)) {
    if (-not $source.Contains($requiredText)) {
        throw "Context Menu source no longer contains: $requiredText"
    }
}
foreach ($forbiddenSourceText in @(
    'Remove-AppxPackage'
    'Add-AppxPackage'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'msiexec'
    'TrustedInstaller'
    'safeboot'
    'Set-Service'
    'Stop-Service'
    'Restart-Service'
    'Restart-Computer'
    'Stop-Computer'
    'shutdown.exe'
    'bcdedit'
    'Stop-Process'
)) {
    if ($source.Contains($forbiddenSourceText)) {
        throw "Context Menu source failed the approved Phase 21 safety boundary: $forbiddenSourceText"
    }
}

if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
    throw 'The canonical Context Menu module is missing.'
}
if (
    (Test-Path -LiteralPath $oldModulePath -PathType Leaf) -and
    (Resolve-Path -LiteralPath $oldModulePath).Path -ne (Resolve-Path -LiteralPath $modulePath).Path
) {
    throw 'The old Context Menu placeholder path still exists as a separate module.'
}
$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredText in @(
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    '$script:BoostLabOwnedBlockedGuids'
    '{9F156763-7844-4DC4-B2B1-901F640F5155}'
    '{09A47860-11B0-4DA5-AFA5-26D86198A780}'
    '{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}'
    'ClassicContextMenu'
    'NoCustomizeThisFolder'
    'ScanWithDefender'
    'BlockedShellExtensions'
    'NoPreviousVersionsPage'
    'contextmenudefault.reg'
    'ImportDefaultFile'
    'Set-Content -Path $Path -Value $Content -Force -ErrorAction Stop'
    '"regedit.exe"'
    '-ArgumentList "/S `"$Path`""'
    'function Test-BoostLabContextMenuState'
    'New-BoostLabVerificationResult'
    '-VerificationResult $verificationResult'
    '[bool]$Confirmed = $false'
    'Clean context menu applied.'
    'Context menu restored to the approved default.'
)) {
    if (-not $moduleSource.Contains($requiredText)) {
        throw "Context Menu module is missing: $requiredText"
    }
}
foreach ($forbiddenModuleText in @(
    'Remove-AppxPackage'
    'Add-AppxPackage'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'Set-Service'
    'Stop-Service'
    'Restart-Service'
    'Restart-Computer'
    'Stop-Computer'
    'shutdown.exe'
    'bcdedit'
    'Stop-Process'
    'UsesTrustedInstaller = $true'
    'safeboot'
)) {
    if ($moduleSource.Contains($forbiddenModuleText)) {
        throw "Context Menu module contains unrelated behavior: $forbiddenModuleText"
    }
}

$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $modulePath,
    [ref]$tokens,
    [ref]$parseErrors
)
if (@($parseErrors).Count -gt 0) {
    throw "Context Menu module syntax error: $($parseErrors[0].Message)"
}
$commands = @(
    $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
        $true
    ) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }
)
if (@($commands | Where-Object { $_ -eq 'Start-Process' }).Count -ne 1) {
    throw 'Context Menu must contain exactly one approved regedit Start-Process call.'
}
if (@($commands | Where-Object { $_ -eq 'Set-Content' }).Count -ne 1) {
    throw 'Context Menu must contain exactly one approved registry-file write helper.'
}

$contextModule = Import-Module `
    -Name $modulePath `
    -Force `
    -PassThru `
    -Prefix 'ContextTest' `
    -Scope Local `
    -DisableNameChecking `
    -ErrorAction Stop
try {
    $toolInfo = Get-ContextTestBoostLabToolInfo
    if (
        [string]$toolInfo.Id -ne 'context-menu' -or
        (@($toolInfo.Actions) -join ',') -ne 'Apply,Default' -or
        (@($toolInfo.ImplementedActions) -join ',') -ne 'Apply,Default'
    ) {
        throw 'Context Menu exported metadata or implemented actions are incorrect.'
    }

    $applyDefinitions = @(& $contextModule { Get-BoostLabContextMenuDefinitions -ActionName 'Apply' })
    $defaultDefinitions = @(& $contextModule { Get-BoostLabContextMenuDefinitions -ActionName 'Default' })
    $applyOperations = @(& $contextModule { Get-BoostLabContextMenuOperations -ActionName 'Apply' })
    $defaultOperations = @(& $contextModule { Get-BoostLabContextMenuOperations -ActionName 'Default' })
    if (
        $applyDefinitions.Count -ne 13 -or
        $defaultDefinitions.Count -ne 21 -or
        $applyOperations.Count -ne 13 -or
        $defaultOperations.Count -ne 10
    ) {
        throw 'Context Menu registry definition or operation counts are incorrect.'
    }

    $expectedApplyOrder = @(
        'ClassicContextMenu'
        'NoCustomizeThisFolder'
        'PinToHome'
        'AddToFavorites'
        'Compatibility'
        'OpenInTerminal'
        'ScanWithDefender'
        'GiveAccessTo'
        'LibraryLocation'
        'ModernSharing'
        'PreviousVersions'
        'SendToAllFilesystemObjects'
        'SendToUserLibraryFolder'
    )
    $expectedDefaultOrder = @(
        'ClassicContextMenu'
        'NoCustomizeThisFolder'
        'PinAndFavoritesDefaults'
        'Compatibility'
        'BlockedShellExtensions'
        'LibraryLocation'
        'ModernSharing'
        'PreviousVersions'
        'SendToAllFilesystemObjects'
        'SendToUserLibraryFolder'
    )
    if (($applyOperations.Id -join '|') -ne ($expectedApplyOrder -join '|')) {
        throw 'Context Menu Apply execution order changed.'
    }
    if (($defaultOperations.Id -join '|') -ne ($expectedDefaultOrder -join '|')) {
        throw 'Context Menu Default execution order changed.'
    }

    $defaultBlockedOperations = @(
        $defaultOperations | Where-Object {
            $_.Key -eq 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'
        }
    )
    if (
        $defaultBlockedOperations.Count -ne 1 -or
        [string]$defaultBlockedOperations[0].Kind -ne 'DeleteKey' -or
        [string]$defaultBlockedOperations[0].Id -ne 'BlockedShellExtensions' -or
        -not [string]::IsNullOrEmpty([string]$defaultBlockedOperations[0].Name)
    ) {
        throw 'Context Menu Default does not delete the complete source-defined Blocked key.'
    }

    $defaultContent = & $contextModule { Get-BoostLabContextMenuDefaultRegistryContent }
    foreach ($requiredText in @(
        '[HKEY_CLASSES_ROOT\Folder\shell\pintohome]'
        '"MUIVerb"="@shell32.dll,-51601"'
        '[HKEY_CLASSES_ROOT\Folder\shell\pintohome\command]'
        '"DelegateExecute"="{b455f46e-e4af-4035-b0a4-cf18d2f6f28e}"'
        '[HKEY_CLASSES_ROOT\*\shell\pintohomefile]'
        '"MUIVerb"="@shell32.dll,-51608"'
        '"NeverDefault"=""'
        '[HKEY_CLASSES_ROOT\*\shell\pintohomefile\command]'
    )) {
        if (-not $defaultContent.Contains($requiredText)) {
            throw "Context Menu Default registry payload is missing: $requiredText"
        }
    }

    $newRegistryState = {
        param(
            [bool]$ReadSucceeded,
            [bool]$Exists,
            [string]$DisplayValue,
            [string]$Message
        )

        return [pscustomobject]@{
            ReadSucceeded = $ReadSucceeded
            KeyExists     = if ($ReadSucceeded) { $Exists } else { $null }
            Exists        = $Exists
            Value         = $null
            DisplayValue  = $DisplayValue
            Message       = $Message
        }
    }
    $newStateMap = {
        param($Definitions)
        $map = [ordered]@{}
        foreach ($definition in @($Definitions)) {
            $key = '{0}|{1}' -f $definition.Path, $definition.Name
            $exists = $definition.Expected -ne 'Absent'
            $map[$key] = & $newRegistryState `
                $true `
                $exists `
                ([string]$definition.Expected) `
                'Mock registry state detected.'
        }
        return $map
    }.GetNewClosure()

    $applyState = & $newStateMap $applyDefinitions
    $applyReader = {
        param($Path, $Name, $ValueType)
        return $applyState[('{0}|{1}' -f $Path, $Name)]
    }.GetNewClosure()
    $applyVerification = & $contextModule {
        param($RegistryReader)
        Test-BoostLabContextMenuState -ActionName 'Apply' -RegistryReader $RegistryReader
    } $applyReader
    if ($applyVerification.Status -ne 'Passed' -or @($applyVerification.Checks).Count -ne 13) {
        throw 'Context Menu Apply verification did not pass all 13 states.'
    }

    $defaultState = & $newStateMap $defaultDefinitions
    $defaultReader = {
        param($Path, $Name, $ValueType)
        return $defaultState[('{0}|{1}' -f $Path, $Name)]
    }.GetNewClosure()
    $defaultVerification = & $contextModule {
        param($RegistryReader)
        Test-BoostLabContextMenuState -ActionName 'Default' -RegistryReader $RegistryReader
    } $defaultReader
    if ($defaultVerification.Status -ne 'Passed' -or @($defaultVerification.Checks).Count -ne 21) {
        throw 'Context Menu Default verification did not pass all 21 states.'
    }

    $warningReader = {
        param($Path, $Name, $ValueType)
        if ($Name -eq 'NoCustomizeThisFolder') {
            return (& $newRegistryState $false $false 'Unknown' 'Mock read failure.')
        }

        return $applyState[('{0}|{1}' -f $Path, $Name)]
    }.GetNewClosure()
    $warningVerification = & $contextModule {
        param($RegistryReader)
        Test-BoostLabContextMenuState -ActionName 'Apply' -RegistryReader $RegistryReader
    } $warningReader
    if ($warningVerification.Status -ne 'Warning') {
        throw "Context Menu expected Warning, found $($warningVerification.Status)."
    }

    $failedReader = {
        param($Path, $Name, $ValueType)
        if ($Name -eq 'NoPreviousVersionsPage') {
            return (& $newRegistryState $true $true '0x00000000' 'Mock contradictory value.')
        }

        return $applyState[('{0}|{1}' -f $Path, $Name)]
    }.GetNewClosure()
    $failedVerification = & $contextModule {
        param($RegistryReader)
        Test-BoostLabContextMenuState -ActionName 'Apply' -RegistryReader $RegistryReader
    } $failedReader
    if ($failedVerification.Status -ne 'Failed') {
        throw "Context Menu expected Failed, found $($failedVerification.Status)."
    }

    $applyEvents = [System.Collections.Generic.List[string]]::new()
    $applyRunner = {
        param($Operation)
        $applyEvents.Add("REG:$($Operation.Id):$($Operation.Kind)")
        return [pscustomobject]@{
            Success = $true; ExitCode = 0; Command = 'mock'; Message = 'Mock operation completed.'
        }
    }.GetNewClosure()
    $applyResult = & $contextModule {
        param($RegistryCommandRunner, $RegistryReader)
        Invoke-BoostLabContextMenuAction `
            -ActionName 'Apply' `
            -AdministratorChecker { return $true } `
            -RegistryCommandRunner $RegistryCommandRunner `
            -RegistryReader $RegistryReader
    } $applyRunner $applyReader
    if (
        -not $applyResult.Success -or
        $applyResult.Message -ne 'Clean context menu applied.' -or
        $applyResult.Data.CommandStatus -ne 'Completed' -or
        $applyResult.VerificationResult.Status -ne 'Passed' -or
        @($applyResult.Data.RegistryStatesChecked).Count -ne 13
    ) {
        throw 'Mocked Context Menu Apply did not return the expected structured result.'
    }
    if (($applyEvents | ForEach-Object { ($_ -split ':')[1] }) -join '|' -ne ($expectedApplyOrder -join '|')) {
        throw 'Mocked Context Menu Apply operation order changed.'
    }

    $defaultEvents = [System.Collections.Generic.List[string]]::new()
    $defaultCapture = [pscustomobject]@{ Path = ''; Content = '' }
    $defaultRunner = {
        param($Operation)
        $defaultEvents.Add("REG:$($Operation.Id):$($Operation.Kind)")
        return [pscustomobject]@{
            Success = $true; ExitCode = 0; Command = 'mock'; Message = 'Mock operation completed.'
        }
    }.GetNewClosure()
    $fileWriter = {
        param($Path, $Content)
        $defaultCapture.Path = $Path
        $defaultCapture.Content = [string]$Content
        $defaultEvents.Add('FILE:PinAndFavoritesDefaults:Write')
    }.GetNewClosure()
    $registryImporter = {
        param($Path)
        $defaultEvents.Add('IMPORT:PinAndFavoritesDefaults:Import')
    }.GetNewClosure()
    $defaultResult = & $contextModule {
        param($RegistryCommandRunner, $FileWriter, $RegistryImporter, $RegistryReader)
        Invoke-BoostLabContextMenuAction `
            -ActionName 'Default' `
            -AdministratorChecker { return $true } `
            -RegistryCommandRunner $RegistryCommandRunner `
            -FileWriter $FileWriter `
            -RegistryImporter $RegistryImporter `
            -RegistryReader $RegistryReader
    } $defaultRunner $fileWriter $registryImporter $defaultReader
    if (
        -not $defaultResult.Success -or
        $defaultResult.Message -ne 'Context menu restored to the approved default.' -or
        $defaultResult.Data.CommandStatus -ne 'Completed' -or
        $defaultResult.Data.RegistryFileStatus -ne 'Written' -or
        $defaultResult.Data.RegistryImportStatus -ne 'Completed' -or
        $defaultResult.VerificationResult.Status -ne 'Passed' -or
        @($defaultResult.Data.RegistryStatesChecked).Count -ne 21
    ) {
        throw 'Mocked Context Menu Default did not return the expected structured result.'
    }
    $expectedDefaultEvents = @(
        'REG:ClassicContextMenu:DeleteKey'
        'REG:NoCustomizeThisFolder:DeleteValue'
        'FILE:PinAndFavoritesDefaults:Write'
        'IMPORT:PinAndFavoritesDefaults:Import'
        'REG:Compatibility:Add'
        'REG:BlockedShellExtensions:DeleteKey'
        'REG:LibraryLocation:Add'
        'REG:ModernSharing:Add'
        'REG:PreviousVersions:DeleteValue'
        'REG:SendToAllFilesystemObjects:Add'
        'REG:SendToUserLibraryFolder:Add'
    )
    if (($defaultEvents -join '|') -ne ($expectedDefaultEvents -join '|')) {
        throw "Context Menu Default execution order changed: $($defaultEvents -join '|')"
    }
    if (
        [IO.Path]::GetFileName($defaultCapture.Path) -ne 'contextmenudefault.reg' -or
        $defaultCapture.Content -ne $defaultContent
    ) {
        throw 'Context Menu Default did not write the approved source registry payload.'
    }

    foreach ($result in @($applyResult, $defaultResult)) {
        foreach ($field in @(
            'Success'
            'ToolId'
            'ToolTitle'
            'Action'
            'Message'
            'RestartRequired'
            'Cancelled'
            'Timestamp'
            'Data'
            'VerificationResult'
        )) {
            if ($null -eq $result.PSObject.Properties[$field]) {
                throw "Context Menu result is missing field: $field"
            }
        }
        foreach ($dataField in @(
            'CommandStatus'
            'ExpectedContextMenuState'
            'DetectedContextMenuState'
            'RegistryStatesChecked'
            'RegistryOperations'
            'RegistryOperationWarnings'
            'RegistryFilePath'
            'RegistryFileStatus'
            'RegistryImportStatus'
            'UiRefreshStatus'
            'CompletedAt'
        )) {
            if ($null -eq $result.Data.PSObject.Properties[$dataField]) {
                throw "Context Menu result data is missing field: $dataField"
            }
        }
    }
}
finally {
    Remove-Module -ModuleInfo $contextModule -Force -ErrorAction SilentlyContinue
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    foreach ($actionName in @('Apply', 'Default')) {
        $plan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName $actionName -IsDryRun $false
        $planText = @(
            $plan.Summary
            @($plan.PlannedChanges)
            @($plan.SideEffects)
            $plan.ConfirmationMessage
        ) -join ' '
        if (
            -not $plan.RequiresAdmin -or
            -not $plan.NeedsExplicitConfirmation -or
            -not $plan.Capabilities.CanModifySecurity -or
            $plan.CanReboot -or
            $plan.RequiresInternet -or
            $plan.UsesTrustedInstaller -or
            $planText -notmatch 'Context Menu|context-menu' -or
            $plan.ConfirmationMessage -notmatch 'No restart is required'
        ) {
            throw "Context Menu $actionName Action Plan is incorrect."
        }
    }
    $defaultPlan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Default' -IsDryRun $false
    $defaultPlanText = @(
        @($defaultPlan.PlannedChanges)
        @($defaultPlan.SideEffects)
        $defaultPlan.ConfirmationMessage
    ) -join ' '
    if (
        $defaultPlanText -notmatch 'complete.*Blocked|entire.*Blocked' -or
        $defaultPlanText -notmatch 'Ultimate' -or
        $defaultPlanText -notmatch 'unrelated'
    ) {
        throw 'Context Menu Default plan does not disclose the source-defined complete Blocked key deletion.'
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredText in @(
    '''context-menu'' = @{'
    '''Windows\ContextMenu.psm1'''
    'Actions = @(''Apply'', ''Default'')'
    '$actionCommand.Parameters.ContainsKey(''Confirmed'')'
    'Get-BoostLabVerificationValidation'
)) {
    if (-not $executionSource.Contains($requiredText)) {
        throw "Context Menu runtime mapping is missing: $requiredText"
    }
}

$uiSource = Get-Content -Raw -LiteralPath $uiPath
foreach ($requiredText in @(
    '$toolId -eq ''context-menu'''
    '-Label ''Command Status'''
    '-Label ''Verification Status'''
    '-Label ''Expected Context Menu state'''
    '-Label ''Detected Context Menu state'''
    '-Label ''Registry keys and values checked'''
    '-Label ''UI / Explorer refresh'''
)) {
    if (-not $uiSource.Contains($requiredText)) {
        throw "Context Menu UI rendering is missing: $requiredText"
    }
}

$record = Get-Content -Raw -LiteralPath $recordPath
foreach ($requiredText in @(
    'source-ultimate/6 Windows/3 Context Menu.ps1'
    '33DA36782CF6416A2FAE98829ADF0913B0E54DC53DE454AB0C5210A79754B6F2'
    'Approved by Yazan'
    'Exact Ultimate Default Parity'
    'deletes the complete shared `Shell Extensions\Blocked` key'
    'can remove unrelated blocked shell-extension entries'
    'NeedsExplicitConfirmation = true'
    'Automated tests must use static inspection and mocks only'
)) {
    if (-not $record.Contains($requiredText)) {
        throw "Context Menu migration record is missing: $requiredText"
    }
}

$unchangedModules = [ordered]@{
    StartMenuLayout = @{
        Path = Join-Path $modulesRoot 'Windows\StartMenuLayout.psm1'
        Hash = 'D93019267A3D566146F713DF69C86F41CDAD93A2B0786D5CB8DDF9F2878E103A'
        Required = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    ThemeBlack = @{
        Path = Join-Path $modulesRoot 'Windows\ThemeBlack.psm1'
        Hash = '76E606B73300CD8A5C729500DC1516166DB80C4D389ECF2094BB6E9376EEA60A'
        Required = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    GameMode = @{
        Path = Join-Path $modulesRoot 'Windows\game-mode.psm1'
        Hash = 'CADEC6B0E4262990BF9D9BBDBD8DBA55EE910EEFC1FF72B78912800AD04624E9'
        Required = 'Start-Process "ms-settings:gaming-gamemode"'
    }
    GameBar = @{
        Path = Join-Path $modulesRoot 'Windows\game-bar.psm1'
        Hash = '8DB85CD336D8EFE665F7710004DC1C2A869ADB77D01D98F71D6D39CC6DB6BBC9'
        Required = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    Copilot = @{
        Path = Join-Path $modulesRoot 'Windows\copilot.psm1'
        Hash = 'B4E7FEC7BF1BE0AD4D5B8295008C315409B261388DB782541102409DC7E239B7'
        Required = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
}
foreach ($name in $unchangedModules.Keys) {
    $definition = $unchangedModules[$name]
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $definition.Path).Hash -ne $definition.Hash) {
        throw "$name module changed during Phase 21."
    }
    $content = Get-Content -Raw -LiteralPath $definition.Path
    if (-not $content.Contains([string]$definition.Required)) {
        throw "$name expected behavior or placeholder marker is missing."
    }
}

$allModules = @(
    Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1' |
        Where-Object { $_.Directory.Parent.FullName -eq $modulesRoot }
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

$deletedToolNames = @(
    'Windows Activation Helper'
    'Firewall'
    'DEP'
    'File Download Security Warning'
    'MPO'
    'FSO'
    'FSE'
    'Hardware Flip'
    'AMD ULPS'
    'WHQL Secure Boot Bypass'
    'Keyboard Shortcuts'
    'Search Shell Mobsync'
    'NVME Faster Driver'
    'Core 1 Thread 1'
    'DDU'
    'UAC'
    'Scaling'
    'Start Menu Shortcuts'
    'Loudness EQ'
)
function ConvertTo-NormalizedToolName {
    param([Parameter(Mandatory)][string]$Name)

    return ($Name -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()
}
$approvedNames = @(
    $tools | ForEach-Object {
        ConvertTo-NormalizedToolName -Name ([string]$_['Title'])
        ConvertTo-NormalizedToolName -Name ([string]$_['Id'])
    }
)
foreach ($deletedName in $deletedToolNames) {
    if ((ConvertTo-NormalizedToolName -Name $deletedName) -in $approvedNames) {
        throw "Deleted tool is present in the catalog: $deletedName"
    }
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
        ForEach-Object {
            '{0}|{1}' -f `
                $_.FullName.Substring($root.Length + 1).Replace('\', '/'), `
                (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
        }
)
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
    $sourceLines.Count -ne 49 -or
    $sourceManifestHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477'
) {
    throw 'source-ultimate content or paths changed.'
}

[pscustomobject]@{
    Success                  = $true
    ToolId                   = 'context-menu'
    ImplementedActions       = @('Apply', 'Default')
    ApplyRegistryCheckCount  = 13
    DefaultRegistryCheckCount = 21
    ApplyExecuted            = $false
    DefaultExecuted          = $false
    MockedApplyPassed        = $true
    MockedDefaultPassed      = $true
    BroadBlockedKeyDeleted   = $true
    ImplementedModuleCount   = $implementedCount
    PlaceholderModuleCount   = $placeholderCount
    SourceUltimateUnchanged  = $true
    ProtectedModulesUnchanged = $true
    Message                  = 'Context Menu Apply and exact Ultimate Default were validated with mocks only.'
    Timestamp                = Get-Date
}



