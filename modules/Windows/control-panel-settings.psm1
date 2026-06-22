Set-StrictMode -Version Latest

$script:BoostLabImplementedActions = @('Apply', 'Default')
$script:BoostLabExpectedSourceHash = 'B78F643D21069F14E7E766769FB1EE15AEF974ABDF3CA010FE808D9EC162FB0B'
$script:BoostLabExpectedCanonicalSourceHash = 'F81FB649A4645A5145B43A051DDF8306145E64F1FCA5249F90B66BFDFA97BE83'
$script:BoostLabSourceRelativePath = 'source-ultimate\6 Windows\15 Control Panel Settings.ps1'

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'control-panel-settings'; Title = 'Control Panel Settings'; Stage = 'Windows'; Order = 15
    Type = 'action'; RiskLevel = 'high'
    Description = 'Run the exact source-defined Control Panel Settings Optimize or Default branch after explicit confirmation.'
    Actions = @('Apply', 'Default')
    Capabilities = [ordered]@{
        RequiresAdmin             = $true
        RequiresInternet          = $false
        CanReboot                 = $false
        CanModifyRegistry         = $true
        CanModifyServices         = $true
        CanInstallSoftware        = $false
        CanDownload               = $false
        CanModifyDrivers          = $false
        CanModifySecurity         = $true
        CanDeleteFiles            = $true
        UsesTrustedInstaller      = $true
        UsesSafeMode              = $false
        SupportsDefault           = $true
        SupportsRestore           = $false
        NeedsExplicitConfirmation = $true
    }
}

function Get-BoostLabControlPanelSettingsProjectRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

function Get-BoostLabControlPanelSettingsSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Join-Path (Get-BoostLabControlPanelSettingsProjectRoot) $script:BoostLabSourceRelativePath
}

function Get-BoostLabControlPanelSettingsSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [scriptblock]$HashReader = $null
    )

    $sourcePath = Get-BoostLabControlPanelSettingsSourcePath
    if ($null -ne $HashReader) {
        $exists = Test-Path -LiteralPath $sourcePath -PathType Leaf
        $detectedHash = ''
        if ($exists) {
            $detectedHash = [string](& $HashReader $sourcePath)
        }

        return [pscustomobject]@{
            SourcePath                = $sourcePath
            SourceRelativePath        = $script:BoostLabSourceRelativePath
            Exists                    = $exists
            ExpectedSha256            = $script:BoostLabExpectedSourceHash
            DetectedSha256            = $detectedHash
            ExpectedCanonicalSha256   = $script:BoostLabExpectedCanonicalSourceHash
            DetectedCanonicalSha256   = ''
            ChecksumStatus            = if ($exists -and $detectedHash -eq $script:BoostLabExpectedSourceHash) { 'Passed' } elseif ($exists) { 'Failed' } else { 'Missing' }
            RawChecksumStatus         = if ($exists -and $detectedHash -eq $script:BoostLabExpectedSourceHash) { 'Passed' } elseif ($exists) { 'Failed' } else { 'Missing' }
            CanonicalChecksumStatus   = 'NotAvailableForCustomHashReader'
            VerificationMode          = if ($exists -and $detectedHash -eq $script:BoostLabExpectedSourceHash) { 'ExactRawSha256' } elseif ($exists) { 'Failed' } else { 'Missing' }
        }
    }

    $projectRoot = Get-BoostLabControlPanelSettingsProjectRoot
    $sourceVerificationModulePath = Join-Path $projectRoot 'core\SourceVerification.psm1'
    if (-not (Get-Command -Name 'Test-BoostLabSourceChecksum' -ErrorAction SilentlyContinue)) {
        Import-Module -Name $sourceVerificationModulePath -Scope Local -Force -ErrorAction Stop
    }

    $verification = Test-BoostLabSourceChecksum -LiteralPath $sourcePath -ExpectedSha256 $script:BoostLabExpectedSourceHash -ExpectedCanonicalSha256 $script:BoostLabExpectedCanonicalSourceHash

    [pscustomobject]@{
        SourcePath                = $sourcePath
        SourceRelativePath        = $script:BoostLabSourceRelativePath
        Exists                    = [bool]$verification.Exists
        ExpectedSha256            = $script:BoostLabExpectedSourceHash
        DetectedSha256            = [string]$verification.DetectedSha256
        ExpectedCanonicalSha256   = $script:BoostLabExpectedCanonicalSourceHash
        DetectedCanonicalSha256   = [string]$verification.DetectedCanonicalSha256
        ChecksumStatus            = [string]$verification.ChecksumStatus
        RawChecksumStatus         = [string]$verification.RawChecksumStatus
        CanonicalChecksumStatus   = [string]$verification.CanonicalChecksumStatus
        VerificationMode          = [string]$verification.VerificationMode
    }
}

