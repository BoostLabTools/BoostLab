Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'spectre-meltdown-assistant'
    Title = 'Spectre / Meltdown Assistant'
    Stage = 'Advanced'
    Order = 1
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Analyze mitigation state and explain security and performance tradeoffs.'
    Actions = @('Analyze', 'Apply', 'Default')
    Capabilities = [ordered]@{
        RequiresAdmin = $true
        RequiresInternet = $false
        CanReboot = $false
        CanModifyRegistry = $true
        CanModifyServices = $false
        CanInstallSoftware = $false
        CanDownload = $false
        CanModifyDrivers = $false
        CanModifySecurity = $true
        CanDeleteFiles = $false
        UsesTrustedInstaller = $false
        UsesSafeMode = $false
        SupportsDefault = $true
        SupportsRestore = $false
        NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Analyze', 'Apply', 'Default')
$script:BoostLabMitigationRegistryPath = 'HKLM:\SYSTEM\ControlSet001\Control\Session Manager\Memory Management'
$script:BoostLabMitigationNativeRegistryPath = 'HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\Memory Management'
$script:BoostLabMitigationValueNames = @(
    'FeatureSettingsOverrideMask'
    'FeatureSettingsOverride'
)
$script:BoostLabApplyCommands = @(
    'reg add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /t REG_DWORD /d "3" /f'
    'reg add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /t REG_DWORD /d "3" /f'
)
$script:BoostLabDefaultCommands = @(
    'reg delete "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /f'
    'reg delete "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /f'
)

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

function Get-BoostLabSpectrePropertyValue {
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$Name,

        [AllowNull()]
        [object]$DefaultValue = $null
    )

    if ($null -eq $InputObject) {
        return $DefaultValue
    }
    if ($InputObject -is [System.Collections.IDictionary]) {
        if ($InputObject.Contains($Name)) {
            return $InputObject[$Name]
        }
        return $DefaultValue
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $DefaultValue
    }
    return $property.Value
}

function Get-BoostLabSpectreRegistryOperationPlan {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName
    )

    $commands = if ($ActionName -eq 'Apply') {
        @($script:BoostLabApplyCommands)
    }
    else {
        @($script:BoostLabDefaultCommands)
    }

    $operations = [System.Collections.Generic.List[object]]::new()
    for ($index = 0; $index -lt $script:BoostLabMitigationValueNames.Count; $index++) {
        $valueName = [string]$script:BoostLabMitigationValueNames[$index]
        if ($ActionName -eq 'Apply') {
            $arguments = @(
                'add'
                $script:BoostLabMitigationNativeRegistryPath
                '/v'
                $valueName
                '/t'
                'REG_DWORD'
                '/d'
                '3'
                '/f'
            )
            $operationType = 'SetDword'
            $expectedType = 'REG_DWORD'
            $expectedData = 3
        }
        else {
            $arguments = @(
                'delete'
                $script:BoostLabMitigationNativeRegistryPath
                '/v'
                $valueName
                '/f'
            )
            $operationType = 'DeleteValue'
            $expectedType = 'Absent'
            $expectedData = 'Absent'
        }

        $operations.Add([pscustomobject]@{
            Action = $ActionName
            OperationType = $operationType
            ValueName = $valueName
            RegistryPath = $script:BoostLabMitigationRegistryPath
            NativeRegistryPath = $script:BoostLabMitigationNativeRegistryPath
            ExpectedType = $expectedType
            ExpectedData = $expectedData
            CommandText = [string]$commands[$index]
            Arguments = [string[]]$arguments
        })
    }

    return $operations.ToArray()
}

function New-BoostLabSpectreMeltdownResult {
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
        Success = $Success
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Action = $Action
        Message = $Message
        RestartRequired = $false
        Cancelled = $Cancelled
        Timestamp = Get-Date
        Data = $Data
        VerificationResult = $VerificationResult
    }
}

