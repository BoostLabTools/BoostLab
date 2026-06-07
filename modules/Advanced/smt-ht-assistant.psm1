Set-StrictMode -Version Latest
$script:BoostLabToolMetadata = [ordered]@{
    Id = 'smt-ht-assistant'; Title = 'SMT / HT Assistant'; Stage = 'Advanced'; Order = 4
    Type = 'assistant'; RiskLevel = 'high'
    Description = 'Analyze processor topology and explain SMT or Hyper-Threading tradeoffs.'
    Actions = @('Analyze', 'Open')
}
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'ToolModule.Placeholder.ps1')
Export-ModuleMember -Function @('Get-BoostLabToolInfo', 'Test-BoostLabToolCompatibility', 'Get-BoostLabToolState', 'Invoke-BoostLabToolAction', 'Restore-BoostLabToolDefault')
