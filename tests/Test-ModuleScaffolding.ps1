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
        throw 'Unable to determine the validator script path.'
    }

    $scriptDirectory = Split-Path -Parent $scriptPath
    $ProjectRoot = Split-Path -Parent $scriptDirectory
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$placeholderPath = Join-Path $modulesRoot 'ToolModule.Placeholder.ps1'
$implementedModules = @{
    'bios-information' = @{
        RelativePath          = 'Check\BIOSInformation.psm1'
        LaunchText            = 'Start-Process $searchUrl'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Analyze'', ''Open'')'
    }
    'startup-apps-settings' = @{
        RelativePath          = 'Setup\StartupAppsSettings.psm1'
        LaunchText            = 'Start-Process "ms-settings:startupapps"'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Open'')'
    }
    'startup-apps-task-manager' = @{
        RelativePath          = 'Setup\StartupAppsTaskManager.psm1'
        LaunchText            = 'Start-Process "taskmgr" -ArgumentList " /0 /startup"'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Open'')'
    }
    'graphics-configuration-center' = @{
        RelativePath          = 'Graphics\GraphicsConfigurationCenter.psm1'
        LaunchText            = 'Start-Process "ms-settings:display-advancedgraphics"'
        ImplementedActionsText = '$script:BoostLabImplementedActions = @(''Open'')'
    }
}
$requiredFunctions = @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
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
)
$prohibitedCommands = @(
    'Set-ItemProperty'
    'New-ItemProperty'
    'Remove-ItemProperty'
    'Remove-Item'
    'Set-Content'
    'Add-Content'
    'Out-File'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'Restart-Computer'
    'Stop-Computer'
    'Checkpoint-Computer'
    'Enable-ComputerRestore'
    'Disable-ComputerRestore'
    'Invoke-Expression'
)
$errors = [System.Collections.Generic.List[string]]::new()

if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    throw "Stage configuration was not found: $configPath"
}
if (-not (Test-Path -LiteralPath $placeholderPath -PathType Leaf)) {
    throw "Shared placeholder implementation was not found: $placeholderPath"
}

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$stages = @($configuration['Stages'] | Sort-Object { [int]$_['Order'] })
$expectedModules = [ordered]@{}

foreach ($stage in $stages) {
    foreach ($tool in @($stage['Tools'] | Sort-Object { [int]$_['Order'] })) {
        $toolId = [string]$tool['Id']
        $relativePath = if ($implementedModules.ContainsKey($toolId)) {
            [string]$implementedModules[$toolId].RelativePath
        }
        else {
            Join-Path ([string]$stage['Name']) ("{0}.psm1" -f $toolId)
        }
        $fullPath = Join-Path $modulesRoot $relativePath
        $expectedModules[$fullPath.ToLowerInvariant()] = @{
            Path = $fullPath
            Tool = $tool
        }
    }
}

$actualModules = @(
    Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1' |
        Where-Object { $_.Directory.Parent.FullName -eq $modulesRoot }
)
$actualModuleLookup = @{}
foreach ($module in $actualModules) {
    $actualModuleLookup[$module.FullName.ToLowerInvariant()] = $module
}

foreach ($expectedKey in $expectedModules.Keys) {
    if (-not $actualModuleLookup.ContainsKey($expectedKey)) {
        $errors.Add("Missing module: $($expectedModules[$expectedKey].Path)")
    }
}

foreach ($actualKey in $actualModuleLookup.Keys) {
    if (-not $expectedModules.Contains($actualKey)) {
        $errors.Add("Unexpected module: $($actualModuleLookup[$actualKey].FullName)")
    }
}

$placeholderTokens = $null
$placeholderParseErrors = $null
$placeholderAst = [System.Management.Automation.Language.Parser]::ParseFile(
    $placeholderPath,
    [ref]$placeholderTokens,
    [ref]$placeholderParseErrors
)
foreach ($parseError in @($placeholderParseErrors)) {
    $errors.Add("Placeholder syntax error: $($parseError.Message)")
}

$placeholderFunctions = @(
    $placeholderAst.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] },
        $true
    ) | ForEach-Object { $_.Name }
)
foreach ($functionName in $requiredFunctions) {
    if ($functionName -notin $placeholderFunctions) {
        $errors.Add("Shared placeholder is missing function: $functionName")
    }
}

