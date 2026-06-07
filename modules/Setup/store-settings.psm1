Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'store-settings'; Title = 'Store Settings'; Stage = 'Setup'; Order = 7
    Type = 'assistant'; RiskLevel = 'low'
    Description = 'Open Microsoft Store settings for update and preference review.'
    Actions = @('Open')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
