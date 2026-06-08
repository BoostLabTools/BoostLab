Set-StrictMode -Version Latest

function Test-BoostLabTrustedInstallerSupported {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        Supported = $false
        Status    = 'NotImplemented'
        Message   = 'TrustedInstaller execution is not implemented in this phase.'
        Timestamp = Get-Date
    }
}

function New-BoostLabTrustedInstallerPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$ToolMetadata,

        [Parameter(Mandatory)]
        [string]$ActionName
    )

    $capabilities = if (
        $ToolMetadata.Contains('Capabilities') -and
        $ToolMetadata['Capabilities'] -is [System.Collections.IDictionary]
    ) {
        $ToolMetadata['Capabilities']
    }
    else {
        @{}
    }
    $usesTrustedInstaller = (
        $capabilities.Contains('UsesTrustedInstaller') -and
        [bool]$capabilities['UsesTrustedInstaller']
    )

    return [pscustomobject]@{
        ToolId                    = [string]$ToolMetadata['Id']
        ToolTitle                 = [string]$ToolMetadata['Title']
        Action                    = $ActionName
        Status                    = 'NotImplemented'
        UsesTrustedInstaller      = $usesTrustedInstaller
        RequiresAdmin             = $true
        NeedsExplicitConfirmation = $true
        Summary                   = 'Describe a future approved TrustedInstaller execution request without running it.'
        PlannedChanges            = @('No command will execute in Phase 14.5.')
        Message                   = 'TrustedInstaller execution planning is available, but command execution is not implemented.'
        Timestamp                 = Get-Date
    }
}

function Invoke-BoostLabTrustedInstallerCommand {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$ToolMetadata,

        [Parameter(Mandatory)]
        [string]$ActionName,

        [string]$CommandDescription = ''
    )

    return [pscustomobject]@{
        Success         = $false
        Status          = 'NotImplemented'
        ToolId          = [string]$ToolMetadata['Id']
        ToolTitle       = [string]$ToolMetadata['Title']
        Action          = $ActionName
        Message         = 'TrustedInstaller command execution is not implemented yet.'
        CommandExecuted = $false
        RestartRequired = $false
        Timestamp       = Get-Date
    }
}

Export-ModuleMember -Function @(
    'Test-BoostLabTrustedInstallerSupported'
    'New-BoostLabTrustedInstallerPlan'
    'Invoke-BoostLabTrustedInstallerCommand'
)
