Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'graphics-configuration-center'; Title = 'Graphics Configuration Center'; Stage = 'Graphics'; Order = 5
    Type = 'assistant'; RiskLevel = 'low'
    Description = 'Open the installed graphics control center for guided configuration.'
    Actions = @('Open')
    Capabilities = [ordered]@{
        RequiresAdmin = $false; RequiresInternet = $false; CanReboot = $false
        CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false
        CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false
        CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false
        SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $false
    }
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
        Capabilities       = [pscustomobject]$script:BoostLabToolMetadata['Capabilities']
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
        Reason    = 'Windows advanced graphics settings URI is supported by this tool.'
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
        Start-Process "ms-settings:display-advancedgraphics"
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
