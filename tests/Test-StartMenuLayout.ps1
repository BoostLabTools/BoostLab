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
        throw 'Unable to determine the Start Menu Layout test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\StartMenuLayout.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\2 Start Menu Layout.ps1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$recordPath = Join-Path $ProjectRoot 'docs\migrations\start-menu-layout.md'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$featureOverrideIds = @('2792562829', '3036241548', '734731404', '762256525')

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration['Stages'] | ForEach-Object { $_['Tools'] })
$tool = $tools | Where-Object { $_['Id'] -eq 'start-menu-layout' } | Select-Object -First 1
if ($null -eq $tool) {
    throw 'Start Menu Layout metadata is missing.'
}
if (
    [string]$tool['Stage'] -ne 'Windows' -or
    [int]$tool['Order'] -ne 2 -or
    [string]$tool['Type'] -ne 'action' -or
    [string]$tool['RiskLevel'] -ne 'low' -or
    (@($tool['Actions']) -join ',') -ne 'Apply,Default'
) {
    throw 'Start Menu Layout stage, order, type, risk, or actions are incorrect.'
}

$capabilities = $tool['Capabilities']
$expectedTrueCapabilities = @(
    'RequiresAdmin'
    'CanModifyRegistry'
    'SupportsDefault'
    'NeedsExplicitConfirmation'
)
foreach ($field in $capabilities.Keys) {
    $expected = $field -in $expectedTrueCapabilities
    if ([bool]$capabilities[$field] -ne $expected) {
        throw "Start Menu Layout capability '$field' is incorrect."
    }
}

if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne '81C1298D7C9E112DB910C4398CD94E4B70ECD97ED3B185CF2FD2B8A380E069E8') {
    throw 'Start Menu Layout Ultimate source hash changed.'
}
$source = Get-Content -Raw -LiteralPath $sourcePath
foreach ($requiredText in @(
    'Start Menu: 25H2 (Recommended)'
    'Start Menu: 24H2'
    '$env:SystemRoot\Temp\newstartmenu.reg'
    '$env:SystemRoot\Temp\oldstartmenu.reg'
    '"EnabledState"=dword:00000002'
    '"EnabledState"=-'
    '"AllAppsViewMode"=dword:00000002'
    '"AllAppsViewMode"=dword:00000000'
    'Set-Content -Path "$env:SystemRoot\Temp\newstartmenu.reg" -Value $NewStartMenu -Force'
    'Set-Content -Path "$env:SystemRoot\Temp\oldstartmenu.reg" -Value $OldStartMenu -Force'
    'Start-Process -Wait "regedit.exe" -ArgumentList "/S `"$env:SystemRoot\Temp\newstartmenu.reg`"" -WindowStyle Hidden'
    'Start-Process -Wait "regedit.exe" -ArgumentList "/S `"$env:SystemRoot\Temp\oldstartmenu.reg`"" -WindowStyle Hidden'
)) {
    if (-not $source.Contains($requiredText)) {
        throw "Start Menu Layout source no longer contains: $requiredText"
    }
}
foreach ($overrideId in $featureOverrideIds) {
    if (-not $source.Contains("Overrides\14\$overrideId")) {
        throw "Start Menu Layout source is missing feature override: $overrideId"
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
    'Set-MpPreference'
    'Restart-Computer'
    'Stop-Computer'
    'shutdown.exe'
    'bcdedit'
    'Stop-Process'
    'Remove-Item'
)) {
    if ($source.Contains($forbiddenSourceText)) {
        throw "Start Menu Layout source failed the Phase 20 safety gate: $forbiddenSourceText"
    }
}

