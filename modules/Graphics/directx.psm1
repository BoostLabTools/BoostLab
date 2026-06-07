Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'directx'; Title = 'DirectX'; Stage = 'Graphics'; Order = 2
    Type = 'action'; RiskLevel = 'medium'
    Description = 'Review and prepare the approved DirectX runtime installation.'
    Actions = @('Analyze', 'Apply')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
