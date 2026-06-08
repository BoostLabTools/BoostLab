Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $verificationModulePath -Scope Local -Force -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'widgets'; Title = 'Widgets'; Stage = 'Windows'; Order = 7
    Type = 'action'; RiskLevel = 'low'
    Description = 'Disable Windows Widgets or restore the approved default policy behavior.'
    Actions = @('Apply', 'Default')
    Capabilities = [ordered]@{
        RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false
        CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false
        CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false
        CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false
        SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Apply', 'Default')
$script:BoostLabWidgetProcessNames = @('Widgets', 'WidgetService')
$script:BoostLabPolicyManagerPath = 'HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests'
$script:BoostLabDshPolicyPath = 'HKLM\SOFTWARE\Policies\Microsoft\Dsh'
$script:BoostLabPolicyManagerProviderPath = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests'
$script:BoostLabDshPolicyProviderPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'

function Test-BoostLabAdministrator {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function New-BoostLabWidgetsResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$Message,

        [bool]$Cancelled = $false,

        [AllowNull()]
        [object]$Data = $null,

        [AllowNull()]
        [object]$VerificationResult = $null
    )

    return [pscustomobject]@{
        Success         = $Success
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        Action          = $Action
        Message         = $Message
        RestartRequired = $false
        Cancelled       = $Cancelled
        Timestamp       = Get-Date
        Data            = $Data
        VerificationResult = $VerificationResult
    }
}

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        Id                 = [string]$script:BoostLabToolMetadata['Id']
        Title              = [string]$script:BoostLabToolMetadata['Title']
        Stage              = [string]$script:BoostLabToolMetadata['Stage']
        Order              = [int]$script:BoostLabToolMetadata['Order']
        Type               = [string]$script:BoostLabToolMetadata['Type']
        RiskLevel          = [string]$script:BoostLabToolMetadata['RiskLevel']
        Description        = [string]$script:BoostLabToolMetadata['Description']
        Actions            = @($script:BoostLabToolMetadata['Actions'])
        Capabilities       = [pscustomobject]$script:BoostLabToolMetadata['Capabilities']
        ImplementedActions = @($script:BoostLabImplementedActions)
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $isWindows = $env:OS -eq 'Windows_NT'
    return [pscustomobject]@{
        Supported = $isWindows
        ToolId    = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason    = if ($isWindows) {
            'Windows registry policy commands are available for action-specific checks.'
        }
        else {
            'Widgets requires Windows.'
        }
        Timestamp = Get-Date
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        Status          = 'Ready'
        LastAction      = $null
        LastResult      = $null
        RestartRequired = $false
        Timestamp       = Get-Date
    }
}

function Invoke-BoostLabWidgetsRegistryCommand {
    param(
        [Parameter(Mandatory)]
        [string]$CommandProcessorPath,

        [Parameter(Mandatory)]
        [string]$CommandText,

        [Parameter(Mandatory)]
        [string]$Description
    )

    $output = & $CommandProcessorPath /c $CommandText 2>&1
    if ($LASTEXITCODE -ne 0) {
        $detail = (@($output) -join ' ').Trim()
        if ([string]::IsNullOrWhiteSpace($detail)) {
            $detail = "reg.exe returned exit code $LASTEXITCODE."
        }

        throw "$Description failed: $detail"
    }
}

function Get-BoostLabWidgetsRegistryValue {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name
    )

    try {
        if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
            return [pscustomobject]@{
                ReadSucceeded = $true
                KeyExists     = $false
                Exists        = $false
                Value         = $null
                DisplayValue  = 'Absent'
                Message       = 'Registry path is absent.'
            }
        }

        $item = Get-ItemProperty -LiteralPath $Path -ErrorAction Stop
        $property = $item.PSObject.Properties[$Name]
        if ($null -eq $property) {
            return [pscustomobject]@{
                ReadSucceeded = $true
                KeyExists     = $true
                Exists        = $false
                Value         = $null
                DisplayValue  = 'Absent'
                Message       = 'Registry value is absent.'
            }
        }

        return [pscustomobject]@{
            ReadSucceeded = $true
            KeyExists     = $true
            Exists        = $true
            Value         = $property.Value
            DisplayValue  = [string]$property.Value
            Message       = 'Registry value detected.'
        }
    }
    catch {
        return [pscustomobject]@{
            ReadSucceeded = $false
            KeyExists     = $null
            Exists        = $false
            Value         = $null
            DisplayValue  = 'Unknown'
            Message       = $_.Exception.Message
        }
    }
}

