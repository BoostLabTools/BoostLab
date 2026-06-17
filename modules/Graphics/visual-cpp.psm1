Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'visual-cpp'; Title = 'Visual C++'; Stage = 'Graphics'; Order = 6
    Type = 'action'; RiskLevel = 'medium'
    Description = 'Review and prepare approved Microsoft Visual C++ runtime installation.'
    Actions = @('Analyze', 'Apply')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
