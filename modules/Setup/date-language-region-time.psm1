Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'date-language-region-time'; Title = 'Date Language Region Time'; Stage = 'Setup'; Order = 2
    Type = 'assistant'; RiskLevel = 'low'
    Description = 'Open the Windows pages for date, time, language, and regional settings.'
    Actions = @('Open')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
