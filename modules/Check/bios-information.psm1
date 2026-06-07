Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'bios-information'; Title = 'BIOS Information'; Stage = 'Check'; Order = 1
    Type = 'assistant'; RiskLevel = 'low'
    Description = 'Review detected BIOS, firmware, and motherboard information.'
    Actions = @('Analyze')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
