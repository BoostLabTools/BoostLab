Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'resizable-bar-assistant'; Title = 'Resizable BAR Assistant'; Stage = 'Advanced'; Order = 3
    Type = 'assistant'; RiskLevel = 'high'
    Description = 'Analyze hardware support and explain firmware requirements for Resizable BAR.'
    Actions = @('Analyze', 'Open')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
