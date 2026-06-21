Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $verificationModulePath -Scope Local -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'mmagent-assistant'
    Title = 'MMAgent Assistant'
    Stage = 'Advanced'
    Order = 2
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Analyze current MMAgent state and apply the approved Ultimate Off or Default MMAgent feature profile.'
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
        CanModifySecurity = $false
        CanDeleteFiles = $false
        UsesTrustedInstaller = $false
        UsesSafeMode = $false
        SupportsDefault = $true
        SupportsRestore = $false
        NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Analyze', 'Apply', 'Default')
$script:BoostLabMMAgentPrefetchRegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'
$script:BoostLabMMAgentPrefetchRegistryCmdKey = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'
$script:BoostLabApplyPrefetchRegistryCommand = 'reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d "0" /f'
$script:BoostLabDefaultPrefetchRegistryCommand = 'reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d "3" /f'

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

function Get-BoostLabMMAgentPropertyValue {
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

function ConvertTo-BoostLabMMAgentDisplayValue {
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return 'Unknown'
    }
    return [string]$Value
}

function New-BoostLabMMAgentAssistantResult {
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

    [pscustomobject]@{
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

function Get-BoostLabMMAgentExpectedState {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName
    )

    if ($ActionName -eq 'Apply') {
        return [ordered]@{
            EnablePrefetcher = 0
            ApplicationLaunchPrefetching = $false
            ApplicationPreLaunch = $false
            MaxOperationAPIFiles = 1
            MemoryCompression = $false
            OperationAPI = $false
            PageCombining = $false
        }
    }

    return [ordered]@{
        EnablePrefetcher = 3
        ApplicationLaunchPrefetching = $true
        ApplicationPreLaunch = $true
        MaxOperationAPIFiles = 512
        MemoryCompression = $false
        OperationAPI = $true
        PageCombining = $false
    }
}

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
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
        [scriptblock]$CommandResolver = {
            param($CommandName)
            Get-Command -Name $CommandName -ErrorAction SilentlyContinue
        }
    )

    $missingCommands = @(
        foreach ($commandName in @(
            'Disable-MMAgent'
            'Enable-MMAgent'
            'Set-MMAgent'
            'Get-MMAgent'
        )) {
            $resolvedCommands = @(& $CommandResolver $commandName)
            if ($resolvedCommands.Count -eq 0) {
                $commandName
            }
        }
    )

    [pscustomobject]@{
        Supported = ($env:OS -eq 'Windows_NT' -and $missingCommands.Count -eq 0)
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason = if ($env:OS -ne 'Windows_NT') {
            'MMAgent Assistant requires Windows.'
        }
        elseif ($missingCommands.Count -gt 0) {
            'MMAgent Assistant is unavailable because these commands were not found: {0}.' -f ($missingCommands -join ', ')
        }
        else {
            'The required MMAgent commands are available.'
        }
        Timestamp = Get-Date
    }
}

function Get-BoostLabMMAgentAssistantState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [scriptblock]$CommandResolver = {
            param($CommandName)
            Get-Command -Name $CommandName -ErrorAction SilentlyContinue
        },

        [scriptblock]$MMAgentReader = {
            Get-MMAgent -ErrorAction Stop
        },

        [scriptblock]$RegistryReader = {
            param($Path, $Name)
            Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop
        }
    )

    $getCommand = @(& $CommandResolver 'Get-MMAgent')
    if ($getCommand.Count -eq 0) {
        return [pscustomobject]@{
            ReadSucceeded = $false
            MMAgentReadSucceeded = $false
            RegistryReadSucceeded = $false
            EnablePrefetcher = $null
            ApplicationLaunchPrefetching = $null
            ApplicationPreLaunch = $null
            MaxOperationAPIFiles = $null
            MemoryCompression = $null
            OperationAPI = $null
            PageCombining = $null
            Warnings = @('Get-MMAgent is unavailable.')
            Message = 'Get-MMAgent is unavailable.'
        }
    }

    $warnings = [System.Collections.Generic.List[string]]::new()
    $mmAgent = $null
    $mmaReadSucceeded = $false
    try {
        $mmaResults = @(& $MMAgentReader)
        if ($mmaResults.Count -eq 0 -or $null -eq $mmaResults[0]) {
            $warnings.Add('Get-MMAgent returned no result.')
        }
        else {
            $mmAgent = $mmaResults[0]
            $mmaReadSucceeded = $true
        }
    }
    catch {
        $warnings.Add("Get-MMAgent failed: $($_.Exception.Message)")
    }

    $prefetchValue = $null
    $registryReadSucceeded = $false
    try {
        $prefetchItem = & $RegistryReader $script:BoostLabMMAgentPrefetchRegistryPath 'EnablePrefetcher'
        $prefetchValue = [int](Get-BoostLabMMAgentPropertyValue -InputObject $prefetchItem -Name 'EnablePrefetcher' -DefaultValue $null)
        $registryReadSucceeded = $true
    }
    catch {
        $warnings.Add("EnablePrefetcher could not be read: $($_.Exception.Message)")
    }

    $state = [pscustomobject]@{
        ReadSucceeded = ($mmaReadSucceeded -or $registryReadSucceeded)
        MMAgentReadSucceeded = $mmaReadSucceeded
        RegistryReadSucceeded = $registryReadSucceeded
        EnablePrefetcher = $prefetchValue
        ApplicationLaunchPrefetching = Get-BoostLabMMAgentPropertyValue -InputObject $mmAgent -Name 'ApplicationLaunchPrefetching'
        ApplicationPreLaunch = Get-BoostLabMMAgentPropertyValue -InputObject $mmAgent -Name 'ApplicationPreLaunch'
        MaxOperationAPIFiles = Get-BoostLabMMAgentPropertyValue -InputObject $mmAgent -Name 'MaxOperationAPIFiles'
        MemoryCompression = Get-BoostLabMMAgentPropertyValue -InputObject $mmAgent -Name 'MemoryCompression'
        OperationAPI = Get-BoostLabMMAgentPropertyValue -InputObject $mmAgent -Name 'OperationAPI'
        PageCombining = Get-BoostLabMMAgentPropertyValue -InputObject $mmAgent -Name 'PageCombining'
        Warnings = $warnings.ToArray()
        Message = if ($warnings.Count -eq 0) {
            'MMAgent and prefetcher state detected.'
        }
        else {
            $warnings -join ' '
        }
    }

    return $state
}

