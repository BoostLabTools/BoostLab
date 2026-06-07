Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'sound'; Title = 'Sound'; Stage = 'Windows'; Order = 16
    Type = 'assistant'; RiskLevel = 'low'
    Description = 'Open Windows sound settings for device and output configuration.'
    Actions = @('Open')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
