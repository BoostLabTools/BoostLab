Set-StrictMode -Version Latest

$script:BoostLabModulesRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'modules'
if (-not (Get-Command -Name 'New-BoostLabActionPlan' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path $PSScriptRoot 'ActionPlan.psm1') -Scope Local -Force -ErrorAction Stop
}
if (-not (Get-Command -Name 'Test-BoostLabActionPlanExecutionGate' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path $PSScriptRoot 'Safety.psm1') -Scope Local -Force -ErrorAction Stop
}

$script:BoostLabImplementedToolModules = @{
    'bios-information' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Check\BIOSInformation.psm1'
        Actions = @('Analyze', 'Open')
    }
    'bios-settings' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Check\BIOSSettings.psm1'
        Actions = @('Analyze', 'Open')
    }
    'startup-apps-settings' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Setup\StartupAppsSettings.psm1'
        Actions = @('Open')
    }
    'startup-apps-task-manager' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Setup\StartupAppsTaskManager.psm1'
        Actions = @('Open')
    }
    'graphics-configuration-center' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Graphics\GraphicsConfigurationCenter.psm1'
        Actions = @('Open')
    }
    'date-language-region-time' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Setup\date-language-region-time.psm1'
        Actions = @('Open')
    }
    'game-mode' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Windows\game-mode.psm1'
        Actions = @('Open')
    }
    'pointer-precision' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Windows\pointer-precision.psm1'
        Actions = @('Open')
    }
    'sound' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Windows\sound.psm1'
        Actions = @('Open')
    }
    'restore-point' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Windows\RestorePoint.psm1'
        Actions = @('Apply', 'Open')
    }
}

function Test-BoostLabToolMetadata {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$ToolMetadata,

        [Parameter(Mandatory)]
        [string]$ActionName
    )

    $requiredFields = @(
        'Id'
        'Title'
        'Stage'
        'Order'
        'Type'
        'RiskLevel'
        'Description'
        'Actions'
        'Capabilities'
    )
    $errors = [System.Collections.Generic.List[string]]::new()

    foreach ($field in $requiredFields) {
        if (-not $ToolMetadata.Contains($field)) {
            $errors.Add("Missing metadata field: $field")
        }
    }

    if ($errors.Count -eq 0) {
        if ([string]::IsNullOrWhiteSpace([string]$ToolMetadata['Id'])) {
            $errors.Add('Tool Id cannot be empty.')
        }
        if ([string]::IsNullOrWhiteSpace([string]$ToolMetadata['Title'])) {
            $errors.Add('Tool Title cannot be empty.')
        }
        if ([string]$ToolMetadata['Type'] -notin @('action', 'assistant')) {
            $errors.Add('Tool Type must be action or assistant.')
        }
        if ([string]$ToolMetadata['RiskLevel'] -notin @('low', 'medium', 'high')) {
            $errors.Add('Tool RiskLevel must be low, medium, or high.')
        }
        if ($ActionName -notin @($ToolMetadata['Actions'])) {
            $errors.Add("Action '$ActionName' is not declared for this tool.")
        }

        $requiredCapabilityFields = @(
            'RequiresAdmin'
            'RequiresInternet'
            'CanReboot'
            'CanModifyRegistry'
            'CanModifyServices'
            'CanInstallSoftware'
            'CanDownload'
            'CanModifyDrivers'
            'CanModifySecurity'
            'CanDeleteFiles'
            'UsesTrustedInstaller'
            'UsesSafeMode'
            'SupportsDefault'
            'SupportsRestore'
            'NeedsExplicitConfirmation'
        )
        $capabilities = $ToolMetadata['Capabilities']
        if ($capabilities -isnot [System.Collections.IDictionary]) {
            $errors.Add('Tool Capabilities must be a dictionary.')
        }
        else {
            foreach ($field in $requiredCapabilityFields) {
                if (-not $capabilities.Contains($field)) {
                    $errors.Add("Missing capability field: $field")
                }
                elseif ($capabilities[$field] -isnot [bool]) {
                    $errors.Add("Capability '$field' must be Boolean.")
                }
            }

            if (
                $capabilities.Contains('NeedsExplicitConfirmation') -and
                [string]$ToolMetadata['RiskLevel'] -eq 'high' -and
                -not [bool]$capabilities['NeedsExplicitConfirmation']
            ) {
                $errors.Add('High-risk tools must require explicit confirmation.')
            }
            if (
                $capabilities.Contains('CanReboot') -and
                $capabilities.Contains('NeedsExplicitConfirmation') -and
                [bool]$capabilities['CanReboot'] -and
                -not [bool]$capabilities['NeedsExplicitConfirmation']
            ) {
                $errors.Add('Tools that can reboot must require explicit confirmation.')
            }
            if (
                $capabilities.Contains('SupportsDefault') -and
                [bool]$capabilities['SupportsDefault'] -and
                'Default' -notin @($ToolMetadata['Actions'])
            ) {
                $errors.Add('SupportsDefault requires a declared Default action.')
            }
            if (
                $capabilities.Contains('SupportsRestore') -and
                [bool]$capabilities['SupportsRestore'] -and
                'Restore' -notin @($ToolMetadata['Actions'])
            ) {
                $errors.Add('SupportsRestore requires a declared Restore action.')
            }
        }
    }

    return [pscustomobject]@{
        IsValid  = ($errors.Count -eq 0)
        Errors   = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function New-BoostLabToolActionResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [string]$ToolId = '',

        [string]$ToolTitle = '',

        [string]$Action = '',

        [Parameter(Mandatory)]
        [string]$Message,

        [bool]$RestartRequired = $false,

        [bool]$Cancelled = $false,

        [AllowNull()]
        [object]$ActionPlan = $null
    )

    return [pscustomobject]@{
        Success         = $Success
        ToolId          = $ToolId
        ToolTitle       = $ToolTitle
        Action          = $Action
        Message         = $Message
        RestartRequired = $RestartRequired
        Cancelled       = $Cancelled
        ActionPlan      = $ActionPlan
        Timestamp       = Get-Date
    }
}

