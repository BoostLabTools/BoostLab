Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'signout-lockscreen-wallpaper-black'; Title = 'Signout LockScreen Wallpaper Black'; Stage = 'Windows'; Order = 5
    Type = 'action'; RiskLevel = 'low'
    Description = 'Apply or reset the approved black sign-out and lock-screen appearance.'
    Actions = @('Apply', 'Default')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
