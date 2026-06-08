Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $verificationModulePath -Scope Local -Force -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'memory-compression'; Title = 'Memory Compression'; Stage = 'Setup'; Order = 1
    Type = 'action'; RiskLevel = 'low'
    Description = 'Disable Windows memory compression using the approved recommendation or restore the default enabled state.'
    Actions = @('Apply', 'Default')
    Capabilities = [ordered]@{
        RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false
        CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false
        CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false
        CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false
        SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Apply', 'Default')

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

function New-BoostLabMemoryCompressionResult {
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
        Success            = $Success
        ToolId             = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle          = [string]$script:BoostLabToolMetadata['Title']
        Action             = $Action
        Message            = $Message
        RestartRequired    = $false
        Cancelled          = $Cancelled
        Timestamp          = Get-Date
        Data               = $Data
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
    param(
        [scriptblock]$CommandResolver = {
            param($CommandName)
            Get-Command -Name $CommandName -ErrorAction SilentlyContinue
        },

        [string]$OperatingSystem = $env:OS
    )

    $missingCommands = @(
        foreach ($commandName in @(
            'Disable-MMAgent'
            'Enable-MMAgent'
            'Get-MMAgent'
        )) {
            $resolvedCommands = @(& $CommandResolver $commandName)
            if ($resolvedCommands.Count -eq 0) {
                $commandName
            }
        }
    )
    $missingCommandCount = $missingCommands.Count
    $isWindows = $OperatingSystem -eq 'Windows_NT'
    $supported = $isWindows -and $missingCommandCount -eq 0

    return [pscustomobject]@{
        Supported = $supported
        ToolId    = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason    = if (-not $isWindows) {
            'Memory Compression requires Windows.'
        }
        elseif ($missingCommandCount -gt 0) {
            'Memory Compression is unavailable because these MMAgent commands were not found: {0}.' -f ($missingCommands -join ', ')
        }
        else {
            'Windows MMAgent memory compression commands are available.'
        }
        Timestamp = Get-Date
    }
}

function Get-BoostLabMemoryCompressionPropertyValue {
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

function Get-BoostLabMemoryCompressionState {
    param(
        [scriptblock]$CommandResolver = {
            param($CommandName)
            Get-Command -Name $CommandName -ErrorAction SilentlyContinue
        },

        [scriptblock]$MMAgentReader = {
            Get-MMAgent -ErrorAction Stop
        }
    )

    $resolvedCommands = @(& $CommandResolver 'Get-MMAgent')
    if ($resolvedCommands.Count -eq 0) {
        return [pscustomobject]@{
            ReadSucceeded    = $false
            MemoryCompression = $null
            DisplayValue     = 'Unknown'
            Message          = 'Get-MMAgent is unavailable.'
        }
    }

    try {
        $mmaAgentResults = @(& $MMAgentReader)
        if ($mmaAgentResults.Count -eq 0) {
            return [pscustomobject]@{
                ReadSucceeded    = $false
                MemoryCompression = $null
                DisplayValue     = 'Unknown'
                Message          = 'Get-MMAgent returned no result.'
            }
        }

        $mmaAgent = $mmaAgentResults[0]
        $property = $mmaAgent.PSObject.Properties['MemoryCompression']
        if ($null -eq $property) {
            return [pscustomobject]@{
                ReadSucceeded    = $false
                MemoryCompression = $null
                DisplayValue     = 'Unknown'
                Message          = 'Get-MMAgent did not return MemoryCompression state.'
            }
        }

        $detected = [bool]$property.Value
        return [pscustomobject]@{
            ReadSucceeded    = $true
            MemoryCompression = $detected
            DisplayValue     = [string]$detected
            Message          = 'MemoryCompression state detected.'
        }
    }
    catch {
        return [pscustomobject]@{
            ReadSucceeded    = $false
            MemoryCompression = $null
            DisplayValue     = 'Unknown'
            Message          = "Get-MMAgent failed: $($_.Exception.Message)"
        }
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $state = Get-BoostLabMemoryCompressionState
    return [pscustomobject]@{
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        Status          = if ($state.ReadSucceeded) {
            "MemoryCompression: $($state.DisplayValue)"
        }
        else {
            'Unsupported or unavailable'
        }
        MemoryCompression = $state.MemoryCompression
        LastAction      = $null
        LastResult      = $null
        RestartRequired = $false
        Timestamp       = Get-Date
    }
}

function Test-BoostLabMemoryCompressionState {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [scriptblock]$StateReader = { Get-BoostLabMemoryCompressionState }
    )

    $expected = $ActionName -eq 'Default'
    $stateResults = @(& $StateReader)
    $state = if ($stateResults.Count -gt 0) {
        $stateResults[0]
    }
    else {
        $null
    }
    $readSucceeded = [bool](Get-BoostLabMemoryCompressionPropertyValue `
        -InputObject $state `
        -Name 'ReadSucceeded' `
        -DefaultValue $false)
    $detectedValue = Get-BoostLabMemoryCompressionPropertyValue `
        -InputObject $state `
        -Name 'MemoryCompression' `
        -DefaultValue $null
    $stateMessage = [string](Get-BoostLabMemoryCompressionPropertyValue `
        -InputObject $state `
        -Name 'Message' `
        -DefaultValue 'MemoryCompression state was unavailable.')

    $status = if (-not $readSucceeded) {
        'Warning'
    }
    elseif ([bool]$detectedValue -eq $expected) {
        'Passed'
    }
    else {
        'Failed'
    }
    $message = switch ($status) {
        'Passed' { 'The expected MemoryCompression state was detected.' }
        'Warning' { 'The MMAgent command completed, but MemoryCompression state could not be detected.' }
        default { 'The detected MemoryCompression state does not match the expected result.' }
    }
    $check = New-BoostLabVerificationCheck `
        -Name 'MemoryCompression' `
        -Expected $expected `
        -Actual $(if ($readSucceeded) { [bool]$detectedValue } else { 'Unknown' }) `
        -Status $status `
        -Message $stateMessage

    return New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $ActionName `
        -Status $status `
        -ExpectedState ([pscustomobject]@{ MemoryCompression = $expected }) `
        -DetectedState ([pscustomobject]@{
            MemoryCompression = if ($readSucceeded) {
                [bool]$detectedValue
            }
            else {
                'Unknown'
            }
        }) `
        -Checks @($check) `
        -Message $message
}

function Invoke-BoostLabMemoryCompressionAction {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [scriptblock]$AdministratorChecker = {
            Test-BoostLabAdministrator
        },

        [scriptblock]$CommandResolver = {
            param($CommandName)
            Get-Command -Name $CommandName -ErrorAction SilentlyContinue
        },

        [scriptblock]$CommandInvoker = {
            param($RequestedAction)
            if ($RequestedAction -eq 'Apply') {
                Disable-MMAgent -MemoryCompression -ErrorAction Stop | Out-Null
            }
            else {
                Enable-MMAgent -MemoryCompression -ErrorAction Stop | Out-Null
            }
        },

        [scriptblock]$StateReader = {
            Get-BoostLabMemoryCompressionState
        }
    )

    if (-not [bool](& $AdministratorChecker)) {
        return New-BoostLabMemoryCompressionResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Administrator rights are required to change Memory Compression.'
    }

    $requiredCommand = if ($ActionName -eq 'Apply') {
        'Disable-MMAgent'
    }
    else {
        'Enable-MMAgent'
    }
    foreach ($commandName in @($requiredCommand, 'Get-MMAgent')) {
        $resolvedCommands = @(& $CommandResolver $commandName)
        if ($resolvedCommands.Count -eq 0) {
            return New-BoostLabMemoryCompressionResult `
                -Success $false `
                -Action $ActionName `
                -Message "Memory Compression is unavailable because $commandName was not found."
        }
    }

    try {
        & $CommandInvoker $ActionName | Out-Null
    }
    catch {
        return New-BoostLabMemoryCompressionResult `
            -Success $false `
            -Action $ActionName `
            -Message "Memory Compression command failed: $($_.Exception.Message)"
    }

    $completedAt = Get-Date
    $verificationResult = Test-BoostLabMemoryCompressionState `
        -ActionName $ActionName `
        -StateReader $StateReader
    $expected = $ActionName -eq 'Default'
    $detected = $verificationResult.DetectedState.MemoryCompression
    $data = [pscustomobject]@{
        CommandStatus              = 'Completed'
        ExpectedMemoryCompression = $expected
        DetectedMemoryCompression = $detected
        CompletedAt                = $completedAt
    }
    $message = if ($verificationResult.Status -eq 'Warning') {
        'Memory Compression command completed, but verification was unavailable.'
    }
    elseif ($verificationResult.Status -eq 'Failed') {
        'Memory Compression command completed, but verification detected an unexpected state.'
    }
    elseif ($ActionName -eq 'Apply') {
        'Memory compression disabled.'
    }
    else {
        'Memory compression restored to default.'
    }

    return New-BoostLabMemoryCompressionResult `
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
        return New-BoostLabMemoryCompressionResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Unsupported action. Only Apply and Default are allowed.'
    }
    if (-not $Confirmed) {
        return New-BoostLabMemoryCompressionResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    return Invoke-BoostLabMemoryCompressionAction -ActionName $ActionName
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [bool]$Confirmed = $false
    )

    return Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed:$Confirmed
}

Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