function Invoke-BoostLabImplementedModuleAction {
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$ToolMetadata,

        [Parameter(Mandatory)]
        [string]$ActionName,

        [bool]$Confirmed = $false
    )

    $toolId = [string]$ToolMetadata['Id']
    $toolTitle = [string]$ToolMetadata['Title']

    if (-not $script:BoostLabImplementedToolModules.ContainsKey($toolId)) {
        return $null
    }

    $moduleDefinition = $script:BoostLabImplementedToolModules[$toolId]
    if ($ActionName -notin @($moduleDefinition['Actions'])) {
        return New-BoostLabToolActionResult `
            -Success $false `
            -ToolId $toolId `
            -ToolTitle $toolTitle `
            -Action $ActionName `
            -Message 'Unsupported action for this tool.'
    }

    $modulePath = [string]$moduleDefinition['Path']
    if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
        return New-BoostLabToolActionResult `
            -Success $false `
            -ToolId $toolId `
            -ToolTitle $toolTitle `
            -Action $ActionName `
            -Message 'The approved tool module was not found.'
    }

    $module = $null
    try {
        $module = Import-Module `
            -Name $modulePath `
            -Force `
            -PassThru `
            -Prefix 'SelectedTool' `
            -Scope Local `
            -DisableNameChecking `
            -ErrorAction Stop

        $moduleName = [string]$module.Name
        $infoCommand = Get-Command `
            -Name 'Get-SelectedToolBoostLabToolInfo' `
            -Module $moduleName `
            -ErrorAction Stop
        $compatibilityCommand = Get-Command `
            -Name 'Test-SelectedToolBoostLabToolCompatibility' `
            -Module $moduleName `
            -ErrorAction Stop
        $actionCommand = Get-Command `
            -Name 'Invoke-SelectedToolBoostLabToolAction' `
            -Module $moduleName `
            -ErrorAction Stop

        $moduleInfo = & $infoCommand
        if (
            [string]$moduleInfo.Id -ne $toolId -or
            [string]$moduleInfo.Title -ne $toolTitle -or
            [string]$moduleInfo.Stage -ne [string]$ToolMetadata['Stage'] -or
            $ActionName -notin @($moduleInfo.Actions) -or
            $ActionName -notin @($moduleInfo.ImplementedActions)
        ) {
            return New-BoostLabToolActionResult `
                -Success $false `
                -ToolId $toolId `
                -ToolTitle $toolTitle `
                -Action $ActionName `
                -Message 'The approved tool module metadata did not match the catalog.'
        }

        $compatibility = & $compatibilityCommand
        if (-not [bool]$compatibility.Supported) {
            return New-BoostLabToolActionResult `
                -Success $false `
                -ToolId $toolId `
                -ToolTitle $toolTitle `
                -Action $ActionName `
                -Message ([string]$compatibility.Reason)
        }

        $actionParameters = @{
            ActionName = $ActionName
        }
        if ($actionCommand.Parameters.ContainsKey('Confirmed')) {
            $actionParameters['Confirmed'] = $Confirmed
        }

        return & $actionCommand @actionParameters
    }
    catch {
        return New-BoostLabToolActionResult `
            -Success $false `
            -ToolId $toolId `
            -ToolTitle $toolTitle `
            -Action $ActionName `
            -Message "Module launch failed: $($_.Exception.Message)"
    }
    finally {
        if ($null -ne $module) {
            Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
        }
    }
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$ToolMetadata,

        [Parameter(Mandatory)]
        [string]$ActionName,

        [switch]$RiskConfirmed,

        [AllowNull()]
        [scriptblock]$ConfirmationCallback
    )

    $validation = Test-BoostLabToolMetadata -ToolMetadata $ToolMetadata -ActionName $ActionName
    $toolId = if ($ToolMetadata.Contains('Id')) { [string]$ToolMetadata['Id'] } else { '' }
    $toolTitle = if ($ToolMetadata.Contains('Title')) { [string]$ToolMetadata['Title'] } else { '' }

    if (-not $validation.IsValid) {
        $message = 'Tool metadata validation failed.'
        $result = New-BoostLabToolActionResult `
            -Success $false `
            -ToolId $toolId `
            -ToolTitle $toolTitle `
            -Action $ActionName `
            -Message $message

        Write-BoostLabError `
            -Message $message `
            -Source 'Execution' `
            -EventId 'ToolAction.ValidationFailed' `
            -Data @{
                ToolId = $toolId
                Action = $ActionName
                Errors = $validation.Errors -join '; '
            } | Out-Null

        return $result
    }

    $riskLevel = (Get-Culture).TextInfo.ToTitleCase(([string]$ToolMetadata['RiskLevel']).ToLowerInvariant())
    $isImplementedAction = (
        $script:BoostLabImplementedToolModules.ContainsKey($toolId) -and
        $ActionName -in @($script:BoostLabImplementedToolModules[$toolId]['Actions'])
    )
    $actionPlan = New-BoostLabActionPlan `
        -ToolMetadata $ToolMetadata `
        -ActionName $ActionName `
        -IsDryRun:(-not $isImplementedAction)

    $requiresExecutionConfirmation = (
        $isImplementedAction -and
        [bool]$actionPlan.NeedsExplicitConfirmation -and
        $ActionName -ne 'Analyze'
    )
    $safetyGate = if ($requiresExecutionConfirmation) {
        Test-BoostLabActionPlanExecutionGate `
            -ActionPlan $actionPlan `
            -Confirmed:$RiskConfirmed `
            -ConfirmationCallback $ConfirmationCallback
    }
    else {
        [pscustomobject]@{
            ConfirmationRequired = $false
            Confirmed            = $true
            CallbackUsed         = $false
            CallbackError        = ''
            IsAllowed            = $true
            Message              = if ($isImplementedAction) {
                'This implemented action does not require an execution confirmation.'
            }
            else {
                'Placeholder actions are not executed and do not request confirmation.'
            }
        }
    }

    $isBiosFirmwareOpen = $toolId -eq 'bios-settings' -and $ActionName -eq 'Open'
    if ($requiresExecutionConfirmation -and -not [bool]$safetyGate.IsAllowed) {
        $message = 'Cancelled by user'
        $result = New-BoostLabToolActionResult `
            -Success $false `
            -ToolId $toolId `
            -ToolTitle $toolTitle `
            -Action $ActionName `
            -Message $message `
            -Cancelled $true `
            -ActionPlan $actionPlan

        $cancellationLogMessage = if ($isBiosFirmwareOpen) {
            '[BIOS Settings] [Open] cancelled by user'
        }
        else {
            '[{0}] [{1}] cancelled by user' -f $toolTitle, $ActionName
        }
        Write-BoostLabInfo `
            -Message $cancellationLogMessage `
            -Source 'Execution' `
            -EventId 'ToolAction.Cancelled' `
            -Data @{
                ToolId    = $toolId
                Stage     = [string]$ToolMetadata['Stage']
                RiskLevel = $riskLevel
                CallbackUsed = [bool]$safetyGate.CallbackUsed
            } | Out-Null

        Set-BoostLabToolState `
            -ToolId $toolId `
            -Status 'Cancelled' `
            -LastAction ([pscustomobject]@{
                ToolId      = $toolId
                ToolTitle   = $toolTitle
                Stage       = [string]$ToolMetadata['Stage']
                Action      = $ActionName
                RiskLevel   = $riskLevel
                RequestedAt = $result.Timestamp
            }) `
            -LastResult $result `
            -NoSave | Out-Null
        Set-BoostLabStateValue -Name 'CurrentStatus' -Value 'Cancelled' -NoSave | Out-Null
        Set-BoostLabRestartRequired -Required $false -Reason '' | Out-Null

        return $result
    }

    if ($isBiosFirmwareOpen) {
        Write-BoostLabWarning `
            -Message '[BIOS Settings] [Open] restart to BIOS/UEFI requested' `
            -Source 'Execution' `
            -EventId 'ToolAction.FirmwareRestartRequested' `
            -Data @{
                ToolId    = $toolId
                Stage     = [string]$ToolMetadata['Stage']
                RiskLevel = $riskLevel
                Confirmed = $true
            } | Out-Null
    }

    $moduleResult = Invoke-BoostLabImplementedModuleAction `
        -ToolMetadata $ToolMetadata `
        -ActionName $ActionName `
        -Confirmed:([bool]$safetyGate.Confirmed)
    if ($null -ne $moduleResult) {
        $moduleResult | Add-Member -NotePropertyName 'ActionPlan' -NotePropertyValue $actionPlan -Force
        $implementedModuleDefinition = $script:BoostLabImplementedToolModules[$toolId]
        $actionRecord = [pscustomobject]@{
            ToolId      = $toolId
            ToolTitle   = $toolTitle
            Stage       = [string]$ToolMetadata['Stage']
            Action      = $ActionName
            RiskLevel   = $riskLevel
            RequestedAt = $moduleResult.Timestamp
        }

        if ([bool]$moduleResult.Success) {
            if ($ActionName -eq 'Analyze' -and $null -ne $moduleResult.PSObject.Properties['Data']) {
                $analysis = $moduleResult.Data
                $summary = if ($toolId -eq 'bios-information') {
                    'Motherboard: {0} {1} | BIOS: {2} {3} ({4}) | Secure Boot: {5} | TPM: {6} | CPU: {7} | Windows: {8}' -f `
                        $analysis.MotherboardManufacturer, `
                        $analysis.MotherboardModel, `
                        $analysis.BiosManufacturer, `
                        $analysis.BiosVersion, `
                        $analysis.BiosReleaseDate, `
                        $analysis.SecureBootStatus, `
                        $analysis.TpmStatus, `
                        $analysis.CpuName, `
                        $analysis.WindowsVersion
                }
                elseif ($toolId -eq 'bios-settings') {
                    $guidanceSummary = @($analysis.GuidanceLines) -join [Environment]::NewLine
                    $warningSummary = @($analysis.Warnings) -join [Environment]::NewLine
                    'Original Ultimate BIOS settings guidance:{0}{1}{0}Warnings:{0}{2}' -f `
                        [Environment]::NewLine, `
                        $guidanceSummary, `
                        $warningSummary
                }
                else {
                    [string]$moduleResult.Message
                }

                Write-BoostLabSuccess `
                    -Message ('[{0}] [{1}] {2}' -f $toolTitle, $ActionName, $summary) `
                    -Source 'Execution' `
                    -EventId 'ToolAction.Analyzed' `
                    -Data @{
                        ToolId    = $toolId
                        Stage     = [string]$ToolMetadata['Stage']
                        Module    = [System.IO.Path]::GetFileName([string]$implementedModuleDefinition['Path'])
                        RiskLevel = $riskLevel
                    } | Out-Null
            }
            elseif ($ActionName -eq 'Open' -and -not $isBiosFirmwareOpen) {
                Write-BoostLabSuccess `
                    -Message ('[{0}] [{1}] launched' -f $toolTitle, $ActionName) `
                    -Source 'Execution' `
                    -EventId 'ToolAction.Launched' `
                    -Data @{
                        ToolId    = $toolId
                        Stage     = [string]$ToolMetadata['Stage']
                        Module    = [System.IO.Path]::GetFileName([string]$implementedModuleDefinition['Path'])
                        RiskLevel = $riskLevel
                    } | Out-Null
            }
            elseif (-not $isBiosFirmwareOpen) {
                Write-BoostLabSuccess `
                    -Message ('[{0}] [{1}] {2}' -f $toolTitle, $ActionName, [string]$moduleResult.Message) `
                    -Source 'Execution' `
                    -EventId 'ToolAction.Completed' `
                    -Data @{
                        ToolId    = $toolId
                        Stage     = [string]$ToolMetadata['Stage']
                        Module    = [System.IO.Path]::GetFileName([string]$implementedModuleDefinition['Path'])
                        RiskLevel = $riskLevel
                    } | Out-Null
            }
        }
        else {
            Write-BoostLabError `
                -Message ('[{0}] [{1}] {2}' -f $toolTitle, $ActionName, [string]$moduleResult.Message) `
                -Source 'Execution' `
                -EventId 'ToolAction.Failed' `
                -Data @{
                    ToolId = $toolId
                    Stage  = [string]$ToolMetadata['Stage']
                } | Out-Null
        }

        $status = if ([bool]$moduleResult.Success -and $ActionName -eq 'Analyze') {
            'Analyzed'
        }
        elseif ([bool]$moduleResult.Success -and $isBiosFirmwareOpen) {
            'Restart requested'
        }
        elseif ([bool]$moduleResult.Success -and $ActionName -eq 'Open') {
            'Launched'
        }
        elseif ([bool]$moduleResult.Success) {
            'Completed'
        }
        else {
            'Action failed'
        }
        Set-BoostLabToolState `
            -ToolId $toolId `
            -Status $status `
            -LastAction $actionRecord `
            -LastResult $moduleResult `
            -NoSave | Out-Null
        Set-BoostLabStateValue -Name 'CurrentStatus' -Value $status -NoSave | Out-Null
        Set-BoostLabRestartRequired -Required ([bool]$moduleResult.RestartRequired) -Reason '' | Out-Null

        return $moduleResult
    }

    $message = 'Action not implemented yet'
    $result = New-BoostLabToolActionResult `
        -Success $false `
        -ToolId $toolId `
        -ToolTitle $toolTitle `
        -Action $ActionName `
        -Message $message `
        -RestartRequired $false `
        -ActionPlan $actionPlan

    $actionRecord = [pscustomobject]@{
        ToolId     = $toolId
        ToolTitle  = $toolTitle
        Stage      = [string]$ToolMetadata['Stage']
        Action     = $ActionName
        RiskLevel  = $riskLevel
        RequestedAt = $result.Timestamp
    }

    Write-BoostLabInfo `
        -Message ('[{0}] [{1}] not implemented yet' -f $toolTitle, $ActionName) `
        -Source 'Execution' `
        -EventId 'ToolAction.Placeholder' `
        -Data @{
            ToolId               = $toolId
            Stage                = [string]$ToolMetadata['Stage']
            Type                 = [string]$ToolMetadata['Type']
            RiskLevel            = $riskLevel
            ConfirmationRequired = [bool]$actionPlan.NeedsExplicitConfirmation
            Confirmed            = if ($requiresExecutionConfirmation) {
                [bool]$safetyGate.Confirmed
            }
            else {
                $false
            }
            GateAllowed          = [bool]$safetyGate.IsAllowed
        } | Out-Null

    Set-BoostLabToolState `
        -ToolId $toolId `
        -Status 'Not implemented' `
        -LastAction $actionRecord `
        -LastResult $result `
        -NoSave | Out-Null
    Set-BoostLabStateValue -Name 'CurrentStatus' -Value 'Not implemented' -NoSave | Out-Null
    Set-BoostLabRestartRequired -Required $false -Reason '' | Out-Null

    return $result
}

Export-ModuleMember -Function @(
    'Test-BoostLabToolMetadata'
    'Invoke-BoostLabToolAction'
)