function New-BoostLabSpectreVerificationCheck {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [AllowNull()]
        [object]$Expected,

        [AllowNull()]
        [object]$Actual,

        [Parameter(Mandatory)]
        [ValidateSet('Passed', 'Warning', 'Failed', 'NotApplicable', 'NotImplemented')]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Message
    )

    return [pscustomobject]@{
        Name = $Name
        Expected = $Expected
        Actual = $Actual
        Status = $Status
        Message = $Message
    }
}

function New-BoostLabSpectreVerificationResult {
    param(
        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [ValidateSet('Passed', 'Warning', 'Failed', 'NotApplicable', 'NotImplemented')]
        [string]$Status,

        [AllowNull()]
        [object]$ExpectedState,

        [AllowNull()]
        [object]$DetectedState,

        [object[]]$Checks = @(),

        [Parameter(Mandatory)]
        [string]$Message
    )

    return [pscustomobject]@{
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Action = $Action
        Status = $Status
        ExpectedState = $ExpectedState
        DetectedState = $DetectedState
        Checks = @($Checks)
        Message = $Message
        Timestamp = Get-Date
    }
}

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        Id = [string]$script:BoostLabToolMetadata['Id']
        Title = [string]$script:BoostLabToolMetadata['Title']
        Stage = [string]$script:BoostLabToolMetadata['Stage']
        Order = [int]$script:BoostLabToolMetadata['Order']
        Type = [string]$script:BoostLabToolMetadata['Type']
        RiskLevel = [string]$script:BoostLabToolMetadata['RiskLevel']
        Description = [string]$script:BoostLabToolMetadata['Description']
        Actions = @($script:BoostLabToolMetadata['Actions'])
        Capabilities = [pscustomobject]$script:BoostLabToolMetadata['Capabilities']
        ImplementedActions = @($script:BoostLabImplementedActions)
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$OperatingSystem = $env:OS,

        [string]$SystemRoot = $env:SystemRoot,

        [bool]$RegistryProviderAvailable = $(
            $null -ne (Get-PSProvider -PSProvider Registry -ErrorAction SilentlyContinue)
        ),

        [scriptblock]$PathChecker = {
            param($Path)
            Test-Path -LiteralPath $Path -PathType Leaf
        }
    )

    $registryUtilityPath = if ([string]::IsNullOrWhiteSpace($SystemRoot)) {
        ''
    }
    else {
        Join-Path $SystemRoot 'System32\reg.exe'
    }
    $registryUtilityAvailable = (
        -not [string]::IsNullOrWhiteSpace($registryUtilityPath) -and
        [bool](& $PathChecker $registryUtilityPath)
    )
    $supported = (
        $OperatingSystem -eq 'Windows_NT' -and
        $RegistryProviderAvailable -and
        $registryUtilityAvailable
    )

    return [pscustomobject]@{
        Supported = $supported
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason = if ($OperatingSystem -ne 'Windows_NT') {
            'Spectre / Meltdown Assistant requires Windows.'
        }
        elseif (-not $RegistryProviderAvailable) {
            'The PowerShell Registry provider is unavailable.'
        }
        elseif (-not $registryUtilityAvailable) {
            'The Windows registry command utility is unavailable.'
        }
        else {
            'The required Windows registry provider and command utility support is available.'
        }
        Timestamp = Get-Date
    }
}

function Get-BoostLabSpectreMitigationValueState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [scriptblock]$RegistryReader = {
            param($Path, $ValueName)

            if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
                return [pscustomobject]@{
                    ReadSucceeded = $true
                    Exists = $false
                    Value = $null
                    DisplayValue = 'Absent'
                    Message = 'The registry path is absent.'
                }
            }

            $item = Get-ItemProperty -LiteralPath $Path -ErrorAction Stop
            $property = $item.PSObject.Properties[$ValueName]
            if ($null -eq $property) {
                return [pscustomobject]@{
                    ReadSucceeded = $true
                    Exists = $false
                    Value = $null
                    DisplayValue = 'Absent'
                    Message = 'The registry value is absent.'
                }
            }

            return [pscustomobject]@{
                ReadSucceeded = $true
                Exists = $true
                Value = [int]$property.Value
                DisplayValue = [string]([int]$property.Value)
                Message = 'The registry value was detected.'
            }
        }
    )

    try {
        $results = @(& $RegistryReader $script:BoostLabMitigationRegistryPath $Name)
        if ($results.Count -eq 0 -or $null -eq $results[0]) {
            throw 'Registry reader returned no result.'
        }
        return $results[0]
    }
    catch {
        return [pscustomobject]@{
            ReadSucceeded = $false
            Exists = $false
            Value = $null
            DisplayValue = 'Unknown'
            Message = $_.Exception.Message
        }
    }
}