function Get-BoostLabMMAgentAnalyzeData {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [scriptblock]$StateReader = {
            Get-BoostLabMMAgentAssistantState
        }
    )

    $state = & $StateReader
    $applyState = [pscustomobject](Get-BoostLabMMAgentExpectedState -ActionName 'Apply')
    $defaultState = [pscustomobject](Get-BoostLabMMAgentExpectedState -ActionName 'Default')

    [pscustomobject]@{
        CurrentEnablePrefetcher = ConvertTo-BoostLabMMAgentDisplayValue $state.EnablePrefetcher
        CurrentApplicationLaunchPrefetching = ConvertTo-BoostLabMMAgentDisplayValue $state.ApplicationLaunchPrefetching
        CurrentApplicationPreLaunch = ConvertTo-BoostLabMMAgentDisplayValue $state.ApplicationPreLaunch
        CurrentMaxOperationAPIFiles = ConvertTo-BoostLabMMAgentDisplayValue $state.MaxOperationAPIFiles
        CurrentMemoryCompression = ConvertTo-BoostLabMMAgentDisplayValue $state.MemoryCompression
        CurrentOperationAPI = ConvertTo-BoostLabMMAgentDisplayValue $state.OperationAPI
        CurrentPageCombining = ConvertTo-BoostLabMMAgentDisplayValue $state.PageCombining
        ApplyProfile = $applyState
        DefaultProfile = $defaultState
        Notes = @(
            'SETTINGS MAY TAKE A WHILE TO INITIALIZE AFTER REBOOT'
            'WAIT A SHORT PERIOD BEFORE CHECKING'
            'The Ultimate Default profile still disables MemoryCompression and PageCombining.'
            'Use the dedicated Memory Compression tool when you only want to change MemoryCompression.'
        )
        Warnings = @($state.Warnings)
        Timestamp = Get-Date
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $state = Get-BoostLabMMAgentAssistantState
    [pscustomobject]@{
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Status = if ([bool]$state.ReadSucceeded) {
            'Prefetcher: {0}; MemoryCompression: {1}; OperationAPI: {2}' -f `
                (ConvertTo-BoostLabMMAgentDisplayValue $state.EnablePrefetcher), `
                (ConvertTo-BoostLabMMAgentDisplayValue $state.MemoryCompression), `
                (ConvertTo-BoostLabMMAgentDisplayValue $state.OperationAPI)
        }
        else {
            'Unsupported or unavailable'
        }
        LastAction = $null
        LastResult = $null
        RestartRequired = $false
        Timestamp = Get-Date
    }
}

function Test-BoostLabMMAgentAssistantState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [scriptblock]$StateReader = { Get-BoostLabMMAgentAssistantState }
    )

    $expectedState = Get-BoostLabMMAgentExpectedState -ActionName $ActionName
    $state = & $StateReader
    $checks = [System.Collections.Generic.List[object]]::new()

    foreach ($propertyName in $expectedState.Keys) {
        $expectedValue = $expectedState[$propertyName]
        $actualValue = Get-BoostLabMMAgentPropertyValue -InputObject $state -Name $propertyName
        $status = if ($null -eq $actualValue) {
            'Warning'
        }
        elseif ([string]$actualValue -eq [string]$expectedValue) {
            'Passed'
        }
        else {
            'Failed'
        }

        $message = if ($status -eq 'Passed') {
            "$propertyName matches the expected state."
        }
        elseif ($status -eq 'Warning') {
            "$propertyName could not be detected."
        }
        else {
            "$propertyName detected '$actualValue'; expected '$expectedValue'."
        }

        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name $propertyName `
                -Expected $expectedValue `
                -Actual $(if ($null -eq $actualValue) { 'Unknown' } else { $actualValue }) `
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

    return New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $ActionName `
        -Status $overallStatus `
        -ExpectedState ([pscustomobject]$expectedState) `
        -DetectedState ([pscustomobject]@{
            EnablePrefetcher = $state.EnablePrefetcher
            ApplicationLaunchPrefetching = $state.ApplicationLaunchPrefetching
            ApplicationPreLaunch = $state.ApplicationPreLaunch
            MaxOperationAPIFiles = $state.MaxOperationAPIFiles
            MemoryCompression = $state.MemoryCompression
            OperationAPI = $state.OperationAPI
            PageCombining = $state.PageCombining
        }) `
        -Checks $checks.ToArray() `
        -Message $(if ($overallStatus -eq 'Passed') {
            'The expected MMAgent state was detected.'
        }
        elseif ($overallStatus -eq 'Warning') {
            'The MMAgent profile command path completed, but one or more states could not be detected.'
        }
        else {
            'The detected MMAgent state does not match the expected result.'
        })
}

function Get-BoostLabMMAgentOperationPlan {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName
    )

    if ($ActionName -eq 'Apply') {
        return @(
            [pscustomobject]@{ Type = 'RegistryAdd'; Name = 'EnablePrefetcher'; Value = 0 }
            [pscustomobject]@{ Type = 'Disable'; Name = 'ApplicationLaunchPrefetching' }
            [pscustomobject]@{ Type = 'Disable'; Name = 'ApplicationPreLaunch' }
            [pscustomobject]@{ Type = 'Set'; Name = 'MaxOperationAPIFiles'; Value = 1 }
            [pscustomobject]@{ Type = 'Disable'; Name = 'MemoryCompression' }
            [pscustomobject]@{ Type = 'Disable'; Name = 'OperationAPI' }
            [pscustomobject]@{ Type = 'Disable'; Name = 'PageCombining' }
        )
    }

    return @(
        [pscustomobject]@{ Type = 'RegistryAdd'; Name = 'EnablePrefetcher'; Value = 3 }
        [pscustomobject]@{ Type = 'Enable'; Name = 'ApplicationLaunchPrefetching' }
        [pscustomobject]@{ Type = 'Enable'; Name = 'ApplicationPreLaunch' }
        [pscustomobject]@{ Type = 'Set'; Name = 'MaxOperationAPIFiles'; Value = 512 }
        [pscustomobject]@{ Type = 'Disable'; Name = 'MemoryCompression' }
        [pscustomobject]@{ Type = 'Enable'; Name = 'OperationAPI' }
        [pscustomobject]@{ Type = 'Disable'; Name = 'PageCombining' }
    )
}

function Invoke-BoostLabMMAgentRegistryCommand {
    param(
        [Parameter(Mandatory)]
        [int]$Value
    )

    $commandText = if ($Value -eq 0) {
        $script:BoostLabApplyPrefetchRegistryCommand
    }
    else {
        $script:BoostLabDefaultPrefetchRegistryCommand
    }
    $commandProcessorPath = Join-Path $env:SystemRoot 'System32\cmd.exe'
    $output = & $commandProcessorPath /d /c $commandText 2>&1
    [pscustomobject]@{
        Success = ($LASTEXITCODE -eq 0)
        Output = (@($output) | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
    }
}

function Invoke-BoostLabMMAgentAssistantAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [scriptblock]$AdministratorChecker = { Test-BoostLabAdministrator },

        [scriptblock]$CommandResolver = {
            param($CommandName)
            Get-Command -Name $CommandName -ErrorAction SilentlyContinue
        },

        [scriptblock]$RegistryInvoker = {
            param($Value)
            Invoke-BoostLabMMAgentRegistryCommand -Value $Value
        },

        [scriptblock]$MMAgentCommandInvoker = {
            param($Operation)
            switch ($Operation.Type) {
                'Disable' {
                    switch ($Operation.Name) {
                        'ApplicationLaunchPrefetching' { Disable-MMAgent -ApplicationLaunchPrefetching -ErrorAction Stop | Out-Null }
                        'ApplicationPreLaunch' { Disable-MMAgent -ApplicationPreLaunch -ErrorAction Stop | Out-Null }
                        'MemoryCompression' { Disable-MMAgent -MemoryCompression -ErrorAction Stop | Out-Null }
                        'OperationAPI' { Disable-MMAgent -OperationAPI -ErrorAction Stop | Out-Null }
                        'PageCombining' { Disable-MMAgent -PageCombining -ErrorAction Stop | Out-Null }
                    }
                }
                'Enable' {
                    switch ($Operation.Name) {
                        'ApplicationLaunchPrefetching' { Enable-MMAgent -ApplicationLaunchPrefetching -ErrorAction Stop | Out-Null }
                        'ApplicationPreLaunch' { Enable-MMAgent -ApplicationPreLaunch -ErrorAction Stop | Out-Null }
                        'OperationAPI' { Enable-MMAgent -OperationAPI -ErrorAction Stop | Out-Null }
                    }
                }
                'Set' {
                    Set-MMAgent -MaxOperationAPIFiles $Operation.Value -ErrorAction Stop | Out-Null
                }
            }
        },

        [scriptblock]$StateReader = { Get-BoostLabMMAgentAssistantState }
    )

    if (-not [bool](& $AdministratorChecker)) {
        return New-BoostLabMMAgentAssistantResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Administrator rights are required to change MMAgent features.'
    }

    foreach ($commandName in @('Disable-MMAgent', 'Enable-MMAgent', 'Set-MMAgent', 'Get-MMAgent')) {
        if (@(& $CommandResolver $commandName).Count -eq 0) {
            return New-BoostLabMMAgentAssistantResult `
                -Success $false `
                -Action $ActionName `
                -Message "MMAgent Assistant is unavailable because $commandName was not found."
        }
    }

    $warnings = [System.Collections.Generic.List[string]]::new()
    $operationsAttempted = [System.Collections.Generic.List[string]]::new()
    foreach ($operation in @(Get-BoostLabMMAgentOperationPlan -ActionName $ActionName)) {
        $operationsAttempted.Add(("{0}:{1}" -f $operation.Type, $operation.Name))
        try {
            if ($operation.Type -eq 'RegistryAdd') {
                $registryResult = & $RegistryInvoker $operation.Value
                if (-not [bool](Get-BoostLabMMAgentPropertyValue -InputObject $registryResult -Name 'Success' -DefaultValue $false)) {
                    $warnings.Add("EnablePrefetcher write failed: $(Get-BoostLabMMAgentPropertyValue -InputObject $registryResult -Name 'Output' -DefaultValue 'Unknown failure')")
                }
            }
            else {
                & $MMAgentCommandInvoker $operation
            }
        }
        catch {
                $warnings.Add(("{0} {1} failed: {2}" -f $operation.Type, $operation.Name, $_.Exception.Message))
        }
    }

    $verificationResult = Test-BoostLabMMAgentAssistantState `
        -ActionName $ActionName `
        -StateReader $StateReader
    $data = [pscustomobject]@{
        CommandStatus = if ($warnings.Count -eq 0) { 'Completed' } else { 'Completed with warnings' }
        VerificationStatus = [string]$verificationResult.Status
        ExpectedState = $verificationResult.ExpectedState
        DetectedState = $verificationResult.DetectedState
        OperationsAttempted = $operationsAttempted.ToArray()
        Warnings = $warnings.ToArray()
        CompletedAt = Get-Date
    }

    $success = $verificationResult.Status -ne 'Failed'
    $message = if ($verificationResult.Status -eq 'Failed') {
        'MMAgent profile command path completed, but verification detected an unexpected state.'
    }
    elseif ($warnings.Count -gt 0) {
        'MMAgent profile applied with warnings.'
    }
    elseif ($ActionName -eq 'Apply') {
        'MMAgent profile set to Off.'
    }
    else {
        'MMAgent profile set to the approved source Default state.'
    }

    return New-BoostLabMMAgentAssistantResult `
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
        return New-BoostLabMMAgentAssistantResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Unsupported action. Only Analyze, Apply, and Default are allowed.'
    }

    if ($ActionName -eq 'Analyze') {
        return New-BoostLabMMAgentAssistantResult `
            -Success $true `
            -Action 'Analyze' `
            -Message 'MMAgent state analyzed.' `
            -Data (Get-BoostLabMMAgentAnalyzeData)
    }

    if (-not $Confirmed) {
        return New-BoostLabMMAgentAssistantResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    return Invoke-BoostLabMMAgentAssistantAction -ActionName $ActionName
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
