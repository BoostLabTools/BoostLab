Set-StrictMode -Version Latest

$script:BoostLabVerificationStatuses = @(
    'Passed'
    'Warning'
    'Failed'
    'NotApplicable'
    'NotImplemented'
)

function Get-BoostLabVerificationPropertyValue {
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$Name
    )

    if ($null -eq $InputObject) {
        return $null
    }
    if ($InputObject -is [System.Collections.IDictionary]) {
        if ($InputObject.Contains($Name)) {
            return $InputObject[$Name]
        }

        return $null
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function New-BoostLabVerificationCheck {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
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
        Name     = $Name
        Expected = $Expected
        Actual   = $Actual
        Status   = $Status
        Message  = $Message
    }
}

function New-BoostLabVerificationResult {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ToolTitle,

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
        [string]$Message,

        [datetime]$Timestamp = (Get-Date)
    )

    return [pscustomobject]@{
        ToolId        = $ToolId
        ToolTitle     = $ToolTitle
        Action        = $Action
        Status        = $Status
        ExpectedState = $ExpectedState
        DetectedState = $DetectedState
        Checks        = @($Checks)
        Message       = $Message
        Timestamp     = $Timestamp
    }
}

function Get-BoostLabVerificationValidation {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$VerificationResult,

        [string]$ExpectedToolId = '',

        [string]$ExpectedToolTitle = '',

        [string]$ExpectedAction = ''
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $requiredFields = @(
        'ToolId'
        'ToolTitle'
        'Action'
        'Status'
        'ExpectedState'
        'DetectedState'
        'Checks'
        'Message'
        'Timestamp'
    )
    foreach ($field in $requiredFields) {
        if ($null -eq $VerificationResult.PSObject.Properties[$field]) {
            $errors.Add("VerificationResult is missing field: $field")
        }
    }

    $status = [string](Get-BoostLabVerificationPropertyValue -InputObject $VerificationResult -Name 'Status')
    if ($status -notin $script:BoostLabVerificationStatuses) {
        $errors.Add("VerificationResult has unsupported status: $status")
    }

    $toolId = [string](Get-BoostLabVerificationPropertyValue -InputObject $VerificationResult -Name 'ToolId')
    $toolTitle = [string](Get-BoostLabVerificationPropertyValue -InputObject $VerificationResult -Name 'ToolTitle')
    $action = [string](Get-BoostLabVerificationPropertyValue -InputObject $VerificationResult -Name 'Action')
    if (-not [string]::IsNullOrWhiteSpace($ExpectedToolId) -and $toolId -ne $ExpectedToolId) {
        $errors.Add("VerificationResult ToolId '$toolId' does not match '$ExpectedToolId'.")
    }
    if (-not [string]::IsNullOrWhiteSpace($ExpectedToolTitle) -and $toolTitle -ne $ExpectedToolTitle) {
        $errors.Add("VerificationResult ToolTitle '$toolTitle' does not match '$ExpectedToolTitle'.")
    }
    if (-not [string]::IsNullOrWhiteSpace($ExpectedAction) -and $action -ne $ExpectedAction) {
        $errors.Add("VerificationResult Action '$action' does not match '$ExpectedAction'.")
    }

    $checksValue = Get-BoostLabVerificationPropertyValue -InputObject $VerificationResult -Name 'Checks'
    $checks = if ($null -eq $checksValue) {
        @()
    }
    else {
        @($checksValue)
    }
    foreach ($check in $checks) {
        if ($null -eq $check) {
            $errors.Add('VerificationResult contains a null check entry.')
            continue
        }

        foreach ($field in @('Name', 'Expected', 'Actual', 'Status', 'Message')) {
            if ($null -eq $check.PSObject.Properties[$field]) {
                $errors.Add("Verification check is missing field: $field")
            }
        }

        $checkStatus = [string](Get-BoostLabVerificationPropertyValue -InputObject $check -Name 'Status')
        if ($checkStatus -notin $script:BoostLabVerificationStatuses) {
            $errors.Add("Verification check has unsupported status: $checkStatus")
        }
    }

    return [pscustomobject]@{
        IsValid   = $errors.Count -eq 0
        Errors    = $errors.ToArray()
        Timestamp = Get-Date
    }
}

function Test-BoostLabVerificationResult {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$VerificationResult,

        [string]$ExpectedToolId = '',

        [string]$ExpectedToolTitle = '',

        [string]$ExpectedAction = ''
    )

    Get-BoostLabVerificationValidation `
        -VerificationResult $VerificationResult `
        -ExpectedToolId $ExpectedToolId `
        -ExpectedToolTitle $ExpectedToolTitle `
        -ExpectedAction $ExpectedAction
}

Export-ModuleMember -Function @(
    'New-BoostLabVerificationCheck'
    'New-BoostLabVerificationResult'
    'Get-BoostLabVerificationValidation'
    'Test-BoostLabVerificationResult'
)
