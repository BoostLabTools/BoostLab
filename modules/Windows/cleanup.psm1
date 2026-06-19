Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'cleanup'; Title = 'Cleanup'; Stage = 'Windows'; Order = 21
    Type = 'action'; RiskLevel = 'medium'
    Description = 'Analyze removable temporary data before preparing a cleanup operation.'
    Actions = @('Analyze', 'Apply')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
