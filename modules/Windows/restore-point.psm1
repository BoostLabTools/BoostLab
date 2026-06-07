Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'restore-point'; Title = 'Restore Point'; Stage = 'Windows'; Order = 23
    Type = 'action'; RiskLevel = 'low'
    Description = 'Prepare a Windows restore point or open recovery options.'
    Actions = @('Apply', 'Open')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
