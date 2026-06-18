Set-StrictMode -Version Latest

$script:BoostLabModulesRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'modules'
if (-not (Get-Command -Name 'New-BoostLabActionPlan' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path $PSScriptRoot 'ActionPlan.psm1') -Scope Local -Force -ErrorAction Stop
}
if (-not (Get-Command -Name 'Test-BoostLabActionPlanExecutionGate' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path $PSScriptRoot 'Safety.psm1') -Scope Local -Force -ErrorAction Stop
}
Import-Module `
    -Name (Join-Path $PSScriptRoot 'Verification.psm1') `
    -Scope Local `
    -ErrorAction Stop
if (-not (Get-Command -Name 'Test-BoostLabAdministrator' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path $PSScriptRoot 'Environment.psm1') -Scope Local -Force -ErrorAction Stop
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
    'to-bios' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Refresh\to-bios.psm1'
        Actions = @('Analyze', 'Open')
    }
    'unattended' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Refresh\unattended.psm1'
        Actions = @('Analyze', 'Apply')
    }
    'startup-apps-settings' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Setup\StartupAppsSettings.psm1'
        Actions = @('Open')
    }
    'startup-apps-task-manager' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Setup\StartupAppsTaskManager.psm1'
        Actions = @('Open')
    }
    'memory-compression' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Setup\MemoryCompression.psm1'
        Actions = @('Apply', 'Default')
    }
    'background-apps' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Setup\BackgroundApps.psm1'
        Actions = @('Apply', 'Default')
    }
    'store-settings' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Setup\StoreSettings.psm1'
        Actions = @('Apply', 'Default')
    }
    'updates-pause' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Setup\UpdatesPause.psm1'
        Actions = @('Apply', 'Default')
    }
    'bitlocker' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Setup\bitlocker.psm1'
        Actions = @('Analyze', 'Apply', 'Default', 'Restore', 'Open')
    }
    'driver-clean' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Graphics\driver-clean.psm1'
        Actions = @('Analyze', 'Open', 'Apply')
    }
    'driver-install-latest' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Graphics\driver-install-latest.psm1'
        Actions = @('Analyze', 'Open', 'Apply')
    }
    'nvidia-settings' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Graphics\nvidia-settings.psm1'
        Actions = @('Analyze', 'Open', 'Apply')
    }
    'hdcp' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Graphics\hdcp.psm1'
        Actions = @('Analyze', 'Apply', 'Default', 'Restore')
    }
    'p0-state' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Graphics\p0-state.psm1'
        Actions = @('Analyze', 'Apply', 'Default', 'Restore')
    }
    'msi-mode' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Graphics\msi-mode.psm1'
        Actions = @('Analyze', 'Apply', 'Default', 'Restore')
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
    'widgets' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Windows\Widgets.psm1'
        Actions = @('Apply', 'Default')
    }
    'restore-point' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Windows\RestorePoint.psm1'
        Actions = @('Apply', 'Open')
    }
    'theme-black' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Windows\ThemeBlack.psm1'
        Actions = @('Apply', 'Default')
    }
    'start-menu-layout' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Windows\StartMenuLayout.psm1'
        Actions = @('Apply', 'Default')
    }
    'context-menu' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Windows\ContextMenu.psm1'
        Actions = @('Apply', 'Default')
    }
    'signout-lockscreen-wallpaper-black' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Windows\SignoutLockScreenWallpaperBlack.psm1'
        Actions = @('Apply', 'Default')
    }
    'user-account-pictures-black' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Windows\user-account-pictures-black.psm1'
        Actions = @('Apply', 'Default')
    }
    'notepad-settings' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Windows\notepad-settings.psm1'
        Actions = @('Apply', 'Default')
    }
    'device-manager-power-savings-wake' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Windows\device-manager-power-savings-wake.psm1'
        Actions = @('Apply', 'Default')
    }
    'network-adapter-power-savings-wake' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Windows\NetworkAdapterPowerSavingsWake.psm1'
        Actions = @('Apply', 'Default')
    }
    'write-cache-buffer-flushing' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Windows\write-cache-buffer-flushing.psm1'
        Actions = @('Analyze', 'Apply')
    }
    'power-plan' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Windows\PowerPlan.psm1'
        Actions = @('Apply', 'Default')
    }
    'spectre-meltdown-assistant' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Advanced\spectre-meltdown-assistant.psm1'
        Actions = @('Analyze', 'Apply', 'Default')
    }
    'mmagent-assistant' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Advanced\mmagent-assistant.psm1'
        Actions = @('Analyze', 'Apply', 'Default')
    }
    'smt-ht-assistant' = @{
        Path    = Join-Path $script:BoostLabModulesRoot 'Advanced\smt-ht-assistant.psm1'
        Actions = @('Analyze', 'Apply', 'Open')
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
                $capabilities.Contains('UsesTrustedInstaller') -and
                $capabilities.Contains('NeedsExplicitConfirmation') -and
                [bool]$capabilities['UsesTrustedInstaller'] -and
                -not [bool]$capabilities['NeedsExplicitConfirmation']
            ) {
                $errors.Add('Tools that use TrustedInstaller must require explicit confirmation.')
            }
            if (
                $capabilities.Contains('UsesSafeMode') -and
                $capabilities.Contains('NeedsExplicitConfirmation') -and
                [bool]$capabilities['UsesSafeMode'] -and
                -not [bool]$capabilities['NeedsExplicitConfirmation']
            ) {
                $errors.Add('Tools that use Safe Mode must require explicit confirmation.')
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

function New-BoostLabWriteCacheUnsupportedScopeRuntimeResult {
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ToolTitle,

        [Parameter(Mandatory)]
        [string]$ActionName,

        [Parameter(Mandatory)]
        [string]$Message
    )

    $verification = New-BoostLabVerificationResult `
        -ToolId $ToolId `
        -ToolTitle $ToolTitle `
        -Action $ActionName `
        -Status 'NotApplicable' `
        -ExpectedState 'Windows host for shared storage optimization behavior' `
        -DetectedState 'Unsupported host for this Windows storage tool' `
        -Checks @(
            New-BoostLabVerificationCheck `
                -Name 'Product scope' `
                -Expected 'Windows host for shared source behavior' `
                -Actual 'Unsupported host for Write Cache Buffer Flushing' `
                -Status 'NotApplicable' `
                -Message $Message
        ) `
        -Message $Message

    return [pscustomobject]@{
        Success            = $true
        Status             = 'NotApplicable'
        ToolId             = $ToolId
        ToolTitle          = $ToolTitle
        Action             = $ActionName
        Message            = $Message
        RestartRequired    = $false
        Cancelled          = $false
        Errors             = @()
        Data               = [pscustomobject]@{
            SupportedProductScope  = $false
            CommandStatus          = 'Not applicable'
            VerificationStatus     = 'NotApplicable'
            ChangesExecuted        = $false
            TargetDiscoveryRun     = $false
            CaptureAttempted       = $false
            RegistryWriteAttempted = $false
            Errors                 = @()
        }
        VerificationResult = $verification
        Timestamp          = Get-Date
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
            if ($toolId -eq 'write-cache-buffer-flushing') {
                return New-BoostLabWriteCacheUnsupportedScopeRuntimeResult `
                    -ToolId $toolId `
                    -ToolTitle $toolTitle `
                    -ActionName $ActionName `
                    -Message ([string]$compatibility.Reason)
            }

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

    if (
        $isImplementedAction -and
        [bool]$actionPlan.RequiresAdmin -and
        -not (Test-BoostLabAdministrator)
    ) {
        $message = 'Administrator rights are required. Relaunch BoostLab through bootstrap.ps1.'
        $result = New-BoostLabToolActionResult `
            -Success $false `
            -ToolId $toolId `
            -ToolTitle $toolTitle `
            -Action $ActionName `
            -Message $message `
            -ActionPlan $actionPlan

        Write-BoostLabError `
            -Message ('[{0}] [{1}] blocked because BoostLab is not running as Administrator' -f $toolTitle, $ActionName) `
            -Source 'Execution' `
            -EventId 'ToolAction.AdministratorRequired' `
            -Data @{
                ToolId        = $toolId
                Stage         = [string]$ToolMetadata['Stage']
                RequiresAdmin = $true
            } | Out-Null

        Set-BoostLabToolState `
            -ToolId $toolId `
            -Status 'Administrator required' `
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
        Set-BoostLabStateValue -Name 'CurrentStatus' -Value 'Administrator required' -NoSave | Out-Null
        Set-BoostLabRestartRequired -Required $false -Reason '' | Out-Null

        return $result
    }

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

    $isBiosFirmwareOpen = $toolId -in @('bios-settings', 'to-bios') -and $ActionName -eq 'Open'
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

        $cancellationLogMessage = if ($toolId -eq 'bios-settings' -and $isBiosFirmwareOpen) {
            '[BIOS Settings] [Open] cancelled by user'
        }
        elseif ($toolId -eq 'to-bios' -and $isBiosFirmwareOpen) {
            '[To BIOS] [Open] cancelled by user'
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
        $firmwareLogMessage = if ($toolId -eq 'bios-settings') {
            '[BIOS Settings] [Open] restart to BIOS/UEFI requested'
        }
        else {
            '[To BIOS] [Open] restart to BIOS/UEFI requested'
        }
        Write-BoostLabWarning `
            -Message $firmwareLogMessage `
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
        $verificationResult = if ($null -ne $moduleResult.PSObject.Properties['VerificationResult']) {
            $moduleResult.VerificationResult
        }
        else {
            $null
        }
        if ($null -ne $verificationResult) {
            $verificationValidation = $null
            try {
                $verificationValidation = Test-BoostLabVerificationResult `
                    -VerificationResult $verificationResult `
                    -ExpectedToolId $toolId `
                    -ExpectedToolTitle $toolTitle `
                    -ExpectedAction $ActionName
            }
            catch {
                $verificationFailureMessage = "Verification contract validation failed: $($_.Exception.Message)"
                $verificationResult = [pscustomobject]@{
                    ToolId        = $toolId
                    ToolTitle     = $toolTitle
                    Action        = $ActionName
                    Status        = 'Failed'
                    ExpectedState = 'A callable BoostLab verification contract validator.'
                    DetectedState = $_.Exception.Message
                    Checks        = @(
                        [pscustomobject]@{
                            Name     = 'Verification runtime'
                            Expected = 'Test-BoostLabVerificationResult is imported and callable'
                            Actual   = $_.Exception.Message
                            Status   = 'Failed'
                            Message  = $verificationFailureMessage
                        }
                    )
                    Message       = $verificationFailureMessage
                    Timestamp     = Get-Date
                }
                $moduleResult | Add-Member `
                    -NotePropertyName 'VerificationResult' `
                    -NotePropertyValue $verificationResult `
                    -Force
                $moduleResult | Add-Member `
                    -NotePropertyName 'Success' `
                    -NotePropertyValue $false `
                    -Force
                $moduleResult | Add-Member `
                    -NotePropertyName 'Message' `
                    -NotePropertyValue $verificationFailureMessage `
                    -Force

                Write-BoostLabError `
                    -Message ('[{0}] [{1}] {2}' -f $toolTitle, $ActionName, $verificationFailureMessage) `
                    -Source 'Execution' `
                    -EventId 'ToolAction.VerificationRuntimeFailed' `
                    -Data @{
                        ToolId = $toolId
                        Error  = $_.Exception.Message
                    } | Out-Null
            }

            if ($null -ne $verificationValidation -and -not $verificationValidation.IsValid) {
                $verificationResult = New-BoostLabVerificationResult `
                    -ToolId $toolId `
                    -ToolTitle $toolTitle `
                    -Action $ActionName `
                    -Status 'Failed' `
                    -ExpectedState 'A valid BoostLab VerificationResult object.' `
                    -DetectedState ($verificationValidation.Errors -join '; ') `
                    -Checks @(
                        New-BoostLabVerificationCheck `
                            -Name 'Verification contract' `
                            -Expected 'Valid schema and matching tool/action identity' `
                            -Actual 'Invalid verification object' `
                            -Status 'Failed' `
                            -Message ($verificationValidation.Errors -join '; ')
                    ) `
                    -Message 'Post-action verification returned an invalid result.'
                $moduleResult | Add-Member `
                    -NotePropertyName 'VerificationResult' `
                    -NotePropertyValue $verificationResult `
                    -Force

                Write-BoostLabWarning `
                    -Message ('[{0}] [{1}] verification contract failed' -f $toolTitle, $ActionName) `
                    -Source 'Execution' `
                    -EventId 'ToolAction.VerificationContractFailed' `
                    -Data @{
                        ToolId = $toolId
                        Errors = $verificationValidation.Errors -join '; '
                    } | Out-Null
            }
        }
        $implementedModuleDefinition = $script:BoostLabImplementedToolModules[$toolId]
        $actionRecord = [pscustomobject]@{
            ToolId      = $toolId
            ToolTitle   = $toolTitle
            Stage       = [string]$ToolMetadata['Stage']
            Action      = $ActionName
            RiskLevel   = $riskLevel
            RequestedAt = $moduleResult.Timestamp
        }

        $moduleStatus = if ($null -ne $moduleResult.PSObject.Properties['Status']) {
            [string]$moduleResult.Status
        }
        else {
            ''
        }
        if ($moduleStatus -eq 'NotApplicable') {
            Write-BoostLabInfo `
                -Message ('[{0}] [{1}] {2}' -f $toolTitle, $ActionName, [string]$moduleResult.Message) `
                -Source 'Execution' `
                -EventId 'ToolAction.NotApplicable' `
                -Data @{
                    ToolId = $toolId
                    Stage = [string]$ToolMetadata['Stage']
                    VerificationStatus = 'NotApplicable'
                } | Out-Null
        }
        elseif ([bool]$moduleResult.Success) {
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
                        VerificationStatus = if ($null -ne $verificationResult) {
                            [string]$verificationResult.Status
                        }
                        else {
                            'NotApplicable'
                        }
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
                        VerificationStatus = if ($null -ne $verificationResult) {
                            [string]$verificationResult.Status
                        }
                        else {
                            'NotApplicable'
                        }
                    } | Out-Null
            }
        }
        else {
            Write-BoostLabError `
                -Message ('[{0}] [{1}] {2}' -f $toolTitle, $ActionName, [string]$moduleResult.Message) `
                -Source 'Execution' `
                -EventId 'ToolAction.Failed' `
                -Data @{
                    ToolId             = $toolId
                    Stage              = [string]$ToolMetadata['Stage']
                    VerificationStatus = if ($null -ne $verificationResult) {
                        [string]$verificationResult.Status
                    }
                    else {
                        'NotApplicable'
                    }
                } | Out-Null
        }

        $status = if ($moduleStatus -eq 'NotApplicable') {
            'Not applicable'
        }
        elseif ([bool]$moduleResult.Success -and $ActionName -eq 'Analyze') {
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
