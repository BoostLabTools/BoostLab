Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'start-menu-taskbar'; Title = 'Start Menu Taskbar'; Stage = 'Windows'; Order = 1
    Type = 'assistant'; RiskLevel = 'low'
    Description = 'Open Windows personalization controls for Start and taskbar settings.'
    Actions = @('Open')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