foreach ($entry in $expectedModules.Values) {
    $modulePath = [string]$entry.Path
    if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
        continue
    }

    $tool = $entry.Tool
    $source = Get-Content -Raw -LiteralPath $modulePath
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $modulePath,
        [ref]$tokens,
        [ref]$parseErrors
    )
    foreach ($parseError in @($parseErrors)) {
        $errors.Add("$modulePath syntax error: $($parseError.Message)")
    }

    $metadataChecks = [ordered]@{
        Id          = "Id = '$($tool['Id'])'"
        Title       = "Title = '$($tool['Title'])'"
        Stage       = "Stage = '$($tool['Stage'])'"
        Order       = "Order = $([int]$tool['Order'])"
        Type        = "Type = '$($tool['Type'])'"
        RiskLevel   = "RiskLevel = '$($tool['RiskLevel'])'"
        Description = "Description = '$($tool['Description'])'"
        Actions     = "Actions = @($((@($tool['Actions']) | ForEach-Object { "'$_'" }) -join ', '))"
    }
    foreach ($field in $metadataChecks.Keys) {
        if (-not $source.Contains([string]$metadataChecks[$field])) {
            $errors.Add("$modulePath metadata mismatch: $field")
        }
    }

    foreach ($functionName in $requiredFunctions) {
        if (-not $source.Contains("'$functionName'")) {
            $errors.Add("$modulePath does not export $functionName.")
        }
    }

    $commands = @(
        $ast.FindAll(
            { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
            $true
        ) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }
    )
    foreach ($commandName in $commands) {
        if ($commandName -in $prohibitedCommands) {
            $errors.Add("$modulePath contains prohibited command: $commandName")
        }
    }

    $toolId = [string]$tool['Id']
    if ($implementedModules.ContainsKey($toolId)) {
        if ($source.Contains('ToolModule.Placeholder.ps1')) {
            $errors.Add("$modulePath must not use the shared placeholder implementation.")
        }
        if (-not $source.Contains([string]$implementedModules[$toolId].ImplementedActionsText)) {
            $errors.Add("$modulePath does not declare the approved implemented actions.")
        }
        if (-not $source.Contains([string]$implementedModules[$toolId].LaunchText)) {
            $errors.Add("$modulePath does not preserve the approved Start-Process behavior.")
        }

        $startProcessCount = @($commands | Where-Object { $_ -eq 'Start-Process' }).Count
        if ($startProcessCount -ne 1) {
            $errors.Add("$modulePath must contain exactly one Start-Process command.")
        }

        if ($toolId -eq 'bios-information') {
            foreach ($requiredText in @(
                'Get-CimInstance'
                '[System.Uri]::EscapeDataString'
                'https://www.google.com/search?q='
                'Confirm-SecureBootUEFI'
                'Get-Tpm'
            )) {
                if (-not $source.Contains($requiredText)) {
                    $errors.Add("$modulePath is missing BIOS information safety behavior: $requiredText")
                }
            }
        }
    }
    else {
        if (-not $source.Contains('ToolModule.Placeholder.ps1')) {
            $errors.Add("$modulePath does not use the shared placeholder contract.")
        }
        if ('Start-Process' -in $commands) {
            $errors.Add("$modulePath is a placeholder but contains Start-Process.")
        }
        if ($source.Contains('$script:BoostLabImplementedActions')) {
            $errors.Add("$modulePath is a placeholder but declares implemented actions.")
        }
    }
}

$normalizedDeletedNames = @(
    $deletedToolNames | ForEach-Object {
        ($_ -replace '[^a-zA-Z0-9]+', '-').Trim('-').ToLowerInvariant()
    }
)
foreach ($module in $actualModules) {
    $moduleId = [System.IO.Path]::GetFileNameWithoutExtension($module.Name).ToLowerInvariant()
    if ($moduleId -in $normalizedDeletedNames) {
        $errors.Add("Deleted tool module found: $($module.FullName)")
    }
}

if ($errors.Count -gt 0) {
    throw "Module scaffolding validation failed:`r`n- $($errors -join "`r`n- ")"
}

[pscustomobject]@{
    Success               = $true
    ApprovedToolCount     = $expectedModules.Count
    ModuleCount           = $actualModules.Count
    ImplementedModuleCount = $implementedModules.Count
    PlaceholderModuleCount = $actualModules.Count - $implementedModules.Count
    RequiredFunctionCount = $requiredFunctions.Count
    DeletedModuleCount    = 0
    Message               = 'All approved tools have matching modules and valid implementation status.'
    Timestamp             = Get-Date
}
