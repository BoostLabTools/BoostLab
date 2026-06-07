Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'loudness-eq'; Title = 'Loudness EQ'; Stage = 'Windows'; Order = 17
    Type = 'assistant'; RiskLevel = 'low'
    Description = 'Open audio device properties for loudness equalization review.'
    Actions = @('Open')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
