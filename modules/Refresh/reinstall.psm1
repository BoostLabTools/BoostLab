Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'reinstall'; Title = 'Reinstall'; Stage = 'Refresh'; Order = 1
    Type = 'assistant'; RiskLevel = 'high'
    Description = 'Review prerequisites and prepare a guided Windows reinstall workflow.'
    Actions = @('Analyze', 'Apply')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
