Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'spectre-meltdown-assistant'; Title = 'Spectre / Meltdown Assistant'; Stage = 'Advanced'; Order = 1
    Type = 'assistant'; RiskLevel = 'high'
    Description = 'Analyze mitigation state and explain security and performance tradeoffs.'
    Actions = @('Analyze', 'Apply', 'Default')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
