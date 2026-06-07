Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'graphics-configuration-center'; Title = 'Graphics Configuration Center'; Stage = 'Graphics'; Order = 4
    Type = 'assistant'; RiskLevel = 'low'
    Description = 'Open the installed graphics control center for guided configuration.'
    Actions = @('Open')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
