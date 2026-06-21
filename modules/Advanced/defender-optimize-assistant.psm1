Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'defender-optimize-assistant'; Title = 'Defender Optimize Assistant'; Stage = 'Advanced'; Order = 5
    Type = 'assistant'; RiskLevel = 'high'
    Description = 'Analyze Microsoft Defender settings before recommending approved changes.'
    Actions = @('Analyze', 'Apply', 'Restore')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
