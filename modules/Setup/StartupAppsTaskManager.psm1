Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'startup-apps-task-manager'; Title = 'Startup Apps (Task Manager)'; Stage = 'Setup'; Order = 4
    Type = 'assistant'; RiskLevel = 'low'
    Description = 'Open Task Manager for detailed startup application review.'
    Actions = @('Open')
}
$script:BoostLabImplementedActions = @('Open')

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
        ImplementedActions = @($script:BoostLabImplementedActions)
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        Supported = $true
        ToolId    = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason    = 'Task Manager is a built-in Windows component.'
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

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ActionName
    )

    if ($ActionName -ne 'Open') {
        return [pscustomobject]@{
            Success         = $false
            ToolId          = [string]$script:BoostLabToolMetadata['Id']
            ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
            Action          = $ActionName
            Message         = 'Unsupported action. Only Open is allowed.'
            RestartRequired = $false
            Timestamp       = Get-Date
        }
    }

    try {
        Start-Process "taskmgr" -ArgumentList " /0 /startup"
        return [pscustomobject]@{
            Success         = $true
            ToolId          = [string]$script:BoostLabToolMetadata['Id']
            ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
            Action          = 'Open'
            Message         = 'Launched'
            RestartRequired = $false
            Timestamp       = Get-Date
        }
    }
    catch {
        return [pscustomobject]@{
            Success         = $false
            ToolId          = [string]$script:BoostLabToolMetadata['Id']
            ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
            Action          = 'Open'
            Message         = "Launch failed: $($_.Exception.Message)"
            RestartRequired = $false
            Timestamp       = Get-Date
        }
    }
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        Success         = $false
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        Action          = 'Default'
        Message         = 'Action is not declared for this tool.'
        RestartRequired = $false
        Timestamp       = Get-Date
    }
}

Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
