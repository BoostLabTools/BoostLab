Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'memory-compression'; Title = 'Memory Compression'; Stage = 'Setup'; Order = 1
    Type = 'action'; RiskLevel = 'medium'
    Description = 'Review and manage the Windows memory compression setting.'
    Actions = @('Analyze', 'Apply', 'Default')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
