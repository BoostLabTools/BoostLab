Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'network-adapter-power-savings-wake'; Title = 'Network Adapter Power Savings & Wake'; Stage = 'Windows'; Order = 19
    Type = 'assistant'; RiskLevel = 'low'
    Description = 'Open network adapter properties for guided power and wake settings.'
    Actions = @('Open')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
