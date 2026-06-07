Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'edge-webview'; Title = 'Edge & WebView'; Stage = 'Windows'; Order = 13
    Type = 'assistant'; RiskLevel = 'medium'
    Description = 'Review Microsoft Edge and WebView components before making changes.'
    Actions = @('Analyze', 'Open')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