$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredText in @(
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    'newstartmenu.reg'
    'oldstartmenu.reg'
    '"EnabledState"=dword:00000002'
    '"EnabledState"=-'
    '"AllAppsViewMode"=dword:00000002'
    '"AllAppsViewMode"=dword:00000000'
    'Set-Content -Path $Path -Value $Content -Force -ErrorAction Stop'
    '"regedit.exe"'
    '-ArgumentList "/S `"$Path`""'
    'function Test-BoostLabStartMenuLayoutState'
    'New-BoostLabVerificationResult'
    '-VerificationResult $verificationResult'
    '[bool]$Confirmed = $false'
    'Start Menu 25H2 layout applied.'
    'Start Menu 24H2 layout restored as default.'
)) {
    if (-not $moduleSource.Contains($requiredText)) {
        throw "Start Menu Layout module is missing: $requiredText"
    }
}
foreach ($overrideId in $featureOverrideIds) {
    if (-not $moduleSource.Contains("'$overrideId'")) {
        throw "Start Menu Layout module is missing feature override: $overrideId"
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
    'Set-MpPreference'
    'Restart-Computer'
    'Stop-Computer'
    'shutdown.exe'
    'bcdedit'
    'Stop-Process'
    'Remove-Item'
    'UsesTrustedInstaller = $true'
    'safeboot'
)) {
    if ($moduleSource.Contains($forbiddenModuleText)) {
        throw "Start Menu Layout module contains unrelated behavior: $forbiddenModuleText"
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
    throw "Start Menu Layout module syntax error: $($parseErrors[0].Message)"
}
$commands = @(
    $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
        $true
    ) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }
)
if (@($commands | Where-Object { $_ -eq 'Start-Process' }).Count -ne 1) {
    throw 'Start Menu Layout must contain exactly one approved regedit Start-Process call.'
}
if (@($commands | Where-Object { $_ -eq 'Set-Content' }).Count -ne 1) {
    throw 'Start Menu Layout must contain exactly one approved registry-file write helper.'
}

