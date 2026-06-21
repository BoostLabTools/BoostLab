Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'services-optimizer'; Title = 'Services Optimizer'; Stage = 'Advanced'; Order = 3
    Type = 'assistant'; RiskLevel = 'high'
    Description = 'Analyze Windows services and prepare a reviewed optimization plan.'
    Actions = @('Analyze', 'Apply', 'Restore')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
