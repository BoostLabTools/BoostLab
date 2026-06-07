Set-StrictMode -Version Latest

$script:BoostLabModulesRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'modules'
$script:BoostLabImplementedToolModules = @{
    'startup-apps-settings' = Join-Path $script:BoostLabModulesRoot 'Setup\StartupAppsSettings.psm1'
    'startup-apps-task-manager' = Join-Path $script:BoostLabModulesRoot 'Setup\StartupAppsTaskManager.psm1'
    'graphics-configuration-center' = Join-Path $script:BoostLabModulesRoot 'Graphics\GraphicsConfigurationCenter.psm1'
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

        [bool]$RestartRequired = $false
    )

    return [pscustomobject]@{
        Success         = $Success
        ToolId          = $ToolId
        ToolTitle       = $ToolTitle
        Action          = $Action
        Message         = $Message
        RestartRequired = $RestartRequired
        Timestamp       = Get-Date
    }
}

function Invoke-BoostLabImplementedModuleAction {
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$ToolMetadata,

        [Parameter(Mandatory)]
        [string]$ActionName
    )

    $toolId = [string]$ToolMetadata['Id']
    $toolTitle = [string]$ToolMetadata['Title']

    if (-not $script:BoostLabImplementedToolModules.ContainsKey($toolId)) {
        return $null
    }

    if ($ActionName -ne 'Open') {
        return New-BoostLabToolActionResult `
            -Success $false `
            -ToolId $toolId `
            -ToolTitle $toolTitle `
            -Action $ActionName `
            -Message 'Unsupported action. Only Open is allowed.'
    }

    $modulePath = [string]$script:BoostLabImplementedToolModules[$toolId]
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

        return & $actionCommand -ActionName $ActionName
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

        [switch]$RiskConfirmed
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
    $safetyGate = if ($riskLevel -eq 'High') {
        Test-BoostLabHighRiskActionGate `
            -ToolId $toolId `
            -ToolTitle $toolTitle `
            -Action $ActionName `
            -RiskLevel $riskLevel `
            -Confirmed:$RiskConfirmed
    }
    else {
        [pscustomobject]@{
            IsHighRisk           = $false
            ConfirmationRequired = $false
            Confirmed            = $true
            IsAllowed            = $true
            Message              = 'High-risk safety gate is not required.'
        }
    }

    $moduleResult = Invoke-BoostLabImplementedModuleAction `
        -ToolMetadata $ToolMetadata `
        -ActionName $ActionName
    if ($null -ne $moduleResult) {
        $actionRecord = [pscustomobject]@{
            ToolId      = $toolId
            ToolTitle   = $toolTitle
            Stage       = [string]$ToolMetadata['Stage']
            Action      = $ActionName
            RiskLevel   = $riskLevel
            RequestedAt = $moduleResult.Timestamp
        }

        if ([bool]$moduleResult.Success) {
            Write-BoostLabSuccess `
                -Message ('[{0}] [{1}] launched' -f $toolTitle, $ActionName) `
                -Source 'Execution' `
                -EventId 'ToolAction.Launched' `
                -Data @{
                    ToolId    = $toolId
                    Stage     = [string]$ToolMetadata['Stage']
                    Module    = [System.IO.Path]::GetFileName([string]$script:BoostLabImplementedToolModules[$toolId])
                    RiskLevel = $riskLevel
                } | Out-Null
        }
        else {
            Write-BoostLabError `
                -Message ('[{0}] [{1}] {2}' -f $toolTitle, $ActionName, [string]$moduleResult.Message) `
                -Source 'Execution' `
                -EventId 'ToolAction.LaunchFailed' `
                -Data @{
                    ToolId = $toolId
                    Stage  = [string]$ToolMetadata['Stage']
                } | Out-Null
        }

        $status = if ([bool]$moduleResult.Success) { 'Launched' } else { 'Launch failed' }
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
        -RestartRequired $false

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
            ConfirmationRequired = [bool]$safetyGate.ConfirmationRequired
            Confirmed            = [bool]$safetyGate.Confirmed
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
