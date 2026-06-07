Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'installers'; Title = 'Installers'; Stage = 'Installers'; Order = 1
    Type = 'action'; RiskLevel = 'medium'
    Description = 'Review and prepare approved application installation selections.'
    Actions = @('Open', 'Apply')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