function Test-BoostLabControlPanelSettingsAdministrator {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function Get-BoostLabControlPanelSettingsSourceText {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [scriptblock]$SourceReader = {
            param([string]$Path)
            Get-Content -LiteralPath $Path -Raw
        }
    )

    $sourcePath = Get-BoostLabControlPanelSettingsSourcePath
    return [string](& $SourceReader $sourcePath)
}

function Get-BoostLabControlPanelSettingsSourceLines {
    param([Parameter(Mandatory)][string]$SourceText)

    return @($SourceText -split "`r?`n")
}

function Get-BoostLabControlPanelSettingsRunTrustedBlock {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$SourceText
    )

    $lines = Get-BoostLabControlPanelSettingsSourceLines -SourceText $SourceText
    $start = -1
    $endExclusive = -1
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '^\s*function\s+Run-Trusted') {
            $start = $index
        }
        if ($start -ge 0 -and $lines[$index] -match 'Write-Host\s+"1\.\s+Control Panel Settings') {
            $endExclusive = $index
            break
        }
    }
    if ($start -lt 0 -or $endExclusive -le $start) {
        throw 'Unable to extract the source Run-Trusted helper.'
    }

    return (($lines[$start..($endExclusive - 1)]) -join "`r`n").Trim()
}

function Get-BoostLabControlPanelSettingsBranchScript {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [Parameter(Mandatory)]
        [string]$SourceText
    )

    $lines = Get-BoostLabControlPanelSettingsSourceLines -SourceText $SourceText
    $marker = if ($ActionName -eq 'Apply') {
        'Write-Host "Control Panel Settings: Optimize..."'
    }
    else {
        'Write-Host "Control Panel Settings: Default..."'
    }

    $markerIndex = -1
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index].Trim() -eq $marker) {
            $markerIndex = $index
            break
        }
    }
    if ($markerIndex -lt 0) {
        throw "Unable to find source branch marker for $ActionName."
    }

    $start = $markerIndex
    for ($index = $markerIndex; $index -ge [Math]::Max(0, $markerIndex - 6); $index--) {
        if ($lines[$index].Trim() -eq 'Clear-Host') {
            $start = $index
            break
        }
    }

    $endExclusive = -1
    for ($index = $markerIndex + 1; $index -lt $lines.Count; $index++) {
        if ($lines[$index].Trim() -ieq 'exit') {
            $endExclusive = $index
            break
        }
    }
    if ($endExclusive -le $start) {
        throw "Unable to find source branch terminator for $ActionName."
    }

    $runTrusted = Get-BoostLabControlPanelSettingsRunTrustedBlock -SourceText $SourceText
    $branch = (($lines[$start..($endExclusive - 1)]) -join "`r`n").Trim()
    $scriptText = ($runTrusted + "`r`n`r`n" + $branch).Trim()

    [pscustomobject]@{
        ActionName = $ActionName
        SourceMenuBranch = if ($ActionName -eq 'Apply') { 'Control Panel Settings: Optimize (Recommended)' } else { 'Control Panel Settings: Default' }
        ScriptText = $scriptText
        ScriptLineCount = @($scriptText -split "`r?`n").Count
        ContainsRunTrusted = $scriptText.Contains('function Run-Trusted')
        ContainsRegistryPayload = $scriptText.Contains('Windows Registry Editor Version 5.00')
        ContainsExit = [regex]::IsMatch($scriptText, '(?m)^\s*exit\s*$')
    }
}

