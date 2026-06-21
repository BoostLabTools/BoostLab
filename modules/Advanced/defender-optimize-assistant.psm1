Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'defender-optimize-assistant'
    Title = 'Defender Optimize Assistant'
    Stage = 'Advanced'
    Order = 5
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Stage the approved Ultimate Defender Optimize or Defender Default Safe Mode workflow.'
    Actions = @('Analyze', 'Apply', 'Default')
    Capabilities = [ordered]@{
        RequiresAdmin = $true
        RequiresInternet = $false
        CanReboot = $true
        CanModifyRegistry = $true
        CanModifyServices = $true
        CanInstallSoftware = $false
        CanDownload = $false
        CanModifyDrivers = $true
        CanModifySecurity = $true
        CanDeleteFiles = $true
        UsesTrustedInstaller = $true
        UsesSafeMode = $true
        SupportsDefault = $true
        SupportsRestore = $false
        NeedsExplicitConfirmation = $true
    }
}

$script:BoostLabImplementedActions = @('Analyze', 'Apply', 'Default')
$script:BoostLabProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script:BoostLabDefenderSourcePath = Join-Path $script:BoostLabProjectRoot 'source-ultimate\8 Advanced\7 Defender Optimize Assistant.ps1'
$script:BoostLabDefenderSourceHash = '512F12D805715E9232304ABE5BA400BE6B3965D63F77D3B39E4C304507BFB9B6'
$script:BoostLabDefenderScheduledTasks = @(
    'Microsoft\Windows\ExploitGuard\ExploitGuard MDM policy Refresh'
    'Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance'
    'Microsoft\Windows\Windows Defender\Windows Defender Cleanup'
    'Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan'
    'Microsoft\Windows\Windows Defender\Windows Defender Verification'
)

function Test-BoostLabAdministrator {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function Get-BoostLabDefenderPropertyValue {
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$Name,

        [AllowNull()]
        [object]$DefaultValue = $null
    )

    if ($null -eq $InputObject) {
        return $DefaultValue
    }
    if ($InputObject -is [System.Collections.IDictionary]) {
        if ($InputObject.Contains($Name)) {
            return $InputObject[$Name]
        }
        return $DefaultValue
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $DefaultValue
    }
    return $property.Value
}

function New-BoostLabDefenderOptimizeResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$Message,

        [bool]$Cancelled = $false,

        [AllowNull()]
        [object]$Data = $null
    )

    [pscustomobject]@{
        Success = $Success
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Action = $Action
        Message = $Message
        RestartRequired = ($Action -in @('Apply', 'Default') -and $Success)
        Cancelled = $Cancelled
        Timestamp = Get-Date
        Data = $Data
    }
}

function Get-BoostLabDefenderSourceInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$SourcePath = $script:BoostLabDefenderSourcePath
    )

    $exists = Test-Path -LiteralPath $SourcePath -PathType Leaf
    $hash = if ($exists) {
        (Get-FileHash -Algorithm SHA256 -LiteralPath $SourcePath).Hash
    }
    else {
        ''
    }

    [pscustomobject]@{
        SourcePath = $SourcePath
        Exists = $exists
        ExpectedSha256 = $script:BoostLabDefenderSourceHash
        ActualSha256 = $hash
        HashMatches = ($exists -and $hash -eq $script:BoostLabDefenderSourceHash)
    }
}

function Assert-BoostLabDefenderSourceIdentity {
    param(
        [string]$SourcePath = $script:BoostLabDefenderSourcePath
    )

    $sourceInfo = Get-BoostLabDefenderSourceInfo -SourcePath $SourcePath
    if (-not $sourceInfo.Exists) {
        throw "Defender Optimize Assistant Ultimate source is missing: $SourcePath"
    }
    if (-not $sourceInfo.HashMatches) {
        throw "Defender Optimize Assistant Ultimate source hash mismatch. Expected $($sourceInfo.ExpectedSha256), detected $($sourceInfo.ActualSha256)."
    }
    return $sourceInfo
}

