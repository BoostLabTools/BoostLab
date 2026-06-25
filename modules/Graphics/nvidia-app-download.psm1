Set-StrictMode -Version Latest

$script:BoostLabNvidiaAppDownloadUrl = 'https://www.nvidia.com/en-us/software/nvidia-app/'
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'nvidia-app-download'; Title = 'Install NVIDIA App'; Stage = 'Graphics'; Order = 3
    Type = 'assistant'; RiskLevel = 'low'
    Description = 'Open the official NVIDIA App webpage in the default browser. BoostLab does not download, install, or change system settings for this shortcut.'
    Actions = @('Open')
    Capabilities = [ordered]@{
        RequiresAdmin = $false; RequiresInternet = $true; CanReboot = $false
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
        Url                = $script:BoostLabNvidiaAppDownloadUrl
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
        Reason    = 'The official NVIDIA App webpage can be opened by this shortcut.'
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

function Invoke-BoostLabNvidiaAppDownloadOpen {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [scriptblock]$UrlOpener
    )

    if ($null -eq $UrlOpener) {
        $UrlOpener = { param([string]$Url) Start-Process $Url }
    }

    try {
        & $UrlOpener $script:BoostLabNvidiaAppDownloadUrl
        return [pscustomobject]@{
            Success         = $true
            ToolId          = [string]$script:BoostLabToolMetadata['Id']
            ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
            Action          = 'Open'
            Message         = 'Opened the official NVIDIA App webpage.'
            Url             = $script:BoostLabNvidiaAppDownloadUrl
            ChangesExecuted = $false
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
            Message         = "NVIDIA App webpage launch failed: $($_.Exception.Message)"
            Url             = $script:BoostLabNvidiaAppDownloadUrl
            ChangesExecuted = $false
            RestartRequired = $false
            Timestamp       = Get-Date
        }
    }
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ActionName,

        [scriptblock]$UrlOpener
    )

    if ($ActionName -ne 'Open') {
        return [pscustomobject]@{
            Success         = $false
            ToolId          = [string]$script:BoostLabToolMetadata['Id']
            ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
            Action          = $ActionName
            Message         = 'Unsupported action. Only Open is allowed.'
            ChangesExecuted = $false
            RestartRequired = $false
            Timestamp       = Get-Date
        }
    }

    return Invoke-BoostLabNvidiaAppDownloadOpen -UrlOpener $UrlOpener
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
        ChangesExecuted = $false
        RestartRequired = $false
        Timestamp       = Get-Date
    }
}

Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault', 'Invoke-BoostLabNvidiaAppDownloadOpen')