function Get-BoostLabWidgetsProcessState {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    try {
        $processes = @([System.Diagnostics.Process]::GetProcessesByName($Name))
        return [pscustomobject]@{
            ReadSucceeded = $true
            IsRunning     = $processes.Count -gt 0
            DisplayValue  = if ($processes.Count -gt 0) { 'Running' } else { 'Not running' }
            Message       = if ($processes.Count -gt 0) {
                "$Name is running."
            }
            else {
                "$Name is not running."
            }
        }
    }
    catch {
        return [pscustomobject]@{
            ReadSucceeded = $false
            IsRunning     = $null
            DisplayValue  = 'Unknown'
            Message       = $_.Exception.Message
        }
    }
}

function Test-BoostLabWidgetsState {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [AllowNull()]
        [scriptblock]$RegistryReader = $null,

        [AllowNull()]
        [scriptblock]$ProcessReader = $null
    )

    $readRegistry = if ($null -ne $RegistryReader) {
        $RegistryReader
    }
    else {
        { param($Path, $Name) Get-BoostLabWidgetsRegistryValue -Path $Path -Name $Name }
    }
    $readProcess = if ($null -ne $ProcessReader) {
        $ProcessReader
    }
    else {
        { param($Name) Get-BoostLabWidgetsProcessState -Name $Name }
    }

    $policyManager = & $readRegistry $script:BoostLabPolicyManagerProviderPath 'value'
    $dshPolicy = & $readRegistry $script:BoostLabDshPolicyProviderPath 'AllowNewsAndInterests'
    $widgetsProcess = & $readProcess 'Widgets'
    $widgetServiceProcess = & $readProcess 'WidgetService'
    $checks = [System.Collections.Generic.List[object]]::new()

    $expectedPolicyManagerValue = if ($ActionName -eq 'Apply') { 0 } else { 1 }
    $policyManagerStatus = if (-not [bool]$policyManager.ReadSucceeded) {
        'Warning'
    }
    elseif (
        -not [bool]$policyManager.Exists -or
        [string]$policyManager.Value -ne [string]$expectedPolicyManagerValue
    ) {
        'Failed'
    }
    else {
        'Passed'
    }
    $checks.Add(
        (New-BoostLabVerificationCheck `
            -Name 'PolicyManager value' `
            -Expected $expectedPolicyManagerValue `
            -Actual ([string]$policyManager.DisplayValue) `
            -Status $policyManagerStatus `
            -Message ([string]$policyManager.Message))
    )

    if ($ActionName -eq 'Apply') {
        $dshStatus = if (-not [bool]$dshPolicy.ReadSucceeded) {
            'Warning'
        }
        elseif (-not [bool]$dshPolicy.Exists -or [string]$dshPolicy.Value -ne '0') {
            'Failed'
        }
        else {
            'Passed'
        }
        $dshExpected = 'AllowNewsAndInterests = 0'
    }
    else {
        $dshStatus = if (-not [bool]$dshPolicy.ReadSucceeded) {
            'Warning'
        }
        elseif ([bool]$dshPolicy.Exists -and [string]$dshPolicy.Value -eq '0') {
            'Failed'
        }
        else {
            'Passed'
        }
        $dshExpected = 'Absent or not set to 0'
    }
    $checks.Add(
        (New-BoostLabVerificationCheck `
            -Name 'Dsh policy state' `
            -Expected $dshExpected `
            -Actual ([string]$dshPolicy.DisplayValue) `
            -Status $dshStatus `
            -Message ([string]$dshPolicy.Message))
    )

    foreach ($processState in @(
        [pscustomobject]@{ Name = 'Widgets process state'; Value = $widgetsProcess }
        [pscustomobject]@{ Name = 'WidgetService process state'; Value = $widgetServiceProcess }
    )) {
        if ($ActionName -eq 'Default') {
            $processStatus = 'NotApplicable'
            $processExpected = 'Informational only'
        }
        elseif (-not [bool]$processState.Value.ReadSucceeded) {
            $processStatus = 'Warning'
            $processExpected = 'Not running'
        }
        elseif ([bool]$processState.Value.IsRunning) {
            $processStatus = 'Failed'
            $processExpected = 'Not running'
        }
        else {
            $processStatus = 'Passed'
            $processExpected = 'Not running'
        }

        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name $processState.Name `
                -Expected $processExpected `
                -Actual ([string]$processState.Value.DisplayValue) `
                -Status $processStatus `
                -Message ([string]$processState.Value.Message))
        )
    }

    $overallStatus = if (@($checks | Where-Object { $_.Status -eq 'Failed' }).Count -gt 0) {
        'Failed'
    }
    elseif (@($checks | Where-Object { $_.Status -eq 'Warning' }).Count -gt 0) {
        'Warning'
    }
    else {
        'Passed'
    }
    $expectedState = [pscustomobject]@{
        PolicyManagerValue      = $expectedPolicyManagerValue
        DshPolicyState          = $dshExpected
        WidgetsProcessState     = if ($ActionName -eq 'Apply') { 'Not running' } else { 'Informational only' }
        WidgetServiceProcessState = if ($ActionName -eq 'Apply') { 'Not running' } else { 'Informational only' }
    }
    $detectedState = [pscustomobject]@{
        PolicyManagerValue      = [string]$policyManager.DisplayValue
        DshPolicyState          = [string]$dshPolicy.DisplayValue
        WidgetsProcessState     = [string]$widgetsProcess.DisplayValue
        WidgetServiceProcessState = [string]$widgetServiceProcess.DisplayValue
    }
    $message = switch ($overallStatus) {
        'Passed' { 'The expected Widgets state was detected.' }
        'Warning' { 'Widgets commands completed, but part of the resulting state could not be confirmed.' }
        default { 'The detected Widgets state does not match the expected result.' }
    }

    return New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $ActionName `
        -Status $overallStatus `
        -ExpectedState $expectedState `
        -DetectedState $detectedState `
        -Checks $checks.ToArray() `
        -Message $message
}

function New-BoostLabWidgetsRegistryOperations {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [AllowNull()]
        [object]$DshPolicyState = $null
    )

    if ($ActionName -eq 'Apply') {
        return @(
            [pscustomobject]@{
                Description = 'Set PolicyManager AllowNewsAndInterests value to 0'
                Command = 'reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" /v "value" /t REG_DWORD /d "0" /f'
                Skip = $false
                SkipMessage = ''
            }
            [pscustomobject]@{
                Description = 'Set Dsh AllowNewsAndInterests value to 0'
                Command = 'reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d "0" /f'
                Skip = $false
                SkipMessage = ''
            }
        )
    }

    $skipDshDelete = (
        $null -ne $DshPolicyState -and
        [bool]$DshPolicyState.ReadSucceeded -and
        -not [bool]$DshPolicyState.Exists
    )
    return @(
        [pscustomobject]@{
            Description = 'Set PolicyManager AllowNewsAndInterests value to 1'
            Command = 'reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" /v "value" /t REG_DWORD /d "1" /f'
            Skip = $false
            SkipMessage = ''
        }
        [pscustomobject]@{
            Description = 'Remove the Dsh Widgets blocking policy key'
            Command = 'reg delete "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /f'
            Skip = $skipDshDelete
            SkipMessage = if ($skipDshDelete) {
                'Dsh Widgets blocking policy is already absent.'
            }
            else {
                ''
            }
        }
    )
}

function Test-BoostLabWidgetsAlreadyDefault {
    param(
        [AllowNull()]
        [object]$PolicyManagerState,

        [AllowNull()]
        [object]$DshPolicyState
    )

    return (
        $null -ne $PolicyManagerState -and
        [bool]$PolicyManagerState.ReadSucceeded -and
        [bool]$PolicyManagerState.Exists -and
        [string]$PolicyManagerState.Value -eq '1' -and
        $null -ne $DshPolicyState -and
        [bool]$DshPolicyState.ReadSucceeded -and
        (
            -not [bool]$DshPolicyState.Exists -or
            [string]$DshPolicyState.Value -ne '0'
        )
    )
}

function Invoke-BoostLabWidgetsAction {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName
    )

    if (-not (Test-BoostLabAdministrator)) {
        return New-BoostLabWidgetsResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Administrator rights are required to change Widgets policy.'
    }
    if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        return New-BoostLabWidgetsResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Widgets policy could not be changed because the Windows system directory is unavailable.'
    }

    $commandProcessorPath = Join-Path $env:SystemRoot 'System32\cmd.exe'
    if (-not (Test-Path -LiteralPath $commandProcessorPath -PathType Leaf)) {
        return New-BoostLabWidgetsResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Widgets policy could not be changed because cmd.exe was not found.'
    }

    $defaultPolicyManagerState = $null
    $defaultDshPolicyState = $null
    if ($ActionName -eq 'Default') {
        $defaultPolicyManagerState = Get-BoostLabWidgetsRegistryValue `
            -Path $script:BoostLabPolicyManagerProviderPath `
            -Name 'value'
        $defaultDshPolicyState = Get-BoostLabWidgetsRegistryValue `
            -Path $script:BoostLabDshPolicyProviderPath `
            -Name 'AllowNewsAndInterests'
    }
    $registryOperations = New-BoostLabWidgetsRegistryOperations `
        -ActionName $ActionName `
        -DshPolicyState $defaultDshPolicyState

    $registryChangesAttempted = [System.Collections.Generic.List[string]]::new()
    $registryChangesCompleted = [System.Collections.Generic.List[string]]::new()
    $registryChangesSkipped = [System.Collections.Generic.List[string]]::new()
    $processesStopped = [System.Collections.Generic.List[string]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()

    foreach ($operation in $registryOperations) {
        if ([bool]$operation.Skip) {
            $registryChangesSkipped.Add([string]$operation.SkipMessage)
            continue
        }

        $registryChangesAttempted.Add([string]$operation.Description)
        try {
            Invoke-BoostLabWidgetsRegistryCommand `
                -CommandProcessorPath $commandProcessorPath `
                -CommandText ([string]$operation.Command) `
                -Description ([string]$operation.Description)
            $registryChangesCompleted.Add([string]$operation.Description)
        }
        catch {
            $errors.Add($_.Exception.Message)
        }
    }

    if ($ActionName -eq 'Apply') {
        foreach ($processName in $script:BoostLabWidgetProcessNames) {
            $runningProcesses = @(Get-Process -Name $processName -ErrorAction SilentlyContinue)
            if ($runningProcesses.Count -eq 0) {
                continue
            }

            try {
                Stop-Process -Force -Name $processName -ErrorAction Stop
                $processesStopped.Add($processName)
            }
            catch {
                if (@(Get-Process -Name $processName -ErrorAction SilentlyContinue).Count -gt 0) {
                    $errors.Add("Stopping $processName failed: $($_.Exception.Message)")
                }
            }
        }
    }

    $completedAt = Get-Date
    $verificationResult = Test-BoostLabWidgetsState -ActionName $ActionName
    $data = [pscustomobject]@{
        RegistryChangesAttempted = $registryChangesAttempted.ToArray()
        RegistryChangesCompleted = $registryChangesCompleted.ToArray()
        RegistryChangesSkipped   = $registryChangesSkipped.ToArray()
        ProcessesStopped         = $processesStopped.ToArray()
        CompletedAt              = $completedAt
    }

    if ($errors.Count -gt 0) {
        return New-BoostLabWidgetsResult `
            -Success $false `
            -Action $ActionName `
            -Message ("Widgets action completed with errors: {0}" -f ($errors -join '; ')) `
            -Data $data `
            -VerificationResult $verificationResult
    }

    $wasAlreadyDefault = (
        $ActionName -eq 'Default' -and
        (Test-BoostLabWidgetsAlreadyDefault `
            -PolicyManagerState $defaultPolicyManagerState `
            -DshPolicyState $defaultDshPolicyState)
    )
    $message = if ($ActionName -eq 'Apply') {
        'Widgets disabled.'
    }
    elseif ($wasAlreadyDefault) {
        'Widgets already default.'
    }
    else {
        'Widgets restored to default.'
    }
    return New-BoostLabWidgetsResult `
        -Success $true `
        -Action $ActionName `
        -Message $message `
        -Data $data `
        -VerificationResult $verificationResult
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ActionName,

        [bool]$Confirmed = $false
    )

    if ($ActionName -notin @($script:BoostLabImplementedActions)) {
        return New-BoostLabWidgetsResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Unsupported action. Only Apply and Default are allowed.'
    }
    if (-not $Confirmed) {
        return New-BoostLabWidgetsResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    return Invoke-BoostLabWidgetsAction -ActionName $ActionName
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [bool]$Confirmed = $false
    )

    return Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed:$Confirmed
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
