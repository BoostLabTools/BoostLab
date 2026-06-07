Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'bloatware'; Title = 'Bloatware'; Stage = 'Windows'; Order = 11
    Type = 'assistant'; RiskLevel = 'medium'
    Description = 'Analyze installed applications before preparing a reviewed removal plan.'
    Actions = @('Analyze', 'Apply', 'Restore')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
