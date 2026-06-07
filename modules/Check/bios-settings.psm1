Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'bios-settings'; Title = 'BIOS Settings'; Stage = 'Check'; Order = 2
    Type = 'assistant'; RiskLevel = 'high'
    Description = 'Review firmware settings guidance before opening BIOS configuration.'
    Actions = @('Analyze', 'Open')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