function Get-BoostLabSpectreMitigationState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [scriptblock]$RegistryReader = {
            param($Path, $ValueName)
            Get-BoostLabSpectreMitigationValueState -Name $ValueName
        }
    )

    $values = [ordered]@{}
    $warnings = [System.Collections.Generic.List[string]]::new()
    foreach ($name in @($script:BoostLabMitigationValueNames)) {
        try {
            $results = @(& $RegistryReader $script:BoostLabMitigationRegistryPath $name)
            if ($results.Count -eq 0 -or $null -eq $results[0]) {
                throw 'Registry reader returned no result.'
            }
            $state = $results[0]
        }
        catch {
            $state = [pscustomobject]@{
                ReadSucceeded = $false
                Exists = $false
                Value = $null
                DisplayValue = 'Unknown'
                Message = $_.Exception.Message
            }
        }
        $values[$name] = $state
        if (-not [bool](Get-BoostLabSpectrePropertyValue $state 'ReadSucceeded' $false)) {
            $warnings.Add("$name could not be read: $(Get-BoostLabSpectrePropertyValue $state 'Message' 'Unknown error')")
        }
    }

    $readable = @($values.Values | Where-Object { [bool](Get-BoostLabSpectrePropertyValue $_ 'ReadSucceeded' $false) })
    $disabledValues = @(
        $values.Values | Where-Object {
            [bool](Get-BoostLabSpectrePropertyValue $_ 'ReadSucceeded' $false) -and
            [bool](Get-BoostLabSpectrePropertyValue $_ 'Exists' $false) -and
            [int](Get-BoostLabSpectrePropertyValue $_ 'Value' -1) -eq 3
        }
    )
    $absentValues = @(
        $values.Values | Where-Object {
            [bool](Get-BoostLabSpectrePropertyValue $_ 'ReadSucceeded' $false) -and
            -not [bool](Get-BoostLabSpectrePropertyValue $_ 'Exists' $false)
        }
    )
    $profile = if ($readable.Count -ne $script:BoostLabMitigationValueNames.Count) {
        'Unknown'
    }
    elseif ($disabledValues.Count -eq $script:BoostLabMitigationValueNames.Count) {
        'Mitigations disabled by Ultimate profile'
    }
    elseif ($absentValues.Count -eq $script:BoostLabMitigationValueNames.Count) {
        'Default mitigation policy'
    }
    else {
        'Custom or partial mitigation policy'
    }

    return [pscustomobject]@{
        ReadSucceeded = ($readable.Count -gt 0)
        Profile = $profile
        FeatureSettingsOverrideMask = $values['FeatureSettingsOverrideMask']
        FeatureSettingsOverride = $values['FeatureSettingsOverride']
        Warnings = $warnings.ToArray()
        Message = if ($warnings.Count -eq 0) {
            'Spectre / Meltdown mitigation registry policy detected.'
        }
        else {
            $warnings -join ' '
        }
    }
}

