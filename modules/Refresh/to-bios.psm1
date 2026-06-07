Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'to-bios'; Title = 'To BIOS'; Stage = 'Refresh'; Order = 4
    Type = 'assistant'; RiskLevel = 'high'
    Description = 'Review restart guidance before opening Windows firmware startup options.'
    Actions = @('Analyze', 'Open')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
