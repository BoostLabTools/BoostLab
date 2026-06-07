Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'context-menu'; Title = 'Context Menu'; Stage = 'Windows'; Order = 3
    Type = 'action'; RiskLevel = 'low'
    Description = 'Manage the reversible Windows context menu preference.'
    Actions = @('Apply', 'Default')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
