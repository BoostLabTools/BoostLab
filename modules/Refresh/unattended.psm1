Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'unattended'; Title = 'Unattended'; Stage = 'Refresh'; Order = 2
    Type = 'action'; RiskLevel = 'high'
    Description = 'Prepare unattended Windows setup options for review before use.'
    Actions = @('Analyze', 'Apply', 'Default')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