function Get-BoostLabDefenderSourceText {
    param(
        [string]$SourcePath = $script:BoostLabDefenderSourcePath
    )

    Assert-BoostLabDefenderSourceIdentity -SourcePath $SourcePath | Out-Null
    return Get-Content -Raw -LiteralPath $SourcePath
}

function Get-BoostLabDefenderScriptPayload {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [string]$SourcePath = $script:BoostLabDefenderSourcePath
    )

    $source = Get-BoostLabDefenderSourceText -SourcePath $SourcePath
    $variableName = if ($ActionName -eq 'Apply') { 'DefenderOptimize' } else { 'DefenderDefault' }
    $fileStem = if ($ActionName -eq 'Apply') { 'defenderoptimize' } else { 'defenderdefault' }
    $regex = [regex]::new(
        ('(?s)\${0}\s*=\s*@''\r?\n(?<Content>.*?)\r?\n''@\r?\nSet-Content -Path "\$env:SystemRoot\\Temp\\{1}\.ps1"' -f $variableName, $fileStem),
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    $match = $regex.Match($source)
    if (-not $match.Success) {
        throw "Unable to extract the source-defined Defender Optimize Assistant $ActionName generated script."
    }

    return [string]$match.Groups['Content'].Value
}

function Get-BoostLabDefenderSecurityCommands {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPayload
    )

    $regex = [regex]::new(
        "(?s)\`$windowssecuritysettings\s*=\s*@\((?<Commands>.*?)\)\s*# run \`$windowssecuritysettings",
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    $match = $regex.Match($ScriptPayload)
    if (-not $match.Success) {
        throw 'Unable to extract the source-defined Defender Safe Mode security command list.'
    }

    return @(
        [regex]::Matches($match.Groups['Commands'].Value, "(?s)'(?<Command>.*?)'") |
            ForEach-Object { [string]$_.Groups['Command'].Value }
    )
}

function Get-BoostLabDefenderBranchDefinition {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [string]$SystemRoot = $env:SystemRoot,

        [string]$SourcePath = $script:BoostLabDefenderSourcePath
    )

    if ([string]::IsNullOrWhiteSpace($SystemRoot)) {
        throw 'SystemRoot is unavailable; Defender Optimize Assistant cannot stage the source-defined workflow.'
    }

    $isApply = $ActionName -eq 'Apply'
    $variableName = if ($isApply) { 'DefenderOptimize' } else { 'DefenderDefault' }
    $fileStem = if ($isApply) { 'defenderoptimize' } else { 'defenderdefault' }
    $label = if ($isApply) { 'Defender: Optimize (Recommended)' } else { 'Defender: Default' }
    $taskSwitch = if ($isApply) { 'Disable' } else { 'Enable' }
    $edgeValue = if ($isApply) { 0 } else { 1 }
    $scriptPath = Join-Path (Join-Path $SystemRoot 'Temp') "$fileStem.ps1"
    $scriptPayload = Get-BoostLabDefenderScriptPayload -ActionName $ActionName -SourcePath $SourcePath
    $securityCommands = Get-BoostLabDefenderSecurityCommands -ScriptPayload $scriptPayload

    $normalBootCommands = [System.Collections.Generic.List[string]]::new()
    $normalBootCommands.Add(('reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Edge" /v SmartScreenEnabled /t REG_DWORD /d {0} /f >nul 2>&1' -f $edgeValue))
    $normalBootCommands.Add(('reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" /v EnableWebContentEvaluation /t REG_DWORD /d {0} /f >nul 2>&1' -f $edgeValue))
    foreach ($taskName in $script:BoostLabDefenderScheduledTasks) {
        $normalBootCommands.Add(('schtasks /Change /TN "{0}" /{1} >nul 2>&1' -f $taskName, $taskSwitch))
    }
    $normalBootCommands.Add('bcdedit /set {current} safeboot minimal >nul 2>&1')

    [pscustomobject]@{
        ActionName = $ActionName
        SourceLabel = $label
        VariableName = $variableName
        FileStem = $fileStem
        GeneratedScriptFileName = "$fileStem.ps1"
        GeneratedScriptPath = $scriptPath
        GeneratedScriptPayload = $scriptPayload
        GeneratedSecurityCommands = $securityCommands
        GeneratedSecurityCommandCount = @($securityCommands).Count
        RunOnceValueName = "*$fileStem"
        RunOnceCommand = 'reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "*{0}" /t REG_SZ /d "powershell.exe -nop -ep bypass -WindowStyle Maximized -f {1}" /f >nul 2>&1' -f $fileStem, $scriptPath
        NormalBootCommands = $normalBootCommands.ToArray()
        ScheduledTasks = $script:BoostLabDefenderScheduledTasks
        ScheduledTaskAction = $taskSwitch
        SafeBootCommand = 'bcdedit /set {current} safeboot minimal >nul 2>&1'
        RestartCommand = 'shutdown -r -t 00'
        SleepSeconds = 5
        UsesTrustedInstallerInGeneratedScript = $scriptPayload.Contains('Run-Trusted')
        RemovesSafeBootInGeneratedScript = $scriptPayload.Contains('bcdedit /deletevalue {current} safeboot')
    }
}