function Get-BoostLabSpectreMeltdownAnalyzeData {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [scriptblock]$StateReader = {
            Get-BoostLabSpectreMitigationState
        }
    )

    $state = & $StateReader
    return [pscustomobject]@{
        CurrentProfile = [string]$state.Profile
        FeatureSettingsOverrideMask = [string]$state.FeatureSettingsOverrideMask.DisplayValue
        FeatureSettingsOverride = [string]$state.FeatureSettingsOverride.DisplayValue
        ApplyProfile = [pscustomobject]@{
            Meaning = 'Disable the source-targeted Spectre / Meltdown mitigations'
            FeatureSettingsOverrideMask = 3
            FeatureSettingsOverride = 3
        }
        DefaultProfile = [pscustomobject]@{
            Meaning = 'Remove the source-defined overrides so Windows uses its default mitigation policy'
            FeatureSettingsOverrideMask = 'Absent'
            FeatureSettingsOverride = 'Absent'
        }
        Recommendation = 'Keep the approved Default mitigation policy unless a technician has explicitly accepted the security exposure of disabling these mitigations.'
        SecurityWarning = 'Apply reduces CPU vulnerability protection by setting the two exact Ultimate mitigation override values to 3.'
        PerformanceTradeoff = 'Disabling mitigations may change performance, but it reduces protection against speculative-execution vulnerabilities.'
        VerificationScope = 'BoostLab verifies the two registry values only. It does not claim to measure the currently active kernel mitigation state.'
        Warnings = @($state.Warnings)
        Timestamp = Get-Date
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $state = Get-BoostLabSpectreMitigationState
    return [pscustomobject]@{
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Status = [string]$state.Profile
        LastAction = $null
        LastResult = $null
        RestartRequired = $false
        Timestamp = Get-Date
    }
}

