Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'pointer-precision'; Title = 'Pointer Precision'; Stage = 'Windows'; Order = 10
    Type = 'action'; RiskLevel = 'low'
    Description = 'Manage the reversible enhanced pointer precision preference.'
    Actions = @('Apply', 'Default')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