function Get-BoostLabDefenderOptimizeAnalyzeData {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$SystemRoot = $env:SystemRoot,

        [string]$SourcePath = $script:BoostLabDefenderSourcePath
    )

    $sourceInfo = Get-BoostLabDefenderSourceInfo -SourcePath $SourcePath
    $applyBranch = if ($sourceInfo.HashMatches) {
        Get-BoostLabDefenderBranchDefinition -ActionName 'Apply' -SystemRoot $SystemRoot -SourcePath $SourcePath
    }
    else {
        $null
    }
    $defaultBranch = if ($sourceInfo.HashMatches) {
        Get-BoostLabDefenderBranchDefinition -ActionName 'Default' -SystemRoot $SystemRoot -SourcePath $SourcePath
    }
    else {
        $null
    }

    [pscustomobject]@{
        SourcePath = $sourceInfo.SourcePath
        SourceSha256 = $sourceInfo.ActualSha256
        SourceHashMatches = $sourceInfo.HashMatches
        Branches = @('Defender: Optimize (Recommended)', 'Defender: Default')
        ApplyBranch = if ($null -ne $applyBranch) {
            [pscustomobject]@{
                Label = $applyBranch.SourceLabel
                GeneratedScript = $applyBranch.GeneratedScriptFileName
                RunOnceValueName = $applyBranch.RunOnceValueName
                NormalBootCommandCount = @($applyBranch.NormalBootCommands).Count
                GeneratedSecurityCommandCount = $applyBranch.GeneratedSecurityCommandCount
                ScheduledTaskAction = $applyBranch.ScheduledTaskAction
            }
        }
        else { $null }
        DefaultBranch = if ($null -ne $defaultBranch) {
            [pscustomobject]@{
                Label = $defaultBranch.SourceLabel
                GeneratedScript = $defaultBranch.GeneratedScriptFileName
                RunOnceValueName = $defaultBranch.RunOnceValueName
                NormalBootCommandCount = @($defaultBranch.NormalBootCommands).Count
                GeneratedSecurityCommandCount = $defaultBranch.GeneratedSecurityCommandCount
                ScheduledTaskAction = $defaultBranch.ScheduledTaskAction
            }
        }
        else { $null }
        ScheduledTasks = $script:BoostLabDefenderScheduledTasks
        ScheduledTaskCount = @($script:BoostLabDefenderScheduledTasks).Count
        SourceWorkflow = @(
            'Apply writes defenderoptimize.ps1, creates RunOnce *defenderoptimize, applies the source-defined normal-boot SmartScreen/task/BCD commands, waits five seconds, and requests restart.'
            'Default writes defenderdefault.ps1, creates RunOnce *defenderdefault, applies the source-defined normal-boot SmartScreen/task/BCD commands, waits five seconds, and requests restart.'
            'Generated Safe Mode scripts run the source-defined Defender/security registry and BCD commands through TrustedInstaller and Administrator, remove safeboot, wait five seconds, and request a second restart.'
            'The source defines no Open or captured-state Restore branch.'
        )
        ExternalArtifacts = @()
        Downloads = @()
        SupportsOpen = $false
        SupportsDefault = $true
        SupportsRestore = $false
        UsesSafeMode = $true
        UsesTrustedInstaller = $true
        RestartRequired = $true
        Timestamp = Get-Date
    }
}

