Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'startup-apps-settings'; Title = 'Startup Apps (Settings)'; Stage = 'Setup'; Order = 3
    Type = 'assistant'; RiskLevel = 'low'
    Description = 'Open the Windows Settings page for startup application management.'
    Actions = @('Open')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