function Test-BoostLabSpectreMeltdownState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [scriptblock]$RegistryReader = {
            param($Path, $ValueName)
            Get-BoostLabSpectreMitigationValueState -Name $ValueName
        }
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    $detected = [ordered]@{}
    foreach ($name in @($script:BoostLabMitigationValueNames)) {
        try {
            $results = @(& $RegistryReader $script:BoostLabMitigationRegistryPath $name)
            $state = if ($results.Count -gt 0) { $results[0] } else { $null }
        }
        catch {
            $state = $null
        }

        $readSucceeded = (
            $null -ne $state -and
            [bool](Get-BoostLabSpectrePropertyValue $state 'ReadSucceeded' $false)
        )
        $exists = (
            $readSucceeded -and
            [bool](Get-BoostLabSpectrePropertyValue $state 'Exists' $false)
        )
        $actual = if (-not $readSucceeded) {
            'Unknown'
        }
        elseif (-not $exists) {
            'Absent'
        }
        else {
            [string](Get-BoostLabSpectrePropertyValue $state 'Value' 'Unknown')
        }
        $expected = if ($ActionName -eq 'Apply') { 3 } else { 'Absent' }
        $status = if (-not $readSucceeded) {
            'Warning'
        }
        elseif ($ActionName -eq 'Apply' -and $exists -and [int](Get-BoostLabSpectrePropertyValue $state 'Value' -1) -eq 3) {
            'Passed'
        }
        elseif ($ActionName -eq 'Default' -and -not $exists) {
            'Passed'
        }
        else {
            'Failed'
        }
        $message = if ($status -eq 'Passed') {
            "$name matches the expected source-defined state."
        }
        elseif ($status -eq 'Warning') {
            "$name could not be read."
        }
        else {
            "$name detected '$actual'; expected '$expected'."
        }

        $detected[$name] = $actual
        $checks.Add(
            (New-BoostLabSpectreVerificationCheck `
                -Name ("{0}\{1}" -f $script:BoostLabMitigationRegistryPath, $name) `
                -Expected $expected `
                -Actual $actual `
                -Status $status `
                -Message $message)
        )
    }

    $overallStatus = if (@($checks | Where-Object Status -eq 'Failed').Count -gt 0) {
        'Failed'
    }
    elseif (@($checks | Where-Object Status -eq 'Warning').Count -gt 0) {
        'Warning'
    }
    else {
        'Passed'
    }
    $expectedProfile = if ($ActionName -eq 'Apply') {
        'Mitigations disabled by Ultimate profile'
    }
    else {
        'Default mitigation policy'
    }

    return New-BoostLabSpectreVerificationResult `
        -Action $ActionName `
        -Status $overallStatus `
        -ExpectedState ([pscustomobject]@{
            Profile = $expectedProfile
            FeatureSettingsOverrideMask = if ($ActionName -eq 'Apply') { 3 } else { 'Absent' }
            FeatureSettingsOverride = if ($ActionName -eq 'Apply') { 3 } else { 'Absent' }
        }) `
        -DetectedState ([pscustomobject]$detected) `
        -Checks $checks.ToArray() `
        -Message $(if ($overallStatus -eq 'Passed') {
            'The two source-defined mitigation registry settings match the expected state.'
        }
        elseif ($overallStatus -eq 'Warning') {
            'The command path completed, but one or more mitigation registry settings could not be read.'
        }
        else {
            'The detected mitigation registry settings do not match the expected state.'
        })
}

function Invoke-BoostLabSpectreRegistryCommand {
    param(
        [Parameter(Mandatory)]
        [object]$Operation
    )

    $arguments = @($Operation.Arguments | ForEach-Object { [string]$_ })
    $commandText = [string]$Operation.CommandText
    $valueName = [string]$Operation.ValueName
    $registryPath = [string]$Operation.RegistryPath
    $expectedType = [string]$Operation.ExpectedType
    $expectedData = $Operation.ExpectedData
    $registryUtilityPath = if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        'reg.exe'
    }
    else {
        Join-Path $env:SystemRoot 'System32\reg.exe'
    }

    try {
        if ($arguments.Count -eq 0) {
            throw 'Registry command argument list is empty.'
        }

        $output = & $registryUtilityPath @arguments 2>&1
        $exitCode = $LASTEXITCODE
        $outputText = (@($output) | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
        return [pscustomobject]@{
            Success = ($exitCode -eq 0)
            ExitCode = $exitCode
            Output = $outputText
            ErrorReason = if ($exitCode -eq 0) { '' } else { $outputText }
            ValueName = $valueName
            RegistryPath = $registryPath
            ExpectedType = $expectedType
            ExpectedData = $expectedData
            CommandText = $commandText
            Arguments = $arguments
        }
    }
    catch {
        return [pscustomobject]@{
            Success = $false
            ExitCode = $null
            Output = $_.Exception.Message
            ErrorReason = $_.Exception.Message
            ValueName = $valueName
            RegistryPath = $registryPath
            ExpectedType = $expectedType
            ExpectedData = $expectedData
            CommandText = $commandText
            Arguments = $arguments
        }
    }
}

function Invoke-BoostLabSpectreMeltdownAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [scriptblock]$AdministratorChecker = {
            Test-BoostLabAdministrator
        },

        [scriptblock]$RegistryInvoker = {
            param($Operation)
            Invoke-BoostLabSpectreRegistryCommand -Operation $Operation
        },

        [scriptblock]$RegistryReader = {
            param($Path, $ValueName)
            Get-BoostLabSpectreMitigationValueState -Name $ValueName
        }
    )

    if (-not [bool](& $AdministratorChecker)) {
        return New-BoostLabSpectreMeltdownResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Administrator rights are required to change Spectre / Meltdown mitigation policy.'
    }

    $operationsToRun = @(Get-BoostLabSpectreRegistryOperationPlan -ActionName $ActionName)
    $operations = [System.Collections.Generic.List[string]]::new()
    $operationResults = [System.Collections.Generic.List[object]]::new()
    $alreadyDefault = [System.Collections.Generic.List[string]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()

    foreach ($operation in $operationsToRun) {
        $valueName = [string]$operation.ValueName
        if ($ActionName -eq 'Default') {
            $preStateResults = @(& $RegistryReader $script:BoostLabMitigationRegistryPath $valueName)
            $preState = if ($preStateResults.Count -gt 0) { $preStateResults[0] } else { $null }
            if (
                $null -ne $preState -and
                [bool](Get-BoostLabSpectrePropertyValue $preState 'ReadSucceeded' $false) -and
                -not [bool](Get-BoostLabSpectrePropertyValue $preState 'Exists' $false)
            ) {
                $alreadyDefault.Add($valueName)
                continue
            }
        }

        $operations.Add([string]$operation.CommandText)
        try {
            $commandResult = & $RegistryInvoker $operation
            $commandOutput = [string](Get-BoostLabSpectrePropertyValue $commandResult 'Output' 'Unknown registry command failure')
            $commandErrorReason = [string](Get-BoostLabSpectrePropertyValue $commandResult 'ErrorReason' $commandOutput)
            $operationResults.Add([pscustomobject]@{
                ValueName = $valueName
                RegistryPath = [string]$operation.RegistryPath
                ExpectedType = [string]$operation.ExpectedType
                ExpectedData = $operation.ExpectedData
                CommandText = [string]$operation.CommandText
                Arguments = @($operation.Arguments)
                Success = [bool](Get-BoostLabSpectrePropertyValue $commandResult 'Success' $false)
                ExitCode = Get-BoostLabSpectrePropertyValue $commandResult 'ExitCode' $null
                ErrorReason = $commandErrorReason
            })
            if (-not [bool](Get-BoostLabSpectrePropertyValue $commandResult 'Success' $false)) {
                $errors.Add("$valueName command failed: $commandErrorReason")
            }
        }
        catch {
            $operationResults.Add([pscustomobject]@{
                ValueName = $valueName
                RegistryPath = [string]$operation.RegistryPath
                ExpectedType = [string]$operation.ExpectedType
                ExpectedData = $operation.ExpectedData
                CommandText = [string]$operation.CommandText
                Arguments = @($operation.Arguments)
                Success = $false
                ExitCode = $null
                ErrorReason = $_.Exception.Message
            })
            $errors.Add("$valueName command failed: $($_.Exception.Message)")
        }
    }

    $verificationResult = Test-BoostLabSpectreMeltdownState `
        -ActionName $ActionName `
        -RegistryReader $RegistryReader
    $commandStatus = if ($errors.Count -gt 0) {
        'Failed'
    }
    elseif ($alreadyDefault.Count -gt 0 -and $operations.Count -eq 0) {
        'Already default'
    }
    else {
        'Completed'
    }
    $data = [pscustomobject]@{
        CommandStatus = $commandStatus
        VerificationStatus = [string]$verificationResult.Status
        ExpectedState = $verificationResult.ExpectedState
        DetectedState = $verificationResult.DetectedState
        RegistryPath = $script:BoostLabMitigationRegistryPath
        CommandsAttempted = $operations.ToArray()
        OperationResults = $operationResults.ToArray()
        AlreadyDefaultValues = $alreadyDefault.ToArray()
        Errors = $errors.ToArray()
        SecurityImpact = if ($ActionName -eq 'Apply') {
            'The source-defined CPU vulnerability mitigations are disabled by registry policy.'
        }
        else {
            'The source-defined overrides are removed so Windows can use its default mitigation policy.'
        }
        VerificationScope = 'Registry configuration only; active kernel mitigation state is not measured.'
        CompletedAt = Get-Date
    }

    $success = ($errors.Count -eq 0 -and $verificationResult.Status -ne 'Failed')
    $message = if ($errors.Count -gt 0) {
        "Spectre / Meltdown action failed: $($errors -join '; ')"
    }
    elseif ($verificationResult.Status -eq 'Failed') {
        'The registry commands completed, but verification detected an unexpected mitigation policy state.'
    }
    elseif ($verificationResult.Status -eq 'Warning') {
        'The registry commands completed, but mitigation policy verification was incomplete.'
    }
    elseif ($ActionName -eq 'Apply') {
        'Spectre / Meltdown mitigations disabled using the approved Ultimate policy values.'
    }
    elseif ($operations.Count -eq 0) {
        'Spectre / Meltdown mitigation policy is already at the approved default.'
    }
    else {
        'Spectre / Meltdown mitigation policy restored to the approved default.'
    }

    return New-BoostLabSpectreMeltdownResult `
        -Success $success `
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
        return New-BoostLabSpectreMeltdownResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Unsupported action. Only Analyze, Apply, and Default are allowed.'
    }

    if ($ActionName -eq 'Analyze') {
        return New-BoostLabSpectreMeltdownResult `
            -Success $true `
            -Action 'Analyze' `
            -Message 'Spectre / Meltdown mitigation policy analyzed.' `
            -Data (Get-BoostLabSpectreMeltdownAnalyzeData)
    }

    if (-not $Confirmed) {
        return New-BoostLabSpectreMeltdownResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    return Invoke-BoostLabSpectreMeltdownAction -ActionName $ActionName
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
