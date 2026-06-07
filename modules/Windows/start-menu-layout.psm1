Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'start-menu-layout'; Title = 'Start Menu Layout'; Stage = 'Windows'; Order = 2
    Type = 'action'; RiskLevel = 'low'
    Description = 'Manage the reversible BoostLab Start menu layout preference.'
    Actions = @('Apply', 'Default')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