function Invoke-BoostLabDefenderCommand {
    param(
        [Parameter(Mandatory)]
        [string]$CommandText
    )

    try {
        $scriptBlock = [scriptblock]::Create($CommandText)
        $output = & $scriptBlock 2>&1
        [pscustomobject]@{
            Success = $true
            Output = @($output) -join [Environment]::NewLine
            CommandText = $CommandText
        }
    }
    catch {
        [pscustomobject]@{
            Success = $false
            Output = $_.Exception.Message
            CommandText = $CommandText
        }
    }
}

function Invoke-BoostLabDefenderOptimizeAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [scriptblock]$AdministratorChecker = { Test-BoostLabAdministrator },

        [scriptblock]$FileWriter = {
            param($Path, $Content)
            Set-Content -Path $Path -Value $Content -Force
            [pscustomobject]@{ Success = $true; Output = '' }
        },

        [scriptblock]$CommandInvoker = {
            param($CommandText)
            Invoke-BoostLabDefenderCommand -CommandText $CommandText
        },

        [scriptblock]$SleepInvoker = {
            param($Seconds)
            Start-Sleep -Seconds $Seconds
            [pscustomobject]@{ Success = $true; Output = '' }
        },

        [scriptblock]$RestartInvoker = {
            shutdown -r -t 00
            [pscustomobject]@{ Success = $true; Output = '' }
        },

        [string]$SystemRoot = $env:SystemRoot,

        [string]$SourcePath = $script:BoostLabDefenderSourcePath
    )

    if (-not [bool](& $AdministratorChecker)) {
        return New-BoostLabDefenderOptimizeResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Administrator rights are required to stage the Defender Optimize Assistant Safe Mode workflow.'
    }

    try {
        $sourceInfo = Assert-BoostLabDefenderSourceIdentity -SourcePath $SourcePath
        $branch = Get-BoostLabDefenderBranchDefinition -ActionName $ActionName -SystemRoot $SystemRoot -SourcePath $SourcePath
    }
    catch {
        return New-BoostLabDefenderOptimizeResult `
            -Success $false `
            -Action $ActionName `
            -Message $_.Exception.Message
    }

    $operations = [System.Collections.Generic.List[object]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    $steps = [System.Collections.Generic.List[object]]::new()
    $steps.Add([pscustomobject]@{
        Name = 'WriteGeneratedScript'
        Invoke = { & $FileWriter $branch.GeneratedScriptPath $branch.GeneratedScriptPayload }
    })
    $steps.Add([pscustomobject]@{
        Name = 'InstallRunOnce'
        Invoke = { & $CommandInvoker $branch.RunOnceCommand }
    })
    foreach ($command in @($branch.NormalBootCommands)) {
        $commandText = [string]$command
        $stepName = if ($commandText -like 'schtasks *') {
            'SetScheduledTaskState'
        }
        elseif ($commandText -like 'bcdedit *') {
            'SetSafeBootMinimal'
        }
        else {
            'SetNormalBootRegistryValue'
        }
        $steps.Add([pscustomobject]@{
            Name = $stepName
            CommandText = $commandText
            Invoke = { & $CommandInvoker $commandText }.GetNewClosure()
        })
    }
    $steps.Add([pscustomobject]@{
        Name = 'SleepBeforeRestart'
        Invoke = { & $SleepInvoker $branch.SleepSeconds }
    })
    $steps.Add([pscustomobject]@{
        Name = 'Restart'
        Invoke = { & $RestartInvoker }
    })

    foreach ($step in $steps) {
        try {
            $result = & $step.Invoke
            $operations.Add([pscustomobject]@{
                Step = $step.Name
                CommandText = if ($step.PSObject.Properties['CommandText']) { [string]$step.CommandText } else { '' }
                Result = $result
            })
            if (-not [bool](Get-BoostLabDefenderPropertyValue -InputObject $result -Name 'Success' -DefaultValue $true)) {
                $errors.Add(("{0} failed: {1}" -f $step.Name, (Get-BoostLabDefenderPropertyValue -InputObject $result -Name 'Output' -DefaultValue 'Unknown failure')))
                break
            }
        }
        catch {
            $errors.Add("$($step.Name) failed: $($_.Exception.Message)")
            break
        }
    }

    $data = [pscustomobject]@{
        SourcePath = $sourceInfo.SourcePath
        SourceSha256 = $sourceInfo.ActualSha256
        SourceBranchLabel = $branch.SourceLabel
        GeneratedScriptPath = $branch.GeneratedScriptPath
        GeneratedScriptFileName = $branch.GeneratedScriptFileName
        RunOnceValueName = $branch.RunOnceValueName
        RunOnceCommand = $branch.RunOnceCommand
        NormalBootCommands = $branch.NormalBootCommands
        NormalBootCommandCount = @($branch.NormalBootCommands).Count
        ScheduledTasks = $branch.ScheduledTasks
        ScheduledTaskAction = $branch.ScheduledTaskAction
        GeneratedSecurityCommandCount = $branch.GeneratedSecurityCommandCount
        UsesTrustedInstallerInGeneratedScript = $branch.UsesTrustedInstallerInGeneratedScript
        RemovesSafeBootInGeneratedScript = $branch.RemovesSafeBootInGeneratedScript
        RestartSequence = 'Source-equivalent workflow stages RunOnce, enters Safe Mode, runs the generated Defender script through TrustedInstaller and Administrator, removes safeboot, and requests a second restart.'
        Operations = $operations.ToArray()
        Errors = $errors.ToArray()
        Downloads = @()
        ExternalArtifacts = @()
        CompletedAt = Get-Date
    }

    $success = $errors.Count -eq 0
    $message = if (-not $success) {
        "Defender Optimize Assistant $($branch.SourceLabel) staging failed: $($errors -join '; ')"
    }
    else {
        "Defender Optimize Assistant $($branch.SourceLabel) source workflow was staged; Windows restart was requested exactly as defined by Ultimate."
    }

    return New-BoostLabDefenderOptimizeResult `
        -Success $success `
        -Action $ActionName `
        -Message $message `
        -Data $data
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
        ImplementedActions = @($script:BoostLabImplementedActions)
        Capabilities = [pscustomobject]$script:BoostLabToolMetadata['Capabilities']
        ActionLabels = [pscustomobject]@{
            Analyze = 'Analyze'
            Apply = 'Defender: Optimize (Recommended)'
            Default = 'Defender: Default'
        }
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$OperatingSystem = $env:OS,

        [string]$SystemRoot = $env:SystemRoot,

        [scriptblock]$PathChecker = {
            param($Path)
            Test-Path -LiteralPath $Path -PathType Leaf
        }
    )

    $isWindows = $OperatingSystem -eq 'Windows_NT' -or [System.Environment]::OSVersion.Platform -eq 'Win32NT'
    $requiredPaths = @()
    if (-not [string]::IsNullOrWhiteSpace($SystemRoot)) {
        $requiredPaths = @(
            (Join-Path $SystemRoot 'System32\cmd.exe')
            (Join-Path $SystemRoot 'System32\schtasks.exe')
            (Join-Path $SystemRoot 'System32\bcdedit.exe')
            (Join-Path $SystemRoot 'System32\shutdown.exe')
        )
    }
    $missingPaths = @(
        foreach ($path in $requiredPaths) {
            if (-not [bool](& $PathChecker $path)) {
                $path
            }
        }
    )
    $sourceInfo = Get-BoostLabDefenderSourceInfo
    $supported = $isWindows -and
        -not [string]::IsNullOrWhiteSpace($SystemRoot) -and
        $missingPaths.Count -eq 0 -and
        $sourceInfo.HashMatches

    [pscustomobject]@{
        Supported = $supported
        Reason = if ($supported) {
            'Defender Optimize Assistant source and required Windows command paths are available.'
        }
        elseif (-not $isWindows) {
            'This tool requires Windows.'
        }
        elseif ([string]::IsNullOrWhiteSpace($SystemRoot)) {
            'SystemRoot is unavailable.'
        }
        elseif ($missingPaths.Count -gt 0) {
            'Required Windows command paths are missing: {0}' -f ($missingPaths -join ', ')
        }
        else {
            'Defender Optimize Assistant Ultimate source identity could not be verified.'
        }
        MissingPaths = $missingPaths
        SourceHashMatches = $sourceInfo.HashMatches
        SourceSha256 = $sourceInfo.ActualSha256
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        Implemented = $true
        ImplementedActions = @($script:BoostLabImplementedActions)
        SupportsDefault = $true
        SupportsRestore = $false
        LastAnalyzed = $null
    }
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ActionName,

        [bool]$Confirmed = $false,

        [scriptblock]$AdministratorChecker = { Test-BoostLabAdministrator },

        [scriptblock]$FileWriter = {
            param($Path, $Content)
            Set-Content -Path $Path -Value $Content -Force
            [pscustomobject]@{ Success = $true; Output = '' }
        },

        [scriptblock]$CommandInvoker = {
            param($CommandText)
            Invoke-BoostLabDefenderCommand -CommandText $CommandText
        },

        [scriptblock]$SleepInvoker = {
            param($Seconds)
            Start-Sleep -Seconds $Seconds
            [pscustomobject]@{ Success = $true; Output = '' }
        },

        [scriptblock]$RestartInvoker = {
            shutdown -r -t 00
            [pscustomobject]@{ Success = $true; Output = '' }
        },

        [string]$SystemRoot = $env:SystemRoot,

        [string]$SourcePath = $script:BoostLabDefenderSourcePath
    )

    if ($ActionName -notin @($script:BoostLabImplementedActions)) {
        return New-BoostLabDefenderOptimizeResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Unsupported action. Only Analyze, Apply, and Default are allowed.'
    }

    if ($ActionName -eq 'Analyze') {
        return New-BoostLabDefenderOptimizeResult `
            -Success $true `
            -Action 'Analyze' `
            -Message 'Defender Optimize Assistant source workflow analyzed.' `
            -Data (Get-BoostLabDefenderOptimizeAnalyzeData -SystemRoot $SystemRoot -SourcePath $SourcePath)
    }

    if (-not $Confirmed) {
        return New-BoostLabDefenderOptimizeResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    return Invoke-BoostLabDefenderOptimizeAction `
        -ActionName $ActionName `
        -AdministratorChecker $AdministratorChecker `
        -FileWriter $FileWriter `
        -CommandInvoker $CommandInvoker `
        -SleepInvoker $SleepInvoker `
        -RestartInvoker $RestartInvoker `
        -SystemRoot $SystemRoot `
        -SourcePath $SourcePath
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [bool]$Confirmed = $false
    )

    return Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed:$Confirmed
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
