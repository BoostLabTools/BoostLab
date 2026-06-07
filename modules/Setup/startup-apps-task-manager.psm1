Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'startup-apps-task-manager'; Title = 'Startup Apps (Task Manager)'; Stage = 'Setup'; Order = 4
    Type = 'assistant'; RiskLevel = 'low'
    Description = 'Open Task Manager for detailed startup application review.'
    Actions = @('Open')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
