Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'write-cache-buffer-flushing'; Title = 'Write Cache Buffer Flushing'; Stage = 'Windows'; Order = 20
    Type = 'assistant'; RiskLevel = 'high'
    Description = 'Analyze storage hardware before changing write-cache buffer flushing.'
    Actions = @('Analyze', 'Apply', 'Default')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
