Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'driver-install-debloat-settings'; Title = 'Driver Install Debloat & Settings'; Stage = 'Graphics'; Order = 6
    Type = 'assistant'; RiskLevel = 'high'
    Description = 'Analyze graphics hardware and prepare a guided driver installation workflow.'
    Actions = @('Analyze', 'Apply', 'Restore')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