$layoutModule = Import-Module `
    -Name $modulePath `
    -Force `
    -PassThru `
    -Prefix 'LayoutTest' `
    -Scope Local `
    -DisableNameChecking `
    -ErrorAction Stop
try {
    $infoCommand = Get-Command `
        -Name 'Get-LayoutTestBoostLabToolInfo' `
        -Module $layoutModule.Name `
        -ErrorAction Stop
    $toolInfo = & $infoCommand
    if (
        [string]$toolInfo.Id -ne 'start-menu-layout' -or
        (@($toolInfo.Actions) -join ',') -ne 'Apply,Default' -or
        (@($toolInfo.ImplementedActions) -join ',') -ne 'Apply,Default'
    ) {
        throw 'Start Menu Layout exported metadata or implemented actions are incorrect.'
    }

    $applyContent = & $layoutModule {
        Get-BoostLabStartMenuLayoutRegistryContent -ActionName 'Apply'
    }
    $defaultContent = & $layoutModule {
        Get-BoostLabStartMenuLayoutRegistryContent -ActionName 'Default'
    }
    $applyDefinitions = @(
        & $layoutModule {
            Get-BoostLabStartMenuLayoutDefinitions -ActionName 'Apply'
        }
    )
    $defaultDefinitions = @(
        & $layoutModule {
            Get-BoostLabStartMenuLayoutDefinitions -ActionName 'Default'
        }
    )
    if ($applyDefinitions.Count -ne 5 -or $defaultDefinitions.Count -ne 5) {
        throw 'Start Menu Layout must expose five source-defined registry states for both actions.'
    }

    $expectedApply = [ordered]@{}
    $expectedDefault = [ordered]@{}
    foreach ($overrideId in $featureOverrideIds) {
        $path = "HKLM:\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14\$overrideId"
        $expectedApply["$path|EnabledState"] = '0x00000002'
        $expectedDefault["$path|EnabledState"] = 'Absent'
    }
    $expectedApply['HKCU:\Software\Microsoft\Windows\CurrentVersion\Start|AllAppsViewMode'] = '0x00000002'
    $expectedDefault['HKCU:\Software\Microsoft\Windows\CurrentVersion\Start|AllAppsViewMode'] = '0x00000000'

    foreach ($definition in $applyDefinitions) {
        $key = '{0}|{1}' -f $definition.Path, $definition.Name
        if (-not $expectedApply.Contains($key) -or $expectedApply[$key] -ne $definition.Expected) {
            throw "Unexpected Start Menu Layout Apply definition: $key = $($definition.Expected)"
        }
    }
    foreach ($definition in $defaultDefinitions) {
        $key = '{0}|{1}' -f $definition.Path, $definition.Name
        if (-not $expectedDefault.Contains($key) -or $expectedDefault[$key] -ne $definition.Expected) {
            throw "Unexpected Start Menu Layout Default definition: $key = $($definition.Expected)"
        }
    }

    $normalizedDword = & $layoutModule {
        ConvertTo-BoostLabStartMenuLayoutDisplayValue -Value 2
    }
    if ($normalizedDword -ne '0x00000002') {
        throw 'Start Menu Layout DWORD normalization is incorrect.'
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
            KeyExists     = if ($ReadSucceeded) { $true } else { $null }
            Exists        = $Exists
            Value         = $null
            DisplayValue  = $DisplayValue
            Message       = $Message
        }
    }
    $newFileState = {
        param(
            [bool]$ReadSucceeded,
            [bool]$Exists,
            [AllowNull()][string]$Content,
            [string]$Message
        )

        return [pscustomobject]@{
            ReadSucceeded = $ReadSucceeded
            Exists        = $Exists
            Content       = $Content
            Message       = $Message
        }
    }

    $applyState = [ordered]@{}
    foreach ($definition in $applyDefinitions) {
        $key = '{0}|{1}' -f $definition.Path, $definition.Name
        $applyState[$key] = & $newRegistryState $true $true ([string]$definition.Expected) 'Mock registry state detected.'
    }
    $applyReader = {
        param($Path, $Name)
        return $applyState[('{0}|{1}' -f $Path, $Name)]
    }.GetNewClosure()
    $applyFileReader = {
        param($Path)
        return (& $newFileState $true $true $applyContent 'Mock file detected.')
    }.GetNewClosure()
    $applyVerification = & $layoutModule {
        param($RegistryFileContent, $RegistryReader, $FileReader)
        Test-BoostLabStartMenuLayoutState `
            -ActionName 'Apply' `
            -RegistryFilePath 'C:\Windows\Temp\newstartmenu.reg' `
            -RegistryFileContent $RegistryFileContent `
            -RegistryReader $RegistryReader `
            -FileReader $FileReader
    } $applyContent $applyReader $applyFileReader
    if ($applyVerification.Status -ne 'Passed' -or @($applyVerification.Checks).Count -ne 6) {
        throw 'Start Menu Layout Apply verification did not pass five registry states and one file state.'
    }

    $defaultState = [ordered]@{}
    foreach ($definition in $defaultDefinitions) {
        $key = '{0}|{1}' -f $definition.Path, $definition.Name
        $exists = $definition.Expected -ne 'Absent'
        $defaultState[$key] = & $newRegistryState $true $exists ([string]$definition.Expected) 'Mock registry state detected.'
    }
    $defaultReader = {
        param($Path, $Name)
        return $defaultState[('{0}|{1}' -f $Path, $Name)]
    }.GetNewClosure()
    $defaultFileReader = {
        param($Path)
        return (& $newFileState $true $true $defaultContent 'Mock file detected.')
    }.GetNewClosure()
    $defaultVerification = & $layoutModule {
        param($RegistryFileContent, $RegistryReader, $FileReader)
        Test-BoostLabStartMenuLayoutState `
            -ActionName 'Default' `
            -RegistryFilePath 'C:\Windows\Temp\oldstartmenu.reg' `
            -RegistryFileContent $RegistryFileContent `
            -RegistryReader $RegistryReader `
            -FileReader $FileReader
    } $defaultContent $defaultReader $defaultFileReader
    if ($defaultVerification.Status -ne 'Passed' -or @($defaultVerification.Checks).Count -ne 6) {
        throw 'Start Menu Layout Default verification did not pass five registry states and one file state.'
    }

    $warningReader = {
        param($Path, $Name)
        if ($Path -like '*3036241548') {
            return (& $newRegistryState $false $false 'Unknown' 'Mock read failure.')
        }

        return $applyState[('{0}|{1}' -f $Path, $Name)]
    }.GetNewClosure()
    $warningVerification = & $layoutModule {
        param($RegistryFileContent, $RegistryReader, $FileReader)
        Test-BoostLabStartMenuLayoutState `
            -ActionName 'Apply' `
            -RegistryFilePath 'C:\Windows\Temp\newstartmenu.reg' `
            -RegistryFileContent $RegistryFileContent `
            -RegistryReader $RegistryReader `
            -FileReader $FileReader
    } $applyContent $warningReader $applyFileReader
    if ($warningVerification.Status -ne 'Warning') {
        throw "Start Menu Layout expected Warning, found $($warningVerification.Status)."
    }

    $failedReader = {
        param($Path, $Name)
        if ($Name -eq 'AllAppsViewMode') {
            return (& $newRegistryState $true $true '0x00000000' 'Mock contradictory value.')
        }

        return $applyState[('{0}|{1}' -f $Path, $Name)]
    }.GetNewClosure()
    $failedVerification = & $layoutModule {
        param($RegistryFileContent, $RegistryReader, $FileReader)
        Test-BoostLabStartMenuLayoutState `
            -ActionName 'Apply' `
            -RegistryFilePath 'C:\Windows\Temp\newstartmenu.reg' `
            -RegistryFileContent $RegistryFileContent `
            -RegistryReader $RegistryReader `
            -FileReader $FileReader
    } $applyContent $failedReader $applyFileReader
    if ($failedVerification.Status -ne 'Failed') {
        throw "Start Menu Layout expected Failed, found $($failedVerification.Status)."
    }

    $applyEvents = [System.Collections.Generic.List[string]]::new()
    $mockApplyState = [ordered]@{}
    $applyCapture = [pscustomobject]@{ Path = ''; Content = '' }
    $fileWriter = {
        param($Path, $Content)
        $applyCapture.Path = $Path
        $applyCapture.Content = [string]$Content
        $applyEvents.Add("WRITE:$([IO.Path]::GetFileName($Path))")
    }.GetNewClosure()
    $registryImporter = {
        param($Path)
        $applyEvents.Add("IMPORT:$([IO.Path]::GetFileName($Path))")
        foreach ($definition in $applyDefinitions) {
            $key = '{0}|{1}' -f $definition.Path, $definition.Name
            $mockApplyState[$key] = & $newRegistryState $true $true ([string]$definition.Expected) 'Mock imported state.'
        }
    }.GetNewClosure()
    $mockApplyReader = {
        param($Path, $Name)
        $key = '{0}|{1}' -f $Path, $Name
        if ($mockApplyState.Contains($key)) {
            return $mockApplyState[$key]
        }

        return (& $newRegistryState $true $false 'Absent' 'Mock state absent.')
    }.GetNewClosure()
    $mockApplyFileReader = {
        param($Path)
        if ($Path -eq $applyCapture.Path) {
            return (& $newFileState $true $true $applyCapture.Content 'Mock written file detected.')
        }

        return (& $newFileState $true $false $null 'Mock file absent.')
    }.GetNewClosure()
    $applyResult = & $layoutModule {
        param($FileWriter, $RegistryImporter, $RegistryReader, $FileReader)
        Invoke-BoostLabStartMenuLayoutAction `
            -ActionName 'Apply' `
            -AdministratorChecker { return $true } `
            -FileWriter $FileWriter `
            -RegistryImporter $RegistryImporter `
            -RegistryReader $RegistryReader `
            -FileReader $FileReader
    } $fileWriter $registryImporter $mockApplyReader $mockApplyFileReader
    if (
        -not $applyResult.Success -or
        $applyResult.Message -ne 'Start Menu 25H2 layout applied.' -or
        $applyResult.Data.CommandStatus -ne 'Completed' -or
        $applyResult.Data.RegistryImportStatus -ne 'Completed' -or
        $applyResult.VerificationResult.Status -ne 'Passed' -or
        @($applyResult.Data.RegistryValuesChecked).Count -ne 5 -or
        @($applyResult.Data.FilePathsChecked).Count -ne 1
    ) {
        throw 'Mocked Start Menu Layout Apply did not return the expected structured result.'
    }
    if (($applyEvents -join '|') -ne 'WRITE:newstartmenu.reg|IMPORT:newstartmenu.reg') {
        throw "Start Menu Layout Apply execution order changed: $($applyEvents -join '|')"
    }
    if (
        -not $applyCapture.Content.Contains('"EnabledState"=dword:00000002') -or
        -not $applyCapture.Content.Contains('"AllAppsViewMode"=dword:00000002')
    ) {
        throw 'Start Menu Layout Apply did not write the approved newstartmenu.reg payload.'
    }

    $defaultEvents = [System.Collections.Generic.List[string]]::new()
    $mockDefaultState = [ordered]@{}
    $defaultCapture = [pscustomobject]@{ Path = ''; Content = '' }
    $defaultFileWriterAction = {
        param($Path, $Content)
        $defaultCapture.Path = $Path
        $defaultCapture.Content = [string]$Content
        $defaultEvents.Add("WRITE:$([IO.Path]::GetFileName($Path))")
    }.GetNewClosure()
    $defaultRegistryImporter = {
        param($Path)
        $defaultEvents.Add("IMPORT:$([IO.Path]::GetFileName($Path))")
        foreach ($definition in $defaultDefinitions) {
            $key = '{0}|{1}' -f $definition.Path, $definition.Name
            $exists = $definition.Expected -ne 'Absent'
            $mockDefaultState[$key] = & $newRegistryState $true $exists ([string]$definition.Expected) 'Mock imported state.'
        }
    }.GetNewClosure()
    $mockDefaultReader = {
        param($Path, $Name)
        $key = '{0}|{1}' -f $Path, $Name
        if ($mockDefaultState.Contains($key)) {
            return $mockDefaultState[$key]
        }

        return (& $newRegistryState $true $false 'Absent' 'Mock state absent.')
    }.GetNewClosure()
    $mockDefaultFileReader = {
        param($Path)
        if ($Path -eq $defaultCapture.Path) {
            return (& $newFileState $true $true $defaultCapture.Content 'Mock written file detected.')
        }

        return (& $newFileState $true $false $null 'Mock file absent.')
    }.GetNewClosure()
    $defaultResult = & $layoutModule {
        param($FileWriter, $RegistryImporter, $RegistryReader, $FileReader)
        Invoke-BoostLabStartMenuLayoutAction `
            -ActionName 'Default' `
            -AdministratorChecker { return $true } `
            -FileWriter $FileWriter `
            -RegistryImporter $RegistryImporter `
            -RegistryReader $RegistryReader `
            -FileReader $FileReader
    } $defaultFileWriterAction $defaultRegistryImporter $mockDefaultReader $mockDefaultFileReader
    if (
        -not $defaultResult.Success -or
        $defaultResult.Message -ne 'Start Menu 24H2 layout restored as default.' -or
        $defaultResult.Data.CommandStatus -ne 'Completed' -or
        $defaultResult.Data.RegistryImportStatus -ne 'Completed' -or
        $defaultResult.VerificationResult.Status -ne 'Passed' -or
        @($defaultResult.Data.RegistryValuesChecked).Count -ne 5 -or
        @($defaultResult.Data.FilePathsChecked).Count -ne 1
    ) {
        throw 'Mocked Start Menu Layout Default did not return the expected structured result.'
    }
    if (($defaultEvents -join '|') -ne 'WRITE:oldstartmenu.reg|IMPORT:oldstartmenu.reg') {
        throw "Start Menu Layout Default execution order changed: $($defaultEvents -join '|')"
    }
    if (
        -not $defaultCapture.Content.Contains('"EnabledState"=-') -or
        -not $defaultCapture.Content.Contains('"AllAppsViewMode"=dword:00000000')
    ) {
        throw 'Start Menu Layout Default did not write the approved oldstartmenu.reg payload.'
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
                throw "Start Menu Layout result is missing field: $field"
            }
        }
        foreach ($dataField in @(
            'CommandStatus'
            'ExpectedStartMenuLayoutState'
            'DetectedStartMenuLayoutState'
            'RegistryValuesChecked'
            'FilePathsChecked'
            'RegistryFilePath'
            'RegistryFileStatus'
            'RegistryImportStatus'
            'UiRefreshStatus'
            'CompletedAt'
        )) {
            if ($null -eq $result.Data.PSObject.Properties[$dataField]) {
                throw "Start Menu Layout result data is missing field: $dataField"
            }
        }
    }
}
finally {
    Remove-Module -ModuleInfo $layoutModule -Force -ErrorAction SilentlyContinue
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
            $plan.CanReboot -or
            $plan.RequiresInternet -or
            $plan.UsesTrustedInstaller -or
            $planText -notmatch 'Start menu|Start Menu' -or
            $plan.ConfirmationMessage -notmatch 'No restart is required'
        ) {
            throw "Start Menu Layout $actionName Action Plan is incorrect."
        }
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredText in @(
    '''start-menu-layout'' = @{'
    '''Windows\StartMenuLayout.psm1'''
    'Actions = @(''Apply'', ''Default'')'
    '$actionCommand.Parameters.ContainsKey(''Confirmed'')'
    'Test-BoostLabVerificationResult'
)) {
    if (-not $executionSource.Contains($requiredText)) {
        throw "Start Menu Layout runtime mapping is missing: $requiredText"
    }
}

$uiSource = Get-Content -Raw -LiteralPath $uiPath
foreach ($requiredText in @(
    '$toolId -eq ''start-menu-layout'''
    '-Label ''Command Status'''
    '-Label ''Verification Status'''
    '-Label ''Expected Start Menu Layout state'''
    '-Label ''Detected Start Menu Layout state'''
    '-Label ''Registry values checked'''
    '-Label ''File paths checked'''
    '-Label ''UI refresh / Settings launch'''
)) {
    if (-not $uiSource.Contains($requiredText)) {
        throw "Start Menu Layout UI rendering is missing: $requiredText"
    }
}