function Get-BoostLabControlPanelSettingsSourceSummary {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$SourceText
    )

    $apply = Get-BoostLabControlPanelSettingsBranchScript -ActionName Apply -SourceText $SourceText
    $default = Get-BoostLabControlPanelSettingsBranchScript -ActionName Default -SourceText $SourceText
    [pscustomobject]@{
        AvailableActions = @('Apply', 'Default')
        ApplyBranch = $apply.SourceMenuBranch
        DefaultBranch = $default.SourceMenuBranch
        OpenSupported = $false
        RestoreSupported = $false
        RequiresAdmin = $true
        UsesTrustedInstaller = $SourceText.Contains('function Run-Trusted')
        RegistryFiles = @(
            'registryoptimize.reg'
            'registrydefaults.reg'
            'disablesetprioritynotifications.reg'
            'appactions.reg'
        )
        RegistryRoots = @('HKCU', 'HKLM', 'HKCR', 'HKEY_USERS')
        ServiceActions = @('Stop-Service camsvc', 'TrustedInstaller service binPath/start/stop', 'CDPUserSvc Start')
        ScheduledTaskActions = @('Disable ScheduledDefrag', 'Enable ScheduledDefrag')
        PowerCfgActions = @('consolelock dc/ac value writes')
        ProcessActions = @('Stop AppActions/CrossDeviceResume/DesktopStickerEditor/SearchHost/TextInputHost/WebExperienceHostApp and related processes')
        FileActions = @(
            'Remove ProgramData CapabilityConsentStorage.db* through Run-Trusted'
            'Write Windows Temp registry files'
            'Delete MicrosoftWindows.Client.CBS settings.dat on Default'
        )
        ApplyScriptLineCount = $apply.ScriptLineCount
        DefaultScriptLineCount = $default.ScriptLineCount
    }
}

function Invoke-BoostLabControlPanelSettingsScript {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ScriptText,

        [Parameter(Mandatory)]
        [string]$ActionName
    )

    try {
        $scriptBlock = [scriptblock]::Create($ScriptText)
        & $scriptBlock
        return [pscustomobject]@{
            Success = $true
            Message = 'Source branch script completed.'
            ExitCode = 0
        }
    }
    catch {
        return [pscustomobject]@{
            Success = $false
            Message = $_.Exception.Message
            ExitCode = 1
        }
    }
}

function New-BoostLabControlPanelSettingsResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Message,

        [AllowNull()]
        [object]$Data = $null,

        [bool]$Cancelled = $false
    )

    [pscustomobject]@{
        Success = $Success
        ToolId = 'control-panel-settings'
        ToolTitle = 'Control Panel Settings'
        Action = $Action
        Status = $Status
        Message = $Message
        RestartRequired = $false
        Cancelled = $Cancelled
        Data = $Data
        Timestamp = Get-Date
    }
}

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        Id = [string]$script:BoostLabToolMetadata['Id']
        Title = [string]$script:BoostLabToolMetadata['Title']
        Stage = [string]$script:BoostLabToolMetadata['Stage']
        Order = [int]$script:BoostLabToolMetadata['Order']
        Type = [string]$script:BoostLabToolMetadata['Type']
        RiskLevel = [string]$script:BoostLabToolMetadata['RiskLevel']
        Description = [string]$script:BoostLabToolMetadata['Description']
        Actions = @($script:BoostLabToolMetadata['Actions'])
        Capabilities = [pscustomobject]$script:BoostLabToolMetadata['Capabilities']
        ImplementedActions = @($script:BoostLabImplementedActions)
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabControlPanelSettingsSourceStatus
    [pscustomobject]@{
        Supported = [bool]($sourceStatus.Exists -and $sourceStatus.ChecksumStatus -eq 'Passed')
        ToolId = 'control-panel-settings'
        ToolTitle = 'Control Panel Settings'
        SourcePath = $sourceStatus.SourcePath
        ExpectedSha256 = $sourceStatus.ExpectedSha256
        DetectedSha256 = $sourceStatus.DetectedSha256
        ChecksumStatus = $sourceStatus.ChecksumStatus
        Reason = if ($sourceStatus.ChecksumStatus -eq 'Passed') {
            'Control Panel Settings source identity is verified.'
        }
        else {
            'Control Panel Settings source identity could not be verified.'
        }
        Timestamp = Get-Date
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabControlPanelSettingsSourceStatus
    [pscustomobject]@{
        ToolId = 'control-panel-settings'
        ToolTitle = 'Control Panel Settings'
        Status = if ($sourceStatus.ChecksumStatus -eq 'Passed') { 'Ready' } else { 'Source verification failed' }
        LastAction = $null
        LastResult = $null
        RestartRequired = $false
        Timestamp = Get-Date
    }
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [bool]$Confirmed = $false,

        [scriptblock]$AdministratorChecker = { Test-BoostLabControlPanelSettingsAdministrator },

        [scriptblock]$SourceReader = {
            param([string]$Path)
            Get-Content -LiteralPath $Path -Raw
        },

        [AllowNull()]
        [scriptblock]$HashReader = $null,

        [scriptblock]$ScriptRunner = {
            param([string]$ScriptText, [string]$ActionName)
            Invoke-BoostLabControlPanelSettingsScript -ScriptText $ScriptText -ActionName $ActionName
        }
    )

    if (-not $Confirmed) {
        return New-BoostLabControlPanelSettingsResult `
            -Success $false `
            -Action $ActionName `
            -Status 'Blocked' `
            -Message 'Explicit confirmation is required before running Control Panel Settings source behavior.' `
            -Cancelled $true
    }

    if (-not (& $AdministratorChecker)) {
        return New-BoostLabControlPanelSettingsResult `
            -Success $false `
            -Action $ActionName `
            -Status 'NeedsAdmin' `
            -Message 'Administrator rights are required for Control Panel Settings source behavior.'
    }

    $sourceStatus = Get-BoostLabControlPanelSettingsSourceStatus -HashReader $HashReader
    if (-not ($sourceStatus.Exists -and $sourceStatus.ChecksumStatus -eq 'Passed')) {
        return New-BoostLabControlPanelSettingsResult `
            -Success $false `
            -Action $ActionName `
            -Status 'SourceVerificationFailed' `
            -Message 'Control Panel Settings source checksum verification failed. No source behavior was executed.' `
            -Data $sourceStatus
    }

    try {
        $sourceText = Get-BoostLabControlPanelSettingsSourceText -SourceReader $SourceReader
        $branch = Get-BoostLabControlPanelSettingsBranchScript -ActionName $ActionName -SourceText $sourceText
        $summary = Get-BoostLabControlPanelSettingsSourceSummary -SourceText $sourceText
        $runResult = & $ScriptRunner $branch.ScriptText $ActionName
        if ($null -eq $runResult) {
            $runResult = [pscustomobject]@{ Success = $false; Message = 'Script runner returned no result.'; ExitCode = 1 }
        }

        $success = [bool]$runResult.Success
        $data = [pscustomobject]@{
            SourcePath = $sourceStatus.SourcePath
            ExpectedSha256 = $sourceStatus.ExpectedSha256
            DetectedSha256 = $sourceStatus.DetectedSha256
            SourceMenuBranch = $branch.SourceMenuBranch
            ScriptLineCount = $branch.ScriptLineCount
            ContainsRunTrusted = $branch.ContainsRunTrusted
            ContainsRegistryPayload = $branch.ContainsRegistryPayload
            ContainsExit = $branch.ContainsExit
            Summary = $summary
            RunnerMessage = [string]$runResult.Message
            RunnerExitCode = if ($runResult.PSObject.Properties['ExitCode']) { $runResult.ExitCode } else { $null }
            ChangesExecuted = $true
            RestoreAvailable = $false
            OpenAvailable = $false
        }

        return New-BoostLabControlPanelSettingsResult `
            -Success $success `
            -Action $ActionName `
            -Status $(if ($success) { 'Completed' } else { 'Failed' }) `
            -Message $(if ($success) { "Control Panel Settings $ActionName source branch completed." } else { "Control Panel Settings $ActionName source branch failed: $($runResult.Message)" }) `
            -Data $data
    }
    catch {
        return New-BoostLabControlPanelSettingsResult `
            -Success $false `
            -Action $ActionName `
            -Status 'Failed' `
            -Message $_.Exception.Message `
            -Data ([pscustomobject]@{
                SourcePath = $sourceStatus.SourcePath
                ExpectedSha256 = $sourceStatus.ExpectedSha256
                DetectedSha256 = $sourceStatus.DetectedSha256
                ChangesExecuted = $false
            })
    }
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([bool]$Confirmed = $false)

    Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed:$Confirmed
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
