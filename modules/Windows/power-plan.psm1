Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'power-plan'; Title = 'Power Plan'; Stage = 'Windows'; Order = 21
    Type = 'action'; RiskLevel = 'medium'
    Description = 'Apply or reset the approved Windows power plan configuration.'
    Actions = @('Apply', 'Default')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
