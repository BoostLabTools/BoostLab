Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $verificationModulePath -Scope Local -Force -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'memory-compression'; Title = 'Memory Compression'; Stage = 'Setup'; Order = 2
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

        [string]$Status = '',

        [bool]$Cancelled = $false,

        [bool]$RestartRequired = $false,

        [AllowNull()]
        [object]$Data = $null,

        [AllowNull()]
        [object]$VerificationResult = $null
    )

    $resolvedStatus = if (-not [string]::IsNullOrWhiteSpace($Status)) {
        $Status
    }
    elseif ($Success) {
        'Passed'
    }
    else {
        'Failed'
    }

    return [pscustomobject]@{
        Success            = $Success
        ToolId             = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle          = [string]$script:BoostLabToolMetadata['Title']
        Action             = $Action
        Status             = $resolvedStatus
        Message            = $Message
        RestartRequired    = $RestartRequired
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

function New-BoostLabMemoryCompressionFinalVerification {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [Parameter(Mandatory)]
        [bool]$Expected,

        [AllowNull()]
        [object]$Actual,

        [Parameter(Mandatory)]
        [ValidateSet('Passed', 'Warning', 'Failed')]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$CheckMessage,

        [Parameter(Mandatory)]
        [string]$Message
    )

    $check = New-BoostLabVerificationCheck `
        -Name 'MemoryCompression' `
        -Expected $Expected `
        -Actual $Actual `
        -Status $Status `
        -Message $CheckMessage

    return New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $ActionName `
        -Status $Status `
        -ExpectedState ([pscustomobject]@{ MemoryCompression = $Expected }) `
        -DetectedState ([pscustomobject]@{ MemoryCompression = $Actual }) `
        -Checks @($check) `
        -Message $Message
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
        },

        [scriptblock]$DelayInvoker = {
            param($Milliseconds)
            Start-Sleep -Milliseconds $Milliseconds
        },

        [int]$VerificationRetryDelayMilliseconds = 500
    )

    function New-MemoryCompressionAttemptRecord {
        param(
            [Parameter(Mandatory)][int]$Attempt,
            [Parameter(Mandatory)][string]$Phase,
            [Parameter(Mandatory)][object]$Verification
        )

        [pscustomobject]@{
            Attempt           = $Attempt
            Phase             = $Phase
            Status            = [string]$Verification.Status
            Detected          = (Get-BoostLabMemoryCompressionPropertyValue `
                -InputObject $Verification.DetectedState `
                -Name 'MemoryCompression' `
                -DefaultValue 'Unknown')
            Message           = [string]$Verification.Message
        }
    }

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
    $expected = $ActionName -eq 'Default'
    $verificationAttempts = [System.Collections.Generic.List[object]]::new()
    $commandAttemptCount = 1
    $reassertionAttempted = $false
    $reassertionFailed = $false
    $reassertionFailureMessage = ''
    $verificationResult = Test-BoostLabMemoryCompressionState `
        -ActionName $ActionName `
        -StateReader $StateReader
    $verificationAttempts.Add((New-MemoryCompressionAttemptRecord -Attempt 1 -Phase 'InitialVerification' -Verification $verificationResult))

    if ($verificationResult.Status -eq 'Failed') {
        $reassertionAttempted = $true
        try {
            & $DelayInvoker $VerificationRetryDelayMilliseconds
            & $CommandInvoker $ActionName | Out-Null
            $commandAttemptCount++
            $retryVerification = Test-BoostLabMemoryCompressionState `
                -ActionName $ActionName `
                -StateReader $StateReader
            $verificationAttempts.Add((New-MemoryCompressionAttemptRecord -Attempt 2 -Phase 'AfterReassertion' -Verification $retryVerification))
            $verificationResult = $retryVerification
        }
        catch {
            $reassertionFailed = $true
            $reassertionFailureMessage = $_.Exception.Message
        }
    }

    $detected = Get-BoostLabMemoryCompressionPropertyValue `
        -InputObject $verificationResult.DetectedState `
        -Name 'MemoryCompression' `
        -DefaultValue 'Unknown'
    $recoveredByReassertion = ($reassertionAttempted -and -not $reassertionFailed -and $verificationResult.Status -eq 'Passed')
    if ($reassertionFailed) {
        $verificationResult = New-BoostLabMemoryCompressionFinalVerification `
            -ActionName $ActionName `
            -Expected $expected `
            -Actual $detected `
            -Status 'Failed' `
            -CheckMessage "Reasserting the source MMAgent command failed: $reassertionFailureMessage" `
            -Message 'Memory Compression verification reassertion failed.'
    }
    elseif ($verificationResult.Status -eq 'Warning') {
        $verificationResult = New-BoostLabMemoryCompressionFinalVerification `
            -ActionName $ActionName `
            -Expected $expected `
            -Actual $detected `
            -Status 'Failed' `
            -CheckMessage 'Get-MMAgent did not return a verified MemoryCompression state.' `
            -Message 'Memory Compression verification was unavailable after the source command completed.'
    }
    elseif ($recoveredByReassertion) {
        $verificationResult = New-BoostLabMemoryCompressionFinalVerification `
            -ActionName $ActionName `
            -Expected $expected `
            -Actual $detected `
            -Status 'Warning' `
            -CheckMessage 'MemoryCompression initially remained unexpected, then matched after one bounded source-command reassertion.' `
            -Message 'Memory Compression matched the expected state after one bounded reassertion.'
    }

    $verificationStatus = [string]$verificationResult.Status
    $success = $verificationStatus -ne 'Failed'
    $finalStatusReason = if ($verificationStatus -eq 'Passed') {
        'MemoryCompressionVerified'
    }
    elseif ($recoveredByReassertion) {
        'MemoryCompressionVerifiedAfterReassertion'
    }
    elseif ($reassertionFailed) {
        'MemoryCompressionReassertionFailed'
    }
    elseif ($verificationAttempts[0].Status -eq 'Warning') {
        'MemoryCompressionVerificationUnavailable'
    }
    else {
        'MemoryCompressionVerificationMismatch'
    }
    $data = [pscustomobject]@{
        CommandStatus              = if ($success -and $verificationStatus -eq 'Warning') { 'Completed with warnings' } else { 'Completed' }
        VerificationStatus         = $verificationStatus
        FinalStatusReason          = $finalStatusReason
        ExpectedMemoryCompression = $expected
        DetectedMemoryCompression = $detected
        CommandAttemptCount        = $commandAttemptCount
        ReassertionAttempted       = $reassertionAttempted
        ReassertionFailure         = $reassertionFailed
        ReassertionFailureMessage  = $reassertionFailureMessage
        VerificationAttempts       = $verificationAttempts.ToArray()
        CompletedAt                = $completedAt
    }
    $message = if ($recoveredByReassertion) {
        'Memory Compression command completed; initial verification remained unexpected, but one bounded reassertion reached the expected state.'
    }
    elseif ($verificationStatus -eq 'Failed' -and $finalStatusReason -eq 'MemoryCompressionVerificationUnavailable') {
        'Memory Compression command completed, but verification was unavailable.'
    }
    elseif ($verificationStatus -eq 'Failed') {
        'Memory Compression command completed, but verification detected an unexpected state.'
    }
    elseif ($ActionName -eq 'Apply') {
        'Memory compression disabled.'
    }
    else {
        'Memory compression restored to default.'
    }

    return New-BoostLabMemoryCompressionResult `
        -Success $success `
        -Action $ActionName `
        -Status $(if (-not $success) { 'Failed' } elseif ($verificationStatus -eq 'Warning') { 'Warning' } else { 'Passed' }) `
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
