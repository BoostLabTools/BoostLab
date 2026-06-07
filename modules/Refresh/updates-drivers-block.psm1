Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'updates-drivers-block'; Title = 'Updates Drivers Block'; Stage = 'Refresh'; Order = 3
    Type = 'action'; RiskLevel = 'medium'
    Description = 'Manage the policy that controls driver delivery through Windows Update.'
    Actions = @('Apply', 'Default')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
