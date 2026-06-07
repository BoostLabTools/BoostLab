Set-StrictMode -Version Latest

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
