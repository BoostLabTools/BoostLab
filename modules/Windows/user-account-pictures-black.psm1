Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'user-account-pictures-black'; Title = 'User Account Pictures Black'; Stage = 'Windows'; Order = 6
    Type = 'action'; RiskLevel = 'low'
    Description = 'Apply or restore the approved black user account image set.'
    Actions = @('Apply', 'Restore')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