$record = Get-Content -Raw -LiteralPath $recordPath
foreach ($requiredText in @(
    'source-ultimate/6 Windows/2 Start Menu Layout.ps1'
    '81C1298D7C9E112DB910C4398CD94E4B70ECD97ED3B185CF2FD2B8A380E069E8'
    'Approved by Yazan'
    'newstartmenu.reg'
    'oldstartmenu.reg'
    'NeedsExplicitConfirmation = true'
    'Automated tests must use mocks'
)) {
    if (-not $record.Contains($requiredText)) {
        throw "Start Menu Layout migration record is missing: $requiredText"
    }
}

$unchangedModules = [ordered]@{
    ThemeBlack = @{
        Path = Join-Path $modulesRoot 'Windows\ThemeBlack.psm1'
        Hash = '29F3474D93061B01E3CF9F23EADA88E932E90E4984EBB39F7DB2BEB24732230F'
        Required = '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    }
    GameMode = @{
        Path = Join-Path $modulesRoot 'Windows\game-mode.psm1'
        Hash = 'CADEC6B0E4262990BF9D9BBDBD8DBA55EE910EEFC1FF72B78912800AD04624E9'
        Required = 'Start-Process "ms-settings:gaming-gamemode"'
    }
    GameBar = @{
        Path = Join-Path $modulesRoot 'Windows\game-bar.psm1'
        Hash = 'E301B2AA588537B81CAB577DA51342FAFFFB7B452C2C36054BD269C51F10CC24'
        Required = 'ToolModule.Placeholder.ps1'
    }
    Copilot = @{
        Path = Join-Path $modulesRoot 'Windows\copilot.psm1'
        Hash = '740FEDE65972C413A7BF0938F3409AB683B45C914281BDDD6C25222FD39E617D'
        Required = 'ToolModule.Placeholder.ps1'
    }
}
foreach ($name in $unchangedModules.Keys) {
    $definition = $unchangedModules[$name]
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $definition.Path).Hash -ne $definition.Hash) {
        throw "$name module changed during Phase 20."
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
if ($implementedCount -ne 23 -or $placeholderCount -ne 25) {
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
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
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
    ToolId                   = 'start-menu-layout'
    ImplementedActions       = @('Apply', 'Default')
    RegistryCheckCount       = 5
    FileCheckCount           = 1
    ApplyExecuted            = $false
    DefaultExecuted          = $false
    MockedApplyPassed        = $true
    MockedDefaultPassed      = $true
    ImplementedModuleCount   = $implementedCount
    PlaceholderModuleCount   = $placeholderCount
    SourceUltimateUnchanged  = $true
    ThemeBlackUnchanged      = $true
    GameBarUnchanged         = $true
    CopilotUnchanged         = $true
    GameModeUnchanged        = $true
    Message                  = 'Start Menu Layout Apply/Default and verification were validated with mocks only.'
    Timestamp                = Get-Date
}
