Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'control-panel-settings'; Title = 'Control Panel Settings'; Stage = 'Windows'; Order = 15
    Type = 'assistant'; RiskLevel = 'low'
    Description = 'Open Control Panel for technician-guided Windows configuration.'
    Actions = @('Open')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
