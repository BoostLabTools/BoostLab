Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'device-manager-power-savings-wake'; Title = 'Device Manager Power Savings & Wake'; Stage = 'Windows'; Order = 18
    Type = 'assistant'; RiskLevel = 'low'
    Description = 'Open Device Manager for guided power-saving and wake configuration.'
    Actions = @('Open')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
