Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'timer-resolution-assistant'; Title = 'Timer Resolution Assistant'; Stage = 'Advanced'; Order = 6
    Type = 'assistant'; RiskLevel = 'high'
    Description = 'Analyze timer behavior and explain latency, power, and stability tradeoffs.'
    Actions = @('Analyze', 'Apply', 'Default')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
